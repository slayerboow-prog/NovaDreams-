-- Metro: el metro subterráneo de Valmar (MetroKit construye, MetroService lo mueve, MetroUI lo enseña).
--
-- Dos líneas bajo la ciudad. Cada estación tiene una boca de metro junto a la acera con escaleras
-- que bajan de verdad: calle → escaleras → vestíbulo (billetes) → escaleras mecánicas por un pozo
-- inclinado → vestíbulo de andenes (billetes y tornos) → andén. Todo se recorre andando; el ascensor
-- es la única forma de "saltar". Plaza Mayor es el corazón: allí se cruzan las dos líneas y está la
-- galería comercial subterránea (tiendas, cafetería, escenario para músicos, tablón de encargos y
-- objetos perdidos), a la que se baja por unas escaleras mecánicas que salen del techo.

local Metro = {}

export type Station = {
	Id: string,
	Name: string,
	Surface: { number },
	Facing: { number },
	Hub: boolean?,
	Access: { Side: number, Lanes: number, Stair: number, Edge: number }?,
}
export type Line = { Id: string, Name: string, Color: Color3, Y: number, Stations: { string } }

local rgb = Color3.fromRGB

-- Estaciones: Surface es el punto de la acera bajo el que está el andén (X, Z) y Facing mira hacia la
-- calzada. El andén va paralelo a la calle y el vestíbulo queda del lado contrario a la calzada.
-- Access (la boca de metro, en el marco de la estación: X hacia el vestíbulo, Z a lo largo del andén):
--   Side  = +1/-1: a qué punta del vestíbulo llega el pozo de las escaleras mecánicas
--   Lanes = X del centro de las escaleras mecánicas (dentro del vestíbulo de andenes)
--   Stair = X del centro de las escaleras de la calle (junto a la acera)
--   Edge  = X del borde de la acera (la boca se pavimenta hasta ahí)
Metro.Stations = {
	Poniente = { Id = "Poniente", Name = "Poniente", Surface = { -1800, 17.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 7.5, Edge = 3.5 } },
	PlazaMayor = { Id = "PlazaMayor", Name = "Plaza Mayor", Surface = { -80, -66 }, Facing = { 1, 0 }, Hub = true },
	Levante = { Id = "Levante", Name = "Levante", Surface = { 1900, 17.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 7.5, Edge = 3.5 } },
	PlayaDorada = { Id = "PlayaDorada", Name = "Playa Dorada", Surface = { 3564, -400 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 7, Edge = 3 } },
	Norte = { Id = "Norte", Name = "Norte", Surface = { 17.5, -1800 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 7.5, Edge = 3.5 } },
	SanRoque = { Id = "SanRoque", Name = "San Roque", Surface = { 17.5, 2000 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 7.5, Edge = 3.5 } },
	Puerto = { Id = "Puerto", Name = "Puerto", Surface = { 700, 3164 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 7, Edge = 3 } },
	Villaverde = { Id = "Villaverde", Name = "Villaverde", Surface = { -2150, -1832.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 7.5, Edge = 3.5 } },
	Financiero = { Id = "Financiero", Name = "Distrito Financiero", Surface = { 16, -360 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 7.5, Edge = 4 } },
	Campus = { Id = "Campus", Name = "Campus", Surface = { 2100, 1317.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 7.5, Edge = 3.5 } },
} :: { [string]: Station }

-- Las líneas van a distinta profundidad para cruzarse sin chocar (Y = suelo del andén)
Metro.Lines = {
	{ Id = "L1", Name = "Línea 1", Color = rgb(215, 40, 50), Y = -42, Stations = { "Villaverde", "Poniente", "PlazaMayor", "Levante", "PlayaDorada", "Campus" } },
	{ Id = "L2", Name = "Línea 2", Color = rgb(40, 110, 215), Y = -66, Stations = { "Norte", "Financiero", "PlazaMayor", "SanRoque", "Puerto" } },
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

-- Los bebés y los niños no pagan (pasan el torno sin billete)
Metro.FreeStages = { Bebe = true, Nino = true }

-- Billetes (máquinas del vestíbulo)
Metro.TicketItem = "BilleteMetro"
Metro.Tickets = {
	{ Id = "Sencillo", Name = "Billete sencillo", Icon = "🎫", Price = 2, Count = 1 },
	{ Id = "Bono10", Name = "Bonometro (10 viajes)", Icon = "🎟️", Price = 15, Count = 10 },
	{ Id = "Joven", Name = "Billete joven (hasta 25 años, 1 viaje)", Icon = "🧑", Price = 1, Count = 1, Stages = { Adolescente = true, AdultoJoven = true } },
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

-- Dirección del andén en una estación (en horizontal). En las estaciones de calle, el andén va
-- paralelo a la calle y el vestíbulo (a la derecha del andén) queda del lado contrario a la calzada;
-- en Plaza Mayor, de la estación anterior a la siguiente. (Puede ir en sentido contrario a la línea:
-- el recorrido de los trenes usa Metro.forward.)
function Metro.direction(line: Line, index: number): Vector3
	local st = Metro.Stations[line.Stations[index]]
	if not st.Hub then
		return Vector3.new(-st.Facing[2], 0, st.Facing[1])
	end
	local n = #line.Stations
	local a = Metro.center(line.Stations[math.max(1, index - 1)], line)
	local b = Metro.center(line.Stations[math.min(n, index + 1)], line)
	local d = b - a
	d = Vector3.new(d.X, 0, d.Z)
	return if d.Magnitude > 0 then d.Unit else Vector3.new(0, 0, -1)
end

-- La dirección del andén en el sentido de la línea (de la primera estación a la última)
function Metro.forward(line: Line, index: number): Vector3
	local d = Metro.direction(line, index)
	local n = #line.Stations
	local a = Metro.center(line.Stations[math.max(1, index - 1)], line)
	local b = Metro.center(line.Stations[math.min(n, index + 1)], line)
	return if d:Dot(b - a) < 0 then -d else d
end

-- Marco de una estación: X a la derecha del andén (hacia el vestíbulo), -Z a lo largo del andén,
-- Y = 0 en el suelo del andén. (Un giro en Y y no CFrame.lookAt: en Lune sale mal hacia +Z.)
function Metro.frame(stationId: string, line: Line): CFrame
	local d = Metro.direction(line, table.find(line.Stations, stationId) :: number)
	return CFrame.new(Metro.center(stationId, line)) * CFrame.Angles(0, math.atan2(-d.X, -d.Z), 0)
end

-- Curva suave (Bézier) entre la salida de un andén y la entrada del siguiente
local CURVE_STEPS = 10
local function curve(a: Vector3, da: Vector3, b: Vector3, db: Vector3): { Vector3 }
	local dist = (b - a).Magnitude
	local k = math.clamp(dist * 0.35, 20, 450)
	local p1, p2 = a + da * k, b - db * k
	local list = {}
	for i = 1, CURVE_STEPS - 1 do
		local t = i / CURVE_STEPS
		local u = 1 - t
		table.insert(list, a * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + b * (t * t * t))
	end
	return list
end

-- Recorrido de la línea: entrada y salida de cada andén (el tren va recto por el andén) y, entre
-- andenes, una curva suave por los túneles. Devuelve los puntos, para cada estación la distancia del
-- recorrido en su centro, y qué tramos son andén (platform[k] = true: de points[k] a points[k + 1]).
function Metro.path(line: Line): ({ Vector3 }, { number }, { [number]: boolean })
	local points, centers, platform = {}, {}, {}
	local half = Metro.PlatformLength / 2
	local s = 0
	local lastDir: Vector3? = nil
	for i, id in line.Stations do
		local c = Metro.center(id, line)
		local d = Metro.forward(line, i)
		local entry, exit = c - d * half, c + d * half
		if lastDir then
			for _, p in curve(points[#points], lastDir, entry, d) do
				s += (p - points[#points]).Magnitude
				table.insert(points, p)
			end
			s += (entry - points[#points]).Magnitude
		end
		table.insert(points, entry)
		platform[#points] = true
		centers[i] = s + half
		s += half * 2
		table.insert(points, exit)
		lastDir = d
	end
	return points, centers, platform
end

---------------------------------------------------------------------
-- Bocas de metro: calle → escaleras → vestíbulo → escaleras mecánicas → vestíbulo de andenes
---------------------------------------------------------------------

Metro.StreetY = 1 -- altura de la acera
Metro.HallY = -14 -- suelo del vestíbulo (bajo la calle: su techo queda por debajo de las calzadas)
Metro.HallHeight = 9
Metro.Underground = -10 -- por debajo de esto ya estás en el metro (no llueve, no se oye la lluvia)
Metro.Slope = math.rad(30) -- pendiente de las escaleras mecánicas (y de la escalera fija de al lado)
Metro.StreetStairs = { Rise = 0.75, Run = 1.2, Flights = { 10, 10 }, Landing = 3.6, Width = 6 }
Metro.MaxRise = 1.2 -- ningún peldaño más alto que esto
-- Pozo de las escaleras mecánicas (de izquierda a derecha mirando hacia abajo): mecánica de bajada,
-- barandilla, escalera fija, barandilla, mecánica de subida. Más las paredes.
Metro.Shaft = { Escalator = 3, Balustrade = 0.5, Stairs = 3.6, Wall = 0.5, Headroom = 8.8, Speed = 7 }
Metro.Shaft.Width = Metro.Shaft.Escalator * 2 + Metro.Shaft.Balustrade * 2 + Metro.Shaft.Stairs + Metro.Shaft.Wall * 2
Metro.LandingLength = 5 -- rellanos arriba y abajo de las escaleras mecánicas
Metro.HallLength = 10 -- vestíbulo entre las escaleras de la calle y las mecánicas
-- Vestíbulo de andenes (en el marco de la estación)
Metro.Lobby = { X0 = 17.5, X1 = 47.5, Z = 25, Height = 13 }

-- Plaza Mayor: la boca está en la plaza y las escaleras mecánicas bajan al vestíbulo de la Línea 1
-- saliendo de su techo (marco de la Línea 1: X hacia el sur, Z hacia el oeste)
Metro.HubAccess = {
	Line = "L1",
	Shaft = { X = 41.2, Z = 18, Dir = { 0, 1 }, Ceiling = true }, -- borde de abajo y hacia dónde baja
	Stair = { X = 6.4, Z = -40, Dir = { 1, 0 } }, -- arriba de la escalera de la calle
	Grow = { XMax = 2, ZMin = 6 }, -- el vestíbulo, algo más grande (máquinas y plano)
}

local function round(v: Vector3): Vector3
	local function r(n: number): number
		return math.floor(n * 1000 + 0.5) / 1000
	end
	return Vector3.new(r(v.X), r(v.Y), r(v.Z))
end

local accessCache: { [string]: any } = {}

-- Geometría de la boca de una estación (todo en coordenadas del mundo y alineado con los ejes):
--   Line, Frame (marco de la estación a la que baja), LowerY (suelo de abajo)
--   Stair = { Top, Dir, Width, Flights = { { Top, Bottom, Steps, Rise, Run } }, Landings = { { From, To } },
--             Bottom, Open (hasta dónde está al aire libre, medido desde arriba), Length }
--   Hall = { Min, Max } (caja del vestíbulo: suelo y techo)
--   Shaft = { Top, Bottom, Dir, Width, Steps, Rise, Run, Length, Ceiling }
--   Route = puntos por los que se pasa andando, de la calle al vestíbulo de andenes
function Metro.access(stationId: string): any
	if accessCache[stationId] then
		return accessCache[stationId]
	end
	local st = Metro.Stations[stationId]
	local spec: any
	local line: Line
	if st.Hub then
		spec = Metro.HubAccess
		line = Metro.lineById[spec.Line]
	else
		for _, l in Metro.Lines do
			if table.find(l.Stations, stationId) then
				line = l
			end
		end
		local a = st.Access :: any
		local runE = (Metro.HallY - line.Y) / math.tan(Metro.Slope)
		local s = a.Side
		local zTop = s * (Metro.Lobby.Z + runE)
		local st2 = Metro.StreetStairs
		local runS = (st2.Flights[1] + st2.Flights[2]) * st2.Run + st2.Landing
		local zFar = zTop + s * Metro.HallLength
		spec = {
			Line = line.Id,
			Shaft = { X = a.Lanes, Z = s * Metro.Lobby.Z, Dir = { 0, -s } },
			Stair = { X = a.Stair, Z = zFar + s * runS, Dir = { 0, -s } },
			Grow = { XMax = 6 },
		}
	end
	local F = Metro.frame(stationId, line)
	local function world(x: number, y: number, z: number): Vector3
		return round(F * Vector3.new(x, y, z))
	end
	local function dirOf(d: { number }): Vector3
		return round((F * Vector3.new(d[1], 0, d[2])) - F.Position)
	end
	local h = Metro.HallY - line.Y -- de abajo al vestíbulo
	local tan = math.tan(Metro.Slope)
	local A: any = { Station = stationId, Line = line, Frame = F, LowerY = line.Y }

	-- Escaleras de la calle: dos tramos con un rellano
	local S = Metro.StreetStairs
	local sd = dirOf(spec.Stair.Dir)
	local top = world(spec.Stair.X, Metro.StreetY - line.Y, spec.Stair.Z)
	local flights, landings = {}, {}
	local p = top
	for i, n in S.Flights do
		local b = round(p + sd * (n * S.Run) - Vector3.new(0, n * S.Rise, 0))
		table.insert(flights, { Top = p, Bottom = b, Steps = n, Rise = S.Rise, Run = S.Run })
		p = b
		if i < #S.Flights then
			local e = round(p + sd * S.Landing)
			table.insert(landings, { From = p, To = e })
			p = e
		end
	end
	local length = (Vector3.new(p.X, 0, p.Z) - Vector3.new(top.X, 0, top.Z)).Magnitude
	-- Al aire libre mientras no quepa una persona (7 studs) bajo el techo del vestíbulo
	local ceiling = Metro.HallY + Metro.HallHeight
	local drop = Metro.StreetY - (ceiling - 7)
	local open = 0
	local walked, y = 0, Metro.StreetY
	for i, f in flights do
		for _ = 1, f.Steps do
			walked += f.Run
			y -= f.Rise
			if Metro.StreetY - y <= drop then
				open = walked
			end
		end
		if landings[i] then
			walked += S.Landing
			if Metro.StreetY - y <= drop then
				open = walked
			end
		end
	end
	A.Stair = { Top = top, Dir = sd, Width = S.Width, Flights = flights, Landings = landings, Bottom = p, Open = open + 1, Length = length }

	-- Escaleras mecánicas (y la fija del medio): del vestíbulo al de andenes
	local ed = dirOf(spec.Shaft.Dir)
	local bottom = world(spec.Shaft.X, 0, spec.Shaft.Z)
	local run = h / tan
	local steps = math.ceil(h / 0.75)
	local shaftTop = round(bottom - ed * run + Vector3.new(0, h, 0))
	A.Shaft = {
		Top = shaftTop,
		Bottom = bottom,
		Dir = ed,
		Width = Metro.Shaft.Width,
		Steps = steps,
		Rise = h / steps,
		Run = run / steps,
		Length = run,
		Ceiling = spec.Shaft.Ceiling == true,
	}

	-- Vestíbulo: la caja que abarca el rellano de abajo de la calle y el de arriba de las mecánicas
	local L = Metro.LandingLength
	local across = Vector3.new(ed.Z, 0, -ed.X) -- perpendicular en horizontal
	local sAcross = Vector3.new(sd.Z, 0, -sd.X)
	local pts = {
		p + sAcross * (S.Width / 2), p - sAcross * (S.Width / 2),
		p + sd * L + sAcross * (S.Width / 2), p + sd * L - sAcross * (S.Width / 2),
		shaftTop + across * (A.Shaft.Width / 2), shaftTop - across * (A.Shaft.Width / 2),
		shaftTop - ed * L + across * (A.Shaft.Width / 2), shaftTop - ed * L - across * (A.Shaft.Width / 2),
	}
	local lo = Vector3.new(math.huge, 0, math.huge)
	local hi = Vector3.new(-math.huge, 0, -math.huge)
	for _, q in pts do
		lo = Vector3.new(math.min(lo.X, q.X), 0, math.min(lo.Z, q.Z))
		hi = Vector3.new(math.max(hi.X, q.X), 0, math.max(hi.Z, q.Z))
	end
	-- Un poco más grande por los lados por donde no se entra (y lo que pida la estación)
	local grow = spec.Grow or {}
	local function side(axis: Vector3, positive: boolean, localGrow: number?)
		local amount = 1.5 + (localGrow or 0)
		-- ¿Por este lado entran las escaleras de la calle o salen las mecánicas? Entonces no crece.
		local out = if positive then axis else -axis
		if out:Dot(-sd) > 0.5 or out:Dot(ed) > 0.5 then
			return 0
		end
		return amount
	end
	local fx = (F * Vector3.new(1, 0, 0)) - F.Position
	local fz = (F * Vector3.new(0, 0, 1)) - F.Position
	local extra = { ["+X"] = 0, ["-X"] = 0, ["+Z"] = 0, ["-Z"] = 0 }
	local function addLocal(v: Vector3, amount: number?)
		if not amount then
			return
		end
		local key = if math.abs(v.X) > 0.5 then (if v.X > 0 then "+X" else "-X") else (if v.Z > 0 then "+Z" else "-Z")
		extra[key] += amount
	end
	addLocal(fx, grow.XMax)
	addLocal(-fx, grow.XMin)
	addLocal(fz, grow.ZMax)
	addLocal(-fz, grow.ZMin)
	local X, Z = Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
	lo = Vector3.new(lo.X - side(X, false, extra["-X"]), Metro.HallY, lo.Z - side(Z, false, extra["-Z"]))
	hi = Vector3.new(hi.X + side(X, true, extra["+X"]), Metro.HallY + Metro.HallHeight, hi.Z + side(Z, true, extra["+Z"]))
	A.Hall = { Min = round(lo), Max = round(hi) }

	-- Camino andando (por la escalera fija): calle → rellano → vestíbulo → abajo
	local route = { top }
	for i, f in flights do
		table.insert(route, f.Bottom)
		if landings[i] then
			table.insert(route, landings[i].To)
		end
	end
	table.insert(route, shaftTop)
	table.insert(route, bottom)
	table.insert(route, round(bottom + ed * L))
	A.Route = route
	accessCache[stationId] = A
	return A
end

-- Escalera mecánica: dónde va el peldaño k (distancia en horizontal desde arriba) en el instante t.
-- speed > 0 baja, < 0 sube; los peldaños dan la vuelta (count peldaños separados pitch)
function Metro.escalatorOffset(k: number, t: number, pitch: number, count: number, speed: number): number
	return ((k + 0.5) * pitch + t * speed) % (count * pitch)
end

-- ¿Está el punto (en horizontal) dentro del vestíbulo de andenes de la estación? (con margen)
function Metro.inLobby(stationId: string, line: Line, p: Vector3, margin: number?): boolean
	local q = Metro.frame(stationId, line):PointToObjectSpace(p)
	local m = margin or 0.05
	local L = Metro.Lobby
	return q.X >= L.X0 - m and q.X <= L.X1 + m and math.abs(q.Z) <= L.Z + m
end

---------------------------------------------------------------------
-- Cuándo llega el tren (paneles de "próximo tren"): cuentas puras, las prueba test-gameplay
---------------------------------------------------------------------

-- Segundos para recorrer dist studs arrancando y frenando (acelera, va a crucero y frena)
function Metro.travelTime(dist: number): number
	local v, a = Metro.Speed, Metro.Accel
	if dist >= v * v / a then
		return 2 * v / a + (dist - v * v / a) / v
	end
	return 2 * math.sqrt(dist / a)
end

-- La parada siguiente en el vaivén de la línea (de punta a punta y vuelta)
function Metro.nextStop(n: number, index: number, dir: number): (number, number)
	local i = index + dir
	if i < 1 or i > n then
		dir = -dir
		i = index + dir
	end
	return i, dir
end

-- Estado del tren (el de MetroService): { Centers, Index, Dir, Phase = "Dwell"|"Move", Timer, Duration, Elapsed }
-- Devuelve: segundos hasta que el tren esté en el andén de la estación target (0 = ya está), y el índice
-- de la estación de punta hacia la que irá al salir de allí (para el cartel: "→ Levante").
function Metro.eta(train: { [string]: any }, target: number): (number, number)
	local centers = train.Centers
	local n = #centers
	local cur, dir = train.Index, train.Dir
	local function heading(at: number, d: number): number
		local _, d2 = Metro.nextStop(n, at, d)
		return if d2 > 0 then n else 1
	end
	local t
	if train.Phase == "Dwell" then
		if cur == target then
			return 0, heading(cur, dir)
		end
		t = math.max(0, train.Timer)
	else
		t = math.max(0, train.Duration - train.Elapsed)
		if cur == target then
			return t, heading(cur, dir)
		end
		t += Metro.Dwell
	end
	for _ = 1, n * 2 do
		local nextI, nextDir = Metro.nextStop(n, cur, dir)
		t += Metro.travelTime(math.abs(centers[nextI] - centers[cur]))
		cur, dir = nextI, nextDir
		if cur == target then
			return t, heading(cur, dir)
		end
		t += Metro.Dwell
	end
	return t, heading(cur, dir)
end

-- Texto del panel para una estación: "Línea 1 → Levante · 2 min", "LLEGANDO", "EN ANDÉN"
function Metro.boardText(line: Line, seconds: number, towardIndex: number, dwellLeft: number?): string
	local toward = Metro.Stations[line.Stations[towardIndex]].Name
	if seconds <= 0 then
		return ("🚇 %s → %s · EN ANDÉN · sale en %d s"):format(line.Name, toward, math.max(0, math.ceil(dwellLeft or 0)))
	elseif seconds <= 20 then
		return ("%s → %s · LLEGANDO"):format(line.Name, toward)
	elseif seconds < 60 then
		return ("%s → %s · %d s"):format(line.Name, toward, math.ceil(seconds))
	end
	return ("%s → %s · %d min"):format(line.Name, toward, math.ceil(seconds / 60))
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
