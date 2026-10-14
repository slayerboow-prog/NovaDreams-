-- Ocean: la forma del mar de Valmar, en funciones puras (sin tocar Roblox salvo Vector3/Vector2).
-- La usan World/OceanBuilder (construye el terreno), Services/OceanService y DivingService (zonas,
-- presión, peces), el cliente (SeaBiome, SeaLife, DiveHud, Swimming) y scripts/test-mar.luau.
-- docs/mar/diseno.md.
--
--   Ocean.landDistance(x, z)   distancia a tierra (negativa dentro de la isla, de sus islas pequeñas,
--                              del aeropuerto o de la desembocadura del río)
--   Ocean.sample(x, z)         todo lo de un punto: { Floor, Zone, D, Basin, Trench, Canyon, Keep }
--   Ocean.floorY(x, z)         la altura del fondo (nil = tierra)
--   Ocean.zoneAt(x, z)         la zona («Vida marina»): Orilla, Arrecife, Kelp, Llanura, Talud,
--                              Garganta, Abismo, Sima (nil = tierra)
--   Ocean.meters(y)            profundidad en metros de una altura (0 en la superficie)
--   Ocean.currentAt(pos)       corriente (studs/s) que empuja suave a quien nada ahí
--   Ocean.Pois / poiPosition   los sitios para descubrir (pecio, ruinas, guarida…)
--   Ocean.plan(z, cell)        lo que OceanBuilder rellena en una fila del mapa (bloques de agua y fondo)
--
-- Escala: 1 m = 3,57 studs (Ocean.StudsPerMeter). Superficie: Y = -2.

local Shared = game:GetService("ReplicatedStorage").Shared
local CityPlan = require(Shared.CityPlan)
local Airport = require(Shared.Airport)
local OceanBiomes = require(Shared.Sea.OceanBiomes)

local Ocean = {}

local WORLD = OceanBiomes.Worlds.Valmar
local P = WORLD.Profile
Ocean.World = WORLD
Ocean.Surface = WORLD.Surface
Ocean.StudsPerMeter = WORLD.StudsPerMeter
Ocean.Area = WORLD.Area
Ocean.CoastY = P.CoastY

local sqrt, floor, sin, abs, min, max = math.sqrt, math.floor, math.sin, math.abs, math.min, math.max

---------------------------------------------------------------------
-- Geografía del mar de Valmar (datos)
---------------------------------------------------------------------

-- Sitios que no se tocan (fondo de -14 como siempre) y su radio: puertos, marina, islas con muelle
Ocean.Keep = {
	{ Name = "Puerto de Valmar", X = 700, Z = 3330, R = 430 },
	{ Name = "Puerto deportivo", X = -3950, Z = 1300, R = 380 },
	{ Name = "Isla del Faro", X = 4450, Z = 2650, R = 300 },
	{ Name = "Islote (puerto espacial)", X = -4450, Z = 1900, R = 230 },
	{ Name = "Isla de las Gaviotas", X = 2900, Z = -3950, R = 330 },
}

-- Cuenca del Abismo Silente (elipse): dentro de Core (fracción del radio) el fondo es Floor
Ocean.Basin = { Name = "Abismo Silente", X = 3050, Z = 4780, RX = 2650, RZ = 960, Core = 0.72, Floor = -242, Noise = 10 }

-- Fosa: la Sima del Kraken (polilínea). Fondo plano de HalfWidth, paredes de Wall studs hasta la cuenca
Ocean.Trench = {
	Name = "Sima del Kraken",
	Points = { { 2000, 4900 }, { 3000, 4650 }, { 4100, 4950 }, { 5000, 4650 } },
	HalfWidth = 45,
	Wall = 160,
	Floor = -560, -- en el centro
	EndFloor = -330, -- en los extremos
}

-- Cañón: la Garganta Negra (del arrecife del este baja hasta el abismo)
Ocean.Canyon = {
	Name = "Garganta Negra",
	Points = { { 4560, 700 }, { 5050, 1700 }, { 5000, 3050 }, { 4500, 3950 } },
	HalfWidth = 42,
	Wall = 110,
	Top = -95, -- al empezar
	Bottom = -240, -- al llegar al abismo
}

-- Arrecifes y bosques de kelp (círculos sobre la plataforma)
Ocean.Reefs = {
	{ X = 4620, Z = -640, R = 340 },
	{ X = 4640, Z = 220, R = 310 },
	{ X = 2860, Z = 3430, R = 270 },
}
Ocean.Kelp = {
	{ X = -4420, Z = -480, R = 380, Dir = { 0, 1 } },
	{ X = -4330, Z = -1620, R = 340, Dir = { 0, 1 } },
	{ X = -1500, Z = -4180, R = 380, Dir = { 1, 0 } },
}

-- La guarida del Kraken: en la pared norte de la sima, en su tramo más hondo
Ocean.Lair = { X = 3560, Z = 4720, Y = -500, Radius = 34 }

-- Corrientes con sitio (además de la de cada zona): { X, Z, R, Dir = {x, z}, Speed }
Ocean.Currents = {
	{ Name = "Corriente del Talud", X = -1000, Z = 3980, R = 420, Dir = { 1, 0.15 }, Speed = 1.4 },
}

-- Sitios para descubrir (POI). Y: altura sobre el fondo. Zone: dónde está (lo comprueba test-mar).
-- Chest = hay un cofre dentro (OceanBuilder lo pone; OceanService lo abre).
Ocean.Pois = {
	{ Id = "ArcoCoral", Name = "Arco de Coral", Zone = "Arrecife", X = 4440, Z = -640, Radius = 45, Y = 6, Chest = true },
	{ Id = "JardinEscarlata", Name = "Jardín Escarlata", Zone = "Arrecife", X = 4630, Z = 240, Radius = 50, Y = 3 },
	{ Id = "CatedralKelp", Name = "Catedral de Kelp", Zone = "Kelp", X = -4430, Z = -470, Radius = 55, Y = 4 },
	{ Id = "Pecio", Name = "Pecio del Albatros", Zone = "Talud", X = -1250, Z = 3930, Radius = 55, Y = 4, Chest = true },
	{ Id = "BolsaAire", Name = "Cueva de la Bolsa de Aire", Zone = "Talud", X = -700, Z = 4010, Radius = 30, Y = 8, Air = true },
	{ Id = "Ruinas", Name = "Ruinas de Valmar la Vieja", Zone = "Llanura", X = -2400, Z = 4520, Radius = 60, Y = 4, Chest = true },
	{ Id = "PuenteGarganta", Name = "Puente de Piedra", Zone = "Garganta", X = 5030, Z = 2300, Radius = 50, Y = 20 },
	{ Id = "JardinLuz", Name = "Jardín de Luz", Zone = "Abismo", X = 2400, Z = 4580, Radius = 60, Y = 4 },
	{ Id = "Batiscafo", Name = "Batiscafo perdido", Zone = "Abismo", X = 4150, Z = 4420, Radius = 45, Y = 5, Chest = true },
	{ Id = "Ballena", Name = "Caída de ballena", Zone = "Abismo", X = 2900, Z = 5230, Radius = 55, Y = 3 },
	{ Id = "Guarida", Name = "Guarida del Kraken", Zone = "Sima", X = Ocean.Lair.X, Z = Ocean.Lair.Z, Radius = 70, Y = 0, Chest = true, Fixed = Ocean.Lair.Y },
}
Ocean.PoiById = {}
for _, poi in Ocean.Pois do
	Ocean.PoiById[poi.Id] = poi
end

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
Ocean.smooth = smooth

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Ruido de valor (siempre el mismo para el mismo sitio), 0..1
local function hash(ix: number, iz: number, seed: number): number
	local v = sin(ix * 127.1 + iz * 311.7 + seed * 74.7) * 43758.5453
	return v - floor(v)
end
Ocean.hash = hash

local function noise(x: number, z: number, wave: number, seed: number): number
	local fx, fz = x / wave, z / wave
	local ix, iz = floor(fx), floor(fz)
	local tx, tz = fx - ix, fz - iz
	tx, tz = tx * tx * (3 - 2 * tx), tz * tz * (3 - 2 * tz)
	local a = hash(ix, iz, seed)
	local b = hash(ix + 1, iz, seed)
	local c = hash(ix, iz + 1, seed)
	local d = hash(ix + 1, iz + 1, seed)
	return lerp(lerp(a, b, tx), lerp(c, d, tx), tz)
end
Ocean.noise = noise

-- Distancia de un punto a un segmento y la fracción a lo largo
local function segment(x: number, z: number, ax: number, az: number, bx: number, bz: number): (number, number)
	local dx, dz = bx - ax, bz - az
	local len2 = dx * dx + dz * dz
	local t = if len2 > 0 then math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) else 0
	local px, pz = ax + t * dx, az + t * dz
	return sqrt((x - px) ^ 2 + (z - pz) ^ 2), t
end

-- Polilínea: distancia y posición a lo largo (0..1 sobre su longitud total)
type Line = { Points: { { number } }, Lengths: { number }?, Total: number? }
local function prepare(line: any)
	if line.Lengths then
		return
	end
	local lengths, total = {}, 0
	for i = 1, #line.Points - 1 do
		local a, b = line.Points[i], line.Points[i + 1]
		local l = sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
		lengths[i] = l
		total += l
	end
	line.Lengths, line.Total = lengths, total
end
local function along(line: any, x: number, z: number): (number, number, number)
	prepare(line)
	local best, bestT, bestI, acc, bestAcc = math.huge, 0, 1, 0, 0
	local pts = line.Points
	for i = 1, #pts - 1 do
		local d, t = segment(x, z, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2])
		if d < best then
			best, bestT, bestI, bestAcc = d, t, i, acc
		end
		acc += line.Lengths[i]
	end
	return best, (bestAcc + bestT * line.Lengths[bestI]) / line.Total, bestI
end
Ocean.along = along

-- Segmentos de la costa con su caja (para descartar rápido)
local coastSegs = {}
do
	local poly = CityPlan.Coast
	for i = 1, #poly do
		local a, b = poly[i], poly[i % #poly + 1]
		table.insert(coastSegs, { a[1], a[2], b[1], b[2], min(a[1], b[1]), max(a[1], b[1]), min(a[2], b[2]), max(a[2], b[2]) })
	end
end
-- El río sale al mar con sus orillas de arena (TerrainBuilder: banda de Width + 40)
local riverSegs = {}
do
	local pts = CityPlan.River.Points
	for i = 1, #pts - 1 do
		table.insert(riverSegs, { pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2] })
	end
end
local RIVER_HALF = (CityPlan.River.Width + 40) / 2

-- Distancia a tierra (negativa dentro)
function Ocean.landDistance(x: number, z: number): number
	local best = math.huge
	for _, s in coastSegs do
		-- (la caja más cerca que lo mejor hasta ahora)
		local bx = if x < s[5] then s[5] - x elseif x > s[6] then x - s[6] else 0
		local bz = if z < s[7] then s[7] - z elseif z > s[8] then z - s[8] else 0
		if bx < best and bz < best then
			local d = segment(x, z, s[1], s[2], s[3], s[4])
			if d < best then
				best = d
			end
		end
	end
	if CityPlan.inside(CityPlan.Coast, x, z) then
		return -best
	end
	for _, island in CityPlan.Islands do
		local d = sqrt((x - island.X) ^ 2 + (z - island.Z) ^ 2) - island.R
		if d < best then
			best = d
		end
	end
	local land = Airport.Land
	local ax = max(land.X0 - x, 0, x - land.X1)
	local az = max(land.Z0 - z, 0, z - land.Z1)
	local inAirport = x > land.X0 and x < land.X1 and z > land.Z0 and z < land.Z1
	best = min(best, if inAirport then -1 else sqrt(ax * ax + az * az))
	for _, s in riverSegs do
		local d = segment(x, z, s[1], s[2], s[3], s[4]) - RIVER_HALF
		if d < best then
			best = d
		end
	end
	return best
end

---------------------------------------------------------------------
-- El fondo
---------------------------------------------------------------------
export type Sample = {
	Floor: number?, -- altura del fondo (nil = tierra)
	Zone: string?,
	D: number, -- distancia a tierra
	Basin: number, -- 0..1 cuánto es abismo
	Trench: number, -- 0..1 cuánto es sima
	Canyon: number, -- 0..1 cuánto es garganta
	Keep: number, -- 0..1 cuánto se deja como estaba (puertos e islas)
	Corridor: boolean, -- cerca de la sima o la garganta (paredes empinadas: celdas más finas)
}

local function basinWeight(x: number, z: number): number
	local b = Ocean.Basin
	local e = sqrt(((x - b.X) / b.RX) ^ 2 + ((z - b.Z) / b.RZ) ^ 2)
	return 1 - smooth((e - b.Core) / (1 - b.Core))
end

local function keepWeight(x: number, z: number): number
	local w = 0
	for _, k in Ocean.Keep do
		local d = sqrt((x - k.X) ^ 2 + (z - k.Z) ^ 2)
		w = max(w, 1 - smooth((d - k.R) / P.Blend))
	end
	return w
end

local function inDisks(list: { any }, x: number, z: number): any
	for _, c in list do
		if (x - c.X) ^ 2 + (z - c.Z) ^ 2 < c.R * c.R then
			return c
		end
	end
	return nil
end

function Ocean.sample(x: number, z: number): Sample
	local d = Ocean.landDistance(x, z)
	if d < 0 then
		return { Floor = nil, Zone = nil, D = d, Basin = 0, Trench = 0, Canyon = 0, Keep = 1, Corridor = false }
	end
	-- Plataforma, talud y llanura
	local base: number
	local amp: number
	if d <= P.Coast then
		base, amp = P.CoastY, 0
	elseif d <= P.ShelfEnd then
		local t = (d - P.Coast) / (P.ShelfEnd - P.Coast)
		base, amp = lerp(P.CoastY, P.ShelfY, smooth(t)), 3 * smooth(t * 3)
	elseif d <= P.SlopeEnd then
		local t = (d - P.ShelfEnd) / (P.SlopeEnd - P.ShelfEnd)
		base, amp = lerp(P.ShelfY, P.PlainY, smooth(t)), 4
	else
		base, amp = P.PlainY, 7
	end
	if amp > 0 then
		local n = noise(x, z, 220, 1) - 0.5 + 0.5 * (noise(x, z, 70, 2) - 0.5)
		base += n * 2 * amp
		-- Crestas de roca en el talud (ruido «de cresta»)
		if d > P.ShelfEnd - 60 and d < P.SlopeEnd + 120 then
			local r = 1 - abs(2 * noise(x, z, 160, 3) - 1)
			base += (r ^ 3) * 14 * smooth((d - P.ShelfEnd + 60) / 120)
		end
	end
	-- Montículos del arrecife
	local reef = inDisks(Ocean.Reefs, x, z)
	if reef and d > P.Coast then
		base += (noise(x, z, 30, 4) ^ 2) * 5
	end
	-- Abismo
	local basin = basinWeight(x, z)
	if basin > 0 then
		local deep = Ocean.Basin.Floor + (noise(x, z, 260, 5) - 0.5) * 2 * Ocean.Basin.Noise
		base = min(base, lerp(base, deep, basin))
	end
	-- Garganta Negra
	local canyonW = 0
	do
		local c = Ocean.Canyon
		local dist, t = along(c, x, z)
		if dist < c.HalfWidth + c.Wall then
			canyonW = 1 - smooth((dist - c.HalfWidth) / c.Wall)
			local bottom = lerp(c.Top, c.Bottom, t) + (noise(x, z, 40, 6) - 0.5) * 6
			base = min(base, lerp(base, bottom, canyonW))
		end
	end
	-- Sima del Kraken
	local trenchW = 0
	do
		local tr = Ocean.Trench
		local dist, t = along(tr, x, z)
		if dist < tr.HalfWidth + tr.Wall then
			trenchW = 1 - smooth((dist - tr.HalfWidth) / tr.Wall)
			-- más honda en el medio (t = 0,5) que en los extremos
			local mid = 1 - abs(2 * t - 1)
			local bottom = lerp(tr.EndFloor, tr.Floor, smooth(mid * 1.6)) + (noise(x, z, 35, 7) - 0.5) * 8
			-- paredes con escalones de roca
			local w = trenchW
			w = w + 0.12 * (noise(x, z, 45, 8) - 0.5) * (1 - abs(2 * w - 1))
			base = min(base, lerp(base, bottom, math.clamp(w, 0, 1)))
		end
	end
	-- Puertos e islas: como estaban
	local keep = keepWeight(x, z)
	if keep > 0 then
		base = lerp(base, P.CoastY, keep)
	end
	if d <= P.Coast then
		base = P.CoastY
	end
	base = min(base, P.CoastY)
	local corridor = canyonW > 0.02 or trenchW > 0.02
	local s: Sample = { Floor = base, Zone = nil, D = d, Basin = basin, Trench = trenchW, Canyon = canyonW, Keep = keep, Corridor = corridor }
	-- La zona
	local zone
	if trenchW > 0.35 and base < -290 then
		zone = "Sima"
	elseif canyonW > 0.4 and basin < 0.5 then
		zone = "Garganta"
	elseif basin > 0.5 or base <= -181 then
		zone = "Abismo"
	elseif d < P.Coast + 25 or keep > 0.6 then
		zone = "Orilla"
	elseif d < P.ShelfEnd then
		if reef then
			zone = "Arrecife"
		elseif inDisks(Ocean.Kelp, x, z) then
			zone = "Kelp"
		else
			zone = "Llanura"
		end
	elseif d < P.SlopeEnd then
		zone = "Talud"
	else
		zone = "Llanura"
	end
	s.Zone = zone
	return s
end

function Ocean.floorY(x: number, z: number): number?
	return Ocean.sample(x, z).Floor
end

function Ocean.zoneAt(x: number, z: number): string?
	return Ocean.sample(x, z).Zone
end

-- Profundidad en metros (0 en la superficie o por encima)
function Ocean.meters(y: number): number
	return max(0, (Ocean.Surface - y) / Ocean.StudsPerMeter)
end

function Ocean.studs(meters: number): number
	return meters * Ocean.StudsPerMeter
end

-- ¿Está el punto (x, z) dentro del mar que hace este módulo? (fuera de tierra y dentro del área)
function Ocean.inArea(x: number, z: number): boolean
	local a = Ocean.Area
	return x >= a.MinX and x <= a.MaxX and z >= a.MinZ and z <= a.MaxZ
end

-- Dónde está un sitio (encima del fondo)
function Ocean.poiPosition(poi: { [string]: any }): Vector3
	local y = poi.Fixed or ((Ocean.floorY(poi.X, poi.Z) or P.CoastY) + (poi.Y or 0))
	return Vector3.new(poi.X, y, poi.Z)
end

-- Corriente en un punto (studs/s, horizontal). Solo bajo el agua.
function Ocean.currentAt(pos: Vector3): Vector3
	if pos.Y > Ocean.Surface - 1 then
		return Vector3.zero
	end
	local v = Vector3.zero
	for _, c in Ocean.Currents do
		local d = sqrt((pos.X - c.X) ^ 2 + (pos.Z - c.Z) ^ 2)
		if d < c.R then
			local k = 1 - smooth(d / c.R)
			v += Vector3.new(c.Dir[1], 0, c.Dir[2]).Unit * c.Speed * k
		end
	end
	-- Por el cañón, el agua baja hacia el abismo
	local c = Ocean.Canyon
	local dist, _, i = along(c, pos.X, pos.Z)
	if dist < c.HalfWidth + c.Wall * 0.5 then
		local a, b = c.Points[i], c.Points[i + 1]
		local dir = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Unit
		v += dir * WORLD.Zones.Garganta.Current * (1 - smooth(dist / (c.HalfWidth + c.Wall * 0.5)))
	end
	-- El kelp se mece: ida y vuelta lenta
	local kelp = inDisks(Ocean.Kelp, pos.X, pos.Z)
	if kelp then
		v += Vector3.new(kelp.Dir[1], 0, kelp.Dir[2]) * WORLD.Zones.Kelp.Current * 0.6
	end
	return v
end

---------------------------------------------------------------------
-- Plan del terreno (lo ejecuta World/OceanBuilder con FillBlock)
---------------------------------------------------------------------
-- Una fila del mapa (de Z a Z + cell) en celdas de `cell` studs. Devuelve bloques:
--   { Kind = "Water" | "Floor", X0, X1, Y0, Y1, Material }
-- Reglas:
--   * Solo celdas de mar con fondo más hondo que la orilla (CoastY - 0,5). Lo de cerca de la costa,
--     puertos e islas no se toca (lo pone TerrainBuilder como siempre).
--   * Agua desde el fondo hasta -14 (encima ya está el agua de siempre) o hasta la superficie al sur de
--     SlabMaxZ (allí no había mar).
--   * El fondo es sólido desde Bottom hasta Floor. Bottom = el más hondo de sus vecinas - 10: así una
--     pared alta (la sima, el borde del abismo) nunca deja ver el vacío de debajo.
--   * Celdas seguidas casi iguales (± Merge studs, mismo material) se juntan en un bloque (≤ MaxRun).
Ocean.Cell = 16
Ocean.Merge = 2
Ocean.MaxRun = 512
Ocean.Thick = 14 -- grosor mínimo del fondo
local SLAB_BOTTOM = -24 -- (TerrainBuilder: arena de -24 a -14)

export type Block = { Kind: string, X0: number, X1: number, Y0: number, Y1: number, Material: string }

-- Altura del fondo en una celda (nil = tierra) y su material; muestras en el centro
function Ocean.cellInfo(x: number, z: number): (number?, string, boolean, number)
	local s = Ocean.sample(x, z)
	if not s.Floor then
		return nil, "Sand", false, 0
	end
	local zone = WORLD.Zones[s.Zone or "Llanura"]
	local mats = zone.Materials
	-- Roca a manchas (y en las paredes empinadas)
	local material = mats.Floor
	if noise(x, z, 90, 9) > 0.68 or s.Trench > 0.15 and s.Trench < 0.9 or s.Canyon > 0.15 and s.Canyon < 0.9 then
		material = mats.Rock
	end
	-- Cuánto se pueden juntar las celdas: poco en la plataforma (se ve con luz), más en lo hondo
	local tolerance = if s.Corridor then 0 elseif s.D < P.ShelfEnd then 1.2 elseif s.D < P.SlopeEnd and s.Basin < 0.3 then Ocean.Merge else 4
	return s.Floor, material, s.Corridor, tolerance
end

-- Lo de una fila. `prev`/`next` (opcionales): las alturas de las filas de al lado (para el fondo de las
-- paredes); `cache` guarda las alturas por fila.
function Ocean.planRow(z0: number, cell: number, floorsPrev: { [number]: number }?, floors: { [number]: any }, floorsNext: { [number]: number }?): { Block }
	local area = Ocean.Area
	local slab = z0 + cell <= WORLD.SlabMaxZ
	local blocks: { Block } = {}
	local n = floor((area.MaxX - area.MinX) / cell)
	local run: { [string]: any }? = nil
	local function flush()
		local r = run
		if not r then
			return
		end
		run = nil
		local mean = r.Sum / r.Count
		table.insert(blocks, { Kind = "Floor", X0 = r.X0, X1 = r.X1, Y0 = r.Bottom, Y1 = mean, Material = r.Material })
	end
	for i = 0, n - 1 do
		local x0 = area.MinX + i * cell
		local info = floors[i]
		local f = info and info.F
		local carve = f ~= nil and (f < P.CoastY - 0.5 or not slab)
		-- El fondo de las vecinas (para no dejar ver el vacío)
		local lowest = f or math.huge
		for _, row in { floorsPrev, floors, floorsNext } do
			if row then
				for di = -1, 1 do
					local nb = row[i + di]
					local nf = if type(nb) == "table" then nb.F else nb
					if nf and nf < lowest then
						lowest = nf
					end
				end
			end
		end
		if carve then
			local bottom = floor(min(f - Ocean.Thick, lowest - 10) / 4) * 4
			local material = info.M
			local r = run
			if r and r.Material == material and abs(f - r.Sum / r.Count) <= min(info.T, r.T) and r.X1 - r.X0 < Ocean.MaxRun then
				r.X1 = x0 + cell
				r.Sum += f
				r.Count += 1
				r.Bottom = min(r.Bottom, bottom)
			else
				flush()
				run = { X0 = x0, X1 = x0 + cell, Sum = f, Count = 1, Bottom = bottom, Material = material, T = info.T }
			end
		else
			flush()
			-- Celda sin tocar junto a una más honda: su fondo baja hasta tapar el vacío
			if f and slab and lowest < SLAB_BOTTOM + 4 then
				local bottom = floor((lowest - 10) / 4) * 4
				table.insert(blocks, { Kind = "Floor", X0 = x0, X1 = x0 + cell, Y0 = bottom, Y1 = SLAB_BOTTOM + 2, Material = "Sand" })
			end
		end
	end
	flush()
	return blocks
end

-- El agua de una banda de filas (rows: sus alturas, de rowFloors), en baldosas de `tile` studs: desde el
-- fondo más hondo de la baldosa hasta -14 (o hasta la superficie al sur de SlabMaxZ). Va ANTES que el
-- fondo (planRow), que tapa el agua sobrante de debajo.
function Ocean.planWater(z0: number, z1: number, rows: { { [number]: any } }, cell: number, tile: number): { Block }
	local area = Ocean.Area
	local per = math.max(1, floor(tile / cell))
	local n = floor((area.MaxX - area.MinX) / cell)
	local top = if z1 <= WORLD.SlabMaxZ then P.CoastY else Ocean.Surface
	local blocks: { Block } = {}
	for i0 = 0, n - 1, per do
		local lowest = math.huge
		for _, row in rows do
			for i = i0, math.min(n - 1, i0 + per - 1) do
				local info = row[i]
				if info and (info.F < P.CoastY - 0.5 or top == Ocean.Surface) and info.F < lowest then
					lowest = info.F
				end
			end
		end
		if lowest < math.huge then
			table.insert(blocks, { Kind = "Water", X0 = area.MinX + i0 * cell, X1 = area.MinX + math.min(n, i0 + per) * cell, Y0 = lowest - 2, Y1 = top, Material = "Water", Z0 = z0, Z1 = z1 })
		end
	end
	return blocks
end

-- Alturas de una fila (para planRow): índice de celda -> { F = fondo, M = material, C = pared empinada }
function Ocean.rowFloors(z0: number, cell: number): { [number]: any }
	local area = Ocean.Area
	local n = floor((area.MaxX - area.MinX) / cell)
	local row = {}
	local zc = z0 + cell / 2
	for i = 0, n - 1 do
		local x = area.MinX + i * cell + cell / 2
		local f, m, c, t = Ocean.cellInfo(x, zc)
		if f then
			row[i] = { F = f, M = m, C = c, T = t }
		end
	end
	return row
end

-- Número de filas del plan
function Ocean.rows(cell: number): number
	return floor((Ocean.Area.MaxZ - Ocean.Area.MinZ) / cell)
end

return Ocean
