-- Region: las ciudades de la región de Valmar y cómo se conectan.
--
--                        Valmar Norte (0, -560)            Villaverde (1250, -1100)
--                              │                                  │
--   San Roque (-1250, 0) ══ AVENIDA ══ Valmar Centro (0,0) ══ AVENIDA ══ Playa Dorada (1250, 0) ~~~ MAR
--                              │
--                        Los Pinos (0, 1100)
--
-- Cada ciudad es una cuadrícula de 4 × 4 manzanas separadas por calles cada 240 studs.
-- El plano (Plan) dice qué va en cada manzana. Filas de norte a sur, columnas de oeste a este.
-- Tipos: Downtown, Houses, FamilyHomes, Hospital, Clinic, School, FirePolice, Mall, Gas, Park, Farm, Beach,
-- Stadium, Faculty, Towers, Business, Leisure, Residence.

local Builder = require(script.Parent.Builder)
local Kit = script.Parent.Kit
local Blocks = require(Kit.Blocks)
local Civic = require(Kit.Civic)
local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)
local Props = require(Kit.Props)
local Rides = require(Kit.Rides)
local Street = require(Kit.Street)

local Region = {}

local SPAN = 360 -- media anchura de cada ciudad
local RING = 380 -- calle de circunvalación de cada barrio (cierra todas sus calles)
local OFFSETS = { -240, 0, 240 } -- calles relativas al centro
local CELLS = { { -360, -260 }, { -220, -20 }, { 20, 220 }, { 260, 360 } }

-- Las dos calles grandes del centro (se cruzan en la plaza y llegan a las rotondas de la Ronda).
-- El resto de carreteras principales (Ronda, avenidas, diagonales) está en CityPlan.Roads (Kit/Roads).
Region.Highways = {
	Avenue = { Axis = "X", At = 0, From = -1205, To = 1205, Lamps = true, Trees = false },
	NorthSouth = { Axis = "Z", At = 0, From = -1205, To = 1205, Lamps = true, Trees = false },
}

-- Centro de una zona según el plano
local function at(name: string): Vector3
	local p = CityPlan.Towns[name]
	return Vector3.new(p[1], 0, p[2])
end

local function T(kind: string, side: string?, title: string?)
	return { Kind = kind, Side = side, Title = title }
end

Region.Towns = {
	{
		Name = "Valmar Norte",
		Center = at("Valmar Norte"),
		Styles = { "Clasico", "Moderno" },
		Floors = { 4, 8 },
		Entry = { Offset = Vector3.new(30, 0, 350), Facing = Vector3.new(0, 0, 1) },
		Plan = {
			{ T("Houses"), T("Downtown"), T("Downtown"), T("Houses") },
			{ T("FirePolice", "E"), T("Hospital", "S"), T("Mall", "S"), T("Gas", "W") },
			{ T("Downtown"), T("School", "N"), T("Park", "N"), T("Leisure", "W") },
			{ T("Houses"), T("Downtown"), T("Downtown"), T("Park", "N") },
		},
	},
	{
		Name = "San Roque",
		Center = at("San Roque"),
		Styles = { "Popular" },
		Floors = { 3, 5 },
		Entry = { Offset = Vector3.new(380, 0, 30), Facing = Vector3.new(1, 0, 0) },
		Plan = {
			{ T("Houses"), T("Downtown"), T("Downtown"), T("Gas", "W") },
			{ T("FirePolice", "E"), T("Mall", "S"), T("Leisure", "S"), T("Houses") },
			{ T("Clinic", "E"), T("Downtown"), T("School", "N"), T("Houses") },
			{ T("Houses"), T("Park", "N"), T("Downtown"), T("Houses") },
		},
	},
	{
		Name = "Playa Dorada",
		Center = at("Playa Dorada"),
		Styles = { "Moderno", "Clasico" },
		Floors = { 4, 9 },
		Entry = { Offset = Vector3.new(-380, 0, 30), Facing = Vector3.new(-1, 0, 0) },
		Plan = {
			{ T("Houses"), T("Downtown"), T("Downtown"), T("Beach", "W") },
			{ T("FirePolice", "E"), T("Mall", "S"), T("Downtown"), T("Beach", "W") },
			{ T("Clinic", "E"), T("School", "N"), T("Park", "N"), T("Beach", "W") },
			{ T("Gas", "E"), T("Leisure", "N"), T("Houses"), T("Beach", "W") },
		},
	},
	{
		Name = "Los Pinos",
		Center = at("Los Pinos"),
		Styles = { "Clasico", "Popular" },
		Floors = { 2, 4 },
		Entry = { Offset = Vector3.new(30, 0, -380), Facing = Vector3.new(0, 0, -1) },
		Plan = {
			{ T("Houses"), T("FamilyHomes", "S"), T("FamilyHomes", "S"), T("Houses") },
			{ T("FirePolice", "E"), T("School", "S"), T("Park", "S"), T("Houses") },
			{ T("Clinic", "E"), T("Houses"), T("Mall", "N"), T("Gas", "W") },
			{ T("Houses"), T("Houses"), T("Leisure", "N"), T("Houses") },
		},
	},
	{
		Name = "Villaverde",
		Center = at("Villaverde"),
		Styles = { "Popular" },
		Floors = { 2, 3 },
		Entry = { Offset = Vector3.new(30, 0, 380), Facing = Vector3.new(0, 0, 1) },
		Plan = {
			{ T("Farm", "S"), T("Farm", "S"), T("Farm", "S"), T("Farm", "S") },
			{ T("FirePolice", "E"), T("Downtown"), T("School", "S"), T("Farm", "W", "Julian") }, -- (la granja de Julián: Kit/GranjaJulian)
			{ T("Clinic", "E"), T("Park", "N"), T("Mall", "N"), T("Farm", "W") },
			{ T("Gas", "E"), T("Houses"), T("Leisure", "N"), T("Farm", "W") },
		},
	},
	{
		Name = "Campus Valmar",
		Center = at("Campus Valmar"),
		Styles = { "Clasico", "Popular" },
		Floors = { 3, 5 },
		TeamColor = Color3.fromRGB(150, 30, 40),
		Entry = { Offset = Vector3.new(30, 0, 380), Facing = Vector3.new(0, 0, 1) },
		Plan = {
			{ T("Residence"), T("Faculty", "S", "FACULTAD DE MEDICINA"), T("Faculty", "S", "FACULTAD DE INGENIERÍA"), T("Residence") },
			{ T("Gas", "E"), T("Stadium", "S"), T("Faculty", "S", "BIBLIOTECA UNIVERSITARIA"), T("Houses") },
			{ T("Clinic", "E"), T("Park", "N"), T("Faculty", "N", "FACULTAD DE DERECHO"), T("Leisure", "W") },
			{ T("Residence"), T("Leisure", "N"), T("School", "N"), T("Faculty", "N", "FACULTAD DE ECONOMÍA") },
		},
	},
	{
		Name = "Distrito Financiero",
		Center = at("Distrito Financiero"),
		Styles = { "Moderno", "Oficina" },
		Floors = { 6, 12 },
		SkipZ = true,
		TeamColor = Color3.fromRGB(30, 90, 170),
		Entry = { Offset = Vector3.new(30, 0, -380), Facing = Vector3.new(0, 0, -1) },
		Plan = {
			{ T("Towers", "S"), T("Towers", "S"), T("Towers", "S"), T("Towers", "S") },
			{ T("Towers", "E"), T("Business"), T("Leisure", "S"), T("Towers", "W") },
			{ T("FirePolice", "E"), T("Mall", "N"), T("Stadium", "N"), T("Gas", "W") },
			{ T("Towers", "N"), T("Downtown"), T("Park", "N"), T("Towers", "N") },
		},
	},
}

-- Todas las calles de la región (carreteras + calles de cada ciudad)
-- Centros de las cuadrículas de barrio (las zonas de la historia)
function Region.centers(): { Vector3 }
	local centers = {}
	for _, town in Region.Towns do
		table.insert(centers, town.Center)
	end
	return centers
end

-- Calle residencial de Valmar Centro (al sur de la avenida, delante de las parcelas)
Region.Residential = { Axis = "X", At = 120, From = -340, To = 340, Lamps = true, Trees = true }

local roadsCache: { Street.Road }? = nil
function Region.roads(): { Street.Road }
	if roadsCache then
		return table.clone(roadsCache)
	end
	local list = {}
	for _, road in Region.Highways do
		table.insert(list, road)
	end
	table.insert(list, Region.Residential)
	for _, town in Region.Towns do
		local c = town.Center
		local trees = town.Name == "Los Pinos"
		-- Calles del barrio: llegan hasta la circunvalación
		for _, o in OFFSETS do
			if not (o == 0 and town.SkipX) then
				table.insert(list, { Axis = "X", At = c.Z + o, From = c.X - RING, To = c.X + RING, Lamps = true, Trees = trees })
			end
			if not (o == 0 and town.SkipZ) then
				table.insert(list, { Axis = "Z", At = c.X + o, From = c.Z - RING, To = c.Z + RING, Lamps = true, Trees = trees })
			end
		end
		-- Circunvalación: un cuadrado alrededor del barrio
		for _, side in { -RING, RING } do
			table.insert(list, { Axis = "X", At = c.Z + side, From = c.X - RING, To = c.X + RING, Lamps = true })
			table.insert(list, { Axis = "Z", At = c.X + side, From = c.Z - RING, To = c.Z + RING, Lamps = true })
		end
	end
	-- Calles secundarias por todos los distritos (Kit/Grid)
	for _, road in require(Kit.Grid).roads(Region.centers(), table.clone(list)) do
		table.insert(list, road)
	end
	-- Que ninguna calle acabe en la nada (Kit/Connect): se alargan hasta otra o se recortan
	local blocked = {}
	for _, town in Region.Towns do
		local c = town.Center
		table.insert(blocked, { X0 = c.X - SPAN - 4, X1 = c.X + SPAN + 4, Z0 = c.Z - SPAN - 4, Z1 = c.Z + SPAN + 4 })
	end
	table.insert(blocked, { X0 = -360, X1 = 360, Z0 = -198, Z1 = -24 }) -- Valmar Centro (plaza y tiendas)
	table.insert(blocked, { X0 = -360, X1 = 360, Z0 = 24, Z1 = 100 }) -- Valmar Centro (parcelas)
	table.insert(blocked, { X0 = -360, X1 = 360, Z0 = 140, Z1 = 240 })
	for _, cell in require(Kit.Districts).cells(Region.centers()) do
		table.insert(blocked, cell)
	end
	local fixed = require(Kit.Connect).fix(list, blocked)
	-- Calles paralelas casi en la misma línea (a pocos studs) que se solapan: la de la cuadrícula se
	-- alinea con la otra y se unen en una sola calle (si no, quedaban dos cruces montados uno encima
	-- del otro, con aceras cruzando la calzada de la vecina)
	for _, a in fixed do
		for _, b in fixed do
			local offset = math.abs(a.At - b.At)
			if a ~= b and a.Axis == b.Axis and offset > 0 and offset <= 10 and a.From <= b.To + 1 and b.From <= a.To + 1 and a.Trees and not b.Trees then
				b.At = a.At
				b.Snapped = true
			end
		end
	end
	-- Dos trozos en línea que se solapan: se unen, salvo si entre medias los corta una carretera
	-- principal que pasa de lado a lado (entonces son dos calles que desembocan en ella)
	local Roads = require(Kit.Roads)
	local function crossedThrough(axis: string, at: number, u: number): boolean
		local x, z = if axis == "X" then u else at, if axis == "X" then at else u
		for _, seg in Roads.segments() do
			local kind = Roads.Kinds[seg.Kind]
			if CityPlan.segmentDistance(x, z, seg.A.X, seg.A.Z, seg.B.X, seg.B.Z) < kind.Road / 2 + kind.Walk + 2 then
				local a = if axis == "X" then seg.A.Z - at else seg.A.X - at
				local b = if axis == "X" then seg.B.Z - at else seg.B.X - at
				if (a > 20 and b < -20) or (a < -20 and b > 20) then
					return true
				end
			end
		end
		return false
	end
	local function joins(m: any, road: any): boolean
		if m.Axis ~= road.Axis or m.At ~= road.At or road.From > m.To + 1 or m.From > road.To + 1 then
			return false
		end
		if road.Snapped or m.Snapped then
			return true
		end
		local lo, hi = math.max(m.From, road.From), math.min(m.To, road.To)
		return not crossedThrough(m.Axis, m.At, (lo + hi) / 2)
	end
	local merged: { Street.Road } = {}
	for _, road in fixed do
		local joined = false
		for _, m in merged do
			if joins(m, road) then
				m.From, m.To = math.min(m.From, road.From), math.max(m.To, road.To)
				if road.Trees then
					m.Trees, m.LampEvery, m.Solid = true, road.LampEvery, road.Solid
				end
				joined = true
				break
			end
		end
		if not joined then
			table.insert(merged, road)
		end
	end
	-- (a veces una unión junta otras dos que ya estaban: otra pasada)
	for _ = 1, 2 do
		for i = #merged, 1, -1 do
			local road = merged[i]
			for j = 1, i - 1 do
				local m = merged[j]
				if joins(m, road) then
					m.From, m.To = math.min(m.From, road.From), math.max(m.To, road.To)
					m.Trees = m.Trees or road.Trees
					table.remove(merged, i)
					break
				end
			end
		end
	end
	for _, road in merged do
		road.Snapped = nil
	end
	-- Una calle que corre casi paralela por encima de una carretera principal (sus aceras pisarían la
	-- calzada): se queda solo con el trozo más largo que va por fuera
	local kept: { Street.Road } = {}
	for _, road in merged do
		local dirStreet = if road.Axis == "X" then Vector3.new(1, 0, 0) else Vector3.new(0, 0, 1)
		-- (solo las carreteras casi paralelas y cerca de esta calle)
		local near = {}
		local x0, x1 = if road.Axis == "X" then road.From else road.At, if road.Axis == "X" then road.To else road.At
		local z0, z1 = if road.Axis == "X" then road.At else road.From, if road.Axis == "X" then road.At else road.To
		for _, seg in Roads.segments() do
			local kind = Roads.Kinds[seg.Kind]
			local reach = kind.Road / 2 + kind.Walk + 19
			if math.abs((seg.B - seg.A).Unit:Dot(dirStreet)) > 0.95 and math.max(seg.A.X, seg.B.X) > x0 - reach and math.min(seg.A.X, seg.B.X) < x1 + reach and math.max(seg.A.Z, seg.B.Z) > z0 - reach and math.min(seg.A.Z, seg.B.Z) < z1 + reach then
				-- En la misma línea que la calle: la carretera la continúa. La calle empieza justo donde
				-- acaba la carretera (con el margen quedaba un trozo sin asfalto, con el terreno a la vista)
				local sideA = if road.Axis == "X" then seg.A.Z - road.At else seg.A.X - road.At
				local sideB = if road.Axis == "X" then seg.B.Z - road.At else seg.B.X - road.At
				local along = if road.Axis == "X" then { seg.A.X, seg.B.X } else { seg.A.Z, seg.B.Z }
				local inLine = math.abs(sideA) < 1 and math.abs(sideB) < 1
				table.insert(near, { seg, reach, if inLine then { math.min(along[1], along[2]), math.max(along[1], along[2]) } else nil })
			end
		end
		local function inside(u: number): boolean
			local x, z = if road.Axis == "X" then u else road.At, if road.Axis == "X" then road.At else u
			for _, item in near do
				local seg, span = item[1], item[3]
				if span then
					if u > span[1] + 0.01 and u < span[2] - 0.01 then
						return true
					end
				elseif CityPlan.segmentDistance(x, z, seg.A.X, seg.A.Z, seg.B.X, seg.B.Z) < item[2] then
					return true
				end
			end
			return false
		end
		local bestFrom, bestTo, runFrom = nil, nil, nil
		local anyInside = false
		local u = road.From
		while true do
			local ok = not inside(u)
			anyInside = anyInside or not ok
			if ok and not runFrom then
				runFrom = u
			end
			local last = u >= road.To
			if runFrom and (not ok or last) then
				local runTo = if ok then u else u - 5
				if not bestFrom or runTo - runFrom > (bestTo :: number) - bestFrom then
					bestFrom, bestTo = runFrom, runTo
				end
				runFrom = nil
			end
			if last then
				break
			end
			u = math.min(u + 5, road.To)
		end
		if not anyInside then
			table.insert(kept, road)
		elseif bestFrom and (bestTo :: number) - bestFrom > 60 then
			-- El extremo que toca el final de una carretera en la misma línea se pega a ella. Si la calle
			-- llegaba hasta un cruce a pocos studs (su circunvalación), se deja entera: el cruce corta
			-- las aceras (si no, la acera de la circunvalación cruzaba la calzada) y el asfalto de las
			-- dos es el mismo, así que el trozo que comparten no se nota.
			for _, item in near do
				local span = item[3]
				if span then
					if math.abs(bestFrom - span[2]) < 5 then
						bestFrom = if span[2] - road.From < 25 then road.From else span[2]
					end
					if math.abs((bestTo :: number) - span[1]) < 5 then
						bestTo = if road.To - span[1] < 25 then road.To else span[1]
					end
				end
			end
			road.From, road.To = bestFrom, bestTo :: number
			table.insert(kept, road)
		end
	end
	roadsCache = kept
	return table.clone(roadsCache :: { Street.Road })
end

-- Lados de la manzana (i, j) que dan a una calle
local function roadSides(i: number, j: number): { string }
	local sides = {}
	if j > 1 then
		table.insert(sides, "N")
	end
	if j < 4 then
		table.insert(sides, "S")
	end
	if i > 1 then
		table.insert(sides, "W")
	end
	if i < 4 then
		table.insert(sides, "E")
	end
	return sides
end

-- Rectángulos (X0, X1, Z0, Z1) de todas las manzanas de las ciudades (los usa TerrainBuilder
-- para hundir el terreno bajo ellas: así nunca asoma por los suelos de las casas)
function Region.blockRects(): { { X0: number, X1: number, Z0: number, Z1: number } }
	local list = {}
	for _, town in Region.Towns do
		local c = town.Center
		for j = 1, 4 do
			for i = 1, 4 do
				table.insert(list, { X0 = c.X + CELLS[i][1], X1 = c.X + CELLS[i][2], Z0 = c.Z + CELLS[j][1], Z1 = c.Z + CELLS[j][2] })
			end
		end
	end
	-- Manzanas de los distritos (Kit/Districts)
	for _, cell in require(Kit.Districts).cells(Region.centers()) do
		table.insert(list, { X0 = cell.X0, X1 = cell.X1, Z0 = cell.Z0, Z1 = cell.Z1 })
	end
	return list
end

-- Suelo de césped de una manzana: su cara de arriba queda en Y = 0, a ras de las calles.
-- El terreno de Roblox está 1 stud más abajo (TerrainBuilder) para que nunca asome por encima.
function Region.groundSlab(parent: Instance, rect: { X0: number, X1: number, Z0: number, Z1: number })
	Builder.part({
		Name = "BlockGround",
		Size = Vector3.new(rect.X1 - rect.X0, 1, rect.Z1 - rect.Z0),
		CFrame = CFrame.new((rect.X0 + rect.X1) / 2, -0.5, (rect.Z0 + rect.Z1) / 2),
		Color = require(script.Parent.Kit.Palette).Ground.Grass,
		Material = Enum.Material.Grass,
		CastShadow = false,
		Parent = parent,
	})
end

-- Parada de autobús interurbano (TravelService la usa para viajar entre ciudades)
-- con una estación de bici pública al lado (VehicleService)
function Region.travelStop(parent: Instance, cf: CFrame, townName: string)
	Props.busStop(parent, cf)
	Rides.station(parent, cf * CFrame.new(11, 0, 0))
	Builder.part({
		Name = "TravelPoint",
		Size = Vector3.new(2, 2, 2),
		CFrame = cf * CFrame.new(0, 2, 0),
		Transparency = 1,
		CanCollide = false,
		Tags = { "TravelStop" },
		Attributes = { Town = townName },
		Parent = parent,
	})
end

function Region.build(world: Instance)
	local folder = Builder.model("Region", world)
	for _, town in Region.Towns do
		local c = town.Center
		local model = Builder.model(town.Name, folder)
		for j = 1, 4 do
			for i = 1, 4 do
				local cell = town.Plan[j][i]
				local rect = {
					X0 = c.X + CELLS[i][1],
					X1 = c.X + CELLS[i][2],
					Z0 = c.Z + CELLS[j][1],
					Z1 = c.Z + CELLS[j][2],
				}
				Region.groundSlab(model, rect)
				-- Casas junto a las casas familiares (misma fila): ahí vive Cosme, el vecino inventor,
				-- con su garaje mirando a la calle que las separa
				local west, east = town.Plan[j][i - 1], town.Plan[j][i + 1]
				local cosmeGarage = if cell.Kind ~= "Houses" then nil
					elseif east and east.Kind == "FamilyHomes" then "E"
					elseif west and west.Kind == "FamilyHomes" then "W"
					else nil
				Blocks.fill(model, rect, cell.Kind, {
					CosmeGarage = cosmeGarage,
					Side = cell.Side,
					Sides = roadSides(i, j),
					TownName = town.Name,
					Styles = town.Styles,
					Floors = town.Floors,
					Title = cell.Title,
					TeamColor = town.TeamColor,
				})
			end
		end
		-- Cartel de bienvenida en la carretera de entrada y parada de autobús en el centro
		-- (fuera de la circunvalación, junto a la calle que entra al barrio)
		local entry = c + town.Entry.Offset + town.Entry.Facing * (RING + 32 - town.Entry.Offset:Dot(town.Entry.Facing))
		Civic.welcome(model, Builder.facing(entry, town.Entry.Facing), town.Name)
		local stop = Vector3.new(c.X - 60, Street.WALK_TOP, c.Z - 16) -- acera norte de la calle central
		Region.travelStop(model, Builder.facing(stop, Vector3.new(0, 0, 1)), town.Name)
	end
	return folder
end

return Region
