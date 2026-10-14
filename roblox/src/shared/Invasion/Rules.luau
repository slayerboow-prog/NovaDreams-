-- Rules: las reglas de la «Invasión de la Grieta» (evento global del servidor; docs/invasion.md).
-- Cuentas puras, iguales en el servidor (Services/InvasionService), el cliente (Controllers/
-- InvasionClient) y las pruebas (scripts/test-invasion.luau).
--
--   * Cuándo: en las fases en que la grieta está ABIERTA de verdad (shared/SkyRift: etapa 5 o más:
--     Abierta, Rota, Inminente, Fusión). Con el ciclo de demostración (Config.SkyRift.DemoCycle) eso
--     pasa dos veces por día de juego (de día y de noche), así que el dueño la ve sin jugar la saga.
--     Sin el ciclo: en cuanto algún jugador conectado tiene su grieta abierta (atributo SkyRift).
--     El modo pruebas la lanza con el botón «Lanzar invasión».
--   * Cómo: aviso (las sirenas de RiftSirens + el aviso del mundo) → oleadas que van a más (naves
--     en el cielo de los aviones, naves de desembarco que aterrizan en sitios abiertos y sueltan
--     tropas de tierra que intentan CONQUISTAR zonas) → fin: VICTORIA si se limpian las oleadas (y el
--     rey, si vino), DERROTA si al cerrarse la grieta (o al acabarse el tiempo) los alienígenas tienen
--     la mayoría de las zonas. Pase lo que pase, al acabar se van los que queden, lo roto se arregla
--     solo y la gente transformada se recupera (Transform).
--   * Topes para el móvil: nunca más de MaxAir naves, MaxGround tropas, MaxDropships naves de
--     desembarco a la vez; el cliente además dibuja menos según su nivel gráfico (FxBudget / Perf).

local Rules = {}

---------------------------------------------------------------------
-- Cuándo
---------------------------------------------------------------------
-- Las fases de la grieta que cuentan como «apertura» (etapa >= 5: el portal está abierto)
Rules.OpeningPhases = { Abierta = true, Rota = true, Inminente = true, Fusion = true }
Rules.Cooldown = 90 -- s mínimos entre el final de una invasión y la siguiente (salvo el modo pruebas)

function Rules.isOpening(phase: string?): boolean
	return type(phase) == "string" and Rules.OpeningPhases[phase] == true
end

-- La fase de la grieta que manda para todo el servidor: con el ciclo de demostración, la de la
-- hora (la misma para todos); sin él, la «más abierta» de los jugadores conectados (sus historias)
function Rules.serverPhase(SkyRift: any, demo: boolean, clock: number, offset: number?, playerPhases: { string }?): string
	if demo then
		return SkyRift.demoPhase(clock, offset)
	end
	local best, bestStage = "Ninguna", 0
	for _, name in playerPhases or {} do
		local ph = SkyRift.Phases[name]
		if ph and ph.Mode == "Sky" and ph.Stage > bestStage then
			best, bestStage = name, ph.Stage
		end
	end
	return best
end

-- ¿Empieza una invasión ahora? (flanco: la grieta se acaba de abrir y no hay otra en marcha)
function Rules.shouldStart(wasOpen: boolean, isOpen: boolean, active: boolean, now: number, lastEnd: number?): boolean
	if active or not isOpen or wasOpen then
		return false
	end
	return lastEnd == nil or now - lastEnd >= Rules.Cooldown
end

---------------------------------------------------------------------
-- Cómo va: estados y oleadas
---------------------------------------------------------------------
Rules.WarnSeconds = 14 -- aviso: sirenas, el cielo se carga, la gente empieza a correr
Rules.WaveSeconds = 50 -- cada oleada (o antes, si se limpia)
Rules.Waves = 4 -- oleadas (más una del rey si viene)
Rules.MaxSeconds = 330 -- tope de la invasión entera (unos 5,5 minutos)
Rules.EndSeconds = 12 -- lo que dura el cartel del final antes de recoger
Rules.MaxAir = 10
Rules.MaxGround = 22
Rules.MaxDropships = 3
Rules.MaxPerPlayer = 6 -- (cuántos más por cada jugador de más, como mucho hasta los topes)

-- Cuántos jugadores cuentan (los que están en Valmar: no en la arena, ni en un planeta)
function Rules.scale(players: number): number
	return math.clamp(1 + 0.3 * (math.max(players, 1) - 1), 1, 3)
end

export type Wave = { Fighters: number, Drones: number, Dropships: number, PerDrop: number, Elite: boolean, King: boolean }

-- Qué trae la oleada n (1..Waves, y Waves+1 = la del rey) con tantos jugadores. Siempre dentro de los topes.
function Rules.wave(n: number, players: number, king: boolean?): Wave
	local k = Rules.scale(players)
	local last = n >= Rules.Waves
	local w = {
		Fighters = math.min(math.floor((1 + n * 0.75) * k + 0.5), 6),
		Drones = math.min(math.floor((1 + n) * k + 0.5), 6),
		Dropships = math.min(if n <= 1 then 1 else 1 + math.floor((n - 1) * 0.5 * k + 0.5), Rules.MaxDropships),
		PerDrop = math.min(3 + n + math.floor(k), 7),
		Elite = n >= 3,
		King = king == true and n > Rules.Waves,
	}
	w.Drones = math.min(w.Drones, Rules.MaxAir - w.Fighters) -- (tope de naves a la vez)
	if w.King then
		w.Fighters, w.Drones, w.Dropships, w.PerDrop = math.min(w.Fighters, 3), math.min(w.Drones, 4), 1, 4
	end
	if last and not w.King then
		w.Elite = true
	end
	return w
end

-- Total de oleadas de esta invasión
function Rules.waveCount(king: boolean?): number
	return Rules.Waves + (if king then 1 else 0)
end

-- ¿Cabe uno más? (los topes nunca se pasan)
function Rules.room(kind: string, alive: number): number
	local cap = if kind == "Air" then Rules.MaxAir elseif kind == "Dropship" then Rules.MaxDropships else Rules.MaxGround
	return math.max(0, cap - alive)
end

-- La máquina de estados: Warn → Wave (1..N) → End. Devuelve el estado siguiente si toca cambiar.
-- s = { State, Since, Wave, Waves, Alive, Spawned (de esta oleada), Open (la grieta), Elapsed }
function Rules.next(s: { [string]: any }, now: number): (string?, string?)
	local t = now - s.Since
	if s.State == "Warn" then
		return if t >= Rules.WarnSeconds then "Wave" else nil, nil
	elseif s.State == "Wave" then
		if s.Elapsed >= Rules.MaxSeconds then
			return "End", "Time"
		end
		if not s.Open and s.Wave >= 2 then
			return "End", "Closed"
		end
		local cleared = s.Spawned and s.Alive == 0
		if cleared or t >= Rules.WaveSeconds then
			if s.Wave >= s.Waves then
				return if cleared then "End" else nil, if cleared then "Cleared" else nil
			end
			return "Wave", nil
		end
	end
	return nil, nil
end

---------------------------------------------------------------------
-- Zonas: los alienígenas intentan CONQUISTAR Valmar
---------------------------------------------------------------------
-- Cada zona (una plaza, el parque, la playa…) tiene Control 0..1: 0 = de Valmar, 1 = conquistada.
-- Los alienígenas cerca la suben; los jugadores cerca la bajan (si hay de los dos, gana el que más
-- haya, más despacio). Conquistada (>= 1) se queda así hasta que los jugadores la recuperan (vuelve a 0).
Rules.ZoneRadius = 70
Rules.CaptureRate = 0.035 -- por alienígena y segundo (hasta 4 cuentan)
Rules.RetakeRate = 0.06 -- por jugador y segundo (hasta 4 cuentan)

export type Zone = { Id: string, Control: number, Conquered: boolean }

-- Devuelve el evento si cambia algo: "Conquered" (acaba de caer) o "Retaken" (recuperada)
function Rules.captureStep(z: Zone, aliens: number, players: number, dt: number): string?
	local a, p = math.min(aliens, 4), math.min(players, 4)
	local before = z.Control
	local delta = 0
	if a > 0 and p == 0 then
		delta = a * Rules.CaptureRate
	elseif p > 0 and a == 0 then
		delta = -p * Rules.RetakeRate
	elseif a > 0 and p > 0 then
		delta = (a * Rules.CaptureRate - p * Rules.RetakeRate) * 0.4
	end
	z.Control = math.clamp(before + delta * dt, 0, 1)
	if not z.Conquered and z.Control >= 1 then
		z.Conquered = true
		return "Conquered"
	elseif z.Conquered and z.Control <= 0 then
		z.Conquered = false
		return "Retaken"
	end
	return nil
end

-- Lo que se ve en la barra: "Valmar" / "Disputa" / "Conquistada"
function Rules.zoneStatus(z: Zone): string
	if z.Conquered then
		return "Conquistada"
	elseif z.Control > 0.02 then
		return "Disputa"
	end
	return "Valmar"
end

-- ¿Cómo acaba para la ciudad? "Victoria" | "Derrota"
function Rules.outcome(reason: string?, conquered: number, zones: number, kingAlive: boolean?): string
	if reason == "Cleared" and not kingAlive then
		return "Victoria"
	end
	if zones > 0 and conquered / zones > 0.5 then
		return "Derrota"
	end
	return if kingAlive then "Derrota" else "Victoria"
end

---------------------------------------------------------------------
-- Las tropas de tierra (sus números base; cada raza los multiplica: Races.Units)
---------------------------------------------------------------------
Rules.Ground = {
	Grunt = { Hp = 90, Damage = 6, Speed = 13, Range = 6, Cooldown = 1.1, Aggro = 70, Score = 10, Radius = 2.2, Height = 6 },
	Heavy = { Hp = 260, Damage = 12, Speed = 9, Range = 9, Cooldown = 1.8, Aggro = 70, Score = 25, Radius = 3.5, Height = 9 },
	Ranged = { Hp = 70, Damage = 7, Speed = 11, Range = 90, Cooldown = 2.2, Aggro = 120, Score = 15, Radius = 2, Height = 7 },
	Elite = { Hp = 650, Damage = 14, Speed = 12, Range = 40, Cooldown = 1.4, Aggro = 110, Score = 80, Radius = 3.5, Height = 11 },
}
-- Qué sale de cada nave de desembarco (en orden)
Rules.DropMix = { "Grunt", "Grunt", "Ranged", "Heavy", "Grunt", "Ranged", "Grunt" }

-- Las naves (EnemyAI.Kinds de shared/AirCombat con más vida en el cielo de la ciudad)
Rules.Air = {
	Fighter = { Ai = "Caza", Hp = 120, Score = 30, Radius = 7 },
	Drone = { Ai = "Dron", Hp = 55, Score = 12, Radius = 5 },
	Dropship = { Hp = 700, Score = 60, Radius = 16, Deploy = 6, Descend = 9 },
	Scout = { Ai = "Caza", Hp = 220, Score = 50, Radius = 8 },
}
-- Banda de altura de las naves alienígenas sobre la ciudad (el cielo de los aviones: shared/Cosmos/Layers)
Rules.AirBand = { Min = 180, Max = 900 }

function Rules.groundStats(kind: string, race: { Units: { [string]: any } }?): { [string]: number }
	local base = Rules.Ground[kind] or Rules.Ground.Grunt
	local m = race and race.Units[kind] or {}
	local out = {}
	for k, v in base do
		out[k] = v
	end
	out.Hp = base.Hp * (m.Hp or 1)
	out.Damage = base.Damage * (m.Damage or 1)
	out.Speed = base.Speed * (m.Speed or 1)
	out.Range = base.Range * (m.Range or 1)
	return out
end

---------------------------------------------------------------------
-- Aviones y naves durante la invasión
---------------------------------------------------------------------
-- La avioneta lleva un cañón SOLO durante la invasión; el avión de línea, nada (es para evacuar)
Rules.PlaneGun = {
	Kinds = { Avioneta = true },
	Damage = 12,
	Cooldown = 0.14,
	Range = 650,
	Cone = math.rad(9), -- dispara hacia delante (con este margen respecto al morro)
	Speed = 900,
	HeatPerShot = 0.06,
	CoolPerSecond = 0.35,
	AssistCone = math.rad(4), -- ayuda a apuntar: el que más centrado esté en este cono
}
Rules.PlaneHp = 160 -- puntos de la avioneta contra los disparos alienígenas (a 0: accidente, nadie muere)

-- Las naves pueden bajar al cielo de la ciudad SOLO durante una invasión (el resto del tiempo su
-- suelo es Layers.FloorY = 260). Durante la invasión, hasta CityShipFloor (por encima de los tejados).
Rules.CityShipFloor = 140

---------------------------------------------------------------------
-- Quién ha ayudado (premio según lo que haya hecho cada uno)
---------------------------------------------------------------------
Rules.Points = {
	Grunt = 10, Heavy = 25, Ranged = 15, Elite = 80, Fighter = 30, Drone = 12, Dropship = 60, Scout = 50,
	King = 400, WeakPoint = 40, Retake = 60, Rescue = 35, Creature = 8, Damage = 0.05, -- (por punto de daño)
}
Rules.Reward = { MoneyPerPoint = 2, XpPerPoint = 0.6, MaxMoney = 2500, MaxXp = 700, MinPoints = 15, VictoryBonus = 1.25 }

function Rules.reward(points: number, outcome: string?): (number, number)
	if points < Rules.Reward.MinPoints then
		return 0, 0
	end
	local R = Rules.Reward
	local k = if outcome == "Victoria" then R.VictoryBonus else 1
	return math.min(math.floor(points * R.MoneyPerPoint * k), R.MaxMoney), math.min(math.floor(points * R.XpPerPoint * k), R.MaxXp)
end

---------------------------------------------------------------------
-- Para el panel
---------------------------------------------------------------------
function Rules.stateText(state: string?, wave: number?, waves: number?, king: boolean?): string
	if state == "Warn" then
		return "¡Se acercan naves por la grieta!"
	elseif state == "Wave" then
		if king and wave and waves and wave >= waves then
			return "¡El rey ha llegado! Oleada final"
		end
		return ("Oleada %d de %d"):format(wave or 1, waves or Rules.Waves)
	elseif state == "End" then
		return "La invasión ha terminado"
	end
	return ""
end

return Rules
