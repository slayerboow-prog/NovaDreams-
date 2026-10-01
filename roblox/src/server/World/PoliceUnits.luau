-- PoliceUnits: las patrullas que salen a por un jugador buscado (WantedService decide cuántas).
--
--   * Coche patrulla: aparece por la misma calle en la que estás (lejos), llega con la sirena,
--     para cerca y bajan 2 agentes.
--   * Agente: te persigue a pie (buscando camino entre los edificios); si te alcanza, te detiene.
--     Se le puede tumbar a golpes (atributos Officer / Hp / Down, los usa CombatService).
--   * Helicóptero: vuela en círculos sobre ti con un foco. Ve desde lejos, pero no a través de un techo.
--   * Patrullas de ronda: unos pocos coches patrulla circulan por las calles cerca de los jugadores
--     aunque nadie esté buscado (sin sirena). Si ven a alguien conduciendo sin carnet (o a un menor
--     al volante), WantedService le da el «¡Alto!»: esa patrulla enciende la sirena y le sigue
--     (pullOver); cuando se para, bajan los agentes a detenerle. Paran en rojo en los semáforos (el
--     mismo ciclo que Controllers/Traffic), guardan distancia con la patrulla de delante y con quien
--     se ponga delante, y giran en las esquinas poco a poco.
-- Todo va anclado y lo mueve el servidor; las hélices y las luces las anima el cliente (WantedUI).

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Wanted = require(ReplicatedStorage.Shared.Wanted)
local TrafficSignals = require(ReplicatedStorage.Shared.TrafficSignals)
local Npc = require(script.Parent.Npc)
local Roads = require(script.Parent.Kit.Roads)
local Rides = require(script.Parent.Kit.Rides)
local PatrolRoutes = require(script.Parent.PatrolRoutes)

local PoliceUnits = {}

local V = Vector3.new
local rgb = Color3.fromRGB

type Officer = { Model: Model, Root: BasePart, Height: number, Path: { Vector3 }, PathAt: number, Car: any? }
type Car = { Model: Model, Offset: CFrame, Officers: { Officer }, Arrived: boolean, Chase: boolean?, Position: Vector3?, Look: Vector3? }
type Patrol = { Model: Model, Offset: CFrame, Index: number, From: string, T: number, Lane: number, Position: Vector3, GroundAt: number, Speed: number, Look: Vector3? }
type Heli = { Model: Model, Offset: CFrame, Angle: number, Position: Vector3, SpotAt: Vector3? }
type Force = { Cars: { Car }, Helis: { Heli }, Officers: { Officer }, Target: Vector3?, Stars: number, Folder: Folder }

local forces: { [Player]: Force } = {}
local patrols: { Patrol } = {}
local root: Folder
local patrolFolder: Folder

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function rayParams(extra: { Instance }?): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list: { Instance } = { root }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	-- (los vehículos no tapan: a quien va en coche se le ve por las ventanillas)
	-- (ni los autobuses: si no, un coche patrulla que busca el suelo junto a un autobús acababa
	-- encima de su techo)
	for _, name in { "Rides", "Buses" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(list, folder)
		end
	end
	for _, instance in extra or {} do
		table.insert(list, instance)
	end
	params.FilterDescendantsInstances = list
	params.IgnoreWater = true
	return params
end

-- ¿Es un vehículo o una persona? (no es suelo: ni el techo de un coche aparcado ni una cabeza)
local function notGround(part: Instance): Instance?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") or model.Name == "ParkedCar" or model:GetAttribute("Drivable") or model:GetAttribute("BusLine") then
			return model
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function groundAt(position: Vector3): Vector3
	local params = rayParams()
	local from, dir = position + V(0, 40, 0), V(0, -120, 0)
	local hit = workspace:Raycast(from, dir, params)
	for _ = 1, 6 do
		local skip = hit and notGround(hit.Instance)
		if not skip then
			break
		end
		local list = params.FilterDescendantsInstances
		table.insert(list, skip)
		params.FilterDescendantsInstances = list
		hit = workspace:Raycast(from, dir, params)
	end
	return if hit then hit.Position else position
end

local function playerRoot(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- La carretera más cercana: tramo, punto más cercano y dirección
local function nearestRoad(position: Vector3): (Roads.Segment?, Vector3, Vector3, number)
	local best, bestPoint, bestDir, bestDistance = nil, position, V(0, 0, -1), math.huge
	local flat = V(position.X, 0, position.Z)
	for _, segment in Roads.segments() do
		local a, b = V(segment.A.X, 0, segment.A.Z), V(segment.B.X, 0, segment.B.Z)
		local along = b - a
		local length = along.Magnitude
		if length > 1 then
			local dir = along / length
			local t = math.clamp((flat - a):Dot(dir), 0, length)
			local point = a + dir * t
			local distance = (flat - point).Magnitude
			if distance < bestDistance then
				best, bestPoint, bestDir, bestDistance = segment, point, dir, distance
			end
		end
	end
	return best, bestPoint, bestDir, bestDistance
end

---------------------------------------------------------------------
-- Agentes a pie
---------------------------------------------------------------------
local function makeOfficer(force: Force, at: Vector3, car: Car?): Officer
	local ground = groundAt(at)
	local model = Npc.create("Agente", force.Folder, CFrame.new(ground), {
		Shirt = rgb(28, 48, 110),
		Pants = rgb(24, 28, 44),
	})
	model:SetAttribute("Officer", true)
	model:SetAttribute("Hp", Wanted.OfficerHealth)
	local head = model:FindFirstChild("Head") :: BasePart?
	if head then
		-- Gorra de policía
		local cap = Instance.new("Part")
		cap.Name = "Cap"
		cap.Size = V(1.3, 0.35, 1.4)
		cap.Color = rgb(24, 34, 70)
		cap.CanCollide = false
		cap.Massless = true
		cap.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.1, -0.1)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = cap
		weld.Parent = cap
		cap.Parent = model
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local r = model.PrimaryPart :: BasePart
	local officer: Officer = { Model = model, Root = r, Height = humanoid.HipHeight + r.Size.Y / 2, Path = {}, PathAt = 0, Car = car }
	table.insert(force.Officers, officer)
	Npc.say(model, "¡Alto, policía!")
	task.delay(2.5, function()
		if model.Parent then
			Npc.say(model, nil)
		end
	end)
	return officer
end

local function officerDown(officer: Officer): boolean
	return officer.Model:GetAttribute("Down") == true or not officer.Model.Parent
end

-- Camino hasta el objetivo esquivando edificios (si no se encuentra, en línea recta)
local function repath(officer: Officer, target: Vector3)
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 6 })
	local ok = pcall(function()
		path:ComputeAsync(officer.Root.Position, target)
	end)
	local points = {}
	if ok and path.Status == Enum.PathStatus.Success then
		for i, waypoint in path:GetWaypoints() do
			if i > 1 then
				table.insert(points, waypoint.Position)
			end
		end
	end
	if #points == 0 then
		points = { groundAt(target) }
	end
	officer.Path = points
end

local function stepOfficer(officer: Officer, target: Vector3?, speed: number, dt: number)
	if officerDown(officer) or not target then
		return
	end
	local now = os.clock()
	if now - officer.PathAt > 1 then
		officer.PathAt = now
		task.spawn(repath, officer, target)
	end
	local nextPoint = officer.Path[1]
	if not nextPoint then
		return
	end
	local from = officer.Root.Position
	local goal = nextPoint + V(0, officer.Height, 0)
	local flat = V(goal.X - from.X, 0, goal.Z - from.Z)
	local distance = flat.Magnitude
	if distance < 1 then
		table.remove(officer.Path, 1)
		return
	end
	local stepLength = math.min(distance, speed * dt)
	local dir = flat / distance
	local nextPos = from + dir * stepLength
	nextPos = V(nextPos.X, from.Y + (goal.Y - from.Y) * math.min(1, stepLength / distance), nextPos.Z)
	officer.Root.CFrame = CFrame.lookAt(nextPos, nextPos + dir)
end

-- Tumbado a golpes: se queda en el suelo y se va al rato
function PoliceUnits.knockDown(model: Model)
	if model:GetAttribute("Down") then
		return
	end
	model:SetAttribute("Down", true)
	local r = model.PrimaryPart
	if r then
		r.CFrame = r.CFrame * CFrame.new(0, -1.8, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	end
	Npc.say(model, "¡Ay! Necesito refuerzos…")
	task.delay(10, function()
		model:Destroy()
	end)
end

---------------------------------------------------------------------
-- Coches patrulla
---------------------------------------------------------------------
local function anchorAll(model: Model)
	for _, part in model:GetDescendants() do
		if part:IsA("Seat") or part:IsA("VehicleSeat") then
			part.Disabled = true -- (nadie se puede subir)
		end
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
end

local function spawnCar(player: Player, force: Force)
	local r = playerRoot(player)
	if not r then
		return
	end
	local segment, point, dir = nearestRoad(r.Position)
	if not segment then
		return
	end
	-- Aparece lejos por la misma calle, por el lado donde hay más calle
	local a, b = V(segment.A.X, 0, segment.A.Z), V(segment.B.X, 0, segment.B.Z)
	local toA, toB = (point - a).Magnitude, (point - b).Magnitude
	local side = if toA > toB then -1 else 1 -- -1: viene desde A
	local room = math.max(toA, toB)
	local startDist = math.clamp(room, 30, 130)
	local width = Roads.Kinds[segment.Kind] and Roads.Kinds[segment.Kind].Road or 22
	local travel = dir * (-side) -- dirección en la que avanza el coche (hacia ti)
	local lane = V(-travel.Z, 0, travel.X) * (width / 4)
	local start = groundAt(point - travel * startDist + lane)
	local stop = groundAt(point - travel * 14 + lane)
	local startCf = CFrame.lookAt(start, start + travel)
	local model = Rides.build("Patrulla", force.Folder, startCf)
	anchorAll(model)
	model:SetAttribute("Siren", true)
	local offset = startCf:ToObjectSpace(model:GetPivot())
	local car: Car = { Model = model, Offset = offset, Officers = {}, Arrived = false }
	table.insert(force.Cars, car)
	-- Llega hasta cerca de ti y bajan los agentes
	task.spawn(function()
		local distance = (stop - start).Magnitude
		local t0 = os.clock()
		local duration = distance / Wanted.CarSpeed
		while model.Parent and os.clock() - t0 < duration do
			local alpha = (os.clock() - t0) / duration
			local eased = 1 - (1 - alpha) ^ 2
			local pos = start:Lerp(stop, eased)
			model:PivotTo(CFrame.lookAt(pos, pos + travel) * offset)
			RunService.Heartbeat:Wait()
		end
		if not model.Parent then
			return
		end
		model:PivotTo(CFrame.lookAt(stop, stop + travel) * offset)
		car.Arrived = true
		for i = 1, 2 do
			local door = stop + V(-travel.Z, 0, travel.X) * (if i == 1 then -3.5 else 3.5)
			table.insert(car.Officers, makeOfficer(force, door, car))
		end
	end)
end

---------------------------------------------------------------------
-- Helicópteros
---------------------------------------------------------------------
local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = model
	return p
end

-- El helicóptero: el servidor solo lo mueve (todo anclado). Cada pantalla gira los rotores, pone el
-- sonido y dibuja el foco (Controllers/Helicopters con shared/Helicopter): el haz, la luz y la mancha
-- en el suelo que sigue a quien buscan (atributos SpotTarget y SpotUser).
local function buildHeli(parent: Instance, cf: CFrame, player: Player): Model
	local m = Instance.new("Model")
	m.Name = "Helicoptero"
	local navy, white = rgb(24, 40, 96), rgb(235, 238, 245)
	local body = part(m, "Body", V(5, 4.2, 9), cf, navy)
	part(m, "Stripe", V(5.05, 1, 9.05), cf * CFrame.new(0, -0.6, 0), white)
	part(m, "Cockpit", V(4.4, 3.2, 3), cf * CFrame.new(0, 0.2, -5), rgb(80, 130, 180), Enum.Material.Glass, 0.3)
	part(m, "Tail", V(1, 1, 9), cf * CFrame.new(0, 0.9, 8.5), navy)
	part(m, "Fin", V(0.3, 3, 1.8), cf * CFrame.new(0, 2.2, 12.6), navy)
	part(m, "TailRotor", V(0.2, 3.2, 0.4), cf * CFrame.new(0.3, 2, 12.6), rgb(40, 40, 44)):AddTag("HeliTailRotor")
	for _, x in { -1.8, 1.8 } do
		part(m, "Skid", V(0.4, 0.4, 9), cf * CFrame.new(x, -3, 0), rgb(60, 60, 66), Enum.Material.Metal)
		part(m, "Strut", V(0.3, 1.2, 0.3), cf * CFrame.new(x, -2.4, -2), rgb(60, 60, 66), Enum.Material.Metal)
		part(m, "Strut", V(0.3, 1.2, 0.3), cf * CFrame.new(x, -2.4, 2), rgb(60, 60, 66), Enum.Material.Metal)
	end
	part(m, "Mast", V(0.5, 1, 0.5), cf * CFrame.new(0, 2.6, 0), rgb(50, 50, 54), Enum.Material.Metal)
	local hub = part(m, "RotorHub", V(0.8, 0.8, 0.8), cf * CFrame.new(0, 3.1, 0), rgb(40, 40, 44), Enum.Material.Metal)
	for i = 0, 1 do
		local blade = part(m, "Blade", V(26, 0.15, 1), hub.CFrame * CFrame.Angles(0, i * math.pi / 2, 0), rgb(30, 30, 34))
		blade:AddTag("HeliBlade")
	end
	for _, x in { -2.6, 2.6 } do
		part(m, if x < 0 then "SirenBlue" else "SirenRed", V(0.4, 0.4, 0.6), cf * CFrame.new(x, -1.8, -3.5), if x < 0 then rgb(40, 60, 140) else rgb(140, 30, 30))
	end
	-- La lámpara del foco (el haz y la luz los pone cada pantalla)
	part(m, "Searchlight", V(0.9, 0.7, 0.9), cf * CFrame.new(0, -2.3, -3.5), rgb(255, 250, 220), Enum.Material.Neon)
	m.PrimaryPart = body
	m:AddTag("PoliceCar") -- (para que el cliente haga parpadear sus luces)
	m:AddTag("Helicopter") -- (rotores, sonido y foco: Controllers/Helicopters)
	m:SetAttribute("Siren", true)
	m:SetAttribute("SpotUser", player.UserId)
	-- Llega entero a cada pantalla (sin rotor a medias por el streaming)
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	m.Parent = parent
	return m
end

local function spawnHeli(player: Player, force: Force)
	local r = playerRoot(player)
	if not r then
		return
	end
	local angle = math.random() * math.pi * 2
	local from = r.Position + V(math.cos(angle) * 260, 90, math.sin(angle) * 260)
	local cf = CFrame.lookAt(from, V(r.Position.X, from.Y, r.Position.Z))
	local model = buildHeli(force.Folder, cf, player)
	table.insert(force.Helis, { Model = model, Offset = cf:ToObjectSpace(model:GetPivot()), Angle = angle, Position = from })
end

local function stepHeli(heli: Heli, target: Vector3?, dt: number, index: number)
	if not heli.Model.Parent or not target then
		return
	end
	heli.Angle += dt * 0.35
	local radius = 38 + index * 14
	local ground = target
	local goal = ground + V(math.cos(heli.Angle) * radius, 68 + index * 8, math.sin(heli.Angle) * radius)
	local toGoal = goal - heli.Position
	local speed = 70
	if toGoal.Magnitude > speed * dt then
		heli.Position += toGoal.Unit * speed * dt
	else
		heli.Position = goal
	end
	local look = V(ground.X, heli.Position.Y, ground.Z)
	local cf = CFrame.lookAt(heli.Position, look) * CFrame.Angles(math.rad(-8), 0, 0)
	heli.Model:PivotTo(cf * heli.Offset)
	-- A dónde apunta el foco (cada pantalla lo sigue con suavidad): solo se avisa si cambia algo
	if not heli.SpotAt or (heli.SpotAt - ground).Magnitude > 0.5 then
		heli.SpotAt = ground
		heli.Model:SetAttribute("SpotTarget", ground)
	end
end

---------------------------------------------------------------------
-- API para WantedService
---------------------------------------------------------------------
local function forceOf(player: Player): Force
	local force = forces[player]
	if not force then
		local folder = Instance.new("Folder")
		folder.Name = "Policia_" .. player.UserId
		folder.Parent = root
		force = { Cars = {}, Helis = {}, Officers = {}, Target = nil, Stars = 0, Folder = folder }
		forces[player] = force
	end
	return force
end

-- Ajusta cuántas patrullas persiguen a este jugador según sus estrellas
function PoliceUnits.ensure(player: Player, stars: number)
	if stars <= 0 then
		PoliceUnits.dismiss(player) -- (sin estrellas no queda ninguna patrulla)
		return
	end
	local force = forceOf(player)
	force.Stars = stars
	local want = Wanted.response(stars)
	-- Quitar lo que ya no sirve (tumbados, borrados)
	for i = #force.Officers, 1, -1 do
		if not force.Officers[i].Model.Parent then
			table.remove(force.Officers, i)
		end
	end
	for i = #force.Cars, 1, -1 do
		if not force.Cars[i].Model.Parent then
			table.remove(force.Cars, i)
		end
	end
	-- Coches que se han quedado muy lejos (te has escapado de ellos): se van y viene otro
	local r = playerRoot(player)
	for i = #force.Cars, 1, -1 do
		local car = force.Cars[i]
		local far = r and (car.Arrived or car.Chase) and (car.Model:GetPivot().Position - r.Position).Magnitude > 320
		-- …o que se han quedado sin agentes (los han tumbado): llegan refuerzos
		local empty = car.Arrived and #car.Officers > 0
		for _, officer in car.Officers do
			if not officerDown(officer) then
				empty = false
			end
		end
		if far or empty then
			for _, officer in car.Officers do
				if not officerDown(officer) then
					officer.Model:Destroy()
				end
			end
			car.Model:Destroy()
			-- (sin prisa: los refuerzos llegan en el siguiente repaso)
			table.remove(force.Cars, i)
		end
	end
	-- Dentro de un edificio (sala de InteriorService) no llegan refuerzos: te esperan fuera
	if player:GetAttribute("InteriorKey") then
		return
	end
	for _ = #force.Cars + 1, want.Cars do
		spawnCar(player, force)
	end
	for _ = #force.Helis + 1, want.Helis do
		spawnHeli(player, force)
	end
end

-- Hacia dónde van (tu posición si te ven, o la última en la que te vieron)
function PoliceUnits.setTarget(player: Player, position: Vector3?)
	forceOf(player).Target = position
end

-- Todas se retiran (te has librado o te han detenido)
function PoliceUnits.dismiss(player: Player)
	local force = forces[player]
	if not force then
		return
	end
	forces[player] = nil
	for _, heli in force.Helis do
		-- el helicóptero se aleja antes de desaparecer
		task.spawn(function()
			local t0 = os.clock()
			while heli.Model.Parent and os.clock() - t0 < 4 do
				heli.Position += V(0, 20, 60) * 0.05
				heli.Model:PivotTo(CFrame.new(heli.Position) * heli.Offset)
				task.wait(0.05)
			end
		end)
	end
	for _, car in force.Cars do
		car.Model:SetAttribute("Siren", false)
	end
	task.delay(4.5, function()
		force.Folder:Destroy()
	end)
end

-- ¿Algún agente, coche o helicóptero te ve ahora mismo?
function PoliceUnits.sees(player: Player): boolean
	local force = forces[player]
	local r = playerRoot(player)
	if not force or not r then
		return false
	end
	local params = rayParams({ player.Character :: Instance })
	local function clear(from: Vector3, range: number): boolean
		local offset = r.Position - from
		if offset.Magnitude > range then
			return false
		end
		return workspace:Raycast(from, offset, params) == nil
	end
	for _, officer in force.Officers do
		if not officerDown(officer) and clear(officer.Root.Position + V(0, 1.5, 0), Wanted.PoliceSight) then
			return true
		end
	end
	for _, car in force.Cars do
		if car.Model.Parent and clear(car.Model:GetPivot().Position + V(0, 4, 0), Wanted.PoliceSight) then
			return true
		end
	end
	for _, heli in force.Helis do
		if heli.Model.Parent and clear(heli.Position + V(0, -3, 0), Wanted.HeliSight + 70) then
			return true
		end
	end
	return false
end

-- Agentes de pie cerca de una posición (para detener)
function PoliceUnits.officersNear(player: Player, position: Vector3, range: number): number
	local force = forces[player]
	local count = 0
	for _, officer in (if force then force.Officers else {}) do
		if not officerDown(officer) and (officer.Root.Position - position).Magnitude <= range then
			count += 1
		end
	end
	return count
end

-- ¿Hay alguna patrulla (de cualquiera) cerca de ese punto? (ven delitos de otros)
function PoliceUnits.anyNear(position: Vector3, range: number, except: Player?): boolean
	local params = rayParams()
	for owner, force in forces do
		if owner ~= except then
			for _, officer in force.Officers do
				local from = officer.Root.Position + V(0, 1.5, 0)
				if not officerDown(officer) and (from - position).Magnitude <= range and not workspace:Raycast(from, position - from, params) then
					return true
				end
			end
		end
	end
	return false
end

---------------------------------------------------------------------
-- Patrullas de ronda (circulan por la ciudad sin que nadie esté buscado)
---------------------------------------------------------------------
local graph: PatrolRoutes.Graph? = nil
local function routes(): PatrolRoutes.Graph
	if not graph then
		graph = PatrolRoutes.graph(Roads.segments())
	end
	return graph :: PatrolRoutes.Graph
end

local function flatDistance(a: Vector3, b: Vector3): number
	return V(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Sale una patrulla en una calle a la distancia justa de ese punto (ni encima ni lejísimos)
local function spawnPatrol(near: Vector3): Patrol?
	local g = routes()
	local P = Wanted.Patrols
	local candidates = {}
	for i, segment in g.Segments do
		local d = flatDistance((segment.A + segment.B) / 2, near)
		if d >= P.Spawn[1] and d <= P.Spawn[2] and PatrolRoutes.length(segment) > 20 then
			table.insert(candidates, i)
		end
	end
	if #candidates == 0 then
		return nil
	end
	local index = candidates[math.random(1, #candidates)]
	local segment = g.Segments[index]
	local from = if math.random() < 0.5 then "A" else "B"
	local width = Roads.Kinds[segment.Kind] and Roads.Kinds[segment.Kind].Road or 22
	local lane = width / 4
	local point, dir = PatrolRoutes.point(segment, from, 0.5, lane)
	local ground = groundAt(point)
	local cf = CFrame.lookAt(ground, ground + dir)
	local model = Rides.build("Patrulla", patrolFolder, cf)
	anchorAll(model)
	model:SetAttribute("Siren", false)
	model:SetAttribute("Patrol", true)
	local patrol: Patrol = { Model = model, Offset = cf:ToObjectSpace(model:GetPivot()), Index = index, From = from, T = 0.5, Lane = lane, Position = ground, GroundAt = 0, Speed = Wanted.Patrols.Speed, Look = dir }
	table.insert(patrols, patrol)
	return patrol
end

-- Semáforos: el mismo ciclo que los coches del tráfico (Controllers/Traffic) y los autobuses
-- (shared/TrafficSignals, con la hora del servidor). Los cruces con semáforo salen de las calles
-- publicadas (ReplicatedStorage.Ambient.Roads); se miran una vez.
local signalIndex: TrafficSignals.Index? = nil
local function signals(): TrafficSignals.Index
	if not signalIndex then
		local ambient = ReplicatedStorage:FindFirstChild("Ambient")
		local roadsFolder = ambient and ambient:FindFirstChild("Roads")
		if not roadsFolder then
			return TrafficSignals.index({}) -- (aún no: se vuelve a mirar)
		end
		signalIndex = TrafficSignals.index(TrafficSignals.fromFolder(roadsFolder))
	end
	return signalIndex :: TrafficSignals.Index
end

local PATROL_LENGTH = 14 -- (largo del coche patrulla, para guardar distancia)
local PATROL_DECEL = 26
local PATROL_TURN_RATE = 3.5 -- radianes por segundo al girar (media vuelta en menos de un segundo)

-- Espacio libre por delante: semáforo en rojo en su calle, la patrulla de delante o alguien
-- (un jugador) en su carril
local function patrolGap(patrol: Patrol, _segment: PatrolRoutes.Segment, length: number, dir: Vector3): number
	-- Semáforo en rojo (o en ámbar, si le da para parar) en un cruce de su calle: para antes del paso
	-- de cebra. Con la sirena puesta (emergencia) no para: pasa despacio, con cuidado.
	local gap = TrafficSignals.gapAhead(signals(), patrol.Position, dir, PATROL_LENGTH / 2, patrol.Speed or 0, PATROL_DECEL, workspace:GetServerTimeNow())
	if gap < math.huge and patrol.Model:GetAttribute("Siren") == true then
		gap = math.max(gap, 12 * 12 / (2 * PATROL_DECEL) + 1.5) -- (a unos 12 studs/s por el cruce)
	end
	for _, other in patrols do
		if other ~= patrol and other.Index == patrol.Index and other.From == patrol.From and other.T > patrol.T then
			gap = math.min(gap, (other.T - patrol.T) * length - PATROL_LENGTH)
		end
	end
	local side = V(-dir.Z, 0, dir.X)
	for _, player in Players:GetPlayers() do
		local r = playerRoot(player)
		if r then
			local rel = r.Position - patrol.Position
			local ahead = rel:Dot(dir)
			if ahead > 0 and ahead < 24 and math.abs(rel:Dot(side)) < 4.5 and math.abs(rel.Y) < 8 then
				gap = math.min(gap, ahead - PATROL_LENGTH / 2 - 2)
			end
		end
	end
	return gap
end

local function stepPatrol(patrol: Patrol, dt: number)
	local g = routes()
	local segment = g.Segments[patrol.Index]
	if not segment then
		return
	end
	local length = math.max(PatrolRoutes.length(segment), 1)
	local _, ahead = PatrolRoutes.point(segment, patrol.From, patrol.T, patrol.Lane)
	-- Frena y arranca poco a poco (como el tráfico: raíz de 2·frenada·hueco)
	local gap = patrolGap(patrol, segment, length, ahead)
	local target = math.min(Wanted.Patrols.Speed, math.sqrt(2 * PATROL_DECEL * math.max(gap - 1.5, 0)))
	local speed = patrol.Speed or Wanted.Patrols.Speed
	speed = math.max(speed + math.clamp(target - speed, -PATROL_DECEL * 2 * dt, 14 * dt), 0)
	patrol.Speed = speed
	patrol.T += speed * dt / length
	if patrol.T >= 1 then
		-- Final del tramo: sigue por otra calle del cruce (o da la vuelta si no hay salida)
		local arrived = if patrol.From == "A" then "B" else "A"
		patrol.Index, patrol.From = PatrolRoutes.next(g, patrol.Index, arrived)
		segment = g.Segments[patrol.Index]
		patrol.T = PatrolRoutes.entry(segment, patrol.From, patrol.Position)
		patrol.Lane = (Roads.Kinds[segment.Kind] and Roads.Kinds[segment.Kind].Road or 22) / 4
	end
	local point, dir = PatrolRoutes.point(segment, patrol.From, patrol.T, patrol.Lane)
	-- La altura del suelo, de vez en cuando (las calles son casi planas)
	local now = os.clock()
	local y = patrol.Position.Y
	if now - patrol.GroundAt > 0.3 then
		patrol.GroundAt = now
		y = groundAt(point).Y
	end
	-- En las esquinas gira y se arrima a su carril poco a poco (antes daba un salto y un giro en seco)
	local blend = math.min(1, dt * 6)
	local flat = V(patrol.Position.X, 0, patrol.Position.Z):Lerp(V(point.X, 0, point.Z), blend)
	local jumped = flatDistance(flat, point) > 20
	if jumped then
		flat = V(point.X, 0, point.Z) -- (un salto grande: callejón sin salida o recién puesta)
	end
	patrol.Position = V(flat.X, y, flat.Z)
	-- (gira de verdad hacia donde va: con Lerp, tras una media vuelta seguía mirando hacia atrás)
	local look = if jumped then dir else PatrolRoutes.turnToward(patrol.Look or dir, dir, PATROL_TURN_RATE * dt)
	patrol.Look = look
	patrol.Model:PivotTo(CFrame.lookAt(patrol.Position, patrol.Position + look) * patrol.Offset)
end

-- Cuántas patrullas de ronda hay: según los jugadores; las que se quedan lejos de todos se retiran
local function tendPatrols()
	local roots = {}
	for _, player in Players:GetPlayers() do
		local r = playerRoot(player)
		if r and player:GetAttribute("LifeStage") ~= "Bebe" then
			table.insert(roots, r.Position)
		end
	end
	for i = #patrols, 1, -1 do
		local patrol = patrols[i]
		local near = false
		for _, position in roots do
			if flatDistance(patrol.Position, position) <= Wanted.Patrols.Despawn then
				near = true
				break
			end
		end
		if not near or not patrol.Model.Parent then
			patrol.Model:Destroy()
			table.remove(patrols, i)
		end
	end
	local want = if #roots == 0 then 0 else math.min(Wanted.Patrols.Max, math.ceil(#roots / Wanted.Patrols.PerPlayers))
	local tries = 0
	while #patrols < want and tries < 3 do
		tries += 1
		spawnPatrol(roots[math.random(1, #roots)])
	end
end
PoliceUnits.tendPatrols = tendPatrols

function PoliceUnits.patrolCount(): number
	return #patrols
end

-- ¿Te ve alguna patrulla de ronda? (a menos de range y sin nada en medio) Devuelve cuál.
function PoliceUnits.patrolSees(player: Player, range: number): Patrol?
	local r = playerRoot(player)
	if not r then
		return nil
	end
	local params = rayParams({ player.Character :: Instance })
	for _, patrol in patrols do
		local from = patrol.Position + V(0, 4, 0)
		local offset = r.Position - from
		if patrol.Model.Parent and offset.Magnitude <= range and workspace:Raycast(from, offset, params) == nil then
			return patrol
		end
	end
	return nil
end

-- ¿Ve la policía a quien conduce? Patrullas de ronda, y agentes o coches de cualquier persecución.
-- Devuelve si le ven y, si fue una patrulla de ronda, cuál (para que le dé el «¡Alto!»).
function PoliceUnits.seesDriver(player: Player, range: number): (boolean, Patrol?)
	local patrol = PoliceUnits.patrolSees(player, range)
	if patrol then
		return true, patrol
	end
	local r = playerRoot(player)
	if not r then
		return false, nil
	end
	local params = rayParams({ player.Character :: Instance })
	local function clear(from: Vector3): boolean
		local offset = r.Position - from
		return offset.Magnitude <= range and workspace:Raycast(from, offset, params) == nil
	end
	for _, force in forces do
		for _, officer in force.Officers do
			if not officerDown(officer) and clear(officer.Root.Position + V(0, 1.5, 0)) then
				return true, nil
			end
		end
		for _, car in force.Cars do
			if car.Model.Parent and clear(car.Model:GetPivot().Position + V(0, 4, 0)) then
				return true, nil
			end
		end
	end
	return false, nil
end

-- «¡Alto!»: la patrulla de ronda que te ha visto enciende la sirena y te sigue (pasa a ser de tu
-- persecución). Cuando te paras, bajan los agentes.
function PoliceUnits.pullOver(player: Player, patrol: Patrol?)
	if not patrol then
		return
	end
	local i = table.find(patrols, patrol)
	if not i or not patrol.Model.Parent then
		return
	end
	table.remove(patrols, i)
	local force = forceOf(player)
	patrol.Model.Parent = force.Folder
	patrol.Model:SetAttribute("Siren", true)
	patrol.Model:SetAttribute("Patrol", nil)
	local r = playerRoot(player)
	local look = if r then V(r.Position.X - patrol.Position.X, 0, r.Position.Z - patrol.Position.Z) else V(0, 0, -1)
	table.insert(force.Cars, {
		Model = patrol.Model,
		Offset = patrol.Offset,
		Officers = {},
		Arrived = false,
		Chase = true,
		Position = patrol.Position,
		Look = if look.Magnitude > 0.1 then look.Unit else V(0, 0, -1),
	})
end

-- La patrulla del «¡Alto!» te sigue; cuando te paras cerca, bajan los agentes
local function stepChase(player: Player, force: Force, car: Car, dt: number)
	local r = playerRoot(player)
	if car.Arrived or not car.Model.Parent or not r or not car.Position then
		return
	end
	local position = car.Position :: Vector3
	local flat = V(r.Position.X - position.X, 0, r.Position.Z - position.Z)
	local distance = flat.Magnitude
	if distance > 12 then
		local step = math.min(distance - 12, Wanted.ChaseSpeed * dt)
		car.Look = flat.Unit
		local nextPos = position + flat.Unit * step
		car.Position = V(nextPos.X, groundAt(nextPos).Y, nextPos.Z)
		local look = car.Look :: Vector3
		car.Model:PivotTo(CFrame.lookAt(car.Position :: Vector3, (car.Position :: Vector3) + look) * car.Offset)
	end
	local velocity = r.AssemblyLinearVelocity
	local speed = if typeof(velocity) == "Vector3" then V(velocity.X, 0, velocity.Z).Magnitude else 0
	if distance <= 24 and speed < Wanted.StopSpeed then
		car.Arrived = true
		local at = car.Position :: Vector3
		local look = car.Look or V(0, 0, -1)
		for k = 1, 2 do
			local door = at + V(-look.Z, 0, look.X) * (if k == 1 then -3.5 else 3.5)
			table.insert(car.Officers, makeOfficer(force, door, car))
		end
	end
end

function PoliceUnits.init()
	root = Instance.new("Folder")
	root.Name = "PoliceResponse"
	root.Parent = workspace
	patrolFolder = Instance.new("Folder")
	patrolFolder.Name = "Patrullas"
	patrolFolder.Parent = root
	-- Patrullas de ronda: cuántas hay, cada 2 segundos
	task.spawn(function()
		while true do
			task.wait(2)
			local ok, err = pcall(tendPatrols)
			if not ok then
				warn("[PoliceUnits] " .. tostring(err))
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for _, patrol in patrols do
			stepPatrol(patrol, dt)
		end
		for player, force in forces do
			for _, car in force.Cars do
				if car.Chase then
					stepChase(player, force, car, dt)
				end
			end
			local speed = Wanted.OfficerSpeed[math.clamp(force.Stars, 1, #Wanted.OfficerSpeed)]
			for _, officer in force.Officers do
				stepOfficer(officer, force.Target, speed, dt)
			end
			for i, heli in force.Helis do
				stepHeli(heli, force.Target, dt, i - 1)
			end
			if not player.Parent then
				PoliceUnits.dismiss(player)
			end
		end
	end)
end

return PoliceUnits
