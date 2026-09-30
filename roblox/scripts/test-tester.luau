-- Prueba del MODO PRUEBAS (src/server/Services/TesterService.luau) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-tester.luau
--
-- Carga los servicios de verdad que toca el modo pruebas (TesterService, JobService, LifeService,
-- NeedsService, InventoryService, WeaponService, VehicleService, RoleService) en un Roblox de
-- mentira; lo que necesita el mapa (Builder, modelos de armas, NPC…) son dobles que no hacen nada.
-- Comprueba:
--   * a quien no es tester el remoto y /pruebas no le hacen nada (ni dinero, ni armas, ni carnets);
--   * el tester recibe todas las armas (y munición y licencia) por la mochila de siempre;
--   * el dinero infinito se rellena al bajar del mínimo y al apagarlo vuelve el dinero de antes;
--   * un niño tester empieza un oficio que pide edad (JobService.start) y uno normal no;
--   * los carnets de conducir se dan de verdad (VehicleService.hasLicense).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local ROOT = "src"
local CREATOR = 777

---------------------------------------------------------------------
-- Roblox de mentira
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
	}
end

-- Doble universal: se puede indexar y llamar sin fin (para lo que el mapa haría de verdad)
local stubMeta = {}
local stub = setmetatable({}, stubMeta)
stubMeta.__index = function()
	return stub
end
stubMeta.__call = function()
	return stub
end

local sent: { any } = {} -- lo que el servidor manda a cada jugador por cualquier remoto
local function fakeRemote(name: string)
	local r = { Name = name, OnServerEvent = signal(), OnClientEvent = signal() }
	function r:FireClient(player, kind, payload)
		table.insert(sent, { Remote = name, Player = player, Kind = kind, Payload = payload })
	end
	function r:FireAllClients() end
	function r:IsA(class)
		return class == "RemoteEvent"
	end
	return r
end
local remoteList = {}
local remotes = setmetatable({}, {
	__index = function(self, name)
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

local node -- (se define abajo)
local replicatedStorage = {}
function replicatedStorage:WaitForChild(name)
	return self[name]
end
function replicatedStorage:FindFirstChild(name)
	return rawget(self, name)
end

local tagged: { [string]: { any } } = {}
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
local players = { PlayerAdded = signal(), PlayerRemoving = signal() }
local active = {}
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

local fakeGame = { CreatorId = CREATOR, CreatorType = roblox.Enum.CreatorType.User, JobId = "prueba", PlaceId = 1 }
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
	Workspace = {},
}
function fakeGame:GetService(name)
	return services[name] or stub
end

---------------------------------------------------------------------
-- Cargador: script.Parent.X y require() como en Roblox
---------------------------------------------------------------------
local mocks: { [string]: any } = {}
local cache: { [string]: any } = {}
local nodeMeta = {}
function node(path: string)
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
		workspace = services.Workspace,
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
			return if type(v) == "table" and rawget(v, "IsPlayer") then "Instance" else typeof(v)
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

local S = ROOT .. "/server/Services/"
-- Lo que depende del mapa o de Roblox de verdad: dobles
for _, path in {
	ROOT .. "/server/World/Builder",
	ROOT .. "/server/World/Kit/Rides",
	ROOT .. "/server/World/Kit/WeaponModel",
	ROOT .. "/server/World/Npc",
	S .. "CombatService",
	S .. "BreakService",
} do
	mocks[path] = stub
end
mocks[S .. "MonetizationService"] = {
	payMultiplier = function()
		return 1
	end,
	has = function()
		return false
	end,
}
mocks[S .. "WantedService"] = {
	stars = function()
		return 0
	end,
	onDuty = function()
		return false
	end,
	clear = function() end,
}

-- DataService: perfiles en memoria con el mismo addMoney/spend que el de verdad
local profiles = {}
local loaded = {}
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
		player:SetAttribute("Money", data.Money)
		return true
	end,
	spend = function(player, price)
		local data = profiles[player]
		if not data or data.Money < price then
			return false
		end
		data.Money -= price
		player:SetAttribute("Money", data.Money)
		return true
	end,
}

---------------------------------------------------------------------
-- Jugadores de mentira
---------------------------------------------------------------------
local function newPlayer(name: string, userId: number, stage: string)
	local attrs = { LifeStage = stage }
	local changed = {}
	local p = { Name = name, DisplayName = name, UserId = userId, Parent = true, IsPlayer = true, Character = nil, Chatted = signal() }
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
	profiles[p] = {
		Money = 50,
		Hunger = 100,
		Energy = 100,
		Items = {},
		Slots = {},
		Stats = { TasksDone = 0, MoneyEarned = 0 },
		Life = { Stage = stage, AgeYears = 8 },
		Story = { Active = {} },
	}
	table.insert(active, p)
	return p
end

---------------------------------------------------------------------
-- Pruebas
---------------------------------------------------------------------
local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local Config = load(ROOT .. "/shared/Config")
local Weapons = load(ROOT .. "/shared/Weapons")
local Gameplay = load(ROOT .. "/shared/Gameplay")
local TesterService = load(S .. "TesterService")
local JobService = load(S .. "JobService")
local VehicleService = load(S .. "VehicleService")
local WeaponService = load(S .. "WeaponService")
local InventoryService = load(S .. "InventoryService")

-- Un oficio normal (sin sistema propio) con su punto de recogida en el mapa
local JOB = "Repartidor"
check(Config.Jobs[JOB] ~= nil, "existe el oficio de prueba (" .. JOB .. ")")
tagged["Pickup_" .. JOB] = { { Position = roblox.Vector3.new(0, 0, 0), Parent = true } }

local owner = newPlayer("Dueño", CREATOR, "Nino")
local other = newPlayer("Jugador", 4242, "Nino")
TesterService.init()
for _, fn in loaded do
	fn(owner, profiles[owner])
	fn(other, profiles[other])
end
task.wait(0.1)
local remote = remoteList.Tester
check(remote ~= nil, "el remoto Tester existe")

local function fire(player, kind, a, b)
	remote.OnServerEvent:Fire(player, kind, a, b)
	task.wait(0.3) -- (más que el límite de peticiones del servidor)
end

local function weaponsOwned(player): number
	local n = 0
	for id in Weapons.List do
		if InventoryService.count(player, Weapons.itemId(id)) > 0 then
			n += 1
		end
	end
	return n
end
local function totalWeapons(): number
	local n = 0
	for _ in Weapons.List do
		n += 1
	end
	return n
end

print("▶ Quién es tester")
check(TesterService.isTester(owner), "el creador del juego es tester")
check(not TesterService.isTester(other), "otro jugador no lo es")
check(owner:GetAttribute("Tester") == true and other:GetAttribute("Tester") == nil, "solo el tester tiene el atributo Tester")
check(TesterService.bypass(owner) and not TesterService.bypass(other), "solo el tester se salta los requisitos")
Config.Testers = { 4242 }
check(TesterService.isTester(other), "un UserId de Config.Testers también es tester")
Config.Testers = {}

print("▶ Un jugador normal no puede usar el modo pruebas")
local before = #sent
for _, call in {
	{ "Open" },
	{ "Toggle", "Money" },
	{ "Toggle", "Bypass" },
	{ "Action", "Weapons" },
	{ "Action", "Licences" },
	{ "Action", "UnlockAll" },
	{ "Action", "MaxLevel" },
	{ "Action", "Stage", "Adulto" },
	{ "Action", "Hour", 12 },
} do
	fire(other, call[1], call[2], call[3])
end
other.Chatted:Fire("/pruebas")
check(TesterService.chat(other, "/pruebas") == false, "/pruebas no le abre nada")
local toOther = 0
for i = before + 1, #sent do
	if sent[i].Player == other then
		toOther += 1
	end
end
check(toOther == 0, "no recibe ninguna respuesta (se ignora en silencio)")
check(profiles[other].Money == 50, "su dinero no cambia")
check(weaponsOwned(other) == 0, "no recibe armas")
check(not VehicleService.hasLicense(other, "B"), "no recibe carnets")
check(profiles[other].Tester == nil, "no se le guarda nada del modo pruebas")
check(other:GetAttribute("LifeStage") == "Nino", "no cambia de etapa")

print("▶ Oficio con requisitos (edad) para un niño")
JobService.start(other, JOB)
check(other:GetAttribute("Job") == nil, "un niño normal no puede trabajar de " .. JOB)
JobService.start(owner, JOB)
check(owner:GetAttribute("Job") == JOB, "un niño tester sí (sin requisitos)")
JobService.quit(owner, true)
profiles[owner].Energy = 0
JobService.start(owner, JOB)
check(owner:GetAttribute("Job") == JOB, "el tester trabaja aunque no le quede energía")
JobService.quit(owner, true)
profiles[owner].Energy = 100

print("▶ Panel: abrir y estado")
before = #sent
fire(owner, "Open")
local opened = nil
for i = before + 1, #sent do
	if sent[i].Player == owner and sent[i].Remote == "Tester" and sent[i].Kind == "Open" then
		opened = sent[i].Payload
	end
end
check(opened ~= nil and opened.Bypass == true and opened.Money == false, "el tester recibe el estado del panel")
check(opened ~= nil and #opened.Stages >= 4 and #opened.Places >= 5, "con etapas de vida y lugares para el teletransporte")
before = #sent
owner.Chatted:Fire("/pruebas")
local chatOpened = false
for i = before + 1, #sent do
	chatOpened = chatOpened or (sent[i].Player == owner and sent[i].Kind == "Open")
end
check(chatOpened, "/pruebas en el chat abre el panel")

print("▶ Sin requisitos: interruptor")
fire(owner, "Toggle", "Bypass")
check(profiles[owner].Tester.Bypass == false and not TesterService.bypass(owner), "se puede apagar")
JobService.start(owner, JOB)
check(owner:GetAttribute("Job") == nil, "apagado, el niño tester ya no puede trabajar")
fire(owner, "Toggle", "Bypass")
check(TesterService.bypass(owner) and owner:GetAttribute("TesterBypass") == true, "y volver a encender")

print("▶ Dinero infinito")
fire(owner, "Toggle", "Money")
check(profiles[owner].Money == 9999999, "al encenderlo: 9 999 999 €")
check(profiles[owner].Tester.RealMoney == 50, "se guarda el dinero de verdad (50 €)")
mocks[S .. "DataService"].spend(owner, 9500000)
task.wait(0.1)
check(profiles[owner].Money == 9999999, "al gastar y bajar del millón se rellena solo")
fire(owner, "Toggle", "Money")
check(profiles[owner].Money == 50, "al apagarlo vuelve el dinero de antes")
mocks[S .. "DataService"].spend(owner, 10)
task.wait(0.1)
check(profiles[owner].Money == 40, "apagado ya no se rellena")

print("▶ Todas las armas")
fire(owner, "Action", "Weapons")
check(weaponsOwned(owner) == totalWeapons(), ("tiene las %d armas de Weapons.List"):format(totalWeapons()))
check(InventoryService.count(owner, Weapons.Licence.Item) == 1, "y la licencia de armas")
local ammoFull = true
for id, ammo in Weapons.AmmoTypes do
	ammoFull = ammoFull and InventoryService.count(owner, id) == ammo.Stack
end
check(ammoFull, "y munición de cada tipo (casilla llena)")
check(profiles[owner].WeaponMags and profiles[owner].WeaponMags.Pistola == Weapons.List.Pistola.Magazine, "con el cargador lleno")
local again = select(1, WeaponService.grantAll(owner))
check(again == 0, "pedirlas otra vez no duplica nada")

print("▶ Carnets")
fire(owner, "Action", "Licences")
local allLicences = true
for key in Gameplay.Licenses do
	allLicences = allLicences and VehicleService.hasLicense(owner, key)
end
check(allLicences, "tiene todos los carnets de conducir (Gameplay.Licenses)")

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
