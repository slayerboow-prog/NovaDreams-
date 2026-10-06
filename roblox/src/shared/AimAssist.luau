-- AimAssist: el manejo de las armas en el móvil (estilo shooter móvil): ayuda de apuntado suave,
-- fricción y sensibilidad de la cámara al arrastrar el dedo. Lo usa Controllers/WeaponController.
--
--   * Imán: al apuntar o disparar con el dedo (o el mando), la cámara se desliza poco a poco hacia el
--     objetivo válido más cercano a la mira, solo si está dentro de un cono pequeño (más ancho de cerca,
--     más estrecho de lejos). Al pulsar Apuntar, un tirón corto («snap») hacia él; disparando, suave.
--   * Fricción: con la mira encima de un objetivo, arrastrar el dedo gira un poco menos.
--   * Se apunta al cuerpo (el torso), nunca a la cabeza.
--   * Solo objetivos que el sistema de armas ya da por válidos (los elige el cliente: jugadores con los
--     que se puede pelear, enemigos de tu misión, tu rival de entrenamiento), con línea de visión (nunca
--     a través de paredes), nunca aliados ni gente pacífica de la calle.
--   * Solo con el dedo o el mando: con ratón no hace nada.
-- El servidor (WeaponService) sigue comprobando cada disparo como siempre: esto solo mueve la cámara.
--
-- Funciones puras (sin servicios de Roblox): las prueba scripts/test-shooter.luau.

local AimAssist = {}

-- Valores para ajustar el manejo (grados, segundos, radianes por punto de pantalla)
AimAssist.Config = {
	ConeNear = 8, -- grados de cono a NearDistance o menos
	ConeFar = 3, -- grados de cono a FarDistance o más
	NearDistance = 12, -- studs
	FarDistance = 120, -- studs
	MaxDistance = 220, -- studs: más lejos no ayuda
	AimPull = 5, -- fuerza del imán apuntando (1/s: cuánto del ángulo que falta se corrige por segundo)
	FirePull = 2.5, -- disparando sin apuntar (más suave)
	Snap = 0.6, -- al pulsar Apuntar: parte del ángulo que se corrige de golpe
	Friction = 0.6, -- sensibilidad con la mira encima de un objetivo (x)
	FrictionCone = 2.5, -- grados: «encima de un objetivo»
	TorsoDrop = 0.6, -- studs por debajo del centro del torso (pecho / tripa, nunca la cabeza)
	-- Cámara con el dedo (radianes por punto arrastrado)
	TouchYaw = 0.0075,
	TouchPitch = 0.0055,
	AimSensitivity = 0.6, -- apuntando gira más despacio (x)
	PitchLimit = 80, -- grados arriba y abajo
}

-- ¿Ayuda con este tipo de entrada? (nombre de Enum.UserInputType: "Touch", "Gamepad1"…; ratón y
-- teclado no)
function AimAssist.enabled(inputType: string?): boolean
	if type(inputType) ~= "string" then
		return false
	end
	return inputType == "Touch" or string.sub(inputType, 1, 7) == "Gamepad"
end

-- Cono (en grados) a esa distancia: más ancho de cerca
function AimAssist.coneFor(distance: number): number
	local c = AimAssist.Config
	if distance <= c.NearDistance then
		return c.ConeNear
	elseif distance >= c.FarDistance then
		return c.ConeFar
	end
	local t = (distance - c.NearDistance) / (c.FarDistance - c.NearDistance)
	return c.ConeNear + (c.ConeFar - c.ConeNear) * t
end

-- Ángulo (en grados) entre la dirección de la mira y el punto
function AimAssist.angleTo(origin: Vector3, look: Vector3, point: Vector3): number
	local to = point - origin
	if to.Magnitude < 1e-3 or look.Magnitude < 1e-3 then
		return 180
	end
	local dot = math.clamp(look.Unit:Dot(to.Unit), -1, 1)
	return math.deg(math.acos(dot))
end

export type Candidate = { Point: Vector3, [string]: any }

-- El mejor objetivo: el más cercano a la mira (en ángulo) que esté dentro de su cono, al alcance y
-- a la vista (`visible(c)`: sin paredes en medio; se mira solo de los que van ganando).
-- Devuelve (candidato, ángulo) o nil.
function AimAssist.pick(origin: Vector3, look: Vector3, list: { Candidate }, visible: ((Candidate) -> boolean)?, range: number?): (Candidate?, number)
	local maxDistance = math.min(range or math.huge, AimAssist.Config.MaxDistance)
	local scored = {}
	for _, c in list do
		local distance = (c.Point - origin).Magnitude
		if distance <= maxDistance and distance > 0.5 then
			local angle = AimAssist.angleTo(origin, look, c.Point)
			if angle <= AimAssist.coneFor(distance) then
				table.insert(scored, { C = c, A = angle })
			end
		end
	end
	table.sort(scored, function(a, b)
		return a.A < b.A
	end)
	for _, entry in scored do
		if not visible or visible(entry.C) then
			return entry.C, entry.A
		end
	end
	return nil, 180
end

-- Punto al que se apunta en un cuerpo: el torso (algo por debajo de su centro), nunca la cabeza
function AimAssist.bodyPoint(torso: Vector3): Vector3
	return torso - Vector3.new(0, AimAssist.Config.TorsoDrop, 0)
end

-- Giro (yaw, pitch en radianes) que lleva la mira de `look` hacia `dir`, multiplicado por `amount`
-- (0..1). yaw positivo = hacia la izquierda (como CFrame.Angles(0, yaw, 0)), pitch positivo = arriba.
function AimAssist.turn(look: Vector3, dir: Vector3, amount: number): (number, number)
	local function angles(v: Vector3): (number, number)
		local u = v.Unit
		return math.atan2(-u.X, -u.Z), math.asin(math.clamp(u.Y, -1, 1))
	end
	local yaw0, pitch0 = angles(look)
	local yaw1, pitch1 = angles(dir)
	local dyaw = yaw1 - yaw0
	-- (por el camino corto)
	if dyaw > math.pi then
		dyaw -= 2 * math.pi
	elseif dyaw < -math.pi then
		dyaw += 2 * math.pi
	end
	local k = math.clamp(amount, 0, 1)
	return dyaw * k, (pitch1 - pitch0) * k
end

-- Cuánto se corrige este fotograma (0..1): imán exponencial, más fuerte apuntando
function AimAssist.pullFraction(aiming: boolean, dt: number): number
	local c = AimAssist.Config
	local strength = if aiming then c.AimPull else c.FirePull
	return 1 - math.exp(-strength * math.max(dt, 0))
end

-- Sensibilidad del arrastre: menos apuntando (aim 0..1) y con la mira encima de un objetivo
function AimAssist.sensitivity(aim: number, onTarget: boolean): number
	local c = AimAssist.Config
	local k = 1 + (c.AimSensitivity - 1) * math.clamp(aim, 0, 1)
	if onTarget then
		k *= c.Friction
	end
	return k
end

-- Arrastre del dedo (en puntos) -> giro de la cámara (yaw, pitch en radianes)
function AimAssist.dragTurn(delta: Vector2, aim: number, onTarget: boolean): (number, number)
	local c = AimAssist.Config
	local k = AimAssist.sensitivity(aim, onTarget)
	return -delta.X * c.TouchYaw * k, -delta.Y * c.TouchPitch * k
end

-- ¿Es un objetivo válido para las armas? (lo que ve el cliente de una persona)
-- info: { IsSelf, Alive, Player (bool), CanFight (bool: edad, sin conversación, sin entrenar),
-- Seated, SameTeam, MissionEnemy (de TU misión), Rival (tu rival de entrenamiento), Officer, Npc }
function AimAssist.validTarget(info: { [string]: any }): boolean
	if info.IsSelf or not info.Alive then
		return false
	end
	if info.MissionEnemy or info.Rival then
		return true
	end
	if info.Player then
		return info.CanFight == true and not info.Seated and not info.SameTeam and not info.Protected
	end
	-- La gente de la calle, los agentes y cualquier otro personaje: nunca (son pacíficos)
	return false
end

return AimAssist
