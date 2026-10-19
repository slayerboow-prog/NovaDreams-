-- AimAssist: la ayuda al apuntar con un arma a pie (docs/invasion.md, «Pelear»). Cuentas puras (las
-- prueba scripts/test-shooter.luau); la aplica Controllers/WeaponController.
--
-- Lo que aprendimos de la versión anterior (v98: «se pega a la gente», «el dedo manda»):
--   * SOLO a enemigos: alienígenas de la invasión (InvasionTarget) y enemigos de tu combate de misión
--     (MissionEnemy). NUNCA a jugadores ni a la gente de la calle.
--   * NUNCA mueve la cámara si no la mueves tú: el imán (Magnet) solo actúa mientras giras la cámara o
--     te mueves, y con un tope pequeño de grados por segundo. Quieto, no hace nada.
--   * Fricción (Friction): con la mira encima de un enemigo, tu giro va algo más despacio (no se escapa).
--   * Imán de la bala (Bullet): un disparo que pasa muy cerca del enemigo (pocos grados) le da.
--   * Se puede apagar (⚙️ «Ayuda al apuntar»: shared/ShooterPrefs); con el ratón va casi apagada.
--
-- Perfiles: Touch (móvil), Gamepad (mando) y Mouse (ratón). Ángulos en grados.

local AimAssist = {}

export type Profile = {
	Cone: number, -- grados: fuera de esto, nada
	Inner: number, -- grados: dentro, fricción máxima (la mira está encima)
	Friction: number, -- 0..1: lo que queda de tu giro con la mira encima (1 = nada de fricción)
	Magnet: number, -- grados por segundo como mucho hacia el enemigo (solo mientras giras o andas)
	Bullet: number, -- grados: imán de la bala
	Range: number, -- studs
}

AimAssist.Profiles = {
	Touch = { Cone = 9, Inner = 2.5, Friction = 0.45, Magnet = 14, Bullet = 3.2, Range = 170 },
	Gamepad = { Cone = 7, Inner = 2.2, Friction = 0.5, Magnet = 10, Bullet = 2.4, Range = 170 },
	Mouse = { Cone = 3, Inner = 1, Friction = 1, Magnet = 0, Bullet = 0.8, Range = 170 },
} :: { [string]: Profile }

export type Candidate = { Id: any, Pos: Vector3, Radius: number }

function AimAssist.profileFor(touch: boolean, gamepad: boolean): string
	if touch then
		return "Touch"
	elseif gamepad then
		return "Gamepad"
	end
	return "Mouse"
end

-- ¿Se puede apuntar con ayuda a esto? Solo enemigos (nunca jugadores ni gente de la calle)
function AimAssist.isEnemy(attrs: { [string]: any }): boolean
	if attrs.IsPlayer then
		return false
	end
	return attrs.InvasionTarget ~= nil or attrs.MissionEnemy ~= nil
end

-- Ángulo (grados) entre lo que mira la cámara y el punto, descontando su tamaño (radio angular)
function AimAssist.angleTo(look: Vector3, origin: Vector3, point: Vector3, radius: number?): (number, number)
	local to = point - origin
	local d = to.Magnitude
	if d < 1e-3 or look.Magnitude < 1e-6 then
		return 0, d
	end
	local cos = math.clamp(to.Unit:Dot(look.Unit), -1, 1)
	local a = math.deg(math.acos(cos))
	local r = math.deg(math.atan((radius or 0) / d))
	return math.max(0, a - r * 0.6), d
end

-- El mejor candidato dentro del cono (el de menor ángulo; a igualdad, el más cercano)
function AimAssist.pick(look: Vector3, origin: Vector3, list: { Candidate }, p: Profile): (Candidate?, number)
	local best, bestScore, bestAngle = nil, math.huge, math.huge
	for _, c in list do
		local a, d = AimAssist.angleTo(look, origin, c.Pos, c.Radius)
		if a <= p.Cone and d <= p.Range then
			local score = a + d * 0.01
			if score < bestScore then
				best, bestScore, bestAngle = c, score, a
			end
		end
	end
	return best, bestAngle
end

-- Lo que queda de tu giro (0..1) con la mira a `angle` grados del enemigo
function AimAssist.friction(angle: number?, p: Profile): number
	if angle == nil or angle >= p.Cone then
		return 1
	end
	if angle <= p.Inner then
		return p.Friction
	end
	local k = (angle - p.Inner) / math.max(p.Cone - p.Inner, 1e-3)
	return p.Friction + (1 - p.Friction) * k
end

-- El imán: cuántos grados girar hacia el enemigo este fotograma (yaw, pitch en radianes, en el sentido de
-- la cámara). Cero si no estás girando ni andando (nunca mueve la cámara por su cuenta), si ya estás
-- encima o fuera del cono.
function AimAssist.magnet(look: Vector3, origin: Vector3, target: Vector3, p: Profile, dt: number, active: boolean): (number, number)
	if not active or p.Magnet <= 0 then
		return 0, 0
	end
	local to = target - origin
	if to.Magnitude < 1e-3 or look.Magnitude < 1e-6 then
		return 0, 0
	end
	local cur = look.Unit
	local want = to.Unit
	local yaw0 = math.atan2(-cur.X, -cur.Z)
	local yaw1 = math.atan2(-want.X, -want.Z)
	local dyaw = (yaw1 - yaw0 + math.pi) % (2 * math.pi) - math.pi
	local dpitch = math.asin(math.clamp(want.Y, -1, 1)) - math.asin(math.clamp(cur.Y, -1, 1))
	local total = math.sqrt(dyaw * dyaw + dpitch * dpitch)
	local angle = math.deg(total)
	if angle > p.Cone or angle < p.Inner * 0.3 then
		return 0, 0
	end
	local step = math.rad(p.Magnet) * dt
	if total <= step then
		return dyaw, dpitch
	end
	return dyaw / total * step, dpitch / total * step
end

-- El imán de la bala: si el disparo pasa a menos de Bullet grados del enemigo, va a él
function AimAssist.bend(origin: Vector3, dir: Vector3, target: Vector3?, p: Profile): Vector3
	if not target or dir.Magnitude < 1e-6 then
		return dir
	end
	local to = target - origin
	if to.Magnitude < 1e-3 or to.Magnitude > p.Range then
		return dir
	end
	local a = math.deg(math.acos(math.clamp(to.Unit:Dot(dir.Unit), -1, 1)))
	-- (de cerca se perdona un poco más)
	local allowed = p.Bullet * (if to.Magnitude < 12 then 1.6 else 1)
	if a <= allowed then
		return to.Unit * dir.Magnitude
	end
	return dir
end

-- ¿Dispara solo? (móvil con «Disparo automático»): con la mira encima de un enemigo que se ve
function AimAssist.autoFire(angle: number?, p: Profile, visible: boolean): boolean
	return visible and angle ~= nil and angle <= math.max(p.Inner, p.Bullet * 0.8)
end

return AimAssist
