-- Ball (compartido): la física del balón de fútbol, en coordenadas del campo (Sports/Pitch).
--
-- No usa la física de Roblox: el balón es una cuenta (posición, velocidad y efecto) que el servidor
-- lleva con autoridad y que cada cliente repite igual para verlo fluido (sin dueño de red, sin
-- tirones ni balones que atraviesan paredes). Paso fijo con sub-pasos de 1/120 s.
--
--   Ball.new(p)                      estado nuevo en p (local)
--   Ball.step(state, dt, pitch, bodies?) -> eventos   un paso de física (gravedad, aire, efecto,
--                                    bote, rodar, postes, larguero, red, cuerpos y vallas invisibles)
--   Ball.shotVelocity(dir, power, loft, curl) -> (V, Spin)   el disparo (power 0..1)
--   Ball.passVelocity(dir, distance, lofted) -> V            un pase que llega a `distance` sin pasarse
--   Ball.carryPosition(feet, facing, speed, phase) -> P      el balón pegado al pie al conducir
--   Ball.crossX(state, pitch, x, maxT) -> (t, P)?            cuándo y dónde cruzará el plano X = x
--   Ball.predict(state, pitch, seconds, bodies?) -> {P}      la trayectoria (IA)
--
-- Eventos de un paso: { Kind = "Goal", Side } | "Post" | "Bar" | "Net" | "Bounce" | "Block" (Id) |
-- "Board". Las pruebas: scripts/test-futbol.luau.

local Pitch = require(script.Parent.Pitch)

local Ball = {}

export type State = {
	P: Vector3,
	V: Vector3,
	Spin: number, -- efecto (giro sobre el eje vertical, rad/s): curva el balón hacia un lado
	InGoal: number, -- 0, o el lado de la portería en la que ha entrado (ya no puede salir por delante)
	Ignore: string?, -- no choca con este cuerpo (quien acaba de chutar) hasta IgnoreUntil
	IgnoreUntil: number,
	T: number, -- tiempo de la simulación (s)
}

export type Body = {
	Id: string,
	A: Vector3, -- segmento del cuerpo (de los pies a la cabeza, o tumbado en una estirada)
	B: Vector3,
	R: number,
	Save: boolean?, -- manos del portero (el choque es una parada)
}

export type Event = { Kind: string, Side: number?, Id: string?, Speed: number? }

Ball.Config = {
	Radius = Pitch.BALL_RADIUS,
	Gravity = 78, -- studs/s² (más que la real a esta escala: el balón no flota)
	AirDrag = 0.10, -- frenado en el aire (por segundo)
	Magnus = 0.034, -- curva por unidad de efecto y de velocidad
	SpinDecay = 0.55, -- el efecto se pierde (por segundo)
	Restitution = 0.52, -- bote en el césped
	BounceMin = 3.5, -- por debajo, deja de botar y rueda
	GroundGrip = 0.9, -- cada bote frena un poco en horizontal
	RollDecel = 3.2, -- frenado constante rodando (studs/s²)
	RollDrag = 0.75, -- frenado proporcional rodando (por segundo)
	StopSpeed = 0.35,
	PostRestitution = 0.62,
	NetRestitution = 0.08,
	NetFriction = 0.55, -- la red se traga la velocidad
	BodyRestitution = 0.32,
	BoardRestitution = 0.4,
	SubStep = 1 / 120,
	Shot = { Min = 38, Max = 98, LowLift = 2.5, HighLift = 17, LoftLift = 15 },
	Pass = { Arrive = 13, Max = 75, LobMin = 46 },
}
local C = Ball.Config

function Ball.new(p: Vector3?): State
	return {
		P = p or Vector3.new(0, C.Radius, 0),
		V = Vector3.zero,
		Spin = 0,
		InGoal = 0,
		Ignore = nil,
		IgnoreUntil = 0,
		T = 0,
	}
end

function Ball.copy(s: State): State
	return {
		P = s.P,
		V = s.V,
		Spin = s.Spin,
		InGoal = s.InGoal,
		Ignore = s.Ignore,
		IgnoreUntil = s.IgnoreUntil,
		T = s.T,
	}
end

-- Pone el balón quieto en el suelo en p (reanudaciones)
function Ball.place(s: State, p: Vector3)
	s.P = Vector3.new(p.X, C.Radius, p.Z)
	s.V = Vector3.zero
	s.Spin = 0
	s.InGoal = 0
	s.Ignore = nil
end

local function finite(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

---------------------------------------------------------------------
-- Choques
---------------------------------------------------------------------

-- Punto más cercano de un segmento AB a P
local function closestOnSegment(a: Vector3, b: Vector3, p: Vector3): Vector3
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-8 then
		return a
	end
	local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
	return a + ab * t
end
Ball.closestOnSegment = closestOnSegment

-- Rebota la esfera contra un punto de contacto `q` a distancia mínima `minDist`.
-- Devuelve true si ha chocado (y viene hacia él).
local function bounceOff(s: State, q: Vector3, minDist: number, e: number, friction: number, fallbackNormal: Vector3): boolean
	local d = s.P - q
	local dist = d.Magnitude
	if dist >= minDist then
		return false
	end
	local n = if dist > 1e-5 then d / dist else fallbackNormal
	s.P = q + n * minDist
	local vn = s.V:Dot(n)
	if vn < 0 then
		local normal = n * vn
		local tangent = s.V - normal
		s.V = tangent * friction - normal * e
		return true
	end
	return false
end

-- Choque con un rectángulo plano alineado con los ejes del campo (la red): min/max con un eje igual
local function rectHit(s: State, lo: Vector3, hi: Vector3, normal: Vector3): boolean
	local q = Vector3.new(math.clamp(s.P.X, lo.X, hi.X), math.clamp(s.P.Y, lo.Y, hi.Y), math.clamp(s.P.Z, lo.Z, hi.Z))
	-- (la normal de respaldo: hacia el lado en el que estaba el balón)
	local side = if (s.P - q):Dot(normal) >= 0 then normal else -normal
	return bounceOff(s, q, C.Radius, C.NetRestitution, C.NetFriction, side)
end

-- La portería del lado `side`: postes, larguero y red. Devuelve el tipo de choque o nil.
local function goalFrame(s: State, pitch: Pitch.Pitch, side: number): string?
	local gl, hw, gh, gd = pitch.GoalLine, pitch.GoalWidth / 2, pitch.GoalHeight, pitch.GoalDepth
	if hw <= 0 then
		return nil -- (campo sin porterías)
	end
	local x = side * gl
	-- Lejos de esta portería: nada que mirar
	if math.abs(s.P.X - x) > gd + 3 or math.abs(s.P.Z) > hw + 3 or s.P.Y > gh + 3 then
		return nil
	end
	local hit: string? = nil
	local minDist = C.Radius + pitch.PostRadius
	for _, z in { -hw, hw } do
		local q = closestOnSegment(Vector3.new(x, 0, z), Vector3.new(x, gh, z), s.P)
		if bounceOff(s, q, minDist, C.PostRestitution, 0.95, Vector3.new(-side, 0, 0)) then
			hit = "Post"
		end
	end
	local qBar = closestOnSegment(Vector3.new(x, gh, -hw), Vector3.new(x, gh, hw), s.P)
	if bounceOff(s, qBar, minDist, C.PostRestitution, 0.95, Vector3.new(-side, 0, 0)) then
		hit = "Bar"
	end
	-- Red: laterales, fondo y techo (sirve por dentro y por fuera)
	local far = x + side * gd
	local x0, x1 = math.min(x, far), math.max(x, far)
	local net = false
	for _, z in { -hw, hw } do
		if rectHit(s, Vector3.new(x0, 0, z), Vector3.new(x1, gh, z), Vector3.new(0, 0, if z > 0 then 1 else -1)) then
			net = true
		end
	end
	if rectHit(s, Vector3.new(far, 0, -hw), Vector3.new(far, gh, hw), Vector3.new(side, 0, 0)) then
		net = true
	end
	if rectHit(s, Vector3.new(x0, gh, -hw), Vector3.new(x1, gh, hw), Vector3.new(0, 1, 0)) then
		net = true
	end
	if net and not hit then
		hit = "Net"
	end
	return hit
end

---------------------------------------------------------------------
-- Paso
---------------------------------------------------------------------

local function subStep(s: State, h: number, pitch: Pitch.Pitch, bodies: { Body }?, events: { Event })
	local r = C.Radius
	local airborne = s.P.Y > r + 0.03 or s.V.Y > 0.6
	local v = s.V
	if airborne then
		-- Gravedad, efecto (Magnus) y aire
		local horizontal = Vector3.new(v.X, 0, v.Z)
		local magnus = Vector3.new(horizontal.Z, 0, -horizontal.X) * (C.Magnus * s.Spin)
		v = v + (Vector3.new(0, -C.Gravity, 0) + magnus) * h
		v = v * math.exp(-C.AirDrag * h)
	else
		-- Rodando: frena (constante + proporcional) y el efecto curva poco
		local horizontal = Vector3.new(v.X, 0, v.Z)
		local speed = horizontal.Magnitude
		local slower = math.max(0, speed - (C.RollDecel + C.RollDrag * speed) * h)
		if slower < C.StopSpeed then
			horizontal = Vector3.zero
		elseif speed > 1e-6 then
			local magnus = Vector3.new(horizontal.Z, 0, -horizontal.X) * (C.Magnus * 0.35 * s.Spin)
			horizontal = horizontal * (slower / speed) + magnus * h
		end
		v = horizontal
	end
	s.Spin *= math.exp(-C.SpinDecay * h * (if airborne then 1 else 3))
	s.V = v
	local before = s.P
	s.P = s.P + v * h

	-- Suelo
	if s.P.Y < r then
		s.P = Vector3.new(s.P.X, r, s.P.Z)
		if s.V.Y < -C.BounceMin then
			table.insert(events, { Kind = "Bounce", Speed = -s.V.Y })
			s.V = Vector3.new(s.V.X * C.GroundGrip, -s.V.Y * C.Restitution, s.V.Z * C.GroundGrip)
		elseif s.V.Y < 0 then
			s.V = Vector3.new(s.V.X, 0, s.V.Z)
		end
	end

	-- Gol: el balón entero pasa la línea entre los postes y por debajo del larguero
	if s.InGoal == 0 and pitch.GoalWidth > 0 then
		for _, side in { -1, 1 } do
			local line = pitch.GoalLine + r
			if before.X * side < line and s.P.X * side >= line and math.abs(s.P.Z) < pitch.GoalWidth / 2 and s.P.Y < pitch.GoalHeight then
				s.InGoal = side
				table.insert(events, { Kind = "Goal", Side = side })
			end
		end
	end

	-- Porterías
	for _, side in { -1, 1 } do
		local hit = goalFrame(s, pitch, side)
		if hit then
			table.insert(events, { Kind = hit, Side = side, Speed = s.V.Magnitude })
		end
	end

	-- Cuerpos (jugadores y manos del portero)
	if bodies then
		for _, body in bodies do
			if s.Ignore == body.Id and s.T < s.IgnoreUntil then
				continue
			end
			local q = closestOnSegment(body.A, body.B, s.P)
			local incoming = s.V.Magnitude
			if bounceOff(s, q, r + body.R, C.BodyRestitution, 0.7, Vector3.new(0, 1, 0)) then
				table.insert(events, { Kind = "Block", Id = body.Id, Speed = incoming, Side = if body.Save then 1 else 0 })
			end
		end
	end

	-- Vallas invisibles (el recinto del campo)
	local bx, bz = pitch.BoardX - r, pitch.BoardZ - r
	if math.abs(s.P.X) > bx then
		s.P = Vector3.new(math.sign(s.P.X) * bx, s.P.Y, s.P.Z)
		s.V = Vector3.new(-s.V.X * C.BoardRestitution, s.V.Y, s.V.Z * 0.8)
		table.insert(events, { Kind = "Board" })
	end
	if math.abs(s.P.Z) > bz then
		s.P = Vector3.new(s.P.X, s.P.Y, math.sign(s.P.Z) * bz)
		s.V = Vector3.new(s.V.X * 0.8, s.V.Y, -s.V.Z * C.BoardRestitution)
		table.insert(events, { Kind = "Board" })
	end
	if s.P.Y > 60 then
		s.P = Vector3.new(s.P.X, 60, s.P.Z)
		s.V = Vector3.new(s.V.X, math.min(s.V.Y, 0), s.V.Z)
	end
	s.T += h
end

function Ball.step(s: State, dt: number, pitch: Pitch.Pitch, bodies: { Body }?): { Event }
	local events: { Event } = {}
	if dt <= 0 then
		return events
	end
	local n = math.max(1, math.ceil(dt / C.SubStep - 1e-6))
	local h = dt / n
	for _ = 1, n do
		subStep(s, h, pitch, bodies, events)
	end
	-- Nunca un NaN en el balón (un dato raro del cliente, un cero entre cero…): al centro y quieto
	if not finite(s.P) or not finite(s.V) or s.Spin ~= s.Spin then
		Ball.place(s, Vector3.zero)
	end
	return events
end

-- ¿Está quieto (o casi) en el suelo?
function Ball.resting(s: State): boolean
	return s.P.Y <= C.Radius + 0.05 and s.V.Magnitude < 1
end

---------------------------------------------------------------------
-- Golpeos
---------------------------------------------------------------------

-- Un disparo hacia `dir` (plano). power 0..1 (más fuerte = más rápido y más alto: pasarse de fuerza
-- manda el balón por encima del larguero). loft 0..1 = vaselina. curl -1..1 = efecto.
function Ball.shotVelocity(dir: Vector3, power: number, loft: number?, curl: number?): (Vector3, number)
	local d = Pitch.unitFlat(dir)
	local p = math.clamp(power, 0, 1)
	local l = math.clamp(loft or 0, 0, 1)
	local speed = C.Shot.Min + (C.Shot.Max - C.Shot.Min) * (p ^ 0.9)
	local lift = C.Shot.LowLift + (C.Shot.HighLift - C.Shot.LowLift) * (p * p) + C.Shot.LoftLift * l
	local forward = speed * (1 - 0.45 * l)
	local spin = math.clamp(curl or 0, -1, 1) * 9
	return d * forward + Vector3.new(0, lift, 0), spin
end

-- Distancia que recorre rodando desde v0 hasta frenar a vf (frenado constante c + proporcional k)
local function rollDistance(v0: number, vf: number): number
	local c, k = C.RollDecel, C.RollDrag
	if v0 <= vf then
		return 0
	end
	return (v0 - vf) / k - (c / (k * k)) * math.log((c + k * v0) / (c + k * vf))
end
Ball.rollDistance = rollDistance

-- Un pase raso que llega a `distance` con algo de velocidad (Pass.Arrive); lofted o muy largo: por alto
function Ball.passVelocity(dir: Vector3, distance: number, lofted: boolean?): Vector3
	local d = Pitch.unitFlat(dir)
	local dist = math.max(1, distance)
	if lofted or dist > C.Pass.LobMin then
		-- Por alto: tiempo de vuelo según la distancia; cae un poco antes del compañero
		local horizontal = math.clamp(dist * 1.05, 26, 62)
		local t = (dist * 0.9) / horizontal
		local up = C.Gravity * t / 2
		return d * horizontal + Vector3.new(0, up, 0)
	end
	-- Raso: la velocidad justa para llegar (búsqueda por mitades)
	local lo, hi = C.Pass.Arrive, C.Pass.Max
	for _ = 1, 30 do
		local mid = (lo + hi) / 2
		if rollDistance(mid, C.Pass.Arrive) < dist then
			lo = mid
		else
			hi = mid
		end
	end
	return d * ((lo + hi) / 2) + Vector3.new(0, 1.5, 0)
end

-- El balón al pie mientras conduces: delante de los pies, y con cada zancada se adelanta un poco y
-- vuelve (los toques). phase: distancia recorrida (studs); speed: velocidad del jugador.
function Ball.carryPosition(feet: Vector3, facing: Vector3, speed: number, phase: number): Vector3
	local f = Pitch.unitFlat(facing)
	local run = math.clamp(speed / 16, 0, 1.3)
	local touch = 0.5 * (1 - math.cos(phase / 4.5 * 2 * math.pi)) -- 0 → 1 → 0 cada zancada
	local ahead = 1.5 + C.Radius + run * (0.4 + 1.1 * touch)
	local p = feet + f * ahead
	return Vector3.new(p.X, C.Radius, p.Z)
end

---------------------------------------------------------------------
-- Predicción (IA y porteros)
---------------------------------------------------------------------

function Ball.predict(s: State, pitch: Pitch.Pitch, seconds: number, bodies: { Body }?, h: number?): { Vector3 }
	local copy = Ball.copy(s)
	local step = h or 1 / 30
	local out = {}
	local t = 0
	while t < seconds do
		Ball.step(copy, step, pitch, bodies)
		t += step
		table.insert(out, copy.P)
		if copy.InGoal ~= 0 then
			break
		end
	end
	return out
end

-- Cuándo (t) y dónde (P) cruzará el plano X = x, o nil si no llega en maxT
function Ball.crossX(s: State, pitch: Pitch.Pitch, x: number, maxT: number?): (number?, Vector3?)
	local copy = Ball.copy(s)
	copy.InGoal = 1 -- (para que no se cuente gol en la predicción)
	local step = 1 / 60
	local t = 0
	local limit = maxT or 2
	local sideNow = math.sign(copy.P.X - x)
	if sideNow == 0 then
		return 0, copy.P
	end
	while t < limit do
		local before = copy.P
		local evs = {}
		subStep(copy, step, pitch, nil, evs)
		t += step
		if math.sign(copy.P.X - x) ~= sideNow then
			-- Interpolación lineal al plano
			local span = copy.P.X - before.X
			local f = if math.abs(span) > 1e-6 then (x - before.X) / span else 1
			return t - step + step * f, before:Lerp(copy.P, math.clamp(f, 0, 1))
		end
		if copy.V.Magnitude < 0.5 and copy.P.Y <= C.Radius + 0.05 then
			return nil, nil
		end
	end
	return nil, nil
end

return Ball
