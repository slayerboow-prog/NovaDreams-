-- Garage: el garaje de Cosme (plano del dueño, n.º 6 y n.º 12; en el render, el garaje abierto con el
-- portal redondo que brilla al fondo y el coche deportivo futurista plateado con tiras de luz azules).
-- Sigue llamándose «GarajeCosme»: delante está la marca de la historia de siempre (StorySpot
-- GarajeCosme, CosmeHouse/QuestHooks).
--
--   * Planta baja: el coche (World/Kit/FutureCar, el «Cometa 66») en una plataforma giratoria con luz,
--     el portal del fondo, banco de trabajo con monitores y panel de herramientas, armario rojo, moto
--     experimental, drones con su base y el montacargas que baja al sótano.
--   * Sótano (debajo, más grande): el garaje de los portales, con el segundo coche del mismo kit, su
--     portal, bancos, rampa pintada y rayas de peligro.
--   Algunos vehículos servirán para misiones futuras (QuestHooks: PropId CosmeCometa, CosmeMoto).

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local PortalSystem = require(script.Parent.PortalSystem)
local Interior = require(script.Parent.Interior)
local Furniture = require(script.Parent.Parent.Furniture)
local FutureCar = require(script.Parent.Parent.Kit.FutureCar)

local Garage = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local Y = Layout.F0
local CEIL = Layout.CEIL.G
local FB = Layout.FB
local G = Layout.Garage

-- El coche del kit, puesto en la casa (cf local: centro a ras de suelo, morro hacia -Z)
local function car(ctx: Kit.Ctx, parent: Instance, cf: CFrame, opts: { [string]: any }?): Model
	local o = table.clone(opts or {})
	o.Light = function(part: BasePart, range: number, brightness: number, color: Color3)
		Kit.light(ctx, part, range, brightness, color)
	end
	local m = FutureCar.build(parent, Kit.world(ctx, cf), o :: any)
	return m
end
Garage.car = car

local function bike(ctx: Kit.Ctx, parent: Instance, cf: CFrame): Model
	local m = Kit.group(parent, "MotoExperimental")
	Kit.ellipsoid(ctx, m, "Cuerpo", V(1.1, 1.4, 3.6), cf * CF(0, 2, 0), C.Purple, M.SmoothPlastic, nil, true).Reflectance = 0.2
	Kit.ellipsoid(ctx, m, "Asiento", V(0.9, 0.4, 1.6), cf * CF(0, 2.75, 0.7), C.Dark, M.Leather)
	Kit.deco(ctx, m, "Manillar", V(2, 0.2, 0.2), cf * CF(0, 3.1, -1.4), C.Chrome, M.Metal)
	for _, z in { -1.6, 1.6 } do
		Kit.cylX(ctx, m, "Rueda", 0.5, 2.2, cf * CF(0, 1.1, z), rgb(30, 30, 34), M.Rubber)
		Kit.cylX(ctx, m, "Aro", 0.55, 1.4, cf * CF(0, 1.1, z), C.Magenta, M.Neon).Transparency = 0.3
	end
	Kit.box(ctx, m, "Caballete", V(0.2, 1, 0.2), cf * CF(0.5, 0.5, 0), C.Dark, M.Metal)
	Kit.doc(m:FindFirstChild("Cuerpo") :: BasePart, "Moto experimental", "«MOTO GRAVITATORIA — prototipo 3». Circula por las paredes. Por el techo todavía no. Reservada para la misión del túnel del tiempo.", "CosmeMoto")
	return m
end

-- Rayas de peligro (amarillo y negro) a lo largo de X
local function hazard(ctx: Kit.Ctx, parent: Instance, x0: number, x1: number, y: number, z: number)
	local n = math.floor((x1 - x0) / 1.3)
	for i = 0, n - 1 do
		Kit.deco(ctx, parent, "Franja", V(1.2, 0.04, 0.6), CF(x0 + 0.65 + i * 1.3, y + 0.03, z) * ANG(0, 0.7, 0), if i % 2 == 0 then C.Yellow else C.Dark, nil, nil, true)
	end
end

local function groundGarage(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "GarajeCosme")
	-- Pared con la casa (puerta al comedor)
	Interior.partition(ctx, m, "Z", G.X1, G.Z0, G.Z1, Y, CEIL, { { A = -13, B = -7, Bottom = Y, Top = Y + 9.5 } }, rgb(70, 74, 84))
	Kit.door(ctx, m, G.X1, Y, -10, 90, 6, 9.3, rgb(70, 74, 84), true)
	-- Suelo de resina oscura con reflejo, rayas de peligro en la boca y manchas de aceite
	local floor = Kit.box(ctx, m, "FloorFinish", V(G.X1 - G.X0, 0.06, G.Z1 - G.Z0), CF((G.X0 + G.X1) / 2, Y + 0.03, (G.Z0 + G.Z1) / 2), rgb(46, 50, 60), M.SmoothPlastic, { CanQuery = true, CastShadow = false })
	floor.Reflectance = 0.15
	hazard(ctx, m, G.X0 + 1, G.X1 - 1, Y, G.Z0 + 1.2)
	for _, p in { { -26, -22 }, { -40, 0 } } do
		Kit.cyl(ctx, m, "ManchaAceite", 0.02, 2.4, CF(p[1], Y + 0.07, p[2]), rgb(30, 30, 36), M.SmoothPlastic)
	end
	-- Luces: barras LED y un aro de luz sobre el coche; tiras de neón azules en las paredes
	for _, p in { { -33, -24 }, { -33, 4 } } do
		Kit.ceilingLamp(ctx, m, p[1], CEIL, p[2], "GarajeCosme", "Bar", rgb(220, 240, 255))
	end
	Kit.ceilingLamp(ctx, m, -34, CEIL, -10, "GarajeCosme", "Ring", rgb(170, 220, 255))
	Kit.switch(ctx, m, G.X1 - 0.4, Y + 4, -14, -90, "GarajeCosme")
	Interior.cove(ctx, m, "Z", G.X0 + 0.65, G.Z0 + 1, G.Z1 - 1, CEIL - 0.3, C.Cyan)
	Interior.cove(ctx, m, "Z", G.X1 - 0.4, G.Z0 + 1, -14, CEIL - 0.3, C.Cyan)
	-- El coche en su plataforma giratoria con aro de luz
	local plat = Kit.group(m, "PlataformaCoche")
	Kit.disc(ctx, plat, "Plataforma", -34, -10, 7.4, Y + 0.25, 0.25, rgb(60, 64, 76), M.DiamondPlate)
	local ring = Kit.cyl(ctx, plat, "AroLuz", 0.05, 14.8, CF(-34, Y + 0.27, -10), C.Cyan, M.Neon)
	ring.Transparency = 0.1
	Kit.cyl(ctx, plat, "AroHueco", 0.06, 14.2, CF(-34, Y + 0.275, -10), rgb(60, 64, 76), M.DiamondPlate)
	local cometa = car(ctx, m, CF(-34, Y + 0.25, -10), { Name = "CocheExperimental", Plate = "COMETA 66" })
	local seat = Furniture.seatPart(cometa, ctx.Site * CF(-34, Y + 2.6, -10.6), V(2, 0.3, 2))
	Furniture.usable(seat, "Sit")
	Kit.doc(cometa:FindFirstChild("Casco", true) :: BasePart, "Cometa 66", "El coche experimental de Cosme. Motor de energía de grieta, cúpula a prueba de meteoritos y un botón que pone «NO». Velocidad máxima: «sí».\n\nUna nota en el parabrisas: «Para la misión de la luna. No conducir hasta que la criatura tenga carnet (de conducir y de astronauta)».", "CosmeCometa")
	-- El portal redondo que brilla al fondo (como el del render)
	local portal = PortalSystem.build(ctx, m, CF(-33, Y + 6.2, G.Z1 - 2.4), 4.2, { Name = "PortalGaraje", Color = C.Blue, Depth = 1.8, Layers = 8, Spin = 0.18, Stand = 6.2 - 4.2 - 0.8, Destination = 3 })
	portal:SetAttribute("Decor", true)
	local back = Kit.neon(ctx, m, "HaloPortal", V(13, 11, 0.1), CF(-33, Y + 6, G.Z1 - 0.62), rgb(40, 60, 140), 0.55)
	back.Name = "HaloPortal"
	local sign = Kit.deco(ctx, m, "CartelPortal", V(5, 1.1, 0.1), CF(-33, Y + 11.7, G.Z1 - 0.6), C.Dark, nil, nil, true)
	Kit.signText(sign, "NO APARCAR DELANTE DEL PORTAL", Enum.NormalId.Front, C.Yellow, C.Dark)
	-- Banco de trabajo con monitores y panel de herramientas (pared de la derecha)
	local bench = Kit.group(m, "BancoTrabajo")
	Kit.box(ctx, bench, "Tablero", V(2.8, 0.35, 12), CF(-42.4, Y + 3.2, -20), rgb(150, 108, 72), M.Wood)
	for _, z in { -25.5, -14.5 } do
		Kit.box(ctx, bench, "Pata", V(2.4, 3, 0.4), CF(-42.4, Y + 1.5, z), C.Dark, M.Metal)
	end
	for i, kind in { "Plans", "Coords", "Graph" } do
		Kit.monitor(ctx, bench, CF(-43, Y + 3.37, -24 + i * 2.6) * ANG(0, -math.pi / 2, 0), 2.2, 1.4, kind)
	end
	Props.scatter(ctx, bench, { -43.6, -41.2, -25.6, -14.4 }, Y + 3.37, 6, { "Tool", "Screws", "Chip", "Gadget", "Battery", "Mug" })
	Kit.deco(ctx, bench, "PanelHerramientas", V(0.2, 4.6, 11), CF(-43.4, Y + 7.6, -20), rgb(200, 160, 110), M.WoodPlanks, nil, true)
	for k = 0, 9 do
		Kit.deco(ctx, bench, "HerramientaColgada", V(0.15, ctx.Rand.range(0.8, 2), 0.3), CF(-43.22, Y + 6.5 + (k % 2) * 2, -24.5 + k * 1), if k % 3 == 0 then C.Red else C.Chrome, M.Metal)
	end
	Kit.neon(ctx, bench, "LuzBanco", V(0.2, 0.12, 11), CF(-43.2, Y + 10.1, -20), rgb(220, 240, 255), 0.2)
	local drawer = Kit.box(ctx, bench, "Cajon", V(0.2, 0.8, 1.6), CF(-40.95, Y + 2.4, -18), C.Red, M.Metal, { CanCollide = false })
	drawer:SetAttribute("SlideDir", ctx.Site:VectorToWorldSpace(V(1, 0, 0)))
	Kit.prompt(drawer, "Abrir el cajón", "🧰 Cajón de herramientas", "Drawer", { Slide = 1.4, Text = "Llaves inglesas, un destornillador sónico de juguete y el manual del Cometa 66 (en el índice pone: «capítulo 1: no»)." })
	-- Armario de herramientas rojo, neumáticos, bidones y cajas
	local chest = Kit.group(m, "ArmarioHerramientas")
	Kit.box(ctx, chest, "Cuerpo", V(2.2, 4.6, 4.4), CF(-42.8, Y + 2.3, -7), rgb(200, 40, 40), M.Metal)
	for k = 0, 4 do
		Kit.deco(ctx, chest, "Cajonera", V(0.06, 0.08, 4), CF(-41.68, Y + 0.9 + k * 0.85, -7), C.Chrome, M.Metal)
	end
	for k = 0, 3 do
		Kit.cyl(ctx, m, "Neumatico", 0.9, 2.6, CF(-42.4, Y + 0.45 + k * 0.9, 1.5), rgb(30, 30, 34), M.Rubber, true)
	end
	Props.make(ctx, m, "Barrel", CF(-42.6, Y, 5))
	Props.make(ctx, m, "Crate", CF(-23.8, Y, 9.6))
	-- Moto experimental y drones con su base
	bike(ctx, m, CF(-25.4, Y, -19))
	for i, p in { { -25, 3 }, { -25, 7 } } do
		Kit.box(ctx, m, "BaseDron", V(2.6, 0.3, 2.6), CF(p[1], Y + 0.15, p[2]), C.Dark, M.DiamondPlate)
		Kit.neon(ctx, m, "Marca", V(1.6, 0.05, 0.2), CF(p[1], Y + 0.32, p[2]), C.Cyan, 0.2)
		if i == 1 then
			Kit.robot(ctx, m, p[1], Y + 4, p[2], "Dron", { { p[1], p[2] }, { p[1] - 4, p[2] - 3 }, { p[1] - 2, p[2] + 2 } }, 1.5)
		else
			Kit.robot(ctx, m, p[1], Y + 0.48, p[2], "Dron", nil, 0)
		end
	end
	-- Montacargas al sótano (plataforma con rayas, barandilla y su cartel)
	local lift = Kit.group(m, "Montacargas")
	Kit.box(ctx, lift, "Plataforma", V(7, 0.2, 7), CF(-40, Y + 0.1, 7.6), rgb(90, 96, 108), M.DiamondPlate)
	hazard(ctx, lift, -43.5, -36.5, Y + 0.2, 4.3)
	for _, x in { -43.4, -36.6 } do
		Kit.box(ctx, lift, "Guia", V(0.5, CEIL - Y, 0.5), CF(x, (Y + CEIL) / 2, 11.2), C.Yellow, M.Metal)
	end
	local lsign = Kit.deco(ctx, lift, "Cartel", V(4, 1, 0.1), CF(-40, Y + 8.5, G.Z1 - 0.62), C.Yellow, nil, nil, true)
	Kit.signText(lsign, "MONTACARGAS ↓", Enum.NormalId.Front, C.Dark, C.Yellow)
	return m
end

-- Garaje del sótano (el de los portales): el segundo coche del kit, su portal y el taller de coches
local function basementGarage(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "GarajeSotano")
	local floor = Kit.box(ctx, m, "FloorFinish", V(36, 0.06, 64), CF(-26, FB + 0.03, 0), rgb(44, 48, 58), M.SmoothPlastic, { CanQuery = true, CastShadow = false })
	floor.Reflectance = 0.12
	for _, p in { { -26, -22 }, { -26, 10 } } do
		Kit.ceilingLamp(ctx, m, p[1], Layout.CEIL.B, p[2], "GarajeSotano", "Bar", rgb(220, 240, 255))
	end
	Kit.switch(ctx, m, -8.6, FB + 4, -17, 90, "GarajeSotano")
	Interior.cove(ctx, m, "Z", -43.4, -31, 31, Layout.CEIL.B - 0.3, C.Blue)
	-- Rayas de peligro y una «pista» pintada hasta el portal
	hazard(ctx, m, -43, -9, FB, -12)
	for i = 0, 6 do
		Kit.neon(ctx, m, "Pista", V(0.3, 0.05, 3), CF(-26, FB + 0.07, -8 + i * 5), C.Cyan, 0.3)
	end
	-- El segundo coche (azul noche) y su plataforma
	Kit.disc(ctx, m, "Plataforma", -30, 2, 7.2, FB + 0.25, 0.25, rgb(60, 64, 76), M.DiamondPlate)
	local second = car(ctx, m, CF(-30, FB + 0.25, 2), { Name = "CochePortales", Paint = rgb(40, 60, 110), Accent = rgb(170, 110, 255), Plate = "66-B" })
	Kit.doc(second:FindFirstChild("Casco", true) :: BasePart, "Coche de los portales", "El hermano del Cometa 66, pintado de azul noche. Una pegatina en el cristal: «Para cruzar el portal sin bajarse. Probado: 0 veces».", "CosmeCochePortales")
	-- Su portal en la pared del fondo
	local portal = PortalSystem.build(ctx, m, CF(-26, FB + 5.6, 29), 4, { Name = "PortalGarajeSotano", Color = C.Purple, Depth = 2.2, Layers = 8, Spin = 0.2, Stand = 5.6 - 4 - 0.8, Destination = 2, NoCoils = true })
	portal:SetAttribute("Decor", true)
	-- Bancos, rampa, neumáticos y cajas
	for _, z in { -24, -6 } do
		local bm = Kit.group(m, "BancoTrabajo")
		Kit.box(ctx, bm, "Tablero", V(2.8, 0.35, 8), CF(-42.4, FB + 3.2, z), rgb(150, 108, 72), M.Wood)
		for _, sz in { -1, 1 } do
			Kit.box(ctx, bm, "Pata", V(2.4, 3, 0.4), CF(-42.4, FB + 1.5, z + sz * 3.6), C.Dark, M.Metal)
		end
		Props.scatter(ctx, bm, { -43.6, -41.2, z - 3.8, z + 3.8 }, FB + 3.37, 5, { "Tool", "Screws", "Gadget", "Battery", "Coil" })
	end
	Kit.monitor(ctx, m, CF(-43, FB + 3.37, -24) * ANG(0, -math.pi / 2, 0), 2.4, 1.5, "Sim")
	local ramp = Kit.group(m, "Rampa")
	Kit.wedge(ctx, ramp, "Rampa", V(6, 2.2, 7), CF(-40, FB + 1.1, 18) * ANG(0, math.pi, 0), rgb(90, 96, 108), M.DiamondPlate, true)
	Kit.box(ctx, ramp, "Tope", V(6, 2.2, 3), CF(-40, FB + 1.1, 23), rgb(90, 96, 108), M.DiamondPlate)
	for k = 0, 2 do
		Kit.cyl(ctx, m, "Neumatico", 0.9, 2.6, CF(-11, FB + 0.45 + k * 0.9, 28), rgb(30, 30, 34), M.Rubber, true)
	end
	Props.scatter(ctx, m, { -20, -10, 20, 30 }, FB, 5, { "Crate", "Barrel", "CableRun" })
	Kit.robot(ctx, m, -18, FB, -2, "Mini", { { -18, -2 }, { -18, 14 }, { -36, 14 } }, 2.4)
	local sign = Kit.deco(ctx, m, "Cartel", V(0.1, 1.2, 5), CF(-43.45, FB + 9.5, 2), C.Dark, nil, nil, true)
	Kit.signText(sign, "GARAJE DE LOS PORTALES", Enum.NormalId.Right, C.Cyan, C.Dark)
	return m
end

function Garage.build(ctx: Kit.Ctx, root: Instance): Model
	local m = groundGarage(ctx, root)
	basementGarage(ctx, root)
	return m
end

return Garage
