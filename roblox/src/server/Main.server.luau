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
-- Si el archivo trae una ciudad de antes de la decoración de las plantas bajas, se decora ahora
-- (una vez: la ciudad guarda la versión en su atributo DecorVersion)
do
	local built = workspace:FindFirstChild("Town")
	if built then
		local ok, err = pcall(function()
			require(World.Kit.Decor).dressTown(built)
		end)
		if not ok then
			warn("[Decor] " .. tostring(err))
		end
	end
end
-- Ciudad construida antes de los acabados (cristal de fachada con reflejo): se aplican ahora, una vez
do
	local built = workspace:FindFirstChild("Town")
	local Polish = require(World.Kit.Polish)
	if built and (built:GetAttribute("SurfaceVersion") or 0) < Polish.SurfaceVersion then
		local ok, err = pcall(Polish.surfaces, built)
		if not ok then
			warn("[Polish] " .. tostring(err))
		end
	end
end
-- Texturas PBR de verdad (MaterialService): un MaterialVariant por material con ids subidos, en lugar
-- del material de Roblox; las piezas sueltas (pintura vial, bordillos, coches…) si la ciudad del archivo
-- se construyó con otros ids. Sin ids no cambia nada (Kit/MaterialLook, shared/Textures).
-- (en un hilo aparte: antes pasa los ids de Decal a imagen con InsertService, shared/Images; y lo
-- mismo con la ropa del pase, shared/OutfitIds)
task.spawn(function()
	local ok, err = pcall(function()
		require(World.Kit.MaterialLook).start(workspace:FindFirstChild("Town"))
	end)
	if not ok then
		warn("[MaterialLook] " .. tostring(err))
	end
end)
task.spawn(function()
	local ok, err = pcall(function()
		local Shared = game:GetService("ReplicatedStorage").Shared
		local Images = require(Shared.Images)
		if Images.resolve(require(Shared.OutfitIds)) > 0 then
			-- la ropa que se puso antes de acabar
			for _, item in workspace:GetDescendants() do
				if item.Name == "ValmarShirt" and item:IsA("Shirt") then
					item.ShirtTemplate = Images.of(item.ShirtTemplate)
				elseif item.Name == "ValmarPants" and item:IsA("Pants") then
					item.PantsTemplate = Images.of(item.PantsTemplate)
				end
			end
		end
	end)
	if not ok then
		warn("[Images] " .. tostring(err))
	end
end)
TerrainBuilder.removeGroundPart()

-- 3b) El sueño del prólogo: una isla pequeña en el cielo donde los personajes nuevos aprenden los
--     controles (Misiones/Prologo_Sueno). Si falla, el prólogo no empieza y se juega normal.
do
	local ok, err = pcall(function()
		require(World.Kit.DreamIsland).build()
	end)
	if not ok then
		warn("[DreamIsland] " .. tostring(err))
	end
end

-- 4) Datos para el tráfico y los peatones que simula cada cliente
local Roads = require(World.Kit.Roads)
local segments = {}
for _, segment in Roads.segments() do
	table.insert(segments, { A = segment.A, B = segment.B, Kind = segment.Kind, Width = Roads.Kinds[segment.Kind].Road, Walk = Roads.Kinds[segment.Kind].Walk })
end
require(World.Ambient).publish(TownBuilder.roads(), segments)

local order = {
	"DataService",
	"OnboardingService", -- primeros pasos: tutorial guiado y consejos de la primera vez (lo guardado)
	"MonetizationService",
	"RoleService",
	"LifeService",
	"AvatarService", -- aspecto por defecto del protagonista (sudadera, cargo, mochila…)
	"PositionService", -- al volver a entrar apareces donde lo dejaste
	"NeedsService",
	"WorldService",
	"CalendarService", -- el día de tu vida se guarda: un servidor vacío sigue tu calendario (antes: siempre «Día 1»)
	"InteriorService", -- todos los edificios por dentro (salas al entrar, ascensores e instituciones)
	"PropertyService", -- casas y pisos que se compran, y los vecinos que viven en ellos
	"HousingService", -- vivienda al llegar, alquiler, llaves, timbre y horario de los vecinos
	"InteractService", -- los muebles se usan: sentarse, dormir, tele, luces, nevera, grifos, ducha, puertas…
	"FridgeService", -- neveras: gratis con tus padres (colegio); desde la universidad, lo que compres y guardes
	"ResidenceService", -- residencia universitaria: habitación compartida o individual para cada estudiante
	"WeatherService", -- estaciones y tiempo: sol, lluvia, tormenta, nieve, niebla
	"ToyService", -- balones y conos con física: se patean, botan y vuelven solos a su sitio
	"BreakService", -- piedras que se lanzan: ventanas y puertas que se rompen (y se arreglan solas)
	"GadgetService", -- inventos exclusivos de las misiones locas (pistola de rayos, mando de dimensiones…)
	"JobService",
	"FoodService",
	"HouseService",
	"SleepService", -- dormir en cualquier cama tuya: energía, estamina, reaparición y amanecer a las 8:30
	"TravelService",
	"VehicleService", -- bicis, monopatines, motos y coches
	"BoatService", -- barcos propios: puerto deportivo (sacar, guardar, comprar) y la lancha del pase
	"RestaurantService", -- camarero + barman (con NPC si falta alguien)
	"DrivingSchoolService", -- autoescuela: carnet de moto y de coche
	"BusService", -- autobús urbano L1: pasajeros con billete y oficio de conductor
	"CrashService", -- choques entre vehículos: el servidor valida los golpes y reparte el empujón (shared/Crash)
	"KnockService", -- lo que sale despedido: papeleras, conos, terrazas, motos de adorno, personas (shared/Knock)
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
	"FlightService", -- aeropuerto: aviones con horario, billetes, embarque y vuelos (Isla de las Gaviotas)
	"AviationService", -- aeroclub: licencia de piloto, avionetas de alquiler y avión de línea que pilotan los jugadores
	"RailService", -- tren de Cercanías en superficie: estaciones, billetes, pasos a nivel y viajeros
	"GymService", -- gimnasios: recepción, máquinas, ritmo, fuerza que se nota en el cuerpo y monitor/a
	"MetroLifeService", -- vida del metro: guardias, ratas, aseos, taquillas, fuente, piano…
	"StaffService", -- cada sitio que atiende al público tiene a alguien (NPC si no hay jugador de ese oficio)
	"CrowdService", -- gente en las salas, las tiendas, los parques y las plazas (aunque juegues solo)
	"PlaceLifeService", -- vida por lugar: corros, músicos, colas, toallas, petanca… cerca de los jugadores
	"DivingService", -- nadar, bucear (aire) y pesca submarina con fusil o arpón
	"SeaEventService", -- catástrofes marinas: tsunami, temporal, remolino, marea negra, tiburón y medusas
	"ClassService", -- clases y exámenes que se juegan (lo usa la historia)
	"DialogueService", -- conversaciones con respuestas (misiones episódicas)
	"MiniGameService", -- pase, canastas, partido de fútbol…
	"CombatService", -- golpes entre jugadores (combo, defenderse y K.O.) y a los personajes de tus misiones
	"CareerService", -- carreras en las instituciones: rangos, ascensos, plus de sueldo y uniformes
	"JusticeService", -- juicios (jueces), condenas y prisión (presos y funcionarios)
	"TaxService", -- Agencia Tributaria: declaración de la renta, agentes e inspecciones
	"ConductService", -- historial de buen o mal comportamiento: la familia se entera, castigos y paga
	"WantedService", -- delitos, testigos y estrellas de búsqueda: patrullas, agentes y helicópteros
	"WeaponService", -- armas de fuego y de juguete, Armerías, licencia de armas y galería de tiro
	"HospitalService", -- morir: pantalla de HAS MUERTO y reaparecer en el hospital (factura)
	"PrisonService", -- la vida en la cárcel: trabajos, deporte, estudios, comedor, túnel y aislamiento
	"SceneService", -- actores y objetos de cada misión (solo para su jugador)
	"LifeStoryService", -- la historia de vida escucha a todos los anteriores
	"CityErrandService", -- encargos de la ciudad: gente con ❗ por todo el mapa que te pide pequeños favores
	-- Pase de temporada (en este orden: temporada, recompensas, misiones, núcleo y la XP que escucha a todos)
	"BattlePassSeasonService", -- temporada actual, estado, cambio de temporada y archivo
	"BattlePassRewardService", -- entrega recompensas con los sistemas de siempre (vehículos, ropa, vivienda…)
	"SeasonMissionService", -- misiones diarias, semanales, de temporada y la historia de temporada
	"BattlePassService", -- niveles, reclamar, premium (Game Pass) y el remoto BattlePass
	"BattlePassXPService", -- XP del pase por jugar normal (escucha StoryEvents), con topes diarios
	"DebugService", -- herramientas de depuración SOLO para el dueño del juego (/debug, panel F8)
	"TesterService", -- modo pruebas SOLO para el dueño (/pruebas): dinero infinito, armas, oficios sin requisitos…
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
