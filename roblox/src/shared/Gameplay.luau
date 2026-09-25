-- Gameplay: números y textos de los sistemas de juego nuevos
-- (vehículos, carnet de conducir, recreativos y restaurante).
-- Va aparte de Config para que cada parte del juego tenga su sitio y sea fácil de equilibrar.

local Gameplay = {}

---------------------------------------------------------------------
-- Vehículos
-- Speed = velocidad al montar (andando son 16). Stage = etapa mínima. License = carnet necesario.
-- Se compran desde el botón "🚲 Vehículos" y se sacan en cualquier sitio.
-- Las bicis y monopatines públicos (junto a las paradas de autobús) son gratis.
---------------------------------------------------------------------
Gameplay.Vehicles = {
	Monopatin = { Name = "Monopatín", Icon = "🛹", Price = 150, Speed = 26, Stage = "Adolescente", Order = 1 },
	Patinete = { Name = "Patinete eléctrico", Icon = "🛴", Price = 250, Speed = 30, Stage = "Adolescente", Order = 2 },
	Bici = { Name = "Bicicleta", Icon = "🚲", Price = 350, Speed = 34, Stage = "Adolescente", Order = 3 },
	Moto = { Name = "Moto", Icon = "🛵", Price = 3500, Speed = 58, Stage = "AdultoJoven", License = "A", Order = 4 },
	Coche = { Name = "Coche", Icon = "🚗", Price = 9000, Speed = 72, Stage = "AdultoJoven", License = "B", Order = 5 },
	-- El autobús no se compra: lo conduce quien trabaja de conductor (BusService)
	Autobus = { Name = "Autobús", Icon = "🚌", Price = 0, Speed = 48, Stage = "AdultoJoven", License = "B", Order = 9, Hidden = true },
}
Gameplay.RentalVehicles = { "Bici", "Monopatin", "Patinete" } -- los que se cogen gratis en las estaciones públicas

-- Cómo se conduce cada vehículo (studs/s y radianes/s). Lo usa client/Controllers/Driving.luau.
--   Accel: aceleración · Brake: frenada · Reverse: velocidad marcha atrás · Turn: giro máximo
--   Lean: se inclina en las curvas (dos ruedas) · Standing: se va de pie (monopatín, patinete)
Gameplay.Driving = {
	Monopatin = { Accel = 12, Brake = 30, Reverse = 6, Turn = 2.4, Lean = 10, Standing = true },
	Patinete = { Accel = 16, Brake = 34, Reverse = 5, Turn = 2.5, Lean = 12, Standing = true },
	Bici = { Accel = 14, Brake = 36, Reverse = 5, Turn = 2.5, Lean = 16 },
	Moto = { Accel = 26, Brake = 50, Reverse = 6, Turn = 2.2, Lean = 22 },
	Coche = { Accel = 22, Brake = 55, Reverse = 18, Turn = 1.7, Lean = 0 },
	Autobus = { Accel = 11, Brake = 34, Reverse = 6, Turn = 1.1, Lean = 0 },
}

-- Combustible y cuentakilómetros (VehicleService gasta; se reposta en las gasolineras)
--   Tank: depósito (litros, o % de batería) · Per1000: lo que se gasta cada 1000 studs
--   Price: € por litro (o por % de batería). Bici y monopatín no gastan nada.
Gameplay.Fuel = {
	Kinds = {
		Coche = { Tank = 50, Per1000 = 2.2, Type = "Gasolina", Unit = "L", Price = 1.5 },
		Moto = { Tank = 12, Per1000 = 0.7, Type = "Gasolina", Unit = "L", Price = 1.5 },
		Patinete = { Tank = 100, Per1000 = 10, Type = "Bateria", Unit = "%", Price = 0.1 },
	},
	KmPerStud = 0.00028, -- 1 stud ≈ 28 cm (y así km/h ≈ studs/s)
	Reserve = 0.15, -- por debajo de esto se enciende la luz de reserva
}

-- Autobús urbano (línea L1 circular por todos los barrios)
Gameplay.Bus = {
	Fare = 2, -- billete (lo cobra la ciudad o el conductor jugador)
	DriverPerStop = 12, -- el conductor cobra por cada parada bien hecha
	DriverPerPassenger = 2, -- y por cada pasajero que sube (jugadores y NPC)
	NpcBuses = 3, -- autobuses automáticos en la línea
	Speed = 36, -- velocidad de los autobuses automáticos (studs/s)
	StopSeconds = 7, -- lo que esperan en cada parada con las puertas abiertas
	StopRadius = 20, -- a qué distancia de la parada hay que parar
}

---------------------------------------------------------------------
-- Carnet de conducir (autoescuela)
---------------------------------------------------------------------
Gameplay.Licenses = {
	A = { Name = "Carnet de moto (A)", Price = 250, Vehicle = "Moto" },
	B = { Name = "Carnet de coche (B)", Price = 400, Vehicle = "Coche" },
}
Gameplay.LicenseStage = "AdultoJoven"
Gameplay.Theory = { Questions = 5, ToPass = 4 }
Gameplay.Practical = { Checkpoints = 5, Seconds = 100, ReachDistance = 16 }

-- Preguntas del examen teórico: la primera respuesta es la correcta (se barajan al preguntar)
Gameplay.TheoryQuestions = {
	{ "El semáforo está en ámbar fijo. ¿Qué haces?", { "Paro si puedo hacerlo con seguridad", "Acelero para pasar", "Toco el claxon" } },
	{ "¿Qué significa una señal de STOP?", { "Detenerse por completo y ceder el paso", "Reducir un poco la velocidad", "Prohibido aparcar" } },
	{ "¿Cuál es la velocidad máxima normal en ciudad?", { "50 km/h", "80 km/h", "100 km/h" } },
	{ "Un peatón está cruzando por un paso de cebra. ¿Qué haces?", { "Paro y le dejo pasar", "Paso rápido por detrás", "Le pito para que corra" } },
	{ "¿Es obligatorio el cinturón en los asientos de atrás?", { "Sí, siempre", "Solo en autopista", "No" } },
	{ "¿Cuándo hay que usar el intermitente?", { "Antes de girar o cambiar de carril", "Solo de noche", "Solo en rotondas" } },
	{ "En una rotonda, ¿quién tiene preferencia?", { "Los que ya circulan por la rotonda", "Los que entran", "El vehículo más grande" } },
	{ "¿Se puede usar el móvil en la mano mientras conduces?", { "No, nunca", "Sí, en los semáforos", "Sí, si vas despacio" } },
	{ "¿Qué debes llevar en la moto siempre?", { "Casco abrochado", "Gafas de sol", "Guantes de lana" } },
	{ "Oyes la sirena de una ambulancia detrás. ¿Qué haces?", { "Me aparto con cuidado para dejarla pasar", "Acelero para no molestar", "Freno en seco en medio del carril" } },
	{ "¿Qué significa una línea continua en el centro de la calzada?", { "Prohibido cruzarla para adelantar", "Se puede adelantar con cuidado", "Zona de aparcamiento" } },
	{ "Si has bebido alcohol…", { "No conduzco", "Conduzco despacio", "Abro la ventanilla y conduzco" } },
}

---------------------------------------------------------------------
-- Recreativos: juegos de bolas, puntuaciones, tickets y premios
---------------------------------------------------------------------
Gameplay.Arcade = {
	Stage = "Nino", -- desde niño se puede jugar
	Games = {
		Bolas = {
			Name = "Lanzabolas",
			Price = 5,
			Balls = 6,
			MaxScore = 600, -- 6 bolas × 100
			TicketsPer = 10, -- 1 ticket por cada 10 puntos
			MinSeconds = 5, -- una partida no puede durar menos (anti-trampas)
		},
		Canasta = {
			Name = "Canastas",
			Price = 5,
			Seconds = 20,
			MaxScore = 50, -- canastas como máximo en 20 s
			TicketsPer = 1, -- 1 ticket por canasta
			MinSeconds = 19,
		},
	},
	TopSize = 5, -- récords que se ven en el marcador
}

-- Puntos de una bola del Lanzabolas según la fuerza del lanzamiento (0 a 1).
-- Lo usan el cliente (para enseñarlo) y el servidor (para dar los tickets).
function Gameplay.bolasScore(power: number): number
	if power >= 0.86 and power <= 0.94 then
		return 100
	elseif power >= 0.74 and power < 0.86 then
		return 50
	elseif power >= 0.6 and power < 0.74 then
		return 30
	elseif power > 0.94 then
		return 20 -- demasiado fuerte: rebota
	end
	return 10
end

Gameplay.Prizes = {
	Peluche = { Name = "Osito de peluche", Icon = "🧸", Tickets = 40, Kind = "Collect", Order = 1 },
	Gafas = { Name = "Gafas de sol", Icon = "🕶", Tickets = 80, Kind = "Wear", Order = 2 },
	Gorra = { Name = "Gorra", Icon = "🧢", Tickets = 150, Kind = "Wear", Order = 3 },
	Monopatin = { Name = "Monopatín", Icon = "🛹", Tickets = 300, Kind = "Vehicle", Order = 4 },
	Bici = { Name = "Bicicleta", Icon = "🚲", Tickets = 600, Kind = "Vehicle", Order = 5 },
}

---------------------------------------------------------------------
-- Restaurante: trabajo en pareja (camarero de sala + barman)
-- Si falta uno de los dos jugadores, ese puesto lo hace un NPC.
---------------------------------------------------------------------
Gameplay.Jobs = {
	Camarero = { DisplayName = "Camarero (sala)", Pay = 35 },
	Barman = { DisplayName = "Barman (barra)", Pay = 30 },
}

Gameplay.Restaurant = {
	MaxCustomers = 5, -- clientes sentados a la vez
	SpawnEvery = { 10, 18 }, -- segundos entre clientes nuevos
	Patience = 150, -- segundos que espera un cliente antes de irse enfadado
	EatSeconds = 12,
	SpeakSeconds = 4, -- lo que tarda el cliente en decir lo que quiere
	NpcWaiterSeconds = 6, -- lo que tarda el camarero NPC en tomar nota
	NpcBarmanSeconds = 7, -- lo que tarda el barman NPC en preparar un plato
	MaxTip = 15,
	OrderOptions = 4, -- opciones que ve el camarero
	IngredientOptions = 8, -- ingredientes que ve el barman
}

Gameplay.Ingredients = {
	"Café", "Leche", "Pan", "Tomate", "Aceite", "Jamón", "Naranja", "Lechuga",
	"Carne", "Queso", "Huevo", "Patata", "Chocolate", "Churros", "Cacao", "Azúcar",
}

Gameplay.Menu = {
	{ Id = "CafeLeche", Name = "Café con leche", Ingredients = { "Café", "Leche" } },
	{ Id = "Tostada", Name = "Tostada con tomate", Ingredients = { "Pan", "Tomate", "Aceite" } },
	{ Id = "BocataJamon", Name = "Bocadillo de jamón", Ingredients = { "Pan", "Jamón" } },
	{ Id = "Zumo", Name = "Zumo de naranja", Ingredients = { "Naranja", "Azúcar" } },
	{ Id = "Ensalada", Name = "Ensalada", Ingredients = { "Lechuga", "Tomate", "Aceite" } },
	{ Id = "Hamburguesa", Name = "Hamburguesa", Ingredients = { "Pan", "Carne", "Queso", "Lechuga" } },
	{ Id = "Mixto", Name = "Sándwich mixto", Ingredients = { "Pan", "Jamón", "Queso" } },
	{ Id = "Tortilla", Name = "Tortilla de patatas", Ingredients = { "Huevo", "Patata", "Aceite" } },
	{ Id = "Churros", Name = "Chocolate con churros", Ingredients = { "Chocolate", "Churros" } },
	{ Id = "ColaCao", Name = "Vaso de cacao", Ingredients = { "Leche", "Cacao", "Azúcar" } },
}

---------------------------------------------------------------------
-- Personaje: nivel, experiencia y estadísticas (para lo que viene, también misiones de combate)
-- Cada nivel da puntos para repartir. Vida y estamina se ven en la pantalla.
---------------------------------------------------------------------
Gameplay.Progression = {
	MaxLevel = 100,
	PointsPerLevel = 3,
	MaxStat = 50, -- puntos máximos en una estadística
	-- Experiencia por lo que haces en tu vida (nombres de StoryEvents)
	Xp = {
		JobTaskDone = 12, ArcadePlayed = 6, LicenseEarned = 150, LicenseFailed = 10, PrizeRedeemed = 5,
		Talk = 3, Traveled = 5, VehicleBought = 25, HomeClaimed = 60, BoughtItem = 3, Ate = 1, Slept = 4,
		BabySteps = 20, BabyStood = 20, LookedOutside = 10,
	},
	QuestXp = 60, -- por cada misión completada de la historia
	Stats = {
		{ Id = "Salud", Icon = "❤", Name = "Salud", Text = "+10 de vida máxima por punto" },
		{ Id = "Resistencia", Icon = "🛡", Name = "Resistencia", Text = "+8 de estamina y se recupera antes" },
		{ Id = "Fuerza", Icon = "💪", Name = "Fuerza", Text = "+4% de daño en combate" },
		{ Id = "Destreza", Icon = "🏃", Name = "Destreza", Text = "Corres un 1% más rápido por punto" },
		{ Id = "Suerte", Icon = "🍀", Name = "Suerte", Text = "+2% de propinas, sueldo y tickets" },
	},
	Health = { Base = 100, PerSalud = 10, RegenPerSecond = 1 },
	Stamina = {
		Base = 100, PerResistencia = 8,
		Drain = 20, -- por segundo corriendo
		Regen = 16, -- por segundo descansando (+2% por punto de Resistencia)
		RegenDelay = 1.2, -- segundos sin correr antes de recuperarse
		MinToStart = 15, -- estamina mínima para empezar a correr
		SprintMultiplier = 1.5, PerDestreza = 0.01,
	},
}

-- Experiencia que hace falta para pasar del nivel "level" al siguiente
function Gameplay.xpToNext(level: number): number
	return 100 + (level - 1) * 60
end

function Gameplay.dish(id: string)
	for _, dish in Gameplay.Menu do
		if dish.Id == id then
			return dish
		end
	end
	return nil
end

-- Texto de una comanda: "Bocadillo de jamón y zumo de naranja"
function Gameplay.orderText(items: { string }): string
	local names = {}
	for i, id in items do
		local dish = Gameplay.dish(id)
		local name = if dish then dish.Name else id
		table.insert(names, if i == 1 then name else string.lower(string.sub(name, 1, 1)) .. string.sub(name, 2))
	end
	if #names <= 1 then
		return names[1] or ""
	end
	return table.concat(names, ", ", 1, #names - 1) .. " y " .. names[#names]
end

return Gameplay
