-- Prueba de la interfaz principal (UI/Hud y UI/Theme) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-hud.luau
--
-- Monta el HUD con un Roblox de mentira en el que cada propiedad que se escribe se comprueba contra
-- la base de datos de la API de Roblox (una propiedad mal escrita o en la clase equivocada falla).
-- Lo monta dos veces, como en el ordenador y como en el móvil, y comprueba que:
--   * en el ordenador sale el menú COMANDO abajo a la izquierda y tu estado abajo a la derecha
--   * en el móvil, iconos arriba a la derecha y tu estado arriba a la izquierda (sin menú COMANDO)
--   * las barras siguen a la salud, la energía, el hambre y la estamina
--   * los objetivos de la historia se dibujan y el botón Misiones los oculta
--   * en conversaciones y de bebé, los comandos y tu estado se apartan
--   * los avisos y las apps del teléfono funcionan

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
		__props = { Name = className, Visible = true },
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

local services = {
	TweenService = tweenService,
	ReplicatedStorage = replicatedStorage,
	Players = players,
	Lighting = lighting,
	GuiService = guiService,
	CollectionService = collection,
	UserInputService = userInput,
	RunService = service("RunService"),
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
local function loadModule(path: string): any
	if cache[path] ~= nil then
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
-- Montar el HUD
---------------------------------------------------------------------
local function mount(touch: boolean)
	-- Cada montaje empieza de cero (módulos y pantalla)
	table.clear(cache)
	table.clear(badWrites)
	for _, child in playerGui:GetChildren() do
		child:Destroy()
	end
	rawget(userInput, "__props").TouchEnabled = touch
	rawget(userInput, "__props").KeyboardEnabled = not touch
	localPlayer:SetAttribute("LifeStage", "Nino")
	local Hud = loadModule("src/client/UI/Hud")
	local storeOpened = false
	local ok, err = pcall(Hud.init, function()
		storeOpened = true
	end)
	return Hud, ok, err, function()
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

print("\n▶ En el ordenador")
local Hud, ok, err, storeOpened = mount(false)
check(ok, "El HUD se monta sin errores" .. (if ok then "" else ": " .. tostring(err)))
check(#badWrites == 0, "Todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
local hud = playerGui:FindFirstChild("MainHud")
local commands = hud and hud:FindFirstChild("Commands")
check(commands and commands.AnchorPoint == roblox.Vector2.new(0, 1) and commands.Position.Y.Scale == 1, "Menú COMANDO abajo a la izquierda")
local rowCount = 0
for _, child in if commands then commands:GetChildren() else {} do
	if child:IsA("TextButton") then
		rowCount += 1
	end
end
check(rowCount == 6, "Con 6 comandos (Mochila, Personaje, Mapa, Misiones, Teléfono, Menú)")
check(hud and textOf(hud, "COMANDO"), "Con la pestaña «COMANDO»")
check(hud and hud:FindFirstChild("CommandIcons") == nil, "Sin iconos de móvil")
local status = hud and hud:FindFirstChild("Status")
check(status and status.AnchorPoint == roblox.Vector2.new(1, 1) and status.Position.X.Scale == 1 and status.Position.Y.Scale == 1, "Tu estado abajo a la derecha")
local portrait = status and status:FindFirstChild("Portrait")
check(portrait and portrait.AnchorPoint.X == 1, "La foto a la derecha y las barras hacia la izquierda")
check(status and textOf(status, "Rayo") and textOf(status, "Nv 1"), "Con tu nombre y tu nivel")

-- Barras
localPlayer:SetAttribute("Energy", 25)
local energy = status and status:FindFirstChild("Energy")
local fill = energy and energy:FindFirstChildOfClass("Frame")
check(fill and math.abs(fill.Size.X.Scale - 0.25) < 0.01, "La barra de energía baja al 25 %")
check(fill and fill.AnchorPoint.X == 1, "Se vacía desde la punta lejana hacia la foto")
check(status and textOf(status, "⚡ 25"), "Y dice «⚡ 25»")
localPlayer:SetAttribute("Money", 1234)
check(status and textOf(status, "1"), "El dinero se actualiza")

-- Comandos: pulsar Misiones oculta los objetivos
local remote = remotes:FindFirstChild("LifeStory")
remote.OnClientEvent:Fire("State", {
	Tracked = { QuestId = "Nino_Jornada", Kind = "Main", TitleKey = "QUEST.DIA_COLE.TITLE", TextKey = "QUEST.DIA.LLEGA_COLE", Args = {} },
	Others = { { QuestId = "Eco_MateoDibujo", TitleKey = "QUEST.DIA_COLE.TITLE" } },
})
local objectives = hud and hud:FindFirstChild("Objectives")
check(objectives and textOf(objectives, "OBJETIVO PRINCIPAL") and textOf(objectives, "OBJETIVOS OPCIONALES"), "Objetivos con sus pestañas (principal y opcionales)")
local misiones = commands and commands:FindFirstChild("Misiones")
if misiones then
	misiones.Activated:Fire()
end
check(objectives and objectives.Visible == false, "El comando Misiones oculta los objetivos")
if misiones then
	misiones.Activated:Fire()
end
check(objectives and objectives.Visible == true, "Y los vuelve a mostrar")

-- Resaltado del comando bajo el ratón
local mochila = commands and commands:FindFirstChild("Mochila")
if mochila then
	mochila.MouseEnter:Fire()
end
check(mochila and mochila.BackgroundColor3 == roblox.Color3.new(1, 1, 1), "El comando bajo el ratón se ilumina")
local opened = false
Hud.setAction("Mochila", function()
	opened = true
end)
if mochila then
	mochila.Activated:Fire()
end
check(opened, "Pulsar Mochila abre la mochila")

-- Conversaciones y bebé
Hud.setBusy(true)
check(status and status.Visible == false and commands.Visible == false and objectives.Visible == false, "En una conversación se apartan comandos, estado y objetivos")
Hud.setBusy(false)
check(status and status.Visible == true and commands.Visible == true, "Y vuelven al acabar")
localPlayer:SetAttribute("LifeStage", "Bebe")
check(status and status.Visible == false and commands.Visible == false, "De bebé no hay comandos ni estado")
localPlayer:SetAttribute("LifeStage", "Nino")

-- Avisos y teléfono
Hud.toast("Money", "+50 $")
local toasts = hud and hud:FindFirstChild("Toasts")
check(toasts and textOf(toasts, "+50 $"), "Los avisos aparecen")
local popups = playerGui:FindFirstChild("HudPopups")
local phone = popups and popups:FindFirstChild("Phone")
local tienda = nil
for _, child in if phone then phone:GetChildren() else {} do
	if child:IsA("TextButton") and tostring(child.Text):find("Tienda") then
		tienda = child
	end
end
if tienda then
	tienda.Activated:Fire()
end
check(storeOpened(), "La app Tienda del teléfono abre la tienda")
check(#badWrites == 0, "Ninguna propiedad inventada al usarlo" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))

print("\n▶ En el móvil")
Hud, ok, err = mount(true)
check(ok, "El HUD se monta sin errores" .. (if ok then "" else ": " .. tostring(err)))
check(#badWrites == 0, "Todas las propiedades existen en Roblox" .. (if #badWrites > 0 then ": " .. table.concat(badWrites, ", ") else ""))
hud = playerGui:FindFirstChild("MainHud")
check(hud and hud:FindFirstChild("Commands") == nil, "Sin menú COMANDO (abajo va el joystick)")
local icons = hud and hud:FindFirstChild("CommandIcons")
check(icons and icons.AnchorPoint == roblox.Vector2.new(1, 0), "Iconos de comandos arriba a la derecha")
status = hud and hud:FindFirstChild("Status")
check(status and status.AnchorPoint == roblox.Vector2.new(0, 0) and status.Position.X.Scale == 0 and status.Position.Y.Scale == 0, "Tu estado arriba a la izquierda")
portrait = status and status:FindFirstChild("Portrait")
check(portrait and portrait.AnchorPoint.X == 0, "La foto a la izquierda y las barras hacia la derecha")

print()
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
