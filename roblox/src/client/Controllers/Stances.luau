-- Stances (cliente): agacharse y tumbarse.
--
-- CONTROLES
--   Ordenador: Ctrl izquierdo agacharse / levantarse; mantenerlo medio segundo, tumbarse.
--   Mando:     cruceta abajo (con el menú de comandos plegado) igual: tocar agacharse, mantener tumbarse.
--   Móvil:     botón "Agacharse" del racimo (UI/TouchLayout): tocar agacharse, mantener tumbarse.
--   Saltar o correr estando agachado o tumbado: te levantas (si hay sitio encima).
--
-- CÓMO SE VE (en todos los jugadores: sale del atributo "Stance" que pone el servidor)
--   * Agachado: la cadera baja Movement.CrouchDepth del largo de la pierna y cada pie va a su sitio
--     con IK de dos huesos (Stances.legIK): rodillas dobladas y algo abiertas, pies planos en el
--     suelo (siguen el escalón o la cuesta que tengan debajo), la cadera inclinada, el pecho algo
--     adelante, la cabeza al frente y los brazos listos. Quieto respira; andando da pasos cortos
--     propios (Stances.gaitFoot/gaitRate: el pie apoyado va justo a la velocidad del cuerpo, no
--     patina) con la cadera que sube y baja y los brazos contrarios a las piernas. Va al 45 %.
--   * Tumbado: boca abajo siguiendo la cuesta del suelo, apoyado en los codos; se arrastra (codo y
--     rodilla contrarios) al 25 % de velocidad. Al tumbarse primero dobla las rodillas y luego baja.
--   Tu personaje es más bajo de verdad (HipHeight, R15), así cabes por debajo de las cosas; la
--   cámara baja con él. R6 (sin rodillas): el tronco baja con una pierna adelante y otra atrás, y no
--   se tumba.
--   Todo entra y sale en Movement.Transition (con curva): nada salta de golpe.
--
-- NO SE PUEDE: montado, sentado, nadando, trepando una escalera, caído (PlatformStand), en una escena
-- o entrenando, de bebé (ya gatea); tumbarse tampoco en cuestas de más de 25°, en escaleras, en el
-- agua ni donde no cabes tumbado (entonces te quedas agachado). Si pasa algo de eso estando agachado,
-- te levantas solo. Levantarse necesita sitio encima.
--
-- Para otros sistemas (las armas): Stances.current(), Stances.speedFactor(), Stances.crouchWeight(model),
-- el atributo "Stance" del jugador y "BusyMove" (true mientras te tumbas o te levantas: baja el arma).
-- Es la capa 17 de PoseLayers (después de RidePose y antes de Locomotion). Las posturas son funciones
-- puras: scripts/test-parkour.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Movement = require(ReplicatedStorage.Shared.Movement)
local Joints = require(ReplicatedStorage.Shared.Joints)

local Stances = {}

local angles = CFrame.Angles
local sin, max, clamp = math.sin, math.max, math.clamp
local HALF_PI = math.pi / 2

---------------------------------------------------------------------
-- Posturas (funciones puras)
---------------------------------------------------------------------

-- Paso agachado: cuánto del ciclo apoya cada pie (el resto va por el aire), lo que sube el pie
-- (en largos de pierna) y el ritmo (pasos por segundo según la velocidad, en largos de pierna)
Stances.Gait = { Duty = 0.6, Lift = 0.13, BaseHz = 0.8, HzPerLeg = 0.26, MaxStride = 1.2 }

-- Un pie a lo largo del ciclo (u 0..1; el derecho empieza apoyado y adelantado). Devuelve dónde va a
-- lo largo del paso (+0.5 delante .. -0.5 detrás, en zancadas) y cuánto sube (0..1).
-- Apoyado, va hacia atrás a ritmo constante (a la velocidad del cuerpo: no patina); por el aire
-- vuelve adelante con una curva que empieza y acaba a esa misma velocidad (sin tirones al pisar).
function Stances.gaitFoot(u: number, duty: number): (number, number)
	u = u % 1
	duty = clamp(duty, 0.2, 0.9)
	if u < duty then
		return 0.5 - u / duty, 0
	end
	local v = (u - duty) / (1 - duty)
	local m = -(1 - duty) / duty -- la pendiente del apoyo, en este tramo
	local v2, v3 = v * v, v * v * v
	local along = -0.5 * (2 * v3 - 3 * v2 + 1) + m * (v3 - 2 * v2 + v) + 0.5 * (-2 * v3 + 3 * v2) + m * (v3 - v2)
	local up = sin(math.pi * v)
	return along, up * up
end

-- Ritmo del paso agachado: (ciclos por segundo, zancada en studs). leg = cadera a tobillo.
-- Con esa zancada el pie apoyado va justo a la velocidad del cuerpo (zancada = v · apoyo / ritmo);
-- si la pierna no llega, la zancada se recorta.
function Stances.gaitRate(speed: number, leg: number): (number, number)
	local G = Stances.Gait
	local l = max(leg, 0.2)
	local v = max(speed, 0)
	local hz = G.BaseHz + G.HzPerLeg * v / l
	local stride = math.min(v * G.Duty / hz, G.MaxStride * l)
	return hz, stride
end

-- Pierna de dos huesos: target = dónde tiene que quedar el tobillo, visto desde la cadera (Y arriba,
-- -Z delante); thigh/shin = muslo y espinilla. Devuelve los Transform de cadera y rodilla: la
-- rodilla dobla hacia atrás y apunta hacia donde va el pie. (Si no llega, se estira hacia allí.)
function Stances.legIK(target: Vector3, thigh: number, shin: number): (CFrame, CFrame)
	local a, b = max(thigh, 0.05), max(shin, 0.05)
	local dist = target.Magnitude
	local dir = if dist > 1e-4 then target / dist else Vector3.new(0, -1, 0)
	local d = clamp(dist, math.abs(a - b) + 1e-3, (a + b) * 0.9995)
	local bend = math.pi - math.acos(clamp((a * a + b * b - d * d) / (2 * a * b), -1, 1))
	local alpha = math.acos(clamp((a * a + d * d - b * b) / (2 * a * d), -1, 1))
	local roll = math.asin(clamp(dir.X, -1, 1))
	local pitch = math.atan2(-dir.Z, -dir.Y)
	return angles(pitch, 0, 0) * angles(0, 0, roll) * angles(alpha, 0, 0), angles(-bend, 0, 0)
end

-- Agachado (tronco, brazos y cabeza; las piernas, si se dan, con los ángulos de Movement.crouchLegs).
-- w 0..1, move 0..1 (quieto → andando), phase = paso (radianes; el pie derecho delante en 0),
-- breath = respiración (-1..1). Pelvis = giro de la cadera (la articulación Root).
function Stances.crouchPose(w: number, hip: number, knee: number, ankle: number, move: number, phase: number, breath: number?): { [string]: CFrame }
	local m = clamp(move, 0, 1) * w
	local still = (1 - clamp(move, 0, 1)) * w
	local b = (breath or 0) * still
	local c = math.cos(phase)
	local swing = 0.32 * m * c -- brazos contrarios a las piernas
	return {
		-- La cadera se inclina adelante (flexión de cadera) y se gira un poco con cada paso
		Pelvis = angles(-0.28 * w - 0.05 * m, 0.09 * m * c, 0.03 * m * sin(phase)),
		-- El pecho sigue algo más adelante y contrarresta el giro de la cadera; respira
		Waist = angles(-0.14 * w - 0.05 * m + 0.018 * b, -0.12 * m * c, 0),
		Neck = angles(0.36 * w + 0.08 * m - 0.01 * b, 0.03 * m * c, 0), -- mira al frente
		RightShoulder = angles(0.22 * w - swing, 0, 0.1 * w),
		LeftShoulder = angles(0.22 * w + swing, 0, -0.1 * w),
		RightElbow = angles(0.5 * w + 0.18 * m * max(0, c), 0, 0),
		LeftElbow = angles(0.5 * w + 0.18 * m * max(0, -c), 0, 0),
		RightHip = angles(hip, 0, 0),
		LeftHip = angles(hip, 0, 0),
		RightKnee = angles(knee, 0, 0),
		LeftKnee = angles(knee, 0, 0),
		RightAnkle = angles(ankle, 0, 0),
		LeftAnkle = angles(ankle, 0, 0),
	}
end

-- Tumbado: postura entera (sustituye a la animación). move 0..1, phase = paso, pitch/roll = cuesta
-- (Movement.slopeAngles), drop = cuánto baja el cuerpo para tocar el suelo
function Stances.pronePose(move: number, phase: number, pitch: number, roll: number, drop: number): { [string]: CFrame }
	local s = sin(phase) * move
	local r, l = max(0, s), max(0, -s)
	return {
		Root = CFrame.new(0, drop, 0) * angles(pitch, 0, 0) * angles(0, 0, roll) * angles(-HALF_PI, 0, 0),
		Waist = angles(0, 0.06 * s, 0.04 * s),
		Neck = angles(1.15, -0.05 * s, 0), -- la cabeza levantada: mira al frente
		-- Codos en el suelo: el brazo de un lado se adelanta mientras la rodilla del otro sube
		RightShoulder = angles(1.95 + 0.4 * s, 0, 0.3),
		LeftShoulder = angles(1.95 - 0.4 * s, 0, -0.3),
		RightElbow = angles(1.45 - 0.35 * r, 0, 0),
		LeftElbow = angles(1.45 - 0.35 * l, 0, 0),
		RightWrist = CFrame.identity,
		LeftWrist = CFrame.identity,
		RightHip = angles(-0.05 + 0.25 * l, 0, 0.12 + 0.45 * l),
		LeftHip = angles(-0.05 + 0.25 * r, 0, -0.12 - 0.45 * r),
		RightKnee = angles(-0.9 * l, 0, 0),
		LeftKnee = angles(-0.9 * r, 0, 0),
		RightAnkle = angles(-0.7, 0, 0), -- puntas hacia atrás
		LeftAnkle = angles(-0.7, 0, 0),
	}
end

-- Velocidad según los pesos de agachado y tumbado (0..1 cada uno)
function Stances.blendSpeed(crouch: number, prone: number): number
	local c, p = clamp(crouch, 0, 1), clamp(prone, 0, 1)
	local standing = 1 + (Movement.Speed.Crouch - 1) * c
	return standing + (Movement.Speed.Prone - standing) * p
end

---------------------------------------------------------------------
-- En Roblox
---------------------------------------------------------------------
local JOINTS = {
	Root = "LowerTorso", Waist = "UpperTorso", Neck = "Head",
	RightShoulder = "RightUpperArm", LeftShoulder = "LeftUpperArm", RightElbow = "RightLowerArm", LeftElbow = "LeftLowerArm",
	RightWrist = "RightHand", LeftWrist = "LeftHand",
	RightHip = "RightUpperLeg", LeftHip = "LeftUpperLeg", RightKnee = "RightLowerLeg", LeftKnee = "LeftLowerLeg",
	RightAnkle = "RightFoot", LeftAnkle = "LeftFoot",
}
-- R6 (sin rodillas): nombre de la articulación -> pieza donde está
local JOINTS_R6 = {
	Root = { "HumanoidRootPart", "RootJoint" }, Neck = { "Torso", "Neck" },
	RightShoulder = { "Torso", "Right Shoulder" }, LeftShoulder = { "Torso", "Left Shoulder" },
	RightHip = { "Torso", "Right Hip" }, LeftHip = { "Torso", "Left Hip" },
}
local ARM_JOINTS = { RightShoulder = true, LeftShoulder = true, RightElbow = true, LeftElbow = true }
local TAU = math.pi * 2

-- Articulaciones: Motor6D o AnimationConstraint (las articulaciones nuevas de los avatares de Roblox,
-- las que tiene el juego publicado). Antes solo se aceptaba Motor6D: con las nuevas no se encontraba
-- ninguna, el cuerpo no se llevaba y agacharse no hacía nada (ni bajar ni doblar las piernas).
-- Las dos tienen Transform; C0/C1 y las piezas de una AnimationConstraint salen de sus Attachment
-- (shared/Joints).
local jointC0, jointC1, jointPart1 = Joints.c0, Joints.c1, Joints.part1
-- La articulación `name` en su pieza (o, si no está ahí, en cualquier parte del personaje)
local function findJoint(model: Model, partName: string, name: string): any
	return Joints.find(model, name, partName)
end
Stances._jointC0, Stances._jointC1, Stances._jointPart1 = jointC0, jointC1, jointPart1

type Leg = {
	Side: number, -- 1 derecha, -1 izquierda
	Hip: Motor6D,
	Knee: Motor6D,
	Ankle: Motor6D,
	Ground: number, -- lo que sube (+) o baja el suelo bajo este pie respecto al del cuerpo (suavizado)
	Normal: Vector3, -- inclinación del suelo bajo el pie (en el espacio de la raíz, suavizada)
}

type Body = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Player: Player,
	R6: boolean,
	Joints: { [string]: Motor6D },
	Legs: { Leg },
	Crouch: number,
	Prone: number,
	Phase: number, -- paso tumbado (radianes)
	Step: number, -- paso agachado (0..1 del ciclo)
	Move: number, -- 0..1 quieto → andando (suavizado)
	Speed: number, -- velocidad en el suelo (suavizada: el paso no tiembla)
	Dir: Vector3, -- hacia dónde anda, en el espacio de la raíz (suavizado)
	Seed: number,
	LastPos: Vector3,
	Gesture: boolean, -- suena una animación de acción (gesto, baile): los brazos son suyos
	GestureAt: number,
	Pitch: number,
	Roll: number,
	Lowest: number?, -- punto más bajo del cuerpo tumbado (sin bajarlo), respecto a la cadera
	Scale: number,
}

local bodies: { [Model]: Body } = {}
local Layers: any, AgeMotion: any, Cinematics: any, Parkour: any
local player: Player
local current = "Stand"
local changedAt = 0
local busyToken = 0
local remote: RemoteEvent? = nil
local jumpBlocks: { [string]: boolean } = {}
local standHip: number? = nil -- HipHeight de pie (lo que pone el servidor según la edad)
local writtenHip: number? = nil

function Stances.current(): string
	return current
end

-- Velocidad de tu personaje ahora mismo (1 de pie; suave en los cambios)
local localBody: Body? = nil
function Stances.speedFactor(): number
	if localBody and localBody.Model == (player and player.Character) then
		return Stances.blendSpeed(localBody.Crouch, localBody.Prone)
	end
	return Movement.speedFactor(current)
end

-- ¿Cuánto está tumbado ese personaje? (0..1; Locomotion no lo inclina tumbado)
function Stances.proneWeight(model: Model?): number
	local body = model and bodies[model]
	return if body then body.Prone else 0
end

-- ¿Cuánto está agachado (y no tumbado) ese personaje, tal como se ve? (0..1; nil si no se lleva la
-- cuenta de él). Lo usan Locomotion (inclinarse sin mover los pies) y WeaponMotion (el tronco).
function Stances.crouchWeight(model: Model?): number?
	local body = model and bodies[model]
	if not body then
		return nil
	end
	local c = body.Crouch
	local p = body.Prone
	return (c * c * (3 - 2 * c)) * (1 - p * p * (3 - 2 * p))
end

-- Otros sistemas pueden impedir saltar un momento (Parkour: con un obstáculo delante salta él)
local function applyJumpBlock()
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, next(jumpBlocks) == nil)
	end
end
function Stances.blockJump(reason: string, on: boolean)
	if (jumpBlocks[reason] == true) == on then
		return
	end
	jumpBlocks[reason] = on or nil
	applyJumpBlock()
end

local function parts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function rayParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance, workspace.CurrentCamera :: Instance }
	params.IgnoreWater = false
	params.RespectCanCollide = true
	return params
end

local function toast(text: string)
	pcall(function()
		require(script.Parent.Parent.UI.Hud).toast("Info", text)
	end)
end

local RAGDOLL_STATES = {
	[Enum.HumanoidStateType.Physics] = true,
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.GettingUp] = true,
	[Enum.HumanoidStateType.Dead] = true,
}

local function context(humanoid: Humanoid): Movement.StanceContext
	local state = humanoid:GetState()
	local scene = false
	if Cinematics then
		local ok, on = pcall(Cinematics.isOnScreen)
		scene = ok and on == true
	end
	return {
		Stage = player:GetAttribute("LifeStage"),
		Crawling = player:GetAttribute("Crawling") == true,
		Riding = player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil,
		Seated = humanoid.SeatPart ~= nil or humanoid.Sit,
		Swimming = state == Enum.HumanoidStateType.Swimming or player:GetAttribute("SwimMode") ~= nil, -- (Swimming.luau)
		Climbing = state == Enum.HumanoidStateType.Climbing,
		Ragdoll = humanoid.PlatformStand or RAGDOLL_STATES[state] == true,
		Busy = scene or player:GetAttribute("Training") ~= nil,
		Dead = humanoid.Health <= 0,
		KO = player:GetAttribute("KO") == true,
	}
end

-- ¿Cabe de pie? (nada encima hasta la altura de la cabeza; se mira en el centro y en las cuatro
-- esquinas del cuerpo: un borde de techo encima del hombro también cuenta)
local function roomToStand(humanoid: Humanoid, root: BasePart): boolean
	local scale = (root.Parent :: Model):GetScale()
	local floor = root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
	local tall = (standHip or humanoid.HipHeight) + root.Size.Y / 2 + 2.3 * scale
	local params = rayParams()
	local cf = root.CFrame
	for _, offset in { Vector3.zero, Vector3.new(0.7, 0, 0.35), Vector3.new(-0.7, 0, 0.35), Vector3.new(0.7, 0, -0.35), Vector3.new(-0.7, 0, -0.35) } do
		local at = cf:PointToWorldSpace(offset * scale)
		local from = Vector3.new(at.X, floor + 0.4, at.Z)
		if workspace:Raycast(from, Vector3.new(0, tall - 0.4, 0), params) then
			return false
		end
	end
	return true
end

-- ¿Se puede tumbar aquí? (nil = sí; si no, por qué)
local function proneBlocker(humanoid: Humanoid, root: BasePart): string?
	local params = rayParams()
	local scale = (root.Parent :: Model):GetScale()
	local height = humanoid.HipHeight + root.Size.Y / 2 + 1.5
	local ground = workspace:Raycast(root.Position, Vector3.new(0, -height, 0), params)
	if not ground then
		return "Aquí no te puedes tumbar."
	elseif ground.Material == Enum.Material.Water then
		return "🌊 En el agua no te puedes tumbar."
	elseif Movement.slopeDegrees(ground.Normal) > Movement.MaxProneSlope then
		return "⛰ Hay demasiada cuesta para tumbarse."
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
	-- Escaleras: el suelo delante y detrás no puede estar a otra altura
	for _, side in { 1, -1 } do
		local at = root.Position + flat * side * 2.2 * scale
		local hit = workspace:Raycast(at, Vector3.new(0, -height - 1.5, 0), params)
		if not hit or math.abs(hit.Position.Y - ground.Position.Y) > 1.1 * scale then
			return "🪜 Aquí no te puedes tumbar (escalones o un desnivel)."
		end
	end
	-- Sitio: el cuerpo tumbado mide casi lo que mides de pie (cabeza delante, pies detrás)
	local low = ground.Position + Vector3.new(0, 0.7 * scale, 0)
	local center = Vector3.new(root.Position.X, low.Y, root.Position.Z)
	if workspace:Raycast(center, flat * 3.2 * scale, params) or workspace:Raycast(center, -flat * 2.8 * scale, params) then
		return "Aquí no hay sitio para tumbarte."
	end
	return nil
end

-- Pone la postura (la pidas tú, la corrija el servidor o te levante algo). Es el único sitio que
-- toca `current`: así el salto, el aviso para las armas (BusyMove), el botón y el servidor siempre
-- van a la par.
local function setCurrent(stance: string, tell: boolean?)
	if current == stance then
		return
	end
	local from = current
	current = stance
	changedAt = os.clock()
	player:SetAttribute("StanceLocal", stance)
	-- Tumbarse y levantarse del suelo lleva un momento: el arma (u otro objeto) se baja.
	-- (Con una ficha: si la postura vuelve a cambiar antes, el último cambio es el que lo quita; antes
	-- un cambio a mitad dejaba "BusyMove" puesto para siempre y el arma bajada)
	busyToken += 1
	if stance == "Prone" or from == "Prone" then
		local token = busyToken
		player:SetAttribute("BusyMove", true)
		task.delay(Movement.Transition.Prone + 0.05, function()
			if busyToken == token then
				player:SetAttribute("BusyMove", nil)
			end
		end)
	elseif player:GetAttribute("BusyMove") and not (Parkour and Parkour.isVaulting()) then
		player:SetAttribute("BusyMove", nil)
	end
	Stances.blockJump("Stance", stance ~= "Stand")
	if tell ~= false and remote then
		remote:FireServer("Stance", stance)
	end
end

local function isR6(humanoid: Humanoid): boolean
	return humanoid.RigType == Enum.HumanoidRigType.R6
end

-- Pide una postura. Devuelve si se ha puesto.
function Stances.request(stance: string, quiet: boolean?): boolean
	if stance == current then
		return true
	end
	-- (si no se puede, siempre se dice por qué: nunca "pulso y no pasa nada")
	local humanoid, root = parts()
	if not humanoid or not root then
		if not quiet then
			toast("Espera a que aparezca tu personaje.")
		end
		return false
	end
	if stance ~= "Stand" and Parkour and Parkour.isVaulting() then
		if not quiet then
			toast("Primero termina el salto.") -- a mitad de un salto de valla no
		end
		return false
	end
	local ok, why = Movement.allowed(stance, context(humanoid))
	if not ok then
		if not quiet then
			toast(why or "Ahora no te puedes agachar.")
		end
		return false
	end
	if stance == "Prone" and isR6(humanoid) then
		stance = "Crouch" -- (los personajes R6 no tienen rodillas ni codos: se quedan agachados)
		if current == "Crouch" then
			if not quiet then
				toast("Con este personaje no te puedes tumbar.")
			end
			return false
		end
	end
	if stance == "Prone" then
		local blocked = proneBlocker(humanoid, root)
		if blocked then
			if not quiet then
				toast(blocked)
			end
			if current == "Stand" then
				setCurrent("Crouch") -- no cabe tumbado: al menos agachado
				return true
			end
			return false
		end
	elseif stance == "Stand" and not roomToStand(humanoid, root) then
		-- Levantarse necesita sitio encima
		if not quiet then
			toast("No hay sitio para levantarte aquí.")
		end
		return false
	end
	setCurrent(stance)
	return true
end

-- Levantarse (al correr o saltar). Devuelve si ya está de pie.
function Stances.standUp(): boolean
	if current == "Stand" then
		return true
	end
	return Stances.request("Stand")
end

function Stances.toggleCrouch()
	Stances.request(if current == "Stand" then "Crouch" else "Stand")
end

-- Tecla o botón de agacharse: tocar = agacharse/levantarse; mantener = tumbarse
local pressedAt: number? = nil
local proneByHold = false
local function press(down: boolean)
	if down then
		pressedAt = os.clock()
		proneByHold = false
		local at = pressedAt
		task.delay(Movement.HoldToProne, function()
			if pressedAt == at then
				proneByHold = true
				Stances.request(if current == "Prone" then "Crouch" else "Prone")
			end
		end)
	else
		if pressedAt and not proneByHold then
			Stances.toggleCrouch()
		end
		pressedAt = nil
	end
end
Stances.press = press

---------------------------------------------------------------------
-- La postura en el cuerpo (todos los jugadores cercanos)
---------------------------------------------------------------------
-- ¿Siguen siendo suyas las articulaciones apuntadas? (al aplicar el aspecto —AvatarService, al
-- aparecer y al cambiar de edad— Roblox cambia las piezas del cuerpo y con ellas las articulaciones:
-- las viejas ya no mueven nada)
local function stale(body: Body): boolean
	return Joints.stale(body.Joints, body.Model)
end

local watchedModels: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function bodyOf(model: Model, owner: Player): Body?
	local old = bodies[model]
	if old and not stale(old) then
		return old
	end
	bodies[model] = nil
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return nil
	end
	local r6 = humanoid.RigType == Enum.HumanoidRigType.R6
	local joints = {}
	if r6 then
		for name, where in JOINTS_R6 do
			joints[name] = findJoint(model, where[1], where[2])
		end
	else
		for name, part in JOINTS do
			joints[name] = findJoint(model, part, name)
		end
	end
	if not joints.Root then
		return nil
	end
	local legs: { Leg } = {}
	for _, side in { 1, -1 } do
		local prefix = if side > 0 then "Right" else "Left"
		local hip = joints[prefix .. "Hip"]
		local knee, ankle = joints[prefix .. "Knee"], joints[prefix .. "Ankle"]
		if hip and (r6 or (knee and ankle)) then
			table.insert(legs, { Side = side, Hip = hip, Knee = knee :: any, Ankle = ankle :: any, Ground = 0, Normal = Vector3.yAxis })
		end
	end
	local body: Body = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Player = owner,
		R6 = r6,
		Joints = joints,
		Legs = legs,
		-- (si se rehace por piezas nuevas, la postura sigue donde iba: sin saltos)
		Crouch = if old then old.Crouch else 0,
		Prone = if old then old.Prone else 0,
		Phase = 0,
		Step = 0,
		Move = 0,
		Speed = 0,
		Dir = Vector3.new(0, 0, -1),
		Seed = math.random() * 10,
		LastPos = root.Position,
		Gesture = false,
		GestureAt = 0,
		Pitch = 0,
		Roll = 0,
		Lowest = nil,
		Scale = model:GetScale(),
	}
	bodies[model] = body
	if not watchedModels[model] then
		watchedModels[model] = true
		model.AncestryChanged:Connect(function(_, parent)
			if not parent then
				bodies[model] = nil
			end
		end)
	end
	return body
end
Stances._bodyOf = bodyOf

-- Punto más bajo del cuerpo tumbado (sin bajarlo), respecto a la cadera
local function proneLowest(body: Body): number
	local scale = body.Model:GetScale()
	if body.Lowest and math.abs(scale - body.Scale) < 0.01 then
		return body.Lowest
	end
	local lowest = AgeMotion.lowestPoint(Joints.shape(body.Joints), Stances.pronePose(0, 0, 0, 0, 0))
	body.Lowest = if lowest == math.huge then 0 else lowest
	body.Scale = scale
	return body.Lowest :: number
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true
groundParams.RespectCanCollide = true

-- Lo que mide la pierna (cadera a tobillo; R6: la pierna entera). Se mide cada vez desde las
-- articulaciones: si el personaje crece (niño → adulto) o cambia de ropa, sigue cuadrando.
local function limbs(leg: Leg, r6: boolean): (number, number)
	if r6 then
		local part = jointPart1(leg.Hip)
		local l = if part then math.abs(jointC1(leg.Hip).Position.Y) + part.Size.Y / 2 else 2
		return l, 0
	end
	local thigh = max((jointC0(leg.Knee).Position - jointC1(leg.Hip).Position).Magnitude, 0.2)
	local shin = max((jointC0(leg.Ankle).Position - jointC1(leg.Knee).Position).Magnitude, 0.2)
	return thigh, shin
end

local function legLength(body: Body): number
	local leg = body.Legs[1]
	if not leg then
		return 2 * max(body.Model:GetScale(), 0.3)
	end
	local a, b = limbs(leg, body.R6)
	return a + b
end

local function linear(value: number, target: number, seconds: number, dt: number): number
	-- (lineal con curva al aplicar: llega en `seconds` exactos)
	local step = dt / math.max(seconds, 1e-3)
	if value < target then
		return math.min(target, value + step)
	end
	return math.max(target, value - step)
end

local function toward(value: number, target: number, rate: number, dt: number): number
	return value + (target - value) * (1 - math.exp(-rate * dt))
end

local function ease(x: number): number
	return x * x * (3 - 2 * x)
end

-- De un giro en el espacio del padre (la raíz, el torso…) al de la articulación (su C0 puede ir girado,
-- como en R6)
local function jointSpace(joint: Motor6D, cf: CFrame): CFrame
	local r = jointC0(joint).Rotation
	return r:Inverse() * cf * r
end

-- ¿Suena una animación de acción (gesto, baile, herramienta)? Entonces los brazos son suyos.
local function gesturing(body: Body, now: number): boolean
	if now - body.GestureAt < 0.25 then
		return body.Gesture
	end
	body.GestureAt = now
	local found = false
	local animator = body.Humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			if track.Priority == Enum.AnimationPriority.Action and track.WeightCurrent > 0.1 then
				found = true
				break
			end
		end
	end
	body.Gesture = found
	return found
end

-- Suelo bajo un pie (en el espacio de la raíz): cuánto más alto está que el suelo bajo el cuerpo
-- (centerY, en el mundo) y su inclinación. Se compara con el suelo de debajo del cuerpo y no con la
-- altura de la raíz: así no le afecta lo que tarda la física en seguir a la HipHeight.
local function footGround(body: Body, at: Vector3, centerY: number, depth: number, reach: number): (number, Vector3)
	local root = body.Root
	local world = root.CFrame:PointToWorldSpace(Vector3.new(at.X, 0, at.Z))
	local hit = workspace:Raycast(world, Vector3.new(0, -(depth + reach + 0.2), 0), groundParams)
	if not hit then
		return 0, Vector3.yAxis
	end
	local delta = hit.Position.Y - centerY
	if math.abs(delta) > reach then
		return 0, Vector3.yAxis
	end
	return delta, root.CFrame:VectorToObjectSpace(hit.Normal)
end

local function crouchR6(body: Body, c: number, move: number)
	local joints = body.Joints
	local l = legLength(body)
	local drop = Movement.CrouchDepth * l * c
	local lean = 0.2 * c
	-- El tronco baja (a la vista: en R6 la altura de verdad no cambia) y se inclina
	local rootJ = joints.Root
	Layers.write(rootJ, jointSpace(rootJ, CFrame.new(0, -drop, 0) * angles(-lean, 0, 0)) * Layers.read(rootJ))
	-- Sin rodillas: una pierna adelante y otra atrás hasta tocar el suelo (zancada baja)
	local spread = math.acos(clamp(1 - drop / max(l, 0.2), -1, 1))
	local k = 1 - 0.45 * c * clamp(move, 0, 1) -- andando, el paso de la animación, más corto
	for _, leg in body.Legs do
		local joint = leg.Hip
		local angle = if leg.Side > 0 then spread + lean else spread - lean
		Layers.write(joint, angles(0, 0, angle) * AgeMotion.scaled(Layers.read(joint), k))
	end
	for name, sign in { RightShoulder = 1, LeftShoulder = -1 } do
		local joint = joints[name]
		if joint then
			Layers.write(joint, angles(0, 0, 0.3 * c * sign) * Layers.read(joint))
		end
	end
end

local function update(body: Body, dt: number, now: number)
	local humanoid, root = body.Humanoid, body.Root
	local mine = body.Player == player
	local stance = if mine then current else (body.Player:GetAttribute("Stance") or "Stand")
	if humanoid.SeatPart or humanoid.Health <= 0 or humanoid.PlatformStand then
		stance = "Stand"
	end
	if body.R6 and stance == "Prone" then
		stance = "Crouch"
	end
	local wantCrouch = if stance == "Crouch" or stance == "Prone" then 1 else 0
	local wantProne = if stance == "Prone" then 1 else 0
	body.Crouch = linear(body.Crouch, wantCrouch, Movement.Transition.Crouch, dt)
	-- De pie a tumbado: primero dobla las rodillas (el tumbarse espera un poco)
	local proneTime = Movement.Transition.Prone
	if wantProne == 1 and body.Crouch < 0.6 then
		body.Prone = linear(body.Prone, 0, proneTime, dt)
	else
		body.Prone = linear(body.Prone, wantProne, proneTime, dt)
	end
	local c, p = ease(body.Crouch), ease(body.Prone)
	local L = legLength(body)
	local fullDrop = Movement.CrouchDepth * L

	-- Tu personaje: más bajo de verdad (R15; la cadera baja justo lo que se doblan las piernas)
	local drop = fullDrop * c + (0.75 * L - fullDrop) * p * c
	if mine and not body.R6 then
		local hipNow = humanoid.HipHeight
		if writtenHip == nil or math.abs(hipNow - writtenHip) > 0.01 then
			standHip = hipNow -- el servidor ha cambiado la altura (otra edad): esa es la de pie
		end
		local stand = standHip or hipNow
		local crouched = math.max(stand - fullDrop, 0.05)
		local lying = 0.05 * body.Model:GetScale()
		local want = stand + (crouched - stand) * c
		want += (lying - want) * p
		if math.abs(want - hipNow) > 0.001 then
			humanoid.HipHeight = want
		end
		writtenHip = humanoid.HipHeight
		-- Lo que ha bajado de verdad (las piernas se doblan eso mismo: ni se hunden ni flotan; al
		-- tumbarse siguen doblándose mientras el cuerpo baja)
		drop = clamp(stand - humanoid.HipHeight, 0, 0.75 * L)
		if body.Crouch <= 0 and body.Prone <= 0 then
			if math.abs(humanoid.HipHeight - stand) > 1e-4 then
				humanoid.HipHeight = stand
			end
			writtenHip = nil
			standHip = nil
		end
	end
	if c < 0.001 and p < 0.001 then
		body.Move, body.Step, body.Speed = 0, 0, 0
		for _, leg in body.Legs do
			leg.Ground, leg.Normal = 0, Vector3.yAxis
		end
		return
	end

	local v = root.AssemblyLinearVelocity
	local flatV = Vector3.new(v.X, 0, v.Z)
	local speed = flatV.Magnitude
	local scale = max(body.Model:GetScale(), 0.3)
	body.Phase = (body.Phase + dt * speed * 1.6 / scale) % TAU
	-- Un salto de sitio (teletransporte, entrar en un interior): los pies no se arrastran desde allí
	local jumped = (root.Position - body.LastPos).Magnitude > 8 * scale
	body.LastPos = root.Position
	local airborne = math.abs(v.Y) > 7 or humanoid:GetState() == Enum.HumanoidStateType.Freefall
	local moving = speed > 0.35 * scale and not airborne
	body.Move = toward(body.Move, if moving then clamp(speed / (2.2 * scale), 0, 1) else 0, 10, dt)
	if speed > 0.2 then
		local lv = root.CFrame:VectorToObjectSpace(flatV)
		local want = Vector3.new(lv.X, 0, lv.Z)
		if want.Magnitude > 1e-3 then
			local dir = body.Dir:Lerp(want.Unit, 1 - math.exp(-12 * dt))
			body.Dir = if dir.Magnitude > 1e-3 then dir.Unit else want.Unit
		end
	end
	body.Speed = toward(body.Speed, if airborne then 0 else speed, 12, dt)
	local hz, stride = Stances.gaitRate(body.Speed, L)
	if moving then
		body.Step = (body.Step + dt * hz) % 1
	end

	if body.R6 then
		crouchR6(body, c, body.Move)
		return
	end

	-- Suelo (para la cuesta y para tocarlo tumbado)
	local floorRel = -(humanoid.HipHeight + root.Size.Y / 2)
	groundParams.FilterDescendantsInstances = { body.Model, workspace.CurrentCamera :: Instance }
	if p > 0.001 then
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -(root.Size.Y / 2 + humanoid.HipHeight + 3), 0), groundParams)
		if hit then
			floorRel = hit.Position.Y - root.Position.Y
			local pitch, roll = Movement.slopeAngles(hit.Normal, root.CFrame.LookVector)
			body.Pitch += (clamp(pitch, -0.45, 0.45) - body.Pitch) * math.min(1, dt * 6)
			body.Roll += (clamp(roll, -0.45, 0.45) - body.Roll) * math.min(1, dt * 6)
		end
	end

	local joints = body.Joints
	local move = body.Move
	local m = move * c
	local u = body.Step
	local ph = u * TAU
	local breath = sin(now * 2.1 + body.Seed)
	-- Legs: cuánto mandan las piernas propias sobre la animación (enseguida: la animación de andar de
	-- pie no casa con las rodillas dobladas)
	-- (quieto, la animación ya tiene las piernas rectas: las propias entran desde el primer momento)
	local wik = 1 - (1 - ease(clamp(body.Crouch * 4, 0, 1))) * clamp(move, 0, 1)
	local pose = Stances.crouchPose(c, 0, 0, 0, move, ph, breath)

	-- La cadera: se inclina, baja en cada apoyo (dos veces por ciclo) y respira
	local G = Stances.Gait
	local dip = 0.5 + 0.5 * math.cos(2 * TAU * (u - G.Duty / 2))
	local bob = -0.05 * L * m * dip + 0.012 * L * breath * (1 - move) * c
	local rootJ = joints.Root
	local rootAnim = Layers.read(rootJ)
	local rootOut = rootAnim:Lerp(jointSpace(rootJ, CFrame.new(0, bob, 0) * pose.Pelvis), wik)

	-- Piernas: cada tobillo a su sitio (apoyado en el suelo o dando el paso) con IK de dos huesos
	local legOut: { [Motor6D]: CFrame } = {}
	if #body.Legs > 0 then
		local rootC0, rootC1 = jointC0(rootJ), jointC1(rootJ)
		local pelvisCF = rootC0 * rootOut * rootC1:Inverse()
		local restPelvis = rootC0 * rootC1:Inverse()
		local reach = 0.45 * L
		-- El suelo bajo el cuerpo. Los demás jugadores: lo que ha bajado su cuerpo se mide (su posición
		-- llega por la red y su HipHeight aquí es la de pie), así las piernas cuadran con lo que se ve
		-- aunque el atributo y la posición lleguen a destiempo.
		local standB = if mine then (standHip or humanoid.HipHeight) else humanoid.HipHeight
		local depth = root.Size.Y / 2 + standB + 0.1 * L
		local centerY: number? = nil
		if not airborne then
			local hit = workspace:Raycast(root.Position, Vector3.new(0, -(depth + reach), 0), groundParams)
			if hit then
				centerY = hit.Position.Y
				if not mine then
					local measured = standB - (root.Position.Y - root.Size.Y / 2 - hit.Position.Y)
					if measured > -0.2 * L and measured < 0.9 * L then
						drop = clamp(measured, 0, 0.75 * L)
					end
				end
			end
		end
		for _, leg in body.Legs do
			local hipJ, kneeJ, ankleJ = leg.Hip, leg.Knee, leg.Ankle
			local thigh, shin = limbs(leg, false)
			local hipC0, hipC1 = jointC0(hipJ), jointC1(hipJ)
			local kneeC0, kneeC1 = jointC0(kneeJ), jointC1(kneeJ)
			local ankleC0 = jointC0(ankleJ)
			local restHip = restPelvis * hipC0
			local restAnkle = restHip * hipC1:Inverse() * kneeC0 * kneeC1:Inverse() * ankleC0
			-- Otro jugador: cuánto tiene que subir este tobillo para pisar el suelo que se ve bajo su
			-- cuerpo, con las medidas de su pie (sin fiarse de su HipHeight, que aquí no cambia)
			local legDrop = drop
			local foot = jointPart1(ankleJ)
			if not mine and centerY and foot then
				local sole = jointC1(ankleJ).Position.Y + foot.Size.Y / 2
				local need = (centerY :: number) - root.Position.Y + sole - restAnkle.Position.Y
				if need > -0.2 * L and need < 0.9 * L then
					legDrop = clamp(need, 0, 0.75 * L)
				end
			end
			local along, up = Stances.gaitFoot(u + (if leg.Side > 0 then 0 else 0.5), G.Duty)
			-- Quieto: un pie algo adelantado y el otro atrás, las rodillas un poco abiertas
			local idle = (if leg.Side > 0 then 0.12 else -0.1) * L * (1 - move)
			local flat = restAnkle.Position
				+ body.Dir * (along * stride * c)
				+ Vector3.new(leg.Side * 0.06 * L * c, 0, -idle * c)
			-- El suelo bajo este pie (escalón, cuesta): el pie se apoya ahí
			local groundWant, normalWant = 0, Vector3.yAxis
			if centerY then
				groundWant, normalWant = footGround(body, flat, centerY :: number, depth, reach)
			end
			if jumped then
				leg.Ground, leg.Normal = groundWant, normalWant
			else
				leg.Ground = toward(leg.Ground, groundWant, 18, dt)
				leg.Normal = leg.Normal:Lerp(normalWant, 1 - math.exp(-12 * dt))
			end
			-- (pasos cortos, poco levantados)
			local lift = up * G.Lift * L * c * clamp(stride / (0.6 * L), 0, 1)
			local target = flat + Vector3.new(0, legDrop + leg.Ground * c + lift, 0)
			local hipFrame = pelvisCF * hipC0
			local hipT, kneeT = Stances.legIK(hipFrame:PointToObjectSpace(target), thigh, shin)
			-- El pie plano sobre el suelo (con su cuesta); por el aire, la punta algo abajo
			local n = leg.Normal
			local axis = Vector3.yAxis:Cross(n)
			local tilt = CFrame.identity
			if axis.Magnitude > 1e-3 then
				tilt = CFrame.fromAxisAngle(axis.Unit, math.min(math.asin(math.min(axis.Magnitude, 1)), 0.35) * c)
			end
			local parent = (hipFrame * hipT * hipC1:Inverse() * kneeC0 * kneeT * kneeC1:Inverse() * ankleC0).Rotation
			local ankleT = parent:Inverse() * tilt * angles(-0.35 * up * c * move, 0, 0) * restAnkle.Rotation
			legOut[hipJ] = hipT
			legOut[kneeJ] = kneeT
			legOut[ankleJ] = ankleT
		end
	end

	-- Los brazos: la animación de andar de pie va a otro ritmo, así que se apaga casi del todo y los
	-- brazos se balancean con estas piernas (salvo un gesto o una herramienta en la mano)
	local armsFree = not gesturing(body, now)
	local tool = body.Model:FindFirstChildOfClass("Tool") ~= nil
	local armKeep = 1 - 0.8 * wik
	local prone = if p > 0.001 then Stances.pronePose(move, body.Phase, body.Pitch, body.Roll, floorRel - proneLowest(body) + 0.05 * scale) else nil
	for name, joint in joints do
		local out = if joint == rootJ then rootOut else Layers.read(joint)
		local ik = legOut[joint]
		if ik then
			out = out:Lerp(ik, wik)
		elseif ARM_JOINTS[name] then
			if armsFree and not (tool and (name == "RightShoulder" or name == "RightElbow")) then
				out = AgeMotion.scaled(out, armKeep)
			end
			out = pose[name] * out
		elseif name == "Waist" or name == "Neck" then
			out = pose[name] * out
		end
		if prone then
			out = out:Lerp(prone[name] or out, p)
		end
		Layers.write(joint, out)
	end
end

-- El servidor contesta si no deja (y por qué)
local function onServer(kind: string, value: any, why: any)
	if kind == "Stance" and type(value) == "string" and Movement.Stances[value] and value ~= current then
		setCurrent(value, false)
		if type(why) == "string" then
			toast(why)
		end
	end
end

-- Cada frame: lo que te levanta solo (montar, sentarte, nadar, trepar, caerte, una escena…) y saltar
local function watch()
	local humanoid = parts()
	if not humanoid or current == "Stand" then
		return
	end
	local ctx = context(humanoid)
	if not Movement.allowed(current, ctx) then
		setCurrent("Stand")
	elseif humanoid.Jump and os.clock() - changedAt > 0.2 then
		humanoid.Jump = false
		Stances.jumpUp()
	end
end

-- Saltar estando agachado o tumbado: levantarse (de tumbado, primero agachado). Con el botón aún
-- pulsado no salta nada más levantarse: primero acaba de ponerse de pie. Devuelve true si se ha
-- encargado (no estabas de pie). Lo usan watch (Espacio, mando) y el botón Saltar del móvil.
function Stances.jumpUp(): boolean
	if current == "Stand" then
		return false
	end
	if Stances.request(if current == "Prone" then "Crouch" else "Stand") and current == "Stand" then
		Stances.blockJump("StandUp", true)
		task.delay(Movement.Transition.Crouch, function()
			Stances.blockJump("StandUp", false)
		end)
	end
	return true
end

-- Personaje nuevo (reaparecer): de pie, sin nada pendiente
local function onCharacter(character: Model)
	current = "Stand"
	changedAt = os.clock()
	busyToken += 1
	standHip, writtenHip = nil, nil
	localBody = nil
	pressedAt = nil
	player:SetAttribute("StanceLocal", "Stand")
	player:SetAttribute("BusyMove", nil)
	table.clear(jumpBlocks)
	task.defer(function()
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end)
end

-- Para las pruebas (scripts/test-parkour.luau): un jugador y un remoto de mentira
function Stances._attach(fakePlayer: any, fakeRemote: any, fakeLayers: any?, fakeAgeMotion: any?)
	player = fakePlayer
	remote = fakeRemote
	Layers = fakeLayers or Layers
	AgeMotion = fakeAgeMotion or AgeMotion
end
Stances._step = function(body: any, dt: number, now: number)
	update(body, dt, now)
end
Stances._watch = watch
Stances._onCharacter = onCharacter
Stances._fromServer = function(value: any, why: any)
	onServer("Stance", value, why)
end

function Stances.init()
	local Players = game:GetService("Players")
	local ContextActionService = game:GetService("ContextActionService")
	local UserInputService = game:GetService("UserInputService")
	player = Players.LocalPlayer
	Layers = require(script.Parent.PoseLayers)
	AgeMotion = require(script.Parent.AgeMotion)
	pcall(function()
		Cinematics = require(script.Parent.Cinematics)
	end)
	pcall(function()
		Parkour = require(script.Parent.Parkour)
	end)
	local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Actions") :: RemoteEvent

	-- El botón Saltar del móvil (no pasa por Humanoid.Jump a tiempo): agachado o tumbado, te levanta
	if TouchLayout.onJump then
		TouchLayout.onJump(function(down: boolean)
			if down and os.clock() - changedAt > 0.2 then
				return Stances.jumpUp()
			end
			return current ~= "Stand"
		end)
	end

	-- El servidor contesta si no deja (y por qué)
	(remote :: RemoteEvent).OnClientEvent:Connect(onServer)

	-- Teclado: Ctrl izquierdo. Mando: cruceta abajo (con el menú de comandos plegado)
	local function typing(): boolean
		return UserInputService:GetFocusedTextBox() ~= nil
	end
	ContextActionService:BindAction("StanceKey", function(_, state)
		if typing() then
			return Enum.ContextActionResult.Pass
		end
		-- Sentado o en un vehículo, Ctrl es el freno de mano: ni agacharse ni el aviso de "no puedes"
		local humanoid = parts()
		if (humanoid and (humanoid.SeatPart ~= nil or humanoid.Sit))
			or player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil then
			pressedAt = nil
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
			press(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			press(false)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftControl)
	ContextActionService:BindActionAtPriority("StancePad", function(_, state)
		local ok, collapsed = pcall(function()
			return require(script.Parent.Parent.Commands.CommandMenu).isCollapsed()
		end)
		if not ok or not collapsed then
			if state == Enum.UserInputState.End and pressedAt then
				press(false)
			end
			return Enum.ContextActionResult.Pass -- la cruceta es del menú de comandos
		end
		if state == Enum.UserInputState.Begin then
			press(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			press(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, 3100, Enum.KeyCode.DPadDown)

	-- Móvil: botón del racimo (tocar agacharse, mantener tumbarse). Es el ÚNICO botón "Agacharse":
	-- el teclado (StanceKey) y el mando (StancePad) no crean botón táctil.
	local function onFoot(): boolean
		return player:GetAttribute("LifeStage") ~= "Bebe" and player:GetAttribute("Crawling") ~= true and not TouchLayout.aboard()
	end
	TouchLayout.register({
		Id = "Agacharse",
		Icon = "agacharse",
		Label = "Agacharse",
		Priority = 15,
		Key = "Ctrl",
		Pad = "Abajo",
		Visible = onFoot,
		Hold = press,
		Active = function()
			return current ~= "Stand"
		end,
	})
	local function refreshLabel()
		TouchLayout.setLabel("Agacharse", if current == "Prone" then "Tumbado" elseif current == "Crouch" then "Agachado" else nil)
		pcall(TouchLayout.refresh) -- el botón se enciende o se apaga ya (no en la próxima revisión)
	end
	player:GetAttributeChangedSignal("StanceLocal"):Connect(refreshLabel)

	-- Cosas que te levantan: montar, sentarte, nadar, trepar, caerte, una escena, morir, reaparecer
	game:GetService("RunService").Heartbeat:Connect(watch)
	player.CharacterAdded:Connect(onCharacter)

	-- Quién está cerca (cada medio segundo; tu personaje, en cuanto aparece)
	local active: { Body } = {}
	task.spawn(function()
		while true do
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position or Vector3.zero
			local list = {}
			for _, other in Players:GetPlayers() do
				local character = other.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if character and root and (other == player or (root.Position - from).Magnitude < 120) then
					local body = bodyOf(character, other)
					if body then
						table.insert(list, body)
						if other == player then
							localBody = body
						end
					end
				end
			end
			active = list
			task.wait(0.5)
		end
	end)

	Layers.add("Stances", 17, function(dt, now)
		for _, body in active do
			if body.Model.Parent and body.Humanoid.Health > 0 then
				local ok, err = pcall(update, body, dt, now or os.clock())
				if not ok then
					warn("[Stances] " .. tostring(err))
					bodies[body.Model] = nil
				end
			end
		end
	end)
end

return Stances
