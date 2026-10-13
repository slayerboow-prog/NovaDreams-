-- KartTrack (compartido): el circuito de karts de San Roque (zona 13) y su cronometraje. Sin Roblox
-- (números sueltos, sin Vector3): lo prueba scripts/test-ocio.luau.
--
--   * Trazado: una línea central cerrada (puntos de control suavizados con Catmull-Rom) de unos
--     370 × 220 studs, con recta de meta al sur, horquilla al este, chicane y curva larga al oeste.
--     Coordenadas del sitio: X hacia el este, Z hacia el sur, centro del sitio en (0, 0).
--   * Cronometraje por puertas: 8 puertas repartidas por la vuelta (la 1 es la línea de meta). Hay que
--     pasarlas en orden; al volver a la 1 después de todas se cierra la vuelta (tiempo y mejor vuelta).
--     Si te saltas una (atajo), esa vuelta no cuenta hasta que la pases.
--   * Máquinas: siguen la línea central con una velocidad que baja en las curvas (KartTrack.botSpeed).
--   * Clasificación: las mejores vueltas (una por persona), de menor a mayor (KartTrack.insertBoard).

local KartTrack = {}

KartTrack.WIDTH = 22 -- ancho del asfalto
KartTrack.LAPS = 3
KartTrack.GATES = 8
KartTrack.GATE_RADIUS = 19 -- a esta distancia de la puerta cuenta que la has pasado
KartTrack.KART_SPEED = 58 -- velocidad punta del kart (Gameplay.Vehicles.Kart.Speed)

-- Puntos de control (x, z) en el sentido de la carrera: recta de meta hacia el este
KartTrack.CONTROL = {
	{ -110, 95 },
	{ 0, 98 },
	{ 110, 95 },
	{ 160, 70 },
	{ 172, 20 },
	{ 150, -25 },
	{ 100, -40 },
	{ 50, -20 },
	{ 0, -40 },
	{ -50, -90 },
	{ -110, -100 },
	{ -160, -70 },
	{ -172, -10 },
	{ -165, 50 },
}

local function catmull(p0: { number }, p1: { number }, p2: { number }, p3: { number }, t: number): { number }
	local t2, t3 = t * t, t * t * t
	local out = {}
	for k = 1, 2 do
		out[k] = 0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3)
	end
	return out
end

-- La línea central, cerrada (el último punto NO repite el primero), con `perSpan` puntos por tramo
function KartTrack.centerline(perSpan: number?): { { number } }
	local n = #KartTrack.CONTROL
	local per = perSpan or 4
	local out = {}
	for i = 1, n do
		local p0 = KartTrack.CONTROL[(i - 2) % n + 1]
		local p1 = KartTrack.CONTROL[i]
		local p2 = KartTrack.CONTROL[i % n + 1]
		local p3 = KartTrack.CONTROL[(i + 1) % n + 1]
		for s = 0, per - 1 do
			table.insert(out, catmull(p0, p1, p2, p3, s / per))
		end
	end
	return out
end

local function dist(a: { number }, b: { number }): number
	local dx, dz = a[1] - b[1], a[2] - b[2]
	return math.sqrt(dx * dx + dz * dz)
end
KartTrack.dist = dist

function KartTrack.length(points: { { number } }): number
	local total = 0
	for i = 1, #points do
		total += dist(points[i], points[i % #points + 1])
	end
	return total
end

-- Las puertas: índices de la línea central repartidos por igual; la 1 es la línea de meta (el punto
-- de la recta de meta más cerca de x = 0)
function KartTrack.gates(points: { { number } }, count: number?): { { number } }
	local n = count or KartTrack.GATES
	local start, bestD = 1, math.huge
	for i, p in points do
		local d = math.abs(p[1]) + (if p[2] > 0 then 0 else 1000)
		if d < bestD then
			start, bestD = i, d
		end
	end
	local out = {}
	for g = 0, n - 1 do
		local idx = (start - 1 + math.floor(g * #points / n)) % #points + 1
		table.insert(out, { points[idx][1], points[idx][2], idx })
	end
	return out
end

-- Distancia más corta de un punto a la línea central (para saber si vas por la pista)
function KartTrack.offTrack(points: { { number } }, x: number, z: number): number
	local best = math.huge
	for i = 1, #points do
		local a, b = points[i], points[i % #points + 1]
		local ax, az, bx, bz = a[1], a[2], b[1], b[2]
		local dx, dz = bx - ax, bz - az
		local len2 = dx * dx + dz * dz
		local t = if len2 > 0 then math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) else 0
		local px, pz = ax + dx * t, az + dz * t
		best = math.min(best, math.sqrt((x - px) ^ 2 + (z - pz) ^ 2))
	end
	return best
end

---------------------------------------------------------------------
-- Cronómetro
---------------------------------------------------------------------
export type Timer = {
	Gates: { { number } },
	Laps: number,
	Next: number, -- la puerta que toca (2 al salir: la salida está justo detrás de la meta)
	Lap: number, -- vuelta en curso (1..Laps)
	LapStart: number,
	Start: number,
	Best: number?,
	Times: { number },
	Done: boolean,
}

function KartTrack.newTimer(gates: { { number } }, laps: number?, start: number): Timer
	return { Gates = gates, Laps = laps or KartTrack.LAPS, Next = 2, Lap = 1, LapStart = start, Start = start, Best = nil, Times = {}, Done = false }
end

-- Una posición del kart en el instante t. Devuelve los sucesos: { Kind = "Gate", Gate },
-- { Kind = "Lap", Lap, Time, Best, NewBest }, { Kind = "Finish", Total, Best }
function KartTrack.feed(timer: Timer, t: number, x: number, z: number): { { [string]: any } }
	local events = {}
	if timer.Done then
		return events
	end
	local gate = timer.Gates[timer.Next]
	if dist(gate, { x, z }) <= KartTrack.GATE_RADIUS then
		if timer.Next == 1 then
			local lapTime = t - timer.LapStart
			table.insert(timer.Times, lapTime)
			local newBest = timer.Best == nil or lapTime < timer.Best
			if newBest then
				timer.Best = lapTime
			end
			table.insert(events, { Kind = "Lap", Lap = timer.Lap, Time = lapTime, Best = timer.Best, NewBest = newBest })
			if timer.Lap >= timer.Laps then
				timer.Done = true
				table.insert(events, { Kind = "Finish", Total = t - timer.Start, Best = timer.Best })
				return events
			end
			timer.Lap += 1
			timer.LapStart = t
			timer.Next = 2
		else
			table.insert(events, { Kind = "Gate", Gate = timer.Next })
			timer.Next = timer.Next % #timer.Gates + 1
		end
	end
	return events
end

-- Cuánto llevas de carrera (para ordenar a los pilotos): vueltas hechas + puertas pasadas
function KartTrack.progress(timer: Timer): number
	if timer.Done then
		return timer.Laps * 1000
	end
	local passed = if timer.Next == 1 then #timer.Gates - 1 else timer.Next - 2
	return (timer.Lap - 1) * 1000 + passed
end

---------------------------------------------------------------------
-- Máquinas
---------------------------------------------------------------------
-- Velocidad de una máquina en el punto i de la línea central: más despacio cuanto más cerrada es la
-- curva que viene. skill de 0 a 1 (1 = va casi a tope).
function KartTrack.botSpeed(points: { { number } }, i: number, skill: number): number
	local n = #points
	local a, b, c = points[(i - 2) % n + 1], points[i], points[i % n + 1]
	local c2 = points[(i + 1) % n + 1]
	local function turn(p, q, r)
		local ux, uz = q[1] - p[1], q[2] - p[2]
		local vx, vz = r[1] - q[1], r[2] - q[2]
		local lu, lv = math.sqrt(ux * ux + uz * uz), math.sqrt(vx * vx + vz * vz)
		if lu < 1e-6 or lv < 1e-6 then
			return 0
		end
		local cos = math.clamp((ux * vx + uz * vz) / (lu * lv), -1, 1)
		return math.acos(cos)
	end
	local sharp = math.max(turn(a, b, c), turn(b, c, c2))
	local top = KartTrack.KART_SPEED * (0.72 + 0.22 * math.clamp(skill, 0, 1))
	return top * math.clamp(1 - sharp * 0.9, 0.55, 1)
end

---------------------------------------------------------------------
-- Clasificación y textos
---------------------------------------------------------------------
-- board = { { Name, UserId, Time } } (de menor a mayor). Una fila por persona (se queda la mejor).
-- Devuelve el puesto (o nil si no entra).
function KartTrack.insertBoard(board: { { [string]: any } }, name: string, userId: number, time: number, max: number?): number?
	local limit = max or 10
	for i, row in board do
		if row.UserId == userId then
			if time >= row.Time then
				return nil
			end
			table.remove(board, i)
			break
		end
	end
	table.insert(board, { Name = name, UserId = userId, Time = time })
	table.sort(board, function(a, b)
		return a.Time < b.Time
	end)
	while #board > limit do
		table.remove(board)
	end
	for i, row in board do
		if row.UserId == userId then
			return i
		end
	end
	return nil
end

function KartTrack.formatTime(t: number?): string
	if not t or t ~= t then
		return "--:--.--"
	end
	local m = math.floor(t / 60)
	local s = t - m * 60
	return ("%d:%05.2f"):format(m, s)
end

-- Premio en dinero por puesto (carrera contra la máquina) y diversión
KartTrack.Entry = 15 -- € la tanda (3 vueltas)
KartTrack.Prize = { 30, 15, 8 }
KartTrack.Fun = 12

return KartTrack
