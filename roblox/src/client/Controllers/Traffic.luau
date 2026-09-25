-- Traffic (cliente): coches, taxis, motos, bicis y patinetes conducidos por NPCs.
-- Se simula en cada dispositivo y solo cerca del jugador (sin coste de red ni de servidor).
--  * Circulan por la red de calles entera (el mismo grafo que usa el autobús, BusRoute):
--    al llegar a un cruce eligen seguir recto o girar, y giran con una curva suave.
--  * Van por la derecha; las bicis y los patinetes, más pegados a la acera y más despacio.
--    Las bicis y patinetes no se meten en la autovía si pueden evitarlo.
--  * Guardan distancia con el de delante y frenan si el jugador se pone delante.
--  * Semáforos: las luces cambian (verde, ámbar, rojo) igual para todos los jugadores y los
--    vehículos paran en rojo antes del cruce.
--  * Detalles: luces de freno al frenar, intermitentes antes de girar, faros de noche,
--    taxis con la luz verde, ciclistas pedaleando y conductores con ropa y casco variados.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BusRoute = require(ReplicatedStorage.Shared.BusRoute)

local Traffic = {}

local player = Players.LocalPlayer

local ROAD_TOP = 0.4
local CELL = 100 -- rejilla para buscar cruces cercanos
local SPAWN_MIN, SPAWN_MAX, DESPAWN = 150, 330, 420
local DECEL = 26 -- frenada (studs/s²)

-- Tipos de vehículo: cuántos hay alrededor del jugador y cómo circulan
local KINDS = {
	Car = { Count = 18, Cruise = { 26, 40 }, Length = 13.5, Small = false },
	Moto = { Count = 4, Cruise = { 30, 42 }, Length = 6, Small = false },
	Bici = { Count = 5, Cruise = { 11, 16 }, Length = 5, Small = true },
	Patinete = { Count = 3, Cruise = { 12, 15 }, Length = 4, Small = true },
}

local SKIN = { Color3.fromRGB(255, 219, 182), Color3.fromRGB(234, 184, 146), Color3.fromRGB(198, 140, 100), Color3.fromRGB(141, 94, 64), Color3.fromRGB(96, 64, 44) }
local SHIRT = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(50, 90, 170), Color3.fromRGB(40, 140, 90), Color3.fromRGB(230, 200, 70), Color3.fromRGB(240, 240, 240), Color3.fromRGB(40, 40, 44), Color3.fromRGB(150, 80, 160), Color3.fromRGB(240, 140, 60) }
local PANTS = { Color3.fromRGB(40, 50, 90), Color3.fromRGB(30, 30, 34), Color3.fromRGB(110, 90, 70), Color3.fromRGB(80, 80, 86), Color3.fromRGB(60, 80, 120) }
local HELMET = { Color3.fromRGB(240, 240, 240), Color3.fromRGB(30, 30, 34), Color3.fromRGB(200, 40, 40), Color3.fromRGB(40, 90, 180), Color3.fromRGB(250, 200, 40) }
local TINTS = { Skin = SKIN, Shirt = SHIRT, Pants = PANTS, Helmet = HELMET }

type Edge = { To: number, Cost: number, W: number, Kind: string? }
type Agent = {
	Model: Model,
	Kind: string,
	Small: boolean,
	Length: number,
	Parts: { BasePart },
	Offsets: { CFrame },
	Pedals: { { Index: number, Pivot: Vector3, Side: number } },
	Tails: { BasePart },
	Indicators: { { Part: BasePart, Side: number } },
	Active: boolean,
	From: number,
	To: number,
	Next: number,
	S: number,
	Speed: number,
	Cruise: number,
	Braking: boolean,
	Turn: number, -- -1 izquierda, 0 recto, 1 derecha
	Phase: number,
}

local nodes: { Vector3 } = {}
local edges: { { Edge } } = {}
local cells: { [string]: { number } } = {}
local lightNodes: { [number]: boolean } = {}
local agents: { Agent } = {}
local folder: Folder
local night = false

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

local function edgeOf(from: number, to: number): Edge?
	for _, e in edges[from] do
		if e.To == to then
			return e
		end
	end
	return nil
end

-- Distancia del centro de la calzada al carril (por la derecha)
local function laneOf(edge: Edge?, small: boolean): number
	local w = if edge then edge.W else 24
	local lane = if w > 30 then w * 0.2 else 2.9
	if small then
		lane = math.min(lane + 3.2, w / 2 - 2)
	end
	return lane
end

local function radiusOf(length: number): number
	return math.min(9, length * 0.4)
end

local function right(d: Vector3): Vector3
	return Vector3.new(-d.Z, 0, d.X)
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

---------------------------------------------------------------------
-- Semáforos (mismo ciclo para todos: se calcula con la hora del servidor)
---------------------------------------------------------------------
local CYCLE = 30

-- Estado del semáforo para quien circula a lo largo del eje X o Z
local function signal(axis: string): string
	local t = workspace:GetServerTimeNow() % CYCLE
	if axis == "X" then
		return if t < 12 then "Green" elseif t < 15 then "Yellow" else "Red"
	end
	return if t < 15 then "Red" elseif t < 27 then "Green" else "Yellow"
end

type Light = { Axis: string, Lamps: { { Part: BasePart, Role: string } } }
local lights: { [Model]: Light } = {}

local LAMP_ON = { Red = Color3.fromRGB(255, 40, 40), Yellow = Color3.fromRGB(255, 190, 30), Green = Color3.fromRGB(60, 255, 120) }
local LAMP_OFF = { Red = Color3.fromRGB(90, 20, 20), Yellow = Color3.fromRGB(90, 70, 20), Green = Color3.fromRGB(20, 70, 36) }

local function nearestNode(p: Vector3, maxDist: number): number?
	local kx, kz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
	local best, bestDist = nil, maxDist
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, id in cells[(kx + dx) .. ":" .. (kz + dz)] or {} do
				local d = (Vector3.new(p.X, 0, p.Z) - nodes[id]).Magnitude
				if d < bestDist then
					best, bestDist = id, d
				end
			end
		end
	end
	return best
end

local function addLight(model: Instance)
	if not model:IsA("Model") or lights[model] then
		return
	end
	local arm = model:FindFirstChild("Arm") :: BasePart?
	local box = model:FindFirstChild("Box") :: BasePart?
	if not arm or not box then
		return
	end
	local look = arm.CFrame.LookVector
	-- Las luces miran perpendiculares al brazo: controlan el tráfico que va a lo largo de la calle de debajo
	local light: Light = { Axis = if math.abs(look.X) > math.abs(look.Z) then "Z" else "X", Lamps = {} }
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part.Name == "Light" then
			local dy = box.CFrame:PointToObjectSpace(part.CFrame.Position).Y
			table.insert(light.Lamps, { Part = part, Role = if dy > 0.5 then "Red" elseif dy < -0.5 then "Green" else "Yellow" })
		end
	end
	lights[model] = light
	local node = nearestNode(arm.CFrame.Position, 40)
	if node then
		lightNodes[node] = true
	end
end

local shown: { [string]: string } = {}
local function refreshLights()
	local state = { X = signal("X"), Z = signal("Z") }
	if shown.X == state.X and shown.Z == state.Z then
		return
	end
	shown.X, shown.Z = state.X, state.Z
	for model, light in lights do
		if not model.Parent then
			lights[model] = nil
			continue
		end
		local on = state[light.Axis]
		for _, lamp in light.Lamps do
			local lit = lamp.Role == on
			lamp.Part.Color = if lit then LAMP_ON[lamp.Role] else LAMP_OFF[lamp.Role]
			lamp.Part.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

---------------------------------------------------------------------
-- Vehículos
---------------------------------------------------------------------
local headlights: { SpotLight } = {}

local function makeAgent(template: Model, kind: string): Agent
	local info = KINDS[kind]
	local model = template:Clone()
	local agent: Agent = {
		Model = model,
		Kind = kind,
		Small = info.Small,
		Length = info.Length,
		Parts = {},
		Offsets = {},
		Pedals = {},
		Tails = {},
		Indicators = {},
		Active = false,
		From = 0,
		To = 0,
		Next = 0,
		S = 0,
		Speed = 0,
		Cruise = 0,
		Braking = false,
		Turn = 0,
		Phase = math.random() * 6,
	}
	local tints = {}
	for name, list in TINTS do
		tints[name] = pick(list)
	end
	local lamp = false
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			local tint = d:GetAttribute("Tint")
			if tint and tints[tint] then
				d.Color = tints[tint]
			end
			table.insert(agent.Parts, d)
			table.insert(agent.Offsets, d.CFrame)
			if d.Name == "PedalLeg" then
				local pivot = d:GetAttribute("Pivot")
				table.insert(agent.Pedals, { Index = #agent.Parts, Pivot = if typeof(pivot) == "Vector3" then pivot else d.CFrame.Position, Side = d:GetAttribute("Side") or 1 })
			elseif d.Name == "Taillight" or d.Name == "ThirdBrake" then
				table.insert(agent.Tails, d)
			elseif d.Name == "IndicatorFront" or d.Name == "IndicatorRear" or d.Name == "Indicator" then
				table.insert(agent.Indicators, { Part = d, Side = if d.CFrame.X > 0 then 1 else -1 })
				d.Material = Enum.Material.SmoothPlastic
			elseif d.Name == "Headlight" and not lamp then
				lamp = true
				local light = Instance.new("SpotLight")
				light.Face = Enum.NormalId.Front
				light.Angle = 55
				light.Range = if kind == "Car" then 42 else 26
				light.Brightness = if kind == "Car" then 3 else 2
				light.Color = Color3.fromRGB(255, 244, 222)
				light.Shadows = false
				light.Enabled = night
				light.Parent = d
				table.insert(headlights, light)
			end
		elseif d:IsA("Seat") or d:IsA("VehicleSeat") or d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
	return agent
end

local function setActive(agent: Agent, active: boolean)
	if agent.Active ~= active then
		agent.Active = active
		agent.Model.Parent = if active then folder else nil
	end
end

-- Siguiente cruce: mejor seguir recto; las bicis evitan la autovía; si no hay salida, da la vuelta
local function chooseNext(agent: Agent): number
	local from, at = agent.From, agent.To
	local d1 = (nodes[at] - nodes[from]).Unit
	local options, total = {}, 0
	local fallback = {}
	for _, e in edges[at] do
		if e.To ~= from then
			local d2 = (nodes[e.To] - nodes[at]).Unit
			local w = if d1:Dot(d2) > 0.8 then 3 elseif d1:Dot(d2) < -0.5 then 0.2 else 1
			if agent.Small and e.Kind == "Autovia" then
				table.insert(fallback, e.To)
			else
				table.insert(options, { e.To, w })
				total += w
			end
		end
	end
	if #options == 0 then
		return if #fallback > 0 then pick(fallback) else from
	end
	local r = math.random() * total
	for _, o in options do
		r -= o[2]
		if r <= 0 then
			return o[1]
		end
	end
	return options[#options][1]
end

local function updateTurn(agent: Agent)
	local d1 = (nodes[agent.To] - nodes[agent.From]).Unit
	local d2 = (nodes[agent.Next] - nodes[agent.To]).Unit
	local cross = d1.X * d2.Z - d1.Z * d2.X
	agent.Turn = if cross > 0.3 then 1 elseif cross < -0.3 then -1 else 0
end

-- Posición y dirección del vehículo según su tramo y lo que ha avanzado (con la curva del cruce)
local function pose(agent: Agent): (Vector3, Vector3)
	local a, b = nodes[agent.From], nodes[agent.To]
	local L = (b - a).Magnitude
	local d1 = (b - a).Unit
	local e1 = edgeOf(agent.From, agent.To)
	local l1 = laneOf(e1, agent.Small)
	local rin = radiusOf(L)
	if agent.S <= L - rin then
		return a + d1 * agent.S + right(d1) * l1, d1
	end
	local c = nodes[agent.Next]
	local L2 = (c - b).Magnitude
	local d2 = if L2 > 0.01 then (c - b).Unit else -d1
	local l2 = laneOf(edgeOf(agent.To, agent.Next), agent.Small)
	local rout = radiusOf(L2)
	local p0 = b - d1 * rin + right(d1) * l1
	local p2 = b + d2 * rout + right(d2) * l2
	local ctrl = b + (right(d1) * l1 + right(d2) * l2) / math.max(1 + d1:Dot(d2), 0.5)
	local t = math.clamp((agent.S - (L - rin)) / (rin + rout), 0, 1)
	local q0, q1 = p0:Lerp(ctrl, t), ctrl:Lerp(p2, t)
	local dir = q1 - q0
	return q0:Lerp(q1, t), if dir.Magnitude > 0.01 then dir.Unit else d2
end

local function edgeLength(from: number, to: number): number
	return (nodes[to] - nodes[from]).Magnitude
end

-- Puntos de aparición: cada 40 studs a lo largo de cada tramo (las calles largas del centro
-- apenas tienen cruces, así que no basta con aparecer junto a los cruces)
type Spot = { From: number, To: number, S: number, Pos: Vector3 }
local spots: { [string]: { Spot } } = {}

local function nearbySpots(center: Vector3, maxDist: number): { Spot }
	local list = {}
	local r = math.ceil(maxDist / CELL)
	local kx, kz = math.floor(center.X / CELL), math.floor(center.Z / CELL)
	for dx = -r, r do
		for dz = -r, r do
			for _, spot in spots[(kx + dx) .. ":" .. (kz + dz)] or {} do
				table.insert(list, spot)
			end
		end
	end
	return list
end

local function respawn(agent: Agent, center: Vector3, minDist: number)
	local list = nearbySpots(center, SPAWN_MAX)
	local flat = Vector3.new(center.X, 0, center.Z)
	for _ = 1, 12 do
		if #list == 0 then
			break
		end
		local spot = list[math.random(1, #list)]
		local dist = (spot.Pos - flat).Magnitude
		if dist < minDist or dist > SPAWN_MAX then
			continue
		end
		-- Sentido al azar
		local from, to, s = spot.From, spot.To, spot.S
		if math.random() < 0.5 then
			from, to, s = to, from, edgeLength(from, to) - s
		end
		local e = edgeOf(from, to)
		if not e or (agent.Small and e.Kind == "Autovia") then
			continue
		end
		-- Que no aparezca encima de otro
		local clash = false
		for _, other in agents do
			if other ~= agent and other.Active and other.From == from and other.To == to and math.abs(other.S - s) < 16 then
				clash = true
				break
			end
		end
		if not clash then
			agent.From, agent.To, agent.S = from, to, s
			agent.Next = chooseNext(agent)
			updateTurn(agent)
			local range = KINDS[agent.Kind].Cruise
			agent.Cruise = range[1] + math.random() * (range[2] - range[1])
			agent.Speed = agent.Cruise * 0.8
			setActive(agent, true)
			return
		end
	end
	setActive(agent, false)
end

-- Espacio libre por delante (otro vehículo, un semáforo en rojo o el jugador)
local function freeGap(agent: Agent, pos: Vector3, dir: Vector3, me: BasePart?): number
	local gap = math.huge
	local L = edgeLength(agent.From, agent.To)
	for _, other in agents do
		if other == agent or not other.Active or (other.Small and not agent.Small) then
			continue
		end
		local half = (other.Length + agent.Length) / 2
		if other.From == agent.From and other.To == agent.To and other.S > agent.S then
			gap = math.min(gap, other.S - agent.S - half)
		elseif other.From == agent.To and other.To == agent.Next then
			gap = math.min(gap, L - agent.S + other.S - half)
		end
	end
	-- Semáforo antes del cruce
	if lightNodes[agent.To] then
		local stopAt = L - 16
		local d = (nodes[agent.To] - nodes[agent.From]).Unit
		local state = signal(if math.abs(d.X) > math.abs(d.Z) then "X" else "Z")
		local toLine = stopAt - agent.S - agent.Length / 2
		if toLine > -1 and (state == "Red" or (state == "Yellow" and toLine > 10)) then
			gap = math.min(gap, math.max(toLine, 0))
		end
	end
	if me then
		local rel = me.Position - pos
		local ahead = rel:Dot(dir)
		local lateral = math.abs(rel:Dot(right(dir)))
		if ahead > 0 and ahead < 22 and lateral < 4.5 and math.abs(rel.Y) < 8 then
			gap = math.min(gap, ahead - agent.Length / 2 - 2)
		end
	end
	return gap
end

local TAIL_DIM, TAIL_BRAKE = Color3.fromRGB(150, 14, 22), Color3.fromRGB(255, 36, 44)
local IND_ON, IND_OFF = Color3.fromRGB(255, 160, 30), Color3.fromRGB(150, 90, 30)

local function setBraking(agent: Agent, braking: boolean)
	if agent.Braking == braking then
		return
	end
	agent.Braking = braking
	for _, tail in agent.Tails do
		tail.Color = if braking then TAIL_BRAKE else TAIL_DIM
		tail.Material = if braking or night then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

local function place(agent: Agent, pos: Vector3, dir: Vector3)
	local root = CFrame.lookAt(Vector3.new(pos.X, ROAD_TOP, pos.Z), Vector3.new(pos.X + dir.X, ROAD_TOP, pos.Z + dir.Z))
	local cframes = table.create(#agent.Parts)
	for i, offset in agent.Offsets do
		cframes[i] = root * offset
	end
	-- Piernas del ciclista: giran en la cadera al ritmo de los pedales
	for _, pedal in agent.Pedals do
		local swing = math.sin(agent.Phase + (if pedal.Side > 0 then 0 else math.pi)) * 0.45
		cframes[pedal.Index] = root * CFrame.new(pedal.Pivot) * CFrame.Angles(swing, 0, 0) * CFrame.new(-pedal.Pivot) * agent.Offsets[pedal.Index]
	end
	workspace:BulkMoveTo(agent.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local blink = 0
local function step(dt: number, center: Vector3)
	local character = player.Character
	local me = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	blink += dt
	local blinkOn = (blink % 0.8) < 0.4
	for _, agent in agents do
		if not agent.Active then
			if math.random() < 0.1 then -- no buscar sitio en cada fotograma
				respawn(agent, center, SPAWN_MIN)
			end
			continue
		end
		local pos, dir = pose(agent)
		if (pos - Vector3.new(center.X, 0, center.Z)).Magnitude > DESPAWN then
			respawn(agent, center, SPAWN_MIN)
			continue
		end
		local edge = edgeOf(agent.From, agent.To)
		local cruise = agent.Cruise * (if edge and edge.Kind == "Autovia" and not agent.Small then 1.5 else 1)
		if agent.Turn ~= 0 then
			cruise = math.min(cruise, 24) -- más despacio al girar
		end
		local gap = freeGap(agent, pos, dir, me)
		local target = math.min(cruise, math.sqrt(2 * DECEL * math.max(gap - 1.5, 0)))
		local change = math.clamp(target - agent.Speed, -DECEL * 2 * dt, 14 * dt)
		agent.Speed = math.max(agent.Speed + change, 0)
		setBraking(agent, change < -1 * dt or agent.Speed < 0.5)
		agent.S += agent.Speed * dt
		agent.Phase += dt * agent.Speed * 0.55

		local L = edgeLength(agent.From, agent.To)
		local L2 = edgeLength(agent.To, agent.Next)
		if agent.S >= L + radiusOf(L2) then
			-- Pasa al siguiente tramo
			agent.S -= L
			agent.From, agent.To = agent.To, agent.Next
			agent.Next = chooseNext(agent)
			updateTurn(agent)
			pos, dir = pose(agent)
		end
		-- Intermitentes en los últimos metros antes de girar
		local signalling = agent.Turn ~= 0 and L - agent.S < 45 and blinkOn
		for _, ind in agent.Indicators do
			local on = signalling and ind.Side == agent.Turn
			ind.Part.Color = if on then IND_ON else IND_OFF
			ind.Part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
		place(agent, pos, dir)
	end
end

---------------------------------------------------------------------

function Traffic.init(data: Instance)
	local roads = {}
	for _, config in data:WaitForChild("Roads"):GetChildren() do
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and (b - a).Magnitude > 10 then
			table.insert(roads, { A = a, B = b, Width = config:GetAttribute("Width") or 24, Kind = config:GetAttribute("Kind") })
		end
	end
	if #roads == 0 then
		return
	end
	local graph = BusRoute.graph(roads, {})
	nodes, edges = graph.Nodes, graph.Edges
	for id, p in nodes do
		local key = math.floor(p.X / CELL) .. ":" .. math.floor(p.Z / CELL)
		cells[key] = cells[key] or {}
		table.insert(cells[key], id)
	end
	for from, list in edges do
		for _, e in list do
			if from < e.To then
				local L = e.Cost
				local r = radiusOf(L)
				local s = r + 5
				while s < L - r - 5 do
					local p = nodes[from] + (nodes[e.To] - nodes[from]).Unit * s
					local key = math.floor(p.X / CELL) .. ":" .. math.floor(p.Z / CELL)
					spots[key] = spots[key] or {}
					table.insert(spots[key], { From = from, To = e.To, S = s, Pos = p })
					s += 40
				end
			end
		end
	end

	folder = Instance.new("Folder")
	folder.Name = "Traffic"
	folder.Parent = workspace

	local cars = data:WaitForChild("Cars"):GetChildren()
	local riders = data:FindFirstChild("Riders")
	local byKind: { [string]: { Model } } = { Car = {} }
	for _, m in cars do
		if m:IsA("Model") then
			table.insert(byKind.Car, m)
		end
	end
	for _, m in if riders then riders:GetChildren() else {} do
		local kind = m:GetAttribute("Kind")
		if m:IsA("Model") and kind and KINDS[kind] then
			byKind[kind] = byKind[kind] or {}
			table.insert(byKind[kind], m)
		end
	end
	for kind, info in KINDS do
		local templates = byKind[kind]
		if templates and #templates > 0 then
			for i = 1, info.Count do
				table.insert(agents, makeAgent(templates[(i - 1) % #templates + 1], kind))
			end
		end
	end

	for _, model in CollectionService:GetTagged("TrafficLight") do
		addLight(model)
	end
	CollectionService:GetInstanceAddedSignal("TrafficLight"):Connect(addLight)

	local center = focus() or Vector3.zero
	for _, agent in agents do
		respawn(agent, center, 30)
	end

	-- Faros y pilotos encendidos al anochecer; semáforos
	task.spawn(function()
		while true do
			local clock = Lighting.ClockTime
			local on = clock >= 18.3 or clock < 7.2
			if on ~= night then
				night = on
				for _, light in headlights do
					light.Enabled = on
				end
				for _, agent in agents do
					agent.Braking = not agent.Braking -- fuerza a repintar los pilotos
					setBraking(agent, not agent.Braking)
				end
			end
			refreshLights()
			task.wait(0.5)
		end
	end)
end

function Traffic.update(dt: number)
	if #agents == 0 then
		return
	end
	local c = focus()
	if c then
		step(math.min(dt, 0.1), c)
	end
end

return Traffic
