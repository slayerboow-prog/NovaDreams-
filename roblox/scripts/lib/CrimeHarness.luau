-- CrimeHarness: el "Roblox de mentira" de las pruebas de delitos y armas (test-wanted, test-combat).
-- Carga los servicios DE VERDAD de la cadena disparo -> daño -> delito -> estrellas -> patrullas:
--   WeaponService.fire -> CombatService.applyHit -> StoryEvents "HitSomeone" -> WantedService.crime
--   -> testigo (la víctima) -> estrellas (atributo Wanted) -> PoliceUnits.ensure (patrullas)
-- con dobles de lo que necesita el mapa (Npc, PoliceUnits, Roads, modelos de armas…). Los dobles
-- apuntan lo que pasa (qué dice cada NPC, cuántas patrullas se piden) para poder comprobarlo.
--
-- Uso (desde scripts/):  local H = require("./lib/CrimeHarness")
--   local owner = H.player("Dueño", H.CREATOR, "Nino")     -- el creador del juego es tester
--   local npc = H.npc("Paseante", Vector3.new(0, 0, -20))
--   H.aimAt(npc)  -- el siguiente disparo da en ese NPC

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local ROOT = "src"
local S = ROOT .. "/server/Services/"
local V = roblox.Vector3.new

local H = {}
H.CREATOR = 777

---------------------------------------------------------------------
-- Señales, dobles y remotos
---------------------------------------------------------------------
local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in handlers do
				fn(...)
			end
		end,
		Wait = function() end,
	}
end
H.signal = signal

local stubMeta = {}
local stub = setmetatable({}, stubMeta)
stubMeta.__index = function()
	return stub
end
stubMeta.__call = function()
	return stub
end
H.stub = stub

H.sent = {} :: { any } -- lo que el servidor manda a cada jugador por cualquier remoto
local function fakeRemote(name: string)
	local r = { Name = name, OnServerEvent = signal(), OnClientEvent = signal(), __instance = true, ClassName = "RemoteEvent" }
	function r:FireClient(player, kind, payload)
		table.insert(H.sent, { Remote = name, Player = player, Kind = kind, Payload = payload })
	end
	function r:FireAllClients() end
	function r:IsA(class)
		return class == "RemoteEvent"
	end
	return r
end
local remoteList = {}
local remotes = setmetatable({}, {
	__index = function(_, name)
		if type(name) ~= "string" then
			return nil
		end
		local r = remoteList[name] or fakeRemote(name)
		remoteList[name] = r
		return r
	end,
})
function remotes:FindFirstChild(name)
	return remotes[name]
end
function remotes:WaitForChild(name)
	return remotes[name]
end
H.remotes = remoteList

-- Avisos (Notify) que ha recibido un jugador después de la marca `from` (= #H.sent de antes)
function H.notices(player, from: number?): { string }
	local list = {}
	for i = (from or 0) + 1, #H.sent do
		local m = H.sent[i]
		if m.Player == player and m.Remote == "Notify" and type(m.Payload) == "string" then
			table.insert(list, m.Payload)
		end
	end
	return list
end
function H.noticeHas(player, needle: string, from: number?): boolean
	for _, text in H.notices(player, from) do
		if string.find(text, needle, 1, true) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Instancias de mentira (modelos, piezas, humanoides)
---------------------------------------------------------------------
local Inst = {}
Inst.__index = Inst
local function inst(class: string, name: string, parent: any?)
	local self = setmetatable({ ClassName = class, Name = name, __instance = true, _attrs = {}, _children = {}, _changed = {} }, Inst)
	if parent then
		self.Parent = parent
		table.insert(parent._children, self)
	end
	return self
end
H.inst = inst
function Inst:GetAttribute(k)
	return self._attrs[k]
end
function Inst:SetAttribute(k, v)
	local before = self._attrs[k]
	self._attrs[k] = v
	if before ~= v and self._changed[k] then
		self._changed[k]:Fire()
	end
end
function Inst:GetAttributeChangedSignal(k)
	self._changed[k] = self._changed[k] or signal()
	return self._changed[k]
end
function Inst:FindFirstChild(name)
	for _, c in self._children do
		if c.Name == name and c.Parent == self then
			return c
		end
	end
	return nil
end
function Inst:FindFirstChildOfClass(class)
	for _, c in self._children do
		if c.ClassName == class and c.Parent == self then
			return c
		end
	end
	return nil
end
function Inst:GetChildren()
	local list = {}
	for _, c in self._children do
		if c.Parent == self then
			table.insert(list, c)
		end
	end
	return list
end
function Inst:GetDescendants()
	local list = {}
	for _, c in self:GetChildren() do
		table.insert(list, c)
		for _, d in c:GetDescendants() do
			table.insert(list, d)
		end
	end
	return list
end
function Inst:IsA(class)
	if class == self.ClassName or class == "Instance" then
		return true
	end
	return class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "MeshPart")
end
function Inst:HasTag()
	return false
end
function Inst:AddTag() end
function Inst:Destroy()
	self.Parent = nil
end
function Inst:GetPivot()
	local root = self:FindFirstChild("HumanoidRootPart")
	return roblox.CFrame.new((root or self).Position or V(0, 0, 0))
end
function Inst:PivotTo() end
function Inst:IsDescendantOf(other)
	local node = self.Parent
	while node do
		if node == other then
			return true
		end
		node = node.Parent
	end
	return false
end

local fakeWorkspace = inst("Workspace", "Workspace")
H.workspace = fakeWorkspace
local npcFolder = inst("Folder", "Gente", fakeWorkspace)

-- Personaje (jugador o NPC): Humanoid, HumanoidRootPart, Head y UpperTorso
local function character(name: string, position: Vector3, parent: any)
	local model = inst("Model", name, parent)
	local humanoid = inst("Humanoid", "Humanoid", model)
	humanoid.Health = 100
	humanoid.MaxHealth = 100
	humanoid.SeatPart = nil
	humanoid.FloorMaterial = roblox.Enum.Material.Plastic
	humanoid.WalkSpeed = 16
	local root = inst("Part", "HumanoidRootPart", model)
	root.Position = position
	root.CFrame = roblox.CFrame.new(position)
	root.Size = V(2, 2, 1)
	root.AssemblyLinearVelocity = V(0, 0, 0)
	local head = inst("Part", "Head", model)
	head.Position = position + V(0, 1.5, 0)
	head.CFrame = roblox.CFrame.new(head.Position)
	local torso = inst("Part", "UpperTorso", model)
	torso.Position = position + V(0, 0.5, 0)
	torso.CFrame = roblox.CFrame.new(torso.Position)
	model.PrimaryPart = root
	return model
end

H.npcs = {} :: { any }
function H.npc(name: string, position: Vector3, attrs: { [string]: any }?)
	local model = character(name, position, npcFolder)
	for k, v in attrs or {} do
		model:SetAttribute(k, v)
	end
	table.insert(H.npcs, model)
	return model
end

-- Agente de policía de a pie (como los de PoliceUnits: Officer, Hp)
function H.officer(position: Vector3)
	return H.npc("Agente", position, { Officer = true, Hp = 40 })
end

---------------------------------------------------------------------
-- Servicios de Roblox
---------------------------------------------------------------------
local replicatedStorage = {}
function replicatedStorage:WaitForChild(name)
	return self[name]
end
function replicatedStorage:FindFirstChild(name)
	return rawget(self, name)
end

local tagged: { [string]: { any } } = {}
H.tagged = tagged
local collection = {
	GetTagged = function(_, tag)
		return tagged[tag] or {}
	end,
	GetInstanceAddedSignal = function()
		return signal()
	end,
	GetInstanceRemovedSignal = function()
		return signal()
	end,
	HasTag = function()
		return false
	end,
}

local active = {}
local players = { PlayerAdded = signal(), PlayerRemoving = signal() }
function players:GetPlayers()
	return active
end
function players:GetPlayerByUserId(id)
	for _, p in active do
		if p.UserId == id then
			return p
		end
	end
	return nil
end
function players:GetPlayerFromCharacter(model)
	for _, p in active do
		if p.Character == model and model ~= nil then
			return p
		end
	end
	return nil
end

local fakeGame = { CreatorId = H.CREATOR, CreatorType = roblox.Enum.CreatorType.User, JobId = "prueba", PlaceId = 1 }
local services = {
	ReplicatedStorage = replicatedStorage,
	Players = players,
	RunService = {
		IsStudio = function()
			return false
		end,
		Heartbeat = signal(),
		Stepped = signal(),
	},
	CollectionService = collection,
	HttpService = {
		JSONEncode = function(_, v)
			return serde.encode("json", v)
		end,
		JSONDecode = function(_, v)
			return serde.decode("json", v)
		end,
		GenerateGUID = function()
			return tostring(math.random(1, 1e9))
		end,
	},
	Lighting = { ClockTime = 12 },
	Workspace = fakeWorkspace,
}
function fakeGame:GetService(name)
	return services[name] or stub
end

-- Rayos: el siguiente disparo da en la pieza que diga H.aimAt (y los demás rayos no dan en nada)
local aimed: any = nil
function H.aimAt(model: any?)
	aimed = model
end
function fakeWorkspace:Raycast(origin, direction, _params)
	if aimed and aimed.Parent then
		local part = aimed:FindFirstChild("UpperTorso")
		return { Instance = part, Position = part.Position, Normal = V(0, 0, 1), Material = roblox.Enum.Material.Plastic, Distance = (part.Position - origin).Magnitude }
	end
	return nil
end
function fakeWorkspace:GetPartBoundsInRadius(position, radius, params)
	local exclude = {}
	for _, i in (params and params.FilterDescendantsInstances) or {} do
		exclude[i] = true
	end
	local list = {}
	for _, model in H.npcs do
		local root = model.Parent and model:FindFirstChild("HumanoidRootPart")
		if root and not exclude[model] and (root.Position - position).Magnitude <= radius then
			table.insert(list, root)
		end
	end
	return list
end
function fakeWorkspace:GetServerTimeNow()
	return os.clock()
end

local function params()
	return { FilterType = nil, FilterDescendantsInstances = {}, IgnoreWater = false, AddToFilter = function() end }
end

---------------------------------------------------------------------
-- Cargador: script.Parent.X y require() como en Roblox
---------------------------------------------------------------------
local mocks: { [string]: any } = {}
local cache: { [string]: any } = {}
H.mocks = mocks
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
replicatedStorage.Shared = node(ROOT .. "/shared")
replicatedStorage.Remotes = remotes

local function load(path: string): any
	if mocks[path] ~= nil then
		return mocks[path]
	end
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = node(path),
		require = function(target)
			return load(rawget(target, "__path"))
		end,
		game = fakeGame,
		workspace = fakeWorkspace,
		task = task,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		CFrame = roblox.CFrame,
		UDim2 = roblox.UDim2,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		RaycastParams = { new = params },
		OverlapParams = { new = params },
		TweenInfo = stub,
		Random = { new = function()
			return { NextNumber = function()
				return 0.5
			end, NextInteger = function(_, a)
				return a
			end }
		end },
		Enum = roblox.Enum,
		Instance = { new = function()
			return stub
		end },
		typeof = function(v)
			if type(v) == "table" and (rawget(v, "IsPlayer") or rawget(v, "__instance")) then
				return "Instance"
			end
			return typeof(v)
		end,
		warn = function(...)
			print("[warn]", ...)
		end,
	}, { __index = _G })
	local file = path .. ".luau"
	if not fs.isFile(file) then
		error("Módulo no encontrado: " .. path)
	end
	local result = luau.load(fs.readFile(file), { debugName = file, environment = env })()
	cache[path] = result
	return result
end
H.load = load

---------------------------------------------------------------------
-- Dobles que apuntan lo que pasa
---------------------------------------------------------------------
H.said = {} :: { [any]: { string } } -- lo que ha dicho cada NPC (en orden)
function H.lastSaid(model): string?
	local list = H.said[model]
	return list and list[#list]
end
function H.saidAny(model, needle: string): boolean
	for _, line in H.said[model] or {} do
		if string.find(line, needle, 1, true) then
			return true
		end
	end
	return false
end
mocks[ROOT .. "/server/World/Npc"] = setmetatable({
	say = function(model, text)
		if text then
			H.said[model] = H.said[model] or {}
			table.insert(H.said[model], text)
		end
	end,
}, { __index = function()
	return stub
end })

H.dispatch = {} :: { [any]: number } -- estrellas con las que se han pedido patrullas (PoliceUnits.ensure)
H.policeWatching = false -- ¿ve la policía el delito? (patrullas cerca)
mocks[ROOT .. "/server/World/PoliceUnits"] = {
	init = function() end,
	ensure = function(player, stars)
		H.dispatch[player] = stars
	end,
	dismiss = function(player)
		H.dispatch[player] = nil
	end,
	setTarget = function() end,
	sees = function()
		return H.policeWatching
	end,
	anyNear = function()
		return H.policeWatching
	end,
	officersNear = function()
		return 0
	end,
	knockDown = function(model)
		model:SetAttribute("Down", true)
	end,
	seesDriver = function()
		return false, nil
	end,
	pullOver = function() end,
}
mocks[ROOT .. "/server/World/Kit/Roads"] = {
	segments = function()
		return {} -- (sin calles: ningún transeúnte al azar; solo cuentan la víctima y los testigos)
	end,
	Kinds = {},
}
for _, path in {
	ROOT .. "/server/World/Builder",
	ROOT .. "/server/World/Kit/Rides",
	ROOT .. "/server/World/Kit/WeaponModel",
	S .. "BreakService",
	S .. "JusticeService",
	S .. "CareerService",
	S .. "ConductService",
	S .. "ClassService",
	S .. "MiniGameService",
	S .. "GadgetService",
} do
	mocks[path] = stub
end
mocks[S .. "ClassService"] = { isRunning = function()
	return false
end }
mocks[S .. "MiniGameService"] = { isRunning = function()
	return false
end }
mocks[S .. "BreakService"] = { hitStructure = function()
	return false
end }
mocks[S .. "ProgressionService"] = { stat = function()
	return 0
end }
mocks[S .. "VehicleService"] = setmetatable({
	ridingKind = function()
		return nil
	end,
	drivingOffence = function()
		return nil
	end,
	hasLicense = function()
		return false
	end,
}, { __index = function()
	return stub
end })
mocks[S .. "MonetizationService"] = {
	payMultiplier = function()
		return 1
	end,
	has = function()
		return false
	end,
}

-- DataService: perfiles en memoria
local profiles = {}
local loaded = {}
H.profiles = profiles
mocks[S .. "DataService"] = {
	get = function(player)
		return profiles[player]
	end,
	onLoaded = function(fn)
		table.insert(loaded, fn)
	end,
	onEarning = function() end,
	addMoney = function(player, amount)
		local data = profiles[player]
		if not data or type(amount) ~= "number" or amount ~= amount then
			return false
		end
		data.Money = math.max(0, math.floor(data.Money + amount))
		return true
	end,
	spend = function(player, price)
		local data = profiles[player]
		if not data or data.Money < price then
			return false
		end
		data.Money -= price
		return true
	end,
}

---------------------------------------------------------------------
-- Jugadores
---------------------------------------------------------------------
function H.player(name: string, userId: number, stage: string, position: Vector3?)
	local attrs = { LifeStage = stage }
	local changed = {}
	local p = { Name = name, DisplayName = name, UserId = userId, Parent = true, IsPlayer = true, Chatted = signal(), CharacterAdded = signal() }
	function p:SetAttribute(k, v)
		local before = attrs[k]
		attrs[k] = v
		if before ~= v and changed[k] then
			changed[k]:Fire()
		end
	end
	function p:GetAttribute(k)
		return attrs[k]
	end
	function p:GetAttributeChangedSignal(k)
		changed[k] = changed[k] or signal()
		return changed[k]
	end
	function p:GetRankInGroup()
		return 0
	end
	function p:IsA(class)
		return class == "Player" or class == "Instance"
	end
	p.Character = character(name, position or V(0, 0, 0), fakeWorkspace)
	profiles[p] = {
		Money = 500,
		Hunger = 100,
		Energy = 100,
		Items = {},
		Slots = {},
		Stats = { TasksDone = 0, MoneyEarned = 0 },
		Life = { Stage = stage, AgeYears = 30 },
		Story = { Active = {} },
	}
	table.insert(active, p)
	players.PlayerAdded:Fire(p)
	for _, fn in loaded do
		fn(p, profiles[p])
	end
	return p
end

---------------------------------------------------------------------
-- Arranque: los servicios de verdad
---------------------------------------------------------------------
function H.boot()
	H.Wanted = load(ROOT .. "/shared/Wanted")
	H.Weapons = load(ROOT .. "/shared/Weapons")
	H.Wanted.CallDelay = 1.6 -- (lo que tarda en llamar la víctima o el testigo; más corto en la prueba)
	H.TesterService = load(S .. "TesterService")
	H.InventoryService = load(S .. "InventoryService")
	H.CombatService = load(S .. "CombatService")
	H.WantedService = load(S .. "WantedService")
	H.WeaponService = load(S .. "WeaponService")
	H.CombatService.init()
	H.WantedService.init()
	H.WeaponService.init()
	return H
end

-- Le da un arma (y su cargador lleno) por la mochila de siempre
function H.give(player, weaponId: string)
	local w = H.Weapons.get(weaponId)
	H.InventoryService.add(player, H.Weapons.itemId(weaponId), 1)
	local data = profiles[player]
	data.WeaponMags = data.WeaponMags or {}
	data.WeaponMags[weaponId] = w.Magazine
end

function H.licence(player)
	H.InventoryService.add(player, H.Weapons.Licence.Item, 1)
end

-- Dispara al NPC (espera la cadencia del arma para que el disparo salga siempre)
function H.shoot(player, target)
	task.wait(1.3)
	H.aimAt(target)
	local root = target:FindFirstChild("UpperTorso")
	local ok = H.WeaponService.fire(player, root.Position)
	H.aimAt(nil)
	return ok
end

return H
