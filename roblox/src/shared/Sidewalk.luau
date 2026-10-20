-- Sidewalk: lo que estorba en las aceras (farolas, papeleras, jardineras, quioscos, árboles, motos
-- aparcadas…) y por dónde pasar sin atravesarlo. Lo calcula el servidor una vez al arrancar
-- (World/Ambient.publish, con el mapa entero) y lo usan los peatones de cada cliente
-- (Controllers/Ambient): se apartan a tiempo y, si no cabe nadie, se dan la vuelta.
--
--   Sidewalk.project(road, cf, size)        -> u0, u1, v0, v1 (la caja de la pieza en la calle)
--   Sidewalk.encode(list) / decode(text)     -> para guardarlo en un atributo de la calle
--   Sidewalk.lane(list, u, dir, look, want, lo, hi, radius) -> por dónde ir (v) y si hay que pararse
--
-- Coordenadas de una calle: u a lo largo (desde A, en la dirección Dir) y v de lado (hacia Perp).

local Sidewalk = {}

export type Obstacle = { U0: number, U1: number, V0: number, V1: number }
export type Frame = { A: Vector3, Dir: Vector3, Perp: Vector3 }

-- La caja de una pieza vista desde la calle (solo en planta): lo que ocupa a lo largo y de lado
function Sidewalk.project(road: Frame, cf: CFrame, size: Vector3): (number, number, number, number)
	local u0, u1, v0, v1 = math.huge, -math.huge, math.huge, -math.huge
	for _, sx in { -0.5, 0.5 } do
		for _, sz in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				local p = (cf * CFrame.new(size.X * sx, size.Y * sy, size.Z * sz)).Position - road.A
				local u, v = p:Dot(road.Dir), p:Dot(road.Perp)
				u0, u1 = math.min(u0, u), math.max(u1, u)
				v0, v1 = math.min(v0, v), math.max(v1, v)
			end
		end
	end
	return u0, u1, v0, v1
end

local function round(x: number): string
	return ("%.1f"):format(x)
end

-- "u0,u1,v0,v1;u0,u1,v0,v1;…" (ordenado a lo largo de la calle)
function Sidewalk.encode(list: { Obstacle }): string
	table.sort(list, function(a, b)
		return a.U0 < b.U0
	end)
	local parts = table.create(#list)
	for _, o in list do
		table.insert(parts, table.concat({ round(o.U0), round(o.U1), round(o.V0), round(o.V1) }, ","))
	end
	return table.concat(parts, ";")
end

function Sidewalk.decode(text: any): { Obstacle }
	local list = {}
	if type(text) ~= "string" then
		return list
	end
	for a, b, c, d in string.gmatch(text, "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
		local o = { U0 = tonumber(a) :: number, U1 = tonumber(b) :: number, V0 = tonumber(c) :: number, V1 = tonumber(d) :: number }
		table.insert(list, o)
	end
	table.sort(list, function(x, y)
		return x.U0 < y.U0
	end)
	return list
end

local scratchBlocks: { Obstacle } = {}
local scratchCandidates: { number } = {}

-- Lo más largo que mide un estorbo de cada lista (a lo largo de la calle). Con eso se sabe desde
-- dónde empezar a mirar sin recorrer la lista desde el principio en cada fotograma. Tabla débil: si
-- la lista deja de usarse, se olvida sola.
local longest: { [{ Obstacle }]: number } = setmetatable({}, { __mode = "k" }) :: any

local function longestOf(list: { Obstacle }): number
	local known = longest[list]
	if known then
		return known
	end
	local best = 0
	for _, o in list do
		best = math.max(best, o.U1 - o.U0)
	end
	longest[list] = best
	return best
end

-- El primer estorbo (de la lista ordenada por U0) que puede llegar hasta a: los de antes empiezan
-- tan atrás que ni el más largo lo alcanza (búsqueda binaria)
local function firstFrom(list: { Obstacle }, a: number): number
	local from = a - longestOf(list) - 1e-6
	local lo, hi = 1, #list + 1
	while lo < hi do
		local mid = (lo + hi) // 2
		if list[mid].U0 < from then
			lo = mid + 1
		else
			hi = mid
		end
	end
	return lo
end

-- Por dónde ir. list: los estorbos de la calle (ordenados por U0); u: dónde está; dir: +1/-1 (hacia
-- dónde anda); look: cuánto mira por delante; want: el v que querría llevar; lo..hi: el trozo de la
-- acera por el que puede ir (su v); radius: medio ancho de la persona.
-- Devuelve el v por el que pasar (el hueco libre más cercano a want) y si tiene algo justo delante que
-- aún no ha esquivado (entonces se para un momento en vez de atravesarlo). Si no cabe por ningún lado,
-- devuelve nil: hay que darse la vuelta.
function Sidewalk.lane(list: { Obstacle }, u: number, dir: number, look: number, want: number, lo: number, hi: number, radius: number, now: number?): (number?, boolean)
	local a, b = if dir > 0 then u - radius else u - look, if dir > 0 then u + look else u + radius
	-- Los que tocan el tramo que tiene delante y la acera por la que va (en tablas reutilizadas: se
	-- llama en cada fotograma por cada peatón)
	local blocks = scratchBlocks
	table.clear(blocks)
	-- (la lista no cambia después de decode: se empieza cerca de u, no desde el principio)
	for k = firstFrom(list, a), #list do
		local o = list[k]
		if o.U0 > b then
			break
		end
		if o.U1 >= a and o.V1 > lo - radius and o.V0 < hi + radius then
			table.insert(blocks, o)
		end
	end
	if #blocks == 0 then
		return math.clamp(want, lo, hi), false
	end
	local function free(v: number): boolean
		for _, o in blocks do
			if v + radius > o.V0 and v - radius < o.V1 then
				return false
			end
		end
		return true
	end
	-- Candidatos: donde quiere ir y justo al lado de cada estorbo (por los dos lados)
	local best, bestD = nil, math.huge
	local candidates = scratchCandidates
	table.clear(candidates)
	table.insert(candidates, math.clamp(want, lo, hi))
	for _, o in blocks do
		table.insert(candidates, o.V0 - radius - 0.05)
		table.insert(candidates, o.V1 + radius + 0.05)
	end
	for _, v in candidates do
		if v >= lo - 1e-6 and v <= hi + 1e-6 and free(v) then
			local d = math.abs(v - want)
			if d < bestD then
				best, bestD = v, d
			end
		end
	end
	-- ¿Algo pegado delante a su altura de ahora? (now: el v que lleva ahora mismo)
	local stuck = false
	if now then
		for _, o in blocks do
			local ahead = if dir > 0 then o.U0 - u else u - o.U1
			-- (solo lo que empieza delante: si ya está metido, se sale de lado sin quedarse clavado)
			if ahead < radius + 0.6 and ahead > -0.2 and now + radius > o.V0 and now - radius < o.V1 then
				stuck = true
			end
		end
	end
	return best, stuck
end

return Sidewalk
