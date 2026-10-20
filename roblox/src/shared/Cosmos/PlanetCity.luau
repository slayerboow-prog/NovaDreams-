-- PlanetCity: el PLANO de un barrio de la capital de un planeta, hecho con DATOS (marco común,
-- docs/planetas/marco-planetas.md). Cuentas puras, como shared/Cosmos/TefraCity (Bastión Ceniza va a
-- mano; los demás planetas usan esto): PlanetCity.new(plan) devuelve un módulo con las MISMAS funciones
-- que TefraCity (inside, shape, footprint, door, topOf, buildingAt, solidTop, landingBlocked, walkable,
-- districtAt, landmarks, weather, shelterAt, nearestShelter, shelterInside, rescueSpot, StorySpots…).
-- Lo usan shared/Cosmos/PlanetSurface (aplanar la meseta, choques), World/PlanetCityBuilder (lo construye),
-- Services/PlanetService y PlanetHazardService (avisos y refugios), LifeStory/Locations (sitios de la
-- historia «<Planeta>_<Id>») y las pruebas.
--
-- Coordenadas LOCALES del planeta (lx, lz: studs desde su Origin; X = este, Z = sur). Altura: el barrio
-- está sobre una meseta llana a la altura de la plataforma (Base = S.padY(), la pasa quien llama).
--
--   plan = {
--     Id, Name, Planet, KeyPrefix («Miasma_»: TODAS las claves empiezan así; nunca las de Valmar),
--     Rect = { X0, X1, Z0, Z1 }   el borde del barrio (dentro, el suelo es la meseta)
--     Blend = 120                 de Rect a Rect+Blend el suelo baja (o sube) hasta el del planeta
--     GroundDrop = 0.6            el terreno queda justo por debajo de los suelos construidos
--     Floors = { { Id, Kind = "Rect" | "Disc", X0, X1, Z0, Z1 | X, Z, R, Material, Color } }
--                                 suelos por donde se anda (plazas, plataformas, calles de tierra)
--     Pits   = { { Kind = "Rect" | "Disc", …, Depth, Name } }  huecos (niebla, lava, simas): no se anda,
--                                 el terreno baja Depth y quien cae sale a la orilla (rescueSpot)
--     OpenGround = true           todo lo que no sea hueco ni edificio es andable (si no, solo Floors)
--     Void = { Depth, Text }      (plataformas en el aire: Miasma) dentro de Rect, lo que no es suelo es
--                                 vacío: el terreno no sube (se ve lo de abajo) y quien cae sale a la orilla
--     Districts = { { Id, Name, Theme, Icon, Color, Poly } }
--     Buildings = { { Id, District, Kind, Shape, Name, X, Z, W, D, R, Face, Floors, Style, Ground,
--                     Sign, ShopId, Info, Icon, Height, Enter } }   (Shape «Box» = Kit/Building con su planta
--                                 baja jugable; las demás formas las dibuja el kit del planeta)
--     Spots, StorySpots = { { Id, Name, X, Z, Y?, Inside?, Outside?, Radius? } }, Shelters = { [Id] = { Cool, Name } },
--     Lamps = { { X, Z } }, Crowd = { { Group, X, Z, FX, FZ, Work?, Sit? } }, Areas = { { X0, X1, Z0, Z1 } },
--     Gather = { { Id, Name, X, Z, Item, Every } }  recoger el material del planeta (aviso «Recoger»)
--     Weather = function(clock) → { Id, Name, Icon, Temp }
--   }

local PlanetCity = {}

local FACE = { N = { 0, -1 }, S = { 0, 1 }, E = { 1, 0 }, W = { -1, 0 } }
PlanetCity.FaceDir = FACE

local function smooth(e0: number, e1: number, x: number): number
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

local function pointIn(poly: { { number } }, x: number, z: number): boolean
	local inside = false
	local j = #poly
	for i = 1, #poly do
		local xi, zi = poly[i][1], poly[i][2]
		local xj, zj = poly[j][1], poly[j][2]
		if (zi > z) ~= (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end
PlanetCity.pointIn = pointIn

-- Huella de un edificio (las mismas reglas que TefraCity.footprint): x0, x1, z0, z1
function PlanetCity.footprint(b: { [string]: any }): (number, number, number, number)
	if b.R and not b.W then
		local r = b.R
		return b.X - r, b.X + r, b.Z - r, b.Z + r
	end
	local w, d = b.W or 10, b.D or 10
	local sx, sz = w, d
	if b.Face == "E" or b.Face == "W" then
		sx, sz = d, w
	end
	return b.X - sx / 2, b.X + sx / 2, b.Z - sz / 2, b.Z + sz / 2
end

-- La puerta de un edificio con planta baja (Box): (x, z) en la fachada y la dirección hacia fuera
function PlanetCity.door(b: { [string]: any }): (number?, number?, { number }?)
	if b.Shape ~= "Box" or b.Ground == "Closed" then
		return nil, nil, nil
	end
	local f = FACE[b.Face or "N"]
	local d = b.D or 10
	return b.X + f[1] * d / 2, b.Z + f[2] * d / 2, f
end

-- Altura de lo de arriba (studs sobre Base), para los choques de la nave
function PlanetCity.topOf(b: { [string]: any }): number
	if b.Shape == "Box" then
		local floors = b.Floors or 1
		local ground = if b.Ground == "Shop" then 15 elseif b.Ground == "House" then 11 elseif b.Ground == "Garage" then 16 else 13
		local fh = if b.Ground == "House" then 10 else 12
		return 1 + ground + (floors - 1) * fh + 2.4 + (b.RoofExtra or 0)
	elseif b.Shape == "Court" then
		return 1
	end
	return b.Height or 10
end

local function inShape(s: { [string]: any }, lx: number, lz: number, margin: number?): boolean
	local m = margin or 0
	if s.Kind == "Disc" then
		return (lx - s.X) ^ 2 + (lz - s.Z) ^ 2 <= (s.R + m) ^ 2
	end
	return lx >= s.X0 - m and lx <= s.X1 + m and lz >= s.Z0 - m and lz <= s.Z1 + m
end
PlanetCity.inShape = inShape

function PlanetCity.new(plan: { [string]: any }): { [string]: any }
	local C: { [string]: any } = {}
	for k, v in plan do
		C[k] = v
	end
	C.KeyPrefix = plan.KeyPrefix or (plan.Planet .. "_")
	C.Blend = plan.Blend or 120
	C.Bank = plan.Bank or 8
	C.GroundDrop = plan.GroundDrop or 0.6
	C.Floors = plan.Floors or {}
	C.Pits = plan.Pits or {}
	C.Districts = plan.Districts or {}
	C.Streets = plan.Streets or {}
	C.Spots = plan.Spots or {}
	C.StorySpots = plan.StorySpots or {}
	C.Shelters = plan.Shelters or {}
	C.Gather = plan.Gather or {}
	C.Lamps = plan.Lamps or {}
	C.Crowd = plan.Crowd or {}
	C.Areas = plan.Areas or {}
	C.RoadHalf = plan.RoadHalf or 20
	C.pointIn = pointIn
	C.footprint = PlanetCity.footprint
	C.door = PlanetCity.door
	C.topOf = PlanetCity.topOf
	C.FaceDir = FACE

	-- Claves con el prefijo del planeta
	local list = {}
	for _, b in plan.Buildings or {} do
		local nb = table.clone(b)
		if string.sub(nb.Id, 1, #C.KeyPrefix) ~= C.KeyPrefix then
			nb.Id = C.KeyPrefix .. nb.Id
		end
		table.insert(list, nb)
	end
	C.Buildings = list
	C.BuildingById = {}
	for _, b in list do
		C.BuildingById[b.Id] = b
	end
	local shelters = {}
	for id, s in C.Shelters do
		shelters[if string.sub(id, 1, #C.KeyPrefix) == C.KeyPrefix then id else C.KeyPrefix .. id] = s
	end
	C.Shelters = shelters
	C.DistrictById = {}
	for _, d in C.Districts do
		C.DistrictById[d.Id] = d
	end
	C.SpotById = {}
	for _, s in C.Spots do
		C.SpotById[s.Id] = s
	end
	C.StorySpotById = {}
	for _, s in C.StorySpots do
		C.StorySpotById[s.Id] = s
	end
	C.GatherById = {}
	for _, g in C.Gather do
		C.GatherById[g.Id] = g
	end

	-- Distancia (con signo) al rectángulo del barrio: negativa dentro
	function C.rectDistance(lx: number, lz: number): number
		local R = C.Rect
		local dx = math.max(R.X0 - lx, 0, lx - R.X1)
		local dz = math.max(R.Z0 - lz, 0, lz - R.Z1)
		if dx == 0 and dz == 0 then
			return -math.min(lx - R.X0, R.X1 - lx, lz - R.Z0, R.Z1 - lz)
		end
		return math.sqrt(dx * dx + dz * dz)
	end
	function C.inside(lx: number, lz: number, margin: number?): boolean
		return C.rectDistance(lx, lz) <= (margin or 0)
	end

	-- ¿Un hueco (niebla, lava, sima)? → el hueco
	local voidPit = if plan.Void then { Kind = "Void", Depth = plan.Void.Depth or 60, Text = plan.Void.Text, Name = plan.Void.Name or "El vacío" } else nil
	C.VoidPit = voidPit
	function C.pitAt(lx: number, lz: number): { [string]: any }?
		for _, p in C.Pits do
			if inShape(p, lx, lz) then
				return p
			end
		end
		if voidPit and C.inside(lx, lz, 0) and not C.floorAt(lx, lz) then
			return voidPit
		end
		return nil
	end
	function C.inPit(lx: number, lz: number): boolean
		return C.pitAt(lx, lz) ~= nil
	end
	C.inLava = C.inPit -- (el mismo nombre que TefraCity, para quien ya lo usa)

	-- El suelo construido en (lx, lz), o nil
	function C.floorAt(lx: number, lz: number): { [string]: any }?
		for _, f in C.Floors do
			if inShape(f, lx, lz) then
				return f
			end
		end
		return nil
	end

	-- La forma del suelo: meseta llana dentro del barrio, huecos hundidos y la bajada al planeta
	function C.shape(lx: number, lz: number, h: number, base: number): number
		local d = C.rectDistance(lx, lz)
		if d > C.Blend then
			return h
		end
		local ground = base - C.GroundDrop
		if d <= C.Bank then
			local pit = C.pitAt(lx, lz)
			if pit == voidPit and pit then
				return math.min(h, base - pit.Depth) -- (el vacío: el terreno de abajo, nunca más alto)
			elseif pit then
				return base - (pit.Depth or 30)
			end
			return ground
		end
		local w = smooth(C.Blend, C.Bank, d)
		return h + (ground - h) * w
	end

	-- La calle más cercana (si el barrio tiene calles de Kit/Street): distancia al eje y la calle
	function C.streetDistance(lx: number, lz: number): (number, any)
		local best, which = math.huge, nil
		for _, s in C.Streets do
			local along = if s.Axis == "X" then lx else lz
			local across = if s.Axis == "X" then lz else lx
			local u = math.clamp(along, s.From, s.To)
			local dd = math.sqrt((along - u) ^ 2 + (across - s.At) ^ 2)
			if dd < best then
				best, which = dd, s
			end
		end
		return best, which
	end

	-- Rejilla de 40 studs con los edificios de cada celda
	local CELL = 40
	local grid: { [number]: { any } }? = nil
	local function cellKey(i: number, k: number): number
		return (i + 1000) * 4096 + (k + 1000)
	end
	local function buildGrid()
		local g = {}
		for _, b in list do
			if b.Shape ~= "Court" then
				local x0, x1, z0, z1 = C.footprint(b)
				for i = math.floor(x0 / CELL), math.floor(x1 / CELL) do
					for k = math.floor(z0 / CELL), math.floor(z1 / CELL) do
						local key = cellKey(i, k)
						g[key] = g[key] or {}
						table.insert(g[key], b)
					end
				end
			end
		end
		return g
	end
	function C.buildingAt(lx: number, lz: number, margin: number?): { [string]: any }?
		if not C.inside(lx, lz, 10 + (margin or 0)) then
			return nil
		end
		grid = grid or buildGrid()
		local m = margin or 0
		for i = math.floor((lx - m) / CELL), math.floor((lx + m) / CELL) do
			for k = math.floor((lz - m) / CELL), math.floor((lz + m) / CELL) do
				for _, b in (grid :: any)[cellKey(i, k)] or {} do
					local x0, x1, z0, z1 = C.footprint(b)
					if lx >= x0 - m and lx <= x1 + m and lz >= z0 - m and lz <= z1 + m then
						return b
					end
				end
			end
		end
		return nil
	end
	function C.solidTop(lx: number, lz: number, margin: number?): number?
		local b = C.buildingAt(lx, lz, margin or 0)
		if b then
			return C.topOf(b)
		end
		return nil
	end
	function C.landingBlocked(lx: number, lz: number): boolean
		if not C.inside(lx, lz, C.Bank) then
			return false
		end
		if C.inPit(lx, lz) then
			return true
		end
		return C.solidTop(lx, lz, 10) ~= nil
	end

	-- ¿Se anda por aquí a la altura del barrio?
	function C.walkable(lx: number, lz: number): boolean
		if not C.inside(lx, lz, C.Bank) or C.inPit(lx, lz) then
			return false
		end
		if C.floorAt(lx, lz) then
			return true
		end
		if #C.Streets > 0 and C.streetDistance(lx, lz) <= C.RoadHalf then
			return true
		end
		return plan.OpenGround == true and C.inside(lx, lz, 0)
	end

	function C.districtAt(lx: number, lz: number): { [string]: any }?
		if not C.inside(lx, lz, 0) then
			return nil
		end
		for _, d in C.Districts do
			if pointIn(d.Poly, lx, lz) then
				return d
			end
		end
		return C.Districts[1]
	end

	-- Refugios (dentro de su planta baja, a más de un stud de las paredes)
	function C.shelterAt(lx: number, lz: number): (string?, { [string]: any }?)
		local b = C.buildingAt(lx, lz, 0)
		if b and C.Shelters[b.Id] then
			local x0, x1, z0, z1 = C.footprint(b)
			if lx > x0 + 1 and lx < x1 - 1 and lz > z0 + 1 and lz < z1 - 1 then
				return b.Id, C.Shelters[b.Id]
			end
		end
		return nil, nil
	end
	function C.nearestShelter(lx: number, lz: number): (number, number, string?)
		local best, bx, bz, bid = math.huge, 0, 0, nil
		for id in C.Shelters do
			local b = C.BuildingById[id]
			if b then
				local dx, dz = C.door(b)
				if dx and dz then
					local d = (dx - lx) ^ 2 + (dz - lz) ^ 2
					if d < best then
						best, bx, bz, bid = d, dx, dz, id
					end
				end
			end
		end
		return bx, bz, bid
	end
	function C.shelterInside(id: string): (number, number)
		local b = C.BuildingById[id]
		if not b then
			return 0, 0
		end
		local dx, dz, f = C.door(b)
		if dx and dz and f then
			return dx - f[1] * 8, dz - f[2] * 8
		end
		return b.X, b.Z
	end

	-- Si caes a un hueco: el sitio andable más cercano (local x, z)
	function C.rescueSpot(lx: number, lz: number): (number, number)
		for radius = 8, 96, 8 do
			local best, bx, bz = math.huge, nil, nil
			for dx = -radius, radius, 8 do
				for dz = -radius, radius, 8 do
					local x, z = lx + dx, lz + dz
					if C.walkable(x, z) and C.buildingAt(x, z, 3) == nil then
						local dist = dx * dx + dz * dz
						if dist < best then
							best, bx, bz = dist, x, z
						end
					end
				end
			end
			if bx and bz then
				return bx, bz
			end
		end
		return plan.Arrival and plan.Arrival[1] or 0, plan.Arrival and plan.Arrival[2] or 0
	end

	-- Lo que sale en el mapa
	function C.landmarks(): { { [string]: any } }
		local out = {}
		for _, b in list do
			if b.Icon then
				table.insert(out, { Id = b.Id, Icon = b.Icon, Name = b.Name, X = b.X, Z = b.Z, Kind = b.Kind })
			end
		end
		for _, s in C.Spots do
			if s.Icon then
				table.insert(out, { Id = s.Id, Icon = s.Icon, Name = s.Name, X = s.X, Z = s.Z, Kind = "Sitio" })
			end
		end
		return out
	end

	function C.weather(clock: number): { Id: string, Name: string, Icon: string, Temp: number }
		if plan.Weather then
			return plan.Weather(clock)
		end
		return { Id = "Despejado", Name = "Despejado", Icon = "sol", Temp = 20 }
	end

	return C
end

return PlanetCity
