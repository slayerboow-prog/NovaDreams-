-- PoliceUnits: las patrullas que salen a por un jugador buscado (WantedService decide cuántas).
--
--   * Coche patrulla: aparece por la misma calle en la que estás (lejos), llega con la sirena,
--     para cerca y bajan 2 agentes.
--   * Agente: te persigue a pie (buscando camino entre los edificios); si te alcanza, te detiene.
--     Se le puede tumbar a golpes (atributos Officer / Hp / Down, los usa CombatService).
--   * Helicóptero: vuela en círculos sobre ti con un foco. Ve desde lejos, pero no a través de un techo.
-- Todo va anclado y lo mueve el servidor; las hélices y las luces las anima el cliente (WantedUI).

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Wanted = require(ReplicatedStorage.Shared.Wanted)
local Npc = require(script.Parent.Npc)
local Roads = require(script.Parent.Kit.Roads)
local Rides = require(script.Parent.Kit.Rides)

local PoliceUnits = {}

local V = Vector3.new
local rgb = Color3.fromRGB

type Officer = { Model: Model, Root: BasePart, Height: number, Path: { Vector3 }, PathAt: number, Car: any? }
type Car = { Model: Model, Offset: CFrame, Officers: { Officer }, Arrived: boolean }
type Heli = { Model: Model, Offset: CFrame, Beam: BasePart, Angle: number, Position: Vector3 }
type Force = { Cars: { Car }, Helis: { Heli }, Officers: { Officer }, Target: Vector3?, Stars: number, Folder: Folder }

local forces: { [Player]: Force } = {}
local root: Folder

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
	for _, instance in extra or {} do
		table.insert(list, instance)
	end
	params.FilterDescendantsInstances = list
	params.IgnoreWater = true
	return params
end

local function groundAt(position: Vector3): Vector3
	local hit = workspace:Raycast(position + V(0, 40, 0), V(0, -120, 0), rayParams())
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

local function buildHeli(parent: Instance, cf: CFrame): (Model, BasePart)
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
	local hub = part(m, "RotorHub", V(0.8, 0.8, 0.8), cf * CFrame.new(0, 2.6, 0), rgb(40, 40, 44), Enum.Material.Metal)
	for i = 0, 1 do
		local blade = part(m, "Blade", V(26, 0.15, 1), hub.CFrame * CFrame.Angles(0, i * math.pi / 2, 0), rgb(30, 30, 34))
		blade:AddTag("HeliBlade")
	end
	for _, x in { -2.6, 2.6 } do
		part(m, if x < 0 then "SirenBlue" else "SirenRed", V(0.4, 0.4, 0.6), cf * CFrame.new(x, -1.8, -3.5), if x < 0 then rgb(40, 60, 140) else rgb(140, 30, 30))
	end
	-- Foco: luz hacia abajo y un haz que llega hasta ti
	local lamp = part(m, "Searchlight", V(0.8, 0.6, 0.8), cf * CFrame.new(0, -2.3, -3.5), rgb(255, 250, 220), Enum.Material.Neon)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = 35
	spot.Range = 60
	spot.Brightness = 6
	spot.Color = rgb(255, 250, 225)
	spot.Parent = lamp
	local beam = part(m, "Beam", V(4, 4, 10), cf, rgb(255, 250, 215), Enum.Material.Neon, 0.88)
	beam.Shape = Enum.PartType.Cylinder
	m.PrimaryPart = body
	m:AddTag("PoliceCar") -- (para que el cliente haga parpadear sus luces)
	m:SetAttribute("Siren", true)
	m.Parent = parent
	return m, beam
end

local function spawnHeli(player: Player, force: Force)
	local r = playerRoot(player)
	if not r then
		return
	end
	local angle = math.random() * math.pi * 2
	local from = r.Position + V(math.cos(angle) * 260, 90, math.sin(angle) * 260)
	local cf = CFrame.lookAt(from, V(r.Position.X, from.Y, r.Position.Z))
	local model, beam = buildHeli(force.Folder, cf)
	table.insert(force.Helis, { Model = model, Offset = cf:ToObjectSpace(model:GetPivot()), Beam = beam, Angle = angle, Position = from })
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
	-- El haz del foco, desde el helicóptero hasta ti
	local lampPos = heli.Position + V(0, -2.5, 0)
	local length = (ground - lampPos).Magnitude
	heli.Beam.Size = V(length, 6, 6)
	heli.Beam.CFrame = CFrame.lookAt(lampPos:Lerp(ground, 0.5), ground) * CFrame.Angles(0, math.pi / 2, 0)
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
		local far = r and car.Arrived and (car.Model:GetPivot().Position - r.Position).Magnitude > 320
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

function PoliceUnits.init()
	root = Instance.new("Folder")
	root.Name = "PoliceResponse"
	root.Parent = workspace
	RunService.Heartbeat:Connect(function(dt)
		for player, force in forces do
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
