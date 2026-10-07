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
	Poniente = { Id = "Poniente", Name = "Poniente", Surface = { -1800, 17.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 8.5, Edge = 3.5 } },
	PlazaMayor = { Id = "PlazaMayor", Name = "Plaza Mayor", Surface = { -80, -66 }, Facing = { 1, 0 }, Hub = true },
	Levante = { Id = "Levante", Name = "Levante", Surface = { 1900, 17.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 8.5, Edge = 3.5 } },
	PlayaDorada = { Id = "PlayaDorada", Name = "Playa Dorada", Surface = { 3564, -400 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 8, Edge = 3 } },
	Norte = { Id = "Norte", Name = "Norte", Surface = { 17.5, -1800 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 8.5, Edge = 3.5 } },
	SanRoque = { Id = "SanRoque", Name = "San Roque", Surface = { 17.5, 2000 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 8.5, Edge = 3.5 } },
	Puerto = { Id = "Puerto", Name = "Puerto", Surface = { 700, 3164 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 8, Edge = 3 } },
	Villaverde = { Id = "Villaverde", Name = "Villaverde", Surface = { -2150, -1832.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 8.5, Edge = 3.5 } },
	Financiero = { Id = "Financiero", Name = "Distrito Financiero", Surface = { 16, -360 }, Facing = { -1, 0 }, Access = { Side = -1, Lanes = 26, Stair = 8.5, Edge = 4 } },
	Campus = { Id = "Campus", Name = "Campus", Surface = { 2100, 1317.5 }, Facing = { 0, -1 }, Access = { Side = -1, Lanes = 26, Stair = 8.5, Edge = 3.5 } },
} :: { [string]: Station }

-- A qué distrito da servicio cada estación y qué hay cerca (plano, planificador y paneles)
Metro.StationInfo = {
	Villaverde = { District = "Oeste", Serves = { "Villaverde", "Barrio residencial", "Campo" } },
	Poniente = { District = "Oeste", Serves = { "Costa oeste", "Marina", "Barrio de lujo" } },
	PlazaMayor = { District = "Centro", Serves = { "Plaza Mayor", "Ayuntamiento", "Galería comercial", "Tiendas" } },
	Levante = { District = "Este", Serves = { "Zona comercial", "Ocio", "Restaurantes" } },
	PlayaDorada = { District = "Este", Serves = { "Playa Dorada", "Paseo marítimo", "Hoteles" } },
	Campus = { District = "Universitario", Serves = { "Universidad", "Residencia de estudiantes", "Biblioteca" } },
	Norte = { District = "Norte", Serves = { "Valmar Norte", "Los Pinos", "Colegio" } },
	Financiero = { District = "Centro", Serves = { "Distrito Financiero", "Oficinas", "Torres" } },
	SanRoque = { District = "Sur", Serves = { "San Roque", "Barrio obrero", "Mercado" } },
	Puerto = { District = "Sur", Serves = { "Puerto", "Zona industrial", "Almacenes" } },
}
Metro.Districts = {
	{ Id = "Centro", Name = "Centro", Icon = "🏙️" },
	{ Id = "Norte", Name = "Norte", Icon = "🏡" },
	{ Id = "Oeste", Name = "Oeste", Icon = "🌴" },
	{ Id = "Este", Name = "Este", Icon = "🛍️" },
	{ Id = "Universitario", Name = "Universitario", Icon = "🎓" },
	{ Id = "Sur", Name = "Sur", Icon = "🏭" },
}

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

-- Tornos (MetroService los monta; MetroKit los pone en el muro entre vestíbulo y andén). Cada torno
-- tiene un atributo Through: dónde te deja al otro lado. Su cartel flota DELANTE del torno, en el lado
-- desde el que se usa, y llega poco: desde el andén no se ve "Pasar (billete)" (solo "Salir") ni desde el
-- vestíbulo "Salir". Antes llegaban los dos a los dos lados, el botón Interactuar del móvil pulsaba el
-- que tocara y el niño que acababa de pasar volvía al vestíbulo con el siguiente toque.
Metro.Gate = {
	Reach = 5, -- alcance del cartel de "Pasar (billete)"
	ExitReach = 4, -- alcance del de "Salir"
	PromptOffset = 3, -- el cartel, a esta distancia del torno (hacia el lado desde el que se usa)
	PromptHeight = 1, -- …y esto por encima de su centro
	Grace = 2.5, -- segundos tras cruzar un torno en los que otro no te devuelve (doble toque sin querer)
	Priority = 1, -- PromptPriority de los carteles de los tornos (van antes que ratas, interfonos…)
}
-- Alcance del cartel de las máquinas de billetes y taquillas (el cartel va delante de ellas)
Metro.SellerReach = 6
-- Cosas "de ambiente" (ratas, interfono, papeleras): nunca le quitan el botón Interactuar a un torno
Metro.AmbientPriority = -1

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Hacia dónde se cruza un torno (unitario, horizontal): de su lado de uso hacia Through
function Metro.gateDirection(gatePos: Vector3, through: Vector3): Vector3
	local d = flat(through - gatePos)
	return if d.Magnitude > 1e-3 then d.Unit else Vector3.new(-1, 0, 0)
end

-- > 0: ya estás al otro lado (el de Through); < 0: en el lado desde el que se usa
function Metro.gateSide(gatePos: Vector3, through: Vector3, pos: Vector3): number
	return flat(pos - gatePos):Dot(Metro.gateDirection(gatePos, through))
end

-- Dónde va el cartel del torno (en el mundo)
function Metro.gatePromptAt(gatePos: Vector3, through: Vector3): Vector3
	return gatePos - Metro.gateDirection(gatePos, through) * Metro.Gate.PromptOffset + Vector3.new(0, Metro.Gate.PromptHeight, 0)
end

-- Dónde y mirando a dónde te deja el torno (de espaldas al torno, hacia el andén o el vestíbulo)
function Metro.gateLanding(gatePos: Vector3, through: Vector3): CFrame
	local d = Metro.gateDirection(gatePos, through)
	return CFrame.new(through) * CFrame.Angles(0, math.atan2(-d.X, -d.Z), 0)
end

-- ¿Pasa el torno y cómo? who: { Stage, Job, FreeJob, Pass, Tester, Tickets }. Devuelve el modo
-- ("Gratis", "Abono", "Servicio", "Pruebas", "Billete") o nil si no puede pasar. Solo "Billete" gasta.
function Metro.gatePass(who: { [string]: any }): string?
	if Metro.FreeStages[who.Stage or ""] then
		return "Gratis"
	elseif who.Pass then
		return "Abono"
	elseif who.FreeJob then
		return "Servicio"
	elseif (who.Tickets or 0) >= 1 then
		return "Billete"
	elseif who.Tester then
		return "Pruebas" -- modo pruebas (TesterService.bypass): pasa sin billete
	end
	return nil
end

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
	MaxSeconds = 120, -- (más que esto: la ventana se quedó abierta; no cuenta)
	Zone = 0.16, -- ancho de la zona verde (de 0 a 1 en la barra)
	Slack = 0.04, -- margen a cada lado de la zona (lo que se desvía la marca entre fotogramas)
	MinGap = 0.25, -- segundos entre dos toques (el botón no admite más deprisa)
	Late = 2, -- segundos de más que se le perdonan a los tiempos del cliente (la red)
}

-- Minijuego de guitarra, igual en el servidor y en el cliente. El servidor elige las zonas verdes
-- (buskZones, con una semilla) y el cliente le devuelve CUÁNDO tocó cada nota (segundos desde que
-- empezó); el servidor rehace la marca y cuenta los aciertos (buskScore). Antes el cliente decía
-- cuántas acertó y siempre se cobraba la propina máxima.
function Metro.buskZones(seed: number): { number }
	local x = math.floor(math.abs(seed)) % 2147483647 + 1
	local zones = {}
	for _ = 1, Metro.Busk.Notes do
		x = (x * 16807) % 2147483647
		table.insert(zones, 0.08 + (x / 2147483647) * 0.76)
	end
	return zones
end

-- Lo rápido que va la marca en la nota n (de la barra entera por segundo)
function Metro.buskSpeed(n: number): number
	return 0.8 + n * 0.06
end

-- Dónde está la marca (0 a 1) tras recorrer «dist» (va y vuelve: rebota en los extremos)
function Metro.buskMark(dist: number): number
	local m = dist % 2
	return if m <= 1 then m else 2 - m
end

-- Aciertos de verdad: rehace la marca con los tiempos de cada toque. Toques imposibles (fuera de
-- orden, más seguidos que MinGap, después de lo que ha durado la actuación de verdad «elapsed») no
-- cuentan, y como mucho Notes.
function Metro.buskScore(zones: { number }, times: any, elapsed: number): number
	if type(times) ~= "table" or type(zones) ~= "table" then
		return 0
	end
	local B = Metro.Busk
	local hits, dist, last = 0, 0, 0
	for n = 1, math.min(#times, B.Notes, #zones) do
		local t = times[n]
		if type(t) ~= "number" or t ~= t or t < last or t > elapsed + B.Late or (n > 1 and t - last < B.MinGap - 0.05) then
			break
		end
		dist += Metro.buskSpeed(n) * (t - last)
		last = t
		local pos = Metro.buskMark(dist)
		if pos >= zones[n] - B.Slack and pos <= zones[n] + B.Zone + B.Slack then
			hits += 1
		end
	end
	return hits
end

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

-- Vía, coche y andén, de lado (en el marco de la estación: X = 0 en el eje de la vía, hacia el andén).
-- El suelo del coche llega a 4,5 del eje y el andén empieza en 5: la vía se vigila solo hasta
-- TrackHalf, y el coche cuenta por dentro hasta CarHalf (quien está en el umbral de la puerta va
-- dentro). Antes la vía llegaba a 4,6 y el coche solo a 4,4: en el umbral de la puerta o al borde del
-- andén te devolvían al andén con «¡No se puede andar por la vía!».
Metro.TrackHalf = 4.4
Metro.CarHalf = 4.6
Metro.PlatformEdge = 5
Metro.PlatformDepth = 12 -- (el andén va de PlatformEdge a PlatformEdge + PlatformDepth)

-- ¿Este punto (en el sitio del coche: X de lado, Y desde el suelo del coche, Z a lo largo) está
-- dentro del coche? (MetroService.carAt: quién va en el tren, aunque sea de pie)
function Metro.inCar(q: Vector3): boolean
	return math.abs(q.X) < Metro.CarHalf and q.Y > -1 and q.Y < 9 and math.abs(q.Z) < Metro.CarLength / 2 + 1
end

-- ¿Está este punto sobre el andén de una estación (o en su borde)? Devuelve la estación y la línea.
-- Las curvas del túnel salen pegadas a las esquinas de algunos andenes (Villaverde): sin esto, la
-- esquina del andén caía dentro de la zona de vía.
function Metro.onPlatform(position: Vector3): (string?, Line?)
	local half = Metro.PlatformLength / 2
	for _, line in Metro.Lines do
		if position.Y > line.Y - 3 and position.Y < line.Y + 7 then
			for _, id in line.Stations do
				local q = Metro.frame(id, line):PointToObjectSpace(position)
				if q.X >= Metro.TrackHalf and q.X <= Metro.PlatformEdge + Metro.PlatformDepth + 1 and math.abs(q.Z) <= half then
					return id, line
				end
			end
		end
	end
	return nil, nil
end

-- ¿Está este punto (los pies) en la vía o en un túnel? Devuelve la línea y el tramo del recorrido.
-- El recorrido se alarga 60 studs por cada punta (los fondos de saco tras la primera y la última
-- estación). El andén nunca cuenta como vía.
local trackCache: { [string]: { Vector3 } } = {}
function Metro.trackAt(position: Vector3): (Line?, number)
	for _, line in Metro.Lines do
		if position.Y > line.Y - 3 and position.Y < line.Y + 7 then
			local points = trackCache[line.Id]
			if not points then
				points = Metro.path(line)
				local first, last = points[1], points[#points]
				table.insert(points, 1, first + (first - points[2]).Unit * 60)
				table.insert(points, last + (last - points[#points - 1]).Unit * 60)
				trackCache[line.Id] = points
			end
			for i = 1, #points - 1 do
				local a, b = points[i], points[i + 1]
				local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
				local ap = Vector3.new(position.X - a.X, 0, position.Z - a.Z)
				local t = math.clamp(ap:Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
				if (ap - ab * t).Magnitude < Metro.TrackHalf then
					if Metro.onPlatform(position) then
						return nil, 0
					end
					return line, i
				end
			end
		end
	end
	return nil, 0
end

-- ¿Está este punto junto al andén de esa estación (a lo largo del andén, del lado de la vía)? Con el
-- tren parado ahí, no se vigila la vía: el tren la ocupa y se sube y se baja por las puertas.
function Metro.alongPlatform(stationId: string, line: Line, position: Vector3): boolean
	local q = Metro.frame(stationId, line):PointToObjectSpace(position)
	return math.abs(q.Z) <= Metro.PlatformLength / 2 and q.X > -6 and q.Y > -3 and q.Y < 7
end

---------------------------------------------------------------------
-- Bocas de metro: calle → escaleras → vestíbulo → escaleras mecánicas → vestíbulo de andenes
---------------------------------------------------------------------

Metro.StreetY = 1 -- altura de la acera
-- (más hondo y más alto que al principio: su techo, y la cabeza de quien esté dentro, quedan varios
-- studs por debajo de las calzadas y del terreno: nada asoma por la calle. scripts/test-metro lo mira)
Metro.HallY = -17 -- suelo del vestíbulo (bajo la calle: su techo queda por debajo de las calzadas)
Metro.HallHeight = 12 -- (techo en -5: la parte al aire libre de la escalera no crece hacia los cruces)
Metro.Underground = -10 -- por debajo de esto ya estás en el metro (no llueve, no se oye la lluvia)
Metro.Slope = math.rad(30) -- pendiente de las escaleras mecánicas (y de la escalera fija de al lado)
-- (8 de ancho: se baja cómodo, dos personas a la par; 12 + 12 peldaños hasta el vestíbulo, que está más hondo)
Metro.StreetStairs = { Rise = 0.75, Run = 1.2, Flights = { 12, 12 }, Landing = 3.6, Width = 8 }
Metro.MaxRise = 1.2 -- ningún peldaño más alto que esto
-- Pozo de las escaleras mecánicas (de izquierda a derecha mirando hacia abajo): mecánica de bajada,
-- barandilla, escalera fija, barandilla, mecánica de subida. Más las paredes.
Metro.Shaft = { Escalator = 3, Balustrade = 0.5, Stairs = 4.4, Wall = 0.5, Headroom = 8.8, Speed = 7 }
Metro.Shaft.Width = Metro.Shaft.Escalator * 2 + Metro.Shaft.Balustrade * 2 + Metro.Shaft.Stairs + Metro.Shaft.Wall * 2
Metro.LandingLength = 5 -- rellanos arriba y abajo de las escaleras mecánicas
Metro.HallLength = 10 -- vestíbulo entre las escaleras de la calle y las mecánicas
-- Vestíbulo de andenes (en el marco de la estación)
Metro.Lobby = { X0 = 17.5, X1 = 47.5, Z = 25, Height = 15 } -- (Height: techo del vestíbulo de andenes)

-- Plaza Mayor: la boca está en la plaza y las escaleras mecánicas bajan al vestíbulo de la Línea 1
-- saliendo de su techo (marco de la Línea 1: X hacia el sur, Z hacia el oeste)
Metro.HubAccess = {
	Line = "L1",
	Shaft = { X = 41.2, Z = 18, Dir = { 0, 1 }, Ceiling = true }, -- borde de abajo y hacia dónde baja
	Stair = { X = 6.4, Z = -38.8, Dir = { 1, 0 } }, -- arriba de la escalera de la calle (apartada de la palmera de la plaza)
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
		local amount = 3 + (localGrow or 0) -- (vestíbulo holgado)
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
function Metro.travelTime(dist: number, speed: number?): number
	local v, a = speed or Metro.Speed, Metro.Accel
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
-- Lo que para el tren en la estación i (más el descanso en las cabeceras, según el horario)
function Metro.dwellAt(train: { [string]: any }, i: number): number
	local d = train.DwellTime or Metro.Dwell
	if i == 1 or i == #train.Centers then
		d += train.Layover or 0
	end
	return d
end

function Metro.eta(train: { [string]: any }, target: number): (number, number)
	local centers = train.Centers
	local n = #centers
	local cur, dir = train.Index, train.Dir
	local speed = train.Speed
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
		t += Metro.dwellAt(train, cur)
	end
	for _ = 1, n * 2 do
		local nextI, nextDir = Metro.nextStop(n, cur, dir)
		t += Metro.travelTime(math.abs(centers[nextI] - centers[cur]), speed)
		cur, dir = nextI, nextDir
		if cur == target then
			return t, heading(cur, dir)
		end
		t += Metro.dwellAt(train, cur)
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

---------------------------------------------------------------------
-- Movimiento del tren (lo calculan igual el servidor y los clientes: así el tren se ve fluido en
-- cada pantalla y todos lo ven en el mismo sitio)
---------------------------------------------------------------------

-- Distancia recorrida a los t segundos de un tramo de dist studs que dura T (acelera, crucero, frena)
function Metro.travelled(dist: number, t: number, T: number, speed: number?): number
	local a, v = Metro.Accel, speed or Metro.Speed
	local ta = v / a
	if dist < v * v / a then
		ta = math.sqrt(dist / a)
		v = a * ta
	end
	if t <= 0 then
		return 0
	elseif t >= T then
		return dist
	elseif t <= ta then
		return 0.5 * a * t * t
	elseif t >= T - ta then
		local r = math.max(0, T - t)
		return dist - 0.5 * a * r * r
	end
	return 0.5 * a * ta * ta + v * (t - ta)
end

-- Dónde va el centro del tren (distancia del recorrido) según su estado publicado:
-- { Phase = "Dwell"|"Move", S, From, To, Duration, T0 (hora del servidor al salir), Speed }
function Metro.positionAt(state: { [string]: any }, now: number): number
	if state.Phase ~= "Move" then
		return state.S or 0
	end
	local dist = math.abs(state.To - state.From)
	local d = Metro.travelled(dist, now - state.T0, state.Duration, state.Speed)
	return state.From + (if state.To >= state.From then d else -d)
end

-- Cuánto dura un tramo (lo mismo que travelTime, con la velocidad del tren)
function Metro.legDuration(dist: number, speed: number?): number
	return Metro.travelTime(dist, speed)
end

---------------------------------------------------------------------
-- Horarios (van con el reloj del juego)
---------------------------------------------------------------------

-- Crowd = viajeros esperando en cada andén; Riders = viajeros sentados en el tren
Metro.Schedule = {
	{ Id = "Nocturno", Name = "Servicio nocturno", From = 0, To = 6, Dwell = 14, Layover = 70, Crowd = 1, Riders = 2, Night = true },
	{ Id = "Punta", Name = "Hora punta", From = 6, To = 9, Dwell = 12, Layover = 0, Crowd = 5, Riders = 9 },
	{ Id = "Normal", Name = "Frecuencia normal", From = 9, To = 16, Dwell = 14, Layover = 15, Crowd = 3, Riders = 5 },
	{ Id = "Punta", Name = "Hora punta", From = 16, To = 20, Dwell = 12, Layover = 0, Crowd = 5, Riders = 9 },
	{ Id = "Reducida", Name = "Frecuencia reducida", From = 20, To = 24, Dwell = 14, Layover = 40, Crowd = 2, Riders = 3, Night = true },
}

function Metro.scheduleAt(clockTime: number): { [string]: any }
	local h = clockTime % 24
	for _, s in Metro.Schedule do
		if h >= s.From and h < s.To then
			return s
		end
	end
	return Metro.Schedule[3]
end

---------------------------------------------------------------------
-- Incidencias (MetroService las lanza de vez en cuando; salen en los paneles, el tren y el móvil)
---------------------------------------------------------------------
Metro.Incidents = {
	Retraso = { Name = "Retraso", Icon = "⏱️", Hold = { 45, 110 }, Text = "Retraso de %d min en la %s" },
	Averia = { Name = "Avería", Icon = "🔧", Slow = 0.55, Seconds = 200, Text = "Avería en la %s: los trenes circulan despacio" },
	Cerrada = { Name = "Estación cerrada", Icon = "🚧", Seconds = 240, Text = "Estación %s cerrada temporalmente: el tren pasa sin parar" },
	Lleno = { Name = "Tren lleno", Icon = "👥", Seconds = 180, Text = "Trenes muy llenos en la %s: puede que no haya asiento" },
	Seguridad = { Name = "Incidencia de seguridad", Icon = "🚨", Hold = { 30, 60 }, Text = "Incidencia de seguridad en %s: el tren espera en la estación" },
	Mantenimiento = { Name = "Mantenimiento", Icon = "🛠️", Seconds = 300, NightOnly = true, Text = "Obras de mantenimiento en %s: el tren pasa sin parar" },
}
Metro.IncidentEvery = { 300, 600 } -- segundos entre una incidencia y la siguiente (al azar)
Metro.IncidentChance = 0.6

---------------------------------------------------------------------
-- Billetes y abonos
---------------------------------------------------------------------
-- Days = días de juego que dura (un día de juego son Config.DayLengthMinutes minutos reales)
Metro.Passes = {
	{ Id = "Dia", Name = "Abono de un día", Icon = "📅", Price = 5, Days = 1 },
	{ Id = "Semana", Name = "Abono semanal", Icon = "🗓️", Price = 22, Days = 7 },
	{ Id = "Mes", Name = "Abono mensual", Icon = "📆", Price = 60, Days = 28 },
	{ Id = "Estudiante", Name = "Abono estudiante (mensual)", Icon = "🎓", Price = 25, Days = 28, Student = true },
	{ Id = "Trabajador", Name = "Abono trabajador (mensual)", Icon = "💼", Price = 40, Days = 28, Worker = true },
}
Metro.passById = {} :: { [string]: any }
for _, p in Metro.Passes do
	Metro.passById[p.Id] = p
end
-- Trabajos con los que el metro sale gratis (van de servicio)
Metro.FreeJobs = { Revisor = true, Policia = true, Guardia = true, Bombero = true, Medico = true }
Metro.StudentStages = { Adolescente = true, AdultoJoven = true }

---------------------------------------------------------------------
-- Planificador de rutas (plano del metro, móvil y "Cómo llegar")
---------------------------------------------------------------------
Metro.TransferSeconds = 45 -- cambiar de línea en Plaza Mayor (andar + escaleras)
Metro.WalkSpeed = 16 -- studs por segundo andando
Metro.MetersPerStud = 0.28

local centersCache: { [string]: { number } } = {}
local function lineCenters(line: Line): { number }
	local c = centersCache[line.Id]
	if not c then
		local _, centers = Metro.path(line)
		c = centers
		centersCache[line.Id] = c
	end
	return c
end

-- Segundos de viaje entre dos estaciones seguidas de una línea (sin la parada)
function Metro.hopSeconds(line: Line, i: number, j: number): number
	local c = lineCenters(line)
	return Metro.travelTime(math.abs(c[j] - c[i]))
end

-- Líneas que paran en una estación
function Metro.linesAt(stationId: string): { Line }
	local list = {}
	for _, line in Metro.Lines do
		if table.find(line.Stations, stationId) then
			table.insert(list, line)
		end
	end
	return list
end

export type Leg = { Line: string, From: string, To: string, Stops: { string }, Seconds: number }
export type Route = { Legs: { Leg }, Seconds: number, Transfers: number }

-- La ruta más rápida entre dos estaciones: líneas, transbordos, paradas y tiempo aproximado
function Metro.route(fromId: string, toId: string): Route?
	if not Metro.Stations[fromId] or not Metro.Stations[toId] then
		return nil
	end
	if fromId == toId then
		return { Legs = {}, Seconds = 0, Transfers = 0 }
	end
	-- Nodos: "L1|Poniente". Dijkstra sencillo (la red es pequeña)
	local dist: { [string]: number } = {}
	local prev: { [string]: string } = {}
	local done: { [string]: boolean } = {}
	local function key(lineId: string, st: string): string
		return lineId .. "|" .. st
	end
	for _, line in Metro.linesAt(fromId) do
		dist[key(line.Id, fromId)] = 0
	end
	while true do
		local best, bestD = nil, math.huge
		for k, d in dist do
			if not done[k] and d < bestD then
				best, bestD = k, d
			end
		end
		if not best then
			break
		end
		done[best] = true
		local lineId, st = string.match(best, "^(.-)|(.+)$")
		local line = Metro.lineById[lineId :: string]
		if st == toId then
			-- Reconstruir los tramos
			local nodes = {}
			local cur: string? = best
			while cur do
				table.insert(nodes, 1, cur)
				cur = prev[cur]
			end
			local legs: { Leg } = {}
			local leg: Leg? = nil
			local lastSeconds = 0
			for _, node in nodes do
				local l, s = string.match(node, "^(.-)|(.+)$")
				local t = dist[node]
				if not leg or leg.Line ~= l then
					if leg then
						table.insert(legs, leg)
					end
					leg = { Line = l :: string, From = s :: string, To = s :: string, Stops = { s :: string }, Seconds = 0 }
					lastSeconds = t
				else
					leg.To = s :: string
					table.insert(leg.Stops, s :: string)
					leg.Seconds += t - lastSeconds
					lastSeconds = t
				end
			end
			if leg then
				table.insert(legs, leg)
			end
			-- (un tramo de una sola parada es el transbordo: fuera)
			local clean = {}
			for _, l in legs do
				if #l.Stops > 1 then
					table.insert(clean, l)
				end
			end
			return { Legs = clean, Seconds = math.floor(bestD + 0.5), Transfers = math.max(0, #clean - 1) }
		end
		local i = table.find(line.Stations, st) :: number
		local function relax(k: string, d: number)
			if not done[k] and d < (dist[k] or math.huge) then
				dist[k] = d
				prev[k] = best :: string
			end
		end
		for _, j in { i - 1, i + 1 } do
			if j >= 1 and j <= #line.Stations then
				relax(key(line.Id, line.Stations[j]), bestD + Metro.hopSeconds(line, i, j) + (if line.Stations[j] == toId then 0 else Metro.Dwell))
			end
		end
		for _, other in Metro.linesAt(st :: string) do
			if other.Id ~= line.Id then
				relax(key(other.Id, st :: string), bestD + Metro.TransferSeconds)
			end
		end
	end
	return nil
end

-- Estación más cercana a un punto (por la boca de la calle): id y distancia en studs
function Metro.nearestStation(position: Vector3): (string?, number)
	local best, bestD = nil, math.huge
	for id in Metro.Stations do
		local ok, access = pcall(Metro.access, id)
		local p = if ok and access then access.Stair.Top else Vector3.new(Metro.Stations[id].Surface[1], Metro.StreetY, Metro.Stations[id].Surface[2])
		local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
		if d < bestD then
			best, bestD = id, d
		end
	end
	return best, bestD
end

-- Dónde está la boca de metro de una estación (para el GPS)
function Metro.entrance(stationId: string): Vector3
	local ok, access = pcall(Metro.access, stationId)
	if ok and access then
		return access.Stair.Top
	end
	local s = Metro.Stations[stationId]
	return Vector3.new(s.Surface[1], Metro.StreetY, s.Surface[2])
end

-- Textos: "450 m", "≈ 30 s andando", "3 min 20 s"
function Metro.meters(studs: number): string
	local m = studs * Metro.MetersPerStud
	if m >= 1000 then
		return ("%.1f km"):format(m / 1000)
	end
	return ("%d m"):format(math.floor(m / 10 + 0.5) * 10)
end
function Metro.duration(seconds: number): string
	seconds = math.max(0, math.floor(seconds + 0.5))
	if seconds < 60 then
		return ("%d s"):format(seconds)
	end
	local m, s = seconds // 60, seconds % 60
	return if s == 0 then ("%d min"):format(m) else ("%d min %d s"):format(m, s)
end

---------------------------------------------------------------------
-- Megafonía
---------------------------------------------------------------------
function Metro.announceNext(line: Line, stationId: string): string
	local text = "Próxima estación: " .. Metro.Stations[stationId].Name .. "."
	local others = {}
	for _, l in Metro.linesAt(stationId) do
		if l.Id ~= line.Id then
			table.insert(others, l.Name)
		end
	end
	if #others > 0 then
		text ..= " Correspondencia con " .. table.concat(others, " y ") .. "."
	end
	return text
end
Metro.AnnounceDoors = "Las puertas van a cerrarse."
Metro.AnnounceSafety = "Por favor, manténganse detrás de la línea de seguridad."
function Metro.announceArriving(line: Line, towardName: string): string
	return ("Tren de la %s con destino %s. Por favor, manténganse detrás de la línea amarilla."):format(line.Name, towardName)
end

return Metro
