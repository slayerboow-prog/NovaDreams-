-- Mercadillo y Recinto de Fiestas (zona 7, Explanada del Este; shared/OcioSitios «Feria»).
--
--   * 12 puestos de mercadillo en dos filas (tag OcioStall + StallId): los alquilan los jugadores para
--     vender lo de la granja y la pesca (Services/FeriaService).
--   * 4 food trucks con su mostrador (tag FoodStand + FoodId: FoodService) y su ventanilla
--     (Pickup_FoodTruck); mesas de pícnic (Dropoff_FoodTruck) y tablón del oficio «Cocinero/a de food truck».
--   * Escenario (tag OcioStage): actuar y, en la fiesta del sábado, música.
--   * Casetas de la feria (tag OcioFairGame + Game): aros, tiro con dianas blandas y pesca de patitos.
--   * Guirnaldas de bombillas y focos que se encienden de noche (tag StreetLamp: WorldService).
--   * Panel con el horario (tag OcioFeriaInfo: FeriaService escribe el texto).
-- Coordenadas del sitio: X hacia el este, Z hacia el sur (la avenida queda al sur).

local Builder = require(script.Parent.Parent.Parent.Builder)
local Props = require(script.Parent.Parent.Props)
local Kit = require(script.Parent.OcioKit)
local Sitios = require(game:GetService("ReplicatedStorage").Shared.OcioSitios)
local Feria = require(game:GetService("ReplicatedStorage").Shared.OcioFeria)

local Mercadillo = {}

local rgb = Color3.fromRGB
local NORTH, SOUTH, EAST, WEST = Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0)
local AWNINGS = { rgb(214, 64, 58), rgb(40, 120, 200), rgb(240, 180, 40), rgb(60, 160, 90), rgb(230, 120, 40), rgb(150, 80, 180) }
local BULBS = { rgb(255, 214, 150), rgb(255, 120, 110), rgb(140, 200, 255), rgb(160, 240, 140), rgb(255, 230, 110) }

local function goods(parent: Instance, counter: BasePart, i: number)
	-- Cajas de fruta y verdura encima del mostrador (una pieza de color)
	local colors = { rgb(220, 60, 50), rgb(240, 170, 40), rgb(90, 170, 60), rgb(150, 90, 50) }
	Kit.decor(parent, "Goods", Vector3.new(counter.Size.X - 2, 0.7, 1.4), counter.CFrame * CFrame.new(0, counter.Size.Y / 2 + 0.35, 0), colors[(i - 1) % #colors + 1], Enum.Material.Pebble)
end

local function foodTruck(parent: Instance, cf: CFrame, truck: { [string]: any }, index: number)
	-- cf = centro del camión a ras de suelo, mirando hacia la ventanilla (los clientes)
	local m = Kit.model("FoodTruck_" .. truck.Id, parent)
	local color = rgb(truck.Color[1], truck.Color[2], truck.Color[3])
	-- Caja (largo en X del camión), cabina y ruedas
	Kit.part(m, "Body", Vector3.new(14, 7.5, 6.4), cf * CFrame.new(0, 4.75, 0), color, Enum.Material.SmoothPlastic)
	Kit.part(m, "Cab", Vector3.new(4.5, 5, 6.2), cf * CFrame.new(9.2, 3.5, 0), Kit.WHITE, Enum.Material.SmoothPlastic)
	Kit.decor(m, "Windshield", Vector3.new(0.2, 2, 5.4), cf * CFrame.new(11.5, 4.6, 0), rgb(60, 90, 120), Enum.Material.Glass, { Transparency = 0.3 })
	for _, x in { -4.5, 9 } do
		for _, z in { -3.1, 3.1 } do
			Kit.wheel(m, cf * CFrame.new(x, 1.2, z), 2.4, 0.9)
		end
	end
	-- Ventanilla (de aquí sale el pedido del oficio) y toldo
	Kit.decor(m, "Window", Vector3.new(8, 2.6, 0.2), cf * CFrame.new(0, 5.2, -3.25), rgb(30, 30, 34), Enum.Material.SmoothPlastic, { Tags = { "Pickup_FoodTruck" } })
	Kit.decor(m, "Awning", Vector3.new(9, 0.2, 2.6), cf * CFrame.new(0, 7.2, -4.4) * CFrame.Angles(math.rad(12), 0, 0), Kit.WHITE, Enum.Material.Fabric)
	local sign = Kit.decor(m, "Name", Vector3.new(12, 1.4, 0.2), cf * CFrame.new(0, 8, -3.25), rgb(30, 30, 34))
	Builder.sign(sign, truck.Name, Enum.NormalId.Front, Kit.WHITE)
	-- Mostradores de comida (FoodService: «Comprar · …»)
	for i, foodId in truck.Foods do
		Kit.part(m, "Food_" .. foodId, Vector3.new(1.6, 1, 1.6), cf * CFrame.new(-3 + (i - 1) * 6, 3.8, -3.9), color, Enum.Material.SmoothPlastic, { Tags = { "FoodStand" }, Attributes = { FoodId = foodId, Truck = index } })
	end
	-- Luz de la ventanilla de noche
	Kit.bulb(m, cf * CFrame.new(0, 6.8, -3.6), Kit.WARM, true, 0.5)
end

local function stage(parent: Instance, cf: CFrame)
	local m = Kit.model("Escenario", parent)
	local floor = Kit.part(m, "Stage", Vector3.new(32, 3, 14), cf * CFrame.new(0, 0.5, 0), rgb(60, 50, 45), Enum.Material.WoodPlanks, { Tags = { "OcioStage" } })
	Kit.part(m, "Steps", Vector3.new(6, 1.5, 3), cf * CFrame.new(-11, -0.25, -8.4), rgb(80, 70, 60), Enum.Material.WoodPlanks)
	Kit.part(m, "BackWall", Vector3.new(32, 14, 1), cf * CFrame.new(0, 8.5, 7), rgb(30, 30, 40), Enum.Material.Fabric)
	for _, x in { -15.5, 15.5 } do
		Kit.part(m, "Truss", Vector3.new(1, 15, 1), cf * CFrame.new(x, 9, -6.5), Kit.METAL, Enum.Material.DiamondPlate)
		Kit.part(m, "Speaker", Vector3.new(3, 5, 2.5), cf * CFrame.new(x * 1.18, 0.5, -5), rgb(25, 25, 28), Enum.Material.SmoothPlastic)
	end
	Kit.part(m, "Roof", Vector3.new(34, 0.8, 15), cf * CFrame.new(0, 16.4, 0), rgb(40, 40, 46), Enum.Material.Metal)
	local banner = Kit.decor(m, "Banner", Vector3.new(24, 3, 0.2), cf * CFrame.new(0, 13, 6.4), rgb(200, 40, 60))
	Builder.sign(banner, "ESCENARIO DE LA EXPLANADA", Enum.NormalId.Front, Kit.WHITE)
	-- Focos de colores (se encienden de noche)
	for i, x in { -10, -3.5, 3.5, 10 } do
		local head = Kit.decor(m, "StageLight", Vector3.new(1.2, 1.2, 1.6), cf * CFrame.new(x, 15.5, -6.5), BULBS[i + 1], Enum.Material.SmoothPlastic, { Tags = { "StreetLamp" } })
		if i % 2 == 1 then
			local l = Instance.new("SpotLight")
			l.Face = Enum.NormalId.Bottom
			l.Angle = 70
			l.Range = 30
			l.Brightness = 3
			l.Color = BULBS[i + 1]
			l.Shadows = false
			l.Enabled = false
			l.Parent = head
		end
	end
	return floor
end

local function booth(parent: Instance, cf: CFrame, gameId: string, color: Color3)
	local g = Feria.Games[gameId]
	local m, counter, roof = Kit.stall(parent, cf, 12, color, "Caseta_" .. gameId)
	counter:AddTag("OcioFairGame")
	counter:SetAttribute("Game", gameId)
	Kit.decor(m, "Back", Vector3.new(12, 8, 0.4), cf * CFrame.new(0, 4, 3.2), rgb(250, 240, 220), Enum.Material.Fabric)
	local sign = Kit.decor(m, "Title", Vector3.new(11, 1.6, 0.2), roof.CFrame * CFrame.new(0, 0.9, -2.6), rgb(30, 30, 34))
	Builder.sign(sign, g.Icon .. " " .. g.Name:upper(), Enum.NormalId.Front, rgb(255, 230, 120))
	if gameId == "Aros" then
		-- Botellas en gradas (aros a las botellas)
		for i = 0, 5 do
			Kit.decor(m, "Bottle", Vector3.new(0.6, 1.6, 0.6), cf * CFrame.new(-3.75 + i * 1.5, 4.2 + (i % 2) * 0.8, 1.2), rgb(60, 150, 90), Enum.Material.Glass, { Transparency = 0.2 })
		end
	elseif gameId == "Tiro" then
		-- Dianas de espuma (blandas): discos de colores en la pared
		for i = 0, 5 do
			local c = if i % 2 == 0 then rgb(240, 80, 70) else rgb(250, 250, 250)
			Kit.decor(m, "Target", Vector3.new(0.3, 1.6, 1.6), cf * CFrame.new(-4 + i * 1.6, 5.4, 2.8) * CFrame.Angles(0, math.rad(90), 0), c, Enum.Material.Fabric, { Shape = Enum.PartType.Cylinder })
		end
	else
		-- Piscinita con patitos de goma
		Kit.disc(m, "Pool", 7, 1.2, cf * CFrame.new(0, 0.6, 7), rgb(70, 140, 220), Enum.Material.Plastic, true)
		Kit.disc(m, "Water", 6.2, 0.2, cf * CFrame.new(0, 1.25, 7), rgb(110, 190, 240), Enum.Material.Glass)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			Kit.decor(m, "Duck", Vector3.new(0.7, 0.7, 0.9), cf * CFrame.new(math.cos(a) * 2, 1.6, 7 + math.sin(a) * 2), rgb(250, 210, 40), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
		end
	end
	return counter
end

function Mercadillo.build(parent: Instance): Model
	local site = Sitios.get("Feria") :: any
	local root = Builder.model("Ocio_Feria", parent)
	root:SetAttribute("Zone", site.Zone)
	local base = Sitios.cframe("Feria")
	local function at(x: number, z: number, dir: Vector3?): CFrame
		local p = base * CFrame.new(x, 0, z)
		return if dir then Builder.facing(p.Position, dir) else p
	end

	-- Suelo de la explanada y arco de entrada (desde la avenida, al sur)
	Kit.slab(root, "Explanada", at(0, 0), site.Size[1] - 4, site.Size[2] - 4, rgb(205, 190, 165), Enum.Material.Pavement)
	local arch = Kit.model("Entrada", root)
	for _, x in { -12, 12 } do
		Kit.part(arch, "Pillar", Vector3.new(2, 12, 2), at(x, 84) * CFrame.new(0, 6, 0), rgb(190, 60, 50), Enum.Material.Brick)
	end
	local banner = Kit.part(arch, "ArchBanner", Vector3.new(26, 3.2, 0.6), at(0, 84) * CFrame.new(0, 11, 0), rgb(250, 235, 200), Enum.Material.Fabric)
	Builder.sign(banner, "MERCADILLO Y FIESTAS DE LA EXPLANADA", Enum.NormalId.Back, rgb(170, 40, 40))
	Builder.sign(banner, "MERCADILLO Y FIESTAS DE LA EXPLANADA", Enum.NormalId.Front, rgb(170, 40, 40))

	-- Puestos del mercadillo: dos filas a los lados del pasillo (oeste)
	local market = Builder.model("Mercadillo", root)
	for i = 1, 12 do
		local row = if i <= 6 then 1 else 2
		local k = (i - 1) % 6
		local x = -97.5 + k * 15
		local z = if row == 1 then -22 else 22
		local cf = at(x, z, if row == 1 then SOUTH else NORTH)
		local m, counter, roof = Kit.stall(market, cf, 12, AWNINGS[(i - 1) % #AWNINGS + 1], "Puesto_" .. i)
		Builder.streamable(m)
		counter:AddTag("OcioStall")
		counter:SetAttribute("StallId", i)
		local label = Kit.decor(m, "StallSign", Vector3.new(10, 1.4, 0.2), roof.CFrame * CFrame.new(0, 0.8, -2.6), rgb(250, 245, 230))
		label.Name = "StallSign"
		Builder.sign(label, ("Puesto %d · Se alquila"):format(i), Enum.NormalId.Front, rgb(40, 40, 40))
		goods(m, counter, i)
	end

	-- Escenario al norte, mirando a la plaza
	stage(root, at(0, -72, SOUTH))

	-- Casetas de la feria al este de la plaza, mirando al oeste
	for i, gameId in Feria.GameOrder do
		booth(root, at(25, -30 + (i - 1) * 28, WEST), gameId, AWNINGS[i + 2])
	end

	-- Food trucks al este, mirando al oeste, y mesas de pícnic delante
	for i, truck in Feria.Trucks do
		foodTruck(root, at(102, -66 + (i - 1) * 42, WEST), truck, i)
	end
	local tables = Builder.model("Picnic", root)
	for _, x in { 58, 76 } do
		for _, z in { -50, -5, 40 } do
			Kit.picnic(tables, at(x, z, WEST), { "Dropoff_FoodTruck" })
		end
	end
	Props.jobBoard(root, at(88, 80, SOUTH), "FoodTruck", "COCINERO/A DE FOOD TRUCK")

	-- Panel con el horario del mercadillo y la fiesta (FeriaService escribe el texto)
	local infoModel = Kit.model("Horario", root)
	local info = Kit.sign(infoModel, at(-22, 80, SOUTH), Feria.status(1, 9).Text, 10, 3.2, rgb(30, 60, 120))
	info.Name = "FeriaInfo"
	info:AddTag("OcioFeriaInfo")

	-- Bancos alrededor de la plaza y papeleras
	for _, p in { { -6, -40 }, { -6, 40 }, { 12, 66 }, { -40, 66 } } do
		Kit.bench(root, at(p[1], p[2], if p[2] > 50 then NORTH else EAST))
	end

	-- Tiovivo en la plaza (gira y los caballitos suben y bajan: Controllers/ObjectMotion, tag Carousel)
	local carousel = Kit.model("Tiovivo", root)
	local car = at(2, 0)
	local function turns(p: BasePart, role: string?)
		p:AddTag("Carousel")
		p:SetAttribute("Pivot", car.Position)
		if role then
			p:SetAttribute("Role", role)
		end
	end
	turns(Kit.disc(carousel, "CarouselBase", 16, 1, car * CFrame.new(0, 0.5, 0), rgb(240, 220, 160), Enum.Material.Wood, true))
	turns(Kit.disc(carousel, "CarouselRoof", 17, 1.2, car * CFrame.new(0, 9, 0), rgb(220, 60, 80), Enum.Material.Fabric))
	turns(Kit.pole(carousel, "CarouselPole", 8.5, 2, car, rgb(250, 230, 150)))
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		turns(Kit.decor(carousel, "Horse", Vector3.new(1, 2.2, 3), car * CFrame.new(math.cos(a) * 5.5, 3.2, math.sin(a) * 5.5) * CFrame.Angles(0, -a, 0), if i % 2 == 0 then Kit.WHITE else rgb(250, 200, 90)), "Horse")
	end
	Kit.bulb(carousel, car * CFrame.new(0, 9.8, 0), BULBS[2], true, 1.2)

	-- Sombrillas en las mesas de pícnic y jardineras en la plaza
	for _, x in { 58, 76 } do
		for _, z in { -50, -5, 40 } do
			local u = at(x, z)
			Kit.pole(tables, "ParasolPole", 7.5, 0.25, u, Kit.WHITE)
			Kit.disc(tables, "Parasol", 8, 0.35, u * CFrame.new(0, 7.5, 0), AWNINGS[(x + z) % #AWNINGS + 1], Enum.Material.Fabric)
		end
	end
	for _, p in { { -10, -60 }, { 14, -60 }, { -10, 60 }, { 40, 60 } } do
		local cf = at(p[1], p[2])
		Kit.part(root, "Planter", Vector3.new(4, 1.6, 4), cf * CFrame.new(0, 0.8, 0), rgb(150, 110, 80), Enum.Material.Brick)
		Kit.decor(root, "PlanterBush", Vector3.new(3.4, 2.2, 3.4), cf * CFrame.new(0, 2.4, 0), rgb(70, 130, 60), Enum.Material.Grass, { Shape = Enum.PartType.Ball })
	end

	-- Guirnaldas de bombillas sobre el pasillo del mercadillo y la zona de comer
	local lights = Builder.model("Guirnaldas", root)
	local H = 10
	local posts = { { -110, -36 }, { -60, -36 }, { -10, -36 }, { -110, 36 }, { -60, 36 }, { -10, 36 }, { 45, -78 }, { 45, 74 }, { 88, -78 }, { 88, 74 } }
	for _, p in posts do
		Kit.pole(lights, "LightPost", H, 0.4, at(p[1], p[2]), Kit.DARK, true)
	end
	local function top(p: { number }): Vector3
		return (at(p[1], p[2]) * CFrame.new(0, H - 0.3, 0)).Position
	end
	for _, pair in { { 1, 4 }, { 2, 5 }, { 3, 6 }, { 1, 2 }, { 2, 3 }, { 4, 5 }, { 5, 6 }, { 7, 8 }, { 9, 10 }, { 7, 9 }, { 8, 10 } } do
		local a, b = posts[pair[1]], posts[pair[2]]
		local len = (top(a) - top(b)).Magnitude
		Kit.stringLights(lights, top(a), top(b), math.clamp(math.floor(len / 14), 3, 7), BULBS)
		-- Banderines de colores colgando bajo el cable (los cruces del pasillo)
		if pair[1] <= 3 and pair[2] == pair[1] + 3 then
			local dir = top(b) - top(a)
			for k = 1, 6 do
				local t = k / 7
				local pos = top(a) + dir * t - Vector3.new(0, 1.1 + 0.5 * math.sin(t * math.pi), 0)
				Kit.decor(lights, "Pennant", Vector3.new(0.1, 1.4, 1.2), Kit.along(pos, dir), AWNINGS[k], Enum.Material.Fabric)
			end
		end
	end
	return root
end

return Mercadillo
