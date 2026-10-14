-- Weather (cliente): pinta la estación y el tiempo que decide el servidor (WeatherService).
--  * Lluvia, tormenta (con relámpagos), nieve, niebla: partículas alrededor de la cámara (no dentro de casa)
--  * Pétalos en primavera y hojas cayendo en otoño
--  * Sonidos: lluvia, trueno, viento y pájaros (Config.Seasons.Sounds; sin ID, los de audio/sfx)
--  * Las copas de los árboles, los arbustos y la hierba cambian de color con la estación y la nieve
--  * El cielo: nubes, luz y color (a través de DayLight.setModifier)
--  * El tiempo y la temperatura se ven en la cápsula de la hora del HUD (UI/Hud lee workspace)
-- Todo pasa en el dispositivo de cada jugador: no gasta red ni servidor.

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

local Weather = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local SNOW_WHITE = rgb(236, 240, 246)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local emitterPart: BasePart
local farPart: BasePart -- la cortina lejana (gotas grandes y tenues: da «volumen» a la lluvia)
local rain: ParticleEmitter
local rainFar: ParticleEmitter
local snow: ParticleEmitter
local falling: ParticleEmitter
local rainSound: Sound?
local thunderSound: Sound?
local windSound: Sound?
local birdsSound: Sound?
-- Volúmenes de base de la lluvia, el viento, los pájaros y el trueno (Config.Seasons.SoundLevels)
local LEVELS = (Config.Seasons and Config.Seasons.SoundLevels) or {}
local thunderVolume = LEVELS.Thunder or 0.6 -- (más flojo dentro de casa y en el metro)
local started = false -- (los avisos de cambio de tiempo no salen al entrar al juego)

local season = "Primavera"
local weather = "Despejado"
local snowCover = 0
local flash = 0 -- relámpago (0..1, se apaga solo)
local nextLightning = 0
local indoor = false
-- Lluvia de verdad en pantalla (v108): intensidad que entra y sale poco a poco (RainLook) y el tiempo
-- de antes para mezclar el cielo sin saltos al cambiar
local rainLevel = 0
local fromInfo: { [string]: any } = Seasons.Weather.Despejado
local blendT = 1

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

-- El color de una planta con la estación y la nieve de ahora
local function paint(part: BasePart, base: Color3, info: any)
	local color = base:Lerp(info.Leaves, info.LeafMix)
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

local function repaint()
	local info = Seasons.Info[season]
	if not info then
		return
	end
	for part, base in foliage do
		if part.Parent then
			paint(part, base, info)
		else
			foliage[part] = nil
		end
	end
	local terrain = workspace.Terrain
	for material, base in terrainBase do
		-- La hierba alta (LeafyGrass, las manchas del campo) algo más oscura y fresca que el césped:
		-- así el suelo no es una alfombra de un solo verde
		local target = if material == Enum.Material.LeafyGrass then info.Grass:Lerp(rgb(44, 78, 40), 0.3) else info.Grass
		local color = base:Lerp(target, 0.6)
		pcall(function()
			terrain:SetMaterialColor(material, color:Lerp(SNOW_WHITE, snowCover * 0.9))
		end)
	end
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
local function ambientSound(key: string, looped: boolean): Sound?
	local ids = Config.Seasons and Config.Seasons.Sounds or {}
	local files = Config.Seasons and Config.Seasons.SoundFiles or {}
	local id = SoundFx.resolve(ids[key], files[key])
	if not id then
		return nil
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
	rainSound = ambientSound("Rain", true)
	windSound = ambientSound("Wind", true)
	birdsSound = ambientSound("Birds", true)
	thunderSound = ambientSound("Thunder", false)
end

-- Volumen del viento según el tiempo
local WIND = { Despejado = 0.08, Nublado = 0.14, Lluvia = 0.18, Tormenta = 0.4, Nieve = 0.22, Niebla = 0.1 }

-- Cambio suave de volumen (se llama cada 0.1 s): sin saltos al entrar en casa o cambiar el tiempo
local function fadeTowards(current: number, target: number): number
	return current + (target - current) * 0.12
end

-- Lo último que se puso en las partículas: solo se escribe si cambia (antes, 10 veces por segundo
-- aunque fuera lo mismo; el ColorSequence de las hojas se creaba nuevo cada vez)
local shownRain, shownSnow = -1, -1
local shownLook = "" -- tamaño, transparencia, inclinación… de la lluvia (se escriben solo si cambian)
local shownFalling: string? = nil -- "Hojas", "Petalos"… o nil (apagadas)
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
	local off = indoor or underground
	local fall = RainLook.falling(rainLevel, Perf.tierName(), wind)
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
	local kind = seasonInfo and seasonInfo.Particles
	local fallingNow = if kind and not off and not info.Rain and not info.Snow then kind else nil
	if fallingNow ~= shownFalling then
		shownFalling = fallingNow
		if fallingNow then
			falling.Color = if fallingNow == "Hojas" then FALLING_COLORS.Hojas else FALLING_COLORS.Otras
			falling.Rate = if fallingNow == "Hojas" then 14 else 8
			falling.Enabled = true
		else
			falling.Enabled = false
		end
	end
	if rainSound then
		-- (sigue a la lluvia que se ve: llovizna flojita, chaparrón fuerte; dentro, amortiguada)
		local level = math.min(rainLevel, LEVELS.RainMaxLevel or 1.7)
		rainSound.Volume = if level > 0.01 and not off then (LEVELS.Rain or 0.5) * level else (if level > 0.01 and not underground then 0.15 * level else 0)
	end
	-- Viento: más con tormenta, nieve o en lo alto; flojito dentro de casa; nada en el metro
	if windSound then
		local wind = WIND[weather] or 0.08
		if seasonInfo and seasonInfo.Cold then
			wind += 0.05
		end
		wind *= 1 + math.clamp((position.Y - 60) / 200, 0, 1)
		local target = if underground then 0 elseif indoor then wind * 0.25 else wind
		windSound.Volume = fadeTowards(windSound.Volume, math.min(target, LEVELS.Wind or 0.5))
	end
	-- Pájaros: de día y con buen tiempo; más en primavera, pocos en invierno (Seasons.Info.Birds)
	if birdsSound then
		-- (de día de verdad: la curva de shared/DayCycle, de ~07:30 a ~21:45)
		local day = GameClock.darkness() < 0.5
		local calm = weather == "Despejado" or weather == "Nublado"
		local amount = if day and calm and not underground then (LEVELS.Birds or 0.3) * (seasonInfo and seasonInfo.Birds or 1) else 0
		if indoor then
			amount *= 0.3
		end
		birdsSound.Volume = fadeTowards(birdsSound.Volume, amount)
	end
	local thunder = LEVELS.Thunder or 0.6
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

local function skyModifier(k: { [string]: any }): { [string]: any }
	return DayGrade.weather(k, Weather.effective(), Seasons.Info[season], flash, workspace:GetAttribute("Wet") or 0)
end

---------------------------------------------------------------------

local function refreshState()
	local newSeason = workspace:GetAttribute("Season") or "Primavera"
	local newWeather = workspace:GetAttribute("Weather") or "Despejado"
	local newSnow = workspace:GetAttribute("Snow") or 0
	local changed = newSeason ~= season or math.abs(newSnow - snowCover) > 0.04
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
	if changed then
		snowCover = newSnow
		repaint()
	end
	started = true
end

function Weather.init()
	buildEmitters()
	local terrain = workspace.Terrain
	for _, material in { Enum.Material.Grass, Enum.Material.LeafyGrass } do
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
	for _, attribute in { "Season", "Weather", "Snow" } do
		workspace:GetAttributeChangedSignal(attribute):Connect(refreshState)
	end
	refreshState()
	DayLight.setModifier(skyModifier)

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
		indoor = Shelter.camera().Enclosed
		local ok, err = pcall(updateParticles)
		if not ok then
			warn("[Weather] " .. tostring(err))
		end
		-- Relámpagos de tormenta: un destello cada 8-20 segundos y el trueno un poco después
		local info = Seasons.Weather[weather]
		if info and info.Lightning and blendT > 0.6 and os.clock() > nextLightning then
			nextLightning = os.clock() + 8 + math.random() * 12
			flash = 1
			if thunderSound then
				local sound = thunderSound
				task.delay(0.6 + math.random() * 1.5, function()
					sound.Volume = thunderVolume
					sound.PlaybackSpeed = 0.85 + math.random() * 0.3 -- (cada trueno un poco distinto)
					sound:Play()
				end)
			end
		end
	end)
end

return Weather
