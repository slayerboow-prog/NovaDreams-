-- TrafficSignals: los semáforos de la ciudad, en cuentas puras (se prueban fuera de Roblox en
-- scripts/test-lights.luau). Lo usan los coches del tráfico (client/Controllers/Traffic), los
-- peatones (client/Controllers/Ambient, por Traffic.mayCross), los autobuses (BusService) y las
-- patrullas (World/PoliceUnits), así todos ven la misma luz al mismo tiempo.
--
--  * Dónde hay semáforo: en cada cruce de dos calles de la cuadrícula (los mismos cruces que
--    construye Kit/Street, con sus dos semáforos). Se calcula con los datos de las calles (los
--    que se publican en ReplicatedStorage.Ambient.Roads), no buscando los modelos de los
--    semáforos: en el cliente, con StreamingEnabled, casi ninguno está cargado.
--  * Cuándo: un ciclo fijo que sale de la hora del servidor (workspace:GetServerTimeNow()), igual
--    en todos los clientes y en el servidor. Verde, ámbar y luego un momento con los dos ejes en
--    rojo para que se vacíe el cruce; nunca hay verde (ni ámbar) a la vez en las dos calles.
--  * Los peatones cruzan la calle del otro eje cuando su eje está en verde (los coches de la calle
--    que cruzan tienen rojo) y queda tiempo para llegar al otro lado.

local TrafficSignals = {}

-- Fases (segundos). El eje X (calles que van de oeste a este) empieza el ciclo.
local GREEN, YELLOW, ALL_RED = 13, 3, 2
TrafficSignals.GREEN, TrafficSignals.YELLOW, TrafficSignals.ALL_RED = GREEN, YELLOW, ALL_RED
local HALF = GREEN + YELLOW + ALL_RED
local CYCLE = HALF * 2
TrafficSignals.CYCLE = CYCLE

-- Línea de parada: distancia del centro del cruce. La calzada del cruce mide 24 (12 a cada lado)
-- y el paso de cebra llega hasta 20 (Kit/Street: HALF): se para antes del paso de cebra.
TrafficSignals.STOP_LINE = 22
-- Radio del cruce: dentro de esto se está "en el cruce" (calzada y pasos de cebra)
TrafficSignals.BOX = 20
-- Un vehículo "va hacia" un cruce si está en su calle (a menos de esto del eje de la calle)
TrafficSignals.LATERAL = 14
-- Más lejos que esto no se mira el semáforo
TrafficSignals.LOOKAHEAD = 140

-- Eje por el que circula quien va en dirección dir
function TrafficSignals.axisOf(dir: Vector3): string
	return if math.abs(dir.X) > math.abs(dir.Z) then "X" else "Z"
end

-- Estado para quien circula a lo largo del eje ("Green", "Yellow" o "Red") en el instante now
-- (hora del servidor) y cuántos segundos le quedan en verde (0 si no está en verde)
function TrafficSignals.state(axis: string, now: number): (string, number)
	local t = now % CYCLE
	if axis ~= "X" then
		t = (t - HALF) % CYCLE
	end
	if t < GREEN then
		return "Green", GREEN - t
	elseif t < GREEN + YELLOW then
		return "Yellow", 0
	end
	return "Red", 0
end

-- ¿Puede empezar a cruzar un peatón que camina a lo largo del eje? (cruza la calle del otro eje,
-- que está en rojo; y le da tiempo a llegar al otro lado)
function TrafficSignals.walk(axis: string, now: number): boolean
	local state, left = TrafficSignals.state(axis, now)
	return state == "Green" and left > 4
end

-- ¿Le da para parar antes de la línea a esta velocidad? (con ámbar se para si puede hacerlo sin
-- un frenazo; si no, sigue y cruza: el rojo de los dos ejes le deja salir del cruce)
function TrafficSignals.canStop(toLine: number, speed: number, decel: number): boolean
	return toLine >= speed * speed / (2 * decel * 1.4) - 0.5
end

-- ¿Tiene que parar en la línea con este estado? (rojo siempre; ámbar si le da para parar)
function TrafficSignals.mustStop(state: string, toLine: number, speed: number, decel: number): boolean
	if toLine <= -1 then
		return false -- ya ha pasado la línea: sigue y sale del cruce (no se para dentro)
	end
	if state == "Red" then
		return true
	end
	return state == "Yellow" and TrafficSignals.canStop(toLine, speed, decel)
end

---------------------------------------------------------------------
-- Dónde hay semáforos
---------------------------------------------------------------------

export type Road = { Axis: string, At: number, From: number, To: number }

-- Cruces con semáforo de una lista de calles de la cuadrícula ({ Axis, At, From, To }): donde se
-- cortan (o se tocan) una calle en X y otra en Z, con la misma regla que Kit/Street.build
function TrafficSignals.intersections(roads: { Road }): { Vector3 }
	local list: { Vector3 } = {}
	local seen: { [string]: boolean } = {}
	for _, a in roads do
		if a.Axis ~= "X" then
			continue
		end
		for _, b in roads do
			if b.Axis == "Z" and b.At >= a.From and b.At <= a.To and a.At >= b.From and a.At <= b.To then
				local key = math.floor(b.At + 0.5) .. ":" .. math.floor(a.At + 0.5)
				if not seen[key] then
					seen[key] = true
					table.insert(list, Vector3.new(b.At, 0, a.At))
				end
			end
		end
	end
	return list
end

-- Lo mismo, leyendo las calles publicadas (ReplicatedStorage.Ambient.Roads: las calles de la
-- cuadrícula llevan los atributos Axis, At, From y To; las carreteras principales, no)
function TrafficSignals.fromFolder(folder: Instance): { Vector3 }
	local roads: { Road } = {}
	for _, config in folder:GetChildren() do
		local axis, at, from, to = config:GetAttribute("Axis"), config:GetAttribute("At"), config:GetAttribute("From"), config:GetAttribute("To")
		if (axis == "X" or axis == "Z") and type(at) == "number" and type(from) == "number" and type(to) == "number" then
			table.insert(roads, { Axis = axis, At = at, From = from, To = to })
		end
	end
	return TrafficSignals.intersections(roads)
end

---------------------------------------------------------------------
-- Búsqueda rápida de cruces cercanos (rejilla)
---------------------------------------------------------------------

local CELL = 100

export type Index = { Cells: { [string]: { Vector3 } }, List: { Vector3 } }

function TrafficSignals.index(list: { Vector3 }): Index
	local cells: { [string]: { Vector3 } } = {}
	for _, p in list do
		local key = math.floor(p.X / CELL) .. ":" .. math.floor(p.Z / CELL)
		cells[key] = cells[key] or {}
		table.insert(cells[key], p)
	end
	return { Cells = cells, List = list }
end

-- ¿Hay un cruce con semáforo a menos de r de p? (devuelve el más cercano)
function TrafficSignals.near(index: Index, p: Vector3, r: number): Vector3?
	local kx, kz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
	local best, bestD = nil, r
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, c in index.Cells[(kx + dx) .. ":" .. (kz + dz)] or {} do
				local d = Vector3.new(c.X - p.X, 0, c.Z - p.Z).Magnitude
				if d < bestD then
					best, bestD = c, d
				end
			end
		end
	end
	return best
end

-- Espacio hasta donde tiene que parar un vehículo en pos, que va en dirección dir (plana), por los
-- semáforos que tiene delante en su calle: la distancia de su morro a la línea de parada del
-- primer cruce en rojo (o en ámbar, si le da para parar). math.huge si no tiene que parar.
-- halfLength: medio largo del vehículo; speed y decel, para decidir con el ámbar.
-- emergency: con la sirena puesta no para (pasa con cuidado: lo decide quien llama).
function TrafficSignals.gapAhead(index: Index, pos: Vector3, dir: Vector3, halfLength: number, speed: number, decel: number, now: number): number
	local axis = TrafficSignals.axisOf(dir)
	local state = TrafficSignals.state(axis, now)
	if state == "Green" then
		return math.huge
	end
	local gap = math.huge
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local reach = TrafficSignals.LOOKAHEAD
	local kx0, kx1 = math.floor(math.min(pos.X, pos.X + dir.X * reach) / CELL), math.floor(math.max(pos.X, pos.X + dir.X * reach) / CELL)
	local kz0, kz1 = math.floor(math.min(pos.Z, pos.Z + dir.Z * reach) / CELL), math.floor(math.max(pos.Z, pos.Z + dir.Z * reach) / CELL)
	for kx = kx0 - 1, kx1 + 1 do
		for kz = kz0 - 1, kz1 + 1 do
			for _, c in index.Cells[kx .. ":" .. kz] or {} do
				local rel = Vector3.new(c.X - pos.X, 0, c.Z - pos.Z)
				local ahead = rel:Dot(dir)
				if ahead > 0 and ahead < reach and math.abs(rel:Dot(side)) < TrafficSignals.LATERAL then
					local toLine = ahead - TrafficSignals.STOP_LINE - halfLength
					if TrafficSignals.mustStop(state, toLine, speed, decel) then
						gap = math.min(gap, math.max(toLine, 0))
					end
				end
			end
		end
	end
	return gap
end

return TrafficSignals
