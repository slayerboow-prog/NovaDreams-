-- Roads: las carreteras principales del plano (CityPlan.Roads), en cualquier ángulo.
--   * Autovía: 4 carriles con mediana, sin aceras (las rotondas llevan paso de peatones)
--   * Avenida: 2 carriles anchos, aceras, farolas y línea central
--   * Calle: calzada normal con aceras
-- Donde se cruzan (o una acaba en medio de otra) se pone un cruce; en los puntos de
-- CityPlan.Roundabouts, una rotonda. Donde pasan sobre el río o un lago se hace un puente.
-- Las calles de dentro de cada barrio (cuadrículas) siguen siendo las de Kit/Street; donde se juntan
-- con estas carreteras se cosen con Kit/Bocacalles (aceras recortadas, boca abierta y paso de cebra).
--
-- Sin huecos: la calzada de cada tramo llega hasta el centro del cruce (se solapan), la acera empieza
-- donde ya no pisa la calzada de otro brazo y lo que queda entre medias es asfalto (o la esquina de
-- acera que une los dos brazos). Las pruebas (scripts/test-streets) lo comprueban punto a punto.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)

local Roads = {}

local rgb = Color3.fromRGB
local G = Palette.Ground
local V3 = Vector3.new

Roads.Kinds = {
	Autovia = { Road = 36, Walk = 0, Median = 3, Lamp = 90 },
	Avenida = { Road = 28, Walk = 7, Median = 0, Lamp = 70 },
	Calle = { Road = 22, Walk = 6, Median = 0, Lamp = 80 },
}
local ROUNDABOUT_R = 56 -- radio exterior de la calzada de una rotonda
local ISLAND_R = 22 -- isla central
local RING_WALK = 6 -- acera alrededor de la rotonda
local ROAD_TOP, WALK_TOP, BASE = 0.4, 1.0, -4
Roads.ROUNDABOUT_R = ROUNDABOUT_R
Roads.ISLAND_R = ISLAND_R
Roads.RING_WALK = RING_WALK

export type Segment = { A: Vector3, B: Vector3, Kind: string, Name: string }

-- (se carga al construir: Kit/Bocacalles necesita a Roads)
local function Bocacalles(): any
	return require(script.Parent.Bocacalles)
end

local function v(p: { number }): Vector3
	return V3(p[1], 0, p[2])
end

local function perpOf(d: Vector3): Vector3
	return V3(-d.Z, 0, d.X)
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
Roads.key = key

-- Tramos rectos de todas las carreteras, partidos en los cruces, donde otra carretera acaba en medio
-- (en T) y en las rotondas que caen en medio de un tramo
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
	-- Puntos que parten un tramo: finales de otros tramos y rotondas encima
	local stops: { Vector3 } = {}
	for _, s in raw do
		table.insert(stops, s.A)
		table.insert(stops, s.B)
	end
	for _, r in CityPlan.Roundabouts do
		table.insert(stops, v(r))
	end
	local out: { Segment } = {}
	for i, s in raw do
		local len = (s.B - s.A).Magnitude
		local dir = (s.B - s.A).Unit
		local list: { number } = {}
		for j, o in raw do
			if i ~= j then
				local p = cross(s.A, s.B, o.A, o.B)
				if p then
					table.insert(list, (p - s.A).Magnitude)
				end
			end
		end
		for _, p in stops do
			local rel = p - s.A
			local along = rel:Dot(dir)
			local off = math.abs(rel.X * dir.Z - rel.Z * dir.X)
			if off < 1 and along > 2 and along < len - 2 then
				table.insert(list, along)
			end
		end
		table.sort(list)
		local prev = 0
		for _, d in list do
			if d - prev > 1 then
				table.insert(out, { A = s.A + dir * prev, B = s.A + dir * d, Kind = s.Kind, Name = s.Name })
				prev = d
			end
		end
		table.insert(out, { A = s.A + dir * prev, B = s.B, Kind = s.Kind, Name = s.Name })
	end
	segmentsCache = out
	return out
end

-- Nodos: puntos donde se juntan 2 o más tramos (o rotondas)
type Node = { Position: Vector3, Count: number, Width: number, Roundabout: boolean }
local nodeCache: { [string]: Node }? = nil
function Roads.nodeMap(): { [string]: Node }
	if nodeCache then
		return nodeCache
	end
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
	for _, s in Roads.segments() do
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
	nodeCache = map
	return map
end

---------------------------------------------------------------------
-- Cruces: brazos de cada nodo y dónde empieza la acera de cada uno
---------------------------------------------------------------------
type Arm = { Seg: Segment, End: string, Dir: Vector3, Perp: Vector3, Len: number, H: number, Walk: number, Trim: number, RoadTrim: number, MarkTrim: number }
type Junction = { Node: Node, Arms: { Arm }, Radius: number }

-- ¿Se solapan dos rectángulos girados? (c = centro, ejes unitarios u/w, medias medidas e1/e2)
local function overlap(c1: Vector3, a1: Vector3, b1: Vector3, e1a: number, e1b: number, c2: Vector3, a2: Vector3, b2: Vector3, e2a: number, e2b: number): boolean
	local d = c2 - c1
	for _, L in { a1, b1, a2, b2 } do
		local r1 = e1a * math.abs(a1:Dot(L)) + e1b * math.abs(b1:Dot(L))
		local r2 = e2a * math.abs(a2:Dot(L)) + e2b * math.abs(b2:Dot(L))
		if math.abs(d:Dot(L)) >= r1 + r2 - 0.05 then
			return false
		end
	end
	return true
end

local junctionCache: { [string]: Junction }? = nil
function Roads.junctions(): { [string]: Junction }
	if junctionCache then
		return junctionCache
	end
	local out = {}
	local map = Roads.nodeMap()
	local arms: { [string]: { Arm } } = {}
	for _, s in Roads.segments() do
		local kind = Roads.Kinds[s.Kind]
		local len = (s.B - s.A).Magnitude
		for _, e in { "A", "B" } do
			local p = if e == "A" then s.A else s.B
			local dir = if e == "A" then (s.B - s.A).Unit else (s.A - s.B).Unit
			local k = key(p)
			arms[k] = arms[k] or {}
			table.insert(arms[k], { Seg = s, End = e, Dir = dir, Perp = perpOf(dir), Len = len, H = kind.Road / 2, Walk = kind.Walk, Trim = 0, RoadTrim = 0, MarkTrim = 0 })
		end
	end
	for k, n in map do
		local list = arms[k] or {}
		local radius = 0
		if n.Roundabout then
			for _, arm in list do
				arm.RoadTrim = ROUNDABOUT_R - 6
				arm.Trim = math.sqrt((ROUNDABOUT_R - 1) ^ 2 - arm.H ^ 2)
				arm.MarkTrim = ROUNDABOUT_R + RING_WALK + 0.8
			end
			radius = ROUNDABOUT_R + RING_WALK
		elseif #list >= 2 then
			local c = n.Position
			for i, arm in list do
				local T = arm.H + arm.Walk
				if arm.Walk > 0 then
					while T < 150 do
						local clash = false
						local bl = math.min(arm.Len - T, 60)
						if bl < 1 then
							break
						end
						for _, side in { -1, 1 } do
							local c1 = c + arm.Dir * (T + bl / 2) + arm.Perp * (side * (arm.H + arm.Walk / 2))
							for j, other in list do
								if j ~= i then
									local lj = math.min(other.Len, 90)
									local c2 = c + other.Dir * (lj / 2)
									if overlap(c1, arm.Dir, arm.Perp, bl / 2, arm.Walk / 2, c2, other.Dir, other.Perp, lj / 2, other.H - 0.2) then
										clash = true
									end
								end
							end
						end
						if not clash then
							break
						end
						T += 0.5
					end
				end
				arm.Trim = T
				arm.RoadTrim = 0
				arm.MarkTrim = T + (if arm.Walk > 0 then 6.5 else 0)
				radius = math.max(radius, math.sqrt(T * T + (arm.H + arm.Walk) ^ 2) + 0.5)
			end
		end
		out[k] = { Node = n, Arms = list, Radius = radius }
	end
	junctionCache = out
	return out
end

-- Recortes de un tramo en sus dos extremos (acera, calzada y marcas)
local function trimsOf(s: Segment): (Arm?, Arm?)
	local J = Roads.junctions()
	local ja, jb = J[key(s.A)], J[key(s.B)]
	local armA, armB = nil, nil
	if ja and (ja.Node.Roundabout or #ja.Arms >= 2) then
		for _, arm in ja.Arms do
			if arm.Seg == s and arm.End == "A" then
				armA = arm
			end
		end
	end
	if jb and (jb.Node.Roundabout or #jb.Arms >= 2) then
		for _, arm in jb.Arms do
			if arm.Seg == s and arm.End == "B" then
				armB = arm
			end
		end
	end
	return armA, armB
end

-- ¿Este punto está sobre agua (río o lago)?
local function overWater(p: Vector3): boolean
	if CityPlan.riverDistance(p.X, p.Z) < CityPlan.River.Width / 2 + 12 then
		return true
	end
	for _, lake in CityPlan.Lakes do
		if (V3(lake.X, 0, lake.Z) - p).Magnitude < lake.R + 6 then
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

local function disc(parent: Instance, name: string, p: Vector3, radius: number, y0: number, y1: number, color: Color3, material: Enum.Material, decor: boolean?): BasePart
	local props = {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = V3(y1 - y0, radius * 2, radius * 2),
		CFrame = CFrame.new(p.X, (y0 + y1) / 2, p.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		Parent = parent,
	}
	return if decor then Builder.decor(props) else Builder.part(props)
end

-- Caja entre dos puntos del suelo (a lo largo de a→b), de ancho "width"
local function between(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, y0: number, y1: number, color: Color3, material: Enum.Material, decor: boolean?): BasePart?
	local d = V3(b.X - a.X, 0, b.Z - a.Z)
	local len = d.Magnitude
	if len < 0.05 then
		return nil
	end
	local mid = (a + b) / 2
	return box(parent, name, Builder.facing(V3(mid.X, (y0 + y1) / 2, mid.Z), d), V3(width, y1 - y0, len), color, material, decor)
end

-- Intervalos: [a, b] ∩ lista y [a, b] menos lista
local function clipTo(list: { { number } }, a: number, b: number): { { number } }
	local out = {}
	for _, p in list do
		local x0, x1 = math.max(p[1], a), math.min(p[2], b)
		if x1 - x0 > 0.05 then
			table.insert(out, { x0, x1 })
		end
	end
	return out
end
local function minus(a: number, b: number, list: { { number } }): { { number } }
	local pieces = { { a, b } }
	for _, c in list do
		local out = {}
		for _, p in pieces do
			if c[2] <= p[1] or c[1] >= p[2] then
				table.insert(out, p)
			else
				if c[1] > p[1] then
					table.insert(out, { p[1], c[1] })
				end
				if c[2] < p[2] then
					table.insert(out, { c[2], p[2] })
				end
			end
		end
		pieces = out
	end
	return pieces
end

type SegmentPlan = {
	RoadA: number,
	RoadB: number,
	MarkA: number,
	MarkB: number,
	Walk: { [number]: { number } }, -- [lado] = { desde, hasta }
	Cuts: { [number]: { { number } } }, -- [lado] = bocas abiertas en la acera
}

local function buildSegment(parent: Instance, s: Segment, plan: SegmentPlan, kerbFree: ((Vector3) -> boolean)?)
	local kind = Roads.Kinds[s.Kind]
	local dir = (s.B - s.A).Unit
	local perp = perpOf(dir)
	local half = kind.Road / 2
	local function frame(d0: number, d1: number): CFrame
		return Builder.facing(s.A + dir * ((d0 + d1) / 2), dir)
	end
	-- Trozos de la calzada: en tierra bajan hasta Y = -4 (ahí el terreno está hundido, así no
	-- asoma ni queda hueco por los lados); sobre el agua son finos (puente)
	local pieces: { { number } } = {} -- { desde, hasta, 1 = sobre agua }
	do
		local a, b = plan.RoadA, plan.RoadB
		local from, wet = a, overWater(s.A + dir * a)
		for d = a + 5, b, 5 do
			local w = overWater(s.A + dir * d)
			if w ~= wet then
				table.insert(pieces, { from, d, if wet then 1 else 0 })
				from, wet = d, w
			end
		end
		table.insert(pieces, { from, b, if wet then 1 else 0 })
	end
	-- Acera de cada lado (sin las bocas) y, donde no hay acera, asfalto hasta el borde
	local walks: { [number]: { { number } } } = {}
	local fills: { [number]: { { number } } } = {}
	if kind.Walk > 0 then
		for _, side in { -1, 1 } do
			local w = plan.Walk[side]
			local list = minus(w[1], w[2], plan.Cuts[side] or {})
			list = clipTo(list, plan.RoadA, plan.RoadB)
			walks[side] = list
			fills[side] = minus(plan.RoadA, plan.RoadB, list)
		end
	end
	for _, piece in pieces do
		local len = piece[2] - piece[1]
		if len > 0.05 then
			local bottom = if piece[3] == 1 then 0 else BASE
			local cf = frame(piece[1], piece[2])
			box(parent, "Road", cf * CFrame.new(0, (bottom + ROAD_TOP) / 2, 0), V3(kind.Road, ROAD_TOP - bottom, len), G.Asphalt, Enum.Material.Asphalt)
			if kind.Walk > 0 then
				for _, side in { -1, 1 } do
					local x = side * (half + kind.Walk / 2)
					for _, w in clipTo(walks[side], piece[1], piece[2]) do
						box(parent, "Sidewalk", frame(w[1], w[2]) * CFrame.new(x, (bottom + WALK_TOP) / 2, 0), V3(kind.Walk, WALK_TOP - bottom, w[2] - w[1]), G.Sidewalk, Enum.Material.Pavement)
					end
					for _, f in clipTo(fills[side], piece[1], piece[2]) do
						box(parent, "Road", frame(f[1], f[2]) * CFrame.new(x, (bottom + ROAD_TOP) / 2, 0), V3(kind.Walk, ROAD_TOP - bottom, f[2] - f[1]), G.Asphalt, Enum.Material.Asphalt)
					end
				end
			end
		end
	end
	-- Sin acera (autovía): bordillo bajo de hormigón a cada lado, en trozos largos. Se corta en los
	-- cruces, rotondas y bocas de calle (kerbFree) y sobre el agua (ahí va el muro del puente).
	if kind.Walk == 0 and kerbFree then
		local STEP = 4
		for _, side in { -1, 1 } do
			local runFrom: number? = nil
			local function close(to: number)
				if runFrom and to - runFrom >= 6 then
					local from = runFrom :: number
					box(parent, "RoadKerb", frame(from, to) * CFrame.new(side * (half + 0.3), 0.7, 0), V3(0.6, 1, to - from), rgb(190, 188, 182), Enum.Material.Concrete)
				end
				runFrom = nil
			end
			local d = plan.RoadA
			while d <= plan.RoadB do
				local q = s.A + dir * d + perp * side * (half + 0.3)
				local ok = not overWater(s.A + dir * d) and kerbFree(q)
				if ok then
					runFrom = runFrom or d
				else
					close(d - STEP)
				end
				d += STEP
			end
			close(math.min(d - STEP, plan.RoadB))
		end
	end
	-- Mediana (autovía) o línea central
	local m0, m1 = plan.MarkA, plan.MarkB
	if m1 - m0 > 2 then
		local mcf = frame(m0, m1)
		local mlen = m1 - m0
		if kind.Median > 0 then
			box(parent, "Median", mcf * CFrame.new(0, 0.7, 0), V3(kind.Median, 0.6, mlen - 2), rgb(196, 192, 184), Enum.Material.Concrete)
			box(parent, "MedianGrass", mcf * CFrame.new(0, 1.02, 0), V3(kind.Median - 0.8, 0.06, mlen - 2.8), rgb(92, 140, 66), Enum.Material.Grass, true)
			for _, x in { -half + 1.2, half - 1.2, -kind.Median / 2 - 0.8, kind.Median / 2 + 0.8 } do
				box(parent, "Marking", mcf * CFrame.new(x, 0.42, 0), V3(0.35, 0.04, mlen), G.Marking, Enum.Material.SmoothPlastic, true)
			end
		else
			box(parent, "Marking", mcf * CFrame.new(0, 0.42, 0), V3(0.4, 0.04, mlen), G.MarkingYellow, Enum.Material.SmoothPlastic, true)
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
		local centre = frame(from, to)
		local outer = half + kind.Walk
		for _, side in { -1, 1 } do
			box(parent, "BridgeRail", centre * CFrame.new(side * (outer + 0.3), 2.6, 0), V3(0.5, 0.5, len), rgb(210, 214, 220), Enum.Material.Metal)
			box(parent, "BridgeWall", centre * CFrame.new(side * (outer + 0.3), 1.3, 0), V3(0.6, 2.6, len), rgb(170, 166, 158), Enum.Material.Concrete)
		end
		box(parent, "BridgeDeck", centre * CFrame.new(0, -0.8, 0), V3(outer * 2 + 1.2, 1.6, len), rgb(150, 146, 140), Enum.Material.Concrete)
		for d = 12, len - 12, 34 do
			box(parent, "Pillar", centre * CFrame.new(0, -7, len / 2 - d), V3(outer * 1.4, 12, 4), rgb(150, 146, 140), Enum.Material.Concrete)
		end
	end
	for d = plan.RoadA, plan.RoadB, step do
		local p = s.A + dir * d
		if overWater(p) then
			bridgeFrom = bridgeFrom or math.max(plan.RoadA, d - step)
		else
			closeBridge(d)
		end
	end
	closeBridge(plan.RoadB)
	-- Farolas (alternando lados), no sobre el puente ni en una boca
	local w0 = math.max(plan.Walk[-1][1], plan.Walk[1][1])
	local w1 = math.min(plan.Walk[-1][2], plan.Walk[1][2])
	local d = w0 + kind.Lamp / 2
	local side = 1
	while d < w1 - 10 do
		local p = s.A + dir * d
		local inCut = false
		for _, c in plan.Cuts[side] or {} do
			if d > c[1] - 5 and d < c[2] + 5 then
				inCut = true
			end
		end
		if not overWater(p) and not inCut then
			local offset = if kind.Walk > 0 then half + kind.Walk - 1 else half + 2
			Props.lamp(parent, Builder.facing(p + perp * side * offset + V3(0, if kind.Walk > 0 then WALK_TOP else 0, 0), -perp * side))
		end
		d += kind.Lamp
		side = -side
	end
end

---------------------------------------------------------------------
-- Cruces: disco de asfalto, esquinas de acera y pasos de cebra
---------------------------------------------------------------------
local function buildJunction(parent: Instance, J: Junction, blocked: (Vector3) -> boolean, cutNear: (Segment, number, number) -> boolean)
	local c = J.Node.Position
	local m = Builder.model("Cruce", parent)
	disc(m, "Junction", c, J.Radius, BASE, ROAD_TOP, G.Asphalt, Enum.Material.Asphalt)
	-- Brazos por ángulo; cada pareja seguida se une por su acera
	local arms = table.clone(J.Arms)
	table.sort(arms, function(a, b)
		return math.atan2(a.Dir.Z, a.Dir.X) < math.atan2(b.Dir.Z, b.Dir.X)
	end)
	for i, a in arms do
		local b = arms[i % #arms + 1]
		if a.Walk > 0 and b.Walk > 0 and a ~= b then
			local angA = math.atan2(a.Dir.Z, a.Dir.X)
			local gap = (math.atan2(b.Dir.Z, b.Dir.X) - angA) % (2 * math.pi)
			if #arms == 1 then
				gap = 2 * math.pi
			end
			local ra = a.H + a.Walk / 2
			local rb = b.H + b.Walk / 2
			local PA = c + a.Dir * a.Trim + a.Perp * ra
			local PB = c + b.Dir * b.Trim - b.Perp * rb
			local width = math.min(a.Walk, b.Walk)
			if gap < math.pi - 0.1 then
				-- Esquina por dentro: un trozo recto de acera de una punta a la otra
				local dir = (PB - PA)
				if dir.Magnitude > 0.1 then
					local u = dir.Unit
					local ext = width / 2
					local p0, p1 = PA - u * ext, PB + u * ext
					if not blocked((p0 + p1) / 2) and not blocked(p0) and not blocked(p1) then
						between(m, "Sidewalk", p0, p1, width + 0.6, BASE, WALK_TOP, G.Sidewalk, Enum.Material.Pavement)
					end
				end
			else
				-- Esquina por fuera: arco de acera alrededor del cruce
				local fa = math.atan2((PA - c).Z, (PA - c).X)
				local sweep = (math.atan2((PB - c).Z, (PB - c).X) - fa) % (2 * math.pi)
				local r0, r1 = (PA - c).Magnitude, (PB - c).Magnitude
				local steps = math.max(2, math.ceil(sweep / math.rad(8)))
				local prev = PA
				for k = 1, steps do
					local t = k / steps
					local f = fa + sweep * t
					local r = r0 + (r1 - r0) * t
					local p = c + V3(math.cos(f), 0, math.sin(f)) * r
					local u = (p - prev).Unit
					if not blocked((prev + p) / 2) and not blocked(prev) and not blocked(p) then
						between(m, "Sidewalk", prev - u * 0.6, p + u * 0.6, width, BASE, WALK_TOP, G.Sidewalk, Enum.Material.Pavement)
					end
					prev = p
				end
			end
		end
	end
	-- Pasos de cebra al llegar al cruce (en los brazos con acera y largos)
	for _, a in arms do
		if a.Walk > 0 and a.Len > a.Trim + 30 then
			local d = a.Trim + 3.5
			local along = if a.End == "A" then d else a.Len - d
			local p = c + a.Dir * d
			if not blocked(p) and not cutNear(a.Seg, along, 14) then
				Bocacalles().crossing(m, p, a.Perp, a.H * 2, 5)
			end
		end
	end
end

---------------------------------------------------------------------
-- Rotondas: anillo liso de asfalto, acera alrededor, isla con bordillo, fuente y árboles
---------------------------------------------------------------------
local function simpleTree(parent: Instance, base: Vector3, h: number, tint: number)
	local m = Builder.model("Arbol", parent)
	Builder.part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = V3(h * 0.55, 1.1, 1.1), CFrame = CFrame.new(base + V3(0, h * 0.275, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(96, 70, 48), Material = Enum.Material.Wood, Parent = m })
	local leaf = rgb(70 + tint * 12, 118 + tint * 10, 58)
	Builder.decor({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = V3(h * 0.62, h * 0.62, h * 0.62), CFrame = CFrame.new(base + V3(0, h * 0.72, 0)), Color = leaf, Material = Enum.Material.LeafyGrass, Parent = m })
	Builder.decor({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = V3(h * 0.45, h * 0.45, h * 0.45), CFrame = CFrame.new(base + V3(h * 0.15, h * 0.95, -h * 0.08)), Color = leaf, Material = Enum.Material.LeafyGrass, Parent = m })
end

local function buildRoundabout(parent: Instance, J: Junction, approaches: { any }, streetAt: (Vector3, number) -> boolean)
	local p = J.Node.Position
	local m = Builder.model("Rotonda", parent)
	local R, I = ROUNDABOUT_R, ISLAND_R
	-- Calzada: un disco liso (hasta Y = -4, el terreno está hundido debajo)
	disc(m, "Road", p, R, BASE, ROAD_TOP, G.Asphalt, Enum.Material.Asphalt)
	-- ¿Este punto cae en la calzada de una calle que entra? (ahí no va acera ni bordillo)
	local function inApproach(q: Vector3, margin: number): boolean
		for _, a in approaches do
			local rel = q - a.E
			if (q - p):Dot(a.D) < 0 and math.abs(rel:Dot(a.N)) < a.H + margin then
				return true
			end
		end
		return streetAt(q, margin)
	end
	-- Acera alrededor (muchos trozos) y bordillo al borde del anillo
	local N = 144
	local dAng = 2 * math.pi / N
	for k = 0, N - 1 do
		local f = (k + 0.5) * dAng
		local dir = V3(math.cos(f), 0, math.sin(f))
		local tangent = V3(-dir.Z, 0, dir.X)
		local rMid = R + RING_WALK / 2
		local chord = 2 * (R + RING_WALK) * math.sin(dAng / 2) + 0.5
		local center = p + dir * rMid
		local blockedHere = false
		for _, corner in { center, center + dir * (RING_WALK / 2) + tangent * (chord / 2), center + dir * (RING_WALK / 2) - tangent * (chord / 2), center - dir * (RING_WALK / 2) + tangent * (chord / 2), center - dir * (RING_WALK / 2) - tangent * (chord / 2) } do
			if inApproach(corner, 0.3) then
				blockedHere = true
			end
		end
		if not blockedHere then
			local cf = Builder.facing(center, tangent)
			box(m, "RingSidewalk", cf * CFrame.new(0, (BASE + WALK_TOP) / 2, 0), V3(RING_WALK, WALK_TOP - BASE, chord), G.Sidewalk, Enum.Material.Pavement)
			-- (el bordillo sobresale 0,05 hacia la calzada: si su cara interior coincide con la de la
			--  acera, las dos parpadean al verse de lejos)
			box(m, "RingCurb", Builder.facing(p + dir * (R + 0.25), tangent) * CFrame.new(0, (ROAD_TOP + WALK_TOP + 0.05) / 2, 0), V3(0.6, WALK_TOP + 0.05 - ROAD_TOP, 2 * (R + 0.6) * math.sin(dAng / 2) + 0.1), G.Curb, Enum.Material.Concrete)
		end
	end
	-- Isla: césped con bordillo de muchos trozos
	disc(m, "Island", p, I, ROAD_TOP, 1.2, rgb(98, 146, 70), Enum.Material.Grass)
	local NI = 64
	for k = 0, NI - 1 do
		local f = (k + 0.5) / NI * 2 * math.pi
		local dir = V3(math.cos(f), 0, math.sin(f))
		local chord = 2 * (I + 1) * math.sin(math.pi / NI) + 0.1
		box(m, "IslandCurb", Builder.facing(p + dir * (I + 0.4), V3(-dir.Z, 0, dir.X)) * CFrame.new(0, (ROAD_TOP + 1.3) / 2, 0), V3(1, 1.3 - ROAD_TOP, chord), G.Curb, Enum.Material.Concrete)
	end
	-- Fuente en el centro, rodeada de flores y árboles
	local fountain = Builder.model("Fuente", m)
	disc(fountain, "FountainBasin", p, 8, 1.2, 2.6, rgb(200, 196, 188), Enum.Material.Limestone)
	disc(fountain, "FountainWater", p + V3(0, 0, 0), 7.2, 2.4, 2.65, rgb(90, 150, 200), Enum.Material.Glass, true).Transparency = 0.25
	disc(fountain, "FountainColumn", p, 1.4, 2.6, 7, rgb(214, 210, 200), Enum.Material.Marble)
	disc(fountain, "FountainBowl", p, 3.4, 7, 7.8, rgb(214, 210, 200), Enum.Material.Marble)
	disc(fountain, "FountainJet", p, 0.7, 7.8, 10.5, rgb(190, 225, 255), Enum.Material.Glass, true).Transparency = 0.35
	fountain:AddTag("Fountain")
	for k = 0, 23 do
		local f = k / 24 * 2 * math.pi
		local colors = { rgb(220, 70, 90), rgb(250, 200, 60), rgb(240, 240, 240), rgb(160, 90, 200) }
		Builder.decor({ Name = "Flowers", Size = V3(2.2, 0.5, 1.4), CFrame = Builder.facing(p + V3(math.cos(f) * 10.5, 1.45, math.sin(f) * 10.5), V3(-math.sin(f), 0, math.cos(f))), Color = colors[k % 4 + 1], Material = Enum.Material.Grass, Parent = m })
	end
	for k = 0, 5 do
		local f = (k + 0.5) / 6 * 2 * math.pi
		simpleTree(m, p + V3(math.cos(f) * 16, 1.2, math.sin(f) * 16), 11 + (k % 3), k % 3)
	end
	-- Marcas: línea discontinua entre los dos carriles del anillo y línea junto a la isla
	local function ringMark(r: number, count: number, fill: number, skipApproach: boolean)
		for k = 0, count - 1 do
			local f = (k + 0.5) / count * 2 * math.pi
			local dir = V3(math.cos(f), 0, math.sin(f))
			local q = p + dir * r
			if not (skipApproach and inApproach(q, 1)) then
				local len = 2 * r * math.sin(math.pi / count) * fill
				box(m, "RingMarking", Builder.facing(q + V3(0, 0.42, 0), V3(-dir.Z, 0, dir.X)), V3(0.35, 0.04, len), G.Marking, Enum.Material.SmoothPlastic, true)
			end
		end
	end
	ringMark((R + I) / 2 + 1, 40, 0.5, false)
	ringMark(I + 2.2, 40, 1.02, false)
	ringMark(R - 1.3, 72, 1.02, true)
	-- Acera a los lados de cada entrada: cierra el hueco entre la acera circular y la calzada que entra
	local function along(a: any, lateral: number, radius: number): number?
		local q = a.E + a.N * lateral - p
		local qd = q:Dot(a.D)
		local disc2 = qd * qd - q:Dot(q) + radius * radius
		if disc2 < 0 then
			return nil
		end
		return -qd - math.sqrt(disc2)
	end
	for _, a in approaches do
		for _, side in { -1, 1 } do
			local lat = side * (a.H + 1.4)
			local t0 = along(a, side * a.H, R - 0.2)
			local t1 = along(a, side * (a.H + 2.8), R + RING_WALK + 0.6)
			if t0 and t1 and t0 - t1 > 0.5 then
				local q0 = a.E + a.N * lat + a.D * t1
				local q1 = a.E + a.N * lat + a.D * t0
				if not streetAt(q0, 0.2) and not streetAt(q1, 0.2) and not streetAt((q0 + q1) / 2, 0.2) then
					between(m, "RingSidewalk", q0, q1, 2.8, BASE, WALK_TOP, G.Sidewalk, Enum.Material.Pavement)
				end
			end
		end
	end
	-- Pasos de cebra en cada entrada, a la altura de la acera de la rotonda
	for _, a in approaches do
		local e0 = a.E - p
		local ed = e0:Dot(a.D)
		local rr = R + RING_WALK / 2
		local disc2 = ed * ed - e0:Dot(e0) + rr * rr
		if disc2 >= 0 and not a.NoCross then
			local t = -ed - math.sqrt(disc2)
			local center = a.E + a.D * t
			Bocacalles().crossing(m, center, a.N, a.H * 2, RING_WALK - 1.2)
			-- Línea de ceda el paso al entrar (en el carril de entrada)
			local tg = -ed - math.sqrt(math.max(0, ed * ed - e0:Dot(e0) + (R - 0.8) ^ 2))
			local g = a.E + a.D * tg
			local side = V3(-a.D.Z, 0, a.D.X)
			for x = 1, a.H - 1.5, 2 do
				box(m, "RingMarking", Builder.facing(g + side * x + V3(0, 0.42, 0), a.D), V3(1.1, 0.04, 0.35), G.Marking, Enum.Material.SmoothPlastic, true)
			end
		end
	end
end

function Roads.build(world: Instance, streets: { any }?)
	local folder = Builder.model("MainRoads", world)
	local B = Bocacalles()
	local mouths = B.compute(streets or {})
	local segments = Roads.segments()
	local J = Roads.junctions()
	-- ¿Cae en la calzada de una calle de barrio? (ni la acera de las rotondas ni las esquinas la pisan)
	local function streetAt(q: Vector3, margin: number): boolean
		for _, road in streets or {} do
			local u = if road.Axis == "X" then q.X else q.Z
			local w = if road.Axis == "X" then q.Z else q.X
			if u > road.From - margin and u < road.To + margin and math.abs(w - road.At) < 12 + margin then
				return true
			end
		end
		return false
	end
	local function blocked(p: Vector3): boolean
		return B.blocked(p, 1) or streetAt(p, 1)
	end
	-- ¿Puede ir el bordillo de la autovía aquí? (no dentro de un cruce, una rotonda ni una boca)
	local function kerbFree(q: Vector3): boolean
		if blocked(q) or streetAt(q, 4) then
			return false
		end
		for _, j in J do
			local c = j.Node.Position
			local r = if j.Node.Roundabout then ROUNDABOUT_R + RING_WALK + 2 else j.Radius + 2
			-- (una curva suave de la misma carretera no es un cruce: ahí el bordillo sigue)
			local bend = #j.Arms == 2 and j.Arms[1].Dir:Dot(j.Arms[2].Dir) < -0.9
			if (#j.Arms >= 2 and not bend) or j.Node.Roundabout then
				if (V3(q.X, 0, q.Z) - V3(c.X, 0, c.Z)).Magnitude < r then
					return false
				end
			end
		end
		return true
	end
	local function cutsOf(s: Segment): { [number]: { { number } } }
		local out = { [-1] = {}, [1] = {} }
		local c = mouths.Cuts[s]
		if c then
			for side, list in c do
				for _, cut in list do
					table.insert(out[side], { cut.From, cut.To })
				end
			end
		end
		return out
	end
	local function cutNear(s: Segment, along: number, margin: number): boolean
		local c = mouths.Cuts[s]
		for _, side in { -1, 1 } do
			for _, cut in (c and c[side]) or {} do
				if along > cut.From - margin and along < cut.To + margin then
					return true
				end
			end
		end
		return false
	end
	for _, s in segments do
		local len = (s.B - s.A).Magnitude
		local armA, armB = trimsOf(s)
		local plan: SegmentPlan = {
			RoadA = if armA then armA.RoadTrim else 0,
			RoadB = len - (if armB then armB.RoadTrim else 0),
			MarkA = if armA then armA.MarkTrim else 0,
			MarkB = len - (if armB then armB.MarkTrim else 0),
			Walk = {},
			Cuts = cutsOf(s),
		}
		for _, side in { -1, 1 } do
			plan.Walk[side] = { if armA then armA.Trim else 0, len - (if armB then armB.Trim else 0) }
		end
		-- Final suelto dentro de una calle de barrio: aceras recortadas (Kit/Bocacalles)
		local clips = mouths.Clips[s]
		if clips then
			for endKey, clip in clips do
				for side, along in clip.Walk do
					if endKey == "A" then
						plan.Walk[side][1] = math.max(plan.Walk[side][1], along)
					else
						plan.Walk[side][2] = math.min(plan.Walk[side][2], along)
					end
				end
				if endKey == "A" then
					plan.MarkA = math.max(plan.MarkA, clip.Mark)
				else
					plan.MarkB = math.min(plan.MarkB, clip.Mark)
				end
			end
		end
		buildSegment(folder, s, plan, kerbFree)
	end
	for k, j in J do
		if j.Node.Roundabout then
			local approaches = {}
			for _, arm in j.Arms do
				table.insert(approaches, { E = j.Node.Position, D = -arm.Dir, N = arm.Perp, H = arm.H, W = arm.H + arm.Walk })
			end
			for _, a in mouths.Approaches[k] or {} do
				table.insert(approaches, a)
			end
			buildRoundabout(folder, j, approaches, streetAt)
		elseif #j.Arms >= 2 then
			buildJunction(folder, j, blocked, cutNear)
		end
	end
	-- Pasos de cebra en las bocas (donde una calle desemboca en otra)
	local crossings = Builder.model("PasosBocacalle", folder)
	-- (si la boca cae en un cruce de las calles del barrio, el paso ya lo pone su cruce)
	local squares = {}
	for _, a in streets or {} do
		if a.Axis == "X" then
			for _, b in streets or {} do
				if b.Axis == "Z" and b.At >= a.From and b.At <= a.To and a.At >= b.From and a.At <= b.To then
					table.insert(squares, V3(b.At, 0, a.At))
				end
			end
		end
	end
	for _, c in mouths.Crossings do
		local inSquare = false
		for _, q in squares do
			if math.abs(c.Center.X - q.X) < 21 and math.abs(c.Center.Z - q.Z) < 21 then
				inSquare = true
				break
			end
		end
		if not inSquare then
			B.crossing(crossings, c.Center, c.WalkDir, c.Length, c.Depth)
		end
	end
	return folder
end

-- Huellas de las carreteras (para hundir el terreno debajo): tramos y círculos
function Roads.footprints(): ({ { A: Vector3, B: Vector3, Width: number } }, { { Position: Vector3, Radius: number } })
	local strips, circles = {}, {}
	for _, s in Roads.segments() do
		local kind = Roads.Kinds[s.Kind]
		table.insert(strips, { A = s.A, B = s.B, Width = kind.Road + kind.Walk * 2 })
	end
	for _, j in Roads.junctions() do
		if j.Radius > 0 then
			table.insert(circles, { Position = j.Node.Position, Radius = j.Radius })
		end
	end
	return strips, circles
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
