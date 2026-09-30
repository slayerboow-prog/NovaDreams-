-- Gps: rutas por las calles (como el GPS de un coche). Es puro (no toca el juego): lo usa
-- Controllers/Gps en el cliente y se prueba fuera de Roblox (scripts/test-gps.luau).
--
--   local graph = Gps.build(tramos)            -- tramos = { { A = Vector3, B = Vector3 }, ... }
--   local path = Gps.route(graph, desde, hasta) -- { Vector3 } por las calles (o nil si no hay grafo)
--   Gps.progress(path, posición)               -- en qué tramo vas, a qué distancia de la ruta y cuánto queda
--   Gps.nextTurn(path, posición)               -- { Kind = "Left" | "Right" | "Straight" | "Arrive", Distance, Remaining }
--
-- El grafo: un nodo en cada extremo de tramo y en cada cruce (dos calles que se cortan, o una que
-- acaba encima de otra: las T). Se busca con A* por la distancia en el suelo (X y Z). El principio y
-- el final se "pegan" a la calle más cercana, y el último trozo va recto hasta el sitio (la puerta).

local Gps = {}

Gps.OffRoute = 25 -- studs fuera de la ruta: se vuelve a calcular
Gps.TurnAngle = 35 -- grados a partir de los que un cambio de dirección es un giro
Gps.StudsPerMeter = 3.5 -- (como el minimapa)

export type Graph = {
	Nodes: { Vector3 },
	Adj: { { { To: number, Cost: number } } },
	Edges: { { A: number, B: number } },
}

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return (flat(a) - flat(b)).Magnitude
end

-- Punto más cercano a p en el tramo a-b (en el suelo): (punto, t 0..1, distancia)
function Gps.closestOnSegment(a: Vector3, b: Vector3, p: Vector3): (Vector3, number, number)
	local ab = flat(b) - flat(a)
	local length2 = ab:Dot(ab)
	local t = if length2 > 1e-9 then math.clamp((flat(p) - flat(a)):Dot(ab) / length2, 0, 1) else 0
	local point = a:Lerp(b, t)
	return point, t, flatDistance(point, p)
end

-- Construye el grafo de calles. tolerance: studs para unir extremos y cruces (por defecto 4)
function Gps.build(segments: { { A: Vector3, B: Vector3 } }, tolerance: number?): Graph
	local tol = tolerance or 4
	local n = #segments
	local cuts: { { number } } = {}
	local boxes = {}
	for i, s in segments do
		cuts[i] = { 0, 1 }
		boxes[i] = {
			math.min(s.A.X, s.B.X) - tol, math.max(s.A.X, s.B.X) + tol,
			math.min(s.A.Z, s.B.Z) - tol, math.max(s.A.Z, s.B.Z) + tol,
		}
	end
	for i = 1, n do
		local bi = boxes[i]
		local si = segments[i]
		for j = i + 1, n do
			local bj = boxes[j]
			if bi[1] <= bj[2] and bj[1] <= bi[2] and bi[3] <= bj[4] and bj[3] <= bi[4] then
				local sj = segments[j]
				-- ¿Se cortan?
				local p, r = flat(si.A), flat(si.B) - flat(si.A)
				local q, s = flat(sj.A), flat(sj.B) - flat(sj.A)
				local denom = r.X * s.Y - r.Y * s.X
				if math.abs(denom) > 1e-9 then
					local qp = q - p
					local t = (qp.X * s.Y - qp.Y * s.X) / denom
					local u = (qp.X * r.Y - qp.Y * r.X) / denom
					if t > 0 and t < 1 and u > 0 and u < 1 then
						table.insert(cuts[i], t)
						table.insert(cuts[j], u)
					end
				end
				-- Un extremo que acaba encima del otro tramo (una T)
				for _, e in { sj.A, sj.B } do
					local _, t, d = Gps.closestOnSegment(si.A, si.B, e)
					if d <= tol and t > 0 and t < 1 then
						table.insert(cuts[i], t)
					end
				end
				for _, e in { si.A, si.B } do
					local _, u, d = Gps.closestOnSegment(sj.A, sj.B, e)
					if d <= tol and u > 0 and u < 1 then
						table.insert(cuts[j], u)
					end
				end
			end
		end
	end

	-- Nodos (unidos si caen muy cerca) y aristas entre cortes seguidos
	local graph: Graph = { Nodes = {}, Adj = {}, Edges = {} }
	local cell = math.max(tol, 1)
	local buckets: { [string]: { number } } = {}
	local function nodeAt(v: Vector3): number
		local cx, cz = math.floor(v.X / cell), math.floor(v.Z / cell)
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, id in buckets[(cx + dx) .. "," .. (cz + dz)] or {} do
					if flatDistance(graph.Nodes[id], v) <= tol then
						return id
					end
				end
			end
		end
		table.insert(graph.Nodes, v)
		local id = #graph.Nodes
		graph.Adj[id] = {}
		local key = cx .. "," .. cz
		buckets[key] = buckets[key] or {}
		table.insert(buckets[key], id)
		return id
	end
	local seen: { [string]: boolean } = {}
	for i, s in segments do
		local list = cuts[i]
		table.sort(list)
		local previous: number? = nil
		for _, t in list do
			local id = nodeAt(s.A:Lerp(s.B, t))
			if previous and previous ~= id then
				local key = if previous < id then previous .. "-" .. id else id .. "-" .. previous
				if not seen[key] then
					seen[key] = true
					local cost = flatDistance(graph.Nodes[previous], graph.Nodes[id])
					table.insert(graph.Adj[previous], { To = id, Cost = cost })
					table.insert(graph.Adj[id], { To = previous, Cost = cost })
					table.insert(graph.Edges, { A = previous, B = id })
				end
			end
			previous = id
		end
	end
	return graph
end

-- El punto de calle más cercano: { Edge, Point, T, Distance } (nil si no hay calles)
function Gps.snap(graph: Graph, p: Vector3): { Edge: number, Point: Vector3, T: number, Distance: number }?
	local best = nil
	for i, edge in graph.Edges do
		local point, t, d = Gps.closestOnSegment(graph.Nodes[edge.A], graph.Nodes[edge.B], p)
		if not best or d < best.Distance then
			best = { Edge = i, Point = point, T = t, Distance = d }
		end
	end
	return best
end

-- Montón (cola de prioridad) para A*
local function push(heap: { { number } }, item: { number })
	table.insert(heap, item)
	local i = #heap
	while i > 1 do
		local parent = i // 2
		if heap[parent][1] <= heap[i][1] then
			break
		end
		heap[parent], heap[i] = heap[i], heap[parent]
		i = parent
	end
end

local function pop(heap: { { number } }): { number }?
	local top = heap[1]
	if not top then
		return nil
	end
	local last = table.remove(heap)
	if #heap > 0 and last then
		heap[1] = last
		local i = 1
		while true do
			local l, r, smallest = i * 2, i * 2 + 1, i
			if heap[l] and heap[l][1] < heap[smallest][1] then
				smallest = l
			end
			if heap[r] and heap[r][1] < heap[smallest][1] then
				smallest = r
			end
			if smallest == i then
				break
			end
			heap[i], heap[smallest] = heap[smallest], heap[i]
			i = smallest
		end
	end
	return top
end

-- Quita los puntos que no cambian de dirección (menos trozos que dibujar)
function Gps.simplify(path: { Vector3 }): { Vector3 }
	if #path <= 2 then
		return path
	end
	local out = { path[1] }
	for i = 2, #path - 1 do
		local a, b, c = flat(out[#out]), flat(path[i]), flat(path[i + 1])
		local d1, d2 = b - a, c - b
		if d1.Magnitude < 0.5 then
			continue
		end
		if d2.Magnitude < 0.5 then
			continue
		end
		local cross = d1.Unit.X * d2.Unit.Y - d1.Unit.Y * d2.Unit.X
		if math.abs(cross) > 0.03 or d1.Unit:Dot(d2.Unit) < 0 then
			table.insert(out, path[i])
		end
	end
	table.insert(out, path[#path])
	return out
end

-- Ruta por las calles de from a to: { Vector3 } (empieza en from y acaba en to)
function Gps.route(graph: Graph, from: Vector3, to: Vector3): { Vector3 }?
	if #graph.Edges == 0 then
		return nil
	end
	local s = Gps.snap(graph, from)
	local g = Gps.snap(graph, to)
	if not s or not g then
		return nil
	end
	-- Mismo tramo: recto por él
	if s.Edge == g.Edge then
		return Gps.simplify({ from, s.Point, g.Point, to })
	end
	local nodes = graph.Nodes
	local startEdge, goalEdge = graph.Edges[s.Edge], graph.Edges[g.Edge]
	-- Nodos provisionales: 0 = inicio (en la calle), -1 = final (en la calle)
	local function neighbours(id: number): { { To: number, Cost: number } }
		if id == 0 then
			return {
				{ To = startEdge.A, Cost = flatDistance(s.Point, nodes[startEdge.A]) },
				{ To = startEdge.B, Cost = flatDistance(s.Point, nodes[startEdge.B]) },
			}
		end
		local list = graph.Adj[id]
		if id == goalEdge.A or id == goalEdge.B then
			list = table.clone(list)
			table.insert(list, { To = -1, Cost = flatDistance(nodes[id], g.Point) })
		end
		return list
	end
	local function position(id: number): Vector3
		return if id == 0 then s.Point elseif id == -1 then g.Point else nodes[id]
	end
	local best: { [number]: number } = { [0] = 0 }
	local came: { [number]: number } = {}
	local heap = {}
	push(heap, { flatDistance(s.Point, g.Point), 0 })
	local found = false
	while true do
		local item = pop(heap)
		if not item then
			break
		end
		local id = item[2]
		if id == -1 then
			found = true
			break
		end
		local cost = best[id]
		for _, link in neighbours(id) do
			local nextCost = cost + link.Cost
			if best[link.To] == nil or nextCost < best[link.To] - 1e-6 then
				best[link.To] = nextCost
				came[link.To] = id
				push(heap, { nextCost + flatDistance(position(link.To), g.Point), link.To })
			end
		end
	end
	if not found then
		return nil
	end
	local reversed = { to, g.Point }
	local id = came[-1]
	while id ~= nil and id ~= 0 do
		table.insert(reversed, nodes[id])
		id = came[id]
	end
	table.insert(reversed, s.Point)
	table.insert(reversed, from)
	local path = {}
	for i = #reversed, 1, -1 do
		table.insert(path, reversed[i])
	end
	return Gps.simplify(path)
end

-- Largo de la ruta (en el suelo)
function Gps.length(path: { Vector3 }): number
	local total = 0
	for i = 2, #path do
		total += flatDistance(path[i - 1], path[i])
	end
	return total
end

-- Dónde vas en la ruta: índice del tramo (i -> i+1), punto más cercano, distancia a la ruta y lo que queda
function Gps.progress(path: { Vector3 }, p: Vector3): { Index: number, Point: Vector3, Off: number, Remaining: number }
	local bestIndex, bestPoint, bestDistance = 1, path[1], math.huge
	for i = 1, #path - 1 do
		local point, _, d = Gps.closestOnSegment(path[i], path[i + 1], p)
		if d < bestDistance - 1e-6 then
			bestIndex, bestPoint, bestDistance = i, point, d
		end
	end
	if #path == 1 then
		bestDistance = flatDistance(path[1], p)
	end
	local remaining = if #path > 1 then flatDistance(bestPoint, path[bestIndex + 1]) else 0
	for i = bestIndex + 1, #path - 1 do
		remaining += flatDistance(path[i], path[i + 1])
	end
	return { Index = bestIndex, Point = bestPoint, Off = bestDistance, Remaining = remaining }
end

-- ¿Te has salido de la ruta? (más de Gps.OffRoute studs)
function Gps.offRoute(path: { Vector3 }, p: Vector3, threshold: number?): boolean
	return Gps.progress(path, p).Off > (threshold or Gps.OffRoute)
end

-- Giro entre dos direcciones: "Left", "Right" o nil (recto). En el mapa X va a la derecha y Z hacia abajo.
function Gps.turnKind(d1: Vector2, d2: Vector2, threshold: number?): string?
	if d1.Magnitude < 1e-6 or d2.Magnitude < 1e-6 then
		return nil
	end
	local a, b = d1.Unit, d2.Unit
	local angle = math.deg(math.atan2(a.X * b.Y - a.Y * b.X, a:Dot(b)))
	if angle > (threshold or Gps.TurnAngle) then
		return "Right"
	elseif angle < -(threshold or Gps.TurnAngle) then
		return "Left"
	end
	return nil
end

-- La siguiente indicación desde donde estás: el próximo giro (y a cuánto), seguir recto o has llegado
function Gps.nextTurn(path: { Vector3 }, p: Vector3, arriveDistance: number?): { Kind: string, Distance: number, Remaining: number }
	local at = Gps.progress(path, p)
	if at.Remaining <= (arriveDistance or 12) then
		return { Kind = "Arrive", Distance = at.Remaining, Remaining = at.Remaining }
	end
	local distance = flatDistance(at.Point, path[at.Index + 1])
	for i = at.Index + 1, #path - 1 do
		local kind = Gps.turnKind(flat(path[i]) - flat(path[i - 1]), flat(path[i + 1]) - flat(path[i]))
		if kind then
			return { Kind = kind, Distance = distance, Remaining = at.Remaining }
		end
		distance += flatDistance(path[i], path[i + 1])
	end
	return { Kind = "Straight", Distance = at.Remaining, Remaining = at.Remaining }
end

-- Texto de la indicación ("Gira a la derecha en 40 m")
function Gps.instructionText(turn: { Kind: string, Distance: number }): string
	local meters = math.max(0, math.floor(turn.Distance / Gps.StudsPerMeter / 5 + 0.5) * 5)
	if turn.Kind == "Arrive" then
		return "Estás llegando"
	elseif turn.Kind == "Left" then
		return if meters <= 5 then "Gira a la izquierda" else ("Gira a la izquierda en %d m"):format(meters)
	elseif turn.Kind == "Right" then
		return if meters <= 5 then "Gira a la derecha" else ("Gira a la derecha en %d m"):format(meters)
	end
	return "Sigue recto"
end

-- "347 m · 2 min" (velocidad en studs por segundo)
function Gps.distanceText(studs: number, speed: number): string
	local meters = math.floor(studs / Gps.StudsPerMeter + 0.5)
	local distance = if meters >= 1000 then ("%.1f km"):format(meters / 1000) else ("%d m"):format(meters)
	local minutes = math.max(1, math.floor(studs / math.max(speed, 1) / 60 + 0.5))
	return ("%s · %d min"):format(distance, minutes)
end

-- Los puntos de la ruta desde donde vas (para dibujar solo lo que queda)
function Gps.ahead(path: { Vector3 }, p: Vector3): { Vector3 }
	local at = Gps.progress(path, p)
	local out = { at.Point }
	for i = at.Index + 1, #path do
		table.insert(out, path[i])
	end
	return out
end

-- Puntos cada `step` studs a lo largo de la ruta, hasta `reach` studs (flechas en el suelo): { { Position, Direction } }
function Gps.marks(path: { Vector3 }, step: number, reach: number, maxCount: number?): { { Position: Vector3, Direction: Vector3 } }
	local out = {}
	local travelled = step * 0.5
	local limit = maxCount or math.huge
	local segmentStart = 0
	for i = 1, #path - 1 do
		local a, b = path[i], path[i + 1]
		local length = flatDistance(a, b)
		while travelled <= segmentStart + length and travelled <= reach and #out < limit do
			local t = if length > 0 then (travelled - segmentStart) / length else 0
			local direction = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			table.insert(out, { Position = a:Lerp(b, t), Direction = if direction.Magnitude > 0 then direction.Unit else Vector3.new(0, 0, -1) })
			travelled += step
		end
		segmentStart += length
		if travelled > reach or #out >= limit then
			break
		end
	end
	return out
end

---------------------------------------------------------------------
-- Prioridad de la navegación: UNA sola guía a la vez
---------------------------------------------------------------------
-- Si tú eliges un destino (un lugar del mapa, "Ir aquí", "Ruta a casa", el plano del metro…), esa
-- ruta MANDA: la indicación dice su nombre, los mapas enseñan su línea y su 📍 y las flechas del
-- suelo llevan allí; lo de la misión (su haz de luz, su ★ en los mapas y su ruta) se esconde hasta que
-- quites la ruta (✕), llegues o elijas «Seguir misión». Una misión nueva no te la quita: solo avisa.

-- Los objetivos que pone el servidor (atributos del jugador), por orden de preferencia
Gps.Targets = {
	{ Attribute = "TaskTarget", Name = "Tu trabajo", Notice = "Nueva tarea del trabajo" },
	{ Attribute = "CityErrandTarget", Name = "Tu encargo", Notice = "Nuevo paso del encargo" },
	{ Attribute = "StoryTarget", Name = "Tu misión", Notice = "Nueva misión" },
	{ Attribute = "SeasonTarget", Name = "Misión de temporada", Notice = "Nueva misión de temporada" }, -- (la que sigues en el pase de temporada)
}

export type Place = { Position: Vector3, Name: string }
export type Destination = { Position: Vector3, Name: string, Manual: boolean }

local function listed(list: { Vector3 }?, target: Vector3): boolean
	for _, p in list or {} do
		if (p - target).Magnitude < 1 then
			return true
		end
	end
	return false
end

-- El objetivo de la misión/trabajo que toca ahora (sin mirar la ruta marcada): el primero que haya y
-- que no esté silenciado. get(atributo) -> valor. Devuelve la posición y su entrada de Gps.Targets
function Gps.missionTarget(get: (string) -> any, suppressed: { Vector3 }?): (Vector3?, { [string]: string }?)
	for _, entry in Gps.Targets do
		local target = get(entry.Attribute)
		if typeof(target) == "Vector3" and not listed(suppressed, target) then
			return target, entry
		end
	end
	return nil, nil
end

-- Adónde lleva el GPS: la ruta que marcaste manda; si no hay, el objetivo de la misión/trabajo
function Gps.pickDestination(manual: Place?, get: (string) -> any, suppressed: { Vector3 }?): Destination?
	if manual then
		return { Position = manual.Position, Name = manual.Name, Manual = true }
	end
	local target, entry = Gps.missionTarget(get, suppressed)
	if target and entry then
		return { Position = target, Name = entry.Name, Manual = false }
	end
	return nil
end

-- Lo que marca la misión en el mundo y en los mapas (haz de luz, ★): nada mientras sigues tu ruta
function Gps.missionMarker(manual: Place?, get: (string) -> any): Vector3?
	if manual then
		return nil
	end
	return (Gps.missionTarget(get, nil))
end

-- ¿Has llegado? (los sitios del mapa no tienen altura de verdad: con ellos solo cuenta el plano)
function Gps.arrived(dest: Destination, position: Vector3, arriveDistance: number): boolean
	local flat = flatDistance(dest.Position, position)
	local sameHeight = dest.Manual or math.abs(dest.Position.Y - position.Y) < 30
	return flat < arriveDistance and sameHeight
end

-- La etiqueta de la ruta marcada en la tarjeta de la misión ("📍 Ruta a Aeropuerto de Valmar")
function Gps.routeChipText(name: string): string
	return "📍 Ruta a " .. name
end

-- El aviso cuando la misión cambia mientras sigues tu ruta (no te la quita)
function Gps.noticeText(entry: { [string]: string }?, step: string?): string
	local head = if entry then entry.Notice else "Nuevo objetivo"
	local what = if step and step ~= "" then ": " .. step else ""
	return head .. what .. " (toca para seguirla)"
end

-- Al llegar a tu ruta: el aviso (y si vuelve la guía de la misión)
function Gps.arrivalText(name: string, missionBack: boolean): string
	return "📍 Has llegado: " .. name .. (if missionBack then " · vuelve la ruta de tu misión" else "")
end

return Gps
