-- Barrios: rellenan el campo vacío entre las ciudades de Valmar.
--
-- Cada barrio es una calle (nueva, o una carretera que ya existe) con manzanas a uno o dos lados:
--   * Urbanizaciones de casas junto a Valmar Centro y a lo largo de las carreteras
--   * Zona Industrial (naves, silos, camiones) al sur de Playa Dorada, junto al puerto
--   * Parque empresarial (oficinas de cristal) junto al Distrito Financiero
--   * Huertas y jardines en el norte
-- Las naves, oficinas, huertas y jardines están hechos con pocas piezas para no cargar el juego.
-- No usa nombres de modelo que busque la historia (Parque, Granja, Gasolinera…): así las misiones
-- siguen encontrando solo los sitios de siempre.

local Builder = require(script.Parent.Parent.Builder)
local Blocks = require(script.Parent.Blocks)
local Nature = require(script.Parent.Nature)
local Props = require(script.Parent.Props)
local Street = require(script.Parent.Street)

local Barrios = {}

local rgb = Color3.fromRGB
local EDGE = Street.HALF + 2 -- del centro de la calle al borde de la manzana

type Rect = { X0: number, X1: number, Z0: number, Z1: number }
export type Cell = Rect & { Kind: string, Sides: { string }, Barrio: string }
type Barrio = {
	Name: string,
	Axis: string, -- eje de la calle del barrio
	At: number,
	From: number,
	To: number,
	NewRoad: boolean, -- false: la calle ya existe (carretera)
	Depth: number, -- fondo de las manzanas
	Seg: number, -- largo aproximado de cada manzana
	Skip: { number }?, -- cruces con otras calles (no se construye encima)
	SideA: { string }?, -- tipos de manzana del lado -1 (se repiten)
	SideB: { string }?, -- tipos del lado +1
	FarA: string?, -- el lado -1 también da a otra calle por detrás (N/S/E/W)
	FarB: string?,
}

Barrios.List = {
	-- Urbanizaciones a los dos lados de Valmar Centro, a ambos lados de la avenida
	{ Name = "El Olivar", Axis = "X", At = -200, From = -870, To = -410, NewRoad = true, Depth = 150, Seg = 220,
		SideA = { "Houses", "Garden" }, SideB = { "Houses", "Houses" }, FarB = "S" },
	{ Name = "El Olivar", Axis = "X", At = 200, From = -870, To = -410, NewRoad = true, Depth = 150, Seg = 220,
		SideA = { "Houses", "Houses" }, SideB = { "Garden", "Houses" }, FarA = "N" },
	{ Name = "Mirasol", Axis = "X", At = -200, From = 410, To = 870, NewRoad = true, Depth = 150, Seg = 220,
		SideA = { "Garden", "Houses" }, SideB = { "Houses", "Houses" }, FarB = "S" },
	{ Name = "Mirasol", Axis = "X", At = 200, From = 410, To = 870, NewRoad = true, Depth = 150, Seg = 220,
		SideA = { "Houses", "Houses" }, SideB = { "Houses", "Garden" }, FarA = "N" },
	-- Entre Valmar Centro y Los Pinos
	{ Name = "Las Acacias", Axis = "X", At = 490, From = -370, To = 370, NewRoad = true, Depth = 175, Seg = 330, Skip = { 0 },
		SideA = { "Houses", "Garden" }, SideB = { "Downtown", "Houses" } },
	-- Norte: huertas junto a Villaverde y urbanización junto al campus
	{ Name = "Las Huertas", Axis = "Z", At = 640, From = -1440, To = -250, NewRoad = true, Depth = 180, Seg = 230,
		SideA = { "Fields", "Fields", "Garden", "Fields", "Houses" }, SideB = { "Fields", "Fields", "Fields", "Garden", "Houses" } },
	{ Name = "Bosque Alto", Axis = "Z", At = -640, From = -1440, To = -250, NewRoad = true, Depth = 180, Seg = 230,
		SideA = { "Residence", "Houses", "Garden", "Houses", "Houses" }, SideB = { "Garden", "Houses", "Houses", "Residence", "Houses" } },
	-- A lo largo de las carreteras del oeste y de la costa (entre ciudades)
	{ Name = "San Roque Norte", Axis = "Z", At = -1250, From = -730, To = -370, NewRoad = false, Depth = 200, Seg = 330,
		SideA = { "Houses" }, SideB = { "Houses" } },
	{ Name = "San Roque Sur", Axis = "Z", At = -1250, From = 370, To = 730, NewRoad = false, Depth = 200, Seg = 330,
		SideA = { "Houses" }, SideB = { "Downtown" } },
	{ Name = "Costa Norte", Axis = "Z", At = 1250, From = -730, To = -370, NewRoad = false, Depth = 200, Seg = 330,
		SideA = { "Downtown" }, SideB = { "Houses" } },
	-- Zona Industrial (sigue la carretera de la costa hacia el sur, junto al puerto)
	{ Name = "Zona Industrial", Axis = "Z", At = 1250, From = 380, To = 1440, NewRoad = true, Depth = 200, Seg = 250,
		SideA = { "Industrial" }, SideB = { "Industrial", "Industrial", "Industrial", "Industrial" } },
	{ Name = "Zona Industrial", Axis = "X", At = 900, From = 390, To = 1010, NewRoad = true, Depth = 200, Seg = 290,
		SideA = { "Industrial" }, SideB = { "Industrial" } },
	-- Parque empresarial junto al Distrito Financiero
	{ Name = "Parque Empresarial", Axis = "Z", At = -640, From = 380, To = 1440, NewRoad = true, Depth = 180, Seg = 250,
		SideA = { "Offices", "Offices", "Garden", "Offices" }, SideB = { "Offices", "Houses", "Offices", "Offices" } },
} :: { Barrio }

---------------------------------------------------------------------
-- Calles y manzanas
---------------------------------------------------------------------

function Barrios.roads(): { Street.Road }
	local list = {}
	for _, b in Barrios.List do
		if b.NewRoad then
			table.insert(list, { Axis = b.Axis, At = b.At, From = b.From, To = b.To, Lamps = true, Trees = false })
		end
	end
	return list
end

local cellsCache: { Cell }? = nil

function Barrios.cells(): { Cell }
	if cellsCache then
		return cellsCache
	end
	local cells: { Cell } = {}
	for _, b in Barrios.List do
		-- Tramos a lo largo de la calle, sin pisar los cruces
		local spans = {}
		local start = b.From + 10
		local skips = table.clone(b.Skip or {})
		table.sort(skips)
		for _, s in skips do
			table.insert(spans, { start, s - EDGE })
			start = s + EDGE
		end
		table.insert(spans, { start, b.To - 10 })
		for side = -1, 1, 2 do
			local kinds = if side < 0 then b.SideA else b.SideB
			if kinds then
				local n = 0
				for _, span in spans do
					local length = span[2] - span[1]
					local count = math.max(1, math.floor(length / b.Seg + 0.5))
					local each = length / count
					for i = 0, count - 1 do
						n += 1
						local a0, a1 = span[1] + i * each + 8, span[1] + (i + 1) * each - 8
						local v0, v1 = EDGE, EDGE + b.Depth
						local rect: Rect
						local facing: string
						if b.Axis == "X" then
							local z0, z1 = if side < 0 then b.At - v1 else b.At + v0, if side < 0 then b.At - v0 else b.At + v1
							rect = { X0 = a0, X1 = a1, Z0 = z0, Z1 = z1 }
							facing = if side < 0 then "S" else "N"
						else
							local x0, x1 = if side < 0 then b.At - v1 else b.At + v0, if side < 0 then b.At - v0 else b.At + v1
							rect = { X0 = x0, X1 = x1, Z0 = a0, Z1 = a1 }
							facing = if side < 0 then "E" else "W"
						end
						local sides = { facing }
						local far = if side < 0 then b.FarA else b.FarB
						if far then
							table.insert(sides, far)
						end
						local kind = kinds[(n - 1) % #kinds + 1]
						table.insert(cells, {
							X0 = rect.X0, X1 = rect.X1, Z0 = rect.Z0, Z1 = rect.Z1,
							Kind = kind, Sides = sides, Barrio = b.Name,
						})
					end
				end
			end
		end
	end
	cellsCache = cells
	return cells
end

---------------------------------------------------------------------
-- Tipos ligeros
---------------------------------------------------------------------

-- Jardín público: caminos en cruz, árboles, bancos, farolas y una fuente pequeña
local function garden(parent: Instance, lot: any)
	local m = Builder.model("Jardin", parent)
	local L, D = lot.Length, lot.Depth
	local stone = rgb(214, 204, 186)
	Builder.part({ Name = "Path", Size = Vector3.new(6, 0.3, D - 8), CFrame = lot.facing(0, D / 2, 0.15), Color = stone, Material = Enum.Material.Pavement, Parent = m })
	Builder.part({ Name = "Path", Size = Vector3.new(L - 16, 0.3, 6), CFrame = lot.facing(0, D / 2, 0.16), Color = stone, Material = Enum.Material.Pavement, Parent = m })
	Builder.part({ Name = "Fountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 14, 14), CFrame = lot.facing(0, D / 2, 0.7) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(200, 196, 188), Material = Enum.Material.Limestone, Parent = m })
	Builder.decor({ Name = "FountainWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 12, 12), CFrame = lot.facing(0, D / 2, 1.45) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(70, 160, 210), Material = Enum.Material.Glass, Transparency = 0.2, Parent = m })
	for _, q in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local u, v = q[1] * L / 4, D / 2 + q[2] * D / 4
		Nature.tree(m, lot.point(u + math.random(-6, 6), v + math.random(-6, 6), 0), 1 + math.random() * 0.4)
		Props.bench(m, lot.facing(q[1] * 10, D / 2 + q[2] * 6, 0))
	end
	for _, u in { -L / 2 + 6, L / 2 - 6 } do
		Props.lamp(m, lot.facing(u, 3, 0))
	end
	return m
end

-- Huertas: parcelas de tierra con surcos de colores y una caseta
local CROPS = { rgb(90, 160, 60), rgb(200, 170, 60), rgb(120, 180, 70), rgb(170, 110, 60), rgb(80, 140, 80) }
local function fields(parent: Instance, lot: any)
	local m = Builder.model("Huerta", parent)
	local L, D = lot.Length, lot.Depth
	local plots = 2
	local each = (L - 20) / plots
	for i = 0, plots - 1 do
		local u = -L / 2 + 10 + each * (i + 0.5)
		local soil = lot.facing(u, D / 2 + 6, 0)
		Builder.part({ Name = "Soil", Size = Vector3.new(each - 10, 0.4, D - 36), CFrame = soil * CFrame.new(0, 0.2, 0), Color = rgb(110, 80, 56), Material = Enum.Material.Ground, Parent = m })
		local crop = CROPS[math.random(1, #CROPS)]
		local rows = math.floor((each - 16) / 5)
		for r = 0, rows - 1 do
			local x = -(each - 16) / 2 + r * 5 + 2.5
			Builder.decor({ Name = "Crop", Size = Vector3.new(2, 1.2, D - 44), CFrame = soil * CFrame.new(x, 1, 0), Color = crop, Material = Enum.Material.LeafyGrass, Parent = m })
		end
	end
	-- Caseta de aperos y valla de madera delante
	local shed = lot.facing(L / 2 - 14, 16, 0)
	Builder.part({ Name = "Shed", Size = Vector3.new(12, 8, 10), CFrame = shed * CFrame.new(0, 4, 0), Color = rgb(170, 60, 50), Material = Enum.Material.WoodPlanks, Parent = m })
	Builder.part({ Name = "ShedRoof", Size = Vector3.new(13, 0.8, 11), CFrame = shed * CFrame.new(0, 8.4, 0), Color = rgb(80, 70, 64), Material = Enum.Material.Slate, Parent = m })
	Builder.part({ Name = "Fence", Size = Vector3.new(L - 30, 0.4, 0.3), CFrame = lot.facing(-8, 3, 2.4), Color = rgb(150, 110, 70), Material = Enum.Material.Wood, Parent = m })
	Builder.part({ Name = "Fence", Size = Vector3.new(L - 30, 0.4, 0.3), CFrame = lot.facing(-8, 3, 1.2), Color = rgb(150, 110, 70), Material = Enum.Material.Wood, Parent = m })
	return m
end

-- Nave industrial con puertas de persiana, muelle de carga, camión y (a veces) silos
local BRANDS = { "LOGÍSTICA VALMAR", "TRANSPORTES DEL SUR", "METALES COSTA", "ALIMENTOS VALMAR", "RECICLAJES ECO", "MUEBLES NORTE", "TEXTIL MAR", "BEBIDAS DORADA" }
local WALLS = { rgb(200, 200, 196), rgb(170, 180, 190), rgb(210, 196, 170), rgb(150, 170, 160) }
local function industrial(parent: Instance, lot: any)
	local m = Builder.model("Nave", parent)
	local L, D = lot.Length, lot.Depth
	local w, d, h = math.min(L - 30, 120), math.min(D - 50, 90), math.random(18, 26)
	local base = lot.facing(0, 36 + d / 2, 0)
	local wall = WALLS[math.random(1, #WALLS)]
	Builder.part({ Name = "Yard", Size = Vector3.new(L - 8, 0.3, D - 8), CFrame = lot.facing(0, D / 2, 0.15), Color = rgb(120, 122, 126), Material = Enum.Material.Asphalt, Parent = m })
	Builder.part({ Name = "Hall", Size = Vector3.new(w, h, d), CFrame = base * CFrame.new(0, h / 2, 0), Color = wall, Material = Enum.Material.CorrodedMetal, Parent = m })
	Builder.part({ Name = "Roof", Size = Vector3.new(w + 2, 1.2, d + 2), CFrame = base * CFrame.new(0, h + 0.6, 0), Color = rgb(90, 96, 104), Material = Enum.Material.Metal, Parent = m })
	-- Puertas de persiana y muelle de carga en la fachada (la que mira a la calle es -Z)
	for _, x in { -w / 4, w / 4 } do
		Builder.decor({ Name = "RollerDoor", Size = Vector3.new(14, 12, 0.3), CFrame = base * CFrame.new(x, 6, -d / 2 - 0.2), Color = rgb(70, 80, 92), Material = Enum.Material.DiamondPlate, Parent = m })
	end
	Builder.part({ Name = "Dock", Size = Vector3.new(w * 0.8, 3, 6), CFrame = base * CFrame.new(0, 1.5, -d / 2 - 3), Color = rgb(150, 150, 146), Material = Enum.Material.Concrete, Parent = m })
	local sign = Builder.part({ Name = "Sign", Size = Vector3.new(math.min(w - 10, 50), 5, 0.4), CFrame = base * CFrame.new(0, h - 4, -d / 2 - 0.4), Color = rgb(30, 70, 140), Parent = m })
	Builder.sign(sign, BRANDS[math.random(1, #BRANDS)], Enum.NormalId.Front)
	-- Camión aparcado delante
	local truck = base * CFrame.new(w / 2 - 12, 0, -d / 2 - 20)
	Builder.part({ Name = "Trailer", Size = Vector3.new(8, 9, 26), CFrame = truck * CFrame.new(0, 5.5, 4), Color = rgb(235, 235, 232), Parent = m })
	Builder.part({ Name = "Cab", Size = Vector3.new(8, 7, 7), CFrame = truck * CFrame.new(0, 4.5, -13), Color = Color3.fromHSV(math.random(), 0.6, 0.75), Parent = m })
	Builder.decor({ Name = "CabWindow", Size = Vector3.new(7, 2.5, 0.2), CFrame = truck * CFrame.new(0, 6, -16.55), Color = rgb(40, 60, 80), Material = Enum.Material.Glass, Parent = m })
	-- Silos en algunas naves
	if math.random() < 0.5 then
		for i = 0, 1 do
			local silo = base * CFrame.new(-w / 2 - 9, 0, -d / 4 + i * 16)
			Builder.part({ Name = "Silo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h + 8, 12, 12), CFrame = silo * CFrame.new(0, (h + 8) / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(210, 214, 218), Material = Enum.Material.Metal, Parent = m })
		end
	end
	-- Chimenea
	if math.random() < 0.4 then
		Builder.part({ Name = "Chimney", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h + 22, 4, 4), CFrame = base * CFrame.new(w / 2 - 8, (h + 22) / 2, d / 2 - 8) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(170, 60, 50), Material = Enum.Material.Brick, Parent = m })
	end
	return m
end

-- Edificio de oficinas de cristal con bandas por planta y aparcamiento
local GLASS = { rgb(90, 140, 170), rgb(70, 110, 140), rgb(110, 150, 160), rgb(80, 120, 150) }
local OFFICE_NAMES = { "TECNOVAL", "SEGUROS VALMAR", "BANCO COSTA", "CONSULTORA NORTE", "ENERGÍA VERDE", "VALMAR MEDIA" }
local function offices(parent: Instance, lot: any)
	local m = Builder.model("Oficinas", parent)
	local L, D = lot.Length, lot.Depth
	local w, d = math.min(L - 40, 70), math.min(D - 70, 44)
	local floors = math.random(4, 9)
	local fh = 12
	local base = lot.facing(0, 60 + d / 2, 0)
	local glass = GLASS[math.random(1, #GLASS)]
	Builder.part({ Name = "Core", Size = Vector3.new(w, floors * fh, d), CFrame = base * CFrame.new(0, floors * fh / 2, 0), Color = glass, Material = Enum.Material.Glass, Reflectance = 0.15, Parent = m })
	for f = 1, floors do
		Builder.part({ Name = "Band", Size = Vector3.new(w + 1, 1.2, d + 1), CFrame = base * CFrame.new(0, f * fh - 0.6, 0), Color = rgb(226, 228, 230), Material = Enum.Material.Concrete, Parent = m })
	end
	Builder.part({ Name = "Canopy", Size = Vector3.new(16, 0.8, 8), CFrame = base * CFrame.new(0, 10, -d / 2 - 4), Color = rgb(60, 64, 70), Material = Enum.Material.Metal, Parent = m })
	local sign = Builder.part({ Name = "Sign", Size = Vector3.new(math.min(w - 8, 30), 4, 0.4), CFrame = base * CFrame.new(0, floors * fh - 5, -d / 2 - 0.9), Color = rgb(20, 26, 36), Parent = m })
	Builder.sign(sign, OFFICE_NAMES[math.random(1, #OFFICE_NAMES)], Enum.NormalId.Front)
	-- Aparcamiento delante con plazas pintadas y unos coches
	local lotCf = lot.facing(0, 28, 0)
	Builder.part({ Name = "Parking", Size = Vector3.new(L - 16, 0.3, 40), CFrame = lotCf * CFrame.new(0, 0.15, 0), Color = rgb(60, 62, 66), Material = Enum.Material.Asphalt, Parent = m })
	for x = -(L - 30) / 2, (L - 30) / 2, 10 do
		Builder.decor({ Name = "Line", Size = Vector3.new(0.4, 0.05, 14), CFrame = lotCf * CFrame.new(x, 0.32, -10), Color = rgb(236, 236, 230), Parent = m })
	end
	for _ = 1, 3 do
		local x = math.random(-3, 3) * 10 + 5
		Props.car(m, lotCf * CFrame.new(x, 0.3, -10))
	end
	return m
end

---------------------------------------------------------------------

local function slab(parent: Instance, rect: Rect)
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

function Barrios.build(world: Instance)
	local folder = Builder.model("Barrios", world)
	local models: { [string]: Model } = {}
	for _, cell in Barrios.cells() do
		local model = models[cell.Barrio]
		if not model then
			model = Builder.model(cell.Barrio, folder)
			models[cell.Barrio] = model
		end
		slab(model, cell)
		local lot = Blocks.lot(cell, cell.Sides[1])
		if cell.Kind == "Garden" then
			garden(model, lot)
		elseif cell.Kind == "Fields" then
			fields(model, lot)
		elseif cell.Kind == "Industrial" then
			industrial(model, lot)
		elseif cell.Kind == "Offices" then
			offices(model, lot)
		else
			Blocks.fill(model, cell, cell.Kind, {
				Side = cell.Sides[1],
				Sides = cell.Sides,
				TownName = cell.Barrio,
				Styles = { "Clasico", "Moderno", "Popular" },
				Floors = { 3, 6 },
			})
		end
	end
	return folder
end

-- ¿Está este punto dentro de algún barrio? (para no plantar árboles del campo encima)
function Barrios.blocked(x: number, z: number): boolean
	for _, cell in Barrios.cells() do
		if x > cell.X0 - 6 and x < cell.X1 + 6 and z > cell.Z0 - 6 and z < cell.Z1 + 6 then
			return true
		end
	end
	return false
end

return Barrios
