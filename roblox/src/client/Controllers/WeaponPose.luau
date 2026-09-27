-- WeaponPose: las posturas con un arma en la mano (funciones puras; las prueba scripts/test-weapons.luau
-- y las aplica WeaponMotion en la capa de PoseLayers).
--
--   * Preparado (sin apuntar): pistola baja con una mano; armas largas a dos manos, cañón abajo.
--   * Apuntando: pistola a dos manos con los brazos estirados; armas largas con la culata al
--     hombro, el codo derecho abierto, la mano izquierda en el guardamanos y la mejilla en la culata.
--   * El tronco, la cabeza y los brazos siguen hacia dónde apunta la cámara (arriba / abajo).
--   * Corriendo se baja el arma (cruzada en el pecho o la pistola hacia el suelo).
--   * Retroceso: el arma y los brazos atrás y arriba; el hombro, el pecho y la cabeza lo acusan.
--   * Recarga: la mano izquierda baja al cinturón, sube al arma y la cabeza mira el arma.
--   * Pegado a una pared: se levanta el cañón.
-- Todo entra y sale con pesos (0..1): nada salta de golpe.
--
-- Ángulos (convención de ReactMotion/AgeMotion, R15), en radianes (x, y, z):
--   Neck/Waist  x > 0 hacia atrás (mirar arriba), y > 0 gira a su izquierda
--   Shoulder    x > 0 brazo hacia delante/arriba, z abre el brazo (derecho +, izquierdo -)
--   Elbow       x > 0 dobla el brazo

local WeaponPose = {}

local V = Vector3.new
local sin, pi = math.sin, math.pi

export type State = {
	Hold: number, -- 0..1 (0 = sin arma; sube al desenfundar)
	Aim: number, -- 0..1
	Pitch: number, -- radianes (arriba +)
	TwoHands: boolean,
	Stock: boolean,
	Sprint: number, -- 0..1
	Reload: number?, -- 0..1 mientras recarga
	Recoil: number, -- valor del muelle de retroceso (0 = quieto)
	Body: number, -- cuánto retroceso acusa el cuerpo (Weapons: Recoil.Body)
	Wall: number, -- 0..1: cañón contra una pared
	SwayX: number?,
	SwayY: number?,
	Phase: number?, -- fase del paso (para correr)
	Busy: number?, -- 0..1: saltando una valla, tumbándose o levantándose (arma bajada)
	Crouch: number?, -- 0..1: agachado (solo el tronco; las piernas las pone la locomoción)
	Prone: number?, -- 0..1: tumbado (codos en el suelo, arma delante)
}

export type Pose = { Arms: { [string]: Vector3 }, Add: { [string]: Vector3 }, Weight: number }

-- Brazos: posturas absolutas (se mezclan con la animación según Weight)
local LOW_ONE = { RightShoulder = V(0.35, 0, -0.05), RightElbow = V(0.45, 0, 0), LeftShoulder = V(0, 0, 0), LeftElbow = V(0.1, 0, 0) }
local LOW_TWO = { RightShoulder = V(0.55, 0, -0.15), RightElbow = V(1.0, 0, 0), LeftShoulder = V(0.85, 0, 0.55), LeftElbow = V(0.9, 0, 0) }
local AIM_ONE = { RightShoulder = V(1.45, 0, -0.22), RightElbow = V(0.12, 0, 0), LeftShoulder = V(1.4, 0, 0.5), LeftElbow = V(0.25, 0, 0) }
local AIM_TWO = { RightShoulder = V(0.55, 0, 0.35), RightElbow = V(1.05, 0, 0), LeftShoulder = V(1.2, 0, 0.45), LeftElbow = V(0.35, 0, 0) }
local RUN_ONE = { RightShoulder = V(0.1, 0, 0.05), RightElbow = V(0.55, 0, 0), LeftShoulder = V(0, 0, 0), LeftElbow = V(0.3, 0, 0) }
local RUN_TWO = { RightShoulder = V(0.2, 0, 0.05), RightElbow = V(1.35, 0, 0), LeftShoulder = V(0.95, 0, 0.6), LeftElbow = V(1.35, 0, 0) }
-- Tumbado: el cuerpo está en horizontal (lo gira la locomoción); los codos al suelo bajo el pecho
-- y los antebrazos hacia delante sujetando el arma
local PRONE = { RightShoulder = V(1.45, 0, 0.3), RightElbow = V(1.45, 0, 0), LeftShoulder = V(1.6, 0, 0.15), LeftElbow = V(1.2, 0, 0) }
local ARMS = { "RightShoulder", "RightElbow", "LeftShoulder", "LeftElbow" }

local function lerp(a: Vector3, b: Vector3, t: number): Vector3
	return a + (b - a) * t
end

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Recarga en tres tiempos: la mano al cinturón, al arma (cargador dentro) y vuelta (corredera)
function WeaponPose.reloadCurve(t: number): (number, number)
	if t <= 0 or t >= 1 then
		return 0, 0
	end
	local down = if t < 0.35 then smooth(t / 0.2) else 1 - smooth((t - 0.35) / 0.25)
	local up = if t < 0.3 then 0 elseif t < 0.75 then smooth((t - 0.3) / 0.25) else 1 - smooth((t - 0.75) / 0.25)
	return math.clamp(down, 0, 1), math.clamp(up, 0, 1)
end

function WeaponPose.pose(s: State): Pose
	local hold = math.clamp(s.Hold, 0, 1)
	local aim = math.clamp(s.Aim, 0, 1)
	local busy = math.clamp(s.Busy or 0, 0, 1)
	local prone = math.clamp(s.Prone or 0, 0, 1)
	local crouch = math.clamp(s.Crouch or 0, 0, 1)
	local sprint = math.max(math.clamp(s.Sprint, 0, 1) * (1 - aim), busy)
	local pitch = math.clamp(s.Pitch, -1.2, 1.2)
	local low = if s.TwoHands then LOW_TWO else LOW_ONE
	local aimed = if s.TwoHands then AIM_TWO else AIM_ONE
	local run = if s.TwoHands then RUN_TWO else RUN_ONE
	local arms: { [string]: Vector3 } = {}
	for _, name in ARMS do
		local v = lerp(low[name], aimed[name], smooth(aim))
		v = lerp(v, PRONE[name], smooth(prone) * (1 - busy))
		arms[name] = lerp(v, run[name], smooth(sprint))
	end
	local add: { [string]: Vector3 } = { Waist = V(0, 0, 0), Neck = V(0, 0, 0) }

	-- Agachado: el tronco un poco hacia delante
	add.Waist += V(-0.07 * crouch, 0, 0)
	-- Tumbado: la cabeza levantada para mirar al frente
	add.Neck += V(0.55 * prone, 0, 0)

	-- Hacia dónde apunta: el tronco y la cabeza acompañan; los brazos, el resto
	-- (tumbado el tronco no se mueve: solo brazos y cabeza)
	local follow = (0.35 + 0.65 * aim) * (1 - prone)
	add.Waist += V(pitch * 0.35 * follow, 0, 0)
	add.Neck += V(pitch * 0.3 * follow, 0, 0)
	local armPitch = pitch * 0.65 * aim
	arms.RightShoulder += V(armPitch, 0, 0)
	arms.LeftShoulder += V(armPitch * (if s.TwoHands or aim > 0 then 1 else 0), 0, 0)

	-- Mejilla en la culata (armas largas apuntando)
	if s.Stock then
		add.Neck += V(-0.1 * aim, -0.08 * aim, -0.14 * aim)
	end

	-- Correr: un poco de vaivén con el paso
	if sprint > 0 and s.Phase then
		local swing = sin(s.Phase) * 0.12 * sprint
		arms.RightShoulder += V(swing, 0, 0)
		arms.LeftShoulder += V(-swing * 0.5, 0, 0)
	end

	-- Retroceso: arma y brazos atrás y arriba; el hombro, el pecho y la cabeza lo acusan
	local r = math.clamp(s.Recoil, -0.5, 2) * math.max(s.Body, 0)
	if r ~= 0 then
		arms.RightShoulder += V(0.14 * r, 0, 0)
		arms.RightElbow += V(0.22 * r, 0, 0)
		arms.LeftShoulder += V(0.1 * r, 0, 0)
		arms.LeftElbow += V(0.15 * r, 0, 0)
		add.Waist += V(0.05 * r, 0, 0)
		add.Neck += V(0.04 * r, 0, 0)
	end

	-- Recarga
	if s.Reload then
		local down, up = WeaponPose.reloadCurve(s.Reload)
		local k = math.max(down, up)
		arms.LeftShoulder += V(-0.7 * down + 0.2 * up, 0, -0.35 * down + 0.15 * up)
		arms.LeftElbow += V(0.3 * down + 0.5 * up, 0, 0)
		arms.RightShoulder += V(-0.25 * k, 0, 0.1 * k)
		arms.RightElbow += V(0.3 * k, 0, 0)
		add.Neck += V(-0.28 * k, 0.1 * k, 0)
	end

	-- Contra una pared: el cañón se levanta
	local wall = math.clamp(s.Wall, 0, 1)
	if wall > 0 then
		arms.RightShoulder += V(0.7 * wall, 0, 0)
		arms.RightElbow += V(0.4 * wall, 0, 0)
		arms.LeftShoulder += V(0.6 * wall, 0, 0)
		arms.LeftElbow += V(0.4 * wall, 0, 0)
	end

	-- Balanceo apuntando
	local sx, sy = s.SwayX or 0, s.SwayY or 0
	if sx ~= 0 or sy ~= 0 then
		arms.RightShoulder += V(sx, sy, 0)
		arms.LeftShoulder += V(sx, sy, 0)
	end

	for name, v in add do
		add[name] = v * hold
	end
	return { Arms = arms, Add = add, Weight = hold }
end

-- De (x, y, z) a CFrame
function WeaponPose.cframe(v: Vector3): CFrame
	return CFrame.Angles(v.X, v.Y, v.Z)
end

-- ¿Todo es un número normal y los ángulos no se van de madre? (para las pruebas)
function WeaponPose.sane(p: Pose): boolean
	local function ok(v: Vector3): boolean
		return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < pi and math.abs(v.Y) < pi and math.abs(v.Z) < pi
	end
	for _, v in p.Arms do
		if not ok(v) then
			return false
		end
	end
	for _, v in p.Add do
		if not ok(v) then
			return false
		end
	end
	return p.Weight == p.Weight
end

return WeaponPose
