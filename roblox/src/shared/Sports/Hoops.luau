-- Hoops (compartido): la física del balón de baloncesto en coordenadas de la pista (Sports/Court).
-- Como Sports/Ball (el de fútbol): una cuenta que lleva el servidor y que cada cliente repite igual.
--
--   Hoops.step(state, dt, court, bodies?) -> eventos: Bounce, Rim, Board, Basket (Side), Wall
--   Hoops.shotVelocity(from, rim, arc) -> V            la parábola exacta que entra limpia por el aro
--   Hoops.shotError(V, quality, distance, contest, rng) -> V   el tiro con el error de tu lanzamiento
--   Hoops.dribblePosition(feet, facing, right, phase, scale) -> P   el bote al conducir
--
-- La canasta cuenta cuando el balón BAJA por dentro del aro (no si sube por debajo). El aro es un toro
-- (un círculo con grosor): el balón puede tocar aro, dar vueltas y entrar o salirse; el tablero rebota.

local Court = require(script.Parent.Court)

local Hoops = {}

export type State = {
	P: Vector3,
	V: Vector3,
	T: number,
	Scored: boolean, -- ya ha entrado en este tiro (no cuenta dos veces)
	Ignore: string?,
	IgnoreUntil: number,
}

Hoops.Config = {
	Radius = Court.BALL_RADIUS,
	Gravity = 70,
	Restitution = 0.78, -- bote en el suelo
	RimRestitution = 0.5,
	BoardRestitution = 0.62,
	RimTube = 0.12, -- grosor del aro
	Friction = 0.7, -- rodando por el suelo (por segundo)
	SubStep = 1 / 120,
	BodyRestitution = 0.3,
	WallRestitution = 0.45,
}
local C = Hoops.Config

function Hoops.new(p: Vector3?): State
	return { P = p or Vector3.new(0, C.Radius, 0), V = Vector3.zero, T = 0, Scored = false, Ignore = nil, IgnoreUntil = 0 }
end

function Hoops.copy(s: State): State
	return { P = s.P, V = s.V, T = s.T, Scored = s.Scored, Ignore = s.Ignore, IgnoreUntil = s.IgnoreUntil }
end

function Hoops.place(s: State, p: Vector3)
	s.P = Vector3.new(p.X, math.max(p.Y, C.Radius), p.Z)
	s.V = Vector3.zero
	s.Scored = false
	s.Ignore = nil
end

local function bounceOff(s: State, q: Vector3, minDist: number, e: number, fallback: Vector3): boolean
	local d = s.P - q
	local dist = d.Magnitude
	if dist >= minDist then
		return false
	end
	local n = if dist > 1e-5 then d / dist else fallback
	s.P = q + n * minDist
	local vn = s.V:Dot(n)
	if vn < 0 then
		local normal = n * vn
		s.V = (s.V - normal) * 0.92 - normal * e
		return true
	end
	return false
end

local function segment(a: Vector3, b: Vector3, p: Vector3): Vector3
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-8 then
		return a
	end
	return a + ab * math.clamp((p - a):Dot(ab) / len2, 0, 1)
end

local function subStep(s: State, h: number, court: Court.Court, bodies: { any }?, events: { any })
	local r = C.Radius
	local before = s.P
	s.V = s.V + Vector3.new(0, -C.Gravity, 0) * h
	s.P = s.P + s.V * h
	-- Suelo
	if s.P.Y < r then
		s.P = Vector3.new(s.P.X, r, s.P.Z)
		if s.V.Y < -2 then
			table.insert(events, { Kind = "Bounce", Speed = -s.V.Y })
			s.V = Vector3.new(s.V.X * 0.95, -s.V.Y * C.Restitution, s.V.Z * 0.95)
		else
			s.V = Vector3.new(s.V.X, 0, s.V.Z) * math.exp(-C.Friction * h)
		end
	end
	for side, hoop in court.Hoops do
		local rim = hoop.Rim
		-- Canasta: baja por el plano del aro por dentro
		if not s.Scored and before.Y >= rim.Y and s.P.Y < rim.Y and s.V.Y < 0 then
			local f = (before.Y - rim.Y) / math.max(before.Y - s.P.Y, 1e-6)
			local at = before:Lerp(s.P, f)
			local flat = Vector3.new(at.X - rim.X, 0, at.Z - rim.Z).Magnitude
			if flat < hoop.Radius - r * 0.3 then
				s.Scored = true
				table.insert(events, { Kind = "Basket", Side = side })
			end
		end
		-- Aro: el punto más cercano del círculo
		local v = s.P - rim
		local flat = Vector3.new(v.X, 0, v.Z)
		if flat.Magnitude < hoop.Radius + r + 0.5 and math.abs(v.Y) < r + 0.5 then
			local dir = if flat.Magnitude > 1e-4 then flat.Unit else Vector3.new(1, 0, 0)
			local q = rim + dir * hoop.Radius
			local speed = s.V.Magnitude
			if bounceOff(s, q, r + C.RimTube, C.RimRestitution, Vector3.new(0, 1, 0)) then
				table.insert(events, { Kind = "Rim", Side = side, Speed = speed })
			end
		end
		-- Tablero: un rectángulo vertical de cara a la pista
		local n = hoop.Normal
		local t = Vector3.new(-n.Z, 0, n.X)
		local d = s.P - hoop.Board
		local q = hoop.Board + t * math.clamp(d:Dot(t), -hoop.BoardHalf.X, hoop.BoardHalf.X) + Vector3.new(0, math.clamp(d.Y, -hoop.BoardHalf.Y, hoop.BoardHalf.Y), 0)
		local speed = s.V.Magnitude
		if bounceOff(s, q, r + 0.15, C.BoardRestitution, n) then
			table.insert(events, { Kind = "Board", Side = side, Speed = speed })
		end
	end
	-- Cuerpos (tapones y rebotes en la gente)
	if bodies then
		for _, body in bodies do
			if s.Ignore == body.Id and s.T < s.IgnoreUntil then
				continue
			end
			local q = segment(body.A, body.B, s.P)
			local speed = s.V.Magnitude
			if bounceOff(s, q, r + body.R, C.BodyRestitution, Vector3.new(0, 1, 0)) then
				table.insert(events, { Kind = "Block", Id = body.Id, Speed = speed })
			end
		end
	end
	-- Paredes invisibles del recinto
	local bx, bz = court.BoardX - r, court.BoardZ - r
	if math.abs(s.P.X) > bx then
		s.P = Vector3.new(math.sign(s.P.X) * bx, s.P.Y, s.P.Z)
		s.V = Vector3.new(-s.V.X * C.WallRestitution, s.V.Y, s.V.Z)
		table.insert(events, { Kind = "Wall" })
	end
	if math.abs(s.P.Z) > bz then
		s.P = Vector3.new(s.P.X, s.P.Y, math.sign(s.P.Z) * bz)
		s.V = Vector3.new(s.V.X, s.V.Y, -s.V.Z * C.WallRestitution)
		table.insert(events, { Kind = "Wall" })
	end
	if s.P.Y > 50 then
		s.P = Vector3.new(s.P.X, 50, s.P.Z)
		s.V = Vector3.new(s.V.X, math.min(0, s.V.Y), s.V.Z)
	end
	s.T += h
end

function Hoops.step(s: State, dt: number, court: Court.Court, bodies: { any }?): { any }
	local events = {}
	if dt <= 0 then
		return events
	end
	local n = math.max(1, math.ceil(dt / C.SubStep - 1e-6))
	for _ = 1, n do
		subStep(s, dt / n, court, bodies, events)
	end
	local p, v = s.P, s.V
	if p.X ~= p.X or p.Y ~= p.Y or p.Z ~= p.Z or v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then
		Hoops.place(s, Vector3.zero)
	end
	return events
end

function Hoops.resting(s: State): boolean
	return s.P.Y <= C.Radius + 0.05 and s.V.Magnitude < 1.5
end

---------------------------------------------------------------------
-- Tiros
---------------------------------------------------------------------

-- La velocidad de un tiro limpio de `from` al centro del aro, con el punto más alto `arc` por encima
-- del aro (o de la mano, si está más alta). Devuelve V.
function Hoops.shotVelocity(from: Vector3, rim: Vector3, arc: number?): Vector3
	local g = C.Gravity
	local apex = math.max(from.Y, rim.Y) + (arc or 4)
	local up = math.sqrt(2 * g * math.max(apex - from.Y, 0.05))
	local tUp = up / g
	local tDown = math.sqrt(2 * math.max(apex - rim.Y, 0.05) / g)
	local flat = Vector3.new(rim.X - from.X, 0, rim.Z - from.Z)
	local total = tUp + tDown
	local horizontal = flat / total
	return horizontal + Vector3.new(0, up, 0)
end

-- Arco según la distancia (de cerca, más bombeado; de lejos, algo más tenso)
function Hoops.arcFor(distance: number): number
	return math.clamp(2.2 + distance * 0.18, 2.5, 6.5)
end

-- El tiro con error: quality 0..1 (1 = lanzamiento perfecto), distancia al aro, contest 0..1 (un
-- defensor encima). El error cambia la fuerza (corto/largo) y la dirección (izquierda/derecha).
function Hoops.shotError(v: Vector3, quality: number, distance: number, contest: number, rng: any): Vector3
	local q = math.clamp(quality, 0, 1)
	local spread = (1 - q) * 0.17 + distance * 0.0008 + contest * 0.06
	local long = (rng:NextNumber() * 2 - 1) * spread
	local side = (rng:NextNumber() * 2 - 1) * spread * 0.55
	local flat = Vector3.new(v.X, 0, v.Z)
	local right = if flat.Magnitude > 1e-3 then Vector3.new(-flat.Z, 0, flat.X).Unit else Vector3.new(1, 0, 0)
	return Vector3.new(v.X, 0, v.Z) * (1 + long) + right * flat.Magnitude * side + Vector3.new(0, v.Y * (1 + long * 0.5), 0)
end

-- El balón botando al conducir: a un lado, delante, y sube y baja de la mano al suelo
function Hoops.dribblePosition(feet: Vector3, facing: Vector3, phase: number, scale: number?): Vector3
	local s = scale or 1
	local f = Vector3.new(facing.X, 0, facing.Z)
	f = if f.Magnitude > 1e-3 then f.Unit else Vector3.new(1, 0, 0)
	local right = Vector3.new(-f.Z, 0, f.X)
	local hand = 3 * s
	local bounce = math.abs(math.sin(phase))
	local y = C.Radius + (hand - C.Radius) * bounce
	local p = feet + f * 1.1 * s + right * 0.9 * s
	return Vector3.new(p.X, y, p.Z)
end

-- Cuándo y dónde baja el balón por debajo de `height` (para los rebotes)
function Hoops.landing(s: State, court: Court.Court, height: number, maxT: number?): (number?, Vector3?)
	local copy = Hoops.copy(s)
	copy.Scored = true
	local t = 0
	local limit = maxT or 2.5
	while t < limit do
		local before = copy.P
		subStep(copy, 1 / 60, court, nil, {})
		t += 1 / 60
		if before.Y >= height and copy.P.Y < height and copy.V.Y < 0 then
			return t, copy.P
		end
	end
	return nil, nil
end

return Hoops
