-- CombatFx (cliente): lo que se ve de la pelea, hecho con piezas sencillas y partículas de Roblox.
--
--   * Impacto: chispas, un anillo que se abre y un destello (blanco-naranja los golpes; los poderes,
--     con el color de la Grieta: verde-cian con el núcleo ámbar).
--   * Congelación del impacto (hitstop): el golpe y las animaciones del que pega y del que recibe se
--     paran un instante (PunchAnim.freeze y Animator a velocidad 0) y siguen.
--   * Texto del final («¡Lanzador!», «¡Guardia rota!») sobre el que lo recibe.
--   * Aura al cargar energía, brillo en el puño al cargar el golpe fuerte.
--   * Desvanecerse: una silueta que se apaga donde estabas y un destello donde apareces.
--   * Poderes: esferas que vuelan, la onda (un haz que crece), la embestida (estela), el puñetazo
--     explosivo (esfera que se abre) y la definitiva con su mini-cinemática de cámara.
--   * Contra la pared: polvo y una grieta en forma de anillo.
-- Todo es local (cada pantalla lo dibuja) y se borra solo. Nada de esto decide si un golpe entra:
-- eso es CombatService.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PunchAnim = require(script.Parent.PunchAnim)
local CameraShake = require(script.Parent.CameraShake)
local SoundFx = require(script.Parent.SoundFx)

local CombatFx = {}

local rgb = Color3.fromRGB
local player = Players.LocalPlayer

-- Colores: golpes (blanco-naranja) y energía de la Grieta (verde-cian y ámbar; shared/SkyRift)
CombatFx.Colors = {
	Hit = rgb(255, 236, 200),
	HitHeavy = rgb(255, 150, 60),
	Block = rgb(150, 200, 255),
	EnergyCore = rgb(255, 222, 150),
	EnergyGlow = rgb(86, 246, 196),
	EnergyEdge = rgb(70, 200, 255),
	Dust = rgb(170, 160, 145),
}

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local folder: Folder? = nil
local function fxFolder(): Instance
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "CombatFx"
	f.Parent = workspace
	folder = f
	return f
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = fxFolder()
	return p
end

local function later(seconds: number, instance: Instance)
	task.delay(seconds, function()
		if instance.Parent then
			instance:Destroy()
		end
	end)
end

local function tween(object: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	local t = TweenService:Create(object, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

-- Chispas en un punto (n partículas de una vez)
local function sparks(at: Vector3, color: Color3, n: number, speed: number, size: number, texture: string?)
	local anchor = part({ Name = "Chispas", Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = CFrame.new(at) })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture or SPARK
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.2, 0.45)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 6
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(n)
	later(0.8, anchor)
end

-- Anillo que se abre (onda del golpe), mirando hacia `normal`
local function ring(at: Vector3, normal: Vector3, color: Color3, from: number, to: number, seconds: number)
	local look = if normal.Magnitude > 0.01 then normal.Unit else Vector3.new(0, 0, -1)
	local r = part({
		Name = "Anillo",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, from, from),
		Color = color,
		Transparency = 0.25,
		CFrame = CFrame.lookAt(at, at + look) * CFrame.Angles(0, math.rad(90), 0),
	})
	tween(r, seconds, { Size = Vector3.new(0.05, to, to), Transparency = 1 })
	later(seconds + 0.05, r)
end

-- Destello esférico
local function flash(at: Vector3, color: Color3, from: number, to: number, seconds: number, transparency: number?)
	local s = part({ Name = "Destello", Shape = Enum.PartType.Ball, Size = Vector3.new(from, from, from), Color = color, Transparency = transparency or 0.2, CFrame = CFrame.new(at) })
	tween(s, seconds, { Size = Vector3.new(to, to, to), Transparency = 1 })
	later(seconds + 0.05, s)
	return s
end

---------------------------------------------------------------------
-- Impactos
---------------------------------------------------------------------

-- Impacto en `at` (dirección del golpe `dir`). strength 0..1 (ligero..final), energy: poder de energía
function CombatFx.impact(at: Vector3, dir: Vector3, strength: number, energy: boolean?, blocked: boolean?)
	local s = math.clamp(strength, 0, 1)
	local color = if blocked then CombatFx.Colors.Block elseif energy then CombatFx.Colors.EnergyGlow elseif s > 0.5 then CombatFx.Colors.HitHeavy else CombatFx.Colors.Hit
	sparks(at, color, math.floor(8 + 18 * s), 18 + 30 * s, 0.6 + 0.8 * s)
	if energy then
		sparks(at, CombatFx.Colors.EnergyCore, math.floor(6 + 10 * s), 10 + 20 * s, 0.8 + s)
	end
	ring(at, dir, color, 0.6, 4 + 8 * s, 0.18 + 0.12 * s)
	flash(at, if energy then CombatFx.Colors.EnergyCore else rgb(255, 255, 255), 0.4, 2 + 3 * s, 0.12 + 0.08 * s, 0.1)
end

-- Congelación del impacto: el golpe y las animaciones de esos personajes se paran `seconds`
local frozen: { [AnimationTrack]: number } = {}
function CombatFx.hitstop(models: { Model? }, seconds: number)
	if seconds <= 0 then
		return
	end
	for _, model in models do
		if model and model.Parent then
			PunchAnim.freeze(model, seconds)
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			if animator then
				local ok, tracks = pcall(function()
					return animator:GetPlayingAnimationTracks()
				end)
				if ok then
					for _, track in tracks do
						if frozen[track] == nil then
							frozen[track] = track.Speed
							pcall(function()
								track:AdjustSpeed(0)
							end)
							task.delay(seconds, function()
								local speed = frozen[track]
								frozen[track] = nil
								if speed and track.IsPlaying then
									pcall(function()
										track:AdjustSpeed(speed)
									end)
								end
							end)
						end
					end
				end
			end
		end
	end
end

-- Texto grande sobre un personaje (el nombre del final)
function CombatFx.label(model: Model?, text: string, color: Color3?)
	local head = model and (model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart"))
	if not head or not head:IsA("BasePart") then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Final"
	billboard.Size = UDim2.fromOffset(260, 50)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
	label.TextColor3 = color or rgb(255, 214, 90)
	label.TextStrokeTransparency = 0.1
	label.Parent = billboard
	local scale = Instance.new("UIScale")
	scale.Scale = 1.6
	scale.Parent = label
	billboard.Parent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
	tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(0.6, function()
		tween(label, 0.35, { TextTransparency = 1, TextStrokeTransparency = 1 })
		tween(billboard, 0.35, { StudsOffset = Vector3.new(0, 4.6, 0) })
	end)
	later(1.1, billboard)
end

---------------------------------------------------------------------
-- Aura (cargar energía) y brillo del puño (cargar el fuerte)
---------------------------------------------------------------------
local auras: { [Model]: { Instance } } = {}

function CombatFx.aura(model: Model?, on: boolean, big: boolean?)
	if not model then
		return
	end
	local existing = auras[model]
	if existing then
		for _, i in existing do
			i:Destroy()
		end
		auras[model] = nil
	end
	if not on then
		return
	end
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso")
	if not root or not root:IsA("BasePart") then
		return
	end
	local list = {}
	local attachment = Instance.new("Attachment")
	attachment.Name = "AuraEnergia"
	attachment.Parent = root
	table.insert(list, attachment)
	for i, color in { CombatFx.Colors.EnergyGlow, CombatFx.Colors.EnergyCore } do
		local e = Instance.new("ParticleEmitter")
		e.Texture = if i == 1 then SMOKE else SPARK
		e.Color = ColorSequence.new(color)
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, if i == 1 then 2.2 else 0.5), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, if i == 1 then 0.6 else 0.1), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(0.4, 0.8)
		e.Speed = NumberRange.new(4, 9)
		e.Acceleration = Vector3.new(0, 14, 0)
		e.SpreadAngle = Vector2.new(25, 25)
		e.EmissionDirection = Enum.NormalId.Top
		e.Rate = (if i == 1 then 30 else 18) * (if big then 2 else 1)
		e.Parent = attachment
		table.insert(list, e)
	end
	local light = Instance.new("PointLight")
	light.Color = CombatFx.Colors.EnergyGlow
	light.Brightness = if big then 4 else 2
	light.Range = if big then 18 else 10
	light.Parent = root
	table.insert(list, light)
	auras[model] = list
end

-- Brillo en el puño derecho mientras se carga el golpe fuerte (seconds: se apaga solo)
function CombatFx.windup(model: Model?, seconds: number?)
	local hand = model and (model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm") or model:FindFirstChild("HumanoidRootPart"))
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local old = hand:FindFirstChild("BrilloCarga")
	if old then
		old:Destroy()
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "BrilloCarga"
	attachment.Parent = hand
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(CombatFx.Colors.HitHeavy)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.15, 0.3)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 40
	e.Parent = attachment
	later(seconds or 2.5, attachment)
end

function CombatFx.stopWindup(model: Model?)
	local hand = model and (model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm") or model:FindFirstChild("HumanoidRootPart"))
	local glow = hand and hand:FindFirstChild("BrilloCarga")
	if glow then
		glow:Destroy()
	end
end

---------------------------------------------------------------------
-- Desvanecerse, pared, embestida
---------------------------------------------------------------------
function CombatFx.vanish(from: Vector3, to: Vector3)
	-- Silueta que se apaga donde estabas y destello donde apareces
	local ghost = part({ Name = "Silueta", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 2.4, 2.4), Color = rgb(220, 240, 255), Transparency = 0.45, CFrame = CFrame.new(from) * CFrame.Angles(0, 0, math.rad(90)) })
	tween(ghost, 0.25, { Size = Vector3.new(5.5, 0.2, 0.2), Transparency = 1 })
	later(0.3, ghost)
	for i = 1, 4 do
		local streak = part({ Name = "Trazo", Size = Vector3.new(0.12, 0.12, 2.5), Color = rgb(235, 245, 255), Transparency = 0.3, CFrame = CFrame.lookAt(from + Vector3.new(math.random(-10, 10) / 10, math.random(-15, 15) / 10, 0), to) })
		tween(streak, 0.2, { Transparency = 1, Size = Vector3.new(0.05, 0.05, 4) })
		later(0.25, streak)
		local _ = i
	end
	flash(to, rgb(235, 245, 255), 1, 4, 0.18, 0.4)
	SoundFx.play("Salto", 0.5, 1.6)
end

function CombatFx.wall(at: Vector3)
	sparks(at, CombatFx.Colors.Dust, 26, 22, 1.4, SMOKE)
	sparks(at, rgb(255, 255, 255), 12, 26, 0.6)
	ring(at, Vector3.new(0, 1, 0), CombatFx.Colors.Dust, 1, 9, 0.35)
	SoundFx.play("GolpeCaida", 1, 0.8)
end

function CombatFx.dash(model: Model?, dir: Vector3)
	local root = model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	for i = 1, 6 do
		task.delay(i * 0.03, function()
			if not root.Parent then
				return
			end
			local at = root.Position + Vector3.new(math.random(-12, 12) / 10, math.random(-15, 15) / 10, math.random(-12, 12) / 10)
			local streak = part({ Name = "Estela", Size = Vector3.new(0.15, 0.15, 3.5), Color = CombatFx.Colors.EnergyGlow, Transparency = 0.2, CFrame = CFrame.lookAt(at, at + dir) })
			tween(streak, 0.25, { Transparency = 1 })
			later(0.3, streak)
		end)
	end
end

---------------------------------------------------------------------
-- Poderes
---------------------------------------------------------------------

-- Una esfera de energía que vuela (va un poco hacia `target`) y se apaga al llegar lejos o al chocar
function CombatFx.orb(origin: Vector3, dir: Vector3, speed: number, range: number, target: Model?, owner: Model?)
	local core = part({ Name = "Esfera", Shape = Enum.PartType.Ball, Size = Vector3.new(1.1, 1.1, 1.1), Color = CombatFx.Colors.EnergyCore, CFrame = CFrame.new(origin) })
	local glow = part({ Name = "EsferaHalo", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), Color = CombatFx.Colors.EnergyGlow, Transparency = 0.55, CFrame = CFrame.new(origin) })
	local light = Instance.new("PointLight")
	light.Color = CombatFx.Colors.EnergyGlow
	light.Range = 8
	light.Brightness = 2
	light.Parent = core
	local pos, d, travelled = origin, if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1), 0
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { fxFolder(), owner :: any }
	local connection: RBXScriptConnection? = nil
	local function finish(hitAt: Vector3?)
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if hitAt then
			sparks(hitAt, CombatFx.Colors.EnergyGlow, 10, 20, 0.9)
		end
		core:Destroy()
		glow:Destroy()
	end
	connection = RunService.Heartbeat:Connect(function(dt)
		local troot = target and target.Parent and target:FindFirstChild("HumanoidRootPart") :: BasePart?
		if troot then
			local want = troot.Position - pos
			if want.Magnitude > 0.5 then
				d = (d + want.Unit * 0.18).Unit
			end
		end
		local stepLength = speed * dt
		local ok, hit = pcall(function()
			return workspace:Raycast(pos, d * stepLength, params)
		end)
		if ok and hit then
			finish(hit.Position)
			return
		end
		pos += d * stepLength
		travelled += stepLength
		core.CFrame = CFrame.new(pos)
		glow.CFrame = CFrame.new(pos)
		if travelled >= range then
			finish(nil)
		end
	end)
	task.delay(range / math.max(speed, 1) + 0.5, function()
		if connection then
			finish(nil)
		end
	end)
end

-- La onda: un haz que sale de las manos, crece hasta `length` y se apaga
function CombatFx.wave(origin: Vector3, dir: Vector3, length: number, width: number, seconds: number?)
	local d = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
	local t = seconds or 0.5
	local function beam(color: Color3, thickness: number, transparency: number)
		local b = part({ Name = "Haz", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, thickness, thickness), Color = color, Transparency = transparency })
		local grow = 0
		local connection: RBXScriptConnection? = nil
		local started = os.clock()
		connection = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - started) / 0.15, 0, 1)
			grow = length * k
			b.Size = Vector3.new(math.max(grow, 0.5), b.Size.Y, b.Size.Z)
			b.CFrame = CFrame.lookAt(origin + d * (grow / 2), origin + d * length) * CFrame.Angles(0, math.rad(90), 0)
			if k >= 1 and connection then
				connection:Disconnect()
				connection = nil
			end
		end)
		task.delay(t, function()
			if connection then
				connection:Disconnect()
			end
			tween(b, 0.3, { Transparency = 1, Size = Vector3.new(b.Size.X, thickness * 0.2, thickness * 0.2) })
			later(0.35, b)
		end)
	end
	beam(CombatFx.Colors.EnergyGlow, width * 1.4, 0.5)
	beam(CombatFx.Colors.EnergyEdge, width * 0.8, 0.25)
	beam(CombatFx.Colors.EnergyCore, width * 0.35, 0)
	flash(origin, CombatFx.Colors.EnergyCore, 1, width * 1.8, 0.3, 0.2)
	SoundFx.play("DisparoTaser", 1, 0.45)
end

-- Explosión de energía (puñetazo explosivo, final de la definitiva)
function CombatFx.explosion(at: Vector3, radius: number)
	flash(at, CombatFx.Colors.EnergyCore, 1, radius * 1.2, 0.35, 0.05)
	flash(at, CombatFx.Colors.EnergyGlow, 2, radius * 2, 0.5, 0.4)
	ring(at, Vector3.new(0, 1, 0), CombatFx.Colors.EnergyGlow, 2, radius * 3, 0.45)
	sparks(at, CombatFx.Colors.EnergyCore, 40, 50, 1.6)
	sparks(at, CombatFx.Colors.Dust, 20, 30, 2.5, SMOKE)
	SoundFx.play("ChoqueFuerte", 1, 0.7)
end

---------------------------------------------------------------------
-- Definitiva: mini-cinemática de cámara (para quien la lanza y para su objetivo)
---------------------------------------------------------------------
local cinematicToken = 0
local cinematicActive = false

local function canTakeCamera(): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and camera.CameraType == Enum.CameraType.Custom and not player:GetAttribute("InCinematic") and not player:GetAttribute("InDialogue")
end

-- Cámara que gira alrededor de `model` durante `windUp` segundos (mientras carga) y luego se coloca
-- detrás para ver el estallido; vuelve sola a la normal.
function CombatFx.ultimateCamera(model: Model, windUp: number)
	if not canTakeCamera() then
		return
	end
	local camera = workspace.CurrentCamera
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	cinematicToken += 1
	local token = cinematicToken
	camera.CameraType = Enum.CameraType.Scriptable
	local started = os.clock()
	local total = windUp + 0.9
	local connection: RBXScriptConnection? = nil
	cinematicActive = true
	local function restore()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if token == cinematicToken and cinematicActive then
			cinematicActive = false
			if camera.CameraType == Enum.CameraType.Scriptable then
				camera.CameraType = Enum.CameraType.Custom
			end
		end
	end
	connection = RunService.RenderStepped:Connect(function()
		if not root.Parent or token ~= cinematicToken then
			restore()
			return
		end
		local t = os.clock() - started
		local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
		local head = root.Position + Vector3.new(0, 1.6, 0)
		if t < windUp then
			-- Gira de delante a un lado, acercándose a la cara
			local k = t / windUp
			local angle = math.rad(25 + 120 * k)
			local side = Vector3.new(-look.Z, 0, look.X)
			local offset = (look * math.cos(angle) + side * math.sin(angle)) * (9 - 3 * k) + Vector3.new(0, 1.2 - 0.6 * k, 0)
			camera.CFrame = CFrame.lookAt(head + offset, head)
		elseif t < total then
			-- Detrás y por encima: se ve salir el estallido
			camera.CFrame = CFrame.lookAt(head - look * 9 + Vector3.new(0, 3.5, 0), head + look * 20)
		else
			restore()
		end
	end)
	task.delay(total + 0.5, restore)
end

function CombatFx.ultimateStart(model: Model?, windUp: number, cinematic: boolean)
	if not model then
		return
	end
	CombatFx.aura(model, true, true)
	PunchAnim.hold(model, "Aim", true)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		flash(root.Position, CombatFx.Colors.EnergyGlow, 2, 12, windUp, 0.6)
		SoundFx.play("DisparoTaser", 0.8, 0.3, root)
	end
	if cinematic then
		CombatFx.ultimateCamera(model, windUp)
	end
	task.delay(windUp + 0.8, function()
		CombatFx.aura(model, false)
		PunchAnim.hold(model, "Aim", false)
	end)
end

function CombatFx.ultimateFire(origin: Vector3, dir: Vector3, length: number, width: number, near: boolean)
	CombatFx.wave(origin, dir, length, width, 0.9)
	task.delay(0.15, function()
		CombatFx.explosion(origin + dir * math.min(length, 14), width * 1.5)
	end)
	if near then
		CameraShake.shake(1.6, 0.6)
	end
end

-- Corta la mini-cinemática de la definitiva (solo si es la nuestra: las de la historia no se tocan)
function CombatFx.cancelCinematic()
	if not cinematicActive then
		return
	end
	cinematicActive = false
	cinematicToken += 1
	local camera = workspace.CurrentCamera
	if camera and camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
	end
end

function CombatFx.inCinematic(): boolean
	return cinematicActive
end

return CombatFx
