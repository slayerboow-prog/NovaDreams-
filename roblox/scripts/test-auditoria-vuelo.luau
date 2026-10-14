-- Auditoría de beta tester (docs/auditoria/vuelo-espacio-mar-invasion.md): escenarios de los fallos
-- encontrados en los aviones, la nave del espacio y la estación, con Lune (sin Roblox). Cada bloque
-- reproduce un fallo que las pruebas de siempre no veían (llamaban a las funciones por dentro y no por
-- el remoto, o no probaban el cambio de un sistema a otro).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-auditoria-vuelo.luau
--
-- Comprueba:
--   * AirCombatService: TODO lo que manda el cliente de la nave (Controllers/AirCombatClient) llega a
--     los sistemas (ShipSystems): sobrecarga, camuflaje, bengalas, dron, modo de vuelo y escáner
--     también (antes el remoto solo dejaba pasar los de las fases 4 a 6 y esos botones no hacían nada).
--   * AirCombatService: si otro sistema se lleva al piloto (Teleporting: la historia, un interior…), el
--     vuelo se acaba sin devolverle a la nave ni al puerto (antes volvía a sentarle en la nave).
--   * SpaceService: al salir de la estación sin el portal (morir, reiniciar, la historia), deja de estar
--     «en la estación» (SpaceReturn ya no le guarda en el puerto espacial).
--   * AviationService: si el piloto se va del juego en pleno vuelo, los pasajeros bajan en el hangar,
--     no en el cielo; y mandar «Touchdown» con el avión parado no suma aterrizajes.

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local check = L.check

local function signal()
	local handlers = {}
	return {
		Connect = function(_, fn)
			table.insert(handlers, fn)
			return { Disconnect = function() end }
		end,
		Fire = function(_, ...)
			for _, fn in table.clone(handlers) do
				fn(...)
			end
		end,
		handlers = handlers,
	}
end

local function fakeRemote(name: string): any
	local r = { Name = name, OnServerEvent = signal(), sent = {} }
	function r:FireClient(_player, kind, payload)
		table.insert(self.sent, { kind, payload })
	end
	function r:FireAllClients(kind, payload)
		table.insert(self.sent, { kind, payload })
	end
	return r
end

local remotes = {
	Notify = fakeRemote("Notify"),
	AirCombat = fakeRemote("AirCombat"),
	Space = fakeRemote("Space"),
	Aviation = fakeRemote("Aviation"),
}
remotes.FindFirstChild = function(self, name)
	return rawget(self, name)
end
L.services.ReplicatedStorage.Remotes = remotes

local players = {}
local removing = signal()
L.services.Players = {
	PlayerRemoving = removing,
	PlayerAdded = signal(),
	GetPlayers = function()
		return players
	end,
}
L.services.RunService = {
	Heartbeat = signal(),
	IsStudio = function()
		return false
	end,
}
L.services.CollectionService = {
	GetTagged = function()
		return {}
	end,
	GetInstanceAddedSignal = function()
		return signal()
	end,
	AddTag = function() end,
}
L.services.Debris = { AddItem = function() end }

-- Un personaje de mentira: raíz, humanoide (asiento) y PivotTo
local function makePlayer(name: string, id: number, pos: any): any
	local p = L.player(name, id)
	local root = { Name = "HumanoidRootPart", CFrame = CFrame.new(pos), AssemblyLinearVelocity = Vector3.zero, Parent = true }
	setmetatable(root, { __index = function(t, k)
		if k == "Position" then
			return rawget(t, "CFrame").Position
		end
		return nil
	end })
	local humanoid = { Health = 100, SeatPart = nil, Sit = false, Parent = true }
	function humanoid:UnequipTools() end
	local character = { Name = name }
	function character:FindFirstChild(n)
		return if n == "HumanoidRootPart" then root else nil
	end
	function character:FindFirstChildOfClass(c)
		return if c == "Humanoid" then humanoid else nil
	end
	function character:PivotTo(cf)
		root.CFrame = cf
	end
	p.Character = character
	p.Root = root
	p.Humanoid = humanoid
	table.insert(players, p)
	return p
end

---------------------------------------------------------------------
print("\n🛰️ Nave: todo lo que pide el cliente llega a los sistemas (remoto AirCombat)")
---------------------------------------------------------------------
local realSystems = L.load("src/server/Services/ShipSystems")
local requests = {}
L.mock("src/server/Services/ShipSystems", setmetatable({
	request = function(s, ctx, action, arg)
		table.insert(requests, action)
		return realSystems.request(s, ctx, action, arg)
	end,
}, { __index = realSystems }))
L.mock("src/server/Services/TesterService", { isTester = function()
	return true
end, bypass = function()
	return false
end })
local AC = L.load("src/server/Services/AirCombatService")
AC.init()
do
	local pilot = makePlayer("Piloto", 701, Vector3.new(0, 5000, 0))
	local s = { Player = pilot, Down = false, Root = pilot.Root, Enemies = {}, Hull = { Hull = 100, MaxHull = 100, Shield = 50, MaxShield = 50 } }
	realSystems.attach(s)
	AC._sessions[pilot] = s
	-- (lo que manda Controllers/AirCombatClient con fire(...) a los sistemas de la nave)
	local fromClient = { "Dodge", "Hyper", "HyperStop", "QuantumList", "Quantum", "QuantumCancel", "Weapon", "Reload", "Overload", "Cloak", "Drone", "Flares", "Mode", "Scan" }
	local missing = {}
	for _, action in fromClient do
		table.clear(requests)
		pcall(function()
			remotes.AirCombat.OnServerEvent:Fire(pilot, action, if action == "Mode" then "Explore" else nil)
		end)
		if requests[1] ~= action then
			table.insert(missing, action)
		end
		s.ReqAt = nil -- (sin esperar el ritmo mínimo entre peticiones)
	end
	check(#missing == 0, "cada botón de la nave llega a ShipSystems" .. (if #missing > 0 then " (no llegan: " .. table.concat(missing, ", ") .. ")" else ""))
	table.clear(requests)
	remotes.AirCombat.OnServerEvent:Fire(pilot, "Mode", "Explore")
	check(s.FlightMode == "Explore", "el modo EXPLORACIÓN también cuenta en el servidor (sin misiles, media cadencia)")
	remotes.AirCombat.OnServerEvent:Fire(pilot, "Teletransporte", Vector3.new(1, 2, 3))
	check(#requests == 1, "una acción inventada no llega a ningún sitio")
	-- Un cliente trucado que manda cientos de «Pose» por segundo: el servidor solo mira las primeras
	local Zone = L.load("src/shared/Cosmos/Zone")
	local cf = CFrame.new(0, 5200, 0)
	local rootCF = { CFrame = cf }
	setmetatable(rootCF, { __index = function(t, k)
		return if k == "Position" then rawget(t, "CFrame").Position else nil
	end })
	s.Root, s.Geo, s.LastPos, s.LastGood, s.PoseAt, s.Poses = rootCF, Zone, cf.Position, cf, os.clock(), 0
	for _ = 1, 300 do
		AC._pose(s, cf)
	end
	check(s.Poses > 0 and s.Poses <= AC.MaxPosesPerSecond, ("300 posiciones en un segundo: solo cuenta %d (tope %d)"):format(s.Poses, AC.MaxPosesPerSecond))
	AC._sessions[pilot] = nil
end

---------------------------------------------------------------------
print("\n🌀 Nave: otro sistema se lleva al piloto (Teleporting)")
---------------------------------------------------------------------
do
	local pilot = makePlayer("Viajero", 702, Vector3.new(0, 5000, 0))
	local destroyed = 0
	local function thing()
		return { Destroy = function()
			destroyed += 1
		end }
	end
	local seat = { Occupant = nil, Position = Vector3.new(0, 5000, 0) }
	local sat = 0
	function seat:Sit()
		sat += 1
	end
	local exits = {}
	AC.onEvent(function(_, name, data)
		if name == "Exit" then
			table.insert(exits, data)
		end
	end)
	local s = {
		Player = pilot, Seat = seat, Humanoid = pilot.Humanoid, Root = { Position = seat.Position }, Ship = thing(), Folder = thing(),
		Enemies = {}, Conns = {}, Exiting = false, Return = CFrame.new(100, 50, 100), Spawner = { Wave = 0 },
		Hull = { Hull = 80, MaxHull = 100 }, Gun = { Missiles = 3 }, Score = 0, Kills = 0, World = "Cosmos", Down = false,
	}
	AC._sessions[pilot] = s
	-- La historia (SceneService.teleportTo) pone Teleporting, le levanta del asiento y le lleva a la calle
	pilot:SetAttribute("Teleporting", true)
	pilot.Root.CFrame = CFrame.new(300, 4, 300)
	AC._seatChanged(s)
	check(AC._sessions[pilot] == nil and sat == 0, "se acaba el vuelo (no vuelve a sentarle en la nave)")
	check((pilot.Root.Position - Vector3.new(300, 4, 300)).Magnitude < 1, "y se queda donde le han llevado (no le devuelve al puerto)")
	check(exits[#exits] and exits[#exits].Reason == "teleport" and destroyed == 2, "la nave y sus enemigos se recogen; SpaceService se entera (motivo «teleport»)")
	pilot:SetAttribute("Teleporting", nil)
	-- Señal que llega tarde (señales diferidas): ya está lejos del asiento
	local s2 = table.clone(s)
	s2.Exiting, s2.Conns = false, {}
	AC._sessions[pilot] = s2
	AC._seatChanged(s2)
	check(AC._sessions[pilot] == nil and sat == 0, "también si el aviso llega cuando ya está lejos de la nave")
	-- Saltar del asiento (sin que nadie se lo lleve): vuelve a sentarse, como siempre
	local s3 = table.clone(s)
	s3.Exiting, s3.Conns = false, {}
	pilot.Root.CFrame = CFrame.new(seat.Position)
	AC._sessions[pilot] = s3
	AC._seatChanged(s3)
	check(AC._sessions[pilot] == s3, "si solo ha saltado del asiento, sigue en la nave")
	AC._sessions[pilot] = nil
end

---------------------------------------------------------------------
print("\n🛰 Estación: dejar de estar en ella sin usar el portal")
---------------------------------------------------------------------
do
	local data = { Money = 0, Story = { Completed = { Saga_24_Final = 1 } }, Space = { Chispas = 0, Ore = {}, Missions = {}, Mined = 0, Kills = 0, Done = 0, Planets = {} } }
	L.mock("src/server/Services/DataService", {
		get = function()
			return data
		end,
		addMoney = function()
			return true
		end,
		spend = function()
			return true
		end,
	})
	L.mock("src/server/Services/SceneService", { dip = function() end })
	local planetLeft = 0
	L.mock("src/server/Services/PlanetService", { leave = function()
		planetLeft += 1
	end })
	local acWorld = nil
	local exitHook = nil
	L.mock("src/server/Services/AirCombatService", {
		inArena = function()
			return false
		end,
		world = function()
			return acWorld
		end,
		status = function()
			return nil
		end,
		setProviders = function() end,
		onEvent = function(fn)
			exitHook = fn
		end,
		enemyList = function()
			return {}
		end,
	})
	L.reset("src/server/Services/SpaceService")
	L.mock("src/server/World/SpaceWorld", {
		space = function()
			return true
		end,
		stationPrompts = function()
			return {}
		end,
	})
	local Stations = L.load("src/shared/Cosmos/Stations")
	local Access = L.load("src/shared/Cosmos/Access")
	local Space = L.load("src/server/Services/SpaceService")
	Space.init()
	local walker = makePlayer("Paseante", 703, Vector3.new(0, 5, 0))
	check(Space.toStation(walker, "Alba") and walker:GetAttribute("SpaceStation") == "Alba" and walker:GetAttribute("SpaceReturn") ~= nil, "por el portal a la Estación Alba: «en la estación» (si sale del juego, al puerto)")
	Space._tick()
	check(walker:GetAttribute("SpaceStation") == "Alba", "mientras sigue allí, sigue en la estación")
	-- Se cae, se reinicia o la historia le lleva a Valmar: reaparece en la ciudad
	walker.Root.CFrame = CFrame.new(40, 5, 40)
	Space._tick()
	check(walker:GetAttribute("SpaceStation") == nil and walker:GetAttribute("SpaceReturn") == nil, "de vuelta en Valmar sin el portal: ya no está en la estación (PositionService guarda dónde está de verdad)")
	-- La nave se acaba porque otro sistema se lo lleva: fuera del planeta y de la estación
	walker:SetAttribute("SpaceReturn", Access.arrival().Position)
	walker:SetAttribute("Planeta", "Tefra")
	if exitHook then
		exitHook(walker, "Exit", { World = "Planet", Reason = "teleport", Hull = 50, Missiles = 1 })
	end
	check(planetLeft >= 1 and walker:GetAttribute("SpaceReturn") == nil, "la nave se acaba por un teleport: PlanetService.leave y sin SpaceReturn")
	local _ = Stations
end

---------------------------------------------------------------------
print("\n✈️ Avioneta: el piloto se va en pleno vuelo con un pasajero")
---------------------------------------------------------------------
local Airport = L.load("src/shared/Airport")
local function hitPart()
	local p = roblox.Instance.new("Part")
	p.CanCollide = true
	return p
end
local groundPart = hitPart()
-- El suelo del aeropuerto está a Airport.GROUND; en el cielo los rayos no llegan a nada
L.globals.workspace = {
	Raycast = function(_, origin, dir)
		local bottom = origin + dir
		if math.min(origin.Y, bottom.Y) <= Airport.GROUND and origin.Y >= Airport.GROUND then
			return { Position = Vector3.new(origin.X, Airport.GROUND, origin.Z), Instance = groundPart, Material = roblox.Enum.Material.Concrete }
		end
		return nil
	end,
	FindFirstChild = function()
		return nil
	end,
}
L.globals.RaycastParams = { new = function()
	return { FilterDescendantsInstances = {} }
end }
L.mock("src/server/World/Builder", {})
L.mock("src/server/World/Kit/Airport", {})
L.mock("src/server/LifeStory/StoryEvents", { emit = function() end })
local aviationData: { [any]: any } = {}
L.mock("src/server/Services/DataService", {
	get = function(p)
		aviationData[p] = aviationData[p] or { Licenses = { Piloto = true }, Aviation = { Theory = true, Landings = 0 } }
		return aviationData[p]
	end,
	spend = function()
		return true
	end,
	addMoney = function() end,
})
L.mock("src/server/Services/TesterService", { bypass = function()
	return false
end, isTester = function()
	return false
end })
L.reset("src/server/Services/AviationService")
local AV = L.load("src/server/Services/AviationService")
AV.init()

local function fakePlane(spec: any, at: any): any
	local attrs = {}
	local root = { Anchored = true, AssemblyLinearVelocity = Vector3.zero, AssemblyAngularVelocity = Vector3.zero, CFrame = at }
	setmetatable(root, { __index = function(t, k)
		if k == "Position" then
			return rawget(t, "CFrame").Position
		end
		return nil
	end })
	function root:SetNetworkOwner() end
	function root:GetNetworkOwner()
		return nil
	end
	local board = { Position = at.Position + Vector3.new(4, 0, 0) }
	local model = {}
	function model:SetAttribute(k, v)
		attrs[k] = v
	end
	function model:GetAttribute(k)
		return attrs[k]
	end
	function model:GetDescendants()
		return {}
	end
	function model:PivotTo(cf)
		root.CFrame = cf
		board.Position = cf.Position + Vector3.new(4, 0, 0)
	end
	local pilotSeat = { Occupant = nil, Position = at.Position }
	function pilotSeat:FindFirstChild()
		return nil
	end
	local seat = { Occupant = nil, Position = at.Position }
	function seat:FindFirstChild()
		return nil
	end
	function seat:Sit() end
	return {
		Spec = spec, Model = model, Root = root, PilotSeat = pilotSeat, Seats = { seat }, Board = board,
		Pilot = nil, Renter = nil, Lesson = nil, Passengers = {}, Airborne = false, Gear = true, Flaps = 0, Speed = 0,
		Health = 100, DownUntil = 0, Collide = {}, Pilots = 0, Released = true,
	}
end

local spec = nil
for _, p in Airport.PilotPlanes do
	if p.Kind == "Avioneta" then
		spec = p
		break
	end
end
do
	local home = Airport.rootCFrame(spec.Kind, spec.Pose)
	local sky = CFrame.new(home.Position + Vector3.new(600, 300, 200))
	local plane = fakePlane(spec, sky)
	AV._planes[spec.Id] = plane
	local pilot = makePlayer("Aviador", 801, sky.Position)
	local guest = makePlayer("Pasajera", 802, sky.Position)
	plane.Pilot, plane.Renter, plane.Airborne = pilot, pilot, true
	AV._piloting[pilot] = plane
	plane.Passengers[guest] = plane.Seats[1]
	AV._riding[guest] = plane
	guest.Humanoid.SeatPart = plane.Seats[1]
	removing:Fire(pilot)
	local gp = guest.Root.Position
	check(AV._riding[guest] == nil, "la pasajera ya no va a bordo")
	check((Vector3.new(gp.X, 0, gp.Z) - Vector3.new(home.Position.X, 0, home.Position.Z)).Magnitude < 40 and gp.Y < Airport.GROUND + 8, ("baja junto al avión en el hangar, en el suelo (y = %.0f; antes, en el cielo donde iba el avión)"):format(gp.Y))
	AV._planes[spec.Id] = nil
end

---------------------------------------------------------------------
print("\n🛬 Avioneta: «Touchdown» sin haber volado no suma aterrizajes")
---------------------------------------------------------------------
do
	local R = Airport.Runway
	local onRunway = CFrame.new((R.X0 + R.X1) / 2, Airport.GROUND + Airport.Kinds[spec.Kind].FloorY, R.Z)
	local plane = fakePlane(spec, onRunway)
	AV._planes[spec.Id] = plane
	local pilot = makePlayer("Tramposo", 803, onRunway.Position)
	plane.Pilot = pilot
	AV._piloting[pilot] = plane
	aviationData[pilot] = { Licenses = { Piloto = true }, Aviation = { Theory = true, Landings = 0 } }
	for _ = 1, 6 do
		AV._onState(pilot, { Air = true, Speed = 0 })
		AV._onTouchdown(pilot, { Sink = 0 })
		AV._lastState[pilot] = nil
	end
	check(aviationData[pilot].Aviation.Landings == 0, ("parado en la pista: 6 «aterrizajes» de mentira no cuentan (lleva %d)"):format(aviationData[pilot].Aviation.Landings))
	-- Un vuelo de verdad: despega, el servidor le ve subir, unos segundos en el aire y aterriza en la pista
	AV._onState(pilot, { Air = true, Speed = 40 })
	plane.Root.CFrame = onRunway + Vector3.new(0, 60, 0)
	plane.LastPos = plane.Root.Position
	AV._validate(plane, 0.25)
	plane.AirSince = os.clock() - 30
	plane.Root.CFrame = onRunway
	plane.LastPos = plane.Root.Position
	AV._onTouchdown(pilot, { Sink = 0 })
	check(aviationData[pilot].Aviation.Landings == 1, "un aterrizaje suave de verdad, sí cuenta")
	AV._planes[spec.Id] = nil
	AV._piloting[pilot] = nil
end

L.finish("test-auditoria-vuelo")
