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
--  * Semáforos (shared/TrafficSignals): las luces cambian (verde, ámbar, rojo y un momento en rojo
--    los dos ejes) igual para todos los jugadores, los autobuses y las patrullas. Los vehículos paran
--    antes del paso de cebra en rojo (y en ámbar si les da para parar), hacen cola sin montarse, no
--    entran en el cruce si no pueden salir de él y, al girar a la izquierda, ceden el paso a los que
--    vienen de frente. Qué cruces tienen semáforo sale de los datos de las calles (no de los modelos:
--    con StreamingEnabled casi ninguno está cargado y antes nadie paraba).
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
local RideSpot = require(ReplicatedStorage.Shared.RideSpot)
local TrafficSignals = require(ReplicatedStorage.Shared.TrafficSignals)
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
	Indicators: { { Part: BasePart, Side: number, On: boolean? } },
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
	Pos: Vector3?, -- dónde se colocó en el último fotograma (para que tu vehículo choque con él)
	Dir: Vector3?,
}

local nodes: { Vector3 } = {}
local edges: { { Edge } } = {}
local cells: { [string]: { number } } = {}
local lightNodes: { [number]: boolean } = {}
local agents: { Agent } = {}
Traffic._agents = agents -- (pruebas: scripts/test-ride.luau)
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
-- Semáforos (mismo ciclo para todos: shared/TrafficSignals, con la hora del servidor)
---------------------------------------------------------------------
-- Hora del servidor del fotograma (se lee una vez por fotograma en step, no por vehículo)
local frameNow = 0

local function serverNow(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.clock()
end

-- Estado del semáforo para quien circula a lo largo del eje X o Z (y cuántos segundos le quedan)
local function signal(axis: string): (string, number)
	return TrafficSignals.state(axis, serverNow())
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

local function paintLight(light: Light, on: string)
	for _, lamp in light.Lamps do
		local lit = lamp.Role == on
		lamp.Part.Color = if lit then LAMP_ON[lamp.Role] else LAMP_OFF[lamp.Role]
		lamp.Part.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

-- Semáforos cuyo modelo ha llegado sin sus piezas (StreamingEnabled): se reintentan en refreshLights
local pendingLights: { [Model]: boolean } = {}

-- Las luces de un semáforo (solo para pintarlas: qué cruces tienen semáforo sale de las calles).
-- Se puede llamar otra vez con el mismo modelo (si sus piezas vuelven a cargarse, se recogen de nuevo).
local function addLight(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local arm = model:FindFirstChild("Arm") :: BasePart?
	local box = model:FindFirstChild("Box") :: BasePart?
	if not arm or not box then
		-- (antes se descartaba para siempre: con StreamingEnabled el modelo llega antes que sus piezas)
		lights[model] = nil
		pendingLights[model] = true
		return
	end
	pendingLights[model] = nil
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
	paintLight(light, (signal(light.Axis))) -- ya, sin esperar al siguiente cambio de luz
end

-- ¿Puede cruzar ya un peatón que va en dirección dir y llega al cruce de `at`? En los cruces con
-- semáforo, solo con verde para su eje (los coches de la otra calle tienen rojo) y con tiempo de
-- sobra para llegar al otro lado; sin semáforo, sí (los coches le ceden el paso: Traffic.setWalkers)
function Traffic.mayCross(at: Vector3, dir: Vector3): boolean
	local node = nearestNode(at, 40)
	if not node or not lightNodes[node] then
		return true
	end
	return TrafficSignals.walk(TrafficSignals.axisOf(dir), serverNow())
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
	-- Semáforos que llegaron sin piezas: se vuelven a mirar
	for model in pendingLights do
		if not model.Parent then
			pendingLights[model] = nil
		else
			addLight(model)
		end
	end
	local state = { X = signal("X"), Z = signal("Z") }
	local changed = shown.X ~= state.X or shown.Z ~= state.Z
	shown.X, shown.Z = state.X, state.Z
	for model, light in lights do
		if not model.Parent then
			lights[model] = nil
			continue
		end
		-- Si una luz se ha descargado (StreamingEnabled), se vuelven a recoger las del modelo
		local stale = false
		for _, lamp in light.Lamps do
			if lamp.Part.Parent ~= model then
				stale = true
				break
			end
		end
		if stale or #light.Lamps == 0 then
			addLight(model)
		elseif changed then
			paintLight(light, state[light.Axis])
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
	-- La carrocería (la pieza más grande) es sólida: a pie no se atraviesa un coche del tráfico.
	-- (Tu vehículo choca con ellos con Traffic.blocking; siguen sin contar para los rayos: CanQuery.)
	if kind == "Car" then
		local body, volume = nil :: BasePart?, 0
		for _, part in agent.Parts do
			local v = part.Size.X * part.Size.Y * part.Size.Z
			if part.Transparency < 0.5 and v > volume then
				body, volume = part, v
			end
		end
		if body then
			body.CanCollide = true
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

local place: (Agent, Vector3, Vector3) -> () -- (más abajo)

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
		-- Que no aparezca encima de otro (ni tan cerca que el de detrás no pueda frenar: antes, a 16)
		local clash = false
		for _, other in agents do
			if other ~= agent and other.Active and other.From == from and other.To == to and math.abs(other.S - s) < 40 then
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
			-- Que le dé para parar antes del cruce de delante (si aparece cerca de uno con semáforo)
			if lightNodes[to] then
				local toLine = edgeLength(from, to) - TrafficSignals.STOP_LINE - s - agent.Length / 2
				agent.Speed = math.min(agent.Speed, math.sqrt(2 * DECEL * math.max(toLine - 1.5, 0)))
			end
			agent.Look, agent.StuckAt = nil, nil
			-- Y a su sitio en el mismo fotograma: el modelo se copia de uno que está en el origen (0, 0: el
			-- cruce grande de Valmar Centro) y, si algo retrasaba su primer paso, se quedaba allí a la vista
			setActive(agent, true)
			place(agent, pose(agent))
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

-- Radio de cada cruce (media calzada de la calle más ancha que llega + 2): hasta ahí se para en
-- los cruces sin semáforo (antes siempre a 14: en la autovía, dentro de la calzada)
local nodeBox: { [number]: number } = {}

-- ¿Hay sitio al salir del cruce? Nadie parado (o casi) en su carril justo después del cruce
local function exitClear(agent: Agent, node: number): boolean
	local need = TrafficSignals.BOX + agent.Length + 1
	local lane = laneOf(edgeOf(node, agent.Next), agent.Small)
	for _, other in agents do
		if other ~= agent and other.Active and other.From == node and other.To == agent.Next and other.Speed < 4 then
			local otherLane = laneOf(edgeOf(other.From, other.To), other.Small)
			if (other.Small == agent.Small or math.abs(otherLane - lane) < (other.Width + agent.Width) / 2) and other.S - other.Length / 2 < need then
				return false
			end
		end
	end
	return true
end

-- Al girar a la izquierda: ¿viene alguien de frente (recto o a su derecha) que va a pasar ya?
-- (los que están parados en su línea no cuentan; los que también giran a la izquierda, tampoco:
-- se cruzan por delante sin tocarse)
local function oncoming(agent: Agent, node: number, d: Vector3): boolean
	for _, other in agents do
		if other ~= agent and other.Active and other.To == node and other.Turn ~= -1 and other.From ~= agent.From then
			local od = nodes[node] - nodes[other.From]
			local Lo = od.Magnitude
			if Lo > 0.01 and (od / Lo):Dot(d) < -0.7 then
				local front = Lo - other.S - other.Length / 2 -- de su morro al centro del cruce
				if front > -TrafficSignals.BOX / 2 and front < 70 and (other.Speed > 3 or front < TrafficSignals.STOP_LINE - 1) then
					return true
				end
			end
		end
	end
	return false
end

-- ¿Hay alguien de la otra calle todavía dentro del cruce? (entró con ámbar y aún no ha salido):
-- en verde se espera en la línea a que lo deje libre, en vez de meterse y cruzarse con él
local function boxBusy(agent: Agent, node: number, d: Vector3): boolean
	local axis = TrafficSignals.axisOf(d)
	for _, other in agents do
		if other == agent or not other.Active then
			continue
		end
		if other.To == node and other.From ~= agent.From then
			-- Aún no ha llegado al centro (o está girando): cuenta si viene por la otra calle y ya ha
			-- pasado su línea
			local od = nodes[node] - nodes[other.From]
			local Lo = od.Magnitude
			if Lo > 0.01 and TrafficSignals.axisOf(od) ~= axis and Lo - TrafficSignals.STOP_LINE - other.S - other.Length / 2 <= -1 then
				return true
			end
		elseif other.From == node and other.S < TrafficSignals.BOX + other.Length / 2 then
			-- Saliendo: cuenta si sale a lo largo de la otra calle (cruza por delante)
			if TrafficSignals.axisOf(nodes[other.To] - nodes[node]) ~= axis then
				return true
			end
		end
	end
	return false
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
	-- Cruce sin semáforo: de uno en uno (se para antes de la calzada de la calle que cruza)
	local node = agent.To
	if not lightNodes[node] and not roundabout[node] and #(edges[node] or {}) >= 3 then
		local toLine = (L - (nodeBox[node] or 14)) - agent.S - agent.Length / 2
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
	-- Semáforo antes del cruce (shared/TrafficSignals): para antes del paso de cebra en rojo, y en
	-- ámbar si le da para parar; una vez pasada la línea, sigue y sale del cruce
	if lightNodes[node] then
		local d = (nodes[node] - nodes[agent.From]).Unit
		local state = TrafficSignals.state(TrafficSignals.axisOf(d), frameNow)
		local toLine = (L - TrafficSignals.STOP_LINE) - agent.S - agent.Length / 2
		if TrafficSignals.mustStop(state, toLine, agent.Speed, DECEL) then
			gap = math.min(gap, math.max(toLine, 0))
		elseif toLine > -1 and toLine < 40 and TrafficSignals.canStop(toLine, agent.Speed, DECEL) then
			-- En verde: no entra si al otro lado no hay sitio para él (no se queda parado dentro del
			-- cruce), si aún hay alguien de la otra calle dentro y, si gira a la izquierda, cede el paso
			-- a los que vienen de frente
			if not exitClear(agent, node) or boxBusy(agent, node, d) or (agent.Turn == -1 and oncoming(agent, node, d)) then
				gap = math.min(gap, math.max(toLine, 0))
			end
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

function place(agent: Agent, pos: Vector3, dir: Vector3)
	agent.Pos, agent.Dir = pos, dir
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

-- La caja de cada vehículo, guardada respecto a su pivote (GetBoundingBox recorre todas sus piezas:
-- antes se hacía en cada fotograma por cada jugador sentado). Se vuelve a medir cada 2 s por si el
-- vehículo cambia. Tabla débil: si el vehículo se destruye, se olvida solo.
type Extent = { Offset: CFrame, Size: Vector3, At: number }
local extents: { [Model]: Extent } = setmetatable({}, { __mode = "k" }) :: any
local EXTENT_EVERY = 2

local function vehicleBox(vehicle: Model, now: number): (CFrame?, Vector3?)
	local ok, pivot = pcall(vehicle.GetPivot, vehicle)
	if not ok then
		return nil, nil
	end
	local cached = extents[vehicle]
	if not cached or now - cached.At > EXTENT_EVERY then
		local okBox, box, size = pcall(function()
			return vehicle:GetBoundingBox()
		end)
		if not okBox or not box then
			extents[vehicle] = nil
			return nil, nil
		end
		cached = { Offset = pivot:ToObjectSpace(box), Size = size, At = now }
		extents[vehicle] = cached
	end
	return pivot * cached.Offset, cached.Size
end

-- Fichas de obstáculo reutilizadas (antes se creaban tablas nuevas en cada fotograma)
local obstaclePool: { Obstacle } = {}
local function obstacleAt(list: { Obstacle }, pos: Vector3): Obstacle
	local n = #list + 1
	local o = obstaclePool[n]
	if not o then
		o = { Pos = pos }
		obstaclePool[n] = o
	end
	o.Pos, o.Box, o.Size, o.Mine = pos, nil, nil, nil
	list[n] = o
	return o
end

-- Un jugador más lejos que esto no puede estar delante de ningún vehículo (todos están a menos de
-- DESPAWN; la caja de un vehículo mide menos de 80)
local PLAYER_REACH = DESPAWN + 22 + 80

-- Lo que ocupa cada jugador en la calle: su cuerpo o, si va en un vehículo, la caja entera del vehículo
local function playerObstacles(list: { Obstacle }, center: Vector3, now: number)
	for _, p in Players:GetPlayers() do
		local character = p.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end
		local rp = root.Position
		if Vector3.new(rp.X - center.X, 0, rp.Z - center.Z).Magnitude > PLAYER_REACH then
			continue
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local vehicle = seat and seat:FindFirstAncestorOfClass("Model")
		local o = obstacleAt(list, rp)
		o.Mine = p == player
		if vehicle and vehicle ~= character then
			local box, size = vehicleBox(vehicle :: Model, now)
			if box and size and size.Magnitude < 80 then
				o.Pos, o.Box, o.Size = box.Position, box, size
			end
		end
	end
end

-- Autobuses de las líneas (servidor: BusService, carpeta workspace.Buses): también son obstáculos
-- (antes los coches parados en un semáforo se dejaban atravesar por el autobús). La lista de los
-- cercanos se rehace cada medio segundo; su caja sale de vehicleBox (guardada, se remide cada 2 s).
local BUS_EVERY = 0.5
local nearBuses: { Model } = {}
local busesAt = -math.huge
local function busObstacles(list: { Obstacle }, center: Vector3, now: number)
	if now - busesAt >= BUS_EVERY then
		busesAt = now
		table.clear(nearBuses)
		-- (y las patrullas de ronda de la policía: World/PoliceUnits, que también paran en rojo; los
		-- coches hacen cola detrás en vez de atravesarlas)
		local police = workspace:FindFirstChild("PoliceResponse")
		local folders: { Instance } = {}
		local busRoot = workspace:FindFirstChild("Buses")
		local patrolRoot = police and police:FindFirstChild("Patrullas")
		if busRoot then
			table.insert(folders, busRoot)
		end
		if patrolRoot then
			table.insert(folders, patrolRoot)
		end
		for _, busFolder in folders do
			for _, bus in busFolder:GetChildren() do
				if bus:IsA("Model") then
					local ok, pivot = pcall(bus.GetPivot, bus)
					if ok and Vector3.new(pivot.X - center.X, 0, pivot.Z - center.Z).Magnitude <= PLAYER_REACH then
						table.insert(nearBuses, bus)
					end
				end
			end
		end
	end
	for _, bus in nearBuses do
		if bus.Parent then
			local box, size = vehicleBox(bus, now)
			if box and size and size.Magnitude < 80 then
				local o = obstacleAt(list, box.Position)
				o.Box, o.Size = box, size
			end
		end
	end
end

local blink = 0
local obstacles: { Obstacle } = {} -- (la misma tabla en cada fotograma)
local warnedStep = false
local function stepAgent(agent: Agent, dt: number, center: Vector3, now: number, blinkOn: boolean, wetSpeed: number)
	if not agent.Active then
		if math.random() < 0.1 then -- no buscar sitio en cada fotograma
			respawn(agent, center, SPAWN_MIN)
		end
		return
	end
	local pos, dir = pose(agent)
	local away = (pos - Vector3.new(center.X, 0, center.Z)).Magnitude
	if away > DESPAWN or (away > SPAWN_MAX and not inView(Vector3.new(pos.X, ROAD_TOP, pos.Z))) then
		respawn(agent, center, SPAWN_MIN)
		return
	end
	local edge = edgeOf(agent.From, agent.To)
	local cruise = agent.Cruise * (if edge and edge.Kind == "Autovia" and not agent.Small then 1.5 else 1)
	cruise *= wetSpeed
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
		-- (solo se pinta cuando cambia: escribir Color y Material cada fotograma cuesta)
		if ind.On ~= on then
			ind.On = on
			ind.Part.Color = if on then IND_ON else IND_OFF
			ind.Part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
	place(agent, pos, dir)
end

local function step(dt: number, center: Vector3)
	-- Jugadores (con sus vehículos) y peatones cruzando: una lista por fotograma para todos los coches
	local now = os.clock()
	frameNow = serverNow() -- (los semáforos: una lectura de la hora por fotograma)
	table.clear(obstacles)
	playerObstacles(obstacles, center, now)
	busObstacles(obstacles, center, now)
	for _, w in walkers do
		obstacleAt(obstacles, w)
	end
	blink += dt
	local blinkOn = (blink % 0.8) < 0.4
	-- Con lluvia o nieve, todos más despacio (una vez por fotograma, no por vehículo)
	local wetSpeed = Wetness.trafficSpeed(workspace:GetAttribute("Wet") or 0, workspace:GetAttribute("Snow") or 0)
	for _, agent in agents do
		-- Uno a uno y protegido: si uno falla, se retira ese (antes el error cortaba el fotograma y los
		-- que iban detrás en la lista se quedaban quietos donde estuvieran; recién creados, en el origen:
		-- el cruce grande de Valmar Centro, lleno de piezas de coche)
		local ok, err = pcall(stepAgent, agent, dt, center, now, blinkOn, wetSpeed)
		if not ok then
			if not warnedStep then
				warnedStep = true
				warn("[Traffic] " .. tostring(err))
			end
			setActive(agent, false)
		end
	end
end

---------------------------------------------------------------------

-- ¿Toca tu vehículo (caja vista desde arriba: centro, hacia dónde mira, largo y ancho) algún
-- vehículo del tráfico? Devuelve dónde está el primero que toca (nil = ninguno). Lo usa Driving:
-- así tu coche o tu moto no atraviesan el tráfico (sus piezas no chocan: las mueve este script).
function Traffic.blocking(pos: Vector3, dir: Vector3, length: number, width: number): Vector3?
	for _, agent in agents do
		local at, facing = agent.Pos, agent.Dir
		if agent.Active and at and facing then
			local reachSq = (length + agent.Length) * (length + agent.Length) / 4 + (width + agent.Width) * (width + agent.Width)
			local dx, dz = at.X - pos.X, at.Z - pos.Z
			if dx * dx + dz * dz <= reachSq and math.abs(pos.Y - ROAD_TOP) < 12 then
				if RideSpot.boxesOverlap(pos, dir, length, width, at, facing, agent.Length, agent.Width) then
					return Vector3.new(at.X, pos.Y, at.Z)
				end
			end
		end
	end
	return nil
end

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
		local widest = 0
		for _, e in edges[id] do
			widest = math.max(widest, e.W)
		end
		nodeBox[id] = math.max(14, widest / 2 + 2)
	end
	-- Cruces con semáforo: los de la cuadrícula de calles (shared/TrafficSignals, con los datos de las
	-- calles; antes se buscaban los modelos de los semáforos y, con StreamingEnabled, no llegaban)
	for _, c in TrafficSignals.fromFolder(data:WaitForChild("Roads")) do
		local node = nearestNode(c, 6)
		if node and not roundabout[node] then
			lightNodes[node] = true
		end
	end
	-- (no aparece nadie entre la línea de parada y el cruce: se saltaría el semáforo)
	local function margin(node: number, L: number): number
		return if lightNodes[node] then TrafficSignals.STOP_LINE + 18 else turnRadius(node, L) + 5
	end
	for from, list in edges do
		for _, e in list do
			if from < e.To then
				local L = e.Cost
				local s = margin(from, L)
				while s < L - margin(e.To, L) do
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
	-- (pruebas: scripts/test-lights.luau)
	Traffic._test = { Nodes = nodes, Edges = edges, LightNodes = lightNodes, NodeBox = nodeBox, Step = step, Pose = pose, EdgeLength = edgeLength, UpdateTurn = updateTurn, SetActive = setActive }

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
