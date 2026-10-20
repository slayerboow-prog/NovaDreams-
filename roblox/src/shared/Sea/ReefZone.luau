-- ReefZone: la ZONA DE REFERENCIA del mar (encargo v2 del dueño, docs/mar/encargo-v2-reconstruccion.md y
-- docs/mar/diseno-v2.md). Una sola zona hecha con la máxima calidad antes de tocar las demás:
--
--   El Cañón de Dorada: delante de Playa Dorada (la playa del este), del jardín de coral de la orilla
--   (Ocean.ShoreReefs «CoralDorada», a 3-4 m) sale un cañón que baja hacia mar abierto entre dos
--   paredes de roca de 25 a 110 studs, con repisas de coral, salientes, un arco, una cueva con
--   claraboyas y un jardín que brilla, un bosque de kelp gigante, columnas de piedra, unas ruinas con
--   una pirámide que no es de nadie de aquí y, al fondo, el borde del abismo con agujas lejanas.
--
--   Regiones (encargo §10): B jardín coralino (la entrada) · A arrecife exterior (la cima de la pared
--   norte y sus repisas) · C caverna (la Cueva de la Luz, pared sur) · E ruinas sumergidas (la Pirámide
--   Hundida, en el ensanche) · D abismo (la caída del final, oscura, con agujas).
--
-- Todo es DATO puro (sin Instance): se prueba fuera de Roblox (scripts/test-reefzone.luau, la «revisión
-- desde la cámara» con rayos: scripts/test-reefzone-camera.luau) y lo construye World/ReefZoneBuilder:
--
--   ReefZone.carve(x, z, base)   el lecho del cañón (lo usa Ocean.sample: el fondo del heightfield)
--   ReefZone.Ops                 lo que se esculpe encima con el terreno (FillBall/FillBlock/FillCylinder,
--                                en orden; Water = hueco: cueva, arco, claraboya)
--   ReefZone.solid(x, y, z, floorFn)  ¿hay roca aquí? (heightfield + Ops en orden): la misma regla que el
--                                terreno de verdad (para colocar cosas y para la revisión con rayos)
--   ReefZone.placements(floorFn) dónde va cada pieza del kit (corales, kelp, rocas, luz, ruinas…)
--   ReefZone.Lights / Shafts / Emitters / Cameras / Pois
--
-- Coordenadas del mundo (studs). La costa de Playa Dorada está en x ≈ 4215 a esta altura (z ≈ -300).

local ReefZone = {}

local sqrt, floor, sin, cos, abs, min, max, pi = math.sqrt, math.floor, math.sin, math.cos, math.abs, math.min, math.max, math.pi

ReefZone.Name = "Cañón de Dorada"
ReefZone.Surface = -2

-- La caja de la zona (lo de fuera no se toca)
ReefZone.Box = { MinX = 4250, MaxX = 4900, MinZ = -470, MaxZ = -130 }
ReefZone.TopLimit = -9 -- nada sólido por encima de esto (los barcos: Boats.Draft + margen; nadar a 2 m)

---------------------------------------------------------------------
-- Ruido y azar repetibles (no se usa Ocean: Ocean usa este módulo)
---------------------------------------------------------------------
local function hash(a: number, b: number, c: number): number
	local n = sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453
	return n - floor(n)
end
ReefZone.hash = hash

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function vnoise(x: number, z: number, scale: number, seed: number): number
	local gx, gz = x / scale, z / scale
	local x0, z0 = floor(gx), floor(gz)
	local fx, fz = smooth(gx - x0), smooth(gz - z0)
	local a = hash(x0, z0, seed)
	local b = hash(x0 + 1, z0, seed)
	local c = hash(x0, z0 + 1, seed)
	local d = hash(x0 + 1, z0 + 1, seed)
	return lerp(lerp(a, b, fx), lerp(c, d, fx), fz)
end
ReefZone.noise = vnoise

---------------------------------------------------------------------
-- El cañón: eje, lecho y anchura
---------------------------------------------------------------------
ReefZone.StartX = 4330 -- el borde del jardín de coral (de aquí al este baja el cañón)
ReefZone.EndX = 4880
ReefZone.CenterZ = -300

-- Eje del cañón (serpentea un poco: así ninguna vista es un pasillo recto)
function ReefZone.axisZ(x: number): number
	local t = math.max(0, x - ReefZone.StartX)
	return ReefZone.CenterZ + 26 * sin(t / 95) - 10 * sin(t / 41)
end

-- Nudos del lecho: { x, altura del lecho, media anchura del fondo }
ReefZone.Knots = {
	{ 4330, -15, 14 }, -- borde del jardín (3,6 m)
	{ 4372, -27, 18 }, -- el labio: aquí empieza a caer
	{ 4420, -40, 24 }, -- (10,6 m: se llega sin equipo)
	{ 4480, -46, 30 }, -- la cueva (sur) y el kelp (norte)
	{ 4540, -55, 32 }, -- el arco
	{ 4600, -66, 46 }, -- el ensanche de las ruinas
	{ 4660, -74, 58 }, -- la Pirámide Hundida (~20 m)
	{ 4725, -92, 44 },
	{ 4795, -118, 46 }, -- el borde del abismo
	{ 4880, -136, 52 },
}

function ReefZone.bedAt(x: number): (number, number)
	local K = ReefZone.Knots
	if x <= K[1][1] then
		return K[1][2], K[1][3]
	end
	for i = 1, #K - 1 do
		local a, b = K[i], K[i + 1]
		if x <= b[1] then
			local t = smooth((x - a[1]) / (b[1] - a[1]))
			return lerp(a[2], b[2], t), lerp(a[3], b[3], t)
		end
	end
	local last = K[#K]
	return last[2], last[3]
end

ReefZone.WallBlend = 26 -- lo que tarda el lecho en volver al fondo de fuera (lo tapa la pared)

-- ¿Está (x, z) en la zona?
function ReefZone.contains(x: number, z: number): boolean
	local b = ReefZone.Box
	return x >= b.MinX and x <= b.MaxX and z >= b.MinZ and z <= b.MaxZ
end

-- ¿Es el cañón? (la zona «Canon» del HUD: del labio del jardín al borde del abismo)
function ReefZone.inCanyon(x: number, z: number): boolean
	return ReefZone.contains(x, z) and x >= ReefZone.StartX + 12
end

-- Distancia al eje (con signo: + al sur, z mayor; en Roblox el norte es -Z) y la media anchura del lecho
function ReefZone.across(x: number, z: number): (number, number, number)
	local bed, hw = ReefZone.bedAt(x)
	return z - ReefZone.axisZ(x), hw, bed
end

-- Ocean.sample: el lecho del cañón dentro del heightfield (solo baja el fondo)
function ReefZone.carve(x: number, z: number, base: number): (number, number)
	if x < ReefZone.StartX - 10 or x > ReefZone.Box.MaxX or z < ReefZone.Box.MinZ or z > ReefZone.Box.MaxZ then
		return base, 0
	end
	local dz, hw, bed = ReefZone.across(x, z)
	local dist = abs(dz)
	if dist >= hw + ReefZone.WallBlend then
		return base, 0
	end
	local w = 1 - smooth((dist - hw) / ReefZone.WallBlend)
	-- arrugas del lecho: dunas bajas a lo largo del cañón (la corriente) y montículos
	local ripple = sin((x * 0.9 + z * 0.35) / 5.5) * 0.5 + (vnoise(x, z, 22, 41) - 0.5) * 3
	local y = bed + ripple
	-- entrada: no se hunde de golpe junto al jardín (de 0 a 1 en los primeros 25 studs)
	w *= smooth((x - (ReefZone.StartX - 10)) / 25)
	return min(base, lerp(base, y, w)), w
end

---------------------------------------------------------------------
-- La paleta (encargo §5: paleta controlada; docs/mar/diseno-v2.md)
---------------------------------------------------------------------
local function c(r: number, g: number, b: number): { number }
	return { r, g, b }
end
ReefZone.Palette = {
	-- corales: cálidos en la entrada y en las repisas altas (más luz), fríos y morados abajo
	Warm = { c(238, 98, 128), c(248, 146, 74), c(250, 204, 92), c(232, 120, 160) },
	Cool = { c(150, 98, 214), c(92, 200, 196), c(118, 140, 232), c(196, 110, 220) },
	Glow = { c(90, 245, 255), c(150, 255, 190), c(255, 130, 230), c(170, 150, 255) },
	Kelp = { c(118, 132, 52), c(96, 118, 44), c(140, 128, 54) },
	Grass = { c(78, 150, 92), c(104, 164, 76), c(66, 132, 108) },
	Rock = { c(118, 116, 110), c(104, 108, 112), c(132, 124, 112) },
	Sand = c(204, 186, 146), -- arena clara dorada (Salt teñido, World/ReefZoneBuilder + TerrainBuilder.Colors)
	Ruin = { c(70, 92, 104), c(58, 76, 92) },
	RuinGlow = c(80, 236, 255),
}

---------------------------------------------------------------------
-- Las operaciones de terreno (en orden)
---------------------------------------------------------------------
export type Op = {
	Kind: string, -- "Ball" | "Block" | "Cylinder"
	X: number,
	Y: number,
	Z: number,
	R: number?, -- bola y cilindro
	H: number?, -- cilindro (alto, vertical)
	SX: number?, -- bloque (ancho en X, alto, fondo en Z; girado Yaw en Y)
	SY: number?,
	SZ: number?,
	Yaw: number?,
	Material: string, -- material del terreno ("Water" = hueco)
	Tag: string, -- "Wall" | "Plateau" | "Ledge" | "Arch" | "Column" | "Spire" | "Cave" | "Skylight" | "Bommie" | "Patch" | "Mound"
	-- caja (para buscar rápido)
	MinX: number?,
	MaxX: number?,
	MinY: number?,
	MaxY: number?,
	MinZ: number?,
	MaxZ: number?,
}

local function bounds(op: Op): Op
	if op.Kind == "Ball" then
		local r = op.R :: number
		op.MinX, op.MaxX, op.MinY, op.MaxY, op.MinZ, op.MaxZ = op.X - r, op.X + r, op.Y - r, op.Y + r, op.Z - r, op.Z + r
	elseif op.Kind == "Cylinder" then
		local r, h = op.R :: number, op.H :: number
		op.MinX, op.MaxX, op.MinY, op.MaxY, op.MinZ, op.MaxZ = op.X - r, op.X + r, op.Y - h / 2, op.Y + h / 2, op.Z - r, op.Z + r
	else
		local hx, hy, hz = (op.SX :: number) / 2, (op.SY :: number) / 2, (op.SZ :: number) / 2
		local yaw = op.Yaw or 0
		local ex = abs(cos(yaw)) * hx + abs(sin(yaw)) * hz
		local ez = abs(sin(yaw)) * hx + abs(cos(yaw)) * hz
		op.MinX, op.MaxX, op.MinY, op.MaxY, op.MinZ, op.MaxZ = op.X - ex, op.X + ex, op.Y - hy, op.Y + hy, op.Z - ez, op.Z + ez
	end
	return op
end

-- La cima de cada pared (dos lados: -1 norte «arrecife exterior», +1 sur «la cueva»)
function ReefZone.topAt(x: number, side: number): number
	local n = vnoise(x, side * 1000, 38, 51)
	local peaks = (vnoise(x, side * 500, 90, 52) - 0.5) * 6
	local top = if side < 0 then -13 + (n - 0.5) * 5 + peaks else -11 + (n - 0.5) * 5 + peaks
	-- más bajas al final (el borde del abismo: la pared se abre y se ve lejos)
	top -= smooth((x - 4740) / 120) * 22
	-- en la entrada, a ras del jardín
	top = lerp(-16, top, smooth((x - 4345) / 45))
	return min(top, ReefZone.TopLimit - 0.5)
end

local opsCache: { Op }? = nil

local function build(): { Op }
	local ops: { Op } = {}
	local function add(op: Op)
		-- nada sólido por encima de TopLimit (barcos y nadar en la superficie): se baja la pieza
		if op.Material ~= "Water" then
			if op.Kind == "Ball" then
				op.Y = min(op.Y, ReefZone.TopLimit - (op.R :: number))
			elseif op.Kind == "Block" then
				local top = op.Y + (op.SY :: number) / 2
				if top > ReefZone.TopLimit then
					op.Y -= top - ReefZone.TopLimit
				end
			elseif op.Kind == "Cylinder" then
				op.Y = min(op.Y, ReefZone.TopLimit - (op.H :: number) / 2)
			end
		end
		table.insert(ops, bounds(op))
	end
	-- 1. Paredes: columnas de bolas a cada lado (bultos y salientes: nunca una pared lisa)
	for _, side in { -1, 1 } do
		local x = 4352
		local k = 0
		while x < ReefZone.EndX do
			k += 1
			local bed, hw = ReefZone.bedAt(x)
			local axis = ReefZone.axisZ(x)
			local top = ReefZone.topAt(x, side)
			local h = top - bed
			local r = 9 + hash(x, side, 1) * 6
			-- de abajo arriba: bolas que se apilan; las de arriba sobresalen (salientes)
			local y = bed + r * 0.45
			local level = 0
			while y < top - r * 0.35 do
				level += 1
				local frac = (y - bed) / max(h, 1)
				local bulge = if frac > 0.62 and hash(x, level, 2) > 0.45 then -4.5 else 0 -- saliente arriba
				local dist = hw + r * 0.78 + (hash(x, level, 3) - 0.5) * 5 + bulge
				add({ Kind = "Ball", X = x + (hash(level, x, 4) - 0.5) * 6, Y = y, Z = axis + side * dist, R = r * (0.85 + hash(level, side, 5) * 0.3), Material = if hash(x, level, 6) > 0.8 then "Limestone" else "Rock", Tag = "Wall" })
				y += r * (0.95 + hash(k, level, 7) * 0.3)
			end
			-- la cima: una bola ancha que redondea el borde
			add({ Kind = "Ball", X = x, Y = top - r * 0.75, Z = axis + side * (hw + r * 1.15), R = r * 1.05, Material = "Rock", Tag = "Wall" })
			-- detrás: la meseta (montaña de arrecife), maciza hasta su fondo, y la ladera de fuera
			local back = 22 + hash(x, side, 8) * 10
			add({ Kind = "Block", X = x, Y = (top - 4 + (bed - 10)) / 2, Z = axis + side * (hw + r + back * 0.55), SX = 15, SY = max(4, top - 4 - (bed - 10)), SZ = back * 1.1, Yaw = 0, Material = "Rock", Tag = "Plateau" })
			add({ Kind = "Ball", X = x + 3, Y = top - 13, Z = axis + side * (hw + r + back * 0.6), R = 13.5, Material = if hash(x, side, 9) > 0.55 then "Limestone" else "Rock", Tag = "Plateau" })
			add({ Kind = "Ball", X = x - 2, Y = top - 26, Z = axis + side * (hw + r + back + 12), R = 20, Material = "Rock", Tag = "Plateau" })
			-- (corrección tras las vistas previas: paredes y cimas grises y vacías) manchas claras de caliza
			-- y arenisca en la cima (cascajo de coral) y vetas de caliza en la cara de la pared: terreno,
			-- no cuesta piezas
			local rr = 3.5 + hash(x, side, 11) * 3
			add({ Kind = "Ball", X = x + (hash(side, x, 12) - 0.5) * 8, Y = top - rr * 0.7, Z = axis + side * (hw + r + 4 + hash(x, side, 13) * 22), R = rr, Material = if hash(x, side, 14) > 0.5 then "Limestone" else "Sandstone", Tag = "Plateau" })
			if h > 24 then
				local vy = bed + h * (0.3 + hash(x, side, 15) * 0.5)
				add({ Kind = "Ball", X = x, Y = vy, Z = axis + side * (hw + 2.5), R = 3 + hash(side, x, 16) * 1.5, Material = "Limestone", Tag = "Wall" })
			end
			x += 11 + hash(x, side, 10) * 5
		end
	end
	-- 2. Repisas (terrazas para los corales en escalera, como ref_06): losas de caliza que salen de la pared
	for i = 1, 26 do
		local side = if i % 2 == 0 then 1 else -1
		local x = 4380 + (i - 1) * 17 + hash(i, 1, 11) * 8
		if x > 4760 then
			break
		end
		local bed, hw = ReefZone.bedAt(x)
		local top = ReefZone.topAt(x, side)
		local frac = 0.3 + hash(i, 2, 12) * 0.45
		local y = bed + (top - bed) * frac
		local depth = 7 + hash(i, 3, 13) * 5
		add({ Kind = "Block", X = x, Y = y, Z = ReefZone.axisZ(x) + side * (hw + 4 - depth * 0.3), SX = 14 + hash(i, 4, 14) * 10, SY = 3, SZ = depth * 2, Yaw = (hash(i, 5, 15) - 0.5) * 0.4, Material = "Limestone", Tag = "Ledge" })
	end
	-- 3. Columnas de piedra en el ensanche (hoodoos: fuste y sombrero) y agujas lejanas del abismo
	local columns = { { 4612, 32, -29 }, { 4688, -36, -27 }, { 4706, 40, -33 }, { 4640, -48, -38 } }
	for i, col in columns do
		local x = col[1]
		local bed = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x) + col[2]
		local topY = col[3]
		local y = bed
		local r = 6.5
		while y < topY - 6 do
			add({ Kind = "Ball", X = x + (hash(i, y, 16) - 0.5) * 2, Y = y + r * 0.6, Z = z + (hash(y, i, 17) - 0.5) * 2, R = r, Material = "Rock", Tag = "Column" })
			y += r * 1.1
			r = max(3.8, r * 0.93)
		end
		add({ Kind = "Ball", X = x, Y = topY - 2, Z = z, R = 8.5, Material = "Limestone", Tag = "Column" })
	end
	local spires = { { 4770, 52, -34 }, { 4800, -60, -40 }, { 4835, 30, -46 }, { 4850, -24, -54 }, { 4875, 64, -38 }, { 4760, -70, -30 } }
	for i, sp in spires do
		local x = sp[1]
		local bed = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x) + sp[2]
		local y = bed - 4
		local r = 9
		while y < sp[3] do
			add({ Kind = "Ball", X = x + (hash(i, y, 18) - 0.5) * 3, Y = y, Z = z, R = r, Material = if r < 5 then "Limestone" else "Rock", Tag = "Spire" })
			y += r * 1.05
			r = max(2.6, r * 0.86)
		end
	end
	-- 4. El arco sobre el cañón (enmarca la pirámide desde la entrada)
	do
		local x = 4538
		local bed, hw = ReefZone.bedAt(x)
		local axis = ReefZone.axisZ(x)
		local span = hw + 10
		local apex = -15
		for k = 0, 22 do
			local t = k / 22 * pi
			local zz = axis + cos(t) * span
			local yy = bed + (apex - bed) * sin(t) ^ 0.75
			add({ Kind = "Ball", X = x + sin(t * 3) * 2, Y = yy, Z = zz, R = 6.2 + 1.5 * (1 - sin(t)), Material = if k % 5 == 0 then "Limestone" else "Rock", Tag = "Arch" })
		end
	end
	-- 5. La Cueva de la Luz (pared sur): dos salas, la boca al cañón y dos claraboyas
	do
		local function cave(x: number, dz: number, y: number, r: number, tag: string)
			local _, hw = ReefZone.bedAt(x)
			add({ Kind = "Ball", X = x, Y = y, Z = ReefZone.axisZ(x) + hw + dz, R = r, Material = "Water", Tag = tag })
		end
		cave(4498, 4, -40, 10, "Cave") -- la boca
		cave(4504, 20, -37, 16, "Cave") -- la sala grande
		cave(4530, 26, -35, 13, "Cave") -- la sala del fondo
		cave(4518, 22, -46, 11, "Cave") -- el suelo de la sala (más hondo: un cuenco)
		-- claraboyas: de la sala a la cima de la meseta (por aquí baja la luz)
		for _, sky in { { 4506, 22, 4.6 }, { 4532, 27, 3.6 } } do
			local _, hw = ReefZone.bedAt(sky[1])
			local zz = ReefZone.axisZ(sky[1]) + hw + sky[2]
			add({ Kind = "Cylinder", X = sky[1], Y = -15, Z = zz, R = sky[3], H = 24, Material = "Water", Tag = "Skylight" })
		end
	end
	-- 6. El jardín de la entrada (B): bommies (montículos de coral) a distintas alturas, dejando sendas de arena
	local bommies = { { 4282, -322, 4.5 }, { 4300, -270, 6 }, { 4318, -338, 5 }, { 4334, -292, 3.5 }, { 4266, -286, 3 }, { 4346, -330, 6.5 }, { 4352, -262, 5 }, { 4292, -352, 3.5 } }
	for i, b in bommies do
		add({ Kind = "Ball", X = b[1], Y = -14 - 9 + b[3], Z = b[2], R = 9, Material = if i % 3 == 0 then "Limestone" else "Rock", Tag = "Bommie" })
	end
	-- 7. Manchas del lecho (cambios de material; solo la capa de arriba): ondas de arena dorada
	-- (Sandstone: su textura de vetas parece arena con ondas), caliza, tierra y fango en lo hondo
	for i = 1, 40 do
		local x = 4290 + hash(i, 7, 20) * 560
		local bed, hw = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x) + (hash(i, 8, 21) - 0.5) * 2 * hw * 0.9
		local deep = bed < -80
		local h = hash(i, 9, 22)
		local mat = if deep then (if h < 0.6 then "Mud" else "Ground") elseif h < 0.45 then "Sandstone" elseif h < 0.7 then "Limestone" elseif h < 0.85 then "Ground" else "Rock"
		add({ Kind = "Cylinder", X = x, Y = bed - 1.2, Z = z, R = 7 + hash(i, 10, 23) * 9, H = 4, Material = mat, Tag = "Patch" })
	end
	return ops
end

function ReefZone.ops(): { Op }
	if not opsCache then
		opsCache = build()
	end
	return opsCache :: { Op }
end

---------------------------------------------------------------------
-- ¿Hay roca? (la misma regla que el terreno: heightfield y luego cada op en orden)
---------------------------------------------------------------------
local GRID = 32
local gridCache: { [number]: { number } }? = nil

local function gridKey(gx: number, gz: number): number
	return gx * 4096 + gz
end

local function opGrid(): { [number]: { number } }
	if gridCache then
		return gridCache
	end
	local g: { [number]: { number } } = {}
	for i, op in ReefZone.ops() do
		for gx = floor((op.MinX :: number) / GRID), floor((op.MaxX :: number) / GRID) do
			for gz = floor((op.MinZ :: number) / GRID), floor((op.MaxZ :: number) / GRID) do
				local key = gridKey(gx, gz)
				local list = g[key]
				if not list then
					list = {}
					g[key] = list
				end
				table.insert(list, i)
			end
		end
	end
	gridCache = g
	return g
end

local function inside(op: Op, x: number, y: number, z: number): boolean
	if x < (op.MinX :: number) or x > (op.MaxX :: number) or y < (op.MinY :: number) or y > (op.MaxY :: number) or z < (op.MinZ :: number) or z > (op.MaxZ :: number) then
		return false
	end
	if op.Kind == "Ball" then
		local dx, dy, dz = x - op.X, y - op.Y, z - op.Z
		local r = op.R :: number
		return dx * dx + dy * dy + dz * dz <= r * r
	elseif op.Kind == "Cylinder" then
		local dx, dz = x - op.X, z - op.Z
		local r = op.R :: number
		return dx * dx + dz * dz <= r * r
	end
	local yaw = op.Yaw or 0
	local dx, dz = x - op.X, z - op.Z
	local lx = dx * cos(yaw) - dz * sin(yaw)
	local lz = dx * sin(yaw) + dz * cos(yaw)
	return abs(lx) <= (op.SX :: number) / 2 and abs(lz) <= (op.SZ :: number) / 2
end

-- solid(x, y, z, floorFn) -> (sólido, material, etiqueta). floorFn(x, z) = el heightfield (Ocean.floorY)
function ReefZone.solid(x: number, y: number, z: number, floorFn: (number, number) -> number?): (boolean, string, string)
	local f = floorFn(x, z)
	local solid = f ~= nil and y <= f
	local material, tag = "Bed", "Bed"
	if f == nil then
		solid, tag = true, "Land"
	end
	if y > ReefZone.Surface then
		return false, "Air", "Air"
	end
	local list = opGrid()[gridKey(floor(x / GRID), floor(z / GRID))]
	if list then
		local ops = ReefZone.ops()
		for _, i in list do
			local op = ops[i]
			if op.Tag ~= "Patch" and inside(op, x, y, z) then
				if op.Material == "Water" then
					solid, material, tag = false, "Water", op.Tag
				else
					solid, material, tag = true, op.Material, op.Tag
				end
			end
		end
	end
	return solid, material, tag
end

-- La superficie de arriba en (x, z), buscando hacia abajo desde fromY (nil si no hay hasta toY)
function ReefZone.surfaceY(x: number, z: number, floorFn: (number, number) -> number?, fromY: number?, toY: number?): number?
	local y = fromY or ReefZone.TopLimit
	local stop = toY or -200
	if ReefZone.solid(x, y, z, floorFn) then
		return nil -- (dentro de la roca)
	end
	local step = 1
	while y > stop do
		local ny = y - step
		if ReefZone.solid(x, ny, z, floorFn) then
			-- afinar
			local lo, hi = ny, y
			for _ = 1, 6 do
				local mid = (lo + hi) / 2
				if ReefZone.solid(x, mid, z, floorFn) then
					lo = mid
				else
					hi = mid
				end
			end
			return lo
		end
		y = ny
	end
	return nil
end

-- La pared más cercana desde un punto en una dirección horizontal (para colgar corales de la pared)
function ReefZone.wallHit(x: number, y: number, z: number, dx: number, dz: number, floorFn: (number, number) -> number?, maxDist: number): (number?, number?)
	local d = 0
	while d < maxDist do
		d += 1
		if ReefZone.solid(x + dx * d, y, z + dz * d, floorFn) then
			return x + dx * (d - 0.6), z + dz * (d - 0.6)
		end
	end
	return nil, nil
end

---------------------------------------------------------------------
-- Luz, haces, partículas y sitios
---------------------------------------------------------------------
-- Luces de verdad (pocas: encargo §7 y §15). Lo demás brilla con Neon (emisivo, no ilumina)
ReefZone.Lights = {
	{ Name = "Piramide", X = 4660, Z = 0, Lift = 34, Range = 46, Brightness = 1.6, Color = c(80, 236, 255) },
	{ Name = "CuevaJardin", X = 4512, Z = 0, Lift = 0, Range = 26, Brightness = 1.2, Color = c(120, 255, 200), Cave = 22, Y = -44 },
	{ Name = "CuevaFondo", X = 4532, Z = 0, Lift = 0, Range = 18, Brightness = 0.9, Color = c(255, 130, 230), Cave = 27, Y = -42 },
}
-- Haces de luz (columnas Neon muy transparentes): las claraboyas de la cueva y dos sobre el cañón
ReefZone.Shafts = {
	{ X = 4506, Cave = 22, Top = -6, Bottom = -50, R = 4.2 },
	{ X = 4532, Cave = 27, Top = -6, Bottom = -46, R = 3.2 },
	{ X = 4430, Axis = 6, Top = -4, Bottom = -40, R = 7, Tilt = 0.18 },
	{ X = 4590, Axis = -10, Top = -4, Bottom = -58, R = 9, Tilt = 0.22 },
}
-- Partículas con fuente (encargo §9: varias medidas y velocidades; burbujas solo donde hay de dónde salgan)
ReefZone.Emitters = {
	{ Kind = "Plancton", X = 4440, Axis = 0, Y = -24, Size = 40 }, -- motas pequeñas y lentas en el cañón
	{ Kind = "Motas", X = 4506, Cave = 22, Y = -30, Size = 10 }, -- motas grandes en el haz de la cueva
	{ Kind = "Burbujas", X = 4672, Axis = 14, Y = -73, Size = 3 }, -- una fumarola junto a la pirámide
	{ Kind = "Esporas", X = 4520, Cave = 24, Y = -44, Size = 14 }, -- esporas que brillan en el jardín de la cueva
	{ Kind = "Nieve", X = 4790, Axis = 0, Y = -80, Size = 60 }, -- nieve marina en el borde del abismo
}

-- Sitios para descubrir (se añaden a Ocean.Pois): el nombre sale en el HUD al llegar
ReefZone.Pois = {
	{ Id = "CanonDorada", Name = "Cañón de Dorada", X = 4440, Radius = 60, Y = 6 },
	{ Id = "CuevaLuz", Name = "Cueva de la Luz", X = 4512, Cave = 22, Radius = 26, Y = 4 },
	{ Id = "PiramideHundida", Name = "Pirámide Hundida", X = 4660, Radius = 60, Y = 8 },
}

-- Una posición dada como { X, Axis = desplazamiento sobre el eje } o { X, Cave = desplazamiento desde la pared sur }
function ReefZone.where(spec: { [string]: any }): (number, number)
	local x = spec.X
	local _, hw = ReefZone.bedAt(x)
	local z = ReefZone.axisZ(x)
	if spec.Cave then
		z += hw + spec.Cave
	elseif spec.Axis then
		z += spec.Axis
	elseif spec.Z and spec.Z ~= 0 then
		z += spec.Z
	end
	return x, z
end

-- Las cámaras de la revisión (encargo fase 4): donde de verdad va a estar el jugador, a la altura de
-- la cámara de tercera persona (≈ 10 studs detrás y 4 por encima del personaje), mirando hacia donde
-- se nada. { nombre, x, y, z, yaw (grados, 0 = +X hacia el mar), pitch (grados, < 0 hacia abajo) }
ReefZone.Cameras = {
	{ Name = "1 Llegada al jardín", X = 4262, Y = -6, Z = -300, Yaw = 0, Pitch = -14 },
	{ Name = "2 Asomarse al labio", X = 4342, Y = -10, Z = -296, Yaw = 2, Pitch = -22 },
	{ Name = "3 Dentro del cañón", X = 4400, Y = -24, Z = -288, Yaw = -4, Pitch = -6 },
	{ Name = "4 El kelp", X = 4420, Y = -28, Z = -280, Yaw = -35, Pitch = 2 },
	{ Name = "5 La boca de la cueva", X = 4486, Y = -34, Z = -268, Yaw = 62, Pitch = 2 },
	{ Name = "6 Dentro de la cueva", X = 4503, Y = -38, Z = -262, Yaw = 30, Pitch = 18 },
	{ Name = "7 El arco y la pirámide", X = 4500, Y = -38, Z = -290, Yaw = 0, Pitch = -6 },
	{ Name = "8 Las ruinas", X = 4610, Y = -52, Z = -300, Yaw = 8, Pitch = -10 },
	{ Name = "9 El borde del abismo", X = 4720, Y = -64, Z = -306, Yaw = 0, Pitch = -12 },
	{ Name = "10 Mirando atrás (a la playa)", X = 4600, Y = -40, Z = -296, Yaw = 180, Pitch = 6 },
	{ Name = "11 Sobre la pared norte", X = 4470, Y = -8, Z = -350, Yaw = 30, Pitch = -26 },
}

---------------------------------------------------------------------
-- Las piezas del kit (dónde va cada una). Kind = nombre de shared/Sea/MarKit
---------------------------------------------------------------------
export type Placement = {
	Kind: string,
	X: number,
	Y: number,
	Z: number,
	Yaw: number,
	Tilt: number?, -- inclinación (en la pared)
	Scale: number, -- alto en studs
	Color: { number },
	Glow: boolean?,
	Sway: boolean?,
	Group: string, -- submodelo (streaming por trozos): Jardin, Labio, Kelp, Cueva, Paredes, Ruinas, Abismo
	Region: string, -- A, B, C, D, E
}

local placementCache: { Placement }? = nil

function ReefZone.placements(floorFn: (number, number) -> number?): { Placement }
	if placementCache then
		return placementCache
	end
	local out: { Placement } = {}
	local P = ReefZone.Palette
	local function pick(list: { { number } }, r: number): { number }
		return list[1 + floor(r * #list) % #list]
	end
	local function put(kind: string, x: number, z: number, scale: number, color: { number }, group: string, region: string, opts: { [string]: any }?)
		local o = opts or {}
		local y = o.Y or ReefZone.surfaceY(x, z, floorFn, o.From, o.To)
		if not y then
			return
		end
		table.insert(out, {
			Kind = kind,
			X = x,
			Y = y + (o.Sink or 0),
			Z = z,
			Yaw = o.Yaw or hash(x, z, 30) * pi * 2,
			Tilt = o.Tilt,
			Scale = scale,
			Color = color,
			Glow = o.Glow,
			Sway = o.Sway,
			Group = group,
			Region = region,
		})
	end
	-- B · el jardín de la entrada: corales en racimos sobre los bommies; sendas de arena libres entre ellos
	local corals = { "CoralCerebro", "CoralCuerno", "CoralMesa", "Abanico", "CoralBlando", "Esponjas", "CoralPilar" }
	for i, b in { { 4282, -322 }, { 4300, -270 }, { 4318, -338 }, { 4334, -292 }, { 4266, -286 }, { 4346, -330 }, { 4352, -262 }, { 4292, -352 } } do
		local n = 4 + floor(hash(i, 1, 31) * 3)
		for k = 1, n do
			local a = hash(i, k, 32) * pi * 2
			local d = 1 + hash(k, i, 33) * 6.5
			local kind = corals[1 + floor(hash(i, k, 34) * #corals) % #corals]
			local s = 2.2 + hash(k, i, 35) * 3
			if kind == "CoralMesa" then
				s = 1.6 + hash(k, i, 35) * 1.4
			elseif kind == "CoralPilar" then
				s = 4 + hash(k, i, 35) * 4
			end
			put(kind, b[1] + cos(a) * d, b[2] + sin(a) * d, s, pick(P.Warm, hash(i, k, 36)), "Jardin", "B", { From = -3, Sink = -0.3 })
		end
		put("RocaPorosa", b[1] + 5, b[2] - 4, 3 + hash(i, 2, 37) * 2, pick(P.Rock, hash(i, 3, 38)), "Jardin", "B", { From = -3, Sink = -0.8 })
	end
	-- praderas en manchas (no por todas partes) y vida pequeña en la arena
	for i = 1, 8 do
		local x = 4262 + hash(i, 4, 39) * 100
		local z = -360 + hash(i, 5, 40) * 120
		for k = 1, 3 do
			put("Pradera", x + (hash(i, k, 41) - 0.5) * 7, z + (hash(k, i, 42) - 0.5) * 7, 2.5 + hash(k, i, 43) * 2.2, pick(P.Grass, hash(i, k, 44)), "Jardin", "B", { From = -3, Sway = true })
		end
	end
	local small = { "Estrella", "Concha", "Erizo", "Concha", "Estrella", "Cangrejo" }
	for i = 1, 12 do
		local kind = small[1 + (i % #small)]
		put(kind, 4262 + hash(i, 6, 45) * 110, -365 + hash(i, 7, 46) * 130, ({ Estrella = 0.3, Concha = 0.55, Erizo = 0.75, Cangrejo = 0.9 })[kind] or 0.5, pick(P.Warm, hash(i, 8, 47)), "Jardin", "B", { From = -3 })
	end
	-- el labio: cascada de corales que caen por el borde (lo primero que se ve al asomarse)
	for i = 1, 22 do
		local x = 4356 + hash(i, 9, 48) * 30
		local _, hw = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x) + (hash(i, 10, 49) - 0.5) * 2 * (hw + 10)
		put(corals[1 + (i % #corals)], x, z, 2.6 + hash(i, 11, 50) * 3.4, pick(if i % 3 == 0 then P.Cool else P.Warm, hash(i, 12, 51)), "Labio", "B", { From = -4, Sink = -0.3 })
	end
	-- A · las repisas y las cimas: corales en escalera (cálidos arriba, fríos y morados abajo)
	for _, op in ReefZone.ops() do
		if op.Tag == "Ledge" then
			local yawCos, yawSin = cos(op.Yaw or 0), sin(op.Yaw or 0)
			local n = 4 + floor(hash(op.X, op.Y, 52) * 3)
			for k = 1, n do
				local lx = (hash(op.X, k, 53) - 0.5) * (op.SX :: number) * 0.85
				local lz = (hash(k, op.X, 54) - 0.5) * (op.SZ :: number) * 0.7
				local x = op.X + lx * yawCos + lz * yawSin
				local z = op.Z - lx * yawSin + lz * yawCos
				local deepish = op.Y < -45
				local kind = corals[1 + floor(hash(op.X, k, 55) * #corals) % #corals]
				put(kind, x, z, 2.4 + hash(k, op.Y, 56) * 3.6, pick(if deepish then P.Cool else P.Warm, hash(op.Z, k, 57)), "Paredes", "A", { From = op.Y + 8, To = op.Y - 4, Sink = -0.3 })
			end
		end
	end
	for _, side in { -1, 1 } do
		local x = 4372
		while x < 4740 do
			local axis = ReefZone.axisZ(x)
			local _, hw = ReefZone.bedAt(x)
			local top = ReefZone.topAt(x, side)
			-- la cima (arrecife exterior en el norte: más denso y con abanicos grandes)
			local zTop = axis + side * (hw + 16 + hash(x, side, 58) * 18)
			local kind = if side < 0 then (if hash(x, 1, 59) < 0.35 then "Abanico" elseif hash(x, 2, 59) < 0.5 then "CoralMesa" else "CoralCuerno") else corals[1 + floor(hash(x, 3, 59) * #corals) % #corals]
			put(kind, x, zTop, (if kind == "Abanico" then 4.5 else 3) + hash(x, side, 60) * 3, pick(P.Warm, hash(x, side, 61)), "Paredes", "A", { From = top + 6, Sink = -0.4 })
			-- en la cara de la pared: corales colgados (salen de lado)
			local y = top - 8 - hash(x, side, 62) * 22
			local wx, wz = ReefZone.wallHit(x, y, axis, 0, side, floorFn, hw + 30)
			if wx and wz then
				put(if hash(x, side, 63) < 0.5 then "CoralBlando" else "Esponjas", wx, wz, 2.5 + hash(x, side, 64) * 2.5, pick(if y < -45 then P.Cool else P.Warm, hash(side, x, 65)), "Paredes", "A", { Y = y, Tilt = side * 1.2 })
			end
			x += 14 + hash(x, side, 66) * 6
		end
	end
	-- el bosque de kelp gigante (pie de la pared norte, x 4400-4490): tallos de 20 a 34 studs que se mecen
	for i = 1, 22 do
		local x = 4398 + hash(i, 13, 67) * 92
		local bed, hw = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x) - hw * (0.15 + hash(i, 14, 68) * 0.75)
		local tall = min(34, (-6) - bed - 2)
		put("KelpGigante", x, z, tall * (0.62 + hash(i, 15, 69) * 0.38), pick(P.Kelp, hash(i, 16, 70)), "Kelp", "A", { From = bed + 12, Sway = true })
	end
	for i = 1, 10 do
		local x = 4400 + hash(i, 17, 71) * 80
		local bed, hw = ReefZone.bedAt(x)
		put("AlgaAncha", x, ReefZone.axisZ(x) - hw * (0.1 + hash(i, 18, 72) * 0.6), 3.5 + hash(i, 19, 73) * 3, pick(P.Grass, hash(i, 20, 74)), "Kelp", "A", { From = bed + 10, Sway = true })
		put("Canto", x + 6, ReefZone.axisZ(x) - hw * 0.5, 3 + hash(i, 21, 75) * 4, pick(P.Rock, hash(i, 22, 76)), "Kelp", "A", { From = bed + 10, Sink = -1 })
	end
	-- C · el jardín de luz de la cueva (ref_04): setas y anémonas que brillan en el suelo y en las paredes
	for i = 1, 22 do
		local cx, cz = ReefZone.where({ X = 4500 + hash(i, 23, 77) * 36, Cave = 16 + hash(i, 24, 78) * 14 })
		local kind = if i % 3 == 0 then "AnemonaLuz" else "SetaLuz"
		put(kind, cx, cz, if kind == "SetaLuz" then 1.6 + hash(i, 25, 79) * 2.6 else 1.6 + hash(i, 25, 79) * 1.4, pick(P.Glow, hash(i, 26, 80)), "Cueva", "C", { From = -30, To = -60, Glow = true, Sway = kind == "AnemonaLuz" })
	end
	-- (corrección tras las vistas previas: la cueva se veía de roca gris) setas de luz colgadas de las
	-- paredes y del techo de las salas, buscando la pared desde el centro de cada sala
	for _, room in { { X = 4504, Cave = 20, Y = -37 }, { X = 4530, Cave = 26, Y = -35 } } do
		local cx, cz = ReefZone.where(room)
		for k = 1, 7 do
			local a = k / 7 * pi * 2 + hash(room.X, k, 99) * 0.5
			local y = room.Y + (hash(k, room.X, 98) - 0.3) * 10
			local wx, wz = ReefZone.wallHit(cx, y, cz, cos(a), sin(a), floorFn, 20)
			if wx and wz then
				put("SetaLuz", wx, wz, 1.4 + hash(k, room.Cave, 97) * 1.2, pick(P.Glow, hash(room.X, k, 96)), "Cueva", "C", { Y = y, Tilt = 1.3, Yaw = -a, Glow = true })
			end
		end
	end
	-- E · las ruinas: la pirámide (punto focal: se ve desde la entrada por el arco), columnas rotas y bloques
	do
		local x, z = 4660, ReefZone.axisZ(4660)
		put("Piramide", x, z, 30, P.Ruin[1], "Ruinas", "E", { From = -40, Sink = -1.5, Yaw = 0.12 })
		for i = 1, 8 do
			local a = (i / 8) * pi * 2 + 0.3
			local d = 30 + hash(i, 27, 81) * 10
			put("ColumnaRuina", x + cos(a) * d, z + sin(a) * d, 6 + hash(i, 28, 82) * 9, P.Ruin[1 + i % 2], "Ruinas", "E", { From = -40, Sink = -0.5 })
		end
		for i = 1, 6 do
			put("CoralBlando", x - 26 + hash(i, 29, 83) * 52, z + (hash(i, 30, 84) - 0.5) * 70, 3 + hash(i, 31, 85) * 3, pick(P.Cool, hash(i, 32, 86)), "Ruinas", "E", { From = -40, Sink = -0.3 })
			put("SetaLuz", x - 20 + hash(i, 33, 87) * 40, z + (hash(i, 34, 88) - 0.5) * 60, 2 + hash(i, 35, 89) * 2, pick(P.Glow, hash(i, 36, 90)), "Ruinas", "E", { From = -40, Glow = true })
		end
	end
	-- D · el borde del abismo: pocas cosas grandes y oscuras (esponjas de tubo altas, rocas) y luces sueltas
	for i = 1, 12 do
		local x = 4730 + hash(i, 37, 91) * 140
		local _, hw = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x) + (hash(i, 38, 92) - 0.5) * 2 * hw
		local kind = if i % 3 == 0 then "AnemonaLuz" elseif i % 3 == 1 then "Esponjas" else "RocaPorosa"
		put(kind, x, z, if kind == "Esponjas" then 5 + hash(i, 39, 93) * 4 else 3 + hash(i, 39, 93) * 3, if kind == "AnemonaLuz" then pick(P.Glow, hash(i, 40, 94)) else pick(P.Cool, hash(i, 40, 94)), "Abismo", "D", { From = -60, Glow = kind == "AnemonaLuz" })
	end
	-- rocas en el lecho a lo largo del cañón (rompen el suelo; rocas porosas y cantos)
	for i = 1, 18 do
		local x = 4380 + hash(i, 41, 95) * 360
		local _, hw = ReefZone.bedAt(x)
		local z = ReefZone.axisZ(x) + (hash(i, 42, 96) - 0.5) * 2 * hw * 0.8
		put(if i % 2 == 0 then "RocaPorosa" else "Canto", x, z, 2.5 + hash(i, 43, 97) * 4.5, pick(P.Rock, hash(i, 44, 98)), "Paredes", "A", { From = -20, Sink = -0.8 })
	end
	placementCache = out
	return out
end

-- Dónde se juntan los bancos de peces (Controllers/SeaLife): alrededor de los corales
ReefZone.FishSpots = {
	{ X = 4300, Z = -300, Y = -9 },
	{ X = 4362, Z = -300, Y = -18 },
	{ X = 4430, Z = -310, Y = -26 },
	{ X = 4540, Z = -300, Y = -34 },
	{ X = 4650, Z = -300, Y = -50 },
}

-- El sitio para bancos de peces más cercano (o nil si la zona no está cerca)
function ReefZone.fishSpotNear(x: number, z: number): { X: number, Y: number, Z: number }?
	local best, bestD = nil, math.huge
	for _, s in ReefZone.FishSpots do
		local d = sqrt((s.X - x) ^ 2 + (s.Z - z) ^ 2)
		if d < bestD then
			best, bestD = s, d
		end
	end
	return if bestD < 120 then best else nil
end

-- Lo más alto de la zona (lo prueba test-reefzone: nunca por encima de TopLimit)
function ReefZone.highestTop(): number
	local top = -math.huge
	for _, op in ReefZone.ops() do
		if op.Material ~= "Water" and op.Tag ~= "Patch" then
			top = max(top, op.MaxY :: number)
		end
	end
	return top
end

return ReefZone
