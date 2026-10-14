-- Punto de entrada del servidor. Construye la ciudad y arranca todos los sistemas.
-- El orden importa: primero el mapa (los servicios buscan sus tags en él).

local Services = script.Parent.Services

local World = script.Parent.World
-- Cada paso del arranque va por Boot.step: en su hilo, con pcall y con tiempo máximo. Un paso que falla
-- o se queda esperando ya no deja sin arrancar a los de detrás (el reloj, las partidas, la historia…).
local Boot = require(script.Parent.Boot)
workspace:SetAttribute("ServerReady", false)

-- 1) Terreno primero, para que nadie caiga al vacío mientras se prepara la ciudad
Boot.step("TerrainBuilder", function()
	require(World.TerrainBuilder).build()
end)
-- 1b) El mar hondo alrededor de Valmar (World/OceanBuilder, docs/mar/diseno.md): en su hilo y poco a
--     poco (no frena el arranque); solo toca el mar lejos de la costa, los puertos y las islas
task.spawn(function()
	local ok, err = pcall(function()
		require(World.OceanBuilder).build()
	end)
	if not ok then
		warn("[OceanBuilder] " .. tostring(err))
	end
end)

-- 2) La ciudad viene construida dentro del archivo (scripts/build-place.luau) y ya optimizada.
--    Antes, si se podían descargar los packs de Synty, se BORRABA y se volvía a construir entera
--    al arrancar (casi 100.000 piezas): eso colgaba Studio y los PC modestos. Ya no se hace.
--    (Solo se construye aquí si el archivo no trae la ciudad.)
local town = workspace:FindFirstChild("Town")
if not town then
	Boot.step("TownBuilder", function()
		require(World.TownBuilder).build()
	end, 600)
end
-- Si el archivo trae una ciudad de antes de la decoración de las plantas bajas, se decora ahora
-- (una vez: la ciudad guarda la versión en su atributo DecorVersion)
Boot.step("Decor", function()
	local built = workspace:FindFirstChild("Town")
	if built then
		require(World.Kit.Decor).dressTown(built)
	end
end, 120)
-- Ciudad construida antes de los acabados (cristal de fachada con reflejo): se aplican ahora, una vez
Boot.step("Polish", function()
	local built = workspace:FindFirstChild("Town")
	local Polish = require(World.Kit.Polish)
	if built and (built:GetAttribute("SurfaceVersion") or 0) < Polish.SurfaceVersion then
		Polish.surfaces(built)
	end
end, 120)
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
-- Materiales PBR realistas que eligió el dueño en la Tienda de creadores (packs de MaterialVariant):
-- sustituyen a los nuestros en asfalto, aceras, césped, fachadas, tejas, terreno… (World/UserMaterials,
-- tabla en shared/UserMaterialChoice). Si no cargan, se queda todo como está.
task.spawn(function()
	local ok, err = pcall(function()
		-- (y con ellos, cada tipo de calle con su asfalto, adoquín o baldosa, y las señales y tapas del
		-- «Realistic road pack»: World/StreetDress, shared/StreetLook)
		require(World.UserMaterials).start(nil, function(service, library, load, unpack)
			require(World.StreetDress).start(service, library, load, unpack, nil, require(World.Region).Highways)
		end)
	end)
	if not ok then
		warn("[UserMaterials] " .. tostring(err))
	end
end)
-- Cielo de fotos (skybox realista) de día y de noche (World/SkyLoader, ids en shared/SkyChoice):
-- lo pone cada cliente según la hora (Controllers/DayLight). Sin ids o si falla, el cielo de siempre.
task.spawn(function() local ok, err = pcall(function() require(World.SkyAssets).start() end) if not ok then warn("[SkyAssets] " .. tostring(err)) end end) -- cielos especiales, luna, fuego, lluvia, partículas (shared/SkyExtras)
task.spawn(function()
	local ok, err = pcall(function()
		require(World.SkyLoader).start()
	end)
	if not ok then
		warn("[SkyLoader] " .. tostring(err))
	end
end)
task.spawn(function()
	local ok, err = pcall(function()
		local Shared = game:GetService("ReplicatedStorage").Shared
		local Images = require(Shared.Images)
		-- Las texturas de la Grieta del cielo (scripts/upload-rift.sh): del Decal a su imagen
		Images.resolve(require(Shared.RiftTextureIds))
		-- La imagen de la isla del mapa grande (scripts/upload-map.sh): igual
		Images.resolve(require(Shared.MapTextureIds))
		-- El espacio, los planetas y la nave (scripts/upload-espacio.sh): igual, y luego cielos y materiales
		if Images.resolve(require(Shared.Cosmos.EspacioTextureIds)) > 0 then
			pcall(function()
				require(script.Parent.World.PlanetWorld).setupLooks()
			end)
		end
		-- Los sprites del HUD de vuelo (scripts/upload-hud.sh): igual (UI/HudArt usa Images.of)
		local hudIds = Shared:FindFirstChild("HudTextureIds")
		if hudIds then
			Images.resolve(require(hudIds) :: any)
		end
		-- Las caras y la ropa de Cosme (scripts/upload-cosme.sh): igual; al que ya esté puesto se le cambian
		if Images.resolve(require(Shared.CosmeTextureIds)) > 0 then
			local CosmeLook = require(Shared.CosmeLook)
			for _, model in game:GetService("CollectionService"):GetTagged(CosmeLook.TAG) do
				pcall(CosmeLook.refresh, model)
			end
		end
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
Boot.step("RemoveGroundPart", function()
	require(World.TerrainBuilder).removeGroundPart()
end)

-- 3b) El sueño del prólogo: una isla pequeña en el cielo donde los personajes nuevos aprenden los
--     controles (Misiones/Prologo_Sueno). Si falla, el prólogo no empieza y se juega normal.
Boot.step("DreamIsland", function()
	require(World.Kit.DreamIsland).build()
end)

-- 4) Datos para el tráfico y los peatones que simula cada cliente
local segments = {}
Boot.step("Ambient", function()
	local Roads = require(World.Kit.Roads)
	for _, segment in Roads.segments() do
		table.insert(segments, { A = segment.A, B = segment.B, Kind = segment.Kind, Width = Roads.Kinds[segment.Kind].Road, Walk = Roads.Kinds[segment.Kind].Walk })
	end
	require(World.Ambient).publish(require(World.TownBuilder).roads(), segments)
end)

-- 4b) Vegetación con modelos 3D de verdad (packs oficiales de Roblox, World/MeshLibrary): carga los
--     packs una vez y cambia en tandas los árboles, arbustos y flores procedurales, primero los de
--     cerca de las calles. Si la carga falla, se queda todo como está.
task.spawn(function()
	local ok, err = pcall(function()
		require(World.MeshLibrary).start(segments)
	end)
	if not ok then
		warn("[MeshLibrary] " .. tostring(err))
	end
end)
-- 4b1) Naturaleza de los packs de Sebastián (World/NatureAssets): rocas, piedras, peces y tiburones
task.spawn(function() local ok, err = pcall(function() require(World.NatureAssets).start() end) if not ok then warn("[NatureAssets] " .. tostring(err)) end end)
-- 4b2) Talleres mecánicos con el «Realistic Autoservice Props Pack» (4ª tanda de Sebastián, revisado
--      limpio: World/WorkshopProps): grúa de motor, gatos, caballetes, foco… en cada sala de taller.
--      Si no carga, los talleres se quedan como estaban.
task.spawn(function()
	local ok, err = pcall(function()
		require(World.WorkshopProps).start()
	end)
	if not ok then
		warn("[WorkshopProps] " .. tostring(err))
	end
end)
-- 4b2b) Armas, ejército y terror de Sebastián (World/UserArsenal): mallas en armerías, comisarías,
--       cuartel, museo, teatro y feria; y los Pliegues de la Grieta (World/Kit/Pliegues). Si no cargan, nada cambia.
task.spawn(function()
	local ok, err = pcall(function()
		require(World.UserArsenal).start()
	end)
	if not ok then
		warn("[UserArsenal] " .. tostring(err))
	end
end)
-- 4b3) Muebles, comida y objetos de la Tienda de creadores en casas, tiendas, bares, oficinas, naves,
--      hospital y comisaría (World/InteriorProps). Si no cargan, todo se queda como estaba.
task.spawn(function()
	local ok, err = pcall(function()
		require(World.InteriorProps).start()
	end)
	if not ok then
		warn("[InteriorProps] " .. tostring(err))
	end
end)
-- 4c) Bloques de pisos y rascacielos con edificios 3D de verdad (Modular Building Kit – Modern City,
--     World/Buildings3D) y los MaterialVariant de Modern City en MaterialService. Espera a que
--     InteriorService haya mirado los edificios. Si la carga falla, se quedan los bloques de siempre.
task.spawn(function()
	local ok, err = pcall(function()
		require(World.Buildings3D).start(segments)
	end)
	if not ok then
		warn("[Buildings3D] " .. tostring(err))
	end
end)
-- 4d) Calles, ciudad y edificios por fuera con los modelos de la Tienda de Sebastián (World/CityAssets)
task.spawn(function() local ok, err = pcall(function() require(World.CityAssets).start() end) if not ok then warn("[CityAssets] " .. tostring(err)) end end)
-- 4f) La nave realista de malla «HX-7 Halcón» (World/NaveLoader; sin ids sigue la de piezas)
task.spawn(function() local ok, err = pcall(function() require(World.NaveLoader).start() end) if not ok then warn("[Nave] " .. tostring(err)) end end)
-- 4e) Zonas de misión fuera de la ciudad (mina, lava, cueva alienígena, cráteres) con los materiales exóticos del dueño (World/MissionZones)
task.spawn(function() local ok, err = pcall(function() require(World.MissionZones).start() end) if not ok then warn("[MissionZones] " .. tostring(err)) end end)

local order = {
	"DataService",
	"OnboardingService", -- primeros pasos: tutorial guiado y consejos de la primera vez (lo guardado)
	"MonetizationService",
	"RoleService",
	"LifeService",
	"AvatarService", -- aspecto por defecto del protagonista (sudadera, cargo, mochila…)
	"BodyPieceService", -- red de seguridad: quita el pelo y la ropa 3D que se quedan sin su personaje (shared/BodyPieces)
	"SettingsService", -- ajustes guardados con la partida (✨ Gráficos: Auto/Bajo/Medio/Alto)
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
	"PetService", -- mascotas: protectora (adoptar perro o gato), vagabundos, tu mascota contigo y montar a caballo
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
	"OceanService", -- el mar hondo: recursos del fondo, cofres, sitios descubiertos y misiones del mar (docs/mar/diseno.md)
	"SeaBeastService", -- el megalodón del Abismo Silente y el kraken de la Sima (daño y fotos: los decide el servidor)
	"ClassService", -- clases y exámenes que se juegan (lo usa la historia)
	"DialogueService", -- conversaciones con respuestas (misiones episódicas)
	"MiniGameService", -- pase, canastas, partido de fútbol…
	"FootballService", -- fútbol de verdad: balón, porteros y partidos en los campos (pachangas y pasos de la historia)
	"RacketService", -- tenis (1c1) y pádel (2c2) de verdad en cualquier pista o campo de deporte
	"VolleyService", -- vóley playa de verdad 2 contra 2: recibir, colocar, rematar y sacar
	"RaceService", -- atletismo de verdad: carreras con salida (y salida nula), zancada y relevos
	"BasketService", -- baloncesto de verdad: botar, tirar con el medidor, bandejas, rebotes y partidos en las canastas
	"ParkService", -- zonas verdes: columpios, tobogán, pícnic, pipicán, hoguera, tiendas del camping y cocina del huerto
	"FunService", -- 🎈 diversión de lo que ya existía: deportes, monopatín, mascota, pesca, cine, recreativos…
	-- Zonas verdes de ocio (Kit/ZonasVerdes): carteles «Jugar» de vóley playa, tenis, pádel y carrera;
	-- mercadillo y fiesta del sábado; karting de San Roque; skatepark con trucos
	"ZonasDeporteService",
	"FeriaService",
	"KartService",
	"SkateService",
	"DamageService", -- daño por puntos: la función central (enemigos de misión con vida, caer en combate)
	"CombatService", -- pelea: combos y finales, guardia, esquivar/desvanecerse, K.O., poderes de la Grieta
	"FighterService", -- rivales de entrenamiento con IA (se cubren, esquivan y contraatacan)
	"AirCombatService", -- combate aéreo y espacial (Saga 2): naves, oleadas y la arena del Modo pruebas (sin nadie dentro no hace nada)
	"SpaceService", -- el espacio encima de Valmar: puerto espacial del islote, portales, estaciones, asteroides, patrullas y los 7 planetas (docs/espacio.md)
	"PlanetService", -- bajar a los planetas sin pantalla de carga (Tefra entero; los demás «próximamente»): entrada en la atmósfera, aterrizar, bajarse, minar a pie (docs/planetas.md)
	"CareerService", -- carreras en las instituciones: rangos, ascensos, plus de sueldo y uniformes
	"JusticeService", -- juicios (jueces), condenas y prisión (presos y funcionarios)
	"TaxService", -- Agencia Tributaria: declaración de la renta, agentes e inspecciones
	"ConductService", -- historial de buen o mal comportamiento: la familia se entera, castigos y paga
	"WantedService", -- delitos, testigos y estrellas de búsqueda: patrullas, agentes y helicópteros
	"WeaponService", -- armas de fuego y de juguete, Armerías, licencia de armas y galería de tiro
	"HospitalService", -- morir: pantalla de HAS MUERTO y reaparecer en el hospital (factura)
	"PrisonService", -- la vida en la cárcel: trabajos, deporte, estudios, comedor, túnel y aislamiento
	"SceneService", -- actores y objetos de cada misión (solo para su jugador)
	"WorldMemoryService", -- memoria del mundo de cada jugador (cráteres, quién vive dónde…) y decorados por fase
	"HappeningService", -- escenas de la historia: planos, efectos, actores con emoción y consecuencias
	"LifeStoryService", -- la historia de vida escucha a todos los anteriores
	"InvasionService", -- Invasión de la Grieta: alienígenas en naves y a pie al abrirse la grieta, zonas, botín, misiones y la ciudad después (docs/invasion.md)
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
	"HomeMapService", -- 🏠 tus casas en los mapas (siempre) y los filtros de la leyenda guardados
	"CanteenService", -- comedor de cada colegio: comida gratis para los alumnos, cocinera y mesas puestas
	"SchoolService", -- compañeros y profe en cada colegio: siguen el horario y van a buscarte si tu misión lo pide
	"UpdateService", -- versión nueva publicada: los servidores viejos llevan a sus jugadores a uno nuevo
	"ActionService", -- linterna (los gestos, trepar y sentarse van en el cliente)
}

-- (cada servicio en su hilo y con tiempo máximo: si uno se queda esperando, los de detrás arrancan igual)
for _, name in order do
	Boot.step(name, function()
		require(Services[name]).init()
	end)
end

-- El reloj del juego SIEMPRE corre: si WorldService no llegó a ponerlo en marcha, se pone ahora
if not workspace:GetAttribute("ClockRunning") then
	Boot.step("Reloj", function()
		require(Services.WorldService).startClock()
	end)
end

-- La casa de Cosme por dentro: avisos, puertas, luces, el portal y Cosme con su rutina (World/CosmeHouse)
task.spawn(function()
	local ok, err = pcall(function()
		require(World.CosmeHouse.Start).start()
	end)
	if not ok then
		warn("[CasaCosme] " .. tostring(err))
	end
end)

-- Listo: la pantalla de carga de los jugadores (UI/LoadingGate) espera a esto y a su partida
Boot.ready()
if Boot.errors + Boot.timeouts > 0 then
	warn(("[Heroes of History] Servidor listo con %d paso(s) con error y %d sin terminar a tiempo"):format(Boot.errors, Boot.timeouts))
end
print("[Heroes of History] Servidor listo ✅")
