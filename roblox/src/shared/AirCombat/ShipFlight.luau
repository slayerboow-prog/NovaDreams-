-- ShipFlight: cómo vuela una nave de combate pequeña (modelo de vuelo ARCADE, para el combate aéreo y
-- espacial: Saga 2, docs/combate-aereo.md).
--
-- Son cuentas puras (solo Vector3/CFrame): no toca el mundo. El suelo y los choques se los da quien
-- llama (env.collide), así se prueban fuera de Roblox (scripts/test-aircombat.luau) y valen igual en el
-- cliente (predicción, cada fotograma) y en el servidor (comprobar que lo que llega tiene sentido).
--
--   * Motor (Throttle 0..1) entre la velocidad mínima y la máxima; nunca se para del todo (es una nave).
--   * Cabeceo, guiñada y alabeo. Sin tocar el alabeo, la nave se nivela sola (asistencia) y se inclina
--     sola hacia donde giras (viraje coordinado, se lee bien en el móvil). Inclinada, también gira.
--   * TURBO con energía: mientras lo mantienes, más velocidad y gira algo peor; si la gastas entera,
--     tiene que enfriarse (BoostCooldown) antes de volver a usarlo. Se recarga sola.
--   * FRENO: frena y gira mucho más cerrado (viraje cerrado para meterse detrás de un enemigo).
--   * Dos modos: "Atmos" (gravedad: subir cuesta velocidad, bajar la da; muy despacio se hunde; hay
--     suelo) y "Space" (sin gravedad ni suelo; solo asteroides). env.mode(pos) dice cuál toca.
--   * Chocar (suelo, roca, asteroide): el evento "Crash" y quien llama hace «la nave estalla →
--     reaparecer en el punto de control».
--   * Fuera de los límites (env.bounds) la nave gira sola hacia dentro.
--
-- Orientación: Rot es un CFrame sin posición. LookVector (-Z) es el morro. Pitch + = morro arriba,
-- Yaw + = a la derecha, Roll + = ala derecha abajo (alabeo a la derecha).

local ShipFlight = {}

export type Spec = {
	Name: string,
	MinSpeed: number, -- studs/s con el motor al mínimo
	MaxSpeed: number, -- a todo motor
	BoostSpeed: number, -- con turbo
	BrakeSpeed: number, -- frenando
	Accel: number, -- studs/s² para ganar velocidad
	Decel: number, -- y para perderla
	PitchRate: number, -- rad/s con la palanca a tope
	YawRate: number,
	RollRate: number,
	BrakeTurn: number, -- multiplica el giro frenando (viraje cerrado)
	BoostTurn: number, -- multiplica el giro con turbo (gira peor)
	BankTurn: number, -- rad/s de rumbo por cada radián de inclinación (atmósfera)
	MaxBank: number, -- inclinación que busca la asistencia al girar (rad)
	LevelRate: number, -- fuerza de la autonivelación
	BoostSeconds: number, -- cuánto dura la energía del turbo entera
	BoostRefill: number, -- segundos para recargarla de 0 a 1
	BoostCooldown: number, -- si se gasta entera, segundos sin turbo
	LiftSpeed: number, -- (atmósfera) por debajo de esto se hunde
	Gravity: number, -- (atmósfera) studs/s²
	Radius: number, -- radio de la nave para los choques
	ThrottleRate: number, -- cuánto sube o baja el motor por segundo con la tecla
}

ShipFlight.Specs = {
	Caza = {
		Name = "Caza ligero",
		MinSpeed = 45,
		MaxSpeed = 210,
		BoostSpeed = 340,
		BrakeSpeed = 60,
		Accel = 110,
		Decel = 150,
		PitchRate = 1.55,
		YawRate = 0.95,
		RollRate = 2.8,
		BrakeTurn = 1.6,
		BoostTurn = 0.7,
		BankTurn = 0.85,
		MaxBank = 0.85,
		LevelRate = 2.4,
		BoostSeconds = 2.6,
		BoostRefill = 3.5,
		BoostCooldown = 3,
		LiftSpeed = 85,
		Gravity = 40,
		Radius = 6,
		ThrottleRate = 0.7,
	} :: Spec,
}

export type Input = {
	Pitch: number, -- -1..1 (+ morro arriba)
	Yaw: number, -- -1..1 (+ derecha)
	Roll: number, -- -1..1 (+ alabeo a la derecha)
	Throttle: number?, -- -1..1: sube o baja el motor (teclas)
	SetThrottle: number?, -- 0..1: pone el motor (mando o móvil)
	Boost: boolean?,
	Brake: boolean?,
}

export type Env = {
	mode: ((pos: Vector3) -> string)?, -- "Atmos" | "Space"
	collide: ((pos: Vector3, radius: number) -> string?)?, -- nombre de lo que toca, o nil
	bounds: ((pos: Vector3) -> Vector3?)?, -- fuera de los límites: hacia dónde volver (unitario)
}

export type State = {
	Spec: Spec,
	Pos: Vector3,
	Rot: CFrame,
	Speed: number,
	Sink: number, -- velocidad vertical extra (atmósfera, al ir despacio)
	Throttle: number,
	Boost: number, -- energía del turbo 0..1
	CoolUntil: number, -- (Time) hasta cuándo no hay turbo
	Boosting: boolean,
	Braking: boolean,
	Mode: string,
	Time: number,
	Warn: string?, -- "Limite" | "Lento" | nil
	Crashed: string?,
}

local function clamp(x: number, a: number, b: number): number
	return if x < a then a elseif x > b then b else x
end

-- Orientación que mira hacia `look` con el techo hacia arriba (sin CFrame.lookAt: el de Lune da la vuelta)
function ShipFlight.facing(look: Vector3, up: Vector3?): CFrame
	local l = if look.Magnitude > 1e-6 then look.Unit else Vector3.new(0, 0, -1)
	local u = up or Vector3.new(0, 1, 0)
	local right = l:Cross(u)
	if right.Magnitude < 1e-4 then
		right = l:Cross(Vector3.new(0, 0, 1))
	end
	right = right.Unit
	local up2 = right:Cross(l).Unit
	return CFrame.fromMatrix(Vector3.zero, right, up2, -l)
end

function ShipFlight.new(kind: string, cf: CFrame, mode: string?): State
	local spec = ShipFlight.Specs[kind] or ShipFlight.Specs.Caza
	return {
		Spec = spec,
		Pos = cf.Position,
		Rot = cf - cf.Position,
		Speed = (spec.MinSpeed + spec.MaxSpeed) * 0.5,
		Sink = 0,
		Throttle = 0.6,
		Boost = 1,
		CoolUntil = 0,
		Boosting = false,
		Braking = false,
		Mode = mode or "Atmos",
		Time = 0,
		Warn = nil,
		Crashed = nil,
	}
end

function ShipFlight.cframe(s: State): CFrame
	return CFrame.new(s.Pos) * s.Rot
end

function ShipFlight.look(s: State): Vector3
	return s.Rot.LookVector
end

function ShipFlight.velocity(s: State): Vector3
	return s.Rot.LookVector * s.Speed + Vector3.new(0, s.Sink, 0)
end

-- Inclinación (rad): + con el ala derecha abajo
function ShipFlight.bank(s: State): number
	return math.asin(clamp(-s.Rot.RightVector.Y, -1, 1))
end

-- Velocidad a la que tiende la nave con ese motor, turbo y freno
function ShipFlight.targetSpeed(spec: Spec, throttle: number, boosting: boolean, braking: boolean): number
	if braking then
		return spec.BrakeSpeed
	elseif boosting then
		return spec.BoostSpeed
	end
	return spec.MinSpeed + (spec.MaxSpeed - spec.MinSpeed) * clamp(throttle, 0, 1)
end

-- ¿Se puede encender el turbo ahora?
function ShipFlight.canBoost(s: State): boolean
	return s.Time >= s.CoolUntil and s.Boost > 0.05
end

-- Avanza la nave dt segundos. Devuelve los eventos: "Crash", "BoostEmpty", "BoostReady", "Space", "Atmos".
function ShipFlight.advance(s: State, inp: Input, dt: number, env: Env?): { string }
	local events = {}
	if s.Crashed then
		return events
	end
	dt = clamp(dt, 0, 0.1)
	local spec = s.Spec
	s.Time += dt
	local e = env or {}
	-- Modo (atmósfera o espacio)
	if e.mode then
		local mode = e.mode(s.Pos)
		if mode ~= s.Mode then
			s.Mode = mode
			table.insert(events, mode)
		end
	end
	local atmos = s.Mode ~= "Space"
	-- Motor
	if inp.SetThrottle then
		s.Throttle = clamp(inp.SetThrottle, 0, 1)
	end
	if inp.Throttle and inp.Throttle ~= 0 then
		s.Throttle = clamp(s.Throttle + inp.Throttle * spec.ThrottleRate * dt, 0, 1)
	end
	-- Turbo: gasta energía mientras se mantiene; vacío -> a enfriar
	local wasCool = s.Time - dt < s.CoolUntil
	s.Braking = inp.Brake == true
	local wantBoost = inp.Boost == true and not s.Braking
	if wantBoost and (s.Boosting or ShipFlight.canBoost(s)) and s.Time >= s.CoolUntil then
		s.Boosting = true
		s.Boost = math.max(0, s.Boost - dt / spec.BoostSeconds)
		if s.Boost <= 0 then
			s.Boosting = false
			s.CoolUntil = s.Time + spec.BoostCooldown
			table.insert(events, "BoostEmpty")
		end
	else
		s.Boosting = false
		if s.Time >= s.CoolUntil then
			s.Boost = math.min(1, s.Boost + dt / spec.BoostRefill)
		end
	end
	if wasCool and s.Time >= s.CoolUntil and s.CoolUntil > 0 then
		table.insert(events, "BoostReady")
	end
	-- Giro: freno = viraje cerrado; turbo = gira peor
	local turn = if s.Braking then spec.BrakeTurn elseif s.Boosting then spec.BoostTurn else 1
	local pitch = clamp(inp.Pitch, -1, 1)
	local yaw = clamp(inp.Yaw, -1, 1)
	local roll = clamp(inp.Roll, -1, 1)
	local bank = ShipFlight.bank(s)
	if math.abs(roll) < 0.15 then
		-- Asistencia: se inclina sola hacia donde gira y, si no gira, vuelve a nivel
		local target = yaw * spec.MaxBank
		local gain = if atmos then spec.LevelRate else spec.LevelRate * 0.6
		roll = clamp((target - bank) * gain, -1, 1)
	end
	s.Rot = s.Rot * CFrame.Angles(pitch * spec.PitchRate * turn * dt, -yaw * spec.YawRate * turn * dt, -roll * spec.RollRate * dt)
	-- Inclinada, la nave gira (sobre la vertical del mundo): se nota sobre todo en la atmósfera
	local liftFactor = if atmos then clamp(s.Speed / spec.LiftSpeed, 0, 1) else 0.6
	local bankYaw = -math.sin(ShipFlight.bank(s)) * spec.BankTurn * liftFactor * turn * dt
	if bankYaw ~= 0 then
		s.Rot = CFrame.Angles(0, bankYaw, 0) * s.Rot
	end
	-- Límites: gira solo hacia dentro
	s.Warn = nil
	if e.bounds then
		local back = e.bounds(s.Pos)
		if back then
			s.Warn = "Limite"
			-- (gira hacia dentro a 1.2 rad/s; si mira justo hacia fuera, por un lado)
			local look = s.Rot.LookVector
			local angle = math.acos(clamp(look:Dot(back), -1, 1))
			if angle > 1e-3 then
				local axis = look:Cross(back)
				if axis.Magnitude < 1e-3 then
					axis = s.Rot.UpVector
				end
				local turnBy = math.min(angle, 1.2 * dt)
				local want = CFrame.fromAxisAngle(axis.Unit, turnBy):VectorToWorldSpace(look)
				s.Rot = ShipFlight.facing(want, s.Rot.UpVector)
			end
		end
	end
	-- Ortonormalizar de vez en cuando (los errores se acumulan)
	s.Rot = ShipFlight.facing(s.Rot.LookVector, s.Rot.UpVector)
	-- Velocidad (en la atmósfera, subiendo cuesta llegar a ella y en picado se pasa)
	local target = ShipFlight.targetSpeed(spec, s.Throttle, s.Boosting, s.Braking)
	if atmos then
		target -= spec.Gravity * s.Rot.LookVector.Y * 1.1
	end
	local accel = if s.Boosting then spec.Accel * 2 else spec.Accel
	local diff = target - s.Speed
	s.Speed += if diff > 0 then math.min(diff, accel * dt) else math.max(diff, -spec.Decel * dt)
	local look = s.Rot.LookVector
	if atmos then
		-- Despacio, la nave se hunde
		local lift = clamp(s.Speed / spec.LiftSpeed, 0, 1)
		local sinkTarget = -spec.Gravity * (1 - lift) * 1.5
		s.Sink += (sinkTarget - s.Sink) * math.min(1, 2 * dt)
		if lift < 0.75 then
			s.Warn = s.Warn or "Lento"
		end
	else
		s.Sink += (0 - s.Sink) * math.min(1, 3 * dt)
	end
	s.Speed = clamp(s.Speed, spec.BrakeSpeed * 0.5, spec.BoostSpeed * 1.1)
	-- Mover y mirar choques
	local vel = look * s.Speed + Vector3.new(0, s.Sink, 0)
	s.Pos += vel * dt
	if e.collide then
		local hit = e.collide(s.Pos, spec.Radius)
		if hit then
			s.Crashed = hit
			s.Speed = 0
			s.Sink = 0
			table.insert(events, "Crash")
		end
	end
	return events
end

-- (servidor) ¿Es posible ir de `from` a `to` en `dt` segundos con esta nave? (con margen por la red)
function ShipFlight.plausible(spec: Spec, from: Vector3, to: Vector3, dt: number): boolean
	local limit = (spec.BoostSpeed * 1.1 + spec.Gravity) * 1.3 * math.max(dt, 0) + 25
	return (to - from).Magnitude <= limit
end

-- Velocidad para el panel (como el resto del juego: 1 stud/s ≈ 1 km/h)
function ShipFlight.kmh(s: State): number
	return math.floor(s.Speed + 0.5)
end

return ShipFlight
