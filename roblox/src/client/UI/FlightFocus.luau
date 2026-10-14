-- FlightFocus: a los mandos de la nave (combate aéreo y espacio) o de un avión (Controllers/Flying, que
-- se queda el minimapa: enter({ Keep = { "MapUI" } })), fuera todo lo del HUD de Valmar que
-- no sirve para volar y estorba (queja del dueño: «se ve todo HORRIBLE», con el GPS «Gira a la derecha
-- en… 10 km», la tarjeta de misión, la barra rápida, el ValPhone y el minimapa encima de la batalla).
--
--   FlightFocus.enter()  esconde: el GPS (GpsGui), la misión (Hud.setFlightFocus: tu estado compacto
--                        y la hora se quedan), el minimapa (MapUI: lo sustituye el radar de la nave),
--                        la barra rápida (HotbarGui), el ValPhone (PhoneGui), la tira de acciones, las
--                        notas y la ayuda, el pase de temporada, los marcadores de misión en 3D y los
--                        globos del chat. El joystick de andar se aparta (la nave usa UI/FlightStick).
--   FlightFocus.exit()   todo vuelve como estaba (si algo cambió mientras tanto, como lo dejó su dueño).
--
-- Mientras dura, si otro sistema vuelve a encender una de esas pantallas, se apaga otra vez (y se
-- recuerda que la quería encendida). Lo que se esconde está en FlightFocus.Hidden (lo prueba
-- scripts/test-aircombat.luau).

local FlightFocus = {}

-- ScreenGuis enteros que se apagan al volar
FlightFocus.Hidden = {
	"GpsGui", -- «Gira a la derecha en…»
	"MapUI", -- minimapa (el radar de la nave va en su sitio)
	"HotbarGui", -- barra rápida 1-9
	"PhoneGui", -- ValPhone
	"ContextStripGui", -- tira de acciones
	"GuideGui", -- primeros pasos, pistas y consejos
	"GuideHighlight",
	"HelpGui", -- «¿Qué hago ahora?»
	"LifeStoryDock",
	"BattlePassTip",
	"ActionsGui",
	"Social",
	"JoystickGui", -- el joystick de andar (la nave tiene su palanca)
}

-- Letreros del mundo (BillboardGui) que se apagan al volar: los que llevan esta etiqueta de
-- CollectionService (las zonas de la invasión, «San Roque» con su barra, salían encima de CAÑÓN y
-- FRENOS en la captura de v117). Vuelven al aterrizar.
FlightFocus.WorldTag = "OcultarAlVolar"

local active = false
local worldWanted: { [Instance]: boolean } = {}
local wanted: { [ScreenGui]: boolean } = {} -- lo que querían sus dueños (para devolverlo)
local conns: { RBXScriptConnection } = {}
local bubbles: boolean? = nil
local guarding = false

local function playerGui(): Instance?
	local ok, pg = pcall(function()
		return game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end)
	return if ok then pg else nil
end

local function hide(gui: ScreenGui)
	if wanted[gui] ~= nil then
		return
	end
	wanted[gui] = gui.Enabled
	gui.Enabled = false
	pcall(function()
		table.insert(conns, gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if active and not guarding and gui.Enabled then
				wanted[gui] = true
				guarding = true
				gui.Enabled = false
				guarding = false
			elseif active and not guarding then
				wanted[gui] = false
			end
		end))
	end)
end

local function try(fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn("[FlightFocus] " .. tostring(err))
	end
end

function FlightFocus.isActive(): boolean
	return active
end

local function hideWorld(item: Instance)
	if worldWanted[item] ~= nil or not item:IsA("BillboardGui") then
		return
	end
	worldWanted[item] = item.Enabled
	item.Enabled = false
end

-- (lo usa quien crea un letrero del mundo) etiqueta un letrero para que no salga mientras pilotas
function FlightFocus.tagWorld(item: Instance)
	pcall(function()
		game:GetService("CollectionService"):AddTag(item, FlightFocus.WorldTag)
	end)
	if active then
		hideWorld(item)
	end
end

-- opts.Keep: pantallas de FlightFocus.Hidden que se quedan (el avión conserva el minimapa: "MapUI")
function FlightFocus.enter(opts: { Keep: { string }? }?)
	if active then
		return
	end
	active = true
	local pg = playerGui()
	if pg then
		local set = {}
		for _, name in FlightFocus.Hidden do
			set[name] = true
		end
		for _, name in (opts and opts.Keep) or {} do
			set[name] = nil
		end
		for _, child in pg:GetChildren() do
			if child:IsA("ScreenGui") and set[child.Name] then
				hide(child)
			end
		end
		-- (las que aparezcan mientras vuelas, también)
		pcall(function()
			table.insert(conns, pg.ChildAdded:Connect(function(child)
				if active and child:IsA("ScreenGui") and set[child.Name] then
					hide(child)
				end
			end))
		end)
	end
	try(function()
		local CollectionService = game:GetService("CollectionService")
		for _, item in CollectionService:GetTagged(FlightFocus.WorldTag) do
			hideWorld(item)
		end
		table.insert(conns, CollectionService:GetInstanceAddedSignal(FlightFocus.WorldTag):Connect(function(item)
			if active then
				hideWorld(item)
			end
		end))
	end)
	try(function()
		require(script.Parent.Hud).setFlightFocus(true)
	end)
	try(function()
		require(script.Parent.Parent.Controllers.TaskMarker).setHidden(true)
	end)
	try(function()
		local config = game:GetService("TextChatService"):FindFirstChildOfClass("BubbleChatConfiguration")
		if config then
			bubbles = config.Enabled
			config.Enabled = false
		end
	end)
end

function FlightFocus.exit()
	if not active then
		return
	end
	active = false
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	for gui, on in wanted do
		if gui.Parent then
			gui.Enabled = on
		end
	end
	table.clear(wanted)
	for item, on in worldWanted do
		if item.Parent then
			(item :: BillboardGui).Enabled = on
		end
	end
	table.clear(worldWanted)
	try(function()
		require(script.Parent.Hud).setFlightFocus(false)
	end)
	try(function()
		-- (si hay una escena o una conversación, Main lo vuelve a esconder enseguida)
		require(script.Parent.Parent.Controllers.TaskMarker).setHidden(false)
	end)
	if bubbles ~= nil then
		local was = bubbles
		bubbles = nil
		try(function()
			local config = game:GetService("TextChatService"):FindFirstChildOfClass("BubbleChatConfiguration")
			if config then
				config.Enabled = was
			end
		end)
	end
end

return FlightFocus
