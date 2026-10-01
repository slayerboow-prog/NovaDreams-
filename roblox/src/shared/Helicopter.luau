-- Helicopter: cuentas puras de los helicópteros (rotores y foco). Lo usa Controllers/Helicopters
-- (cliente) y se prueba fuera de Roblox (scripts/test-props.luau).
--
--   * Rotores: giran en cada pantalla (el servidor solo mueve el helicóptero). Velocidad que no
--     hace efecto estroboscópico a 30 fps (dos palas cruzadas = 4 brazos iguales cada 90°: cada
--     fotograma avanza bastante menos de 90°), arranque suave y un disco borroso a toda velocidad.
--   * Foco: una luz de verdad (SpotLight cerca del suelo: el alcance de una luz en Roblox es de 60
--     studs y el helicóptero vuela a 70–90), un haz fino y suave que se desvanece antes del suelo y
--     una mancha de luz en el suelo (elipse según lo inclinado que llega) que sigue al sospechoso
--     con un poco de retraso. El haz nunca encierra la cámara: si la cámara está dentro de la parte
--     visible del haz, se esconde (solo en esa pantalla).

local Helicopter = {}

Helicopter.MainRate = 14 -- rad/s del rotor principal (≈ 2,2 vueltas por segundo)
Helicopter.TailRate = 34 -- rad/s del rotor de cola
Helicopter.SpinUp = 2 -- segundos hasta coger toda la velocidad
Helicopter.Near = 700 -- studs: más lejos no se animan (ni suenan)

Helicopter.Light = {
	Angle = 20, -- apertura del foco (grados, de borde a borde)
	LensBack = 45, -- la luz de verdad se pone a esta distancia de la mancha, en la línea del haz
	MaxRange = 60, -- (alcance máximo de una luz en Roblox)
	Brightness = 6,
	Lag = 2.4, -- lo rápido que la mancha alcanza al objetivo (1/s): se nota que «persigue»
	Snap = 80, -- si el objetivo salta más que esto, la mancha va directa
	MinRadius = 6,
	MaxRadius = 11,
	Visible = 0.72, -- el haz se ve hasta este punto de su largo; luego se desvanece del todo
}

-- Velocidad del rotor (rad/s) a los t segundos de verlo (arranque suave)
function Helicopter.rotorSpeed(t: number, rate: number): number
	local k = math.clamp(t / Helicopter.SpinUp, 0, 1)
	return rate * (k * k * (3 - 2 * k))
end

-- Ángulo del rotor tras dt segundos a esa velocidad (siempre entre 0 y 2π)
function Helicopter.advance(angle: number, dt: number, speed: number): number
	return (angle + speed * math.max(dt, 0)) % (2 * math.pi)
end

-- Cuánto avanza el rotor en un fotograma (rad) y si se ve girar hacia delante: con `arms` brazos
-- iguales, el giro se ve bien si cada fotograma avanza menos de media separación entre brazos
function Helicopter.looksSmooth(rate: number, fps: number, arms: number): boolean
	local step = rate / fps
	return step < (2 * math.pi / arms) / 2
end

-- Transparencia de las palas y del disco borroso según la velocidad (0..1 de la máxima)
function Helicopter.blur(ratio: number): (number, number)
	local k = math.clamp((ratio - 0.4) / 0.6, 0, 1)
	return 0.45 * k, 1 - 0.16 * k -- (palas, disco)
end

-- La mancha persigue al objetivo con retraso (suavizado exponencial, igual con cualquier fps)
function Helicopter.follow(current: Vector3, target: Vector3, dt: number, lag: number?): Vector3
	if (target - current).Magnitude > Helicopter.Light.Snap then
		return target
	end
	local k = 1 - math.exp(-(lag or Helicopter.Light.Lag) * math.max(dt, 0))
	return current:Lerp(target, k)
end

-- Radio de la mancha en el suelo a esa distancia de la lámpara (con la apertura del foco)
function Helicopter.spotRadius(distance: number): number
	local r = distance * math.tan(math.rad(Helicopter.Light.Angle / 2))
	return math.clamp(r, Helicopter.Light.MinRadius, Helicopter.Light.MaxRadius)
end

-- Elipse de la mancha: ancho y largo (el largo se estira cuanto más inclinado llega el haz).
-- dir = de la lámpara al suelo (unitario), normal = la del suelo
function Helicopter.ellipse(dir: Vector3, normal: Vector3, radius: number): (number, number)
	local cos = math.abs(dir:Dot(normal))
	return 2 * radius, 2 * radius / math.max(cos, 0.4)
end

-- Ángulo (grados) de la luz de verdad para que su cono cubra la mancha desde LensBack
function Helicopter.lensAngle(radius: number, back: number): number
	return math.clamp(2 * math.deg(math.atan(radius / math.max(back, 1))), 10, 120)
end

-- ¿Está el punto (la cámara) dentro del haz? El haz va de `apex` (radio r0) a `ground` (radio r1),
-- pero solo cuenta la parte que se ve (hasta Light.Visible del largo). margin: holgura (studs).
function Helicopter.insideBeam(point: Vector3, apex: Vector3, ground: Vector3, r0: number, r1: number, margin: number?): boolean
	local axis = ground - apex
	local length = axis.Magnitude
	if length < 1e-3 then
		return false
	end
	local dir = axis / length
	local rel = point - apex
	local t = rel:Dot(dir) / length
	local m = margin or 2
	if t < -m / length or t > Helicopter.Light.Visible then
		return false
	end
	local radius = r0 + (r1 - r0) * math.clamp(t, 0, 1)
	local off = (rel - dir * rel:Dot(dir)).Magnitude
	return off <= radius + m
end

return Helicopter
