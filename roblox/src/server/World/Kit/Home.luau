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
-- Distribución (vista desde arriba, la puerta al sur/frente):
--   ┌───────────────────────────────┐  fondo: ventanal con vista
--   │            SALÓN              │
--   ├─────────┐ pasillo ┌──────────┤
--   │DORMITORIO│  ↑↑↑   │  COCINA  │
--   └─────────┴──puerta─┴──────────┘

local Builder = require(script.Parent.Parent.Builder)
local Building = require(script.Parent.Building)
local Nature = require(script.Parent.Nature)
local StoryMarks = require(script.Parent.StoryMarks)

local Home = {}

local rgb = Color3.fromRGB
-- Más grande que antes (36 × 30 y 11 de alto): en el salón, la cocina y el dormitorio no cabía la cámara
-- de las escenas de la historia (salía detrás de una pared o pegada a la nuca de alguien). Cabe en su
-- parcela (Blocks.familyRow: 50 de ancho por casa).
local W, D = 44, 42 -- tamaño exterior de la casa
local G = 14 -- altura interior (planta baja de tipo "House", más alta)
-- La distribución se escribió para 36 × 30: las posiciones se estiran (los muebles no cambian de tamaño)
local SX, SZ = W / 36, D / 30
local WALL = rgb(246, 242, 234)
local WOOD = rgb(150, 108, 72)

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
			Size = if axis == "X" then Vector3.new(width, G - 8, 0.6) else Vector3.new(0.6, G - 8, width),
			CFrame = if axis == "X" then at(mid, 8 + (G - 8) / 2, fixed) else at(fixed, 8 + (G - 8) / 2, mid),
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
		WindowFaces = { Front = true, Back = true, Left = true, Right = true },
		FloorColor = rgb(186, 146, 104),
		LightColor = rgb(255, 226, 186),
	})
	-- at() de Building ya mide desde el suelo interior: los muebles con y = 0 quedan apoyados en él
	local ground = at
	-- (posiciones de la distribución de 36 × 30, estiradas a la casa de ahora)
	local function sat(x: number, y: number, z: number): CFrame
		return at(x * SX, y, z * SZ)
	end
	model:AddTag("FamilyHome")
	model:SetAttribute("HomeId", homeId)

	-- Tabiques: dormitorio (izquierda) y cocina (derecha) delante; salón al fondo
	local front = D / 2 - 1 -- (del pasillo a la fachada)
	local side = W / 2 - 1
	partition(model, ground, "Z", -4 * SX, -front, 0) -- pasillo / dormitorio
	partition(model, ground, "Z", 4 * SX, -front, 0) -- pasillo / cocina
	partition(model, ground, "X", 0, -side, -4 * SX, { -10 * SX - 2.5, -10 * SX + 2.5 }) -- dormitorio / salón (con puerta)
	partition(model, ground, "X", 0, 4 * SX, side, { 10 * SX - 2.5, 10 * SX + 2.5 }) -- cocina / salón (con puerta)

	-- Volúmenes de habitación (la historia detecta cuándo entra el jugador)
	local rooms = {
		{ "Salon", Vector3.new(34 * SX, G - 1, 14 * SZ), sat(0, 5, 7) },
		{ "Cocina", Vector3.new(13 * SX, G - 1, 14 * SZ), sat(10.5, 5, -7) },
		{ "Dormitorio", Vector3.new(13 * SX, G - 1, 14 * SZ), sat(-10.5, 5, -7) },
	}
	for _, r in rooms do
		tagged({ Name = "Room_" .. r[1], Size = r[2], CFrame = r[3], Tags = { "Room" }, Attributes = { Room = r[1], HomeId = homeId }, Parent = model })
	end

	-- SALÓN: sofá mirando al ventanal, sillón del abuelo, alfombra, tele y plantas
	local sofa = rgb(96, 120, 150)
	box(model, "SofaSeat", Vector3.new(10, 1.6, 3.4), sat(-4, 0.8, 4), sofa, Enum.Material.Fabric)
	box(model, "SofaBack", Vector3.new(10, 3, 1), sat(-4, 2, 4) * CFrame.new(0, 0, -1.6), sofa, Enum.Material.Fabric)
	box(model, "Rug", Vector3.new(12, 0.1, 7), sat(-2, 0.05, 9), rgb(190, 96, 72), Enum.Material.Fabric, true)
	box(model, "CoffeeTable", Vector3.new(5, 1.4, 2.6), sat(-4, 0.7, 8), WOOD, Enum.Material.Wood)
	box(model, "Armchair", Vector3.new(4, 1.6, 4), sat(11, 0.8, 7), rgb(140, 90, 60), Enum.Material.Fabric)
	box(model, "ArmchairBack", Vector3.new(4, 3, 1), sat(11, 2, 7) * CFrame.new(0, 0, 2.5), rgb(140, 90, 60), Enum.Material.Fabric)
	box(model, "TVStand", Vector3.new(1.6, 2, 6), sat(-15.6, 1, 8), WOOD, Enum.Material.Wood)
	box(model, "TV", Vector3.new(0.3, 3.2, 5.6), sat(-15.6, 3.7, 8), rgb(18, 18, 22), Enum.Material.Glass, true)
	for _, x in { -15.5, 15.5 } do
		box(model, "Pot", Vector3.new(1.6, 1.6, 1.6), sat(x, 0.8, 12.8), rgb(170, 90, 60), Enum.Material.Plaster)
		Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = sat(x, 2.6, 12.8), Color = rgb(70, 124, 58), Material = Enum.Material.LeafyGrass, Parent = model })
	end
	-- Ventanal: punto de mirar afuera (hacia la ciudad, al fondo de la casa)
	tagged({ Name = "LookOutside", Size = Vector3.new(2, 2, 0.2), CFrame = sat(0, 5.5, 13.2) * CFrame.Angles(0, math.pi, 0), Tags = { "LookOutside" }, Attributes = { HomeId = homeId }, Parent = model })
	tagged({ Name = "Familia_Abu", Size = Vector3.new(2, 5, 2), CFrame = sat(11, 2.5, 4.5), Tags = { "FamilySpot" }, Attributes = { Npc = "Familia_Abu", HomeId = homeId }, Parent = model })

	-- COCINA: encimera, nevera, mesa con sillas y trona
	box(model, "Counter", Vector3.new(2.6, 3.6, 10), sat(15.3, 1.8, -8.5), rgb(236, 234, 228), Enum.Material.Plaster)
	box(model, "Worktop", Vector3.new(2.9, 0.3, 10.2), sat(15.3, 3.75, -8.5), rgb(60, 62, 66), Enum.Material.Granite, true)
	-- Nevera: se come de ella gratis y sin límite (InteractService, solo la familia de la casa)
	local fridge = box(model, "Fridge", Vector3.new(2.8, 7, 2.8), sat(15.4, 3.5, -2), rgb(226, 229, 233), Enum.Material.Metal)
	fridge:AddTag("Interact")
	fridge:SetAttribute("Use", "Fridge")
	fridge:SetAttribute("FamilyHomeId", homeId)
	box(model, "KitchenTable", Vector3.new(5, 0.4, 3.4), sat(9, 2.8, -8), WOOD, Enum.Material.Wood)
	box(model, "TableLeg", Vector3.new(0.6, 2.6, 0.6), sat(9, 1.3, -8), WOOD, Enum.Material.Wood, true)
	for _, x in { 6.8, 11.2 } do
		box(model, "Chair", Vector3.new(1.8, 1.8, 1.8), sat(x, 0.9, -8), rgb(120, 84, 56), Enum.Material.Wood)
	end
	box(model, "HighChair", Vector3.new(1.6, 3.4, 1.6), sat(9, 1.7, -11.2), rgb(240, 200, 60))
	tagged({ Name = "Familia_Padre", Size = Vector3.new(2, 5, 2), CFrame = sat(9, 2.5, -4.5), Tags = { "FamilySpot" }, Attributes = { Npc = "Familia_Padre", HomeId = homeId }, Parent = model })

	-- DORMITORIO: cama de los padres, cuna y juguetes
	box(model, "BedFrame", Vector3.new(6, 1.4, 8), sat(-13.5, 0.7, -9.5), WOOD, Enum.Material.Wood)
	box(model, "Mattress", Vector3.new(5.6, 0.8, 7.6), sat(-13.5, 1.8, -9.5), rgb(238, 238, 242), Enum.Material.Fabric)
	box(model, "Blanket", Vector3.new(5.8, 0.3, 4.6), sat(-13.5, 2.3, -8), rgb(110, 150, 200), Enum.Material.Fabric, true)
	local crib = sat(-7, 0, -11.5)
	box(model, "CribBase", Vector3.new(4.4, 0.6, 3), crib * CFrame.new(0, 1.6, 0), rgb(250, 250, 250))
	for _, dz in { -1.4, 1.4 } do
		box(model, "CribRail", Vector3.new(4.4, 2, 0.2), crib * CFrame.new(0, 2.6, dz), rgb(250, 250, 250), nil, true)
	end
	for _, dx in { -2.1, 2.1 } do
		box(model, "CribLeg", Vector3.new(0.3, 3.6, 3), crib * CFrame.new(dx, 1.8, 0), rgb(250, 250, 250), nil, true)
	end
	for i, color in { rgb(230, 70, 70), rgb(60, 140, 230), rgb(250, 200, 50) } do
		box(model, "ToyBlock", Vector3.new(0.8, 0.8, 0.8), sat(-9 + i * 0.9, 0.4, -5), color, nil, true)
	end
	-- Mañana del primer día de cole: armario, espejo, mochila y desayuno
	local mark = { HomeId = homeId }
	box(model, "Wardrobe", Vector3.new(1.8, 7.2, 4.2), sat(-5.2, 3.6, -2.4), WOOD, Enum.Material.Wood)
	box(model, "WardrobeDoorLine", Vector3.new(0.1, 6.6, 0.1), sat(-5.2, 3.6, -2.4) * CFrame.new(-0.95, 0, 0), rgb(90, 64, 42), Enum.Material.Wood, true)
	for _, z in { -2.8, -2 } do
		box(model, "WardrobeKnob", Vector3.new(0.15, 0.4, 0.15), sat(-5.2, 3.6, -2.4) * CFrame.new(-1, 0, z + 2.4), rgb(210, 180, 90), Enum.Material.Metal, true)
	end
	StoryMarks.prop(model, "Armario", sat(-6.5, 3, -2.4), Vector3.new(2, 6, 4.4), mark)
	box(model, "MirrorFrame", Vector3.new(2.4, 4.4, 0.15), sat(-15.2, 4.4, -0.45), rgb(200, 170, 110), Enum.Material.Wood, true)
	box(model, "Mirror", Vector3.new(2, 4, 0.1), sat(-15.2, 4.4, -0.55), rgb(210, 225, 235), Enum.Material.Glass, true).Reflectance = 0.6
	StoryMarks.prop(model, "Espejo", sat(-15.2, 3.5, -1.6), Vector3.new(3, 5, 2), mark)
	box(model, "Backpack", Vector3.new(1.4, 1.8, 0.9), sat(-15.2, 0.9, -4.3), rgb(40, 110, 200), Enum.Material.Fabric)
	box(model, "BackpackPocket", Vector3.new(1, 0.8, 0.3), sat(-15.2, 0.6, -4.3) * CFrame.new(0, 0, 0.55), rgb(230, 180, 40), Enum.Material.Fabric, true)
	StoryMarks.prop(model, "Mochila", sat(-15.2, 1.2, -4.3), Vector3.new(2, 2.4, 2), mark)
	StoryMarks.prop(model, "Cama", sat(-13.5, 2, -9.5), Vector3.new(6, 3, 8), mark)
	StoryMarks.spot(model, "Despertar", sat(-9.5, 2.5, -8) * CFrame.Angles(0, math.rad(-90), 0), mark)
	-- Desayuno en la mesa de la cocina
	box(model, "BreakfastPlate", Vector3.new(1.4, 0.1, 1.4), sat(9, 3.05, -8), rgb(250, 250, 250), nil, true)
	box(model, "Toast", Vector3.new(0.9, 0.15, 0.9), sat(9, 3.18, -8), rgb(220, 170, 100), nil, true)
	box(model, "Glass", Vector3.new(0.4, 0.7, 0.4), sat(9, 3.35, -8) * CFrame.new(1.2, 0, -0.3), rgb(255, 170, 60), Enum.Material.Glass, true)
	StoryMarks.prop(model, "Desayuno", sat(9, 3.5, -8), Vector3.new(3, 2, 2.4), mark)
	StoryMarks.spot(model, "SalirCasa", at(0, 2.5, -D / 2 - 4) * CFrame.Angles(0, math.pi, 0), mark)

	tagged({ Name = "BabySpawn", Size = Vector3.new(2, 1, 2), CFrame = sat(-7, 0.6, -8) * CFrame.Angles(0, math.pi, 0), Tags = { "BabySpawn" }, Attributes = { HomeId = homeId }, Parent = model })

	return model
end

-- Fila de casas familiares a lo largo de un lado de manzana (lote de Blocks.lot)
function Home.familyRow(parent: Instance, lot: any, prefix: string): Model
	local m = Builder.model("CasasFamiliares", parent)
	local count = math.floor(lot.Length / 48)
	local width = lot.Length / count
	for i = 0, count - 1 do
		local u = -lot.Length / 2 + width * (i + 0.5)
		Home.familyHouse(m, lot.facing(u, 12 + D / 2, 0), prefix .. "_" .. (i + 1))
		-- Camino de entrada, setos y jardín
		Builder.part({ Name = "Path", Size = Vector3.new(4, 0.4, 12), CFrame = lot.facing(u, 6, 0.2), Color = rgb(206, 196, 178), Material = Enum.Material.Pavement, Parent = m })
		for _, side in { -1, 1 } do
			Nature.hedge(m, lot.point(u + side * (width / 2 - 1), 2, 0), lot.point(u + side * (width / 2 - 1), lot.Depth - 2, 0), 2.6)
		end
		Nature.tree(m, lot.point(u + width / 4, lot.Depth - 8, 0))
	end
	return m
end

return Home
