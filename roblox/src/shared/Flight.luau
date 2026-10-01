-- Flight: cómo vuela un avión pilotado por un jugador (modelo de vuelo arcade, pero creíble).
--
-- Lo usan Controllers/Flying (el ordenador del piloto mueve el avión con esto cada fotograma),
-- Services/AviationService (comprueba que lo que llega tiene sentido) y scripts/test-flight.luau.
-- Son cuentas puras (sin tocar Roblox salvo Vector3/CFrame): el suelo y los choques se los da quien
-- llama (env.ground y env.hit), así se prueban fuera de Roblox.
--
--   * En tierra: rueda con el motor, se frena (B) y se gira con la rueda de morro (A/D o Q/E). Por
--     debajo de Vr el morro no sube; pasada Vr, tirando (S) el morro sube y despega.
--   * En el aire: alabeo (A/D), cabeceo (W/S: W baja el morro, S lo sube, como la palanca de un avión)
--     y timón (Q/E). Al inclinarse, gira solo (viraje coordinado). Sin tocar nada, las alas vuelven
--     poco a poco a nivel.
--   * La sustentación crece con la velocidad al cuadrado: por debajo de la velocidad de pérdida
--     (Vstall, menor con flaps) el avión se cae, el morro baja solo y salta el aviso de PÉRDIDA.
--     Subiendo se pierde velocidad y bajando se gana (la gravedad a lo largo de la trayectoria).
--   * Tren y flaps frenan (más resistencia). Con flaps, la pérdida llega más tarde (vuela más lento).
--   * Aterrizar: con el tren bajado, las alas casi a nivel, el morro sin clavar y cayendo despacio.
--     Suave (≤ SoftSink) bien; duro (≤ HardSink) daña el avión; más fuerte, sin tren, en el agua o
--     con un ala: accidente.
--   * Chocar con un edificio o el terreno en vuelo es accidente. Rodando despacio solo se para.
--   * Límites del mapa: cerca del borde el avión gira solo hacia dentro; arriba hay techo de vuelo.
--
-- Unidades: studs y segundos. Como en el velocímetro de los coches, 1 stud/s ≈ 1 km/h (1 stud ≈ 28 cm).

local Flight = {}

Flight.G = 32 -- gravedad del vuelo (studs/s²): la del juego (196) es para saltar, no para volar
Flight.METERS = 0.28 -- metros por stud (para la altitud del panel)
Flight.KNOTS = 1 / 1.852 -- nudos por km/h

-- Pose: el punto bajo las ruedas y la actitud, como Shared/Airport.pose (el morro mira a -Z).
--   Yaw: rumbo (0 = morro a -Z, sube girando a la izquierda) · Pitch: + morro arriba · Roll: + ala
--   derecha arriba (alabeo a la izquierda)
export type Spec = {
	Name: string,
	Vr: number, -- velocidad de rotación (despegue)
	Vstall: number, -- velocidad de pérdida sin flaps
	Vmax: number, -- velocidad máxima en llano a todo gas (sin tren ni flaps)
	Accel: number, -- empuje a todo gas (studs/s²)
	Brake: number, -- frenos en tierra (studs/s²)
	Rolling: number, -- rozamiento de las ruedas
	PitchRate: number,
	RollRate: number,
	YawRate: number,
	TaxiTurn: number, -- giro con la rueda de morro (rad/s, despacio)
	StallDrop: number, -- lo rápido que baja el morro en pérdida (rad/s)
	MaxBank: number,
	MaxPitch: number,
	MinPitch: number,
	RotateMax: number, -- morro arriba máximo en tierra (al despegar)
	SoftSink: number, -- caída máxima de un aterrizaje suave (studs/s)
	HardSink: number, -- y de uno duro (más: accidente)
	BumpSpeed: number, -- rodando más despacio que esto, tocar algo solo para el avión
	GearDrag: number,
	FlapDrag: number, -- por cada punto de flaps
	FlapLift: number, -- cuánto baja la pérdida cada punto de flaps (fracción)
	Flaps: number, -- puntos de flaps (0..Flaps)
	FixedGear: boolean, -- tren fijo (avioneta): no se sube
	BellyClear: number, -- con el tren subido, cuánto baja la panza respecto a las ruedas
	Box: Vector3, -- caja del cuerpo para los choques (ancho, alto, largo)
	BoxY: number, -- altura del centro de la caja sobre las ruedas
	Span: number,
}

local rad = math.rad

Flight.Specs = {
	-- Avioneta de ala alta (tipo Cessna): despega en menos de 120 studs y aterriza en la pista corta
	-- de la Isla de las Gaviotas
	Avioneta = {
		Name = "Avioneta",
		Vr = 52,
		Vstall = 44,
		Vmax = 155,
		Accel = 15,
		Brake = 20,
		Rolling = 0.8,
		PitchRate = rad(48),
		RollRate = rad(100),
		YawRate = rad(24),
		TaxiTurn = rad(60),
		StallDrop = rad(32),
		MaxBank = rad(70),
		MaxPitch = rad(35),
		MinPitch = rad(-40),
		RotateMax = rad(12),
		SoftSink = 10,
		HardSink = 19,
		BumpSpeed = 16,
		GearDrag = 0.06,
		FlapDrag = 0.12,
		FlapLift = 0.1,
		Flaps = 2,
		FixedGear = true,
		BellyClear = 0,
		Box = Vector3.new(4.4, 4.2, 20),
		BoxY = 5.2,
		Span = 34,
	} :: Spec,
	-- Avión de línea (bimotor de pasillo único): necesita la pista larga de Valmar
	Avion = {
		Name = "Avión de línea",
		Vr = 92,
		Vstall = 78,
		Vmax = 275,
		Accel = 10.5,
		Brake = 15,
		Rolling = 0.9,
		PitchRate = rad(26),
		RollRate = rad(55),
		YawRate = rad(12),
		TaxiTurn = rad(34),
		StallDrop = rad(20),
		MaxBank = rad(60),
		MaxPitch = rad(28),
		MinPitch = rad(-30),
		RotateMax = rad(11),
		SoftSink = 9,
		HardSink = 17,
		BumpSpeed = 12,
		GearDrag = 0.14,
		FlapDrag = 0.09,
		FlapLift = 0.09,
		Flaps = 2,
		FixedGear = false,
		BellyClear = 3.2,
		Box = Vector3.new(8.2, 8, 66),
		BoxY = 8.6,
		Span = 66,
	} :: Spec,
}

-- Límites del cielo: más allá del borde del mapa el avión gira solo hacia dentro; techo de vuelo
Flight.Bounds = { X0 = -5600, X1 = 5600, Z0 = -5000, Z1 = 4900, Ceiling = 1400, Margin = 500 }

export type State = {
	Kind: string,
	Pos: Vector3, -- punto bajo las ruedas
	Yaw: number,
	Pitch: number,
	Roll: number,
	Speed: number, -- hacia el morro (studs/s)
	Sink: number, -- caída extra (pérdida, virajes) (studs/s, + hacia abajo)
	Throttle: number, -- 0..1
	Gear: boolean, -- tren bajado
	Flaps: number,
	OnGround: boolean,
	Stalled: boolean,
	Health: number, -- 0..100 (los aterrizajes duros lo bajan)
	Crashed: string?, -- por qué se ha estrellado
	Warn: string?, -- "Perdida" | "Limite" | "Techo" (el panel lo enseña)
	Event: string?, -- lo que ha pasado en este paso: "Despegue" | "Suave" | "Duro" | "Choque" | "Accidente"
	Sunk: number?, -- (con Event de aterrizaje) a qué velocidad caía al tocar el suelo
	Bumped: string?, -- (con Event "Choque") con qué ha tocado rodando
	Climb: number, -- velocidad vertical (studs/s, + subiendo)
	Airborne: number, -- segundos en el aire (0 en tierra)
}

export type Input = {
	Pitch: number, -- -1..1 (+ morro arriba)
	Roll: number, -- -1..1 (+ a la derecha)
	Yaw: number, -- -1..1 (+ a la derecha)
	Throttle: number, -- -1..1 (+ más gas): cuánto se mueve la palanca de gas
	Brake: boolean,
}

-- Lo que el piloto ve debajo: altura del suelo y tipo ("Pista", "Suelo", "Agua") o nil si no hay nada
export type Env = {
	ground: (Vector3) -> (number?, string?),
	hit: ((CFrame, Vector3) -> string?)?, -- ¿choca la caja del cuerpo al moverse? (nombre de lo tocado)
}

Flight.NoInput = table.freeze({ Pitch = 0, Roll = 0, Yaw = 0, Throttle = 0, Brake = false }) :: Input

function Flight.new(kind: string, pose: CFrame): State
	local look = pose.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	return {
		Kind = kind,
		Pos = pose.Position,
		Yaw = yaw,
		Pitch = 0,
		Roll = 0,
		Speed = 0,
		Sink = 0,
		Throttle = 0,
		Gear = true,
		Flaps = 0,
		OnGround = true,
		Stalled = false,
		Health = 100,
		Crashed = nil,
		Warn = nil,
		Event = nil,
		Climb = 0,
		Airborne = 0,
	}
end

-- Actitud y posición como CFrame (el mismo que Airport.pose: el punto bajo las ruedas)
function Flight.cframe(s: State): CFrame
	return CFrame.new(s.Pos) * CFrame.Angles(0, s.Yaw, 0) * CFrame.Angles(s.Pitch, 0, 0) * CFrame.Angles(0, 0, s.Roll)
end

function Flight.look(s: State): Vector3
	local cp = math.cos(s.Pitch)
	return Vector3.new(-math.sin(s.Yaw) * cp, math.sin(s.Pitch), -math.cos(s.Yaw) * cp)
end

-- Velocidad (vector) en este momento (rodando, siempre en horizontal: el suelo la lleva)
function Flight.velocity(s: State): Vector3
	if s.OnGround then
		return Vector3.new(-math.sin(s.Yaw), 0, -math.cos(s.Yaw)) * s.Speed
	end
	return Flight.look(s) * s.Speed - Vector3.new(0, s.Sink, 0)
end

-- Velocidad de pérdida con estos flaps
function Flight.stallSpeed(spec: Spec, flaps: number): number
	return spec.Vstall * (1 - spec.FlapLift * math.clamp(flaps, 0, spec.Flaps))
end

-- Sustentación (1 = sostiene el avión): crece con la velocidad al cuadrado
function Flight.lift(spec: Spec, speed: number, flaps: number): number
	local vs = Flight.stallSpeed(spec, flaps)
	return (math.max(speed, 0) / vs) ^ 2
end

-- Resistencia al avance (studs/s²): con la velocidad al cuadrado, más con el tren y los flaps
function Flight.drag(spec: Spec, speed: number, gear: boolean, flaps: number): number
	local k = 1 + (if gear then spec.GearDrag else 0) + spec.FlapDrag * math.clamp(flaps, 0, spec.Flaps)
	return spec.Accel * (speed / spec.Vmax) ^ 2 * k
end

-- ¿Qué tal ha sido la toma? "Suave" | "Duro" | "Accidente" y por qué
function Flight.landing(spec: Spec, sink: number, pitch: number, roll: number, gear: boolean, surface: string?): (string, string?)
	if surface == "Agua" then
		return "Accidente", "Has caído al agua"
	elseif not gear then
		return "Accidente", "Has aterrizado sin el tren"
	elseif math.abs(roll) > rad(16) then
		return "Accidente", "Has tocado el suelo con un ala"
	elseif pitch < rad(-10) then
		return "Accidente", "Has entrado de morro"
	elseif sink <= spec.SoftSink then
		return "Suave", nil
	elseif sink <= spec.HardSink then
		return "Duro", "Aterrizaje duro"
	end
	return "Accidente", "Has caído demasiado rápido"
end

-- Daño de un aterrizaje duro (más cuanto más fuerte)
function Flight.hardDamage(spec: Spec, sink: number): number
	local t = math.clamp((sink - spec.SoftSink) / math.max(spec.HardSink - spec.SoftSink, 1), 0, 1)
	return math.floor(15 + 35 * t + 0.5)
end

local function approach(value: number, target: number, step: number): number
	if value < target then
		return math.min(value + step, target)
	end
	return math.max(value - step, target)
end

local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

local function crash(s: State, reason: string)
	s.Crashed = reason
	s.Event = "Accidente"
	s.Speed = 0
	s.Sink = 0
	s.Throttle = 0
end

-- Cerca del borde del mapa: hacia dónde girar (rumbo hacia el centro) y cuánto (0..1)
function Flight.boundsPull(pos: Vector3): (number?, number)
	local B = Flight.Bounds
	local inside = math.min(pos.X - B.X0, B.X1 - pos.X, pos.Z - B.Z0, B.Z1 - pos.Z)
	if inside >= B.Margin then
		return nil, 0
	end
	local cx, cz = (B.X0 + B.X1) / 2, (B.Z0 + B.Z1) / 2
	local d = Vector3.new(cx - pos.X, 0, cz - pos.Z)
	return math.atan2(-d.X, -d.Z), math.clamp(1 - inside / B.Margin, 0, 1)
end

-- Un paso de dt segundos. Cambia el estado y lo devuelve. (Se trocea en pasos de 1/60 s como mucho.)
function Flight.step(s: State, input: Input, dt: number, env: Env): State
	s.Event, s.Bumped, s.Sunk = nil, nil, nil
	if s.Crashed then
		return s
	end
	local spec = Flight.Specs[s.Kind]
	local G = Flight.G
	-- Gas, flaps y tren
	s.Throttle = math.clamp(s.Throttle + math.clamp(input.Throttle, -1, 1) * 0.55 * dt, 0, 1)
	if spec.FixedGear then
		s.Gear = true
	end
	s.Flaps = math.clamp(math.floor(s.Flaps + 0.5), 0, spec.Flaps)
	local vs = Flight.stallSpeed(spec, s.Flaps)
	local speed = s.Speed
	local lift = Flight.lift(spec, speed, s.Flaps)
	local authority = math.clamp(speed / vs, 0.15, 1)
	local pitchIn = math.clamp(input.Pitch, -1, 1)
	local rollIn = math.clamp(input.Roll, -1, 1)
	local yawIn = math.clamp(input.Yaw, -1, 1)
	s.Warn = nil

	if s.OnGround then
		s.Airborne = 0
		s.Stalled = false
		-- Rueda de morro: gira más cerrado despacio, menos deprisa (y nada parado)
		local steer = math.clamp(yawIn + rollIn, -1, 1)
		local turn = spec.TaxiTurn * math.clamp(speed / 5, 0, 1) / (1 + speed / 45)
		s.Yaw = wrap(s.Yaw - steer * turn * dt)
		-- Rotación: el morro solo sube pasada Vr (casi) y tirando de la palanca
		local target = 0
		if speed >= spec.Vr * 0.92 and pitchIn > 0.05 then
			target = spec.RotateMax * pitchIn
		end
		s.Pitch = approach(s.Pitch, target, rad(9) * dt)
		s.Roll = approach(s.Roll, 0, rad(30) * dt)
		s.Sink = 0
		-- Despega: morro arriba y bastante velocidad para sostenerse
		if s.Pitch > rad(4) and speed >= spec.Vr and lift >= 1 then
			s.OnGround = false
			s.Event = "Despegue"
		end
	else
		s.Airborne += dt
		-- Pérdida (con margen para salir de ella: no parpadea)
		if s.Stalled then
			s.Stalled = speed < vs * 1.06
		else
			s.Stalled = speed < vs
		end
		local pitchRate = pitchIn * spec.PitchRate * authority
		if s.Stalled then
			-- El morro baja solo: hay que dejar que gane velocidad
			pitchRate = -spec.StallDrop + math.min(pitchIn, 0) * spec.PitchRate * 0.5
			s.Warn = "Perdida"
		end
		-- Con las alas muy inclinadas cuesta subir el morro
		s.Pitch = math.clamp(s.Pitch + pitchRate * dt, spec.MinPitch, spec.MaxPitch)
		if math.abs(rollIn) > 0.05 then
			s.Roll = s.Roll - rollIn * spec.RollRate * authority * dt
		else
			s.Roll = s.Roll - s.Roll * math.min(1, 0.9 * dt) -- vuelve solo a nivel
		end
		s.Roll = math.clamp(s.Roll, -spec.MaxBank, spec.MaxBank)
		-- Viraje coordinado (al inclinarse gira) más el timón
		local yawRate = G * math.tan(s.Roll) / math.max(speed, 25) - yawIn * spec.YawRate * authority
		-- Borde del mapa: gira solo hacia dentro
		local home, pull = Flight.boundsPull(s.Pos)
		if home and pull > 0 then
			local diff = wrap(home - s.Yaw)
			if math.abs(diff) > rad(5) then
				yawRate += math.sign(diff) * spec.YawRate * 3 * pull
				s.Roll = approach(s.Roll, math.sign(diff) * rad(25) * pull, spec.RollRate * 0.5 * dt)
			end
			s.Warn = s.Warn or "Limite"
		end
		s.Yaw = wrap(s.Yaw + yawRate * dt)
		-- Techo de vuelo: el morro no sube más
		local ceiling = Flight.Bounds.Ceiling
		if s.Pos.Y > ceiling - 120 then
			local room = math.clamp((ceiling - s.Pos.Y) / 120, 0, 1)
			s.Pitch = math.min(s.Pitch, spec.MaxPitch * room)
			s.Warn = s.Warn or "Techo"
		end
	end

	-- Velocidad: empuje - resistencia - la gravedad a lo largo de la trayectoria (- frenos en tierra)
	local vel = Flight.velocity(s)
	local sinPath = if vel.Magnitude > 0.5 then vel.Unit.Y else 0
	local accel = s.Throttle * spec.Accel - Flight.drag(spec, speed, s.Gear, s.Flaps) - G * 0.5 * sinPath
	if s.OnGround then
		accel -= spec.Rolling + (if input.Brake then spec.Brake else 0)
	end
	speed = math.max(0, speed + accel * dt)
	if s.OnGround and speed < 0.05 and s.Throttle < 0.02 then
		speed = 0
	end
	s.Speed = speed

	-- En el aire: lo que no sostienen las alas, cae (pérdida o mucha inclinación)
	if not s.OnGround then
		local support = math.min(Flight.lift(spec, speed, s.Flaps), 1) * math.cos(s.Roll)
		local deficit = math.max(0, 1 - support)
		s.Sink = math.max(0, s.Sink + (G * deficit - s.Sink * 1.2 * math.min(lift, 1)) * dt)
	end

	-- Moverse
	local before = Flight.cframe(s)
	vel = Flight.velocity(s)
	local move = vel * dt
	local pos = s.Pos + move
	-- Límites: nunca fuera del mapa ni por encima del techo
	local B = Flight.Bounds
	pos = Vector3.new(math.clamp(pos.X, B.X0 - 200, B.X1 + 200), math.min(pos.Y, B.Ceiling), math.clamp(pos.Z, B.Z0 - 200, B.Z1 + 200))
	s.Climb = (pos.Y - s.Pos.Y) / math.max(dt, 1e-3)

	-- Choques del cuerpo (edificios, terreno, farolas…): rodando despacio solo se para
	if env.hit and move.Magnitude > 1e-4 then
		local name = env.hit(before, pos - s.Pos)
		if name then
			if s.OnGround and speed <= spec.BumpSpeed then
				s.Speed = 0
				s.Event = "Choque"
				s.Bumped = name
				return s
			end
			s.Pos = pos
			crash(s, "Te has estrellado contra " .. name)
			return s
		end
	end

	-- Suelo
	local gy, surface = env.ground(pos)
	if s.OnGround then
		if gy == nil or gy < pos.Y - 1.5 then
			-- Se acaba el suelo (un borde, el muelle…): sin velocidad para volar, se cae
			s.OnGround = false
		else
			if surface == "Agua" then
				s.Pos = Vector3.new(pos.X, gy, pos.Z)
				crash(s, "Has caído al agua")
				return s
			end
			pos = Vector3.new(pos.X, gy, pos.Z)
		end
	elseif gy ~= nil then
		local clear = if s.Gear then 0 else spec.BellyClear
		if pos.Y - clear <= gy then
			local sink = math.max(0, -vel.Y)
			local result, why = Flight.landing(spec, sink, s.Pitch, s.Roll, s.Gear, surface)
			s.Pos = Vector3.new(pos.X, gy + clear, pos.Z)
			if result == "Accidente" then
				crash(s, why or "Accidente")
				return s
			end
			s.OnGround = true
			s.Sink = 0
			s.Roll = 0
			s.Stalled = false
			s.Airborne = 0
			s.Event = result
			s.Sunk = sink
			if result == "Duro" then
				s.Health -= Flight.hardDamage(spec, sink)
				if s.Health <= 0 then
					s.Health = 0
					crash(s, "El avión no ha aguantado el aterrizaje")
					return s
				end
			end
			pos = Vector3.new(pos.X, gy, pos.Z)
		end
	end
	s.Pos = pos
	return s
end

-- Varios pasos pequeños (así da igual que el fotograma sea largo)
function Flight.advance(s: State, input: Input, dt: number, env: Env): { string }
	local events = {}
	local left = math.min(dt, 0.25)
	while left > 1e-6 and not s.Crashed do
		local h = math.min(left, 1 / 60)
		Flight.step(s, input, h, env)
		if s.Event then
			table.insert(events, s.Event)
		end
		left -= h
	end
	return events
end

-- Rumbo en grados (0 = norte, -Z; 90 = este, +X) para el panel
function Flight.heading(s: State): number
	return math.floor((-math.deg(s.Yaw)) % 360 + 0.5) % 360
end

-- Puntos cardinales para el panel
function Flight.compass(deg: number): string
	local names = { "N", "NE", "E", "SE", "S", "SO", "O", "NO" }
	return names[math.floor(((deg % 360) + 22.5) / 45) % 8 + 1]
end

return Flight
