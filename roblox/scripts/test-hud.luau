-- Prueba de la interfaz principal FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-hud.luau
--
-- Monta el HUD (UI/Hud), el ValPhone y la tira de acciones (Commands/CommandMenu), los botones táctiles
-- (UI/TouchLayout) y el joystick (Controllers/Joystick) con un Roblox de mentira en el que cada
-- propiedad que se escribe se comprueba contra la base de datos de la API de Roblox. Lo monta como en
-- el ordenador (1920x1080, 1600x900, 1366x768) y como en el móvil y la tableta (640x360, 667x375, 844x390, 932x430,
-- 1024x768) y comprueba que:
--   * tu estado va arriba a la izquierda, la hora en el centro, la misión a la derecha y el ValPhone
--     asomando abajo a la izquierda (en el móvil, a la izquierda del joystick); la barra rápida centrada
--   * NADA SE PISA: estado, reloj, minimapa, misión, el ValPhone y su aviso, la tira de acciones,
--     barra rápida, joystick, cada botón táctil y los botones de Roblox (también en móviles grandes:
--     1334x750, 1846x852, 2400x1080)
--   * ya no hay menú COMANDOS ni menú rápido: todo son apps del ValPhone (Ir a casa, Tienda, Mapa,
--     Mochila, Ajustes, Mensajes…) que hacen lo mismo; se abre con un muelle, se cierra tocando fuera
--     o con la barra de inicio; las notificaciones bajan del teléfono (mensajes, pase); las acciones
--     de ahora (Atacar, Saludar…) van en la tira junto a las teclas o en la burbuja «Acciones» del móvil;
--     al volante el teléfono asoma debajo de tu estado y en marcha no se abre
--   * nunca salen dos botones táctiles con el mismo texto (p. ej. dos «Agacharse»)
--   * al volante (móvil): flechas ◀ ▶ a la izquierda en lugar del joystick y, a la derecha, pedales,
--     freno de mano, luces, intermitentes, emergencia, Bajarse y claxon, grandes y sin pisar nada
--   * las barras, el dinero, la experiencia y la misión siguen a los atributos
--   * el joystick mueve al personaje (Humanoid:Move relativo)
--   * en conversaciones y de bebé se aparta lo que tapa la escena
--   * el GPS (Controllers/Gps) da la indicación bajo la reloj sin pisar nada
--   * primeros pasos (Controllers/Guide), el botón ❓ (Controllers/HelpUI) y las pistas: la tarjeta sale
--     a un jugador nuevo y no a uno que ya jugaba, cada paso se cumple al hacerlo de verdad, «Saltar»,
--     el prólogo (InPrologue), «Llévame» pone el GPS, la pista tras 90 s (y no en conversaciones) y
--     los consejos de la primera vez; y la tarjeta y el ❓ tampoco pisan nada

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local db = roblox.getReflectionDatabase()

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Un toque de verdad en un botón táctil: el dedo empieza a pulsar (después de que el botón enseñe lo
-- que hace) y suelta. (Los botones con FreshPress no hacen caso de un toque que empezó antes.)
local function waitReal(seconds: number)
	local from = os.clock()
	while os.clock() - from < seconds do
	end
end
-- (en Roblox un toque en un botón también llega a UserInputService.InputBegan, con processed = true:
-- ContextDetector lo mira para saber que el toque es nuevo)
local touchBeganHook: ((any) -> ())? = nil
local function tap(button: any)
	waitReal(0.2)
	local input = { UserInputType = roblox.Enum.UserInputType.Touch, UserInputState = roblox.Enum.UserInputState.Begin, Position = roblox.Vector3.zero }
	button.InputBegan:Fire(input)
	if touchBeganHook then
		touchBeganHook(input)
	end
	button.Activated:Fire()
end

-- Ventanas del móvil (lo que se mide en el código; lo que se ve lo prueba test-clientboot en 667x375)
do
	print("▶ Ventanas del móvil (código)")
	local debugPrints = {}
	local function scan(dir: string)
		for _, name in fs.readDir(dir) do
			local path = dir .. "/" .. name
			if fs.isDir(path) then
				scan(path)
			elseif string.sub(name, -5) == ".luau" and string.find(fs.readFile(path), 'print%("DBG') then
				table.insert(debugPrints, path)
			end
		end
	end
	scan("src/client")
	check(#debugPrints == 0, ("Sin print(\"DBG\", …) de depuración en el cliente (%s)"):format(table.concat(debugPrints, ", ")))
	local function orderOf(path: string, name: string): number?
		local source = fs.readFile(path)
		local at = string.find(source, 'Name = "' .. name .. '"', 1, true)
		local tail = at and string.sub(source, at, at + 400)
		return tonumber(tail and string.match(tail, "DisplayOrder = (%d+)"))
	end
	local touchOrder = orderOf("src/client/UI/TouchLayout.luau", "TouchLayout") or 4
	for _, w in { { "src/client/UI/Hud.luau", "HudPopups", "menú, controles y misiones" }, { "src/client/Controllers/InventoryUI.luau", "InventoryUI", "la mochila" }, { "src/client/UI/Dialog.luau", "Dialogs", "las ventanas de UI/Dialog" } } do
		local order = orderOf(w[1], w[2])
		check(order ~= nil and order > touchOrder, ("%s (%s) por encima de los botones táctiles (DisplayOrder %s > %d)"):format(w[3], w[2], tostring(order), touchOrder))
	end
	-- Cada ventana grande se apunta en «una a la vez» (Dialog.registerBig con su isOpen) y cierra las demás al abrirse
	for _, w in {
		{ "src/client/Controllers/InventoryUI.luau", "Inventory" },
		{ "src/client/Controllers/HelpUI.luau", "Help" },
		{ "src/client/Controllers/StoryJournal.luau", "Journal" },
		{ "src/client/Controllers/MapUI.luau", "BigMap" },
		{ "src/client/UI/Phone.luau", "Phone" },
		{ "src/client/Controllers/HousingUI.luau", "HouseKeys" },
		{ "src/client/Controllers/FridgeUI.luau", "Fridge" },
		{ "src/client/Controllers/InteriorUI.luau", "Elevator" },
	} do
		local source = fs.readFile(w[1])
		local registered = string.find(source, 'Dialog.registerBig("' .. w[2] .. '", ', 1, true) ~= nil
		local closes = string.find(source, 'closeOthers%(?"?' .. w[2]) ~= nil or string.find(source, 'Dialog.closeOthers, "' .. w[2] .. '"', 1, true) ~= nil
		check(registered and closes, ("Una ventana a la vez: %s se apunta (registerBig) y cierra las demás al abrirse"):format(w[2]))
	end
	local hud = fs.readFile("src/client/UI/Hud.luau")
	check(string.find(hud, "end, Hud.questsOpen)", 1, true) ~= nil, "Misiones se apunta con su isOpen (Dialog.anyOpen la ve)")
	local bus = fs.readFile("src/client/Controllers/BusUI.luau")
	check(string.find(bus, "gui.Enabled = true", 1, true) == nil, "Autobús: no enciende su pantalla cada 0,2 s (encima de cinemáticas y del modo foto)")
end

---------------------------------------------------------------------
-- Señales y objetos de mentira
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	local self = {}
	function self:Connect(fn)
		table.insert(handlers, fn)
		return {
			Disconnect = function()
				local i = table.find(handlers, fn)
				if i then
					table.remove(handlers, i)
				end
			end,
		}
	end
	function self:Once(fn)
		return self:Connect(fn)
	end
	function self:Wait() end
	function self:Fire(...)
		for _, fn in table.clone(handlers) do
			fn(...)
		end
	end
	return self
end

local function hasProperty(className: string, name: string): boolean
	local class = db:GetClass(className)
	while class do
		if class.Properties[name] ~= nil then
			return true
		end
		class = class.Superclass and db:GetClass(class.Superclass)
	end
	return false
end

local function isA(className: string, other: string): boolean
	local class = db:GetClass(className)
	while class do
		if class.Name == other then
			return true
		end
		class = class.Superclass and db:GetClass(class.Superclass)
	end
	return false
end

local badWrites: { string } = {}
local Instance = {}
local instanceMeta = {}

local function newInstance(className: string): any
	assert(db:GetClass(className), "Clase desconocida: " .. className)
	local data = {
		__class = className,
		__props = { Name = className, Visible = true, ZIndex = 1 },
		__children = {},
		__attributes = {},
		__signals = {},
		__attrSignals = {},
		__propSignals = {},
	}
	return setmetatable(data, instanceMeta)
end
Instance.new = newInstance

local methods = {}
function methods:GetChildren()
	return table.clone(rawget(self, "__children"))
end
function methods:GetDescendants()
	local out = {}
	local function walk(object)
		for _, child in rawget(object, "__children") do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end
function methods:FindFirstChild(name)
	for _, child in rawget(self, "__children") do
		if child.Name == name then
			return child
		end
	end
	return nil
end
function methods:FindFirstChildOfClass(className)
	for _, child in rawget(self, "__children") do
		if rawget(child, "__class") == className then
			return child
		end
	end
	return nil
end
function methods:FindFirstChildWhichIsA(className)
	for _, child in rawget(self, "__children") do
		if isA(rawget(child, "__class"), className) then
			return child
		end
	end
	return nil
end
function methods:WaitForChild(name)
	return self:FindFirstChild(name) or error("WaitForChild se quedaría esperando: " .. tostring(name))
end
function methods:IsA(className)
	return isA(rawget(self, "__class"), className)
end
function methods:IsDescendantOf(other)
	local parent = self.Parent
	while parent do
		if parent == other then
			return true
		end
		parent = parent.Parent
	end
	return false
end
function methods:Destroy()
	self.Parent = nil
	for _, child in rawget(self, "__children") do
		child:Destroy()
	end
end
function methods:ClearAllChildren()
	for _, child in rawget(self, "__children") do
		child:Destroy()
	end
end
function methods:GetAttribute(name)
	return rawget(self, "__attributes")[name]
end
function methods:SetAttribute(name, value)
	rawget(self, "__attributes")[name] = value
	local s = rawget(self, "__attrSignals")[name]
	if s then
		s:Fire()
	end
end
function methods:GetAttributeChangedSignal(name)
	local signals = rawget(self, "__attrSignals")
	signals[name] = signals[name] or signal()
	return signals[name]
end
function methods:GetPropertyChangedSignal(name)
	local signals = rawget(self, "__propSignals")
	signals[name] = signals[name] or signal()
	return signals[name]
end
function methods:FireServer(...) end

instanceMeta.__index = function(self, key)
	if methods[key] then
		return methods[key]
	end
	local props = rawget(self, "__props")
	if props[key] ~= nil then
		return props[key]
	end
	if key == "ClassName" then
		return rawget(self, "__class")
	end
	if key == "Parent" then
		return nil
	end
	-- Un hijo por su nombre (como en Roblox: gui.Status)
	if typeof(key) == "string" and not hasProperty(rawget(self, "__class"), key) then
		for _, child in rawget(self, "__children") do
			if rawget(child, "__props").Name == key then
				return child
			end
		end
	end
	-- Un evento (Activated, MouseEnter, HealthChanged, OnClientEvent…): empieza con mayúscula y
	-- no es una propiedad
	if typeof(key) == "string" and not hasProperty(rawget(self, "__class"), key) then
		local signals = rawget(self, "__signals")
		signals[key] = signals[key] or signal()
		return signals[key]
	end
	return nil
end
instanceMeta.__newindex = function(self, key, value)
	local className = rawget(self, "__class")
	if key ~= "Parent" and key ~= "Name" and not hasProperty(className, key) then
		table.insert(badWrites, ("%s.%s"):format(className, tostring(key)))
		return
	end
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old then
			local list = rawget(old, "__children")
			local i = table.find(list, self)
			if i then
				table.remove(list, i)
			end
		end
		if value then
			table.insert(rawget(value, "__children"), self)
		end
	end
	props[key] = value
	local s = rawget(self, "__propSignals")[key]
	if s then
		s:Fire()
	end
end
instanceMeta.__tostring = function(self)
	return rawget(self, "__props").Name
end

local function find(root, path: string)
	local current = root
	for part in path:gmatch("[^/]+") do
		current = current and current:FindFirstChild(part)
	end
	return current
end

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local function service(className: string, extra: { [string]: any }?)
	local object = newInstance(className)
	for key, value in extra or {} do
		rawget(object, "__props")[key] = value
	end
	return object
end

local TweenInfo = { new = function(...)
	return { ... }
end }
local tweenService = service("TweenService")
rawset(tweenService, "Create", function(_, object, _, goals)
	return {
		Play = function()
			for key, value in goals do
				object[key] = value -- sin animación: el valor final directamente
			end
		end,
		Completed = signal(),
		Cancel = function() end,
	}
end)

local replicatedStorage = service("ReplicatedStorage")
local remotes = newInstance("Folder")
remotes.Name = "Remotes"
remotes.Parent = replicatedStorage
-- Calles publicadas (para el GPS): una L, hacia el norte y luego al este
local ambientFolder = newInstance("Folder")
ambientFolder.Name = "Ambient"
ambientFolder.Parent = replicatedStorage
local roadsFolder = newInstance("Folder")
roadsFolder.Name = "Roads"
roadsFolder.Parent = ambientFolder
for i, road in { { roblox.Vector3.new(0, 0, 0), roblox.Vector3.new(0, 0, -200) }, { roblox.Vector3.new(0, 0, -200), roblox.Vector3.new(200, 0, -200) } } do
	local config = newInstance("Configuration")
	config.Name = "Road" .. i
	config:SetAttribute("A", road[1])
	config:SetAttribute("B", road[2])
	config.Parent = roadsFolder
end
for _, name in { "LifeStory", "QuitJob", "GoHome", "Onboarding", "SeaEvent" } do
	local remote = newInstance("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

-- Lo que el cliente manda al servidor por el remoto de los primeros pasos
local onboardingSent: { { any } } = {}
rawset(remotes:FindFirstChild("Onboarding"), "FireServer", function(_, ...)
	table.insert(onboardingSent, { ... })
end)

local players = service("Players")
rawset(players, "GetUserThumbnailAsync", function()
	return "rbxthumb://test"
end)
local localPlayer = newInstance("Player")
rawget(localPlayer, "__props").DisplayName = "Rayo"
rawget(localPlayer, "__props").UserId = 1
local playerGui = newInstance("PlayerGui")
playerGui.Name = "PlayerGui"
playerGui.Parent = localPlayer
rawget(players, "__props").LocalPlayer = localPlayer

local camera = newInstance("Camera")
rawget(camera, "__props").ViewportSize = roblox.Vector2.new(1920, 1080)
local fakeWorkspace = newInstance("Workspace")
rawget(fakeWorkspace, "__props").CurrentCamera = camera
fakeWorkspace:SetAttribute("Day", 3)
fakeWorkspace:SetAttribute("ServerReady", true) -- (Main.server.luau ya ha arrancado: UI/ServerWait no espera)

local lighting = service("Lighting", { ClockTime = 10 })
local guiService = service("GuiService")
rawset(guiService, "GetGuiInset", function()
	return roblox.Vector2.new(0, 58), roblox.Vector2.new(0, 0)
end)
local collection = service("CollectionService")
rawset(collection, "GetTagged", function()
	return {}
end)
local userInput = service("UserInputService", { TouchEnabled = false, KeyboardEnabled = true, GamepadEnabled = false })
touchBeganHook = function(input)
	userInput.InputBegan:Fire(input, true)
end
rawset(userInput, "GetFocusedTextBox", function()
	return nil
end)
rawset(userInput, "GetLastInputType", function()
	return roblox.Enum.UserInputType.Keyboard
end)
local contextActions = service("ContextActionService")
for _, name in { "BindAction", "BindActionAtPriority", "UnbindAction", "SetTitle", "SetPosition" } do
	rawset(contextActions, name, function() end)
end

local services = {
	TweenService = tweenService,
	ReplicatedStorage = replicatedStorage,
	Players = players,
	Lighting = lighting,
	GuiService = guiService,
	CollectionService = collection,
	UserInputService = userInput,
	RunService = service("RunService"),
	ContextActionService = contextActions,
	ProximityPromptService = service("ProximityPromptService"),
	-- (el panel lee el encargo de la ciudad en JSON: atributo CityErrand)
	HttpService = {
		JSONDecode = function(_, text)
			return require("@lune/serde").decode("json", text)
		end,
		JSONEncode = function(_, value)
			return require("@lune/serde").encode("json", value)
		end,
	},
}
local fakeGame = { GetService = function(_, name)
	return services[name] or error("Servicio sin simular: " .. name)
end }

-- task: los bucles "while true … task.wait" dan una sola vuelta; delay y spawn en el momento
local fakeTask = {
	spawn = function(fn, ...)
		local thread = coroutine.create(fn)
		local ok, err = coroutine.resume(thread, ...)
		if not ok then
			error(err)
		end
		return thread
	end,
	defer = function(fn, ...)
		fn(...)
	end,
	delay = function() end,
	wait = function()
		coroutine.yield()
	end,
}

---------------------------------------------------------------------
-- Cargar módulos (ReplicatedStorage.Shared -> src/shared; UI -> src/client/UI)
---------------------------------------------------------------------
local nodeMeta = {}
local function node(path: string)
	return setmetatable({ __path = path }, nodeMeta)
end
nodeMeta.__index = function(self, key)
	local path = rawget(self, "__path")
	if key == "Parent" then
		return node((path:match("^(.*)/[^/]+$")))
	end
	return node(path .. "/" .. key)
end
rawget(replicatedStorage, "__props").Shared = node("src/shared")

local cache: { [string]: any } = {}
-- Módulos que aquí no hacen falta (sonidos): se sustituyen por uno vacío
local STUBS = {
	-- (las cinemáticas, con su música y sus sonidos: aquí solo hace falta saber que no hay ninguna)
	["src/client/Controllers/Cinematics"] = function()
		return { isPlaying = function()
			return false
		end }
	end,
	["src/client/Controllers/SoundFx"] = function()
		return setmetatable({}, { __index = function()
			return function() end
		end })
	end,
}
local function loadModule(path: string): any
	if cache[path] ~= nil then
		return cache[path]
	end
	if STUBS[path] then
		cache[path] = STUBS[path]()
		return cache[path]
	end
	local file = path .. ".luau"
	if not fs.isFile(file) then
		file = path .. "/init.luau"
	end
	assert(fs.isFile(file), "Módulo no encontrado: " .. path)
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return loadModule(rawget(target, "__path"))
		end,
		game = fakeGame,
		workspace = fakeWorkspace,
		task = fakeTask,
		Instance = Instance,
		TweenInfo = TweenInfo,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Vector2 = roblox.Vector2,
		Vector3 = roblox.Vector3,
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		Font = roblox.Font,
		Enum = roblox.Enum,
		CFrame = roblox.CFrame,
		RaycastParams = { new = function()
			return {}
		end },
		UserSettings = function()
			return { GetService = function()
				return { SavedQualityLevel = roblox.Enum.SavedQualitySetting.Automatic }
			end }
		end,
		typeof = function(value)
			if getmetatable(value) == instanceMeta then
				return "Instance"
			end
			return typeof(value)
		end,
		warn = function(...)
			print("[warn]", ...)
		end,
	}, { __index = _G })
	local result = luau.load(fs.readFile(file), { debugName = file, environment = env })()
	cache[path] = result
	return result
end

---------------------------------------------------------------------
-- Montar el HUD (con el menú de comandos, los botones táctiles y el joystick)
---------------------------------------------------------------------
local renderSteps: { [string]: (number) -> () } = {}
rawset(services.RunService, "BindToRenderStep", function(_, name, _, fn)
	renderSteps[name] = fn
end)
rawset(services.RunService, "UnbindFromRenderStep", function(_, name)
	renderSteps[name] = nil
end)

-- Personaje de mentira: su Humanoid apunta lo que le piden (Move)
local moves: { { Vector: any, Relative: boolean } } = {}
local character = newInstance("Model")
character.Name = "Rayo"
local humanoid = newInstance("Humanoid")
humanoid.Parent = character
rawget(humanoid, "__props").Health = 100
rawget(humanoid, "__props").MaxHealth = 100
rawset(humanoid, "Move", function(_, vector, relative)
	table.insert(moves, { Vector = vector, Relative = relative })
end)
rawget(localPlayer, "__props").Character = character
rawget(humanoid, "__props").WalkSpeed = 16
local rootPart = newInstance("Part")
rootPart.Name = "HumanoidRootPart"
rootPart.Parent = character
rawget(rootPart, "__props").Position = roblox.Vector3.new(0, 3, -10)
rawget(rootPart, "__props").CFrame = roblox.CFrame.new(0, 3, -10)
rawset(fakeWorkspace, "Raycast", function()
	return nil
end)

local function setViewport(x: number, y: number)
	camera.ViewportSize = roblox.Vector2.new(x, y) -- (dispara el cambio: todo se recoloca)
end

-- Lo que ven los primeros pasos del mapa grande y de la mochila (en el juego: MapUI.isOpen, InventoryUI.isOpen)
local fakeHooks = { Map = false, Bag = false, Dialog = false }

local function mount(touch: boolean, x: number, y: number)
	-- Cada montaje empieza de cero (módulos y pantalla)
	table.clear(cache)
	table.clear(badWrites)
	table.clear(renderSteps)
	for _, child in playerGui:GetChildren() do
		child:Destroy()
	end
	rawget(camera, "__propSignals").ViewportSize = nil
	rawget(camera, "__props").ViewportSize = roblox.Vector2.new(x, y)
	rawget(userInput, "__props").TouchEnabled = touch
	rawget(userInput, "__props").KeyboardEnabled = not touch
	localPlayer:SetAttribute("LifeStage", "Nino")
	-- Jugador nuevo (lo que pone OnboardingService): la tarjeta de los primeros pasos está en pantalla
	localPlayer:SetAttribute("Tutorial", "Pendiente")
	localPlayer:SetAttribute("TutorialSteps", "")
	localPlayer:SetAttribute("TipsSeen", "")
	local Hud = loadModule("src/client/UI/Hud")
	local storeOpened = false
	local ok, err = pcall(Hud.init, function()
		storeOpened = true
	end)
	local mods = {
		Hud = Hud,
		HudLayout = loadModule("src/client/UI/HudLayout"),
		TouchLayout = loadModule("src/client/UI/TouchLayout"),
		CommandMenu = loadModule("src/client/Commands/CommandMenu"),
		CommandRegistry = loadModule("src/client/Commands/CommandRegistry"),
		Joystick = loadModule("src/client/Controllers/Joystick"),
		Gps = loadModule("src/client/Controllers/Gps"),
		Guide = loadModule("src/client/Controllers/Guide"),
		HelpUI = loadModule("src/client/Controllers/HelpUI"),
	}
	if ok then
		ok, err = pcall(mods.CommandMenu.init)
	end
	if ok then
		ok, err = pcall(mods.Joystick.init)
	end
	if ok then
		ok, err = pcall(mods.Gps.init)
	end
	if ok then
		ok, err = pcall(mods.HelpUI.init)
	end
	if ok then
		ok, err = pcall(mods.Guide.init, {
			mapOpen = function()
				return fakeHooks.Map
			end,
			bagOpen = function()
				return fakeHooks.Bag
			end,
			dialogOpen = function()
				return fakeHooks.Dialog
			end,
		})
		-- (como en Main.client: abrir el ❓ y «Llévame» son pasos)
		mods.HelpUI.onOpen(function()
			mods.Guide.mark("Ayuda")
		end)
		mods.HelpUI.onGo(function()
			mods.Guide.mark("Mision")
		end)
	end
	-- Un objetivo de misión al noreste: el GPS calcula la ruta y da la indicación
	localPlayer:SetAttribute("StoryTarget", roblox.Vector3.new(150, 0, -200))
	if ok then
		ok, err = pcall(mods.Gps.update)
	end
	return mods, ok, err, function()
		return storeOpened
	end
end

local function textOf(root, text: string): boolean
	for _, object in root:GetDescendants() do
		local value = rawget(object, "__props").Text
		if typeof(value) == "string" and value:find(text, 1, true) then
			return true
		end
	end
	return false
end

-- Un descendiente por su nombre (FindFirstChild(nombre, true) de Roblox)
local function deep(root, name: string)
	for _, object in if root then root:GetDescendants() else {} do
		if object.Name == name then
			return object
		end
	end
	return nil
end

-- Rectángulo en el lienzo de un objeto que cuelga directamente de una pantalla
-- (con el encogido del móvil, HudLayout.Compact: el UIScale «PressScale» con su atributo HudShrink)
local function rectOf(object, layout)
	local size = object.Size
	local scaler = object:FindFirstChild("PressScale")
	local shrink = scaler and scaler:GetAttribute("HudShrink") or nil
	return layout.HudLayoutModule.rect({ Anchor = object.AnchorPoint, Position = object.Position, Size = roblox.Vector2.new(size.X.Offset, size.Y.Offset), Shrink = shrink }, layout.Canvas)
end

local function describe(r): string
	return ("(%d,%d %dx%d)"):format(r.X, r.Y, r.W, r.H)
end

-- Comprueba que ningún par de rectángulos visibles se pisa
local function noOverlaps(rects: { { Name: string, Rect: any } }, HudLayout, where: string)
	local clashes = {}
	for i = 1, #rects do
		for j = i + 1, #rects do
			if HudLayout.overlaps(rects[i].Rect, rects[j].Rect) then
				table.insert(clashes, rects[i].Name .. describe(rects[i].Rect) .. " / " .. rects[j].Name .. describe(rects[j].Rect))
			end
		end
	end
	check(#clashes == 0, where .. ": nada se pisa (" .. #rects .. " piezas)" .. (if #clashes > 0 then ": " .. table.concat(clashes, "; ") else ""))
end

-- Todo lo que se ve del HUD (en el lienzo)
local function hudRects(mods)
	local HudLayout = mods.HudLayout
	local layout = HudLayout.current()
	layout.HudLayoutModule = HudLayout
	local hud = playerGui:FindFirstChild("MainHud")
	local list = {}
	local function add(name: string, object)
		if object and object.Visible ~= false then
			table.insert(list, { Name = name, Rect = rectOf(object, layout) })
		end
	end
	add("Estado", hud:FindFirstChild("Status"))
	add("Reloj", hud:FindFirstChild("Clock"))
	add("Misión", hud:FindFirstChild("Mission"))
	table.insert(list, { Name = "Minimapa", Rect = HudLayout.rect(layout.Items.Minimap, layout.Canvas) })
	-- Las balas del arma: siempre (el peor caso: con el arma en la mano)
	table.insert(list, { Name = "Balas del arma", Rect = HudLayout.rect(layout.Items.Ammo, layout.Canvas) })
	table.insert(list, { Name = "Barra rápida", Rect = HudLayout.rect(layout.Items.Hotbar, layout.Canvas) })
	-- El ValPhone que asoma y el hueco de su aviso (aunque no esté); en el ordenador, el hueco entero
	-- de la tira de acciones (en el móvil es la burbuja del racimo y su lista se abre encima)
	local phoneGui = playerGui:FindFirstChild("PhoneGui")
	add("ValPhone", phoneGui and phoneGui:FindFirstChild("PhonePeek"))
	-- (al volante o volando, el aviso baja debajo del teléfono que asoma: Items.PhoneBannerDrive)
	local atWheel = layout.Touch and mods.TouchLayout and (mods.TouchLayout.isDriving() or mods.TouchLayout.isFlying())
	-- (en el móvil el aviso va en el hueco de las notas, debajo de tu estado, y se turnan: mientras se
	-- ve el aviso la nota o la tarjeta esperan —Guide, Phone.bannerShowing—; se cuenta si no hay nota)
	local guideShown = false
	local guideScreen = playerGui:FindFirstChild("GuideGui")
	for _, name in { "TutorialCard", "GuideNote" } do
		local piece = guideScreen and guideScreen:FindFirstChild(name)
		if piece and piece.Visible then
			guideShown = true
		end
	end
	if not (layout.Touch and guideShown) then
		table.insert(list, { Name = "Aviso del ValPhone", Rect = HudLayout.rect(if atWheel then layout.Items.PhoneBannerDrive else layout.Items.PhoneBanner, layout.Canvas) })
	end
	if not layout.Touch then
		table.insert(list, { Name = "Tira de acciones", Rect = HudLayout.rect(layout.Items.Context, layout.Canvas) })
	end
	local stick = playerGui:FindFirstChild("JoystickGui")
	add("Joystick", stick and stick:FindFirstChild("Joystick"))
	local gps = playerGui:FindFirstChild("GpsGui")
	add("Indicación del GPS", gps and gps:FindFirstChild("GpsBanner"))
	local helpGui = playerGui:FindFirstChild("HelpGui")
	add("Botón ❓", helpGui and helpGui:FindFirstChild("HelpButton"))
	local guideGui = playerGui:FindFirstChild("GuideGui")
	add("Tarjeta de primeros pasos", guideGui and guideGui:FindFirstChild("TutorialCard"))
	add("Pista o consejo", guideGui and guideGui:FindFirstChild("GuideNote"))
	local touchGui = playerGui:FindFirstChild("TouchLayout")
	for _, child in if touchGui then touchGui:GetChildren() else {} do
		if child:IsA("TextButton") and child.Visible then
			add("Botón " .. child.Name, child)
		elseif child.Name == "Hints" and child.Visible then
			add("Teclas", child)
		end
	end
	-- Los botones de Roblox de arriba a la izquierda (menú, chat, voz)
	table.insert(list, { Name = "Botones de Roblox", Rect = { X = 0, Y = 0, W = 250 / layout.Scale, H = 58 / layout.Scale } })
	return list, layout
end

---------------------------------------------------------------------
print("\n▶ En el ordenador (1920x1080)")
local mods, ok, err, storeOpened = mount(false, 1920, 1080)
local Hud, HudLayout, CommandMenu, CommandRegistry, TouchLayout = mods.Hud, mods.HudLayout, mods.CommandMenu, mods.CommandRegistry, mods.TouchLayout
check(ok, "El HUD, los comandos y los botones se montan sin errores" .. (if ok then "" else ": " .. tostring(err)))
check(#badWrites == 0, "Todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
local hud = playerGui:FindFirstChild("MainHud")
local layout = HudLayout.current()
check(layout.Scale > 1 and math.abs(layout.Canvas.X - 1700) < 1, "Escala del HUD según la pantalla (lienzo de 1700 de ancho)")

-- Arriba a la izquierda: tu estado
local status = hud and hud:FindFirstChild("Status")
check(status and status.AnchorPoint == roblox.Vector2.new(0, 0) and status.Position.X.Offset == 16 and status.Position.Y.Offset * layout.Scale >= 58, "Tu estado arriba a la izquierda, debajo de los botones de Roblox")
check(status and status:FindFirstChild("Portrait") and status.Portrait:FindFirstChild("Photo").Image == "rbxthumb://test", "Con tu foto de verdad en el aro")
check(status and status.Portrait:FindFirstChild("LevelBadge") ~= nil, "Y la corona del nivel")
check(status and textOf(status, "Rayo") and textOf(status, "Nv. 1"), "Con tu nombre y «Nv. 1»")
localPlayer:SetAttribute("Xp", 125)
localPlayer:SetAttribute("XpNext", 300)
check(status and textOf(status, "125 / 300 XP"), "Experiencia «125 / 300 XP»")
localPlayer:SetAttribute("Energy", 25)
local energy = status and status:FindFirstChild("Energy")
local fill = energy and energy:FindFirstChild("Fill")
check(fill and math.abs(fill.Size.X.Scale - 0.25) < 0.01, "La barra de energía baja al 25 %")
check(status and status:FindFirstChild("EnergyValue") and status.EnergyValue.Text == "25", "Y su número a la derecha dice 25")
check(status and status:FindFirstChild("Hunger") and status:FindFirstChild("Fun") and status:FindFirstChild("Mood") and status:FindFirstChild("Health"), "Barras de energía, hambre, 🎈 diversión, ánimo (o estamina) y salud")
-- 🎈 Diversión (NeedsService): su barra, su número y la carita seria si te aburres
localPlayer:SetAttribute("Fun", 20)
local funBar = status and status:FindFirstChild("Fun")
local funFill = funBar and funBar:FindFirstChild("Fill")
check(funFill and math.abs(funFill.Size.X.Scale - 0.2) < 0.01 and status.FunValue.Text == "20", "La barra de diversión baja al 20 % con su número")
check(status and status:FindFirstChild("FunIcon") and status.FunIcon:GetAttribute("Icon") == "diversion", "Con su icono (el globo)")
localPlayer:SetAttribute("Bored", true)
check(status.FunIcon:GetAttribute("Icon") == "aburrido", "Aburrido (Bored): la carita seria en vez del globo")
localPlayer:SetAttribute("Bored", nil)
localPlayer:SetAttribute("Fun", nil)
check(status.FunIcon:GetAttribute("Icon") == "diversion" and math.abs(funFill.Size.X.Scale - 1) < 0.01, "Sin el atributo, llena (partidas de antes)")
do
	-- Las 5 barras caben en el alto de siempre, una debajo de otra sin pisarse
	local ok, last = true, -math.huge
	for _, id in { "Energy", "Hunger", "Fun", "Mood", "Health" } do
		local icon = status:FindFirstChild(id .. "Icon")
		local track = status:FindFirstChild(id)
		if not icon or not track then
			ok = false
			continue
		end
		local y0 = icon.Position.Y.Offset
		if y0 < last or y0 + icon.Size.Y.Offset > status.Size.Y.Offset + 1 or track.Size.Y.Offset < 8 then
			ok = false
		end
		last = y0 + icon.Size.Y.Offset
	end
	check(ok, "Ordenador: las 5 barras (energía, hambre, diversión, ánimo, salud) en columna, sin pisarse y dentro de la tarjeta")
end
localPlayer:SetAttribute("Money", 510)
localPlayer:SetAttribute("Money", 560)
check(status and status:FindFirstChild("Money") and status.Money.Text:find("560", 1, true) ~= nil, "El dinero junto al nombre se actualiza")
check(status and textOf(status, "+"), "Y al ganar dinero sube un «+…»")

-- Arriba en el centro: la cápsula de la hora
local clock = hud and hud:FindFirstChild("Clock")
check(clock and clock.AnchorPoint == roblox.Vector2.new(0.5, 0) and clock.Position.X.Scale == 0.5, "Cápsula de la hora arriba en el centro")
check(clock and clock:FindFirstChild("Time").Text == "10:00", "Con la hora («10:00»)")
check(clock and clock:FindFirstChild("Date").Text:find(", ", 1, true) ~= nil and clock:FindFirstChild("Day").Text:find("Día", 1, true) ~= nil, "La fecha y el día de tu historia")
check(clock and clock:FindFirstChild("Temp").Text:find("°C", 1, true) ~= nil and clock:FindFirstChild("Weather").Text == "Despejado", "Y el tiempo dentro de la cápsula («18°C», «Despejado»)")
check(playerGui:FindFirstChild("WeatherChip") == nil, "Sin la etiqueta suelta del tiempo")

-- GPS: ruta hasta el objetivo, indicación bajo la hora y la línea para los mapas
local gpsBanner = playerGui:FindFirstChild("GpsGui") and playerGui.GpsGui:FindFirstChild("GpsBanner")
check(gpsBanner and gpsBanner.Visible, "Indicación del GPS bajo la cápsula de la hora")
check(gpsBanner and gpsBanner.Instruction.Text:find("Gira a la derecha", 1, true) ~= nil, "«" .. (if gpsBanner then gpsBanner.Instruction.Text else "?") .. "» (hacia el norte y luego a la derecha)")
check(gpsBanner and gpsBanner.Distance.Text:find(" m · ", 1, true) ~= nil and gpsBanner.Distance.Text:find("min", 1, true) ~= nil, "Con la distancia y el tiempo («" .. (if gpsBanner then gpsBanner.Distance.Text else "?") .. "»)")
local gpsPath = mods.Gps.path()
check(gpsPath and #gpsPath >= 3, "La ruta va por las calles (gira en el cruce)")
local camera3 = fakeWorkspace.CurrentCamera
local arrows = camera3 and camera3:FindFirstChild("GpsRuta")
check(arrows and #arrows:GetChildren() <= 40 and #arrows:GetChildren() > 0, "Flechas en el suelo (" .. (if arrows then #arrows:GetChildren() else 0) .. " piezas, como mucho 40)")
gpsBanner.Clear.Activated:Fire()
mods.Gps.update()
check(gpsBanner.Visible == false and mods.Gps.path() == nil, "El botón × quita la ruta")
localPlayer:SetAttribute("StoryTarget", roblox.Vector3.new(150, 0, -201))
mods.Gps.update()
check(gpsBanner.Visible, "Un objetivo nuevo vuelve a poner la ruta")

-- Derecha: la misión
local remote = remotes:FindFirstChild("LifeStory")
remote.OnClientEvent:Fire("State", {
	Tracked = { QuestId = "Nino_Jornada", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", TextKey = "QUEST.DIA.LLEGA_COLE", Args = {} },
	Others = { { QuestId = "Eco_MateoDibujo", TitleKey = "QUEST.DIA_COLE.TITLE" }, { QuestId = "Loco_Nino_Chip", TitleKey = "QUEST.DIA_COLE.TITLE", Later = "AfterSchool" } },
})
local mission = hud and hud:FindFirstChild("Mission")
check(mission and mission.Visible and mission.Kind.Text == "MISIÓN PRINCIPAL", "Panel de la misión con «MISIÓN PRINCIPAL»")
check(mission and mission.Title.Text ~= "" and mission.Step.Text ~= "" and mission.Count.Text == "0/1", "Con el nombre, el paso («• …») y el contador «0/1»")
check(mission and mission:FindFirstChild("Chevron") ~= nil, "Y la flecha › para ver todas las misiones")
local popups = playerGui:FindFirstChild("HudPopups")
Hud.runCommand("Misiones")
local quests = popups and popups:FindFirstChild("Quests")
check(quests and textOf(quests, "MISIONES OPCIONALES"), "La flecha abre la lista de misiones (con las opcionales)")
check(quests and textOf(quests, "después del cole"), "Las misiones que esperan a que acabe el cole siguen en la lista, marcadas «🏫 después del cole»")
Hud.showQuests()
check(popups and popups:FindFirstChild("Quests") == quests, "«Ver mis misiones» (Hud.showQuests) no cierra la lista si ya está abierta")
Hud.runCommand("Misiones")
check(popups and popups:FindFirstChild("Quests") == nil, "Y se cierra otra vez")

-- Un encargo de la ciudad aceptado: el panel lo enseña (con la paga y «Dejar») y el ❓ también
localPlayer:SetAttribute("CityErrand", '{"Id":"Parque_Perro","Title":"¡Se ha escapado Trufa!","Giver":"Doña Amparo","Step":"Busca a Trufa por el parque","StepNum":1,"StepTotal":2,"Money":26,"Xp":16}')
localPlayer:SetAttribute("CityErrandTarget", roblox.Vector3.new(40, 0, 40))
check(mission and string.find(mission.Kind.Text, "ENCARGO", 1, true) ~= nil and string.find(mission.Title.Text, "Trufa", 1, true) ~= nil and mission.Step.Text == "Busca a Trufa por el parque" and mission.Quit.Visible, "Encargo de la ciudad en el panel: «ENCARGO», el paso y el botón «Dejar»")
local objective = Hud.objective()
check(objective ~= nil and objective.Kind == "ENCARGO" and objective.Target == roblox.Vector3.new(40, 0, 40), "«¿Qué hago ahora?» también habla del encargo")
Hud.runCommand("Misiones")
quests = popups and popups:FindFirstChild("Quests")
check(quests and textOf(quests, "ENCARGO DE LA CIUDAD") and textOf(quests, "Dejar el encargo"), "La lista de misiones enseña el encargo con su botón para dejarlo")
Hud.runCommand("Misiones")
localPlayer:SetAttribute("CityErrand", nil)
localPlayer:SetAttribute("CityErrandTarget", nil)
check(mission and mission.Kind.Text == "MISIÓN PRINCIPAL", "Al acabar el encargo vuelve la misión")

-- UNA sola guía (Controllers/Gps): la ruta que eliges tú (el aeropuerto) manda sobre la de la misión
-- en la indicación, la línea de los mapas y las flechas; la misión se atenúa con «📍 Ruta a …»
do
	local Gps, Guide = mods.Gps, mods.Guide
	local banner = playerGui.GpsGui.GpsBanner
	local chip = mission and mission:FindFirstChild("RouteChip")
	local airport = roblox.Vector3.new(-400, 0, 300)
	local function toastSaid(text: string): boolean
		local toastGui = playerGui:FindFirstChild("HudToasts")
		return toastGui ~= nil and textOf(toastGui, text)
	end
	local realDelay = fakeTask.delay
	fakeTask.delay = function(seconds, fn, ...) -- (el aviso espera al paso nuevo: aquí, en el momento)
		if seconds < 1 then
			fn(...)
		end
	end
	Gps.follow()
	Gps.update()
	check(banner.Visible and banner.Distance.Text:find("Tu misión", 1, true) ~= nil, "Sin ruta tuya, la indicación va a tu misión («" .. banner.Distance.Text .. "»)")
	check(chip and not chip.Visible and mission.Kind.Visible and Gps.missionMarker() ~= nil, "La tarjeta de la misión normal y el haz de luz / ★ en la misión")
	Gps.setManual(airport, "Aeropuerto de Valmar")
	Gps.update()
	local path = Gps.path()
	check(banner.Visible and banner.Distance.Text:find("📍 Aeropuerto de Valmar", 1, true) ~= nil and banner.Distance.Text:find("Tu misión", 1, true) == nil, "Eliges el aeropuerto: la indicación dice «" .. banner.Distance.Text .. "» (no «Tu misión»)")
	check(path and path[#path] == airport, "La línea de los mapas y las flechas del suelo van al aeropuerto")
	check(Gps.missionMarker() == nil, "El haz de luz y la ★ de la misión se esconden")
	check(chip and chip.Visible and chip.Text.Text == "📍 Ruta a Aeropuerto de Valmar" and not mission.Kind.Visible and mission.Title.TextTransparency > 0.3, "La tarjeta de la misión se queda, atenuada, con «📍 Ruta a Aeropuerto de Valmar»")
	check(chip and chip:FindFirstChild("Follow") and chip.Follow.Text:find("Seguir misión", 1, true) ~= nil, "Y su botón «Seguir misión ×»")
	-- La misión cambia de paso mientras vas: no te quita la ruta, solo avisa
	remote.OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Nino_Jornada", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", TextKey = "Ve al patio del colegio", Args = {} },
		Others = {},
	})
	localPlayer:SetAttribute("StoryTarget", roblox.Vector3.new(160, 0, -220))
	Gps.update()
	check(Gps.manual() ~= nil and banner.Distance.Text:find("Aeropuerto de Valmar", 1, true) ~= nil and Gps.missionMarker() == nil, "Un paso nuevo de la misión NO te quita la ruta al aeropuerto")
	local notice = Gps.lastNotice() or ""
	check(notice:find("Nueva misión: Ve al patio del colegio", 1, true) ~= nil and notice:find("toca para seguirla", 1, true) ~= nil, "Solo avisa: «" .. notice .. "»")
	local note = Guide.currentNote()
	check(note and note.Text:find("Nueva misión", 1, true) ~= nil and note.Button and note.Button:find("Seguir misión", 1, true) ~= nil, "El aviso sale en la nota de la guía, con «🧭 Seguir misión»")
	Guide.dismissNote()
	-- «Seguir misión ×» de la tarjeta: vuelve la guía de la misión
	chip.Follow.Activated:Fire()
	Gps.update()
	check(Gps.manual() == nil and banner.Distance.Text:find("Tu misión", 1, true) ~= nil and Gps.missionMarker() ~= nil, "«Seguir misión» quita tu ruta y vuelve sola la de la misión")
	check(not chip.Visible and mission.Kind.Visible and mission.Title.TextTransparency == 0, "La tarjeta vuelve a verse normal")
	check(toastSaid("Vuelves a la ruta de tu misión"), "Con el aviso «🧭 Vuelves a la ruta de tu misión»")
	-- × de la indicación con tu ruta: quita solo la tuya (la misión vuelve)
	Gps.setManual(airport, "Aeropuerto de Valmar")
	Gps.update()
	banner.Clear.Activated:Fire()
	Gps.update()
	check(Gps.manual() == nil and banner.Visible and banner.Distance.Text:find("Tu misión", 1, true) ~= nil, "× en la indicación quita tu ruta y vuelve la de la misión")
	-- Llegar a tu ruta: se quita sola, con aviso, y vuelve la misión
	Gps.setManual(roblox.Vector3.new(2, 0, -6), "Tu casa")
	Gps.update()
	check(Gps.manual() == nil and toastSaid("Has llegado: Tu casa · vuelve la ruta de tu misión"), "Al llegar, tu ruta se quita sola («📍 Has llegado: Tu casa · vuelve la ruta de tu misión»)")
	Gps.update()
	check(banner.Visible and banner.Distance.Text:find("Tu misión", 1, true) ~= nil and not chip.Visible, "Y la indicación vuelve a tu misión")
	fakeTask.delay = realDelay
end

-- Sin menú rápido junto al minimapa (sus apps son filas del menú de comandos: más abajo)
check(popups and popups:FindFirstChild("Phone") == nil and popups:FindFirstChild("PhoneButton") == nil, "Sin el menú rápido (ni su botón) junto al minimapa")
do
	local mini = HudLayout.rect(layout.Items.Minimap, layout.Canvas)
	local mrect = rectOf(mission, (function()
		layout.HudLayoutModule = HudLayout
		return layout
	end)())
	check(math.abs(mini.X + mini.W - (layout.Canvas.X - 16)) < 0.5 and mini.Y <= 10, "El minimapa pegado a la esquina de arriba a la derecha")
	check(math.abs(mrect.X + mrect.W - (layout.Canvas.X - 16)) < 0.5 and mrect.Y >= mini.Y + mini.H and mrect.Y - (mini.Y + mini.H) <= 12, "La misión justo debajo del minimapa, en el borde derecho")
end

-- El ValPhone (en lugar del menú COMANDOS): asoma abajo a la izquierda y todo el menú son sus apps.
-- Las acciones de ahora van en la tira de acciones, encima de las teclas (Commands/ContextStrip).
-- (con las prioridades del juego: Atacar 7, Objetos 50, Mapa 51, las apps 52-56 y Más 60)
local ran: { [string]: number } = {}
local function track(id: string)
	return function()
		ran[id] = (ran[id] or 0) + 1
	end
end
for name, priority in { Atacar = 7, Objetos = 50, Mapa = 51, Mas = 60, Extra = 61 } do
	CommandRegistry.register({ Id = name, Label = name, Icon = "espada", Priority = priority, Run = track(name) })
end
-- La app Ajustes (en el juego, «Menú» dentro de «Más») con un volumen (− / +, como los de
-- Controllers/AudioMix: de 0 a 10) y un sí/no
local musicLevel = 6
Hud.addMenuStepper("🎵 Música: 6", 1, function(delta: number): string
	musicLevel = math.clamp(musicLevel + delta, 0, 10)
	return "🎵 Música: " .. musicLevel
end)
local gpsOn = true
Hud.addMenuToggle("🧭 GPS: sí", 3.2, function()
	gpsOn = not gpsOn
	return if gpsOn then "🧭 GPS: sí" else "🧭 GPS: no"
end)
CommandRegistry.register({ Id = "Menu", Label = "Ajustes", Icon = "menu", Priority = 59.9, Screen = "Ajustes", Run = function() end } :: any)
-- Mensajes, con su punto rojo (como en DefaultCommands)
local PhoneInbox = loadModule("src/client/UI/PhoneInbox")
CommandRegistry.addProvider(function()
	local unread = PhoneInbox.unread()
	return { { Id = "Mensajes", Label = "Mensajes", Icon = "hablar", Priority = 50.2, Screen = "Mensajes", Badge = if unread > 0 then unread else nil } :: any }
end)
CommandMenu.refresh()
local phoneGui = playerGui:FindFirstChild("PhoneGui")
local peek = phoneGui and phoneGui:FindFirstChild("PhonePeek")
local body = phoneGui and phoneGui:FindFirstChild("ValPhone")
local function appTile(id: string)
	return deep(body, "App_" .. id)
end
check(playerGui:FindFirstChild("CommandMenuGui") == nil, "Ya no está el panel COMANDOS de la izquierda")
check(peek and peek.Visible and peek.AnchorPoint == roblox.Vector2.new(0, 1) and peek.Position.X.Offset == 16 and peek.Position.Y.Scale == 1 and peek.Position.Y.Offset == -16, "El ValPhone asoma abajo a la izquierda")
check(peek and textOf(peek, "ValPhone") and textOf(peek, "Tab"), "Con su marca («ValPhone», la de los carteles del metro) y su tecla (Tab)")
check(body and not body.Visible and body:GetAttribute("Open") == false, "Cerrado, el teléfono no tapa nada")
do
	local missing = {}
	for _, id in { "AppIr a casa", "AppTienda", "AppRuta a casa", "Mapa", "Objetos", "Mas", "Extra", "Menu", "Mensajes" } do
		if not appTile(id) then
			table.insert(missing, id)
		end
	end
	check(#missing == 0, "Todo el menú son apps del teléfono (Ir a casa, Tienda, Ruta a casa del GPS, Mapa, Mochila, Ajustes, Mensajes…)" .. (if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))
end
check(appTile("Objetos") and appTile("Objetos").Label.Text == "Mochila" and textOf(appTile("AppTienda").Tile, "🛒") and appTile("AppTienda").Label.Text == "Tienda", "Cada app con su nombre corto y su icono («Mochila», 🛒 «Tienda»)")
check(appTile("Mapa") and appTile("Mapa").Parent.Name == "Dock" and appTile("Menu").Parent.Name == "Dock" and appTile("Mensajes").Parent.Name == "Dock", "Mapa, Mensajes y Ajustes en el dock de abajo")
check(appTile("Atacar") == nil, "Las acciones de ahora (Atacar) no van dentro del teléfono")
-- Abrir: sube entero con un muelle
peek.Activated:Fire()
do
	local open = HudLayout.current().Items.PhoneOpen
	check(CommandMenu.isPhoneOpen() and body.Visible and body:GetAttribute("Open") and body.Position == open.Position and phoneGui.Scrim.Visible, "Tocarlo lo sube entero (y oscurece un poco el juego detrás)")
	local r = HudLayout.rect(open, layout.Canvas)
	check(r.Y >= 0 and r.X >= 0 and r.X + r.W < layout.Canvas.X / 3 and r.H >= 520 and math.abs(r.H / r.W - 2) < 0.05, ("Con forma de teléfono (%dx%d) y dentro de la pantalla"):format(r.W, r.H))
end
check(not peek.Visible, "Abierto, el que asoma se esconde")
check(textOf(body.Screen.StatusBar, "10:00") and body.Screen.StatusBar.Battery:GetAttribute("Level") == 25, "Barra de estado: la hora del juego y la batería (= tu energía: 25 %)")
check(textOf(body.Screen.Home.Widget, "ValPhone 12"), "Con el reloj grande y el modelo («ValPhone 12»)")
appTile("AppTienda").MouseEnter:Fire()
check(appTile("AppTienda").Tile.Ring.Visible, "Al pasar el ratón por una app se ilumina")
appTile("AppTienda").MouseLeave:Fire()
check(not appTile("AppTienda").Tile.Ring.Visible, "Y se apaga al salir")
appTile("AppTienda").Activated:Fire()
check(storeOpened() and not CommandMenu.isPhoneOpen() and peek.Visible, "La app Tienda guarda el teléfono y abre la tienda (como el botón de antes)")
peek.Activated:Fire()
appTile("Extra").Activated:Fire()
check(ran.Extra == 1 and not CommandMenu.isPhoneOpen(), "Cada app hace lo mismo que su fila de antes")
-- Ajustes: dentro del teléfono
peek.Activated:Fire()
appTile("Menu").Activated:Fire()
local appScreen = body.Screen.App
local musicRow = deep(appScreen, "Row1")
check(appScreen.Visible and appScreen.Header.Title.Text == "Ajustes" and textOf(appScreen, "Música") and textOf(appScreen, "SONIDO") and musicRow and musicRow.Parent.Name == "Card", "Ajustes se abre DENTRO del teléfono, por secciones (SONIDO) en tarjetas, con las opciones del menú")
do
	-- Volumen: − 6 + con botones grandes (≥ 44 px: cómodos con el dedo)
	local stepper = musicRow and musicRow:FindFirstChild("Stepper")
	local minus = stepper and stepper:FindFirstChild("Minus")
	local plus = stepper and stepper:FindFirstChild("Plus")
	local value = stepper and stepper:FindFirstChild("Value")
	check(minus and plus and value and value.Text == "6" and not textOf(appScreen, "Música: 6"), "Un volumen sale como − 6 + (no un texto «Música: 6»)")
	check(minus and plus and minus.Size.X.Offset >= 44 and minus.Size.Y.Offset >= 44 and plus.Size.X.Offset >= 44 and plus.Size.Y.Offset >= 44, "Los botones − y + miden al menos 44 × 44 (móvil)")
	minus.Activated:Fire()
	check(value.Text == "5" and musicLevel == 5 and CommandMenu.isPhoneOpen(), "− baja un paso (5) sin cerrar el teléfono")
	check(textOf(playerGui.HudPopups.Menu, "Música: 5"), "Y la ventana MENÚ dice lo mismo")
	for _ = 1, 8 do
		plus.Activated:Fire()
	end
	check(value.Text == "10" and musicLevel == 10 and plus:GetAttribute("Edge") == true, "+ no pasa de 10 (y el + se apaga en el tope)")
	for _ = 1, 14 do
		minus.Activated:Fire()
	end
	check(value.Text == "0" and musicLevel == 0 and minus:GetAttribute("Edge") == true, "− no baja de 0")
	local windowRow = deep(playerGui.HudPopups.Menu, "Stepper")
	check(windowRow and windowRow:FindFirstChild("Minus") and windowRow.Minus.Size.Y.Offset >= 44, "La ventana MENÚ también tiene − / + grandes")
	windowRow.Plus.Activated:Fire()
	windowRow.Plus.Activated:Fire()
	check(musicLevel == 2 and textOf(playerGui.HudPopups.Menu, "Música: 2"), "Y cambian el mismo volumen")
end
local gpsRow = deep(appScreen, "Row2")
check(gpsRow and gpsRow.Switch and gpsRow.Switch:GetAttribute("On") == true and not textOf(appScreen, "GPS: sí"), "Sí/no es un interruptor (encendido), no un texto «GPS: sí»")
gpsRow.Activated:Fire()
gpsRow = deep(appScreen, "Row2")
check(gpsRow and gpsRow.Switch:GetAttribute("On") == false and CommandMenu.isPhoneOpen(), "Tocarla apaga el interruptor sin cerrar el teléfono")
check(textOf(playerGui.HudPopups.Menu, "GPS: no"), "Y la ventana MENÚ dice lo mismo")
do
	-- Cómo se ven las opciones de verdad (Main.client) en Ajustes
	local SettingsRows = loadModule("src/client/Commands/SettingsRows")
	local noop = function()
		return ""
	end
	local rows, _, kinds = SettingsRows.build({
		{ Text = "📖 Mi historia", Order = 0, Press = noop },
		{ Text = "🎵 Música: 7", Order = 1, Press = noop },
		{ Text = "🗣️ Voces: 9", Order = 1.5, Press = noop },
		{ Text = "🔔 Efectos: 0", Order = 2, Press = noop },
		{ Text = "🌳 Ambiente: 5", Order = 2.1, Press = noop },
		{ Text = "👕 Ropa: mi avatar de Roblox", Order = 3, Press = noop },
		{ Text = "✨ Gráficos: Auto (Alto)", Order = 3.3, Press = noop },
		{ Text = "⚠️ Se borra la partida. Pulsa otra vez", Order = 4, Press = noop },
	}, "Auto")
	local sound = {}
	for i = 1, 4 do
		sound[i] = rows[i].Label .. "=" .. tostring(rows[i].Stepper and rows[i].Stepper.Value) .. (if kinds[i] == "Stepper" and rows[i].Section == "Sonido" then "" else "?")
	end
	check(table.concat(sound, " ") == "Música=7 Voces=9 Efectos=0 Ambiente=5", "Sonido primero: Música, Voces, Efectos y Ambiente con − / + de 0 a 10 (" .. table.concat(sound, " ") .. ")")
	check(rows[1].Stepper.Min == 0 and rows[1].Stepper.Max == 10, "De 0 a 10")
	check(rows[5].Label == "Gráficos" and kinds[5] == "Graphics" and rows[5].Selected == 1 and #rows[5].Segments == 4 and rows[5].Detail:find("Alto") ~= nil, "Gráficos: selector Auto · Bajo · Medio · Alto (y lo que usa ahora el Auto)")
	check(rows[6].Selected == 2 and rows[7].Action and rows[8].Danger and rows[8].Label == "Empezar una vida nueva" and rows[8].Detail:find("Pulsa otra vez") ~= nil, "Ropa con selector; Mi historia con flecha; la vida nueva en rojo, al final, y pidiendo confirmación")
end
appScreen.Header.Back.Activated:Fire()
check(not appScreen.Visible and body.Screen.Home.Visible and CommandMenu.isPhoneOpen(), "‹ vuelve al inicio")
appTile("Menu").Activated:Fire()
body.Screen.HomeBar.Activated:Fire()
check(not appScreen.Visible and body.Screen.Home.Visible and CommandMenu.isPhoneOpen(), "La barra de inicio también vuelve al inicio…")
body.Screen.HomeBar.Activated:Fire()
check(not CommandMenu.isPhoneOpen(), "…y en el inicio guarda el teléfono")
peek.Activated:Fire()
phoneGui.Scrim.Activated:Fire()
check(not CommandMenu.isPhoneOpen(), "Tocar fuera del teléfono lo guarda")
CommandMenu.toggle()
check(CommandMenu.isPhoneOpen(), "Tab (o Select del mando) lo abre…")
do
	-- Teclado / mando dentro: flechas para elegir app y Enter para abrirla
	local PhoneUI = loadModule("src/client/UI/Phone")
	PhoneUI.navigate(1, 0)
	local first = appTile("Objetos")
	check(first and first.Tile.Ring.Visible, "Las flechas (o la cruceta) eligen app: se ilumina la primera (Mochila)")
	PhoneUI.navigate(1, 0)
	check(first and not first.Tile.Ring.Visible, "…y se mueven a la siguiente")
	PhoneUI.navigate(-1, 0)
	PhoneUI.accept()
	check(ran.Objetos == 1 and not CommandMenu.isPhoneOpen(), "Enter (o A) abre la elegida (la mochila) y guarda el teléfono")
end
CommandMenu.toggle()
CommandMenu.toggle()
check(not CommandMenu.isPhoneOpen(), "…y Tab lo guarda")
-- Un mensaje con el teléfono guardado: baja una notificación y la app enciende su punto
local banner = phoneGui:FindFirstChild("PhoneBanner")
PhoneInbox.push({ Icon = "📱", From = "Abu Rosa", Text = "Abu Rosa quiere hablar contigo — bájate para hablar", Open = "Misiones" })
check(banner and banner.Visible and textOf(banner, "Abu Rosa quiere hablar contigo") and textOf(banner, "ABU ROSA"), "Un mensaje nuevo («📱 Abu Rosa quiere hablar contigo») baja como notificación del teléfono")
check(peek.Badge.Visible and peek.Badge.Count.Text == "1" and appTile("Mensajes").Tile.Badge.Visible, "El teléfono y la app Mensajes enseñan el aviso (1)")
banner.Hit.Activated:Fire()
check(CommandMenu.isPhoneOpen() and appScreen.Visible and appScreen.Header.Title.Text == "Mensajes" and textOf(appScreen, "Abu Rosa"), "Tocar la notificación abre Mensajes")
check(PhoneInbox.unread() == 0 and not banner.Visible, "Al verlo ya no queda nada sin leer")
CommandMenu.closePhone()
check(not peek.Badge.Visible and not appTile("Mensajes").Tile.Badge.Visible, "…y el aviso del teléfono se apaga")
-- Recompensas del pase por reclamar: aviso que baja del teléfono y punto rojo en su app
local passReady = false
CommandRegistry.addProvider(function()
	return { { Id = "PaseTemporada", Label = "Pase de temporada", Icon = "🏆", Priority = 55.5, Badge = passReady, Run = function() end } :: any }
end)
CommandMenu.refresh()
check(not banner.Visible, "Sin nada nuevo, ningún aviso")
passReady = true
CommandMenu.refresh()
check(banner.Visible and textOf(banner, "recompensas del pase") and appTile("PaseTemporada").Tile.Badge.Visible, "Recompensas del pase por reclamar: baja un aviso del teléfono y su app lleva el punto")
-- La tira de acciones: encima de las teclas, abajo a la derecha
local stripGui = playerGui:FindFirstChild("ContextStripGui")
local strip = stripGui and stripGui:FindFirstChild("ContextStrip")
check(strip and strip.Visible and strip:FindFirstChild("Chip1") and strip.Chip1.Label.Text == "Atacar", "Las acciones de ahora (Atacar) van en la tira de acciones")
check(strip and strip.AnchorPoint == roblox.Vector2.new(1, 1) and strip.Position == HudLayout.current().Items.Context.Position, "La tira, abajo a la derecha (encima de las teclas)")
check(strip and strip.Chip1.Key.Visible and strip.Chip1.Key.Text == "Enter", "La elegida va resaltada y dice su tecla («Enter»)")
strip.Chip1.Activated:Fire()
check(ran.Atacar == 1, "Hacer clic (o Enter) la hace")
CommandRegistry.register({ Id = "Saludar", Label = "Saludar", Icon = "saludar", Priority = 5, Run = track("Saludar") })
CommandMenu.refresh()
do
	local chipA, chipB = strip:FindFirstChild("Chip1"), strip:FindFirstChild("Chip2")
	check(chipA and chipB and chipA.Label.Text == "Saludar" and chipB.Label.Text == "Atacar", "Varias acciones: una píldora cada una, la más importante abajo del todo")
	if chipB then
		chipB.MouseEnter:Fire()
	end
	check(chipB and chipB.Parent == strip and chipB.Key.Visible and not chipA.Key.Visible, "Al pasar el ratón se elige otra (sin rehacer la tira bajo el ratón)")
	CommandRegistry.register({ Id = "Saludar", Label = "Saludar", Icon = "saludar", Priority = 5, When = function()
		return false
	end })
	CommandMenu.refresh()
end

-- Ordenador: sin botones táctiles ni joystick; lista de teclas
local touchGui = playerGui:FindFirstChild("TouchLayout")
local anyButton = false
for _, child in if touchGui then touchGui:GetChildren() else {} do
	if child:IsA("TextButton") then
		anyButton = true
	end
end
check(not anyButton, "Sin botones táctiles en el ordenador")
check(playerGui:FindFirstChild("JoystickGui") == nil, "Ni joystick")
local hints = touchGui and touchGui:FindFirstChild("Hints")
check(hints and hints.Visible and textOf(hints, "Espacio") and textOf(hints, "Saltar"), "En su lugar, la lista de teclas («Espacio · Saltar»)")

-- Conversaciones y bebé
Hud.setBusy(true)
CommandMenu.setBusy(true)
check(status.Visible == false and mission.Visible == false and not peek.Visible and not strip.Visible, "En una conversación se apartan estado, misión, el ValPhone y la tira de acciones")
Hud.setBusy(false)
CommandMenu.setBusy(false)
check(status.Visible and mission.Visible and peek.Visible and strip.Visible, "Y vuelven al acabar")
localPlayer:SetAttribute("LifeStage", "Bebe")
check(status.Visible == false and mission.Visible == false, "De bebé no hay estado ni misión")
localPlayer:SetAttribute("LifeStage", "Nino")

-- Avisos
Hud.toast("Money", "+50 $")
local toastGui = playerGui:FindFirstChild("HudToasts")
local toasts = toastGui and toastGui:FindFirstChild("Toasts")
check(toasts and textOf(toasts, "+50 $"), "Los avisos aparecen")
check(toastGui and (toastGui.DisplayOrder or 0) > 5, "Los avisos salen por encima de las ventanas")
check(#badWrites == 0, "Ninguna propiedad inventada al usarlo" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))

-- Primeros pasos y ❓ en el ordenador: botón para el ratón, tecla H y textos con teclas
do
	local helpGui = playerGui:FindFirstChild("HelpGui")
	local helpButton = helpGui and helpGui:FindFirstChild("HelpButton")
	local card = playerGui:FindFirstChild("GuideGui") and playerGui.GuideGui:FindFirstChild("TutorialCard")
	check(helpButton and helpButton.Visible and helpButton:FindFirstChild("Key") and helpButton.Key.Text == "H", "Ordenador: botón ❓ «¿Qué hago?» con su tecla H (junto a la misión)")
	check(hints and textOf(hints, "¿Qué hago?"), "Y la fila «H · ¿Qué hago?» en la lista de teclas")
	check(card and card.Visible and card.Text.Text:find("W A S D", 1, true) ~= nil, "La tarjeta de los primeros pasos, con las teclas («W A S D»)")
	userInput.InputBegan:Fire({ KeyCode = roblox.Enum.KeyCode.H, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
	local helpCard = helpGui and helpGui:FindFirstChild("HelpCard")
	check(helpCard and helpCard.Visible, "La tecla H abre «¿Qué hago ahora?»")
	userInput.InputBegan:Fire({ KeyCode = roblox.Enum.KeyCode.H, UserInputType = roblox.Enum.UserInputType.Keyboard }, false)
	check(helpCard and not helpCard.Visible, "Y la cierra")
end

-- Las balas del arma las coloca HudLayout (Items.Ammo), con la escala del HUD: antes iban en píxeles
-- fijos desde abajo (-330 en el móvil) y en un móvil apaisado quedaban encima del minimapa
do
	local weaponSrc = fs.readFile("src/client/Controllers/WeaponController.luau")
	check(weaponSrc:find("layout.Items.Ammo", 1, true) ~= nil and weaponSrc:find("HudLayout.scaleGui(ammoGui)", 1, true) ~= nil and weaponSrc:find("-330", 1, true) == nil, "Las balas del arma van donde dice HudLayout (Items.Ammo), a la escala del HUD")
end

-- Nada se pisa, en varios tamaños de ordenador
for _, size in { { 1920, 1080 }, { 1600, 900 }, { 1366, 768 } } do
	setViewport(size[1], size[2])
	local list, now = hudRects(mods)
	noOverlaps(list, HudLayout, ("%dx%d"):format(size[1], size[2]))
	local bar = HudLayout.rect(now.Items.Hotbar, now.Canvas)
	check(math.abs(bar.X + bar.W / 2 - now.Canvas.X / 2) < 0.5, ("%dx%d: barra rápida centrada"):format(size[1], size[2]))
end

---------------------------------------------------------------------
-- Móvil y tableta
---------------------------------------------------------------------
local bagToggles = 0 -- (veces que el botón Inventario abre la mochila)
-- Los textos de verdad de los botones del racimo (CombatController, Character, Stances…)
local CLUSTER_LABELS = { Ataque = "Atacar", Defender = "Defensa", Correr = "Correr", Agacharse = "Agacharse", Esquivar = "Esquivar" }
local function registerAll(TL)
	-- Los botones de siempre del racimo (los registran Combate, Correr, Stances…) y cinco de contexto a la vez
	for _, id in { "Ataque", "Defender", "Correr", "Agacharse", "Esquivar" } do
		TL.register({ Id = id, Icon = "espada", Label = CLUSTER_LABELS[id], Slot = id, Priority = 5, Callback = function() end })
	end
	for i, id in { "Linterna", "Foto", "Piedra", "Bajarse", "Sirena" } do
		TL.register({ Id = id, Icon = "linterna", Label = id, Priority = 10 + i, Callback = function() end, Badge = if id == "Piedra" then function()
			return "×3"
		end else nil })
	end
	-- Inventario, como lo registra Controllers/InventoryUI (aquí no se monta la mochila)
	TL.register({
		Id = "Inventario", Icon = "mochila", Label = "Inventario", Slot = "Inventario", Shape = "Side", Priority = 2,
		Visible = function()
			return not TL.isDriving() and not TL.isFlying()
		end,
		Callback = function()
			bagToggles += 1
		end,
	})
end

-- El centro y el rectángulo (en el lienzo) de un botón
local function centerOf(button, layout)
	local r = rectOf(button, layout)
	return r.X + r.W / 2, r.Y + r.H / 2, r
end

-- Comprueba que los botones visibles caben en la pantalla
local function insideScreen(list, layout, where: string)
	local out = {}
	for _, item in list do
		local r = item.Rect
		if r.X < -0.5 or r.Y < -0.5 or r.X + r.W > layout.Canvas.X + 0.5 or r.Y + r.H > layout.Canvas.Y + 0.5 then
			table.insert(out, item.Name .. describe(r))
		end
	end
	check(#out == 0, where .. ": nada se sale de la pantalla" .. (if #out > 0 then ": " .. table.concat(out, ", ") else ""))
end

for _, size in { { 640, 360 }, { 667, 375 }, { 844, 390 }, { 932, 430 }, { 1334, 750 }, { 1846, 852 }, { 2400, 1080 }, { 1024, 768 } } do
	print(("\n▶ En el móvil / tableta (%dx%d)"):format(size[1], size[2]))
	local touchStore
	mods, ok, err, touchStore = mount(true, size[1], size[2])
	HudLayout, TouchLayout, CommandMenu, CommandRegistry = mods.HudLayout, mods.TouchLayout, mods.CommandMenu, mods.CommandRegistry
	check(ok, "Se monta sin errores" .. (if ok then "" else ": " .. tostring(err)))
	check(#badWrites == 0, "Todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
	bagToggles = 0
	registerAll(TouchLayout)
	local ranTouch: { [string]: number } = {}
	local function trackTouch(id: string)
		return function()
			ranTouch[id] = (ranTouch[id] or 0) + 1
		end
	end
	for name, priority in { Atacar = 7, Objetos = 50, Mapa = 51, Mas = 60 } do
		CommandRegistry.register({ Id = name, Label = name, Icon = "espada", Priority = priority, Run = trackTouch(name) })
	end
	-- Mensajes con 3 sin leer (el globito rojo del botón Teléfono)
	CommandRegistry.register({ Id = "Mensajes", Label = "Mensajes", Icon = "hablar", Priority = 50.2, Screen = "Mensajes", Badge = 3 } :: any)
	CommandMenu.refresh()
	TouchLayout.refresh()
	local buttons = TouchLayout.buttons()
	local visible = 0
	for _, button in buttons do
		if button.Visible then
			visible += 1
		end
	end
	check(visible == 14, "Racimo de 6 (Correr, Defensa, Saltar, Agacharse, Atacar, Esquivar: sin «Interactuar» aparte), 5 de contexto, el ❓, Teléfono e Inventario (" .. visible .. ")")
	check(buttons.Ayuda and buttons.Ayuda.Visible and buttons.Ayuda:FindFirstChild("Caption").Text == "¿Qué hago?", "Botón ❓ «¿Qué hago?» junto a la misión")
	local guideCard = playerGui:FindFirstChild("GuideGui") and playerGui.GuideGui:FindFirstChild("TutorialCard")
	check(guideCard and guideCard.Visible, "Jugador nuevo: la tarjeta de los primeros pasos se ve (y entra en la prueba de que nada se pisa)")
	check(buttons.Saltar and buttons.Saltar.Visible and buttons.Saltar:FindFirstChild("Caption").Text == "Saltar", "Botón Saltar propio (icono y texto)")
	check(buttons.Ataque and buttons.Ataque.Size.X.Offset > buttons.Correr.Size.X.Offset, "El Atacar es el botón grande")
	check(buttons.Piedra and buttons.Piedra.Badge.Visible and buttons.Piedra.Badge.Text == "×3", "Numerito en la esquina (piedras «×3»)")
	local now = HudLayout.current()
	now.HudLayoutModule = HudLayout
	local stick = playerGui:FindFirstChild("JoystickGui")
	stick = stick and stick:FindFirstChild("Joystick")
	check(stick and stick.Visible and localPlayer.DevTouchMovementMode == roblox.Enum.DevTouchMovementMode.Scriptable, "Joystick propio (en lugar del de Roblox)")
	local stickRect = stick and rectOf(stick, now)
	check(stickRect and stickRect.X < now.Canvas.X * 0.3 and stickRect.Y + stickRect.H > now.Canvas.Y * 0.8, "El joystick abajo a la izquierda")
	check(stick and #stick:GetChildren() > 0 and stick:FindFirstChild("Knob") ~= nil, "Joystick redondo con flechas y pomo en el centro")

	-- El racimo SIN arma, como la referencia (docs/referencias/hud-movil-botones.jpg), con Interactuar
	-- fusionado en el Atacar grande: en medio Correr, Defensa y Saltar; abajo Agacharse, el Atacar grande
	-- en el centro y Esquivar (arriba a la derecha, la burbuja «Acciones» cuando hay acciones)
	do
		local want = { Correr = "Correr", Defender = "Defensa", Saltar = "Saltar", Agacharse = "Agacharse", Ataque = "Atacar", Esquivar = "Esquivar" }
		local inCluster = {}
		for id, button in buttons do
			local slot = button:GetAttribute("Slot")
			if button.Visible and slot and HudLayout.Cluster[slot] and slot ~= "Contexto" and id ~= "Contexto" then
				table.insert(inCluster, id)
			end
		end
		table.sort(inCluster)
		local wrong = {}
		for id, caption in want do
			local b = buttons[id]
			if not (b and b.Visible and b:GetAttribute("Slot") == id and b.Caption.Text == caption) then
				table.insert(wrong, id)
			end
		end
		check(#inCluster == 6 and #wrong == 0, ("Sin arma, el racimo tiene exactamente los 6 de la referencia (%s)%s"):format(table.concat(inCluster, ", "), if #wrong > 0 then "; mal: " .. table.concat(wrong, ", ") else ""))
		local c = {}
		for id in want do
			local x, y, r = centerOf(buttons[id], now)
			c[id] = { X = x, Y = y, R = r.W / 2 }
		end
		local tol = 6
		local middle = math.abs(c.Correr.Y - c.Defender.Y) < tol and math.abs(c.Defender.Y - c.Saltar.Y) < tol and c.Correr.X < c.Defender.X and c.Defender.X < c.Saltar.X
		local bottom = c.Agacharse.X < c.Ataque.X and c.Ataque.X < c.Esquivar.X and math.abs(c.Agacharse.Y - c.Esquivar.Y) < tol and math.abs(c.Agacharse.Y - c.Ataque.Y) < c.Ataque.R
		local order = c.Saltar.Y < c.Ataque.Y
		local centered = math.abs(c.Defender.X - c.Ataque.X) < tol
		local biggest = true
		for id in want do
			if id ~= "Ataque" and c[id].R >= c.Ataque.R then
				biggest = false
			end
		end
		check(middle, "Fila del medio: Correr, Defensa y Saltar, a la misma altura y en ese orden")
		check(bottom, "Fila de abajo: Agacharse, el Atacar y Esquivar, en ese orden")
		check(order and centered, "La Defensa encima del Atacar")
		check(not (buttons.Interactuar and buttons.Interactuar.Visible), "Ya no hay botón «Interactuar» aparte en el racimo (sin nada cerca, no sale)")
		check(biggest, "El Atacar es el más grande")
		check(not buttons.Gestos and not buttons.Fijar, "Ni Gestos ni Fijar en el racimo (Gestos y Foto son apps del ValPhone)")
	end

	-- Abajo a la izquierda: Teléfono e Inventario debajo del joystick, con el texto al lado
	local phoneGui = playerGui:FindFirstChild("PhoneGui")
	local peek = phoneGui and phoneGui:FindFirstChild("PhonePeek")
	do
		local tel, bag = buttons.Telefono, buttons.Inventario
		check(peek and not peek.Visible, "En el móvil el ValPhone ya no asoma: lo abre el botón Teléfono")
		check(tel and tel.Visible and tel.Caption.Text == "Teléfono" and bag and bag.Visible and bag.Caption.Text == "Inventario", "Botones «Teléfono» e «Inventario» con su texto")
		if tel and bag and stickRect then
			local tr, br = rectOf(tel, now), rectOf(bag, now)
			check(tr.Y >= stickRect.Y + stickRect.H - 0.5 and br.Y >= stickRect.Y + stickRect.H - 0.5 and tr.X < br.X and math.abs(tr.Y - br.Y) < 1, "Debajo del joystick, uno al lado del otro (Teléfono a la izquierda)")
			check(tr.X <= 16.5 and now.Canvas.Y - (tr.Y + tr.H) <= 16.5, "Pegados a la esquina de abajo a la izquierda")
			check(math.min(tr.W, tr.H) * now.Scale >= 30, ("Se tocan bien con el pulgar (%d px)"):format(math.min(tr.W, tr.H) * now.Scale))
			local disc = tel:FindFirstChild("Disc")
			check(disc and disc.Badge.Visible and disc.Badge.Text == "3" and disc.Badge.BackgroundColor3 == roblox.Color3.fromRGB(255, 59, 48), "Teléfono con el globito rojo de avisos sin leer («3»)")
			bag.Activated:Fire()
			check(bagToggles == 1, "Inventario abre la mochila")
		end
	end
	-- La burbuja «Acciones», arriba a la derecha del racimo (donde estaba Interactuar). «Atacar» ya es el
	-- botón grande: no sale dos veces
	local bubble = buttons.Contexto
	check(bubble == nil or not bubble.Visible, "Sin duplicados: con «Atacar» como única acción, no sale otro «Atacar» pequeño")
	CommandRegistry.register({ Id = "Atacar", Label = "Atacar", Icon = "espada", Priority = 7, When = function()
		return false
	end })
	CommandRegistry.register({ Id = "Lanzar", Label = "Lanzar", Icon = "espada", Priority = 7, Run = trackTouch("Lanzar") })
	CommandMenu.refresh()
	TouchLayout.refresh()
	bubble = TouchLayout.buttons().Contexto
	check(bubble and bubble.Visible and bubble:GetAttribute("Slot") == "Interactuar" and bubble.Caption.Text == "Lanzar" and not bubble.Badge.Visible, "La burbuja de acciones arriba a la derecha del racimo, con la acción de ahora («Lanzar»)")
	if bubble and buttons.Saltar and buttons.Defender then
		local bx, by = centerOf(bubble, now)
		local sx, sy = centerOf(buttons.Saltar, now)
		local dx = centerOf(buttons.Defender, now)
		check(by < sy and bx > dx, "…encima de Saltar, a la derecha de la Defensa (como el botón de arriba de la referencia)")
	end
	if bubble then
		-- Un dedo que ya estaba apoyado cuando la burbuja pasó a «Lanzar» no la usa
		bubble.Activated:Fire()
	end
	check(ranTouch.Lanzar == nil or ranTouch.Lanzar == 0, "Un toque que empezó antes de que la burbuja cambiara no hace la acción")
	if bubble then
		tap(bubble)
	end
	check(ranTouch.Lanzar == 1, "Con una sola acción, un toque la hace")

	CommandRegistry.register({ Id = "Saludar", Label = "Saludar", Icon = "saludar", Priority = 5, Run = trackTouch("Saludar") })
	CommandMenu.refresh()
	TouchLayout.refresh()
	check(bubble and bubble.Badge.Visible and bubble.Badge.Text == "2" and bubble.Caption.Text == "Acciones", "Con varias: «Acciones» y cuántas hay (2)")
	local stripGui = playerGui:FindFirstChild("ContextStripGui")
	local strip = stripGui and stripGui:FindFirstChild("ContextStrip")
	check(strip and not strip.Visible, "La lista de acciones no tapa nada hasta que se pide")
	if bubble then
		tap(bubble)
	end
	check(strip and strip.Visible and strip:FindFirstChild("Chip1") and strip:FindFirstChild("Chip2") and strip.Chip1.Label.Text == "Saludar", "Un toque en la burbuja abre la lista de acciones")
	do
		local sr = strip and rectOf(strip, now)
		local br = bubble and rectOf(bubble, now)
		check(sr and br and sr.X + sr.W <= br.X and sr.Y + sr.H <= br.Y + br.H + 0.5 and sr.Y >= 0, "…a la izquierda de la burbuja, hacia arriba")
	end
	if strip and strip:FindFirstChild("Chip1") then
		strip.Chip1.Activated:Fire()
	end
	check(ranTouch.Saludar == 1 and not strip.Visible, "Un toque en una acción la hace y la lista se cierra")
	if bubble then
		bubble.Activated:Fire()
	end
	strip.Parent.ContextScrim.Activated:Fire()
	check(not strip.Visible, "Tocar fuera la cierra sin hacer nada")
	CommandRegistry.register({ Id = "Saludar", Label = "Saludar", Icon = "saludar", Priority = 5, When = function()
		return false
	end })
	CommandMenu.refresh()
	-- El teléfono: sube por la izquierda sin tapar los botones ni la barra rápida
	if buttons.Telefono then
		buttons.Telefono.Activated:Fire()
	end
	do
		local openRect = HudLayout.rect(now.Items.PhoneOpen, now.Canvas)
		local covers = {}
		local tl = TouchLayout.buttons()
		check(not tl.Telefono.Visible and not tl.Inventario.Visible, "Abierto, Teléfono e Inventario se esconden debajo (se cierra tocando fuera)")
		for name, slot in now.Slots do
			if name ~= "Ayuda" and not HudLayout.Left[name] and HudLayout.overlaps(openRect, HudLayout.rect(slot, now.Canvas)) then
				table.insert(covers, name)
			end
		end
		if HudLayout.overlaps(openRect, HudLayout.rect(now.Items.Hotbar, now.Canvas)) then
			table.insert(covers, "Barra rápida")
		end
		check(CommandMenu.isPhoneOpen() and openRect.Y >= 0 and #covers == 0, "Abierto, el ValPhone sube por la izquierda sin tapar los botones ni la barra rápida" .. (if #covers > 0 then ": tapa " .. table.concat(covers, ", ") else ""))
		local tienda = phoneGui and deep(phoneGui.ValPhone, "App_AppTienda")
		local home = phoneGui and deep(phoneGui.ValPhone, "App_AppIr a casa")
		check(tienda and home and tienda.Label.Text == "Tienda", "Con las apps (Ir a casa, Tienda…)")
		if tienda then
			tienda.Activated:Fire()
		end
		check(touchStore and touchStore() and not CommandMenu.isPhoneOpen(), "Y la app Tienda abre la tienda, como el botón de antes")
		local back = TouchLayout.buttons()
		check(back.Telefono.Visible and back.Inventario.Visible, "Al cerrarse vuelven Teléfono e Inventario")
	end
	local popupsGui = playerGui:FindFirstChild("HudPopups")
	check(popupsGui:FindFirstChild("Phone") == nil and popupsGui:FindFirstChild("PhoneButton") == nil, "Sin el menú rápido ni su botón junto al minimapa")
	do
		now.HudLayoutModule = HudLayout
		local mini = HudLayout.rect(now.Items.Minimap, now.Canvas)
		local mrect = HudLayout.rect(now.Items.Mission, now.Canvas)
		check(math.abs(mini.X + mini.W - (now.Canvas.X - 16)) < 0.5 and mini.Y <= 10, "El minimapa pegado a la esquina de arriba a la derecha")
		check(math.abs(mrect.X + mrect.W - (now.Canvas.X - 16)) < 0.5 and mrect.Y >= mini.Y + mini.H and mrect.Y - (mini.Y + mini.H) <= 12, "La misión justo debajo del minimapa")
		local bar = HudLayout.rect(now.Items.Hotbar, now.Canvas)
		check(now.Canvas.Y - (bar.Y + bar.H) <= 8.5 and math.abs(bar.X + bar.W / 2 - now.Canvas.X / 2) < 0.5, "La barra rápida centrada y pegada al borde de abajo")
		-- El racimo, pegado a la esquina de abajo a la derecha
		local right, bottom = 0, 0
		for name, slot in now.Slots do
			if name ~= "Ayuda" then
				local r = HudLayout.rect(slot, now.Canvas)
				right = math.max(right, r.X + r.W)
				bottom = math.max(bottom, r.Y + r.H)
			end
		end
		check(now.Canvas.X - right <= 16.5 and now.Canvas.Y - bottom <= 20, ("Los botones pegados a la esquina de abajo a la derecha (a %d y %d del borde)"):format(now.Canvas.X - right, now.Canvas.Y - bottom))
	end
	local list = hudRects(mods)
	noOverlaps(list, HudLayout, ("%dx%d"):format(size[1], size[2]))
	insideScreen(list, now, ("%dx%d"):format(size[1], size[2]))
	-- El botón grande contextual (estilo shooter móvil): sin nada cerca es «Atacar»; con un cartel cerca
	-- (hablar con alguien, comer, coger…) pasa a ser esa acción, con su texto, y al tocarlo la hace (el
	-- cartel de Roblox ya no tiene toque propio en el móvil). En una pelea sigue siendo «Atacar» y el
	-- cartel va al botón pequeño; un enemigo de misión nunca cuenta como cartel.
	local pps = services.ProximityPromptService
	local talkPart = newInstance("Part")
	rawget(talkPart, "__props").Position = roblox.Vector3.new(0, 3, -12)
	talkPart.Parent = fakeWorkspace
	local talk = newInstance("ProximityPrompt")
	for key, value in { Enabled = true, MaxActivationDistance = 10, ActionText = "Hablar", ObjectText = "Papá", HoldDuration = 0, KeyboardKeyCode = roblox.Enum.KeyCode.E, GamepadKeyCode = roblox.Enum.KeyCode.ButtonX } do
		rawget(talk, "__props")[key] = value
	end
	local talkHolds = 0
	rawset(talk, "InputHoldBegin", function()
		talkHolds += 1
	end)
	rawset(talk, "InputHoldEnd", function() end)
	talk.Parent = talkPart
	do
		local tl = TouchLayout.buttons()
		check(tl.Ataque and tl.Ataque.Visible and tl.Ataque:GetAttribute("Slot") == "Ataque" and tl.Ataque.Caption.Text == "Atacar", "Sin cartel cerca: el botón grande es «Atacar»")
		pps.PromptShown:Fire(talk, roblox.Enum.ProximityPromptInputType.Touch)
		CommandMenu.refresh()
		TouchLayout.refresh()
		tl = TouchLayout.buttons()
		local big = tl.Interactuar
		check(big and big.Visible and big:GetAttribute("Slot") == "Ataque" and big.Caption.Text == "Hablar" and not tl.Ataque.Visible, "Con un cartel cerca: el botón grande dice «Hablar» (su ActionText) y el Atacar se aparta")
		check(big and big.Size.X.Offset == tl.Ataque.Size.X.Offset and big.Size.X.Offset > tl.Correr.Size.X.Offset, "…con el tamaño del botón grande")
		local inExtras = false
		for _, button in tl do
			local slot = tostring(button:GetAttribute("Slot"))
			if button.Visible and string.sub(slot, 1, 5) == "Extra" and button.Caption.Text == "Atacar" then
				inExtras = true
			end
		end
		check(not inExtras, "…y el Atacar no baja a la columna pequeña")
		-- Un toque justo cuando el botón acaba de cambiar a «Hablar» (iba para el Atacar) no habla:
		-- nada se usa solo al acercarse (MenuLogic.armed)
		if big then
			big.Activated:Fire()
		end
		check(talkHolds == 0, "Un toque justo cuando el botón grande acaba de cambiar no dispara el cartel")
		-- El pulgar ya estaba apoyado (iba para el Atacar) y se queda ahí mientras el botón pasa a
		-- «Hablar»: al soltarlo, tampoco (el toque empezó antes de que cambiara)
		if big then
			big.InputBegan:Fire({ UserInputType = roblox.Enum.UserInputType.Touch, UserInputState = roblox.Enum.UserInputState.Begin, Position = roblox.Vector3.zero })
			TouchLayout.setLabel("Interactuar", "Leer")
			waitReal(0.5)
			big.Activated:Fire()
		end
		check(talkHolds == 0, "Un pulgar apoyado antes de que el botón pasara a «Leer» no lo abre al soltar")
		TouchLayout.setLabel("Interactuar", "Hablar")
		waitReal(0.5)
		if big then
			tap(big)
		end
		check(talkHolds == 1, "Tocar el botón grande dispara el cartel (como la tecla E)")
		local list = hudRects(mods)
		noOverlaps(list, HudLayout, ("%dx%d con «Hablar» en el botón grande"):format(size[1], size[2]))
		insideScreen(list, now, ("%dx%d con «Hablar» en el botón grande"):format(size[1], size[2]))
		-- En plena pelea (enemigo fijado o golpes hace nada): sigue «Atacar» y el cartel va al pequeño
		TouchLayout.setFightCheck(function()
			return true
		end)
		TouchLayout.refresh()
		tl = TouchLayout.buttons()
		check(tl.Ataque.Visible and tl.Ataque:GetAttribute("Slot") == "Ataque" and tl.Ataque.Caption.Text == "Atacar" and tl.Interactuar.Visible and string.sub(tostring(tl.Interactuar:GetAttribute("Slot")), 1, 5) == "Extra" and tl.Interactuar.Caption.Text == "Hablar", "En plena pelea el grande sigue siendo «Atacar» y «Hablar» va en la columna pequeña")
		TouchLayout.setFightCheck(nil)
		-- Al alejarse vuelve el Atacar
		pps.PromptHidden:Fire(talk)
		CommandMenu.refresh()
		TouchLayout.refresh()
		tl = TouchLayout.buttons()
		check(tl.Ataque.Visible and tl.Ataque:GetAttribute("Slot") == "Ataque" and not tl.Interactuar.Visible, "Al alejarse vuelve «Atacar»")
		-- Un enemigo de misión (MissionEnemy) con cartel: nunca cambia el botón
		local enemy = newInstance("Model")
		enemy:SetAttribute("MissionEnemy", "Cucarachas")
		enemy.Parent = fakeWorkspace
		local enemyPart = newInstance("Part")
		rawget(enemyPart, "__props").Position = roblox.Vector3.new(1, 3, -11)
		enemyPart.Parent = enemy
		local enemyPrompt = newInstance("ProximityPrompt")
		for key, value in { Enabled = true, MaxActivationDistance = 10, ActionText = "Lanzar globo", HoldDuration = 0, KeyboardKeyCode = roblox.Enum.KeyCode.E, GamepadKeyCode = roblox.Enum.KeyCode.ButtonX } do
			rawget(enemyPrompt, "__props")[key] = value
		end
		enemyPrompt.Parent = enemyPart
		pps.PromptShown:Fire(enemyPrompt, roblox.Enum.ProximityPromptInputType.Touch)
		CommandMenu.refresh()
		TouchLayout.refresh()
		tl = TouchLayout.buttons()
		check(tl.Ataque.Visible and tl.Ataque.Caption.Text == "Atacar" and not tl.Interactuar.Visible, "Un enemigo de misión nunca cuenta como cartel: sigue «Atacar»")
		pps.PromptHidden:Fire(enemyPrompt)
		enemy.Parent = nil
		-- (el cartel de «Hablar» vuelve para la prueba del arma)
		pps.PromptShown:Fire(talk, roblox.Enum.ProximityPromptInputType.Touch)
		CommandMenu.refresh()
	end
	-- Con un arma de fuego (estilo shooter móvil, como los registra Controllers/WeaponController): el
	-- Atacar grande pasa a ser Disparar, Apuntar encima, Recargar con las balas en el hueco de
	-- Interactuar y un segundo Disparar a la derecha del joystick. Agacharse, Saltar y Esquivar siguen.
	do
		local armedNow = true
		localPlayer:SetAttribute("Weapon", "Pistola")
		local function armedFn()
			return armedNow
		end
		-- (CombatController esconde Atacar y Defensa con el arma en la mano en el móvil)
		TouchLayout.register({ Id = "Ataque", Icon = "espada", Label = "Atacar", Slot = "Ataque", Priority = 3, Visible = function()
			return not armedNow
		end, Callback = function() end })
		TouchLayout.register({ Id = "Defender", Icon = "escudo", Label = "Defensa", Slot = "Defender", Priority = 4, Visible = function()
			return not armedNow
		end, Hold = function() end })
		local held, dragged = 0, roblox.Vector2.new(0, 0)
		TouchLayout.register({ Id = "Disparar", Icon = "disparar", Label = "Disparar", Slot = "Disparar", Priority = 1, Visible = armedFn, Hold = function(down)
			held += if down then 1 else -1
		end, Drag = function(delta)
			dragged += delta
		end })
		TouchLayout.register({ Id = "DispararIzq", Icon = "disparar", Label = "Disparar", Slot = "DispararIzq", Priority = 1, Twin = true, Visible = armedFn, Hold = function() end, Drag = function() end } :: any)
		TouchLayout.register({ Id = "Apuntar", Icon = "objetivo", Label = "Apuntar", Slot = "Apuntar", Priority = 1, Visible = armedFn, Callback = function() end })
		TouchLayout.register({ Id = "Recargar", Icon = "recargar", Label = "Recargar", Slot = "Recargar", Priority = 0.5, Visible = armedFn, Badge = function()
			return "12/90"
		end, Callback = function() end })
		TouchLayout.refresh()
		local tl = TouchLayout.buttons()
		local function at(id: string, slot: string): boolean
			return tl[id] ~= nil and tl[id].Visible and tl[id]:GetAttribute("Slot") == slot
		end
		check(at("Disparar", "Ataque") and tl.Disparar.Caption.Text == "Disparar" and (tl.Ataque == nil or not tl.Ataque.Visible), "Con arma: el botón grande pasa a ser «Disparar»")
		check(at("Apuntar", "Defender") and (tl.Defender == nil or not tl.Defender.Visible), "Apuntar encima del disparo (en el sitio de Defensa)")
		check(at("Recargar", "Interactuar") and tl.Recargar.Badge.Visible and tl.Recargar.Badge.Text == "12/90", "Recargar con las balas («12/90») en el sitio de Interactuar")
		check(at("DispararIzq", "DispararIzq") and tl.DispararIzq.Caption.Text == "Disparar", "Segundo «Disparar» en el lado izquierdo")
		check(at("Agacharse", "Agacharse") and at("Saltar", "Saltar") and at("Esquivar", "Esquivar") and at("Correr", "Correr"), "Agacharse, Saltar, Esquivar y Correr siguen en el racimo")
		check(tl.Interactuar.Visible and string.sub(tostring(tl.Interactuar:GetAttribute("Slot")), 1, 5) == "Extra" and tl.Interactuar.Caption.Text == "Hablar", "Con arma y un cartel cerca: sigue «Disparar» y «Hablar» va en la columna pequeña")
		if stickRect then
			local x, y, r = centerOf(tl.DispararIzq, now)
			local sx, sy = stickRect.X + stickRect.W / 2, stickRect.Y + stickRect.H / 2
			check(x > sx and y < sy and not HudLayout.overlaps(r, stickRect) and r.X + r.W < now.Canvas.X / 2, "El Disparar de la izquierda, arriba a la derecha del joystick (pulgar izquierdo)")
		end
		-- Arrastrar el dedo que mantiene Disparar ya NO gira nada (aunque el botón traiga un Drag viejo): la
		-- cámara la gira la de Roblox con otro dedo. Otro dedo (el joystick) no suelta el gatillo
		do
			local E = roblox.Enum
			local finger = { UserInputType = E.UserInputType.Touch, Position = roblox.Vector3.new(700, 300, 0) }
			local other = { UserInputType = E.UserInputType.Touch, Position = roblox.Vector3.new(80, 300, 0) }
			tl.Disparar.InputBegan:Fire(finger)
			finger.Position = roblox.Vector3.new(730, 290, 0)
			userInput.InputChanged:Fire(finger)
			other.Position = roblox.Vector3.new(120, 300, 0)
			userInput.InputChanged:Fire(other)
			userInput.InputEnded:Fire(other)
			check(held == 1 and dragged == roblox.Vector2.new(0, 0), "Arrastrar el dedo de Disparar no gira la cámara (sigue el gatillo pulsado); otro dedo no lo suelta")
			userInput.InputEnded:Fire(finger)
			check(held == 0, "Al levantar ese dedo se suelta el gatillo")
		end
		local armedList = hudRects(mods)
		noOverlaps(armedList, HudLayout, ("%dx%d con arma"):format(size[1], size[2]))
		insideScreen(armedList, now, ("%dx%d con arma"):format(size[1], size[2]))
		-- Al guardar el arma vuelve el racimo normal
		armedNow = false
		localPlayer:SetAttribute("Weapon", nil)
		TouchLayout.refresh()
		tl = TouchLayout.buttons()
		check(at("Interactuar", "Ataque") and tl.Interactuar.Caption.Text == "Hablar", "Al guardar el arma, con el cartel aún cerca, el grande vuelve a ser «Hablar»")
		pps.PromptHidden:Fire(talk)
		talkPart.Parent = nil
		CommandMenu.refresh()
		TouchLayout.refresh()
		tl = TouchLayout.buttons()
		check(at("Ataque", "Ataque") and at("Defender", "Defender") and not tl.Interactuar.Visible and not tl.Disparar.Visible and not tl.DispararIzq.Visible and not tl.Apuntar.Visible and not tl.Recargar.Visible, "Al guardar el arma vuelve el racimo normal")
		-- Un botón quitado (o vuelto a registrar) ya no escucha a UserInputService: sus conexiones
		-- InputEnded/InputChanged se cortan (antes se quedaban vivas y se iban acumulando)
		local ghost = { UserInputType = roblox.Enum.UserInputType.Touch, Position = roblox.Vector3.new(700, 300, 0) }
		tl.Disparar.InputBegan:Fire(ghost)
		local heldBefore, draggedBefore = held, dragged
		for _, id in { "Disparar", "DispararIzq", "Apuntar", "Recargar" } do
			TouchLayout.unregister(id)
		end
		ghost.Position = roblox.Vector3.new(760, 280, 0)
		userInput.InputChanged:Fire(ghost)
		userInput.InputEnded:Fire(ghost)
		check(heldBefore == 1 and held == heldBefore and dragged == draggedBefore, "Al quitar un botón se desconectan sus InputEnded/InputChanged (no responde a un dedo después)")
		registerAll(TouchLayout)
	end
	-- Al volante (móvil): flechas ◀ ▶ a la izquierda (sin joystick) y, a la derecha, ACELERAR, FRENO,
	-- freno de mano, luces, intermitentes, emergencia, Bajarse y el claxon (UI/DriveButtons y
	-- HudLayout.Drive). Todo grande, al alcance del pulgar y sin pisar nada.
	do
		local DriveButtons = loadModule("src/client/UI/DriveButtons")
		local held: { [string]: boolean } = {}
		local calls: { string } = {}
		local status = { Lights = 0, Indicator = "", Hazard = false, Parked = false, Reversing = false }
		DriveButtons.register(TouchLayout, {
			Driving = function()
				return true
			end,
			Kind = function()
				return "Coche"
			end,
			Hold = function(slot, down)
				held[slot] = down
			end,
			Lights = function(long)
				table.insert(calls, if long then "Largas" else "Luces")
			end,
			Indicator = function(side)
				table.insert(calls, side)
			end,
			Status = function()
				return status
			end,
		})
		-- (como Controllers/Vehicles y SoundFx: Bajarse y el claxon tienen hueco al volante)
		TouchLayout.register({ Id = "Bajarse", Icon = "bajarse", Label = "Bajarse", Slot = "Correr", DriveSlot = "Bajarse", Priority = 4, Callback = function() end })
		TouchLayout.register({ Id = "Claxon", Icon = "claxon", Label = "Claxon", Slot = "Gestos", DriveSlot = "Claxon", Priority = 2.5, Callback = function() end })
		-- (los botones de ir a pie se esconden solos en un vehículo: aquí se quitan)
		for _, id in { "Ataque", "Defender", "Correr", "Agacharse", "Esquivar" } do
			TouchLayout.unregister(id)
		end
		mods.Joystick.setDriving(true)
		TouchLayout.setDriving(true)
		mods.CommandMenu._state().Vehicle() -- (en el juego lo avisa el atributo Riding, o la revisión de cada 0,4 s)
		local driveButtons = TouchLayout.buttons()
		local want = { "GiroIzq", "GiroDer", "Acelerar", "Frenar", "FrenoMano", "Luces", "IntIzq", "IntDer", "Emergencia", "Bajarse", "Claxon" }
		local missing = {}
		for _, id in want do
			local b = driveButtons[id]
			if not (b and b.Visible and b:GetAttribute("Slot") == id) then
				table.insert(missing, id)
			end
		end
		check(#missing == 0, "Al volante: flechas, pedales, freno de mano, luces, intermitentes, emergencia, Bajarse y claxon en su sitio" .. (if #missing > 0 then " (faltan: " .. table.concat(missing, ", ") .. ")" else ""))
		local joy = playerGui:FindFirstChild("JoystickGui")
		joy = joy and joy:FindFirstChild("Joystick")
		check(joy and joy.Visible == false, "Al volante el joystick se esconde (se gira con las flechas)")
		local drive = HudLayout.current()
		drive.HudLayoutModule = HudLayout
		local function rectFor(id: string)
			return rectOf(driveButtons[id], drive)
		end
		local gas, brake = rectFor("Acelerar"), rectFor("Frenar")
		local left, right = rectFor("GiroIzq"), rectFor("GiroDer")
		check(drive.Canvas.X - (gas.X + gas.W) <= 16.5 and drive.Canvas.Y - (gas.Y + gas.H) <= 16.5 and gas.H >= 1.8 * gas.W and brake.X + brake.W <= gas.X and brake.H < gas.H,
			"ACELERAR alto en la esquina de abajo a la derecha y FRENO a su izquierda (más bajo)")
		check(left.X + left.W <= right.X and right.X + right.W < drive.Canvas.X * 0.3 and drive.Canvas.Y - (left.Y + left.H) <= 20, "Las flechas ◀ ▶ abajo a la izquierda (donde estaba el joystick)")
		local small = {}
		for _, id in { "Acelerar", "Frenar", "GiroIzq", "GiroDer" } do
			local r = rectFor(id)
			if math.min(r.W, r.H) * drive.Scale < 44 then
				table.insert(small, ("%s %d px"):format(id, math.min(r.W, r.H) * drive.Scale))
			end
		end
		check(#small == 0, "Pedales y flechas grandes para el pulgar (44 px o más)" .. (if #small > 0 then ": " .. table.concat(small, ", ") else ""))
		local arrowIcon = driveButtons.GiroIzq:FindFirstChild("Icon")
		check(arrowIcon and arrowIcon.Rotation == 180 and driveButtons.GiroDer:FindFirstChild("Icon").Rotation == 0, "Las flechas se dibujan (◀ y ▶), sin depender de la fuente")
		noOverlaps(hudRects(mods), HudLayout, ("%dx%d al volante"):format(size[1], size[2]))
		-- El ValPhone al volante: asoma debajo de tu estado (abajo van las flechas); en marcha no se abre
		do
			local vehicle = mods.CommandMenu._state().Vehicle
			vehicle()
			local phonePeek = playerGui.PhoneGui.PhonePeek
			local spot = HudLayout.rect(drive.Items.PhoneDrive, drive.Canvas)
			local r = rectOf(phonePeek, drive)
			check(phonePeek.Visible and math.abs(r.X - spot.X) < 0.5 and math.abs(r.Y - spot.Y) < 0.5, "Al volante el ValPhone asoma debajo de tu estado (sin tapar las flechas)")
			noOverlaps(hudRects(mods), HudLayout, ("%dx%d al volante, con el ValPhone"):format(size[1], size[2]))
			local seat = newInstance("Part")
			rawget(seat, "__props").AssemblyLinearVelocity = roblox.Vector3.new(18, 0, 0)
			rawget(humanoid, "__props").SeatPart = seat
			vehicle()
			check(phonePeek:GetAttribute("Locked") == true and mods.CommandMenu.openPhone() == false and not mods.CommandMenu.isPhoneOpen(), "En marcha el teléfono no se abre (nunca tapa los mandos)")
			rawget(seat, "__props").AssemblyLinearVelocity = roblox.Vector3.new(0, 0, 0)
			vehicle()
			check(mods.CommandMenu.openPhone() and mods.CommandMenu.isPhoneOpen(), "Parado sí se abre")
			rawget(seat, "__props").AssemblyLinearVelocity = roblox.Vector3.new(0, 0, 25)
			vehicle()
			check(not mods.CommandMenu.isPhoneOpen(), "Y si arrancas con él abierto, se guarda solo")
			rawget(humanoid, "__props").SeatPart = nil
			-- «Bajarse» como única acción de ahora: el botón Bajarse de siempre se queda en su sitio
			local Registry = mods.CommandRegistry
			Registry.register({ Id = "Atacar", Label = "Atacar", Icon = "espada", Priority = 7, When = function()
				return false
			end })
			Registry.register({ Id = "BajarseCmd", Label = "Bajarse", Icon = "bajarse", Priority = 6, Run = function() end })
			mods.CommandMenu.refresh()
			TouchLayout.refresh()
			local b = TouchLayout.buttons()
			check(b.Bajarse and b.Bajarse.Visible and b.Bajarse:GetAttribute("Slot") == "Bajarse" and not (b.Contexto and b.Contexto.Visible), "Con «Bajarse» en las acciones, el botón Bajarse sigue en su sitio al volante (sin repetirlo)")
			Registry.register({ Id = "BajarseCmd", Label = "Bajarse", Icon = "bajarse", Priority = 6, When = function()
				return false
			end })
			Registry.register({ Id = "Atacar", Label = "Atacar", Icon = "espada", Priority = 7, Run = function() end })
			mods.CommandMenu.refresh()
			TouchLayout.refresh()
		end
		-- Mantener pulsado: varios dedos a la vez (acelerar y girar)
		local gasTouch = { UserInputType = roblox.Enum.UserInputType.Touch, UserInputState = roblox.Enum.UserInputState.Begin }
		local leftTouch = { UserInputType = roblox.Enum.UserInputType.Touch, UserInputState = roblox.Enum.UserInputState.Begin }
		driveButtons.Acelerar.InputBegan:Fire(gasTouch)
		driveButtons.GiroIzq.InputBegan:Fire(leftTouch)
		check(held.Gas == true and held.Left == true, "Acelerar y girar a la vez (dos dedos)")
		userInput.InputEnded:Fire(leftTouch)
		check(held.Left == false and held.Gas == true, "Al soltar la flecha deja de girar, sin soltar el acelerador")
		userInput.InputEnded:Fire(gasTouch)
		check(held.Gas == false, "Y al soltar el pedal deja de acelerar")
		local lightTouch = { UserInputType = roblox.Enum.UserInputType.Touch, UserInputState = roblox.Enum.UserInputState.Begin }
		driveButtons.Luces.InputBegan:Fire(lightTouch)
		userInput.InputEnded:Fire(lightTouch)
		driveButtons.IntIzq.Activated:Fire()
		driveButtons.Emergencia.Activated:Fire()
		check(calls[1] == "Luces" and calls[2] == "L" and calls[3] == "H", "Tocar Luces enciende las luces; los intermitentes y la emergencia responden")
		status.Lights, status.Indicator, status.Hazard, status.Reversing = 2, "L", true, true
		TouchLayout.refresh()
		check(driveButtons.Luces.Badge.Visible and driveButtons.Luces.Badge.Text == "Largas" and driveButtons.Frenar.Badge.Text == "R", "Con las largas, «Largas» en el botón; marcha atrás, «R» en el freno")
		-- Fuera del coche todo vuelve a su sitio
		TouchLayout.setDriving(false)
		mods.Joystick.setDriving(false)
		for _, id in DriveButtons.Ids do
			TouchLayout.unregister(id)
		end
		TouchLayout.unregister("Claxon")
		registerAll(TouchLayout)
		check(joy and joy.Visible and TouchLayout.buttons().Ataque.Visible and TouchLayout.buttons().GiroIzq == nil, "Al bajarse vuelven el joystick y los botones de ir a pie")
	end
	-- A los mandos de un avión (móvil): como la nave del espacio (queja del dueño: «los controles del avión,
	-- la interfaz y todo, debe ser igual que el de las naves espaciales»). La palanca analógica a la
	-- izquierda (UI/FlightStick); a la derecha, redondos como los de la nave, MOTOR + (el más grande),
	-- MOTOR − y FRENOS (UI/FlyButtons en HudLayout.Fly); y el HUD de la nave (UI/AirCombatHud con
	-- Variant = "Plane", Controllers/PlaneHudClient): perfil, brújula, panel del avión, radar, misiones y
	-- la barra de ranuras FLAPS, TREN, CÁMARA, PALANCA y BAJARSE (el botón del tren vuelve). Nada se pisa.
	do
		local FlyButtons = loadModule("src/client/UI/FlyButtons")
		local ACH = loadModule("src/client/UI/AirCombatHud")
		local SHL = loadModule("src/client/UI/ShipHudLayout")
		local PHC = loadModule("src/client/Controllers/PlaneHudClient")
		local FlightM = loadModule("src/shared/Flight")
		local flyHolds: { [string]: boolean } = {}
		local status = { Throttle = 0.4, Gear = true, FixedGear = false, Flaps = 1, Brake = false, Camera = "Persecucion", CanExit = true }
		FlyButtons.register(TouchLayout, {
			Flying = function()
				return true
			end,
			Hold = function(slot, down)
				flyHolds[slot] = down
			end,
			Status = function()
				return status
			end,
		})
		TouchLayout.setFlying(true)
		local view = PHC.new(playerGui, true)
		ACH.setEnabled(view, true)
		-- Captura del dueño (v116, avioneta): el avatar del perfil era un puntito (ancho 0 con la restricción
		-- de aspecto), «Nv. 100» y «10.000.014 €» se metían encima del nombre, y volando hacia el sur la N
		-- del radar caía encima de «RADAR 0,7 km»
		do
			local P = view.Profile
			local avatarSize = P.Avatar.Size
			local fits = P.Level.TextScaled and P.Money.TextScaled and P.Level:FindFirstChildOfClass("UITextSizeConstraint") ~= nil and P.Money:FindFirstChildOfClass("UITextSizeConstraint") ~= nil
			-- (el letrero del alcance va fuera del aro, abajo a la izquierda: la N abajo no lo pisa)
			local label = view.RadarLabel
			local aside = label.Position.X.Scale < 0.3 and label.AnchorPoint.X == 1
			check(avatarSize.X.Scale == 1 and avatarSize.Y.Scale == 1 and fits and aside,
				"Perfil y radar sin solapes: avatar del alto del panel, nivel y dinero encogen para caber, «RADAR» fuera del camino de la N")
		end
		local tapped: { string } = {}
		view.OnSlot = function(id)
			table.insert(tapped, id)
		end
		local flyButtons = TouchLayout.buttons()
		local slotOf = { MotorMas = "MotorMas", MotorMenos = "MotorMenos", Frenos = "Frenos" }
		local missing = {}
		for id, slot in slotOf do
			local b = flyButtons[id]
			if not (b and b.Visible and b:GetAttribute("Slot") == slot) then
				table.insert(missing, id)
			end
		end
		check(#missing == 0, "Volando: MOTOR +, MOTOR − y FRENOS en su sitio (como IMPULSO y FRENO de la nave)" .. (if #missing > 0 then " (faltan: " .. table.concat(missing, ", ") .. ")" else ""))
		check(flyButtons.TimonIzq == nil and flyButtons.TimonDer == nil and flyButtons.Tren == nil and flyButtons.Flaps == nil, "Volando no hay botones de timón (la palanca lo hace) y el tren y los flaps van en las ranuras del HUD")
		local walking = {}
		for _, id in { "Ataque", "Interactuar", "Saltar", "Correr", "Linterna" } do
			local b = flyButtons[id]
			if b and b.Visible then
				table.insert(walking, id)
			end
		end
		check(#walking == 0, "Volando no salen los botones de ir a pie" .. (if #walking > 0 then " (salen: " .. table.concat(walking, ", ") .. ")" else ""))
		local fly = HudLayout.current()
		fly.HudLayoutModule = HudLayout
		-- Las zonas del HUD de la nave con los botones del avión (y la palanca): nada se pisa
		local l = SHL.compute(roblox.Vector2.new(size[1], size[2]), { Touch = true, Inset = 58, Vehicle = "Plane", Buttons = SHL.PlaneButtonSlots })
		local clash = SHL.clashes(l)
		local nButtons = 0
		for _ in l.Buttons do
			nButtons += 1
		end
		if size[1] == 932 then
			-- (y en el ordenador: las mismas zonas, con la tarjeta de teclas y sin palanca)
			local pc = SHL.compute(roblox.Vector2.new(1920, 1080), { Touch = false, Inset = 58, Vehicle = "Plane" })
			local pcClash = SHL.clashes(pc)
			check(#pcClash == 0 and pc.Zones.Keys ~= nil and pc.Zones.Jump == nil and pc.Stick == nil, "1920x1080 volando (ordenador): las zonas del HUD del avión (sin salto) no se pisan; teclas y sin palanca" .. (if #pcClash > 0 then ": " .. table.concat(pcClash, ", ") else ""))
			local keys, takeoff = PHC.hints("Keyboard", true)
			local pad = PHC.hints("Gamepad", true)
			check(keys[1].Key == "W / S" and #takeoff >= 5 and string.find(pad[1].Text, "Atrás sube", 1, true) ~= nil, "Listas de teclas del avión (mandos y «despegar y aterrizar»; con mando, el stick hacia atrás sube el morro)")
		end
		check(#clash == 0 and nButtons == 3 and l.Zones.Jump == nil, ("%dx%d volando: las zonas del HUD del avión (perfil, brújula, velocidad, estructura, radar, misiones, pista, ranuras) no pisan MOTOR, FRENOS ni la palanca%s"):format(size[1], size[2], if #clash > 0 then ": " .. table.concat(clash, ", ") else ""))
		-- Los botones de verdad, donde dice el HUD (y sin pisar la zona de la palanca)
		do
			local zone = HudLayout.rect(fly.Items.FlightZone, fly.Canvas)
			local ring = HudLayout.rect(fly.Items.FlightStick, fly.Canvas)
			local bad = {}
			for id in slotOf do
				local r = rectOf(flyButtons[id], fly)
				if HudLayout.overlaps(r, zone) then
					table.insert(bad, id .. "/zona")
				end
				for name, z in l.Zones do
					if name ~= "Quantum" and SHL.overlaps(r, z) then
						table.insert(bad, id .. "/" .. name)
					end
				end
			end
			check(#bad == 0 and ring.W * fly.Scale >= 80 and zone.W >= fly.Canvas.X * 0.45,
				("Volando: la palanca (mitad izquierda, aro de %d px) y los botones sin pisar las zonas del HUD%s"):format(ring.W * fly.Scale, if #bad > 0 then " (" .. table.concat(bad, ", ") .. ")" else ""))
		end
		local small = {}
		for id in slotOf do
			local r = rectOf(flyButtons[id], fly)
			if math.min(r.W, r.H) * fly.Scale < (if size[1] <= 700 then 32 else 44) then
				table.insert(small, ("%s %d px"):format(id, math.min(r.W, r.H) * fly.Scale))
			end
		end
		local slotPt = l.SlotSize * l.Scale
		check(#small == 0 and slotPt >= (if size[1] <= 700 then 32 else 44), ("Mandos del avión grandes para el pulgar (ranuras de %d pt)"):format(slotPt) .. (if #small > 0 then ": " .. table.concat(small, ", ") else ""))
		local gasR = rectOf(flyButtons.MotorMas, fly)
		local minusR = rectOf(flyButtons.MotorMenos, fly)
		check(fly.Canvas.X - (gasR.X + gasR.W) <= 24 and gasR.W >= minusR.W, "MOTOR + el más grande, pegado a la derecha (donde la nave tiene DISPARO)")
		-- Mantener el motor y soltarlo
		local gasTouch = { UserInputType = roblox.Enum.UserInputType.Touch, UserInputState = roblox.Enum.UserInputState.Begin }
		flyButtons.MotorMas.InputBegan:Fire(gasTouch)
		check(flyHolds.ThrottleUp == true, "Mantener MOTOR + da gas")
		userInput.InputEnded:Fire(gasTouch)
		check(flyHolds.ThrottleUp == false, "Y al soltarlo deja de dar gas")
		check(flyButtons.MotorMas.Meter.Visible, "Barrita del gas en MOTOR +")
		-- Ranuras: FLAPS, TREN (también en la avioneta), CÁMARA, PALANCA y BAJARSE; se tocan
		local st = { Flaps = 1, MaxFlaps = 2, Gear = true, FixedGear = false, OnGround = false, Camera = "Persecucion", PullUp = true, CanExit = false, Throttle = 0.5 }
		ACH.setSlots(view, PHC.slots(st), "Touch")
		local names = {}
		for i, s in view.Slots do
			names[i] = s.Name.Text
		end
		check(#view.Slots == 8 and names[1] == "FLAPS" and names[2] == "TREN ↓" and names[3] == "FRENO APARC." and names[4] == "CÁMARA" and names[5] == "↓ SUBE" and names[6] == "RALENTÍ" and names[7] == "A TOPE" and names[8] == "Para el avión" and view.Slots[1].Count.Text == "1",
			"Ranuras del avión: FLAPS (1), TREN ↓, FRENO APARC., CÁMARA, PALANCA (↓ sube), RALENTÍ, A TOPE y BAJARSE (parado): " .. table.concat(names, " · "))
		view.Slots[2].Button.Activated:Fire()
		view.Slots[1].Button.Activated:Fire()
		check(tapped[1] == "Gear" and tapped[2] == "Flaps", "Tocar TREN y FLAPS en la barra los cambia")
		check(not FlightM.Specs.Avioneta.FixedGear, "La avioneta también tiene TREN (retráctil)")
		-- El panel del avión (zona C)
		ACH.setPlane(view, { Speed = 120, Altitude = 84.4, Heading = 271, Climb = -2.4, Throttle = 0.75, Gear = false, Flaps = 2, Brake = false, Health = 80, Warn = "Perdida", OnGround = false, Stalled = true })
		local V = view.Values
		check(V.Speed.Text == "120" and V.Boost.Text == "75%" and V.Energy.Text == "84 m" and V.Flares.Text == "▼ 2.4 m/s" and V.Hull.Text == "80%" and V.Missiles.Text == "271° O" and string.find(V.Weapon.Text, "FLAPS 2", 1, true) ~= nil and string.find(V.Weapon.Text, "TREN ↑", 1, true) ~= nil,
			("Panel del avión: VEL, MOTOR, ALTITUD, V/S, ESTRUCTURA, RUMBO, flaps y tren (%s · %s · %s)"):format(V.Speed.Text, V.Energy.Text, V.Weapon.Text))
		local cap = view.Zones.Speed:FindFirstChild("BoostCaption")
		check(cap and cap.Text == "MOTOR" and view.Gui.Name == "PlaneHud" and view.Vehicle == "Plane", "El arco de velocidad lleva el MOTOR (donde la nave el IMPULSO); vehículo «Plane»")
		check(string.find(view.Warning.Text, "PÉRDIDA", 1, true) ~= nil and view.Chips.Mode.Text == "⚠ PÉRDIDA", "Aviso de PÉRDIDA (zona J) y el chip del estado")
		ACH.setPlane(view, { Speed = 60, Altitude = 0, Heading = 270, Climb = 0, Throttle = 1, Gear = true, Flaps = 2, Brake = false, Health = 100, Warn = "FinPista", OnGround = true })
		check(string.find(view.Warning.Text, "FIN DE PISTA", 1, true) ~= nil and view.Chips.Mode.Text == "EN TIERRA", "Aviso FIN DE PISTA en tierra")
		-- La ayuda para despegar (letrero y flecha de la palanca), según el ajuste y el aparato
		local A = FlightM.Specs.Avioneta
		local sim = FlightM.new("Avioneta", roblox.CFrame.new())
		sim.Speed, sim.Throttle, sim.Cue = A.Vr + 3, 1, "Rotar"
		local c1 = PHC.cue(sim, A, true, "Touch")
		local c2 = PHC.cue(sim, A, false, "Touch")
		local c3 = PHC.cue(sim, A, true, "Keyboard")
		check(c1 and c1.Stick == "Down" and string.find(c1.Title, "TIRA HACIA ABAJO PARA DESPEGAR", 1, true) ~= nil and c2 and c2.Stick == "Up" and c3 and string.find(c3.Title, "PULSA W", 1, true) ~= nil,
			"Ayuda para despegar: «TIRA HACIA ABAJO PARA DESPEGAR» con la flecha hacia abajo (hacia arriba con el ajuste en No; «PULSA W» en el ordenador)")
		sim.Cue, sim.Speed, sim.Throttle = nil, 0, 0
		local c4 = PHC.cue(sim, A, true, "Touch")
		sim.OnGround = false
		check(c4 and string.find(c4.Title, "MOTOR + A TOPE", 1, true) ~= nil and c4.Stick == nil and PHC.cue(sim, A, true, "Touch") == nil, "Parado en tierra: «PARA DESPEGAR: MOTOR + A TOPE»; en el aire, ninguna ayuda")
		ACH.setPrompt(view, c1.Title, c1.Sub, c1.Progress, c1.Color)
		check(view.Prompt.Frame.Visible and view.Prompt.Title.Text == c1.Title, "La ayuda sale en el letrero encima de las ranuras")
		-- Al bajarse vuelve todo
		TouchLayout.setFlying(false)
		FlyButtons.unregister(TouchLayout)
		view.Gui:Destroy()
		view.Overlay:Destroy()
		registerAll(TouchLayout)
		check(TouchLayout.buttons().Ataque.Visible and TouchLayout.buttons().MotorMas == nil, "Al bajarse del avión vuelven los botones de ir a pie")
	end
	do
		-- Las balas (arma en la mano): arriba a la derecha, a la izquierda del minimapa, dentro de la
		-- pantalla y lejos de los botones de disparar (la captura: encima del minimapa)
		local ammo = HudLayout.rect(now.Items.Ammo, now.Canvas)
		local mini = HudLayout.rect(now.Items.Minimap, now.Canvas)
		local clockRect = HudLayout.rect(now.Items.Clock, now.Canvas)
		check(ammo.X >= clockRect.X + clockRect.W and ammo.X + ammo.W <= mini.X and ammo.Y >= 0 and ammo.Y + ammo.H <= mini.Y + mini.H, ("Balas del arma %s: entre el reloj y el minimapa, sin pisar nada"):format(describe(ammo)))
		-- La pista («Pista: …  [Toca para ir]») encima de la barra rápida, sin pisarla ni pisar los botones
		local guideRect = HudLayout.rect(now.Items.Guide, now.Canvas)
		local bar = HudLayout.rect(now.Items.Hotbar, now.Canvas)
		local clash = {}
		for name, slot in now.Slots do
			if HudLayout.overlaps(guideRect, HudLayout.rect(slot, now.Canvas)) then
				table.insert(clash, name)
			end
		end
		check(guideRect.Y + guideRect.H <= bar.Y and #clash == 0, "La pista va encima de la barra rápida sin pisar los botones" .. (if #clash > 0 then ": " .. table.concat(clash, ", ") else ""))
	end

	-- Nunca dos botones iguales (la captura tenía dos «Agacharse»)
	do
		TouchLayout.register({ Id = "Agacharse", Icon = "agacharse", Label = "Agacharse", Priority = 10.5, Callback = function() end })
		TouchLayout.register({ Id = "Agacharse", Icon = "agacharse", Label = "Agacharse", Priority = 10.5, Callback = function() end })
		TouchLayout.register({ Id = "AgacharseCopia", Icon = "agacharse", Label = "Agacharse", Priority = 10.6, Callback = function() end })
		TouchLayout.refresh()
		local count = 0
		for _, button in TouchLayout.buttons() do
			if button.Visible and button:FindFirstChild("Caption") and button.Caption.Text == "Agacharse" then
				count += 1
			end
		end
		check(count == 1, ("Un solo botón «Agacharse» aunque se registre dos veces o con otro nombre (%d)"):format(count))
		TouchLayout.unregister("Agacharse")
		TouchLayout.unregister("AgacharseCopia")
	end

	-- Paneles de trabajo (UI/HudLayout.jobPanel): a la derecha del menú de comandos, entre tu estado y
	-- la barra rápida, por encima de los comandos (DisplayOrder 3); si es alto, su lista se desplaza
	do
		local Theme = loadModule("src/client/UI/Theme")
		local jobGui = Instance.new("ScreenGui")
		jobGui.Name = "PruebaTrabajo"
		jobGui.Parent = playerGui
		Theme.fit(jobGui)
		local jobPanel = Theme.panel({ Name = "Panel", Size = roblox.UDim2.fromOffset(300, 400), Parent = jobGui })
		Theme.padding(8).Parent = jobPanel
		Theme.label({ Size = roblox.UDim2.new(1, 0, 0, 22), Text = "🛎️ Recepción", Parent = jobPanel })
		HudLayout.jobPanel(jobPanel)
		local k = jobGui:FindFirstChildOfClass("UIScale").Scale
		local sc = now.Scale
		local jobRect = {
			X = jobPanel.Position.X.Offset * k / sc,
			Y = jobPanel.Position.Y.Offset * k / sc,
			W = jobPanel.Size.X.Offset * k / sc,
			H = jobPanel.Size.Y.Offset * k / sc,
		}
		local clashes = {}
		for _, other in hudRects(mods) do
			if HudLayout.overlaps(jobRect, other.Rect) and other.Name ~= "Tarjeta de primeros pasos" then
				table.insert(clashes, other.Name .. describe(other.Rect))
			end
		end
		check(#clashes == 0 and jobRect.Y + jobRect.H <= now.Canvas.Y, ("Panel de trabajo %s: no pisa estado, comandos, joystick, barra rápida ni botones%s"):format(describe(jobRect), if #clashes > 0 then ": " .. table.concat(clashes, ", ") else ""))
		check(jobGui.DisplayOrder == 3 and jobPanel:FindFirstChild("JobScroll") and jobPanel.JobScroll.CanvasSize.Y.Offset == 400 - 16, "Encima de los comandos (DisplayOrder 3) y, si no cabe entero, con lista que se desplaza")
		check(k >= 0.8 - 1e-6, ("Textos del panel a escala %.2f (antes 0,6)"):format(k))
		jobGui:Destroy()
	end

	-- Más botones de contexto que huecos (con un arma): el último hueco es «Más» y pasa de página
	do
		for _, id in { "Extra6", "Extra7" } do
			TouchLayout.register({ Id = id, Icon = "linterna", Label = id, Priority = 40, Callback = function() end })
		end
		local tl = TouchLayout.buttons()
		local more = tl.MasBotones
		check(more and more.Visible and more:GetAttribute("Slot") == "Extra5" and (tl.Extra7 == nil or not tl.Extra7.Visible), "Con 7 botones de contexto: 4 a la vista y «Más» en el último hueco")
		if more then
			more.Activated:Fire()
			tl = TouchLayout.buttons()
			check(tl.Extra7 and tl.Extra7.Visible and tl.Extra6 and tl.Extra6.Visible and not tl.Linterna.Visible, "«Más» enseña los que faltaban")
			more.Activated:Fire()
		end
		TouchLayout.unregister("Extra6")
		TouchLayout.unregister("Extra7")
		check(not TouchLayout.buttons().MasBotones.Visible and TouchLayout.buttons().Sirena.Visible, "Con 5 o menos, sin «Más»")
	end

	-- Nadando (DivingUI → TouchLayout.setSwimming): fuera pelear y gestos; Bucear en el hueco grande
	do
		local Swim = require("../src/shared/Swim")
		local swimming = false
		TouchLayout.register({ Id = "BucearBajar", Icon = "bajarse", Label = "Bucear", Slot = "Ataque", Priority = 8, Visible = function()
			return swimming
		end, Hold = function() end })
		TouchLayout.register({ Id = "BucearSubir", Icon = "flecha", Label = "Subir", Slot = "Defender", Priority = 7, Visible = function()
			return swimming
		end, Hold = function() end })
		swimming = true
		TouchLayout.setSwimming(true, Swim.HiddenButtons)
		local tl = TouchLayout.buttons()
		local combatGone = not tl.Ataque.Visible and not tl.Defender.Visible and not tl.Esquivar.Visible and (tl.Agacharse == nil or not tl.Agacharse.Visible)
		check(combatGone and tl.Saltar.Visible and tl.Correr.Visible, "Nadando: fuera Ataque, Defensa, Esquivar y Agacharse; quedan Saltar y Correr")
		check(tl.BucearBajar.Visible and tl.BucearBajar:GetAttribute("Slot") == "Ataque" and tl.BucearSubir.Visible and tl.BucearSubir:GetAttribute("Slot") == "Defender", "Bucear en el hueco grande y Subir al lado")
		swimming = false
		TouchLayout.setSwimming(false)
		tl = TouchLayout.buttons()
		check(tl.Ataque.Visible and tl.Defender.Visible and not tl.BucearBajar.Visible and tl.Ataque:GetAttribute("Slot") == "Ataque", "Al salir del agua vuelven los de siempre")
		TouchLayout.unregister("BucearBajar")
		TouchLayout.unregister("BucearSubir")
	end

	-- Con un arma en la mano los avisos (hambre, «arma de servicio…») suben bajo el reloj, más pequeños y
	-- como mucho dos: no tapan la mira del centro
	do
		local toastsGui = playerGui:FindFirstChild("HudToasts")
		local list = toastsGui and toastsGui:FindFirstChild("Toasts")
		localPlayer:SetAttribute("Weapon", "PistolaAgua")
		for i = 1, 3 do
			mods.Hud.toast("Info", "Aviso con arma " .. i)
		end
		local shown = 0
		for _, child in if list then list:GetChildren() else {} do
			if child:IsA("Frame") then
				shown += 1
			end
		end
		local top = list and list.Position.Y.Offset or 0
		local bottom = top + 2 * 46 * 0.8
		check(list and shown <= 2 and top == now.Items.Activity.Position.Y.Offset and bottom < now.Canvas.Y / 2 - 60, ("Con arma, los avisos van arriba bajo el reloj (%d-%d de %d), como mucho dos (%d): no tapan la mira"):format(top, bottom, now.Canvas.Y, shown))
		localPlayer:SetAttribute("Weapon", nil)
		check(list and list.Position.Y.Offset > top, "Al guardar el arma vuelven a su sitio")
	end

	-- Ventanas del HUD en el móvil: más grandes que el HUD y con el ✖ de al menos ~36 px
	do
		mods.Hud.showQuests()
		local questsWin = popupsGui:FindFirstChild("Quests")
		local press = questsWin and questsWin:FindFirstChild("PressScale")
		local k = if press then press:GetAttribute("Base") or 1 else 1
		local closePx = questsWin and questsWin.Close.Size.X.Offset * now.Scale * k
		-- (en pantallas grandes, 2400x1080, el HUD ya va a escala 1,3: no hace falta agrandarla)
		check(questsWin and (k > 1 or now.Scale >= 1.2) and closePx and closePx >= 35.9, ("Misiones: ventana agrandada (x%.2f) y ✖ de %d px"):format(k, closePx or 0))
		mods.Hud.runCommand("Misiones")
		check(popupsGui:FindFirstChild("Quests") == nil, "Y se cierra")
	end

	-- El joystick mueve al personaje (relativo a la cámara)
	table.clear(moves)
	local s = now.Scale
	local rectPx = { X = stickRect.X * s, Y = stickRect.Y * s, W = stickRect.W * s, H = stickRect.H * s }
	rawget(stick, "__props").AbsolutePosition = roblox.Vector2.new(rectPx.X, rectPx.Y)
	rawget(stick, "__props").AbsoluteSize = roblox.Vector2.new(rectPx.W, rectPx.H)
	local touchInput = { UserInputType = roblox.Enum.UserInputType.Touch, Position = roblox.Vector3.new(rectPx.X + rectPx.W / 2, rectPx.Y, 0) }
	stick.InputBegan:Fire(touchInput)
	local step = renderSteps.ValmarJoystick
	if step then
		step(1 / 60)
	end
	local last = moves[#moves]
	check(last and last.Relative == true and last.Vector.Z < -0.9 and math.abs(last.Vector.X) < 0.01, "Empujar el joystick hacia arriba anda hacia delante (Humanoid:Move relativo a la cámara)")
	check(mods.Joystick.push() > 0.99, "Hasta el borde: empuje completo (para correr solo)")
	userInput.InputEnded:Fire(touchInput)
	last = moves[#moves]
	check(last and last.Vector.Magnitude < 1e-6 and renderSteps.ValmarJoystick == nil, "Al soltar, se para")
	check(mods.Joystick.vectorFrom(roblox.Vector2.new(5, 0), 100).Magnitude == 0, "Con zona muerta en el centro")

	-- El botón Saltar salta de verdad. Antes solo ponía Humanoid.Jump = true, que el control de Roblox
	-- vuelve a escribir cada fotograma (y el botón no dispara JumpRequest): en el móvil no saltaba.
	do
		local E = roblox.Enum
		local props = rawget(humanoid, "__props")
		local states: { any } = {}
		local enabled = true
		props.FloorMaterial = E.Material.Plastic
		props.JumpHeight = 7.2
		props.Jump = false
		rawset(humanoid, "GetState", function()
			return E.HumanoidStateType.Running
		end)
		rawset(humanoid, "GetStateEnabled", function(_, kind)
			return if kind == E.HumanoidStateType.Jumping then enabled else true
		end)
		rawset(humanoid, "ChangeState", function(_, kind)
			table.insert(states, kind)
		end)
		local jumpButton = TouchLayout.buttons().Saltar
		local press = { UserInputType = E.UserInputType.Touch, Position = roblox.Vector3.new(0, 0, 0) }
		local function tap()
			jumpButton.InputBegan:Fire(press)
			local step = renderSteps.SaltarTactil
			props.Jump = false -- (lo que hace el control de Roblox cada fotograma: su botón no está pulsado)
			if step then
				step(1 / 60)
			end
			local held = humanoid.Jump
			userInput.InputEnded:Fire(press)
			return held
		end
		local held = tap()
		check(states[#states] == E.HumanoidStateType.Jumping, "Tocar Saltar de pie en el suelo salta (Humanoid:ChangeState(Jumping), sin depender de Humanoid.Jump)")
		check(held == true, "Mantenido: Jump = true en cada fotograma después del control de Roblox (Input + 2), como su botón")
		check(renderSteps.SaltarTactil == nil and humanoid.Jump == false, "Al soltar se deja de pedir el salto (no queda un salto pendiente)")
		-- Corriendo (y con la energía a 0) también
		table.clear(states)
		localPlayer:SetAttribute("Sprinting", true)
		localPlayer:SetAttribute("Energy", 0)
		tap()
		check(states[#states] == E.HumanoidStateType.Jumping, "Corriendo y sin energía también se salta (saltar no gasta ni pide energía)")
		localPlayer:SetAttribute("Sprinting", nil)
		localPlayer:SetAttribute("Energy", nil)
		-- En el aire, en una conversación o sentado, no
		table.clear(states)
		props.FloorMaterial = E.Material.Air
		tap()
		props.FloorMaterial = E.Material.Plastic
		localPlayer:SetAttribute("InDialogue", true)
		tap()
		localPlayer:SetAttribute("InDialogue", nil)
		localPlayer:SetAttribute("InCinematic", true)
		tap()
		localPlayer:SetAttribute("InCinematic", nil)
		check(#states == 0, "En el aire, en una conversación o en una cinemática no salta")
		-- Quien se encarga del botón (parkour con obstáculo delante, levantarse de agachado…) lo dice
		local got: { boolean } = {}
		TouchLayout.onJump(function(down: boolean)
			table.insert(got, down)
			return down
		end)
		tap()
		check(#states == 0 and got[1] == true and got[2] == false, "Si alguien se encarga (TouchLayout.onJump devuelve true), no salta además; se avisa al pulsar y al soltar")
		props.Jump = false
	end

	-- Conversaciones: sin botones ni joystick
	mods.Hud.setBusy(true)
	mods.Joystick.setBusy(true)
	local anyVisible = false
	for _, button in TouchLayout.buttons() do
		anyVisible = anyVisible or button.Visible
	end
	check(not anyVisible and stick.Visible == false, "En una conversación se apartan los botones y el joystick")
	mods.Hud.setBusy(false)
	mods.Joystick.setBusy(false)
	check(TouchLayout.buttons().Ataque.Visible and stick.Visible, "Y vuelven al acabar")

	-- Conduciendo: el cuadro de mandos (VehicleHud) va abajo en el centro, justo encima de la barra
	-- rápida (no tapa la calle), y no pisa la indicación del GPS, los avisos, las estrellas de búsqueda,
	-- las flechas de girar, los pedales ni nada de arriba o de abajo (con y sin estrellas)
	local VehicleHud = loadModule("src/client/Controllers/VehicleHud")
	local vok, verr = pcall(VehicleHud.init, playerGui)
	check(vok, "El cuadro de mandos se monta sin errores" .. (if vok then "" else ": " .. tostring(verr)))
	local vgui = playerGui:FindFirstChild("VehicleHud")
	local panel = vgui and vgui:FindFirstChildOfClass("Frame")
	for _, stars in { 0, 2 } do
		localPlayer:SetAttribute("Wanted", if stars > 0 then stars else nil)
		if panel then
			local ui = panel:FindFirstChildOfClass("UIScale")
			local k = if ui then ui.Scale else 1
			local w, h = panel.Size.X.Offset * k, panel.Size.Y.Offset * k
			local x = panel.Position.X.Scale * size[1] + panel.Position.X.Offset - panel.AnchorPoint.X * w
			local y = panel.Position.Y.Scale * size[2] + panel.Position.Y.Offset - panel.AnchorPoint.Y * h
			-- (los testigos, la marcha y el combustible van dentro del cuadro)
			local mine = { X = x / s, Y = y / s, W = w / s, H = h / s } -- (en el lienzo del HUD)
			local clashes = {}
			local others = {}
			for _, other in hudRects(mods) do
				-- (al volante la tarjeta de los primeros pasos y las pistas se quitan: Guide.inVehicle; el
				-- consejo del vehículo va encima del cuadro, Items.GuideDrive)
				if other.Name ~= "Tarjeta de primeros pasos" and other.Name ~= "Pista o consejo" then
					table.insert(others, other)
				end
			end
			table.insert(others, { Name = "Consejo al volante", Rect = HudLayout.rect(now.Items.GuideDrive, now.Canvas) })
			for _, name in if stars > 0 then { "Gps", "Activity", "Wanted" } else { "Gps", "Activity" } do
				table.insert(others, { Name = name, Rect = HudLayout.rect(now.Items[name], now.Canvas) })
			end
			for name, slot in now.Slots do
				table.insert(others, { Name = "Hueco " .. name, Rect = HudLayout.rect(slot, now.Canvas) })
			end
			-- (al volante: pedales, flechas, luces, intermitentes…)
			for name, slot in now.DriveSlots do
				table.insert(others, { Name = "Hueco al volante " .. name, Rect = HudLayout.rect(slot, now.Canvas) })
			end
			for _, other in others do
				if HudLayout.overlaps(mine, other.Rect) then
					table.insert(clashes, other.Name)
				end
			end
			check(#clashes == 0 and mine.Y + mine.H < now.Canvas.Y, ("Conduciendo (%d estrellas): el cuadro de mandos no pisa nada%s"):format(stars, if #clashes > 0 then ": " .. table.concat(clashes, ", ") else ""))
			if stars == 0 then
				local bar = HudLayout.rect(now.Items.Hotbar, now.Canvas)
				local gap = bar.Y - (mine.Y + mine.H)
				check(gap >= 0 and gap <= 24 and math.abs((mine.X + mine.W / 2) - now.Canvas.X / 2) < 2,
					("El cuadro de mandos va justo encima de la barra rápida, en el centro (a %.0f de ella)"):format(gap))
				check(mine.Y > now.Canvas.Y * 0.6 and mine.H <= now.Canvas.Y * 0.22 and mine.W <= 700,
					("Y es pequeño y va abajo: no tapa la calle (de %.0f a %.0f de %.0f de alto)"):format(mine.Y, mine.Y + mine.H, now.Canvas.Y))
				local left = HudLayout.rect(now.DriveSlots.GiroDer, now.Canvas)
				local right = math.huge
				for _, slot in now.DriveSlots do
					local r = HudLayout.rect(slot, now.Canvas)
					if r.Y + r.H > mine.Y and r.X > now.Canvas.X / 2 then
						right = math.min(right, r.X)
					end
				end
				check(mine.X > left.X + left.W and mine.X + mine.W < right,
					"Entre las flechas de girar (izquierda) y los pedales, luces e intermitentes (derecha)")
				local middle = panel:FindFirstChild("Center")
				local speedo, fuelGauge = panel:FindFirstChild("Speedometer"), panel:FindFirstChild("Fuel")
				local gearsRow = middle and middle:FindFirstChild("Gears")
				check(speedo and fuelGauge and gearsRow and gearsRow:FindFirstChild("D") and middle:FindFirstChild("Telltales"),
					"Como un salpicadero: velocímetro de aguja, testigos, marcha P R N D y combustible de E a F")
			end
		else
			check(false, "Conduciendo: falta el cuadro de mandos")
		end
	end
	localPlayer:SetAttribute("Wanted", nil)

	-- HUD compacto del móvil (HudLayout.Compact): lo que solo informa ocupa poco y deja ver el juego;
	-- los mandos no cambian. (En el móvil del dueño: 932x430)
	if size[1] == 932 then
		local Compact = HudLayout.Compact
		local hudGui = playerGui:FindFirstChild("MainHud")
		local st = hudGui and hudGui:FindFirstChild("Status")
		-- (si al montar alguna barra estaba baja se despliega sola un rato: se pliega tocándolo)
		if st and st:GetAttribute("Expanded") and st:FindFirstChild("Expand") then
			st.Expand.Activated:Fire()
		end
		check(st and st.Size.X.Offset == Compact.Status.X and st.Size.Y.Offset == Compact.Status.Y and not st:FindFirstChild("Name").Visible and not st.EnergyValue.Visible,
			"Móvil: tu estado plegado (foto, nivel, dinero y 5 barritas, sin nombre ni números)")
		check(st and st.Level.Visible and st.Money.Visible and st.Energy.Visible and st.Fun.Visible and st.Health.Visible, "Plegado se siguen viendo el nivel, el dinero y las 5 barras (con la diversión)")
		do
			-- Plegado: 3 + 2 barritas con icono, sin pisarse entre ellas y dentro de la tarjeta
			local rects = {}
			local inside = true
			for _, id in { "Energy", "Hunger", "Fun", "Mood", "Health" } do
				for _, piece in { st:FindFirstChild(id .. "Icon"), st:FindFirstChild(id) } do
					if piece then
						local r = { piece.Position.X.Offset, piece.Position.Y.Offset, piece.Size.X.Offset, piece.Size.Y.Offset }
						table.insert(rects, r)
						if r[1] + r[3] > Compact.Status.X or r[2] + r[4] > Compact.Status.Y then
							inside = false
						end
					end
				end
			end
			local clash = false
			for i = 1, #rects do
				for j = i + 1, #rects do
					local a, b = rects[i], rects[j]
					if a[1] < b[1] + b[3] and b[1] < a[1] + a[3] and a[2] < b[2] + b[4] and b[2] < a[2] + a[4] then
						clash = true
					end
				end
			end
			check(#rects == 10 and inside and not clash, "Móvil: las 5 barritas (3 arriba, 2 abajo) con su icono, sin pisarse y dentro de la tarjeta")
		end
		local expand = st and st:FindFirstChild("Expand")
		if expand then
			expand.Activated:Fire()
		end
		check(st and st:GetAttribute("Expanded") == true and st.Size.X.Offset == HudLayout.Sizes.Status.X and st:FindFirstChild("Name").Visible and st.EnergyValue.Visible,
			"Al tocarlo se despliega entero (nombre, experiencia y números)")
		if expand then
			expand.Activated:Fire()
		end
		check(st and st:GetAttribute("Expanded") == false and st.Size.X.Offset == Compact.Status.X, "Y al volver a tocarlo se pliega")
		local clk = hudGui and hudGui:FindFirstChild("Clock")
		check(clk and clk.Size.X.Offset == Compact.Clock.X and clk.Time.Visible and clk.Temp.Visible and not clk.Date.Visible and clk:FindFirstChild("ShortDate") and clk.ShortDate.Text ~= "",
			"Móvil: la cápsula de la hora en una fila: hora grande, tiempo y la fecha corta («" .. (if clk and clk:FindFirstChild("ShortDate") then clk.ShortDate.Text else "?") .. "»)")
		local mini = HudLayout.rect(now.Items.Minimap, now.Canvas)
		check(mini.W < HudLayout.Sizes.Minimap and mini.W >= HudLayout.Sizes.Minimap * 0.8 and math.abs(mini.X + mini.W - (now.Canvas.X - 16)) < 0.5, "Móvil: el minimapa, algo más pequeño (x0,85) y pegado a la esquina")
		local bar = HudLayout.rect(now.Items.Hotbar, now.Canvas)
		check(bar.H == HudLayout.Sizes.Hotbar.Y and bar.W == HudLayout.Sizes.Hotbar.X, "Móvil: la barra rápida a su tamaño (es juego: objetos, vehículos, teléfono)")
		-- Suelos de legibilidad (en pt de pantalla): lo que se toca ≥ 44, barras ≥ 6
		local k = now.Scale
		check(st and st.Energy.Size.Y.Offset * k >= 6 and st.Level.Size.Y.Offset * k >= 16, ("Móvil: las barras de tu estado miden ≥ 6 pt de grueso (%.1f)"):format(st and st.Energy.Size.Y.Offset * k or 0))
		local note = HudLayout.rect(now.Items.Guide, now.Canvas)
		check(note.X <= 16 and note.X + note.W < now.Canvas.X / 2 - 100 and HudLayout.rect(now.Items.GuideDrive, now.Canvas).X == note.X,
			"Móvil: pistas y consejos a la izquierda (nunca en el centro), a pie y al volante")
		local help = HudLayout.rect(now.Items.HelpCard, now.Canvas)
		check(help.X > now.Canvas.X / 2, "Móvil: «¿Qué hago ahora?» arriba a la derecha, no en el centro")
		local phoneSpot = HudLayout.rect(now.Items.PhoneDrive, now.Canvas)
		check(phoneSpot.W * now.Scale >= 44 and phoneSpot.H * now.Scale >= 44 and phoneSpot.W < HudLayout.Sizes.PhonePeek.X, ("Móvil: al volante, el ValPhone es un icono junto a tu estado, que se toca bien (%.0fx%.0f pt)"):format(phoneSpot.W * now.Scale, phoneSpot.H * now.Scale))
		-- Los mandos no se encogen: los mismos huecos y tamaños que antes (pedales, flechas, Bajarse…)
		check(now.DriveSlots.Acelerar.Size.Y == 240 and now.DriveSlots.Bajarse.Size.X == 80 and now.DriveSlots.GiroIzq.Size.X == 150,
			"Los mandos del vehículo siguen igual de grandes")
		check(HudLayout.DashTouch == 1, "El cuadro de mandos del coche, a su tamaño (x1)")
		-- El aviso del ValPhone y las notas comparten sitio y se turnan
		do
			local PhoneMod = loadModule("src/client/UI/Phone")
			local GuideMod = mods.Guide
			local noteGui = playerGui:FindFirstChild("GuideGui")
			local noteFrame = noteGui and noteGui:FindFirstChild("GuideNote")
			GuideMod.note("Info", "Prueba de turno")
			GuideMod.refresh()
			local wasShown = noteFrame and noteFrame.Visible
			pcall(PhoneMod.notify, { Text = "Mensaje de prueba", App = "Mensajes" })
			if PhoneMod.bannerShowing() then
				GuideMod.refresh()
				check(wasShown and not noteFrame.Visible, "Móvil: mientras baja un aviso del ValPhone (mismo sitio), la nota espera")
				PhoneMod.hideBanner()
				GuideMod.refresh()
				check(noteFrame.Visible, "Y al irse el aviso, vuelve la nota")
			end
			GuideMod.dismissNote()
		end
		-- Bici, patinete, monopatín: un velocímetro pequeño sin P R N D ni esferas
		local chip = vgui and vgui:FindFirstChild("SpeedChip")
		local vok2 = pcall(VehicleHud.show, "Patinete")
		check(vok2 and chip and chip.Visible and panel and not panel.Visible, "Patinete: solo el velocímetro pequeño (sin P R N D ni combustible de coche)")
		local c = HudLayout.rect(now.Items.DashCompact, now.Canvas)
		local d = HudLayout.rect(now.Items.Dash, now.Canvas)
		check(c.W * c.H < d.W * d.H * 0.4, "Y ocupa mucho menos que el cuadro del coche")
		pcall(VehicleHud.show, "Coche")
		check(chip and not chip.Visible and panel and panel.Visible, "Coche: el cuadro de mandos de siempre (más pequeño)")
		pcall(VehicleHud.hide)
	end

	-- Catástrofes del mar (Controllers/SeaEventsUI): la alerta es una tira pequeña arriba, bajo el
	-- reloj (no un cartel en el centro), con una × que la cierra para esa catástrofe
	local SeaEventsUI = loadModule("src/client/Controllers/SeaEventsUI")
	local sok, serr = pcall(SeaEventsUI.init)
	check(sok, "La alerta de las catástrofes del mar se monta sin errores" .. (if sok then "" else ": " .. tostring(serr)))
	local seaGui = playerGui:FindFirstChild("SeaEventGui")
	local alert = seaGui and seaGui:FindFirstChild("SeaAlert")
	check(alert ~= nil and seaGui:FindFirstChildOfClass("UIScale") ~= nil, "La alerta va en su capa, a la escala del HUD")
	if alert and sok then
		local seaAt = 1000
		fakeWorkspace:SetAttribute("SeaEvent", "Medusas")
		fakeWorkspace:SetAttribute("SeaEventSite", "el puerto")
		fakeWorkspace:SetAttribute("SeaEventPos", roblox.Vector3.new(0, 0, 0))
		fakeWorkspace:SetAttribute("SeaEventDir", roblox.Vector3.new(1, 0, 0))
		fakeWorkspace:SetAttribute("SeaEventAt", seaAt)
		fakeWorkspace:SetAttribute("SeaEventEnd", 1e9)
		localPlayer:SetAttribute("LifeStage", "Adulto")
		local function frame()
			services.RunService.RenderStepped:Fire(1 / 60)
		end
		frame()
		local title, tip = alert:FindFirstChild("Title"), alert:FindFirstChild("Tip")
		check(alert.Visible and title and string.find(title.Text, "PLAGA DE MEDUSAS", 1, true) and tip and string.find(tip.Text, "Pican", 1, true),
			"Plaga de medusas: sale la alerta con el nombre, el sitio, la cuenta atrás y qué hacer")
		-- Pequeña y arriba, bajo el reloj (en el lienzo del HUD), y sin pisar el reloj, el GPS ni las
		-- estrellas en ningún caso
		local h = alert.Size.Y.Offset
		local function alertRect(gps: boolean, wanted: boolean)
			local y = SeaEventsUI.alertTop(now, gps, wanted)
			return { X = now.Canvas.X / 2 - alert.Size.X.Offset / 2, Y = y, W = alert.Size.X.Offset, H = h }
		end
		local mineTop = alert.Position.Y.Offset
		check(alert.Size.X.Offset <= 600 and h <= 64 and mineTop + h < now.Canvas.Y * 0.4 and (mineTop == SeaEventsUI.alertTop(now, false, false) or mineTop == SeaEventsUI.alertTop(now, true, false)),
			("Y es pequeña y va arriba, bajo el reloj, lejos del centro (%d × %d, de %d a %d de %d de alto)"):format(alert.Size.X.Offset, h, mineTop, mineTop + h, now.Canvas.Y))
		local seaClashes = {}
		for _, case in { { false, false }, { true, false }, { true, true }, { false, true } } do
			local r = alertRect(case[1], case[2])
			local others = { Reloj = now.Items.Clock }
			if case[1] then
				others.GPS = now.Items.Gps
			end
			if case[2] then
				others.Estrellas = now.Items.Wanted
			end
			for name, item in others do
				if HudLayout.overlaps(r, HudLayout.rect(item, now.Canvas)) then
					table.insert(seaClashes, name .. (if case[1] then " (con GPS)" else "") .. (if case[2] then " (con estrellas)" else ""))
				end
			end
		end
		check(#seaClashes == 0, "La alerta no pisa el reloj, el GPS ni las estrellas" .. (if #seaClashes > 0 then ": " .. table.concat(seaClashes, ", ") else ""))
		local close = alert:FindFirstChild("Close")
		check(close ~= nil and close.Size.X.Offset >= 46, "Con una × para cerrarla (grande para el dedo)")
		if close then
			close.Activated:Fire()
		end
		frame()
		check(not alert.Visible and fakeWorkspace:GetAttribute("SeaEvent") == "Medusas", "Al tocar la × se cierra y no vuelve mientras dura esa catástrofe (que sigue)")
		fakeWorkspace:SetAttribute("SeaEventAt", seaAt + 4000)
		frame()
		check(alert.Visible, "La siguiente catástrofe sí avisa")
		fakeWorkspace:SetAttribute("SeaEvent", nil)
		frame()
		check(not alert.Visible, "Al acabar, se quita")
		localPlayer:SetAttribute("LifeStage", "Nino")
	end
	check(#badWrites == 0, "Ninguna propiedad inventada al usarlo" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
end

---------------------------------------------------------------------
-- Primeros pasos, el botón ❓ y las pistas (Controllers/Guide y Controllers/HelpUI)
---------------------------------------------------------------------
do
	print("\n▶ Primeros pasos, ❓ «¿Qué hago ahora?», pistas y consejos (móvil 844x390)")
	local function sent(kind: string, id: string?): boolean
		for _, message in onboardingSent do
			if message[1] == kind and message[2] == id then
				return true
			end
		end
		return false
	end
	local function toastSaid(text: string): boolean
		local toastGui = playerGui:FindFirstChild("HudToasts")
		return toastGui ~= nil and textOf(toastGui, text)
	end
	local function clearToasts()
		local toastGui = playerGui:FindFirstChild("HudToasts")
		local list = toastGui and toastGui:FindFirstChild("Toasts")
		for _, child in if list then list:GetChildren() else {} do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end
	local function near(a: number, b: number): boolean
		return math.abs(a - b) < 1
	end
	for _, attribute in { "InPrologue", "InDialogue", "Riding", "Wanted", "Sprinting" } do
		localPlayer:SetAttribute(attribute, nil)
	end
	table.clear(onboardingSent)
	fakeHooks.Map, fakeHooks.Bag, fakeHooks.Dialog = false, false, false
	local m, okMount, errMount = mount(true, 844, 390)
	check(okMount, "Se monta sin errores" .. (if okMount then "" else ": " .. tostring(errMount)))
	local Guide, HelpUI, TL, HL = m.Guide, m.HelpUI, m.TouchLayout, m.HudLayout
	local layout = HL.current()
	local function centerOf(placement): (number, number)
		local r = HL.rect(placement, layout.Canvas)
		return r.X + r.W / 2, r.Y + r.H / 2
	end
	local guideGui = playerGui:FindFirstChild("GuideGui")
	local tcard = guideGui and guideGui:FindFirstChild("TutorialCard")
	local noteView = guideGui and guideGui:FindFirstChild("GuideNote")
	local highlightGui = playerGui:FindFirstChild("GuideHighlight")
	local ring = highlightGui and highlightGui:FindFirstChild("Ring")
	local arrowView = highlightGui and highlightGui:FindFirstChild("Arrow")
	local pps = services.ProximityPromptService
	local function ringOn(placement): boolean
		local x, y = centerOf(placement)
		return ring ~= nil and ring.Visible and near(ring.Position.X.Offset, x) and near(ring.Position.Y.Offset, y)
	end

	-- Nuevo o de antes
	check(tcard and tcard.Visible and tcard.Count.Text:find("1/7", 1, true) ~= nil and tcard.Title.Text == "Muévete", "Jugador nuevo: sale la tarjeta «PRIMEROS PASOS · 1/7 · Muévete»")
	check(tcard and tcard.Text.Text:find("joystick", 1, true) ~= nil and tcard.Skip.Text:find("Saltar", 1, true) ~= nil, "En el móvil habla del joystick, con el botón «Saltar»")
	check(ringOn(layout.Items.Joystick) and arrowView and arrowView.Visible, "Un aro brillante y una flecha señalan el joystick de verdad")
	localPlayer:SetAttribute("Tutorial", "Veterano")
	check(tcard.Visible == false and ring.Visible == false, "Quien ya jugaba antes (Veterano): no sale el tutorial")
	localPlayer:SetAttribute("Tutorial", "Pendiente")
	check(tcard.Visible, "Jugador nuevo (Pendiente): sí")
	fakeHooks.Dialog = true
	Guide.refresh()
	check(tcard.Visible == false, "Con una decisión de la historia en pantalla (también abajo en el centro), la tarjeta espera")
	fakeHooks.Dialog = false
	localPlayer:SetAttribute("Training", "Cinta")
	Guide.refresh()
	check(tcard.Visible == false, "Y mientras entrenas (la barra del gimnasio)")
	localPlayer:SetAttribute("Training", nil)
	Guide.refresh()
	check(tcard.Visible, "Luego vuelve")

	-- Cada paso se cumple al hacerlo de verdad
	local humanoidProps = rawget(humanoid, "__props")
	humanoidProps.MoveDirection = roblox.Vector3.new(0, 0, -1)
	Guide.tick(0.5)
	check(tcard.Title.Text == "Muévete" and not sent("Step", "Mover"), "Medio segundo andando aún no cuenta (no es un temporizador: hay que andar)")
	Guide.tick(0.6)
	humanoidProps.MoveDirection = roblox.Vector3.new(0, 0, 0)
	check(sent("Step", "Mover") and tcard.Title.Text == "Corre" and tcard.Count.Text:find("2/7", 1, true) ~= nil, "Andar con el joystick cumple «Muévete» (se guarda) y pasa a «Corre»")
	check(ringOn(layout.Slots.Correr), "El aro pasa al botón Correr")
	Guide.tick(30)
	check(tcard.Title.Text == "Corre", "Esperar sin hacer nada no cumple nada")
	localPlayer:SetAttribute("Sprinting", true)
	localPlayer:SetAttribute("Sprinting", nil)
	check(sent("Step", "Correr") and tcard.Title.Text == "Habla o usa algo", "Correr de verdad (Sprinting) cumple «Corre»")
	check(ringOn(layout.Slots.Ataque), "El aro pasa al botón grande (el que cambia a «Hablar», «Coger»…)")
	pps.PromptTriggered:Fire(newInstance("ProximityPrompt"), newInstance("Player"))
	check(tcard.Title.Text == "Habla o usa algo", "Un cartel que usa otro jugador no cuenta")
	pps.PromptTriggered:Fire(newInstance("ProximityPrompt"), localPlayer)
	check(sent("Step", "Interactuar") and tcard.Title.Text == "Abre el mapa", "Usar un cartel (hablar, abrir…) cumple «Habla o usa algo»")
	check(ringOn(layout.Items.Minimap), "El aro señala el minimapa")
	fakeHooks.Map = true
	Guide.tick(0.25)
	check(not tcard.Visible, "Con el mapa grande abierto la tarjeta se aparta")
	fakeHooks.Map = false
	Guide.tick(0.25)
	check(sent("Step", "Mapa") and tcard.Title.Text == "Abre la mochila", "Abrir el mapa grande cumple «Abre el mapa»")
	check(ringOn(layout.Items.Phone), "El aro señala el ValPhone (la app Mochila)")
	fakeHooks.Bag = true
	Guide.tick(0.25)
	check(not tcard.Visible, "Con la mochila abierta la tarjeta no la tapa")
	fakeHooks.Bag = false
	Guide.tick(0.25)
	check(sent("Step", "Mochila") and tcard.Title.Text == "¿No sabes qué hacer?", "Abrir la mochila cumple «Abre la mochila»")
	check(ringOn(layout.Slots.Ayuda), "El aro señala el botón ❓")

	-- ❓: tu objetivo en claro, dónde está y «Llévame»
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Nino_Jornada", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", TextKey = "Ve al colegio y entra en clase", Args = { placeKey = "Colegio Valmar" } },
		Others = {},
	})
	localPlayer:SetAttribute("StoryTarget", roblox.Vector3.new(150, 0, -200))
	local missionStep = playerGui.MainHud.Mission.Step.Text
	TL.buttons().Ayuda.Activated:Fire()
	local helpCard = playerGui.HelpGui.HelpCard
	local body = helpCard.Body
	check(helpCard.Visible and missionStep ~= "" and body.Step.Text:find(missionStep, 1, true) ~= nil, "El ❓ abre la tarjeta con tu objetivo en claro («" .. body.Step.Text .. "»)")
	check(body.Kind.Text:find("MISIÓN PRINCIPAL", 1, true) ~= nil, "Dice qué misión es («" .. body.Kind.Text .. "»)")
	check(body.Where.Text:find("Colegio Valmar · ", 1, true) ~= nil and body.Where.Text:find(" m · ", 1, true) ~= nil and body.Where.Text:find("hacia el", 1, true) ~= nil, "Dónde está (el sitio), a cuánto y hacia dónde («" .. body.Where.Text .. "»)")
	check(sent("Step", "Ayuda") and tcard.Title.Text == "Sigue tu misión", "Abrir el ❓ cumple «¿No sabes qué hacer?»")
	check(ringOn(layout.Items.Mission), "El aro señala la misión")
	-- La ruta estaba quitada (×) y el GPS apagado en el menú: «Llévame» la vuelve a poner
	local banner = playerGui.GpsGui.GpsBanner
	banner.Clear.Activated:Fire()
	m.Gps.setEnabled(false)
	m.Gps.update()
	check(m.Gps.path() == nil and banner.Visible == false, "(sin ruta: quitada con × y el GPS apagado)")
	clearToasts()
	body.Go.Activated:Fire()
	m.Gps.update()
	check(m.Gps.isEnabled() and m.Gps.path() ~= nil and banner.Visible and helpCard.Visible == false, "«Llévame» pone la ruta del GPS al objetivo y cierra la tarjeta")
	check(sent("Step", "Mision") and tcard.Visible == false and ring.Visible == false, "…y cumple «Sigue tu misión»: primeros pasos terminados")
	check(toastSaid("Ya sabes lo básico") and (Guide.state()) == "Hecho", "Al acabar: «🎉 ¡Ya sabes lo básico!»")

	-- «Saltar» y «Ver tutorial otra vez»
	table.clear(onboardingSent)
	Guide.restart()
	check(sent("Restart") and tcard.Visible and tcard.Count.Text:find("1/7", 1, true) ~= nil, "«Ver tutorial otra vez» lo empieza de nuevo (se guarda)")
	tcard.Skip.Activated:Fire()
	check(sent("Skip") and tcard.Visible == false and ring.Visible == false and (Guide.state()) == "Saltado", "«Saltar» quita la tarjeta y se guarda")
	localPlayer:SetAttribute("Tutorial", "Saltado") -- (lo que contesta el servidor)
	Guide.tick(5)
	check(tcard.Visible == false, "Y no vuelve")

	-- Prólogo (InPrologue): la tarjeta no sale, pero lo que haces cuenta
	Guide.restart()
	clearToasts()
	localPlayer:SetAttribute("InPrologue", true)
	check(tcard.Visible == false and ring.Visible == false, "En el prólogo (InPrologue) no sale la tarjeta")
	humanoidProps.MoveDirection = roblox.Vector3.new(1, 0, 0)
	Guide.tick(1.2)
	humanoidProps.MoveDirection = roblox.Vector3.new(0, 0, 0)
	localPlayer:SetAttribute("Sprinting", true)
	localPlayer:SetAttribute("Sprinting", nil)
	pps.PromptTriggered:Fire(newInstance("ProximityPrompt"), localPlayer)
	fakeHooks.Map = true
	Guide.tick(0.25)
	fakeHooks.Map = false
	check(tcard.Visible == false, "Tampoco mientras anda, corre, habla y abre el mapa en el prólogo")
	localPlayer:SetAttribute("InPrologue", nil)
	check(tcard.Visible and tcard.Title.Text == "Abre la mochila" and tcard.Count.Text:find("5/7", 1, true) ~= nil, "Al acabar el prólogo cuenta lo que hizo en él: solo sale lo que falta («Abre la mochila», 5/7)")
	-- Todo hecho dentro del prólogo: se da por terminado sin decir nada
	Guide.restart()
	clearToasts()
	localPlayer:SetAttribute("InPrologue", true)
	humanoidProps.MoveDirection = roblox.Vector3.new(1, 0, 0)
	Guide.tick(1.2)
	humanoidProps.MoveDirection = roblox.Vector3.new(0, 0, 0)
	localPlayer:SetAttribute("Sprinting", true)
	localPlayer:SetAttribute("Sprinting", nil)
	pps.PromptTriggered:Fire(newInstance("ProximityPrompt"), localPlayer)
	fakeHooks.Map, fakeHooks.Bag = true, true
	Guide.tick(0.25)
	fakeHooks.Map, fakeHooks.Bag = false, false
	HelpUI.open()
	HelpUI.close()
	m.Hud.runCommand("Misiones")
	Guide.tick(0.25)
	m.Hud.runCommand("Misiones")
	localPlayer:SetAttribute("InPrologue", nil)
	check(tcard.Visible == false and (Guide.state()) == "Hecho" and not toastSaid("Ya sabes lo básico") and not toastSaid("Bien hecho"), "Si lo hizo todo en el prólogo, se da por hecho sin decir nada")

	-- Pistas si te atascas: nunca en una conversación; a los 90 s, «💡 Pista: …» con «Toca para ir»
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Nino_Jornada", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", TextKey = "Busca a Leo en el patio del colegio", Args = {} },
		Others = {},
	})
	missionStep = playerGui.MainHud.Mission.Step.Text
	localPlayer:SetAttribute("InDialogue", true)
	for _ = 1, 150 do
		Guide.tick(1)
	end
	check(Guide.currentNote() == nil and noteView.Visible == false, "En una conversación (InDialogue) no sale ninguna pista (150 s)")
	localPlayer:SetAttribute("InDialogue", nil)
	Guide.setBusy(true) -- (una cinemática: Cinematics.isPlaying() en Main.client)
	for _ = 1, 150 do
		Guide.tick(1)
	end
	check(Guide.currentNote() == nil, "Ni durante una cinemática")
	Guide.setBusy(false)
	for _ = 1, 85 do
		Guide.tick(1)
	end
	check(Guide.currentNote() == nil, "85 s jugando sin avanzar: todavía nada" .. (if Guide.currentNote() then " (" .. Guide.currentNote().Text .. ")" else ""))
	for _ = 1, 6 do
		Guide.tick(1)
	end
	local hint = Guide.currentNote()
	check(hint and hint.Kind == "Hint" and noteView.Visible and noteView.Text.Text:find("💡 Pista:", 1, true) ~= nil and noteView.Text.Text:find(missionStep, 1, true) ~= nil, "A los 90 s sin avanzar: «" .. noteView.Text.Text .. "»")
	-- (móvil: toda la nota es el botón, ≥ 44 pt; lo que hace va al final del texto: «👆 Toca para ir»)
	check(noteView.Text.Text:find("👆", 1, true) ~= nil and noteView.Text.Text:find("Toca para ir", 1, true) ~= nil, "Con «👆 Toca para ir» (en el móvil toda la nota se toca)")
	check(not (tcard.Visible and noteView.Visible), "La pista no sale a la vez que la tarjeta")
	m.Gps.clear()
	m.Gps.update()
	noteView.Go.Activated:Fire()
	m.Gps.update()
	check(m.Gps.path() ~= nil and noteView.Visible == false, "Tocarla pone la ruta del GPS (y se quita)")
	for _ = 1, 95 do
		Guide.tick(1)
	end
	check(Guide.currentNote() ~= nil and Guide.currentNote().Kind == "Hint", "Sigue sin avanzar: la pista sale una segunda vez")
	Guide.dismissNote()
	local again = false
	for _ = 1, 400 do
		Guide.tick(1)
		again = again or Guide.currentNote() ~= nil
	end
	check(not again, "Pero la misma pista no sale más de dos veces")
	-- Paso nuevo y te alejas mucho rato de él: «te estás alejando»
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Nino_Jornada", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", TextKey = "Vuelve a casa con tu familia", Args = {} },
		Others = {},
	})
	Guide.tick(1)
	local rootProps = rawget(rootPart, "__props")
	rootProps.Position = roblox.Vector3.new(-200, 3, 300)
	for _ = 1, 50 do
		Guide.tick(1)
	end
	hint = Guide.currentNote()
	check(hint and noteView.Text.Text:find("te estás alejando", 1, true) ~= nil, "Si te alejas mucho rato del objetivo: «" .. noteView.Text.Text .. "»")
	rootProps.Position = roblox.Vector3.new(0, 3, -10)
	Guide.dismissNote()

	-- La nota lleva × (móvil: ≥ 44 px) y no sale encima de una ventana (Mis vehículos): espera a
	-- que se cierre, con su «Toca para ir». Cerrada con la ×, la misma no vuelve en un rato.
	local Dialog = loadModule("src/client/UI/Dialog")
	local plaza = "💡 Pista: Ve a la Plaza Mayor"
	local wentThere = false
	Guide.note("Hint", plaza, "🧭 Toca para ir", function()
		wentThere = true
	end)
	Guide.tick(0.25)
	local closeButton = noteView:FindFirstChild("Close")
	check(noteView.Visible and closeButton ~= nil and closeButton.Visible and closeButton.Size.X.Offset >= 44 and closeButton.Size.Y.Offset >= 44, "La pista lleva una × para cerrarla (≥ 44 px)")
	check(closeButton ~= nil and closeButton.Text == "×" and closeButton.ZIndex > noteView.Go.ZIndex - 5, "La × se ve y se puede tocar")
	local vehiclesWindow = Dialog.window("Vehicles", "🚲 Mis vehículos", roblox.Vector2.new(480, 520))
	check(Dialog.anyOpen(), "Dialog.anyOpen(): Mis vehículos está abierta")
	Guide.tick(0.25)
	check(noteView.Visible == false and tcard.Visible == false, "Con Mis vehículos abierta, la pista no sale encima")
	for _ = 1, 30 do
		Guide.tick(1)
	end
	check(noteView.Visible == false and Guide.currentNote() ~= nil and Guide.currentNote().Text == plaza, "Espera (30 s) sin perderse ni irse sola")
	Guide.note("Hint", plaza, "🧭 Toca para ir", function() end)
	Guide.dismissNote()
	check(Guide.currentNote() == nil, "La misma pista no se pone dos veces en la cola")
	Guide.note("Hint", plaza, "🧭 Toca para ir", function()
		wentThere = true
	end)
	vehiclesWindow:Destroy()
	check(not Dialog.anyOpen(), "Al cerrar la ventana ya no hay ninguna abierta")
	Guide.tick(0.25)
	check(noteView.Visible and noteView.Text.Text:find(plaza, 1, true) == 1 and noteView.Text.Text:find("Toca para ir", 1, true) ~= nil, "Al cerrarla, sale la pista con «Toca para ir»")
	noteView.Go.Activated:Fire()
	check(wentThere and noteView.Visible == false, "«Toca para ir» sigue funcionando")
	Guide.note("Hint", plaza, "🧭 Toca para ir", function() end)
	Guide.tick(0.25)
	noteView.Close.Activated:Fire()
	check(Guide.currentNote() == nil and noteView.Visible == false, "La × la quita")
	Guide.note("Hint", plaza, "🧭 Toca para ir", function() end)
	Guide.tick(0.25)
	check(Guide.currentNote() == nil, "Cerrada con la ×, la misma pista no vuelve enseguida")
	for _ = 1, 301 do
		Guide.tick(1)
	end
	Guide.note("Hint", plaza, "🧭 Toca para ir", function() end)
	Guide.tick(0.25)
	check(Guide.currentNote() ~= nil and Guide.currentNote().Text == plaza, "Pasados 5 min, sí puede volver")
	Guide.dismissNote()
	-- (con el mapa abierto, igual)
	fakeHooks.Map = true
	Guide.note("Hint", "💡 Pista: Ve al colegio", "🧭 Toca para ir", function() end)
	Guide.tick(0.25)
	check(noteView.Visible == false, "Con el mapa abierto tampoco sale")
	fakeHooks.Map = false
	Guide.tick(0.25)
	check(noteView.Visible, "Y sale al cerrarlo")
	Guide.dismissNote()

	-- Consejos de la primera vez (una sola vez cada uno; en el prólogo no)
	table.clear(onboardingSent)
	localPlayer:SetAttribute("Riding", "Bici")
	Guide.tick(0.25)
	local tip = Guide.currentNote()
	check(tip and tip.Kind == "Tip" and noteView.Visible and noteView.Text.Text:find("ACELERAR", 1, true) ~= nil and sent("Tip", "Vehiculo"), "Primera vez en un vehículo: su consejo («" .. noteView.Text.Text .. "»), y se guarda")
	TL.refresh()
	check(TL.buttons().Ayuda.Visible == false, "Montado, el ❓ se aparta (la H es el claxon)")
	Guide.dismissNote()
	localPlayer:SetAttribute("Riding", nil)
	Guide.tick(0.25)
	localPlayer:SetAttribute("Riding", "Bici")
	Guide.tick(0.25)
	check(Guide.currentNote() == nil, "La segunda vez ya no sale")
	localPlayer:SetAttribute("Riding", nil)
	localPlayer:SetAttribute("InPrologue", true)
	localPlayer:SetAttribute("Wanted", 2)
	Guide.tick(0.25)
	check(Guide.currentNote() == nil and noteView.Visible == false, "En el prólogo no salen consejos")
	localPlayer:SetAttribute("InPrologue", nil)
	Guide.tick(0.25)
	check(Guide.currentNote() and noteView.Text.Text:find("policía", 1, true) ~= nil, "Al acabar, sí (estrellas de búsqueda)")
	Guide.dismissNote()
	localPlayer:SetAttribute("Wanted", nil)
	local machine = newInstance("Model")
	machine:SetAttribute("GymMachine", "Cinta")
	local machinePrompt = newInstance("ProximityPrompt")
	machinePrompt.MaxActivationDistance = 10
	machinePrompt.Parent = machine
	pps.PromptShown:Fire(machinePrompt)
	pps.PromptHidden:Fire(machinePrompt)
	Guide.tick(0.25)
	check(Guide.currentNote() and noteView.Text.Text:find("Empujar", 1, true) ~= nil, "Delante de una máquina del gimnasio: su consejo (corto en el móvil)")
	Guide.dismissNote()
	localPlayer:SetAttribute("Hunger", 20)
	Guide.tick(0.25)
	check(Guide.currentNote() and noteView.Text.Text:find("ambre", 1, true) ~= nil, "Con hambre: su consejo")
	Guide.dismissNote()
	localPlayer:SetAttribute("Hunger", nil)

	-- ❓ sin misión: 2-3 ideas para ahora mismo
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", { Others = {} })
	localPlayer:SetAttribute("StoryTarget", nil)
	HelpUI.open()
	check(helpCard.Visible and body.Kind.Text == "AHORA NO TIENES MISIÓN" and body:FindFirstChild("Idea1") ~= nil and body:FindFirstChild("Idea2") ~= nil, "Sin misión: ideas para ahora mismo («" .. (if body:FindFirstChild("Idea1") then body.Idea1.Text.Text else "?") .. "»…)")
	HelpUI.close()
	-- Con alguien cerca que necesita ayuda (encargo de la ciudad): la primera idea
	localPlayer:SetAttribute("CityErrandMarks", '[{"Id":"Parque:0,0","Title":"¡Se ha escapado Trufa!","Giver":"Doña Amparo","X":30,"Y":0,"Z":30}]')
	HelpUI.open()
	local errandIdea = body:FindFirstChild("Encargo")
	check(errandIdea ~= nil and errandIdea.Text.Text:find("Doña Amparo", 1, true) ~= nil and errandIdea:FindFirstChild("Go") ~= nil, "Sin misión y con un ❗ cerca: «Doña Amparo necesita ayuda» con su «Llévame»")
	HelpUI.close()
	localPlayer:SetAttribute("CityErrandMarks", nil)

	-- La misión en pausa (el cole cerrado): la tarjeta dice cuándo sigue y el ❓ también (no «sin misión»)
	local Hud = m.Hud
	local missionStepLabel = playerGui.MainHud.Mission.Step
	check(Hud.storySynced(), "Con el estado de la historia recibido, ya no está «cargando»")
	fakeWorkspace:SetAttribute("Day", 6) -- sábado
	lighting.ClockTime = 20
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Cole04_Malotes", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", StepType = "Scene", Args = {},
			Later = "School", Closed = { Name = "El colegio", From = 8.5, To = 17, Weekdays = { 1, 2, 3, 4, 5 } }, From = 8.5 },
		Others = {},
	})
	check(missionStepLabel.Text == "El colegio está cerrado · abre el lunes a las 8:30 · 💤 duerme", "Sábado por la noche: «" .. missionStepLabel.Text .. "»")
	HelpUI.open()
	check(body.Kind.Text == "TU MISIÓN SIGUE MÁS TARDE" and body.Step.Text:find("sigue el lunes a las 8:30", 1, true) ~= nil and body:FindFirstChild("Idea1") ~= nil, "El ❓ dice cuándo sigue («" .. body.Step.Text .. "») y da ideas para mientras")
	HelpUI.close()
	fakeWorkspace:SetAttribute("Day", 1) -- lunes
	lighting.ClockTime = 19
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Cole04_Malotes", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", StepType = "Scene", Args = {},
			Later = "School", Closed = { Name = "El colegio", From = 8.5, To = 17, Weekdays = { 1, 2, 3, 4, 5 } }, From = 8.5 },
		Others = {},
	})
	check(missionStepLabel.Text == "El colegio está cerrado · abre mañana a las 8:30 · 💤 duerme", "Lunes a las 19:00: «" .. missionStepLabel.Text .. "»")
	lighting.ClockTime = 10
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Loco_N1_Cosme", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", StepType = "Talk", Args = {}, Later = "AfterSchool", From = 17 },
		Others = {},
	})
	check(missionStepLabel.Text == "Sigue al salir del cole (17:00)", "En horario de cole, una principal que no es del cole: «" .. missionStepLabel.Text .. "»")
	-- Un paso sin texto (una escena): «Mira la escena», no «sin misión»
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Cole04_Malotes", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", StepType = "Scene", Args = {} },
		Others = {},
	})
	HelpUI.open()
	check(body.Kind.Text:find("MISIÓN PRINCIPAL", 1, true) ~= nil and body.Step.Text == "👉 Mira la escena", "Paso sin texto (escena): «" .. body.Step.Text .. "»")
	HelpUI.close()
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", {
		Tracked = { QuestId = "Cole04_Malotes", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", StepType = "Talk", NpcKey = "Nico", Args = {} },
		Others = {},
	})
	check(missionStepLabel.Text == "Habla con Nico", "Hablar sin texto: «" .. missionStepLabel.Text .. "»")
	-- Trabajando sin TaskText: «Sigue con tu trabajo de Barista»
	localPlayer:SetAttribute("Job", "Barista")
	HelpUI.open()
	check(body.Kind.Text:find("TRABAJO", 1, true) ~= nil and body.Step.Text:find("Sigue con tu trabajo de Barista", 1, true) ~= nil, "Trabajo sin tarea escrita: «" .. body.Step.Text .. "»")
	HelpUI.close()
	localPlayer:SetAttribute("Job", nil)
	remotes:FindFirstChild("LifeStory").OnClientEvent:Fire("State", { Others = {} })
	fakeWorkspace:SetAttribute("Day", nil)
	check(#badWrites == 0, "Ninguna propiedad inventada" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
end

---------------------------------------------------------------------
-- Bocadillos de texto (UI/BubbleLayout): uno por personaje, sin pisarse
---------------------------------------------------------------------
do
	print("\n▶ Bocadillos de los personajes")
	local B = loadModule("src/client/UI/BubbleLayout")
	local book = B.book()
	local ana, luis, perro = {}, {}, {}
	B.put(book, ana, "¡Hola!", 0)
	local entry, changed = B.put(book, ana, "¿Qué tal el día? Yo muy bien, gracias.", 0.5)
	local count = 0
	for _ in book.Entries do
		count += 1
	end
	check(count == 1 and changed and entry.Text == "¿Qué tal el día? Yo muy bien, gracias.", "Una frase nueva del mismo personaje sustituye a la anterior (un solo bocadillo suyo)")
	local _, again = B.put(book, ana, "¿Qué tal el día? Yo muy bien, gracias.", 0.8)
	check(not again, "La misma frase otra vez no vuelve a saltar")
	B.put(book, luis, "¡Buenas!", 1)
	B.put(book, perro, "¡Guau!", 1, { Seconds = 1.4 })
	count = 0
	for _ in book.Entries do
		count += 1
	end
	check(count == 3 and book.Entries[luis].Text == "¡Buenas!" and book.Entries[ana].Text ~= book.Entries[luis].Text, "Cada personaje tiene su propio bocadillo (no se mezclan)")
	check(B.duration("¡Eh!") < B.duration("Si ves algo raro, avísame por el interfono, que para eso estoy aquí toda la noche."), "Las frases largas duran más")
	check(B.duration("¡Eh!") >= 2 and B.duration(string.rep("palabra ", 80)) <= 9, "Ni tan cortas que no se lean ni eternas (2-9 s)")
	check(B.speaking(book, perro, 2) and not B.speaking(book, perro, 2.5), "Con duración fija se calla a su hora")
	local gone = B.sweep(book, 2.5 + B.FadeOut)
	check(table.find(gone, perro) ~= nil and book.Entries[perro] == nil and book.Entries[ana] ~= nil, "Se quita cuando termina de irse (los demás siguen)")
	B.quiet(book, luis, 3)
	check(not B.speaking(book, luis, 3.01), "Callar a alguien quita su bocadillo")
	local a1 = B.alpha(book.Entries[ana], 0.05)
	local a2 = B.alpha(book.Entries[ana], 1)
	check(a1 < 1 and a2 == 1, "Aparece con un fundido")
	local sticky = B.put(B.book(), {}, "¿Me pone un café con leche, por favor?", 0, { Sticky = true })
	check(sticky.Until >= 12 and sticky.Until <= 40, "Las frases que se quedan (pedidos) tienen un tope")
	-- Tamaño: ancho máximo y varias líneas
	local w1, h1 = B.estimate("¡Eh!")
	local w2, h2 = B.estimate(string.rep("texto largo ", 20), "Abu Rosa")
	check(w1 < w2 and w2 <= B.MaxWidth and h2 > h1 * 2, "Las frases largas se parten en líneas sin pasar del ancho máximo")
	check(B.scale(5, 1080) > B.scale(50, 1080) and B.scale(10, 390) < B.scale(10, 1080) and B.scale(10, 390) >= 0.55, "Más lejos, más pequeño; en el móvil algo menor, pero legible")
	-- Apilar: dos que hablan juntos no se pisan; uno lejos en pantalla se queda en su sitio
	local lifts = B.stack({
		{ Id = "ana", X = 500, Y = 300, W = 200, H = 60, Depth = 10 },
		{ Id = "luis", X = 540, Y = 305, W = 200, H = 60, Depth = 12 },
		{ Id = "eva", X = 560, Y = 310, W = 180, H = 50, Depth = 14 },
		{ Id = "lejos", X = 1400, Y = 300, W = 200, H = 60, Depth = 30 },
	})
	check(lifts.ana == 0 and lifts.lejos == 0, "El más cercano y los que no chocan se quedan en su sitio")
	local function rect(id, x, y, w, h)
		local bottom = y - lifts[id]
		return { L = x - w / 2, R = x + w / 2, T = bottom - h, B = bottom }
	end
	local ra, rl, re = rect("ana", 500, 300, 200, 60), rect("luis", 540, 305, 200, 60), rect("eva", 560, 310, 180, 50)
	local function overlap(p, q)
		return p.L < q.R and p.R > q.L and p.T < q.B and p.B > q.T
	end
	check(lifts.luis > 0 and lifts.eva > lifts.luis and not overlap(ra, rl) and not overlap(ra, re) and not overlap(rl, re), "Los que hablan cerca se apilan hacia arriba sin pisarse")
end

-- Con un arma en el móvil la cámara es la de Roblox: ya no hay zona de arrastre propia (CamaraTactil,
-- mitad derecha, Active) que se tragaba los toques ni giraba la cámara a mano
do
	print("\n▶ Con arma, sin zona de cámara táctil propia (la cámara es la de Roblox)")
	local found = {}
	local function scan(dir: string)
		for _, name in fs.readDir(dir) do
			local path = dir .. "/" .. name
			if fs.isDir(path) then
				scan(path)
			elseif string.sub(name, -5) == ".luau" then
				local source = fs.readFile(path)
				if string.find(source, "CamaraTactil", 1, true) or string.find(source, "ZonaCamara", 1, true) or string.find(source, "DragZoneOrder", 1, true) then
					table.insert(found, path)
				end
			end
		end
	end
	scan("src")
	check(#found == 0, ("ninguna pantalla CamaraTactil / ZonaCamara (%s)"):format(if #found > 0 then table.concat(found, ", ") else "ninguna"))
end

---------------------------------------------------------------------
-- Mapa grande (shared/MapScreen + Controllers/MapUI): la pantalla del dibujo de referencia
-- (docs/mapa/comparacion.png) con los datos de verdad, y que cabe en el móvil apaisado
---------------------------------------------------------------------
print("\n▶ Mapa grande: cabe en cada pantalla sin pisarse (MapScreen.layout)")
do
	local MapScreen = loadModule("src/shared/MapScreen")
	local V2 = roblox.Vector2
	local roblox_ = { X = 0, Y = 0, W = 250, H = 58 } -- botones de Roblox (en píxeles)
	for _, size in { { 932, 430 }, { 844, 390 }, { 667, 375 }, { 640, 360 }, { 1846, 852 }, { 2400, 1080 }, { 1334, 750 }, { 1024, 768 }, { 1366, 768 }, { 1600, 900 }, { 1920, 1080 }, { 2560, 1440 } } do
		local viewport = V2.new(size[1], size[2])
		local layout = MapScreen.layout(viewport)
		local k = layout.Scale
		local name = ("%dx%d"):format(size[1], size[2])
		local R = layout.Rects
		local bad, overlaps = {}, {}
		for _, id in layout.Fixed do
			if not MapScreen.inside(R[id], layout.Canvas) then
				table.insert(bad, id)
			end
		end
		local topbar = { X = 0, Y = 0, W = roblox_.W / k, H = roblox_.H / k }
		for i, a in layout.Fixed do
			if MapScreen.overlaps(R[a], topbar) then
				table.insert(overlaps, a .. "/botones de Roblox")
			end
			for j = i + 1, #layout.Fixed do
				local b = layout.Fixed[j]
				if MapScreen.overlaps(R[a], R[b]) then
					table.insert(overlaps, a .. "/" .. b)
				end
			end
		end
		-- Los paneles plegables (móvil): dentro de la pantalla y sin tapar la brújula, el zoom, las pestañas ni la tarjeta
		if not layout.Wide then
			for _, drawer in { "Districts", "Places" } do
				if not MapScreen.inside(R[drawer], layout.Canvas) then
					table.insert(bad, drawer)
				end
				for _, other in { "Compass", "Zoom", "TabDistricts", "TabPlaces", "Location", "Close", "Clock", "Logo" } do
					if MapScreen.overlaps(R[drawer], R[other]) then
						table.insert(overlaps, drawer .. "/" .. other)
					end
				end
			end
		end
		check(#bad == 0 and #overlaps == 0, ("mapa %s: todo dentro de la pantalla y nada se pisa (fuera: %s; se pisan: %s)"):format(name, table.concat(bad, ", "), table.concat(overlaps, ", ")))
		-- Cuánto se ve el mapa: el hueco libre (sin paneles) es la mayor parte de la pantalla
		local map = layout.Map
		local share = map.W * map.H / (layout.Canvas.X * layout.Canvas.Y)
		check(share >= (if layout.Wide then 0.45 elseif layout.Canvas.X < 1000 then 0.45 else 0.55), ("mapa %s: la isla se ve en el %.0f %% de la pantalla (%s)"):format(name, share * 100, if layout.Wide then "paneles a los lados" else "paneles en pestañas"))
		-- Lo que se toca, ≥ 40 px; las letras, ≥ 10,8 px
		local small = {}
		for _, id in { "Close", "TabDistricts", "TabPlaces" } do
			local r = R[id]
			if r and math.min(r.W, r.H) * k < 40 then
				table.insert(small, id)
			end
		end
		if R.Zoom.W * k < 40 then
			table.insert(small, "Zoom")
		end
		check(#small == 0 and layout.Text.Sub * k >= 10.5 and (layout.Row - 8) * k >= 34, ("mapa %s: botones ≥ 40 px (%s), subtítulos de %.1f px y filas de %.0f px (≥ 34)"):format(name, table.concat(small, ", "), layout.Text.Sub * k, (layout.Row - 8) * k))
	end
	local phone = MapScreen.layout(V2.new(932, 430))
	check(phone.Wide and phone.Rects.Districts ~= nil and phone.Rects.Places ~= nil, "932x430 (móvil apaisado, como el dibujo): Distritos y Lugares a los lados de la isla")
	local small = MapScreen.layout(V2.new(667, 375))
	check(not small.Wide and small.Rects.TabDistricts ~= nil and small.Map.W >= small.Canvas.X - 1, "667x375 (móvil pequeño): pestañas y la isla a toda la pantalla, detrás")
	local ref = MapScreen.layout(V2.new(1846, 852))
	check(ref.Wide and ref.Rects.TabDistricts == nil and ref.Rects.Districts.X < ref.Map.X and ref.Rects.Places.X + ref.Rects.Places.W > ref.Map.X + ref.Map.W and ref.Rects.Places.X >= ref.Map.X + ref.Map.W - 40, "1846x852 (el dibujo): Distritos a la izquierda, Lugares a la derecha y la isla en medio")
	check(ref.Rects.Compass.X > ref.Map.X and ref.Rects.Clock.X > ref.Rects.Compass.X and ref.Rects.Close.X > ref.Rects.Clock.X, "1846x852: brújula, hora y ✖ arriba a la derecha")
	check(ref.Rects.Location.Y > ref.Rects.Districts.Y + ref.Rects.Districts.H and ref.Rects.Hint.Y > ref.Rects.Places.Y + ref.Rects.Places.H, "1846x852: «Valmar» abajo a la izquierda y la pista abajo a la derecha")
	check(ref.Rects.Zoom.Y >= ref.Rects.Places.Y + ref.Rects.Places.H and ref.Rects.Zoom.X >= ref.Rects.Places.X and ref.Rects.Zoom.Y + ref.Rects.Zoom.H <= ref.Rects.Hint.Y, "1846x852: + / − / ◎ en fila debajo de los lugares (no tapan la isla)")
	local phoneShare = phone.Map.W * phone.Map.H / (phone.Canvas.X * phone.Canvas.Y)
	check(phoneShare >= 0.5, ("932x430: el hueco de la isla es el %.0f %% de la pantalla (≥ 50)"):format(phoneShare * 100))

	print("\n▶ Mapa grande: los datos de verdad")
	local want = {
		{ "Distrito Centro", "El corazón de Valmar" },
		{ "Distrito Norte", "Residencial y vida tranquila" },
		{ "Distrito Oeste", "Costa, lujo y naturaleza" },
		{ "Distrito Este", "Comercio, ocio y playa" },
		{ "Distrito Universitario", "Estudios y juventud" },
		{ "Distrito Sur", "Industria, trabajo y negocios" },
	}
	local okDistricts = #MapScreen.Districts == 6
	for i, w in want do
		local d = MapScreen.Districts[i]
		okDistricts = okDistricts and d ~= nil and d.Name == w[1] and d.Sub == w[2]
	end
	check(okDistricts, "Distritos: los 6 del plano (CityPlan) con su subtítulo, en el orden del dibujo")
	-- Los lugares de la ciudad de verdad (scripts/map/export.luau sobre la ciudad construida)
	local serde = require("@lune/serde")
	local MapInfo = loadModule("src/shared/MapInfo")
	local exported = serde.decode("json", fs.readFile("docs/mapa/lugares.json"))
	local landmarks = {}
	for _, place in exported do
		local kind = MapInfo.KindByModel[place.Kind]
		if kind then
			table.insert(landmarks, { Kind = kind, Position = roblox.Vector3.new(place.X, 0, place.Z), District = if place.Host then "" else place.District })
		end
	end
	local rows = MapScreen.placeRows(landmarks)
	local byTitle = {}
	for _, row in rows do
		byTitle[row.Title] = row
	end
	local missing = {}
	for _, title in { "Aeropuerto de Valmar", "Aeródromo de las Gaviotas", "Agencia Tributaria", "Armería (3)", "Ayuntamiento", "Camping Valmar", "Campos de Valmar", "Casa de Cosme", "Centro Comercial Valmar" } do
		if not byTitle[title] then
			table.insert(missing, title)
		end
	end
	check(#rows >= 25 and #missing == 0, ("Lugares importantes: %d filas con los del dibujo (faltan: %s)"):format(#rows, table.concat(missing, ", ")))
	check(rows[1] and rows[1].Title == "Aeropuerto de Valmar" and rows[2].Title == "Aeródromo de las Gaviotas" and rows[3].Title == "Agencia Tributaria" and rows[4].Title == "Armería (3)", "Lugares importantes: en orden alfabético, como en el dibujo (Aeropuerto, Aeródromo, Agencia, Armería…)")
	local function sub(title: string): string
		return byTitle[title] and byTitle[title].Sub or "?"
	end
	check(sub("Armería (3)") == "Toca: te marca el más cercano", "Armería (3): «Toca: te marca el más cercano»")
	check(sub("Ayuntamiento") == "Distrito Centro" and sub("Camping Valmar") == "Distrito Oeste" and sub("Campos de Valmar") == "Distrito Oeste" and sub("Casa de Cosme") == "Distrito Norte" and sub("Centro Comercial Valmar") == "Distrito Este", "Subtítulos: el distrito de cada lugar (Ayuntamiento · Centro, Camping · Oeste, Casa de Cosme · Norte…)")
	check(sub("Aeropuerto de Valmar") == "Afueras de Valmar" and sub("Aeródromo de las Gaviotas") == "Afueras de Valmar", "Aeropuerto y aeródromo: «Afueras de Valmar»")
	check(sub("Agencia Tributaria") == "Distrito Centro" and sub("Puerto de Valmar") == "Distrito Sur", ("Instituciones y puerto (sin distrito del servidor): el más cercano (Agencia · %s, Puerto · %s)"):format(sub("Agencia Tributaria"), sub("Puerto de Valmar")))
	local armeria = byTitle["Armería (3)"]
	local near = armeria and MapScreen.nearest(armeria.Places, roblox.Vector3.new(2400, 0, -400))
	check(near and near.Position.X == 2493, "Armería (3): desde el Distrito Este marca la del Este (la más cercana)")
	check(MapScreen.coords(0, 0) == "37.6289° N   0.7307° W", ("Coordenadas de Valmar Centro: %s"):format(MapScreen.coords(0, 0)))

	print("\n▶ Mapa grande: la imagen de la ciudad de verdad en 3D (scripts/map/blender_render.py) y su proyección")
	local A = MapScreen.Art
	local total = A.Rows * A.Cols
	local current = #MapScreen.tiles(loadModule("src/shared/MapTextureIds"))
	check(#MapScreen.tiles({}) == 0 and (current == 0 or current == total), ("Sin los %d ids subidos, nada de imagen (el dibujo de siempre); ahora: %d"):format(total, current))
	local ids = {}
	for r = 0, A.Rows - 1 do
		for c = 0, A.Cols - 1 do
			ids[("isla_%d_%d"):format(r, c)] = "rbxassetid://" .. (100 + r * A.Cols + c)
		end
	end
	local tiles = MapScreen.tiles(ids)
	local last = tiles[#tiles]
	check(#tiles == total and tiles[1].X0 == 0 and tiles[1].Y0 == 0 and math.abs(last.X1 - A.Width) < 0.01 and math.abs(last.Y1 - A.Height) < 0.01, ("Con los %d ids: trozos que cubren toda la imagen (%dx%d)"):format(total, A.Width, A.Height))
	local meta = fs.isFile("textures/mapa/meta.json") and serde.decode("json", fs.readFile("textures/mapa/meta.json"))
	local Projection = loadModule("src/shared/MapProjection")
	check(meta and meta.Width == A.Width and meta.Height == A.Height and meta.Cols == A.Cols and meta.Rows == A.Rows and meta.TileWidth <= 1024 and meta.TileHeight <= 1024 and meta.Tilt == Projection.Tilt and meta.CX == Projection.CX and meta.CS == Projection.CS and meta.OrthoWidth == Projection.OrthoWidth, "textures/mapa: la imagen y su cámara coinciden con shared/MapProjection, y cada trozo mide ≤ 1024x1024 (límite de Roblox)")
	local pngs = 0
	for name in ids do
		if fs.isFile("textures/mapa/" .. name .. ".png") then
			pngs += 1
		end
	end
	check(pngs == total, ("textures/mapa: los %d trozos para scripts/upload-map.sh (%d)"):format(total, pngs))
	-- La proyección: ida y vuelta exactas en el suelo, y el norte arriba y el este a la derecha
	local worstBack = 0
	for _, p in { { 0, 0 }, { -3010, 3088 }, { 2898, -3989 }, { 4427, 2650 }, { -3940, 1248 } } do
		local a = MapScreen.toArt(p[1], p[2])
		local back = MapScreen.toWorld(a.X, a.Y)
		worstBack = math.max(worstBack, (back - V2.new(p[1], p[2])).Magnitude)
	end
	local north, east = MapScreen.toArt(0, -1000), MapScreen.toArt(1000, 0)
	local origin = MapScreen.toArt(0, 0)
	check(worstBack < 0.01 and north.Y < origin.Y and east.X > origin.X and math.abs(north.X - origin.X) < 1e-6, ("Proyección exacta de la cámara (ida y vuelta: %.4f studs), norte arriba y este a la derecha"):format(worstBack))
	local higher = MapScreen.toArt(0, 0, 100)
	check(higher.Y < origin.Y, "Lo alto sale más arriba en la imagen (vista inclinada)")
	-- Toda la isla y cada lugar caen dentro de la imagen, y dentro de la caja de la isla
	local box = MapScreen.IslandBox
	local outside = {}
	for _, place in landmarks do
		local a = MapScreen.toArt(place.Position.X, place.Position.Z)
		if a.X < box.X0 or a.X > box.X1 or a.Y < box.Y0 or a.Y > box.Y1 then
			table.insert(outside, place.Kind.Name)
		end
	end
	check(box.X0 >= 0 and box.Y0 >= 0 and box.X1 <= A.Width and box.Y1 <= A.Height and #outside == 0, ("La isla entera cabe en la imagen, con mar alrededor, y cada lugar cae dentro (fuera: %s)"):format(table.concat(outside, ", ")))
	-- Etiquetas de los distritos: no se pisan entre ellas ni tapan los lugares con nombre
	for _, size in { { 1846, 852 }, { 932, 430 }, { 667, 375 } } do
		local layout = MapScreen.layout(V2.new(size[1], size[2]))
		local fit = MapScreen.fitScale(layout)
		local placed = MapScreen.districtLabels(layout, landmarks, MapScreen.toArt, fit)
		local list = {}
		for id, l in placed do
			table.insert(list, { id, l })
		end
		local clashes = {}
		for i, a in list do
			for j = i + 1, #list do
				local b = list[j]
				local la, lb = a[2], b[2]
				if math.abs(la.X - lb.X) * 2 < la.W + lb.W and math.abs(la.Y - lb.Y) * 2 < la.H + lb.H then
					table.insert(clashes, a[1] .. "/" .. b[1])
				end
			end
		end
		check(#clashes == 0, ("%dx%d: las etiquetas de los distritos no se pisan (%s)"):format(size[1], size[2], table.concat(clashes, ", ")))
	end
	local overlapped = MapScreen.placeLabels({ { Id = "A", X = 0, Y = 0, W = 100, H = 40 }, { Id = "B", X = 10, Y = 5, W = 100, H = 40 } }, { { X0 = -20, Y0 = 50, X1 = 20, Y1 = 90 } })
	check(math.abs(overlapped.B.Y - overlapped.A.Y) >= 40 or math.abs(overlapped.B.X - overlapped.A.X) >= 100, "placeLabels: una etiqueta que pisaría a otra se aparta a un hueco libre")

	print("\n▶ Mapa grande: el código (Controllers/MapUI)")
	local source = fs.readFile("src/client/Controllers/MapUI.luau")
	local function has(text: string): boolean
		return string.find(source, text, 1, true) ~= nil
	end
	check(has("MapScreen.layout(") and has("MapScreen.placeRows(") and has("MapScreen.tiles(MapTextureIds)"), "MapUI usa MapScreen (sitio de cada pieza, listas y la imagen)")
	check(has("Gps.setManual(") and has("Gps.clear()"), "Tocar un lugar pone la ruta del GPS (Gps.setManual) y «Quitar ruta» la quita")
	check(has("pinch") and has("MouseWheel") and has("dragMoved"), "Se mueve arrastrando y se acerca con la rueda o pellizcando")
	check(has("layer.Outlines") and has("MapScreen.smooth("), "Los bordes de los distritos los dibuja la interfaz (nítidos al acercar)")
	check(not string.find(string.lower(source .. fs.readFile("src/shared/MapScreen.luau")), "nova", 1, true), "El mapa se llama Heroes of History (nada de otros nombres)")
	local screenSrc = fs.readFile("src/shared/MapScreen.luau")
	check(string.find(screenSrc, 'MapScreen.Title = "HEROES OF HISTORY"', 1, true) ~= nil and string.find(screenSrc, 'MapScreen.Tagline = "History of Valmar"', 1, true) ~= nil, "El logo del mapa: HEROES OF HISTORY · History of Valmar")
	check(string.find(screenSrc, 'MapScreen.Badge = "HH"', 1, true) ~= nil and has("Text = MapScreen.Badge") and not has('Text = "RL"'), "La insignia del logo dice «HH»")
	check(not string.find(string.lower(source .. screenSrc), "real life simulator", 1, true), "Ya no queda el nombre antiguo en el mapa")
end

---------------------------------------------------------------------
-- Los letreros de arriba en el centro (UI/TopStack). Lo que pidió el dueño (captura del móvil en el
-- colegio: «hay mucha información junta»): el marcador de los pases, el aviso de la grieta con su
-- flecha morada encima del marcador y la narración de una escena, todo a la vez.
---------------------------------------------------------------------
do
	print("\n▶ Letreros de arriba en el centro (UI/TopStack): ni se pisan ni salen en las escenas")
	local TopStack = loadModule("src/client/UI/TopStack")
	local Layout = loadModule("src/client/UI/HudLayout")
	local P = TopStack.Priority
	-- Lo que puede haber a la vez (en píxeles, a su tamaño de siempre: nada se encoge)
	local entries = {
		{ Id = "AvisoGrieta", Priority = P.World, Order = 1, W = 280, H = 40 },
		{ Id = "FlechaGrieta", Priority = P.World, Order = 2, W = 56, H = 56 },
		{ Id = "MarcadorPases", Priority = P.Mission, Order = 3, W = 360, H = 58 },
		{ Id = "PistaPases", Priority = P.Mission, Order = 4, W = 420, H = 64 },
		{ Id = "BuenPase", Priority = P.Mission, Order = 5, W = 600, H = 64 },
		{ Id = "AvisoHistoria", Priority = P.Story, Order = 6, W = 520, H = 34 },
	}
	local function area(r)
		return ("(%d,%d %dx%d)"):format(math.floor(r.X), math.floor(r.Y), math.floor(r.W), math.floor(r.H))
	end
	for _, size in { { 932, 430 }, { 844, 390 }, { 640, 360 }, { 1920, 1080 } } do
		local view = roblox.Vector2.new(size[1], size[2])
		local touch = size[1] < 1000
		local where = ("%dx%d"):format(size[1], size[2])
		local placed, bottom = TopStack.arrange(view, entries, { Touch = touch, Inset = 58 })
		local shown = {}
		for _, e in entries do
			if placed[e.Id].Shown then
				table.insert(shown, { Name = e.Id, Rect = placed[e.Id] })
			end
		end
		-- Entre ellos
		local clashes = {}
		for i = 1, #shown do
			for j = i + 1, #shown do
				if Layout.overlaps(shown[i].Rect, shown[j].Rect) then
					table.insert(clashes, shown[i].Name .. "/" .. shown[j].Name)
				end
			end
		end
		check(#shown >= 1 and #clashes == 0, ("%s: %d letreros a la vista y ninguno pisa a otro%s"):format(where, #shown, if #clashes > 0 then " (" .. table.concat(clashes, ", ") .. ")" else ""))
		-- Con el HUD (reloj, GPS, avisos fijos, estrellas, minimapa, misión, tu estado, ❓)
		local hits = {}
		for _, s in shown do
			for i, block in TopStack.obstacles(view, { Touch = touch, Inset = 58 }) do
				if Layout.overlaps(s.Rect, block) then
					table.insert(hits, s.Name .. " " .. area(s.Rect) .. " / " .. TopStack.Obstacles[i] .. " " .. area(block))
				end
			end
		end
		check(#hits == 0, ("%s: ninguno pisa el reloj, el GPS, la misión, el minimapa ni tu estado%s"):format(where, if #hits > 0 then " (" .. table.concat(hits, "; ") .. ")" else ""))
		-- Prioridad: la historia primero, luego lo que juegas, y los avisos del mundo al final
		check(placed.AvisoHistoria.Shown and (not placed.MarcadorPases.Shown or placed.MarcadorPases.Y > placed.AvisoHistoria.Y)
			and (not placed.AvisoGrieta.Shown or (placed.MarcadorPases.Shown and placed.AvisoGrieta.Y > placed.MarcadorPases.Y)),
			where .. ": orden historia > misión > avisos del mundo (la grieta nunca encima del marcador)")
		-- La flecha de la grieta: en su propio hueco, debajo de su aviso
		check(not placed.FlechaGrieta.Shown or (placed.AvisoGrieta.Shown and placed.FlechaGrieta.Y >= placed.AvisoGrieta.Y + placed.AvisoGrieta.H),
			where .. ": la flecha morada de la grieta va en su hueco (debajo de su aviso, nunca encima de un panel de texto)")
		-- Lo que se ve, dentro del hueco de arriba (el centro de la pantalla es para jugar)
		local low = true
		for _, s in shown do
			if s.Name ~= shown[1].Name and s.Rect.Y + s.Rect.H > size[2] * TopStack.MaxBottom then
				low = false
			end
		end
		check(low and bottom <= size[2], ("%s: la columna no baja de %d%% de la pantalla (lo que no cabe espera)"):format(where, math.floor(TopStack.MaxBottom * 100)))
		-- En una narración, conversación o escena: ninguno
		local quiet = TopStack.arrange(view, entries, { Touch = touch, Inset = 58, Quiet = true })
		local any = false
		for _, e in entries do
			any = any or quiet[e.Id].Shown
		end
		check(not any, where .. ": durante la narración de una escena no se ve ninguno")
		-- Pilotando un avión: el panel de instrumentos no se tapa (la captura del dueño: el aviso de la
		-- grieta y su flecha encima de VEL/ALT/RUMBO); los avisos del mundo esperan, el resto va debajo
		-- (el panel de antes, "Flight", y el del HUD de la nave que usan ahora los aviones, "ShipHud")
		for _, panelName in { "Flight", "ShipHud" } do
			local pilot, pBottom = TopStack.arrange(view, entries, { Touch = touch, Inset = 58, Piloting = panelName })
			local panel = TopStack.panelRect(view, { Touch = touch, Inset = 58, Piloting = panelName })
			local bad = {}
			local count = 0
			for _, e in entries do
				local p = pilot[e.Id]
				if p.Shown then
					count += 1
					if Layout.overlaps(p, panel) then
						table.insert(bad, e.Id)
					end
				end
			end
			check(panel ~= nil and #bad == 0 and count >= 1 and not pilot.AvisoGrieta.Shown and not pilot.FlechaGrieta.Shown and pBottom >= panel.Y + panel.H,
				("%s pilotando (%s): nada tapa el panel de instrumentos; la grieta y su flecha esperan a que aterrices%s"):format(where, panelName, if #bad > 0 then " (" .. table.concat(bad, ", ") .. ")" else ""))
			local alone = TopStack.arrange(view, { entries[1], entries[2] }, { Touch = touch, Inset = 58, Piloting = panelName })
			check(not alone.AvisoGrieta.Shown and not alone.FlechaGrieta.Shown, where .. " pilotando: aunque no haya nada más, el aviso de la grieta no sale encima del panel")
			local unpiloted = TopStack.arrange(view, { entries[1] }, { Touch = touch, Inset = 58 })
			check(unpiloted.AvisoGrieta.Shown, where .. ": al aterrizar (sin pilotar) el aviso de la grieta vuelve")
		end
		-- Los botones táctiles no cambian de tamaño (TopStack no toca el HUD)
		local before = Layout.compute(view, { Touch = touch, Inset = 58 }).Slots.Ataque
		check(not touch or (before and before.Size.X == Layout.Cluster.Ataque[3] * 2), where .. ": los controles, a su tamaño de siempre")
	end

	-- En vivo: un marcador y el aviso de la grieta en pantallas de verdad (las de mentira de esta prueba)
	TopStack._reset()
	setViewport(932, 430)
	local screen = Instance.new("ScreenGui")
	screen.Name = "PruebaTopStack"
	screen.IgnoreGuiInset = true
	screen.Parent = playerGui
	local board = Instance.new("Frame")
	board.Name = "Marcador"
	board.Size = roblox.UDim2.fromOffset(360, 58)
	board.Visible = false
	board.Parent = screen
	local rift = Instance.new("TextLabel")
	rift.Name = "Texto"
	rift.Size = roblox.UDim2.fromOffset(280, 40)
	rift.Parent = screen
	TopStack.register(board, P.Mission, { Id = "Marcador" })
	TopStack.register(rift, P.World, { Id = "Grieta" })
	check(rift.Visible and not board.Visible, "En vivo: el aviso de la grieta se ve solo (el marcador aún no)")
	TopStack.set(board, true)
	local by, ry = board.Position.Y.Offset, rift.Position.Y.Offset
	check(board.Visible and (not rift.Visible or ry >= by + 58), ("Sale el marcador de los pases: va arriba y la grieta, debajo de él o esperando (%d / %d)"):format(by, ry))
	local riftShown = rift.Visible
	localPlayer:SetAttribute("InDialogue", true)
	TopStack.refresh()
	check(not board.Visible and not rift.Visible, "Empieza la narración de una escena: el marcador y la grieta se apartan")
	check(TopStack.wanted(board), "…pero el marcador sigue pedido (vuelve al acabar si el juego sigue)")
	localPlayer:SetAttribute("InDialogue", nil)
	TopStack.refresh()
	check(board.Visible and rift.Visible == riftShown, "Acaba la narración: vuelven")
	TopStack.set(board, false)
	check(not board.Visible and rift.Visible and rift.Position.Y.Offset <= by, "Se acaba el juego: el marcador se va y la grieta sale en su sitio (arriba)")
	-- A los mandos de un avión: la grieta espera, el marcador sale debajo del panel y los avisos del HUD también
	TopStack.setPiloting("ShipHud")
	TopStack.set(board, true)
	local panelPx = TopStack.panelRect(roblox.Vector2.new(932, 430), { Touch = true, Inset = 58, Piloting = "ShipHud" })
	check(TopStack.isPiloting() and not rift.Visible and TopStack.wanted(rift) and board.Visible and board.Position.Y.Offset >= panelPx.Y + panelPx.H and TopStack.bottom() >= panelPx.Y + panelPx.H,
		"En vivo pilotando: la grieta espera (sigue pedida), el marcador va debajo del panel de instrumentos y los avisos del HUD debajo de todo")
	TopStack.set(board, false)
	TopStack.setPiloting(nil)
	check(rift.Visible and not TopStack.isPiloting(), "Al bajarse del avión vuelve el aviso de la grieta")
	screen:Destroy()
	TopStack._reset()

	-- El código: cada letrero de arriba va en la columna y el marcador se quita al acabar el juego
	local football = fs.readFile("src/client/Controllers/FootballClient.luau")
	local dropAt = football:find("local function dropView", 1, true)
	local dropEnd = dropAt and football:find("\nend\n", dropAt, true)
	local drop = if dropAt and dropEnd then football:sub(dropAt, dropEnd) else ""
	check(drop:find("TopStack.set(board, false)", 1, true) ~= nil, "Fútbol: al acabar tu juego (End) el marcador se quita (antes se quedaba arriba con los pases de entonces)")
	for _, file in { "FootballClient", "BasketClient", "VolleyClient", "RaceClient", "RacketClient", "OcioClient", "SkyRift" } do
		local src = fs.readFile("src/client/Controllers/" .. file .. ".luau")
		check(src:find("TopStack.register(", 1, true) ~= nil and not src:find("board.Visible = ", 1, true) and not src:find("banner.Visible = ", 1, true),
			file .. ": sus letreros de arriba van en la columna (TopStack), no sueltos")
	end
	local hudSrc = fs.readFile("src/client/UI/Hud.luau")
	check(hudSrc:find("TopStack.bottom()", 1, true) ~= nil and hudSrc:find("queuedToasts", 1, true) ~= nil, "Los avisos del HUD van debajo de la columna y en las escenas esperan a que acaben")
	check(hudSrc:find("TopStack.isPiloting()", 1, true) ~= nil, "Pilotando, los avisos del HUD van debajo del panel de instrumentos")
	local flyingSrc = fs.readFile("src/client/Controllers/Flying.luau")
	check(flyingSrc:find('TopStack.setPiloting, "ShipHud"', 1, true) ~= nil and flyingSrc:find("TopStack.setPiloting, nil", 1, true) ~= nil
		and flyingSrc:find("FlightFocus.enter", 1, true) ~= nil and flyingSrc:find("FlightFocus.exit", 1, true) ~= nil and flyingSrc:find("FlightStick.setEnabled(true)", 1, true) ~= nil,
		"Controllers/Flying: al pilotar, palanca analógica, HUD de vuelo (FlightFocus) y el panel libre (TopStack); al bajarse vuelve todo")
	local guideSrc = fs.readFile("src/client/Controllers/Guide.luau")
	check(guideSrc:find("TopStack.shownRects()", 1, true) ~= nil, "La flecha de los primeros pasos no se pone encima de un letrero de arriba")
end

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
