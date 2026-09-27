-- Metro: el metro subterráneo de Valmar (MetroKit construye, MetroService lo mueve, MetroUI lo enseña).
--
-- Dos líneas bajo la ciudad. Cada estación tiene una boca de metro en la calle (Surface) y, debajo,
-- el vestíbulo (billetes y tornos), el andén y los túneles hasta la siguiente. Plaza Mayor es el
-- corazón: allí se cruzan las dos líneas y está la galería comercial subterránea (tiendas,
-- cafetería, escenario para músicos, tablón de encargos y objetos perdidos).

local Metro = {}

export type Station = { Id: string, Name: string, Surface: { number }, Facing: { number }, Hub: boolean? }
export type Line = { Id: string, Name: string, Color: Color3, Y: number, Stations: { string } }

local rgb = Color3.fromRGB

-- Boca de metro: dónde está en la calle (X, Z) y hacia dónde mira su puerta (la calle)
Metro.Stations = {
	Poniente = { Id = "Poniente", Name = "Poniente", Surface = { -1800, 17.5 }, Facing = { 0, -1 } },
	PlazaMayor = { Id = "PlazaMayor", Name = "Plaza Mayor", Surface = { -80, -66 }, Facing = { 1, 0 }, Hub = true },
	Levante = { Id = "Levante", Name = "Levante", Surface = { 1900, 17.5 }, Facing = { 0, -1 } },
	PlayaDorada = { Id = "PlayaDorada", Name = "Playa Dorada", Surface = { 3564, -400 }, Facing = { -1, 0 } },
	Norte = { Id = "Norte", Name = "Norte", Surface = { 17.5, -1800 }, Facing = { -1, 0 } },
	SanRoque = { Id = "SanRoque", Name = "San Roque", Surface = { 17.5, 2000 }, Facing = { -1, 0 } },
	Puerto = { Id = "Puerto", Name = "Puerto", Surface = { 700, 3164 }, Facing = { 0, -1 } },
} :: { [string]: Station }

-- Las líneas van a distinta profundidad para cruzarse sin chocar
Metro.Lines = {
	{ Id = "L1", Name = "Línea 1", Color = rgb(215, 40, 50), Y = -150, Stations = { "Poniente", "PlazaMayor", "Levante", "PlayaDorada" } },
	{ Id = "L2", Name = "Línea 2", Color = rgb(40, 110, 215), Y = -185, Stations = { "Norte", "PlazaMayor", "SanRoque", "Puerto" } },
} :: { Line }
Metro.lineById = {} :: { [string]: Line }
for _, line in Metro.Lines do
	Metro.lineById[line.Id] = line
end

-- Medidas
Metro.PlatformLength = 150
Metro.CarLength = 34
Metro.CarGap = 2
Metro.Cars = 3
Metro.Speed = 90 -- studs/s en el túnel
Metro.Accel = 30
Metro.Dwell = 14 -- segundos con las puertas abiertas en cada estación

-- Billetes (máquinas del vestíbulo)
Metro.TicketItem = "BilleteMetro"
Metro.Tickets = {
	{ Id = "Sencillo", Name = "Billete sencillo", Icon = "🎫", Price = 2, Count = 1 },
	{ Id = "Bono10", Name = "Bonometro (10 viajes)", Icon = "🎟️", Price = 15, Count = 10 },
}

-- Productos de las tiendas del metro (se registran en Items)
Metro.Products = {
	Bocadillo = { Name = "Bocadillo de tortilla", Icon = "🥪", Kind = "Food", Hunger = 32, Energy = 0, Desc = "De la bocatería del metro. Recién hecho." },
	Croqueton = { Name = "Croquetas para llevar", Icon = "🍢", Kind = "Food", Hunger = 22, Energy = 0, Desc = "Un cucurucho de croquetas caseras." },
	CafeAnden = { Name = "Café del andén", Icon = "☕", Kind = "Food", Hunger = 2, Energy = 18, Desc = "Para despertarse entre estación y estación." },
	Churros = { Name = "Churros", Icon = "🥖", Kind = "Food", Hunger = 18, Energy = 6, Desc = "Con azúcar, calentitos." },
	Refresco = { Name = "Refresco", Icon = "🥤", Kind = "Food", Hunger = 2, Energy = 10, Desc = "Bien frío, de la máquina." },
	Chuches = { Name = "Bolsa de chuches", Icon = "🍬", Kind = "Food", Hunger = 6, Energy = 8, Desc = "Ositos, regaliz y nubes." },
	Revista = { Name = "Revista", Icon = "📰", Kind = "Thing", Desc = "Para leer en el metro." },
	Vinilo = { Name = "Disco de vinilo", Icon = "💿", Kind = "Thing", Desc = "De la tienda de discos del metro. Suena a antiguo, y eso mola." },
	Auriculares = { Name = "Auriculares", Icon = "🎧", Kind = "Thing", Desc = "Para ir escuchando música en el metro." },
	Guitarra = { Name = "Guitarra", Icon = "🎸", Kind = "Thing", Desc = "Para tocar en el escenario de la galería del metro y ganar propinas." },
	FotoMaton = { Name = "Tira del fotomatón", Icon = "📸", Kind = "Thing", Desc = "Cuatro fotos seguidas haciendo el tonto en el metro." },
	PaqueteMetro = { Name = "Paquete urgente", Icon = "📦", Kind = "Thing", Desc = "Hay que llevarlo al quiosco de otra estación antes de que se acabe el tiempo." },
	CarteraPerdida = { Name = "Objeto perdido", Icon = "👛", Kind = "Thing", Desc = "Alguien lo ha perdido en el metro. Llévalo a Objetos Perdidos." },
	-- Puestos de la galería y de los vestíbulos
	Donut = { Name = "Dónut glaseado", Icon = "🍩", Kind = "Food", Hunger = 12, Energy = 6, Desc = "Del puesto de dónuts del metro. Pringa los dedos." },
	PizzaCorte = { Name = "Porción de pizza", Icon = "🍕", Kind = "Food", Hunger = 26, Energy = 2, Desc = "Pizza al corte, recién salida del horno." },
	Kebab = { Name = "Kebab", Icon = "🌯", Kind = "Food", Hunger = 34, Energy = 0, Desc = "Enrollado, con salsa de yogur. Para comer de camino." },
	ZumoNaranja = { Name = "Zumo de naranja", Icon = "🧃", Kind = "Food", Hunger = 4, Energy = 12, Desc = "Exprimido al momento en la frutería del metro." },
	Ramo = { Name = "Ramo de flores", Icon = "💐", Kind = "Thing", Desc = "De la floristería del metro. Para regalar (o para ti)." },
	Rosa = { Name = "Rosa roja", Icon = "🌹", Kind = "Thing", Desc = "Una sola rosa, envuelta en papel." },
	Postal = { Name = "Postal de Valmar", Icon = "🖼️", Kind = "Thing", Desc = "Con la Torre Valmar y un atardecer de postal." },
	Llavero = { Name = "Llavero del metro", Icon = "🔑", Kind = "Thing", Desc = "Un trenecito rojo de la Línea 1." },
	Iman = { Name = "Imán de nevera", Icon = "🧲", Kind = "Thing", Desc = "Con el plano del metro de Valmar." },
	Paraguas = { Name = "Paraguas", Icon = "☂️", Kind = "Thing", Desc = "Por si llueve al salir del metro." },
	Tiritas = { Name = "Caja de tiritas", Icon = "🩹", Kind = "Thing", Desc = "De la farmacia de la galería." },
	Panuelos = { Name = "Pañuelos", Icon = "🤧", Kind = "Thing", Desc = "Un paquete de pañuelos de papel." },
	Libro = { Name = "Libro de bolsillo", Icon = "📕", Kind = "Thing", Desc = "Una novela de misterio para el trayecto." },
	Calcetines = { Name = "Calcetines divertidos", Icon = "🧦", Kind = "Thing", Desc = "Con dibujos de trenes. Del puesto de la galería." },
}

-- Tiendas (ShopId -> lo que vende). Las de la galería están en Plaza Mayor; los quioscos, en todas.
Metro.Shops = {
	Quiosco = { Name = "Quiosco del metro", Icon = "📰", Items = { { "Revista", 2 }, { "Chuches", 2 }, { "Refresco", 2 } } },
	Cafeteria = { Name = "Café Andén", Icon = "☕", Items = { { "CafeAnden", 2 }, { "Churros", 3 }, { "Refresco", 2 } } },
	Bocateria = { Name = "Bocatas Express", Icon = "🥪", Items = { { "Bocadillo", 4 }, { "Croqueton", 3 }, { "Refresco", 2 } } },
	Musica = { Name = "Vinilo Subterráneo", Icon = "💿", Items = { { "Vinilo", 12 }, { "Auriculares", 20 }, { "Guitarra", 60 } } },
	Maquina = { Name = "Máquina expendedora", Icon = "🥤", Items = { { "Refresco", 2 }, { "Chuches", 2 }, { "Agua", 1 } } },
	Donuts = { Name = "Dónuts & Co.", Icon = "🍩", Items = { { "Donut", 2 }, { "CafeAnden", 2 }, { "ZumoNaranja", 3 } } },
	Pizza = { Name = "Pizza al Corte", Icon = "🍕", Items = { { "PizzaCorte", 3 }, { "Refresco", 2 }, { "Agua", 1 } } },
	Kebab = { Name = "Kebab Andén 2", Icon = "🌯", Items = { { "Kebab", 5 }, { "Refresco", 2 } } },
	Floristeria = { Name = "Floristería Raíces", Icon = "💐", Items = { { "Rosa", 3 }, { "Ramo", 10 } } },
	Recuerdos = { Name = "Recuerdos de Valmar", Icon = "🧲", Items = { { "Postal", 1 }, { "Llavero", 4 }, { "Iman", 3 }, { "Calcetines", 5 } } },
	Farmacia = { Name = "Farmacia del Metro", Icon = "💊", Items = { { "Tiritas", 3 }, { "Panuelos", 1 }, { "Agua", 1 } } },
	Libreria = { Name = "Libros al Paso", Icon = "📚", Items = { { "Libro", 6 }, { "Revista", 2 }, { "Paraguas", 7 } } },
	Palomitas = { Name = "Carrito de palomitas", Icon = "🍿", Items = { { "Palomitas", 2 }, { "Refresco", 2 } } },
}

-- Vida del metro (MetroLifeService): guardias, ratas, aseos y cacharros con los que trastear
Metro.Life = {
	RatBounty = 1, -- lo que paga el metro por cada rata espantada
	RatCooldown = 8, -- segundos entre recompensas (por jugador)
	RatsPerNest = 2,
	PhonePrice = 1,
	WishPrice = 1,
	ShinePrice = 2,
	BinCooldown = 30, -- segundos entre registrar papeleras (por jugador)
	BinCoinChance = 0.25,
	LockerCoinChance = 0.15,
	ActiveRange = 150, -- las cosas se animan si hay alguien a esta distancia
}
Metro.PhotoPrice = 3

-- Músicos: tocar en el escenario de la galería
Metro.Busk = {
	Instrument = "Guitarra",
	Notes = 12, -- notas por actuación
	PerHit = 2, -- propina por nota bien tocada
	MaxTips = 30,
	Cooldown = 45, -- segundos entre actuaciones
	MinSeconds = 10, -- una actuación dura al menos esto
}

-- Encargos del tablón (galería de Plaza Mayor)
Metro.Missions = {
	Perdido = { Name = "Objeto perdido", Icon = "👛", Reward = 25, Text = "Alguien ha perdido algo en la estación %s. Búscalo en el andén y llévalo a Objetos Perdidos." },
	Paquete = { Name = "Paquete urgente", Icon = "📦", Reward = 20, Bonus = 10, Seconds = 300, Text = "Lleva este paquete al quiosco de la estación %s (tienes 5 minutos; si llegas rápido, propina)." },
	Gato = { Name = "El gato del metro", Icon = "🐈", Reward = 30, Text = "Se ha escapado el gato de la taquillera. Dicen que lo han visto en %s. Tráelo al tablón." },
}

-- Revisor/a (oficio): pide el billete a los viajeros
Metro.Revisor = {
	PerCheck = 2, -- viajero con billete: todo en orden
	PerFine = 6, -- viajero sin billete: multa
	NoTicketChance = 0.3,
	MaxNpc = 4,
	EnergyCost = 1,
}

---------------------------------------------------------------------
-- Geometría (la usan MetroKit y MetroService, así coinciden)
---------------------------------------------------------------------

-- Centro subterráneo de una estación en una línea (debajo de su boca de metro)
function Metro.center(stationId: string, line: Line): Vector3
	local s = Metro.Stations[stationId]
	return Vector3.new(s.Surface[1], line.Y, s.Surface[2])
end

-- Dirección del andén en una estación (de la anterior a la siguiente, en horizontal)
function Metro.direction(line: Line, index: number): Vector3
	local n = #line.Stations
	local a = Metro.center(line.Stations[math.max(1, index - 1)], line)
	local b = Metro.center(line.Stations[math.min(n, index + 1)], line)
	local d = b - a
	d = Vector3.new(d.X, 0, d.Z)
	return if d.Magnitude > 0 then d.Unit else Vector3.new(0, 0, -1)
end

-- Recorrido de la línea: entrada y salida de cada andén (el tren va recto por el andén y gira en
-- los túneles). Devuelve los puntos y, para cada estación, la distancia del recorrido en su centro.
function Metro.path(line: Line): ({ Vector3 }, { number })
	local points, centers = {}, {}
	local half = Metro.PlatformLength / 2
	local s = 0
	for i, id in line.Stations do
		local c = Metro.center(id, line)
		local d = Metro.direction(line, i)
		local entry, exit = c - d * half, c + d * half
		if #points > 0 then
			s += (entry - points[#points]).Magnitude
		end
		table.insert(points, entry)
		centers[i] = s + half
		s += half * 2
		table.insert(points, exit)
	end
	return points, centers
end

-- Punto y dirección a una distancia s del recorrido
function Metro.sample(points: { Vector3 }, s: number): (Vector3, Vector3)
	local walked = 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local len = (b - a).Magnitude
		if s <= walked + len or i == #points - 1 then
			local t = if len > 0 then math.clamp((s - walked) / len, 0, 1) else 0
			return a:Lerp(b, t), if len > 0 then (b - a).Unit else Vector3.new(0, 0, -1)
		end
		walked += len
	end
	return points[1], Vector3.new(0, 0, -1)
end

return Metro
