-- EnemyAI: cómo piensan los enemigos del combate aéreo (cuentas puras: las usa AirCombatService en el
-- servidor y las prueba scripts/test-aircombat.luau).
--
--   * Dron (robot): van en ENJAMBRE. Se acercan y, ya cerca, te rodean en círculo (cada uno con su
--     fase y su plano, sin chocarse entre ellos: separación) y disparan al pasar de cara.
--   * Caza enemigo (con piloto): DUELO. Te persigue apuntando a donde vas a estar; si le das o te le
--     pones detrás, rompe y esquiva un rato; si se te echa encima, se aleja para volver a entrar.
--   * Torreta: quieta (en el suelo o en un asteroide); gira hacia ti y dispara si estás a tiro.
--
-- Elegir blanco (pickTarget): primero quien le ha disparado hace poco (si sigue cerca), si no se queda
-- con el que tenía (no cambia de idea cada segundo) salvo que otro esté mucho más cerca, y si no, el más
-- cercano dentro de su radio de alerta. Sirve para uno o varios jugadores (cooperativo en la Saga 2).

local EnemyAI = {}

export type Stats = {
	Speed: number,
	Turn: number, -- rad/s
	Range: number, -- alcance del disparo
	FireCone: number, -- rad: dispara si te tiene así de centrado
	FireCooldown: number,
	Damage: number,
	Aggro: number, -- radio de alerta
	Orbit: number?, -- (dron) radio del círculo alrededor del blanco
	Radius: number, -- tamaño para los impactos
	Score: number,
}

EnemyAI.Kinds = {
	Dron = { Speed = 150, Turn = 2.2, Range = 520, FireCone = math.rad(10), FireCooldown = 1.1, Damage = 4, Aggro = 1600, Orbit = 140, Radius = 4.5, Score = 100 },
	Caza = { Speed = 185, Turn = 1.5, Range = 650, FireCone = math.rad(6), FireCooldown = 0.45, Damage = 5, Aggro = 2000, Radius = 6, Score = 250 },
	Torreta = { Speed = 0, Turn = 1.1, Range = 760, FireCone = math.rad(5), FireCooldown = 0.8, Damage = 6, Aggro = 900, Radius = 7, Score = 150 },
} :: { [string]: Stats }

-- Lo que cada tipo usa de shared/AirCombat/Shields
EnemyAI.ShieldSpec = { Dron = "Dron", Caza = "CazaEnemigo", Torreta = "Torreta" }

export type Enemy = {
	Id: string,
	Kind: string,
	Stats: Stats,
	Pos: Vector3,
	Look: Vector3,
	Speed: number,
	Target: string?,
	Mode: string, -- "Chase" | "Strafe" | "Pursue" | "Evade" | "Extend" | "Aim" | "Idle"
	ModeUntil: number,
	NextFire: number,
	Phase: number, -- (dron) fase del círculo
	Side: number, -- -1 | 1 (hacia dónde rompe al esquivar)
	LastHitBy: string?,
	LastHitAt: number,
	Mult: { [string]: number }, -- multiplicadores de la oleada (Damage, Fire, Speed)
}

export type Pilot = { Id: string, Pos: Vector3, Vel: Vector3?, Look: Vector3?, Alive: boolean? }

local UP = Vector3.new(0, 1, 0)

function EnemyAI.new(id: string, kind: string, pos: Vector3, look: Vector3?, mult: { [string]: number }?, phase: number?): Enemy
	local stats = EnemyAI.Kinds[kind] or EnemyAI.Kinds.Dron
	local m = mult or {}
	return {
		Id = id,
		Kind = kind,
		Stats = stats,
		Pos = pos,
		Look = if look and look.Magnitude > 0 then look.Unit else Vector3.new(0, 0, -1),
		Speed = stats.Speed * (m.Speed or 1),
		Target = nil,
		Mode = if kind == "Torreta" then "Aim" else "Chase",
		ModeUntil = 0,
		NextFire = 1 + (phase or 0) % 1,
		Phase = phase or 0,
		Side = if (phase or 0) % 2 < 1 then 1 else -1,
		LastHitBy = nil,
		LastHitAt = -math.huge,
		Mult = m,
	}
end

local function find(pilots: { Pilot }, id: string?): Pilot?
	if not id then
		return nil
	end
	for _, p in pilots do
		if p.Id == id and p.Alive ~= false then
			return p
		end
	end
	return nil
end

-- A quién ataca este enemigo ahora (Id o nil)
function EnemyAI.pickTarget(e: Enemy, pilots: { Pilot }, now: number): string?
	local aggro = e.Stats.Aggro
	local attacker = find(pilots, e.LastHitBy)
	if attacker and now - e.LastHitAt < 6 and (attacker.Pos - e.Pos).Magnitude < aggro * 1.5 then
		return attacker.Id
	end
	local closest, closestD = nil, math.huge
	for _, p in pilots do
		if p.Alive ~= false then
			local d = (p.Pos - e.Pos).Magnitude
			if d < closestD then
				closest, closestD = p, d
			end
		end
	end
	local current = find(pilots, e.Target)
	if current then
		local d = (current.Pos - e.Pos).Magnitude
		if d < aggro * 1.3 and not (closest and closest ~= current and closestD < d * 0.5) then
			return current.Id
		end
	end
	if closest and closestD <= aggro then
		return closest.Id
	end
	return nil
end

-- Le han dado (para la persecución y para esquivar)
function EnemyAI.hit(e: Enemy, by: string?, now: number)
	e.LastHitBy = by
	e.LastHitAt = now
end

local function safeUnit(v: Vector3, fallback: Vector3): Vector3
	return if v.Magnitude > 1e-4 then v.Unit else fallback
end

-- Separación del enjambre: aparta de los vecinos que están más cerca que `radius`
function EnemyAI.separation(e: Enemy, neighbors: { Enemy }, radius: number): Vector3
	local push = Vector3.zero
	for _, n in neighbors do
		if n ~= e then
			local d = e.Pos - n.Pos
			local m = d.Magnitude
			if m > 1e-3 and m < radius then
				push += d.Unit * ((radius - m) / radius)
			end
		end
	end
	return push
end

-- Decide adónde ir y si dispara. Devuelve (dirección deseada unitaria, velocidad deseada, ¿dispara?)
function EnemyAI.think(e: Enemy, target: Pilot?, now: number, neighbors: { Enemy }?): (Vector3, number, boolean)
	local st = e.Stats
	local speedMul = e.Mult.Speed or 1
	if not target then
		e.Mode = if e.Kind == "Torreta" then "Aim" else "Idle"
		-- Sin blanco: da vueltas suaves (o la torreta se queda quieta)
		if e.Kind == "Torreta" then
			return e.Look, 0, false
		end
		local around = e.Look:Cross(UP)
		return safeUnit(e.Look + around * 0.15, e.Look), st.Speed * 0.6 * speedMul, false
	end
	local to = target.Pos - e.Pos
	local dist = to.Magnitude
	local toUnit = safeUnit(to, e.Look)
	local facing = math.acos(math.clamp(e.Look:Dot(toUnit), -1, 1))
	local canFire = dist <= st.Range and facing <= st.FireCone and now >= e.NextFire
	local desired = toUnit
	local speed = st.Speed * speedMul
	if e.Kind == "Torreta" then
		e.Mode = "Aim"
		local lead = target.Pos + (target.Vel or Vector3.zero) * (dist / 520)
		return safeUnit(lead - e.Pos, toUnit), 0, canFire
	elseif e.Kind == "Dron" then
		local orbit = st.Orbit or 140
		if dist > orbit * 1.8 then
			e.Mode = "Chase"
			desired = toUnit
		else
			e.Mode = "Strafe"
			-- Tangente del círculo en su propio plano (según la fase): unos por arriba, otros de lado
			local axis = safeUnit(UP * math.cos(e.Phase) + toUnit:Cross(UP) * math.sin(e.Phase), UP)
			local tangent = safeUnit(toUnit:Cross(axis), e.Look)
			local radial = toUnit * ((dist - orbit) / orbit)
			desired = safeUnit(tangent + radial * 1.2, tangent)
			-- Al pasar de cara, apunta un momento para disparar
			if facing < st.FireCone * 3 then
				desired = safeUnit(desired + toUnit * 1.5, desired)
			end
		end
		if neighbors then
			desired = safeUnit(desired + EnemyAI.separation(e, neighbors, 40) * 1.5, desired)
		end
		return desired, speed, canFire
	end
	-- Caza enemigo: perseguir, esquivar, alejarse
	local tLook = target.Look or Vector3.new(0, 0, -1)
	local behindMe = (e.Pos - target.Pos).Magnitude < 320 and math.acos(math.clamp(tLook:Dot(safeUnit(e.Pos - target.Pos, tLook)), -1, 1)) < math.rad(14)
	if now >= e.ModeUntil then
		if now - e.LastHitAt < 0.5 or behindMe then
			e.Mode = "Evade"
			e.ModeUntil = now + 1.8
			e.Side = -e.Side
		elseif dist < 70 then
			e.Mode = "Extend"
			e.ModeUntil = now + 1.6
		else
			e.Mode = "Pursue"
			e.ModeUntil = now + 0.5
		end
	end
	if e.Mode == "Evade" then
		local side = safeUnit(toUnit:Cross(UP), e.Look) * e.Side
		desired = safeUnit(side * 1.4 + UP * 0.5 - toUnit * 0.3, side)
		speed *= 1.15
		canFire = false
	elseif e.Mode == "Extend" then
		desired = safeUnit(e.Look - toUnit * 0.6 + UP * 0.2, e.Look)
		speed *= 1.1
		canFire = false
	else
		local lead = target.Pos + (target.Vel or Vector3.zero) * math.min(dist / 520, 1.5)
		desired = safeUnit(lead - e.Pos, toUnit)
	end
	return desired, speed, canFire
end

-- Gira hacia `desired` como mucho Turn*dt, ajusta la velocidad y avanza (la torreta solo gira)
function EnemyAI.steer(e: Enemy, desired: Vector3, speed: number, dt: number)
	local c = math.clamp(e.Look:Dot(desired), -1, 1)
	local angle = math.acos(c)
	local maxTurn = e.Stats.Turn * dt
	if angle <= maxTurn or angle < 1e-4 then
		e.Look = desired
	else
		-- (casi de espaldas: gira hacia un lado, no se queda parado)
		local blendTo = if c < -0.999 then safeUnit(desired + e.Look:Cross(UP) * 0.2, desired) else desired
		e.Look = safeUnit(e.Look * (1 - maxTurn / angle) + blendTo * (maxTurn / angle), e.Look)
	end
	if e.Kind == "Torreta" then
		e.Speed = 0
		return
	end
	e.Speed += math.clamp(speed - e.Speed, -120 * dt, 120 * dt)
	e.Pos += e.Look * e.Speed * dt
end

-- Ya ha disparado: siguiente disparo (con la cadencia de la oleada)
function EnemyAI.fired(e: Enemy, now: number)
	e.NextFire = now + e.Stats.FireCooldown / (e.Mult.Fire or 1)
end

function EnemyAI.damage(e: Enemy): number
	return e.Stats.Damage * (e.Mult.Damage or 1)
end

return EnemyAI
