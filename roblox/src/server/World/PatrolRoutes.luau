-- PatrolRoutes: por dónde circulan las patrullas de policía (cuentas puras, se prueban fuera de
-- Roblox en scripts/test-wanted.luau).
--   * Las calles son tramos rectos (World/Kit/Roads.segments) que se juntan en los cruces.
--   * Al llegar al final de un tramo, la patrulla sigue por otro que salga de ese cruce (sin dar
--     la vuelta si hay otro camino); en un callejón sin salida, da la vuelta.

local PatrolRoutes = {}

export type Segment = { A: Vector3, B: Vector3, Kind: string?, Name: string? }
export type Graph = { Segments: { Segment }, Ends: { [string]: { { Index: number, From: string } } } }

local function key(p: Vector3): string
	return math.floor(p.X / 4 + 0.5) .. ":" .. math.floor(p.Z / 4 + 0.5)
end
PatrolRoutes.key = key

-- Qué tramos salen de cada cruce
function PatrolRoutes.graph(segments: { Segment }): Graph
	local ends: { [string]: { { Index: number, From: string } } } = {}
	for i, s in segments do
		for _, side in { "A", "B" } do
			local k = key((s :: any)[side])
			ends[k] = ends[k] or {}
			table.insert(ends[k], { Index = i, From = side })
		end
	end
	return { Segments = segments, Ends = ends }
end

-- Siguiente tramo al llegar al extremo `side` ("A" o "B") del tramo `index`.
-- Devuelve el tramo y desde qué extremo se entra en él. pick(n) elige 1..n (por defecto, al azar).
function PatrolRoutes.next(graph: Graph, index: number, side: string, pick: ((number) -> number)?): (number, string)
	local segment = graph.Segments[index]
	local point = (segment :: any)[side]
	local options = {}
	for _, entry in graph.Ends[key(point)] or {} do
		if entry.Index ~= index then
			table.insert(options, entry)
		end
	end
	if #options == 0 then
		-- Sin salida: da la vuelta por el mismo tramo
		return index, side
	end
	local choose = pick or function(n: number): number
		return math.random(1, n)
	end
	local chosen = options[math.clamp(choose(#options), 1, #options)]
	return chosen.Index, chosen.From
end

-- Punto a ras de calle de un tramo: t = 0 en el extremo `from`, 1 en el otro; lane = carril
-- (distancia a la derecha del centro, en el sentido de la marcha)
function PatrolRoutes.point(segment: Segment, from: string, t: number, lane: number): (Vector3, Vector3)
	local a = if from == "A" then segment.A else segment.B
	local b = if from == "A" then segment.B else segment.A
	local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local dir = if along.Magnitude > 0.01 then along.Unit else Vector3.new(0, 0, -1)
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local p = a:Lerp(b, math.clamp(t, 0, 1)) + right * lane
	return p, dir
end

-- Gira la dirección `look` (en horizontal) hacia `dir` como mucho `maxAngle` radianes, por el lado más
-- corto. Antes se mezclaba look:Lerp(dir): al dar la vuelta en un callejón (dir = -look) la mezcla
-- nunca cambiaba de sentido y el coche patrulla seguía para siempre mirando hacia atrás (marcha
-- atrás por toda la ciudad). En media vuelta exacta gira por la izquierda.
function PatrolRoutes.turnToward(look: Vector3, dir: Vector3, maxAngle: number): Vector3
	local a = Vector3.new(look.X, 0, look.Z)
	local b = Vector3.new(dir.X, 0, dir.Z)
	if b.Magnitude < 1e-4 then
		return if a.Magnitude > 1e-4 then a.Unit else Vector3.new(0, 0, -1)
	end
	b = b.Unit
	if a.Magnitude < 1e-4 then
		return b
	end
	a = a.Unit
	local angleA = math.atan2(a.X, a.Z)
	local angleB = math.atan2(b.X, b.Z)
	local delta = (angleB - angleA + math.pi) % (2 * math.pi) - math.pi
	if math.abs(delta) >= math.pi - 1e-3 then
		delta = math.pi -- (media vuelta: siempre por el mismo lado)
	end
	if math.abs(delta) <= maxAngle then
		return b
	end
	local angle = angleA + math.sign(delta) * maxAngle
	return Vector3.new(math.sin(angle), 0, math.cos(angle))
end

function PatrolRoutes.length(segment: Segment): number
	return Vector3.new(segment.B.X - segment.A.X, 0, segment.B.Z - segment.A.Z).Magnitude
end

return PatrolRoutes
