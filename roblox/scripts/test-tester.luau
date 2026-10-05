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
do
	local savedNames = Config.TesterNames
	Config.TesterNames = {}
	check(not TesterService.isTester(other), "sin estar en ninguna lista, no es tester")
	Config.TesterNames = { string.upper(other.Name) }
	check(TesterService.isTester(other), "un nombre de Config.TesterNames también es tester (sin mirar mayúsculas)")
	Config.TesterNames = savedNames
end

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

print("▶ Al volante: sin requisitos no hay delito por la edad ni por el carnet")
local function toastsTo(player, from: number, needle: string): boolean
	for i = from + 1, #sent do
		local m = sent[i]
		if m.Player == player and m.Remote == "Notify" and type(m.Payload) == "string" and m.Payload:find(needle, 1, true) then
			return true
		end
	end
	return false
end
-- (el dueño es un niño tester sin carnets: se los quitamos para probar lo de la edad Y el carnet)
profiles[owner].Licenses = {}
check(TesterService.bypass(owner) and owner:GetAttribute("LifeStage") == "Nino", "(el dueño es un niño con «Sin requisitos»)")
check(VehicleService.offenceFor(owner, "Coche") == nil and VehicleService.offenceFor(owner, "Moto") == nil, "un niño tester al volante de un coche o una moto no comete delito")
before = #sent
check(VehicleService.licenceWarning(owner, "Coche") == nil and not toastsTo(owner, before, "Eres menor"), "ni le sale el aviso «Eres menor y no tienes carnet»")
check(VehicleService.offenceFor(other, "Coche") == "MenorVolante", "un niño normal al volante de un coche: «Menor al volante»")
before = #sent
check(VehicleService.licenceWarning(other, "Coche") == "MenorVolante" and toastsTo(other, before, "Eres menor"), "y a él sí le avisa («la policía te parará y llamará a tu familia»)")
check(VehicleService.offenceFor(other, "Bici") == nil, "(la bici no pide carnet a nadie)")
fire(owner, "Toggle", "Bypass")
check(not TesterService.bypass(owner), "«Sin requisitos» apagado…")
check(VehicleService.offenceFor(owner, "Coche") == "MenorVolante", "…el niño tester vuelve a ser un menor al volante (reglas normales)")
before = #sent
check(VehicleService.licenceWarning(owner, "Coche") == "MenorVolante" and toastsTo(owner, before, "Eres menor"), "…y le sale el aviso de siempre")
fire(owner, "Toggle", "Bypass")
local autoLicences = true
for key in Gameplay.Licenses do
	autoLicences = autoLicences and VehicleService.hasLicense(owner, key)
end
check(TesterService.bypass(owner) and autoLicences, "al encender «Sin requisitos» se le dan todos los carnets de conducir")
do
	-- Al entrar al juego con «Sin requisitos»: carnets puestos
	local newcomer = newPlayer("Dueño2", CREATOR, "Nino")
	for _, fn in loaded do
		fn(newcomer, profiles[newcomer])
	end
	task.wait(0.1)
	local all = true
	for key in Gameplay.Licenses do
		all = all and VehicleService.hasLicense(newcomer, key)
	end
	check(all, "un tester que entra con «Sin requisitos» ya tiene los carnets de conducir")
	check(InventoryService.count(newcomer, Weapons.Licence.Item) == 0, "(sin meterle nada en la mochila: la licencia de armas solo con el botón)")
	table.remove(active, table.find(active, newcomer))
end

---------------------------------------------------------------------
-- Pase de temporada apagado (BattlePassConfig.Enabled = false): el tester lo tiene igual, y los
-- vehículos del pase se sacan y se dan desde el panel («🏎️ Vehículos del pase»)
---------------------------------------------------------------------
print("▶ Pase apagado: el tester lo tiene, un jugador normal no")
do
	local BPConfig = load(ROOT .. "/shared/BattlePass/Config")
	local Catalog = load(ROOT .. "/shared/BattlePass/Catalog")
	local BattlePassService = load(S .. "BattlePassService")
	local Season = load(S .. "BattlePassSeasonService")
	local Rewards = load(S .. "BattlePassRewardService")
	local S1 = BPConfig.Seasons[1]
	-- (el pase ya está encendido para todos; antes de que empiece la temporada nadie lo tiene, salvo el tester)
	check(type(BPConfig.Enabled) == "boolean", "(el pase tiene su interruptor)")
	Season.setClock(function()
		return S1.StartsAt - 4 * 86400 -- (antes de que empiece: «Próximamente»)
	end)
	local state = TesterService.state(owner)
	check(type(state.BattlePass) == "table" and Season.activeFor(owner), "el panel del tester trae la sección del pase (premium simulado, nivel, reclamar…)")
	if BPConfig.Enabled then
		check(Season.activeFor(other) and Season.now(other) < S1.StartsAt, "un jugador normal tiene el pase encendido, pero sin adelantar la temporada (eso solo el tester)")
	else
		check(not Season.activeFor(other) and BattlePassService.testerState(other) == nil, "un jugador normal no tiene pase")
	end
	local ownerSnap = BattlePassService.snapshot(owner)
	check(ownerSnap and ownerSnap.Season.Status == "Active" and Season.status(S1, Season.now(other)) == "Upcoming", "para el tester la temporada ya está en marcha (aunque empiece el 5 de octubre); para los demás no")
	fire(owner, "Action", "BattlePass", { Op = "SetLevel", Value = 50 })
	check(profiles[owner].BattlePass.Level == 50, "el tester pone el nivel 50 con el pase apagado")
	fire(other, "Action", "BattlePass", { Op = "SetLevel", Value = 50 })
	check(profiles[other].BattlePass == nil or profiles[other].BattlePass.Level ~= 50, "a un jugador normal no le hace nada")

	print("▶ Vehículos del pase: sacar cada uno")
	local list = state.PassVehicles or {}
	check(#list == 14, ("el panel lista los 14 vehículos del pase (%d)"):format(#list))
	local names = {}
	for _, entry in list do
		names[entry.Name] = true
	end
	check(names["Voltex GT-R"] and names["Storm"] and names["Aurora X «Faro de Valmar»"] and names["Aurora X"], "del Voltex GT-R al Storm, y el Aurora X «Faro de Valmar»")
	-- (el doble de VehicleService.mount apunta lo que se saca; lo demás es el camino de verdad)
	local realMount = VehicleService.mount
	local mounted = {}
	VehicleService.mount = function(player, kind, opts)
		table.insert(mounted, { Player = player, Kind = kind, Opts = opts })
		return true
	end
	local humanoid = { Health = 100, SeatPart = nil }
	owner.Character = { FindFirstChildOfClass = function()
		return humanoid
	end }
	local byId = {}
	for _, entry in Catalog.vehicles() do
		byId[entry.Id] = entry
	end
	local good = 0
	for _, entry in list do
		local n = #mounted
		task.wait(2.1) -- (como el menú: como mucho 3 cada 6 s)
		TesterService.handle(owner, "Action", "PassVehicle", entry.Id)
		local m = mounted[n + 1]
		local spec = byId[entry.Id]
		local opts = m and m.Opts
		if m and m.Player == owner and spec and m.Kind == spec.Kind and opts and opts.Style and opts.Style.Model == spec.Model and opts.Style.Accent == spec.Trim and opts.Paint == spec.Color then
			good += 1
		else
			print("    (no salió bien: " .. tostring(entry.Id) .. ")")
		end
	end
	check(good == 14, ("el tester saca cada uno con su modelo, su pintura y sus detalles (%d de 14)"):format(good))
	local faro = byId.S1_P50_Car
	check(faro and faro.Model == "AuroraX" and faro.Trim ~= nil, "el «Faro de Valmar» sale como Aurora X con detalles en oro")
	local n = #mounted
	TesterService.handle(other, "Action", "PassVehicle", "VoltexGTR")
	check(#mounted == n, "un jugador normal no saca nada")
	VehicleService.mount = realMount
	owner.Character = nil

	print("▶ Vehículos del pase: «Darme todos»")
	TesterService.handle(owner, "Action", "PassVehiclesAll")
	local owned = profiles[owner].Cosmetics.Owned
	local count = 0
	for _, entry in Catalog.vehicles() do
		if entry.RewardId and owned[entry.RewardId] then
			count += 1
		end
	end
	check(count == 13 and owned.S1_P50_Car ~= nil, ("se le dan como recompensas del pase de verdad (%d de 13, con el «Faro de Valmar»)"):format(count))
	check(profiles[owner].Vehicles.Coche and profiles[owner].Vehicles.Moto, "con el coche y la moto de base (salen en «Mis vehículos»)")
	local models = owner:GetAttribute("BP_VehicleModels")
	local listed = 0
	for _ in string.gmatch(models or "", "[^,]+") do
		listed += 1
	end
	check(listed == 13, ("«Mis vehículos» los lista para elegir (%d)"):format(listed))
	check(VehicleService.ChooseModel ~= nil and VehicleService.ChooseModel(owner, "Coche", "S1_P49") and Rewards.modelFor(owner, "Coche") == "ShadowF1", "y se elige cuál sale: el Shadow F1")
	check(VehicleService.ChooseModel(owner, "Moto", "S1_P42") and Rewards.modelFor(owner, "Moto") == "Storm", "o la Storm en la moto")
	check(not VehicleService.ChooseModel(other, "Coche", "S1_P49"), "un jugador normal no elige nada")
	local again = TesterService.handle(owner, "Action", "PassVehiclesAll")
	check(again, "pulsarlo otra vez no rompe nada (no los duplica)")
	TesterService.handle(other, "Action", "PassVehiclesAll")
	check(profiles[other].Cosmetics == nil or next(profiles[other].Cosmetics.Owned or {}) == nil, "a un jugador normal no le da nada")
	-- «Todos los vehículos» también los da
	local fresh = newPlayer("Dueño3", CREATOR, "Adulto")
	TesterService.handle(fresh, "Action", "Vehicles")
	check(profiles[fresh].Cosmetics and profiles[fresh].Cosmetics.Owned.S1_P04 and profiles[fresh].Cosmetics.Owned.S1_P50_Car, "«Todos los vehículos» incluye los del pase")
	table.remove(active, table.find(active, fresh))
	Season.setClock(nil)
end

---------------------------------------------------------------------
-- Cambiar de etapa con la historia de verdad (scripts/lib/StoryHarness: LifeStoryService real).
-- Como el dueño en la versión publicada: niño en el capítulo del colegio, con «Recados por el
-- barrio» (principal) en marcha y «El vecino del garaje» (secundaria) seguida.
---------------------------------------------------------------------
local okStory, storyError = pcall(function()
	local H = require("./lib/StoryHarness")
	local Story = H.boot()
	local Tester = H.loadModule(H.ROOT .. "/server/Services/TesterService")
	local StoryConfig = H.Config
	local kid = H.newPlayer("DueñoNiño", "Nino", 100)
	StoryConfig.Testers = { kid.UserId }
	local data = H.profiles[kid]
	local story = data.Story
	task.wait(0.5)

	local function prepare(player)
		local st = H.profiles[player].Story
		for _, q in { "Cole01_PrimerDia", "Cole02_Mochila", "Cole03_Grupo", "Cole04_Malotes", "Cole05_Venganza", "Cole06_Examen" } do
			st.Completed[q] = os.time()
			st.Active[q] = nil
		end
		for id, prog in st.Active do
			if prog.Kind == "Main" then
				st.Active[id] = nil
			end
		end
		st.Active.Nino_Recados = { Kind = "Main" }
		Story.resetQuest(player, "Nino_Recados")
		st.Active.Loco_N1_Cosme = { Kind = "Side" }
		Story.resetQuest(player, "Loco_N1_Cosme")
		st.Tracked = "Loco_N1_Cosme"
		task.wait(0.3)
	end

	print("▶ Cambiar de etapa a Adulto en mitad de una misión de niño")
	prepare(kid)
	check(story.Chapter == "Nino_ElColegio" and story.Active.Nino_Recados ~= nil and story.Active.Loco_N1_Cosme ~= nil, "(niño en el colegio con «Recados por el barrio» y «El vecino del garaje»)")
	kid:SetAttribute("InDialogue", true) -- (hablando con alguien: antes eso lo bloqueaba)
	check(Tester.handle(kid, "Action", "Stage", "Adulto") == true, "el panel acepta «Adulto» aunque esté en una conversación")
	task.wait(0.5)
	check(data.Life.Stage == "Adulto" and kid:GetAttribute("LifeStage") == "Adulto", "ya es adulto (datos y atributo LifeStage, del que tiran el cuerpo y la ropa)")
	local ages = StoryConfig.LifeStory.AgeRange.Adulto
	check(data.Life.AgeYears >= ages[1] and data.Life.AgeYears <= ages[2] and kid:GetAttribute("AgeYears") == data.Life.AgeYears, ("con edad de adulto (%d años)"):format(data.Life.AgeYears))
	check(kid:GetAttribute("InDialogue") == nil, "la conversación se corta")
	check(story.Active.Nino_Recados == nil and story.Completed.Nino_Recados == nil, "«Recados por el barrio» (de niño) se deja, sin contar como hecha")
	check(story.Active.Loco_N1_Cosme ~= nil, "«El vecino del garaje» (sin límite de edad) sigue en marcha")
	check(story.Chapter ~= "Nino_ElColegio" and story.Chapter ~= nil, ("capítulo de adulto (%s)"):format(tostring(story.Chapter)))
	local adultMain = nil
	for id, prog in story.Active do
		if prog.Kind == "Main" then
			adultMain = id
		end
	end
	check(adultMain ~= nil and adultMain ~= "Nino_Recados" and adultMain ~= "Nino_Jornada", ("empieza la principal del capítulo de adulto (%s)"):format(tostring(adultMain)))

	print("▶ Se guarda: salir y volver a entrar")
	local saved = H.leave(kid)
	local back = H.rejoin(kid, saved)
	task.wait(0.5)
	local d2 = H.profiles[back]
	check(d2.Life.Stage == "Adulto" and back:GetAttribute("LifeStage") == "Adulto", "al volver sigue siendo adulto")
	check(d2.Life.AgeYears == data.Life.AgeYears and back:GetAttribute("AgeYears") == d2.Life.AgeYears, "con la misma edad")
	check(d2.Story.Chapter == story.Chapter and d2.Story.Active.Nino_Recados == nil, "en el mismo capítulo, sin la misión de niño")

	print("▶ «Hazme adulto» (un toque) y los que no son testers")
	local kid2 = H.newPlayer("DueñoNiño2", "Nino", 100)
	StoryConfig.Testers = { kid.UserId, kid2.UserId }
	task.wait(0.3)
	prepare(kid2)
	check(Tester.handle(kid2, "Action", "MakeAdult") == true and H.profiles[kid2].Life.Stage == "Adulto", "«Hazme adulto» le hace adulto")
	check(H.profiles[kid2].Story.Active.Nino_Recados == nil, "y deja la misión de niño")
	local normal = H.newPlayer("NiñoNormal", "Nino", 100)
	task.wait(0.3)
	check(Tester.handle(normal, "Action", "MakeAdult") == false and H.profiles[normal].Life.Stage == "Nino", "a un jugador normal no le hace nada")
end)
check(okStory, "las pruebas de etapa con la historia de verdad terminan sin errores" .. (if okStory then "" else ": " .. tostring(storyError)))

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
