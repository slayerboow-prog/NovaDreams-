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
--
--   FlightFocus.setZone("Planeta" | nil)  en un planeta (también a pie, al bajarte de la nave), fuera
--                        lo que solo sirve en Valmar (FlightFocus.ZoneHidden): el GPS «Gira a la
--                        izquierda… 10,9 km», el minimapa de Valmar, la tarjeta de misión de Valmar
--                        (Hud.setZoneFocus), sus marcadores en 3D y las pistas de los primeros pasos
--                        (vídeo del dueño en Tefra, v117). Lo pone Controllers/EnvDirector.
-- Las dos cosas (volar y la zona) se suman: cada pantalla vuelve cuando ya nadie la quiere escondida.

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

-- Lo de Valmar que no pinta nada en otro planeta
FlightFocus.ZoneHidden = {
	Planeta = {
		"GpsGui", -- la ruta por las calles de Valmar
		"MapUI", -- el minimapa de Valmar (en la nave, el radar; a pie, el VISOR)
		"GuideGui", -- primeros pasos y pistas de Valmar
		"GuideHighlight",
		"HelpGui",
	},
}

local active = false -- volando (enter/exit)
local zone: string? = nil -- "Planeta" o nil (setZone)
local worldWanted: { [Instance]: boolean } = {}
local wanted: { [ScreenGui]: boolean } = {} -- lo que querían sus dueños (para devolverlo)
local guards: { [ScreenGui]: RBXScriptConnection } = {}
local conns: { RBXScriptConnection } = {}
local zoneConn: RBXScriptConnection? = nil
local flightSet: { [string]: boolean } = {}
local bubbles: boolean? = nil
local guarding = false
local markersHidden = false

local function playerGui(): Instance?
	local ok, pg = pcall(function()
		return game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end)
	return if ok then pg else nil
end

-- Las pantallas que alguien quiere escondidas ahora (volando y/o en otra zona)
local function hiddenNames(): { [string]: boolean }
	local set = {}
	if active then
		for name in flightSet do
			set[name] = true
		end
	end
	for _, name in (zone and FlightFocus.ZoneHidden[zone]) or {} do
		set[name] = true
	end
	return set
end

local function hide(gui: ScreenGui)
	if wanted[gui] ~= nil then
		return
	end
	wanted[gui] = gui.Enabled ~= false
	gui.Enabled = false
	pcall(function()
		guards[gui] = gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if wanted[gui] == nil or guarding then
				return
			end
			if gui.Enabled then
				wanted[gui] = true
				guarding = true
				gui.Enabled = false
				guarding = false
			else
				wanted[gui] = false
			end
		end)
	end)
end

local function restore(gui: ScreenGui)
	local was = wanted[gui]
	if was == nil then
		return
	end
	wanted[gui] = nil
	local guard = guards[gui]
	if guard then
		guard:Disconnect()
		guards[gui] = nil
	end
	if gui.Parent then
		gui.Enabled = was
	end
end

-- Esconde lo que toca y devuelve lo que ya nadie quiere escondido
local function sync()
	local set = hiddenNames()
	local pg = playerGui()
	if pg then
		for _, child in pg:GetChildren() do
			if child:IsA("ScreenGui") and set[child.Name] then
				hide(child)
			end
		end
	end
	for gui in table.clone(wanted) do
		if not set[gui.Name] then
			restore(gui)
		end
	end
	local any = active or zone ~= nil
	if any and not zoneConn and pg then
		-- (las que aparezcan mientras tanto, también)
		pcall(function()
			zoneConn = pg.ChildAdded:Connect(function(child)
				if child:IsA("ScreenGui") and hiddenNames()[child.Name] then
					hide(child)
				end
			end)
		end)
	elseif not any and zoneConn then
		zoneConn:Disconnect()
		zoneConn = nil
	end
end

local function try(fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn("[FlightFocus] " .. tostring(err))
	end
end

-- Los marcadores de misión en 3D (haz de luz): fuera mientras alguien lo pida
local function syncMarkers()
	local want = active or zone ~= nil
	if want == markersHidden then
		return
	end
	markersHidden = want
	try(function()
		-- (si hay una escena o una conversación, Main lo vuelve a esconder enseguida)
		require(script.Parent.Parent.Controllers.TaskMarker).setHidden(want)
	end)
end

function FlightFocus.isActive(): boolean
	return active
end

function FlightFocus.zone(): string?
	return zone
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
	table.clear(flightSet)
	for _, name in FlightFocus.Hidden do
		flightSet[name] = true
	end
	for _, name in (opts and opts.Keep) or {} do
		flightSet[name] = nil
	end
	sync()
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
	syncMarkers()
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
	table.clear(flightSet)
	sync()
	for item, on in worldWanted do
		if item.Parent then
			(item :: BillboardGui).Enabled = on
		end
	end
	table.clear(worldWanted)
	try(function()
		require(script.Parent.Hud).setFlightFocus(false)
	end)
	syncMarkers()
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

-- La zona donde estás (Controllers/EnvDirector): "Planeta" o nil (Valmar)
function FlightFocus.setZone(name: string?)
	if name ~= nil and FlightFocus.ZoneHidden[name] == nil then
		name = nil
	end
	if name == zone then
		return
	end
	zone = name
	sync()
	syncMarkers()
	try(function()
		local Hud = require(script.Parent.Hud) :: any
		if Hud.setZoneFocus then
			Hud.setZoneFocus(name)
		end
	end)
end

return FlightFocus
