-- Prueba de los BARCOS PROPIOS y el puerto deportivo FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-boats.luau                    (servicios de verdad en un Roblox de mentira)
--   lune run scripts/test-boats.luau /tmp/x.rbxl        (además, el puerto deportivo del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Carga los servicios reales (BoatService, VehicleService, BattlePassRewardService,
-- BattlePassSeasonService, TesterService) con dobles de DataService, LifeService y DialogueService.
-- Comprueba:
--   * la «Gaviota» del pase (BattlePassRewardService -> BoatAdapter -> BoatService.grant) sale en el
--     menú del puerto deportivo, y la interfaz del pase ya no dice «Llega con el puerto deportivo»;
--   * sacarla desde el menú: aparece en el agua en un amarre del pantalán y te sube al timón;
--   * no se puede sacar dos veces (un barco en el agua a la vez), ni lejos de la oficina;
--   * un segundo barco sale en OTRO amarre (sin chocar); pasajeros a bordo; el barco ajeno no se pilota;
--   * bajarse en el agua: de pie en cubierta; guardar: el barco desaparece con quien vaya a bordo;
--   * comprar la lancha (edad y dinero); quien no la tiene no la saca;
--   * guardar y cargar (JSON como DataStore) y «Vida nueva» (lo del pase vuelve, lo comprado no);
--   * el modo pruebas («Todos los vehículos») da también los barcos;
--   * un barco abandonado vuelve solo al puerto;
--   * mar y tierra (shared/Boats): la orilla, las islas, el aeropuerto y el borde del mapa paran el barco;
--   * (con el mapa) la oficina y los 8 amarres existen, están a la altura del mar, en mar abierto y
--     sin nada sólido donde va el barco ni en su salida.

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
}
-- (el creador del juego, 777, es tester: para probar «Todos los vehículos» del modo pruebas)
local fakeGame = { CreatorId = 777, CreatorType = Enum.CreatorType.User, JobId = "prueba", PlaceId = 1 }
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
local S = ROOT .. "/server/Services/"
local profiles = {}
local loadedCallbacks = {}
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
-- Menú del puerto deportivo: el doble apunta la conversación; la prueba elige la opción
local dialogues = {}
mocks[S .. "DialogueService"] = {
	play = function(player, dialogue, context, onDone)
		table.insert(dialogues, { Player = player, Lines = dialogue.Lines, Context = context, Done = onDone })
		return true
	end,
	isBusy = function()
		return false
	end,
}
local Gameplay = loadModule(ROOT .. "/shared/Gameplay")
Gameplay.ExitCooldown = 0
local Boats = loadModule(ROOT .. "/shared/Boats")

---------------------------------------------------------------------
-- Puerto deportivo mínimo (como el de Kit/Landmarks): oficina y 4 amarres
---------------------------------------------------------------------
local terrain = fakeInstance("Terrain")
terrain.Name = "Terrain"
terrain.Parent = worldRoot
local OFFICE_AT = Vector3.new(-3886, 4, 1250)
local office = fakeInstance("Part")
office.Name = "OficinaBarcos"
office.CFrame = CFrame.lookAt(OFFICE_AT, OFFICE_AT + Vector3.new(1, 0, 0))
office.Size = Vector3.new(6, 6, 6)
office:AddTag("BoatMarina")
office.Parent = worldRoot
local slipParts = {}
for i = 1, 4 do
	local slip = fakeInstance("Part")
	slip.Name = "BoatSlip"
	local at = Vector3.new(-3900.5, Boats.SeaLevel, 1240 - 15 - (i - 1) * 20)
	slip.CFrame = CFrame.lookAt(at, at + Vector3.new(-1, 0, 0))
	slip.Size = Vector3.new(7, 0.2, 20)
	slip:SetAttribute("Slip", i)
	slip:AddTag("BoatSlip")
	slip.Parent = worldRoot
	slipParts[i] = slip
end

---------------------------------------------------------------------
-- Jugadores
---------------------------------------------------------------------
local playersFolder = fakeInstance("Players")
local function newPlayer(id: number, stage: string, money: number, data: { [string]: any }?)
	local player = fakeInstance("Player")
	player.Name = "Jugador" .. id
	player.DisplayName = "Marinera" .. id
	player.UserId = id
	player.Inbox = {}
	player:SetAttribute("LifeStage", stage)
	profiles[player] = data or { Money = money, Stats = { TasksDone = 0, MoneyEarned = 0 }, Boats = {} }
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
	root.CFrame = CFrame.new(OFFICE_AT + Vector3.new(6, 0, 0))
	root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	root.Parent = character
	character.Parent = worldRoot
	player.Character = character
	player.Parent = playersFolder
	table.insert(playersList, player)
	for _, callback in loadedCallbacks do
		callback(player, profiles[player])
	end
	return player, root, humanoid
end

local function leave(player)
	local i = table.find(playersList, player)
	if i then
		table.remove(playersList, i)
	end
	players.PlayerRemoving:Fire(player)
	player.Parent = nil
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

local function has(list: any, key: string): boolean
	return type(list) == "string" and string.find("," .. list .. ",", "," .. key .. ",", 1, true) ~= nil
end

local function boatsOf(player)
	local list = {}
	local rides = worldRoot:FindFirstChild("Rides")
	for _, model in (rides and rides:GetChildren()) or {} do
		if model:GetAttribute("OwnerId") == player.UserId and Boats.isBoat(model:GetAttribute("Kind")) then
			table.insert(list, model)
		end
	end
	return list
end

-- Abre el menú de la oficina y devuelve sus opciones (textos) y cómo elegir una
local function openMenu(player)
	table.clear(dialogues)
	local BoatService = loadModule(S .. "BoatService")
	BoatService.openMenu(player)
	local d = dialogues[#dialogues]
	if not d then
		return {}, function() end
	end
	local options = d.Lines[2].Options
	local texts = {}
	for _, option in options do
		table.insert(texts, option.T)
	end
	local function choose(pattern: string): boolean
		for _, option in options do
			if string.find(option.T, pattern, 1, true) then
				d.Context.apply(option.Effects)
				d.Done()
				return true
			end
		end
		return false
	end
	return texts, choose
end

local function anyText(texts, pattern)
	for _, t in texts do
		if string.find(t, pattern, 1, true) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Arranque de servicios reales
---------------------------------------------------------------------
local VehicleService = loadModule(S .. "VehicleService")
local BoatService = loadModule(S .. "BoatService")
local Rewards = loadModule(S .. "BattlePassRewardService")
local TesterService = loadModule(S .. "TesterService")
local Catalog = loadModule(ROOT .. "/shared/BattlePass/Catalog")
local Rides = loadModule(ROOT .. "/server/World/Kit/Rides")
VehicleService.init()
BoatService.init()

task.delay(240, function()
	print("❌ La prueba ha tardado demasiado")
	process.exit(1)
end)

local ok, err = xpcall(function()
	---------------------------------------------------------------------
	print("▶ Mar y tierra (shared/Boats)")
	local slipAt = slipParts[1].Position
	local west, east = Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0)
	local size = Rides.Spec.Gaviota.Size
	check(Boats.isSea(slipAt.X, slipAt.Z) and Boats.hullAtSea(slipAt, west, size), "el amarre del puerto deportivo es mar abierto (cabe la «Gaviota» entera)")
	check(not Boats.isSea(-3850, 1300) and not Boats.isSea(0, 0), "el muelle y el centro de Valmar son tierra")
	check(Boats.canMove(slipAt, slipAt + west * 30, west, size), "desde el amarre se sale hacia mar abierto")
	check(not Boats.canMove(slipAt, slipAt + east * 80, east, size), "hacia la costa se para en la orilla (no sube a la playa)")
	check(not Boats.canMove(slipAt, slipAt + east * 200, east, size), "un salto grande tampoco atraviesa la costa (se mira todo el camino)")
	check(not Boats.hullAtSea(Vector3.new(-3852, Boats.SeaLevel, 1225), west, size), "con la popa en la arena, no")
	check(not Boats.isSea(-4450, 1900) and Boats.isSea(-4450 - 130, 1900), "el Islote es tierra; a su alrededor, mar")
	check(not Boats.isSea(4450, 2650) and not Boats.isSea(-3000, 3300), "la Isla del Faro y el aeropuerto (tierra ganada al mar) son tierra")
	check(not Boats.isSea(-5000 - Boats.Margin - 10, 0) and Boats.isSea(-5000 - Boats.Margin + 50, 0), "no se sale del mapa (ni del agua del terreno)")
	local a, b = Boats.bob(1, 0)
	local c2 = Boats.bob(1, 50)
	check(math.abs(a) < 0.5 and math.abs(b) < math.rad(6) and math.abs(c2) < 0.6, "el balanceo es suave (menos de medio stud y pocos grados)")
	check(Gameplay.Vehicles.Lancha.Speed <= Gameplay.Vehicles.Moto.Speed and Gameplay.Vehicles.Gaviota.Speed == Gameplay.Vehicles.Lancha.Speed, "velocidad parecida a los demás vehículos (la del pase, igual que la normal)")
	check(Gameplay.Vehicles.Lancha.Hidden and Gameplay.Vehicles.Gaviota.Hidden, "los barcos no salen en el menú «Vehículos» (solo en el puerto deportivo)")
	for _, kind in Boats.Kinds do
		local spec = Rides.Spec[kind]
		local inside = true
		for _, seat in Rides.passengerSeats(kind, nil) do
			local p = seat.Seat.Position
			inside = inside and math.abs(p.X) < spec.Size.X / 2 and math.abs(p.Z) < spec.Size.Z / 2
		end
		check(#Rides.passengerSeats(kind, nil) >= 3 and inside and spec.Stand ~= nil, kind .. ": asientos de pasajero dentro del barco y sitio en cubierta")
	end

	---------------------------------------------------------------------
	print("▶ La «Gaviota» del pase llega al puerto deportivo")
	local owner, ownerRoot, ownerHum = newPlayer(1, "AdultoJoven", 500)
	local def = Catalog.get("S1_P35")
	check(def ~= nil and def.Type == "Boat" and def.Boat == "Gaviota", "la recompensa premium del nivel 35 es la «Gaviota»")
	check(Rewards.BoatAdapter.available(), "el adaptador del pase ya encuentra BoatService (la interfaz no dice «Llega con el puerto deportivo»)")
	local okGrant = Rewards.grant(owner, def, "S1")
	check(okGrant == true and BoatService.owns(owner, "Gaviota") and has(owner:GetAttribute("OwnedBoats"), "Gaviota"), "reclamarla la hace tuya (OwnedBoats = Gaviota)")
	check(profiles[owner].Cosmetics.Owned.S1_P35 ~= nil, "y queda también en la colección del pase")
	check(not has(owner:GetAttribute("OwnedVehicles"), "Gaviota") and not VehicleService.grant(owner, "Gaviota"), "no se cuela en los vehículos de tierra")
	local texts, choose = openMenu(owner)
	check(anyText(texts, "Sacar Lancha «Gaviota»") and anyText(texts, "Comprar lancha"), "el menú de la oficina la lista («Sacar…») y ofrece comprar la lancha")

	---------------------------------------------------------------------
	print("▶ Sacarla")
	ownerRoot.CFrame = CFrame.new(0, 3, 0)
	local okFar, whyFar = BoatService.launch(owner, "Gaviota")
	check(not okFar and whyFar == "Far" and #boatsOf(owner) == 0, "lejos de la oficina no sale")
	ownerRoot.CFrame = CFrame.new(OFFICE_AT + Vector3.new(6, 0, 0))
	check(choose("Sacar Lancha «Gaviota»"), "elige «Sacar» en el menú")
	local mine = boatsOf(owner)
	local boat = mine[1]
	check(#mine == 1 and owner:GetAttribute("Riding") == "Gaviota", "sale la «Gaviota» y va al timón")
	local chassis = boat and boat.PrimaryPart
	check(chassis ~= nil and math.abs(chassis.Position.Y - (Boats.SeaLevel + 0.5)) < 0.01, "flota a la altura del mar")
	check(chassis ~= nil and (Vector3.new(chassis.Position.X, 0, chassis.Position.Z) - Vector3.new(slipAt.X, 0, slipAt.Z)).Magnitude < 0.01, "en el primer amarre del pantalán")
	check(chassis ~= nil and chassis.CFrame.LookVector:Dot(west) > 0.99, "con la proa hacia mar abierto")
	check(ownerHum.SeatPart ~= nil and ownerHum.SeatPart.Name == "DriverSeat", "sentado en el asiento del piloto")
	check(owner:GetAttribute("BoatOut") == "Gaviota" and owner:GetAttribute("VehicleSpeed") == Gameplay.Vehicles.Gaviota.Speed, "BoatOut y la velocidad del barco")
	local plate = boat and boat:FindFirstChild("NamePlate")
	local label = plate and plate:FindFirstChild("SurfaceGui", true) and plate:FindFirstChild("SurfaceGui"):FindFirstChild("TextLabel")
	check(label ~= nil and string.find(label.Text, "MARINERA1", 1, true) ~= nil, "con su nombre en la popa")
	check(boat ~= nil and boat:GetAttribute("Drivable") == true and boat:GetAttribute("Kind") == "Gaviota", "es un vehículo de verdad (Drivable, Kind)")

	---------------------------------------------------------------------
	print("▶ Uno a la vez")
	local okTwice, whyTwice = BoatService.launch(owner, "Gaviota")
	check(not okTwice and whyTwice == "Out" and #boatsOf(owner) == 1, "no se puede sacar dos veces")
	texts = openMenu(owner)
	check(anyText(texts, "Guardar Lancha «Gaviota»") and not anyText(texts, "Sacar"), "con un barco en el agua, el menú ofrece guardarlo (y no sacar otro)")

	---------------------------------------------------------------------
	print("▶ Otro jugador: comprar, otro amarre, pasajeros y barco ajeno")
	local friend, friendRoot, friendHum = newPlayer(2, "AdultoJoven", 10000)
	local kid = newPlayer(3, "Nino", 20000)
	local okNot, whyNot = BoatService.launch(friend, "Gaviota")
	check(not okNot and whyNot == "NotOwned" and #boatsOf(friend) == 0, "quien no la tiene no la saca")
	local drive = chassis and chassis:FindFirstChild("DrivePrompt")
	check(drive ~= nil and drive.ActionText == "Pilotar", "el barco tiene su cartel «Pilotar»")
	VehicleService.board(friend, boat:FindFirstChild("RideSeat"))
	check(friend:GetAttribute("Passenger") == "Gaviota" and friendHum.SeatPart ~= nil, "un amigo sube a bordo de pasajero")
	VehicleService.leavePassenger(friend, true)
	BoatService.buy(kid, "Lancha")
	check(not BoatService.owns(kid, "Lancha") and profiles[kid].Money == 20000, "un niño no puede comprar un barco")
	local texts2, choose2 = openMenu(friend)
	check(anyText(texts2, "Comprar lancha (7.500") or anyText(texts2, "Comprar lancha"), "el menú le ofrece la lancha")
	choose2("Comprar lancha")
	check(BoatService.owns(friend, "Lancha") and profiles[friend].Money == 2500 and has(friend:GetAttribute("OwnedBoats"), "Lancha"), "compra la lancha (7.500 €)")
	friendRoot.CFrame = CFrame.new(OFFICE_AT + Vector3.new(4, 0, 2))
	local okFriend = BoatService.launch(friend, "Lancha")
	local theirs = boatsOf(friend)[1]
	check(okFriend and theirs ~= nil and friend:GetAttribute("Riding") == "Lancha", "la saca")
	local p1, p2 = chassis.Position, theirs and theirs.PrimaryPart.Position
	check(p2 ~= nil and (Vector3.new(p1.X - p2.X, 0, p1.Z - p2.Z)).Magnitude >= BoatService.SlipClearance and math.abs(p2.Z - slipParts[2].Position.Z) < 0.01, "sale en el siguiente amarre (no encima de la otra)")
	VehicleService.dismount(friend, true)
	local ownerBoatPrompt = theirs and theirs.PrimaryPart:FindFirstChild("DrivePrompt")
	VehicleService.dismount(owner, true)
	if ownerBoatPrompt then
		ownerBoatPrompt.Triggered:Fire(owner)
	end
	check(owner:GetAttribute("Riding") == nil and notified(owner, "es de otra persona"), "el barco de otro no se puede pilotar")

	---------------------------------------------------------------------
	print("▶ Bajarse en el agua y volver a subir")
	local deck = ownerRoot.Position
	local local_ = chassis.CFrame:PointToObjectSpace(deck)
	check(math.abs(local_.X) < size.X / 2 and math.abs(local_.Z) < size.Z / 2 and deck.Y > Boats.SeaLevel + 1, "al bajarse sin pantalán al lado, se queda de pie en cubierta (no en el agua)")
	check(chassis.Anchored == true and boat.Parent ~= nil, "el barco se queda fondeado")
	drive.Triggered:Fire(owner)
	check(owner:GetAttribute("Riding") == "Gaviota", "«Pilotar» le vuelve a subir")

	---------------------------------------------------------------------
	print("▶ Guardar")
	VehicleService.board(friend, boat:FindFirstChild("RideSeat"))
	ownerRoot.CFrame = CFrame.new(OFFICE_AT + Vector3.new(6, 0, 0))
	local okStore = BoatService.store(owner)
	check(okStore and #boatsOf(owner) == 0 and boat.Parent == nil, "guardarla la quita del agua")
	check(owner:GetAttribute("Riding") == nil and ownerHum.SeatPart == nil and owner:GetAttribute("BoatOut") == nil, "y el piloto se baja")
	check(friend:GetAttribute("Passenger") == nil and friendHum.SeatPart == nil, "y el pasajero también")
	check(BoatService.owns(owner, "Gaviota"), "sigue siendo suya")
	local okAgain = BoatService.launch(owner, "Gaviota")
	check(okAgain and #boatsOf(owner) == 1 and owner:GetAttribute("Riding") == "Gaviota", "después se puede volver a sacar")
	local again = boatsOf(owner)[1]
	check(again.PrimaryPart and math.abs(again.PrimaryPart.Position.Z - slipParts[1].Position.Z) < 0.01, "en el primer amarre libre")

	---------------------------------------------------------------------
	print("▶ Barco abandonado")
	VehicleService.dismount(owner, true)
	ownerRoot.CFrame = CFrame.new(0, 3, 0)
	BoatService.IdleReturn = 0
	BoatService.returnIdle()
	check(#boatsOf(owner) == 0 and notified(owner, "ha vuelto sola al puerto deportivo"), "sin nadie a bordo y su dueña lejos, vuelve sola al puerto")
	BoatService.IdleReturn = 600
	friendRoot.CFrame = CFrame.new(OFFICE_AT + Vector3.new(4, 0, 2))
	leave(friend)
	check(#boatsOf(friend) == 0, "al salir del juego, su barco desaparece")

	---------------------------------------------------------------------
	print("▶ Guardar y cargar (JSON como DataStore)")
	local serde = require("@lune/serde")
	local saved = serde.encode("json", profiles[owner])
	leave(owner)
	local back = newPlayer(1, "AdultoJoven", 0, serde.decode("json", saved))
	check(BoatService.owns(back, "Gaviota") and has(back:GetAttribute("OwnedBoats"), "Gaviota"), "al volver a entrar sigue teniendo la «Gaviota»")
	-- «Vida nueva»: DataService guarda Cosmetics (lo del pase) pero no Boats
	local reborn = serde.decode("json", saved)
	reborn.Boats = {}
	reborn.Boats.Lancha = nil
	leave(back)
	local newLife = newPlayer(1, "Nino", 0, reborn)
	check(BoatService.owns(newLife, "Gaviota"), "con «Vida nueva» la «Gaviota» del pase vuelve sola (desde la colección)")
	local buyer = newPlayer(4, "AdultoJoven", 9000)
	buyer.Character.HumanoidRootPart.CFrame = CFrame.new(OFFICE_AT + Vector3.new(5, 0, 0))
	BoatService.buy(buyer, "Lancha")
	local fresh = { Money = 0, Stats = {}, Boats = {}, Cosmetics = serde.decode("json", serde.encode("json", profiles[buyer])).Cosmetics }
	leave(buyer)
	local buyer2 = newPlayer(4, "AdultoJoven", 0, fresh)
	check(not BoatService.owns(buyer2, "Lancha"), "la lancha comprada no vuelve con «Vida nueva» (como los vehículos)")

	---------------------------------------------------------------------
	print("▶ Modo pruebas")
	local tester = newPlayer(777, "AdultoJoven", 0)
	local normal = newPlayer(5, "AdultoJoven", 0)
	TesterService.handle(normal, "Action", "Vehicles")
	check(#BoatService.list(normal) == 0, "a quien no es tester no le da nada")
	TesterService.handle(tester, "Action", "Vehicles")
	check(BoatService.owns(tester, "Lancha") and BoatService.owns(tester, "Gaviota"), "«Todos los vehículos» da también la lancha y la «Gaviota»")
	check(has(tester:GetAttribute("OwnedVehicles"), "Coche"), "(y los vehículos de siempre)")
end, debug.traceback)

if not ok then
	print("❌ Error: " .. tostring(err))
	failures += 1
end

---------------------------------------------------------------------
-- Con el mapa construido: el puerto deportivo de verdad
---------------------------------------------------------------------
local placePath = process.args[1]
local okMap, errMap = xpcall(function()
if placePath then
	print("▶ Puerto deportivo en el mapa (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	local marina = town and town:FindFirstChild("Marina")
	local offices, slips = {}, {}
	for _, d in (marina and marina:GetDescendants()) or {} do
		if d:IsA("BasePart") then
			local tags = d:GetTags()
			if table.find(tags, "BoatMarina") then
				table.insert(offices, d)
			elseif table.find(tags, "BoatSlip") then
				table.insert(slips, d)
			end
		end
	end
	check(#offices == 1, "la oficina «⚓ Barcos» está en el puerto deportivo (Town.Marina, tag BoatMarina)")
	check(#slips == 8, ("8 amarres (tag BoatSlip): %d"):format(#slips))
	-- Piezas sólidas del mapa (sin lo que solo se ve en Studio)
	local solid = {}
	for _, d in town:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide and not table.find(d:GetTags(), "EditOnly") then
			table.insert(solid, d)
		end
	end
	local function aabb(part)
		local r, s, p = part.CFrame.Rotation, part.Size, part.CFrame.Position
		local hx = math.abs(r.XVector.X) * s.X / 2 + math.abs(r.YVector.X) * s.Y / 2 + math.abs(r.ZVector.X) * s.Z / 2
		local hy = math.abs(r.XVector.Y) * s.X / 2 + math.abs(r.YVector.Y) * s.Y / 2 + math.abs(r.ZVector.Y) * s.Z / 2
		local hz = math.abs(r.XVector.Z) * s.X / 2 + math.abs(r.YVector.Z) * s.Y / 2 + math.abs(r.ZVector.Z) * s.Z / 2
		return p - Vector3.new(hx, hy, hz), p + Vector3.new(hx, hy, hz)
	end
	local function blocked(lo: Vector3, hi: Vector3): string?
		for _, part in solid do
			local a, b = aabb(part)
			if a.X < hi.X and b.X > lo.X and a.Y < hi.Y and b.Y > lo.Y and a.Z < hi.Z and b.Z > lo.Z then
				return part:GetFullName()
			end
		end
		return nil
	end
	local indices, level, sea, clear, lane = {}, true, true, true, true
	local spec = Rides.Spec.Gaviota.Size
	for _, slip in slips do
		table.insert(indices, slip:GetAttribute("Slip"))
		local p, look = slip.CFrame.Position, slip.CFrame.LookVector
		level = level and math.abs(p.Y - Boats.SeaLevel) < 0.01 and math.abs(look.Y) < 0.01
		sea = sea and Boats.hullAtSea(p, look, spec) and Boats.canMove(p, p + look * 150, look, spec)
		-- Donde va el casco (de la línea de flotación a 3 studs por encima) y el camino de salida
		local half = Vector3.new(spec.X / 2 * math.abs(look.Z) + spec.Z / 2 * math.abs(look.X), 0, spec.X / 2 * math.abs(look.X) + spec.Z / 2 * math.abs(look.Z))
		local hit = blocked(p - half + Vector3.new(0, -1.5, 0), p + half + Vector3.new(0, 3, 0))
		if hit then
			clear = false
			print("    (en el amarre " .. tostring(slip:GetAttribute("Slip")) .. ": " .. hit .. ")")
		end
		-- (el casco, deslizado hacia el mar paso a paso)
		for d = 10, 110, 10 do
			local at = p + look * d
			local laneHit = blocked(at - half + Vector3.new(0, -1.5, 0), at + half + Vector3.new(0, 3, 0))
			if laneHit then
				lane = false
				print("    (en la salida del amarre " .. tostring(slip:GetAttribute("Slip")) .. ": " .. laneHit .. ")")
				break
			end
		end
	end
	table.sort(indices)
	check(#indices == 8 and indices[1] == 1 and indices[8] == 8, "los amarres van numerados del 1 al 8")
	check(level, "a la altura del mar y rectos")
	check(sea, "en mar abierto, con salida recta de 150 studs hacia el mar")
	check(clear, "nada sólido donde aparece el barco")
	check(lane, "nada sólido en la salida de cada amarre")
	local office = offices[1]
	local near = office and (office.CFrame.Position - slips[1].CFrame.Position).Magnitude or math.huge
	for _, slip in slips do
		near = math.min(near, (office.CFrame.Position - slip.CFrame.Position).Magnitude)
	end
	check(near < 40, "el primer amarre está al lado de la oficina")
	local front = office and (office.CFrame.Position + office.CFrame.LookVector * 5)
	check(front ~= nil and blocked(Vector3.new(front.X - 1, 0.8, front.Z - 1), Vector3.new(front.X + 1, 1.05, front.Z + 1)) ~= nil, "delante de la puerta de la oficina hay suelo firme (el muelle)")
end

end, debug.traceback)
if not okMap then
	print("❌ Error (mapa): " .. tostring(errMap))
	failures += 1
end

print(if failures == 0 then "\n✅ Barcos: todo correcto" else ("\n❌ %d fallos"):format(failures))
process.exit(if failures == 0 then 0 else 1)
