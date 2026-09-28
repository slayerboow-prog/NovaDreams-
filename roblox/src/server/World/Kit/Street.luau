-- Street: red de calles alineadas con los ejes X y Z.
-- Genera asfalto con líneas, aceras elevadas con bordillo, cruces con pasos de
-- cebra y semáforos, farolas y árboles de alineación.
--
-- Cada calle se describe con:
--   { Axis = "X" | "Z", At = coordenada fija, From = inicio, To = fin,
--     Lamps = true, Trees = false }
-- "u" = posición a lo largo de la calle; "v" = posición transversal (0 = centro).

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Props = require(script.Parent.Props)
local Nature = require(script.Parent.Nature)
local StreetDetail = require(script.Parent.StreetDetail)
local Bocacalles = require(script.Parent.Bocacalles)
local Roads = require(script.Parent.Roads)
local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)

local Street = {}

Street.ROAD_WIDTH = 24
Street.SIDEWALK = 8
Street.HALF = Street.ROAD_WIDTH / 2 + Street.SIDEWALK -- 20: del centro al borde exterior de la acera
Street.ROAD_TOP = 0.4
Street.WALK_TOP = 1.0
-- Las calzadas y aceras bajan hasta aquí: debajo de las calles el terreno está hundido (TerrainBuilder)
-- para que nunca asome por encima del asfalto, y así no queda hueco por los lados.
Street.BASE = -4

local RW = Street.ROAD_WIDTH
local H = Street.HALF
local ROAD_TOP = Street.ROAD_TOP
local WALK_TOP = Street.WALK_TOP
local G = Palette.Ground

export type Road = { Axis: string, At: number, From: number, To: number, Lamps: boolean?, Trees: boolean?, LampEvery: number?, Solid: boolean? }

---------------------------------------------------------------------
-- Geometría
---------------------------------------------------------------------

-- Rotondas: ninguna acera ni bordillo de una calle se mete en su anillo de asfalto
local RING_R = Roads.ROUNDABOUT_R
local function ringNear(x0: number, x1: number, z0: number, z1: number, radius: number): Vector3?
	for _, r in CityPlan.Roundabouts do
		local dx = math.max(x0 - r[1], 0, r[1] - x1)
		local dz = math.max(z0 - r[2], 0, r[2] - z1)
		if dx * dx + dz * dz < radius * radius then
			return Vector3.new(r[1], 0, r[2])
		end
	end
	return nil
end
Street.ringNear = ringNear

-- Caja alineada con los ejes del mundo
local function wbox(parent: Instance, x0: number, x1: number, z0: number, z1: number, y0: number, y1: number, props: { [string]: any }, decor: boolean?, whole: boolean?): BasePart?
	if (props.Name == "Sidewalk" or props.Name == "Curb") and not decor and not whole then
		local c = ringNear(x0, x1, z0, z1, RING_R + 0.5)
		if c then
			-- Troceada en cuadros de 2 studs: fuera los que caen en el anillo (los demás se juntan por filas)
			local nx, nz = math.max(1, math.ceil((x1 - x0) / 2)), math.max(1, math.ceil((z1 - z0) / 2))
			local sx, sz = (x1 - x0) / nx, (z1 - z0) / nz
			local last = nil
			for j = 0, nz - 1 do
				local runStart: number? = nil
				for i = 0, nx do
					local keep = false
					if i < nx then
						local cx, cz = x0 + (i + 0.5) * sx, z0 + (j + 0.5) * sz
						keep = (Vector3.new(cx, 0, cz) - c).Magnitude > RING_R + 0.3
					end
					if keep and not runStart then
						runStart = i
					elseif not keep and runStart then
						last = wbox(parent, x0 + runStart * sx, x0 + i * sx, z0 + j * sz, z0 + (j + 1) * sz, y0, y1, table.clone(props), decor, true)
						runStart = nil
					end
				end
			end
			return last
		end
	end
	props.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	props.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	props.Parent = parent
	return if decor then Builder.decor(props) else Builder.part(props)
end

-- Caja en coordenadas de la calle (u a lo largo, v transversal)
local function rbox(parent: Instance, road: Road, u0: number, u1: number, v0: number, v1: number, y0: number, y1: number, props: { [string]: any }, decor: boolean?): BasePart?
	if road.Axis == "X" then
		return wbox(parent, u0, u1, road.At + v0, road.At + v1, y0, y1, props, decor)
	end
	return wbox(parent, road.At + v0, road.At + v1, u0, u1, y0, y1, props, decor)
end

function Street.point(road: Road, u: number, v: number, y: number): Vector3
	if road.Axis == "X" then
		return Vector3.new(u, y, road.At + v)
	end
	return Vector3.new(road.At + v, y, u)
end

-- Dirección transversal (hacia +v o -v)
function Street.across(road: Road, sign: number): Vector3
	return if road.Axis == "X" then Vector3.new(0, 0, sign) else Vector3.new(sign, 0, 0)
end

function Street.along(road: Road, sign: number): Vector3
	return if road.Axis == "X" then Vector3.new(sign, 0, 0) else Vector3.new(0, 0, sign)
end

local function asphalt()
	return { Name = "Road", Color = G.Asphalt, Material = Enum.Material.Asphalt }
end
local function pavement()
	return { Name = "Sidewalk", Color = G.Sidewalk, Material = Enum.Material.Pavement }
end
local function curb()
	return { Name = "Curb", Color = G.Curb, Material = Enum.Material.Concrete }
end
local function marking(yellow: boolean?)
	return { Name = "Marking", Color = if yellow then G.MarkingYellow else G.Marking, Material = Enum.Material.SmoothPlastic }
end

---------------------------------------------------------------------
-- Tramos
---------------------------------------------------------------------

-- Límites de un tramo: la calzada va de u0 a u1; cada acera (y su bordillo) puede acabar antes
-- (donde la calle desemboca en una carretera o en una rotonda, Kit/Bocacalles) y tener bocas abiertas
-- (donde otra carretera desemboca en ella). Donde no hay acera, la calzada ocupa todo el ancho.
type Limits = { Walk: { [number]: { number } }, Cuts: { [number]: { any } }, Mark: { number } }

local function segment(parent: Instance, road: Road, u0: number, u1: number, limits: Limits?)
	local length = u1 - u0
	if length < 1 then
		return
	end
	local lim: Limits = limits or { Walk = { [-1] = { u0, u1 }, [1] = { u0, u1 } }, Cuts = {}, Mark = { u0, u1 } }
	rbox(parent, road, u0, u1, -RW / 2, RW / 2, Street.BASE, ROAD_TOP, asphalt())
	local m0, m1 = math.max(u0, lim.Mark[1]), math.min(u1, lim.Mark[2])
	for _, s in { -1, 1 } do
		local inner, outer = s * RW / 2, s * H
		local w = lim.Walk[s]
		local walks = Bocacalles.subtract(math.max(u0, w[1]), math.min(u1, w[2]), lim.Cuts[s])
		for _, piece in walks do
			local a, b = piece[1], piece[2]
			if b - a > 0.05 then
				rbox(parent, road, a, b, math.min(inner, outer), math.max(inner, outer), Street.BASE, WALK_TOP, pavement())
				local c0, c1 = s * (RW / 2 - 0.05), s * (RW / 2 + 0.55)
				rbox(parent, road, a, b, math.min(c0, c1), math.max(c0, c1), ROAD_TOP, WALK_TOP + 0.05, curb())
			end
		end
		-- Sin acera (boca abierta o final dentro de otra carretera): asfalto hasta el borde
		local cover = {}
		for _, piece in walks do
			table.insert(cover, { From = piece[1], To = piece[2] })
		end
		for _, gap in Bocacalles.subtract(u0, u1, cover) do
			if gap[2] - gap[1] > 0.05 then
				rbox(parent, road, gap[1], gap[2], math.min(inner, outer), math.max(inner, outer), Street.BASE, ROAD_TOP, asphalt())
			end
		end
		-- Línea continua de borde
		if m1 - m0 > 1 then
			local e0, e1 = s * (RW / 2 - 1.4), s * (RW / 2 - 1.0)
			for _, piece in Bocacalles.subtract(m0, m1, lim.Cuts[s]) do
				if piece[2] - piece[1] > 0.5 then
					rbox(parent, road, piece[1], piece[2], math.min(e0, e1), math.max(e0, e1), ROAD_TOP, ROAD_TOP + 0.04, marking(), true)
				end
			end
		end
	end
	-- Línea central: discontinua (continua en las calles secundarias: una sola pieza)
	if m1 - m0 > 5 then
		if road.Solid then
			rbox(parent, road, m0 + 2, m1 - 2, -0.2, 0.2, ROAD_TOP, ROAD_TOP + 0.04, marking(true), true)
		else
			local u = m0 + 3
			while u + 6 <= m1 - 3 do
				rbox(parent, road, u, u + 6, -0.25, 0.25, ROAD_TOP, ROAD_TOP + 0.04, marking(), true)
				u += 12
			end
		end
	end
	local function freeAt(u: number, s: number): boolean
		return not Bocacalles.inCut(u, lim.Cuts[s], 6)
	end
	u0, u1 = m0, m1
	if u1 - u0 < 1 then
		return
	end

	-- Farolas al tresbolillo y árboles de alineación
	if road.Lamps ~= false then
		local i = 0
		local lu = u0 + 12
		while lu <= u1 - 8 do
			local s = if i % 2 == 0 then 1 else -1
			local pos = Street.point(road, lu, s * (RW / 2 + 1.8), WALK_TOP)
			local lampCf = Builder.facing(pos, Street.across(road, -s))
			if freeAt(lu, s) then
				Props.lamp(parent, lampCf)
				StreetDetail.lampBanner(parent, lampCf, i)
			end
			if i % 3 == 1 and freeAt(lu + 3, s) then
				local binPos = Street.point(road, lu + 3, s * (RW / 2 + 1.8), WALK_TOP)
				Props.bin(parent, CFrame.new(binPos))
			end
			i += 1
			lu += road.LampEvery or 36
		end
	end
	if road.Trees then
		local tu = u0 + 30
		while tu <= u1 - 8 do
			for _, s in { -1, 1 } do
				if not freeAt(tu, s) then
					continue
				end
				local v = s * (H - 2.6)
				rbox(parent, road, tu - 1.8, tu + 1.8, v - 1.8, v + 1.8, WALK_TOP, WALK_TOP + 0.05, { Name = "TreePit", Color = Color3.fromRGB(84, 64, 46), Material = Enum.Material.Ground }, true)
				Nature.tree(parent, Street.point(road, tu, v, WALK_TOP), 0.75 + math.random() * 0.2)
			end
			tu += 36
		end
	end

	-- Detalles de la acera y de la calzada (Kit/StreetDetail)
	StreetDetail.segment(parent, road, u0, u1, function(u, v, y)
		return Street.point(road, u, v, y)
	end, function(sign)
		return Street.across(road, sign)
	end, RW, WALK_TOP, ROAD_TOP, freeAt)
end

---------------------------------------------------------------------
-- Cruces
---------------------------------------------------------------------

type Arms = { West: boolean, East: boolean, North: boolean, South: boolean }

-- Paso de cebra en el brazo abierto de un cruce: se cruza de esquina a esquina, con rampas
local function zebra(parent: Instance, x0: number, x1: number, z0: number, z1: number, alongX: boolean)
	local center = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
	if alongX then
		Bocacalles.crossing(parent, center, Vector3.new(0, 0, 1), z1 - z0, x1 - x0 - 1, nil, ROAD_TOP, WALK_TOP)
	else
		Bocacalles.crossing(parent, center, Vector3.new(1, 0, 0), x1 - x0, z1 - z0 - 1, nil, ROAD_TOP, WALK_TOP)
	end
end

local function intersection(parent: Instance, cx: number, cz: number, arms: Arms, roadA: Road?, roadB: Road?)
	local r = RW / 2
	wbox(parent, cx - r, cx + r, cz - r, cz + r, Street.BASE, ROAD_TOP, asphalt())

	local strips = {
		{ Open = arms.West, X0 = cx - H, X1 = cx - r, Z0 = cz - r, Z1 = cz + r, AlongX = true },
		{ Open = arms.East, X0 = cx + r, X1 = cx + H, Z0 = cz - r, Z1 = cz + r, AlongX = true },
		{ Open = arms.North, X0 = cx - r, X1 = cx + r, Z0 = cz - H, Z1 = cz - r, AlongX = false },
		{ Open = arms.South, X0 = cx - r, X1 = cx + r, Z0 = cz + r, Z1 = cz + H, AlongX = false },
	}
	for _, s in strips do
		if s.Open then
			wbox(parent, s.X0, s.X1, s.Z0, s.Z1, Street.BASE, ROAD_TOP, asphalt())
			-- (junto a una rotonda el paso de peatones es el de la rotonda)
			if not ringNear(s.X0, s.X1, s.Z0, s.Z1, RING_R + 1) then
				zebra(parent, s.X0, s.X1, s.Z0, s.Z1, s.AlongX)
			end
		else
			wbox(parent, s.X0, s.X1, s.Z0, s.Z1, Street.BASE, WALK_TOP, pavement())
		end
	end

	-- Esquinas de acera con bordillo
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x0, x1 = math.min(cx + sx * r, cx + sx * H), math.max(cx + sx * r, cx + sx * H)
			local z0, z1 = math.min(cz + sz * r, cz + sz * H), math.max(cz + sz * r, cz + sz * H)
			wbox(parent, x0, x1, z0, z1, Street.BASE, WALK_TOP, pavement())
			local ex = cx + sx * r -- borde hacia la calle N-S
			local ez = cz + sz * r -- borde hacia la calle E-O
			wbox(parent, math.min(ex, ex + sx * 0.6), math.max(ex, ex + sx * 0.6), z0, z1, ROAD_TOP, WALK_TOP + 0.05, curb())
			wbox(parent, x0, x1, math.min(ez, ez + sz * 0.6), math.max(ez, ez + sz * 0.6), ROAD_TOP, WALK_TOP + 0.05, curb())
		end
	end

	-- Semáforos en dos esquinas opuestas
	local p1 = Vector3.new(cx + r + 1.5, WALK_TOP, cz + r + 1.5)
	Props.trafficLight(parent, Builder.facing(p1, Vector3.new(0, 0, -1)), 11)
	local p2 = Vector3.new(cx - r - 1.5, WALK_TOP, cz - r - 1.5)
	Props.trafficLight(parent, Builder.facing(p2, Vector3.new(1, 0, 0)), 11)
	-- Poste con el nombre de las dos calles (en otra esquina)
	if roadA and roadB then
		StreetDetail.corner(parent, Vector3.new(cx + r + 1.4, WALK_TOP, cz - r - 1.4), roadA, roadB)
	end
end

---------------------------------------------------------------------

function Street.build(parent: Instance, roads: { Road })
	local folder = Builder.model("Streets", parent)
	local cuts: { [Road]: { number } } = {}
	for _, road in roads do
		cuts[road] = {}
	end
	-- Donde desemboca en una carretera o una rotonda, o recibe una carretera (Kit/Bocacalles)
	local mouths = Bocacalles.compute(roads)
	local function mouthAt(road: Road, side: number, u: number): boolean
		for _, c in (mouths.Cuts[road] or {})[side] or {} do
			if u > c.From - 1 and u < c.To + 1 then
				return true
			end
		end
		return false
	end

	for _, a in roads do
		if a.Axis == "X" then
			for _, b in roads do
				if b.Axis == "Z" and b.At >= a.From and b.At <= a.To and a.At >= b.From and a.At <= b.To then
					table.insert(cuts[a], b.At)
					table.insert(cuts[b], a.At)
					-- Un brazo también se abre si por ahí llega una carretera principal (Kit/Bocacalles)
					intersection(folder, b.At, a.At, {
						West = a.From < b.At - H or mouthAt(b, -1, a.At),
						East = a.To > b.At + H or mouthAt(b, 1, a.At),
						North = b.From < a.At - H or mouthAt(a, -1, b.At),
						South = b.To > a.At + H or mouthAt(a, 1, b.At),
					}, a, b)
				end
			end
		end
	end

	for _, road in roads do
		local list = cuts[road]
		table.sort(list)
		local clips = mouths.Clips[road] or {}
		local holes = mouths.Cuts[road] or {}
		local limits: Limits = { Walk = { [-1] = { road.From, road.To }, [1] = { road.From, road.To } }, Cuts = holes, Mark = { road.From, road.To } }
		for endKey, clip in clips do
			for side, u in clip.Walk do
				if endKey == "A" then
					limits.Walk[side][1] = math.max(limits.Walk[side][1], u)
				else
					limits.Walk[side][2] = math.min(limits.Walk[side][2], u)
				end
			end
			if endKey == "A" then
				limits.Mark[1] = math.max(limits.Mark[1], clip.Mark)
			else
				limits.Mark[2] = math.min(limits.Mark[2], clip.Mark)
			end
		end
		local start = road.From
		for _, c in list do
			segment(folder, road, start, c - H, limits)
			start = c + H
		end
		segment(folder, road, start, road.To, limits)
	end
	return folder
end

-- Aparca coches en el borde de una calle, entre u0 y u1, en el lado "side" (+1/-1)
function Street.parkCars(parent: Instance, road: Road, u0: number, u1: number, side: number, chance: number?)
	local u = u0 + 8
	while u <= u1 - 8 do
		if math.random() < (chance or 0.6) then
			local pos = Street.point(road, u, side * (RW / 2 - 3.1), ROAD_TOP) -- carril de aparcamiento (el tráfico va por dentro)
			local heading = Street.along(road, if side > 0 then 1 else -1)
			Props.car(parent, Builder.facing(pos, heading))
		end
		u += 16
	end
end

return Street
