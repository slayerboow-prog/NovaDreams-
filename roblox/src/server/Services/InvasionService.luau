-- InvasionService: la «Invasión de la Grieta», un evento global del servidor (docs/invasion.md).
--
--   * Cuándo: al abrirse la grieta (shared/Invasion/Rules.OpeningPhases; con el ciclo de demostración,
--     dos veces por día de juego) o con el botón «Lanzar invasión» del modo pruebas (TesterService).
--   * Quién viene: una raza distinta cada vez (shared/Invasion/Races: nunca la misma dos veces
--     seguidas), a veces varias a la vez (y se pelean entre ellas) y, con mala suerte, su DIOS o REY
--     (shared/Invasion/King: fases, puntos débiles, ataques de área, más vida con más jugadores).
--   * Qué hacen: naves en el cielo de los aviones (shared/AirCombat/EnemyAI) que atacan aviones, naves
--     y a la gente; naves de desembarco que ATERRIZAN en sitios abiertos de verdad (Landing: plazas,
--     parques, la playa; nunca en carreteras ni tejados) y sueltan tropas de tierra (AlienAI: andan por
--     las calles, atacan a los jugadores, «alcanzan» a los vecinos —que se transforman en criaturas,
--     nada de sangre— y CONQUISTAN zonas, que los jugadores recuperan). La baliza nodriza en lo alto
--     del cielo, el explorador sobre la bahía y el vuelo de evacuación son de las misiones de vuelo.
--   * Quién manda: TODO el servidor. El daño a los alienígenas llega de las armas de siempre
--     (CombatService/WeaponService con InvasionService.hitModel), del cañón de la avioneta (remoto
--     "Invasion" "PlaneFire": cadencia, calor, cono respecto al morro y rayo del servidor) y del láser
--     de las naves (AirCombatService.ExternalHit). El cliente solo dibuja (Controllers/InvasionClient).
--   * Botín (shared/Invasion/Loot) con topes contra las granjas; premio según lo que haya hecho cada
--     uno (Rules.Points); misiones (shared/Invasion/Missions) y avisos a la historia (StoryEvents:
--     InvasionStarted, InvasionKill, InvasionMission, InvasionRescue, InvasionEnded, InvasionCured,
--     InvasionRepaired).
--   * Después: lo que queda tocado de la ciudad (Transform: gente transformada, destrozos, bolsas de
--     alienígenas, tiendas y paradas cerradas) se arregla con la cadena «Recuperar la normalidad»
--     (Laboratorio Xeno junto al hospital) o solo con el tiempo.
--   * Barato: un bucle a 20 vueltas por segundo SOLO mientras hay algo (invasión, criaturas, bolsas…);
--     topes de enemigos (Rules.Max*); los modelos se quitan al acabar; sin nada, no hace nada.
--
-- Atributos de workspace (para el cliente): InvasionActive, Invasion (JSON: estado, oleada, zonas,
-- razas, rey…), InvasionThreats / InvasionSafe (Panic), InvasionCity (resumen de la ciudad).
-- Del jugador: InvasionBook (JSON: sus misiones), InvasionPoints.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Inv = Shared.Invasion
local Races = require(Inv.Races)
local Rules = require(Inv.Rules)
local Landing = require(Inv.Landing)
local Nav = require(Inv.Nav)
local AlienAI = require(Inv.AlienAI)
local King = require(Inv.King)
local HitCheck = require(Inv.HitCheck)
local Loot = require(Inv.Loot)
local Transform = require(Inv.Transform)
local Panic = require(Inv.Panic)
local Missions = require(Inv.Missions)
local SkyRift = require(Shared.SkyRift)
local GameClock = require(Shared.GameClock)
local Config = require(Shared.Config)
local Layers = require(Shared.Cosmos.Layers)
local EnemyAI = require(Shared.AirCombat.EnemyAI)
local ShipWeapons = require(Shared.AirCombat.ShipWeapons)

local AlienModels = require(script.Parent.Parent.World.Kit.AlienModels)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)

local InvasionService = {}

InvasionService.Tick = 0.05
InvasionService.ThinkEvery = 0.1 -- (tropas de tierra)
InvasionService.ZoneEvery = 0.5
InvasionService.PublishEvery = 0.5
InvasionService.ThreatEvery = 1
InvasionService.CityEvery = 0.5
InvasionService.DespawnFar = 1600 -- tropas sin ningún jugador a menos de esto se quitan (o no se mueven)
InvasionService.RescuePerZone = 2
InvasionService.MaxRescue = 6
InvasionService.MaxResponders = 6
InvasionService.ActionGap = 0.25
InvasionService.Bay = Vector3.new(700, 320, 3900) -- (sobre la bahía del puerto: el explorador)
InvasionService.BeaconAt = Vector3.new(0, 1560, -200) -- (en lo alto del cielo de la ciudad: solo naves)
InvasionService.EvacRoute = { Vector3.new(-2850, 260, 3050), Vector3.new(-3400, 420, 2200), Vector3.new(-4300, 520, 900), Vector3.new(-5600, 600, -400) }
InvasionService.EvacSpeed = 70
InvasionService.LabOffset = Vector3.new(30, 0, 18)

local rng = Random.new()
local function r(): number
	return rng:NextNumber()
end

local function now(): number
	return os.clock()
end

local flinchAt: { [string]: number } = {} -- (último respingo avisado de cada alienígena: sin inundar el remoto)

local function service(name: string): any
	local ok, result = pcall(function()
		return require(script.Parent[name])
	end)
	return if ok then result else nil
end

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
type Air = { Id: string, Kind: string, Race: string, AI: any, Hp: number, MaxHp: number, Model: Model, Root: BasePart, Mission: string?, Until: number? }
type Ground = { Id: string, AI: AlienAI.Alien, Model: Model, Root: BasePart, GroundAt: number, Pocket: string? }
type Drop = { Id: string, Race: string, Zone: string, Pos: Vector3, Land: Vector3, Hp: number, MaxHp: number, Model: Model, Root: BasePart, Phase: string, Since: number, Left: number, NextOut: number }
type ZoneRec = { Id: string, Name: string, Pos: Vector3, Control: number, Conquered: boolean, Siege: { { Id: string, Pos: Vector3 } }, Damaged: number, Fell: boolean? }
type Event = {
	Id: number,
	Lineup: Races.Lineup,
	State: string,
	Since: number,
	Started: number,
	Wave: number,
	Waves: number,
	Spawned: boolean,
	Open: boolean,
	Zones: { [string]: ZoneRec },
	Contrib: { [number]: number },
	DamageBy: { [string]: { [number]: number } },
	KingRec: any?,
	Outcome: string?,
	Reason: string?,
	EndAt: number?,
	Tester: boolean,
	Killed: number,
	Conquests: number,
	Retakes: number,
}

local E: Event? = nil
local history = { Last = nil :: string?, SinceKing = 0, Count = 0, LastEnd = nil :: number? }
local city = Transform.newCity()
local air: { [string]: Air } = {}
local ground: { [string]: Ground } = {}
local drops: { [string]: Drop } = {}
local bolts: { { [string]: any } } = {}
local creatures: { [string]: { Rec: Transform.Creature, Model: Model, Root: BasePart, BiteAt: number } } = {}
local damages: { [string]: Model } = {}
local shutters: { [string]: Instance } = {}
local rescue: { [string]: { Model: Model, Zone: string, Since: number, Prompt: ProximityPrompt? } } = {}
local responders: { { Model: Model, Zone: string, FireAt: number, SayAt: number } } = {}
local cones: { Instance } = {}
local explosions: { { Pos: Vector3, Until: number } } = {}
local special = { Scout = nil :: Air?, Beacon = nil :: any, Evac = nil :: any }
local pstate: { [Player]: { [string]: any } } = {}
local serial = 0
local folder: Folder? = nil
local remote: RemoteEvent? = nil
local notify: RemoteEvent? = nil
local loop: RBXScriptConnection? = nil
local wasOpen = false
local safePoints: { Panic.Safe } = {}
local lab: { Model: Model?, Pos: Vector3? } = {}
local clocks = { Think = 0, Zone = 0, Publish = 0, Threat = 0, City = 0, Watch = 0 }
local graph: Nav.Graph? = nil

InvasionService._state = function()
	return E
end
InvasionService._air = air
InvasionService._ground = ground
InvasionService._drops = drops
InvasionService._city = city
InvasionService._creatures = creatures
InvasionService._history = history
InvasionService._special = special
InvasionService._pstate = pstate
InvasionService._rescue = rescue
InvasionService._damages = damages
InvasionService._shutters = shutters

local function nextId(prefix: string): string
	serial += 1
	return ("%s%d"):format(prefix, serial)
end

local function getFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = workspace:FindFirstChild("Invasion")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Invasion"
		f.Parent = workspace
	end
	folder = f :: Folder
	return folder :: Folder
end

local function sub(name: string): Instance
	local f = getFolder()
	local s = f:FindFirstChild(name)
	if not s then
		-- (una carpeta: cada modelo de dentro llega entero —Atomic— a quien esté cerca; lejos, nada)
		s = Instance.new("Folder")
		s.Name = name
		s.Parent = f
	end
	return s :: Instance
end

local function stream(model: Model)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
end

---------------------------------------------------------------------
-- Jugadores
---------------------------------------------------------------------
local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root, humanoid
end

local function stateOf(player: Player): { [string]: any }
	local s = pstate[player]
	if not s then
		s = { Counters = Loot.newCounters(now()), Points = 0, LastFire = -math.huge, Heat = 0, HeatAt = now(), PlaneHp = Rules.PlaneHp, Airborne = {}, Sampled = {}, LastAction = -math.huge, ZoneTime = {} }
		pstate[player] = s
	end
	return s
end
InvasionService.stateOf = stateOf

local function isTester(player: Player): boolean
	local ok, yes = pcall(function()
		return service("TesterService").isTester(player)
	end)
	return ok and yes == true
end

-- data.Invasion (con lo que falte)
local function invData(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	if type(data.Invasion) ~= "table" then
		data.Invasion = {}
	end
	local d = data.Invasion
	d.Book = Missions.sanitize(d.Book)
	if type(d.Stash) ~= "table" then
		d.Stash = {}
	end
	if type(d.Collection) ~= "table" then
		d.Collection = {}
	end
	if type(d.Stats) ~= "table" then
		d.Stats = {}
	end
	for _, k in { "Kills", "Invasions", "Kings", "Cured" } do
		d.Stats[k] = tonumber(d.Stats[k]) or 0
	end
	return d
end
InvasionService.invData = invData

-- ¿En Valmar? (no en la arena del combate aéreo, ni en un planeta, ni en el espacio de verdad)
local function inValmar(player: Player): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	local p = root.Position
	return math.abs(p.X) < 7000 and math.abs(p.Z) < 7000 and p.Y < Layers.PlaneBandTop + 200
end

local function valmarPlayers(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		if inValmar(p) then
			table.insert(out, p)
		end
	end
	return out
end
InvasionService.valmarPlayers = valmarPlayers

local function send(player: Player, kind: string, payload: any?)
	if remote then
		remote:FireClient(player, kind, payload)
	end
end

local function broadcast(kind: string, payload: any?)
	if remote then
		remote:FireAllClients(kind, payload)
	end
end

local function toast(player: Player, kind: string, text: string)
	if notify then
		notify:FireClient(player, kind, text)
	end
end

local function worldToast(text: string, kind: string?)
	broadcast("World", { Text = text, Kind = kind or "Warn" })
end
InvasionService.worldToast = worldToast

-- ¿Cómo va este jugador ahora? "Foot" | "Plane" | "Ship" (y su raíz)
local function viaOf(player: Player): (string, BasePart?, any?)
	local ac = service("AirCombatService")
	if ac and ac.world and ac.world(player) == "Cosmos" then
		local st = ac.status(player)
		return "Ship", nil, st
	end
	local av = service("AviationService")
	local plane = av and av.pilotPlane and av.pilotPlane(player)
	if plane then
		return "Plane", plane.Root, plane
	end
	return "Foot", (rootOf(player)), nil
end
InvasionService.viaOf = viaOf

---------------------------------------------------------------------
-- Misiones, puntos y botín
---------------------------------------------------------------------
local function publishBook(player: Player)
	local d = invData(player)
	if not d then
		return
	end
	local list = {}
	for id, p in d.Book.Active do
		local m = Missions.get(id)
		if m then
			table.insert(list, { Id = id, Title = m.Title, Chain = m.Chain, Step = Missions.stepText(id, p), Needs = m.Needs, Giver = m.Giver })
		end
	end
	table.sort(list, function(a, b)
		local order = { Evento = 1, Vuelo = 2, Paz = 3 }
		return (order[a.Chain] or 9) < (order[b.Chain] or 9)
	end)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, list)
	if ok then
		player:SetAttribute("InvasionBook", json)
	end
	player:SetAttribute("InvasionPoints", math.floor(stateOf(player).Points))
end
InvasionService.publishBook = publishBook

local giveItem: (Player, string, number, boolean?) -> boolean

local function rewardMission(player: Player, m: Missions.Mission)
	local rw = m.Reward
	pcall(DataService.addMoney, player, rw.Money, true)
	pcall(function()
		service("ProgressionService").addXp(player, rw.Xp, "Invasion")
	end)
	for id, n in rw.Items or {} do
		giveItem(player, id, n, true)
	end
	toast(player, "Success", ("✅ %s · $%d y %d XP"):format(m.Title, rw.Money, rw.Xp))
	send(player, "MissionDone", { Id = m.Id, Title = m.Title, Outro = m.Outro, Money = rw.Money, Xp = rw.Xp })
	StoryEvents.emit(player, "InvasionMission", { Id = m.Id, Chain = m.Chain, Kind = m.Needs or m.Chain })
end

local function missionEvent(player: Player, name: string, payload: { [string]: any }?)
	local d = invData(player)
	if not d then
		return
	end
	local changed = Missions.event(d.Book, name, payload)
	for _, c in changed do
		local m = Missions.get(c.Id)
		if m and c.Kind == "Done" then
			rewardMission(player, m)
		elseif m and c.Kind == "Step" then
			toast(player, "Info", ("🛸 %s: %s"):format(m.Title, Missions.stepText(c.Id, d.Book.Active[c.Id])))
		end
	end
	if #changed > 0 then
		publishBook(player)
	end
end
InvasionService.missionEvent = missionEvent

local function addPoints(player: Player, n: number)
	local s = stateOf(player)
	s.Points += n
	if E then
		E.Contrib[player.UserId] = (E.Contrib[player.UserId] or 0) + n
	end
end

-- Dar un objeto (con los topes de Loot si no es un premio); lo que no cabe, a la Xenobodega
giveItem = function(player: Player, id: string, count: number, reward: boolean?): boolean
	local d = invData(player)
	if not d or count <= 0 then
		return false
	end
	local kind = Loot.kindOf(id)
	if not reward and not Loot.allow(stateOf(player).Counters, kind, count, now()) then
		return false
	end
	if kind == "Collectible" then
		if d.Collection[id] then
			id, count, kind = "Xenita", 2, "Mineral" -- (ya lo tenías: en su lugar, mineral)
		else
			d.Collection[id] = os.time()
		end
	end
	if kind == "Blueprint" or kind == "ShipPart" then
		-- (para el astillero de la Saga 2: también en data.Space.Blueprints)
		local data = DataService.get(player)
		if data then
			data.Space = if type(data.Space) == "table" then data.Space else {}
			data.Space.Blueprints = if type(data.Space.Blueprints) == "table" then data.Space.Blueprints else {}
			data.Space.Blueprints[id] = (tonumber(data.Space.Blueprints[id]) or 0) + count
		end
	end
	local inv = service("InventoryService")
	local added = false
	if inv then
		local ok, res = pcall(inv.add, player, id, count)
		added = ok and res == true
	end
	if not added then
		d.Stash[id] = (tonumber(d.Stash[id]) or 0) + count
	end
	return true
end
InvasionService.giveItem = giveItem

local function dropLoot(player: Player, kind: string, raceId: string)
	local got = {}
	for _, drop in Loot.roll(kind, raceId, r) do
		if giveItem(player, drop.Id, drop.Count) then
			local def = Loot.get(drop.Id)
			local name = if def then def.Name else drop.Id
			if string.sub(drop.Id, 1, 5) == "Arma_" then
				local W = require(Shared.Weapons)
				local w = W.fromItem(drop.Id)
				name = if w then w.Name else drop.Id
			end
			table.insert(got, { Id = drop.Id, Count = drop.Count, Name = name, Rarity = if def then def.Rarity elseif string.sub(drop.Id, 1, 5) == "Arma_" then "Epico" else "Comun" })
			if def and def.Kind == "Sample" then
				missionEvent(player, "Sample", { Amount = drop.Count })
			end
		end
	end
	if #got > 0 then
		send(player, "Loot", got)
	end
end
InvasionService.dropLoot = dropLoot

local function startMission(player: Player, id: string, quiet: boolean?): (boolean, string?)
	local d = invData(player)
	if not d then
		return false, "Aún no ha cargado tu partida."
	end
	local who = {
		Invasion = E ~= nil and E.State ~= "End",
		CityNormal = Transform.summary(city).Normal,
		Tester = isTester(player),
		Pilot = isTester(player) or (function()
			local av = service("AviationService")
			local ok, yes = pcall(function()
				return av.hasLicense(player)
			end)
			return ok and yes == true
		end)(),
		ShipOk = (function()
			local sp = service("SpaceService")
			local ok, yes = pcall(function()
				return sp.canFly(player)
			end)
			return ok and yes == true
		end)(),
	}
	local ok, why = Missions.canStart(d.Book, id, who)
	if not ok then
		if not quiet then
			toast(player, "Error", why or "Ahora no")
		end
		return false, why
	end
	Missions.start(d.Book, id, now())
	stateOf(player).Airborne = {} -- (si ya vas volando, el paso «Despega» cuenta en la siguiente vuelta)
	local m = Missions.get(id) :: Missions.Mission
	if not quiet then
		toast(player, "Info", ("🛸 Nueva misión: %s"):format(m.Title))
	end
	send(player, "Brief", { Id = id, Title = m.Title, Giver = m.Giver, Lines = m.Brief })
	publishBook(player)
	-- (las de vuelo preparan su objetivo)
	if id == "Evacuacion" then
		InvasionService.ensureEvac()
	elseif id == "Bahia" then
		InvasionService.ensureScout()
	end
	return true, nil
end
InvasionService.startMission = startMission

---------------------------------------------------------------------
-- El mundo: rayos, suelo y sitios
---------------------------------------------------------------------
local function excludeParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list: { Instance } = { getFolder() }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	params.FilterDescendantsInstances = list
	params.IgnoreWater = false
	return params
end

local function groundY(x: number, z: number, fallback: number): number
	local ok, hit = pcall(function()
		return workspace:Raycast(Vector3.new(x, fallback + 60, z), Vector3.new(0, -260, 0), excludeParams())
	end)
	if ok and hit then
		return hit.Position.Y
	end
	return fallback
end

local ROAD_WORDS = { "road", "calzada", "asfalto", "carril", "autovia", "avenida", "street" }
local function probe(x: number, z: number): Landing.Probe
	local p: Landing.Probe = { X = x, Z = z, Hit = false }
	local ok = pcall(function()
		local hit = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -520, 0), excludeParams())
		if not hit then
			return
		end
		p.Hit = true
		p.GroundY = hit.Position.Y
		p.Material = hit.Material.Name
		p.NormalY = hit.Normal.Y
		p.Water = hit.Material == Enum.Material.Water
		local name = string.lower(hit.Instance.Name)
		for _, w in ROAD_WORDS do
			if string.find(name, w, 1, true) then
				p.Road = true
			end
		end
		local box = CFrame.new(hit.Position + Vector3.new(0, Landing.Footprint.Y / 2 + 0.8, 0))
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = { getFolder() }
		local parts = workspace:GetPartBoundsInBox(box, Landing.Footprint, overlap)
		local clear = true
		for _, part in parts do
			if part:IsA("BasePart") and (part.CanCollide or part.Transparency < 0.9) and part.Size.Magnitude > 1.5 then
				clear = false
				break
			end
		end
		p.Clear = clear
	end)
	if not ok then
		p.Hit = false
	end
	return p
end
InvasionService.probe = probe

local zoneCache: { [string]: Vector3 } = {}
local function resolveZones(): { [string]: ZoneRec }
	local out: { [string]: ZoneRec } = {}
	local anyPlayer = Players:GetPlayers()[1]
	local loc = service("LocationService")
	for _, site in Landing.Sites do
		local pos = zoneCache[site.Id]
		if not pos then
			local x, z = site.XZ[1], site.XZ[2]
			if site.Place and loc and anyPlayer then
				local ok, spot = pcall(loc.resolve, anyPlayer, site.Place)
				if ok and spot and typeof(spot.Position) == "Vector3" then
					x, z = spot.Position.X, spot.Position.Z
				end
			end
			pos = Landing.find(x, z, probe)
			if pos then
				zoneCache[site.Id] = pos
			end
		end
		if pos then
			local siege = {}
			for i = 0, 2 do
				local a = i / 3 * math.pi * 2 + 0.6
				local sx, sz = pos.X + math.cos(a) * 30, pos.Z + math.sin(a) * 30
				table.insert(siege, { Id = ("%s_%d"):format(site.Id, i + 1), Pos = Vector3.new(sx, groundY(sx, sz, pos.Y), sz) })
			end
			out[site.Id] = { Id = site.Id, Name = site.Name, Pos = pos, Control = 0, Conquered = false, Siege = siege, Damaged = 0 }
		end
	end
	return out
end
InvasionService.resolveZones = resolveZones

-- Sitios seguros a los que corre la gente (puertas de tiendas, comisarías, bomberos, metro, hoteles)
local SAFE_TAGS = { Shop = "Door", PoliceStation = "Police", FireStation = "Police", HotelLobby = "Door", MetroBoard = "Metro", MetroDisplay = "Metro" }
local function collectSafe(): { Panic.Safe }
	local out = {}
	for tag, kind in SAFE_TAGS do
		for _, inst in CollectionService:GetTagged(tag) do
			local pos: Vector3? = nil
			if inst:IsA("BasePart") then
				pos = inst.Position
			elseif inst:IsA("Model") then
				local ok, cf = pcall(inst.GetPivot, inst)
				pos = if ok then cf.Position else nil
			end
			if pos and math.abs(pos.Y) < 200 and #out < 160 then
				table.insert(out, { Pos = pos, Kind = kind })
			end
		end
	end
	return out
end

---------------------------------------------------------------------
-- Efectos (los dibuja el cliente)
---------------------------------------------------------------------
local function boom(pos: Vector3, size: number, raceId: string?)
	table.insert(explosions, { Pos = pos, Until = now() + 6 })
	if #explosions > 12 then
		table.remove(explosions, 1)
	end
	broadcast("Boom", { Pos = pos, Size = size, Race = raceId })
end

local function shot(from: Vector3, to: Vector3, raceId: string?, kind: string?, id: string?)
	broadcast("Shot", { From = from, To = to, Race = raceId, Kind = kind, Id = id })
end

---------------------------------------------------------------------
-- Aparecer
---------------------------------------------------------------------
local function setTarget(model: Model, id: string, kind: string, raceId: string, hp: number)
	model:SetAttribute("InvasionTarget", id)
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Race", raceId)
	model:SetAttribute("Hp", hp)
	model:SetAttribute("MaxHp", hp)
	stream(model)
end

local function spawnAir(kind: string, raceId: string, pos: Vector3, mission: string?): Air?
	local spec = Rules.Air[kind]
	local race = Races.get(raceId)
	if not spec or not race then
		return nil
	end
	local count = 0
	for _ in air do
		count += 1
	end
	if not mission and Rules.room("Air", count) <= 0 then
		return nil
	end
	local id = nextId("A")
	local look = Vector3.new(-pos.X, 0, -pos.Z)
	local ai = EnemyAI.new(id, spec.Ai, pos, if look.Magnitude > 1 then look.Unit else nil, { Damage = 1, Fire = 0.8, Speed = 0.85 }, serial * 1.7)
	local model = AlienModels.ship(race, kind)
	model:PivotTo(CFrame.lookAt(pos, pos + ai.Look))
	setTarget(model, id, kind, raceId, spec.Hp)
	model:SetAttribute("InvasionShip", true)
	model.Parent = sub("Air")
	local rec: Air = { Id = id, Kind = kind, Race = raceId, AI = ai, Hp = spec.Hp, MaxHp = spec.Hp, Model = model, Root = model.PrimaryPart :: BasePart, Mission = mission }
	air[id] = rec
	return rec
end
InvasionService.spawnAir = spawnAir

local function groundCount(): number
	local n = 0
	for _ in ground do
		n += 1
	end
	return n
end

local function spawnGround(raceId: string, kind: string, pos: Vector3, zone: string?, pocket: string?): Ground?
	local race = Races.get(raceId)
	if not race or (not pocket and Rules.room("Ground", groundCount()) <= 0) then
		return nil
	end
	local id = nextId("G")
	local ai = AlienAI.new(id, race, kind, pos, zone, serial)
	local model = AlienModels.ground(race, kind)
	local h = (model.PrimaryPart :: BasePart).Size.Y
	model:PivotTo(CFrame.new(pos + Vector3.new(0, h / 2, 0)))
	setTarget(model, id, kind, raceId, ai.MaxHp)
	model:SetAttribute("InvasionAlien", id)
	model.Parent = sub("Ground")
	local rec: Ground = { Id = id, AI = ai, Model = model, Root = model.PrimaryPart :: BasePart, GroundAt = 0, Pocket = pocket }
	ground[id] = rec
	return rec
end
InvasionService.spawnGround = spawnGround

local function spawnDropship(raceId: string, zone: ZoneRec, perDrop: number): Drop?
	local race = Races.get(raceId)
	local n = 0
	for _ in drops do
		n += 1
	end
	if not race or Rules.room("Dropship", n) <= 0 then
		return nil
	end
	local id = nextId("D")
	local spec = Rules.Air.Dropship
	local land = zone.Pos + Vector3.new((r() - 0.5) * 20, 0, (r() - 0.5) * 20)
	local start = land + Vector3.new(0, 650, 0)
	local model = AlienModels.ship(race, "Dropship")
	model:PivotTo(CFrame.new(start))
	setTarget(model, id, "Dropship", raceId, spec.Hp)
	model:SetAttribute("InvasionShip", true)
	model:SetAttribute("Zone", zone.Id)
	model.Parent = sub("Air")
	local rec: Drop = { Id = id, Race = raceId, Zone = zone.Id, Pos = start, Land = land, Hp = spec.Hp, MaxHp = spec.Hp, Model = model, Root = model.PrimaryPart :: BasePart, Phase = "Descend", Since = now(), Left = perDrop, NextOut = 0 }
	drops[id] = rec
	broadcast("Landing", { Pos = land, Zone = zone.Id, Name = zone.Name, Race = raceId })
	return rec
end
InvasionService.spawnDropship = spawnDropship

local function spawnKing(raceId: string, zone: ZoneRec)
	local race = Races.get(raceId)
	if not race or not E then
		return
	end
	local players = math.max(#valmarPlayers(), 1)
	local st = King.new(raceId, players, now())
	local model, weak = AlienModels.king(race)
	local h = (model.PrimaryPart :: BasePart).Size.Y
	local pos = zone.Pos
	model:PivotTo(CFrame.new(pos + Vector3.new(0, h / 2, 0)))
	setTarget(model, "King", "King", raceId, st.MaxHp)
	model:SetAttribute("InvasionAlien", "King")
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	if not model:FindFirstChildOfClass("Humanoid") then
		humanoid.Parent = model
	end
	model.Parent = sub("Ground")
	E.KingRec = { State = st, Model = model, Root = model.PrimaryPart, Weak = weak, Pos = pos, Zone = zone.Id, Telegraph = nil, Race = raceId }
	worldToast(("👑 ¡%s, %s de los %s, ha llegado a %s!"):format(race.King.Name, race.King.Title, race.Name, zone.Name), "Error")
	broadcast("King", { Phase = 1, Name = race.King.Name, Title = race.King.Title, Line = race.King.Lines[1], Pos = pos })
end

---------------------------------------------------------------------
-- Quitar y estallar
---------------------------------------------------------------------
local function removeAir(id: string, destroyed: boolean)
	local rec = air[id]
	if not rec then
		return
	end
	air[id] = nil
	if destroyed then
		boom(rec.AI.Pos, if rec.Kind == "Drone" then 1 else 1.6, rec.Race)
	end
	rec.Model:Destroy()
	if special.Scout == rec then
		special.Scout = nil
	end
end

local function removeGround(id: string, destroyed: boolean)
	local rec = ground[id]
	if not rec then
		return
	end
	ground[id] = nil
	if destroyed then
		boom(rec.AI.Pos + Vector3.new(0, 3, 0), if rec.AI.Kind == "Heavy" or rec.AI.Kind == "Elite" then 1.2 else 0.8, rec.AI.Race)
	end
	rec.Model:Destroy()
	if rec.Pocket then
		local p = city.Pockets[rec.Pocket]
		if p then
			p.Left -= 1
		end
	end
end

local function removeDrop(id: string, destroyed: boolean)
	local rec = drops[id]
	if not rec then
		return
	end
	drops[id] = nil
	if destroyed then
		boom(rec.Pos, 3, rec.Race)
	end
	rec.Model:Destroy()
end

---------------------------------------------------------------------
-- Daño a los alienígenas (siempre el servidor)
---------------------------------------------------------------------
local function credit(id: string, player: Player?, amount: number)
	if not E or not player then
		return
	end
	local t = E.DamageBy[id]
	if not t then
		t = {}
		E.DamageBy[id] = t
	end
	t[player.UserId] = (t[player.UserId] or 0) + amount
	addPoints(player, amount * Rules.Points.Damage)
end

-- Los que han ayudado a tumbar algo grande (al menos un 10 % del daño)
local function helpers(id: string, total: number): { Player }
	local out = {}
	local t = E and E.DamageBy[id]
	if not t then
		return out
	end
	for uid, dmg in t do
		if dmg >= total * 0.1 then
			local p = Players:GetPlayerByUserId(uid)
			if p then
				table.insert(out, p)
			end
		end
	end
	return out
end

local function killed(player: Player?, kind: string, raceId: string, via: string, isAir: boolean)
	if E then
		E.Killed += 1
	end
	if not player then
		return
	end
	addPoints(player, Rules.Points[kind] or 10)
	local d = invData(player)
	if d then
		d.Stats.Kills += 1
	end
	dropLoot(player, kind, raceId)
	missionEvent(player, "Kill", { Air = isAir, Kind = kind, Via = via, Airborne = via ~= "Foot", Race = raceId })
	if kind == "Elite" then
		missionEvent(player, "EliteDown", { Via = via })
	end
	StoryEvents.emit(player, "InvasionKill", { Kind = kind, Race = raceId, Via = via, Air = isAir })
end

local function kingDamage(player: Player?, amount: number, at: Vector3?, via: string): number
	local k = E and E.KingRec
	if not k or k.State.Dead then
		return 0
	end
	local weak: number? = nil
	if at then
		for i, part in k.Weak do
			if k.State.Weak[i] > 0 and part.Parent and (part.Position - at).Magnitude <= 5 then
				weak = i
			end
		end
	end
	local res = King.damage(k.State, amount, weak, now())
	credit("King", player, res.Dealt)
	if res.WeakBroken then
		local part = k.Weak[res.WeakBroken]
		if part then
			part.Transparency = 0.85
		end
		boom(if part then part.Position else k.Pos, 1.4, k.Race)
		if player then
			addPoints(player, Rules.Points.WeakPoint)
		end
		if res.Exposed then
			worldToast("👑 ¡El rey está AL DESCUBIERTO! ¡Ahora!", "Success")
		end
	end
	if res.PhaseChanged then
		for _, part in k.Weak do
			part.Transparency = 0
		end
		local race = Races.get(k.Race)
		broadcast("King", { Phase = res.Phase, Line = race and race.King.Lines[math.min(res.Phase or 2, 3)] or nil, Pos = k.Pos })
		for _ = 1, King.Adds[res.Phase or 2] or 3 do
			spawnGround(k.Race, if r() < 0.3 then "Heavy" else "Grunt", k.Pos + Vector3.new((r() - 0.5) * 40, 0, (r() - 0.5) * 40), k.Zone)
		end
	end
	k.Model:SetAttribute("Hp", math.max(0, k.State.Hp))
	if res.Dead then
		local race = Races.get(k.Race)
		boom(k.Pos + Vector3.new(0, 20, 0), 5, k.Race)
		worldToast(("👑 ¡%s ha caído! Valmar respira."):format(race and race.King.Name or "El rey"), "Success")
		history.SinceKing = 0
		for _, p in helpers("King", k.State.MaxHp) do
			addPoints(p, Rules.Points.King)
			dropLoot(p, "King", k.Race)
			missionEvent(p, "EliteDown", { Via = via, King = true })
			StoryEvents.emit(p, "InvasionKill", { Kind = "King", Race = k.Race, Via = via, Air = false })
			local d = invData(p)
			if d then
				d.Stats.Kings += 1
			end
		end
		k.Model:Destroy()
		E.KingRec = nil
	end
	return res.Dealt
end

-- Daño a cualquier objetivo de la invasión (id = InvasionTarget). via = "Foot" | "Plane" | "Ship" | "Police"
function InvasionService.damage(player: Player?, id: string, amount: number, via: string, at: Vector3?, zone: string?): number
	if type(id) ~= "string" or type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return 0
	end
	amount = math.min(amount, 400)
	local t = now()
	if id == "King" then
		return kingDamage(player, amount, at, via)
	end
	local g = ground[id]
	if g then
		local dealt = math.min(g.AI.Hp, amount)
		g.AI.Hp -= dealt
		AlienAI.hit(g.AI, if player then tostring(player.UserId) else nil, t)
		-- Encajar el disparo: tambalearse (y perder el ataque que cargaba) si es fuerte o en la cabeza
		local staggered = false
		if g.AI.Hp > 0 then
			staggered = AlienAI.stagger(g.AI, dealt, zone == "Head", t)
			if staggered or t - (flinchAt[id] or 0) > 0.12 then
				flinchAt[id] = t
				local from = nil
				if player then
					local pr = (rootOf(player))
					from = if pr then pr.Position else nil
				end
				broadcast("Flinch", { Id = id, From = from, Heavy = staggered })
			end
		else
			flinchAt[id] = nil
		end
		credit(id, player, dealt)
		g.Model:SetAttribute("Hp", math.max(0, g.AI.Hp))
		if g.AI.Hp <= 0 then
			local kind, raceId = g.AI.Kind, g.AI.Race
			local pocket = g.Pocket
			removeGround(id, true)
			killed(player, kind, raceId, via, false)
			if pocket and city.Pockets[pocket] and city.Pockets[pocket].Left <= 0 and player then
				missionEvent(player, "PocketCleared", {})
			end
		end
		return dealt
	end
	local a = air[id]
	if a then
		local dealt = math.min(a.Hp, amount)
		a.Hp -= dealt
		EnemyAI.hit(a.AI, if player then tostring(player.UserId) else nil, t)
		credit(id, player, dealt)
		a.Model:SetAttribute("Hp", math.max(0, a.Hp))
		if a.Hp <= 0 then
			local kind, raceId, isScout = a.Kind, a.Race, special.Scout == a
			removeAir(id, true)
			killed(player, kind, raceId, via, true)
			if isScout and player then
				missionEvent(player, "ScoutDown", { Via = via })
				worldToast("📡 El explorador alienígena ha caído sobre la bahía", "Success")
			end
		end
		return dealt
	end
	local d = drops[id]
	if d then
		local dealt = math.min(d.Hp, amount)
		d.Hp -= dealt
		credit(id, player, dealt)
		d.Model:SetAttribute("Hp", math.max(0, d.Hp))
		if d.Hp <= 0 then
			local raceId = d.Race
			local total = d.MaxHp
			removeDrop(id, true)
			for _, p in helpers(id, total) do
				killed(p, "Dropship", raceId, via, true)
				missionEvent(p, "DropshipDown", { Via = via })
			end
			if player and #helpers(id, total) == 0 then
				killed(player, "Dropship", raceId, via, true)
				missionEvent(player, "DropshipDown", { Via = via })
			end
		end
		return dealt
	end
	local b = special.Beacon
	if b and id == b.Id then
		return InvasionService.damageBeacon(player, amount, at, via)
	end
	local ev = special.Evac
	if ev and id == ev.Id then
		return 0 -- (no se dispara al avión de la evacuación)
	end
	return 0
end

-- La baliza: primero los 3 pilones, luego el núcleo. Solo cuenta el láser de las naves
function InvasionService.damageBeacon(player: Player?, amount: number, at: Vector3?, via: string): number
	local b = special.Beacon
	if not b or via ~= "Ship" then
		return 0
	end
	local pylon: number? = nil
	if at then
		for i, part in b.Pylons do
			if b.PylonHp[i] > 0 and (part.Position - at).Magnitude <= 8 then
				pylon = i
			end
		end
	end
	local left = 0
	for _, hp in b.PylonHp do
		if hp > 0 then
			left += 1
		end
	end
	local dealt = 0
	if pylon then
		dealt = math.min(b.PylonHp[pylon], amount)
		b.PylonHp[pylon] -= dealt
		if b.PylonHp[pylon] <= 0 then
			boom(b.Pylons[pylon].Position, 1.5, b.Race)
			b.Pylons[pylon].Transparency = 1
		end
	elseif left == 0 then
		dealt = math.min(b.Hp, amount)
		b.Hp -= dealt
	end
	credit(b.Id, player, dealt)
	b.Model:SetAttribute("Hp", math.max(0, b.Hp))
	if b.Hp <= 0 then
		boom(b.Model:GetPivot().Position, 4, b.Race)
		worldToast("📡 ¡La baliza nodriza ha caído! La flota se queda a ciegas", "Success")
		for _, p in helpers(b.Id, b.MaxHp + 900) do
			addPoints(p, 80)
			missionEvent(p, "BeaconDown", { Via = "Ship" })
		end
		if player then
			missionEvent(player, "BeaconDown", { Via = "Ship" })
		end
		b.Model:Destroy()
		special.Beacon = nil
	end
	return dealt
end

-- Un golpe o un disparo de las armas de siempre a una pieza de un alienígena (CombatService /
-- WeaponService). Devuelve (¿cuenta?, daño hecho, ¿ha caído?)
function InvasionService.hitModel(player: Player?, model: Instance, amount: number, info: { [string]: any }?): (boolean, number, boolean)
	local node: Instance? = model
	local id: string? = nil
	while node and node ~= workspace do
		local v = node:GetAttribute("InvasionTarget")
		if type(v) == "string" then
			id = v
			break
		end
		node = node.Parent
	end
	if not id then
		return false, 0, false
	end
	local at = info and typeof(info.At) == "Vector3" and info.At or nil
	local zone = info and type(info.Zone) == "string" and info.Zone or nil
	local before = ground[id] or air[id] or drops[id]
	local dealt = InvasionService.damage(player, id, amount, "Foot", at, zone)
	local gone = before ~= nil and ground[id] == nil and air[id] == nil and drops[id] == nil
	return dealt > 0, dealt, gone
end

-- Compensación de lag (WeaponService): si el rayo de verdad no ha dado a ningún alienígena, ¿le daba
-- donde lo veía el jugador (hace su ping + la interpolación)? Nunca a través de lo que tapa el rayo
-- (blocked: distancia a la pared) ni más allá del alcance. Devuelve (modelo, punto, zona) o nil.
function InvasionService.rewindHit(player: Player, origin: Vector3, dir: Vector3, range: number, blocked: number?): (Model?, Vector3?, string?)
	if not next(ground) or dir.Magnitude < 1e-6 then
		return nil, nil, nil
	end
	local ok, ping = pcall(function()
		return player:GetNetworkPing()
	end)
	local back = HitCheck.rewindTime(if ok then ping else nil)
	local t = now() - back
	local list: { HitCheck.Candidate } = {}
	local models: { [string]: Model } = {}
	for id, g in ground do
		local hist = (g :: any).Hist
		local feet = if hist then HitCheck.sample(hist, t) else g.AI.Pos
		if feet and (feet - origin).Magnitude <= range + 10 then
			-- (la cápsula sale del modelo de verdad: la caja de su raíz; HitCheck.shape)
			local root = g.Model and g.Model.PrimaryPart
			local height, radius, bottom = HitCheck.shape(if root then root.Size else nil, g.AI.Stats.Height, g.AI.Stats.Radius)
			table.insert(list, { Id = id, Feet = feet + Vector3.new(0, bottom, 0), Height = height, Radius = radius })
			models[id] = g.Model
		end
	end
	local c, d, head = HitCheck.pick(origin, dir, range, list, blocked)
	if not c or not d then
		return nil, nil, nil
	end
	return models[c.Id], origin + dir.Unit * d, if head then "Head" else "Torso"
end

-- ¿Es una pieza de la invasión? (para que disparar a un alienígena no sea un delito)
function InvasionService.isTarget(inst: Instance?): boolean
	local node = inst
	while node and node ~= workspace do
		if node:GetAttribute("InvasionTarget") ~= nil then
			return true
		end
		node = node.Parent
	end
	return false
end

-- Lo que hay que mirar para un proyectil: { Id, Pos, Radius }
local function targets(): { { Id: string, Pos: Vector3, Radius: number } }
	local out = {}
	for id, a in air do
		table.insert(out, { Id = id, Pos = a.AI.Pos, Radius = Rules.Air[a.Kind].Radius })
	end
	for id, d in drops do
		table.insert(out, { Id = id, Pos = d.Pos, Radius = Rules.Air.Dropship.Radius })
	end
	for id, g in ground do
		table.insert(out, { Id = id, Pos = g.AI.Pos + Vector3.new(0, g.AI.Stats.Height / 2, 0), Radius = g.AI.Stats.Radius + 1 })
	end
	local k = E and E.KingRec
	if k then
		table.insert(out, { Id = "King", Pos = k.Pos + Vector3.new(0, King.Height / 2, 0), Radius = King.Radius })
		for i, part in k.Weak do
			if k.State.Weak[i] > 0 then
				table.insert(out, { Id = "King", Pos = part.Position, Radius = 3.5, Weak = i } :: any)
			end
		end
	end
	local b = special.Beacon
	if b then
		local c = b.Model:GetPivot().Position
		table.insert(out, { Id = b.Id, Pos = c, Radius = 9 })
		for i, part in b.Pylons do
			if b.PylonHp[i] > 0 then
				table.insert(out, { Id = b.Id, Pos = part.Position, Radius = 4 })
			end
		end
	end
	return out
end
InvasionService.targets = targets

-- El primer objetivo que toca un segmento (de `a` a `b`)
local function segmentTarget(a: Vector3, b: Vector3, extra: number?): ({ [string]: any }?, Vector3?)
	local best, bestD = nil, math.huge
	for _, t in targets() do
		if ShipWeapons.segmentHits(a, b, t.Pos, t.Radius + (extra or 0)) then
			local d = (t.Pos - a).Magnitude
			-- (a igual distancia, el punto débil manda)
			if d < bestD or ((t :: any).Weak and d < bestD + 6) then
				best, bestD = t, d
			end
		end
	end
	return best, if best then best.Pos else nil
end
InvasionService.segmentTarget = segmentTarget

-- (AirCombatService.ExternalHit) el láser de una nave: ¿toca algo de la invasión?
local function shipBolt(player: Player, from: Vector3, to: Vector3, damage: number, kind: string?): boolean
	if not E then
		return false
	end
	local t, at = segmentTarget(from, to, 1)
	if not t then
		return false
	end
	InvasionService.damage(player, t.Id, damage * (if kind == "Missile" then 1 else 1.4), "Ship", at)
	return true
end
InvasionService.shipBolt = shipBolt

---------------------------------------------------------------------
-- El cañón de la avioneta (solo durante la invasión)
---------------------------------------------------------------------
function InvasionService.planeFire(player: Player, dir: any): boolean
	if not E or E.State ~= "Wave" or typeof(dir) ~= "Vector3" or dir ~= dir or dir.Magnitude < 0.5 then
		return false
	end
	local via, root, plane = viaOf(player)
	if via ~= "Plane" or not root or not plane then
		return false
	end
	local kind = plane.Spec and plane.Spec.Kind
	if not Rules.PlaneGun.Kinds[kind] then
		return false -- (el avión de línea no lleva nada)
	end
	local G = Rules.PlaneGun
	local s = stateOf(player)
	local t = now()
	s.Heat = math.max(0, s.Heat - (t - s.HeatAt) * G.CoolPerSecond)
	s.HeatAt = t
	if t - s.LastFire < G.Cooldown * 0.9 or s.Heat >= 1 then
		return false
	end
	local look = root.CFrame.LookVector
	local unit = dir.Unit
	if math.acos(math.clamp(look:Dot(unit), -1, 1)) > G.Cone then
		unit = look -- (fuera del cono: dispara recto)
	end
	s.LastFire = t
	s.Heat = math.min(1, s.Heat + G.HeatPerShot)
	local origin = root.Position + look * 12
	-- Ayuda a apuntar: el objetivo más centrado dentro de su cono pequeño
	local best, bestAngle = nil, G.AssistCone
	for _, tg in targets() do
		local to = tg.Pos - origin
		local d = to.Magnitude
		if d <= G.Range and d > 1 then
			local ang = math.acos(math.clamp(unit:Dot(to / d), -1, 1))
			if ang < bestAngle then
				best, bestAngle = tg, ang
			end
		end
	end
	local finish = origin + unit * G.Range
	if best then
		finish = best.Pos
		InvasionService.damage(player, best.Id, G.Damage, "Plane", best.Pos)
	else
		local hit = segmentTarget(origin, finish, 1)
		if hit then
			finish = hit.Pos
			InvasionService.damage(player, hit.Id, G.Damage, "Plane", hit.Pos)
		end
	end
	shot(origin, finish, nil, "Plane")
	send(player, "Heat", s.Heat)
	return true
end

---------------------------------------------------------------------
-- Daño a los jugadores (de las naves y las tropas alienígenas)
---------------------------------------------------------------------
-- En plena conversación, escena o cinemática de la historia (o en el prólogo) el jugador no se puede
-- mover ni defender: ni es un blanco ni le hacen daño (si no, moría en mitad del diálogo y la misión
-- se quedaba a medias en el hospital). Solo las escenas que lanza el servidor (la historia): una
-- escena «Cliente» la abre la propia pantalla con latidos y no puede servir de escudo.
local function storyBusy(player: Player): boolean
	if player:GetAttribute("InDialogue") == true or player:GetAttribute("InPrologue") == true then
		return true
	end
	return player:GetAttribute("InScene") == true and player:GetAttribute("SceneId") ~= "Cliente"
end
InvasionService.storyBusy = storyBusy

local function hurtPlayer(player: Player, amount: number, from: Vector3, raceId: string?)
	if storyBusy(player) then
		return
	end
	local via, _, extra = viaOf(player)
	if via == "Ship" then
		local ac = service("AirCombatService")
		if ac and ac.hurtPilot then
			pcall(ac.hurtPilot, player, amount, "Laser", from)
		end
		return
	elseif via == "Plane" then
		local s = stateOf(player)
		s.PlaneHp -= amount
		send(player, "PlaneHit", { Hp = math.max(0, s.PlaneHp), Max = Rules.PlaneHp, From = from })
		if s.PlaneHp <= 0 then
			s.PlaneHp = Rules.PlaneHp
			local av = service("AviationService")
			if av and extra then
				pcall(av.crash, extra, "Te han derribado las naves alienígenas")
			end
		end
		return
	end
	if player:GetAttribute("InteriorKey") ~= nil or player:GetAttribute("Dead") then
		return
	end
	local _, humanoid = rootOf(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if player:GetAttribute("Tester") and player:GetAttribute("TesterGod") then
		return
	end
	humanoid:TakeDamage(amount)
	send(player, "Hurt", { From = from, Amount = amount, Race = raceId })
	if humanoid.Health <= 0 then
		player:SetAttribute("InvasionDown", true) -- (HospitalService: los defensores no pagan la factura)
	end
end
InvasionService.hurtPlayer = hurtPlayer

---------------------------------------------------------------------
-- Las naves en el cielo de la ciudad
---------------------------------------------------------------------
-- Los «pilotos» para la IA de las naves: aviones, naves, gente a pie (los cazas bajan a ametrallar), el
-- vuelo de evacuación y, si no hay nada, las zonas (ametrallan la ciudad)
local function airPilots(): { EnemyAI.Pilot }
	local out = {}
	for _, p in valmarPlayers() do
		local via, root, extra = viaOf(p)
		if via == "Ship" and extra then
			table.insert(out, { Id = tostring(p.UserId), Pos = extra.Pos, Vel = extra.Vel or Vector3.zero, Look = extra.Look, Alive = not extra.Down })
		elseif root then
			local alive = p:GetAttribute("InteriorKey") == nil and not p:GetAttribute("Dead")
			table.insert(out, { Id = tostring(p.UserId), Pos = root.Position, Vel = root.AssemblyLinearVelocity, Look = root.CFrame.LookVector, Alive = alive, Detect = if via == "Foot" then 650 else nil })
		end
	end
	local ev = special.Evac
	if ev then
		table.insert(out, { Id = "evac", Pos = ev.Pos, Vel = ev.Dir * InvasionService.EvacSpeed, Look = ev.Dir, Alive = true })
	end
	return out
end

local function airBounds(pos: Vector3): Vector3?
	local back = Vector3.zero
	if pos.Y < Rules.AirBand.Min then
		back += Vector3.new(0, 1, 0)
	elseif pos.Y > Rules.AirBand.Max then
		back += Vector3.new(0, -1, 0)
	end
	local flat = Vector3.new(pos.X, 0, pos.Z)
	if flat.Magnitude > 5200 then
		back -= flat.Unit
	end
	return if back.Magnitude > 0 then back.Unit else nil
end

local function stepAir(dt: number, t: number)
	local pilots = airPilots()
	local list = {}
	for _, a in air do
		table.insert(list, a.AI)
	end
	-- (sin nadie en el aire ni cerca: ametrallan las zonas)
	local zoneTargets = {}
	if E then
		for _, z in E.Zones do
			table.insert(zoneTargets, { Id = "zone:" .. z.Id, Pos = z.Pos + Vector3.new(0, 4, 0), Alive = true })
		end
	end
	for id, a in air do
		local e = a.AI
		local pool = pilots
		if a.Mission == "Scout" then
			pool = {} -- (el explorador no pelea: da vueltas sobre la bahía)
		end
		e.Target = EnemyAI.pickTarget(e, pool, t)
		local target = nil
		for _, p in pool do
			if p.Id == e.Target then
				target = p
			end
		end
		if not target and a.Mission ~= "Scout" and #zoneTargets > 0 then
			target = zoneTargets[(tonumber(string.sub(id, 2)) or 1) % #zoneTargets + 1]
		end
		local desired, speed, fire
		if a.Mission == "Scout" then
			local ang = t * 0.35
			local goal = InvasionService.Bay + Vector3.new(math.cos(ang) * 260, math.sin(t * 0.7) * 30, math.sin(ang) * 260)
			local to = goal - e.Pos
			desired, speed, fire = if to.Magnitude > 1 then to.Unit else e.Look, 150, false
		else
			desired, speed, fire = EnemyAI.think(e, target, t, list)
		end
		local back = airBounds(e.Pos)
		if back then
			desired = (desired + back * 2.5).Unit
		end
		EnemyAI.steer(e, desired, speed, dt)
		a.Model:PivotTo(CFrame.lookAt(e.Pos, e.Pos + e.Look))
		if fire and target and #bolts < 60 then
			EnemyAI.fired(e, t)
			local dir = (target.Pos - e.Pos).Unit
			dir = (dir + Vector3.new(r() - 0.5, r() - 0.5, r() - 0.5) * 0.05).Unit
			local B = ShipWeapons.EnemyBolt
			local origin = e.Pos + dir * 8
			table.insert(bolts, { Pos = origin, Dir = dir, Speed = B.Speed, Life = B.Life, Damage = EnemyAI.damage(e) * 1.2, Race = a.Race })
			broadcast("Bolt", { Pos = origin, Dir = dir, Speed = B.Speed, Life = B.Life, Race = a.Race })
		end
		if a.Until and t > a.Until then
			removeAir(id, false) -- (el explorador se escapa por la grieta)
		end
	end
end

local function stepBolts(dt: number)
	if #bolts == 0 then
		return
	end
	local people = {}
	for _, p in valmarPlayers() do
		local via, root, extra = viaOf(p)
		local pos = if via == "Ship" and extra then extra.Pos elseif root then root.Position else nil
		if pos then
			table.insert(people, { Player = p, Pos = pos, Radius = if via == "Plane" then 12 elseif via == "Ship" then 7 else 3 })
		end
	end
	for i = #bolts, 1, -1 do
		local b = bolts[i]
		local from = b.Pos
		local to = from + b.Dir * b.Speed * dt
		b.Pos = to
		b.Life -= dt
		local gone = b.Life <= 0
		if not gone then
			for _, who in people do
				if ShipWeapons.segmentHits(from, to, who.Pos, who.Radius) then
					hurtPlayer(who.Player, b.Damage, from, b.Race)
					gone = true
					break
				end
			end
		end
		local ev = special.Evac
		if not gone and ev and ShipWeapons.segmentHits(from, to, ev.Pos, 30) then
			ev.Hp -= b.Damage
			gone = true
		end
		if not gone and to.Y < 2 then
			gone = true
		end
		if gone then
			table.remove(bolts, i)
		end
	end
end

local function stepDrops(dt: number, t: number)
	for id, d in drops do
		local spec = Rules.Air.Dropship
		if d.Phase == "Descend" then
			local k = math.clamp((t - d.Since) / spec.Descend, 0, 1)
			local ease = 1 - (1 - k) ^ 3
			local hover = d.Land + Vector3.new(0, 7, 0)
			d.Pos = (d.Land + Vector3.new(0, 650, 0)):Lerp(hover, ease)
			if k >= 1 then
				d.Phase = "Deploy"
				d.NextOut = t + 1
			end
		elseif d.Phase == "Deploy" then
			if t >= d.NextOut and d.Left > 0 then
				d.NextOut = t + 1.1
				local mix = Rules.DropMix[(spec.Deploy - d.Left) % #Rules.DropMix + 1]
				local out = d.Land + Vector3.new((r() - 0.5) * 16, 0, -14 + (r() - 0.5) * 6)
				if spawnGround(d.Race, mix, Vector3.new(out.X, groundY(out.X, out.Z, d.Land.Y), out.Z), d.Zone) then
					d.Left -= 1
				else
					d.Left = 0 -- (tope: no caben más)
				end
			elseif d.Left <= 0 then
				d.Phase = "Hold"
			end
		end
		d.Model:PivotTo(CFrame.new(d.Pos) * CFrame.Angles(0, t * 0.15, 0))
		-- (la nave de desembarco posada también dispara a quien se acerque)
		if d.Phase ~= "Descend" and t >= ((d :: any).FireAt or 0) then
			(d :: any).FireAt = t + 2.5
			for _, p in valmarPlayers() do
				local via, root = viaOf(p)
				if via == "Foot" and root and (root.Position - d.Pos).Magnitude < 90 and r() < 0.5 then
					shot(d.Pos, root.Position, d.Race, "Drop")
					hurtPlayer(p, 6, d.Pos, d.Race)
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Las tropas de tierra
---------------------------------------------------------------------
local function footTargets(): { AlienAI.Target }
	local out = {}
	for _, p in valmarPlayers() do
		local via, root = viaOf(p)
		if via == "Foot" and root then
			local alive = p:GetAttribute("InteriorKey") == nil and not p:GetAttribute("Dead") and not p:GetAttribute("KO") and not storyBusy(p)
			table.insert(out, { Id = tostring(p.UserId), Pos = root.Position, Alive = alive })
		end
	end
	return out
end

local function playerById(id: string): Player?
	local uid = tonumber(id)
	return if uid then Players:GetPlayerByUserId(uid) else nil
end

local function transformAt(raceId: string, pos: Vector3): any
	local c = Transform.transform(city, raceId, pos, now(), r)
	if not c then
		return nil
	end
	local race = Races.get(raceId)
	local spec = nil
	for _, cr in race and race.Creatures or {} do
		if cr.Id == c.Type then
			spec = cr
		end
	end
	local model = AlienModels.creature(race :: any, spec or { Id = c.Type, Name = c.Name, Hostile = c.Hostile })
	model:SetAttribute("Creature", c.Id)
	model:SetAttribute("CreatureName", c.Name)
	model:SetAttribute("Citizen", c.Citizen)
	model:SetAttribute("Hostile", c.Hostile)
	local feet = tonumber(model:GetAttribute("FeetOffset")) or 2.4
	model:PivotTo(CFrame.new(pos + Vector3.new(0, feet, 0)))
	stream(model)
	model.Parent = sub("City")
	local root = model.PrimaryPart :: BasePart
	-- Tomar una muestra (sin hacerle daño) y revertirla con el inversor de fase
	local sample = Instance.new("ProximityPrompt")
	sample.Name = "Muestra"
	sample.ActionText = "Tomar una muestra"
	sample.ObjectText = c.Name
	sample.HoldDuration = 1
	sample.MaxActivationDistance = 10
	sample.RequiresLineOfSight = false
	sample.Parent = root
	local cure = Instance.new("ProximityPrompt")
	cure.Name = "Revertir"
	cure.ActionText = "Revertir (inversor de fase)"
	cure.ObjectText = ("%s (era %s)"):format(c.Name, c.Citizen)
	cure.KeyboardKeyCode = Enum.KeyCode.R
	cure.HoldDuration = 1.5
	cure.MaxActivationDistance = 10
	cure.RequiresLineOfSight = false
	cure.UIOffset = Vector2.new(0, 60)
	cure.Parent = root
	local id = c.Id
	sample.Triggered:Connect(function(player)
		InvasionService.takeSample(player, id)
	end)
	cure.Triggered:Connect(function(player)
		InvasionService.cure(player, id)
	end)
	creatures[id] = { Rec = c, Model = model, Root = root, BiteAt = 0 }
	broadcast("Transform", { Pos = pos, Race = raceId, Name = c.Name })
	return c
end
InvasionService.transformAt = transformAt

local function damageZone(zone: ZoneRec, spot: Vector3, raceId: string)
	if zone.Damaged >= 4 then
		return
	end
	zone.Damaged += 1
	local d = Transform.damage(city, zone.Id, spot, now(), r)
	local model = AlienModels.damage(spot, serial)
	model:SetAttribute("Damage", d.Id)
	stream(model)
	model.Parent = sub("City")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Reparar"
	prompt.ActionText = "Reparar"
	prompt.ObjectText = "Destrozo de la invasión"
	prompt.HoldDuration = 3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	local id = d.Id
	prompt.Triggered:Connect(function(player)
		InvasionService.repair(player, id)
	end)
	damages[id] = model
	boom(spot, 0.7, raceId)
end

-- Dónde cubrirse en una zona: los objetos del sitio (bancos, quioscos, farolas: zone.Siege)
local function coverOf(zone: ZoneRec?): { Vector3 }?
	if not zone then
		return nil
	end
	local out = {}
	for _, prop in zone.Siege do
		table.insert(out, prop.Pos)
	end
	return out
end

local function stepGround(dt: number, t: number, think: boolean)
	if not next(ground) then
		return
	end
	local people = footTargets()
	-- Turnos de ataque: cuántos están cargando ya contra cada jugador (AlienAI.MaxAttackers)
	local busy: { [string]: number } = {}
	for _, o in ground do
		local w = o.AI.WindupTarget
		if w then
			busy[w] = (busy[w] or 0) + 1
		end
	end
	local npcs = {}
	for id, res in rescue do
		if res.Model.Parent then
			table.insert(npcs, { Id = "npc:" .. id, Pos = res.Model:GetPivot().Position })
		end
	end
	for id, g in ground do
		local a = g.AI
		-- (lejos de todo jugador: quieto; muy lejos y sin ser una bolsa, se quita)
		local nearest = math.huge
		for _, p in people do
			nearest = math.min(nearest, AlienAI.flat(p.Pos, a.Pos))
		end
		if nearest > InvasionService.DespawnFar and not g.Pocket and not (E and E.State ~= "End") then
			removeGround(id, false)
			continue
		end
		if think then
			local zone = E and a.Zone and E.Zones[a.Zone]
			local pocketPos = g.Pocket and city.Pockets[g.Pocket] and city.Pockets[g.Pocket].Pos
			local rivals = {}
			if E and E.Lineup.Rivalry then
				for oid, o in ground do
					if oid ~= id and Races.hostile(a.Race, o.AI.Race) and AlienAI.flat(o.AI.Pos, a.Pos) < 60 then
						table.insert(rivals, { Id = "alien:" .. oid, Pos = o.AI.Pos, Race = o.AI.Race })
					end
				end
			end
			local ctx: AlienAI.Context = {
				Players = people,
				Npcs = npcs,
				Rivals = rivals,
				Props = if zone then zone.Siege :: any else nil,
				Cover = coverOf(zone),
				Busy = busy,
				ZonePos = if zone then zone.Pos elseif pocketPos then pocketPos else nil,
				ZoneConquered = zone and zone.Conquered or false,
				Graph = graph,
			}
			local dec = AlienAI.think(a, ctx, t)
			if dec.Windup then
				-- Aviso: va a atacar (el cliente lo hace brillar y echar el brazo atrás)
				broadcast("Windup", { Id = id, T = dec.Windup, Race = a.Race })
			end
			;(g :: any).Goal = dec.Goal
			;(g :: any).Speed = dec.Speed
			if dec.Blink then
				a.Pos = dec.Blink
				broadcast("Blink", { Pos = a.Pos, Race = a.Race })
			end
			if dec.Attack then
				AlienAI.attacked(a, t)
				local tg = dec.Attack
				local from = a.Pos + Vector3.new(0, a.Stats.Height * 0.6, 0)
				if dec.AttackKind == "Player" then
					local p = playerById(tg.Id)
					if p then
						local dist = AlienAI.flat(tg.Pos, a.Pos)
						if AlienAI.ranged(a) then
							-- (apunta a donde estabas al empezar a cargar: si te has movido de lado, falla)
							local now3 = (rootOf(p))
							local moved = if now3 then AlienAI.flat(now3.Position, tg.Pos) else 0
							shot(from, tg.Pos + Vector3.new(0, 2, 0), a.Race, a.Kind, id)
							if moved < 4.5 and r() < AlienAI.accuracy(dist, a.Stats.Range) then
								hurtPlayer(p, a.Stats.Damage, from, a.Race)
							end
						else
							broadcast("Swipe", { Pos = from, To = tg.Pos, Race = a.Race, Id = id })
							hurtPlayer(p, a.Stats.Damage, from, a.Race)
						end
					end
				elseif dec.AttackKind == "Npc" then
					local rid = string.sub(tg.Id, 5)
					local res = rescue[rid]
					if res then
						rescue[rid] = nil
						local pos = res.Model:GetPivot().Position
						res.Model:Destroy()
						transformAt(a.Race, Vector3.new(pos.X, pos.Y - 2.4, pos.Z))
					end
				elseif dec.AttackKind == "Alien" then
					local oid = string.sub(tg.Id, 7)
					local o = ground[oid]
					if o then
						shot(from, o.AI.Pos + Vector3.new(0, 3, 0), a.Race, a.Kind)
						o.AI.Hp -= a.Stats.Damage * 1.5
						if o.AI.Hp <= 0 then
							removeGround(oid, true)
						end
					end
				elseif dec.AttackKind == "Prop" and zone then
					shot(from, tg.Pos, a.Race, a.Kind)
					if r() < 0.35 then
						damageZone(zone, tg.Pos, a.Race)
					end
				end
			end
		end
		local goal = (g :: any).Goal
		if goal then
			AlienAI.step(a, goal, (g :: any).Speed or a.Stats.Speed, dt)
		end
		if t - g.GroundAt > 0.3 then
			g.GroundAt = t
			a.Pos = Vector3.new(a.Pos.X, groundY(a.Pos.X, a.Pos.Z, a.Pos.Y), a.Pos.Z)
		end
		local h = a.Stats.Height
		g.Model:PivotTo(CFrame.lookAt(a.Pos + Vector3.new(0, h / 2, 0), a.Pos + Vector3.new(a.Look.X, h / 2, a.Look.Z)))
		-- (historia para la compensación de lag de los disparos: shared/Invasion/HitCheck)
		local hist = (g :: any).Hist
		if not hist then
			hist = HitCheck.newHistory()
			;(g :: any).Hist = hist
		end
		HitCheck.push(hist, t, a.Pos)
	end
end

---------------------------------------------------------------------
-- El rey
---------------------------------------------------------------------
local function stepKing(dt: number, t: number)
	local k = E and E.KingRec
	if not k then
		return
	end
	if King.tick(k.State, t) then
		for _, part in k.Weak do
			part.Transparency = 0
		end
		worldToast("👑 Los puntos débiles del rey vuelven a brillar", "Warn")
	end
	-- Anda despacio hacia el jugador más cercano (sin salir de su zona)
	local people = footTargets()
	local best, bestD = nil, math.huge
	for _, p in people do
		local d = AlienAI.flat(p.Pos, k.Pos)
		if d < bestD and p.Alive ~= false then
			best, bestD = p, d
		end
	end
	local zone = E.Zones[k.Zone]
	if best and bestD > 30 then
		local to = Vector3.new(best.Pos.X - k.Pos.X, 0, best.Pos.Z - k.Pos.Z)
		local nextPos = k.Pos + to.Unit * math.min(6 * dt, to.Magnitude)
		if not zone or AlienAI.flat(nextPos, zone.Pos) < 140 then
			k.Pos = Vector3.new(nextPos.X, groundY(nextPos.X, nextPos.Z, k.Pos.Y), nextPos.Z)
		end
	end
	local look = if best then Vector3.new(best.Pos.X - k.Pos.X, 0, best.Pos.Z - k.Pos.Z) else Vector3.new(0, 0, -1)
	if look.Magnitude < 0.1 then
		look = Vector3.new(0, 0, -1)
	end
	k.Model:PivotTo(CFrame.lookAt(k.Pos + Vector3.new(0, King.Height / 2, 0), k.Pos + Vector3.new(look.X, King.Height / 2, look.Z)))
	-- Ataques de área: aviso y, a los Telegraph segundos, golpe
	if k.Telegraph and t >= k.Telegraph.At then
		local tel = k.Telegraph
		k.Telegraph = nil
		for _, p in valmarPlayers() do
			local via, root = viaOf(p)
			if via == "Foot" and root then
				for _, c in tel.Centers do
					if King.hits(tel.Attack, c, root.Position, tel.Dir) then
						hurtPlayer(p, King.Attacks[tel.Attack].Damage, c, k.Race)
						break
					end
				end
			end
		end
		broadcast("KingStrike", { Attack = tel.Attack, Centers = tel.Centers, Dir = tel.Dir, Race = k.Race })
	end
	local attack = King.nextAttack(k.State, t)
	if attack and best then
		local centers = {}
		if attack == "Onda" then
			centers = { k.Pos }
		elseif attack == "Lluvia" then
			for i, p in people do
				if i > King.Attacks.Lluvia.Count then
					break
				end
				table.insert(centers, p.Pos)
			end
		else
			centers = { k.Pos }
		end
		k.Telegraph = { Attack = attack, Centers = centers, Dir = look.Unit, At = t + King.Telegraph }
		broadcast("KingWarn", { Attack = attack, Centers = centers, Dir = look.Unit, Seconds = King.Telegraph, Race = k.Race, Radius = King.Attacks[attack].Radius, Width = King.Attacks.Rayo.Width, Length = King.Attacks.Rayo.Length })
	end
end

---------------------------------------------------------------------
-- Zonas, rescates, policía
---------------------------------------------------------------------
local function spawnRescue(zone: ZoneRec)
	local n = 0
	for _, res in rescue do
		if res.Zone == zone.Id then
			n += 1
		end
	end
	local total = 0
	for _ in rescue do
		total += 1
	end
	if n >= InvasionService.RescuePerZone or total >= InvasionService.MaxRescue then
		return
	end
	local Npc = require(script.Parent.Parent.World.Npc)
	local a = r() * math.pi * 2
	local x, z = zone.Pos.X + math.cos(a) * 40, zone.Pos.Z + math.sin(a) * 40
	local y = groundY(x, z, zone.Pos.Y)
	local ok, model = pcall(Npc.create, "VecinoAtrapado", sub("City"), CFrame.new(x, y + 3, z))
	if not ok or not model then
		return
	end
	pcall(Npc.placeFeet, model, CFrame.new(x, y, z))
	model:SetAttribute("Rescue", true)
	local id = nextId("R")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Rescatar"
	prompt.ActionText = "Rescatar"
	prompt.ObjectText = "Vecino atrapado"
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		InvasionService.rescue(player, id)
	end)
	rescue[id] = { Model = model, Zone = zone.Id, Since = now(), Prompt = prompt }
	pcall(Npc.say, model, "¡Ayuda! ¡No puedo salir de aquí!", 4)
end

function InvasionService.rescue(player: Player, id: string): boolean
	local res = rescue[id]
	if not res or not res.Model.Parent then
		return false
	end
	local root = rootOf(player)
	if not root or (root.Position - res.Model:GetPivot().Position).Magnitude > 14 then
		return false
	end
	rescue[id] = nil
	local Npc = require(script.Parent.Parent.World.Npc)
	pcall(Npc.say, res.Model, Panic.bark("Rescued", r()) or "¡Gracias!", 3)
	if res.Prompt then
		res.Prompt:Destroy()
	end
	-- (se va al sitio seguro más cercano y desaparece)
	local pos = res.Model:GetPivot().Position
	local safe = Panic.chooseSafe(pos, InvasionService.threats(), safePoints, 400)
	local model = res.Model
	task.spawn(function()
		if safe then
			pcall(Npc.walkTo, model, { safe.Pos }, 14)
		else
			task.wait(3)
		end
		if model.Parent then
			model:Destroy()
		end
	end)
	addPoints(player, Rules.Points.Rescue)
	missionEvent(player, "Rescue", {})
	StoryEvents.emit(player, "InvasionRescue", {})
	return true
end

local function spawnResponders(zone: ZoneRec)
	if #responders >= InvasionService.MaxResponders then
		return
	end
	for _, rsp in responders do
		if rsp.Zone == zone.Id then
			return
		end
	end
	local Npc = require(script.Parent.Parent.World.Npc)
	local points = Panic.cordon(zone.Pos, Rules.ZoneRadius + 25, 6)
	for i, p in points do
		if i <= 2 and #responders < InvasionService.MaxResponders then
			local army = i == 2
			local y = groundY(p.X, p.Z, zone.Pos.Y)
			local ok, model = pcall(Npc.create, if army then "Soldado" else "Agente", sub("City"), CFrame.new(p.X, y + 3, p.Z), if army then { Shirt = Color3.fromRGB(70, 90, 50), Pants = Color3.fromRGB(60, 70, 45) } else { Shirt = Color3.fromRGB(28, 48, 110), Pants = Color3.fromRGB(24, 28, 44) })
			if ok and model then
				pcall(Npc.placeFeet, model, CFrame.lookAt(Vector3.new(p.X, y, p.Z), Vector3.new(zone.Pos.X, y, zone.Pos.Z)))
				model:SetAttribute("Officer", true)
				model:SetAttribute("Responder", true)
				table.insert(responders, { Model = model, Zone = zone.Id, FireAt = now() + 2, SayAt = now() + 1 })
				pcall(Npc.say, model, if army then "¡Unidad de Defensa en posición!" else "¡Atrás! ¡Zona acordonada!", 3)
			end
		end
		if #cones < 30 then
			local y = groundY(p.X, p.Z, zone.Pos.Y)
			local cone = AlienModels.cone(Vector3.new(p.X, y, p.Z))
			cone.Parent = sub("City")
			table.insert(cones, cone)
		end
	end
end

local function stepResponders(t: number)
	for i = #responders, 1, -1 do
		local rsp = responders[i]
		if not rsp.Model.Parent then
			table.remove(responders, i)
			continue
		end
		if t >= rsp.FireAt then
			rsp.FireAt = t + 1.6 + r()
			local pos = rsp.Model:GetPivot().Position
			local best, bestD = nil, 90
			for _, g in ground do
				local d = (g.AI.Pos - pos).Magnitude
				if d < bestD then
					best, bestD = g, d
				end
			end
			if best then
				shot(pos + Vector3.new(0, 1.5, 0), best.AI.Pos + Vector3.new(0, best.AI.Stats.Height / 2, 0), nil, "Police")
				InvasionService.damage(nil, best.Id, 9, "Police", nil)
			elseif t >= rsp.SayAt then
				rsp.SayAt = t + 12
				local Npc = require(script.Parent.Parent.World.Npc)
				pcall(Npc.say, rsp.Model, ({ "Mantened la distancia.", "Civiles, ¡hacia el metro!", "Aquí unidad 4: zona estable." })[1 + math.floor(r() * 3) % 3], 3)
			end
		end
	end
end

local function closeServicesNear(pos: Vector3)
	-- Las tiendas de alrededor bajan la persiana (y las paradas de bus quedan suspendidas)
	local n = 0
	for _, tag in { "Shop", "BusStop" } do
		for _, inst in CollectionService:GetTagged(tag) do
			if n >= 4 then
				return
			end
			if inst:IsA("BasePart") and (inst.Position - pos).Magnitude < 220 then
				local id = ("%s_%d_%d"):format(tag, math.floor(inst.Position.X), math.floor(inst.Position.Z))
				if not shutters[id] then
					n += 1
					local name = if tag == "Shop" then "una tienda" else "una parada de autobús"
					Transform.closeService(city, id, name, now(), r)
					local shutter = Instance.new("Part")
					shutter.Name = if tag == "Shop" then "Persiana" else "ParadaSuspendida"
					shutter.Anchored = true
					shutter.CanCollide = false
					shutter.CanTouch = false
					shutter.Material = Enum.Material.CorrodedMetal
					shutter.Color = if tag == "Shop" then Color3.fromRGB(150, 150, 155) else Color3.fromRGB(230, 170, 40)
					shutter.Size = if tag == "Shop" then Vector3.new(math.max(inst.Size.X, 6), math.max(inst.Size.Y, 8), 0.4) else Vector3.new(3, 2, 0.3)
					shutter.CFrame = if tag == "Shop" then inst.CFrame else inst.CFrame * CFrame.new(0, 3, 0)
					local prompt = Instance.new("ProximityPrompt")
					prompt.Name = "Reabrir"
					prompt.ActionText = if tag == "Shop" then "Ayudar a subir la persiana" else "Reactivar la parada"
					prompt.ObjectText = "Servicio cerrado por la invasión"
					prompt.HoldDuration = 2
					prompt.MaxActivationDistance = 10
					prompt.RequiresLineOfSight = false
					prompt.Enabled = false -- (se puede reabrir al acabar la invasión)
					prompt.Parent = shutter
					prompt.Triggered:Connect(function(player)
						InvasionService.reopen(player, id)
					end)
					shutter.Parent = sub("City")
					shutters[id] = shutter
				end
			end
		end
	end
end

local function stepZones(dt: number)
	if not E then
		return
	end
	local people = footTargets()
	for _, z in E.Zones do
		local aliens = 0
		for _, g in ground do
			if AlienAI.flat(g.AI.Pos, z.Pos) <= Rules.ZoneRadius then
				aliens += 1
			end
		end
		local inside = {}
		for _, p in people do
			if p.Alive ~= false and AlienAI.flat(p.Pos, z.Pos) <= Rules.ZoneRadius then
				table.insert(inside, p)
			end
		end
		local ev = Rules.captureStep(z, aliens, #inside, dt)
		if aliens > 0 then
			spawnResponders(z)
			if r() < 0.04 * dt * 10 then
				spawnRescue(z)
			end
			if not z.Fell then
				closeServicesNear(z.Pos)
			end
		end
		-- Defender: estar en la zona mientras hay alienígenas y no cae
		for _, p in inside do
			local player = playerById(p.Id)
			if player then
				local s = stateOf(player)
				local key = z.Id
				if aliens > 0 and not z.Conquered then
					s.ZoneTime[key] = (s.ZoneTime[key] or 0) + dt
					if s.ZoneTime[key] >= 20 then
						s.ZoneTime[key] = -40 -- (otra vez dentro de un rato)
						missionEvent(player, "ZoneDefended", { Zone = z.Id })
						addPoints(player, 20)
					end
				end
			end
		end
		if ev == "Conquered" then
			E.Conquests += 1
			z.Fell = true
			worldToast(("🛸 ¡Los alienígenas han conquistado %s! Recuperadla"):format(z.Name), "Error")
			local race = E.Lineup.Main
			for _ = 1, Transform.PerConquest do
				local a = r() * math.pi * 2
				local x, zz = z.Pos.X + math.cos(a) * 25, z.Pos.Z + math.sin(a) * 25
				transformAt(race, Vector3.new(x, groundY(x, zz, z.Pos.Y), zz))
			end
		elseif ev == "Retaken" then
			E.Retakes += 1
			worldToast(("🏳 ¡%s vuelve a ser de Valmar!"):format(z.Name), "Success")
			for _, p in inside do
				local player = playerById(p.Id)
				if player then
					addPoints(player, Rules.Points.Retake)
					missionEvent(player, "ZoneDefended", { Zone = z.Id, Retaken = true })
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- La ciudad después (criaturas, destrozos, bolsas, servicios)
---------------------------------------------------------------------
local function stepCity(dt: number, t: number)
	-- Las criaturas dan vueltas por su sitio; las molestas persiguen y pican un poco
	local people = footTargets()
	for id, c in creatures do
		if not c.Model.Parent then
			creatures[id] = nil
			continue
		end
		local nearest: Vector3? = nil
		local nearestId: string? = nil
		local best = 30
		for _, p in people do
			local d = (p.Pos - c.Rec.Pos).Magnitude
			if d < best then
				best, nearest, nearestId = d, p.Pos, p.Id
			end
		end
		local goal, bite, flee = Transform.wander(c.Rec, t, nearest)
		local step = goal - c.Rec.Pos
		if step.Magnitude > 0.1 then
			local move = step.Unit * math.min(step.Magnitude, (if c.Rec.Hostile and nearest then 9 elseif flee then Transform.FleeSpeed else 3) * dt)
			local p = c.Rec.Pos + move
			c.Rec.Pos = Vector3.new(p.X, groundY(p.X, p.Z, p.Y), p.Z)
		end
		local face = Vector3.new(step.X, 0, step.Z)
		local up = Vector3.new(0, tonumber(c.Model:GetAttribute("FeetOffset")) or 2.4, 0)
		c.Model:PivotTo(CFrame.lookAt(c.Rec.Pos + up, c.Rec.Pos + up + (if face.Magnitude > 0.1 then face.Unit else Vector3.new(0, 0, -1))))
		if bite and nearestId and t >= c.BiteAt then
			c.BiteAt = t + Transform.HostileEvery
			local p = playerById(nearestId)
			if p then
				hurtPlayer(p, Transform.HostileDamage, c.Rec.Pos, c.Rec.Race)
			end
		end
	end
	-- Lo que se arregla solo
	local rec = Transform.recover(city, os.clock())
	for _, c in rec.Creatures do
		local m = creatures[c.Id]
		if m then
			broadcast("Restore", { Pos = c.Pos, Race = c.Race })
			m.Model:Destroy()
			creatures[c.Id] = nil
		end
	end
	for _, d in rec.Damage do
		local m = damages[d.Id]
		if m then
			m:Destroy()
			damages[d.Id] = nil
		end
	end
	for _, p in rec.Pockets do
		for id, g in ground do
			if g.Pocket == p.Id then
				removeGround(id, false)
			end
		end
	end
	for _, s in rec.Services do
		local m = shutters[s.Id]
		if m then
			m:Destroy()
			shutters[s.Id] = nil
		end
	end
	-- Los pasos de las misiones de paz que ya no tienen nada que hacer
	local summary = Transform.summary(city)
	for _, p in Players:GetPlayers() do
		local d = invData(p)
		if d and next(d.Book.Active) then
			local changed = Missions.autoSkip(d.Book, summary)
			for _, c in changed do
				local m = Missions.get(c.Id)
				if m and c.Kind == "Done" then
					rewardMission(p, m)
				end
			end
			if #changed > 0 then
				publishBook(p)
			end
		end
	end
end

function InvasionService.takeSample(player: Player, id: string): boolean
	local c = creatures[id]
	local s = stateOf(player)
	if not c or s.Sampled[id] then
		if c then
			toast(player, "Info", "Ya tienes una muestra de esta criatura")
		end
		return false
	end
	local root = rootOf(player)
	if not root or (root.Position - c.Rec.Pos).Magnitude > 14 then
		return false
	end
	s.Sampled[id] = true
	local race = Races.get(c.Rec.Race)
	if race and giveItem(player, race.Sample, 1) then
		toast(player, "Success", "🧪 Muestra tomada (con cuidado: no le has hecho daño)")
		missionEvent(player, "Sample", {})
		addPoints(player, Rules.Points.Creature)
		return true
	end
	toast(player, "Info", "No te caben más muestras por ahora")
	return false
end

function InvasionService.cure(player: Player, id: string): boolean
	local c = creatures[id]
	if not c then
		return false
	end
	local root = rootOf(player)
	if not root or (root.Position - c.Rec.Pos).Magnitude > 14 then
		return false
	end
	local inv = service("InventoryService")
	local d = invData(player)
	local hasItem = inv and inv.count(player, Loot.Recipe.Out) > 0
	local hasStash = d and (tonumber(d.Stash[Loot.Recipe.Out]) or 0) > 0
	if not hasItem and not hasStash then
		toast(player, "Info", "💉 Necesitas un inversor de fase (Laboratorio Xeno, junto al hospital)")
		return false
	end
	if hasItem then
		inv.remove(player, Loot.Recipe.Out, 1)
	else
		d.Stash[Loot.Recipe.Out] -= 1
	end
	local rec = Transform.cure(city, id)
	creatures[id] = nil
	local pos = c.Model:GetPivot().Position
	c.Model:Destroy()
	broadcast("Restore", { Pos = c.Rec.Pos, Race = c.Rec.Race })
	-- La persona vuelve (un vecino que se va a casa)
	task.spawn(function()
		local Npc = require(script.Parent.Parent.World.Npc)
		local ok, model = pcall(Npc.create, "Vecino", sub("City"), CFrame.new(pos))
		if ok and model then
			pcall(Npc.placeFeet, model, CFrame.new(pos - Vector3.new(0, 2.4, 0)))
			pcall(Npc.say, model, Transform.Thanks[1 + math.floor(r() * #Transform.Thanks) % #Transform.Thanks], 4)
			task.wait(5)
			if model.Parent then
				model:Destroy()
			end
		end
	end)
	if d then
		d.Stats.Cured += 1
	end
	toast(player, "Success", ("💖 %s vuelve a ser %s"):format(if rec then rec.Name else "La criatura", if rec then rec.Citizen else "quien era"))
	addPoints(player, 25)
	pcall(DataService.addMoney, player, 60, true)
	missionEvent(player, "Cured", {})
	StoryEvents.emit(player, "InvasionCured", {})
	return true
end

function InvasionService.repair(player: Player, id: string): boolean
	local m = damages[id]
	if not m then
		return false
	end
	local root = rootOf(player)
	if not root or (root.Position - m:GetPivot().Position).Magnitude > 16 then
		return false
	end
	Transform.repair(city, id)
	damages[id] = nil
	m:Destroy()
	toast(player, "Success", "🧱 Destrozo reparado. Valmar te lo agradece")
	pcall(DataService.addMoney, player, 40, true)
	missionEvent(player, "Repaired", {})
	StoryEvents.emit(player, "InvasionRepaired", {})
	return true
end

function InvasionService.reopen(player: Player, id: string): boolean
	local m = shutters[id]
	if not m or (E and E.State ~= "End") then
		return false
	end
	local root = rootOf(player)
	if not root or (root.Position - (m :: BasePart).Position).Magnitude > 14 then
		return false
	end
	Transform.reopen(city, id)
	shutters[id] = nil
	m:Destroy()
	toast(player, "Success", "🏪 ¡Abierto otra vez!")
	pcall(DataService.addMoney, player, 30, true)
	missionEvent(player, "Reopened", {})
	return true
end

---------------------------------------------------------------------
-- El Laboratorio Xeno (junto al hospital): fabricar, vender, la Xenobodega y la doctora
---------------------------------------------------------------------
local function ownedCounts(player: Player): { [string]: number }
	local data = DataService.get(player)
	local have = {}
	for id, n in (data and data.Items) or {} do
		if type(n) == "number" then
			have[id] = n
		end
	end
	return have
end

function InvasionService.craft(player: Player): boolean
	local ok, spend = Loot.craftPlan(ownedCounts(player))
	if not ok then
		toast(player, "Info", "🧪 Hacen falta 3 muestras alienígenas y 1 material alienígena")
		return false
	end
	local inv = service("InventoryService")
	if not inv or not inv.canAdd(player, Loot.Recipe.Out, 1) then
		toast(player, "Error", "No te cabe en la mochila")
		return false
	end
	for id, n in spend do
		inv.remove(player, id, n)
	end
	inv.add(player, Loot.Recipe.Out, 1)
	toast(player, "Success", "💉 ¡Inversor de fase listo! Úsalo junto a una criatura («Revertir»)")
	missionEvent(player, "Crafted", {})
	return true
end

function InvasionService.sell(player: Player): number
	local inv = service("InventoryService")
	local total = 0
	for id, n in ownedCounts(player) do
		local price = Loot.price(id)
		local def = Loot.get(id)
		-- (se vende lo que es para vender: materiales, minerales y coleccionables repetidos no)
		if price > 0 and def and (def.Kind == "Material" or def.Kind == "Mineral") and inv and inv.remove(player, id, n) then
			total += price * n
		end
	end
	if total > 0 then
		DataService.addMoney(player, total, true)
		toast(player, "Success", ("💰 Vendido al laboratorio por $%d"):format(total))
	else
		toast(player, "Info", "No tienes materiales ni minerales alienígenas para vender")
	end
	return total
end

function InvasionService.unstash(player: Player): number
	local d = invData(player)
	local inv = service("InventoryService")
	if not d or not inv then
		return 0
	end
	local moved = 0
	for id, n in d.Stash do
		local count = tonumber(n) or 0
		while count > 0 and inv.add(player, id, 1) do
			count -= 1
			moved += 1
		end
		d.Stash[id] = if count > 0 then count else nil
	end
	toast(player, "Info", if moved > 0 then ("📦 %d cosas de la Xenobodega a tu mochila"):format(moved) else "📦 La Xenobodega está vacía (o tu mochila, llena)")
	return moved
end

local function buildLab()
	if lab.Model and lab.Model.Parent then
		return
	end
	local anchor: Vector3? = nil
	local loc = service("LocationService")
	local p1 = Players:GetPlayers()[1]
	if loc and p1 then
		local ok, spot = pcall(loc.resolve, p1, "Hospital")
		if ok and spot then
			anchor = spot.Position
		end
	end
	if not anchor then
		return
	end
	local pos = Landing.find(anchor.X + InvasionService.LabOffset.X, anchor.Z + InvasionService.LabOffset.Z, function(x, z)
		local p = probe(x, z)
		p.Clear = true -- (el puesto es pequeño: basta con suelo firme)
		return p
	end) or anchor
	local model = Instance.new("Model")
	model.Name = "LaboratorioXeno"
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.Parent = model
		return p
	end
	local base = CFrame.new(pos)
	local desk = part("Mostrador", Vector3.new(8, 3.4, 3), base * CFrame.new(0, 1.7, 0), Color3.fromRGB(235, 238, 242))
	part("Toldo", Vector3.new(10, 0.4, 6), base * CFrame.new(0, 8, 1), Color3.fromRGB(40, 170, 160))
	part("Poste", Vector3.new(0.5, 8, 0.5), base * CFrame.new(-4.6, 4, 3.6), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
	part("Poste", Vector3.new(0.5, 8, 0.5), base * CFrame.new(4.6, 4, 3.6), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
	local vial = part("Probeta", Vector3.new(0.8, 1.6, 0.8), base * CFrame.new(2.5, 4.2, 0), Color3.fromRGB(120, 255, 200), Enum.Material.Neon)
	vial.Shape = Enum.PartType.Cylinder
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(220, 46)
	sign.StudsOffset = Vector3.new(0, 3, 0)
	sign.MaxDistance = 120
	sign.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(10, 40, 40)
	label.TextColor3 = Color3.fromRGB(150, 255, 230)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "🧪 LABORATORIO XENO"
	label.Parent = sign
	sign.Parent = desk
	local function prompt(name: string, text: string, key: Enum.KeyCode, offset: number, fn: (Player) -> ())
		local p = Instance.new("ProximityPrompt")
		p.Name = name
		p.ActionText = text
		p.ObjectText = "Laboratorio Xeno"
		p.KeyboardKeyCode = key
		p.MaxActivationDistance = 12
		p.RequiresLineOfSight = false
		p.UIOffset = Vector2.new(0, offset)
		p.Parent = desk
		p.Triggered:Connect(function(player)
			local s = stateOf(player)
			if now() - s.LastAction < InvasionService.ActionGap then
				return
			end
			s.LastAction = now()
			fn(player)
		end)
	end
	prompt("Doctora", "Hablar con la Dra. Arenas", Enum.KeyCode.E, 0, function(player)
		local okStart, why = startMission(player, "Normalidad", true)
		if not okStart then
			toast(player, "Info", "👩‍🔬 Dra. Arenas: «" .. (if why == "Ya la estás haciendo." then "Sigue así: cada vecino cuenta." elseif why then why else "Vuelve cuando haga falta.") .. "»")
		end
	end)
	prompt("Fabricar", "Fabricar inversor de fase", Enum.KeyCode.F, 60, InvasionService.craft)
	prompt("Vender", "Vender materiales alienígenas", Enum.KeyCode.G, 120, InvasionService.sell)
	prompt("Bodega", "Recoger de la Xenobodega", Enum.KeyCode.H, 180, InvasionService.unstash)
	model.PrimaryPart = desk
	stream(model)
	model.Parent = getFolder()
	lab.Model, lab.Pos = model, pos
	local folderLm = ReplicatedStorage:FindFirstChild("MapLandmarks")
	if folderLm and not folderLm:FindFirstChild("LabXeno") then
		local config = Instance.new("Configuration")
		config.Name = "LabXeno"
		config:SetAttribute("Kind", "LabXeno")
		config:SetAttribute("Position", Vector3.new(pos.X, 0, pos.Z))
		config:SetAttribute("District", "")
		config.Parent = folderLm
	end
end
InvasionService.buildLab = buildLab

---------------------------------------------------------------------
-- Misiones de vuelo: el explorador, la baliza y el vuelo de evacuación
---------------------------------------------------------------------
function InvasionService.ensureScout()
	if not E or special.Scout or E.State == "End" then
		return
	end
	local race = E.Lineup.Main
	local rec = spawnAir("Scout", race, InvasionService.Bay + Vector3.new(260, 0, 0), "Scout")
	if rec then
		rec.Until = now() + 240
		special.Scout = rec
		worldToast("📡 Torre: un explorador alienígena da vueltas sobre la bahía", "Warn")
	end
end

local function spawnBeacon()
	if not E or special.Beacon then
		return
	end
	local race = Races.get(E.Lineup.Main)
	if not race then
		return
	end
	local model, pylons = AlienModels.beacon(race)
	model:PivotTo(CFrame.new(InvasionService.BeaconAt))
	local id = "Beacon"
	setTarget(model, id, "Beacon", race.Id, 900)
	model:SetAttribute("InvasionShip", true)
	model.Parent = sub("Air")
	special.Beacon = { Id = id, Model = model, Pylons = pylons, PylonHp = { 260, 260, 260 }, Hp = 900, MaxHp = 900, Race = race.Id }
end

function InvasionService.ensureEvac()
	if not E or special.Evac or E.State == "End" then
		return
	end
	local model = AlienModels.evacJet()
	local route = InvasionService.EvacRoute
	model:PivotTo(CFrame.lookAt(route[1], route[2]))
	model:SetAttribute("Evac", true)
	stream(model)
	model.Parent = sub("Air")
	special.Evac = { Id = "Evac", Model = model, Pos = route[1], Dir = (route[2] - route[1]).Unit, Leg = 1, Hp = 700, Escort = {}, Started = now() }
	worldToast("✈ El vuelo de evacuación EV-01 despega del aeropuerto: ¡escoltadlo!", "Warn")
	-- (y le salen al paso dos cazas)
	for i = 1, 2 do
		spawnAir("Fighter", E.Lineup.Main, route[2] + Vector3.new(i * 120, 120, -200))
	end
end

local function stepEvac(dt: number)
	local ev = special.Evac
	if not ev then
		return
	end
	local route = InvasionService.EvacRoute
	local goal = route[ev.Leg + 1]
	if not goal then
		-- Ha salido del corredor: misión cumplida para quien lo haya escoltado bastante
		for uid, time in ev.Escort do
			local p = Players:GetPlayerByUserId(uid)
			if p and time >= 25 then
				missionEvent(p, "EscortDone", {})
				addPoints(p, 80)
			end
		end
		worldToast("✈ EV-01: «Corredor despejado. Gracias, Valmar»", "Success")
		ev.Model:Destroy()
		special.Evac = nil
		return
	end
	local to = goal - ev.Pos
	if to.Magnitude < 30 then
		ev.Leg += 1
	else
		ev.Dir = to.Unit
		ev.Pos += ev.Dir * math.min(to.Magnitude, InvasionService.EvacSpeed * dt)
	end
	ev.Model:PivotTo(CFrame.lookAt(ev.Pos, ev.Pos + ev.Dir))
	for _, p in valmarPlayers() do
		local via, root = viaOf(p)
		if via == "Plane" and root and (root.Position - ev.Pos).Magnitude < 380 then
			ev.Escort[p.UserId] = (ev.Escort[p.UserId] or 0) + dt
		end
	end
	if ev.Hp <= 0 then
		worldToast("✈ EV-01 tocado: vuelve al aeropuerto para un aterrizaje de emergencia (todos bien). Lo intentará otra vez", "Error")
		ev.Model:Destroy()
		special.Evac = nil
		task.delay(25, function()
			if E and E.State == "Wave" then
				InvasionService.ensureEvac()
			end
		end)
	end
end

---------------------------------------------------------------------
-- Amenazas para la gente que huye (Panic)
---------------------------------------------------------------------
function InvasionService.threats(): { Panic.Threat }
	local out = {}
	for _, g in ground do
		table.insert(out, { Pos = g.AI.Pos, Radius = Panic.Radius, Weight = if g.AI.Kind == "Heavy" or g.AI.Kind == "Elite" then 1 else 0.8 })
	end
	for _, d in drops do
		table.insert(out, { Pos = d.Land, Radius = Panic.LandingRadius, Weight = 1 })
	end
	local t = now()
	for _, x in explosions do
		if x.Until > t then
			table.insert(out, { Pos = x.Pos, Radius = Panic.ExplosionRadius, Weight = 0.7 })
		end
	end
	local k = E and E.KingRec
	if k then
		table.insert(out, { Pos = k.Pos, Radius = 220, Weight = 1 })
	end
	return out
end

local function publish()
	local ev = E
	if not ev then
		return
	end
	local zones = {}
	for _, z in ev.Zones do
		table.insert(zones, { Id = z.Id, Name = z.Name, X = math.floor(z.Pos.X), Y = math.floor(z.Pos.Y), Z = math.floor(z.Pos.Z), Control = math.floor(z.Control * 100) / 100, Conquered = z.Conquered })
	end
	table.sort(zones, function(a, b)
		return a.Id < b.Id
	end)
	local nAir, nGround = 0, 0
	for _ in air do
		nAir += 1
	end
	for _ in ground do
		nGround += 1
	end
	for _ in drops do
		nAir += 1
	end
	local k = ev.KingRec
	local payload = {
		Id = ev.Id,
		State = ev.State,
		Wave = ev.Wave,
		Waves = ev.Waves,
		Races = ev.Lineup.Races,
		Main = ev.Lineup.Main,
		King = ev.Lineup.King,
		KingAlive = k ~= nil,
		KingHp = if k then math.floor(k.State.Hp) else nil,
		KingMax = if k then math.floor(k.State.MaxHp) else nil,
		KingStatus = if k then King.status(k.State, now()) else nil,
		Zones = zones,
		Air = nAir,
		Ground = nGround,
		Outcome = ev.Outcome,
		Text = Rules.stateText(ev.State, ev.Wave, ev.Waves, ev.Lineup.King ~= nil),
		Left = math.max(0, math.floor(Rules.MaxSeconds - (now() - ev.Started))),
		Beacon = special.Beacon ~= nil,
		Scout = special.Scout ~= nil,
		Evac = if special.Evac then { X = math.floor(special.Evac.Pos.X), Y = math.floor(special.Evac.Pos.Y), Z = math.floor(special.Evac.Pos.Z) } else nil,
	}
	local ok, json = pcall(HttpService.JSONEncode, HttpService, payload)
	if ok then
		workspace:SetAttribute("Invasion", json)
	end
end

-- La fila EVENTO del HUD de la nave (SpaceService.infoFor): «🛸 Invasión · Oleada 2 de 4 · Baliza»
function InvasionService.shipEventText(_player: Player): string?
	local ev = E
	if not ev or ev.State == "End" then
		return nil
	end
	local parts = { "🛸 INVASIÓN · " .. Rules.stateText(ev.State, ev.Wave, ev.Waves, ev.Lineup.King ~= nil) }
	if special.Beacon then
		table.insert(parts, "baliza nodriza arriba")
	end
	local n = 0
	for _ in air do
		n += 1
	end
	if n > 0 then
		table.insert(parts, ("%d naves"):format(n))
	end
	return table.concat(parts, " · ")
end

local function publishThreats()
	local ok, json = pcall(HttpService.JSONEncode, HttpService, Panic.encode(InvasionService.threats(), 24))
	if ok then
		workspace:SetAttribute("InvasionThreats", json)
	end
end

local function publishCity()
	local s = Transform.summary(city)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, s)
	if ok then
		workspace:SetAttribute("InvasionCity", json)
	end
end

---------------------------------------------------------------------
-- Empezar y acabar
---------------------------------------------------------------------
local ensureLoop: () -> ()

function InvasionService.active(): boolean
	return E ~= nil and E.State ~= "End"
end

-- opts = { Tester = bool, King = bool, Races = n, Race = id }
function InvasionService.start(opts: { [string]: any }?): boolean
	if E then
		return false
	end
	local o = opts or {}
	local lineup = Races.lineup(history, r, { ForceKing = o.King == true, ForceRaces = o.Races, Race = o.Race })
	local zones = resolveZones()
	if not next(zones) then
		warn("[Invasion] no hay ningún sitio libre para aterrizar: no empieza")
		return false
	end
	graph = graph or Nav.graph()
	if #safePoints == 0 then
		safePoints = collectSafe()
		local list = {}
		for _, s in safePoints do
			table.insert(list, { math.floor(s.Pos.X), math.floor(s.Pos.Z), s.Kind })
		end
		local ok, json = pcall(HttpService.JSONEncode, HttpService, list)
		if ok then
			workspace:SetAttribute("InvasionSafe", json)
		end
	end
	history.Count += 1
	history.Last = lineup.Main
	history.SinceKing = if lineup.King then 0 else history.SinceKing + 1
	local t = now()
	E = {
		Id = history.Count,
		Lineup = lineup,
		State = "Warn",
		Since = t,
		Started = t,
		Wave = 0,
		Waves = Rules.waveCount(lineup.King ~= nil),
		Spawned = false,
		Open = true,
		Zones = zones,
		Contrib = {},
		DamageBy = {},
		KingRec = nil,
		Outcome = nil,
		Reason = nil,
		EndAt = nil,
		Tester = o.Tester == true,
		Killed = 0,
		Conquests = 0,
		Retakes = 0,
	}
	workspace:SetAttribute("InvasionActive", true)
	Layers.setCityOpen(true) -- (las naves pueden bajar al cielo de la ciudad mientras dure)
	local main = Races.get(lineup.Main) :: Races.Race
	local names = Races.names(lineup.Races)
	worldToast(("🛸 ¡INVASIÓN! Por la grieta llegan los %s%s"):format(names, if #lineup.Races > 1 and lineup.Rivalry then " (y no se llevan bien entre ellos)" else ""), "Error")
	broadcast("Start", { Races = lineup.Races, Main = lineup.Main, King = lineup.King, Lore = main.Lore, Galaxy = main.Galaxy })
	for _, p in Players:GetPlayers() do
		local s = stateOf(p)
		s.Points = 0
		s.Airborne = {}
		s.PlaneHp = Rules.PlaneHp
		s.Counters.Invasion = {}
		task.spawn(function()
			startMission(p, "Defensa", true)
			local d = invData(p)
			if d then
				d.Stats.Invasions += 1
			end
		end)
		StoryEvents.emit(p, "InvasionStarted", { Race = lineup.Main, King = lineup.King ~= nil })
	end
	spawnBeacon()
	publish()
	ensureLoop()
	return true
end

local function clearEventModels()
	for id, g in ground do
		if not g.Pocket then
			removeGround(id, false)
		end
	end
	for id in air do
		removeAir(id, false)
	end
	for id in drops do
		removeDrop(id, false)
	end
	table.clear(bolts)
	if E and E.KingRec then
		E.KingRec.Model:Destroy()
		E.KingRec = nil
	end
	if special.Beacon then
		special.Beacon.Model:Destroy()
		special.Beacon = nil
	end
	if special.Evac then
		special.Evac.Model:Destroy()
		special.Evac = nil
	end
	special.Scout = nil
	for id, res in rescue do
		res.Model:Destroy()
		rescue[id] = nil
	end
	for _, rsp in responders do
		rsp.Model:Destroy()
	end
	table.clear(responders)
	for _, c in cones do
		c:Destroy()
	end
	table.clear(cones)
end

function InvasionService.finish(reason: string?)
	local ev = E
	if not ev or ev.State == "End" then
		return
	end
	local conquered, total = 0, 0
	for _, z in ev.Zones do
		total += 1
		if z.Conquered then
			conquered += 1
		end
	end
	local outcome = Rules.outcome(reason, conquered, total, ev.KingRec ~= nil)
	ev.State = "End"
	ev.Since = now()
	ev.Outcome = outcome
	ev.Reason = reason
	-- Bolsas: en las zonas conquistadas se quedan unos pocos atrincherados
	local pockets = 0
	for _, z in ev.Zones do
		if z.Conquered and pockets < 2 then
			pockets += 1
			local p = Transform.pocket(city, ev.Lineup.Main, z.Pos, 3, os.clock(), r)
			for i = 1, 3 do
				local a = i / 3 * math.pi * 2
				local x, zz = z.Pos.X + math.cos(a) * 12, z.Pos.Z + math.sin(a) * 12
				spawnGround(ev.Lineup.Main, if i == 3 then "Heavy" else "Grunt", Vector3.new(x, groundY(x, zz, z.Pos.Y), zz), nil, p.Id)
			end
		end
	end
	-- Los servicios cerrados ya se pueden reabrir
	for _, s in shutters do
		local prompt = s:FindFirstChild("Reabrir")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = true
		end
	end
	clearEventModels()
	-- (la gente vuelve a salir a la calle: sin amenazas, CrowdService deja de bloquear)
	local crowd = service("CrowdService")
	if crowd and crowd.flee then
		pcall(crowd.flee, {}, safePoints)
	end
	-- Premios por lo que ha hecho cada uno
	for _, p in Players:GetPlayers() do
		local pts = ev.Contrib[p.UserId] or 0
		local money, xp = Rules.reward(pts, outcome)
		if money > 0 then
			pcall(DataService.addMoney, p, money, true)
			pcall(function()
				service("ProgressionService").addXp(p, xp, "Invasion")
			end)
		end
		send(p, "End", { Outcome = outcome, Points = math.floor(pts), Money = money, Xp = xp, Reason = reason })
		local d = invData(p)
		if d then
			Missions.endInvasion(d.Book)
			publishBook(p)
		end
		StoryEvents.emit(p, "InvasionEnded", { Outcome = outcome, Points = math.floor(pts) })
		-- Si la ciudad ha quedado tocada, la doctora pide ayuda (a quien haya participado)
		if pts > 0 and not Transform.summary(city).Normal then
			task.spawn(startMission, p, "Normalidad", true)
		end
	end
	worldToast(if outcome == "Victoria" then "🏆 ¡VICTORIA! Valmar ha resistido la invasión" else "⚠ Los alienígenas se repliegan… pero dejan Valmar tocada. Toca recuperarla", if outcome == "Victoria" then "Success" else "Error")
	workspace:SetAttribute("InvasionActive", false)
	Layers.setCityOpen(false)
	history.LastEnd = now()
	publish()
	publishCity()
	task.delay(Rules.EndSeconds, function()
		if E == ev then
			E = nil
			workspace:SetAttribute("Invasion", nil)
			workspace:SetAttribute("InvasionThreats", nil)
			workspace:SetAttribute("InvasionActive", nil)
		end
	end)
end

-- Una oleada nueva
local function nextWave()
	local ev = E :: Event
	ev.Wave += 1
	ev.State = "Wave"
	ev.Since = now()
	ev.Spawned = true
	local players = math.max(#valmarPlayers(), 1)
	local isKing = ev.Lineup.King ~= nil and ev.Wave > Rules.Waves
	local w = Rules.wave(ev.Wave, players, ev.Lineup.King ~= nil)
	local races = ev.Lineup.Races
	local zoneList = {}
	for _, z in ev.Zones do
		table.insert(zoneList, z)
	end
	table.sort(zoneList, function(a, b)
		return a.Id < b.Id
	end)
	-- (las zonas que más importan: primero las que no están conquistadas, cerca de los jugadores)
	local people = footTargets()
	table.sort(zoneList, function(a, b)
		local function score(z: ZoneRec): number
			local best = math.huge
			for _, p in people do
				best = math.min(best, AlienAI.flat(p.Pos, z.Pos))
			end
			return best + (if z.Conquered then 3000 else 0)
		end
		return score(a) < score(b)
	end)
	local function race(i: number): string
		return races[(i - 1) % #races + 1]
	end
	for i = 1, w.Dropships do
		local z = zoneList[(i - 1) % #zoneList + 1]
		spawnDropship(race(i), z, w.PerDrop)
	end
	local center = if zoneList[1] then zoneList[1].Pos else Vector3.zero
	for i = 1, w.Fighters + w.Drones do
		local a = i / (w.Fighters + w.Drones) * math.pi * 2
		local pos = center + Vector3.new(math.cos(a) * 900, 450 + (i % 3) * 120, math.sin(a) * 900)
		spawnAir(if i <= w.Fighters then "Fighter" else "Drone", race(i), pos)
	end
	if w.Elite then
		local z = zoneList[1]
		if z then
			spawnGround(race(1), "Elite", z.Pos + Vector3.new(0, 0, 30), z.Id)
		end
	end
	if isKing and not ev.KingRec and zoneList[1] then
		spawnKing(ev.Lineup.King :: string, zoneList[1])
	end
	worldToast(("🛸 %s"):format(Rules.stateText("Wave", ev.Wave, ev.Waves, isKing)), "Warn")
	broadcast("Wave", { Wave = ev.Wave, Waves = ev.Waves, King = isKing })
end

local function alive(): number
	local n = 0
	for _, g in ground do
		if not g.Pocket then
			n += 1
		end
	end
	for _, a in air do
		if not a.Mission then
			n += 1
		end
	end
	for _ in drops do
		n += 1
	end
	if E and E.KingRec then
		n += 1
	end
	return n
end
InvasionService.alive = alive

-- ¿Está abierta la grieta para todo el servidor? (Rules.serverPhase)
function InvasionService.riftOpen(): boolean
	local demo = type(Config.SkyRift) == "table" and Config.SkyRift.DemoCycle == true
	local offset = workspace:GetAttribute("SkyRiftDemoOffset")
	local phases = {}
	for _, p in Players:GetPlayers() do
		local ph = p:GetAttribute("SkyRift")
		if type(ph) == "string" then
			table.insert(phases, ph)
		end
	end
	local ok, phase = pcall(Rules.serverPhase, SkyRift, demo, GameClock.hour(), if type(offset) == "number" then offset else 0, phases)
	return ok and Rules.isOpening(phase)
end

local function watchRift()
	local open = InvasionService.riftOpen()
	if E then
		if not E.Tester then
			E.Open = open
		end
	elseif Rules.shouldStart(wasOpen, open, false, now(), history.LastEnd) and #valmarPlayers() > 0 then
		InvasionService.start()
	end
	wasOpen = open
end

local function stepEvent(dt: number, t: number)
	local ev = E
	if not ev or ev.State == "End" then
		return
	end
	local nextState, reason = Rules.next({ State = ev.State, Since = ev.Since, Wave = ev.Wave, Waves = ev.Waves, Alive = alive(), Spawned = ev.Spawned, Open = ev.Open, Elapsed = t - ev.Started }, t)
	if nextState == "Wave" then
		nextWave()
	elseif nextState == "End" then
		InvasionService.finish(reason)
		return
	end
	-- (si alguien sigue con «Ojos sobre la bahía» o «Corredor de evacuación» y su objetivo ya no está —el
	-- explorador se escapó, el vuelo aterrizó—, vuelve a salir: nunca te quedas sin poder acabarla)
	clocks.Watch += dt
	if clocks.Watch >= 5 and ev.State == "Wave" then
		clocks.Watch = 0
		for _, p in Players:GetPlayers() do
			local d = invData(p)
			if d and d.Book.Active.Bahia and not special.Scout then
				InvasionService.ensureScout()
			end
			if d and d.Book.Active.Evacuacion and not special.Evac then
				InvasionService.ensureEvac()
			end
		end
	end
	-- «Despegado»: en avión o en nave durante la invasión (para las misiones de vuelo)
	for _, p in valmarPlayers() do
		local via, _, extra = viaOf(p)
		local s = stateOf(p)
		local up = (via == "Plane" and extra and extra.Airborne) or via == "Ship"
		if up and not s.Airborne[via] then
			s.Airborne[via] = true
			missionEvent(p, "Airborne", { Via = via })
		end
	end
end

local function hasWork(): boolean
	return E ~= nil or next(creatures) ~= nil or next(ground) ~= nil or next(city.Damage) ~= nil or next(city.Services) ~= nil or next(city.Pockets) ~= nil
end

local acc = 0
ensureLoop = function()
	if loop then
		return
	end
	loop = RunService.Heartbeat:Connect(function(frameDt)
		acc += frameDt
		if acc < InvasionService.Tick then
			return
		end
		local dt = math.min(acc, 0.2)
		acc = 0
		local ok, err = pcall(InvasionService.step, dt)
		if not ok then
			warn("[Invasion] " .. tostring(err))
		end
		if not hasWork() and loop then
			loop:Disconnect()
			loop = nil
		end
	end)
end

-- Una vuelta (también la usan las pruebas)
function InvasionService.step(dt: number)
	local t = now()
	clocks.Think += dt
	clocks.Zone += dt
	clocks.Publish += dt
	clocks.Threat += dt
	clocks.City += dt
	local think = clocks.Think >= InvasionService.ThinkEvery
	if think then
		clocks.Think = 0
	end
	stepEvent(dt, t)
	stepAir(dt, t)
	stepBolts(dt)
	stepDrops(dt, t)
	stepGround(dt, t, think)
	stepKing(dt, t)
	stepEvac(dt)
	if clocks.Zone >= InvasionService.ZoneEvery then
		stepZones(clocks.Zone)
		stepResponders(t)
		clocks.Zone = 0
	end
	if clocks.City >= InvasionService.CityEvery then
		stepCity(clocks.City, t)
		clocks.City = 0
	end
	if clocks.Publish >= InvasionService.PublishEvery then
		clocks.Publish = 0
		publish()
		publishCity()
	end
	if clocks.Threat >= InvasionService.ThreatEvery then
		clocks.Threat = 0
		publishThreats()
		local crowd = service("CrowdService")
		if crowd and crowd.flee and E then
			pcall(crowd.flee, InvasionService.threats(), safePoints)
		end
	end
end

---------------------------------------------------------------------
-- Modo pruebas
---------------------------------------------------------------------
-- action: "Start" | "King" | "Multi" | "Stop" | "Wave" | "City"
function InvasionService.tester(player: Player, action: any): (boolean, string)
	if action == "Stop" then
		if not E then
			return false, "No hay ninguna invasión"
		end
		InvasionService.finish("Tester")
		return true, "🛸 Invasión terminada"
	elseif action == "Wave" then
		if not E or E.State == "End" then
			return false, "No hay ninguna invasión"
		end
		E.Since -= Rules.WaveSeconds + Rules.WarnSeconds
		return true, "🛸 Siguiente oleada"
	elseif action == "City" then
		-- Deja la ciudad tocada (para probar «Recuperar la normalidad» sin esperar a una invasión)
		local root = rootOf(player)
		if not root then
			return false, "Sin personaje"
		end
		local race = history.Last or Races.List[1].Id
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			local p = root.Position + Vector3.new(math.cos(a) * 18, 0, math.sin(a) * 18)
			transformAt(race, Vector3.new(p.X, groundY(p.X, p.Z, p.Y), p.Z))
		end
		local zone = { Id = "Pruebas", Name = "Aquí", Pos = root.Position, Control = 0, Conquered = false, Siege = {}, Damaged = 0 }
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2 + 1
			local p = root.Position + Vector3.new(math.cos(a) * 26, 0, math.sin(a) * 26)
			damageZone(zone :: any, Vector3.new(p.X, groundY(p.X, p.Z, p.Y), p.Z), race)
		end
		buildLab()
		ensureLoop()
		startMission(player, "Normalidad", true)
		giveItem(player, Races.get(race).Sample, 3, true)
		giveItem(player, Races.get(race).Material, 1, true)
		return true, "🧪 Ciudad tocada a tu alrededor: 3 criaturas y 3 destrozos (y muestras para el inversor)"
	end
	if E then
		return false, "Ya hay una invasión en marcha"
	end
	local ok = InvasionService.start({ Tester = true, King = action == "King", Races = if action == "Multi" then 2 else nil })
	if ok then
		buildLab()
	end
	return ok, if ok then "🛸 ¡Invasión lanzada para todo el servidor!" else "No se ha podido lanzar (¿sin sitios libres?)"
end

---------------------------------------------------------------------
-- Remoto y arranque
---------------------------------------------------------------------
local function onRemote(player: Player, action: any, a: any)
	if type(action) ~= "string" then
		return
	end
	if action == "PlaneFire" then
		InvasionService.planeFire(player, a)
		return
	end
	local s = stateOf(player)
	if now() - s.LastAction < InvasionService.ActionGap then
		return
	end
	s.LastAction = now()
	if action == "Accept" and type(a) == "string" and Missions.get(a) then
		startMission(player, a)
	elseif action == "Sync" then
		publishBook(player)
	end
end

function InvasionService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local existing = remotes:FindFirstChild("Invasion") :: RemoteEvent?
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = "Invasion"
		created.Parent = remotes
		existing = created
	end
	remote = existing
	;(remote :: RemoteEvent).OnServerEvent:Connect(onRemote)
	Layers.setCityOpen(false)
	-- Hooks en los demás sistemas (aditivos: si falta uno, la invasión sigue sin él)
	local combat = service("CombatService")
	if combat then
		combat.invasionHit = InvasionService.hitModel
	end
	local ac = service("AirCombatService")
	if ac then
		ac.ExternalHit = shipBolt
	end
	local weapons = service("WeaponService")
	if weapons then
		weapons.invasionShip = function(player: Player, part: Instance, amount: number, at: Vector3): boolean
			return (InvasionService.hitModel(player, part, amount, { At = at }))
		end
		weapons.invasionRewind = InvasionService.rewindHit
	end
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			DataService.waitFor(player, 30)
			publishBook(player)
		end)
		player.CharacterAdded:Connect(function()
			task.delay(12, function()
				player:SetAttribute("InvasionDown", nil)
			end)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		pstate[player] = nil
	end)
	-- La grieta: cada 2 s (nada más que una cuenta)
	task.spawn(function()
		task.wait(8)
		while true do
			local ok, err = pcall(watchRift)
			if not ok then
				warn("[Invasion] " .. tostring(err))
			end
			if hasWork() then
				ensureLoop()
			end
			task.wait(2)
		end
	end)
	-- El laboratorio, cuando haya alguien (necesita resolver el hospital)
	task.spawn(function()
		while not lab.Model do
			if #Players:GetPlayers() > 0 then
				pcall(buildLab)
			end
			task.wait(10)
		end
	end)
end

return InvasionService
