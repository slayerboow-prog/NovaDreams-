-- ShipWeapons: las armas de las naves (cañones láser y misiles con fijación) y sus cuentas.
--
--   * Láser: ráfagas rápidas (Cooldown) de proyectiles muy veloces con trazadora. Calor: cada disparo
--     calienta; recalentado (Heat >= 1) no dispara hasta enfriarse por debajo de CoolTo.
--   * Misil: solo con un blanco FIJADO (shared/AirCombat/Lock); busca al blanco girando como mucho
--     Turn rad/s, deja estela de humo y se acaba a los Life segundos. Pocos (Ammo) y se recargan solos.
-- Lo mismo en el servidor (manda: daño, cadencia, munición) y en el cliente (dibujar al instante).
-- Cuentas puras (scripts/test-aircombat.luau).

local ShipWeapons = {}

ShipWeapons.Laser = {
	Damage = 7,
	Speed = 950, -- studs/s
	Life = 1.1, -- s (alcance ≈ 1000 studs)
	Cooldown = 0.11,
	HeatPerShot = 0.045,
	CoolRate = 0.45, -- por segundo
	CoolTo = 0.55, -- recalentado: vuelve a disparar al bajar de aquí
	Spread = 0.012, -- rad (dos cañones, un poco abiertos)
	Muzzle = 2.6, -- separación de los cañones (studs a cada lado)
	MaxAimOff = math.rad(32), -- (servidor) cuánto se puede apartar el disparo del morro
	HitRadius = 1.2, -- grosor del proyectil
}

ShipWeapons.Missile = {
	Damage = 40,
	Speed = 280,
	Accel = 260, -- sale despacio y acelera
	Turn = 2.6, -- rad/s
	Life = 6,
	Cooldown = 0.9,
	Ammo = 6,
	Reload = 7, -- s por misil
	HitRadius = 5,
}

-- Disparo de los enemigos (más lento: se puede esquivar)
ShipWeapons.EnemyBolt = { Speed = 520, Life = 1.8, HitRadius = 1.6 }

export type Gun = { NextLaser: number, Heat: number, Overheated: boolean, NextMissile: number, Missiles: number, ReloadAt: number }

function ShipWeapons.newGun(): Gun
	return { NextLaser = 0, Heat = 0, Overheated = false, NextMissile = 0, Missiles = ShipWeapons.Missile.Ammo, ReloadAt = 0 }
end

-- Enfría los cañones y recarga misiles (cada fotograma o cada vuelta del servidor)
function ShipWeapons.tick(g: Gun, now: number, dt: number)
	local L = ShipWeapons.Laser
	g.Heat = math.max(0, g.Heat - L.CoolRate * dt)
	if g.Overheated and g.Heat <= L.CoolTo then
		g.Overheated = false
	end
	local M = ShipWeapons.Missile
	if g.Missiles < M.Ammo then
		if g.ReloadAt <= 0 then
			g.ReloadAt = now + M.Reload
		elseif now >= g.ReloadAt then
			g.Missiles += 1
			g.ReloadAt = if g.Missiles < M.Ammo then now + M.Reload else 0
		end
	else
		g.ReloadAt = 0
	end
end

-- ¿Puede disparar el láser ahora? Si sí, lo apunta (cadencia y calor)
function ShipWeapons.tryLaser(g: Gun, now: number): boolean
	if g.Overheated or now < g.NextLaser then
		return false
	end
	g.NextLaser = now + ShipWeapons.Laser.Cooldown
	g.Heat += ShipWeapons.Laser.HeatPerShot
	if g.Heat >= 1 then
		g.Heat = 1
		g.Overheated = true
	end
	return true
end

function ShipWeapons.tryMissile(g: Gun, now: number): boolean
	if g.Missiles <= 0 or now < g.NextMissile then
		return false
	end
	g.NextMissile = now + ShipWeapons.Missile.Cooldown
	g.Missiles -= 1
	if g.ReloadAt <= 0 then
		g.ReloadAt = now + ShipWeapons.Missile.Reload
	end
	return true
end

-- Distancia más corta entre el segmento a→b y el punto p (para los proyectiles rápidos: no se saltan
-- al blanco entre dos vueltas)
function ShipWeapons.segmentDistance(a: Vector3, b: Vector3, p: Vector3): number
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-9 then
		return (p - a).Magnitude
	end
	local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
	return (a + ab * t - p).Magnitude
end

function ShipWeapons.segmentHits(a: Vector3, b: Vector3, center: Vector3, radius: number): boolean
	return ShipWeapons.segmentDistance(a, b, center) <= radius
end

-- (servidor) ¿Es razonable esta dirección de disparo para una nave que mira hacia `look`?
function ShipWeapons.aimAllowed(look: Vector3, dir: Vector3): boolean
	if dir.Magnitude < 0.5 or dir.Magnitude > 1.5 or dir.X ~= dir.X then
		return false
	end
	local c = math.clamp(look.Unit:Dot(dir.Unit), -1, 1)
	return math.acos(c) <= ShipWeapons.Laser.MaxAimOff
end

-- Un paso de un misil que busca: gira hacia `target` como mucho Turn*dt y acelera hasta Speed.
-- m = { Pos, Dir (unitario), Speed }. Devuelve la posición anterior (para el segmento del choque).
function ShipWeapons.steerMissile(m: { [string]: any }, target: Vector3?, dt: number): Vector3
	local M = ShipWeapons.Missile
	local from = m.Pos
	if target then
		local want = target - m.Pos
		if want.Magnitude > 1e-3 then
			want = want.Unit
			local c = math.clamp(m.Dir:Dot(want), -1, 1)
			local angle = math.acos(c)
			local maxTurn = M.Turn * dt
			if angle <= maxTurn or angle < 1e-4 then
				m.Dir = want
			else
				local t = maxTurn / angle
				m.Dir = (m.Dir * (1 - t) + want * t).Unit
			end
		end
	end
	m.Speed = math.min(M.Speed, m.Speed + M.Accel * dt)
	m.Pos = m.Pos + m.Dir * m.Speed * dt
	return from
end

return ShipWeapons
