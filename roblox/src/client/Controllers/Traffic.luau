-- Traffic (cliente): coches, taxis, motos, bicis y patinetes conducidos por NPCs.
-- Se simula en cada dispositivo y solo cerca del jugador (sin coste de red ni de servidor).
--  * Circulan por la red de calles entera (el mismo grafo que usa el autobús, BusRoute):
--    al llegar a un cruce eligen seguir recto o girar, y giran con una curva suave.
--  * Van por la derecha; las bicis y los patinetes, más pegados a la acera y más despacio.
--    Las bicis y patinetes no se meten en la autovía si pueden evitarlo.
--  * Guardan distancia con el de delante (también con las bicis, si van por su mismo carril), frenan
--    si se pone delante un jugador (o su coche entero), o un peatón cruzando, y en los cruces sin
--    semáforo pasan de uno en uno. Si llevan un rato parados detrás de ti, te pitan («¡Piii!»).
--  * Aparecen y se retiran fuera de tu vista (detrás de la cámara o muy lejos), no delante de ti.
--  * Con lluvia o nieve van más despacio (shared/Wetness).
--  * Semáforos: las luces cambian (verde, ámbar, rojo) igual para todos los jugadores y los
--    vehículos paran en rojo antes del cruce.
--  * En las rotondas dan la vuelta por el anillo (dejando la isla a la izquierda), a la velocidad de
--    siempre, y salen por la calle que toque.
--  * Detalles: luces de freno al frenar, intermitentes antes de girar, faros de noche,
--    taxis con la luz verde, ciclistas pedaleando y conductores con ropa y casco variados.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BusRoute = require(ReplicatedStorage.Shared.BusRoute)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Wetness = require(ReplicatedStorage.Shared.Wetness)
local Perf = require(script.Parent.Parent.UI.Perf)
local Nudge = require(script.Parent.Nudge)

local Traffic = {}

local player = Players.LocalPlayer

local ROAD_TOP = 0.4
local CELL = 100 -- rejilla para buscar cruces cercanos
local SPAWN_MIN, SPAWN_MAX, DESPAWN = 150, 330, 420
local HIDDEN = 200 -- más cerca que esto, solo aparecen (o se retiran) fuera de la vista de la cámara
local DECEL = 26 -- frenada (studs/s²)

-- Tipos de vehículo: cuántos hay alrededor del jugador y cómo circulan
-- (Width: el ancho, para ver si dos vehículos en carriles distintos se rozan)
local KINDS = {
	Car = { Count = 20, Cruise = { 26, 40 }, Length = 13.5, Width = 6.6, Small = false },
	Moto = { Count = 4, Cruise = { 30, 42 }, Length = 6, Width = 2.2, Small = false },
	Bici = { Count = 6, Cruise = { 11, 16 }, Length = 5, Width = 1.8, Small = true },
	Patinete = { Count = 3, Cruise = { 12, 15 }, Length = 4, Width = 1.4, Small = true },
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
	Width: number,
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
	Look: Vector3?, -- hacia dónde mira el morro (suavizado)
	StuckAt: number?, -- desde cuándo está parado detrás del jugador
	HonkAt: number?,
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
		-- (bien pegadas a la acera: un coche en su carril pasa a su lado sin rozarlas)
		lane = math.min(lane + 4.4, w / 2 - 2)
	end
	return lane
end

local function radiusOf(length: number): number
	return math.min(9, length * 0.4)
end

-- Rotondas: nodo del grafo → centro de la rotonda. Se da la vuelta por el anillo a este radio
-- (entre la isla, de radio 22, y el borde, de 56)
local RING_LANE = 44
local roundabout: { [number]: Vector3 } = {}

-- Radio de la curva al llegar a (o salir de) un nodo por un tramo de largo "length"
local function turnRadius(node: number, length: number): number
	if roundabout[node] then
		return math.min(RING_LANE, length - 1)
	end
	return radiusOf(length)
end

local function right(d: Vector3): Vector3
	return Vector3.new(-d.Z, 0, d.X)
end

-- Pasos a nivel cerrados (los pone Controllers/RailUI): los coches esperan antes de la barrera
type RailStop = { Pos: Vector3, Stop: number }
local railStops: { RailStop } = {}
function Traffic.setRailStops(list: { RailStop })
	railStops = list
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

-- Estado del semáforo para quien circula a lo largo del eje X o Z (y cuántos segundos le quedan)
local function signal(axis: string): (string, number)
	local t = workspace:GetServerTimeNow() % CYCLE
	if axis == "X" then
		if t < 12 then
			return "Green", 12 - t
		end
		return if t < 15 then "Yellow" else "Red", 0
	end
	if t < 15 then
		return "Red", 0
	end
	return if t < 27 then "Green" else "Yellow", math.max(27 - t, 0)
end
Traffic.signal = signal

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

-- ¿Puede cruzar ya un peatón que va en dirección dir y llega al cruce de `at`? En los cruces con
-- semáforo, solo con verde para su eje (los coches de la otra calle tienen rojo) y con tiempo de
-- sobra para llegar al otro lado; sin semáforo, sí (los coches le ceden el paso: Traffic.setWalkers)
function Traffic.mayCross(at: Vector3, dir: Vector3): boolean
	local node = nearestNode(at, 40)
	if not node or not lightNodes[node] then
		return true
	end
	local state, left = signal(if math.abs(dir.X) > math.abs(dir.Z) then "X" else "Z")
	return state == "Green" and left > 4
end

-- Peatones cruzando la calzada ahora mismo (los pone Controllers/Ambient cada fotograma): los coches
-- frenan ante ellos
local walkers: { Vector3 } = {}
function Traffic.setWalkers(list: { Vector3 })
	walkers = list
end

-- ¿Se ve este punto desde la cámara? (más o menos delante de ella)
local function inView(p: Vector3): boolean
	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end
	local rel = p - camera.CFrame.Position
	local d = rel.Magnitude
	return d > 0.01 and rel:Dot(camera.CFrame.LookVector) / d > 0.3
end
Traffic.inView = inView

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
		Width = info.Width,
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

-- Vuelta a la rotonda: de la entrada p0 a la salida p2 alrededor del centro c, dejando la isla a la
-- izquierda (el ángulo baja). Devuelve el ángulo de entrada, lo que se gira y los dos radios.
local function ringArc(c: Vector3, p0: Vector3, p2: Vector3): (number, number, number, number)
	local e, x = p0 - c, p2 - c
	local fe, fx = math.atan2(e.Z, e.X), math.atan2(x.Z, x.X)
	local sweep = (fe - fx) % (2 * math.pi)
	if sweep < 0.05 then
		sweep += 2 * math.pi
	end
	return fe, sweep, Vector3.new(e.X, 0, e.Z).Magnitude, Vector3.new(x.X, 0, x.Z).Magnitude
end

-- Posición y dirección del vehículo según su tramo y lo que ha avanzado (con la curva del cruce
-- o la vuelta a la rotonda)
local function pose(agent: Agent): (Vector3, Vector3)
	local a, b = nodes[agent.From], nodes[agent.To]
	local L = (b - a).Magnitude
	local d1 = (b - a).Unit
	local e1 = edgeOf(agent.From, agent.To)
	local l1 = laneOf(e1, agent.Small)
	local rin = turnRadius(agent.To, L)
	if agent.S <= L - rin then
		return a + d1 * agent.S + right(d1) * l1, d1
	end
	local c = nodes[agent.Next]
	local L2 = (c - b).Magnitude
	local d2 = if L2 > 0.01 then (c - b).Unit else -d1
	local l2 = laneOf(edgeOf(agent.To, agent.Next), agent.Small)
	local rout = turnRadius(agent.To, L2)
	local p0 = b - d1 * rin + right(d1) * l1
	local p2 = b + d2 * rout + right(d2) * l2
	local t = math.clamp((agent.S - (L - rin)) / (rin + rout), 0, 1)
	local center = roundabout[agent.To]
	if center then
		local fe, sweep, r0, r1 = ringArc(center, p0, p2)
		local f = fe - sweep * t
		local r = r0 + (r1 - r0) * t
		return center + Vector3.new(math.cos(f), 0, math.sin(f)) * r, Vector3.new(math.sin(f), 0, -math.cos(f))
	end
	local ctrl = b + (right(d1) * l1 + right(d2) * l2) / math.max(1 + d1:Dot(d2), 0.5)
	local q0, q1 = p0:Lerp(ctrl, t), ctrl:Lerp(p2, t)
	local dir = q1 - q0
	return q0:Lerp(q1, t), if dir.Magnitude > 0.01 then dir.Unit else d2
end

-- En la vuelta a una rotonda el recorrido es más largo que la recta que se cuenta: cuánto se estira
local function arcFactor(agent: Agent): number
	local center = roundabout[agent.To]
	if not center then
		return 1
	end
	local a, b, c = nodes[agent.From], nodes[agent.To], nodes[agent.Next]
	local L, L2 = (b - a).Magnitude, (c - b).Magnitude
	local rin, rout = turnRadius(agent.To, L), turnRadius(agent.To, L2)
	if agent.S <= L - rin or L2 < 0.01 then
		return 1
	end
	local d1, d2 = (b - a).Unit, (c - b).Unit
	local p0 = b - d1 * rin + right(d1) * laneOf(edgeOf(agent.From, agent.To), agent.Small)
	local p2 = b + d2 * rout + right(d2) * laneOf(edgeOf(agent.To, agent.Next), agent.Small)
	local _, sweep, r0, r1 = ringArc(center, p0, p2)
	return (rin + rout) / math.max(sweep * (r0 + r1) / 2, 1)
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
		-- Nunca aparece a la vista (salvo muy lejos): antes salían coches de la nada delante de ti
		if dist < HIDDEN and minDist >= SPAWN_MIN and inView(Vector3.new(spot.Pos.X, ROAD_TOP, spot.Pos.Z)) then
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
			agent.Look, agent.StuckAt = nil, nil
			setActive(agent, true)
			return
		end
	end
	setActive(agent, false)
end

-- Cruces sin semáforo (de 3 calles o más): pasan de uno en uno. Quien llega primero se lo "pide" y
-- los demás esperan antes de entrar (antes se cruzaban unos a través de otros)
local claims: { [number]: { Agent: Agent, At: number } } = {}
local function holds(holder: Agent, node: number): boolean
	if not holder.Active then
		return false
	end
	if holder.To == node then
		return true
	end
	return holder.From == node and holder.S < turnRadius(node, edgeLength(holder.From, holder.To)) + holder.Length
end

-- Algo por delante en la calzada (una persona o el coche de un jugador): { Pos, Box?, Size? }
type Obstacle = { Pos: Vector3, Box: CFrame?, Size: Vector3?, Mine: boolean? }

-- Cuánto sobresale una caja en una dirección (desde su centro)
local function reach(box: CFrame, size: Vector3, d: Vector3): number
	return math.abs(d:Dot(box.RightVector)) * size.X / 2 + math.abs(d:Dot(box.UpVector)) * size.Y / 2 + math.abs(d:Dot(box.LookVector)) * size.Z / 2
end

-- Espacio libre por delante (otro vehículo, un semáforo en rojo, un cruce ocupado, un peatón o un
-- jugador). Devuelve también si lo que para es el jugador (para pitarle).
local function freeGap(agent: Agent, pos: Vector3, dir: Vector3, obstacles: { Obstacle }): (number, boolean)
	local gap = math.huge
	local L = edgeLength(agent.From, agent.To)
	local myLane = laneOf(edgeOf(agent.From, agent.To), agent.Small)
	for _, other in agents do
		if other == agent or not other.Active then
			continue
		end
		local half = (other.Length + agent.Length) / 2
		local ahead = nil
		local otherLane = 0
		if other.From == agent.From and other.To == agent.To and other.S > agent.S then
			ahead = other.S - agent.S - half
			otherLane = laneOf(edgeOf(other.From, other.To), other.Small)
		elseif other.From == agent.To and other.To == agent.Next then
			ahead = L - agent.S + other.S - half
			otherLane = laneOf(edgeOf(other.From, other.To), other.Small)
		end
		-- Bicis y patinetes cuentan si van por el mismo carril (se rozarían); en su carril pegado a
		-- la acera, el coche pasa a su lado
		if ahead and (other.Small == agent.Small or math.abs(otherLane - myLane) < (other.Width + agent.Width) / 2) then
			gap = math.min(gap, ahead)
		end
	end
	-- Cruce sin semáforo: de uno en uno
	local node = agent.To
	if not lightNodes[node] and not roundabout[node] and #(edges[node] or {}) >= 3 then
		local toLine = (L - 14) - agent.S - agent.Length / 2
		if toLine < 14 then
			local claim = claims[node]
			local now = os.clock()
			if claim and claim.Agent ~= agent and holds(claim.Agent, node) and now - claim.At < 8 then
				if toLine > -1 then
					gap = math.min(gap, math.max(toLine, 0))
				end
			elseif not claim or claim.Agent ~= agent then
				claims[node] = { Agent = agent, At = now }
			end
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
	-- Paso a nivel con las barreras bajadas: se para antes (si ya lo estaba cruzando, sigue)
	for _, stop in railStops do
		local rel = stop.Pos - pos
		local ahead = rel:Dot(dir)
		if ahead > 0 and math.abs(rel:Dot(right(dir))) < 16 then
			local toLine = ahead - stop.Stop - agent.Length / 2
			if toLine > -1 and toLine < 80 then
				gap = math.min(gap, math.max(toLine, 0))
			end
		end
	end
	-- Personas y coches de jugadores delante (del coche del jugador cuenta la caja entera, no solo
	-- dónde va sentado: antes le atravesaban el morro o la cola)
	local byPlayer = false
	local side = right(dir)
	for _, o in obstacles do
		local rel = o.Pos - pos
		local ahead = rel:Dot(dir)
		local lateral = math.abs(rel:Dot(side))
		local long, wide = 0, 0
		if o.Box and o.Size then
			long, wide = reach(o.Box, o.Size, dir), reach(o.Box, o.Size, side)
		end
		if ahead + long > 0 and ahead - long < 22 and lateral - wide < agent.Width / 2 + 1.2 and math.abs(rel.Y) < 8 + (if o.Size then o.Size.Y / 2 else 0) then
			local g = ahead - long - agent.Length / 2 - 2
			if g < gap then
				gap = g
				byPlayer = o.Mine == true
			end
		end
	end
	return gap, byPlayer
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

-- Lo que ocupa cada jugador en la calle: su cuerpo o, si va en un vehículo, la caja entera del vehículo
local function playerObstacles(list: { Obstacle })
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
		local o: Obstacle = { Pos = root.Position, Mine = p == player }
		if vehicle and vehicle ~= character then
			local ok, box, size = pcall(function()
				return (vehicle :: Model):GetBoundingBox()
			end)
			if ok and box and size.Magnitude < 80 then
				o.Pos, o.Box, o.Size = box.Position, box, size
			end
		end
		table.insert(list, o)
	end
end

local blink = 0
local function step(dt: number, center: Vector3)
	-- Jugadores (con sus vehículos) y peatones cruzando: una lista por fotograma para todos los coches
	local obstacles: { Obstacle } = {}
	playerObstacles(obstacles)
	for _, w in walkers do
		table.insert(obstacles, { Pos = w })
	end
	local now = os.clock()
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
		local away = (pos - Vector3.new(center.X, 0, center.Z)).Magnitude
		if away > DESPAWN or (away > SPAWN_MAX and not inView(Vector3.new(pos.X, ROAD_TOP, pos.Z))) then
			respawn(agent, center, SPAWN_MIN)
			continue
		end
		local edge = edgeOf(agent.From, agent.To)
		local cruise = agent.Cruise * (if edge and edge.Kind == "Autovia" and not agent.Small then 1.5 else 1)
		-- Con lluvia o nieve, todos más despacio
		cruise *= Wetness.trafficSpeed(workspace:GetAttribute("Wet") or 0, workspace:GetAttribute("Snow") or 0)
		if agent.Turn ~= 0 then
			cruise = math.min(cruise, 24) -- más despacio al girar
		end
		local gap, byPlayer = freeGap(agent, pos, dir, obstacles)
		-- Parado detrás del jugador más de 2 s: le pita (sin sonido de claxon en el juego: el bocadillo)
		if byPlayer and agent.Speed < 0.5 and agent.Kind == "Car" then
			agent.StuckAt = agent.StuckAt or now
			if now - agent.StuckAt > 2 and now - (agent.HonkAt or 0) > 8 then
				agent.HonkAt = now
				local body = agent.Parts[1]
				if body then
					pcall(Nudge.say, body, "¡Piii, piii!", 1.4)
				end
			end
		else
			agent.StuckAt = nil
		end
		local target = math.min(cruise, math.sqrt(2 * DECEL * math.max(gap - 1.5, 0)))
		local change = math.clamp(target - agent.Speed, -DECEL * 2 * dt, 14 * dt)
		agent.Speed = math.max(agent.Speed + change, 0)
		setBraking(agent, change < -1 * dt or agent.Speed < 0.5)
		agent.S += agent.Speed * dt * arcFactor(agent)
		agent.Phase += dt * agent.Speed * 0.55

		local L = edgeLength(agent.From, agent.To)
		local L2 = edgeLength(agent.To, agent.Next)
		if agent.S >= L + turnRadius(agent.To, L2) then
			-- Pasa al siguiente tramo
			agent.S -= L
			agent.From, agent.To = agent.To, agent.Next
			agent.Next = chooseNext(agent)
			updateTurn(agent)
			pos, dir = pose(agent)
		end
		-- El morro gira poco a poco hacia donde va (sin tirones al pasar de un tramo a otro)
		local look = agent.Look
		if look and look:Dot(dir) > -0.5 then
			local blend = look:Lerp(dir, math.min(1, dt * 12))
			dir = if blend.Magnitude > 0.01 then blend.Unit else dir
		end
		agent.Look = dir
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
	-- Las calles que acaban a la entrada de una rotonda se unen a su centro (como el autobús)
	for _, rb in CityPlan.Roundabouts do
		local c = Vector3.new(rb[1], 0, rb[2])
		for i = 1, #roads do
			local r = roads[i]
			for _, e in { r.A, r.B } do
				local dist = (Vector3.new(e.X, 0, e.Z) - c).Magnitude
				if dist > 3 and dist < 60 then
					table.insert(roads, { A = Vector3.new(e.X, 0, e.Z), B = c, Width = r.Width, Kind = r.Kind })
				end
			end
		end
	end
	local graph = BusRoute.graph(roads, {})
	nodes, edges = graph.Nodes, graph.Edges
	for id, p in nodes do
		for _, rb in CityPlan.Roundabouts do
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(rb[1], 0, rb[2])).Magnitude < 4 then
				roundabout[id] = Vector3.new(rb[1], 0, rb[2])
			end
		end
	end
	for id, p in nodes do
		local key = math.floor(p.X / CELL) .. ":" .. math.floor(p.Z / CELL)
		cells[key] = cells[key] or {}
		table.insert(cells[key], id)
	end
	for from, list in edges do
		for _, e in list do
			if from < e.To then
				local L = e.Cost
				local s = turnRadius(from, L) + 5
				while s < L - turnRadius(e.To, L) - 5 do
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
			for i = 1, Perf.count(info.Count) do
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
