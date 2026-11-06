-- Laboratorio de cine: un archivo ligero del juego para revisar escenas y cinemáticas en un PC modesto.
--
-- El archivo de siempre (RealLifeSimulator.rbxl) trae la ciudad entera (~435.000 piezas) y al darle a
-- Probar en Studio el servidor y el cliente arrancan además el mar hondo, el relieve, el espacio, los
-- planetas, Nácara, el tráfico y los packs de la Tienda: en un portátil con 7-8 GB de RAM Studio se
-- quedaba sin memoria y se cerraba (RBXCRASH: OutOfMemory).
--
-- scripts/build-lab.luau hace LaboratorioCine.rbxl a partir del archivo de siempre: se queda solo con la
-- ciudad cerca de donde pasa la historia (Los Pinos: casa, colegio, parque y casa de Cosme; el campus y
-- la plaza del centro) y marca workspace con el atributo «LaboratorioCine». Con esa marca, Main (servidor)
-- y Main (cliente) se saltan lo pesado de esta lista. El juego publicado nunca lleva la marca: nada cambia.
-- Las escenas cuyo sitio no está en el laboratorio se ponen donde estás (como ya hacía la Cinemateca).

local Laboratorio = {}

Laboratorio.ATTR = "LaboratorioCine"

-- Lo que NO arranca en el laboratorio (pasos del servidor, extras del mundo, servicios y pantallas)
Laboratorio.Skip = {
	-- mundo (servidor)
	OceanBuilder = true,
	Relief = true,
	SafeSpotIndex = true,
	UserMaterials = true,
	MeshLibrary = true,
	NatureAssets = true,
	WorkshopProps = true,
	UserArsenal = true,
	InteriorProps = true,
	Buildings3D = true,
	CityAssets = true,
	Nave = true,
	Puerto = true,
	Aliens = true,
	MissionZones = true,
	-- servicios del espacio, los planetas y el mar
	SpaceService = true,
	GalaxyMapService = true,
	PlanetService = true,
	TefraService = true,
	TefraJobService = true,
	PlanetHazardService = true,
	PlanetJobService = true,
	SpaceJobService = true,
	VarkunService = true,
	AirCombatService = true,
	OceanService = true,
	SeaBeastService = true,
	NacaraService = true,
	SeaCivService = true,
	HondarioService = true,
	MarJobService = true,
	SeaEventService = true,
	InvasionService = true,
	-- transporte grande y gente de relleno por toda la ciudad
	FlightService = true,
	AviationService = true,
	RailService = true,
	MetroService = true,
	MetroLifeService = true,
	CrowdService = true,
	PlaceLifeService = true,
	CityErrandService = true,
	-- pantalla (cliente)
	Ambient = true, -- tráfico y peatones
	Wildlife = true,
	MetroTrains = true,
	Flights = true,
	SeaBiome = true,
	SeaLife = true,
	SpaceDebris = true,
	ValmarGlobe = true,
	NaveLod = true,
	BusBoards = true,
}

-- ¿Es el archivo del laboratorio?
function Laboratorio.active(): boolean
	local ok, on = pcall(function()
		return workspace:GetAttribute(Laboratorio.ATTR) == true
	end)
	return ok and on == true
end

-- ¿Se salta esto en el laboratorio?
function Laboratorio.skips(name: string): boolean
	return Laboratorio.Skip[name] == true and Laboratorio.active()
end

-- La misma función, o una que no hace nada si en el laboratorio se salta (para task.spawn(...))
function Laboratorio.unless(name: string, fn: (...any) -> ...any): (...any) -> ...any
	if Laboratorio.skips(name) then
		return function() end
	end
	return fn
end

return Laboratorio
