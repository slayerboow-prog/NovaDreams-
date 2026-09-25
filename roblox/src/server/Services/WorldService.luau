-- WorldService: ciclo día/noche, farolas y efectos de iluminación para dar ambiente.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)

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
		(Lighting :: any).PrioritizeLightingQuality = false -- respeta la calidad gráfica de cada jugador
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

-- Luz del faro (se enciende con las farolas)
local function lighthouse(on: boolean)
	for _, lamp in CollectionService:GetTagged("FaroLuz") do
		for _, light in lamp:GetChildren() do
			if light:IsA("Light") then
				light.Enabled = on
			end
		end
		if lamp:IsA("BasePart") then
			lamp.Material = if on then Enum.Material.Neon else Enum.Material.Glass
		end
	end
end

-- Las farolas no se encienden todas a la vez (cada fotocélula tarda un poco distinto)
local function setNight(on: boolean)
	night = on
	lighthouse(on)
	for _, bulb in CollectionService:GetTagged("StreetLamp") do
		task.delay(math.random() * 6, applyLamp, bulb)
	end
end

---------------------------------------------------------------------
-- Faro (luz giratoria de noche) y barca del puerto a la isla
---------------------------------------------------------------------
local function spinLighthouse()
	local angle = 0
	while true do
		local dt = task.wait(0.1)
		if night then
			angle = (angle + dt * math.pi / 4) % (math.pi * 2) -- una vuelta cada 8 segundos
			for _, lamp in CollectionService:GetTagged("FaroLuz") do
				if lamp:IsA("BasePart") then
					lamp.CFrame = CFrame.new(lamp.Position) * CFrame.Angles(0, angle, 0)
				end
			end
		end
	end
end

local ferryBusy: { [Player]: boolean } = {}
local function setupFerry(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	prompt.Triggered:Connect(function(player)
		local target = prompt:GetAttribute("Target")
		local character = player.Character
		if ferryBusy[player] or typeof(target) ~= "Vector3" or not character or player:GetAttribute("Riding") then
			return
		end
		ferryBusy[player] = true
		local notify = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Notify")
		if notify then
			(notify :: RemoteEvent):FireClient(player, "Travel", "⛵ " .. prompt.ActionText .. "...")
		end
		task.wait(0.8)
		if character.Parent then
			character:PivotTo(CFrame.new(target))
		end
		ferryBusy[player] = nil
	end)
end

---------------------------------------------------------------------
-- Lugares del mapa: ReplicatedStorage.MapLandmarks (lo lee el mapa de cada jugador)
---------------------------------------------------------------------
local function publishLandmarks()
	local town = workspace:FindFirstChild("Town")
	if not town then
		return
	end
	type Found = { Kind: string, Position: Vector3, Count: number }
	local found: { Found } = {}
	for _, model in town:GetDescendants() do
		local kind = model:IsA("Model") and MapInfo.KindByModel[model.Name]
		if kind then
			local ok, cf = pcall(function()
				return (model :: Model):GetBoundingBox()
			end)
			if ok then
				local position = cf.Position
				-- Las playas y granjas son varias manzanas: se juntan en un solo punto
				local merged = false
				if kind.Merge then
					for _, other in found do
						if other.Kind == kind.Model and (other.Position - position).Magnitude < kind.Merge then
							other.Position = (other.Position * other.Count + position) / (other.Count + 1)
							other.Count += 1
							merged = true
							break
						end
					end
				end
				if not merged then
					table.insert(found, { Kind = kind.Model, Position = position, Count = 1 })
				end
			end
		end
	end
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks") or Instance.new("Folder")
	folder.Name = "MapLandmarks"
	folder:ClearAllChildren()
	for i, place in found do
		local config = Instance.new("Configuration")
		config.Name = place.Kind .. i
		config:SetAttribute("Kind", place.Kind)
		config:SetAttribute("Position", Vector3.new(place.Position.X, 0, place.Position.Z))
		local district = MapInfo.districtAt(place.Position.X, place.Position.Z)
		config:SetAttribute("District", if district then district.Name else "")
		config.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

function WorldService.init()
	setupLighting()
	publishLandmarks()
	for _, prompt in CollectionService:GetTagged("Ferry") do
		setupFerry(prompt)
	end
	CollectionService:GetInstanceAddedSignal("Ferry"):Connect(setupFerry)
	Players.PlayerRemoving:Connect(function(player)
		ferryBusy[player] = nil
	end)
	task.spawn(spinLighthouse)

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
