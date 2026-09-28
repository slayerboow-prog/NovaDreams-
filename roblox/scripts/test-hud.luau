-- Prueba de la interfaz principal FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-hud.luau
--
-- Monta el HUD (UI/Hud), el menú de comandos (Commands/CommandMenu), los botones táctiles
-- (UI/TouchLayout) y el joystick (Controllers/Joystick) con un Roblox de mentira en el que cada
-- propiedad que se escribe se comprueba contra la base de datos de la API de Roblox. Lo monta como en
-- el ordenador (1920x1080, 1600x900, 1366x768) y como en el móvil y la tableta (844x390, 932x430,
-- 1024x768) y comprueba que:
--   * tu estado va arriba a la izquierda, la hora en el centro, la misión a la derecha y el menú de
--     comandos abajo a la izquierda (en el móvil, justo encima del joystick); la barra rápida centrada
--   * NADA SE PISA: estado, reloj, minimapa, menú rápido, misión, comandos, barra rápida, joystick,
--     cada botón táctil y los botones de Roblox
--   * las barras, el dinero, la experiencia y la misión siguen a los atributos
--   * el menú de comandos se oculta y se muestra con su botón, y ⌄ despliega todos
--   * el menú rápido no tapa el minimapa; el joystick mueve al personaje (Humanoid:Move relativo)
--   * en conversaciones y de bebé se aparta lo que tapa la escena
--   * el GPS (Controllers/Gps) da la indicación bajo la reloj sin pisar nada

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
for _, name in { "LifeStory", "QuitJob", "GoHome" } do
	local remote = newInstance("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

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

-- Rectángulo en el lienzo de un objeto que cuelga directamente de una pantalla
local function rectOf(object, layout)
	local size = object.Size
	return layout.HudLayoutModule.rect({ Anchor = object.AnchorPoint, Position = object.Position, Size = roblox.Vector2.new(size.X.Offset, size.Y.Offset) }, layout.Canvas)
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
local function hudRects(mods, withQuick: boolean?)
	local HudLayout = mods.HudLayout
	local layout = HudLayout.current()
	layout.HudLayoutModule = HudLayout
	local hud = playerGui:FindFirstChild("MainHud")
	local popups = playerGui:FindFirstChild("HudPopups")
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
	table.insert(list, { Name = "Barra rápida", Rect = HudLayout.rect(layout.Items.Hotbar, layout.Canvas) })
	local phone = popups:FindFirstChild("Phone")
	local phoneButton = popups:FindFirstChild("PhoneButton")
	if withQuick ~= false then
		add("Menú rápido", phone)
		add("Botón del teléfono", phoneButton)
	end
	local commands = playerGui:FindFirstChild("CommandMenuGui")
	-- (el menú de comandos: su hueco entero, aunque tenga menos filas)
	if commands then
		table.insert(list, { Name = "Comandos", Rect = HudLayout.rect(layout.Items.Commands, layout.Canvas) })
	end
	local stick = playerGui:FindFirstChild("JoystickGui")
	add("Joystick", stick and stick:FindFirstChild("Joystick"))
	local gps = playerGui:FindFirstChild("GpsGui")
	add("Indicación del GPS", gps and gps:FindFirstChild("GpsBanner"))
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
check(status and status:FindFirstChild("Hunger") and status:FindFirstChild("Mood") and status:FindFirstChild("Health"), "Barras de energía, hambre, ánimo (o estamina) y salud")
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
check(gpsBanner.Visible == false and mods.Gps.path() == nil, "El botón ✕ quita la ruta")
localPlayer:SetAttribute("StoryTarget", roblox.Vector3.new(150, 0, -201))
mods.Gps.update()
check(gpsBanner.Visible, "Un objetivo nuevo vuelve a poner la ruta")

-- Derecha: la misión
local remote = remotes:FindFirstChild("LifeStory")
remote.OnClientEvent:Fire("State", {
	Tracked = { QuestId = "Nino_Jornada", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", TextKey = "QUEST.DIA.LLEGA_COLE", Args = {} },
	Others = { { QuestId = "Eco_MateoDibujo", TitleKey = "QUEST.DIA_COLE.TITLE" } },
})
local mission = hud and hud:FindFirstChild("Mission")
check(mission and mission.Visible and mission.Kind.Text == "MISIÓN PRINCIPAL", "Panel de la misión con «MISIÓN PRINCIPAL»")
check(mission and mission.Title.Text ~= "" and mission.Step.Text ~= "" and mission.Count.Text == "0/1", "Con el nombre, el paso («• …») y el contador «0/1»")
check(mission and mission:FindFirstChild("Chevron") ~= nil, "Y la flecha › para ver todas las misiones")
local popups = playerGui:FindFirstChild("HudPopups")
Hud.runCommand("Misiones")
local quests = popups and popups:FindFirstChild("Quests")
check(quests and textOf(quests, "MISIONES OPCIONALES"), "La flecha abre la lista de misiones (con las opcionales)")
Hud.runCommand("Misiones")
check(popups and popups:FindFirstChild("Quests") == nil, "Y se cierra otra vez")

-- Menú rápido: abierto en el ordenador, al lado del minimapa
local phone = popups and popups:FindFirstChild("Phone")
check(phone and phone.Visible and popups.PhoneButton.Visible == false, "Menú rápido abierto en el ordenador")
local tienda = phone and phone:FindFirstChild("Apps"):FindFirstChild("Tienda")
check(tienda and textOf(tienda, "Tienda"), "Con la app «Tienda» (icono y texto)")
if tienda then
	tienda.Activated:Fire()
end
check(storeOpened(), "La app Tienda abre la tienda")
check(phone and phone.Visible, "En el ordenador se queda abierto al usar una app")

-- Menú de comandos: abajo a la izquierda, con la pestaña COMANDOS
for i, name in { "Atacar", "Objetos", "Mapa", "Telefono", "Mas", "Extra" } do
	CommandRegistry.register({ Id = name, Label = name, Icon = "espada", Priority = i, Run = function() end })
end
CommandMenu.refresh()
local commandGui = playerGui:FindFirstChild("CommandMenuGui")
local commands = commandGui and commandGui:FindFirstChild("CommandMenu")
check(commands and commands.AnchorPoint == roblox.Vector2.new(0, 1) and commands.Position.Y.Scale == 1 and commands.Position.X.Offset == 16 and commands.Position.Y.Offset == -16, "Menú de comandos abajo a la izquierda")
check(commands and commands.Visible, "Visible con comandos")
check(commands and commands.Header.Title.Text == "COMANDOS" and commands.Header:FindFirstChild("Crown") ~= nil, "Con la pestaña «COMANDOS» y la corona")
local rows = commands and commands.List.Rows
local shown = 0
for _, row in if rows then rows:GetChildren() else {} do
	if row.Visible then
		shown += 1
	end
end
check(shown == 5 and commands.More.Visible, "Se ven 5 comandos y el desplegable ⌄ para los demás")
local selector = commands and commands.List.Selector
check(selector and selector.Visible and selector.Position.Y.Offset == 0, "El elegido lleva el selector azul (primera fila)")
if rows then
	rows.Row3.MouseEnter:Fire()
end
check(selector and selector.Position.Y.Offset == 2 * HudLayout.Sizes.CommandPitch, "El selector se desliza al comando bajo el ratón")
commands.More.Activated:Fire()
shown = 0
for _, row in rows:GetChildren() do
	if row.Visible then
		shown += 1
	end
end
check(shown == 6, "⌄ despliega todos los comandos")
commands.More.Activated:Fire()
local fullHeight = commands.Size.Y.Offset
commands.Header.Toggle.Activated:Fire()
check(CommandMenu.isCollapsed() and commands.List.Visible == false and commands.Size.Y.Offset == HudLayout.Sizes.CommandHeader, "El botón de la pestaña oculta los comandos (queda solo la pestaña)")
commands.Header.Toggle.Activated:Fire()
check(not CommandMenu.isCollapsed() and commands.List.Visible and commands.Size.Y.Offset == fullHeight, "Y los vuelve a mostrar")
check(commands and commands.Hint.Visible and commands.Hint.Text:find("Tab", 1, true) ~= nil, "Pista de teclas en el ordenador (Tab oculta)")

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
check(status.Visible == false and mission.Visible == false and phone.Visible == false and commands.Visible == false, "En una conversación se apartan estado, misión, menú rápido y comandos")
Hud.setBusy(false)
CommandMenu.setBusy(false)
check(status.Visible and mission.Visible and phone.Visible and commands.Visible, "Y vuelven al acabar")
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

-- Nada se pisa, en varios tamaños de ordenador
for _, size in { { 1920, 1080 }, { 1600, 900 }, { 1366, 768 } } do
	setViewport(size[1], size[2])
	local list, now = hudRects(mods)
	noOverlaps(list, HudLayout, ("%dx%d"):format(size[1], size[2]))
	local mini = HudLayout.rect(now.Items.Minimap, now.Canvas)
	local quick = rectOf(phone, now)
	check(not HudLayout.overlaps(mini, quick), ("%dx%d: el menú rápido no tapa el minimapa"):format(size[1], size[2]))
	local bar = HudLayout.rect(now.Items.Hotbar, now.Canvas)
	check(math.abs(bar.X + bar.W / 2 - now.Canvas.X / 2) < 0.5, ("%dx%d: barra rápida centrada"):format(size[1], size[2]))
end

---------------------------------------------------------------------
-- Móvil y tableta
---------------------------------------------------------------------
local function registerAll(TL)
	-- Los botones de siempre (los registran Combate, Correr, Gestos…) y cinco de contexto a la vez
	for _, id in { "Ataque", "Defender", "Correr", "Gestos", "Esquivar", "Fijar" } do
		TL.register({ Id = id, Icon = "espada", Label = id, Slot = id, Priority = 5, Callback = function() end })
	end
	for i, id in { "Linterna", "Foto", "Piedra", "Bajarse", "Sirena" } do
		TL.register({ Id = id, Icon = "linterna", Label = id, Priority = 10 + i, Callback = function() end, Badge = if id == "Piedra" then function()
			return "×3"
		end else nil })
	end
end

for _, size in { { 844, 390 }, { 932, 430 }, { 1024, 768 } } do
	print(("\n▶ En el móvil / tableta (%dx%d)"):format(size[1], size[2]))
	mods, ok, err = mount(true, size[1], size[2])
	HudLayout, TouchLayout, CommandMenu, CommandRegistry = mods.HudLayout, mods.TouchLayout, mods.CommandMenu, mods.CommandRegistry
	check(ok, "Se monta sin errores" .. (if ok then "" else ": " .. tostring(err)))
	check(#badWrites == 0, "Todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
	registerAll(TouchLayout)
	for i, name in { "Atacar", "Objetos", "Mapa", "Telefono", "Mas" } do
		CommandRegistry.register({ Id = name, Label = name, Icon = "espada", Priority = i, Run = function() end })
	end
	CommandMenu.refresh()
	TouchLayout.refresh()
	local buttons = TouchLayout.buttons()
	local visible = 0
	for _, button in buttons do
		if button.Visible then
			visible += 1
		end
	end
	check(visible == 13, "Racimo con Interactuar, Saltar, los 6 de siempre y 5 de contexto (" .. visible .. ")")
	check(buttons.Saltar and buttons.Saltar.Visible and buttons.Saltar:FindFirstChild("Caption").Text == "Saltar", "Botón Saltar propio (icono y texto)")
	check(buttons.Ataque and buttons.Ataque.Size.X.Offset > buttons.Correr.Size.X.Offset, "El Ataque es el botón grande")
	check(buttons.Piedra and buttons.Piedra.Badge.Visible and buttons.Piedra.Badge.Text == "×3", "Numerito en la esquina (piedras «×3»)")
	local now = HudLayout.current()
	local stick = playerGui:FindFirstChild("JoystickGui")
	stick = stick and stick:FindFirstChild("Joystick")
	check(stick and stick.Visible and localPlayer.DevTouchMovementMode == roblox.Enum.DevTouchMovementMode.Scriptable, "Joystick propio (en lugar del de Roblox)")
	local stickRect = stick and rectOf(stick, (function()
		now.HudLayoutModule = HudLayout
		return now
	end)())
	local commandRect = HudLayout.rect(now.Items.Commands, now.Canvas)
	check(stickRect and stickRect.X < now.Canvas.X * 0.3 and stickRect.Y + stickRect.H > now.Canvas.Y * 0.9, "El joystick abajo a la izquierda")
	check(stickRect and commandRect.Y + commandRect.H <= stickRect.Y and commandRect.X <= 20, "El menú de comandos a la izquierda, justo encima del joystick")
	-- Ocultar los comandos en el móvil: el botón ˅ es diminuto; tocar la pestaña entera también vale
	local phoneCommands = playerGui:FindFirstChild("CommandMenuGui")
	phoneCommands = phoneCommands and phoneCommands:FindFirstChild("CommandMenu")
	local tab = phoneCommands and phoneCommands.Header:FindFirstChild("HeaderHit")
	if tab then
		tab.Activated:Fire()
		local hidden = CommandMenu.isCollapsed() and phoneCommands.List.Visible == false
		tab.Activated:Fire()
		check(hidden and not CommandMenu.isCollapsed() and phoneCommands.List.Visible, "Tocar la pestaña COMANDOS los oculta y los vuelve a mostrar")
	else
		check(false, "Falta la pestaña de los comandos")
	end
	local popupsGui = playerGui:FindFirstChild("HudPopups")
	check(popupsGui.Phone.Visible == false and popupsGui.PhoneButton.Visible, "En el móvil el menú rápido empieza cerrado (botón del teléfono)")
	local list = hudRects(mods)
	noOverlaps(list, HudLayout, ("%dx%d con el menú rápido cerrado"):format(size[1], size[2]))
	-- Abrir el menú rápido con el botón del teléfono
	popupsGui.PhoneButton.Activated:Fire()
	check(popupsGui.Phone.Visible, "El botón del teléfono abre el menú rápido")
	list = hudRects(mods)
	noOverlaps(list, HudLayout, ("%dx%d con el menú rápido abierto"):format(size[1], size[2]))
	local tile = popupsGui.Phone.Apps:FindFirstChild("Ir a casa")
	if tile then
		tile.Activated:Fire()
	end
	check(popupsGui.Phone.Visible == false, "En el móvil se cierra al usar una app (deja ver el mundo)")

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

	-- Conduciendo: el cuadro de mandos (VehicleHud) no tapa la indicación del GPS, los avisos, las
	-- estrellas de búsqueda ni nada de arriba o de abajo (con y sin estrellas)
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
			local mine = { X = x / s, Y = y / s, W = w / s, H = h / s } -- (en el lienzo del HUD)
			local clashes = {}
			local others = hudRects(mods)
			for _, name in if stars > 0 then { "Gps", "Activity", "Wanted" } else { "Gps", "Activity" } do
				table.insert(others, { Name = name, Rect = HudLayout.rect(now.Items[name], now.Canvas) })
			end
			for name, slot in now.Slots do
				table.insert(others, { Name = "Hueco " .. name, Rect = HudLayout.rect(slot, now.Canvas) })
			end
			for _, other in others do
				if HudLayout.overlaps(mine, other.Rect) then
					table.insert(clashes, other.Name)
				end
			end
			check(#clashes == 0 and mine.Y + mine.H < now.Canvas.Y, ("Conduciendo (%d estrellas): el cuadro de mandos no pisa nada%s"):format(stars, if #clashes > 0 then ": " .. table.concat(clashes, ", ") else ""))
		else
			check(false, "Conduciendo: falta el cuadro de mandos")
		end
	end
	localPlayer:SetAttribute("Wanted", nil)
	check(#badWrites == 0, "Ninguna propiedad inventada al usarlo" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
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

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
