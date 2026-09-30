-- Prueba del PASE DE TEMPORADA FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-battlepass.luau
--
-- Carga los servicios de verdad del pase (BattlePassService, BattlePassXPService, SeasonMissionService,
-- BattlePassRewardService, BattlePassSeasonService, TesterService) en un Roblox de mentira. Los
-- sistemas que entregan (vehículos, recreativos, progresión…) son dobles que apuntan lo que reciben.
-- Comprueba (plan de QA de docs/pase-de-temporada.md):
--   * progreso gratis sin premium; subir varios niveles de golpe; reclamar una vez (y no dos);
--   * comprar el premium en el nivel 30 entrega las premium 1–30 (y solo esas) y es idempotente;
--   * compra desactivada con GamePassId = 0; fin de compra con otro pase o sin comprar no hace nada;
--   * el remoto ignora valores falsos del cliente y tiene límite de peticiones;
--   * topes diarios de XP y hueco mínimo entre eventos; misiones diarias, semanales, de temporada e
--     historia por fases; eventos de temporada;
--   * fin de temporada: periodo de reclamar, archivo y temporada nueva sin perder nada;
--   * recompensa que ya no existe: compensación sin romper nada;
--   * guardar y cargar (JSON, como DataStore) y el premium simulado del modo pruebas NO se guarda.

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

-- Instancia de mentira: guarda propiedades y atributos, y cualquier método no hace nada
local function fakeInstance(className: string?)
	local attrs = {}
	local obj = { ClassName = className or "Instance", Name = className or "Instance" }
	function obj:SetAttribute(k, v)
		attrs[k] = v
	end
	function obj:GetAttribute(k)
		return attrs[k]
	end
	function obj:IsA(c)
		return c == obj.ClassName or c == "Instance" or (c == "BasePart" and obj.ClassName == "Part")
	end
	function obj:GetChildren()
		return {}
	end
	function obj:FindFirstChild()
		return nil
	end
	return obj
end

local sent: { any } = {}
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

local node
local replicatedStorage = {}
function replicatedStorage:WaitForChild(name)
	return self[name]
end
function replicatedStorage:FindFirstChild(name)
	return rawget(self, name)
end

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

-- Tienda de Roblox de mentira
local market = {
	PromptGamePassPurchaseFinished = signal(),
	owns = {} :: { [number]: boolean }, -- UserId -> tiene el pase
	failures = 0, -- cuántas veces falla UserOwnsGamePassAsync antes de contestar
	prompts = {} :: { any },
	asks = 0,
}
function market:UserOwnsGamePassAsync(userId, _passId)
	market.asks += 1
	if market.failures > 0 then
		market.failures -= 1
		error("HTTP 500 (de mentira)")
	end
	return market.owns[userId] == true
end
function market:PromptGamePassPurchase(player, passId)
	table.insert(market.prompts, { Player = player, PassId = passId })
end
function market:GetProductInfo()
	return { PriceInRobux = 449 }
end

local stubMeta = {}
local stub = setmetatable({}, stubMeta)
stubMeta.__index = function()
	return stub
end
stubMeta.__call = function()
	return stub
end

local fakeGame = { CreatorId = CREATOR, CreatorType = roblox.Enum.CreatorType.User, JobId = "prueba", PlaceId = 1 }
local services = {
	ReplicatedStorage = replicatedStorage,
	Players = players,
	MarketplaceService = market,
	RunService = {
		IsStudio = function()
			return false
		end,
		Heartbeat = signal(),
	},
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

local warnings = 0
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
		Color3 = roblox.Color3,
		CFrame = roblox.CFrame,
		Enum = roblox.Enum,
		Instance = { new = fakeInstance },
		typeof = function(v)
			return if type(v) == "table" and rawget(v, "IsPlayer") then "Instance" else typeof(v)
		end,
		warn = function(...)
			warnings += 1
			print("  [warn]", ...)
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

-- DataService: perfiles en memoria con el mismo addMoney/spend que el de verdad
local profiles = {}
local loaded = {}
local saves = 0
mocks[S .. "DataService"] = {
	get = function(player)
		return profiles[player]
	end,
	waitFor = function(player)
		return profiles[player]
	end,
	onLoaded = function(fn)
		table.insert(loaded, fn)
	end,
	onEarning = function() end,
	save = function()
		saves += 1
		return true
	end,
	addMoney = function(player, amount)
		local data = profiles[player]
		if not data or type(amount) ~= "number" or amount ~= amount then
			return false
		end
		data.Money = math.max(0, math.floor(data.Money + amount))
		player:SetAttribute("Money", data.Money)
		return true
	end,
}
-- Sistemas que entregan: dobles que apuntan lo que reciben
local granted = { Vehicles = {}, Xp = 0, Tickets = 0, Prizes = {}, Outfit = 0 }
mocks[S .. "VehicleService"] = {
	grant = function(player, kind)
		local data = profiles[player]
		data.Vehicles = data.Vehicles or {}
		if data.Vehicles[kind] then
			return false
		end
		data.Vehicles[kind] = true
		table.insert(granted.Vehicles, kind)
		return true
	end,
}
mocks[S .. "ArcadeService"] = {
	addTickets = function(player, n)
		granted.Tickets += n
		return true
	end,
	grantPrize = function(player, id)
		local data = profiles[player]
		data.Prizes = data.Prizes or {}
		if data.Prizes[id] then
			return false
		end
		data.Prizes[id] = true
		return true
	end,
}
mocks[S .. "ProgressionService"] = {
	addXp = function(_, amount)
		granted.Xp += amount
	end,
}
mocks[S .. "AvatarService"] = {
	apply = function()
		granted.Outfit += 1
	end,
}
mocks[S .. "PropertyService"] = {}
mocks[S .. "LocationService"] = {
	resolve = function(_, placeId)
		return { Position = roblox.Vector3.new(10, 0, 20), Place = placeId }
	end,
}
local storyObservers = {}
mocks[S .. "LifeStoryService"] = {
	observe = function(fn)
		table.insert(storyObservers, fn)
	end,
}
mocks[ROOT .. "/server/World/Kit/Rides"] = {
	build = function(kind)
		return fakeInstance("Model")
	end,
}

---------------------------------------------------------------------
-- Jugadores de mentira
---------------------------------------------------------------------
local function newPlayer(name: string, userId: number, stage: string)
	local attrs = { LifeStage = stage }
	local p = { Name = name, DisplayName = name, UserId = userId, Parent = true, IsPlayer = true, Character = nil, Chatted = signal() }
	function p:SetAttribute(k, v)
		attrs[k] = v
	end
	function p:GetAttribute(k)
		return attrs[k]
	end
	function p:GetAttributeChangedSignal()
		return signal()
	end
	function p:GetRankInGroup()
		return 0
	end
	profiles[p] = {
		Money = 100,
		Hunger = 100,
		Energy = 100,
		Stats = { TasksDone = 0, MoneyEarned = 0 },
		Life = { Stage = stage, AgeYears = 25 },
	}
	table.insert(active, p)
	for _, fn in loaded do
		fn(p, profiles[p])
	end
	return p
end

local function removePlayer(p)
	local i = table.find(active, p)
	if i then
		table.remove(active, i)
	end
	players.PlayerRemoving:Fire(p)
	profiles[p] = nil
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

local BPConfig = load(ROOT .. "/shared/BattlePass/Config")
local Catalog = load(ROOT .. "/shared/BattlePass/Catalog")
local SeasonMath = load(ROOT .. "/server/BattlePass/SeasonMath")
local Season = load(S .. "BattlePassSeasonService")
local Rewards = load(S .. "BattlePassRewardService")
local Missions = load(S .. "SeasonMissionService")
local BattlePass = load(S .. "BattlePassService")
local XP = load(S .. "BattlePassXPService")
local TesterService = load(S .. "TesterService")
local StoryEvents = load(ROOT .. "/server/LifeStory/StoryEvents")

local S1 = BPConfig.Seasons[1]
check(BPConfig.Enabled == false, "el pase viene APAGADO por defecto (BattlePassConfig.Enabled = false)")
-- Apagado: los servicios no hacen nada (ni remoto, ni ganchos, ni escuchar eventos)
do
	for _, name in { "BattlePassRewardService", "BattlePassService", "BattlePassXPService" } do
		load(S .. name).init()
	end
	local VehicleMock = mocks[S .. "VehicleService"]
	check(remoteList.BattlePass == nil and #loaded == 0 and VehicleMock.PaintFor == nil, "apagado: sin remoto, sin datos al entrar y sin ganchos")
	local Tester = load(S .. "TesterService")
	check(load(S .. "BattlePassService").testerState({}) == nil, "apagado: el modo pruebas no enseña el pase")
end
BPConfig.Enabled = true -- (para el resto de la prueba, encendido)
local clock = S1.StartsAt - 3600 -- una hora antes de empezar
Season.setClock(function()
	return clock
end)

for _, name in { "BattlePassSeasonService", "BattlePassRewardService", "SeasonMissionService", "BattlePassService", "BattlePassXPService", "TesterService" } do
	load(S .. name).init()
end
check(mocks[S .. "VehicleService"].PaintFor ~= nil and mocks[S .. "AvatarService"].OutfitFor ~= nil and mocks[S .. "PropertyService"].DecorateOwned ~= nil, "encendido: ganchos en vehículos, ropa y vivienda")
local remote = remoteList.BattlePass

local function lastSent(player, kind, remoteName: string?)
	for i = #sent, 1, -1 do
		local s = sent[i]
		if s.Player == player and s.Kind == kind and (remoteName == nil or s.Remote == remoteName) then
			return s.Payload
		end
	end
	return nil
end

local function fire(player, action, a, b, c)
	remote.OnServerEvent:Fire(player, action, a, b, c)
	task.wait(0.2) -- (más que el hueco mínimo entre peticiones)
end

local function money(player): number
	return profiles[player].Money
end

-- Todas las recompensas: una por nivel y pista
print("▶ Datos de la temporada 1")
do
	local count, free, premium, bad = 0, 0, 0, {}
	local ids = {}
	for _, r in S1.Rewards do
		count += 1
		if r.Track == "Free" then
			free += 1
		else
			premium += 1
		end
		if ids[r.Id] then
			table.insert(bad, "Id repetido " .. r.Id)
		end
		ids[r.Id] = true
		if not (r.Name and r.Icon and r.Rarity and r.Type and r.Description and BPConfig.Rarities[r.Rarity] and BPConfig.TypeNames[r.Type]) then
			table.insert(bad, r.Id)
		end
	end
	check(count == 100 and free == 50 and premium == 50, "50 niveles con recompensa gratis y premium (100 en total)")
	check(#bad == 0, "todas tienen Id único, nombre, icono, rareza, tipo y descripción" .. (if #bad > 0 then " (" .. table.concat(bad, ", ") .. ")" else ""))
	local legendary = Season.reward(S1, 50, "Premium")
	check(legendary and legendary.Rarity == "Legendaria", "el nivel 50 premium es legendario (" .. (legendary and legendary.Name or "?") .. ")")
	local total = SeasonMath.totalFor(S1.Xp, S1.MaxLevel)
	check(total == 77420, ("XP total hasta el 50: %d"):format(total))
	-- Jugador normal (~50 min al día): ~70% de las diarias, ~1/7 de las semanales, actividad ~650 y las de
	-- temporada repartidas. Debe llegar al 50 en unas 7–8 semanas (y no en 2).
	local dailyMissions = 3 * 140 * 0.7
	local weeklyMissions = 5 * 520 / 7 * 0.8
	local seasonMissions = 0
	for _, def in S1.Missions.Season do
		seasonMissions += def.Xp
	end
	local perDay = dailyMissions + weeklyMissions + 650 + seasonMissions * 0.6 / 63
	local days = total / perDay
	check(days >= 42 and days <= 60, ("un jugador normal llega al 50 en ~%.0f días (%.1f semanas)"):format(days, days / 7))
	local maxPerDay = 3 * 150 + 5 * 600 / 7 + BPConfig.DailyActivityCap + seasonMissions / 63
	check(total / maxPerDay >= 28, ("ni jugando al máximo cada día se llega antes de %.0f días"):format(total / maxPerDay))
	local moneyFree, moneyPremium = 0, 0
	for _, r in S1.Rewards do
		if r.Type == "Money" then
			if r.Track == "Free" then
				moneyFree += r.Amount
			else
				moneyPremium += r.Amount
			end
		end
	end
	check(moneyFree <= 3000 and moneyPremium <= 2000, ("poco dinero: %d € gratis y %d € premium en toda la temporada"):format(moneyFree, moneyPremium))
	check(S1.GamePassId == 0 and BPConfig.PriceConfiguredExternally == true, "el precio no está en el código (GamePassId = 0 de momento)")
	check(Catalog.get("S1_P50_Car") ~= nil and Catalog.get("S1_P50_Car").Parent == "S1_P50", "el catálogo conoce lo que va dentro de los conjuntos")
end

print("▶ Antes de empezar la temporada")
local ana = newPlayer("Ana", 1001, "Adulto")
local bp = profiles[ana].BattlePass
check(bp ~= nil and bp.SeasonId == "S1" and bp.Level == 1, "al entrar se crea su pase (temporada S1, nivel 1)")
check(Season.status(S1) == "Upcoming", "la temporada está «Próximamente»")
check(BattlePass.addXp(ana, 5000, "Test") == 0, "no se gana XP antes de empezar")
local ok, code = BattlePass.claim(ana, "Free", 1)
check(not ok and code == "NotStarted", "no se reclama antes de empezar")

clock = S1.StartsAt + 3 * 86400 + 3600 -- jueves de la primera semana
print("▶ Progreso gratis sin premium")
check(Season.status(S1) == "Active", "la temporada está en marcha")
local before = money(ana)
BattlePass.addXp(ana, Season.totalFor(S1, 3), "Test")
check(bp.Level == 3, "sube al nivel 3")
check(BattlePass.claim(ana, "Free", 1), "reclama la gratis del 1 (título)")
check(BattlePass.claim(ana, "Free", 2), "reclama la gratis del 2 (150 €)")
check(money(ana) == before + 150, "recibe 150 € (una vez)")
ok, code = BattlePass.claim(ana, "Free", 2)
check(not ok and code == "AlreadyClaimed" and money(ana) == before + 150, "reclamar dos veces: rechazado y sin dinero de más")
ok, code = BattlePass.claim(ana, "Premium", 1)
check(not ok and code == "PremiumLocked", "la premium sin pase: PREMIUM_LOCKED")
ok, code = BattlePass.claim(ana, "Free", 4)
check(not ok and code == "Locked", "un nivel no alcanzado: bloqueado")
check(ana:GetAttribute("BP_Title") == "Vecino/a de Valmar", "el título se equipa solo y se ve (atributo BP_Title)")
local snap = BattlePass.snapshot(ana)
local states = {}
for _, r in snap.Rewards do
	states[r.Track .. r.Level] = r.State
end
check(states.Free1 == "CLAIMED" and states.Free3 == "AVAILABLE" and states.Free4 == "LOCKED" and states.Premium1 == "PREMIUM_LOCKED", "estados: RECLAMADA, DISPONIBLE, BLOQUEADA y PREMIUM BLOQUEADA")
check(snap.Premium.ComingSoon == true and snap.Premium.PurchaseEnabled == false, "sin GamePassId el premium sale «Próximamente»")
check(#snap.Rewards == 100 and snap.Progress.Level == 3 and snap.Season.Name == S1.Name, "el estado para la interfaz trae las 100 recompensas y el nivel")
local fieldsOk = true
for _, r in snap.Rewards do
	fieldsOk = fieldsOk and r.Id and r.Name and r.Icon and r.Rarity and r.RarityName and r.Type and r.TypeName and r.Level and r.Track and r.State
end
check(fieldsOk, "cada recompensa trae icono, nombre, rareza, tipo, nivel, pista y estado")
check(snap.Missions and #snap.Missions.Daily.List == 3 and #snap.Missions.Weekly.List == 5, "3 misiones diarias y 5 semanales")
local encodedOk = pcall(serde.encode, "json", { Missions = snap.Missions, Progress = snap.Progress })
check(encodedOk, "el estado se puede mandar (sin funciones ni cosas raras)")

print("▶ Varios niveles de golpe")
local marker = #sent
BattlePass.addXp(ana, Season.totalFor(S1, 12) - bp.TotalXp, "Test")
check(bp.Level == 12, "del 3 al 12 de una vez")
local unlocked = lastSent(ana, "Unlocked", "BattlePass")
check(#sent > marker and unlocked and unlocked.From == 3 and unlocked.Level == 12 and #unlocked.Rewards == 18, "aviso «recompensa desbloqueada» con las 18 recompensas nuevas (gratis + premium)")
local given = BattlePass.claimAll(ana)
check(#given == 10, ("«Reclamar todo» da las 10 gratis que faltaban (dio %d)"):format(#given))
check(ana:GetAttribute("BP_Level") == 12, "atributo BP_Level para el HUD")

print("▶ Aviso de nivel: sin repetirse con el de la interfaz")
do
	local uma = newPlayer("Uma", 1098, "Adulto")
	local function levelNotices(from: number): number
		local n = 0
		for i = from + 1, #sent do
			local s = sent[i]
			if s.Player == uma and s.Remote == "Notify" and type(s.Payload) == "string" and s.Payload:find("¡nivel", 1, true) then
				n += 1
			end
		end
		return n
	end
	local mark = #sent
	BattlePass.addXp(uma, Season.totalFor(S1, 2), "Test")
	local info = lastSent(uma, "Unlocked", "BattlePass")
	check(info and info.Notified == true and levelNotices(mark) == 1, "sin interfaz del pase: el servidor avisa con su Notify (y lo dice: Notified)")
	fire(uma, "Get", "Ui")
	mark = #sent
	BattlePass.addXp(uma, Season.totalFor(S1, 3) - profiles[uma].BattlePass.TotalXp, "Test")
	info = lastSent(uma, "Unlocked", "BattlePass")
	check(info and info.Level == 3 and info.Notified == false and levelNotices(mark) == 0, "con la interfaz del pase (Get con \"Ui\"): solo su «RECOMPENSA DESBLOQUEADA», sin el Notify de «¡nivel n!»")
	removePlayer(uma)
end

print("▶ Cosméticos a la vista: solo lo tuyo y equipado")
do
	local vera = newPlayer("Vera", 1099, "Adulto")
	local cos = profiles[vera].Cosmetics
	cos.Equipped.Nameplate = "S1_F10" -- (equipado a mano sin tenerlo: datos tocados)
	cos.Equipped.HudSkin = "S1_P08"
	cos.Equipped.PhoneTheme = "S1_F10" -- (una placa en el hueco del teléfono)
	Rewards.sync(vera)
	check(vera:GetAttribute("BP_Nameplate") == nil and vera:GetAttribute("BP_HudSkin") == nil and vera:GetAttribute("BP_PhoneTheme") == nil, "lo equipado que no es tuyo no se ve (placa, temas)")
	cos.Owned.S1_F10 = { Type = "Nameplate", Season = "S1", At = 0 }
	Rewards.sync(vera)
	check(vera:GetAttribute("BP_Nameplate") == "S1_F10" and vera:GetAttribute("BP_PhoneTheme") == nil, "tuyo y equipado: se ve; en el hueco equivocado, no")
	cos.Equipped.HudSkin = nil
	check(not Rewards.equip(vera, "HudSkin", "S1_P08") and vera:GetAttribute("BP_HudSkin") == nil, "no se equipa un tema de HUD que no tienes")
	BPConfig.Enabled = false
	cos.Equipped.Nameplate = nil
	Rewards.sync(vera)
	check(vera:GetAttribute("BP_Nameplate") == "S1_F10", "pase apagado: sync no toca nada")
	BPConfig.Enabled = true
	Rewards.sync(vera)
	check(vera:GetAttribute("BP_Nameplate") == nil, "y encendido otra vez vuelve a lo de verdad")
	removePlayer(vera)
end

print("▶ El remoto no se fía del cliente")
local premiumBefore = bp.PremiumOwned
fire(ana, "Claim", "Premium", 5)
check(bp.ClaimedPremium["5"] == nil, "no puede reclamar una premium sin pase")
fire(ana, "Claim", "Free", 999)
check(lastSent(ana, "Result", "BattlePass").Code == "BadRequest", "nivel que no existe: petición no válida")
fire(ana, "Claim", "Free", "13")
fire(ana, "Claim", "Free", 13.5)
check(bp.ClaimedFree["13"] == nil, "niveles como texto o con decimales: nada")
fire(ana, "Claim", { Level = 50, PremiumOwned = true }, 50)
fire(ana, "SetLevel", 50)
fire(ana, "AddXp", 99999)
fire(ana, "Grant", "S1_P50")
check(bp.Level == 12 and bp.PremiumOwned == premiumBefore and bp.TotalXp == Season.totalFor(S1, 12), "nivel, XP y premium no cambian por lo que mande el cliente")
task.wait(BPConfig.RateLimit.Window + 0.1) -- (el límite de peticiones ya se ha gastado arriba)
fire(ana, "Buy")
check(lastSent(ana, "Result", "BattlePass").Code == "ComingSoon" and #market.prompts == 0, "comprar con GamePassId = 0: «Próximamente» y no se abre la compra")
fire(ana, "Get")
check(lastSent(ana, "State", "BattlePass") ~= nil, "«Get» devuelve el estado")

print("▶ Límite de peticiones")
task.wait(BPConfig.RateLimit.Window + 0.1)
local allowed = 0
for _ = 1, 30 do
	if BattlePass.allow(ana) then
		allowed += 1
	end
end
check(allowed <= 1, ("30 peticiones seguidas: se atiende %d (hueco mínimo)"):format(allowed))
task.wait(BPConfig.RateLimit.Window + 0.1)
allowed = 0
local startedAt = os.clock()
local tries = 0
while os.clock() - startedAt < BPConfig.RateLimit.Window - 0.3 do
	tries += 1
	if BattlePass.allow(ana) then
		allowed += 1
	end
	task.wait(BPConfig.RateLimit.MinGap + 0.02)
end
check(allowed == BPConfig.RateLimit.Burst, ("%d peticiones en %d s: se atienden %d (tope %d)"):format(tries, BPConfig.RateLimit.Window, allowed, BPConfig.RateLimit.Burst))
task.wait(BPConfig.RateLimit.Window + 0.1)

print("▶ Comprar el premium en el nivel 30")
S1.GamePassId = 424242
local bob = newPlayer("Bob", 1002, "Adulto")
local bobBp = profiles[bob].BattlePass
BattlePass.addXp(bob, Season.totalFor(S1, 30), "Test")
check(bobBp.Level == 30 and not bobBp.PremiumOwned, "Bob llega al 30 sin premium")
market.owns[bob.UserId] = false
check(BattlePass.checkOwnership(bob) == false and not bobBp.PremiumOwned, "Roblox dice que no lo tiene: sigue sin premium")
fire(bob, "Buy")
check(#market.prompts == 1 and market.prompts[1].PassId == 424242, "«Comprar» abre la compra oficial de Roblox con el Game Pass de la temporada")
market.PromptGamePassPurchaseFinished:Fire(bob, 999, true)
market.PromptGamePassPurchaseFinished:Fire(bob, 424242, false)
task.wait(0.1)
check(not bobBp.PremiumOwned, "otro Game Pass o compra cancelada: nada")
local bobMoney = money(bob)
market.owns[bob.UserId] = true
market.PromptGamePassPurchaseFinished:Fire(bob, 424242, true)
task.wait(0.2)
local premiumClaims = 0
for l = 1, 30 do
	if bobBp.ClaimedPremium[tostring(l)] == true then
		premiumClaims += 1
	end
end
check(bobBp.PremiumOwned == true and premiumClaims == 30 and bobBp.ClaimedPremium["31"] == nil, "con la compra recibe las 30 premium ya alcanzadas (y la 31 no)")
local premiumMoney = 0
for l = 1, 30 do
	local r = Season.reward(S1, l, "Premium")
	if r.Type == "Money" then
		premiumMoney += r.Amount
	end
end
check(money(bob) == bobMoney + premiumMoney, ("el dinero premium del 1 al 30 llega una vez (+%d €)"):format(premiumMoney))
check(table.find(granted.Vehicles, "Moto") ~= nil and Rewards.paintFor(bob, "Moto") == Season.reward(S1, 15, "Premium").Color, "la moto premium: vehículo normal + su acabado exclusivo al sacarla")
check(saves > 0, "tras la compra se guarda enseguida")
market.PromptGamePassPurchaseFinished:Fire(bob, 424242, true)
BattlePass.checkOwnership(bob)
BattlePass.grantPremium(bob, "GamePass")
task.wait(0.2)
check(money(bob) == bobMoney + premiumMoney, "avisos repetidos de la compra: no se entrega dos veces (idempotente)")
check(bob:GetAttribute("BP_Premium") == true, "atributo BP_Premium")

print("▶ Compra hecha fuera del juego / fallo al preguntar a Roblox")
market.owns[1003] = true -- (lo compró en la web, sin estar en el juego)
market.failures = 2
local cai = newPlayer("Cai", 1003, "Adulto")
task.wait(3.5) -- (reintentos: 1 s y 2 s)
check(profiles[cai].BattlePass.PremiumOwned, "al entrar se comprueba; Roblox falla 2 veces, se reintenta y se activa")
local asks = market.asks
BattlePass.checkOwnership(cai)
check(market.asks == asks, "una vez sabido, no se vuelve a preguntar (caché)")

print("▶ XP por jugar: topes diarios y anti-spam")
local dan = newPlayer("Dan", 1004, "Adulto")
local danBp = profiles[dan].BattlePass
local gap = BPConfig.Sources.Trabajo.MinGap
XP.onEvent(dan, "JobTaskDone", { JobId = "Repartidor" })
local first = danBp.TotalXp
XP.onEvent(dan, "JobTaskDone", { JobId = "Repartidor" })
check(first == BPConfig.JobXp.Repartidor and danBp.TotalXp == first, "dos tareas seguidas en menos de " .. gap .. " s: la segunda no da XP")
BPConfig.Sources.Trabajo.MinGap = 0
for _ = 1, 200 do
	XP.onEvent(dan, "JobTaskDone", { JobId = "Bombero" })
end
check(danBp.Daily.Sources.Trabajo == BPConfig.Sources.Trabajo.Cap, ("200 tareas: el trabajo da como mucho %d XP al día"):format(BPConfig.Sources.Trabajo.Cap))
for _, src in { "Ocio", "Estudio", "Transporte", "Compras", "Encargos", "Hitos" } do
	BPConfig.Sources[src].MinGap = 0
end
for _ = 1, 100 do
	for _, ev in { "WatchedMovie", "LessonCompleted", "RodeMetro", "BoughtItem", "ErrandDone", "Promoted" } do
		XP.onEvent(dan, ev, {})
	end
end
check(danBp.Daily.Xp <= BPConfig.DailyActivityCap, ("toda la actividad del día junta: como mucho %d XP (lleva %d)"):format(BPConfig.DailyActivityCap, danBp.Daily.Xp))
local capped = danBp.Daily.Xp
StoryEvents.emit(dan, "JobTaskDone", { JobId = "Bombero" })
task.wait(0.05)
check(danBp.Daily.Xp == capped, "con el tope lleno, un evento más no suma")
XP.onEvent(dan, "Traveled", { Town = "X", NoXp = true })
check(danBp.Daily.Xp == capped, "un viaje repetido (NoXp) no da XP")
clock += 86400
local fresh = danBp.TotalXp
XP.onEvent(dan, "JobTaskDone", { JobId = "Bombero" })
check(danBp.TotalXp > fresh and danBp.Daily.Xp == BPConfig.JobXp.Bombero, "al día siguiente se puede volver a ganar")
local zoneBefore = danBp.TotalXp
XP.onEvent(dan, "ZoneEntered", { Zone = "Villaverde" })
XP.onEvent(dan, "ZoneEntered", { Zone = "Villaverde" })
check(danBp.TotalXp - zoneBefore == BPConfig.Sources.Explorar.Events.ZoneEntered, "explorar: un barrio da XP solo la primera vez en la temporada")
local tripBefore = danBp.TotalXp
XP.onEvent(dan, "VehicleTrip", { Kind = "Coche", Km = 2 })
check(danBp.TotalXp - tripBefore == 2 * BPConfig.Sources.Conducir.Events.VehicleTrip, "conducir: XP por km")
XP.onEvent(dan, "VehicleTrip", { Kind = "Coche", Km = 0 / 0 })
XP.onEvent(dan, "VehicleTrip", "no soy una tabla")
check(danBp.TotalXp == tripBefore + 50, "km raros (NaN) o datos rotos: nada")

print("▶ Misiones")
local eva = newPlayer("Eva", 1005, "Adulto")
local eli = newPlayer("Eli", 1006, "Adulto")
local kid = newPlayer("Kiko", 1007, "Nino")
local evaM, eliM = profiles[eva].BattlePass.Missions, profiles[eli].BattlePass.Missions
check(table.concat(evaM.Daily.Ids, ",") == table.concat(eliM.Daily.Ids, ","), "dos jugadores de la misma edad tienen las mismas diarias (iguales en todos los servidores)")
local kidJobs = false
for _, id in profiles[kid].BattlePass.Missions.Daily.Ids do
	kidJobs = kidJobs or id == "D_Turno" or id == "D_Gimnasio"
end
for _, id in profiles[kid].BattlePass.Missions.Weekly.Ids do
	kidJobs = kidJobs or id == "W_Turnos"
end
check(not kidJobs, "a un niño no le tocan misiones de trabajo")
local dailyId = evaM.Daily.Ids[1]
local dailyDef = nil
for _, def in S1.Missions.Daily do
	if def.Id == dailyId then
		dailyDef = def
	end
end
local evaBp = profiles[eva].BattlePass
local xpBefore = evaBp.TotalXp
for _ = 1, dailyDef.Goal + 2 do
	local payload = if dailyDef.Measure == "Km" then { Km = 1 } else { JobId = "Barista" }
	Missions.onEvent(eva, dailyDef.Events[1], payload)
end
check(evaM.Daily.Prog[dailyId] and evaM.Daily.Prog[dailyId].Done, "misión diaria «" .. dailyDef.Title .. "» completada jugando")
check(evaBp.TotalXp - xpBefore == dailyDef.Xp, ("da su XP una sola vez (+%d)"):format(dailyDef.Xp))
check(lastSent(eva, "MissionDone", "BattlePass") ~= nil, "aviso de misión completada")
-- Semanal de barrios distintos (si le ha tocado) y de temporada
local distinct = { Id = "W_Test", Title = "Prueba de barrios", Events = { "ZoneEntered" }, Measure = "Distinct", DistinctField = "Zone", Goal = 3, Xp = 10 }
table.insert(S1.Missions.Weekly, distinct)
evaM.Weekly.Ids[1] = "W_Test"
for _, zone in { "Valmar Centro", "Valmar Centro", "San Roque", "Los Pinos" } do
	Missions.onEvent(eva, "ZoneEntered", { Zone = zone })
end
check(evaM.Weekly.Prog.W_Test.Done, "«visita 3 barrios distintos»: repetir barrio no cuenta dos veces")
table.remove(S1.Missions.Weekly)
for _ = 1, 25 do
	Missions.onEvent(eva, "RodeMetro", { Station = "Campus" })
end
check(evaM.Season.S_Viajero and evaM.Season.S_Viajero.Done, "misión de temporada: 25 viajes en transporte")
-- Semana nueva: semanales nuevas
local oldWeek = evaM.Weekly.Key
clock += 7 * 86400
BattlePass.ensure(eva)
check(profiles[eva].BattlePass.Missions.Weekly.Key ~= oldWeek and next(profiles[eva].BattlePass.Missions.Weekly.Prog) == nil, "cada lunes se renuevan las semanales")

print("▶ Historia de temporada por fases")
local story = S1.Missions.Story[1]
local iris = newPlayer("Iris", 1013, "Adulto")
local st = function()
	return profiles[iris].BattlePass.Missions.Story[story.Id]
end
BattlePass.ensure(iris)
Missions.onEvent(iris, "ZoneEntered", { Zone = "San Roque" })
check((st() == nil or st().Phase == 1), "fase 1: ir a otro barrio no vale")
check(Missions.track(iris, story.Id) and iris:GetAttribute("SeasonTarget") ~= nil, "«Seguir» la fase pone el destino en el GPS (SeasonTarget)")
Missions.onEvent(iris, "ZoneEntered", { Zone = "Valmar Centro" })
check(st().Phase == 2 and iris:GetAttribute("SeasonTarget") == nil, "fase 1 hecha en la Plaza del Centro (el GPS se quita)")
Missions.onEvent(iris, "Talk", { Npc = "Mateo" })
Missions.onEvent(iris, "RodeMetro", { Station = "Levante" })
for _ = 1, 5 do
	Missions.onEvent(iris, "JobTaskDone", { JobId = "Barista" })
end
Missions.onEvent(iris, "ZoneEntered", { Zone = "Playa Dorada" })
Missions.onEvent(iris, "ZoneEntered", { Zone = "Villaverde" })
check(st().Phase == #story.Phases and not st().Done, "llega a la decisión final")
local okChoice, codeChoice = Missions.choose(iris, story.Id, "Inventada")
check(not okChoice and codeChoice == "BadRequest", "una opción que no existe no vale")
check(Missions.choose(iris, story.Id, "Modernizar") and st().Done and st().Choice == "Modernizar", "decide y la historia se completa")
check(profiles[iris].Cosmetics.Owned[story.Reward.Id] ~= nil, "recibe el título de recuerdo «" .. story.Reward.Name .. "»")

print("▶ Evento de temporada")
local event = S1.Events[1]
local saved = clock
clock = event.StartsAt + 3600
check(Season.eventMultiplier(S1) == math.min(event.XpMultiplier, BPConfig.MaxEventMultiplier), "durante «" .. event.Name .. "» la XP de actividad sube un poco")
event.XpMultiplier = 10
check(Season.eventMultiplier(S1) == BPConfig.MaxEventMultiplier, "aunque un evento diga ×10, el tope es ×" .. BPConfig.MaxEventMultiplier)
event.XpMultiplier = 1.25
local evSnap = BattlePass.snapshot(eva)
check(#evSnap.Events == 1 and #evSnap.Missions.Event.List == 1, "el evento y su misión salen en el estado")
clock = saved

print("▶ Equipar y colección")
local okEquip, codeEquip = Rewards.equip(eva, "Title", "S1_P50_Title")
check(not okEquip and codeEquip == "NotOwned", "no se puede equipar lo que no tienes")
check(Rewards.equip(iris, "Title", story.Reward.Id) and iris:GetAttribute("BP_Title") == story.Reward.Text, "equipar un título tuyo")
okEquip = Rewards.equip(iris, "Nameplate", story.Reward.Id)
check(not okEquip, "un título no va en el hueco de la placa")
check(Rewards.equip(iris, "Title", nil) and iris:GetAttribute("BP_Title") == nil, "quitarse el título")

print("▶ Recompensa que ya no existe")
local removed = table.clone(S1.Rewards)
local frank = newPlayer("Frank", 1008, "Adulto")
BattlePass.addXp(frank, Season.totalFor(S1, 4), "Test")
for i, r in S1.Rewards do
	if r.Level == 4 and r.Track == "Free" then
		table.remove(S1.Rewards, i)
		break
	end
end
local frankMoney = money(frank)
local okMissing, codeMissing = BattlePass.claim(frank, "Free", 4)
check(okMissing and codeMissing == "Compensated" and money(frank) == frankMoney + BPConfig.MissingRewardFallback.Amount, "se reclama igual y llega la compensación (sin errores)")
S1.Rewards = removed
profiles[frank].Cosmetics.Owned["S9_Borrado"] = { Type = "Title", Season = "S9" }
profiles[frank].Cosmetics.Equipped.Title = "S9_Borrado"
Rewards.sync(frank)
check(frank:GetAttribute("BP_Title") == nil and BattlePass.snapshot(frank) ~= nil, "algo guardado que ya no está en el catálogo se ignora sin romper nada")
local okBad = Rewards.grant(frank, { Id = "X", Type = "Vehicle", Kind = "Nave espacial" }, "S1")
check(okBad, "un vehículo que no existe da la compensación")

print("▶ Modo pruebas: premium simulado")
local owner = newPlayer("Dueño", CREATOR, "Adulto")
local ownerBp = profiles[owner].BattlePass
local tester = remoteList.Tester
tester.OnServerEvent:Fire(owner, "Action", "BattlePass", { Op = "Premium" })
task.wait(0.3)
check(BattlePass.isPremium(owner) and ownerBp.PremiumOwned == false, "premium simulado: cuenta como premium pero NO se guarda como comprado")
tester.OnServerEvent:Fire(owner, "Action", "BattlePass", { Op = "SetLevel", Value = 10 })
task.wait(0.3)
check(ownerBp.Level == 10, "el tester pone el nivel 10")
check(BattlePass.claim(owner, "Premium", 3) and ownerBp.ClaimedPremium["3"] == "T", "lo reclamado con premium simulado queda marcado «T» (no es una compra)")
tester.OnServerEvent:Fire(owner, "Action", "BattlePass", { Op = "NextDay" })
task.wait(0.3)
check(Season.now(owner) - Season.now() == 86400 and Season.now(ana) == Season.now(), "adelantar el día solo le cambia el reloj a él")
local notTester = newPlayer("Gil", 1009, "Adulto")
tester.OnServerEvent:Fire(notTester, "Action", "BattlePass", { Op = "Premium" })
task.wait(0.3)
check(not BattlePass.isPremium(notTester) and not BattlePass.testerAction(notTester, { Op = "SetLevel", Value = 50 }), "a quien no es tester no le hace nada")

print("▶ Guardar y cargar (JSON como DataStore)")
local function roundTrip(player)
	local data = profiles[player]
	local copy = serde.decode("json", serde.encode("json", { BattlePass = data.BattlePass, Cosmetics = data.Cosmetics, SeasonArchive = data.SeasonArchive, Money = data.Money }))
	removePlayer(player)
	local again = newPlayer(player.Name, player.UserId, "Adulto")
	for k, v in copy do
		profiles[again][k] = v
	end
	for _, fn in loaded do
		fn(again, profiles[again])
	end
	return again
end
local ownerAgain = roundTrip(owner)
local ob = profiles[ownerAgain].BattlePass
check(ob.Level == 10 and ob.ClaimedPremium["3"] == "T" and ob.PremiumOwned == false, "tras volver a entrar: mismo nivel y reclamos")
check(not BattlePass.isPremium(ownerAgain), "el premium simulado NO vuelve (no se guardó)")
check(Season.now(ownerAgain) == Season.now(), "ni el reloj adelantado")
local bobAgain = roundTrip(bob)
local bb = profiles[bobAgain].BattlePass
check(bb.PremiumOwned == true and bb.Level == 30 and bb.ClaimedPremium["30"] == true, "el premium comprado y los reclamos sí se conservan")
check(Rewards.paintFor(bobAgain, "Moto") ~= nil, "y el acabado de la moto sigue equipado")
local snap2 = BattlePass.snapshot(bobAgain)
check(snap2 and snap2.Premium.Purchased and snap2.Progress.Level == 30, "el estado se rehace bien tras cargar")
-- Datos rotos o viejos
local weird = newPlayer("Viejo", 1010, "Adulto")
profiles[weird].BattlePass = { SeasonId = 5, TotalXp = "300", ClaimedFree = "roto", PremiumOwned = "sí" }
profiles[weird].Cosmetics = nil
local wbp = BattlePass.ensure(weird)
check(wbp and wbp.PremiumOwned == false and type(wbp.ClaimedFree) == "table" and profiles[weird].Cosmetics.Tokens == 0, "una partida con datos rotos se arregla sola (y nunca da premium por error)")

print("▶ Más allá del 50: fichas (solo cosméticos)")
local gus = newPlayer("Gus", 1011, "Adulto")
BattlePass.addXp(gus, Season.totalFor(S1, 50) + BPConfig.Tokens.OverflowXpPerToken * 3 + 10, "Test")
check(profiles[gus].BattlePass.Level == 50 and profiles[gus].Cosmetics.Tokens == 3, "la XP de más da fichas (3)")
BattlePass.addXp(gus, BPConfig.Tokens.OverflowXpPerToken * 100, "Test")
check(profiles[gus].Cosmetics.Tokens == BPConfig.Tokens.MaxFromOverflow, ("con tope: %d fichas por temporada"):format(BPConfig.Tokens.MaxFromOverflow))
local item = S1.TokenShop[1]
check(BattlePass.buyToken(gus, item.Id) and profiles[gus].Cosmetics.Owned[item.Id] and profiles[gus].Cosmetics.Tokens == BPConfig.Tokens.MaxFromOverflow - item.Cost, "comprar «" .. item.Name .. "» en la tienda de fichas")
local okTwice, codeTwice = BattlePass.buyToken(gus, item.Id)
check(not okTwice and codeTwice == "AlreadyClaimed", "cada artículo una vez")
local okReroll, codeReroll = Missions.reroll(gus, profiles[gus].BattlePass.Missions.Daily.Ids[1])
check(not okReroll and codeReroll == "NoPerk", "cambiar una diaria pide la comodidad premium")
BattlePass.claim(gus, "Free", 50)
check(profiles[gus].Cosmetics.Owned.S1_F50_Title and profiles[gus].Cosmetics.Owned.S1_F50_Decor, "el conjunto del 50 gratis entrega todo lo de dentro")
local okAgain30, codeAgain30 = BattlePass.claim(bobAgain, "Premium", 30)
check(not okAgain30 and codeAgain30 == "AlreadyClaimed", "tras volver a entrar, lo ya reclamado sigue reclamado")
-- Bob sube al 50 y reclama la legendaria
BattlePass.addXp(bobAgain, Season.totalFor(S1, 50), "Test")
check(BattlePass.claim(bobAgain, "Premium", 50), "Bob reclama la legendaria del 50")
local bc = profiles[bobAgain].Cosmetics
check(bc.Owned.S1_P50_Car and bc.Owned.S1_P50_Title and bc.Owned.S1_P50_Plate and bc.Owned.S1_P50_Decor and table.find(granted.Vehicles, "Coche"), "con el coche «Faro de Valmar», su título, su placa y la decoración")
check(Missions.reroll(bobAgain, profiles[bobAgain].BattlePass.Missions.Daily.Ids[2]), "con la comodidad premium (nivel 30) cambia una diaria")
local okR2, codeR2 = Missions.reroll(bobAgain, profiles[bobAgain].BattlePass.Missions.Daily.Ids[3])
check(not okR2 and codeR2 == "AlreadyRerolled", "solo una al día")

print("▶ Fin de temporada y temporada nueva")
local hal = newPlayer("Hal", 1012, "Adulto")
BattlePass.addXp(hal, Season.totalFor(S1, 8), "Test")
BattlePass.claim(hal, "Free", 1)
clock = S1.EndsAt + 3600
check(Season.status(S1) == "Grace", "acabada: periodo para reclamar")
check(BattlePass.addXp(hal, 5000, "Test") == 0, "ya no se gana XP")
check(BattlePass.claim(hal, "Free", 2), "pero aún se reclama lo alcanzado")
clock = S1.EndsAt + (BPConfig.ClaimGraceDays + 1) * 86400
local okLate, codeLate = BattlePass.claim(hal, "Free", 3)
check(not okLate and codeLate == "SeasonClosed", "pasado el periodo ya no")
-- Temporada 2 (de prueba)
local S2 = table.clone(S1)
S2.Id = "S2"
S2.Name = "Temporada de prueba"
S2.StartsAt = S1.EndsAt + 14 * 86400
S2.EndsAt = S2.StartsAt + 63 * 86400
S2.GamePassId = 0
table.insert(BPConfig.Seasons, S2)
clock = S2.StartsAt + 3600
local halMoney = money(hal)
local halBp = BattlePass.ensure(hal)
local archive = profiles[hal].SeasonArchive.S1
check(halBp.SeasonId == "S2" and halBp.TotalXp == 0 and halBp.Level == 1, "empieza la temporada 2 desde el nivel 1")
check(archive and archive.Level == 8 and archive.FreeClaimed == 8, "la temporada 1 queda en el historial (nivel 8, 8 gratis: las que faltaban se entregaron solas)")
check(money(hal) > halMoney, "lo alcanzado y sin reclamar se entregó al archivar (nada se pierde)")
check(profiles[hal].Cosmetics.Owned.S1_F01 ~= nil and hal:GetAttribute("BP_Title") ~= nil, "el título de la temporada 1 sigue siendo suyo y equipado")
local bobS2 = BattlePass.ensure(bobAgain)
check(bobS2.SeasonId == "S2" and bobS2.PremiumOwned == false and profiles[bobAgain].SeasonArchive.S1.PremiumOwned == true, "el premium era de la temporada 1: en la 2 hay que comprar su pase (y queda en el historial)")
check(profiles[bobAgain].Cosmetics.Owned.S1_P50_Car ~= nil and Rewards.paintFor(bobAgain, "Coche") ~= nil, "Bob conserva su coche legendario de la temporada 1")
local hist = BattlePass.snapshot(hal).History
check(#hist == 1 and hist[1].SeasonId == "S1", "el historial sale en el estado")
BattlePass.ensure(hal)
check(profiles[hal].SeasonArchive.S1.Level == 8, "volver a entrar no archiva otra vez")

print()
if failures == 0 then
	print("✅ Todo correcto")
	process.exit(0)
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
