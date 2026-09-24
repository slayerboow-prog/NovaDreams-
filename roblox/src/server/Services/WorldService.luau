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
	-- Los valores base vienen del archivo del juego (default.project.json); esto asegura que existen
	ensure("Atmosphere", {})
	ensure("BloomEffect", {})
	ensure("SunRaysEffect", {})
	ensure("ColorCorrectionEffect", {})
	ensure("Sky", {})
end

---------------------------------------------------------------------
-- Curva de iluminación por horas: el mismo mapa se ve distinto al amanecer,
-- de día, en la hora dorada, al anochecer y de noche.
---------------------------------------------------------------------
local rgb = Color3.fromRGB
type Key = { [string]: any }
local KEYS: { { Hour: number, Key: Key } } = {
	{ Hour = 0, Key = { Ambient = rgb(38, 42, 60), Outdoor = rgb(58, 64, 92), Brightness = 1.1, Exposure = -0.1, AtmColor = rgb(42, 52, 74), AtmDecay = rgb(20, 26, 42), Density = 0.36, Tint = rgb(196, 208, 255), Saturation = -0.05, Contrast = 0.16, Bloom = 1.1 } },
	{ Hour = 5.5, Key = { Ambient = rgb(46, 48, 66), Outdoor = rgb(70, 74, 100), Brightness = 1.2, Exposure = -0.05, AtmColor = rgb(70, 72, 96), AtmDecay = rgb(40, 40, 60), Density = 0.36, Tint = rgb(210, 214, 250), Saturation = 0, Contrast = 0.14, Bloom = 0.9 } },
	{ Hour = 7, Key = { Ambient = rgb(92, 80, 80), Outdoor = rgb(150, 130, 120), Brightness = 2.0, Exposure = 0.1, AtmColor = rgb(240, 202, 172), AtmDecay = rgb(140, 110, 110), Density = 0.3, Tint = rgb(255, 236, 216), Saturation = 0.12, Contrast = 0.12, Bloom = 0.6 } },
	{ Hour = 10, Key = { Ambient = rgb(70, 70, 78), Outdoor = rgb(128, 128, 136), Brightness = 2.6, Exposure = 0.15, AtmColor = rgb(206, 214, 224), AtmDecay = rgb(110, 120, 138), Density = 0.28, Tint = rgb(255, 250, 242), Saturation = 0.14, Contrast = 0.1, Bloom = 0.5 } },
	{ Hour = 16, Key = { Ambient = rgb(72, 70, 76), Outdoor = rgb(134, 128, 132), Brightness = 2.6, Exposure = 0.15, AtmColor = rgb(214, 214, 218), AtmDecay = rgb(120, 118, 130), Density = 0.28, Tint = rgb(255, 248, 238), Saturation = 0.14, Contrast = 0.1, Bloom = 0.5 } },
	{ Hour = 18.5, Key = { Ambient = rgb(100, 80, 70), Outdoor = rgb(172, 130, 108), Brightness = 2.4, Exposure = 0.2, AtmColor = rgb(255, 188, 138), AtmDecay = rgb(162, 100, 88), Density = 0.32, Tint = rgb(255, 222, 190), Saturation = 0.22, Contrast = 0.15, Bloom = 0.7 } },
	{ Hour = 20, Key = { Ambient = rgb(60, 54, 76), Outdoor = rgb(90, 80, 112), Brightness = 1.5, Exposure = 0, AtmColor = rgb(118, 108, 150), AtmDecay = rgb(58, 48, 80), Density = 0.34, Tint = rgb(222, 214, 255), Saturation = 0.05, Contrast = 0.15, Bloom = 0.9 } },
	{ Hour = 21.5, Key = { Ambient = rgb(38, 42, 60), Outdoor = rgb(58, 64, 92), Brightness = 1.1, Exposure = -0.1, AtmColor = rgb(42, 52, 74), AtmDecay = rgb(20, 26, 42), Density = 0.36, Tint = rgb(196, 208, 255), Saturation = -0.05, Contrast = 0.16, Bloom = 1.1 } },
}

local function lerp(a: any, b: any, t: number): any
	if typeof(a) == "Color3" then
		return (a :: Color3):Lerp(b, t)
	end
	return a + (b - a) * t
end

local function sample(hour: number): Key
	for i = 1, #KEYS do
		local a = KEYS[i]
		local b = KEYS[i + 1] or { Hour = KEYS[1].Hour + 24, Key = KEYS[1].Key }
		if hour >= a.Hour and hour < b.Hour then
			local t = (hour - a.Hour) / (b.Hour - a.Hour)
			local out = {}
			for name, value in a.Key do
				out[name] = lerp(value, b.Key[name], t)
			end
			return out
		end
	end
	return KEYS[1].Key
end

local function applyCurve(hour: number)
	local k = sample(hour)
	Lighting.Ambient = k.Ambient
	Lighting.OutdoorAmbient = k.Outdoor
	Lighting.Brightness = k.Brightness
	Lighting.ExposureCompensation = k.Exposure
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = k.AtmColor
		atmosphere.Decay = k.AtmDecay
		atmosphere.Density = k.Density
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.TintColor = k.Tint
		cc.Saturation = k.Saturation
		cc.Contrast = k.Contrast
	end
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Intensity = k.Bloom
	end
end

local NIGHT_WINDOW_COLOR = Color3.fromRGB(255, 208, 140)
local night = false

local function applyLamp(bulb: Instance)
	local light = bulb:FindFirstChildWhichIsA("Light")
	if light then
		light.Enabled = night
	end
	if bulb:IsA("BasePart") then
		bulb.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

-- Ventanas que se iluminan de noche (las marca el generador de edificios)
local function applyWindow(window: Instance)
	if not window:IsA("BasePart") then
		return
	end
	window.Material = if night then Enum.Material.Neon else Enum.Material.Glass
	window.Color = if night then NIGHT_WINDOW_COLOR else (window:GetAttribute("DayColor") or window.Color)
end

local function setNight(on: boolean)
	night = on
	for _, bulb in CollectionService:GetTagged("StreetLamp") do
		applyLamp(bulb)
	end
	for _, window in CollectionService:GetTagged("NightWindow") do
		applyWindow(window)
	end
end

function WorldService.init()
	setupLighting()

	local day = 1
	workspace:SetAttribute("Day", day)
	local hoursPerSecond = 24 / (Config.DayLengthMinutes * 60)
	local lampsOn: boolean? = nil

	-- Lo que se construya después (casas de jugadores) respeta la hora actual
	CollectionService:GetInstanceAddedSignal("StreetLamp"):Connect(applyLamp)
	CollectionService:GetInstanceAddedSignal("NightWindow"):Connect(applyWindow)

	local sinceCurve = math.huge
	RunService.Heartbeat:Connect(function(dt)
		local previous = Lighting.ClockTime
		local clock = (previous + dt * hoursPerSecond) % 24
		Lighting.ClockTime = clock
		if clock < previous then
			day += 1
			workspace:SetAttribute("Day", day)
		end

		sinceCurve += dt
		if sinceCurve >= 0.5 then
			sinceCurve = 0
			applyCurve(clock)
		end

		local shouldBeOn = clock >= Config.LampsOnAt or clock < Config.LampsOffAt
		if shouldBeOn ~= lampsOn then
			lampsOn = shouldBeOn
			setNight(shouldBeOn)
		end
	end)
end

return WorldService
