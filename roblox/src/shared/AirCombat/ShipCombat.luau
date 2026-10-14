-- ShipCombat: las reglas del combate y los extras de la nave de la segunda tanda del Espacio AAA
-- (fases 7 a 9; docs/espacio-aaa/diseno.md). Cuentas puras: las usa el servidor (manda:
-- Services/ShipSystems, AirCombatService) y el cliente (predice y pinta), y las prueba
-- scripts/test-espacio-aaa.luau.
--
--   * Fijar un misil: distancia, ángulo y LÍNEA DE VISIÓN (canLock).
--   * Cambiar de objetivo (cycle): el siguiente por ángulo desde el morro.
--   * Misiles ENEMIGOS (los cazas): mismas reglas de fijado; se pueden esquivar o engañar.
--   * CONTRAMEDIDAS (bengalas): cargas limitadas que se reponen, recarga corta; rompen el fijado de los
--     misiles que vienen (salvo los que ya están encima).
--   * SOBRECARGA DEL ESCUDO (el «escudo especial»): +60 % de escudo un rato; gasta energía y al acabar
--     se recalienta (un rato sin regenerar).
--   * CAMUFLAJE: se desvanece poco a poco; los enemigos solo te ven muy cerca y los radares de los
--     demás no te enseñan; gasta energía, dura poco y se rompe al disparar (no es invisibilidad total).
--   * DRONES modulares: combate, defensa, exploración y reparación; solo los desbloqueados.
--   * Mejoras de la nave (blindaje, baterías, bengalas) y precios (Chispas y dinero de Valmar; nada de
--     Robux).

local ShipCombat = {}

---------------------------------------------------------------------
-- Fijado, objetivos y amenazas
---------------------------------------------------------------------
ShipCombat.MissileLock = { Range = 950, Cone = math.rad(13) }

-- ¿Se puede fijar un misil a `target` desde aquí? -> ok, motivo ("Lejos" | "Angulo" | "Tapado")
-- blocked(a, b) -> true si algo sólido tapa la línea (asteroide, estación, suelo)
function ShipCombat.canLock(origin: Vector3, look: Vector3, target: Vector3, range: number?, cone: number?, blocked: ((Vector3, Vector3) -> boolean)?): (boolean, string?)
	local to = target - origin
	local dist = to.Magnitude
	if dist > (range or ShipCombat.MissileLock.Range) then
		return false, "Lejos"
	end
	if dist > 1e-3 and math.acos(math.clamp(look.Unit:Dot(to.Unit), -1, 1)) > (cone or ShipCombat.MissileLock.Cone) then
		return false, "Angulo"
	end
	if blocked and blocked(origin, target) then
		return false, "Tapado"
	end
	return true, nil
end

-- El siguiente objetivo al cambiar (Tab / cruceta / botón): ordenados por ángulo desde el morro, dentro
-- del alcance; después de `current` viene el siguiente (y vuelve a empezar)
function ShipCombat.cycle(targets: { { Id: string, Pos: Vector3 } }, current: string?, origin: Vector3, look: Vector3, range: number): string?
	local list = {}
	for _, t in targets do
		local to = t.Pos - origin
		if to.Magnitude <= range and to.Magnitude > 1 then
			table.insert(list, { Id = t.Id, A = math.acos(math.clamp(look.Unit:Dot(to.Unit), -1, 1)) })
		end
	end
	if #list == 0 then
		return nil
	end
	table.sort(list, function(a, b)
		return a.A < b.A
	end)
	for i, t in list do
		if t.Id == current then
			return list[i % #list + 1].Id
		end
	end
	return list[1].Id
end

-- Datos de un enemigo para el HUD (categoría, nivel y salud)
ShipCombat.Categories = { Dron = "Dron", Caza = "Caza enemigo", Torreta = "Torreta" }
ShipCombat.Threat = { Dron = "BAJA", Caza = "ALTA", Torreta = "MEDIA" }

-- Misiles de los cazas enemigos (mismas reglas: alcance, ángulo, línea de visión; se esquivan)
ShipCombat.EnemyMissile = { Damage = 22, Speed = 230, Accel = 200, Turn = 1.9, Life = 7, HitRadius = 5, Range = 900, Cone = math.rad(25), Cooldown = 9, Max = 6 }

-- Un paso de un misil enemigo hacia `target` (o el señuelo): gira como mucho Turn·dt
function ShipCombat.steer(m: { [string]: any }, target: Vector3, dt: number, spec: { [string]: number }?)
	local S = spec or ShipCombat.EnemyMissile
	local want = target - m.Pos
	if want.Magnitude > 1e-3 then
		want = want.Unit
		local angle = math.acos(math.clamp(m.Dir:Dot(want), -1, 1))
		local maxTurn = S.Turn * dt
		if angle <= maxTurn or angle < 1e-4 then
			m.Dir = want
		else
			local k = maxTurn / angle
			m.Dir = (m.Dir * (1 - k) + want * k).Unit
		end
	end
	m.Speed = math.min(S.Speed, m.Speed + S.Accel * dt)
	local from = m.Pos
	m.Pos = m.Pos + m.Dir * m.Speed * dt
	return from
end

-- Amenaza: el misil más cercano que viene hacia ti -> (dirección desde la nave, distancia) o nil
function ShipCombat.incoming(shipPos: Vector3, missiles: { { Pos: Vector3 } }): (Vector3?, number?)
	local best, bestD = nil, math.huge
	for _, m in missiles do
		local d = (m.Pos - shipPos).Magnitude
		if d < bestD then
			best, bestD = m, d
		end
	end
	if not best then
		return nil, nil
	end
	local dir = best.Pos - shipPos
	return if dir.Magnitude > 1e-3 then dir.Unit else Vector3.new(0, 0, -1), bestD
end

---------------------------------------------------------------------
-- Contramedidas (bengalas)
---------------------------------------------------------------------
ShipCombat.Flares = { Charges = 4, Cooldown = 2.5, Regen = 12, Radius = 700, TooClose = 35, DecoySeconds = 3 }

export type FlareState = { Charges: number, Max: number, NextAt: number, RegenAt: number }

function ShipCombat.newFlares(bonus: number?): FlareState
	local max = ShipCombat.Flares.Charges + (bonus or 0)
	return { Charges = max, Max = max, NextAt = 0, RegenAt = 0 }
end

function ShipCombat.flareTick(f: FlareState, now: number)
	if f.Charges < f.Max then
		if f.RegenAt <= 0 then
			f.RegenAt = now + ShipCombat.Flares.Regen
		elseif now >= f.RegenAt then
			f.Charges += 1
			f.RegenAt = if f.Charges < f.Max then now + ShipCombat.Flares.Regen else 0
		end
	else
		f.RegenAt = 0
	end
end

-- Soltar bengalas: -> ok, motivo
function ShipCombat.flare(f: FlareState, now: number): (boolean, string?)
	if now < f.NextAt then
		return false, "Recarga"
	end
	if f.Charges <= 0 then
		return false, "SinCargas"
	end
	f.Charges -= 1
	f.NextAt = now + ShipCombat.Flares.Cooldown
	if f.RegenAt <= 0 then
		f.RegenAt = now + ShipCombat.Flares.Regen
	end
	return true, nil
end

-- Engañar a los misiles que vienen: los que están a menos de Radius (y no encima) se van al señuelo.
-- Devuelve cuántos se han engañado.
function ShipCombat.divert(missiles: { { [string]: any } }, shipPos: Vector3, decoy: Vector3, now: number): number
	local n = 0
	local F = ShipCombat.Flares
	for _, m in missiles do
		local d = (m.Pos - shipPos).Magnitude
		if d <= F.Radius and d > F.TooClose and not m.Decoy then
			m.Decoy = decoy
			m.DecoyUntil = now + F.DecoySeconds
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------------
-- Sobrecarga del escudo y camuflaje
---------------------------------------------------------------------
ShipCombat.Overload = { Cost = 30, Seconds = 6, Boost = 1.6, Overheat = 5, Cooldown = 20 }
ShipCombat.Cloak = { MinEnergy = 20, Drain = 6, MaxSeconds = 12, Cooldown = 15, Detect = 300, Fade = 0.8 }

-- Lo que ve un enemigo de un piloto camuflado: solo muy cerca
function ShipCombat.detectRange(cloaked: boolean): number
	return if cloaked then ShipCombat.Cloak.Detect else math.huge
end

-- Transparencia del camuflaje (0..1) a los `t` segundos: sube poco a poco (para los demás, casi
-- invisible; para ti, a medias para que sigas viendo tu nave)
function ShipCombat.cloakAlpha(t: number, own: boolean): number
	local k = math.clamp(t / ShipCombat.Cloak.Fade, 0, 1)
	return k * (if own then 0.55 else 0.85)
end

---------------------------------------------------------------------
-- Modos de vuelo: combate, crucero y exploración
---------------------------------------------------------------------
ShipCombat.ModeOrder = { "Combat", "Cruise", "Explore" }
ShipCombat.RadarRange = { Combat = 1400, Cruise = 4000, Explore = 6000 }
ShipCombat.Scan = { Every = 4, Radius = 3000 }

-- ¿Qué armas en cada modo? (exploración: sin misiles y los cañones a media cadencia)
function ShipCombat.weaponRules(mode: string?): { Missiles: boolean, Rate: number }
	if mode == "Explore" then
		return { Missiles = false, Rate = 0.5 }
	end
	return { Missiles = true, Rate = 1 }
end

function ShipCombat.nextMode(mode: string?): string
	local i = table.find(ShipCombat.ModeOrder, mode or "Combat") or 1
	return ShipCombat.ModeOrder[i % #ShipCombat.ModeOrder + 1]
end

---------------------------------------------------------------------
-- Drones
---------------------------------------------------------------------
export type DroneKind = { Id: string, Name: string, Cost: number, Seconds: number, Cooldown: number, Hp: number, Range: number, Price: { Chispas: number, Money: number }, Color: Color3 }

ShipCombat.Drones = {
	Exploracion = { Id = "Exploracion", Name = "Dron explorador", Cost = 20, Seconds = 40, Cooldown = 20, Hp = 30, Range = 400, Price = { Chispas = 6, Money = 300 }, Color = Color3.fromRGB(120, 220, 255), Scan = 2500 },
	Defensa = { Id = "Defensa", Name = "Dron de defensa", Cost = 25, Seconds = 30, Cooldown = 25, Hp = 50, Range = 400, Price = { Chispas = 10, Money = 600 }, Color = Color3.fromRGB(120, 255, 170), Intercept = 70, Every = 0.6 },
	Reparacion = { Id = "Reparacion", Name = "Dron de reparación", Cost = 25, Seconds = 25, Cooldown = 30, Hp = 35, Range = 400, Price = { Chispas = 12, Money = 700 }, Color = Color3.fromRGB(255, 220, 120), Heal = 3 },
	Combate = { Id = "Combate", Name = "Dron de combate", Cost = 30, Seconds = 30, Cooldown = 30, Hp = 40, Range = 400, Price = { Chispas = 15, Money = 900 }, Color = Color3.fromRGB(255, 120, 90), Reach = 500, Damage = 5, Every = 0.6 },
}
ShipCombat.DroneOrder = { "Exploracion", "Defensa", "Reparacion", "Combate" }

-- Dónde va el dron: dando vueltas alrededor de la nave, a la vista
function ShipCombat.droneOrbit(owner: CFrame, t: number): Vector3
	local a = t * 1.3
	return owner.Position + owner.RightVector * math.cos(a) * 22 + owner.UpVector * (8 + math.sin(a * 0.7) * 3) - owner.LookVector * (6 + math.sin(a) * 10)
end

-- ¿Puede sacar este dron? -> ok, motivo
function ShipCombat.canDeploy(unlocked: { [string]: any }?, kind: string?, energy: number, cooldown: number, active: boolean): (boolean, string?)
	local def = kind and ShipCombat.Drones[kind]
	if not def then
		return false, "SinDron"
	end
	if not (unlocked and unlocked[kind]) then
		return false, "SinDron"
	end
	if active then
		return false, "Ocupada"
	end
	if cooldown > 0 then
		return false, "Recarga"
	end
	if energy < def.Cost then
		return false, "Energia"
	end
	return true, nil
end

---------------------------------------------------------------------
-- Mejoras de la nave (tienda de las estaciones) y precios
---------------------------------------------------------------------
ShipCombat.Upgrades = {
	Blindaje = { Name = "Blindaje", Levels = 3, Per = 20, Text = "+20 de casco", Money = 800, Chispas = 4 },
	Baterias = { Name = "Baterías", Levels = 3, Per = 15, Text = "+15 de energía", Money = 700, Chispas = 4 },
	Bengalas = { Name = "Lanzabengalas", Levels = 2, Per = 1, Text = "+1 bengala", Money = 500, Chispas = 3 },
}
ShipCombat.UpgradeOrder = { "Blindaje", "Baterias", "Bengalas" }

-- Precio del siguiente nivel (o nil si ya está al máximo)
function ShipCombat.upgradePrice(id: string, level: number): { Money: number, Chispas: number }?
	local u = ShipCombat.Upgrades[id]
	if not u or level >= u.Levels then
		return nil
	end
	local n = level + 1
	return { Money = u.Money * n, Chispas = u.Chispas * n }
end

-- Lo que dan las mejoras compradas: { Hull, Energy, Flares }
function ShipCombat.bonuses(levels: { [string]: any }?): { Hull: number, Energy: number, Flares: number }
	local l = levels or {}
	local function lv(id: string): number
		local u = ShipCombat.Upgrades[id]
		return math.clamp(math.floor(tonumber(l[id]) or 0), 0, u.Levels) * u.Per
	end
	return { Hull = lv("Blindaje"), Energy = lv("Baterias"), Flares = lv("Bengalas") }
end

ShipCombat.Reasons = {
	SinCargas = "Sin bengalas: se reponen solas",
	SinDron = "No tienes ese dron: desbloquéalo en la tienda de una estación",
	Exploracion = "En modo exploración no hay misiles",
	Tapado = "Algo tapa al objetivo",
	Lejos = "Objetivo demasiado lejos",
	Angulo = "Objetivo fuera del cono",
}

return ShipCombat
