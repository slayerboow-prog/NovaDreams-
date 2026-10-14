-- AirCombatFx (cliente): lo que se VE del combate aéreo, grande y de colores, con tope según el nivel
-- gráfico (shared/AirCombat/FxBudget + UI/Perf). Todo es local y se borra solo; no decide nada (los
-- impactos y el daño son de Services/AirCombatService).
--
--   * Láser: trazadoras de neón que brillan (núcleo blanco y halo de color: cian las tuyas, rojo las
--     enemigas) y un fogonazo en la boca del cañón.
--   * Misil: cuerpo brillante con estela de color y humo blanco que se queda; busca a su blanco.
--   * Estallido (un robot o un dron): destello blanco, bola de fuego naranja, onda que se abre, chispas
--     gordas de colores, trozos que salen volando y, en Medio/Alto, un fogonazo de luz de verdad.
--     Derribos de verdad, pero nada de sangre: estallan máquinas.
--   * Restos: trozos chamuscados del casco que arden y echan humo; en la atmósfera caen dando vueltas y
--     se estrellan contra el suelo (otra explosión pequeña); en el espacio se alejan girando.
--   * Escudo: una onda azul alrededor de la nave al parar un disparo (y chispas si da en el casco).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FxBudget = require(ReplicatedStorage.Shared.AirCombat.FxBudget)
local ShipWeapons = require(ReplicatedStorage.Shared.AirCombat.ShipWeapons)
local Arena = require(ReplicatedStorage.Shared.AirCombat.Arena)
local ShipCombat = require(ReplicatedStorage.Shared.AirCombat.ShipCombat)

local AirCombatFx = {}

local COL = FxBudget.Colors
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local folder: Folder? = nil
local function root(): Instance
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "AirCombatFx"
	f.Parent = workspace
	folder = f
	return f
end

-- Nivel gráfico de ahora (UI/Perf lo deja en el atributo GraphicsTier del jugador)
local function tier(): string?
	local attr = Players.LocalPlayer:GetAttribute("GraphicsTier")
	return if type(attr) == "string" then attr else nil
end

local budgetCache: FxBudget.Budget? = nil
local budgetAt = -math.huge
local function budget(): FxBudget.Budget
	if not budgetCache or os.clock() - budgetAt > 2 then
		budgetCache = FxBudget.get(tier())
		budgetAt = os.clock()
	end
	return budgetCache :: FxBudget.Budget
end

local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	pcall(function()
		p.CanQuery = false
	end)
	p.Material = Enum.Material.Neon
	for k, v in props do
		if k ~= "ClassName" then
			(p :: any)[k] = v
		end
	end
	p.Parent = root()
	return p
end

local function later(seconds: number, inst: Instance)
	task.delay(seconds, function()
		if inst.Parent then
			inst:Destroy()
		end
	end)
end

local function tween(obj: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	TweenService:Create(obj, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.LightEmission = 1
	e.Texture = SPARK
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

local function facing(at: Vector3, dir: Vector3): CFrame
	return CFrame.lookAt(at, at + (if dir.Magnitude > 1e-4 then dir.Unit else Vector3.new(0, 0, -1)))
end

---------------------------------------------------------------------
-- Trazadoras del láser
---------------------------------------------------------------------
type Tracer = { Part: BasePart, Glow: BasePart?, Pos: Vector3, Dir: Vector3, Speed: number, Life: number }
local tracers: { Tracer } = {}

function AirCombatFx.tracer(from: Vector3, dir: Vector3, speed: number, life: number, enemy: boolean?)
	local b = budget()
	if #tracers >= b.Tracers then
		local old = table.remove(tracers, 1)
		if old then
			old.Part:Destroy()
			if old.Glow then
				old.Glow:Destroy()
			end
		end
	end
	local unit = dir.Unit
	local core = part({ Name = "Laser", Size = Vector3.new(0.3, 0.3, 12), Color = if enemy then COL.EnemyCore else COL.LaserCore, CFrame = facing(from, unit) })
	local glow = nil
	if b.Trails then
		glow = part({ Name = "LaserHalo", Size = Vector3.new(1, 1, 14), Color = if enemy then COL.Enemy else COL.Laser, Transparency = 0.45, CFrame = facing(from, unit) })
	else
		core.Size = Vector3.new(0.6, 0.6, 12)
		core.Color = if enemy then COL.Enemy else COL.Laser
	end
	table.insert(tracers, { Part = core, Glow = glow, Pos = from, Dir = unit, Speed = speed, Life = life })
end

-- Fogonazo en la boca del cañón
function AirCombatFx.muzzle(at: Vector3, dir: Vector3, enemy: boolean?)
	local f = part({ Name = "Fogonazo", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.2, Color = if enemy then COL.Enemy else COL.Laser, Transparency = 0.15, CFrame = CFrame.new(at + dir.Unit * 1.5) })
	tween(f, 0.09, { Size = Vector3.one * 0.4, Transparency = 1 })
	later(0.12, f)
end

---------------------------------------------------------------------
-- Impactos, estallidos y escudo
---------------------------------------------------------------------
local activeBursts = 0

local function sparks(at: Vector3, n: number, speed: number, size: number, colors: { Color3 }?, lifetime: number?)
	local anchor = part({ Name = "Chispas", Size = Vector3.one * 0.2, Transparency = 1, CFrame = CFrame.new(at) })
	local list = colors or COL.Spark
	local per = math.max(1, math.floor(n / #list))
	for _, c in list do
		local e = emitter(anchor, {
			Color = ColorSequence.new(c, Color3.new(1, 1, 1):Lerp(c, 0.4)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(0.6, size * 0.7), NumberSequenceKeypoint.new(1, 0) }),
			Transparency = seq(0, 1),
			Lifetime = NumberRange.new((lifetime or 0.6) * 0.5, lifetime or 0.6),
			Speed = NumberRange.new(speed * 0.4, speed),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 3,
			RotSpeed = NumberRange.new(-200, 200),
		})
		e:Emit(per)
	end
	later((lifetime or 0.6) + 0.4, anchor)
end

local function ring(at: Vector3, normal: Vector3, color: Color3, from: number, to: number, seconds: number)
	local r = part({ Name = "Onda", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, from, from), Color = color, Transparency = 0.2, CFrame = facing(at, normal) * CFrame.Angles(0, math.rad(90), 0) })
	tween(r, seconds, { Size = Vector3.new(0.1, to, to), Transparency = 1 })
	later(seconds + 0.05, r)
end

local function ball(at: Vector3, color: Color3, from: number, to: number, seconds: number, transparency: number?, material: Enum.Material?)
	local s = part({ Name = "Destello", Shape = Enum.PartType.Ball, Size = Vector3.one * from, Color = color, Transparency = transparency or 0.1, CFrame = CFrame.new(at) })
	if material then
		s.Material = material
	end
	tween(s, seconds, { Size = Vector3.one * to, Transparency = 1 })
	later(seconds + 0.05, s)
	return s
end

local function lightFlash(at: Vector3, color: Color3, range: number, seconds: number)
	local anchor = part({ Name = "Luz", Size = Vector3.one * 0.2, Transparency = 1, CFrame = CFrame.new(at) })
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 6
	light.Shadows = false
	light.Parent = anchor
	tween(light, seconds, { Brightness = 0 })
	later(seconds + 0.05, anchor)
end

-- Impacto pequeño (le has dado; o un disparo contra una roca)
function AirCombatFx.hit(at: Vector3, dir: Vector3?, color: Color3?, big: boolean?)
	local c = color or COL.Laser
	ball(at, Color3.new(1, 1, 1), 1, if big then 7 else 4, 0.12, 0)
	ball(at, c, 2, if big then 10 else 6, 0.2, 0.35)
	sparks(at, if big then 12 else 6, 45, if big then 1.4 else 0.9, { c, COL.Spark[1] }, 0.4)
	if dir then
		ring(at, dir, c, 1, if big then 12 else 7, 0.2)
	end
end

-- Estallido de una máquina (dron, caza, torreta o la nave). size 0..1
function AirCombatFx.burst(at: Vector3, size: number?, look: Vector3?)
	local b = budget()
	local s = math.clamp(size or 0.6, 0.2, 1)
	local r = 8 + 22 * s
	if activeBursts >= b.Bursts then
		-- (demasiados a la vez: solo el destello)
		ball(at, COL.BoomCore, 2, r, 0.3, 0)
		return
	end
	activeBursts += 1
	task.delay(1.2, function()
		activeBursts -= 1
	end)
	-- Destello blanco, bola de fuego naranja y halo rojo oscuro: tres capas que se abren a distinto ritmo
	ball(at, COL.BoomCore, 2, r * 0.9, 0.18, 0)
	ball(at, COL.BoomGlow, 3, r * 1.5, 0.45, 0.2)
	ball(at, COL.Spark[4], 4, r * 2.1, 0.6, 0.6)
	ring(at, look or Vector3.new(0, 1, 0), COL.BoomRing, 2, r * 3, 0.4)
	ring(at, Vector3.new(0, 1, 0), COL.Spark[3], 2, r * 2.4, 0.5)
	sparks(at, FxBudget.sparks(tier(), s), 70 + 60 * s, 1.6 + 1.6 * s, nil, 0.9)
	-- Bola de fuego con textura (sube un poco) y humo que se queda
	local anchor = part({ Name = "Fuego", Size = Vector3.one * 0.2, Transparency = 1, CFrame = CFrame.new(at) })
	emitter(anchor, {
		Texture = FIRE,
		Color = ColorSequence.new(COL.BoomCore, COL.BoomGlow),
		Size = seq(r * 0.5, r * 0.9),
		Transparency = seq(0.1, 1),
		Lifetime = NumberRange.new(0.35, 0.6),
		Speed = NumberRange.new(6, 18),
		SpreadAngle = Vector2.new(180, 180),
	}):Emit(math.max(3, math.floor(b.Sparks / 6)))
	emitter(anchor, {
		Texture = SMOKE,
		LightEmission = 0,
		Color = ColorSequence.new(Color3.fromRGB(120, 110, 105)),
		Size = seq(r * 0.4, r * 1.2),
		Transparency = seq(0.35, 1),
		Lifetime = NumberRange.new(1, 1.8),
		Speed = NumberRange.new(4, 10),
		SpreadAngle = Vector2.new(180, 180),
	}):Emit(math.max(2, math.floor(b.Sparks / 8)))
	later(2.2, anchor)
	-- Trozos de metal brillante que salen volando y se apagan
	for i = 1, b.Debris do
		local dir = Vector3.new(math.random() - 0.5, math.random() - 0.3, math.random() - 0.5)
		dir = if dir.Magnitude > 0.05 then dir.Unit else Vector3.new(0, 1, 0)
		local chunk = part({
			Name = "Trozo",
			Size = Vector3.new(0.8, 0.8, 0.8) * (0.8 + math.random() * (1 + s)),
			Color = COL.Spark[(i - 1) % #COL.Spark + 1],
			CFrame = CFrame.new(at) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
		})
		local travel = r * (1.2 + math.random())
		tween(chunk, 0.9, { CFrame = CFrame.new(at + dir * travel) * CFrame.Angles(math.random() * 9, math.random() * 9, 0), Size = Vector3.one * 0.1, Transparency = 0.8 })
		later(0.95, chunk)
	end
	if b.Lights then
		lightFlash(at, COL.BoomGlow, r * 4, 0.5)
	end
end

-- Onda del escudo alrededor de la nave (el escudo ha parado un disparo que venía de `from`)
function AirCombatFx.shield(ship: BasePart, from: Vector3?, broke: boolean?)
	local at = ship.Position
	local bubble = part({ Name = "Escudo", Shape = Enum.PartType.Ball, Size = Vector3.one * 20, Color = COL.Shield, Material = Enum.Material.ForceField, Transparency = 0, CFrame = CFrame.new(at) })
	local weld = Instance.new("WeldConstraint")
	bubble.Anchored = false
	bubble.Massless = true
	weld.Part0 = ship
	weld.Part1 = bubble
	weld.Parent = bubble
	tween(bubble, if broke then 0.6 else 0.35, { Size = Vector3.one * (if broke then 30 else 23), Transparency = 1 })
	later(0.65, bubble)
	if from then
		local dir = (from - at)
		if dir.Magnitude > 1 then
			local p = at + dir.Unit * 10
			ring(p, dir, COL.Shield, 2, 12, 0.3)
			sparks(p, 6, 30, 0.8, { COL.Shield, Color3.new(1, 1, 1) }, 0.35)
		end
	end
	if broke then
		sparks(at, 18, 60, 1.2, { COL.Shield, Color3.new(1, 1, 1) }, 0.6)
	end
end

---------------------------------------------------------------------
-- Misiles
---------------------------------------------------------------------
type MissileFx = { Part: BasePart, Pos: Vector3, Dir: Vector3, Speed: number, Target: () -> Vector3?, Life: number }
local missiles: { [string]: MissileFx } = {}
local missileCount = 0

-- enemy: (Espacio AAA) misil de un caza enemigo: rojo y con su velocidad (shared/AirCombat/ShipCombat)
function AirCombatFx.missile(id: string, from: Vector3, dir: Vector3, target: () -> Vector3?, enemy: boolean?)
	local b = budget()
	if missileCount >= b.Missiles then
		return
	end
	missileCount += 1
	local body = part({ Name = "Misil", Size = Vector3.new(0.9, 0.9, 3.2), Color = if enemy then COL.Enemy else COL.Missile, CFrame = facing(from, dir) })
	local tail = Instance.new("Attachment")
	tail.Position = Vector3.new(0, 0, 1.6)
	tail.Parent = body
	if b.Trails then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.5, 1.6)
		a0.Parent = body
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.5, 1.6)
		a1.Parent = body
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(COL.BoomCore, COL.Missile)
		trail.LightEmission = 1
		trail.Lifetime = 0.35
		trail.Transparency = seq(0, 1)
		trail.WidthScale = seq(1.4, 0.2)
		trail.FaceCamera = true
		trail.Parent = body
	end
	emitter(tail, {
		Texture = SMOKE,
		LightEmission = 0,
		Color = ColorSequence.new(COL.Smoke),
		Size = seq(1.2, 4.5),
		Transparency = seq(0.25, 1),
		Lifetime = NumberRange.new(0.9, 1.6),
		Speed = NumberRange.new(0, 2),
		Rate = b.Smoke,
	})
	emitter(tail, {
		Texture = FIRE,
		Color = ColorSequence.new(COL.BoomCore, COL.Missile),
		Size = seq(1.4, 0.2),
		Transparency = seq(0, 1),
		Lifetime = NumberRange.new(0.08, 0.15),
		Speed = NumberRange.new(4, 8),
		EmissionDirection = Enum.NormalId.Back,
		Rate = 40,
	})
	missiles[id] = { Part = body, Pos = from, Dir = dir.Unit, Speed = 120, Target = target, Life = (if enemy then ShipCombat.EnemyMissile.Life else ShipWeapons.Missile.Life) + 0.5, Enemy = enemy }
end

local function dropMissile(id: string)
	local m = missiles[id]
	if not m then
		return
	end
	missiles[id] = nil
	missileCount -= 1
	-- (el humo se queda un momento flotando)
	for _, d in m.Part:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.Rate = 0
		elseif d:IsA("Trail") then
			d.Enabled = false
		end
	end
	m.Part.Transparency = 1
	later(1.8, m.Part)
end

function AirCombatFx.boom(id: string, at: Vector3, hit: boolean)
	dropMissile(id)
	if hit then
		AirCombatFx.burst(at, 0.45)
	else
		AirCombatFx.hit(at, nil, COL.Missile, true)
	end
end

---------------------------------------------------------------------
-- Restos en llamas que caen
---------------------------------------------------------------------
type Wreck = { Part: BasePart, Fire: { ParticleEmitter }, Pos: Vector3, Vel: Vector3, Spin: Vector3, Rot: CFrame, Life: number, Space: boolean, Landed: boolean }
local wrecks: { Wreck } = {}

-- Trozos grandes del casco, chamuscados, ardiendo y echando humo: en la atmósfera caen dando vueltas
-- y se estrellan contra el suelo o las rocas (otra pequeña explosión); en el espacio se alejan girando.
-- vel = velocidad que llevaba la máquina (los restos siguen un poco su camino). size 0..1
function AirCombatFx.wreck(at: Vector3, vel: Vector3?, size: number?)
	local b = budget()
	local s = math.clamp(size or 0.6, 0.2, 1)
	local space = Arena.modeAt(at) == "Space"
	local count = math.max(1, math.floor(b.Wrecks * (0.5 + s * 0.5) + 0.5))
	for i = 1, count do
		if #wrecks >= b.WreckMax then
			local old = table.remove(wrecks, 1)
			if old then
				old.Part:Destroy()
			end
		end
		local chunk = Vector3.new(1.5 + math.random() * 2.5, 0.6 + math.random() * 1.2, 1.5 + math.random() * 3) * (0.7 + s * 0.6)
		local p = part({
			Name = "Restos",
			ClassName = if i % 2 == 0 then "WedgePart" else "Part",
			Size = chunk,
			Material = Enum.Material.CorrodedMetal,
			Color = Color3.fromRGB(46, 42, 40):Lerp(Color3.fromRGB(80, 60, 50), math.random()),
			CFrame = CFrame.new(at),
		})
		local fireEmit = {}
		local a0 = Instance.new("Attachment")
		a0.Parent = p
		table.insert(fireEmit, emitter(a0, {
			Texture = FIRE,
			Color = ColorSequence.new(COL.BoomCore, COL.BoomGlow),
			Size = seq(chunk.Magnitude * 0.6, 0.3),
			Transparency = seq(0.05, 1),
			Lifetime = NumberRange.new(0.25, 0.45),
			Speed = NumberRange.new(1, 4),
			SpreadAngle = Vector2.new(25, 25),
			Rate = b.WreckFire,
		}))
		table.insert(fireEmit, emitter(a0, {
			Texture = SMOKE,
			LightEmission = 0,
			Color = ColorSequence.new(Color3.fromRGB(70, 64, 60), Color3.fromRGB(30, 28, 28)),
			Size = seq(chunk.Magnitude * 0.5, chunk.Magnitude * 2.2),
			Transparency = seq(0.3, 1),
			Lifetime = NumberRange.new(1.2, 2.2),
			Speed = NumberRange.new(0.5, 2),
			Rate = b.Smoke * 0.6,
		}))
		local out = Vector3.new(math.random() - 0.5, math.random() * 0.8 - 0.1, math.random() - 0.5)
		out = if out.Magnitude > 0.05 then out.Unit else Vector3.new(0, 1, 0)
		table.insert(wrecks, {
			Part = p,
			Fire = fireEmit,
			Pos = at,
			Vel = (vel or Vector3.zero) * 0.35 + out * (25 + math.random() * 35),
			Spin = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 8,
			Rot = CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
			Life = if space then 5 else 8,
			Space = space,
			Landed = false,
		})
	end
end

local function stepWrecks(dt: number)
	for i = #wrecks, 1, -1 do
		local w = wrecks[i]
		w.Life -= dt
		if not w.Landed then
			if w.Space then
				w.Vel *= math.exp(-0.15 * dt)
			else
				w.Vel += Vector3.new(0, -70 * dt, 0)
				w.Vel *= math.exp(-0.25 * dt)
			end
			w.Pos += w.Vel * dt
			w.Rot = w.Rot * CFrame.Angles(w.Spin.X * dt, w.Spin.Y * dt, w.Spin.Z * dt)
			if not w.Space and Arena.collide(w.Pos, 1) then
				-- Se estrella: pequeña explosión, deja de arder poco a poco y se queda humeando
				w.Landed = true
				w.Life = math.min(w.Life, 3)
				ball(w.Pos, COL.BoomGlow, 2, 9, 0.3, 0.15)
				sparks(w.Pos, 8, 40, 1.2, { COL.Spark[1], COL.Spark[2] }, 0.5)
				for _, e in w.Fire do
					e.Rate *= 0.4
				end
			end
		end
		w.Part.CFrame = CFrame.new(w.Pos) * w.Rot
		if w.Life <= 0 then
			for _, e in w.Fire do
				e.Rate = 0
			end
			tween(w.Part, 0.6, { Transparency = 1 })
			later(2.5, w.Part)
			table.remove(wrecks, i)
		end
	end
end

function AirCombatFx.clearWrecks()
	for _, w in wrecks do
		w.Part:Destroy()
	end
	table.clear(wrecks)
end

---------------------------------------------------------------------
-- Cada fotograma
---------------------------------------------------------------------
function AirCombatFx.step(dt: number)
	for i = #tracers, 1, -1 do
		local t = tracers[i]
		local from = t.Pos
		t.Pos = from + t.Dir * t.Speed * dt
		t.Life -= dt
		if t.Life <= 0 or Arena.segmentBlocked(from, t.Pos) then
			if t.Life > 0 then
				AirCombatFx.hit(t.Pos, -t.Dir, t.Part.Color)
			end
			t.Part:Destroy()
			if t.Glow then
				t.Glow:Destroy()
			end
			table.remove(tracers, i)
		else
			local cf = facing(t.Pos, t.Dir)
			t.Part.CFrame = cf
			if t.Glow then
				t.Glow.CFrame = cf
			end
		end
	end
	for id, m in missiles do
		local target = m.Target()
		if (m :: any).Enemy then
			ShipCombat.steer(m :: any, target or (m.Pos + m.Dir * 100), dt)
		else
			ShipWeapons.steerMissile(m :: any, target, dt)
		end
		m.Life -= dt
		m.Part.CFrame = facing(m.Pos, m.Dir)
		if m.Life <= 0 then
			dropMissile(id)
		end
	end
	stepWrecks(dt)
end

function AirCombatFx.clear()
	for _, t in tracers do
		t.Part:Destroy()
		if t.Glow then
			t.Glow:Destroy()
		end
	end
	table.clear(tracers)
	for id in table.clone(missiles) do
		dropMissile(id)
	end
	AirCombatFx.clearWrecks()
	pcall(AirCombatFx.hyperStep, CFrame.new(), 0, 0)
	pcall(AirCombatFx.portalStep, nil, 0, 0)
	pcall(AirCombatFx.distort, 0)
end

---------------------------------------------------------------------
-- La nave (shared/AirCombat/ShipModel): motores que brillan según el motor, luces de navegación que
-- parpadean, estelas y luces de verdad según el nivel gráfico. Solo en esta pantalla.
---------------------------------------------------------------------
type ShipLook = { Exhaust: { BasePart }, Flames: { BasePart }, Strobe: BasePart?, Tier: string?, T: number }
local looks: { [Model]: ShipLook } = {}

local function setupShip(ship: Model): ShipLook
	local look = looks[ship]
	-- (si la nave ha cambiado de piezas a malla —ShipModel.upgrade—, se vuelve a mirar)
	if look and look.Tier == tier() and (look.Exhaust[1] == nil or look.Exhaust[1].Parent == ship) then
		return look
	end
	local fresh: ShipLook = { Exhaust = {}, Flames = {}, Strobe = nil, Tier = tier(), T = if look then look.T else 0 }
	local b = budget()
	for _, d in ship:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Escape" then
				table.insert(fresh.Exhaust, d)
			elseif d.Name == "Llama" then
				table.insert(fresh.Flames, d)
			elseif d.Name == "LuzCola" then
				fresh.Strobe = d
			end
		elseif d:IsA("Trail") then
			d.Enabled = b.ShipTrails
		elseif d:IsA("PointLight") then
			d.Enabled = b.Lights
		end
	end
	looks[ship] = fresh
	return fresh
end

-- Cada fotograma: throttle 0..1, boosting (turbo), down (derribada: todo apagado), glow 0..1 (Espacio
-- AAA: preparando o en hipervelocidad, o cargando el salto: los motores al rojo blanco azulado)
function AirCombatFx.shipStep(ship: Model, throttle: number, boosting: boolean, down: boolean, dt: number, glow: number?)
	if not ship.Parent then
		looks[ship] = nil
		return
	end
	local look = setupShip(ship)
	look.T += dt
	local g = math.clamp(glow or 0, 0, 1)
	local power = if down then 0 else math.clamp(0.35 + throttle * 0.5 + (if boosting then 0.4 else 0) + g * 0.6, 0, 1.4)
	local flicker = 0.92 + 0.08 * math.sin(look.T * (37 + g * 30))
	local hot = if boosting or g > 0.3 then Color3.fromRGB(235, 250, 255) else COL.Laser
	for _, p in look.Exhaust do
		p.Color = Color3.fromRGB(40, 70, 90):Lerp(hot, math.clamp(power * flicker, 0, 1))
	end
	for _, p in look.Flames do
		p.Transparency = if down then 1 else math.clamp(0.95 - power * 0.6 * flicker, 0.12, 1)
		p.Color = if boosting or g > 0.3 then Color3.fromRGB(200, 240, 255) else COL.Laser
	end
	local strobe = look.Strobe
	if strobe then
		strobe.Transparency = if not down and (look.T % 1.3) < 0.12 then 0 else 0.85
	end
end

function AirCombatFx.forgetShip(ship: Model)
	looks[ship] = nil
end

function AirCombatFx.counts(): (number, number, number)
	return #tracers, missileCount, #wrecks
end

---------------------------------------------------------------------
-- Espacio AAA: esquiva, hipervelocidad y salto cuántico (con tope según el nivel gráfico)
---------------------------------------------------------------------
-- Esquiva: tres «fantasmas» de la nave que se quedan atrás y se apagan (la estela del salto lateral)
function AirCombatFx.dodge(from: CFrame, to: Vector3)
	for i = 0, 2 do
		local at = from.Position:Lerp(to, i / 3)
		local ghost = part({ Name = "EsquivaEstela", Size = Vector3.new(12, 1.6, 14), Color = COL.Laser, Transparency = 0.35 + i * 0.15, CFrame = CFrame.new(at) * (from - from.Position) })
		tween(ghost, 0.35, { Transparency = 1, Size = Vector3.new(16, 0.4, 18) })
		later(0.4, ghost)
	end
end

-- Hipervelocidad: rayas de luz alrededor de la cámara que pasan a toda velocidad (k 0..1)
local streaks: { { Part: BasePart, Off: Vector3 } } = {}
function AirCombatFx.hyperStep(camera: CFrame, k: number, dt: number)
	local b = budget()
	local want = if k <= 0.01 then 0 else (if b.Trails then (if b.Lights then 36 else 22) else 12)
	while #streaks > want do
		local s = table.remove(streaks)
		if s then
			s.Part:Destroy()
		end
	end
	local rng = Random.new()
	while #streaks < want do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(14, 45)
		local p = part({ Name = "Hiperraya", Size = Vector3.new(0.18, 0.18, 30), Color = Color3.fromRGB(190, 235, 255), Transparency = 1 })
		table.insert(streaks, { Part = p, Off = Vector3.new(math.cos(a) * r, math.sin(a) * r, -rng:NextNumber(20, 320)) })
	end
	for _, s in streaks do
		local off = s.Off + Vector3.new(0, 0, 900 * k * dt)
		if off.Z > 5 then
			off = Vector3.new(off.X, off.Y, -320)
		end
		s.Off = off
		s.Part.Size = Vector3.new(0.18, 0.18, 10 + 50 * k)
		s.Part.Transparency = 1 - 0.75 * k
		s.Part.CFrame = camera * CFrame.new(off)
	end
end

-- Salto cuántico: el portal delante de la nave mientras carga (k 0..1); nil para quitarlo
local portal: { Ring: { BasePart }, Disk: BasePart, T: number }? = nil
function AirCombatFx.portalStep(at: CFrame?, k: number, dt: number)
	if not at then
		if portal then
			for _, p in portal.Ring do
				p:Destroy()
			end
			portal.Disk:Destroy()
			portal = nil
		end
		return
	end
	if not portal then
		local b = budget()
		local ring = {}
		local n = if b.Lights then 18 else 10
		for _ = 1, n do
			table.insert(ring, part({ Name = "PortalLuz", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.4, Color = Color3.fromRGB(200, 130, 255) }))
		end
		local disk = part({ Name = "Portal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 1, 1), Color = Color3.fromRGB(120, 80, 255), Material = Enum.Material.ForceField, Transparency = 0.2 })
		portal = { Ring = ring, Disk = disk, T = 0 }
	end
	local pp = portal :: any
	pp.T += dt
	local radius = 6 + 34 * k
	local center = at * CFrame.new(0, 0, -(70 - 30 * k))
	for i, p in pp.Ring do
		local a = (i / #pp.Ring) * math.pi * 2 + pp.T * (1.5 + 4 * k)
		p.CFrame = center * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)
	end
	pp.Disk.Size = Vector3.new(0.5, radius * 2, radius * 2)
	pp.Disk.CFrame = center * CFrame.Angles(0, math.rad(90), 0)
end

-- Bengalas: chispas muy brillantes que caen hacia atrás (los misiles se van detrás)
function AirCombatFx.flares(at: Vector3, back: Vector3)
	local b = budget()
	local n = if b.Lights then 8 else 5
	local rng = Random.new()
	for i = 1, n do
		local dir = (back + Vector3.new(rng:NextNumber(-0.6, 0.6), rng:NextNumber(-0.8, 0.1), rng:NextNumber(-0.6, 0.6))).Unit
		local f = part({ Name = "Bengala", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, Color = Color3.fromRGB(255, 235, 170), CFrame = CFrame.new(at + dir * 4) })
		tween(f, 1.6, { CFrame = CFrame.new(at + dir * (60 + i * 6)), Transparency = 1, Size = Vector3.one * 0.4 }, Enum.EasingStyle.Quad)
		later(1.7, f)
		if i == 1 and b.Lights then
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 200, 120)
			light.Range = 30
			light.Brightness = 3
			light.Parent = f
		end
	end
end

-- Pulso del escáner (modo exploración): un aro de luz que se abre
function AirCombatFx.scanPing(at: Vector3, radius: number)
	local ring = part({ Name = "Escaner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 20, 20), Color = Color3.fromRGB(120, 220, 255), Material = Enum.Material.ForceField, Transparency = 0.2, CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)) })
	local d = math.min(radius, 1800) * 2
	tween(ring, 1.4, { Size = Vector3.new(0.4, d, d), Transparency = 1 })
	later(1.5, ring)
end

-- Camuflaje y sobrecarga de cualquier nave (la tuya y las de los demás): según los atributos que pone
-- el servidor en la nave («Cloak», «Overload»). Transparencia local poco a poco y una burbuja.
local cloakSeen: { [Model]: number } = {}
local bubbles: { [Model]: BasePart } = {}
function AirCombatFx.shipStates(own: Model?)
	local now = os.clock()
	for _, m in workspace:GetChildren() do
		if m:IsA("Model") and string.sub(m.Name, 1, 5) == "Nave_" then
			local cloaked = m:GetAttribute("Cloak") ~= nil
			if cloaked and not cloakSeen[m] then
				cloakSeen[m] = now
			elseif not cloaked and cloakSeen[m] then
				cloakSeen[m] = nil
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						d.LocalTransparencyModifier = 0
					end
				end
			end
			local since = cloakSeen[m]
			if since then
				local alpha = ShipCombat.cloakAlpha(now - since, m == own)
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						d.LocalTransparencyModifier = alpha
					elseif d:IsA("Trail") or d:IsA("PointLight") then
						d.Enabled = alpha < 0.5
					end
				end
			end
			local over = m:GetAttribute("Overload") == true
			local bubble = bubbles[m]
			if over and not bubble and m.PrimaryPart then
				local p = part({ Name = "Sobrecarga", Shape = Enum.PartType.Ball, Size = Vector3.one * 26, Color = Color3.fromRGB(120, 210, 255), Material = Enum.Material.ForceField, Transparency = 0.1, CFrame = m.PrimaryPart.CFrame })
				bubbles[m] = p
			elseif bubble and (not over or not m.Parent) then
				bubble:Destroy()
				bubbles[m] = nil
			elseif bubble and m.PrimaryPart then
				bubble.CFrame = m.PrimaryPart.CFrame
			end
		end
	end
	for m, b in bubbles do
		if not m.Parent then
			b:Destroy()
			bubbles[m] = nil
		end
	end
	for m in cloakSeen do
		if not m.Parent then
			cloakSeen[m] = nil
		end
	end
end

-- Distorsión de la imagen (hipervelocidad y salto): desenfoque y tono, con efectos nativos de la
-- cámara; en gráficos Bajo, solo el tono. k 0..1 (0 = quitarlo)
local blur: BlurEffect? = nil
local tint: ColorCorrectionEffect? = nil
function AirCombatFx.distort(k: number, color: Color3?)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if k <= 0.01 then
		if blur then
			blur.Size = 0
		end
		if tint then
			tint.Saturation, tint.Contrast, tint.TintColor = 0, 0, Color3.new(1, 1, 1)
		end
		return
	end
	if budget().Lights then
		if not blur or not blur.Parent then
			blur = Instance.new("BlurEffect")
			blur.Name = "NaveDistorsion"
			blur.Parent = camera
		end
		;(blur :: BlurEffect).Size = 10 * k
	end
	if not tint or not tint.Parent then
		tint = Instance.new("ColorCorrectionEffect")
		tint.Name = "NaveTono"
		tint.Parent = camera
	end
	local c = color or Color3.fromRGB(190, 220, 255)
	;(tint :: ColorCorrectionEffect).TintColor = Color3.new(1, 1, 1):Lerp(c, 0.5 * k)
	;(tint :: ColorCorrectionEffect).Contrast = 0.2 * k
	;(tint :: ColorCorrectionEffect).Saturation = -0.2 * k
end

-- Al activar el camuflaje: un brillo que se deshace alrededor de la nave
function AirCombatFx.cloakShimmer(ship: BasePart)
	local p = part({ Name = "Camuflaje", Shape = Enum.PartType.Ball, Size = Vector3.one * 24, Color = Color3.fromRGB(170, 220, 255), Material = Enum.Material.Glass, Transparency = 0.55, CFrame = ship.CFrame })
	tween(p, 0.8, { Size = Vector3.one * 32, Transparency = 1 })
	later(0.9, p)
end

-- Salida del salto (o la entrada, al desaparecer): un destello violeta que se abre
function AirCombatFx.portalBurst(at: Vector3)
	local f = part({ Name = "SaltoDestello", Shape = Enum.PartType.Ball, Size = Vector3.one * 8, Color = Color3.fromRGB(220, 170, 255), Transparency = 0.1, CFrame = CFrame.new(at) })
	tween(f, 0.6, { Size = Vector3.one * 90, Transparency = 1 })
	later(0.7, f)
	if budget().Lights then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(200, 140, 255)
		light.Range = 60
		light.Brightness = 4
		light.Parent = f
	end
end

return AirCombatFx
