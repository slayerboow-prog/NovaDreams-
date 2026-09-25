-- Supermarket: supermercados completos de Valmar, como uno de verdad.
--
--   Entrada con puertas automáticas, carritos y cestas · cajas con cinta, lector y pantalla ·
--   cajas de autocobro · pasillos con góndolas llenas de productos (con carteles colgantes) ·
--   frutería con cajones · panadería · pared de neveras (lácteos, carne, pescado) · congeladores ·
--   mostrador de charcutería con báscula · almacén con palés y cajas · tablón de empleo.
--
-- Todo lo que se puede usar lleva etiquetas para SupermarketService:
--   Supermarket (modelo) · SuperShelf (sección de estantería, atributo Product) · SuperCheckout
--   (caja, atributo Lane) · SuperSelfCheckout · SuperDeli · SuperStock (almacén) · SuperBoard ·
--   SuperDoor · SuperBounds (volumen del interior, para la alarma)
--
-- Tamaños: "Grande" (hipermercado), "Mediano" y "Compacto" (el del centro).
-- CFrame = centro del edificio a ras de suelo, mirando hacia la calle (la fachada está delante).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local Groceries = require(ReplicatedStorage.Shared.Groceries)

local Supermarket = {}

local rgb = Color3.fromRGB
local WHITE = rgb(242, 242, 238)
local SHELF = rgb(214, 216, 220)
local DARK = rgb(40, 42, 46)

type Spec = { W: number, D: number, H: number, Aisles: number, Lanes: number, Self: number, Fish: boolean }
local SPECS: { [string]: Spec } = {
	Grande = { W = 140, D = 112, H = 16, Aisles = 7, Lanes = 6, Self = 4, Fish = true },
	Mediano = { W = 88, D = 84, H = 13, Aisles = 4, Lanes = 3, Self = 2, Fish = false },
	Compacto = { W = 60, D = 80, H = 12, Aisles = 3, Lanes = 2, Self = 1, Fish = false },
}
Supermarket.Specs = SPECS

-- Productos de una sección de estantería (lo que se ve): 4 baldas con 3 frentes cada una
local function goods(section: BasePart, product: Groceries.Product, width: number, levels: { number }, depth: number)
	for _, y in levels do
		for k = -1, 1 do
			local x = k * width / 3
			local cf = section.CFrame * CFrame.new(x, y, 0)
			if product.Shape == "Bottle" or product.Shape == "Can" then
				local h = if product.Shape == "Bottle" then 1.5 else 0.9
				for j = -1, 1, 2 do
					Builder.decor({
						Name = "Good",
						Shape = Enum.PartType.Cylinder,
						Size = Vector3.new(h, 0.7, 0.7),
						CFrame = cf * CFrame.new(j * width / 9, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
						Color = product.Color,
						Material = Enum.Material.SmoothPlastic,
						Parent = section,
					})
				end
			else
				local h = if product.Shape == "Bag" then 1.1 else 1.3
				Builder.decor({
					Name = "Good",
					Size = Vector3.new(width / 3 - 0.35, h, depth),
					CFrame = cf * CFrame.new(0, h / 2, 0),
					Color = product.Color,
					Material = Enum.Material.SmoothPlastic,
					Parent = section,
				})
			end
		end
	end
end

-- Sección que se puede usar (invisible; los productos cuelgan de ella para poder vaciarla)
local function section(parent: Instance, cf: CFrame, size: Vector3, product: Groceries.Product): BasePart
	local part = Builder.decor({
		Name = "Section_" .. product.Id,
		Size = size,
		CFrame = cf,
		Transparency = 1,
		Parent = parent,
	})
	part:SetAttribute("Product", product.Id)
	part:AddTag("SuperShelf")
	return part
end

-- Cartel con texto (una SurfaceGui por delante y por detrás)
local function sign(part: BasePart, text: string, both: boolean?)
	Builder.sign(part, text, Enum.NormalId.Front)
	if both then
		Builder.sign(part, text, Enum.NormalId.Back)
	end
end

function Supermarket.build(parent: Instance, cf: CFrame, size: string, name: string): Model
	local spec = SPECS[size] or SPECS.Mediano
	local W, D, H = spec.W, spec.D, spec.H
	local m = Builder.model("Supermercado", parent)
	m:SetAttribute("Store", name)
	m:SetAttribute("Size", size)
	m:AddTag("Supermarket")
	Builder.streamable(m)

	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local function box(n: string, s: Vector3, c: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
		local props = { Name = n, Size = s, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = m }
		for k, v in extra or {} do
			props[k] = v
		end
		return Builder.part(props)
	end
	local function deco(n: string, s: Vector3, c: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
		local props = { Name = n, Size = s, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = m }
		for k, v in extra or {} do
			props[k] = v
		end
		return Builder.decor(props)
	end

	local front, back = -D / 2, D / 2
	local stockDepth = 12
	local storeBack = back - stockDepth -- pared interior entre la tienda y el almacén
	local T = 1.2

	---------------------------------------------------------------------
	-- Edificio
	---------------------------------------------------------------------
	box("Floor", Vector3.new(W, 0.4, D), at(0, 0.2, 0), rgb(226, 226, 222), Enum.Material.CeramicTiles)
	box("Roof", Vector3.new(W + 2, 1, D + 2), at(0, H + 0.5, 0), rgb(200, 200, 204), Enum.Material.Concrete)
	deco("Parapet", Vector3.new(W + 2, 1.6, 0.8), at(0, H + 1.8, front - 0.6), rgb(36, 132, 76))
	box("BackWall", Vector3.new(W, H, T), at(0, H / 2, back - T / 2), WHITE, Enum.Material.Plaster)
	for _, s in { -1, 1 } do
		box("SideWall", Vector3.new(T, H, D), at(s * (W / 2 - T / 2), H / 2, 0), WHITE, Enum.Material.Plaster)
	end
	-- Fachada: cristal de suelo a techo, con la puerta a la derecha
	local doorX, doorW = W / 2 - 16, 12
	local left0, left1 = -W / 2 + T, doorX - doorW / 2
	local right0, right1 = doorX + doorW / 2, W / 2 - T
	for _, span in { { left0, left1 }, { right0, right1 } } do
		local w = span[2] - span[1]
		if w > 0.5 then
			box("FrontGlass", Vector3.new(w, H - 4, 0.4), at((span[1] + span[2]) / 2, (H - 4) / 2 + 0.4, front + 0.2), rgb(170, 205, 225), Enum.Material.Glass, { Transparency = 0.55 })
			box("FrontBand", Vector3.new(w, 3.6, 0.8), at((span[1] + span[2]) / 2, H - 1.8, front + 0.4), rgb(36, 132, 76))
		end
	end
	box("DoorLintel", Vector3.new(doorW, H - 9, 0.8), at(doorX, 9 + (H - 9) / 2, front + 0.4), rgb(36, 132, 76))
	-- Puertas automáticas (se abren solas al acercarse: SupermarketService)
	for _, s in { -1, 1 } do
		local door = box("AutoDoor", Vector3.new(doorW / 2, 9, 0.3), at(doorX + s * doorW / 4, 4.9, front + 0.2), rgb(180, 215, 230), Enum.Material.Glass, { Transparency = 0.45 })
		door:SetAttribute("Slide", Vector3.new(s * doorW / 2 * 0.95, 0, 0))
		door:AddTag("SuperDoor")
	end
	-- Rótulo grande
	local signPart = deco("StoreSign", Vector3.new(math.min(W - 10, 46), 4, 0.6), at(-W / 6, H - 1.8, front - 0.6), rgb(36, 132, 76), Enum.Material.SmoothPlastic)
	sign(signPart, "🛒 " .. string.upper(name))
	-- Marquesina de la entrada y felpudo
	deco("Canopy", Vector3.new(doorW + 8, 0.5, 6), at(doorX, 9.8, front - 3), rgb(36, 132, 76))
	deco("Mat", Vector3.new(doorW, 0.06, 5), at(doorX, 0.43, front + 3), DARK, Enum.Material.Fabric)

	-- Luz: paneles en el techo (pocas luces de verdad, muchas "lámparas" que brillan)
	local lights = if size == "Grande" then { { -35, -20 }, { 35, -20 }, { -35, 25 }, { 35, 25 } } else { { -W / 5, -D / 6 }, { W / 5, D / 8 } }
	for _, l in lights do
		local panel = deco("LightPanel", Vector3.new(8, 0.3, 3), at(l[1], H - 0.2, l[2]), rgb(250, 252, 255), Enum.Material.Neon)
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 40
		light.Angle = 120
		light.Brightness = 1.6
		light.Color = rgb(245, 250, 255)
		light.Shadows = false
		light.Parent = panel
	end
	for x = -W / 2 + 10, W / 2 - 10, 16 do
		for z = front + 10, storeBack - 6, 16 do
			deco("CeilingLight", Vector3.new(6, 0.2, 1.2), at(x, H - 0.1, z), rgb(248, 250, 255), Enum.Material.Neon)
		end
	end

	-- Volumen del interior (para saber si alguien sale con productos sin pagar)
	local bounds = Builder.decor({ Name = "Bounds", Size = Vector3.new(W - 2, H, D - 2), CFrame = at(0, H / 2, 0), Transparency = 1, Parent = m })
	bounds:AddTag("SuperBounds")

	---------------------------------------------------------------------
	-- Entrada: carritos, cestas y tablón de empleo
	---------------------------------------------------------------------
	for i = 0, 3 do
		local c = at(doorX + doorW / 2 + 3, 0.4, front + 4 + i * 1.4)
		deco("CartBasket", Vector3.new(2.2, 1.6, 3), c * CFrame.new(0, 2.4, 0), rgb(190, 195, 200), Enum.Material.DiamondPlate)
		deco("CartBase", Vector3.new(2, 0.2, 3), c * CFrame.new(0, 0.6, 0), DARK, Enum.Material.Metal)
	end
	for i = 0, 2 do
		deco("Basket", Vector3.new(1.8, 1, 1.2), at(doorX - doorW / 2 - 2, 0.9 + i * 0.9, front + 4), rgb(210, 40, 40), Enum.Material.Plastic)
	end
	local board = box("StaffBoard", Vector3.new(4, 3, 0.3), at(doorX - doorW / 2 - 2, 5, front + 8) * CFrame.Angles(0, math.pi / 2, 0), rgb(34, 108, 196))
	sign(board, "SE BUSCA\nCAJERO · REPONEDOR\nCHARCUTERO", true)
	board:AddTag("SuperBoard")
	deco("BoardPost", Vector3.new(0.3, 4, 0.3), at(doorX - doorW / 2 - 2, 2, front + 8), rgb(60, 64, 70), Enum.Material.Metal)

	---------------------------------------------------------------------
	-- Cajas (fila delantera, a la izquierda de la puerta)
	---------------------------------------------------------------------
	local laneX0 = -W / 2 + 7
	for i = 1, spec.Lanes do
		local x = laneX0 + (i - 1) * 9
		local z = front + 9
		local belt = box("Checkout", Vector3.new(2.6, 3, 9), at(x, 1.9, z), rgb(60, 64, 70), Enum.Material.Metal)
		deco("Belt", Vector3.new(2.2, 0.1, 6), at(x, 3.45, z + 1.2), rgb(25, 25, 28), Enum.Material.Rubber)
		deco("Scanner", Vector3.new(1.4, 0.15, 1.2), at(x, 3.45, z - 2.4), rgb(130, 200, 255), Enum.Material.Neon)
		local screen = deco("Register", Vector3.new(1.6, 1.3, 0.3), at(x + 1.6, 4.4, z - 3) * CFrame.Angles(0, -math.pi / 2, 0), DARK)
		sign(screen, "CAJA " .. i)
		deco("Bagging", Vector3.new(2.6, 0.2, 2.5), at(x, 3.3, z - 5.6), rgb(200, 200, 205), Enum.Material.Metal)
		local lamp = deco("LaneLight", Vector3.new(0.8, 0.8, 0.8), at(x - 1, 7, z - 3), rgb(80, 220, 120), Enum.Material.Neon)
		deco("LanePole", Vector3.new(0.2, 3.6, 0.2), at(x - 1, 5, z - 3), rgb(60, 64, 70), Enum.Material.Metal)
		belt:SetAttribute("Lane", i)
		belt:SetAttribute("CashierSpot", at(x + 2.6, 0.4, z - 2.4).Position)
		belt:SetAttribute("QueueSpot", at(x - 2.6, 0.4, z + 6).Position)
		belt:SetAttribute("PaySpot", at(x - 2.6, 0.4, z - 2).Position)
		lamp:SetAttribute("Lane", i)
		belt:AddTag("SuperCheckout")
	end
	-- Autocobro
	for i = 1, spec.Self do
		local x = laneX0 + spec.Lanes * 9 + 2 + (i - 1) * 5
		local kiosk = box("SelfCheckout", Vector3.new(2.4, 3.4, 2), at(x, 2.1, front + 12), rgb(230, 232, 236), Enum.Material.SmoothPlastic)
		local screen = deco("SelfScreen", Vector3.new(2, 1.4, 0.2), at(x, 4.6, front + 11.2) * CFrame.Angles(math.rad(-20), math.pi, 0), rgb(40, 120, 200), Enum.Material.Neon)
		sign(screen, "AUTOCOBRO")
		kiosk:AddTag("SuperSelfCheckout")
	end

	---------------------------------------------------------------------
	-- Góndolas (pasillos centrales)
	---------------------------------------------------------------------
	local gx0, gx1 = -W / 2 + 18, W / 2 - 20
	local gz0, gz1 = front + 24, storeBack - 18
	local L = gz1 - gz0
	local spacing = (gx1 - gx0) / spec.Aisles
	local aisleXs = { gx0 - spacing / 2 + 1 }
	local faceIndex = 0
	local levels = { -2.8, -1.2, 0.4, 2.0 }
	local SEC = 8
	local sections = math.max(1, math.floor(L / SEC))
	local secLen = L / sections
	for i = 1, spec.Aisles do
		local x = gx0 + spacing * (i - 0.5)
		table.insert(aisleXs, x + spacing / 2)
		local mid = (gz0 + gz1) / 2
		box("Gondola", Vector3.new(1.2, 7.6, L), at(x, 4.2, mid), SHELF, Enum.Material.Metal)
		deco("GondolaBase", Vector3.new(3.4, 0.6, L), at(x, 0.7, mid), rgb(170, 172, 178), Enum.Material.Metal)
		for _, lv in levels do
			deco("ShelfBoard", Vector3.new(3.4, 0.15, L), at(x, 4.4 + lv - 0.1, mid), SHELF, Enum.Material.Metal)
		end
		-- Cartel colgante del pasillo
		for side, dir in { -1, 1 } do
			faceIndex += 1
			local category = Groceries.AisleOrder[(faceIndex - 1) % #Groceries.AisleOrder + 1]
			local products = Groceries.bySection[category]
			for k = 1, sections do
				local z = gz0 + (k - 0.5) * secLen
				local product = products[(k - 1) % #products + 1]
				local faceCf = Builder.facing(at(x + dir * 1.25, 4.4, z).Position, (at(x + dir, 0, z).Position - at(x, 0, z).Position))
				local part = section(m, faceCf, Vector3.new(secLen - 0.4, 7, 1.2), product)
				goods(part, product, secLen - 0.6, levels, 1.1)
			end
			if side == 1 then
				local hang = deco("AisleSign", Vector3.new(10, 2.2, 0.3), at(x, H - 3.2, gz0 + 2), rgb(36, 132, 76))
				local a = Groceries.Sections[Groceries.AisleOrder[(faceIndex - 2) % #Groceries.AisleOrder + 1]]
				local b = Groceries.Sections[category]
				sign(hang, ("PASILLO %d\n%s %s · %s %s"):format(i, a.Icon, a.Name, b.Icon, b.Name), true)
				deco("SignWire", Vector3.new(0.1, 2, 0.1), at(x, H - 1.1, gz0 + 2), DARK)
			end
		end
	end

	---------------------------------------------------------------------
	-- Frutería (cajones inclinados a la derecha, cerca de la entrada)
	---------------------------------------------------------------------
	local produce = {}
	for _, id in { "Fruta", "Verdura" } do
		for _, product in Groceries.bySection[id] do
			table.insert(produce, product)
		end
	end
	local px = W / 2 - 8
	for k, product in produce do
		local z = front + 22 + (k - 1) * 5.5
		if z > storeBack - 34 then
			break
		end
		local table_ = at(px, 0, z) * CFrame.Angles(0, math.pi / 2, 0)
		deco("ProduceStand", Vector3.new(5, 2.6, 4), table_ * CFrame.new(0, 1.7, 0), rgb(150, 110, 70), Enum.Material.WoodPlanks)
		local crate = table_ * CFrame.new(0, 3.3, 0) * CFrame.Angles(math.rad(-18), 0, 0)
		deco("Crate", Vector3.new(4.6, 0.8, 3.6), crate, rgb(180, 140, 90), Enum.Material.Wood)
		local part = section(m, crate * CFrame.new(0, 0.6, 0), Vector3.new(4.4, 1, 3.4), product)
		Builder.decor({ Name = "Good", Size = Vector3.new(4.2, 0.5, 3.2), CFrame = crate * CFrame.new(0, 0.55, 0), Color = product.Color, Material = Enum.Material.Pebble, Parent = part })
		for j = -1, 1 do
			Builder.decor({
				Name = "Good",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1, 1, 1),
				CFrame = crate * CFrame.new(j * 1.2, 1, j * 0.5),
				Color = product.Color,
				Material = Enum.Material.SmoothPlastic,
				Parent = part,
			})
		end
		local tag = deco("PriceTag", Vector3.new(2.4, 1, 0.1), table_ * CFrame.new(0, 2.6, -2.05), rgb(250, 230, 70))
		sign(tag, ("%s %s  %d€"):format(product.Icon, product.Name, product.Price))
	end
	local fruitSign = deco("SectionSign", Vector3.new(0.3, 2.2, 12), at(W / 2 - 1, H - 4, front + 30), rgb(220, 70, 60))
	Builder.sign(fruitSign, "🍎 FRUTERÍA", Enum.NormalId.Left)

	-- Panadería (estantería de pared a la derecha, al fondo)
	local breadZ = storeBack - 22
	local rack = at(W / 2 - 3, 4, breadZ) * CFrame.Angles(0, math.pi / 2, 0) -- mira hacia dentro
	deco("BreadRack", Vector3.new(14, 7.6, 2.6), rack * CFrame.new(0, 0, 0.6), rgb(170, 120, 70), Enum.Material.WoodPlanks)
	for k, product in Groceries.bySection.Panaderia do
		local part = section(m, rack * CFrame.new(-5.25 + (k - 1) * 3.5, 0.4, -0.9), Vector3.new(3.3, 7, 1.2), product)
		goods(part, product, 3.1, { -2.6, -0.8, 1.0 }, 1)
	end
	local breadSign = deco("SectionSign", Vector3.new(0.3, 2, 10), at(W / 2 - 1, H - 4, breadZ), rgb(200, 150, 80))
	Builder.sign(breadSign, "🥖 PANADERÍA", Enum.NormalId.Left)

	---------------------------------------------------------------------
	-- Neveras (pared del fondo): lácteos, carne y pescado
	---------------------------------------------------------------------
	box("InnerWall", Vector3.new(W - 2 * T, H, T), at(0, H / 2, storeBack + T / 2), WHITE, Enum.Material.Plaster)
	local fridgeProducts = {}
	for _, id in { "Lacteos", "Carne", if spec.Fish then "Pescado" else nil } do
		for _, product in Groceries.bySection[id] or {} do
			table.insert(fridgeProducts, product)
		end
	end
	local fw = 5
	local fx0 = -W / 2 + 18
	local maxUnits = math.floor((W / 2 - 22 - fx0) / fw) -- sin tapar la puerta del almacén
	for k = 1, math.min(#fridgeProducts, maxUnits) do
		local product = fridgeProducts[k]
		local x = fx0 + (k - 0.5) * fw
		local unit = at(x, 4.5, storeBack - 1.8) -- mira hacia la tienda
		deco("Fridge", Vector3.new(fw, 8.6, 3.4), unit * CFrame.new(0, 0, 0.3), rgb(230, 234, 238), Enum.Material.Metal)
		deco("FridgeGlass", Vector3.new(fw - 0.4, 7, 0.15), unit * CFrame.new(0, -0.2, -1.5), rgb(200, 225, 240), Enum.Material.Glass, { Transparency = 0.6 })
		deco("FridgeLight", Vector3.new(fw - 0.6, 0.2, 0.3), unit * CFrame.new(0, 3.5, -1.2), rgb(240, 250, 255), Enum.Material.Neon)
		local part = section(m, unit * CFrame.new(0, 0, -1.8), Vector3.new(fw - 0.4, 7, 1.2), product)
		goods(part, product, fw - 0.8, { -3, -1.4, 0.2, 1.8 }, 1)
		-- (los productos van detrás del cristal)
		for _, good in part:GetChildren() do
			if good:IsA("BasePart") then
				good.CFrame = good.CFrame * CFrame.new(0, 0, 0.9)
			end
		end
	end
	local fridgeSign = deco("SectionSign", Vector3.new(24, 2, 0.3), at(fx0 + 14, H - 3.5, storeBack - 0.6), rgb(90, 150, 220))
	Builder.sign(fridgeSign, "🥛 LÁCTEOS · 🥩 CARNE" .. (if spec.Fish then " · 🐟 PESCADO" else ""), Enum.NormalId.Front)

	-- Congeladores (islas delante de las neveras)
	local frozen = Groceries.bySection.Congelados
	local freezerZ = storeBack - 10
	for k, product in frozen do
		local x = -W / 2 + 22 + (k - 1) * 11
		if x > gx1 then
			break
		end
		local c = at(x, 0, freezerZ)
		deco("Freezer", Vector3.new(10, 3, 4), c * CFrame.new(0, 1.9, 0), rgb(235, 238, 242), Enum.Material.Metal)
		deco("FreezerGlass", Vector3.new(9.4, 0.15, 3.4), c * CFrame.new(0, 3.45, 0), rgb(200, 230, 245), Enum.Material.Glass, { Transparency = 0.55 })
		local part = section(m, Builder.facing(c.Position + Vector3.new(0, 3, 0), c.LookVector * -1), Vector3.new(9, 1, 3.2), product)
		for j = -1, 1 do
			Builder.decor({ Name = "Good", Size = Vector3.new(2.6, 0.9, 2.8), CFrame = c * CFrame.new(j * 3, 2.9, 0), Color = product.Color, Parent = part })
		end
	end

	---------------------------------------------------------------------
	-- Charcutería (mostrador a la izquierda) y pescadería en el grande
	---------------------------------------------------------------------
	local deliZ = (gz0 + gz1) / 2
	local deliX = -W / 2 + 7
	local counter = at(deliX, 0, deliZ) * CFrame.Angles(0, -math.pi / 2, 0) -- mira hacia dentro de la tienda
	local deli = box("DeliCounter", Vector3.new(16, 3.6, 2.6), counter * CFrame.new(0, 2.2, 0), rgb(240, 240, 240), Enum.Material.SmoothPlastic)
	deco("DeliGlass", Vector3.new(16, 1.6, 0.2), counter * CFrame.new(0, 4.8, -1.1) * CFrame.Angles(math.rad(-25), 0, 0), rgb(200, 225, 240), Enum.Material.Glass, { Transparency = 0.55 })
	for k = 1, #Groceries.Deli do
		deco("DeliTray", Vector3.new(2.4, 0.4, 1.6), counter * CFrame.new(-6.4 + (k - 1) * 3.2, 4.2, -0.2), rgb(200, 90, 80):Lerp(rgb(240, 200, 120), (k - 1) / #Groceries.Deli), Enum.Material.SmoothPlastic)
	end
	deco("Scale", Vector3.new(1.6, 0.5, 1.2), counter * CFrame.new(6.5, 4.3, 0.6), rgb(200, 204, 210), Enum.Material.Metal)
	deco("Slicer", Vector3.new(1.6, 1.2, 1.4), counter * CFrame.new(3, 4.6, 0.6), rgb(170, 30, 30), Enum.Material.Metal)
	deco("DeliBackWall", Vector3.new(16, 6, 0.4), counter * CFrame.new(0, 3, 4.3), rgb(250, 240, 220), Enum.Material.CeramicTiles)
	local deliSign = deco("SectionSign", Vector3.new(14, 2, 0.3), counter * CFrame.new(0, 8.5, 4), rgb(170, 40, 40))
	Builder.sign(deliSign, "🔪 CHARCUTERÍA", Enum.NormalId.Front)
	deli:SetAttribute("StaffSpot", (counter * CFrame.new(0, 0.4, 2.6)).Position)
	deli:SetAttribute("CustomerSpot", (counter * CFrame.new(0, 0.4, -3.4)).Position)
	deli:AddTag("SuperDeli")
	if spec.Fish then
		local fish = at(deliX, 0, deliZ - 20) * CFrame.Angles(0, -math.pi / 2, 0)
		deco("FishCounter", Vector3.new(12, 3, 3), fish * CFrame.new(0, 1.9, 0), rgb(230, 235, 240), Enum.Material.Metal)
		deco("Ice", Vector3.new(11.4, 0.4, 2.6), fish * CFrame.new(0, 3.6, 0), rgb(235, 245, 255), Enum.Material.Ice)
		for k, product in Groceries.bySection.Pescado do
			local part = section(m, fish * CFrame.new(-3 + (k - 1) * 6, 4.2, -0.6), Vector3.new(5, 1, 2), product)
			Builder.decor({ Name = "Good", Size = Vector3.new(4.6, 0.5, 2), CFrame = fish * CFrame.new(-3 + (k - 1) * 6, 4, 0), Color = product.Color, Parent = part })
		end
		local fishSign = deco("SectionSign", Vector3.new(10, 2, 0.3), fish * CFrame.new(0, 8, 3), rgb(70, 140, 190))
		Builder.sign(fishSign, "🐟 PESCADERÍA", Enum.NormalId.Front)
	end

	---------------------------------------------------------------------
	-- Almacén (detrás de la pared del fondo)
	---------------------------------------------------------------------
	local stockDoorX = W / 2 - 12
	-- hueco en la pared interior: se tapa con dos trozos alrededor de la puerta
	local wall = m:FindFirstChild("InnerWall") :: BasePart
	wall:Destroy()
	local dw = 7
	local l0, l1 = -W / 2 + T, stockDoorX - dw / 2
	local r0, r1 = stockDoorX + dw / 2, W / 2 - T
	box("InnerWall", Vector3.new(l1 - l0, H, T), at((l0 + l1) / 2, H / 2, storeBack + T / 2), WHITE, Enum.Material.Plaster)
	box("InnerWall", Vector3.new(r1 - r0, H, T), at((r0 + r1) / 2, H / 2, storeBack + T / 2), WHITE, Enum.Material.Plaster)
	box("InnerWall", Vector3.new(dw, H - 8, T), at(stockDoorX, 8 + (H - 8) / 2, storeBack + T / 2), WHITE, Enum.Material.Plaster)
	local staff = deco("StaffSign", Vector3.new(5, 1.2, 0.2), at(stockDoorX, 8.8, storeBack - 0.1), rgb(200, 40, 40))
	Builder.sign(staff, "ALMACÉN · SOLO PERSONAL", Enum.NormalId.Front)
	deco("StripCurtain", Vector3.new(dw, 8, 0.1), at(stockDoorX, 4.4, storeBack + 0.6), rgb(220, 230, 235), Enum.Material.Plastic, { Transparency = 0.6 })
	for i, x in { -W / 2 + 10, -W / 4, 0, W / 4 - 6 } do
		local c = at(x, 0, storeBack + stockDepth / 2 + 0.6)
		deco("Pallet", Vector3.new(5, 0.5, 5), c * CFrame.new(0, 0.65, 0), rgb(170, 130, 80), Enum.Material.WoodPlanks)
		for j = 0, 2 do
			deco("StockBox", Vector3.new(4.4, 1.6, 4.4), c * CFrame.new(0, 1.7 + j * 1.65, 0), rgb(190, 150, 90), Enum.Material.Cardboard)
		end
		local pickup = Builder.decor({ Name = "StockPoint", Size = Vector3.new(4, 4, 4), CFrame = c * CFrame.new(0, 2, -3.5), Transparency = 1, Parent = m })
		pickup:SetAttribute("Index", i)
		pickup:AddTag("SuperStock")
	end
	deco("Forklift", Vector3.new(3, 3, 5), at(W / 2 - 6, 1.9, storeBack + stockDepth / 2), rgb(240, 180, 30), Enum.Material.Metal)

	-- Puntos para que los clientes NPC se muevan (en coordenadas del mundo)
	m:SetAttribute("Origin", cf)
	m:SetAttribute("Door", at(doorX, 0.4, front - 4).Position)
	m:SetAttribute("Inside", at(doorX, 0.4, front + 14).Position)
	m:SetAttribute("FrontZ", front + 19)
	m:SetAttribute("BackZ", gz1 + 4)
	m:SetAttribute("AisleXs", table.concat(aisleXs, ","))
	return m
end

return Supermarket
