-- Locomotion (cliente): que andar, correr y hacer cosas se sienta fluido.
--
-- TU PERSONAJE
--   * Arrancar y parar sin tirones: la dirección y la velocidad que pides (teclado, joystick o
--     mando) se acercan poco a poco a lo que pides (acelera en ~0,2 s y frena en ~0,15 s). Los giros
--     cerrados frenan un poco, como de verdad. Al empezar a correr la velocidad sube suave (y la
--     animación de Roblox pasa de andar a correr sola, porque va con la velocidad real).
--   * Mira hacia donde mira la cámara: la cabeza (y un poco la cintura) giran con suavidad.
--   * Al usar un cartel "pulsa E" se gira hacia el objeto y alarga la mano (o se agacha si está en
--     el suelo, o se lleva la comida a la boca): ReactMotion.gestureFor elige el gesto.
--   * Tras una caída fuerte (traspiés) anda más despacio un momento.
--
-- TODOS LOS JUGADORES CERCANOS (en tu pantalla)
--   * Se inclinan hacia dentro al girar, hacia delante al correr y al acelerar (y atrás al frenar).
--   * Al aterrizar se agachan un poco (según la altura); desde muy alto, traspiés (ReactMotion).
--   * Sentarse en un banco o una silla no es un salto: el cuerpo se desliza hasta el asiento.
--
-- Es la capa 20 de PoseLayers (entre AgeMotion y ReactMotion). Las funciones puras (approach,
-- leanPose, lookPose, landing, glideOffset, fade, ease…) se prueban fuera de Roblox:
-- scripts/test-motion.luau

local Locomotion = {}

local abs, exp, clamp, atan2 = math.abs, math.exp, math.clamp, math.atan2
local angles = CFrame.Angles
local TAU = math.pi * 2

---------------------------------------------------------------------
-- Funciones puras
---------------------------------------------------------------------

-- Curvas 0..1 -> 0..1 (empiezan en 0 y acaban en 1)
function Locomotion.ease(t: number): number -- suave al entrar y al salir
	local x = clamp(t, 0, 1)
	return x * x * (3 - 2 * x)
end
function Locomotion.easeOut(t: number): number -- rápido al principio, se posa suave
	local x = 1 - clamp(t, 0, 1)
	return 1 - x * x * x
end

-- Se acerca a target sin pasarse (exponencial: igual a cualquier número de frames por segundo)
function Locomotion.smooth(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - exp(-rate * math.max(dt, 0)))
end

-- Peso de una animación que entra o sale en `seconds` (lineal y siempre entre 0 y 1)
function Locomotion.fade(weight: number, on: boolean, dt: number, seconds: number): number
	local step = if seconds > 0 then dt / seconds else 1
	return clamp(weight + (if on then step else -step), 0, 1)
end

-- Velocidad que se acerca a la pedida: acelera con `accel`, frena con `decel` (más rápido)
function Locomotion.approach(current: Vector3, target: Vector3, dt: number, accel: number, decel: number): Vector3
	local rate = if target.Magnitude >= current.Magnitude - 1e-3 then accel else decel
	local out = current:Lerp(target, 1 - exp(-rate * math.max(dt, 0)))
	if (out - target).Magnitude < 0.02 then
		return target
	end
	return out
end

-- Diferencia entre dos ángulos, entre -pi y pi
function Locomotion.angleDelta(from: number, to: number): number
	return (to - from + math.pi) % TAU - math.pi
end

-- Hacia dónde mira un CFrame (giro alrededor de Y; 0 = hacia -Z, positivo = a su izquierda)
function Locomotion.yawOf(cf: CFrame): number
	local look = cf.LookVector
	return atan2(-look.X, -look.Z)
end

-- Inclinarse: turn = giro (rad/s, positivo a la izquierda), speed = velocidad / velocidad de andar,
-- accel = aceleración hacia delante (studs/s²), sprint = 0..1
function Locomotion.leanPose(turn: number, speed: number, accel: number, sprint: number): { [string]: CFrame }
	local s = clamp(speed, 0, 2)
	local roll = clamp(turn * s * 0.07, -0.2, 0.2)
	local pitch = clamp(-0.09 * clamp(sprint, 0, 1) - 0.004 * clamp(accel, -40, 40) * math.min(s, 1), -0.24, 0.1)
	return {
		Root = angles(pitch, 0, roll),
		Waist = angles(-pitch * 0.3, 0, -roll * 0.45), -- el pecho compensa un poco: la cabeza va recta
	}
end

-- Mirar hacia la cámara: yaw/pitch relativos al cuerpo; weight 0..1
function Locomotion.lookPose(yaw: number, pitch: number, weight: number): { [string]: CFrame }
	local w = clamp(weight, 0, 1)
	local y = clamp(yaw, -1.2, 1.2) * w
	local p = clamp(pitch, -0.8, 0.8) * w
	return {
		Neck = angles(p * 0.5, y * 0.45, 0),
		Waist = angles(p * 0.1, y * 0.15, 0),
	}
end

-- Dirección de la cámara respecto al cuerpo: (yaw, pitch, cuánto conviene girar la cabeza 0..1).
-- Si la cámara mira al personaje de frente, no se gira (quedaría mirando hacia atrás).
function Locomotion.cameraLook(root: CFrame, look: Vector3): (number, number, number)
	local dir = root:VectorToObjectSpace(look)
	local flat = math.sqrt(dir.X * dir.X + dir.Z * dir.Z)
	if flat < 1e-4 then
		return 0, 0, 0
	end
	local yaw = atan2(-dir.X, -dir.Z)
	local pitch = atan2(dir.Y, flat)
	local facing = 1 - Locomotion.ease((abs(yaw) - 1.4) / 0.7)
	return yaw, pitch, facing
end

-- Qué hace el cuerpo al tocar el suelo tras caer a `fallSpeed` (studs/s hacia abajo):
-- nil (nada), "Land" (agacharse un poco), "Stumble" (traspiés) o "Roll" (voltereta), y la fuerza 0..1
-- (runSpeed: velocidad al caer; corriendo, desde muy alto se rueda en lugar de tropezar)
function Locomotion.landing(fallSpeed: number, runSpeed: number?): (string?, number)
	if fallSpeed < 32 then
		return nil, 0
	elseif fallSpeed > 88 then
		return if (runSpeed or 0) > 14 then "Roll" else "Stumble", 1
	end
	return "Land", clamp((fallSpeed - 32) / 50, 0.15, 1)
end

-- Deslizarse al sentarse: el cuerpo empieza donde estaba (from) y llega al asiento (root) con curva.
-- Devuelve el retoque de la articulación Root (su C0 es c0) para este momento (t 0..1)
function Locomotion.glideOffset(root: CFrame, from: CFrame, c0: CFrame, t: number): CFrame
	local visual = from:Lerp(root, Locomotion.easeOut(t))
	local offset = root:ToObjectSpace(visual) -- dónde se ve, visto desde donde está de verdad
	return c0:Inverse() * offset * c0
end

-- Campo de visión al correr (un poco más abierto: sensación de velocidad)
function Locomotion.fov(base: number, sprint: number): number
	return base + 7 * clamp(sprint, 0, 1)
end

---------------------------------------------------------------------
-- En Roblox
---------------------------------------------------------------------

-- Para otros sistemas (armas…): la postura de tu personaje ("Stand", "Crouch" o "Prone") y si está
-- ocupado moviéndose (saltando un obstáculo, tumbándose o levantándose: el arma se baja). También
-- están los atributos del jugador "Stance" (del servidor, lo ven todos) y "BusyMove" (solo tuyo).
local StancesModule: any = nil
function Locomotion.stance(): string
	if StancesModule then
		return StancesModule.current()
	end
	return "Stand"
end
function Locomotion.busyMove(): boolean
	local Players = game:GetService("Players")
	return Players.LocalPlayer:GetAttribute("BusyMove") == true
end

local ACTIVE_DISTANCE = 90
local ACCEL, DECEL = 11, 15 -- ritmo de arrancar y de frenar
local GLIDE_TIME = 0.3

type Body = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Player: Player?,
	Joints: { [string]: Motor6D },
	Yaw: number,
	Turn: number,
	Speed: number,
	Accel: number,
	Sprint: number,
	Weight: number, -- 0..1: cuánto se aplica (se quita al sentarse, nadar, trepar…)
	Look: number, -- 0..1: cuánto mira hacia la cámara (solo tu personaje)
	LookYaw: number,
	LookPitch: number,
	Fall: number, -- velocidad de caída más fuerte desde que dejó el suelo
	GlideFrom: CFrame?,
	GlideStart: number,
	Seat: Instance?,
}

local bodies: { [Model]: Body } = {}
local Layers: any, ReactMotion: any, Cinematics: any, Joystick: any, Stances: any, Parkour: any
local player: Player
local stumbleUntil = 0
local faceYaw: number? = nil
local faceUntil = 0

local function gesturing(humanoid: Humanoid): boolean
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return false
	end
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Priority == Enum.AnimationPriority.Action and track.WeightCurrent > 0.1 then
			return true
		end
	end
	return false
end

local function bodyOf(model: Model): Body?
	local body = bodies[model]
	if body then
		return body
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	local joints = {}
	for name, part in { Root = "LowerTorso", Waist = "UpperTorso", Neck = "Head" } do
		local p = model:FindFirstChild(part)
		local motor = p and p:FindFirstChild(name)
		if motor and motor:IsA("Motor6D") then
			joints[name] = motor
		end
	end
	local newBody: Body = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Player = game:GetService("Players"):GetPlayerFromCharacter(model),
		Joints = joints,
		Yaw = Locomotion.yawOf(root.CFrame),
		Turn = 0,
		Speed = 0,
		Accel = 0,
		Sprint = 0,
		Weight = 0,
		Look = 0,
		LookYaw = 0,
		LookPitch = 0,
		Fall = 0,
		GlideFrom = nil,
		GlideStart = 0,
		Seat = humanoid.SeatPart,
	}
	bodies[model] = newBody
	-- Al sentarse: se apunta dónde estaba para deslizarse hasta el asiento
	humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		local seat = humanoid.SeatPart
		if seat and seat ~= newBody.Seat then
			newBody.GlideFrom = root.CFrame
			newBody.GlideStart = os.clock()
		end
		newBody.Seat = seat
	end)
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			bodies[model] = nil
		end
	end)
	return newBody
end

local FREE_STATES = {
	[Enum.HumanoidStateType.Running] = true,
	[Enum.HumanoidStateType.RunningNoPhysics] = true,
	[Enum.HumanoidStateType.Jumping] = true,
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.Landed] = true,
}

local function update(body: Body, dt: number, now: number)
	local humanoid, root = body.Humanoid, body.Root
	if dt <= 0 then
		return
	end
	local mine = body.Model == player.Character
	local state = humanoid:GetState()
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local walk = math.max(humanoid.WalkSpeed, 1)

	-- Giro y aceleración (suavizados)
	local yaw = Locomotion.yawOf(root.CFrame)
	local turn = clamp(Locomotion.angleDelta(body.Yaw, yaw) / dt, -12, 12)
	body.Yaw = yaw
	body.Turn = Locomotion.smooth(body.Turn, if speed > 1 then turn else 0, 8, dt)
	body.Accel = Locomotion.smooth(body.Accel, clamp((speed - body.Speed) / dt, -60, 60), 6, dt)
	body.Speed = speed
	local sprinting = body.Player ~= nil and body.Player:GetAttribute("Sprinting") == true and speed > walk * 0.6
	body.Sprint = Locomotion.smooth(body.Sprint, if sprinting then 1 else 0, 4, dt)

	local free = FREE_STATES[state] == true and humanoid.SeatPart == nil and not humanoid.PlatformStand
	-- Tumbado o saltando un obstáculo manda su propia postura (sin inclinarse ni girar la cabeza)
	if (Stances and Stances.proneWeight(body.Model) > 0.3) or (Parkour and Parkour.isVaulting(body.Model)) then
		free = false
	end
	if body.Player and body.Player:GetAttribute("Crawling") then
		free = false -- gateando manda AgeMotion
	end
	body.Weight = Locomotion.smooth(body.Weight, if free then 1 else 0, 6, dt)

	-- Aterrizar: la caída más fuerte desde que dejó el suelo
	if state == Enum.HumanoidStateType.Swimming or humanoid.SeatPart or (Parkour and Parkour.isVaulting(body.Model)) then
		body.Fall = 0
	elseif v.Y < -8 then
		body.Fall = math.max(body.Fall, -v.Y)
	elseif v.Y > -3 and body.Fall > 0 then
		local kind, strength = Locomotion.landing(body.Fall, speed)
		body.Fall = 0
		if kind and ReactMotion then
			ReactMotion.play(body.Model, kind, { Strength = strength })
			if mine and kind == "Stumble" then
				stumbleUntil = now + 0.7
			end
		end
	end

	-- Mirar hacia la cámara (solo el tuyo: la cámara de los demás no se sabe)
	local lookWanted = 0
	if mine then
		local camera = workspace.CurrentCamera
		local head = body.Model:FindFirstChild("Head") :: BasePart?
		local third = head ~= nil and (camera.CFrame.Position - head.Position).Magnitude > 2
		if camera.CameraType == Enum.CameraType.Custom and third and free and not gesturing(humanoid) then
			local y, p, facing = Locomotion.cameraLook(root.CFrame, camera.CFrame.LookVector)
			body.LookYaw = Locomotion.smooth(body.LookYaw, y, 7, dt)
			body.LookPitch = Locomotion.smooth(body.LookPitch, p, 7, dt)
			lookWanted = facing
		end
	end
	body.Look = Locomotion.smooth(body.Look, lookWanted, 5, dt)

	-- Retoques
	local pose: { [string]: CFrame } = {}
	if body.Weight > 0.01 then
		local lean = Locomotion.leanPose(body.Turn, speed / walk, body.Accel, body.Sprint)
		for name, cf in lean do
			pose[name] = CFrame.identity:Lerp(cf, body.Weight)
		end
	end
	if body.Look > 0.01 then
		for name, cf in Locomotion.lookPose(body.LookYaw, body.LookPitch, body.Look) do
			pose[name] = if pose[name] then pose[name] * cf else cf
		end
	end
	-- Deslizarse hasta el asiento
	local glide: CFrame? = nil
	if body.GlideFrom then
		local t = (now - body.GlideStart) / GLIDE_TIME
		local jump = (root.Position - body.GlideFrom.Position).Magnitude
		if t >= 1 or jump > 10 then
			body.GlideFrom = nil -- (un salto enorme es un viaje: no se desliza)
		elseif jump > 0.05 and body.Joints.Root then
			glide = Locomotion.glideOffset(root.CFrame, body.GlideFrom, body.Joints.Root.C0, t)
		end
	end
	if glide then
		pose.Root = if pose.Root then glide * pose.Root else glide
	end
	for name, cf in pose do
		local joint = body.Joints[name]
		if joint then
			Layers.write(joint, cf * Layers.read(joint))
		end
	end
end

---------------------------------------------------------------------
-- Mover tu personaje con suavidad
---------------------------------------------------------------------
local controls: any = nil
local velocity = Vector3.zero -- lo que se pide ahora (studs/s)
local smoothing = false -- si este frame hemos corregido lo que pedía el control

local function blockedMove(humanoid: Humanoid): boolean
	local state = humanoid:GetState()
	return humanoid.SeatPart ~= nil
		or humanoid.PlatformStand
		or humanoid.Health <= 0
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Dead
		or player:GetAttribute("Riding") ~= nil
		or player:GetAttribute("Training") ~= nil
		or player:GetAttribute("InDialogue") == true
		or (Cinematics ~= nil and Cinematics.isPlaying())
		or (Parkour ~= nil and Parkour.isVaulting())
end

local function moveStep(dt: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or not controls then
		velocity = Vector3.zero
		return
	end
	if blockedMove(humanoid) then
		if smoothing then
			smoothing = false
			velocity = Vector3.zero
		end
		return
	end
	local ok, raw = pcall(function()
		-- En el móvil, el joystick propio del HUD (el de Roblox no está)
		local stick = if Joystick and Joystick.active() then Joystick.moveVector() else nil
		if stick and stick.Magnitude > 0 then
			return stick
		end
		return controls:GetMoveVector()
	end)
	if not ok or typeof(raw) ~= "Vector3" then
		return
	end
	-- Lo que pide el control es relativo a la cámara (solo su giro horizontal)
	local camera = workspace.CurrentCamera
	local _, camYaw = camera.CFrame:ToEulerAnglesYXZ()
	local wanted = CFrame.fromEulerAnglesYXZ(0, camYaw, 0):VectorToWorldSpace(raw)
	wanted = Vector3.new(wanted.X, 0, wanted.Z)
	if wanted.Magnitude > 1 then
		wanted = wanted.Unit
	end
	local now = os.clock()
	-- Girarse hacia lo que acabas de usar (si no te mueves)
	if faceYaw and now < faceUntil and wanted.Magnitude < 0.05 then
		local current = Locomotion.yawOf(root.CFrame)
		local step = Locomotion.angleDelta(current, faceYaw) * (1 - exp(-16 * dt))
		root.CFrame = CFrame.new(root.Position) * CFrame.fromEulerAnglesYXZ(0, current + step, 0)
	elseif now >= faceUntil then
		faceYaw = nil
	end
	local walk = humanoid.WalkSpeed
	if walk <= 0.1 then
		velocity = Vector3.zero
		return
	end
	-- Agachado o tumbado se va más despacio (Stances); tras un traspiés, un momento más lento
	local factor = (if now < stumbleUntil then 0.35 else 1) * (if Stances then Stances.speedFactor() else 1)
	local target = wanted * walk * factor
	velocity = Locomotion.approach(velocity, target, dt, ACCEL, DECEL)
	if velocity.Magnitude > walk then
		velocity = velocity.Unit * walk
	end
	local move = velocity / walk
	if (move - wanted).Magnitude < 1e-3 then
		-- Ya vamos como pide el control: no hace falta corregir nada
		if smoothing and wanted.Magnitude < 1e-3 then
			humanoid:Move(Vector3.zero, false)
		end
		smoothing = false
		return
	end
	smoothing = true
	humanoid:Move(move, false)
end

-- Girarse hacia un punto (lo usan el cartel "pulsa E" y otros sistemas)
function Locomotion.face(position: Vector3, seconds: number?)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local flat = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	faceYaw = atan2(-flat.X, -flat.Z)
	faceUntil = os.clock() + (seconds or 0.35)
end

---------------------------------------------------------------------
-- Gesto al usar un cartel "pulsa E"
---------------------------------------------------------------------
local function promptPosition(prompt: ProximityPrompt): Vector3?
	local parent = prompt.Parent
	if parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	elseif parent and parent:IsA("BasePart") then
		return parent.Position
	elseif parent and parent:IsA("Model") then
		local ok, pivot = pcall(function()
			return parent:GetPivot()
		end)
		return if ok then pivot.Position else nil
	end
	return nil
end

local function onPrompt(prompt: ProximityPrompt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or blockedMove(humanoid) or player:GetAttribute("KO") then
		return
	end
	local at = promptPosition(prompt)
	if not at then
		return
	end
	if prompt:GetAttribute("NoGesture") then
		return -- los muebles con postura propia (grifo, nevera, piano…): UseMotion
	end
	local kind = ReactMotion.gestureFor(prompt.ActionText, 0)
	if kind == nil then
		return -- sentarse, montar, hablar…: lo hace su propia animación
	end
	Locomotion.face(at, 0.35)
	if gesturing(humanoid) then
		return -- ya hay otra animación (un gesto, un baile…)
	end
	-- Altura del objeto: -1 a ras de suelo, 0 a la cintura, 1 por encima de la cabeza
	local waist = humanoid.HipHeight + root.Size.Y / 2
	local height = clamp((at.Y - root.Position.Y) / math.max(waist, 1), -1, 1)
	kind = ReactMotion.gestureFor(prompt.ActionText, height)
	if kind then
		ReactMotion.play(character, kind, { Height = height })
	end
end

---------------------------------------------------------------------

function Locomotion.init()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local ProximityPromptService = game:GetService("ProximityPromptService")
	player = Players.LocalPlayer
	Layers = require(script.Parent.PoseLayers)
	ReactMotion = require(script.Parent.ReactMotion)
	Cinematics = require(script.Parent.Cinematics)
	Joystick = require(script.Parent.Joystick)
	Stances = require(script.Parent.Stances)
	StancesModule = Stances
	Parkour = require(script.Parent.Parkour)

	-- El control de Roblox (teclado, joystick y mando): lo que pide cada frame
	task.spawn(function()
		local ok, module = pcall(function()
			return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 30) :: any)
		end)
		if ok and module then
			local got, result = pcall(function()
				return module:GetControls()
			end)
			controls = if got then result else nil
		end
	end)
	-- Justo después de que el control pida el movimiento (y antes de la física)
	RunService:BindToRenderStep("MovimientoSuave", Enum.RenderPriority.Input.Value + 1, function(dt)
		local ok, err = pcall(moveStep, dt)
		if not ok then
			warn("[Locomotion] " .. tostring(err))
		end
	end)
	player.CharacterAdded:Connect(function()
		velocity = Vector3.zero
		smoothing = false
		stumbleUntil = 0
		faceYaw = nil
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who == player then
			pcall(onPrompt, prompt)
		end
	end)

	-- Quién está cerca: los jugadores (cada medio segundo)
	local active: { Body } = {}
	task.spawn(function()
		while true do
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position or Vector3.zero
			local list = {}
			for _, other in Players:GetPlayers() do
				local character = other.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if character and root and (root.Position - from).Magnitude < ACTIVE_DISTANCE then
					local body = bodyOf(character)
					if body then
						table.insert(list, body)
					end
				end
			end
			active = list
			task.wait(0.5)
		end
	end)

	Layers.add("Locomotion", 20, function(dt, now)
		for _, body in active do
			if body.Model.Parent and body.Humanoid.Health > 0 then
				local ok, err = pcall(update, body, dt, now)
				if not ok then
					warn("[Locomotion] " .. tostring(err))
					bodies[body.Model] = nil
				end
			end
		end
	end)
end

return Locomotion
