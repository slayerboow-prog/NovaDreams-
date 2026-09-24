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
-- Tipos: Downtown, Houses, Hospital, Clinic, School, FirePolice, Mall, Gas, Park, Farm, Beach.

local Builder = require(script.Parent.Builder)
local Kit = script.Parent.Kit
local Blocks = require(Kit.Blocks)
local Civic = require(Kit.Civic)
local Props = require(Kit.Props)
local Street = require(Kit.Street)

local Region = {}

local SPAN = 360 -- media anchura de cada ciudad
local OFFSETS = { -240, 0, 240 } -- calles relativas al centro
local CELLS = { { -360, -260 }, { -220, -20 }, { 20, 220 }, { 260, 360 } }

-- Carreteras que unen las ciudades (también son la calle central de algunas)
Region.Highways = {
	Avenue = { Axis = "X", At = 0, From = -1610, To = 1610, Lamps = true, Trees = false },
	NorthSouth = { Axis = "Z", At = 0, From = -920, To = 1460, Lamps = true, Trees = false },
	Coast = { Axis = "Z", At = 1250, From = -1460, To = 360, Lamps = true, Trees = false },
	West = { Axis = "Z", At = -1250, From = -1460, To = 1460, Lamps = true, Trees = false },
}

local function T(kind: string, side: string?, title: string?)
	return { Kind = kind, Side = side, Title = title }
end

Region.Towns = {
	{
		Name = "Valmar Norte",
		Center = Vector3.new(0, 0, -560),
		Styles = { "Clasico", "Moderno" },
		Floors = { 4, 8 },
		SkipZ = true, -- su calle central N-S es la carretera NorthSouth
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
		Center = Vector3.new(-1250, 0, 0),
		Styles = { "Popular" },
		Floors = { 3, 5 },
		SkipX = true, -- su calle central E-O es la avenida
		SkipZ = true, -- su calle central N-S es la carretera del oeste
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
		Center = Vector3.new(1250, 0, 0),
		Styles = { "Moderno", "Clasico" },
		Floors = { 4, 9 },
		SkipX = true,
		SkipZ = true, -- su calle central N-S es la carretera de la costa
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
		Center = Vector3.new(0, 0, 1100),
		Styles = { "Clasico", "Popular" },
		Floors = { 2, 4 },
		SkipZ = true,
		Entry = { Offset = Vector3.new(30, 0, -380), Facing = Vector3.new(0, 0, -1) },
		Plan = {
			{ T("Houses"), T("Houses"), T("Houses"), T("Houses") },
			{ T("FirePolice", "E"), T("School", "S"), T("Park", "S"), T("Houses") },
			{ T("Clinic", "E"), T("Houses"), T("Mall", "N"), T("Gas", "W") },
			{ T("Houses"), T("Houses"), T("Leisure", "N"), T("Houses") },
		},
	},
	{
		Name = "Villaverde",
		Center = Vector3.new(1250, 0, -1100),
		Styles = { "Popular" },
		Floors = { 2, 3 },
		SkipZ = true,
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
		Center = Vector3.new(-1250, 0, -1100),
		Styles = { "Clasico", "Popular" },
		Floors = { 3, 5 },
		SkipZ = true, -- su calle central N-S es la carretera del oeste
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
		Center = Vector3.new(-1250, 0, 1100),
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

-- Parada de autobús interurbano (TravelService la usa para viajar entre ciudades)
function Region.travelStop(parent: Instance, cf: CFrame, townName: string)
	Props.busStop(parent, cf)
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
