-- TownBuilder: construye la ciudad de Valmar (prototipo) con los kits de /Kit.
--
-- Mapa (vista desde arriba, el norte es -Z):
--
--   Punto Limpio · edificios · Mega Burger · PLAZA | edificios · Cafetería · Supermercado · Correos
--   ========================== AVENIDA (z = 0) ===========================================
--   Casas 1-8 (fila 1)                             |
--   ========================== CALLE RESIDENCIAL (z = 120) ===============================
--   Casas 9-16 (fila 2)                            |
--                                           CALLE N-S (x = 0)
--
-- Todo lo que usa la jugabilidad se marca con tags (CollectionService):
--   JobBoard (+JobId), Pickup_<Trabajo>, Dropoff_<Trabajo>, FoodStand (+FoodId),
--   StreetLamp, NightWindow, Plot (+PlotId), PlotSign (+PlotId)

local Builder = require(script.Parent.Builder)
local Kit = script.Parent.Kit
local Palette = require(Kit.Palette)
local Street = require(Kit.Street)
local Building = require(Kit.Building)
local Nature = require(Kit.Nature)
local Props = require(Kit.Props)
local AssetLibrary = require(Kit.AssetLibrary)
local Region = require(script.Parent.Region)

local TownBuilder = {}

local WALK = Street.WALK_TOP
local PLOT_SIZE = 50
local rgb = Color3.fromRGB

local NORTH = Vector3.new(0, 0, -1)
local SOUTH = Vector3.new(0, 0, 1)
local EAST = Vector3.new(1, 0, 0)
local WEST = Vector3.new(-1, 0, 0)

local function facing(position: Vector3, direction: Vector3): CFrame
	return Builder.facing(position, direction)
end

local ROADS = {
	Avenue = Region.Highways.Avenue, -- la avenida sigue hasta San Roque y Playa Dorada
	Residential = { Axis = "X", At = 120, From = -340, To = 340, Lamps = true, Trees = true },
	NorthSouth = Region.Highways.NorthSouth, -- sigue hasta Valmar Norte y Los Pinos
}

-- Fachada a ras de la acera norte de la avenida: devuelve el CFrame del edificio
local function northOfAvenue(x: number, depth: number): CFrame
	return facing(Vector3.new(x, 0, -Street.HALF - depth / 2), SOUTH)
end

---------------------------------------------------------------------
-- Mobiliario interior de los negocios
---------------------------------------------------------------------

local function counter(parent: Instance, cf: CFrame, width: number, color: Color3)
	Builder.part({ Name = "Counter", Size = Vector3.new(width, 3.6, 3), CFrame = cf * CFrame.new(0, 1.8, 0), Color = color, Material = Enum.Material.Wood, Parent = parent })
	Builder.part({ Name = "CounterTop", Size = Vector3.new(width + 0.4, 0.3, 3.4), CFrame = cf * CFrame.new(0, 3.75, 0), Color = rgb(236, 234, 228), Material = Enum.Material.Marble, Parent = parent })
end

local function foodStand(parent: Instance, cf: CFrame, foodId: string, color: Color3)
	Builder.part({
		Name = "Food_" .. foodId,
		Size = Vector3.new(1.6, 1.2, 1.6),
		CFrame = cf,
		Color = color,
		Tags = { "FoodStand" },
		Attributes = { FoodId = foodId },
		Parent = parent,
	})
end

local function cafeTable(parent: Instance, cf: CFrame, tag: string?)
	local m = Builder.model("Table", parent)
	Builder.part({
		Name = "Top",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 4.4, 4.4),
		CFrame = cf * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(236, 232, 224),
		Material = Enum.Material.Marble,
		Tags = if tag then { tag } else nil,
		Parent = m,
	})
	Builder.decor({ Name = "Leg", Size = Vector3.new(0.4, 2.8, 0.4), CFrame = cf * CFrame.new(0, 1.5, 0), Color = Palette.Street.Metal, Material = Enum.Material.Metal, Parent = m })
	for _, dir in { -1, 1 } do
		local chair = cf * CFrame.new(dir * 3.4, 0, 0) * CFrame.Angles(0, if dir > 0 then math.rad(90) else math.rad(-90), 0)
		Builder.part({ Name = "Seat", Size = Vector3.new(2, 0.3, 2), CFrame = chair * CFrame.new(0, 1.9, 0), Color = rgb(150, 100, 64), Material = Enum.Material.Wood, Parent = m })
		Builder.decor({ Name = "Back", Size = Vector3.new(2, 2, 0.25), CFrame = chair * CFrame.new(0, 3, -0.9), Color = rgb(150, 100, 64), Material = Enum.Material.Wood, Parent = m })
		for _, lx in { -0.8, 0.8 } do
			for _, lz in { -0.8, 0.8 } do
				Builder.decor({ Name = "ChairLeg", Size = Vector3.new(0.2, 1.8, 0.2), CFrame = chair * CFrame.new(lx, 0.9, lz), Color = Palette.Street.Metal, Parent = m })
			end
		end
	end
end

---------------------------------------------------------------------
-- Negocios
---------------------------------------------------------------------

local function buildCafe(world: Instance)
	local W, D = 44, 34
	local model, at = Building.build({
		Name = "Cafeteria", Parent = world, CFrame = northOfAvenue(70, D),
		Width = W, Depth = D, Floors = 4, Style = "Clasico", GroundFloor = "Shop",
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "CAFETERÍA CENTRAL", SignColor = rgb(96, 60, 38), Awning = rgb(110, 66, 40),
		FloorMaterial = Enum.Material.WoodPlanks, FloorColor = rgb(150, 108, 72),
	})
	counter(model, at(0, 0, 11), 26, rgb(96, 60, 38))
	Builder.part({
		Name = "CoffeeMachine", Size = Vector3.new(3, 3, 2), CFrame = at(-9, 5.4, 11),
		Color = rgb(60, 60, 66), Material = Enum.Material.Metal, Tags = { "Pickup_Barista" }, Parent = model,
	})
	foodStand(model, at(4, 4.5, 10.5), "Cafe", rgb(96, 60, 38))
	foodStand(model, at(9, 4.5, 10.5), "Croissant", rgb(222, 170, 90))
	for _, p in { { -12, -8 }, { 0, -8 }, { 12, -8 }, { -12, 1 }, { 12, 1 } } do
		cafeTable(model, at(p[1], 0, p[2]), "Dropoff_Barista")
	end
	Props.jobBoard(world, at(10, 0, -D / 2 - 3.5) * CFrame.Angles(0, math.pi, 0), "Barista", "BARISTA")
	-- Terraza en la acera
	cafeTable(world, at(-14, 0, -D / 2 - 4), nil)
end

local function buildSupermarket(world: Instance)
	local W, D = 60, 48
	local model, at = Building.build({
		Name = "Supermercado", Parent = world, CFrame = northOfAvenue(160, D),
		Width = W, Depth = D, Floors = 2, Style = "Moderno", GroundFloor = "Shop", Balconies = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "SUPERMERCADO", SignColor = rgb(36, 132, 76), Awning = rgb(36, 132, 76),
		FloorMaterial = Enum.Material.CeramicTiles, FloorColor = rgb(226, 226, 222),
		LightColor = rgb(240, 248, 255),
	})
	for i, x in { -20, -8, 4 } do
		for j, z in { -6, 8 } do
			local shelf = Builder.part({
				Name = "Shelf" .. i .. j, Size = Vector3.new(3, 7, 10), CFrame = at(x, 3.5, z),
				Color = rgb(206, 206, 210), Material = Enum.Material.Metal, Tags = { "Dropoff_Reponedor" }, Parent = model,
			})
			for k = 0, 2 do
				Builder.decor({
					Name = "Products", Size = Vector3.new(3.4, 1, 9), CFrame = shelf.CFrame * CFrame.new(0, -2 + k * 2.2, 0),
					Color = Color3.fromHSV(math.random(), 0.55, 0.9), Parent = model,
				})
			end
		end
	end
	for _, x in { 20, 25 } do
		Builder.part({
			Name = "StockBoxes", Size = Vector3.new(4, 4, 4), CFrame = at(x, 2, 18),
			Color = rgb(190, 150, 90), Material = Enum.Material.Cardboard, Tags = { "Pickup_Reponedor" }, Parent = model,
		})
	end
	counter(model, at(20, 0, -12), 10, rgb(36, 132, 76))
	foodStand(model, at(17, 4.5, -12), "Fruta", rgb(226, 60, 60))
	foodStand(model, at(22, 4.5, -12), "Bocadillo", rgb(226, 190, 120))
	Props.jobBoard(world, at(-22, 0, -D / 2 - 3.5) * CFrame.Angles(0, math.pi, 0), "Reponedor", "REPONEDOR")
end

local function buildPostOffice(world: Instance)
	local W, D = 40, 30
	local model, at = Building.build({
		Name = "Correos", Parent = world, CFrame = northOfAvenue(255, D),
		Width = W, Depth = D, Floors = 3, Style = "Clasico", GroundFloor = "Shop", WallColor = rgb(238, 204, 96),
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "CORREOS", SignColor = rgb(30, 60, 140), Awning = rgb(30, 60, 140),
	})
	counter(model, at(0, 0, 3), 20, rgb(30, 60, 140))
	Builder.part({
		Name = "Parcels", Size = Vector3.new(10, 5, 4), CFrame = at(0, 2.5, 11),
		Color = rgb(170, 120, 70), Material = Enum.Material.Cardboard, Tags = { "Pickup_Repartidor" }, Parent = model,
	})
	Props.jobBoard(world, at(10, 0, -D / 2 - 3.5) * CFrame.Angles(0, math.pi, 0), "Repartidor", "REPARTIDOR")
end

local function buildBurger(world: Instance)
	local W, D = 40, 32
	local model, at = Building.build({
		Name = "MegaBurger", Parent = world, CFrame = northOfAvenue(-150, D),
		Width = W, Depth = D, Floors = 2, Style = "Popular", GroundFloor = "Shop", WallColor = rgb(196, 58, 48),
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = "MEGA BURGER", SignColor = rgb(240, 186, 40), Awning = rgb(240, 186, 40),
		FloorMaterial = Enum.Material.CeramicTiles, FloorColor = rgb(230, 222, 206),
	})
	counter(model, at(0, 0, 10), 22, rgb(240, 186, 40))
	foodStand(model, at(-4, 4.5, 9.5), "Hamburguesa", rgb(170, 100, 50))
	foodStand(model, at(4, 4.5, 9.5), "Menu", rgb(226, 60, 50))
	for _, p in { { -11, -6 }, { 11, -6 }, { 0, -1 } } do
		cafeTable(model, at(p[1], 0, p[2]), nil)
	end
end

---------------------------------------------------------------------
-- Edificios de viviendas y comercios cerrados (relleno urbano)
---------------------------------------------------------------------

local SHOP_NAMES = { "FARMACIA", "PANADERÍA", "ZAPATERÍA", "BANCO VALMAR", "INMOBILIARIA", "FLORISTERÍA", "LIBRERÍA", "PELUQUERÍA", "FERRETERÍA", "ÓPTICA" }
local AWNINGS = { rgb(170, 40, 40), rgb(40, 90, 150), rgb(40, 120, 70), rgb(200, 150, 40), rgb(90, 60, 110) }
local STYLES = { "Clasico", "Popular", "Moderno", "Clasico", "Popular" }

local function filler(world: Instance, cf: CFrame, width: number, index: number)
	local style = STYLES[(index - 1) % #STYLES + 1]
	local isShop = math.random() < 0.55
	Building.build({
		Name = "Edificio_" .. index,
		Parent = world,
		CFrame = cf,
		Width = width,
		Depth = 28,
		Floors = math.random(3, 6),
		Style = style,
		GroundFloor = if isShop then "Shop" else "Closed",
		Interior = false,
		WindowFaces = { Front = true, Left = true, Right = true },
		Sign = if isShop then SHOP_NAMES[math.random(1, #SHOP_NAMES)] else nil,
		Awning = if isShop then Palette.pick(AWNINGS) else nil,
	})
end

local function buildFillers(world: Instance)
	local folder = Builder.model("Edificios", world)
	local index = 0
	-- Acera norte de la avenida (x, ancho)
	for _, spec in { { -310, 36 }, { -199, 34 }, { -111, 30 }, { 34, 24 }, { 111, 34 }, { 212, 38 }, { 306, 56 } } do
		index += 1
		filler(folder, northOfAvenue(spec[1], 28), spec[2], index)
	end
	-- Calle N-S, tramo norte (fachadas mirando a la calle)
	for _, spec in { { 1, -86, 34 }, { 1, -126, 34 }, { 1, -164, 30 }, { -1, -104, 34 }, { -1, -144, 34 } } do
		index += 1
		local side, z, width = spec[1], spec[2], spec[3]
		local pos = Vector3.new(side * (Street.HALF + 14), 0, z)
		filler(folder, facing(pos, if side > 0 then WEST else EAST), width, index)
	end
end

---------------------------------------------------------------------
-- Plaza mayor (punto de aparición)
---------------------------------------------------------------------

local function buildPlaza(world: Instance)
	local plaza = Builder.model("Plaza", world)
	local cx, cz = -60, -52
	local x0, x1, z0, z1 = -90, -30, -82, -20
	Builder.part({
		Name = "PlazaFloor",
		Size = Vector3.new(x1 - x0, WALK, z1 - z0),
		CFrame = CFrame.new((x0 + x1) / 2, WALK / 2, (z0 + z1) / 2),
		Color = Palette.Ground.Plaza,
		Material = Enum.Material.Pavement,
		Parent = plaza,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.new(cx, WALK + 0.1, -32)
	spawn.Color = Palette.Ground.Plaza
	spawn.Material = Enum.Material.Pavement
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = plaza

	-- Fuente de dos pisos
	local f = Vector3.new(cx, WALK, cz - 4)
	local stone = rgb(226, 222, 212)
	local function disc(name: string, height: number, diameter: number, y: number, color: Color3, material: Enum.Material, transparency: number?)
		Builder.part({
			Name = name,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, diameter, diameter),
			CFrame = CFrame.new(f + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = color,
			Material = material,
			Transparency = transparency or 0,
			CanCollide = transparency == nil,
			Parent = plaza,
		})
	end
	disc("FountainRim", 2.2, 22, 1.1, stone, Enum.Material.Limestone)
	disc("FountainWater", 0.3, 20.4, 1.9, rgb(70, 150, 210), Enum.Material.Glass, 0.25)
	disc("FountainColumn", 6, 2.4, 4, stone, Enum.Material.Limestone)
	disc("FountainBowl", 1, 9, 6.8, stone, Enum.Material.Limestone)
	disc("FountainBowlWater", 0.2, 8, 7.35, rgb(70, 150, 210), Enum.Material.Glass, 0.25)
	disc("FountainTop", 2.4, 1.2, 8.4, stone, Enum.Material.Limestone)

	-- Palmeras, bancos y parterres
	for _, p in { { -84, -76 }, { -36, -76 }, { -84, -30 }, { -36, -30 }, { -84, -53 }, { -36, -53 } } do
		Nature.palm(plaza, Vector3.new(p[1], WALK, p[2]))
	end
	for _, b in { { -74, -56, EAST }, { -46, -56, WEST }, { -60, -70, SOUTH } } do
		Props.bench(plaza, facing(Vector3.new(b[1], WALK, b[2]), b[3]))
	end
	Nature.flowerBed(plaza, CFrame.new(-74, WALK, -40), 8, 4)
	Nature.flowerBed(plaza, CFrame.new(-46, WALK, -40), 8, 4)
	Nature.flowerBed(plaza, CFrame.new(-60, WALK, -78), 16, 3)

	-- Cartel de bienvenida (mira hacia el punto de aparición)
	local welcome = Builder.part({
		Name = "WelcomeSign",
		Size = Vector3.new(22, 4.5, 0.6),
		CFrame = facing(Vector3.new(cx, WALK + 8, -80), SOUTH),
		Color = rgb(28, 34, 48),
		Parent = plaza,
	})
	Builder.sign(welcome, "Bienvenido a VALMAR", Enum.NormalId.Front)
	for _, x in { -10, 10 } do
		Builder.part({ Name = "SignPost", Size = Vector3.new(0.8, 10, 0.8), CFrame = CFrame.new(cx + x, WALK + 5, -80), Color = Palette.Street.Metal, Material = Enum.Material.Metal, Parent = plaza })
	end
end

---------------------------------------------------------------------
-- Punto Limpio y bolsas de basura
---------------------------------------------------------------------

local function buildRecycling(world: Instance)
	local area = Builder.model("PuntoLimpio", world)
	local cx = -240
	Builder.part({
		Name = "Yard", Size = Vector3.new(40, WALK, 38), CFrame = CFrame.new(cx, WALK / 2, -39),
		Color = rgb(128, 128, 124), Material = Enum.Material.Concrete, Parent = area,
	})
	local colors = { rgb(40, 120, 60), rgb(40, 80, 160), rgb(220, 180, 40) }
	for i, x in { -12, 0, 12 } do
		Builder.part({
			Name = "Container" .. i, Size = Vector3.new(9, 6, 5), CFrame = CFrame.new(cx + x, WALK + 3, -50),
			Color = colors[i], Material = Enum.Material.Metal, Tags = { "Dropoff_Basurero" }, Parent = area,
		})
	end
	for _, x in { -20, 20 } do
		Builder.part({ Name = "Fence", Size = Vector3.new(0.4, 5, 36), CFrame = CFrame.new(cx + x, WALK + 2.5, -40), Color = Palette.Street.Metal, Material = Enum.Material.DiamondPlate, Parent = area })
	end
	local sign = Builder.part({ Name = "Sign", Size = Vector3.new(16, 3, 0.4), CFrame = facing(Vector3.new(cx, WALK + 9.5, -53), SOUTH), Color = rgb(40, 120, 60), Parent = area })
	Builder.sign(sign, "PUNTO LIMPIO", Enum.NormalId.Front)
	Props.jobBoard(world, facing(Vector3.new(cx + 12, WALK, -24), SOUTH), "Basurero", "BASURERO")

	local bags = Builder.model("TrashBags", world)
	local spots = {
		Vector3.new(-300, 0, 16), Vector3.new(-200, 0, 16), Vector3.new(-100, 0, 16), Vector3.new(120, 0, 16),
		Vector3.new(300, 0, 16), Vector3.new(40, 0, -16), Vector3.new(220, 0, -16), Vector3.new(-250, 0, 104),
		Vector3.new(-60, 0, 136), Vector3.new(90, 0, 104), Vector3.new(260, 0, 136), Vector3.new(16, 0, 200),
		Vector3.new(-16, 0, -70),
	}
	for i, spot in spots do
		Builder.part({
			Name = "TrashBag" .. i, Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = CFrame.new(spot + Vector3.new(0, WALK + 1.1, 0)), Color = rgb(24, 24, 28),
			Material = Enum.Material.Plastic, CanCollide = false, Tags = { "Pickup_Basurero" }, Parent = bags,
		})
	end
end

---------------------------------------------------------------------
-- Parcelas residenciales
---------------------------------------------------------------------

-- Tamaños de las casas de muestra (los mismos que los dos primeros niveles de Config.HouseTiers)
local SHOW_HOUSES = { Vector3.new(24, 12, 20), Vector3.new(32, 14, 28) }

function TownBuilder.showHouse(plot: Instance, origin: CFrame): Model
	local size = SHOW_HOUSES[math.random(1, #SHOW_HOUSES)]
	local model = Building.build({
		Name = "House",
		Parent = plot,
		CFrame = origin * CFrame.new(0, 0, PLOT_SIZE / 2 - size.Z / 2 - 3),
		Width = size.X,
		Depth = size.Z,
		Floors = 1,
		Style = "Casa",
		GroundFloor = "House",
		Interior = false,
	})
	model:SetAttribute("ShowHouse", true)
	return model
end

local function buildPlot(parent: Instance, plotId: number, center: Vector3)
	local cf = facing(center, NORTH) -- todas las casas miran a la calle del norte
	local plot = Builder.model("Plot_" .. plotId, parent)
	plot:SetAttribute("PlotId", plotId)
	plot:SetAttribute("Origin", cf)
	plot:AddTag("Plot")
	local half = PLOT_SIZE / 2

	Builder.part({
		Name = "Lawn", Size = Vector3.new(PLOT_SIZE, 0.3, PLOT_SIZE), CFrame = cf * CFrame.new(0, 0.15, 0),
		Color = Palette.Ground.Lawn, Material = Enum.Material.Grass, Parent = plot,
	})
	-- Camino desde la acera hasta la puerta
	Builder.part({
		Name = "Path", Size = Vector3.new(5, 0.4, 36), CFrame = cf * CFrame.new(0, 0.2, -half - 2),
		Color = rgb(200, 190, 172), Material = Enum.Material.Pavement, Parent = plot,
	})
	-- Setos en los laterales y al fondo
	Nature.hedge(plot, (cf * CFrame.new(-half + 0.8, 0, -half + 4)).Position, (cf * CFrame.new(-half + 0.8, 0, half - 0.8)).Position)
	Nature.hedge(plot, (cf * CFrame.new(half - 0.8, 0, -half + 4)).Position, (cf * CFrame.new(half - 0.8, 0, half - 0.8)).Position)
	Nature.hedge(plot, (cf * CFrame.new(-half + 1.6, 0, half - 0.8)).Position, (cf * CFrame.new(half - 1.6, 0, half - 0.8)).Position)

	-- Buzón (destino del repartidor)
	Builder.part({ Name = "MailboxPost", Size = Vector3.new(0.4, 3.5, 0.4), CFrame = cf * CFrame.new(5, 1.75, -half + 1), Color = Palette.Street.Wood, Parent = plot })
	Builder.part({
		Name = "Mailbox", Size = Vector3.new(1.2, 1.2, 2), CFrame = cf * CFrame.new(5, 4, -half + 1),
		Color = rgb(196, 48, 48), Tags = { "Dropoff_Repartidor" }, Parent = plot,
	})
	-- Cartel de la parcela (reclamar / mejorar casa)
	Builder.part({ Name = "SignPost", Size = Vector3.new(0.4, 4, 0.4), CFrame = cf * CFrame.new(-6, 2, -half + 1), Color = Palette.Street.Wood, Parent = plot })
	local sign = Builder.part({
		Name = "PlotSign", Size = Vector3.new(5, 2.6, 0.3), CFrame = cf * CFrame.new(-6, 4.8, -half + 1),
		Color = rgb(246, 246, 240), Tags = { "PlotSign" }, Attributes = { PlotId = plotId }, Parent = plot,
	})
	local label = Builder.sign(sign, "SE VENDE\nLibre", Enum.NormalId.Front, rgb(30, 30, 30))
	label.Name = "Label"

	-- Casa "en venta" hasta que alguien reclama la parcela (HouseService la sustituye)
	TownBuilder.showHouse(plot, cf)

	-- Jardín
	Nature.tree(plot, (cf * CFrame.new(-half + 6, 0, half - 6)).Position)
	Nature.cypress(plot, (cf * CFrame.new(half - 5, 0, half - 5)).Position)
	for _, x in { -12, 12 } do
		Nature.bush(plot, (cf * CFrame.new(x, 0.3, -half + 5)).Position)
	end
end

local function buildPlots(world: Instance)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = world
	local xs = { -270, -200, -130, -60, 60, 130, 200, 270 }
	local id = 0
	for _, rowZ in { 65, 185 } do
		for _, x in xs do
			id += 1
			buildPlot(plots, id, Vector3.new(x, 0, rowZ))
		end
	end
end

---------------------------------------------------------------------
-- Vida en la calle: coches aparcados y paradas de autobús
---------------------------------------------------------------------

local function buildStreetLife(world: Instance)
	local folder = Builder.model("StreetLife", world)
	local H = Street.HALF
	Street.parkCars(folder, ROADS.Residential, -336, -H - 4, 1, 0.3)
	Street.parkCars(folder, ROADS.Residential, H + 4, 336, 1, 0.3)
	Street.parkCars(folder, ROADS.Residential, -336, -H - 4, -1, 0.2)
	Street.parkCars(folder, ROADS.Residential, H + 4, 336, -1, 0.2)
	Street.parkCars(folder, ROADS.Avenue, -336, -H - 4, 1, 0.25)
	Street.parkCars(folder, ROADS.Avenue, H + 4, 336, 1, 0.25)
	Region.travelStop(folder, facing(Vector3.new(-130, WALK, 17.4), NORTH), "Valmar Centro")
	Props.busStop(folder, facing(Vector3.new(86, WALK, 17.4), NORTH))
end

---------------------------------------------------------------------

local function buildGround(world: Instance)
	-- Solo para verlo en Studio: en el juego se sustituye por terreno real (TerrainBuilder)
	local x0, x1, z0, z1 = -2400, 1640, -2400, 2400
	for i = 0, 2 do
		for j = 0, 2 do
			local w, d = (x1 - x0) / 3, (z1 - z0) / 3
			Builder.part({
				Name = "Ground", Size = Vector3.new(w, 2, d),
				CFrame = CFrame.new(x0 + w * (i + 0.5), -1, z0 + d * (j + 0.5)),
				Color = Palette.Ground.Grass, Material = Enum.Material.Grass, Tags = { "EditOnly" }, Parent = world,
			})
		end
	end
	for j = 0, 2 do
		local d = (z1 - z0) / 3
		Builder.part({
			Name = "Sea", Size = Vector3.new(2400 - x1, 2, d),
			CFrame = CFrame.new((x1 + 2400) / 2, -1.6, z0 + d * (j + 0.5)),
			Color = Color3.fromRGB(46, 120, 170), Material = Enum.Material.Glass, Reflectance = 0.2, Tags = { "EditOnly" }, Parent = world,
		})
	end
end

-- Arboledas en el campo entre ciudades (lejos de calles y manzanas)
local function buildOutskirts(world: Instance)
	local folder = Builder.model("Campo", world)
	local roads = Region.roads()
	table.insert(roads, ROADS.Residential)
	local function blocked(x: number, z: number): boolean
		if math.abs(x) < 380 and z > -220 and z < 240 then
			return true -- Valmar Centro
		end
		for _, town in Region.Towns do
			if math.abs(x - town.Center.X) < 390 and math.abs(z - town.Center.Z) < 390 then
				return true
			end
		end
		for _, road in roads do
			local along, across = if road.Axis == "X" then x else z, if road.Axis == "X" then z else x
			if along >= road.From - 30 and along <= road.To + 30 and math.abs(across - road.At) < 34 then
				return true
			end
		end
		return x > 1600
	end
	-- Grupos de árboles (bosquecillos) en vez de árboles sueltos al azar
	for _ = 1, 70 do
		local cx, cz = math.random(-2200, 1550), math.random(-2200, 2200)
		for _ = 1, math.random(3, 7) do
			local x, z = cx + math.random(-30, 30), cz + math.random(-30, 30)
			if not blocked(x, z) then
				if math.random() < 0.3 then
					Nature.cypress(folder, Vector3.new(x, 0, z))
				else
					Nature.tree(folder, Vector3.new(x, 0, z), 1 + math.random() * 0.5)
				end
			end
		end
	end
end

-- Todas las calles del mapa (las usan el tráfico y los peatones del cliente)
function TownBuilder.roads()
	local roads = Region.roads()
	table.insert(roads, ROADS.Residential)
	return roads
end

function TownBuilder.build(): Folder
	local world = Instance.new("Folder")
	world.Name = "Town"
	-- Recuerda si se construyó con modelos importados (packs de Synty) o solo por código
	world:SetAttribute("BuiltWithAssets", AssetLibrary.has("Tree") or AssetLibrary.has("Lamp") or AssetLibrary.has("Car"))
	world.Parent = workspace

	buildGround(world)
	Street.build(world, TownBuilder.roads()) -- carreteras y calles de todas las ciudades
	buildPlaza(world)
	buildCafe(world)
	buildSupermarket(world)
	buildPostOffice(world)
	buildBurger(world)
	buildFillers(world)
	buildRecycling(world)
	buildPlots(world)
	buildStreetLife(world)
	Region.build(world)
	buildOutskirts(world)

	return world
end

return TownBuilder
