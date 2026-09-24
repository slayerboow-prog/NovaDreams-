-- TownBuilder: construye la ciudad de Real Life Simulator al arrancar el servidor.
--
-- Mapa (vista desde arriba, el norte es -Z):
--
--          Punto Limpio   Hamburguesería   PLAZA   |   Cafetería   Supermercado   Correos
--   ================================ AVENIDA (z = 0) ===============================
--          Casas 1-8 (fila 1)                       |
--   ================================ CALLE (z = 120) ===============================
--          Casas 9-16 (fila 2)                      |
--                                            CALLE (x = 0)
--
-- Todo lo que el resto del código necesita se marca con tags (CollectionService):
--   JobBoard (+JobId), Pickup_<Trabajo>, Dropoff_<Trabajo>, FoodStand (+FoodId),
--   StreetLamp, Plot (+PlotId), PlotSign (+PlotId)

local Builder = require(script.Parent.Builder)

local TownBuilder = {}

local ROAD_WIDTH = 24
local PLOT_SIZE = 50

local Colors = {
	Grass = Color3.fromRGB(96, 150, 72),
	Asphalt = Color3.fromRGB(45, 47, 52),
	Sidewalk = Color3.fromRGB(175, 172, 165),
	Line = Color3.fromRGB(240, 240, 235),
	Wood = Color3.fromRGB(120, 85, 55),
	DarkWood = Color3.fromRGB(80, 55, 40),
	Metal = Color3.fromRGB(90, 95, 105),
	Leaves = Color3.fromRGB(62, 120, 58),
}

local function facing(position: Vector3, direction: Vector3): CFrame
	return CFrame.lookAt(position, position + direction)
end
local NORTH = Vector3.new(0, 0, -1)
local SOUTH = Vector3.new(0, 0, 1)

---------------------------------------------------------------------
-- Elementos pequeños
---------------------------------------------------------------------

local function tree(parent: Instance, position: Vector3)
	local m = Builder.model("Tree", parent)
	local height = 10 + math.random() * 6
	Builder.part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.6, 1.6),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Colors.Wood,
		Material = Enum.Material.Wood,
		Parent = m,
	})
	local crown = 9 + math.random() * 4
	Builder.part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(crown, crown, crown),
		CFrame = CFrame.new(position + Vector3.new(0, height + crown * 0.25, 0)),
		Color = Colors.Leaves:Lerp(Color3.fromRGB(90, 140, 60), math.random()),
		Material = Enum.Material.Grass,
		Parent = m,
	})
end

local function streetLamp(parent: Instance, position: Vector3)
	local m = Builder.model("StreetLamp", parent)
	Builder.part({
		Name = "Pole",
		Size = Vector3.new(0.6, 14, 0.6),
		CFrame = CFrame.new(position + Vector3.new(0, 7, 0)),
		Color = Colors.Metal,
		Material = Enum.Material.Metal,
		Parent = m,
	})
	local bulb = Builder.part({
		Name = "Bulb",
		Size = Vector3.new(1.6, 0.8, 1.6),
		CFrame = CFrame.new(position + Vector3.new(0, 14.2, 0)),
		Color = Color3.fromRGB(255, 230, 170),
		Material = Enum.Material.SmoothPlastic,
		Tags = { "StreetLamp" },
		Parent = m,
	})
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 1.5
	light.Color = Color3.fromRGB(255, 214, 150)
	light.Enabled = false
	light.Parent = bulb
end

local function bench(parent: Instance, cf: CFrame)
	local m = Builder.model("Bench", parent)
	Builder.part({ Name = "Seat", Size = Vector3.new(6, 0.5, 2), CFrame = cf * CFrame.new(0, 1.8, 0), Color = Colors.Wood, Material = Enum.Material.Wood, Parent = m })
	Builder.part({ Name = "Back", Size = Vector3.new(6, 2, 0.4), CFrame = cf * CFrame.new(0, 3, 0.9), Color = Colors.Wood, Material = Enum.Material.Wood, Parent = m })
	for _, x in { -2.5, 2.5 } do
		Builder.part({ Name = "Leg", Size = Vector3.new(0.4, 1.6, 1.8), CFrame = cf * CFrame.new(x, 0.8, 0), Color = Colors.Metal, Parent = m })
	end
end

local function jobBoard(parent: Instance, cf: CFrame, jobId: string, title: string)
	local m = Builder.model("JobBoard_" .. jobId, parent)
	Builder.part({ Name = "Post", Size = Vector3.new(0.5, 4, 0.5), CFrame = cf * CFrame.new(0, 2, 0), Color = Colors.Metal, Parent = m })
	local board = Builder.part({
		Name = "Board",
		Size = Vector3.new(4.5, 3, 0.3),
		CFrame = cf * CFrame.new(0, 5, 0),
		Color = Color3.fromRGB(40, 110, 200),
		Tags = { "JobBoard" },
		Attributes = { JobId = jobId },
		Parent = m,
	})
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Front)
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Back)
end

-- Mostrador de venta. El FoodId debe existir en Config.Foods.
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

---------------------------------------------------------------------
-- Terreno y calles
---------------------------------------------------------------------

local function buildGround(world: Instance)
	Builder.part({
		Name = "Ground",
		Size = Vector3.new(900, 2, 900),
		CFrame = CFrame.new(0, -1, 0),
		Color = Colors.Grass,
		Material = Enum.Material.Grass,
		Parent = world,
	})
end

local function road(parent: Instance, from: Vector3, to: Vector3, lampStart: number)
	local length = (to - from).Magnitude
	local cf = CFrame.lookAt((from + to) / 2, to)
	-- Acera
	Builder.part({
		Name = "Sidewalk",
		Size = Vector3.new(ROAD_WIDTH + 8, 0.4, length + 8),
		CFrame = cf * CFrame.new(0, 0.2, 0),
		Color = Colors.Sidewalk,
		Material = Enum.Material.Concrete,
		Parent = parent,
	})
	-- Asfalto
	Builder.part({
		Name = "Road",
		Size = Vector3.new(ROAD_WIDTH, 0.4, length),
		CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = Colors.Asphalt,
		Material = Enum.Material.Asphalt,
		Parent = parent,
	})
	-- Línea discontinua central
	local step = 12
	for d = -length / 2 + step / 2, length / 2 - step / 2, step do
		Builder.part({
			Name = "Line",
			Size = Vector3.new(0.5, 0.05, 5),
			CFrame = cf * CFrame.new(0, 0.52, d),
			Color = Colors.Line,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = parent,
		})
	end
	-- Farolas a ambos lados
	for d = -length / 2 + lampStart, length / 2 - 20, 60 do
		for _, side in { -1, 1 } do
			local pos = cf * CFrame.new(side * (ROAD_WIDTH / 2 + 2.5), 0.4, d)
			streetLamp(parent, pos.Position)
		end
	end
end

local function buildRoads(world: Instance)
	local roads = Builder.model("Roads", world)
	road(roads, Vector3.new(-340, 0, 0), Vector3.new(340, 0, 0), 20) -- Avenida principal
	road(roads, Vector3.new(-340, 0, 120), Vector3.new(340, 0, 120), 20) -- Calle residencial
	road(roads, Vector3.new(0, 0, -140), Vector3.new(0, 0, 260), 50) -- Calle norte-sur (farolas fuera de los cruces)
end

---------------------------------------------------------------------
-- Plaza central (punto de aparición)
---------------------------------------------------------------------

local function buildPlaza(world: Instance)
	local plaza = Builder.model("Plaza", world)
	local center = Vector3.new(-60, 0, -55)

	Builder.part({
		Name = "PlazaFloor",
		Size = Vector3.new(60, 0.4, 60),
		CFrame = CFrame.new(center + Vector3.new(0, 0.2, 0)),
		Color = Color3.fromRGB(205, 195, 180),
		Material = Enum.Material.Pavement,
		Parent = plaza,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 0.4, 12)
	spawn.CFrame = CFrame.new(center + Vector3.new(0, 0.5, 18))
	spawn.Color = Color3.fromRGB(205, 195, 180)
	spawn.Material = Enum.Material.Pavement
	spawn.Transparency = 0
	spawn.Duration = 0 -- sin campo de fuerza
	spawn.Neutral = true
	spawn.Parent = plaza
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	-- Fuente
	Builder.part({
		Name = "FountainBase",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 18, 18),
		CFrame = CFrame.new(center + Vector3.new(0, 1, -5)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(220, 220, 215),
		Material = Enum.Material.Marble,
		Parent = plaza,
	})
	Builder.part({
		Name = "FountainWater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 16, 16),
		CFrame = CFrame.new(center + Vector3.new(0, 2, -5)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(80, 160, 220),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		CanCollide = false,
		Parent = plaza,
	})
	Builder.part({
		Name = "FountainPillar",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 2, 2),
		CFrame = CFrame.new(center + Vector3.new(0, 4, -5)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(220, 220, 215),
		Material = Enum.Material.Marble,
		Parent = plaza,
	})

	-- Cartel de bienvenida
	local welcome = Builder.part({
		Name = "WelcomeSign",
		Size = Vector3.new(20, 5, 0.6),
		CFrame = facing(center + Vector3.new(0, 9, 28), NORTH),
		Color = Color3.fromRGB(30, 34, 46),
		Parent = plaza,
	})
	Builder.sign(welcome, "Bienvenido a VALMAR", Enum.NormalId.Front)
	Builder.sign(welcome, "Bienvenido a VALMAR", Enum.NormalId.Back)
	for _, x in { -9, 9 } do
		Builder.part({ Name = "SignPost", Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(center + Vector3.new(x, 4.5, 28)), Color = Colors.Metal, Parent = plaza })
	end

	for _, offset in { Vector3.new(-18, 0, -5), Vector3.new(18, 0, -5) } do
		bench(plaza, facing(center + offset, if offset.X < 0 then Vector3.new(1, 0, 0) else Vector3.new(-1, 0, 0)))
	end
	for _, offset in { Vector3.new(-25, 0, -25), Vector3.new(25, 0, -25), Vector3.new(-25, 0, 25), Vector3.new(25, 0, 25) } do
		tree(plaza, center + offset)
	end
end

---------------------------------------------------------------------
-- Negocios
---------------------------------------------------------------------

local function table4(parent: Instance, cf: CFrame, tag: string?)
	local m = Builder.model("Table", parent)
	Builder.part({
		Name = "Top",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 5, 5),
		CFrame = cf * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Colors.DarkWood,
		Material = Enum.Material.Wood,
		Tags = if tag then { tag } else nil,
		Parent = m,
	})
	Builder.part({ Name = "Leg", Size = Vector3.new(0.6, 2.8, 0.6), CFrame = cf * CFrame.new(0, 1.6, 0), Color = Colors.Metal, Parent = m })
	for _, dir in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0) } do
		Builder.part({ Name = "Chair", Size = Vector3.new(2, 2, 2), CFrame = cf * CFrame.new(dir * 3.8) * CFrame.new(0, 1.2, 0), Color = Color3.fromRGB(170, 60, 50), Parent = m })
	end
end

local function counter(parent: Instance, cf: CFrame, width: number, color: Color3)
	Builder.part({ Name = "Counter", Size = Vector3.new(width, 3.6, 3), CFrame = cf * CFrame.new(0, 1.8, 0), Color = color, Parent = parent })
	Builder.part({ Name = "CounterTop", Size = Vector3.new(width + 0.4, 0.3, 3.4), CFrame = cf * CFrame.new(0, 3.75, 0), Color = Color3.fromRGB(235, 235, 235), Material = Enum.Material.Marble, Parent = parent })
end

local function buildCafe(world: Instance)
	local pos = Vector3.new(70, 0, -55)
	local model, at = Builder.building({
		Name = "Cafeteria",
		Parent = world,
		CFrame = facing(pos, SOUTH),
		Size = Vector3.new(44, 14, 34),
		WallColor = Color3.fromRGB(230, 205, 170),
		WallMaterial = Enum.Material.Brick,
		RoofColor = Color3.fromRGB(110, 70, 45),
		Sign = "CAFETERÍA CENTRAL",
		SignColor = Color3.fromRGB(110, 70, 45),
	})
	counter(model, at(0, 0.4, 9), 26, Color3.fromRGB(110, 70, 45))
	Builder.part({
		Name = "CoffeeMachine",
		Size = Vector3.new(3, 3, 2),
		CFrame = at(-9, 5.6, 9),
		Color = Color3.fromRGB(60, 60, 65),
		Material = Enum.Material.Metal,
		Tags = { "Pickup_Barista" },
		Parent = model,
	})
	foodStand(model, at(4, 4.5, 8.5), "Cafe", Color3.fromRGB(110, 70, 45))
	foodStand(model, at(9, 4.5, 8.5), "Croissant", Color3.fromRGB(220, 170, 90))
	for _, p in { { -12, -8 }, { 0, -8 }, { 12, -8 }, { -12, 1 }, { 12, 1 } } do
		table4(model, at(p[1], 0.4, p[2]), "Dropoff_Barista")
	end
	jobBoard(world, at(8, 0, -20), "Barista", "BARISTA")
end

local function buildSupermarket(world: Instance)
	local pos = Vector3.new(160, 0, -62)
	local model, at = Builder.building({
		Name = "Supermercado",
		Parent = world,
		CFrame = facing(pos, SOUTH),
		Size = Vector3.new(60, 16, 48),
		WallColor = Color3.fromRGB(235, 235, 235),
		RoofColor = Color3.fromRGB(40, 140, 80),
		FloorColor = Color3.fromRGB(220, 220, 220),
		FloorMaterial = Enum.Material.Marble,
		Sign = "SUPERMERCADO",
		SignColor = Color3.fromRGB(40, 140, 80),
		LightColor = Color3.fromRGB(240, 250, 255),
	})
	-- Estanterías (destino del reponedor)
	for i, x in { -20, -8, 4 } do
		for j, z in { -6, 8 } do
			local shelf = Builder.part({
				Name = "Shelf" .. i .. j,
				Size = Vector3.new(3, 7, 10),
				CFrame = at(x, 3.9, z),
				Color = Color3.fromRGB(200, 200, 205),
				Material = Enum.Material.Metal,
				Tags = { "Dropoff_Reponedor" },
				Parent = model,
			})
			-- Productos de colores para que parezca lleno
			for k = 0, 2 do
				Builder.part({
					Name = "Products",
					Size = Vector3.new(3.4, 1, 9),
					CFrame = shelf.CFrame * CFrame.new(0, -2 + k * 2.2, 0),
					Color = Color3.fromHSV(math.random(), 0.6, 0.9),
					CanCollide = false,
					Parent = model,
				})
			end
		end
	end
	-- Almacén (origen de las cajas)
	for _, x in { 20, 25 } do
		Builder.part({
			Name = "StockBoxes",
			Size = Vector3.new(4, 4, 4),
			CFrame = at(x, 2.4, 18),
			Color = Color3.fromRGB(190, 150, 90),
			Material = Enum.Material.Cardboard,
			Tags = { "Pickup_Reponedor" },
			Parent = model,
		})
	end
	-- Caja registradora
	counter(model, at(20, 0.4, -12), 10, Color3.fromRGB(40, 140, 80))
	foodStand(model, at(17, 4.5, -12), "Fruta", Color3.fromRGB(230, 60, 60))
	foodStand(model, at(22, 4.5, -12), "Bocadillo", Color3.fromRGB(230, 190, 120))
	jobBoard(world, at(10, 0, -28), "Reponedor", "REPONEDOR")
end

local function buildPostOffice(world: Instance)
	local pos = Vector3.new(255, 0, -55)
	local model, at = Builder.building({
		Name = "Correos",
		Parent = world,
		CFrame = facing(pos, SOUTH),
		Size = Vector3.new(40, 14, 30),
		WallColor = Color3.fromRGB(245, 210, 60),
		RoofColor = Color3.fromRGB(30, 60, 140),
		Sign = "CORREOS",
		SignColor = Color3.fromRGB(30, 60, 140),
	})
	counter(model, at(0, 0.4, 2), 20, Color3.fromRGB(30, 60, 140))
	Builder.part({
		Name = "Parcels",
		Size = Vector3.new(10, 5, 4),
		CFrame = at(0, 2.9, 11),
		Color = Color3.fromRGB(170, 120, 70),
		Material = Enum.Material.Cardboard,
		Tags = { "Pickup_Repartidor" },
		Parent = model,
	})
	jobBoard(world, at(8, 0, -18), "Repartidor", "REPARTIDOR")
end

local function buildBurger(world: Instance)
	local pos = Vector3.new(-150, 0, -55)
	local model, at = Builder.building({
		Name = "Hamburgueseria",
		Parent = world,
		CFrame = facing(pos, SOUTH),
		Size = Vector3.new(40, 14, 32),
		WallColor = Color3.fromRGB(200, 50, 45),
		RoofColor = Color3.fromRGB(245, 190, 40),
		Sign = "MEGA BURGER",
		SignColor = Color3.fromRGB(245, 190, 40),
	})
	counter(model, at(0, 0.4, 9), 22, Color3.fromRGB(245, 190, 40))
	foodStand(model, at(-4, 4.5, 8.5), "Hamburguesa", Color3.fromRGB(170, 100, 50))
	foodStand(model, at(4, 4.5, 8.5), "Menu", Color3.fromRGB(230, 60, 50))
	for _, p in { { -10, -6 }, { 10, -6 }, { 0, -2 } } do
		table4(model, at(p[1], 0.4, p[2]), nil)
	end
end

local function buildRecycling(world: Instance)
	local center = Vector3.new(-240, 0, -55)
	local area = Builder.model("PuntoLimpio", world)
	Builder.part({
		Name = "Yard",
		Size = Vector3.new(40, 0.4, 36),
		CFrame = CFrame.new(center + Vector3.new(0, 0.2, 0)),
		Color = Color3.fromRGB(120, 120, 115),
		Material = Enum.Material.Concrete,
		Parent = area,
	})
	for i, x in { -10, 0, 10 } do
		Builder.part({
			Name = "Container" .. i,
			Size = Vector3.new(8, 6, 5),
			CFrame = CFrame.new(center + Vector3.new(x, 3.4, -8)),
			Color = ({ Color3.fromRGB(40, 120, 60), Color3.fromRGB(40, 80, 160), Color3.fromRGB(220, 180, 40) })[i],
			Material = Enum.Material.Metal,
			Tags = { "Dropoff_Basurero" },
			Parent = area,
		})
	end
	local sign = Builder.part({
		Name = "Sign",
		Size = Vector3.new(16, 3, 0.4),
		CFrame = facing(center + Vector3.new(0, 9, -11), SOUTH),
		Color = Color3.fromRGB(40, 120, 60),
		Parent = area,
	})
	Builder.sign(sign, "PUNTO LIMPIO", Enum.NormalId.Front)
	jobBoard(world, facing(center + Vector3.new(8, 0, 14), SOUTH), "Basurero", "BASURERO")

	-- Bolsas de basura repartidas por la ciudad (origen del basurero)
	local bags = Builder.model("TrashBags", world)
	local spots = {
		Vector3.new(-300, 0, 18), Vector3.new(-200, 0, -18), Vector3.new(-100, 0, 18),
		Vector3.new(40, 0, -18), Vector3.new(120, 0, 18), Vector3.new(220, 0, -18),
		Vector3.new(300, 0, 18), Vector3.new(-250, 0, 102), Vector3.new(-60, 0, 138),
		Vector3.new(90, 0, 102), Vector3.new(260, 0, 138), Vector3.new(18, 0, 200),
		Vector3.new(-18, 0, -110),
	}
	for i, spot in spots do
		Builder.part({
			Name = "TrashBag" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.4, 2.4, 2.4),
			CFrame = CFrame.new(spot + Vector3.new(0, 1.6, 0)),
			Color = Color3.fromRGB(25, 25, 28),
			Material = Enum.Material.Plastic,
			CanCollide = false,
			Tags = { "Pickup_Basurero" },
			Parent = bags,
		})
	end
end

---------------------------------------------------------------------
-- Parcelas residenciales
---------------------------------------------------------------------

local function buildPlot(parent: Instance, plotId: number, center: Vector3)
	local cf = facing(center, NORTH) -- todas las casas miran a la calle del norte
	local plot = Builder.model("Plot_" .. plotId, parent)
	plot:SetAttribute("PlotId", plotId)
	plot:SetAttribute("Origin", cf)
	plot:AddTag("Plot")

	Builder.part({
		Name = "Lawn",
		Size = Vector3.new(PLOT_SIZE, 0.3, PLOT_SIZE),
		CFrame = cf * CFrame.new(0, 0.15, 0),
		Color = Color3.fromRGB(110, 165, 80),
		Material = Enum.Material.Grass,
		Parent = plot,
	})
	-- Camino hasta la acera
	Builder.part({
		Name = "Path",
		Size = Vector3.new(5, 0.35, 14),
		CFrame = cf * CFrame.new(0, 0.2, -PLOT_SIZE / 2 + 2),
		Color = Colors.Sidewalk,
		Material = Enum.Material.Concrete,
		Parent = plot,
	})
	-- Buzón (destino del repartidor)
	Builder.part({ Name = "MailboxPost", Size = Vector3.new(0.4, 3.5, 0.4), CFrame = cf * CFrame.new(5, 1.75, -PLOT_SIZE / 2 + 1), Color = Colors.Wood, Parent = plot })
	Builder.part({
		Name = "Mailbox",
		Size = Vector3.new(1.2, 1.2, 2),
		CFrame = cf * CFrame.new(5, 4, -PLOT_SIZE / 2 + 1),
		Color = Color3.fromRGB(200, 50, 50),
		Tags = { "Dropoff_Repartidor" },
		Parent = plot,
	})
	-- Cartel de la parcela (reclamar / mejorar casa)
	Builder.part({ Name = "SignPost", Size = Vector3.new(0.4, 4, 0.4), CFrame = cf * CFrame.new(-6, 2, -PLOT_SIZE / 2 + 1), Color = Colors.Wood, Parent = plot })
	local sign = Builder.part({
		Name = "PlotSign",
		Size = Vector3.new(5, 2.6, 0.3),
		CFrame = cf * CFrame.new(-6, 4.8, -PLOT_SIZE / 2 + 1),
		Color = Color3.fromRGB(245, 245, 240),
		Tags = { "PlotSign" },
		Attributes = { PlotId = plotId },
		Parent = plot,
	})
	local label = Builder.sign(sign, "SE VENDE\nLibre", Enum.NormalId.Front, Color3.fromRGB(30, 30, 30))
	label.Name = "Label"

	-- Árboles en el jardín trasero
	tree(plot, (cf * CFrame.new(-PLOT_SIZE / 2 + 4, 0, PLOT_SIZE / 2 - 4)).Position)
	tree(plot, (cf * CFrame.new(PLOT_SIZE / 2 - 4, 0, PLOT_SIZE / 2 - 4)).Position)
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

function TownBuilder.build(): Folder
	local world = Instance.new("Folder")
	world.Name = "Town"
	world.Parent = workspace

	buildGround(world)
	buildRoads(world)
	buildPlaza(world)
	buildCafe(world)
	buildSupermarket(world)
	buildPostOffice(world)
	buildBurger(world)
	buildRecycling(world)
	buildPlots(world)

	-- Unos cuantos árboles por las afueras
	for _ = 1, 40 do
		local x = math.random(-420, 420)
		local z = math.random(-420, 420)
		if math.abs(x) > 25 and (math.abs(z) > 250 or z < -110) then
			tree(world, Vector3.new(x, 0, z))
		end
	end

	return world
end

return TownBuilder
