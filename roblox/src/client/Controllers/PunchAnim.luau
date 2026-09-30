-- PunchAnim (cliente): puñetazos, patada y guardia que se ven siempre.
--
-- Mueve C0 (la unión fija de cada articulación: Motor6D.C0, o Attachment0.CFrame en las
-- AnimationConstraint, las articulaciones nuevas de Roblox; ver shared/Joints) en vez de Transform:
-- C0 no lo toca ninguna animación de Roblox ni ninguna capa de PoseLayers, así que el golpe se ve
-- pase lo que pase con el orden en que se animan las cosas. Se suma encima de la animación que esté sonando (andar,
-- correr…) y, al acabar, cada articulación vuelve exactamente a su C0 de antes.
--
--   Combo: 1 directo (derecha) · 2 cruzado (izquierda) · 3 patada (golpe fuerte, empuja)
--   Guardia: los dos antebrazos delante de la cara mientras se mantiene 🛡
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

PunchAnim.Holds = {
	Guard = function(w: number): Pose
		return merge(guardArm("Right", w), guardArm("Left", w), { Neck = angles(-0.15 * w, 0, 0), Waist = angles(-0.08 * w, 0, 0) })
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

-- Golpe en un personaje ("Jab", "Cross" o "Kick"). Devuelve false si no se puede (sin articulaciones).
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
	return true
end

-- Postura mantenida ("Guard") encendida o apagada
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
