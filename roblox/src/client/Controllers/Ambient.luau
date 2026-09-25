-- Ambient (cliente): tráfico y peatones alrededor del jugador.
-- Se simula en cada dispositivo (no en el servidor) y solo cerca del jugador,
-- así la ciudad parece viva sin coste de red ni de servidor.
--  * Vehículos (coches, taxis, motos, bicis y patinetes): ver Traffic.luau.
--  * Peatones: caminan por las aceras con animación de pasos. De noche hay menos.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Traffic = require(script.Parent.Traffic)

local Ambient = {}

local player = Players.LocalPlayer

local PED_COUNT = 28
local WALK_TOP = 1.0
-- Cada calle es un tramo recto en cualquier ángulo: A + Dir·u (u de From a To) + Perp·v
type Road = { A: Vector3, Dir: Vector3, Perp: Vector3, From: number, To: number, Lane: number, Walk: number? }
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
	Style: string,
	Scale: number,
	Index: { [string]: number },
	Umbrella: boolean,
}

local roads: { Road } = {}
local peds: { Agent } = {}
local folder: Folder

local function point(road: Road, u: number, v: number, y: number): Vector3
	local p = road.A + road.Dir * u + road.Perp * v
	return Vector3.new(p.X, y, p.Z)
end

local function heading(road: Road, dir: number): CFrame
	local d = road.Dir * dir
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
		local rel = center - road.A
		local along = rel:Dot(road.Dir)
		local offset = math.abs(rel:Dot(road.Perp))
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

local function setActive(agent: Agent, active: boolean)
	if agent.Active ~= active then
		agent.Active = active
		agent.Model.Parent = if active then folder else nil
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

-- Tipos de peatón (con su probabilidad): paseando, corriendo, con el perro, con bolsas de la
-- compra, mirando el móvil o niños. Si llueve, casi todos sacan el paraguas.
local STYLES = { { "Walk", 30 }, { "Jog", 10 }, { "Dog", 12 }, { "Bag", 16 }, { "Phone", 14 }, { "Kid", 12 } }
local DOG_COLORS = { Color3.fromRGB(150, 100, 60), Color3.fromRGB(40, 36, 34), Color3.fromRGB(230, 220, 200), Color3.fromRGB(200, 150, 80) }
local UMBRELLA_COLORS = { Color3.fromRGB(30, 30, 34), Color3.fromRGB(200, 40, 50), Color3.fromRGB(40, 80, 170), Color3.fromRGB(240, 200, 40), Color3.fromRGB(120, 60, 140) }

local function pickStyle(): string
	local total = 0
	for _, s in STYLES do
		total += s[2]
	end
	local r = math.random() * total
	for _, s in STYLES do
		r -= s[2]
		if r <= 0 then
			return s[1]
		end
	end
	return "Walk"
end

local function raining(): boolean
	local weather = workspace:GetAttribute("Weather")
	return weather == "Lluvia" or weather == "Tormenta"
end

-- Figura de peatón: 1 torso, 2 cabeza, 3 pelo, 4-5 piernas, 6-7 brazos y luego los extras
-- (paraguas, bolsa, móvil, perro y correa) según el tipo
local function makePed(): Agent
	local model = Instance.new("Model")
	model.Name = "Peaton"
	local style = pickStyle()
	local scale = if style == "Kid" then 0.68 else 1
	local skin, shirt, pants = pick(SKIN), pick(CLOTHES), pick(PANTS)
	if style == "Jog" then
		shirt, pants = pick({ Color3.fromRGB(250, 120, 40), Color3.fromRGB(60, 200, 220), Color3.fromRGB(240, 240, 240), Color3.fromRGB(230, 60, 120) }), Color3.fromRGB(30, 30, 34)
	end
	local s = scale
	local specs = {
		{ "Torso", Vector3.new(2, 2.3, 1.1) * s, shirt, Enum.PartType.Block },
		{ "Head", Vector3.new(1.3, 1.3, 1.3) * s, skin, Enum.PartType.Ball },
		{ "Hair", Vector3.new(1.4, 0.55, 1.4) * s, pick(HAIR), Enum.PartType.Block },
		{ "LegL", Vector3.new(0.9, 2.4, 0.95) * s, pants, Enum.PartType.Block },
		{ "LegR", Vector3.new(0.9, 2.4, 0.95) * s, pants, Enum.PartType.Block },
		{ "ArmL", Vector3.new(0.7, 2.2, 0.75) * s, shirt, Enum.PartType.Block },
		{ "ArmR", Vector3.new(0.7, 2.2, 0.75) * s, shirt, Enum.PartType.Block },
		-- Paraguas (se esconde si no llueve)
		{ "UmbrellaStick", Vector3.new(0.12, 3.2, 0.12), Color3.fromRGB(50, 50, 54), Enum.PartType.Block },
		{ "Umbrella", Vector3.new(0.5, 5.2, 5.2), pick(UMBRELLA_COLORS), Enum.PartType.Cylinder },
	}
	if style == "Bag" then
		table.insert(specs, { "Bag", Vector3.new(0.5, 1.3, 1.1), pick({ Color3.fromRGB(240, 236, 226), Color3.fromRGB(60, 140, 80), Color3.fromRGB(200, 60, 50) }), Enum.PartType.Block })
	elseif style == "Phone" then
		table.insert(specs, { "Phone", Vector3.new(0.5, 0.9, 0.12), Color3.fromRGB(20, 20, 24), Enum.PartType.Block })
	elseif style == "Dog" then
		local fur = pick(DOG_COLORS)
		table.insert(specs, { "DogBody", Vector3.new(0.9, 0.9, 2.2), fur, Enum.PartType.Block })
		table.insert(specs, { "DogHead", Vector3.new(0.8, 0.8, 0.9), fur, Enum.PartType.Block })
		table.insert(specs, { "DogSnout", Vector3.new(0.45, 0.4, 0.4), fur:Lerp(Color3.new(0, 0, 0), 0.3), Enum.PartType.Block })
		for _, name in { "DogLegFL", "DogLegFR", "DogLegBL", "DogLegBR" } do
			table.insert(specs, { name, Vector3.new(0.28, 0.9, 0.28), fur, Enum.PartType.Block })
		end
		table.insert(specs, { "DogTail", Vector3.new(0.18, 0.18, 0.9), fur, Enum.PartType.Block })
		table.insert(specs, { "Leash", Vector3.new(0.08, 0.08, 1), Color3.fromRGB(200, 40, 40), Enum.PartType.Block })
	end
	local parts, index = {}, {}
	for _, spec in specs do
		local p = Instance.new("Part")
		p.Name = spec[1]
		p.Size = spec[2]
		p.Color = spec[3]
		p.Shape = spec[4]
		p.Material = if spec[1] == "Umbrella" then Enum.Material.Fabric else Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = spec[1] ~= "Leash"
		p.Parent = model
		table.insert(parts, p)
		index[spec[1]] = #parts
	end
	return {
		Model = model,
		Parts = parts,
		Offsets = {},
		Road = nil,
		U = 0,
		Dir = 1,
		Speed = 0,
		Cruise = 0,
		Side = 1,
		Phase = math.random() * 6,
		Active = false,
		Style = style,
		Scale = scale,
		Index = index,
		Umbrella = false,
	}
end

local function respawnPed(agent: Agent, center: Vector3, initial: boolean)
	local road, u = spawnPoint(center, if initial then 10 else 90, 200)
	if road and not road.Walk then
		road = nil -- las autovías no tienen acera
	end
	agent.Road = road
	if not road then
		setActive(agent, false)
		return
	end
	agent.U = u
	agent.Dir = if math.random() < 0.5 then 1 else -1
	agent.Side = if math.random() < 0.5 then 1 else -1
	local style = agent.Style
	agent.Cruise = if style == "Jog" then 9 + math.random() * 2.5
		elseif style == "Kid" then 4 + math.random() * 1.5
		elseif style == "Dog" or style == "Phone" then 3.5 + math.random() * 1.5
		else 4.5 + math.random() * 2.5
	agent.Speed = agent.Cruise
	-- Paraguas: casi todos lo sacan si llueve (los que corren, no)
	agent.Umbrella = raining() and style ~= "Jog" and math.random() < 0.85
	local stick, canopy = agent.Parts[agent.Index.UmbrellaStick], agent.Parts[agent.Index.Umbrella]
	stick.Transparency = if agent.Umbrella then 0 else 1
	canopy.Transparency = if agent.Umbrella then 0 else 1
	setActive(agent, true)
end

local function posePed(agent: Agent, root: CFrame)
	local s = agent.Scale
	local jog = agent.Style == "Jog"
	local swing = math.sin(agent.Phase) * (if jog then 0.95 else 0.55)
	local bob = math.abs(math.cos(agent.Phase)) * (if jog then 0.35 else 0.12) * s
	local base = root * CFrame.new(0, bob, 0)
	if jog then
		base *= CFrame.Angles(-0.12, 0, 0) -- inclinado hacia delante
	end
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x * s, y * s, z * s)
	end
	local armL = at(-1.38, 4.55, 0) * CFrame.Angles(-swing * 0.8, 0, 0) * CFrame.new(0, -1.05 * s, 0)
	local armR = at(1.38, 4.55, 0) * CFrame.Angles(swing * 0.8, 0, 0) * CFrame.new(0, -1.05 * s, 0)
	if agent.Umbrella then
		armL = at(-1.38, 4.55, 0) * CFrame.Angles(0.9, 0, 0.15) * CFrame.new(0, -1.05 * s, 0)
	end
	if agent.Style == "Phone" then
		armR = at(1.38, 4.55, 0) * CFrame.Angles(1.3, 0, 0.35) * CFrame.new(0, -1.05 * s, 0)
	elseif agent.Style == "Bag" then
		armR = at(1.38, 4.55, 0) * CFrame.Angles(swing * 0.25, 0, 0) * CFrame.new(0, -1.05 * s, 0)
	end
	local cframes = {
		at(0, 3.55, 0), -- torso
		at(0, 5.35, 0), -- cabeza
		at(0, 5.95, 0.05), -- pelo
		at(-0.48, 2.4, 0) * CFrame.Angles(swing, 0, 0) * CFrame.new(0, -1.2 * s, 0),
		at(0.48, 2.4, 0) * CFrame.Angles(-swing, 0, 0) * CFrame.new(0, -1.2 * s, 0),
		armL,
		armR,
	}
	local rot = base.Rotation
	-- Paraguas en la mano izquierda, abierto encima de la cabeza
	local handL = (armL * CFrame.new(0, -1.05 * s, 0)).Position
	local stickTop = handL + Vector3.new(0, 3, 0)
	cframes[8] = CFrame.new(handL + Vector3.new(0, 1.5, 0)) * rot
	cframes[9] = CFrame.new(stickTop + Vector3.new(0, 0.1, 0)) * rot * CFrame.Angles(0, 0, math.rad(90))
	local handR = (armR * CFrame.new(0, -1.05 * s, 0)).Position
	local i = agent.Index
	if i.Bag then
		cframes[i.Bag] = CFrame.new(handR - Vector3.new(0, 0.75, 0)) * rot
	elseif i.Phone then
		cframes[i.Phone] = CFrame.new(handR + rot:VectorToWorldSpace(Vector3.new(-0.25, 0.25, -0.1))) * rot * CFrame.Angles(math.rad(-20), 0, 0)
	elseif i.DogBody then
		-- El perro trota a la derecha, un poco por delante, con la correa en la mano
		local trot = agent.Phase * 1.6
		local dog = root * CFrame.new(2.4, math.abs(math.sin(trot)) * 0.12, -1.8)
		cframes[i.DogBody] = dog * CFrame.new(0, 1.35, 0)
		cframes[i.DogHead] = dog * CFrame.new(0, 1.95, -1.3)
		cframes[i.DogSnout] = dog * CFrame.new(0, 1.8, -1.9)
		local leg = math.sin(trot) * 0.6
		cframes[i.DogLegFL] = dog * CFrame.new(-0.3, 0.9, -0.75) * CFrame.Angles(leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogLegFR] = dog * CFrame.new(0.3, 0.9, -0.75) * CFrame.Angles(-leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogLegBL] = dog * CFrame.new(-0.3, 0.9, 0.75) * CFrame.Angles(-leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogLegBR] = dog * CFrame.new(0.3, 0.9, 0.75) * CFrame.Angles(leg, 0, 0) * CFrame.new(0, -0.45, 0)
		cframes[i.DogTail] = dog * CFrame.new(0, 1.85, 1.3) * CFrame.Angles(math.rad(35), math.sin(agent.Phase * 4) * 0.5, 0)
		local collar = (dog * CFrame.new(0, 1.7, -0.9)).Position
		local mid = (handR + collar) / 2
		local leash = agent.Parts[i.Leash]
		local length = (collar - handR).Magnitude
		if math.abs(leash.Size.Z - length) > 0.05 then
			leash.Size = Vector3.new(0.08, 0.08, length)
		end
		cframes[i.Leash] = CFrame.lookAt(mid, collar)
	end
	workspace:BulkMoveTo(agent.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local function updatePeds(dt: number, center: Vector3)
	local clock = Lighting.ClockTime
	local night = clock < 7 or clock > 21.5
	for i, ped in peds do
		-- De noche solo sale una parte de la gente (y ningún niño)
		local wanted = not night or (i % 3 == 0 and ped.Style ~= "Kid")
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
		ped.Phase += dt * ped.Speed * (if ped.Style == "Kid" then 2.1 elseif ped.Style == "Jog" then 1.1 else 1.5)
		local pos = point(road, ped.U, ped.Side * (road.Walk or 15.5), WALK_TOP)
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
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and (b - a).Magnitude > 20 then
			local dir = (b - a).Unit
			local width = config:GetAttribute("Width") or 24
			local kind = config:GetAttribute("Kind")
			table.insert(roads, {
				A = a,
				Dir = dir,
				Perp = Vector3.new(-dir.Z, 0, dir.X),
				From = 0,
				To = (b - a).Magnitude,
				Lane = if width > 30 then width * 0.2 else 2.9,
				Walk = if kind == "Autovia" then nil else width / 2 + 3.5, -- centro de la acera
			})
		end
	end
	if #roads == 0 then
		return
	end

	folder = Instance.new("Folder")
	folder.Name = "AmbientLife"
	folder.Parent = workspace

	for _ = 1, PED_COUNT do
		table.insert(peds, makePed())
	end

	-- Primera colocación repartida alrededor del jugador
	local center = focus() or Vector3.zero
	for _, ped in peds do
		respawnPed(ped, center, true)
	end

	Traffic.init(data)

	RunService.RenderStepped:Connect(function(dt)
		local c = focus()
		if not c then
			return
		end
		Traffic.update(dt)
		updatePeds(math.min(dt, 0.1), c)
	end)
end

return Ambient
