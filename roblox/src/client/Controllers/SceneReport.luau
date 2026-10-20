-- SceneReport (cliente): cuando algo de una escena o de una conversación falla en tu pantalla, se avisa
-- al servidor y se recupera todo (fase 3 del sistema de cine, docs/cine/auditoria-sistema.md).
--
--   SceneReport.guard("Happening", "Grieta_Caen", "Fx", fn, ...)  -- pcall con aviso: ok, resultado
--   SceneReport.report("Dialogue", token, "Line", err)             -- solo el aviso
--   SceneReport.recover("Happening")                               -- red de seguridad (ver abajo)
--
-- * El aviso va por el remoto de siempre de las escenas (Remotes.Scene, el del latido) como
--   ("Error", { Source, Scene, Step, Kind, Message }). Sin nombre ni id del jugador (shared/LifeStory/
--   SceneFaults.clean). Como mucho MaxPerMinute avisos por minuto y el mismo (escena + paso) una vez cada
--   SameEvery s: un fallo en cada fotograma no inunda la red. El servidor vuelve a limpiar y a limitar.
-- * recover(): un momento después de un fallo, si ya no queda ninguna escena ni conversación en
--   pantalla, se devuelve lo que pudiera haberse quedado: la cámara (CineCamera.ensureReleased), los
--   controles de las escenas (Cinematica, Escena, Dialogo), el giro del personaje (AutoRotate) y la
--   interfaz (SceneGuis.forceRestore). Si aún queda alguna, esa escena se encarga al acabar.
-- * Inject (pruebas): SceneReport.Inject["Happening.Fx"] = true (o Inject.Fx) hace fallar ese paso.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SceneFaults = require(ReplicatedStorage.Shared.LifeStory.SceneFaults)

local SceneReport = {}

SceneReport.MaxPerMinute = 8
SceneReport.SameEvery = 30
SceneReport.RecoverAfter = 1 -- segundos tras un fallo antes de mirar si hay que devolver algo
SceneReport.Inject = {} :: { [string]: any } -- (pruebas) pasos que fallan a propósito (true o n veces)
SceneReport.Sent = {} :: { { [string]: string } } -- (pruebas y depuración) los últimos avisos mandados
SceneReport.Dropped = 0 -- avisos que no se mandaron por el límite

local player = Players.LocalPlayer
local sentAt: { number } = {}
local lastSame: { [string]: number } = {}

local function names(): { string }
	local list = {}
	if player then
		pcall(function()
			table.insert(list, player.Name)
			table.insert(list, player.DisplayName)
			table.insert(list, tostring(player.UserId))
		end)
	end
	return list
end

local function remote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local found = remotes and remotes:FindFirstChild("Scene")
	return if found and found:IsA("RemoteEvent") then found else nil
end

-- Avisa al servidor (si toca por el límite). Devuelve si se ha mandado.
function SceneReport.report(source: string, scene: any, step: string?, err: any, kind: string?): boolean
	local report = SceneFaults.normalize({ Source = source, Scene = scene, Step = step, Kind = kind or "Error", Message = err }, names())
	if not report then
		return false
	end
	warn(("[%s] %s en %s/%s: %s"):format(report.Source, report.Kind, report.Scene, report.Step, report.Message))
	local now = os.clock()
	local key = SceneFaults.key(report)
	if lastSame[key] and now - lastSame[key] < SceneReport.SameEvery then
		SceneReport.Dropped += 1
		return false
	end
	for i = #sentAt, 1, -1 do
		if now - sentAt[i] > 60 then
			table.remove(sentAt, i)
		end
	end
	if #sentAt >= SceneReport.MaxPerMinute then
		SceneReport.Dropped += 1
		return false
	end
	lastSame[key] = now
	table.insert(sentAt, now)
	table.insert(SceneReport.Sent, report)
	if #SceneReport.Sent > 50 then
		table.remove(SceneReport.Sent, 1)
	end
	local r = remote()
	if r then
		pcall(r.FireServer, r, "Error", report)
	end
	return true
end

-- ¿Ese paso tiene que fallar a propósito? (pruebas)
-- (Inject[...] = true: siempre; = n: las n veces siguientes)
function SceneReport.injected(source: string, step: string): boolean
	for _, key in { source .. "." .. step, step } do
		local value = (SceneReport.Inject :: any)[key]
		if value == true then
			return true
		elseif type(value) == "number" and value > 0 then
			(SceneReport.Inject :: any)[key] = if value > 1 then value - 1 else nil
			return true
		end
	end
	return false
end

-- pcall con aviso: si fn falla (o el paso está inyectado), se avisa y devuelve false
function SceneReport.guard(source: string, scene: any, step: string, fn: (...any) -> ...any, ...: any): (boolean, ...any)
	if SceneReport.injected(source, step) then
		SceneReport.report(source, scene, step, "fallo inyectado (prueba): " .. step)
		return false
	end
	local result = table.pack(pcall(fn, ...))
	if not result[1] then
		SceneReport.report(source, scene, step, result[2])
		return false
	end
	return true, table.unpack(result, 2, result.n)
end

-- (para quien llama) lanza el fallo inyectado dentro de su propio pcall
function SceneReport.check(source: string, step: string)
	if SceneReport.injected(source, step) then
		error("fallo inyectado (prueba): " .. step, 0)
	end
end

-- ¿Queda algo de historia en pantalla? (cinemática, escena del motor o conversación)
local function busy(): boolean
	local controllers = script.Parent
	local okChain, chained = pcall(function()
		return (require(controllers.Parent.UI.SceneChain) :: any).active()
	end)
	if okChain and chained then
		return true -- (puente negro entre dos escenas: la siguiente ya llega)
	end
	for _, name in { "Cinematics", "HappeningClient", "DialogueUI" } do
		local ok, on = pcall(function()
			local module = require((controllers :: any)[name]) :: any
			if name == "Cinematics" then
				return module.isOnScreen()
			elseif name == "HappeningClient" then
				return module.isPlaying()
			end
			return module.isOpen()
		end)
		if ok and on then
			return true
		end
	end
	return false
end
SceneReport._busy = busy

SceneReport.Recovered = 0 -- veces que la red de seguridad tuvo que devolver algo
-- Devuelve ya lo que se haya quedado, si no queda nada en pantalla. Devuelve si ha tocado algo.
function SceneReport.recoverNow(): boolean
	if busy() then
		return false
	end
	local touched = false
	-- (primero las marcas que se quedaron puestas: con InCinematic o InDialogue la cámara cree que
	-- alguien la usa y no la suelta)
	pcall(function()
		if player:GetAttribute("InCinematic") ~= nil or player:GetAttribute("InDialogue") ~= nil then
			player:SetAttribute("InCinematic", nil)
			player:SetAttribute("InDialogue", nil)
			touched = true
		end
	end)
	pcall(function()
		local CineCamera = require(script.Parent.CineCamera) :: any
		if CineCamera.ensureReleased() then
			touched = true
		end
	end)
	pcall(function()
		local Controls = require(script.Parent.Controls) :: any
		for _, reason in { "Cinematica", "Escena", "Dialogo" } do
			if Controls.isDisabled(reason) then
				Controls.enable(reason)
				touched = true
			end
		end
	end)
	pcall(function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and not humanoid.AutoRotate then
			humanoid.AutoRotate = true
			touched = true
		end
	end)
	pcall(function()
		local SceneGuis = require(script.Parent.Parent.UI.SceneGuis) :: any
		if SceneGuis.active() and SceneGuis.forceRestore() then
			touched = true
		end
	end)
	if touched then
		SceneReport.Recovered += 1
	end
	return touched
end

-- Después de un fallo: mira enseguida y otra vez un poco más tarde (lo que quede en pantalla puede
-- estar acabando)
function SceneReport.recover(_source: string?)
	task.delay(SceneReport.RecoverAfter, SceneReport.recoverNow)
	task.delay(SceneReport.RecoverAfter + 2.5, SceneReport.recoverNow)
end

-- (pruebas) empezar de cero
function SceneReport._reset()
	table.clear(sentAt)
	table.clear(lastSame)
	table.clear(SceneReport.Sent)
	table.clear(SceneReport.Inject)
	SceneReport.Dropped = 0
	SceneReport.Recovered = 0
end

return SceneReport
