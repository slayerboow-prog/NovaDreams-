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
--   * (Espacio AAA, docs/espacio-aaa/diseno.md) LATERAL (Strafe) y VERTICAL (Lift) con propulsores,
--     FRENO DE EMERGENCIA (EBrake: en el espacio se queda quieta), modos "Combat" (gira mejor) y "Cruise"
--     (más velocidad, gira peor), ASISTENCIA de vuelo (apagada: inercia controlada, la nave derrapa al
--     girar), ESQUIVA (ShipFlight.dodge: un empujón lateral real que se apaga solo), choques BARRIDOS
--     (se mira el segmento entero: a mucha velocidad tampoco se atraviesa nada), choques SUAVES (despacio:
--     rebota, "Bump", y unos instantes la asistencia la endereza) y Override (lo usa la hipervelocidad:
--     shared/AirCombat/Hyperspeed pone la velocidad, la aceleración y cuánto gira).
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
	StrafeSpeed: number, -- (propulsores) studs/s de lado
	VertSpeed: number, -- y hacia arriba/abajo
	DriftRate: number, -- con la asistencia: lo rápido que la deriva va a lo que pides (o se frena)
	DriftFree: number, -- sin asistencia: lo despacio que se pierde la inercia
	EBrakeDecel: number, -- freno de emergencia (studs/s²)
	CrashSpeed: number, -- por encima, chocar es estallar; por debajo, rebotar
	Bounce: number, -- studs/s del rebote
	RecoverSeconds: number, -- tras un rebote o una esquiva, la asistencia endereza la nave
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
		StrafeSpeed = 70,
		VertSpeed = 55,
		DriftRate = 4,
		DriftFree = 0.35,
		EBrakeDecel = 380,
		CrashSpeed = 110,
		Bounce = 30,
		RecoverSeconds = 1.1,
	} :: Spec,
}

-- Modos de vuelo: velocidad máxima (Speed), giro (Turn) y propulsores laterales (Strafe)
ShipFlight.Modes = {
	Combat = { Speed = 1, Turn = 1, Strafe = 1, Name = "COMBATE" },
	Cruise = { Speed = 1.45, Turn = 0.7, Strafe = 0.5, Name = "CRUCERO" },
}

export type Input = {
	Pitch: number, -- -1..1 (+ morro arriba)
	Yaw: number, -- -1..1 (+ derecha)
	Roll: number, -- -1..1 (+ alabeo a la derecha)
	Throttle: number?, -- -1..1: sube o baja el motor (teclas)
	SetThrottle: number?, -- 0..1: pone el motor (mando o móvil)
	Boost: boolean?,
	Brake: boolean?,
	Strafe: number?, -- -1..1 (+ derecha)
	Lift: number?, -- -1..1 (+ arriba)
	EBrake: boolean?, -- freno de emergencia
}

export type Env = {
	mode: ((pos: Vector3) -> string)?, -- "Atmos" | "Space"
	collide: ((pos: Vector3, radius: number) -> string?)?, -- nombre de lo que toca, o nil (se barre el segmento)
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
	Drift: Vector3, -- velocidad aparte del morro (lateral, vertical, inercia), mundo
	FlightMode: string, -- "Combat" | "Cruise"
	Assist: boolean, -- asistencia de vuelo
	EBraking: boolean,
	RecoverUntil: number, -- (Time) recuperándose de un rebote o una esquiva
	Bumped: string?, -- lo último contra lo que rebotó
	Dodge: { Vel: Vector3, Start: number, Dur: number }?,
	Override: { Speed: number, Accel: number, Decel: number, Turn: number }?, -- (hipervelocidad)
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
		Drift = Vector3.zero,
		FlightMode = "Combat",
		Assist = true,
		EBraking = false,
		RecoverUntil = 0,
		Bumped = nil,
		Dodge = nil,
		Override = nil,
	}
end

function ShipFlight.setMode(s: State, mode: string)
	if ShipFlight.Modes[mode] then
		s.FlightMode = mode
	end
end

function ShipFlight.setAssist(s: State, on: boolean)
	s.Assist = on
end

-- Velocidad de la esquiva en este instante (se apaga sola: recorre Vel·Dur en Dur segundos)
local function dodgeVel(s: State): Vector3
	local d = s.Dodge
	if not d then
		return Vector3.zero
	end
	local u = (s.Time - d.Start) / d.Dur
	if u >= 1 or u < 0 then
		return Vector3.zero
	end
	return d.Vel * (2 * (1 - u))
end

-- Esquiva: un empujón de `distance` studs hacia `dir` (mundo, unitario) en `duration` segundos
function ShipFlight.dodge(s: State, dir: Vector3, distance: number, duration: number)
	if dir.Magnitude < 1e-3 or duration <= 0 then
		return
	end
	s.Dodge = { Vel = dir.Unit * (distance / duration), Start = s.Time, Dur = duration }
	s.RecoverUntil = math.max(s.RecoverUntil, s.Time + duration + 0.25)
end

function ShipFlight.dodging(s: State): boolean
	local d = s.Dodge
	return d ~= nil and s.Time - d.Start < d.Dur
end

-- Dirección de la esquiva en el mundo: "L" | "R" | "U" | "D"
function ShipFlight.dodgeDir(s: State, side: string): Vector3
	local r, u = s.Rot.RightVector, s.Rot.UpVector
	if side == "L" then
		return -r
	elseif side == "U" then
		return u
	elseif side == "D" then
		return -u
	end
	return r
end

function ShipFlight.cframe(s: State): CFrame
	return CFrame.new(s.Pos) * s.Rot
end

function ShipFlight.look(s: State): Vector3
	return s.Rot.LookVector
end

function ShipFlight.velocity(s: State): Vector3
	return s.Rot.LookVector * s.Speed + Vector3.new(0, s.Sink, 0) + s.Drift + dodgeVel(s)
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

-- Avanza la nave dt segundos. Devuelve los eventos: "Crash", "Bump", "BoostEmpty", "BoostReady", "Space",
-- "Atmos".
function ShipFlight.advance(s: State, inp: Input, dt: number, env: Env?): { string }
	local events = {}
	if s.Crashed then
		return events
	end
	dt = clamp(dt, 0, 0.1)
	local spec = s.Spec
	s.Time += dt
	local e = env or {}
	local mk = ShipFlight.Modes[s.FlightMode] or ShipFlight.Modes.Combat
	local over = s.Override
	-- Modo (atmósfera o espacio)
	if e.mode then
		local mode = e.mode(s.Pos)
		if mode ~= s.Mode then
			s.Mode = mode
			table.insert(events, mode)
		end
	end
	local atmos = s.Mode ~= "Space"
	local recovering = s.Time < s.RecoverUntil
	-- Motor
	if inp.SetThrottle then
		s.Throttle = clamp(inp.SetThrottle, 0, 1)
	end
	if inp.Throttle and inp.Throttle ~= 0 then
		s.Throttle = clamp(s.Throttle + inp.Throttle * spec.ThrottleRate * dt, 0, 1)
	end
	-- Turbo: gasta energía mientras se mantiene; vacío -> a enfriar
	local wasCool = s.Time - dt < s.CoolUntil
	s.EBraking = inp.EBrake == true and over == nil
	s.Braking = (inp.Brake == true or s.EBraking) and over == nil
	local wantBoost = inp.Boost == true and not s.Braking and over == nil
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
	-- Giro: freno = viraje cerrado; turbo = gira peor; el modo y la hipervelocidad también cuentan
	local turn = if s.Braking then spec.BrakeTurn elseif s.Boosting then spec.BoostTurn else 1
	turn *= mk.Turn
	if over then
		turn *= over.Turn
	end
	local control = if recovering then 0.5 else 1
	local pitch = clamp(inp.Pitch, -1, 1) * control
	local yaw = clamp(inp.Yaw, -1, 1) * control
	local roll = clamp(inp.Roll, -1, 1) * control
	local bank = ShipFlight.bank(s)
	if math.abs(roll) < 0.15 or recovering then
		-- Asistencia: se inclina sola hacia donde gira y, si no gira, vuelve a nivel
		local target = yaw * spec.MaxBank
		local gain = if atmos then spec.LevelRate else spec.LevelRate * 0.6
		if recovering then
			gain = spec.LevelRate * 1.5
		end
		roll = clamp((target - bank) * gain, -1, 1)
	end
	local oldLook = s.Rot.LookVector
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
	local target: number
	local accel = if s.Boosting then spec.Accel * 2 else spec.Accel
	local decel = spec.Decel
	if over then
		target, accel, decel = over.Speed, over.Accel, over.Decel
	elseif s.EBraking then
		target = if atmos then spec.BrakeSpeed * 0.5 else 0
		decel = spec.EBrakeDecel
	elseif s.Braking or s.Boosting then
		target = ShipFlight.targetSpeed(spec, s.Throttle, s.Boosting, s.Braking)
	else
		local top = spec.MaxSpeed * mk.Speed
		target = spec.MinSpeed + (top - spec.MinSpeed) * clamp(s.Throttle, 0, 1)
	end
	if atmos and not over then
		target -= spec.Gravity * s.Rot.LookVector.Y * 1.1
	end
	local diff = target - s.Speed
	s.Speed += if diff > 0 then math.min(diff, accel * dt) else math.max(diff, -decel * dt)
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
	local top = math.max(spec.BoostSpeed * 1.1, if over then over.Speed * 1.05 else 0)
	s.Speed = clamp(s.Speed, if atmos then spec.BrakeSpeed * 0.5 else 0, top)
	-- Propulsores (lateral y vertical) e inercia
	if not s.Assist and not over then
		-- (sin asistencia, parte de la velocidad sigue por donde iba: la nave derrapa al girar)
		s.Drift += (oldLook - look) * s.Speed * 0.85
	end
	local strafe = clamp(inp.Strafe or 0, -1, 1)
	local liftIn = clamp(inp.Lift or 0, -1, 1)
	local want = s.Rot.RightVector * strafe * spec.StrafeSpeed * mk.Strafe + s.Rot.UpVector * liftIn * spec.VertSpeed * (if atmos then 0.6 else 1)
	if over then
		want = Vector3.zero
	end
	local pushing = strafe ~= 0 or liftIn ~= 0
	local rate = if s.EBraking or over then 5 elseif pushing or s.Assist or recovering then spec.DriftRate else spec.DriftFree
	s.Drift += (want - s.Drift) * math.min(1, rate * dt)
	-- Mover y mirar choques (barridos: cada radio de la nave por el camino)
	local vel = look * s.Speed + Vector3.new(0, s.Sink, 0) + s.Drift + dodgeVel(s)
	if s.Dodge and s.Time - s.Dodge.Start >= s.Dodge.Dur then
		s.Dodge = nil
	end
	local from = s.Pos
	local to = from + vel * dt
	s.Pos = to
	if e.collide then
		local len = (to - from).Magnitude
		local steps = math.clamp(math.ceil(len / math.max(spec.Radius, 1)), 1, 400)
		local safe = from
		for i = 1, steps do
			local p = from:Lerp(to, i / steps)
			local hit = e.collide(p, spec.Radius)
			if hit then
				local speed = vel.Magnitude
				if speed <= spec.CrashSpeed and not over then
					-- Despacio: rebota, pierde velocidad y se endereza (recuperación)
					s.Pos = safe
					local back = if speed > 1e-3 then -vel.Unit else Vector3.new(0, 1, 0)
					s.Drift = back * spec.Bounce
					s.Speed *= 0.3
					s.Dodge = nil
					s.Bumped = hit
					s.RecoverUntil = s.Time + spec.RecoverSeconds
					table.insert(events, "Bump")
				else
					s.Pos = p
					s.Crashed = hit
					s.Speed = 0
					s.Sink = 0
					s.Drift = Vector3.zero
					table.insert(events, "Crash")
				end
				break
			end
			safe = p
		end
	end
	return events
end

-- (servidor) ¿Es posible ir de `from` a `to` en `dt` segundos con esta nave? (con margen por la red).
-- extraSpeed: studs/s de más que el servidor ha aprobado (esquiva, hipervelocidad); extraDist: studs.
function ShipFlight.plausible(spec: Spec, from: Vector3, to: Vector3, dt: number, extraSpeed: number?, extraDist: number?): boolean
	local top = math.max(spec.BoostSpeed * 1.1, spec.MaxSpeed * ShipFlight.Modes.Cruise.Speed * 1.05)
	local side = (spec.StrafeSpeed or 0) + (spec.VertSpeed or 0) + (spec.Bounce or 0)
	local limit = (top + spec.Gravity + side + (extraSpeed or 0)) * 1.3 * math.max(dt, 0) + 25 + (extraDist or 0)
	return (to - from).Magnitude <= limit
end

-- Velocidad para el panel (como el resto del juego: 1 stud/s ≈ 1 km/h)
function ShipFlight.kmh(s: State): number
	return math.floor(ShipFlight.velocity(s).Magnitude + 0.5)
end

return ShipFlight
