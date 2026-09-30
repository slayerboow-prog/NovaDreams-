-- BattlePassConfig: TODOS los números del pase de temporada en un solo sitio (solo datos).
-- Cada temporada está en su propio archivo (Season1, Season2…); aquí va lo común: topes de XP,
-- de dónde sale la XP, límites de los remotos, fichas y compra.
--
-- PRECIO: no está en el código. El pase es un Game Pass de Roblox: el precio en Robux se pone en el
-- Creator Dashboard (create.roblox.com > tu experiencia > Monetización > Pases) y se puede cambiar
-- ahí cuando quieras sin tocar nada de esto. Aquí solo va su ID (GamePassId de cada temporada).
-- Ver docs/pase-de-temporada.md, «Pasos para el dueño».

local Season1 = require(script.Parent.Season1)

local BattlePassConfig = {}

BattlePassConfig.ProductType = "GamePass"
BattlePassConfig.PriceConfiguredExternally = true
-- Solo orientativo (para el documento): el precio real se decide en el Creator Dashboard
BattlePassConfig.SuggestedPrice = "unos 4,99 € de valor (entre 399 y 499 Robux)"

-- Temporadas en orden. La actual es la última que ya ha empezado (StartsAt <= ahora); si ninguna ha
-- empezado todavía, la primera (se enseña como «Próximamente»).
BattlePassConfig.Seasons = { Season1 }

-- Tras acabar una temporada, durante estos días aún se puede reclamar lo alcanzado (sin ganar XP).
BattlePassConfig.ClaimGraceDays = 7

-- Al comprar el premium, las recompensas premium de los niveles ya alcanzados se entregan solas
-- (si es false, quedan «Disponibles» para reclamar a mano).
BattlePassConfig.AutoClaimRetroactiveOnPurchase = true
-- Al cambiar de temporada, lo alcanzado y sin reclamar se entrega solo (nada se pierde).
BattlePassConfig.AutoGrantUnclaimedOnArchive = true

-- Si una recompensa ya no existe (se quitó del juego) o no se puede entregar para siempre, se da esto
BattlePassConfig.MissingRewardFallback = { Type = "Money", Amount = 250 }

---------------------------------------------------------------------
-- XP de actividad (BattlePassXPService)
---------------------------------------------------------------------
-- Tope diario de XP que dan las actividades (las misiones van aparte, que ya tienen su límite).
-- Con ~50 minutos al día se llega cerca del tope; más no suma: así no hace falta «farmear».
BattlePassConfig.DailyActivityCap = 1400
-- Multiplicador máximo de un evento (seguridad: aunque un evento diga más, no pasa de aquí)
BattlePassConfig.MaxEventMultiplier = 1.5

-- Fuentes de XP: eventos del juego (StoryEvents) que dan XP del pase. Cap = tope diario de la fuente,
-- MinGap = segundos mínimos entre dos eventos que cuentan (anti-spam).
BattlePassConfig.Sources = {
	Trabajo = { Cap = 600, MinGap = 3, Events = { JobTaskDone = 15 } },
	Estudio = { Cap = 300, MinGap = 20, Events = { LessonCompleted = 40, ExamGraded = 60, Studied = 25, PracticeDone = 40, PrisonDegree = 60 } },
	Historia = { Cap = 480, MinGap = 5, Events = { QuestDone = 120 } },
	Encargos = { Cap = 300, MinGap = 20, Events = { ErrandDone = 60 } },
	Transporte = { Cap = 200, MinGap = 30, Events = { RodeMetro = 15, RodeTrain = 20, BusRide = 15, Flew = 40, Traveled = 10 } },
	Conducir = { Cap = 150, MinGap = 10, Events = { VehicleTrip = 25 }, PerKm = true }, -- 25 XP por km
	Explorar = { Cap = 400, MinGap = 0, Events = { ZoneEntered = 100 }, OnlyFirst = true }, -- solo la primera vez en cada barrio
	Ocio = { Cap = 200, MinGap = 8, Events = { WatchedMovie = 30, ArcadePlayed = 8, CaughtFish = 8, GymSet = 5, FarmHarvest = 10, BuskPlayed = 10 } },
	Compras = { Cap = 60, MinGap = 10, Events = { BoughtItem = 5, SupermarketPurchase = 10 } },
	Hitos = { Cap = 400, MinGap = 0, Events = { Promoted = 150, LicenseEarned = 150, HomeClaimed = 100, BusinessOpened = 100 } },
}

-- XP por tarea según el oficio (JobTaskDone). Las tareas grandes (un incendio, un paciente) valen más
-- que las pequeñas (cobrar a un cliente). Sin entrada: la de Sources.Trabajo.
BattlePassConfig.JobXp = {
	Bombero = 40, Policia = 30, Medico = 25, Juez = 30, Hacienda = 25, Repartidor = 20, Basurero = 15,
	Pescador = 20, Agricultor = 20, Recepcionista = 15, Barista = 12, Camarero = 12, Barman = 12,
	Taquillero = 10, Revisor = 10, Armero = 10, MonitorGimnasio = 10, Empresario = 8, Empleado = 10,
	Cajero = 8, Charcutero = 10, Conductor = 8,
}

---------------------------------------------------------------------
-- Fichas de temporada (SeasonTokens): solo cosméticos, cantidad controlada
---------------------------------------------------------------------
BattlePassConfig.Tokens = {
	-- Pasado el nivel 50, cada tanto de XP de más da 1 ficha (hasta MaxFromOverflow por temporada)
	OverflowXpPerToken = 4000,
	MaxFromOverflow = 10,
}

---------------------------------------------------------------------
-- Remotos (anti-spam)
---------------------------------------------------------------------
BattlePassConfig.RemoteName = "BattlePass"
BattlePassConfig.RateLimit = {
	Burst = 8, -- peticiones seguidas como mucho…
	Window = 4, -- …en estos segundos
	MinGap = 0.15, -- y al menos esto entre dos
}
-- Como mucho un estado completo al cliente cada tanto (los cambios se juntan)
BattlePassConfig.PushEvery = 0.5

-- Reintentos al preguntar a Roblox si tiene el Game Pass (UserOwnsGamePassAsync)
BattlePassConfig.OwnershipRetries = 3

---------------------------------------------------------------------
-- Rarezas (para la interfaz)
---------------------------------------------------------------------
BattlePassConfig.Rarities = {
	Comun = { Name = "Común", Color = Color3.fromRGB(190, 195, 205), Order = 1 },
	Rara = { Name = "Rara", Color = Color3.fromRGB(80, 160, 255), Order = 2 },
	Epica = { Name = "Épica", Color = Color3.fromRGB(180, 100, 255), Order = 3 },
	Legendaria = { Name = "Legendaria", Color = Color3.fromRGB(255, 196, 64), Order = 4 },
}

-- Nombre de cada tipo de recompensa (para la interfaz)
BattlePassConfig.TypeNames = {
	Money = "Dinero", CharacterXp = "Experiencia", Tickets = "Tickets", Tokens = "Fichas",
	Vehicle = "Vehículo", VehicleSkin = "Vehículo exclusivo", Boat = "Barco", Wearable = "Accesorio",
	Outfit = "Conjunto de ropa", Emote = "Gesto", Title = "Título", Nameplate = "Placa de nombre",
	HomeTheme = "Tema de vivienda", Decor = "Decoración", PhoneTheme = "Tema del teléfono",
	HudSkin = "Estilo de la interfaz", Perk = "Comodidad", Story = "Recuerdo", Bundle = "Conjunto",
}

-- Telemetría interna mínima (contadores). true = además se manda a AnalyticsService de Roblox.
BattlePassConfig.Telemetry = { UseAnalyticsService = false }

return BattlePassConfig
