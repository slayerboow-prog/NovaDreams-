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
function Fake.GetPivot(self)
	local props = self.__props
	return props.WorldPivot or (props.PrimaryPart and props.PrimaryPart.CFrame) or props.CFrame or CFrame.new()
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
-- Contorno de un modelo (lo que ocupan sus piezas, sin girar): InteriorService busca los edificios
function Fake.GetBoundingBox(self)
	local lo, hi = nil, nil
	for _, d in self:GetDescendants() do
		if PARTS[d.__props.ClassName] then
			local p, h = d.__props.CFrame.Position, d.__props.Size / 2
			lo = if lo then Vector3.new(math.min(lo.X, p.X - h.X), math.min(lo.Y, p.Y - h.Y), math.min(lo.Z, p.Z - h.Z)) else p - h
			hi = if hi then Vector3.new(math.max(hi.X, p.X + h.X), math.max(hi.Y, p.Y + h.Y), math.max(hi.Z, p.Z + h.Z)) else p + h
		end
	end
	if not lo or not hi then
		error("modelo vacío")
	end
	return CFrame.new((lo + hi) / 2), hi - lo
end
function Fake.SetNetworkOwner() end
function Fake.RemoveTag(self, tag)
	self.__tags[tag] = nil
end
-- Tamaño del personaje (Model:ScaleTo / GetScale)
function Fake.GetScale(self)
	return rawget(self, "__props").Scale or 1
end
function Fake.ScaleTo(self, scale)
	rawget(self, "__props").Scale = scale
end

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
	Trade = remote(),
	Fishing = remote(),
	Metro = remote(),
	Diving = remote(),
	SeaEvent = remote(),
	Social = remote(),
	Weapons = remote(),
	Wanted = remote(),
	Combat = remote(),
	Farm = remote(),
	Business = remote(),
	Interior = remote(),
	Interact = remote(),
	Gym = remote(),
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
function players:GetPlayerByUserId(id)
	for _, p in playersList do
		if p.UserId == id then
			return p
		end
	end
	return nil
end
for _, r in remotes do
	if type(r) == "table" and r.OnServerEvent then
		function r:FireAllClients(...)
			for _, p in playersList do
				table.insert(p.Inbox, table.pack(...))
			end
		end
	end
end
function players:CreateHumanoidModelFromDescription()
	error("sin avatares en la prueba")
end
function players:GetNameFromUserIdAsync(id)
	return "Jugador" .. id
end

local guid = 0
policyBlocked = {}
chatBlocked = {}
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
	-- Normas de Roblox por país: los UserId de esta lista no pueden intercambiar objetos de pago
	PolicyService = {
		GetPolicyInfoForPlayerAsync = function(_, player)
			return { IsPaidItemTradingAllowed = not (policyBlocked :: any)[player.UserId] }
		end,
	},
	-- Chat de Roblox: los UserId de chatBlocked no pueden chatear en privado
	TextChatService = (function()
		local service = fakeInstance("TextChatService")
		service.CanUsersDirectChatAsync = function(_, _, ids)
			local allowed = {}
			for _, id in ids do
				if not (chatBlocked :: any)[id] then
					table.insert(allowed, id)
				end
			end
			return allowed
		end
		return service
	end)(),
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
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		ColorSequence = roblox.ColorSequence,
		RaycastParams = { new = function() return {} end },
		OverlapParams = { new = function() return {} end },
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
	save = function()
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
check(profiles[teen].Money == 850 and string.find(tostring(teen:GetAttribute("OwnedVehicles")), "Monopatin", 1, true) ~= nil, "compra su monopatín")
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Monopatin")
check(teen:GetAttribute("Riding") == "Monopatin", "saca su monopatín en cualquier sitio")
local rides = worldRoot:FindFirstChild("Rides")
check(rides ~= nil and #rides:GetChildren() == 1, "hay un solo vehículo con el jugador")
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Coche")
check(teen:GetAttribute("Riding") == "Monopatin", "no puede sacar un coche que no tiene")
check(string.find("," .. tostring(teen:GetAttribute("OwnedVehicles")) .. ",", ",Bici,", 1, true) ~= nil and string.find("," .. tostring(teen:GetAttribute("OwnedVehicles")) .. ",", ",Patinete,", 1, true) ~= nil, "la bici y el patinete son suyos desde el principio")
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
print("▶ Pasajeros")
do
	local Rides = loadModule(ROOT .. "/server/World/Kit/Rides")
	check(#Rides.passengerSeats("Moto") == 1 and #Rides.passengerSeats("Bici") == 0 and #Rides.passengerSeats("Patinete") == 0 and #Rides.passengerSeats("Monopatin") == 0, "la moto lleva asiento de atrás; bici, patinete y monopatín no")
	check(#Rides.passengerSeats("Patrulla") == 3 and #Rides.passengerSeats("Bomberos") == 3 and #Rides.passengerSeats("Camion") == 1, "coche patrulla y camiones llevan asientos de pasajero")
	local car = worldRoot.Rides:FindFirstChild("Coche")
	local seats = {}
	for _, c in car:GetChildren() do
		if c.ClassName == "Seat" and c.Name == "RideSeat" then
			table.insert(seats, c)
		end
	end
	check(#seats == 3 and promptOf(car, "Subir de copiloto") ~= nil and promptOf(car, "Subir detrás") ~= nil, "el coche tiene copiloto y dos asientos detrás, cada uno con su cartel")
	check(car.PrimaryPart.RootPriority == 127, "la base del coche manda en el conjunto (nadie tiembla)")
	local friend, friendRoot, friendHumanoid = newPlayer(21, "AdultoJoven", 500)
	moveTo(friendRoot, car.PrimaryPart.Position + Vector3.new(4, 0, 0))
	promptOf(car, "Conducir").Triggered:Fire(friend)
	check(friend:GetAttribute("Riding") == nil and notified(friend, "de otra persona"), "no puede conducir el coche de otro")
	promptOf(car, "Subir de copiloto").Triggered:Fire(friend)
	check(friend:GetAttribute("Passenger") == "Coche" and friendHumanoid.SeatPart ~= nil and friendHumanoid.SeatPart.Name == "RideSeat", "se sube de copiloto al coche aparcado de su amigo")
	check(promptOf(car, "Subir de copiloto").Enabled == false, "el asiento ocupado ya no ofrece subirse")
	local kidRider, _, kidHumanoid = newPlayer(22, "Nino", 0)
	promptOf(car, "Subir de copiloto").Triggered:Fire(kidRider)
	check(kidRider:GetAttribute("Passenger") == nil, "no se puede sentar en un asiento ocupado")
	local back
	for _, seat in seats do
		if seat:GetAttribute("Label") == "Subir detrás" then
			back = seat
			break
		end
	end
	back.SeatPrompt.Triggered:Fire(kidRider)
	check(kidRider:GetAttribute("Passenger") == "Coche" and kidHumanoid.SeatPart == back, "un niño va detrás")
	promptOf(car, "Conducir").Triggered:Fire(adult)
	check(adult:GetAttribute("Riding") == "Coche" and car:GetAttribute("Driver") == adult.UserId, "el dueño conduce con sus amigos dentro")
	check(friend:GetAttribute("Passenger") == "Coche" and friendHumanoid.SeatPart ~= nil and not car.PrimaryPart.Anchored, "los pasajeros siguen sentados con el coche en marcha")
	remotes.Vehicle.OnServerEvent:Fire(adult, "Dismount")
	check(adult:GetAttribute("Riding") == nil and friend:GetAttribute("Passenger") == "Coche" and car.PrimaryPart.Anchored, "si el conductor se baja, los pasajeros siguen en el coche aparcado")
	-- Con suelo de verdad para ver dónde queda
	local floor = part("Street", CFrame.new(0, -0.5, 0))
	local oldRaycast = Fake.Raycast
	Fake.Raycast = function(_, origin)
		return { Position = Vector3.new(origin.X, 0, origin.Z), Instance = floor, Normal = Vector3.new(0, 1, 0), Material = Enum.Material.Concrete }
	end
	remotes.Vehicle.OnServerEvent:Fire(friend, "Dismount")
	local rel = car.PrimaryPart.CFrame:PointToObjectSpace(friendRoot.Position)
	check(friend:GetAttribute("Passenger") == nil and friendHumanoid.SeatPart == nil, "se baja con «Bajarse»")
	check(rel.X > 3.5 and rel.X < 7.5 and math.abs(rel.Z) < 2 and friendRoot.Position.Y > 1, "se baja por su lado, de pie junto al coche (no dentro)")
	check(promptOf(car, "Subir de copiloto").Enabled == true, "el asiento queda libre otra vez")
	kidHumanoid.Sit = false
	rel = car.PrimaryPart.CFrame:PointToObjectSpace(kidHumanoid.Parent.HumanoidRootPart.Position)
	check(kidRider:GetAttribute("Passenger") == nil and rel.X < -3.5 and rel.Z > 1, "saltar le baja por la puerta de atrás de su lado")
	-- Vehículo de trabajo o de alquiler: al retirarlo, los pasajeros se bajan antes
	VehicleService.mount(adult, "Coche", { Rented = true })
	local rented
	for _, m in worldRoot.Rides:GetChildren() do
		if m:GetAttribute("Driver") == adult.UserId then
			rented = m
		end
	end
	promptOf(rented, "Subir de copiloto").Triggered:Fire(friend)
	check(friend:GetAttribute("Passenger") == "Coche", "se sube de copiloto a un vehículo de trabajo")
	remotes.Vehicle.OnServerEvent:Fire(adult, "Dismount")
	check(friend:GetAttribute("Passenger") == nil and friendHumanoid.SeatPart == nil and friendRoot.Position.Y > 1, "al retirarlo, el pasajero se baja a su lado")
	Fake.Raycast = oldRaycast
	floor:Destroy()
end

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
local why = lastMessage(hero, "Info")
check(why ~= nil and tostring(why[2]):find("Bájate") ~= nil, "y te dice por qué no corre")
hero:SetAttribute("Riding", nil)
remotes.Progression.OnServerEvent:Fire(hero, "Sprint", false)
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
local sardineShelf = sp("Section_Sardinas", Vector3.new(482, 4, 510), { "SuperShelf" }, { Product = "Sardinas" })
sp("FishCounter", Vector3.new(482, 2, 512), { "SuperFish" })

local SupermarketService = loadModule(S .. "SupermarketService")
SupermarketService.init()
local shopper, shopperRoot = newPlayer(30, "Adulto", 100)
moveTo(shopperRoot, Vector3.new(500, 0, 495))
local startStock = milk:GetAttribute("Stock")
check(startStock ~= nil and startStock > 0 and promptOf(milk, "Coger") ~= nil, "las estanterías tienen productos y cartel Coger")
check(sardineShelf:GetAttribute("Stock") == 0, "el pescado empieza vacío: lo traen los pescadores")
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

;(function()
print("▶ Intercambio entre jugadores y mercadillo")
local Trade = loadModule(ROOT .. "/shared/Trade")
local TradeService = loadModule(S .. "TradeService")
TradeService.init()
local ana, anaRoot = newPlayer(71, "Adulto", 500)
local ben, benRoot = newPlayer(72, "Adolescente", 100)
profiles[ana].Items = { Pan = 5 }
profiles[ben].Items = { Fruta = 3 }
InventoryService.refresh(ana)
InventoryService.refresh(ben)
moveTo(anaRoot, Vector3.new(3000, 0, 3000))
moveTo(benRoot, Vector3.new(3100, 0, 3000))
local T = remotes.Trade.OnServerEvent
T:Fire(ana, "Request", 72)
check(notified(ana, "Acércate"), "hay que estar cerca para intercambiar")
moveTo(benRoot, Vector3.new(3004, 0, 3000))
T:Fire(ana, "Request", 72)
local invite = lastMessage(ben, "Invite")
check(invite ~= nil and invite[2].UserId == 71, "al otro le llega la invitación")
T:Fire(ben, "Answer", 71, true)
check(lastMessage(ana, "Session") ~= nil and lastMessage(ben, "Session") ~= nil, "se abre la ventana a los dos")
T:Fire(ana, "Offer", { Pan = 99 }, 0)
check(notified(ana, "No tienes tantos"), "no se puede ofrecer más de lo que tienes")
T:Fire(ana, "Offer", { LlaveHotel = 1 }, 0)
check(notified(ana, "no se puede intercambiar"), "hay cosas que no se intercambian")
T:Fire(ana, "Offer", { Pan = 2 }, 50)
T:Fire(ben, "Offer", { Fruta = 1 }, 0)
local seen = lastMessage(ben, "Session")[2]
check(#seen.Them.Items == 1 and seen.Them.Items[1].Id == "Pan" and seen.Them.Money == 50, "cada uno ve lo que le da el otro")
T:Fire(ana, "Accept", true)
T:Fire(ben, "Offer", { Fruta = 2 }, 0)
check(lastMessage(ana, "Session")[2].Me.Accepted == false, "si el otro cambia su oferta, se quita tu Aceptar")
T:Fire(ana, "Accept", true)
T:Fire(ben, "Accept", true)
check(lastMessage(ben, "Session")[2].Counting == true, "los dos aceptan: empieza la cuenta atrás")
check(InventoryService.count(ana, "Fruta") == 0, "durante la cuenta atrás aún no se ha cambiado nada")
task.wait(Trade.ConfirmSeconds + 0.4)
check(InventoryService.count(ana, "Pan") == 3 and InventoryService.count(ana, "Fruta") == 2 and profiles[ana].Money == 450, "Ana da 2 panes y 50 y recibe 2 frutas")
check(InventoryService.count(ben, "Pan") == 2 and InventoryService.count(ben, "Fruta") == 1 and profiles[ben].Money == 150, "Ben recibe 2 panes y 50 y da 2 frutas")
check(TradeService._sessionOf[ana] == nil and lastMessage(ana, "Closed") ~= nil, "el intercambio se cierra al terminar")
-- Si en tu país no está permitido (norma de Roblox)
local lia, liaRoot = newPlayer(73, "Adulto", 100)
policyBlocked[73] = true
moveTo(liaRoot, Vector3.new(3002, 0, 3002))
T:Fire(lia, "Request", 71)
check(notified(lia, "En tu país"), "si Roblox no lo permite en tu país, no se puede intercambiar")
T:Fire(lia, "List", "Pan", 1, 10)
check(#(lastMessage(lia, "Market") or { nil, {} })[2] == 0, "ni poner cosas en el mercadillo")
local baby = newPlayer(74, "Bebe", 0)
T:Fire(baby, "List", "Pan", 1, 10)
check(notified(baby, "bebés"), "los bebés no intercambian")
-- Mercadillo
T:Fire(ana, "List", "Pan", 1, 20)
local market = lastMessage(ben, "Market")
check(market ~= nil and #market[2] == 1 and market[2][1].Price == 20, "Ana pone un pan a la venta y todos lo ven")
T:Fire(ana, "List", "Pan", 3, 20)
check(notified(ana, "No tienes tantos"), "no se puede vender lo que ya está a la venta")
T:Fire(ben, "Buy", market[2][1].Id)
check(profiles[ben].Money == 130 and InventoryService.count(ben, "Pan") == 3, "Ben compra el pan")
check(profiles[ana].Money == 450 + Trade.sellerGets(20) and InventoryService.count(ana, "Pan") == 2, "Ana cobra (menos el 5 % del mercadillo)")
check(#lastMessage(ana, "Market")[2] == 0, "el anuncio se quita al venderse")
T:Fire(ana, "List", "Pan", 1, 20)
players.PlayerRemoving:Fire(ana)
check(#lastMessage(ben, "Market")[2] == 0, "si el vendedor se va, sus anuncios se quitan")
end)()

;(function()
print("▶ Menú del jugador: grupo y chat privado")
check(loadModule(ROOT .. "/shared/Trade").tradeable("Pez_Sardina"), "los peces se pueden comerciar")
local Social = loadModule(ROOT .. "/shared/Social")
local SocialService = loadModule(S .. "SocialService")
SocialService.init()
local G = remotes.Social.OnServerEvent
local eva = newPlayer(81, "Adulto", 100)
local leo = newPlayer(82, "Adulto", 100)
local mia = newPlayer(83, "Adolescente", 100)
G:Fire(eva, "Invite", 82)
local invite = lastMessage(leo, "GroupInvite")
check(invite ~= nil and invite[2].UserId == 81, "al invitar al grupo le llega la invitación")
G:Fire(leo, "Answer", 81, true)
local g = lastMessage(eva, "Group")
check(g ~= nil and g[2] and #g[2].Members == 2 and g[2].Members[1].Leader == true, "se crea el grupo con los dos (el que invita es el líder)")
check(eva:GetAttribute("GroupId") ~= nil and eva:GetAttribute("GroupId") == leo:GetAttribute("GroupId"), "los dos tienen el mismo grupo")
local chats = services.TextChatService:FindFirstChild(Social.Folder)
check(chats ~= nil and chats:FindFirstChild(Social.groupChannel(eva:GetAttribute("GroupId"))) ~= nil, "el grupo tiene su canal de chat")
task.wait(0.6)
G:Fire(leo, "Invite", 81)
check(notified(leo, "ya está en tu grupo"), "no se invita a quien ya está en tu grupo")
task.wait(0.6)
G:Fire(leo, "Invite", 83)
G:Fire(mia, "Answer", 82, false)
check(notified(leo, "no quiere unirse"), "se puede decir que no")
check(SocialService._groupOf[mia] == nil, "y no entra")
task.wait(0.6)
G:Fire(eva, "Invite", 83)
G:Fire(mia, "Answer", 81, true)
check(#lastMessage(leo, "Group")[2].Members == 3, "entra una tercera persona y todos lo ven")
G:Fire(leo, "Leave")
check(lastMessage(leo, "Group")[2] == nil and leo:GetAttribute("GroupId") == nil, "al salir del grupo se quita el panel")
check(#lastMessage(eva, "Group")[2].Members == 2, "los demás siguen en el grupo")
players.PlayerRemoving:Fire(mia)
check(SocialService._groupOf[eva] == nil and lastMessage(eva, "Group")[2] == nil, "si queda uno solo, el grupo se deshace")
-- Chat privado
task.wait(0.6)
G:Fire(eva, "Chat", 82)
local open = lastMessage(eva, "ChatOpen")
check(open ~= nil and open[2].Channel == Social.privateChannel(81, 82) and chats:FindFirstChild(open[2].Channel) ~= nil, "el chat privado abre un canal para los dos")
local kid = newPlayer(84, "Nino", 0)
chatBlocked[84] = true
task.wait(0.6)
G:Fire(eva, "Chat", 84)
check(notified(eva, "No puedes chatear en privado"), "si Roblox no deja chatear a esos dos, no se abre")
players.PlayerRemoving:Fire(leo)
check(chats:FindFirstChild(Social.privateChannel(81, 82)) == nil, "al irse alguien se borran sus chats privados")
local _ = kid
end)()

;(function()
print("▶ Pesca: cañas, cebo, pescar, vender en la pescadería, barco y pescador")
local Fishing = loadModule(ROOT .. "/shared/Fishing")
Fishing.BiteMin, Fishing.BiteMax = 0.2, 0.3 -- en la prueba pican enseguida
local spot = part("FishingSpot", CFrame.new(4000, 3.5, 4000), { "FishingSpot" }, { Water = "Mar", CastDistance = 10 })
spot.Size = Vector3.new(3, 5, 3)
spot.Parent = worldRoot
local shopCounter = part("FishingShopCounter", CFrame.new(4010, 2, 4000), { "FishingShopCounter" })
shopCounter.Parent = worldRoot
local dock = part("BoatDock", CFrame.new(4020, 4, 4000), { "FishingBoatDock" })
dock.Parent = worldRoot
local deck = part("Deck spawn", CFrame.new(4300, 3, 4300), { "FishingBoatDeck" })
deck.Parent = worldRoot
local FishingService = loadModule(S .. "FishingService")
FishingService.init()
check(jobProviders.Handler_Pescador ~= nil, "el tablón del puerto lleva al oficio de pescador")
local fisher, fisherRoot = newPlayer(81, "Adulto", 200)
profiles[fisher].Items = {}
InventoryService.refresh(fisher)
moveTo(fisherRoot, Vector3.new(4000, 0, 4000))
promptOf(spot, "Pescar").Triggered:Fire(fisher)
check(notified(fisher, "Necesitas una caña"), "sin caña no se puede pescar")
-- Tienda de pesca
moveTo(fisherRoot, Vector3.new(4008, 0, 4000))
promptOf(shopCounter, "Comprar").Triggered:Fire(fisher)
check(lastMessage(fisher, "Shop") ~= nil and #lastMessage(fisher, "Shop")[2] == 13, "la tienda enseña las 5 cañas, 7 herramientas y el cebo")
local F = remotes.Fishing.OnServerEvent
F:Fire(fisher, "Buy", "CanaPescar")
F:Fire(fisher, "Buy", "Cebo")
check(InventoryService.count(fisher, "CanaPescar") == 1 and InventoryService.count(fisher, "Cebo") == Fishing.Bait.Pack, "compra una caña y un paquete de cebo")
check(profiles[fisher].Money == 200 - Fishing.Rods.CanaPescar.Price - Fishing.Bait.Price, "paga la caña y el cebo")
F:Fire(fisher, "Buy", "CanaPescar")
check(notified(fisher, "Ya tienes"), "no compra dos cañas iguales")
-- Pescar
moveTo(fisherRoot, Vector3.new(4000, 0, 4000))
promptOf(spot, "Pescar").Triggered:Fire(fisher)
local cast = lastMessage(fisher, "Cast")
check(cast ~= nil and cast[2].Bobber.Y < 0, "se lanza el sedal y el corcho cae al agua")
check(InventoryService.count(fisher, "Cebo") == Fishing.Bait.Pack - 1, "cada lanzamiento gasta un cebo")
F:Fire(fisher, "Reel", cast[2].Token)
check(lastMessage(fisher, "Result")[2].Kind == "Early", "si tiras antes de que pique, el pez se asusta")
local function fishInBag(who)
	local n = 0
	for _, sp in Fishing.Species do
		n += InventoryService.count(who, sp.Item)
	end
	return n
end
local caught, catches, everyCatchStored = nil, 0, true
for _ = 1, 25 do
	F:Fire(fisher, "Again")
	local c = lastMessage(fisher, "Cast")
	task.wait(0.45)
	local bite = lastMessage(fisher, "Bite")
	if bite and bite[2].Token == c[2].Token then
		local before = fishInBag(fisher)
		F:Fire(fisher, "Reel", c[2].Token)
		local r = lastMessage(fisher, "Result")[2]
		if r.Kind == "Catch" then
			caught = r
			catches += 1
			-- El pez que dice que has pescado es el que entra en la mochila
			local species = nil
			for _, sp in Fishing.Species do
				if sp.Name == r.Name then
					species = sp
				end
			end
			if fishInBag(fisher) ~= before + 1 or not species or InventoryService.count(fisher, species.Item) < 1 then
				everyCatchStored = false
			end
			if catches >= 3 then
				break
			end
		end
	end
end
check(caught ~= nil, "cuando pica y tiras a tiempo, sacas un pez")
check(fishInBag(fisher) >= catches and everyCatchStored, ("cada pez pescado va a la mochila (%d de %d)"):format(fishInBag(fisher), catches))
check(string.find(fisher:GetAttribute("Inventory") or "", "Pez_") ~= nil, "y se ve en la mochila (casillas del inventario)")
-- Caben muchos peces iguales (antes el 21º se perdía)
local sardines = InventoryService.count(fisher, "Pez_Sardina")
check(InventoryService.canAdd(fisher, "Pez_Sardina", 40 - sardines), "caben 40 sardinas en la mochila")
-- Tardar demasiado
F:Fire(fisher, "Again")
local slow = lastMessage(fisher, "Cast")[2].Token
task.wait(0.35 + Fishing.Window + 0.6)
check(lastMessage(fisher, "Result")[2].Kind == "Late" and lastMessage(fisher, "Result")[2].Token == slow, "si tardas en tirar, se escapa")
-- Vender en la pescadería
local counter = nil
for _, c in services.CollectionService:GetTagged("SuperFish") do
	counter = c
end
local sardineShelf = nil
for _, d in counter.Parent:GetDescendants() do
	if d:GetAttribute("Product") == "Sardinas" then
		sardineShelf = d
	end
end
InventoryService.add(fisher, "Pez_Sardina", 3)
local sardinesToSell = InventoryService.count(fisher, "Pez_Sardina")
local moneyBefore = profiles[fisher].Money
local stockBefore = sardineShelf:GetAttribute("Stock") or 0
promptOf(counter, "Vender pescado").Triggered:Fire(fisher)
check(InventoryService.count(fisher, "Pez_Sardina") == 0 and sardineShelf:GetAttribute("Stock") == math.min(stockBefore + sardinesToSell, loadModule(ROOT .. "/shared/Groceries").StockMax), "las sardinas pasan al mostrador del supermercado")
check(profiles[fisher].Money >= moneyBefore + 3 * Fishing.byId.Sardina.Price, "el supermercado paga el pescado")
-- Barco de pesca (alquiler)
moneyBefore = profiles[fisher].Money
moveTo(fisherRoot, Vector3.new(4020, 0, 4000))
promptOf(dock, "Subir al barco de pesca").Triggered:Fire(fisher)
check(profiles[fisher].Money == moneyBefore - Fishing.BoatPrice and fisher:GetAttribute("BoatReturn") ~= nil, "se alquila el barco y subes a alta mar (y sabe por dónde volver)")
-- Pescador de turno: le prestan una caña y el barco le sale gratis
local pro, proRoot = newPlayer(82, "AdultoJoven", 50)
profiles[pro].Items = {}
InventoryService.refresh(pro)
moveTo(proRoot, Vector3.new(4020, 0, 4000))
FishingService.start(pro)
check(pro:GetAttribute("Job") == "Pescador" and InventoryService.count(pro, "CanaPescar") == 1, "al empezar de pescador te prestan una caña")
promptOf(dock, "Subir al barco de pesca").Triggered:Fire(pro)
check(profiles[pro].Money == 50, "el barco es gratis para los pescadores")
InventoryService.add(pro, "Pez_Sardina", 2)
local jobEvents = 0
local conn = StoryEventsModule.connect(function(p, name, payload)
	if p == pro and name == "JobTaskDone" and payload.JobId == "Pescador" then
		jobEvents += 1
	end
end)
promptOf(counter, "Vender pescado").Triggered:Fire(pro)
check(profiles[pro].Money >= 50 + math.floor(2 * Fishing.byId.Sardina.Price * Fishing.Job.PayBonus), "de pescador cobras más por el pescado")
check(jobEvents == 1, "cada venta del pescador cuenta para la historia")
if conn and conn.Disconnect then
	conn:Disconnect()
end
FishingService.quit(pro)
check(pro:GetAttribute("Job") == nil and InventoryService.count(pro, "CanaPescar") == 0, "al acabar el turno devuelves la caña prestada")
end)()

;(function()
print("▶ Pesca por niveles: mucha variedad, peces grandes, bancos que vuelven y monstruos entre varios")
local Fishing = loadModule(ROOT .. "/shared/Fishing")
local FishingService = loadModule(S .. "FishingService")
local F = remotes.Fishing.OnServerEvent
local pop = FishingService._pop
check(#Fishing.Species >= 40, ("hay mucha variedad de peces (%d especies)"):format(#Fishing.Species))
for water in Fishing.Waters do
	local easy = false
	for _, sp in Fishing.Species do
		if sp.Waters[water] and sp.Level == 1 and sp.Tool == nil then
			easy = true
		end
	end
	check(easy, "en " .. Fishing.Waters[water] .. " hay peces para empezar")
end
local deepOnly = true
for _, sp in Fishing.Species do
	if sp.Level >= 24 and (sp.Waters.Mar or sp.Waters.Rio or sp.Waters.Lago) and not sp.Waters.AltaMar and sp.Level > 30 then
		deepOnly = false
	end
end
check(deepOnly and Fishing.byId.TiburonBlanco.Waters.AltaMar ~= nil and Fishing.byId.TiburonBlanco.Waters.Mar == nil, "los más grandes solo están en alta mar (hace falta el barco)")
check(Fishing.levelFor(0) == 1 and Fishing.levelFor(Fishing.xpFor(10)) == 10 and Fishing.levelFor(Fishing.xpFor(10) - 1) == 9, "la experiencia sube el nivel")
-- En la prueba: sin basura, los bancos no se rellenan por tiempo y las peleas duran poco
local saved = { Junk = Fishing.JunkWeight, Regen = Fishing.Respawn.RegenSeconds, Secs = Fishing.Respawn.Seconds, Fight = Fishing.fightSeconds, Gap = Fishing.BossPullGap }
Fishing.JunkWeight = 0
Fishing.Respawn.RegenSeconds = 1e9
Fishing.Respawn.Seconds = 1e9
Fishing.fightSeconds = function()
	return 2.5
end
local function onlyIn(water, counts)
	for id in pop[water] do
		pop[water][id] = counts[id] or 0
	end
end
local spots = {}
for i = 1, 4 do
	local sp = part("FishingSpot", CFrame.new(5000 + i * 20, 3.5, 5000), { "FishingSpot" }, { Water = "AltaMar", CastDistance = 10 })
	sp.Size = Vector3.new(3, 5, 3)
	spots[i] = sp
end
local function fisherAt(id, i, xp, gear)
	local p, root = newPlayer(id, "Adulto", 100)
	profiles[p].Items = {}
	for _, g in gear do
		profiles[p].Items[g] = 1
	end
	profiles[p].Fishing = { Xp = xp, Caught = {} }
	InventoryService.refresh(p)
	moveTo(root, spots[i].Position - Vector3.new(0, 3, 0))
	return p
end
-- Espera a que pique y tira; devuelve el mensaje que llegue (Result o Fight)
local function hook(p, spot)
	FishingService._cast(p, spot)
	local c = lastMessage(p, "Cast")
	task.wait(0.45)
	local bite = lastMessage(p, "Bite")
	if not bite or bite[2].Token ~= c[2].Token then
		return nil, c
	end
	F:Fire(p, "Reel", c[2].Token)
	local fight = lastMessage(p, "Fight")
	if fight and fight[2].Token == c[2].Token then
		return fight, c
	end
	return lastMessage(p, "Result"), c
end
-- Novato: pica un tiburón blanco y rompe el sedal (te dice qué te falta)
local novice = fisherAt(91, 1, 0, { "CanaPescar" })
onlyIn("AltaMar", { TiburonBlanco = 5 })
local r = hook(novice, spots[1])
check(r ~= nil and r[2].Kind == "Locked" and table.find(r[2].Missing, "nivel 38") ~= nil and table.find(r[2].Missing, "arpón") ~= nil, "si pica uno demasiado grande, rompe el sedal y te dice qué te falta")
check(InventoryService.count(novice, "Pez_TiburonBlanco") == 0 and pop.AltaMar.TiburonBlanco == 5, "y no te lo llevas (sigue en el agua)")
-- Experto: pelea a tirones y lo saca
local expert = fisherAt(92, 2, Fishing.xpFor(45), { "CanaAbisal", "Arpon", "Sonar" })
local xpBefore = profiles[expert].Fishing.Xp
local fight, c = hook(expert, spots[2])
local need = Fishing.pullsFor(Fishing.byId.TiburonBlanco, 5)
check(fight ~= nil and fight[1] == "Fight" and fight[2].Need == need and need > 1, ("los peces grandes pelean: hay que tirar %d veces"):format(need))
check(expert:GetAttribute("FishAnim") == "Fight", "mientras pelea, todos le ven tirar de la caña")
for _ = 2, need do
	task.wait(0.12)
	F:Fire(expert, "Reel", c[2].Token)
end
local res = lastMessage(expert, "Result")
check(res ~= nil and res[2].Kind == "Catch" and res[2].Name == Fishing.byId.TiburonBlanco.Name, "a base de tirones saca el tiburón blanco")
check(expert:GetAttribute("FishAnim") == "Catch" and expert:GetAttribute("FishAnimFish") == "TiburonBlanco" and type(expert:GetAttribute("FishAnimAt")) == "number", "todos ven la animación de sacarlo y el pez en la mano")
check(InventoryService.count(expert, "Pez_TiburonBlanco") == 1 and pop.AltaMar.TiburonBlanco == 4, "va a la mochila y queda uno menos en el agua")
check(profiles[expert].Fishing.Xp == xpBefore + Fishing.byId.TiburonBlanco.Xp and profiles[expert].Fishing.Caught.TiburonBlanco == 1, "da experiencia y cuenta para la guía de peces")
check(expert:GetAttribute("FishingLevel") == 45 and novice:GetAttribute("FishingLevel") == 1, "cada uno ve su nivel de pesca")
-- Si no tiras a tiempo, se suelta
fight, c = hook(expert, spots[2])
task.wait(3.2)
check(lastMessage(expert, "Result")[2].Kind == "Escaped", "si dejas de tirar, el pez grande se suelta")
-- Subir de nivel avisa de lo nuevo
local learner = fisherAt(93, 3, Fishing.xpFor(2) - 1, { "CanaPescar" })
onlyIn("AltaMar", { Sardina = 30 })
r = hook(learner, spots[3])
check(r ~= nil and r[2].Kind == "Catch" and learner:GetAttribute("FishingLevel") >= 2 and notified(learner, "Nivel de pesca"), "al subir de nivel te avisa de lo que desbloqueas")
-- Bancos de peces: si se acaba una especie, vuelve tras unas capturas
onlyIn("AltaMar", { TiburonBlanco = 1, Merluza = 36 })
for _ = 1, 30 do
	fight, c = hook(expert, spots[2])
	if fight and fight[1] == "Fight" then
		for _ = 2, need do
			task.wait(0.12)
			F:Fire(expert, "Reel", c[2].Token)
		end
		break
	end
end
check(pop.AltaMar.TiburonBlanco == 0, "se ha pescado el último tiburón blanco")
for _ = 1, Fishing.Respawn.AfterCatches do
	hook(expert, spots[2])
end
check(pop.AltaMar.TiburonBlanco == Fishing.byId.TiburonBlanco.Pop and notified(expert, "Ha vuelto un banco de gran tiburón blanco"), "tras unas capturas vuelven a salir (el mar no se vacía)")
onlyIn("AltaMar", {})
FishingService._cast(learner, spots[3])
task.wait(1.2) -- el bucle del servicio lo nota
check(pop.AltaMar.Sardina > 0, "aunque se pescara todo, vuelven peces nuevos")
-- Monstruos: el Megalodón solo se saca entre varios
Fishing.BossPullGap = 0
local mega = Fishing.Bosses.Megalodon
local savedHp = mega.Hp
mega.Hp = 40
local b1 = fisherAt(94, 1, Fishing.xpFor(45), { "CanaAbisal", "Arpon", "Sonar" })
local b3 = fisherAt(95, 3, Fishing.xpFor(45), { "CanaAbisal", "Arpon", "Sonar" })
local b4 = fisherAt(96, 4, Fishing.xpFor(45), { "CanaAbisal", "Arpon", "Sonar" })
F:Fire(novice, "Stop")
F:Fire(learner, "Stop")
F:Fire(expert, "Stop")
for i, p in { b1, expert, b3, b4 } do
	FishingService._cast(p, spots[i])
end
FishingService._startBoss(mega)
check(lastMessage(b1, "Boss") ~= nil and lastMessage(b3, "Boss")[2].MinPlayers == 3, "¡pica el Megalodón! A todos los del barco les sale")
for _ = 1, 15 do
	for _, p in { b1, expert, b3 } do
		F:Fire(p, "Reel", "Boss")
	end
end
local ended = lastMessage(b1, "BossEnd")
check(ended ~= nil and ended[2].Win == true, "entre tres pescadores expertos lo sacan")
check(InventoryService.count(b1, "Pez_Megalodon") == 1 and InventoryService.count(b3, "Pez_Megalodon") == 1 and InventoryService.count(b4, "Pez_Megalodon") == 0, "cada uno que ha tirado se lleva el trofeo (el que no ha tirado, no)")
-- Uno solo no puede con el Kraken
local kraken = Fishing.Bosses.Kraken
local savedK = kraken.Hp
kraken.Hp = 20
FishingService._startBoss(kraken)
for _ = 1, 25 do
	F:Fire(b1, "Reel", "Boss")
end
check(lastMessage(b1, "BossEnd")[2].Win == false and InventoryService.count(b1, "Pez_Kraken") == 0, "el Kraken no lo saca uno solo (hacen falta 4)")
mega.Hp, kraken.Hp = savedHp, savedK
-- La lonja compra lo que el supermercado no vende
local counter = nil
for _, cc in services.CollectionService:GetTagged("SuperFish") do
	counter = cc
end
local money = profiles[b1].Money
promptOf(counter, "Vender pescado").Triggered:Fire(b1)
check(profiles[b1].Money >= money + mega.Price and InventoryService.count(b1, "Pez_Megalodon") == 0, "la lonja paga el trofeo del Megalodón")
-- La tienda pide nivel para el equipo bueno
local shop = nil
for _, cc in services.CollectionService:GetTagged("FishingShopCounter") do
	shop = cc
end
local _, noviceRoot = nil, novice.Character.HumanoidRootPart
moveTo(noviceRoot, shop.Position)
profiles[novice].Money = 10000
F:Fire(novice, "Buy", "CanaAbisal")
check(InventoryService.count(novice, "CanaAbisal") == 0 and notified(novice, "pide nivel de pesca 32"), "la caña abisal pide nivel 32")
F:Fire(novice, "Buy", "Arpon")
check(InventoryService.count(novice, "Arpon") == 0, "el arpón también pide nivel")
F:Fire(expert, "Buy", "Red")
Fishing.JunkWeight, Fishing.Respawn.RegenSeconds, Fishing.Respawn.Seconds, Fishing.fightSeconds, Fishing.BossPullGap = saved.Junk, saved.Regen, saved.Secs, saved.Fight, saved.Gap
for water, list in pop do
	for id in list do
		list[id] = Fishing.byId[id].Pop
	end
end
end)()

;(function()
print("▶ Pescar en cualquier agua (orillas del lago, del río y del mar)")
local FishingService = loadModule(S .. "FishingService")
local angler, anglerRoot = newPlayer(83, "Adulto", 0)
profiles[angler].Items = { CanaPescar = 1 }
InventoryService.refresh(angler)
local F = remotes.Fishing.OnServerEvent
local realIsWater = FishingService.isWater
FishingService.isWater = function()
	return false
end
moveTo(anglerRoot, Vector3.new(-2750 + 300, 0, -520))
F:Fire(angler, "Here")
check(notified(angler, "no hay agua"), "sin agua delante no se puede pescar")
FishingService.isWater = function()
	return true
end
local function waterAt(position)
	moveTo(anglerRoot, position)
	F:Fire(angler, "Here")
	local cast = lastMessage(angler, "Cast")
	F:Fire(angler, "Stop")
	return cast and cast[2].Water
end
check(waterAt(Vector3.new(-2750 + 300, 0, -520)) == "el lago", "en la orilla del lago se pescan peces de lago")
check(waterAt(Vector3.new(1440, 0, -400)) == "el río", "en la orilla del río, peces de río")
check(waterAt(Vector3.new(700, 0, 3600)) == "el mar", "en la costa, peces de mar")
FishingService.isWater = realIsWater
end)()

;(function()
print("▶ Metro: billetes, tornos, tren, galería, músicos, encargos y revisor")
local Metro = loadModule(ROOT .. "/shared/Metro")
Metro.Busk.MinSeconds, Metro.Busk.Cooldown = 0, 0
local M = remotes.Metro.OnServerEvent
local L1 = Metro.lineById.L1
local function mp(name, cf, tags, attrs, size)
	local p = part(name, cf, tags, attrs)
	p.Size = size or Vector3.new(4, 5, 2)
	p.Parent = worldRoot
	return p
end
-- Estaciones (lo mínimo de cada una)
for id, st in Metro.Stations do
	local c = Vector3.new(st.Surface[1], -150, st.Surface[2])
	mp("Door", CFrame.new(st.Surface[1], 2.5, st.Surface[2]), { "MetroEntrance" }, { Station = id })
	mp("Arrival", CFrame.new(c + Vector3.new(30, 3, 0)), { "MetroArrival" }, { Station = id, Line = "L1" })
	mp("Alight", CFrame.new(c + Vector3.new(12, 3, 0)), { "MetroAlight" }, { Station = id, Line = "L1" })
	local kiosk = mp("Kiosk", CFrame.new(c + Vector3.new(40, 2, 18)), { "MetroShop", "MetroDelivery" }, { ShopId = "Quiosco", Station = id })
	local _ = kiosk
end
local P = Metro.Stations.Poniente
local base = Vector3.new(P.Surface[1], -150, P.Surface[2])
local machine = mp("TicketMachine", CFrame.new(base + Vector3.new(46, 3, -20)), { "MetroTicketMachine" })
local gate = mp("Turnstile", CFrame.new(base + Vector3.new(19, 2, 0)), { "MetroGate" }, { Through = base + Vector3.new(14, 3, 0) })
local board = mp("Board", CFrame.new(base + Vector3.new(7, 2.5, 0)), { "MetroBoard" }, { Station = "Poniente", Line = "L1" })
-- Tren de la Línea 1 (3 coches con un asiento y una puerta cada uno)
local trainModel = fakeInstance("Model")
trainModel.Name = "Metro_L1"
trainModel:SetAttribute("Line", "L1")
trainModel.Parent = worldRoot
for k = 1, 3 do
	local carModel = fakeInstance("Model")
	carModel.Name = "Car" .. k
	carModel.Parent = trainModel
	local root = part("Root", CFrame.new(base), {})
	root.Parent = carModel
	local seat = fakeInstance("Seat")
	seat.Name = "Seat"
	seat.CFrame = CFrame.new(base)
	seat.Parent = carModel
	local door = part("Door", CFrame.new(base), { "MetroDoor" })
	door.Parent = carModel
end
trainModel:AddTag("MetroTrain")
-- Galería
local H = Metro.Stations.PlazaMayor
local hub = Vector3.new(H.Surface[1], -150, H.Surface[2])
local music = mp("Counter", CFrame.new(hub + Vector3.new(98, 2, 28)), { "MetroShop" }, { ShopId = "Musica" })
local mic = mp("Mic", CFrame.new(hub + Vector3.new(128, 3, -16)), { "MetroStage" })
local missionBoard = mp("MissionBoard", CFrame.new(hub + Vector3.new(80, 5, -24)), { "MetroMissionBoard" })
local lostOffice = mp("LostOffice", CFrame.new(hub + Vector3.new(58, 2, -28)), { "MetroLostOffice" })
local MetroService = loadModule(S .. "MetroService")
MetroService.init()
check(jobProviders.Handler_Revisor ~= nil, "el tablón de la galería lleva al oficio de revisor/a")
local train = MetroService._trains.L1
check(train ~= nil and train.Phase == "Dwell" and train.Index == 1, "el tren de la Línea 1 espera en la primera estación con las puertas abiertas")
local rider, riderRoot, riderHumanoid = newPlayer(91, "Adulto", 100)
profiles[rider].Items = {}
InventoryService.refresh(rider)
moveTo(riderRoot, Vector3.new(P.Surface[1], 0, P.Surface[2]))
local door = nil
for _, d in services.CollectionService:GetTagged("MetroEntrance") do
	if d:GetAttribute("Station") == "Poniente" then
		door = d
	end
end
promptOf(door, "Bajar al metro").Triggered:Fire(rider)
check(notified(rider, "Metro · Poniente"), "por la boca de metro se baja al vestíbulo")
moveTo(riderRoot, base + Vector3.new(40, -2, -18))
promptOf(gate, "Pasar (billete)").Triggered:Fire(rider)
check(notified(rider, "Necesitas un billete"), "sin billete no se pasa el torno")
M:Fire(rider, "BuyTicket", "Sencillo")
check(profiles[rider].Money == 98 and InventoryService.count(rider, "BilleteMetro") == 1, "la máquina vende el billete")
promptOf(gate, "Pasar (billete)").Triggered:Fire(rider)
check(InventoryService.count(rider, "BilleteMetro") == 0 and rider:GetAttribute("MetroTicket") == true, "el torno gasta el billete")
-- Subir y viajar
moveTo(riderRoot, base + Vector3.new(8, -2, 0))
promptOf(board, "Subir al metro").Triggered:Fire(rider)
check(riderHumanoid.SeatPart ~= nil and MetroService._riding[rider] == train and lastMessage(rider, "Board") ~= nil, "sube al tren y se sienta")
local guard = 0
while not (train.Index == 2 and train.Phase == "Dwell") and guard < 400 do
	guard += 1
	MetroService._step(train, 0.5)
end
local arrive = lastMessage(rider, "Arrive")
check(arrive ~= nil and arrive[2].Station == "Plaza Mayor", "el tren llega a Plaza Mayor y te avisa")
local car2 = trainModel:FindFirstChild("Car2"):FindFirstChild("Root")
check((car2.Position - Metro.center("PlazaMayor", L1)).Magnitude < 5, "el tren para con el centro en el andén")
check(train.Cars[1].Doors[1].Transparency == 1, "con el tren parado las puertas están abiertas")
M:Fire(rider, "Alight")
check(MetroService._riding[rider] == nil and lastMessage(rider, "Off") ~= nil, "bajas en Plaza Mayor")
MetroService._step(train, Metro.Dwell + 0.1)
check(train.Phase == "Move" and train.Cars[1].Doors[1].Transparency == 0, "el tren cierra las puertas y sigue")
-- Galería: tienda de discos y escenario
moveTo(riderRoot, hub + Vector3.new(98, -2, 22))
profiles[rider].Money = 30
M:Fire(rider, "Buy", "Musica", "Guitarra")
check(InventoryService.count(rider, "Guitarra") == 0, "sin dinero suficiente no se compra la guitarra")
profiles[rider].Money = 200
M:Fire(rider, "Buy", "Musica", "Guitarra")
check(InventoryService.count(rider, "Guitarra") == 1 and profiles[rider].Money == 140, "compra una guitarra en la tienda de discos")
moveTo(riderRoot, hub + Vector3.new(128, -2, -12))
promptOf(mic, "Tocar música").Triggered:Fire(rider)
local buskMsg = lastMessage(rider, "Busk")
check(buskMsg ~= nil, "en el escenario empieza la actuación")
M:Fire(rider, "BuskEnd", buskMsg[2].Token, 99)
check(profiles[rider].Money == 140 + Metro.Busk.Notes * Metro.Busk.PerHit, "las propinas dependen de las notas (y no se puede hacer trampa)")
-- Encargos
promptOf(missionBoard, "Ver encargos").Triggered:Fire(rider)
check(lastMessage(rider, "Missions") ~= nil and #lastMessage(rider, "Missions")[2].Offers == 3, "el tablón ofrece tres encargos")
M:Fire(rider, "Accept", "Perdido")
local m = MetroService._missions[rider]
check(m ~= nil and m.Thing ~= nil, "aparece el objeto perdido en otra estación")
promptOf(m.Thing, "Recoger").Triggered:Fire(rider)
check(InventoryService.count(rider, "CarteraPerdida") == 1, "lo recoges")
local before = profiles[rider].Money
promptOf(lostOffice, "Objetos perdidos").Triggered:Fire(rider)
check(profiles[rider].Money == before + Metro.Missions.Perdido.Reward and InventoryService.count(rider, "CarteraPerdida") == 0, "en Objetos Perdidos te pagan")
M:Fire(rider, "Accept", "Paquete")
m = MetroService._missions[rider]
check(InventoryService.count(rider, "PaqueteMetro") == 1, "te dan el paquete urgente")
local kiosk = nil
for _, k in services.CollectionService:GetTagged("MetroDelivery") do
	if k:GetAttribute("Station") == m.Station then
		kiosk = k
	end
end
before = profiles[rider].Money
promptOf(kiosk, "Entregar paquete").Triggered:Fire(rider)
check(profiles[rider].Money == before + Metro.Missions.Paquete.Reward + Metro.Missions.Paquete.Bonus, "entregado a tiempo en el quiosco: pago y propina")
M:Fire(rider, "Accept", "Gato")
m = MetroService._missions[rider]
promptOf(m.Thing, "Coger al gato").Triggered:Fire(rider)
check(rider:GetAttribute("CarryingCat") == true, "encuentras al gato del metro")
before = profiles[rider].Money
promptOf(missionBoard, "Ver encargos").Triggered:Fire(rider)
check(profiles[rider].Money == before + Metro.Missions.Gato.Reward and rider:GetAttribute("CarryingCat") == nil, "lo devuelves al tablón y te pagan")
-- Revisor
local inspector, inspectorRoot = newPlayer(92, "Adulto", 0)
moveTo(inspectorRoot, base + Vector3.new(12, 0, 0))
MetroService.startRevisor(inspector)
check(inspector:GetAttribute("Job") == "Revisor", "empieza el turno de revisor/a")
local ask = nil
for _, d in worldRoot:GetDescendants() do
	if d.ClassName == "ProximityPrompt" and d.ActionText == "Pedir el billete" and d:GetAttribute("OwnerUserId") == 92 then
		ask = d
	end
end
check(ask ~= nil, "hay viajeros en el andén para revisar")
local events = 0
StoryEventsModule.connect(function(p, name, payload)
	if p == inspector and name == "JobTaskDone" and payload.JobId == "Revisor" then
		events += 1
	end
end)
ask.Triggered:Fire(inspector)
check(profiles[inspector].Money == Metro.Revisor.PerCheck or profiles[inspector].Money == Metro.Revisor.PerFine, "cobra por revisar (y más si pone una multa)")
check(events == 1, "cada revisión cuenta para la historia")
MetroService.quitRevisor(inspector)
check(inspector:GetAttribute("Job") == nil, "termina el turno")
print("▶ Nadar, bucear y pesca submarina con fusil o arpón")
local Fishing = loadModule(ROOT .. "/shared/Fishing")
local FishingService = loadModule(S .. "FishingService")
local DivingService = loadModule(S .. "DivingService")
local realIsWater = FishingService.isWater
FishingService.isWater = function(p)
	return p.Y < Fishing.Dive.Surface + 0.5 -- en la prueba, todo es agua por debajo de la superficie
end
local savedGap = Fishing.Dive.ShotGap
Fishing.Dive.ShotGap = 0
DivingService.init()
local D = remotes.Diving.OnServerEvent
local function diver(id, xp, gear, at)
	local p, root, humanoid = newPlayer(id, "Adulto", 100)
	profiles[p].Items = {}
	for _, g in gear do
		profiles[p].Items[g] = 1
	end
	profiles[p].Fishing = { Xp = xp, Caught = {} }
	InventoryService.refresh(p)
	root.CFrame = CFrame.new(at)
	p.Character.Head.CFrame = CFrame.new(at + Vector3.new(0, 1.5, 0))
	return p, root, humanoid
end
local function fishesOf(p)
	local n = 0
	for _, f in DivingService._fishes do
		if f.Owner == p then
			n += 1
		end
	end
	return n
end
local where = Vector3.new(6000, -9, 6000)
local ana, anaRoot, anaHum = diver(101, 0, { "FusilSubmarino" }, where)
task.wait(2.3)
check(DivingService.underwater(ana), "bajo el agua, el buceador está sumergido")
check(ana:GetAttribute("OxygenMax") == Fishing.Dive.Oxygen.Base and ana:GetAttribute("Oxygen") < Fishing.Dive.Oxygen.Base, "bajo el agua se gasta el aire")
check(ana:GetAttribute("Speargun") == "FusilSubmarino" and ana:GetAttribute("DiveGear") == nil, "los demás ven el fusil en su mano")
check(fishesOf(ana) >= 1, "con el fusil submarino salen peces nadando alrededor")
-- Un pez que aún no puede cazar
local dorada = DivingService.spawn(ana, Fishing.byId.Dorada, where + Vector3.new(6, 0, 0), "Mar")
D:Fire(ana, "Shoot", dorada)
check(notified(ana, "te falta nivel 3") and dorada.Parent ~= nil, "si el pez pide más nivel, no se caza (y te dice qué falta)")
-- Uno que sí
local popBefore = FishingService.pop.Rio.Trucha
local trucha = DivingService.spawn(ana, Fishing.byId.Trucha, where + Vector3.new(0, 0, 8), "Rio")
D:Fire(ana, "Shoot", trucha)
check(InventoryService.count(ana, "Pez_Trucha") == 1 and lastMessage(ana, "Caught") ~= nil, "disparas con el fusil y la trucha va a la mochila")
check(type(ana:GetAttribute("SpearAt")) == "number", "el disparo se ve (retroceso del arma)")
check(profiles[ana].Fishing.Xp > 0 and FishingService.pop.Rio.Trucha == popBefore - 1 and trucha.Parent == nil, "da experiencia y sale del banco de peces")
local far = DivingService.spawn(ana, Fishing.byId.Trucha, where + Vector3.new(40, 0, 0), "Rio")
D:Fire(ana, "Shoot", far)
check(notified(ana, "demasiado lejos") and far.Parent ~= nil, "no se puede disparar a un pez muy lejos")
-- Los grandes: arpón y varios disparos
local shark = DivingService.spawn(ana, Fishing.byId.TiburonAzul, where + Vector3.new(0, 0, -8), "AltaMar")
D:Fire(ana, "Shoot", shark)
check(notified(ana, "arpón"), "los grandes piden arpón")
local leo = diver(102, Fishing.xpFor(45), { "Arpon", "Botella" }, where + Vector3.new(0, 0, -4))
local hp = shark:GetAttribute("Hp")
check(hp > 1, ("un tiburón aguanta varios disparos (%d)"):format(hp))
D:Fire(leo, "Shoot", shark)
check(shark:GetAttribute("Hp") == hp - 1 and lastMessage(leo, "Hit") ~= nil and InventoryService.count(leo, "Pez_TiburonAzul") == 0, "al primer disparo queda herido y huye")
for _ = 1, hp do
	if shark.Parent then
		moveTo(leo.Character.HumanoidRootPart, shark.Position - Vector3.new(0, 3 + 3, 0))
		leo.Character.Head.CFrame = CFrame.new(shark.Position - Vector3.new(0, 1.5, 0))
		D:Fire(leo, "Shoot", shark)
	end
end
check(InventoryService.count(leo, "Pez_TiburonAzul") == 1, "a varios arponazos saca el tiburón azul")
-- Sin estar bajo el agua no se dispara
local t2 = DivingService.spawn(ana, Fishing.byId.Trucha, where + Vector3.new(4, 0, 0), "Rio")
ana.Character.Head.CFrame = CFrame.new(where + Vector3.new(0, 20, 0))
D:Fire(ana, "Shoot", t2)
check(t2.Parent ~= nil and InventoryService.count(ana, "Pez_Trucha") == 1, "fuera del agua no se dispara")
-- Aire: sin aire pierdes vida; al salir se recupera; con gafas aguantas más
ana.Character.Head.CFrame = CFrame.new(where + Vector3.new(0, 1.5, 0))
ana:SetAttribute("Oxygen", 1)
local health = anaHum.Health
task.wait(2.2)
check(anaHum.Health < health and notified(ana, "sin aire"), "sin aire pierdes vida")
ana.Character.Head.CFrame = CFrame.new(where + Vector3.new(0, 20, 0))
task.wait(1.2)
check(ana:GetAttribute("Oxygen") > 0, "al sacar la cabeza recuperas el aire")
InventoryService.add(ana, "Gafas", 1)
task.wait(1.2)
check(ana:GetAttribute("OxygenMax") == Fishing.Dive.Oxygen.Gafas and leo:GetAttribute("OxygenMax") == Fishing.Dive.Oxygen.Botella, "con gafas y tubo o con equipo de buceo aguantas más")
check(Fishing.spearable(Fishing.byId.Mero) and not Fishing.spearable(Fishing.byId.Gamba), "se cazan buceando los peces medianos y grandes (las gambas no)")
Fishing.Dive.ShotGap = savedGap
FishingService.isWater = realIsWater
local _ = anaRoot
end)()

;(function()
print("▶ Interiores: cada tipo de sala amueblado y decorado")
local Interiors = loadModule(ROOT .. "/server/World/Interiors")
local Interact = loadModule(ROOT .. "/shared/Interact")
local Properties = loadModule(ROOT .. "/shared/Properties")
local lab = fakeInstance("Folder")
lab.Name = "PruebasInteriores"
lab.Parent = worldRoot
local function countParts(model)
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end
local function usesOf(model)
	local set = {}
	for _, d in model:GetDescendants() do
		if d:HasTag("Interact") then
			local use = d:GetAttribute("Use")
			set[use] = (set[use] or 0) + 1
		end
	end
	return set
end
-- Mínimo de piezas (muebles y detalles) de cada tipo
local MIN = {
	Casa = 350, Villa = 420, Piso = 330, Portal = 80, OficinaLobby = 150, Oficina = 300, Local = 150,
	Nave = 150, Taller = 110, Ocio = 250, Aula = 200, Ayuntamiento = 200, Museo = 200, Teatro = 250,
	Estacion = 150, CentroComercial = 250, Juzgado = 150, Hacienda = 120, Cuartel = 180,
}
local kinds = {}
for kind in MIN do
	table.insert(kinds, kind)
end
table.sort(kinds)
for _, kind in kinds do
	local ok, r = pcall(Interiors[kind], lab, CFrame.new(0, 5000, 0), { Seed = kind .. "_7_7:0" })
	check(ok, kind .. " se construye" .. (if ok then "" else ": " .. tostring(r)))
	if ok then
		local n = countParts(r.Model)
		local u = usesOf(r.Model)
		check(n > MIN[kind] and n < 1800, ("%s: %d piezas (más de %d, sin pasarse)"):format(kind, n, MIN[kind]))
		check((u.Sit or 0) > 0 and (u.Light or 0) > 0, ("%s: asientos (%d) e interruptor"):format(kind, u.Sit or 0))
		check(r.Model:FindFirstChild("InteriorEntry") ~= nil, kind .. ": tiene sitio de entrada")
		r.Model:Destroy()
	end
end
for _, kind in { "Casa", "Villa", "Piso" } do
	local r = Interiors[kind](lab, CFrame.new(0, 5000, 0), { Seed = kind .. "_3_9:1" })
	local u = usesOf(r.Model)
	check((u.TV or 0) >= 1 and (u.Bed or 0) >= 1 and u.Fridge == 1 and (u.Tap or 0) >= 2 and u.Shower == 1, kind .. ": tele, camas, nevera, grifos y ducha")
	check(u.Door == 3 and (u.Wardrobe or 0) >= 1 and (u.Window or 0) >= 5 and (u.Light or 0) >= 5, kind .. ": puertas, armarios, ventanas e interruptor en cada habitación")
	local rooms = {}
	for _, d in r.Model:GetDescendants() do
		if d:HasTag("RoomLight") then
			rooms[d:GetAttribute("Room")] = true
		end
	end
	check(rooms.Salon and rooms.Cocina and rooms.Dormitorio and rooms.Bano and rooms.Habitacion, kind .. ": luces en salón, cocina, dormitorio, baño y otra habitación")
	check(#r.Spots >= 3, kind .. ": sitios libres para los vecinos")
	local exitTag = false
	for _, d in r.Model:GetDescendants() do
		if d:HasTag("InteriorExit") then
			exitTag = true
		end
	end
	check(exitTag, kind .. (if kind == "Piso" then ": puerta al rellano" else ": puerta a la calle"))
	r.Model:Destroy()
end
-- La misma vivienda sale siempre igual; otras, distintas
local function signature(model)
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local c = d.Color or Color3.new()
			table.insert(parts, ("%s %d %d %d"):format(d.Name, math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)))
		end
	end
	table.sort(parts)
	return table.concat(parts, "|")
end
local a = Interiors.Casa(lab, CFrame.new(0, 5000, 0), { Seed = "Casa_10_20:0" })
local b = Interiors.Casa(lab, CFrame.new(300, 5000, 0), { Seed = "Casa_10_20:0" })
check(signature(a.Model) == signature(b.Model), "la misma casa sale siempre igual (misma semilla)")
local different = 0
for i = 1, 5 do
	local c = Interiors.Casa(lab, CFrame.new(0, 5000, 300), { Seed = "Casa_" .. i * 37 .. "_5:0" })
	if signature(c.Model) ~= signature(a.Model) then
		different += 1
	end
	c.Model:Destroy()
end
check(different == 5, "cada casa es distinta")
a.Model:Destroy()
b.Model:Destroy()

print("▶ Interiores: usar los muebles (tele, luces, sentarse, nevera, cama, grifo)")
Interact.Uses.Tap.Seconds = 0.15
Interact.Uses.Fridge.Seconds = 0.15
local savedSleep = Config.SleepSeconds
Config.SleepSeconds = 0.1
mocks[S .. "SceneService"] = {
	teleportTo = function(player, target)
		player.Character.HumanoidRootPart.CFrame = CFrame.new(target + Vector3.new(0, 3, 0))
	end,
}
-- Un barrio de mentira: casas, un bloque de pisos y un local de ocio
local town = fakeInstance("Folder")
town.Name = "Town"
town.Parent = worldRoot
local function building(parentName, name, position, size)
	local block = town:FindFirstChild(parentName)
	if not block then
		block = fakeInstance("Model")
		block.Name = parentName
		block.Parent = town
	end
	local m = fakeInstance("Model")
	m.Name = name
	m.Parent = block
	local body = fakeInstance("Part")
	body.Name = "Body"
	body.Size = size
	body.CFrame = CFrame.new(position)
	body.Parent = m
	return m
end
for i = 0, 5 do
	building("Manzana_Casas", "Casa", Vector3.new(2000 + i * 60, 10, 2000), Vector3.new(40, 20, 36))
end
building("Manzana_Pisos", "Bloque", Vector3.new(2000, 30, 2200), Vector3.new(40, 60, 40))
building("Ocio", "Ocio_Local", Vector3.new(2200, 10, 2200), Vector3.new(50, 20, 40))
building("Manzana_Downtown", "Bloque", Vector3.new(2400, 75, 2200), Vector3.new(40, 150, 40)) -- 12 plantas
building("Manzana_Towers", "Bloque", Vector3.new(2600, 30, 2200), Vector3.new(40, 60, 40))
building("Manzana_Campus", "Bloque", Vector3.new(2800, 30, 2200), Vector3.new(40, 60, 40))
services.RunService = services.RunService or {
	IsStudio = function()
		return true
	end,
	Heartbeat = signal(),
}
local InteriorService = loadModule(S .. "InteriorService")
local PropertyService = loadModule(S .. "PropertyService")
local InteractService = loadModule(S .. "InteractService")
InteriorService.init()
PropertyService.init()
InteractService.init()
local casas, forSale, neighbor, ocio = {}, nil, nil, nil
for _, b in InteriorService.all() do
	if b.Kind == "Casa" then
		table.insert(casas, b)
	elseif b.Kind == "Ocio" then
		ocio = b
	end
end
check(#casas == 6 and ocio ~= nil, "se encuentran las casas y el local de ocio")
local mine
for _, b in casas do
	if Properties.isNeighborHome(Properties.unitKey(b.Key, 0)) then
		neighbor = neighbor or b
	elseif not mine then
		mine = b
	else
		forSale = forSale or b
	end
end
check(mine ~= nil and forSale ~= nil and neighbor ~= nil, "hay casas en venta y casas de vecinos")
local owner, ownerRoot, ownerHum = newPlayer(130, "Adulto", 50000)
local stranger, strangerRoot, strangerHum = newPlayer(131, "Adulto", 500)
local friend, friendRoot = newPlayer(132, "Adulto", 500)
owner.DisplayName, stranger.DisplayName, friend.DisplayName = "Dueña", "Desconocido", "Amiga"
for _, callback in loadedCallbacks do
	for _, p in { owner, stranger, friend } do
		pcall(callback, p, profiles[p])
	end
end
profiles[owner].Properties = {}
InteriorService.enter(owner, mine)
local inst = InteriorService.instance(mine, 0)
check(inst ~= nil and owner:GetAttribute("InteriorKey") == mine.Id .. ":0", "al entrar se monta la casa")
local buyPrompt
for _, d in inst.Room.Model:GetDescendants() do
	if d.ClassName == "ProximityPrompt" and d.ActionText == "Comprar vivienda" then
		buyPrompt = d
	end
end
check(buyPrompt ~= nil, "la casa en venta tiene su cartel de comprar")
buyPrompt.Triggered:Fire(owner)
check(PropertyService.access(owner, mine, 0) == "Owner" and PropertyService.access(stranger, mine, 0) == "Stranger", "comprada: es suya; para otro, casa ajena")
inst = InteriorService.instance(mine, 0)
local model = inst.Room.Model
local function partOf(use, pick)
	local found = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Use") == use then
			table.insert(found, d)
		end
	end
	table.sort(found, function(x, y)
		return x.Position.X < y.Position.X
	end)
	return found[pick or 1]
end
local function goNear(root, part)
	root.CFrame = CFrame.new(part.Position + Vector3.new(0, 0, 1.5))
end
local function fire(player, root, part)
	goNear(root, part)
	part:FindFirstChild("InteractPrompt").Triggered:Fire(player)
end
local promptsOk, nearOnly = true, true
for _, use in { "Sit", "TV", "Light", "Bed", "Fridge", "Tap", "Shower", "Door", "Wardrobe", "Window" } do
	local part = partOf(use)
	local prompt = part and part:FindFirstChild("InteractPrompt")
	if not prompt then
		promptsOk = false
		print("    (sin cartel: " .. use .. ")")
	elseif prompt.MaxActivationDistance > 9 then
		nearOnly = false
	end
end
check(promptsOk, "cada cosa tiene su cartel: sentarse, tele, luz, cama, nevera, grifo, ducha, puerta, armario, ventana")
check(nearOnly, "los carteles solo salen de cerca")
check(partOf("Tap"):FindFirstChild("InteractPrompt"):GetAttribute("NoGesture") == true and partOf("TV"):FindFirstChild("InteractPrompt"):GetAttribute("NoGesture") == nil, "los que tienen postura propia no hacen el gesto de alargar la mano")
check(partOf("Bed"):FindFirstChild("InteractPrompt").ActionText == "Dormir", "en una casa con dueño la cama es para dormir")
-- Tele
local tv = partOf("TV")
fire(owner, ownerRoot, tv)
check(tv:GetAttribute("On") == true and tv:GetAttribute("Channel") == 1 and tv:FindFirstChild("InteractPrompt").ActionText == "Apagar la tele", "la tele se enciende (canal 1)")
fire(owner, ownerRoot, tv)
check(tv:GetAttribute("On") == false and tv:FindFirstChild("InteractPrompt").ActionText == "Encender la tele", "y se apaga")
-- Luces
local switch
for _, d in model:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("Use") == "Light" and d:GetAttribute("Room") == "Salon" then
		switch = d
	end
end
local function salonLights()
	local on, off = 0, 0
	for _, d in model:GetDescendants() do
		if d:HasTag("RoomLight") and d:GetAttribute("Room") == "Salon" then
			local light = d:FindFirstChildOfClass("PointLight")
			if light and light.Enabled == false then
				off += 1
			else
				on += 1
			end
		end
	end
	return on, off
end
local on0 = salonLights()
fire(owner, ownerRoot, switch)
local on1, off1 = salonLights()
check(on0 > 0 and on1 == 0 and off1 == on0 and switch:GetAttribute("On") == false and switch:FindFirstChild("InteractPrompt").ActionText == "Encender la luz", "el interruptor apaga las luces del salón")
fire(stranger, strangerRoot, switch)
check((salonLights()) == on0, "encender la luz se puede hasta en casa ajena")
-- Puerta
local door = partOf("Door", 2)
local before = door.CFrame
local wasOpen = door:GetAttribute("Open")
fire(owner, ownerRoot, door)
check(door:GetAttribute("Open") == not wasOpen and door.CFrame ~= before, "la puerta gira en su bisagra")
-- Sentarse en el sofá
local sofaBase
for _, d in model:GetDescendants() do
	if d.Name == "SofaBase" then
		sofaBase = d
	end
end
fire(owner, ownerRoot, sofaBase)
check(ownerHum.SeatPart ~= nil and ownerHum.SeatPart.Parent.Name == "Sofa" and owner:GetAttribute("UsePose") == "Sofa", "se sienta en el sofá (postura de sofá)")
ownerHum.Sit = false
check(owner:GetAttribute("UsePose") == nil, "al levantarse se quita la postura")
-- Nevera: desde la universidad se come lo que hayas comprado y guardado (FridgeService)
local InventoryService = loadModule(S .. "InventoryService")
local FridgeService = loadModule(S .. "FridgeService")
local Fridge = loadModule(ROOT .. "/shared/Fridge")
FridgeService.init()
local fridge = partOf("Fridge")
table.clear(needsChanges)
clearInbox(owner)
fire(owner, ownerRoot, fridge)
check(#needsChanges == 0 and notified(owner, "vacía") and lastMessage(owner, "Fridge") ~= nil, "vacía: hay que comprar comida en el supermercado")
check(owner:GetAttribute("UsePose") == "Fridge", "postura de abrir la nevera")
local fridgeDoor
for _, d in fridge.Parent:GetDescendants() do
	if d.Name == "FridgeDoor" then
		fridgeDoor = d
	end
end
check(fridgeDoor:GetAttribute("Open") == true, "la puerta de la nevera se abre")
task.wait(0.3)
check(fridgeDoor:GetAttribute("Open") == false and owner:GetAttribute("UsePose") == nil, "y se cierra sola")
-- Compra en el supermercado (a la mochila) y la guarda
InventoryService.add(owner, "Pan", 3)
fire(owner, ownerRoot, fridge)
local R = remotes.Interact.OnServerEvent
R:Fire(owner, "Fridge", "StoreAll")
local fridgeKey = "casa:" .. mine.Key .. "#0"
local stock = profiles[owner].Fridges[fridgeKey]
check(stock ~= nil and stock.Pan == 3 and InventoryService.count(owner, "Pan") == 0, "guarda la compra en la nevera")
local panel = lastMessage(owner, "Fridge")
check(panel ~= nil and #panel[2].Inside == 1 and panel[2].Inside[1].Count == 3, "el panel enseña lo que hay dentro")
table.clear(needsChanges)
R:Fire(owner, "Fridge", "Eat", "Pan")
check(#needsChanges == 1 and needsChanges[1][2] > 0 and stock.Pan == 2, "comer gasta lo guardado")
R:Fire(owner, "Fridge", "Take", "Pan")
check(stock.Pan == 1 and InventoryService.count(owner, "Pan") == 1, "coger algo lo lleva a la mochila")
-- Se guarda con la partida (ida y vuelta por JSON, como en el DataStore)
local serde = require("@lune/serde")
local saved = serde.decode("json", serde.encode("json", profiles[owner].Fridges))
check(saved[fridgeKey] and saved[fridgeKey].Pan == 1, "lo de la nevera se guarda con la partida")
table.clear(needsChanges)
clearInbox(stranger)
fire(stranger, strangerRoot, fridge)
R:Fire(stranger, "Fridge", "Eat", "Pan")
check(#needsChanges == 0 and stock.Pan == 1 and notified(stranger, "No es tu casa"), "en casa ajena no se coge nada de su nevera")
-- Invitado (mismo grupo que el dueño): come de lo del dueño
owner:SetAttribute("GroupId", 77)
friend:SetAttribute("GroupId", 77)
check(PropertyService.access(friend, mine, 0) == "Guest", "alguien de tu grupo es invitado")
fire(friend, friendRoot, fridge)
R:Fire(friend, "Fridge", "Eat", "Pan")
check(#needsChanges == 1 and needsChanges[1][1] == friend and stock.Pan == nil, "un invitado come de lo que ha guardado el dueño")
local savedCooldown = Interact.Snack.Cooldown
-- La casa de tus padres (casa familiar): gratis y sin límite solo en la etapa del colegio
local family = fakeInstance("Model")
family.Name = "CasaFamiliar"
family:SetAttribute("HomeId", "Casa_Test")
family:AddTag("FamilyHome")
family.Parent = worldRoot
local oldFridge = fakeInstance("Part")
oldFridge.Name = "Fridge"
oldFridge.Size = Vector3.new(2.8, 7, 2.8)
oldFridge.CFrame = CFrame.new(-900, 3.5, -900)
oldFridge.Parent = family
InteractService.setupFamilyHome(family)
local famPrompt = oldFridge:FindFirstChild("InteractPrompt")
check(famPrompt ~= nil and famPrompt.ActionText == "Coger algo de comer", "la nevera de la casa familiar tiene su cartel")
local kid, kidRoot = newPlayer(133, "Nino", 0)
kid:SetAttribute("FamilyHomeId", "Casa_Test")
table.clear(needsChanges)
Interact.Snack.Cooldown = 0
for _ = 1, 5 do
	fire(kid, kidRoot, oldFridge)
end
check(#needsChanges == 5 and needsChanges[1][1] == kid and needsChanges[1][2] == Interact.Snack.Hunger and profiles[kid].Money == 0, "de niño comes gratis de la nevera de tus padres, las veces que quieras")
check(kid:GetAttribute("UsePose") == "Fridge", "cogiendo la comida de la nevera")
local teen, teenRoot = newPlayer(134, "Adolescente", 0)
teen:SetAttribute("FamilyHomeId", "Casa_Test")
fire(teen, teenRoot, oldFridge)
check(#needsChanges == 6 and needsChanges[6][1] == teen, "en el instituto, también")
local student, studentRoot = newPlayer(135, "AdultoJoven", 0)
student:SetAttribute("FamilyHomeId", "Casa_Test")
fire(student, studentRoot, oldFridge)
check(#needsChanges == 6 and notified(student, "Ya no vives con tus padres"), "desde la universidad, en casa de tus padres ya no hay comida gratis")
Interact.Snack.Cooldown = savedCooldown
table.clear(needsChanges)
fire(friend, friendRoot, oldFridge)
check(#needsChanges == 0, "la nevera de otra familia no es tuya")
check(Fridge.freeAtFamily("Nino") and Fridge.freeAtFamily("Adolescente") and not Fridge.freeAtFamily("AdultoJoven") and not Fridge.freeAtFamily("Adulto"), "gratis solo en la etapa del colegio")
table.clear(needsChanges)
-- Cama: el dueño duerme; un desconocido no puede
table.clear(needsChanges)
clearInbox(stranger)
local bed = partOf("Bed")
fire(stranger, strangerRoot, bed)
check(stranger:GetAttribute("UsePose") == nil and not stranger:GetAttribute("Sleeping") and #needsChanges == 0 and notified(stranger, "No es tu casa"), "no se puede dormir en la cama de un desconocido")
fire(owner, ownerRoot, bed)
check(owner:GetAttribute("UsePose") == "Lie" and ownerRoot.Anchored == true and ownerHum.PlatformStand == true, "el dueño se tumba en la cama")
check(owner:GetAttribute("Sleeping") == true, "y se duerme")
task.wait(0.3)
local slept = false
for _, change in needsChanges do
	if change[1] == owner and change[3] >= Interact.SleepEnergy then
		slept = true
	end
end
check(slept and owner:GetAttribute("Sleeping") == nil, "al despertar, energía al máximo")
remotes.Interact.OnServerEvent:Fire(owner, "Stop")
task.wait(0.6)
check(owner:GetAttribute("UsePose") == nil and ownerRoot.Anchored == false and ownerHum.PlatformStand == false, "saltar le levanta de la cama")
-- Grifo
local tap = partOf("Tap")
fire(owner, ownerRoot, tap)
local water = tap:FindFirstChild("Water")
check(tap:GetAttribute("Running") == true and water.Enabled == true and owner:GetAttribute("UsePose") == "Tap", "el grifo echa agua (y se lava las manos)")
task.wait(0.3)
check(tap:GetAttribute("Running") == false and water.Enabled == false, "el grifo se cierra solo")
-- Armario
local wardrobe = partOf("Wardrobe")
fire(owner, ownerRoot, wardrobe)
local opened = 0
for _, d in wardrobe.Parent:GetDescendants() do
	if d:GetAttribute("Hinge") and d:GetAttribute("Open") then
		opened += 1
	end
end
check(opened == 2, "el armario abre sus dos puertas")
-- Ducha y ventana: un desconocido no se ducha en tu casa, pero sí puede mirar por la ventana
fire(stranger, strangerRoot, partOf("Shower"))
check(stranger:GetAttribute("UsePose") == nil, "un desconocido no se ducha en tu casa")
fire(stranger, strangerRoot, partOf("Window"))
check(stranger:GetAttribute("UsePose") == "Window", "pero sí puede asomarse a la ventana")
remotes.Interact.OnServerEvent:Fire(stranger, "Stop")
-- En una casa en venta: te tumbas pero no duermes
InteriorService.enter(stranger, forSale)
local saleInst = InteriorService.instance(forSale, 0)
table.clear(needsChanges)
for _, d in saleInst.Room.Model:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("Use") == "Bed" then
		goNear(strangerRoot, d)
		check(d:FindFirstChild("InteractPrompt").ActionText == "Tumbarse", "en una casa en venta la cama dice «Tumbarse»")
		d:FindFirstChild("InteractPrompt").Triggered:Fire(stranger)
		break
	end
end
task.wait(0.3)
check(stranger:GetAttribute("UsePose") == "Lie" and not stranger:GetAttribute("Sleeping") and #needsChanges == 0, "en una casa en venta te tumbas, pero no duermes")
remotes.Interact.OnServerEvent:Fire(stranger, "Stop")
-- Vecinos: sus residentes están en los sitios libres
InteriorService.enter(friend, neighbor)
local neighborInst = InteriorService.instance(neighbor, 0)
local residents = 0
for _, d in neighborInst.Room.Model:GetChildren() do
	if d:GetAttribute("Resident") then
		residents += 1
	end
end
check(residents >= 1, "en las casas de vecinos hay vecinos")
-- Bar: la nevera de bebidas se paga
InteriorService.enter(stranger, ocio)
local bar = InteriorService.instance(ocio, 0)
local cooler
for _, d in bar.Room.Model:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("Use") == "Fridge" then
		cooler = d
	end
end
table.clear(needsChanges)
local money = profiles[stranger].Money
check(cooler:FindFirstChild("InteractPrompt").ActionText == "Comprar bebida", "en el bar, la nevera vende bebidas")
goNear(strangerRoot, cooler)
cooler:FindFirstChild("InteractPrompt").Triggered:Fire(stranger)
check(profiles[stranger].Money == money - Interact.Drink.Price and #needsChanges == 1, "la bebida se paga y quita la sed")
-- Piano del bar: sentarse y tocar
local piano
for _, d in bar.Room.Model:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("Use") == "Piano" then
		piano = d
	end
end
task.wait(0.3)
goNear(strangerRoot, piano)
piano:FindFirstChild("InteractPrompt").Triggered:Fire(stranger)
check(strangerHum.SeatPart ~= nil and stranger:GetAttribute("UsePose") == "Piano" and piano:GetAttribute("Playing") == true, "al piano: se sienta y toca")
strangerHum.Sit = false
check(piano:GetAttribute("Playing") == false and stranger:GetAttribute("UsePose") == nil, "al levantarse deja de sonar")

print("▶ Edificios de varias plantas: escalera, pasillos, puertas y dueños")
local Floors = loadModule(ROOT .. "/shared/Floors")
local tower, offices, residence
for _, b in InteriorService.all() do
	if b.Model.Parent.Name == "Manzana_Downtown" then
		tower = b
	elseif b.Model.Parent.Name == "Manzana_Towers" then
		offices = b
	elseif b.Residence then
		residence = b
	end
end
check(tower ~= nil and tower.Floors == 12 and InteriorService.isTower(tower), "el bloque del centro tiene 12 plantas y se sube por dentro")
check(offices ~= nil and offices.Upper == "Oficina" and residence ~= nil and residence.Upper == "Dorm", "hay oficinas y una residencia universitaria en el campus")
local walker, walkerRoot = newPlayer(140, "Adulto", 90000)
local visitor, visitorRoot = newPlayer(141, "Adulto", 500)
walker.DisplayName, visitor.DisplayName = "Paseante", "Visita"
for _, callback in loadedCallbacks do
	for _, p in { walker, visitor } do
		pcall(callback, p, profiles[p])
	end
end
profiles[walker].Properties = {}
InteriorService.enter(walker, tower)
check(walker:GetAttribute("InteriorKey") == tower.Id .. ":T", "al entrar se llega al portal del edificio")
local built = InteriorService.builtFloors(tower)
check(#built == 3 and built[1] == 0 and built[3] == 2, "solo se montan las plantas de cerca (0, 1 y 2)")
local towerInst = InteriorService.tower(tower)
local function floorModel(f)
	return towerInst.Room.Model:FindFirstChild("Planta_" .. f)
end
local function top(p)
	return p.CFrame.Position.Y + p.Size.Y / 2
end
-- La escalera: escalones de 0,75 como mucho 1 stud, descansillo y llega al suelo de la de arriba
local stairsOk, landings = true, true
for f = 0, 1 do
	local m = floorModel(f)
	local steps = {}
	local slab, nextSlab, mid
	for _, d in m:GetDescendants() do
		if d:GetAttribute("Step") then
			table.insert(steps, d)
		elseif d.Name == "FloorSlab" then
			slab = d
		elseif d.Name == "MidLanding" then
			mid = d
		end
	end
	for _, d in floorModel(f + 1):GetDescendants() do
		if d.Name == "FloorSlab" then
			nextSlab = d
		end
	end
	table.sort(steps, function(a, b)
		return a:GetAttribute("Step") < b:GetAttribute("Step")
	end)
	landings = landings and slab ~= nil and mid ~= nil and nextSlab ~= nil
	if #steps ~= 16 or not slab or not nextSlab then
		stairsOk = false
		continue
	end
	local last = top(slab)
	for i, s in steps do
		local h = top(s)
		if h - last > 1.0001 or h - last <= 0 then
			stairsOk = false
		end
		if i == 8 and math.abs(h - top(mid)) > 0.01 then
			stairsOk = false
		end
		last = h
	end
	if math.abs(last - top(nextSlab)) > 0.01 then
		stairsOk = false
	end
end
check(landings, "cada planta tiene rellano, descansillo y la de arriba su suelo")
check(stairsOk, "la escalera une las plantas: 16 escalones de 0,75 (≤ 1 stud) hasta el rellano de arriba")
local signs = 0
for _, d in floorModel(1):GetDescendants() do
	if d:GetAttribute("FloorLabel") == "Planta 1" then
		signs += 1
	end
end
check(signs >= 2, "el número de la planta en el rellano y en el pasillo")
-- Puertas: de 3 a 6 viviendas por planta, cada una con su nombre y su dueño
local labels, perFloorOk, mapsOk = {}, true, true
for f = 1, 11 do
	local units = Floors.units(tower.Key, tower.Kind, tower.Upper, f)
	if #units < 3 or #units > 6 then
		perFloorOk = false
	end
	for _, u in units do
		if labels[u.Label] then
			perFloorOk = false
		end
		labels[u.Label] = true
		local back = InteriorService.unitOf(tower, f, u.Letter)
		local occ = InteriorService.occupant(tower, u)
		if not back or back.Id ~= u.Id or not (occ.Type == "Owner" or occ.Type == "Neighbor" or occ.Type == "ForSale") then
			mapsOk = false
		end
	end
end
check(perFloorOk, "cada planta de viviendas tiene de 3 a 6 puertas, con nombres distintos (1ºA, 1ºB…)")
check(mapsOk, "cada puerta es una vivienda con su dueño (jugador, vecinos o en venta)")
local doors1 = {}
for _, d in floorModel(1):GetDescendants() do
	if d:HasTag("UnitDoor") then
		table.insert(doors1, d)
	end
end
check(#doors1 == #Floors.units(tower.Key, tower.Kind, tower.Upper, 1), "en el pasillo están todas las puertas de la planta")
-- Llamar, visitar, entrar y salir al rellano
local function doorWith(f, kind)
	for _, u in Floors.units(tower.Key, tower.Kind, tower.Upper, f) do
		if InteriorService.occupant(tower, u).Type == kind then
			for _, d in floorModel(f):GetDescendants() do
				if d:HasTag("UnitDoor") and d:GetAttribute("UnitId") == u.Id then
					return d, u
				end
			end
		end
	end
	return nil
end
local neighborDoor, neighborUnit
for f = 1, 2 do
	if not neighborDoor then
		neighborDoor, neighborUnit = doorWith(f, "Neighbor")
	end
end
if neighborDoor then
	clearInbox(walker)
	check(neighborDoor:FindFirstChild("DoorPrompt").ActionText == "Llamar", "en casa de los vecinos se llama")
	neighborDoor:FindFirstChild("DoorPrompt").Triggered:Fire(walker)
	task.wait(1)
	check(notified(walker, "Toc, toc"), "llamas y contestan (y a veces te dejan pasar)")
	if walker:GetAttribute("InteriorKey") ~= tower.Id .. ":T" then
		InteriorService.leave(walker)
	end
end
local saleDoor, saleUnit
for f = 1, 2 do
	if not saleDoor then
		saleDoor, saleUnit = doorWith(f, "ForSale")
	end
end
check(saleDoor ~= nil and saleDoor:FindFirstChild("DoorPrompt").ActionText == "Visitar", "las que están en venta se visitan")
saleDoor:FindFirstChild("DoorPrompt").Triggered:Fire(walker)
local saleFloor = saleDoor:GetAttribute("Floor")
check(walker:GetAttribute("InteriorKey") == tower.Id .. ":" .. saleUnit.Id, "al visitarla entras en esa vivienda (" .. saleUnit.Label .. ")")
check(saleDoor:GetAttribute("Open") == true, "la puerta se abre")
local flat = InteriorService.instance(tower, saleFloor, saleUnit.Letter)
local buyFlat
for _, d in flat.Room.Model:GetDescendants() do
	if d.ClassName == "ProximityPrompt" and d.ActionText == "Comprar vivienda" then
		buyFlat = d
	end
end
check(buyFlat ~= nil, "dentro está el cartel de SE VENDE")
buyFlat.Triggered:Fire(walker)
check(PropertyService.access(walker, tower, saleFloor, saleUnit.Letter) == "Owner" and profiles[walker].Properties[1].Letter == saleUnit.Letter, "comprada: el " .. saleUnit.Label .. " es suyo")
local plate = floorModel(saleFloor):FindFirstChild("UnitDoor_" .. saleUnit.Id)
local plateText = plate and plate:FindFirstChild("PlateText", true)
check(plateText ~= nil and string.find(plateText.Text, "Paseante", 1, true) ~= nil, "la placa de la puerta dice quién vive")
InteriorService.leave(walker)
check(walker:GetAttribute("InteriorKey") == tower.Id .. ":T" and walker:GetAttribute("TowerFloor") == saleFloor, "al salir se vuelve al pasillo de esa planta")
-- Un desconocido llama y nadie abre; alguien del grupo entra
local ownedDoor = floorModel(saleFloor):FindFirstChild("UnitDoor_" .. saleUnit.Id):FindFirstChild("DoorPanel")
InteriorService.enter(visitor, tower)
clearInbox(visitor)
visitorRoot.CFrame = CFrame.new(ownedDoor.Position)
ownedDoor:FindFirstChild("DoorPrompt").Triggered:Fire(visitor)
check(notified(visitor, "Nadie te abre") and visitor:GetAttribute("InteriorKey") == tower.Id .. ":T", "en la casa de otro jugador llamas y no entras")
walker:SetAttribute("GroupId", 91)
visitor:SetAttribute("GroupId", 91)
ownedDoor:FindFirstChild("DoorPrompt").Triggered:Fire(visitor)
check(visitor:GetAttribute("InteriorKey") == tower.Id .. ":" .. saleUnit.Id, "si es de tu grupo, pasas")
InteriorService.leave(visitor) -- al pasillo
InteriorService.leave(visitor) -- y a la calle
-- Subir: al ir por la escalera se montan las plantas de arriba y se quitan las de abajo
local origin = towerInst.Tower.Origin.Position
walkerRoot.CFrame = CFrame.new(origin + Vector3.new(0, 6 * Floors.Height + 3, 0))
InteriorService.stepTowers()
local nowBuilt, parts = InteriorService.builtFloors(tower)
check(walker:GetAttribute("TowerFloor") == 6, "sabe en qué planta estás por la altura")
local nearOk = nowBuilt[1] >= 3 and nowBuilt[#nowBuilt] <= 9
for f = 4, 8 do
	nearOk = nearOk and table.find(nowBuilt, f) ~= nil
end
check(nearOk and not table.find(nowBuilt, 0), ("en la 6ª: montadas de la 4ª a la 8ª (y las de abajo, quitadas): %s"):format(table.concat(nowBuilt, ",")))
local perFloor = math.floor(parts / #nowBuilt)
check(parts < 1500, ("piezas del edificio de 12 plantas: %d (unas %d por planta, tope 1500)"):format(parts, perFloor))
-- La ascensor lleva a cualquier planta (y monta las de alrededor)
walker:SetAttribute("ElevatorBuilding", tower.Id)
remotes.Interior.OnServerEvent:Fire(walker, "Floor", 11)
local after = InteriorService.builtFloors(tower)
check(walker:GetAttribute("TowerFloor") == 11 and table.find(after, 11) ~= nil and table.find(after, 9) ~= nil, "el ascensor te deja en la 11ª (y se monta alrededor)")
InteriorService.leave(walker)
check(walker:GetAttribute("InteriorKey") == nil, "desde el portal se sale a la calle")
-- Oficinas: abiertas en horario
local officeFloor1
InteriorService.goTo(visitor, offices, 1)
officeFloor1 = InteriorService.tower(offices).Room.Model:FindFirstChild("Planta_1")
local companyDoor
for _, d in officeFloor1:GetDescendants() do
	if d:HasTag("UnitDoor") then
		local u = InteriorService.unitOf(offices, 1, d:GetAttribute("Letter"))
		if InteriorService.occupant(offices, u).Type == "Company" then
			companyDoor = d
		end
	end
end
if companyDoor then
	services.Lighting.ClockTime = 22
	clearInbox(visitor)
	companyDoor:FindFirstChild("DoorPrompt").Triggered:Fire(visitor)
	check(notified(visitor, "cerrado") and visitor:GetAttribute("InteriorKey") == offices.Id .. ":T", "de noche la oficina está cerrada")
	services.Lighting.ClockTime = 10
	companyDoor:FindFirstChild("DoorPrompt").Triggered:Fire(visitor)
	check(string.find(visitor:GetAttribute("InteriorKey") or "", "^" .. offices.Id .. ":1") ~= nil, "en horario, entras en la oficina")
	services.Lighting.ClockTime = 21
end
-- Casa de dos plantas: escalera por dentro y arriba pasillo con puertas
local Interiors2 = loadModule(ROOT .. "/server/World/Interiors")
local house = Interiors2.Casa(lab, CFrame.new(0, 5000, 0), { Seed = "Casa_2_2:0", Floors = 2 })
local hs = {}
local doors2 = 0
for _, d in house.Model:GetDescendants() do
	if d:GetAttribute("Step") then
		table.insert(hs, d)
	elseif d:GetAttribute("Use") == "Door" then
		doors2 += 1
	end
end
table.sort(hs, function(a, b)
	return a:GetAttribute("Step") < b:GetAttribute("Step")
end)
local houseOk = #hs == 16
local lastY = 0
for _, s in hs do
	local h = top(s) - 5000
	houseOk = houseOk and h - lastY <= 1.0001
	lastY = h
end
check(houseOk and math.abs(lastY - (house.H + 1)) < 0.01, "casa de dos plantas: escalera de escalones ≤ 1 stud hasta la planta de arriba")
check(doors2 == 6 and house.Model:GetAttribute("Storeys") == 2, "arriba: pasillo y tres habitaciones con puerta (más las tres de abajo)")
house.Model:Destroy()

print("▶ Residencia universitaria: habitación y nevera propia")
local ResidenceService = loadModule(S .. "ResidenceService")
local uni, uniRoot = newPlayer(150, "AdultoJoven", 300)
uni.DisplayName = "Estudiante"
ResidenceService.assign(uni)
local dormKey = uni:GetAttribute("DormUnit")
check(type(dormKey) == "string" and string.find(dormKey, residence.Key, 1, true) == 1, "en la universidad te dan una habitación en la residencia")
local kidNo = newPlayer(151, "Nino", 0)
ResidenceService.assign(kidNo)
check(kidNo:GetAttribute("DormUnit") == nil, "de niño no")
local singles = 0
for id = 1000, 1400 do
	local room = ResidenceService.roomFor(id)
	if room and room.Single then
		singles += 1
	end
end
check(singles > 40 and singles < 200, ("más o menos una de cada cuatro, individual (%d de 401)"):format(singles))
local _, dormUnit = string.match(dormKey, "^(.+)#(%w+)$")
local dFloor, dLetter = Floors.parseUnit(dormUnit)
InteriorService.goToUnit(uni, residence, dFloor, dLetter)
check(uni:GetAttribute("InteriorKey") == residence.Id .. ":" .. dormUnit, "entra en su habitación")
local dorm = InteriorService.instance(residence, dFloor, dLetter)
local dormFridge, dormBeds = nil, 0
for _, d in dorm.Room.Model:GetDescendants() do
	if d:IsA("BasePart") and d:GetAttribute("Use") == "Fridge" then
		dormFridge = d
	elseif d:IsA("BasePart") and d:GetAttribute("Use") == "Bed" then
		dormBeds += 1
	end
end
check(dormFridge ~= nil and dormBeds == (if dorm.Room.Model:GetAttribute("Single") then 1 else 2), "tiene nevera y su cama (dos si es compartida)")
InventoryService.add(uni, "Pan", 2)
uniRoot.CFrame = CFrame.new(dormFridge.Position + Vector3.new(0, 0, 1.5))
dormFridge:FindFirstChild("InteractPrompt").Triggered:Fire(uni)
remotes.Interact.OnServerEvent:Fire(uni, "Fridge", "StoreAll")
table.clear(needsChanges)
remotes.Interact.OnServerEvent:Fire(uni, "Fridge", "Eat", "Pan")
local dormStock = profiles[uni].Fridges["residencia:" .. dormKey]
check(dormStock ~= nil and dormStock.Pan == 1 and #needsChanges == 1, "guarda la compra en la nevera de la residencia y come de ella")
local otherStudent, otherRoot = newPlayer(152, "AdultoJoven", 0)
otherStudent:SetAttribute("DormUnit", "otra")
otherRoot.CFrame = uniRoot.CFrame
table.clear(needsChanges)
dormFridge:FindFirstChild("InteractPrompt").Triggered:Fire(otherStudent)
remotes.Interact.OnServerEvent:Fire(otherStudent, "Fridge", "Eat", "Pan")
check(#needsChanges == 0 and dormStock.Pan == 1, "otro estudiante no coge de tu nevera")
Config.SleepSeconds = savedSleep
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
