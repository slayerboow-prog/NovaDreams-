-- WeatherService: la estación del año y el tiempo que hace. Lo decide el servidor (igual para todos)
-- y lo publica en atributos de workspace, que se replican solos a los jugadores:
--   Season       "Primavera" | "Verano" | "Otono" | "Invierno" (la del calendario: shared/Seasons)
--   SeasonNext   la estación vecina con la que se está mezclando (al acercarse el cambio, o recién pasado)
--   SeasonBlend  0..0,5  cuánto se mezcla con la vecina (colores, temperatura: sin saltos entre días)
--   Weather      "Despejado" | "Intervalos" | "Nublado" | "Lluvia" | "Tormenta" | "Nieve" | "Niebla"
--   Snow         0..1  cuánta nieve hay acumulada en el suelo (sube mientras nieva, se derrite después)
--   Wet          0..1  lo mojado que está todo (sube con la lluvia, se seca en horas de juego: Wetness.water)
--   Puddles      0..1  el agua de los charcos (crecen despacio con la lluvia y tardan más en secarse)
--   Rayo         «n|x|z|cerca|semilla» cada rayo de tormenta (shared/Storm: cuándo y dónde, igual para
--                todos; cada jugador lo dibuja y oye el trueno con el retraso de su distancia)
--   Festive      true del 1 de diciembre al 6 de enero (luces en la plaza)
--   ClimaForzado texto para el modo pruebas («Tormenta (pruebas)»…) o nil
-- Cada jugador lo pinta en su dispositivo (client/Controllers/Weather, WetWorld, Relampagos y Wildlife)
-- y la historia lo puede usar en sus condiciones (Season, Weather) para que la gente hable del tiempo.
--
-- Quién manda (de más a menos): un evento del mundo o una escena (force(weather) / force(nil), p. ej. la
-- tormenta de SeaEventService) > el modo pruebas (/clima, /estacion, panel) > el calendario.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameClock = require(ReplicatedStorage.Shared.GameClock) -- (la hora del juego: GameClock.hour())
local Config = require(ReplicatedStorage.Shared.Config)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Wetness = require(ReplicatedStorage.Shared.Wetness)
local RainLook = require(ReplicatedStorage.Shared.RainLook)
local Storm = require(ReplicatedStorage.Shared.Storm)
local TerrainPalette = require(ReplicatedStorage.Shared.TerrainPalette)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local WeatherService = {}

local TICK = 2 -- segundos reales entre comprobaciones
local SNOW_UP, SNOW_DOWN = 1 / 120, 1 / 240 -- la nieve cuaja en 2 minutos y se derrite en 4

-- Forzados (nil = lo normal). event: eventos del mundo y escenas; tester: el modo pruebas.
local forced: { Event: string?, Tester: string?, Season: string? } = { Event = nil, Tester = nil, Season = nil }

-- Forzar un tiempo (nil = volver al tiempo normal). Útil para escenas o eventos especiales.
-- source = "Tester" para el modo pruebas (un evento manda sobre él); sin source, es un evento.
function WeatherService.force(weather: string?, source: string?)
	local value = if weather and Seasons.Weather[weather] then weather else nil
	if source == "Tester" then
		forced.Tester = value
	else
		forced.Event = value
	end
	WeatherService.step()
end

-- Forzar la estación (solo el modo pruebas; nil = la del calendario)
function WeatherService.forceSeason(season: string?)
	forced.Season = if season and Seasons.Info[season] then season else nil
	WeatherService.step()
end

function WeatherService.forced(): { [string]: string? }
	return table.clone(forced)
end

function WeatherService.current(): (string, string)
	return workspace:GetAttribute("Season") or "Primavera", workspace:GetAttribute("Weather") or "Despejado"
end

-- La estación y el tiempo que tocan ahora (con lo forzado). Puro con day/clock: lo usan las pruebas.
function WeatherService.decide(day: number, clock: number): (string, string, number, string)
	local season, other, blend = Seasons.blendAt(day, clock)
	if forced.Season then
		season, other, blend = forced.Season, Seasons.nextOf(forced.Season), 0
	end
	local weather = forced.Event or forced.Tester
	if not weather then
		weather = Seasons.weatherAt(day, clock)
		if forced.Season then
			-- (estación forzada: su tiempo, no el del calendario)
			local weights = Seasons.weights(season, nil, 0)
			local total = 0
			for _, id in Seasons.WeatherOrder do
				total += weights[id]
			end
			local slot = (math.max(day, 1) - 1) * 4 + math.floor(clock / 6)
			local roll = Seasons.hash(slot + 0.5) * total
			for _, id in Seasons.WeatherOrder do
				if roll < weights[id] then
					weather = id
					break
				end
				roll -= weights[id]
			end
		end
		-- Fuera del invierno no nieva (si sale, llueve)
		if weather == "Nieve" and season ~= "Invierno" then
			weather = "Lluvia"
		end
	end
	return season, weather :: string, blend, other
end

---------------------------------------------------------------------
-- Rayos (shared/Storm)
---------------------------------------------------------------------

local strikes: { number } = {}
local strikeCount = 0
local nextStrike = 0

-- Dónde cae: cerca de alguien que esté en Valmar (si cae «cerca») o lejos de él; si no hay nadie, por
-- la isla
local function strikeSpot(s: Storm.Strike): (number, number)
	local around = Vector3.new(0, 0, 0)
	local candidates = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and TerrainPalette.inValmar(root.Position) and player:GetAttribute("Planeta") == nil then
			table.insert(candidates, root.Position)
		end
	end
	if #candidates > 0 then
		around = candidates[math.random(1, #candidates)]
	end
	return around.X + math.cos(s.Angle) * s.Distance, around.Z + math.sin(s.Angle) * s.Distance
end

local function lightningTick(weather: string, clock: number, at: number?)
	local info = Seasons.Weather[weather]
	if not info or not info.Lightning then
		nextStrike = 0
		return
	end
	local now = at or os.clock()
	if nextStrike == 0 then
		nextStrike = now + 3 + math.random() * 4 -- (el primero, al poco de empezar)
		return
	end
	if now < nextStrike then
		return
	end
	nextStrike = now + Storm.nextGap(RainLook.intensity(weather, clock), math.random())
	if not Storm.allow(strikes, now) then
		return
	end
	Storm.record(strikes, now)
	local s = Storm.strike(math.random(), math.random(), math.random())
	local x, z = strikeSpot(s)
	strikeCount += 1
	workspace:SetAttribute("Rayo", Storm.encode(strikeCount, x, z, s.Near, math.random(1, 1000000)))
end

---------------------------------------------------------------------

local lastClock: number? = nil

-- Horas de juego que han pasado desde la última vez (vuelta de la medianoche incluida; un salto grande
-- del reloj —dormir, el modo pruebas— cuenta como mucho 3 horas para el secado)
local function gameHoursSince(clock: number): number
	if not lastClock then
		lastClock = clock
		return 0
	end
	local d = (clock - lastClock) % 24
	lastClock = clock
	if d > 12 then
		return 0 -- (el reloj ha ido hacia atrás: no se seca ni se moja)
	end
	return math.min(d, 3)
end

local function round(x: number, places: number): number
	local m = 10 ^ places
	return math.floor(x * m + 0.5) / m
end

function WeatherService.step()
	local day = workspace:GetAttribute("Day") or 1
	local clock = GameClock.hour()
	local season, weather, blend, other = WeatherService.decide(day, clock)
	if workspace:GetAttribute("Season") ~= season then
		workspace:SetAttribute("Season", season)
		for _, player in Players:GetPlayers() do
			StoryEvents.emit(player, "SeasonChanged", { Season = season })
		end
	end
	workspace:SetAttribute("SeasonNext", other)
	workspace:SetAttribute("SeasonBlend", round(blend, 2))
	workspace:SetAttribute("Festive", if forced.Season then forced.Season == "Invierno" else Seasons.festive(day))
	if workspace:GetAttribute("Weather") ~= weather then
		workspace:SetAttribute("Weather", weather)
		for _, player in Players:GetPlayers() do
			StoryEvents.emit(player, "WeatherChanged", { Weather = weather })
		end
	end
	local label: string? = nil
	if forced.Event then
		label = forced.Event .. " (evento)"
	elseif forced.Tester or forced.Season then
		label = ("%s%s (pruebas)"):format(forced.Season and (forced.Season .. " · ") or "", forced.Tester or "auto")
	end
	workspace:SetAttribute("ClimaForzado", label)
end

local function waterTick()
	local weather = workspace:GetAttribute("Weather") or "Despejado"
	local season = workspace:GetAttribute("Season") or "Primavera"
	local info = Seasons.Weather[weather] or Seasons.Weather.Despejado
	local clock = GameClock.hour()
	local hours = gameHoursSince(clock)
	local snow = workspace:GetAttribute("Snow") or 0
	snow = math.clamp(snow + (if info.Snow then SNOW_UP else -SNOW_DOWN) * TICK, 0, 1)
	workspace:SetAttribute("Snow", round(snow, 3))
	local rain = if info.Wet then RainLook.intensity(weather, clock) else 0
	local wet, puddles = Wetness.water(workspace:GetAttribute("Wet") or 0, workspace:GetAttribute("Puddles") or 0, rain, hours, Wetness.dryHours(season, weather, clock))
	workspace:SetAttribute("Wet", round(wet, 3))
	workspace:SetAttribute("Puddles", round(puddles, 3))
	lightningTick(weather, clock)
end

-- (pruebas: scripts/test-estaciones)
WeatherService._lightningTick = lightningTick
WeatherService._waterTick = function()
	waterTick()
end

function WeatherService.init()
	Storm.configure(Config.Seasons and Config.Seasons.Lightning)
	workspace:SetAttribute("Snow", 0)
	workspace:SetAttribute("Wet", 0)
	workspace:SetAttribute("Puddles", 0)
	task.spawn(function()
		while true do
			local ok, err = pcall(function()
				WeatherService.step()
				waterTick()
			end)
			if not ok then
				warn("[WeatherService] " .. tostring(err))
			end
			task.wait(TICK)
		end
	end)
end

return WeatherService
