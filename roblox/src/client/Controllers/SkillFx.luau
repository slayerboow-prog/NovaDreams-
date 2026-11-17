-- SkillFx: los EFECTOS DE LAS HABILIDADES (17-11-2026, el dueño: «las habilidades deben tener animaciones realistas,
-- ahora salen polígonos muy feos»). Antes eran cilindros de neón que crecían; ahora:
--
--   * Animación del personaje (las de Roblox de siempre: tajo y estocada con arma; se ven en todos los clientes porque
--     se ponen en el Animator del personaje) y, en tu personaje, un giro de verdad (el tajo circular y la tormenta).
--   * Estelas de corte (Trail con degradado: un barrido suave, sin aristas) que giran alrededor de quien la lanza.
--   * Partículas con las texturas de Roblox: chispas, fuego, humo y polvo que sale del suelo en anillo.
--   * El golpe sísmico: salto, onda de polvo, rocas que saltan del suelo y la cámara tiembla si estás cerca.
--   * Furia: llamas y luz roja alrededor mientras dura. Coraza: una burbuja de energía azul (material ForceField).
-- El servidor (Services/HunterSkillService) avisa a todos con el remoto HunterSkill: "Fx", userId, id, desde, dir.
-- Todo es solo para la vista (sin colisiones con nadie: las rocas no pegan).

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HunterSkills = require(game:GetService("ReplicatedStorage").Shared.HunterSkills)

local SkillFx = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local player = Players.LocalPlayer

local TEX = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
}
-- Animaciones de Roblox (las del script Animate de siempre: valen en cualquier juego)
local ANIM = {
	R15 = { Slash = "rbxassetid://522635514", Lunge = "rbxassetid://522638767" },
	R6 = { Slash = "rbxassetid://129967390", Lunge = "rbxassetid://129967478" },
}

local function fxFolder(): Folder
	local f = workspace:FindFirstChild("HabilidadesFx")
	if not f then
		f = Instance.new("Folder")
		f.Name = "HabilidadesFx"
		f.Parent = workspace
	end
	return f :: Folder
end

local function anchor(at: Vector3, life: number): Part
	local p = Instance.new("Part")
	p.Name = "Fx"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = V3(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(at)
	p.Parent = fxFolder()
	Debris:AddItem(p, life)
	return p
end

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.LightEmission = props.LightEmission or 0.6
	e.Texture = props.Texture or TEX.Spark
	e.Color = props.Color or ColorSequence.new(rgb(255, 255, 255))
	e.Size = props.Size or NumberSequence.new(1, 0)
	e.Transparency = props.Transparency or NumberSequence.new(0, 1)
	e.Lifetime = props.Lifetime or NumberRange.new(0.4, 0.8)
	e.Speed = props.Speed or NumberRange.new(10, 20)
	e.SpreadAngle = props.Spread or Vector2.new(180, 180)
	e.Drag = props.Drag or 2
	e.Acceleration = props.Accel or V3(0, 0, 0)
	e.RotSpeed = props.RotSpeed or NumberRange.new(-90, 90)
	e.Rotation = NumberRange.new(0, 360)
	if props.Shape then
		e.Shape = props.Shape
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	end
	e.Parent = parent
	return e
end

-- Polvo que sale del suelo en anillo (la «onda»)
local function dustRing(at: Vector3, radius: number, color: Color3, amount: number)
	local p = anchor(at, 3)
	p.Size = V3(radius * 0.6, 0.2, radius * 0.6)
	local e = emitter(p, {
		Texture = TEX.Smoke,
		LightEmission = 0,
		Color = ColorSequence.new(color),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, radius * 0.12), NumberSequenceKeypoint.new(1, radius * 0.35) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(radius * 1.6, radius * 2.4),
		Drag = 4,
		Spread = Vector2.new(0, 8),
		Shape = Enum.ParticleEmitterShape.Disc,
	})
	e:Emit(amount)
end

local function sparks(at: Vector3, color: Color3, amount: number, speed: number?)
	local p = anchor(at, 2)
	local e = emitter(p, {
		Color = ColorSequence.new(rgb(255, 255, 255), color),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.25, 0.6),
		Speed = NumberRange.new(speed or 18, (speed or 18) * 1.8),
		Drag = 3,
		LightEmission = 1,
	})
	e:Emit(amount)
end

local function flash(at: Vector3, color: Color3, range: number, life: number)
	local p = anchor(at, life + 0.1)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 4
	l.Shadows = false
	l.Parent = p
	TweenService:Create(l, TweenInfo.new(life), { Brightness = 0 }):Play()
end

-- Un barrido de arma: dos puntos que giran alrededor del centro dejando una estela suave
local function sweep(center: () -> Vector3, inner: number, outer: number, turns: number, seconds: number, color: Color3, startAngle: number?)
	local p = anchor(center(), seconds + 0.6)
	local a0 = Instance.new("Attachment")
	local a1 = Instance.new("Attachment")
	a0.Parent = p
	a1.Parent = p
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	-- (un filo fino y corto: un arco de luz, no una sábana)
	trail.Lifetime = 0.13
	trail.LightEmission = 1
	trail.FaceCamera = false
	trail.Color = ColorSequence.new(rgb(255, 255, 255), color)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.4, 0.6), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	trail.MinLength = 0.05
	trail.Parent = p
	local t0 = os.clock()
	local base = startAngle or 0
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		if e > seconds or not p.Parent then
			trail.Enabled = false
			conn:Disconnect()
			return
		end
		local k = e / seconds
		-- (rápido al principio y frena al final, como un golpe de verdad)
		local ease = 1 - (1 - k) ^ 2.2
		local ang = base + ease * turns * math.pi * 2
		local c = center()
		p.CFrame = CFrame.new(c) * CFrame.Angles(0, ang, 0)
		-- (el filo: de inner a outer, pero estrecho y algo inclinado, como un arma que corta en diagonal)
		local mid = (inner + outer) / 2
		local tilt = math.sin(ang * 0.5) * 0.8
		a0.Position = V3(0, 0.9 + tilt, -(mid - 0.9))
		a1.Position = V3(0, -0.5 + tilt, -(mid + 1.4))
	end)
end

local function rootOf(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function playAnim(character: Model?, kind: string, speed: number?)
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local ids = if hum.RigType == Enum.HumanoidRigType.R15 then ANIM.R15 else ANIM.R6
	local a = Instance.new("Animation")
	a.AnimationId = ids[kind]
	local ok, track = pcall(function()
		return animator:LoadAnimation(a)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action4
		track:Play(0.05, 1, speed or 1.4)
		task.delay(1.2, function()
			pcall(function()
				track:Stop(0.2)
				track:Destroy()
			end)
		end)
	end
end

-- Tu personaje gira (el tajo circular y la tormenta): el cliente manda en su propio personaje
local function spinSelf(character: Model?, turns: number, seconds: number)
	if not character or character ~= player.Character then
		return
	end
	local root = rootOf(character)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		return
	end
	hum.AutoRotate = false
	local t0 = os.clock()
	local start = root.CFrame
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		if e > seconds or not root.Parent then
			conn:Disconnect()
			hum.AutoRotate = true
			return
		end
		local k = 1 - (1 - e / seconds) ^ 2
		root.CFrame = CFrame.new(root.Position) * (start - start.Position) * CFrame.Angles(0, -k * turns * math.pi * 2, 0)
	end)
end

local function shake(at: Vector3, strength: number, seconds: number)
	local cam = workspace.CurrentCamera
	local mine = rootOf(player.Character)
	if not cam or not mine or (mine.Position - at).Magnitude > 60 then
		return
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		if e > seconds then
			conn:Disconnect()
			return
		end
		local k = (1 - e / seconds) * strength
		cam.CFrame *= CFrame.Angles(math.rad((math.random() - 0.5) * k), math.rad((math.random() - 0.5) * k), 0)
	end)
end

local function rocks(at: Vector3, radius: number, n: number)
	for i = 1, n do
		local a = (i / n) * math.pi * 2 + math.random() * 0.4
		local d = radius * (0.25 + math.random() * 0.5)
		local r = Instance.new("Part")
		r.Name = "Roca"
		r.Size = V3(1 + math.random() * 1.6, 0.8 + math.random() * 1.2, 1 + math.random() * 1.6)
		r.Material = Enum.Material.Slate
		r.Color = rgb(96 + math.random(0, 30), 84 + math.random(0, 20), 70 + math.random(0, 16))
		r.CanQuery = false
		r.CanTouch = false
		r.CFrame = CFrame.new(at + V3(math.cos(a) * d, 0.8, math.sin(a) * d)) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
		r.CollisionGroup = "Default"
		r.Parent = fxFolder()
		r.AssemblyLinearVelocity = V3(math.cos(a) * 14, 26 + math.random() * 14, math.sin(a) * 14)
		r.AssemblyAngularVelocity = V3(math.random() * 10, math.random() * 10, math.random() * 10)
		-- (no empujan a nadie: no chocan con personajes)
		pcall(function()
			r.CanCollide = true
		end)
		Debris:AddItem(r, 2.6)
		task.delay(1.8, function()
			if r.Parent then
				TweenService:Create(r, TweenInfo.new(0.7), { Transparency = 1 }):Play()
			end
		end)
	end
end

-- Llamas alrededor del personaje mientras dura la Furia
local function fireAura(character: Model, seconds: number)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or rootOf(character)
	if not torso then
		return
	end
	local att = Instance.new("Attachment")
	att.Name = "FuriaFx"
	att.Parent = torso
	local e = emitter(att, {
		Texture = TEX.Fire,
		Color = ColorSequence.new(rgb(255, 200, 80), rgb(255, 60, 20)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0.2) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.35, 0.7),
		Speed = NumberRange.new(2, 5),
		Accel = V3(0, 9, 0),
		LightEmission = 0.9,
		Spread = Vector2.new(180, 180),
	})
	e.Rate = 40
	e.Enabled = true
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 110, 40)
	light.Range = 14
	light.Brightness = 1.6
	light.Shadows = false
	light.Parent = att
	task.delay(seconds, function()
		e.Enabled = false
		Debris:AddItem(att, 1)
		TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 0 }):Play()
	end)
end

-- La burbuja de la Coraza
local function shieldBubble(character: Model, seconds: number)
	local root = rootOf(character)
	if not root then
		return
	end
	local b = Instance.new("Part")
	b.Name = "CorazaFx"
	b.Shape = Enum.PartType.Ball
	b.Material = Enum.Material.ForceField
	b.Color = rgb(110, 190, 255)
	b.Size = V3(1, 1, 1)
	b.CanCollide = false
	b.CanQuery = false
	b.CanTouch = false
	b.Massless = true
	b.Transparency = 0.1
	b.CFrame = root.CFrame
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = b
	weld.Parent = b
	b.Parent = fxFolder()
	TweenService:Create(b, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = V3(9, 9, 9) }):Play()
	local e = emitter(b, {
		Color = ColorSequence.new(rgb(200, 240, 255), rgb(80, 160, 255)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.5, 1),
		Speed = NumberRange.new(1, 3),
		LightEmission = 1,
	})
	e.Rate = 14
	e.Enabled = true
	task.delay(math.max(0.5, seconds - 0.6), function()
		if b.Parent then
			e.Enabled = false
			TweenService:Create(b, TweenInfo.new(0.6), { Transparency = 1, Size = V3(11, 11, 11) }):Play()
		end
	end)
	Debris:AddItem(b, seconds + 0.4)
end

-- Una habilidad: quién (userId), cuál (id), desde dónde y hacia dónde
function SkillFx.play(userId: number, id: string, from: Vector3, dir: Vector3)
	local sk = HunterSkills.get(id)
	if not sk then
		return
	end
	local who = Players:GetPlayerByUserId(userId)
	local character = who and who.Character
	local root = rootOf(character)
	local function center(): Vector3
		return if root and root.Parent then root.Position else from
	end
	local ground = from - V3(0, 2.6, 0)
	if id == "TajoCircular" then
		playAnim(character, "Slash", 1.6)
		spinSelf(character, 1, 0.35)
		sweep(center, 2.5, sk.Radius * 0.75, 1, 0.35, rgb(140, 220, 255))
		dustRing(ground, sk.Radius, rgb(200, 190, 170), 26)
		sparks(from, rgb(140, 220, 255), 30, 26)
	elseif id == "TormentaAcero" then
		playAnim(character, "Slash", 2)
		spinSelf(character, 3, 0.9)
		sweep(center, 2, sk.Radius * 0.8, 3, 0.9, rgb(255, 230, 150))
		sweep(center, 3, sk.Radius * 0.6, 3, 0.9, rgb(220, 230, 255), math.pi)
		for k = 0, 2 do
			task.delay(k * 0.28, function()
				sparks(center(), rgb(255, 210, 120), 24, 22)
			end)
		end
		dustRing(ground, sk.Radius, rgb(190, 180, 160), 20)
	elseif id == "Embestida" then
		playAnim(character, "Lunge", 1.3)
		dustRing(ground, 6, rgb(200, 190, 170), 14)
		if root then
			local a0 = Instance.new("Attachment")
			a0.Position = V3(0, 1.4, 0)
			local a1 = Instance.new("Attachment")
			a1.Position = V3(0, -1.4, 0)
			a0.Parent = root
			a1.Parent = root
			local trail = Instance.new("Trail")
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Lifetime = 0.3
			trail.LightEmission = 1
			trail.Color = ColorSequence.new(rgb(255, 255, 255), rgb(120, 220, 255))
			trail.Transparency = NumberSequence.new(0.2, 1)
			trail.Parent = root
			Debris:AddItem(trail, 0.8)
			Debris:AddItem(a0, 0.8)
			Debris:AddItem(a1, 0.8)
		end
		task.delay(0.35, function()
			dustRing(center() - V3(0, 2.6, 0), 8, rgb(200, 190, 170), 18)
			sparks(center(), rgb(120, 220, 255), 20, 20)
		end)
	elseif id == "GolpeSismico" then
		playAnim(character, "Slash", 1.1)
		if character == player.Character and root then
			root.AssemblyLinearVelocity = V3(root.AssemblyLinearVelocity.X, 42, root.AssemblyLinearVelocity.Z)
		end
		task.delay(0.42, function()
			local at = center() - V3(0, 2.6, 0)
			dustRing(at, sk.Radius, rgb(170, 150, 120), 40)
			rocks(at, sk.Radius, 12)
			sparks(at + V3(0, 1, 0), rgb(255, 200, 90), 36, 30)
			flash(at + V3(0, 2, 0), rgb(255, 200, 120), 40, 0.5)
			shake(at, 4, 0.5)
		end)
	elseif id == "Furia" then
		if character then
			sparks(from, rgb(255, 120, 40), 40, 16)
			flash(from, rgb(255, 110, 40), 24, 0.6)
			fireAura(character, sk.Seconds or 15)
		end
	elseif id == "Coraza" then
		if character then
			sparks(from, rgb(120, 200, 255), 30, 12)
			shieldBubble(character, sk.Seconds or 12)
		end
	else
		sparks(from, rgb(255, 255, 255), 24, 18)
		dustRing(ground, sk.Radius or 10, rgb(200, 190, 170), 18)
	end
	local _ = dir
end

function SkillFx.init()
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	local remote = remotes:WaitForChild("HunterSkill", 30) :: RemoteEvent?
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(kind: string, userId: any, id: any, from: any, dir: any)
		if kind == "Fx" and type(userId) == "number" and type(id) == "string" and typeof(from) == "Vector3" then
			local ok, err = pcall(SkillFx.play, userId, id, from, if typeof(dir) == "Vector3" then dir else V3(0, 0, -1))
			if not ok then
				warn("[SkillFx] " .. tostring(err))
			end
		end
	end)
end

return SkillFx
