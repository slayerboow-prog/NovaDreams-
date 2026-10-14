-- Nav: por dónde andan las tropas alienígenas de tierra (cuentas puras; scripts/test-invasion.luau).
--
-- Barato y robusto (nada de PathfindingService por cada alienígena): un grafo de las calles del plano
-- (CityPlan.Roads, partidas en tramos de Step studs, con los cruces unidos) y A* sobre él. Un
-- alienígena lejos de su objetivo va a la calle más cercana, sigue el camino de calles y, ya cerca
-- (Direct studs), va recto. El servidor guarda el camino y solo lo recalcula si cambia mucho el
-- objetivo. Si no hay grafo (o el objetivo está cerca), va recto (con el empujón de los obstáculos
-- que mira el servidor).

local CityPlan = require(script.Parent.Parent.CityPlan)

local Nav = {}

Nav.Step = 120
Nav.Join = 18 -- nodos más cerca que esto se unen (cruces)
Nav.Direct = 160 -- más cerca que esto del objetivo: recto

export type Graph = { Nodes: { Vector3 }, Edges: { { number } } }

local cache: Graph? = nil

function Nav.build(roads: { { Points: { { number } } } }?): Graph
	local nodes: { Vector3 } = {}
	local edges: { { number } } = {}
	local function nodeAt(x: number, z: number): number
		for i, n in nodes do
			if (n.X - x) ^ 2 + (n.Z - z) ^ 2 <= Nav.Join * Nav.Join then
				return i
			end
		end
		table.insert(nodes, Vector3.new(x, 0, z))
		table.insert(edges, {})
		return #nodes
	end
	local function link(a: number, b: number)
		if a == b then
			return
		end
		if not table.find(edges[a], b) then
			table.insert(edges[a], b)
		end
		if not table.find(edges[b], a) then
			table.insert(edges[b], a)
		end
	end
	for _, road in roads or CityPlan.Roads do
		local prev: number? = nil
		for i = 1, #road.Points - 1 do
			local a, b = road.Points[i], road.Points[i + 1]
			local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
			local n = math.max(1, math.ceil(len / Nav.Step))
			for k = 0, n do
				if not (k == 0 and prev) then
					local t = k / n
					local id = nodeAt(a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)
					if prev then
						link(prev, id)
					end
					prev = id
				end
			end
		end
	end
	return { Nodes = nodes, Edges = edges }
end

function Nav.graph(): Graph
	if not cache then
		cache = Nav.build()
	end
	return cache :: Graph
end

function Nav.nearest(g: Graph, pos: Vector3): (number?, number)
	local best, bestD = nil, math.huge
	for i, n in g.Nodes do
		local d = (n.X - pos.X) ^ 2 + (n.Z - pos.Z) ^ 2
		if d < bestD then
			best, bestD = i, d
		end
	end
	return best, math.sqrt(bestD)
end

local function flat(a: Vector3, b: Vector3): number
	return math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2)
end

-- A* de un nodo a otro: lista de nodos (índices) o nil
function Nav.route(g: Graph, from: number, to: number, maxIter: number?): { number }?
	if from == to then
		return { from }
	end
	local open = { from }
	local came: { [number]: number } = {}
	local gScore: { [number]: number } = { [from] = 0 }
	local fScore: { [number]: number } = { [from] = flat(g.Nodes[from], g.Nodes[to]) }
	local closed: { [number]: boolean } = {}
	local iter = 0
	while #open > 0 and iter < (maxIter or 4000) do
		iter += 1
		local bi, best = 1, open[1]
		for i, n in open do
			if fScore[n] < fScore[best] then
				bi, best = i, n
			end
		end
		if best == to then
			local path = { to }
			local cur = to
			while came[cur] do
				cur = came[cur]
				table.insert(path, 1, cur)
			end
			return path
		end
		table.remove(open, bi)
		closed[best] = true
		for _, nb in g.Edges[best] do
			if not closed[nb] then
				local tentative = gScore[best] + flat(g.Nodes[best], g.Nodes[nb])
				if gScore[nb] == nil or tentative < gScore[nb] then
					came[nb] = best
					gScore[nb] = tentative
					fScore[nb] = tentative + flat(g.Nodes[nb], g.Nodes[to])
					if not table.find(open, nb) then
						table.insert(open, nb)
					end
				end
			end
		end
	end
	return nil
end

-- Los puntos (en planta, Y = 0) para ir de `from` a `goal`: por las calles si está lejos, recto si
-- está cerca. Siempre acaba en el objetivo.
function Nav.path(from: Vector3, goal: Vector3, g: Graph?): { Vector3 }
	if flat(from, goal) <= Nav.Direct then
		return { goal }
	end
	local graph = g or Nav.graph()
	local a, da = Nav.nearest(graph, from)
	local b, db = Nav.nearest(graph, goal)
	-- (si las calles quedan más lejos que el propio objetivo, recto)
	if not a or not b or da + db >= flat(from, goal) then
		return { goal }
	end
	local route = Nav.route(graph, a, b)
	if not route then
		return { goal }
	end
	local out = {}
	for _, id in route do
		table.insert(out, graph.Nodes[id])
	end
	table.insert(out, goal)
	return out
end

return Nav
