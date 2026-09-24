-- Config: TODOS los números del juego en un solo sitio.
-- Si quieres equilibrar la economía (sueldos, precios, etc.) cambia los valores aquí.

local Config = {}

Config.GameName = "Nova Life"

---------------------------------------------------------------------
-- Guardado de datos
---------------------------------------------------------------------
Config.DataStoreName = "NovaLife_PlayerData_v1"
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
		Place = "Cafetería Nova",
		Pay = 25,
		EnergyCost = 2,
		PickupText = "Prepara un café en la cafetera",
		DropoffText = "Sirve el café en la mesa marcada",
		CarryColor = Color3.fromRGB(110, 70, 40),
		CarrySize = Vector3.new(0.8, 1, 0.8),
	},
	Reponedor = {
		DisplayName = "Reponedor",
		Place = "Supermercado Nova",
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
		Place = "Correos Nova",
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
