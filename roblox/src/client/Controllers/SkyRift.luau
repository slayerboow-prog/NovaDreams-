-- SkyRift (cliente): la Grieta del cielo de la Saga de la Grieta (las cuentas, en shared/SkyRift).
--
--   * Una raja dentada y ramificada que cruza el cielo en diagonal: núcleo blanco-amarillo
--     incandescente, fuego naranja/ámbar alrededor y un halo verde-cian tipo nebulosa; puntos
--     brillantes en las uniones y chispas/escombros que salen despacio. Late y parpadea un poco.
--   * Cuándo sale y cuánto: el servidor publica la fase en el atributo SkyRift del jugador
--     (LifeStoryService, según la saga). Al cambiar de fase se abre o se cierra poco a poco.
--   * En Valmar está «en el cielo»: sigue a la cámara a 450 studs, hacia Los Pinos (no hay paralaje,
--     como la luna). En el prólogo (fase Sueno) está fija encima de la isla del sueño.
--   * Solo de esta pantalla (no va por la red), sin colisión, sin consultas ni sombra. Beams de un
--     tramo y pocos emisores; en gráficos Bajo, sin halo ni partículas.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Rift = require(ReplicatedStorage.Shared.SkyRift)
local Perf = require(script.Parent.Parent.UI.Perf)

local SkyRift = {}

local player = Players.LocalPlayer

type Piece = { A0: Attachment, A1: Attachment, Beams: { [string]: Beam }, Key: number }
type Emitter = { Attachment: Attachment, Emitter: ParticleEmitter, T: number, Rate: number }

local shape = Rift.shape()
local folder: Folder? = nil
local anchor: Part? = nil
local pieces: { Piece } = {} -- en el orden de Rift.reveal
local haloPieces: { Piece } = {} -- en el orden de Rift.halo
local emitters: { Emitter } = {}
local tierName = "Medium"

local open, intensity = 0, 0
local appliedOpen = -1
local phaseName = "Ninguna"
local preview: string? = nil -- modo pruebas: ver una fase sin jugarla
local mode = "Sky"
local skyRotation = CFrame.new()
local lastLook = 0

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function currentPhase(): Rift.Phase
	return Rift.phase(preview or phaseName)
end

local function placement()
	return Rift.Placement[if mode == "Dream" then "Dream" else "Sky"]
end

local function scale(): number
	return placement().Scale
end

local function newBeam(layer: string, a0: Attachment, a1: Attachment, key: number): Beam
	local spec = Rift.Layers[layer]
	local beam = Instance.new("Beam")
	beam.Name = layer
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.Segments = 1 -- tramos rectos: la forma dentada ya la dan los puntos
	-- Cada tramo, de un tono a otro (alternando): el fuego no es un color plano
	local c0, c1 = rgb(spec.Color), rgb(spec.Color2)
	if key % 2 == 1 then
		c0, c1 = c1, c0
	end
	beam.Color = ColorSequence.new(c0, c1)
	beam.LightEmission = spec.LightEmission
	beam.LightInfluence = 0
	beam.Brightness = spec.Brightness
	beam.Transparency = NumberSequence.new(1)
	if layer == "Halo" then
		beam.Texture = Rift.HaloTexture
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.TextureLength = 1
		beam.TextureSpeed = 0.04 + 0.02 * (key % 3) -- la nebulosa se mueve muy despacio
		beam.ZOffset = 0
	elseif layer == "Fire" then
		beam.ZOffset = 1
	else
		beam.ZOffset = 2 -- el núcleo, siempre por encima del fuego
	end
	beam.Enabled = false
	beam.Parent = a0
	return beam
end

local function newPiece(parent: BasePart, key: number, layers: { string }): Piece
	local a0 = Instance.new("Attachment")
	a0.Name = "A" .. key
	a0.Parent = parent
	local a1 = Instance.new("Attachment")
	a1.Name = "B" .. key
	a1.Parent = parent
	local piece: Piece = { A0 = a0, A1 = a1, Beams = {}, Key = key }
	for _, layer in layers do
		piece.Beams[layer] = newBeam(layer, a0, a1, key)
	end
	return piece
end

local function pointOnMain(t: number): Rift.Point
	local pts = shape.Main.Points
	local f = t * (#pts - 1) + 1
	local i = math.clamp(math.floor(f), 1, #pts - 1)
	local k = f - i
	return { X = pts[i].X + (pts[i + 1].X - pts[i].X) * k, Y = pts[i].Y + (pts[i + 1].Y - pts[i].Y) * k }
end

local function newEmitter(parent: BasePart, at: Rift.Point, t: number, kind: string): Emitter
	local s = scale()
	local att = Instance.new("Attachment")
	att.Name = kind
	att.Position = Vector3.new(at.X * s, at.Y * s, 0)
	att.Parent = parent
	local e = Instance.new("ParticleEmitter")
	e.Name = kind
	e.Texture = Rift.SparkTexture
	e.LockedToPart = true -- (la grieta sigue a la cámara: las partículas van con ella)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Brightness = 3
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-30, 30)
	local rate
	if kind == "Union" then
		-- Punto brillante: un destello que casi no se mueve
		local size = s * Rift.MainWidth * 2.6
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, size * 0.5),
			NumberSequenceKeypoint.new(0.4, size),
			NumberSequenceKeypoint.new(1, size * 0.3),
		})
		e.Color = ColorSequence.new(Color3.fromRGB(255, 248, 220), Color3.fromRGB(255, 160, 50))
		e.Lifetime = NumberRange.new(1, 1.6)
		e.Speed = NumberRange.new(0)
		rate = 2.2
	else
		-- Chispas y escombros: salen despacio hacia todos lados y caen un poco (caen cosas del cielo)
		local size = s * Rift.MainWidth * 0.45
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 0.2) })
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 160)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 130, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 40, 20)),
		})
		e.Lifetime = NumberRange.new(3, 5)
		e.Speed = NumberRange.new(s * 0.01, s * 0.03)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = Vector3.new(0, -s * 0.006, 0)
		e.Drag = 0.4
		rate = 3
	end
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Rate = 0
	e.Parent = att
	return { Attachment = att, Emitter = e, T = t, Rate = rate }
end

local function destroy()
	if folder then
		folder:Destroy()
	end
	folder, anchor = nil, nil
	pieces, haloPieces, emitters = {}, {}, {}
	appliedOpen = -1
end

local function placeAnchor()
	local part = anchor
	if not part then
		return
	end
	local p = placement()
	if mode == "Dream" then
		local c = p.Center
		part.CFrame = CFrame.new(c[1], c[2], c[3]) * CFrame.Angles(0, p.Yaw, 0) * CFrame.Angles(p.Pitch, 0, 0)
	else
		local camera = workspace.CurrentCamera
		if camera then
			local d = p.Direction
			local dir = Vector3.new(d[1], d[2], d[3]).Unit
			part.CFrame = skyRotation + camera.CFrame.Position + dir * p.Distance
		end
	end
end

local function build()
	destroy()
	local look = Rift.tierLook(tierName)
	local f = Instance.new("Folder")
	f.Name = "CieloGrieta"
	local part = Instance.new("Part")
	part.Name = "Grieta"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Locked = true
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Parent = f
	folder, anchor = f, part

	local d = Rift.Placement.Sky.Direction
	local dir = Vector3.new(d[1], d[2], d[3]).Unit
	skyRotation = CFrame.lookAt(Vector3.zero, dir) -- (mirando hacia fuera: la derecha es la de la cámara)

	for i, seg in Rift.reveal(shape, 1) do
		table.insert(pieces, newPiece(part, i, if seg.Path == 0 then look.Layers else look.BranchLayers))
	end
	if look.Halo then
		for i in Rift.halo(shape, 1) do
			table.insert(haloPieces, newPiece(part, 1000 + i, { "Halo" }))
		end
	end
	if look.Particles then
		for _, joint in shape.Joints do
			table.insert(emitters, newEmitter(part, joint.Point, joint.T, "Union"))
		end
		for _, t in Rift.SparkSpots do
			table.insert(emitters, newEmitter(part, pointOnMain(t), t, "Chispas"))
		end
	end
	placeAnchor()
end

-- Dónde y qué ancho tiene cada tramo con la apertura de ahora
local function applyGeometry()
	local s = scale()
	local function put(list: { Piece }, segs: { Rift.Segment }, mul: (string) -> number)
		for i, seg in segs do
			local piece = list[i]
			if piece then
				piece.A0.Position = Vector3.new(seg.A.X * s, seg.A.Y * s, 0)
				piece.A1.Position = Vector3.new(seg.B.X * s, seg.B.Y * s, 0)
				for layer, beam in piece.Beams do
					local m = mul(layer)
					beam.Width0 = seg.W0 * s * m
					beam.Width1 = seg.W1 * s * m
					beam.Enabled = seg.Visible
				end
			end
		end
	end
	put(pieces, Rift.reveal(shape, open), function(layer)
		return Rift.Layers[layer].WidthMul
	end)
	put(haloPieces, Rift.halo(shape, open), function()
		return 1 -- (el ancho del halo ya viene hecho)
	end)
	for _, e in emitters do
		e.Emitter.Enabled = math.abs(e.T - 0.5) * 2 <= open
	end
	appliedOpen = open
end

-- Brillo, transparencia y pulso
local function applyLook(now: number)
	local sky = Rift.skyFactor(Lighting.ClockTime)
	local function paint(list: { Piece })
		for _, piece in list do
			local pulse = Rift.pulse(now, piece.Key)
			for layer, beam in piece.Beams do
				if beam.Enabled then
					local transparency, brightness = Rift.layerLook(layer, intensity, pulse, sky)
					beam.Transparency = NumberSequence.new(transparency)
					beam.Brightness = brightness
				end
			end
		end
	end
	paint(pieces)
	paint(haloPieces)
	local sparks = currentPhase().Sparks
	for i, e in emitters do
		local pulse = Rift.pulse(now, i * 7)
		e.Emitter.Rate = if e.Emitter.Enabled then e.Rate * sparks * intensity * pulse else 0
	end
end

local function step(dt: number)
	local phase = currentPhase()
	open = Rift.approach(open, phase.Open, dt)
	intensity = Rift.approach(intensity, phase.Intensity, dt)
	local visible = intensity > 0.002 and open > 0.002
	if not visible then
		if folder and folder.Parent then
			folder.Parent = nil -- nada que dibujar
		end
		return
	end
	if mode ~= phase.Mode then
		mode = phase.Mode -- (del sueño a Valmar: otra escala y otro sitio)
		if folder then
			build()
		end
	end
	if not folder then
		build()
	end
	local f = folder :: Folder
	if f.Parent ~= workspace then
		f.Parent = workspace
	end
	if mode == "Sky" then
		placeAnchor()
	end
	if math.abs(open - appliedOpen) > 0.002 then
		applyGeometry()
	end
	local now = os.clock()
	if now - lastLook > 1 / 15 then -- el pulso, 15 veces por segundo basta
		lastLook = now
		applyLook(now)
	end
end

local function readPhase()
	local value = player:GetAttribute("SkyRift")
	phaseName = if type(value) == "string" and Rift.Phases[value] then value else "Ninguna"
end

-- Modo pruebas: ver una fase sin jugarla (nil = la de tu historia)
function SkyRift.preview(name: string?)
	preview = if name and Rift.Phases[name] then name else nil
end

function SkyRift.phaseName(): string
	return preview or phaseName
end

function SkyRift.init()
	tierName = Perf.tierName()
	Perf.onTier(function(name)
		if name ~= tierName then
			tierName = name
			if folder then
				build() -- (otra cantidad de capas y partículas)
			end
		end
	end)
	readPhase()
	player:GetAttributeChangedSignal("SkyRift"):Connect(readPhase)
	-- Justo después de la cámara: la grieta se mueve con ella en el mismo fotograma
	RunService:BindToRenderStep("CieloGrieta", Enum.RenderPriority.Camera.Value + 2, step)
end

return SkyRift
