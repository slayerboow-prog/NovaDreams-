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
