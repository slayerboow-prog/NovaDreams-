-- WeaponFx (cliente): todo lo que se ve y se oye de un disparo. Lo llaman WeaponController (tus
-- disparos, al momento) y los avisos del servidor ("Shot", "Reload") para los de los demás.
--
--   * Fogonazo corto y brillante en la boca del cañón, con una luz que dura un instante.
--   * Trazador de la bala hasta donde da (o dos cables el táser, un chorro el agua, una bola la pintura).
--   * Impactos según el material: chispas en metal, polvo y esquirlas en hormigón/ladrillo/piedra,
--     astillas en madera, salpicadura en el agua, tierra en el césped; agujero de bala en la superficie
--     (se desvanece a los 20 s; como mucho 60). A las personas: marca de impacto y una nubecilla (sin sangre).
--   * Casquillos que saltan a la derecha con giro, rebotan con un "tin" y se quedan un rato (como mucho
--     30; los cartuchos de escopeta son rojos con culote dorado; el revólver los suelta al recargar).
--   * Humo del cañón al dejar de disparar después de una ráfaga (y reverbero tras ráfagas largas).
--   * Sonido por capas: el disparo y el eco; de lejos más flojo y apagado; fuera, más eco que dentro.
--   * Recarga: cargador fuera (se cae al suelo), cargador dentro y corredera; clic en seco sin balas;
--     la corredera se queda atrás con el cargador vacío.
-- Todo se recicla (piezas en una carpeta de la cámara) y en modo ligero (móviles) hay la mitad.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Perf = require(script.Parent.Parent.UI.Perf)
local SoundFx = require(script.Parent.SoundFx)

local WeaponFx = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local FX = Weapons.Fx
local MAX_CASINGS = if Perf.lite then math.floor(FX.MaxCasings / 2) else FX.MaxCasings
local MAX_HOLES = if Perf.lite then math.floor(FX.MaxHoles / 2) else FX.MaxHoles
local PARTICLES = if Perf.lite then 0.5 else 1

local folder: Folder
local emitters: { [string]: { Attachment: Attachment, Emitter: ParticleEmitter, Default: ColorSequence } } = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function newPart(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function ignoreList(): { Instance }
	local list: { Instance } = { folder }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(list, other.Character)
		end
	end
	return list
end

-- ¿Estás bajo techo? (el eco suena distinto)
local function indoors(at: Vector3): boolean
	rayParams.FilterDescendantsInstances = ignoreList()
	return workspace:Raycast(at, Vector3.new(0, 40, 0), rayParams) ~= nil
end

-- CFrame en `at` mirando hacia `dir` (sin fallar si mira justo arriba o abajo)
local function face(at: Vector3, dir: Vector3): CFrame
	local d = if dir.Magnitude > 1e-4 then dir.Unit else Vector3.new(0, 1, 0)
	if math.abs(d.Y) > 0.999 then
		d = (d + Vector3.new(0.01, 0, 0.01)).Unit
	end
	return CFrame.lookAt(at, at + d)
end

local function listener(): Vector3
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.Position else Vector3.zero
end

-- Suena en un punto del mundo (volumen, tono, apagado 0..1 = se pierden los agudos)
function WeaponFx.soundAt(name: string, at: Vector3, volume: number, pitch: number?, muffle: number?)
	if SoundFx.isMuted() or volume <= 0.01 then
		return
	end
	local id = SoundFx.id(name)
	if not id then
		return
	end
	-- (volumen y tono de Config, o de su Fallback si el audio aún no está subido)
	local v, p = SoundFx.tune(name, id, volume, pitch)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = at
	attachment.Parent = workspace.Terrain
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = v
	sound.PlaybackSpeed = p * (0.96 + math.random() * 0.08)
	sound.RollOffMaxDistance = FX.HearDistance
	sound.RollOffMinDistance = 12
	sound.SoundGroup = SoundFx.group("SFX") -- (grupo de efectos: el silencio y el compresor también valen aquí)
	if (muffle or 0) > 0.05 then
		local eq = Instance.new("EqualizerSoundEffect")
		eq.HighGain = -40 * (muffle :: number)
		eq.MidGain = -12 * (muffle :: number)
		eq.LowGain = 2
		eq.Parent = sound
	end
	sound.Parent = attachment
	sound:Play()
	task.delay(4, function()
		attachment:Destroy()
	end)
end

-- El disparo con sus capas: estampido + eco (más fuera que dentro; de lejos, apagado)
function WeaponFx.shotSound(w: Weapons.Weapon, at: Vector3)
	local distance = (listener() - at).Magnitude
	local inside = indoors(at)
	local volume, muffle, echo = Weapons.hearing(distance, inside, math.max(w.Loud, 0.25))
	WeaponFx.soundAt(w.Sound.Shot, at, volume * w.Sound.Volume, w.Sound.Pitch, muffle)
	if w.Sound.Tail and echo > 0.05 then
		task.delay(0.08 + distance / 900 + (if inside then 0.02 else 0.18), function()
			WeaponFx.soundAt("EcoDisparo", at, echo * volume, if inside then 1.3 else 0.9, math.max(muffle, 0.4))
		end)
	end
end

---------------------------------------------------------------------
-- Partículas (un emisor por tipo; se mueve al sitio y se "dispara")
---------------------------------------------------------------------

local SPARKS = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local function makeEmitter(kind: string, props: { [string]: any })
	local attachment = Instance.new("Attachment")
	attachment.Name = "Fx_" .. kind
	attachment.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.EmissionDirection = Enum.NormalId.Front
	for key, value in props do
		(e :: any)[key] = value
	end
	e.Parent = attachment
	emitters[kind] = { Attachment = attachment, Emitter = e, Default = e.Color }
end

local function burst(kind: string, at: Vector3, normal: Vector3?, count: number, color: Color3?)
	local entry = emitters[kind]
	if not entry then
		return
	end
	entry.Attachment.WorldCFrame = face(at, normal or Vector3.new(0, 1, 0))
	entry.Emitter.Color = if color then ColorSequence.new(color) else entry.Default
	entry.Emitter:Emit(math.max(1, math.floor(count * PARTICLES + 0.5)))
end

local function setupEmitters()
	local seq = NumberSequence.new
	local key = NumberSequenceKeypoint.new
	makeEmitter("Sparks", { Texture = SPARKS, Color = ColorSequence.new(rgb(255, 220, 120)), LightEmission = 1, Size = seq(0.18, 0), Lifetime = NumberRange.new(0.12, 0.3), Speed = NumberRange.new(14, 26), SpreadAngle = Vector2.new(55, 55), Acceleration = Vector3.new(0, -40, 0), Drag = 3 })
	makeEmitter("Dust", { Texture = SMOKE, Color = ColorSequence.new(rgb(170, 160, 150)), Size = seq({ key(0, 0.3), key(1, 1.3) }), Transparency = seq({ key(0, 0.35), key(1, 1) }), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(35, 35), Drag = 4, Acceleration = Vector3.new(0, 2, 0) })
	makeEmitter("Chips", { Texture = SPARKS, Color = ColorSequence.new(rgb(120, 115, 110)), Size = seq(0.12), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(8, 16), SpreadAngle = Vector2.new(45, 45), Acceleration = Vector3.new(0, -50, 0) })
	makeEmitter("Splinters", { Texture = SPARKS, Color = ColorSequence.new(rgb(150, 110, 70)), Size = seq(0.16), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(7, 14), SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, -45, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-300, 300) })
	makeEmitter("Water", { Texture = SMOKE, Color = ColorSequence.new(rgb(200, 225, 245)), Size = seq({ key(0, 0.3), key(1, 0.9) }), Transparency = seq({ key(0, 0.2), key(1, 1) }), Lifetime = NumberRange.new(0.35, 0.6), Speed = NumberRange.new(8, 14), SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, -45, 0) })
	makeEmitter("Dirt", { Texture = SMOKE, Color = ColorSequence.new(rgb(110, 90, 60)), Size = seq({ key(0, 0.3), key(1, 1) }), Transparency = seq({ key(0, 0.3), key(1, 1) }), Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(5, 10), SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, -25, 0) })
	makeEmitter("Glass", { Texture = SPARKS, Color = ColorSequence.new(rgb(210, 235, 255)), LightEmission = 0.6, Size = seq(0.14), Lifetime = NumberRange.new(0.3, 0.7), Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, -50, 0) })
	makeEmitter("Puff", { Texture = SMOKE, Color = ColorSequence.new(rgb(235, 235, 235)), Size = seq({ key(0, 0.25), key(1, 0.8) }), Transparency = seq({ key(0, 0.4), key(1, 1) }), Lifetime = NumberRange.new(0.25, 0.45), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(40, 40), Drag = 3 })
	makeEmitter("Paint", { Texture = SMOKE, Color = ColorSequence.new(rgb(80, 220, 90)), Size = seq({ key(0, 0.4), key(1, 0.9) }), Transparency = seq({ key(0, 0), key(1, 1) }), Lifetime = NumberRange.new(0.25, 0.4), Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, -30, 0) })
	makeEmitter("Muzzle", { Texture = FIRE, Color = ColorSequence.new(rgb(255, 210, 120), rgb(255, 120, 40)), LightEmission = 1, Size = seq({ key(0, 0.7), key(1, 0.1) }), Transparency = seq({ key(0, 0), key(1, 1) }), Lifetime = NumberRange.new(0.04, 0.07), Speed = NumberRange.new(10, 18), SpreadAngle = Vector2.new(12, 12), LockedToPart = false })
	makeEmitter("MuzzleSmoke", { Texture = SMOKE, Color = ColorSequence.new(rgb(200, 200, 200)), Size = seq({ key(0, 0.3), key(1, 1.2) }), Transparency = seq({ key(0, 0.6), key(1, 1) }), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, 3, 0) })
end

---------------------------------------------------------------------
-- Fogonazo
---------------------------------------------------------------------

local flashPart: Part
local flashLight: PointLight
local flashToken = 0

function WeaponFx.muzzle(at: CFrame, w: Weapons.Weapon)
	if w.Kind == "Toy" then
		if w.Class == "Agua" then
			burst("Water", at.Position, at.LookVector, 3)
		end
		return
	end
	if w.Kind == "Taser" then
		burst("Sparks", at.Position, at.LookVector, 6, rgb(140, 200, 255))
		return
	end
	flashToken += 1
	local token = flashToken
	local size = if w.Class == "Escopeta" or w.Class == "Francotirador" then 1.6 elseif w.Hands == 2 then 1.2 else 0.9
	flashPart.Size = Vector3.new(size * 0.7, size * 0.7, size * 1.3)
	flashPart.CFrame = at * CFrame.new(0, 0, -size * 0.55) * CFrame.Angles(0, 0, math.random() * math.pi)
	flashPart.Transparency = 0.1
	flashLight.Enabled = true
	flashLight.Range = 10 + size * 6
	burst("Muzzle", at.Position, at.LookVector, 4)
	task.delay(0.045, function()
		if flashToken == token then
			flashPart.Transparency = 1
			flashLight.Enabled = false
		end
	end)
end

---------------------------------------------------------------------
-- Trazadores
---------------------------------------------------------------------

type Tracer = { Part: Part, From: Vector3, To: Vector3, Start: number, Duration: number, Kind: string, Life: number }
local tracers: { Tracer } = {}
local tracerPool: { Part } = {}

local function tracerPart(): Part
	local p = table.remove(tracerPool)
	if p then
		return p
	end
	return newPart("Trazador", Vector3.new(0.06, 0.06, 1), rgb(255, 230, 160), Enum.Material.Neon)
end

function WeaponFx.tracer(from: Vector3, to: Vector3, w: Weapons.Weapon)
	if #tracers >= FX.MaxTracers then
		local old = table.remove(tracers, 1) :: Tracer
		old.Part.Transparency = 1
		table.insert(tracerPool, old.Part)
	end
	local distance = (to - from).Magnitude
	local p = tracerPart()
	local kind = w.Tracer
	if kind == "Wire" then
		p.Color = rgb(255, 230, 60)
		p.Size = Vector3.new(0.03, 0.03, distance)
		p.CFrame = CFrame.lookAt((from + to) / 2, to)
		p.Transparency = 0.2
		table.insert(tracers, { Part = p, From = from, To = to, Start = os.clock(), Duration = 0, Kind = kind, Life = 1.2 })
		return
	end
	p.Color = if kind == "Water" then rgb(140, 200, 255) elseif kind == "Paint" then rgb(80, 220, 90) else rgb(255, 230, 160)
	p.Material = if kind == "Water" then Enum.Material.Glass else Enum.Material.Neon
	local thick = if kind == "Paint" then 0.35 elseif kind == "Water" then 0.18 else 0.07
	p.Size = Vector3.new(thick, thick, if kind == "Paint" then 0.35 else math.min(6, distance))
	p.Transparency = if kind == "Water" then 0.35 else 0.15
	local duration = math.clamp(distance / w.Velocity, 0.02, 0.45)
	table.insert(tracers, { Part = p, From = from, To = to, Start = os.clock(), Duration = duration, Kind = kind, Life = duration + 0.05 })
end

local function stepTracers()
	local now = os.clock()
	for i = #tracers, 1, -1 do
		local t = tracers[i]
		local age = now - t.Start
		if age > t.Life then
			t.Part.Transparency = 1
			table.remove(tracers, i)
			table.insert(tracerPool, t.Part)
		elseif t.Kind == "Wire" then
			t.Part.Transparency = 0.2 + 0.8 * (age / t.Life)
		else
			local u = math.clamp(age / math.max(t.Duration, 1e-3), 0, 1)
			local head = t.From:Lerp(t.To, u)
			if t.Kind == "Water" then
				-- El chorro cae un poco (parábola)
				head -= Vector3.new(0, 4 * u * u * (t.To - t.From).Magnitude / 45, 0)
			end
			local len = t.Part.Size.Z
			local tail = head - (t.To - t.From).Unit * math.min(len, (head - t.From).Magnitude)
			t.Part.CFrame = CFrame.lookAt((head + tail) / 2, head + (t.To - t.From).Unit * 0.01)
		end
	end
end

---------------------------------------------------------------------
-- Agujeros de bala
---------------------------------------------------------------------

type Hole = { Part: Part, Born: number }
local holes: { Hole } = {}
local oldestHole = 1

function WeaponFx.hole(at: Vector3, normal: Vector3, color: Color3?, size: number?)
	local index = Weapons.recycleIndex(#holes, MAX_HOLES, oldestHole)
	local hole = holes[index]
	if not hole then
		local p = newPart("AgujeroBala", Vector3.new(0.02, 0.25, 0.25), rgb(25, 22, 20))
		p.Shape = Enum.PartType.Cylinder
		hole = { Part = p, Born = 0 }
		holes[index] = hole
	else
		oldestHole = oldestHole % MAX_HOLES + 1
	end
	local s = size or 0.25
	hole.Part.Size = Vector3.new(0.02, s, s)
	hole.Part.Color = color or rgb(25, 22, 20)
	-- El cilindro mira por su eje X: lo alineamos con la normal y un pelín fuera de la superficie
	local cf = face(at + normal * 0.012, normal)
	hole.Part.CFrame = cf * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.random() * 6.28, 0, 0)
	hole.Part.Transparency = 0.05
	hole.Born = os.clock()
end

local function stepHoles()
	local now = os.clock()
	for _, hole in holes do
		local age = now - hole.Born
		if age > FX.HoleSeconds - 3 and hole.Part.Transparency < 1 then
			hole.Part.Transparency = math.clamp((age - (FX.HoleSeconds - 3)) / 3, 0, 1)
		end
	end
end

---------------------------------------------------------------------
-- Casquillos (y cargadores que caen)
---------------------------------------------------------------------

type Casing = { Parts: { Part }, Offsets: { CFrame }, Position: Vector3, Velocity: Vector3, Spin: Vector3, Rot: CFrame, Born: number, Life: number, Bounces: number, Resting: boolean, Sound: boolean }
local casings: { Casing } = {}
local oldestCasing = 1

local function casingParts(kind: string): ({ Part }, { CFrame })
	if kind == "Shell" then
		local body = newPart("Cartucho", Vector3.new(0.13, 0.13, 0.32), rgb(180, 30, 30))
		local base = newPart("Culote", Vector3.new(0.14, 0.14, 0.08), rgb(210, 170, 70), Enum.Material.Metal)
		return { body, base }, { CFrame.new(), CFrame.new(0, 0, 0.18) }
	end
	return { newPart("Casquillo", Vector3.new(0.07, 0.07, 0.2), rgb(214, 170, 70), Enum.Material.Metal) }, { CFrame.new() }
end

local function spawnDebris(kind: string, from: CFrame, velocity: Vector3, life: number, custom: Part?)
	local index = Weapons.recycleIndex(#casings, MAX_CASINGS, oldestCasing)
	local old = casings[index]
	if old then
		oldestCasing = oldestCasing % MAX_CASINGS + 1
		for _, p in old.Parts do
			p:Destroy()
		end
	end
	local parts, offsets
	if custom then
		parts, offsets = { custom }, { CFrame.new() }
	else
		parts, offsets = casingParts(kind)
	end
	casings[index] = {
		Parts = parts, Offsets = offsets, Position = from.Position, Velocity = velocity,
		Spin = Vector3.new(math.random() * 20 - 10, math.random() * 30 - 15, math.random() * 20 - 10),
		Rot = from.Rotation, Born = os.clock(), Life = life, Bounces = 0, Resting = false, Sound = custom == nil,
	}
end

-- Casquillos del arma (en la ventana de expulsión)
function WeaponFx.casings(model: Model?, w: Weapons.Weapon, event: string, spent: number?)
	local kind, count = Weapons.casingFor(w, event, spent)
	if not kind or count <= 0 or not model or not model.PrimaryPart then
		return
	end
	local port = model.PrimaryPart:FindFirstChild("Expulsion") :: Attachment?
	local cf = if port then port.WorldCFrame else model.PrimaryPart.CFrame
	for i = 1, math.min(count, 6) do
		local v = Weapons.casingVelocity(cf.RightVector, cf.UpVector, cf.LookVector * -1, math.random(), math.random())
		if event == "Reload" then
			v = Vector3.new(math.random() - 0.5, -2, math.random() - 0.5) -- (el revólver los suelta hacia abajo)
		end
		spawnDebris(kind, cf * CFrame.new(0, 0, i * 0.05), v, FX.CasingSeconds)
	end
end

-- El cargador vacío se cae al suelo (una copia; el de verdad se esconde hasta que entra el nuevo)
function WeaponFx.dropMag(model: Model?)
	local mag = model and model:FindFirstChild("Cargador") :: BasePart?
	if not mag then
		return
	end
	local copy = mag:Clone()
	for _, child in copy:GetChildren() do
		child:Destroy()
	end
	copy.Anchored = true
	copy.CanCollide = false
	copy.CanQuery = false
	copy.Parent = folder
	mag.LocalTransparencyModifier = 1
	spawnDebris("Mag", mag.CFrame, Vector3.new(0, -3, 0) + mag.CFrame.LookVector * 0.5, 5, copy)
end

function WeaponFx.showMag(model: Model?)
	local mag = model and model:FindFirstChild("Cargador") :: BasePart?
	if mag then
		mag.LocalTransparencyModifier = 0
	end
end

local GRAVITY = Vector3.new(0, -60, 0)
local function stepCasings(dt: number)
	local now = os.clock()
	rayParams.FilterDescendantsInstances = ignoreList()
	for _, c in casings do
		local age = now - c.Born
		if age > c.Life + 0.6 then
			if c.Parts[1].Transparency < 1 then
				for _, p in c.Parts do
					p.Transparency = 1
				end
			end
			continue
		end
		if not c.Resting and c.Velocity.Magnitude < 1e-3 then
			c.Velocity = Vector3.new(0, -1, 0)
		end
		if not c.Resting then
			local nextPos = c.Position + c.Velocity * dt
			local hit = workspace:Raycast(c.Position, nextPos - c.Position + (nextPos - c.Position).Unit * 0.05, rayParams)
			if hit then
				c.Bounces += 1
				local n = hit.Normal
				c.Velocity = (c.Velocity - 2 * c.Velocity:Dot(n) * n) * 0.35
				nextPos = hit.Position + n * 0.05
				c.Spin *= 0.5
				if c.Sound and c.Bounces <= 2 then
					WeaponFx.soundAt("Casquillo", hit.Position, if c.Bounces == 1 then 1 else 0.6, 0.9 + math.random() * 0.3)
				end
				if c.Bounces >= 3 or c.Velocity.Magnitude < 2 then
					c.Resting = true
					-- Tumbado en el suelo
					c.Rot = CFrame.fromMatrix(Vector3.zero, n:Cross(Vector3.new(0.3, 0, 1)).Unit, n) * CFrame.Angles(math.rad(90), math.random() * 6, 0)
				end
			else
				c.Velocity += GRAVITY * dt
				c.Rot = c.Rot * CFrame.Angles(c.Spin.X * dt, c.Spin.Y * dt, c.Spin.Z * dt)
			end
			c.Position = nextPos
		end
		local fade = math.clamp((age - c.Life) / 0.6, 0, 1)
		local base = CFrame.new(c.Position) * c.Rot
		for i, p in c.Parts do
			p.CFrame = base * c.Offsets[i]
			p.Transparency = fade
		end
	end
end

---------------------------------------------------------------------
-- Humo del cañón
---------------------------------------------------------------------

local smokes: { [Model]: { Until: number, Heat: number } } = {}

function WeaponFx.barrelSmoke(model: Model?, burstLength: number, w: Weapons.Weapon)
	if not model or w.Kind ~= "Real" then
		return
	end
	local long = w.Class == "Fusil" or w.Class == "Subfusil"
	if burstLength < FX.SmokeAfter and not long then
		return
	end
	smokes[model] = { Until = os.clock() + (if burstLength >= 12 then 2 else 1.3), Heat = if burstLength >= 12 then 1 else 0 }
end

local smokeClock = 0
local function stepSmoke(dt: number)
	smokeClock += dt
	if smokeClock < 0.12 then
		return
	end
	smokeClock = 0
	local now = os.clock()
	for model, s in smokes do
		local boca = model.PrimaryPart and model.PrimaryPart:FindFirstChild("Boca") :: Attachment?
		if now > s.Until or not boca or not model.Parent then
			smokes[model] = nil
		else
			burst("MuzzleSmoke", boca.WorldPosition, Vector3.new(0, 1, 0), 1)
			if s.Heat > 0 then
				-- Reverbero: aire caliente (casi transparente, sube rápido)
				burst("Puff", boca.WorldPosition + Vector3.new(0, 0.3, 0), Vector3.new(0, 1, 0), 1, rgb(255, 255, 255))
			end
		end
	end
end

---------------------------------------------------------------------
-- Impactos
---------------------------------------------------------------------

local PAINT_COLORS = { rgb(80, 220, 90), rgb(255, 80, 180), rgb(255, 200, 40), rgb(60, 160, 255) }

function WeaponFx.impact(hit: { [string]: any }, w: Weapons.Weapon)
	local at: Vector3 = hit.P
	local normal: Vector3 = hit.N or Vector3.new(0, 1, 0)
	if hit.K == "Miss" then
		return
	end
	local distance = (listener() - at).Magnitude
	if distance > 400 then
		return
	end
	if w.Kind == "Toy" then
		if w.Class == "Agua" then
			burst("Water", at, normal, 4)
		else
			local color = PAINT_COLORS[math.random(1, #PAINT_COLORS)]
			burst("Paint", at, normal, 8, color)
			if hit.K ~= "Char" then
				WeaponFx.hole(at, normal, color, 0.7) -- mancha de pintura
			end
		end
		return
	end
	if w.Kind == "Taser" then
		burst("Sparks", at, normal, 5, rgb(160, 210, 255))
		return
	end
	if hit.K == "Char" then
		burst("Puff", at, normal, 4)
		return
	end
	local kind = if hit.K == "Glass" then "Glass" else Weapons.impactKind(hit.M)
	if kind == "Sparks" then
		burst("Sparks", at, normal, 10)
		if math.random() < 0.35 then
			WeaponFx.soundAt("Rebote", at, 0.8, 0.8 + math.random() * 0.6)
		end
	elseif kind == "Dust" then
		burst("Dust", at, normal, 4)
		burst("Chips", at, normal, 5)
	elseif kind == "Splinters" then
		burst("Splinters", at, normal, 7)
		burst("Dust", at, normal, 2, rgb(150, 120, 90))
	elseif kind == "Water" then
		burst("Water", at, Vector3.new(0, 1, 0), 10)
	elseif kind == "Dirt" then
		burst("Dirt", at, normal, 6)
	elseif kind == "Glass" then
		burst("Glass", at, normal, 10)
	else
		burst("Puff", at, normal, 4, rgb(180, 180, 180))
	end
	WeaponFx.soundAt("ImpactoBala", at, math.clamp(1 - distance / 200, 0, 1), 0.9 + math.random() * 0.3)
	if Weapons.leavesHole(kind) then
		WeaponFx.hole(at, normal, nil, if w.Pellets > 1 then 0.16 else 0.25)
	end
end

---------------------------------------------------------------------
-- Corredera: retrocede en cada disparo y se queda atrás con el cargador vacío
---------------------------------------------------------------------

local slideHome: { [Weld]: CFrame } = setmetatable({}, { __mode = "k" }) :: any

function WeaponFx.slide(model: Model?, back: boolean, cycle: boolean?)
	local grip = model and model.PrimaryPart
	local weld = grip and grip:FindFirstChild("W_Corredera") :: Weld?
	if not weld then
		return
	end
	local home = slideHome[weld] or weld.C0
	slideHome[weld] = home
	local scale = (model :: Model):GetAttribute("Scale") or 1
	local offset = CFrame.new(0, 0, 0.22 * scale)
	if cycle and not back then
		weld.C0 = home * offset
		task.delay(0.05, function()
			if weld.Parent then
				weld.C0 = home
			end
		end)
	else
		weld.C0 = if back then home * offset else home
	end
end

---------------------------------------------------------------------

function WeaponFx.init()
	folder = Instance.new("Folder")
	folder.Name = "WeaponFx"
	folder.Parent = workspace.CurrentCamera or workspace
	setupEmitters()
	flashPart = newPart("Fogonazo", Vector3.new(0.8, 0.8, 1.2), rgb(255, 200, 110), Enum.Material.Neon)
	flashPart.Shape = Enum.PartType.Ball
	flashPart.Transparency = 1
	flashLight = Instance.new("PointLight")
	flashLight.Color = rgb(255, 190, 120)
	flashLight.Brightness = 4
	flashLight.Range = 14
	flashLight.Shadows = false
	flashLight.Enabled = false
	flashLight.Parent = flashPart
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(function()
			stepTracers()
			stepCasings(math.min(dt, 1 / 20))
			stepHoles()
			stepSmoke(dt)
		end)
		if not ok then
			warn("[WeaponFx] " .. tostring(err))
		end
	end)
	local _ = player
end

return WeaponFx
