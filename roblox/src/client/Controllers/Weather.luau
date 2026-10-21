-- Weather (cliente): pinta la estación y el tiempo que decide el servidor (WeatherService).
--  * Lluvia, tormenta (con relámpagos), nieve, niebla: partículas alrededor de la cámara (no dentro de casa)
--  * Pétalos en primavera y hojas cayendo en otoño
--  * Sonidos: lluvia, trueno, viento y pájaros (Config.Seasons.Sounds; sin ID, los de audio/sfx)
--  * Las copas de los árboles, los arbustos y la hierba cambian de color con la estación y la nieve
--  * El cielo: nubes, luz y color (a través de DayLight.setModifier)
--  * El tiempo y la temperatura se ven en la cápsula de la hora del HUD (UI/Hud lee workspace)
-- Todo pasa en el dispositivo de cada jugador: no gasta red ni servidor.
--
-- Estaciones v126 (docs/clima/estaciones.md):
--  * La estación se mezcla con la vecina al acercarse el cambio (workspace SeasonNext / SeasonBlend):
--    cada copa con su color (flores en primavera; amarillo, naranja y rojo en otoño; apagadas en
--    invierno), la hierba del terreno de Valmar y la altura del sol (Lighting.GeographicLatitude).
--  * Con el suelo mojado, la hierba y la tierra del terreno se oscurecen (shared/TerrainPalette.Wettable:
--    nunca los materiales del fondo del mar) y solo con la cámara en Valmar.
--  * Los rayos los decide el servidor y los dibuja Controllers/Relampagos (el fogonazo llega aquí con
--    Weather.setFlash). Mientras una escena o la Grieta muy abierta mandan en el cielo (DayLight), el
--    tiempo de Valmar se aparta (RainLook.storyHold).
--  * Sonido de la lluvia según dónde estás (RainLook.rainMix): calle, bajo un toldo, dentro, en el coche.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local GameClock = require(ReplicatedStorage.Shared.GameClock) -- (la hora del juego: GameClock.hour())
local Config = require(ReplicatedStorage.Shared.Config)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Metro = require(ReplicatedStorage.Shared.Metro)
local DayLight = require(script.Parent.DayLight)
local DayGrade = require(ReplicatedStorage.Shared.DayGrade)
local Hud = require(script.Parent.Parent.UI.Hud)
local SoundFx = require(script.Parent.SoundFx)
local RainLook = require(ReplicatedStorage.Shared.RainLook)
local Shelter = require(script.Parent.Shelter)
local Perf = require(script.Parent.Parent.UI.Perf)
local Wetness = require(ReplicatedStorage.Shared.Wetness)
local TerrainPalette = require(ReplicatedStorage.Shared.TerrainPalette)
local RideState = require(ReplicatedStorage.Shared.RideState)

local Weather = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local SNOW_WHITE = rgb(236, 240, 246)
local BLACK = Color3.new(0, 0, 0)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local emitterPart: BasePart
local farPart: BasePart -- la cortina lejana (gotas grandes y tenues: da «volumen» a la lluvia)
local rain: ParticleEmitter
local rainFar: ParticleEmitter
local snow: ParticleEmitter
local falling: ParticleEmitter
local rainSound: Sound?
local windSound: Sound?
local birdsSound: Sound?
-- (v126) variantes: chaparrón, tejado o toldo, techo del coche y viento de tormenta (nil = no subidas aún)
local heavySound: Sound?
local roofSound: Sound?
local carSound: Sound?
local stormWindSound: Sound?
-- Volúmenes de base de la lluvia, el viento, los pájaros y el trueno (Config.Seasons.SoundLevels)
local LEVELS = (Config.Seasons and Config.Seasons.SoundLevels) or {}
local thunderVolume = LEVELS.Thunder or 0.6 -- (más flojo dentro de casa y en el metro)
local started = false -- (los avisos de cambio de tiempo no salen al entrar al juego)

local season = "Primavera"
local seasonNext = "Verano" -- (la vecina con la que se mezcla y cuánto, 0..0,5: workspace SeasonNext / SeasonBlend)
local seasonBlend = 0
local weather = "Despejado"
local snowCover = 0
local wetShown = 0 -- (lo mojado con que se pintó el terreno, por pasos de Wetness.level)
local flash = 0 -- relámpago (0..1, lo pone Controllers/Relampagos; se apaga solo)
local indoor = false
local covered = false -- (algo encima de la cámara: un toldo, un balcón)
local hold = 0 -- (0..1) cuánto manda una escena o la Grieta en el cielo: el tiempo se aparta
local latitude: number? = nil -- (la altura del sol de la estación, ya suavizada)
local nearTrees = 0 -- copas cerca de la cámara (para las hojas que caen)
-- Lluvia de verdad en pantalla (v108): intensidad que entra y sale poco a poco (RainLook) y el tiempo
-- de antes para mezclar el cielo sin saltos al cambiar
local rainLevel = 0
local fromInfo: { [string]: any } = Seasons.Weather.Despejado
local blendT = 1

-- ¿Le toca a esto en la zona de la cámara? (Controllers/EnvDirector: en el espacio y en los planetas,
-- nada del tiempo ni del cielo de Valmar). Si aún no se sabe, sí.
local function envAllows(what: string): boolean
	local ok, allowed = pcall(function()
		return require(script.Parent.EnvDirector).allows(what)
	end)
	return not ok or allowed ~= false
end


---------------------------------------------------------------------
-- Colores de la naturaleza según la estación
---------------------------------------------------------------------

-- Color original de cada copa, arbusto o seto. Tabla débil (si la pieza desaparece, se olvida sola)
-- y además se quita al salir del mapa (workspace.DescendantRemoving): antes crecía sin parar con lo
-- que entraba y salía del streaming.
local foliage: { [BasePart]: Color3 } = setmetatable({}, { __mode = "k" }) :: any
-- Las que han salido del mapa: su color original se guarda aparte (también tabla débil) por si
-- vuelven a entrar (ya están pintadas: sin esto se tomaría el color pintado como el original)
local parked: { [BasePart]: Color3 } = setmetatable({}, { __mode = "k" }) :: any
local terrainBase: { [Enum.Material]: Color3 } = {}
local NATURE_NAMES = { Leaves = true, Bush = true, Hedge = true, Plant = true }

-- Cada árbol con su color (fijo: sale de dónde está el árbol entero, así todas sus copas van igual):
-- en otoño unos amarillos, otros rojos…
local rolls: { [BasePart]: number } = setmetatable({}, { __mode = "k" }) :: any
local function rollOf(part: BasePart): number
	local cached = rolls[part]
	if cached then
		return cached
	end
	local p = part.Position
	local model = part.Parent
	if model and model:IsA("Model") and model ~= workspace then
		local ok, pivot = pcall(function()
			return (model :: Model):GetPivot().Position
		end)
		if ok then
			p = pivot
		end
	end
	local roll = Seasons.hash(math.floor(p.X / 4) * 0.131 + math.floor(p.Z / 4) * 0.719)
	rolls[part] = roll
	return roll
end

-- El color de una planta con la estación (mezclada con la vecina) y la nieve de ahora
local function paint(part: BasePart, base: Color3, _info: any?)
	local f = Seasons.foliage(season, seasonNext, seasonBlend, rollOf(part))
	local color = base:Lerp(f.Color, f.Mix)
	part.Color = color:Lerp(SNOW_WHITE, snowCover * 0.75)
end

local function track(part: Instance)
	if part:IsA("BasePart") and NATURE_NAMES[part.Name] and part.Material == Enum.Material.LeafyGrass and not foliage[part] then
		local base = parked[part] or part.Color
		parked[part] = nil
		foliage[part] = base
		-- (la que llega nueva con el streaming se pinta ya con la estación y la nieve de ahora, sin
		-- esperar al próximo cambio)
		local info = Seasons.Info[season]
		if info then
			paint(part, base, info)
		end
	end
end

local function untrack(part: Instance)
	local base = foliage[part :: BasePart]
	if base then
		foliage[part :: BasePart] = nil
		parked[part :: BasePart] = base
	end
end

-- ¿Se puede pintar el terreno ahora? Solo con la cámara en Valmar (el terreno es uno para todo el
-- place: en un planeta lo pinta su planeta, Controllers/TerrainPaletteClient y PlanetClient)
local function terrainHere(): boolean
	local okZone, zone = pcall(function()
		return require(script.Parent.TerrainPaletteClient).zone()
	end)
	if okZone and zone ~= "Valmar" then
		return false
	end
	local camera = workspace.CurrentCamera
	if camera and not TerrainPalette.inValmar(camera.Focus.Position) then
		return false
	end
	return envAllows("Weather")
end

local terrainWritten: { [Enum.Material]: Color3 } = {}
local function paintTerrain()
	if not terrainHere() then
		return
	end
	local info = Seasons.Info[season]
	if not info then
		return
	end
	local other = Seasons.Info[seasonNext] or info
	local grass = info.Grass:Lerp(other.Grass, seasonBlend)
	local terrain = workspace.Terrain
	local darken = Wetness.terrainDarken(wetShown)
	for material, base in terrainBase do
		if not TerrainPalette.weatherMay(material.Name) then
			continue -- (nunca el fondo del mar ni el agua)
		end
		-- ¿Lo ha cambiado otro (el servidor, los materiales de usuario)? Entonces ese es su color de verdad
		local okNow, now = pcall(function()
			return terrain:GetMaterialColor(material)
		end)
		local written = terrainWritten[material]
		if okNow and written and typeof(now) == "Color3" and not TerrainPalette.same(now, written) then
			base = now
			terrainBase[material] = now
		end
		local color = base
		if TerrainPalette.Seasonal[material.Name] then
			-- La hierba alta (LeafyGrass, las manchas del campo) algo más oscura y fresca que el césped:
			-- así el suelo no es una alfombra de un solo verde
			local target = if material == Enum.Material.LeafyGrass then grass:Lerp(rgb(44, 78, 40), 0.3) else grass
			color = base:Lerp(target, 0.6):Lerp(SNOW_WHITE, snowCover * 0.9)
		end
		if TerrainPalette.Wettable[material.Name] and darken > 0 then
			color = color:Lerp(BLACK, darken * (1 - snowCover))
		end
		pcall(function()
			terrain:SetMaterialColor(material, color)
		end)
		local okRead, readBack = pcall(function()
			return terrain:GetMaterialColor(material)
		end)
		terrainWritten[material] = if okRead and typeof(readBack) == "Color3" then readBack else color
	end
end

local repainting = false
local function repaint()
	local info = Seasons.Info[season]
	if not info then
		return
	end
	paintTerrain()
	if repainting then
		return -- (ya va una vuelta: la siguiente coge lo último)
	end
	repainting = true
	task.spawn(function()
		local n = 0
		for part, base in foliage do
			if part.Parent then
				paint(part, base, info)
			else
				foliage[part] = nil
			end
			n += 1
			if n % 1500 == 0 then
				task.wait() -- (miles de copas: en trozos, sin congelar la pantalla)
			end
		end
		repainting = false
	end)
end

---------------------------------------------------------------------
-- Partículas alrededor de la cámara
---------------------------------------------------------------------

local function emitter(name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Enabled = false
	for key, value in props do
		(e :: any)[key] = value
	end
	e.Parent = emitterPart
	return e
end

-- Un sonido del tiempo (Config.Seasons.Sounds): su Id o, si es 0, el archivo de audio/sfx
-- (SoundIds o ReplicatedStorage > Sonidos, ver SoundFx.resolve). nil si no hay audio.
local function resolveSound(key: string): string?
	local ids = Config.Seasons and Config.Seasons.Sounds or {}
	local files = Config.Seasons and Config.Seasons.SoundFiles or {}
	return SoundFx.resolve(ids[key], files[key])
end

-- variant = true: una variante (v126) que solo se crea si está subida y NO es el mismo audio que el de
-- siempre (si no, sonaría dos veces lo mismo); si no lo está, nil y suena el de siempre
local function ambientSound(key: string, looped: boolean, variant: boolean?): Sound?
	local id = resolveSound(key)
	if not id then
		return nil
	end
	if variant then
		local fallback = (Config.Seasons and Config.Seasons.SoundFallback or {})[key]
		if fallback and resolveSound(fallback) == id then
			return nil
		end
	end
	local sound = Instance.new("Sound")
	sound.Name = "Weather" .. key
	sound.SoundId = id
	sound.Looped = looped
	sound.Volume = if looped then 0 else 0.6
	sound.SoundGroup = SoundFx.group("Ambience")
	sound.Parent = workspace.CurrentCamera
	if looped then
		sound:Play()
	end
	return sound
end

local function buildEmitters()
	emitterPart = Instance.new("Part")
	emitterPart.Name = "WeatherSky"
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.CanTouch = false
	emitterPart.CastShadow = false
	emitterPart.Transparency = 1
	emitterPart.Size = Vector3.new(120, 1, 120)
	emitterPart.Parent = workspace.CurrentCamera

	-- Lluvia (v108): antes las gotas eran humo de 0,09 aplastado (Squash -3,2 con VelocityParallel las
	-- ponía ANCHAS y bajitas: rayitas horizontales invisibles, sobre todo en el móvil). Ahora son trazos
	-- largos en la dirección en que caen (Squash positivo), más gruesos y claros; cuántas y cómo según
	-- la intensidad y el nivel gráfico (RainLook.falling). El viento las inclina.
	rain = emitter("Rain", {
		Texture = SMOKE,
		Color = ColorSequence.new(rgb(214, 222, 236)),
		LightEmission = 0.3,
		LightInfluence = 0.6,
		Transparency = NumberSequence.new(0.4),
		Size = NumberSequence.new(0.18),
		Squash = NumberSequence.new(2.6), -- gotas estiradas a lo largo de su caída
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Speed = NumberRange.new(95, 115),
		Acceleration = Vector3.new(0, -40, 0),
		EmissionDirection = Enum.NormalId.Bottom,
		Lifetime = NumberRange.new(0.9, 1.1),
		SpreadAngle = Vector2.new(3, 3),
		Rate = 0,
	})
	farPart = emitterPart:Clone()
	farPart:ClearAllChildren() -- (el clon se lleva el emisor de lluvia de cerca)
	farPart.Name = "WeatherSkyFar"
	farPart.Size = Vector3.new(240, 1, 240)
	farPart.Parent = workspace.CurrentCamera
	rainFar = emitter("RainFar", {
		Texture = SMOKE,
		Color = ColorSequence.new(rgb(200, 208, 222)),
		LightEmission = 0.2,
		LightInfluence = 0.6,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(0.5, 0.72), NumberSequenceKeypoint.new(1, 0.9) }),
		Size = NumberSequence.new(0.55),
		Squash = NumberSequence.new(3),
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Speed = NumberRange.new(100, 120),
		Acceleration = Vector3.new(0, -40, 0),
		EmissionDirection = Enum.NormalId.Bottom,
		Lifetime = NumberRange.new(1.3, 1.6),
		SpreadAngle = Vector2.new(2, 2),
		Rate = 0,
	})
	rainFar.Parent = farPart
	snow = emitter("Snow", {
		Texture = SMOKE,
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		LightEmission = 0.3,
		Transparency = NumberSequence.new(0.1),
		Size = NumberSequence.new(0.28),
		Speed = NumberRange.new(6, 9),
		Acceleration = Vector3.new(1.5, -2, 0),
		EmissionDirection = Enum.NormalId.Bottom,
		Lifetime = NumberRange.new(7, 9),
		SpreadAngle = Vector2.new(25, 25),
		RotSpeed = NumberRange.new(-40, 40),
		Rate = 0,
	})
	falling = emitter("Falling", {
		Texture = SMOKE,
		LightEmission = 0,
		Transparency = NumberSequence.new(0.05),
		Size = NumberSequence.new(0.35),
		Squash = NumberSequence.new(0.6),
		Speed = NumberRange.new(3, 5),
		Acceleration = Vector3.new(2, -1.5, 1),
		EmissionDirection = Enum.NormalId.Bottom,
		Lifetime = NumberRange.new(8, 11),
		SpreadAngle = Vector2.new(40, 40),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-120, 120),
		Rate = 0,
	})
	-- Sonidos: lluvia, viento y pájaros en bucle (el volumen lo pone updateParticles) y el trueno.
	-- Todos en el grupo Ambience (control 🌳 Ambiente del menú).
	rainSound = ambientSound("RainLight", true, true) or ambientSound("Rain", true)
	windSound = ambientSound("Wind", true)
	birdsSound = ambientSound("Birds", true)
	heavySound = ambientSound("RainHeavy", true, true)
	roofSound = ambientSound("RainRoof", true, true)
	carSound = ambientSound("RainCar", true, true)
	stormWindSound = ambientSound("WindStorm", true, true)
end

-- (Controllers/Relampagos) un trueno del tiempo: "ThunderNear" / "ThunderFar" o, si no están subidos,
-- el trueno de siempre (en 🌳 Ambiente)
function Weather.makeSound(key: string, looped: boolean): Sound?
	if key == "Thunder" then
		return ambientSound("Thunder", looped)
	end
	return ambientSound(key, looped, true) or ambientSound("Thunder", looped)
end

-- Volumen del viento según el tiempo
local WIND = { Despejado = 0.08, Intervalos = 0.1, Nublado = 0.14, Lluvia = 0.18, Tormenta = 0.4, Nieve = 0.22, Niebla = 0.1 }

-- Cambio suave de volumen (se llama cada 0.1 s): sin saltos al entrar en casa o cambiar el tiempo
local function fadeTowards(current: number, target: number): number
	return current + (target - current) * 0.12
end

-- Lo último que se puso en las partículas: solo se escribe si cambia (antes, 10 veces por segundo
-- aunque fuera lo mismo; el ColorSequence de las hojas se creaba nuevo cada vez)
local shownRain, shownSnow = -1, -1
local shownLook = "" -- tamaño, transparencia, inclinación… de la lluvia (se escriben solo si cambian)
local shownFalling: string? = nil -- "Hojas|n|nivel", "Petalos|n|nivel"… o nil (apagadas)
local FALLING_COLORS = {
	Hojas = ColorSequence.new(rgb(214, 120, 44)),
	Otras = ColorSequence.new(rgb(250, 196, 214)),
}

local function updateParticles()
	local info = Seasons.Weather[weather] or Seasons.Weather.Despejado
	local seasonInfo = Seasons.Info[season]
	local camera = workspace.CurrentCamera
	local position = camera.CFrame.Position
	local wind = DayGrade.wind(weather, Lighting.ClockTime)
	-- La "nube" que suelta las partículas va delante y encima de la cámara (y un poco contra el viento,
	-- para que la lluvia inclinada caiga alrededor de ti)
	local ahead = camera.CFrame.LookVector * Vector3.new(1, 0, 1) * 20
	local upwind = Vector3.new(-wind.X, 0, -wind.Z) * 0.9
	emitterPart.CFrame = CFrame.new(position + ahead + upwind + Vector3.new(0, if info.Snow then 35 else 45, 0))
	farPart.CFrame = CFrame.new(position + ahead * 2 + upwind * 1.4 + Vector3.new(0, 70, 0))
	local underground = position.Y < Metro.Underground -- bajando al metro (vestíbulos, escaleras, andenes)
	-- (en la arena del combate aéreo, lejos de Valmar, no llueve: tiene su propio cielo)
	local me = game:GetService("Players").LocalPlayer
	local arena = me:GetAttribute("AirCombatWorld") == "Arena" or me:GetAttribute("Planeta") ~= nil -- (ni en un planeta: docs/planetas.md)
		or not envAllows("Weather") -- (ni en el espacio ni subiendo a él: EnvDirector)
	local off = indoor or underground or arena or hold > 0.85 -- (o una escena manda en el cielo)
	-- Cuánto suenan aquí los bucles de Valmar (pájaros, viento, lluvia, trueno): 1 en Valmar, 0 en el
	-- espacio, los planetas y bajo el mar; en la subida se van apagando (la misma zona que el cielo:
	-- EnvDirector + shared/Cosmos/Soundscapes). Antes solo los callaba el metro o estar dentro: en el
	-- espacio seguían los pajaritos y el viento sonaba MÁS (sube con la altura).
	local valmar = SoundFx.valmarAudio()
	local fall = RainLook.falling(rainLevel * (1 - hold), Perf.tierName(), wind)
	-- (en pasos de 20 gotas: no se reescribe el emisor por cambios mínimos)
	local rainRate = if off then 0 else math.floor(fall.Rate / 20) * 20
	if rainRate ~= shownRain then
		shownRain = rainRate
		rain.Rate = rainRate
		rain.Enabled = rainRate > 0
		rainFar.Rate = if off then 0 else fall.FarRate
		rainFar.Enabled = rainFar.Rate > 0
	end
	local look = ("%.2f|%.2f|%d|%d|%s"):format(fall.Size, fall.Transparency, math.floor(fall.Tilt.X), math.floor(fall.Tilt.Z), tostring(rain:GetAttribute("DropImage")))
	if rainRate > 0 and look ~= shownLook then
		shownLook = look
		-- Con la imagen de gota de verdad (SkyExtras.dressWeather) ya es alargada: se estira menos
		local image = rain:GetAttribute("DropImage") == true
		rain.Size = NumberSequence.new(if image then fall.Size * 1.1 else fall.Size)
		rain.Squash = NumberSequence.new(if image then 1.4 else fall.Squash)
		rain.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, fall.Transparency), NumberSequenceKeypoint.new(1, fall.Transparency + 0.1) })
		rain.Acceleration = Vector3.new(fall.Tilt.X, -40, fall.Tilt.Z)
		rainFar.Acceleration = Vector3.new(fall.Tilt.X, -40, fall.Tilt.Z)
	end
	local snowRate = if off then 0 else (info.Snow or 0) * 260
	if snowRate ~= shownSnow then
		shownSnow = snowRate
		snow.Rate = snowRate
		snow.Enabled = snow.Rate > 0
	end
	-- Hojas en otoño y pétalos en primavera: solo cerca de árboles (más cuantos más hay)
	local kind = seasonInfo and seasonInfo.Particles
	local nextInfo = Seasons.Info[seasonNext]
	if seasonBlend >= 0.35 and nextInfo and nextInfo.Particles then
		kind = kind or nextInfo.Particles -- (llegando el otoño ya caen algunas)
	end
	local trees = math.clamp(nearTrees / 12, 0, 1)
	local fallingNow = if kind and not off and not info.Rain and not info.Snow and trees > 0 then kind else nil
	local fallingKey = if fallingNow then ("%s|%d|%s"):format(fallingNow, math.floor(trees * 4), Perf.tierName()) else nil
	if fallingKey ~= shownFalling then
		shownFalling = fallingKey
		if fallingNow then
			falling.Color = if fallingNow == "Hojas" then FALLING_COLORS.Hojas else FALLING_COLORS.Otras
			local most = if fallingNow == "Hojas" then 22 else 10
			local tierScale = ({ Low = 0.5, Medium = 0.8, High = 1 } :: { [string]: number })[Perf.tierName()] or 0.8
			falling.Rate = math.max(2, math.floor(most * (0.25 + 0.75 * trees) * tierScale))
			falling.Enabled = true
		else
			falling.Enabled = false
		end
	end
	if rainSound then
		-- (sigue a la lluvia que se ve: llovizna flojita, chaparrón fuerte; dentro, amortiguada)
		local level = math.min(rainLevel, LEVELS.RainMaxLevel or 1.7)
		local volume = if level > 0.01 and not off then (LEVELS.Rain or 0.5) * level else (if level > 0.01 and not underground then 0.15 * level else 0)
		-- (v126) dónde estás: en la calle, bajo un toldo, dentro, en un coche con techo o en el metro
		local vehicle = RideState.vehicleOf(me)
		local where = if underground then "Metro"
			elseif vehicle ~= nil and not RainLook.OpenVehicles[vehicle] then "Coche"
			elseif indoor then "Dentro"
			elseif covered then "Toldo"
			else "Fuera"
		local mix = RainLook.rainMix(level, where)
		local full = (LEVELS.Rain or 0.5) * level * valmar * (1 - hold)
		-- (sin las variantes subidas, la lluvia de siempre suena como antes)
		volume *= if heavySound or roofSound or carSound then mix.Bed else 1
		volume *= 1 - hold
		SoundFx.loopVolume(rainSound, volume * valmar)
		SoundFx.loopVolume(heavySound, full * mix.Heavy)
		SoundFx.loopVolume(roofSound, full * mix.Roof)
		SoundFx.loopVolume(carSound, full * mix.Car)
	end
	-- Viento: más con tormenta, nieve o en lo alto; flojito dentro de casa; nada en el metro
	if windSound then
		local wind = WIND[weather] or 0.08
		if seasonInfo and seasonInfo.Cold then
			wind += 0.05
		end
		wind *= 1 + math.clamp((position.Y - 60) / 200, 0, 1)
		local target = (if underground then 0 elseif indoor then wind * 0.25 else wind) * valmar
		-- (v126) con tormenta, ráfagas: parte del viento lo pone el de tormenta (la suma no pasa del tope)
		local gusty = if stormWindSound and weather == "Tormenta" then 0.6 else 0
		SoundFx.loopVolume(windSound, fadeTowards(windSound.Volume, math.min(target, LEVELS.Wind or 0.5) * (1 - gusty)))
		if stormWindSound then
			SoundFx.loopVolume(stormWindSound, fadeTowards(stormWindSound.Volume, math.min(target, LEVELS.Wind or 0.5) * gusty))
		end
	end
	-- Pájaros: de día y con buen tiempo; más en primavera, pocos en invierno (Seasons.Info.Birds)
	if birdsSound then
		-- (de día de verdad: la curva de shared/DayCycle, de ~07:30 a ~21:45)
		local day = GameClock.darkness() < 0.5
		local calm = weather == "Despejado" or weather == "Nublado" or weather == "Intervalos"
		local amount = if day and calm and not underground then (LEVELS.Birds or 0.3) * (seasonInfo and seasonInfo.Birds or 1) else 0
		if indoor then
			amount *= 0.3
		end
		amount *= valmar * valmar -- (subiendo, los pájaros se van antes que el viento)
		SoundFx.loopVolume(birdsSound, fadeTowards(birdsSound.Volume, amount))
	end
	local thunder = (LEVELS.Thunder or 0.6) * valmar
	thunderVolume = if underground then thunder * 0.2 elseif indoor then thunder * 0.58 else thunder
end

---------------------------------------------------------------------
-- El cielo: se lo pasamos a DayLight para que lo mezcle con la luz de la hora
---------------------------------------------------------------------

-- (Las cuentas están en shared/DayGrade.weather: lluvia gris y fría, bruma, suelo mojado que refleja…)
-- El tiempo que se ve AHORA: el de antes mezclándose con el nuevo (sin saltos) y la lluvia con la
-- intensidad de este momento (llovizna, chaparrón…). Es lo que pinta el cielo, la lluvia y el sonido.
function Weather.effective(): { [string]: any }
	local info = Seasons.Weather[weather] or Seasons.Weather.Despejado
	return RainLook.blend(fromInfo, info, blendT, rainLevel)
end

-- La intensidad de la lluvia que se ve ahora (0 = nada; 1 = fuerte; 1,7 = aguacero de tormenta)
function Weather.rainLevel(): number
	return rainLevel
end

-- El fogonazo de un relámpago (0..1): lo pone Controllers/Relampagos fotograma a fotograma
-- (con el ajuste «⚡ Destellos de relámpago: no», 0)
function Weather.setFlash(value: number)
	flash = math.clamp(value, 0, 1)
end

-- El volumen del trueno aquí (más flojo dentro de casa y en el metro; 0 fuera de Valmar)
function Weather.thunderVolume(): number
	return thunderVolume
end

-- Cuánto manda ahora una escena o la Grieta en el cielo (0..1)
function Weather.storyHold(): number
	return hold
end

-- Luz de la estación: la vecina se mezcla (el tono cálido del verano, el frío del invierno)
local function seasonLight(): { [string]: any }?
	if not Seasons.Info[season] then
		return nil
	end
	local warm = Seasons.mixValue(season, seasonNext, seasonBlend, "Warm")
	local cold = Seasons.mixValue(season, seasonNext, seasonBlend, "Cold")
	return { Warm = if warm > 0.001 then warm else nil, Cold = if cold > 0.001 then cold else nil }
end

local function skyModifier(k: { [string]: any }): { [string]: any }
	local out = DayGrade.weather(k, Weather.effective(), seasonLight(), flash * (1 - hold), workspace:GetAttribute("Wet") or 0)
	if hold > 0.01 then
		-- (una escena o la Grieta muy abierta mandan: el tiempo se aparta poco a poco)
		out = DayGrade.mix(out, k, hold)
	end
	return out
end

---------------------------------------------------------------------

local function refreshState()
	local newSeason = workspace:GetAttribute("Season") or "Primavera"
	local newWeather = workspace:GetAttribute("Weather") or "Despejado"
	local newSnow = workspace:GetAttribute("Snow") or 0
	local newNext = workspace:GetAttribute("SeasonNext")
	newNext = if type(newNext) == "string" and Seasons.Info[newNext] then newNext else Seasons.nextOf(newSeason)
	local newBlend = tonumber(workspace:GetAttribute("SeasonBlend")) or 0
	newBlend = math.floor(math.clamp(newBlend, 0, 0.5) * 20 + 0.5) / 20 -- (por pasos de 0,05: menos repintados)
	local newWet = Wetness.level(workspace:GetAttribute("Wet") or 0)
	local changed = newSeason ~= season or math.abs(newSnow - snowCover) > 0.04 or newNext ~= seasonNext or newBlend ~= seasonBlend
	-- Avisos cuando cambia la estación o empieza algo llamativo (no al entrar al juego)
	if started then
		local info = Seasons.Info[newSeason]
		if newSeason ~= season and info then
			Hud.toast("Info", ("%s Llega %s"):format(info.Icon, ({ Primavera = "la primavera", Verano = "el verano", Otono = "el otoño", Invierno = "el invierno" })[newSeason] or info.Name))
		elseif newWeather ~= weather and (newWeather == "Tormenta" or newWeather == "Nieve" or newWeather == "Lluvia") then
			local w = Seasons.Weather[newWeather]
			Hud.toast("Info", ("%s %s"):format(w.Icon, ({ Tormenta = "¡Se acerca una tormenta!", Nieve = "Empieza a nevar", Lluvia = "Empieza a llover" })[newWeather]))
		end
	end
	if newWeather ~= weather then
		-- El cielo pasa del que se ve ahora al nuevo poco a poco (también si cambia a medio cambio)
		fromInfo = if started then Weather.effective() else (Seasons.Weather[newWeather] or Seasons.Weather.Despejado)
		blendT = if started then 0 else 1
		if not started then
			rainLevel = RainLook.intensity(newWeather, GameClock.hour())
		end
	end
	season, weather = newSeason, newWeather
	seasonNext, seasonBlend = newNext, newBlend
	if changed then
		snowCover = newSnow
		wetShown = newWet
		repaint()
	elseif newWet ~= wetShown then
		wetShown = newWet
		paintTerrain() -- (solo el terreno se oscurece al mojarse; las copas no)
	end
	started = true
end

function Weather.init()
	buildEmitters()
	local terrain = workspace.Terrain
	for _, material in { Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground } do
		local ok, color = pcall(function()
			return terrain:GetMaterialColor(material)
		end)
		if ok then
			terrainBase[material] = color
		end
	end
	-- Copas y arbustos que ya hay (poco a poco, para no congelar el arranque) y los que vayan apareciendo
	task.spawn(function()
		for i, part in workspace:GetDescendants() do
			track(part)
			if i % 4000 == 0 then
				task.wait()
			end
		end
		repaint()
	end)
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(untrack)
	for _, attribute in { "Season", "Weather", "Snow", "SeasonNext", "SeasonBlend", "Wet" } do
		workspace:GetAttributeChangedSignal(attribute):Connect(refreshState)
	end
	refreshState()
	DayLight.setModifier(skyModifier)
	-- Al volver de un planeta (o del espacio), el terreno de Valmar con su estación y su lluvia otra vez
	task.spawn(function()
		local wasHere = true
		while true do
			task.wait(2)
			local here = terrainHere()
			if here and not wasHere then
				-- (lo que cambió fuera lo pintó el planeta y ya lo ha devuelto: no se toma como color nuevo)
				table.clear(terrainWritten)
				paintTerrain()
			end
			wasHere = here
		end
	end)

	local since = 0
	RunService.RenderStepped:Connect(function(dt)
		flash = math.max(0, flash - dt * 3)
		since += dt
		if since < 0.1 then
			return
		end
		local step = since
		since = 0
		-- La lluvia entra y sale poco a poco (RainLook.Fade) y el cielo también
		rainLevel = RainLook.approach(rainLevel, RainLook.intensity(weather, GameClock.hour()), step, RainLook.Fade)
		blendT = math.min(1, blendT + step / RainLook.Fade)
		-- Solo se quita la lluvia DENTRO (tejado y paredes); bajo un balcón se sigue viendo llover
		local shelter = Shelter.camera()
		indoor = shelter.Enclosed
		covered = shelter.Covered and not shelter.Enclosed
		-- ¿Manda una escena o la Grieta en el cielo? (sube y baja poco a poco)
		local okHold, target = pcall(function()
			return RainLook.storyHold(DayLight.layerWeights())
		end)
		hold = RainLook.approach(hold, if okHold and type(target) == "number" then target else 0, step, 2)
		local ok, err = pcall(updateParticles)
		if not ok then
			warn("[Weather] " .. tostring(err))
		end
		-- (los relámpagos los decide el servidor y los dibuja Controllers/Relampagos)
		-- La altura del sol de la estación (alto en verano, bajo en invierno), solo en Valmar
		if envAllows("Weather") then
			local want = Seasons.latitude(season, seasonNext, seasonBlend)
			local now = latitude or want
			now += (want - now) * math.min(1, step * 0.5)
			latitude = now
			if math.abs(Lighting.GeographicLatitude - now) > 0.05 then
				Lighting.GeographicLatitude = now
			end
		end
	end)
	-- Copas cerca de la cámara (cada 3 s): para las hojas y los pétalos que caen
	task.spawn(function()
		while true do
			task.wait(3)
			local camera = workspace.CurrentCamera
			if camera then
				local at = camera.CFrame.Position
				local count = 0
				for part in foliage do
					if part.Parent and (part.Position - at).Magnitude < 70 then
						count += 1
						if count >= 12 then
							break
						end
					end
				end
				nearTrees = count
			end
		end
	end)
end

return Weather
