-- Ambient (cliente): tráfico y peatones alrededor del jugador.
-- Se simula en cada dispositivo (no en el servidor) y solo cerca del jugador,
-- así la ciudad parece viva sin coste de red ni de servidor.
--  * Coches: circulan por su carril (por la derecha) y frenan si hay alguien delante.
--  * Peatones: caminan por las aceras con animación de pasos. De noche hay menos.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ambient = {}

local player = Players.LocalPlayer

local CAR_COUNT = 16
local PED_COUNT = 20
local ROAD_TOP, WALK_TOP = 0.4, 1.0
local LANE = 2.9 -- distancia del centro de la calzada al centro del carril
local SIDEWALK = 15.5 -- distancia del centro de la calzada al centro de la acera

type Road = { Axis: string, At: number, From: number, To: number }
type Agent = {
	Model: Model,
	Parts: { BasePart },
	Offsets: { CFrame },
	Road: Road?,
	U: number,
	Dir: number,
	Speed: number,
	Cruise: number,
	Side: number,
	Phase: number,
	Active: boolean,
}

local roads: { Road } = {}
local cars: { Agent } = {}
local peds: { Agent } = {}
local folder: Folder

local function point(road: Road, u: number, v: number, y: number): Vector3
	if road.Axis == "X" then
		return Vector3.new(u, y, road.At + v)
	end
	return Vector3.new(road.At + v, y, u)
end

local function heading(road: Road, dir: number): CFrame
	local d = if road.Axis == "X" then Vector3.new(dir, 0, 0) else Vector3.new(0, 0, dir)
	return CFrame.Angles(0, math.atan2(-d.X, -d.Z), 0)
end

local function focus(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return camera and camera.Focus.Position
end

-- Elige una calle cercana y una posición en ella a una distancia razonable del jugador
local function spawnPoint(center: Vector3, minDist: number, maxDist: number): (Road?, number)
	for _ = 1, 12 do
		local road = roads[math.random(1, #roads)]
		local along = if road.Axis == "X" then center.X else center.Z
		local across = if road.Axis == "X" then center.Z else center.X
		local offset = math.abs(across - road.At)
		if offset < maxDist then
			local reach = math.sqrt(maxDist * maxDist - offset * offset)
			local u0 = math.max(road.From + 10, along - reach)
			local u1 = math.min(road.To - 10, along + reach)
			if u1 > u0 then
				local u = u0 + math.random() * (u1 - u0)
				local distance = math.sqrt((u - along) ^ 2 + offset * offset)
				if distance >= minDist then
					return road, u
				end
			end
		end
	end
	return nil, 0
end

local function place(agent: Agent, root: CFrame)
	local cframes = table.create(#agent.Parts)
	for i, offset in agent.Offsets do
		cframes[i] = root * offset
	end
	workspace:BulkMoveTo(agent.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local function setActive(agent: Agent, active: boolean)
	if agent.Active ~= active then
		agent.Active = active
		agent.Model.Parent = if active then folder else nil
	end
end

---------------------------------------------------------------------
-- Coches
---------------------------------------------------------------------

-- Faros: una luz por coche (en el primer faro) que se enciende de noche
local headlights: { SpotLight } = {}

local function addHeadlight(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Headlight" then
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Front
			light.Angle = 55
			light.Range = 42
			light.Brightness = 3
			light.Color = Color3.fromRGB(255, 244, 222)
			light.Shadows = false
			light.Enabled = false
			light.Parent = d
			table.insert(headlights, light)
			return
		end
	end
end

local function makeCar(template: Model): Agent
	local model = template:Clone()
	addHeadlight(model)
	local parts, offsets = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			table.insert(parts, d)
			table.insert(offsets, d.CFrame)
		end
	end
	return { Model = model, Parts = parts, Offsets = offsets, Road = nil, U = 0, Dir = 1, Speed = 0, Cruise = 0, Side = 1, Phase = 0, Active = false }
end

local function respawnCar(agent: Agent, center: Vector3, initial: boolean)
	local road, u = spawnPoint(center, if initial then 30 else 160, 330)
	agent.Road = road
	if not road then
		setActive(agent, false)
		return
	end
	agent.U = u
	agent.Dir = if math.random() < 0.5 then 1 else -1
	agent.Cruise = 26 + math.random() * 14
	agent.Speed = agent.Cruise
	setActive(agent, true)
end

local function updateCars(dt: number, center: Vector3)
	local character = player.Character
	local me = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, car in cars do
		local road = car.Road
		if not road then
			respawnCar(car, center, false)
			continue
		end
		local pos = point(road, car.U, car.Dir * LANE, ROAD_TOP)
		-- ¿Hay algo delante en el carril? (el jugador u otro coche)
		local blocked = false
		if me then
			local rel = me.Position - pos
			local ahead = if road.Axis == "X" then rel.X * car.Dir else rel.Z * car.Dir
			local lateral = if road.Axis == "X" then math.abs(rel.Z) else math.abs(rel.X)
			blocked = ahead > 0 and ahead < 16 and lateral < 5 and math.abs(rel.Y) < 8
		end
		if not blocked then
			for _, other in cars do
				if other ~= car and other.Road == road and other.Dir == car.Dir then
					local gap = (other.U - car.U) * car.Dir
					if gap > 0 and gap < 18 then
						blocked = true
						break
					end
				end
			end
		end
		local target = if blocked then 0 else car.Cruise
		car.Speed += math.clamp(target - car.Speed, -60 * dt, 18 * dt)
		car.U += car.Dir * car.Speed * dt

		local distance = (pos - center).Magnitude
		if car.U < road.From or car.U > road.To or distance > 400 then
			respawnCar(car, center, false)
		else
			place(car, CFrame.new(pos) * heading(road, car.Dir))
		end
	end
end

---------------------------------------------------------------------
-- Peatones
---------------------------------------------------------------------

local SKIN = { Color3.fromRGB(255, 219, 182), Color3.fromRGB(234, 184, 146), Color3.fromRGB(198, 140, 100), Color3.fromRGB(141, 94, 64), Color3.fromRGB(96, 64, 44) }
local CLOTHES = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(50, 90, 170), Color3.fromRGB(40, 140, 90), Color3.fromRGB(230, 200, 70), Color3.fromRGB(240, 240, 240), Color3.fromRGB(40, 40, 44), Color3.fromRGB(150, 80, 160), Color3.fromRGB(240, 140, 60) }
local PANTS = { Color3.fromRGB(40, 50, 90), Color3.fromRGB(30, 30, 34), Color3.fromRGB(110, 90, 70), Color3.fromRGB(80, 80, 86), Color3.fromRGB(60, 80, 120) }
local HAIR = { Color3.fromRGB(30, 22, 18), Color3.fromRGB(90, 60, 30), Color3.fromRGB(200, 170, 110), Color3.fromRGB(150, 60, 30), Color3.fromRGB(180, 180, 180) }

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

-- Figura de peatón: 0 torso, 1 cabeza, 2 pelo, 3-4 piernas, 5-6 brazos (en ese orden)
local function makePed(): Agent
	local model = Instance.new("Model")
	model.Name = "Peaton"
	local skin, shirt, pants = pick(SKIN), pick(CLOTHES), pick(PANTS)
	local specs = {
		{ "Torso", Vector3.new(2, 2.3, 1.1), shirt, Enum.PartType.Block },
		{ "Head", Vector3.new(1.3, 1.3, 1.3), skin, Enum.PartType.Ball },
		{ "Hair", Vector3.new(1.4, 0.55, 1.4), pick(HAIR), Enum.PartType.Block },
		{ "LegL", Vector3.new(0.9, 2.4, 0.95), pants, Enum.PartType.Block },
		{ "LegR", Vector3.new(0.9, 2.4, 0.95), pants, Enum.PartType.Block },
		{ "ArmL", Vector3.new(0.7, 2.2, 0.75), shirt, Enum.PartType.Block },
		{ "ArmR", Vector3.new(0.7, 2.2, 0.75), shirt, Enum.PartType.Block },
	}
	local parts = {}
	for _, s in specs do
		local p = Instance.new("Part")
		p.Name = s[1]
		p.Size = s[2]
		p.Color = s[3]
		p.Shape = s[4]
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = true
		p.Parent = model
		table.insert(parts, p)
	end
	return { Model = model, Parts = parts, Offsets = {}, Road = nil, U = 0, Dir = 1, Speed = 0, Cruise = 0, Side = 1, Phase = math.random() * 6, Active = false }
end

local function respawnPed(agent: Agent, center: Vector3, initial: boolean)
	local road, u = spawnPoint(center, if initial then 10 else 90, 200)
	agent.Road = road
	if not road then
		setActive(agent, false)
		return
	end
	agent.U = u
	agent.Dir = if math.random() < 0.5 then 1 else -1
	agent.Side = if math.random() < 0.5 then 1 else -1
	agent.Cruise = 4.5 + math.random() * 2.5
	agent.Speed = agent.Cruise
	setActive(agent, true)
end

local function posePed(agent: Agent, root: CFrame)
	local swing = math.sin(agent.Phase) * 0.55
	local bob = math.abs(math.cos(agent.Phase)) * 0.12
	local base = root * CFrame.new(0, bob, 0)
	local cframes = {
		base * CFrame.new(0, 3.55, 0), -- torso
		base * CFrame.new(0, 5.35, 0), -- cabeza
		base * CFrame.new(0, 5.95, 0.05), -- pelo
		base * CFrame.new(-0.48, 2.4, 0) * CFrame.Angles(swing, 0, 0) * CFrame.new(0, -1.2, 0),
		base * CFrame.new(0.48, 2.4, 0) * CFrame.Angles(-swing, 0, 0) * CFrame.new(0, -1.2, 0),
		base * CFrame.new(-1.38, 4.55, 0) * CFrame.Angles(-swing * 0.8, 0, 0) * CFrame.new(0, -1.05, 0),
		base * CFrame.new(1.38, 4.55, 0) * CFrame.Angles(swing * 0.8, 0, 0) * CFrame.new(0, -1.05, 0),
	}
	workspace:BulkMoveTo(agent.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local function updatePeds(dt: number, center: Vector3)
	local clock = Lighting.ClockTime
	local night = clock < 7 or clock > 21.5
	for i, ped in peds do
		-- De noche solo sale una parte de la gente
		local wanted = not night or i % 3 == 0
		if not wanted then
			setActive(ped, false)
			ped.Road = nil
			continue
		end
		local road = ped.Road
		if not road then
			respawnPed(ped, center, false)
			continue
		end
		ped.U += ped.Dir * ped.Speed * dt
		ped.Phase += dt * ped.Speed * 1.5
		local pos = point(road, ped.U, ped.Side * SIDEWALK, WALK_TOP)
		if ped.U < road.From or ped.U > road.To or (pos - center).Magnitude > 240 then
			respawnPed(ped, center, false)
		else
			posePed(ped, CFrame.new(pos) * heading(road, ped.Dir))
		end
	end
end

---------------------------------------------------------------------

function Ambient.init()
	local data = ReplicatedStorage:WaitForChild("Ambient", 60)
	if not data then
		warn("[Ambient] No hay datos de calles: sin tráfico ni peatones")
		return
	end
	for _, config in data:WaitForChild("Roads"):GetChildren() do
		table.insert(roads, {
			Axis = config:GetAttribute("Axis"),
			At = config:GetAttribute("At"),
			From = config:GetAttribute("From"),
			To = config:GetAttribute("To"),
		})
	end
	if #roads == 0 then
		return
	end

	folder = Instance.new("Folder")
	folder.Name = "AmbientLife"
	folder.Parent = workspace

	local templates = data:WaitForChild("Cars"):GetChildren()
	for i = 1, CAR_COUNT do
		local template = templates[(i - 1) % #templates + 1]
		if template and template:IsA("Model") then
			table.insert(cars, makeCar(template))
		end
	end
	for _ = 1, PED_COUNT do
		table.insert(peds, makePed())
	end

	-- Primera colocación repartida alrededor del jugador
	local center = focus() or Vector3.zero
	for _, car in cars do
		respawnCar(car, center, true)
	end
	for _, ped in peds do
		respawnPed(ped, center, true)
	end

	-- Faros encendidos al anochecer (con algo de margen: primero se encienden los coches)
	task.spawn(function()
		local lit: boolean? = nil
		while true do
			local clock = Lighting.ClockTime
			local on = clock >= 18.3 or clock < 7.2
			if on ~= lit then
				lit = on
				for _, light in headlights do
					light.Enabled = on
				end
			end
			task.wait(2)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local c = focus()
		if not c then
			return
		end
		updateCars(math.min(dt, 0.1), c)
		updatePeds(math.min(dt, 0.1), c)
	end)
end

return Ambient
