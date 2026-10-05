-- Garage: el garaje experimental de Cosme (docs/historia/casa-cosme.md, punto 22; en la imagen, el
-- garaje abierto con un portal al fondo y un coche experimental). Sigue llamándose «GarajeCosme»:
-- delante está la marca de la historia de siempre (StorySpot GarajeCosme, CosmeHouse/QuestHooks).
--
--   * Coche experimental (inventado: el «Cometa 66», con cúpula, aletas, toberas y luz por debajo),
--     moto experimental, un vehículo desmontado en el elevador, drones con su base, bancos de trabajo
--     con panel de herramientas, ordenadores y el portal del fondo.
--   * Escalera al sótano (sala de energía): Layout.Stairs.Garaje, con barandillas.
--   Algunos vehículos servirán para misiones futuras (QuestHooks: PropId CosmeCometa, CosmeMoto).

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local PortalSystem = require(script.Parent.PortalSystem)
local Laboratory = require(script.Parent.Laboratory)
local Furniture = require(script.Parent.Parent.Furniture)

local Garage = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local Y = Layout.F0
local CEIL = Layout.CEIL.G

-- El coche experimental (cf: centro del coche en el suelo, el morro hacia -Z)
local function car(ctx: Kit.Ctx, parent: Instance, cf: CFrame): Model
	local m = Kit.group(parent, "CocheExperimental")
	local body = rgb(196, 206, 222)
	Kit.box(ctx, m, "Chasis", V(5.6, 1.2, 11), cf * CF(0, 1.5, 0), body, M.Metal)
	Kit.wedge(ctx, m, "Morro", V(5.6, 1, 3), cf * CF(0, 2.6, -4) * ANG(0, math.pi, 0), body, M.Metal, true)
	Kit.box(ctx, m, "Lomo", V(5.2, 0.9, 5), cf * CF(0, 2.55, 1.6), body, M.Metal)
	local dome = Kit.ball(ctx, m, "Cupula", 4.6, CF(0, 0, 0) * cf * CF(0, 3, -0.4), rgb(80, 160, 220), M.Glass, 0.35)
	dome.Size = V(4.4, 2.4, 5)
	for _, s in { -1, 1 } do
		Kit.wedge(ctx, m, "Aleta", V(0.3, 2.2, 3), cf * CF(s * 2.4, 3.6, 4.2), C.Cyan, M.Metal)
		Kit.cylX(ctx, m, "Tobera", 1.4, 1.2, cf * CF(s * 1.6, 1.8, 5.8) * ANG(0, math.pi / 2, 0), C.Dark, M.Metal)
		local flame = Kit.neon(ctx, m, "Llama", V(0.8, 0.8, 0.3), cf * CF(s * 1.6, 1.8, 6.55), C.Cyan, 0.2)
		Kit.fx(flame, "Energy", 6)
		Kit.neon(ctx, m, "Faro", V(1.2, 0.3, 0.15), cf * CF(s * 1.9, 1.9, -5.55), rgb(220, 240, 255))
		Kit.neon(ctx, m, "Raya", V(0.15, 0.2, 10), cf * CF(s * 2.82, 1.6, 0), C.Cyan, 0.1)
		for _, z in { -3.6, 3.6 } do
			Kit.cylX(ctx, m, "Rueda", 0.9, 2.4, cf * CF(s * 2.6, 1.2, z), rgb(30, 30, 34), M.Rubber)
			Kit.cylX(ctx, m, "Llanta", 0.95, 1.4, cf * CF(s * 2.6, 1.2, z), C.Cyan, M.Neon).Transparency = 0.3
		end
	end
	local under = Kit.neon(ctx, m, "LuzBajos", V(4.6, 0.1, 9.6), cf * CF(0, 0.85, 0), C.Cyan, 0.3)
	Kit.light(ctx, under, 12, 1, C.Cyan)
	local seat = Furniture.seatPart(m, ctx.Site * cf * CF(0, 2.35, -0.6), V(2, 0.3, 2))
	Furniture.usable(seat, "Sit")
	local plate = Kit.deco(ctx, m, "Matricula", V(2.2, 0.6, 0.1), cf * CF(0, 1.4, -5.55), C.White, nil, nil, true)
	Kit.signText(plate, "COMETA 66", Enum.NormalId.Front, C.Dark, C.White)
	Kit.doc(m:FindFirstChild("Chasis") :: BasePart, "Cometa 66", "El coche experimental de Cosme. Motor de energía de grieta, cúpula a prueba de meteoritos y un botón que pone «NO». Velocidad máxima: «sí».\n\nUna nota en el parabrisas: «Para la misión de la luna. No conducir hasta que la criatura tenga carnet (de conducir y de astronauta)».", "CosmeCometa")
	return m
end

local function bike(ctx: Kit.Ctx, parent: Instance, cf: CFrame): Model
	local m = Kit.group(parent, "MotoExperimental")
	Kit.box(ctx, m, "Cuerpo", V(1, 1.2, 3.4), cf * CF(0, 2, 0), C.Purple, M.Metal)
	Kit.box(ctx, m, "Asiento", V(0.9, 0.3, 1.4), cf * CF(0, 2.75, 0.6), C.Dark, M.Leather)
	Kit.deco(ctx, m, "Manillar", V(2, 0.2, 0.2), cf * CF(0, 3.2, -1.4), C.Chrome, M.Metal)
	for _, z in { -1.6, 1.6 } do
		Kit.cylX(ctx, m, "Rueda", 0.5, 2.2, cf * CF(0, 1.1, z), rgb(30, 30, 34), M.Rubber)
		Kit.cylX(ctx, m, "Aro", 0.55, 1.4, cf * CF(0, 1.1, z), C.Magenta, M.Neon).Transparency = 0.3
	end
	Kit.box(ctx, m, "Caballete", V(0.2, 1, 0.2), cf * CF(0.5, 0.5, 0), C.Dark, M.Metal)
	Kit.doc(m:FindFirstChild("Cuerpo") :: BasePart, "Moto experimental", "«MOTO GRAVITATORIA — prototipo 3». Circula por las paredes. Por el techo todavía no. Reservada para la misión del túnel del tiempo.", "CosmeMoto")
	return m
end

function Garage.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "GarajeCosme")
	local G = Layout.Garage
	-- Suelo con rayas amarillas y negras, manchas de aceite
	for i = 0, 7 do
		Kit.deco(ctx, m, "Franja", V(1.6, 0.04, 0.8), CF(14 + i * 2.6, Y + 0.02, -31.2) * ANG(0, 0.7, 0), if i % 2 == 0 then C.Yellow else C.Dark, nil, nil, true)
	end
	for _, p in { { 24, -20 }, { 30, -4 }, { 18, -2 } } do
		Kit.cyl(ctx, m, "ManchaAceite", 0.02, 2.4, CF(p[1], Y + 0.02, p[2]), rgb(30, 30, 36), M.SmoothPlastic)
	end
	-- Luces y su interruptor
	for _, p in { { 20, -22 }, { 36, -26 }, { 20, -4 }, { 28, -10 } } do
		Kit.ceilingLamp(ctx, m, p[1], CEIL, p[2], "GarajeCosme", "Bar", rgb(220, 240, 255))
	end
	Kit.switch(ctx, m, 12.6, Y + 4, -24, -90, "GarajeCosme")
	-- Coche, moto y el portal del fondo
	car(ctx, m, CF(25, Y, -12))
	bike(ctx, m, CF(19, Y, -13))
	local portal = PortalSystem.build(ctx, m, CF(25, Y + 6.2, 3.2), 4, { Name = "PortalGaraje", Color = C.Blue, Depth = 2, Layers = 8, Spin = 0.18, Stand = 6.2 - 4.8, Destination = 3, NoCoils = true })
	portal:SetAttribute("Decor", true)
	-- Elevador con el vehículo desmontado
	local lift = Kit.group(m, "Elevador")
	for _, x in { 13.5, 18.5 } do
		Kit.box(ctx, lift, "Columna", V(0.8, 11, 0.8), CF(x, Y + 5.5, -3), C.Red, M.Metal)
		Kit.box(ctx, lift, "Brazo", V(0.5, 0.4, 7), CF(x + (if x < 16 then 0.6 else -0.6), Y + 5.4, -3), C.Dark, M.Metal)
	end
	Kit.box(ctx, lift, "Travesano", V(5.8, 0.6, 0.6), CF(16, Y + 11.3, -3), C.Red, M.Metal)
	Kit.box(ctx, lift, "ChasisDesmontado", V(3.6, 0.6, 7), CF(16, Y + 5.9, -3), rgb(120, 126, 136), M.CorrodedMetal)
	Kit.box(ctx, lift, "Motor", V(2, 1.4, 1.8), CF(16, Y + 6.9, -5), rgb(80, 86, 96), M.Metal)
	for _, z in { -1, 1.4 } do
		Kit.cylX(ctx, lift, "Rueda", 0.8, 2.2, CF(14.6 + (z + 1) * 0.8, Y + 1.1, z - 7.6) * ANG(0, 0.6, 0), rgb(30, 30, 34), M.Rubber)
	end
	Props.make(ctx, lift, "Pile", CF(16, Y, 1.2))
	Kit.doc(lift:FindFirstChild("ChasisDesmontado") :: BasePart, "Vehículo desmontado", "«Furgoneta multidimensional». Le falta todo menos las ganas. Una etiqueta: «Piezas en el almacén, caja 41 (las de otra dimensión)».", "CosmeFurgoneta")
	-- Bancos de trabajo y panel de herramientas en la pared
	for i, z in { -21, -15 } do
		local bench = Kit.group(m, "BancoTrabajo")
		Kit.box(ctx, bench, "Tablero", V(3, 0.4, 5.4), CF(14.1, Y + 3.2, z), rgb(150, 108, 72), M.Wood)
		Kit.box(ctx, bench, "Cajonera", V(2.8, 3, 2), CF(14.1, Y + 1.5, z - 1.5), C.Red, M.Metal)
		Kit.deco(ctx, bench, "Pata", V(0.3, 3, 0.3), CF(14.1, Y + 1.5, z + 2.4), C.Dark, M.Metal)
		Props.scatter(ctx, bench, { 12.8, 15.4, z - 2.6, z + 2.6 }, Y + 3.4, 5, { "Tool", "Screws", "Chip", "Gadget", "Battery", "Mug" })
		local drawer = Kit.box(ctx, bench, "Cajon", V(0.2, 0.8, 1.6), CF(15.55, Y + 2.4, z - 1.5), C.Red:Lerp(C.White, 0.2), M.Metal, { CanCollide = false })
		drawer:SetAttribute("SlideDir", ctx.Site:VectorToWorldSpace(V(1, 0, 0)))
		Kit.prompt(drawer, "Abrir el cajón", "🧰 Cajón de herramientas", "Drawer", { Slide = 1.4, Text = if i == 1 then "Llaves inglesas, un destornillador sónico de juguete y un pósit: «la llave de 66 no existe, no la busques»." else "Tornillos ordenados por dimensión de origen." })
		local _ = drawer
	end
	local board = Kit.box(ctx, m, "PanelHerramientas", V(0.2, 5, 11), CF(12.6, Y + 7.5, -18), rgb(200, 160, 110), M.WoodPlanks, { CanCollide = false })
	for k = 0, 9 do
		Kit.deco(ctx, m, "HerramientaColgada", V(0.15, ctx.Rand.range(0.8, 2), 0.3), CF(12.78, Y + 6 + (k % 2) * 2, -23 + k * 1.1), if k % 3 == 0 then C.Red else C.Chrome, M.Metal)
	end
	local _ = board
	-- Ordenadores en el fondo
	local desk = Kit.box(ctx, m, "MesaOrdenadores", V(6.8, 0.3, 2.8), CF(16, Y + 3, 4.2), C.Dark, M.Metal)
	for _, x in { 13, 19 } do
		Kit.box(ctx, m, "Pata", V(0.4, 2.85, 2.4), CF(x, Y + 1.43, 4.2), C.Dark, M.Metal)
	end
	for i, kind in { "Plans", "Coords", "Graph" } do
		Kit.monitor(ctx, m, CF(11.2 + i * 2.4, Y + 3.15, 4.6), 2, 1.3, kind)
	end
	local _ = desk
	Props.scatter(ctx, m, { 13, 19, 3, 3.6 }, Y + 3.15, 3, { "Mug", "Keyboard", "Papers" })
	-- Drones y su base (zona libre delante de la escalera al sótano)
	for i, p in { { 37, -28 }, { 42, -28 }, { 42, -23.5 } } do
		local pad = Kit.box(ctx, m, "BaseDron", V(2.6, 0.3, 2.6), CF(p[1], Y + 0.15, p[2]), C.Dark, M.DiamondPlate)
		Kit.neon(ctx, m, "Marca", V(1.6, 0.05, 0.2), CF(p[1], Y + 0.32, p[2]), C.Cyan, 0.2)
		local _ = pad
		if i < 3 then
			Kit.robot(ctx, m, p[1], Y + 3 + i, p[2], "Dron", { { p[1], p[2] }, { p[1] - 6, p[2] + 2 }, { p[1] - 2, p[2] + 6 } }, 1.5)
		else
			Kit.robot(ctx, m, p[1], Y + 0.48, p[2], "Dron", nil, 0)
		end
	end
	-- Neumáticos apilados, bidones y una caja de herramientas grande
	for k = 0, 3 do
		Kit.cyl(ctx, m, "Neumatico", 0.9, 2.6, CF(44, Y + 0.45 + k * 0.9, -31), rgb(30, 30, 34), M.Rubber, true)
	end
	Props.make(ctx, m, "Barrel", CF(35, Y, -30.5))
	Props.make(ctx, m, "Crate", CF(21, Y, -30.5))
	Props.scatter(ctx, m, { 20, 32, -30, -22 }, Y, 4, { "CableRun", "Pile" })
	local sign = Kit.deco(ctx, m, "CartelPortal", V(5, 1.2, 0.1), CF(25, Y + 12.6, 5.45), C.Dark, nil, nil, true)
	Kit.signText(sign, "NO APARCAR DELANTE DEL PORTAL", Enum.NormalId.Front, C.Yellow, C.Dark)
	-- Escalera al sótano (con barandillas alrededor del hueco)
	local s = Layout.Stairs.Garaje
	Laboratory.coreStairs(ctx, m, s, "BajadaGaraje")
	Kit.railing(ctx, m, V(s.X0 + 0.2, Y, s.Z0 + s.Near), V(s.X0 + 0.2, Y, 5.6))
	Kit.railing(ctx, m, V(s.X0 + 0.2, Y, s.Z0 + s.Near), V(s.X0 + 5.8, Y, s.Z0 + s.Near))
	local down = Kit.deco(ctx, m, "CartelSotano", V(5, 1.2, 0.1), CF(45.45, Y + 8, -16.5) * ANG(0, math.pi / 2, 0), C.Yellow, nil, nil, true)
	Kit.signText(down, "↓ SALA DE ENERGÍA", Enum.NormalId.Front, C.Dark, C.Yellow)
	local _ = down
	return m
end

return Garage
