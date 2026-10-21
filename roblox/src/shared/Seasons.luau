-- Seasons: las estaciones del año y el tiempo que hace (sol, nubes, lluvia, tormenta, nieve, niebla).
-- Es "puro" (no toca el juego): lo usan el servidor (WeatherService decide el tiempo y lo publica en
-- workspace) y cada jugador (Controllers/Weather lo pinta: lluvia, nieve, hojas, colores; y
-- Controllers/Wildlife decide qué animales salen). Todo el servidor ve el mismo tiempo.
--
-- Estaciones v126 (docs/clima/estaciones.md, petición del dueño: «estaciones del año en Valmar»):
--   * Van con el CALENDARIO del juego (la fecha que sale en el HUD, «sáb 6 ene»): diciembre, enero y
--     febrero son invierno; marzo-mayo, primavera; junio-agosto, verano; septiembre-noviembre, otoño
--     (Valmar es mediterránea: Config.Seasons.Mode = "Calendario"). Con Mode = "Rapido" vuelve el ciclo
--     corto de antes (una estación cada Config.Seasons.DaysPerSeason días).
--   * Cambian POCO A POCO: los últimos y los primeros días de cada estación se mezclan con la vecina
--     (Seasons.blendAt: colores, temperatura y probabilidad de cada tiempo, sin saltos).
--   * Cada estación: su temperatura (mínima y máxima del día), la altura del sol (Latitude), el tono de
--     la luz (Warm / Cold), lo que llueve, el color de las hojas (verde, flores en primavera, amarillo,
--     naranja y rojo en otoño, copas más claras y peladas en invierno), la ropa de la gente y la playa.
--
-- El tiempo cambia cada Config.Seasons.WeatherHours horas de juego, al azar pero igual para todos
-- (depende del día y la hora).

local Config = require(script.Parent.Config)

local Seasons = {}

local rgb = Color3.fromRGB

export type SeasonId = "Primavera" | "Verano" | "Otono" | "Invierno"
export type WeatherId = "Despejado" | "Intervalos" | "Nublado" | "Lluvia" | "Tormenta" | "Nieve" | "Niebla"

Seasons.Order = { "Primavera", "Verano", "Otono", "Invierno" }
-- Orden fijo de los tiempos (el sorteo no depende del orden de las tablas)
Seasons.WeatherOrder = { "Despejado", "Intervalos", "Nublado", "Lluvia", "Tormenta", "Nieve", "Niebla" }

-- Cómo es cada estación: probabilidad de cada tiempo, color de la hierba y de las hojas,
-- y cuántos animales se ven (1 = lo normal).
-- (Hierba, paisaje v118: verdes vivos todo el año, como la isla mediterránea de la referencia del
-- dueño: el invierno es lluvioso y verde, el verano algo más cálido; antes el verano y el invierno
-- dejaban el campo color paja o gris)
-- Clima mediterráneo (v126): verano seco y caluroso con alguna tormenta de tarde, otoño de nubes y
-- lluvia, invierno suave y lluvioso con NIEVE MUY RARA (algún día suelto), primavera variable.
--   Temp: { mínima de madrugada, máxima de la tarde } en °C, con el cielo despejado.
--   Latitude: Lighting.GeographicLatitude (la altura del sol: alto en verano, bajo en invierno).
--   Leaves / LeafMix: color de las copas y cuánto se mezcla con el suyo. Autumn: colores sueltos para
--   que cada árbol tenga el suyo (amarillo, naranja, rojo). Bare (0..1): copas más claras y peladas.
--   Blossom (0..1): parte de los árboles con flores; BlossomColors: rosa y blanco.
--   Beach: gente en la playa (1 = verano). Coats / ShortSleeves: parte de la gente con abrigo o manga corta.
Seasons.Info = {
	Primavera = {
		Name = "Primavera", Icon = "🌸",
		Weather = { Despejado = 34, Intervalos = 26, Nublado = 14, Lluvia = 18, Tormenta = 5, Niebla = 3 },
		Grass = rgb(86, 150, 58), Leaves = rgb(110, 176, 80), LeafMix = 0.25,
		Particles = "Petalos", Birds = 1.2, Butterflies = 1, Ground = 1,
		Temp = { 10, 21 }, Latitude = 37,
		Blossom = 0.35, BlossomColors = { rgb(246, 186, 210), rgb(250, 238, 244), rgb(236, 160, 196) },
		Bare = 0, Beach = 0.45, Coats = 0.1, ShortSleeves = 0.3,
	},
	Verano = {
		Name = "Verano", Icon = "☀️",
		Weather = { Despejado = 60, Intervalos = 24, Nublado = 4, Lluvia = 3, Tormenta = 8, Niebla = 1 },
		Grass = rgb(108, 146, 60), Leaves = rgb(70, 124, 52), LeafMix = 0.2,
		Particles = nil, Birds = 1, Butterflies = 1.3, Ground = 1,
		Warm = 0.12, -- luz algo más cálida
		Temp = { 21, 32 }, Latitude = 30,
		Blossom = 0, Bare = 0, Beach = 1, Coats = 0, ShortSleeves = 0.85,
	},
	Otono = {
		Name = "Otoño", Icon = "🍂",
		Weather = { Despejado = 20, Intervalos = 22, Nublado = 20, Lluvia = 24, Tormenta = 8, Niebla = 6 },
		Grass = rgb(114, 134, 62), Leaves = rgb(214, 118, 40), LeafMix = 0.7,
		Autumn = { rgb(222, 178, 52), rgb(214, 118, 40), rgb(186, 62, 36), rgb(160, 120, 48) },
		Particles = "Hojas", Birds = 0.7, Butterflies = 0, Ground = 1,
		Warm = 0.05,
		Temp = { 11, 21 }, Latitude = 40,
		Blossom = 0, Bare = 0.15, Beach = 0.25, Coats = 0.35, ShortSleeves = 0.1,
	},
	Invierno = {
		Name = "Invierno", Icon = "❄️",
		Weather = { Despejado = 26, Intervalos = 18, Nublado = 24, Lluvia = 20, Tormenta = 3, Niebla = 6, Nieve = 3 },
		Grass = rgb(86, 128, 66), Leaves = rgb(96, 104, 86), LeafMix = 0.55,
		Particles = nil, Birds = 0.4, Butterflies = 0, Ground = 0.7,
		Cold = 0.1, -- luz algo más fría
		Temp = { 4, 13 }, Latitude = 46,
		Blossom = 0, Bare = 0.55, BareColor = rgb(132, 112, 88), Beach = 0.08, Coats = 0.85, ShortSleeves = 0,
	},
}

-- Cómo cambia el cielo con cada tiempo (DayLight lo mezcla con la luz de la hora: shared/DayGrade.weather)
--   Cover: nubes (0..1; nil = las de la hora). Brightness: luz del sol. Density: bruma.
--   Dark (0..1, v126): lo oscuras y bajas que son las nubes (cubierto gris 0,15; lluvia 0,45;
--   tormenta 0,85: «nubes muy oscuras»). Rain / Snow: lo que cae. Lightning: relámpagos.
Seasons.Weather = {
	Despejado = { Name = "Despejado", Icon = "☀️", Cover = nil, Brightness = 1, Saturation = 0, Density = 0 },
	Intervalos = { Name = "Poco nuboso", Icon = "⛅", Cover = 0.62, Brightness = 0.95, Saturation = -0.02, Density = 0.01 },
	Nublado = { Name = "Nublado", Icon = "☁️", Cover = 0.8, Brightness = 0.78, Saturation = -0.1, Density = 0.04, Dark = 0.15 },
	Lluvia = { Name = "Lluvia", Icon = "🌧️", Cover = 0.88, Brightness = 0.6, Saturation = -0.18, Density = 0.08, Rain = 1, Wet = true, Dark = 0.45 },
	Tormenta = { Name = "Tormenta", Icon = "⛈️", Cover = 0.94, Brightness = 0.42, Saturation = -0.25, Density = 0.1, Rain = 1.7, Lightning = true, Wet = true, Dark = 0.85 },
	Nieve = { Name = "Nieve", Icon = "🌨️", Cover = 0.85, Brightness = 0.85, Saturation = -0.12, Density = 0.1, Snow = 1, Dark = 0.1 },
	Niebla = { Name = "Niebla", Icon = "🌫️", Cover = 0.6, Brightness = 0.8, Saturation = -0.15, Density = 0.35 },
}

local function config(): { [string]: any }
	return Config.Seasons or { DaysPerSeason = 7, WeatherHours = 6, Start = "Primavera" }
end

local function calendar(): { [string]: number }
	return Config.Calendar or { DaysPerWeek = 7, DaysPerMonth = 28, MonthsPerYear = 12 }
end

-- ¿Van las estaciones con el calendario (los meses del HUD)? (Config.Seasons.Mode; por defecto sí)
function Seasons.calendarMode(): boolean
	return config().Mode ~= "Rapido"
end

-- Mes del calendario (1..12) y día del mes (1..28) de un día de juego (como GameClock.fromDay)
function Seasons.monthOf(day: number): (number, number)
	local cal = calendar()
	local index = math.max(math.floor(day), 1) - 1
	local perYear = cal.DaysPerMonth * cal.MonthsPerYear
	return (index % perYear) // cal.DaysPerMonth + 1, index % cal.DaysPerMonth + 1
end

-- Mes con el que empieza cada estación (calendario mediterráneo, hemisferio norte)
local STARTS = { Invierno = 12, Primavera = 3, Verano = 6, Otono = 9 }
local BY_MONTH = { "Invierno", "Invierno", "Primavera", "Primavera", "Primavera", "Verano", "Verano", "Verano", "Otono", "Otono", "Otono", "Invierno" }

-- Dónde está un día dentro de su estación: (estación, días desde que empezó (0..), días que dura)
function Seasons.position(day: number): (SeasonId, number, number)
	local cfg = config()
	if Seasons.calendarMode() then
		local cal = calendar()
		local month, dayOfMonth = Seasons.monthOf(day)
		local season = BY_MONTH[month] or "Primavera"
		local offset = (month - STARTS[season]) % 12
		return season :: SeasonId, offset * cal.DaysPerMonth + dayOfMonth - 1, 3 * cal.DaysPerMonth
	end
	local start = table.find(Seasons.Order, cfg.Start) or 1
	local index = (math.max(math.floor(day), 1) - 1) // cfg.DaysPerSeason
	local season = Seasons.Order[(start - 1 + index) % #Seasons.Order + 1]
	return season :: SeasonId, (math.max(math.floor(day), 1) - 1) % cfg.DaysPerSeason, cfg.DaysPerSeason
end

-- Estación de un día de juego
function Seasons.seasonOf(day: number): SeasonId
	return (Seasons.position(day))
end

-- La estación siguiente y la de antes
function Seasons.nextOf(season: string): SeasonId
	local i = table.find(Seasons.Order, season) or 1
	return Seasons.Order[i % #Seasons.Order + 1] :: SeasonId
end
function Seasons.previousOf(season: string): SeasonId
	local i = table.find(Seasons.Order, season) or 1
	return Seasons.Order[(i - 2) % #Seasons.Order + 1] :: SeasonId
end

-- Cuántos días quedan de estación (para los textos: «queda poco verano»)
function Seasons.daysLeft(day: number): number
	local _, at, length = Seasons.position(day)
	return length - at
end

-- Cuántos días de cada lado del cambio se mezclan dos estaciones (Config.Seasons.BlendDays)
function Seasons.blendDays(length: number?): number
	local cfg = config()
	local days = cfg.BlendDays or (if Seasons.calendarMode() then 10 else 2)
	return math.clamp(days, 0, math.max(0, ((length or 84) / 2) - 1))
end

-- La estación que se VE en un día y una hora: (la de ahora, la vecina con la que se mezcla, cuánto
-- 0..0,5). Los últimos BlendDays días se va acercando a la siguiente (hasta la mitad justo al cambiar)
-- y los primeros BlendDays días aún queda algo de la de antes: sin saltos entre un día y otro.
function Seasons.blendAt(day: number, clockTime: number?): (SeasonId, SeasonId, number)
	local season, at, length = Seasons.position(day)
	local pos = at + math.clamp((clockTime or 12) / 24, 0, 0.999) -- (días con decimales desde que empezó)
	local blend = Seasons.blendDays(length)
	if blend <= 0 then
		return season, Seasons.nextOf(season), 0
	end
	if pos >= length - blend then
		return season, Seasons.nextOf(season), 0.5 * (pos - (length - blend)) / blend
	elseif pos < blend then
		return season, Seasons.previousOf(season), 0.5 * (1 - pos / blend)
	end
	return season, Seasons.nextOf(season), 0
end

-- Un número de dos estaciones mezcladas (a = la de ahora, b = la vecina, t = 0..0,5)
local function mixNumber(a: number?, b: number?, t: number): number
	local x, y = a or 0, b or a or 0
	return x + (y - x) * t
end
function Seasons.mixValue(season: string, other: string?, t: number?, key: string): number
	local a, b = Seasons.Info[season] or Seasons.Info.Primavera, Seasons.Info[other or season]
	-- (lo que una estación no tiene cuenta como 0: el verano tiene luz cálida, el invierno no)
	local x = (a :: any)[key] or 0
	return mixNumber(x, if b then ((b :: any)[key] or 0) else x, math.clamp(t or 0, 0, 1))
end

-- Probabilidad (pesos) de cada tiempo ese día, ya mezclada con la estación vecina
function Seasons.weights(season: string, other: string?, t: number?): { [string]: number }
	local out = {}
	local a = (Seasons.Info[season] or Seasons.Info.Primavera).Weather
	local b = (Seasons.Info[other or season] or Seasons.Info[season] or Seasons.Info.Primavera).Weather
	local k = math.clamp(t or 0, 0, 1)
	for _, id in Seasons.WeatherOrder do
		local w = (a[id] or 0) * (1 - k) + (b[id] or 0) * k
		if id == "Nieve" and season ~= "Invierno" then
			w = 0 -- (la nieve, solo en invierno: al mezclarse con el otoño no nieva en noviembre)
		end
		out[id] = w
	end
	return out
end

-- Número "al azar" pero fijo para una semilla (igual en todos los servidores y en las pruebas)
local function hash(seed: number): number
	local x = math.sin(seed * 78.233 + 12.9898) * 43758.5453
	return x - math.floor(x)
end
Seasons.hash = hash

-- El tiempo que hace en un día y una hora. Cambia cada WeatherHours horas.
function Seasons.weatherAt(day: number, clockTime: number): WeatherId
	local cfg = config()
	local season, other, t = Seasons.blendAt(day, clockTime)
	local weights = Seasons.weights(season, other, t)
	local slot = (math.max(day, 1) - 1) * math.ceil(24 / cfg.WeatherHours) + math.floor(clockTime / cfg.WeatherHours)
	local total = 0
	for _, id in Seasons.WeatherOrder do
		total += weights[id] or 0
	end
	local roll = hash(slot) * total
	for _, id in Seasons.WeatherOrder do
		local weight = weights[id] or 0
		if roll < weight then
			return id :: WeatherId
		end
		roll -= weight
	end
	return "Despejado"
end

-- Temperatura que se enseña en la cápsula de la hora (°C, redondeada): la mínima y la máxima de la
-- estación (mezcladas con la vecina), más calor a media tarde y fresco de madrugada, y lo que resta el
-- tiempo que hace. other / t (opcionales): la estación vecina y cuánto (workspace SeasonNext / SeasonBlend).
local WEATHER_TEMP = { Despejado = 1, Intervalos = 0, Nublado = -1.5, Lluvia = -3, Tormenta = -4, Nieve = -6, Niebla = -2 }
Seasons.WeatherTemp = WEATHER_TEMP
function Seasons.temperature(season: string, weather: string, clockTime: number, other: string?, t: number?): number
	local info = Seasons.Info[season] or Seasons.Info.Primavera
	local otherInfo = Seasons.Info[other or season] or info
	local k = math.clamp(t or 0, 0, 1)
	local low = mixNumber(info.Temp[1], otherInfo.Temp[1], k)
	local high = mixNumber(info.Temp[2], otherInfo.Temp[2], k)
	-- Máxima hacia las 15:00 y mínima hacia las 5:00
	local daily = 0.5 + 0.5 * math.cos((clockTime - 15) / 24 * 2 * math.pi)
	local temp = low + (high - low) * daily + (WEATHER_TEMP[weather] or 0)
	if weather == "Nieve" then
		temp = math.min(temp, 1) -- (si nieva, hace frío de verdad)
	end
	return math.floor(temp + 0.5)
end

-- Texto corto para la interfaz: «🌸 Primavera · 🌧️ Lluvia»
function Seasons.label(season: string, weather: string): string
	local s, w = Seasons.Info[season], Seasons.Weather[weather]
	if not s or not w then
		return ""
	end
	return ("%s %s · %s %s"):format(s.Icon, s.Name, w.Icon, w.Name)
end

---------------------------------------------------------------------
-- Árboles, ropa, playa y fiestas (lo pintan Controllers/Weather, Controllers/Ambient y el servidor)
---------------------------------------------------------------------

export type Foliage = { Color: Color3, Mix: number, Bare: number, Blossom: boolean }

-- Cómo se ve UNA copa con la estación (roll 0..1, fijo por árbol: cada uno con su color). Devuelve el
-- color al que se acerca, cuánto (0..1), lo pelada que está (0..1: más clara y algo transparente) y si
-- tiene flores. Se mezcla con la estación vecina.
local function foliageOf(season: string, roll: number): Foliage
	local info = Seasons.Info[season] or Seasons.Info.Primavera
	local color = info.Leaves
	local blossom = false
	if info.Autumn then
		color = info.Autumn[math.floor(roll * #info.Autumn) % #info.Autumn + 1]
	end
	if (info.Blossom or 0) > 0 and roll < info.Blossom and info.BlossomColors then
		color = info.BlossomColors[math.floor(roll / info.Blossom * #info.BlossomColors) % #info.BlossomColors + 1]
		blossom = true
	end
	local bare = info.Bare or 0
	if info.BareColor and bare > 0 then
		color = color:Lerp(info.BareColor, bare * 0.6)
	end
	return { Color = color, Mix = if blossom then 0.75 else info.LeafMix, Bare = bare, Blossom = blossom }
end

function Seasons.foliage(season: string, other: string?, t: number?, roll: number): Foliage
	local a = foliageOf(season, roll)
	local k = math.clamp(t or 0, 0, 1)
	if not other or other == season or k <= 0 then
		return a
	end
	local b = foliageOf(other, roll)
	return {
		Color = a.Color:Lerp(b.Color, k),
		Mix = a.Mix + (b.Mix - a.Mix) * k,
		Bare = a.Bare + (b.Bare - a.Bare) * k,
		Blossom = if k < 0.5 then a.Blossom else b.Blossom,
	}
end

-- Ropa de un peatón (roll 0..1, al azar al vestirlo): abrigo en invierno, manga corta en verano
-- (Controllers/Ambient: el abrigo es de un color de abrigo y algo más largo; la manga corta, los
-- brazos del color de la piel)
Seasons.CoatColors = { rgb(40, 44, 58), rgb(150, 112, 74), rgb(92, 92, 98), rgb(26, 26, 30), rgb(112, 40, 48), rgb(54, 72, 60) }
function Seasons.dress(season: string, roll: number): { Coat: boolean, ShortSleeves: boolean }
	local info = Seasons.Info[season] or Seasons.Info.Primavera
	local coat = roll < (info.Coats or 0)
	local short = not coat and (1 - roll) < (info.ShortSleeves or 0)
	return { Coat = coat, ShortSleeves = short }
end

-- Cuánta gente va a la playa con la estación (shared/PlaceLife.amount: 1 = lo de siempre, en verano)
function Seasons.beach(season: string?, other: string?, t: number?): number
	if not season or not Seasons.Info[season] then
		return 1
	end
	return math.clamp(Seasons.mixValue(season, other, t, "Beach"), 0, 1)
end

-- ¿Luces de fiesta en la plaza? (genéricas: guirnaldas y un árbol de luces). En el calendario, del
-- 1 de diciembre al 6 de enero; en el ciclo rápido, todo el invierno.
function Seasons.festive(day: number): boolean
	if Seasons.calendarMode() then
		local month, dayOfMonth = Seasons.monthOf(day)
		return month == 12 or (month == 1 and dayOfMonth <= 6)
	end
	return Seasons.seasonOf(day) == "Invierno"
end

-- La altura del sol (Lighting.GeographicLatitude) con la estación mezclada
function Seasons.latitude(season: string, other: string?, t: number?): number
	return Seasons.mixValue(season, other, t, "Latitude")
end

return Seasons
