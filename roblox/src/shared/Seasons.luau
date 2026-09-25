-- Seasons: las estaciones del año y el tiempo que hace (sol, nubes, lluvia, tormenta, nieve, niebla).
-- Es "puro" (no toca el juego): lo usan el servidor (WeatherService decide el tiempo y lo publica en
-- workspace) y cada jugador (Controllers/Weather lo pinta: lluvia, nieve, hojas, colores; y
-- Controllers/Wildlife decide qué animales salen). Todo el servidor ve el mismo tiempo.
--
-- Una estación dura Config.Seasons.DaysPerSeason días de juego. El tiempo cambia cada
-- Config.Seasons.WeatherHours horas de juego, al azar pero igual para todos (depende del día y la hora).

local Config = require(script.Parent.Config)

local Seasons = {}

local rgb = Color3.fromRGB

export type SeasonId = "Primavera" | "Verano" | "Otono" | "Invierno"
export type WeatherId = "Despejado" | "Nublado" | "Lluvia" | "Tormenta" | "Nieve" | "Niebla"

Seasons.Order = { "Primavera", "Verano", "Otono", "Invierno" }

-- Cómo es cada estación: probabilidad de cada tiempo, color de la hierba y de las hojas,
-- y cuántos animales se ven (1 = lo normal).
Seasons.Info = {
	Primavera = {
		Name = "Primavera", Icon = "🌸",
		Weather = { Despejado = 45, Nublado = 25, Lluvia = 25, Tormenta = 5 },
		Grass = rgb(98, 156, 68), Leaves = rgb(110, 176, 80), LeafMix = 0.25,
		Particles = "Petalos", Birds = 1.2, Butterflies = 1, Ground = 1,
	},
	Verano = {
		Name = "Verano", Icon = "☀️",
		Weather = { Despejado = 70, Nublado = 15, Lluvia = 5, Tormenta = 10 },
		Grass = rgb(132, 150, 70), Leaves = rgb(70, 124, 52), LeafMix = 0.2,
		Particles = nil, Birds = 1, Butterflies = 1.3, Ground = 1,
		Warm = 0.12, -- luz algo más cálida
	},
	Otono = {
		Name = "Otoño", Icon = "🍂",
		Weather = { Despejado = 35, Nublado = 30, Lluvia = 25, Tormenta = 5, Niebla = 5 },
		Grass = rgb(128, 132, 70), Leaves = rgb(214, 118, 40), LeafMix = 0.7,
		Particles = "Hojas", Birds = 0.7, Butterflies = 0, Ground = 1,
	},
	Invierno = {
		Name = "Invierno", Icon = "❄️",
		Weather = { Despejado = 35, Nublado = 30, Nieve = 25, Niebla = 10 },
		Grass = rgb(118, 132, 96), Leaves = rgb(96, 104, 86), LeafMix = 0.55,
		Particles = nil, Birds = 0.4, Butterflies = 0, Ground = 0.7,
		Cold = 0.1, -- luz algo más fría
	},
}

-- Cómo cambia el cielo con cada tiempo (DayLight lo mezcla con la luz de la hora)
Seasons.Weather = {
	Despejado = { Name = "Despejado", Icon = "☀️", Cover = nil, Brightness = 1, Saturation = 0, Density = 0 },
	Nublado = { Name = "Nublado", Icon = "☁️", Cover = 0.75, Brightness = 0.8, Saturation = -0.08, Density = 0.03 },
	Lluvia = { Name = "Lluvia", Icon = "🌧️", Cover = 0.85, Brightness = 0.6, Saturation = -0.18, Density = 0.08, Rain = 1, Wet = true },
	Tormenta = { Name = "Tormenta", Icon = "⛈️", Cover = 0.92, Brightness = 0.45, Saturation = -0.25, Density = 0.1, Rain = 1.7, Lightning = true, Wet = true },
	Nieve = { Name = "Nieve", Icon = "🌨️", Cover = 0.8, Brightness = 0.85, Saturation = -0.12, Density = 0.1, Snow = 1 },
	Niebla = { Name = "Niebla", Icon = "🌫️", Cover = 0.6, Brightness = 0.8, Saturation = -0.15, Density = 0.35 },
}

local function config()
	return Config.Seasons or { DaysPerSeason = 7, WeatherHours = 6, Start = "Primavera" }
end

-- Estación de un día de juego (día 1 = primer día de la estación inicial)
function Seasons.seasonOf(day: number): SeasonId
	local cfg = config()
	local start = table.find(Seasons.Order, cfg.Start) or 1
	local index = (math.max(day, 1) - 1) // cfg.DaysPerSeason
	return Seasons.Order[(start - 1 + index) % #Seasons.Order + 1] :: SeasonId
end

-- Cuántos días quedan de estación (para los textos: «queda poco verano»)
function Seasons.daysLeft(day: number): number
	local cfg = config()
	return cfg.DaysPerSeason - (math.max(day, 1) - 1) % cfg.DaysPerSeason
end

-- Número "al azar" pero fijo para una semilla (igual en todos los servidores y en las pruebas)
local function hash(seed: number): number
	local x = math.sin(seed * 78.233 + 12.9898) * 43758.5453
	return x - math.floor(x)
end

-- El tiempo que hace en un día y una hora. Cambia cada WeatherHours horas.
function Seasons.weatherAt(day: number, clockTime: number): WeatherId
	local cfg = config()
	local season = Seasons.Info[Seasons.seasonOf(day)]
	local slot = (math.max(day, 1) - 1) * math.ceil(24 / cfg.WeatherHours) + math.floor(clockTime / cfg.WeatherHours)
	local total = 0
	for _, weight in season.Weather do
		total += weight
	end
	local roll = hash(slot) * total
	-- Orden fijo para que el resultado no dependa del orden de la tabla
	for _, id in { "Despejado", "Nublado", "Lluvia", "Tormenta", "Nieve", "Niebla" } do
		local weight = season.Weather[id] or 0
		if roll < weight then
			return id :: WeatherId
		end
		roll -= weight
	end
	return "Despejado"
end

-- Texto corto para la interfaz: «🌸 Primavera · 🌧️ Lluvia»
function Seasons.label(season: string, weather: string): string
	local s, w = Seasons.Info[season], Seasons.Weather[weather]
	if not s or not w then
		return ""
	end
	return ("%s %s · %s %s"):format(s.Icon, s.Name, w.Icon, w.Name)
end

return Seasons
