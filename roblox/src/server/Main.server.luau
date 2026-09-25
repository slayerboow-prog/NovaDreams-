-- Punto de entrada del servidor. Construye la ciudad y arranca todos los sistemas.
-- El orden importa: primero el mapa (los servicios buscan sus tags en él).

local Services = script.Parent.Services

local World = script.Parent.World
local TerrainBuilder = require(World.TerrainBuilder)

-- 1) Terreno primero, para que nadie caiga al vacío mientras se prepara la ciudad
TerrainBuilder.build()

-- 2) Packs gratuitos de Synty desde la Creator Store (si se pueden descargar)
local packs = require(World.AssetLoader).load()

-- 3) La ciudad viene construida dentro del archivo (scripts/build-place.luau).
--    Si ahora hay packs y la ciudad del archivo se hizo sin ellos, se reconstruye con los modelos.
local town = workspace:FindFirstChild("Town")
if town and packs > 0 and not town:GetAttribute("BuiltWithAssets") then
	town:Destroy()
	town = nil
end
local TownBuilder = require(World.TownBuilder)
if not town then
	TownBuilder.build()
end
TerrainBuilder.removeGroundPart()

-- 4) Datos para el tráfico y los peatones que simula cada cliente
require(World.Ambient).publish(TownBuilder.roads())

local order = {
	"DataService",
	"MonetizationService",
	"RoleService",
	"LifeService",
	"NeedsService",
	"WorldService",
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
