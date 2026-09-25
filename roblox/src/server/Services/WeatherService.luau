-- WeatherService: la estación del año y el tiempo que hace. Lo decide el servidor (igual para todos)
-- y lo publica en atributos de workspace, que se replican solos a los jugadores:
--   Season   "Primavera" | "Verano" | "Otono" | "Invierno"
--   Weather  "Despejado" | "Nublado" | "Lluvia" | "Tormenta" | "Nieve" | "Niebla"
--   Snow     0..1  cuánta nieve hay acumulada en el suelo (sube mientras nieva, se derrite después)
--   Wet      0..1  lo mojado que está todo (sube con la lluvia, se seca con el sol)
-- Cada jugador lo pinta en su dispositivo (client/Controllers/Weather y Wildlife) y la historia lo
-- puede usar en sus condiciones (Season, Weather) para que la gente hable del tiempo.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Seasons = require(ReplicatedStorage.Shared.Seasons)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local Players = game:GetService("Players")

local WeatherService = {}

local TICK = 2 -- segundos reales entre comprobaciones
local SNOW_UP, SNOW_DOWN = 1 / 120, 1 / 240 -- la nieve cuaja en 2 minutos y se derrite en 4
local WET_UP, WET_DOWN = 1 / 30, 1 / 150

local override: string? = nil -- para pruebas y eventos: forzar un tiempo concreto

-- Forzar un tiempo (nil = volver al tiempo normal). Útil para probar o para escenas especiales.
function WeatherService.force(weather: string?)
	override = if weather and Seasons.Weather[weather] then weather else nil
end

function WeatherService.current(): (string, string)
	return workspace:GetAttribute("Season") or "Primavera", workspace:GetAttribute("Weather") or "Despejado"
end

local function step()
	local day = workspace:GetAttribute("Day") or 1
	local season = Seasons.seasonOf(day)
	local weather = override or Seasons.weatherAt(day, Lighting.ClockTime)
	-- En invierno no llueve (nieva) y fuera del invierno no nieva
	if weather == "Nieve" and season ~= "Invierno" then
		weather = "Lluvia"
	elseif weather == "Lluvia" and season == "Invierno" then
		weather = "Nieve"
	end
	if workspace:GetAttribute("Season") ~= season then
		workspace:SetAttribute("Season", season)
		for _, player in Players:GetPlayers() do
			StoryEvents.emit(player, "SeasonChanged", { Season = season })
		end
	end
	if workspace:GetAttribute("Weather") ~= weather then
		workspace:SetAttribute("Weather", weather)
		for _, player in Players:GetPlayers() do
			StoryEvents.emit(player, "WeatherChanged", { Weather = weather })
		end
	end
	local info = Seasons.Weather[weather]
	local snow = workspace:GetAttribute("Snow") or 0
	snow = math.clamp(snow + (if info.Snow then SNOW_UP else -SNOW_DOWN) * TICK, 0, 1)
	workspace:SetAttribute("Snow", math.floor(snow * 1000) / 1000)
	local wet = workspace:GetAttribute("Wet") or 0
	wet = math.clamp(wet + (if info.Wet then WET_UP else -WET_DOWN) * TICK, 0, 1)
	workspace:SetAttribute("Wet", math.floor(wet * 1000) / 1000)
end

function WeatherService.init()
	workspace:SetAttribute("Snow", 0)
	workspace:SetAttribute("Wet", 0)
	task.spawn(function()
		while true do
			local ok, err = pcall(step)
			if not ok then
				warn("[WeatherService] " .. tostring(err))
			end
			task.wait(TICK)
		end
	end)
end

return WeatherService
