-- PlaceLife: la "vida por lugar". Qué hace la gente en cada tipo de sitio de Valmar (parque, playa,
-- plaza, paradas de bus, bocas de metro, puerta del colegio, hospital, centro comercial, mercado,
-- puerto, campus, gasolinera, tiendas, oficinas, estaciones y bancos de la calle), a qué horas, qué día
-- de la semana y con qué tiempo.
-- Solo son datos y cuentas (sin Roblox): los usa el servidor (Services/PlaceLifeService) para poner a
-- la gente cerca de los jugadores, y las pruebas.
--
--   PlaceLife.Places[tipo]       -> cómo se encuentra en el mapa (Tags / Models), dónde se ponen
--                                   (Shape), cuánta gente cabe (Slots) y qué hacen (Activities)
--   PlaceLife.Activities[nombre] -> la actividad: sentarse, charlar en grupo, correr, perro, toalla…
--   PlaceLife.amount(tipo, hora, tiempo, díaSemana?) -> cuánta gente hay ahora (0..Slots; más el finde)
--   PlaceLife.allowed(tipo, hora, tiempo)         -> las actividades que pegan ahora (con su peso)
--   PlaceLife.pick(tipo, hora, tiempo, r?)        -> una actividad al azar de esas (r: 0..1)
--   PlaceLife.umbrella(tiempo)                    -> ¿se saca el paraguas?

local PlaceLife = {}

-- Presupuesto (pensado para móvil): solo cerca de los jugadores y con topes
PlaceLife.Radius = 200 -- solo se llenan los sitios a menos de esto de algún jugador
PlaceLife.Keep = 240 -- y se vacían cuando ya no hay nadie a menos de esto
PlaceLife.PlayerBudget = 40 -- como mucho, gente del servidor a menos de Radius de cada jugador (con CrowdService)
PlaceLife.GlobalCap = 90 -- en todo el servidor (solo la de este sistema)
PlaceLife.SpawnPerTick = 4 -- grupos nuevos por vuelta (aparecen poco a poco, no de golpe)
PlaceLife.MinGap = 5 -- nadie aparece a menos de esto de un jugador
PlaceLife.FrontGap = 30 -- ni a menos de esto delante de él (si se puede evitar)
PlaceLife.FrontCone = 0.5 -- (lo que cuenta como "delante": unos 60° a cada lado)
PlaceLife.Tick = 2
PlaceLife.ChatterEvery = 6 -- segundos entre frase y frase (una sola a la vez en todo el servidor)

-- Tiempos que mojan (se saca el paraguas y sale menos gente)
local WET = { Lluvia = true, Tormenta = true, Nieve = true, Rain = true, Storm = true, Snow = true }

function PlaceLife.wet(weather: string?): boolean
	return weather ~= nil and WET[weather] == true
end

function PlaceLife.umbrella(weather: string?): boolean
	return weather == "Lluvia" or weather == "Tormenta" or weather == "Rain" or weather == "Storm"
end

export type Activity = {
	Pose: string?, -- "Sit" (en un banco) | "Lie" (en la toalla)
	Works: { string }?, -- tareas de Npc.work (Book, Phone, Coffee, Watch, Knit, Count, Carry, Call…)
	Size: { number }?, -- grupo de { mín, máx } personas
	Walk: string?, -- "Loop" (vuelta alrededor) | "Line" (de un punto a otro)
	Speed: number?,
	Dog: boolean?,
	Towel: boolean?,
	Ball: boolean?,
	Boules: boolean?, -- petanca (bolas en el suelo)
	CardTable: boolean?, -- mesita de cartas con taburetes
	Kids: boolean?,
	Lead: string?, -- el primero hace esto (Guitar: músico) y los demás le miran (su público)
	Pair: boolean?, -- van de dos en dos, uno al lado del otro
	Queue: boolean?, -- en fila delante de la puerta
	Uniform: boolean?, -- con ropa de trabajo (en su descanso)
	Elders: boolean?,
	Dry: boolean?, -- solo sin lluvia
	Hours: { number }?, -- solo a estas horas
	Lines: string, -- frases (PlaceLife.Lines)
}

PlaceLife.Activities = {
	Banco = { Pose = "Sit", Works = { "Book", "Phone", "Knit", "Coffee" }, Lines = "Banco" } :: Activity,
	Charla = { Size = { 2, 4 }, Works = { "Coffee", "Phone" }, Lines = "Charla" } :: Activity,
	Correr = { Walk = "Loop", Speed = 13, Dry = true, Hours = { 6.5, 22 }, Lines = "Correr" } :: Activity,
	Perro = { Walk = "Line", Speed = 4.5, Dog = true, Hours = { 6.5, 23.5 }, Lines = "Perro" } :: Activity,
	Pasear = { Walk = "Line", Speed = 5, Lines = "Pasear" } :: Activity,
	Leer = { Works = { "Book" }, Lines = "Leer" } :: Activity,
	Fotos = { Works = { "Phone" }, Walk = "Line", Speed = 3.5, Hours = { 8, 21.5 }, Lines = "Fotos" } :: Activity,
	Toalla = { Pose = "Lie", Towel = true, Dry = true, Hours = { 9, 20.5 }, Lines = "Playa" } :: Activity,
	Pelota = { Kids = true, Size = { 2, 3 }, Ball = true, Dry = true, Hours = { 9, 20.5 }, Lines = "Pelota" } :: Activity,
	Petanca = { Elders = true, Size = { 2, 4 }, Boules = true, Works = { "Watch" }, Dry = true, Hours = { 9, 20.5 }, Lines = "Petanca" } :: Activity,
	Cartas = { Elders = true, Size = { 2, 4 }, CardTable = true, Works = { "Count" }, Dry = true, Hours = { 10, 21 }, Lines = "Cartas" } :: Activity,
	Puesto = { Works = { "Carry", "Count" }, Hours = { 8, 21.5 }, Lines = "Puesto" } :: Activity,
	EsperarBus = { Works = { "Phone", "Watch", "Book" }, Lines = "Bus" } :: Activity,
	EsperarMetro = { Works = { "Phone", "Watch" }, Lines = "Metro" } :: Activity,
	Recoger = { Works = { "Phone", "Watch" }, Hours = { 8, 17 }, Lines = "Colegio" } :: Activity,
	Llamar = { Works = { "Call", "Phone" }, Lines = "Hospital" } :: Activity,
	Compras = { Works = { "Carry", "Phone" }, Walk = "Line", Speed = 4.5, Lines = "Compras" } :: Activity,
	Pescar = { Works = { "Watch" }, Dry = true, Hours = { 6, 21 }, Lines = "Puerto" } :: Activity,
	Estudiar = { Works = { "Book", "Phone" }, Lines = "Campus" } :: Activity,
	Repostar = { Works = { "Phone", "Watch" }, Lines = "Gasolinera" } :: Activity,
	Musico = { Lead = "Guitar", Size = { 1, 4 }, Dry = true, Hours = { 10, 22.5 }, Lines = "Musico" } :: Activity,
	Pareja = { Pair = true, Size = { 2, 2 }, Walk = "Line", Speed = 4.2, Lines = "Pareja" } :: Activity,
	Cola = { Queue = true, Size = { 2, 5 }, Works = { "Phone", "Watch", "Carry" }, Lines = "Cola" } :: Activity,
	Descanso = { Uniform = true, Size = { 1, 3 }, Works = { "Coffee", "Phone" }, Lines = "Descanso" } :: Activity,
	Reparto = { Works = { "Phone" }, Lines = "Reparto" } :: Activity,
	Viajar = { Works = { "Carry", "Watch", "Phone" }, Walk = "Line", Speed = 5, Lines = "Estacion" } :: Activity,
}

-- Frases cortas (bocadillos de vez en cuando). TimeContext quita las que no pegan con la hora o el tiempo.
PlaceLife.Lines = {
	Banco = { "Qué a gusto se está aquí.", "Me encanta este libro.", "Un ratito de descanso.", "¡Qué buen día hace!" },
	Charla = { "¿Y tú qué tal?", "¡No me digas!", "Pues eso le dije yo.", "Hay que quedar más.", "¿Has visto el partido?", "Ja, ja, ¡qué bueno!" },
	Correr = { "¡Una vuelta más!", "Uf… ¡qué cansancio!", "Cinco kilómetros ya." },
	Perro = { "¡Ven aquí, Toby!", "¡No te comas eso!", "¡Buen chico!", "Vamos, que es tarde." },
	Pasear = { "Qué bonito está esto.", "Vamos dando un paseo.", "Mira, ya han abierto la heladería." },
	Leer = { "Un capítulo más…", "Qué final tan raro." },
	Fotos = { "¡Qué vistas!", "Esta para el móvil.", "Sonríe… ¡ya!" },
	Playa = { "¡Qué calor!", "¿Me pasas la crema?", "El agua está buenísima.", "Qué bonito está el mar." },
	Pelota = { "¡Pásamela!", "¡Gol!", "¡Te toca!", "¡Mamá, mira!" },
	Petanca = { "¡Arrimada!", "Esa ha quedado lejos…", "Me toca a mí.", "En mis tiempos…" },
	Cartas = { "¡Cante las cuarenta!", "Paso.", "Esta mano es mía.", "Baraja tú." },
	Puesto = { "¿A cómo están los tomates?", "Póngame medio kilo.", "¡Qué buena pinta!", "¿Me cobra?" },
	Bus = { "¿Cuánto faltará?", "Ya debería haber pasado…", "¿Este va al centro?", "Menos mal que traje el móvil." },
	Metro = { "Te espero abajo.", "¿Tienes el billete?", "Llego en diez minutos." },
	Colegio = { "¿Qué tal el cole?", "Ya salen los niños.", "¡Aquí, cariño!", "Hoy tienen excursión." },
	Hospital = { "Ya le han visto, está bien.", "Mañana le dan el alta.", "¿Dónde es urgencias?" },
	Compras = { "Me lo he comprado todo.", "Estaba de rebajas.", "¿Vamos a por un helado?" },
	Puerto = { "Hoy no pican…", "Mira qué barco tan grande.", "Huele a mar." },
	Campus = { "Mañana hay examen…", "¿Me dejas los apuntes?", "Voy a la biblioteca." },
	Gasolinera = { "Lleno, por favor.", "Qué cara está la gasolina.", "Me pido un café para el camino." },
	Musico = { "¡Gracias, gracias!", "Esta va por Valmar.", "¡Qué bien toca!", "Otra, otra." },
	Pareja = { "¿Cenamos fuera?", "Te quiero.", "¿Vamos al cine luego?", "Mira qué bonito." },
	Cola = { "Esta cola no avanza…", "¿Es usted la última?", "Hoy hay mucha gente.", "Merece la pena, ya verás." },
	Descanso = { "Cinco minutos y vuelvo.", "Qué ganas de que sea viernes.", "Hoy no para de entrar gente." },
	Reparto = { "¡Pedido para el tercero!", "Me quedan tres entregas.", "¿Es aquí el número doce?" },
	Estacion = { "Que pierdo el tren…", "¿De qué andén sale?", "Llevo la maleta a rastras." },
	Lluvia = { "¡Vaya chaparrón!", "Menos mal que traje el paraguas.", "Esto no para…" },
	Noche = { "Qué tarde se ha hecho.", "Me voy a casa.", "Buenas noches." },
}

export type Place = {
	Label: string,
	Tags: { string }?, -- piezas o modelos con esta etiqueta
	Models: { string }?, -- modelos del mapa con este nombre (dentro de workspace.Town)
	Shape: string, -- "Area" (dentro de su caja) | "Ring" (alrededor de un punto) | "Around" (junto a un edificio)
	Min: number?, -- (Ring/Around) distancia mínima y máxima
	Max: number?,
	MinSize: number?, -- (Area) caja mínima para contar
	Slots: number, -- gente como mucho en cada sitio
	Night: number?, -- lo que queda de noche (0..1; por defecto 0.15)
	Rain: number?, -- lo que queda con lluvia (0..1; por defecto 0.35)
	Hours: { number }?, -- horario (OpeningHours): fuera de él casi nadie
	Peak: { { number } }?, -- horas punta (fuera de ellas, OffPeak)
	OffPeak: number?,
	Every: number?, -- solo uno de cada N sitios (bancos de la calle: no todos a la vez)
	Weekend: number?, -- sábado y domingo: más gente (> 1) o menos (< 1)
	Activities: { [string]: number }, -- actividad -> peso
}

PlaceLife.Places = {
	Parque = {
		Label = "Parque", Models = { "Parque", "Jardin" }, Shape = "Area", MinSize = 30, Slots = 12, Night = 0.1, Rain = 0.25,
		Weekend = 1.35,
		Activities = { Charla = 3, Correr = 2, Perro = 2, Pasear = 2, Pareja = 2, Leer = 1, Fotos = 1, Pelota = 2, Petanca = 1, Cartas = 1, Musico = 1 },
	} :: Place,
	Playa = {
		Label = "Playa", Models = { "Playa" }, Shape = "Area", MinSize = 30, Slots = 14, Night = 0.05, Rain = 0.08,
		Weekend = 1.4,
		Activities = { Toalla = 5, Charla = 2, Correr = 1, Pelota = 2, Pasear = 2, Pareja = 1, Fotos = 1, Perro = 1 },
	} :: Place,
	Plaza = {
		Label = "Plaza", Models = { "Plaza", "PlazaFinanciera" }, Shape = "Area", MinSize = 20, Slots = 10, Night = 0.25, Rain = 0.3,
		Weekend = 1.3,
		Activities = { Charla = 4, Fotos = 2, Pasear = 3, Pareja = 2, Perro = 1, Cartas = 1, Petanca = 1, Musico = 2 },
	} :: Place,
	ParadaBus = {
		Label = "Parada de bus", Tags = { "BusStop", "TravelStop" }, Shape = "Ring", Min = 2.5, Max = 7, Slots = 3, Night = 0.3, Rain = 0.8,
		Activities = { EsperarBus = 5, Charla = 1 },
	} :: Place,
	BocaMetro = {
		Label = "Boca de metro", Tags = { "MetroEntrance" }, Shape = "Ring", Min = 5, Max = 11, Slots = 3, Night = 0.3, Rain = 0.6,
		Activities = { EsperarMetro = 3, Charla = 2, Pasear = 1, Musico = 1 },
	} :: Place,
	Colegio = {
		Label = "Colegio", Tags = { "SchoolEntrance" }, Shape = "Ring", Min = 6, Max = 16, Slots = 8, Night = 0, Rain = 0.6,
		Peak = { { 8, 9.25 }, { 13.75, 15.25 }, { 16.75, 17.5 } }, OffPeak = 0.15, -- (a la entrada y a la salida)
		Weekend = 0, -- (sábado y domingo no hay cole)
		Activities = { Recoger = 4, Charla = 3, Pelota = 1 },
	} :: Place,
	Hospital = {
		Label = "Hospital", Models = { "Hospital", "CentroSalud" }, Shape = "Around", Min = 3, Max = 9, Slots = 5, Night = 0.4, Rain = 0.5,
		Activities = { Llamar = 3, Charla = 2, Pasear = 1 },
	} :: Place,
	CentroComercial = {
		Label = "Centro comercial", Models = { "CentroComercial", "GranCentroComercial" }, Shape = "Around", Min = 3, Max = 10, Slots = 8, Night = 0.1, Rain = 0.5,
		Hours = { 10, 22 }, Weekend = 1.4,
		Activities = { Compras = 4, Charla = 2, Pareja = 1, Cola = 1, Reparto = 1, Fotos = 1 },
	} :: Place,
	Mercado = {
		Label = "Mercado", Tags = { "FoodStand" }, Shape = "Ring", Min = 3, Max = 7, Slots = 3, Night = 0.1, Rain = 0.4,
		Hours = { 8, 22 },
		Weekend = 1.3,
		Activities = { Puesto = 4, Cola = 2, Charla = 1 },
	} :: Place,
	Puerto = {
		Label = "Puerto", Models = { "Puerto", "Marina" }, Shape = "Area", MinSize = 20, Slots = 6, Night = 0.15, Rain = 0.2,
		Activities = { Pescar = 3, Fotos = 2, Pasear = 2, Charla = 1 },
	} :: Place,
	Campus = {
		Label = "Campus", Models = { "Facultad" }, Shape = "Around", Min = 3, Max = 12, Slots = 8, Night = 0.2, Rain = 0.4,
		Hours = { 8, 21 },
		Weekend = 0.4,
		Activities = { Estudiar = 3, Charla = 3, Correr = 1, Leer = 1, Pareja = 1, Musico = 1 },
	} :: Place,
	Gasolinera = {
		Label = "Gasolinera", Tags = { "FuelPump" }, Shape = "Ring", Min = 3, Max = 6, Slots = 2, Night = 0.35, Rain = 0.7,
		Activities = { Repostar = 3, Llamar = 1 },
	} :: Place,
	Tienda = {
		Label = "Tienda de la calle", Tags = { "Shop" }, Shape = "Front", Min = 1.5, Max = 6, Slots = 4, Night = 0.05, Rain = 0.5,
		Hours = { 9.5, 21.5 }, Peak = { { 11.5, 14 }, { 18, 21 } }, OffPeak = 0.45, Weekend = 1.3,
		Activities = { Cola = 3, Descanso = 1, Reparto = 1, Charla = 1, Compras = 1 },
	} :: Place,
	Oficinas = {
		Label = "Oficinas", Models = { "Oficinas", "Rascacielos", "TorreValmar" }, Shape = "Around", Min = 3, Max = 9, Slots = 5, Night = 0.05, Rain = 0.4,
		Peak = { { 8, 9.5 }, { 10.5, 11.5 }, { 13.5, 15 }, { 17.5, 19 } }, OffPeak = 0.35, Weekend = 0.2,
		Activities = { Descanso = 4, Llamar = 2, Charla = 2, Reparto = 1 },
	} :: Place,
	Estacion = {
		Label = "Estación", Models = { "EstacionCentral", "EstacionAutobuses" }, Shape = "Around", Min = 3, Max = 10, Slots = 8, Night = 0.25, Rain = 0.7,
		Peak = { { 7, 9.5 }, { 13, 15 }, { 17.5, 20 } }, OffPeak = 0.6,
		Activities = { Viajar = 4, EsperarBus = 2, Charla = 2, Musico = 1, Pareja = 1 },
	} :: Place,
	BancoCalle = {
		Label = "Banco de la calle", Tags = { "Bench" }, Shape = "Ring", Min = 0, Max = 0, Slots = 1, Night = 0.1, Rain = 0.15,
		Every = 3, -- (uno de cada tres: CrowdService ya pone gente en otro de cada tres)
		Activities = { Banco = 1 },
	} :: Place,
}

-- Orden fijo de los tipos (para recorrerlos siempre igual)
PlaceLife.Order = { "Parque", "Playa", "Plaza", "ParadaBus", "BocaMetro", "Colegio", "Hospital", "CentroComercial", "Mercado", "Puerto", "Campus", "Gasolinera", "Tienda", "Oficinas", "Estacion", "BancoCalle" }

local function within(hours: { number }, hour: number): boolean
	local from, to = hours[1], hours[2]
	if from <= to then
		return hour >= from and hour < to
	end
	return hour >= from or hour < to
end
PlaceLife.within = within

-- Lo que queda de gente a esta hora (1 = todo, de día)
function PlaceLife.timeFactor(place: Place, hour: number): number
	local f = 1
	if place.Hours and not within(place.Hours, hour) then
		f = 0.1 -- (cerrado: algún rezagado en la puerta)
	end
	if place.Peak then
		local peak = false
		for _, window in place.Peak do
			peak = peak or within(window, hour)
		end
		if not peak then
			f *= place.OffPeak or 0.2
		end
	end
	if hour < 6.5 or hour >= 22 then
		f *= (place.Night or 0.15) * (if hour >= 1 and hour < 6 then 0.5 else 1) -- (de madrugada, aún menos)
	elseif hour >= 20.5 or hour < 7.5 then
		f *= 0.4 + 0.6 * (place.Night or 0.15) -- (anochecer y amanecer: a medias)
	end
	return f
end

-- Lo que queda de gente con este tiempo
function PlaceLife.weatherFactor(place: Place, weather: string?): number
	if weather == "Tormenta" or weather == "Storm" then
		return (place.Rain or 0.35) * 0.5
	elseif PlaceLife.wet(weather) then
		return place.Rain or 0.35
	elseif weather == "Niebla" or weather == "Fog" then
		return 0.8
	elseif weather == "Nublado" or weather == "Cloudy" then
		return if place.Label == "Playa" then 0.45 else 0.9
	end
	return 1
end

-- Cuánta gente hay ahora en un sitio de ese tipo (número entero, 0..Slots)
-- weekday: 1 = lunes … 7 = domingo (GameClock); sábado y domingo cambia según el sitio (Weekend)
function PlaceLife.amount(kind: string, hour: number, weather: string?, weekday: number?): number
	local place = PlaceLife.Places[kind]
	if not place then
		return 0
	end
	local weekend = if weekday and weekday >= 6 then (place.Weekend or 1) else 1
	local n = place.Slots * PlaceLife.timeFactor(place, hour) * PlaceLife.weatherFactor(place, weather) * weekend
	return math.clamp(math.floor(n + 0.5), 0, math.ceil(place.Slots * math.max(1, weekend)))
end

-- ¿Pega esta actividad ahora?
function PlaceLife.fits(activity: Activity, hour: number, weather: string?): boolean
	if activity.Dry and PlaceLife.wet(weather) then
		return false
	end
	if activity.Hours and not within(activity.Hours, hour) then
		return false
	end
	return true
end

-- Las actividades de ese sitio que pegan ahora: { { Name, Weight } } (en orden fijo)
function PlaceLife.allowed(kind: string, hour: number, weather: string?): { { Name: string, Weight: number } }
	local place = PlaceLife.Places[kind]
	local list = {}
	if not place then
		return list
	end
	local names = {}
	for name in place.Activities do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local weight = place.Activities[name]
		local activity = PlaceLife.Activities[name]
		if activity and weight > 0 and PlaceLife.fits(activity, hour, weather) then
			table.insert(list, { Name = name, Weight = weight })
		end
	end
	return list
end

-- Una actividad al azar (según su peso) de las que pegan ahora; r: número de 0 a 1 (por defecto, al azar)
function PlaceLife.pick(kind: string, hour: number, weather: string?, r: number?): string?
	local list = PlaceLife.allowed(kind, hour, weather)
	local total = 0
	for _, entry in list do
		total += entry.Weight
	end
	if total <= 0 then
		return nil
	end
	local roll = (r or math.random()) * total
	for _, entry in list do
		roll -= entry.Weight
		if roll <= 0 then
			return entry.Name
		end
	end
	return list[#list].Name
end

-- Cuántas personas lleva una actividad (grupos de 2 a 4…)
function PlaceLife.groupSize(name: string, r: number?): number
	local activity = PlaceLife.Activities[name]
	local size = activity and activity.Size
	if not size then
		return 1
	end
	return size[1] + math.floor((r or math.random()) * (size[2] - size[1] + 1) * 0.999)
end

return PlaceLife
