-- SkyRift (cliente): la Grieta del cielo de la Saga de la Grieta (las cuentas, en shared/SkyRift).
--
--   * Las 7 ETAPAS que encargó el dueño (scripts/rift/etapas.png): 1 nada, 2 un destello violeta con
--     una raya fina, 3 la fractura con rayos, 4 la gran fractura, 5 el portal (la rasgadura con el
--     espacio dentro: scripts/rift/referencia.png), 6 la grieta colosal y 7 el evento final (casi todo
--     el cielo es espacio y la ciudad se ve violeta). La fase la publica el servidor en el atributo
--     SkyRift del jugador (LifeStoryService); cada fase dice su etapa. Al cambiar de etapa, la de
--     antes se apaga y la nueva nace pequeña y crece.
--   * Dónde: se ve SIN buscarla. Cuando empieza una fase (o entra el jugador) se elige el lado del cielo
--     hacia el que mira la cámara (su giro) y, a ~27° sobre el horizonte (shared/SkyRift.Placement:
--     encima de los edificios y dentro de la pantalla del móvil), se queda fija ahí.
--   * Aviso «¡Mira al cielo!» con una flecha hacia la grieta: la primera vez que hay grieta en el cielo
--     de Valmar (Rasguño o más) y la primera noche en «Crece» o más (shared/SkyRift.hintFor). Al
--     avisar, la grieta se vuelve a poner delante de la cámara.
--   * Composición (de atrás adelante), en un plano lejano (a ~650 studs) que siempre mira a la cámara
--     (sin deformarse) y sigue a la cámara en la dirección elegida (como la luna):
--       SurfaceGui (LightInfluence 0 y Brightness > 1: el Bloom la hace resplandecer):
--         halo azul/morado · textura de la etapa · galaxia que gira despacio · rayos del borde ·
--         rayos que parpadean (se regeneran cada 0,1-0,6 s) · destello violeta (etapas 2-3)
--       Delante: resplandor aditivo (Beams), rocas 3D que flotan y giran (borde azul con un Highlight),
--       chispas y polvo de energía en el borde, y el ambiente teñido (DayLight.pushLayer).
--   * Sin texturas subidas (shared/RiftTextureIds vacío) se dibuja por código con la misma silueta
--     (shared/SkyRiftArt): relleno oscuro por columnas, borde eléctrico, planeta, galaxia de puntos,
--     estrellas y rayos de tramos.
--   * Solo de esta pantalla (no va por la red), sin colisión, sin consultas ni sombra. En gráficos Bajo,
--     sin rocas 3D ni resplandor y la mitad de rayos y partículas (la textura principal, igual).
--   * Ciclo de demostración (Config.SkyRift.DemoCycle, temporal): la fase sale de la hora del servidor
--     (shared/SkyRift.Demo) en vez de la historia; el modo pruebas la adelanta para todos
--     (atributo SkyRiftDemoOffset de workspace).
--   * Cambio de etapa EN DIRECTO (Config.SkyRift.LiveTransitions, shared/SkyRift.Live): como un evento
--     en vivo. Nadie pierde la cámara, la interfaz ni los controles: quien mire al cielo ve cómo se
--     carga (parpadeo, rayos, rumor), cómo la vieja se rasga más y se apaga (o se cose y se encoge)
--     mientras nace la nueva, rocas que se desprenden, un destello con onda expansiva y un trueno
--     grave, y la luz del ambiente que cambia poco a poco. Como pistas: un aviso pequeño arriba (uno
--     por transición) y, a pie, un temblor muy leve. Quien entra tarde ve ya la etapa de ahora.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Rift = require(Shared.SkyRift)
local Art = require(Shared.SkyRiftArt)
local SkyMoods = require(Shared.SkyMoods)
local Images = require(Shared.Images)
local Perf = require(script.Parent.Parent.UI.Perf)
local Config = require(Shared.Config)

local SkyRift = {}

local player = Players.LocalPlayer

local CANVAS_W = 1024 -- ancho del lienzo (SurfaceGui) en píxeles
local LAYER = "GrietaCielo" -- capa de luz de DayLight
local LAYER_OLD = "GrietaCieloAntes" -- (en una transición, la luz de la etapa de antes, que se va)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- Colores del dibujo por código (los de la referencia)
local C = {
	Space = Color3.fromRGB(14, 10, 46),
	SpaceTop = Color3.fromRGB(26, 22, 86),
	SpaceLow = Color3.fromRGB(60, 22, 112),
	Rim = Color3.fromRGB(150, 225, 255),
	RimOuter = Color3.fromRGB(110, 70, 255),
	Violet = Color3.fromRGB(196, 120, 255),
	Bolt = Color3.fromRGB(205, 240, 255),
	BoltPurple = Color3.fromRGB(215, 160, 255),
	Galaxy = Color3.fromRGB(255, 170, 240),
	GalaxyArm = Color3.fromRGB(170, 120, 255),
	Planet = Color3.fromRGB(40, 60, 140),
	PlanetLit = Color3.fromRGB(120, 160, 240),
	Rock = Color3.fromRGB(36, 34, 46),
	RockEdge = Color3.fromRGB(120, 200, 255),
}

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
type Fade = { Obj: Instance, Prop: string, Base: number }
type BoltSlot = {
	State: string, -- "on" | "off"
	T: number,
	Data: Rift.Bolt?,
	Image: ImageLabel?,
	Segs: { Frame },
}
type RockInst = { Spec: Rift.Rock, Main: BasePart, Wedge: BasePart, WedgeOffset: CFrame, Size: number }
type Emitter = { Att: Attachment, E: ParticleEmitter, Rate: number, Spot: { number } }

local ids: { [string]: any } = {}
do
	local module = Shared:FindFirstChild("RiftTextureIds")
	if module then
		local ok, value = pcall(require, module)
		if ok and type(value) == "table" then
			ids = value
		end
	end
end

local tierName = "Medium"
local phaseName = "Ninguna" -- la fase que se ve (la de la historia o la del ciclo de demostración)
local storyPhase = "Ninguna" -- la de tu historia (atributo SkyRift)
local storyReady = false -- ¿ha llegado ya? (hasta entonces no se lanza ninguna transición)
local tracker = Rift.newTracker()
local preview: string? = nil -- modo pruebas: ver una fase sin jugarla
local mode = "Sky"

local shownStage = 1 -- la etapa que está dibujada
local open, vis = 0, 0 -- cuánto ha crecido dentro de su etapa y cuánto se ve
local appliedOpen, appliedVis = -1, -1

local folder: Folder? = nil
local anchor: Part? = nil
local gui: SurfaceGui? = nil
local canvasH = 512
local textures: Rift.Textures? = nil
local width, height = 600, 300
local roll = 0
local drawHeight = 1 -- (sin textura) cuánto de alto se dibuja la silueta dentro del lienzo

-- Lo que se mueve
local images: { [string]: ImageLabel } = {}
local fades: { Fade } = {}
local rimSegs: { { Frame } } = {} -- { núcleo, exterior } por tramo del borde
local columns: { Frame } = {}
local dots: { { Obj: Frame, R: number, A: number, Arm: number } } = {}
local stars: { { Obj: Frame, U: number, V: number, Tw: number } } = {}
local nebula: { { Obj: Frame, U: number, V: number, S: number } } = {}
local planet: Frame? = nil
local galaxyCore: Frame? = nil
local star: { Frame } = {}
local backdrop: { Frame } = {}
local bolts: { BoltSlot } = {}
local rocks: { RockInst } = {}
local emitters: { Emitter } = {}
local halos: { Beam } = {}
local spawn: { { number } } = Art.Rim
local hum: Sound? = nil
local crack: Sound? = nil
local lastCrack = 0
local lastLook, lastAmbient = 0, 0
local clock = 0 -- segundos de juego (de los dt del render: el pulso, los rayos y las rocas)
local ambientOn: string? = nil

local random = Random.new()
local function rnd(): number
	return random:NextNumber()
end

---------------------------------------------------------------------
-- Fases y colocación
---------------------------------------------------------------------
local function currentPhase(): Rift.Phase
	return Rift.phase(preview or phaseName)
end

local function stageSpec(): Rift.Stage
	return Rift.stage(shownStage)
end

local function frameWidth(): number
	if mode == "Dream" then
		return Rift.Placement.Dream.DreamWidth
	end
	return stageSpec().Width
end

-- La dirección del cielo: el giro (yaw) se elige mirando hacia donde mira la cámara al empezar la fase
-- o al entrar, y luego se queda fijo (skyYaw); nil = elegirlo en el próximo fotograma
local skyYaw: number? = nil
local function aim()
	local camera = workspace.CurrentCamera
	if camera then
		local look = camera.CFrame.LookVector
		skyYaw = Rift.yawOf(look.X, look.Z)
	end
end

local function skyDirection(): Vector3
	if skyYaw == nil then
		aim()
	end
	local x, y, z = Rift.skyDirection(skyYaw)
	return Vector3.new(x, y, z)
end

-- El centro del plano: en el cielo, delante de la cámara; si es muy alto (etapas 6-7), se sube para
-- que su borde de abajo no tape la ciudad
local function centerPoint(camPos: Vector3, h: number?): Vector3
	if mode == "Dream" then
		local c = Rift.Placement.Dream.Center
		return Vector3.new(c[1], c[2], c[3])
	end
	local dist = Rift.Placement.Sky.Distance
	local dir = skyDirection()
	local rise = dist * dir.Y - dist * math.tan(math.rad(5)) -- altura del centro sobre el horizonte (+5°)
	local shift = math.max(0, (h or height) * 0.45 - rise)
	return camPos + dir * dist + Vector3.yAxis * shift
end

local function placeAnchor()
	local part = anchor
	local camera = workspace.CurrentCamera
	if not part or not camera then
		return
	end
	local camPos = camera.CFrame.Position
	local at = centerPoint(camPos)
	-- Siempre de frente a la cámara (la cara Front, la del SurfaceGui, mira hacia ella)
	part.CFrame = CFrame.lookAt(at, camPos) * CFrame.Angles(0, 0, roll)
end

---------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------
local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local obj = Instance.new(className)
	for k, v in props do
		(obj :: any)[k] = v
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

-- Algo que se apaga con la grieta: su transparencia base (la de vis = 1)
local function fade(obj: Instance, prop: string, base: number)
	table.insert(fades, { Obj = obj, Prop = prop, Base = base })
	;(obj :: any)[prop] = 1
end

local function frame(name: string, color: Color3, z: number, transparency: number, round: boolean?): Frame
	local f = make("Frame", {
		Name = name,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = z,
	}, gui)
	if round then
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	end
	fade(f, "BackgroundTransparency", transparency)
	return f
end

local function image(name: string, id: string, z: number, transparency: number): ImageLabel
	local img = make("ImageLabel", {
		Name = name,
		Image = id,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
		ScaleType = Enum.ScaleType.Stretch,
	}, gui)
	fade(img, "ImageTransparency", transparency)
	images[name] = img
	return img
end

-- Un tramo recto de A a B (en píxeles del lienzo) con un Frame girado
local function segment(f: Frame, ax: number, ay: number, bx: number, by: number, thick: number)
	local dx, dy = bx - ax, by - ay
	local len = math.sqrt(dx * dx + dy * dy)
	f.Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2)
	f.Size = UDim2.fromOffset(len + thick * 0.6, thick)
	f.Rotation = math.deg(math.atan2(dy, dx))
end

-- Suelta lo dibujado sin destruirlo (la transición se lo queda como «la de antes» y lo apaga)
local function detach()
	folder, anchor, gui, textures = nil, nil, nil, nil
	images, fades, rimSegs, columns, dots, stars, nebula = {}, {}, {}, {}, {}, {}, {}
	star, backdrop, bolts, rocks, emitters, halos = {}, {}, {}, {}, {}, {}
	planet, galaxyCore = nil, nil
	hum, crack = nil, nil
	appliedOpen, appliedVis = -1, -1
end

local function destroy()
	if folder then
		folder:Destroy()
	end
	detach()
end

-- Del marco (u, v: 0..1) al lienzo con la apertura de ahora
local function toPx(u: number, v: number): (number, number)
	local w, h = Rift.size(open)
	return Rift.toCanvas(u, v, CANVAS_W, canvasH, w, h * drawHeight)
end

local function buildTextured(tex: Rift.Textures, st: Rift.Stage)
	if tex.Glow then
		image("Halo", tex.Glow, 1, 0)
	end
	image("Interior", tex.Main, 2, 0)
	local art = Art.Stages[shownStage]
	if tex.Galaxy and art and art.Galaxy then
		image("Galaxia", tex.Galaxy, 3, 0)
	end
	if tex.Rays then
		image("Rayos", tex.Rays, 4, 0)
	end
	spawn = (art and art.Spawn) or Art.Rim
end

local function buildDrawn(st: Rift.Stage)
	local d = st.Draw
	local look = Rift.tierLook(tierName)
	spawn = Art.Rim
	-- Etapa 7: casi todo el cielo es espacio (tres manchas grandes violeta detrás)
	if d.Backdrop then
		for i = 1, 3 do
			local f = frame("Fondo" .. i, if i == 2 then C.SpaceLow else C.Space, 1, 0.25 + 0.15 * i, true)
			make("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.3, 0),
					NumberSequenceKeypoint.new(0.7, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Rotation = 90 * (i - 1),
			}, f)
			table.insert(backdrop, f)
		end
	end
	if d.Fill then
		for i in Art.Columns do
			local f = frame("Columna" .. i, C.Space, 2, 0)
			make("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, C.SpaceTop),
					ColorSequenceKeypoint.new(0.55, C.Space),
					ColorSequenceKeypoint.new(1, C.SpaceLow),
				}),
			}, f)
			columns[i] = f
		end
		-- Nebulosa: manchas violeta y azules transparentes
		local r = Rift.rng(77)
		for i = 1, Rift.NebulaBlobs do
			local c = Art.Columns[math.clamp(math.floor(r() * #Art.Columns) + 1, 1, #Art.Columns)]
			local f = frame("Nebulosa" .. i, if i % 2 == 0 then C.SpaceLow else Color3.fromRGB(40, 60, 170), 3, 0.62, true)
			table.insert(nebula, { Obj = f, U = c[1], V = c[3] + (c[4] - c[3]) * (0.3 + 0.4 * r()), S = 0.04 + 0.05 * r() })
		end
	end
	if d.Cosmos then
		-- Planeta (a la izquierda, asomando por arriba, como en la referencia)
		local p = frame("Planeta", C.Planet, 4, 0, true)
		make("UIGradient", { Rotation = -30, Color = ColorSequence.new(C.Planet, C.PlanetLit) }, p)
		planet = p
		-- Galaxia: núcleo rosa brillante y dos brazos de puntos que giran
		local core = frame("GalaxiaNucleo", C.Galaxy, 5, 0.05, true)
		galaxyCore = core
		for i = 1, Rift.GalaxyDots do
			local arm = i % 2
			local k = math.floor((i - 1) / 2) / (Rift.GalaxyDots / 2)
			local f = frame("Galaxia" .. i, if k < 0.35 then C.Galaxy else C.GalaxyArm, 4, 0.1 + 0.6 * k, true)
			table.insert(dots, { Obj = f, R = 0.08 + 0.92 * k, A = k * 4.2 + arm * math.pi, Arm = arm })
		end
		-- Estrellas (dentro de la silueta)
		local r = Rift.rng(31)
		local want = Rift.counts(shownStage, tierName).Stars
		local tries = 0
		while #stars < want and tries < want * 20 do
			tries += 1
			local u, v = 0.15 + 0.7 * r(), 0.3 + 0.4 * r()
			if Rift.inside(Art :: any, u, v) then
				local f = frame("Estrella" .. (#stars + 1), Color3.new(1, 1, 1), 4, 0.15, true)
				table.insert(stars, { Obj = f, U = u, V = v, Tw = r() * 10 })
			end
		end
	end
	-- Borde eléctrico: un tramo por cada lado del contorno (núcleo claro y, por fuera, morado)
	local rimColor = if shownStage == 2 then C.Violet else C.Rim
	for i in Art.Rim do
		local core = frame("Borde" .. i, rimColor, 6, 0)
		local outer = if look.OuterRim then frame("BordeFuera" .. i, C.RimOuter, 5, 0.55) else nil
		rimSegs[i] = { core, outer :: any }
	end
end

local function buildStar()
	-- El destello violeta de la primera anomalía (punto brillante con rayos en cruz)
	local glow = frame("DestelloHalo", C.Violet, 7, 0.55, true)
	local core = frame("Destello", Color3.fromRGB(250, 235, 255), 9, 0, true)
	local h1 = frame("DestelloRayoH", Color3.fromRGB(230, 200, 255), 8, 0.15)
	local h2 = frame("DestelloRayoV", Color3.fromRGB(230, 200, 255), 8, 0.15)
	star = { glow, core, h1, h2 }
end

local function newBoltSlot(): BoltSlot
	local slot: BoltSlot = { State = "off", T = rnd() * 0.5, Data = nil, Image = nil, Segs = {} }
	local tex = textures
	if tex and #tex.Bolts > 0 then
		local img = make("ImageLabel", {
			Name = "Rayo",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			ImageTransparency = 1,
			ZIndex = 10,
			Image = tex.Bolts[1],
		}, gui)
		slot.Image = img
	else
		local look = Rift.tierLook(tierName)
		for k = 1, look.BoltSegments + 3 do
			local f = make("Frame", {
				Name = "RayoTramo",
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = C.Bolt,
				BackgroundTransparency = 1,
				ZIndex = 10,
			}, gui)
			slot.Segs[k] = f
		end
	end
	return slot
end

local function buildRocks(n: number, st: Rift.Stage)
	if n <= 0 or not folder then
		return
	end
	local model = make("Model", { Name = "Rocas" }, folder)
	make("Highlight", {
		Name = "BordeAzul",
		Adornee = model,
		FillColor = Color3.fromRGB(90, 110, 255),
		FillTransparency = 0.82,
		OutlineColor = C.RockEdge,
		OutlineTransparency = 0.12,
		DepthMode = Enum.HighlightDepthMode.Occluded,
	}, model)
	for i, spec in Rift.rocks(n, 9157 + shownStage) do
		local r = Rift.rng(spec.Seed)
		local size = spec.Size * width * st.RockScale
		local function part(className: string, name: string, s: Vector3): BasePart
			return make(className, {
				Name = name,
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				CastShadow = false,
				Locked = true,
				Material = if i % 3 == 0 then Enum.Material.Basalt else Enum.Material.Rock,
				Color = C.Rock,
				Size = s,
			}, model)
		end
		local main = part("Part", "Roca" .. i, Vector3.new(size * (0.8 + 0.4 * r()), size * (0.6 + 0.3 * r()), size * (0.7 + 0.4 * r())))
		local wedge = part("WedgePart", "Cuna" .. i, Vector3.new(size * (0.5 + 0.3 * r()), size * (0.5 + 0.3 * r()), size * (0.6 + 0.3 * r())))
		local offset = CFrame.new(size * (r() - 0.5) * 0.5, size * 0.35, size * (r() - 0.5) * 0.4) * CFrame.Angles(r() * 6.28, r() * 6.28, r() * 6.28)
		table.insert(rocks, { Spec = spec, Main = main, Wedge = wedge, WedgeOffset = offset, Size = size })
	end
end

local function buildEmitters(n: number)
	local part = anchor
	if n <= 0 or not part then
		return
	end
	for i = 1, n do
		local spot = spawn[math.clamp(math.floor((i - 0.5) / n * #spawn) + 1, 1, #spawn)]
		local att = make("Attachment", { Name = "Energia" .. i }, part)
		local dust = i % 3 == 0
		local s = width * (if dust then 0.012 else 0.006)
		local e = make("ParticleEmitter", {
			Name = if dust then "Polvo" else "Chispas",
			Texture = SPARK,
			LockedToPart = true, -- (la grieta sigue a la cámara: las partículas van con ella)
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = if dust then 2 else 4,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-40, 40),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, s), NumberSequenceKeypoint.new(1, s * 0.2) }),
			Color = if dust
				then ColorSequence.new(Color3.fromRGB(150, 140, 255), Color3.fromRGB(200, 120, 255))
				else ColorSequence.new(Color3.fromRGB(200, 240, 255), Color3.fromRGB(110, 150, 255)),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = if dust then NumberRange.new(3, 5) else NumberRange.new(0.6, 1.4),
			Speed = if dust then NumberRange.new(width * 0.004, width * 0.01) else NumberRange.new(width * 0.02, width * 0.05),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, -width * (if dust then 0.002 else 0.02), 0),
			Drag = if dust then 0.3 else 1,
			Rate = 0,
		}, att)
		table.insert(emitters, { Att = att, E = e, Rate = if dust then 4 else 9, Spot = spot })
	end
end

local function buildHalos()
	local part = anchor
	if not part then
		return
	end
	for i, color in { Color3.fromRGB(70, 140, 255), Color3.fromRGB(150, 80, 255) } do
		local a0 = make("Attachment", { Name = "HaloA" .. i }, part)
		local a1 = make("Attachment", { Name = "HaloB" .. i }, part)
		local beam = make("Beam", {
			Name = "Resplandor",
			Attachment0 = a0,
			Attachment1 = a1,
			FaceCamera = true,
			Segments = 1,
			Texture = SMOKE,
			TextureMode = Enum.TextureMode.Stretch,
			TextureLength = 1,
			TextureSpeed = 0.03 * i,
			Color = ColorSequence.new(color),
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = 1.6,
			Transparency = NumberSequence.new(1),
			ZOffset = -1,
		}, a0)
		table.insert(halos, beam)
	end
end

local function buildSounds()
	local f = folder
	if not f then
		return
	end
	local ok, SoundIds = pcall(require, Shared:FindFirstChild("SoundIds") :: ModuleScript)
	if not ok or type(SoundIds) ~= "table" then
		return
	end
	-- Zumbido grave de energía (el viento muy lento) y el crepitar de un rayo de vez en cuando
	if type(SoundIds.viento) == "string" then
		hum = make("Sound", { Name = "Zumbido", SoundId = SoundIds.viento, Looped = true, Volume = 0, PlaybackSpeed = 0.32 }, f)
	end
	if type(SoundIds.trueno) == "string" then
		crack = make("Sound", { Name = "Crepitar", SoundId = SoundIds.trueno, Volume = 0.18, PlaybackSpeed = 1.6 }, f)
	end
end

local function build()
	destroy()
	if shownStage <= 1 then
		return
	end
	local st = stageSpec()
	local counts = Rift.counts(shownStage, tierName)
	local look = Rift.tierLook(tierName)
	textures = Rift.textures(ids, shownStage, Art :: any, Images.of)
	local aspect = if textures then textures.Aspect else Rift.Aspect
	drawHeight = if textures then 1 else st.Draw.Height / math.max(1, st.Draw.Height)
	if not textures then
		aspect = st.FrameAspect or Rift.Aspect / math.max(1, st.Draw.Height)
	end
	roll = if textures then 0 else st.Draw.Roll
	width = frameWidth()
	height = width / aspect
	canvasH = math.floor(CANVAS_W / aspect + 0.5)

	local f = Instance.new("Folder")
	f.Name = "CieloGrieta"
	local part = make("Part", {
		Name = "Grieta",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Locked = true,
		Transparency = 1,
		Size = Vector3.new(width, height, 0.2),
	}, f)
	folder, anchor = f, part
	gui = make("SurfaceGui", {
		Name = "Lienzo",
		Face = Enum.NormalId.Front,
		Adornee = part,
		LightInfluence = 0, -- no la apaga la noche ni la sombra
		Brightness = 2,
		AlwaysOnTop = false,
		MaxDistance = 100000,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = Vector2.new(CANVAS_W, canvasH),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ClipsDescendants = false,
		ResetOnSpawn = false,
	}, part)

	local tex = textures
	if tex then
		buildTextured(tex, st)
	else
		buildDrawn(st)
	end
	if st.Star then
		buildStar()
	end
	for _ = 1, counts.Bolts do
		table.insert(bolts, newBoltSlot())
	end
	if look.Halo and shownStage >= 3 then
		buildHalos()
	end
	buildRocks(counts.Rocks, st)
	buildEmitters(counts.Emitters)
	buildSounds()
	placeAnchor()
end

---------------------------------------------------------------------
-- Geometría (cuando cambia lo abierta que está)
---------------------------------------------------------------------
local function applyGeometry()
	local w, h = Rift.size(open)
	local hh = h * drawHeight
	-- Capas con textura: estiradas a la apertura (Rasguño: pequeña y fina)
	for name, img in images do
		if name == "Galaxia" then
			local art = Art.Stages[shownStage]
			local g = art and art.Galaxy
			if g then
				local x, y = toPx(g[1], g[2])
				img.Position = UDim2.fromOffset(x, y)
				img.Size = UDim2.fromOffset(g[3] * 2 * CANVAS_W * w, g[3] * 2 * CANVAS_W * w * math.min(1, h / w))
			end
		else
			img.Size = UDim2.fromScale(w, h)
		end
	end
	-- Dibujo por código
	for i, f in columns do
		local c = Art.Columns[i]
		local x, top = toPx(c[1], c[3])
		local _, bottom = toPx(c[1], c[4])
		f.Position = UDim2.fromOffset(x, (top + bottom) / 2)
		f.Size = UDim2.fromOffset(c[2] * CANVAS_W * w + 1.5, math.max(1, bottom - top))
	end
	local rim = Art.Rim
	local thick = 3 + 5 * math.min(1, open * hh * 2)
	for i, pair in rimSegs do
		local a, b = rim[i], rim[i % #rim + 1]
		local ax, ay = toPx(a[1], a[2])
		local bx, by = toPx(b[1], b[2])
		segment(pair[1], ax, ay, bx, by, thick)
		if pair[2] then
			segment(pair[2], ax, ay, bx, by, thick * 3.2)
		end
	end
	for _, n in nebula do
		local x, y = toPx(n.U, n.V)
		n.Obj.Position = UDim2.fromOffset(x, y)
		n.Obj.Size = UDim2.fromOffset(n.S * CANVAS_W * w * 2, n.S * CANVAS_W * w * hh)
	end
	if planet then
		local p = Art.Planet
		local x, y = toPx(p[1], p[2])
		local r = p[3] * CANVAS_W * w
		planet.Position = UDim2.fromOffset(x, y)
		planet.Size = UDim2.fromOffset(r * 2, r * 2 * math.min(1, hh * 1.4))
	end
	for _, s in stars do
		local x, y = toPx(s.U, s.V)
		s.Obj.Position = UDim2.fromOffset(x, y)
		s.Obj.Size = UDim2.fromOffset(3, 3)
	end
	for i, f in backdrop do
		f.Position = UDim2.fromScale(0.5 + 0.12 * (i - 2), 0.45)
		f.Size = UDim2.fromScale(1.05 * w, 1.1 * hh)
	end
	if #star > 0 then
		-- (con textura, encima del destello de la imagen; sin ella, en el centro)
		local art = Art.Stages[shownStage]
		local su = if textures and art and art.Star then art.Star else { 0.5, 0.5 }
		local x, y = toPx(su[1], su[2])
		local s = CANVAS_W * (0.05 + 0.05 * open)
		star[1].Position, star[1].Size = UDim2.fromOffset(x, y), UDim2.fromOffset(s * 2.4, s * 2.4)
		star[2].Position, star[2].Size = UDim2.fromOffset(x, y), UDim2.fromOffset(s * 0.35, s * 0.35)
		star[3].Position, star[3].Size = UDim2.fromOffset(x, y), UDim2.fromOffset(s * 4, 3)
		star[4].Position, star[4].Size = UDim2.fromOffset(x, y), UDim2.fromOffset(3, s * 3)
	end
	-- Partículas en el borde
	for _, e in emitters do
		local px, py = toPx(e.Spot[1], e.Spot[2])
		-- (visto de frente, la derecha del lienzo es la -X de la pieza)
		e.Att.Position = Vector3.new(-(px / CANVAS_W - 0.5) * width, -(py / canvasH - 0.5) * height, -3)
	end
	-- Resplandor aditivo a lo largo de la grieta
	for i, beam in halos do
		local a0, a1 = beam.Attachment0, beam.Attachment1
		if a0 and a1 then
			local y = (if i == 1 then 0.02 else -0.04) * height * hh
			a0.Position = Vector3.new(-0.42 * width * w, y, -1)
			a1.Position = Vector3.new(0.42 * width * w, y, -1)
			beam.Width0 = height * hh * (if i == 1 then 0.75 else 0.95)
			beam.Width1 = beam.Width0
		end
	end
	appliedOpen = open
end

---------------------------------------------------------------------
-- Cada fotograma: rayos, rocas, galaxia, brillo
---------------------------------------------------------------------
local function placeBolt(slot: BoltSlot)
	local b = slot.Data
	if not b then
		return
	end
	local w = Rift.size(open)
	local sx, sy = toPx(b.U, b.V)
	local len = b.Length * CANVAS_W * w
	local ca, sa = math.cos(b.Angle), math.sin(b.Angle)
	local img = slot.Image
	local tex = textures
	if img and tex then
		img.Image = tex.Bolts[math.clamp(b.Texture, 1, #tex.Bolts)]
		img.Size = UDim2.fromOffset(len, len * 0.5)
		img.Position = UDim2.fromOffset(sx + ca * len / 2, sy + sa * len / 2)
		img.Rotation = math.deg(b.Angle)
		img.ImageColor3 = if b.Purple then Color3.fromRGB(230, 190, 255) else Color3.new(1, 1, 1)
		return
	end
	local main, branch = Rift.boltPath(math.floor(rnd() * 1e6), #slot.Segs - 3)
	local function at(p: { number }): (number, number)
		return sx + (p[1] * ca - p[2] * sa) * len, sy + (p[1] * sa + p[2] * ca) * len
	end
	local color = if b.Purple then C.BoltPurple else C.Bolt
	local k = 0
	for i = 1, #main - 1 do
		k += 1
		local f = slot.Segs[k]
		if f then
			local ax, ay = at(main[i])
			local bx, by = at(main[i + 1])
			segment(f, ax, ay, bx, by, 3 - i * 0.2)
			f.BackgroundColor3 = color
		end
	end
	for i = 1, #branch - 1 do
		k += 1
		local f = slot.Segs[k]
		if f then
			local ax, ay = at(branch[i])
			local bx, by = at(branch[i + 1])
			segment(f, ax, ay, bx, by, 1.6)
			f.BackgroundColor3 = color
		end
	end
end

local function showBolt(slot: BoltSlot, transparency: number)
	if slot.Image then
		slot.Image.ImageTransparency = transparency
	end
	for _, f in slot.Segs do
		f.BackgroundTransparency = transparency
	end
end

local flareStart, flareSeconds, flareStrength = 0, 0, 0
local liveFlare = 0 -- (transición en directo) la carga: más brillo y rayos más seguidos
local function flareNow(now: number): number
	local f = 0
	if flareSeconds > 0 then
		local u = (now - flareStart) / flareSeconds
		if u >= 0 and u <= 1 then
			f = flareStrength * math.sin(u * math.pi)
		end
	end
	return math.max(f, liveFlare)
end

-- La transición en directo que está pasando (ver «Cambio de etapa en directo» más abajo)
type GhostRock = { Part: BasePart, Off: CFrame, Vel: Vector3, Spin: Vector3 }
type Ghost = {
	Folder: Folder,
	Part: BasePart,
	Size: Vector3,
	Roll: number,
	Height: number,
	Fades: { Fade },
	Rocks: { GhostRock },
	Gui: SurfaceGui?,
	Brightness: number,
	Seam: { Frame },
}
type Debris = { Part: BasePart, Start: Vector3, Vel: Vector3, Spin: Vector3, Born: number }
type Live = {
	T: Rift.Transition,
	Start: number,
	Morphed: boolean,
	MorphStart: number,
	Flashed: boolean,
	Hinted: boolean,
	Ghost: Ghost?,
	OldMood: string?,
	OldWeight: number,
	Extra: number,
	Event: Folder?,
	Ring: BasePart?,
	RingStroke: UIStroke?,
	RingGlow: Frame?,
	Rumble: Sound?,
	RumbleBase: number,
	Boom: Sound?,
	Far: Sound?,
	FarPlayed: boolean,
	Debris: { Debris },
	Light: Instance?,
	Width: number,
}
local live: Live? = nil
local liveCount = 0 -- (pruebas) transiciones lanzadas

local function updateBolts(dt: number, now: number)
	local flare = flareNow(now)
	for _, slot in bolts do
		slot.T -= dt * (1 + flare)
		if slot.State == "on" then
			if slot.T <= 0 then
				slot.State = "off"
				slot.T = if slot.Data then slot.Data.Wait else 0.3
				showBolt(slot, 1)
			else
				-- Parpadeo: cada fotograma un poco distinto
				showBolt(slot, 1 - vis * (0.45 + 0.55 * rnd()))
			end
		elseif slot.T <= 0 and vis > 0.05 and #spawn > 0 then
			slot.Data = Rift.newBolt(spawn, rnd)
			slot.State = "on"
			slot.T = (slot.Data :: Rift.Bolt).Life
			placeBolt(slot)
			showBolt(slot, 1 - vis)
			if crack and shownStage >= 3 and now - lastCrack > 4 and rnd() < 0.08 then
				lastCrack = now
				crack.Volume = 0.12 + 0.12 * vis
				crack:Play()
			end
		end
	end
end

local function updateRocks(now: number)
	local part = anchor
	if not part or #rocks == 0 then
		return
	end
	local base = part.CFrame * CFrame.Angles(0, 0, -roll) -- (las rocas, sin el giro del dibujo)
	local dist = if mode == "Dream" then 120 else Rift.Placement.Sky.Distance
	local grow = 0.35 + 0.65 * open
	for _, r in rocks do
		local x, y, depth = Rift.rockAt(r.Spec, now, open)
		local s = r.Spec.Spin
		local cf = base
			* CFrame.new(x * width, y * width, -depth * dist)
			* CFrame.Angles(s[1] * now, s[2] * now, s[3] * now)
		r.Main.CFrame = cf
		r.Wedge.CFrame = cf * r.WedgeOffset
		local scale = r.Size * grow
		if math.abs(r.Main.Size.Y - scale * 0.75) > r.Size * 0.05 then
			r.Main.Size = Vector3.new(scale, scale * 0.75, scale * 0.85)
			r.Wedge.Size = Vector3.new(scale * 0.6, scale * 0.6, scale * 0.7)
		end
	end
end

local function updateCosmos(now: number)
	local g = Art.Galaxy
	local w, h = Rift.size(open)
	local hh = h * drawHeight
	local gx, gy = toPx(g[1], g[2])
	local gr = g[3] * CANVAS_W * w
	if galaxyCore then
		galaxyCore.Position = UDim2.fromOffset(gx, gy)
		galaxyCore.Size = UDim2.fromOffset(gr * 0.45, gr * 0.45 * math.min(1, hh * 1.5))
	end
	local spin = now * 0.12
	for _, d in dots do
		local a = d.A + spin
		local r = d.R * gr
		d.Obj.Position = UDim2.fromOffset(gx + math.cos(a) * r, gy + math.sin(a) * r * 0.6 * math.min(1, hh * 1.5))
		local size = 4 + 7 * (1 - d.R)
		d.Obj.Size = UDim2.fromOffset(size, size)
	end
	for _, s in stars do
		s.Obj.BackgroundTransparency = 1 - vis * (0.55 + 0.45 * math.abs(math.sin(now * 1.3 + s.Tw)))
	end
	local img = images.Galaxia
	if img then
		img.Rotation = (now * 4) % 360 -- la galaxia gira despacio
	end
	if #star > 0 then
		local tw = 0.75 + 0.25 * math.sin(now * 5.3) * math.sin(now * 2.1)
		star[3].Rotation = 8 * math.sin(now * 0.7)
		star[4].Rotation = 8 * math.sin(now * 0.7)
		star[1].BackgroundTransparency = 1 - vis * 0.45 * tw
		star[2].BackgroundTransparency = 1 - vis * tw
	end
end

-- Transparencias (solo cuando cambia lo que se ve) y brillo con el pulso
local function applyLook(now: number)
	local sky = Rift.skyFactor(Lighting.ClockTime)
	local v = Rift.visibility(vis, sky)
	if math.abs(v - appliedVis) > 0.01 then
		appliedVis = v
		for _, f in fades do
			(f.Obj :: any)[f.Prop] = 1 - (1 - f.Base) * v
		end
		for i, beam in halos do
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 1 - 0.35 * v * (if i == 1 then 1 else 0.7)),
				NumberSequenceKeypoint.new(0.7, 1 - 0.35 * v * (if i == 1 then 1 else 0.7)),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
	end
	local pulse = Rift.pulse(now, 0)
	local flare = flareNow(now)
	if gui then
		gui.Brightness = Rift.brightness(v, pulse, flare)
	end
	local sparks = currentPhase().Sparks
	for i, e in emitters do
		e.E.Rate = e.Rate * sparks * v * Rift.pulse(now, i * 7)
	end
	if hum then
		hum.Volume = 0.35 * v * math.min(1, shownStage / 5)
		if v > 0.02 and not hum.IsPlaying then
			hum:Play()
		end
	end
end

-- La luz del entorno teñida de azul/morado (etapa 7: violeta), sin romper el ciclo del día
local function applyAmbient()
	local ok, DayLight = pcall(require, script.Parent.DayLight)
	if not ok then
		return
	end
	local st = stageSpec()
	local weight = Rift.ambientWeight(shownStage, open, vis)
	local moodName = st.Mood
	local L = live
	if L then
		-- La luz parpadea con la carga y pasa poco a poco a la de la etapa nueva
		local a = Rift.liveAt(clock - L.Start, L.T.Kind)
		local flick = 1 + 0.45 * a.Build * math.sin(clock * 23) * math.sin(clock * 7.1)
		if not L.Morphed then
			if not moodName then
				moodName = Rift.stage(L.T.To).Mood -- (del cielo normal: un presagio del color que viene)
				weight = 0.18 * a.Build
			end
			weight *= flick
		else
			local old = L.OldWeight * (1 - a.Morph)
			if L.OldMood and (L.OldMood == moodName or not moodName) then
				-- (el mismo color, o se cierra del todo: una sola capa que va de la vieja a la nueva)
				moodName = L.OldMood
				weight = math.max(weight, old)
			elseif L.OldMood then
				local oldMood = SkyMoods.List[L.OldMood]
				if oldMood and old > 0.01 then
					DayLight.pushLayer(LAYER_OLD, oldMood, 2, math.clamp(old * flick, 0, 1))
				else
					DayLight.popLayer(LAYER_OLD, 2)
					L.OldMood = nil
				end
			end
			weight = math.clamp(weight * (1 + 0.25 * a.Build * (flick - 1)), 0, 1)
		end
	end
	local mood = moodName and SkyMoods.List[moodName]
	if mood and weight > 0.01 then
		DayLight.pushLayer(LAYER, mood, 2, weight)
		ambientOn = moodName
	elseif ambientOn then
		DayLight.popLayer(LAYER, 2)
		ambientOn = nil
	end
end

---------------------------------------------------------------------
-- Aviso «¡Mira al cielo!» con una flecha hacia la grieta
---------------------------------------------------------------------
local HINT_SECONDS = 6
local hintMemo: { [string]: boolean } = {} -- (lo ya avisado en esta partida: First / Night)
local hintGui: ScreenGui? = nil
local hintArrow: TextLabel? = nil
local hintUntil = 0
local hintCount = 0
local hintKind: string? = nil
local lastHintCheck = -1

local function hideHint()
	if hintGui then
		hintGui:Destroy()
	end
	hintGui, hintArrow = nil, nil
end

local function showHint(kind: string, text: string?)
	hintKind = kind
	hintCount += 1
	hintUntil = clock + HINT_SECONDS
	hideHint()
	pcall(function()
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			return
		end
		local g = make("ScreenGui", { Name = "AvisoGrieta", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6 })
		make("TextLabel", {
			Name = "Texto",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.16, 0),
			Size = UDim2.new(0, 280, 0, 40),
			BackgroundColor3 = Color3.fromRGB(24, 18, 52),
			BackgroundTransparency = 0.25,
			Text = text or (if kind == "Night" then "🌌 ¡Mira al cielo! Esta noche la grieta brilla" else "🌌 ¡Mira al cielo!"),
			TextColor3 = Color3.fromRGB(215, 190, 255),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, g)
		hintArrow = make("TextLabel", {
			Name = "Flecha",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.16, 70),
			Size = UDim2.new(0, 56, 0, 56),
			BackgroundTransparency = 1,
			Text = "➜",
			TextColor3 = Color3.fromRGB(196, 120, 255),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}, g)
		g.Parent = playerGui
		hintGui = g
	end)
end

-- La flecha apunta a la grieta en la pantalla (si está detrás, hacia arriba)
local function updateHint()
	if not hintGui then
		return
	end
	if clock >= hintUntil then
		hideHint()
		return
	end
	local arrow = hintArrow
	local part = anchor
	local camera = workspace.CurrentCamera
	if not arrow or not part or not camera then
		return
	end
	pcall(function()
		local screen, onScreen = camera:WorldToViewportPoint(part.CFrame.Position)
		local view = camera.ViewportSize
		local from = Vector2.new(view.X * 0.5, view.Y * 0.16 + 70)
		local dx, dy = screen.X - from.X, screen.Y - from.Y
		if screen.Z < 0 then
			dx, dy = -dx, -dy -- (detrás de la cámara)
		end
		if not onScreen and math.abs(dx) + math.abs(dy) < 1 then
			dx, dy = 0, -1
		end
		arrow.Rotation = math.deg(math.atan2(dy, dx))
	end)
end

local function checkHint(now: number)
	if preview or now - lastHintCheck < 0.5 then
		return
	end
	lastHintCheck = now
	local kind = Rift.hintFor(hintMemo, phaseName, Lighting.ClockTime)
	if kind then
		if not live then
			aim() -- (al avisar, delante de la cámara: se ve sin buscarla; en plena transición no se mueve)
		end
		showHint(kind)
	end
end

---------------------------------------------------------------------
-- Cambio de etapa EN DIRECTO (shared/SkyRift.Live): un evento en el cielo, sin cámara ni interfaz
---------------------------------------------------------------------
local function liveConfig(): { [string]: any }
	local cfg = (Config :: any).SkyRift
	return if type(cfg) == "table" then cfg else {}
end

local function liveEnabled(): boolean
	return liveConfig().LiveTransitions ~= false
end

-- ¿Está ocupado en otra cosa? (escena, conversación, prólogo): sin aviso ni temblor
local function busy(): boolean
	return player:GetAttribute("InCinematic") == true or player:GetAttribute("InDialogue") == true or player:GetAttribute("InPrologue") == true
end

-- ¿Al volante o jugando un deporte? (sin temblor: que nadie se estrelle)
local function moving(): boolean
	if player:GetAttribute("Riding") ~= nil or player:GetAttribute("InSport") ~= nil or player:GetAttribute("InMiniGame") ~= nil then
		return true
	end
	local ok, seated = pcall(function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.SeatPart ~= nil
	end)
	return ok and seated == true
end

local function addBolts(n: number)
	if not gui or n <= 0 then
		return
	end
	for _ = 1, n do
		table.insert(bolts, newBoltSlot())
	end
end

-- Quita los rayos de más de la transición (deja los de la etapa)
local function trimBolts()
	local base = Rift.counts(shownStage, tierName).Bolts
	for i = #bolts, base + 1, -1 do
		local slot = bolts[i]
		if slot.Image then
			slot.Image:Destroy()
		end
		for _, f in slot.Segs do
			f:Destroy()
		end
		table.remove(bolts, i)
	end
end

local function sound(name: string, id: any, props: { [string]: any }, parent: Instance): Sound?
	if type(id) ~= "string" then
		return nil
	end
	local volume = tonumber(liveConfig().SoundVolume) or 1
	local s = make("Sound", {
		Name = name,
		SoundId = id,
		-- En el cielo, lejos, pero se oye entero y de su lado (estéreo): no se apaga con la distancia
		RollOffMode = Enum.RollOffMode.Linear,
		RollOffMinDistance = 2500,
		RollOffMaxDistance = 6000,
	}, parent)
	for k, v in props do
		(s :: any)[k] = v
	end
	s.Volume = (props.Volume or 0.5) * volume
	return s
end

-- La pieza de la onda expansiva (un anillo de luz en un SurfaceGui) y los sonidos, que van con ella
local function buildEvent(L: Live)
	local f = Instance.new("Folder")
	f.Name = "GrietaEvento"
	local ring = make("Part", {
		Name = "Onda",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Locked = true,
		Transparency = 1,
		Size = Vector3.new(1, 1, 0.2),
	}, f)
	local sg = make("SurfaceGui", {
		Name = "Lienzo",
		Face = Enum.NormalId.Front,
		Adornee = ring,
		LightInfluence = 0,
		Brightness = 3,
		MaxDistance = 100000,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = Vector2.new(512, 512),
		ResetOnSpawn = false,
	}, ring)
	local glow = make("Frame", {
		Name = "Brillo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.92),
		BackgroundColor3 = Color3.fromRGB(190, 150, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, sg)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)
	local circle = make("Frame", {
		Name = "Anillo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.94),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, sg)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
	local stroke = make("UIStroke", { Color = Color3.fromRGB(215, 195, 255), Thickness = 14, Transparency = 1 }, circle)
	L.Event, L.Ring, L.RingStroke, L.RingGlow = f, ring, stroke, glow
	local ok, SoundIds = pcall(require, Shared:FindFirstChild("SoundIds") :: ModuleScript)
	if ok and type(SoundIds) == "table" then
		-- Un trueno lejano al empezar, un rumor grave que sube con la carga y un trueno hondo al estallar
		local abre = L.T.Kind == "Abre"
		L.Far = sound("TruenoLejano", SoundIds.trueno, { Volume = 0.22, PlaybackSpeed = 0.75 }, ring)
		L.Rumble = sound("Rumor", SoundIds.viento, { Volume = 0.45, Looped = true, PlaybackSpeed = 0.22 }, ring)
		L.Boom = sound("Estallido", SoundIds.trueno, { Volume = if abre then 0.55 else 0.4, PlaybackSpeed = if abre then 0.45 else 0.85 }, ring)
		if L.Rumble then
			L.RumbleBase = L.Rumble.Volume
			L.Rumble.Volume = 0
		end
	end
	f.Parent = workspace
end

-- La de antes se queda dibujada (sin rehacerla) y se apaga: se rasga más y se desvanece, o se cose
-- y se encoge hasta una raya. Sus rocas se desprenden y van a la deriva.
local function makeGhost(L: Live): Ghost?
	local f, part = folder, anchor
	if not f or not part or shownStage <= 1 or vis < 0.01 then
		return nil
	end
	f.Name = "CieloGrietaAntes"
	local g: Ghost = {
		Folder = f,
		Part = part,
		Size = part.Size,
		Roll = roll,
		Height = height,
		Fades = {},
		Rocks = {},
		Gui = gui,
		Brightness = if gui then gui.Brightness else 2,
		Seam = {},
	}
	local burst = Rift.liveCounts(tierName, L.T.Kind, L.T.To).Sparks
	for _, d in f:GetDescendants() do
		if d:IsA("ImageLabel") then
			table.insert(g.Fades, { Obj = d, Prop = "ImageTransparency", Base = (d :: ImageLabel).ImageTransparency })
		elseif d:IsA("Frame") then
			table.insert(g.Fades, { Obj = d, Prop = "BackgroundTransparency", Base = (d :: Frame).BackgroundTransparency })
		elseif d:IsA("ParticleEmitter") then
			local e = d :: ParticleEmitter
			pcall(function()
				e:Emit(math.max(1, math.floor(burst / 4)))
			end)
			e.Rate = 0
		elseif d:IsA("Beam") then
			(d :: Beam).Enabled = false
		elseif d:IsA("Sound") then
			pcall(function()
				(d :: Sound):Stop()
			end)
		end
	end
	local out = if L.T.Kind == "Abre" then 1 else -0.6 -- (al coserse, las rocas se recogen hacia dentro)
	for _, r in rocks do
		for _, p in { r.Main, r.Wedge } do
			local off = part.CFrame:ToObjectSpace(p.CFrame)
			local dir = Vector3.new(off.Position.X, off.Position.Y, 0)
			dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, -1, 0)
			local speed = width * (0.04 + 0.08 * rnd()) * out
			table.insert(g.Rocks, {
				Part = p,
				Off = off,
				Vel = dir * speed + Vector3.new(0, 0, -width * 0.01 * rnd()),
				Spin = Vector3.new(rnd() - 0.5, rnd() - 0.5, rnd() - 0.5) * 2,
			})
		end
	end
	-- Al coserse: una costura de luz a lo largo de la grieta, con puntadas
	if L.T.Kind == "Cierra" and gui then
		local seam = make("Frame", {
			Name = "Costura",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.03),
			BackgroundColor3 = Color3.fromRGB(245, 230, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 30,
		}, gui)
		table.insert(g.Seam, seam)
		for i = 1, 7 do
			local stitch = make("Frame", {
				Name = "Puntada",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.1 + 0.8 * (i - 1) / 6, 0.5),
				Size = UDim2.fromScale(0.012, 0.35),
				Rotation = 25,
				BackgroundColor3 = Color3.fromRGB(205, 170, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 31,
			}, gui)
			table.insert(g.Seam, stitch)
		end
	end
	detach() -- (ya no es la de ahora: la nueva se construye aparte)
	return g
end

local function destroyGhost(L: Live)
	local g = L.Ghost
	if g then
		g.Folder:Destroy()
		L.Ghost = nil
	end
end

local function updateGhost(L: Live, camPos: Vector3)
	local g = L.Ghost
	if not g then
		return
	end
	local t = clock - L.MorphStart
	local u = math.clamp(t / Rift.Live.MorphSeconds, 0, 1)
	if u >= 1 then
		destroyGhost(L)
		return
	end
	local e = Rift.smooth(u)
	local sx, sy, alpha
	if L.T.Kind == "Abre" then
		sx, sy = 1 + 0.35 * e, 1 + 0.55 * e -- (se rasga más y se apaga)
		alpha = (1 - u) ^ 1.3
	else
		sx, sy = 1 - 0.6 * e, math.max(0.02, (1 - e) ^ 2.2) -- (se cose: primero se aplasta, luego se acorta)
		alpha = if u < 0.8 then 1 else math.max(0, (1 - u) / 0.2)
	end
	local at = centerPoint(camPos, g.Height)
	local cf = CFrame.lookAt(at, camPos) * CFrame.Angles(0, 0, g.Roll)
	g.Part.CFrame = cf
	g.Part.Size = Vector3.new(g.Size.X * sx, g.Size.Y * sy, g.Size.Z)
	for _, f in g.Fades do
		(f.Obj :: any)[f.Prop] = 1 - (1 - f.Base) * alpha
	end
	if g.Gui then
		g.Gui.Brightness = g.Brightness * (1 + flareNow(clock))
	end
	-- La costura brilla a medida que se cierra y se apaga al final
	local seam = math.clamp(u * 2.2, 0, 1) * alpha
	for i, f in g.Seam do
		f.BackgroundTransparency = 1 - seam * (if i == 1 then 0.95 else 0.8)
	end
	local fall = width * 0.02
	for _, r in g.Rocks do
		local pos = r.Off.Position + r.Vel * t + Vector3.new(0, -0.5 * fall * t * t, 0)
		r.Part.CFrame = cf * CFrame.new(pos) * r.Off.Rotation * CFrame.Angles(r.Spin.X * t, r.Spin.Y * t, r.Spin.Z * t)
		r.Part.Transparency = 1 - alpha
	end
end

-- Rocas que se desprenden de la nueva al abrirse (no en gráficos Bajo)
local function spawnDebris(L: Live)
	local n = Rift.liveCounts(tierName, L.T.Kind, L.T.To).Debris
	local f = L.Event
	if n <= 0 or not f or #spawn == 0 then
		return
	end
	local w = width
	for i = 1, n do
		local p = spawn[math.clamp(math.floor(rnd() * #spawn) + 1, 1, #spawn)]
		local x, y = (p[1] - 0.5) * w * 0.7, -(p[2] - 0.5) * height * 0.7
		local dir = Vector3.new(x, y, 0)
		dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, -1, 0)
		local size = w * (0.012 + 0.025 * rnd())
		local part = make(if i % 2 == 0 then "WedgePart" else "Part", {
			Name = "Escombro",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Locked = true,
			Material = Enum.Material.Basalt,
			Color = C.Rock,
			Size = Vector3.new(size, size * (0.6 + 0.4 * rnd()), size * (0.7 + 0.3 * rnd())),
		}, f)
		table.insert(L.Debris, {
			Part = part,
			Start = Vector3.new(x * 0.6, y * 0.6, -Rift.Placement.Sky.Distance * 0.05),
			Vel = dir * w * (0.05 + 0.07 * rnd()) + Vector3.new(0, -w * 0.02, 0),
			Spin = Vector3.new(rnd() - 0.5, rnd() - 0.5, rnd() - 0.5) * 3,
			Born = clock,
		})
	end
end

local function updateDebris(L: Live)
	local part = anchor
	local base = if part then part.CFrame * CFrame.Angles(0, 0, -roll) else nil
	for _, d in L.Debris do
		local t = clock - d.Born
		if base then
			local pos = d.Start + d.Vel * t + Vector3.new(0, -0.5 * width * 0.015 * t * t, 0)
			d.Part.CFrame = base * CFrame.new(pos) * CFrame.Angles(d.Spin.X * t, d.Spin.Y * t, d.Spin.Z * t)
		end
		d.Part.Transparency = math.clamp((t - 6) / 4, 0, 1)
	end
end

-- El destello: un momento de luz violeta en todo el mundo (sin tocar la cámara)
local function flashLight(L: Live, k: number)
	pcall(function()
		local cc = L.Light :: ColorCorrectionEffect?
		if not cc and k > 0.01 then
			local made = Instance.new("ColorCorrectionEffect")
			made.Name = "GrietaDestello"
			made.Parent = Lighting
			L.Light = made
			cc = made
		end
		if cc then
			cc.Brightness = 0.1 * k
			cc.Contrast = 0.05 * k
			cc.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(225, 205, 255), k)
		end
	end)
end

local function placeRing(L: Live, camPos: Vector3, a: { [string]: any })
	local ring = L.Ring
	if not ring then
		return
	end
	local at = if anchor then anchor.CFrame.Position elseif L.Ghost then L.Ghost.Part.CFrame.Position else centerPoint(camPos)
	local toCam = camPos - at
	toCam = if toCam.Magnitude > 0.01 then toCam.Unit else Vector3.yAxis
	local pos = at + toCam * 30
	local w = math.max(L.Width, 400)
	local u = a.Ring
	local d
	if u < 0 then
		d = 1
	elseif L.T.Kind == "Abre" then
		d = w * (0.3 + 2.2 * Rift.smooth(u)) -- (sale hacia fuera)
	else
		d = w * (1.3 - 1.2 * Rift.smooth(u)) -- (al coserse, se recoge hacia la costura)
	end
	ring.Size = Vector3.new(d, d, 0.2)
	ring.CFrame = CFrame.lookAt(pos, camPos)
	if L.RingStroke then
		L.RingStroke.Transparency = if u < 0 then 1 else 0.1 + 0.9 * u
	end
	if L.RingGlow then
		L.RingGlow.BackgroundTransparency = if u < 0 then 1 else 0.7 + 0.3 * u
	end
end

local function finishLive()
	local L = live
	if not L then
		return
	end
	live = nil
	liveFlare = 0
	destroyGhost(L)
	if L.Event then
		L.Event:Destroy()
	end
	if L.Light then
		pcall(function()
			(L.Light :: Instance):Destroy()
		end)
	end
	trimBolts()
	pcall(function()
		local DayLight = require(script.Parent.DayLight) :: any
		DayLight.popLayer(LAYER_OLD, 2)
	end)
end

-- Cambia ya a la etapa nueva (la de antes, apagándose aparte)
local function morph(L: Live)
	L.Morphed = true
	L.MorphStart = clock
	L.OldMood = stageSpec().Mood
	L.OldWeight = Rift.ambientWeight(shownStage, open, vis)
	local oldWidth = width
	L.Ghost = makeGhost(L)
	destroy()
	shownStage = L.T.To
	mode = "Sky"
	open, vis = 0, 0
	if shownStage > 1 then
		build()
		addBolts(L.Extra)
		spawnDebris(L)
	end
	L.Width = if shownStage > 1 then width else oldWidth
end

local function startLive(t: Rift.Transition)
	finishLive()
	local L: Live = {
		T = t,
		Start = clock,
		Morphed = false,
		MorphStart = 0,
		Flashed = false,
		Hinted = false,
		Ghost = nil,
		OldMood = nil,
		OldWeight = 0,
		Extra = Rift.liveCounts(tierName, t.Kind, t.To).BurstBolts,
		FarPlayed = false,
		RumbleBase = 0,
		Debris = {},
		Width = width,
	}
	live = L
	liveCount += 1
	if shownStage <= 1 or not folder then
		aim() -- (nace del cielo normal: delante de la cámara de ahora, para que se vea nacer)
	else
		addBolts(L.Extra) -- (la de ahora se carga: más rayos)
	end
	buildEvent(L)
end

local function updateLive()
	local L = live
	if not L then
		return
	end
	local t = clock - L.Start
	local a = Rift.liveAt(t, L.T.Kind)
	local camera = workspace.CurrentCamera
	local camPos = if camera then camera.CFrame.Position else Vector3.zero
	liveFlare = 1.4 * a.Build + 2.2 * a.Flash
	if a.Morphed and not L.Morphed then
		morph(L)
	end
	if L.Morphed and shownStage > 1 then
		-- La nueva crece en lo que dura el cambio (no a su ritmo lento de siempre)
		local phase = currentPhase()
		local target = if phase.Stage == shownStage then phase else Rift.phase(L.T.ToPhase)
		open = math.max(open, target.Open * a.Morph)
		vis = math.max(vis, target.Intensity * math.min(1, a.Morph * 1.6))
	end
	-- Rumor y truenos (en el cielo, de su lado)
	if L.Far and not L.FarPlayed and t > 0.3 then
		L.FarPlayed = true
		pcall(function()
			(L.Far :: Sound):Play()
		end)
	end
	local rumble = L.Rumble
	if rumble then
		rumble.Volume = L.RumbleBase * a.Build
		if a.Build > 0.02 and not rumble.IsPlaying then
			pcall(function()
				rumble:Play()
			end)
		end
	end
	if a.Flash > 0 and not L.Flashed then
		L.Flashed = true
		if L.Boom then
			pcall(function()
				(L.Boom :: Sound):Play()
			end)
		end
		-- Chispas que estallan en el borde de la nueva
		local burst = Rift.liveCounts(tierName, L.T.Kind, L.T.To).Sparks
		for _, e in emitters do
			pcall(function()
				e.E:Emit(math.max(1, math.floor(burst / math.max(1, #emitters))))
			end)
		end
		-- Un temblor muy leve, solo a pie y sin escena (nunca al volante ni en un deporte)
		local shake = tonumber(liveConfig().Shake) or 0
		if shake > 0 and not busy() and not moving() then
			pcall(function()
				require(script.Parent.CameraShake).shake(math.min(shake, 0.15), 0.6)
			end)
		end
	end
	flashLight(L, a.Flash)
	-- El aviso de arriba, uno por transición (no en plena escena)
	if not L.Hinted and t > 1 then
		L.Hinted = true
		if liveConfig().Toast ~= false and not busy() then
			showHint("Live", Rift.liveToast(L.T))
		end
	end
	updateGhost(L, camPos)
	updateDebris(L)
	placeRing(L, camPos, a)
	if a.Done then
		finishLive()
	end
end

-- La fase que se ve: la de tu historia o, con el ciclo de demostración, la de la hora del servidor
local function demoOn(): boolean
	return liveConfig().DemoCycle == true
end

local function demoOffset(): number
	local ok, v = pcall(function()
		return workspace:GetAttribute("SkyRiftDemoOffset")
	end)
	return if ok and type(v) == "number" then math.floor(v) else 0
end

local lastPhaseCheck = -1
local function refreshPhase()
	local demo = demoOn()
	local name = Rift.effectivePhase(storyPhase, Lighting.ClockTime, demo, demoOffset())
	local before = phaseName
	phaseName = name
	local t = Rift.track(tracker, name, storyReady or demo)
	if t and liveEnabled() and not preview then
		startLive(t) -- (se queda en su lado del cielo: quien la miraba la ve cambiar ahí mismo)
	elseif name ~= before then
		skyYaw = nil -- (empieza otra fase sin transición: se pone delante de la cámara de ahora)
	end
end

local function step(dt: number)
	clock += dt
	local now = clock
	if now - lastPhaseCheck >= 0.2 then
		lastPhaseCheck = now
		refreshPhase()
	end
	updateLive()
	-- (en plena transición, hasta el cambio se sigue viendo la de antes, cargándose)
	local L = live
	local phase = if L and not L.Morphed then Rift.phase(L.T.FromPhase) else currentPhase()
	if phase.Mode ~= mode then
		mode = phase.Mode -- (del sueño a Valmar: otro sitio y otro tamaño)
		if folder then
			build()
		end
	end
	if phase.Stage ~= shownStage then
		-- Otra etapa: la de ahora se apaga y luego nace la nueva, pequeña
		vis = math.max(0, vis - dt * 0.8)
		if vis <= 0.002 or shownStage <= 1 then
			shownStage = phase.Stage
			open, vis = 0, 0
			build()
		end
	else
		open = Rift.approach(open, phase.Open, dt)
		vis = Rift.approach(vis, phase.Intensity, dt * 2)
	end
	if now - lastAmbient > (if live then 0.1 else 0.25) then
		lastAmbient = now
		applyAmbient()
	end
	local visible = vis > 0.002 and shownStage > 1
	if not visible then
		if folder and folder.Parent then
			folder.Parent = nil -- nada que dibujar
			if hum then
				hum:Stop()
			end
		end
		return
	end
	if not folder then
		build()
	end
	local f = folder
	if not f then
		return
	end
	if f.Parent ~= workspace then
		f.Parent = workspace
	end
	placeAnchor()
	if mode == "Sky" then
		checkHint(now)
	end
	updateHint()
	if math.abs(open - appliedOpen) > 0.002 then
		applyGeometry()
	end
	updateBolts(dt, now)
	updateRocks(now)
	if now - lastLook > 1 / 15 then -- la galaxia, las estrellas y el pulso, 15 veces por segundo
		lastLook = now
		updateCosmos(now)
		applyLook(now)
	end
end

local function readPhase()
	local value = player:GetAttribute("SkyRift")
	storyPhase = if type(value) == "string" and Rift.Phases[value] then value else "Ninguna"
	storyReady = storyReady or type(value) == "string"
	refreshPhase()
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------
-- Modo pruebas: ver una fase sin jugarla (nil = la de tu historia). instant: ya del todo, sin esperar
-- a que crezca (para comprobarla al momento)
function SkyRift.preview(name: string?, instant: boolean?)
	SkyRift.finishLive()
	preview = if name and Rift.Phases[name] then name else nil
	skyYaw = nil -- (delante de la cámara)
	if instant then
		local phase = currentPhase()
		mode = phase.Mode
		shownStage = phase.Stage
		open, vis = phase.Open, phase.Intensity
		build()
	end
end

-- Modo pruebas: ver la etapa n (1..7) al momento
function SkyRift.previewStage(n: number)
	SkyRift.preview(Rift.StagePreview[math.clamp(math.floor(n), 1, #Rift.StagePreview)], true)
end

-- Escenas: la Grieta se enciende un momento (strength 1 = el doble de brillo en el pico)
function SkyRift.flare(strength: number?, seconds: number?)
	flareStart = clock
	flareSeconds = math.max(seconds or 2, 0.1)
	flareStrength = math.clamp(strength or 1, 0, 3)
end

-- Escenas: dónde está la Grieta en el mundo ahora (de ella salen las estrellas fugaces). Aunque no se
-- vea (fase Ninguna), devuelve el punto del cielo donde estaría.
function SkyRift.worldPoint(): Vector3?
	if mode == "Dream" then
		local c = Rift.Placement.Dream.Center
		return Vector3.new(c[1], c[2], c[3])
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	return centerPoint(camera.CFrame.Position)
end

function SkyRift.phaseName(): string
	return preview or phaseName
end

function SkyRift.stage(): number
	return shownStage
end

-- (pruebas) qué hay dibujado ahora
function SkyRift.debugState(): { [string]: any }
	return {
		Yaw = skyYaw,
		Hints = hintCount,
		HintKind = hintKind,
		HintGui = hintGui,
		Stage = shownStage,
		Open = open,
		Vis = vis,
		Textured = textures ~= nil,
		Bolts = #bolts,
		Rocks = #rocks,
		Emitters = #emitters,
		Ambient = ambientOn,
		Folder = folder,
		Live = if live then { Kind = live.T.Kind, From = live.T.From, To = live.T.To, Morphed = live.Morphed, T = clock - live.Start } else nil,
		LiveCount = liveCount,
		Ghost = if live and live.Ghost then live.Ghost.Folder else nil,
		Event = if live then live.Event else nil,
		Demo = demoOn(),
	}
end

-- Termina ya la transición en curso (modo pruebas)
function SkyRift.finishLive()
	local L = live
	if L then
		if not L.Morphed then
			morph(L)
		end
		finishLive()
		local phase = currentPhase()
		if phase.Stage == shownStage then
			open, vis = phase.Open, phase.Intensity
		end
	end
end

function SkyRift.init()
	tierName = Perf.tierName()
	Perf.onTier(function(name)
		if name ~= tierName then
			tierName = name
			if folder then
				build() -- (otra cantidad de rocas, rayos y partículas)
			end
		end
	end)
	readPhase()
	player:GetAttributeChangedSignal("SkyRift"):Connect(readPhase)
	-- Justo después de la cámara: la grieta se mueve con ella en el mismo fotograma
	RunService:BindToRenderStep("CieloGrieta", Enum.RenderPriority.Camera.Value + 2, step)
end

return SkyRift
