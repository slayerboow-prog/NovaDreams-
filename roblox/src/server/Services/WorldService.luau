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
	ensure("Atmosphere", { Density = 0.3, Offset = 0.25, Color = Color3.fromRGB(199, 199, 199), Decay = Color3.fromRGB(106, 112, 125), Glare = 0.2, Haze = 1.5 })
	ensure("BloomEffect", { Intensity = 0.6, Size = 24, Threshold = 1.6 })
	ensure("SunRaysEffect", { Intensity = 0.05, Spread = 0.8 })
	ensure("ColorCorrectionEffect", { Brightness = 0.02, Contrast = 0.08, Saturation = 0.12 })
	ensure("Sky", {})
end

local function setLamps(on: boolean)
	for _, bulb in CollectionService:GetTagged("StreetLamp") do
		local light = bulb:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = on
		end
		if bulb:IsA("BasePart") then
			bulb.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

function WorldService.init()
	setupLighting()

	local day = 1
	workspace:SetAttribute("Day", day)
	local hoursPerSecond = 24 / (Config.DayLengthMinutes * 60)
	local lampsOn: boolean? = nil

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
			setLamps(shouldBeOn)
		end
	end)
end

return WorldService
