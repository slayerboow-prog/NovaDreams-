-- PunchAnim (cliente): puñetazos, patadas y guardia que se ven siempre y se notan.
--
-- Cada golpe tiene tres tiempos, como en los juegos de lucha: ANTICIPACIÓN corta (el brazo o la
-- pierna van un poco atrás y el cuerpo carga), GOLPE rápido hasta la extensión máxima en el instante
-- del impacto (Impact, fracción de Duration) y RETROCESO a la postura normal. La cadera (Root) y el
-- torso (Waist) giran con el golpe, el cuerpo da un pequeño paso hacia delante (Root se adelanta, solo
-- se ve: la física no cambia) y la cabeza sigue mirando al frente.
--
-- Cómo se aplica (dos partes, cada una en su sitio):
--   * La postura va en C0 (la unión fija de cada articulación: Motor6D.C0, o Attachment0.CFrame en las
--     AnimationConstraint, las articulaciones nuevas de Roblox; ver shared/Joints). C0 no lo toca
--     ninguna animación de Roblox; al acabar, cada articulación vuelve exactamente a su C0 de antes.
--     ActorLife (respirar, mirar) también escribe C0 en TU personaje cada frame: mientras PunchAnim
--     trabaja en un cuerpo (PunchAnim.busy) ActorLife no lo toca. Antes los dos escribían en el mismo
--     frame y, según el orden, ganaba ActorLife: en tu pantalla tus puñetazos casi no se veían (solo
--     las patadas, porque ActorLife no mueve las piernas).
--   * Lo que la animación de andar/correr pone en esas articulaciones (Transform: el brazo que se
--     balancea al correr) se apaga durante el golpe con una capa de PoseLayers (la última, 45), para
--     que el brazo no se tambalee encima del puñetazo. Las piernas siguen andando salvo en los golpes
--     de pierna (Legs).
--
-- Encadenar: si llega un golpe con otro a medias, el anterior se funde en 0,08 s (no hay cortes).
-- Impacto: PunchAnim.freeze congela el golpe en su extensión máxima (hitstop); si llega antes de
-- tiempo, espera al impacto. PunchAnim.untilImpact dice cuánto falta (CombatController retrasa lo
-- que se ve del golpe de los demás hasta ese instante).
--
--   Ligeros: directo, cruzado, gancho, rodillazo, codazo y patada (el sexto, empuja)
--   Finales: gancho de abajo arriba (lanzador), patada giratoria (una vuelta entera), los dos puños
--   al suelo (golpe al suelo y remate aéreo), golpe cargado y las dos manos delante (poderes)
--   Mantenidas: guardia, cargar el fuerte (Windup), cargar energía (Charge) y apuntar (Aim)
--
-- R15 (lo normal: el sitio está en GameSettingsAvatar = R15, así que Roblox convierte a todos a R15)
-- con Motor6D o con AnimationConstraint. Si alguna vez llegara un cuerpo R6 (sin codos ni rodillas),
-- se usa una versión simple con sus articulaciones ("Right Shoulder", "RootJoint"…): la postura se
-- gira a los ejes de cada C0, así que se ve igual de hacia delante.
-- Las posturas son funciones puras: scripts/test-punch.luau (y la hoja de dibujos de
-- scripts/audit/poses-golpes.luau).
--
-- Ángulos (en los ejes de la pieza de dentro; en R15 los C0 no tienen giro):
--   Shoulder x > 0 brazo hacia delante · y > 0 (derecho) hacia el centro · z > 0 (derecho) hacia fuera
--   Elbow x > 0 dobla el brazo · Hip x > 0 pierna hacia delante · Knee x < 0 dobla la rodilla
--   Waist/Root y > 0 gira a su izquierda · x > 0 se echa hacia atrás · Root z < 0 = adelante (studs)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Joints = require(game:GetService("ReplicatedStorage").Shared.Joints)

local PunchAnim = {}

local sin, pi = math.sin, math.pi
local angles = CFrame.Angles
local identity = CFrame.identity

export type Pose = { [string]: CFrame }
export type Move = {
	Duration: number,
	Impact: number, -- fracción de Duration con la extensión máxima (el impacto)
	Limb: string, -- la pieza que golpea (la estela y las pruebas)
	Reach: string, -- hacia dónde llega: "Forward", "Up", "Down" o "Across" (barre hacia el otro lado)
	Legs: boolean?, -- golpe de pierna: también se paran las piernas de la animación de andar
	Pose: (t: number) -> Pose,
}

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function bell(t: number): number -- 0 → 1 → 0
	return sin(math.clamp(t, 0, 1) * pi)
end

-- Sube rápido hasta `peak`, se mantiene hasta `hold` y vuelve suave
local function strike(t: number, peak: number, hold: number): number
	if t <= 0 or t >= 1 then
		return 0
	elseif t < peak then
		return smooth(t / peak)
	elseif t < hold then
		return 1
	end
	return 1 - smooth((t - hold) / (1 - hold))
end

-- Los tres tiempos de un golpe (t de 0 a 1):
--   a: anticipación (0 → 1 en [0, wind], vuelve a 0 en el impacto)
--   k: extensión (0 hasta wind, sale rápido y llega a 1 justo en `impact`, se mantiene hasta `hold` y vuelve)
--   g: presencia (la guardia y el cuerpo: entra en [0, wind], se mantiene hasta `hold` y sale)
local function phases(t: number, wind: number, impact: number, hold: number): (number, number, number)
	if t <= 0 or t >= 1 then
		return 0, 0, 0
	end
	local a, k, g
	if t < wind then
		a = smooth(t / wind)
		k = 0
		g = a
	elseif t < impact then
		local x = (t - wind) / (impact - wind)
		a = 1 - smooth(x)
		k = 1 - (1 - x) * (1 - x) * (1 - x) -- sale disparado y frena justo al llegar
		g = 1
	elseif t < hold then
		a, k, g = 0, 1, 1
	else
		local back = 1 - smooth((t - hold) / (1 - hold))
		a, k, g = 0, back, back
	end
	return a, k, g
end
PunchAnim._phases = phases

-- Puño en guardia delante de la cara: el brazo sube hacia delante, se cierra hacia el centro y el
-- antebrazo se dobla hacia arriba (peso w de 0 a 1)
local function guardArm(side: string, w: number): Pose
	local s = if side == "Right" then 1 else -1
	return {
		[side .. "Shoulder"] = angles(0, 0.55 * s * w, 0) * angles(0.95 * w, 0, 0),
		[side .. "Elbow"] = angles(1.85 * w, 0, 0),
	}
end

-- Brazo que pega recto (directo, cruzado, cargado): de la guardia a estirado hacia el blanco.
-- yaw: hacia dónde apunta el brazo estirado respecto al torso (+ hacia el centro), compensando el giro
local function straightArm(side: string, a: number, k: number, g: number, yaw: number, raise: number?): Pose
	local s = if side == "Right" then 1 else -1
	local lift = raise or 1.55
	return {
		[side .. "Shoulder"] = angles(0, s * (0.55 * g * (1 - k) + yaw * k), 0)
			* angles(0.95 * g * (1 - k) + lift * k - 0.35 * a, 0, s * 0.25 * a),
		[side .. "Elbow"] = angles(1.85 * g * (1 - k) + 0.08 * k + 0.35 * a, 0, 0),
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

-- Paso adelante y giro de cadera (Root: mueve todo el cuerpo respecto a su sitio)
local function step(forward: number, yaw: number, down: number?): CFrame
	return CFrame.new(0, -(down or 0), -forward) * angles(0, yaw, 0)
end

-- Postura de piernas para el paso: la de atrás se estira, la de delante se dobla un poco
local function stance(rear: string, k: number): Pose
	local front = if rear == "Right" then "Left" else "Right"
	return {
		[rear .. "Hip"] = angles(-0.3 * k, 0, 0),
		[rear .. "Knee"] = angles(-0.1 * k, 0, 0),
		[front .. "Hip"] = angles(0.3 * k, 0, 0),
		[front .. "Knee"] = angles(-0.35 * k, 0, 0),
	}
end

PunchAnim.Moves = {} :: { [string]: Move }
local Moves = PunchAnim.Moves

-- Directo de derecha: el hombro derecho viene adelante (la cadera y el torso giran a la izquierda)
Moves.Jab = {
	Duration = 0.34,
	Impact = 0.3,
	Limb = "RightHand",
	Reach = "Forward",
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.14, 0.3, 0.56)
		local turn = 0.45 * k - 0.15 * a
		return merge({
			Root = step(0.55 * k, 0.15 * k - 0.05 * a),
			Waist = angles(-0.08 * k, turn, 0),
			Neck = angles(0.05 * k, -0.85 * (turn + 0.15 * k), 0),
		}, straightArm("Right", a, k, g, -0.2), guardArm("Left", g), stance("Right", k))
	end,
}
-- Cruzado de izquierda
Moves.Cross = {
	Duration = 0.36,
	Impact = 0.3,
	Limb = "LeftHand",
	Reach = "Forward",
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.14, 0.3, 0.56)
		local turn = -0.55 * k + 0.18 * a
		return merge({
			Root = step(0.6 * k, -0.2 * k + 0.06 * a),
			Waist = angles(-0.1 * k, turn, 0),
			Neck = angles(0.05 * k, -0.85 * (turn - 0.2 * k), 0),
		}, straightArm("Left", a, k, g, -0.3), guardArm("Right", g), stance("Left", k))
	end,
}
-- Gancho de izquierda: el brazo doblado sube por el lado y barre hacia dentro con el giro de la cintura
Moves.Hook = {
	Duration = 0.38,
	Impact = 0.36,
	Limb = "LeftHand",
	Reach = "Across",
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.18, 0.36, 0.58)
		local turn = -0.75 * k + 0.35 * a -- carga girando a la izquierda y barre a la derecha
		return merge({
			Root = step(0.4 * k, -0.25 * k + 0.1 * a),
			Waist = angles(-0.06 * k, turn, 0.08 * k),
			Neck = angles(0, -0.8 * (turn - 0.25 * k), 0),
			-- el brazo sube a la altura del hombro abierto hacia fuera y, girado sobre sí mismo, el
			-- antebrazo barre en horizontal hacia el centro
			LeftShoulder = angles(0, -0.55 * g * (1 - k) + 0.75 * k + 0.2 * a, 0)
				* angles(0.95 * g * (1 - k) + 1.5 * k - 0.2 * a, 0, -0.3 * a)
				* angles(0, -1.45 * k, 0),
			LeftElbow = angles(1.85 * g * (1 - k) + 1.45 * k, 0, 0),
		}, guardArm("Right", g), stance("Left", 0.6 * k))
	end,
}
-- Rodillazo: la rodilla derecha sube hacia el pecho y las manos tiran hacia abajo
Moves.Knee = {
	Duration = 0.4,
	Impact = 0.34,
	Limb = "RightUpperLeg",
	Reach = "Up",
	Legs = true,
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.16, 0.34, 0.6)
		return {
			Root = step(0.45 * k, 0, -0.08 * a),
			RightHip = angles(-0.25 * a + 1.65 * k, 0, 0),
			RightKnee = angles(-0.3 * a - 1.95 * k, 0, 0),
			LeftKnee = angles(-0.3 * a - 0.15 * k, 0, 0),
			LeftHip = angles(0.25 * a - 0.15 * k, 0, 0),
			Waist = angles(-0.32 * k + 0.1 * a, 0, 0),
			Neck = angles(0.2 * k, 0, 0),
			RightShoulder = angles(1.3 * g - 0.75 * k, 0, 0.15 * g),
			LeftShoulder = angles(1.3 * g - 0.75 * k, 0, -0.15 * g),
			RightElbow = angles(1.3 * g, 0, 0),
			LeftElbow = angles(1.3 * g, 0, 0),
		}
	end,
}
-- Codazo de derecha: el brazo muy doblado sube a la altura del hombro y todo el torso gira detrás
Moves.Elbow = {
	Duration = 0.38,
	Impact = 0.34,
	Limb = "RightUpperArm", -- (la punta del codo)
	Reach = "Forward",
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.16, 0.34, 0.58)
		local turn = 0.85 * k - 0.3 * a
		return merge({
			Root = step(0.45 * k, 0.2 * k - 0.08 * a),
			Waist = angles(-0.06 * k, turn, -0.08 * k),
			Neck = angles(0, -0.8 * (turn + 0.2 * k), 0),
			-- el brazo a la altura del hombro, girado sobre sí mismo: el antebrazo plegado en horizontal
			-- delante del pecho y la punta del codo por delante
			RightShoulder = angles(0, 0.55 * g * (1 - k) - 0.85 * k - 0.2 * a, 0)
				* angles(0.95 * g * (1 - k) + 1.5 * k - 0.15 * a, 0, 0.3 * a)
				* angles(0, 1.5 * k, 0),
			RightElbow = angles(1.85 * g * (1 - k) + 2.4 * k, 0, 0),
		}, guardArm("Left", g), stance("Right", 0.7 * k))
	end,
}
-- Patada frontal (empuja): sube la rodilla, estira la pierna adelante echándose atrás y la baja
Moves.Kick = {
	Duration = 0.5,
	Impact = 0.42,
	Limb = "RightFoot",
	Reach = "Forward",
	Legs = true,
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.2, 0.42, 0.62)
		local chamber = strike(t, 0.22, 0.42) -- la rodilla sube antes de estirar
		return merge({
			Root = step(0.5 * k, 0.1 * k, 0),
			RightHip = angles(1.3 * chamber * (1 - k) + 1.6 * k, 0, 0),
			RightKnee = angles(-1.75 * chamber * (1 - k) - 0.05 * k, 0, 0),
			LeftKnee = angles(-0.3 * g, 0, 0),
			LeftHip = angles(-0.15 * k, 0, 0),
			Waist = angles(0.18 * g + 0.15 * k, 0.1 * k, 0),
			Neck = angles(-0.2 * k, -0.2 * k, 0),
		}, guardArm("Right", g), guardArm("Left", g * (1 - 0.5 * k)), {
			LeftShoulder = angles(0, 0, -0.35 * k), -- el brazo izquierdo se abre para equilibrar
		})
	end,
}
-- Lanzador: se agacha y sube con el puño hacia el cielo, echándose atrás
Moves.Uppercut = {
	Duration = 0.5,
	Impact = 0.44,
	Limb = "RightHand",
	Reach = "Up",
	Legs = true,
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.26, 0.44, 0.64)
		local crouch = a
		return merge({
			Root = step(0.6 * k, 0.3 * k - 0.15 * a, 0.35 * crouch),
			RightShoulder = angles(0, 0.15 * k, 0) * angles(0.2 * crouch + 2.3 * k, 0, 0.35 * crouch),
			RightElbow = angles(1.7 * crouch + 0.4 * k, 0, 0),
			RightHip = angles(0.5 * crouch, 0, 0),
			LeftHip = angles(0.5 * crouch, 0, 0),
			RightKnee = angles(-0.85 * crouch, 0, 0),
			LeftKnee = angles(-0.85 * crouch, 0, 0),
			Waist = angles(-0.3 * crouch + 0.22 * k, 0.4 * k - 0.2 * crouch, 0),
			Neck = angles(0.08 * k, -0.35 * k, 0),
		}, guardArm("Left", g))
	end,
}
-- Patada giratoria (empujón lejano): una vuelta entera hacia la derecha; en el impacto la pierna
-- derecha, levantada de lado, barre justo por delante
Moves.SpinKick = {
	Duration = 0.62,
	Impact = 0.52,
	Limb = "RightFoot",
	Reach = "Forward",
	Legs = true,
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.18, 0.52, 0.7)
		-- giro: 3/4 de vuelta hasta el impacto (la pierna derecha mira adelante) y el último cuarto después
		local spin = if t <= 0 or t >= 1 then 0 elseif t < 0.52 then -1.5 * pi * smooth(t / 0.52) else -1.5 * pi - 0.5 * pi * smooth((t - 0.52) / 0.48)
		return merge({
			Root = step(0.45 * k, spin + 0.12 * a, 0),
			RightHip = angles(0.2 * k, 0, 1.45 * k),
			RightKnee = angles(-1.3 * a - 0.15 * k, 0, 0),
			LeftKnee = angles(-0.3 * g, 0, 0),
			Waist = angles(0, 0, -0.35 * k),
			Neck = angles(0, 0.3 * k, 0.25 * k),
		}, guardArm("Right", g), guardArm("Left", g))
	end,
}
-- Al suelo / remate: los dos puños suben por encima de la cabeza y bajan de golpe
Moves.Slam = {
	Duration = 0.55,
	Impact = 0.55,
	Limb = "RightHand",
	Reach = "Down",
	Legs = true,
	Pose = function(t: number): Pose
		local raise = strike(t, 0.3, 0.38)
		local slam = strike((t - 0.38) / 0.62, 0.27, 0.6) -- llega abajo en t = 0,55
		local up = raise * (1 - slam)
		return {
			Root = step(0.4 * slam, 0, 0.55 * slam - 0.1 * up),
			RightShoulder = angles(2.75 * up + 1.1 * slam, 0, -0.1 * up),
			LeftShoulder = angles(2.75 * up + 1.1 * slam, 0, 0.1 * up),
			RightElbow = angles(0.6 * up, 0, 0),
			LeftElbow = angles(0.6 * up, 0, 0),
			Waist = angles(0.3 * up - 0.85 * slam, 0, 0),
			RightKnee = angles(-1.05 * slam, 0, 0),
			LeftKnee = angles(-1.05 * slam, 0, 0),
			RightHip = angles(0.6 * slam, 0, 0),
			LeftHip = angles(0.6 * slam, 0, 0),
			Neck = angles(0.3 * up + 0.5 * slam, 0, 0),
		}
	end,
}
-- Golpe cargado: sale desde muy atrás (la postura de cargarlo) con todo el cuerpo y un paso largo
Moves.Charged = {
	Duration = 0.5,
	Impact = 0.3,
	Limb = "RightHand",
	Reach = "Forward",
	Pose = function(t: number): Pose
		local a, k, g = phases(t, 0.12, 0.3, 0.62)
		local turn = 0.6 * k - 0.55 * a
		return merge({
			Root = step(1.0 * k, 0.25 * k - 0.15 * a),
			Waist = angles(-0.15 * k, turn, 0),
			Neck = angles(0.05 * k, -0.85 * (turn + 0.25 * k), 0),
			RightShoulder = angles(0, 0, 0.35 * a) * angles(-0.55 * a, 0, 0),
		}, straightArm("Right", 0, k, g, -0.5), guardArm("Left", g), stance("Right", 1.3 * k))
	end,
}
-- Poder de energía: las dos manos hacia delante, abiertas
Moves.Blast = {
	Duration = 0.55,
	Impact = 0.2,
	Limb = "RightHand",
	Reach = "Forward",
	Pose = function(t: number): Pose
		local k = strike(t, 0.2, 0.7)
		return {
			Root = step(0.25 * k, 0),
			RightShoulder = angles(0, 0.25 * k, 0) * angles(1.5 * k, 0, 0),
			LeftShoulder = angles(0, -0.25 * k, 0) * angles(1.5 * k, 0, 0),
			RightElbow = angles(0.2 * k, 0, 0),
			LeftElbow = angles(0.2 * k, 0, 0),
			Waist = angles(0.12 * k, 0, 0),
			RightHip = angles(-0.3 * k, 0, 0),
			LeftHip = angles(0.3 * k, 0, 0),
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
			RightShoulder = angles(0, 0, 0.35 * w) * angles(-0.55 * w, 0, 0),
			RightElbow = angles(1.6 * w, 0, 0),
			Waist = angles(0, -0.55 * w, 0),
			Neck = angles(0, 0.45 * w, 0),
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
			RightShoulder = angles(0, 0.35 * w, 0) * angles(1.45 * w, 0, 0),
			LeftShoulder = angles(0, -0.35 * w, 0) * angles(1.45 * w, 0, 0),
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
	local def = move and Moves[move]
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

-- Fundido al encadenar (función pura): lo que quedaba del golpe anterior (`from`) se va apagando
-- (f de 1 a 0) encima del nuevo
function PunchAnim.blend(from: Pose, to: Pose, f: number): Pose
	if f <= 0 then
		return to
	end
	local out = table.clone(to)
	for name, cf in from do
		local faded = cf:Lerp(identity, 1 - math.min(f, 1))
		out[name] = if out[name] then faded * out[name] else faded
	end
	return out
end

-- Cuánto hay que apagar la animación de andar (Transform) en cada articulación (función pura)
local UPPER = { RightShoulder = 1, LeftShoulder = 1, RightElbow = 1, LeftElbow = 1, Waist = 0.7, Neck = 0.6 }
local LOWER = { Root = 0.8, RightHip = 1, LeftHip = 1, RightKnee = 1, LeftKnee = 1 }
function PunchAnim.damping(move: string?, t: number, holds: { [string]: number }): { [string]: number }
	local out = {}
	local def = move and Moves[move]
	if def and t >= 0 and t <= 1 then
		local w = strike(t, 0.15, 0.8)
		for name, k in UPPER do
			out[name] = k * w
		end
		if def.Legs then
			for name, k in LOWER do
				out[name] = k * w
			end
		end
	end
	for name, w in holds do
		if PunchAnim.Holds[name] and w > 0.001 then
			for joint, cf in PunchAnim.Holds[name](1) do
				local k = UPPER[joint]
				if k then
					out[joint] = math.max(out[joint] or 0, k * math.min(w, 1))
				end
			end
		end
	end
	return out
end

---------------------------------------------------------------------
-- Aplicar a los personajes
---------------------------------------------------------------------

-- R15: articulación -> pieza donde suele estar
local JOINTS = {
	Root = "LowerTorso",
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
-- R6: nuestro nombre -> su articulación (no tiene codos, rodillas ni cintura: la cintura va a la raíz)
local R6 = {
	Root = "RootJoint",
	Neck = "Neck",
	RightShoulder = "Right Shoulder",
	LeftShoulder = "Left Shoulder",
	RightHip = "Right Hip",
	LeftHip = "Left Hip",
}

type Body = {
	Joints: { [string]: any }, -- Motor6D o AnimationConstraint
	R6: boolean,
	Scale: number,
	Original: { [string]: CFrame }, -- C0 de antes de tocarlo
	Written: { [string]: CFrame }, -- C0 que pusimos (si alguien lo cambia, se respeta el suyo)
	Move: string?,
	Start: number,
	Duration: number,
	Want: { [string]: boolean },
	WantAt: { [string]: number }, -- cuándo se encendió (o se refrescó) cada postura mantenida
	Holds: { [string]: number },
	FreezeAt: number?, -- segundos dentro del golpe en que se congela (el impacto)…
	FreezeFor: number, -- …y cuánto
	From: Pose?, -- lo que quedaba del golpe anterior (se funde)
	FromAt: number,
	Damp: { [string]: number },
}

local BLEND = 0.08
-- Una postura mantenida de un NPC (guardia, apuntar…) que nadie refresca en este tiempo se apaga
-- sola: si se pierde el aviso de «apagar», el cuerpo no se queda en guardia (y PunchAnim.busy) para
-- siempre. La guardia de un rival que sigue con Blocking puesto cuenta como refresco.
PunchAnim.HoldExpiry = 5
local bodies: { [Model]: Body } = {}
local started = false

-- ¿Es el mismo C0? (casi exacto: Roblox lo guarda con menos decimales de los que se escriben)
local function same(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 1e-3 and a.LookVector:Dot(b.LookVector) > 0.99999 and a.UpVector:Dot(b.UpVector) > 0.99999
end

local function collect(model: Model): ({ [string]: any }, boolean)
	-- Motor6D o AnimationConstraint (antes solo Motor6D: con las articulaciones nuevas no golpeaba)
	local joints = Joints.collect(model, JOINTS)
	if joints.RightShoulder and joints.LeftShoulder then
		return joints, false
	end
	local r6 = {}
	for ours, theirs in R6 do
		r6[ours] = Joints.find(model, theirs)
	end
	return r6, true
end

-- Al aplicar el aspecto Roblox cambia las piezas y sus articulaciones: se vuelven a buscar (las C0
-- de las nuevas son las de partida)
local function refresh(body: Body, model: Model)
	if Joints.stale(body.Joints, model) then
		body.Joints, body.R6 = collect(model)
		table.clear(body.Written)
		table.clear(body.Original)
	end
end

local function scaleOf(model: Model): number
	local ok, s = pcall(function()
		return (model :: any):GetScale()
	end)
	return if ok and type(s) == "number" and s > 0 then s else 1
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
	local joints, r6 = collect(model)
	if not joints.RightShoulder or not joints.LeftShoulder then
		return nil -- sin brazos: quien llama usa otra cosa
	end
	local body: Body = {
		Joints = joints, R6 = r6, Scale = scaleOf(model), Original = {}, Written = {}, Move = nil, Start = 0, Duration = 1,
		Want = {}, WantAt = {}, Holds = {}, FreezeAt = nil, FreezeFor = 0, From = nil, FromAt = 0, Damp = {},
	}
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
	table.clear(body.Damp)
end

-- Segundos dentro del golpe teniendo en cuenta la congelación del impacto
local function elapsed(body: Body, now: number): number
	local e = now - body.Start
	local at = body.FreezeAt
	if at and e >= at then
		e = if e < at + body.FreezeFor then at else e - body.FreezeFor
	end
	return e
end

-- La postura de un cuerpo en este instante (con lo que quede del golpe anterior)
local function poseNow(body: Body, now: number): (Pose, number)
	local t = if body.Move then elapsed(body, now) / body.Duration else 2
	local pose = PunchAnim.pose(if t <= 1 then body.Move else nil, t, body.Holds)
	if body.From then
		local f = 1 - (now - body.FromAt) / BLEND
		if f > 0 then
			pose = PunchAnim.blend(body.From, pose, f)
		else
			body.From = nil
		end
	end
	return pose, t
end

-- La postura (en ejes de la pieza de dentro) llevada a la articulación: en R15 los C0 no tienen giro
-- y no cambia nada; en R6 (C0 girados) se gira a sus ejes. El paso adelante va a la escala del cuerpo.
local function toJoint(original: CFrame, offset: CFrame, scale: number): CFrame
	local rot = original.Rotation
	local moved = offset.Position * scale
	return original * (rot:Inverse() * (CFrame.new(moved) * offset.Rotation) * rot)
end
PunchAnim._toJoint = toJoint

local function apply(body: Body, pose: Pose)
	if body.R6 then
		-- Sin cintura: el giro del torso va a la raíz
		if pose.Waist then
			pose = table.clone(pose)
			pose.Root = (pose.Root or identity) * pose.Waist
			pose.Waist = nil
		end
	end
	for name, joint in body.Joints do
		local offset = pose[name]
		local written = body.Written[name]
		-- Si otro sistema ha cambiado el C0 (p. ej. al crecer), ese es el nuevo de partida
		local c0 = Joints.c0(joint)
		if not written or not same(c0, written) then
			body.Original[name] = c0
		end
		local value = if offset then toJoint(body.Original[name], offset, body.Scale) else body.Original[name]
		Joints.setC0(joint, value)
		body.Written[name] = value
	end
end

local function stepBodies(dt: number)
	local now = os.clock()
	for model, body in bodies do
		if not model.Parent then
			bodies[model] = nil
			continue
		end
		refresh(body, model)
		-- Posturas mantenidas de un NPC sin refrescar: caducan (los jugadores mandan las suyas siempre)
		if next(body.Want) ~= nil and not Players:GetPlayerFromCharacter(model) then
			for name in body.Want do
				if name == "Guard" and model:GetAttribute("Blocking") == true then
					body.WantAt[name] = now
				elseif now - (body.WantAt[name] or now) > PunchAnim.HoldExpiry then
					body.Want[name] = nil
					body.WantAt[name] = nil
				end
			end
		end
		-- Pesos de las posturas mantenidas (entran rápido y salen suave)
		for name in PunchAnim.Holds do
			local target = if body.Want[name] then 1 else 0
			local w = body.Holds[name] or 0
			w += (target - w) * math.min(1, dt * (if target > w then 14 else 8))
			body.Holds[name] = if w > 0.01 or target > 0 then w else nil
		end
		local pose, t = poseNow(body, now)
		if t > 1 then
			body.Move = nil
			body.FreezeAt = nil
		end
		if not body.Move and not body.From and next(body.Holds) == nil then
			release(body)
			bodies[model] = nil
			continue
		end
		body.Damp = PunchAnim.damping(body.Move, t, body.Holds)
		apply(body, pose)
	end
end

-- Capa de PoseLayers: apaga lo que la animación de andar pone en las articulaciones del golpe
local function dampLayer()
	local ok, Layers = pcall(require, script.Parent.PoseLayers)
	if not ok then
		return
	end
	Layers.add("PunchAnim", 45, function()
		for model, body in bodies do
			if not model.Parent then
				continue
			end
			for name, w in body.Damp do
				local joint = body.Joints[name]
				if joint and w > 0.001 and joint.Parent then
					Layers.write(joint, Layers.read(joint):Lerp(identity, math.min(w, 1)))
				end
			end
		end
	end)
end
PunchAnim._dampLayer = dampLayer

local function start()
	if started then
		return
	end
	started = true
	RunService.RenderStepped:Connect(stepBodies)
	pcall(dampLayer)
end

-- Golpe en un personaje (un nombre de PunchAnim.Moves: "Jab", "Cross", "Kick", "Uppercut"…). Si había
-- otro a medias, se funde con el nuevo. Devuelve false si no se puede (sin articulaciones).
function PunchAnim.play(model: Model?, move: string): boolean
	local def = Moves[move]
	local body = bodyOf(model)
	if not def or not body then
		return false
	end
	start()
	local now = os.clock()
	if body.Move then
		-- Lo que queda del golpe de antes (sin las mantenidas: esas siguen solas)
		local t = elapsed(body, now) / body.Duration
		if t >= 0 and t <= 1 then
			local prev = Moves[body.Move].Pose(t)
			if body.From then
				prev = PunchAnim.blend(body.From, prev, 1 - (now - body.FromAt) / BLEND)
			end
			body.From = prev
			body.FromAt = now
		end
	end
	body.Move = move
	body.Start = now
	body.Duration = def.Duration
	body.FreezeAt, body.FreezeFor = nil, 0
	return true
end

-- Segundos que faltan para el impacto del golpe en curso (0 si no hay o ya ha pasado)
function PunchAnim.untilImpact(model: Model?): number
	local body = model and bodies[model]
	if not body or not body.Move then
		return 0
	end
	local def = Moves[body.Move]
	return math.max(0, def.Impact * body.Duration - elapsed(body, os.clock()))
end

-- Congela el golpe en curso `seconds` en su extensión máxima (el impacto: hitstop). Si el golpe aún
-- no ha llegado, se congela al llegar; si ya volvía, vuelve al impacto. Devuelve false si no hay golpe.
function PunchAnim.freeze(model: Model?, seconds: number): boolean
	local body = model and bodies[model]
	if not body or not body.Move or seconds <= 0 then
		return false
	end
	local now = os.clock()
	local def = Moves[body.Move]
	local impact = def.Impact * body.Duration
	if body.FreezeAt then
		-- Ya congelado (dos golpes a la vez): se alarga
		body.FreezeFor = math.max(body.FreezeFor, (now - body.Start) - body.FreezeAt + seconds)
		return true
	end
	local e = now - body.Start
	if e > impact then
		body.Start = now - impact -- de vuelta a la extensión máxima
	end
	body.FreezeAt, body.FreezeFor = impact, seconds
	return true
end

-- ¿Está dando un golpe ahora?
function PunchAnim.isPlaying(model: Model?): boolean
	local body = model and bodies[model]
	return body ~= nil and body.Move ~= nil
end

-- ¿Está PunchAnim moviendo este cuerpo (golpe, fundido o postura mantenida)? Mientras tanto ActorLife
-- no escribe sus C0
function PunchAnim.busy(model: Model?): boolean
	return model ~= nil and bodies[model] ~= nil
end

-- Postura mantenida ("Guard", "Windup", "Charge", "Aim") encendida o apagada
function PunchAnim.hold(model: Model?, name: string, on: boolean): boolean
	local body = if on then bodyOf(model) else (model and bodies[model])
	if not body then
		return false
	end
	start()
	body.Want[name] = on or nil
	body.WantAt[name] = if on then os.clock() else nil
	return true
end

-- Para las pruebas (scripts/test-joints.luau, scripts/test-punch.luau)
PunchAnim._bodyOf = bodyOf
PunchAnim._step = stepBodies
PunchAnim._bodies = bodies

return PunchAnim
