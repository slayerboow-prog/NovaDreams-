-- ArcadeHoops (compartido): la máquina de canastas de los recreativos, con la física de verdad del
-- baloncesto (Sports/Hoops). La jaula de la máquina es una «pista» pequeñita (Sports/Court): el aro y el
-- tablero de la máquina, el suelo de la jaula y sus redes a los lados como paredes.
--   * Mantén «Tirar»: la barra de fuerza sube y baja. Suelta en la franja dorada y el balón entra
--     limpio; un poco antes o después se queda corto o largo (y puede tocar aro y entrar… o no).
--   * Puedes tener varios balones en el aire a la vez; cada canasta seguida acelera la barra.
-- La usa el cliente (Controllers/Arcade); el servidor solo pone topes a la puntuación (ArcadeService).
-- Se prueba en scripts/test-baloncesto.luau.

local Court = require(script.Parent.Court)
local Hoops = require(script.Parent.Hoops)

local ArcadeHoops = {}

ArcadeHoops.Sweet = 0.74 -- fuerza ideal (centro de la franja dorada)
ArcadeHoops.Window = 0.045 -- media franja dorada
ArcadeHoops.Tolerance = 0.3 -- a esta distancia de la ideal, el tiro es malísimo
ArcadeHoops.Period = 0.9 -- segundos de 0 a 1 de la barra (al principio)
ArcadeHoops.Speedup = 0.05 -- cada canasta seguida, la barra va un 5 % más rápida (hasta el doble)
ArcadeHoops.Reload = 0.32 -- segundos entre balón y balón
ArcadeHoops.MaxInAir = 3
ArcadeHoops.Life = 3.2 -- segundos que vive un balón tirado

export type Machine = {
	Court: Court.Court,
	From: Vector3, -- de dónde sale el balón (local: encima del mostrador)
}

-- La máquina a partir de sus piezas (posiciones y tamaños del mundo):
--   shooter: dónde se tira (encima del mostrador), hoop/hoopRadius: el aro, board/boardSize: el
--   tablero, floorY: la altura del suelo de la jaula, halfWidth: media anchura de la jaula
function ArcadeHoops.machine(shooter: Vector3, hoop: Vector3, hoopRadius: number, board: Vector3, boardSize: Vector3, floorY: number, halfWidth: number?): Machine
	local flat = Vector3.new(hoop.X - shooter.X, 0, hoop.Z - shooter.Z)
	local axis = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(1, 0, 0)
	local boardFlat = Vector3.new(board.X, 0, board.Z)
	local shooterFlat = Vector3.new(shooter.X, 0, shooter.Z)
	-- (el centro, un poco por detrás del que tira: la pared invisible de atrás no le toca)
	local mid = (boardFlat + shooterFlat - axis * 1.5) / 2
	local cf = CFrame.fromMatrix(Vector3.new(mid.X, floorY, mid.Z), axis, Vector3.new(0, 1, 0))
	local rim = cf:PointToObjectSpace(hoop)
	local boardLocal = cf:PointToObjectSpace(board)
	local sizes = { boardSize.X, boardSize.Y, boardSize.Z }
	table.sort(sizes)
	local h: Court.Hoop = {
		Side = 1,
		Rim = rim,
		Radius = hoopRadius,
		Board = boardLocal,
		BoardHalf = Vector2.new(sizes[3] / 2, sizes[2] / 2),
		Normal = Vector3.new(-1, 0, 0),
	}
	local length = boardLocal.X * 2
	local court = Court.new(cf, length, (halfWidth or 2.4) * 2, { [1] = h }, { Id = "Recreativos", BoardMargin = 0 })
	court.BoardX = boardLocal.X + 0.05
	court.BoardZ = halfWidth or 2.4
	return { Court = court, From = cf:PointToObjectSpace(shooter) }
end

-- La barra de fuerza (0..1, sube y baja) a los `held` segundos de mantener, con la racha `streak`
function ArcadeHoops.meter(held: number, streak: number?): number
	local period = ArcadeHoops.Period / math.min(2, 1 + ArcadeHoops.Speedup * (streak or 0))
	local f = (math.max(0, held) / period) % 2
	return if f <= 1 then f else 2 - f
end

-- Calidad del lanzamiento (0..1) según la fuerza al soltar
function ArcadeHoops.quality(power: number): number
	local d = math.abs(power - ArcadeHoops.Sweet)
	if d <= ArcadeHoops.Window then
		return 1
	end
	return math.clamp(1 - (d - ArcadeHoops.Window) / ArcadeHoops.Tolerance, 0, 1)
end

-- El tiro: un balón nuevo con su velocidad. Con fuerza de más se va largo, con menos se queda corto
-- (y el error de Hoops.shotError por la calidad). rng: Random
function ArcadeHoops.shoot(m: Machine, power: number, rng: any): Hoops.State
	local hoop = m.Court.Hoops[1]
	local s = Hoops.new(m.From)
	local distance = Vector3.new(hoop.Rim.X - m.From.X, 0, hoop.Rim.Z - m.From.Z).Magnitude
	local v = Hoops.shotVelocity(m.From, hoop.Rim, Hoops.arcFor(distance) * 0.8)
	-- Fuerza: lo que se pasa o le falta respecto a la ideal (fuera de la franja dorada)
	local off = power - ArcadeHoops.Sweet
	local excess = math.sign(off) * math.max(0, math.abs(off) - ArcadeHoops.Window)
	v = Vector3.new(v.X, 0, v.Z) * (1 + excess * (if excess > 0 then 2 else 1.1)) + Vector3.new(0, v.Y * (1 + excess * 0.5), 0)
	s.V = Hoops.shotError(v, ArcadeHoops.quality(power), distance, 0, rng)
	return s
end

-- Avanza un balón: devuelve true si ha entrado en este paso
function ArcadeHoops.step(m: Machine, s: Hoops.State, dt: number): (boolean, { any })
	local events = Hoops.step(s, dt, m.Court)
	for _, e in events do
		if e.Kind == "Basket" then
			return true, events
		end
	end
	return false, events
end

return ArcadeHoops
