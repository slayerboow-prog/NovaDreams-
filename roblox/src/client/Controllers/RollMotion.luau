-- RollMotion (cliente): la voltereta del botón Esquivar (Q, B en el mando, Esquivar en el móvil).
--
--   * El personaje rueda por el suelo hacia delante (o hacia donde empujas el joystick / las teclas)
--     durante Combat.RollTime (~0,7 s): se hace bola (cabeza al pecho, rodillas recogidas, brazos
--     delante), baja el cuerpo y da una vuelta entera sobre su eje X, y se levanta.
--   * Como no hay animación subida de rodar, se hace con código: es una capa de PoseLayers (35, después
--     de ReactMotion) que escribe Transform en la articulación de la raíz (R15 "Root", R6 "RootJoint") y
--     en las de cuello, cintura, hombros, codos, caderas y rodillas que tenga el cuerpo. Vale para R15 y
--     R6 y para Motor6D y AnimationConstraint (shared/Joints): cada giro se pide en los ejes de la pieza
--     de dentro y se pasa a los de la articulación (toJoint), así el R6 —con sus C0 girados— rueda igual.
--   * Siempre se restaura: la capa solo escribe mientras dura; en cuanto deja de escribir, PoseLayers
--     devuelve cada articulación a su animación. Se corta sola si mueres, te sientas, quedas K.O., entras
--     en una conversación o una cinemática, nadas, trepas, o cambia el personaje.
--   * El impulso: un LinearVelocity en el plano (solo X y Z: la gravedad sigue igual, si ruedas por un
--     borde caes) que sale a Combat.RollSpeed y frena hasta RollEndSpeed (Combat.rollSpeed). Respeta las
--     colisiones (es física, no se teletransporta) y además, con una pared justo delante, deja de empujar.
--   * Lo ven todos: el servidor (CombatService) pone el atributo "Roll" (hora del servidor) al jugador y
--     cada pantalla dibuja la voltereta de los demás; el movimiento llega solo (el personaje es de su
--     dispositivo). La invulnerabilidad y la pausa son las de la esquiva (Combat, CombatService).
-- Las posturas son funciones puras (RollMotion.pose / weight / spin / toJoint): scripts/test-motion.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Joints = require(ReplicatedStorage.Shared.Joints)
local Combat = require(ReplicatedStorage.Shared.Combat)

local RollMotion = {}

local angles = CFrame.Angles
local pi = math.pi

-- Las articulaciones que se mueven, por nombre lógico -> { nombre real, pieza donde suele estar }
RollMotion.Rigs = {
	R15 = {
		Root = { "Root", "LowerTorso" },
		Waist = { "Waist", "UpperTorso" },
		Neck = { "Neck", "Head" },
		RightShoulder = { "RightShoulder", "RightUpperArm" },
		LeftShoulder = { "LeftShoulder", "LeftUpperArm" },
		RightElbow = { "RightElbow", "RightLowerArm" },
		LeftElbow = { "LeftElbow", "LeftLowerArm" },
		RightHip = { "RightHip", "RightUpperLeg" },
		LeftHip = { "LeftHip", "LeftUpperLeg" },
		RightKnee = { "RightKnee", "RightLowerLeg" },
		LeftKnee = { "LeftKnee", "LeftLowerLeg" },
	},
	R6 = {
		Root = { "RootJoint", "HumanoidRootPart" },
		Neck = { "Neck", "Torso" },
		RightShoulder = { "Right Shoulder", "Torso" },
		LeftShoulder = { "Left Shoulder", "Torso" },
		RightHip = { "Right Hip", "Torso" },
		LeftHip = { "Left Hip", "Torso" },
	},
}

-- Dónde gira la bola (por encima de la articulación de la raíz) y cuánto baja el cuerpo, en studs a
-- escala 1. En el R15 la raíz está en la cadera: el centro de la bola queda algo más arriba (el pecho
-- doblado); en el R6 la raíz ya está en el centro del torso.
RollMotion.Pivot = { R15 = 0.9, R6 = 0 }
RollMotion.Drop = { R15 = 1.2, R6 = 1.3 }

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- Cuánto manda la voltereta sobre la animación (entra rápido, se mantiene y sale suave): 0..1
function RollMotion.weight(t: number): number
	if t <= 0 or t >= 1 then
		return 0
	elseif t < 0.12 then
		return smooth(t / 0.12)
	elseif t > 0.82 then
		return 1 - smooth((t - 0.82) / 0.18)
	end
	return 1
end

-- El giro del cuerpo (radianes; negativo = la cabeza va hacia delante y abajo): una vuelta entera
function RollMotion.spin(t: number): number
	return -2 * pi * smooth((t - 0.06) / 0.84)
end

-- La postura en el instante t (0..1), en los ejes de la pieza de dentro de cada articulación
-- (convención de ReactMotion: Root x < 0 hacia delante, Hip x > 0 pierna delante, Knee x < 0 doblar…)
function RollMotion.pose(t: number, rig: string?, scale: number?): { [string]: CFrame }
	local r6 = rig == "R6"
	local s = scale or 1
	local k = RollMotion.weight(t)
	local c = (if r6 then RollMotion.Pivot.R6 else RollMotion.Pivot.R15) * s
	local drop = (if r6 then RollMotion.Drop.R6 else RollMotion.Drop.R15) * s * k
	local pose: { [string]: CFrame } = {
		Root = CFrame.new(0, -drop, 0) * CFrame.new(0, c, 0) * angles(RollMotion.spin(t), 0, 0) * CFrame.new(0, -c, 0),
		Neck = angles(-0.6 * k, 0, 0),
		RightShoulder = angles(1.4 * k, 0, 0.2 * k),
		LeftShoulder = angles(1.4 * k, 0, -0.2 * k),
		RightHip = angles(1.8 * k, 0, 0),
		LeftHip = angles(1.8 * k, 0, 0),
	}
	if not r6 then
		pose.Waist = angles(-0.5 * k, 0, 0)
		pose.RightElbow = angles(1.2 * k, 0, 0)
		pose.LeftElbow = angles(1.2 * k, 0, 0)
		pose.RightKnee = angles(-2.0 * k, 0, 0)
		pose.LeftKnee = angles(-2.0 * k, 0, 0)
	end
	return pose
end

-- Un giro pedido en los ejes de la pieza de dentro -> el Transform de la articulación (cuyos ejes son
-- los de su C0: Part1 = Part0 * C0 * Transform * C1⁻¹, y C0 * (R⁻¹ D R) = posición * D * R)
function RollMotion.toJoint(c0: CFrame, d: CFrame): CFrame
	local r = c0.Rotation
	return r:Inverse() * d * r
end

---------------------------------------------------------------------
-- Quién está rodando (tu personaje y los demás)
---------------------------------------------------------------------
type Entry = { Start: number, Duration: number, Rig: string, Scale: number, Joints: { [string]: any }, Humanoid: Humanoid }

local playing: { [Model]: Entry } = {}
local Layers: any = nil
local localRoll: { Finish: (boolean) -> () }? = nil

local function collect(model: Model, rig: string): { [string]: any }
	local out = {}
	for logical, spec in RollMotion.Rigs[rig] do
		local joint = Joints.find(model, spec[1], spec[2])
		if joint then
			out[logical] = joint
		end
	end
	return out
end

-- Empieza a dibujar la voltereta en ese personaje (start: os.clock() del comienzo)
function RollMotion.play(model: Model?, start: number?, duration: number?): boolean
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if not model or not humanoid then
		return false
	end
	local rig = if humanoid.RigType == Enum.HumanoidRigType.R15 then "R15" else "R6"
	local joints = collect(model, rig)
	if not joints.Root then
		return false -- sin raíz que girar: no hay voltereta que dibujar
	end
	local ok, scale = pcall(function()
		return model:GetScale()
	end)
	playing[model] = {
		Start = start or os.clock(),
		Duration = duration or Combat.RollTime,
		Rig = rig,
		Scale = if ok and type(scale) == "number" then math.max(scale, 0.3) else 1,
		Joints = joints,
		Humanoid = humanoid,
	}
	return true
end

function RollMotion.stop(model: Model?)
	if model then
		playing[model] = nil
	end
end

function RollMotion.isRolling(model: Model?): boolean
	return model ~= nil and playing[model] ~= nil
end

-- ¿Hay algo que corte la voltereta? (también para la de los demás)
local STOP_STATES: { [any]: boolean } = {
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Physics] = true,
}
function RollMotion.blocked(humanoid: Humanoid, owner: Player?): boolean
	if humanoid.Health <= 0 or humanoid.SeatPart ~= nil or humanoid.Sit or humanoid.PlatformStand then
		return true
	end
	if STOP_STATES[humanoid:GetState()] then
		return true
	end
	if owner and (owner:GetAttribute("KO") or owner:GetAttribute("InDialogue") or owner:GetAttribute("InCinematic") or owner:GetAttribute("Riding")) then
		return true
	end
	return false
end

-- Un frame de la capa: cada personaje que rueda (lo que no se escribe vuelve solo a la animación)
function RollMotion.step(now: number)
	local Players = game:GetService("Players")
	for model, entry in playing do
		local t = (now - entry.Start) / entry.Duration
		if t >= 1 or not model.Parent or entry.Humanoid.Parent ~= model or RollMotion.blocked(entry.Humanoid, Players:GetPlayerFromCharacter(model)) then
			playing[model] = nil
			continue
		end
		if t < 0 then
			continue
		end
		-- (al cambiar el aspecto Roblox cambia las articulaciones: se vuelven a buscar)
		if Joints.stale(entry.Joints, model) then
			entry.Joints = collect(model, entry.Rig)
		end
		local w = RollMotion.weight(t)
		local pose = RollMotion.pose(t, entry.Rig, entry.Scale)
		for logical, joint in entry.Joints do
			local d = pose[logical]
			if not d then
				continue
			end
			local target = RollMotion.toJoint(Joints.c0(joint), d)
			if logical == "Root" then
				-- (el giro no se mezcla con Lerp: una vuelta entera "mezclada" sería no girar)
				Layers.write(joint, Layers.read(joint):Lerp(CFrame.identity, w) * target)
			else
				Layers.write(joint, Layers.read(joint):Lerp(target, w))
			end
		end
	end
end

---------------------------------------------------------------------
-- Tu voltereta: el impulso por el suelo
---------------------------------------------------------------------

-- Rueda hacia `direction` (horizontal). Devuelve false si ahora no se puede.
function RollMotion.roll(direction: Vector3): boolean
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or not root or RollMotion.blocked(humanoid, player) then
		return false
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		return false -- (en el aire no se rueda)
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 1e-3 then
		flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	if flat.Magnitude < 1e-3 then
		return false
	end
	local dir = flat.Unit
	if localRoll then
		localRoll.Finish(false)
	end
	local duration = Combat.RollTime
	local start = os.clock()
	-- Mirando hacia donde rueda (solo el giro: la posición no se toca)
	root.CFrame = CFrame.lookAlong(root.Position, dir)
	local savedRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false
	RollMotion.play(character, start, duration)

	local attachment = root:FindFirstChild("RootAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "RollAttachment"
		attachment.Parent = root
	end
	local push = Instance.new("LinearVelocity")
	push.Name = "Roll"
	push.Attachment0 = attachment
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	push.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	push.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	push.PlaneVelocity = Vector2.new(dir.X, dir.Z) * Combat.rollSpeed(0)
	push.MaxForce = 60000
	push.Parent = root

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local scale = math.max(character:GetScale(), 0.3)

	local connection: RBXScriptConnection? = nil
	local done = false
	local this = {} :: any
	local function finish(ok: boolean)
		if done then
			return
		end
		done = true
		if connection then
			connection:Disconnect()
		end
		push:Destroy()
		if attachment and attachment.Name == "RollAttachment" then
			attachment:Destroy()
		end
		if humanoid.Parent and humanoid.AutoRotate == false then
			humanoid.AutoRotate = savedRotate
		end
		if not ok then
			RollMotion.stop(character)
		end
		if localRoll == this then
			localRoll = nil
		end
	end
	this.Finish = finish
	localRoll = this
	connection = RunService.Heartbeat:Connect(function()
		local t = (os.clock() - start) / duration
		if t >= 1 then
			finish(true)
			return
		end
		if not character.Parent or player.Character ~= character or RollMotion.blocked(humanoid, player) then
			finish(false)
			return
		end
		-- Una pared justo delante: deja de empujar (la física ya no deja pasar, así no tiembla)
		local wall = workspace:Raycast(root.Position - Vector3.new(0, 1 * scale, 0), dir * 1.6 * scale, params)
		if wall and math.abs(wall.Normal.Y) < 0.5 and wall.Instance.CanCollide then
			push.PlaneVelocity = Vector2.zero
		else
			push.PlaneVelocity = Vector2.new(dir.X, dir.Z) * Combat.rollSpeed(t)
		end
	end)
	-- (por si acaso: nunca se queda empujando)
	task.delay(duration + 0.5, function()
		finish(true)
	end)
	return true
end

function RollMotion.isLocalRolling(): boolean
	return localRoll ~= nil
end

---------------------------------------------------------------------

function RollMotion.init()
	local Players = game:GetService("Players")
	Layers = require(script.Parent.PoseLayers)
	-- Después de ReactMotion (30): mientras rueda, manda la voltereta
	Layers.add("RollMotion", 35, function(_, now)
		RollMotion.step(now)
	end)
	-- Las volteretas de los demás (el servidor pone "Roll" = hora del servidor en su jugador)
	local me = Players.LocalPlayer
	local function watch(other: Player)
		if other == me then
			return
		end
		other:GetAttributeChangedSignal("Roll"):Connect(function()
			local at = other:GetAttribute("Roll")
			local character = other.Character
			if type(at) ~= "number" or not character then
				return
			end
			-- (su posición llega un pelín tarde: la postura también)
			local elapsed = workspace:GetServerTimeNow() - at - 0.08
			if elapsed < Combat.RollTime then
				RollMotion.play(character, os.clock() - math.max(elapsed, 0), Combat.RollTime)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	-- Personaje nuevo: nada a medias
	me.CharacterAdded:Connect(function()
		if localRoll then
			localRoll.Finish(false)
		end
	end)
end

return RollMotion
