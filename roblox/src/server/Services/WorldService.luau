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
	end)
end

return WorldService
