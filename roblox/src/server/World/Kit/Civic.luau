-- Civic: edificios y espacios públicos que tiene cada ciudad
-- (hospital, colegio, bomberos, policía, centro comercial, gasolinera, parque, granja, playa).
--
-- Todas las funciones reciben una "parcela de manzana" (Lot) que sabe convertir
-- coordenadas locales a mundo:  u = a lo largo de la calle (0 = centro),
-- v = distancia hacia dentro desde la acera.  lot.facing(u, v) da un CFrame que mira a la calle.

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local Building = require(script.Parent.Building)
local Nature = require(script.Parent.Nature)
local Props = require(script.Parent.Props)
local StoryMarks = require(script.Parent.StoryMarks)

local Civic = {}

local FT = Building.FLOOR_TOP
local rgb = Color3.fromRGB

export type Lot = {
	Length: number, -- largo a lo largo de la calle
	Depth: number, -- fondo hacia dentro
	point: (u: number, v: number, y: number) -> Vector3,
	facing: (u: number, v: number, y: number?) -> CFrame, -- mira hacia la calle
	along: (u: number, v: number, y: number?) -> CFrame, -- mira a lo largo de la calle (+u)
}

-- Losa plana (asfalto, hormigón, césped…) en coordenadas del lote
local function slab(parent: Instance, lot: Lot, u0: number, u1: number, v0: number, v1: number, top: number, color: Color3, material: Enum.Material, name: string?)
	local cf = lot.facing((u0 + u1) / 2, (v0 + v1) / 2, top / 2)
	return Builder.part({
		Name = name or "Slab",
		Size = Vector3.new(math.abs(u1 - u0), top, math.abs(v1 - v0)),
		CFrame = cf,
		Color = color,
		Material = material,
		Parent = parent,
	})
end

local function signBoard(parent: Instance, cf: CFrame, text: string, width: number, color: Color3, textColor: Color3?)
	local board = Builder.decor({ Name = "Sign", Size = Vector3.new(width, width * 0.22, 0.4), CFrame = cf, Color = color, Parent = parent })
	Builder.sign(board, text, Enum.NormalId.Front, textColor)
	Builder.sign(board, text, Enum.NormalId.Back, textColor)
	return board
end

---------------------------------------------------------------------
-- Aparcamiento con plazas pintadas y coches
---------------------------------------------------------------------
function Civic.parkingLot(parent: Instance, lot: Lot, u0: number, u1: number, v0: number, v1: number, fill: number?)
	local m = Builder.model("Parking", parent)
	slab(m, lot, u0, u1, v0, v1, 0.4, Palette.Ground.Asphalt, Enum.Material.Asphalt, "ParkingFloor")
	local rowDepth, aisle, stall = 18, 22, 10
	local v = v0 + 2
	local row = 0
	while v + rowDepth <= v1 - 2 do
		local u = u0 + 4
		while u + stall <= u1 - 4 do
			-- Línea de separación
			local line = lot.facing(u, v + rowDepth / 2, 0.42)
			Builder.decor({ Name = "Line", Size = Vector3.new(0.4, 0.05, rowDepth), CFrame = line, Color = Palette.Ground.Marking, Parent = m })
			if math.random() < (fill or 0.55) then
				local heading = if row % 2 == 0 then 1 else -1
				local center = lot.point(u + stall / 2, v + rowDepth / 2, 0.4)
				local toward = lot.point(u + stall / 2, v + rowDepth / 2 + heading, 0.4) - center
				Props.car(m, Builder.facing(center, toward))
			end
			u += stall
		end
		row += 1
		v += rowDepth + (if row % 2 == 1 then 0 else aisle)
	end
	-- Farolas en el borde
	for u = u0 + 10, u1 - 10, 40 do
		Props.lamp(m, lot.facing(u, v0 + 1, 0.4) * CFrame.Angles(0, math.pi, 0))
	end
	return m
end

---------------------------------------------------------------------
-- Hospital / centro de salud
---------------------------------------------------------------------
function Civic.hospital(parent: Instance, lot: Lot, townName: string, small: boolean?)
	local m = Builder.model(if small then "CentroSalud" else "Hospital", parent)
	local W = math.min(lot.Length - 20, if small then 70 else 96)
	local D = math.min(lot.Depth - 24, 56)
	local setback = 14
	slab(m, lot, -lot.Length / 2 + 2, lot.Length / 2 - 2, 0, setback, FT, rgb(206, 204, 198), Enum.Material.Concrete, "Apron")
	local model, at, info = Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(0, setback + D / 2, 0),
		Width = W, Depth = D, Floors = if small then 3 else 5, Style = "Moderno", GroundFloor = "Lobby",
		WallColor = rgb(240, 242, 244), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true, Back = true },
		Sign = if small then "CENTRO DE SALUD" else "HOSPITAL " .. string.upper(townName), SignColor = rgb(200, 36, 40),
		FloorMaterial = Enum.Material.CeramicTiles, FloorColor = rgb(232, 234, 232), LightColor = rgb(240, 248, 255),
	})
	-- Cruz roja en lo alto de la fachada
	local crossCf = at(0, info.Top - FT + 5, -D / 2 + 1)
	Builder.decor({ Name = "CrossBack", Size = Vector3.new(9, 9, 0.4), CFrame = crossCf, Color = rgb(250, 250, 250), Parent = model })
	Builder.decor({ Name = "Cross", Size = Vector3.new(7, 2.2, 0.6), CFrame = crossCf * CFrame.new(0, 0, -0.2), Color = rgb(220, 30, 40), Material = Enum.Material.Neon, Parent = model })
	Builder.decor({ Name = "Cross", Size = Vector3.new(2.2, 7, 0.6), CFrame = crossCf * CFrame.new(0, 0, -0.2), Color = rgb(220, 30, 40), Material = Enum.Material.Neon, Parent = model })
	if not small then
		-- Helipuerto en la azotea
		local pad = at(W / 4, info.Top - FT + 1.2, D / 6)
		Builder.part({ Name = "Helipad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 20, 20), CFrame = pad * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(70, 72, 78), Parent = model })
		Builder.decor({ Name = "H", Size = Vector3.new(1.2, 0.1, 8), CFrame = pad * CFrame.new(-2.6, 0.2, 0), Color = rgb(250, 250, 250), Parent = model })
		Builder.decor({ Name = "H", Size = Vector3.new(1.2, 0.1, 8), CFrame = pad * CFrame.new(2.6, 0.2, 0), Color = rgb(250, 250, 250), Parent = model })
		Builder.decor({ Name = "H", Size = Vector3.new(5.2, 0.1, 1.2), CFrame = pad * CFrame.new(0, 0.2, 0), Color = rgb(250, 250, 250), Parent = model })
	end
	-- Marquesina de urgencias con ambulancias
	local canopyU = W / 2 - 10
	Builder.part({ Name = "Canopy", Size = Vector3.new(20, 0.6, 12), CFrame = lot.facing(canopyU, setback - 5, FT + 9), Color = rgb(226, 228, 232), Material = Enum.Material.Metal, Parent = m })
	for _, du in { -9, 9 } do
		Builder.part({ Name = "Post", Size = Vector3.new(0.6, 9, 0.6), CFrame = lot.facing(canopyU + du, setback - 10.5, FT + 4.5), Color = rgb(200, 202, 206), Material = Enum.Material.Metal, Parent = m })
	end
	signBoard(m, lot.facing(canopyU, setback - 10.6, FT + 10.4), "URGENCIAS", 12, rgb(200, 36, 40))
	Props.vehicle(m, lot.along(canopyU - 4, setback - 6, FT), "Ambulance")
	if not small then
		Props.vehicle(m, lot.along(-W / 2 + 10, setback - 6, FT), "Ambulance")
	end
	-- Aparcamiento detrás si cabe
	local back = setback + D + 6
	if lot.Depth - back > 30 then
		Civic.parkingLot(m, lot, -lot.Length / 2 + 6, lot.Length / 2 - 6, back, lot.Depth - 4, 0.5)
	end
	return m
end

---------------------------------------------------------------------
-- Colegio con pista deportiva y parque infantil
---------------------------------------------------------------------
local function hoop(parent: Instance, cf: CFrame)
	Builder.part({ Name = "HoopPost", Size = Vector3.new(0.5, 10, 0.5), CFrame = cf * CFrame.new(0, 5, 0), Color = Palette.Street.Metal, Parent = parent })
	Builder.decor({ Name = "Backboard", Size = Vector3.new(6, 3.6, 0.3), CFrame = cf * CFrame.new(0, 10, -1), Color = rgb(250, 250, 250), Parent = parent })
	Builder.decor({ Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2, 2), CFrame = cf * CFrame.new(0, 9, -2.3) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(230, 90, 30), Parent = parent })
end

function Civic.playground(parent: Instance, cf: CFrame)
	local m = Builder.model("Playground", parent)
	Builder.part({ Name = "SoftFloor", Size = Vector3.new(24, 0.3, 18), CFrame = cf * CFrame.new(0, 0.15, 0), Color = rgb(210, 90, 70), Material = Enum.Material.Rubber, Parent = m })
	-- Tobogán
	Builder.part({ Name = "Tower", Size = Vector3.new(4, 5, 4), CFrame = cf * CFrame.new(-6, 2.8, 0), Color = rgb(60, 140, 220), Parent = m })
	Builder.part({ Name = "TowerRoof", ClassName = "WedgePart", Size = Vector3.new(4.4, 2, 4.4), CFrame = cf * CFrame.new(-6, 6.3, 0), Color = rgb(240, 200, 40), Parent = m })
	Builder.part({ Name = "Slide", ClassName = "WedgePart", Size = Vector3.new(2.4, 5, 8), CFrame = cf * CFrame.new(-6, 2.8, 6) * CFrame.Angles(0, math.pi, 0), Color = rgb(240, 200, 40), Parent = m })
	-- Columpios
	for _, x in { 2, 10 } do
		Builder.part({ Name = "SwingPost", Size = Vector3.new(0.4, 7, 0.4), CFrame = cf * CFrame.new(x, 3.8, 0), Color = rgb(220, 60, 60), Parent = m })
	end
	Builder.part({ Name = "SwingBar", Size = Vector3.new(8.4, 0.4, 0.4), CFrame = cf * CFrame.new(6, 7.2, 0), Color = rgb(220, 60, 60), Parent = m })
	for _, x in { 4.5, 7.5 } do
		Builder.decor({ Name = "Rope", Size = Vector3.new(0.1, 5, 0.1), CFrame = cf * CFrame.new(x, 4.6, 0), Color = rgb(60, 60, 60), Parent = m })
		Builder.part({ Name = "SwingSeat", Size = Vector3.new(1.6, 0.2, 1), CFrame = cf * CFrame.new(x, 2.1, 0), Color = rgb(40, 40, 44), Parent = m })
	end
	return m
end

function Civic.school(parent: Instance, lot: Lot, townName: string)
	local m = Builder.model("Colegio", parent)
	local W = math.min(lot.Length - 24, 110)
	local D = 28
	local setback = 12
	slab(m, lot, -W / 2, W / 2, 0, setback, FT, rgb(214, 206, 190), Enum.Material.Pavement, "Entrance")
	local building, at = Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(0, setback + D / 2, 0),
		Width = W, Depth = D, Floors = 2, Style = "Clasico", GroundFloor = "Lobby",
		WallColor = rgb(196, 112, 84), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true, Back = true },
		Sign = "COLEGIO " .. string.upper(townName), SignColor = rgb(30, 90, 160),
		FloorMaterial = Enum.Material.WoodPlanks, FloorColor = rgb(196, 160, 118),
	})
	Civic.schoolInterior(building, at, W, D, townName)
	local mark = { School = townName }
	-- Mástil con bandera
	Builder.part({ Name = "Flagpole", Size = Vector3.new(0.4, 20, 0.4), CFrame = lot.facing(-W / 2 + 6, 5, 10), Color = rgb(220, 220, 224), Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "Flag", Size = Vector3.new(5, 3, 0.1), CFrame = lot.facing(-W / 2 + 8.6, 5, 18.5), Color = rgb(40, 110, 200), Material = Enum.Material.Fabric, Parent = m })
	-- Patio: pista deportiva y parque infantil
	local courtV = setback + D + 24
	if lot.Depth > courtV + 20 then
		local court = lot.facing(-12, courtV, 0)
		Builder.part({ Name = "Court", Size = Vector3.new(60, 0.4, 32), CFrame = court * CFrame.new(0, 0.2, 0), Color = rgb(56, 128, 96), Material = Enum.Material.Concrete, Tags = { "PEArea" }, Parent = m })
		for _, line in { { 60, 0.5, 0, -15.6 }, { 60, 0.5, 0, 15.6 }, { 0.5, 32, -29.6, 0 }, { 0.5, 32, 29.6, 0 }, { 0.5, 32, 0, 0 } } do
			Builder.decor({ Name = "CourtLine", Size = Vector3.new(line[1], 0.05, line[2]), CFrame = court * CFrame.new(line[3], 0.42, line[4]), Color = rgb(240, 240, 240), Parent = m })
		end
		hoop(m, court * CFrame.new(-31, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))
		hoop(m, court * CFrame.new(31, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
		Civic.playground(m, lot.facing(math.min(W / 2 - 14, 34), courtV, 0))
		-- Patio del recreo (volumen invisible: la historia sabe cuándo estás en el recreo)
		Builder.part({
			Name = "RecessArea", Size = Vector3.new(lot.Length - 10, 10, 44), CFrame = lot.facing(0, courtV, 5),
			Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false, Tags = { "RecessArea" }, Parent = m,
		})
		StoryMarks.area(m, "Patio", lot.facing(0, courtV, 5), Vector3.new(lot.Length - 10, 10, 44), mark)
		-- Los tres grupos del recreo: deportistas (pista), artistas (tizas junto al parque infantil), estudiantes (banco)
		StoryMarks.spot(m, "Grupo_Deportistas", lot.facing(-12, courtV + 19, FT + 2.5), mark)
		StoryMarks.spot(m, "Grupo_Artistas", lot.facing(34, courtV + 13, FT + 2.5), mark)
		for k, color in { rgb(250, 120, 160), rgb(90, 180, 250), rgb(250, 220, 80), rgb(140, 220, 120) } do
			Builder.decor({ Name = "ChalkDrawing", Size = Vector3.new(2.6, 0.05, 2.6), CFrame = lot.facing(28 + k * 3, courtV + 16, 0.03) * CFrame.Angles(0, math.rad(k * 17), 0), Color = color, Parent = m })
		end
		Builder.part({ Name = "Easel", Size = Vector3.new(2.4, 3.6, 0.3), CFrame = lot.facing(40, courtV + 13, 1.8) * CFrame.Angles(math.rad(-12), 0, 0), Color = rgb(250, 250, 245), Parent = m })
		Props.bench(m, lot.facing(-40, setback + D + 5, 0))
		StoryMarks.spot(m, "Grupo_Estudiantes", lot.facing(-36, setback + D + 5, FT + 2.5), mark)
		-- Sitios para las pistas de "La mochila desaparecida" (la historia pone el objeto)
		StoryMarks.spot(m, "Pista_Papel", lot.facing(0, courtV + 21, FT + 2.5), mark)
		StoryMarks.spot(m, "Pista_Pegatina", lot.facing(46, courtV - 6, FT + 2.5), mark)
	end
	-- Campo de fútbol y gimnasio al fondo del recinto
	local fieldV = courtV + 40 + 30
	if lot.Depth > fieldV + 32 then
		local field = lot.facing(-12, fieldV, 0)
		Builder.part({ Name = "Pitch", Size = Vector3.new(80, 0.35, 50), CFrame = field * CFrame.new(0, 0.18, 0), Color = rgb(74, 148, 70), Material = Enum.Material.Grass, Tags = { "PEArea" }, Parent = m })
		for _, line in { { 80, 0.5, 0, -24.6 }, { 80, 0.5, 0, 24.6 }, { 0.5, 50, -39.6, 0 }, { 0.5, 50, 39.6, 0 }, { 0.5, 50, 0, 0 } } do
			Builder.decor({ Name = "PitchLine", Size = Vector3.new(line[1], 0.05, line[2]), CFrame = field * CFrame.new(line[3], 0.37, line[4]), Color = rgb(245, 245, 245), Parent = m })
		end
		for _, side in { -1, 1 } do
			local goal = field * CFrame.new(side * 39, 0, 0)
			Builder.part({ Name = "GoalBar", Size = Vector3.new(0.4, 0.4, 12), CFrame = goal * CFrame.new(0, 6, 0), Color = rgb(250, 250, 250), Parent = m })
			for _, z in { -6, 6 } do
				Builder.part({ Name = "GoalPost", Size = Vector3.new(0.4, 6, 0.4), CFrame = goal * CFrame.new(0, 3, z), Color = rgb(250, 250, 250), Parent = m })
			end
		end
		StoryMarks.spot(m, "Futbol_Centro", field * CFrame.new(0, FT + 2.5, 0), mark)
		StoryMarks.spot(m, "Futbol_PorteriaA", field * CFrame.new(-36, FT + 2.5, 0), mark)
		StoryMarks.spot(m, "Futbol_PorteriaB", field * CFrame.new(36, FT + 2.5, 0), mark)
		local gymU = math.min(W / 2 - 12, 48)
		Civic.schoolGym(m, lot.facing(gymU, fieldV, 0), townName)
		StoryMarks.spot(m, "Pista_Huella", lot.facing(gymU - 4, fieldV - 26, FT + 2.5), mark)
		StoryMarks.spot(m, "Pista_Objeto", lot.facing(gymU + 5, fieldV - 20, FT + 2.5), mark)
		-- Comedor y biblioteca a un lado del campo
		if lot.Length >= 190 then
			Civic.schoolCanteen(m, lot.facing(-lot.Length / 2 + 24, fieldV - 24, 0), townName)
		end
	end
	-- Llegada al colegio: padres, autobús escolar y el balón del camino
	StoryMarks.spot(m, "Balon_Camino", lot.facing(-W / 2 - 22, -4, FT + 2.5), mark)
	for i, u in { -18, 14, 24 } do
		StoryMarks.spot(m, "Padres_" .. i, lot.facing(u, 6, FT + 2.5), mark)
	end
	Props.vehicle(m, lot.along(W / 2 + 16, -11.3, 0.4), "SchoolBus")
	StoryMarks.spot(m, "Autobus", lot.facing(W / 2 + 6, -4, FT + 2.5), mark)

	-- Valla del recinto (laterales y fondo)
	local half = lot.Length / 2 - 3
	for _, u in { -half, half } do
		Builder.part({ Name = "Fence", Size = Vector3.new(0.3, 5, lot.Depth - setback - 4), CFrame = lot.facing(u, (lot.Depth + setback) / 2, 2.5), Color = rgb(40, 110, 70), Material = Enum.Material.Metal, Transparency = 0.3, Parent = m })
	end
	for _, u in { -half + 8, half - 8 } do
		Nature.tree(m, lot.point(u, lot.Depth - 10, 0))
	end
	return m
end

---------------------------------------------------------------------
-- Interior del colegio (para las clases de la historia):
--   [ Aula A | Entrada | Aula B | Música ]   dentro del edificio de una planta jugable
-- Etiquetas: Classroom / Desk / Board / TeacherSpot (atributo ClassroomId), MusicRoom, SchoolEntrance.
-- Los tabiques caen entre ventanas para no cortarlas.
---------------------------------------------------------------------
local SCHOOL_G = 13 -- altura interior de la planta baja "Lobby"

local function invisible(props: { [string]: any }): BasePart
	props.Transparency = 1
	props.CanCollide = false
	props.CanQuery = false
	props.CastShadow = false
	return Builder.part(props)
end

-- Tabique a lo ancho (eje Z) en x, con puerta centrada
local function schoolPartition(model: Model, at: (number, number, number) -> CFrame, x: number, halfD: number)
	local wallColor = rgb(242, 236, 222)
	for _, seg in { { -halfD, -2.5 }, { 2.5, halfD } } do
		Builder.part({ Name = "Partition", Size = Vector3.new(0.6, SCHOOL_G, seg[2] - seg[1]), CFrame = at(x, SCHOOL_G / 2, (seg[1] + seg[2]) / 2), Color = wallColor, Material = Enum.Material.Plaster, Parent = model })
	end
	Builder.part({ Name = "Lintel", Size = Vector3.new(0.6, SCHOOL_G - 8, 5), CFrame = at(x, 8 + (SCHOOL_G - 8) / 2, 0), Color = wallColor, Material = Enum.Material.Plaster, Parent = model })
end

local function classroom(model: Model, at: (number, number, number) -> CFrame, id: string, x0: number, x1: number, boardX: number, facing: number, deskXs: { number })
	local halfD = 13
	invisible({ Name = "Classroom_" .. id, Size = Vector3.new(x1 - x0, 10, halfD * 2), CFrame = at((x0 + x1) / 2, 5, 0), Tags = { "Classroom" }, Attributes = { ClassroomId = id }, Parent = model })
	-- Pizarra y mesa del profesor
	Builder.part({ Name = "Board", Size = Vector3.new(0.2, 4.5, 11), CFrame = at(boardX, 5.8, 0), Color = rgb(34, 70, 52), Material = Enum.Material.Slate, Tags = { "Board" }, Attributes = { ClassroomId = id }, Parent = model })
	Builder.decor({ Name = "BoardFrame", Size = Vector3.new(0.3, 5, 11.6), CFrame = at(boardX - facing * 0.05, 5.8, 0), Color = rgb(150, 110, 70), Material = Enum.Material.Wood, Parent = model })
	local teacherX = boardX + facing * 3.5
	invisible({ Name = "TeacherSpot_" .. id, Size = Vector3.new(2, 5, 2), CFrame = at(teacherX, 2.5, 0), Tags = { "TeacherSpot" }, Attributes = { ClassroomId = id }, Parent = model })
	Builder.part({ Name = "TeacherDesk", Size = Vector3.new(2.6, 2.8, 5), CFrame = at(teacherX + facing * 2.6, 1.4, 5), Color = rgb(130, 92, 60), Material = Enum.Material.Wood, Parent = model })
	-- Pupitres mirando a la pizarra
	for _, x in deskXs do
		for _, z in { -9, -3, 3, 9 } do
			Builder.part({ Name = "Desk", Size = Vector3.new(2.6, 2.6, 3.2), CFrame = at(x, 1.3, z), Color = rgb(206, 170, 120), Material = Enum.Material.Wood, Tags = { "Desk" }, Attributes = { ClassroomId = id }, Parent = model })
			Builder.part({ Name = "Chair", Size = Vector3.new(1.8, 1.6, 1.8), CFrame = at(x + facing * 2.4, 0.8, z), Color = rgb(60, 110, 180), Parent = model })
		end
	end
end

function Civic.schoolInterior(model: Model, ground: (number, number, number) -> CFrame, W: number, D: number, townName: string?)
	-- Muebles sobre el suelo interior (a FT del terreno); los tabiques, desde el terreno
	local function at(x: number, y: number, z: number): CFrame
		return ground(x, y + FT, z)
	end
	local half = W / 2 - 1
	local halfD = D / 2 - 1
	-- Entrada (fuera, delante de la puerta) y vestíbulo
	invisible({ Name = "SchoolEntrance", Size = Vector3.new(4, 5, 2), CFrame = at(0, 2.5, -D / 2 - 2), Tags = { "SchoolEntrance" }, Parent = model })
	if W < 100 then
		classroom(model, at, "A", -half, half, -half + 0.6, 1, { -half + 10, -half + 18, -half + 26 })
		return
	end
	schoolPartition(model, ground, -11.8, halfD)
	schoolPartition(model, ground, 11.8, halfD)
	schoolPartition(model, ground, 35.8, halfD)
	classroom(model, at, "A", -half, -11.8, -half + 0.6, 1, { -44, -36, -28, -20 })
	classroom(model, at, "B", 11.8, 35.8, 35.2, -1, { 17, 25 })
	-- Sala de música
	invisible({ Name = "MusicRoom", Size = Vector3.new(half - 35.8, 10, halfD * 2), CFrame = at((35.8 + half) / 2, 5, 0), Tags = { "MusicRoom" }, Parent = model })
	Builder.part({ Name = "Piano", Size = Vector3.new(5, 3.4, 2), CFrame = at(46, 1.7, halfD - 1.5), Color = rgb(24, 22, 26), Parent = model })
	Builder.decor({ Name = "PianoKeys", Size = Vector3.new(4.6, 0.2, 0.8), CFrame = at(46, 3.5, halfD - 3), Color = rgb(245, 245, 245), Parent = model })
	for i, color in { rgb(200, 40, 40), rgb(220, 220, 224), rgb(220, 220, 224) } do
		Builder.part({ Name = "Drum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 2.4, 2.4), CFrame = at(40 + i * 2.6, 1, -halfD + 3) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Parent = model })
	end
	for _, z in { -4, 0, 4 } do
		Builder.part({ Name = "MusicChair", Size = Vector3.new(1.8, 1.6, 1.8), CFrame = at(44, 0.8, z), Color = rgb(230, 150, 40), Parent = model })
	end
	-- Corcho con dibujos en el vestíbulo
	for i, color in { rgb(240, 200, 60), rgb(90, 170, 230), rgb(230, 100, 120) } do
		Builder.decor({ Name = "Drawing", Size = Vector3.new(2.4, 2, 0.1), CFrame = at(-6 + i * 3, 6, halfD - 0.1), Color = color, Parent = model })
	end

	-- Pasillo con taquillas (misiones "El primer día" y "La mochila desaparecida")
	local mark = { School = townName }
	StoryMarks.area(model, "Pasillo", at(0, 5, 0), Vector3.new(23, 10, halfD * 2), mark)
	for i, x in { -10.4, -8.1, -5.8, 5.8, 8.1, 10.4 } do
		local locker = Builder.part({ Name = "Locker", Size = Vector3.new(2.1, 6, 1.3), CFrame = at(x, 3, halfD - 0.7), Color = if i % 2 == 0 then rgb(50, 110, 180) else rgb(60, 130, 200), Material = Enum.Material.Metal, Parent = model })
		Builder.decor({ Name = "LockerVent", Size = Vector3.new(1.4, 0.8, 0.05), CFrame = at(x, 5, halfD - 1.37), Color = rgb(30, 60, 110), Parent = model })
		local plate = Builder.decor({ Name = "LockerNumber", Size = Vector3.new(0.7, 0.5, 0.05), CFrame = at(x, 4.2, halfD - 1.37), Color = rgb(240, 240, 240), Parent = model })
		Builder.sign(plate, tostring(i), Enum.NormalId.Front, rgb(20, 20, 24))
		StoryMarks.prop(model, "Taquilla", locker.CFrame * CFrame.new(0, 0, -1), Vector3.new(2.2, 6, 1.6), { School = townName, LockerId = i })
	end
	StoryMarks.spot(model, "Informante_Pasillo", at(-6, 2.5, -6), mark)
	StoryMarks.spot(model, "Libros", at(5, 2.5, -2), mark)
	StoryMarks.spot(model, "Profesor_Entrada", at(4, 2.5, -D / 2 - 4), mark)
end

---------------------------------------------------------------------
-- Pabellón del colegio: gimnasio con canasta y, al fondo, el almacén (oscuro y lleno de trastos)
---------------------------------------------------------------------
function Civic.schoolGym(parent: Instance, cf: CFrame, townName: string)
	local W, D, G = 24, 34, 16
	local model, ground = Building.build({
		Name = "Gimnasio", Parent = parent, CFrame = cf,
		Width = W, Depth = D, Floors = 1, GroundHeight = G, Style = "Moderno", GroundFloor = "Lobby",
		WallColor = rgb(226, 214, 196), Balconies = false, WindowFaces = { Front = true, Left = true, Right = true },
		FloorMaterial = Enum.Material.WoodPlanks, FloorColor = rgb(214, 170, 110), LightColor = rgb(246, 248, 255),
	})
	local function at(x: number, y: number, z: number): CFrame
		return ground(x, y + FT, z)
	end
	local mark = { School = townName }
	local wall = rgb(236, 230, 218)
	-- Tabique con puerta entre la pista y el almacén (z = 7)
	for _, seg in { { -11, -1.8 }, { 1.8, 11 } } do
		Builder.part({ Name = "Partition", Size = Vector3.new(seg[2] - seg[1], G, 0.6), CFrame = ground((seg[1] + seg[2]) / 2, G / 2, 7), Color = wall, Material = Enum.Material.Plaster, Parent = model })
	end
	Builder.part({ Name = "Lintel", Size = Vector3.new(3.6, G - 8, 0.6), CFrame = ground(0, 8 + (G - 8) / 2, 7), Color = wall, Material = Enum.Material.Plaster, Parent = model })
	local door = Builder.part({ Name = "StorageSign", Size = Vector3.new(3, 0.8, 0.1), CFrame = at(0, 7.6, 6.65), Color = rgb(40, 40, 46), Parent = model })
	Builder.sign(door, "ALMACÉN", Enum.NormalId.Front, rgb(255, 210, 80))

	-- Pista: canasta en el tabique, líneas, colchonetas y bancos
	StoryMarks.area(model, "Gimnasio", at(0, 6, -4.5), Vector3.new(W - 2, 12, 22), mark)
	Builder.decor({ Name = "Backboard", Size = Vector3.new(5, 3.4, 0.3), CFrame = at(-6, 9, 6.4), Color = rgb(250, 250, 250), Parent = model })
	Builder.decor({ Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2, 2), CFrame = at(-6, 7.8, 5.2) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(230, 90, 30), Parent = model })
	Builder.decor({ Name = "Net", Size = Vector3.new(1.4, 1.2, 1.4), CFrame = at(-6, 7.1, 5.2), Color = rgb(250, 250, 250), Material = Enum.Material.Fabric, Transparency = 0.4, Parent = model })
	StoryMarks.prop(model, "Canasta", at(-6, 2.5, -1), Vector3.new(4, 5, 4), mark) -- desde aquí se tira
	Builder.decor({ Name = "FreeThrowLine", Size = Vector3.new(4, 0.05, 0.3), CFrame = at(-6, 0.03, -1.8), Color = rgb(250, 250, 250), Parent = model })
	for k = 0, 2 do
		Builder.decor({ Name = "Ball", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = at(-9.5 + k * 1.3, 0.6, 5), Color = rgb(230, 110, 40), Parent = model })
	end
	for _, z in { -12, -8 } do
		Builder.part({ Name = "Mat", Size = Vector3.new(4, 0.5, 3.4), CFrame = at(8, 0.25, z), Color = rgb(40, 90, 180), Material = Enum.Material.Fabric, Parent = model })
	end
	Builder.part({ Name = "Bench", Size = Vector3.new(1.2, 1.4, 8), CFrame = at(-10, 0.7, -9), Color = rgb(170, 120, 70), Material = Enum.Material.Wood, Parent = model })
	StoryMarks.spot(model, "Gimnasio_Grupo", at(3, 2.5, -2) * CFrame.Angles(0, math.rad(180), 0), mark)

	-- Almacén: estanterías, cajas, balones, conos y varias mochilas olvidadas (ninguna es la tuya… o sí)
	StoryMarks.area(model, "Almacen", at(0, 6, 11.5), Vector3.new(W - 2, 12, 8.4), mark)
	for _, x in { -9.5, 9.5 } do
		Builder.part({ Name = "Shelf", Size = Vector3.new(2, 7, 7), CFrame = at(x, 3.5, 11.6), Color = rgb(120, 120, 128), Material = Enum.Material.Metal, Parent = model })
		for level = 0, 2 do
			Builder.decor({ Name = "Box", Size = Vector3.new(1.6, 1.4, 2), CFrame = at(x, 1 + level * 2.3, 10 + (level % 2) * 2.5), Color = rgb(180, 140, 90), Material = Enum.Material.Cardboard, Parent = model })
		end
	end
	for k = 0, 3 do
		Builder.decor({ Name = "Cone", Size = Vector3.new(0.8, 1.2, 0.8), CFrame = at(-6 + k, 0.6, 15), Color = rgb(250, 120, 30), Parent = model })
	end
	Builder.part({ Name = "BallCart", Size = Vector3.new(3, 2.2, 2), CFrame = at(5, 1.1, 14.5), Color = rgb(90, 90, 96), Material = Enum.Material.Metal, Parent = model })
	local bagColors = { rgb(200, 50, 60), rgb(40, 150, 90), rgb(240, 190, 40), rgb(120, 60, 160), rgb(40, 110, 200) }
	for i, x in { -6.5, -4, -1, 2, 4.5 } do
		local bag = at(x, 0.9, 9.2 + (i % 2) * 1.2) * CFrame.Angles(0, math.rad(i * 23), 0)
		Builder.part({ Name = "LostBackpack", Size = Vector3.new(1.4, 1.8, 0.9), CFrame = bag, Color = bagColors[i], Material = Enum.Material.Fabric, Parent = model })
		StoryMarks.prop(model, "MochilaAlmacen", bag, Vector3.new(2, 2.4, 2), { School = townName, Index = i })
	end
	Builder.decor({ Name = "OldTrophy", Size = Vector3.new(0.8, 1.6, 0.8), CFrame = at(9.5, 7.8, 11.6), Color = rgb(210, 170, 60), Material = Enum.Material.Metal, Parent = model })
	StoryMarks.spot(model, "Almacen_NPC", at(6, 2.5, 13) * CFrame.Angles(0, math.rad(180), 0), mark)
	StoryMarks.spot(model, "Gimnasio_Puerta", at(0, 2.5, -D / 2 - 3), mark)
	return model
end

---------------------------------------------------------------------
-- Edificio del comedor (delante) y la biblioteca del colegio (detrás)
---------------------------------------------------------------------
function Civic.schoolCanteen(parent: Instance, cf: CFrame, townName: string)
	local W, D, G = 36, 46, 13
	local model, ground = Building.build({
		Name = "ComedorBiblioteca", Parent = parent, CFrame = cf,
		Width = W, Depth = D, Floors = 1, GroundHeight = G, Style = "Clasico", GroundFloor = "Lobby",
		WallColor = rgb(206, 128, 96), Balconies = false, WindowFaces = { Front = true, Left = true, Right = true, Back = true },
		Sign = "COMEDOR · BIBLIOTECA", SignColor = rgb(30, 90, 160),
		FloorMaterial = Enum.Material.WoodPlanks, FloorColor = rgb(196, 160, 118),
	})
	local function at(x: number, y: number, z: number): CFrame
		return ground(x, y + FT, z)
	end
	local mark = { School = townName }
	local wall = rgb(242, 236, 222)
	for _, seg in { { -17, -2.5 }, { 2.5, 17 } } do
		Builder.part({ Name = "Partition", Size = Vector3.new(seg[2] - seg[1], G, 0.6), CFrame = ground((seg[1] + seg[2]) / 2, G / 2, 2), Color = wall, Material = Enum.Material.Plaster, Parent = model })
	end
	Builder.part({ Name = "Lintel", Size = Vector3.new(5, G - 8, 0.6), CFrame = ground(0, 8 + (G - 8) / 2, 2), Color = wall, Material = Enum.Material.Plaster, Parent = model })

	-- COMEDOR: mesas largas con bancos y la barra con bandejas
	StoryMarks.area(model, "Comedor", at(0, 5, -10), Vector3.new(W - 2, 10, 23), mark)
	for _, x in { -11, -5, 8 } do
		Builder.part({ Name = "Table", Size = Vector3.new(2.6, 0.3, 14), CFrame = at(x, 2.6, -10), Color = rgb(236, 232, 224), Material = Enum.Material.Wood, Parent = model })
		Builder.decor({ Name = "TableLegs", Size = Vector3.new(1.6, 2.5, 12), CFrame = at(x, 1.25, -10), Color = rgb(150, 150, 156), Material = Enum.Material.Metal, Transparency = 0.5, Parent = model })
		for _, side in { -1, 1 } do
			Builder.part({ Name = "Bench", Size = Vector3.new(1, 1.5, 14), CFrame = at(x + side * 2, 0.75, -10), Color = rgb(60, 110, 180), Parent = model })
		end
	end
	Builder.part({ Name = "ServingCounter", Size = Vector3.new(3, 3.4, 14), CFrame = at(15, 1.7, -11), Color = rgb(200, 204, 210), Material = Enum.Material.Metal, Parent = model })
	for k = 0, 3 do
		Builder.decor({ Name = "Tray", Size = Vector3.new(1.6, 0.15, 1.2), CFrame = at(15, 3.5, -16 + k * 3), Color = Color3.fromHSV(k / 5, 0.5, 0.9), Parent = model })
	end
	StoryMarks.prop(model, "BarraComedor", at(13, 2.5, -11), Vector3.new(3, 5, 14), mark)
	StoryMarks.spot(model, "Informante_Comedor", at(-8, 2.5, -4) * CFrame.Angles(0, math.rad(180), 0), mark)

	-- BIBLIOTECA: estanterías llenas, mesas de lectura y el mostrador
	StoryMarks.area(model, "Biblioteca", at(0, 5, 12), Vector3.new(W - 2, 10, 19), mark)
	local function shelf(cfShelf: CFrame, length: number)
		Builder.part({ Name = "Bookshelf", Size = Vector3.new(length, 8, 1.6), CFrame = cfShelf * CFrame.new(0, 4, 0), Color = rgb(120, 82, 52), Material = Enum.Material.Wood, Parent = model })
		for level = 0, 3 do
			local x = -length / 2 + 0.6
			while x < length / 2 - 0.6 do
				local w = 0.3 + math.random() * 0.35
				Builder.decor({
					Name = "Book", Size = Vector3.new(w, 1.2 + math.random() * 0.4, 1.2), CFrame = cfShelf * CFrame.new(x + w / 2, 1.1 + level * 1.9, -0.25),
					Color = Color3.fromHSV(math.random(), 0.55, 0.45 + math.random() * 0.4), Parent = model,
				})
				x += w + 0.05
			end
		end
	end
	shelf(at(0, 0, 21.4) * CFrame.Angles(0, math.pi, 0), 20)
	for _, z in { 9, 15 } do
		shelf(at(-15.8, 0, z) * CFrame.Angles(0, math.rad(90), 0), 5)
		shelf(at(15.8, 0, z) * CFrame.Angles(0, math.rad(-90), 0), 5)
	end
	for _, x in { -6, 6 } do
		Builder.part({ Name = "ReadingTable", Size = Vector3.new(6, 0.3, 3), CFrame = at(x, 2.6, 13), Color = rgb(170, 120, 80), Material = Enum.Material.Wood, Parent = model })
		Builder.decor({ Name = "Lamp", Size = Vector3.new(0.5, 1.2, 0.5), CFrame = at(x + 2, 3.35, 13), Color = rgb(60, 140, 90), Parent = model })
		for _, dz in { -2.2, 2.2 } do
			Builder.part({ Name = "Chair", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = at(x, 0.8, 13 + dz), Color = rgb(60, 110, 180), Parent = model })
		end
	end
	Builder.part({ Name = "LibraryDesk", Size = Vector3.new(6, 3.2, 2), CFrame = at(10, 1.6, 5), Color = rgb(120, 82, 52), Material = Enum.Material.Wood, Parent = model })
	StoryMarks.prop(model, "Apuntes", at(-6, 3.2, 13), Vector3.new(3, 2, 2), mark) -- misión del examen: coger apuntes
	StoryMarks.spot(model, "Bibliotecaria", at(10, 2.5, 7.5) * CFrame.Angles(0, math.rad(180), 0), mark)
	StoryMarks.spot(model, "Informante_Biblioteca", at(6, 2.5, 10) * CFrame.Angles(0, math.rad(180), 0), mark)
	return model
end

---------------------------------------------------------------------
-- Bomberos y policía (comparten manzana)
---------------------------------------------------------------------
function Civic.fireStation(parent: Instance, lot: Lot, u: number)
	local m = Builder.model("Bomberos", parent)
	local W, D, setback = 44, 34, 16
	slab(m, lot, u - W / 2 - 2, u + W / 2 + 2, 0, setback, FT, rgb(200, 198, 192), Enum.Material.Concrete, "Apron")
	local model, at, info = Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(u, setback + D / 2, 0),
		Width = W, Depth = D, Floors = 2, Style = "Clasico", GroundFloor = "Garage",
		WallColor = rgb(176, 50, 42), Balconies = false, Interior = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "BOMBEROS", SignColor = rgb(40, 40, 44),
	})
	-- Torre de entrenamiento
	Builder.part({ Name = "Tower", Size = Vector3.new(8, info.Top + 8, 8), CFrame = at(W / 2 - 4, (info.Top + 8) / 2 - FT, D / 2 - 4), Color = rgb(176, 50, 42), Material = Enum.Material.Brick, Parent = model })
	Props.vehicle(m, lot.along(u - 4, setback - 8, FT), "FireTruck")
	return m
end

function Civic.policeStation(parent: Instance, lot: Lot, u: number)
	local m = Builder.model("Policia", parent)
	local W, D, setback = 44, 30, 16
	slab(m, lot, u - W / 2 - 2, u + W / 2 + 2, 0, setback, FT, rgb(200, 198, 192), Enum.Material.Concrete, "Apron")
	local model, at, info = Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(u, setback + D / 2, 0),
		Width = W, Depth = D, Floors = 3, Style = "Moderno", GroundFloor = "Lobby",
		WallColor = rgb(234, 236, 240), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "POLICÍA", SignColor = rgb(24, 60, 150),
	})
	-- Franja azul corporativa
	Builder.decor({ Name = "Band", Size = Vector3.new(W + 0.4, 1.4, 0.4), CFrame = at(0, info.GroundTop - FT + 0.8, -D / 2 - 0.25), Color = rgb(30, 70, 180), Parent = model })
	for i, du in { -12, 0, 12 } do
		if i ~= 2 then
			Props.vehicle(m, lot.facing(u + du, setback - 7, FT), "Police")
		end
	end
	return m
end

function Civic.firePolice(parent: Instance, lot: Lot)
	local m = Builder.model("ServiciosEmergencia", parent)
	if lot.Length >= 110 then
		Civic.fireStation(m, lot, -lot.Length / 4)
		Civic.policeStation(m, lot, lot.Length / 4)
	else
		Civic.fireStation(m, lot, 0)
	end
	return m
end

---------------------------------------------------------------------
-- Centro comercial con aparcamiento delante
---------------------------------------------------------------------
function Civic.mall(parent: Instance, lot: Lot, townName: string)
	local m = Builder.model("CentroComercial", parent)
	local W = math.min(lot.Length - 16, 150)
	local D = math.min(math.floor(lot.Depth * 0.5), 90)
	local back = lot.Depth - 4 - D / 2
	local model, at, info = Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(0, back, 0),
		Width = W, Depth = D, Floors = 2, GroundHeight = 18, FloorHeight = 14, Style = "Moderno", GroundFloor = "Shop",
		WallColor = rgb(238, 238, 234), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "CENTRO COMERCIAL " .. string.upper(townName), SignColor = rgb(120, 40, 140), ShopId = "CentroComercial",
		FloorMaterial = Enum.Material.Marble, FloorColor = rgb(236, 232, 226), LightColor = rgb(255, 244, 228),
	})
	-- Atrio de cristal sobre la entrada
	Builder.part({ Name = "Atrium", Size = Vector3.new(26, info.Top - FT + 6, 8), CFrame = at(0, (info.Top - FT + 6) / 2, -D / 2 - 3), Color = rgb(150, 196, 220), Material = Enum.Material.Glass, Transparency = 0.45, Reflectance = 0.2, CanCollide = false, Parent = model })
	-- Letreros de tiendas en la fachada
	local brands = { { "MODA", rgb(220, 60, 90) }, { "CINE", rgb(30, 30, 34) }, { "HOGAR", rgb(40, 140, 110) }, { "TECNO", rgb(40, 100, 200) } }
	for i, b in brands do
		local du = (if i <= 2 then -1 else 1) * (W / 2 - 16 - ((i - 1) % 2) * 22)
		local board = Builder.decor({ Name = "Brand", Size = Vector3.new(16, 3, 0.3), CFrame = at(du, info.GroundTop - FT - 1.8, -D / 2 - 0.3), Color = b[2], Parent = model })
		Builder.sign(board, b[1], Enum.NormalId.Front)
	end
	-- Aparcamiento
	local front = back - D / 2 - 6
	if front > 30 then
		Civic.parkingLot(m, lot, -lot.Length / 2 + 6, lot.Length / 2 - 6, 4, front, 0.6)
	end
	return m
end

---------------------------------------------------------------------
-- Gasolinera
---------------------------------------------------------------------
function Civic.gasStation(parent: Instance, lot: Lot)
	local m = Builder.model("Gasolinera", parent)
	local L = math.min(lot.Length - 10, 70)
	slab(m, lot, -L / 2, L / 2, 0, 44, 0.5, rgb(190, 188, 184), Enum.Material.Concrete, "Apron")
	local canopy = lot.facing(0, 16, 11)
	Builder.part({ Name = "Canopy", Size = Vector3.new(34, 1.4, 20), CFrame = canopy, Color = rgb(245, 245, 245), Parent = m })
	Builder.decor({ Name = "CanopyBand", Size = Vector3.new(34.2, 0.8, 20.2), CFrame = canopy * CFrame.new(0, 0.2, 0), Color = rgb(30, 150, 80), Parent = m })
	for _, du in { -12, 12 } do
		for _, dv in { -6, 6 } do
			Builder.part({ Name = "Pillar", Size = Vector3.new(1, 10.5, 1), CFrame = lot.facing(du, 16 + dv, 5.5), Color = rgb(235, 235, 235), Parent = m })
		end
		Builder.part({ Name = "Pump", Size = Vector3.new(2, 4.5, 1.4), CFrame = lot.facing(du, 16, 2.75), Color = rgb(30, 150, 80), Parent = m })
		Builder.decor({ Name = "PumpScreen", Size = Vector3.new(1.4, 1, 0.1), CFrame = lot.facing(du, 16 - 0.75, 3.8), Color = rgb(20, 20, 24), Material = Enum.Material.Neon, Parent = m })
	end
	Building.build({
		Name = "Tienda", Parent = m, CFrame = lot.facing(0, 36, 0),
		Width = 26, Depth = 14, Floors = 1, Style = "Moderno", GroundFloor = "Shop", Balconies = false,
		WallColor = rgb(240, 240, 238), WindowFaces = { Front = true }, Sign = "24H", SignColor = rgb(30, 150, 80), ShopId = "Gasolinera",
	})
	-- Tótem de precios
	local pylon = lot.facing(L / 2 - 4, 3, 0)
	Builder.part({ Name = "Pylon", Size = Vector3.new(1, 12, 1), CFrame = pylon * CFrame.new(0, 6, 0), Color = rgb(60, 60, 64), Parent = m })
	signBoard(m, pylon * CFrame.new(0, 12, 0), "GASOLINA 1,59\nDIÉSEL 1,49", 7, rgb(30, 150, 80))
	Props.car(m, lot.along(-12, 11, 0.5))
	return m
end

---------------------------------------------------------------------
-- Parque con estanque, caminos, bancos y parque infantil
---------------------------------------------------------------------
function Civic.park(parent: Instance, lot: Lot, townName: string?)
	local m = Builder.model("Parque", parent)
	local mark = { Town = townName }
	local L, Dp = lot.Length, lot.Depth
	slab(m, lot, -L / 2, L / 2, 0, Dp, 0.3, Palette.Ground.Lawn, Enum.Material.Grass, "Lawn")
	-- Caminos en cruz
	slab(m, lot, -3, 3, 0, Dp, 0.45, rgb(214, 200, 170), Enum.Material.Pavement, "Path")
	slab(m, lot, -L / 2, L / 2, Dp / 2 - 3, Dp / 2 + 3, 0.46, rgb(214, 200, 170), Enum.Material.Pavement, "Path")
	-- Estanque
	if L >= 120 and Dp >= 120 then
		local pond = lot.facing(L / 4 + 2, Dp / 4 + 2, 0)
		Builder.part({ Name = "PondRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 34, 34), CFrame = pond * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(170, 160, 146), Material = Enum.Material.Cobblestone, Parent = m })
		Builder.part({ Name = "PondWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 31, 31), CFrame = pond * CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(60, 130, 170), Material = Enum.Material.Glass, Transparency = 0.2, Reflectance = 0.3, CanCollide = false, Parent = m })
		local playground = lot.facing(-L / 4, Dp * 0.75, 0.3)
		Civic.playground(m, playground)
		StoryMarks.prop(m, "Columpios", playground * CFrame.new(6, 3.5, 0), Vector3.new(9, 7, 4), mark)
	else
		local playground = lot.facing(-L / 4, Dp / 2 + 16, 0.3)
		Civic.playground(m, playground)
		StoryMarks.prop(m, "Columpios", playground * CFrame.new(6, 3.5, 0), Vector3.new(9, 7, 4), mark)
	end

	-- Para quedar con los amigos (misión "El grupo"): media pista de baloncesto, fuente y quiosco
	StoryMarks.area(m, "Parque", lot.facing(0, Dp / 2, 5), Vector3.new(L, 10, Dp), mark)
	local courtV = Dp * 0.75
	slab(m, lot, L / 4 - 9, L / 4 + 13, courtV - 10, courtV + 10, 0.42, rgb(56, 128, 96), Enum.Material.Concrete, "HalfCourt")
	Builder.decor({ Name = "CourtLine", Size = Vector3.new(0.4, 0.05, 20), CFrame = lot.facing(L / 4 - 8.6, courtV, 0.44), Color = rgb(240, 240, 240), Parent = m })
	local hoopBase = lot.point(L / 4 + 12, courtV, 0.42)
	hoop(m, Builder.facing(hoopBase, lot.point(L / 4, courtV, 0.42) - hoopBase))
	StoryMarks.prop(m, "Canasta", CFrame.new(lot.point(L / 4 + 4, courtV, 2.9)), Vector3.new(4, 5, 4), mark)
	StoryMarks.spot(m, "Parque_Canasta", lot.facing(L / 4 - 4, courtV + 6, 2.9), mark)

	local fountain = lot.point(-L / 4, Dp * 0.25, 0.3)
	Builder.part({ Name = "FountainRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 10, 10), CFrame = CFrame.new(fountain + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(226, 222, 212), Material = Enum.Material.Limestone, Parent = m })
	Builder.part({ Name = "FountainWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 9, 9), CFrame = CFrame.new(fountain + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(70, 150, 210), Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false, Parent = m })
	Builder.part({ Name = "FountainColumn", Size = Vector3.new(1.2, 4, 1.2), CFrame = CFrame.new(fountain + Vector3.new(0, 2.6, 0)), Color = rgb(226, 222, 212), Material = Enum.Material.Limestone, Parent = m })
	StoryMarks.prop(m, "Fuente", CFrame.new(fountain + Vector3.new(0, 2.5, 0)), Vector3.new(11, 5, 11), mark)
	StoryMarks.spot(m, "Parque_Fuente", CFrame.new(fountain + Vector3.new(7, 2.5, 0)), mark)

	-- Quiosco (tienda: chuches, bebidas, cromos)
	local kiosk = lot.facing(-20, Dp / 2 - 14, 0.3)
	Builder.part({ Name = "KioskBody", Size = Vector3.new(7, 6, 6), CFrame = kiosk * CFrame.new(0, 3, 0), Color = rgb(40, 120, 90), Parent = m })
	Builder.part({ Name = "KioskRoof", Size = Vector3.new(8.4, 0.5, 7.6), CFrame = kiosk * CFrame.new(0, 6.3, -0.4), Color = rgb(230, 70, 60), Parent = m })
	Builder.part({ Name = "KioskCounter", Size = Vector3.new(6, 0.4, 1.2), CFrame = kiosk * CFrame.new(0, 3.4, -3.4), Color = rgb(236, 232, 224), Parent = m })
	for k = 0, 4 do
		Builder.decor({ Name = "Sweets", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = kiosk * CFrame.new(-2.4 + k * 1.2, 4.1, -3.4), Color = Color3.fromHSV(k / 5, 0.7, 0.95), Parent = m })
	end
	local kioskSign = Builder.decor({ Name = "KioskSign", Size = Vector3.new(6, 1.2, 0.2), CFrame = kiosk * CFrame.new(0, 5.4, -3.05), Color = rgb(250, 240, 220), Parent = m })
	Builder.sign(kioskSign, "QUIOSCO", Enum.NormalId.Front, rgb(200, 40, 50))
	Builder.part({
		Name = "ShopEntrance", Size = Vector3.new(4, 5, 2), CFrame = kiosk * CFrame.new(0, 2.5, -5), Transparency = 1,
		CanCollide = false, CanQuery = false, Tags = { "Shop" }, Attributes = { ShopId = "Quiosco" }, Parent = m,
	})
	StoryMarks.spot(m, "Parque_Tienda", kiosk * CFrame.new(3, 2.5, -6), mark)
	StoryMarks.spot(m, "Parque_Reunion", lot.facing(-12, Dp * 0.25, 2.9), mark)
	-- Arboleda perimetral diseñada (no al azar)
	for u = -L / 2 + 8, L / 2 - 8, 18 do
		Nature.tree(m, lot.point(u, 6, 0.3))
		Nature.tree(m, lot.point(u, Dp - 6, 0.3))
	end
	for v = 24, Dp - 24, 18 do
		Nature.tree(m, lot.point(-L / 2 + 6, v, 0.3))
		Nature.tree(m, lot.point(L / 2 - 6, v, 0.3))
	end
	-- Bancos y farolas junto a los caminos
	for _, v in { Dp * 0.25, Dp * 0.75 } do
		Props.bench(m, lot.facing(-6, v, 0.45) * CFrame.Angles(0, math.rad(90), 0))
		Props.bench(m, lot.facing(6, v, 0.45) * CFrame.Angles(0, math.rad(-90), 0))
		Props.lamp(m, lot.facing(-5, v + 8, 0.45) * CFrame.Angles(0, math.rad(-90), 0))
	end
	Nature.flowerBed(m, lot.facing(0, Dp / 2, 0.46), 10, 10)
	return m
end

---------------------------------------------------------------------
-- Campo: granja con cultivos, granero y silo
---------------------------------------------------------------------
function Civic.farm(parent: Instance, lot: Lot)
	local m = Builder.model("Granja", parent)
	local L, Dp = lot.Length, lot.Depth
	local crops = { rgb(120, 90, 60), rgb(96, 140, 60), rgb(200, 176, 90), rgb(110, 150, 70) }
	local rowW = 6
	local u = -L / 2 + 6
	local i = 0
	while u + rowW <= L / 2 - 6 do
		i += 1
		slab(m, lot, u, u + rowW - 1, 30, Dp - 6, 0.5, crops[(math.floor(i / 4) % #crops) + 1], Enum.Material.Ground, "Crop")
		u += rowW
	end
	-- Granero rojo y silo
	Building.build({
		Name = "Granero", Parent = m, CFrame = lot.facing(-L / 4, 14, 0),
		Width = 26, Depth = 20, Floors = 1, Style = "Casa", GroundFloor = "House",
		WallColor = rgb(160, 48, 40), Interior = false,
	})
	local silo = lot.point(-L / 4 + 20, 12, 0)
	Builder.part({ Name = "Silo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26, 9, 9), CFrame = CFrame.new(silo + Vector3.new(0, 13, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(206, 208, 212), Material = Enum.Material.Metal, Parent = m })
	Builder.part({ Name = "SiloTop", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), CFrame = CFrame.new(silo + Vector3.new(0, 26, 0)), Color = rgb(170, 60, 50), Parent = m })
	-- Valla de madera
	for _, v in { 2, Dp - 2 } do
		Builder.part({ Name = "Fence", Size = Vector3.new(L - 4, 0.4, 0.3), CFrame = lot.facing(0, v, 2.4), Color = Palette.Street.Wood, Material = Enum.Material.Wood, Parent = m })
		Builder.part({ Name = "Fence", Size = Vector3.new(L - 4, 0.4, 0.3), CFrame = lot.facing(0, v, 1.2), Color = Palette.Street.Wood, Material = Enum.Material.Wood, Parent = m })
	end
	for _, uu in { -L / 2 + 6, L / 2 - 6 } do
		Nature.tree(m, lot.point(uu, 10, 0), 1.2)
	end
	return m
end

---------------------------------------------------------------------
-- Playa con sombrillas, hamacas y paseo marítimo
---------------------------------------------------------------------
function Civic.beach(parent: Instance, lot: Lot)
	local m = Builder.model("Playa", parent)
	local L, Dp = lot.Length, lot.Depth
	slab(m, lot, -L / 2, L / 2, 0, 12, FT, rgb(186, 150, 110), Enum.Material.WoodPlanks, "Boardwalk")
	slab(m, lot, -L / 2, L / 2, 12, Dp + 30, 0.6, rgb(232, 214, 170), Enum.Material.Sand, "Sand")
	local colors = { rgb(230, 70, 60), rgb(40, 120, 210), rgb(250, 200, 50), rgb(250, 250, 250) }
	for u = -L / 2 + 12, L / 2 - 12, 22 do
		for v = 26, Dp - 6, 26 do
			local base = lot.point(u + math.random(-3, 3), v + math.random(-3, 3), 0.6)
			Builder.part({ Name = "UmbrellaPole", Size = Vector3.new(0.3, 8, 0.3), CFrame = CFrame.new(base + Vector3.new(0, 4, 0)), Color = rgb(240, 240, 240), Parent = m })
			Builder.decor({ Name = "Umbrella", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 9, 9), CFrame = CFrame.new(base + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = colors[math.random(1, #colors)], Material = Enum.Material.Fabric, Parent = m })
			Builder.part({ Name = "Lounger", Size = Vector3.new(2.4, 0.6, 6), CFrame = CFrame.new(base + Vector3.new(3, 0.6, 0)), Color = rgb(250, 250, 250), Parent = m })
		end
	end
	for u = -L / 2 + 6, L / 2 - 6, 24 do
		Nature.palm(m, lot.point(u, 8, FT))
	end
	-- Torre de socorrista
	local tower = lot.point(0, Dp - 20, 0.6)
	for _, dx in { -2, 2 } do
		for _, dz in { -2, 2 } do
			Builder.part({ Name = "Leg", Size = Vector3.new(0.4, 8, 0.4), CFrame = CFrame.new(tower + Vector3.new(dx, 4, dz)), Color = rgb(250, 250, 250), Parent = m })
		end
	end
	Builder.part({ Name = "Cabin", Size = Vector3.new(5, 4, 5), CFrame = CFrame.new(tower + Vector3.new(0, 10, 0)), Color = rgb(220, 60, 50), Parent = m })
	return m
end

---------------------------------------------------------------------
-- Cartel de bienvenida a la entrada de cada ciudad
---------------------------------------------------------------------
function Civic.welcome(parent: Instance, cf: CFrame, townName: string)
	local m = Builder.model("Bienvenida", parent)
	for _, x in { -7, 7 } do
		Builder.part({ Name = "Post", Size = Vector3.new(0.6, 9, 0.6), CFrame = cf * CFrame.new(x, 4.5, 0), Color = Palette.Street.Metal, Parent = m })
	end
	signBoard(m, cf * CFrame.new(0, 8, 0), "BIENVENIDO A\n" .. string.upper(townName), 16, rgb(30, 100, 60))
	return m
end

---------------------------------------------------------------------
-- Estadio de fútbol (necesita una manzana grande, 200 × 200)
---------------------------------------------------------------------
function Civic.stadium(parent: Instance, lot: Lot, name: string, teamColor: Color3)
	local m = Builder.model("Estadio", parent)
	local cv = lot.Depth / 2
	local center = lot.point(0, cv, 0)
	-- Explanada de acceso
	slab(m, lot, -lot.Length / 2 + 2, lot.Length / 2 - 2, 0, lot.Depth - 2, FT, rgb(196, 192, 184), Enum.Material.Pavement, "Esplanade")
	-- Terreno de juego (110 × 70) con líneas
	local pitch = lot.facing(0, cv, FT)
	Builder.part({ Name = "Pitch", Size = Vector3.new(110, 0.3, 70), CFrame = pitch * CFrame.new(0, 0.15, 0), Color = rgb(70, 146, 66), Material = Enum.Material.Grass, Parent = m })
	for i = -5, 5 do
		if i % 2 == 0 then
			Builder.decor({ Name = "Stripe", Size = Vector3.new(10, 0.05, 70), CFrame = pitch * CFrame.new(i * 10, 0.31, 0), Color = rgb(80, 160, 74), Parent = m })
		end
	end
	local white = rgb(245, 245, 245)
	for _, l in { { 110, 0.5, 0, -34.6 }, { 110, 0.5, 0, 34.6 }, { 0.5, 70, -54.6, 0 }, { 0.5, 70, 54.6, 0 }, { 0.5, 70, 0, 0 },
		{ 0.5, 40, -38, 0 }, { 0.5, 40, 38, 0 }, { 16.6, 0.5, -46.4, -20 }, { 16.6, 0.5, -46.4, 20 }, { 16.6, 0.5, 46.4, -20 }, { 16.6, 0.5, 46.4, 20 } } do
		Builder.decor({ Name = "Line", Size = Vector3.new(l[1], 0.06, l[2]), CFrame = pitch * CFrame.new(l[3], 0.33, l[4]), Color = white, Parent = m })
	end
	Builder.decor({ Name = "CenterCircle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.06, 18, 18), CFrame = pitch * CFrame.new(0, 0.32, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = white, Parent = m })
	Builder.decor({ Name = "CenterCircleIn", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.07, 17, 17), CFrame = pitch * CFrame.new(0, 0.33, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(70, 146, 66), Parent = m })
	for _, side in { -1, 1 } do
		local goal = pitch * CFrame.new(side * 55, 0, 0)
		Builder.part({ Name = "Crossbar", Size = Vector3.new(0.4, 0.4, 14), CFrame = goal * CFrame.new(0, 7.5, 0), Color = white, Parent = m })
		for _, z in { -7, 7 } do
			Builder.part({ Name = "Post", Size = Vector3.new(0.4, 7.5, 0.4), CFrame = goal * CFrame.new(0, 3.75, z), Color = white, Parent = m })
		end
		Builder.decor({ Name = "Net", Size = Vector3.new(3, 7.5, 14), CFrame = goal * CFrame.new(side * 1.6, 3.75, 0), Color = white, Transparency = 0.7, Parent = m })
	end
	-- Gradas: cuña de asientos + muro trasero, mirando al campo
	local stands = {
		{ Offset = Vector3.new(0, 0, 0), Along = 0, Across = 50, Length = 124, Depth = 24, Height = 18 },
		{ Along = 0, Across = -50, Length = 124, Depth = 20, Height = 14 },
		{ Along = 70, Across = 0, Length = 84, Depth = 18, Height = 14 },
		{ Along = -70, Across = 0, Length = 84, Depth = 18, Height = 14 },
	}
	for i, st in stands do
		local pos = lot.point(st.Along, cv + st.Across, FT)
		local toCenter = Vector3.new(center.X, pos.Y, center.Z) - pos
		local cf = Builder.facing(pos, toCenter)
		Builder.part({ ClassName = "WedgePart", Name = "Stand", Size = Vector3.new(st.Length, st.Height, st.Depth), CFrame = cf * CFrame.new(0, st.Height / 2, 0), Color = if i % 2 == 1 then teamColor else rgb(236, 236, 236), Material = Enum.Material.SmoothPlastic, Parent = m })
		Builder.part({ Name = "StandBack", Size = Vector3.new(st.Length, st.Height + 4, 1.5), CFrame = cf * CFrame.new(0, (st.Height + 4) / 2, st.Depth / 2 + 0.75), Color = rgb(210, 212, 216), Material = Enum.Material.Concrete, Parent = m })
		if i == 1 then
			-- Cubierta de la tribuna principal
			Builder.part({ Name = "Roof", Size = Vector3.new(st.Length, 1, st.Depth + 6), CFrame = cf * CFrame.new(0, st.Height + 8, -2), Color = rgb(236, 238, 242), Material = Enum.Material.Metal, Parent = m })
		end
		if i == 3 then
			local board = Builder.decor({ Name = "Scoreboard", Size = Vector3.new(26, 8, 0.6), CFrame = cf * CFrame.new(0, st.Height + 6, st.Depth / 2), Color = rgb(20, 20, 24), Parent = m })
			Builder.sign(board, "VALMAR  2 - 1  VISITANTE", Enum.NormalId.Front, rgb(255, 210, 60))
		end
	end
	-- Torres de focos en las esquinas
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local base = lot.point(sx * 72, cv + sz * 58, FT)
			local toCenter = Vector3.new(center.X, base.Y, center.Z) - base
			local cf = Builder.facing(base, toCenter)
			Builder.part({ Name = "LightPole", Size = Vector3.new(1.2, 44, 1.2), CFrame = cf * CFrame.new(0, 22, 0), Color = rgb(190, 192, 196), Material = Enum.Material.Metal, Parent = m })
			Builder.decor({ Name = "Floodlights", Size = Vector3.new(8, 4, 0.6), CFrame = cf * CFrame.new(0, 44, -0.8) * CFrame.Angles(math.rad(-20), 0, 0), Color = rgb(255, 252, 235), Material = Enum.Material.Neon, Parent = m })
		end
	end
	-- Rótulo de entrada hacia la calle
	signBoard(m, lot.facing(0, 6, FT + 10), "ESTADIO " .. string.upper(name), 34, teamColor)
	for _, du in { -18, 18 } do
		Builder.part({ Name = "SignPost", Size = Vector3.new(0.8, 10, 0.8), CFrame = lot.facing(du, 6, FT + 5), Color = Palette.Street.Metal, Parent = m })
	end
	return m
end

---------------------------------------------------------------------
-- Facultad universitaria / biblioteca con pórtico de columnas
---------------------------------------------------------------------
local FACULTY_IDS = { { "MEDICINA", "Medicina" }, { "INGENIER", "Ingenieria" }, { "DERECHO", "Derecho" }, { "ECONOM", "Economia" } }

function Civic.faculty(parent: Instance, lot: Lot, title: string)
	local m = Builder.model("Facultad", parent)
	-- La historia identifica cada facultad por su atributo Faculty; la biblioteca lleva la etiqueta Library
	for _, pair in FACULTY_IDS do
		if string.find(title, pair[1], 1, true) then
			m:SetAttribute("Faculty", pair[2])
		end
	end
	if string.find(title, "BIBLIOTECA", 1, true) then
		m:AddTag("Library")
	end
	local W = math.min(lot.Length - 30, 120)
	local D = math.min(lot.Depth - 30, 40)
	local setback = 18
	slab(m, lot, -lot.Length / 2 + 2, lot.Length / 2 - 2, 0, setback, FT, rgb(222, 214, 196), Enum.Material.Limestone, "Plaza")
	Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(0, setback + D / 2, 0),
		Width = W, Depth = D, Floors = 4, Style = "Clasico", GroundFloor = "Lobby",
		WallColor = rgb(232, 222, 200), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true, Back = true },
		Sign = title, SignColor = rgb(110, 30, 40),
	})
	-- Pórtico: 6 columnas, arquitrabe y frontón
	local stone = rgb(240, 234, 222)
	for i = 0, 5 do
		local u = -15 + i * 6
		Builder.part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, 2, 2), CFrame = lot.facing(u, setback - 5, FT + 8) * CFrame.Angles(0, 0, math.rad(90)), Color = stone, Material = Enum.Material.Marble, Parent = m })
	end
	Builder.part({ Name = "Architrave", Size = Vector3.new(36, 2, 8), CFrame = lot.facing(0, setback - 4, FT + 17), Color = stone, Material = Enum.Material.Limestone, Parent = m })
	Builder.part({ ClassName = "WedgePart", Name = "Pediment", Size = Vector3.new(8, 6, 18), CFrame = lot.along(-9, setback - 4, FT + 21) * CFrame.Angles(0, math.pi, 0), Color = stone, Material = Enum.Material.Limestone, Parent = m })
	Builder.part({ ClassName = "WedgePart", Name = "Pediment", Size = Vector3.new(8, 6, 18), CFrame = lot.along(9, setback - 4, FT + 21), Color = stone, Material = Enum.Material.Limestone, Parent = m })
	-- Jardín con árboles a los lados
	for _, u in { -lot.Length / 2 + 10, lot.Length / 2 - 10 } do
		Nature.tree(m, lot.point(u, 8, FT))
	end
	-- Patio universitario detrás (césped, paseo y alineaciones de árboles)
	local back = setback + D + 8
	if lot.Depth - back > 40 then
		slab(m, lot, -lot.Length / 2 + 4, lot.Length / 2 - 4, back, lot.Depth - 4, 0.3, Palette.Ground.Lawn, Enum.Material.Grass, "Quad")
		slab(m, lot, -3, 3, back, lot.Depth - 4, 0.45, rgb(222, 212, 190), Enum.Material.Pavement, "Walk")
		for v = back + 10, lot.Depth - 12, 20 do
			for _, u in { -lot.Length / 2 + 14, -20, 20, lot.Length / 2 - 14 } do
				Nature.tree(m, lot.point(u, v, 0.3))
			end
		end
		for v = back + 20, lot.Depth - 20, 40 do
			Props.bench(m, lot.facing(-6, v, 0.45) * CFrame.Angles(0, math.rad(90), 0))
		end
	end
	return m
end

---------------------------------------------------------------------
-- Rascacielos de oficinas con el nombre de la empresa en lo alto
---------------------------------------------------------------------
local COMPANIES = { "TECNOVAL", "BANCO VALMAR", "SEGUROS ALBA", "ENERGÍA COSTA", "LOGÍSTICA RUTA", "GRUPO ALTAMAR", "SOLENA", "MEDIA SUR", "CONSTRUCTORA NORTE", "ÓPTIMA SOFT" }

function Civic.officeTower(parent: Instance, lot: Lot, u: number, width: number, depth: number, setback: number)
	local company = COMPANIES[math.random(1, #COMPANIES)]
	local model, at, info = Building.build({
		Name = "Torre", Parent = parent, CFrame = lot.facing(u, setback + depth / 2, 0),
		Width = width, Depth = depth, Floors = math.random(10, 20), GroundHeight = 16, Style = "Oficina", GroundFloor = "Lobby",
		WindowFaces = { Front = true, Left = true, Right = true, Back = true },
		Sign = company, SignColor = rgb(24, 30, 44),
	})
	-- Letrero luminoso en la azotea
	local board = Builder.decor({ Name = "RoofSign", Size = Vector3.new(width * 0.8, 5, 0.6), CFrame = at(0, info.Top - FT + 5.5, -depth / 2 + 2), Color = rgb(20, 24, 34), Parent = model })
	Builder.sign(board, company, Enum.NormalId.Front, rgb(120, 220, 255))
	return model
end

-- Manzana de torres en un lado (1 o 2 torres según el largo) con plaza delante
function Civic.towers(parent: Instance, lot: Lot)
	local m = Builder.model("Torres", parent)
	local setback = 14
	slab(m, lot, -lot.Length / 2 + 2, lot.Length / 2 - 2, 0, setback, FT, rgb(214, 214, 210), Enum.Material.Pavement, "Plaza")
	local depth = math.min(lot.Depth - setback - 8, 40)
	if lot.Length >= 150 then
		for _, u in { -lot.Length / 4, lot.Length / 4 } do
			Civic.officeTower(m, lot, u, 44, depth, setback)
		end
	else
		Civic.officeTower(m, lot, 0, math.min(lot.Length - 16, 50), depth, setback)
	end
	for u = -lot.Length / 2 + 10, lot.Length / 2 - 10, 30 do
		Nature.flowerBed(m, lot.facing(u, 5, FT), 6, 3)
	end
	return m
end

-- Distrito financiero: torres a ambos lados de una plaza central con fuente
function Civic.business(parent: Instance, lotFront: Lot, lotBack: Lot)
	local m = Builder.model("PlazaFinanciera", parent)
	local depth = 40
	for _, lot in { lotFront, lotBack } do
		for _, u in { -lot.Length / 4, lot.Length / 4 } do
			Civic.officeTower(m, lot, u, 46, depth, 10)
		end
	end
	-- Plaza central entre las torres
	local cv = lotFront.Depth / 2
	slab(m, lotFront, -lotFront.Length / 2 + 4, lotFront.Length / 2 - 4, 10 + depth + 2, lotFront.Depth - 10 - depth - 2, FT, rgb(218, 212, 200), Enum.Material.Pavement, "Plaza")
	local f = lotFront.point(0, cv, FT)
	Builder.part({ Name = "Fountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 24, 24), CFrame = CFrame.new(f + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(200, 204, 210), Material = Enum.Material.Granite, Parent = m })
	Builder.decor({ Name = "Water", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 22, 22), CFrame = CFrame.new(f + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(70, 150, 210), Material = Enum.Material.Glass, Transparency = 0.25, Parent = m })
	for _, du in { -60, -30, 30, 60 } do
		Nature.tree(m, lotFront.point(du, cv, FT))
	end
	return m
end

---------------------------------------------------------------------
-- Calle de ocio: cine, recreativos, gimnasio y autoescuela
---------------------------------------------------------------------

local function neonStrip(parent: Instance, cf: CFrame, width: number, color: Color3)
	Builder.decor({ Name = "Neon", Size = Vector3.new(width, 0.35, 0.3), CFrame = cf, Color = color, Material = Enum.Material.Neon, Parent = parent })
end

function Civic.cinema(parent: Instance, lot: Lot, u: number, townName: string)
	local W, D = 52, 44
	local model, at = Building.build({
		Name = "Cine", Parent = parent, CFrame = lot.facing(u + W / 2, 8 + D / 2, 0),
		Width = W, Depth = D, Floors = 1, GroundHeight = 22, Style = "Moderno", GroundFloor = "Shop",
		WallColor = rgb(52, 40, 62), Interior = false, Balconies = false, WindowFaces = { Front = true }, ShopId = "Cine",
	})
	-- Marquesina luminosa con carteles de películas
	local marquee = Builder.decor({ Name = "Marquee", Size = Vector3.new(30, 6, 0.8), CFrame = at(0, 17, -D / 2 - 0.5), Color = rgb(18, 16, 24), Parent = model })
	Builder.sign(marquee, "CINE " .. string.upper(townName), Enum.NormalId.Front, rgb(255, 214, 90))
	neonStrip(model, at(0, 20.2, -D / 2 - 1), 31, rgb(255, 200, 60))
	neonStrip(model, at(0, 13.8, -D / 2 - 1), 31, rgb(255, 200, 60))
	for i, color in { rgb(200, 50, 60), rgb(40, 110, 200) } do
		Builder.decor({ Name = "Poster", Size = Vector3.new(5, 7, 0.2), CFrame = at(if i == 1 then -16 else 16, 6, -D / 2 - 0.3), Color = color, Parent = model })
	end
	return W
end

-- Recreativos con interior jugable (ArcadeService):
--   ArcadeMachine (+GameId = "Bolas" | "Canasta"), PrizeCounter, ArcadeScoreboard
local function arcadeLabel(part: BasePart, text: string, color: Color3)
	Builder.sign(part, text, Enum.NormalId.Front, color)
end

function Civic.arcade(parent: Instance, lot: Lot, u: number)
	local W, D = 30, 30
	local model, at = Building.build({
		Name = "Recreativos", Parent = parent, CFrame = lot.facing(u + W / 2, 8 + D / 2, 0),
		Width = W, Depth = D, Floors = 1, GroundHeight = 16, Style = "Moderno", GroundFloor = "Shop",
		WallColor = rgb(36, 30, 56), Balconies = false, WindowFaces = { Front = true },
		Sign = "RECREATIVOS", SignColor = rgb(200, 40, 160), ShopId = "Recreativos",
		FloorMaterial = Enum.Material.Carpet, FloorColor = rgb(40, 34, 70), LightColor = rgb(230, 200, 255),
	})
	for i, color in { rgb(255, 60, 200), rgb(60, 220, 255), rgb(255, 230, 60) } do
		neonStrip(model, at(0, 15 - i * 0.9, -D / 2 - 0.4), W - 2, color)
	end
	local F = FT -- suelo interior

	-- Dos pistas de lanzabolas al fondo a la izquierda
	for i, x in { -10, -5 } do
		local color = if i == 1 then rgb(255, 60, 200) else rgb(60, 220, 255)
		Builder.part({ Name = "Lane", Size = Vector3.new(3.4, 0.4, 11), CFrame = at(x, F + 1.2, 4) * CFrame.Angles(math.rad(6), 0, 0), Color = rgb(150, 108, 72), Material = Enum.Material.WoodPlanks, Parent = model })
		for _, side in { -1, 1 } do
			Builder.part({ Name = "Rail", Size = Vector3.new(0.3, 2.4, 13), CFrame = at(x + side * 1.85, F + 1.6, 4), Color = color, Parent = model })
		end
		local target = Builder.part({ Name = "Target", Size = Vector3.new(3.4, 4.2, 0.4), CFrame = at(x, F + 3.4, 10.4), Color = rgb(20, 18, 30), Parent = model })
		arcadeLabel(target, "100\n50 · 30\n10", color)
		neonStrip(model, at(x, F + 5.7, 10.2), 3.6, color)
		local console = Builder.part({
			Name = "Console", Size = Vector3.new(3.4, 3, 1.4), CFrame = at(x, F + 1.5, -2.6), Color = rgb(30, 26, 48),
			Tags = { "ArcadeMachine" }, Attributes = { GameId = "Bolas" }, Parent = model,
		})
		local screen = Builder.decor({ Name = "Screen", Size = Vector3.new(3, 1, 0.1), CFrame = at(x, F + 3.4, -2.2), Color = rgb(20, 18, 30), Parent = model })
		arcadeLabel(screen, "LANZABOLAS", color)
		for k = 0, 2 do
			Builder.decor({ Name = "Ball", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = at(x - 0.9 + k * 0.9, F + 3.25, -2.6), Color = rgb(250, 240, 220), Parent = model })
		end
		arcadeLabel(console, "5 $", rgb(255, 230, 60))
	end

	-- Máquina de canastas
	local hx = 3.5
	Builder.part({ Name = "CageFloor", Size = Vector3.new(5, 0.4, 10), CFrame = at(hx, F + 0.2, 5), Color = rgb(60, 50, 90), Parent = model })
	for _, side in { -1, 1 } do
		Builder.part({ Name = "CageNet", Size = Vector3.new(0.2, 8, 10), CFrame = at(hx + side * 2.5, F + 4, 5), Color = rgb(200, 200, 220), Material = Enum.Material.Glass, Transparency = 0.6, Parent = model })
	end
	local backboard = Builder.part({ Name = "Backboard", Size = Vector3.new(4.4, 3, 0.3), CFrame = at(hx, F + 7.4, 9.9), Color = rgb(240, 240, 245), Parent = model })
	arcadeLabel(backboard, "CANASTAS", rgb(230, 90, 30))
	Builder.part({ Name = "Hoop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2.2, 2.2), CFrame = at(hx, F + 6.2, 8.9) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(240, 110, 30), Material = Enum.Material.Metal, Transparency = 0, Parent = model })
	Builder.decor({ Name = "Net", Size = Vector3.new(1.6, 1.4, 1.6), CFrame = at(hx, F + 5.4, 8.9), Color = rgb(250, 250, 250), Material = Enum.Material.Fabric, Transparency = 0.4, Parent = model })
	for k = 0, 3 do
		Builder.decor({ Name = "Basketball", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = at(hx - 1.5 + k, F + 1, 1.6), Color = rgb(230, 110, 40), Parent = model })
	end
	local hoopConsole = Builder.part({
		Name = "Console", Size = Vector3.new(4.4, 3, 1.4), CFrame = at(hx, F + 1.5, -2.6), Color = rgb(30, 26, 48),
		Tags = { "ArcadeMachine" }, Attributes = { GameId = "Canasta" }, Parent = model,
	})
	arcadeLabel(hoopConsole, "5 $", rgb(255, 230, 60))

	-- Mostrador de premios a la derecha
	local counterPart = Builder.part({
		Name = "PrizeCounter", Size = Vector3.new(3, 3.6, 12), CFrame = at(10.5, F + 1.8, 2), Color = rgb(250, 200, 40),
		Tags = { "PrizeCounter" }, Parent = model,
	})
	Builder.sign(counterPart, "PREMIOS", Enum.NormalId.Left, rgb(120, 30, 90))
	for k = 0, 4 do
		for level = 0, 2 do
			Builder.decor({
				Name = "Prize", Shape = if (k + level) % 2 == 0 then Enum.PartType.Ball else Enum.PartType.Block,
				Size = Vector3.new(1.2, 1.2, 1.2), CFrame = at(13.6, F + 2 + level * 2.4, -3 + k * 2.6),
				Color = Color3.fromHSV(((k * 3 + level) % 10) / 10, 0.6, 0.95), Parent = model,
			})
		end
	end
	for level = 0, 2 do
		Builder.decor({ Name = "PrizeShelf", Size = Vector3.new(1.6, 0.2, 13), CFrame = at(13.6, F + 1.3 + level * 2.4, 2), Color = rgb(200, 200, 210), Parent = model })
	end

	-- Marcador de récords (ArcadeService escribe los nombres)
	Builder.part({
		Name = "Scoreboard", Size = Vector3.new(12, 4.6, 0.3), CFrame = at(-4.5, F + 10, 14.2), Color = rgb(12, 10, 20),
		Tags = { "ArcadeScoreboard" }, Parent = model,
	})

	-- Máquinas decorativas en la pared izquierda
	for k = 0, 2 do
		local cf = at(-13.2, F, -11 + k * 3.4) * CFrame.Angles(0, math.rad(-90), 0)
		Builder.part({ Name = "Cabinet", Size = Vector3.new(2.6, 6, 2.2), CFrame = cf * CFrame.new(0, 3, 0), Color = rgb(30, 26, 48), Parent = model })
		Builder.decor({ Name = "CabinetScreen", Size = Vector3.new(2, 1.6, 0.1), CFrame = cf * CFrame.new(0, 4.2, -1.12), Color = Color3.fromHSV(k / 3, 0.7, 1), Material = Enum.Material.Neon, Parent = model })
	end
	return W
end

function Civic.gym(parent: Instance, lot: Lot, u: number)
	local W, D = 40, 36
	local model, at = Building.build({
		Name = "Gimnasio", Parent = parent, CFrame = lot.facing(u + W / 2, 8 + D / 2, 0),
		Width = W, Depth = D, Floors = 2, Style = "Moderno", GroundFloor = "Shop", Balconies = false,
		WallColor = rgb(230, 232, 236), WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "GIMNASIO", SignColor = rgb(230, 110, 30), ShopId = "Gimnasio", FloorMaterial = Enum.Material.Rubber, FloorColor = rgb(50, 52, 58),
	})
	-- Máquinas visibles desde el escaparate
	for i = 0, 3 do
		local cf = at(-12 + i * 8, 0, -6)
		Builder.part({ Name = "Treadmill", Size = Vector3.new(2.6, 1, 6), CFrame = cf * CFrame.new(0, 0.5, 0), Color = rgb(30, 30, 34), Parent = model })
		Builder.decor({ Name = "Console", Size = Vector3.new(2.6, 3.6, 0.4), CFrame = cf * CFrame.new(0, 2.4, -2.8), Color = rgb(70, 72, 80), Parent = model })
	end
	for i = 0, 2 do
		Builder.part({ Name = "Bench", Size = Vector3.new(1.4, 1.6, 5), CFrame = at(-10 + i * 10, 0.8, 8), Color = rgb(200, 60, 40), Parent = model })
	end
	return W
end

-- Autoescuela: aquí se saca el carnet de moto (A) y de coche (B) (DrivingSchoolService)
function Civic.drivingSchool(parent: Instance, lot: Lot, u: number, townName: string)
	local W, D = 30, 26
	local model, at = Building.build({
		Name = "Autoescuela", Parent = parent, CFrame = lot.facing(u + W / 2, 8 + D / 2, 0),
		Width = W, Depth = D, Floors = 2, Style = "Clasico", GroundFloor = "Shop", Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "AUTOESCUELA", SignColor = rgb(40, 90, 150), Awning = rgb(40, 90, 150), ShopId = "Autoescuela",
		FloorMaterial = Enum.Material.CeramicTiles, FloorColor = rgb(226, 226, 222),
	})
	-- Aula de teoría: pizarra con señales y pupitres
	local board = Builder.part({ Name = "Board", Size = Vector3.new(10, 4, 0.3), CFrame = at(0, FT + 5, D / 2 - 1.4), Color = rgb(245, 245, 245), Parent = model })
	Builder.sign(board, "STOP · CEDA EL PASO · 50", Enum.NormalId.Front, rgb(200, 30, 30))
	for _, x in { -7, 0, 7 } do
		for _, z in { 0, 5 } do
			Builder.part({ Name = "Desk", Size = Vector3.new(4, 0.3, 2), CFrame = at(x, FT + 2.6, z), Color = rgb(190, 150, 100), Material = Enum.Material.Wood, Parent = model })
			Builder.part({ Name = "Chair", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = at(x, FT + 0.8, z - 1.8), Color = rgb(40, 90, 150), Parent = model })
		end
	end
	-- Punto para apuntarse (en la acera, delante de la puerta)
	local desk = Builder.part({
		Name = "Signup", Size = Vector3.new(4, 3.4, 0.4), CFrame = at(-9, FT + 3.2, -D / 2 - 2.5), Color = rgb(40, 90, 150),
		Tags = { "DrivingSchool" }, Attributes = { Town = townName }, Parent = model,
	})
	Builder.sign(desk, "CARNET\nMOTO · COCHE", Enum.NormalId.Front)
	Builder.sign(desk, "CARNET\nMOTO · COCHE", Enum.NormalId.Back)
	Builder.part({ Name = "SignupPost", Size = Vector3.new(0.3, FT + 1.5, 0.3), CFrame = at(-9, (FT + 1.5) / 2, -D / 2 - 2.5), Color = rgb(60, 64, 70), Parent = model })
	-- Coche de prácticas con la "L"
	local carCf = lot.along(u + W + 8, 4, FT)
	local car = Props.car(model, carCf, rgb(245, 245, 245))
	if car and car:IsA("Model") and car.Name == "ParkedCar" then
		local plate = Builder.decor({ Name = "LPlate", Size = Vector3.new(1.6, 1.6, 0.1), CFrame = carCf * CFrame.new(0, 5.8, 0.6), Color = rgb(40, 90, 200), Parent = car })
		Builder.sign(plate, "L", Enum.NormalId.Front)
		Builder.sign(plate, "L", Enum.NormalId.Back)
	end
	return W
end

function Civic.leisure(parent: Instance, lot: Lot, townName: string)
	local m = Builder.model("Ocio", parent)
	slab(m, lot, -lot.Length / 2 + 2, lot.Length / 2 - 2, 0, 8, FT, rgb(206, 200, 190), Enum.Material.Pavement, "Frontage")
	local builders = {
		function(u)
			return Civic.cinema(m, lot, u, townName)
		end,
		function(u)
			return Civic.arcade(m, lot, u)
		end,
		function(u)
			return Civic.gym(m, lot, u)
		end,
		function(u)
			return Civic.drivingSchool(m, lot, u, townName)
		end,
	}
	local widths = { 52, 30, 40, 30 }
	local u = -lot.Length / 2 + 4
	for i, build in builders do
		if u + widths[i] <= lot.Length / 2 - 4 then
			u += build(u) + 4
		end
	end
	if lot.Depth - 56 > 30 then
		Civic.parkingLot(m, lot, -lot.Length / 2 + 6, lot.Length / 2 - 6, 56, lot.Depth - 4, 0.5)
	end
	return m
end

return Civic
