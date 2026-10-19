-- AsteroidFx (cliente): lo que se ve de los asteroides que se rompen (docs/espacio-aaa/asteroides.md).
--
--   * Estado: copia el registro de shared/Cosmos/Asteroids de ReplicatedStorage.AsteroidesEstado (lo
--     escribe el servidor: SpaceService). Con eso la nave choca con los trozos (Zone) y aquí se ven.
--   * Trozos: cada trozo es una roca más pequeña (shared/Cosmos/AsteroidBuild, la misma forma en todos
--     los clientes) que sale volando con su impulso y su giro y se frena (Asteroids.posAt/rotAt); al
--     caducar se desvanece.
--   * Romperse: fogonazo, nube de polvo, chispas y pedazos de roca con física sencilla (sin gravedad: es
--     el espacio), un temblor de cámara pequeño si estás cerca y el ruido. Al minar, saltan lascas.
--   * Para el móvil: como mucho Asteroids.DebrisMax pedazos a la vez (los más viejos se quitan antes),
--     solo giran los asteroides cercanos (TumbleMax, a 30 Hz), de lejos sin detalles (LodFar) y nada
--     de esto corre si no estás en el espacio.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cosmos = ReplicatedStorage.Shared.Cosmos
local Asteroids = require(Cosmos.Asteroids)
local AsteroidBuild = require(Cosmos.AsteroidBuild)
local Layers = require(Cosmos.Layers)
local Zone = require(Cosmos.Zone)
local Mining = require(Cosmos.Mining)

local AsteroidFx = {}

local rgb = Color3.fromRGB

type Debris = { Part: BasePart, Vel: Vector3, Axis: Vector3, W: number, Life: number, Age: number, Fade: number }
type Visual = { Model: Model, Frag: Asteroids.Fragment, Settled: boolean }

local pool = Asteroids.newPool()
local visuals: { [string]: Visual } = {}
local known: { [string]: { [string]: Asteroids.Fragment } } = {} -- trozos de cada familia que ya se ven
local folder: Folder? = nil
local tumbling: { { Model: Model, Center: Vector3, Pivot: CFrame, Axis: Vector3, W: number } } = {}
local lodState: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local scanAt = 0
local tumbleAcc = 0
local inSpace = false

local function fxFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "AsteroidesLocales"
	f.Parent = workspace
	folder = f
	return f
end

local function camPos(): Vector3?
	local ok, pos = pcall(function()
		local cam = workspace.CurrentCamera
		return if cam then cam.CFrame.Position else nil
	end)
	return if ok then pos else nil
end

local function lazy(name: string): any
	local ok, m = pcall(function()
		return require(script.Parent:FindFirstChild(name) :: any)
	end)
	return if ok then m else nil
end

---------------------------------------------------------------------
-- Pedazos sueltos (adorno): física sencilla y tope
---------------------------------------------------------------------
local function removeDebris(d: Debris)
	if d.Part then
		d.Part:Destroy()
	end
end

-- Un pedazo de roca que sale despedido (vel: studs/s)
function AsteroidFx.chunk(at: Vector3, vel: Vector3, size: number, color: Color3, glow: boolean?): BasePart
	local r = Random.new()
	local p = Instance.new(if r:NextNumber() < 0.5 then "Part" else "CornerWedgePart") :: BasePart
	p.Name = "Lasca"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = Vector3.new(size * r:NextNumber(0.7, 1.3), size * r:NextNumber(0.5, 1), size * r:NextNumber(0.6, 1.2))
	p.Color = color
	p.Material = if glow then Enum.Material.Neon else Enum.Material.Slate
	p.CFrame = CFrame.new(at) * CFrame.Angles(r:NextNumber(0, 6.28), r:NextNumber(0, 6.28), r:NextNumber(0, 6.28))
	p.Parent = fxFolder()
	local axis = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-1, 1), r:NextNumber(-1, 1))
	local d: Debris = {
		Part = p, Vel = vel, Axis = if axis.Magnitude > 1e-3 then axis.Unit else Vector3.new(0, 1, 0),
		W = r:NextNumber(1.5, 6), Life = r:NextNumber(Asteroids.DebrisLife[1], Asteroids.DebrisLife[2]), Age = 0, Fade = 0.9,
	}
	for _, old in Asteroids.poolAdd(pool, d) do
		removeDebris(old)
	end
	return p
end

function AsteroidFx.debrisCount(): number
	return #pool.List
end

local function stepDebris(dt: number)
	local list = pool.List
	local drag = math.exp(-0.35 * dt)
	for i = #list, 1, -1 do
		local d = list[i]
		d.Age += dt
		if d.Age >= d.Life or not d.Part.Parent then
			removeDebris(d)
			table.remove(list, i)
		else
			d.Vel *= drag
			local cf = d.Part.CFrame
			d.Part.CFrame = CFrame.new(cf.Position + d.Vel * dt) * CFrame.fromAxisAngle(d.Axis, d.W * dt) * (cf - cf.Position)
			local left = d.Life - d.Age
			if left < d.Fade then
				d.Part.Transparency = 1 - left / d.Fade
			end
		end
	end
end

---------------------------------------------------------------------
-- Polvo, chispas y fogonazo
---------------------------------------------------------------------
local function burst(at: Vector3, radius: number, color: Color3, big: boolean)
	local holder = Instance.new("Part")
	holder.Name = "Polvo"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = CFrame.new(at)
	holder.Parent = fxFolder()
	local dust = Instance.new("ParticleEmitter")
	dust.Rate = 0
	dust.Lifetime = NumberRange.new(1.6, 3.2)
	dust.Speed = NumberRange.new(radius * 0.4, radius * 1.1)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Drag = 1.6
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, radius * 0.25), NumberSequenceKeypoint.new(1, radius * 0.8) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	dust.Color = ColorSequence.new(color)
	dust.RotSpeed = NumberRange.new(-30, 30)
	dust.Rotation = NumberRange.new(0, 360)
	dust.LightInfluence = 1
	dust.Parent = holder
	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate = 0
	sparks.Lifetime = NumberRange.new(0.3, 0.8)
	sparks.Speed = NumberRange.new(radius * 1.5, radius * 3.5)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 2
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, math.clamp(radius * 0.05, 0.3, 2)), NumberSequenceKeypoint.new(1, 0) })
	sparks.Color = ColorSequence.new(rgb(255, 210, 140), Asteroids.CrackColor)
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Parent = holder
	pcall(function()
		dust:Emit(if big then 22 else 6)
		sparks:Emit(if big then 40 else 10)
	end)
	task.delay(4, function()
		holder:Destroy()
	end)
	local fx = lazy("AirCombatFx")
	if fx and big then
		pcall(fx.hit, at, nil, Asteroids.CrackColor, true)
	end
end

-- Se rompe algo en at (radio del que se rompe): polvo, chispas, pedazos, temblor y ruido
function AsteroidFx.shatter(at: Vector3, radius: number, color: Color3, push: Vector3?)
	local cam = camPos()
	local dist = if cam then (cam - at).Magnitude else 0
	burst(at, math.clamp(radius, 4, 40), color, true)
	local n = math.clamp(math.floor(radius / 3), 4, 14)
	local r = Random.new()
	for _ = 1, n do
		local dir = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-1, 1), r:NextNumber(-1, 1))
		dir = if dir.Magnitude > 1e-3 then dir.Unit else Vector3.new(0, 1, 0)
		local speed = r:NextNumber(25, 70)
		AsteroidFx.chunk(at + dir * radius * 0.5, dir * speed + (push or Vector3.zero) * 0.3, math.clamp(radius * r:NextNumber(0.06, 0.16), 0.8, 7), color, r:NextNumber() < 0.15)
	end
	if dist < 600 then
		local shake = lazy("CameraShake")
		if shake then
			pcall(shake.shake, math.clamp((1 - dist / 600) * (0.25 + radius / 80), 0.08, 0.9), 0.45)
		end
	end
	local sfx = lazy("SoundFx")
	if sfx and dist < 900 then
		pcall(sfx.play, "NaveEstallido", { Volume = math.clamp(0.7 - dist / 1400, 0.15, 0.7), Pitch = math.clamp(0.9 - radius / 120, 0.45, 0.85) })
	end
end

---------------------------------------------------------------------
-- Trozos (las rocas pequeñas que salen al romperse)
---------------------------------------------------------------------
local function meshes(): Instance?
	return ReplicatedStorage:FindFirstChild("AsteroideMallas")
end

local function buildVisual(f: Asteroids.Fragment, t: number): Visual
	local cf = CFrame.new(Asteroids.posAt(f, t)) * Asteroids.rotAt(f, t)
	local model = AsteroidBuild.make(f.Id, f.Radius, f.Ore, f.Field, cf, { Meshes = meshes(), Shadows = false })
	model.Name = "Trozo"
	model:SetAttribute("FragId", f.Id)
	model.Parent = fxFolder()
	return { Model = model, Frag = f, Settled = false }
end

local function fadeAndDrop(v: Visual)
	local m = v.Model
	task.spawn(function()
		for i = 1, 10 do
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = i / 10
				end
			end
			task.wait(0.06)
		end
		m:Destroy()
	end)
end

local function parentOf(id: string): string
	return (string.match(id, "^(.*)~%d+$") or id)
end

local function colorOf(field: string?): Color3
	local pal = Asteroids.Palettes[field or ""] or Asteroids.Palettes.Hierro
	return pal.Base
end

-- Un atributo del estado ha cambiado: se copia al registro y se ve lo nuevo (quiet: al entrar, lo que ya
-- estaba roto se pone sin efectos)
function AsteroidFx.apply(root: string, text: any, quiet: boolean?)
	local t = Asteroids.clock()
	local fam = Asteroids.decode(root, text)
	Asteroids.setFamily(root, fam)
	local before = known[root] or {}
	local now: { [string]: Asteroids.Fragment } = if fam then fam.Frags else {}
	-- Lo que se ha roto ahora (el asteroide entero o un trozo que ya no está y tiene hijos)
	local broke: { [string]: boolean } = {}
	for id, f in now do
		if not before[id] then
			local parent = parentOf(id)
			if not broke[parent] then
				broke[parent] = true
				local at, radius, push = nil, f.Radius * 2, nil
				local rock = Zone.rock(parent)
				if rock then
					at, radius = rock.Center, rock.Radius
				elseif before[parent] then
					at = Asteroids.posAt(before[parent], t)
					radius = before[parent].Radius
				end
				if at and not quiet then
					AsteroidFx.shatter(at, radius, colorOf(f.Field), push)
				end
			end
		end
	end
	-- Un asteroide entero que se hace polvo (pequeño: sin trozos)
	if fam and not known[root] and next(now) == nil and not quiet then
		local rock = Zone.rock(root)
		if rock then
			AsteroidFx.shatter(rock.Center, rock.Radius, colorOf(rock.Field), nil)
		end
	end
	-- Trozos que se van: si caducan, se desvanecen; si se rompen sin hijos, polvo
	for id, f in before do
		if not now[id] then
			local v = visuals[id]
			visuals[id] = nil
			local expired = t >= f.Expire - 1 or fam == nil
			if not expired and not broke[id] and not quiet then
				AsteroidFx.shatter(Asteroids.posAt(f, t), f.Radius, colorOf(f.Field), nil)
				if v then
					v.Model:Destroy()
				end
			elseif v then
				if broke[id] then
					v.Model:Destroy()
				else
					fadeAndDrop(v)
				end
			end
		end
	end
	for id, f in now do
		if not visuals[id] then
			local ok, v = pcall(buildVisual, f, t)
			if ok then
				visuals[id] = v
			end
		end
	end
	known[root] = if fam then table.clone(now) else nil
end

local function stepVisuals()
	if next(visuals) == nil then
		return
	end
	local t = Asteroids.clock()
	for _, v in visuals do
		if not v.Settled then
			local f = v.Frag
			v.Model:PivotTo(CFrame.new(Asteroids.posAt(f, t)) * Asteroids.rotAt(f, t))
			if t - f.T0 > 9 then
				v.Settled = true -- (ya casi quieto: deja de moverse para no gastar)
			end
		end
	end
end

---------------------------------------------------------------------
-- Giro lento de los cercanos y LOD (de lejos, sin detalles)
---------------------------------------------------------------------
local function scan(cam: Vector3)
	local list = {}
	for _, m in CollectionService:GetTagged("Asteroide") do
		if m:IsA("Model") and m.Parent then
			local id = m:GetAttribute("RockId")
			local rock = type(id) == "string" and Zone.rock(id)
			if rock then
				local d = (rock.Center - cam).Magnitude - rock.Radius
				local near = d < Asteroids.LodFar
				if lodState[m] ~= near then
					lodState[m] = near
					AsteroidBuild.setDetail(m, near)
				end
				if d < Asteroids.TumbleRange then
					table.insert(list, { Model = m, Rock = rock, D = d })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.D < b.D
	end)
	local keep = {}
	for i = 1, math.min(#list, Asteroids.TumbleMax) do
		local e = list[i]
		local found = nil
		for _, tb in tumbling do
			if tb.Model == e.Model then
				found = tb
				break
			end
		end
		if not found then
			local axis, w = Asteroids.tumble(e.Rock.Id)
			local pivot = e.Model:GetAttribute("PivotOriginal")
			found = { Model = e.Model, Center = e.Rock.Center, Pivot = if typeof(pivot) == "CFrame" then pivot else e.Model:GetPivot(), Axis = axis, W = w }
			e.Model:SetAttribute("PivotOriginal", found.Pivot)
		end
		table.insert(keep, found)
	end
	tumbling = keep
end

local function stepTumble()
	local t = Asteroids.clock()
	for _, tb in tumbling do
		if tb.Model.Parent then
			local c = tb.Center
			tb.Model:PivotTo(CFrame.new(c) * CFrame.fromAxisAngle(tb.Axis, tb.W * t) * CFrame.new(-c) * tb.Pivot)
		end
	end
end

---------------------------------------------------------------------
-- Minar: lascas que saltan (los avisos "Mine" y "Chip" del remoto Space)
---------------------------------------------------------------------
function AsteroidFx.onSpace(kind: string, p: any)
	if type(p) ~= "table" or typeof(p.Pos) ~= "Vector3" then
		return
	end
	local cam = camPos()
	if cam and (cam - p.Pos).Magnitude > 1500 then
		return
	end
	local r = Random.new()
	local out = if cam then (cam - p.Pos) else Vector3.new(0, 1, 0)
	out = if out.Magnitude > 1e-3 then out.Unit else Vector3.new(0, 1, 0)
	if kind == "Mine" and not p.Full then
		local ore = Mining.Ores[p.Ore or ""]
		local glow = Asteroids.VeinGlow[p.Ore or ""]
		for k = 1, 4 do
			local dir = (out + Vector3.new(r:NextNumber(-0.8, 0.8), r:NextNumber(-0.8, 0.8), r:NextNumber(-0.8, 0.8))).Unit
			AsteroidFx.chunk(p.Pos, dir * r:NextNumber(18, 45), r:NextNumber(0.8, 2.2), if k == 1 and glow then glow.Color elseif ore then ore.Color:Lerp(rgb(80, 76, 72), 0.6) else rgb(90, 86, 82), k == 1 and glow ~= nil)
		end
		burst(p.Pos, 6, rgb(150, 140, 128), false)
	elseif kind == "Chip" then
		local dir = (out + Vector3.new(r:NextNumber(-0.6, 0.6), r:NextNumber(-0.6, 0.6), r:NextNumber(-0.6, 0.6))).Unit
		AsteroidFx.chunk(p.Pos, dir * r:NextNumber(12, 30), r:NextNumber(0.5, 1.2), rgb(96, 90, 86), false)
	end
end

---------------------------------------------------------------------
-- Cada fotograma (solo en el espacio)
---------------------------------------------------------------------
function AsteroidFx.step(dt: number)
	stepDebris(dt)
	local cam = camPos()
	inSpace = cam ~= nil and cam.Y > Layers.SpaceY - 300
	if not inSpace then
		return
	end
	stepVisuals()
	local now = os.clock()
	if now >= scanAt and cam then
		scanAt = now + 0.5
		scan(cam)
	end
	tumbleAcc += dt
	if tumbleAcc >= 1 / 30 then
		tumbleAcc = 0
		stepTumble()
	end
end

local function watchState(state: Instance)
	for name, value in state:GetAttributes() do
		pcall(AsteroidFx.apply, name, value, true)
	end
	state.AttributeChanged:Connect(function(name)
		local ok, err = pcall(AsteroidFx.apply, name, state:GetAttribute(name))
		if not ok then
			warn("[AsteroidFx] " .. tostring(err))
		end
	end)
end

function AsteroidFx.init()
	local state = ReplicatedStorage:FindFirstChild("AsteroidesEstado")
	if state then
		watchState(state)
	else
		local conn
		conn = ReplicatedStorage.ChildAdded:Connect(function(child)
			if child.Name == "AsteroidesEstado" then
				conn:Disconnect()
				watchState(child)
			end
		end)
	end
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
		local remote = remotes and remotes:WaitForChild("Space", 30)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(function(kind, payload)
				local ok, err = pcall(AsteroidFx.onSpace, kind, payload)
				if not ok then
					warn("[AsteroidFx] " .. tostring(err))
				end
			end)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(AsteroidFx.step, dt)
		if not ok then
			warn("[AsteroidFx] " .. tostring(err))
		end
	end)
end

-- (pruebas)
AsteroidFx._pool = pool
AsteroidFx._visuals = visuals
AsteroidFx._stepDebris = stepDebris

return AsteroidFx
