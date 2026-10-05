-- SkyExtras (cliente): lo que se ve del cielo, el tiempo y los efectos con los assets del dueño
-- (shared/SkyExtras; los carga World/SkyAssets). Todo local: no gasta red ni servidor.
--
--   * Cielos especiales encima del de la hora (DayLight.setSkyOverride): isla morada en el sueño del
--     prólogo, verde cuando la Grieta escupe algo, arcoíris al dormir y en los momentos dorados,
--     asteroides en la noche de la lluvia de estrellas, cielo gris (clásico) con lluvia o tormenta y de
--     invierno con nieve.
--   * Luna 3D (8159177542) de noche en Medio y Alto (la 2D de 12737479807 se esconde mientras).
--   * Brillo del sol en la cámara (122782784244668 trae una puerta trasera: este es nuestro, hecho con
--     círculos de la interfaz) cuando miras al sol a cielo abierto. Medio y Alto.
--   * Tormenta: nubes de malla oscuras (979423743) sobre ti, con relámpagos dentro.
--   * Lluvia de estrellas: estelas que cruzan el cielo (con la imagen de cometa del pack de partículas).
--   * Fuego y humo (11365590395): llamas en los fuegos de los incendios y en las chimeneas de las
--     casas por dentro; humo en las chimeneas de fuera cerca de ti.
--   * Agua que se mueve (223224044) en las fuentes de la ciudad. Medio y Alto.
--   * Gota de lluvia (11552439884), copo y hoja (13188926423) en las partículas de Controllers/Weather.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local SkyExtras = require(ReplicatedStorage.Shared.SkyExtras)
local SkyChoice = require(ReplicatedStorage.Shared.SkyChoice)
local DayLight = require(script.Parent.DayLight)
local Perf = require(script.Parent.Parent.UI.Perf)

local Controller = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local DREAM_ORIGIN = Vector3.new(-3400, 700, -3400) -- (World/Kit/DreamIsland.Origin)

local function fx(): Instance?
	return ReplicatedStorage:FindFirstChild(SkyExtras.FxLibrary)
end
local function image(key: string): string?
	local lib = fx()
	local value = lib and lib:GetAttribute(key)
	return if type(value) == "string" and value ~= "" then value else nil
end
local function lowTier(): boolean
	return Perf.tierName() == "Low"
end
local function camera(): Camera
	return workspace.CurrentCamera
end

local function decorPart(name: string, size: Vector3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

---------------------------------------------------------------------
-- Cielo especial
---------------------------------------------------------------------

local function moodNames(): { string }
	local names = {}
	local ok, SkyMoods = pcall(function()
		return require(ReplicatedStorage.Shared.SkyMoods)
	end)
	if not ok or type(SkyMoods) ~= "table" or type(SkyMoods.List) ~= "table" then
		return names
	end
	for _, mood in DayLight.activeMoods() do
		for name, entry in SkyMoods.List do
			if entry == mood then
				table.insert(names, name)
				break
			end
		end
	end
	return names
end

local function updateSky()
	local library = ReplicatedStorage:FindFirstChild(SkyExtras.Library)
	local have = {}
	if library then
		for _, item in library:GetChildren() do
			if item:IsA("Sky") then
				have[item.Name] = true
			end
		end
	end
	local cam = camera()
	local hour = Lighting.ClockTime
	local slot = SkyExtras.pick({
		Prologue = player:GetAttribute("InPrologue") == true or (cam and (cam.CFrame.Position - DREAM_ORIGIN).Magnitude < 450),
		Sleeping = player:GetAttribute("Sleeping") ~= nil and player:GetAttribute("Sleeping") ~= false,
		Moods = moodNames(),
		Weather = workspace:GetAttribute("Weather"),
		Hour = hour,
		Day = workspace:GetAttribute("Day") or 1,
		Night = SkyChoice.phase(hour) == "Night",
	}, have)
	DayLight.setSkyOverride(slot)
end

---------------------------------------------------------------------
-- Luna 3D
---------------------------------------------------------------------

local moon: BasePart? = nil
local moonShown = false
local function buildMoon(): BasePart?
	local lib = fx()
	local source = lib and lib:FindFirstChild("Luna3D")
	if not source or not source:IsA("BasePart") then
		return nil
	end
	local m = source:Clone()
	-- De noche la luz viene DESDE la luna: su cara hacia nosotros quedaría a oscuras. Se pinta con
	-- su propia textura y brillo (como la luna de verdad, que refleja el sol).
	local appearance = m:FindFirstChildOfClass("SurfaceAppearance")
	local colorMap: string? = nil
	if appearance then
		pcall(function()
			colorMap = (appearance :: any).ColorMap
		end)
	end
	if m:IsA("MeshPart") and type(colorMap) == "string" and colorMap ~= "" then
		(appearance :: Instance):Destroy()
		pcall(function()
			(m :: any).TextureID = colorMap
		end)
		m.Material = Enum.Material.Neon
		m.Color = rgb(150, 150, 146)
	else
		local glow = Instance.new("Highlight")
		glow.FillColor = rgb(235, 235, 225)
		glow.FillTransparency = 0.55
		glow.OutlineTransparency = 1
		glow.DepthMode = Enum.HighlightDepthMode.Occluded
		glow.Parent = m
	end
	local d = SkyExtras.moonDiameter(SkyExtras.MoonDistance, SkyExtras.MoonDegrees)
	local biggest = math.max(m.Size.X, m.Size.Y, m.Size.Z, 0.01)
	m.Size = m.Size * (d / biggest)
	m.Anchored = true
	m.CanCollide = false
	m.CanQuery = false
	m.CanTouch = false
	m.CastShadow = false
	m.Name = "Luna3D"
	return m
end

local function setSkyMoon(show2D: boolean)
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		local size = if show2D then SkyExtras.Moon.AngularSize else 0
		if sky.MoonAngularSize ~= size then
			sky.MoonAngularSize = size
		end
	end
end

local function updateMoon()
	local cam = camera()
	local dir = Lighting:GetMoonDirection()
	local want = not lowTier() and SkyExtras.moonVisible(Lighting.ClockTime, dir.Y)
	if want and not moon then
		moon = buildMoon()
	end
	if not moon then
		if moonShown then
			setSkyMoon(true)
			moonShown = false
		end
		return
	end
	if want then
		local m = moon :: BasePart
		m.CFrame = CFrame.lookAt(cam.CFrame.Position + dir * SkyExtras.MoonDistance, cam.CFrame.Position)
		if m.Parent ~= cam then
			m.Parent = cam
		end
		if not moonShown then
			setSkyMoon(false)
			moonShown = true
		end
	elseif moonShown then
		(moon :: BasePart).Parent = nil
		setSkyMoon(true)
		moonShown = false
	end
end

---------------------------------------------------------------------
-- Brillo del sol en la cámara (nuestro)
---------------------------------------------------------------------

local glareGui: ScreenGui? = nil
local glareDots: { { Frame: Frame, At: number, Alpha: number } } = {}
local GLARE = {
	{ At = 0, Size = 0.34, Alpha = 0.78, Color = rgb(255, 244, 214) },
	{ At = 0.35, Size = 0.05, Alpha = 0.86, Color = rgb(255, 214, 160) },
	{ At = 0.6, Size = 0.09, Alpha = 0.9, Color = rgb(190, 230, 255) },
	{ At = 0.95, Size = 0.04, Alpha = 0.88, Color = rgb(255, 190, 150) },
	{ At = 1.3, Size = 0.13, Alpha = 0.93, Color = rgb(170, 210, 255) },
	{ At = 1.7, Size = 0.07, Alpha = 0.9, Color = rgb(255, 230, 190) },
}
local function buildGlare()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrilloSol"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -5
	gui.Enabled = false
	for _, def in GLARE do
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = def.Color
		f.BorderSizePixel = 0
		f.Size = UDim2.fromScale(def.Size, def.Size)
		f.SizeConstraint = Enum.SizeConstraint.RelativeYY
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = f
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		fade.Parent = f
		f.Parent = gui
		table.insert(glareDots, { Frame = f, At = def.At, Alpha = def.Alpha })
	end
	gui.Parent = player:WaitForChild("PlayerGui")
	glareGui = gui
end

local sunParams = RaycastParams.new()
sunParams.FilterType = Enum.RaycastFilterType.Exclude
local glareAmount = 0
local function updateGlare(dt: number)
	if not glareGui then
		return
	end
	local cam = camera()
	local sun = Lighting:GetSunDirection()
	local weather = workspace:GetAttribute("Weather")
	local clear = weather == nil or weather == "Despejado" or weather == "Nublado"
	local target = 0
	local screen = Vector3.zero
	if not lowTier() and clear and sun.Y > 0.03 then
		local point, onScreen = cam:WorldToViewportPoint(cam.CFrame.Position + sun * 1000)
		local facing = cam.CFrame.LookVector:Dot(sun)
		if onScreen and facing > 0.6 then
			local character = player.Character
			sunParams.FilterDescendantsInstances = if character then { character, cam } else { cam }
			local blocked = workspace:Raycast(cam.CFrame.Position, sun * 900, sunParams)
			if not blocked then
				target = math.clamp((facing - 0.6) / 0.35, 0, 1)
				if weather == "Nublado" then
					target *= 0.5
				end
				screen = point
			end
		end
	end
	glareAmount += (target - glareAmount) * math.min(1, dt * 6)
	local gui = glareGui :: ScreenGui
	gui.Enabled = glareAmount > 0.02
	if not gui.Enabled then
		return
	end
	local view = cam.ViewportSize
	local center = Vector2.new(view.X / 2, view.Y / 2)
	local sunAt = Vector2.new(screen.X, screen.Y)
	for _, dot in glareDots do
		local at = sunAt + (center - sunAt) * dot.At * 2
		dot.Frame.Position = UDim2.fromOffset(at.X, at.Y)
		dot.Frame.BackgroundTransparency = 1 - (1 - dot.Alpha) * glareAmount
	end
end

---------------------------------------------------------------------
-- Nubes de tormenta y lluvia de estrellas
---------------------------------------------------------------------

local stormClouds: { BasePart } = {}
local stormLights: { PointLight } = {}
local nextBolt = 0
local CLOUD_SPOTS = { Vector3.new(-180, 0, -120), Vector3.new(160, 30, -200), Vector3.new(40, -20, 210), Vector3.new(-240, 10, 150), Vector3.new(260, 20, 90) }

local function clearStorm()
	for _, c in stormClouds do
		c:Destroy()
	end
	table.clear(stormClouds)
	table.clear(stormLights)
end

local function bolt(cloud: BasePart)
	local rayo = image("Img_Rayo")
	if not rayo then
		return
	end
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromScale(40, 180)
	board.StudsOffsetWorldSpace = Vector3.new(0, -100, 0)
	board.LightInfluence = 0
	board.AlwaysOnTop = false
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = rayo
	img.ImageColor3 = rgb(220, 225, 255)
	img.Parent = board
	board.Parent = cloud
	task.delay(0.18, function()
		board:Destroy()
	end)
end

local function updateStorm()
	local storm = workspace:GetAttribute("Weather") == "Tormenta"
	local lib = fx()
	local source = lib and lib:FindFirstChild("NubeTormenta")
	if not storm or lowTier() or not source or not source:IsA("BasePart") then
		if #stormClouds > 0 then
			clearStorm()
		end
		return
	end
	local cam = camera()
	local base = cam.CFrame.Position * Vector3.new(1, 0, 1) + Vector3.new(0, 300, 0)
	if #stormClouds == 0 then
		for i, offset in CLOUD_SPOTS do
			local c = source:Clone() :: BasePart
			local big = math.max(c.Size.X, c.Size.Y, c.Size.Z, 0.01)
			local scale = (160 + i * 25) / big
			c.Size = c.Size * scale
			local mesh = c:FindFirstChildWhichIsA("SpecialMesh")
			if mesh then
				mesh.Scale = mesh.Scale * scale
				mesh.VertexColor = Vector3.new(0.32, 0.33, 0.36)
			end
			c.Color = rgb(70, 72, 80)
			c.Anchored = true
			c.CanCollide = false
			c.CanQuery = false
			c.CastShadow = false
			local light = Instance.new("PointLight")
			light.Color = rgb(200, 205, 255)
			light.Range = 60
			light.Brightness = 0
			light.Shadows = false
			light.Parent = c
			c:SetAttribute("Offset", offset)
			c.Parent = cam
			table.insert(stormClouds, c)
			table.insert(stormLights, light)
		end
	end
	for _, c in stormClouds do
		local offset = c:GetAttribute("Offset") or Vector3.zero
		-- (se van moviendo con el viento, despacio)
		local drift = Vector3.new(math.sin(os.clock() / 40) * 30, 0, math.cos(os.clock() / 55) * 30)
		c.CFrame = CFrame.new(base + offset + drift)
	end
	if os.clock() > nextBolt then
		nextBolt = os.clock() + 5 + math.random() * 9
		local i = math.random(1, #stormClouds)
		local light = stormLights[i]
		task.spawn(function()
			for _ = 1, 2 do
				light.Brightness = 8
				task.wait(0.07)
				light.Brightness = 0
				task.wait(0.09)
			end
		end)
		bolt(stormClouds[i])
	end
end

local nextMeteor = 0
local function meteor()
	local cam = camera()
	local yaw = math.random() * math.pi * 2
	local start = Vector3.new(math.cos(yaw), 0.55 + math.random() * 0.35, math.sin(yaw)).Unit * 700
	local across = Vector3.new(-math.sin(yaw), -0.35, math.cos(yaw)).Unit * (140 + math.random() * 120)
	local p = decorPart("Estrella", Vector3.new(1.6, 1.6, 1.6))
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Color = rgb(255, 240, 210)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.8, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.8, 0)
	a1.Parent = p
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.45
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(rgb(255, 245, 220), rgb(160, 200, 255))
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	local comet = image("Img_Cometa")
	if comet then
		trail.Texture = comet
	end
	trail.Parent = p
	local from = cam.CFrame.Position + start
	p.CFrame = CFrame.new(from)
	p.Parent = cam
	local t0 = os.clock()
	local life = 0.9 + math.random() * 0.6
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / life
		if k >= 1 or not p.Parent then
			conn:Disconnect()
			p:Destroy()
			return
		end
		p.CFrame = CFrame.new(camera().CFrame.Position + start + across * k)
	end)
end

local function updateMeteors()
	local day = workspace:GetAttribute("Day") or 1
	if not SkyExtras.meteorNight(day, Lighting.ClockTime) or os.clock() < nextMeteor then
		return
	end
	nextMeteor = os.clock() + (if lowTier() then 2.5 else 0.7) + math.random() * 1.8
	meteor()
end

---------------------------------------------------------------------
-- Fuego, humo de chimeneas y agua de las fuentes
---------------------------------------------------------------------

local chimneys: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local smoking: { [BasePart]: ParticleEmitter } = setmetatable({}, { __mode = "k" }) :: any
local flamed: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function flamesFor(part: BasePart, rate: number, size: number): ParticleEmitter?
	local lib = fx()
	local source = lib and lib:FindFirstChild("Fuego")
	local template = source and source:FindFirstChild("Llamas")
	if not template or not template:IsA("ParticleEmitter") then
		return nil
	end
	local e = template:Clone()
	e.Name = "LlamasReales"
	e.Rate = rate
	pcall(function()
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, size * 0.6),
			NumberSequenceKeypoint.new(0.4, size),
			NumberSequenceKeypoint.new(1, size * 0.2),
		})
	end)
	e.Parent = part
	return e
end

-- Un fuego de Roblox (incendios de FireService): llamas de verdad encima, encendidas a la vez
local function dressFire(fire: Fire)
	if flamed[fire] or lowTier() then
		return
	end
	local part = fire.Parent
	if not part or not part:IsA("BasePart") then
		return
	end
	flamed[fire] = true
	local e = flamesFor(part, 40, math.clamp(fire.Size * 0.35, 1, 4))
	if not e then
		flamed[fire] = nil
		return
	end
	local emitter = e :: ParticleEmitter
	local function sync()
		emitter.Enabled = fire.Enabled and fire.Parent ~= nil
	end
	sync()
	fire:GetPropertyChangedSignal("Enabled"):Connect(sync)
	fire.AncestryChanged:Connect(function()
		if not fire.Parent then
			emitter:Destroy()
		end
	end)
end

local function consider(item: Instance)
	if item:IsA("Fire") then
		task.defer(dressFire, item)
	elseif item:IsA("BasePart") then
		if item.Name == "Chimney" then
			local parent = item.Parent
			if parent and parent.Name ~= "Fireplace" then
				chimneys[item] = true
			end
		elseif item.Name == "Fire" and item.Parent and item.Parent.Name == "Fireplace" and not flamed[item] then
			flamed[item] = true
			task.defer(function()
				if not lowTier() then
					flamesFor(item, 22, 1.1)
				end
			end)
		end
	end
end

local function smokeFor(part: BasePart): ParticleEmitter
	local holder = Instance.new("Attachment")
	holder.Name = "HumoChimenea"
	-- (arriba de la chimenea: el lado más largo es la altura, también en las cilíndricas tumbadas)
	local up = part.CFrame:VectorToObjectSpace(Vector3.yAxis)
	local half = part.Size / 2
	holder.Position = up * (math.abs(up.X) * half.X + math.abs(up.Y) * half.Y + math.abs(up.Z) * half.Z + 0.5)
	holder.Parent = part
	local e = Instance.new("ParticleEmitter")
	e.Texture = image("Img_Humo") or "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(rgb(196, 196, 200), rgb(150, 150, 156))
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.6, 0.78),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Size = NumberSequence.new(1.6, 7)
	e.Lifetime = NumberRange.new(5, 8)
	e.Speed = NumberRange.new(3, 5)
	e.Acceleration = Vector3.new(1.2, 0.6, 0.4)
	e.SpreadAngle = Vector2.new(8, 8)
	e.EmissionDirection = Enum.NormalId.Top
	e.RotSpeed = NumberRange.new(-15, 15)
	e.Rate = 2.5
	e.LightInfluence = 1
	e.Parent = holder
	return e
end

local function updateChimneys()
	local cam = camera().CFrame.Position
	local hour = Lighting.ClockTime
	-- (más humo con frío, por la mañana temprano y al anochecer: se enciende la calefacción)
	local cold = workspace:GetAttribute("Season") == "Invierno" or workspace:GetAttribute("Season") == "Otoño"
	local wanted = if lowTier() then 3 else 10
	if not cold and hour > 9 and hour < 18 then
		wanted = math.floor(wanted / 3)
	end
	local list = {}
	for part in chimneys do
		if part.Parent then
			local d = (part.Position - cam).Magnitude
			if d < 380 then
				table.insert(list, { Part = part, D = d })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.D < b.D
	end)
	local keep = {}
	for i = 1, math.min(wanted, #list) do
		keep[list[i].Part] = true
	end
	for part, e in smoking do
		if not keep[part] then
			e.Enabled = false
		end
	end
	for part in keep do
		local e = smoking[part]
		if not e then
			e = smokeFor(part)
			smoking[part] = e
		end
		e.Enabled = true
	end
end

local fountainTextures: { [BasePart]: Texture } = setmetatable({}, { __mode = "k" }) :: any
local function updateWater(dt: number)
	local water = image("Agua1")
	if not water or lowTier() then
		for _, t in fountainTextures do
			t.Transparency = 1
		end
		return
	end
	local cam = camera().CFrame.Position
	for _, fountain in CollectionService:GetTagged("Fountain") do
		local part = fountain:FindFirstChild("FountainWater")
		if part and part:IsA("BasePart") then
			local tex = fountainTextures[part]
			if not tex then
				tex = Instance.new("Texture")
				tex.Name = "AguaQueSeMueve"
				tex.Texture = water
				tex.Face = Enum.NormalId.Right -- (la fuente es un cilindro tumbado: la cara de arriba es +X)
				tex.StudsPerTileU = 6
				tex.StudsPerTileV = 6
				tex.Color3 = rgb(170, 210, 240)
				tex.Parent = part
				fountainTextures[part] = tex
			end
			local t = tex :: Texture
			local near = (part.Position - cam).Magnitude < 260
			t.Transparency = if near then 0.55 else 1
			if near then
				t.OffsetStudsU = (t.OffsetStudsU + dt * 0.6) % 6
				t.OffsetStudsV = (t.OffsetStudsV + dt * 0.35) % 6
			end
		end
	end
end

---------------------------------------------------------------------
-- Imágenes en las partículas de Controllers/Weather
---------------------------------------------------------------------

local weatherDressed = false
local function dressWeather()
	if weatherDressed then
		return
	end
	local holder = camera():FindFirstChild("WeatherSky")
	local rainImage = image("LluviaImagen")
	if not holder or not rainImage then
		return
	end
	weatherDressed = true
	local rain = holder:FindFirstChild("Rain")
	if rain and rain:IsA("ParticleEmitter") then
		rain.Texture = rainImage
		rain.Size = NumberSequence.new(0.16)
		rain.Squash = NumberSequence.new(-1.5)
	end
	local copo = image("Img_Copo")
	local snow = holder:FindFirstChild("Snow")
	if copo and snow and snow:IsA("ParticleEmitter") then
		snow.Texture = copo
	end
	local hoja = image("Img_Hoja")
	local falling = holder:FindFirstChild("Falling")
	if hoja and falling and falling:IsA("ParticleEmitter") then
		falling.Texture = hoja
	end
end

---------------------------------------------------------------------

function Controller.init()
	pcall(buildGlare)
	task.spawn(function()
		for i, item in workspace:GetDescendants() do
			consider(item)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)
	workspace.DescendantAdded:Connect(consider)

	local slow, slower = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(function()
			updateMoon()
			updateGlare(dt)
			updateWater(dt)
		end)
		if not ok then
			warn("[SkyExtras] " .. tostring(err))
		end
		slow += dt
		slower += dt
		if slow >= 0.5 then
			slow = 0
			local ok2, err2 = pcall(function()
				updateSky()
				updateStorm()
				updateMeteors()
				dressWeather()
			end)
			if not ok2 then
				warn("[SkyExtras] " .. tostring(err2))
			end
		end
		if slower >= 2 then
			slower = 0
			pcall(updateChimneys)
		end
	end)
end

return Controller
