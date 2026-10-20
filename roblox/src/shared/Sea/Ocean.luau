-- Ocean: la forma del mar de Valmar, en funciones puras (sin tocar Roblox salvo Vector3/Vector2).
-- La usan World/OceanBuilder (construye el terreno), Services/OceanService y DivingService (zonas,
-- presión, peces), el cliente (SeaBiome, SeaLife, DiveHud, Swimming) y scripts/test-mar.luau.
-- docs/mar/diseno.md.
--
--   Ocean.landDistance(x, z)   distancia a tierra (negativa dentro de la isla, de sus islas pequeñas,
--                              del aeropuerto o de la desembocadura del río)
--   Ocean.sample(x, z)         todo lo de un punto: { Floor, Zone, D, Basin, Trench, Canyon, Keep }
--   Ocean.floorY(x, z)         la altura del fondo (nil = tierra)
--   Ocean.zoneAt(x, z)         la zona («Vida marina»): Orilla, Coral (jardines de la orilla), Arrecife,
--                              Kelp, Llanura, Talud, Garganta, Catedrales, Abismo, Sima (nil = tierra)
--   Ocean.ShoreReefs           los jardines de coral delante de las playas (v122)
--   Ocean.meters(y)            profundidad en metros de una altura (0 en la superficie)
--   Ocean.currentAt(pos)       corriente (studs/s) que empuja suave a quien nada ahí
--   Ocean.Pois / poiPosition   los sitios para descubrir (pecio, ruinas, guarida…)
--   Ocean.planBand / planWater lo que OceanBuilder rellena en una banda del mapa (bloques de fondo y agua)
--   Ocean.spires()             las agujas de roca (borde del abismo y del Cañón de las Catedrales)
--
-- Escala: 1 m = 3,57 studs (Ocean.StudsPerMeter). Superficie: Y = -2.

local Shared = game:GetService("ReplicatedStorage").Shared
local CityPlan = require(Shared.CityPlan)
local Airport = require(Shared.Airport)
local OceanBiomes = require(Shared.Sea.OceanBiomes)
local ReefZone = require(Shared.Sea.ReefZone) -- (la zona de referencia v2: el Cañón de Dorada)

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

-- Cañón de las Catedrales (mar enorme, v120): un cañón ancho de paredes altas que baja por el sur desde
-- la llanura hasta el borde del Abismo Silente. Arriba, Valmar Hundida (el barrio de los faroles); abajo,
-- la Catedral Abisal (una cueva enorme con claraboyas). Su fondo nunca pasa de 75 m (con botella se
-- llega a todo).
Ocean.Cathedrals = {
	Name = "Cañón de las Catedrales",
	Points = { { -3600, 5300 }, { -2500, 5420 }, { -1400, 5350 }, { -300, 5200 }, { 800, 4980 } },
	HalfWidth = 60,
	Wall = 70,
	Top = -158, -- al empezar (~44 m)
	Bottom = -252, -- junto al abismo (~70 m)
}

-- Arrecifes y bosques de kelp (círculos sobre la plataforma)
Ocean.Reefs = {
	{ X = 4620, Z = -640, R = 340 },
	{ X = 4640, Z = 220, R = 310 },
	{ X = 2860, Z = 3430, R = 270 },
}
-- Jardines de coral de la orilla (v122): la mayoría de los jugadores solo nada cerca de las playas y el
-- arrecife de verdad estaba a 2-3 km. Uno delante de cada playa grande, a ~110 studs de la arena (3-4 m
-- de agua), y al final del módulo se reparten más solos por el resto de las playas (uno cada
-- ~520 studs de costa: desde cualquier playa hay uno a menos de ~600 studs). Zona «Coral» (Jardín de coral), cada uno es un sitio para descubrir (Ocean.Pois) y el
-- objetivo de «Explora el arrecife» es el que tengas más cerca (shared/Sea/Diving).
Ocean.ShoreReefs = {
	{ Id = "CoralDorada", Name = "Jardín de coral de Playa Dorada", X = 4300, Z = -300, R = 50 },
	{ Id = "CoralLevante", Name = "Jardín de coral de Levante", X = 4107, Z = -1772, R = 55 },
	{ Id = "CoralFaro", Name = "Jardín de coral del Faro", X = 4033, Z = 1220, R = 55 },
	{ Id = "CoralCalaSol", Name = "Jardín de coral de Cala del Sol", X = 3438, Z = 2614, R = 55 },
	{ Id = "CoralSur", Name = "Jardín de coral de la Playa del Sur", X = 1781, Z = 3408, R = 55 },
	{ Id = "CoralPoniente", Name = "Jardín de coral de Poniente", X = -511, Z = 3609, R = 55 },
	{ Id = "CoralRoca", Name = "Jardín de coral de la Roca", X = -3278, Z = 2177, R = 55 },
	{ Id = "CoralOeste", Name = "Jardín de coral del Oeste", X = -4006, Z = 531, R = 55 },
	{ Id = "CoralNorte", Name = "Jardín de coral del Norte", X = -3381, Z = -3250, R = 55 },
}
Ocean.ShoreReefNamed = #Ocean.ShoreReefs -- (los de arriba llevan piezas del servidor; los repartidos, no)
Ocean.ShoreReefSpacing = 520
Ocean.ShoreReefOffset = 105
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
	{ Id = "ValmarHundida", Name = "Valmar Hundida", Zone = "Catedrales", X = -2500, Z = 5420, Radius = 80, Y = 4, Chest = true },
	{ Id = "CatedralAbisal", Name = "Catedral Abisal", Zone = "Catedrales", X = -300, Z = 5200, Radius = 75, Y = 6 },
}
-- (los jardines de coral de la orilla también son sitios: se añaden al final del módulo, junto con
-- los que se reparten solos por el resto de las playas: Ocean.ShoreReefs)

-- La Catedral Abisal: cueva enorme excavada en una mole de roca que tapa el cañón (se entra por los dos
-- lados del cañón) con claraboyas arriba por las que baja la luz
Ocean.Cathedral = { X = -300, Z = 5200, Radius = 92, Hollow = 74, Lift = 26, Skylights = 3 }

-- Campos de medusas (Controllers/SeaAmbient): sitios fijos donde flotan muchas medusas que brillan
Ocean.JellyFields = {
	{ Name = "Velo de las Medusas", X = -1900, Z = 5440, R = 160, Top = -60 },
	{ Name = "Jardín de Luz", X = 2400, Z = 4580, R = 180, Top = -110 },
	{ Name = "Catedral", X = -300, Z = 5200, R = 45, Top = -170 },
	{ Name = "Garganta", X = 5000, Z = 3050, R = 120, Top = -70 },
	{ Name = "Talud", X = -1000, Z = 4100, R = 140, Top = -30 },
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
	Cathedrals: number, -- 0..1 cuánto es el Cañón de las Catedrales
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
		return { Floor = nil, Zone = nil, D = d, Basin = 0, Trench = 0, Canyon = 0, Cathedrals = 0, Keep = 1, Corridor = false }
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
	-- Jardines de coral de la orilla: montículos bajos (nunca a menos de 2,5 m de la superficie)
	local shoreReef = inDisks(Ocean.ShoreReefs, x, z)
	if shoreReef and d > P.Coast then
		base = min(base + (noise(x, z, 24, 16) ^ 2) * 3, Ocean.Surface - 9)
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
	-- Cañón de las Catedrales (ancho, de paredes casi verticales y con escalones de roca)
	local cathW = 0
	do
		local c = Ocean.Cathedrals
		local dist, t = along(c, x, z)
		if dist < c.HalfWidth + c.Wall then
			local k = (dist - c.HalfWidth) / c.Wall
			-- pared empinada: casi todo el desnivel en el primer 60 % de la pared, con dos repisas
			cathW = 1 - smooth(k * 1.25)
			cathW = cathW + 0.08 * math.sin(k * math.pi * 3) * (1 - abs(2 * cathW - 1))
			cathW = math.clamp(cathW, 0, 1)
			local bottom = lerp(c.Top, c.Bottom, smooth(t)) + (noise(x, z, 50, 15) - 0.5) * 5
			base = min(base, lerp(base, bottom, cathW))
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
	-- Cañón de Dorada (zona de referencia v2, shared/Sea/ReefZone): el lecho del cañón
	local reefW = 0
	base, reefW = ReefZone.carve(x, z, base)
	-- Puertos e islas: como estaban
	local keep = keepWeight(x, z)
	if keep > 0 then
		base = lerp(base, P.CoastY, keep)
	end
	if d <= P.Coast then
		base = P.CoastY
	end
	base = min(base, P.CoastY)
	local corridor = canyonW > 0.02 or trenchW > 0.02 or cathW > 0.02 or reefW > 0.02
	local s: Sample = { Floor = base, Zone = nil, D = d, Basin = basin, Trench = trenchW, Canyon = canyonW, Cathedrals = cathW, Keep = keep, Corridor = corridor }
	-- La zona
	local zone
	if trenchW > 0.35 and base < -290 then
		zone = "Sima"
	elseif cathW > 0.4 and basin < 0.5 then
		zone = "Catedrales"
	elseif canyonW > 0.4 and basin < 0.5 then
		zone = "Garganta"
	elseif basin > 0.5 or base <= -181 then
		zone = "Abismo"
	elseif ReefZone.inCanyon(x, z) then
		zone = "Canon" -- (zona de referencia v2: el Cañón de Dorada)
	elseif shoreReef and keep < 0.3 then
		zone = "Coral"
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

-- Agujas de roca (mar enorme, v120): columnas altas de basalto en el borde del Abismo Silente y en lo
-- alto de las paredes del Cañón de las Catedrales. Se ven de lejos entre la bruma, una detrás de otra.
-- Nunca dentro del territorio del megalodón (elipse ≤ 1,02), ni en la sima, la garganta, puertos o
-- sitios. { X, Z, Base (Y del fondo), H (alto), R (radio) }. Siempre las mismas.
local spireCache: { { [string]: number } }? = nil
function Ocean.spires(): { { [string]: number } }
	if spireCache then
		return spireCache
	end
	local list = {}
	local function try(x: number, z: number, h: number, r: number)
		local area = Ocean.Area
		if x < area.MinX + 80 or x > area.MaxX - 80 or z < area.MinZ + 80 or z > area.MaxZ - 80 then
			return -- (fuera del mar que se construye)
		end
		local s = Ocean.sample(x, z)
		if not s.Floor or s.Keep > 0.01 or s.Trench > 0.02 or s.Canyon > 0.02 or s.D < 420 then
			return
		end
		local b = Ocean.Basin
		if sqrt(((x - b.X) / b.RX) ^ 2 + ((z - b.Z) / b.RZ) ^ 2) < 1.04 then
			return
		end
		for _, poi in Ocean.Pois do
			if (x - poi.X) ^ 2 + (z - poi.Z) ^ 2 < (poi.Radius + r + 30) ^ 2 then
				return
			end
		end
		-- (nunca más alta que 20 studs bajo la superficie: los barcos pasan por encima)
		h = min(h, Ocean.Surface - 20 - s.Floor)
		if h > 30 then
			table.insert(list, { X = x, Z = z, Base = s.Floor, H = h, R = r })
		end
	end
	-- Borde del abismo
	local b = Ocean.Basin
	for i = 1, 30 do
		local a = (i - 1) / 30 * math.pi * 2 + (hash(i, 1, 70) - 0.5) * 0.15
		local e = 1.06 + hash(i, 2, 70) * 0.1
		try(b.X + math.cos(a) * b.RX * e, b.Z + math.sin(a) * b.RZ * e, 70 + hash(i, 3, 70) * 80, 9 + hash(i, 4, 70) * 9)
	end
	-- Lo alto de las paredes del cañón (a los dos lados)
	local c = Ocean.Cathedrals
	prepare(c)
	for i = 1, 16 do
		local k = (i - 0.5) / 16
		local dist = k * (c.Total :: number)
		local seg = 1
		while seg < #c.Points - 1 and dist > (c.Lengths :: any)[seg] do
			dist -= (c.Lengths :: any)[seg]
			seg += 1
		end
		local p0, p1 = c.Points[seg], c.Points[seg + 1]
		local t = math.clamp(dist / (c.Lengths :: any)[seg], 0, 1)
		local dx, dz = p1[1] - p0[1], p1[2] - p0[2]
		local len = sqrt(dx * dx + dz * dz)
		local side = if i % 2 == 0 then 1 else -1
		local off = c.HalfWidth + c.Wall + 6 + hash(i, 5, 71) * 20
		local x = p0[1] + dx * t - dz / len * off * side
		local z = p0[2] + dz * t + dx / len * off * side
		try(x, z, 50 + hash(i, 6, 71) * 60, 8 + hash(i, 7, 71) * 7)
	end
	spireCache = list
	return list
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
-- Por bandas de filas (de Z a Z + n·cell) en celdas de `cell` studs. Devuelve bloques:
--   { Kind = "Water" | "Floor", X0, X1, Z0, Z1, Y0, Y1, Material }
-- Reglas:
--   * Solo celdas de mar con fondo más hondo que la orilla (CoastY - 0,5). Lo de cerca de la costa,
--     puertos e islas no se toca (lo pone TerrainBuilder como siempre).
--   * Agua desde el fondo hasta -14 (encima ya está el agua de siempre) o hasta la superficie al sur de
--     SlabMaxZ (allí no había mar).
--   * El fondo es sólido desde Bottom hasta Floor. Bottom = el más hondo de sus vecinas - 10: así una
--     pared alta (la sima, el borde del abismo) nunca deja ver el vacío de debajo.
--   * Celdas casi iguales (mismo material, alturas dentro de la tolerancia de cellInfo) se juntan en un
--     rectángulo grande (planBand: hasta MaxRun de ancho y toda la banda de largo). v117 lo hacía solo
--     por filas (planRow: 92 644 rellenos); v120, 53 000 con el mismo fondo.
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
	local wall = s.Trench > 0.15 and s.Trench < 0.9 or s.Canyon > 0.15 and s.Canyon < 0.9 or s.Cathedrals > 0.15 and s.Cathedrals < 0.9
	if noise(x, z, 90, 9) > 0.68 or wall then
		material = mats.Rock
	end
	-- Cuánto se pueden juntar las celdas (World/OceanBuilder junta las parecidas en bloques grandes): nada
	-- en las paredes empinadas, poco en la plataforma (se ve con luz), más en lo hondo y oscuro
	local steep = s.Corridor and (s.Trench > 0.02 and s.Trench < 0.97 or s.Canyon > 0.02 and s.Canyon < 0.97 or s.Cathedrals > 0.02 and s.Cathedrals < 0.97)
	local tolerance = if steep then 0 elseif s.Corridor then 2 elseif s.D < P.ShelfEnd then 1.2 elseif s.D < P.SlopeEnd and s.Basin < 0.3 then Ocean.Merge else 4
	return s.Floor, material, s.Corridor, tolerance
end

-- El fondo de una banda de filas con bloques grandes (v120: el mar enorme con MENOS rellenos que antes).
-- rows[k] (k = 0..n-1) son las filas de la banda (de rowFloors) y rows[-1] / rows[n] las de al lado.
-- «Greedy meshing»: desde cada celda sin usar se alarga el bloque por la fila y luego hacia
-- las filas de abajo mientras toda la tira siga siendo mar parecido: mismo material y alturas dentro de
-- la tolerancia de cellInfo (Spread veces: la cima del bloque es la media). Las celdas de la orilla que
-- no se tocan y lindan con mar hondo bajan su fondo para tapar el vacío.
-- Devuelve bloques con Z0/Z1.
Ocean.Spread = 2 -- la diferencia máxima dentro de un bloque = Spread × tolerancia
function Ocean.planBand(z0: number, cell: number, rows: { [number]: { [number]: any }? }, n: number): { Block }
	local area = Ocean.Area
	local ncols = floor((area.MaxX - area.MinX) / cell)
	local maxW = max(1, floor(Ocean.MaxRun / cell))
	local blocks: { Block } = {}
	local used: { [number]: boolean } = {}
	local function slab(k: number): boolean
		return z0 + (k + 1) * cell <= WORLD.SlabMaxZ
	end
	local function infoAt(i: number, k: number): any
		local row = rows[k]
		return row and row[i]
	end
	-- El fondo más hondo de la celda y sus 8 vecinas
	local function lowestAround(i: number, k: number): number
		local lowest = math.huge
		for dk = -1, 1 do
			local row = rows[k + dk]
			if row then
				for di = -1, 1 do
					local nb = row[i + di]
					if nb and nb.F < lowest then
						lowest = nb.F
					end
				end
			end
		end
		return lowest
	end
	local function carves(info: any, k: number): boolean
		return info ~= nil and (info.F < P.CoastY - 0.5 or not slab(k))
	end
	local function bottomOf(info: any, i: number, k: number): number
		return floor(min(info.F - Ocean.Thick, lowestAround(i, k) - 10) / 4) * 4
	end
	for k0 = 0, n - 1 do
		for i0 = 0, ncols - 1 do
			local key0 = k0 * ncols + i0
			local info0 = infoAt(i0, k0)
			if used[key0] or info0 == nil then
				continue
			end
			if not carves(info0, k0) then
				-- Celda sin tocar junto a una más honda: su fondo baja hasta tapar el vacío
				if slab(k0) then
					local lowest = lowestAround(i0, k0)
					if lowest < SLAB_BOTTOM + 4 then
						table.insert(blocks, { Kind = "Floor", X0 = area.MinX + i0 * cell, X1 = area.MinX + (i0 + 1) * cell, Z0 = z0 + k0 * cell, Z1 = z0 + (k0 + 1) * cell, Y0 = floor((lowest - 10) / 4) * 4, Y1 = SLAB_BOTTOM + 2, Material = "Salt" })
					end
				end
				continue
			end
			local material = info0.M
			local tol = info0.T
			local lo, hi = info0.F, info0.F
			local function fits(info: any, k: number): boolean
				if not carves(info, k) or info.M ~= material then
					return false
				end
				local t = min(tol, info.T)
				return max(hi, info.F) - min(lo, info.F) <= t * Ocean.Spread + 1e-9
			end
			-- 1. por la fila
			local i1 = i0
			while i1 + 1 < ncols and i1 + 1 - i0 < maxW do
				local nb = infoAt(i1 + 1, k0)
				if used[k0 * ncols + i1 + 1] or not fits(nb, k0) then
					break
				end
				i1 += 1
				tol = min(tol, nb.T)
				lo, hi = min(lo, nb.F), max(hi, nb.F)
			end
			-- 2. hacia abajo, la tira entera
			local k1 = k0
			while k1 + 1 < n do
				local k = k1 + 1
				local ok = true
				local tlo, thi, ttol = lo, hi, tol
				for i = i0, i1 do
					local nb = infoAt(i, k)
					if used[k * ncols + i] or not carves(nb, k) or nb.M ~= material then
						ok = false
						break
					end
					ttol = min(ttol, nb.T)
					tlo, thi = min(tlo, nb.F), max(thi, nb.F)
					if thi - tlo > ttol * Ocean.Spread + 1e-9 then
						ok = false
						break
					end
				end
				if not ok then
					break
				end
				k1, lo, hi, tol = k, tlo, thi, ttol
			end
			-- el bloque: cima en la media, fondo bajo la vecina más honda del borde
			local sum, count, bottom = 0, 0, math.huge
			for k = k0, k1 do
				for i = i0, i1 do
					used[k * ncols + i] = true
					local info = infoAt(i, k)
					sum += info.F
					count += 1
					if k == k0 or k == k1 or i == i0 or i == i1 then
						bottom = min(bottom, bottomOf(info, i, k))
					end
				end
			end
			bottom = min(bottom, floor((lo - Ocean.Thick) / 4) * 4)
			table.insert(blocks, { Kind = "Floor", X0 = area.MinX + i0 * cell, X1 = area.MinX + (i1 + 1) * cell, Z0 = z0 + k0 * cell, Z1 = z0 + (k1 + 1) * cell, Y0 = bottom, Y1 = sum / count, Material = material })
		end
	end
	return blocks
end

-- El agua de una banda de filas (rows: sus alturas, de rowFloors), en baldosas de `tile` studs: desde el
-- fondo más hondo de la baldosa hasta -14 (o hasta la superficie al sur de SlabMaxZ). Va ANTES que el
-- fondo (planBand), que tapa el agua sobrante de debajo.
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

-- Alturas de una fila (para planBand): índice de celda -> { F = fondo, M = material, C = pared empinada }
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

---------------------------------------------------------------------
-- Jardines de coral repartidos por las playas (v122)
---------------------------------------------------------------------
-- Por cada tramo de costa con playa (no los acantilados de CityPlan.Cliffs), cada ShoreReefSpacing
-- studs, un jardín a ShoreReefOffset de la arena; solo en mar libre (ni puertos, ni islas, ni el
-- aeropuerto, ni el río, ni dentro del arrecife o del kelp) y no a menos de 400 studs de otro.
do
	local coast = CityPlan.Coast
	local function cliff(i: number): boolean
		for _, r in CityPlan.Cliffs do
			if i >= r[1] and i < r[2] then
				return true
			end
		end
		return false
	end
	local DIRS = { { "del norte", 0, -1 }, { "del este", 1, 0 }, { "del sur", 0, 1 }, { "del oeste", -1, 0 } }
	local count = 0
	for i = 1, #coast do
		if not cliff(i) then
			local a, b = coast[i], coast[i % #coast + 1]
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len = sqrt(dx * dx + dz * dz)
			local nx, nz = -dz / len, dx / len
			local mx, mz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
			if CityPlan.inside(coast, mx + nx * 5, mz + nz * 5) then
				nx, nz = -nx, -nz
			end
			local steps = math.max(1, math.floor(len / Ocean.ShoreReefSpacing + 0.5))
			for k = 1, steps do
				local t = (k - 0.5) / steps
				local x = a[1] + dx * t + nx * Ocean.ShoreReefOffset
				local z = a[2] + dz * t + nz * Ocean.ShoreReefOffset
				local d = Ocean.landDistance(x, z)
				local free = d > 80 and d < 150 and keepWeight(x, z) < 0.01 and not inDisks(Ocean.Reefs, x, z) and not inDisks(Ocean.Kelp, x, z)
				if free then
					for _, other in Ocean.ShoreReefs do
						if (other.X - x) ^ 2 + (other.Z - z) ^ 2 < 400 * 400 then
							free = false
							break
						end
					end
				end
				if free then
					count += 1
					-- (el nombre: hacia qué lado de la isla queda)
					local best, bestDot = DIRS[1], -math.huge
					for _, dir in DIRS do
						local dot = dir[2] * x + dir[3] * z
						if dot > bestDot then
							best, bestDot = dir, dot
						end
					end
					table.insert(Ocean.ShoreReefs, { Id = ("CoralPlaya%d"):format(count), Name = "Jardín de coral " .. best[1], X = floor(x), Z = floor(z), R = 45 })
				end
			end
		end
	end
	for _, reef in Ocean.ShoreReefs do
		local poi = { Id = reef.Id, Name = reef.Name, Zone = "Coral", X = reef.X, Z = reef.Z, Radius = 38, Y = 2, Shore = true }
		table.insert(Ocean.Pois, poi)
		Ocean.PoiById[poi.Id] = poi
	end
end

-- Los sitios de la zona de referencia (Cañón de Dorada: ReefZone.Pois). Su zona, la que diga el fondo.
-- Reef = lo construye World/ReefZoneBuilder (no OceanBuilder).
for _, rp in ReefZone.Pois do
	local x, z = ReefZone.where(rp)
	local poi = { Id = rp.Id, Name = rp.Name, Zone = Ocean.zoneAt(x, z), X = floor(x), Z = floor(z), Radius = rp.Radius, Y = rp.Y, Chest = rp.Chest, Reef = true }
	table.insert(Ocean.Pois, poi)
	Ocean.PoiById[poi.Id] = poi
end

return Ocean
