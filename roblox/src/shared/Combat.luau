-- Combat: reglas del combate cuerpo a cuerpo (lo usan CombatService en el servidor y
-- CombatController en el cliente). Se puede pegar a otros jugadores por la calle y en misiones.
--
--   * Combo de 3 golpes: puñetazo, puñetazo y golpe fuerte (empuja). Pulsar a tiempo encadena.
--   * Defender (mantener): si miras al que te pega, recibes solo una parte del daño y no te empuja.
--   * Fuerza (estadística del personaje): +4% de daño por punto.
--   * K.O. en vez de morir: al quedarte sin vida caes unos segundos y te levantas con algo de vida.
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
Combat.MinStage = "Nino" -- a partir de niño (los bebés ni pegan ni reciben)

-- Daño de un golpe
function Combat.damage(combo: number, fuerza: number?, blocked: boolean?): number
	local base = Combat.Damage[math.clamp(combo, 1, #Combat.Damage)]
	local amount = base * (1 + math.max(0, fuerza or 0) * Combat.PerFuerza)
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

return Combat
