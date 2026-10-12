-- Home: casa familiar con interior completo, donde nacen los jugadores (tutorial de bebé).
--
-- Lo que usa la historia (LifeStory), dentro de cada Model "CasaFamiliar" (tag FamilyHome, atributo HomeId):
--   Room        (atributo Room = "Salon" | "Cocina" | "Dormitorio") -> volumen invisible de cada habitación
--   LookOutside -> punto junto al ventanal del salón, mirando a la ciudad (LookVector hacia fuera)
--   BabySpawn   -> aparición del bebé, junto a la cuna
--   FamilySpot  (atributo Npc = "Familia_Abu" | "Familia_Padre") -> dónde se colocan los NPC de la familia
-- Para la misión "El primer día" (StoryMarks, todas con HomeId):
--   StoryProp PropId = "Cama" | "Armario" | "Espejo" | "Mochila" | "Desayuno"
--   StorySpot SpotId = "Despertar" (junto a la cama) | "SalirCasa" (delante de la puerta)
-- (La casa de Cosme, el vecino inventor, está en la manzana de al lado: World/CosmeHouse)
--
-- Distribución (vista desde arriba, la puerta al sur/frente). Medidas pensadas para que quepan 3-6
-- personajes y la cámara de las escenas (docs/auditoria-escala): habitaciones de ~21 × 21 studs, techo
-- de 13, pasillo de 8 y puertas de 7 (dos personas de lado).
--   ┌────────────────────────────────────────┐  fondo: ventanal con vista
--   │  tele ↔ sofá      SALÓN        comedor │
--   ├───────puerta─┐ pasillo ┌─puerta────────┤
--   │  DORMITORIO  │   ↑↑↑   │    COCINA     │
--   └──────────────┴─puerta──┴───────────────┘

local Builder = require(script.Parent.Parent.Builder)
local Building = require(script.Parent.Building)
local Nature = require(script.Parent.Nature)
local StoryMarks = require(script.Parent.StoryMarks)

local Home = {}

local rgb = Color3.fromRGB
local W, D = 52, 44 -- tamaño exterior de la casa (antes 36 × 30: no cabían las escenas)
local G = 13 -- altura interior (antes 11)
local X, Z = W / 2 - 1, D / 2 - 1 -- caras interiores de las paredes (25 y 21)
local HALL = 4 -- medio ancho del pasillo central
local DOOR_H = 9 -- altura de las puertas (y de los dinteles)
local SLOT = 62 -- largo de calle por casa (Home.familyRow)
Home.Size = Vector3.new(W, G, D)
Home.Slot = SLOT
local WALL = rgb(246, 242, 234)
local WOOD = rgb(150, 108, 72)
local CHAIR = rgb(120, 84, 56)

local function tagged(props: { [string]: any }): BasePart
	props.Transparency = 1
	props.CanCollide = false
	props.CanQuery = false
	props.CastShadow = false
	return Builder.part(props)
end

-- Tabique interior (x0..x1 o z0..z1) con hueco de puerta opcional
local function partition(model: Model, at: (number, number, number) -> CFrame, axis: string, fixed: number, from: number, to: number, door: { number }?)
	local segments = if door then { { from, door[1] }, { door[2], to } } else { { from, to } }
	for _, seg in segments do
		local a, b = seg[1], seg[2]
		if b - a > 0.05 then
			local mid = (a + b) / 2
			Builder.part({
				Name = "Partition",
				Size = if axis == "X" then Vector3.new(b - a, G, 0.6) else Vector3.new(0.6, G, b - a),
				CFrame = if axis == "X" then at(mid, G / 2, fixed) else at(fixed, G / 2, mid),
				Color = WALL,
				Material = Enum.Material.Plaster,
				Parent = model,
			})
		end
	end
	if door then
		local mid = (door[1] + door[2]) / 2
		local width = door[2] - door[1]
		Builder.part({
			Name = "Lintel",
			Size = if axis == "X" then Vector3.new(width, G - DOOR_H, 0.6) else Vector3.new(0.6, G - DOOR_H, width),
			CFrame = if axis == "X" then at(mid, DOOR_H + (G - DOOR_H) / 2, fixed) else at(fixed, DOOR_H + (G - DOOR_H) / 2, mid),
			Color = WALL,
			Material = Enum.Material.Plaster,
			Parent = model,
		})
	end
end

local function box(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, decor: boolean?)
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = model }
	return if decor then Builder.decor(props) else Builder.part(props)
end

-- Silla sencilla (asiento sólido y respaldo de adorno) en (x, z), mirando hacia (dx, dz)
local function chair(model: Model, at: (number, number, number) -> CFrame, x: number, z: number, dx: number, dz: number, color: Color3)
	local cf = at(x, 0, z) * CFrame.Angles(0, math.atan2(-dx, -dz), 0)
	box(model, "Chair", Vector3.new(1.8, 1.8, 1.8), cf * CFrame.new(0, 0.9, 0), color, Enum.Material.Wood)
	box(model, "ChairBack", Vector3.new(1.8, 2, 0.3), cf * CFrame.new(0, 2.8, 0.75), color, Enum.Material.Wood, true)
end

-- Estantería de pared con libros (cf en el suelo, pegada a la pared, con los libros hacia -Z)
local function bookshelf(model: Model, cf: CFrame, length: number)
	box(model, "Bookshelf", Vector3.new(length, 7, 1.4), cf * CFrame.new(0, 3.5, 0), WOOD, Enum.Material.Wood)
	for level = 0, 2 do
		for k = 0, math.floor(length / 1.6) - 1 do
			local h = 1.2 + ((k * 7 + level * 3) % 5) * 0.12
			local color = Color3.fromHSV(((k * 37 + level * 11) % 100) / 100, 0.5, 0.7)
			box(model, "Books", Vector3.new(1.2, h, 1), cf * CFrame.new(-length / 2 + 0.9 + k * 1.6, 1.4 + level * 2.1 + h / 2, -0.35), color, nil, true)
		end
	end
end

function Home.familyHouse(parent: Instance, cf: CFrame, homeId: string): Model
	local model, at = Building.build({
		Name = "CasaFamiliar",
		Parent = parent,
		CFrame = cf,
		Width = W,
		Depth = D,
		Floors = 1,
		GroundHeight = G,
		Style = "Casa",
		GroundFloor = "House",
		DoorWidth = 7,
		DoorHeight = DOOR_H,
		WindowFaces = { Front = true, Back = true, Left = true, Right = true },
		FloorColor = rgb(186, 146, 104),
		LightColor = rgb(255, 226, 186),
	})
	-- at() de Building ya mide desde el suelo interior: los muebles con y = 0 quedan apoyados en él
	local ground = at
	model:AddTag("FamilyHome")
	model:SetAttribute("HomeId", homeId)

	-- Tabiques: dormitorio (izquierda) y cocina (derecha) delante; salón al fondo. Puertas de 7 studs.
	partition(model, ground, "Z", -HALL, -Z, 0) -- pasillo / dormitorio
	partition(model, ground, "Z", HALL, -Z, 0) -- pasillo / cocina
	partition(model, ground, "X", 0, -X, -HALL, { -14, -7 }) -- dormitorio / salón (con puerta)
	partition(model, ground, "X", 0, HALL, X, { 7, 14 }) -- cocina / salón (con puerta)

	-- Volúmenes de habitación (la historia detecta cuándo entra el jugador)
	local side = X - HALL - 0.3 -- ancho de dormitorio y cocina
	local rooms = {
		{ "Salon", Vector3.new(2 * X, G - 1, Z - 0.3), at(0, (G - 1) / 2, (Z + 0.3) / 2) },
		{ "Cocina", Vector3.new(side, G - 1, Z - 0.3), at(HALL + 0.3 + side / 2, (G - 1) / 2, -(Z + 0.3) / 2) },
		{ "Dormitorio", Vector3.new(side, G - 1, Z - 0.3), at(-(HALL + 0.3 + side / 2), (G - 1) / 2, -(Z + 0.3) / 2) },
	}
	for _, r in rooms do
		tagged({ Name = "Room_" .. r[1], Size = r[2], CFrame = r[3], Tags = { "Room" }, Attributes = { Room = r[1], HomeId = homeId }, Parent = model })
	end

	-- SALÓN (z 0..21): a la izquierda, el sofá mirando a la tele; a la derecha, la mesa del comedor; al
	-- fondo, el ventanal con el sillón del abuelo. El centro queda libre para las escenas.
	local sofa = rgb(96, 120, 150)
	box(model, "Rug", Vector3.new(12, 0.1, 13), at(-16, 0.05, 10.5), rgb(190, 96, 72), Enum.Material.Fabric, true)
	box(model, "TVStand", Vector3.new(1.8, 2, 7), at(-X + 0.9, 1, 10.5), WOOD, Enum.Material.Wood)
	box(model, "TV", Vector3.new(0.3, 3.6, 6.4), at(-X + 0.9, 4, 10.5), rgb(18, 18, 22), Enum.Material.Glass, true)
	box(model, "SofaSeat", Vector3.new(3.6, 1.6, 11), at(-9.5, 0.8, 10.5), sofa, Enum.Material.Fabric)
	box(model, "SofaBack", Vector3.new(1, 3, 11), at(-7.7, 2, 10.5), sofa, Enum.Material.Fabric)
	for _, z in { 5.4, 15.6 } do
		box(model, "SofaArm", Vector3.new(3.6, 2.4, 0.8), at(-9.5, 1.2, z), sofa, Enum.Material.Fabric, true)
	end
	box(model, "CoffeeTable", Vector3.new(2.8, 1.4, 5), at(-15, 0.7, 10.5), WOOD, Enum.Material.Wood)
	-- Sillón del abuelo: en el centro del salón + (11, 0), mirando hacia delante, como en la casa de antes
	-- (las escenas ponen al abuelo en HomeSalon + (10, 0, -2) «sentado» y + (11, 0, -2.5) hablando)
	local sz = (Z + 0.3) / 2 -- centro del salón (z)
	box(model, "Armchair", Vector3.new(4, 1.6, 4), at(11, 0.8, sz), rgb(140, 90, 60), Enum.Material.Fabric)
	box(model, "ArmchairBack", Vector3.new(4, 3, 1), at(11, 2, sz + 2.5), rgb(140, 90, 60), Enum.Material.Fabric)
	box(model, "SideTable", Vector3.new(1.8, 2.2, 1.8), at(14, 1.1, sz + 1.6), WOOD, Enum.Material.Wood)
	box(model, "Lamp", Vector3.new(1.2, 1.4, 1.2), at(14, 2.9, sz + 1.6), rgb(250, 236, 200), Enum.Material.Fabric, true)
	tagged({ Name = "Familia_Abu", Size = Vector3.new(2, 5, 2), CFrame = at(11, 2.5, sz - 2.5), Tags = { "FamilySpot" }, Attributes = { Npc = "Familia_Abu", HomeId = homeId }, Parent = model })
	-- Comedor: mesa para seis, a la derecha
	box(model, "DiningTable", Vector3.new(4.4, 0.4, 9), at(20, 2.8, 9.5), WOOD, Enum.Material.Wood)
	box(model, "DiningLeg", Vector3.new(0.6, 2.6, 0.6), at(20, 1.3, 9.5), CHAIR, Enum.Material.Wood, true)
	for _, z in { 6.5, 12.5 } do
		chair(model, at, 16.2, z, 1, 0, CHAIR)
		chair(model, at, 23.8, z, -1, 0, CHAIR)
	end
	chair(model, at, 20, 3.4, 0, 1, CHAIR)
	chair(model, at, 20, 15.6, 0, -1, CHAIR)
	bookshelf(model, at(14, 0, Z - 0.7), 6)
	for _, x in { -X + 1.5, X - 1.5 } do
		box(model, "Pot", Vector3.new(1.6, 1.6, 1.6), at(x, 0.8, Z - 1.5), rgb(170, 90, 60), Enum.Material.Plaster)
		Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = at(x, 2.6, Z - 1.5), Color = rgb(70, 124, 58), Material = Enum.Material.LeafyGrass, Parent = model })
	end
	box(model, "FloorLamp", Vector3.new(0.4, 6, 0.4), at(-X + 1.5, 3, 2), rgb(60, 60, 64), Enum.Material.Metal, true)
	box(model, "FloorLampShade", Vector3.new(1.6, 1.4, 1.6), at(-X + 1.5, 6.6, 2), rgb(250, 236, 200), Enum.Material.Fabric, true)
	for i, color in { rgb(200, 120, 90), rgb(90, 140, 190), rgb(220, 190, 110) } do
		box(model, "Picture", Vector3.new(3, 2.2, 0.1), at(({ -19.5, 19.5, -10.5 })[i], 7.5, 0.4), color, nil, true)
	end
	-- Ventanal: punto de mirar afuera (hacia la ciudad, al fondo de la casa)
	tagged({ Name = "LookOutside", Size = Vector3.new(2, 2, 0.2), CFrame = at(0, 5.5, Z - 0.8) * CFrame.Angles(0, math.pi, 0), Tags = { "LookOutside" }, Attributes = { HomeId = homeId }, Parent = model })

	-- COCINA (x 4..25, z -21..0): encimeras en L con fregadero y placa, nevera, mesa con sillas y trona
	local counter, top = rgb(236, 234, 228), rgb(60, 62, 66)
	box(model, "Counter", Vector3.new(2.6, 3.6, 12), at(X - 1.3, 1.8, -13.5), counter, Enum.Material.Plaster)
	box(model, "Worktop", Vector3.new(2.9, 0.3, 12.2), at(X - 1.3, 3.75, -13.5), top, Enum.Material.Granite, true)
	box(model, "Counter", Vector3.new(14, 3.6, 2.6), at(15.4, 1.8, -Z + 1.3), counter, Enum.Material.Plaster)
	box(model, "Worktop", Vector3.new(14.2, 0.3, 2.9), at(15.4, 3.75, -Z + 1.3), top, Enum.Material.Granite, true)
	box(model, "Sink", Vector3.new(2.4, 0.2, 1.6), at(14, 3.92, -Z + 1.3), rgb(190, 194, 200), Enum.Material.Metal, true)
	box(model, "Hob", Vector3.new(2.4, 0.1, 2), at(X - 1.3, 3.95, -10), rgb(30, 30, 34), Enum.Material.Glass, true)
	box(model, "WallCabinet", Vector3.new(12, 2.6, 1.4), at(15.4, 8.2, -Z + 0.7), counter, Enum.Material.Plaster, true)
	-- Nevera: se come de ella gratis y sin límite (InteractService, solo la familia de la casa)
	local fridge = box(model, "Fridge", Vector3.new(2.8, 7, 2.8), at(X - 1.4, 3.5, -4), rgb(226, 229, 233), Enum.Material.Metal)
	fridge:AddTag("Interact")
	fridge:SetAttribute("Use", "Fridge")
	fridge:SetAttribute("FamilyHomeId", homeId)
	local kx, kz = HALL + 0.3 + side / 2, -(Z + 0.3) / 2 -- centro de la cocina
	local tx, tz = kx - 4.5, kz - 1 -- la mesa
	box(model, "KitchenTable", Vector3.new(6, 0.4, 4), at(tx, 2.8, tz), WOOD, Enum.Material.Wood)
	box(model, "TableLeg", Vector3.new(0.6, 2.6, 0.6), at(tx, 1.3, tz), WOOD, Enum.Material.Wood, true)
	chair(model, at, tx - 4.3, tz, 1, 0, CHAIR)
	chair(model, at, tx + 4.3, tz, -1, 0, CHAIR)
	for _, dx in { -1.5, 1.5 } do
		chair(model, at, tx + dx, tz - 3.3, 0, 1, CHAIR)
	end
	box(model, "HighChair", Vector3.new(1.6, 3.4, 1.6), at(tx - 1.8, 1.7, tz + 3.9), rgb(240, 200, 60))
	tagged({ Name = "Familia_Padre", Size = Vector3.new(2, 5, 2), CFrame = at(kx - 1.5, 2.5, kz + 2.5), Tags = { "FamilySpot" }, Attributes = { Npc = "Familia_Padre", HomeId = homeId }, Parent = model })

	-- DORMITORIO (x -25..-4, z -21..0): cama de los padres, cuna, escritorio y juguetes
	box(model, "BedFrame", Vector3.new(7, 1.4, 9), at(-19.5, 0.7, -Z + 4.5), WOOD, Enum.Material.Wood)
	box(model, "Headboard", Vector3.new(7, 3.4, 0.6), at(-19.5, 1.7, -Z + 0.3), WOOD, Enum.Material.Wood, true)
	box(model, "Mattress", Vector3.new(6.6, 0.8, 8.6), at(-19.5, 1.8, -Z + 4.5), rgb(238, 238, 242), Enum.Material.Fabric)
	box(model, "Blanket", Vector3.new(6.8, 0.3, 5), at(-19.5, 2.3, -Z + 6.2), rgb(110, 150, 200), Enum.Material.Fabric, true)
	for _, x in { -24.1, -14.9 } do
		box(model, "Nightstand", Vector3.new(1.8, 2, 1.8), at(x, 1, -Z + 1.2), WOOD, Enum.Material.Wood)
	end
	box(model, "BedroomRug", Vector3.new(9, 0.1, 7), at(-14, 0.05, -9), rgb(220, 200, 160), Enum.Material.Fabric, true)
	local crib = at(-9, 0, -Z + 3.5)
	box(model, "CribBase", Vector3.new(4.4, 0.6, 3), crib * CFrame.new(0, 1.6, 0), rgb(250, 250, 250))
	for _, dz in { -1.4, 1.4 } do
		box(model, "CribRail", Vector3.new(4.4, 2, 0.2), crib * CFrame.new(0, 2.6, dz), rgb(250, 250, 250), nil, true)
	end
	for _, dx in { -2.1, 2.1 } do
		box(model, "CribLeg", Vector3.new(0.3, 3.6, 3), crib * CFrame.new(dx, 1.8, 0), rgb(250, 250, 250), nil, true)
	end
	for i, color in { rgb(230, 70, 70), rgb(60, 140, 230), rgb(250, 200, 50) } do
		box(model, "ToyBlock", Vector3.new(0.8, 0.8, 0.8), at(-14 + i * 0.9, 0.4, -9), color, nil, true)
	end
	-- Escritorio junto a la pared, con su silla
	box(model, "Desk", Vector3.new(2.4, 2.8, 5), at(-X + 1.2, 1.4, -8.5), WOOD, Enum.Material.Wood)
	chair(model, at, -X + 3.4, -8.5, -1, 0, rgb(60, 110, 180))
	-- Mañana del primer día de cole: armario, espejo, mochila y desayuno
	local mark = { HomeId = homeId }
	box(model, "Wardrobe", Vector3.new(1.8, 7.2, 4.2), at(-HALL - 1.2, 3.6, -5), WOOD, Enum.Material.Wood)
	box(model, "WardrobeDoorLine", Vector3.new(0.1, 6.6, 0.1), at(-HALL - 2.15, 3.6, -5), rgb(90, 64, 42), Enum.Material.Wood, true)
	for _, z in { -5.4, -4.6 } do
		box(model, "WardrobeKnob", Vector3.new(0.15, 0.4, 0.15), at(-HALL - 2.2, 3.6, z), rgb(210, 180, 90), Enum.Material.Metal, true)
	end
	StoryMarks.prop(model, "Armario", at(-HALL - 2.5, 3, -5), Vector3.new(2, 6, 4.4), mark)
	box(model, "MirrorFrame", Vector3.new(2.4, 4.4, 0.15), at(-20, 4.4, -0.45), rgb(200, 170, 110), Enum.Material.Wood, true)
	box(model, "Mirror", Vector3.new(2, 4, 0.1), at(-20, 4.4, -0.55), rgb(210, 225, 235), Enum.Material.Glass, true).Reflectance = 0.6
	StoryMarks.prop(model, "Espejo", at(-20, 3.5, -1.6), Vector3.new(3, 5, 2), mark)
	box(model, "Backpack", Vector3.new(1.4, 1.8, 0.9), at(-X + 1, 0.9, -3.2), rgb(40, 110, 200), Enum.Material.Fabric)
	box(model, "BackpackPocket", Vector3.new(1, 0.8, 0.3), at(-X + 1, 0.6, -2.65), rgb(230, 180, 40), Enum.Material.Fabric, true)
	StoryMarks.prop(model, "Mochila", at(-X + 1, 1.2, -3.2), Vector3.new(2, 2.4, 2), mark)
	StoryMarks.prop(model, "Cama", at(-19.5, 2, -Z + 4.5), Vector3.new(7, 3, 9), mark)
	StoryMarks.spot(model, "Despertar", at(-14.5, 2.5, -Z + 6) * CFrame.Angles(0, math.rad(-90), 0), mark)
	-- Desayuno en la mesa de la cocina
	box(model, "BreakfastPlate", Vector3.new(1.4, 0.1, 1.4), at(tx, 3.05, tz), rgb(250, 250, 250), nil, true)
	box(model, "Toast", Vector3.new(0.9, 0.15, 0.9), at(tx, 3.18, tz), rgb(220, 170, 100), nil, true)
	box(model, "Glass", Vector3.new(0.4, 0.7, 0.4), at(tx + 1.2, 3.35, tz - 0.3), rgb(255, 170, 60), Enum.Material.Glass, true)
	StoryMarks.prop(model, "Desayuno", at(tx, 3.5, tz), Vector3.new(3, 2, 2.4), mark)
	StoryMarks.spot(model, "SalirCasa", at(0, 2.5, -D / 2 - 4) * CFrame.Angles(0, math.pi, 0), mark)

	-- Recibidor (el pasillo de 8 studs): perchero y zapatero pegados a la pared, sin estorbar
	box(model, "CoatRack", Vector3.new(0.6, 6, 0.6), at(HALL - 0.8, 3, -Z + 2), rgb(90, 64, 42), Enum.Material.Wood, true)
	box(model, "ShoeCabinet", Vector3.new(1.2, 2.4, 4), at(HALL - 0.9, 1.2, -12), WOOD, Enum.Material.Wood)

	tagged({ Name = "BabySpawn", Size = Vector3.new(2, 1, 2), CFrame = at(-9, 0.6, -Z + 7) * CFrame.Angles(0, math.pi, 0), Tags = { "BabySpawn" }, Attributes = { HomeId = homeId }, Parent = model })

	return model
end

-- Fila de casas familiares a lo largo de un lado de manzana (lote de Blocks.lot): una casa cada SLOT studs
function Home.familyRow(parent: Instance, lot: any, prefix: string): Model
	local m = Builder.model("CasasFamiliares", parent)
	local count = math.max(1, math.floor(lot.Length / SLOT))
	local width = lot.Length / count
	for i = 0, count - 1 do
		local u = -lot.Length / 2 + width * (i + 0.5)
		Home.familyHouse(m, lot.facing(u, 12 + D / 2, 0), prefix .. "_" .. (i + 1))
		-- Camino de entrada, setos y jardín
		Builder.part({ Name = "Path", Size = Vector3.new(7, 0.4, 12), CFrame = lot.facing(u, 6, 0.2), Color = rgb(206, 196, 178), Material = Enum.Material.Pavement, Parent = m })
		for _, side in { -1, 1 } do
			Nature.hedge(m, lot.point(u + side * (width / 2 - 1), 2, 0), lot.point(u + side * (width / 2 - 1), lot.Depth - 2, 0), 2.6)
		end
		Nature.tree(m, lot.point(u + width / 4, lot.Depth - 8, 0))
	end
	return m
end

return Home
