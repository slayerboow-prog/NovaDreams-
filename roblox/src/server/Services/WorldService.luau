-- WorldService: ciclo día/noche, farolas y efectos de iluminación para dar ambiente.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldService = {}

local function ensure(className: string, props: { [string]: any })
	local instance = Lighting:FindFirstChildOfClass(className) or Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = Lighting
end

local function setupLighting()
	Lighting.ClockTime = Config.StartClockTime
	-- Los valores base vienen del archivo del juego (default.project.json); esto asegura que existen.
	-- La luz de cada hora (amanecer, mediodía, atardecer, noche) la pinta cada jugador en su dispositivo:
	-- client/Controllers/DayLight.luau (así va suave, no gasta red y se adapta a la calidad gráfica).
	ensure("Atmosphere", {})
	ensure("BloomEffect", {})
	ensure("SunRaysEffect", {})
	ensure("ColorCorrectionEffect", {})
	ensure("DepthOfFieldEffect", { FarIntensity = 0, NearIntensity = 0, InFocusRadius = 120, FocusDistance = 60 })
	ensure("Sky", { SunAngularSize = 14, MoonAngularSize = 9, StarCount = 3000 })
	-- Estilo de luz realista (propiedades recientes de Roblox: si no existen, no pasa nada)
	pcall(function()
		(Lighting :: any).LightingStyle = Enum.LightingStyle.Realistic
	end)
	pcall(function()
		(Lighting :: any).PrioritizeLightingQuality = true
	end)
	-- Agua del mar de Playa Dorada: más transparente, con reflejos y olas suaves
	local terrain = workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(28, 104, 124)
	terrain.WaterTransparency = 0.55
	terrain.WaterReflectance = 0.85
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 12
	-- Nubes de verdad (volumétricas); su cantidad y color los ajusta cada jugador según la hora
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.45
	clouds.Density = 0.3
	clouds.Parent = terrain
end

local NIGHT_WINDOW_COLOR = Color3.fromRGB(240, 180, 110)
local night = false
local windowOn: { [BasePart]: boolean } = {}

local function applyLamp(bulb: Instance)
	local light = bulb:FindFirstChildWhichIsA("Light")
	if light then
		light.Enabled = night
	end
	if bulb:IsA("BasePart") then
		bulb.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

-- Ventanas que se iluminan de noche (las marca el generador de edificios).
-- Cada una tiene su color (NightColor) y su horario (OnAt / OffAt; 25 = la 1 de la madrugada):
-- la ciudad se va encendiendo poco a poco al anochecer y apagando de madrugada, como una de verdad.
local function setWindow(window: BasePart, on: boolean)
	if windowOn[window] == on then
		return
	end
	windowOn[window] = on
	window.Material = if on then Enum.Material.Neon else Enum.Material.Glass
	window.Color = if on then (window:GetAttribute("NightColor") or NIGHT_WINDOW_COLOR) else (window:GetAttribute("DayColor") or window.Color)
end

local function shouldBeLit(window: Instance, clock: number): boolean
	local onAt = window:GetAttribute("OnAt") or Config.LampsOnAt
	local offAt = window:GetAttribute("OffAt") or (Config.LampsOffAt + 24)
	local t = if clock < 12 then clock + 24 else clock -- horas de la noche seguidas (1:00 = 25)
	return t >= onAt and t < offAt
end

local function applyWindow(window: Instance)
	if window:IsA("BasePart") then
		setWindow(window, shouldBeLit(window, Lighting.ClockTime))
		window.Destroying:Connect(function()
			windowOn[window] = nil
		end)
	end
end

local function updateWindows(clock: number)
	for _, window in CollectionService:GetTagged("NightWindow") do
		if window:IsA("BasePart") then
			setWindow(window, shouldBeLit(window, clock))
		end
	end
end

-- Las farolas no se encienden todas a la vez (cada fotocélula tarda un poco distinto)
local function setNight(on: boolean)
	night = on
	for _, bulb in CollectionService:GetTagged("StreetLamp") do
		task.delay(math.random() * 6, applyLamp, bulb)
	end
end

function WorldService.init()
	setupLighting()

	local day = 1
	workspace:SetAttribute("Day", day)
	local hoursPerSecond = 24 / (Config.DayLengthMinutes * 60)
	local lampsOn: boolean? = nil
	local windowTimer = 0

	-- Lo que se construya después (casas de jugadores) respeta la hora actual
	CollectionService:GetInstanceAddedSignal("StreetLamp"):Connect(applyLamp)
	CollectionService:GetInstanceAddedSignal("NightWindow"):Connect(applyWindow)

	RunService.Heartbeat:Connect(function(dt)
		local previous = Lighting.ClockTime
		local clock = (previous + dt * hoursPerSecond) % 24
		Lighting.ClockTime = clock
		if clock < previous then
			day += 1
			workspace:SetAttribute("Day", day)
		end


		local shouldBeOn = clock >= Config.LampsOnAt or clock < Config.LampsOffAt
		if shouldBeOn ~= lampsOn then
			lampsOn = shouldBeOn
			setNight(shouldBeOn)
		end
		-- Las ventanas se revisan cada segundo real (poco más de un minuto de juego)
		windowTimer += dt
		if windowTimer >= 1 then
			windowTimer = 0
			updateWindows(clock)
		end
	end)
end

return WorldService
