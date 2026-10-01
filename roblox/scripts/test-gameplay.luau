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
	-- Un modelo se mueve con su PrimaryPart, o con su HumanoidRootPart (personajes)
	local primary = self.__props.PrimaryPart
	if primary then
		primary.CFrame = cf
		return
	end
	for _, child in self.__children do
		if child.__props.Name == "HumanoidRootPart" then
			child.CFrame = cf
			return
		end
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
	elseif key == "Position" and typeof(value) == "Vector3" then -- (en la interfaz, Position es un UDim2)
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
function collection:AddTag(instance, tag)
	instance:AddTag(tag)
end
function collection:RemoveTag(instance, tag)
	instance.__tags[tag] = nil
end
function collection:HasTag(instance, tag)
	return instance:HasTag(tag)
end

local function remote()
	local r = { OnServerEvent = signal() }
	function r:FireClient(player, ...)
		table.insert(player.Inbox, table.pack(...))
	end
	return r
end
-- Bocadillos (Npc.say -> remoto Speech a los jugadores cercanos): se apuntan aquí (y a quién van)
local speechLog = {}
local speechTo = {}
local speechRemote = {}
function speechRemote:FireAllClients(payload)
	table.insert(speechLog, payload)
end
function speechRemote:FireClient(player, payload)
	if speechLog[#speechLog] ~= payload then
		table.insert(speechLog, payload)
	end
	speechTo[payload] = speechTo[payload] or {}
	speechTo[payload][player] = true
end
local remotes = {
	Speech = speechRemote,
	Notify = remote(),
	Housing = remote(),
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
	Flight = remote(),
	Aviation = remote(),
	Rail = remote(),
	Bus = remote(),
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
	-- (SceneService de verdad, para llevar al jugador de un sitio a otro: sin caminos en la prueba)
	PathfindingService = {
		CreatePath = function()
			error("sin caminos en la prueba")
		end,
	},
	RunService = {
		Heartbeat = signal(),
		IsStudio = function()
			return false
		end,
	},
	-- (lo que se quita solo al rato: en la prueba, al momento)
	Debris = {
		AddItem = function(_, item)
			item:Destroy()
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
Gameplay.ExitCooldown = 0.3 -- (lo que tarda en poder volver a subirse después de bajarse)

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
task.delay(480, function()
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
check(kid:GetAttribute("Riding") == "Monopatin", "un niño ya puede coger el monopatín público (conducir: desde niño)")
remotes.Vehicle.OnServerEvent:Fire(kid, "Dismount")
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
check(adult:GetAttribute("Riding") == "Coche" and notified(adult, "sin el Carnet de coche"), "sin carnet también puede conducir su coche (con aviso: si le ve la policía, le para)")
check(VehicleService.drivingOffence(adult) == "SinCarnet", "conducir el coche sin carnet es «Conducir sin carnet»")
remotes.Vehicle.OnServerEvent:Fire(adult, "Dismount")
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
task.wait(Gameplay.ExitCooldown + 0.05) -- (se acaban de bajar: esperan un momento para volver a subir)
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
	task.wait(Gameplay.ExitCooldown + 0.05)
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
print("▶ Bajarse siempre a la primera (conductor y pasajero, en marcha, sin volver a sentarse)")
do
	local floor = part("Street", CFrame.new(0, -0.5, 0))
	local oldRaycast = Fake.Raycast
	Fake.Raycast = function(_, origin)
		return { Position = Vector3.new(origin.X, 0, origin.Z), Instance = floor, Normal = Vector3.new(0, 1, 0), Material = Enum.Material.Concrete }
	end
	local function exitedMessage(player)
		local m = lastMessage(player, "Exited")
		return m ~= nil and type(m[2]) == "table" and typeof(m[2].CFrame) == "CFrame"
	end
	local function welds(seat)
		local n = 0
		for _, c in seat:GetChildren() do
			if c.Name == "SeatWeld" then
				n += 1
			end
		end
		return n
	end
	local driver, driverRoot, driverHum = newPlayer(31, "AdultoJoven", 20000)
	profiles[driver].Licenses = { B = true }
	remotes.Vehicle.OnServerEvent:Fire(driver, "Buy", "Coche")
	remotes.Vehicle.OnServerEvent:Fire(driver, "Spawn", "Coche")
	local car
	for _, m in worldRoot.Rides:GetChildren() do
		if m:GetAttribute("OwnerId") == driver.UserId then
			car = m
		end
	end
	local seat = car:FindFirstChild("DriverSeat")
	check(driver:GetAttribute("Riding") == "Coche" and driverHum.SeatPart == seat, "se sube a su coche")
	-- A toda velocidad: una pulsación y fuera; el coche se para y se queda aparcado
	car.PrimaryPart.Anchored = false
	car.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, -70)
	clearInbox(driver)
	remotes.Vehicle.OnServerEvent:Fire(driver, "Dismount")
	local rel = car.PrimaryPart.CFrame:PointToObjectSpace(driverRoot.Position)
	check(driver:GetAttribute("Riding") == nil and driverHum.SeatPart == nil and welds(seat) == 0 and seat.Occupant == nil, "una pulsación le baja aunque vaya a toda velocidad (sin soldadura en el asiento)")
	check(car.PrimaryPart.Anchored and car.PrimaryPart.AssemblyLinearVelocity.Magnitude == 0, "el coche frena en seco y se queda aparcado")
	check(rel.X < -3 and driverRoot.Position.Y > 1, "queda de pie junto a la puerta del conductor (fuera de la carrocería)")
	check(exitedMessage(driver), "su ordenador recibe dónde dejarle (se levanta él también, sin esperar)")
	-- Justo después: el cartel de conducir no le vuelve a sentar
	promptOf(car, "Conducir").Triggered:Fire(driver)
	check(driver:GetAttribute("Riding") == nil and driverHum.SeatPart == nil, "justo después de bajarse, nada le vuelve a sentar (ni el cartel)")
	task.wait(Gameplay.ExitCooldown + 0.05)
	promptOf(car, "Conducir").Triggered:Fire(driver)
	check(driver:GetAttribute("Riding") == "Coche", "un momento después ya puede volver a subir")
	-- Con dos soldaduras (algo raro que pasa a veces): se quitan todas
	local extra = fakeInstance("Weld")
	extra.Name = "SeatWeld"
	extra.Parent = seat
	driverHum.Sit = false -- (saltar)
	check(driver:GetAttribute("Riding") == nil and welds(seat) == 0, "saltar también le baja, y no queda ninguna soldadura")
	-- Sentado en un vehículo sin que el servidor lo sepa: «Bajarse» le saca igual
	task.wait(Gameplay.ExitCooldown + 0.05)
	local back
	for _, c in car:GetChildren() do
		if c.ClassName == "Seat" and c:GetAttribute("Label") == "Subir detrás" then
			back = c
			break
		end
	end
	back:Sit(driverHum)
	clearInbox(driver)
	remotes.Vehicle.OnServerEvent:Fire(driver, "Dismount")
	rel = car.PrimaryPart.CFrame:PointToObjectSpace(driverRoot.Position)
	check(driverHum.SeatPart == nil and welds(back) == 0 and back.Occupant == nil and math.abs(rel.X) > 3, "sentado sin que el servidor lo sepa: «Bajarse» le saca igual y le deja a su lado")
	check(exitedMessage(driver), "y su ordenador también se levanta")
	-- Sin ir sentado en nada: contesta igual (el ordenador se asegura de que está de pie)
	clearInbox(driver)
	remotes.Vehicle.OnServerEvent:Fire(driver, "Dismount")
	check(lastMessage(driver, "Exited") ~= nil, "«Bajarse» siempre tiene respuesta")
	-- Pasajero con el coche en marcha
	task.wait(Gameplay.ExitCooldown + 0.05)
	local rider, riderRoot, riderHum = newPlayer(32, "Adolescente", 0)
	promptOf(car, "Subir de copiloto").Triggered:Fire(rider)
	promptOf(car, "Conducir").Triggered:Fire(driver)
	check(rider:GetAttribute("Passenger") == "Coche" and driver:GetAttribute("Riding") == "Coche", "conductor y copiloto dentro")
	car.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, -50)
	local riderSeat = riderHum.SeatPart
	remotes.Vehicle.OnServerEvent:Fire(rider, "Dismount")
	rel = car.PrimaryPart.CFrame:PointToObjectSpace(riderRoot.Position)
	check(rider:GetAttribute("Passenger") == nil and riderHum.SeatPart == nil and welds(riderSeat) == 0 and rel.X > 3, "el copiloto se baja a la primera, por su lado, con el coche en marcha")
	promptOf(car, "Subir de copiloto").Triggered:Fire(rider)
	check(rider:GetAttribute("Passenger") == nil, "y no se vuelve a sentar sin querer")
	remotes.Vehicle.OnServerEvent:Fire(driver, "Dismount")
	-- El vehículo desaparece con él dentro (lo retira otro sistema): se baja igual, no se queda
	-- «montado» a pie (con la velocidad del coche, sin poder correr y conduciendo para la policía)
	task.wait(Gameplay.ExitCooldown + 0.05)
	promptOf(car, "Conducir").Triggered:Fire(driver)
	check(driver:GetAttribute("Riding") == "Coche", "vuelve a subir a su coche")
	clearInbox(driver)
	car:Destroy() -- (las pruebas de después buscan «el» coche aparcado)
	check(driver:GetAttribute("Riding") == nil and driver:GetAttribute("VehicleSpeed") == nil and VehicleService.ridingKind(driver) == nil and VehicleService.drivingOffence(driver) == nil, "si el coche desaparece con él dentro, se baja (no se queda «montado» a pie)")
	check(driverHum.SeatPart == nil and lastMessage(driver, "Exited") ~= nil, "y su ordenador también se levanta")
	-- Llevarle a otro sitio (cárcel, juzgado, a casa, una escena) yendo al volante o de pasajero:
	-- se baja antes (si no, se llevaría el vehículo con él o se quedaría soldado al asiento)
	do
		local Scene = loadModule(S .. "SceneService")
		task.wait(Gameplay.ExitCooldown + 0.05)
		remotes.Vehicle.OnServerEvent:Fire(driver, "Spawn", "Coche")
		local own
		for _, m in worldRoot.Rides:GetChildren() do
			if m:GetAttribute("OwnerId") == driver.UserId then
				own = m
			end
		end
		local rider2, _, rider2Hum = newPlayer(33, "Adolescente", 0)
		promptOf(own, "Subir de copiloto").Triggered:Fire(rider2)
		check(driver:GetAttribute("Riding") == "Coche" and rider2:GetAttribute("Passenger") == "Coche", "conductor y copiloto dentro antes del viaje")
		local before = own.PrimaryPart.CFrame
		Scene.teleportTo(driver, Vector3.new(900, 0, 900))
		Scene.teleportTo(rider2, Vector3.new(-900, 0, 900))
		check(driver:GetAttribute("Riding") == nil and driverHum.SeatPart == nil and VehicleService.ridingKind(driver) == nil, "al llevarle a otro sitio, primero se baja del coche")
		check(rider2:GetAttribute("Passenger") == nil and rider2Hum.SeatPart == nil, "y el copiloto también")
		check((own.PrimaryPart.CFrame.Position - before.Position).Magnitude < 12 and (driverRoot.Position - Vector3.new(900, 0, 900)).Magnitude < 10, "el coche se queda donde estaba y él llega solo")
		own:Destroy()
		-- Quién te sigue: solo los acompañantes de la misión que juegas, y solo a pie y en la calle
		local walker2 = newPlayer(34, "Nino", 0)
		walker2:SetAttribute("StoryFocus", nil)
		check(not Scene._followsNow(walker2, "Loco_Nino") and Scene._followsNow(walker2, nil), "sin ninguna misión en juego (horario de cole), no te sigue ningún acompañante")
		walker2:SetAttribute("StoryFocus", "Loco_Nino")
		check(Scene._followsNow(walker2, "Loco_Nino") and not Scene._followsNow(walker2, "Cole04_Malotes"), "te sigue el acompañante de la misión que juegas, y no los de las demás")
		walker2:SetAttribute("InteriorKey", "casa")
		check(not Scene._followsNow(walker2, "Loco_Nino"), "dentro de un edificio no te sigue nadie")
		walker2:SetAttribute("InteriorKey", nil)
		walker2:SetAttribute("Riding", "Coche")
		check(not Scene._followsNow(walker2, "Loco_Nino"), "yendo en coche (o en bici, autobús, metro) no te sigue nadie")
		walker2:SetAttribute("Riding", nil)
	end
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
-- El NPC de servicio que está atendiendo (el que se retira se aparta andando y lleva Leaving)
local function servingNpc(name: string)
	for _, c in worldRoot.RestaurantLife:GetChildren() do
		if c.Name == name and not c:GetAttribute("Leaving") then
			return c
		end
	end
	return nil
end
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
check(barman:GetAttribute("Job") == nil and servingNpc("Npc_Camarero") == nil, "deja el trabajo y el NPC se va")
do
	local leaving = worldRoot.RestaurantLife:FindFirstChild("Npc_Camarero")
	check(leaving == nil or (leaving:GetAttribute("Leaving") == true and leaving:GetAttribute("Work") == nil), "al cerrar, el camarero NPC deja la bandeja y se va andando (no se esfuma de golpe)")
end
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
local said = customer:GetAttribute("Says") -- Npc.say: el bocadillo lo dibuja cada cliente (UI/SpeechBubbles)
check(said ~= nil and string.find(said, "Quiero", 1, true) ~= nil, "el cliente dice lo que quiere")
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
check(servingNpc("Npc_Barman") == nil and servingNpc("Npc_Camarero") == nil, "con dos jugadores no hay NPC de servicio (el que había se retira)")
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
said = customer2:GetAttribute("Says")
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
check(servingNpc("Npc_Camarero") ~= nil, "si el camarero se va, entra un camarero NPC")

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
local shopperBefore = profiles[shopper].Money
remotes.Supermarket.OnServerEvent:Fire(shopper, "Pay", receipt2[2])
-- (con un cliente jugador, el cajero no gana más del 60 % de lo que pagó: si no, dos amigos se
-- hacían ricos comprándose pan el uno al otro)
local shopperPaid = shopperBefore - profiles[shopper].Money
local cashierPay = math.min(Groceries.Jobs.Cajero.PerCustomer + 2 * Groceries.Jobs.Cajero.PerItem, math.max(1, math.floor(shopperPaid * 0.6)))
check(shopperPaid > 0 and profiles[cashier].Money == cashierBefore + cashierPay, "el cajero cobra por cliente y por producto (sin pasar de lo que paga el cliente)")
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
check(profiles[barista].Money == baristaBefore + math.min(J.PerOrder + 5 * J.PerStep + J.TipFast, math.max(1, math.floor(price * 0.6))), "el barista cobra por pedido, por paso y propina (sin pasar de lo que paga el cliente)")

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
;(function() -- (en una función: sus variables no cuentan para el límite de locales del archivo)
	print("▶ Autobuses urbanos: líneas, paradas, paneles de llegada, pasajeros y conductor")
	services.RunService = services.RunService or { Heartbeat = signal() }
	local ambient = fakeInstance("Folder")
	local roadsFolder = fakeInstance("Folder")
	roadsFolder.Name = "Roads"
	roadsFolder.Parent = ambient
	services.ReplicatedStorage.Ambient = ambient
	local roadCount = 0
	local function road(a, b, width, kind)
		roadCount += 1
		local c = fakeInstance("Configuration")
		c.Name = "Road" .. roadCount
		c:SetAttribute("A", a)
		c:SetAttribute("B", b)
		c:SetAttribute("Width", width or 24)
		c:SetAttribute("Kind", kind)
		c.Parent = roadsFolder
		return c
	end
	-- Las calles de verdad de Valmar, en el mismo orden que las publica el servidor
	local BusLinesMod = loadModule(ROOT .. "/shared/BusLines")
	-- (la prueba usa un Region de mentira: para las calles se carga un momento el de verdad)
	local regionPath = ROOT .. "/server/World/Region"
	local fakeRegion = mocks[regionPath]
	mocks[regionPath] = nil
	local cityRoads = loadModule(ROOT .. "/server/World/Kit/BusStops").roads()
	mocks[regionPath] = fakeRegion
	cache[regionPath] = nil
	local realRoads = {}
	for _, r in cityRoads do
		table.insert(realRoads, road(r.A, r.B, r.Width, r.Kind))
	end
	local centroStop = part("TravelPoint", CFrame.new(200, 2, 1985), { "TravelStop" }, { Town = "Valmar Centro" })
	local BusService = loadModule(S .. "BusService")
	BusService.init()
	waitFor(function()
		return BusService.isReady()
	end, 120, "la red de autobuses")
	local busLines = BusService.lines()
	local signs = {}
	for _, d in worldRoot:GetDescendants() do
		if d:HasTag("BusStop") then
			signs[d:GetAttribute("StopId")] = d
		end
	end
	local signCount = 0
	for _ in signs do
		signCount += 1
	end
	check(#busLines >= 5 and signCount >= 40, ("%d líneas y %d paradas con su marquesina (se construyen si el mapa no las trae)"):format(#busLines, signCount))
	local onRoute = true
	for _, line in busLines do
		for _, stop in line.Stops do
			local point = stop.Sign and stop.Sign:GetAttribute("StopPoint")
			local p = BusLinesMod.pointAt(line.Plan, stop.S)
			onRoute = onRoute and typeof(point) == "Vector3" and (Vector3.new(p.X, 0, p.Z) - Vector3.new(point.X, 0, point.Z)).Magnitude < 3
		end
	end
	check(onRoute, "cada parada de cada línea está en su recorrido (el autobús para junto a la marquesina)")
	local allBuses = BusService.buses()
	local expected = 0
	for _, line in busLines do
		expected += line.Def.Buses
	end
	local noDriver = #allBuses == expected
	for _, bus in allBuses do
		noDriver = noDriver and bus.Driver == nil and bus.Model:FindFirstChild("BusDriverNpc") ~= nil
	end
	check(noDriver and #worldRoot:FindFirstChild("Buses"):GetChildren() == expected, ("salen %d autobuses con conductor del juego (sin ningún conductor jugador)"):format(expected))
	local before = {}
	for _, bus in allBuses do
		before[bus] = bus.S
	end
	for _ = 1, 50 do
		services.RunService.Heartbeat:Fire(0.1)
	end
	local moving = true
	for _, bus in allBuses do
		moving = moving and (bus.S ~= before[bus] or bus.DoorsOpen)
	end
	check(moving, "circulan solos por sus líneas")

	-- Un autobús de la L1 llega a una parada y abre las puertas
	local l1 = BusService.lineOf("L1")
	local function step(times, until_)
		for _ = 1, times do
			services.RunService.Heartbeat:Fire(0.1)
			if until_ and until_() then
				return true
			end
		end
		return false
	end
	local openBus = nil
	step(4000, function()
		for _, bus in allBuses do
			if bus.Line == l1 and bus.DoorsOpen and bus.AtStop then
				openBus = bus
				return true
			end
		end
		return false
	end)
	check(openBus ~= nil and openBus.Model:GetAttribute("CurrentStop") ~= nil and openBus.Model:GetAttribute("DoorsOpen") == true, "un autobús de la L1 para en una parada y abre las puertas")
	local boardStop = openBus.Line.Stops[openBus.AtStop]
	local boardSign = boardStop.Sign
	services.RunService.Heartbeat:Fire(2) -- (se publican los paneles)
	local stopPromptObj = promptOf(boardSign, nil)
	check(stopPromptObj ~= nil and stopPromptObj.ActionText == "Subir al bus (L1)", "en la parada, el cartel del poste dice «Subir al bus (L1)»")

	-- Un niño sube gratis desde la parada, pide bajar en la próxima y baja en la acera
	local kid, kidRoot, kidHumanoid = newPlayer(60, "Nino", 0)
	moveTo(kidRoot, boardSign.Position + Vector3.new(0, -8, 0))
	stopPromptObj.Triggered:Fire(kid)
	check(kidHumanoid.SeatPart ~= nil and kidHumanoid.SeatPart.Name == "PassengerSeat" and kidHumanoid.SeatPart:IsDescendantOf(openBus.Model), "un niño sube al autobús desde la parada y se sienta")
	check(profiles[kid].Money == 0 and notified(kid, "gratis"), "los niños viajan gratis")
	check(kid:GetAttribute("BusLine") == "L1", "el pasajero sabe en qué línea va (panel del autobús)")
	local teen, teenRoot, teenHumanoid = newPlayer(61, "Adolescente", 10)
	moveTo(teenRoot, boardSign.Position + Vector3.new(0, -8, 0))
	promptOf(openBus.Model, "Subir al bus (L1)").Triggered:Fire(teen)
	check(teenHumanoid.SeatPart ~= nil and profiles[teen].Money == 10 - Gameplay.Bus.Fares.Adolescente, "un adolescente sube por la puerta y paga medio billete")
	local broke, brokeRoot, brokeHumanoid = newPlayer(41, "Adulto", 0)
	moveTo(brokeRoot, boardSign.Position + Vector3.new(0, -8, 0))
	stopPromptObj.Triggered:Fire(broke)
	check(brokeHumanoid.SeatPart == nil and notified(broke, "billete"), "un adulto sin dinero no puede subir")
	local rider, riderRoot, riderHumanoid = newPlayer(40, "Adulto", 10)
	moveTo(riderRoot, boardSign.Position + Vector3.new(0, -8, 0))
	stopPromptObj.Triggered:Fire(rider)
	check(riderHumanoid.SeatPart ~= nil and profiles[rider].Money == 10 - Gameplay.Bus.Fare, "un adulto paga el billete entero")
	local far, farRoot, farHumanoid = newPlayer(42, "Adulto", 10)
	moveTo(farRoot, boardSign.Position + Vector3.new(300, -8, 0))
	stopPromptObj.Triggered:Fire(far)
	check(farHumanoid.SeatPart == nil and profiles[far].Money == 10, "desde lejos no se puede subir")
	moveTo(brokeRoot, Vector3.new(9000, 0, 9000))
	moveTo(farRoot, Vector3.new(9000, 0, 9000))

	-- El autobús arranca (espera un poco si hay alguien en la parada)
	step(400, function()
		return not openBus.DoorsOpen
	end)
	check(not openBus.DoorsOpen and openBus.AtStop == nil, "cierra las puertas y sigue su ruta")
	-- Saltar con el autobús en marcha: vuelves a tu asiento y se pide la parada
	teenRoot.CFrame = teenHumanoid.SeatPart.CFrame -- (sentado, el personaje va pegado al asiento)
	teenHumanoid.Sit = false
	task.wait(0.05)
	check(teenHumanoid.SeatPart ~= nil and openBus.Model:GetAttribute("StopRequested") == true, "si saltas en marcha no te caes: vuelves al asiento y se pide parada")
	remotes.Bus.OnServerEvent:Fire(kid, "Request")
	check(openBus.Model:GetAttribute("StopRequested") == true and notified(kid, "Parada solicitada"), "«Bajar en la próxima»: parada solicitada (timbre)")

	-- El panel de la próxima parada: el tiempo baja a medida que se acerca
	local nextStop = openBus.Line.Stops[openBus.NextStop]
	local function etaAt(stopId, lineId)
		local best = nil
		for _, a in BusService.arrivals()[stopId] or {} do
			if a.Line == lineId and (best == nil or a.Seconds < best) then
				best = a.Seconds
			end
		end
		return best
	end
	local eta1 = etaAt(nextStop.Id, "L1")
	step(30)
	local eta2 = etaAt(nextStop.Id, "L1")
	check(eta1 ~= nil and eta2 ~= nil and eta2 < eta1, ("el tiempo de llegada baja a medida que se acerca (%s → %s s)"):format(tostring(eta1 and math.floor(eta1)), tostring(eta2 and math.floor(eta2))))
	services.RunService.Heartbeat:Fire(2)
	local boardRows = BusLinesMod.decodeBoard(nextStop.Sign:GetAttribute("Board"))
	local hasL1 = false
	for _, a in boardRows do
		hasL1 = hasL1 or a.Line == "L1"
	end
	check(hasL1 and string.find(promptOf(nextStop.Sign, nil).ObjectText, "L", 1, true) ~= nil, "el panel de la parada y su cartel dicen cuánto falta: " .. (if boardRows[1] then BusLinesMod.boardText(boardRows[1]) else "(vacío)"))

	-- Llega a la siguiente parada: el niño y el adolescente bajan en la acera, junto a la marquesina
	step(4000, function()
		return openBus.DoorsOpen and openBus.AtStop ~= nil
	end)
	task.wait(0.05)
	local exitStop = openBus.Line.Stops[openBus.AtStop]
	check(exitStop.Id == nextStop.Id, "para en la siguiente parada")
	local kidPos = kidRoot.CFrame.Position
	local signPos = exitStop.Sign.Position
	check(kidHumanoid.SeatPart == nil and kid:GetAttribute("BusLine") == nil and notified(kid, "Has bajado"), "el niño baja en la parada que pidió")
	local stopInfo = exitStop.Info
	local across = (Vector3.new(kidPos.X, 0, kidPos.Z) - stopInfo.Center):Dot(stopInfo.Right)
	check((Vector3.new(kidPos.X, 0, kidPos.Z) - Vector3.new(signPos.X, 0, signPos.Z)).Magnitude < 30 and across > stopInfo.Width / 2 and across < stopInfo.Width / 2 + stopInfo.Walk and math.abs(kidPos.Y - 4) < 0.5, "y aparece en la acera, al lado de la marquesina (no en la calzada)")
	check(teenHumanoid.SeatPart == nil, "el que saltó en marcha también baja en esta parada")
	check(riderHumanoid.SeatPart ~= nil, "quien no pidió parada sigue sentado")
	riderHumanoid.Sit = false
	task.wait(0.05)
	check(riderHumanoid.SeatPart == nil, "con las puertas abiertas, saltando se baja")
	for _, p in { kid, teen, rider } do
		p.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(9000, 3, 9000)
	end

	-- Oficio de conductor: con la red en marcha, un jugador conduce su autobús en la línea más cercana
	promptOf(centroStop, "🚌 Trabajar de conductor").Triggered:Fire(broke)
	check(broke:GetAttribute("Job") == nil and notified(broke, "carnet"), "sin carnet no se puede ser conductor")
	local driverMoney = profiles[adult].Money
	moveTo(adultRoot, Vector3.new(0, 0, 600))
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
	check(#BusService.buses() == expected + 1, "los autobuses del juego siguen circulando con el conductor jugador")
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
	-- (para las pruebas de después: se quitan las calles de la ciudad y quedan unas pocas de prueba)
	for _, c in realRoads do
		c:Destroy()
	end
	road(Vector3.new(0, 0, 2000), Vector3.new(400, 0, 2000))
	road(Vector3.new(400, 0, 2000), Vector3.new(400, 0, 2400))
	road(Vector3.new(400, 0, 2400), Vector3.new(0, 0, 2400))
	road(Vector3.new(0, 0, 2400), Vector3.new(0, 0, 2000))
end)()
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
local fanPaid = 2 * Cinema.TicketPrice + Cinema.snackById.Palomitas.Price
check(profiles[clerk].Money >= math.min(Cinema.Job.PerSale + 2 * Cinema.Job.PerTicket + Cinema.Job.PerSnack, math.floor(fanPaid * 0.6)), "el taquillero cobra por cliente, entradas y barra (sin pasar de lo que paga el cliente)")
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
task.wait(0.6) -- (el mercado se manda a todos como mucho dos veces por segundo)
check(#lastMessage(ben, "Market")[2] == 0, "si el vendedor se va, sus anuncios se quitan")
-- Anunciar y retirar sin parar no inunda a los demás: los cambios seguidos se juntan en un envío
local carl, carlRoot = newPlayer(75, "Adulto", 100)
profiles[carl].Items = { Pan = 3 }
InventoryService.refresh(carl)
moveTo(carlRoot, Vector3.new(3010, 0, 3000))
local function marketsTo(p: any): number
	local n = 0
	for _, m in p.Inbox do
		if m[1] == "Market" then
			n += 1
		end
	end
	return n
end
local before = marketsTo(ben)
for _ = 1, 20 do
	T:Fire(carl, "List", "Pan", 1, 5)
	local mine = lastMessage(carl, "Market")[2]
	T:Fire(carl, "Unlist", mine[#mine] and mine[#mine].Id)
end
task.wait(0.6)
local sent = marketsTo(ben) - before
check(sent >= 1 and sent <= 3, ("40 cambios seguidos en el mercadillo: a los demás les llegan juntos (%d envíos)"):format(sent))
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
print("▶ Aeropuerto: horario de vuelos, billetes, embarque, vuelo y aterrizaje (Isla de las Gaviotas)")
do
	local Airport = loadModule(ROOT .. "/shared/Airport")
	local CityPlanA = loadModule(ROOT .. "/shared/CityPlan")
	-- Rutas: cuentas puras (las mismas en el servidor y en los clientes)
	local function standOf(where, kind)
		return if where == "Gaviotas" then Airport.Stands.Gaviotas else Airport.Stands[kind]
	end
	local endsOk, speedOk, pavedOk, clearOk, chainOk = true, true, true, true, true
	for id, route in Airport.Routes do
		local a, b = Airport.pose(route, 0), Airport.pose(route, route.Total)
		if (a.Position - standOf(route.From, route.Kind)).Magnitude > 0.5 or (b.Position - standOf(route.To, route.Kind)).Magnitude > 0.5 then
			endsOk = false
			print("    (puntas) " .. id)
		end
		for i = 2, #route.Legs do
			if math.abs(route.Legs[i - 1].V1 - route.Legs[i].V0) > 0.01 then
				speedOk = false
				print("    (velocidad) " .. id .. " tramo " .. i)
			end
		end
		local t = 0
		local last = a
		while t <= route.Total do
			local cf, _, speed = Airport.pose(route, t)
			local p = cf.Position
			local leg = Airport.legAt(route, t)
			if leg.Ground then
				if not Airport.paved(p.X, p.Z, 1) or math.abs(p.Y - Airport.GROUND) > 0.01 then
					pavedOk = false
					print(("    (fuera del asfalto) %s t=%.1f (%.0f, %.0f)"):format(id, t, p.X, p.Z))
				end
			else
				-- En el aire: por encima de montañas y ciudad (salvo al despegar y aterrizar)
				local nearField = (p - Vector3.new(-3170, 0, 3420)).Magnitude < 1700 or (p - Vector3.new(2900, 0, -3950)).Magnitude < 1300
				for _, m in CityPlanA.Mountains do
					local d = math.sqrt((p.X - m.X) ^ 2 + (p.Z - m.Z) ^ 2)
					if d < m.R and p.Y < m.H - m.R + math.sqrt(m.R * m.R - d * d) + 60 then
						clearOk = false
						print(("    (montaña) %s t=%.1f"):format(id, t))
					end
				end
				if not nearField and CityPlanA.inside(CityPlanA.Coast, p.X, p.Z) and p.Y < 200 then
					clearOk = false
					print(("    (bajo sobre la ciudad) %s t=%.1f y=%.0f"):format(id, t, p.Y))
				end
			end
			-- Sin saltos: de un instante al siguiente, lo que permite su velocidad
			if (p - last.Position).Magnitude > math.max(speed, 20) * 0.25 + 3 then
				chainOk = false
				print(("    (salto) %s t=%.1f"):format(id, t))
			end
			last = cf
			t += 0.25
		end
	end
	check(endsOk, "cada ruta sale de la puerta de su avión y acaba en la de llegada")
	check(speedOk, "la velocidad no da saltos entre tramos (acelera y frena poco a poco)")
	check(pavedOk, "en tierra, los aviones ruedan siempre por el asfalto (pista, calle de rodaje y plataforma)")
	check(clearOk, "en el aire vuelan por encima de las montañas y de la ciudad")
	check(chainOk, "el avión se mueve sin saltos a lo largo de todo el vuelo")
	local joinOk = true
	for _, plane in Airport.Planes do
		for i, id in plane.Routes do
			local nextId = plane.Routes[i % #plane.Routes + 1]
			local r1, r2 = Airport.Routes[id], Airport.Routes[nextId]
			local e, s = Airport.pose(r1, r1.Total), Airport.pose(r2, 0)
			if r1.To ~= r2.From or (e.Position - s.Position).Magnitude > 0.5 or e.LookVector:Dot(s.LookVector) < 0.99 then
				joinOk = false
			end
		end
	end
	check(joinOk, "cada vuelo acaba donde empieza el siguiente del mismo avión (en su puerta y mirando igual)")
	local vuelta = Airport.Routes.Vuelta
	check(Airport.fare(vuelta, "Nino") == 0 and Airport.fare(vuelta, "Adolescente") == vuelta.Price / 2 and Airport.fare(vuelta, "Adulto") == vuelta.Price, "billetes: niños gratis, adolescentes la mitad")
	check(Airport.Runway.X1 - Airport.Runway.X0 >= 600, "la pista mide más de 600 studs")

	-- Mapa mínimo: mostradores, puertas, llegadas, paneles y los dos aviones
	local function fp(name, pos, tags, attrs)
		local p = part(name, CFrame.new(pos), tags, attrs)
		p.Size = Vector3.new(4, 4, 4)
		return p
	end
	local deskVuelta = fp("CheckIn", Vector3.new(-2966, 4, 3081), { "FlightCheckIn" }, { Route = "Vuelta", Place = "Valmar" })
	local deskIda = fp("CheckIn", Vector3.new(-2948, 4, 3081), { "FlightCheckIn" }, { Route = "IdaGaviotas", Place = "Valmar" })
	local deskBack = fp("CheckIn", Vector3.new(2975, 4.4, -4034), { "FlightCheckIn" }, { Route = "VueltaGaviotas", Place = "Gaviotas" })
	local gate1 = fp("Gate", Vector3.new(-2900, 4, 3137), { "FlightGate" }, { Plane = "VLM101", Place = "Valmar" })
	local gate2 = fp("Gate", Vector3.new(-2780, 4, 3137), { "FlightGate" }, { Plane = "VLM205", Place = "Valmar" })
	local gateG = fp("Gate", Vector3.new(2991, 3.4, -3974), { "FlightGate" }, { Plane = "VLM205", Place = "Gaviotas" })
	local arrivalV = fp("Arrival", Vector3.new(-2745, 4, 3088), { "FlightArrival" }, { Place = "Valmar" })
	local arrivalG = fp("Arrival", Vector3.new(2979, 3.4, -4019), { "FlightArrival" }, { Place = "Gaviotas" })
	local boardPart = fp("DeparturesBoard", Vector3.new(-2890, 10, 3099), { "FlightBoard" })
	local sgui = fakeInstance("SurfaceGui")
	sgui.Parent = boardPart
	local boardLabel = fakeInstance("TextLabel")
	boardLabel.Name = "Text"
	boardLabel.Text = "SALIDAS"
	boardLabel.Parent = sgui
	local models = {}
	for _, spec in Airport.Planes do
		local model = fakeInstance("Model")
		model.Name = spec.Id
		model:SetAttribute("PlaneId", spec.Id)
		model:SetAttribute("Kind", spec.Kind)
		model:SetAttribute("NeedsWeld", true)
		model:AddTag("Plane")
		model.Parent = worldRoot
		local root = fakeInstance("Part")
		root.Name = "Root"
		root.Anchored = true
		root.CFrame = CFrame.new()
		root.Parent = model
		local wing = fakeInstance("Part")
		wing.Name = "Wing"
		wing.Anchored = true
		wing.Parent = model
		for i = 1, Airport.Kinds[spec.Kind].Seats do
			local seat = fakeInstance("Seat")
			seat.Name = "Seat"
			seat.Anchored = true
			seat:SetAttribute("SeatIndex", i)
			seat.Parent = model
		end
		models[spec.Id] = model
	end
	local FlightService = loadModule(S .. "FlightService")
	FlightService.init()
	local planesF = FlightService._planes
	local big, small = planesF.VLM101, planesF.VLM205
	check(big ~= nil and small ~= nil and big.Phase == "Boarding" and small.Phase == "Boarding", "los dos aviones esperan en su puerta con el embarque abierto")
	check(models.VLM101:GetAttribute("NeedsWeld") == nil and models.VLM101.Wing.Anchored == false and big.Root.Anchored == true, "el avión se suelda a su suelo al arrancar (y el suelo va anclado)")
	check((big.Root.Position - Airport.rootCFrame("Avion", Airport.parkPose(Airport.Routes.Vuelta)).Position).Magnitude < 0.01, "el avión está en su puesto de la puerta 1")
	FlightService._refreshBoards()
	check(boardLabel.Text:find("VLM101", 1, true) ~= nil and boardLabel.Text:find("EMBARCANDO", 1, true) ~= nil, "el panel de salidas enseña los vuelos que embarcan")
	check(FlightService.canPilot(nil :: any, "VLM101") == false, "nadie pilota los aviones (queda el hueco para el oficio de piloto)")

	-- Billetes
	local flyer, flyerRoot, flyerHum = newPlayer(990, "Adulto", 100)
	local kid, kidRoot, kidHum = newPlayer(991, "Nino", 0)
	local teen = newPlayer(992, "Adolescente", 100)
	local baby = newPlayer(993, "Bebe", 100)
	moveTo(flyerRoot, Vector3.new(-2900, 1, 3130))
	promptOf(gate1, "Embarcar").Triggered:Fire(flyer)
	check(notified(flyer, "Necesitas un billete") and flyerHum.SeatPart == nil, "sin billete no se embarca")
	promptOf(deskVuelta, "Comprar billete").Triggered:Fire(flyer)
	check(profiles[flyer].Money == 60 and flyer:GetAttribute("FlightTicket") == "Vuelta", "el mostrador vende el billete (40 €)")
	promptOf(deskVuelta, "Comprar billete").Triggered:Fire(kid)
	check(profiles[kid].Money == 0 and kid:GetAttribute("FlightTicket") == "Vuelta" and notified(kid, "gratis"), "los niños vuelan gratis (billete infantil)")
	promptOf(deskVuelta, "Comprar billete").Triggered:Fire(teen)
	check(profiles[teen].Money == 80 and teen:GetAttribute("FlightTicket") == "Vuelta", "los adolescentes pagan la mitad")
	promptOf(deskVuelta, "Comprar billete").Triggered:Fire(baby)
	check(baby:GetAttribute("FlightTicket") == nil and profiles[baby].Money == 100, "los bebés no vuelan solos")
	local poor = newPlayer(994, "Adulto", 10)
	promptOf(deskVuelta, "Comprar billete").Triggered:Fire(poor)
	check(poor:GetAttribute("FlightTicket") == nil and notified(poor, "no te llega"), "sin dinero no hay billete")

	-- Embarque
	promptOf(gate1, "Embarcar").Triggered:Fire(flyer)
	promptOf(gate1, "Embarcar").Triggered:Fire(kid)
	check(flyerHum.SeatPart ~= nil and kidHum.SeatPart ~= nil and flyerHum.SeatPart ~= kidHum.SeatPart, "con billete, en la puerta se embarca y cada uno tiene su asiento")
	check(FlightService._riding[flyer] == big and lastMessage(flyer, "Board") ~= nil and flyer:GetAttribute("FlightTicket") == nil, "el billete se gasta al embarcar y sale el panel del vuelo")
	check(flyer:GetAttribute("FlightLanding") == arrivalV.Position, "si sale del juego volando, al volver aparece en la sala de llegadas")
	-- Quien se levanta antes de despegar, se baja del avión
	local teenHum = teen.Character:FindFirstChildOfClass("Humanoid")
	promptOf(gate1, "Embarcar").Triggered:Fire(teen)
	check(teenHum.SeatPart ~= nil, "el adolescente también embarca")
	teenHum.Sit = false
	FlightService._step(big, 0.1)
	check(FlightService._riding[teen] == nil and lastMessage(teen, "Off") ~= nil, "si te levantas antes de despegar, bajas del avión")
	-- El avión grande no embarca en la puerta 2
	local other = newPlayer(995, "Adulto", 100)
	promptOf(deskIda, "Comprar billete").Triggered:Fire(other)
	check(other:GetAttribute("FlightTicket") == "IdaGaviotas" and profiles[other].Money == 75, "billete de avioneta a la Isla de las Gaviotas (25 €)")

	-- Despegue y vuelo
	FlightService._step(big, big.Timer + 0.05)
	check(big.Phase == "Flight", "al acabar el embarque, el avión sale de la puerta")
	local start = big.Root.Position
	local maxY, moved = 0, false
	local reseated = false
	local guard = 0
	while big.Phase == "Flight" and guard < 4000 do
		guard += 1
		FlightService._step(big, 0.5)
		maxY = math.max(maxY, big.Root.Position.Y)
		if (big.Root.Position - start).Magnitude > 50 then
			moved = true
		end
		if not reseated and big.Root.Position.Y > 150 then
			flyerHum.Sit = false -- (intenta levantarse en pleno vuelo)
			FlightService._step(big, 0.1)
			reseated = flyerHum.SeatPart ~= nil
		end
		if big.Phase == "Flight" and guard == 80 then
			check(flyerHum.SeatPart ~= nil and FlightService._riding[flyer] == big, "en pleno vuelo los pasajeros siguen sentados")
		end
	end
	check(moved and maxY > 200, ("el avión despega y vuela por encima de la isla (sube hasta %.0f)"):format(maxY))
	check(reseated, "en pleno vuelo nadie se levanta del asiento")
	check(big.Phase == "Boarding" and big.Route.Id == "Vuelta", "aterriza y vuelve a su puerta para el siguiente vuelo")
	check(flyerHum.SeatPart == nil and kidHum.SeatPart == nil and FlightService._riding[flyer] == nil and lastMessage(flyer, "Off") ~= nil, "al llegar, los pasajeros bajan del avión")
	local dist = (Vector3.new(flyerRoot.Position.X, 0, flyerRoot.Position.Z) - Vector3.new(arrivalV.Position.X, 0, arrivalV.Position.Z)).Magnitude
	check(flyer:GetAttribute("FlightLanding") == nil, "al bajar ya no hay sala de llegadas pendiente")
	check(dist < 8 and (kidRoot.Position - flyerRoot.Position).Magnitude > 0.5 and notified(flyer, "Te damos la bienvenida a Aeropuerto de Valmar"), "y aparecen en la sala de llegadas (cada uno en su sitio)")

	-- Avioneta: ida a la Isla de las Gaviotas y vuelta
	local otherRoot = other.Character.HumanoidRootPart
	local otherHum = other.Character:FindFirstChildOfClass("Humanoid")
	promptOf(gate1, "Embarcar").Triggered:Fire(other)
	check(otherHum.SeatPart == nil, "con billete de avioneta no se sube al avión grande")
	promptOf(gate2, "Embarcar").Triggered:Fire(other)
	check(otherHum.SeatPart ~= nil and FlightService._riding[other] == small, "embarca en la avioneta por la puerta 2")
	check(FlightService.eta(small, "Gaviotas") ~= nil and (FlightService.eta(small, "Gaviotas") :: number) > small.Route.Total - 1, "el horario sabe cuándo embarca la avioneta en la isla")
	-- Suelo de verdad en la isla: el jugador aparece encima (Shared/Ground)
	local floor = part("Plaza", CFrame.new(2979, 0, -4019), {})
	floor.Size = Vector3.new(40, 1, 40)
	local oldRaycast = Fake.Raycast
	Fake.Raycast = function(_, origin)
		if (Vector3.new(origin.X, 0, origin.Z) - Vector3.new(2979, 0, -4019)).Magnitude < 20 then
			return { Instance = floor, Position = Vector3.new(origin.X, 0.4, origin.Z), Normal = Vector3.new(0, 1, 0) }
		end
		return nil
	end
	FlightService._step(small, small.Timer + 0.05)
	guard = 0
	while small.Phase == "Flight" and guard < 4000 do
		guard += 1
		FlightService._step(small, 0.5)
	end
	Fake.Raycast = oldRaycast
	check(small.Phase == "Boarding" and small.Route.Id == "VueltaGaviotas", "la avioneta aterriza en la Isla de las Gaviotas y embarca para volver")
	local d2 = (Vector3.new(otherRoot.Position.X, 0, otherRoot.Position.Z) - Vector3.new(arrivalG.Position.X, 0, arrivalG.Position.Z)).Magnitude
	check(otherHum.SeatPart == nil and d2 < 8 and math.abs(otherRoot.Position.Y - 3.4) < 0.01, "baja en el aeródromo de la isla, de pie en el suelo firme")
	check(notified(other, "Aeródromo de las Gaviotas"), "aviso de bienvenida a la isla")
	promptOf(gate2, "Embarcar").Triggered:Fire(flyer)
	check(notified(flyer, "todavía no está en la puerta"), "si el avión no está en la puerta, te dice cuándo embarca")
	promptOf(deskBack, "Comprar billete").Triggered:Fire(other)
	promptOf(gateG, "Embarcar").Triggered:Fire(other)
	check(otherHum.SeatPart ~= nil and profiles[other].Money == 50, "en la isla se compra el billete de vuelta y se embarca")
	FlightService._step(small, small.Timer + 0.05)
	guard = 0
	while small.Phase == "Flight" and guard < 4000 do
		guard += 1
		FlightService._step(small, 0.5)
	end
	local d3 = (Vector3.new(otherRoot.Position.X, 0, otherRoot.Position.Z) - Vector3.new(arrivalV.Position.X, 0, arrivalV.Position.Z)).Magnitude
	check(small.Phase == "Boarding" and small.Route.Id == "IdaGaviotas" and d3 < 8 and otherHum.SeatPart == nil, "vuelve a Valmar y baja en la sala de llegadas")
	for _, p in { flyer, kid, teen, baby, poor, other } do
		local i = table.find(playersList, p)
		if i then
			table.remove(playersList, i)
		end
	end
end

print("▶ Aeroclub: licencia de piloto, avionetas de alquiler, avión de línea, aterrizajes y accidentes")
do
	local Airport = loadModule(ROOT .. "/shared/Airport")
	local AV = remotes.Aviation.OnServerEvent
	local boards, pmodels, gears = {}, {}, {}
	for _, spec in Airport.PilotPlanes do
		local model = fakeInstance("Model")
		model.Name = spec.Id
		model:SetAttribute("PilotPlane", spec.Id)
		model:SetAttribute("Kind", spec.Kind)
		model:SetAttribute("NeedsWeld", true)
		model:AddTag("PilotPlane")
		model.Parent = worldRoot
		local root = fakeInstance("Part")
		root.Name = "Root"
		root.Anchored = true
		root.CanCollide = true
		root.CFrame = Airport.rootCFrame(spec.Kind, spec.Pose)
		root.Parent = model
		model.PrimaryPart = root
		local seat = fakeInstance("Seat")
		seat.Name = "PilotSeat"
		seat.CFrame = root.CFrame
		seat.Parent = model
		for i = 1, 2 do
			local s2 = fakeInstance("Seat")
			s2.Name = "Seat"
			s2.CFrame = root.CFrame * CFrame.new(0, 0, i * 3)
			s2:SetAttribute("SeatIndex", i)
			s2.Parent = model
		end
		local wheel = fakeInstance("Part")
		wheel.Name = "Wheel"
		wheel:SetAttribute("Gear", true)
		wheel.Parent = model
		local board = fakeInstance("Part")
		board.Name = "BoardPoint"
		board.CFrame = root.CFrame * CFrame.new(-4, -2, 0)
		board.Parent = model
		boards[spec.Id], pmodels[spec.Id], gears[spec.Id] = board, model, wheel
	end
	local desk = part("AeroclubDesk", CFrame.new(Airport.Aeroclub.X, 4, 3194), { "Aeroclub" }, { Place = "Valmar" })
	local Aviation = loadModule(S .. "AviationService")
	Aviation.init()
	local P = Aviation._planes
	local A1, A2, JET = P["EC-VAL1"], P["EC-VAL2"], P["EC-VLA"]
	check(A1 ~= nil and A2 ~= nil and JET ~= nil and pmodels["EC-VAL1"]:GetAttribute("NeedsWeld") == nil and A1.Root.Anchored, "las dos avionetas y el avión de línea del aeroclub esperan en su sitio (soldados y anclados)")
	check(promptOf(boards["EC-VAL1"], "Pilotar") ~= nil and promptOf(boards["EC-VAL1"], "Subir a bordo") ~= nil and promptOf(desk, "Aeroclub") ~= nil, "carteles «Pilotar», «Subir a bordo» y el mostrador del aeroclub")
	local teen = newPlayer(1990, "Adolescente", 1000)
	local teenHum = teen.Character:FindFirstChildOfClass("Humanoid")
	local pilot, pilotRoot, pilotHum = newPlayer(1991, "Adulto", 1000)
	promptOf(boards["EC-VAL1"], "Pilotar").Triggered:Fire(teen)
	check(notified(teen, "mayor de edad") and teenHum.SeatPart == nil, "para pilotar hay que ser mayor de edad")
	promptOf(boards["EC-VAL1"], "Pilotar").Triggered:Fire(pilot)
	check(notified(pilot, "licencia de piloto") and pilotHum.SeatPart == nil, "sin licencia de piloto no se pilota")
	-- Curso: el teórico
	promptOf(desk, "Aeroclub").Triggered:Fire(pilot)
	local menu = lastMessage(pilot, "Menu")
	check(menu ~= nil and type(menu[3]) == "table" and string.find(menu[3].Options[1], "Curso de piloto", 1, true) ~= nil, "el mostrador del aeroclub ofrece el curso de piloto")
	AV:Fire(pilot, "Choose", menu[2], 1)
	local theory = lastMessage(pilot, "Theory")
	check(theory ~= nil and #theory[3].Questions == 5 and profiles[pilot].Money == 850, "el curso cuesta 150 € y empieza con un teórico de 5 preguntas")
	AV:Fire(pilot, "Answers", theory[2], { 0, 0, 0, 0, 0 })
	check(notified(pilot, "suspendido") and not (profiles[pilot].Aviation and profiles[pilot].Aviation.Theory), "con las respuestas mal, suspenso")
	promptOf(desk, "Aeroclub").Triggered:Fire(pilot)
	AV:Fire(pilot, "Choose", lastMessage(pilot, "Menu")[2], 1)
	local token = lastMessage(pilot, "Theory")[2]
	AV:Fire(pilot, "Answers", token, table.clone(Aviation._sessions[pilot].Correct))
	check(profiles[pilot].Aviation.Theory == true and notified(pilot, "Teórico aprobado"), "con 4 o más bien, teórico aprobado")
	-- Clase práctica (gratis): despegar, subir y aterrizar suave en la pista
	promptOf(desk, "Aeroclub").Triggered:Fire(pilot)
	menu = lastMessage(pilot, "Menu")
	check(string.find(menu[3].Options[1], "Clase práctica", 1, true) ~= nil, "después, la clase práctica")
	local money = profiles[pilot].Money
	AV:Fire(pilot, "Choose", menu[2], 1)
	check(pilotHum.SeatPart == A1.PilotSeat and pilot:GetAttribute("Piloting") == "EC-VAL1" and not A1.Root.Anchored and lastMessage(pilot, "Pilot") ~= nil and profiles[pilot].Money == money, "clase práctica gratis: a los mandos de la avioneta (su ordenador la vuela)")
	check(pmodels["EC-VAL1"]:GetAttribute("EngineOn") == true and promptOf(boards["EC-VAL1"], "Pilotar").Enabled == false and pilot:GetAttribute("ActivityText") ~= nil, "motor en marcha, nadie más puede cogerla y el aviso de la clase")
	A1.Root.CFrame = CFrame.new(-3000, 320, Airport.Runway.Z)
	AV:Fire(pilot, "State", { Air = true, Gear = true, Flaps = 0, Throttle = 1, Speed = 90 })
	check(A1.Airborne and pmodels["EC-VAL1"]:GetAttribute("Airborne") == true and notified(pilot, "aterriza suave") and promptOf(boards["EC-VAL1"], "Subir a bordo").Enabled == false, "por encima de 70 m: ahora a aterrizar (y en el aire no se sube nadie)")
	AV:Fire(pilot, "Exit")
	check(pilotHum.SeatPart == A1.PilotSeat and notified(pilot, "En el aire no se baja"), "en el aire no se baja nadie")
	pilotHum.Sit = false
	task.wait(0.05)
	check(pilotHum.SeatPart == A1.PilotSeat and Aviation._piloting[pilot] == A1, "si se suelta en el aire, vuelve a su asiento")
	-- Toca la pista
	local runway = part("Runway", CFrame.new(-3200, -0.3, Airport.Runway.Z), {})
	runway.CanCollide = true
	local oldRaycast = Fake.Raycast
	Fake.Raycast = function(_, origin)
		return { Instance = runway, Position = Vector3.new(origin.X, Airport.GROUND, origin.Z), Normal = Vector3.new(0, 1, 0) }
	end
	A1.Root.CFrame = CFrame.new(-3200, Airport.GROUND + Airport.Kinds.Avioneta.FloorY - 0.3, Airport.Runway.Z)
	AV:Fire(pilot, "Touchdown", { Sink = 4, Result = "Suave" })
	check(profiles[pilot].Licenses and profiles[pilot].Licenses.Piloto == true and notified(pilot, "APROBADO") and pilot:GetAttribute("ActivityText") == nil, "aterrizaje suave en la pista: ¡licencia de piloto!")
	AV:Fire(pilot, "Touchdown", { Sink = 4, Result = "Suave" })
	check(profiles[pilot].Aviation.Landings == 1, "con licencia, cada aterrizaje suave en avioneta cuenta para la habilitación")
	AV:Fire(pilot, "Touchdown", { Sink = 15, Result = "Duro" })
	check(A1.Health < 100 and notified(pilot, "Aterrizaje duro") and profiles[pilot].Aviation.Landings == 1, "un aterrizaje duro daña el avión (y no cuenta)")
	task.wait(0.1)
	AV:Fire(pilot, "State", { Air = false, Gear = true, Flaps = 0, Throttle = 0, Speed = 0 })
	AV:Fire(pilot, "Exit")
	check(pilotHum.SeatPart == nil and pilot:GetAttribute("Piloting") == nil and A1.Root.Anchored and lastMessage(pilot, "Off") ~= nil and A1.Renter == pilot and A1.LeftAt ~= nil, "parado en tierra se baja: la avioneta queda aparcada (y sigue siendo suya)")
	promptOf(boards["EC-VAL1"], "Pilotar").Triggered:Fire(pilot)
	check(pilotHum.SeatPart == A1.PilotSeat and profiles[pilot].Money == money, "su avioneta alquilada la vuelve a coger sin pagar")
	task.wait(0.1)
	AV:Fire(pilot, "Exit")
	-- Otro piloto: la avioneta alquilada no es suya; alquila la otra
	local other, otherRoot, otherHum = newPlayer(1992, "Adulto", 1000)
	profiles[other].Licenses = { Piloto = true }
	promptOf(boards["EC-VAL1"], "Pilotar").Triggered:Fire(other)
	check(otherHum.SeatPart == nil and notified(other, "alquilada por otra persona"), "la avioneta que ha alquilado otro no se puede coger")
	promptOf(desk, "Aeroclub").Triggered:Fire(other)
	AV:Fire(other, "Choose", lastMessage(other, "Menu")[2], 2)
	check(otherHum.SeatPart == A2.PilotSeat and profiles[other].Money == 940 and A2.Renter == other and notified(other, "Avioneta alquilada"), "con licencia alquila la otra avioneta (60 €)")
	-- Un pasajero (en tierra) y un accidente
	promptOf(boards["EC-VAL2"], "Subir a bordo").Triggered:Fire(teen)
	check(teenHum.SeatPart ~= nil and Aviation._riding[teen] == A2, "otro jugador sube de pasajero con el avión parado")
	teenHum.Health = 100
	A2.Root.CFrame = CFrame.new(-2000, 200, 3000)
	AV:Fire(other, "Crash", { Reason = "Te has estrellado contra Torre" })
	local home = Airport.rootCFrame("Avioneta", Airport.pilotPlane("EC-VAL2").Pose).Position
	check(otherHum.SeatPart == nil and teenHum.SeatPart == nil and other:GetAttribute("Piloting") == nil and notified(other, "Accidente") and notified(teen, "Accidente"), "accidente: piloto y pasajero salen del avión (con aviso)")
	check(teenHum.Health < 100 and teenHum.Health >= 10 and otherHum.Health >= 10, "se hacen daño pero nadie muere")
	check((A2.Root.Position - home).Magnitude < 0.5 and A2.Root.Anchored and A2.Renter == nil and A2.DownUntil > os.clock(), "la avioneta vuelve al hangar y queda en revisión")
	promptOf(boards["EC-VAL2"], "Pilotar").Triggered:Fire(other)
	check(otherHum.SeatPart == nil and notified(other, "en revisión"), "en revisión no se puede volar")
	-- El avión de línea: licencia y 3 aterrizajes suaves
	promptOf(boards["EC-VLA"], "Pilotar").Triggered:Fire(other)
	check(otherHum.SeatPart == nil and notified(other, "aterrizajes suaves"), "el avión de línea pide 3 aterrizajes suaves en avioneta")
	profiles[other].Aviation.Landings = 3
	promptOf(boards["EC-VLA"], "Pilotar").Triggered:Fire(other)
	check(otherHum.SeatPart == JET.PilotSeat and other:GetAttribute("Piloting") == "EC-VLA" and profiles[other].Money == 940, "con la habilitación, a los mandos del avión de línea (sin alquiler)")
	task.wait(0.1)
	JET.Root.CFrame = CFrame.new(-3000, 200, 3400)
	AV:Fire(other, "State", { Air = true, Gear = false, Flaps = 1, Throttle = 0.8, Speed = 200 })
	check(gears["EC-VLA"].Transparency == 1 and pmodels["EC-VLA"]:GetAttribute("GearDown") == false and JET.Flaps == 1, "subir el tren lo esconde para todos")
	-- Vigilancia del servidor: un salto imposible vuelve atrás; atravesar un edificio es accidente
	JET.LastPos, JET.LastGood = JET.Root.Position, JET.Root.CFrame -- (ya volando por ahí)
	Aviation._validate(JET, 0.25)
	local good = JET.Root.CFrame
	JET.Root.CFrame = CFrame.new(4000, 200, -3000)
	Aviation._validate(JET, 0.25)
	check((JET.Root.Position - good.Position).Magnitude < 0.5 and lastMessage(other, "Reset") ~= nil, "un salto imposible: vuelve al último sitio bueno")
	local building = part("Edificio", CFrame.new(-3010, 200, 3400), {})
	building.CanCollide = true
	Fake.Raycast = function(_, origin, direction)
		if origin.Y > 100 and direction.Magnitude > 1 then
			return { Instance = building, Position = origin + direction / 2, Normal = Vector3.new(1, 0, 0) }
		end
		return nil
	end
	JET.Root.CFrame = CFrame.new(-3030, 200, 3400)
	Aviation._validate(JET, 0.25)
	Fake.Raycast = oldRaycast
	check(other:GetAttribute("Piloting") == nil and notified(other, "Te has estrellado contra Edificio") and JET.Root.Anchored, "atravesar un edificio en vuelo: accidente (lo comprueba el servidor)")
	-- La avioneta alquilada que se deja lejos vuelve sola al hangar
	moveTo(pilotRoot, Vector3.new(0, 0, 0))
	A1.LeftAt = os.clock() - Aviation.ReturnAfter - 1
	Aviation._validate(A1, 0.25)
	local home1 = Airport.rootCFrame("Avioneta", Airport.pilotPlane("EC-VAL1").Pose).Position
	check((A1.Root.Position - home1).Magnitude < 0.5 and A1.Renter == nil and notified(pilot, "ha vuelto al hangar"), "la avioneta que se deja sola vuelve al hangar (y se acaba el alquiler)")
	local _ = otherRoot
	for _, p in { teen, pilot, other } do
		local i = table.find(playersList, p)
		if i then
			table.remove(playersList, i)
		end
	end
end

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
-- Bocas de metro que se bajan andando (geometría compartida: Metro.access)
local stairsOk, landingsOk, hallsOk, shaftsOk, lobbyOk, deepOk = true, true, true, true, true, true
for id in Metro.Stations do
	local A = Metro.access(id)
	local S, K, H = A.Stair, A.Shaft, A.Hall
	local function near(a, b)
		return (a - b).Magnitude < 0.05
	end
	-- De la acera, dos tramos con rellano hasta el vestíbulo; ningún peldaño más alto de la cuenta
	local p = S.Top
	if math.abs(p.Y - Metro.StreetY) > 0.01 then
		stairsOk = false
	end
	for i, f in S.Flights do
		local drop = f.Top.Y - f.Bottom.Y
		local run = (Vector3.new(f.Bottom.X, 0, f.Bottom.Z) - Vector3.new(f.Top.X, 0, f.Top.Z)).Magnitude
		if not near(f.Top, p) or f.Rise > Metro.MaxRise or math.abs(f.Steps * f.Rise - drop) > 0.01 or math.abs(f.Steps * f.Run - run) > 0.01 then
			stairsOk = false
		end
		p = f.Bottom
		local land = S.Landings[i]
		if land then
			if not near(land.From, p) or math.abs(land.To.Y - p.Y) > 0.01 or (land.To - land.From).Magnitude < 3 then
				landingsOk = false
			end
			p = land.To
		end
	end
	if not near(p, S.Bottom) or math.abs(S.Bottom.Y - Metro.HallY) > 0.01 then
		stairsOk = false
	end
	-- El vestíbulo recoge el final de la escalera y el principio de las mecánicas; su techo, bajo las calles
	local function onHall(q)
		return q.X >= H.Min.X - 0.05 and q.X <= H.Max.X + 0.05 and q.Z >= H.Min.Z - 0.05 and q.Z <= H.Max.Z + 0.05 and math.abs(q.Y - H.Min.Y) < 0.05
	end
	if not onHall(S.Bottom) or not onHall(K.Top) or H.Max.Y + 0.5 > -4.2 or H.Max.Y - H.Min.Y < 7 then
		hallsOk = false
	end
	-- Escaleras mecánicas (y la fija de al lado): peldaños bajos, pendiente de escalera mecánica
	local run = (Vector3.new(K.Bottom.X, 0, K.Bottom.Z) - Vector3.new(K.Top.X, 0, K.Top.Z)).Magnitude
	local slope = math.deg(math.atan((K.Top.Y - K.Bottom.Y) / run))
	if K.Rise > Metro.MaxRise or math.abs(K.Steps * K.Rise - (K.Top.Y - K.Bottom.Y)) > 0.01 or slope > 35 or slope < 25 or math.abs(K.Bottom.Y - A.LowerY) > 0.01 then
		shaftsOk = false
	end
	-- Y llegan al vestíbulo de andenes de su línea (donde están los tornos)
	if not Metro.inLobby(id, A.Line, K.Bottom) or not Metro.inLobby(id, A.Line, A.Route[#A.Route]) then
		lobbyOk = false
	end
	-- Al fondo del todo ya se está "bajo tierra" (no llueve); en la acera, no
	if not (A.LowerY + 6 < Metro.Underground and Metro.StreetY + 5 > Metro.Underground) then
		deepOk = false
	end
	-- Camino continuo: cada tramo empieza donde acaba el anterior y nunca sube de golpe
	for k = 2, #A.Route do
		local a, b = A.Route[k - 1], A.Route[k]
		if b.Y > a.Y + 0.01 then
			stairsOk = false
		end
	end
end
check(stairsOk, "las bocas de metro bajan de la acera con escaleras (peldaños de 1,2 como mucho y sin huecos)")
check(landingsOk, "las escaleras de la calle tienen su rellano a mitad")
check(hallsOk, "el vestíbulo recoge la escalera de la calle y las mecánicas, bajo el suelo de las calles")
check(shaftsOk, "escaleras mecánicas y fija hasta el fondo, con pendiente de escalera mecánica")
check(lobbyOk, "las escaleras mecánicas llegan al vestíbulo de andenes de cada estación")
check(deepOk, "abajo se está bajo tierra (sin lluvia) y en la calle no")
local off = { Metro.escalatorOffset(0, 0, 1.3, 40, 7), Metro.escalatorOffset(39, 0, 1.3, 40, 7), Metro.escalatorOffset(0, 10, 1.3, 40, -7) }
check(off[1] > 0 and off[2] < 40 * 1.3 and off[3] >= 0 and off[3] < 40 * 1.3, "los peldaños de las escaleras mecánicas dan la vuelta sin salirse")
-- Cuándo llega el tren: cuentas puras
do
	local centers = { 75, 1000, 2500 }
	local t0 = { Centers = centers, Index = 1, Dir = 1, Phase = "Dwell", Timer = 5, Duration = 1, Elapsed = 0 }
	local e0, to0 = Metro.eta(t0, 1)
	local e1 = Metro.eta(t0, 2)
	local e3, to3 = Metro.eta(t0, 3)
	check(e0 == 0 and to0 == 3, "con el tren en el andén el panel dice EN ANDÉN (y hacia la última estación)")
	check(math.abs(e1 - (5 + Metro.travelTime(925))) < 0.01, "llega a la siguiente: lo que le queda parado + el viaje")
	check(math.abs(e3 - (5 + Metro.travelTime(925) + Metro.Dwell + Metro.travelTime(1500))) < 0.01 and to3 == 1, "a la última: con la parada de en medio, y luego vuelve")
	local back = { Centers = centers, Index = 3, Dir = 1, Phase = "Move", Timer = 0, Duration = 20, Elapsed = 5 }
	local eb = Metro.eta(back, 2)
	check(math.abs(eb - (15 + Metro.Dwell + Metro.travelTime(1500))) < 0.01, "si va hacia la punta, primero llega allí y da la vuelta")
	check(Metro.travelTime(10) < Metro.travelTime(100) and Metro.travelTime(5000) > 5000 / Metro.Speed, "el tren arranca y frena (tarda más que a velocidad de crucero)")
	check(Metro.boardText(L1, 150, #L1.Stations):find("3 min") ~= nil and Metro.boardText(L1, 10, 1):find("LLEGANDO") ~= nil and Metro.boardText(L1, 0, 1, 7):find("EN ANDÉN") ~= nil, "el cartel: minutos, llegando y en andén")
	-- Con descanso en las cabeceras (horario de noche) el tren tarda más en volver
	local rest = { Centers = centers, Index = 3, Dir = 1, Phase = "Move", Timer = 0, Duration = 20, Elapsed = 5, Layover = 60 }
	check(math.abs(Metro.eta(rest, 2) - (eb + 60)) < 0.01, "de noche el tren descansa en la cabecera y el panel lo cuenta")
	-- Movimiento compartido (servidor y clientes calculan lo mismo)
	local T = Metro.travelTime(900)
	local state = { Phase = "Move", From = 100, To = 1000, Duration = T, T0 = 50 }
	check(Metro.positionAt(state, 50) == 100 and math.abs(Metro.positionAt(state, 50 + T) - 1000) < 0.01, "el tren sale del andén y llega justo al siguiente")
	local mid = Metro.positionAt(state, 50 + T / 2)
	check(math.abs(mid - 550) < 1, "a mitad de tiempo va por la mitad del túnel")
	local back2 = { Phase = "Move", From = 1000, To = 100, Duration = T, T0 = 0 }
	check(Metro.positionAt(back2, T / 2) < 1000 and Metro.positionAt(back2, T) == 100, "también de vuelta")
end
-- Horarios según la hora del juego
check(Metro.scheduleAt(7.5).Id == "Punta" and Metro.scheduleAt(12).Id == "Normal" and Metro.scheduleAt(18).Id == "Punta" and Metro.scheduleAt(22).Id == "Reducida" and Metro.scheduleAt(3).Id == "Nocturno", "el metro sigue el horario: punta, normal, reducido y nocturno")
check(Metro.scheduleAt(7.5).Layover < Metro.scheduleAt(22).Layover and Metro.scheduleAt(22).Layover < Metro.scheduleAt(3).Layover, "en hora punta pasan más trenes que por la noche")
-- Planificador de rutas
do
	local same = Metro.route("Poniente", "Levante")
	check(same ~= nil and #same.Legs == 1 and same.Legs[1].Line == "L1" and same.Transfers == 0 and same.Legs[1].Stops[2] == "PlazaMayor", "ruta en la misma línea: sin transbordo y pasando por Plaza Mayor")
	local cross = Metro.route("Villaverde", "Puerto")
	check(cross ~= nil and cross.Transfers == 1 and cross.Legs[1].Line == "L1" and cross.Legs[2].Line == "L2" and cross.Legs[1].To == "PlazaMayor" and cross.Legs[2].From == "PlazaMayor" and cross.Legs[2].To == "Puerto", "ruta con transbordo en Plaza Mayor (Línea 1 y luego Línea 2)")
	check(cross.Seconds > same.Seconds and cross.Seconds > 60, "el tiempo aproximado cuenta los tramos y el transbordo")
	local rev = Metro.route("Campus", "Norte")
	check(rev ~= nil and rev.Legs[1].Stops[1] == "Campus" and rev.Legs[#rev.Legs].Stops[#rev.Legs[#rev.Legs].Stops] == "Norte", "las rutas van en los dos sentidos")
	check(#Metro.route("Norte", "Norte").Legs == 0, "misma estación: no hay que viajar")
	for id in Metro.Stations do
		for id2 in Metro.Stations do
			if not Metro.route(id, id2) then
				check(false, "hay ruta de " .. id .. " a " .. id2)
			end
		end
	end
	check(true, "todas las estaciones están conectadas entre sí")
	local LEV = Metro.Stations.Levante
	local near, d = Metro.nearestStation(Vector3.new(LEV.Surface[1] + 30, 1, LEV.Surface[2]))
	local e = Metro.entrance("Levante")
	check(near == "Levante" and math.abs(d - (Vector3.new(e.X, 0, e.Z) - Vector3.new(LEV.Surface[1] + 30, 0, LEV.Surface[2])).Magnitude) < 0.01, "la estación más cercana a donde estás (hasta su boca de metro)")
	check(Metro.meters(1600) == "450 m" and Metro.duration(200) == "3 min 20 s" and Metro.duration(40) == "40 s", "distancias y tiempos en texto")
	check(Metro.announceNext(L1, "PlazaMayor"):find("Correspondencia con Línea 2") ~= nil and Metro.announceNext(L1, "Levante"):find("Correspondencia") == nil, "la megafonía avisa del transbordo solo donde lo hay")
	for id in Metro.Stations do
		local info = Metro.StationInfo[id]
		if not info or not info.District then
			check(false, "cada estación dice a qué distrito da servicio: " .. id)
		end
	end
	local districts = {}
	for _, info in Metro.StationInfo do
		districts[info.District] = true
	end
	local all = true
	for _, dd in Metro.Districts do
		all = all and districts[dd.Id] == true
	end
	check(all, "el metro llega a los 6 distritos")
end
-- Estaciones (lo mínimo de cada una)
for id, st in Metro.Stations do
	local c = Vector3.new(st.Surface[1], L1.Y, st.Surface[2])
	mp("Door", CFrame.new(st.Surface[1], 2.5, st.Surface[2]), { "MetroEntrance" }, { Station = id })
	mp("Arrival", CFrame.new(c + Vector3.new(30, 3, 0)), { "MetroArrival" }, { Station = id, Line = "L1" })
	mp("Alight", CFrame.new(c + Vector3.new(12, 3, 0)), { "MetroAlight" }, { Station = id, Line = "L1" })
	local kiosk = mp("Kiosk", CFrame.new(c + Vector3.new(40, 2, 18)), { "MetroShop", "MetroDelivery" }, { ShopId = "Quiosco", Station = id })
	local _ = kiosk
end
local P = Metro.Stations[L1.Stations[1]] -- (la primera estación de la Línea 1: allí espera el tren)
local base = Vector3.new(P.Surface[1], L1.Y, P.Surface[2])
local machine = mp("TicketMachine", CFrame.new(base + Vector3.new(46, 3, -20)), { "MetroTicketMachine" })
local gate = mp("Turnstile", CFrame.new(base + Vector3.new(19, 2, 0)), { "MetroGate" }, { Through = base + Vector3.new(14, 3, 0) })
local board = mp("Board", CFrame.new(base + Vector3.new(7, 2.5, 0)), { "MetroBoard" }, { Station = P.Id, Line = "L1" })
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
	for _, x in { -4.4, 4.4 } do -- (una puerta a cada lado, como los coches de verdad)
		local door = part("Door", CFrame.new(base + Vector3.new(x, 0, 0)), { "MetroDoor" })
		door.Parent = carModel
	end
end
trainModel:AddTag("MetroTrain")
-- Galería
local H = Metro.Stations.PlazaMayor
local hub = Vector3.new(H.Surface[1], L1.Y, H.Surface[2])
-- Escalera mecánica: el suelo invisible lleva a quien se sube
local belt = mp("EscalatorBelt", CFrame.new(base + Vector3.new(30, 10, -40)), { "MetroEscalator" }, { Velocity = Vector3.new(6, -3.5, 0), Down = true })
local music = mp("Counter", CFrame.new(hub + Vector3.new(98, 2, 28)), { "MetroShop" }, { ShopId = "Musica" })
local mic = mp("Mic", CFrame.new(hub + Vector3.new(128, 3, -16)), { "MetroStage" })
local missionBoard = mp("MissionBoard", CFrame.new(hub + Vector3.new(80, 5, -24)), { "MetroMissionBoard" })
local lostOffice = mp("LostOffice", CFrame.new(hub + Vector3.new(58, 2, -28)), { "MetroLostOffice" })
-- Taquilla con persona (lejos de las máquinas) y un banco en el andén de la primera estación
local booth = mp("BoothCounter", CFrame.new(base + Vector3.new(40, 1.7, -60)), { "MetroTicketBooth" }, { Station = P.Id, StaffSpot = base + Vector3.new(40, 0.2, -62.5) }, Vector3.new(5.8, 3.4, 1))
local metroBench = mp("Bench", CFrame.new(base + Vector3.new(15.6, 1.5, 30)), {}, nil, Vector3.new(1.6, 0.4, 5))
local MetroService = loadModule(S .. "MetroService")
MetroService.init()
check(jobProviders.Handler_Revisor ~= nil, "el tablón de la galería lleva al oficio de revisor/a")
check(belt.AssemblyLinearVelocity == Vector3.new(6, -3.5, 0), "las escaleras mecánicas llevan (cinta transportadora)")
local train = MetroService._trains.L1
check(train ~= nil and train.Phase == "Dwell" and train.Index == 1, "el tren de la Línea 1 espera en la primera estación con las puertas abiertas")
local rider, riderRoot, riderHumanoid = newPlayer(91, "Adulto", 100)
profiles[rider].Items = {}
InventoryService.refresh(rider)
moveTo(riderRoot, Vector3.new(P.Surface[1], 0, P.Surface[2]))
local door = nil
for _, d in services.CollectionService:GetTagged("MetroEntrance") do
	if d:GetAttribute("Station") == P.Id then
		door = d
	end
end
promptOf(door, "Bajar en ascensor").Triggered:Fire(rider)
check(notified(rider, "Metro · " .. P.Name), "el ascensor de la boca de metro baja directo al vestíbulo de andenes")
moveTo(riderRoot, base + Vector3.new(40, -2, -18))
promptOf(gate, "Pasar (billete)").Triggered:Fire(rider)
check(notified(rider, "Necesitas un billete"), "sin billete no se pasa el torno")
M:Fire(rider, "BuyTicket", "Sencillo")
check(profiles[rider].Money == 98 and InventoryService.count(rider, "BilleteMetro") == 1, "la máquina vende el billete")
promptOf(gate, "Pasar (billete)").Triggered:Fire(rider)
check(InventoryService.count(rider, "BilleteMetro") == 0 and rider:GetAttribute("MetroTicket") == true, "el torno gasta el billete")
do
	-- Ya al otro lado (en el andén): el torno no le devuelve ni le cobra otro billete (captura del niño
	-- que no podía entrar: un segundo toque de Interactuar le sacaba otra vez al vestíbulo)
	local landed = riderRoot.Position
	InventoryService.add(rider, "BilleteMetro", 1)
	promptOf(gate, "Pasar (billete)").Triggered:Fire(rider)
	check(landed.X < gate.Position.X - 3 and InventoryService.count(rider, "BilleteMetro") == 1 and (riderRoot.Position - landed).Magnitude < 0.1, "pasado el torno, te quedas en el andén: otro toque no te mueve ni te cobra")
	InventoryService.remove(rider, "BilleteMetro", 1)
end
do
	local kid = newPlayer(93, "Nino", 0)
	promptOf(gate, "Pasar (billete)").Triggered:Fire(kid)
	check(kid:GetAttribute("MetroTicket") == true and notified(kid, "gratis"), "los niños pasan el torno gratis")
end
-- Subir y viajar
moveTo(riderRoot, base + Vector3.new(8, -2, 0))
promptOf(board, "Subir al metro").Triggered:Fire(rider)
check(riderHumanoid.SeatPart ~= nil and MetroService._riding[rider] == train and lastMessage(rider, "Board") ~= nil, "sube al tren y se sienta")
local guard = 0
local hubIndex = table.find(L1.Stations, "PlazaMayor")
-- (antes de salir: cuánto dice el panel que tarda en llegar a Plaza Mayor)
local etaHub, towardHub = Metro.eta(train, hubIndex)
local waited = 0
while not (train.Index == hubIndex and train.Phase == "Dwell") and guard < 2000 do
	guard += 1
	waited += 0.5
	MetroService._step(train, 0.5)
end
check(math.abs(waited - etaHub) <= 1.5 and towardHub == #L1.Stations, ("el panel acierta cuándo llega el tren (%.1f s dicho, %.1f s de verdad) y hacia dónde va"):format(etaHub, waited))
local arrive = lastMessage(rider, "Arrive")
check(arrive ~= nil and arrive[2].Station == "Plaza Mayor", "el tren llega a Plaza Mayor y te avisa")
local car2 = trainModel:FindFirstChild("Car2"):FindFirstChild("Root")
check((car2.Position - Metro.center("PlazaMayor", L1)).Magnitude < 5, "el tren para con el centro en el andén")
do
	local frame = Metro.frame("PlazaMayor", L1)
	local platformOpen, farClosed, near, far = true, true, 0, 0
	for _, car in train.Cars do
		local facing = if frame.RightVector:Dot(car.Root.CFrame.RightVector) >= 0 then 1 else -1
		for _, door in car.Doors do
			if (door:GetAttribute("Side") or 0) * facing > 0 then
				near += 1
				platformOpen = platformOpen and door.Transparency == 1 and door.CanCollide == false
			else
				far += 1
				farClosed = farClosed and door.Transparency == 0 and door.CanCollide ~= false
			end
		end
	end
	check(near > 0 and platformOpen, "con el tren parado se abren las puertas del lado del andén")
	check(far > 0 and farClosed, "…y las del otro lado (la pared y la vía) siguen cerradas")
end
M:Fire(rider, "Alight")
check(MetroService._riding[rider] == nil and lastMessage(rider, "Off") ~= nil, "bajas en Plaza Mayor")
-- Un coche que se ha llevado otro sistema (un viajero sentado al que teletransportan) vuelve a su sitio
do
	local root = train.Cars[1].Root
	local before = root.Position
	root.CFrame = CFrame.new(700, 1, -1900) -- (en la calle, en Los Pinos)
	MetroService._step(train, 0.05)
	check(train.Phase == "Dwell" and (root.Position - before).Magnitude < 1, "si algo se lleva un coche del metro a la calle, vuelve a su sitio")
end
-- Nadie andando por los túneles: vuelve al andén con un aviso
do
	local points = Metro.path(L1)
	local tunnelPoint = (points[2] + points[3]) / 2
	moveTo(riderRoot, tunnelPoint + Vector3.new(0, 3, 0))
	MetroService._guardTracks()
	local back = riderRoot.Position
	check((back - tunnelPoint).Magnitude > 40 and notified(rider, "No se puede andar por la vía"), "quien se mete en el túnel vuelve al andén (con un aviso)")
	for _, spot in { CFrame.new(6.5, 0, 0), CFrame.new(12, 0, 60), CFrame.new(16, 0, -70) } do
		local at = Metro.frame("Poniente", L1) * spot
		moveTo(riderRoot, at.Position) -- (los pies en el andén)
		MetroService._guardTracks()
		check((riderRoot.Position - (at.Position + Vector3.new(0, 3, 0))).Magnitude < 0.5, ("en el andén (a %.1f del centro de la vía) no te mueve nadie"):format(spot.X))
	end
end
local walker, walkerRoot = newPlayer(94, "Adolescente", 0)
moveTo(walkerRoot, train.Cars[2].Root.Position + Vector3.new(0, 3, 0))
MetroService._step(train, Metro.Dwell + 0.1)
check(MetroService._riding[walker] == train and lastMessage(walker, "Board") ~= nil, "quien entra andando en el tren se sienta al cerrarse las puertas")
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
promptOf(lostOffice, "Objetos Perdidos").Triggered:Fire(rider)
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
-- Ir de pie: se puede andar por el coche con el tren en marcha, y bajar andando en la parada
do
	while train.Phase ~= "Dwell" do
		MetroService._step(train, 0.5)
	end
	local stander, standerRoot = newPlayer(95, "Adulto", 0)
	moveTo(standerRoot, train.Cars[1].Root.Position + Vector3.new(0, 3, 0))
	MetroService._step(train, train.Timer + 0.1)
	check(MetroService._riding[stander] == train and lastMessage(stander, "Board") ~= nil, "quien entra andando viaja de pie (no le obligan a sentarse)")
	MetroService._step(train, 1)
	moveTo(standerRoot, train.Cars[2].Root.Position + Vector3.new(0, 3, 0))
	MetroService._checkPassengers()
	check(MetroService._riding[stander] == train and train.Phase == "Move", "con el tren en marcha se puede cambiar de coche sin dejar de viajar")
	local got = nil
	StoryEventsModule.connect(function(p, name, payload)
		if p == stander and name == "RodeMetro" then
			got = payload.Station
		end
	end)
	while train.Phase ~= "Dwell" do
		MetroService._step(train, 0.5)
		moveTo(standerRoot, train.Cars[2].Root.Position + Vector3.new(0, 3, 0))
	end
	local here = train.Line.Stations[train.Index]
	moveTo(standerRoot, Metro.center(here, train.Line) + Vector3.new(12, 3, 0))
	MetroService._checkPassengers()
	check(MetroService._riding[stander] == nil and got == here, "al salir por la puerta con el tren parado has bajado en esa estación")
end
-- Incidencias
do
	while train.Phase ~= "Dwell" do
		MetroService._step(train, 0.5)
	end
	MetroService._step(train, train.Timer + 0.1)
	local target = train.Line.Stations[train.Index]
	local inc = MetroService.startIncident("Cerrada", "L1", target)
	check(inc ~= nil and inc.Text:find(Metro.Stations[target].Name) ~= nil and #MetroService._incidents >= 1, "una estación se cierra y sale el aviso")
	while train.Phase ~= "Dwell" do
		MetroService._step(train, 0.5)
	end
	check(train.Line.Stations[train.Index] == target and train.DoorsOpen == false and train.Cars[1].Doors[1].Transparency == 0 and train.Timer <= 3, "en la estación cerrada el tren no abre las puertas y sigue enseguida")
	MetroService._closed[target] = nil
	MetroService._step(train, train.Timer + 0.1)
	local delay = MetroService.startIncident("Retraso", "L1")
	check(delay ~= nil and (train.Hold or 0) >= Metro.Incidents.Retraso.Hold[1] and delay.Text:find("Retraso") ~= nil, "un retraso retiene el tren en la próxima parada")
	local held = train.Hold
	while train.Phase ~= "Dwell" do
		MetroService._step(train, 0.5)
	end
	check(train.Timer >= Metro.dwellAt(train, train.Index) + held - 0.01, "el tren espera más en la estación por el retraso")
	local slow = MetroService.startIncident("Averia", "L1")
	local leg = train.Duration
	while train.Phase ~= "Move" do
		MetroService._step(train, 0.5)
	end
	check(slow ~= nil and train.Speed < Metro.Speed and slow.Alt:find("Línea 2") ~= nil, "una avería hace que el tren vaya más despacio (y te recomienda la otra línea)")
	check(train.Duration > Metro.travelTime(math.abs(train.To - train.From)) + 0.5, "con la avería el tramo tarda más")
	train.Speed = Metro.Speed
	local _ = leg
end
-- Abonos y gratis de servicio
do
	local commuter, commuterRoot = newPlayer(96, "Adulto", 100)
	profiles[commuter].Items = {}
	InventoryService.refresh(commuter)
	moveTo(commuterRoot, machine.Position + Vector3.new(0, 0, 3))
	M:Fire(commuter, "BuyPass", "Estudiante")
	check(profiles[commuter].Money == 100 and notified(commuter, "estudiantes"), "el abono estudiante es solo para estudiantes")
	M:Fire(commuter, "BuyPass", "Semana")
	local week = Metro.passById.Semana
	check(profiles[commuter].Money == 100 - week.Price and profiles[commuter].Metro.PassKind == "Semana" and profiles[commuter].Metro.PassUntil > os.time(), "compra un abono semanal en la máquina")
	local lobby = gate.Position + Vector3.new(3, -2, 0) -- (delante del torno, en el vestíbulo)
	moveTo(commuterRoot, lobby)
	promptOf(gate, "Pasar (billete)").Triggered:Fire(commuter)
	check(commuter:GetAttribute("MetroTicket") == true and InventoryService.count(commuter, Metro.TicketItem) == 0, "con abono pasa el torno sin billete")
	profiles[commuter].Metro.PassUntil = os.time() - 1
	commuter:SetAttribute("MetroTicket", nil)
	moveTo(commuterRoot, lobby)
	MetroService._passedGateAt[commuter] = nil -- (sin esperar Metro.Gate.Grace)
	promptOf(gate, "Pasar (billete)").Triggered:Fire(commuter)
	check(commuter:GetAttribute("MetroTicket") == nil and notified(commuter, "billete o un abono"), "el abono caducado ya no vale")
	local cop, copRoot = newPlayer(97, "Adulto", 0)
	cop:SetAttribute("Job", "Policia")
	moveTo(copRoot, gate.Position + Vector3.new(3, -2, 0))
	promptOf(gate, "Pasar (billete)").Triggered:Fire(cop)
	check(cop:GetAttribute("MetroTicket") == true and notified(cop, "servicio"), "de servicio (policía) el metro es gratis")
end
-- Viajeros NPC en el tren
do
	local fan = newPlayer(98, "Adulto", 0)
	train.Passengers[fan] = true
	MetroService._refreshRiders(train)
	check(#train.Riders > 0 and #train.Riders <= (MetroService._schedule().Riders or 99), "en el tren van viajeros sentados (según la hora)")
	local seatsTaken = 0
	for _, car in train.Cars do
		for _, seat in car.Seats do
			if seat:GetAttribute("NpcRider") then
				seatsTaken += 1
			end
		end
	end
	check(seatsTaken == #train.Riders, "cada viajero ocupa su asiento")
	train.Passengers[fan] = nil
	local saved = {}
	for _, other in services.Players:GetPlayers() do
		local r = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if r then
			saved[r] = r.Position
			moveTo(r, Vector3.new(9000, 0, 9000))
		end
	end
	MetroService._refreshRiders(train)
	check(#train.Riders == 0, "si no hay nadie cerca, los viajeros se van (no gastan)")
	for r, pos in saved do
		moveTo(r, pos)
	end
end
-- Taquilla con persona: el taquillero/a sale cuando hay alguien cerca y vende lo mismo que la máquina
do
	local buyer, buyerRoot = newPlayer(120, "Adulto", 50)
	profiles[buyer].Items = {}
	InventoryService.refresh(buyer)
	moveTo(buyerRoot, booth.Position + Vector3.new(0, -3, -1.5 + 6))
	MetroService._ambientTick()
	local clerk = nil
	for _, c in worldRoot:GetChildren() do
		if (c.Name == "Taquillera" or c.Name == "Taquillero") and c:IsA("Model") then
			clerk = c
		end
	end
	local hum = clerk and clerk:FindFirstChildOfClass("Humanoid")
	check(clerk ~= nil and clerk:HasTag("NamedActor") and hum ~= nil and hum.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None and hum.DisplayName == clerk.Name, "en la taquilla hay una persona (con su nombre encima)")
	local cRoot = clerk and clerk.PrimaryPart
	check(cRoot ~= nil and (cRoot.Position - booth:GetAttribute("StaffSpot")).Magnitude < 4, "el taquillero/a está detrás del mostrador")
	promptOf(booth, "Comprar billete").Triggered:Fire(buyer)
	check(lastMessage(buyer, "Tickets") ~= nil, "en la taquilla se compra igual que en la máquina")
	M:Fire(buyer, "BuyTicket", "Bono10")
	check(profiles[buyer].Money == 35 and InventoryService.count(buyer, "BilleteMetro") == 10, "la taquilla vende el bonometro")
	M:Fire(buyer, "BuyPass", "Dia")
	check(profiles[buyer].Money == 30 and profiles[buyer].Metro and profiles[buyer].Metro.PassKind == "Dia", "y también abonos")
	-- Nunca aparece al lado de un jugador
	if clerk then
		clerk:Destroy()
	end
	moveTo(buyerRoot, booth:GetAttribute("StaffSpot") + Vector3.new(0, -2, 0))
	MetroService._ambientTick()
	local again = false
	for _, c in worldRoot:GetChildren() do
		if (c.Name == "Taquillera" or c.Name == "Taquillero") and c.Parent then
			again = true
		end
	end
	check(not again, "el taquillero/a no aparece encima de nadie")
	moveTo(buyerRoot, Vector3.new(9000, 0, -9000))
end
-- Andén: los viajeros que esperan se sientan en los bancos
do
	local alightP = nil
	for _, a in services.CollectionService:GetTagged("MetroAlight") do
		if a:GetAttribute("Station") == P.Id then
			alightP = a
		end
	end
	local saved = {}
	for _, other in services.Players:GetPlayers() do
		local r = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if r then
			saved[r] = r.Position
			moveTo(r, Vector3.new(9000, 0, 9000))
		end
	end
	MetroService._ambientTick() -- (sin nadie cerca se van todos)
	local waiter, waiterRoot = newPlayer(121, "Adulto", 0)
	moveTo(waiterRoot, alightP.Position + Vector3.new(0, -3, -40))
	MetroService._ambientTick()
	local seated, tooClose = nil, false
	for _, c in worldRoot:GetChildren() do
		if c.Name == "Viajero" and c:IsA("Model") and c.PrimaryPart then
			if (c.PrimaryPart.Position - waiterRoot.Position).Magnitude < 5 then
				tooClose = true
			end
			if c:GetAttribute("UsePose") == "Sit" and (c.PrimaryPart.Position - metroBench.Position).Magnitude < 4 then
				seated = c
			end
		end
	end
	check(seated ~= nil, "en el andén hay quien espera sentado en el banco")
	check(not tooClose, "los viajeros no aparecen al lado de ningún jugador")
	if seated then
		local look = seated.PrimaryPart.CFrame.LookVector
		check(look.X < -0.9, "sentado mirando hacia la vía")
	end
	moveTo(waiterRoot, Vector3.new(9000, 0, -9000))
	for r, pos in saved do
		moveTo(r, pos)
	end
end
-- Viajeros que se cambian de vagón (andando por el pasillo, con el tren parado)
do
	local fan = newPlayer(122, "Adulto", 0)
	train.Passengers[fan] = true
	for _ = 1, 600 do
		if train.Phase == "Dwell" and train.Timer > 9 then
			break
		end
		MetroService._step(train, 0.5)
	end
	MetroService._refreshRiders(train)
	while #train.Riders > 1 do
		MetroService._removeRider(train, #train.Riders)
	end
	local npc = train.Riders[1]
	local fromCar = npc and npc:GetAttribute("MetroCar")
	local moved = npc ~= nil and train.Phase == "Dwell" and MetroService._changeCar(train, npc)
	check(moved and npc:GetAttribute("MetroCar") ~= fromCar and math.abs(npc:GetAttribute("MetroCar") - fromCar) == 1, "un viajero se cambia al vagón de al lado")
	check(moved and npc:HasTag("MetroRider") and npc:GetAttribute("ChangingCar") == nil and npc:GetAttribute("UsePose") == "Sit", "y vuelve a sentarse (y va con su coche)")
	local taken = 0
	for _, car in train.Cars do
		for _, seat in car.Seats do
			if seat:GetAttribute("NpcRider") then
				taken += 1
			end
		end
	end
	check(taken == #train.Riders, "deja libre su asiento y ocupa el nuevo")
	train.Passengers[fan] = nil
end
-- Incidencia de seguridad: bajan agentes de policía al andén y se van al acabar
do
	local alightP = nil
	for _, a in services.CollectionService:GetTagged("MetroAlight") do
		if a:GetAttribute("Station") == P.Id then
			alightP = a
		end
	end
	local inc = MetroService.startIncident("Seguridad", "L1")
	check(inc ~= nil and inc.Station == train.Line.Stations[train.Index], "incidencia de seguridad en la estación del tren")
	for _, a in services.CollectionService:GetTagged("MetroAlight") do
		if inc and a:GetAttribute("Station") == inc.Station then
			alightP = a
		end
	end
	local saved = {}
	for _, other in services.Players:GetPlayers() do
		local r = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if r then
			saved[r] = r.Position
			moveTo(r, Vector3.new(9000, 0, 9000))
		end
	end
	local watcher, watcherRoot = newPlayer(123, "Adulto", 0)
	moveTo(watcherRoot, alightP.Position + Vector3.new(2.5, -3, -4)) -- (justo por donde entran, junto a los tornos)
	MetroService._incidentTick()
	task.wait(1.5)
	local cops = inc and inc.Police or {}
	local uniform, near = #cops > 0, false
	for _, cop in cops do
		local r = cop.PrimaryPart
		if cop.Name ~= "Policía" or cop:GetAttribute("MetroPolice") ~= true then
			uniform = false
		end
		local home = cop:GetAttribute("Home")
		if typeof(home) ~= "Vector3" or (home - watcherRoot.Position).Magnitude < 5 then
			near = true
		end
		local _ = r
	end
	check(#cops >= 1 and #cops <= 2 and uniform, ("bajan agentes de policía al andén (%d)"):format(#cops))
	check(not near, "los agentes no aparecen al lado de ningún jugador")
	local said = false
	for _, cop in cops do
		if typeof(cop:GetAttribute("Says")) == "string" then
			said = true
		end
	end
	check(said, "los agentes avisan a la gente")
	MetroService._incidentTick()
	check(inc ~= nil and #inc.Police == #cops, "no bajan más agentes de la cuenta")
	moveTo(watcherRoot, Vector3.new(9000, 0, -9000))
	for _, i2 in MetroService._incidents do
		i2.Until = 0
	end
	MetroService._incidentTick()
	task.wait(0.1)
	local gone = true
	for _, cop in cops do
		if cop.Parent then
			gone = false
		end
	end
	check(inc ~= nil and inc.Police == nil and gone, "al acabar la incidencia se van (sin nadie delante)")
	train.Hold = nil
	for r, pos in saved do
		moveTo(r, pos)
	end
	local _ = watcher
end
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
anaRoot.CFrame = CFrame.new(where + Vector3.new(0, 20, 0)) -- (bajo el agua se mira el centro del cuerpo: Shared/Swim)
ana.Character.Head.CFrame = CFrame.new(where + Vector3.new(0, 21.5, 0))
D:Fire(ana, "Shoot", t2)
check(t2.Parent ~= nil and InventoryService.count(ana, "Pez_Trucha") == 1, "fuera del agua no se dispara")
-- Aire: sin aire pierdes vida; al salir se recupera; con gafas aguantas más
anaRoot.CFrame = CFrame.new(where)
ana.Character.Head.CFrame = CFrame.new(where + Vector3.new(0, 1.5, 0))
ana:SetAttribute("Oxygen", 1)
local health = anaHum.Health
task.wait(2.2)
check(anaHum.Health < health and notified(ana, "sin aire"), "sin aire pierdes vida")
anaRoot.CFrame = CFrame.new(where + Vector3.new(0, 20, 0))
ana.Character.Head.CFrame = CFrame.new(where + Vector3.new(0, 21.5, 0))
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
print("▶ Cercanías: billetes, tren en superficie, puertas, viajeros, pasos a nivel y vía")
local Rail = loadModule(ROOT .. "/shared/Rail")
local Items = loadModule(ROOT .. "/shared/Items")
local R = remotes.Rail.OnServerEvent
local L = Rail.Line
local function rp(name, cf, tags, attrs, size)
	local p = part(name, cf, tags, attrs)
	p.Size = size or Vector3.new(4, 5, 2)
	p.Parent = worldRoot
	return p
end
check(Items.get(Rail.TicketItem) ~= nil, "el billete de Cercanías es un objeto de la mochila")
-- Geometría compartida: la vía pasa por el centro de cada andén, en orden, y el andén queda a su lado
do
	local points, centers, length = Rail.path()
	local inOrder, onTrack, sideOk = true, true, true
	for i, id in L.Stations do
		if i > 1 and centers[i] <= centers[i - 1] then
			inOrder = false
		end
		if Rail.distance(Rail.center(id)) > 0.5 then
			onTrack = false
		end
		local _, t = Rail.sample(points, centers[i])
		local f = Rail.frame(id)
		local side = Vector3.new(Rail.Stations[id].Side[1], 0, Rail.Stations[id].Side[2])
		if math.abs(f.LookVector:Dot(t)) < 0.99 or f.RightVector:Dot(side) < 0.99 then
			sideOk = false
		end
	end
	check(inOrder and onTrack and centers[1] > Rail.halfTrain() and centers[#centers] < length - Rail.halfTrain(), "las estaciones están sobre la vía, en orden y con sitio para el tren entero")
	check(sideOk, "el andén de cada estación queda a un lado de la vía, paralelo a ella")
	local A = Rail.access("ValmarNorte")
	check(#A.Route >= 4 and math.abs(A.Route[1].Y - Rail.WalkY) < 0.01 and math.abs(A.Route[#A.Route].Y - Rail.Deck) < 0.01, "de la acera (abajo) al andén (arriba) por la rampa")
	local near = Rail.nearestStation(Rail.entrance("Levante") + Vector3.new(20, 0, 0))
	check(near == "Levante", "la estación más cercana a una entrada es la suya")
end
-- Pasos a nivel: las barreras bajan antes de que llegue el tren y suben cuando ha pasado
do
	local T = Rail.travelTime(2000)
	local leg = { Phase = "Move", From = 0, To = 2000, T0 = 0, Duration = T, Speed = Rail.Speed }
	local function atS(target)
		local lo, hi = 0, T
		for _ = 1, 40 do
			local mid = (lo + hi) / 2
			if Rail.positionAt(leg, mid) < target then
				lo = mid
			else
				hi = mid
			end
		end
		return lo
	end
	check(not Rail.crossingClosed(leg, 1500, 0), "con el tren lejos, el paso a nivel está abierto")
	check(Rail.crossingClosed(leg, 1500, atS(1000)), "el tren se acerca: se bajan las barreras")
	check(Rail.crossingClosed(leg, 1500, atS(1500)), "mientras pasa el tren, cerrado")
	check(not Rail.crossingClosed(leg, 1500, atS(1800)), "cuando el tren ha pasado, se abre")
	check(not Rail.crossingClosed(leg, 2400, atS(1800)), "si el tren para antes (en el andén), no cierra el paso de después")
	check(not Rail.crossingClosed({ Phase = "Dwell", S = 100, DwellEnd = 30 }, 400, 0), "con el tren parado lejos, abierto")
end
-- Estaciones (lo mínimo): botón de subir, sitio para bajar y panel; máquina en la primera
local boards, displays = {}, {}
for _, id in L.Stations do
	local f = Rail.frame(id)
	boards[id] = rp("RailBoard", f * CFrame.new(Rail.PlatformGap + 1.4, Rail.Deck + 2.5, 0), { "RailBoard" }, { Station = id, Line = L.Id })
	rp("RailAlight", f * CFrame.new(Rail.PlatformGap + 5, Rail.Deck + 3, 8), { "RailAlight" }, { Station = id, Line = L.Id }, Vector3.new(2, 2, 2))
	local display = rp("Departures", f * CFrame.new(9, Rail.Deck + 7, -30), { "RailDisplay" }, { Station = id, Line = L.Id })
	local gui = fakeInstance("SurfaceGui")
	gui.Parent = display
	local label = fakeInstance("TextLabel")
	label.Text = ""
	label.Parent = gui
	displays[id] = label
end
local first = L.Stations[1]
local f1 = Rail.frame(first)
local machine = rp("TicketMachine", f1 * CFrame.new(14, Rail.Deck + 2.8, -7), { "RailTicketMachine" }, { Station = first })
-- Tren de 3 coches (un asiento y una puerta a cada lado en cada coche)
local railPoints, centers = Rail.path()
local base = Rail.sample(railPoints, centers[1])
local trainModel = fakeInstance("Model")
trainModel.Name = "Cercanias_C1"
trainModel:SetAttribute("Line", L.Id)
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
	for _, x in { -4.4, 4.4 } do
		local door = part("Door", CFrame.new(base + Vector3.new(x, 0, 0)), { "RailDoor" })
		door.Parent = carModel
	end
end
trainModel:AddTag("RailTrain")
local RailService = loadModule(S .. "RailService")
RailService.init()
local train = RailService._trains[L.Id]
check(train ~= nil and train.Phase == "Dwell" and train.Index == 1 and train.DoorsOpen, "el tren de Cercanías espera en " .. Rail.Stations[first].Name .. " con las puertas abiertas")
local function doorsBySide(station)
	local frame = Rail.frame(station)
	local near, far, nearOpen, farClosed = 0, 0, true, true
	for _, car in train.Cars do
		local facing = if frame.RightVector:Dot(car.Root.CFrame.RightVector) >= 0 then 1 else -1
		for _, door in car.Doors do
			if (door:GetAttribute("Side") or 0) * facing > 0 then
				near += 1
				nearOpen = nearOpen and door.Transparency == 1 and door.CanCollide == false
			else
				far += 1
				farClosed = farClosed and door.Transparency == 0 and door.CanCollide ~= false
			end
		end
	end
	return near > 0 and nearOpen, far > 0 and farClosed
end
do
	local nearOpen, farClosed = doorsBySide(first)
	check(nearOpen and farClosed, "solo se abren las puertas del lado del andén")
end
-- Billete
local rider, riderRoot, riderHumanoid = newPlayer(981, "Adulto", 100)
profiles[rider].Items = {}
InventoryService.refresh(rider)
moveTo(riderRoot, boards[first].Position + Vector3.new(0, -2, 0))
promptOf(boards[first], "Subir al tren").Triggered:Fire(rider)
check(RailService._riding[rider] == nil and notified(rider, "Necesitas un billete de Cercanías"), "sin billete no se sube al tren")
moveTo(riderRoot, machine.Position)
promptOf(machine, "Comprar billete").Triggered:Fire(rider)
check(lastMessage(rider, "Tickets") ~= nil, "la máquina roja enseña los billetes")
R:Fire(rider, "BuyTicket", "Sencillo")
check(profiles[rider].Money == 97 and InventoryService.count(rider, Rail.TicketItem) == 1, "compra un billete de Cercanías")
do
	local far = newPlayer(985, "Adulto", 100)
	R:Fire(far, "BuyTicket", "Sencillo")
	check(profiles[far].Money == 100, "lejos de la máquina no se puede comprar")
end
-- Subir y viajar
moveTo(riderRoot, boards[first].Position + Vector3.new(0, -2, 0))
promptOf(boards[first], "Subir al tren").Triggered:Fire(rider)
check(riderHumanoid.SeatPart ~= nil and RailService._riding[rider] == train and lastMessage(rider, "Board") ~= nil, "sube al tren y se sienta")
check(InventoryService.count(rider, Rail.TicketItem) == 0, "al subir se gasta el billete")
RailService._updateDisplays()
check(string.find(displays[first].Text, "EN ANDÉN", 1, true) ~= nil and string.find(displays[L.Stations[2]].Text, "C1", 1, true) ~= nil, "los paneles de salidas: en andén aquí, y cuándo llega en las demás")
local etaNext, toward = Rail.eta(train, 2)
local waited, guard = 0, 0
while not (train.Index == 2 and train.Phase == "Dwell") and guard < 4000 do
	guard += 1
	waited += 0.5
	RailService._step(train, 0.5)
end
check(math.abs(waited - etaNext) <= 1.5 and toward == #L.Stations, ("el panel acierta cuándo llega el tren (%.1f s dicho, %.1f s de verdad)"):format(etaNext, waited))
local arrived = lastMessage(rider, "Arrive")
local second = L.Stations[2]
check(arrived ~= nil and arrived[2].Station == Rail.Stations[second].Name, "el tren llega a " .. Rail.Stations[second].Name .. " y te avisa")
local mid = train.Cars[2].Root.Position
local c2 = Rail.center(second)
check((Vector3.new(mid.X, 0, mid.Z) - Vector3.new(c2.X, 0, c2.Z)).Magnitude < 1 and math.abs(mid.Y - Rail.Deck) < 1, "el tren para con el centro en el andén, a su altura")
do
	local nearOpen, farClosed = doorsBySide(second)
	check(nearOpen and farClosed, "en cada estación, puertas abiertas solo del lado del andén")
end
-- Un niño sube gratis
local kid, kidRoot = newPlayer(983, "Nino", 0)
moveTo(kidRoot, boards[second].Position + Vector3.new(0, -2, 0))
promptOf(boards[second], "Subir al tren").Triggered:Fire(kid)
check(RailService._riding[kid] == train, "los niños viajan gratis")
-- Bajar
R:Fire(rider, "Alight")
task.wait()
local alightSpot = nil
for _, a in services.CollectionService:GetTagged("RailAlight") do
	if a:GetAttribute("Station") == second then
		alightSpot = a
	end
end
check(RailService._riding[rider] == nil and lastMessage(rider, "Off") ~= nil, "bajas del tren en " .. Rail.Stations[second].Name)
check(alightSpot ~= nil and (riderRoot.Position - alightSpot.Position).Magnitude < 1, "…y apareces en el andén")
-- Colarse andando sin billete: multa del revisor
local walker, walkerRoot = newPlayer(982, "Adolescente", 50)
profiles[walker].Items = {}
InventoryService.refresh(walker)
moveTo(walkerRoot, train.Cars[3].Root.Position)
RailService._step(train, train.Timer + 0.1)
check(train.Phase == "Move" and RailService._riding[walker] == train, "quien entra andando viaja al cerrarse las puertas")
check(profiles[walker].Money == 50 - Rail.Fine and notified(walker, "multa"), "sin billete, el revisor le pone una multa")
check(train.Cars[1].Doors[1].Transparency == 0 and train.Cars[1].Doors[2].Transparency == 0, "el tren cierra todas las puertas y sigue")
-- Nadie en la vía delante del tren
do
	local dir = if train.To >= train.From then 1 else -1
	local ahead = Rail.sample(railPoints, train.S + dir * (Rail.halfTrain() + 15))
	local behind = Rail.sample(railPoints, train.S - dir * 400)
	local victim, victimRoot = newPlayer(984, "Adulto", 10)
	local bystander, bystanderRoot = newPlayer(986, "Adulto", 10)
	moveTo(victimRoot, Vector3.new(ahead.X, 0.6, ahead.Z))
	moveTo(bystanderRoot, Vector3.new(behind.X, 0.6, behind.Z))
	RailService._guardTracks()
	local d = Rail.distance(victimRoot.Position)
	check(d > Rail.CarWidth / 2 + 2 and notified(victim, "Cuidado con el tren"), "quien está en la vía delante del tren se aparta (con un aviso)")
	check((bystanderRoot.Position - Vector3.new(behind.X, 3.6, behind.Z)).Magnitude < 0.5 and not notified(bystander, "Cuidado"), "lejos del tren, nadie te mueve")
	check(RailService._riding[walker] == train, "a quien va dentro del tren no se le aparta")
end
-- Un viajero que sale del tren con el tren parado ha bajado
guard = 0
while train.Phase ~= "Dwell" and guard < 4000 do
	guard += 1
	RailService._step(train, 0.5)
end
moveTo(walkerRoot, Rail.center(L.Stations[train.Index]) + Vector3.new(0, 20, 0))
RailService._checkPassengers()
check(RailService._riding[walker] == nil, "si sales por la puerta con el tren parado, has bajado")
-- De punta a punta y vuelta
guard = 0
local reachedEnd = false
while guard < 20000 do
	guard += 1
	RailService._step(train, 0.5)
	if train.Phase == "Dwell" and train.Index == #L.Stations then
		reachedEnd = true
	end
	if reachedEnd and train.Phase == "Move" then
		break
	end
end
check(reachedEnd and train.Dir == -1 and train.Index == #L.Stations - 1, "el tren llega a " .. Rail.Stations[L.Stations[#L.Stations]].Name .. " y da la vuelta")
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
-- Villa (Kit/Lite): la puerta está en la cristalera, a un lado (DoorOut: da a la calle, -Z). En venta
-- (no de vecinos), para entrar a verla
do
	local villaX = 3000
	while Properties.isNeighborHome(("Villa_%d_2400#0"):format(villaX)) do
		villaX += 10
	end
	local villaModel = building("Manzana_Villas", "Villa", Vector3.new(villaX, 10, 2400), Vector3.new(60, 20, 40))
	local villaDoor = fakeInstance("Part")
	villaDoor.Name = "Door"
	villaDoor.Size = Vector3.new(3.8, 7.4, 0.3)
	villaDoor.CFrame = CFrame.new(villaX - 20, 4, 2379.7)
	villaDoor:SetAttribute("DoorOut", Vector3.new(0, 0, -1))
	villaDoor.Parent = villaModel
end
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
-- Villa: el cartel "Entrar" está delante de su puerta (no en la cancela ni en un lateral); se entra
-- a su sala y al salir vuelves delante de la puerta
do
	local villa
	for _, b in InteriorService.all() do
		if b.Kind == "Villa" then
			villa = b
		end
	end
	local villaDoor = villa and villa.Model:FindFirstChild("Door")
	local doorAt = villaDoor and Vector3.new(villaDoor.Position.X, 0, villaDoor.Position.Z) or Vector3.new(0, 0, 0)
	check(villaDoor ~= nil and (villa.Out - Vector3.new(0, 0, -1)).Magnitude < 1e-3 and (Vector3.new(villa.Door.X, 0, villa.Door.Z) - (doorAt + villa.Out * 2.5)).Magnitude < 0.1,
		"la villa se abre por su puerta (el cartel de entrar, justo delante, mirando a la calle)")
	InteriorService.leave(friend)
	InteriorService.enter(friend, villa)
	local villaInst = villa and InteriorService.instance(villa, 0)
	local villaEntry = villaInst and villaInst.Room.Model:FindFirstChild("InteriorEntry", true)
	check(villaInst ~= nil and friend:GetAttribute("InteriorKey") == villa.Id .. ":0" and villaInst.Room.Model.Name == "Interior_Villa" and villaEntry ~= nil
		and (friendRoot.Position - villaEntry.Position).Magnitude < 5, "una villa en venta se visita: se monta su sala y apareces en su entrada")
	InteriorService.leave(friend)
	check(friend:GetAttribute("InteriorKey") == nil and villa ~= nil and (Vector3.new(friendRoot.Position.X, 0, friendRoot.Position.Z) - (doorAt + villa.Out * 5.5)).Magnitude < 1,
		"al salir de la villa vuelves a la calle, delante de su puerta")
end
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
-- Escalera de emergencia: al fondo del pasillo, puerta cortafuegos, cartel de salida, 16 escalones
-- por planta y en la planta baja la salida a la calle
local emOk = true
for f = 0, 1 do
	local m = floorModel(f)
	local esteps, fireDoor, exitSign, lamp = {}, nil, nil, nil
	for _, d in m:GetDescendants() do
		if d:GetAttribute("EmergencyStep") then
			table.insert(esteps, d)
		elseif d:HasTag("FireDoor") then
			fireDoor = d
		elseif d.Name == "ExitSign" then
			exitSign = d
		elseif d.Name == "EmergencyLight" then
			lamp = d
		end
	end
	table.sort(esteps, function(a, b)
		return a:GetAttribute("EmergencyStep") < b:GetAttribute("EmergencyStep")
	end)
	local rises = #esteps == 16
	for i = 2, #esteps do
		local dh = top(esteps[i]) - top(esteps[i - 1])
		rises = rises and dh > 0 and dh <= 1.0001
	end
	emOk = emOk and rises and fireDoor ~= nil and exitSign ~= nil and lamp ~= nil
end
local streetExit = false
for _, d in floorModel(0):GetDescendants() do
	if d.Name == "EmergencyExit" and d:HasTag("InteriorExit") then
		streetExit = true
	end
end
check(emOk and streetExit, "escalera de emergencia: puerta cortafuegos, cartel verde, luz de emergencia, 16 escalones por planta y salida a la calle")
local detailsOk = true
for _, name in { "SmokeDetector", "ElectricPanel", "EvacuationPlan", "Extinguisher", "Bin" } do
	local found = false
	for _, d in floorModel(1):GetDescendants() do
		found = found or d.Name == name
	end
	detailsOk = detailsOk and found
end
check(detailsOk, "pasillos con detalles: detectores de humo, cuadro eléctrico, plano de evacuación, extintor y papelera")
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

-- Viviendas de verdad (HousingService): ficha, timbre, llaves, privacidad, alquiler, vivienda al llegar
local Housing = loadModule(ROOT .. "/shared/Housing")
local Residents = loadModule(ROOT .. "/shared/Residents")
local HousingService = loadModule(S .. "HousingService")
HousingService.AutoAssign = false
HousingService.init()
local sheet = PropertyService.sheetOf(tower, saleFloor, saleUnit.Letter)
check(sheet ~= nil and string.match(sheet.Id, "^D%d%d%-E%d%d%d%-%d%d%d%d$") ~= nil and sheet.Floor == saleFloor and Housing.parseId(sheet.Id) ~= nil,
	"cada vivienda tiene su ficha con un ID único (" .. tostring(sheet and sheet.Id) .. ": " .. tostring(sheet and Housing.describe(sheet)) .. ")")
local seenIds, dupId, sheets = {}, false, 0
for f = 1, tower.Floors - 1 do
	for _, u in Floors.units(tower.Key, tower.Kind, tower.Upper, f) do
		local sh = PropertyService.sheetOf(tower, f, u.Letter)
		if sh then
			sheets += 1
			dupId = dupId or seenIds[sh.Id] == true
			seenIds[sh.Id] = true
		end
	end
end
check(sheets >= 20 and not dupId, ("las %d viviendas del edificio tienen IDs distintos"):format(sheets))
local topSheet = PropertyService.sheetOf(tower, tower.Floors - 1, "A")
check(topSheet ~= nil and topSheet.Type == "Atico" and table.find(topSheet.Extras, "Terraza") ~= nil, "la última planta es un ático con terraza")
-- Timbre: sin grupo ni llave, el dueño recibe el aviso y decide
walker:SetAttribute("GroupId", nil)
visitor:SetAttribute("GroupId", nil)
InteriorService.enter(visitor, tower)
visitorRoot.CFrame = CFrame.new(ownedDoor.Position)
clearInbox(visitor)
clearInbox(walker)
ownedDoor:FindFirstChild("DoorPrompt").Triggered:Fire(visitor)
local bellToken
for _, m in walker.Inbox do
	if m[1] == "Doorbell" and type(m[2]) == "table" then
		bellToken = m[2].Token
	end
end
check(bellToken ~= nil and notified(visitor, "Has llamado") and visitor:GetAttribute("InteriorKey") == tower.Id .. ":T", "timbre: al dueño le llega el aviso y la visita espera en el pasillo")
remotes.Housing.OnServerEvent:Fire(walker, "Answer", bellToken, false)
check(notified(visitor, "no puede abrirte") and visitor:GetAttribute("InteriorKey") == tower.Id .. ":T", "timbre: si el dueño no abre, no entras")
task.wait(0.3)
clearInbox(walker)
ownedDoor:FindFirstChild("DoorPrompt").Triggered:Fire(visitor)
for _, m in walker.Inbox do
	if m[1] == "Doorbell" and type(m[2]) == "table" then
		bellToken = m[2].Token
	end
end
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(walker, "Answer", bellToken, true)
check(visitor:GetAttribute("InteriorKey") == tower.Id .. ":" .. saleUnit.Id and PropertyService.access(visitor, tower, saleFloor, saleUnit.Letter) == "Guest", "timbre: si abre, pasas (y eres invitado un rato)")
-- Echar a la visita
local unitRef = { Key = tower.Key, Floor = saleFloor, Letter = saleUnit.Letter }
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(walker, "Kick", unitRef, visitor.UserId)
check(visitor:GetAttribute("InteriorKey") == tower.Id .. ":T", "el dueño puede echar a una visita (vuelve al pasillo)")
InteriorService.leave(visitor) -- (a la calle)
-- Llaves: se dan, valen aunque el dueño no esté en su casa, y se quitan
local third, thirdRoot = newPlayer(901, "Adulto", 100)
third.DisplayName = "Tercera"
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(walker, "GiveKey", unitRef, third.UserId)
check(PropertyService.access(third, tower, saleFloor, saleUnit.Letter) == "Guest" and notified(third, "te ha dado una llave"), "llaves: con llave entras (y te avisan)")
local ownerRec = PropertyService.ownerOf(tower, saleFloor, saleUnit.Letter)
check(ownerRec ~= nil and ownerRec.Access ~= nil and ownerRec.Access[tostring(third.UserId)] == "Tercera", "llaves: se guardan con la vivienda (valen en todos los servidores)")
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(walker, "Privacy", unitRef, "Cerrada")
check(PropertyService.access(third, tower, saleFloor, saleUnit.Letter) == "Stranger", "privacidad «Cerrada»: ni con llave")
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(walker, "Privacy", unitRef, "Llaves")
check(PropertyService.access(third, tower, saleFloor, saleUnit.Letter) == "Guest", "privacidad «Llaves»: los que tienen llave, sí")
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(walker, "TakeKey", unitRef, third.UserId)
check(PropertyService.access(third, tower, saleFloor, saleUnit.Letter) == "Stranger", "llaves: al quitarla, ya no entras")
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(visitor, "GiveKey", unitRef, visitor.UserId)
remotes.Housing.OnServerEvent:Fire(third, "Privacy", unitRef, "Grupo")
check(PropertyService.ownerOf(tower, saleFloor, saleUnit.Letter).Privacy == "Llaves", "solo el dueño cambia las llaves y la privacidad")
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(walker, "Privacy", unitRef, "Grupo")
-- Alquiler: se paga cada día de juego; sin dinero, avisos y deuda; al tercer impago se pierde
local renter, renterRoot = newPlayer(902, "Adulto", 5000)
renter.DisplayName = "Inquilina"
profiles[renter].Properties = {}
local rentDoor, rentUnit
for f = 1, tower.Floors - 1 do
	if not rentDoor then
		rentDoor, rentUnit = doorWith(f, "ForSale")
	end
end
local rentFloor = rentDoor:GetAttribute("Floor")
InteriorService.enter(renter, tower)
InteriorService.goToUnit(renter, tower, rentFloor, rentUnit.Letter)
local rentPrompt
for _, d in InteriorService.instance(tower, rentFloor, rentUnit.Letter).Room.Model:GetDescendants() do
	if d.ClassName == "ProximityPrompt" and d.ActionText == "Alquilar vivienda" then
		rentPrompt = d
	end
end
check(rentPrompt ~= nil, "las viviendas libres también se alquilan")
local rentPrice = Housing.rent(PropertyService.priceOf(tower, rentFloor, rentUnit.Letter))
rentPrompt.Triggered:Fire(renter)
local lease = profiles[renter].Properties[1]
check(lease ~= nil and lease.Contract == "Alquiler" and lease.Rent == rentPrice and profiles[renter].Money == 5000 - rentPrice and PropertyService.access(renter, tower, rentFloor, rentUnit.Letter) == "Owner",
	"alquilada: paga el primer día (" .. rentPrice .. ") y es suya mientras pague")
local day = 20 * 60
HousingService.collectRent(renter, (lease.Since or os.time()) + day + 1)
check(profiles[renter].Money == 5000 - 2 * rentPrice and lease.Unpaid == 0, "al día siguiente se cobra el alquiler")
profiles[renter].Money = 0
clearInbox(renter)
HousingService.collectRent(renter, lease.RentDue + 1)
check(lease.Unpaid == 1 and lease.Debt == rentPrice and notified(renter, "aviso 1 de 3"), "sin dinero: deuda y aviso (no te echan)")
HousingService.collectRent(renter, lease.RentDue + 1)
check(lease.Unpaid == 2 and PropertyService.access(renter, tower, rentFloor, rentUnit.Letter) == "Owner", "segundo impago: otro aviso, sigue siendo suya")
HousingService.collectRent(renter, lease.RentDue + 1)
check(#profiles[renter].Properties == 0 and PropertyService.access(renter, tower, rentFloor, rentUnit.Letter) ~= "Owner" and profiles[renter].Housing.Debt == 3 * rentPrice,
	"al tercer impago se pierde el alquiler (y queda la deuda)")
InteriorService.leave(renter)
InteriorService.leave(renter)
-- Vivienda al llegar: a cada uno la suya, al azar, sin repetir aunque lleguen a la vez
local newcomers = {}
for i = 1, 6 do
	local p = newPlayer(910 + i, "Nino", 0)
	p.DisplayName = "Nuevo" .. i
	profiles[p].Properties = {}
	profiles[p].Housing = {}
	table.insert(newcomers, p)
end
-- (el mismo orden "aleatorio" para todos: todos quieren el mismo piso a la vez)
local function sameRng()
	return { NextInteger = function(_, a, b) return b end }
end
local done = 0
for i, p in newcomers do
	task.spawn(function()
		local ok, err = pcall(HousingService.assignStarter, p, sameRng())
		if not ok then
			print("[assignStarter] " .. tostring(err))
		end
		done += 1
	end)
end
local waited = 0
while done < #newcomers and waited < 5 do
	waited += task.wait()
end
local homes, repeated, allHave = {}, false, true
for _, p in newcomers do
	local entry = profiles[p].Properties[1]
	allHave = allHave and entry ~= nil and entry.Contract == "Inicial" and profiles[p].Housing.Assigned == true
	if entry then
		local k = entry.Key .. "#" .. entry.Floor .. entry.Letter
		repeated = repeated or homes[k] == true
		homes[k] = true
		local b = InteriorService.byKey(entry.Key)
		allHave = allHave and b ~= nil and PropertyService.access(p, b, entry.Floor, entry.Letter) == "Owner"
	end
end
check(allHave, "vivienda al llegar: a cada jugador nuevo le toca un piso suyo")
check(not repeated, "vivienda al llegar: nunca el mismo piso a dos jugadores (aunque lleguen a la vez)")
local firstHome = profiles[newcomers[1]].Properties[1]
HousingService.assignStarter(newcomers[1])
check(#profiles[newcomers[1]].Properties == 1 and profiles[newcomers[1]].Properties[1] == firstHome, "vivienda al llegar: solo una vez (al volver, sigue siendo la misma)")
check(PropertyService.goHome(newcomers[1]) and newcomers[1]:GetAttribute("InteriorKey") ~= nil, "«Ir a casa» te lleva a tu piso")
InteriorService.leave(newcomers[1])
InteriorService.leave(newcomers[1])
-- Vida en el portal: vecinos que entran y salen y un repartidor que llama al portero
InteriorService.goTo(visitor, tower, 0)
InteriorService.stepTowers()
local courier = HousingService.lobbyScene(tower, "Repartidor")
local chat = HousingService.lobbyScene(tower, "Llega")
check(courier ~= nil and courier.Parent ~= nil and courier:GetAttribute("LobbyNeighbor") == "Repartidor" and chat ~= nil and chat:GetAttribute("LobbyNeighbor") == "Llega",
	"en el portal hay vida: llega un repartidor y un vecino que vuelve a casa")
local t0l = os.clock()
local delivered = false
while os.clock() - t0l < 12 and not delivered do
	for _, line in speechLog do
		if type(line) == "table" and type(line.Text) == "string" and (string.find(line.Text, "aquete para el", 1, true) or string.find(line.Text, "pedido para el", 1, true)) then
			delivered = true
		end
	end
	task.wait(0.2)
end
check(delivered, "el repartidor llama al portero automático: «¡Paquete para el …!» (o «Traigo un pedido para el …»)")
InteriorService.leave(visitor)
-- Vecinos con su vida: a media mañana muchos están trabajando; por la noche, en casa (o durmiendo)
local working, home23 = 0, 0
for i = 1, 60 do
	local person = Residents.person("prueba#" .. i)
	if Residents.where(person, 11) == "Trabajo" then
		working += 1
	end
	if Residents.where(person, 22) == "Casa" then
		home23 += 1
	end
end
check(working >= 20 and home23 >= 30, ("vecinos con rutina: a las 11 trabajan %d de 60; a las 22 están en casa %d"):format(working, home23))
local somebody = Residents.person("prueba#1")
check(somebody.Age >= 20 and somebody.Name ~= "" and Residents.describe(somebody):find(" años, ", 1, true) ~= nil, "cada vecino tiene nombre, edad, trabajo y horario: " .. Residents.describe(somebody))
local answered, text = HousingService.neighborAnswer(tower, { Id = "3" }, 11)
local person3 = Residents.person(Properties.unitKey(tower.Key, "3"))
check(answered == (Residents.where(person3, 11) == "Casa") and (answered or string.find(text, person3.Name, 1, true) ~= nil), "si llamas a un vecino que no está, te dicen dónde anda")
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
-- El ascensor de verdad: se llama desde el rellano, viene, abre, se entra, se elige planta y sube
local lift = InteriorService.lift(tower)
check(lift ~= nil and lift.Floor == 0 and lift.Cabin.Model.Parent ~= nil, "el edificio tiene su ascensor (cabina en la planta baja)")
local function waitLift(floor, seconds)
	local t0 = os.clock()
	while os.clock() - t0 < seconds and not (lift.Floor == floor and not lift.Busy and lift.DoorsOpen) do
		task.wait(0.05)
	end
	return lift.Floor == floor and lift.DoorsOpen
end
local function doorsOf(f)
	local out = {}
	for _, d in floorModel(f):GetDescendants() do
		if d:HasTag("LiftLandingDoor") then
			table.insert(out, d)
		end
	end
	return out
end
local call6
for _, d in floorModel(6):GetDescendants() do
	if d:HasTag("InteriorElevator") then
		for _, c in d:GetChildren() do
			if c.ClassName == "ProximityPrompt" then
				call6 = c
			end
		end
	end
end
check(call6 ~= nil and call6.ActionText == "Llamar al ascensor", "en cada rellano hay botón para llamar al ascensor")
call6.Triggered:Fire(walker)
task.wait(0.4)
local midClosed = lift.Busy
for f = 0, 8 do
	if floorModel(f) then
		for _, d in doorsOf(f) do
			midClosed = midClosed and d.CanCollide ~= false
		end
	end
end
check(midClosed, "mientras el ascensor se mueve, todas las puertas de rellano están cerradas (no se cae nadie al hueco)")
check(waitLift(6, 10), "el ascensor sube hasta la 6ª y abre")
local open6 = #doorsOf(6) == 2
for _, d in doorsOf(6) do
	open6 = open6 and d.CanCollide == false
end
check(open6 and lift.Cabin.Doors[1].CanCollide == false, "con la cabina en la 6ª se abren sus puertas y las del rellano")
local cabinFloor = lift.Cabin.Model:FindFirstChild("CabinFloor")
check(cabinFloor ~= nil and math.abs((cabinFloor.Position.Y + 0.2) - (origin.Y + 6 * Floors.Height)) < 0.05, "la cabina queda a ras del suelo de la planta")
-- Sin entrar no se puede elegir planta
clearInbox(walker)
InteriorService.openElevator(walker, tower)
remotes.Interior.OnServerEvent:Fire(walker, "Floor", 11)
check(notified(walker, "Entra en el ascensor") and lift.Floor == 6, "el panel de plantas se usa desde dentro de la cabina")
-- Dentro: a la 11ª
walkerRoot.CFrame = CFrame.new(cabinFloor.Position + Vector3.new(0, 3.2, 0))
InteriorService.openElevator(walker, tower)
remotes.Interior.OnServerEvent:Fire(walker, "Floor", 11)
local rodeAttr = false
local t0 = os.clock()
while os.clock() - t0 < 3 and not rodeAttr do
	rodeAttr = walker:GetAttribute("LiftTower") ~= nil
	task.wait(0.05)
end
check(rodeAttr, "al arrancar, el cliente sabe que vas dentro (para moverte fluido)")
check(waitLift(11, 15), "el ascensor sube contigo hasta la 11ª y abre")
InteriorService.stepTowers() -- (las plantas de alrededor se montan en la siguiente vuelta)
local after = InteriorService.builtFloors(tower)
check(walker:GetAttribute("TowerFloor") == 11 and walker:GetAttribute("LiftTower") == nil and math.abs(walkerRoot.Position.Y - (origin.Y + 11 * Floors.Height + 3.2)) < 0.5
	and table.find(after, 11) ~= nil and table.find(after, 9) ~= nil, "llegas a la 11ª dentro de la cabina (y se montan las plantas de alrededor)")
local closed6 = true
for _, d in (floorModel(6) and doorsOf(6)) or {} do
	closed6 = closed6 and d.CanCollide ~= false
end
check(closed6, "las puertas de la 6ª se quedaron cerradas")
local display = lift.Cabin.Display
check(display ~= nil and display.Text == "11", "la pantalla dice en qué planta está")
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
;(function() -- (en su propia función: la de fuera ya no tiene sitio para más variables)
print("▶ Edificios, segunda fase: estilo por distrito, vecinos por la escalera y el ascensor, encargos")
-- Estilo por distrito: el portal y los pasillos van con el distrito (lujo, obrero, moderno…)
HousingService.LobbyLife = false -- (aquí mandan las pruebas)
local TowerW = loadModule(ROOT .. "/server/World/Tower")
local Errands = loadModule(ROOT .. "/shared/Errands")
local luxPlan = TowerW.plan("Prueba_10_10", "🏢 Prueba", "Portal", "Piso", 6, "Oeste")
local surPlan = TowerW.plan("Prueba_10_10", "🏢 Prueba", "Portal", "Piso", 6, "Sur")
local offPlan = TowerW.plan("Prueba_10_10", "🏢 Prueba", "OficinaLobby", "Oficina", 6, "Oeste")
local plainPlan = TowerW.plan("Prueba_10_10", "🏢 Prueba", "Portal", "Piso", 6, nil)
check(luxPlan.Style.Theme == "Lujo" and surPlan.Style.Theme == "Obrero" and offPlan.Style.Theme == nil and plainPlan.Style.Theme == nil
	and luxPlan.Style.Wall ~= surPlan.Style.Wall and luxPlan.Style.FloorMaterial ~= surPlan.Style.FloorMaterial,
	"estilo por distrito: Oeste de lujo, Sur obrero (colores y suelo distintos); las oficinas, con el suyo")
local centro1, centro2 = Floors.themeFor("Centro", "Portal_5_5"), Floors.themeFor("Centro", "Portal_5_5")
check(centro1 == centro2 and (centro1 == "Clasico" or centro1 == "Moderno") and Floors.themeFor(nil, "x") == nil, "el mismo edificio, siempre con el mismo estilo (" .. tostring(centro1) .. ")")
local function namesIn(model)
	local out = {}
	for _, d in model:GetDescendants() do
		out[d.Name] = (out[d.Name] or 0) + 1
	end
	return out
end
local luxLobby = TowerW.buildFloor(lab, CFrame.new(0, 7000, 0), luxPlan, 0)
local luxUp = TowerW.buildFloor(lab, CFrame.new(0, 7000, 0), luxPlan, 1)
local surLobby = TowerW.buildFloor(lab, CFrame.new(400, 7000, 0), surPlan, 0)
local surUp = TowerW.buildFloor(lab, CFrame.new(400, 7000, 0), surPlan, 1)
local plainUp = TowerW.buildFloor(lab, CFrame.new(800, 7000, 0), plainPlan, 1)
local nl, nlu, ns = namesIn(luxLobby.Model), namesIn(luxUp.Model), namesIn(surLobby.Model)
check(luxLobby.Model:GetAttribute("Theme") == "Lujo" and nl.Chandelier == 1 and nl.LobbyMirror == 1 and nl.Runner == 1 and nlu.Runner == 1 and nlu.Chandelier == nil,
	"portal de lujo: lámpara de araña, espejo y alfombra (y la alfombra en cada pasillo)")
check(surLobby.Model:GetAttribute("Theme") == "Obrero" and ns.NoticeBoard == 1 and (ns.Wainscot or 0) >= 2, "portal obrero: tablón de la comunidad y pared pintada a media altura")
-- (la pared pintada no tapa ninguna puerta)
local wainOk = true
for _, d in surUp.Model:GetDescendants() do
	if d.Name == "Wainscot" then
		for _, door in TowerW.doors(surPlan, 1) do
			local x = 400 + door.CFrame.Position.X
			local sameWall = math.abs((door.CFrame.Position.Z) - (d.Position.Z)) < 1
			if sameWall and math.abs(d.Position.X - x) < d.Size.X / 2 then
				wainOk = false
			end
		end
	end
end
check(wainOk, "la pared pintada se corta en las puertas")
check(surUp.Parts - plainUp.Parts <= 12 and luxUp.Parts - plainUp.Parts <= 12, ("el estilo cuesta pocas piezas por planta (+%d, +%d)"):format(surUp.Parts - plainUp.Parts, luxUp.Parts - plainUp.Parts))
local towerDistrict = InteriorService.districtOf(tower)
InteriorService.goTo(visitor, tower, 0)
InteriorService.stepTowers()
local towerInst = InteriorService.tower(tower)
check(towerInst.Tower.Plan.Style.Theme == Floors.themeFor(towerDistrict, tower.Key), "cada bloque del mapa lleva el estilo de su distrito (" .. tostring(towerDistrict) .. ": " .. tostring(towerInst.Tower.Plan.Style.Theme) .. ")")
-- La escalera andando: el camino va por encima de los escalones de verdad
local stepParts = {}
for _, m in { luxLobby.Model, luxUp.Model } do
	for _, d in m:GetDescendants() do
		if d:GetAttribute("Step") or d.Name == "MidLanding" or d.Name == "FloorSlab" then
			table.insert(stepParts, d)
		end
	end
end
local path = Floors.stairPath(luxPlan.W, 0, 2)
local onSteps, smooth = true, true
for i, p in path do
	local world = Vector3.new(p.X, 7000 + p.Y, p.Z)
	if p.Y < 12 then
		local found = false
		for _, s in stepParts do
			local l = world - s.Position
			if math.abs(l.X) <= s.Size.X / 2 + 0.01 and math.abs(l.Z) <= s.Size.Z / 2 + 0.01 and math.abs((s.Position.Y + s.Size.Y / 2) - world.Y) < 0.02 then
				found = true
			end
		end
		onSteps = onSteps and found
	end
	if i > 1 then
		local q = path[i - 1]
		local run = math.sqrt((p.X - q.X) ^ 2 + (p.Z - q.Z) ^ 2)
		smooth = smooth and math.abs(p.Y - q.Y) <= 0.75 * run + 0.01
	end
end
local down = Floors.stairPath(luxPlan.W, 2, 0)
check(onSteps and path[1].Y == 0 and path[#path].Y == 24 and down[1].Y == 24 and down[#down].Y == 0, "escalera andando: cada paso del camino pisa un escalón, el descansillo o el rellano (y se baja por el mismo)")
check(smooth, "escalera andando: nunca sube más de 0,75 por cada stud (como los escalones)")
for _, b in { luxLobby, luxUp, surLobby, surUp, plainUp } do
	b.Model:Destroy()
end

-- Vecinos que suben de verdad: con alguien en el portal, un vecino llega, sube a su planta
-- (montada) por la escalera o en el ascensor y entra por su puerta
local function waitGone(npc, seconds, watch)
	local t0 = os.clock()
	while npc and npc.Parent and os.clock() - t0 < seconds do
		if watch then
			watch(npc)
		end
		task.wait(0.05)
	end
	return npc ~= nil and npc.Parent == nil
end
local builtNow = InteriorService.builtFloors(tower)
check(#builtNow == 3 and builtNow[3] == 2, "con una visita en el portal: montadas la baja, la 1ª y la 2ª")
local stairNpc = HousingService.lobbyScene(tower, "Llega", "Escalera")
check(stairNpc ~= nil, "llega un vecino al portal")
waitGone(stairNpc, 20)
local reached = stairNpc and stairNpc:GetAttribute("HomeReached")
local reachedFloor = reached and tonumber(string.match(reached, "^(%d+)"))
check(stairNpc:GetAttribute("Travel") == "Escalera" and reachedFloor ~= nil and reachedFloor >= 1 and reachedFloor <= 2,
	"sube andando por la escalera hasta su planta (montada) y entra por su puerta (" .. tostring(reached) .. ")")
local lift = InteriorService.lift(tower)
local topY = 0
local liftNpc = HousingService.lobbyScene(tower, "Llega", "Ascensor")
waitGone(liftNpc, 60, function(npc)
	local root = npc.PrimaryPart
	if root then
		topY = math.max(topY, root.Position.Y)
	end
end)
local liftHome = liftNpc and liftNpc:GetAttribute("HomeReached")
local liftFloor = liftHome and tonumber(string.match(liftHome, "^(%d+)"))
check(liftNpc ~= nil and liftNpc:GetAttribute("Travel") == "Ascensor" and liftFloor ~= nil and lift.Floor == liftFloor,
	"otro coge el ascensor de verdad: lo llama, entra, la cabina sube a su planta y sale a su puerta (" .. tostring(liftHome) .. ")")
check(topY > towerInst.Tower.Origin.Position.Y + Floors.Height * 0.8, "va dentro de la cabina mientras sube")
local builtAfter = InteriorService.builtFloors(tower)
check(#builtAfter == 3 and builtAfter[3] == 2, "los vecinos no hacen montar plantas: siguen la baja, la 1ª y la 2ª")
-- Nunca aparece un vecino a menos de 5 studs de un jugador
local blocker, blockerRoot = newPlayer(950, "Adulto", 100)
blocker.DisplayName = "Encargada"
for _, callback in loadedCallbacks do
	pcall(callback, blocker, profiles[blocker])
end
InteriorService.goTo(blocker, tower, 0)
local liftSpot, doorSpot
for _, d in InteriorService.tower(tower).Tower.Built[0].Model:GetDescendants() do
	if d:HasTag("InteriorElevator") then
		liftSpot = d.Position
	elseif d:HasTag("InteriorEntry") then
		doorSpot = d.Position
	end
end
visitorRoot.CFrame = CFrame.new(doorSpot)
blockerRoot.CFrame = CFrame.new(liftSpot)
check(HousingService.lobbyScene(tower, "Llega") == nil and HousingService.lobbyScene(tower, "Sale") == nil, "si hay jugadores en la puerta y en el ascensor, ningún vecino aparece encima")
blockerRoot.CFrame = CFrame.new(liftSpot + Vector3.new(12, 0, 0))
local okSpawn = HousingService.lobbyScene(tower, "Sale")
local spawnFar = true
local spawnedAt = okSpawn and okSpawn:GetAttribute("SpawnedAt")
spawnFar = spawnedAt ~= nil
if spawnedAt then
	for _, p in { visitorRoot, blockerRoot } do
		spawnFar = spawnFar and (Vector3.new(p.Position.X, 0, p.Position.Z) - Vector3.new(spawnedAt.X, 0, spawnedAt.Z)).Magnitude >= 5
	end
end
check(okSpawn ~= nil and spawnFar, "con el ascensor libre, el vecino sale por él (a más de 5 studs de nadie)")
waitGone(okSpawn, 5)
InteriorService.leave(visitor)
-- En las plantas de arriba: un vecino sale de su casa y baja por la escalera a la planta montada más baja
InteriorService.goTo(blocker, tower, 6)
InteriorService.stepTowers()
local upBuilt = InteriorService.builtFloors(tower)
local downNpc = HousingService.floorScene(tower, "Baja", "Escalera")
waitGone(downNpc, 15)
local upBuiltAfter = InteriorService.builtFloors(tower)
check(downNpc ~= nil and downNpc:GetAttribute("Travel") == "Escalera" and upBuilt[1] == 4 and upBuiltAfter[1] == 4 and #upBuiltAfter == #upBuilt,
	"en la 6ª: un vecino sale de su casa y baja andando (solo por las plantas montadas: " .. table.concat(upBuiltAfter, ",") .. ")")
local upNpc = HousingService.floorScene(tower, "Sube", "Escalera")
waitGone(upNpc, 15)
local upHome = upNpc and upNpc:GetAttribute("HomeReached")
check(upNpc ~= nil and upHome ~= nil and tonumber(string.match(upHome, "^(%d+)")) > 4, "y otro sube desde abajo hasta su puerta (" .. tostring(upHome) .. ")")

-- Encargos de los vecinos
check(not Errands.shouldOffer({ Since = 0 }, 10, 0) and Errands.shouldOffer({ Since = 0 }, 30, 0) and not Errands.shouldOffer({ Since = 0 }, 30, 0.99)
	and not Errands.shouldOffer({ Since = 0, LastAt = 20 }, 60, 0) and not Errands.shouldOffer({ Since = 0, Active = true }, 999, 0),
	"encargos: no nada más llegar, no a cada rato (espera entre uno y otro) y nunca con otro en marcha")
local homesE = {
	{ Floor = 1, Letter = "A", Label = "1ºA", UnitKey = "k#1" },
	{ Floor = 1, Letter = "B", Label = "1ºB", UnitKey = "k#1B" },
	{ Floor = 5, Letter = "B", Label = "5ºB", UnitKey = "k#5B" },
}
local picked = Errands.pick(homesE, { 0, 0, 0 }, "Entrega")
check(picked ~= nil and picked.From.UnitKey == "k#1" and picked.To.Floor == 5 and Errands.title(picked) == "Entrega en el 5ºB", "encargos: el paquete va a otra planta («" .. (picked and Errands.title(picked) or "?") .. "»)")
local errClock = 10000
HousingService.errandClock = function()
	return errClock
end
profiles[blocker].Housing = { Home = { Key = tower.Key, Floor = saleFloor, Letter = saleUnit.Letter } }
InteriorService.goTo(blocker, tower, 0)
check(HousingService.errandSpot(blocker) == "Portal", "encargos: tu portal cuenta como «en casa»")
blocker:SetAttribute("InteriorKey", tower.Id .. ":" .. saleUnit.Id)
check(HousingService.errandSpot(blocker) == "Casa", "y tu piso también")
blocker:SetAttribute("InteriorKey", offices.Id .. ":T")
check(HousingService.errandSpot(blocker) == nil, "en otro edificio, no")
HousingService.stepErrands()
InteriorService.goTo(blocker, tower, 0)
local savedChance = Errands.Chance
Errands.Chance = 1
clearInbox(blocker)
HousingService.stepErrands()
local function offerIn(p)
	for _, m in p.Inbox do
		if m[1] == "ErrandOffer" and type(m[2]) == "table" then
			return m[2]
		end
	end
	return nil
end
check(offerIn(blocker) == nil, "encargos: nada más llegar al portal, nadie te pide nada")
errClock += Errands.FirstDelay + 1
HousingService.stepErrands()
local autoOffer = offerIn(blocker)
check(autoOffer ~= nil and type(autoOffer.Text) == "string" and autoOffer.Money > 0 and notified(blocker, "te para en el portal"), "encargos: al rato, un vecino te para en el portal y te pide un favor")
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(blocker, "ErrandAnswer", autoOffer.Token, false)
check(HousingService.errandOf(blocker) == nil and notified(blocker, "Otro día"), "«Ahora no»: no pasa nada")
clearInbox(blocker)
errClock += 60
HousingService.stepErrands()
check(offerIn(blocker) == nil, "encargos: después, un buen rato sin pedirte nada (no es pesado)")
Errands.Chance = savedChance
-- Entrega en el …: recoger en los buzones y llevarlo a su puerta
local function errandPrompt(action)
	local inst = InteriorService.tower(tower)
	for _, built in inst.Tower.Built do
		for _, d in built.Model:GetDescendants() do
			if d.ClassName == "ProximityPrompt" and d.Name == "ErrandPrompt" and d.ActionText == action then
				return d
			end
		end
	end
	return nil
end
clearInbox(blocker)
local offerE = HousingService.offerErrand(blocker, tower, "Entrega", "Casa")
check(offerE ~= nil and notified(blocker, "Llaman a tu puerta"), "un vecino te llama a la puerta de casa para pedirte un favor")
task.wait(0.3)
remotes.Housing.OnServerEvent:Fire(blocker, "ErrandAnswer", offerIn(blocker).Token, true)
local errand = HousingService.errandOf(blocker)
check(errand ~= nil and errand.Kind == "Entrega" and errand.To.Id ~= nil and string.match(errand.To.Id, "^D%d%d%-E%d%d%d%-%d%d%d%d$") ~= nil, "aceptado: «" .. (errand and Errands.title(errand) or "?") .. "» (" .. tostring(errand and errand.To.Id) .. ")")
local tracker
for _, m in blocker.Inbox do
	if m[1] == "Errand" and type(m[2]) == "table" and m[2].Title then
		tracker = m[2]
	end
end
check(tracker ~= nil and string.find(tracker.Goal, "buzones", 1, true) ~= nil, "en pantalla, lo que toca: recoger el paquete en los buzones")
local mailPrompt = errandPrompt("Recoger paquete")
check(mailPrompt ~= nil and mailPrompt:GetAttribute("OwnerUserId") == blocker.UserId and mailPrompt.Parent.Name == "MailboxWall", "en los buzones del portal: «Recoger paquete» (solo lo ves tú)")
InteriorService.goTo(blocker, tower, errand.To.Floor)
InteriorService.stepTowers()
local deliverPrompt = errandPrompt("Entregar paquete")
check(deliverPrompt ~= nil and deliverPrompt.Parent:GetAttribute("UnitId") == Floors.unitId(errand.To.Floor, errand.To.Letter), "en la puerta del " .. errand.To.Label .. ": «Entregar paquete»")
clearInbox(blocker)
deliverPrompt.Triggered:Fire(blocker)
check(notified(blocker, "Primero recoge el paquete") and HousingService.errandOf(blocker) ~= nil, "sin el paquete no se puede entregar")
InteriorService.goTo(blocker, tower, 0)
InteriorService.stepTowers()
mailPrompt = errandPrompt("Recoger paquete")
mailPrompt.Triggered:Fire(visitor)
check(not errand.HasPackage, "otro jugador no puede recoger tu paquete")
mailPrompt.Triggered:Fire(blocker)
check(errand.HasPackage and errandPrompt("Recoger paquete") == nil, "recoges el paquete")
InteriorService.goTo(blocker, tower, errand.To.Floor)
InteriorService.stepTowers()
local money0 = profiles[blocker].Money
clearInbox(blocker)
errandPrompt("Entregar paquete").Triggered:Fire(blocker)
check(HousingService.errandOf(blocker) == nil and profiles[blocker].Money == money0 + Errands.Rewards.Entrega.Money and notified(blocker, "Encargo hecho") and errandPrompt("Entregar paquete") == nil,
	"entregado: te pagan y el encargo se acaba (" .. tostring(profiles[blocker].Money - money0) .. ")")
-- Busca a … en su piso: solo si está en casa (su horario)
task.wait(0.3)
clearInbox(blocker)
HousingService.offerErrand(blocker, tower, "Visita", "Portal")
remotes.Housing.OnServerEvent:Fire(blocker, "ErrandAnswer", offerIn(blocker).Token, true)
local visit = HousingService.errandOf(blocker)
check(visit ~= nil and visit.Kind == "Visita" and string.find(Errands.title(visit), "Busca a ", 1, true) == 1, "otro encargo: «" .. (visit and Errands.title(visit) or "?") .. "»")
local person = Residents.person(visit.To.UnitKey)
local awayAt, homeAt
for h = 0, 23.5, 0.5 do
	local w = Residents.where(person, h)
	if w ~= "Casa" and not awayAt then
		awayAt = h
	elseif w == "Casa" and not homeAt then
		homeAt = h
	end
end
InteriorService.goTo(blocker, tower, visit.To.Floor)
InteriorService.stepTowers()
local findPrompt = errandPrompt("Buscar a " .. Errands.firstName(person.Name))
check(findPrompt ~= nil, "en su puerta: «Buscar a " .. Errands.firstName(person.Name) .. "»")
services.Lighting.ClockTime = awayAt
clearInbox(blocker)
money0 = profiles[blocker].Money
findPrompt.Triggered:Fire(blocker)
check(notified(blocker, "Vuelve más tarde") and HousingService.errandOf(blocker) ~= nil and profiles[blocker].Money == money0, "si no está (trabajo, compra o durmiendo), te dicen dónde anda y que vuelvas luego")
services.Lighting.ClockTime = homeAt
findPrompt.Triggered:Fire(blocker)
check(HousingService.errandOf(blocker) == nil and profiles[blocker].Money == money0 + Errands.Rewards.Visita.Money, "cuando está en casa, le das el recado y te pagan")
services.Lighting.ClockTime = 21
-- Caduca si no lo haces
task.wait(0.3)
clearInbox(blocker)
HousingService.offerErrand(blocker, tower, "Entrega", "Portal")
remotes.Housing.OnServerEvent:Fire(blocker, "ErrandAnswer", offerIn(blocker).Token, true)
check(HousingService.errandOf(blocker) ~= nil, "otro encargo más")
errClock += Errands.Expire + 1
HousingService.stepErrands()
check(HousingService.errandOf(blocker) == nil and notified(blocker, "Se acabó el tiempo") and errandPrompt("Recoger paquete") == nil and errandPrompt("Entregar paquete") == nil,
	"si no lo haces a tiempo, caduca (y se quitan sus carteles)")
HousingService.errandClock = os.clock
HousingService.LobbyLife = true
InteriorService.leave(blocker)
InteriorService.leave(visitor)
end)()
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

;(function()
print("▶ Gimnasio: recepción, máquinas, ritmo, fuerza en el cuerpo, deportistas y monitor/a")
local Gym = loadModule(ROOT .. "/shared/Gym")
-- Un gimnasio de verdad (el mismo interior que en el mapa: World/Kit/GymKit)
local GymKit = loadModule(ROOT .. "/server/World/Kit/GymKit")
local building = fakeInstance("Model")
building.Name = "GimnasioValmar"
building.Parent = worldRoot
GymKit.interior(building, CFrame.new(6000, 1, 6000), "Gimnasio de Prueba")
local tagged = services.CollectionService:GetTagged("GymMachine")
local kinds = {}
for _, m in tagged do
	kinds[m:GetAttribute("Kind")] = true
end
local kindCount = 0
for _ in kinds do
	kindCount += 1
end
check(#tagged >= 15 and kindCount >= 14, ("el gimnasio tiene %d máquinas de %d tipos"):format(#tagged, kindCount))
local desk = services.CollectionService:GetTagged("GymReception")[1]
check(desk ~= nil and typeof(desk:GetAttribute("StaffSpot")) == "Vector3", "hay recepción con sitio para la recepcionista")
check(#services.CollectionService:GetTagged("GymFountain") == 1 and #services.CollectionService:GetTagged("Bench") >= 2, "fuente de agua y bancos para descansar")
local lockers, mirrors = 0, 0
for _, d in building:GetDescendants() do
	if d.Name == "Locker" then
		lockers += 1
	elseif d.Name == "Mirror" then
		mirrors += 1
	end
end
check(lockers >= 6 and mirrors >= 2, "vestuarios con taquillas y espejos")

local GymService = loadModule(S .. "GymService")
local clock, now = 1000, 5000000
GymService._clock = function()
	return clock
end
GymService._now = function()
	return now
end
local callbacksBefore = #loadedCallbacks
GymService.init()
local function loaded(p)
	for i = callbacksBefore + 1, #loadedCallbacks do
		loadedCallbacks[i](p, profiles[p])
	end
end
check(jobProviders.Handler_MonitorGimnasio ~= nil, "el tablón del gimnasio lleva al oficio de monitor/a")
check(promptOf(desk, "Recepción") ~= nil, "la recepción tiene su cartel")
local receptionist = nil
for _, d in desk.Parent:GetDescendants() do
	if d.Name == "Recepcionista" then
		receptionist = d
	end
end
check(receptionist ~= nil, "la recepcionista está detrás del mostrador")
local function machineOf(kind)
	for _, m in services.CollectionService:GetTagged("GymMachine") do
		if m:GetAttribute("Kind") == kind then
			return m
		end
	end
	return nil
end
local cinta, banca, comba = machineOf("Cinta"), machineOf("PressBanca"), machineOf("Comba")
check(promptOf(cinta, "Entrenar") ~= nil and promptOf(banca, "Entrenar") ~= nil, "cada máquina tiene su cartel «Entrenar»")
check(promptOf(banca, "Entrenar"):GetAttribute("MinStage") == "Adolescente" and promptOf(cinta, "Entrenar"):GetAttribute("MinStage") == "Nino", "los niños solo ven los carteles de las máquinas ligeras")

local athlete, athleteRoot = newPlayer(91, "Adulto", 200)
profiles[athlete].Hunger, profiles[athlete].Energy = 100, 100
loaded(athlete)
check(athlete:GetAttribute("GymStrength") == 0 and athlete:GetAttribute("GymPass") == nil, "empieza sin fuerza y sin entrada")
-- Sin entrada no se entrena
promptOf(cinta, "Entrenar").Triggered:Fire(athlete)
check(athlete:GetAttribute("Training") == nil and notified(athlete, "Necesitas entrada"), "sin entrada te mandan a la recepción")
-- Recepción: entrada del día
moveTo(athleteRoot, desk.Position + Vector3.new(0, 0, -3))
promptOf(desk, "Recepción").Triggered:Fire(athlete)
local info = lastMessage(athlete, "Reception")
check(info ~= nil and info[2].Active == false and #info[2].Passes == 2 and info[2].Passes[1].Price == 5 and info[2].Passes[2].Price == 60, "la recepción enseña la entrada (5 €) y el abono (60 €)")
local G = remotes.Gym.OnServerEvent
G:Fire(athlete, "Buy", "Dia")
check(profiles[athlete].Money == 195 and athlete:GetAttribute("GymPass") == "Dia" and GymService.data(athlete).PassUntil == now + Gym.daySeconds(Config.DayLengthMinutes), "paga la entrada del día")
-- Lejos de la recepción no se compra nada
moveTo(athleteRoot, Vector3.new(0, 0, 0))
G:Fire(athlete, "Buy", "Mes")
check(profiles[athlete].Money == 195, "lejos de la recepción no se puede comprar")

-- Entrenar en el press de banca
promptOf(banca, "Entrenar").Triggered:Fire(athlete)
local anchor = banca:FindFirstChild("GymAnchor")
check(athlete:GetAttribute("Training") == "PressBanca" and athleteRoot.Anchored == true, "se pone a entrenar (quieto en la máquina)")
check((athleteRoot.Position - (anchor.Position + Vector3.new(0, 3 - anchor.Size.Y / 2, 0))).Magnitude < 0.01, "colocado justo en su sitio de la máquina")
check(athlete.Character:GetAttribute("GymExercise") == "PressBanca" and athlete.Character:HasTag("GymTraining"), "todos lo ven entrenar (etiqueta y ejercicio en el personaje)")
local start = lastMessage(athlete, "Start")
check(start ~= nil and start[2].SetReps == Gym.SetReps and start[2].Kind == "PressBanca", "sale la barra del ritmo")
G:Fire(athlete, "Rep", "Bien")
G:Fire(athlete, "Rep", "Bien")
check(GymService._sessions[athlete].Reps == 1, "no cuentan dos repeticiones seguidas sin darle tiempo")
check(athlete.Character:GetAttribute("GymRep") == 1, "cada repetición se ve (GymRep)")
table.clear(needsChanges)
for _ = 2, Gym.SetReps do
	clock += 1
	G:Fire(athlete, "Rep", "Perfecto")
end
local set = lastMessage(athlete, "Set")
check(set ~= nil and set[2].Sets == 1 and set[2].GainStrength > 0 and set[2].GainCardio == 0, "serie completa: sube la Fuerza")
check((athlete:GetAttribute("GymStrength") or 0) > 0, "y se guarda (atributo GymStrength)")
local spent = false
for _, c in needsChanges do
	if c[1] == athlete and c[2] < 0 and c[3] < 0 then
		spent = true
	end
end
check(spent, "entrenar gasta hambre y energía")
-- Sin fuerzas
local tired = false
for _ = 1, 20 do
	clock += 1
	G:Fire(athlete, "Rep", "Bien")
	if lastMessage(athlete, "Tired") then
		tired = true
		break
	end
end
check(tired, "si no descansas, te quedas sin fuerzas")
clock += 10
GymService._regen(10)
check(GymService._sessions[athlete].Effort == Gym.EffortMax, "descansando se recupera el esfuerzo")
clock += 1
G:Fire(athlete, "Miss")
check(GymService._sessions[athlete].Effort == Gym.EffortMax - Gym.MissEffort, "fallar el ritmo también cansa")

-- El cuerpo se ensancha (LifeService de verdad, con el tamaño de su edad)
local savedLife = mocks[S .. "LifeService"]
mocks[S .. "LifeService"] = nil
local savedCache = cache[S .. "LifeService"]
cache[S .. "LifeService"] = nil
local RealLife = loadModule(S .. "LifeService")
mocks[S .. "LifeService"] = savedLife
cache[S .. "LifeService"] = savedCache
athlete.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
athlete:SetAttribute("GymStrength", 100)
RealLife.refresh(athlete)
local humanoid = athlete.Character:FindFirstChildOfClass("Humanoid")
local width = humanoid:FindFirstChild("BodyWidthScale")
local depth = humanoid:FindFirstChild("BodyDepthScale")
check(width ~= nil and depth ~= nil and math.abs(width.Value - 1.25) < 1e-6 and math.abs(depth.Value - 1.25) < 1e-6, "con 100 de Fuerza: un 25 % más ancho")
athlete:SetAttribute("GymStrength", 0)
RealLife.refresh(athlete)
check(width ~= nil and math.abs(width.Value - 1) < 1e-6, "y vuelve a su medida si pierde la fuerza")
-- Con otra medida de base (su avatar) y tamaño de niño: se multiplica
local kidLook = newPlayer(95, "Nino", 0)
local kidHumanoid = kidLook.Character:FindFirstChildOfClass("Humanoid")
kidHumanoid.WalkSpeed = 16
local base = FakeInstanceLib.new("NumberValue")
base.Name = "BodyWidthScale"
base.Value = 0.9
base.Parent = kidHumanoid
kidLook:SetAttribute("GymStrength", 100)
RealLife.refresh(kidLook)
check(math.abs(base.Value - 0.9 * 1.25) < 1e-6 and math.abs(kidLook.Character:GetScale() - Config.StageBody.Nino.Scale) < 1e-6, "se multiplica con su medida y con el tamaño de su edad")
base.Value = 1 -- (otro sistema le cambia el aspecto)
RealLife.refresh(kidLook)
check(math.abs(base.Value - 1.25) < 1e-6, "si cambia de aspecto, la fuerza se aplica sobre el nuevo")
-- En Roblox, ScaleTo también multiplica las medidas del Humanoid (ancho, fondo, alto, cabeza). Antes,
-- con tamaño de niño y algo de fuerza, cada vez que se volvía a aplicar el cuerpo (bajarse de un
-- vehículo, entrenar…) el ancho encogido se tomaba por el normal: el personaje quedaba cada vez más delgado.
do
	local plainScaleTo = Fake.ScaleTo
	Fake.ScaleTo = function(self, scale)
		local old = self:GetScale()
		local h = self:FindFirstChildOfClass("Humanoid")
		for _, name in { "BodyWidthScale", "BodyDepthScale", "BodyHeightScale", "HeadScale" } do
			local v = h and h:FindFirstChild(name)
			if v then
				v.Value = v.Value * scale / old
			end
		end
		plainScaleTo(self, scale)
	end
	local thin = newPlayer(961, "Nino", 0)
	local thinHumanoid = thin.Character:FindFirstChildOfClass("Humanoid")
	thinHumanoid.WalkSpeed = 16
	thin:SetAttribute("GymStrength", 40)
	RealLife.refresh(thin)
	local w = thinHumanoid:FindFirstChild("BodyWidthScale")
	local first = w and w.Value / thin.Character:GetScale()
	for _ = 1, 5 do
		RealLife.refresh(thin) -- (como al bajarse de la bici cinco veces)
	end
	local after = w and w.Value / thin.Character:GetScale()
	Fake.ScaleTo = plainScaleTo
	check(
		first ~= nil and after ~= nil and math.abs(first - Gym.bodyScale(40)) < 1e-6 and math.abs(after - first) < 1e-6
			and math.abs(thin.Character:GetScale() - Config.StageBody.Nino.Scale) < 1e-6,
		("volver a aplicar el cuerpo no adelgaza al personaje (ancho %.2f → %.2f)"):format(first or -1, after or -1)
	)
end
athlete:SetAttribute("GymStrength", GymService.data(athlete).Strength)

-- Dejar la máquina
G:Fire(athlete, "Stop")
check(athlete:GetAttribute("Training") == nil and athleteRoot.Anchored == false, "«Dejar» te baja de la máquina")
check(athlete.Character:GetAttribute("GymExercise") == nil and not athlete.Character:HasTag("GymTraining"), "y deja de hacer el ejercicio")
local exit = banca:GetAttribute("Exit")
check((Vector3.new(athleteRoot.Position.X, 0, athleteRoot.Position.Z) - Vector3.new(exit.X, 0, exit.Z)).Magnitude < 0.01, "se aparta a un lado de la máquina")
check(notified(athlete, "Buen entreno"), "te dice cómo ha ido el entreno")

-- Niños y bebés
local kid, kidRoot = newPlayer(92, "Nino", 50)
profiles[kid].Hunger, profiles[kid].Energy = 100, 100
loaded(kid)
moveTo(kidRoot, desk.Position + Vector3.new(0, 0, -3))
G:Fire(kid, "Buy", "Dia")
check(profiles[kid].Money == 47, "los niños pagan la mitad (3 €)")
promptOf(banca, "Entrenar").Triggered:Fire(kid)
check(kid:GetAttribute("Training") == nil and notified(kid, "para mayores"), "un niño no puede usar el press de banca")
promptOf(comba, "Entrenar").Triggered:Fire(kid)
check(kid:GetAttribute("Training") == "Comba", "pero sí la comba")
local baby, babyRoot = newPlayer(93, "Bebe", 50)
profiles[baby].Hunger, profiles[baby].Energy = 100, 100
loaded(baby)
moveTo(babyRoot, desk.Position + Vector3.new(0, 0, -3))
G:Fire(baby, "Buy", "Dia")
check(profiles[baby].Money == 50 and notified(baby, "bebés"), "un bebé no puede apuntarse")
promptOf(cinta, "Entrenar").Triggered:Fire(baby)
check(baby:GetAttribute("Training") == nil, "ni entrenar")
-- Máquina ocupada por otro jugador
promptOf(comba, "Entrenar").Triggered:Fire(athlete)
check(athlete:GetAttribute("Training") == nil and notified(athlete, "ocupada"), "si otro jugador está en la máquina, está ocupada")
G:Fire(kid, "Stop")

-- Cansado: no se entrena
profiles[athlete].Energy = 5
promptOf(cinta, "Entrenar").Triggered:Fire(athlete)
check(athlete:GetAttribute("Training") == nil and notified(athlete, "Te falta energía para entrenar"), "con muy poca energía no se puede entrenar")
profiles[athlete].Energy = 100

-- Deportistas (NPC) cuando hay alguien cerca, y te dejan su máquina
moveTo(athleteRoot, desk.Position + Vector3.new(0, 0, 4))
GymService._tick()
GymService._tick()
local npcs = {}
for _, d in worldRoot:FindFirstChild("Deportistas"):GetChildren() do
	if d:HasTag("GymTraining") then
		table.insert(npcs, d)
	end
end
check(#npcs >= 2, ("hay %d deportistas entrenando"):format(#npcs))
local npc = npcs[1]
local npcMachine = nil
for _, m in services.CollectionService:GetTagged("GymMachine") do
	if npc and m:GetAttribute("MachineId") == npc:GetAttribute("GymMachine") then
		npcMachine = m
	end
end
local repBefore = npc and npc:GetAttribute("GymRep") or 0
clock += 20
GymService._tick()
check(npc ~= nil and (npc:GetAttribute("GymRep") or 0) > repBefore, "los deportistas hacen sus repeticiones")
if npcMachine then
	promptOf(npcMachine, "Entrenar").Triggered:Fire(athlete)
end
check(npcMachine ~= nil and athlete:GetAttribute("Training") == npcMachine:GetAttribute("Kind") and npc.Parent == nil, "un deportista te deja su máquina")
G:Fire(athlete, "Stop")

-- Monitor/a de gimnasio
local coach, coachRoot = newPlayer(94, "Adulto", 0)
profiles[coach].Hunger, profiles[coach].Energy = 100, 100
loaded(coach)
jobProviders.Handler_MonitorGimnasio.Start(coach)
check(coach:GetAttribute("Job") == "MonitorGimnasio", "empieza de monitor/a")
moveTo(coachRoot, desk.Position + Vector3.new(2, 0, 4))
for _, gymInfo in GymService._gyms do
	gymInfo.NextRequest = 0
end
GymService._tick()
local helpPrompt = nil
for _, d in worldRoot:FindFirstChild("Deportistas"):GetDescendants() do
	if d.ClassName == "ProximityPrompt" and d.ActionText == "Ayudar" then
		helpPrompt = d
	end
end
check(helpPrompt ~= nil and helpPrompt:GetAttribute("JobOnly") == "MonitorGimnasio", "un deportista pide ayuda (solo lo ve el monitor)")
check(coach:GetAttribute("TaskText") ~= nil, "al monitor le marca a quién ayudar")
local jobEvents = 0
local conn = StoryEventsModule.connect(function(p, name, payload)
	if p == coach and name == "JobTaskDone" and payload.JobId == "MonitorGimnasio" then
		jobEvents += 1
	end
end)
if helpPrompt then
	helpPrompt.Triggered:Fire(coach)
end
check(profiles[coach].Money == Config.Jobs.MonitorGimnasio.Pay and jobEvents == 1, "ayudar le paga y cuenta para la historia")
-- Entrenar con un monitor cerca: sube más y el monitor se lleva propina
local moneyCoach = profiles[coach].Money
clock += 5
moveTo(athleteRoot, cinta:FindFirstChild("GymAnchor").Position)
promptOf(cinta, "Entrenar").Triggered:Fire(athlete)
for _ = 1, Gym.SetReps do
	clock += 2
	G:Fire(athlete, "Rep", "Bien")
end
check(lastMessage(athlete, "Set") ~= nil and lastMessage(athlete, "Set")[2].Monitor == true, "entrenando cerca del monitor ganas más")
check(profiles[coach].Money > moneyCoach, "y el monitor se lleva una propina")
G:Fire(athlete, "Stop")
if conn and conn.Disconnect then
	conn:Disconnect()
end
jobProviders.Handler_MonitorGimnasio.Quit(coach)
check(coach:GetAttribute("Job") == nil, "acaba el turno de monitor/a")

-- Fuente de agua
table.clear(needsChanges)
promptOf(services.CollectionService:GetTagged("GymFountain")[1], "Beber agua").Triggered:Fire(athlete)
check(#needsChanges == 1 and needsChanges[1][3] > 0, "beber agua da un poco de energía")

-- Días sin entrenar: se pierde un poco (y la entrada caduca)
local data = GymService.data(athlete)
local before = data.Strength
now += Gym.daySeconds(Config.DayLengthMinutes) * 10
GymService.applyDecay(athlete)
check(data.Strength < before and data.Strength > before * 0.8, "tras 10 días sin entrenar pierde un poco de fuerza")
local after = data.Strength
GymService.applyDecay(athlete)
check(data.Strength == after, "y no se vuelve a quitar lo mismo")
promptOf(cinta, "Entrenar").Triggered:Fire(athlete)
check(athlete:GetAttribute("Training") == nil, "la entrada del día ya ha caducado")
end)()

;(function()
print("▶ Granja: fincas, bancales, corral, cooperativa, obrador y supermercado")
local Farming = loadModule(ROOT .. "/shared/Farming")
local town = worldRoot:FindFirstChild("Town")
if not town then
	town = fakeInstance("Folder")
	town.Name = "Town"
	town.Parent = worldRoot
end
local farm = fakeInstance("Model")
farm.Name = "Granja"
farm.Parent = town
for i = 1, 10 do
	local row = part("Crop", CFrame.new(3000 + i * 6, 0.25, 3050))
	row.Size = Vector3.new(5, 0.5, 64)
	row.Parent = farm
end
local barn = fakeInstance("Model")
barn.Name = "Granero"
barn.WorldPivot = CFrame.new(3030, 0, 3000)
barn.Parent = farm
local barnWalls = part("Walls", CFrame.new(3030, 5, 3000))
barnWalls.Size = Vector3.new(26, 10, 20)
barnWalls.Parent = barn
for _, p in collection:GetTagged("SuperStock") do
	p:SetAttribute("Index", 1)
end
local FarmService = loadModule(S .. "FarmService")
local clock = 100000
FarmService._clock = function()
	return clock
end
FarmService.init()
local fincasFolder = worldRoot:FindFirstChild("Fincas")
local signs, stakes = {}, {}
for _, d in fincasFolder:GetDescendants() do
	if d.Name == "CartelFinca" then
		table.insert(signs, d)
	elseif d.Name == "Estaca" then
		table.insert(stakes, d)
	end
end
check(#signs == 2 and #stakes == 8, ("10 filas de cultivo = 2 fincas de 4 bancales (%d carteles, %d estacas)"):format(#signs, #stakes))
local coop = fincasFolder:FindFirstChild("Cooperativa")
check(coop ~= nil and promptOf(coop, "Cooperativa") ~= nil and promptOf(coop, "Obrador") ~= nil and promptOf(coop, "Vender cosecha") ~= nil, "delante del granero hay una cooperativa con tienda, obrador y venta")
local function fire(player, ...)
	task.wait(0.16)
	remotes.Farm.OnServerEvent:Fire(player, ...)
end
local farmer, farmerRoot = newPlayer(380, "Adulto", 1000)
profiles[farmer].Items = {}
profiles[farmer].Slots = {}
local baby = newPlayer(381, "Bebe", 0)
local sign = signs[1]
promptOf(sign, "Quedarme esta finca").Triggered:Fire(baby)
check(notified(baby, "pequeño"), "un bebé no puede quedarse una finca")
moveTo(farmerRoot, sign.Position)
promptOf(sign, "Quedarme esta finca").Triggered:Fire(farmer)
check(farmer:GetAttribute("FincaAt") ~= nil and notified(farmer, "es tuya"), "un adulto se queda la finca")
local myStakes = {}
for _, st in stakes do
	if st.Parent == sign.Parent then
		table.insert(myStakes, st)
	end
end
table.sort(myStakes, function(a, b)
	return a.Position.X < b.Position.X
end)
local stake = myStakes[1]
local other = newPlayer(382, "Adulto", 100)
promptOf(stake, "Plantar").Triggered:Fire(other)
check(notified(other, "es de"), "en una finca ajena no se puede plantar")
moveTo(farmerRoot, stake.Position)
promptOf(stake, "Plantar").Triggered:Fire(farmer)
local panel = lastMessage(farmer, "Panel")
check(panel ~= nil and panel[2].Id == "Seeds" and #panel[2].Rows >= 3, "al tocar un bancal vacío sale la lista de semillas")
local money0 = profiles[farmer].Money
fire(farmer, "Plant", 1, "Lechuga")
check(profiles[farmer].Money == money0 - Farming.cropById.Lechuga.Seed and profiles[farmer].Farm.Plots["1"].Crop == "Lechuga", "sin semillas, las compra y planta al momento")
fire(farmer, "Plant", 1, "Olivo")
check(profiles[farmer].Farm.Plots["1"].Crop == "Lechuga", "no se planta encima de otra cosa ni sin nivel")
local ready = profiles[farmer].Farm.Plots["1"].ReadyAt
check(promptOf(stake, "Regar") ~= nil, "el bancal plantado pide riego")
promptOf(stake, "Regar").Triggered:Fire(farmer)
check(profiles[farmer].Farm.Plots["1"].Watered and profiles[farmer].Farm.Plots["1"].ReadyAt < ready, "regar hace que tarde menos")
local plants = fincasFolder:FindFirstChild("Finca1") and fincasFolder.Finca1:FindFirstChild("Plot1")
check(plants ~= nil and #plants:GetChildren() > 0, "en el bancal se ven las plantas")
clock += 10000
promptOf(stake, "Ver").Triggered:Fire(farmer) -- el aviso aún no se ha refrescado: da igual el texto
check(InventoryService.count(farmer, "Agro_Lechuga") >= Farming.cropById.Lechuga.Yield[1] + 1 and profiles[farmer].Farm.Plots["1"] == nil, "cuando está listo, se cosecha a la mochila y el bancal queda libre")
check((farmer:GetAttribute("FarmXp") or 0) > 0, "cosechar da experiencia de agricultor")
-- Cooperativa
moveTo(farmerRoot, coop.Mostrador.Position)
promptOf(coop, "Cooperativa").Triggered:Fire(farmer)
check(lastMessage(farmer, "Panel")[2].Id == "Coop" and lastMessage(farmer, "Panel")[2].Tab == "Semillas", "la cooperativa abre en semillas")
fire(farmer, "BuySeed", "Trigo", 5)
check(InventoryService.count(farmer, "Semilla_Trigo") == 5, "compra 5 de semillas de trigo")
fire(farmer, "BuySeed", "Olivo", 1)
check(InventoryService.count(farmer, "Semilla_Olivo") == 0, "los árboles que piden nivel no se venden")
fire(farmer, "BuyAnimal", "Gallina")
fire(farmer, "BuyFeed", 5)
check(#profiles[farmer].Farm.Animals == 1 and InventoryService.count(farmer, Farming.Feed) == 5, "compra una gallina y pienso")
fire(farmer, "BuyAnimal", "Vaca")
check(#profiles[farmer].Farm.Animals == 1, "la vaca pide más nivel")
-- Trigo: plantar con semilla, cosechar y hacer harina en el obrador
moveTo(farmerRoot, myStakes[2].Position)
local moneyBefore = profiles[farmer].Money
fire(farmer, "Plant", 2, "Trigo")
check(profiles[farmer].Money == moneyBefore and InventoryService.count(farmer, "Semilla_Trigo") == 4, "con semillas, planta sin pagar")
clock += 10000
promptOf(myStakes[2]).Triggered:Fire(farmer)
local wheat = InventoryService.count(farmer, "Agro_Trigo")
check(wheat >= 6, ("cosecha trigo (%d)"):format(wheat))
-- Corral: dar de comer y recoger
local trough = sign.Parent:FindFirstChild("Abrevadero")
moveTo(farmerRoot, trough.Position)
promptOf(trough, "Atender animales").Triggered:Fire(farmer)
check(profiles[farmer].Farm.Animals[1].ReadyAt ~= nil and InventoryService.count(farmer, Farming.Feed) == 4, "atender da de comer a la gallina (1 pienso)")
clock += 1000
promptOf(trough, "Atender animales").Triggered:Fire(farmer)
check(InventoryService.count(farmer, "Agro_Huevos") == 2 and profiles[farmer].Farm.Animals[1].ReadyAt ~= nil, "después recoge 2 huevos y le vuelve a dar de comer")
local herd = fincasFolder.Finca1:FindFirstChild("Herd")
check(herd ~= nil and herd:FindFirstChild("Gallina") ~= nil, "la gallina se ve en el corral")
-- Obrador
moveTo(farmerRoot, coop.Mostrador.Position)
fire(farmer, "Make", "Harina", 2)
check(InventoryService.count(farmer, "Agro_Harina") == 2 and InventoryService.count(farmer, "Agro_Trigo") == wheat - 6, "en el molino, 6 de trigo son 2 sacos de harina")
local extraWheat = InventoryService.count(farmer, "Agro_Trigo") - 2
if extraWheat > 0 then
	InventoryService.remove(farmer, "Agro_Trigo", extraWheat) -- la cosecha es al azar: nos quedamos con 2
end
fire(farmer, "Make", "Harina", 1)
check(InventoryService.count(farmer, "Agro_Harina") == 2 and notified(farmer, "Te faltan ingredientes"), "sin trigo suficiente no hay más harina")
fire(farmer, "Make", "Queso", 1)
check(InventoryService.count(farmer, "Agro_Queso") == 0 and notified(farmer, "nivel 4"), "el queso pide nivel 4")
fire(farmer, "Make", "Pizza", 1)
check(notified(farmer, "cocina de tu restaurante"), "los platos se cocinan en un restaurante, no en el obrador")
moveTo(farmerRoot, Vector3.new(0, 0, 0))
fire(farmer, "Make", "Pan", 1)
check(InventoryService.count(farmer, "Agro_Pan") == 0, "lejos de la cooperativa no se usa el obrador")
-- Vender a la cooperativa
moveTo(farmerRoot, coop.Mostrador.Position)
local m1 = profiles[farmer].Money
fire(farmer, "Sell", "Agro_Huevos", 1)
check(profiles[farmer].Money == m1 + Farming.sellPrice("Agro_Huevos", "Coop") and InventoryService.count(farmer, "Agro_Huevos") == 1, "vende un huevo a la cooperativa")
-- Supermercado: paga más y llena la estantería
InventoryService.add(farmer, "Agro_Leche", 5)
local stockPoint = collection:GetTagged("SuperStock")[1]
local milkShelf
for _, shelf in collection:GetTagged("SuperShelf") do
	if shelf:GetAttribute("Product") == "Leche" then
		milkShelf = shelf
	end
end
milkShelf:SetAttribute("Stock", 0)
moveTo(farmerRoot, stockPoint.Position)
local m2 = profiles[farmer].Money
local expected = 0
for _, id in Farming.ProductOrder do
	if Farming.Products[id].Grocery then
		expected += InventoryService.count(farmer, id) * Farming.sellPrice(id, "Super")
	end
end
promptOf(stockPoint, "Entregar productos del campo").Triggered:Fire(farmer)
check(profiles[farmer].Money == m2 + expected and InventoryService.count(farmer, "Agro_Leche") == 0 and InventoryService.count(farmer, "Agro_Huevos") == 0, "el supermercado compra leche, huevos y lechugas, más caros")
check(milkShelf:GetAttribute("Stock") >= 5, "la leche de la granja se pone en su estantería")
check(InventoryService.count(farmer, "Agro_Harina") == 2, "lo que el supermercado no vende (harina) te lo quedas")
-- Se va del juego: la finca queda libre (lo plantado sigue en sus datos)
fire(farmer, "Plant", 3, "Trigo")
players.PlayerRemoving:Fire(farmer)
local label = sign:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel")
check(label.Text == "FINCA LIBRE", "al irse, la finca queda libre")
_G.__farmer = farmer
end)()

;(function()
print("▶ Negocios: locales, gasolineras y hoteles")
local Business = loadModule(ROOT .. "/shared/Business")
local building = { Id = 7, Key = "Bloque_4000_4000", Kind = "Local", Walkable = false, Door = Vector3.new(4000, 0.4, 4000), Out = Vector3.new(0, 0, -1), Title = "🏬 Comercio y viviendas", Floors = 3 }
local building2 = { Id = 8, Key = "Bloque_4100_4000", Kind = "Local", Walkable = false, Door = Vector3.new(4100, 0.4, 4000), Out = Vector3.new(0, 0, -1), Title = "🏬 Comercio y viviendas", Floors = 3 }
-- Filtro de Roblox de mentira: tapa con # lo que lleve "Prohibida"
services.TextService = {
	FilterStringAsync = function(_, text)
		return {
			GetNonChatStringForBroadcastAsync = function()
				return (text:gsub("Prohibida", "#########"))
			end,
		}
	end,
}
local resets, left = 0, 0
local Interior = {
	Hooks = {},
	all = function()
		return { building, building2 }
	end,
	reset = function()
		resets += 1
	end,
	leave = function()
		left += 1
	end,
}
mocks[S .. "InteriorService"] = Interior
-- Gasolinera con su poste y surtidor
local town = worldRoot:FindFirstChild("Town")
local gasModel = fakeInstance("Model")
gasModel.Name = "Gasolinera"
gasModel.Parent = town
local pylon = part("Pylon", CFrame.new(-290, 6, -310))
pylon.Size = Vector3.new(2, 12, 2)
pylon.Parent = gasModel
fuelPump.Parent = gasModel
local BusinessService = loadModule(S .. "BusinessService")
local bclock = 500000
BusinessService._clock = function()
	return bclock
end
BusinessService.init()
local keys = {}
for key, premise in BusinessService._premises do
	if premise.Kind ~= "Local" or premise.Building == building then
		keys[premise.Kind] = key
	end
end
check(keys.Local ~= nil and keys.Gas ~= nil and keys.Hotel ~= nil, "encuentra los locales, las gasolineras y los hoteles")
local L = keys.Local
local function fire(player, ...)
	task.wait(0.16)
	remotes.Business.OnServerEvent:Fire(player, ...)
end
local owner, ownerRoot = newPlayer(390, "Adulto", 60000)
profiles[owner].Items = {}
profiles[owner].Slots = {}
owner:SetAttribute("InteriorKey", "7:0")
local teen = newPlayer(391, "Adolescente", 99999)
teen:SetAttribute("InteriorKey", "7:0")
fire(teen, "BuyPremise", L)
check(notified(teen, "mayor de edad") and BusinessService._index()[L] == nil, "un adolescente no puede comprar un local")
local price = Business.premisePrice("Local", L)
fire(owner, "BuyPremise", L)
check(profiles[owner].Money == 60000 - price and BusinessService._index()[L].Owner == 390, "un adulto compra el local")
check(lastMessage(owner, "Panel")[2].Id == "Setup", "después elige qué negocio abrir")
fire(teen, "BuyPremise", L)
check(profiles[teen].Money == 99999, "un local con dueño no se vende dos veces")
fire(owner, "Open", L, "Gasolinera")
check(BusinessService._getRecord(L, true).Type == nil, "en un local no se puede abrir una gasolinera")
fire(owner, "Open", L, "Fruteria")
local rec = BusinessService._getRecord(L, true)
check(rec.Type == "Fruteria" and rec.Open and rec.Name == "Frutas " .. owner.Name, "abre una frutería con su nombre")
check(resets > 0, "la sala del local se rehace con el negocio")
-- Dentro del local: cartel, comprar, gestionar
local room = fakeInstance("Model")
room.Parent = worldRoot
local register = part("Register", CFrame.new(4010, 4, 4020))
register.Parent = room
local counterPart = part("Counter", CFrame.new(4010, 2, 4020))
counterPart.Parent = room
Interior.Hooks.Decorate({ Floor = 0, Building = building, Room = { Model = room } })
check(promptOf(register, "Comprar") ~= nil and promptOf(register, "Gestionar") ~= nil and room:FindFirstChild("CartelNegocio") ~= nil, "dentro hay cartel, «Comprar» y «Gestionar»")
check(promptOf(counterPart, "Cocina") == nil, "una frutería no tiene cocina")
-- Existencias desde la mochila y precios
InventoryService.add(owner, "Agro_Manzana", 30)
InventoryService.add(owner, "Agro_Pizza", 2)
fire(owner, "Stock", L, "Agro_Manzana", 30)
fire(owner, "Stock", L, "Agro_Pizza", 2)
rec = BusinessService._getRecord(L, true)
check(rec.Stock.Agro_Manzana == 30 and InventoryService.count(owner, "Agro_Manzana") == 0, "pone 30 manzanas a la venta desde la mochila")
check(rec.Stock.Agro_Pizza == nil and InventoryService.count(owner, "Agro_Pizza") == 2, "una frutería no puede vender pizzas")
local ref = Business.Goods.Agro_Manzana.Ref
fire(owner, "Price", L, "Agro_Manzana", 1)
check(Business.priceOf(BusinessService._getRecord(L, true), "Agro_Manzana") == ref + Business.priceStep(Business.Goods.Agro_Manzana), "sube el precio")
-- Un cliente compra en el mostrador
local buyer = newPlayer(392, "Adulto", 100)
profiles[buyer].Items = {}
profiles[buyer].Slots = {}
buyer:SetAttribute("InteriorKey", "7:0")
promptOf(register, "Comprar").Triggered:Fire(buyer)
check(lastMessage(buyer, "Panel")[2].Id == "Shop", "«Comprar» abre la tienda")
local unit = Business.priceOf(BusinessService._getRecord(L, true), "Agro_Manzana")
fire(buyer, "Buy", L, "Agro_Manzana", 2)
rec = BusinessService._getRecord(L, true)
check(InventoryService.count(buyer, "Agro_Manzana") == 2 and profiles[buyer].Money == 100 - unit * 2, "el cliente compra 2 manzanas")
check(rec.Stock.Agro_Manzana == 28 and rec.Till == unit * 2 and notified(owner, "ha comprado"), "el dinero va a la caja y el dueño se entera")
local outside = newPlayer(393, "Adulto", 100)
fire(outside, "Buy", L, "Agro_Manzana", 1)
check(profiles[outside].Money == 100, "desde fuera del local no se compra")
-- Los vecinos compran solos
bclock += 3600
local units, money = BusinessService._simulate(L)
rec = BusinessService._getRecord(L, true)
check(units > 0 and money > 0 and rec.Stock.Agro_Manzana == 28 - units, ("en una hora los vecinos compran %d manzanas (+$%d)"):format(units, money))
local till = math.floor(rec.Till)
local before = profiles[owner].Money
fire(owner, "Collect", L)
check(profiles[owner].Money == before + till and BusinessService._getRecord(L, true).Till < 1, "recoge la caja")
fire(owner, "Toggle", L)
fire(buyer, "Buy", L, "Agro_Manzana", 1)
check(InventoryService.count(buyer, "Agro_Manzana") == 2 and notified(buyer, "cerrado"), "cerrado no se puede comprar")
fire(owner, "Toggle", L)
fire(outside, "Collect", L)
check(notified(outside, "no es tuyo"), "nadie más puede recoger tu caja")
-- Gasolinera: mayorista, precio y repostajes
local G = keys.Gas
local anchor = BusinessService._premises[G].Anchor
moveTo(ownerRoot, anchor.Position)
owner:SetAttribute("InteriorKey", nil)
fire(owner, "BuyPremise", G)
fire(owner, "Open", G, "Gasolinera")
fire(owner, "Order", G, "W_Gasolina", 1)
local grec = BusinessService._getRecord(G, true)
check(grec.Type == "Gasolinera" and grec.Stock.W_Gasolina == Business.Goods.W_Gasolina.Lot, "compra la gasolinera y pide gasolina al mayorista")
fire(owner, "Price", G, "W_Gasolina", 1)
check(math.abs(Business.priceOf(BusinessService._getRecord(G, true), "W_Gasolina") - 1.6) < 0.001, "sube la gasolina a 1,60")
remotes.Vehicle.OnServerEvent:Fire(adult, "Spawn", "Coche")
local car = worldRoot.Rides:FindFirstChild("Coche")
local chassis = car.PrimaryPart
for _ = 1, 8 do
	chassis.CFrame = chassis.CFrame * CFrame.new(0, 0, -150)
	task.wait(0.55)
end
chassis.CFrame = fuelPump.CFrame * CFrame.new(0, 0, 6)
task.wait(0.6)
local tillBefore = BusinessService._getRecord(G, true).Till
local litersBefore = BusinessService._getRecord(G, true).Stock.W_Gasolina
promptOf(fuelPump, "Repostar / cargar").Triggered:Fire(adult)
task.wait(0.1)
grec = BusinessService._getRecord(G, true)
check(grec.Till > tillBefore and grec.Stock.W_Gasolina < litersBefore and notified(owner, "Han repostado"), "quien reposta paga al dueño y bajan los litros")
remotes.Vehicle.OnServerEvent:Fire(adult, "Dismount")
-- Hotel: las reservas van a la caja
local H = keys.Hotel
local hotelAnchor = BusinessService._premises[H].Anchor
local hotelier, hotelierRoot = newPlayer(394, "Adulto", 60000)
moveTo(hotelierRoot, hotelAnchor.Position)
fire(hotelier, "BuyPremise", H)
fire(hotelier, "Open", H, "Hotel")
local lobby = BusinessService._premises[H].Model
local HotelService = loadModule(S .. "HotelService")
HotelService.RoomSold(lobby, 50, buyer)
task.wait(0.1)
check(BusinessService._getRecord(H, true).Till == 50 and notified(hotelier, "se aloja"), "una reserva en su hotel va a su caja")
-- Máximo de negocios y vender el local
check(#(function()
	local n = {}
	for _, e in BusinessService._index() do
		if e.Owner == 390 then
			table.insert(n, e)
		end
	end
	return n
end)() == 2, "el dueño tiene 2 negocios")
owner:SetAttribute("InteriorKey", "7:0")
fire(owner, "Unstock", L, "Agro_Manzana")
check(InventoryService.count(owner, "Agro_Manzana") > 0 and (BusinessService._getRecord(L, true).Stock.Agro_Manzana or 0) == 0, "retira las manzanas que quedan")
local m3 = profiles[owner].Money
fire(owner, "SellPremise", L)
check(BusinessService._index()[L] == nil and profiles[owner].Money >= m3 + Business.sellBack(price), "vende el local y le devuelven una parte")
-- Restaurante: cocina de platos
fire(owner, "BuyPremise", L)
fire(owner, "Open", L, "Restaurante")
local room2 = fakeInstance("Model")
room2.Parent = worldRoot
local reg2 = part("Register", CFrame.new(4010, 4, 4020))
reg2.Parent = room2
local counter2 = part("Counter", CFrame.new(4010, 2, 4020))
counter2.Parent = room2
Interior.Hooks.Decorate({ Floor = 0, Building = building, Room = { Model = room2 } })
local kitchen = promptOf(counter2, "Cocina")
check(kitchen ~= nil, "un restaurante tiene cocina")
kitchen.Triggered:Fire(buyer)
check(notified(buyer, "Solo el dueño"), "la cocina es solo del dueño")
ownerRoot.CFrame = CFrame.new(counter2.Position)
kitchen.Triggered:Fire(owner)
check(lastMessage(owner, "Panel")[2].Id == "Kitchen", "el dueño abre la cocina")
InventoryService.add(owner, "Agro_Harina", 1)
InventoryService.add(owner, "Agro_TomateFrito", 1)
InventoryService.add(owner, "Agro_Queso", 1)
task.wait(0.16)
remotes.Farm.OnServerEvent:Fire(owner, "Make", "Pizza", 1)
check(InventoryService.count(owner, "Agro_Pizza") == 4 and InventoryService.count(owner, "Agro_Queso") == 0, "cocina 2 pizzas con harina, tomate frito y queso")
fire(owner, "Stock", L, "Agro_Pizza", 4)
check(BusinessService._getRecord(L, true).Stock.Agro_Pizza == 4, "y las pone a la venta en su restaurante")

-- Nombre libre: filtro propio y filtro de Roblox
local function nameOfL()
	return BusinessService._getRecord(L, true).Name
end
local before2 = nameOfL()
fire(owner, "SetName", L, "P.U.T.A tienda")
check(nameOfL() == before2 and notified(owner, "no está permitido"), "un nombre con palabrotas (aunque sea con trucos) se rechaza")
task.wait(3.1)
fire(owner, "SetName", L, "La Cocina Prohibida")
check(nameOfL() == before2 and notified(owner, "Roblox no permite"), "si el filtro de Roblox tapa algo, se rechaza")
task.wait(3.1)
fire(owner, "SetName", L, "  Casa   Pepa  ")
check(nameOfL() == "Casa Pepa" and BusinessService._index()[L].Name == "Casa Pepa", "un nombre normal se acepta (y sale en el cartel)")
-- Personal: dependientes
fire(owner, "HireNpc", L, 1)
fire(owner, "HireNpc", L, 1)
fire(owner, "HireNpc", L, 1)
check(BusinessService._getRecord(L, true).Npc == 2, "contrata 2 dependientes (el máximo)")
fire(owner, "HireNpc", L, -1)
check(BusinessService._getRecord(L, true).Npc == 1, "despide a uno")
-- Contratar a un jugador: oferta, aceptar y turno
local worker, workerRoot = newPlayer(395, "Adulto", 0)
profiles[worker].Items = {}
profiles[worker].Slots = {}
local kid = newPlayer(396, "Nino", 0)
fire(owner, "Offer", L, kid.UserId)
check(notified(owner, "mayores de edad"), "no se puede contratar a un niño")
fire(owner, "Offer", L, worker.UserId)
check(lastMessage(worker, "Panel")[2].Id == "Offer", "al empleado le llega la oferta de trabajo")
fire(worker, "AcceptJob", L)
local wrec = BusinessService._getRecord(L, true)
check(wrec.Workers and wrec.Workers[tostring(worker.UserId)] ~= nil and notified(owner, "trabaja ahora"), "acepta y ya trabaja en el negocio")
fire(worker, "Shift", L)
check(notified(worker, "tienes que estar en el negocio") or notified(worker, "Tienes que estar"), "fuera del negocio no se empieza el turno")
worker:SetAttribute("InteriorKey", "7:0")
fire(worker, "Shift", L)
check(worker:GetAttribute("BizShift") ~= nil, "en el negocio empieza el turno")
local wage = BusinessService._getRecord(L, true).Workers[tostring(worker.UserId)].Wage
local memo = BusinessService._getRecord(L, true)
memo.Till = 100
BusinessService._payShifts()
check(profiles[worker].Money == wage and BusinessService._getRecord(L, true).Till == 100 - wage, "cada minuto de turno cobra su sueldo de la caja")
memo = BusinessService._getRecord(L, true)
memo.Till = 0
BusinessService._payShifts()
check(worker:GetAttribute("BizShift") == nil and notified(worker, "No queda dinero"), "sin dinero en la caja se acaba el turno")
fire(owner, "Wage", L, tostring(worker.UserId))
check(BusinessService._getRecord(L, true).Workers[tostring(worker.UserId)].Wage ~= wage, "el dueño cambia el sueldo")
fire(owner, "FireWorker", L, tostring(worker.UserId))
check(BusinessService._getRecord(L, true).Workers[tostring(worker.UserId)] == nil and notified(worker, "Ya no trabajas"), "y le despide")
-- Sucursales: otro local con el mismo negocio y nombre
owner:SetAttribute("InteriorKey", "8:0")
local L2
for key, premise in BusinessService._premises do
	if premise.Building == building2 then
		L2 = key
	end
end
fire(owner, "BuyPremise", L2)
local setup = lastMessage(owner, "Panel")[2]
local hasBranch = false
for _, row in setup.Rows do
	for _, b in row.Buttons or {} do
		if b.Action == "Branch" then
			hasBranch = true
		end
	end
end
check(hasBranch, "al comprar otro local puede abrir una sucursal de su restaurante")
local m4 = profiles[owner].Money
fire(owner, "Branch", L2, L)
local r2 = BusinessService._getRecord(L2, true)
check(r2.Type == "Restaurante" and r2.Name == "Casa Pepa" and profiles[owner].Money == m4 - math.floor(Business.Types.Restaurante.License * Business.BranchLicense), "abre la sucursal con el mismo nombre y media licencia")
task.wait(3.1)
owner:SetAttribute("InteriorKey", "7:0")
fire(owner, "SetName", L, "Casa Pepa Grill")
check(BusinessService._getRecord(L2, true).Name == "Casa Pepa Grill", "al cambiar el nombre cambia en toda la cadena")
local _ = left
end)()

;(function()
print("▶ Catástrofes marinas: tsunami, marea negra, tiburón, medusas, temporal y remolino")
local SeaEvents = loadModule(ROOT .. "/shared/SeaEvents")
local Fishing = loadModule(ROOT .. "/shared/Fishing")
local FishingService = loadModule(S .. "FishingService")
local DivingService = loadModule(S .. "DivingService")
local SeaEventService = loadModule(S .. "SeaEventService")
local realIsWater = FishingService.isWater
FishingService.isWater = function(p)
	return p.Y < -1 -- en la prueba: por debajo de la superficie siempre hay agua
end
for _, id in SeaEvents.Order do
	SeaEvents.Kinds[id].Warning = 0
end
local savedStart = SeaEvents.WaveStart
SeaEvents.WaveStart = 20
local function ticks(n, gap)
	for _ = 1, n do
		SeaEventService._tick()
		if gap then
			task.wait(gap)
		end
	end
end
local function person(id, pos, items)
	local p, root, hum = newPlayer(id, "Adulto", 100)
	profiles[p].Items = items or {}
	InventoryService.refresh(p)
	root.CFrame = CFrame.new(pos)
	p.Character.Head.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
	return p, root, hum
end
check(SeaEvents.pick(0) == "Tsunami" and SeaEvents.pick(0.9999) == "Medusas", "cada catástrofe tiene su probabilidad")
check(not SeaEvents.showAlert({ Id = "MareaNegra", Stage = "Adulto", Clock = 14, Distance = 300, Busy = true }), "la alerta no tapa una conversación")
check(not SeaEvents.showAlert({ Id = "MareaNegra", Stage = "Nino", Clock = 14.5, Distance = 3000 }), "a un niño en el comedor del cole no le sale la marea negra (es para mayores y está lejos)")
check(SeaEvents.showAlert({ Id = "MareaNegra", Stage = "Adulto", Clock = 14.5, Distance = 3000 }) and SeaEvents.showAlert({ Id = "Tsunami", Stage = "Nino", Clock = 10, Distance = 3000 }), "a los adultos sí, y el tsunami se avisa a todos")
check(SeaEvents.showAlert({ Id = "Medusas", Stage = "Adolescente", Clock = 19, Distance = 3000 }) and not SeaEvents.showAlert({ Id = "Medusas", Stage = "Adolescente", Clock = 11, Distance = 3000 }), "a un adolescente, fuera de clase sí; en clase y lejos, no")
check(not SeaEventService.ready("Tsunami") and SeaEventService.ready("Medusas") == false and SeaEvents.Kinds.Tsunami.MinGap >= 3600, "al arrancar no sale ninguna enseguida (y el tsunami, como mucho cada hora o más)")
check(SeaEvents.pick(0, function(id)
	return id ~= "Tsunami" and id ~= "Temporal" and id ~= "Remolino"
end) == "MareaNegra", "las que están en espera no salen")
check(SeaEvents.Kinds.Tsunami.Weight < SeaEvents.Kinds.Medusas.Weight and SeaEvents.Kinds.Tsunami.MinGap > SeaEvents.Kinds.Medusas.MinGap, "las que más dañan salen mucho menos")
-- Tsunami en Playa Dorada
local low, _, lowHum = person(201, Vector3.new(4150, 2, -1000))
local high, _, highHum = person(202, Vector3.new(4150, 30, -1000))
local far, _, farHum = person(203, Vector3.new(4150, 2, 200))
check(SeaEventService.start("Tsunami", "Playa Dorada") and worldRoot:GetAttribute("SeaEvent") == "Tsunami", "empieza el tsunami")
check(lastMessage(low, "Start") ~= nil and notified(low, "TSUNAMI"), "llega la alerta a todos")
check(not SeaEventService.start("Medusas"), "no hay dos catástrofes a la vez")
ticks(25, 0.1)
check(lowHum.Health < 100 and lastMessage(low, "Hit") ~= nil, "la ola arrastra a quien está en la playa")
check(highHum.Health == 100 and farHum.Health == 100, "quien está en alto o lejos no sufre nada")
SeaEventService.stop()
check(worldRoot:GetAttribute("SeaEvent") == nil and lastMessage(high, "End") ~= nil, "al acabar se avisa y vuelve la calma")
-- Marea negra: no se pesca y se limpia entre todos
local cleaner = person(204, Vector3.new(4210, 3, -1000), { CanaPescar = 1 })
check(SeaEventService.start("MareaNegra", "Playa Dorada"), "empieza la marea negra")
local patches = SeaEventService._event().Patches
check(#patches == SeaEvents.Kinds.MareaNegra.Patches, ("salen manchas de petróleo en el mar (%d)"):format(#patches))
local oilSpot = part("FishingSpot", CFrame.new(4210, 3.5, -1000), { "FishingSpot" }, { Water = "Mar", CastDistance = 10 })
FishingService._cast(cleaner, oilSpot)
check(notified(cleaner, "petróleo") and FishingService._fishing[cleaner] == nil, "donde hay petróleo no se puede pescar")
local money = profiles[cleaner].Money
for _, patch in table.clone(patches) do
	promptOf(patch, "Limpiar").Triggered:Fire(cleaner)
end
local mk = SeaEvents.Kinds.MareaNegra
check(profiles[cleaner].Money == money + mk.Reward * mk.Patches + mk.Bonus, "se cobra por cada mancha limpia y un premio al acabar")
check(SeaEventService._event() == nil and notified(cleaner, "limpiado toda la marea negra"), "limpia toda, la catástrofe se acaba")
-- Tiburón en la playa
local bather, _, batherHum = person(205, Vector3.new(4230, -3, -1000))
check(SeaEventService.start("Tiburon", "Playa Dorada"), "aparece el tiburón en la playa")
ticks(60)
check(batherHum.Health < 100 and notified(bather, "mordido"), "si te bañas, te puede morder")
local hunter = person(206, Vector3.new(4225, -8, -1000), { Arpon = 1, Botella = 1 })
profiles[hunter].Fishing = { Xp = Fishing.xpFor(40), Caught = {} }
ticks(1)
local shark = SeaEventService._event().Shark
check(shark ~= nil, "a un buceador con arpón le aparece el tiburón para cazarlo")
local savedGap = Fishing.Dive.ShotGap
Fishing.Dive.ShotGap = 0
for _ = 1, 12 do
	if shark.Parent then
		hunter.Character.HumanoidRootPart.CFrame = CFrame.new(shark.Position - Vector3.new(0, 3, 0))
		hunter.Character.Head.CFrame = CFrame.new(shark.Position - Vector3.new(0, 1.5, 0))
		remotes.Diving.OnServerEvent:Fire(hunter, "Shoot", shark)
	end
end
Fishing.Dive.ShotGap = savedGap
ticks(1)
check(SeaEventService._event() == nil and notified(hunter, "Recompensa por cazar al tiburón"), "si lo cazas, se acaba el peligro y te dan recompensa")
-- Medusas: el equipo de buceo protege
local swimmer, _, swimmerHum = person(207, Vector3.new(4230, -3, -990))
local suited, _, suitedHum = person(208, Vector3.new(4230, -3, -1010), { Botella = 1 })
check(SeaEventService.start("Medusas", "Playa Dorada"), "llega la plaga de medusas")
ticks(60)
check(swimmerHum.Health < 100 and suitedHum.Health == 100, "las medusas pican a los bañistas (con equipo de buceo no)")
SeaEventService.stop()
-- Temporal: rayos en alta mar
check(SeaEventService.start("Temporal"), "empieza el temporal")
ticks(1)
check(lastMessage(swimmer, "Strike") ~= nil, "caen rayos en el mar")
SeaEventService.stop()
-- Remolino: en el centro te hace daño
check(SeaEventService.start("Remolino"), "aparece un remolino")
local c = worldRoot:GetAttribute("SeaEventPos")
local diver2, _, diver2Hum = person(209, Vector3.new(c.X, -3, c.Z))
ticks(4)
check(diver2Hum.Health < 100 and notified(diver2, "remolino"), "si nadas en el centro del remolino te hace daño")
SeaEventService.stop()
SeaEvents.WaveStart = savedStart
FishingService.isWater = realIsWater
local _ = far
end)()

;(function()
print("▶ Personal y gente: cada puesto atendido, NPC que se aparta por un jugador, salas con gente y decoración")
local StaffService = loadModule(S .. "StaffService")
local CrowdService = loadModule(S .. "CrowdService")
local Decor = loadModule(ROOT .. "/server/World/Kit/Decor")
local Interiors = loadModule(ROOT .. "/server/World/Interiors")
local lab = fakeInstance("Model")
lab.Name = "PruebasPersonal"
lab.Parent = worldRoot
local BASE = Vector3.new(61000, 0, -61000) -- (lejos de los jugadores de las otras pruebas)
-- Un puesto por cada oficio que atiende al público (los de la ciudad: marcas StaffSpot de Kit/Decor)
local ROLES = {
	{ "Dependiente" }, { "Cajero" }, { "Cajera" }, { "Recepcionista" }, { "Informadora" }, { "Vigilante" },
	{ "Agente de guardia", "Policia" }, { "Bombero", "Bombero" }, { "Funcionaria de Correos" }, { "Bibliotecaria" },
	{ "Conserje" }, { "Encargado de premios" }, { "Profesor de autoescuela" }, { "Monitora", "MonitorGimnasio" },
}
local posts = {}
for i, r in ROLES do
	local p = fakeInstance("Part")
	p.Name = "StaffSpot"
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(BASE + Vector3.new(i * 30, 0.5, 0))
	p:AddTag("StaffSpot")
	p:SetAttribute("Role", r[1])
	p:SetAttribute("Work", "Type")
	p:SetAttribute("JobId", r[2])
	p.Parent = lab
	StaffService.register(p)
	posts[r[1]] = StaffService.posts()[#StaffService.posts()]
end
check(#StaffService.posts() >= #ROLES, "cada oficio de cara al público tiene su puesto")
StaffService.tick()
task.wait(0.05)
local anyone = false
for _, post in StaffService.posts() do
	anyone = anyone or StaffService.npcOf(post) ~= nil
end
check(not anyone, "sin jugadores cerca no se gasta nada: no hay nadie en los puestos")
local visitor, visitorRoot = newPlayer(260, "Adulto", 100)
moveTo(visitorRoot, BASE + Vector3.new(200, 0, 0))
StaffService.ACTIVE = 1000
services.Lighting.ClockTime = 12 -- a mediodía está todo abierto (cada oficio tiene su horario)
StaffService.tick()
task.wait(0.05)
local staffed, working = 0, 0
for _, r in ROLES do
	local npc = StaffService.npcOf(posts[r[1]])
	if npc and npc:GetAttribute("StaffRole") == r[1] then
		staffed += 1
		if npc:GetAttribute("Work") == "Type" then
			working += 1
		end
	end
end
check(staffed == #ROLES, ("con un jugador cerca, todos los puestos atendidos por un NPC (%d/%d)"):format(staffed, #ROLES))
check(working == #ROLES, "y cada uno haciendo su tarea (Npc.work)")
local clerk = StaffService.npcOf(posts["Dependiente"])
services.Lighting.ClockTime = 3
StaffService.tick()
task.wait(0.05)
check(StaffService.npcOf(posts["Dependiente"]) == nil and StaffService.hasClosedSign(posts["Dependiente"]), "a las 3 de la mañana la tienda cierra: sin dependiente y con el cartel de CERRADO")
check(clerk ~= nil and clerk:GetAttribute("Leaving") == true and clerk:GetAttribute("Says") ~= nil,
	"al cerrar con gente cerca, el dependiente se despide y se va andando (no desaparece de golpe)")
waitFor(function()
	return clerk == nil or clerk.Parent == nil
end, 4, "que el dependiente se vaya")
check(clerk ~= nil and clerk.Parent == nil and StaffService.npcOf(posts["Cajero"]) ~= nil,
	"sin nadie a su lado, se va del todo; la gasolinera (cartel de 24H) sigue con su cajero")
check(StaffService.npcOf(posts["Agente de guardia"]) ~= nil, "la comisaría abre las 24 horas")
services.Lighting.ClockTime = 12
StaffService.tick()
task.wait(0.05)
local cop = posts["Agente de guardia"]
local copNpc = StaffService.npcOf(cop)
check(copNpc ~= nil and promptOf(copNpc, "Hablar") ~= nil, "se puede hablar con el agente del mostrador")
promptOf(copNpc, "Hablar").Triggered:Fire(visitor)
check(copNpc:GetAttribute("Says") ~= nil, "y te contesta con un bocadillo")
local lastSpeech = speechLog[#speechLog]
check(lastSpeech ~= nil and lastSpeech.Speaker == copNpc and lastSpeech.Text == copNpc:GetAttribute("Says"),
	"el bocadillo va a los clientes con quién lo dice (cada uno dibuja el suyo encima de su cabeza)")
do
	-- Solo a los que están cerca: un jugador en la otra punta del mapa no recibe la frase
	local Npc = loadModule(ROOT .. "/server/World/Npc")
	local far, farRoot = newPlayer(262, "Adulto", 100)
	moveTo(farRoot, cop.CFrame.Position + Vector3.new(0, 0, 900))
	Npc.say(copNpc, "Prueba de alcance")
	local sent = speechTo[speechLog[#speechLog]] or {}
	check(sent[visitor] == true and sent[far] == nil, "las frases de los NPC solo van a los jugadores cercanos (no a toda la ciudad)")
	moveTo(visitorRoot, cop.CFrame.Position + Vector3.new(0, 0, 900))
	Npc.say(copNpc, nil)
	sent = speechTo[speechLog[#speechLog]] or {}
	check(sent[visitor] == true, "y el 'ya no habla' llega también a quien oyó la frase aunque se haya alejado")
	moveTo(visitorRoot, BASE + Vector3.new(200, 0, 0))
end
-- Un jugador policía entra de servicio en la comisaría: el agente NPC se aparta
local officer, officerRoot = newPlayer(261, "Adulto", 100)
officer:SetAttribute("Job", "Policia")
moveTo(officerRoot, cop.CFrame.Position + Vector3.new(2, 0, 0))
StaffService.tick()
waitFor(function()
	return StaffService.npcOf(cop) == nil
end, 4, "que el agente NPC se aparte")
check(StaffService.npcOf(cop) == nil and copNpc:GetAttribute("Leaving") == true and copNpc:GetAttribute("Work") == nil,
	"el jugador policía cubre el mostrador: el NPC deja la tarea y se aparta (no se esfuma delante de él)")
check((copNpc.PrimaryPart.Position - cop.CFrame.Position).Magnitude > 3, "se ha apartado del mostrador andando")
check(StaffService.npcOf(posts["Bombero"]) ~= nil and StaffService.npcOf(posts["Cajero"]) ~= nil, "los demás puestos siguen atendidos")
-- Un policía de patrulla lejos no cubre el mostrador
moveTo(officerRoot, cop.CFrame.Position + Vector3.new(0, 0, 400))
StaffService.tick()
task.wait(0.05)
check(StaffService.npcOf(cop) == copNpc and copNpc:GetAttribute("Leaving") == nil, "si el policía se va de patrulla, vuelve el mismo agente NPC a su puesto (no aparece otro encima)")
waitFor(function()
	return copNpc:GetAttribute("Work") ~= nil
end, 3, "que el agente vuelva a su tarea")
check(((copNpc.PrimaryPart.Position - cop.CFrame.Position) * Vector3.new(1, 0, 1)).Magnitude < 1, "y está otra vez en el mostrador")
moveTo(officerRoot, cop.CFrame.Position + Vector3.new(2, 0, 0))
StaffService.tick()
waitFor(function()
	return StaffService.npcOf(cop) == nil
end, 4, "que se aparte otra vez")
officer:SetAttribute("Job", nil)
StaffService.tick()
task.wait(0.05)
local back = StaffService.npcOf(cop)
check(back ~= nil and (back.PrimaryPart.Position - cop.CFrame.Position).Magnitude < 6, "al dejar el oficio, el NPC vuelve a su puesto")
-- Bomberos y monitor/a igual
local firefighter, fireRoot = newPlayer(262, "Adulto", 100)
firefighter:SetAttribute("Job", "Bombero")
moveTo(fireRoot, posts["Bombero"].CFrame.Position)
StaffService.tick()
waitFor(function()
	return StaffService.npcOf(posts["Bombero"]) == nil
end, 4, "que el bombero NPC se aparte")
check(true, "un jugador bombero en el parque: el bombero NPC le deja su sitio")
firefighter:SetAttribute("Job", nil)
StaffService.tick()
task.wait(0.05)
check(StaffService.npcOf(posts["Bombero"]) ~= nil, "y vuelve cuando lo deja")
-- Sin jugadores cerca: se van todos
moveTo(visitorRoot, BASE + Vector3.new(0, 0, 50000))
moveTo(officerRoot, BASE + Vector3.new(0, 0, 50000))
moveTo(fireRoot, BASE + Vector3.new(0, 0, 50000))
StaffService.ACTIVE = 170
StaffService.tick()
task.wait(0.05)
anyone = false
for _, post in StaffService.posts() do
	anyone = anyone or StaffService.npcOf(post) ~= nil
end
check(not anyone, "cuando no queda nadie cerca, se quitan")

-- Gente en una planta baja de la ciudad: sigue el horario de su sitio (la biblioteca cierra a las 21)
local librarySpots = {}
for k = 1, 3 do
	local spot = fakeInstance("Part")
	spot.Name = "CrowdSpot"
	spot.Size = Vector3.new(1, 1, 1)
	spot.CFrame = CFrame.new(BASE + Vector3.new(0, 0.5, 300 + k * 4))
	spot:SetAttribute("Group", "Library_9_9")
	spot:SetAttribute("Work", "Book")
	spot.Parent = lab
	CrowdService.addSpot(spot)
	table.insert(librarySpots, spot)
end
services.Lighting.ClockTime = 12
moveTo(visitorRoot, BASE + Vector3.new(2, 0, 306))
CrowdService.tickCity()
local readers = CrowdService.count("City")
check(readers >= 1, ("a mediodía hay gente leyendo en la biblioteca (%d)"):format(readers))
services.Lighting.ClockTime = 22
CrowdService.tickCity()
local stillThere, reading = 0, 0
for _, d in worldRoot:GetDescendants() do
	if d:IsA("Model") and d:GetAttribute("Crowd") == "City" then
		stillThere += 1
		if d:GetAttribute("Work") ~= nil then
			reading += 1
		end
	end
end
check(stillThere == readers and reading == 0, "a las 22:00 cierra: dejan de leer y se van (sin esfumarse delante del jugador que está a su lado)")
moveTo(visitorRoot, BASE + Vector3.new(60, 0, 306))
CrowdService.tickCity()
check(CrowdService.count("City") == 0, "en cuanto no hay nadie a su lado, se han ido")
services.Lighting.ClockTime = 12
check(CrowdService._groupOpen({ Kind = "GasShop" } :: any, 3) == false and CrowdService._groupOpen({ Kind = "Library" } :: any, 20.5),
	"la tienda de la gasolinera de madrugada casi vacía; la biblioteca abierta a las 20:30")
moveTo(visitorRoot, BASE + Vector3.new(0, 0, 50000))
for _, spot in librarySpots do
	spot:Destroy()
end

-- Salas por dentro: gente dentro del tope de cada sala y se va con la sala
local kinds = {}
for kind in CrowdService.Plans do
	table.insert(kinds, kind)
end
table.sort(kinds)
local allOk, total = true, 0
for _, kind in kinds do
	local r = Interiors[kind](lab, CFrame.new(0, 6000, 0), { Seed = kind .. "_3_3:0", Shop = if kind == "Local" then "BAR" else nil })
	local n = CrowdService.populate(r)
	local inside = 0
	for _, d in r.Model:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("Crowd") == "Room" then
			inside += 1
		end
	end
	local plan = CrowdService.Plans[kind]
	if not (inside == n and n >= 1 and n <= plan.Cap) then
		allOk = false
		print(("    (%s: %d personas, tope %d)"):format(kind, n, plan.Cap))
	end
	total += n
	r.Model:Destroy()
end
check(allOk, ("cada sala se llena con su gente, sin pasar de su tope (%d personas en %d salas)"):format(total, #kinds))
check(CrowdService.count("Room") == 0, "y al quitar la sala se va su gente")
local office = Interiors.Oficina(lab, CFrame.new(0, 6000, 0), { Seed = "Oficina_9_9:0" })
CrowdService.populate(office)
local typing, taken = 0, 0
for _, d in office.Model:GetDescendants() do
	if d:IsA("Model") and d:GetAttribute("Crowd") and d:GetAttribute("Work") == "Type" then
		typing += 1
	end
	if d:IsA("Seat") and d:GetAttribute("Taken") then
		taken += 1
	end
end
check(typing >= 1 and taken >= 1, "en la oficina hay gente sentada tecleando (y su silla queda ocupada)")
office.Model:Destroy()
local savedCap = CrowdService.ROOM_CAP
CrowdService.ROOM_CAP = 3
local big = Interiors.Estacion(lab, CFrame.new(0, 6000, 0), { Seed = "Estacion_1_1:0" })
check(CrowdService.populate(big) <= 3, "con el tope global lleno, no se ponen más")
big.Model:Destroy()
CrowdService.ROOM_CAP = savedCap

-- Plantas bajas de la ciudad: decoración y marcas (Kit/Decor)
local function shell(parentName: string, name: string, W: number, D: number, G: number, sign: string?, lit: boolean?)
	local holder = fakeInstance("Model")
	holder.Name = parentName
	holder.Parent = lab
	local m = fakeInstance("Model")
	m.Name = name
	m.Parent = holder
	local O = CFrame.new(BASE + Vector3.new(0, 0, 3000 + math.random(0, 50000)))
	local function add(n, size, cf)
		local p = fakeInstance("Part")
		p.Name = n
		p.Size = size
		p.CFrame = cf
		p.Parent = m
		return p
	end
	add("Floor", Vector3.new(W - 2, 1, D - 2), O * CFrame.new(0, 0.5, 0))
	add("Ceiling", Vector3.new(W - 2, 1, D - 2), O * CFrame.new(0, 1 + G - 0.5, 0))
	add("Wall", Vector3.new(W, G + 1, 1), O * CFrame.new(0, (G + 1) / 2, D / 2 - 0.5))
	add("Wall", Vector3.new(1, G + 1, D - 2), O * CFrame.new(-W / 2 + 0.5, (G + 1) / 2, 0))
	add("Wall", Vector3.new(1, G + 1, D - 2), O * CFrame.new(W / 2 - 0.5, (G + 1) / 2, 0))
	for _, sx in { -1, 1 } do
		add("Wall", Vector3.new(W / 2 - 4, G + 1, 1), O * CFrame.new(sx * (W / 4 + 2), (G + 1) / 2, -D / 2 + 0.5))
	end
	if lit ~= false then
		add("CeilingLamp", Vector3.new(3.2, 0.25, 3.2), O * CFrame.new(0, G - 0.2, 0))
	end
	if sign then
		local s = add("Sign", Vector3.new(10, 2.6, 0.3), O * CFrame.new(0, G - 1, -D / 2 - 0.2))
		local Builder = loadModule(ROOT .. "/server/World/Builder")
		Builder.sign(s, sign, Enum.NormalId.Front)
	end
	local nearby = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(nearby, d)
		end
	end
	return m, nearby
end
local function tagged(model, tag)
	local list = {}
	for _, d in model:GetDescendants() do
		if d:HasTag(tag) then
			table.insert(list, d)
		end
	end
	return list
end
local MIN_CITY = { Mall = { "CentroComercial", "Edificio", 140, 80, 18, 400 }, Lobby = { "Torres", "Torre", 44, 38, 16, 50 }, Library = { "Facultad", "Edificio", 100, 38, 13, 120 }, Faculty = { "Facultad", "Edificio", 100, 38, 13, 60 }, GasShop = { "Gasolinera", "Tienda", 26, 14, 15, 50 } }
local names = {}
for kind in MIN_CITY do
	table.insert(names, kind)
end
table.sort(names)
local gasShop
for _, kind in names do
	local spec = MIN_CITY[kind]
	local m, nearby = shell(spec[1], spec[2], spec[3], spec[4], spec[5], "SITIO")
	if kind == "Library" then
		m.Parent:AddTag("Library")
	end
	check(Decor.kindOf(m) == kind, kind .. ": se reconoce el sitio")
	local added = Decor.dress(m, kind, nearby)
	check(added >= spec[6], ("%s: decorado a fondo (%d piezas, mínimo %d)"):format(kind, added, spec[6]))
	check(#tagged(m, "StaffSpot") >= 1, kind .. ": con su puesto de trabajo (StaffSpot)")
	check(#tagged(m, "CrowdSpot") >= 1, kind .. ": y sitios para su gente (CrowdSpot)")
	if kind == "GasShop" then
		gasShop = m
	end
end
-- Nada se pisa: la decoración no invade la entrada
local entryFree = true
for _, d in gasShop:GetDescendants() do
	if d:IsA("BasePart") and d.Parent and d.Parent.Name ~= "Tienda" then
		local l = gasShop.Floor.CFrame:PointToObjectSpace(d.Position)
		if math.abs(l.X) < 3 and l.Z < -6 + 3 and l.Y < 8 and not d:HasTag("CrowdSpot") then
			entryFree = false
		end
	end
end
check(entryFree, "la puerta queda libre (nada delante de la entrada)")
-- Tienda vacía y a oscuras: se cierra con su puerta y por dentro va a juego con su cartel
local dark, darkNearby = shell("Manzana", "Edificio", 30, 28, 15, "BANCO VALMAR", false)
check(Decor.kindOf(dark) == "DarkShop", "una tienda vacía y a oscuras se reconoce")
Decor.dress(dark, "DarkShop", darkNearby)
check(dark:FindFirstChild("ShopDoor") ~= nil, "y se cierra con su puerta de cristal (se entra a su interior)")
check(Interiors.profileFor("BANCO VALMAR").Id == "Banco" and Interiors.profileFor("PANADERÍA").Id == "Panaderia" and Interiors.profileFor("PELUQUERÍA").Layout == "Salon" and Interiors.profileFor("BAR").Layout == "Eatery", "el interior va con lo que pone el cartel (banco, panadería, peluquería, bar…)")
local bank = Interiors.Local(lab, CFrame.new(0, 7000, 0), { Seed = "Local_5_5:0", Shop = "BANCO VALMAR" })
check(bank.Model:GetAttribute("Shop") == "Banco" and #tagged(bank.Model, "ClerkSpot") >= 2 and bank.Model:FindFirstChild("ATM", true) ~= nil, "el banco por dentro: mostrador, empleados y cajero automático")
bank.Model:Destroy()
-- Clientes de la gasolinera: aparecen con un jugador cerca y se van cuando se aleja
for _, spot in tagged(gasShop, "CrowdSpot") do
	CrowdService.addSpot(spot)
end
local shopper, shopperRoot = newPlayer(263, "Adulto", 100)
moveTo(shopperRoot, gasShop.Floor.Position)
local savedClock = services.Lighting.ClockTime
services.Lighting.ClockTime = 12 -- (de día)
CrowdService.tickCity()
services.Lighting.ClockTime = savedClock
check(CrowdService.count("City") >= 1 and CrowdService.count("City") <= CrowdService.GROUP_CAP, "con un jugador cerca, hay clientes en la tienda")
moveTo(shopperRoot, gasShop.Floor.Position + Vector3.new(0, 0, 900))
CrowdService.tickCity()
check(CrowdService.count("City") == 0, "y al irse el jugador, se quitan")
-- Decoración de las salas montadas (cuadros, carteles, tablones… en todas las que no son viviendas)
local decorOk = true
local roomKinds = {}
for kind in Decor.RoomRecipes do
	table.insert(roomKinds, kind)
end
table.sort(roomKinds)
for _, kind in roomKinds do
	local r = Interiors[kind](lab, CFrame.new(0, 8000, 0), { Seed = kind .. "_4_4:0" })
	local holder = r.Model:FindFirstChild("Decor")
	local n = 0
	for _, d in if holder then holder:GetDescendants() else {} do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	if n < 5 then
		decorOk = false
		print(("    (%s: %d piezas de decoración)"):format(kind, n))
	end
	r.Model:Destroy()
end
check(decorOk, "cada sala que no es vivienda gana detalles en paredes y suelo")
local _ = { visitorRoot, officerRoot, fireRoot }
end)()

---------------------------------------------------------------------
-- (en su propia función: la prueba ya usa casi todas las variables locales permitidas)
;(function()
print("▶ Armas: Armería, licencia, disparos, galería, policía y zonas seguras")
mocks[ROOT .. "/server/World/PoliceUnits"] = {
	init = function() end, ensure = function() end, dismiss = function() end, setTarget = function() end, knockDown = function() end,
	sees = function() return false end, anyNear = function() return false end, officersNear = function() return 0 end,
	seesDriver = function() return false, nil end, pullOver = function() end, patrolSees = function() return nil end,
}
mocks[S .. "JusticeService"] = { process = function() end }
mocks[S .. "CareerService"] = { addPoints = function() end }
mocks[S .. "BreakService"] = { hitStructure = function() return nil end }
mocks[S .. "ClassService"] = { isRunning = function() return false end }
mocks[S .. "MiniGameService"] = { isRunning = function() return false end }
function players:GetPlayerFromCharacter(character)
	for _, p in playersList do
		if p.Character == character then
			return p
		end
	end
	return nil
end
function Fake.GetPartBoundsInRadius()
	return {}
end
-- Rayos de verdad (contra cajas) para esta parte: las balas tienen que dar en algo
local realRaycast = Fake.Raycast
Fake.Raycast = function(_, origin, direction, params)
	local ignored = (params and params.FilterDescendantsInstances) or {}
	local best, bestT = nil, math.huge
	for _, part in worldRoot:GetDescendants() do
		local props = rawget(part, "__props")
		if PARTS[props.ClassName] and props.CanQuery ~= false and props.Transparency ~= 1 then
			local skip = false
			for _, ignore in ignored do
				if part == ignore or part:IsDescendantOf(ignore) then
					skip = true
					break
				end
			end
			if not skip then
				local cf, half = props.CFrame, props.Size / 2
				local o = cf:PointToObjectSpace(origin)
				local d = cf:VectorToObjectSpace(direction)
				local tmin, tmax = 0, 1
				local hit = true
				for _, axis in { "X", "Y", "Z" } do
					local oa, da, h = o[axis], d[axis], half[axis]
					if math.abs(da) < 1e-9 then
						if math.abs(oa) > h then
							hit = false
						end
					else
						local t1, t2 = (-h - oa) / da, (h - oa) / da
						tmin = math.max(tmin, math.min(t1, t2))
						tmax = math.min(tmax, math.max(t1, t2))
					end
				end
				if hit and tmin <= tmax and tmin < bestT then
					best, bestT = part, tmin
				end
			end
		end
	end
	if not best then
		return nil
	end
	local position = origin + direction * bestT
	return { Instance = best, Position = position, Normal = -direction.Unit, Material = Enum.Material.Plastic, Distance = (position - origin).Magnitude }
end

-- Suelo de verdad (shared/Ground): ni el techo de un coche aparcado ni la cabeza de alguien
do
	local Ground = loadModule(ROOT .. "/shared/Ground")
	local floor = part("GroundFloor", CFrame.new(7000, 0, 7000), {})
	floor.Size = Vector3.new(40, 1, 40)
	local parked = fakeInstance("Model")
	parked.Name = "ParkedCar"
	parked.Parent = worldRoot
	local roof = part("Roof", CFrame.new(7000, 5, 7000), {})
	roof.Size = Vector3.new(6, 1, 12)
	roof.Parent = parked
	local person = fakeInstance("Model")
	person.Name = "Vecina"
	person.Parent = worldRoot
	fakeInstance("Humanoid").Parent = person
	local head = part("Head", CFrame.new(7010, 5, 7000), {})
	head.Size = Vector3.new(2, 2, 2)
	head.Parent = person
	local leaf = part("Leaf", CFrame.new(7020, 5, 7000), {})
	leaf.Size = Vector3.new(4, 4, 4)
	leaf.CanCollide = false
	local function groundY(x)
		local params = { FilterDescendantsInstances = {} } :: any
		local hit = Ground.cast(Vector3.new(x, 20, 7000), Vector3.new(0, -40, 0), params)
		return hit and hit.Position.Y
	end
	check(groundY(7000) == 0.5, "el suelo bajo un coche aparcado es la calle, no su techo")
	check(groundY(7010) == 0.5, "el suelo bajo una persona es la calle, no su cabeza")
	check(groundY(7020) == 0.5, "las hojas y adornos que no chocan no son suelo")
	for _, p in { floor, parked, person, leaf } do
		p:Destroy()
	end
end

-- Una Armería de prueba: mostrador, ventanilla, galería con una diana
local shopCounter = part("GunShopCounter", CFrame.new(5020, 1.6, 5000), { "GunShop" }, { ShopName = "Armería de prueba" })
shopCounter.Size = Vector3.new(14, 3.2, 2.4)
local licenceDesk = part("LicenceDesk", CFrame.new(5010, 1.7, 5000), { "GunLicence" })
licenceDesk.Size = Vector3.new(5, 3.4, 2)
local rangeVolume = part("Galeria", CFrame.new(5000, 6, 5030), { "ShootingRange" })
rangeVolume.Size = Vector3.new(30, 12, 24)
rangeVolume.CanQuery = false
local target = part("Diana", CFrame.new(5000, 4.6, 5040), { "RangeTarget" }, { Lane = 1, Score = 0 })
target.Size = Vector3.new(3, 4, 0.1)
local CombatService = loadModule(S .. "CombatService")
CombatService.init()
local WantedService = loadModule(S .. "WantedService")
WantedService.init()
local WeaponService = loadModule(S .. "WeaponService")
WeaponService.init()
-- Jugadores nuevos de esta parte: los servicios se enteran (PlayerAdded)
local function join(id: number, stage: string, money: number)
	local p, r, h = newPlayer(id, stage, money)
	p.DisplayName = p.Name
	players.PlayerAdded:Fire(p)
	return p, r, h
end
local Weapons = loadModule(ROOT .. "/shared/Weapons")
local Inv = loadModule(S .. "InventoryService")
local Wp = remotes.Weapons.OnServerEvent
local function act(player, ...)
	task.wait(0.1) -- (el servidor ignora peticiones demasiado seguidas)
	Wp:Fire(player, ...)
end
local function place(player, position: Vector3, facing: Vector3?)
	local look = facing or Vector3.new(0, 0, -1)
	player.Character.HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
	player.Character.Head.CFrame = CFrame.new(position + Vector3.new(0, 4.6, 0))
end

check(promptOf(shopCounter, "Comprar") ~= nil and promptOf(licenceDesk, "Licencia de armas") ~= nil, "la Armería tiene mostrador y ventanilla de licencias")

local buyer = join(301, "AdultoJoven", 20000)
place(buyer, Vector3.new(5020, 0, 5004))
promptOf(shopCounter, "Comprar").Triggered:Fire(buyer)
local shop = lastMessage(buyer, "Shop")
check(shop ~= nil and #shop[2].Items >= 9, "el menú lista las armas, la munición y la licencia")
act(buyer, "Buy", "Pistola")
check(Inv.count(buyer, "Arma_Pistola") == 0 and profiles[buyer].Money == 20000 and notified(buyer, "licencia"), "sin licencia no se puede comprar un arma")
local kid = join(302, "Nino", 500)
place(kid, Vector3.new(5022, 0, 5004))
act(kid, "Buy", "Pistola")
check(Inv.count(kid, "Arma_Pistola") == 0, "un niño no puede comprar una pistola")
act(kid, "Buy", "PistolaAgua")
check(Inv.count(kid, "Arma_PistolaAgua") == 1, "un niño sí compra la pistola de agua")

-- Licencia: tasa + test (primero suspende, luego aprueba)
local function answerQuiz(player, good: boolean)
	local msg = lastMessage(player, "Quiz")
	local answers = {}
	for i, q in msg[3].Questions do
		for _, entry in Weapons.Quiz do
			if entry[1] == q.Text then
				local right = table.find(q.Options, entry[2][1])
				answers[i] = if good then right else (right % #q.Options) + 1
			end
		end
	end
	act(player, "Answers", msg[2], answers)
end
promptOf(licenceDesk, "Licencia de armas").Triggered:Fire(buyer)
check(profiles[buyer].Money == 20000 - Weapons.Licence.Price and lastMessage(buyer, "Quiz") ~= nil, "se paga la tasa y empieza el test de seguridad")
answerQuiz(buyer, false)
check(Inv.count(buyer, Weapons.Licence.Item) == 0, "suspender el test no da la licencia")
clearInbox(buyer)
promptOf(licenceDesk, "Licencia de armas").Triggered:Fire(buyer)
answerQuiz(buyer, true)
check(Inv.count(buyer, Weapons.Licence.Item) == 1 and buyer:GetAttribute("WeaponLicence") == true, "aprobando el test se obtiene la licencia de armas")
promptOf(licenceDesk, "Licencia de armas").Triggered:Fire(kid)
check(Inv.count(kid, Weapons.Licence.Item) == 0, "un niño no puede sacarse la licencia")

local money = profiles[buyer].Money
act(buyer, "Buy", "Pistola")
check(Inv.count(buyer, "Arma_Pistola") == 1 and profiles[buyer].Money == money - Weapons.List.Pistola.Price, "con licencia se compra la pistola")
act(buyer, "Buy", "Municion_9mm")
check(Inv.count(buyer, "Municion_9mm") == Weapons.AmmoTypes.Municion_9mm.Box, "y una caja de munición")

-- Galería de tiro: practicar no es delito
act(buyer, "Equip", "Pistola")
check(buyer:GetAttribute("Weapon") == "Pistola" and buyer:GetAttribute("WeaponMag") == 15, "empuña la pistola con el cargador lleno")
place(buyer, Vector3.new(5000, 0, 5025), Vector3.new(0, 0, 1))
act(buyer, "Aim", true)
check(buyer:GetAttribute("Aiming") == true, "apunta")
Wp:Fire(buyer, "Fire", target.Position)
check(buyer:GetAttribute("WeaponMag") == 14 and lastMessage(buyer, "Shot") ~= nil, "disparar gasta una bala y se ve el disparo")
check((target:GetAttribute("Score") or 0) > 0 and (target:GetAttribute("Shots") or 0) == 1, "la diana marca el impacto y la puntuación")
Wp:Fire(buyer, "Fire", target.Position)
check(buyer:GetAttribute("WeaponMag") == 14, "no se puede disparar más rápido que la cadencia")
task.wait(0.2)
Wp:Fire(buyer, "Fire", target.Position)
check(buyer:GetAttribute("WeaponMag") == 13, "pasada la pausa, sí")
task.wait(0.2)
check(WantedService.stars(buyer) == 0, "en la galería de tiro practicar no suma estrellas")
act(buyer, "Reload")
check(buyer:GetAttribute("Reloading") == true, "recarga")
task.wait(Weapons.List.Pistola.Reload.Tactical + 0.2)
check(buyer:GetAttribute("WeaponMag") == 16 and Inv.count(buyer, "Municion_9mm") == 12, "recarga táctica: 15 + 1 en la recámara, gasta munición de la mochila")

-- Disparar a una persona en la calle (con un policía mirando)
local victim, _, victimHum = join(303, "Adulto", 100)
local cop = join(304, "Adulto", 0)
place(buyer, Vector3.new(26000, 0, 26000))
place(victim, Vector3.new(26000, 0, 25985))
place(cop, Vector3.new(26030, 0, 26000))
cop:SetAttribute("Job", "Policia")
check(Inv.count(cop, "Arma_PistolaPolicia") == 1 and Inv.count(cop, "Arma_Taser") == 1, "la policía de servicio recibe la pistola reglamentaria y el táser")
task.wait(0.3)
Wp:Fire(buyer, "Fire", victim.Character.Head.Position)
check(victimHum.Health < 100, "la bala hace daño (CombatService)")
check(lastMessage(buyer, "Confirm") ~= nil, "el tirador ve el aspa de acierto")
check(WantedService.stars(buyer) >= 2, "disparar a una persona suma estrellas de búsqueda")
if WantedService.stars(buyer) < 2 then
	print("    (avisos al policía: " .. table.concat(notifyTexts(cop), " | ") .. ")")
end

-- Policía de servicio contra un buscado: no es delito
local suspectHum = buyer.Character:FindFirstChildOfClass("Humanoid")
local suspectHealth = suspectHum.Health
act(cop, "Equip", "PistolaPolicia")
act(cop, "Aim", true)
check(cop:GetAttribute("Weapon") == "PistolaPolicia", "el policía empuña su pistola")
place(cop, Vector3.new(26000, 0, 26015), Vector3.new(0, 0, -1))
Wp:Fire(cop, "Fire", buyer.Character.Head.Position)
check(suspectHum.Health < suspectHealth, "el policía alcanza al sospechoso")
task.wait(0.2)
check(WantedService.stars(cop) == 0, "un policía de servicio que dispara a un buscado no comete delito")

-- Zona segura: no se dispara
local safe = part("ZonaSegura", CFrame.new(7000, 5, 7000), { "SafeZone" }, { ZoneName = "el hospital" })
safe.Size = Vector3.new(40, 20, 40)
safe.CanQuery = false
place(cop, Vector3.new(7000, 0, 7000))
local copMag = cop:GetAttribute("WeaponMag")
task.wait(0.2)
Wp:Fire(cop, "Fire", Vector3.new(7000, 4, 6980))
check(cop:GetAttribute("WeaponMag") == copMag and notified(cop, "no se puede disparar"), "en una zona segura no se puede disparar")
cop:SetAttribute("Job", nil)
check(Inv.count(cop, "Arma_PistolaPolicia") == 0 and cop:GetAttribute("Weapon") == nil, "al acabar el turno se devuelven las armas de servicio")

-- Los niños no empuñan armas de verdad
Inv.add(kid, "Arma_Pistola", 1)
act(kid, "Equip", "Pistola")
check(kid:GetAttribute("Weapon") == nil, "un niño no puede empuñar un arma de verdad (aunque la tenga)")
act(kid, "Equip", "PistolaAgua")
check(kid:GetAttribute("Weapon") == "PistolaAgua", "sí la pistola de agua")

Fake.Raycast = realRaycast
end)()

---------------------------------------------------------------------
;(function()
print("▶ Conducir sin carnet: la policía, el historial (😇/😈) y la familia")
local Wanted = loadModule(ROOT .. "/shared/Wanted")
local Conduct = loadModule(ROOT .. "/shared/Conduct")
local PoliceMock = mocks[ROOT .. "/server/World/PoliceUnits"]
local JusticeMock = mocks[S .. "JusticeService"]
local rels, affinity, dialogues, processed, pulled = {}, {}, {}, {}, {}
mocks[S .. "LifeStoryService"] = {
	addRel = function(player, npc, amount)
		rels[player] = rels[player] or {}
		rels[player][npc] = (rels[player][npc] or 0) + amount
	end,
	addAffinity = function(player, _, amount)
		affinity[player] = (affinity[player] or 0) + amount
	end,
	updateCamino = function() end,
	logEvent = function() end,
}
mocks[S .. "DialogueService"] = {
	play = function(player, dialogue, context)
		table.insert(dialogues, { Player = player, Lines = dialogue.Lines, Args = context and context.args })
		return true
	end,
	bark = function() end,
}
mocks[S .. "SceneService"] = {
	teleportTo = function(player, target)
		player.Character.HumanoidRootPart.CFrame = CFrame.new(target + Vector3.new(0, 3, 0))
	end,
}
JusticeMock.process = function(player)
	table.insert(processed, player)
end
local WantedService = loadModule(S .. "WantedService")
local ConductService = loadModule(S .. "ConductService")
ConductService.init()
ConductService.HomeDelay = 0.05
Wanted.StopSeconds = 0.3
local savedRaycast = Fake.Raycast
Fake.Raycast = function()
	return nil -- (nada tapa la vista)
end
-- Qué ve la policía en cada momento (patrullas de ronda y persecuciones: PoliceUnits)
local seen = {}
PoliceMock.seesDriver = function(player)
	return seen[player] == true, if seen[player] then "patrulla" else nil
end
PoliceMock.pullOver = function(player, patrol)
	table.insert(pulled, { player, patrol })
end
local function join(id: number, stage: string, money: number)
	local p, r, h = newPlayer(id, stage, money)
	p.DisplayName = p.Name
	players.PlayerAdded:Fire(p)
	return p, r, h
end
local function crimeMessage(player, text)
	for _, m in player.Inbox do
		if m[1] == "Crime" and type(m[2]) == "table" and m[2].Crime == text then
			return m[2]
		end
	end
	return nil
end
local function busted(player)
	local m = lastMessage(player, "Busted")
	return m and m[2]
end
local function ownCar(player)
	for _, m in worldRoot.Rides:GetChildren() do
		if m:GetAttribute("OwnerId") == player.UserId then
			return m
		end
	end
	return nil
end

-- Un adulto sin carnet conduce su coche
local driver, driverRoot = join(401, "Adulto", 20000)
moveTo(driverRoot, Vector3.new(9000, 0, 9000))
remotes.Vehicle.OnServerEvent:Fire(driver, "Buy", "Coche")
remotes.Vehicle.OnServerEvent:Fire(driver, "Spawn", "Coche")
check(driver:GetAttribute("Riding") == "Coche", "sin carnet se puede conducir cualquier coche")
WantedService.checkDrivers()
check(WantedService.stars(driver) == 0 and (profiles[driver].Conduct == nil or (profiles[driver].Conduct.Points or 0) == 0), "si no le ve la policía, no pasa nada")
seen[driver] = true
WantedService.checkDrivers()
check(WantedService.stars(driver) == 1 and crimeMessage(driver, "Conducir sin carnet") ~= nil, "le ve una patrulla: «Conducir sin carnet», 1 estrella")
check(notified(driver, "¡Alto!") and #pulled == 1 and pulled[1][1] == driver and pulled[1][2] == "patrulla", "le dan el «¡Alto!» y esa patrulla le sigue con la sirena")
task.wait(0.05)
check(profiles[driver].Conduct ~= nil and profiles[driver].Conduct.Points == Conduct.Points.SinCarnet and driver:GetAttribute("ConductLast") == "Conducir sin carnet", "va a su historial de comportamiento")
check(rels[driver] == nil, "es adulto: sus padres no se enteran")
WantedService.checkDrivers()
check(WantedService.stars(driver) == 1, "mientras sigue el «¡Alto!», no se vuelve a contar")
-- No para: huida
local driverCar = ownCar(driver)
driverCar.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, -40)
task.wait(Wanted.StopSeconds + 0.05)
WantedService.checkDrivers()
check(WantedService.stars(driver) == 2 and crimeMessage(driver, "No parar ante la policía") ~= nil, "si sigue conduciendo tras el «¡Alto!»: huida, 2 estrellas")
-- Le alcanzan: adulto, a disposición judicial
WantedService.arrest(driver)
check(#processed == 1 and processed[1] == driver and busted(driver) ~= nil and busted(driver).Minor == false, "un adulto detenido pasa a disposición judicial (juicio o sentencia)")
check(driver:GetAttribute("Riding") == nil and driverCar.PrimaryPart.Anchored, "al detenerle se baja del coche y el coche se queda parado")

-- Con carnet no es delito
local legal, legalRoot = join(402, "Adulto", 20000)
moveTo(legalRoot, Vector3.new(9100, 0, 9000))
profiles[legal].Licenses = { B = true }
remotes.Vehicle.OnServerEvent:Fire(legal, "Buy", "Coche")
remotes.Vehicle.OnServerEvent:Fire(legal, "Spawn", "Coche")
seen[legal] = true
WantedService.checkDrivers()
check(legal:GetAttribute("Riding") == "Coche" and WantedService.stars(legal) == 0, "con carnet, que le vea la policía no es nada")
remotes.Vehicle.OnServerEvent:Fire(legal, "Dismount")

-- Un policía jugador de servicio también lo ve
local cop, copRoot = join(403, "Adulto", 0)
local sneaky, sneakyRoot = join(404, "Adulto", 20000)
moveTo(sneakyRoot, Vector3.new(9300, 0, 9000))
remotes.Vehicle.OnServerEvent:Fire(sneaky, "Buy", "Coche")
remotes.Vehicle.OnServerEvent:Fire(sneaky, "Spawn", "Coche")
local sneakyCar = ownCar(sneaky)
moveTo(copRoot, sneakyCar.PrimaryPart.Position + Vector3.new(Wanted.DriveSight + 40, 0, 0))
cop:SetAttribute("Job", "Policia")
WantedService.checkDrivers()
check(WantedService.stars(sneaky) == 0, "un policía de servicio lejos no lo ve")
moveTo(copRoot, sneakyCar.PrimaryPart.Position + Vector3.new(30, 0, 0))
WantedService.checkDrivers()
check(WantedService.stars(sneaky) == 1 and notified(cop, "conduce sin carnet"), "un policía de servicio cerca lo ve y le para")
cop:SetAttribute("Job", nil)

-- Una adolescente con la moto (sin carnet: menor al volante)
local teen, teenRoot = join(405, "Adolescente", 50)
moveTo(teenRoot, Vector3.new(9500, 0, 9000))
teen:SetAttribute("FamilyHomeId", "CasaTest")
teen:SetAttribute("FamilyKey", "NPC.PAPA")
profiles[teen].Story = { Traits = {}, Flags = {} }
local home = fakeInstance("Model")
home.Name = "CasaFamiliar"
home:SetAttribute("HomeId", "CasaTest")
home:AddTag("FamilyHome")
home.Parent = worldRoot
local dadSpot = fakeInstance("Part")
dadSpot.Name = "Familia_Padre"
dadSpot.CFrame = CFrame.new(12000, 2.5, 12000)
dadSpot.Parent = home
profiles[teen].Vehicles = { Moto = true }
remotes.Vehicle.OnServerEvent:Fire(teen, "Spawn", "Moto")
check(teen:GetAttribute("Riding") == "Moto" and notified(teen, "Eres menor"), "una adolescente puede conducir la moto (con aviso: es menor)")
WantedService.checkDrivers()
check(WantedService.stars(teen) == 0, "sin policía a la vista, nadie se entera")
seen[teen] = true
WantedService.checkDrivers()
task.wait(0.05)
check(WantedService.stars(teen) == 1 and crimeMessage(teen, "Menor al volante") ~= nil, "la ve una patrulla: «Menor al volante»")
check(notified(teen, "Nos ha llamado la policía") and notified(teen, "Papá"), "su familia la llama al móvil: «¡Nos ha llamado la policía!»")
check(rels[teen] ~= nil and rels[teen].Familia == Conduct.Family.Rel and (affinity[teen] or 0) < 0 and profiles[teen].Story.Traits.Rebeldia == 1, "baja la relación con sus padres y sube su Rebeldía")
check(typeof(teen:GetAttribute("GroundedUntil")) == "number" and ConductService.isGrounded(teen), "castigada (sin paga)")
-- Para y se baja: no hay huida
remotes.Vehicle.OnServerEvent:Fire(teen, "Dismount")
task.wait(Wanted.StopSeconds + 0.05)
WantedService.checkDrivers()
check(WantedService.stars(teen) == 1, "si para y se baja, no es huida")
-- La detienen: a casa con su familia (no hay juicio)
local before = #processed
WantedService.arrest(teen)
check(#processed == before and busted(teen) ~= nil and busted(teen).Minor == true, "una menor no va a juicio")
task.wait(ConductService.HomeDelay + 0.15)
check((teenRoot.Position - dadSpot.Position).Magnitude < 10, "la policía la lleva a su casa")
check(#dialogues > 0 and dialogues[#dialogues].Player == teen and dialogues[#dialogues].Lines[2].S == "Familia", "en casa la espera la charla con su familia")
check(rels[teen].Familia == Conduct.Family.Rel + Conduct.Family.RelArrest, "sus padres se enfadan todavía más")
local log = profiles[teen].Conduct.Log
check(log[#log].K == "Detenido" and profiles[teen].Conduct.Points == Conduct.Points.MenorVolante + Conduct.Points.Detenido, "todo queda en su historial")
check(string.find(tostring(teen:GetAttribute("ConductLevel")), Conduct.level(profiles[teen].Conduct.Points).Name, 1, true) ~= nil, "la ficha enseña su nivel de historial")
-- Castigada: sin paga
local money = profiles[teen].Money
profiles[teen].Conduct.PaidAt = os.time() - Config.DayLengthMinutes * 60 - 1
ConductService.tick(teen)
check(profiles[teen].Money == money and notified(teen, "no hay paga"), "castigada, se queda sin paga")

-- Un niño al volante de un coche
local kidDriver, kidRoot = join(406, "Nino", 0)
moveTo(kidRoot, Vector3.new(9700, 0, 9000))
check(VehicleService.mount(kidDriver, "Coche", { Rented = true }) and kidDriver:GetAttribute("Riding") == "Coche", "un niño también puede ponerse al volante")
WantedService.checkDrivers()
check(WantedService.stars(kidDriver) == 0, "si no le ve nadie, no pasa nada")
seen[kidDriver] = true
WantedService.checkDrivers()
check(WantedService.stars(kidDriver) == 1, "si le ve la policía, le para (aunque sea un niño)")
remotes.Vehicle.OnServerEvent:Fire(kidDriver, "Dismount")
local baby = join(407, "Bebe", 0)
check(not VehicleService.mount(baby, "Coche", { Rented = true }) and baby:GetAttribute("Riding") == nil, "un bebé no conduce nada")
-- Nunca «montado» sin vehículo (se quedaba el panel del patinete y su velocidad yendo a pie)
do
	local scooter, scooterRoot = join(408, "Nino", 0)
	moveTo(scooterRoot, Vector3.new(9760, 0, 9000))
	VehicleService.mount(scooter, "Patinete", { Rented = true })
	local model = VehicleService.rideModel(scooter)
	-- Si al bajarse falla algo (aquí, dejar al jugador a su lado), el estado se quita igual
	local savedExited = 0
	local realPrimary = model and model.PrimaryPart
	if model then
		model.PrimaryPart = nil
	end
	local ok = pcall(VehicleService.dismount, scooter, true)
	check(model ~= nil and realPrimary ~= nil and ok and scooter:GetAttribute("Riding") == nil and scooter:GetAttribute("VehicleSpeed") == nil, "al bajarse del patinete siempre se quita el estado de montado")
	-- Y si se queda colgado por otro camino: «Bajarse» (y la vigilancia de cada poco) lo limpia
	scooter:SetAttribute("Riding", "Patinete")
	scooter:SetAttribute("VehicleSpeed", 30)
	remotes.Vehicle.OnServerEvent:Fire(scooter, "Dismount")
	check(scooter:GetAttribute("Riding") == nil and scooter:GetAttribute("VehicleSpeed") == nil and savedExited == 0, "«Bajarse» sin vehículo quita el panel y la velocidad del patinete")
	scooter:SetAttribute("Riding", "Patinete")
	local first = VehicleService.clearStale(scooter)
	task.wait(1.6)
	check(not first and VehicleService.clearStale(scooter) and scooter:GetAttribute("Riding") == nil, "la vigilancia quita un «montado» sin vehículo (si sigue así un momento)")
end
-- Sacar tu propio coche, moto o patinete (barra rápida / menú «Spawn"): al volante (no de pasajero),
-- la pata recogida, sin «Conducir» encima mientras lo llevas; si el personaje no llega a sentarse,
-- se le vuelve a sentar y, si no, queda todo limpio; nada suelto sin conductor (se hundía)
do
	for i, who in { { 409, "Nino" }, { 410, "AdultoJoven" } } do
		local owner, ownerRoot, ownerHum = join(who[1], who[2], 0)
		profiles[owner].Vehicles = { Coche = true, Moto = true, Patinete = true }
		for j, kind in { "Coche", "Moto", "Patinete" } do
			moveTo(ownerRoot, Vector3.new(9800 + i * 200, 0, 9000 + j * 60))
			task.wait(2.1) -- (sin ráfagas: como mucho 3 vehículos cada 6 s)
			remotes.Vehicle.OnServerEvent:Fire(owner, "Spawn", kind)
			local model = VehicleService.rideModel(owner)
			local seat = model and model:FindFirstChild("DriverSeat")
			local chassis = model and model.PrimaryPart
			local prompt = chassis and chassis:FindFirstChild("DrivePrompt")
			local label = who[2] .. " · " .. kind
			check(model ~= nil and owner:GetAttribute("Riding") == kind and ownerHum.SeatPart == seat and seat.Occupant == ownerHum and owner:GetAttribute("Passenger") == nil, label .. ": al sacarlo va al volante (no de pasajero)")
			check(chassis ~= nil and not chassis.Anchored and chassis.CFrame.UpVector.Y > 0.95, label .. ": sale derecho y suelto para conducir")
			check(prompt ~= nil and prompt.Enabled == false, label .. ": mientras lo llevas no sale «Conducir» encima")
			local stand = model and model:FindFirstChild("Kickstand", true)
			if kind ~= "Coche" then
				check(stand ~= nil and stand:GetAttribute("StandIsDown") == false, label .. ": la pata (o el caballete) va recogida")
			end
			-- Su ordenador no llegó a sentarle (la soldadura llegó sin sentarse): «Reseat» le vuelve a sentar
			rawget(ownerHum, "__props").SeatPart = nil
			remotes.Vehicle.OnServerEvent:Fire(owner, "Reseat")
			check(ownerHum.SeatPart == seat and seat.Occupant == ownerHum and VehicleService.rideModel(owner) == model, label .. ": si no llegó a sentarse, se le vuelve a sentar al volante")
			-- …y si tampoco, su ordenador pide bajarse: todo limpio y el vehículo aparcado
			remotes.Vehicle.OnServerEvent:Fire(owner, "Reseat")
			check(VehicleService.rideModel(owner) == model, label .. ": (volver a sentar, solo una vez)")
			remotes.Vehicle.OnServerEvent:Fire(owner, "Dismount")
			check(owner:GetAttribute("Riding") == nil and owner:GetAttribute("VehicleSpeed") == nil and ownerHum.SeatPart == nil, label .. ": al bajarse no queda nada de «montado» (ni pedales ni velocidad)")
			check(chassis ~= nil and chassis.Anchored and prompt ~= nil and prompt.Enabled, label .. ": aparcado y anclado, con su «Conducir»")
			if kind ~= "Coche" then
				check(stand ~= nil and stand:GetAttribute("StandIsDown") == true, label .. ": aparcado sin nadie, la pata abajo")
			end
			-- Suelto sin conductor (algo falló a medias): la vigilancia lo aparca, nunca se hunde
			if chassis then
				chassis.Anchored = false
				VehicleService.parkOrphans()
				check(chassis.Anchored, label .. ": un vehículo suelto sin conductor se aparca solo")
			end
		end
	end
end
-- Sin castigo: la paga llega cada día de juego
task.wait(0.05)
local kidData = profiles[kidDriver]
kidData.Conduct.GroundedUntil = nil
kidData.Conduct.PaidAt = os.time() - Config.DayLengthMinutes * 60 - 1
ConductService.tick(kidDriver)
check(kidData.Money == Conduct.Family.Allowance.Nino, "sin castigo, la familia le da la paga")
-- Portarse bien borra puntos
local pts = kidData.Conduct.Points
kidData.Conduct.CalmAt = os.time() - Conduct.CalmMinutes * 60 * 2 - 1
ConductService.tick(kidDriver)
check(pts > 0 and kidData.Conduct.Points == math.max(0, pts - 2), "portarse bien borra puntos del historial")
-- Romper cristales también cuenta
local vandal = join(408, "Adulto", 0)
StoryEventsModule.emit(vandal, "Vandalism", { What = "han roto una ventana" })
task.wait(0.05)
check(profiles[vandal].Conduct ~= nil and profiles[vandal].Conduct.Points == Conduct.Points.Vandalismo, "romper cristales va al historial")

Fake.Raycast = savedRaycast
end)()

---------------------------------------------------------------------
;(function()
print("▶ Encargos de la ciudad: gente con ❗ por el mapa, favores de 1 a 3 pasos, paga y esperas")
local CityErrands = loadModule(ROOT .. "/shared/CityErrands")
local problems = CityErrands.validate()
check(#problems == 0, "los encargos están bien escritos" .. (if #problems > 0 then ": " .. table.concat(problems, " | ") else ""))
local siteKinds = {}
for _, t in CityErrands.Templates do
	siteKinds[t.Site] = true
end
local kindCount = 0
for _ in siteKinds do
	kindCount += 1
end
check(#CityErrands.Templates >= 25 and kindCount >= 15, ("hay %d encargos en %d tipos de sitio"):format(#CityErrands.Templates, kindCount))
local perro = CityErrands.ById.Parque_Perro
check(CityErrands.reward(perro, 800).Money > CityErrands.reward(perro, 0).Money and CityErrands.reward(perro, 800).Xp > CityErrands.reward(perro, 0).Xp, "cuanto más lejos te mandan, más se paga")
check(CityErrands.fitsStage(CityErrands.ById.Parque_Balon, "Nino") and not CityErrands.fitsStage(CityErrands.ById.Parque_Balon, "Adulto"), "el balón del árbol es cosa de peques")
check(not CityErrands.fitsStage(CityErrands.ById.Puerto_Cajas, "Nino") and CityErrands.fitsStage(CityErrands.ById.Puerto_Cajas, "AdultoJoven"), "descargar el barco, solo mayores")
check(not CityErrands.fitsStage(perro, "Bebe"), "a los bebés nadie les pide nada")
check(#CityErrands.forSite("Parque", "Adulto", 12) > 0 and #CityErrands.forSite("Parque", "Adulto", 23) == 0, "de noche el parque no tiene encargos (horario)")
check(#CityErrands.forSite("Policia", "Adulto", 3) > 0, "la comisaría abre las 24 horas")

-- Dobles: la historia (¿hay algo que lo impida?), las conversaciones y la experiencia
local savedMocks = {
	LifeStory = mocks[S .. "LifeStoryService"],
	Dialogue = mocks[S .. "DialogueService"],
	Progression = mocks[S .. "ProgressionService"],
	Scene = mocks[S .. "SceneService"],
}
local storyBlock = {}
mocks[S .. "LifeStoryService"] = {
	errandBlock = function(player)
		return storyBlock[player]
	end,
}
local talks, talking = {}, {}
mocks[S .. "DialogueService"] = {
	isBusy = function(player)
		return talking[player] ~= nil
	end,
	play = function(player, dialogue, context, onDone, onCancel)
		if talking[player] then
			return false
		end
		local entry = { Player = player, Lines = dialogue.Lines, Context = context, OnDone = onDone, OnCancel = onCancel }
		talking[player] = entry
		table.insert(talks, entry)
		return true
	end,
	bark = function() end,
}
local xpGiven = {}
mocks[S .. "ProgressionService"] = {
	addXp = function(player, amount)
		xpGiven[player] = (xpGiven[player] or 0) + amount
	end,
}
mocks[S .. "SceneService"] = nil -- (el de verdad: construye los objetos)
-- Contestar a la conversación abierta (1 = «¡Claro!», 2 = «Ahora no puedo»)
local function answer(player, option)
	local entry = talking[player]
	if not entry then
		return false
	end
	talking[player] = nil
	for _, line in entry.Lines do
		if line.Ask then
			entry.Context.apply(line.Options[option].Effects, "/opt")
		end
	end
	entry.OnDone()
	return true
end
remotes.CityErrand = remote()
local HttpService = services.HttpService
local Lighting = services.Lighting

-- Un barrio de prueba lejos de todo: parque, súper, farmacia, una casa, colegio, comisaría, parada y puerto
local townFolder = worldRoot:FindFirstChild("Town")
if not townFolder then
	townFolder = fakeInstance("Folder")
	townFolder.Name = "Town"
	townFolder.Parent = worldRoot
end
local function site(name, position, size)
	local model = fakeInstance("Model")
	model.Name = name
	local p = fakeInstance("Part")
	p.Name = "Suelo"
	p.CFrame = CFrame.new(position + Vector3.new(0, size.Y / 2, 0))
	p.Size = size
	p.Parent = model
	model.Parent = townFolder
	return model
end
local O = Vector3.new(30000, 0, 30000)
site("Parque", O, Vector3.new(60, 1, 60))
site("Supermercado", O + Vector3.new(200, 0, 0), Vector3.new(40, 16, 30))
local farmacia = part("Farmacia", CFrame.new(O + Vector3.new(0, 4, 260)), { "Shop" }, { ShopId = "Farmacia" })
farmacia.Size = Vector3.new(10, 8, 4)
site("Vivienda", O + Vector3.new(200, 0, 260), Vector3.new(20, 10, 20))
site("Colegio", O + Vector3.new(420, 0, 0), Vector3.new(60, 12, 50))
site("Policia", O + Vector3.new(420, 0, 300), Vector3.new(30, 12, 30))
site("ParadaBus", O + Vector3.new(-60, 0, 330), Vector3.new(6, 4, 3))
site("Puerto", O + Vector3.new(-400, 0, 0), Vector3.new(50, 1, 50))

local CityErrandService = loadModule(S .. "CityErrandService")
CityErrandService.StartDelay = 1e6 -- (los repasos los hace la prueba, cuando toca)
CityErrandService.init()
CityErrandService.reindex()
local function siteOf(kind, near)
	local best, bestD = nil, math.huge
	for _, s in CityErrandService.sites() do
		local d = (s.Center - near).Magnitude
		if s.Kind == kind and d < bestD then
			best, bestD = s, d
		end
	end
	return best
end
local parque = siteOf("Parque", O)
local super = siteOf("Super", O)
local parada = siteOf("Estacion", O)
check(parque ~= nil and super ~= nil and siteOf("Farmacia", O) ~= nil and siteOf("Barrio", O) ~= nil and parada ~= nil, "encuentra los sitios del mapa (modelos y etiquetas)")

Lighting.ClockTime = 11
local ana, anaRoot = newPlayer(970, "AdultoJoven", 0)
moveTo(anaRoot, O + Vector3.new(0, 0, -45))

-- Aparece gente cerca, nunca encima de un jugador y sin llenar la zona
-- (solo cuenta los de este barrio: los otros jugadores de la prueba tienen los suyos)
local count, tooClose = 0, false
local function audit()
	count, tooClose = 0, false
	for _, g in CityErrandService.givers() do
		if (g.Position - O).Magnitude > 700 then
			continue
		end
		count += 1
		for _, p in playersList do
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(g.Position.X, 0, g.Position.Z)).Magnitude < CityErrands.Config.MinPlayerGap then
				tooClose = true
			end
		end
	end
end
CityErrandService.scan()
audit()
check(count >= 1 and count <= CityErrands.Config.SpawnsPerScan, ("aparece gente con encargos cerca del jugador (%d)"):format(count))
for _ = 1, 4 do
	CityErrandService.scan()
end
audit()
check(count <= CityErrands.Config.MaxPerArea and not tooClose, "como mucho " .. CityErrands.Config.MaxPerArea .. " por zona y nadie a menos de 5 studs de un jugador")
local marks = HttpService:JSONDecode(ana:GetAttribute("CityErrandMarks") or "[]")
check(#marks == count and #marks > 0, "los ❗ salen en el mapa del jugador")
local portGiver = false
for _, g in CityErrandService.givers() do
	if g.Site.Kind == "Puerto" and (g.Position - O).Magnitude < 700 then
		portGiver = true
	end
end
check(not portGiver, "solo aparecen cerca de algún jugador (el puerto, lejos, está vacío)")

-- Nunca a menos de 5 studs: con el jugador justo donde se pondría, se aparta
moveTo(anaRoot, O + Vector3.new(0, 0, -18))
local g0 = CityErrandService.place(parque, "Parque_Perro", anaRoot.Position)
check(g0 ~= nil and (Vector3.new(g0.Position.X, 0, g0.Position.Z) - Vector3.new(anaRoot.Position.X, 0, anaRoot.Position.Z)).Magnitude >= CityErrands.Config.MinPlayerGap, "si el jugador está en el sitio, aparece a unos pasos (no encima)")
check(g0 ~= nil and g0.Model:FindFirstChild("Head") ~= nil and promptOf(g0.Model, "Hablar") ~= nil, "con su botón de hablar")

-- 1) ¡Se ha escapado Trufa!: buscarla por el parque y devolverla
moveTo(anaRoot, O + Vector3.new(0, 0, -45))
local giver = CityErrandService.place(parque, "Parque_Perro", anaRoot.Position)
local money0 = profiles[ana].Money
CityErrandService.talk(ana, giver)
check(talking[ana] ~= nil and talking[ana].Lines[1].S == "Doña Amparo", "al hablar te cuenta qué le pasa (conversación con respuestas)")
answer(ana, 1)
local job = CityErrandService.activeOf(ana)
check(job ~= nil and job.Template.Id == "Parque_Perro" and ana:GetAttribute("CityErrand") ~= nil, "«¡Claro!»: el encargo sale en el panel de misiones")
check(typeof(ana:GetAttribute("CityErrandTarget")) == "Vector3", "y en el GPS (CityErrandTarget)")
local state = HttpService:JSONDecode(ana:GetAttribute("CityErrand"))
check(state.Title == "¡Se ha escapado Trufa!" and state.Step == "Busca a Trufa por el parque" and state.Money == job.Money, "el panel dice qué hacer y cuánto pagan")
local itemsFolder = job.Folder
check(itemsFolder:IsDescendantOf(worldRoot) and itemsFolder:GetAttribute("ErrandOwner") == 970 and #itemsFolder:GetChildren() == 1, "Trufa aparece por el parque (solo para ti)")
local trufa = itemsFolder:GetChildren()[1]
check((ana:GetAttribute("CityErrandTarget") - trufa:GetPivot().Position).Magnitude < 0.5, "el GPS lleva hasta Trufa")
promptOf(trufa, "Coger a Trufa").Triggered:Fire(ana)
check(job.Step == 2 and (ana:GetAttribute("CityErrandTarget") - giver.Model:GetPivot().Position).Magnitude < 0.5, "con Trufa en brazos, el GPS lleva de vuelta con Doña Amparo")
CityErrandService.talk(ana, giver)
check(CityErrandService.activeOf(ana) == nil and ana:GetAttribute("CityErrand") == nil and ana:GetAttribute("CityErrandTarget") == nil, "al devolverla se acaba el encargo y se quita del panel")
check(profiles[ana].Money == money0 + job.Money and job.Money >= perro.Reward.Money and xpGiven[ana] == job.Xp, ("cobra %d € y %d XP"):format(job.Money, job.Xp))
check(notified(ana, "Encargo hecho"), "aviso de encargo hecho")
check(giver.Model:GetAttribute("Says") == perro.Thanks, "Doña Amparo da las gracias")
-- La misma persona no te vuelve a pedir nada en un rato
local again = CityErrandService.place(parque, "Parque_Perro", anaRoot.Position)
CityErrandService.talk(ana, again)
check(talking[ana] == nil and string.find(again.Model:GetAttribute("Says") or "", "otra vez tú", 1, true) ~= nil, "la misma persona espera un rato antes de pedirte otro favor")
local ok1, why1 = CityErrandService.canOffer(ana, again)
check(not ok1 and why1 == "Cooldown", "(motivo: la espera)")
for _ = 1, 3 do
	CityErrandService.scan()
end
local sameAgain = false
for _, g in CityErrandService.givers() do
	if g ~= again and g.Key == again.Key then
		sameAgain = true
	end
end
check(not sameAgain, "y no vuelve a aparecer con el mismo encargo mientras espera")
profiles[ana].CityErrands.Cooldowns[again.Key] = os.time() - 1
check((CityErrandService.canOffer(ana, again)), "pasada la espera, te lo vuelve a pedir")

-- 2) La compra de la señora Rosario: del súper a una casa del barrio (más lejos, más paga)
moveTo(anaRoot, O + Vector3.new(200, 0, -40))
local cajero = CityErrandService.place(super, "Super_CompraRosario", anaRoot.Position)
CityErrandService.talk(ana, cajero)
answer(ana, 1)
job = CityErrandService.activeOf(ana)
local rosario = job and job.Recipient
check(job ~= nil and job.Carry == "Bolsas de la compra" and rosario ~= nil and rosario.Name == "Señora Rosario", "te dan la compra y la señora Rosario espera en su casa")
check(rosario ~= nil and (rosario:GetPivot().Position - (O + Vector3.new(200, 0, 260))).Magnitude < 40, "…en una casa del barrio de verdad")
check(job ~= nil and job.Money > CityErrands.ById.Super_CompraRosario.Reward.Money + 5, ("paga según la distancia (%s €)"):format(tostring(job and job.Money)))
money0 = profiles[ana].Money
local expected = job.Money
promptOf(rosario, "Entregar").Triggered:Fire(ana)
check(CityErrandService.activeOf(ana) == nil and profiles[ana].Money == money0 + expected, "al entregarla, cobras")
check(rosario:GetAttribute("Says") ~= nil, "y la señora Rosario te lo agradece")

-- 3) Parque limpio: con tiempo; si se acaba, no se cobra
moveTo(anaRoot, O + Vector3.new(0, 0, -45))
local jardinero = CityErrandService.place(parque, "Parque_Basura", anaRoot.Position)
CityErrandService.talk(ana, jardinero)
answer(ana, 1)
job = CityErrandService.activeOf(ana)
itemsFolder = job and job.Folder
check(job ~= nil and job.Deadline ~= nil and #itemsFolder:GetChildren() == 5, "cinco papeles por el suelo y un reloj en marcha")
promptOf(itemsFolder:GetChildren()[1], "Recoger").Triggered:Fire(ana)
promptOf(itemsFolder:GetChildren()[1], "Recoger").Triggered:Fire(ana)
state = HttpService:JSONDecode(ana:GetAttribute("CityErrand"))
check(job.Collected == 2 and string.find(state.Step, "(2/5)", 1, true) ~= nil and type(state.Left) == "number", "el panel cuenta los que llevas y el tiempo que queda")
money0 = profiles[ana].Money
job.Deadline = os.clock() - 1
CityErrandService.tick()
check(CityErrandService.activeOf(ana) == nil and profiles[ana].Money == money0 and notified(ana, "Se acabó el tiempo"), "si se acaba el tiempo, el encargo se pierde y no se cobra")
check(#itemsFolder:GetChildren() == 0, "y la basura que quedaba desaparece")

-- 4) Turista perdido: te sigue hasta el parque
moveTo(anaRoot, O + Vector3.new(-60, 0, 300))
local hans = CityErrandService.place(parada, "Estacion_Turista", anaRoot.Position)
CityErrandService.talk(ana, hans)
answer(ana, 1)
job = CityErrandService.activeOf(ana)
local goal = job and job.Plan[1].Point
check(job ~= nil and goal ~= nil and (goal - O).Magnitude < 60, "Hans quiere ir a algo bonito: el parque más cercano")
moveTo(anaRoot, O + Vector3.new(-40, 0, 150))
CityErrandService.tick()
check((hans.Model:GetPivot().Position - anaRoot.Position).Magnitude < 20, "Hans te sigue (si se queda atrás, te alcanza)")
moveTo(anaRoot, goal)
CityErrandService.tick()
CityErrandService.tick()
check(CityErrandService.activeOf(ana) == nil and notified(ana, "Turista perdido"), "al llegar con él al parque, encargo hecho")

-- Edad y dejar un encargo (botón «Dejar»)
moveTo(anaRoot, O + Vector3.new(0, 0, -45))
local hugo = CityErrandService.place(parque, "Parque_Balon", anaRoot.Position)
local kid, kidRoot = newPlayer(971, "Nino", 0)
moveTo(kidRoot, O + Vector3.new(10, 0, -45))
CityErrandService.talk(ana, hugo)
check(talking[ana] == nil and string.find(hugo.Model:GetAttribute("Says") or "", "peque", 1, true) ~= nil, "a un adulto no le piden bajar un balón de un árbol (edad)")
CityErrandService.talk(kid, hugo)
answer(kid, 1)
check(CityErrandService.activeOf(kid) ~= nil, "a un niño, sí")
remotes.CityErrand.OnServerEvent:Fire(kid, "Abandon")
check(CityErrandService.activeOf(kid) == nil and kid:GetAttribute("CityErrand") == nil and notified(kid, "Has dejado el encargo"), "«Dejar»: se quita del panel y avisa")
moveTo(kidRoot, super.Center + Vector3.new(0, 0, -30))
local lola = CityErrandService.place(super, "Super_Yogures", kidRoot.Position)
CityErrandService.talk(kid, lola)
check(talking[kid] == nil and string.find(lola.Model:GetAttribute("Says") or "", "cosa de mayores", 1, true) ~= nil, "a un niño no le piden reponer el súper")
local kidOnly = true
for _, template in CityErrands.forSite("Parque", "Nino", 12) do
	kidOnly = kidOnly and CityErrands.fitsStage(template, "Nino")
end
check(kidOnly and #CityErrands.forSite("Puerto", "Nino", 12) == 0, "alrededor de un niño solo aparecen encargos para su edad")
local _, babyRoot = newPlayer(972, "Bebe", 0)
moveTo(babyRoot, O + Vector3.new(420, 0, -60))
moveTo(anaRoot, O + Vector3.new(5000, 0, 5000))
moveTo(kidRoot, O + Vector3.new(5000, 0, 5040))
for _ = 1, 3 do
	CityErrandService.scan()
end
local nearBaby = false
for _, g in CityErrandService.givers() do
	if (g.Position - (O + Vector3.new(420, 0, 0))).Magnitude < 100 then
		nearBaby = true
	end
end
check(not nearBaby, "alrededor de un bebé no aparece nadie")

-- Nada en mitad de una conversación, de una escena o de la misión del cole
moveTo(anaRoot, O + Vector3.new(0, 0, -45))
local aurelio = CityErrandService.place(parque, "Parque_Basura", anaRoot.Position)
profiles[ana].CityErrands.Cooldowns[aurelio.Key] = nil -- (el de antes se quedó sin tiempo: que no espere)
check((CityErrandService.canOffer(ana, aurelio)), "(se le puede ofrecer)")
talking[ana] = { Lines = {} }
local before = #talks
CityErrandService.talk(ana, aurelio)
check(#talks == before, "en mitad de una conversación no te ofrecen nada")
talking[ana] = nil
ana:SetAttribute("InDialogue", true)
CityErrandService.talk(ana, aurelio)
check(#talks == before, "ni mientras hablas con alguien de la historia (InDialogue)")
ana:SetAttribute("InDialogue", nil)
storyBlock[ana] = "Busy"
CityErrandService.talk(ana, aurelio)
check(#talks == before, "ni durante una escena de la historia")
storyBlock[ana] = "Story"
clearInbox(ana)
CityErrandService.talk(ana, aurelio)
check(#talks == before and notified(ana, "cole"), "ni si toca la misión principal en horario de cole")
storyBlock[ana] = nil
ana:SetAttribute("Job", "Barista")
CityErrandService.talk(ana, aurelio)
check(#talks == before, "ni trabajando")
ana:SetAttribute("Job", nil)
-- Decir que no: tarda en volver a preguntarte
CityErrandService.talk(ana, aurelio)
answer(ana, 2)
local ok2, why2 = CityErrandService.canOffer(ana, aurelio)
check(#talks == before + 1 and CityErrandService.activeOf(ana) == nil and not ok2 and why2 == "Cooldown", "«Ahora no puedo»: no insiste en un rato")
-- Un encargo a la vez
profiles[ana].CityErrands.Cooldowns[aurelio.Key] = nil
CityErrandService.talk(ana, aurelio)
answer(ana, 1)
local otro = CityErrandService.place(super, "Super_Yogures", anaRoot.Position)
clearInbox(ana)
CityErrandService.talk(ana, otro)
check(#talks == before + 2 and notified(ana, "Ya tienes un encargo"), "un encargo a la vez")
CityErrandService.abandon(ana)

-- Horario: de noche el parque se vacía y el súper cierra
Lighting.ClockTime = 23.5
local ok3, why3 = CityErrandService.canOffer(ana, otro)
check(not ok3 and why3 == "Closed", "con el súper cerrado no se ofrece nada")
CityErrandService.scan()
local emptyAtNight = true
for _, g in CityErrandService.givers() do
	if not g.Leaving and (g.Site.Kind == "Parque" or g.Site.Kind == "Super") then
		emptyAtNight = false
	end
end
check(emptyAtNight, "de noche se va la gente del parque y del súper")
Lighting.ClockTime = 11

-- Se va cuando no queda nadie cerca
local lonely = CityErrandService.place(parque, "Parque_Perro", anaRoot.Position)
moveTo(anaRoot, O + Vector3.new(5000, 0, 5000))
CityErrandService.scan()
check(lonely.Model.Parent == nil, "sin jugadores cerca, se va")

mocks[S .. "LifeStoryService"] = savedMocks.LifeStory
mocks[S .. "DialogueService"] = savedMocks.Dialogue
mocks[S .. "ProgressionService"] = savedMocks.Progression
mocks[S .. "SceneService"] = savedMocks.Scene
end)()

---------------------------------------------------------------------
;(function()
print("▶ Vida por lugar: gente haciendo cosas en cada sitio, solo cerca de los jugadores y con topes")
local PlaceLife = loadModule(ROOT .. "/shared/PlaceLife")
local PlaceLifeService = loadModule(S .. "PlaceLifeService")
local BASE = Vector3.new(-83000, 0, 83000) -- (lejos de los jugadores de las otras pruebas)
local savedClock, savedWeather, savedDay = services.Lighting.ClockTime, worldRoot:GetAttribute("Weather"), worldRoot:GetAttribute("Day")
worldRoot:SetAttribute("Day", 3) -- (miércoles)
worldRoot:SetAttribute("Weather", "Despejado")
services.Lighting.ClockTime = 12

-- Los datos: cada tipo de sitio tiene su gente y sus actividades (con frases)
local KINDS = { "Parque", "Playa", "Plaza", "ParadaBus", "BocaMetro", "Colegio", "Hospital", "CentroComercial", "Mercado", "Puerto", "Campus", "Gasolinera", "Tienda", "Oficinas", "Estacion", "BancoCalle" }
local function peakOf(kind: string): number
	return if kind == "Colegio" then 8.5 elseif kind == "Tienda" then 12.5 else 12
end
local dataOk, missing = true, {}
for _, kind in KINDS do
	local place = PlaceLife.Places[kind]
	local ok = place ~= nil and table.find(PlaceLife.Order, kind) ~= nil and #PlaceLife.allowed(kind, peakOf(kind), "Despejado") > 0
		and PlaceLife.amount(kind, peakOf(kind), "Despejado", 3) > 0 and (place.Tags ~= nil or place.Models ~= nil)
	for name in if place then place.Activities else {} do
		local activity = PlaceLife.Activities[name]
		ok = ok and activity ~= nil and PlaceLife.Lines[activity.Lines] ~= nil
	end
	if not ok then
		dataOk = false
		table.insert(missing, kind)
	end
end
check(dataOk, "cada tipo de sitio (parque, playa, plaza, paradas, metro, cole, hospital, centro comercial, mercado, puerto, campus, gasolinera, tiendas, oficinas, estación, bancos) tiene gente y actividades " .. table.concat(missing, ","))
local rainLess, nightLess = true, true
for _, kind in KINDS do
	local day = PlaceLife.amount(kind, peakOf(kind), "Despejado", 3)
	if PlaceLife.amount(kind, peakOf(kind), "Lluvia", 3) >= day then
		rainLess = false
		print("    (lluvia: " .. kind .. ")")
	end
	if PlaceLife.amount(kind, 2, "Despejado", 3) >= day then
		nightLess = false
		print("    (noche: " .. kind .. ")")
	end
end
check(rainLess, "con lluvia hay menos gente en todos los sitios")
check(nightLess, "y de madrugada, también")
local noTowel = true
for _ = 1, 30 do
	noTowel = noTowel and PlaceLife.pick("Playa", 12, "Lluvia") ~= "Toalla" and PlaceLife.pick("Parque", 12, "Lluvia") ~= "Pelota"
end
check(noTowel and PlaceLife.pick("Playa", 12, "Despejado", 0.01) ~= nil, "con lluvia nadie toma el sol en la toalla ni juega a la pelota")
check(PlaceLife.amount("Colegio", 8.5, "Despejado", 6) == 0 and PlaceLife.amount("Parque", 12, "Despejado", 7) > PlaceLife.amount("Parque", 12, "Despejado", 3),
	"el sábado no hay nadie en la puerta del cole, y el domingo el parque está más lleno")
check(PlaceLife.amount("Colegio", 14.5, "Despejado", 2) > PlaceLife.amount("Colegio", 11, "Despejado", 2), "a la salida del cole hay más padres esperando que a media mañana")
check(PlaceLife.amount("Tienda", 12.5, "Despejado", 2) > PlaceLife.amount("Tienda", 16, "Despejado", 2), "en hora punta hay cola en las tiendas")

-- Un parque, una parada de bus y un banco de la calle en el mapa de prueba
local lab = fakeInstance("Model")
lab.Name = "PruebasVidaLugar"
lab.Parent = worldRoot
local park = fakeInstance("Model")
park.Name = "Parque"
park.Parent = lab
local lawn = fakeInstance("Part")
lawn.Name = "Cesped"
lawn.Size = Vector3.new(140, 1, 140)
lawn.CFrame = CFrame.new(BASE + Vector3.new(0, -0.5, 0))
lawn.Parent = park
local parkAnchor = PlaceLifeService.addAnchor("Parque", park)
local stop = fakeInstance("Part")
stop.Name = "BusStop"
stop.Size = Vector3.new(6, 8, 2)
stop.CFrame = CFrame.new(BASE + Vector3.new(90, 4, 0))
stop:AddTag("BusStop")
stop.Parent = lab
local stopAnchor = PlaceLifeService.addAnchor("ParadaBus", stop)
local benchAnchor = nil
for k = 0, 10 do
	local x = BASE.X + 40 + k
	if math.floor(x * 7 + (BASE.Z + 20) * 13) % 3 == 1 then
		local bench = fakeInstance("Model")
		bench.Name = "Bench"
		local seat = fakeInstance("Part")
		seat.Name = "Seat"
		seat.Size = Vector3.new(5, 0.4, 1.6)
		seat.CFrame = CFrame.new(Vector3.new(x, 1.6, BASE.Z + 20))
		seat.Parent = bench
		bench.Parent = lab
		benchAnchor = PlaceLifeService.addAnchor("BancoCalle", bench)
		break
	end
end
check(parkAnchor ~= nil and stopAnchor ~= nil and benchAnchor ~= nil and #PlaceLifeService.anchors() >= 3, "se encuentran el parque, la parada y el banco")

local function ours(): { any }
	local list = {}
	for _, d in worldRoot:GetDescendants() do
		if d.ClassName == "Model" and d:GetAttribute("PlaceLife") ~= nil and d.Parent ~= nil and not d:GetAttribute("FadeOut") and not d:GetAttribute("Leaving") then
			table.insert(list, d)
		end
	end
	return list
end
local function ticks(n)
	for _ = 1, n do
		PlaceLifeService.tick()
	end
end

-- Sin jugadores cerca no hay nadie (no se gasta nada)
ticks(3)
check(PlaceLifeService.count() == 0, "sin jugadores cerca no se pone a nadie")

-- Llega un jugador al parque (mirando al norte, -Z)
local _, walkerRoot = newPlayer(970, "Adulto", 0)
moveTo(walkerRoot, BASE)
ticks(12)
local n = PlaceLifeService.count("Parque")
check(n > 0 and n <= PlaceLife.amount("Parque", 12, "Despejado", 3), ("con un jugador en el parque hay gente haciendo cosas (%d)"):format(n))
check(PlaceLifeService.count("ParadaBus") > 0 and PlaceLifeService.count("BancoCalle") == 1, "gente esperando el bus y alguien sentado en el banco")
local gapOk, frontOk, namesOk, busy = true, true, true, true
for _, npc in ours() do
	local root = npc.PrimaryPart
	local d = Vector3.new(root.Position.X - BASE.X, 0, root.Position.Z - BASE.Z)
	if d.Magnitude < PlaceLife.MinGap then
		gapOk = false
	end
	if d.Magnitude < PlaceLife.FrontGap and d.Unit:Dot(Vector3.new(0, 0, -1)) > PlaceLife.FrontCone then
		frontOk = false
	end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None or npc:GetAttribute("FadeIn") ~= true then
		namesOk = false
	end
	if not PlaceLife.Activities[npc:GetAttribute("Activity")] then
		busy = false
	end
end
check(gapOk, "nadie aparece a menos de 5 studs del jugador")
check(frontOk, "ni a menos de 30 delante de él")
check(namesOk, "sin el nombre de Roblox encima y apareciendo con fundido")
check(busy, "cada uno con su actividad")

-- Chácharas: con el jugador cerca, alguien dice algo
local before = #speechLog
PlaceLifeService.chatter(true)
local said = speechLog[#speechLog]
check(#speechLog > before and said.Speaker:GetAttribute("PlaceLife") ~= nil and type(said.Text) == "string", "la gente del sitio suelta frases cortas")

-- El jugador se va: se quitan (fundiéndose)
moveTo(walkerRoot, BASE + Vector3.new(0, 0, 5000))
ticks(1)
check(PlaceLifeService.count() == 0, "cuando el jugador se va, se quitan todos")
task.wait(0.9)
check(#ours() == 0, "y desaparecen del mapa")

-- Topes: por jugador y en todo el servidor
local savedBudget, savedCap = PlaceLife.PlayerBudget, PlaceLife.GlobalCap
PlaceLife.PlayerBudget = 5
moveTo(walkerRoot, BASE)
ticks(12)
local near = PlaceLifeService.nearCount(BASE, PlaceLife.Radius)
check(near <= 5 and PlaceLifeService.count() > 0, ("con un presupuesto de 5 por jugador, no pasa de 5 (%d)"):format(near))
PlaceLife.PlayerBudget = savedBudget
moveTo(walkerRoot, BASE + Vector3.new(0, 0, 5000))
ticks(1)
PlaceLife.GlobalCap = 3
moveTo(walkerRoot, BASE)
ticks(12)
check(PlaceLifeService.count() <= 3 and PlaceLifeService.count() > 0, "y el tope del servidor también se respeta")
PlaceLife.GlobalCap = savedCap
ticks(12)
local sunny = PlaceLifeService.count("Parque")

-- Lluvia: queda menos gente (los que sobran se van)
worldRoot:SetAttribute("Weather", "Lluvia")
ticks(3)
local rainy = PlaceLifeService.count("Parque")
check(rainy < sunny and rainy <= PlaceLife.amount("Parque", 12, "Lluvia", 3), ("con lluvia se va la gente del parque (%d → %d)"):format(sunny, rainy))
local dryOnly = true
for _, npc in ours() do
	local activity = PlaceLife.Activities[npc:GetAttribute("Activity")]
	if activity and activity.Dry then
		dryOnly = false
	end
end
check(dryOnly, "nadie juega a la pelota ni toma el sol bajo la lluvia")
worldRoot:SetAttribute("Weather", "Despejado")

-- Noche: casi nadie
ticks(12)
services.Lighting.ClockTime = 2
ticks(3)
check(PlaceLifeService.count("Parque") <= PlaceLife.amount("Parque", 2, "Despejado", 3) and PlaceLifeService.count("Parque") < sunny,
	("de madrugada el parque se queda casi vacío (%d)"):format(PlaceLifeService.count("Parque")))

-- El jugador se va: se vacía todo
services.Lighting.ClockTime = 12
moveTo(walkerRoot, BASE + Vector3.new(0, 0, 5000))
ticks(1)
task.wait(3.2)
check(PlaceLifeService.count() == 0 and #ours() == 0, "al irse el jugador, no queda nadie")

services.Lighting.ClockTime = savedClock
worldRoot:SetAttribute("Weather", savedWeather)
worldRoot:SetAttribute("Day", savedDay)
lab:Destroy()
end)()

---------------------------------------------------------------------
print("▶ Dormir: energía, estamina, reaparición y amanecer a las 8:30")
Config.SleepSeconds = 0.05
Config.SleepWaitSeconds = 2
local lighting = services.Lighting
local dayCount = 1
mocks[S .. "WorldService"] = {
	skipTo = function(clock)
		local newDay = lighting.ClockTime > clock
		if newDay then
			dayCount += 1
		end
		lighting.ClockTime = clock
		return newDay
	end,
}
local othersBefore = table.clone(playersList)
table.clear(playersList) -- en el servidor, de momento, solo quien va a dormir
local bed = part("CamaPublica", CFrame.new(40, 2, 40), { "PublicBed" })
bed.Size = Vector3.new(6, 1, 8)
local SleepService = loadModule(S .. "SleepService")
SleepService.init()
local sleepy, sleepyRoot = newPlayer(90, "AdultoJoven", 0)
services.Players.PlayerAdded:Fire(sleepy) -- en Roblox se avisa al entrar
for _, callback in loadedCallbacks do
	callback(sleepy, profiles[sleepy])
end
sleepy:SetAttribute("Stamina", 3)
lighting.ClockTime = 21.5
promptOf(bed, "Dormir").Triggered:Fire(sleepy)
task.wait(0.6)
check(lighting.ClockTime == 8.5 and dayCount == 2, "solo en el servidor: si duermes a las 21:30, te levantas a las 8:30 del día siguiente")
local lastNeeds = needsChanges[#needsChanges]
check(lastNeeds and lastNeeds[1] == sleepy and lastNeeds[3] == Config.Needs.Max, "al despertar, la energía está al máximo")
check(sleepy:GetAttribute("Stamina") == sleepy:GetAttribute("MaxStamina") and (sleepy:GetAttribute("Stamina") or 0) > 3, "y la estamina también")
check(profiles[sleepy].SpawnPoint ~= nil and sleepy:GetAttribute("SpawnPoint") ~= nil, "la cama queda guardada como punto de reaparición")
check(notified(sleepy, "Buenos días") and sleepy:GetAttribute("Sleeping") == nil, "aviso de buenos días y ya no está durmiendo")
sleepyRoot.CFrame = CFrame.new(500, 3, 500)
sleepy.CharacterAdded:Fire(sleepy.Character)
task.wait(0.9)
check((sleepyRoot.Position - bed.Position).Magnitude < 6, "al reaparecer, aparece en su cama")
lighting.ClockTime = 12
clearInbox(sleepy)
promptOf(bed, "Dormir").Triggered:Fire(sleepy)
task.wait(0.4)
check(lighting.ClockTime == 12 and notified(sleepy, "Siesta"), "de día es una siesta: descansas, pero no pasa el tiempo")
local other = newPlayer(91, "Adulto", 0)
lighting.ClockTime = 23
clearInbox(sleepy)
promptOf(bed, "Dormir").Triggered:Fire(sleepy)
task.wait(0.5)
check(lighting.ClockTime == 23 and notified(sleepy, "Esperando a que se acuesten los demás"), "con otro jugador despierto, la noche no pasa: espera en la cama")
promptOf(bed, "Dormir").Triggered:Fire(other)
task.wait(0.8)
check(lighting.ClockTime == 8.5 and dayCount == 3 and notified(other, "Buenos días"), "cuando se acuestan todos, amanece para todos a las 8:30")
lighting.ClockTime = 23
clearInbox(sleepy)
promptOf(bed, "Dormir").Triggered:Fire(sleepy)
task.wait(Config.SleepWaitSeconds + 1.5)
check(lighting.ClockTime == 23 and notified(sleepy, "los demás siguen despiertos"), "si los demás no se acuestan, te levantas descansado y la noche sigue")
table.clear(playersList)
for _, p in othersBefore do
	table.insert(playersList, p)
end

---------------------------------------------------------------------
print("\n▶ Las partidas de todos los jugadores de la prueba se pueden guardar (DataStore/JSON)")
---------------------------------------------------------------------
-- Si una sola cosa no se puede guardar (un Vector3, un NaN, una tabla con claves numéricas
-- sueltas…), Roblox rechaza el guardado ENTERO y al volver todo está como antes (scripts/test-persistence)
do
	local SaveCheck = loadModule(ROOT .. "/shared/SaveCheck")
	local bad, biggest, count = {}, 0, 0
	for _, profile in profiles do
		count += 1
		for _, problem in SaveCheck.scan(profile) do
			bad[problem.Path .. ": " .. problem.Reason] = true
		end
		local clean = SaveCheck.sanitize(profile)
		biggest = math.max(biggest, SaveCheck.size(clean))
	end
	local list = {}
	for text in bad do
		table.insert(list, text)
	end
	table.sort(list)
	for _, text in list do
		print("    · " .. text)
	end
	check(#list == 0, ("%d partidas sin nada que el DataStore rechace%s"):format(count, if #list > 0 then (" (%d problemas)"):format(#list) else ""))
	check(biggest < SaveCheck.SOFT_CHARS, ("la mayor ocupa %d caracteres (límite %d)"):format(biggest, SaveCheck.MAX_CHARS))
end

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
