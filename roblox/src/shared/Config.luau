-- Config: TODOS los números del juego en un solo sitio.
-- Si quieres equilibrar la economía (sueldos, precios, etc.) cambia los valores aquí.

local Config = {}

Config.GameName = "Real Life Simulator"

---------------------------------------------------------------------
-- Guardado de datos
---------------------------------------------------------------------
Config.DataStoreName = "RealLifeSim_PlayerData_v1"
Config.AutosaveSeconds = 120
Config.StartingMoney = 500

---------------------------------------------------------------------
-- Ciclo día / noche
---------------------------------------------------------------------
Config.DayLengthMinutes = 20 -- minutos reales que dura un día completo
Config.StartClockTime = 8 -- hora a la que empieza el servidor
Config.LampsOnAt = 18 -- las farolas se encienden a esta hora...
Config.LampsOffAt = 6.5 -- ...y se apagan a esta

---------------------------------------------------------------------
-- Calendario del juego (lo usan GameClock y la historia de vida)
-- El día 1 es lunes del mes 1 del año 1.
---------------------------------------------------------------------
Config.Calendar = {
	DaysPerWeek = 7,
	DaysPerMonth = 28, -- 4 semanas por mes
	MonthsPerYear = 12,
}

---------------------------------------------------------------------
-- Historia de vida (LifeStoryService)
---------------------------------------------------------------------
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
-- 2. Copia el ID de cada audio aquí (campo Id). Mientras sea 0, ese audio no suena
--    (todo lo demás funciona igual). También me los puedes pasar y los pongo yo.
---------------------------------------------------------------------
Config.Audio = {
	Music = {
		Nacimiento = { Id = 0, File = "nacimiento.ogg", Volume = 0.4, Looped = true },
		TemaValmar = { Id = 0, File = "tema_valmar.ogg", Volume = 0.45, Looped = true },
		PasanLosAnos = { Id = 0, File = "pasan_los_anos.ogg", Volume = 0.5, Looped = false },
		VidaAdulta = { Id = 0, File = "vida_adulta.ogg", Volume = 0.4, Looped = true },
	},
	Stings = {
		Momento = { Id = 0, File = "sting_momento.ogg", Volume = 0.55 },
		Capitulo = { Id = 0, File = "sting_capitulo.ogg", Volume = 0.55 },
		PrimerosPasos = { Id = 0, File = "sting_primeros_pasos.ogg", Volume = 0.6 },
	},
	AmbientVolume = 0.2, -- música de fondo de un capítulo (más baja que en las cinemáticas)
	DuckVolume = 0.45, -- la música baja a este porcentaje mientras alguien habla
	Voices = {
		-- Voz sintetizada de Roblox (AudioTextToSpeech) para los personajes, si el motor la tiene.
		-- Si no está disponible, se ven los subtítulos igual.
		TextToSpeech = true,
		Volume = 1,
		-- Cómo suena cada personaje (VoiceId: una de las voces de Roblox; vacío = la voz por defecto)
		Speakers = {
			Abu = { VoiceId = "", Pitch = 0.95, Speed = 0.92 },
			Familia = { VoiceId = "", Pitch = 1.05, Speed = 1 },
			Narrador = { VoiceId = "", Pitch = 1, Speed = 0.9 },
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
---------------------------------------------------------------------
Config.Jobs = {
	Barista = {
		DisplayName = "Barista",
		Place = "Cafetería Central",
		Pay = 25,
		EnergyCost = 2,
		PickupText = "Prepara un café en la cafetera",
		DropoffText = "Sirve el café en la mesa marcada",
		CarryColor = Color3.fromRGB(110, 70, 40),
		CarrySize = Vector3.new(0.8, 1, 0.8),
	},
	Reponedor = {
		DisplayName = "Reponedor",
		Place = "Supermercado",
		Pay = 30,
		EnergyCost = 3,
		PickupText = "Coge una caja del almacén",
		DropoffText = "Coloca la caja en la estantería marcada",
		CarryColor = Color3.fromRGB(190, 150, 90),
		CarrySize = Vector3.new(2, 1.6, 1.6),
	},
	Basurero = {
		DisplayName = "Basurero",
		Place = "Punto Limpio",
		Pay = 45,
		EnergyCost = 4,
		PickupText = "Recoge la bolsa de basura marcada",
		DropoffText = "Tira la bolsa en el contenedor del Punto Limpio",
		CarryColor = Color3.fromRGB(30, 30, 30),
		CarrySize = Vector3.new(1.6, 2, 1.6),
	},
	Repartidor = {
		DisplayName = "Repartidor",
		Place = "Correos",
		Pay = 70,
		EnergyCost = 5,
		PickupText = "Recoge un paquete en Correos",
		DropoffText = "Entrega el paquete en el buzón marcado",
		CarryColor = Color3.fromRGB(170, 120, 70),
		CarrySize = Vector3.new(1.8, 1.4, 1.8),
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
	Nevera = { Name = "Algo de la nevera", Price = 0, Hunger = 20, Energy = 0, Cooldown = 180 },
}

Config.SleepSeconds = 4 -- lo que dura la animación de dormir

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
Config.GamePasses = {
	VIP = {
		Id = 0,
		Name = "VIP",
		Description = "Cobras el DOBLE en todos los trabajos.",
		Robux = 199,
		PayMultiplier = 2,
	},
	Metabolismo = {
		Id = 0,
		Name = "Metabolismo Pro",
		Description = "El hambre y el cansancio bajan a la mitad de velocidad.",
		Robux = 99,
		NeedsMultiplier = 0.5,
	},
}

Config.DevProducts = {
	-- Paquetes de dinero del juego (se pueden comprar muchas veces)
	{ Key = "Cash1", Id = 0, Name = "Bolsa de dinero", Cash = 1000, Robux = 25 },
	{ Key = "Cash2", Id = 0, Name = "Maletín de dinero", Cash = 6000, Robux = 99 },
	{ Key = "Cash3", Id = 0, Name = "Caja fuerte", Cash = 35000, Robux = 399 },
}

return Config
