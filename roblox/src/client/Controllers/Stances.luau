-- Stances (cliente): agacharse y tumbarse.
--
-- CONTROLES
--   Ordenador: Ctrl izquierdo agacharse / levantarse; mantenerlo medio segundo, tumbarse.
--   Mando:     cruceta abajo (con el menú de comandos plegado) igual: tocar agacharse, mantener tumbarse.
--   Móvil:     botón "Agacharse" del racimo (UI/TouchLayout): tocar agacharse, mantener tumbarse.
--   Saltar o correr estando agachado o tumbado: te levantas (si hay sitio encima).
--
-- CÓMO SE VE (en todos los jugadores: sale del atributo "Stance" que pone el servidor)
--   * Agachado: rodillas dobladas (con los pies en su sitio: IK de dos huesos, Movement.crouchLegs),
--     el tronco algo adelante, los brazos listos y pasos más cortos. Va al 55 % de velocidad.
--   * Tumbado: boca abajo siguiendo la cuesta del suelo, apoyado en los codos; se arrastra (codo y
--     rodilla contrarios) al 25 % de velocidad. Al tumbarse primero dobla las rodillas y luego baja.
--   Tu personaje es más bajo de verdad (HipHeight), así cabes por debajo de las cosas.
--
-- NO SE PUEDE: montado, sentado, nadando, de bebé (ya gatea); tumbarse tampoco en cuestas de más de
-- 25°, en escaleras, en el agua ni donde no cabes tumbado (entonces te quedas agachado). Levantarse
-- necesita sitio encima.
--
-- Para otros sistemas (las armas): Stances.current(), Stances.speedFactor(), el atributo "Stance" del
-- jugador y "BusyMove" (true mientras te tumbas o te levantas: baja el arma).
-- Es la capa 17 de PoseLayers (después de RidePose y antes de Locomotion). Las posturas son funciones
-- puras: scripts/test-parkour.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Movement = require(ReplicatedStorage.Shared.Movement)

local Stances = {}

local angles = CFrame.Angles
local sin, max, clamp = math.sin, math.max, math.clamp
local HALF_PI = math.pi / 2

---------------------------------------------------------------------
-- Posturas (funciones puras)
---------------------------------------------------------------------

-- Agachado: retoques encima de la animación. w 0..1, legs = ángulos de Movement.crouchLegs
-- (ya con el peso), move 0..1, phase = paso
function Stances.crouchPose(w: number, hip: number, knee: number, ankle: number, move: number, phase: number): { [string]: CFrame }
	local bob = sin(phase * 2) * 0.03 * move * w
	return {
		Waist = angles(-0.3 * w + bob, 0, 0),
		Neck = angles(0.22 * w, 0, 0), -- mira al frente
		RightShoulder = angles(0.3 * w, 0, 0.08 * w),
		LeftShoulder = angles(0.3 * w, 0, -0.08 * w),
		RightElbow = angles(0.55 * w, 0, 0),
		LeftElbow = angles(0.55 * w, 0, 0),
		RightHip = angles(hip, 0, 0.04 * w),
		LeftHip = angles(hip, 0, -0.04 * w),
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
local LEGS = { RightHip = true, LeftHip = true, RightKnee = true, LeftKnee = true, RightAnkle = true, LeftAnkle = true }

type Body = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Player: Player,
	Joints: { [string]: Motor6D },
	Crouch: number,
	Prone: number,
	Phase: number,
	Pitch: number,
	Roll: number,
	Thigh: number,
	Shin: number,
	Lowest: number?, -- punto más bajo del cuerpo tumbado (sin bajarlo), respecto a la cadera
	Scale: number,
}

local bodies: { [Model]: Body } = {}
local Layers: any, AgeMotion: any
local player: Player
local current = "Stand"
local changedAt = 0
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
	if localBody then
		return Stances.blendSpeed(localBody.Crouch, localBody.Prone)
	end
	return Movement.speedFactor(current)
end

-- ¿Cuánto está tumbado ese personaje? (0..1; Locomotion no lo inclina tumbado)
function Stances.proneWeight(model: Model?): number
	local body = model and bodies[model]
	return if body then body.Prone else 0
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

local function context(humanoid: Humanoid): Movement.StanceContext
	return {
		Stage = player:GetAttribute("LifeStage"),
		Crawling = player:GetAttribute("Crawling") == true,
		Riding = player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil,
		Seated = humanoid.SeatPart ~= nil or humanoid.Sit,
		Swimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming,
		Dead = humanoid.Health <= 0,
		KO = player:GetAttribute("KO") == true,
	}
end

-- ¿Cabe de pie? (nada encima hasta la altura de la cabeza)
local function roomToStand(humanoid: Humanoid, root: BasePart): boolean
	local scale = (root.Parent :: Model):GetScale()
	local floor = root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
	local tall = (standHip or humanoid.HipHeight) + root.Size.Y / 2 + 2.3 * scale
	local from = Vector3.new(root.Position.X, floor + 0.4, root.Position.Z)
	return workspace:Raycast(from, Vector3.new(0, tall - 0.4, 0), rayParams()) == nil
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
		return "No cabes tumbado aquí."
	end
	return nil
end

local function setCurrent(stance: string)
	if current == stance then
		return
	end
	local from = current
	current = stance
	changedAt = os.clock()
	player:SetAttribute("StanceLocal", stance)
	-- Tumbarse y levantarse del suelo lleva un momento: el arma (u otro objeto) se baja
	if stance == "Prone" or from == "Prone" then
		player:SetAttribute("BusyMove", true)
		task.delay(Movement.Transition.Prone + 0.05, function()
			if os.clock() - changedAt >= Movement.Transition.Prone then
				player:SetAttribute("BusyMove", nil)
			end
		end)
	end
	Stances.blockJump("Stance", stance ~= "Stand")
	if remote then
		remote:FireServer("Stance", stance)
	end
end

-- Pide una postura. Devuelve si se ha puesto.
function Stances.request(stance: string, quiet: boolean?): boolean
	local humanoid, root = parts()
	if not humanoid or not root or stance == current then
		return stance == current
	end
	local ok, why = Movement.allowed(stance, context(humanoid))
	if not ok then
		if why and not quiet then
			toast(why)
		end
		return false
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
	elseif stance == "Stand" or (stance == "Crouch" and current == "Prone") then
		-- Levantarse necesita sitio encima (de tumbado a agachado, también)
		if stance == "Stand" and not roomToStand(humanoid, root) then
			if not quiet then
				toast("No hay sitio para levantarte aquí.")
			end
			return false
		end
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
local function bodyOf(model: Model, owner: Player): Body?
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
	for name, part in JOINTS do
		local p = model:FindFirstChild(part)
		local motor = p and p:FindFirstChild(name)
		if motor and motor:IsA("Motor6D") then
			joints[name] = motor
		end
	end
	local thigh, shin = 1.2, 1.2
	if joints.RightHip and joints.RightKnee and joints.RightAnkle then
		thigh = math.max((joints.RightHip.C1.Position - joints.RightKnee.C0.Position).Magnitude, 0.2)
		shin = math.max((joints.RightKnee.C1.Position - joints.RightAnkle.C0.Position).Magnitude, 0.2)
	end
	body = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Player = owner,
		Joints = joints,
		Crouch = 0,
		Prone = 0,
		Phase = 0,
		Pitch = 0,
		Roll = 0,
		Thigh = thigh,
		Shin = shin,
		Lowest = nil,
		Scale = model:GetScale(),
	}
	bodies[model] = body
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			bodies[model] = nil
		end
	end)
	return body
end

-- Punto más bajo del cuerpo tumbado (sin bajarlo), respecto a la cadera
local function proneLowest(body: Body): number
	local scale = body.Model:GetScale()
	if body.Lowest and math.abs(scale - body.Scale) < 0.01 then
		return body.Lowest
	end
	local shape = { Joints = {}, Sizes = {} }
	for name, joint in body.Joints do
		local p0, p1 = joint.Part0, joint.Part1
		if p0 and p1 then
			shape.Joints[name] = { Part0 = p0.Name, Part1 = p1.Name, C0 = joint.C0, C1 = joint.C1 }
			shape.Sizes[p1.Name] = p1.Size
		end
	end
	local lowest = AgeMotion.lowestPoint(shape, Stances.pronePose(0, 0, 0, 0, 0))
	body.Lowest = if lowest == math.huge then 0 else lowest
	body.Scale = scale
	return body.Lowest :: number
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true

local function crouchDrop(body: Body): number
	return 0.3 * (body.Thigh + body.Shin)
end

local function smooth(value: number, target: number, seconds: number, dt: number): number
	-- (lineal con curva al aplicar: llega en `seconds` exactos)
	local step = dt / math.max(seconds, 1e-3)
	if value < target then
		return math.min(target, value + step)
	end
	return math.max(target, value - step)
end

local function ease(x: number): number
	return x * x * (3 - 2 * x)
end

local function update(body: Body, dt: number)
	local humanoid, root = body.Humanoid, body.Root
	local mine = body.Player == player
	local stance = if mine then current else (body.Player:GetAttribute("Stance") or "Stand")
	if humanoid.SeatPart or humanoid.Health <= 0 then
		stance = "Stand"
	end
	local wantCrouch = if stance == "Crouch" or stance == "Prone" then 1 else 0
	local wantProne = if stance == "Prone" then 1 else 0
	body.Crouch = smooth(body.Crouch, wantCrouch, Movement.Transition.Crouch, dt)
	-- De pie a tumbado: primero dobla las rodillas (el tumbarse espera un poco)
	local proneTime = Movement.Transition.Prone
	if wantProne == 1 and body.Crouch < 0.6 then
		body.Prone = smooth(body.Prone, 0, proneTime, dt)
	else
		body.Prone = smooth(body.Prone, wantProne, proneTime, dt)
	end
	local c, p = ease(body.Crouch), ease(body.Prone)

	-- Tu personaje: más bajo de verdad
	if mine then
		local hipNow = humanoid.HipHeight
		if writtenHip == nil or math.abs(hipNow - writtenHip) > 0.01 then
			standHip = hipNow -- el servidor ha cambiado la altura (otra edad): esa es la de pie
		end
		local stand = standHip or hipNow
		local crouched = math.max(stand - crouchDrop(body), 0.05)
		local lying = 0.05 * body.Model:GetScale()
		local want = stand + (crouched - stand) * c
		want += (lying - want) * p
		if math.abs(want - hipNow) > 0.001 then
			humanoid.HipHeight = want
		end
		writtenHip = humanoid.HipHeight
		if c < 0.001 and p < 0.001 then
			writtenHip = nil
			standHip = nil
		end
	end
	if c < 0.001 and p < 0.001 then
		return
	end

	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local move = math.clamp(speed / 4, 0, 1)
	local scale = math.max(body.Model:GetScale(), 0.3)
	body.Phase = (body.Phase + dt * speed * (if p > 0.5 then 1.6 else 0.6) / scale) % (math.pi * 2)

	-- Suelo (para la cuesta y para tocarlo tumbado)
	local floorRel = -(humanoid.HipHeight + root.Size.Y / 2)
	if p > 0.001 then
		groundParams.FilterDescendantsInstances = { body.Model, workspace.CurrentCamera :: Instance }
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -(root.Size.Y / 2 + humanoid.HipHeight + 3), 0), groundParams)
		if hit then
			floorRel = hit.Position.Y - root.Position.Y
			local pitch, roll = Movement.slopeAngles(hit.Normal, root.CFrame.LookVector)
			body.Pitch += (clamp(pitch, -0.45, 0.45) - body.Pitch) * math.min(1, dt * 6)
			body.Roll += (clamp(roll, -0.45, 0.45) - body.Roll) * math.min(1, dt * 6)
		end
	end

	local hip, knee, ankle = Movement.crouchLegs(crouchDrop(body) * c, body.Thigh, body.Shin)
	local crouch = Stances.crouchPose(c, hip, knee, ankle, move, body.Phase)
	local prone = if p > 0.001 then Stances.pronePose(move, body.Phase, body.Pitch, body.Roll, floorRel - proneLowest(body) + 0.05 * scale) else nil
	for name, joint in body.Joints do
		local out = Layers.read(joint)
		if c > 0.001 then
			if LEGS[name] and move > 0 then
				out = AgeMotion.scaled(out, 1 - 0.35 * c) -- pasos más cortos
			end
			local offset = crouch[name]
			if offset then
				out = offset * out
			end
		end
		if prone then
			out = out:Lerp(prone[name] or out, p)
		end
		Layers.write(joint, out)
	end
end

function Stances.init()
	local Players = game:GetService("Players")
	local ContextActionService = game:GetService("ContextActionService")
	local UserInputService = game:GetService("UserInputService")
	player = Players.LocalPlayer
	Layers = require(script.Parent.PoseLayers)
	AgeMotion = require(script.Parent.AgeMotion)
	local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Actions") :: RemoteEvent

	-- El servidor contesta si no deja (y por qué)
	(remote :: RemoteEvent).OnClientEvent:Connect(function(kind: string, value: any, why: any)
		if kind == "Stance" and type(value) == "string" and value ~= current then
			current = value
			player:SetAttribute("StanceLocal", value)
			Stances.blockJump("Stance", value ~= "Stand")
			if type(why) == "string" then
				toast(why)
			end
		end
	end)

	-- Teclado: Ctrl izquierdo. Mando: cruceta abajo (con el menú de comandos plegado)
	local function typing(): boolean
		return UserInputService:GetFocusedTextBox() ~= nil
	end
	ContextActionService:BindAction("StanceKey", function(_, state)
		if typing() then
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

	-- Móvil: botón del racimo (tocar agacharse, mantener tumbarse)
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
	end
	player:GetAttributeChangedSignal("StanceLocal"):Connect(refreshLabel)

	-- Cosas que te levantan: montar, sentarte, nadar, morir, reaparecer
	local RunService = game:GetService("RunService")
	RunService.Heartbeat:Connect(function()
		local humanoid = parts()
		if not humanoid then
			return
		end
		if current ~= "Stand" then
			local ctx = context(humanoid)
			if not Movement.allowed(current, ctx) then
				current = "Stand"
				changedAt = os.clock()
				player:SetAttribute("StanceLocal", "Stand")
				Stances.blockJump("Stance", false)
				if remote then
					remote:FireServer("Stance", "Stand")
				end
			elseif humanoid.Jump and os.clock() - changedAt > 0.2 then
				-- Saltar estando agachado o tumbado: levantarse (de tumbado, primero agachado)
				humanoid.Jump = false
				Stances.request(if current == "Prone" then "Crouch" else "Stand")
			end
		end
	end)
	player.CharacterAdded:Connect(function(character)
		current = "Stand"
		standHip, writtenHip = nil, nil
		localBody = nil
		player:SetAttribute("StanceLocal", "Stand")
		player:SetAttribute("BusyMove", nil)
		table.clear(jumpBlocks)
		task.defer(function()
			local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
			if humanoid then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			end
		end)
	end)

	-- Quién está cerca (cada medio segundo)
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

	Layers.add("Stances", 17, function(dt)
		for _, body in active do
			if body.Model.Parent and body.Humanoid.Health > 0 then
				local ok, err = pcall(update, body, dt)
				if not ok then
					warn("[Stances] " .. tostring(err))
					bodies[body.Model] = nil
				end
			end
		end
	end)
end

return Stances
