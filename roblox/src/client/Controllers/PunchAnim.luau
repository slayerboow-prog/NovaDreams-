-- PunchAnim (cliente): puñetazos, patada y guardia que se ven siempre.
--
-- Mueve C0 (la unión fija de cada articulación: Motor6D.C0, o Attachment0.CFrame en las
-- AnimationConstraint, las articulaciones nuevas de Roblox; ver shared/Joints) en vez de Transform:
-- C0 no lo toca ninguna animación de Roblox ni ninguna capa de PoseLayers, así que el golpe se ve
-- pase lo que pase con el orden en que se animan las cosas. Se suma encima de la animación que esté sonando (andar,
-- correr…) y, al acabar, cada articulación vuelve exactamente a su C0 de antes.
--
--   Ligeros: directo, cruzado, gancho, rodillazo, codazo y patada (el sexto, empuja)
--   Finales: gancho de abajo arriba (lanzador), patada giratoria (empujón lejano), los dos puños al suelo
--   (golpe al suelo y remate aéreo), golpe cargado y las dos manos delante (poderes de energía)
--   Mantenidas: guardia 🛡, cargar el fuerte (Windup), cargar energía (Charge) y apuntar (Aim)
--   PunchAnim.freeze: el golpe se congela un instante al impactar (hitstop)
--
-- Cada jugador ve los golpes de todos en su pantalla (CombatController: "Swing" y "Blocking").
-- Las posturas son funciones puras: scripts/test-punch.luau. Solo R15 (el juego es MorphToR15).
--
-- Ángulos (articulaciones R15, C0 sin giro):
--   Shoulder x > 0 brazo hacia delante · Elbow x > 0 dobla el brazo
--   Hip x > 0 pierna hacia delante · Knee x < 0 dobla la rodilla
--   Waist y > 0 gira el torso a su izquierda · Waist x > 0 se echa hacia atrás

local RunService = game:GetService("RunService")
local Joints = require(game:GetService("ReplicatedStorage").Shared.Joints)

local PunchAnim = {}

local sin, pi = math.sin, math.pi
local angles = CFrame.Angles

export type Pose = { [string]: CFrame }

local function bell(t: number): number -- 0 → 1 → 0
	return sin(math.clamp(t, 0, 1) * pi)
end

-- Sube rápido hasta `peak`, se mantiene hasta `hold` y vuelve suave
local function strike(t: number, peak: number, hold: number): number
	if t <= 0 or t >= 1 then
		return 0
	elseif t < peak then
		local x = t / peak
		return x * x * (3 - 2 * x)
	elseif t < hold then
		return 1
	end
	local x = (t - hold) / (1 - hold)
	return 1 - x * x * (3 - 2 * x)
end

-- Puño en guardia delante de la cara: el brazo sube hacia delante, se cierra hacia el centro y el
-- antebrazo se dobla hacia arriba (peso w de 0 a 1)
local function guardArm(side: string, w: number): Pose
	local inward = if side == "Right" then 0.55 else -0.55 -- girar sobre la vertical: hacia el centro
	return {
		[side .. "Shoulder"] = angles(0, inward * w, 0) * angles(0.95 * w, 0, 0),
		[side .. "Elbow"] = angles(1.85 * w, 0, 0),
	}
end

local function merge(...: Pose): Pose
	local out = {}
	for _, pose in { ... } do
		for name, cf in pose do
			out[name] = if out[name] then out[name] * cf else cf
		end
	end
	return out
end

PunchAnim.Moves = {
	-- Directo de derecha: el brazo sale recto y el torso gira
	Jab = {
		Duration = 0.32,
		Pose = function(t: number): Pose
			local k = strike(t, 0.3, 0.55)
			local g = bell(t)
			return merge({
				RightShoulder = angles(1.25 * g + 0.35 * k, 0, 0.25 * g * (1 - k)),
				RightElbow = angles(1.9 * g * (1 - k), 0, 0),
				Waist = angles(0, 0.45 * k, 0),
				Neck = angles(0, -0.35 * k, 0),
			}, guardArm("Left", g))
		end,
	},
	-- Cruzado de izquierda
	Cross = {
		Duration = 0.34,
		Pose = function(t: number): Pose
			local k = strike(t, 0.3, 0.55)
			local g = bell(t)
			return merge({
				LeftShoulder = angles(1.25 * g + 0.35 * k, 0, -0.25 * g * (1 - k)),
				LeftElbow = angles(1.9 * g * (1 - k), 0, 0),
				Waist = angles(0, -0.5 * k, 0),
				Neck = angles(0, 0.4 * k, 0),
			}, guardArm("Right", g))
		end,
	},
	-- Patada frontal: sube la rodilla, estira la pierna y la vuelve a bajar
	Kick = {
		Duration = 0.55,
		Pose = function(t: number): Pose
			local chamber = strike(t, 0.22, 0.72) -- la rodilla sube pronto y se queda arriba
			local extend = strike((t - 0.22) / 0.5, 0.4, 0.6) -- la pierna se estira en medio
			local g = bell(t)
			return merge({
				RightHip = angles(1.2 * chamber + 0.35 * extend, 0, 0),
				RightKnee = angles(-1.6 * chamber * (1 - extend), 0, 0),
				LeftKnee = angles(-0.25 * g, 0, 0),
				Waist = angles(0.25 * g, 0, 0),
			}, guardArm("Right", g), guardArm("Left", g))
		end,
	},
}

-- Golpes del combo largo y los finales (shared/Combat.Moves: Anim)
PunchAnim.Moves.Hook = {
	-- Gancho de izquierda: el brazo doblado barre de fuera hacia dentro con el giro de la cintura
	Duration = 0.34,
	Pose = function(t: number): Pose
		local k = strike(t, 0.32, 0.55)
		local g = bell(t)
		return merge({
			LeftShoulder = angles(1.15 * g, 0, -0.85 * g * (1 - k) - 0.2 * k),
			LeftElbow = angles(1.45 * g, 0, 0),
			Waist = angles(0, -0.7 * k + 0.2 * g * (1 - k), 0),
			Neck = angles(0, 0.45 * k, 0),
		}, guardArm("Right", g))
	end,
}
PunchAnim.Moves.Knee = {
	-- Rodillazo: la rodilla derecha sube hacia el pecho y las manos tiran hacia abajo
	Duration = 0.36,
	Pose = function(t: number): Pose
		local k = strike(t, 0.3, 0.6)
		local g = bell(t)
		return {
			RightHip = angles(1.55 * k, 0, 0),
			RightKnee = angles(-1.9 * k, 0, 0),
			LeftKnee = angles(-0.2 * g, 0, 0),
			Waist = angles(-0.25 * k, 0, 0),
			RightShoulder = angles(0.9 * g - 0.4 * k, 0, 0.15 * g),
			LeftShoulder = angles(0.9 * g - 0.4 * k, 0, -0.15 * g),
			RightElbow = angles(1.2 * g, 0, 0),
			LeftElbow = angles(1.2 * g, 0, 0),
		}
	end,
}
PunchAnim.Moves.Elbow = {
	-- Codazo de derecha: el brazo muy doblado y todo el torso gira detrás
	Duration = 0.34,
	Pose = function(t: number): Pose
		local k = strike(t, 0.3, 0.55)
		local g = bell(t)
		return merge({
			RightShoulder = angles(1.2 * g, 0, 0.35 * g),
			RightElbow = angles(2.2 * g, 0, 0),
			Waist = angles(0, 0.75 * k - 0.2 * g * (1 - k), 0),
			Neck = angles(0, -0.5 * k, 0),
		}, guardArm("Left", g))
	end,
}
PunchAnim.Moves.Uppercut = {
	-- Lanzador: se agacha y sube con el puño hacia el cielo, echándose atrás
	Duration = 0.5,
	Pose = function(t: number): Pose
		local crouch = strike(t, 0.18, 0.3)
		local k = strike((t - 0.2) / 0.8, 0.25, 0.5)
		local g = bell(t)
		return merge({
			RightShoulder = angles(0.6 * crouch + 2.4 * k, 0, 0.1 * g),
			RightElbow = angles(1.6 * crouch * (1 - k) + 0.35 * k, 0, 0),
			RightKnee = angles(-0.7 * crouch, 0, 0),
			LeftKnee = angles(-0.7 * crouch, 0, 0),
			RightHip = angles(0.45 * crouch, 0, 0),
			LeftHip = angles(0.45 * crouch, 0, 0),
			Waist = angles(-0.25 * crouch + 0.3 * k, 0.35 * k, 0),
			Neck = angles(0.35 * k, 0, 0),
		}, guardArm("Left", g))
	end,
}
PunchAnim.Moves.SpinKick = {
	-- Patada giratoria (empujón lejano): la cintura gira y la pierna derecha barre alta
	Duration = 0.6,
	Pose = function(t: number): Pose
		local turn = strike(t, 0.35, 0.6)
		local leg = strike((t - 0.15) / 0.75, 0.35, 0.55)
		local g = bell(t)
		return merge({
			Waist = angles(0.15 * leg, 1.25 * turn, 0),
			RightHip = angles(1.7 * leg, 0, 0),
			RightKnee = angles(-1.2 * g * (1 - leg), 0, 0),
			LeftKnee = angles(-0.3 * g, 0, 0),
			Neck = angles(0, -0.8 * turn, 0),
		}, guardArm("Right", g), guardArm("Left", g))
	end,
}
PunchAnim.Moves.Slam = {
	-- Al suelo / remate: los dos puños suben por encima de la cabeza y bajan de golpe
	Duration = 0.55,
	Pose = function(t: number): Pose
		local raise = strike(t, 0.3, 0.4)
		local slam = strike((t - 0.35) / 0.65, 0.2, 0.55)
		local up = raise * (1 - slam)
		return {
			RightShoulder = angles(2.7 * up + 1.0 * slam, 0, 0),
			LeftShoulder = angles(2.7 * up + 1.0 * slam, 0, 0),
			RightElbow = angles(0.6 * up, 0, 0),
			LeftElbow = angles(0.6 * up, 0, 0),
			Waist = angles(0.25 * up - 0.5 * slam, 0, 0),
			RightKnee = angles(-0.6 * slam, 0, 0),
			LeftKnee = angles(-0.6 * slam, 0, 0),
			RightHip = angles(0.35 * slam, 0, 0),
			LeftHip = angles(0.35 * slam, 0, 0),
			Neck = angles(0.3 * up - 0.2 * slam, 0, 0),
		}
	end,
}
PunchAnim.Moves.Charged = {
	-- Golpe cargado: el brazo sale desde muy atrás con todo el cuerpo
	Duration = 0.45,
	Pose = function(t: number): Pose
		local k = strike(t, 0.22, 0.6)
		local g = bell(t)
		return merge({
			RightShoulder = angles(1.6 * k, 0, 0.1 * g),
			RightElbow = angles(0.6 * g * (1 - k), 0, 0),
			Waist = angles(-0.15 * k, 0.8 * k, 0),
			Neck = angles(0, -0.6 * k, 0),
			LeftHip = angles(0.4 * k, 0, 0),
			RightKnee = angles(-0.35 * k, 0, 0),
		}, guardArm("Left", g))
	end,
}
PunchAnim.Moves.Blast = {
	-- Poder de energía: las dos manos hacia delante, abiertas
	Duration = 0.55,
	Pose = function(t: number): Pose
		local k = strike(t, 0.2, 0.7)
		return {
			RightShoulder = angles(1.5 * k, 0.25 * k, 0),
			LeftShoulder = angles(1.5 * k, -0.25 * k, 0),
			RightElbow = angles(0.25 * k, 0, 0),
			LeftElbow = angles(0.25 * k, 0, 0),
			Waist = angles(0.12 * k, 0, 0),
			RightHip = angles(0.3 * k, 0, 0),
			LeftKnee = angles(-0.3 * k, 0, 0),
		}
	end,
}

PunchAnim.Holds = {
	Guard = function(w: number): Pose
		return merge(guardArm("Right", w), guardArm("Left", w), { Neck = angles(-0.15 * w, 0, 0), Waist = angles(-0.08 * w, 0, 0) })
	end,
	-- Cargando el golpe fuerte: el brazo derecho atrás y la cintura girada
	Windup = function(w: number): Pose
		return merge({
			RightShoulder = angles(-0.55 * w, 0, 0.35 * w),
			RightElbow = angles(1.6 * w, 0, 0),
			Waist = angles(0, -0.55 * w, 0),
			Neck = angles(0, 0.4 * w, 0),
		}, guardArm("Left", w))
	end,
	-- Cargando energía: un poco agachado, brazos abajo y abiertos, puños apretados
	Charge = function(w: number): Pose
		return {
			RightShoulder = angles(-0.2 * w, 0, 0.55 * w),
			LeftShoulder = angles(-0.2 * w, 0, -0.55 * w),
			RightElbow = angles(0.6 * w, 0, 0),
			LeftElbow = angles(0.6 * w, 0, 0),
			RightHip = angles(0.3 * w, 0, 0),
			LeftHip = angles(0.3 * w, 0, 0),
			RightKnee = angles(-0.5 * w, 0, 0),
			LeftKnee = angles(-0.5 * w, 0, 0),
			Waist = angles(-0.12 * w, 0, 0),
			Neck = angles(0.15 * w, 0, 0),
		}
	end,
	-- Apuntando la definitiva: las dos manos juntas delante
	Aim = function(w: number): Pose
		return {
			RightShoulder = angles(1.45 * w, 0.35 * w, 0),
			LeftShoulder = angles(1.45 * w, -0.35 * w, 0),
			RightElbow = angles(0.35 * w, 0, 0),
			LeftElbow = angles(0.35 * w, 0, 0),
			RightHip = angles(0.35 * w, 0, 0),
			LeftKnee = angles(-0.35 * w, 0, 0),
		}
	end,
}

-- Postura de un momento (función pura): golpe en curso (t de 0 a 1) más las posturas mantenidas
function PunchAnim.pose(move: string?, t: number, holds: { [string]: number }): Pose
	local poses = {}
	local def = move and PunchAnim.Moves[move]
	if def and t >= 0 and t <= 1 then
		table.insert(poses, def.Pose(t))
	end
	for name, w in holds do
		local hold = PunchAnim.Holds[name]
		if hold and w > 0.001 then
			table.insert(poses, hold(w))
		end
	end
	return merge(table.unpack(poses))
end

---------------------------------------------------------------------
-- Aplicar a los personajes
---------------------------------------------------------------------

local JOINTS = {
	Waist = "UpperTorso",
	Neck = "Head",
	RightShoulder = "RightUpperArm",
	LeftShoulder = "LeftUpperArm",
	RightElbow = "RightLowerArm",
	LeftElbow = "LeftLowerArm",
	RightHip = "RightUpperLeg",
	LeftHip = "LeftUpperLeg",
	RightKnee = "RightLowerLeg",
	LeftKnee = "LeftLowerLeg",
}

type Body = {
	Joints: { [string]: any }, -- Motor6D o AnimationConstraint
	Original: { [string]: CFrame }, -- C0 de antes de tocarlo
	Written: { [string]: CFrame }, -- C0 que pusimos (si alguien lo cambia, se respeta el suyo)
	Move: string?,
	Start: number,
	Duration: number,
	Want: { [string]: boolean },
	Holds: { [string]: number },
	PauseAt: number?,
	PauseUntil: number?,
}

local bodies: { [Model]: Body } = {}
local started = false

-- ¿Es el mismo C0? (casi exacto: Roblox lo guarda con menos decimales de los que se escriben)
local function same(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 1e-3 and a.LookVector:Dot(b.LookVector) > 0.99999 and a.UpVector:Dot(b.UpVector) > 0.99999
end

-- Al aplicar el aspecto Roblox cambia las piezas y sus articulaciones: se vuelven a buscar (las C0
-- de las nuevas son las de partida)
local function refresh(body: Body, model: Model)
	if Joints.stale(body.Joints, model) then
		body.Joints = Joints.collect(model, JOINTS)
		table.clear(body.Written)
		table.clear(body.Original)
	end
end

local function bodyOf(model: Model?): Body?
	if not model or not model.Parent then
		return nil
	end
	local existing = bodies[model]
	if existing then
		refresh(existing, model)
		return existing
	end
	-- Motor6D o AnimationConstraint (antes solo Motor6D: con las articulaciones nuevas no golpeaba)
	local joints = Joints.collect(model, JOINTS)
	if not joints.RightShoulder or not joints.LeftShoulder then
		return nil -- sin brazos (R6): quien llama usa otra cosa
	end
	local body: Body = { Joints = joints, Original = {}, Written = {}, Move = nil, Start = 0, Duration = 1, Want = {}, Holds = {} }
	bodies[model] = body
	return body
end

-- Deja cada articulación tocada como estaba
local function release(body: Body)
	for name, joint in body.Joints do
		local written = body.Written[name]
		if written and joint.Parent and same(Joints.c0(joint), written) then
			Joints.setC0(joint, body.Original[name])
		end
	end
	table.clear(body.Written)
	table.clear(body.Original)
end

local function step(dt: number)
	local now = os.clock()
	for model, body in bodies do
		if not model.Parent then
			bodies[model] = nil
			continue
		end
		refresh(body, model)
		-- Pesos de las posturas mantenidas (entran rápido y salen suave)
		for name in PunchAnim.Holds do
			local target = if body.Want[name] then 1 else 0
			local w = body.Holds[name] or 0
			w += (target - w) * math.min(1, dt * (if target > w then 14 else 8))
			body.Holds[name] = if w > 0.01 or target > 0 then w else nil
		end
		-- Congelado del impacto (hitstop): el golpe se queda quieto un instante y luego sigue
		if body.PauseUntil then
			if now < body.PauseUntil then
				now = body.PauseAt :: number
			else
				body.Start += body.PauseUntil - (body.PauseAt :: number)
				body.PauseUntil, body.PauseAt = nil, nil
			end
		end
		local t = if body.Move then (now - body.Start) / body.Duration else 2
		if t > 1 then
			body.Move = nil
		end
		if not body.Move and next(body.Holds) == nil then
			release(body)
			bodies[model] = nil
			continue
		end
		local pose = PunchAnim.pose(body.Move, t, body.Holds)
		for name, joint in body.Joints do
			local offset = pose[name]
			local written = body.Written[name]
			-- Si otro sistema ha cambiado el C0 (p. ej. al crecer), ese es el nuevo de partida
			local c0 = Joints.c0(joint)
			if not written or not same(c0, written) then
				body.Original[name] = c0
			end
			local value = if offset then body.Original[name] * offset else body.Original[name]
			Joints.setC0(joint, value)
			body.Written[name] = value
		end
	end
end

local function start()
	if started then
		return
	end
	started = true
	RunService.RenderStepped:Connect(step)
end

-- Golpe en un personaje (un nombre de PunchAnim.Moves: "Jab", "Cross", "Kick", "Uppercut"…). Devuelve false si no se puede (sin articulaciones).
function PunchAnim.play(model: Model?, move: string): boolean
	local def = PunchAnim.Moves[move]
	local body = bodyOf(model)
	if not def or not body then
		return false
	end
	start()
	body.Move = move
	body.Start = os.clock()
	body.Duration = def.Duration
	body.PauseAt, body.PauseUntil = nil, nil
	return true
end

-- Congela el golpe en curso `seconds` (el impacto: hitstop). Devuelve false si no hay golpe.
function PunchAnim.freeze(model: Model?, seconds: number): boolean
	local body = model and bodies[model]
	if not body or not body.Move or seconds <= 0 then
		return false
	end
	local now = os.clock()
	if body.PauseUntil and now < body.PauseUntil then
		body.PauseUntil = math.max(body.PauseUntil, now + seconds)
	else
		body.PauseAt, body.PauseUntil = now, now + seconds
	end
	return true
end

-- ¿Está dando un golpe ahora?
function PunchAnim.isPlaying(model: Model?): boolean
	local body = model and bodies[model]
	return body ~= nil and body.Move ~= nil
end

-- Postura mantenida ("Guard", "Windup", "Charge", "Aim") encendida o apagada
function PunchAnim.hold(model: Model?, name: string, on: boolean): boolean
	local body = if on then bodyOf(model) else (model and bodies[model])
	if not body then
		return false
	end
	start()
	body.Want[name] = on or nil
	return true
end

-- Para las pruebas (scripts/test-joints.luau)
PunchAnim._bodyOf = bodyOf
PunchAnim._step = step

return PunchAnim
