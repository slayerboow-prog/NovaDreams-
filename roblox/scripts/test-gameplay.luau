-- Prueba automática de los sistemas de juego nuevos FUERA de Roblox, con Lune:
-- vehículos, autoescuela, recreativos y restaurante (con 1 y 2 jugadores; el resto, NPC).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-gameplay.luau
--
-- Carga los servicios reales de src/ con un "Roblox de mentira": instancias falsas (piezas,
-- modelos, atributos, etiquetas, avisos de proximidad) y dobles de DataService, LifeService…

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local ROOT = "src"
local CFrame, Vector3, Color3, Enum = roblox.CFrame, roblox.Vector3, roblox.Color3, roblox.Enum

---------------------------------------------------------------------
-- Señales e instancias falsas
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	local s = {}
	function s:Connect(fn)
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
	function s:Fire(...)
		for _, fn in table.clone(handlers) do
			fn(...)
		end
	end
	function s:Wait()
		return nil
	end
	return s
end

local EVENTS = { Triggered = true, Died = true, Destroying = true, Completed = true, CharacterRemoving = true, CharacterAdded = true, Activated = true, Event = true, ChildAdded = true }
local PARTS = { Part = true, Seat = true, VehicleSeat = true, WedgePart = true, CornerWedgePart = true }

local Fake = {}
local FakeMeta = {}
local worldRoot

local function fakeInstance(className: string)
	local obj = setmetatable({
		__props = { ClassName = className, Name = className },
		__attrs = {},
		__attrSignals = {},
		__tags = {},
		__children = {},
	}, FakeMeta)
	if PARTS[className] then
		obj.__props.CFrame = CFrame.new()
		obj.__props.Size = Vector3.new(1, 1, 1)
	end
	return obj
end

function Fake.IsA(self, name)
	local class = self.__props.ClassName
	return class == name or name == "Instance" or (name == "BasePart" and PARTS[class] ~= nil) or (name == "GuiButton" and class == "TextButton")
end
function Fake.Destroy(self)
	if self.__destroyed then
		return
	end
	self.__destroyed = true
	if self.__props.Destroying then
		self.__props.Destroying:Fire()
	end
	for _, child in table.clone(self.__children) do
		child:Destroy()
	end
	self.Parent = nil
end
function Fake.GetAttribute(self, name)
	return self.__attrs[name]
end
function Fake.SetAttribute(self, name, value)
	self.__attrs[name] = value
	if self.__attrSignals[name] then
		self.__attrSignals[name]:Fire()
	end
end
function Fake.GetAttributeChangedSignal(self, name)
	self.__attrSignals[name] = self.__attrSignals[name] or signal()
	return self.__attrSignals[name]
end
function Fake.GetPropertyChangedSignal(self, name)
	local signals = rawget(self, "__propSignals")
	if not signals then
		signals = {}
		rawset(self, "__propSignals", signals)
	end
	signals[name] = signals[name] or signal()
	return signals[name]
end
-- Asientos: Seat:Sit sienta al humanoide (Occupant / SeatPart y la soldadura SeatWeld)
function Fake.Sit(self, humanoid)
	local weld = fakeInstance("Weld")
	weld.Name = "SeatWeld"
	weld.C1 = CFrame.new()
	weld.Parent = self
	humanoid.SeatPart = self
	self.Occupant = humanoid
end
function Fake.Raycast()
	return nil -- sin suelo de verdad: los vehículos salen a la altura del personaje
end
function Fake.AddTag(self, tag)
	self.__tags[tag] = true
end
function Fake.HasTag(self, tag)
	return self.__tags[tag] == true
end
function Fake.GetChildren(self)
	return table.clone(self.__children)
end
function Fake.PivotTo(self, cf)
	local primary = self.__props.PrimaryPart
	if primary then
		primary.CFrame = cf
	end
end
function Fake.FindFirstAncestorOfClass(self, className)
	local p = self.__props.Parent
	while p do
		if p.ClassName == className then
			return p
		end
		p = p.__props.Parent
	end
	return nil
end
function Fake.IsDescendantOf(self, ancestor)
	local p = self.__props.Parent
	while p do
		if p == ancestor then
			return true
		end
		p = p.__props.Parent
	end
	return false
end
function Fake.GetDescendants(self)
	local list = {}
	local function walk(o)
		for _, c in o.__children do
			table.insert(list, c)
			walk(c)
		end
	end
	walk(self)
	return list
end
function Fake.FindFirstChild(self, name, recursive)
	for _, c in self.__children do
		if c.__props.Name == name then
			return c
		end
	end
	if recursive then
		for _, c in self.__children do
			local found = c:FindFirstChild(name, true)
			if found then
				return found
			end
		end
	end
	return nil
end
function Fake.FindFirstChildOfClass(self, className)
	for _, c in self.__children do
		if c.__props.ClassName == className then
			return c
		end
	end
	return nil
end
function Fake.WaitForChild(self, name)
	return self:FindFirstChild(name)
end
function Fake.SetStateEnabled() end
function Fake.SetNetworkOwner() end

FakeMeta.__index = function(self, key)
	if Fake[key] then
		return Fake[key]
	end
	local props = rawget(self, "__props")
	if key == "Position" and props.CFrame then
		return props.CFrame.Position
	end
	if key == "Rotation" and props.CFrame then
		return props.CFrame.Rotation
	end
	if props[key] ~= nil then
		return props[key]
	end
	if EVENTS[key] then
		props[key] = signal()
		return props[key]
	end
	for _, c in rawget(self, "__children") do
		if c.__props.Name == key then
			return c
		end
	end
	return nil
end
FakeMeta.__newindex = function(self, key, value)
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old then
			local i = table.find(old.__children, self)
			if i then
				table.remove(old.__children, i)
			end
		end
		props.Parent = value
		if value then
			table.insert(value.__children, self)
			local added = rawget(value, "__props").ChildAdded
			if added then
				added:Fire(self)
			end
		end
	elseif key == "Position" then
		props.CFrame = CFrame.new(value) * (props.CFrame and props.CFrame.Rotation or CFrame.new())
	else
		props[key] = value
		-- Bajarse del asiento (Sit = false o se quita la soldadura)
		if key == "Sit" and value == false and props.SeatPart then
			local seat = props.SeatPart
			props.SeatPart = nil
			seat.Occupant = nil
		end
	end
	local signals = rawget(self, "__propSignals")
	if signals and signals[key] then
		signals[key]:Fire()
	end
end

local FakeInstanceLib = {
	new = function(className: string, parent)
		local obj = fakeInstance(className)
		if parent then
			obj.Parent = parent
		end
		return obj
	end,
}

local function fakeTypeof(value)
	if type(value) == "table" and rawget(value, "__props") then
		return "Instance"
	end
	return typeof(value)
end

---------------------------------------------------------------------
-- Servicios de mentira
---------------------------------------------------------------------
worldRoot = fakeInstance("Workspace")
worldRoot.Name = "Workspace"

local collection = {}
function collection:GetTagged(tag)
	local list = {}
	for _, d in worldRoot:GetDescendants() do
		if d:HasTag(tag) then
			table.insert(list, d)
		end
	end
	return list
end
function collection:GetInstanceAddedSignal()
	return signal()
end

local function remote()
	local r = { OnServerEvent = signal() }
	function r:FireClient(player, ...)
		table.insert(player.Inbox, table.pack(...))
	end
	return r
end
local remotes = {
	Notify = remote(),
	QuitJob = remote(),
	Vehicle = remote(),
	DrivingSchool = remote(),
	Arcade = remote(),
	Restaurant = remote(),
	Inventory = remote(),
	Progression = remote(),
	Supermarket = remote(),
	Cafe = remote(),
	Post = remote(),
	Garbage = remote(),
	Medical = remote(),
	Police = remote(),
	Fire = remote(),
	Cinema = remote(),
	Hotel = remote(),
}
function remotes:WaitForChild(name)
	return self[name]
end
function remotes:FindFirstChild(name)
	return rawget(self, name)
end

local playersList = {}
local players = { PlayerAdded = signal(), PlayerRemoving = signal() }
function players:GetPlayers()
	return table.clone(playersList)
end
function players:CreateHumanoidModelFromDescription()
	error("sin avatares en la prueba")
end
function players:GetNameFromUserIdAsync(id)
	return "Jugador" .. id
end

local guid = 0
local services = {
	CollectionService = collection,
	Players = players,
	Lighting = { ClockTime = 21 }, -- de noche: los faros se encienden
	ReplicatedStorage = { Shared = nil, Remotes = remotes },
	HttpService = {
		JSONEncode = function(_, value)
			return require("@lune/serde").encode("json", value)
		end,
		JSONDecode = function(_, text)
			return require("@lune/serde").decode("json", text)
		end,
		GenerateGUID = function()
			guid += 1
			return "token-" .. guid
		end,
	},
	TweenService = {
		Create = function(_, instance, _, goal)
			local tween = { Completed = signal() }
			function tween.Play()
				for key, value in goal do
					instance[key] = value
				end
			end
			return tween
		end,
	},
	DataStoreService = {
		GetOrderedDataStore = function()
			error("sin DataStore en la prueba")
		end,
	},
}
local fakeGame = {}
function fakeGame:GetService(name)
	return services[name] or error("Servicio sin doble: " .. name)
end

---------------------------------------------------------------------
-- Cargador de módulos (script.Parent.X y require como en Roblox)
---------------------------------------------------------------------
local mocks: { [string]: any } = {}
local cache: { [string]: any } = {}
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
services.ReplicatedStorage.Shared = node(ROOT .. "/shared")
function services.ReplicatedStorage:WaitForChild(name)
	return self[name]
end
function services.ReplicatedStorage:FindFirstChild(name)
	return rawget(self, name)
end

local function loadModule(path: string): any
	if mocks[path] ~= nil then
		return mocks[path]
	end
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return loadModule(rawget(target, "__path"))
		end,
		game = fakeGame,
		workspace = worldRoot,
		task = task,
		Instance = FakeInstanceLib,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrame,
		Color3 = Color3,
		Enum = Enum,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		TweenInfo = { new = function() return {} end },
		RaycastParams = { new = function() return {} end },
		typeof = fakeTypeof,
		warn = function(...)
			print("[warn]", ...)
		end,
	}, { __index = _G })
	local chunk = luau.load(fs.readFile(path .. ".luau"), { debugName = path, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

---------------------------------------------------------------------
-- Dobles de servicios que dependen de Roblox de verdad
---------------------------------------------------------------------
local profiles = {}
local loadedCallbacks = {}
local S = ROOT .. "/server/Services/"
mocks[S .. "DataService"] = {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function(callback)
		table.insert(loadedCallbacks, callback)
	end,
	addMoney = function(player, amount)
		profiles[player].Money = math.max(0, profiles[player].Money + amount)
		return true
	end,
	spend = function(player, price)
		if profiles[player].Money < price then
			return false
		end
		profiles[player].Money -= price
		return true
	end,
}
local Stages = loadModule(ROOT .. "/shared/LifeStory/Stages")
local Config = loadModule(ROOT .. "/shared/Config")
mocks[S .. "LifeService"] = {
	allows = function(player, action)
		return Stages.allows(player:GetAttribute("LifeStage"), action, Config.StageLimits)
	end,
	refresh = function() end,
}
local needsChanges = {}
mocks[S .. "NeedsService"] = {
	canWork = function()
		return true
	end,
	change = function(player, hunger, energy)
		table.insert(needsChanges, { player, hunger, energy })
	end,
	refreshSpeed = function() end,
}
mocks[S .. "MonetizationService"] = { payMultiplier = function() return 1 end }
local jobProviders, jobStarts = {}, {}
mocks[S .. "JobService"] = {
	quit = function() end,
	setProvider = function(id, provider)
		jobProviders[id] = provider
	end,
	shiftOf = function()
		return nil
	end,
	start = function(player, id, context)
		table.insert(jobStarts, { player, id, context })
	end,
	setHandler = function(id, handler)
		jobProviders["Handler_" .. id] = handler
	end,
}
mocks[ROOT .. "/server/World/Region"] = { Towns = { { Name = "Los Pinos", Center = Vector3.new(0, 0, 1100) } } }

local Gameplay = loadModule(ROOT .. "/shared/Gameplay")
-- Tiempos cortos para que la prueba vaya rápida
Gameplay.Restaurant.SpawnEvery = { 0, 0 }
Gameplay.Restaurant.SpeakSeconds = 0.05
Gameplay.Restaurant.NpcWaiterSeconds = 0.05
Gameplay.Restaurant.NpcBarmanSeconds = 0.05
Gameplay.Restaurant.EatSeconds = 0.1
Gameplay.Arcade.Games.Bolas.MinSeconds = 0
Gameplay.Arcade.Games.Canasta.MinSeconds = 0

---------------------------------------------------------------------
-- Mapa mínimo con las mismas etiquetas que el de verdad
---------------------------------------------------------------------
local function part(name, cf, tags, attrs, className)
	local p = fakeInstance(className or "Part")
	p.Name = name
	p.CFrame = cf
	for _, tag in tags or {} do
		p:AddTag(tag)
	end
	for k, v in attrs or {} do
		p:SetAttribute(k, v)
	end
	p.Parent = worldRoot
	return p
end

local R0 = CFrame.new(300, 0, -40) -- restaurante
part("Board", R0 * CFrame.new(-16, 4.8, -22), { "RestaurantBoard" })
part("BarStation", R0 * CFrame.new(4, 3, 13), { "RestaurantBar" })
part("Pass", R0 * CFrame.new(-8, 4, 9), { "RestaurantPass" })
part("Door", R0 * CFrame.new(0, 3, -22), { "RestaurantDoor" })
part("WaiterSpot", R0 * CFrame.new(-4, 3, 4), { "RestaurantWaiterSpot" })
part("BarmanSpot", R0 * CFrame.new(8, 3, 13.5), { "RestaurantBarmanSpot" })
for i, p in { { -21, -9 }, { -11, -9 }, { 11, -9 } } do
	part("Top", R0 * CFrame.new(p[1], 3, p[2]), { "RestaurantTable" }, { TableId = i })
	for _, dir in { -1, 1 } do
		local seat = part("Seat", R0 * CFrame.new(p[1] + dir * 3.4, 1.9, p[2]) * CFrame.Angles(0, if dir > 0 then math.rad(90) else math.rad(-90), 0), { "RestaurantSeat" }, { TableId = i }, "Seat")
		seat.Size = Vector3.new(2, 0.3, 2)
	end
end
local machineBolas = part("Console", CFrame.new(0, 2, 500), { "ArcadeMachine" }, { GameId = "Bolas" })
local machineCanasta = part("Console", CFrame.new(5, 2, 500), { "ArcadeMachine" }, { GameId = "Canasta" })
local prizeCounter = part("PrizeCounter", CFrame.new(10, 2, 500), { "PrizeCounter" })
part("Scoreboard", CFrame.new(0, 10, 510), { "ArcadeScoreboard" })
local school = part("Signup", CFrame.new(100, 3, 1000), { "DrivingSchool" }, { Town = "Los Pinos" })
local station = part("RentalPoint", CFrame.new(-50, 3, -24), { "RentalStation" })
local fuelPump = part("Pump", CFrame.new(-300, 3, -300), { "FuelPump" })

---------------------------------------------------------------------
-- Jugadores
---------------------------------------------------------------------
local playersFolder = fakeInstance("Players")

local function newPlayer(id: number, stage: string, money: number)
	local player = fakeInstance("Player")
	player.Name = "Jugador" .. id
	player.UserId = id
	player.Inbox = {}
	player:SetAttribute("LifeStage", stage)
	profiles[player] = { Money = money, Stats = { TasksDone = 0, MoneyEarned = 0 } }
	local character = fakeInstance("Model")
	character.Name = player.Name
	local humanoid = fakeInstance("Humanoid")
	humanoid.HipHeight = 2
	humanoid.Health = 100
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.Parent = character
	local root = fakeInstance("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(0, 3, 0)
	root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	root.Parent = character
	local head = fakeInstance("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = CFrame.new(0, 4.6, 0)
	head.Parent = character
	character.Parent = worldRoot
	player.Character = character
	player.Parent = playersFolder
	table.insert(playersList, player)
	return player, root, humanoid
end

local function moveTo(root, position: Vector3)
	root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
end

local function lastMessage(player, kind)
	for i = #player.Inbox, 1, -1 do
		local m = player.Inbox[i]
		if m[1] == kind then
			return m
		end
	end
	return nil
end

local function clearInbox(player)
	table.clear(player.Inbox)
end

local function promptOf(instance, action)
	for _, c in instance:GetDescendants() do
		if c.ClassName == "ProximityPrompt" and (action == nil or c.ActionText == action) then
			return c
		end
	end
	return nil
end

local function waitFor(condition: () -> boolean, seconds: number?, what: string)
	local deadline = os.clock() + (seconds or 5)
	while not condition() do
		if os.clock() > deadline then
			error("Tiempo agotado esperando: " .. what)
		end
		task.wait(0.02)
	end
end

local failures = 0
local function check(ok: boolean, text: string)
	print((if ok then "  ✅ " else "  ❌ ") .. text)
	if not ok then
		failures += 1
	end
end

local function notified(player, pattern)
	for _, m in player.Inbox do
		if type(m[2]) == "string" and string.find(m[2], pattern, 1, true) then
			return true
		end
	end
	return false
end

-- Notify:FireClient(player, kind, text) guarda { kind, text }
local function notifyTexts(player)
	local list = {}
	for _, m in player.Inbox do
		if type(m[2]) == "string" then
			table.insert(list, m[2])
		end
	end
	return list
end

---------------------------------------------------------------------
-- Arranque de servicios reales
---------------------------------------------------------------------
local VehicleService = loadModule(S .. "VehicleService")
local RestaurantService = loadModule(S .. "RestaurantService")
local DrivingSchoolService = loadModule(S .. "DrivingSchoolService")
local ArcadeService = loadModule(S .. "ArcadeService")
VehicleService.init()
RestaurantService.init()
DrivingSchoolService.init()
ArcadeService.init()

-- Si algo se atasca, la prueba falla en vez de quedarse colgada
task.delay(240, function()
	print("❌ La prueba ha tardado demasiado")
	process.exit(1)
end)

local ok, err = xpcall(function()
---------------------------------------------------------------------
print("▶ Textos de las comandas y puntos del lanzabolas")
check(Gameplay.orderText({ "BocataJamon", "Zumo" }) == "Bocadillo de jamón y zumo de naranja", "comanda de dos platos en español natural")
check(Gameplay.bolasScore(0.9) == 100 and Gameplay.bolasScore(0.97) == 20 and Gameplay.bolasScore(0.1) == 10, "zonas del lanzabolas")

---------------------------------------------------------------------
print("▶ Vehículos")
local teen, teenRoot, teenHumanoid = newPlayer(1, "Adolescente", 1000)
local kid = newPlayer(2, "Nino", 1000)
promptOf(station, "Coger monopatín").Triggered:Fire(kid)
check(kid:GetAttribute("Riding") == nil, "un niño no puede coger el monopatín público")
promptOf(station, "Coger bicicleta").Triggered:Fire(kid)
check(kid:GetAttribute("Riding") == "Bici", "un niño ya puede coger la bici pública")
remotes.Vehicle.OnServerEvent:Fire(kid, "Dismount")
promptOf(station, "Coger patinete eléctrico").Triggered:Fire(kid)
check(kid:GetAttribute("Riding") == "Patinete", "un niño ya puede coger el patinete")
remotes.Vehicle.OnServerEvent:Fire(kid, "Dismount")
check(kid:GetAttribute("Riding") == nil, "el niño se baja del patinete")
local baby = newPlayer(20, "Bebe", 0)
promptOf(station, "Coger bicicleta").Triggered:Fire(baby)
check(baby:GetAttribute("Riding") == nil, "un bebé no puede coger la bici")
promptOf(station, "Coger bicicleta").Triggered:Fire(teen)
check(teen:GetAttribute("Riding") == "Bici" and teen:GetAttribute("VehicleSpeed") == Gameplay.Vehicles.Bici.Speed, "un adolescente coge la bici pública y va más rápido")
check(teenHumanoid.SeatPart ~= nil and teenHumanoid.SeatPart.Name == "DriverSeat", "se sienta en el asiento de conductor de la bici")
remotes.Vehicle.OnServerEvent:Fire(teen, "Dismount")
check(teen:GetAttribute("Riding") == nil and teenHumanoid.SeatPart == nil, "se baja del asiento")
check(#worldRoot:FindFirstChild("Rides"):GetChildren() == 0, "la bici pública desaparece al bajarse")
promptOf(station, "Coger patinete eléctrico").Triggered:Fire(teen)
check(teen:GetAttribute("Riding") == "Patinete", "coge el patinete eléctrico público")
teenHumanoid.Sit = false
check(teen:GetAttribute("Riding") == nil, "saltar le baja del patinete")
remotes.Vehicle.OnServerEvent:Fire(teen, "Buy", "Coche")
check(profiles[teen].Money == 1000, "un adolescente no puede comprarse un coche")
remotes.Vehicle.OnServerEvent:Fire(teen, "Buy", "Monopatin")
check(profiles[teen].Money == 850 and teen:GetAttribute("OwnedVehicles") == "Monopatin", "compra su monopatín")
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Monopatin")
check(teen:GetAttribute("Riding") == "Monopatin", "saca su monopatín en cualquier sitio")
local rides = worldRoot:FindFirstChild("Rides")
check(rides ~= nil and #rides:GetChildren() == 1, "hay un solo vehículo con el jugador")
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Bici")
check(teen:GetAttribute("Riding") == "Monopatin", "no puede sacar una bici que no tiene")
teenHumanoid.Died:Fire()
check(teen:GetAttribute("Riding") == nil and #rides:GetChildren() == 1, "si muere, su monopatín se queda aparcado")
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Monopatin")
check(teen:GetAttribute("Riding") == "Monopatin" and #rides:GetChildren() == 1, "al sacarlo otra vez no se duplica")
remotes.Vehicle.OnServerEvent:Fire(teen, "Dismount")

---------------------------------------------------------------------
print("▶ Autoescuela")
local adult, adultRoot = newPlayer(3, "AdultoJoven", 20000)
remotes.Vehicle.OnServerEvent:Fire(adult, "Buy", "Coche")
remotes.Vehicle.OnServerEvent:Fire(adult, "Spawn", "Coche")
check(adult:GetAttribute("Riding") == nil, "sin carnet no puede conducir su coche")
promptOf(school).Triggered:Fire(teen)
check(lastMessage(teen, "Menu") == nil, "un adolescente no puede sacarse el carnet")

local function answerTheory(player, rightAnswers: number)
	local msg = lastMessage(player, "Theory")
	local token, exam = msg[2], msg[3]
	local answers = {}
	for i, question in exam.Questions do
		local correct = nil
		for _, q in Gameplay.TheoryQuestions do
			if q[1] == question.Text then
				correct = table.find(question.Options, q[2][1])
			end
		end
		answers[i] = if i <= rightAnswers then correct else (correct % 3) + 1
	end
	remotes.DrivingSchool.OnServerEvent:Fire(player, "Answers", token, answers)
end

promptOf(school).Triggered:Fire(adult)
local menu = lastMessage(adult, "Menu")
check(menu ~= nil and #menu[3] == 2, "la autoescuela ofrece carnet A y B")
remotes.DrivingSchool.OnServerEvent:Fire(adult, "Choose", menu[2], "B")
check(profiles[adult].Money == 20000 - 9000 - 400, "paga la matrícula del carnet B")
answerTheory(adult, 3)
check(adult:GetAttribute("Riding") == nil and not VehicleService.hasLicense(adult, "B"), "con 3 de 5 suspende el teórico")

clearInbox(adult)
promptOf(school).Triggered:Fire(adult)
remotes.DrivingSchool.OnServerEvent:Fire(adult, "Choose", lastMessage(adult, "Menu")[2], "B")
answerTheory(adult, 5)
check(adult:GetAttribute("Riding") == "Coche", "aprueba el teórico y empieza el práctico en coche")
local target = adult:GetAttribute("TaskTarget")
check(typeof(target) == "Vector3" and (Vector3.new(target.X, 0, target.Z) - Vector3.new(-240 + 240, 0, 1100 - 240)).Magnitude < 400, "el primer punto está en una calle del pueblo")
for _ = 1, Gameplay.Practical.Checkpoints do
	local point = adult:GetAttribute("TaskTarget")
	if typeof(point) ~= "Vector3" then
		break
	end
	moveTo(adultRoot, point)
	task.wait(0.3)
end
check(VehicleService.hasLicense(adult, "B"), "pasa por todos los puntos y aprueba el carnet B")
check(adult:GetAttribute("Riding") == nil and adult:GetAttribute("TaskTarget") == nil, "al aprobar se baja del coche de prácticas")
remotes.Vehicle.OnServerEvent:Fire(adult, "Spawn", "Coche")
check(adult:GetAttribute("Riding") == "Coche" and adult:GetAttribute("VehicleSpeed") == Gameplay.Vehicles.Coche.Speed, "ya puede conducir su coche")
local carModel = worldRoot.Rides:FindFirstChild("Coche")
local beam = carModel and carModel:FindFirstChild("Headlight") and carModel.Headlight:FindFirstChildOfClass("SpotLight")
check(beam ~= nil and beam.Enabled == true, "de noche el coche lleva los faros encendidos")
check(adult:GetAttribute("Fuel") == 1 and adult:GetAttribute("FuelType") == "Gasolina" and adult:GetAttribute("Odometer") == 0, "su coche nuevo sale con el depósito lleno y 0 km")
local carChassis = carModel.PrimaryPart
carChassis.CFrame = carChassis.CFrame * CFrame.new(0, 0, -150)
task.wait(0.6)
for _ = 1, 7 do
	carChassis.CFrame = carChassis.CFrame * CFrame.new(0, 0, -150)
	task.wait(0.55)
end
local fuelNow = adult:GetAttribute("Fuel")
check(fuelNow < 1 and fuelNow > 0.9 and adult:GetAttribute("Odometer") > 0.25, "conduciendo baja el combustible y suben los kilómetros")
carChassis.CFrame = fuelPump.CFrame * CFrame.new(0, 0, 6)
task.wait(0.6)
local moneyBeforeFuel = profiles[adult].Money
promptOf(fuelPump, "Repostar / cargar").Triggered:Fire(adult)
check(adult:GetAttribute("Fuel") == 1 and profiles[adult].Money < moneyBeforeFuel and notified(adult, "repostado"), "en la gasolinera reposta y paga los litros")
remotes.Vehicle.OnServerEvent:Fire(adult, "Dismount")
check(adult:GetAttribute("Fuel") == nil and profiles[adult].Fuel and profiles[adult].Fuel.Coche == 50 and profiles[adult].Odometer.Coche > 0.25, "al bajarse se guardan la gasolina y los kilómetros de su coche")
remotes.Vehicle.OnServerEvent:Fire(adult, "Spawn", "Coche")
remotes.Vehicle.OnServerEvent:Fire(adult, "Dismount")

-- Suspender por bajarse en el práctico
clearInbox(adult)
promptOf(school).Triggered:Fire(adult)
remotes.DrivingSchool.OnServerEvent:Fire(adult, "Choose", lastMessage(adult, "Menu")[2], "A")
answerTheory(adult, 4)
check(adult:GetAttribute("Riding") == "Moto", "con 4 de 5 aprueba el teórico de moto")
remotes.Vehicle.OnServerEvent:Fire(adult, "Dismount")
check(not VehicleService.hasLicense(adult, "A") and adult:GetAttribute("TaskTarget") == nil, "si se baja en el práctico, suspende")

---------------------------------------------------------------------
print("▶ Recreativos")
profiles[kid].Money = 100
promptOf(machineBolas).Triggered:Fire(kid)
local play = lastMessage(kid, "Play")
check(play ~= nil and profiles[kid].Money == 95, "jugar al lanzabolas cuesta 5 $")
remotes.Arcade.OnServerEvent:Fire(kid, "Result", play[2], { 0.9, 0.9, 0.9, 0.8, 0.65, 0.1 })
check(profiles[kid].Tickets == 39, "3 bolas de 100 + 50 + 30 + 10 = 390 puntos = 39 tickets")
remotes.Arcade.OnServerEvent:Fire(kid, "Result", play[2], { 0.9, 0.9, 0.9, 0.9, 0.9, 0.9 })
check(profiles[kid].Tickets == 39, "no se puede cobrar dos veces la misma partida")
promptOf(machineCanasta).Triggered:Fire(kid)
remotes.Arcade.OnServerEvent:Fire(kid, "Result", lastMessage(kid, "Play")[2], 999)
check(profiles[kid].Tickets == 39 + Gameplay.Arcade.Games.Canasta.MaxScore, "las canastas tienen un máximo (anti-trampas)")
promptOf(prizeCounter).Triggered:Fire(kid)
check(lastMessage(kid, "Prizes") ~= nil, "el mostrador abre los premios")
remotes.Arcade.OnServerEvent:Fire(kid, "Redeem", "Gafas")
check(profiles[kid].Prizes.Gafas and profiles[kid].Wearing.Gafas, "canjea las gafas y se las pone")
check(kid.Character:FindFirstChild("Wearable_Gafas") ~= nil, "las gafas aparecen en la cabeza")
remotes.Arcade.OnServerEvent:Fire(kid, "Wear", "Gafas")
check(kid.Character:FindFirstChild("Wearable_Gafas") == nil, "se las puede quitar")
local before = profiles[kid].Tickets
remotes.Arcade.OnServerEvent:Fire(kid, "Redeem", "Bici")
check(profiles[kid].Tickets == before, "sin tickets suficientes no hay bici")
profiles[kid].Tickets = 1000
kid:SetAttribute("OwnedVehicles", nil)
remotes.Arcade.OnServerEvent:Fire(kid, "Redeem", "Monopatin")
check(profiles[kid].Vehicles and profiles[kid].Vehicles.Monopatin == true and profiles[kid].Tickets == 700, "el monopatín de premio va a sus vehículos")

---------------------------------------------------------------------
print("▶ Restaurante con un solo jugador de BARMAN (camarero NPC)")
local barman, barmanRoot = newPlayer(4, "Adulto", 0)
local board = collection:GetTagged("RestaurantBoard")[1]
promptOf(board, "Barman (barra)").Triggered:Fire(barman)
check(barman:GetAttribute("Job") == "Barman", "ficha de barman")
check(worldRoot.RestaurantLife:FindFirstChild("Npc_Camarero") ~= nil, "aparece un camarero NPC")
local barPart = collection:GetTagged("RestaurantBar")[1]
local passPart = collection:GetTagged("RestaurantPass")[1]
waitFor(function()
	return barman:GetAttribute("TaskTarget") ~= nil
end, 5, "la primera comanda del camarero NPC")
moveTo(barmanRoot, barPart.Position)
promptOf(barPart).Triggered:Fire(barman)
local barMsg = lastMessage(barman, "Bar")
check(barMsg ~= nil and #barMsg[3] >= 1, "la barra muestra las comandas pendientes")
local entry = barMsg[3][1]
local dishId
for _, d in Gameplay.Menu do
	if d.Name == entry.Dish then
		dishId = d.Id
	end
end
local recipe = Gameplay.dish(dishId).Ingredients
check(#entry.Options == Gameplay.Restaurant.IngredientOptions, "el barman ve 8 ingredientes para elegir")
local wrong = {}
for _, option in entry.Options do
	if not table.find(recipe, option) then
		table.insert(wrong, option)
		break
	end
end
remotes.Restaurant.OnServerEvent:Fire(barman, "Prepare", barMsg[2], entry.OrderId, entry.Index, wrong)
check(profiles[barman].Money == 0, "con ingredientes equivocados no cobra")
remotes.Restaurant.OnServerEvent:Fire(barman, "Prepare", barMsg[2], entry.OrderId, entry.Index, recipe)
check(profiles[barman].Money == Gameplay.Jobs.Barman.Pay, "con los ingredientes correctos prepara el plato y cobra")
-- Prepara todo lo que vaya llegando durante un rato
local deadline = os.clock() + 3
while os.clock() < deadline do
	local msg = lastMessage(barman, "BarUpdate") or lastMessage(barman, "Bar")
	if msg and #msg[3] > 0 then
		local e = msg[3][1]
		local id
		for _, d in Gameplay.Menu do
			if d.Name == e.Dish then
				id = d.Id
			end
		end
		clearInbox(barman)
		remotes.Restaurant.OnServerEvent:Fire(barman, "Prepare", barMsg[2], e.OrderId, e.Index, Gameplay.dish(id).Ingredients)
	end
	task.wait(0.05)
end
local served = false
for _, text in notifyTexts(barman) do
	served = served or string.find(text, "preparado", 1, true) ~= nil
end
check(profiles[barman].Money >= Gameplay.Jobs.Barman.Pay * 2, "sigue preparando platos (" .. profiles[barman].Money .. " $)")
remotes.QuitJob.OnServerEvent:Fire(barman)
check(barman:GetAttribute("Job") == nil and worldRoot.RestaurantLife:FindFirstChild("Npc_Camarero") == nil, "deja el trabajo y el NPC se va")
waitFor(function()
	for _, c in worldRoot.RestaurantLife:GetChildren() do
		if string.sub(c.Name, 1, 8) == "Cliente_" then
			return false
		end
	end
	return true
end, 5, "que se vayan los clientes al cerrar")
check(true, "al cerrar el restaurante los clientes se van")

---------------------------------------------------------------------
print("▶ Restaurante con un solo jugador de CAMARERO (barman NPC)")
local waiter, waiterRoot = newPlayer(5, "Adolescente", 0)
promptOf(board, "Camarero (sala)").Triggered:Fire(waiter)
check(waiter:GetAttribute("Job") == "Camarero" and worldRoot.RestaurantLife:FindFirstChild("Npc_Barman") ~= nil, "ficha de camarero y aparece un barman NPC")
local customer
waitFor(function()
	for _, c in worldRoot.RestaurantLife:GetChildren() do
		if string.sub(c.Name, 1, 8) == "Cliente_" then
			local prompt = promptOf(c)
			if prompt and prompt.Enabled then
				customer = c
				return true
			end
		end
	end
	return false
end, 5, "un cliente sentado con ✋")
local icon = customer:FindFirstChild("Head", true) and customer.Head:FindFirstChild("Icon")
check(icon ~= nil and icon.TextLabel.Text == "✋", "el cliente levanta la mano ✋")
promptOf(customer).Triggered:Fire(waiter)
local bubble = customer.Head:FindFirstChild("Bubble")
check(bubble ~= nil and string.find(bubble.TextLabel.Text, "Quiero", 1, true) ~= nil, "el cliente dice lo que quiere")
local said = bubble.TextLabel.Text
waitFor(function()
	return lastMessage(waiter, "TakeOrder") ~= nil
end, 8, "las opciones del camarero")
local take = lastMessage(waiter, "TakeOrder")
check(#take[3] == Gameplay.Restaurant.OrderOptions, "el camarero ve 4 opciones")
local correctIndex, wrongIndex
for i, option in take[3] do
	-- Frase exacta (una opción puede ser el final de otra: "zumo de naranja")
	if said == "¡Hola! Quiero " .. string.lower(string.sub(option, 1, 1)) .. string.sub(option, 2) .. ", por favor." then
		correctIndex = i
	else
		wrongIndex = i
	end
end
check(correctIndex ~= nil, "una de las opciones es justo lo que ha dicho el cliente")
clearInbox(waiter)
remotes.Restaurant.OnServerEvent:Fire(waiter, "OrderChoice", take[2], wrongIndex)
check(notified(waiter, "no ha pedido eso"), "si elige mal, el cliente lo repite")
waitFor(function()
	return lastMessage(waiter, "TakeOrder") ~= nil
end, 4, "las opciones otra vez")
take = lastMessage(waiter, "TakeOrder")
for i, option in take[3] do
	-- Frase exacta (una opción puede ser el final de otra: "zumo de naranja")
	if said == "¡Hola! Quiero " .. string.lower(string.sub(option, 1, 1)) .. string.sub(option, 2) .. ", por favor." then
		correctIndex = i
	end
end
remotes.Restaurant.OnServerEvent:Fire(waiter, "OrderChoice", take[2], correctIndex)
check(notified(waiter, "Comanda enviada"), "si acierta, la comanda va a la barra")
waitFor(function()
	return notified(waiter, "está listo en el pase")
end, 5, "que el barman NPC prepare el pedido")
check(true, "el barman NPC prepara el pedido y avisa")
moveTo(waiterRoot, passPart.Position)
promptOf(passPart).Triggered:Fire(waiter)
check(waiter.Character:FindFirstChild("CarriedPlate") ~= nil, "recoge el plato en el pase")
promptOf(customer).Triggered:Fire(waiter)
check(waiter.Character:FindFirstChild("CarriedPlate") == nil and profiles[waiter].Money >= Gameplay.Jobs.Camarero.Pay, "sirve la mesa y cobra (" .. profiles[waiter].Money .. " $)")
check(customer.Head.Icon.TextLabel.Text == "😋", "el cliente come")

---------------------------------------------------------------------
print("▶ Restaurante con DOS jugadores (camarero + barman)")
promptOf(board, "Barman (barra)").Triggered:Fire(barman)
check(worldRoot.RestaurantLife:FindFirstChild("Npc_Barman") == nil and worldRoot.RestaurantLife:FindFirstChild("Npc_Camarero") == nil, "con dos jugadores no hay NPC de servicio")
local other = newPlayer(6, "Adulto", 0)
promptOf(board, "Barman (barra)").Triggered:Fire(other)
check(other:GetAttribute("Job") == nil, "un tercero no puede quitarle el puesto")
-- El camarero toma nota a un cliente nuevo
local customer2
waitFor(function()
	for _, c in worldRoot.RestaurantLife:GetChildren() do
		if string.sub(c.Name, 1, 8) == "Cliente_" and c ~= customer then
			local prompt = promptOf(c)
			if prompt and prompt.Enabled and prompt.ActionText == "Tomar nota" then
				customer2 = c
				return true
			end
		end
	end
	return false
end, 5, "otro cliente")
clearInbox(waiter)
promptOf(customer2).Triggered:Fire(waiter)
said = customer2.Head.Bubble.TextLabel.Text
waitFor(function()
	return lastMessage(waiter, "TakeOrder") ~= nil
end, 8, "opciones")
take = lastMessage(waiter, "TakeOrder")
for i, option in take[3] do
	-- Frase exacta (una opción puede ser el final de otra: "zumo de naranja")
	if said == "¡Hola! Quiero " .. string.lower(string.sub(option, 1, 1)) .. string.sub(option, 2) .. ", por favor." then
		correctIndex = i
	end
end
clearInbox(barman)
remotes.Restaurant.OnServerEvent:Fire(waiter, "OrderChoice", take[2], correctIndex)
check(notified(barman, "Nueva comanda"), "al barman jugador le llega la comanda")
moveTo(barmanRoot, barPart.Position)
promptOf(barPart).Triggered:Fire(barman)
local moneyBefore = profiles[barman].Money
for _ = 1, 3 do
	local msg = lastMessage(barman, "BarUpdate") or lastMessage(barman, "Bar")
	for _, e in msg[3] do
		local id
		for _, d in Gameplay.Menu do
			if d.Name == e.Dish then
				id = d.Id
			end
		end
		remotes.Restaurant.OnServerEvent:Fire(barman, "Prepare", lastMessage(barman, "Bar")[2], e.OrderId, e.Index, Gameplay.dish(id).Ingredients)
	end
end
check(profiles[barman].Money > moneyBefore, "el barman jugador prepara los platos")
waitFor(function()
	return notified(waiter, "está listo en el pase")
end, 10, "plato listo")
local waiterMoney = profiles[waiter].Money
promptOf(passPart).Triggered:Fire(waiter)
local carried = waiter.Character:FindFirstChild("CarriedPlate")
check(carried ~= nil, "el camarero recoge el plato del barman")
promptOf(customer2).Triggered:Fire(waiter)
check(profiles[waiter].Money > waiterMoney, "y lo sirve a su mesa")

remotes.QuitJob.OnServerEvent:Fire(waiter)
check(worldRoot.RestaurantLife:FindFirstChild("Npc_Camarero") ~= nil, "si el camarero se va, entra un camarero NPC")

---------------------------------------------------------------------
print("▶ Mochila (inventario estilo Minecraft)")
local InventoryService = loadModule(S .. "InventoryService")
InventoryService.init()
local serde = require("@lune/serde")
local Items = loadModule(ROOT .. "/shared/Items")
local owner = newPlayer(20, "AdultoJoven", 100)
local bag = profiles[owner]
bag.Hunger, bag.Energy = 50, 50
bag.Vehicles = { Bici = true }
bag.Licenses = { B = true }
local function slotsOf(player)
	local raw = player:GetAttribute("Inventory")
	return if type(raw) == "string" then serde.decode("json", raw) else {}
end
local function slotOf(player, id)
	for i, entry in slotsOf(player) do
		if type(entry) == "table" and entry.i == id then
			return i, entry.n
		end
	end
	return nil
end
local function ask(...)
	task.wait(0.1) -- el servidor ignora peticiones demasiado seguidas
	remotes.Inventory.OnServerEvent:Fire(owner, ...)
end
InventoryService.refresh(owner)
check(#slotsOf(owner) == Items.Slots, "la mochila tiene 36 casillas")
check(slotOf(owner, "Vehiculo_Bici") ~= nil and slotOf(owner, "Carnet_B") ~= nil, "la bici y el carnet salen en la barra rápida")
check(InventoryService.add(owner, "Pan", 2), "compra dos panes")
local panSlot, panCount = slotOf(owner, "Pan")
check(panSlot ~= nil and panSlot <= Items.Hotbar and panCount == 2, "el pan va al primer hueco de la barra rápida, ×2")
ask("Move", panSlot, 15)
check(slotOf(owner, "Pan") == 15, "se puede mover el pan a otra casilla de la mochila")
table.clear(needsChanges)
ask("Use", 15)
check(bag.Items.Pan == 1 and #needsChanges == 1 and needsChanges[1][1] == owner and needsChanges[1][2] == Items.List.Pan.Hunger, "comer un pan quita hambre y gasta uno")
bag.Hunger = 100
ask("Use", 15)
check(bag.Items.Pan == 1, "sin hambre no se lo come (como en Minecraft)")
ask("Drop", slotOf(owner, "Vehiculo_Bici"))
check(slotOf(owner, "Vehiculo_Bici") ~= nil, "la bici no se puede tirar")
ask("Drop", 15)
check(slotOf(owner, "Pan") == nil and bag.Items.Pan == nil, "tirar el último pan deja la casilla vacía")
check(InventoryService.add(owner, "Fruta", Items.List.Fruta.Stack) and not InventoryService.canAdd(owner, "Fruta"), "cada casilla tiene su máximo")
ask("Move", 1, 99)
ask("Move", "1", 2)
check(slotOf(owner, "Vehiculo_Bici") ~= nil, "las peticiones raras se ignoran")
bag.Vehicles.Bici = nil
owner:SetAttribute("OwnedVehicles", "")
InventoryService.refresh(owner)
check(slotOf(owner, "Vehiculo_Bici") == nil, "lo que ya no tienes desaparece de la mochila")
check(pcall(serde.encode, "json", bag), "la mochila se puede guardar (JSON válido)")


---------------------------------------------------------------------
print("▶ Personaje: nivel, estadísticas, vida y estamina")
local ProgressionService = loadModule(S .. "ProgressionService")
local StoryEventsModule = loadModule(ROOT .. "/server/LifeStory/StoryEvents")
ProgressionService.init()
local hero, heroRoot, heroHumanoid = newPlayer(8, "Adolescente", 0)
for _, callback in loadedCallbacks do
	callback(hero, profiles[hero])
end
check(hero:GetAttribute("Level") == 1 and hero:GetAttribute("MaxStamina") == Gameplay.Progression.Stamina.Base, "empieza en nivel 1 con la estamina llena")
for _ = 1, 9 do
	StoryEventsModule.emit(hero, "JobTaskDone", {})
end
task.wait(0.1)
check(hero:GetAttribute("Level") == 2 and hero:GetAttribute("StatPoints") == Gameplay.Progression.PointsPerLevel, "trabajar da experiencia y sube de nivel (+3 puntos)")
remotes.Progression.OnServerEvent:Fire(hero, "Spend", "Salud")
check(hero:GetAttribute("Stat_Salud") == 1 and heroHumanoid.MaxHealth == 110, "un punto en Salud sube la vida máxima a 110")
remotes.Progression.OnServerEvent:Fire(hero, "Spend", "Resistencia")
check(hero:GetAttribute("MaxStamina") == Gameplay.Progression.Stamina.Base + Gameplay.Progression.Stamina.PerResistencia, "un punto en Resistencia da más estamina")
remotes.Progression.OnServerEvent:Fire(hero, "Spend", "Magia")
check(hero:GetAttribute("StatPoints") == 1, "no se puede gastar en una estadística que no existe")
heroRoot.AssemblyLinearVelocity = Vector3.new(16, 0, 0)
remotes.Progression.OnServerEvent:Fire(hero, "Sprint", true)
task.wait(0.4)
check(hero:GetAttribute("Sprinting") == true, "con Shift y moviéndose, corre")
waitFor(function()
	return hero:GetAttribute("Sprinting") == nil
end, 10, "que se acabe la estamina")
check((hero:GetAttribute("Stamina") or 99) <= 1, "corriendo se gasta la estamina hasta pararse")
remotes.Progression.OnServerEvent:Fire(hero, "Sprint", false)
task.wait(2)
check((hero:GetAttribute("Stamina") or 0) > 5, "descansando, la estamina se recupera")
hero:SetAttribute("Riding", "Bici")
remotes.Progression.OnServerEvent:Fire(hero, "Sprint", true)
task.wait(0.4)
check(hero:GetAttribute("Sprinting") == nil, "en bici no se esprinta")
hero:SetAttribute("Riding", nil)
profiles[hero].Story = { Completed = {} }
task.wait(3.3)
local before = hero:GetAttribute("Xp")
profiles[hero].Story.Completed.Mision1 = 1
profiles[hero].Story.Completed.Mision2 = 2
task.wait(3.3)
check(hero:GetAttribute("Xp") == before + 2 * Gameplay.Progression.QuestXp, "cada misión completada da experiencia")

---------------------------------------------------------------------
print("▶ Supermercado: comprar, pagar, alarma, cajero, charcutería y reponedor")
local Groceries = loadModule(ROOT .. "/shared/Groceries")
local superModel = fakeInstance("Model")
superModel.Name = "Supermercado"
superModel.Parent = worldRoot
superModel:SetAttribute("Store", "Super Prueba")
superModel:SetAttribute("Origin", CFrame.new(500, 0, 500))
superModel:SetAttribute("Door", Vector3.new(500, 0.4, 468))
superModel:SetAttribute("Inside", Vector3.new(500, 0.4, 478))
superModel:SetAttribute("FrontZ", -15)
superModel:SetAttribute("BackZ", 15)
superModel:SetAttribute("AisleXs", "0")
superModel:AddTag("Supermarket")
local function sp(name, position, tags, attrs, size)
	local p = part(name, CFrame.new(position), tags, attrs)
	p.Size = size or Vector3.new(4, 4, 4)
	p.Parent = superModel
	return p
end
sp("Bounds", Vector3.new(500, 8, 500), { "SuperBounds" }, nil, Vector3.new(60, 16, 60))
local milk = sp("Section_Leche", Vector3.new(495, 4, 500), { "SuperShelf" }, { Product = "Leche" })
for _ = 1, 4 do
	local g = part("Good", CFrame.new(495, 4, 500))
	g.Parent = milk
end
local cookies = sp("Section_Galletas", Vector3.new(490, 4, 500), { "SuperShelf" }, { Product = "Galletas" })
local belt1 = sp("Checkout", Vector3.new(505, 2, 480), { "SuperCheckout" }, { Lane = 1, CashierSpot = Vector3.new(508, 0.4, 480), QueueSpot = Vector3.new(502, 0.4, 486), PaySpot = Vector3.new(502, 0.4, 478) })
local belt2 = sp("Checkout", Vector3.new(514, 2, 480), { "SuperCheckout" }, { Lane = 2, CashierSpot = Vector3.new(517, 0.4, 480), QueueSpot = Vector3.new(511, 0.4, 486), PaySpot = Vector3.new(511, 0.4, 478) })
local kiosk = sp("SelfCheckout", Vector3.new(520, 2, 482), { "SuperSelfCheckout" })
local deli = sp("DeliCounter", Vector3.new(480, 2, 500), { "SuperDeli" }, { StaffSpot = Vector3.new(477, 0.4, 500), CustomerSpot = Vector3.new(484, 0.4, 500) })
local stockPoint = sp("StockPoint", Vector3.new(500, 2, 525), { "SuperStock" })
local superBoard = sp("StaffBoard", Vector3.new(495, 4, 478), { "SuperBoard" })

local SupermarketService = loadModule(S .. "SupermarketService")
SupermarketService.init()
local shopper, shopperRoot = newPlayer(30, "Adulto", 100)
moveTo(shopperRoot, Vector3.new(500, 0, 495))
local startStock = milk:GetAttribute("Stock")
check(startStock ~= nil and startStock > 0 and promptOf(milk, "Coger") ~= nil, "las estanterías tienen productos y cartel Coger")
promptOf(milk, "Coger").Triggered:Fire(shopper)
promptOf(milk, "Coger").Triggered:Fire(shopper)
local function cartOf(player)
	local raw = player:GetAttribute("Cart")
	return raw and require("@lune/serde").decode("json", raw)
end
local cart = cartOf(shopper)
check(cart ~= nil and cart.Items[1].Count == 2 and cart.Total == 2 * Groceries.byId.Leche.Price, "coge dos leches: van al carrito con su precio")
check(milk:GetAttribute("Stock") == startStock - 2, "la estantería tiene dos menos")
remotes.Supermarket.OnServerEvent:Fire(shopper, "Return", "Leche")
check(cartOf(shopper).Items[1].Count == 1 and milk:GetAttribute("Stock") == startStock - 1, "devuelve una leche a su sitio")
promptOf(kiosk, "Pagar").Triggered:Fire(shopper)
local receiptMsg = lastMessage(shopper, "Receipt")
check(receiptMsg ~= nil and receiptMsg[4] == Groceries.byId.Leche.Price, "el autocobro enseña el ticket con el total")
remotes.Supermarket.OnServerEvent:Fire(shopper, "Pay", receiptMsg[2])
check(profiles[shopper].Money == 100 - Groceries.byId.Leche.Price and InventoryService.count(shopper, "Leche") == 1, "paga y la leche va a la mochila")
check(shopper:GetAttribute("Cart") == nil, "el carrito se vacía al pagar")

-- Salir sin pagar: pita la alarma y los productos vuelven
local cookieStock = cookies:GetAttribute("Stock")
promptOf(cookies, "Coger").Triggered:Fire(shopper)
moveTo(shopperRoot, Vector3.new(600, 0, 600))
task.wait(0.8)
check(shopper:GetAttribute("Cart") == nil and cookies:GetAttribute("Stock") == cookieStock and notified(shopper, "sin pagar"), "si sales sin pagar pita la alarma y se queda todo en la tienda")

-- Cajero jugador
local cashier = newPlayer(31, "Adulto", 0)
promptOf(superBoard, "🧾 Cajero/a").Triggered:Fire(cashier)
check(cashier:GetAttribute("Job") == "Cajero", "un jugador se hace cajero desde el tablón")
moveTo(shopperRoot, Vector3.new(500, 0, 495))
promptOf(milk, "Coger").Triggered:Fire(shopper)
promptOf(cookies, "Coger").Triggered:Fire(shopper)
local cashierLane = if cashier:GetAttribute("TaskTarget") == belt2:GetAttribute("CashierSpot") then belt2 else belt1
promptOf(cashierLane, "Pagar aquí").Triggered:Fire(shopper)
local scanMsg = lastMessage(cashier, "Scan")
check(scanMsg ~= nil and #scanMsg[3] == 2, "el cajero recibe los dos productos del cliente para pasarlos")
check(lastMessage(shopper, "Receipt") == receiptMsg, "el cliente espera: no paga hasta que se pasen los productos")
remotes.Supermarket.OnServerEvent:Fire(cashier, "Scan", scanMsg[2], 1)
remotes.Supermarket.OnServerEvent:Fire(cashier, "Scan", scanMsg[2], 2)
local receipt2 = lastMessage(shopper, "Receipt")
check(receipt2 ~= receiptMsg and receipt2[2] == scanMsg[2], "pasados los productos, el cliente ve el ticket")
local cashierBefore = profiles[cashier].Money
remotes.Supermarket.OnServerEvent:Fire(shopper, "Pay", receipt2[2])
check(profiles[cashier].Money == cashierBefore + Groceries.Jobs.Cajero.PerCustomer + 2 * Groceries.Jobs.Cajero.PerItem, "el cajero cobra por cliente y por producto")
check(InventoryService.count(shopper, "Galletas") == 1, "el cliente se lleva las galletas")

-- Charcutería con charcutero jugador
local butcher = newPlayer(32, "Adulto", 0)
promptOf(superBoard, "🔪 Charcutero/a").Triggered:Fire(butcher)
check(butcher:GetAttribute("Job") == "Charcutero", "un jugador se hace charcutero")
moveTo(shopperRoot, Vector3.new(484, 0, 500))
remotes.Supermarket.OnServerEvent:Fire(shopper, "DeliOrder", "JamonSerrano", 200)
local work = lastMessage(butcher, "DeliWork")
check(work ~= nil and string.find(work[3], "200 g") ~= nil, "el charcutero recibe el pedido: 200 g de jamón")
remotes.Supermarket.OnServerEvent:Fire(butcher, "DeliServe", work[2], "Pavo", 200)
check(InventoryService.count(shopper, "JamonSerrano") == 0 and notified(butcher, "no es lo que"), "si se equivoca de producto, no vale")
local moneyBefore = profiles[shopper].Money
remotes.Supermarket.OnServerEvent:Fire(butcher, "DeliServe", work[2], "JamonSerrano", 200)
check(InventoryService.count(shopper, "JamonSerrano") == 2 and profiles[shopper].Money == moneyBefore - Groceries.deliPrice("JamonSerrano", 200), "bien cortado: el cliente paga y se lleva el jamón")
check(profiles[butcher].Money == Groceries.Jobs.Charcutero.PerOrder, "el charcutero cobra el pedido")

-- Reponedor
promptOf(superBoard, "📦 Reponedor/a").Triggered:Fire(cashier)
local startMsg = jobStarts[#jobStarts]
check(startMsg ~= nil and startMsg[2] == "Reponedor" and startMsg[3].Store ~= nil, "el reponedor empieza en SU supermercado")
local provider = jobProviders.Reponedor
local shift = { Context = startMsg[3] }
check(provider.Pickup(cashier, shift) == stockPoint, "coge las cajas en el almacén de esa tienda")
cookies:SetAttribute("Stock", 0)
local target = provider.Dropoff(cashier, shift)
check(target == cookies, "le manda a la sección más vacía")
provider.Done(cashier, shift)
check(cookies:GetAttribute("Stock") == Groceries.StockMax, "al dejar la caja, la sección se llena")

---------------------------------------------------------------------
print("▶ Cafetería: pedir en la caja y oficio de barista paso a paso")
local CafeMenu = loadModule(ROOT .. "/shared/CafeMenu")
local cafeModel = fakeInstance("Model")
cafeModel.Name = "Cafeteria"
cafeModel.Parent = worldRoot
cafeModel:SetAttribute("Outside", Vector3.new(700, 0.4, 670))
cafeModel:SetAttribute("Door", Vector3.new(700, 0.4, 680))
for i = 1, 4 do
	cafeModel:SetAttribute("Queue" .. i, Vector3.new(702, 0.4, 690 - i * 3))
end
cafeModel:SetAttribute("Wait", Vector3.new(690, 0.4, 690))
cafeModel:SetAttribute("Staff", Vector3.new(698, 0.4, 698))
local function cp(name, position, tags, attrs)
	local p = part(name, CFrame.new(position), tags, attrs)
	p.Size = Vector3.new(2, 2, 2)
	p.Parent = cafeModel
	return p
end
local register = cp("Register", Vector3.new(702, 4, 694), { "CafeRegister" })
local pickupSpot = cp("Pickup", Vector3.new(690, 4, 694), { "CafePickup" })
local cafeStations = {}
for id in CafeMenu.Stations do
	cafeStations[id] = cp("Station_" .. id, Vector3.new(700, 4, 700), { "CafeStation" }, { Station = id })
end
cp("Seat", Vector3.new(705, 2, 680), { "CafeSeat" })
cafeModel:AddTag("Cafe")
local CafeService = loadModule(S .. "CafeService")
CafeService.init()
check(jobProviders.Handler_Barista ~= nil, "el tablón de barista lo lleva la cafetería (la historia sigue usando el mismo tablón)")

local barista, baristaRoot = newPlayer(40, "Adolescente", 0)
moveTo(baristaRoot, Vector3.new(700, 0, 698))
CafeService.start(barista)
check(barista:GetAttribute("Job") == "Barista" and lastMessage(barista, "Start") ~= nil, "un jugador empieza de barista")

local coffeeFan, coffeeRoot = newPlayer(41, "Adulto", 20)
moveTo(coffeeRoot, Vector3.new(702, 0, 690))
promptOf(register, "Pedir").Triggered:Fire(coffeeFan)
local menuMsg = lastMessage(coffeeFan, "Menu")
check(menuMsg ~= nil and #menuMsg[2] == #CafeMenu.List and menuMsg[3] == (barista.DisplayName or barista.Name), "en la caja sale la carta y quién atiende")
remotes.Cafe.OnServerEvent:Fire(coffeeFan, "Order", { "Capuchino", "Croissant" })
local price = CafeMenu.byId.Capuchino.Price + CafeMenu.byId.Croissant.Price
check(profiles[coffeeFan].Money == 20 - price, "pide un capuchino y un croissant y paga")
local workMsg = lastMessage(barista, "Work")
local mine = workMsg and workMsg[2][#workMsg[2]]
check(mine ~= nil and mine.Name == (coffeeFan.DisplayName or coffeeFan.Name) and #mine.Tasks == 5, "el barista ve el pedido con sus 5 pasos")

-- Si había pedidos de clientes NPC antes, se hacen en orden: los terminamos primero
local function doSteps()
	for _ = 1, 30 do
		local msg = lastMessage(barista, "Work")
		local current = msg and msg[2][1]
		if not current then
			return nil
		end
		if current.Ready then
			return current
		end
		for _, t in current.Tasks do
			if not t.Done then
				for id, station in CafeMenu.Stations do
					if station.Name == t.Label then
						promptOf(cafeStations[id], station.Name).Triggered:Fire(barista)
					end
				end
				break
			end
		end
	end
	return nil
end
local ready = doSteps()
while ready and ready.Name ~= (coffeeFan.DisplayName or coffeeFan.Name) do
	promptOf(pickupSpot, "Entregar pedido").Triggered:Fire(barista)
	ready = doSteps()
end
check(ready ~= nil and ready.Name == (coffeeFan.DisplayName or coffeeFan.Name), "hace todos los pasos en orden y el pedido queda listo")
check(barista:GetAttribute("TaskTarget") == pickupSpot.Position, "la línea azul le lleva a la recogida")
promptOf(cafeStations.Grind, CafeMenu.Stations.Grind.Name).Triggered:Fire(barista)
check(notified(barista, "ya está listo"), "no deja hacer más pasos a un pedido ya listo")
local baristaBefore = profiles[barista].Money
promptOf(pickupSpot, "Entregar pedido").Triggered:Fire(barista)
check(InventoryService.count(coffeeFan, "Cafe_Capuchino") == 1 and InventoryService.count(coffeeFan, "Cafe_Croissant") == 1, "el cliente recibe el capuchino y el croissant en la mochila")
local J = CafeMenu.Job
check(profiles[barista].Money == baristaBefore + J.PerOrder + 5 * J.PerStep + J.TipFast, "el barista cobra por pedido, por paso y propina por ser rápido")

-- Paso equivocado
remotes.Cafe.OnServerEvent:Fire(coffeeFan, "Order", { "Espresso" })
local espressoWork = lastMessage(barista, "Work")
local first = espressoWork and espressoWork[2][1]
if first and first.Name == (coffeeFan.DisplayName or coffeeFan.Name) then
	promptOf(cafeStations.Brew, CafeMenu.Stations.Brew.Name).Triggered:Fire(barista)
	check(notified(barista, "Ahora no toca"), "si va al puesto equivocado, le avisa del paso que toca")
end
CafeService.quit(barista)
check(barista:GetAttribute("Job") == nil and lastMessage(barista, "Stop") ~= nil, "deja el trabajo de barista")

---------------------------------------------------------------------
print("▶ Correos: oficio de repartidor con ruta por las casas")
local postModel = fakeInstance("Model")
postModel.Name = "Correos"
postModel.Parent = worldRoot
local sortTable = part("PostSort", CFrame.new(900, 3, 900), { "PostSort" })
sortTable.Parent = postModel
local postVehicle = part("PostVehicle", CFrame.new(890, 2, 880), { "PostVehicle" })
postVehicle.Parent = postModel
postModel:AddTag("PostOffice")
for k = 1, 6 do
	local angle = k * math.pi / 3
	local pos = Vector3.new(900 + math.cos(angle) * (150 + k * 20), 3.5, 900 + math.sin(angle) * (150 + k * 20))
	part("Mailbox", CFrame.new(pos), { "Buzon" }, { Address = "Calle de Prueba, " .. k, DoorSpot = pos + Vector3.new(0, -3.5, 6) })
end
local PostService = loadModule(S .. "PostService")
PostService.init()
check(jobProviders.Handler_Repartidor ~= nil, "el tablón de Correos lleva al oficio de repartidor (el mismo tablón de la historia)")
local postie, postieRoot = newPlayer(42, "Adolescente", 0)
moveTo(postieRoot, Vector3.new(900, 0, 896))
local postEvents = 0
StoryEventsModule.connect(function(player, name, payload)
	if player == postie and name == "JobTaskDone" and payload and payload.JobId == "Repartidor" then
		postEvents += 1
	end
end)
PostService.start(postie)
local routeMsg = lastMessage(postie, "Route")
check(postie:GetAttribute("Job") == "Repartidor" and routeMsg ~= nil and routeMsg[2].Phase == "Load" and #routeMsg[2].Stops == Gameplay.Post.Parcels, "empieza con una ruta de 5 casas por cargar")
check(string.find(routeMsg[2].Stops[1].Address, "Calle de Prueba") ~= nil, "cada paquete va a la dirección de una casa")
promptOf(sortTable, "Cargar / cerrar la ruta").Triggered:Fire(postie)
check(lastMessage(postie, "Route")[2].Phase == "Deliver", "carga los paquetes en la mesa del escáner")
local function ownPrompt()
	for _, d in worldRoot:GetDescendants() do
		if d.ClassName == "ProximityPrompt" and d:GetAttribute("OwnerUserId") == postie.UserId and d.Parent then
			return d
		end
	end
	return nil
end
local firstPrompt = ownPrompt()
check(firstPrompt ~= nil and firstPrompt:GetAttribute("JobOnly") == "Repartidor", "en la primera casa hay un cartel solo para su repartidor")
local stranger = newPlayer(43, "Adulto", 0)
firstPrompt.Triggered:Fire(stranger)
check(lastMessage(postie, "Route")[2].Stops[1].Done == false, "otro jugador no puede entregar sus paquetes")
for _ = 1, Gameplay.Post.Parcels do
	local prompt = ownPrompt()
	if prompt then
		prompt.Triggered:Fire(postie)
	end
end
local finished = lastMessage(postie, "Route")[2]
check(finished.Phase == "Return" and postEvents == Gameplay.Post.Parcels, "entrega los 5 paquetes (cada uno cuenta para la historia)")
check(profiles[postie].Money >= Gameplay.Post.Parcels * Gameplay.Post.PerParcel, "cobra por cada paquete, más si la casa está lejos")
local beforeBonus = profiles[postie].Money
promptOf(sortTable, "Cargar / cerrar la ruta").Triggered:Fire(postie)
check(profiles[postie].Money == beforeBonus + Gameplay.Post.RouteBonus * 2 and lastMessage(postie, "Route")[2].Phase == "Load", "cierra la ruta con bonus por rapidez y le dan otra")
PostService.quit(postie)
check(postie:GetAttribute("Job") == nil and ownPrompt() == nil, "deja el trabajo y se quitan sus carteles")

---------------------------------------------------------------------
print("▶ Limpieza: oficio de basurero con papeleras llenas")
local depotModel = fakeInstance("Model")
depotModel.Name = "PuntoLimpio"
depotModel.Parent = worldRoot
local unload = part("GarbageUnload", CFrame.new(1200, 2, 1200), { "GarbageUnload" })
unload.Parent = depotModel
local truckSpot = part("GarbageTruckSpot", CFrame.new(1190, 2, 1210), { "GarbageTruck" })
truckSpot.Parent = depotModel
depotModel:AddTag("GarbageDepot")
for k = 1, 10 do
	local bin = part("Bin", CFrame.new(1200 + k * 30, 1.3, 1250), { "Papelera" })
	bin.Size = Vector3.new(2.6, 1.4, 1.4)
end
local looseBag = part("TrashBag", CFrame.new(1210, 1, 1210), { "Pickup_Basurero" })
local GarbageService = loadModule(S .. "GarbageService")
GarbageService.init()
check(jobProviders.Handler_Basurero ~= nil, "el tablón del Punto Limpio lleva al oficio de basurero")
local sweeper, sweeperRoot = newPlayer(44, "Adolescente", 0)
moveTo(sweeperRoot, Vector3.new(1200, 0, 1205))
GarbageService.start(sweeper)
local gRoute = lastMessage(sweeper, "Route")
check(sweeper:GetAttribute("Job") == "Basurero" and gRoute ~= nil and gRoute[2].Total == Gameplay.Garbage.Bins, "empieza con 8 papeleras llenas en la ruta")
local function ownBins()
	local list = {}
	for _, d in worldRoot:GetDescendants() do
		if d.ClassName == "ProximityPrompt" and d:GetAttribute("OwnerUserId") == sweeper.UserId and d.Parent then
			table.insert(list, d)
		end
	end
	return list
end
local bins = ownBins()
check(#bins == Gameplay.Garbage.Bins and bins[1].Parent:FindFirstChild("Overflow") ~= nil, "las papeleras de la ruta se ven rebosando y tienen su cartel")
promptOf(looseBag, "Recoger bolsa").Triggered:Fire(sweeper)
check(lastMessage(sweeper, "Route")[2].Bags == 1 and looseBag.Transparency == 1, "recoge una bolsa suelta de la calle")
for _, prompt in bins do
	prompt.Triggered:Fire(sweeper)
end
local gDone = lastMessage(sweeper, "Route")[2]
check(gDone.Phase == "Unload" and gDone.Left == 0 and gDone.Bags == Gameplay.Garbage.Bins + 1, "vacía las 8 papeleras y lleva 9 bolsas")
local gMoney = profiles[sweeper].Money
check(gMoney == Gameplay.Garbage.Bins * Gameplay.Garbage.PerBin + Gameplay.Garbage.PerBag, "cobra por papelera y por bolsa suelta")
promptOf(unload, "Descargar").Triggered:Fire(sweeper)
local gNew = lastMessage(sweeper, "Route")[2]
check(profiles[sweeper].Money == gMoney + Gameplay.Garbage.UnloadBonus * 2 and gNew.Phase == "Collect" and gNew.Bags == 0, "descarga en el Punto Limpio con bonus y le dan otra ruta")
GarbageService.quit(sweeper)
check(sweeper:GetAttribute("Job") == nil and #ownBins() == 0, "deja el trabajo y se quitan sus carteles")

---------------------------------------------------------------------
print("▶ Hospital: pacientes y oficio de médico/a con diagnóstico")
local Medical = loadModule(ROOT .. "/shared/Medical")
local clinicModel = fakeInstance("Model")
clinicModel.Name = "Edificio"
clinicModel.Parent = worldRoot
clinicModel:SetAttribute("Outside", Vector3.new(1500, 0.4, 1470))
clinicModel:SetAttribute("Door", Vector3.new(1500, 0.4, 1480))
clinicModel:SetAttribute("Reception", Vector3.new(1490, 0.4, 1485))
clinicModel:SetAttribute("Room1Door", Vector3.new(1480, 0.4, 1500))
local function mp(name, position, tags, attrs)
	local p = part(name, CFrame.new(position), tags, attrs)
	p.Size = Vector3.new(3, 2, 3)
	p.Parent = clinicModel
	return p
end
local receptionDesk = mp("ReceptionDesk", Vector3.new(1490, 2, 1488), { "ClinicReception" })
local desk1 = mp("Desk", Vector3.new(1478, 2, 1505), { "ClinicDesk" }, { RoomId = 1 })
local bed1 = mp("Bed", Vector3.new(1484, 2.5, 1506), { "ClinicBed" }, { RoomId = 1 })
local meds1 = mp("MedCabinet", Vector3.new(1481, 3.5, 1510), { "ClinicMeds" }, { RoomId = 1 })
mp("Seat", Vector3.new(1505, 1.6, 1487), { "ClinicSeat" })
clinicModel:AddTag("Clinic")
local MedicalService = loadModule(S .. "MedicalService")
MedicalService.init()
check(jobProviders.Handler_Medico ~= nil, "el tablón del hospital lleva al oficio de médico/a")
local teenDoc, teenDocRoot = newPlayer(45, "Adolescente", 0)
moveTo(teenDocRoot, Vector3.new(1490, 0, 1484))
MedicalService.start(teenDoc)
check(teenDoc:GetAttribute("Job") == nil and notified(teenDoc, "mayor de edad"), "un adolescente no puede ser médico")
local doctor, doctorRoot = newPlayer(46, "AdultoJoven", 0)
moveTo(doctorRoot, Vector3.new(1490, 0, 1484))
MedicalService.start(doctor)
check(doctor:GetAttribute("Job") == "Medico" and lastMessage(doctor, "Case")[2].Phase == "Call", "un adulto empieza la guardia en la consulta 1")
local sick, sickRoot = newPlayer(47, "Adulto", 50)
moveTo(sickRoot, Vector3.new(1490, 0, 1484))
promptOf(receptionDesk, "Pedir cita").Triggered:Fire(sick)
check(notified(sick, "Tienes cita"), "un jugador pide cita en admisión y espera")
-- Si antes llegaron pacientes NPC, se atienden en orden: los pasamos con diagnóstico
local function treatNext()
	promptOf(desk1, "Llamar al siguiente paciente").Triggered:Fire(doctor)
	local case = lastMessage(doctor, "Case")[2]
	if not case.Patient then
		return nil
	end
	moveTo(doctorRoot, Vector3.new(1484, 0, 1503))
	remotes.Medical.OnServerEvent:Fire(doctor, "Exam", "Temperatura")
	remotes.Medical.OnServerEvent:Fire(doctor, "Exam", "Palpar")
	case = lastMessage(doctor, "Case")[2]
	return case
end
local case = treatNext()
local guard = 0
while case and case.Patient ~= (sick.DisplayName or sick.Name) and guard < 10 do
	guard += 1
	remotes.Medical.OnServerEvent:Fire(doctor, "Diagnose", case.Options[1].Id)
	if lastMessage(doctor, "Case")[2].Phase ~= "Call" then
		-- acertó por casualidad: cualquier medicina equivocada no cura, se termina bien igualmente
		for _, a in Medical.Ailments do
			remotes.Medical.OnServerEvent:Fire(doctor, "Medicine", a.Medicine)
			promptOf(bed1, "Aplicar tratamiento").Triggered:Fire(doctor)
			if lastMessage(doctor, "Case")[2].Phase == "Call" then
				break
			end
		end
	end
	case = treatNext()
end
check(case ~= nil and case.Patient == (sick.DisplayName or sick.Name) and case.Says ~= nil, "llama al jugador enfermo, que le cuenta lo que le pasa")
check(case.Exams[1].Result ~= nil or case.Exams[5].Result ~= nil, "las pruebas dan resultados")
check(case.Options ~= nil and #case.Options == 4, "con dos pruebas salen cuatro diagnósticos posibles")
-- El diagnóstico correcto (lo sabemos por el resultado de las pruebas que coinciden)
local right = nil
for _, option in case.Options do
	local a = Medical.byId[option.Id]
	if a.Results.Temperatura == case.Exams[1].Result and a.Results.Palpar == case.Exams[5].Result then
		right = right or a
	end
end
remotes.Medical.OnServerEvent:Fire(doctor, "Exam", "Auscultar")
remotes.Medical.OnServerEvent:Fire(doctor, "Exam", "Garganta")
remotes.Medical.OnServerEvent:Fire(doctor, "Exam", "Tension")
case = lastMessage(doctor, "Case")[2]
for _, option in case.Options do
	local a = Medical.byId[option.Id]
	local ok = true
	for k, exam in case.Exams do
		if exam.Result and a.Results[exam.Id] ~= exam.Result then
			ok = false
		end
	end
	if ok then
		right = a
	end
end
remotes.Medical.OnServerEvent:Fire(doctor, "Diagnose", right.Id)
check(lastMessage(doctor, "Case")[2].Phase == "Treat", "acierta el diagnóstico con las pruebas")
promptOf(meds1, "Coger medicina").Triggered:Fire(doctor)
check(lastMessage(doctor, "Meds") ~= nil, "el botiquín enseña las medicinas")
local wrong = if right.Medicine == "Venda" then "Jarabe" else "Venda"
remotes.Medical.OnServerEvent:Fire(doctor, "Medicine", wrong)
promptOf(bed1, "Aplicar tratamiento").Triggered:Fire(doctor)
check(notified(doctor, "Eso no es para") and lastMessage(doctor, "Case")[2].Phase == "Treat", "con la medicina equivocada no deja tratar")
local docMoney = profiles[doctor].Money
remotes.Medical.OnServerEvent:Fire(doctor, "Medicine", right.Medicine)
promptOf(bed1, "Aplicar tratamiento").Triggered:Fire(doctor)
check(notified(sick, "Curado") and lastMessage(doctor, "Case")[2].Phase == "Call", "con la buena, el paciente se cura")
check(profiles[doctor].Money == docMoney + Medical.Job.PerPatient + Medical.Job.RightDiagnosis, "el médico cobra por paciente y por acertar")
MedicalService.quit(doctor)
check(doctor:GetAttribute("Job") == nil, "termina la guardia")
-- Sin médico jugador: consulta rápida con el médico NPC
local walkIn, walkInRoot = newPlayer(48, "Adulto", 20)
moveTo(walkInRoot, Vector3.new(1490, 0, 1484))
promptOf(receptionDesk, "Pedir cita").Triggered:Fire(walkIn)
check(profiles[walkIn].Money == 20 - Medical.QuickVisitPrice, "sin médico de guardia, la consulta rápida cuesta poco y te atiende el médico NPC")

---------------------------------------------------------------------
print("▶ Autobús urbano L1: billete, paradas y conductor")
services.RunService = services.RunService or { Heartbeat = signal() }
local ambient = fakeInstance("Folder")
local roadsFolder = fakeInstance("Folder")
roadsFolder.Name = "Roads"
roadsFolder.Parent = ambient
services.ReplicatedStorage.Ambient = ambient
local function road(a, b)
	local c = fakeInstance("Configuration")
	c:SetAttribute("A", a)
	c:SetAttribute("B", b)
	c:SetAttribute("Width", 24)
	c.Parent = roadsFolder
end
road(Vector3.new(0, 0, 2000), Vector3.new(400, 0, 2000))
road(Vector3.new(400, 0, 2000), Vector3.new(400, 0, 2400))
road(Vector3.new(400, 0, 2400), Vector3.new(0, 0, 2400))
road(Vector3.new(0, 0, 2400), Vector3.new(0, 0, 2000))
local centroStop = part("TravelPoint", CFrame.new(200, 2, 1985), { "TravelStop" }, { Town = "Valmar Centro" })
part("TravelPoint", CFrame.new(200, 2, 2415), { "TravelStop" }, { Town = "Los Pinos" })
local BusService = loadModule(S .. "BusService")
BusService.init()
task.wait(0.3)
local busesFolder = worldRoot:FindFirstChild("Buses")
check(busesFolder ~= nil and #busesFolder:GetChildren() == Gameplay.Bus.NpcBuses, "salen los autobuses automáticos de la línea L1")
local openBus = nil
for _ = 1, 600 do
	services.RunService.Heartbeat:Fire(0.1)
	for _, m in busesFolder:GetChildren() do
		if m:GetAttribute("DoorsOpen") then
			openBus = m
		end
	end
	if openBus then
		break
	end
end
check(openBus ~= nil and openBus:GetAttribute("CurrentStop") ~= nil, "un autobús llega a una parada y abre las puertas")
local rider, _, riderHumanoid = newPlayer(40, "Adulto", 10)
promptOf(openBus, "Subir").Triggered:Fire(rider)
check(riderHumanoid.SeatPart ~= nil and riderHumanoid.SeatPart.Name == "PassengerSeat" and profiles[rider].Money == 10 - Gameplay.Bus.Fare, "paga el billete y se sienta dentro")
riderHumanoid.Sit = false
check(riderHumanoid.SeatPart == nil, "saltando se baja del autobús")
local broke, _, brokeHumanoid = newPlayer(41, "Adulto", 0)
promptOf(openBus, "Subir").Triggered:Fire(broke)
check(brokeHumanoid.SeatPart == nil and notified(broke, "billete"), "sin dinero no se puede subir")
promptOf(centroStop, "🚌 Trabajar de conductor").Triggered:Fire(broke)
check(broke:GetAttribute("Job") == nil and notified(broke, "carnet"), "sin carnet no se puede ser conductor")
local driverMoney = profiles[adult].Money
promptOf(centroStop, "🚌 Trabajar de conductor").Triggered:Fire(adult)
check(adult:GetAttribute("Job") == "Conductor" and adult:GetAttribute("Riding") == "Autobus", "con carnet se hace conductor y se sube a su autobús")
local target = adult:GetAttribute("TaskTarget")
check(typeof(target) == "Vector3", "la línea azul le lleva a la siguiente parada")
local driverBus = nil
for _, d in worldRoot:GetDescendants() do
	if d.Name == "Autobus_" .. adult.Name then
		driverBus = d
	end
end
local chassis = driverBus and driverBus.PrimaryPart
chassis.CFrame = CFrame.new(target + Vector3.new(0, 1, 0))
chassis.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
for _ = 1, 25 do
	services.RunService.Heartbeat:Fire(0.1)
	task.wait(0.1)
end
check(profiles[adult].Money >= driverMoney + Gameplay.Bus.DriverPerStop and driverBus:GetAttribute("DoorsOpen") == true, "para en la parada: se abren las puertas y cobra")
remotes.QuitJob.OnServerEvent:Fire(adult)
check(adult:GetAttribute("Job") == nil and adult:GetAttribute("Riding") == nil, "deja el turno y se baja")

---------------------------------------------------------------------
print("▶ Policía: avisos por la ciudad (robo, multa, accidente, persona perdida)")
-- (las calles de la prueba del autobús sirven para los avisos)
local stationModel = fakeInstance("Model")
stationModel.Name = "Edificio"
stationModel.Parent = worldRoot
local policeDesk = part("FrontDesk", CFrame.new(200, 2, 2200), { "PoliceDesk" })
policeDesk.Parent = stationModel
local patrolSpot = part("PolicePatrol", CFrame.new(190, 2, 2190), { "PolicePatrol" })
patrolSpot.Parent = stationModel
stationModel:AddTag("PoliceStation")
local PoliceService = loadModule(S .. "PoliceService")
PoliceService.init()
check(jobProviders.Handler_Policia ~= nil, "el tablón de la comisaría lleva al oficio de policía")
local cadet, cadetRoot = newPlayer(49, "Adolescente", 0)
moveTo(cadetRoot, Vector3.new(200, 0, 2196))
PoliceService.start(cadet)
check(cadet:GetAttribute("Job") == nil and notified(cadet, "mayor de edad"), "un adolescente no puede ser policía")
local officer, officerRoot = newPlayer(50, "AdultoJoven", 0)
moveTo(officerRoot, Vector3.new(200, 0, 2196))
local policeEvents = 0
StoryEventsModule.connect(function(player, name, payload)
	if player == officer and name == "JobTaskDone" and payload and payload.JobId == "Policia" then
		policeEvents += 1
	end
end)
PoliceService.start(officer)
check(officer:GetAttribute("Job") == "Policia" and lastMessage(officer, "Incident") ~= nil, "empieza el servicio y llega el primer aviso")
local function officerPrompts()
	local list = {}
	for _, d in worldRoot:GetDescendants() do
		if d.ClassName == "ProximityPrompt" and d:GetAttribute("OwnerUserId") == officer.UserId and d.Parent then
			table.insert(list, d)
		end
	end
	return list
end
-- Resuelve varios avisos seguidos, sea del tipo que sea
local solvedKinds = {}
for round = 1, 6 do
	local before = policeEvents
	local msg = lastMessage(officer, "Incident")
	local title = msg and msg[2] and msg[2].Title or "?"
	for _ = 1, 3 do
		for _, prompt in officerPrompts() do
			if prompt.ActionText == "Poner conos" or prompt.ActionText == "Tomar datos" then
				prompt.Triggered:Fire(officer)
			end
		end
		for _, prompt in officerPrompts() do
			if prompt.ActionText ~= "Poner conos" and prompt.ActionText ~= "Tomar datos" then
				prompt.Triggered:Fire(officer)
			end
		end
		if policeEvents == before then
			promptOf(policeDesk, "Entregar informe").Triggered:Fire(officer)
		end
		if policeEvents > before then
			break
		end
	end
	if policeEvents > before then
		solvedKinds[title] = true
	end
	task.wait(5.2)
end
local solvedCount = 0
for _ in solvedKinds do
	solvedCount += 1
end
check(policeEvents >= 5, "resuelve los avisos seguidos (cada uno cuenta para la historia)")
check(solvedCount >= 2, "hay avisos de distintos tipos")
check(profiles[officer].Money >= policeEvents * 15, "cobra por cada aviso resuelto")
PoliceService.quit(officer)
check(officer:GetAttribute("Job") == nil and #officerPrompts() == 0, "termina el servicio y se quitan sus avisos")

---------------------------------------------------------------------
-- (en su propia función: la prueba ya usa casi todas las variables locales permitidas)
;(function()
print("▶ Bomberos: incendios, fuego que crece y gatos en apuros")
local fireStation = fakeInstance("Model")
fireStation.Name = "Bomberos"
fireStation.Parent = worldRoot
local truckBay = part("FireTruckSpot", CFrame.new(150, 2, 2150), { "FireTruckSpot" })
truckBay.Parent = fireStation
fireStation:AddTag("FireStation")
-- Una casa con su buzón, una papelera y una farola dentro del radio de los avisos
local houseModel = fakeInstance("Model")
houseModel.Name = "Casa"
houseModel.Parent = worldRoot
local houseBody = part("Body", CFrame.new(300, 5, 2300), nil)
houseBody.Size = Vector3.new(24, 10, 20)
houseBody.Parent = houseModel
local houseBox = part("Mailbox", CFrame.new(300, 3.5, 2280), { "Buzon" }, { Address = "Calle del Fuego, 7", DoorSpot = Vector3.new(300, 0, 2288) })
houseBox.Parent = houseModel
part("Bin", CFrame.new(260, 1.3, 2250), { "Papelera" })
local lampModel = fakeInstance("Model")
lampModel.Name = "StreetLamp"
lampModel.Parent = worldRoot
local lampBase = part("Base", CFrame.new(240, 0.5, 2260), nil)
lampBase.Size = Vector3.new(1.2, 1, 1.2)
lampBase.Parent = lampModel
local lampLens = part("Lens", CFrame.new(240, 13.9, 2256.6), { "StreetLamp" })
lampLens.Parent = lampModel
local FireService = loadModule(S .. "FireService")
FireService.init()
check(jobProviders.Handler_Bombero ~= nil, "el tablón del parque lleva al oficio de bombero")
local firefighter, firefighterRoot = newPlayer(51, "Adulto", 0)
moveTo(firefighterRoot, Vector3.new(150, 0, 2146))
local fireEvents = 0
StoryEventsModule.connect(function(player, name, payload)
	if player == firefighter and name == "JobTaskDone" and payload and payload.JobId == "Bombero" then
		fireEvents += 1
	end
end)
FireService.start(firefighter)
check(firefighter:GetAttribute("Job") == "Bombero" and lastMessage(firefighter, "Incident") ~= nil, "empieza la guardia y llega un aviso")
local function firePrompts()
	local list = {}
	for _, d in worldRoot:GetDescendants() do
		if d.ClassName == "ProximityPrompt" and d:GetAttribute("OwnerUserId") == firefighter.UserId and d.Parent then
			table.insert(list, d)
		end
	end
	return list
end
local fireKinds = {}
for _ = 1, 6 do
	local before = fireEvents
	local msg = lastMessage(firefighter, "Incident")
	local title = msg and msg[2] and msg[2].Title or "?"
	for _ = 1, 12 do
		local prompts = firePrompts()
		if #prompts == 0 or fireEvents > before then
			break
		end
		prompts[1].Triggered:Fire(firefighter)
	end
	if fireEvents > before then
		fireKinds[title] = true
	end
	task.wait(6.2)
end
local fireKindCount = 0
for _ in fireKinds do
	fireKindCount += 1
end
check(fireEvents >= 5, "apaga los fuegos y resuelve los avisos (cada uno cuenta para la historia)")
check(fireKindCount >= 2, "hay avisos de distintos tipos")
check(profiles[firefighter].Money >= fireEvents * 15, "cobra por cada aviso")
FireService.quit(firefighter)
check(firefighter:GetAttribute("Job") == nil and #firePrompts() == 0, "termina la guardia y se quitan sus avisos")
end)()
;(function()
print("▶ Cine: comprar entradas, taquillero/a y la sala")
local Cinema = loadModule(ROOT .. "/shared/Cinema")
local cinemaModel = fakeInstance("Model")
cinemaModel.Name = "Cine"
cinemaModel.Parent = worldRoot
cinemaModel:SetAttribute("Outside", Vector3.new(1800, 0.4, 1770))
cinemaModel:SetAttribute("Door", Vector3.new(1800, 0.4, 1780))
for i = 1, 4 do
	cinemaModel:SetAttribute("Queue" .. i, Vector3.new(1805, 0.4, 1786 - i * 3))
end
cinemaModel:SetAttribute("Staff", Vector3.new(1805, 0.4, 1792))
cinemaModel:SetAttribute("Lobby", Vector3.new(1780, 0.4, 1795))
cinemaModel:SetAttribute("Inside", Vector3.new(1780, 0.4, 1801))
local function cp(name, position, tags, attrs)
	local p = part(name, CFrame.new(position), tags, attrs)
	p.Size = Vector3.new(3, 3, 2)
	p.Parent = cinemaModel
	return p
end
local ticketWindow = cp("TicketWindow", Vector3.new(1805, 4, 1790), { "CinemaRegister" })
local salaDoor = cp("SalaDoor", Vector3.new(1780, 4.5, 1798), { "CinemaDoor" })
local popcorn = cp("Station_Palomitas", Vector3.new(1811, 4.5, 1793), { "CinemaStation" }, { Station = "Palomitas" })
cp("Station_Refresco", Vector3.new(1815, 4.5, 1793), { "CinemaStation" }, { Station = "Refresco" })
cp("Station_Nachos", Vector3.new(1819, 4.5, 1793), { "CinemaStation" }, { Station = "Nachos" })
cp("CinemaSeat", Vector3.new(1780, 1.7, 1810), { "CinemaSeat" })
cinemaModel:AddTag("Cinema")
local CinemaService = loadModule(S .. "CinemaService")
CinemaService.init()
check(jobProviders.Handler_Taquillero ~= nil, "el tablón del cine lleva al oficio de taquillero/a")
local clerk, clerkRoot = newPlayer(52, "Adolescente", 0)
moveTo(clerkRoot, Vector3.new(1805, 0, 1792))
CinemaService.start(clerk)
check(clerk:GetAttribute("Job") == "Taquillero", "un adolescente puede trabajar de taquillero")
local fan, fanRoot = newPlayer(53, "Nino", 40)
moveTo(fanRoot, Vector3.new(1805, 0, 1786))
promptOf(ticketWindow, "Comprar entradas").Triggered:Fire(fan)
local menuMsg = lastMessage(fan, "Menu")
check(menuMsg ~= nil and menuMsg[2].Title ~= nil and #menuMsg[2].Snacks == 3, "la taquilla enseña la próxima película y la barra")
remotes.Cinema.OnServerEvent:Fire(fan, "Buy", 2, { "Palomitas" })
check(profiles[fan].Money == 40 - 2 * Cinema.TicketPrice - Cinema.snackById.Palomitas.Price, "compra 2 entradas y palomitas")
-- Si antes había clientes NPC, se atienden en orden
local function serveFirst()
	local msg = lastMessage(clerk, "Work")
	local first = msg and msg[2][1]
	if not first then
		return nil
	end
	-- Película y número, a partir del texto del pedido
	local filmId, count = nil, tonumber(string.match(first.Text, "^(%d+)"))
	for _, f in Cinema.Films do
		if string.find(first.Text, f.Title, 1, true) then
			filmId = f.Id
		end
	end
	remotes.Cinema.OnServerEvent:Fire(clerk, "Print", filmId, count)
	for _, id in { "Palomitas", "Refresco", "Nachos" } do
		for _, d in cinemaModel:GetDescendants() do
			if d.ClassName == "ProximityPrompt" and d.Parent and d.Parent.Name == "Station_" .. id then
				d.Triggered:Fire(clerk)
			end
		end
	end
	promptOf(ticketWindow, "Entregar pedido").Triggered:Fire(clerk)
	return first
end
local first = lastMessage(clerk, "Work")[2][1]
remotes.Cinema.OnServerEvent:Fire(clerk, "Print", "NoExiste", 9)
check(notified(clerk, "Eso no es lo que ha pedido"), "si imprime otra película u otro número, no vale")
local served = serveFirst()
local guard = 0
while served and served.Name ~= (fan.DisplayName or fan.Name) and guard < 8 do
	guard += 1
	served = serveFirst()
end
check(InventoryService.count(fan, Cinema.TicketItem) == 2 and InventoryService.count(fan, "Palomitas") == 1, "el cliente recibe sus 2 entradas y las palomitas")
check(profiles[clerk].Money >= Cinema.Job.PerSale + 2 * Cinema.Job.PerTicket + Cinema.Job.PerSnack, "el taquillero cobra por cliente, entradas y barra")
-- Entrar a la sala (si no es el descanso)
local _, phase = Cinema.session(workspace and workspace.GetServerTimeNow and workspace:GetServerTimeNow() or os.clock())
promptOf(salaDoor, "Entrar a la sala").Triggered:Fire(fan)
if phase ~= "Break" then
	check(InventoryService.count(fan, Cinema.TicketItem) == 1, "al entrar a la sala se gasta una entrada")
else
	check(InventoryService.count(fan, Cinema.TicketItem) == 2, "en el descanso no deja entrar (y no gasta la entrada)")
end
local noTicket = newPlayer(54, "Adulto", 0)
promptOf(salaDoor, "Entrar a la sala").Triggered:Fire(noTicket)
check(notified(noTicket, "Necesitas una entrada") or notified(noTicket, "limpiando"), "sin entrada no se entra")
CinemaService.quit(clerk)
check(clerk:GetAttribute("Job") == nil, "cierra la taquilla")
end)()

;(function()
print("▶ Hotel: reservar habitación, recepcionista y descansar")
local Hotel = loadModule(ROOT .. "/shared/Hotel")
local hotelModel = fakeInstance("Model")
hotelModel.Name = "Hotel"
hotelModel.Parent = worldRoot
hotelModel:SetAttribute("HotelName", "MIRAMAR")
hotelModel:SetAttribute("Outside", Vector3.new(2000, 0.4, 1970))
hotelModel:SetAttribute("Door", Vector3.new(2000, 0.4, 1980))
for i = 1, 3 do
	hotelModel:SetAttribute("Queue" .. i, Vector3.new(1997, 0.4, 1990 - i * 3))
end
hotelModel:SetAttribute("Staff", Vector3.new(1997, 0.4, 1996))
hotelModel:SetAttribute("Elevator", Vector3.new(2009, 0.4, 1993))
local desk = part("Desk", CFrame.new(1997, 2.8, 1993), { "HotelDesk" })
desk.Size = Vector3.new(12, 3.6, 2.4)
desk.Parent = hotelModel
local elevator = part("HotelElevator", CFrame.new(2010, 4, 1993), { "HotelElevator" })
elevator.Size = Vector3.new(2, 6, 9)
elevator.Parent = hotelModel
hotelModel:AddTag("HotelLobby")
local HotelService = loadModule(S .. "HotelService")
HotelService.init()
check(jobProviders.Handler_Recepcionista ~= nil, "el tablón del hotel lleva al oficio de recepcionista")
local clerk, clerkRoot = newPlayer(62, "AdultoJoven", 0)
moveTo(clerkRoot, Vector3.new(1997, 0, 1996))
HotelService.start(clerk)
check(clerk:GetAttribute("Job") == "Recepcionista", "empieza el turno en recepción")
local guest, guestRoot = newPlayer(63, "Adulto", 100)
moveTo(guestRoot, Vector3.new(1997, 0, 1988))
promptOf(desk, "Reservar habitación").Triggered:Fire(guest)
local menuMsg = lastMessage(guest, "Menu")
check(menuMsg ~= nil and #menuMsg[2].Types == 3, "recepción enseña los tres tipos de habitación")
local suite = Hotel.typeById.Suite
remotes.Hotel.OnServerEvent:Fire(guest, "Book", "Suite")
check(profiles[guest].Money == 100 - suite.Price, "paga la suite")
-- Atiende la cola hasta llegar a nuestro huésped
local function work()
	return lastMessage(clerk, "Work")
end
local wrongTried, freeTried = false, false
local guard = 0
while InventoryService.count(guest, Hotel.KeyItem) == 0 and guard < 10 do
	guard += 1
	local msg = work()
	local first = msg and msg[2][1]
	if not first then
		break
	end
	local rooms = msg[3]
	local pick = nil
	if first.Kind == "In" then
		if not wrongTried then
			-- Una habitación de otro tipo no vale
			for _, r in rooms do
				if r.Type ~= first.Type and not r.Guest then
					remotes.Hotel.OnServerEvent:Fire(clerk, "Assign", r.Room)
					break
				end
			end
			check(notified(clerk, "Esa no es"), "si das otro tipo de habitación, no vale")
			wrongTried = true
		end
		for _, r in rooms do
			if r.Type == first.Type and not r.Guest then
				pick = r.Room
				break
			end
		end
	else
		if not freeTried then
			for _, r in rooms do
				if not r.Guest then
					remotes.Hotel.OnServerEvent:Fire(clerk, "Assign", r.Room)
					break
				end
			end
			check(notified(clerk, "no es la habitación"), "en una salida hay que dar SU habitación")
			freeTried = true
		end
		for _, r in rooms do
			if r.Guest == first.Name then
				pick = r.Room
			end
		end
	end
	remotes.Hotel.OnServerEvent:Fire(clerk, "Assign", pick)
end
check(InventoryService.count(guest, Hotel.KeyItem) == 1, "el huésped recibe la llave")
local roomsNow = work()[3]
local taken = false
for _, r in roomsNow do
	if r.Guest == (guest.DisplayName or guest.Name) then
		taken = Hotel.typeOfRoom[r.Room] == "Suite"
	end
end
check(taken, "su suite sale ocupada con su nombre en el panel")
check(profiles[clerk].Money >= Hotel.Job.PerCheckIn, "el recepcionista cobra por la entrada")
local noKey = newPlayer(64, "Adulto", 0)
promptOf(elevator, "Subir a tu habitación").Triggered:Fire(noKey)
check(notified(noKey, "Necesitas la llave"), "sin llave no se sube")
promptOf(elevator, "Subir a tu habitación").Triggered:Fire(guest)
check(InventoryService.count(guest, Hotel.KeyItem) == 0, "al subir se usa la llave")
HotelService.quit(clerk)
check(clerk:GetAttribute("Job") == nil, "termina el turno")
end)()

end, debug.traceback)
if not ok then
	print("❌ Error en la prueba: " .. tostring(err))
	process.exit(1)
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
process.exit(0)
