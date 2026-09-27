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
	"AvatarService", -- aspecto por defecto del protagonista (sudadera, cargo, mochila…)
	"PositionService", -- al volver a entrar apareces donde lo dejaste
	"NeedsService",
	"WorldService",
	"InteriorService", -- todos los edificios por dentro (salas al entrar, ascensores e instituciones)
	"PropertyService", -- casas y pisos que se compran, y los vecinos que viven en ellos
	"InteractService", -- los muebles se usan: sentarse, dormir, tele, luces, nevera, grifos, ducha, puertas…
	"WeatherService", -- estaciones y tiempo: sol, lluvia, tormenta, nieve, niebla
	"ToyService", -- balones y conos con física: se patean, botan y vuelven solos a su sitio
	"BreakService", -- piedras que se lanzan: ventanas y puertas que se rompen (y se arreglan solas)
	"JobService",
	"FoodService",
	"HouseService",
	"TravelService",
	"VehicleService", -- bicis, monopatines, motos y coches
	"RestaurantService", -- camarero + barman (con NPC si falta alguien)
	"DrivingSchoolService", -- autoescuela: carnet de moto y de coche
	"BusService", -- autobús urbano L1: pasajeros con billete y oficio de conductor
	"ArcadeService", -- recreativos: juegos de bolas, tickets y premios
	"ProgressionService", -- nivel, experiencia, estadísticas, vida y estamina
	"LocationService",
	"CinematicService",
	"InventoryService", -- mochila estilo Minecraft (barra rápida + 27 casillas)
	"ShopService", -- tiendas donde se hacen los recados
	"SupermarketService", -- supermercados: carrito, cajas, charcutería, clientes y oficios
	"CafeService", -- cafeterías: pedir en la barra y oficio de barista paso a paso
	"PostService", -- Correos: oficio de repartidor con rutas por las casas de Valmar
	"GarbageService", -- Limpieza: oficio de basurero con papeleras llenas y camión de la basura
	"MedicalService", -- hospitales: pacientes, consultas y oficio de médico/a con diagnóstico
	"PoliceService", -- comisarías: oficio de policía con avisos, coche patrulla y sirena
	"FireService", -- bomberos: incendios en casas, coches y papeleras, gatos en apuros, camión y sirena
	"CinemaService", -- cines: sesiones con película en pantalla y oficio de taquillero/a
	"HotelService", -- hoteles: reservar habitación, descansar y oficio de recepcionista
	"TradeService", -- intercambio entre jugadores y mercadillo
	"SocialService", -- grupos de jugadores y chat privado (menú al tocar a un jugador)
	"FishingService", -- pesca, tienda de pesca, barco y oficio de pescador
	"FarmService", -- agricultores y ganaderos: fincas de Villaverde, cooperativa, obrador y venta a supermercados
	"BusinessService", -- negocios de jugadores: locales, gasolineras y hoteles con existencias, precios y clientes
	"MetroService", -- metro subterráneo: trenes, galería, encargos y revisor
	"GymService", -- gimnasios: recepción, máquinas, ritmo, fuerza que se nota en el cuerpo y monitor/a
	"MetroLifeService", -- vida del metro: guardias, ratas, aseos, taquillas, fuente, piano…
	"DivingService", -- nadar, bucear (aire) y pesca submarina con fusil o arpón
	"SeaEventService", -- catástrofes marinas: tsunami, temporal, remolino, marea negra, tiburón y medusas
	"ClassService", -- clases y exámenes que se juegan (lo usa la historia)
	"DialogueService", -- conversaciones con respuestas (misiones episódicas)
	"MiniGameService", -- pase, canastas, partido de fútbol…
	"CombatService", -- golpes entre jugadores (combo, defenderse y K.O.) y a los personajes de tus misiones
	"CareerService", -- carreras en las instituciones: rangos, ascensos, plus de sueldo y uniformes
	"JusticeService", -- juicios (jueces), condenas y prisión (presos y funcionarios)
	"TaxService", -- Agencia Tributaria: declaración de la renta, agentes e inspecciones
	"WantedService", -- delitos, testigos y estrellas de búsqueda: patrullas, agentes y helicópteros
	"WeaponService", -- armas de fuego y de juguete, Armerías, licencia de armas y galería de tiro
	"HospitalService", -- morir: pantalla de HAS MUERTO y reaparecer en el hospital (factura)
	"PrisonService", -- la vida en la cárcel: trabajos, deporte, estudios, comedor, túnel y aislamiento
	"SceneService", -- actores y objetos de cada misión (solo para su jugador)
	"LifeStoryService", -- la historia de vida escucha a todos los anteriores
	"BabyService", -- tutorial de bebé (fase 2)
	"CanteenService", -- comedor de cada colegio: comida gratis para los alumnos, cocinera y mesas puestas
	"SchoolService", -- compañeros y profe en cada colegio: siguen el horario y van a buscarte si tu misión lo pide
	"UpdateService", -- versión nueva publicada: los servidores viejos llevan a sus jugadores a uno nuevo
	"ActionService", -- linterna (los gestos, trepar y sentarse van en el cliente)
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
