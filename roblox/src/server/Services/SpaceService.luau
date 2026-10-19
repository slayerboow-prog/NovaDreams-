-- SpaceService: el espacio encima de Valmar (docs/espacio.md). Quedarse en Valmar está bien: todo
-- esto es opcional.
--
--   * Puerto espacial (islote de la costa oeste, World/SpaceWorld): «Subir a la nave» (con la Saga 1
--     terminada o siendo tester; si no, un aviso amable), portal a la Estación Alba y portal a la playa.
--     En la playa del Distrito Oeste, el portal «Ir al puerto espacial» (lo puede usar todo el mundo).
--   * La nave (AirCombatService, World = "Cosmos"): despegas, cruzas el cielo de los aviones (ahí no hay
--     nada del espacio) y, por encima de shared/Cosmos/Layers.SpaceY, estás en el espacio: estaciones,
--     asteroides que se minan con el láser, patrullas enemigas en sus sectores y los 7 planetas al fondo.
--   * Volver a Valmar SIEMPRE: botón VALMAR de la nave (fundido rápido → puerto espacial), portal de
--     cada estación, o bajarse de la nave por debajo de Layers.LandY (te deja en el suelo de debajo o en
--     el puerto). Si te desconectas en el espacio, al volver apareces en el puerto espacial
--     (atributos AirArenaReturn / SpaceReturn: PositionService).
--   * Estaciones (zona segura): atracar, tienda (vender mineral, reparar, recargar misiles), tablón de
--     misiones secundarias (shared/Cosmos/Missions) y el hangar para despegar.
--   * Asteroides que se rompen (shared/Cosmos/Asteroids; docs/espacio-aaa/asteroides.md): el láser, los
--     misiles y los choques de la nave los dañan (grietas), al gastarse se parten en trozos más pequeños
--     que se pueden minar otra vez, y a los Asteroids.RespawnSeconds vuelven enteros. Lo decide el
--     servidor (vida, mineral, trozos) y lo publica en ReplicatedStorage.AsteroidesEstado (un atributo
--     de texto por asteroide roto); los pedazos de adorno, el polvo y las chispas son del cliente.
--   * Todo lo que se gana lo decide el servidor (minar: shared/Cosmos/Mining.allow; derribos: los
--     del servidor; misiones: sus sucesos) y se guarda en data.Space (DataService).
--
-- Remoto "Space" (cliente → servidor): "Home", "Dock", "Planet" (id), "Menu" (ficha, opción).
--   (servidor → cliente): "Menu", "Mine", "Chip", "Planet", "Docked".
-- API: SpaceService.board(player, desde?) · home(player) · toStation(player, id?) · toPort(player) ·
--   registerPlanet(id, { Travel = fn(player), Available = fn(player)? }) (episodios de la Saga 2)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Layers = require(Cosmos.Layers)
local Access = require(Cosmos.Access)
local Stations = require(Cosmos.Stations)
local Zone = require(Cosmos.Zone)
local Mining = require(Cosmos.Mining)
local Asteroids = require(Cosmos.Asteroids)
local Missions = require(Cosmos.Missions)
local Planets = require(Cosmos.Planets)
local NavInfo = require(Cosmos.NavInfo)
local SpaceEvents = require(Cosmos.SpaceEvents)
local Waves = require(ReplicatedStorage.Shared.AirCombat.Waves)
local ShipWeapons = require(ReplicatedStorage.Shared.AirCombat.ShipWeapons)
local ShipCombat = require(ReplicatedStorage.Shared.AirCombat.ShipCombat)
local Shields = require(ReplicatedStorage.Shared.AirCombat.Shields)

local DataService = require(script.Parent.DataService)

local SpaceService = {}

SpaceService.TickSeconds = 1
SpaceService.SpawnCooldown = 22 -- s entre patrullas
SpaceService.DespawnDistance = 2600
SpaceService.SpawnDistance = 780
SpaceService.KillReward = { Dron = 15, Caza = 40 } -- $ por derribo
SpaceService.KillChispas = { Caza = 1 }
SpaceService.ChispasPerHour = 40 -- tope de chispas por derribos (contra granjas de enemigos)
SpaceService.ActionGap = 0.4 -- s entre dos peticiones del cliente

type PState = {
	Rate: Mining.Rate,
	NextSpawn: number,
	LastAction: number,
	Ship: { Hull: number?, Missiles: number? },
	Menu: { Token: string, Actions: { () -> () } }?,
	MenuSerial: number,
	KillChispas: { number },
	Station: string?,
	Docking: boolean?,
}

local states: { [Player]: PState } = {}
local rocks: { [string]: Mining.Rock } = {}
local stages: { [string]: number } = {} -- nivel de daño que se ve en cada asteroide entero
local remote: RemoteEvent? = nil
local notify: RemoteEvent? = nil
local loop: RBXScriptConnection? = nil
local beachCF: CFrame? = nil
local acc = 0
local ensureLoop: () -> ()

local function service(name: string): any
	return require(script.Parent[name])
end

local function now(): number
	return os.clock()
end

-- La hora de los eventos globales (la misma en todos los servidores y clientes: shared/Cosmos/SpaceEvents)
function SpaceService.eventClock(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.time()
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function send(player: Player, kind: string, payload: any?)
	if remote and player.Parent then
		remote:FireClient(player, kind, payload)
	end
end

local function stateOf(player: Player): PState
	local s = states[player]
	if not s then
		s = { Rate = Mining.newRate(), NextSpawn = 0, LastAction = -math.huge, Ship = {}, Menu = nil, MenuSerial = 0, KillChispas = {}, Station = nil }
		states[player] = s
	end
	return s
end

-- data.Space (con lo que falte, por si la partida es de antes)
local function spaceData(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	if type(data.Space) ~= "table" then
		data.Space = {}
	end
	local sp = data.Space
	sp.Chispas = tonumber(sp.Chispas) or 0
	if type(sp.Ore) ~= "table" then
		sp.Ore = {}
	end
	if type(sp.Missions) ~= "table" then
		sp.Missions = {}
	end
	sp.Mined = tonumber(sp.Mined) or 0
	sp.Kills = tonumber(sp.Kills) or 0
	sp.Done = tonumber(sp.Done) or 0
	if type(sp.Planets) ~= "table" then
		sp.Planets = {}
	end
	-- (nombres nuevos de los planetas: las partidas viejas pasan a los ids nuevos sin perder nada)
	Planets.migrate(sp.Planets)
	Mining.migrate(sp.Ore)
	-- (Espacio AAA) puntos de interés descubiertos volando: destinos del salto cuántico
	if type(sp.Found) ~= "table" then
		sp.Found = {}
	end
	-- (Espacio AAA, fase 9) mejoras de la nave, drones desbloqueados y el que llevas
	if type(sp.Upgrades) ~= "table" then
		sp.Upgrades = {}
	end
	if type(sp.Drones) ~= "table" then
		sp.Drones = {}
	end
	if type(sp.DroneKind) ~= "string" or not sp.Drones[sp.DroneKind] then
		sp.DroneKind = nil
	end
	return sp
end
SpaceService.spaceData = spaceData

local function isTester(player: Player): boolean
	local ok, yes = pcall(function()
		return service("TesterService").isTester(player)
	end)
	return ok and yes == true
end

function SpaceService.canFly(player: Player): (boolean, string?)
	return Access.canFly({ SagaDone = Access.sagaDone(DataService.get(player)), Tester = isTester(player) })
end

local function airCombat(): any
	return service("AirCombatService")
end

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root, humanoid
end

---------------------------------------------------------------------
-- Moverse (con un fundido rápido: Controllers/SceneDip)
---------------------------------------------------------------------
local function dip(player: Player)
	pcall(function()
		service("SceneService").dip(player)
	end)
end

local function setStation(player: Player, id: string?)
	stateOf(player).Station = id
	player:SetAttribute("SpaceStation", id)
	-- (si se desconecta en la estación, PositionService guarda el puerto espacial, no el cielo)
	player:SetAttribute("SpaceReturn", if id then Access.arrival().Position else nil)
	if id and ensureLoop then
		ensureLoop() -- (vigila que siga allí: tick)
	end
end

local function place(player: Player, cf: CFrame): boolean
	local root, humanoid = rootOf(player)
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	if humanoid.SeatPart then
		pcall(function()
			service("VehicleService").standUp(player)
		end)
		humanoid.Sit = false
	end
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 5)
	end)
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = cf
	return true
end

local function jump(player: Player, cf: CFrame, station: string?): boolean
	dip(player)
	-- (si estaba a pie en un planeta: fuera su nave aparcada y sus atributos; Services/PlanetService)
	pcall(function()
		service("PlanetService").leave(player)
	end)
	local ok = place(player, cf)
	if ok then
		setStation(player, station)
	end
	return ok
end

---------------------------------------------------------------------
-- El mundo (se construye la primera vez que hace falta)
---------------------------------------------------------------------
local function world(): any
	return require(script.Parent.Parent.World.SpaceWorld)
end

local promptsWired: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function wire(p: ProximityPrompt?, fn: (Player) -> ())
	if not p or promptsWired[p] then
		return
	end
	promptsWired[p] = true
	pcall(function()
		p.Triggered:Connect(function(player: Player)
			local ok, err = pcall(fn, player)
			if not ok then
				warn("[SpaceService] " .. tostring(err))
			end
		end)
	end)
end

local ensureSpace: () -> ()

ensureSpace = function()
	local W = world()
	if W.space() then
		return
	end
	W.buildSpace()
	for id, prompts in W.stationPrompts() do
		wire(prompts.Shop, function(player)
			SpaceService.shop(player, id)
		end)
		wire(prompts.Board, function(player)
			SpaceService.missionBoard(player, id)
		end)
		wire(prompts.Launch, function(player)
			SpaceService.board(player, id)
		end)
		wire(prompts.Home, function(player)
			SpaceService.home(player)
		end)
	end
end
SpaceService.ensureSpace = function()
	ensureSpace()
end

---------------------------------------------------------------------
-- Volar
---------------------------------------------------------------------
local objectiveFor: (Player) -> () -> string?
local onExitRequest: (Player) -> ()

-- Subir a la nave: en el puerto espacial (from = nil / "Port") o en el hangar de una estación (id)
function SpaceService.board(player: Player, from: string?): boolean
	local ok, why = SpaceService.canFly(player)
	if not ok then
		toast(player, "Info", Access.Messages[why or "Locked"] or Access.Messages.Locked)
		return false
	end
	local AC = airCombat()
	if AC.inArena(player) then
		return false
	end
	if player:GetAttribute("Piloting") ~= nil then
		toast(player, "Info", Access.Messages.Driving)
		return false
	end
	ensureSpace()
	local st = from and Stations.ById[from]
	local start = if st then Stations.launch(st) else Access.launch()
	local ps = stateOf(player)
	local entered = AC.enter(player, {
		World = "Cosmos",
		Trusted = true,
		Start = start,
		Section = Layers.mode(start.Position.Y),
		Return = Access.arrival(),
		Objective = objectiveFor(player),
		OnExit = onExitRequest,
		Hull = ps.Ship.Hull,
		Missiles = ps.Ship.Missiles,
	})
	if entered then
		setStation(player, nil)
		ps.NextSpawn = now() + 8
		ensureLoop() -- (patrullas: el bucle solo va mientras alguien vuela aquí)
		toast(player, "Success", if st
			then "🚀 Despegas del muelle. VALMAR te devuelve a casa cuando quieras."
			else "🚀 ¡Despega! Sube y sube: por encima del cielo de los aviones empieza el espacio. VALMAR te devuelve a casa cuando quieras.")
	end
	return entered
end

-- Volver a Valmar (siempre): de la nave o de una estación, al puerto espacial
function SpaceService.home(player: Player): boolean
	local AC = airCombat()
	local arrival = Access.arrival()
	-- (si estaba en un planeta, en la nave o a pie: Services/PlanetService recoge su nave aparcada)
	pcall(function()
		service("PlanetService").leave(player)
	end)
	local w = AC.world(player)
	if w == "Cosmos" or w == "Planet" then
		dip(player)
		AC.setReturn(player, arrival)
		AC.exit(player, "exit")
		setStation(player, nil)
		toast(player, "Success", Access.Messages.Home)
		return true
	end
	local ok = jump(player, arrival, nil)
	if ok then
		toast(player, "Success", Access.Messages.Home)
	end
	return ok
end

-- Bajarse de la nave (botón Salir / X): solo cerca del suelo
local function landingFor(player: Player, pos: Vector3): CFrame
	if Zone.nearPort(pos) then
		return Access.arrival()
	end
	local found: CFrame? = nil
	pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignore = {}
		if player.Character then
			table.insert(ignore, player.Character)
		end
		local ship = workspace:FindFirstChild("Nave_" .. player.UserId)
		if ship then
			table.insert(ignore, ship)
		end
		params.FilterDescendantsInstances = ignore
		params.IgnoreWater = false
		local hit = workspace:Raycast(Vector3.new(pos.X, math.min(pos.Y, Layers.LandY + 50), pos.Z), Vector3.new(0, -(Layers.LandY + 200), 0), params)
		if hit and hit.Material ~= Enum.Material.Water and hit.Position.Y < 80 then
			local SafeSpot = require(script.Parent.Parent.World.SafeSpot)
			local feet = SafeSpot.find(hit.Position)
			if feet then
				found = Access.face(feet + Vector3.new(0, 3, 0), Vector3.new(0, 0, -1))
			end
		end
	end)
	return found or Access.arrival()
end
SpaceService._landingFor = landingFor

onExitRequest = function(player: Player)
	local AC = airCombat()
	local st = AC.status(player)
	if not st then
		return
	end
	if st.World == "Planet" then
		-- (en un planeta: bajarse si la nave está posada; Services/PlanetService)
		service("PlanetService").disembark(player)
		return
	end
	if Stations.dockAt(st.Pos) then
		SpaceService.dock(player)
		return
	end
	if not Layers.canLand(st.Pos) then
		toast(player, "Info", Access.Messages.TooHigh:format(Layers.meters(Layers.LandY)))
		return
	end
	dip(player)
	AC.setReturn(player, landingFor(player, st.Pos))
	AC.exit(player, "exit")
	toast(player, "Success", "🛬 Has aterrizado. ¡Bienvenido a Valmar!")
end

-- Atracar en el muelle de una estación (bajarse en el vestíbulo)
function SpaceService.dock(player: Player): boolean
	local AC = airCombat()
	local st = AC.status(player)
	if not st or st.Down or AC.world(player) ~= "Cosmos" then
		return false
	end
	local station = Stations.dockAt(st.Pos)
	if not station then
		toast(player, "Info", "Acércate al muelle de una estación (el aro verde) para atracar")
		return false
	end
	local ps = stateOf(player)
	ps.Docking = true
	ps.Ship = { Hull = st.Hull, Missiles = st.Missiles }
	dip(player)
	AC.setReturn(player, Stations.arrival(station))
	AC.exit(player, "dock")
	ps.Docking = false
	setStation(player, station.Id)
	send(player, "Docked", { Station = station.Id })
	toast(player, "Success", ("🛰 Atracado en la %s: tienda, tablón de misiones y portal a Valmar."):format(station.Name))
	SpaceService.event(player, { Type = "Dock", Station = station.Id, Now = os.time() })
	return true
end

-- Portal del puerto espacial → Estación Alba (andando)
function SpaceService.toStation(player: Player, id: string?): boolean
	local ok, why = SpaceService.canFly(player)
	if not ok then
		toast(player, "Info", Access.Messages[why or "Locked"] or Access.Messages.Locked)
		return false
	end
	ensureSpace()
	local station = Stations.ById[id or "Alba"] or Stations.List[1]
	local moved = jump(player, Stations.arrival(station), station.Id)
	if moved then
		toast(player, "Success", ("🌀 %s: zona segura. Tienda, misiones, hangar y portal de vuelta a Valmar."):format(station.Name))
	end
	return moved
end

-- Al puerto espacial (andando, desde la playa o el modo pruebas)
function SpaceService.toPort(player: Player): boolean
	local ok = jump(player, Access.arrival(), nil)
	if ok then
		toast(player, "Info", "🚀 Puerto espacial de Valmar: «Subir a la nave» junto a la nave de exposición")
	end
	return ok
end

function SpaceService.toBeach(player: Player): boolean
	local cf = beachCF
	if not cf then
		return SpaceService.home(player)
	end
	return jump(player, cf * CFrame.new(0, 3, 10), nil) -- (detrás del portal, tierra adentro)
end

---------------------------------------------------------------------
-- Sucesos: derribos, minar, atracar, derribado (misiones y recompensas)
---------------------------------------------------------------------
local function reward(player: Player, money: number, chispas: number)
	if money > 0 then
		DataService.addMoney(player, money, true)
	end
	local sp = spaceData(player)
	if sp and chispas > 0 then
		sp.Chispas += chispas
	end
end

function SpaceService.event(player: Player, ev: { [string]: any })
	local sp = spaceData(player)
	if not sp then
		return
	end
	local done, lost = Missions.progress(sp.Missions, ev)
	for _, def in done do
		sp.Done += 1
		reward(player, def.Money, def.Chispas)
		toast(player, "Success", ("✅ Misión «%s» completada: +$%d · ✨ +%d Chispas de estrella"):format(def.Title, def.Money, def.Chispas))
	end
	for _, def in lost do
		toast(player, "Info", ("📦 Te han derribado: la carga de «%s» se ha perdido. Puedes volver a cogerla en el tablón."):format(def.Title))
	end
end

local function chispasAllowed(ps: PState, t: number): boolean
	local keep = {}
	for _, at in ps.KillChispas do
		if t - at < 3600 then
			table.insert(keep, at)
		end
	end
	ps.KillChispas = keep
	return #keep < SpaceService.ChispasPerHour
end

local function onKill(player: Player, data: { [string]: any })
	local kind = data and data.Kind
	if type(kind) ~= "string" then
		return
	end
	local sp = spaceData(player)
	if not sp then
		return
	end
	sp.Kills += 1
	local ps = stateOf(player)
	local chispas = SpaceService.KillChispas[kind] or 0
	if chispas > 0 and not chispasAllowed(ps, now()) then
		chispas = 0
	elseif chispas > 0 then
		table.insert(ps.KillChispas, now())
	end
	-- (evento global «Incursión pirata»: un derribo en su sector da una Chispa más, con el mismo tope)
	local st = airCombat().status(player)
	local sector = st and Zone.sectorAt(st.Pos)
	if sector and SpaceEvents.killBonus(SpaceService.eventClock(), sector.Id) and chispasAllowed(ps, now()) then
		table.insert(ps.KillChispas, now())
		chispas += 1
	end
	reward(player, SpaceService.KillReward[kind] or 0, chispas)
	SpaceService.event(player, { Type = "Kill", Kind = kind })
end

---------------------------------------------------------------------
-- Asteroides: daño, rotura en trozos y vuelta (shared/Cosmos/Asteroids)
---------------------------------------------------------------------
-- El estado que ven los clientes: un atributo de texto por asteroide roto (sin él: entero)
local function stateFolder(): Instance?
	local ok, f = pcall(function()
		local existing = ReplicatedStorage:FindFirstChild("AsteroidesEstado")
		if existing then
			return existing
		end
		local c = Instance.new("Configuration")
		c.Name = "AsteroidesEstado"
		c.Parent = ReplicatedStorage
		return c
	end)
	return if ok then f else nil
end

local function publish(root: string)
	local fam = Asteroids.family(root)
	local text = if fam then Asteroids.encode(fam) else nil
	SpaceService._published[root] = text
	local folder = stateFolder()
	if folder then
		pcall(function()
			folder:SetAttribute(root, text)
		end)
	end
end
SpaceService._published = {} :: { [string]: string? }

local function showStage(rock: Zone.Rock, r: Mining.Rock)
	if (rock :: any).Fragment then
		return
	end
	local stage = Asteroids.stage(r)
	if stages[rock.Id] ~= stage then
		stages[rock.Id] = stage
		pcall(function()
			world().setRockDamage(rock.Id, stage)
		end)
	end
end

-- Se rompe (se ha gastado): se parte en trozos más pequeños (o en polvo si ya es pequeño).
-- push: la velocidad de lo que lo rompe. Devuelve los trozos nuevos.
function SpaceService.breakRock(rock: Zone.Rock, push: Vector3?): { Asteroids.Fragment }
	local t = Asteroids.clock()
	local any = rock :: any
	local root = any.Root or rock.Id
	local fam = Asteroids.family(root)
	if not fam then
		fam = { Root = root, Field = rock.Field, Respawn = t + Asteroids.RespawnSeconds, Frags = {} }
	end
	local gen, parentVel = 1, nil
	if any.Fragment then
		local f = Asteroids.fragment(rock.Id)
		if f then
			gen = f.Gen + 1
			parentVel = Asteroids.velAt(f, t)
		end
		fam.Frags[rock.Id] = nil
	end
	local room = Asteroids.FragmentMax - Asteroids.fragmentCount() + (if any.Fragment then 1 else 0)
	local children = Asteroids.split(rock :: any, gen, t, parentVel, push, room)
	for _, c in children do
		c.Expire = math.min(c.Expire, fam.Respawn)
		fam.Frags[c.Id] = c
		local units = Asteroids.childUnits(c.Radius)
		rocks[c.Id] = { Units = units, Max = units, Hits = 0, EmptyAt = nil }
	end
	rocks[rock.Id] = nil
	stages[rock.Id] = nil
	Asteroids.setFamily(root, fam)
	if not any.Fragment then
		pcall(function()
			world().hideRock(rock.Id)
		end)
	end
	publish(root)
	ensureLoop()
	return children
end

-- Vuelven enteros los que toca (si no hay una nave justo ahí) y se van los trozos caducados
local function sweepRocks()
	if next(Asteroids.families()) == nil then
		return
	end
	local AC = airCombat()
	local changed, back = Asteroids.sweep(Asteroids.clock(), function(root: string): boolean
		local rock = Zone.rock(root)
		if not rock then
			return true
		end
		for _, player in Players:GetPlayers() do
			local ok, st = pcall(AC.status, player)
			if ok and type(st) == "table" and typeof(st.Pos) == "Vector3" and (st.Pos - rock.Center).Magnitude < rock.Radius + 60 then
				return false
			end
		end
		return true
	end)
	for _, root in changed do
		publish(root)
	end
	for _, root in back do
		for id in table.clone(rocks) do
			if id == root or string.sub(id, 1, #root + 1) == root .. "~" then
				rocks[id] = nil
			end
		end
		stages[root] = nil
		publish(root)
		pcall(function()
			world().showRock(root)
		end)
	end
end
SpaceService._sweepRocks = sweepRocks

-- Un láser o un misil tuyo, o tu nave, ha dado en un asteroide (lo dice AirCombatService con su
-- propio disparo o su propia posición). data: Id, Pos, Ship, Power (impactos: misil), Ram (impactos de un
-- choque: rompe pero no da mineral), Push (velocidad de lo que da).
function SpaceService.onRock(player: Player, data: { [string]: any }): string?
	local id = data and data.Id
	local rock = type(id) == "string" and Zone.liveRock(id)
	if not rock then
		return nil
	end
	local ship = if typeof(data.Ship) == "Vector3" then data.Ship else rock.Center
	local t = now()
	local r = rocks[rock.Id]
	if not r then
		r = Mining.newRock(rock.Radius)
		rocks[rock.Id] = r
	end
	local at = if typeof(data.Pos) == "Vector3" then data.Pos else rock.Center
	local push = if typeof(data.Push) == "Vector3" then data.Push else nil
	local ram = tonumber(data.Ram)
	if ram then
		-- Choque de la nave: lo agrieta y lo rompe, pero nadie se lleva mineral
		local result = "Chip"
		for _ = 1, math.clamp(math.floor(ram), 0, 12) do
			result = Mining.hit(r, t)
			if result == "Empty" or result == "Dry" then
				break
			end
		end
		showStage(rock, r)
		if result == "Empty" or result == "Dry" then
			SpaceService.breakRock(rock, push)
			return "Broken"
		end
		return "Ram"
	end
	local power = math.clamp(math.floor(tonumber(data.Power) or 1), 1, 8)
	local result = "Chip"
	for _ = 1, power do
		result = Mining.hit(r, t)
		if result ~= "Chip" then
			break
		end
	end
	if result == "Chip" or result == "Dry" then
		showStage(rock, r)
		send(player, "Chip", { Pos = at, Dry = result == "Dry" })
		if result == "Dry" then
			SpaceService.breakRock(rock, push)
		end
		return result
	end
	local sp = spaceData(player)
	if not sp then
		return nil
	end
	local ps = stateOf(player)
	local ok, why = Mining.allow(ps.Rate, t, Mining.cargo(sp.Ore), ship, rock.Center, Zone.safeAt(ship))
	if not ok and why ~= "Cargo" then
		-- (no se da: demasiado rápido, desde lejos o en zona segura; el asteroide no la pierde)
		r.Units += 1
		r.EmptyAt = nil
		return why
	end
	if ok then
		sp.Ore[rock.Ore] = (tonumber(sp.Ore[rock.Ore]) or 0) + 1
		sp.Mined += 1
		-- (evento global «Tormenta de asteroides» en este campo: una unidad más si cabe)
		if SpaceEvents.mineBonus(SpaceService.eventClock(), rock.Field) and Mining.cargo(sp.Ore) < Mining.CargoMax then
			sp.Ore[rock.Ore] += 1
			sp.Mined += 1
		end
		send(player, "Mine", { Pos = at, Ore = rock.Ore, Cargo = Mining.cargo(sp.Ore), Empty = result == "Empty" })
		SpaceService.event(player, { Type = "Mine", Ore = rock.Ore, Count = 1 })
	else
		-- (bodega llena: el trozo se suelta igual, pero no cabe)
		send(player, "Mine", { Pos = at, Ore = rock.Ore, Full = true, Cargo = Mining.cargo(sp.Ore) })
	end
	showStage(rock, r)
	if result == "Empty" then
		SpaceService.breakRock(rock, push)
	end
	return if ok then result else why
end

---------------------------------------------------------------------
-- Tienda y tablón (menús: Dialog.choose en el cliente)
---------------------------------------------------------------------
local function menu(player: Player, title: string, body: string?, options: { { Text: string, Do: (() -> ())? } })
	local ps = stateOf(player)
	ps.MenuSerial += 1
	local token = ("m%d"):format(ps.MenuSerial)
	local texts, actions = {}, {}
	for i, o in options do
		texts[i] = o.Text
		actions[i] = o.Do or function() end
	end
	ps.Menu = { Token = token, Actions = actions }
	send(player, "Menu", { Token = token, Title = title, Body = body, Options = texts })
end

local function inStation(player: Player, stationId: string): boolean
	local station = Stations.ById[stationId]
	local root = rootOf(player)
	return station ~= nil and root ~= nil and Stations.inHall(station, root.Position)
end

function SpaceService.shop(player: Player, stationId: string)
	local station = Stations.ById[stationId]
	local sp = spaceData(player)
	local data = DataService.get(player)
	if not station or not sp or not data then
		return
	end
	local ps = stateOf(player)
	local maxHull = Shields.Specs.Caza.Hull + ShipCombat.bonuses(sp.Upgrades).Hull
	local hull = ps.Ship.Hull or maxHull
	local missiles = ps.Ship.Missiles or ShipWeapons.Missile.Ammo
	local money, chispas, units = Mining.sellValue(sp.Ore)
	local repair = Stations.repairCost(hull, maxHull)
	local refill = Stations.missileCost(missiles, ShipWeapons.Missile.Ammo)
	local options = {}
	if units > 0 then
		table.insert(options, { Text = ("💰 Vender %d de mineral: +$%d%s"):format(units, money, if chispas > 0 then (" · ✨ +%d"):format(chispas) else ""), Do = function()
			if not inStation(player, stationId) then
				return
			end
			local m, c, u = Mining.sellValue(sp.Ore)
			if u <= 0 then
				return
			end
			sp.Ore = {}
			reward(player, m, c)
			toast(player, "Success", ("💰 Vendido: %d de mineral por $%d%s"):format(u, m, if c > 0 then (" y ✨ %d Chispas de estrella"):format(c) else ""))
		end })
	end
	if repair > 0 then
		table.insert(options, { Text = ("🔧 Reparar el casco: $%d"):format(repair), Do = function()
			if inStation(player, stationId) and DataService.spend(player, repair) then
				ps.Ship.Hull = maxHull
				toast(player, "Success", "🔧 Casco como nuevo")
			else
				toast(player, "Error", "No tienes dinero suficiente")
			end
		end })
	end
	if refill > 0 then
		table.insert(options, { Text = ("🚀 Recargar misiles: $%d"):format(refill), Do = function()
			if inStation(player, stationId) and DataService.spend(player, refill) then
				ps.Ship.Missiles = ShipWeapons.Missile.Ammo
				toast(player, "Success", "🚀 Misiles a tope")
			else
				toast(player, "Error", "No tienes dinero suficiente")
			end
		end })
	end
	table.insert(options, { Text = "🛠 Taller de la nave (mejoras y drones)", Do = function()
		SpaceService.workshop(player, stationId)
	end })
	table.insert(options, { Text = "Cerrar" })
	local body = ("Bodega %d/%d · ✨ %d Chispas · Casco %d/%d · Misiles %d/%d"):format(units, Mining.CargoMax, sp.Chispas, math.floor(hull + 0.5), maxHull, missiles, ShipWeapons.Missile.Ammo)
	menu(player, "🛒 Tienda · " .. station.Name, body, options)
end

-- (Espacio AAA, fase 9) El taller de la estación: mejoras de la nave y drones, con Chispas de estrella y
-- dinero de Valmar (nada de Robux). Lo comprado se guarda en data.Space (Upgrades, Drones, DroneKind) y
-- vale la próxima vez que subas a la nave.
function SpaceService.buyUpgrade(player: Player, id: string): (boolean, string?)
	local sp = spaceData(player)
	if not sp or not ShipCombat.Upgrades[id] then
		return false, "Desconocido"
	end
	local level = math.floor(tonumber(sp.Upgrades[id]) or 0)
	local price = ShipCombat.upgradePrice(id, level)
	if not price then
		return false, "Maximo"
	end
	if sp.Chispas < price.Chispas then
		return false, "Chispas"
	end
	if not DataService.spend(player, price.Money) then
		return false, "Dinero"
	end
	sp.Chispas -= price.Chispas
	sp.Upgrades[id] = level + 1
	return true, nil
end

function SpaceService.buyDrone(player: Player, kind: string): (boolean, string?)
	local sp = spaceData(player)
	local def = ShipCombat.Drones[kind]
	if not sp or not def then
		return false, "Desconocido"
	end
	if sp.Drones[kind] then
		sp.DroneKind = kind -- (ya lo tienes: equiparlo)
		return true, "Equipado"
	end
	if sp.Chispas < def.Price.Chispas then
		return false, "Chispas"
	end
	if not DataService.spend(player, def.Price.Money) then
		return false, "Dinero"
	end
	sp.Chispas -= def.Price.Chispas
	sp.Drones[kind] = os.time()
	sp.DroneKind = kind
	return true, nil
end

local BUY_TEXT = { Chispas = "Te faltan Chispas de estrella", Dinero = "No tienes dinero suficiente", Maximo = "Ya está al máximo" }

function SpaceService.workshop(player: Player, stationId: string)
	local sp = spaceData(player)
	if not sp or not Stations.ById[stationId] then
		return
	end
	local options = {}
	for _, id in ShipCombat.UpgradeOrder do
		local u = ShipCombat.Upgrades[id]
		local level = math.floor(tonumber(sp.Upgrades[id]) or 0)
		local price = ShipCombat.upgradePrice(id, level)
		local text = if price
			then ("⬆ %s %d/%d (%s): $%d · ✨ %d"):format(u.Name, level, u.Levels, u.Text, price.Money, price.Chispas)
			else ("✅ %s al máximo (%d/%d)"):format(u.Name, level, u.Levels)
		table.insert(options, { Text = text, Do = function()
			if not inStation(player, stationId) then
				return
			end
			local ok, why = SpaceService.buyUpgrade(player, id)
			toast(player, if ok then "Success" else "Error", if ok then ("🛠 %s mejorado: se nota al subir a la nave"):format(u.Name) else (BUY_TEXT[why or ""] or "No se puede"))
		end })
	end
	for _, kind in ShipCombat.DroneOrder do
		local def = ShipCombat.Drones[kind]
		local text = if sp.DroneKind == kind then ("🛰 %s (equipado)"):format(def.Name)
			elseif sp.Drones[kind] then ("🛰 Equipar %s"):format(def.Name)
			else ("🔓 %s: $%d · ✨ %d"):format(def.Name, def.Price.Money, def.Price.Chispas)
		table.insert(options, { Text = text, Do = function()
			if not inStation(player, stationId) then
				return
			end
			local ok, why = SpaceService.buyDrone(player, kind)
			toast(player, if ok then "Success" else "Error", if ok then ("🛰 %s listo: ranura 8 de la nave"):format(def.Name) else (BUY_TEXT[why or ""] or "No se puede"))
		end })
	end
	table.insert(options, { Text = "Cerrar" })
	menu(player, "🛠 Taller de la nave", ("✨ %d Chispas · se paga con Chispas de estrella y dinero de Valmar"):format(sp.Chispas), options)
end

-- Lo que lleva tu nave (mejoras y drones) al subir (AirCombatService.LoadoutProvider)
function SpaceService.loadoutFor(player: Player): { [string]: any }?
	local sp = spaceData(player)
	if not sp then
		return nil
	end
	return { Upgrades = sp.Upgrades, Drones = sp.Drones, DroneKind = sp.DroneKind }
end

-- Pulso del escáner (modo exploración, dron explorador): lo que descubre a `radius` de `at`
function SpaceService.scanFor(player: Player, at: Vector3, radius: number): { string }
	local sp = spaceData(player)
	if not sp then
		return {}
	end
	local out = {}
	for _, poi in NavInfo.pois() do
		if not sp.Found[poi.Id] and (at - poi.Center).Magnitude <= radius + poi.Radius then
			sp.Found[poi.Id] = os.time()
			table.insert(out, poi.Name)
		end
	end
	if #out > 0 then
		toast(player, "Success", ("📡 Escáner: %s descubierto. Ya puedes ir con el salto cuántico (X)."):format(table.concat(out, ", ")))
	end
	return out
end

function SpaceService.missionBoard(player: Player, stationId: string)
	local station = Stations.ById[stationId]
	local sp = spaceData(player)
	if not station or not sp then
		return
	end
	local options = {}
	for _, def in Missions.List do
		local st = sp.Missions[def.Id]
		if type(st) == "table" then
			table.insert(options, { Text = ("✖ Dejar «%s» (%d/%d)"):format(def.Title, tonumber(st.P) or 0, def.Count), Do = function()
				Missions.abandon(sp.Missions, def.Id)
				toast(player, "Info", ("Has dejado «%s»"):format(def.Title))
			end })
		elseif Missions.canAccept(sp.Missions, def.Id, stationId) then
			table.insert(options, { Text = ("✅ %s · $%d · ✨ %d"):format(def.Title, def.Money, def.Chispas), Do = function()
				if Missions.accept(sp.Missions, def.Id, stationId, os.time()) then
					toast(player, "Success", ("📋 %s: %s"):format(def.Title, def.Text))
				else
					toast(player, "Info", ("Como mucho %d misiones a la vez"):format(Missions.MaxActive))
				end
			end })
		end
	end
	table.insert(options, { Text = "Cerrar" })
	menu(player, "📋 Tablón · " .. station.Name, ("Misiones a la vez: %d/%d · se pueden repetir"):format(Missions.activeCount(sp.Missions), Missions.MaxActive), options)
end

local function onMenu(player: Player, token: any, index: any)
	local ps = stateOf(player)
	local m = ps.Menu
	if not m or token ~= m.Token or type(index) ~= "number" then
		return
	end
	ps.Menu = nil
	local fn = m.Actions[math.floor(index)]
	if fn then
		fn()
	end
end

---------------------------------------------------------------------
-- Los planetas (estrellas del fondo)
---------------------------------------------------------------------
function SpaceService.registerPlanet(id: string, dest: { [string]: any }?)
	id = Planets.canonical(id) or id -- (los episodios con el nombre viejo siguen valiendo)
	Planets.setDestination(id, dest)
end

-- Estado de un planeta para este jugador ("Ready", "Soon", "Locked", "Order") y el que falta antes
function SpaceService.planetStatus(player: Player, id: string): (string, string?)
	local sp = spaceData(player)
	local status, need = Planets.status(id, {
		SagaDone = Access.sagaDone(DataService.get(player)),
		Tester = isTester(player),
		Done = sp and sp.Planets or {},
	})
	local dest = Planets.destination(id)
	if status == "Ready" and dest and type(dest.Available) == "function" and not dest.Available(player) then
		status = "Soon"
	end
	return status, need
end

function SpaceService.planet(player: Player, id: any): string?
	if type(id) == "string" then
		id = Planets.canonical(id)
	end
	if type(id) ~= "string" or not Planets.ById[id] then
		return nil
	end
	local status, need = SpaceService.planetStatus(player, id)
	local dest = Planets.destination(id)
	send(player, "Planet", { Id = id, Status = status, Text = Planets.message(id, status, need) })
	if status == "Ready" and dest and type(dest.Travel) == "function" then
		dip(player)
		task.spawn(dest.Travel, player)
	end
	return status
end

---------------------------------------------------------------------
-- Panel de la nave (línea del objetivo) y patrullas
---------------------------------------------------------------------
objectiveFor = function(player: Player): () -> string?
	return function(): string?
		local st = airCombat().status(player)
		local sp = spaceData(player)
		if not st or not sp then
			return nil
		end
		local parts = {}
		local layer = Layers.layerAt(st.Pos.Y)
		local station = Stations.safeAt(st.Pos)
		local sector = Zone.sectorAt(st.Pos)
		local field = Zone.fieldAt(st.Pos)
		if station then
			table.insert(parts, ("🛡️ Zona segura · %s"):format(station.Name))
			if Stations.dockAt(st.Pos) then
				table.insert(parts, "pulsa ATRACAR")
			end
		elseif sector then
			table.insert(parts, ("⚠ %s"):format(sector.Name))
		elseif field then
			table.insert(parts, ("⛏ %s"):format(field.Name))
		else
			table.insert(parts, ("%s · %d m"):format(Layers.Names[layer] or layer, Layers.meters(st.Pos.Y)))
		end
		table.insert(parts, Mining.cargoText(sp.Ore))
		table.insert(parts, ("✨ %d"):format(sp.Chispas))
		local m = Missions.summary(sp.Missions)
		if m ~= "" then
			table.insert(parts, m)
		end
		return table.concat(parts, " · ")
	end
end

local function discover(player: Player, pos: Vector3)
	local sp = spaceData(player)
	if not sp then
		return
	end
	for _, poi in NavInfo.discoverAt(pos, sp.Found) do
		sp.Found[poi.Id] = os.time()
		toast(player, "Success", ("📡 Descubierto: %s. Ya puedes ir con el salto cuántico (X)."):format(poi.Name))
	end
end
SpaceService._discover = discover

local function patrol(player: Player, t: number)
	local AC = airCombat()
	local st = AC.status(player)
	if not st then
		return
	end
	if not st.Down then
		discover(player, st.Pos)
	end
	local list = AC.enemyList(player)
	for _, e in list do
		if (e.Pos - st.Pos).Magnitude > SpaceService.DespawnDistance then
			AC.dropEnemy(player, e.Id)
		end
	end
	if st.Down or st.Safe then
		return
	end
	local sector = Zone.sectorAt(st.Pos)
	local ps = stateOf(player)
	if not sector or t < ps.NextSpawn then
		return
	end
	list = AC.enemyList(player)
	local room = sector.Max - #list
	if room <= 0 then
		return
	end
	local sp = spaceData(player)
	local level = sector.Level + math.min(4, math.floor(((sp and sp.Kills) or 0) / 20))
	local group = SpaceService.patrolGroup(sector, level, room)
	local count = #group
	if count == 0 then
		return
	end
	local ring = Waves.ring(count, st.Pos + st.Look * 200, SpaceService.SpawnDistance, math.floor(t))
	local scale = Waves.scale(level, "Normal")
	local spawned = 0
	for i, kind in group do
		local p = ring[i]
		p = Vector3.new(p.X, math.max(p.Y, Layers.AIMinY + 120), p.Z)
		if not Zone.safeAt(p) and AC.spawnEnemy(player, kind, p, scale) then
			spawned += 1
		end
	end
	ps.NextSpawn = t + SpaceService.SpawnCooldown
	if spawned > 0 then
		toast(player, "Info", ("⚠ ¡Patrulla enemiga en el %s! (%d)"):format(sector.Name, spawned))
	end
end

-- Qué sale en una patrulla (puro: test-space)
function SpaceService.patrolGroup(sector: Zone.Sector, level: number, room: number): { string }
	local out = {}
	local drones = math.min(2 + math.floor(level / 2), 6)
	local cazas = if sector.Cazas then (if level >= 4 then 2 else 1) else 0
	for _ = 1, cazas do
		table.insert(out, "Caza")
	end
	for _ = 1, drones do
		table.insert(out, "Dron")
	end
	while #out > room do
		table.remove(out)
	end
	return out
end

local function tick()
	local t = now()
	local AC = airCombat()
	local anyone = false
	for _, player in Players:GetPlayers() do
		-- (andando en una estación: si ya no está en el espacio —ha muerto, se ha reiniciado, la historia
		-- o el móvil le han llevado a Valmar—, deja de estar en la estación; si no, SpaceReturn se quedaba
		-- puesto y al salir del juego le guardaba en el puerto espacial en vez de donde estaba)
		local ps = states[player]
		if ps and ps.Station and AC.world(player) == nil then
			local root = rootOf(player)
			if root and not Layers.inSpace(root.Position) then
				setStation(player, nil)
			else
				anyone = true
			end
		end
		if AC.world(player) == "Cosmos" then
			anyone = true
			local ok, err = pcall(patrol, player, t)
			if not ok then
				warn("[SpaceService] " .. tostring(err))
			end
		end
	end
	-- Asteroides rotos: los trozos caducan y el asteroide vuelve entero
	local okSweep, errSweep = pcall(sweepRocks)
	if not okSweep then
		warn("[SpaceService] " .. tostring(errSweep))
	end
	if not anyone and next(Asteroids.families()) == nil and loop then
		loop:Disconnect()
		loop = nil
	end
end
SpaceService._tick = tick

ensureLoop = function()
	if loop then
		return
	end
	acc = 0
	loop = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= SpaceService.TickSeconds then
			acc = 0
			tick()
		end
	end)
end

---------------------------------------------------------------------
-- Arranque: el puerto, el portal de la playa y el mapa
---------------------------------------------------------------------
-- El primer sitio libre de la playa para el portal (suelo de arena o hierba y nada encima)
function SpaceService.findBeachSpot(): CFrame?
	-- (cada sitio de la lista y, si no vale, alrededor: anillos de 45 y 90 studs)
	local tries = {}
	for _, ring in { 0, 45, 90 } do
		for _, xz in Access.BeachSpots do
			if ring == 0 then
				table.insert(tries, xz)
			else
				for k = 0, 7 do
					local a = k / 8 * math.pi * 2
					table.insert(tries, { xz[1] + math.cos(a) * ring, xz[2] + math.sin(a) * ring })
				end
			end
		end
	end
	for _, xz in tries do
		local ok, cf = pcall(function()
			local params = RaycastParams.new()
			params.IgnoreWater = false
			local hit = workspace:Raycast(Vector3.new(xz[1], 400, xz[2]), Vector3.new(0, -500, 0), params)
			if not hit or not hit.Instance:IsA("Terrain") or hit.Material == Enum.Material.Water or hit.Position.Y < -0.5 or hit.Position.Y > 60 then
				return nil
			end
			local lookSea = Access.Port - hit.Position
			local cf0 = Access.face(hit.Position, Vector3.new(lookSea.X, 0, lookSea.Z))
			local overlap = OverlapParams.new()
			local parts = workspace:GetPartBoundsInBox(cf0 * CFrame.new(0, Access.PortalClear.Y / 2 + 0.6, 0), Access.PortalClear, overlap)
			if #parts > 0 then
				return nil
			end
			return cf0
		end)
		if ok and cf then
			return cf
		end
	end
	return nil
end

local function publishLandmark(kind: string, pos: Vector3)
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks")
	if not folder or folder:FindFirstChild(kind .. "_Space") then
		return
	end
	local config = Instance.new("Configuration")
	config.Name = kind .. "_Space"
	config:SetAttribute("Kind", kind)
	config:SetAttribute("Position", Vector3.new(pos.X, 0, pos.Z))
	config:SetAttribute("District", "")
	config.Parent = folder
end

local function setupValmar()
	local W = world()
	local _, prompts = W.buildPort()
	wire(prompts.Board, function(player)
		SpaceService.board(player, nil)
	end)
	wire(prompts.PortalStation, function(player)
		SpaceService.toStation(player, "Alba")
	end)
	wire(prompts.PortalBeach, function(player)
		SpaceService.toBeach(player)
	end)
	local spot = SpaceService.findBeachSpot()
	if spot then
		beachCF = spot
		local _, p = W.buildBeachPortal(spot)
		wire(p, function(player)
			SpaceService.toPort(player)
		end)
	else
		warn("[SpaceService] No hay sitio libre en la playa para el portal del puerto espacial (se llega con el modo pruebas)")
	end
	-- En el mapa (después de que WorldService publique los suyos: los vuelve a poner si los borra)
	task.spawn(function()
		for _ = 1, 30 do
			publishLandmark("PuertoEspacial", Access.Port)
			if beachCF then
				publishLandmark("PortalPuertoEspacial", beachCF.Position)
			end
			task.wait(10)
		end
	end)
end

local function onRemote(player: Player, action: any, a: any, b: any)
	local ps = stateOf(player)
	local t = now()
	if action ~= "Menu" and t - ps.LastAction < SpaceService.ActionGap then
		return
	end
	ps.LastAction = t
	if action == "Home" then
		SpaceService.home(player)
	elseif action == "Dock" then
		SpaceService.dock(player)
	elseif action == "Planet" then
		SpaceService.planet(player, a)
	elseif action == "Menu" then
		onMenu(player, a, b)
	end
end

function SpaceService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local existing = remotes:FindFirstChild("Space") :: RemoteEvent?
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = "Space"
		created.Parent = remotes
		existing = created
	end
	remote = existing
	;(existing :: RemoteEvent).OnServerEvent:Connect(function(player, action, a, b)
		local ok, err = pcall(onRemote, player, action, a, b)
		if not ok then
			warn("[SpaceService] " .. tostring(err))
		end
	end)
	airCombat().setProviders(SpaceService.navFor, SpaceService.infoFor)
	airCombat().ScanProvider = SpaceService.scanFor
	airCombat().LoadoutProvider = SpaceService.loadoutFor
	airCombat().onEvent(function(player: Player, name: string, data: any)
		if airCombat().world(player) ~= "Cosmos" and name ~= "Exit" then
			return
		end
		if name == "Kill" then
			onKill(player, data)
		elseif name == "Rock" then
			SpaceService.onRock(player, data)
		elseif name == "Down" then
			SpaceService.event(player, { Type = "Down" })
		elseif name == "Exit" and type(data) == "table" and (data.World == "Cosmos" or data.World == "Planet") then
			local ps = stateOf(player)
			if data.Down then
				ps.Ship = {} -- (derribada: la próxima es nueva)
			elseif not ps.Docking then
				-- (bajarse o volver a Valmar: la nave se queda como estaba en el hangar)
				ps.Ship = { Hull = data.Hull, Missiles = data.Missiles }
			end
			if data.Reason == "teleport" or data.Reason == "character" then
				-- (se lo ha llevado otro sistema o ha reaparecido: ya no está ni en el planeta ni en una
				-- estación; si no, SpaceReturn le dejaba guardado en el puerto espacial)
				pcall(function()
					service("PlanetService").leave(player)
				end)
				setStation(player, nil)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	-- El puerto y el portal de la playa, cuando la ciudad ya está hecha
	task.spawn(function()
		local waited = 0
		while not workspace:FindFirstChild("Town") and waited < 60 do
			task.wait(1)
			waited += 1
		end
		task.wait(2)
		local ok, err = pcall(setupValmar)
		if not ok then
			warn("[SpaceService] puerto espacial: " .. tostring(err))
		end
	end)
end

-- (Espacio AAA) Para el salto cuántico: lo descubierto, las misiones y si se puede bajar a cada planeta
function SpaceService.navFor(player: Player): { [string]: any }?
	local sp = spaceData(player)
	if not sp then
		return nil
	end
	return {
		Found = sp.Found,
		Missions = sp.Missions,
		PlanetStatus = function(id: string): string
			return (SpaceService.planetStatus(player, id))
		end,
	}
end

-- Para el HUD de la nave («Nav», 1 vez por segundo): Chispas, bodega, misiones del tablón y eventos
function SpaceService.infoFor(player: Player): { [string]: any }?
	local sp = spaceData(player)
	if not sp then
		return nil
	end
	local missions = {}
	for _, m in NavInfo.missionTargets(sp.Missions) do
		table.insert(missions, { Id = m.Id, Title = m.Title, Progress = m.Progress, Target = m.Target, TargetName = m.TargetName })
	end
	local event: string? = nil
	local st = airCombat().status(player)
	if st then
		local sector = Zone.sectorAt(st.Pos)
		local enemies = #airCombat().enemyList(player)
		if enemies > 0 then
			event = ("⚠ %d enemigos cerca%s"):format(enemies, if sector then " · " .. sector.Name else "")
		elseif sector then
			event = ("⚠ Patrullas en el %s (nivel %d)"):format(sector.Name, sector.Level)
		elseif st.Safe then
			event = "🛡 Zona segura de la estación"
		end
	end
	-- (Invasión de la Grieta: el evento global manda en la fila EVENTO del HUD de la nave)
	local okInv, invText = pcall(function()
		local Invasion = require(script.Parent.InvasionService) :: any
		return Invasion.shipEventText and Invasion.shipEventText(player) or nil
	end)
	if okInv and type(invText) == "string" then
		event = invText
	end
	local found = 0
	for _ in sp.Found do
		found += 1
	end
	return {
		Chispas = sp.Chispas,
		Cargo = Mining.cargoText(sp.Ore),
		Missions = missions,
		Event = event,
		Found = found,
		CargoUnits = Mining.cargo(sp.Ore),
		CargoMax = Mining.CargoMax,
		Crystals = math.floor(tonumber(sp.Ore.Cristal) or 0),
	}
end

-- (pruebas)
SpaceService._states = states
SpaceService._rocks = rocks
SpaceService._onKill = onKill
SpaceService._onMenu = onMenu
SpaceService._objectiveFor = function(player: Player)
	return objectiveFor(player)
end
SpaceService.objectiveFor = SpaceService._objectiveFor
SpaceService.onExitRequest = function(player: Player)
	onExitRequest(player)
end
-- Casco y misiles de la nave guardada (al bajarse en un planeta o atracar)
function SpaceService.shipState(player: Player): { Hull: number?, Missiles: number? }
	return stateOf(player).Ship
end

return SpaceService
