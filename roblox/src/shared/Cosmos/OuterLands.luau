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
--   * UN SOLO TERRENO (fase B, 17-11-2026, el dueño: «el continente pegado a la ciudad»): el mar hondo de Valmar
--     ya no existe. Alrededor de la isla queda solo la LAGUNA (Lagoon studs de agua poco honda: el puerto, la
--     marina, las playas, el aeropuerto ganado al mar y las islas pequeñas siguen junto al agua) y más allá todo
--     es tierra hasta la costa de fuera. Cuatro PASOS de tierra (norte, este, sur y oeste, donde antes estaban
--     los puentes) cruzan la laguna: de la ciudad se sale andando. Un campamento seguro (con Taller) en cada
--     región de los pasos.
--   * Dentro de la isla y en lo hondo de la laguna no se escribe nada (height = nil): ahí manda TerrainBuilder.

local VR = require(script.Parent.ValmarRegions)
local CityPlan = require(script.Parent.Parent.CityPlan)
local Airport = require(script.Parent.Parent.Airport)

local OuterLands = {}

OuterLands.Surface = -2 -- el nivel del mar (shared/Sea/OceanBiomes)
OuterLands.Floor = -26 -- el fondo del mar alrededor del continente
OuterLands.Band = 456 -- mar más allá de la costa de fuera (y luego el límite)
OuterLands.CampY = 8
-- La laguna alrededor de la isla (lo que queda del mar de Valmar)
OuterLands.Lagoon = 330 -- studs de agua desde la costa de la isla (más o menos 90, con ruido)
OuterLands.LagoonFloor = -14 -- el fondo de la laguna (el de TerrainBuilder: allí no se escribe)
OuterLands.IslandWater = 170 -- agua alrededor de las islas pequeñas (más su radio)
OuterLands.PasoWidth = 420 -- ancho de los pasos de tierra que cruzan la laguna
-- Lo que está construido sobre el agua y sigue necesitándola (rectángulos X0..X1, Z0..Z1 y su margen de agua)
OuterLands.KeepWater = {
	{ X0 = Airport.Land.X0, X1 = Airport.Land.X1, Z0 = Airport.Land.Z0, Z1 = Airport.Land.Z1, Margin = 220 }, -- aeropuerto
	{ X0 = 380, X1 = 940, Z0 = 3150, Z1 = 3650, Margin = 260 }, -- puerto (shared/Port/PuertoPlan)
}

local F = VR.Frame
local W = F.Width

-- Los cuatro pasos de tierra (antes, puentes): de la costa de la isla hacia fuera (Dir: unidad); el campamento,
-- en la región a la que llevan. (Se sigue llamando Bridges por lo que ya lo usaba: MapUI, ValmarWilds…)
-- (17-11-2026: con el orden de regiones del mapa definitivo; el del suroeste, en diagonal, lleva al Bosque Etéreo,
-- la región de menos nivel, esquivando el aeropuerto)
OuterLands.Bridges = {
	{ Id = "Norte", Name = "Paso del Norte", X = 0, Dir = { 0, -1 }, Region = "MontanasHeladas" },
	{ Id = "Este", Name = "Paso del Este", Z = 0, Dir = { 1, 0 }, Region = "DesiertoDorado" },
	{ Id = "Sur", Name = "Paso del Sur", X = -1200, Dir = { 0, 1 }, Region = "LlanurasSalvajes" },
	{ Id = "Oeste", Name = "Paso del Oeste", Z = 300, Dir = { -1, 0 }, Region = "PantanoMaldito" },
	{ Id = "Suroeste", Name = "Paso del Suroeste", X = 0, Z = 0, Dir = { -0.8660254, 0.5 }, Region = "BosqueEtereo" },
}
OuterLands.Pasos = OuterLands.Bridges
-- dónde cruza cada paso el borde del antiguo mar de Valmar y dónde queda su campamento
for _, b in OuterLands.Bridges do
	local dx, dz = b.Dir[1], b.Dir[2]
	if dx ~= 0 and dz ~= 0 then
		-- (en diagonal, desde el centro: hasta el borde del antiguo mar siguiendo su rumbo)
		local bearing = math.deg(math.atan2(dx, -dz))
		local dist = VR.rayBox(bearing, 0)
		b.EdgeX, b.EdgeZ = (b.X or 0) + dx * dist, (b.Z or 0) + dz * dist
	else
		b.EdgeX = if dx > 0 then F.MaxX elseif dx < 0 then F.MinX else b.X
		b.EdgeZ = if dz > 0 then F.MaxZ elseif dz < 0 then F.MinZ else b.Z
	end
	b.CampX, b.CampZ = b.EdgeX + dx * 430, b.EdgeZ + dz * 430
end
-- (17-11-2026) Los SANTUARIOS de cada región (shared/Cosmos/RegionGuide, Kind = "Santuario") también son zona
-- segura y llana, como los campamentos
OuterLands.Sanctuaries = {}
do
	local okG, RG = pcall(function()
		return require(script.Parent.RegionGuide)
	end)
	if okG then
		for _, e in RG.all() do
			if e.Place.Kind == "Santuario" then
				table.insert(OuterLands.Sanctuaries, { X = e.X, Z = e.Z, Region = e.Region, Name = e.Place.Name, Flat = 80, Edge = 200 })
			elseif e.Place.Kind == "Arbol" then
				-- (el santuario del árbol gigante: llano y grande, pero no es zona segura)
				table.insert(OuterLands.Sanctuaries, { X = e.X, Z = e.Z, Region = e.Region, Name = e.Place.Name, Flat = 330, Edge = 470, NotSafe = true })
			end
		end
	end
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

-- El volcán de las Tierras Volcánicas (en la esquina noreste, como en el mapa definitivo)
OuterLands.Volcano = { X = 6200, Z = -5900, R = 760, H = 470, Crater = 190, CraterDepth = 270 }

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

-- Distancia a la costa de la isla (positiva fuera de la isla, negativa dentro)
local COAST = CityPlan.Coast
local CMINX, CMAXX, CMINZ, CMAXZ = math.huge, -math.huge, math.huge, -math.huge
for _, pt in COAST do
	CMINX, CMAXX = math.min(CMINX, pt[1]), math.max(CMAXX, pt[1])
	CMINZ, CMAXZ = math.min(CMINZ, pt[2]), math.max(CMAXZ, pt[2])
end
function OuterLands.coastDistance(x: number, z: number): number
	-- (lejos de la caja de la isla basta la distancia a la caja: es menor o igual, y ahorra cuentas)
	local bx = math.max(CMINX - x, x - CMAXX, 0)
	local bz = math.max(CMINZ - z, z - CMAXZ, 0)
	local box = math.sqrt(bx * bx + bz * bz)
	if box > 1200 then
		return box
	end
	local best = math.huge
	local j = #COAST
	for i = 1, #COAST do
		local a, b = COAST[j], COAST[i]
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local len2 = dx * dx + dz * dz
		local t = if len2 > 0 then math.clamp(((x - a[1]) * dx + (z - a[2]) * dz) / len2, 0, 1) else 0
		local px, pz = a[1] + t * dx - x, a[2] + t * dz - z
		best = math.min(best, px * px + pz * pz)
		j = i
	end
	best = math.sqrt(best)
	return if CityPlan.inside(COAST, x, z) then -best else best
end

-- ¿Dentro de la isla grande?
function OuterLands.onIsland(x: number, z: number): boolean
	return x >= CMINX and x <= CMAXX and z >= CMINZ and z <= CMAXZ and CityPlan.inside(COAST, x, z)
end

-- Cuánto está un punto dentro de un paso de tierra (0 fuera, 1 en medio)
function OuterLands.paso(x: number, z: number): number
	local best = 0
	for _, b in OuterLands.Bridges do
		local dx, dz = b.Dir[1], b.Dir[2]
		local ox, oz = b.X or 0, b.Z or 0
		local along = (x - ox) * dx + (z - oz) * dz
		if along > 0 then
			local side = math.abs((x - ox) * dz - (z - oz) * dx)
			local half = OuterLands.PasoWidth / 2 + math.noise(x / 300, z / 300, 2.2) * 40
			best = math.max(best, 1 - smooth(half - 70, half + 50, side))
		end
	end
	return best
end

-- La orilla de dentro (la de la laguna): >0 en tierra (studs desde el agua), <0 en la laguna
function OuterLands.innerEdge(x: number, z: number): number
	local s = OuterLands.coastDistance(x, z)
	local lag = OuterLands.Lagoon + math.noise(x / 520, z / 520, 4.2) * 70 + math.noise(x / 170, z / 170, 6.1) * 22
	local e = s - lag
	-- los pasos de tierra: cruzan la laguna desde la costa (tierra desde el primer stud fuera de la isla)
	if s < lag + 200 then
		local k = OuterLands.paso(x, z)
		if k > 0 then
			e = math.max(e, (s + 60) * k + e * (1 - k))
		end
	end
	-- agua alrededor de las islas pequeñas
	for _, isl in CityPlan.Islands do
		local di = math.sqrt((x - isl.X) ^ 2 + (z - isl.Z) ^ 2)
		e = math.min(e, di - isl.R - OuterLands.IslandWater)
	end
	-- y alrededor de lo construido sobre el agua
	for _, r in OuterLands.KeepWater do
		local rx = math.max(r.X0 - x, x - r.X1, 0)
		local rz = math.max(r.Z0 - z, z - r.Z1, 0)
		e = math.min(e, math.sqrt(rx * rx + rz * rz) - r.Margin)
	end
	return e
end

-- Lo que está de la orilla: >0 en tierra (studs desde la playa más cercana), <0 en el agua
function OuterLands.edge(x: number, z: number): number
	local d = VR.outside(x, z)
	local n2 = math.noise(x / 650, z / 650, 9.2) * 130 + math.noise(x / 210, z / 210, 2.4) * 45
	local outer = (W - 80) - d + n2
	-- (a más de 900 del borde del antiguo mar no hay laguna ni isla cerca)
	if d > 900 then
		return outer
	end
	return math.min(OuterLands.innerEdge(x, z), outer)
end

-- ¿Cerca de un campamento? (llano). Devuelve 0..1 (1 = llano del todo)
function OuterLands.flat(x: number, z: number): number
	local best = 0
	for _, b in OuterLands.Bridges do
		local dc = math.sqrt((x - b.CampX) ^ 2 + (z - b.CampZ) ^ 2)
		best = math.max(best, 1 - smooth(OuterLands.CampRadius, OuterLands.CampRadius + 140, dc))
	end
	return best
end

-- Altura del suelo (Y del mundo) de las Tierras Exteriores (y de su mar de fuera). nil en la isla y en lo
-- hondo de la laguna (ahí no se escribe: queda lo de TerrainBuilder)
function OuterLands.height(x: number, z: number): number?
	local d = VR.outside(x, z)
	if d <= 0 and OuterLands.onIsland(x, z) then
		return nil
	end
	local n2 = math.noise(x / 650, z / 650, 9.2) * 130 + math.noise(x / 210, z / 210, 2.4) * 45
	local outer = (W - 80) - d + n2
	local inner = if d > 900 then math.huge else OuterLands.innerEdge(x, z)
	local e = math.min(inner, outer)
	local base
	if inner <= outer and e <= 0 then
		-- la orilla de la laguna: baja enseguida a su fondo (el de TerrainBuilder)
		local Lf = OuterLands.LagoonFloor
		if e < -60 then
			if d <= 0 then
				return nil
			end
			base = Lf
		else
			base = -1 + (e / 60) * (-1 - Lf)
		end
	elseif e <= -220 then
		base = OuterLands.Floor
	elseif e <= 0 then
		base = OuterLands.Floor + (e + 220) / 220 * (-1 - OuterLands.Floor)
	else
		base = -1 + math.min(e, 300) / 300 * 7
	end
	local h = base
	if e > 0 then
		local r1, r2, f = OuterLands.regions(x, z)
		local rel = RELIEF[r1.Id](x, z) * (1 - f) + RELIEF[r2.Id](x, z) * f
		local m = smooth(60, 420, e)
		h = base + rel * m
	end
	-- (por los pasos de tierra se anda en seco: sin charcas del pantano entre la ciudad y la tierra de fuera)
	if d <= 0 and e > 0 and inner < 1100 then
		local k = OuterLands.paso(x, z)
		if k > 0 then
			h = h + (math.max(h, 1.5) - h) * k
		end
	end
	local fl = OuterLands.flat(x, z)
	if fl > 0 then
		h = h + (OuterLands.CampY - h) * fl
	end
	-- (los santuarios: llanos a su propia altura, la que tendría el suelo en su centro)
	for _, s in OuterLands.Sanctuaries do
		if s.Y then
			local ds = math.sqrt((x - s.X) ^ 2 + (z - s.Z) ^ 2)
			if ds < s.Edge then
				local k = 1 - smooth(s.Flat, s.Edge, ds)
				h = h + (s.Y - h) * k
			end
		end
	end
	return h
end

-- (la altura de cada santuario: la del suelo en su centro, sin allanar; como mínimo un poco sobre el agua)
for _, s in OuterLands.Sanctuaries do
	s.Y = math.max(OuterLands.Surface + 3, OuterLands.height(s.X, s.Z) or 4)
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

-- ¿Escribe aquí el terreno World/OuterLandsBuilder? (fuera de la isla y de lo hondo de la laguna)
function OuterLands.covers(x: number, z: number): boolean
	return OuterLands.height(x, z) ~= nil
end

-- Lo más cerca que queda un campamento
function OuterLands.campDistance(x: number, z: number): number
	local best = math.huge
	for _, b in OuterLands.Bridges do
		best = math.min(best, math.sqrt((x - b.CampX) ^ 2 + (z - b.CampZ) ^ 2))
	end
	for _, s in OuterLands.Sanctuaries do
		if not s.NotSafe then
			best = math.min(best, math.sqrt((x - s.X) ^ 2 + (z - s.Z) ^ 2))
		end
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
			-- (×1,5: ahora también hay tierra donde estaba el mar de Valmar)
			local kind, count = entry[1], math.floor(entry[2] * 1.5)
			local made = 0
			for _ = 1, count * 30 do
				if made >= count then
					break
				end
				local a = reg.Bearing + (rnd() * 2 - 1) * (VR.Width / 2 - 2)
				local t = -0.75 + rnd() * 1.67
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
