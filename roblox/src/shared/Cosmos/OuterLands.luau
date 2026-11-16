-- OuterLands: LAS TIERRAS EXTERIORES, el continente nuevo alrededor del mar de Valmar (petición del dueño:
-- «haz la tierra nueva alrededor» para que las ocho regiones de caza sean territorios de verdad). Cuentas puras
-- y repetibles (mismo resultado en el servidor, en el cliente y en las pruebas): la altura del suelo de cada
-- punto, su material, dónde van los puentes, los campamentos y la decoración. Lo escribe World/OuterLandsBuilder;
-- lo usan World/ValmarWilds (guaridas encima), Controllers/RegionBanner y scripts/test-tierras.luau.
--
--   * Forma: un marco de ValmarRegions.Frame.Width studs alrededor del mar (shared/Sea/OceanBiomes), con su
--     playa hacia Valmar y su costa hacia fuera; más allá, una franja de mar (Band) y un límite invisible.
--   * El relieve sale de la región (shared/Cosmos/ValmarRegions): lomas y bosque, praderas, charcas del
--     pantano, dunas, terrazas de las ruinas, picos nevados, roca negra afilada y un volcán con cráter. En el
--     borde entre dos regiones se mezclan las dos (nada de escalones).
--   * Cuatro puentes desde la costa de la isla (norte, este, sur y oeste) y un campamento seguro (con Taller) donde
--     llegan. Junto a los campamentos y a la llegada de los puentes el suelo es llano.

local VR = require(script.Parent.ValmarRegions)

local OuterLands = {}

OuterLands.Surface = -2 -- el nivel del mar (shared/Sea/OceanBiomes)
OuterLands.Floor = -26 -- el fondo del mar alrededor del continente
OuterLands.Band = 456 -- mar más allá de la costa de fuera (y luego el límite)
OuterLands.Coast = 160 -- la playa de dentro empieza a tantos studs del borde del mar de Valmar
OuterLands.DeckY = 30 -- altura del tablero de los puentes
OuterLands.CampY = 8

local F = VR.Frame
local W = F.Width

-- Los cuatro puentes: de la costa de la isla (From, en tierra) hacia fuera hasta el continente (Dir: unidad)
OuterLands.Bridges = {
	{ Id = "Norte", Name = "Puente del Norte", X = 0, Dir = { 0, -1 }, Region = "BosqueEtereo" },
	{ Id = "Este", Name = "Puente del Este", Z = 0, Dir = { 1, 0 }, Region = "PantanoMaldito" },
	{ Id = "Sur", Name = "Puente del Sur", X = -1200, Dir = { 0, 1 }, Region = "LlanurasSalvajes" },
	{ Id = "Oeste", Name = "Puente del Oeste", Z = 300, Dir = { -1, 0 }, Region = "DesiertoDorado" },
}
-- dónde llega cada puente al borde del mar de Valmar y dónde queda su campamento
for _, b in OuterLands.Bridges do
	local dx, dz = b.Dir[1], b.Dir[2]
	local edgeX = if dx > 0 then F.MaxX elseif dx < 0 then F.MinX else b.X
	local edgeZ = if dz > 0 then F.MaxZ elseif dz < 0 then F.MinZ else b.Z
	b.EdgeX, b.EdgeZ = edgeX, edgeZ
	b.CampX, b.CampZ = edgeX + dx * 430, edgeZ + dz * 430
end
OuterLands.CampRadius = 170 -- llano alrededor del campamento
OuterLands.SafeRadius = 280 -- ninguna guarida tan cerca de un campamento

local function smooth(a: number, b: number, x: number): number
	local t = math.clamp((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

local function fbm(x: number, z: number, scale: number, seed: number): number
	local s = 0
	local amp, freq, norm = 1, 1 / scale, 0
	for _ = 1, 3 do
		s += math.noise(x * freq, z * freq, seed) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.1
	end
	return s / norm * 1.8 -- (más o menos −1..1)
end

-- El volcán de las Tierras Volcánicas (en la esquina suroeste)
OuterLands.Volcano = { X = -6450, Z = 6450, R = 760, H = 470, Crater = 190, CraterDepth = 270 }

-- El relieve propio de cada región (studs sobre la playa)
local RELIEF: { [string]: (number, number) -> number } = {
	BosqueEtereo = function(x, z)
		return math.max(0, 28 + 62 * fbm(x, z, 620, 1.3))
	end,
	LlanurasSalvajes = function(x, z)
		return math.max(0, 10 + 18 * fbm(x, z, 900, 2.1))
	end,
	PantanoMaldito = function(x, z)
		return -5 + 11 * fbm(x, z, 330, 3.3) -- (lo que baja del mar se llena de agua: charcas)
	end,
	DesiertoDorado = function(x, z)
		local warp = 4 * fbm(x, z, 800, 4.4)
		local ridge = 1 - math.abs(math.sin((x * 0.75 + z * 0.35) / 120 + warp))
		return 12 + 42 * ridge * ridge + 10 * fbm(x, z, 500, 4.9)
	end,
	RuinasAntiguas = function(x, z)
		local v = math.max(0, 34 + 46 * fbm(x, z, 700, 5.5))
		return math.floor(v / 16) * 16 + (v % 16) * 0.2 -- (terrazas)
	end,
	MontanasHeladas = function(x, z)
		local r = 1 - math.abs(fbm(x, z, 760, 6.6))
		return 30 + 360 * r ^ 2.6 + 24 * fbm(x, z, 260, 6.9)
	end,
	TierrasOscuras = function(x, z)
		local r = 1 - math.abs(fbm(x, z, 520, 7.7))
		return math.max(0, 24 + 170 * r ^ 3 + 18 * fbm(x, z, 200, 7.1))
	end,
	TierrasVolcanicas = function(x, z)
		local V = OuterLands.Volcano
		local d = math.sqrt((x - V.X) ^ 2 + (z - V.Z) ^ 2)
		local cone = V.H * math.max(0, 1 - d / V.R) ^ 1.5
		local crater = V.CraterDepth * math.max(0, 1 - d / V.Crater) ^ 0.6
		return math.max(0, 22 + 40 * fbm(x, z, 560, 8.8)) + cone - crater
	end,
}
OuterLands.Relief = RELIEF

-- Diferencia de ángulos (−180..180)
local function delta(a: number, b: number): number
	return ((a - b + 540) % 360) - 180
end

-- Las dos regiones de un punto y cuánto pesa la segunda (0 dentro, 0,5 en el borde)
function OuterLands.regions(x: number, z: number): ({ [string]: any }, { [string]: any }, number)
	local b = VR.bearing(x, z) + math.noise(x / 900, z / 900, 3.7) * 14
	local first, second, d1, d2 = nil, nil, math.huge, math.huge
	for _, reg in VR.List do
		local d = math.abs(delta(b, reg.Bearing))
		if d < d1 then
			first, second, d2, d1 = reg, first, d1, d
		elseif d < d2 then
			second, d2 = reg, d
		end
	end
	local half = VR.Width / 2
	local f = 0.5 * smooth(half - 7, half, d1)
	return first :: any, second :: any, f
end

-- Lo que está de la orilla: >0 en tierra (studs desde la playa más cercana), <0 en el agua
function OuterLands.edge(x: number, z: number): number
	local d = VR.outside(x, z)
	if d <= 0 then
		return -1000
	end
	local n1 = math.noise(x / 700, z / 700, 5.1) * 140 + math.noise(x / 230, z / 230, 1.7) * 50
	local n2 = math.noise(x / 650, z / 650, 9.2) * 130 + math.noise(x / 210, z / 210, 2.4) * 45
	local inner = d - OuterLands.Coast + n1
	local outer = (W - 80) - d + n2
	return math.min(inner, outer)
end

-- ¿Cerca de un campamento o del paso de un puente? (llano). Devuelve 0..1 (1 = llano del todo)
function OuterLands.flat(x: number, z: number): number
	local best = 0
	for _, b in OuterLands.Bridges do
		local dc = math.sqrt((x - b.CampX) ^ 2 + (z - b.CampZ) ^ 2)
		best = math.max(best, 1 - smooth(OuterLands.CampRadius, OuterLands.CampRadius + 140, dc))
		-- el paso desde el borde del mar hasta el campamento (por donde baja la rampa del puente)
		local dx, dz = b.Dir[1], b.Dir[2]
		local along = (x - b.EdgeX) * dx + (z - b.EdgeZ) * dz
		local side = math.abs((x - b.EdgeX) * dz - (z - b.EdgeZ) * dx)
		if along > -20 and along < 460 then
			best = math.max(best, 1 - smooth(40, 110, side))
		end
	end
	return best
end

-- Altura del suelo (Y del mundo) en las Tierras Exteriores (y en su franja de mar). nil dentro del mar de Valmar.
function OuterLands.height(x: number, z: number): number?
	local d = VR.outside(x, z)
	if d <= 0 then
		return nil
	end
	local e = OuterLands.edge(x, z)
	local base
	if e <= -220 then
		base = OuterLands.Floor
	elseif e <= 0 then
		base = OuterLands.Floor + (e + 220) / 220 * (2 - OuterLands.Floor)
	else
		base = 2 + math.min(e, 300) / 300 * 5
	end
	local h = base
	if e > 0 then
		local r1, r2, f = OuterLands.regions(x, z)
		local rel = RELIEF[r1.Id](x, z) * (1 - f) + RELIEF[r2.Id](x, z) * f
		local m = smooth(60, 420, e)
		h = base + rel * m
	end
	local fl = OuterLands.flat(x, z)
	if fl > 0 then
		h = h + (OuterLands.CampY - h) * fl
	end
	return h
end

-- ¿Tierra firme (no agua) en ese punto?
function OuterLands.isLand(x: number, z: number): boolean
	local h = OuterLands.height(x, z)
	return h ~= nil and h > OuterLands.Surface + 1.5
end

-- Pendiente (subida por stud) alrededor de un punto
function OuterLands.slope(x: number, z: number, step: number?): number
	local s = step or 8
	local h = OuterLands.height(x, z) or 0
	local hx = OuterLands.height(x + s, z) or h
	local hz = OuterLands.height(x, z + s) or h
	return math.sqrt((hx - h) ^ 2 + (hz - h) ^ 2) / s
end

-- Lo más cerca que queda un campamento
function OuterLands.campDistance(x: number, z: number): number
	local best = math.huge
	for _, b in OuterLands.Bridges do
		best = math.min(best, math.sqrt((x - b.CampX) ^ 2 + (z - b.CampZ) ^ 2))
	end
	return best
end

-- Material del suelo (nombre de Enum.Material) con su altura y pendiente
function OuterLands.material(x: number, z: number, h: number, slope: number): string
	if h < OuterLands.Surface - 0.5 then
		local reg = OuterLands.regions(x, z)
		return if reg.Id == "PantanoMaldito" then "Mud" else "Sand"
	end
	local reg = OuterLands.regions(x, z)
	local e = OuterLands.edge(x, z)
	local g = reg.Ground
	-- (el suelo pisado del campamento; alrededor y en el paso del puente, el de la región)
	if OuterLands.campDistance(x, z) < 70 then
		return if reg.Id == "MontanasHeladas" then "Snow" else "Ground"
	end
	if OuterLands.flat(x, z) > 0.6 then
		return g.Flat
	end
	if e < 90 and h < 9 and reg.Id ~= "PantanoMaldito" then
		return if reg.Id == "TierrasVolcanicas" or reg.Id == "TierrasOscuras" then "Basalt" else "Sand"
	end
	local n = math.noise(x / 60, z / 60, 2.9)
	if reg.Id == "TierrasVolcanicas" then
		local V = OuterLands.Volcano
		local dv = math.sqrt((x - V.X) ^ 2 + (z - V.Z) ^ 2)
		if dv < V.Crater * 1.15 or (dv < V.R and n > 0.35) then
			return "CrackedLava"
		end
	end
	if reg.Id == "MontanasHeladas" and h > 150 and slope < 1.1 then
		return if slope > 0.6 then "Glacier" else "Snow"
	end
	if slope > 1.0 + 0.2 * n then
		return g.Steep
	elseif slope > 0.55 + 0.1 * n then
		return g.Slope
	elseif n > 0.25 then
		return g.Mix
	end
	return g.Flat
end

---------------------------------------------------------------------
-- La decoración de cada región (repetible): { Kind, Region, X, Z, Y, Size, Turn }
---------------------------------------------------------------------
OuterLands.DecorPerRegion = {
	BosqueEtereo = { { "Arbol", 460 }, { "Roca", 40 } },
	LlanurasSalvajes = { { "ArbolSolo", 70 }, { "Roca", 50 } },
	PantanoMaldito = { { "ArbolMuerto", 170 }, { "Roca", 20 } },
	DesiertoDorado = { { "Cactus", 120 }, { "Pilar", 40 }, { "Templo", 6 } },
	RuinasAntiguas = { { "Ruina", 30 }, { "Pilar", 50 }, { "Roca", 25 } },
	MontanasHeladas = { { "Pino", 220 }, { "Hielo", 60 } },
	TierrasOscuras = { { "ArbolNegro", 120 }, { "Pua", 70 }, { "Ruina", 8 } },
	TierrasVolcanicas = { { "Pua", 60 }, { "Lava", 26 }, { "Roca", 25 } },
}

local cachedDecor: { { [string]: any } }? = nil
function OuterLands.decor(): { { [string]: any } }
	if cachedDecor then
		return cachedDecor
	end
	local out = {}
	local seed = 99173
	local function rnd(): number
		seed = (seed * 16807) % 2147483647
		return seed / 2147483647
	end
	for _, reg in VR.List do
		local list = OuterLands.DecorPerRegion[reg.Id] or {}
		for _, entry in list do
			local kind, count = entry[1], entry[2]
			local made = 0
			for _ = 1, count * 30 do
				if made >= count then
					break
				end
				local a = reg.Bearing + (rnd() * 2 - 1) * (VR.Width / 2 - 2)
				local t = 0.08 + rnd() * 0.84
				local dist = VR.rayBox(a, t * W)
				local x, z = math.sin(math.rad(a)) * dist, -math.cos(math.rad(a)) * dist
				local h = OuterLands.height(x, z)
				local first = OuterLands.regions(x, z)
				local wantFlat = kind == "Templo" or kind == "Ruina" or kind == "Lava"
				if h and h > OuterLands.Surface + 2 and first.Id == reg.Id and OuterLands.campDistance(x, z) > OuterLands.CampRadius + 40
					and OuterLands.flat(x, z) < 0.05 and OuterLands.slope(x, z) < (if wantFlat then 0.3 else 0.8) then
					made += 1
					table.insert(out, { Kind = kind, Region = reg.Id, X = x, Z = z, Y = h, Size = 0.75 + rnd() * 0.6, Turn = rnd() * math.pi * 2, Seed = math.floor(rnd() * 1e6) })
				end
			end
		end
	end
	cachedDecor = out
	return out
end

return OuterLands
