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
local Missions = require(Cosmos.Missions)
local Planets = require(Cosmos.Planets)
local Waves = require(ReplicatedStorage.Shared.AirCombat.Waves)
local ShipWeapons = require(ReplicatedStorage.Shared.AirCombat.ShipWeapons)
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
local emptied: { [string]: boolean } = {}
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
	reward(player, SpaceService.KillReward[kind] or 0, chispas)
	SpaceService.event(player, { Type = "Kill", Kind = kind })
end

-- Un láser tuyo ha dado en un asteroide (lo dice AirCombatService con su propio disparo)
function SpaceService.onRock(player: Player, data: { [string]: any }): string?
	local id = data and data.Id
	local rock = type(id) == "string" and Zone.rock(id)
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
	local result = Mining.hit(r, t)
	local at = if typeof(data.Pos) == "Vector3" then data.Pos else rock.Center
	if result == "Chip" or result == "Dry" then
		send(player, "Chip", { Pos = at, Dry = result == "Dry" })
		return result
	end
	local sp = spaceData(player)
	if not sp then
		return nil
	end
	local ps = stateOf(player)
	local ok, why = Mining.allow(ps.Rate, t, Mining.cargo(sp.Ore), ship, rock.Center, Zone.safeAt(ship))
	if not ok then
		-- (no se da: bodega llena, demasiado rápido o desde lejos; el asteroide no la pierde)
		r.Units += 1
		r.EmptyAt = nil
		if why == "Cargo" then
			send(player, "Mine", { Pos = at, Ore = rock.Ore, Full = true, Cargo = Mining.cargo(sp.Ore) })
		end
		return why
	end
	if result == "Empty" then
		emptied[rock.Id] = true
		pcall(function()
			world().setRockLit(rock.Id, false)
		end)
		ensureLoop()
	end
	sp.Ore[rock.Ore] = (tonumber(sp.Ore[rock.Ore]) or 0) + 1
	sp.Mined += 1
	send(player, "Mine", { Pos = at, Ore = rock.Ore, Cargo = Mining.cargo(sp.Ore), Empty = result == "Empty" })
	SpaceService.event(player, { Type = "Mine", Ore = rock.Ore, Count = 1 })
	return result
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
	local maxHull = Shields.Specs.Caza.Hull
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
	table.insert(options, { Text = "Cerrar" })
	local body = ("Bodega %d/%d · ✨ %d Chispas · Casco %d/%d · Misiles %d/%d"):format(units, Mining.CargoMax, sp.Chispas, math.floor(hull + 0.5), maxHull, missiles, ShipWeapons.Missile.Ammo)
	menu(player, "🛒 Tienda · " .. station.Name, body, options)
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

local function patrol(player: Player, t: number)
	local AC = airCombat()
	local st = AC.status(player)
	if not st then
		return
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
		if AC.world(player) == "Cosmos" then
			anyone = true
			local ok, err = pcall(patrol, player, t)
			if not ok then
				warn("[SpaceService] " .. tostring(err))
			end
		end
	end
	-- Asteroides vacíos que ya se han rellenado: vuelven a brillar
	for id in table.clone(emptied) do
		local r = rocks[id]
		if r and Mining.refill(r, t) then
			emptied[id] = nil
			pcall(function()
				world().setRockLit(id, true)
			end)
		elseif not r then
			emptied[id] = nil
		end
	end
	if not anyone and next(emptied) == nil and loop then
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
