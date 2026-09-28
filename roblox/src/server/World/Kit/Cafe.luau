-- Cafe: la barra de una cafetería de verdad, lista para el oficio de barista (CafeService).
--
--   Cafe.build(model, at, W, D)
--     model = el edificio (Building.build); at(x, y, z) = CFrame dentro (y = 0 suelo, -Z = fachada)
--
-- Barra de servicio con caja registradora (CafeRegister: aquí se pide) y zona de recogida
-- (CafePickup: aquí se entrega). Detrás, la encimera de trabajo con los puestos (CafeStation +
-- atributo Station): molinillo, cafetera espresso con vaporizador, nevera de la leche, olla de
-- chocolate, exprimidor, hervidor, tazas y la vitrina de bollería.
-- En el modelo quedan los puntos que usan los clientes NPC (atributos Vector3):
--   Outside, Door, Queue1..Queue4 (cola de la caja), Wait (esperando su pedido) y Staff (barista NPC).

local Builder = require(script.Parent.Parent.Builder)

local Cafe = {}

local rgb = Color3.fromRGB
local WOOD = rgb(96, 60, 38)
local DARK = rgb(34, 34, 38)
local STEEL = rgb(200, 202, 208)
local MARBLE = rgb(236, 234, 228)

function Cafe.build(model: Model, at: (number, number, number) -> CFrame, _W: number, D: number)
	local function solid(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
		local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = model }
		for k, v in extra or {} do
			props[k] = v
		end
		return Builder.part(props)
	end
	local function bit(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
		return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = model })
	end
	local function cyl(name: string, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
		return Builder.decor({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = model })
	end
	local function upright(x: number, y: number, z: number): CFrame
		return at(x, y, z) * CFrame.Angles(0, 0, math.rad(90))
	end
	local function station(id: string, size: Vector3, cf: CFrame)
		-- Pieza invisible que marca el puesto (el cartel sale aquí)
		Builder.part({ Name = "Station_" .. id, Size = size, CFrame = cf, Transparency = 1, CanCollide = false, Tags = { "CafeStation" }, Attributes = { Station = id }, Parent = model })
	end

	local TOP = 3.9 -- altura de las encimeras
	local frontZ, backZ = 9, D / 2 - 2.2

	---------------------------------------------------------------------
	-- Barra de servicio (delante) con caja y recogida
	---------------------------------------------------------------------
	local x0, x1 = -15, 5
	local cx, width = (x0 + x1) / 2, x1 - x0
	solid("Counter", Vector3.new(width, 3.6, 3), at(cx, 1.8, frontZ), WOOD, Enum.Material.WoodPlanks)
	solid("CounterTop", Vector3.new(width + 0.4, 0.3, 3.4), at(cx, 3.75, frontZ), MARBLE, Enum.Material.Marble)
	bit("CounterKick", Vector3.new(width, 0.5, 0.2), at(cx, 0.25, frontZ - 1.55), DARK)
	for k = 0, 5 do
		-- Listones verticales del frontal
		bit("CounterSlat", Vector3.new(0.25, 3, 0.1), at(x0 + 1.5 + k * (width - 3) / 5, 1.9, frontZ - 1.55), rgb(80, 50, 30), Enum.Material.Wood)
	end
	-- Caja registradora con pantalla, datáfono y bote de propinas
	local reg = at(1.5, TOP, frontZ)
	solid("Register", Vector3.new(2.2, 0.8, 1.6), reg * CFrame.new(0, 0.4, 0.3), DARK, Enum.Material.SmoothPlastic, { Tags = { "CafeRegister" } })
	bit("RegisterScreen", Vector3.new(1.8, 1.2, 0.1), reg * CFrame.new(0, 1.5, 0.4) * CFrame.Angles(math.rad(-15), 0, 0), rgb(60, 170, 220), Enum.Material.Neon)
	bit("CardReader", Vector3.new(0.5, 0.15, 0.8), reg * CFrame.new(1.6, 0.08, -0.5), DARK)
	cyl("TipJar", 0.9, 0.7, reg * CFrame.new(-1.8, 0.45, -0.8) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 230, 240), Enum.Material.Glass)
	bit("TipSign", Vector3.new(0.7, 0.3, 0.05), reg * CFrame.new(-1.8, 0.6, -1.16), rgb(250, 240, 200))
	-- Zona de recogida con su cartel
	local pick = at(-11, TOP, frontZ)
	solid("Pickup", Vector3.new(4, 0.1, 2.6), pick * CFrame.new(0, 0.05, 0), rgb(220, 214, 200), Enum.Material.Wood, { Tags = { "CafePickup" } })
	bit("PickupSignPost", Vector3.new(0.12, 1.6, 0.12), pick * CFrame.new(1.8, 0.8, -0.9), DARK, Enum.Material.Metal)
	local pickSign = bit("PickupSign", Vector3.new(2.4, 0.7, 0.1), pick * CFrame.new(1.8, 1.8, -0.9), rgb(250, 240, 210))
	Builder.sign(pickSign, "RECOGIDA", Enum.NormalId.Front, WOOD)
	-- Servilleteros y azucareros
	for _, x in { -6, -2 } do
		bit("Napkins", Vector3.new(0.7, 0.6, 0.5), at(x, TOP + 0.3, frontZ - 0.8), STEEL, Enum.Material.Metal)
		cyl("Sugar", 0.7, 0.45, upright(x + 0.8, TOP + 0.35, frontZ - 0.8), rgb(240, 240, 240), Enum.Material.Glass)
	end
	-- Pila de tazas (lado del barista)
	local cups = at(-3.5, TOP, frontZ + 0.6)
	for k = 0, 3 do
		cyl("CupStack", 0.35, 0.8, cups * CFrame.new(0, 0.2 + k * 0.36, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(250, 250, 250))
	end
	for k = 0, 2 do
		cyl("CupStack", 0.35, 0.8, cups * CFrame.new(1, 0.2 + k * 0.36, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(250, 250, 250))
	end
	station("Cup", Vector3.new(2.4, 1.6, 1.4), cups * CFrame.new(0.5, 0.8, 0))

	---------------------------------------------------------------------
	-- Vitrina de bollería (al lado de la barra)
	---------------------------------------------------------------------
	local vx = 8.5
	solid("DisplayBase", Vector3.new(7, 3, 3), at(vx, 1.5, frontZ), WOOD, Enum.Material.WoodPlanks)
	bit("DisplayGlass", Vector3.new(7, 2.2, 3), at(vx, 4.1, frontZ), rgb(200, 230, 240), Enum.Material.Glass, 0.6)
	bit("DisplayTop", Vector3.new(7.2, 0.15, 3.2), at(vx, 5.25, frontZ), MARBLE, Enum.Material.Marble)
	bit("DisplayLight", Vector3.new(6.6, 0.08, 0.3), at(vx, 5.1, frontZ + 1), rgb(255, 240, 210), Enum.Material.Neon)
	for row, y in { 3.25, 4.25 } do
		bit("DisplayShelf", Vector3.new(6.8, 0.08, 2.6), at(vx, y - 0.25, frontZ), rgb(230, 230, 232), Enum.Material.Glass)
		for k = 0, 4 do
			local px = vx - 2.6 + k * 1.3
			if row == 1 then
				-- Croissants y tostadas
				bit("Croissant", Vector3.new(0.9, 0.35, 0.5), at(px, y - 0.02, frontZ - 0.4) * CFrame.Angles(0, math.rad(20), 0), rgb(222, 170, 90), Enum.Material.Sand)
				bit("Croissant", Vector3.new(0.9, 0.35, 0.5), at(px + 0.2, y - 0.02, frontZ + 0.5) * CFrame.Angles(0, math.rad(-15), 0), rgb(214, 160, 80), Enum.Material.Sand)
			else
				-- Magdalenas y tartas
				cyl("Muffin", 0.5, 0.6, upright(px, y - 0.05, frontZ - 0.4), rgb(230, 180, 90), Enum.Material.Sand)
				cyl("Cake", 0.6, 1, upright(px, y, frontZ + 0.5), if k % 2 == 0 then rgb(250, 230, 220) else rgb(120, 70, 40), Enum.Material.SmoothPlastic)
			end
		end
	end
	station("Pastry", Vector3.new(6, 2, 1.4), at(vx, 4, frontZ + 1.8))

	---------------------------------------------------------------------
	-- Encimera de trabajo (detrás) con los puestos
	---------------------------------------------------------------------
	solid("BackCounter", Vector3.new(36, 3.6, 2.6), at(0, 1.8, backZ), rgb(70, 70, 76), Enum.Material.Metal)
	solid("BackCounterTop", Vector3.new(36.2, 0.3, 2.8), at(0, 3.75, backZ), rgb(40, 40, 44), Enum.Material.Granite)
	for k = -8, 8 do
		bit("DrawerLine", Vector3.new(0.08, 3, 0.05), at(k * 2.1, 1.8, backZ - 1.32), rgb(50, 50, 56))
	end
	local function onBack(x: number, y: number, dz: number?): CFrame
		return at(x, TOP + y, backZ + (dz or 0))
	end
	local function stationBack(id: string, x: number, w: number)
		station(id, Vector3.new(w, 2.4, 1.6), onBack(x, 1, -1.4))
	end

	-- Molinillo
	local gx = -13
	bit("GrinderBase", Vector3.new(1.4, 1.6, 1.4), onBack(gx, 0.8), DARK, Enum.Material.Metal)
	cyl("GrinderHopper", 1.4, 1.2, onBack(gx, 2.3) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 60, 40), Enum.Material.Glass)
	bit("GrinderBeans", Vector3.new(0.9, 0.6, 0.9), onBack(gx, 2.1), rgb(70, 40, 22), Enum.Material.Pebble)
	bit("GrinderSpout", Vector3.new(0.4, 0.3, 0.6), onBack(gx, 0.9, -0.9), STEEL, Enum.Material.Metal)
	stationBack("Grind", gx, 2)

	-- Cafetera espresso de dos grupos, con manómetro, portafiltros y tazas calentándose encima
	local mx = -6.5
	bit("MachineBody", Vector3.new(5, 2.4, 2), onBack(mx, 1.2), rgb(180, 30, 36), Enum.Material.Metal)
	bit("MachineTop", Vector3.new(5.1, 0.2, 2.1), onBack(mx, 2.5), STEEL, Enum.Material.Metal)
	bit("MachineDrip", Vector3.new(4.4, 0.15, 1), onBack(mx, 0.08, -0.9), STEEL, Enum.Material.DiamondPlate)
	for _, dx in { -1.2, 1.2 } do
		cyl("GroupHead", 0.4, 0.8, onBack(mx + dx, 1.2, -1.1) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
		bit("Portafilter", Vector3.new(0.15, 0.15, 1), onBack(mx + dx, 0.9, -1.7), DARK)
		bit("Button", Vector3.new(0.3, 0.3, 0.05), onBack(mx + dx, 2, -1.02), rgb(240, 240, 240), Enum.Material.Neon)
	end
	cyl("Gauge", 0.1, 0.6, onBack(mx, 1.9, -1.02) * CFrame.Angles(0, math.rad(90), 0), rgb(250, 250, 250))
	for k = -2, 2 do
		cyl("WarmCup", 0.35, 0.6, onBack(mx + k * 0.8, 2.8) * CFrame.Angles(0, 0, math.rad(90)), rgb(250, 250, 250))
	end
	stationBack("Brew", mx, 4.6)
	-- Vaporizador (lanza de vapor) con su jarra
	bit("SteamWand", Vector3.new(0.12, 1.2, 0.12), onBack(mx + 2.8, 0.9, -1.2) * CFrame.Angles(math.rad(15), 0, 0), STEEL, Enum.Material.Metal)
	cyl("MilkPitcher", 0.8, 0.6, onBack(mx + 3.4, 0.4, -0.6) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
	stationBack("Foam", mx + 3.2, 1.6)

	-- Nevera de la leche (bajo la encimera, con puerta de cristal) y bricks encima
	local fx = 0.5
	bit("FridgeDoor", Vector3.new(3, 2.8, 0.1), at(fx, 1.6, backZ - 1.35), rgb(190, 220, 235), Enum.Material.Glass, 0.3)
	bit("FridgeLight", Vector3.new(2.6, 0.1, 0.1), at(fx, 2.9, backZ - 1.2), rgb(220, 240, 255), Enum.Material.Neon)
	for k = -1, 1 do
		bit("MilkBottle", Vector3.new(0.5, 1, 0.5), at(fx + k * 0.8, 1.2, backZ - 0.9), rgb(250, 250, 250))
		bit("MilkCarton", Vector3.new(0.6, 1, 0.4), onBack(fx + k * 0.7, 0.5), if k == 0 then rgb(60, 120, 200) else rgb(240, 240, 240))
	end
	stationBack("Milk", fx, 2.6)

	-- Olla de chocolate
	local cx2 = 5
	cyl("ChocoPot", 1.2, 1.4, onBack(cx2, 0.6) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
	cyl("Chocolate", 0.1, 1.2, onBack(cx2, 1.2) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 50, 30))
	bit("Ladle", Vector3.new(0.1, 1.4, 0.1), onBack(cx2 + 0.3, 1.5) * CFrame.Angles(0, 0, math.rad(20)), STEEL, Enum.Material.Metal)
	stationBack("Chocolate", cx2, 1.8)

	-- Exprimidor con cesta de naranjas
	local jx = 9.5
	bit("JuicerBody", Vector3.new(1.4, 1.8, 1.4), onBack(jx, 0.9), rgb(240, 240, 240), Enum.Material.Metal)
	cyl("JuicerTop", 0.3, 1.2, onBack(jx, 1.95) * CFrame.Angles(0, 0, math.rad(90)), rgb(250, 160, 30), Enum.Material.Glass)
	bit("OrangeBasket", Vector3.new(1.8, 0.5, 1.2), onBack(jx + 1.8, 0.25), rgb(150, 100, 60), Enum.Material.Wood)
	for k = 0, 4 do
		Builder.decor({ Name = "Orange", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), CFrame = onBack(jx + 1.2 + (k % 3) * 0.55, 0.65 + (k // 3) * 0.3, (k % 2) * 0.35 - 0.15), Color = rgb(250, 140, 20), Material = Enum.Material.SmoothPlastic, Parent = model })
	end
	stationBack("Juice", jx + 0.6, 2.6)

	-- Hervidor para el té con cajitas de té
	local tx = 14
	cyl("Kettle", 1, 0.9, onBack(tx, 0.5) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
	bit("KettleHandle", Vector3.new(0.12, 0.5, 0.6), onBack(tx, 1.1, 0.1), DARK)
	for k = 0, 2 do
		bit("TeaBox", Vector3.new(0.6, 0.5, 0.4), onBack(tx + 1.2, 0.25 + k * 0.5), ({ rgb(40, 120, 70), rgb(170, 40, 50), rgb(220, 180, 60) })[k + 1])
	end
	stationBack("Tea", tx + 0.4, 2)

	---------------------------------------------------------------------
	-- Pared del fondo: pizarra con la carta, estantes con tarros y lámparas
	---------------------------------------------------------------------
	local wallZ = D / 2 - 0.9
	local board = bit("MenuBoard", Vector3.new(14, 5, 0.2), at(-4, 8.2, wallZ), rgb(30, 34, 32), Enum.Material.Slate)
	bit("MenuFrame", Vector3.new(14.6, 5.6, 0.1), at(-4, 8.2, wallZ + 0.1), WOOD, Enum.Material.Wood)
	model:SetAttribute("MenuBoard", true)
	board:AddTag("CafeMenuBoard") -- CafeService le pone la carta con los precios
	for _, y in { 6.5, 8.5 } do
		bit("Shelf", Vector3.new(8, 0.25, 1), at(11, y, wallZ - 0.4), WOOD, Enum.Material.Wood)
		for k = 0, 5 do
			cyl("Jar", 0.9, 0.7, upright(8 + k * 1.2, y + 0.58, wallZ - 0.4), if k % 2 == 0 then rgb(90, 60, 40) else rgb(200, 180, 140), Enum.Material.Glass)
		end
	end
	for _, x in { -12, -4, 4 } do
		bit("LampCord", Vector3.new(0.08, 3, 0.08), at(x, 10, frontZ), DARK)
		local lamp = bit("PendantLamp", Vector3.new(1.4, 0.8, 1.4), at(x, 8.2, frontZ), rgb(255, 230, 180), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 14
		light.Brightness = 0.8
		light.Color = rgb(255, 214, 160)
		light.Parent = lamp
	end
	-- Sacos de café y plantas
	for k = 0, 1 do
		bit("BeanSack", Vector3.new(1.8, 2, 1.4), at(-19 + k * 2, 1, backZ - 0.2) * CFrame.Angles(0, math.rad(k * 20), math.rad(4)), rgb(170, 140, 100), Enum.Material.Fabric)
	end
	for _, p in { { -20, -14 }, { 20, -14 }, { 20, 4 } } do
		cyl("PlantPot", 1.6, 1.8, upright(p[1], 0.8, p[2]), rgb(236, 232, 224), Enum.Material.Plaster)
		Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 3.4, 2.6), CFrame = at(p[1], 3.2, p[2]), Color = rgb(60, 120, 60), Material = Enum.Material.LeafyGrass, Parent = model })
	end

	---------------------------------------------------------------------
	-- Puntos para los clientes NPC y el barista NPC
	---------------------------------------------------------------------
	local function point(x: number, z: number): Vector3
		return at(x, 0, z).Position
	end
	model:SetAttribute("Outside", point(0, -D / 2 - 7))
	model:SetAttribute("Door", point(0, -D / 2 + 2))
	for i = 1, 4 do
		model:SetAttribute("Queue" .. i, point(1.5, frontZ - 3 - (i - 1) * 3))
	end
	model:SetAttribute("Wait", point(-11, frontZ - 4))
	model:SetAttribute("Staff", point(-2, frontZ + 3))
	model:AddTag("Cafe")
end

return Cafe
