-- SceneChain (cliente): el PUENTE entre dos escenas seguidas (una cinemática que acaba y otra que
-- empieza, el montaje de cambio de etapa y la cabecera o la primera escena del capítulo siguiente).
--
-- Antes, al acabar una escena volvía TODA la interfaz y, un segundo después, empezaba la otra (la queja
-- de la v107: «se ve un segundo la interfaz del juego y ya empieza la otra»). Ahora, si se sabe que
-- viene otra, la escena que acaba funde a negro y deja una cortina negra (sin interfaz, sin botones de
-- interactuar, sin control del personaje) hasta que la siguiente está en pantalla; esa entra desde
-- negro y la cortina se va.
--
-- ¿Cómo se sabe que viene otra?
--   * El servidor lo dice: atributo SceneFollowUp del jugador = hasta qué hora del servidor
--     (workspace:GetServerTimeNow) se espera la siguiente (CinematicService.expectFollowUp). Lo pone
--     cuando ya sabe que después de esta escena va otra (el capítulo siguiente espera a que acabe el
--     montaje, el paso siguiente de la misión es otra cinemática…) y lo quita al lanzarla.
--   * Esta pantalla ya la tiene en cola: una cinemática que espera turno (Cinematics) o una escena
--     del motor que espera a que acabe la cinemática (HappeningClient). Esos módulos se apuntan con
--     SceneChain.addSource.
-- La cortina nunca se queda: se va en cuanto empieza la escena siguiente (SceneChain.started), o
-- GRACE s después de que ya no se espere nada, o como mucho a los MAX s.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local SceneGuis = require(script.Parent.SceneGuis)

local SceneChain = {}

SceneChain.ATTRIBUTE = "SceneFollowUp"
SceneChain.GRACE = 3.5 -- (el servidor carga el mapa antes de mandarla: hasta 2,5 s)
SceneChain.MAX = 6 -- (un aviso que se queda sin escena: nunca más de esto a oscuras)
SceneChain.FADE_OUT = 0.45

local player = Players.LocalPlayer
local sources: { () -> boolean } = {}
local screens: { () -> boolean } = {}

type Curtain = { Gui: ScreenGui, Frame: Frame, Release: () -> (), Since: number, Done: boolean }
local curtain: Curtain? = nil

local function serverNow(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.clock()
end

local function controls(): any
	local ok, module = pcall(function()
		return require(script.Parent.Parent.Controllers.Controls) :: any
	end)
	return if ok then module else nil
end

-- Un módulo que tiene escenas en cola se apunta: fn() dice si tiene alguna esperando
function SceneChain.addSource(fn: () -> boolean)
	table.insert(sources, fn)
end

-- Un módulo que pone escenas en pantalla se apunta: fn() dice si tiene alguna en pantalla ahora
function SceneChain.addScreen(fn: () -> boolean)
	table.insert(screens, fn)
end

-- ¿Viene otra escena detrás? (lo dice el servidor o hay una en cola en esta pantalla)
function SceneChain.expected(): boolean
	local untilAt = player:GetAttribute(SceneChain.ATTRIBUTE)
	if type(untilAt) == "number" and untilAt > serverNow() then
		return true
	end
	for _, fn in sources do
		local ok, result = pcall(fn)
		if ok and result == true then
			return true
		end
	end
	return false
end

-- ¿Hay una cortina puesta? (la interfaz y la marca InCinematic siguen apagadas)
function SceneChain.active(): boolean
	return curtain ~= nil
end

local function onScreen(): boolean
	for _, fn in screens do
		local ok, result = pcall(fn)
		if ok and result == true then
			return true
		end
	end
	return false
end

local function finish(c: Curtain, fade: number)
	if c.Done then
		return
	end
	c.Done = true
	if curtain == c then
		curtain = nil
	end
	TweenService:Create(c.Frame, TweenInfo.new(fade), { BackgroundTransparency = 1 }):Play()
	task.delay(fade, function()
		pcall(c.Release)
		local module = controls()
		if module then
			pcall(module.enable, "PuenteEscenas")
		end
		-- (si no ha llegado ninguna escena, la marca de «en escena» se quita aquí)
		if curtain == nil and not onScreen() then
			pcall(function()
				player:SetAttribute("InCinematic", nil)
			end)
		end
		c.Gui:Destroy()
	end)
end

-- Una escena acaba (su pantalla ya está en negro). Si viene otra, se pone la cortina y devuelve true:
-- quien llama sigue recogiendo lo suyo (devolver la interfaz no enciende nada mientras la cortina
-- esté). Si no viene nada, devuelve false y todo vuelve como siempre.
function SceneChain.bridge(): boolean
	if curtain then
		return true
	end
	if not SceneChain.expected() then
		return false
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
	if not playerGui then
		return false
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SceneChain"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 60 -- (encima de la interfaz y de la pantalla de la escena que acaba)
	local frame = Instance.new("Frame")
	frame.Name = "Black"
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 0
	frame.Parent = gui
	gui.Parent = playerGui
	local release = SceneGuis.hide(gui, { CoreAll = true })
	local c: Curtain = { Gui = gui, Frame = frame, Release = release, Since = os.clock(), Done = false }
	curtain = c
	local module = controls()
	if module then
		pcall(module.disable, "PuenteEscenas", function()
			return curtain == c
		end)
	end
	pcall(function()
		player:SetAttribute("InCinematic", true) -- (las armas y los botones de interactuar esperan)
	end)
	task.spawn(function()
		local lapsed: number? = nil
		while not c.Done do
			local now = os.clock()
			if now - c.Since >= SceneChain.MAX then
				break
			end
			if SceneChain.expected() then
				lapsed = nil
			else
				lapsed = lapsed or now
				if now - (lapsed :: number) >= SceneChain.GRACE then
					break
				end
			end
			task.wait(0.1)
		end
		finish(c, SceneChain.FADE_OUT)
	end)
	return true
end

-- La escena siguiente ya está en pantalla (con su propia pantalla, que entra desde negro): la
-- cortina se va
function SceneChain.started()
	local c = curtain
	if c then
		task.delay(0.15, function()
			finish(c, SceneChain.FADE_OUT)
		end)
	end
end

-- (pruebas) empezar de cero
function SceneChain._reset()
	local c = curtain
	curtain = nil
	if c then
		c.Done = true
		pcall(c.Release)
		pcall(function()
			c.Gui:Destroy()
		end)
	end
end

return SceneChain
