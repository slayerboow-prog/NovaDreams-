-- Crossing: los peatones y los pasos de cebra, en cuentas puras (se prueban fuera de Roblox en
-- scripts/test-lights.luau y scripts/test-wanted.luau). Lo usan:
--   * los peatones de la calle (client/Controllers/Ambient): cuándo pueden empezar a cruzar y a qué
--     paso cruzan;
--   * los personajes del servidor que andan (World/RoadGuard: Npc.walkTo y las escenas): no bajan a
--     la calzada si viene un vehículo o el semáforo no les deja;
--   * KnockService (servidor): si atropellar a alguien es culpa de quien conduce (delito) o un
--     accidente (el peatón cruzaba en rojo o por donde no debía).
--
-- Reglas de los peatones:
--   * Solo cruzan por los pasos de cebra de los cruces (siguiendo recta su acera), nunca a mitad de
--     calle.
--   * Con semáforo: esperan en el bordillo mientras los coches de la calle que cruzan tengan verde o
--     ámbar; empiezan solo con el verde de su eje (TrafficSignals.walk) y si les da tiempo a llegar
--     al otro lado (no en los últimos segundos). Si la luz cambia mientras cruzan, aprietan el paso;
--     nunca se paran en medio.
--   * Sin semáforo: miran a los dos lados y solo cruzan si ningún vehículo (tampoco el tuyo) llega al
--     paso antes de que les dé tiempo a cruzar con margen (Crossing.gapClear).
--
-- Quién tiene la culpa de un atropello (Crossing.fault / Crossing.judge, siempre con lo que sabe el
-- servidor: la posición, la hora del servidor —la misma de los semáforos— y la velocidad del coche):
--   * en la acera (o el coche fuera de la calzada): culpa de quien conduce;
--   * a más de Crossing.Reckless veces el límite de la calle: culpa de quien conduce;
--   * en un paso de cebra con semáforo mientras los peatones tienen paso: culpa de quien conduce;
--   * saltarse un rojo (más allá de lo que tarda en cruzar quien entró con ámbar): culpa suya;
--   * en un paso de cebra sin semáforo: el peatón tiene preferencia (culpa de quien conduce);
--   * el peatón cruzaba en rojo o por mitad de la calle, y tú con verde (o ámbar) y a velocidad
--     normal: accidente, no es delito.

local TrafficSignals = require(script.Parent.TrafficSignals)

local Crossing = {}

-- Peatones
Crossing.MinStart = 4 -- no empiezan a cruzar si a su verde le queda menos que esto (s)
Crossing.Safety = 1 -- margen al calcular si les da tiempo a cruzar (s)
Crossing.Gap = 2.5 -- sin semáforo: segundos de margen sobre lo que tardan en cruzar
Crossing.Near = 10 -- un vehículo a menos de esto del paso (a lo largo de la calle) siempre es "viene"
Crossing.HurryMax = 14 -- lo más deprisa que corre alguien que acaba de cruzar (studs/s)
Crossing.HurryFactor = 1.5 -- si la luz cambia mientras cruza, al menos esto más rápido

-- Culpa
Crossing.AmberGrace = 2.5 -- s de rojo en que quien entró con ámbar aún está saliendo del cruce
Crossing.Reckless = 1.5 -- más de esto por el límite de la calle: conducción temeraria
Crossing.Limits = { Calle = 40, Avenida = 48, Autovia = 72 } -- límites (studs/s) por tipo de calle
Crossing.DefaultLimit = 40
Crossing.Latency = 0.6 -- lo más atrás que el servidor acepta la hora del golpe que dice el cliente (s)

local HALF = TrafficSignals.GREEN + TrafficSignals.YELLOW + TrafficSignals.ALL_RED

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

---------------------------------------------------------------------
-- Semáforos para peatones
---------------------------------------------------------------------

-- Fase del eje (0..CYCLE): 0 = empieza su verde
local function phase(axis: string, now: number): number
	local t = now % TrafficSignals.CYCLE
	if axis ~= "X" then
		t = (t - HALF) % TrafficSignals.CYCLE
	end
	return t
end
Crossing.phase = phase

local function other(axis: string): string
	return if axis == "X" then "Z" else "X"
end
Crossing.other = other

-- Segundos que les quedan a los coches de la calle que cruza un peatón que anda a lo largo de
-- pedAxis antes de tener verde (0 si ya lo tienen o están en verde/ámbar). Mientras sea > 0, el
-- peatón que va por el paso está protegido: los coches de esa calle tienen rojo.
function Crossing.clearLeft(pedAxis: string, now: number): number
	local t = phase(pedAxis, now)
	return if t < HALF then HALF - t else 0
end

-- ¿Tienen paso los peatones que andan a lo largo de pedAxis? (los coches de la calle que cruzan,
-- en rojo: el verde de su eje, su ámbar y el rojo de los dos)
function Crossing.pedProtected(pedAxis: string, now: number): boolean
	return Crossing.clearLeft(pedAxis, now) > 0
end

-- Segundos desde que se puso en rojo el semáforo de quien circula a lo largo del eje (0 si no está
-- en rojo)
function Crossing.sinceRed(axis: string, now: number): number
	local t = phase(axis, now)
	local red = TrafficSignals.GREEN + TrafficSignals.YELLOW
	return if t >= red then t - red else 0
end

-- ¿Puede EMPEZAR a cruzar en un cruce con semáforo quien anda a lo largo de pedAxis y tarda need
-- segundos en llegar al otro lado? Con su verde (TrafficSignals.walk), sin ser los últimos segundos,
-- y si le da tiempo antes de que acabe su ámbar (con margen).
function Crossing.signalStart(pedAxis: string, now: number, need: number): boolean
	local state, left = TrafficSignals.state(pedAxis, now)
	if state ~= "Green" or left < Crossing.MinStart or not TrafficSignals.walk(pedAxis, now) then
		return false
	end
	return need + Crossing.Safety <= left + TrafficSignals.YELLOW
end

---------------------------------------------------------------------
-- Sin semáforo: mirar a los dos lados
---------------------------------------------------------------------

export type Mover = { Pos: Vector3, Vel: Vector3 }

-- ¿Llega algún vehículo al paso (de p0 a p1, de bordillo a bordillo) antes de need + Gap segundos?
-- Mira a los dos lados: los que se acercan por cualquier sentido de la calle. Uno parado justo en
-- el paso también cuenta. Devuelve si está despejado y, si no, en cuántos segundos llega el primero.
function Crossing.gapClear(p0: Vector3, p1: Vector3, need: number, vehicles: { Mover }): (boolean, number)
	local across = flat(p1 - p0)
	local width = across.Magnitude
	if width < 0.1 then
		return true, math.huge
	end
	across = across.Unit
	local along = Vector3.new(-across.Z, 0, across.X) -- (a lo largo de la calle)
	local mid = flat(p0 + p1) / 2
	local first = math.huge
	for _, v in vehicles do
		local rel = flat(v.Pos) - mid
		local off = rel:Dot(across)
		if math.abs(off) <= width / 2 + 8 then
			local dist = rel:Dot(along) -- (+: de un lado, -: del otro)
			local toward = -flat(v.Vel):Dot(along) * (if dist >= 0 then 1 else -1)
			local d = math.abs(dist)
			local moving = flat(v.Vel).Magnitude > 0.5
			-- (encima del paso, o pegado y en marcha: ya está aquí; uno parado esperando no cuenta)
			local eta = if d < 4 or (d < Crossing.Near and moving) then 0 elseif toward > 0.5 then d / toward else math.huge
			first = math.min(first, eta)
		end
	end
	return first > need + Crossing.Gap, first
end

-- A qué paso cruza quien ya está en la calzada (nunca se para en medio):
--   base: su paso normal; remaining: lo que le queda hasta el otro bordillo;
--   signalled y pedAxis: si el paso tiene semáforo y por qué eje anda; threat: sin semáforo, en
--   cuántos segundos llega el vehículo más cercano (math.huge si no viene ninguno).
function Crossing.pace(base: number, remaining: number, signalled: boolean, pedAxis: string?, now: number, threat: number?): number
	local pace = base
	if signalled and pedAxis then
		local state = TrafficSignals.state(pedAxis, now)
		if state ~= "Green" then
			pace = base * Crossing.HurryFactor -- (la luz ha cambiado: aprieta el paso)
		end
		local budget = Crossing.clearLeft(pedAxis, now) - 0.5
		pace = math.max(pace, remaining / math.max(budget, 0.4))
	elseif threat and threat < remaining / math.max(base, 0.1) + Crossing.Gap then
		pace = base * Crossing.HurryFactor -- (viene alguien: deprisa)
	end
	return math.clamp(pace, base, math.max(base, Crossing.HurryMax))
end

---------------------------------------------------------------------
-- Calles: dónde está cada cosa (acera, paso de cebra o calzada)
---------------------------------------------------------------------

export type Road = { A: Vector3, Dir: Vector3, Perp: Vector3, Len: number, Half: number, WalkIn: number?, WalkOut: number?, Kind: string?, Axis: string? }
export type World = { Roads: { Road }, Signals: TrafficSignals.Index, Rings: { Vector3 } }

-- El mundo de calles, con tablas sencillas ({ A, B, Width, Kind, WalkIn, WalkOut, Axis, At, From, To })
-- rings: centros de las rotondas (sus cruces no llevan semáforo)
function Crossing.world(list: { { [string]: any } }, rings: { Vector3 }?): World
	local roads: { Road } = {}
	local grid: { TrafficSignals.Road } = {}
	for _, r in list do
		local a, b = r.A, r.B
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" and flat(b - a).Magnitude > 1 then
			local dir = flat(b - a).Unit
			table.insert(roads, {
				A = flat(a),
				Dir = dir,
				Perp = Vector3.new(-dir.Z, 0, dir.X),
				Len = flat(b - a).Magnitude,
				Half = (r.Width or 24) / 2,
				WalkIn = r.WalkIn,
				WalkOut = r.WalkOut,
				Kind = r.Kind,
				Axis = r.Axis,
			})
		end
		if (r.Axis == "X" or r.Axis == "Z") and type(r.At) == "number" and type(r.From) == "number" and type(r.To) == "number" then
			table.insert(grid, { Axis = r.Axis, At = r.At, From = r.From, To = r.To })
		end
	end
	local signals: { Vector3 } = {}
	for _, c in TrafficSignals.intersections(grid) do
		local nearRing = false
		for _, ring in rings or {} do
			if flat(c - ring).Magnitude < 70 then
				nearRing = true
				break
			end
		end
		if not nearRing then
			table.insert(signals, c)
		end
	end
	return { Roads = roads, Signals = TrafficSignals.index(signals), Rings = rings or {} }
end

-- Lo mismo, con las calles publicadas (ReplicatedStorage.Ambient.Roads)
function Crossing.fromFolder(folder: Instance, rings: { Vector3 }?): World
	local list = {}
	for _, config in folder:GetChildren() do
		table.insert(list, {
			A = config:GetAttribute("A"),
			B = config:GetAttribute("B"),
			Width = config:GetAttribute("Width"),
			Kind = config:GetAttribute("Kind"),
			WalkIn = config:GetAttribute("WalkIn"),
			WalkOut = config:GetAttribute("WalkOut"),
			Axis = config:GetAttribute("Axis"),
			At = config:GetAttribute("At"),
			From = config:GetAttribute("From"),
			To = config:GetAttribute("To"),
		})
	end
	return Crossing.world(list, rings)
end

export type Zone = {
	Zone: string, -- "Sidewalk" (acera o fuera de la calzada), "Crosswalk" (paso de cebra) o "Road" (calzada)
	Road: Road?, -- la calle de cuya calzada se trata
	Signalled: boolean, -- paso (o cruce) con semáforo
	Junction: Vector3?, -- el cruce con semáforo
	DriverAxis: string?, -- eje de los coches de esa calzada
	PedAxis: string?, -- eje por el que anda quien cruza por ese paso
}

local function axisOfRoad(road: Road): string
	return road.Axis or TrafficSignals.axisOf(road.Dir)
end

-- ¿Dónde está p? (acera, paso de cebra o calzada a mitad de calle / en medio del cruce)
function Crossing.zone(world: World, p: Vector3): Zone
	local q = flat(p)
	local onRoad: Road? = nil
	local best = math.huge
	for _, road in world.Roads do
		local rel = q - road.A
		local u = rel:Dot(road.Dir)
		local v = math.abs(rel:Dot(road.Perp))
		if u >= -0.5 and u <= road.Len + 0.5 and v <= road.Half + 0.3 and v / road.Half < best then
			onRoad, best = road, v / road.Half
		end
	end
	if not onRoad then
		return { Zone = "Sidewalk", Signalled = false }
	end
	local road = onRoad :: Road
	-- ¿Sigue por aquí la acera de alguna calle que corta esta? (eso es el paso de cebra)
	local crossing: Road? = nil
	for _, other in world.Roads do
		if other ~= road and math.abs(other.Dir:Dot(road.Dir)) < 0.5 then
			local walkIn = other.WalkIn
			local walkOut = other.WalkOut
			if walkIn and walkOut and walkOut > walkIn then
				local rel = q - other.A
				local u = rel:Dot(other.Dir)
				local v = math.abs(rel:Dot(other.Perp))
				local reach = road.Half + 3
				if v >= walkIn - 0.5 and v <= walkOut + 1 and u >= -reach and u <= other.Len + reach then
					crossing = other
					break
				end
			end
		end
	end
	local junction = TrafficSignals.near(world.Signals, q, TrafficSignals.BOX + 14)
	local zone: Zone = {
		Zone = if crossing then "Crosswalk" else "Road",
		Road = road,
		Signalled = junction ~= nil,
		Junction = junction,
		DriverAxis = axisOfRoad(road),
		PedAxis = if crossing then axisOfRoad(crossing) else nil,
	}
	return zone
end

-- Límite de velocidad donde está p (por el tipo de calle)
function Crossing.limitAt(world: World, p: Vector3): number
	local z = Crossing.zone(world, p)
	local road = z.Road
	return if road and road.Kind and Crossing.Limits[road.Kind] then Crossing.Limits[road.Kind] else Crossing.DefaultLimit
end

---------------------------------------------------------------------
-- ¿De quién es la culpa?
---------------------------------------------------------------------

export type Context = {
	Zone: string, -- "Sidewalk", "Crosswalk" o "Road" (donde estaba el peatón)
	CarOffRoad: boolean?, -- el coche iba fuera de la calzada (por la acera)
	Signalled: boolean, -- cerca de un cruce con semáforo
	DriverAxis: string?, -- eje por el que iba el coche (el de la calzada en un paso de cebra)
	PedAxis: string?, -- eje por el que anda quien cruza el paso
	Now: number, -- hora del servidor del golpe
	Speed: number, -- velocidad del coche (studs/s)
	Limit: number, -- límite de la calle
}

-- Devuelve si es culpa de quien conduce (delito de atropello) y por qué:
--   "Sidewalk", "Speeding", "Walk" (paso de cebra con los peatones con paso), "RedLight", "Zebra"
--   (paso sin semáforo), o sin culpa: "Jaywalk" (cruzaba en rojo o a mitad de calle), "Amber".
function Crossing.fault(ctx: Context): (boolean, string)
	if ctx.Zone == "Sidewalk" or ctx.CarOffRoad then
		return true, "Sidewalk"
	end
	if ctx.Speed > ctx.Limit * Crossing.Reckless then
		return true, "Speeding"
	end
	if ctx.Signalled and ctx.DriverAxis then
		local state = TrafficSignals.state(ctx.DriverAxis, ctx.Now)
		if state == "Red" then
			if ctx.Zone == "Crosswalk" and ctx.PedAxis and ctx.PedAxis ~= ctx.DriverAxis and Crossing.pedProtected(ctx.PedAxis, ctx.Now) then
				return true, "Walk"
			end
			if Crossing.sinceRed(ctx.DriverAxis, ctx.Now) > Crossing.AmberGrace then
				return true, "RedLight"
			end
			return false, "Amber"
		end
		return false, "Jaywalk"
	end
	if ctx.Zone == "Crosswalk" then
		return true, "Zebra"
	end
	return false, "Jaywalk"
end

export type Claim = { Ped: string?, Signal: string?, At: number? }
export type Verdict = {
	Fault: boolean,
	Reason: string,
	Zone: string,
	Signal: string, -- el semáforo de quien conduce según el servidor ("Green", "Yellow", "Red" o "None")
	PedWalk: boolean, -- los peatones de ese paso tenían paso (según el servidor)
	Rejected: boolean, -- lo que dice el cliente no cuadra con lo que ve el servidor
	At: number, -- hora del golpe con la que se ha juzgado
}

-- El juicio del servidor: ped = dónde estaba el peatón, carPos y carVel = el coche según el
-- servidor, now = hora del servidor al llegar el aviso, claim = lo que dice el cliente (estado del
-- peatón "OnSidewalk"/"OnCrosswalk"/"Jaywalk", su semáforo y la hora del golpe). Del cliente solo se
-- acepta la hora (y como mucho Crossing.Latency hacia atrás): todo lo demás lo calcula el servidor.
function Crossing.judge(world: World, ped: Vector3, carPos: Vector3, carVel: Vector3, now: number, claim: Claim?): Verdict
	local at = now
	if claim and type(claim.At) == "number" and claim.At == claim.At and claim.At <= now and claim.At >= now - Crossing.Latency then
		at = claim.At
	end
	local z = Crossing.zone(world, ped)
	local car = Crossing.zone(world, carPos)
	local speed = flat(carVel).Magnitude
	local driverAxis = if z.Zone == "Crosswalk" then z.DriverAxis elseif speed > 1 then TrafficSignals.axisOf(flat(carVel)) else z.DriverAxis
	local ctx: Context = {
		Zone = z.Zone,
		CarOffRoad = car.Zone == "Sidewalk",
		Signalled = z.Signalled,
		DriverAxis = driverAxis,
		PedAxis = z.PedAxis,
		Now = at,
		Speed = speed,
		Limit = Crossing.limitAt(world, if z.Road then ped else carPos),
	}
	local fault, reason = Crossing.fault(ctx)
	local signal = if z.Signalled and driverAxis then (TrafficSignals.state(driverAxis, at)) else "None"
	local pedWalk = z.Zone == "Crosswalk" and (not z.Signalled or (z.PedAxis ~= nil and Crossing.pedProtected(z.PedAxis :: string, at)))
	-- Lo que dice el cliente, comparado con lo que ve el servidor
	local rejected = false
	if claim then
		if claim.Ped == "Jaywalk" and (z.Zone == "Sidewalk" or ctx.CarOffRoad or pedWalk) then
			rejected = true -- dice que cruzaba mal, pero estaba en la acera o tenía paso
		elseif claim.Ped == "OnSidewalk" and z.Zone ~= "Sidewalk" and not ctx.CarOffRoad then
			rejected = true
		end
		if claim.Signal and claim.Signal ~= signal and not (signal == "None" or claim.Signal == "None") then
			-- (justo en el cambio de luz se perdona la diferencia de un instante)
			local before = if driverAxis then (TrafficSignals.state(driverAxis, at - Crossing.Latency)) else signal
			local after = if driverAxis then (TrafficSignals.state(driverAxis, at + Crossing.Latency)) else signal
			if claim.Signal ~= before and claim.Signal ~= after then
				rejected = true
			end
		end
	end
	return { Fault = fault, Reason = reason, Zone = z.Zone, Signal = signal, PedWalk = pedWalk, Rejected = rejected, At = at }
end

---------------------------------------------------------------------
-- Personajes que andan (servidor): ¿un tramo baja a la calzada?
---------------------------------------------------------------------

export type Leg = { Entry: Vector3, Exit: Vector3, Zone: Zone }

-- Si el tramo de from a to pasa por una calzada empezando fuera de ella, dónde entra y dónde sale
-- (cada `stepLen` studs). nil si no pisa ninguna calzada o ya está dentro (que siga).
function Crossing.legAcross(world: World, from: Vector3, to: Vector3, stepLen: number?): Leg?
	local d = flat(to - from)
	local len = d.Magnitude
	if len < 0.5 then
		return nil
	end
	if Crossing.zone(world, from).Zone ~= "Sidewalk" then
		return nil -- (ya está en la calzada: que salga)
	end
	local step = stepLen or 2
	local n = math.ceil(len / step)
	local entry: Vector3? = nil
	local entryZone: Zone? = nil
	local exit: Vector3? = nil
	for i = 1, n do
		local p = from + d * (i / n)
		local z = Crossing.zone(world, p)
		if z.Zone ~= "Sidewalk" then
			if not entry then
				entry, entryZone = p, z
			end
		elseif entry then
			exit = p
			break
		end
	end
	if not entry then
		return nil
	end
	return { Entry = entry :: Vector3, Exit = exit or Vector3.new(to.X, from.Y, to.Z), Zone = entryZone :: Zone }
end

-- ¿Tiene que esperar en el bordillo quien va a hacer ese tramo a `speed`? (semáforo de su eje en un
-- cruce con semáforo, o un vehículo que llega sin semáforo)
function Crossing.mustWait(world: World, from: Vector3, to: Vector3, speed: number, now: number, vehicles: { Mover }): boolean
	local leg = Crossing.legAcross(world, from, to)
	if not leg then
		return false
	end
	local need = flat(leg.Exit - from).Magnitude / math.max(speed, 1)
	local z = leg.Zone
	if z.Signalled then
		local pedAxis = z.PedAxis or TrafficSignals.axisOf(flat(to - from))
		if not Crossing.signalStart(pedAxis, now, need) then
			return true
		end
	end
	local clear = Crossing.gapClear(leg.Entry, leg.Exit, need, vehicles)
	return not clear
end

return Crossing
