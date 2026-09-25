-- HouseService: parcelas y casas.
--  * Cada jugador puede reclamar UNA parcela libre del servidor (gratis).
--  * El nivel de su casa (Config.HouseTiers) se guarda y se puede mejorar con dinero.
--  * Dentro hay cama (dormir = recuperar energía) y nevera (comida gratis con espera).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local Building = require(script.Parent.Parent.World.Kit.Building)
local TownBuilder = require(script.Parent.Parent.World.TownBuilder)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local HouseService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

type Plot = {
	Id: number,
	Model: Model,
	Origin: CFrame,
	SignLabel: TextLabel,
	Prompt: ProximityPrompt,
	Owner: Player?,
	House: Model?,
}
local plots: { [number]: Plot } = {}

local function plotOf(player: Player): Plot?
	local id = player:GetAttribute("PlotId")
	return if id then plots[id] else nil
end

---------------------------------------------------------------------
-- Construcción de la casa
---------------------------------------------------------------------

local WOOD = Color3.fromRGB(96, 66, 48)

local function furnish(model: Model, at: (number, number, number) -> CFrame, size: Vector3, plotId: number)
	-- "at" usa coordenadas interiores: y = 0 es el suelo, -Z es la fachada (puerta)
	local W, D = size.X, size.Z

	-- DORMITORIO: cama al fondo a la derecha
	local bedCf = at(W / 2 - 4.5, 0, D / 2 - 5.5)
	Builder.part({ Name = "BedFrame", Size = Vector3.new(6, 1.4, 8), CFrame = bedCf * CFrame.new(0, 0.7, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	local mattress = Builder.part({
		Name = "Bed",
		Size = Vector3.new(5.6, 0.8, 7.6),
		CFrame = bedCf * CFrame.new(0, 1.8, 0),
		Color = Color3.fromRGB(238, 238, 242),
		Material = Enum.Material.Fabric,
		Tags = { "Bed" },
		Attributes = { PlotId = plotId },
		Parent = model,
	})
	Builder.decor({ Name = "Blanket", Size = Vector3.new(5.8, 0.3, 4.6), CFrame = bedCf * CFrame.new(0, 2.3, -1.4), Color = Color3.fromRGB(70, 110, 180), Material = Enum.Material.Fabric, Parent = model })
	Builder.decor({ Name = "Pillow", Size = Vector3.new(4, 0.6, 1.6), CFrame = bedCf * CFrame.new(0, 2.5, 2.8), Color = Color3.new(1, 1, 1), Material = Enum.Material.Fabric, Parent = model })
	Builder.part({ Name = "Headboard", Size = Vector3.new(6, 4, 0.5), CFrame = bedCf * CFrame.new(0, 2, 4.1), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	Builder.part({ Name = "Nightstand", Size = Vector3.new(2, 2.2, 2), CFrame = at(W / 2 - 9, 1.1, D / 2 - 2.2), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	local lamp = Builder.decor({ Name = "BedLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = at(W / 2 - 9, 2.9, D / 2 - 2.2), Color = Color3.fromRGB(255, 236, 200), Material = Enum.Material.Neon, Parent = model })
	local lampLight = Instance.new("PointLight")
	lampLight.Range = 10
	lampLight.Brightness = 0.8
	lampLight.Color = Color3.fromRGB(255, 214, 160)
	lampLight.Parent = lamp

	local sleep = Builder.prompt(mattress, "Dormir", "Cama", 0.5)
	sleep.Triggered:Connect(function(player)
		HouseService.sleep(player, plotId)
	end)

	-- COCINA: nevera y encimera al fondo a la izquierda
	Builder.part({ Name = "FridgeBody", Size = Vector3.new(3.2, 7, 3), CFrame = at(-W / 2 + 2.6, 3.5, D / 2 - 2.5), Color = Color3.fromRGB(226, 229, 233), Material = Enum.Material.Metal, Parent = model })
	Builder.part({
		Name = "Fridge",
		Size = Vector3.new(0.3, 1.4, 0.3),
		CFrame = at(-W / 2 + 3.6, 4.2, D / 2 - 4.15),
		Color = Color3.fromRGB(90, 90, 96),
		Tags = { "FoodStand" },
		Attributes = { FoodId = "Nevera", PlotId = plotId },
		Parent = model,
	})
	Builder.part({ Name = "KitchenCounter", Size = Vector3.new(6, 3.6, 2.6), CFrame = at(-W / 2 + 7.4, 1.8, D / 2 - 2.3), Color = Color3.fromRGB(240, 238, 232), Material = Enum.Material.Plaster, Parent = model })
	Builder.decor({ Name = "Worktop", Size = Vector3.new(6.2, 0.3, 2.8), CFrame = at(-W / 2 + 7.4, 3.75, D / 2 - 2.3), Color = Color3.fromRGB(60, 62, 66), Material = Enum.Material.Granite, Parent = model })

	-- SALÓN: sofá mirando a la tele, alfombra y mesa baja
	local sofaCf = at(-W / 2 + 3, 0, -2) * CFrame.Angles(0, math.rad(-90), 0)
	local sofaColor = Color3.fromRGB(116, 128, 140)
	Builder.part({ Name = "SofaSeat", Size = Vector3.new(9, 1.6, 3.4), CFrame = sofaCf * CFrame.new(0, 1, 0), Color = sofaColor, Material = Enum.Material.Fabric, Parent = model })
	Builder.part({ Name = "SofaBack", Size = Vector3.new(9, 3, 1), CFrame = sofaCf * CFrame.new(0, 2.2, 1.6), Color = sofaColor, Material = Enum.Material.Fabric, Parent = model })
	for _, x in { -4.8, 4.8 } do
		Builder.part({ Name = "SofaArm", Size = Vector3.new(0.8, 2.4, 3.4), CFrame = sofaCf * CFrame.new(x, 1.6, 0), Color = sofaColor, Material = Enum.Material.Fabric, Parent = model })
	end
	Builder.decor({ Name = "Rug", Size = Vector3.new(6, 0.1, 8), CFrame = at(-W / 2 + 8.5, 0.05, -2), Color = Color3.fromRGB(176, 88, 68), Material = Enum.Material.Fabric, Parent = model })
	Builder.part({ Name = "CoffeeTable", Size = Vector3.new(2.5, 1.4, 4), CFrame = at(-W / 2 + 8, 0.7, -2), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	Builder.part({ Name = "TVStand", Size = Vector3.new(1.6, 2, 5), CFrame = at(2, 1, -2), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	Builder.decor({ Name = "TV", Size = Vector3.new(0.3, 3, 5), CFrame = at(2, 3.6, -2), Color = Color3.fromRGB(18, 18, 22), Material = Enum.Material.Glass, Parent = model })

	-- Detalles de la cocina: fregadero con grifo, placa, horno, microondas, hervidor y frutero
	local kz = D / 2 - 2.3
	local function kx(x: number): number
		return -W / 2 + x
	end
	Builder.decor({ Name = "Sink", Size = Vector3.new(2, 0.1, 1.6), CFrame = at(kx(8.8), 3.92, kz), Color = Color3.fromRGB(190, 194, 198), Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "Tap", Size = Vector3.new(0.2, 1.2, 0.2), CFrame = at(kx(8.8), 4.5, kz + 0.9), Color = Color3.fromRGB(200, 200, 206), Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "TapSpout", Size = Vector3.new(0.2, 0.2, 0.8), CFrame = at(kx(8.8), 5.05, kz + 0.6), Color = Color3.fromRGB(200, 200, 206), Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "Hob", Size = Vector3.new(2.4, 0.08, 2), CFrame = at(kx(5.6), 3.94, kz), Color = Color3.fromRGB(20, 20, 24), Material = Enum.Material.Glass, Parent = model })
	for _, o in { Vector3.new(-0.6, 0, -0.5), Vector3.new(0.6, 0, -0.5), Vector3.new(-0.6, 0, 0.5), Vector3.new(0.6, 0, 0.5) } do
		Builder.decor({ Name = "Burner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.05, 0.8, 0.8), CFrame = at(kx(5.6) + o.X, 3.99, kz + o.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 60, 66), Parent = model })
	end
	Builder.decor({ Name = "OvenDoor", Size = Vector3.new(2.4, 1.8, 0.1), CFrame = at(kx(5.6), 1.9, kz - 1.35), Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Glass, Parent = model })
	Builder.decor({ Name = "OvenHandle", Size = Vector3.new(2, 0.15, 0.15), CFrame = at(kx(5.6), 3, kz - 1.45), Color = Color3.fromRGB(200, 200, 206), Material = Enum.Material.Metal, Parent = model })
	for _, x in { 7.9, 9.7 } do
		Builder.decor({ Name = "CabinetDoor", Size = Vector3.new(1.6, 2.8, 0.08), CFrame = at(kx(x), 1.8, kz - 1.33), Color = Color3.fromRGB(226, 222, 212), Material = Enum.Material.Wood, Parent = model })
		Builder.decor({ Name = "CabinetKnob", Size = Vector3.new(0.15, 0.6, 0.15), CFrame = at(kx(x) + 0.5, 2.6, kz - 1.42), Color = Color3.fromRGB(120, 120, 126), Material = Enum.Material.Metal, Parent = model })
	end
	Builder.decor({ Name = "Microwave", Size = Vector3.new(1.8, 1.1, 1.3), CFrame = at(kx(10.6), 4.45, kz + 0.4), Color = Color3.fromRGB(230, 230, 232), Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "MicrowaveDoor", Size = Vector3.new(1.1, 0.8, 0.05), CFrame = at(kx(10.4), 4.45, kz - 0.27), Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Glass, Parent = model })
	Builder.decor({ Name = "Kettle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.9, 0.7, 0.7), CFrame = at(kx(7.2), 4.35, kz + 0.5) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 60, 50), Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "FruitBowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.3, 1.3), CFrame = at(kx(9.9), 4.05, kz - 0.5) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(236, 232, 224), Material = Enum.Material.Plastic, Parent = model })
	for k, c in { Color3.fromRGB(220, 50, 40), Color3.fromRGB(250, 190, 40), Color3.fromRGB(110, 170, 60) } do
		Builder.decor({ Name = "Fruit", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), CFrame = at(kx(9.9) + (k - 2) * 0.35, 4.4, kz - 0.5), Color = c, Parent = model })
	end
	Builder.decor({ Name = "FridgeHandle", Size = Vector3.new(0.15, 2.4, 0.15), CFrame = at(-W / 2 + 3.9, 5.6, D / 2 - 4.1), Color = Color3.fromRGB(90, 90, 96), Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "FridgeLine", Size = Vector3.new(3.1, 0.08, 0.05), CFrame = at(-W / 2 + 2.6, 4.9, D / 2 - 4.02), Color = Color3.fromRGB(150, 152, 156), Parent = model })

	-- Salón: cojines, lámpara de pie, revistas, taza, consola y pantalla encendida
	Builder.decor({ Name = "Cushion", Size = Vector3.new(1.8, 1.6, 0.5), CFrame = sofaCf * CFrame.new(-3, 2.4, 0.9) * CFrame.Angles(math.rad(-12), 0, 0), Color = Color3.fromRGB(230, 190, 90), Material = Enum.Material.Fabric, Parent = model })
	Builder.decor({ Name = "Cushion", Size = Vector3.new(1.8, 1.6, 0.5), CFrame = sofaCf * CFrame.new(3, 2.4, 0.9) * CFrame.Angles(math.rad(-12), 0, 0), Color = Color3.fromRGB(236, 236, 230), Material = Enum.Material.Fabric, Parent = model })
	Builder.decor({ Name = "Throw", Size = Vector3.new(2.4, 0.15, 3.2), CFrame = sofaCf * CFrame.new(2.2, 1.86, 0), Color = Color3.fromRGB(150, 60, 60), Material = Enum.Material.Fabric, Parent = model })
	local floorLamp = at(-W / 2 + 2.2, 0, 4.2)
	Builder.decor({ Name = "LampBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1.4, 1.4), CFrame = floorLamp * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 40, 44), Material = Enum.Material.Metal, Parent = model })
	Builder.decor({ Name = "LampPole", Size = Vector3.new(0.15, 5.6, 0.15), CFrame = floorLamp * CFrame.new(0, 2.9, 0), Color = Color3.fromRGB(40, 40, 44), Material = Enum.Material.Metal, Parent = model })
	local shade = Builder.decor({ Name = "LampShade", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.3, 1.6, 1.6), CFrame = floorLamp * CFrame.new(0, 6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(250, 236, 206), Material = Enum.Material.Neon, Parent = model })
	local shadeLight = Instance.new("PointLight")
	shadeLight.Range = 12
	shadeLight.Brightness = 0.7
	shadeLight.Color = Color3.fromRGB(255, 214, 160)
	shadeLight.Parent = shade
	Builder.decor({ Name = "Magazine", Size = Vector3.new(1, 0.08, 1.4), CFrame = at(-W / 2 + 7.8, 1.44, -3) * CFrame.Angles(0, math.rad(15), 0), Color = Color3.fromRGB(200, 60, 90), Parent = model })
	Builder.decor({ Name = "Mug", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.45, 0.45), CFrame = at(-W / 2 + 8.2, 1.65, -0.8) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.Plastic, Parent = model })
	Builder.decor({ Name = "Console", Size = Vector3.new(1, 0.4, 1.8), CFrame = at(2, 2.2, -0.2), Color = Color3.fromRGB(240, 240, 244), Parent = model })
	Builder.decor({ Name = "Screen", Size = Vector3.new(0.05, 2.7, 4.7), CFrame = at(1.83, 3.6, -2), Color = Color3.fromRGB(40, 90, 150), Material = Enum.Material.Neon, Transparency = 0.35, Parent = model })
	Builder.decor({ Name = "Speaker", Size = Vector3.new(0.8, 1.8, 0.8), CFrame = at(2, 2.9, -5.2), Color = Color3.fromRGB(30, 30, 34), Parent = model })
	Builder.decor({ Name = "Speaker", Size = Vector3.new(0.8, 1.8, 0.8), CFrame = at(2, 2.9, 1.2), Color = Color3.fromRGB(30, 30, 34), Parent = model })

	-- Estantería baja con libros junto a la entrada
	local shelf = at(-W / 2 + 4.2, 0, -D / 2 + 1.8)
	Builder.part({ Name = "Bookshelf", Size = Vector3.new(5, 3, 1.6), CFrame = shelf * CFrame.new(0, 1.5, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	local bx = -2.1
	while bx < 2 do
		local bw = 0.25 + math.random() * 0.25
		local bh = 1 + math.random() * 0.5
		Builder.decor({ Name = "Book", Size = Vector3.new(bw, bh, 1), CFrame = shelf * CFrame.new(bx + bw / 2, 3 + bh / 2, 0), Color = Color3.fromHSV(math.random(), 0.5, 0.6), Parent = model })
		bx += bw + 0.05
	end
	Builder.decor({ Name = "PhotoFrame", Size = Vector3.new(1.2, 1, 0.12), CFrame = shelf * CFrame.new(1.4, 1.5 + 1.9, 0.3) * CFrame.Angles(math.rad(-10), 0, 0), Color = Color3.fromRGB(200, 170, 120), Material = Enum.Material.Wood, Parent = model })

	-- Dormitorio: alfombra, libro y cómoda con espejo
	Builder.decor({ Name = "BedRug", Size = Vector3.new(8, 0.08, 5), CFrame = at(W / 2 - 5, 0.05, D / 2 - 10.5), Color = Color3.fromRGB(226, 214, 190), Material = Enum.Material.Fabric, Parent = model })
	Builder.decor({ Name = "Book", Size = Vector3.new(0.9, 0.25, 1.2), CFrame = at(W / 2 - 9, 2.35, D / 2 - 2.4) * CFrame.Angles(0, math.rad(20), 0), Color = Color3.fromRGB(40, 70, 120), Parent = model })
	Builder.decor({ Name = "Slippers", Size = Vector3.new(1.2, 0.25, 1.1), CFrame = at(W / 2 - 8.6, 0.13, D / 2 - 8), Color = Color3.fromRGB(230, 120, 150), Material = Enum.Material.Fabric, Parent = model })

	-- Lámparas de techo (cocina, salón y dormitorio)
	for _, p in { Vector3.new(-W / 2 + 7, 0, D / 2 - 5), Vector3.new(-W / 2 + 7, 0, -3), Vector3.new(W / 2 - 5, 0, D / 2 - 6) } do
		Builder.decor({ Name = "LampCord", Size = Vector3.new(0.08, 1.6, 0.08), CFrame = at(p.X, 9.4, p.Z), Color = Color3.fromRGB(40, 40, 44), Parent = model })
		local bulb = Builder.decor({ Name = "CeilingLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = at(p.X, 8.3, p.Z), Color = Color3.fromRGB(255, 240, 214), Material = Enum.Material.Neon, Parent = model })
		local light = Instance.new("PointLight")
		light.Range = 14
		light.Brightness = 0.6
		light.Color = Color3.fromRGB(255, 226, 180)
		light.Parent = bulb
	end

	-- Las casas más grandes tienen comedor y cómoda
	if W >= 30 then
		local table0 = at(-W / 2 + 10, 0, D / 2 - 10)
		Builder.part({ Name = "DiningTable", Size = Vector3.new(6, 0.3, 3.6), CFrame = table0 * CFrame.new(0, 3, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
		for _, lx in { -2.6, 2.6 } do
			for _, lz in { -1.5, 1.5 } do
				Builder.decor({ Name = "TableLeg", Size = Vector3.new(0.3, 2.85, 0.3), CFrame = table0 * CFrame.new(lx, 1.43, lz), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
			end
		end
		Builder.decor({ Name = "TableRunner", Size = Vector3.new(4.6, 0.05, 1), CFrame = table0 * CFrame.new(0, 3.18, 0), Color = Color3.fromRGB(236, 230, 214), Material = Enum.Material.Fabric, Parent = model })
		Builder.decor({ Name = "Vase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 0.6, 0.6), CFrame = table0 * CFrame.new(0, 3.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 130, 170), Material = Enum.Material.Glass, Parent = model })
		Builder.decor({ Name = "VaseFlowers", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), CFrame = table0 * CFrame.new(0, 4.5, 0), Color = Color3.fromRGB(230, 90, 130), Material = Enum.Material.Grass, Parent = model })
		for _, c in { { -1.5, -2.6, 0 }, { 1.5, -2.6, 0 }, { -1.5, 2.6, 180 }, { 1.5, 2.6, 180 } } do
			local chair = table0 * CFrame.new(c[1], 0, c[2]) * CFrame.Angles(0, math.rad(c[3]), 0)
			Builder.part({ Name = "ChairSeat", Size = Vector3.new(1.8, 0.3, 1.8), CFrame = chair * CFrame.new(0, 1.9, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
			Builder.decor({ Name = "ChairBack", Size = Vector3.new(1.8, 2.2, 0.2), CFrame = chair * CFrame.new(0, 3.1, -0.85), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
			Builder.decor({ Name = "ChairLegs", Size = Vector3.new(1.6, 1.75, 1.6), CFrame = chair * CFrame.new(0, 0.88, 0), Color = WOOD, Material = Enum.Material.Wood, Transparency = 0.6, Parent = model })
		end
		local dresser = at(W / 2 - 1.8, 0, D / 2 - 13)
		Builder.part({ Name = "Dresser", Size = Vector3.new(2.4, 2.8, 5), CFrame = dresser * CFrame.new(0, 1.4, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
		for k = 0, 2 do
			Builder.decor({ Name = "DrawerHandle", Size = Vector3.new(0.12, 0.15, 1.2), CFrame = dresser * CFrame.new(-1.25, 0.6 + k * 0.85, 0), Color = Color3.fromRGB(200, 180, 110), Material = Enum.Material.Metal, Parent = model })
		end
		Builder.decor({ Name = "JewelBox", Size = Vector3.new(0.8, 0.5, 1.2), CFrame = dresser * CFrame.new(0, 3.05, 1.2), Color = Color3.fromRGB(150, 40, 60), Material = Enum.Material.Fabric, Parent = model })
		-- Planta grande en la esquina del comedor
		Builder.part({ Name = "Pot", Size = Vector3.new(1.8, 2, 1.8), CFrame = at(-W / 2 + 2, 1, D / 2 - 7), Color = Color3.fromRGB(236, 232, 224), Material = Enum.Material.Plaster, Parent = model })
		Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 4, 3), CFrame = at(-W / 2 + 2, 4, D / 2 - 7), Color = Color3.fromRGB(60, 120, 60), Material = Enum.Material.LeafyGrass, Parent = model })
	end

	-- Planta junto a la entrada
	Builder.part({ Name = "Pot", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = at(W / 2 - 2, 0.8, -D / 2 + 2), Color = Color3.fromRGB(170, 90, 60), Material = Enum.Material.Plaster, Parent = model })
	Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = at(W / 2 - 2, 2.6, -D / 2 + 2), Color = Color3.fromRGB(70, 124, 58), Material = Enum.Material.LeafyGrass, Parent = model })
end

local function buildHouse(plot: Plot, tier: number)
	if plot.House then
		plot.House:Destroy()
		plot.House = nil
	end
	local info = Config.HouseTiers[tier]
	local size = info.Size
	-- Colocamos la casa hacia el fondo de la parcela (50x50), dejando jardín delante
	local offsetZ = 25 - size.Z / 2 - 3
	local model, at = Building.build({
		Name = "House",
		Parent = plot.Model,
		CFrame = plot.Origin * CFrame.new(0, 0, offsetZ),
		Width = size.X,
		Depth = size.Z,
		Floors = if size.Y >= 16 then 2 else 1,
		Style = "Casa",
		GroundFloor = "House",
		WallColor = info.Color,
		FloorColor = Color3.fromRGB(176, 136, 98),
	})
	furnish(model, at, size, plot.Id)
	plot.House = model
end

local function refreshSign(plot: Plot)
	local owner = plot.Owner
	if not owner then
		plot.SignLabel.Text = "SE VENDE\nLibre"
		plot.Prompt.ActionText = "Reclamar casa"
		plot.Prompt.ObjectText = "Parcela " .. plot.Id .. " · Gratis"
		return
	end
	local data = DataService.get(owner)
	local tier = if data then data.HouseTier else 1
	local nextTier = Config.HouseTiers[tier + 1]
	plot.SignLabel.Text = ("%s\n%s"):format(owner.DisplayName, Config.HouseTiers[tier].Name)
	if nextTier then
		plot.Prompt.ActionText = "Mejorar a " .. nextTier.Name
		plot.Prompt.ObjectText = Format.money(nextTier.Price)
	else
		plot.Prompt.ActionText = "Casa al máximo"
		plot.Prompt.ObjectText = Config.HouseTiers[tier].Name
	end
end

---------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------

function HouseService.claim(player: Player, plot: Plot)
	local data = DataService.get(player)
	if not data then
		return
	end
	if plotOf(player) then
		Notify:FireClient(player, "Error", "Ya tienes una casa en este servidor.")
		return
	end
	if not LifeService.allows(player, "ClaimHome") then
		return
	end
	plot.Owner = player
	player:SetAttribute("PlotId", plot.Id)
	buildHouse(plot, data.HouseTier)
	refreshSign(plot)
	Notify:FireClient(player, "Success", "¡Bienvenido a tu nueva casa! Pulsa 'Casa' para volver cuando quieras.")
	StoryEvents.emit(player, "HomeClaimed", { PlotId = plot.Id })
end

function HouseService.upgrade(player: Player, plot: Plot)
	local data = DataService.get(player)
	if not data then
		return
	end
	local nextTier = Config.HouseTiers[data.HouseTier + 1]
	if not nextTier then
		Notify:FireClient(player, "Info", "Tu casa ya es la mejor de la ciudad.")
		return
	end
	if not DataService.spend(player, nextTier.Price) then
		Notify:FireClient(player, "Error", ("Necesitas %s para mejorar tu casa."):format(Format.money(nextTier.Price)))
		return
	end
	data.HouseTier += 1
	buildHouse(plot, data.HouseTier)
	refreshSign(plot)
	Notify:FireClient(player, "Success", ("¡Enhorabuena! Ahora vives en: %s"):format(nextTier.Name))
end

function HouseService.release(player: Player)
	local plot = plotOf(player)
	if not plot then
		return
	end
	if plot.House then
		plot.House:Destroy()
	end
	plot.House = TownBuilder.showHouse(plot.Model, plot.Origin)
	plot.Owner = nil
	player:SetAttribute("PlotId", nil)
	refreshSign(plot)
end

function HouseService.sleep(player: Player, plotId: number)
	if player:GetAttribute("PlotId") ~= plotId then
		Notify:FireClient(player, "Error", "Esta cama no es tuya.")
		return
	end
	if player:GetAttribute("Sleeping") then
		return
	end
	player:SetAttribute("Sleeping", true)
	Notify:FireClient(player, "Sleep", "Zzz...")
	task.wait(Config.SleepSeconds * 0.6)
	-- De noche, si todos duermen, se hace de día
	require(script.Parent.WorldService).trySkipNight()
	task.wait(Config.SleepSeconds * 0.4)
	if player.Parent then
		player:SetAttribute("Sleeping", nil)
		NeedsService.change(player, 0, Config.Needs.Max)
		Notify:FireClient(player, "Success", "Has dormido genial. ¡Energía al máximo!")
		StoryEvents.emit(player, "Slept", {})
	end
end

function HouseService.goHome(player: Player)
	local plot = plotOf(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not plot then
		Notify:FireClient(player, "Error", "Aún no tienes casa. Busca un cartel de SE VENDE en la zona residencial.")
		return
	end
	if root then
		player.Character:PivotTo(plot.Origin * CFrame.new(0, 4, -23.5) * CFrame.Angles(0, math.pi, 0))
	end
end

---------------------------------------------------------------------

function HouseService.init()
	for _, model in CollectionService:GetTagged("Plot") do
		local id = model:GetAttribute("PlotId")
		local sign = model:FindFirstChild("PlotSign") :: BasePart
		local label = sign:FindFirstChild("Label", true) :: TextLabel
		local prompt = Builder.prompt(sign, "Reclamar casa", "", 0.5)
		local plot: Plot = {
			Id = id,
			Model = model,
			Origin = model:GetAttribute("Origin"),
			SignLabel = label,
			Prompt = prompt,
			House = model:FindFirstChild("House") :: Model?, -- casa de muestra "en venta"
		}
		plots[id] = plot
		refreshSign(plot)

		prompt.Triggered:Connect(function(player)
			if plot.Owner == nil then
				HouseService.claim(player, plot)
			elseif plot.Owner == player then
				HouseService.upgrade(player, plot)
			else
				Notify:FireClient(player, "Info", ("Esta es la casa de %s."):format(plot.Owner.DisplayName))
			end
		end)
	end

	local GoHome = ReplicatedStorage.Remotes.GoHome :: RemoteEvent
	GoHome.OnServerEvent:Connect(HouseService.goHome)

	Players.PlayerRemoving:Connect(HouseService.release)
end

return HouseService
