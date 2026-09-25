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

local EVENTS = { Triggered = true, Died = true, Destroying = true, Completed = true, CharacterRemoving = true, CharacterAdded = true, Activated = true, Event = true }
local PARTS = { Part = true, Seat = true, WedgePart = true, CornerWedgePart = true }

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
function Fake.GetPropertyChangedSignal()
	return signal()
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
		end
	elseif key == "Position" then
		props.CFrame = CFrame.new(value) * (props.CFrame and props.CFrame.Rotation or CFrame.new())
	else
		props[key] = value
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
}

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
local S = ROOT .. "/server/Services/"
mocks[S .. "DataService"] = {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function() end,
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
mocks[S .. "NeedsService"] = { canWork = function() return true end, change = function() end }
mocks[S .. "MonetizationService"] = { payMultiplier = function() return 1 end }
mocks[S .. "JobService"] = { quit = function() end }
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
task.delay(90, function()
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
promptOf(station, "Coger bicicleta").Triggered:Fire(kid)
check(kid:GetAttribute("Riding") == nil, "un niño no puede coger la bici pública")
promptOf(station, "Coger bicicleta").Triggered:Fire(teen)
check(teen:GetAttribute("Riding") == "Bici" and teen:GetAttribute("VehicleSpeed") == Gameplay.Vehicles.Bici.Speed, "un adolescente coge la bici pública y va más rápido")
check(teenHumanoid.HipHeight > 2, "el personaje sube al sillín")
remotes.Vehicle.OnServerEvent:Fire(teen, "Dismount")
check(teen:GetAttribute("Riding") == nil and teenHumanoid.HipHeight == 2, "se baja y vuelve a su altura")
remotes.Vehicle.OnServerEvent:Fire(teen, "Buy", "Coche")
check(profiles[teen].Money == 1000, "un adolescente no puede comprarse un coche")
remotes.Vehicle.OnServerEvent:Fire(teen, "Buy", "Monopatin")
check(profiles[teen].Money == 850 and teen:GetAttribute("OwnedVehicles") == "Monopatin", "compra su monopatín")
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Monopatin")
check(teen:GetAttribute("Riding") == "Monopatin", "saca su monopatín en cualquier sitio")
local rides = worldRoot:FindFirstChild("Rides")
check(rides ~= nil and #rides:GetChildren() == 1, "hay un solo vehículo soldado al jugador")
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Bici")
check(teen:GetAttribute("Riding") == "Monopatin", "no puede sacar una bici que no tiene")
teenHumanoid.Died:Fire()
check(teen:GetAttribute("Riding") == nil and #rides:GetChildren() == 0, "si muere, el vehículo desaparece")

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
local carModel = worldRoot.Rides:GetChildren()[1]
local beam = carModel and carModel:FindFirstChild("Headlight") and carModel.Headlight:FindFirstChildOfClass("SpotLight")
check(beam ~= nil and beam.Enabled == true, "de noche el coche lleva los faros encendidos")
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
end, 3, "las opciones del camarero")
local take = lastMessage(waiter, "TakeOrder")
check(#take[3] == Gameplay.Restaurant.OrderOptions, "el camarero ve 4 opciones")
local correctIndex, wrongIndex
for i, option in take[3] do
	local lowered = string.lower(string.sub(option, 1, 1)) .. string.sub(option, 2)
	if string.find(said, lowered .. ", por favor", 1, true) then
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
	local lowered = string.lower(string.sub(option, 1, 1)) .. string.sub(option, 2)
	if string.find(said, lowered .. ", por favor", 1, true) then
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
end, 3, "opciones")
take = lastMessage(waiter, "TakeOrder")
for i, option in take[3] do
	local lowered = string.lower(string.sub(option, 1, 1)) .. string.sub(option, 2)
	if string.find(said, lowered .. ", por favor", 1, true) then
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
end, 3, "plato listo")
local waiterMoney = profiles[waiter].Money
promptOf(passPart).Triggered:Fire(waiter)
local carried = waiter.Character:FindFirstChild("CarriedPlate")
check(carried ~= nil, "el camarero recoge el plato del barman")
promptOf(customer2).Triggered:Fire(waiter)
check(profiles[waiter].Money > waiterMoney, "y lo sirve a su mesa")

remotes.QuitJob.OnServerEvent:Fire(waiter)
check(worldRoot.RestaurantLife:FindFirstChild("Npc_Camarero") ~= nil, "si el camarero se va, entra un camarero NPC")

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
