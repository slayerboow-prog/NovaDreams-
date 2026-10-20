-- AlienAnim (cliente): da vida a los alienígenas de la Invasión de la Grieta y a la gente transformada.
-- No decide nada (lo manda Services/InvasionService): solo se ve.
--
--   * Animación procedural de los modelos de malla v2 (atributo Mesh: World/Kit/AlienModels): cada
--     segmento (Body, Head, ArmL…) con su Motor6D; la pose sale de shared/Invasion/AlienPose según lo que
--     hace (la velocidad se mide aquí, del movimiento que llega del servidor): quieto, andar, correr,
--     preparar el ataque (se ve venir), golpear o disparar, encajar un disparo (respingo) y caer.
--   * Versión lejana (LOD): de lejos se esconden los segmentos y se ve la malla LOD (sin animar).
--   * Aviso del ataque (evento "Windup"): el alienígena brilla del color de su raza mientras carga.
--   * Respingo al encajar un disparo (evento "Flinch"): también en los de piezas (un destello).
--   * Al caer: se deshace en luz y chispas (una copia local que se desmonta y se desvanece; nada de sangre).
--   * La transformación de un vecino (evento "Transform"): una silueta de luz que se retuerce en una
--     espiral y de ella sale la criatura (que aparece poco a poco); al curarla, al revés ("Restore").
-- Topes: como mucho MaxAnimated animados a la vez (los más cercanos) y efectos según el nivel gráfico.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local AlienPose = require(ReplicatedStorage.Shared.Invasion.AlienPose)
local Races = require(ReplicatedStorage.Shared.Invasion.Races)

local AlienAnim = {}

AlienAnim.MaxAnimated = 28
AlienAnim.LodNear, AlienAnim.LodFar = 150, 175

local player = Players.LocalPlayer

type Rec = {
	Model: Model,
	Root: BasePart?,
	Joints: { [string]: Motor6D },
	Lod: { BasePart },
	Parts: { BasePart },
	Gait: string,
	Scale: number,
	Race: string?,
	Last: Vector3?,
	Speed: number,
	WindupAt: number?,
	WindupFor: number,
	StrikeAt: number?,
	HitAt: number?,
	HitSide: number,
	IsLod: boolean,
	Seed: number,
	Born: number,
	FadeIn: number?,
	Attack: string?,
	Pulse: { { Part: BasePart, Color: Color3, Phase: number } }?,
}

local recs: { [Model]: Rec } = {}
local byTarget: { [string]: Model } = {}

local function tier(): string
	local t = player:GetAttribute("GraphicsTier")
	return if type(t) == "string" then t else "Medium"
end

local function glowOf(raceId: any): Color3
	local race = if type(raceId) == "string" then Races.get(raceId) else nil
	return if race then Races.color(race.Palette.Glow) else Color3.fromRGB(180, 255, 240)
end

---------------------------------------------------------------------
-- Seguir los modelos
---------------------------------------------------------------------
local function track(model: Instance)
	if not model:IsA("Model") or recs[model] then
		return
	end
	local joints: { [string]: Motor6D } = {}
	local lod: { BasePart } = {}
	local parts: { BasePart } = {}
	local pulse: { { Part: BasePart, Color: Color3, Phase: number } }? = if model:GetAttribute("Pulse") then {} else nil
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			joints[d.Name] = d
		elseif d:IsA("BasePart") then
			if d:GetAttribute("Lod") then
				table.insert(lod, d)
				d.LocalTransparencyModifier = 1 -- (de cerca, al empezar)
			elseif d.Transparency < 1 then
				table.insert(parts, d)
				-- (Vórtidos de cristal: el neón late despacio —costuras, núcleos, motores—; cada pieza con su fase)
				if pulse and d.Material == Enum.Material.Neon and #pulse < 24 then
					table.insert(pulse, { Part = d, Color = d.Color, Phase = #pulse * 0.9 })
				end
			end
		end
	end
	local height = tonumber(model:GetAttribute("MeshHeight")) or (model.PrimaryPart and model.PrimaryPart.Size.Y) or 6
	local rec: Rec = {
		Model = model,
		Root = model.PrimaryPart,
		Joints = joints,
		Lod = lod,
		Parts = parts,
		Gait = tostring(model:GetAttribute("Gait") or (if model:GetAttribute("InvasionShip") then "Ship" else "Biped")),
		Scale = height / 6,
		Race = model:GetAttribute("Race"),
		Last = nil,
		Speed = 0,
		WindupAt = nil,
		WindupFor = 0.6,
		StrikeAt = nil,
		HitAt = nil,
		HitSide = 1,
		IsLod = false,
		Seed = (#model.Name * 1.37) % 6,
		Born = os.clock(),
		FadeIn = nil,
		Attack = (function()
			local a = model:GetAttribute("Attack")
			return if type(a) == "string" then a else nil
		end)(),
		Pulse = pulse,
	}
	recs[model] = rec
	local id = model:GetAttribute("InvasionTarget")
	if type(id) == "string" then
		byTarget[id] = model
	end
	model.Destroying:Connect(function()
		AlienAnim.onGone(model)
	end)
end

local function untrack(model: Model)
	local rec = recs[model]
	if not rec then
		return
	end
	recs[model] = nil
	local id = model:GetAttribute("InvasionTarget")
	if type(id) == "string" and byTarget[id] == model then
		byTarget[id] = nil
	end
end

function AlienAnim.modelOf(id: any): Model?
	if type(id) ~= "string" then
		return nil
	end
	local m = byTarget[id]
	return if m and m.Parent then m else nil
end

---------------------------------------------------------------------
-- Efectos
---------------------------------------------------------------------
local function fxFolder(): Folder
	local f = workspace:FindFirstChild("AlienFx")
	if not f then
		f = Instance.new("Folder")
		f.Name = "AlienFx"
		f.Parent = workspace
	end
	return f :: Folder
end

local function sparks(at: Vector3, color: Color3, count: number, speed: number?, life: number?)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(at)
	p.Parent = fxFolder()
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.3, life or 0.8)
	e.Speed = NumberRange.new((speed or 12) * 0.5, speed or 12)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 3
	e.Rate = 0
	e.Parent = p
	e:Emit(count)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = 12
	l.Brightness = 3
	l.Parent = p
	TweenService:Create(l, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(p, (life or 0.8) + 0.4)
end
AlienAnim.sparks = sparks

-- Un destello del color de la raza (respingo; también en los de piezas)
local flashes = 0
local function flash(model: Model, color: Color3, strength: number, seconds: number)
	if flashes >= 10 then
		return
	end
	local h = Instance.new("Highlight")
	h.Adornee = model
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 1 - strength
	h.OutlineTransparency = 1 - strength * 0.8
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = fxFolder()
	flashes += 1
	TweenService:Create(h, TweenInfo.new(seconds), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	task.delay(seconds, function()
		flashes -= 1
		h:Destroy()
	end)
end

-- El alienígena prepara un ataque: brilla cada vez más (se ve venir)
function AlienAnim.windup(id: any, seconds: number?)
	local m = AlienAnim.modelOf(id)
	local rec = m and recs[m]
	if not m or not rec then
		return
	end
	rec.WindupAt = os.clock()
	rec.WindupFor = math.clamp(seconds or 0.6, 0.2, 2)
	rec.StrikeAt = nil
	if flashes < 10 then
		local h = Instance.new("Highlight")
		h.Adornee = m
		h.FillColor = glowOf(rec.Race)
		h.OutlineColor = Color3.new(1, 1, 1)
		h.FillTransparency = 0.95
		h.OutlineTransparency = 0.6
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = fxFolder()
		flashes += 1
		TweenService:Create(h, TweenInfo.new(rec.WindupFor, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { FillTransparency = 0.45, OutlineTransparency = 0 }):Play()
		task.delay(rec.WindupFor + 0.1, function()
			flashes -= 1
			h:Destroy()
		end)
	end
end

-- Suelta el golpe o el disparo
function AlienAnim.strike(id: any)
	local m = AlienAnim.modelOf(id)
	local rec = m and recs[m]
	if rec then
		rec.WindupAt = nil
		rec.StrikeAt = os.clock()
	end
end

-- Encaja un disparo: respingo y destello blanco
function AlienAnim.flinch(id: any, from: Vector3?, heavy: boolean?)
	local m = AlienAnim.modelOf(id)
	local rec = m and recs[m]
	if not m or not rec then
		return
	end
	rec.HitAt = os.clock()
	local root = rec.Root
	if root and typeof(from) == "Vector3" then
		local rel = root.CFrame:PointToObjectSpace(from)
		rec.HitSide = if rel.X >= 0 then -1 else 1
	end
	if heavy then
		rec.WindupAt = nil -- (un golpe fuerte le corta el ataque: lo ha visto el servidor también)
	end
	flash(m, Color3.new(1, 1, 1), if heavy then 0.6 else 0.35, 0.18)
end

-- Al caer: una copia local que se deshace en luz (la de verdad ya la ha quitado el servidor)
local dissolving = 0
function AlienAnim.onGone(model: Model)
	local rec = recs[model]
	untrack(model)
	if not rec then
		return
	end
	local hp = tonumber(model:GetAttribute("Hp"))
	if hp == nil or hp > 0 or dissolving >= (if tier() == "Low" then 2 else 6) then
		return -- (se ha ido sin caer: la recogida o el streaming)
	end
	local root = rec.Root
	if not root then
		return
	end
	local camera = workspace.CurrentCamera
	if (camera.CFrame.Position - root.Position).Magnitude > 260 then
		return
	end
	local ok, copy = pcall(function()
		model.Archivable = true
		return model:Clone()
	end)
	if not ok or not copy then
		return
	end
	dissolving += 1
	local color = glowOf(rec.Race)
	local pieces = {}
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
			if d:GetAttribute("Lod") or d.Transparency >= 1 then
				d.Transparency = 1
			else
				table.insert(pieces, { Part = d, Base = d.CFrame, Dir = (d.Position - root.Position + Vector3.new(0, 0.5, 0)).Unit, Spin = (math.random() - 0.5) * 3 })
			end
		elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Humanoid") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end
	copy.Parent = fxFolder()
	sparks(root.Position, color, if tier() == "Low" then 12 else 30, 16, 1.0)
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local age = os.clock() - t0
		local fade, shrink = AlienPose.dissolve(age)
		for i, p in pieces do
			local part = p.Part :: BasePart
			if part.Parent then
				local drift = p.Dir * (age * age * 3) + Vector3.new(0, age * 1.5, 0)
				part.CFrame = (p.Base + drift) * CFrame.Angles(p.Spin * age, p.Spin * age * 0.6, 0)
				part.Transparency = math.max(part.Transparency, fade)
				if i % 3 == 0 and age < 0.6 then
					part.Material = Enum.Material.Neon
					part.Color = part.Color:Lerp(color, math.min(1, age * 2))
				end
				local s = part.Size
				if s.Magnitude > 0.2 then
					part.Size = s * (shrink ^ 0.02)
				end
			end
		end
		if age >= AlienPose.DissolveTime then
			conn:Disconnect()
			copy:Destroy()
			dissolving -= 1
		end
	end)
end

-- La transformación: silueta de persona en luz que se retuerce y deja paso a la criatura
local function silhouette(at: Vector3, color: Color3): { BasePart }
	local list = {}
	local function piece(size: Vector3, offset: Vector3, ball: boolean?)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Material = Enum.Material.Neon
		p.Color = Color3.new(1, 1, 1):Lerp(color, 0.35)
		p.Transparency = 0.25
		p.Size = size
		if ball then
			p.Shape = Enum.PartType.Ball
		end
		p.CFrame = CFrame.new(at + offset)
		p.Parent = fxFolder()
		table.insert(list, p)
	end
	piece(Vector3.new(1.6, 2, 1), Vector3.new(0, 3, 0))
	piece(Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), true)
	piece(Vector3.new(0.6, 2, 0.6), Vector3.new(-1.1, 3, 0))
	piece(Vector3.new(0.6, 2, 0.6), Vector3.new(1.1, 3, 0))
	piece(Vector3.new(0.7, 2, 0.7), Vector3.new(-0.4, 1, 0))
	piece(Vector3.new(0.7, 2, 0.7), Vector3.new(0.4, 1, 0))
	return list
end

local function nearestCreature(at: Vector3): Model?
	local folder = workspace:FindFirstChild("Invasion")
	local city = folder and folder:FindFirstChild("City")
	local best, bestD = nil, 8
	for _, m in if city then city:GetChildren() else {} do
		if m:IsA("Model") and m.PrimaryPart then
			local d = (m.PrimaryPart.Position - at).Magnitude
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

function AlienAnim.transform(at: Vector3, raceId: any, reverse: boolean?)
	if typeof(at) ~= "Vector3" then
		return
	end
	local camera = workspace.CurrentCamera
	if (camera.CFrame.Position - at).Magnitude > 300 then
		return
	end
	local color = glowOf(raceId)
	local sil = silhouette(at, color)
	-- espiral de chispas y un anillo en el suelo
	local spiral = Instance.new("Part")
	spiral.Anchored, spiral.CanCollide, spiral.CanQuery, spiral.CanTouch = true, false, false, false
	spiral.Transparency = 1
	spiral.Size = Vector3.new(0.2, 0.2, 0.2)
	spiral.CFrame = CFrame.new(at + Vector3.new(0, 2.5, 0))
	spiral.Parent = fxFolder()
	local a0 = Instance.new("Attachment")
	a0.Parent = spiral
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.45, 0)
	e.Lifetime = NumberRange.new(0.6, 1.0)
	e.Speed = NumberRange.new(2, 4)
	e.SpreadAngle = Vector2.new(25, 25)
	e.EmissionDirection = Enum.NormalId.Top
	e.RotSpeed = NumberRange.new(-200, 200)
	e.Rate = if tier() == "Low" then 30 else 90
	e.Parent = a0
	local ring = Instance.new("Part")
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.3
	ring.Size = Vector3.new(0.15, 1, 1)
	ring.CFrame = CFrame.new(at + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = fxFolder()
	TweenService:Create(ring, TweenInfo.new(AlienPose.TransformTime, Enum.EasingStyle.Quad), { Size = Vector3.new(0.15, 14, 14), Transparency = 1 }):Play()
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 4
	light.Parent = spiral
	local creature = if reverse then nil else nearestCreature(at)
	local creatureParts = {}
	if creature then
		for _, d in creature:GetDescendants() do
			if d:IsA("BasePart") and not d:GetAttribute("Lod") and d.Transparency < 1 then
				d.LocalTransparencyModifier = 1
				table.insert(creatureParts, d)
			end
		end
		local rec = recs[creature]
		if rec then
			rec.FadeIn = os.clock()
		end
	end
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local age = os.clock() - t0
		local person, beast = AlienPose.transform(age)
		if reverse then
			person, beast = beast, person
		end
		for i, p in sil do
			p.Transparency = 1 - person * 0.75
			local twist = (1 - person) * 2.5 * (if i % 2 == 0 then 1 else -1)
			local base = at + Vector3.new(0, 2.5, 0)
			local rel = p.Position - base
			p.CFrame = CFrame.new(base) * CFrame.Angles(0, twist * 0.05, 0) * CFrame.new(rel * (0.985 + 0.015 * person)) * CFrame.Angles(0, twist * 0.2, 0)
		end
		for _, d in creatureParts do
			if d.Parent then
				d.LocalTransparencyModifier = 1 - beast
			end
		end
		spiral.CFrame = CFrame.new(at + Vector3.new(0, 1 + age * 1.5, 0)) * CFrame.Angles(0, age * 12, 0)
		a0.Position = Vector3.new(1.2 * (1 - age / AlienPose.TransformTime), 0, 0)
		if age >= AlienPose.TransformTime then
			conn:Disconnect()
			for _, p in sil do
				p:Destroy()
			end
			e.Enabled = false
			Debris:AddItem(spiral, 1.2)
			ring:Destroy()
			for _, d in creatureParts do
				if d.Parent then
					d.LocalTransparencyModifier = 0
				end
			end
		end
	end)
	sparks(at + Vector3.new(0, 2.5, 0), color, if tier() == "Low" then 10 else 26, 10, 1.2)
end

---------------------------------------------------------------------
-- Cada fotograma: poses y LOD
---------------------------------------------------------------------
local order: { Rec } = {}
local orderAt = 0

local function step(dt: number)
	local camera = workspace.CurrentCamera
	local cam = camera.CFrame.Position
	local now = os.clock()
	if now - orderAt > 0.5 then
		orderAt = now
		table.clear(order)
		for m, rec in recs do
			if m.Parent and rec.Root then
				table.insert(order, rec)
			end
		end
		table.sort(order, function(a, b)
			return ((a.Root :: BasePart).Position - cam).Magnitude < ((b.Root :: BasePart).Position - cam).Magnitude
		end)
	end
	local cap = if tier() == "Low" then 10 else AlienAnim.MaxAnimated
	for i, rec in order do
		local root = rec.Root
		if not root or not rec.Model.Parent then
			continue
		end
		local pos = root.Position
		local distance = (pos - cam).Magnitude
		-- Velocidad (suavizada) de lo que llega del servidor
		if rec.Last and dt > 0 then
			local v = Vector3.new(pos.X - rec.Last.X, 0, pos.Z - rec.Last.Z).Magnitude / dt
			if v < 200 then -- (un salto de teletransporte no es correr)
				rec.Speed += (v - rec.Speed) * math.min(1, dt * 6)
			end
		end
		rec.Last = pos
		-- LOD
		if #rec.Lod > 0 then
			local lod = AlienPose.useLod(distance, rec.IsLod, AlienAnim.LodNear, AlienAnim.LodFar)
			if lod ~= rec.IsLod then
				rec.IsLod = lod
				for _, p in rec.Lod do
					p.LocalTransparencyModifier = if lod then 0 else 1
				end
				for _, p in rec.Parts do
					p.LocalTransparencyModifier = if lod then 1 else 0
				end
			end
		end
		if rec.IsLod or i > cap or not next(rec.Joints) then
			continue
		end
		local windup = nil
		if rec.WindupAt then
			windup = (now - rec.WindupAt) / rec.WindupFor
			if windup > 1.4 then
				rec.WindupAt = nil
				windup = nil
			end
		end
		local strike = nil
		if rec.StrikeAt then
			strike = (now - rec.StrikeAt) / 0.4
			if strike > 1 then
				rec.StrikeAt = nil
				strike = nil
			end
		end
		local pose = AlienPose.pose(rec.Gait, {
			T = now + rec.Seed,
			Speed = rec.Speed,
			Base = 7 * math.max(rec.Scale, 0.5),
			Windup = windup,
			Strike = strike,
			Hit = if rec.HitAt then now - rec.HitAt else nil,
			HitSide = rec.HitSide,
			Scale = rec.Scale,
			Race = rec.Race,
			Attack = rec.Attack,
		})
		if rec.Pulse and i <= 12 then
			-- el brillo del cristal y de los motores: late entre el 80 y el 100 % (más fuerte al cargar)
			local boost = if windup then 0.15 * math.clamp(windup, 0, 1) else 0
			for _, e in rec.Pulse do
				local k = AlienPose.pulse(now + rec.Seed, e.Phase) + boost
				e.Part.Color = Color3.new(math.min(1, e.Color.R * k), math.min(1, e.Color.G * k), math.min(1, e.Color.B * k))
			end
		end
		for name, joint in rec.Joints do
			local cf = pose[name]
			joint.Transform = cf or CFrame.identity
		end
	end
end

local function watchFolder(folder: Instance)
	for _, sub in folder:GetChildren() do
		if sub:IsA("Folder") then
			for _, m in sub:GetChildren() do
				track(m)
			end
			sub.ChildAdded:Connect(function(m)
				task.defer(track, m)
			end)
			sub.ChildRemoved:Connect(function(m)
				if m:IsA("Model") and not m.Parent then
					task.defer(function()
						if recs[m] and not m.Parent then
							untrack(m)
						end
					end)
				end
			end)
		end
	end
	folder.ChildAdded:Connect(function(sub)
		if sub:IsA("Folder") then
			sub.ChildAdded:Connect(function(m)
				task.defer(track, m)
			end)
			for _, m in sub:GetChildren() do
				track(m)
			end
		end
	end)
end

function AlienAnim.init()
	local function hook(f: Instance)
		if f.Name == "Invasion" and f:IsA("Folder") then
			watchFolder(f)
		end
	end
	for _, c in workspace:GetChildren() do
		hook(c)
	end
	workspace.ChildAdded:Connect(hook)
	local signal = (RunService :: any).PreAnimation or RunService.Stepped
	signal:Connect(function(a, b)
		local dt = if type(b) == "number" then b else a
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[AlienAnim] " .. tostring(err))
		end
	end)
end

AlienAnim._recs = recs
AlienAnim._track = track
AlienAnim._step = step

return AlienAnim
