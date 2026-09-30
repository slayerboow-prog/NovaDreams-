-- GymMotion (cliente): el cuerpo y la máquina se mueven mientras alguien entrena en el gimnasio.
--
--   * Cualquier personaje con la etiqueta GymTraining (jugadores y deportistas NPC; lo pone
--     GymService) hace el ejercicio de su atributo GymExercise con las posturas de GymPoses.
--     El cardio (cinta, bici, elíptica, remo, saco, yoga, comba) no para; en las pesas, cada vez que
--     sube el atributo GymRep se hace una repetición entera (empieza y acaba en reposo).
--   * Entra y sale suave: el peso de la postura sube y baja con una curva (sin tirones), y mientras
--     tanto se mezcla con la animación de Roblox.
--   * La máquina se mueve a la vez (solo en tu pantalla): la cinta corre, los pedales y los volantes
--     giran, las pesas suben y bajan, la barra va con las manos, el saco se balancea… (atributo Anim
--     de cada pieza: World/Kit/GymKit). Al terminar, cada pieza vuelve a su sitio.
--   * Objetos en las manos: mancuernas, guantes de boxeo y la comba (que da vueltas alrededor del
--     cuerpo y pasa bajo los pies justo cuando saltas).
--
-- Es la capa 40 de PoseLayers (después de AgeMotion, Locomotion y ReactMotion): escribe
-- Motor6D.Transform mezclando lo que hay debajo con la postura del ejercicio.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gym = require(ReplicatedStorage.Shared.Gym)
local Joints = require(ReplicatedStorage.Shared.Joints)
local GymPoses = require(script.Parent.GymPoses)

local GymMotion = {}

local Layers: any = nil
local TAU = math.pi * 2
local ACTIVE_DISTANCE = 160
local FADE = 0.45 -- segundos para entrar y salir de la postura
local ROPE_SEGMENTS = 14

type Moving = { Part: BasePart, Rest: CFrame, Anim: string }
type Body = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Joints: { [string]: any }, -- Motor6D o AnimationConstraint
	Kind: string?,
	Want: boolean,
	Weight: number,
	T: number,
	RepStart: number?,
	Queue: number,
	SeenRep: number,
	Belt: number,
	Machine: Model?,
	Moving: { Moving },
	Props: { BasePart },
	Rope: { BasePart },
	Near: boolean,
}

local bodies: { [Model]: Body } = {}
local machines: { [string]: Model } = {}
-- Dónde está cada pieza de máquina en reposo (se apunta la primera vez: si dos personajes se turnan
-- en la misma máquina, el segundo no toma por reposo una pieza que el primero había movido)
local restOf: { [BasePart]: CFrame } = setmetatable({}, { __mode = "k" }) :: any

---------------------------------------------------------------------
-- Máquinas
---------------------------------------------------------------------
local function indexMachine(machine: Instance)
	local id = machine:GetAttribute("MachineId")
	if type(id) == "string" and machine:IsA("Model") then
		machines[id] = machine
	end
end

local function rotateAround(cf: CFrame, pivot: Vector3, axis: Vector3, angle: number): CFrame
	if axis.Magnitude < 1e-3 or angle == 0 then
		return cf
	end
	return CFrame.new(pivot) * CFrame.fromAxisAngle(axis.Unit, angle) * CFrame.new(-pivot) * cf
end

local function collectMoving(body: Body)
	table.clear(body.Moving)
	local machine = body.Machine
	if not machine then
		return
	end
	for _, d in machine:GetDescendants() do
		if d:IsA("BasePart") then
			local anim = d:GetAttribute("Anim")
			if type(anim) == "string" then
				restOf[d] = restOf[d] or d.CFrame
				table.insert(body.Moving, { Part = d, Rest = restOf[d], Anim = anim })
			end
		end
	end
end

local function restoreMoving(body: Body)
	for _, m in body.Moving do
		if m.Part.Parent then
			m.Part.CFrame = m.Rest
		end
	end
	table.clear(body.Moving)
end

-- Onda de la pieza: con la carga del ejercicio (pesas) o con un seno (pedales, manetas)
local function wave(part: BasePart, def: GymPoses.Kind, t: number): number
	local phase = part:GetAttribute("Phase") or 0
	local f = (t + phase) % 1
	if part:GetAttribute("Wave") == "Sin" then
		return math.sin(TAU * f)
	end
	return def.Load(f)
end

local function handPosition(body: Body, which: string): Vector3?
	if which == "Right" or which == "Left" then
		local hand = body.Model:FindFirstChild(which .. "Hand")
		return if hand and hand:IsA("BasePart") then hand.Position else nil
	end
	local right = body.Model:FindFirstChild("RightHand")
	local left = body.Model:FindFirstChild("LeftHand")
	if right and left and right:IsA("BasePart") and left:IsA("BasePart") then
		return (right.Position + left.Position) / 2
	end
	return nil
end

local function moveMachine(body: Body, def: GymPoses.Kind, w: number)
	for _, m in body.Moving do
		local part = m.Part
		if not part.Parent then
			continue
		end
		local rest = m.Rest
		local target = rest
		if m.Anim == "Belt" then
			local start, dir = part:GetAttribute("Start"), part:GetAttribute("Dir")
			local length = part:GetAttribute("Length") or 5
			if typeof(start) == "Vector3" and typeof(dir) == "Vector3" then
				local along = ((part:GetAttribute("Along") or 0) + body.Belt) % length
				target = CFrame.new(start + dir * along) * rest.Rotation
			end
			part.CFrame = target -- (las tablillas no vuelven atrás: siguen donde se paran)
			continue
		elseif m.Anim == "Spin" then
			local pivot, axis = part:GetAttribute("Pivot"), part:GetAttribute("Axis")
			if typeof(pivot) == "Vector3" and typeof(axis) == "Vector3" then
				local turns = part:GetAttribute("Turns") or 1
				target = rotateAround(rest, pivot, axis, TAU * turns * ((body.T + (part:GetAttribute("Phase") or 0)) % 1))
			end
		elseif m.Anim == "Orbit" then
			local a, b = part:GetAttribute("DirA"), part:GetAttribute("DirB")
			if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
				local theta = TAU * ((body.T + (part:GetAttribute("Phase") or 0)) % 1)
				local offset = a * (part:GetAttribute("RadA") or 0) * math.sin(theta) + b * (part:GetAttribute("RadB") or 0) * (math.cos(theta) - 1)
				target = rest + offset
			end
		elseif m.Anim == "Slide" then
			local dir = part:GetAttribute("Dir")
			if typeof(dir) == "Vector3" then
				target = rest + dir * (part:GetAttribute("Dist") or 1) * wave(part, def, body.T)
			end
		elseif m.Anim == "Swing" then
			local pivot, axis = part:GetAttribute("Pivot"), part:GetAttribute("Axis")
			if typeof(pivot) == "Vector3" and typeof(axis) == "Vector3" then
				target = rotateAround(rest, pivot, axis, (part:GetAttribute("Angle") or 0.2) * wave(part, def, body.T))
			end
		elseif m.Anim == "Hands" then
			local at = handPosition(body, part:GetAttribute("Hand") or "Both")
			local offset = part:GetAttribute("HandOffset")
			if at then
				target = CFrame.new(at + (if typeof(offset) == "Vector3" then offset else Vector3.zero)) * rest.Rotation
			end
		end
		part.CFrame = if w >= 0.999 then target else rest:Lerp(target, w)
	end
end

---------------------------------------------------------------------
-- Objetos en las manos y comba
---------------------------------------------------------------------
local function makeProps(body: Body, def: GymPoses.Kind)
	for _, spec in def.Props or {} do
		local hand = body.Model:FindFirstChild(spec.Hand .. "Hand")
		if not hand or not hand:IsA("BasePart") then
			continue
		end
		local part = Instance.new("Part")
		part.Name = "GymProp_" .. spec.Name
		part.Size = spec.Size
		part.Color = spec.Color
		part.Material = spec.Material or Enum.Material.SmoothPlastic
		if spec.Shape then
			part.Shape = spec.Shape
		end
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		part.Transparency = 1
		part.CFrame = hand.CFrame * spec.Offset
		local weld = Instance.new("Weld")
		weld.Part0 = hand
		weld.Part1 = part
		weld.C0 = spec.Offset
		weld.Parent = part
		part.Parent = body.Model
		table.insert(body.Props, part)
	end
	if body.Kind == "Comba" then
		local folder = workspace.CurrentCamera
		for i = 1, ROPE_SEGMENTS do
			local seg = Instance.new("Part")
			seg.Name = "GymRope" .. i
			seg.Anchored = true
			seg.CanCollide = false
			seg.CanQuery = false
			seg.CanTouch = false
			seg.CastShadow = false
			seg.Size = Vector3.new(0.07, 0.07, 0.5)
			seg.Color = Color3.fromRGB(240, 170, 40)
			seg.Material = Enum.Material.SmoothPlastic
			seg.Transparency = 1
			seg.Parent = folder
			table.insert(body.Rope, seg)
		end
	end
end

local function clearProps(body: Body)
	for _, part in body.Props do
		part:Destroy()
	end
	for _, part in body.Rope do
		part:Destroy()
	end
	table.clear(body.Props)
	table.clear(body.Rope)
end

-- La comba: un arco de una mano a la otra que gira alrededor del cuerpo
local function moveRope(body: Body, w: number, lift: number)
	if #body.Rope == 0 then
		return
	end
	local right = body.Model:FindFirstChild("RightHand")
	local left = body.Model:FindFirstChild("LeftHand")
	local visible = w > 0.5 and right and left and right:IsA("BasePart") and left:IsA("BasePart")
	if not visible then
		for _, seg in body.Rope do
			seg.Transparency = 1
		end
		return
	end
	local a = GymPoses.ropeAngle(body.T)
	local frame = body.Root.CFrame
	local dir = frame.UpVector * math.cos(a) + frame.LookVector * math.sin(a)
	local reach = lift * 1.35
	local points = {}
	for i = 0, ROPE_SEGMENTS do
		local u = i / ROPE_SEGMENTS
		local base = (left :: BasePart).Position:Lerp((right :: BasePart).Position, u)
		table.insert(points, base + dir * reach * math.sin(math.pi * u))
	end
	for i, seg in body.Rope do
		local p0, p1 = points[i], points[i + 1]
		local length = (p1 - p0).Magnitude
		seg.Size = Vector3.new(0.07, 0.07, math.max(0.05, length))
		seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		seg.Transparency = 0
	end
end

---------------------------------------------------------------------
-- Personajes
---------------------------------------------------------------------
local function findJoints(body: Body)
	-- Motor6D o AnimationConstraint (las articulaciones nuevas de Roblox; antes solo Motor6D y con
	-- las nuevas el ejercicio no movía el cuerpo)
	body.Joints = Joints.collect(body.Model, GymPoses.Joints)
end

local function release(body: Body)
	restoreMoving(body)
	clearProps(body)
	bodies[body.Model] = nil
end

local function watch(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local body = bodies[model]
	if not body then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or not root:IsA("BasePart") or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
			return
		end
		body = {
			Model = model,
			Humanoid = humanoid,
			Root = root,
			Joints = {},
			Kind = nil,
			Want = true,
			Weight = 0,
			T = 0,
			RepStart = nil,
			Queue = 0,
			SeenRep = model:GetAttribute("GymRep") or 0,
			Belt = 0,
			Machine = nil,
			Moving = {},
			Props = {},
			Rope = {},
			Near = true,
		}
		bodies[model] = body
		findJoints(body)
	elseif Joints.stale(body.Joints, model) then
		findJoints(body) -- (al aplicar el aspecto Roblox cambia las piezas y sus articulaciones)
	end
	local b = body :: Body
	b.Want = true
	local kind = model:GetAttribute("GymExercise")
	if kind ~= b.Kind then
		-- Otro ejercicio: fuera lo del anterior
		restoreMoving(b)
		clearProps(b)
		b.Kind = kind
		b.T = 0
		b.RepStart = nil
		b.Queue = 0
		b.SeenRep = model:GetAttribute("GymRep") or 0
		local def = GymPoses.get(kind)
		if def then
			makeProps(b, def)
		end
	end
	local id = model:GetAttribute("GymMachine")
	b.Machine = if type(id) == "string" then machines[id] else nil
	collectMoving(b)
end

local function unwatch(model: Instance)
	local body = bodies[model :: Model]
	if body then
		body.Want = false -- sale suave; al llegar a 0 se suelta
	end
end

-- Cuánto mide su cuerpo comparado con un R15 normal
local function sizeOf(body: Body): number
	local torso = body.Model:FindFirstChild("UpperTorso")
	if torso and torso:IsA("BasePart") then
		return math.clamp(torso.Size.Y / 1.6, 0.3, 2)
	end
	return 1
end

local function step(body: Body, dt: number, now: number)
	local def = GymPoses.get(body.Kind)
	body.Weight = GymPoses.weight(body.Weight, if body.Want and def then 1 else 0, dt, FADE)
	if not body.Want and body.Weight <= 0 then
		release(body)
		return
	end
	if not def or not body.Near then
		return
	end
	-- Avanza el ciclo
	if def.Loop then
		body.T = (body.T + dt / def.Period) % 1
	else
		local rep = body.Model:GetAttribute("GymRep") or 0
		if rep > body.SeenRep then
			body.Queue = math.min(body.Queue + (rep - body.SeenRep), 2)
		end
		body.SeenRep = rep
		if body.RepStart == nil and body.Queue > 0 and body.Want then
			body.Queue -= 1
			body.RepStart = now
		end
		if body.RepStart then
			local t = (now - body.RepStart) / def.Period
			if t >= 1 then
				body.RepStart = nil
				body.T = 0
			else
				body.T = t
			end
		end
	end
	local speed = if body.Kind == "Cinta" then 8 else 0
	body.Belt += speed * dt * body.Weight
	-- Postura
	local w = GymPoses.ease(body.Weight)
	if w <= 0 then
		return
	end
	local machine = Gym.Machines[body.Kind or ""]
	local ctx: GymPoses.Ctx = {
		Lift = body.Humanoid.HipHeight + body.Root.Size.Y / 2,
		Scale = sizeOf(body),
		Geo = if machine then machine.Geo else {},
	}
	local pose = def.Pose(body.T, ctx)
	for name, joint in body.Joints do
		local target = pose[name]
		if target and joint.Parent then
			Layers.write(joint, GymPoses.blend(Layers.read(joint), target, w))
		end
	end
end

function GymMotion.init()
	Layers = require(script.Parent.PoseLayers)
	for _, machine in CollectionService:GetTagged("GymMachine") do
		indexMachine(machine)
	end
	CollectionService:GetInstanceAddedSignal("GymMachine"):Connect(indexMachine)
	CollectionService:GetInstanceRemovedSignal("GymMachine"):Connect(function(machine)
		local id = machine:GetAttribute("MachineId")
		if type(id) == "string" and machines[id] == machine then
			machines[id] = nil
		end
	end)
	local function added(model: Instance)
		task.defer(function()
			if model.Parent and model:HasTag("GymTraining") then
				pcall(watch, model)
			end
		end)
	end
	for _, model in CollectionService:GetTagged("GymTraining") do
		added(model)
	end
	CollectionService:GetInstanceAddedSignal("GymTraining"):Connect(added)
	CollectionService:GetInstanceRemovedSignal("GymTraining"):Connect(unwatch)

	-- Cerca o lejos de la cámara (cada medio segundo) y si ha cambiado de ejercicio o de máquina
	task.spawn(function()
		while true do
			task.wait(0.5)
			local camera = workspace.CurrentCamera
			local from = if camera then camera.CFrame.Position else Vector3.zero
			for model, body in bodies do
				if not model.Parent or not body.Root.Parent then
					release(body)
				else
					body.Near = (body.Root.Position - from).Magnitude < ACTIVE_DISTANCE
					if Joints.stale(body.Joints, model) then
						findJoints(body) -- (al aplicar el aspecto Roblox cambia las piezas y sus articulaciones)
					end
					if body.Want and (model:GetAttribute("GymExercise") ~= body.Kind or (body.Machine == nil and model:GetAttribute("GymMachine") ~= nil)) then
						pcall(watch, model)
					end
				end
			end
		end
	end)

	-- El cuerpo: capa 40 de PoseLayers (después de las animaciones y del resto de capas)
	Layers.add("GymMotion", 40, function(dt, now)
		for _, body in bodies do
			local ok, err = pcall(step, body, dt, now)
			if not ok then
				warn("[GymMotion] " .. tostring(err))
				release(body)
			end
		end
	end)

	-- La máquina y la comba: después de la física, cuando las manos ya están en su sitio
	RunService.Heartbeat:Connect(function()
		for _, body in bodies do
			local def = GymPoses.get(body.Kind)
			if def and body.Near then
				local w = GymPoses.ease(body.Weight)
				local ok, err = pcall(function()
					moveMachine(body, def, w)
					moveRope(body, w, body.Humanoid.HipHeight + body.Root.Size.Y / 2)
					-- (en primera persona se esconden con la mano)
					local hand = body.Model:FindFirstChild("RightHand")
					for _, part in body.Props do
						part.Transparency = if w > 0.5 then 0 else 1
						if hand and hand:IsA("BasePart") then
							part.LocalTransparencyModifier = hand.LocalTransparencyModifier
						end
					end
				end)
				if not ok then
					warn("[GymMotion] " .. tostring(err))
				end
			end
		end
	end)
end

-- Para las pruebas (scripts/test-joints.luau): buscar el cuerpo y ponerle la postura sin Roblox
GymMotion._findJoints, GymMotion._step = findJoints, step
function GymMotion._useLayers(layers: any)
	Layers = layers
end

return GymMotion
