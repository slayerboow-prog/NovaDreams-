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

local Street = {}

Street.ROAD_WIDTH = 24
Street.SIDEWALK = 8
Street.HALF = Street.ROAD_WIDTH / 2 + Street.SIDEWALK -- 20: del centro al borde exterior de la acera
Street.ROAD_TOP = 0.4
Street.WALK_TOP = 1.0

local RW = Street.ROAD_WIDTH
local H = Street.HALF
local ROAD_TOP = Street.ROAD_TOP
local WALK_TOP = Street.WALK_TOP
local G = Palette.Ground

export type Road = { Axis: string, At: number, From: number, To: number, Lamps: boolean?, Trees: boolean? }

---------------------------------------------------------------------
-- Geometría
---------------------------------------------------------------------

-- Caja alineada con los ejes del mundo
local function wbox(parent: Instance, x0: number, x1: number, z0: number, z1: number, y0: number, y1: number, props: { [string]: any }, decor: boolean?): BasePart
	props.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	props.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	props.Parent = parent
	return if decor then Builder.decor(props) else Builder.part(props)
end

-- Caja en coordenadas de la calle (u a lo largo, v transversal)
local function rbox(parent: Instance, road: Road, u0: number, u1: number, v0: number, v1: number, y0: number, y1: number, props: { [string]: any }, decor: boolean?): BasePart
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

local function segment(parent: Instance, road: Road, u0: number, u1: number)
	local length = u1 - u0
	if length < 1 then
		return
	end
	rbox(parent, road, u0, u1, -RW / 2, RW / 2, 0, ROAD_TOP, asphalt())
	for _, s in { -1, 1 } do
		local inner, outer = s * RW / 2, s * H
		rbox(parent, road, u0, u1, math.min(inner, outer), math.max(inner, outer), 0, WALK_TOP, pavement())
		local c0, c1 = s * (RW / 2 - 0.05), s * (RW / 2 + 0.55)
		rbox(parent, road, u0, u1, math.min(c0, c1), math.max(c0, c1), ROAD_TOP, WALK_TOP + 0.05, curb())
		-- Línea continua de borde
		local e0, e1 = s * (RW / 2 - 1.4), s * (RW / 2 - 1.0)
		rbox(parent, road, u0, u1, math.min(e0, e1), math.max(e0, e1), ROAD_TOP, ROAD_TOP + 0.04, marking(), true)
	end
	-- Línea discontinua central
	local u = u0 + 3
	while u + 6 <= u1 - 3 do
		rbox(parent, road, u, u + 6, -0.25, 0.25, ROAD_TOP, ROAD_TOP + 0.04, marking(), true)
		u += 12
	end

	-- Farolas al tresbolillo y árboles de alineación
	if road.Lamps ~= false then
		local i = 0
		local lu = u0 + 12
		while lu <= u1 - 8 do
			local s = if i % 2 == 0 then 1 else -1
			local pos = Street.point(road, lu, s * (RW / 2 + 1.8), WALK_TOP)
			Props.lamp(parent, Builder.facing(pos, Street.across(road, -s)))
			if i % 3 == 1 then
				local binPos = Street.point(road, lu + 3, s * (RW / 2 + 1.8), WALK_TOP)
				Props.bin(parent, CFrame.new(binPos))
			end
			i += 1
			lu += 36
		end
	end
	if road.Trees then
		local tu = u0 + 30
		while tu <= u1 - 8 do
			for _, s in { -1, 1 } do
				local v = s * (H - 2.6)
				rbox(parent, road, tu - 1.8, tu + 1.8, v - 1.8, v + 1.8, WALK_TOP, WALK_TOP + 0.05, { Name = "TreePit", Color = Color3.fromRGB(84, 64, 46), Material = Enum.Material.Ground }, true)
				Nature.tree(parent, Street.point(road, tu, v, WALK_TOP), 0.75 + math.random() * 0.2)
			end
			tu += 36
		end
	end
end

---------------------------------------------------------------------
-- Cruces
---------------------------------------------------------------------

type Arms = { West: boolean, East: boolean, North: boolean, South: boolean }

local function zebra(parent: Instance, x0: number, x1: number, z0: number, z1: number, alongX: boolean)
	-- Franjas paralelas al tráfico, repartidas a lo ancho de la calzada
	if alongX then
		local z = z0 + 1.5
		while z + 1.5 <= z1 do
			wbox(parent, x0 + 1, x1 - 1, z - 0.8, z + 0.8, ROAD_TOP, ROAD_TOP + 0.04, marking(), true)
			z += 3
		end
	else
		local x = x0 + 1.5
		while x + 1.5 <= x1 do
			wbox(parent, x - 0.8, x + 0.8, z0 + 1, z1 - 1, ROAD_TOP, ROAD_TOP + 0.04, marking(), true)
			x += 3
		end
	end
end

local function intersection(parent: Instance, cx: number, cz: number, arms: Arms)
	local r = RW / 2
	wbox(parent, cx - r, cx + r, cz - r, cz + r, 0, ROAD_TOP, asphalt())

	local strips = {
		{ Open = arms.West, X0 = cx - H, X1 = cx - r, Z0 = cz - r, Z1 = cz + r, AlongX = true },
		{ Open = arms.East, X0 = cx + r, X1 = cx + H, Z0 = cz - r, Z1 = cz + r, AlongX = true },
		{ Open = arms.North, X0 = cx - r, X1 = cx + r, Z0 = cz - H, Z1 = cz - r, AlongX = false },
		{ Open = arms.South, X0 = cx - r, X1 = cx + r, Z0 = cz + r, Z1 = cz + H, AlongX = false },
	}
	for _, s in strips do
		if s.Open then
			wbox(parent, s.X0, s.X1, s.Z0, s.Z1, 0, ROAD_TOP, asphalt())
			zebra(parent, s.X0, s.X1, s.Z0, s.Z1, s.AlongX)
		else
			wbox(parent, s.X0, s.X1, s.Z0, s.Z1, 0, WALK_TOP, pavement())
		end
	end

	-- Esquinas de acera con bordillo
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x0, x1 = math.min(cx + sx * r, cx + sx * H), math.max(cx + sx * r, cx + sx * H)
			local z0, z1 = math.min(cz + sz * r, cz + sz * H), math.max(cz + sz * r, cz + sz * H)
			wbox(parent, x0, x1, z0, z1, 0, WALK_TOP, pavement())
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
end

---------------------------------------------------------------------

function Street.build(parent: Instance, roads: { Road })
	local folder = Builder.model("Streets", parent)
	local cuts: { [Road]: { number } } = {}
	for _, road in roads do
		cuts[road] = {}
	end

	for _, a in roads do
		if a.Axis == "X" then
			for _, b in roads do
				if b.Axis == "Z" and b.At >= a.From and b.At <= a.To and a.At >= b.From and a.At <= b.To then
					table.insert(cuts[a], b.At)
					table.insert(cuts[b], a.At)
					intersection(folder, b.At, a.At, {
						West = a.From < b.At - H,
						East = a.To > b.At + H,
						North = b.From < a.At - H,
						South = b.To > a.At + H,
					})
				end
			end
		end
	end

	for _, road in roads do
		local list = cuts[road]
		table.sort(list)
		local start = road.From
		for _, c in list do
			segment(folder, road, start, c - H)
			start = c + H
		end
		segment(folder, road, start, road.To)
	end
	return folder
end

-- Aparca coches en el borde de una calle, entre u0 y u1, en el lado "side" (+1/-1)
function Street.parkCars(parent: Instance, road: Road, u0: number, u1: number, side: number, chance: number?)
	local u = u0 + 8
	while u <= u1 - 8 do
		if math.random() < (chance or 0.6) then
			local pos = Street.point(road, u, side * (RW / 2 - 3.6), ROAD_TOP)
			local heading = Street.along(road, if side > 0 then 1 else -1)
			Props.car(parent, Builder.facing(pos, heading))
		end
		u += 16
	end
end

return Street
