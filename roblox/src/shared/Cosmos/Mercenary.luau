-- Mercenary: las cuentas del trabajo de MERCENARIO (docs/universo/diseno-espacio.md §1.4 bis; cuentas puras).
-- Lo usan Services/SpaceJobService (servidor: mueve los cargueros, pone a los piratas, cobra) y
-- scripts/test-spacejobs.luau.
--
--   * ESCOLTA DE CONVOY: N cargueros de verdad (modelos que se mueven) salen del muelle de una estación
--     hacia el de otra, en fila, a Speed (más despacio que tu nave). Si te alejas más de HoldDistance, el
--     convoy ESPERA (no le dejas solo); si tardas más de HoldMax en volver, el contrato falla. En dos
--     puntos de la ruta (Ambushes) les salen piratas, que dañan al carguero más cercano mientras estén a
--     menos de AttackRange (cada tipo con su daño por segundo). Llegar con Required o más cargueros
--     vivos = cumplido (paga según cuántos llegan).
--   * DEFENSA DE ESTACIÓN: al acercarte a la estación (StartRange) empiezan 3 oleadas de piratas por
--     fuera de la zona segura; mientras estén a menos de AttackRange, la integridad de la estación baja.
--     Limpiar las 3 = cumplido; integridad a 0 o irte demasiado tiempo = fallado.
-- Topes para el móvil: como mucho MaxPirates vivos por contrato y una Pesada por oleada.

local Stations = require(script.Parent.Stations)

local Mercenary = {}

Mercenary.Speed = 70 -- studs/s de los cargueros (la nave va a 45–210)
Mercenary.Spacing = 55 -- distancia entre cargueros
Mercenary.StartRange = 1500 -- a esta distancia del muelle de salida, el convoy arranca
Mercenary.HoldDistance = 1600 -- más lejos, el convoy espera
Mercenary.HoldMax = 60 -- s esperando antes de fallar
Mercenary.AttackRange = 700 -- los piratas dañan a menos de esto
Mercenary.ShipHull = 100
Mercenary.Dps = { Dron = 1, Caza = 2, Interceptor = 1.6, Aguja = 1.6, Pesada = 4.5 }
Mercenary.Ambushes = { 0.3, 0.65 }
Mercenary.MaxPirates = 5

-- Defensa
Mercenary.DefenseStart = 2500
Mercenary.DefenseRing = 950 -- (fuera de la zona segura de 520)
Mercenary.DefenseAttack = 1100
Mercenary.DefenseLeave = 3500 -- más lejos que esto cuenta como irse
Mercenary.WaveGap = 8
Mercenary.Integrity = 100
Mercenary.IntegrityDps = 0.35 -- por pirata y por segundo (× su daño relativo)

Mercenary.Levels = {
	{ Ships = 2, Required = 1, Ambush = { "Interceptor", "Interceptor" }, Waves = { { "Interceptor", "Dron", "Dron" }, { "Interceptor", "Interceptor", "Dron" }, { "Pesada", "Interceptor", "Interceptor" } } },
	{ Ships = 3, Required = 2, Ambush = { "Interceptor", "Interceptor", "Pesada" }, Waves = { { "Interceptor", "Interceptor", "Dron" }, { "Interceptor", "Interceptor", "Interceptor", "Dron" }, { "Pesada", "Interceptor", "Interceptor", "Interceptor" } } },
}

local function level(n: number?): { [string]: any }
	return Mercenary.Levels[math.clamp(math.floor(tonumber(n) or 1), 1, #Mercenary.Levels)]
end
Mercenary.level = level

-- Lo que sale (con los topes: como mucho una Pesada y MaxPirates en total)
function Mercenary.capGroup(group: { string }, alive: number): { string }
	local out, heavy = {}, false
	for _, k in group do
		if #out + alive >= Mercenary.MaxPirates then
			break
		end
		if k == "Pesada" then
			if heavy then
				continue
			end
			heavy = true
		end
		table.insert(out, k)
	end
	return out
end

---------------------------------------------------------------------
-- Convoy
---------------------------------------------------------------------
export type Route = { Start: Vector3, End: Vector3, Dir: Vector3, Length: number }

function Mercenary.route(from: string, to: string): Route?
	local a, b = Stations.ById[from], Stations.ById[to]
	if not a or not b or a == b then
		return nil
	end
	local start = Stations.launch(a).Position
	local finish = b.Dock
	local d = finish - start
	return { Start = start, End = finish, Dir = d.Unit, Length = d.Magnitude }
end

-- Dónde está el carguero i (1 = el primero) con el convoy en la distancia D
function Mercenary.shipPos(route: Route, d: number, i: number): Vector3
	local along = math.clamp(d - (i - 1) * Mercenary.Spacing, 0, route.Length)
	local side = route.Dir:Cross(Vector3.new(0, 1, 0))
	side = if side.Magnitude > 1e-3 then side.Unit else Vector3.new(1, 0, 0)
	local lateral = if i == 1 then 0 elseif i % 2 == 0 then 18 else -18
	return route.Start + route.Dir * along + side * lateral
end

export type Convoy = { D: number, Hull: { number }, Ambush: number, Held: number, Holding: boolean, Done: boolean }

function Mercenary.newConvoy(lvl: number?): Convoy
	local L = level(lvl)
	local hull = {}
	for i = 1, L.Ships do
		hull[i] = Mercenary.ShipHull
	end
	return { D = 0, Hull = hull, Ambush = 0, Held = 0, Holding = false, Done = false }
end

function Mercenary.alive(c: Convoy): number
	local n = 0
	for _, h in c.Hull do
		if h > 0 then
			n += 1
		end
	end
	return n
end

-- Un paso del convoy. escort = dónde está tu nave (nil = no estás: derribado o fuera de la nave).
-- pirates = { { Pos, Kind } } vivos de este contrato. Devuelve los sucesos:
--   { Type = "Ambush", Index } · { Type = "Hold" } · { Type = "Resume" } · { Type = "Lost", Ship } ·
--   { Type = "Arrived", Alive } · { Type = "Failed", Why = "Abandoned" | "Destroyed" }
function Mercenary.stepConvoy(c: Convoy, route: Route, lvl: number?, dt: number, escort: Vector3?, pirates: { { Pos: Vector3, Kind: string } }): { { [string]: any } }
	local events = {}
	if c.Done then
		return events
	end
	-- Daño de los piratas: cada uno al carguero vivo más cercano a su alcance
	for _, p in pirates do
		local best, bestD = nil, Mercenary.AttackRange
		for i, h in c.Hull do
			if h > 0 then
				local dist = (Mercenary.shipPos(route, c.D, i) - p.Pos).Magnitude
				if dist <= bestD then
					best, bestD = i, dist
				end
			end
		end
		if best then
			c.Hull[best] = math.max(0, c.Hull[best] - (Mercenary.Dps[p.Kind] or 1) * dt)
			if c.Hull[best] <= 0 then
				table.insert(events, { Type = "Lost", Ship = best })
			end
		end
	end
	if Mercenary.alive(c) == 0 then
		c.Done = true
		table.insert(events, { Type = "Failed", Why = "Destroyed" })
		return events
	end
	-- ¿Está la escolta? Si no, espera
	local lead = Mercenary.shipPos(route, c.D, 1)
	local present = escort ~= nil and (escort - lead).Magnitude <= Mercenary.HoldDistance
	if not present then
		if not c.Holding then
			c.Holding = true
			table.insert(events, { Type = "Hold" })
		end
		c.Held += dt
		if c.Held > Mercenary.HoldMax then
			c.Done = true
			table.insert(events, { Type = "Failed", Why = "Abandoned" })
		end
		return events
	end
	if c.Holding then
		c.Holding = false
		table.insert(events, { Type = "Resume" })
	end
	c.Held = 0
	-- (con piratas cerca, el convoy no se para: hay que defenderlo en marcha)
	c.D += Mercenary.Speed * dt
	local nextAmbush = Mercenary.Ambushes[c.Ambush + 1]
	if nextAmbush and c.D >= route.Length * nextAmbush then
		c.Ambush += 1
		table.insert(events, { Type = "Ambush", Index = c.Ambush })
	end
	-- Llega cuando el último vivo está en el muelle
	local last = 0
	for i, h in c.Hull do
		if h > 0 then
			last = i
		end
	end
	if c.D - (last - 1) * Mercenary.Spacing >= route.Length then
		c.Done = true
		table.insert(events, { Type = "Arrived", Alive = Mercenary.alive(c) })
	end
	return events
end

-- Dónde salen los piratas de una emboscada: delante del convoy, en abanico (fuera de la zona segura)
function Mercenary.ambushSpots(route: Route, d: number, count: number): { Vector3 }
	local out = {}
	local ahead = route.Start + route.Dir * math.clamp(d + 600, 0, route.Length)
	local side = route.Dir:Cross(Vector3.new(0, 1, 0))
	side = if side.Magnitude > 1e-3 then side.Unit else Vector3.new(1, 0, 0)
	for i = 1, count do
		local k = i - (count + 1) / 2
		table.insert(out, ahead + side * (k * 140) + Vector3.new(0, 60 + (i % 2) * 50, 0))
	end
	return out
end

---------------------------------------------------------------------
-- Defensa de estación
---------------------------------------------------------------------
export type Defense = { Wave: number, Integrity: number, NextWaveAt: number, Held: number, Done: boolean, Started: boolean }

function Mercenary.newDefense(): Defense
	return { Wave = 0, Integrity = Mercenary.Integrity, NextWaveAt = 0, Held = 0, Done = false, Started = false }
end

-- Dónde sale la oleada n alrededor de la estación (fuera de la zona segura)
function Mercenary.waveSpots(station: string, wave: number, count: number): { Vector3 }
	local s = Stations.ById[station]
	local out = {}
	if not s then
		return out
	end
	local base = wave * 1.9
	for i = 1, count do
		local a = base + (i - 1) * 0.35
		table.insert(out, s.Center + Vector3.new(math.cos(a) * Mercenary.DefenseRing, 80 + (i % 2) * 60, math.sin(a) * Mercenary.DefenseRing))
	end
	return out
end

-- Un paso de la defensa. alive = piratas vivos de este contrato ({ Pos, Kind }); now = reloj.
-- Sucesos: { Type = "Start" } · { Type = "Wave", Index, Group } · { Type = "Hold" } · { Type = "Won" } ·
--   { Type = "Failed", Why = "Destroyed" | "Abandoned" }
function Mercenary.stepDefense(d: Defense, station: string, lvl: number?, dt: number, now: number, escort: Vector3?, alive: { { Pos: Vector3, Kind: string } }): { { [string]: any } }
	local events = {}
	local s = Stations.ById[station]
	if d.Done or not s then
		return events
	end
	local L = level(lvl)
	local dist = if escort then (escort - s.Center).Magnitude else math.huge
	if not d.Started then
		if dist <= Mercenary.DefenseStart then
			d.Started = true
			d.NextWaveAt = now + 3
			table.insert(events, { Type = "Start" })
		end
		return events
	end
	-- Daño a la estación
	for _, p in alive do
		if (p.Pos - s.Center).Magnitude <= Mercenary.DefenseAttack then
			d.Integrity = math.max(0, d.Integrity - Mercenary.IntegrityDps * (Mercenary.Dps[p.Kind] or 1) * dt)
		end
	end
	if d.Integrity <= 0 then
		d.Done = true
		table.insert(events, { Type = "Failed", Why = "Destroyed" })
		return events
	end
	-- ¿Te has ido?
	if dist > Mercenary.DefenseLeave then
		d.Held += dt
		if d.Held > Mercenary.HoldMax then
			d.Done = true
			table.insert(events, { Type = "Failed", Why = "Abandoned" })
		end
		return events
	end
	d.Held = 0
	if #alive > 0 then
		return events
	end
	-- Oleada limpia: la siguiente o se acabó
	if d.Wave >= #L.Waves then
		d.Done = true
		table.insert(events, { Type = "Won" })
		return events
	end
	if now >= d.NextWaveAt then
		d.Wave += 1
		d.NextWaveAt = now + Mercenary.WaveGap
		table.insert(events, { Type = "Wave", Index = d.Wave, Group = Mercenary.capGroup(L.Waves[d.Wave], 0) })
	end
	return events
end

return Mercenary
