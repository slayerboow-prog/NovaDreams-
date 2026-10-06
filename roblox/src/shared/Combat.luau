-- Combat: reglas del combate cuerpo a cuerpo (lo usan CombatService en el servidor y
-- CombatController en el cliente). Se puede pegar a otros jugadores por la calle y en misiones.
--
--   * Combo de 3 golpes: puñetazo, puñetazo y golpe fuerte (empuja). Pulsar a tiempo encadena.
--   * Defender (mantener): si miras al que te pega, recibes solo una parte del daño y no te empuja.
--   * Fuerza (estadística del personaje): +4% de daño por punto.
--   * Músculo del gimnasio (GymStrength, 0..100): hasta un +20% más de daño.
--   * K.O.: al quedarte sin vida caes unos segundos y te levantas con algo de vida… salvo que
--     alguien te remate en el suelo: entonces mueres y reapareces en el hospital (shared/Hospital).
--   * Nadie puede pegar ni recibir golpes siendo bebé, en una conversación, en clase, en un
--     minijuego, recién aparecido o mientras está K.O.

local Combat = {}

Combat.Damage = { 8, 8, 15 } -- por golpe del combo
Combat.Range = 6 -- studs por delante del atacante
Combat.HitRadius = 4 -- tamaño de la zona del golpe
Combat.FacingDot = 0.25 -- cuánto tiene que estar delante (1 = justo delante)
Combat.Cooldown = { 0.32, 0.32, 0.65 } -- pausa después de cada golpe del combo
Combat.ComboWindow = 0.9 -- segundos para encadenar el siguiente golpe
Combat.MaxTargets = 2
Combat.Knockback = { 6, 6, 32 } -- empujón (studs/s) de cada golpe
Combat.BlockFactor = 0.2 -- parte del daño que pasa si te defiendes de cara
Combat.KOSeconds = 6
Combat.KOHealth = 0.35 -- vida (fracción) con la que te levantas
Combat.SpawnProtection = 5 -- segundos sin poder recibir golpes al aparecer
Combat.PerFuerza = 0.04
Combat.PerMuscle = 0.002 -- por punto de Fuerza del gimnasio (Shared/Gym: +20 % a 100)
Combat.MinStage = "Nino" -- a partir de niño (los bebés ni pegan ni reciben)
-- Esquivar: una voltereta por el suelo (hacia delante, o hacia donde empujas el joystick) con un
-- instante en que los golpes no te dan. La postura la dibuja Controllers/RollMotion.
Combat.RollTime = 0.7 -- lo que dura la voltereta (segundos)
Combat.RollSpeed = 24 -- studs/s al empezar a rodar…
Combat.RollEndSpeed = 0.35 -- …y al acabar va a esta parte (frena rodando)
Combat.DodgeInvulnerable = 0.35 -- segundos sin recibir golpes (al principio de la voltereta)
Combat.DodgeCooldown = 1.1 -- pausa entre dos esquivas (más que la voltereta: no se encadenan)

-- Velocidad de la voltereta en el instante t (0..1): sale fuerte y frena suave hasta RollEndSpeed
function Combat.rollSpeed(t: number): number
	local x = math.clamp(t, 0, 1)
	local k = 1 - x * x * (3 - 2 * x)
	return Combat.RollSpeed * (Combat.RollEndSpeed + (1 - Combat.RollEndSpeed) * k)
end

-- ¿Esquiva este golpe? (dentro del instante de esquiva)
function Combat.dodging(dodgeAt: number?, now: number): boolean
	return dodgeAt ~= nil and now - dodgeAt >= 0 and now - dodgeAt <= Combat.DodgeInvulnerable
end

-- Daño de un golpe
function Combat.damage(combo: number, fuerza: number?, blocked: boolean?, muscle: number?): number
	local base = Combat.Damage[math.clamp(combo, 1, #Combat.Damage)]
	local amount = base * (1 + math.max(0, fuerza or 0) * Combat.PerFuerza)
	amount *= 1 + math.clamp(muscle or 0, 0, 100) * Combat.PerMuscle
	if blocked then
		amount *= Combat.BlockFactor
	end
	return math.max(1, math.floor(amount + 0.5))
end

-- Siguiente golpe del combo: si el anterior fue hace poco se encadena; si no, vuelve al primero
function Combat.nextCombo(last: number, lastAt: number, now: number): number
	if last >= 1 and last < #Combat.Damage and now - lastAt <= Combat.ComboWindow then
		return last + 1
	end
	return 1
end

-- ¿Se puede pegar ya? (la pausa depende del golpe anterior)
function Combat.ready(last: number, lastAt: number, now: number): boolean
	local wait = Combat.Cooldown[math.clamp(last, 1, #Combat.Cooldown)] or 0
	return last == 0 or now - lastAt >= wait
end

-- Resultado de un golpe sobre alguien con "health" de vida: (vida nueva, ¿K.O.?)
function Combat.apply(health: number, amount: number): (number, boolean)
	local after = health - amount
	if after <= 0 then
		return 1, true
	end
	return after, false
end

---------------------------------------------------------------------
-- ESTILO DE LUCHA: combos, guardia, aguante, energía, aire (CombatService y CombatController).
-- Lo de arriba (Damage, nextCombo, ready…) sigue valiendo para lo que ya lo usaba (armas, atropellos).
--
--   * Golpes ligeros (hasta Combat.MaxLights seguidos): directo, cruzado, gancho, rodillazo, codazo y
--     el sexto, una patada que empuja.
--   * Golpe fuerte: solo, "Golpe fuerte" (y un segundo seguido, "Patada giratoria"). Después de
--     ligeros cambia el final: 1-2 ligeros + fuerte = LANZADOR (al aire), 3-4 = EMPUJÓN LEJANO (vuela y
--     puede chocar con una pared), 5-6 = GOLPE AL SUELO (derribado). En el aire: ligeros aéreos y el
--     fuerte es el REMATE AÉREO (hacia abajo).
--   * Golpe cargado (mantener el fuerte Combat.ChargeTime): rompe la guardia.
--   * Guardia: quita casi todo el daño, pero gasta la barra de guardia; vacía = guardia rota (aturdido).
--   * Aguante: lo gastan desvanecerse y el impulso aéreo; se recupera solo.
--   * Energía: sube al golpear, al recibir y manteniendo Cargar; la gastan los poderes (shared/Powers).
-- Todo con números (sin Vector3): se prueba fuera de Roblox (scripts/test-combos.luau).
---------------------------------------------------------------------

Combat.MaxLights = 6
Combat.ChainWindow = 0.85 -- segundos para encadenar el siguiente golpe del combo
Combat.ChargeTime = 0.55 -- mantener el fuerte esto = golpe cargado
Combat.MaxChargeHold = 2.5 -- (más no cuenta: suelta solo)
Combat.ReadySlack = 0.85 -- el servidor deja pegar un poco antes (la red no es exacta)
Combat.LockReach = 3 -- con objetivo fijado alcanzas un poco más (te lanzas hacia él)

export type Move = {
	Damage: number,
	Knockback: number, -- empujón horizontal (studs/s)
	Lift: number, -- hacia arriba (negativo: contra el suelo)
	Stun: number, -- segundos sin poder hacer nada (el que lo recibe)
	Recovery: number, -- pausa del que pega antes del siguiente
	GuardDamage: number, -- lo que quita a la barra de guardia si se defiende
	Hitstop: number, -- congelación del impacto (segundos)
	Anim: string, -- postura (Controllers/PunchAnim)
	Label: string?, -- nombre del final (sale en pantalla)
	Heavy: boolean?,
	Down: number?, -- derribado: segundos en el suelo
	Air: number?, -- en el aire: segundos flotando (lanzador y golpes aéreos)
	Launch: boolean?, -- el que pega sube detrás (lanzador)
	Wall: boolean?, -- puede estamparse contra una pared
	GuardBreak: boolean?, -- rompe la guardia
	Energy: boolean?, -- poder de energía (lo marcan los poderes)
}

Combat.Moves = {
	L1 = { Damage = 5, Knockback = 3, Lift = 0, Stun = 0.4, Recovery = 0.2, GuardDamage = 6, Hitstop = 0.05, Anim = "Jab" },
	L2 = { Damage = 5, Knockback = 3, Lift = 0, Stun = 0.4, Recovery = 0.2, GuardDamage = 6, Hitstop = 0.05, Anim = "Cross" },
	L3 = { Damage = 6, Knockback = 3, Lift = 0, Stun = 0.42, Recovery = 0.22, GuardDamage = 7, Hitstop = 0.05, Anim = "Hook" },
	L4 = { Damage = 6, Knockback = 4, Lift = 0, Stun = 0.42, Recovery = 0.22, GuardDamage = 7, Hitstop = 0.06, Anim = "Knee" },
	L5 = { Damage = 7, Knockback = 4, Lift = 0, Stun = 0.45, Recovery = 0.24, GuardDamage = 8, Hitstop = 0.06, Anim = "Elbow" },
	L6 = { Damage = 9, Knockback = 36, Lift = 10, Stun = 0.75, Recovery = 0.45, GuardDamage = 12, Hitstop = 0.08, Anim = "Kick", Label = "Empujón" },
	H1 = { Damage = 12, Knockback = 24, Lift = 6, Stun = 0.65, Recovery = 0.5, GuardDamage = 25, Hitstop = 0.09, Anim = "Kick", Heavy = true, Label = "Golpe fuerte" },
	H2 = { Damage = 14, Knockback = 44, Lift = 12, Stun = 0.8, Recovery = 0.6, GuardDamage = 30, Hitstop = 0.1, Anim = "SpinKick", Heavy = true, Down = 1.2, Wall = true, Label = "Patada giratoria" },
	Lanzador = { Damage = 12, Knockback = 4, Lift = 58, Stun = 0.6, Recovery = 0.35, GuardDamage = 22, Hitstop = 0.1, Anim = "Uppercut", Heavy = true, Air = 1.4, Launch = true, Label = "¡Lanzador!" },
	Empujon = { Damage = 15, Knockback = 72, Lift = 14, Stun = 0.9, Recovery = 0.6, GuardDamage = 28, Hitstop = 0.12, Anim = "SpinKick", Heavy = true, Down = 1.4, Wall = true, Label = "¡Empujón lejano!" },
	Suelo = { Damage = 18, Knockback = 8, Lift = -40, Stun = 0.9, Recovery = 0.6, GuardDamage = 30, Hitstop = 0.12, Anim = "Slam", Heavy = true, Down = 1.6, Label = "¡Al suelo!" },
	AirL = { Damage = 5, Knockback = 3, Lift = 10, Stun = 0.45, Recovery = 0.2, GuardDamage = 6, Hitstop = 0.05, Anim = "Jab", Air = 0.9 },
	Remate = { Damage = 14, Knockback = 14, Lift = -75, Stun = 0.9, Recovery = 0.55, GuardDamage = 25, Hitstop = 0.12, Anim = "Slam", Heavy = true, Down = 1.5, Label = "¡Remate aéreo!" },
	Cargado = { Damage = 20, Knockback = 52, Lift = 10, Stun = 1, Recovery = 0.7, GuardDamage = 999, Hitstop = 0.16, Anim = "Charged", Heavy = true, Down = 1.2, Wall = true, GuardBreak = true, Label = "¡Golpe cargado!" },
} :: { [string]: Move }

-- Para enseñar los finales (ayuda en pantalla y pruebas): combinación -> golpe
Combat.Finishers = {
	{ Lights = 0, Move = "H1" },
	{ Lights = 1, Move = "Lanzador" },
	{ Lights = 2, Move = "Lanzador" },
	{ Lights = 3, Move = "Empujon" },
	{ Lights = 4, Move = "Empujon" },
	{ Lights = 5, Move = "Suelo" },
	{ Lights = 6, Move = "Suelo" },
}

export type Chain = { Lights: number, Heavies: number, At: number }

function Combat.newChain(): Chain
	return { Lights = 0, Heavies = 0, At = -math.huge }
end

-- Siguiente golpe del combo. kind: "Light" | "Heavy". charged: fuerte mantenido. airborne: en el aire
-- (después de un lanzador). Devuelve el nombre del golpe (Combat.Moves) y la cadena nueva.
function Combat.nextMove(chain: Chain, kind: string, now: number, charged: boolean?, airborne: boolean?): (string, Chain)
	local fresh = now - chain.At > Combat.ChainWindow
	local lights = if fresh then 0 else chain.Lights
	local heavies = if fresh then 0 else chain.Heavies
	if kind ~= "Heavy" then
		if airborne then
			return "AirL", { Lights = math.min(lights + 1, Combat.MaxLights), Heavies = 0, At = now }
		end
		lights = if lights >= Combat.MaxLights then 1 else lights + 1
		return "L" .. lights, { Lights = lights, Heavies = 0, At = now }
	end
	local reset = { Lights = 0, Heavies = 0, At = now }
	if charged then
		return "Cargado", reset
	elseif airborne then
		return "Remate", reset
	elseif lights == 0 then
		if heavies >= 1 then
			return "H2", reset
		end
		return "H1", { Lights = 0, Heavies = 1, At = now }
	end
	for _, f in Combat.Finishers do
		if f.Lights == math.min(lights, Combat.MaxLights) then
			return f.Move, reset
		end
	end
	return "H1", reset
end

-- ¿Se puede dar ya otro golpe? (la pausa es la Recovery del anterior; slack < 1 para el servidor)
function Combat.readyMove(last: string?, lastAt: number, now: number, slack: number?): boolean
	local move = last and Combat.Moves[last]
	if not move then
		return true
	end
	return now - lastAt >= move.Recovery * (slack or 1)
end

-- Daño de un golpe del estilo nuevo (fuerza y gimnasio como siempre; defendido pasa BlockFactor)
function Combat.moveDamage(name: string, fuerza: number?, muscle: number?, blocked: boolean?, mul: number?): number
	local move = Combat.Moves[name]
	local base = if move then move.Damage else Combat.Damage[1]
	local amount = base * (1 + math.max(0, fuerza or 0) * Combat.PerFuerza)
	amount *= 1 + math.clamp(muscle or 0, 0, 100) * Combat.PerMuscle
	amount *= mul or 1
	if blocked then
		amount *= Combat.BlockFactor
	end
	return math.max(1, math.floor(amount + 0.5))
end

---------------------------------------------------------------------
-- Guardia
---------------------------------------------------------------------
Combat.GuardMax = 100
Combat.GuardRegen = 22 -- por segundo, si no te dan
Combat.GuardRegenDelay = 1.2
Combat.GuardBreakStun = 1.3 -- aturdido al romperse la guardia
Combat.GuardAfterBreak = 50 -- con lo que vuelve la barra

-- Golpe contra la guardia: (barra nueva, ¿rota?)
function Combat.guardHit(guard: number, move: Move): (number, boolean)
	if move.GuardBreak then
		return 0, true
	end
	local after = guard - move.GuardDamage
	if after <= 0 then
		return 0, true
	end
	return after, false
end

---------------------------------------------------------------------
-- Aguante (esquivar / desvanecerse / impulso aéreo) y energía
---------------------------------------------------------------------
Combat.StaminaMax = 100
Combat.StaminaRegen = 24 -- por segundo
Combat.StaminaRegenDelay = 0.8
Combat.VanishCost = 34 -- desvanecerse (unas 3 seguidas con la barra llena)
Combat.EscapeCost = 50 -- desvanecerse justo después de recibir un golpe (escapar del combo)
Combat.VanishWindow = 0.6 -- tras recibir un golpe, Esquivar = escapar desvaneciéndose
Combat.VanishDistance = 5 -- a cuánto del rival apareces (detrás o a un lado)
Combat.VanishInvulnerable = 0.4
Combat.VanishCooldown = 0.45
Combat.AirDashCost = 15
Combat.AirDashes = 2 -- impulsos aéreos por salto
Combat.GetUpInvulnerable = 0.6 -- al levantarse del suelo no te pueden volver a pegar enseguida

Combat.EnergyMax = 100
Combat.EnergyPerHit = 5 -- por golpe que das
Combat.EnergyWhenHit = 2 -- por golpe que recibes
Combat.ChargeRate = 32 -- por segundo, manteniendo Cargar

-- Recupera una barra: valor, máximo, ritmo por segundo, segundos desde el último gasto, espera, dt
function Combat.regen(value: number, max: number, rate: number, since: number, delay: number, dt: number): number
	if since < delay then
		return value
	end
	return math.min(max, value + rate * dt)
end

-- ¿Qué hace Esquivar? "Vanish" (desvanecerse: aparece detrás o a un lado del rival) o "Roll" (voltereta).
-- Desvanecerse si tienes aguante y: acabas de recibir un golpe (escapar), tienes a alguien fijado o
-- estás en el aire. Devuelve también lo que cuesta.
function Combat.dodgeKind(stamina: number, locked: boolean, sinceHit: number, airborne: boolean?): (string, number)
	local escaping = sinceHit <= Combat.VanishWindow
	local cost = if escaping then Combat.EscapeCost else Combat.VanishCost
	if (escaping or locked or airborne) and stamina >= cost then
		return "Vanish", cost
	end
	return "Roll", 0
end

-- Rodar tras un salto: Esquivar en el aire se guarda y, al tocar el suelo, se rueda enseguida.
Combat.RollBuffer = 0.4 -- segundos antes de tocar el suelo que vale pulsar Esquivar
Combat.LandWindow = 0.25 -- segundos después de aterrizar en los que Esquivar también rueda (sin bloqueos)

-- En el aire, ¿se guarda la voltereta para el aterrizaje? (desvanecerse sigue siendo para escapar de
-- un golpe o con alguien fijado; un salto normal + Esquivar = rodar al caer)
function Combat.queueAirRoll(locked: boolean, sinceHit: number): boolean
	return not locked and sinceHit > Combat.VanishWindow
end

-- Al aterrizar (o justo después), ¿toca rodar? pressedAt = cuándo se pulsó Esquivar en el aire
function Combat.rollOnLanding(pressedAt: number?, landedAt: number): boolean
	return pressedAt ~= nil and landedAt - pressedAt <= Combat.RollBuffer and landedAt >= pressedAt
end

-- ¿Puede actuar (pegar, defenderse, cargar…)? Aturdido o en el suelo, no.
function Combat.canAct(now: number, stunUntil: number?, downUntil: number?): boolean
	return now >= (stunUntil or 0) and now >= (downUntil or 0)
end

-- Cuánto dura lo que deja a la víctima un golpe (aturdido y, si la derriba, más el levantarse)
function Combat.stunFor(move: Move): number
	if move.Down then
		return move.Down + 0.35
	end
	return move.Stun
end

return Combat
