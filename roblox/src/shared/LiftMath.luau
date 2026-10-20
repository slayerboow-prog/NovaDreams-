-- LiftMath: las cuentas del viaje del ascensor (las comparten el servidor, World/Lift, y el cliente,
-- Controllers/LiftRide, para que los dos vean la cabina en el mismo sitio en cada momento).

local Floors = require(script.Parent.Floors)

local LiftMath = {}

LiftMath.Speed = 16 -- studs por segundo (a velocidad de crucero)
LiftMath.MinTrip = 2.2 -- segundos (aunque sea una planta)

-- Arranque y frenada suaves (seno): fracción del recorrido en la fracción t del tiempo
function LiftMath.ease(t: number): number
	t = math.clamp(t, 0, 1)
	return (1 - math.cos(math.pi * t)) / 2
end

-- Cuánto dura un viaje de una planta a otra
function LiftMath.duration(fromFloor: number, toFloor: number): number
	local distance = math.abs(toFloor - fromFloor) * Floors.Height
	return math.max(LiftMath.MinTrip, distance / LiftMath.Speed * 1.35)
end

-- Altura del suelo de la cabina (desde el suelo de la planta baja) en el segundo `elapsed` del viaje
function LiftMath.heightAt(fromFloor: number, toFloor: number, elapsed: number, duration: number): number
	local a, b = fromFloor * Floors.Height, toFloor * Floors.Height
	return a + (b - a) * LiftMath.ease(elapsed / duration)
end

return LiftMath
