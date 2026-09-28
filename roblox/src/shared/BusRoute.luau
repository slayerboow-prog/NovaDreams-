-- BusRoute: el "GPS" de los autobuses.
-- Convierte todas las calles (tramos rectos A-B con su ancho) en un grafo de cruces y calcula
-- el camino más corto por las calles entre dos puntos (Dijkstra). Con eso se arma la línea
-- circular que pasa por todas las paradas, siempre por asfalto.

local BusRoute = {}

export type Road = { A: Vector3, B: Vector3, Width: number, Kind: string? }
-- Cada arista lleva también el ancho (W) y el tipo (Kind) de su calle: lo usa el tráfico del cliente
export type Graph = { Nodes: { Vector3 }, Edges: { { { To: number, Cost: number, W: number, Kind: string? } } }, StopNodes: { number } }

local MERGE = 7 -- puntos a menos de esto son el mismo cruce

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Parámetro (0..1) del punto de un tramo más cercano a p, y la distancia
local function project(a: Vector3, b: Vector3, p: Vector3): (number, number)
	local ab = b - a
	local len2 = ab:Dot(ab)
	local t = if len2 > 0 then math.clamp((p - a):Dot(ab) / len2, 0, 1) else 0
	return t, (a + ab * t - p).Magnitude
end

-- Intersección de dos tramos (parámetros en cada uno) o nil
local function cross(a: Vector3, b: Vector3, c: Vector3, d: Vector3): (number?, number?)
	local r, s = b - a, d - c
	local den = r.X * s.Z - r.Z * s.X
	if math.abs(den) < 1e-6 then
		return nil, nil
	end
	local t = ((c.X - a.X) * s.Z - (c.Z - a.Z) * s.X) / den
	local u = ((c.X - a.X) * r.Z - (c.Z - a.Z) * r.X) / den
	if t >= -0.001 and t <= 1.001 and u >= -0.001 and u <= 1.001 then
		return math.clamp(t, 0, 1), math.clamp(u, 0, 1)
	end
	return nil, nil
end

-- Grafo de calles. stops = puntos (en la acera) que se enganchan a la calle más cercana.
function BusRoute.graph(roads: { Road }, stops: { Vector3 }): Graph
	local list = {}
	for _, r in roads do
		local a, b = flat(r.A), flat(r.B)
		if (b - a).Magnitude > 1 then
			table.insert(list, { A = a, B = b, W = r.Width or 24, Kind = r.Kind, Params = { 0, 1 } })
		end
	end
	-- Cruces entre calles (en X, en T y en esquina)
	for i = 1, #list do
		local ri = list[i]
		for j = i + 1, #list do
			local rj = list[j]
			local t, u = cross(ri.A, ri.B, rj.A, rj.B)
			if t and u then
				table.insert(ri.Params, t)
				table.insert(rj.Params, u)
			else
				-- Una calle que acaba encima de la otra (en T): su punta se engancha
				for _, pair in { { ri, rj }, { rj, ri } } do
					local x, y = pair[1], pair[2]
					for _, e in { 0, 1 } do
						local p = if e == 0 then x.A else x.B
						local tt, dist = project(y.A, y.B, p)
						if dist <= y.W / 2 + 6 then
							table.insert(y.Params, tt)
							table.insert(x.Params, e)
						end
					end
				end
			end
		end
	end
	-- Paradas: se enganchan a la calle más cercana
	local stopLinks = {}
	for k, stop in stops do
		local best, bestT, bestDist = nil, 0, math.huge
		for _, r in list do
			local t, dist = project(r.A, r.B, flat(stop))
			if dist < bestDist then
				best, bestT, bestDist = r, t, dist
			end
		end
		if best then
			table.insert(best.Params, bestT)
			stopLinks[k] = { Road = best, T = bestT }
		end
	end
	-- Nodos (juntando los que están casi en el mismo sitio) y aristas a lo largo de cada calle
	local nodes: { Vector3 } = {}
	local edges = {}
	local hash = {}
	local function nodeAt(p: Vector3): number
		local kx, kz = math.floor(p.X / MERGE), math.floor(p.Z / MERGE)
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, id in hash[(kx + dx) .. ":" .. (kz + dz)] or {} do
					if (nodes[id] - p).Magnitude < MERGE then
						return id
					end
				end
			end
		end
		table.insert(nodes, p)
		local id = #nodes
		edges[id] = {}
		local key = kx .. ":" .. kz
		hash[key] = hash[key] or {}
		table.insert(hash[key], id)
		return id
	end
	local function link(x: number, y: number, w: number, kind: string?)
		if x == y then
			return
		end
		for _, e in edges[x] do
			if e.To == y then
				return -- ya unidos (dos calles que se solapan)
			end
		end
		local cost = (nodes[x] - nodes[y]).Magnitude
		table.insert(edges[x], { To = y, Cost = cost, W = w, Kind = kind })
		table.insert(edges[y], { To = x, Cost = cost, W = w, Kind = kind })
	end
	for _, r in list do
		table.sort(r.Params)
		local prev: number? = nil
		r.Nodes = {}
		for _, t in r.Params do
			local id = nodeAt(r.A + (r.B - r.A) * t)
			r.Nodes[t] = id
			if prev and prev ~= id then
				link(prev, id, r.W, r.Kind)
			end
			prev = id
		end
	end
	local stopNodes = {}
	for k, s in stopLinks do
		stopNodes[k] = s.Road.Nodes[s.T]
	end
	return { Nodes = nodes, Edges = edges, StopNodes = stopNodes }
end

-- Camino más corto entre dos nodos (lista de posiciones) o nil si no hay
function BusRoute.path(graph: Graph, from: number, to: number): { Vector3 }?
	local n = #graph.Nodes
	local dist, prev, done = {}, {}, {}
	for i = 1, n do
		dist[i] = math.huge
	end
	dist[from] = 0
	-- Montículo binario sencillo
	local heap = { { 0, from } }
	local function push(item)
		table.insert(heap, item)
		local i = #heap
		while i > 1 do
			local p = i // 2
			if heap[p][1] <= heap[i][1] then
				break
			end
			heap[p], heap[i] = heap[i], heap[p]
			i = p
		end
	end
	local function pop()
		local top = heap[1]
		local last = table.remove(heap)
		if #heap > 0 then
			heap[1] = last
			local i = 1
			while true do
				local l, r, m = i * 2, i * 2 + 1, i
				if l <= #heap and heap[l][1] < heap[m][1] then
					m = l
				end
				if r <= #heap and heap[r][1] < heap[m][1] then
					m = r
				end
				if m == i then
					break
				end
				heap[m], heap[i] = heap[i], heap[m]
				i = m
			end
		end
		return top
	end
	while #heap > 0 do
		local item = pop()
		local u = item[2]
		if not done[u] then
			done[u] = true
			if u == to then
				break
			end
			for _, e in graph.Edges[u] do
				local alt = dist[u] + e.Cost
				if alt < dist[e.To] then
					dist[e.To] = alt
					prev[e.To] = u
					push({ alt, e.To })
				end
			end
		end
	end
	if dist[to] == math.huge then
		return nil
	end
	local out = {}
	local u = to
	while u do
		table.insert(out, 1, graph.Nodes[u])
		u = prev[u]
	end
	return out
end

-- Línea circular: visita las paradas en orden (la más cercana cada vez) y vuelve al principio.
-- Devuelve los puntos del recorrido por el centro de la calle y en qué punto está cada parada.
function BusRoute.loop(roads: { Road }, stops: { Vector3 }): ({ Vector3 }, { { Index: number, Stop: number } })
	local graph = BusRoute.graph(roads, stops)
	-- Orden de visita
	local order, used = { 1 }, { [1] = true }
	for _ = 2, #stops do
		local last = stops[order[#order]]
		local best, bestDist = nil, math.huge
		for k, s in stops do
			if not used[k] and graph.StopNodes[k] then
				local d = (s - last).Magnitude
				if d < bestDist then
					best, bestDist = k, d
				end
			end
		end
		if not best then
			break
		end
		used[best] = true
		table.insert(order, best)
	end
	local points: { Vector3 } = {}
	local marks = {}
	for i, k in order do
		local nextK = order[i % #order + 1]
		local a, b = graph.StopNodes[k], graph.StopNodes[nextK]
		local piece = if a and b then BusRoute.path(graph, a, b) else nil
		if piece then
			table.insert(marks, { Index = #points + 1, Stop = k })
			for j, p in piece do
				if j < #piece or i == #order then
					if #points == 0 or (points[#points] - p).Magnitude > 0.5 then
						table.insert(points, p)
					end
				end
			end
		end
	end
	return points, marks
end

-- Desplaza el recorrido al carril de la derecha (se circula por la derecha)
function BusRoute.lane(points: { Vector3 }, offset: number): { Vector3 }
	local out = {}
	local n = #points
	for i, p in points do
		local a = points[if i > 1 then i - 1 else n]
		local b = points[if i < n then i + 1 else 1]
		local dir = b - a
		if dir.Magnitude < 0.01 then
			table.insert(out, p)
		else
			local d = dir.Unit
			local right = Vector3.new(-d.Z, 0, d.X)
			table.insert(out, p + right * offset)
		end
	end
	return out
end

return BusRoute
