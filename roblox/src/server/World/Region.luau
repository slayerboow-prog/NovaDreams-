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
			{ T("FirePolice", "E"), T("Downtown"), T("School", "S"), T("Farm", "W") },
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

function Region.roads(): { Street.Road }
	local list = {}
	for _, road in Region.Highways do
		table.insert(list, road)
	end
	for _, town in Region.Towns do
		local c = town.Center
		for _, o in OFFSETS do
			if not (o == 0 and town.SkipX) then
				table.insert(list, { Axis = "X", At = c.Z + o, From = c.X - SPAN, To = c.X + SPAN, Lamps = true, Trees = town.Name == "Los Pinos" })
			end
			if not (o == 0 and town.SkipZ) then
				table.insert(list, { Axis = "Z", At = c.X + o, From = c.Z - SPAN, To = c.Z + SPAN, Lamps = true, Trees = town.Name == "Los Pinos" })
			end
		end
	end
	-- Calles secundarias por todos los distritos (Kit/Grid)
	for _, road in require(Kit.Grid).roads(Region.centers(), table.clone(list)) do
		table.insert(list, road)
	end
	return list
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
		Color = Color3.fromRGB(98, 146, 70),
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
				Blocks.fill(model, rect, cell.Kind, {
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
		local entry = c + town.Entry.Offset
		Civic.welcome(model, Builder.facing(entry, town.Entry.Facing), town.Name)
		local stop = Vector3.new(c.X - 60, Street.WALK_TOP, c.Z - 16) -- acera norte de la calle central
		Region.travelStop(model, Builder.facing(stop, Vector3.new(0, 0, 1)), town.Name)
	end
	return folder
end

return Region
