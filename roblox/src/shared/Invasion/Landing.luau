-- Landing: dónde pueden aterrizar las naves de desembarco alienígenas (y dónde están las zonas que
-- intentan conquistar). Cuentas puras (scripts/test-invasion.luau); el servidor (InvasionService)
-- mira el mundo de verdad con rayos y se lo pasa a Landing.valid.
--
-- Lo que pidió el dueño: que aterricen en sitios ABIERTOS (plazas, parques, la playa…), nunca en una
-- carretera ni encima de un edificio. Por eso cada sitio candidato:
--   1. sale de un lugar conocido del mapa (LifeStory/Locations, resuelto por LocationService) o de un
--      punto del plano (CityPlan.Places / Towns), y alrededor se prueban anillos de puntos;
--   2. cada punto se valida: suelo firme y casi plano (no agua), sin nada encima en una caja del
--      tamaño de la nave (Clear), lejos de las carreteras del plano (CityPlan.Roads, con su ancho real
--      de Kit/Roads) y no en asfalto, y no demasiado alto (no es un tejado).

local CityPlan = require(script.Parent.Parent.CityPlan)

local Landing = {}

-- Ancho real de cada tipo de carretera (Kit/Roads: calzada + aceras) y el margen de seguridad
Landing.RoadHalf = { Autovia = 18 + 2, Avenida = 14 + 7, Calle = 11 + 6 }
Landing.RoadMargin = 14
Landing.Footprint = Vector3.new(44, 30, 44) -- la caja libre que necesita una nave de desembarco
Landing.MaxGroundY = 70 -- más alto que esto es un tejado o un monte: no
Landing.MinNormalY = 0.92 -- casi plano
Landing.Rings = { 0, 26, 52, 80 } -- anillos alrededor del sitio candidato (studs)
Landing.PerRing = 8
-- Suelos que valen (Enum.Material.Name) y los que no
Landing.BadMaterials = { Water = true, Asphalt = true, Glass = true, Neon = true, Air = true }

-- Los sitios: Place = un lugar de LifeStory/Locations (LocationService); XZ = un punto del plano
Landing.Sites = {
	{ Id = "PlazaCentro", Name = "Plaza del centro", Place = "PlazaCentro", XZ = { 40, 60 } },
	{ Id = "Parque", Name = "El parque", Place = "Parque", XZ = { -420, -1820 } },
	{ Id = "Playa", Name = "Playa Dorada", Place = "Playa", XZ = { 3780, -1000 } },
	{ Id = "PlazaFinanciera", Name = "Plaza Financiera", Place = "PlazaFinanciera", XZ = { 0, -720 } },
	{ Id = "Campus", Name = "Campus Valmar", XZ = { 2650, 1300 } },
	{ Id = "SanRoque", Name = "San Roque", XZ = { -650, 2250 } },
	{ Id = "Camping", Name = "El camping", XZ = CityPlan.Places.Camping },
	{ Id = "Mirador", Name = "El mirador", XZ = CityPlan.Places.Mirador },
}

-- Distancia (en planta) a la carretera del plano más cercana, descontado su medio ancho (negativo = encima)
function Landing.roadGap(x: number, z: number): number
	local best = math.huge
	for _, road in CityPlan.Roads do
		local half = Landing.RoadHalf[road.Kind] or 20
		for i = 1, #road.Points - 1 do
			local a, b = road.Points[i], road.Points[i + 1]
			local d = CityPlan.segmentDistance(x, z, a[1], a[2], b[1], b[2]) - half
			if d < best then
				best = d
			end
		end
	end
	for _, r in CityPlan.Roundabouts do
		local d = math.sqrt((x - r[1]) ^ 2 + (z - r[2]) ^ 2) - 62
		if d < best then
			best = d
		end
	end
	return best
end

-- Lo que el servidor ha visto en un punto con sus rayos
export type Probe = {
	X: number,
	Z: number,
	Hit: boolean, -- ¿hay suelo debajo?
	GroundY: number?,
	Material: string?, -- Enum.Material.Name del suelo
	NormalY: number?,
	Clear: boolean?, -- ¿la caja de la nave está vacía?
	Road: boolean?, -- ¿la pieza del suelo es una carretera (nombre/etiqueta)?
	Water: boolean?,
}

-- ¿Vale este punto para aterrizar? (ok, motivo)
function Landing.valid(p: Probe): (boolean, string?)
	if not p.Hit or p.GroundY == nil then
		return false, "sin suelo"
	end
	if p.Water or (p.Material and Landing.BadMaterials[p.Material]) then
		return false, "suelo no válido (" .. tostring(p.Material) .. ")"
	end
	if p.Road then
		return false, "carretera"
	end
	if (p.NormalY or 1) < Landing.MinNormalY then
		return false, "cuesta"
	end
	if p.GroundY > Landing.MaxGroundY or p.GroundY < -2 then
		return false, "demasiado alto o bajo (tejado o agua)"
	end
	if p.Clear ~= true then
		return false, "hay algo encima (edificio, árbol, farola…)"
	end
	if Landing.roadGap(p.X, p.Z) < Landing.RoadMargin then
		return false, "demasiado cerca de una carretera"
	end
	return true, nil
end

-- Los puntos que se prueban alrededor de un sitio (en orden: el centro primero)
function Landing.tries(x: number, z: number): { { number } }
	local out = {}
	for _, ring in Landing.Rings do
		if ring == 0 then
			table.insert(out, { x, z })
		else
			for k = 0, Landing.PerRing - 1 do
				local a = k / Landing.PerRing * math.pi * 2 + ring * 0.01
				table.insert(out, { x + math.cos(a) * ring, z + math.sin(a) * ring })
			end
		end
	end
	return out
end

-- Busca el primer punto válido alrededor de (x, z) con la función que mira el mundo (probe(x, z) -> Probe)
function Landing.find(x: number, z: number, probe: (number, number) -> Probe): (Vector3?, number)
	local tried = 0
	for _, xz in Landing.tries(x, z) do
		tried += 1
		local p = probe(xz[1], xz[2])
		if Landing.valid(p) then
			return Vector3.new(p.X, p.GroundY :: number, p.Z), tried
		end
	end
	return nil, tried
end

-- El sitio libre más cercano a un punto (para el cliente: la zona donde estás)
function Landing.nearest(zones: { { Pos: Vector3 } }, pos: Vector3, radius: number?): (number?, number)
	local best, bestD = nil, math.huge
	for i, z in zones do
		local d = Vector2.new(z.Pos.X - pos.X, z.Pos.Z - pos.Z).Magnitude
		if d < bestD then
			best, bestD = i, d
		end
	end
	if radius and bestD > radius then
		return nil, bestD
	end
	return best, bestD
end

return Landing
