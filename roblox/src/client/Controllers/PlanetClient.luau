-- PlanetClient (cliente): los planetas de cerca y bajar a ellos sin pantalla de carga (docs/planetas.md).
--
--   * En el espacio, cada planeta es una ESFERA con su textura (shared/Cosmos/PlanetBodies.view: una
--     esfera impostora más cerca de la cámara con el mismo tamaño en pantalla; la estrella de
--     Controllers/SpaceClient se apaga a la vez que crece la esfera), su capa de nubes y el aro de su
--     atmósfera. Sin texturas subidas: colores y materiales (shared/Cosmos/EspacioLook).
--   * Entrar (shared/Cosmos/PlanetEntry): vuela hacia un planeta abierto y, en su atmósfera, el casco se
--     calienta (brillo y plasma delante del morro), la cámara tiembla, las nubes llegan y tapan la
--     pantalla y el cielo pasa del negro al del planeta. Los mandos son tuyos todo el rato. Abajo del
--     todo se pide "Descend": el servidor mueve la nave a la superficie (misma velocidad y rumbo) y las
--     nubes se abren sobre Lontana. Subir hasta el techo hace lo mismo al revés.
--   * Cerrados: un planeta «próximamente» (o sin la Saga 1) aparta la nave de su atmósfera y lo dice.
--   * En la superficie: cielo malva con la luna Ovilla (Sky «CieloLontana» si está subido), bruma, luz
--     y color propios, agua del color del planeta, ceniza y pelusa que caen (shared/AirCombat/FxBudget).
--   * Aterrizar y despegar: shared/Cosmos/Landing (en Controllers/AirCombatClient). BAJAR (Salir) te
--     baja con la nave posada; «Subir a la nave» junto a ella para volver.
--   * VISOR (botón, tecla I, mando L3): durante unos segundos marca el mineral cercano (Highlight) y los
--     puntos de interés con su distancia.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Layers = require(Cosmos.Layers)
local PlanetBodies = require(Cosmos.PlanetBodies)
local PlanetEntry = require(Cosmos.PlanetEntry)
local Planets = require(Cosmos.Planets)
local Lontana = require(Cosmos.Lontana)
local Zone = require(Cosmos.Zone)
local Mining = require(Cosmos.Mining)
local EspacioLook = require(Cosmos.EspacioLook)
local EspacioTextureIds = require(Cosmos.EspacioTextureIds)
local FxBudget = require(ReplicatedStorage.Shared.AirCombat.FxBudget)
local AirCombatClient = require(script.Parent.AirCombatClient)
local SpaceClient = require(script.Parent.SpaceClient)
local CameraShake = require(script.Parent.CameraShake)
local SoundFx = require(script.Parent.SoundFx)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)

local PlanetClient = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local STEP = "PlanetClientStep"
local VISOR_KEYS = "PlanetVisor"
local rgb = Color3.fromRGB

PlanetClient.VisorSeconds = 12
PlanetClient.VisorRange = 520
PlanetClient.VisorMaxHighlights = 16

-- Las superficies que hay (las demás, «próximamente»)
local SURFACES: { [string]: any } = { Lontana = Lontana }

local remote: RemoteEvent? = nil
local entry = PlanetEntry.new()
local open: { [string]: string } = {} -- [id] = estado ("Ready", "Soon", "Locked", "Order")
local deniedUntil: { [string]: number } = {}
local lastStatusAsk = -math.huge
local lastNear = -math.huge
local soonToastAt: { [string]: number } = {}
local lastShake = 0
local skyOwned = false
local onSurface = false
local savedWater: Color3? = nil
local visorUntil = 0
local visorCool = 0
local visorMarks: { Instance } = {}

local function fire(...)
	if remote then
		remote:FireServer(...)
	end
end

local function ids(): { [string]: string }
	local ok, map = pcall(function()
		return require(ReplicatedStorage.Shared.Images).map(EspacioTextureIds)
	end)
	return if ok and type(map) == "table" then map else EspacioTextureIds
end

local function budget(): FxBudget.Budget
	local attr = player:GetAttribute("GraphicsTier")
	return FxBudget.get(if type(attr) == "string" then attr else nil)
end

local function isOpen(id: string): boolean
	return open[id] == "Ready" and SURFACES[id] ~= nil and os.clock() >= (deniedUntil[id] or 0)
end
PlanetClient.isOpen = isOpen

---------------------------------------------------------------------
-- Geometría para la nave (Controllers/AirCombatClient)
---------------------------------------------------------------------
local function groundFor(id: string?): any
	local S = SURFACES[id or ""]
	if not S then
		return nil
	end
	return function(x: number, z: number): (number, boolean, number)
		local h, water = S.groundAt(x, z)
		return h, water, S.slopeAt(x, z)
	end
end

-- En el espacio: lo de siempre, y los planetas cerrados apartan la nave de su atmósfera
local function cosmosBounds(pos: Vector3): Vector3?
	local back = Zone.bounds(pos)
	local push = PlanetBodies.repel(pos, isOpen)
	if push then
		back = if back then (back + push * 2).Unit else push
	end
	return back
end

---------------------------------------------------------------------
-- Los planetas en el espacio (esfera, nubes, aro)
---------------------------------------------------------------------
type BodyView = { Body: PlanetBodies.Body, Sphere: BasePart, Clouds: BasePart?, Halo: BillboardGui, HaloImage: GuiObject, Anchor: BasePart }
local bodyViews: { [string]: BodyView } = {}
local bodyFolder: Folder? = nil
local bodiesShown = false

local function sphere(name: string, color: Color3, texture: string?, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = Vector3.one * 100
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if texture then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.TextureId = texture
		mesh.Parent = p
		p.Color = rgb(255, 255, 255)
	end
	p.Parent = parent
	return p
end

local function buildBodies()
	if bodyFolder then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "PlanetasCuerpos"
	folder.Parent = workspace.CurrentCamera
	bodyFolder = folder
	local map = ids()
	local gui = player:WaitForChild("PlayerGui")
	for _, b in PlanetBodies.List do
		local look = EspacioLook.planet(map, b.Id)
		local s = sphere("Planeta" .. b.Id, b.Ground, look.Texture, folder)
		local clouds: BasePart? = nil
		if b.Clouds and look.Clouds and budget().Clouds then
			clouds = sphere("Nubes" .. b.Id, rgb(255, 255, 255), look.Clouds, folder)
		elseif b.Clouds and not look.Texture then
			-- (sin texturas: un casquete de otro color para que no sea una bola lisa)
			local cap = sphere("Casquete" .. b.Id, b.Band, nil, folder)
			cap.Transparency = 0.25
			clouds = cap
		end
		local anchor = Instance.new("Part")
		anchor.Name = "Aro" .. b.Id
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanTouch = false
		anchor.CanQuery = false
		anchor.Transparency = 1
		anchor.Size = Vector3.one
		anchor.Parent = folder
		local bb = Instance.new("BillboardGui")
		bb.Name = "AtmosferaPlaneta" .. b.Id
		bb.Adornee = anchor
		bb.LightInfluence = 0
		bb.AlwaysOnTop = false
		bb.ResetOnSpawn = false
		bb.Enabled = false
		bb.Parent = gui
		local halo: GuiObject
		if look.Halo then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Image = look.Halo
			img.ImageColor3 = b.Halo
			img.Size = UDim2.fromScale(1, 1)
			img.Parent = bb
			halo = img
		else
			-- (sin imagen: un aro con borde y degradado)
			local f = Instance.new("Frame")
			f.BackgroundTransparency = 1
			f.Size = UDim2.fromScale(0.82, 0.82)
			f.Position = UDim2.fromScale(0.09, 0.09)
			f.Parent = bb
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = f
			local stroke = Instance.new("UIStroke")
			stroke.Color = b.Halo
			stroke.Thickness = 6
			stroke.Transparency = 0.35
			stroke.Parent = f
			halo = f
		end
		bodyViews[b.Id] = { Body = b, Sphere = s, Clouds = clouds, Halo = bb, HaloImage = halo, Anchor = anchor }
	end
end

local function hideBodies()
	if not bodiesShown then
		return
	end
	bodiesShown = false
	for _, v in bodyViews do
		v.Sphere.Transparency = 1
		if v.Clouds then
			v.Clouds.Transparency = 1
		end
		v.Halo.Enabled = false
	end
end

local function updateBodies(camPos: Vector3, blend: number, t: number)
	if blend <= 0.02 then
		hideBodies()
		return
	end
	buildBodies()
	bodiesShown = true
	local camera = workspace.CurrentCamera
	local fov = if camera then camera.FieldOfView else 70
	local vpY = if camera then camera.ViewportSize.Y else 720
	for _, v in bodyViews do
		local b = v.Body
		local view = PlanetBodies.view(b, camPos, fov, vpY)
		local alpha = view.Body * blend
		local center = camPos + view.Dir * view.DrawDistance
		local spin = CFrame.Angles(math.rad(b.Tilt), 0, 0) * CFrame.Angles(0, math.rad(b.Spin * t), 0)
		local d = view.DrawRadius * 2
		v.Sphere.Size = Vector3.one * d
		v.Sphere.CFrame = CFrame.new(center) * spin
		v.Sphere.Transparency = 1 - alpha
		if v.Clouds then
			v.Clouds.Size = Vector3.one * d * 1.012
			v.Clouds.CFrame = CFrame.new(center) * CFrame.Angles(math.rad(b.Tilt), 0, 0) * CFrame.Angles(0, math.rad(b.Spin * 1.6 * t + 40), 0)
			v.Clouds.Transparency = 1 - alpha * (if v.Clouds.Name:sub(1, 5) == "Nubes" then 1 else 0.75)
		end
		v.Anchor.CFrame = CFrame.new(center)
		v.Halo.Size = UDim2.new(d * PlanetBodies.HaloScale, 0, d * PlanetBodies.HaloScale, 0)
		v.Halo.Enabled = alpha > 0.03
		if v.HaloImage:IsA("ImageLabel") then
			(v.HaloImage :: ImageLabel).ImageTransparency = 1 - alpha * 0.9
		end
	end
end

---------------------------------------------------------------------
-- Efectos de la entrada: calor y plasma en la nave, nubes en la pantalla, cielo
---------------------------------------------------------------------
local fxGui: ScreenGui? = nil
local cloudVeil: Frame? = nil
local cloudPuffs: { ImageLabel } = {}
local plasma: BasePart? = nil
local plasmaEmitter: ParticleEmitter? = nil

local function ensureFx()
	if fxGui then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "EntradaPlaneta"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 3
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	fxGui = gui
	local veil = Instance.new("Frame")
	veil.Name = "Velo"
	veil.Size = UDim2.fromScale(1, 1)
	veil.BorderSizePixel = 0
	veil.BackgroundColor3 = rgb(236, 226, 234)
	veil.BackgroundTransparency = 1
	veil.Parent = gui
	cloudVeil = veil
	for i = 1, 6 do
		local img = Instance.new("ImageLabel")
		img.Name = "Nube"
		img.BackgroundTransparency = 1
		img.Image = "rbxasset://textures/particles/smoke_main.dds"
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.ImageTransparency = 1
		img.ZIndex = 2
		img.Rotation = i * 57
		img.Parent = gui
		table.insert(cloudPuffs, img)
	end
	local p = Instance.new("Part")
	p.Name = "PlasmaEntrada"
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Color = rgb(255, 150, 70)
	p.Size = Vector3.new(9, 9, 9)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Parent = workspace.CurrentCamera
	plasma = p
	local e = Instance.new("ParticleEmitter")
	e.Name = "Plasma"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(255, 230, 160), rgb(255, 90, 40))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Lifetime = NumberRange.new(0.25, 0.5)
	e.Speed = NumberRange.new(40, 80)
	e.SpreadAngle = Vector2.new(35, 35)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 0) })
	e.Rate = 0
	e.EmissionDirection = Enum.NormalId.Back
	e.Parent = p
	plasmaEmitter = e
end

local function planetTint(id: string?): Color3
	local b = id and PlanetBodies.ById[id]
	return if b then b.Halo:Lerp(rgb(255, 255, 255), 0.55) else rgb(236, 226, 234)
end

local function applyFx(fx: PlanetEntry.Effects, ship: BasePart?, speed: number, t: number)
	local active = fx.Cloud > 0.01 or fx.Heat > 0.01
	if not active and not fxGui then
		return
	end
	ensureFx()
	local gui = fxGui :: ScreenGui
	gui.Enabled = fx.Cloud > 0.01
	local veil = cloudVeil :: Frame
	veil.BackgroundColor3 = planetTint(entry.Body)
	veil.BackgroundTransparency = 1 - math.clamp(fx.Cloud, 0, 1) * 0.97
	-- nubes que pasan (se agrandan y se abren hacia los lados)
	local camera = workspace.CurrentCamera
	local vp = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	for i, img in cloudPuffs do
		local k = ((t * (0.6 + speed / 300)) + i / #cloudPuffs) % 1
		local a = i * 1.7
		local dist = k * 0.7
		img.Position = UDim2.fromOffset(vp.X * (0.5 + math.cos(a) * dist), vp.Y * (0.5 + math.sin(a) * dist))
		local size = vp.X * (0.4 + k * 1.4)
		img.Size = UDim2.fromOffset(size, size)
		img.ImageColor3 = planetTint(entry.Body)
		img.ImageTransparency = 1 - math.clamp(fx.Cloud * 1.3, 0, 1) * (1 - k) * 0.85
	end
	-- calor del casco y plasma delante del morro
	local p = plasma :: BasePart
	if ship and fx.Heat > 0.01 then
		local cf = ship.CFrame
		p.CFrame = cf * CFrame.new(0, 0, -9)
		p.Size = Vector3.new(8, 6, 6) * (0.8 + fx.Heat * 0.6)
		p.Transparency = 1 - fx.Heat * 0.55
		p.Color = rgb(255, 120, 50):Lerp(rgb(255, 235, 200), fx.Heat * 0.5)
		;(plasmaEmitter :: ParticleEmitter).Rate = math.floor(fx.Plasma * (if budget().Lights then 140 else 60))
	else
		p.Transparency = 1
		;(plasmaEmitter :: ParticleEmitter).Rate = 0
	end
	if fx.Shake > 0.05 and t - lastShake > 0.22 then
		lastShake = t
		CameraShake.shake(fx.Shake * 0.5, 0.3)
	end
end

---------------------------------------------------------------------
-- Luz y cielo (en la entrada y en la superficie)
---------------------------------------------------------------------
local LONTANA_MOOD = {
	Brightness = 2.3,
	Exposure = 0.02,
	Ambient = rgb(92, 74, 92),
	Outdoor = rgb(150, 122, 150),
	SunTint = rgb(70, 40, 50),
	ShadeTint = rgb(30, 20, 46),
	Density = 0.4,
	Offset = 0.15,
	AtmColor = rgb(224, 186, 206),
	Decay = rgb(130, 96, 140),
	Glare = 0.4,
	Haze = 2.3,
	Tint = rgb(255, 236, 246),
	Saturation = -0.06,
	Contrast = 0.12,
	Cover = 0.6,
	CloudDensity = 0.45,
	CloudColor = rgb(228, 210, 222),
	Bloom = 0.7,
}
PlanetClient.Moods = { Lontana = LONTANA_MOOD }

-- Mezcla de dos capas de luz (números y colores; lo que solo tiene una, de esa)
local function mixMood(a: { [string]: any }, b: { [string]: any }, t: number): { [string]: any }
	local out = {}
	for k, v in a do
		local w = b[k]
		if w == nil then
			out[k] = v
		elseif type(v) == "number" and type(w) == "number" then
			out[k] = v + (w - v) * t
		elseif typeof(v) == "Color3" and typeof(w) == "Color3" then
			out[k] = v:Lerp(w, t)
		else
			out[k] = if t < 0.5 then v else w
		end
	end
	for k, w in b do
		if out[k] == nil then
			out[k] = w
		end
	end
	return out
end
PlanetClient._mixMood = mixMood

local function DayLight(): any
	return require(script.Parent.DayLight)
end

local lastSkyKey = ""
local function setSky(owner: boolean, planetMix: number, planet: string?, space: boolean)
	if owner ~= skyOwned then
		skyOwned = owner
		SpaceClient.setSkyOwner(owner)
		if not owner then
			pcall(function()
				DayLight().popLayer("PlanetSky", 1.2)
			end)
		end
	end
	if owner then
		local mood = mixMood(SpaceClient.SpaceMood, PlanetClient.Moods[planet or "Lontana"] or LONTANA_MOOD, planetMix)
		pcall(function()
			DayLight().pushLayer("PlanetSky", mood, 0.25, 1)
		end)
	end
	-- Las caras del cielo: la del planeta (si está subida) cuando ya es más planeta que espacio; en el
	-- espacio, la nebulosa (si está subida); si no, el de siempre
	local key = if owner and planetMix > 0.5 then "Planeta" elseif space then "Espacio" else "Normal"
	if key ~= lastSkyKey then
		lastSkyKey = key
		pcall(function()
			DayLight().forceSky(if key == "Planeta" then { "CieloLontana" } elseif key == "Espacio" then { "EspacioProfundo" } else nil)
		end)
	end
end

---------------------------------------------------------------------
-- En la superficie: agua, ceniza, la Grieta del cielo fuera
---------------------------------------------------------------------
local ashPart: BasePart? = nil

local function setSurface(on: boolean, camPos: Vector3)
	if on ~= onSurface then
		onSurface = on
		pcall(function()
			require(script.Parent.SkyRift).setSuppressed(on)
		end)
		pcall(function()
			local terrain = workspace.Terrain
			if on then
				savedWater = savedWater or terrain.WaterColor
				terrain.WaterColor = Lontana.WaterColor
			elseif savedWater then
				terrain.WaterColor = savedWater
				savedWater = nil
			end
		end)
		if on and not ashPart then
			local p = Instance.new("Part")
			p.Name = "CenizaLontana"
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.Transparency = 1
			p.Size = Vector3.new(160, 1, 160)
			p.Parent = workspace.CurrentCamera
			local b = budget()
			for i, look in { { rgb(190, 184, 190), 0.25 }, { rgb(250, 246, 250), 0.6 } } do
				local e = Instance.new("ParticleEmitter")
				e.Name = if i == 1 then "Ceniza" else "Pelusa"
				e.Texture = "rbxasset://textures/particles/smoke_main.dds"
				e.Color = ColorSequence.new(look[1])
				e.Size = NumberSequence.new(look[2])
				e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(1, 1) })
				e.Lifetime = NumberRange.new(7, 11)
				e.Speed = NumberRange.new(2, 5)
				e.EmissionDirection = Enum.NormalId.Bottom
				e.Acceleration = Vector3.new(1.2, -0.6, 0.4)
				e.RotSpeed = NumberRange.new(-60, 60)
				e.Rate = if i == 1 then math.floor(b.Smoke * 0.8) else math.floor(b.Smoke * 0.25)
				e.LightInfluence = 0.6
				e.Parent = p
			end
			ashPart = p
		end
		if ashPart then
			for _, e in (ashPart :: BasePart):GetChildren() do
				if e:IsA("ParticleEmitter") then
					e.Enabled = on
				end
			end
		end
	end
	if on and ashPart then
		ashPart.CFrame = CFrame.new(camPos + Vector3.new(0, 40, 0))
	end
end

---------------------------------------------------------------------
-- VISOR
---------------------------------------------------------------------
local function clearVisor()
	for _, m in visorMarks do
		m:Destroy()
	end
	table.clear(visorMarks)
end

local function marker(adornee: Instance, text: string, color: Color3)
	local bb = Instance.new("BillboardGui")
	bb.Name = "VisorMarca"
	bb.Adornee = adornee
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(170, 40)
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.LightInfluence = 0
	bb.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = rgb(20, 16, 28)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	bb.Parent = player:WaitForChild("PlayerGui")
	table.insert(visorMarks, bb)
end

-- Lo que marca el visor desde `from` (puro: lo prueba scripts/test-planetas): los minerales más
-- cercanos dentro del alcance (hasta `max`) y todos los puntos de interés, con su distancia
function PlanetClient.visorTargets(from: Vector3, range: number, max: number): ({ { Id: string, Ore: string, Distance: number } }, { { Id: string, Name: string, Distance: number } })
	local nodes = {}
	for _, n in Lontana.nodes() do
		local d = (n.Pos - from).Magnitude
		if d <= range then
			table.insert(nodes, { Id = n.Id, Ore = n.Ore, Distance = d })
		end
	end
	table.sort(nodes, function(a, b)
		return a.Distance < b.Distance
	end)
	while #nodes > max do
		table.remove(nodes)
	end
	local pois = {}
	for _, p in Lontana.POIs do
		local pos = Lontana.toWorld(p.X, p.Z, Lontana.Origin.Y + Lontana.poiY(p.Id))
		table.insert(pois, { Id = p.Id, Name = p.Name, Distance = (pos - from).Magnitude })
	end
	return nodes, pois
end

local function onPlanetNow(): boolean
	return type(player:GetAttribute("Planeta")) == "string"
end

local function useVisor()
	local now = os.clock()
	if not onPlanetNow() or now < visorCool then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	visorCool = now + 3
	visorUntil = now + PlanetClient.VisorSeconds
	clearVisor()
	local from = camera.CFrame.Position
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		from = root.Position
	end
	local nodes, pois = PlanetClient.visorTargets(from, PlanetClient.VisorRange, PlanetClient.VisorMaxHighlights)
	local planetFolder = workspace:FindFirstChild("Planetas")
	local lontana = planetFolder and planetFolder:FindFirstChild("Lontana")
	local mineral = lontana and lontana:FindFirstChild("Mineral")
	local poiFolder = lontana and lontana:FindFirstChild("PuntosDeInteres")
	for _, n in nodes do
		local model = mineral and mineral:FindFirstChild("Nodo_" .. n.Id)
		local ore = Mining.Ores[n.Ore]
		if model then
			local h = Instance.new("Highlight")
			h.Name = "VisorBrillo"
			h.FillColor = if ore then ore.Color else rgb(255, 255, 255)
			h.FillTransparency = 0.55
			h.OutlineColor = rgb(255, 255, 255)
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.Adornee = model
			h.Parent = model
			table.insert(visorMarks, h)
			if #visorMarks <= 16 then
				marker(model, ("⛏ %s · %d m"):format(if ore then ore.Name else n.Ore, math.floor(n.Distance * 0.28 + 0.5)), if ore then ore.Color else rgb(255, 255, 255))
			end
		end
	end
	for _, p in pois do
		local model = poiFolder and poiFolder:FindFirstChild(p.Id)
		if model then
			marker(model, ("📍 %s · %d m"):format(p.Name, math.floor(p.Distance * 0.28 + 0.5)), rgb(255, 214, 120))
		end
	end
	SoundFx.play("NaveFijando", 0.7)
	Hud.toast("Info", ("🔎 Visor: %d minerales cerca y %d puntos de interés"):format(#nodes, #pois))
end

---------------------------------------------------------------------
-- Cada fotograma
---------------------------------------------------------------------
local function step(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local t = os.clock()
	local camPos = camera.CFrame.Position
	local arena = player:GetAttribute("AirCombatWorld") == "Arena"
	local inSpaceArea = (Layers.inColumn(camPos, 600) or PlanetBodies.approachAt(camPos, 600) ~= nil) and not arena
	local blend = if inSpaceArea then Layers.skyBlend(camPos.Y) else 0
	local surface = Lontana.inRegion(camPos, 200) and not arena
	local cur = AirCombatClient.current()
	local fx: PlanetEntry.Effects = PlanetEntry.effects(entry)
	if cur and (cur.World == "Cosmos" or cur.World == "Planet") and not cur.Down then
		local root = cur.Root :: BasePart
		local action = PlanetEntry.update(entry, {
			World = cur.World,
			Pos = root.Position,
			Look = root.CFrame.LookVector,
			Open = isOpen,
			Surface = if cur.World == "Planet" then (SURFACES[cur.Planet or ""] or Lontana).Surface else nil,
		}, dt)
		if action == "Descend" or action == "Ascend" then
			fire(action)
		elseif action == "Timeout" then
			Hud.toast("Info", "☁ La atmósfera está revuelta: inténtalo otra vez")
			if entry.Body then
				deniedUntil[entry.Body] = t + 6
			end
		end
		fx = PlanetEntry.effects(entry, cur.Speed)
		applyFx(fx, root, cur.Speed or 150, t)
		-- Estado de los planetas (a cuáles se puede bajar) y avisos al acercarse
		if cur.World == "Cosmos" then
			if t - lastStatusAsk > 20 then
				lastStatusAsk = t
				fire("Status")
			end
			local pos = root.Position
			for _, b in PlanetBodies.List do
				local d = (pos - b.Center).Magnitude
				if d < PlanetBodies.approachRadius(b) then
					if isOpen(b.Id) and SURFACES[b.Id] and t - lastNear > 30 then
						lastNear = t
						fire("Near", b.Id)
					elseif not isOpen(b.Id) and d < PlanetBodies.entryRadius(b) + 700 and t - (soonToastAt[b.Id] or -math.huge) > 15 then
						soonToastAt[b.Id] = t
						local status = open[b.Id] or "Soon"
						Hud.toast("Info", Planets.message(b.Id, if status == "Ready" then "Soon" else status))
					end
				end
			end
		end
	else
		if entry.Phase ~= "Space" and entry.Phase ~= "Surface" then
			entry = PlanetEntry.new()
		end
		applyFx({ Heat = 0, Shake = 0, Cloud = 0, Sky = 0, Plasma = 0 }, nil, 0, t)
	end
	-- Luz: en la superficie, la del planeta; entrando o saliendo, mezclada con la del espacio
	local planetId = entry.Body or (if surface then "Lontana" else nil)
	local phase = entry.Phase
	local entering = phase == "Entry" or phase == "Descending" or phase == "Departure" or phase == "Arrival" or phase == "Climb" or phase == "Ascending"
	if surface then
		setSky(true, if phase == "Climb" or phase == "Ascending" then math.max(fx.Sky, 0.3) else 1, "Lontana", false)
	elseif entering and inSpaceArea then
		setSky(true, fx.Sky, planetId, true)
	else
		setSky(false, 0, nil, blend > 0.6)
	end
	setSurface(surface, camPos)
	updateBodies(camPos, if surface then 0 else blend, t)
	if #visorMarks > 0 and (t > visorUntil or not onPlanetNow()) then
		clearVisor()
	end
end
PlanetClient._step = step

local function onEvent(kind: string, p: any)
	if kind == "Status" and type(p) == "table" then
		for id, st in p do
			if type(id) == "string" and type(st) == "string" then
				open[id] = st
			end
		end
	elseif kind == "Denied" and type(p) == "table" then
		if type(p.Id) == "string" then
			deniedUntil[p.Id] = os.clock() + 20
			open[p.Id] = "Soon"
		end
		if type(p.Text) == "string" then
			Hud.toast("Info", p.Text)
		end
	elseif kind == "Mine" and type(p) == "table" then
		SoundFx.play("NaveImpacto", 0.6)
	elseif kind == "Found" and type(p) == "table" then
		SoundFx.play("MisionCompleta", if p.First then 0.6 else 0.3)
	end
end
PlanetClient._onEvent = onEvent

function PlanetClient.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Planet", 10) :: RemoteEvent?
	if remote then
		remote.OnClientEvent:Connect(function(kind, payload)
			local ok, err = pcall(onEvent, kind, payload)
			if not ok then
				warn("[PlanetClient] " .. tostring(err))
			end
		end)
	end
	AirCombatClient.setEnv("Cosmos", { mode = Zone.modeAt, collide = Zone.collide, bounds = cosmosBounds })
	AirCombatClient.setEnv("Planet", { mode = Lontana.modeAt, collide = Lontana.collide, bounds = Lontana.bounds })
	AirCombatClient.setGround(groundFor)
	AirCombatClient.onRelocate(function(world: string, planet: string?)
		PlanetEntry.relocated(entry, world, planet or entry.Body)
		if world == "Planet" then
			SoundFx.play("NaveEstallido", 0.25)
		end
	end)
	TouchLayout.register({
		Id = "PlanetaVisor",
		Icon = "objetivo",
		Label = "VISOR",
		FlySlot = "VisorNave",
		Priority = 2.2,
		Key = "I",
		Pad = "L3",
		Visible = onPlanetNow,
		Callback = useVisor,
		Active = function()
			return os.clock() < visorUntil
		end,
	})
	ContextActionService:BindAction(VISOR_KEYS, function(_, state)
		if state == Enum.UserInputState.Begin and onPlanetNow() then
			useVisor()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.I, Enum.KeyCode.ButtonL3)
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 4, function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[PlanetClient] " .. tostring(err))
		end
	end)
	task.delay(3, function()
		fire("Status")
	end)
	if TOUCH then
		-- (en el móvil, el VISOR también a pie: columna de contexto)
		TouchLayout.refresh()
	end
end

-- (pruebas)
PlanetClient._entry = function()
	return entry
end
PlanetClient._open = open

return PlanetClient
