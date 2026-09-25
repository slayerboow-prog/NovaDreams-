-- Roads: las carreteras principales del plano (CityPlan.Roads), en cualquier ángulo.
--   * Autovía: 4 carriles con mediana, sin aceras (las rotondas llevan paso de peatones)
--   * Avenida: 2 carriles anchos, aceras, farolas y línea central
--   * Calle: calzada normal con aceras
-- Donde se cruzan dos carreteras se pone un cruce; en los puntos de CityPlan.Roundabouts, una rotonda.
-- Donde pasan sobre el río o un lago se hace un puente (barandillas y pilares).
-- Las calles de dentro de cada barrio (cuadrículas) siguen siendo las de Kit/Street.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local Roads = {}

local rgb = Color3.fromRGB
local G = Palette.Ground

Roads.Kinds = {
	Autovia = { Road = 36, Walk = 0, Median = 3, Lamp = 90 },
	Avenida = { Road = 28, Walk = 7, Median = 0, Lamp = 70 },
	Calle = { Road = 22, Walk = 6, Median = 0, Lamp = 80 },
}
local ROUNDABOUT_R = 56 -- radio exterior de la calzada de una rotonda
local ISLAND_R = 22 -- isla central

export type Segment = { A: Vector3, B: Vector3, Kind: string, Name: string }

local function v(p: { number }): Vector3
	return Vector3.new(p[1], 0, p[2])
end

-- Intersección de dos segmentos en planta (nil si no se cruzan por dentro)
local function cross(a: Vector3, b: Vector3, c: Vector3, d: Vector3): Vector3?
	local r = b - a
	local s = d - c
	local den = r.X * s.Z - r.Z * s.X
	if math.abs(den) < 1e-6 then
		return nil
	end
	local t = ((c.X - a.X) * s.Z - (c.Z - a.Z) * s.X) / den
	local u = ((c.X - a.X) * r.Z - (c.Z - a.Z) * r.X) / den
	if t > 0.01 and t < 0.99 and u > 0.01 and u < 0.99 then
		return a + r * t
	end
	return nil
end

local function key(p: Vector3): string
	return math.floor(p.X + 0.5) .. ":" .. math.floor(p.Z + 0.5)
end

-- Tramos rectos de todas las carreteras, partidos en los cruces
local segmentsCache: { Segment }? = nil
function Roads.segments(): { Segment }
	if segmentsCache then
		return segmentsCache
	end
	local raw: { Segment } = {}
	for _, road in CityPlan.Roads do
		for i = 1, #road.Points - 1 do
			table.insert(raw, { A = v(road.Points[i]), B = v(road.Points[i + 1]), Kind = road.Kind, Name = road.Name })
		end
	end
	-- Puntos de corte de cada tramo
	local cuts: { { number } } = {}
	for i, s in raw do
		cuts[i] = {}
		for j, o in raw do
			if i ~= j then
				local p = cross(s.A, s.B, o.A, o.B)
				if p then
					table.insert(cuts[i], (p - s.A).Magnitude)
				end
			end
		end
	end
	local out: { Segment } = {}
	for i, s in raw do
		local len = (s.B - s.A).Magnitude
		local dir = (s.B - s.A).Unit
		local list = cuts[i]
		table.sort(list)
		local prev = 0
		for _, d in list do
			table.insert(out, { A = s.A + dir * prev, B = s.A + dir * d, Kind = s.Kind, Name = s.Name })
			prev = d
		end
		table.insert(out, { A = s.A + dir * prev, B = s.B, Kind = s.Kind, Name = s.Name })
		local _ = len
	end
	segmentsCache = out
	return out
end

-- Nodos: puntos donde se juntan 2 o más tramos (o rotondas)
local function nodes(segments: { Segment }): { [string]: { Position: Vector3, Count: number, Width: number, Roundabout: boolean } }
	local map = {}
	local function add(p: Vector3, width: number)
		local k = key(p)
		local n = map[k]
		if not n then
			n = { Position = p, Count = 0, Width = 0, Roundabout = false }
			map[k] = n
		end
		n.Count += 1
		n.Width = math.max(n.Width, width)
	end
	for _, s in segments do
		local kind = Roads.Kinds[s.Kind]
		local w = kind.Road / 2 + kind.Walk
		add(s.A, w)
		add(s.B, w)
	end
	for _, r in CityPlan.Roundabouts do
		local k = key(v(r))
		if map[k] then
			map[k].Roundabout = true
		else
			map[k] = { Position = v(r), Count = 1, Width = 20, Roundabout = true }
		end
	end
	return map
end

-- ¿Este punto está sobre agua (río o lago)?
local function overWater(p: Vector3): boolean
	if CityPlan.riverDistance(p.X, p.Z) < CityPlan.River.Width / 2 + 12 then
		return true
	end
	for _, lake in CityPlan.Lakes do
		if (Vector3.new(lake.X, 0, lake.Z) - p).Magnitude < lake.R + 6 then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------

local function box(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material, decor: boolean?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material, Parent = parent }
	return if decor then Builder.decor(props) else Builder.part(props)
end

local function disc(parent: Instance, name: string, p: Vector3, radius: number, y0: number, y1: number, color: Color3, material: Enum.Material): BasePart
	return Builder.part({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(y1 - y0, radius * 2, radius * 2),
		CFrame = CFrame.new(p.X, (y0 + y1) / 2, p.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		Parent = parent,
	})
end

local function buildSegment(parent: Instance, s: Segment, trimA: number, trimB: number)
	local kind = Roads.Kinds[s.Kind]
	local dir = (s.B - s.A).Unit
	local a = s.A + dir * trimA
	local b = s.B - dir * trimB
	local length = (b - a).Magnitude
	if length < 2 then
		return
	end
	local mid = (a + b) / 2
	local base = Builder.facing(mid, dir) -- Z local = a lo largo (hacia -Z mira B)
	local half = kind.Road / 2
	-- Calzada
	box(parent, "Road", base * CFrame.new(0, 0.2, 0), Vector3.new(kind.Road, 0.4, length), G.Asphalt, Enum.Material.Asphalt)
	-- Mediana (autovía) o línea central
	if kind.Median > 0 then
		box(parent, "Median", base * CFrame.new(0, 0.7, 0), Vector3.new(kind.Median, 0.6, length), rgb(196, 192, 184), Enum.Material.Concrete)
		box(parent, "MedianGrass", base * CFrame.new(0, 1.02, 0), Vector3.new(kind.Median - 0.8, 0.06, length), rgb(92, 140, 66), Enum.Material.Grass, true)
		for _, x in { -half + 1.2, half - 1.2, -kind.Median / 2 - 0.8, kind.Median / 2 + 0.8 } do
			box(parent, "Marking", base * CFrame.new(x, 0.42, 0), Vector3.new(0.35, 0.04, length), G.Marking, Enum.Material.SmoothPlastic, true)
		end
	else
		box(parent, "Marking", base * CFrame.new(0, 0.42, 0), Vector3.new(0.4, 0.04, length), G.MarkingYellow, Enum.Material.SmoothPlastic, true)
	end
	-- Aceras con bordillo
	if kind.Walk > 0 then
		for _, side in { -1, 1 } do
			local x = side * (half + kind.Walk / 2)
			box(parent, "Sidewalk", base * CFrame.new(x, 0.5, 0), Vector3.new(kind.Walk, 1, length), G.Sidewalk, Enum.Material.Pavement)
		end
	end
	-- Puente: tramos sobre el agua con barandilla y pilares
	local step = 10
	local bridgeFrom: number? = nil
	local function closeBridge(to: number)
		if not bridgeFrom then
			return
		end
		local from = bridgeFrom
		bridgeFrom = nil
		local len = to - from
		if len < 8 then
			return
		end
		local centre = base * CFrame.new(0, 0, length / 2 - (from + to) / 2)
		local outer = half + kind.Walk
		for _, side in { -1, 1 } do
			box(parent, "BridgeRail", centre * CFrame.new(side * (outer + 0.3), 2.6, 0), Vector3.new(0.5, 0.5, len), rgb(210, 214, 220), Enum.Material.Metal)
			box(parent, "BridgeWall", centre * CFrame.new(side * (outer + 0.3), 1.3, 0), Vector3.new(0.6, 2.6, len), rgb(170, 166, 158), Enum.Material.Concrete)
		end
		box(parent, "BridgeDeck", centre * CFrame.new(0, -0.8, 0), Vector3.new(outer * 2 + 1.2, 1.6, len), rgb(150, 146, 140), Enum.Material.Concrete)
		for d = 12, len - 12, 34 do
			box(parent, "Pillar", centre * CFrame.new(0, -7, len / 2 - d), Vector3.new(outer * 1.4, 12, 4), rgb(150, 146, 140), Enum.Material.Concrete)
		end
	end
	for d = 0, length, step do
		local p = a + dir * d
		if overWater(p) then
			bridgeFrom = bridgeFrom or math.max(0, d - step)
		else
			closeBridge(d)
		end
	end
	closeBridge(length)
	-- Farolas (alternando lados), no sobre el puente
	local d = kind.Lamp / 2
	local side = 1
	while d < length - 10 do
		local p = a + dir * d
		if not overWater(p) then
			local perp = Vector3.new(-dir.Z, 0, dir.X) * side
			local offset = if kind.Walk > 0 then half + kind.Walk - 1 else half + 2
			Props.lamp(parent, Builder.facing(p + perp * offset + Vector3.new(0, if kind.Walk > 0 then 1 else 0, 0), -perp))
		end
		d += kind.Lamp
		side = -side
	end
end

-- Paso de peatones (cebra) cruzando la calzada, a "dist" del nodo
local function zebra(parent: Instance, node: Vector3, dir: Vector3, width: number, dist: number)
	local p = node + dir * dist
	local base = Builder.facing(p, dir)
	for x = -width / 2 + 2, width / 2 - 2, 2.6 do
		box(parent, "Zebra", base * CFrame.new(x, 0.42, 0), Vector3.new(1.3, 0.04, 5), G.Marking, Enum.Material.SmoothPlastic, true)
	end
end

local function buildRoundabout(parent: Instance, p: Vector3)
	local m = Builder.model("Rotonda", parent)
	disc(m, "Road", p, ROUNDABOUT_R, 0, 0.4, G.Asphalt, Enum.Material.Asphalt)
	disc(m, "Curb", p, ISLAND_R + 1, 0, 1.1, rgb(214, 211, 204), Enum.Material.Concrete)
	disc(m, "Island", p, ISLAND_R, 0, 1.2, rgb(98, 146, 70), Enum.Material.Grass)
	-- Adorno central: fuente o árbol con flores
	Builder.part({ Name = "Monument", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 12, 12), CFrame = CFrame.new(p.X, 2.7, p.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(200, 196, 188), Material = Enum.Material.Limestone, Parent = m })
	Builder.part({ Name = "Obelisk", Size = Vector3.new(2.4, 16, 2.4), CFrame = CFrame.new(p.X, 12, p.Z), Color = rgb(226, 222, 210), Material = Enum.Material.Marble, Parent = m })
	-- Línea discontinua del carril interior
	for i = 0, 23 do
		local ang = i / 24 * math.pi * 2
		local r = (ROUNDABOUT_R + ISLAND_R) / 2 + 2
		box(m, "Marking", CFrame.new(p.X + math.cos(ang) * r, 0.42, p.Z + math.sin(ang) * r) * CFrame.Angles(0, -ang, 0), Vector3.new(0.35, 0.04, 5), G.Marking, Enum.Material.SmoothPlastic, true)
	end
end

function Roads.build(world: Instance)
	local folder = Builder.model("MainRoads", world)
	local segments = Roads.segments()
	local map = nodes(segments)
	-- Recorte de cada tramo en sus extremos (para no pisar el cruce o la rotonda)
	local function trim(p: Vector3): number
		local n = map[key(p)]
		if not n then
			return 0
		end
		if n.Roundabout then
			return ROUNDABOUT_R - 2
		end
		return if n.Count >= 2 then n.Width else 0
	end
	for _, s in segments do
		buildSegment(folder, s, trim(s.A), trim(s.B))
	end
	for _, n in map do
		if n.Roundabout then
			buildRoundabout(folder, n.Position)
		elseif n.Count >= 2 then
			disc(folder, "Junction", n.Position, n.Width + 0.5, 0, 0.4, G.Asphalt, Enum.Material.Asphalt)
		end
	end
	-- Pasos de peatones al llegar a cada rotonda y cruce (en avenidas y calles)
	for _, s in segments do
		local kind = Roads.Kinds[s.Kind]
		if kind.Walk > 0 then
			local dir = (s.B - s.A).Unit
			for _, endInfo in { { s.A, dir }, { s.B, -dir } } do
				local n = map[key(endInfo[1])]
				if n and (n.Roundabout or n.Count >= 2) and (s.B - s.A).Magnitude > 60 then
					zebra(folder, endInfo[1], endInfo[2], kind.Road, trim(endInfo[1]) + 6)
				end
			end
		end
	end
	return folder
end

-- ¿Punto cerca de una carretera principal? (para no plantar árboles encima)
function Roads.near(x: number, z: number, margin: number): boolean
	for _, s in Roads.segments() do
		local kind = Roads.Kinds[s.Kind]
		if CityPlan.segmentDistance(x, z, s.A.X, s.A.Z, s.B.X, s.B.Z) < kind.Road / 2 + kind.Walk + margin then
			return true
		end
	end
	for _, r in CityPlan.Roundabouts do
		if math.sqrt((x - r[1]) ^ 2 + (z - r[2]) ^ 2) < ROUNDABOUT_R + margin then
			return true
		end
	end
	return false
end

return Roads
