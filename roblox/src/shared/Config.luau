-- Config: TODOS los números del juego en un solo sitio.
-- Si quieres equilibrar la economía (sueldos, precios, etc.) cambia los valores aquí.

local Config = {}

Config.GameName = "Heroes of History"
-- La saga de ahora (la historia de Valmar). La siguiente será otra saga con su propio subtítulo.
Config.SagaName = "History of Valmar"
-- El lema de siempre (se puede usar como línea secundaria)
Config.GameMotto = "Tu vida, tu historia"

---------------------------------------------------------------------
-- Guardado de datos
---------------------------------------------------------------------
-- (NO cambiar: es el nombre interno de las partidas guardadas, de cuando el juego se llamaba de otra forma)
Config.DataStoreName = "RealLifeSim_PlayerData_v1"
Config.AutosaveSeconds = 120
Config.StartingMoney = 500

---------------------------------------------------------------------
-- Ciclo día / noche
---------------------------------------------------------------------
Config.DayLengthMinutes = 20 -- minutos reales que dura un día completo
Config.StartClockTime = 8 -- hora a la que empieza el servidor
-- Horario del colegio y del instituto. Mientras haya algún niño o adolescente en el servidor, de
-- Start a End el reloj va más despacio (ClockSpeed): así un día de cole cabe en su horario de verdad.
Config.SchoolDay = {
	Opens = 8.5, -- se abren las puertas
	Start = 9, -- empiezan las clases
	LunchFrom = 14, -- comida en el comedor
	LunchTo = 15,
	End = 17, -- se acaban las clases y cierra
	ClockSpeed = 0.4, -- en horario de clase, una hora de juego dura 2,5 veces más
}
-- El horario del día y la noche (verano de España: atardece de 21:30 a 22:00, noche cerrada a las
-- 22:00, amanece de 7:00 a 8:00) y la curva de oscuridad que siguen farolas, ventanas, faros y grillos
-- están en shared/DayCycle. Lighting.ClockTime es la hora del SOL: la del juego es GameClock.hour().
-- Horario por defecto de una ventana sin OnAt / OffAt (en horas «de antes», DayCycle.windowLit)
Config.WindowsOnAt = 18
Config.WindowsOffAt = 30.5

---------------------------------------------------------------------
-- Calendario del juego (lo usan GameClock y la historia de vida)
-- El día 1 es lunes del mes 1 del año 1.
---------------------------------------------------------------------
Config.Calendar = {
	DaysPerWeek = 7,
	DaysPerMonth = 28, -- 4 semanas por mes
	MonthsPerYear = 12,
}

-- Estaciones y tiempo (shared/Seasons.luau). Un día de juego dura DayLengthMinutes minutos reales,
-- así que con 7 días por estación cada estación dura unas dos horas y media de juego.
Config.Seasons = {
	DaysPerSeason = 7,
	WeatherHours = 6, -- cada cuántas horas de juego puede cambiar el tiempo
	Start = "Primavera", -- estación del día 1
	-- Sonidos (client/Controllers/Weather). Con Id = 0 se usa el archivo de audio/sfx que dice
	-- SoundFiles: su ID en SoundIds (scripts/upload-audio.sh) o un Sound con ese nombre en
	-- ReplicatedStorage > Sonidos. Si no hay ninguno, no suena nada.
	Sounds = { Rain = 0, Thunder = 0, Birds = 0, Wind = 0 },
	SoundFiles = { Rain = "lluvia", Thunder = "trueno", Birds = "pajaros", Wind = "viento" },
	-- Volumen de base (todos en el control 🌳 Ambiente): la lluvia por nivel de lluvia (hasta 1,7), el
	-- viento como mucho, los pájaros con buen tiempo y el trueno. Modestos: un motor o un disparo cerca
	-- se tienen que oír por encima (scripts/test-audiomix).
	SoundLevels = { Rain = 0.5, RainMaxLevel = 1.7, Wind = 0.5, Birds = 0.3, Thunder = 0.6 },
}

---------------------------------------------------------------------
-- La Grieta del cielo (shared/SkyRift, Controllers/SkyRift)
---------------------------------------------------------------------
Config.SkyRift = {
	-- TEMPORAL (pruebas del dueño): true = el cielo recorre las 7 etapas a lo largo de cada día de
	-- juego (shared/SkyRift.Demo), igual para todos. Para volver a la de la historia: false.
	DemoCycle = true,
	LiveTransitions = true, -- cada cambio de etapa se ve pasar en el cielo, en directo (~16 s)
	Toast = true, -- aviso pequeño arriba «¡Mira al cielo!» (uno por transición)
	Shake = 0.06, -- temblor muy leve de la cámara en el destello, solo a pie (0 = ninguno)
	SoundVolume = 1, -- multiplicador del rumor y del trueno de la transición (y de las sirenas)
	-- Sirenas de las comisarías y los bomberos durante cada cambio de etapa (shared/SkyRift.Sirens,
	-- Controllers/RiftSirens): 3D, solo cerca de los cuarteles y solo mientras dura el cambio. false = sin sirenas
	StationSirens = true,
}

---------------------------------------------------------------------
-- Historia de vida (LifeStoryService)
---------------------------------------------------------------------
-- Herramientas de desarrollo (solo para el dueño del juego)
Config.Debug = {
	DevLogs = false, -- true: los avisos [MISSION], [NPC], [DIALOGUE]… salen también en el juego publicado
	LogLevel = "Info", -- nivel mínimo en Studio (o con DevLogs): Debug, Info, Warn, Error
	-- Quién puede usar /debug y el panel de depuración, además del creador del juego y de Studio
	DebugUserIds = {} :: { number },
}

-- Modo pruebas (TesterService, panel «Modo pruebas» con /pruebas): dinero infinito, todas las armas,
-- todos los oficios sin requisitos… Ya lo tienen Studio, el creador del juego y el dueño del grupo;
-- aquí se añaden otros UserId de confianza.
Config.Testers = {} :: { number }
-- …y nombres de usuario de Roblox (sin @; da igual mayúsculas). El número de usuario es más seguro
-- (el nombre se puede cambiar), pero con esto basta mientras no lo tengamos.
Config.TesterNames = { "Sibuastian" } :: { string }

Config.LifeStory = {
	-- Un personaje NUEVO nace bebé (tutorial de bebé, fase 2). Quien ya jugaba antes de la
	-- historia de vida (tiene tiempo jugado guardado) sigue siendo adulto.
	NewCharacterStage = "Bebe",
	VeteranStage = "Adulto",
	DefaultAge = 0,
	TickSeconds = 0.5, -- cada cuánto se comprueban llegadas y esperas
	RefreshSeconds = 5, -- cada cuánto se revisan misiones que dependen de la hora
	MaxActiveSide = 3, -- misiones secundarias a la vez
	DeclineCooldown = 600, -- segundos reales antes de volver a ofrecer una secundaria rechazada
	MaxLifeEvents = 200, -- acontecimientos guardados en la biografía
	ReachPadding = 14, -- studs de margen alrededor de un edificio para contar como "has llegado"
	-- Prólogo jugable («El sueño», tutorial de controles) para personajes nuevos, una sola vez
	Prologue = true,
	PrologueMaxSeconds = 480, -- tope real: si se atasca, se cierra solo y se sigue con el juego normal
	-- «Anteriormente en tu vida…»: al volver al juego, si llevabas fuera al menos este tiempo
	RecapMinAwaySeconds = 60,
	-- Horas de juego que dura cada etapa. Los grandes momentos se reparten por esas horas y entre
	-- ellos se viven días normales generados (DayPlans). El bebé es un tutorial corto (sin horas).
	StageHours = {
		Nino = 5, -- el colegio
		Adolescente = 5, -- el instituto
		AdultoJoven = 8, -- la universidad (o los primeros años de trabajo): residencia, cursos, exámenes, secundarias
		Adulto = 40, -- la vida adulta (capítulo «Tu vida»): más o menos un cumpleaños por hora de juego
	},
	-- Edad al empezar y al terminar cada etapa (un cumpleaños cada StageHours / años)
	AgeRange = {
		Bebe = { 0, 3 },
		Nino = { 6, 12 },
		Adolescente = { 13, 17 },
		AdultoJoven = { 18, 22 },
		Adulto = { 23, 64 }, -- (justo después de la etapa anterior: antes saltaba de 22 a 30)
		Mayor = { 65, 90 },
	},
}

-- Cómo es el cuerpo en cada etapa (tamaño del personaje, velocidad al andar, altura del salto)
Config.StageBody = {
	Bebe = { Scale = 0.45, WalkSpeed = 8, JumpHeight = 1.5 },
	Nino = { Scale = 0.65, WalkSpeed = 14, JumpHeight = 6 },
	Adolescente = { Scale = 0.85, WalkSpeed = 16, JumpHeight = 7.2 },
	AdultoJoven = { Scale = 1, WalkSpeed = 16, JumpHeight = 7.2 },
	Adulto = { Scale = 1, WalkSpeed = 16, JumpHeight = 7.2 },
	Mayor = { Scale = 1, WalkSpeed = 13, JumpHeight = 5 },
}

-- Aspecto por defecto del protagonista (AvatarService): sudadera negra con capucha gris abierta,
-- camiseta blanca, pantalón cargo negro, zapatillas blancas, mochila negra, colgante con chapa
-- y pelo castaño despeinado. Cada jugador puede cambiar a su avatar de Roblox en el Menú.
-- Si subes una cara o ropa a Roblox (Creator Hub), pon aquí su ID (0 = no se usa):
Config.DefaultLook = {
	Enabled = true,
	Skin = Color3.fromRGB(234, 190, 150),
	Hair = Color3.fromRGB(74, 46, 30),
	HairOld = Color3.fromRGB(196, 196, 200), -- de mayor, pelo canoso
	Hoodie = Color3.fromRGB(26, 26, 30),
	HoodLining = Color3.fromRGB(150, 152, 158),
	Tee = Color3.fromRGB(236, 236, 236),
	Pants = Color3.fromRGB(34, 36, 42),
	Shoes = Color3.fromRGB(245, 245, 245),
	Backpack = Color3.fromRGB(22, 22, 26),
	Metal = Color3.fromRGB(200, 204, 210),
	Onesie = Color3.fromRGB(170, 205, 235), -- pelele del bebé
	FaceId = 0,
	ShirtId = 0,
	PantsId = 0,
}

-- Qué etapa mínima hace falta para cada cosa (el servidor lo comprueba siempre)
Config.StageLimits = {
	Work = "Adolescente", -- trabajar (a los adolescentes solo trabajos sencillos)
	ClaimHome = "AdultoJoven", -- tener casa propia
	Travel = "Nino", -- coger el autobús entre zonas
}

-- Tutorial de bebé (fase 2)
Config.Baby = {
	CrawlSpeed = 4, -- velocidad gateando, antes de levantarse
	StepStuds = 4, -- cada cuántos studs andados cuenta un "paso"
	HungryAfterFirstSteps = 35, -- el hambre baja a este valor para enseñar las necesidades
	MaxDistanceFromHome = 6, -- margen fuera de la casa antes de volver a entrar (un bebé no sale solo)
}

---------------------------------------------------------------------
-- MÚSICA Y VOCES de la historia (cinemáticas y momentos clave)
-- La música es original y está en roblox/audio/. Para que suene:
-- 1. En Studio: Window > Asset Manager > Bulk Import (o create.roblox.com > Creations > Audio)
--    y sube los .ogg de roblox/audio/.
-- 2. Copia el ID de cada audio aquí (campo Id), o arrastra los audios a ReplicatedStorage > Musica,
--    o usa scripts/upload-audio.sh --music (escribe los IDs en shared/SoundIds). Si no hay ninguno,
--    ese audio no suena (todo lo demás funciona igual).
---------------------------------------------------------------------
-- Efectos de sonido del juego (client/Controllers/SoundFx.luau). Cada uno puede ser:
--   * "rbxasset://sounds/..." -> sonidos que vienen instalados con Roblox (funcionan siempre)
--   * un número -> ID de un audio de Roblox (de la Caja de herramientas o subido por ti)
--   * 0 -> busca el audio de File (audio/sfx) en shared/SoundIds y en ReplicatedStorage > Sonidos;
--          si no está, no suena (o suena Fallback, si lo tiene: ver abajo)
-- Fallback = { Id, Volume, Pitch }: lo que suena mientras el audio de File no esté subido. Solo sonidos
-- de Roblox retocados con cuidado: collide.wav nunca por debajo de Pitch 0.9 (grave suena a "bomba").
-- También se puede arrastrar un Sound a ReplicatedStorage > Sonidos con el mismo nombre
-- (por ejemplo "Motor"): ese tiene preferencia.
Config.Sounds = {
	-- Volumen del menú (shared/AudioSettings, Controllers/AudioMix): Bus = "Ambience" = control 🌳 Ambiente
	-- (camas de fondo: ciudad, salas, grillos, olas…); sin Bus, 🔔 Efectos (interfaz, acciones, vehículos,
	-- deportes, armas). World = true: sale de una pieza del mundo y va en 3D (InverseTapered: entero hasta
	-- MinDistance y cada vez más flojo hasta MaxDistance). Un motor, un claxon o un disparo, por encima
	-- del ambiente (scripts/test-audiomix comprueba el orden con los niveles por defecto).
	-- Id = número: audio público de la biblioteca de Roblox (Roblox o ProSoundEffects; manda sobre File y
	-- Fallback). Region = { desde, hasta }: solo ese trozo (s); FadeOut: fundido al final. audio/README.md
	Salto = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.25, Pitch = 1.3, World = true, MinDistance = 5, MaxDistance = 45 },
	Aterrizaje = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.7, Pitch = 0.8, World = true, MinDistance = 6, MaxDistance = 60 },
	-- Golpes del personaje: chocar corriendo con una pared, puñetazos… ("tuc" seco) y caer desde alto
	-- ("pof" del cuerpo; sustituye al Aterrizaje cuando la caída es fuerte, no se suman)
	Golpe = { Id = 0, File = "golpe_choque", Volume = 0.55, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.3, Pitch = 1.15 }, World = true, MinDistance = 6, MaxDistance = 70 },
	GolpeCaida = { Id = 0, File = "golpe_caida", Volume = 0.7, Pitch = 1, Fallback = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.6, Pitch = 0.9 }, World = true, MinDistance = 8, MaxDistance = 90 },
	Chapuzon = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.7, Pitch = 1, World = true, MinDistance = 8, MaxDistance = 90 },
	-- Fútbol de verdad (Controllers/FootballClient): golpeo, poste y silbato
	-- (Id = 0 + File: el nuestro de audio/sfx cuando esté subido; mientras, su Fallback de siempre)
	FutbolChute = { Id = 9119327232, File = "balon_patada", Volume = 0.4, Pitch = 1.05, Category = "Mundo", Vary = 0.06, Cooldown = 0.05, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.55, Pitch = 0.8 }, World = true, MinDistance = 8, MaxDistance = 110 },
	FutbolPoste = { Id = 9116764099, File = "aro_rebote", Volume = 0.45, Pitch = 0.85, Category = "Mundo", Fallback = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.6, Pitch = 0.45 }, World = true, MinDistance = 8, MaxDistance = 110 },
	FutbolSilbato = { Id = 9117261163, File = "silbato", Volume = 0.3, Pitch = 1, Category = "Mundo", Vary = 0.02, Cooldown = 0.3, Fallback = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.4, Pitch = 2.3 }, World = true, MinDistance = 25, MaxDistance = 220 },
	-- Gol: el silbato, la red y la grada (capas; sin audio subido suena solo lo que haya)
	FutbolGol = { Id = 0, Category = "Mundo", Duck = 0.55, DuckHold = 2, Layers = { { Name = "SilbatoGol", Delay = 0.35 }, { Name = "RedSwish", Pitch = 0.75, Volume = 0.8 }, { Name = "Ovacion", Delay = 0.05 } } },
	-- El pitido largo del gol (silbato de bolita, al aire libre)
	SilbatoGol = { Id = 9125965988, Volume = 0.4, Pitch = 1, Category = "Mundo", Vary = 0.02, Cooldown = 1 },
	Ovacion = { Id = 9120974911, File = "estadio_ovacion", Volume = 0.6, Pitch = 1, Category = "Mundo", Vary = 0.03, Cooldown = 2 },
	-- Baloncesto, tenis/pádel, vóley y gimnasio
	BalonBote = { Id = 9113329573, File = "balon_bote", Volume = 0.45, Pitch = 1, Category = "Mundo", Vary = 0.07, Cooldown = 0.06, World = true, MinDistance = 6, MaxDistance = 80 },
	AroRebote = { Id = 9116764099, File = "aro_rebote", Volume = 0.5, Pitch = 1, Category = "Mundo", Vary = 0.05, Cooldown = 0.08, World = true, MinDistance = 8, MaxDistance = 90 },
	RedSwish = { Id = 9113342890, Region = { 0.03, 0.62 }, FadeOut = 0.12, File = "red_swish", Volume = 2.5, Pitch = 1, Category = "Mundo", Vary = 0.05, Cooldown = 0.2, World = true, MinDistance = 6, MaxDistance = 70 },
	Canasta = { Id = 0, Category = "Mundo", Layers = { { Name = "RedSwish" }, { Name = "Ovacion", Delay = 0.15, Volume = 0.55 } } },
	RaquetaGolpe = { Id = 9119985541, Region = { 1.29, 1.75 }, FadeOut = 0.1, File = "raqueta_golpe", Volume = 0.45, Pitch = 1, Category = "Mundo", Vary = 0.07, Cooldown = 0.05, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.3, Pitch = 1.8 }, World = true, MinDistance = 8, MaxDistance = 100 },
	VoleyGolpe = { Id = 9113330443, File = "balon_bote", Volume = 0.55, Pitch = 1.08, Category = "Mundo", Vary = 0.07, Cooldown = 0.05, World = true, MinDistance = 8, MaxDistance = 100 },
	Punto = { Id = 0, Category = "Mundo", Layers = { { Name = "Ovacion", Volume = 0.4 } } },
	PesasGolpe = { Id = 9113271308, File = "pesas_golpe", Volume = 1.3, Pitch = 1, Category = "Mundo", Vary = 0.06, Cooldown = 0.15, World = true, MinDistance = 5, MaxDistance = 50 },
	Trepar = { Id = "rbxasset://sounds/action_get_up.mp3", Volume = 0.6, Pitch = 1.1, World = true, MinDistance = 4, MaxDistance = 40 },
	-- Interfaz (2D). Los nuestros (audio/sfx: ui_*, notificacion…) mandan en cuanto estén subidos;
	-- mientras, el Fallback (el sonido de Roblox de siempre)
	Clic = { Id = 15675059323, File = "ui_toque", Volume = 0.3, Pitch = 1, Category = "UI", Vary = 0.04, Fallback = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.3, Pitch = 1 } },
	Aviso = { Id = 17208361335, File = "notificacion", Volume = 0.25, Pitch = 1, Category = "UI", Vary = 0.01, Cooldown = 0.15, Fallback = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 1.2 } },
	Error = { Id = 17208353912, File = "error_suave", Volume = 0.26, Pitch = 1, Category = "UI", Vary = 0.02, Cooldown = 0.25, Fallback = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 0.6 } },
	-- Menú de comandos: moverse, aceptar, volver y abrir un submenú
	MenuMover = { Id = 17208339919, File = "ui_seleccion", Volume = 0.9, Pitch = 1, Category = "UI", Vary = 0.03, Fallback = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.22, Pitch = 1.45 } },
	MenuOk = { Id = 17208396156, File = "ui_toque", Volume = 0.45, Pitch = 1, Category = "UI", Vary = 0.02, Fallback = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.3, Pitch = 1.6 } },
	MenuAtras = { Id = 17208186900, File = "ui_cerrar", Volume = 0.7, Pitch = 1, Category = "UI", Vary = 0.03, Fallback = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.28, Pitch = 0.75 } },
	MenuAbrir = { Id = 17208405682, File = "ui_abrir", Volume = 0.8, Pitch = 1, Category = "UI", Vary = 0.03, Fallback = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.2, Pitch = 1.8 } },
	Seleccion = { Id = 17208339919, File = "ui_seleccion", Volume = 1, Pitch = 1, Category = "UI", Vary = 0.03, Cooldown = 0.04 }, -- barra rápida
	MovilAbrir = { Id = 17208408337, File = "movil_abrir", Volume = 0.6, Pitch = 1, Category = "UI", Vary = 0.02, Cooldown = 0.3 },
	-- Recompensas y momentos (2D). Sin su audio subido NO suenan: mejor nada que un pitido
	Dinero = { Id = 17208380755, File = "dinero", Volume = 0.75, Pitch = 1, Category = "Recompensa", Vary = 0.03, Cooldown = 0.15 }, -- «ka-ching» al cobrar
	Pago = { Id = 9113728756, File = "caja_registradora", Volume = 0.45, Pitch = 1, Category = "Recompensa", Vary = 0.02, Cooldown = 0.3 }, -- pagar: pitido del lector y el cajón
	Xp = { Id = 17208319162, File = "xp", Volume = 0.5, Pitch = 1, Category = "Recompensa", Vary = 0.04, Cooldown = 0.6 },
	SubirNivel = { Id = 1846170664, File = "nivel_sube", Volume = 0.55, Pitch = 1, Category = "Momento", Vary = 0, Cooldown = 2, Duck = 0.4, DuckHold = 2.4 },
	MisionEmpieza = { Id = 15675085146, File = "mision_empieza", Volume = 1, Pitch = 1, Category = "Momento", Vary = 0, Cooldown = 2, Duck = 0.6, DuckHold = 1.2 },
	MisionCompleta = { Id = 1846284687, File = "mision_completa", Volume = 0.54, Pitch = 1, Category = "Momento", Vary = 0, Cooldown = 2, Duck = 0.45, DuckHold = 2.4 },
	Logro = { Id = 15675043410, File = "logro", Volume = 0.55, Pitch = 1, Category = "Momento", Vary = 0, Cooldown = 1.5, Duck = 0.5, DuckHold = 1.8 },
	Descubrimiento = { Id = 9119447936, File = "descubrimiento_fx", Volume = 3, Pitch = 1, Category = "Momento", Vary = 0, Cooldown = 3, Duck = 0.65, DuckHold = 2 },
	Tension = { Id = 9125404320, File = "tension_golpe", Volume = 0.45, Pitch = 1, Category = "Momento", Vary = 0.02, Cooldown = 6 },
	-- Coger algo (3D, en ti)
	Coger = { Id = 17208323435, File = "coger_objeto", Volume = 0.55, Pitch = 1, Category = "Mundo", Vary = 0.08, Cooldown = 0.12, World = true, MinDistance = 4, MaxDistance = 40 },
	-- Choques de vehículos (SoundFx.crash): flojo o fuerte según la velocidad
	ChoqueLeve = { Id = 0, File = "choque_leve", Volume = 0.55, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.25, Pitch = 1.2 }, World = true, MinDistance = 10, MaxDistance = 140 },
	ChoqueFuerte = { Id = 0, File = "choque_fuerte", Volume = 0.75, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.35, Pitch = 1 }, World = true, MinDistance = 15, MaxDistance = 220 },
	Arranque = { Id = "rbxasset://sounds/switch.wav", Volume = 0.5, Pitch = 0.7, World = true, MinDistance = 6, MaxDistance = 60 },
	-- Mandos del vehículo (SoundFx: intermitente «tic-tac» suave, freno de mano y el interruptor de las luces)
	Intermitente = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.12, Pitch = 1.7, World = true, MinDistance = 3, MaxDistance = 20 },
	FrenoMano = { Id = "rbxasset://sounds/switch.wav", Volume = 0.35, Pitch = 0.55, World = true, MinDistance = 3, MaxDistance = 25 },
	LucesCoche = { Id = "rbxasset://sounds/switch.wav", Volume = 0.3, Pitch = 1.25, World = true, MinDistance = 3, MaxDistance = 20 },
	-- Rueda pinchada (Driving): el «flap» de la goma una vez por vuelta
	PinchazoFlap = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.3, Pitch = 0.4, World = true, MinDistance = 6, MaxDistance = 60 },
	-- Armas (shared/Weapons: Sound.Shot). Los disparos son nuestros (audio/sfx/disparo_*); hasta que se
	-- suban suena el Fallback. Para otro, pon un Sound con ese nombre en ReplicatedStorage > Sonidos.
	DisparoPistola = { Id = 0, File = "disparo_pistola", Volume = 0.9, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.7, Pitch = 1.9 }, World = true, MinDistance = 25, MaxDistance = 450 },
	DisparoRevolver = { Id = 0, File = "disparo_revolver", Volume = 0.95, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.75, Pitch = 1.4 }, World = true, MinDistance = 25, MaxDistance = 450 },
	DisparoEscopeta = { Id = 0, File = "disparo_escopeta", Volume = 0.95, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.75, Pitch = 1 }, World = true, MinDistance = 30, MaxDistance = 450 },
	DisparoSubfusil = { Id = 0, File = "disparo_subfusil", Volume = 0.75, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.6, Pitch = 2.2 }, World = true, MinDistance = 25, MaxDistance = 450 },
	DisparoFusil = { Id = 0, File = "disparo_fusil", Volume = 0.95, Pitch = 1, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.75, Pitch = 1.7 }, World = true, MinDistance = 30, MaxDistance = 450 },
	DisparoFrancotirador = { Id = 0, File = "disparo_fusil", Volume = 1, Pitch = 0.9, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.75, Pitch = 1.1 }, World = true, MinDistance = 35, MaxDistance = 450 }, -- (el del fusil, más lento)
	DisparoTaser = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 2.5, World = true, MinDistance = 6, MaxDistance = 60 },
	DisparoAgua = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.3, Pitch = 2, World = true, MinDistance = 5, MaxDistance = 40 },
	DisparoPaintball = { Id = "rbxasset://sounds/paintball.wav", Volume = 0.6, Pitch = 1, World = true, MinDistance = 8, MaxDistance = 90 },
	EcoDisparo = { Id = 0, File = "disparo_eco", Volume = 0.45, Pitch = 1, World = true, MinDistance = 40, MaxDistance = 450 }, -- cola / eco del disparo (sin subir: no suena)
	ArmaSeco = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.5, Pitch = 0.7, World = true, MinDistance = 3, MaxDistance = 25 }, -- sin balas
	CargadorFuera = { Id = "rbxasset://sounds/switch.wav", Volume = 0.5, Pitch = 1.3, World = true, MinDistance = 3, MaxDistance = 25 },
	CargadorDentro = { Id = "rbxasset://sounds/switch.wav", Volume = 0.6, Pitch = 0.9, World = true, MinDistance = 3, MaxDistance = 25 },
	Corredera = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.6, Pitch = 0.5, World = true, MinDistance = 3, MaxDistance = 25 },
	Casquillo = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.12, Pitch = 3.5, World = true, MinDistance = 2, MaxDistance = 20 },
	Rebote = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.35, Pitch = 2.5, World = true, MinDistance = 5, MaxDistance = 60 },
	ImpactoBala = { Id = "rbxasset://sounds/collide.wav", Volume = 0.35, Pitch = 2.6, World = true, MinDistance = 5, MaxDistance = 80 },
	-- Muebles de las casas y edificios (InteractClient)
	Interruptor = { Id = "rbxasset://sounds/switch.wav", Volume = 0.35, Pitch = 1.4, World = true, MinDistance = 4, MaxDistance = 30 },
	Puerta = { Id = 9120839870, Region = { 0.55, 2.3 }, FadeOut = 0.2, File = "puerta_madera", Volume = 2, Pitch = 1, Category = "Mundo", Vary = 0.06, Cooldown = 0.2, Fallback = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.4, Pitch = 0.55 }, World = true, MinDistance = 8, MaxDistance = 70 },
	Nevera = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.35, Pitch = 0.8, World = true, MinDistance = 4, MaxDistance = 30 },
	Agua = { Id = "rbxasset://sounds/action_swim.mp3", Volume = 0.25, Pitch = 1.6, World = true, MinDistance = 4, MaxDistance = 30 },
	Piano = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 1, World = true, MinDistance = 8, MaxDistance = 80 },
	Tecla = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.12, Pitch = 1.8, World = true, MinDistance = 3, MaxDistance = 25 },
	Tele = { Id = 0, File = "tele", Volume = 0.3, Pitch = 1, World = true, MinDistance = 6, MaxDistance = 45 }, -- tele encendida (bucle)
	-- Estos no vienen con Roblox: son nuestros, de audio/sfx (File = nombre del archivo sin .ogg).
	-- Con Id = 0 se usa el ID de SoundIds (scripts/upload-audio.sh) o el Sound con ese nombre en
	-- ReplicatedStorage > Sonidos. Ver audio/README.md.
	Motor = { Id = 0, File = "motor", Volume = 0.8, Pitch = 1, World = true, MinDistance = 10, MaxDistance = 110 }, -- en bucle mientras conduces un coche o una moto
	Helicoptero = { Id = 0, File = "motor", Volume = 0.55, Pitch = 0.42, World = true, MinDistance = 25, MaxDistance = 420 }, -- rotor de los helicópteros (Controllers/Helicopters): el motor, muy grave
	Claxon = { Id = 9113013987, File = "claxon", Volume = 2, Pitch = 1, World = true, MinDistance = 18, MaxDistance = 240 }, -- tecla H en coche o moto
	Timbre = { Id = 9125390528, Region = { 0, 2.3 }, FadeOut = 0.3, File = "timbre", Volume = 1.8, Pitch = 1, World = true, MinDistance = 6, MaxDistance = 60 }, -- tecla H en bici o patinete
	Multitud = { Id = 9112767169, File = "multitud", Volume = 0.6, Pitch = 1, Bus = "Ambience" }, -- murmullo de gente en el centro
	-- Metro (MetroTrains): gong de megafonía, pitido de cierre de puertas, el traqueteo del tren en
	-- marcha, el frenazo y el ambiente del andén
	MetroGong = { Id = 9114132738, Region = { 0, 3.5 }, FadeOut = 0.4, Volume = 0.8, Pitch = 1 },
	MetroPuertas = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 1.9, World = true, MinDistance = 6, MaxDistance = 60 },
	MetroTren = { Id = 0, File = "metro_tren", Volume = 0.4, Pitch = 1 }, -- en bucle mientras vas en el tren
	MetroFreno = { Id = 0, File = "metro_freno", Volume = 0.5, Pitch = 1, Layers = { { Name = "BocinaTren", Volume = 0.8 } } },
	BocinaTren = { Id = 9120247994, Volume = 1, Pitch = 1, Category = "Mundo", Vary = 0.02, Cooldown = 4 }, -- el tren avisa al llegar
	-- Aeropuerto (Flights): «ding-dong» de megafonía antes de cada aviso
	AvisoAeropuerto = { Id = 9114132512, Region = { 0, 3.2 }, FadeOut = 0.4, Volume = 0.9, Pitch = 1, Vary = 0, Cooldown = 1 },
	MetroAnden = { Id = 0, File = "metro_anden", Volume = 0.25, Pitch = 1, Bus = "Ambience" }, -- en bucle en los andenes (gente, anuncios de fondo)
	-- Ascensor (LiftRide): "ding" al llegar a la planta
	Ascensor = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 1.4, World = true, MinDistance = 5, MaxDistance = 40 },
	-- Ambiente por tipo de lugar (StoryAudio, Config.Audio.Ambience). Los Amb* son nuestros (audio/sfx/amb_*).
	-- Mientras no estén subidos, cada capa usa la siguiente opción de su lista, que es un audio ya subido
	-- (multitud, viento…). El volumen de las capas lo pone Config.Audio.Ambience (aquí no cuenta).
	AmbSala = { Id = 0, File = "amb_sala", Bus = "Ambience" }, -- aire de una sala cerrada (base de los interiores)
	AmbCasa = { Id = 0, File = "amb_casa", Bus = "Ambience" }, -- nevera, la calle por la ventana, crujidos
	AmbColegio = { Id = 0, File = "amb_colegio", Bus = "Ambience" }, -- niños en el pasillo, pasos, puertas
	AmbUniversidad = { Id = 0, File = "amb_universidad", Bus = "Ambience" }, -- estudiantes, vestíbulo, máquina expendedora
	AmbHospital = { Id = 0, File = "amb_hospital", Bus = "Ambience" }, -- ventilación, murmullo, camilla que pasa
	AmbCalle = { Id = 0, File = "amb_calle", Bus = "Ambience" }, -- tráfico lejano y gente a lo lejos
	AmbAire = { Id = 0, File = "viento", Muffle = true, Bus = "Ambience" }, -- (ya subido) el viento, apagado: aire de fondo
	-- Golpes sueltos del ambiente (sonidos de Roblox: suenan siempre)
	Reloj = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.05, Pitch = 1.7, Bus = "Ambience" }, -- tic-tac de la casa
	Monitor = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.035, Pitch = 2.3, Bus = "Ambience" }, -- pitido del monitor del hospital
	-- Mundo de noche y en la costa (Controllers/GameSfx, grupo Ambience; sin subir, no suenan)
	Grillos = { Id = 9112762281, File = "grillos", Volume = 0.35, Pitch = 1, Bus = "Ambience" },
	Olas = { Id = 9119677145, File = "olas", Volume = 0.25, Pitch = 1, Bus = "Ambience" },
	-- Grada en bucle mientras juegas un partido o una carrera (GameSfx, atributo InSport; grupo Ambience)
	PublicoEstadio = { Id = 9119562817, Volume = 0.24, Pitch = 1, Bus = "Ambience" },
	-- Vehículos sin motor (SoundFx.vehicleSpeed): en bucle, suben con la velocidad. Region = el trozo
	-- constante de la grabación (en s); el bucle se queda dentro
	BiciCadena = { Id = 9113438203, Region = { 2, 9 }, Volume = 3.5, Pitch = 1, World = true, MinDistance = 4, MaxDistance = 30 }, -- piñón libre y cadena
	PatineteZumbido = { Id = 9116980359, Region = { 0.6, 3.2 }, Volume = 0.1, Pitch = 1, World = true, MinDistance = 4, MaxDistance = 35 }, -- motor eléctrico
	MonopatinRodar = { Id = 9125955674, Region = { 2, 22 }, Volume = 0.15, Pitch = 1, World = true, MinDistance = 4, MaxDistance = 40 }, -- ruedas en el asfalto
	-- Coches: chirrido de ruedas (bucle, SoundFx.skid), cambio de marcha y puertas al subir y bajar
	Derrape = { Id = 9120399191, Region = { 1.5, 4.8 }, Volume = 1.4, Pitch = 1, World = true, MinDistance = 12, MaxDistance = 160 },
	CambioMarcha = { Id = 9113018515, Region = { 0.33, 0.95 }, FadeOut = 0.08, Volume = 2.5, Pitch = 1, Category = "Mundo", Vary = 0.05, Cooldown = 0.4, World = true, MinDistance = 6, MaxDistance = 40 },
	PuertaCoche = { Id = 9113205539, Volume = 1.8, Pitch = 1, Category = "Mundo", Vary = 0.04, Cooldown = 0.5, World = true, MinDistance = 6, MaxDistance = 50 }, -- se cierra al subir
	PuertaCocheAbrir = { Id = 9113205239, Volume = 2.5, Pitch = 1, Category = "Mundo", Vary = 0.04, Cooldown = 0.5, World = true, MinDistance = 6, MaxDistance = 50 }, -- se abre al bajar
	ClaxonPesado = { Id = 9114661361, Volume = 0.85, Pitch = 1, World = true, MinDistance = 25, MaxDistance = 320 }, -- autobús, camión, bomberos y barcos
	-- Comer y beber (SoundFx.gesture: mochila, nevera, carteles «Comer»/«Beber»)
	Comer = { Id = 9113138343, Volume = 1.2, Pitch = 1, Category = "Mundo", Vary = 0.06, Cooldown = 0.8, World = true, MinDistance = 3, MaxDistance = 30 },
	Beber = { Id = 9114686828, Region = { 0.2, 1.2 }, FadeOut = 0.1, Volume = 0.6, Pitch = 1, Category = "Mundo", Vary = 0.05, Cooldown = 0.8, World = true, MinDistance = 3, MaxDistance = 30 },
	-- Cocinar (sartén que chisporrotea) y fabricar (martillo)
	Cocinar = { Id = 9114542867, Region = { 2, 5 }, FadeOut = 0.6, Volume = 1, Pitch = 1, Category = "Mundo", Vary = 0.04, Cooldown = 2, World = true, MinDistance = 5, MaxDistance = 40 },
	Fabricar = { Id = 9114756156, Region = { 0, 0.9 }, FadeOut = 0.15, Volume = 0.85, Pitch = 1, Category = "Mundo", Vary = 0.05, Cooldown = 0.5, World = true, MinDistance = 5, MaxDistance = 40 },
	-- Deportes: pistola de salida (atletismo, RaceClient)
	PistolaSalida = { Id = 9114700217, Region = { 0, 1.8 }, Volume = 0.65, Pitch = 1, Category = "Mundo", Vary = 0.02, Cooldown = 1 },
	-- K.O. (CombatController): el golpe a la barbilla y el cuerpo que cae
	KO = { Id = 9113798204, Volume = 0.36, Pitch = 1, Category = "Mundo", Vary = 0.03, Cooldown = 1, Layers = { { Name = "KOCaida", Delay = 0.35 } } },
	KOCaida = { Id = 9113469292, Region = { 0.2, 1 }, FadeOut = 0.15, Volume = 0.45, Pitch = 1, Category = "Mundo", Vary = 0.04 },
	-- Nadar (Swimming): una brazada en la superficie
	Brazada = { Id = 9120589166, Region = { 3.82, 4.5 }, FadeOut = 0.15, Volume = 0.8, Pitch = 1, Category = "Mundo", Vary = 0.08, Cooldown = 0.3, World = true, MinDistance = 5, MaxDistance = 50 },
	-- Combate aéreo y espacial (Controllers/AirCombatClient, docs/combate-aereo.md): todo va al control
	-- 🔔 Efectos y, lo que sale de una nave, en 3D (World). Sin ids nuevos sin comprobar: sonidos de Roblox
	-- (rbxasset) retocados y los nuestros ya subidos (motor, choques: shared/SoundIds).
	NaveMotor = { Id = 0, File = "motor", Volume = 0.4, Pitch = 1.8, World = true, MinDistance = 14, MaxDistance = 260 }, -- zumbido del motor (bucle; sube con el gas y el turbo)
	NaveLaser = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.22, Pitch = 2.8, Vary = 0.08, Cooldown = 0.05, World = true, MinDistance = 10, MaxDistance = 260 },
	NaveLaserEnemigo = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.18, Pitch = 1.9, Vary = 0.06, Cooldown = 0.08, World = true, MinDistance = 10, MaxDistance = 260 },
	NaveMisil = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.6, Pitch = 0.55, Cooldown = 0.2, World = true, MinDistance = 12, MaxDistance = 300 },
	NaveFijando = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.16, Pitch = 1.3, Vary = 0, Cooldown = 0.18 }, -- pitido mientras fija
	NaveFijado = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.3, Pitch = 1.6, Vary = 0, Cooldown = 0.5, Layers = { { Name = "NaveFijando", Delay = 0.08, Pitch = 1.25 } } }, -- ¡fijado! (doble pitido)
	NaveEstallido = { Id = 0, File = "choque_fuerte", Volume = 0.6, Pitch = 1.15, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.35, Pitch = 0.95 }, Category = "Mundo", Cooldown = 0.08, World = true, MinDistance = 20, MaxDistance = 400, Layers = { { Name = "NaveChispas", Delay = 0.05 } } }, -- explosión de un derribo (un dron, un caza, una torreta o tu nave)
	NaveChispas = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.2, Pitch = 3.2, Vary = 0.15, World = true, MinDistance = 10, MaxDistance = 200 },
	NaveEscudo = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 0.7, Vary = 0.05, Cooldown = 0.1 }, -- te dan y lo para el escudo
	NaveCasco = { Id = 0, File = "choque_leve", Volume = 0.5, Pitch = 1.2, Fallback = { Id = "rbxasset://sounds/collide.wav", Volume = 0.3, Pitch = 1.3 }, Cooldown = 0.1 }, -- te dan en el casco
	NaveImpacto = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.25, Pitch = 1.6, Cooldown = 0.06 }, -- le has dado (marca de impacto)
}

-- Mezcla de los efectos (SoundFx). Volumen por categoría de Config.Sounds (Category): la interfaz por
-- debajo de las recompensas, todo por debajo de las voces (los audios ya van igualados de sonoridad:
-- scripts/audio/sfx_feedback.py). MaxActive = efectos sueltos a la vez (móvil); los del mundo se
-- quedan fuera antes. La música se agacha (Duck) con las fanfarrias grandes y vuelve en DuckRelease s.
Config.SfxMix = {
	Categories = { UI = 0.8, Recompensa = 1, Momento = 1, Mundo = 1 },
	MaxActive = 18,
	DuckAttack = 0.08,
	DuckRelease = 0.9,
	-- (el volumen del menú, de 0 a 10 por control, está en shared/AudioSettings y Controllers/AudioMix)
}

-- Voces de la gente de la ciudad (voz sintetizada de Roblox, como la de la historia)
Config.StreetVoices = {
	Enabled = true,
	Volume = 0.5, -- (× Config.Audio.Voices.Volume y su ganancia; suena desde la persona, más bajo de lejos)
	Distance = 26, -- a cuántos studs tiene que estar alguien para que diga una frase suelta (Every)
	-- Proximidad: todo NPC que habla se oye desde su cabeza. Hasta Near studs, claro; luego cada vez
	-- menos (Mid: la mitad) hasta Far, donde ya no se oye (y más lejos ni se pide la voz)
	Near = 10,
	Mid = 25,
	Far = 55,
	Every = { 25, 50 }, -- cada cuántos segundos dice algo alguien cercano (poco: las voces tienen límite por minuto)
	Lines = {
		"¡Buenos días!", "Qué buen día hace hoy.", "¿Has visto el partido de ayer?", "Hoy hay mucho lío.",
		"Uf, qué calor.", "¡Hola, vecino!", "Luego te llamo.", "Me voy a tomar un café.",
		"¿Sabes dónde está la estación?", "Mañana es fiesta.", "¡Qué bonito está el mar!",
	},
	Emotes = { Saludar = "¡Hola!", Reir = "¡Ja, ja, ja!", Animar = "¡Vamos!", Senalar = "¡Mira allí!", NoSe = "Ni idea…" },
	-- La voz de cada persona de la calle: una de estas, según su edad (atributo Age). Pocas a propósito:
	-- así las frases que se repiten no se vuelven a pedir a Roblox (límite por minuto). Pitch en semitonos.
	Presets = {
		Adulto = {
			{ VoiceId = "101", Pitch = -1, Speed = 1 },
			{ VoiceId = "101", Pitch = 1, Speed = 1.06 },
			{ VoiceId = "102", Pitch = 0, Speed = 1.02 },
			{ VoiceId = "102", Pitch = 1.5, Speed = 1.06 },
		},
		Nino = { { VoiceId = "101", Pitch = 6, Speed = 1.08 }, { VoiceId = "102", Pitch = 5, Speed = 1.1 } },
		Adolescente = { { VoiceId = "101", Pitch = 2.5, Speed = 1.04 }, { VoiceId = "102", Pitch = 2.5, Speed = 1.05 } },
		Mayor = { { VoiceId = "101", Pitch = -3, Speed = 0.86 }, { VoiceId = "102", Pitch = -2.5, Speed = 0.88 } },
	},
}

Config.Audio = {
	Music = {
		-- Si una pieza no carga en el juego (audio privado, de otro dueño o en revisión), StoryAudio prueba
		-- sus otras copias (SoundIds, ReplicatedStorage > Musica) y después su Fallback: nunca silencio
		-- mientras quede alguna pieza que cargue. Comprobar los audios de verdad:
		-- bash scripts/cloud-test.sh -v audio
		Nacimiento = { Id = 99685990275611, File = "nacimiento.ogg", Volume = 0.4, Looped = true, Fallback = "Intima" },
		TemaValmar = { Id = 71915200549382, File = "tema_valmar.ogg", Volume = 0.45, Looped = true, Fallback = "Descubrimiento" },
		PasanLosAnos = { Id = 136669358482377, File = "pasan_los_anos.ogg", Volume = 0.5, Looped = false, Fallback = "Resolucion" },
		VidaAdulta = { Id = 90317690788724, File = "vida_adulta.ogg", Volume = 0.4, Looped = true, Fallback = "Descubrimiento" },
		-- Música por intensidad (Intensity, abajo). Id: pista con licencia de la biblioteca de Roblox (APM
		-- Music, pública para cualquier experiencia); si no carga, la nuestra (File en shared/SoundIds).
		-- Con Id = 0: se busca File en shared/SoundIds
		-- (scripts/upload-audio.sh --music) y en ReplicatedStorage > Musica. Si aún no está subida,
		-- suena su Fallback (otra pieza de esta lista) o, sin Fallback, nada.
		Descubrimiento = { Id = 1836329853, File = "descubrimiento.ogg", Volume = 0.43, Looped = true, Fallback = "TemaValmar" },
		Intima = { Id = 9046644321, File = "intima.ogg", Volume = 0.89, Looped = true, Fallback = "Nacimiento" },
		Tension = { Id = 1841589066, File = "tension.ogg", Volume = 0.7, Looped = true }, -- (ninguna de antes sirve: sin ella, solo ambiente)
		Resolucion = { Id = 9047298617, File = "resolucion.ogg", Volume = 0.63, Looped = false, Fallback = "VidaAdulta" },
		TemaFinal = { Id = 9047308022, File = "tema_final.ogg", Volume = 0.67, Looped = false, Fallback = "TemaValmar" },
	},
	-- Intensidad de la música en una escena (StoryAudio.setIntensity; pista Music = { Intensity = … }).
	-- Cue = pieza de Music (nil = sin música: queda el ambiente); Scale = volumen; Fade = segundos del cruce.
	Intensity = {
		Nada = { Fade = 3 }, -- momento normal: poca o ninguna música
		Descubrimiento = { Cue = "Descubrimiento", Scale = 0.9, Fade = 2.5 },
		Intima = { Cue = "Intima", Scale = 1, Fade = 3 },
		Tension = { Cue = "Tension", Scale = 1, Fade = 1.2 },
		Resolucion = { Cue = "Resolucion", Scale = 1, Fade = 1.5 },
		Tema = { Cue = "TemaFinal", Scale = 1, Fade = 2 }, -- final de capítulo
	},
	-- Ambiente por tipo de lugar (StoryAudio.setAmbience; si ninguna escena lo pide, según dónde estás).
	-- Cada tipo tiene capas en bucle (Layers) y golpes sueltos (Spots), todo en el grupo Ambience.
	--   Layers: { Sounds = opciones, Volume, Hours = { desde, hasta }?, OffHours = volumen fuera de hora }
	--     opciones: nombres de Config.Sounds por preferencia; suena la primera que tenga audio. Una opción
	--     puede ser { Sound = "Multitud", Scale = 0.6, Pitch = 1.15 } (volumen y tono propios).
	--   Spots: { Sound, Every = { min, max } segundos, Volume = multiplicador, Burst = { min, max }?, Gap?,
	--            Alternate = tono de un golpe de cada dos (tic-tac)?, Hours? }
	-- Nunca silencio absoluto: todos los tipos (menos el metro, que ya tiene su andén) tienen una capa base.
	Ambience = {
		Fade = 2.5, -- segundos del fundido al cambiar de ambiente
		Every = 1, -- cada cuánto se mira dónde estás
		Kinds = {
			Calle = {
				Layers = { { Sounds = { "AmbCalle", { Sound = "Multitud", Scale = 0.5 } }, Volume = 0.12, OffHours = 0.6, Hours = { 7, 23 } } },
			},
			Parque = { -- (pájaros y viento ya los pone Weather)
				Layers = { { Sounds = { "AmbCalle", { Sound = "Multitud", Scale = 0.3 } }, Volume = 0.05 } },
			},
			Casa = {
				Layers = { { Sounds = { "AmbCasa", "AmbSala", { Sound = "AmbAire", Scale = 1.4 } }, Volume = 0.13 } },
				Spots = { { Sound = "Reloj", Every = { 1, 1 }, Volume = 1, Alternate = 0.85 } }, -- tic-tac
			},
			Colegio = {
				Layers = {
					{ Sounds = { "AmbSala", "AmbAire" }, Volume = 0.07 },
					{ Sounds = { "AmbColegio", { Sound = "Multitud", Scale = 0.8, Pitch = 1.2 } }, Volume = 0.15, Hours = { 8, 18 }, OffHours = 0 },
				},
				Spots = { { Sound = "Puerta", Every = { 12, 30 }, Volume = 0.35 } },
			},
			Universidad = {
				Layers = {
					{ Sounds = { "AmbSala", "AmbAire" }, Volume = 0.07 },
					{ Sounds = { "AmbUniversidad", { Sound = "Multitud", Scale = 0.7 } }, Volume = 0.14, Hours = { 8, 21 }, OffHours = 0.15 },
				},
				Spots = { { Sound = "Puerta", Every = { 15, 35 }, Volume = 0.3 } },
			},
			Hospital = {
				Layers = { { Sounds = { "AmbHospital", "AmbSala", { Sound = "AmbAire", Scale = 1.4 } }, Volume = 0.14 } },
				Spots = { { Sound = "Monitor", Every = { 1.05, 1.05 }, Volume = 1 }, { Sound = "Puerta", Every = { 18, 40 }, Volume = 0.25 } },
			},
			Oficina = {
				Layers = { { Sounds = { "AmbSala", "AmbAire" }, Volume = 0.08 } },
				Spots = { { Sound = "Tecla", Every = { 4, 10 }, Volume = 0.5, Burst = { 3, 9 }, Gap = 0.13 } },
			},
			Tienda = {
				Layers = { { Sounds = { "AmbSala", "AmbAire" }, Volume = 0.07 }, { Sounds = { { Sound = "Multitud", Scale = 0.45 } }, Volume = 0.25 } },
			},
			Sala = { -- museo, teatro, juzgado, ayuntamiento: grande y callada
				Layers = { { Sounds = { "AmbSala", "AmbAire" }, Volume = 0.08 }, { Sounds = { { Sound = "Multitud", Scale = 0.2 } }, Volume = 0.25 } },
				Spots = { { Sound = "Puerta", Every = { 25, 50 }, Volume = 0.2 } },
			},
			Estacion = {
				Layers = { { Sounds = { { Sound = "Multitud", Scale = 0.7 } }, Volume = 0.25 }, { Sounds = { "AmbCalle" }, Volume = 0.05 } },
				Spots = { { Sound = "MetroGong", Every = { 45, 90 }, Volume = 0.5 } },
			},
			Nave = { -- naves, talleres, cuartel
				Layers = { { Sounds = { "AmbSala", "AmbAire" }, Volume = 0.1 } },
			},
			Ocio = {
				Layers = { { Sounds = { "AmbSala", "AmbAire" }, Volume = 0.06 }, { Sounds = { { Sound = "Tele", Scale = 0.8 }, { Sound = "Multitud", Scale = 0.5 } }, Volume = 0.25 } },
			},
			Portal = { -- escaleras y pasillos de los edificios
				Layers = { { Sounds = { "AmbSala", "AmbAire" }, Volume = 0.07 } },
				Spots = { { Sound = "Puerta", Every = { 15, 40 }, Volume = 0.2 } },
			},
			Interior = { -- cualquier otra sala
				Layers = { { Sounds = { "AmbSala", "AmbAire" }, Volume = 0.08 } },
			},
			Metro = { Layers = {} }, -- (el andén y el tren ya suenan: MetroTrains)
		},
		-- Otros nombres que se aceptan en setAmbience (sin mayúsculas ni tildes)
		Aliases = {
			escuela = "Colegio", instituto = "Colegio", aula = "Colegio", hogar = "Casa", piso = "Casa",
			exterior = "Calle", ciudad = "Calle", facultad = "Universidad", campus = "Universidad",
			clinica = "Hospital", centrosalud = "Hospital", centrodesalud = "Hospital", tienda = "Tienda", comercio = "Tienda",
			naturaleza = "Parque", playa = "Parque",
		},
		-- Salas de los edificios (modelo "Interior_<Nombre>" en workspace.Interiores) -> tipo
		Rooms = {
			Casa = "Casa", Villa = "Casa", Piso = "Casa", Dorm = "Casa",
			Aula = "Universidad", -- (si la puerta está junto a un colegio, Colegio: Places)
			Oficina = "Oficina", OficinaLobby = "Oficina", Hacienda = "Oficina",
			Local = "Tienda", CentroComercial = "Tienda",
			Museo = "Sala", Teatro = "Sala", Juzgado = "Sala", Ayuntamiento = "Sala",
			Estacion = "Estacion", Nave = "Nave", Taller = "Nave", Cuartel = "Nave", Ocio = "Ocio",
			Portal = "Portal", Tower = "Portal",
		},
		-- Lugares del mapa (ReplicatedStorage.MapLandmarks): a menos de Radius studs, ese tipo.
		-- Outdoor = el tipo si estás al aire libre (sin techo encima; sin Outdoor, el mismo). Dentro de un
		-- edificio, el lugar de su puerta manda en aulas, pasillos y oficinas (un aula junto al colegio es
		-- Colegio); las casas, tiendas y demás salas se quedan con su tipo.
		Places = {
			Hospital = { Kind = "Hospital", Radius = 90, Outdoor = "Calle" },
			CentroSalud = { Kind = "Hospital", Radius = 45, Outdoor = "Calle" },
			Colegio = { Kind = "Colegio", Radius = 90 },
			Facultad = { Kind = "Universidad", Radius = 140 },
			Parque = { Kind = "Parque", Radius = 80, Outdoor = "Parque" },
			Playa = { Kind = "Parque", Radius = 160, Outdoor = "Parque" },
			Granja = { Kind = "Parque", Radius = 160, Outdoor = "Parque" },
			Camping = { Kind = "Parque", Radius = 120, Outdoor = "Parque" },
		},
	},
	Stings = {
		Momento = { Id = 107278309519549, File = "sting_momento.ogg", Volume = 0.55 },
		Capitulo = { Id = 99594760388393, File = "sting_capitulo.ogg", Volume = 0.55 },
		PrimerosPasos = { Id = 129269798599195, File = "sting_primeros_pasos.ogg", Volume = 0.6 },
	},
	AmbientVolume = 0.3, -- música de fondo de un capítulo (más baja que en las cinemáticas; con 0.2 casi no se oía en el móvil)
	BootDelay = 2, -- segundos desde que arranca el cliente hasta que empieza la música de fondo
	DuckVolume = 0.3, -- la música baja a este porcentaje mientras alguien habla
	AmbienceDuck = 0.5, -- y el ambiente (grupo Ambience), a este
	Voices = {
		-- Voz sintetizada de Roblox (AudioTextToSpeech) para los personajes: cada uno con la suya
		-- (shared/LifeStory/CastVoices: VoiceId, tono y velocidad por personaje). Si no está disponible o
		-- se pasa del límite de Roblox, se ven los subtítulos igual y se vuelve a probar al rato.
		-- Roblox tiene dos voces en español: "101" (hombre) y "102" (mujer). Pitch va en SEMITONOS
		-- (-12 … 12; 0 = la voz tal cual) y Speed es la velocidad (0,5 … 2).
		TextToSpeech = true,
		-- Volumen: la voz sintetizada sale mucho más baja que la música («se escuchan muy bajo», v108).
		-- Volume va al máximo de AudioTextToSpeech (3) y Gain (AudioFader, 0 … 3) la sube otra vez; el
		-- limitador (LimitDb, -12 … 0 dB) evita que sature. El menú 🗣️ Voces multiplica Volume.
		Volume = 3,
		Gain = 2,
		LimitDb = -1,
		AutoLocalize = false, -- false: se dice en español, como el subtítulo (true = Roblox lo traduce)
		-- Límite de Roblox: 1 + 6 × jugadores frases nuevas por minuto en TODO el juego (y 4 por
		-- segundo por jugador). Las frases ya dichas se repiten sin gastar (Cache).
		PerMinute = 10, -- frases nuevas de la historia por minuto que pide cada jugador como mucho
		StreetReserve = 3, -- la gente de la calle solo habla si en el último minuto se han pedido menos
		Cache = 80, -- frases ya generadas que se guardan para repetirlas
		-- A tiempo («se escuchan atrasadas al mensaje», v108): generar una frase tarda. Se generan por
		-- adelantado las que vienen (Prefetch = cuántas en cola); la caja de la conversación espera a la
		-- voz como mucho WaitText s antes de escribir el texto, y si el audio llega más de MaxDelay s tarde,
		-- esa frase no se dice.
		Prefetch = 6,
		WaitText = 0.6,
		MaxDelay = 1.5,
		Lookahead = 10, -- s: en escenas y cinemáticas, se adelantan las frases de los próximos 10 s
		-- Perfiles de voz (los que no son un personaje del reparto; los personajes, en CastVoices)
		Speakers = {
			Narrador = { VoiceId = "101", Pitch = -1, Speed = 0.92 },
			Abu = { VoiceId = "102", Pitch = -2.5, Speed = 0.86 },
			Familia = { VoiceId = "102", Pitch = 0.5, Speed = 1.04 },
			Profe = { VoiceId = "102", Pitch = 0.5, Speed = 0.96 },
			Nino = { VoiceId = "102", Pitch = 5, Speed = 1.08 },
			Rectora = { VoiceId = "102", Pitch = -1.5, Speed = 0.9 },
			Hombre = { VoiceId = "101", Pitch = 0, Speed = 1 },
			Mujer = { VoiceId = "102", Pitch = 0, Speed = 1 },
			Megafonia = { VoiceId = "102", Pitch = 0.5, Speed = 0.95 }, -- avisos del metro y del aeropuerto
		},
		-- Voces grabadas (opcional): clave del texto = ID del audio. Si existe, se usa en vez de la sintetizada.
		Lines = {
			-- ["DLG.ABU.NACER.01"] = 0,
		},
	},
}

---------------------------------------------------------------------
-- Necesidades (hambre y energía, de 0 a 100)
---------------------------------------------------------------------
Config.Needs = {
	Max = 100,
	HungerPerMinute = 2.5, -- cuánto baja el hambre por minuto real
	EnergyPerMinute = 1.2, -- cuánto baja la energía por minuto real
	LowThreshold = 15, -- por debajo de esto el personaje camina más lento
	CantWorkThreshold = 5, -- por debajo de esto no se puede trabajar
}
Config.WalkSpeed = 16
Config.TiredWalkSpeed = 10

---------------------------------------------------------------------
-- Trabajos
-- Cada trabajo es un circuito: recoger algo en un punto (Pickup)
-- y llevarlo a otro (Dropoff). Los puntos se marcan con tags en el mapa.
-- PayText (opcional): lo que pone el tablón de lo que se cobra. Los oficios con su propio sistema
-- no pagan Pay por entrega, así que lo dicen con su texto. Sin PayText, el tablón pone "Pay/entrega".
---------------------------------------------------------------------
Config.Jobs = {
	Barista = {
		DisplayName = "Barista",
		PayText = "10 € + 2 € por paso", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Cafetería Central",
		Pay = 25,
		EnergyCost = 2,
		PickupText = "Prepara un café en la cafetera",
		DropoffText = "Sirve el café en la mesa marcada",
		CarryColor = Color3.fromRGB(110, 70, 40),
		CarrySize = Vector3.new(0.8, 1, 0.8),
	},
	Reponedor = {
		DisplayName = "Reponedor/a",
		Place = "Supermercado",
		Pay = 30,
		EnergyCost = 3,
		PickupText = "Coge una caja del almacén",
		DropoffText = "Coloca la caja en la estantería marcada",
		CarryColor = Color3.fromRGB(190, 150, 90),
		CarrySize = Vector3.new(2, 1.6, 1.6),
	},
	Basurero = {
		DisplayName = "Basurero/a",
		PayText = "7 € por papelera", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Punto Limpio",
		Pay = 45,
		EnergyCost = 4,
		PickupText = "Recoge la bolsa de basura marcada",
		DropoffText = "Tira la bolsa en el contenedor del Punto Limpio",
		CarryColor = Color3.fromRGB(30, 30, 30),
		CarrySize = Vector3.new(1.6, 2, 1.6),
	},
	-- Médico/a: consultas del hospital (MedicalService: su propio sistema, no este circuito)
	Medico = {
		DisplayName = "Médico/a",
		PayText = "hasta 30 € por paciente", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Hospital",
		Pay = 30,
		EnergyCost = 3,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Policia = {
		DisplayName = "Policía",
		PayText = "15–30 € por aviso + distancia", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Comisaría",
		Pay = 30,
		EnergyCost = 3,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	-- Instituciones del Estado (Ciudad de la Justicia; carreras y rangos en shared/Institutions)
	Juez = {
		DisplayName = "Juez/a",
		Place = "Palacio de Justicia",
		Pay = 30,
		EnergyCost = 2,
		PickupText = "Recoge un expediente del archivo",
		DropoffText = "Estudia el expediente en el estrado",
		CarryColor = Color3.fromRGB(220, 190, 110),
		CarrySize = Vector3.new(1.2, 0.4, 1.6),
	},
	Funcionario = {
		DisplayName = "Funcionario/a de prisiones",
		Place = "Centro Penitenciario",
		Pay = 30,
		EnergyCost = 3,
		PickupText = "Recoge las llaves y el parte en la garita",
		DropoffText = "Haz la ronda: revisa el punto marcado",
		CarryColor = Color3.fromRGB(200, 200, 210),
		CarrySize = Vector3.new(0.8, 0.3, 0.8),
	},
	Militar = {
		DisplayName = "Militar",
		Place = "Cuartel del Ejército",
		Pay = 32,
		EnergyCost = 4,
		PickupText = "Recoge tu equipo en la armería",
		DropoffText = "Cubre el puesto marcado (guardia o instrucción)",
		CarryColor = Color3.fromRGB(78, 92, 56),
		CarrySize = Vector3.new(1.6, 1.2, 0.8),
	},
	Hacienda = {
		DisplayName = "Agente de Hacienda",
		Place = "Agencia Tributaria",
		Pay = 28,
		EnergyCost = 2,
		PickupText = "Recoge un expediente fiscal del archivo",
		DropoffText = "Tramítalo en una mesa de la oficina",
		CarryColor = Color3.fromRGB(240, 240, 230),
		CarrySize = Vector3.new(1.2, 0.4, 1.6),
	},
	Bombero = {
		DisplayName = "Bombero/a",
		PayText = "15–45 € por aviso + distancia", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Parque de bomberos",
		Pay = 30,
		EnergyCost = 4,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Taquillero = {
		DisplayName = "Taquillero/a",
		PayText = "6 € + 2 € por entrada", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Cine",
		Pay = 12,
		EnergyCost = 2,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Revisor = {
		DisplayName = "Revisor/a",
		PayText = "2 € por billete, 6 € por multa", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Metro",
		Pay = 4,
		EnergyCost = 1,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Armero = {
		DisplayName = "Armero/a",
		Place = "Armeria",
		Pay = 14,
		EnergyCost = 1,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Pescador = {
		DisplayName = "Pescador/a",
		PayText = "según lo que pesques", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Puerto",
		Pay = 10,
		EnergyCost = 1,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	-- Monitor/a de gimnasio (GymService: corrige la postura de quien entrena)
	MonitorGimnasio = {
		DisplayName = "Monitor/a de gimnasio",
		Place = "Gimnasio",
		Pay = 14,
		EnergyCost = 2,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Recepcionista = {
		DisplayName = "Recepcionista",
		PayText = "6–8 € por huésped", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Hotel",
		Pay = 10,
		EnergyCost = 2,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Repartidor = {
		DisplayName = "Repartidor/a",
		PayText = "10 € + distancia", -- lo que se ve en el tablón (lo que se cobra de verdad)
		Place = "Correos",
		Pay = 70,
		EnergyCost = 5,
		PickupText = "Recoge un paquete en Correos",
		DropoffText = "Entrega el paquete en el buzón marcado",
		CarryColor = Color3.fromRGB(170, 120, 70),
		CarrySize = Vector3.new(1.8, 1.4, 1.8),
	},
	-- Oficios con su propio sistema que no tienen tablón aquí (supermercado y autobús). Están para
	-- que el HUD los reconozca. Pay es solo lo básico por tarea (el HUD aún lo enseña con Format.money)
	Cajero = {
		DisplayName = "Cajero/a",
		PayText = "6 € por cliente + 1 € por producto",
		Place = "Supermercado",
		Pay = 6,
		EnergyCost = 1,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Charcutero = {
		DisplayName = "Charcutero/a",
		PayText = "8 € por pedido",
		Place = "Supermercado",
		Pay = 8,
		EnergyCost = 1,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
	Conductor = {
		DisplayName = "Conductor/a de autobús",
		PayText = "12 € por parada + 2 € por pasajero",
		Place = "Cocheras de autobuses",
		Pay = 12,
		EnergyCost = 1,
		PickupText = "",
		DropoffText = "",
		CarryColor = Color3.fromRGB(250, 250, 250),
		CarrySize = Vector3.new(1, 1, 1),
	},
}
Config.TaskReachDistance = 7 -- a cuántos studs del objetivo cuenta como "llegado"

---------------------------------------------------------------------
-- Comida (se compra en los mostradores con ProximityPrompt)
---------------------------------------------------------------------
Config.Foods = {
	Cafe = { Name = "Café", Price = 8, Hunger = 5, Energy = 20 },
	Croissant = { Name = "Croissant", Price = 12, Hunger = 25, Energy = 0 },
	Fruta = { Name = "Fruta", Price = 6, Hunger = 15, Energy = 0 },
	Bocadillo = { Name = "Bocadillo", Price = 15, Hunger = 35, Energy = 0 },
	Hamburguesa = { Name = "Hamburguesa", Price = 25, Hunger = 55, Energy = 0 },
	Menu = { Name = "Menú completo", Price = 45, Hunger = 100, Energy = 10 },
	-- La nevera de tu casa es gratis, pero tiene tiempo de espera
	Nevera = { Name = "Algo de la nevera", Price = 0, Hunger = 20, Energy = 0, Cooldown = 3 }, -- (en casa se come sin límite)
}

Config.SleepSeconds = 4 -- lo que dura la animación de dormir
-- Dormir en una cama (SleepService): desde SleepNightFrom (o de madrugada) la noche pasa y te
-- despiertas a las WakeClockTime del día siguiente. La hora es la misma para todo el servidor:
-- la noche solo pasa si duermen todos los jugadores (o estás solo). Mientras, esperas SleepWaitSeconds.
Config.SleepNightFrom = 18 -- a partir de esta hora, dormir es «la noche»
Config.WakeClockTime = 8.5 -- 8:30 de la mañana
Config.SleepWaitSeconds = 12 -- cuánto esperas en la cama a que se acuesten los demás

---------------------------------------------------------------------
-- Casas: cada jugador reclama una parcela gratis y puede mejorarla.
-- El nivel de casa se GUARDA entre partidas.
---------------------------------------------------------------------
Config.HouseTiers = {
	{ Name = "Estudio", Price = 0, Size = Vector3.new(24, 12, 20), Color = Color3.fromRGB(214, 196, 168) },
	{ Name = "Casa familiar", Price = 5000, Size = Vector3.new(32, 14, 28), Color = Color3.fromRGB(180, 205, 225) },
	{ Name = "Chalet", Price = 25000, Size = Vector3.new(40, 16, 34), Color = Color3.fromRGB(235, 235, 230) },
	{ Name = "Mansión", Price = 100000, Size = Vector3.new(46, 22, 44), Color = Color3.fromRGB(245, 240, 225) },
}

---------------------------------------------------------------------
-- MONETIZACIÓN (Robux)
-- 1. Publica el juego en Roblox.
-- 2. En create.roblox.com > tu experiencia > Monetización crea los
--    Game Passes y Developer Products.
-- 3. Copia aquí sus IDs. Mientras el ID sea 0, el artículo aparece
--    en la tienda como "Próximamente" y no se puede comprar.
---------------------------------------------------------------------
-- Sin pases VIP ni paquetes de dinero: pagar da VALOR (cosméticos del pase de temporada), nunca
-- más sueldo, más dinero ni ventajas. El pase de temporada tiene su propio Game Pass en
-- Shared/BattlePass. Aquí quedan las listas (vacías) por si algún día hay otro artículo cosmético.
Config.GamePasses = {} :: { [string]: { Id: number, Name: string, Description: string, Robux: number } }
Config.DevProducts = {} :: { { Key: string, Id: number, Name: string, Cash: number, Robux: number } }

return Config
