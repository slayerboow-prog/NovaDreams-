-- BusLines: la red de autobuses urbanos de Valmar (líneas, paradas y tiempos de llegada).
--
-- Cada línea es un circuito: el autobús sale de su cabecera, llega a la otra punta (Turn) y vuelve
-- por otras calles. Cada parada es de un solo sentido y está en la acera de la derecha (se circula
-- por la derecha); donde la línea pasa en los dos sentidos hay una parada a cada lado.
--
-- Las paradas se definen con un punto encima de una calle (a media manzana, lejos de los cruces).
-- Los puntos "via" no son paradas: solo obligan al autobús a pasar por esa calle en ese sentido.
-- BusLines.plan(calles) engancha cada punto a su calle, calcula el recorrido de cada línea por el
-- asfalto (sin cambios de sentido), el carril, las rotondas y dónde va cada marquesina. Lo usan:
--   * al construir la ciudad (World/Kit/BusStops): marquesinas, postes y paneles
--   * el servidor (BusService): los autobuses, las llegadas y los paneles de tiempo
-- Las dos partes calculan lo mismo con las mismas calles, así que las paradas coinciden siempre.

-- (por ReplicatedStorage y no por script.Parent: así también carga al construir la ciudad con Lune)
local Shared = game:GetService("ReplicatedStorage").Shared
local BusRoute = require(Shared.BusRoute)
local CityPlan = require(Shared.CityPlan)

local BusLines = {}

BusLines.Lane = 5 -- del centro de la calle al centro del carril derecho
BusLines.ArcRadius = 40 -- radio por el que se da la vuelta en una rotonda
BusLines.Walk = { Avenida = 7, Calle = 6, Autovia = 0 } -- ancho de la acera por tipo de calle
BusLines.StreetWalk = 8 -- calles de barrio (Kit/Street)
BusLines.ShelterDepth = 2.6 -- del borde exterior de la acera al centro de la marquesina

export type LineDef = {
	Id: string,
	Name: string,
	Color: { number },
	Buses: number, -- autobuses que la recorren a la vez
	Out: string, -- destino a la ida ("L1 → Playa Dorada")
	Back: string, -- destino a la vuelta
	Turn: number, -- desde esta parada (la otra cabecera) el autobús ya vuelve
	Stops: { { any } }, -- { "Nombre", x, z } (o { "via", x, z })
}

-- Las líneas. El orden de las paradas es el sentido de la marcha.
BusLines.Lines = {
	{
		Id = "L1",
		Name = "Centro – Playa Dorada",
		Color = { 215, 45, 50 },
		Buses = 3,
		Out = "Playa Dorada",
		Back = "Plaza Mayor",
		Turn = 6,
		Stops = {
			{ "Plaza Mayor", -200, 0 },
			{ "Avenida del Este", 700, 0 },
			{ "Levante (metro)", 1900, 0 },
			{ "Paseo de Levante", 2900, 0 },
			{ "Playa Dorada (metro)", 3550, -500 },
			{ "Playa Dorada · Playa", 3790, -880 },
			{ "Playa Dorada · Centro", 3430, -1240 },
			{ "Carretera de Levante", 3310, -1600 },
			{ "Distrito Este", 2400, -1800 },
			{ "Distrito Financiero", 0, -930 },
			{ "via", -625, -300 },
		},
	},
	{
		Id = "L2",
		Name = "Valmar Norte – Puerto",
		Color = { 40, 110, 215 },
		Buses = 3,
		Out = "Puerto",
		Back = "Valmar Norte",
		Turn = 10,
		Stops = {
			{ "Valmar Norte · Hospital", -700, -2020 },
			{ "Valmar Norte · Colegio", -700, -1780 },
			{ "Norte (metro)", 0, -1700 },
			{ "Distrito Financiero", 0, -930 },
			{ "Valmar Centro", 0, 500 },
			{ "San Roque (metro)", 0, 2000 },
			{ "San Roque · Colegio", -410, 2370 },
			{ "via", -340, 2490 },
			{ "Avenida del Sur", 0, 2700 },
			{ "Puerto (metro)", 700, 3150 },
			{ "Distrito Sur · Industria", 1125, 2400 },
			{ "Distrito Sur", 1125, 1700 },
			{ "Ronda Este", 1125, 500 },
			{ "Norte (metro)", 0, -1550 },
			{ "Calle Mayor del Norte", -200, -1900 },
			{ "via", -500, -2140 },
		},
	},
	{
		Id = "L3",
		Name = "Circular",
		Color = { 245, 170, 30 },
		Buses = 3,
		Out = "Circular",
		Back = "Circular",
		Turn = 1,
		Stops = {
			{ "Poniente (metro)", -1875, -150 },
			{ "Distrito Oeste · Norte", -1875, -1000 },
			{ "Distrito Norte · Oeste", -1000, -1375 },
			{ "Valmar Norte · Sur", -600, -1375 },
			{ "Los Pinos · Sur", 500, -1375 },
			{ "Ronda Este · Norte", 1125, -700 },
			{ "Ronda Este · Sur", 1125, 250 },
			{ "Ronda Sur · Este", 500, 1125 },
			{ "Ronda Sur · Oeste", -500, 1125 },
			{ "Distrito Oeste · Sur", -1875, 850 },
		},
	},
	{
		Id = "L4",
		Name = "Campus – Puerto",
		Color = { 40, 170, 90 },
		Buses = 2,
		Out = "Puerto",
		Back = "Campus Valmar",
		Turn = 6,
		Stops = {
			{ "Campus · Facultades", 2410, 1180 },
			{ "Avenida Universitaria", 1980, 1300 },
			{ "Distrito Sur · Talleres", 1125, 1900 },
			{ "Distrito Sur · Muelles", 1125, 2700 },
			{ "Puerto de Mercancías", 900, 3150 },
			{ "Distrito Sur · Fábricas", 625, 2500 },
			{ "Distrito Sur · Norte", 625, 1700 },
			{ "Avenida Universitaria · Este", 2030, 1300 },
			{ "Campus · Estadio", 2530, 1300 },
			{ "Campus · Colegio", 2890, 1600 },
		},
	},
	{
		Id = "L5",
		Name = "Los Pinos – Villaverde",
		Color = { 160, 90, 220 },
		Buses = 3,
		Out = "Villaverde",
		Back = "Los Pinos",
		Turn = 12,
		Stops = {
			{ "Los Pinos · Centro comercial", 820, -1900 },
			{ "Los Pinos · Parque", 940, -2020 },
			{ "Los Pinos · Casas", 580, -2140 },
			{ "Los Pinos · Colegio", 460, -2020 },
			{ "Calle Mayor del Norte · Este", 200, -1900 },
			{ "Norte (metro)", 0, -1700 },
			{ "Distrito Norte", -800, -1375 },
			{ "Carretera de Villaverde", -1600, -1573 },
			{ "Villaverde · Entrada", -2100, -1850 },
			{ "Villaverde · Colegio", -2580, -1850 },
			{ "Villaverde · Oeste", -2940, -2000 },
			{ "Villaverde · Granjas", -2580, -2230 },
			{ "Villaverde · Centro", -2460, -2000 },
			{ "Villaverde · Salida", -2150, -1850 },
			{ "Camino de Villaverde", -1600, -1573 },
			{ "Norte (metro)", 0, -1550 },
		},
	},
} :: { LineDef }

BusLines.byId = {} :: { [string]: LineDef }
for _, line in BusLines.Lines do
	BusLines.byId[line.Id] = line
end

function BusLines.color(line: LineDef): Color3
	return Color3.fromRGB(line.Color[1], line.Color[2], line.Color[3])
end

-- Destino que se ve en el panel ("L1 → Playa Dorada") para la parada número k de la línea
function BusLines.headsign(line: LineDef, k: number): string
	return if k < line.Turn then line.Out else line.Back
end

---------------------------------------------------------------------
-- Plan: recorridos y paradas sobre las calles de verdad
---------------------------------------------------------------------

export type Road = { A: Vector3, B: Vector3, Width: number?, Kind: string? }
export type StopInfo = {
	Id: string,
	Name: string,
	Center: Vector3, -- en el centro de la calle
	Right: Vector3, -- hacia la acera de la parada
	Along: Vector3, -- sentido de la marcha
	Shelter: Vector3, -- dónde va la marquesina (Y = 0)
	Width: number, -- ancho de la calzada
	Walk: number, -- ancho de la acera
	Lines: { string },
}
export type LineStop = { Id: string, S: number, Index: number, Headsign: string }
export type LinePlan = {
	Id: string,
	Name: string,
	Color: Color3,
	Buses: number,
	Route: { Vector3 },
	Cum: { number },
	Total: number,
	Stops: { LineStop },
}
export type Plan = { Stops: { [string]: StopInfo }, Order: { string }, Lines: { LinePlan } }

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function rightOf(d: Vector3): Vector3
	return Vector3.new(-d.Z, 0, d.X)
end

-- Tramo más cercano a un punto
local function nearestRoad(roads: { Road }, p: Vector3): Road?
	local best, bestDist = nil, math.huge
	for _, r in roads do
		local a, b = flat(r.A), flat(r.B)
		local ab = b - a
		local len2 = ab:Dot(ab)
		if len2 > 1 then
			local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
			local dist = (a + ab * t - p).Magnitude
			if dist < bestDist then
				best, bestDist = r, dist
			end
		end
	end
	return best
end

-- Las calles de los barrios acaban un poco antes de las rotondas de la Ronda: se unen a su centro
local function withConnectors(roads: { Road }): { Road }
	local list = table.clone(roads)
	for _, rb in CityPlan.Roundabouts do
		local c = Vector3.new(rb[1], 0, rb[2])
		for _, r in roads do
			for _, e in { flat(r.A), flat(r.B) } do
				local d = (e - c).Magnitude
				if d > 3 and d < 60 then
					table.insert(list, { A = e, B = c, Width = r.Width or 24, Kind = r.Kind })
				end
			end
		end
	end
	return list
end

local function roundaboutAt(p: Vector3): Vector3?
	for _, rb in CityPlan.Roundabouts do
		local c = Vector3.new(rb[1], 0, rb[2])
		if (flat(p) - c).Magnitude < 4 then
			return c
		end
	end
	return nil
end

-- Camino más corto de `from` a `to` sin dar media vuelta (tampoco al salir: `prev` es el nodo
-- del que venía el autobús). Solo en una calle sin salida se permite dar la vuelta.
-- Devuelve los nodos del camino (de from a to) o nil.
function BusLines.path(graph: BusRoute.Graph, from: number, to: number, prev: number?): { number }?
	local edges = graph.Edges
	local n = #graph.Nodes
	-- Estado = (nodo anterior, nodo): clave anterior * (n + 1) + nodo
	local dist: { [number]: number } = {}
	local back: { [number]: number } = {}
	local start = (prev or 0) * (n + 1) + from
	dist[start] = 0
	local heap = { { 0, start } }
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
			heap[1] = last :: any
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
	local done: { [number]: boolean } = {}
	local goal: number? = nil
	while #heap > 0 do
		local item = pop()
		local key = item[2]
		if not done[key] then
			done[key] = true
			local u = key % (n + 1)
			local p = key // (n + 1)
			if u == to and key ~= start then
				goal = key
				break
			elseif u == to and from == to then
				goal = key
				break
			end
			local list = edges[u]
			for _, e in list do
				-- Media vuelta: solo si es una calle sin salida
				if e.To ~= p or #list == 1 then
					local nk = u * (n + 1) + e.To
					local alt = dist[key] + e.Cost + (if e.To == p then 400 else 0)
					if dist[nk] == nil or alt < dist[nk] then
						dist[nk] = alt
						back[nk] = key
						push({ alt, nk })
					end
				end
			end
		end
	end
	if not goal then
		return nil
	end
	local out = {}
	local key: number? = goal
	while key do
		table.insert(out, 1, key % (n + 1))
		key = back[key]
	end
	return out
end

-- Carril derecho de un circuito cerrado, dando la vuelta por fuera de la isla en las rotondas.
-- Devuelve los puntos y, para cada punto del centro, su índice en el carril.
function BusLines.lane(center: { Vector3 }, offset: number): ({ Vector3 }, { number })
	local lane = BusRoute.lane(center, offset)
	local out, map = {}, {}
	local n = #center
	for i, p in center do
		local c = if n >= 3 then roundaboutAt(p) else nil
		local din, dout
		if c then
			din = flat(c - center[if i > 1 then i - 1 else n])
			dout = flat(center[if i < n then i + 1 else 1] - c)
		end
		if c and din.Magnitude > 1 and dout.Magnitude > 1 then
			din, dout = din.Unit, dout.Unit
			local R = BusLines.ArcRadius
			local e = -din * R + rightOf(din) * offset
			local x = dout * R + rightOf(dout) * offset
			local fe, fx = math.atan2(e.Z, e.X), math.atan2(x.Z, x.X)
			-- Se gira dejando la isla a la izquierda (el ángulo baja)
			local sweep = (fe - fx) % (2 * math.pi)
			if sweep < 0.05 then
				sweep += 2 * math.pi
			end
			local steps = math.max(2, math.ceil(sweep / math.rad(15)))
			map[i] = #out + 1 + steps // 2
			for k = 0, steps do
				local f = fe - sweep * k / steps
				table.insert(out, c + Vector3.new(math.cos(f), 0, math.sin(f)) * R)
			end
		else
			table.insert(out, lane[i])
			map[i] = #out
		end
	end
	return out, map
end

-- Calcula toda la red sobre estas calles (las de ReplicatedStorage.Ambient.Roads, en su orden)
function BusLines.plan(roads: { Road }, lines: { LineDef }?): Plan
	local defs = lines or BusLines.Lines
	local all = withConnectors(roads)
	local anchors: { Vector3 } = {}
	for _, line in defs do
		for _, s in line.Stops do
			table.insert(anchors, Vector3.new(s[2], 0, s[3]))
		end
	end
	local graph = BusRoute.graph(all, anchors)
	local plan: Plan = { Stops = {}, Order = {}, Lines = {} }
	local base = 0
	for _, line in defs do
		local count = #line.Stops
		-- Tramos entre paradas seguidas sin dar media vuelta. Dos pasadas: en la segunda, la salida
		-- de la primera parada ya sabe por dónde llega el autobús al cerrar la vuelta.
		local legs: { { number } } = {}
		local arrive: number? = nil
		for _ = 1, 2 do
			local prev = arrive
			for k = 1, count do
				local from = graph.StopNodes[base + k]
				local to = graph.StopNodes[base + (k % count) + 1]
				local piece = if from and to then BusLines.path(graph, from, to, prev) else nil
				legs[k] = piece or { from, to }
				prev = if piece and #piece >= 2 then piece[#piece - 1] else nil
			end
			arrive = prev
		end
		local center: { Vector3 } = {}
		local marks: { [number]: number } = {}
		for k = 1, count do
			local piece = legs[k]
			marks[k] = #center + 1
			for j, id in piece do
				if j < #piece then
					local p = graph.Nodes[id]
					-- (dos cruces casi pegados hacen un zigzag: se queda solo el primero)
					local gap = if #center == 0 then math.huge else (center[#center] - p).Magnitude
					if gap > 12 or (j == 1 and gap > 0.5) then
						table.insert(center, p)
					elseif j == 1 then
						marks[k] = #center
					end
				end
			end
		end
		local route, map = BusLines.lane(center, BusLines.Lane)
		for i, p in route do
			route[i] = Vector3.new(p.X, 0.4, p.Z)
		end
		local cum = { 0 }
		for i = 2, #route do
			cum[i] = cum[i - 1] + (route[i] - route[i - 1]).Magnitude
		end
		local total = if #route > 1 then cum[#route] + (route[1] - route[#route]).Magnitude else 0
		local linePlan: LinePlan = {
			Id = line.Id,
			Name = line.Name,
			Color = BusLines.color(line),
			Buses = line.Buses,
			Route = route,
			Cum = cum,
			Total = total,
			Stops = {},
		}
		for k = 1, count do
			local ci = marks[k]
			local name = tostring(line.Stops[k][1])
			if ci and name ~= "via" and #center > 1 then
				local p = center[ci]
				local dir = flat(center[ci % #center + 1] - p)
				if dir.Magnitude < 1 then
					dir = flat(p - center[if ci > 1 then ci - 1 else #center])
				end
				dir = dir.Unit
				local right = rightOf(dir)
				-- ¿Ya hay una parada aquí (de otra línea, en el mismo sentido)?
				local id: string? = nil
				for _, other in plan.Order do
					local info = plan.Stops[other]
					if (info.Center - p).Magnitude < 40 and info.Right:Dot(right) > 0.9 then
						id = other
						break
					end
				end
				if not id then
					local road = nearestRoad(all, p)
					local width = if road then road.Width or 24 else 24
					local walk = if road and road.Kind then BusLines.Walk[road.Kind] or 0 else BusLines.StreetWalk
					local newId = ("P%02d"):format(#plan.Order + 1)
					plan.Stops[newId] = {
						Id = newId,
						Name = name,
						Center = p,
						Right = right,
						Along = dir,
						Shelter = p + right * (width / 2 + walk - BusLines.ShelterDepth),
						Width = width,
						Walk = walk,
						Lines = {},
					}
					table.insert(plan.Order, newId)
					id = newId
				end
				local info = plan.Stops[id :: string]
				if not table.find(info.Lines, line.Id) then
					table.insert(info.Lines, line.Id)
				end
				local li = map[ci]
				table.insert(linePlan.Stops, { Id = id :: string, S = cum[li], Index = li, Headsign = BusLines.headsign(line, k) })
			end
		end
		table.insert(plan.Lines, linePlan)
		base += count
	end
	return plan
end

-- Las calles tal y como las publica el servidor (ReplicatedStorage.Ambient.Roads: Road1, Road2…),
-- en su orden: así el plan sale igual en el servidor y al construir la ciudad
function BusLines.roadsFrom(folder: Instance): { Road }
	local list = {}
	for _, config in folder:GetChildren() do
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
			local n = tonumber(string.match(config.Name, "%d+$")) or 0
			table.insert(list, { N = n, A = a, B = b, Width = config:GetAttribute("Width") or 24, Kind = config:GetAttribute("Kind") })
		end
	end
	table.sort(list, function(x, y)
		return x.N < y.N
	end)
	local roads: { Road } = {}
	for _, r in list do
		table.insert(roads, { A = r.A, B = r.B, Width = r.Width, Kind = r.Kind })
	end
	return roads
end

---------------------------------------------------------------------
-- Recorrido: punto a una distancia s y distancia de un punto
---------------------------------------------------------------------

function BusLines.pointAt(line: LinePlan, s: number): (Vector3, Vector3)
	local route, cum = line.Route, line.Cum
	s = s % line.Total
	local lo, hi = 1, #route
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if cum[mid] <= s then
			lo = mid
		else
			hi = mid
		end
	end
	if cum[hi] <= s then
		lo = hi
	end
	local a = route[lo]
	local b = route[if lo < #route then lo + 1 else 1]
	local seg = (b - a).Magnitude
	local t = if seg > 0 then math.clamp((s - cum[lo]) / seg, 0, 1) else 0
	local dir = if seg > 0 then (b - a).Unit else Vector3.new(0, 0, -1)
	return a + (b - a) * t, dir
end

-- Distancia s del punto del recorrido más cercano a p (y a cuántos studs está)
function BusLines.project(line: LinePlan, p: Vector3): (number, number)
	local route, cum = line.Route, line.Cum
	local bestS, bestD = 0, math.huge
	local q = flat(p)
	for i, a in route do
		local b = route[if i < #route then i + 1 else 1]
		local fa, fb = flat(a), flat(b)
		local ab = fb - fa
		local len2 = ab:Dot(ab)
		local t = if len2 > 0 then math.clamp((q - fa):Dot(ab) / len2, 0, 1) else 0
		local d = (fa + ab * t - q).Magnitude
		if d < bestD then
			bestD, bestS = d, cum[i] + math.sqrt(len2) * t
		end
	end
	return bestS, bestD
end

---------------------------------------------------------------------
-- Tiempos de llegada
---------------------------------------------------------------------

-- Segundos hasta que un autobús que va por busS (y aún espera `wait` s en su parada) llega a la
-- parada que está en stopS. stops = las S de todas las paradas de la línea (en cada parada
-- intermedia espera `dwell` s). speed = velocidad media en marcha (studs/s).
function BusLines.eta(total: number, busS: number, stopS: number, stops: { number }, speed: number, dwell: number, wait: number?): number
	local d = (stopS - busS) % total
	if d < 0.5 or total - d < 0.5 then
		return wait or 0
	end
	local between = 0
	for _, s in stops do
		local ds = (s - busS) % total
		if ds > 0.5 and ds < d - 0.5 then
			between += 1
		end
	end
	return (wait or 0) + d / speed + between * dwell
end

-- Texto del tiempo en el panel: "En parada", "Llegando" o "3 min"
function BusLines.formatEta(seconds: number, atStop: boolean?): string
	if atStop then
		return "En parada"
	elseif seconds < 30 then
		return "Llegando"
	end
	return ("%d min"):format(math.max(1, math.floor(seconds / 60 + 0.5)))
end

-- El panel de una parada viaja en un atributo de texto: "L2|Valmar Norte|180|0;L1|Playa Dorada|12|1"
-- (línea, destino, segundos, 1 = está en la parada con las puertas abiertas)
export type Arrival = { Line: string, Headsign: string, Seconds: number, AtStop: boolean }

function BusLines.encodeBoard(list: { Arrival }): string
	local parts = {}
	for _, a in list do
		table.insert(parts, ("%s|%s|%d|%d"):format(a.Line, a.Headsign, math.floor(a.Seconds + 0.5), if a.AtStop then 1 else 0))
	end
	return table.concat(parts, ";")
end

function BusLines.decodeBoard(text: string?): { Arrival }
	local list = {}
	for entry in string.gmatch(text or "", "[^;]+") do
		local line, headsign, seconds, at = string.match(entry, "^([^|]*)|([^|]*)|(%d+)|(%d)$")
		if line then
			table.insert(list, { Line = line, Headsign = headsign, Seconds = tonumber(seconds) or 0, AtStop = at == "1" })
		end
	end
	return list
end

-- Una línea del panel: "L2 → Valmar Norte · 3 min"
function BusLines.boardText(a: Arrival): string
	return ("%s → %s · %s"):format(a.Line, a.Headsign, BusLines.formatEta(a.Seconds, a.AtStop))
end

return BusLines
