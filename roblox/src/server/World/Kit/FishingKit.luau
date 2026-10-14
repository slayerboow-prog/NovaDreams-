-- FishingKit: todo lo de la pesca en el mapa (lo usa FishingService).
--
--   FishingKit.spot(parent, cf, water)        sitio de pesca: parte invisible con tag FishingSpot.
--        cf = donde te pones, mirando al agua. Atributos: Water ("Mar", "AltaMar", "Rio", "Lago")
--        y CastDistance (a cuántos studs cae el corcho, delante, en el agua).
--   FishingKit.jetty(parent, cf, water, name)  pantalán de madera hacia el agua con 3 sitios de pesca.
--        cf = en la orilla, mirando al agua. Modelo "ZonaPesca" (sale en el mapa).
--   FishingKit.boat(parent, cf)                barco de pesca fondeado en alta mar: cubierta
--        (FishingBoatDeck), 4 sitios de pesca y la vuelta a puerto (FishingBoatReturn).
--   FishingKit.dock(parent, cf)                amarre del puerto para subir al barco (FishingBoatDock).
--   FishingKit.shop(parent, cf, W, D)          por dentro de la tienda de pesca del centro:
--        mostrador (FishingShopCounter), cañas, cebo, redes, chalecos, carteles.
--        cf = centro del suelo de la tienda, mirando a la calle (-Z = puerta).

local Builder = require(script.Parent.Parent.Builder)

local FishingKit = {}

local rgb = Color3.fromRGB
local WOOD = rgb(128, 94, 64)
local DARK_WOOD = rgb(86, 62, 42)
local ROPE = rgb(200, 180, 130)
local WHITE = rgb(240, 240, 236)
local WATER_Y = -2

function FishingKit.spot(parent: Instance, cf: CFrame, water: string, castDistance: number?): BasePart
	local spot = Builder.part({
		Name = "FishingSpot",
		Size = Vector3.new(3, 5, 3),
		CFrame = cf * CFrame.new(0, 2.5, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Tags = { "FishingSpot" },
		Attributes = { Water = water, CastDistance = castDistance or 10 },
		Parent = parent,
	})
	-- Cubo y caja de aparejos (para que se vea que ahí se pesca)
	Builder.decor({ Name = "Bucket", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 1.1, 1.1), CFrame = cf * CFrame.new(1.6, 0.6, 0.6) * CFrame.Angles(0, 0, math.rad(90)), Color = rgb(60, 120, 190), Parent = parent })
	Builder.decor({ Name = "TackleBox", Size = Vector3.new(1.2, 0.6, 0.7), CFrame = cf * CFrame.new(-1.6, 0.3, 0.8), Color = rgb(40, 110, 60), Parent = parent })
	return spot
end

local function post(parent: Instance, cf: CFrame, height: number)
	Builder.decor({ Name = "Post", Size = Vector3.new(0.9, height, 0.9), CFrame = cf * CFrame.new(0, -height / 2 + 0.4, 0), Color = DARK_WOOD, Material = Enum.Material.Wood, Parent = parent })
end

function FishingKit.jetty(parent: Instance, cf: CFrame, water: string, name: string?): Model
	local m = Builder.model("ZonaPesca", parent)
	m:SetAttribute("PlaceName", name or "Zona de pesca")
	local L, W = 30, 8
	-- Tablero y pilotes
	Builder.part({ Name = "Deck", Size = Vector3.new(W, 0.8, L), CFrame = cf * CFrame.new(0, 0.6, -L / 2), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = m })
	for z = 2, L, 7 do
		for _, x in { -W / 2 + 0.4, W / 2 - 0.4 } do
			post(m, cf * CFrame.new(x, 0.2, -z), 7)
		end
	end
	-- Barandilla a los lados (el extremo queda libre para pescar)
	for _, x in { -W / 2 + 0.2, W / 2 - 0.2 } do
		Builder.decor({ Name = "Rail", Size = Vector3.new(0.25, 0.25, L - 10), CFrame = cf * CFrame.new(x, 3.1, -(L - 10) / 2 - 1), Color = WOOD, Parent = m })
		for z = 1, L - 10, 5 do
			Builder.decor({ Name = "Baluster", Size = Vector3.new(0.25, 2.2, 0.25), CFrame = cf * CFrame.new(x, 2.1, -z), Color = WOOD, Parent = m })
		end
	end
	-- Tres sitios de pesca en el extremo: dos a los lados y uno al frente
	FishingKit.spot(m, cf * CFrame.new(-2.2, 1, -L + 1.5) * CFrame.Angles(0, math.rad(20), 0), water)
	FishingKit.spot(m, cf * CFrame.new(2.2, 1, -L + 1.5) * CFrame.Angles(0, math.rad(-20), 0), water)
	FishingKit.spot(m, cf * CFrame.new(W / 2 - 1.5, 1, -L + 9) * CFrame.Angles(0, math.rad(-90), 0), water)
	-- Banco, farol y cartel
	Builder.part({ Name = "Bench", Size = Vector3.new(1.4, 0.4, 4), CFrame = cf * CFrame.new(-W / 2 + 1.2, 1.9, -12), Color = WOOD, Material = Enum.Material.Wood, Parent = m })
	for _, z in { -10.6, -13.4 } do
		Builder.decor({ Name = "BenchLeg", Size = Vector3.new(1.2, 0.9, 0.3), CFrame = cf * CFrame.new(-W / 2 + 1.2, 1.4, z), Color = DARK_WOOD, Parent = m })
	end
	local pole = Builder.decor({ Name = "LampPost", Size = Vector3.new(0.4, 7, 0.4), CFrame = cf * CFrame.new(W / 2 - 0.6, 4.5, -L + 3), Color = rgb(40, 44, 50), Material = Enum.Material.Metal, Parent = m })
	local _ = pole
	local bulb = Builder.decor({ Name = "Lens", Size = Vector3.new(0.9, 0.9, 0.9), CFrame = cf * CFrame.new(W / 2 - 0.6, 8.2, -L + 3), Color = rgb(255, 230, 170), Material = Enum.Material.SmoothPlastic, Tags = { "StreetLamp" }, Parent = m })
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.2
	light.Color = rgb(255, 214, 150)
	light.Enabled = false
	light.Parent = bulb
	local board = Builder.part({ Name = "Sign", Size = Vector3.new(5, 1.8, 0.3), CFrame = cf * CFrame.new(0, 3.4, 1.5), Color = rgb(30, 90, 140), Parent = m })
	Builder.decor({ Name = "SignPost", Size = Vector3.new(0.3, 3, 0.3), CFrame = cf * CFrame.new(-2.2, 1.5, 1.5), Color = DARK_WOOD, Parent = m })
	Builder.decor({ Name = "SignPost", Size = Vector3.new(0.3, 3, 0.3), CFrame = cf * CFrame.new(2.2, 1.5, 1.5), Color = DARK_WOOD, Parent = m })
	Builder.sign(board, "🎣 ZONA DE PESCA", Enum.NormalId.Back)
	Builder.sign(board, "🎣 ZONA DE PESCA", Enum.NormalId.Front)
	-- Boya en el agua
	Builder.decor({ Name = "Buoy", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = cf * CFrame.new(5, WATER_Y + 0.4, -L - 10), Color = rgb(240, 90, 40), Parent = m })
	return m
end

-- Barco de pesca (arrastrero) fondeado. cf = centro, proa hacia -Z.
function FishingKit.boat(parent: Instance, cf: CFrame): Model
	local m = Builder.model("BarcoPesca", parent)
	local HULL = rgb(30, 70, 130)
	local W, L = 12, 40
	local deckY = 2.2
	Builder.part({ Name = "Hull", Size = Vector3.new(W, 5, L), CFrame = cf * CFrame.new(0, -0.6, 0), Color = HULL, Parent = m })
	Builder.part({ Name = "Bow", ClassName = "WedgePart", Size = Vector3.new(W, 5, 9), CFrame = cf * CFrame.new(0, -0.6, -L / 2 - 4.5) * CFrame.Angles(0, math.rad(180), 0), Color = HULL, Parent = m })
	Builder.decor({ Name = "Waterline", Size = Vector3.new(W + 0.1, 0.6, L + 0.1), CFrame = cf * CFrame.new(0, -1.9, 0), Color = rgb(170, 40, 40), Parent = m })
	Builder.decor({ Name = "Stripe", Size = Vector3.new(W + 0.1, 0.5, L + 0.1), CFrame = cf * CFrame.new(0, 1.3, 0), Color = WHITE, Parent = m })
	Builder.part({ Name = "Deck", Size = Vector3.new(W - 0.6, 0.4, L - 0.6), CFrame = cf * CFrame.new(0, deckY - 0.2, 0), Color = rgb(150, 120, 90), Material = Enum.Material.WoodPlanks, Parent = m })
	-- Borda (para no caerse)
	for _, x in { -W / 2 + 0.2, W / 2 - 0.2 } do
		Builder.part({ Name = "Gunwale", Size = Vector3.new(0.4, 1.4, L), CFrame = cf * CFrame.new(x, deckY + 0.7, 0), Color = HULL, Parent = m })
	end
	Builder.part({ Name = "Transom", Size = Vector3.new(W, 1.4, 0.4), CFrame = cf * CFrame.new(0, deckY + 0.7, L / 2 - 0.2), Color = HULL, Parent = m })
	-- Puente de mando
	Builder.part({ Name = "Wheelhouse", Size = Vector3.new(8, 6, 8), CFrame = cf * CFrame.new(0, deckY + 3, -8), Color = WHITE, Parent = m })
	Builder.decor({ Name = "Windows", Size = Vector3.new(7, 1.6, 0.1), CFrame = cf * CFrame.new(0, deckY + 4.2, -12.05), Color = rgb(60, 100, 140), Material = Enum.Material.Glass, Parent = m })
	Builder.decor({ Name = "Roof", Size = Vector3.new(8.6, 0.4, 8.6), CFrame = cf * CFrame.new(0, deckY + 6.2, -8), Color = rgb(200, 60, 50), Parent = m })
	Builder.decor({ Name = "Radar", Size = Vector3.new(3, 0.3, 0.5), CFrame = cf * CFrame.new(0, deckY + 7.4, -8), Color = WHITE, Parent = m })
	Builder.decor({ Name = "Mast", Size = Vector3.new(0.5, 14, 0.5), CFrame = cf * CFrame.new(0, deckY + 7, -3), Color = WHITE, Parent = m })
	Builder.decor({ Name = "Boom", Size = Vector3.new(0.4, 0.4, 16), CFrame = cf * CFrame.new(0, deckY + 11, 5) * CFrame.Angles(math.rad(-20), 0, 0), Color = WHITE, Parent = m })
	-- Redes, cajas de pescado y boyas
	Builder.decor({ Name = "NetPile", Size = Vector3.new(5, 1.4, 4), CFrame = cf * CFrame.new(-2, deckY + 0.7, 14), Color = rgb(60, 130, 90), Material = Enum.Material.Fabric, Parent = m })
	for i = 0, 3 do
		Builder.decor({ Name = "FishCrate", Size = Vector3.new(2, 1, 1.4), CFrame = cf * CFrame.new(3.4, deckY + 0.5 + (i // 2) * 1, 4 + (i % 2) * 1.6), Color = rgb(40, 110, 190), Parent = m })
	end
	for _, z in { -14, 0, 12 } do
		Builder.decor({ Name = "Fender", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = cf * CFrame.new(W / 2 + 0.5, 0.6, z), Color = rgb(240, 90, 40), Parent = m })
	end
	-- Por dónde se sube (se aparece aquí) y vuelta a puerto
	Builder.part({ Name = "Deck spawn", Size = Vector3.new(4, 1, 4), CFrame = cf * CFrame.new(0, deckY + 0.5, 4), Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false, Tags = { "FishingBoatDeck" }, Parent = m })
	Builder.part({ Name = "ReturnBoard", Size = Vector3.new(3, 2, 0.3), CFrame = cf * CFrame.new(0, deckY + 1.8, -3.8), Color = rgb(30, 90, 140), Tags = { "FishingBoatReturn" }, Parent = m })
	-- Sitios de pesca: dos por banda, mirando al mar
	for _, z in { -2, 10 } do
		FishingKit.spot(m, cf * CFrame.new(-W / 2 + 1.6, deckY, z) * CFrame.Angles(0, math.rad(90), 0), "AltaMar", 9)
		FishingKit.spot(m, cf * CFrame.new(W / 2 - 1.6, deckY, z) * CFrame.Angles(0, math.rad(-90), 0), "AltaMar", 9)
	end
	return m
end

-- Amarre del puerto: poste con cartel para subir al barco de pesca
function FishingKit.dock(parent: Instance, cf: CFrame): BasePart
	Builder.decor({ Name = "DockPost", Size = Vector3.new(0.4, 4, 0.4), CFrame = cf * CFrame.new(0, 2, 0), Color = DARK_WOOD, Parent = parent })
	local board = Builder.part({
		Name = "BoatDock",
		Size = Vector3.new(4.4, 2.2, 0.3),
		CFrame = cf * CFrame.new(0, 4.6, 0),
		Color = rgb(30, 90, 140),
		Tags = { "FishingBoatDock" },
		Parent = parent,
	})
	Builder.sign(board, "⛴️ BARCO DE PESCA", Enum.NormalId.Front)
	Builder.sign(board, "⛴️ BARCO DE PESCA", Enum.NormalId.Back)
	Builder.decor({ Name = "Rope", Size = Vector3.new(0.2, 0.2, 6), CFrame = cf * CFrame.new(0, 1.2, -3), Color = ROPE, Parent = parent })
	return board
end

-- Por dentro de la tienda de pesca (W de ancho, D de fondo)
function FishingKit.shop(parent: Instance, cf: CFrame, W: number, D: number)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	-- Mostrador al fondo con caja y báscula
	local counter = Builder.part({ Name = "FishingShopCounter", Size = Vector3.new(10, 3.4, 2.6), CFrame = at(W / 2 - 9, 1.9, D / 2 - 6), Color = WOOD, Material = Enum.Material.Wood, Tags = { "FishingShopCounter" }, Parent = parent })
	counter:SetAttribute("StaffSpot", (at(W / 2 - 9, 0.4, D / 2 - 3.2)).Position)
	Builder.decor({ Name = "CounterTop", Size = Vector3.new(10.4, 0.2, 3), CFrame = at(W / 2 - 9, 3.7, D / 2 - 6), Color = rgb(60, 60, 64), Parent = parent })
	Builder.decor({ Name = "Register", Size = Vector3.new(1.6, 1, 1.2), CFrame = at(W / 2 - 6, 4.3, D / 2 - 6), Color = rgb(40, 40, 44), Parent = parent })
	Builder.decor({ Name = "Scale", Size = Vector3.new(1.4, 0.4, 1.2), CFrame = at(W / 2 - 11.5, 4, D / 2 - 6), Color = rgb(200, 204, 210), Material = Enum.Material.Metal, Parent = parent })
	-- Pared de cañas: expositor con cañas de colores en vertical
	local rackX = -W / 2 + 1.2
	Builder.decor({ Name = "RodRack", Size = Vector3.new(0.6, 9, D - 12), CFrame = at(rackX, 4.5, 0), Color = DARK_WOOD, Parent = parent })
	local colors = { rgb(200, 50, 40), rgb(40, 90, 170), rgb(240, 180, 30), rgb(30, 30, 34), rgb(60, 150, 80) }
	local n = 0
	for z = -(D - 14) / 2, (D - 14) / 2, 1.6 do
		n += 1
		Builder.decor({ Name = "Rod", Size = Vector3.new(0.12, 8, 0.12), CFrame = at(rackX + 0.5, 4.8, z) * CFrame.Angles(0, 0, math.rad(4)), Color = colors[n % #colors + 1], Parent = parent })
		Builder.decor({ Name = "Reel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 0.6, 0.6), CFrame = at(rackX + 0.7, 2, z), Color = rgb(170, 170, 176), Material = Enum.Material.Metal, Parent = parent })
	end
	-- Nevera de cebo vivo
	Builder.part({ Name = "BaitFridge", Size = Vector3.new(4, 4, 2.4), CFrame = at(W / 2 - 3, 2, -D / 2 + 8), Color = WHITE, Material = Enum.Material.Metal, Parent = parent })
	Builder.decor({ Name = "BaitGlass", Size = Vector3.new(3.4, 0.1, 2), CFrame = at(W / 2 - 3, 4.05, -D / 2 + 8), Color = rgb(200, 225, 240), Material = Enum.Material.Glass, Transparency = 0.5, Parent = parent })
	local baitSign = Builder.decor({ Name = "BaitSign", Size = Vector3.new(3.6, 1, 0.2), CFrame = at(W / 2 - 3, 5.2, -D / 2 + 9.1), Color = rgb(170, 110, 60), Parent = parent })
	Builder.sign(baitSign, "🐛 CEBO VIVO", Enum.NormalId.Front)
	-- Estantería central: carretes, anzuelos y cajas de aparejos
	for i = -1, 1 do
		local shelf = at(0, 0, i * 6)
		Builder.part({ Name = "Shelf", Size = Vector3.new(8, 0.3, 2.4), CFrame = shelf * CFrame.new(0, 3, 0), Color = rgb(220, 220, 214), Parent = parent })
		Builder.part({ Name = "Shelf", Size = Vector3.new(8, 0.3, 2.4), CFrame = shelf * CFrame.new(0, 1.2, 0), Color = rgb(220, 220, 214), Parent = parent })
		for x = -3, 3, 1.5 do
			Builder.decor({ Name = "Box", Size = Vector3.new(1.1, 0.8, 1), CFrame = shelf * CFrame.new(x, 3.55, 0), Color = colors[(math.floor(x) + 4 + i) % #colors + 1], Parent = parent })
			Builder.decor({ Name = "Box", Size = Vector3.new(1.1, 0.6, 1), CFrame = shelf * CFrame.new(x, 1.65, 0), Color = rgb(230, 200, 120), Parent = parent })
		end
	end
	-- Chalecos salvavidas y una red colgada
	for i = 0, 2 do
		Builder.decor({ Name = "LifeJacket", Size = Vector3.new(1.6, 2.2, 0.4), CFrame = at(W / 2 - 1, 5.5, -2 + i * 2.2) * CFrame.Angles(0, math.rad(-90), 0), Color = rgb(250, 110, 20), Parent = parent })
	end
	Builder.decor({ Name = "Net", Size = Vector3.new(8, 4, 0.1), CFrame = at(0, 8.5, D / 2 - 1.2), Color = rgb(70, 140, 100), Material = Enum.Material.Fabric, Transparency = 0.3, Parent = parent })
	Builder.decor({ Name = "LifeRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 3, 3), CFrame = at(-3, 7.5, D / 2 - 1.3) * CFrame.Angles(0, math.rad(90), 0), Color = rgb(240, 70, 50), Parent = parent })
	-- Pez disecado en la pared
	Builder.decor({ Name = "TrophyBoard", Size = Vector3.new(4, 1.6, 0.2), CFrame = at(3, 7.6, D / 2 - 1.3), Color = DARK_WOOD, Parent = parent })
	Builder.decor({ Name = "TrophyFish", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 1, 0.5), CFrame = at(3, 7.6, D / 2 - 1.5), Color = rgb(120, 150, 170), Material = Enum.Material.Metal, Parent = parent })
	-- Cartel de precios
	local prices = Builder.decor({ Name = "PriceBoard", Size = Vector3.new(6, 3, 0.2), CFrame = at(W / 2 - 9, 7, D / 2 - 1.3), Color = rgb(20, 40, 60), Parent = parent })
	Builder.sign(prices, "🎣 CAÑAS · 🐛 CEBO\n⛴️ SALIDAS EN BARCO\nDESDE EL PUERTO", Enum.NormalId.Front)
	return counter
end

return FishingKit
