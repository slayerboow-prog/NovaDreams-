-- BattlePassClient: envoltorio del remoto "BattlePass" para la interfaz del pase de temporada.
-- Solo habla con el servidor y guarda el último estado: NO pinta nada (la interfaz va aparte y usa
-- esto). El servidor lo decide todo; aquí solo se PIDE. Contrato en docs/pase-de-temporada.md.
--
--   local BP = require(Controllers.BattlePassClient)
--   BP.start()
--   BP.onState(function(state) ... end)        -- cada estado completo (Season, Premium, Progress…)
--   BP.on("Unlocked", function(info) ... end)   -- también "Result", "MissionDone", "Premium"
--   BP.refresh()                               -- pide el estado (al abrir el panel)
--   BP.setLevelUpToasts(true)                  -- la interfaz avisa del nivel: el servidor no manda Notify
--   BP.claim("Free", 5) · BP.claimAll() · BP.buy() · BP.equip("Title", id) · BP.track(missionId)
--   BP.reroll(missionId) · BP.choose(storyId, optionId) · BP.buyToken(itemId)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattlePassClient = {}

local remote: RemoteEvent? = nil
local current: { [string]: any }? = nil
local readyListeners: { () -> () } = {}
local stateListeners: { ({ [string]: any }) -> () } = {}
local listeners: { [string]: { (any) -> () } } = {}
local started = false
local levelUpToasts = false -- ¿la interfaz enseña ella el aviso de nivel? (se le dice al servidor)

local function fire(list: { (any) -> () }?, value: any)
	for _, fn in list or {} do
		task.spawn(fn, value)
	end
end

-- La configuración compartida del pase (nil si no se puede cargar)
function BattlePassClient.config(): { [string]: any }?
	local ok, config = pcall(function()
		return require((ReplicatedStorage :: any).Shared.BattlePass.Config)
	end)
	if not ok then
		ok, config = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BattlePass"):WaitForChild("Config"))
		end)
	end
	return if ok and type(config) == "table" then config else nil
end

-- ¿Hay pase para este jugador? Encendido (BattlePassConfig.Enabled) para todos; apagado, solo para
-- los testers (atributo Tester: modo pruebas). Lo de verdad lo decide el servidor (su remoto solo
-- atiende a quien tiene el pase).
function BattlePassClient.enabled(): boolean
	local config = BattlePassClient.config()
	if config ~= nil and config.Enabled == true then
		return true
	end
	local ok, tester = pcall(function()
		return (game:GetService("Players").LocalPlayer :: any):GetAttribute("Tester") == true
	end)
	return config ~= nil and ok and tester == true
end

function BattlePassClient.start()
	if started or not BattlePassClient.enabled() then
		return -- (pase apagado: BattlePassConfig.Enabled)
	end
	started = true
	task.spawn(function()
		-- (sin límite de tiempo: en un servidor recién abierto el remoto puede tardar en crearse)
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local found = remotes:WaitForChild("BattlePass")
		if not found or not found:IsA("RemoteEvent") then
			return -- (servidor sin pase de temporada: no pasa nada)
		end
		remote = found
		found.OnClientEvent:Connect(function(kind, payload)
			if kind == "State" and type(payload) == "table" then
				current = payload
				fire(stateListeners :: any, payload)
			end
			fire(listeners[kind], payload)
		end)
		-- Primer estado: se pide; si la partida aún no había cargado, se vuelve a pedir cada 3 s
		-- (el servidor también lo manda solo al terminar de cargarla)
		BattlePassClient.refresh()
		fire(readyListeners :: any, nil)
		for _ = 1, 40 do
			if current then
				break
			end
			task.wait(3)
			if not current then
				BattlePassClient.refresh()
			end
		end
	end)
end

-- ¿Ya está conectado al remoto del servidor?
function BattlePassClient.ready(): boolean
	return remote ~= nil
end

-- Avisa cuando el remoto está listo (enseguida si ya lo está)
function BattlePassClient.onReady(fn: () -> ())
	table.insert(readyListeners, fn)
	if remote then
		task.spawn(fn)
	end
end

-- Último estado recibido (nil hasta el primero)
function BattlePassClient.state(): { [string]: any }?
	return current
end

function BattlePassClient.onState(fn: ({ [string]: any }) -> ())
	table.insert(stateListeners, fn)
	if current then
		task.spawn(fn, current)
	end
end

function BattlePassClient.on(kind: string, fn: (any) -> ())
	listeners[kind] = listeners[kind] or {}
	table.insert(listeners[kind], fn)
end

function BattlePassClient.request(action: string, a: any?, b: any?, c: any?): boolean
	if not remote then
		return false
	end
	remote:FireServer(action, a, b, c)
	return true
end

-- La interfaz del pase avisa ella sola al subir de nivel («RECOMPENSA DESBLOQUEADA»): el servidor lo
-- sabe al pedir el estado (Get con "Ui") y ya no manda su Notify de «¡nivel n!» (no se repite).
function BattlePassClient.setLevelUpToasts(on: boolean)
	levelUpToasts = on == true
end

function BattlePassClient.refresh(): boolean
	return BattlePassClient.request("Get", if levelUpToasts then "Ui" else nil)
end
function BattlePassClient.claim(track: string, level: number): boolean
	return BattlePassClient.request("Claim", track, level)
end
function BattlePassClient.claimAll(): boolean
	return BattlePassClient.request("ClaimAll")
end
function BattlePassClient.buy(): boolean
	return BattlePassClient.request("Buy")
end
function BattlePassClient.equip(slot: string, id: string?, kind: string?): boolean
	return BattlePassClient.request("Equip", slot, id, kind)
end
function BattlePassClient.track(missionId: string?): boolean
	return BattlePassClient.request("Track", missionId)
end
function BattlePassClient.reroll(missionId: string): boolean
	return BattlePassClient.request("Reroll", missionId)
end
function BattlePassClient.choose(storyId: string, optionId: string): boolean
	return BattlePassClient.request("StoryChoice", storyId, optionId)
end
function BattlePassClient.buyToken(itemId: string): boolean
	return BattlePassClient.request("BuyToken", itemId)
end

return BattlePassClient
