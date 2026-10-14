-- Rail: el tren de Cercanías de Valmar, en superficie (RailKit lo construye, RailService lo mueve,
-- RailUI lo enseña y Controllers/MetroTrains lo mueve en cada pantalla, igual que el metro).
--
-- Una línea, la C1, que va por las afueras del norte y baja por la orilla este del río:
--
--   Villaverde ── Valmar Norte ──┐     ┌── Los Pinos ──╮ (puente sobre el río)
--                                └─────┘ (paso a nivel en la Avenida del Norte)
--                                                      │ orilla este
--                                                    Levante (paso a nivel en la Avenida del Este)
--                                                      │
--                                                    Campus
--
-- La vía va por el campo (sin tocar manzanas): donde cruza una calle hay un paso a nivel con barreras
-- y luces (el asfalto sigue entero: los carriles van encastrados). Cada estación tiene andén, marquesina,
-- máquina de billetes, panel de salidas y carteles, y una rampa que baja a la acera de al lado.
-- Las cuentas del movimiento (acelerar, frenar, cuándo llega) son las del metro (Shared/Metro).

-- (el metro, al lado; si quien carga los módulos no da script.Parent, por ReplicatedStorage)
local Metro = (function()
	local ok, m = pcall(function()
		return require(script.Parent.Metro)
	end)
	if ok and m then
		return m
	end
	return require(game:GetService("ReplicatedStorage").Shared.Metro)
end)()

local Rail = {}

local rgb = Color3.fromRGB

export type Station = {
	Id: string,
	Name: string,
	At: { number }, -- centro del andén (X, Z) sobre la vía
	Side: { number }, -- hacia dónde queda el andén (X, Z), en horizontal
	Access: { Z: number, Path: { { number } }? }, -- rampa (Z en el marco de la estación) y camino a la acera
	District: string,
	Serves: { string },
}

Rail.Line = {
	Id = "C1",
	Name = "Cercanías C1",
	Color = rgb(206, 32, 52),
	Stations = { "Villaverde", "ValmarNorte", "LosPinos", "Levante", "Campus" },
}
Rail.Lines = { Rail.Line }

-- Trazado de la vía: esquinas (X, Z) y el radio de la curva en cada una (Y = altura del andén)
Rail.Route = {
	{ -2840, -2280, 0 },
	{ -2400, -2280, 150 },
	{ -2260, -2425, 150 },
	{ -1000, -2425, 200 }, -- sube por encima de las manzanas de la Avenida del Norte
	{ -760, -2652, 200 },
	{ 620, -2652, 200 },
	{ 860, -2425, 200 },
	{ 1740, -2425, 250 }, -- después del puente, gira hacia el sur por la orilla este
	{ 1740, 1240, 0 },
}

-- Estaciones. Side: hacia dónde está el andén. Access.Z: dónde baja la rampa (a lo largo del andén, en
-- el marco de la estación: -Z hacia delante). La rampa llega a 30 studs de la vía: en las tres primeras
-- es justo el borde de la acera de la calle de al lado; en las otras dos sigue un camino hasta la acera.
Rail.Stations = {
	Villaverde = {
		Id = "Villaverde", Name = "Villaverde", At = { -2700, -2280 }, Side = { 0, 1 }, Access = { Z = 0 },
		District = "Oeste", Serves = { "Villaverde", "Granjas", "Cooperativa" },
	},
	ValmarNorte = {
		Id = "ValmarNorte", Name = "Valmar Norte", At = { -1175, -2425 }, Side = { 0, 1 }, Access = { Z = 0 },
		District = "Norte", Serves = { "Valmar Norte", "Colegio", "Hospital" },
	},
	LosPinos = {
		Id = "LosPinos", Name = "Los Pinos", At = { 1020, -2425 }, Side = { 0, 1 }, Access = { Z = 0 },
		District = "Norte", Serves = { "Los Pinos", "Casas familiares", "Parque" },
	},
	Levante = {
		Id = "Levante", Name = "Levante", At = { 1740, -120 }, Side = { 1, 0 }, Access = { Z = 60, Path = { { 1773, -63 }, { 1773, -20.5 } } },
		District = "Este", Serves = { "Zona comercial", "Metro Levante", "Playa Dorada (en metro)" },
	},
	Campus = {
		Id = "Campus", Name = "Campus", At = { 1740, 1150 }, Side = { 1, 0 }, Access = { Z = 55, Path = { { 1773, 1202 }, { 1773, 1270 } } },
		District = "Universitario", Serves = { "Campus Valmar", "Facultades", "Metro Campus" },
	},
} :: { [string]: Station }

-- Medidas (studs)
Rail.Deck = 4 -- suelo de los coches = altura del andén (la vía va a ras del suelo)
Rail.RailTop = 0.85 -- cara de arriba de los carriles
Rail.Gauge = 4.6 -- entre los dos carriles
Rail.PlatformLength = 150
Rail.PlatformGap = 5.4 -- del centro de la vía al borde del andén
Rail.PlatformWidth = 10
Rail.RampReach = 30 -- de la vía al pie de la rampa (el borde de la acera)
Rail.RampWidth = 8
Rail.WalkY = 1 -- altura de la acera y del camino
Rail.CarLength = 34
Rail.CarGap = 2
Rail.Cars = 3
Rail.CarWidth = 9
Rail.Speed = 120 -- studs/s de crucero (acelera y frena como el metro: Metro.Accel)
Rail.Dwell = 16 -- segundos con las puertas abiertas en cada estación
Rail.Layover = 20 -- descanso en las cabeceras
Rail.CrossingWarn = 9 -- segundos antes de que llegue el tren se bajan las barreras
Rail.Clearance = 7 -- media anchura de la vía despejada (nada encima)

-- Billetes (máquinas rojas de los andenes). Los abonos del metro también valen en el tren.
Rail.TicketItem = "BilleteTren"
Rail.Tickets = {
	{ Id = "Sencillo", Name = "Billete de Cercanías", Icon = "🎫", Price = 3, Count = 1 },
	{ Id = "Bono10", Name = "Bono Cercanías (10 viajes)", Icon = "🎟️", Price = 24, Count = 10 },
}
Rail.FreeStages = Metro.FreeStages -- los bebés y los niños no pagan
Rail.FreeJobs = Metro.FreeJobs -- de servicio, gratis
Rail.Fine = 20 -- multa del revisor si viajas sin billete

---------------------------------------------------------------------
-- Geometría (la usan RailKit, RailService, los clientes y las pruebas: así coinciden)
---------------------------------------------------------------------

-- Esquina redondeada: los puntos del arco entre dos tramos rectos (cada ~10 studs)
local function fillet(a: Vector3, b: Vector3, c: Vector3, r: number): { Vector3 }
	local d1, d2 = (b - a).Unit, (c - b).Unit
	local cosang = math.clamp(d1:Dot(d2), -1, 1)
	local theta = math.acos(cosang)
	if theta < 1e-3 or r <= 0 then
		return { b }
	end
	local t = r * math.tan(theta / 2)
	local p1 = b - d1 * t
	local cross = d1.X * d2.Z - d1.Z * d2.X
	local n = if cross > 0 then Vector3.new(-d1.Z, 0, d1.X) else Vector3.new(d1.Z, 0, -d1.X)
	local center = p1 + n * r
	local a0 = math.atan2(p1.Z - center.Z, p1.X - center.X)
	local steps = math.max(2, math.ceil(theta * r / 10))
	local sign = if cross > 0 then 1 else -1
	local list = {}
	for k = 0, steps do
		local ang = a0 + sign * theta * k / steps
		table.insert(list, Vector3.new(center.X + math.cos(ang) * r, a.Y, center.Z + math.sin(ang) * r))
	end
	return list
end

local pathCache: { Points: { Vector3 }, Centers: { number }, Length: number }? = nil

-- Recorrido de la vía a la altura del andén (Y = Rail.Deck): puntos, distancia del recorrido del centro
-- de cada estación (en el orden de la línea) y largo total
function Rail.path(): ({ Vector3 }, { number }, number)
	local cached = pathCache
	if cached then
		return cached.Points, cached.Centers, cached.Length
	end
	local corners = {}
	for _, c in Rail.Route do
		table.insert(corners, Vector3.new(c[1], Rail.Deck, c[2]))
	end
	local points = { corners[1] }
	for i = 2, #corners - 1 do
		for _, p in fillet(corners[i - 1], corners[i], corners[i + 1], Rail.Route[i][3]) do
			if (p - points[#points]).Magnitude > 0.05 then
				table.insert(points, p)
			end
		end
	end
	table.insert(points, corners[#corners])
	local length = 0
	for i = 1, #points - 1 do
		length += (points[i + 1] - points[i]).Magnitude
	end
	local centers = {}
	for i, id in Rail.Line.Stations do
		centers[i] = Rail.project(points, Rail.center(id))
	end
	pathCache = { Points = points, Centers = centers, Length = length }
	return points, centers, length
end

-- Distancia del recorrido del punto de la vía más cercano a p (en horizontal)
function Rail.project(points: { Vector3 }, p: Vector3): number
	local best, bestS = math.huge, 0
	local walked = 0
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = ab.Magnitude
		if len > 0 then
			local t = math.clamp(Vector3.new(p.X - a.X, 0, p.Z - a.Z):Dot(ab) / (len * len), 0, 1)
			local q = Vector3.new(a.X + ab.X * t, 0, a.Z + ab.Z * t)
			local d = (Vector3.new(p.X, 0, p.Z) - q).Magnitude
			if d < best then
				best, bestS = d, walked + len * t
			end
		end
		walked += len
	end
	return bestS
end

-- Distancia (en horizontal) de un punto a la vía y la distancia del recorrido de ese punto
function Rail.distance(p: Vector3): (number, number)
	local points = Rail.path()
	local s = Rail.project(points, p)
	local q = Rail.sample(points, s)
	return (Vector3.new(p.X - q.X, 0, p.Z - q.Z)).Magnitude, s
end

Rail.sample = Metro.sample -- punto y dirección a una distancia s del recorrido
Rail.positionAt = Metro.positionAt -- dónde va el centro del tren según su estado publicado
Rail.travelTime = Metro.travelTime -- segundos de un tramo (arranca, va a crucero y frena)
Rail.travelled = Metro.travelled -- lo recorrido a los t segundos de un tramo

function Rail.center(stationId: string): Vector3
	local st = Rail.Stations[stationId]
	return Vector3.new(st.At[1], Rail.Deck, st.At[2])
end

-- Marco de una estación: en el centro del andén a ras del suelo (Y = 0), X hacia el andén, -Z a lo
-- largo de la vía. (Un giro en Y y no CFrame.lookAt: en Lune sale mal hacia +Z.)
function Rail.frame(stationId: string): CFrame
	local st = Rail.Stations[stationId]
	local n = Vector3.new(st.Side[1], 0, st.Side[2]).Unit
	local dir = Vector3.new(n.Z, 0, -n.X) -- (así la derecha del marco es el andén)
	return CFrame.new(st.At[1], 0, st.At[2]) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
end

-- Del andén a la acera, andando: pie de la rampa, arriba de la rampa, centro del andén y los puntos
-- del camino hasta la acera (Route va de la acera al andén). Todo en coordenadas del mundo.
function Rail.access(stationId: string): { [string]: any }
	local st = Rail.Stations[stationId]
	local f = Rail.frame(stationId)
	local z = st.Access.Z
	local edge = Rail.PlatformGap + Rail.PlatformWidth
	local top = (f * CFrame.new(edge - 1, Rail.Deck, z)).Position
	local bottom = (f * CFrame.new(Rail.RampReach, Rail.WalkY, z)).Position
	local platform = (f * CFrame.new(Rail.PlatformGap + Rail.PlatformWidth / 2, Rail.Deck, 0)).Position
	local route = {}
	local path = st.Access.Path
	if path then
		for i = #path, 1, -1 do
			table.insert(route, Vector3.new(path[i][1], Rail.WalkY, path[i][2]))
		end
	else
		table.insert(route, (f * CFrame.new(Rail.RampReach + 1.5, Rail.WalkY, z)).Position)
	end
	table.insert(route, bottom)
	table.insert(route, top)
	table.insert(route, (f * CFrame.new(Rail.PlatformGap + Rail.PlatformWidth / 2, Rail.Deck, z)).Position) -- (por el medio del andén)
	table.insert(route, platform)
	return { Sidewalk = route[1], RampBottom = bottom, RampTop = top, Platform = platform, Route = route, Frame = f }
end

-- Dónde se entra a la estación desde la calle (para el GPS y el mapa)
function Rail.entrance(stationId: string): Vector3
	return Rail.access(stationId).Sidewalk
end

-- Estación más cercana a un punto (por su entrada): id y distancia en studs
function Rail.nearestStation(position: Vector3): (string?, number)
	local best, bestD = nil, math.huge
	for id in Rail.Stations do
		local p = Rail.entrance(id)
		local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
		if d < bestD then
			best, bestD = id, d
		end
	end
	return best, bestD
end

---------------------------------------------------------------------
-- Cuándo llega el tren (paneles y planificador): las cuentas del metro con los datos del tren
---------------------------------------------------------------------
Rail.eta = Metro.eta
Rail.nextStop = Metro.nextStop

function Rail.stationName(id: string): string
	local st = Rail.Stations[id]
	return if st then st.Name else id
end

-- Texto del panel de salidas: "C1 → Campus · 2 min", "LLEGANDO", "EN ANDÉN"
function Rail.boardText(seconds: number, towardIndex: number, dwellLeft: number?): string
	local line = Rail.Line
	local toward = Rail.stationName(line.Stations[towardIndex])
	if seconds <= 0 then
		return ("🚆 %s → %s · EN ANDÉN · sale en %d s"):format(line.Id, toward, math.max(0, math.ceil(dwellLeft or 0)))
	elseif seconds <= 20 then
		return ("🚆 %s → %s · LLEGANDO"):format(line.Id, toward)
	elseif seconds < 60 then
		return ("🚆 %s → %s · %d s"):format(line.Id, toward, math.ceil(seconds))
	end
	return ("🚆 %s → %s · %d min"):format(line.Id, toward, math.ceil(seconds / 60))
end

function Rail.announceNext(stationId: string): string
	local text = "Próxima estación: " .. Rail.stationName(stationId) .. "."
	if stationId == "Levante" or stationId == "Campus" then
		text ..= " Correspondencia con el metro."
	end
	return text
end
Rail.AnnounceDoors = "Atención: cierre de puertas."
function Rail.announceArriving(towardName: string): string
	return ("Tren de Cercanías con destino %s. Por favor, no rebasen la línea amarilla."):format(towardName)
end

-- Medio tren (del centro a la punta)
function Rail.halfTrain(): number
	return (Rail.CarLength * Rail.Cars + Rail.CarGap * (Rail.Cars - 1)) / 2
end

-- ¿Está cerrado el paso a nivel que está en crossS del recorrido? state = lo que publica RailService
-- ({ Phase, S, From, To, T0, Duration, Speed, DwellEnd }). Se cierra mientras el tren lo pisa, unos
-- segundos antes de que llegue (solo si va hacia él) y justo antes de salir de un andén que está al lado.
function Rail.crossingClosed(state: { [string]: any }, crossS: number, now: number): boolean
	local half = Rail.halfTrain() + 6
	local s = Metro.positionAt(state, now)
	if math.abs(s - crossS) < half then
		return true
	end
	if state.Phase == "Move" then
		local dir = if (state.To or 0) >= (state.From or 0) then 1 else -1
		local ahead = (crossS - s) * dir
		local stop = ((state.To or 0) - s) * dir -- (lo que le queda hasta el andén)
		return ahead > 0 and ahead < half + (state.Speed or Rail.Speed) * Rail.CrossingWarn and ahead < stop + half
	end
	local left = (state.DwellEnd or 0) - now
	return left < 5 and math.abs(s - crossS) < half + 60
end

return Rail
