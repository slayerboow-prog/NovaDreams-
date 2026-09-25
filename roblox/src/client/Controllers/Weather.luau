-- Weather (cliente): pinta la estación y el tiempo que decide el servidor (WeatherService).
--  * Lluvia, tormenta (con relámpagos), nieve, niebla: partículas alrededor de la cámara (no dentro de casa)
--  * Pétalos en primavera y hojas cayendo en otoño
--  * Las copas de los árboles, los arbustos y la hierba cambian de color con la estación y la nieve
--  * El cielo: nubes, luz y color (a través de DayLight.setModifier)
--  * Una etiqueta pequeña con la estación y el tiempo («🍂 Otoño · 🌧️ Lluvia»)
-- Todo pasa en el dispositivo de cada jugador: no gasta red ni servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local DayLight = require(script.Parent.DayLight)
local Hud = require(script.Parent.Parent.UI.Hud)

local Weather = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local SNOW_WHITE = rgb(236, 240, 246)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local emitterPart: BasePart
local rain: ParticleEmitter
local snow: ParticleEmitter
local falling: ParticleEmitter
local rainSound: Sound?
local thunderSound: Sound?
local label: TextLabel

local season = "Primavera"
local weather = "Despejado"
local snowCover = 0
local flash = 0 -- relámpago (0..1, se apaga solo)
local nextLightning = 0
local indoor = false

---------------------------------------------------------------------
-- Colores de la naturaleza según la estación
---------------------------------------------------------------------

local foliage: { [BasePart]: Color3 } = {} -- color original de cada copa, arbusto o seto
local terrainBase: { [Enum.Material]: Color3 } = {}
local NATURE_NAMES = { Leaves = true, Bush = true, Hedge = true, Plant = true }

local function track(part: Instance)
	if part:IsA("BasePart") and NATURE_NAMES[part.Name] and part.Material == Enum.Material.LeafyGrass and not foliage[part] then
		foliage[part] = part.Color
	end
end

local function repaint()
	local info = Seasons.Info[season]
	if not info then
		return
	end
	for part, base in foliage do
		if part.Parent then
			local color = base:Lerp(info.Leaves, info.LeafMix)
			part.Color = color:Lerp(SNOW_WHITE, snowCover * 0.75)
		else
			foliage[part] = nil
		end
	end
	local terrain = workspace.Terrain
	for material, base in terrainBase do
		local color = base:Lerp(info.Grass, 0.6)
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

	rain = emitter("Rain", {
		Texture = SMOKE,
		Color = ColorSequence.new(rgb(200, 210, 225)),
		LightEmission = 0.1,
		Transparency = NumberSequence.new(0.35),
		Size = NumberSequence.new(0.09),
		Squash = NumberSequence.new(-3.2), -- gotas estiradas
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Speed = NumberRange.new(90, 110),
		Acceleration = Vector3.new(0, -40, 0),
		EmissionDirection = Enum.NormalId.Bottom,
		Lifetime = NumberRange.new(0.9, 1.1),
		SpreadAngle = Vector2.new(4, 4),
		Rate = 0,
	})
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
	local sounds = Config.Seasons and Config.Seasons.Sounds or {}
	if (sounds.Rain or 0) ~= 0 then
		rainSound = Instance.new("Sound")
		rainSound.SoundId = "rbxassetid://" .. sounds.Rain
		rainSound.Looped = true
		rainSound.Volume = 0
		rainSound.Parent = workspace.CurrentCamera
		rainSound:Play()
	end
	if (sounds.Thunder or 0) ~= 0 then
		thunderSound = Instance.new("Sound")
		thunderSound.SoundId = "rbxassetid://" .. sounds.Thunder
		thunderSound.Volume = 0.6
		thunderSound.Parent = workspace.CurrentCamera
	end
end

-- ¿Hay techo encima de la cámara? (dentro de casa no llueve)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function underRoof(): boolean
	local camera = workspace.CurrentCamera
	local character = player.Character
	rayParams.FilterDescendantsInstances = if character then { character, camera } else { camera }
	local hit = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, 80, 0), rayParams)
	return hit ~= nil and hit.Instance.Transparency < 0.5 and hit.Material ~= Enum.Material.LeafyGrass
end

local function updateParticles()
	local info = Seasons.Weather[weather] or Seasons.Weather.Despejado
	local seasonInfo = Seasons.Info[season]
	local camera = workspace.CurrentCamera
	local position = camera.CFrame.Position
	-- La "nube" que suelta las partículas va delante y encima de la cámara
	local ahead = camera.CFrame.LookVector * Vector3.new(1, 0, 1) * 20
	emitterPart.CFrame = CFrame.new(position + ahead + Vector3.new(0, if info.Snow then 35 else 45, 0))
	local off = indoor
	rain.Rate = if off then 0 else (info.Rain or 0) * 900
	rain.Enabled = rain.Rate > 0
	snow.Rate = if off then 0 else (info.Snow or 0) * 260
	snow.Enabled = snow.Rate > 0
	local kind = seasonInfo and seasonInfo.Particles
	if kind and not off and not info.Rain and not info.Snow then
		falling.Color = ColorSequence.new(if kind == "Hojas" then rgb(214, 120, 44) else rgb(250, 196, 214))
		falling.Rate = if kind == "Hojas" then 14 else 8
		falling.Enabled = true
	else
		falling.Enabled = false
	end
	if rainSound then
		rainSound.Volume = if info.Rain and not off then 0.5 * info.Rain else (if info.Rain then 0.15 else 0)
	end
end

---------------------------------------------------------------------
-- El cielo: se lo pasamos a DayLight para que lo mezcle con la luz de la hora
---------------------------------------------------------------------

local function skyModifier(k: { [string]: any }): { [string]: any }
	local info = Seasons.Weather[weather] or Seasons.Weather.Despejado
	local seasonInfo = Seasons.Info[season] or {}
	local out = table.clone(k)
	out.Brightness = k.Brightness * info.Brightness + flash * 4
	out.Exposure = k.Exposure + flash * 0.6
	out.Saturation = k.Saturation + info.Saturation
	out.Density = math.clamp(k.Density + info.Density, 0, 0.8)
	if info.Cover then
		out.Cover = math.max(k.Cover, info.Cover)
		out.CloudColor = k.CloudColor:Lerp(rgb(110, 114, 124), (info.Rain or 0) * 0.5 + (if info.Lightning then 0.2 else 0))
	end
	if seasonInfo.Warm then
		out.Tint = k.Tint:Lerp(rgb(255, 236, 214), seasonInfo.Warm)
	elseif seasonInfo.Cold then
		out.Tint = k.Tint:Lerp(rgb(220, 232, 255), seasonInfo.Cold)
	end
	if info.Rain then
		out.Tint = out.Tint:Lerp(rgb(214, 222, 236), 0.25)
	end
	return out
end

---------------------------------------------------------------------

local function buildLabel()
	-- Debajo del minimapa (arriba a la derecha), con el mismo estilo y escala que el HUD
	local gui = Instance.new("ScreenGui")
	gui.Name = "WeatherChip"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 2
	gui.Parent = player:WaitForChild("PlayerGui")
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local camera = workspace.CurrentCamera
	local function rescale()
		local v = camera.ViewportSize
		scale.Scale = math.clamp(math.min(v.Y / 900, v.X / 1700), 0.55, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(1, -110, 0, 296) -- centrado bajo el minimapa (176 px, a 22 px del borde)
	label.Size = UDim2.fromOffset(200, 26)
	label.BackgroundColor3 = Color3.fromRGB(12, 22, 42)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.Text = ""
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 140, 240)
	stroke.Transparency = 0.55
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = label
end

local function refreshState()
	local newSeason = workspace:GetAttribute("Season") or "Primavera"
	local newWeather = workspace:GetAttribute("Weather") or "Despejado"
	local newSnow = workspace:GetAttribute("Snow") or 0
	local changed = newSeason ~= season or math.abs(newSnow - snowCover) > 0.04
	-- Avisos cuando cambia la estación o empieza algo llamativo (no al entrar al juego)
	if label and label.Text ~= "" then
		local info = Seasons.Info[newSeason]
		if newSeason ~= season and info then
			Hud.toast("Info", ("%s Llega %s"):format(info.Icon, ({ Primavera = "la primavera", Verano = "el verano", Otono = "el otoño", Invierno = "el invierno" })[newSeason] or info.Name))
		elseif newWeather ~= weather and (newWeather == "Tormenta" or newWeather == "Nieve" or newWeather == "Lluvia") then
			local w = Seasons.Weather[newWeather]
			Hud.toast("Info", ("%s %s"):format(w.Icon, ({ Tormenta = "¡Se acerca una tormenta!", Nieve = "Empieza a nevar", Lluvia = "Empieza a llover" })[newWeather]))
		end
	end
	season, weather = newSeason, newWeather
	if changed then
		snowCover = newSnow
		repaint()
	end
	if label then
		label.Text = Seasons.label(season, weather)
	end
end

function Weather.init()
	buildEmitters()
	buildLabel()
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
		since = 0
		indoor = underRoof()
		local ok, err = pcall(updateParticles)
		if not ok then
			warn("[Weather] " .. tostring(err))
		end
		-- Relámpagos de tormenta: un destello cada 8-20 segundos y el trueno un poco después
		local info = Seasons.Weather[weather]
		if info and info.Lightning and os.clock() > nextLightning then
			nextLightning = os.clock() + 8 + math.random() * 12
			flash = 1
			if thunderSound then
				task.delay(0.6 + math.random() * 1.5, function()
					thunderSound:Play()
				end)
			end
		end
	end)
end

return Weather
