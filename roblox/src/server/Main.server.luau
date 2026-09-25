-- Punto de entrada del servidor. Construye la ciudad y arranca todos los sistemas.
-- El orden importa: primero el mapa (los servicios buscan sus tags en él).

local Services = script.Parent.Services

local World = script.Parent.World
local TerrainBuilder = require(World.TerrainBuilder)

-- 1) Terreno primero, para que nadie caiga al vacío mientras se prepara la ciudad
TerrainBuilder.build()

-- 2) La ciudad viene construida dentro del archivo (scripts/build-place.luau) y ya optimizada.
--    Antes, si se podían descargar los packs de Synty, se BORRABA y se volvía a construir entera
--    al arrancar (casi 100.000 piezas): eso colgaba Studio y los PC modestos. Ya no se hace.
--    (Solo se construye aquí si el archivo no trae la ciudad.)
local town = workspace:FindFirstChild("Town")
local TownBuilder = require(World.TownBuilder)
if not town then
	TownBuilder.build()
end
TerrainBuilder.removeGroundPart()

-- 4) Datos para el tráfico y los peatones que simula cada cliente
local Roads = require(World.Kit.Roads)
local segments = {}
for _, segment in Roads.segments() do
	table.insert(segments, { A = segment.A, B = segment.B, Kind = segment.Kind, Width = Roads.Kinds[segment.Kind].Road })
end
require(World.Ambient).publish(TownBuilder.roads(), segments)

local order = {
	"DataService",
	"MonetizationService",
	"RoleService",
	"LifeService",
	"NeedsService",
	"WorldService",
	"WeatherService", -- estaciones y tiempo: sol, lluvia, tormenta, nieve, niebla
	"JobService",
	"FoodService",
	"HouseService",
	"TravelService",
	"VehicleService", -- bicis, monopatines, motos y coches
	"RestaurantService", -- camarero + barman (con NPC si falta alguien)
	"DrivingSchoolService", -- autoescuela: carnet de moto y de coche
	"ArcadeService", -- recreativos: juegos de bolas, tickets y premios
	"ProgressionService", -- nivel, experiencia, estadísticas, vida y estamina
	"LocationService",
	"CinematicService",
	"InventoryService", -- mochila estilo Minecraft (barra rápida + 27 casillas)
	"ShopService", -- tiendas donde se hacen los recados
	"ClassService", -- clases y exámenes que se juegan (lo usa la historia)
	"DialogueService", -- conversaciones con respuestas (misiones episódicas)
	"MiniGameService", -- pase, canastas, partido de fútbol…
	"SceneService", -- actores y objetos de cada misión (solo para su jugador)
	"LifeStoryService", -- la historia de vida escucha a todos los anteriores
	"BabyService", -- tutorial de bebé (fase 2)
	"SchoolService", -- compañeros y profe en cada colegio
}

for _, name in order do
	local ok, err = pcall(function()
		require(Services[name]).init()
	end)
	if not ok then
		warn(("[Main] Error iniciando %s: %s"):format(name, tostring(err)))
	end
end

print("[Real Life Simulator] Servidor listo ✅")
