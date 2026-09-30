-- Crash: choques entre vehículos (la cuenta; sin Roblox, se prueba con scripts/test-collisions.luau).
--
-- Los vehículos del juego NO usan la física de Roblox: Driving.luau (en el ordenador de quien
-- conduce) coloca el coche en cada fotograma con rayos, y el tráfico, los autobuses y las patrullas
-- del juego van anclados. Por eso los choques se calculan aquí, a mano, como un motor de juego:
--
--   * Cada vehículo es una caja vista desde arriba (centro a ras de suelo, hacia dónde mira, largo,
--     ancho), con su velocidad (plana), su giro (rad/s alrededor del eje Y) y su masa (Crash.Mass).
--   * contact(a, b): si las cajas se tocan (separación por ejes, SAT), hacia dónde empuja el golpe
--     (de a hacia b), cuánto se meten y en qué punto.
--   * resolve(a, b, c): el impulso de un choque de verdad: se reparte según las masas y la velocidad
--     con la que se acercan en el punto del golpe, con un poco de rebote (restitución), roce y giro
--     (un golpe descentrado hace girar). Topes: ningún vehículo cambia de velocidad más de MaxDeltaV
--     ni gira más de MaxSpin (nada sale volando).
--   * Un vehículo "Kinematic" (anclado: aparcado, autobús o patrulla del juego) no se mueve: el otro
--     rebota como contra una pared, pero con la forma, el giro y el roce del choque.
--   * judge(...): lo que hace el servidor con el aviso de un cliente («he chocado con ese»): comprueba
--     velocidades y posiciones con SU vista del mundo, calcula él el impulso y solo entonces se lo
--     manda al otro conductor. Un cliente nunca decide el empujón que recibe otro.
--   * thrown(kind, dv): en moto, bici, patinete o monopatín, un golpe fuerte te tira al suelo.
--   * Los barcos no chocan aquí (Mass = nil): tienen su propia regla en el agua (shared/Boats).

local Crash = {}

-- Masas (≈ kg). Los nombres del tráfico (Controllers/Traffic) van también: Car, Moto, Bici, Patinete.
Crash.Mass = {
	Monopatin = 80,
	Patinete = 95,
	Bici = 105,
	Moto = 260,
	Coche = 1300,
	Car = 1300,
	Patrulla = 1600,
	Camion = 9000,
	Bomberos = 10000,
	Autobus = 12000,
}
Crash.DefaultMass = 1500 -- un vehículo sin tipo conocido (p. ej. una patrulla del juego)
Crash.Boats = { Lancha = true, Gaviota = true } -- nunca chocan con esto

-- Dos ruedas (o una tabla): con un golpe de al menos esta velocidad (studs/s) te caes
Crash.FallSpeed = { Moto = 24, Bici = 16, Patinete = 14, Monopatin = 12 }

Crash.Restitution = { Slow = 0.32, Fast = 0.12, FastAt = 50 } -- rebote: poco, y menos cuanto más fuerte
Crash.Friction = 0.35 -- roce entre las carrocerías (frena el deslizamiento de lado)
Crash.MaxDeltaV = 45 -- lo más que cambia la velocidad de un vehículo en un golpe (studs/s)
Crash.MaxSpin = 3 -- lo más rápido que puede girar por un golpe (rad/s)
Crash.MaxImpulse = 12000 * 45 -- tope absoluto del impulso (masa × velocidad)
Crash.MaxCorrection = 2.5 -- lo más que se separa de un golpe en un fotograma (studs)
Crash.Slop = 0.03 -- se deja este hueco al separar (así no se vuelven a tocar al fotograma siguiente)
Crash.HeightGap = 7 -- más diferencia de altura que esto: uno va por un puente y el otro por debajo
Crash.PushDecay = 4.5 -- el empujón de lado se va con el agarre de las ruedas (1/s)
Crash.SpinDecay = 3.2 -- el giro por el golpe también (1/s)
Crash.FeelSpeed = 3 -- menos que esto (studs/s) es un roce: sin ruido ni temblor

-- Servidor: tolerancias para los avisos de los clientes
Crash.Server = {
	SpeedSlack = 1.25, -- la velocidad que dice llevar: como mucho su máximo × esto (+ 6)
	LagSlack = 4, -- margen de posición por el retraso de la red (studs)…
	LagTime = 0.3, -- …más lo que recorren en este tiempo
	PairGap = 0.4, -- el mismo par de vehículos, como mucho un golpe cada esto (s)
	Burst = 6, -- y cada jugador, como mucho estos avisos…
	BurstWindow = 2, -- …cada tantos segundos
}

export type Body = {
	Pos: Vector3, -- centro a ras de suelo
	Dir: Vector3, -- hacia dónde mira (plano, unitario)
	Length: number,
	Width: number,
	Vel: Vector3, -- velocidad (plana)
	Spin: number, -- giro alrededor del eje Y (rad/s; + = hacia la izquierda, como el Yaw de Driving)
	Mass: number,
	Kinematic: boolean?, -- no lo mueve el choque (aparcado, autobús o patrulla del juego)
	Kind: string?,
}

export type Contact = { Normal: Vector3, Depth: number, Point: Vector3 }

export type Result = {
	VelA: Vector3,
	VelB: Vector3,
	SpinA: number,
	SpinB: number,
	Impulse: number, -- tamaño del impulso (masa × velocidad)
	Closing: number, -- lo rápido que se acercaban por la línea del golpe (studs/s, > 0)
	Type: string, -- "Frontal", "Alcance" (por detrás) o "Lateral"
	MoveA: Vector3, -- cuánto se separa cada uno para que no queden metidos
	MoveB: Vector3,
}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function unitFlat(v: Vector3): Vector3
	local f = flat(v)
	if f.Magnitude < 1e-6 then
		return Vector3.new(0, 0, -1)
	end
	return f.Unit
end

local function rightOf(d: Vector3): Vector3
	return Vector3.new(-d.Z, 0, d.X)
end

-- Componente Y de r × v (los dos planos): el "brazo" de un empujón
local function cross(r: Vector3, v: Vector3): number
	return r.Z * v.X - r.X * v.Z
end

-- Velocidad de un punto de un cuerpo que gira (ω alrededor de Y): v + ω × r
local function pointVel(b: Body, r: Vector3): Vector3
	return b.Vel + Vector3.new(b.Spin * r.Z, 0, -b.Spin * r.X)
end

function Crash.mass(kind: string?): number?
	if kind == nil then
		return Crash.DefaultMass
	end
	if Crash.Boats[kind] then
		return nil
	end
	return Crash.Mass[kind] or Crash.DefaultMass
end

-- ¿Choca este tipo de vehículo con los demás? (los barcos no)
function Crash.collides(kind: string?): boolean
	return Crash.mass(kind) ~= nil
end

function Crash.body(pos: Vector3, dir: Vector3, length: number, width: number, vel: Vector3?, spin: number?, kind: string?, kinematic: boolean?): Body
	return {
		Pos = pos,
		Dir = unitFlat(dir),
		Length = length,
		Width = width,
		Vel = flat(vel or Vector3.zero),
		Spin = spin or 0,
		Mass = Crash.mass(kind) or Crash.DefaultMass,
		Kinematic = kinematic == true,
		Kind = kind,
	}
end

local function inverse(b: Body): (number, number)
	if b.Kinematic then
		return 0, 0
	end
	local m = math.max(b.Mass, 1)
	local inertia = m * (b.Length * b.Length + b.Width * b.Width) / 12
	return 1 / m, 1 / inertia
end

-- Las 4 esquinas de la caja (planas, a la altura de su centro)
function Crash.corners(b: Body): { Vector3 }
	local f = b.Dir * (b.Length / 2)
	local r = rightOf(b.Dir) * (b.Width / 2)
	local p = flat(b.Pos)
	return { p + f + r, p + f - r, p - f - r, p - f + r }
end

local function inside(b: Body, p: Vector3, margin: number): boolean
	local d = p - flat(b.Pos)
	return math.abs(d:Dot(b.Dir)) <= b.Length / 2 + margin and math.abs(d:Dot(rightOf(b.Dir))) <= b.Width / 2 + margin
end

-- ¿Se tocan? (slack = se dan por tocándose aunque les separe esto; lo usa el servidor por el retraso)
function Crash.contact(a: Body, b: Body, slack: number?): Contact?
	if math.abs(a.Pos.Y - b.Pos.Y) > Crash.HeightGap then
		return nil
	end
	local extra = slack or 0
	local d = flat(b.Pos) - flat(a.Pos)
	local af, ar, bf, br = a.Dir, rightOf(a.Dir), b.Dir, rightOf(b.Dir)
	local best, normal = math.huge, af
	for _, axis in { af, ar, bf, br } do
		local ra = math.abs(axis:Dot(af)) * a.Length / 2 + math.abs(axis:Dot(ar)) * a.Width / 2
		local rb = math.abs(axis:Dot(bf)) * b.Length / 2 + math.abs(axis:Dot(br)) * b.Width / 2
		local dist = d:Dot(axis)
		local overlap = ra + rb + extra - math.abs(dist)
		if overlap < 0 then
			return nil
		end
		if overlap < best - 1e-9 then
			best = overlap
			normal = if dist >= 0 then axis else -axis
		end
	end
	local depth = math.max(best - extra, 0)
	-- Punto del golpe: las esquinas de uno que están dentro del otro (su media). Si ninguna (se
	-- cruzan de canto), el punto medio entre las dos caras que se tocan.
	local sum, n = Vector3.zero, 0
	for _, p in Crash.corners(a) do
		if inside(b, p, 0.05 + extra) then
			sum += p
			n += 1
		end
	end
	for _, p in Crash.corners(b) do
		if inside(a, p, 0.05 + extra) then
			sum += p
			n += 1
		end
	end
	local point
	if n > 0 then
		point = sum / n
	else
		local reachA = math.abs(normal:Dot(af)) * a.Length / 2 + math.abs(normal:Dot(ar)) * a.Width / 2
		point = flat(a.Pos) + normal * (reachA - depth / 2)
	end
	return { Normal = normal, Depth = depth, Point = Vector3.new(point.X, (a.Pos.Y + b.Pos.Y) / 2, point.Z) }
end

-- Cómo ha sido el golpe (para el ruido, el temblor y los daños): de frente, por detrás o de lado
function Crash.classify(a: Body, b: Body, normal: Vector3): string
	local aInto = a.Dir:Dot(normal) -- a va hacia b
	local bInto = b.Dir:Dot(normal)
	if math.abs(aInto) > 0.7 and math.abs(bInto) > 0.7 then
		if aInto * bInto < 0 then
			return "Frontal"
		end
		return "Alcance"
	end
	return "Lateral"
end

function Crash.restitution(closing: number): number
	local r = Crash.Restitution
	local t = math.clamp(closing / r.FastAt, 0, 1)
	return r.Slow + (r.Fast - r.Slow) * t
end

-- El choque: velocidades y giros después del golpe (a y b no se tocan: se devuelve el resultado).
-- bounce = false: sin rebote (contacto que sigue, p. ej. empujando despacio)
function Crash.resolve(a: Body, b: Body, c: Contact, bounce: boolean?): Result
	local n = c.Normal
	local invMA, invIA = inverse(a)
	local invMB, invIB = inverse(b)
	local rA = flat(c.Point - a.Pos)
	local rB = flat(c.Point - b.Pos)
	local vrel = pointVel(b, rB) - pointVel(a, rA)
	local vn = vrel:Dot(n)
	local result: Result = {
		VelA = a.Vel,
		VelB = b.Vel,
		SpinA = a.Spin,
		SpinB = b.Spin,
		Impulse = 0,
		Closing = math.max(-vn, 0),
		Type = Crash.classify(a, b, n),
		MoveA = Vector3.zero,
		MoveB = Vector3.zero,
	}
	-- Separarlos (los dos quietos no se mueven: el que se pueda, todo)
	local share = invMA + invMB
	if c.Depth > 0 then
		local total = math.min(c.Depth + Crash.Slop, Crash.MaxCorrection)
		if share > 0 then
			result.MoveA = -n * total * invMA / share
			result.MoveB = n * total * invMB / share
		end
	end
	if vn >= 0 or share <= 0 then
		return result -- ya se separan (o ninguno se puede mover)
	end
	local e = if bounce == false then 0 else Crash.restitution(-vn)
	local rAn, rBn = cross(rA, n), cross(rB, n)
	local denom = invMA + invMB + rAn * rAn * invIA + rBn * rBn * invIB
	local j = -(1 + e) * vn / denom
	-- Topes: ni un impulso enorme ni un cambio de velocidad que lance a nadie
	j = math.min(j, Crash.MaxImpulse)
	if invMA > 0 then
		j = math.min(j, Crash.MaxDeltaV / invMA)
	end
	if invMB > 0 then
		j = math.min(j, Crash.MaxDeltaV / invMB)
	end
	local impulse = n * j
	-- Roce a lo largo de la superficie del golpe (como mucho Friction × el impulso)
	local vt = vrel - n * vn
	if vt.Magnitude > 1e-4 then
		local t = vt.Unit
		local rAt, rBt = cross(rA, t), cross(rB, t)
		local denomT = invMA + invMB + rAt * rAt * invIA + rBt * rBt * invIB
		local jt = math.clamp(-vrel:Dot(t) / denomT, -Crash.Friction * j, Crash.Friction * j)
		impulse += t * jt
	end
	local dvA = -impulse * invMA
	local dvB = impulse * invMB
	if dvA.Magnitude > Crash.MaxDeltaV then
		dvA = dvA.Unit * Crash.MaxDeltaV
	end
	if dvB.Magnitude > Crash.MaxDeltaV then
		dvB = dvB.Unit * Crash.MaxDeltaV
	end
	result.VelA = a.Vel + dvA
	result.VelB = b.Vel + dvB
	result.SpinA = math.clamp(a.Spin - invIA * cross(rA, impulse), -Crash.MaxSpin, Crash.MaxSpin)
	result.SpinB = math.clamp(b.Spin + invIB * cross(rB, impulse), -Crash.MaxSpin, Crash.MaxSpin)
	result.Impulse = impulse.Magnitude
	return result
end

-- El empujón de lado y el giro de un golpe se van apagando (agarre de las ruedas)
function Crash.settle(push: Vector3, spin: number, dt: number): (Vector3, number)
	local keepPush = math.exp(-Crash.PushDecay * dt)
	local keepSpin = math.exp(-Crash.SpinDecay * dt)
	push *= keepPush
	spin *= keepSpin
	if push.Magnitude < 0.05 then
		push = Vector3.zero
	end
	if math.abs(spin) < 0.01 then
		spin = 0
	end
	return push, spin
end

-- Reparte una velocidad nueva entre la marcha (a lo largo de heading) y el empujón (el resto)
function Crash.split(vel: Vector3, heading: Vector3): (number, Vector3)
	local speed = vel:Dot(heading)
	return speed, flat(vel - heading * speed)
end

-- ¿Se cae quien va en este vehículo con un golpe que le cambia la velocidad en dv (studs/s)?
function Crash.thrown(kind: string?, dv: number): boolean
	local limit = kind and Crash.FallSpeed[kind]
	return limit ~= nil and dv >= limit
end

-- Lo que se nota: 0..1 (ruido, temblor, chispas) según la velocidad del golpe
function Crash.strength(closing: number): number
	if closing < Crash.FeelSpeed then
		return 0
	end
	return math.clamp((closing - Crash.FeelSpeed) / 45, 0.05, 1)
end

-- Daños de chapa (solo se ven; se arreglan al aparcar o con el tiempo): 0 nada, 1 abolladura,
-- 2 abolladura y cristal rajado
Crash.DentAt, Crash.GlassAt = 20, 36
function Crash.damageLevel(closing: number): number
	if closing >= Crash.GlassAt then
		return 2
	elseif closing >= Crash.DentAt then
		return 1
	end
	return 0
end

---------------------------------------------------------------------
-- Servidor: avisos de los clientes
---------------------------------------------------------------------

-- Límite de frecuencia: store[key] = última vez. ¿Vale ahora?
function Crash.rate(store: { [any]: number }, key: any, now: number, gap: number): boolean
	local last = store[key]
	if last and now - last < gap then
		return false
	end
	store[key] = now
	return true
end

-- Ráfaga: como mucho `count` en `window` segundos (list = instantes de los últimos avisos)
function Crash.burst(list: { number }, now: number, count: number, window: number): boolean
	local i = 1
	while i <= #list do
		if now - list[i] > window then
			table.remove(list, i)
		else
			i += 1
		end
	end
	if #list >= count then
		return false
	end
	table.insert(list, now)
	return true
end

export type Judgement = { Ok: boolean, Reason: string?, Result: Result?, Contact: Contact? }

-- El servidor decide si un choque que avisa un cliente es de verdad y cuánto empuja al otro.
--   a = el vehículo de quien avisa, b = con el que dice chocar (los dos con la vista del servidor:
--       posiciones de sus piezas y velocidades limitadas); maxA / maxB = sus velocidades máximas
--   claimed = la velocidad que dice llevar (solo se comprueba que sea posible)
function Crash.judge(a: Body, b: Body, maxA: number, maxB: number, claimed: number?): Judgement
	local S = Crash.Server
	if not Crash.collides(a.Kind) or not Crash.collides(b.Kind) then
		return { Ok = false, Reason = "barco" }
	end
	if typeof(claimed) == "number" and (claimed ~= claimed or claimed > maxA * S.SpeedSlack + 6) then
		return { Ok = false, Reason = "velocidad imposible" }
	end
	-- Las velocidades que se usan son las del servidor, nunca más que su máximo (con margen)
	local function capped(v: Vector3, max: number): Vector3
		local limit = max * S.SpeedSlack + 6
		if v.Magnitude > limit then
			return v.Unit * limit
		end
		return v
	end
	a = table.clone(a)
	b = table.clone(b)
	a.Vel = capped(a.Vel, maxA)
	b.Vel = capped(b.Vel, maxB)
	local slack = S.LagSlack + (a.Vel - b.Vel).Magnitude * S.LagTime
	local c = Crash.contact(a, b, slack)
	if not c then
		return { Ok = false, Reason = "lejos" }
	end
	-- Con el retraso, puede que en el servidor aún no se toquen: se usa la línea del golpe igualmente
	local result = Crash.resolve(a, b, c)
	if result.Closing < 1 then
		return { Ok = false, Reason = "no se acercan", Contact = c }
	end
	return { Ok = true, Result = result, Contact = c }
end

return Crash
