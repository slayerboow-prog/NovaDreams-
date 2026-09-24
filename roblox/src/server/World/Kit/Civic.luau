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
	Building.build({
		Name = "Edificio", Parent = m, CFrame = lot.facing(0, setback + D / 2, 0),
		Width = W, Depth = D, Floors = 2, Style = "Clasico", GroundFloor = "Lobby",
		WallColor = rgb(196, 112, 84), Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true, Back = true },
		Sign = "COLEGIO " .. string.upper(townName), SignColor = rgb(30, 90, 160),
	})
	-- Mástil con bandera
	Builder.part({ Name = "Flagpole", Size = Vector3.new(0.4, 20, 0.4), CFrame = lot.facing(-W / 2 + 6, 5, 10), Color = rgb(220, 220, 224), Material = Enum.Material.Metal, Parent = m })
	Builder.decor({ Name = "Flag", Size = Vector3.new(5, 3, 0.1), CFrame = lot.facing(-W / 2 + 8.6, 5, 18.5), Color = rgb(40, 110, 200), Material = Enum.Material.Fabric, Parent = m })
	-- Patio: pista deportiva y parque infantil
	local courtV = setback + D + 24
	if lot.Depth > courtV + 20 then
		local court = lot.facing(-12, courtV, 0)
		Builder.part({ Name = "Court", Size = Vector3.new(60, 0.4, 32), CFrame = court * CFrame.new(0, 0.2, 0), Color = rgb(56, 128, 96), Material = Enum.Material.Concrete, Parent = m })
		for _, line in { { 60, 0.5, 0, -15.6 }, { 60, 0.5, 0, 15.6 }, { 0.5, 32, -29.6, 0 }, { 0.5, 32, 29.6, 0 }, { 0.5, 32, 0, 0 } } do
			Builder.decor({ Name = "CourtLine", Size = Vector3.new(line[1], 0.05, line[2]), CFrame = court * CFrame.new(line[3], 0.42, line[4]), Color = rgb(240, 240, 240), Parent = m })
		end
		hoop(m, court * CFrame.new(-31, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))
		hoop(m, court * CFrame.new(31, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
		Civic.playground(m, lot.facing(math.min(W / 2 - 14, 34), courtV, 0))
	end
	-- Campo de fútbol y gimnasio al fondo del recinto
	local fieldV = courtV + 40 + 30
	if lot.Depth > fieldV + 32 then
		local field = lot.facing(-12, fieldV, 0)
		Builder.part({ Name = "Pitch", Size = Vector3.new(80, 0.35, 50), CFrame = field * CFrame.new(0, 0.18, 0), Color = rgb(74, 148, 70), Material = Enum.Material.Grass, Parent = m })
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
		Building.build({
			Name = "Gimnasio", Parent = m, CFrame = lot.facing(math.min(W / 2 - 12, 48), fieldV, 0),
			Width = 24, Depth = 34, Floors = 1, GroundHeight = 16, Style = "Moderno", GroundFloor = "Closed",
			WallColor = rgb(226, 214, 196), Interior = false, WindowFaces = { Front = true, Left = true, Right = true },
		})
	end

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
		Sign = "CENTRO COMERCIAL " .. string.upper(townName), SignColor = rgb(120, 40, 140),
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
		WallColor = rgb(240, 240, 238), WindowFaces = { Front = true }, Sign = "24H", SignColor = rgb(30, 150, 80),
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
function Civic.park(parent: Instance, lot: Lot)
	local m = Builder.model("Parque", parent)
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
		Civic.playground(m, lot.facing(-L / 4, Dp * 0.75, 0.3))
	else
		Civic.playground(m, lot.facing(-L / 4, Dp / 2 + 16, 0.3))
	end
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

return Civic
