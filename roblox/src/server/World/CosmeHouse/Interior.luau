-- Interior: las plantas baja y alta de la casa de Cosme (docs/historia/casa-cosme.md, puntos 5-17).
--
--   Baja: vestíbulo con la escalera principal a la vista (cuatro tramos que suben hasta el ático por
--   un hueco de 30 studs de alto con cristalera), despacho (y la torre), sala de estar, comedor y
--   cocina, baño, y la bajada al sótano (con la puerta al garaje).
--   Alta: pasillo-galería, biblioteca científica (con la torre), sala de ordenadores, habitación de
--   Cosme, baño, sala de experimentos y salida al balcón.
--
-- Todo lo que se usa va con shared/Interact (puertas, sillas, sofás, camas, luces, grifos, ducha,
-- ordenadores, armario) o con los avisos de la casa (Kit.prompt: documentos, pantallas, cajones,
-- experimentos, máquinas; los conecta CosmeHouse/Interactions).

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local PortalSystem = require(script.Parent.PortalSystem)
local Furniture = require(script.Parent.Parent.Furniture)

local Interior = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local F0, F1 = Layout.F0, Layout.F1
local CG, CU = Layout.CEIL.G, Layout.CEIL.U

local function op(a: number, b: number, bottom: number, top: number, kind: string?): Kit.Opening
	return { A = a, B = b, Bottom = bottom, Top = top, Kind = kind }
end

local function partition(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, a: number, b: number, y0: number, y1: number, openings: { Kit.Opening }?, color: Color3?)
	return Kit.wall(ctx, parent, axis, fixed, a, b, y0, y1, { Thick = 0.6, Name = "InnerWall", Color = color or C.Wall, Material = M.Plaster, Openings = openings, Frame = C.Dark })
end

-- Suelo de otro material encima del forjado (baldosas del baño y la cocina, piedra del vestíbulo)
local function overlay(ctx: Kit.Ctx, parent: Instance, name: string, x0: number, x1: number, z0: number, z1: number, y: number, color: Color3, material: Enum.Material)
	Kit.box(ctx, parent, name, V(x1 - x0, 0.06, z1 - z0), CF((x0 + x1) / 2, y + 0.03, (z0 + z1) / 2), color, material, { CanQuery = true, CastShadow = false })
end

local function rug(ctx: Kit.Ctx, parent: Instance, x: number, y: number, z: number, w: number, d: number, color: Color3, pattern: Color3?)
	Kit.deco(ctx, parent, "Alfombra", V(w, 0.08, d), CF(x, y + 0.04, z), color, M.Fabric, nil, true)
	if pattern then
		-- Dibujo de átomo (aro y núcleo), como en la alfombra del vestíbulo de la imagen
		local ring = Kit.cyl(ctx, parent, "DibujoAro", 0.02, math.min(w, d) * 0.6, CF(x, y + 0.09, z), pattern, M.Fabric)
		ring.Transparency = 0
		Kit.cyl(ctx, parent, "DibujoHueco", 0.025, math.min(w, d) * 0.5, CF(x, y + 0.095, z), color, M.Fabric)
		Kit.cyl(ctx, parent, "DibujoNucleo", 0.03, math.min(w, d) * 0.14, CF(x, y + 0.1, z), pattern, M.Fabric)
	end
end

local function at(ctx: Kit.Ctx, x: number, y: number, z: number, yaw: number?): CFrame
	return Kit.at(ctx, x, y, z, yaw)
end

---------------------------------------------------------------------
-- Escalera principal (vestíbulo -> planta alta -> ático): Layout.Stairs.Hall
---------------------------------------------------------------------
local function mainStair(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "EscaleraPrincipal")
	local s = Layout.Stairs.Hall
	for k = 1, s.Flights do
		Kit.flight(ctx, m, s, k, Layout.flight(s, k), rgb(120, 84, 56), M.Wood)
	end
	-- Rellanos del fondo (los de cerca son el suelo de cada planta)
	for _, l in Layout.landings(s) do
		if not l.Near then
			Kit.box(ctx, m, "Rellano", V(l.X1 - l.X0, 0.8, l.Z1 - l.Z0), CF((l.X0 + l.X1) / 2, l.Y - 0.4, (l.Z0 + l.Z1) / 2), rgb(120, 84, 56), M.Wood, { CanQuery = true })
			Kit.railing(ctx, m, V(s.X0 + 0.2, l.Y, l.Z0), V(s.X0 + 0.2, l.Y, l.Z1 - 0.3))
		end
	end
	-- Espina central (separa los dos carriles) con tiras de luz
	local z0, z1 = s.Z0 + s.Near, s.Z0 + s.Near + s.Run
	Kit.box(ctx, m, "InnerWall", V(0.6, Layout.F2 + 1 - F0, z1 - z0), CF(s.X0 + 6, (F0 + Layout.F2 + 1) / 2, (z0 + z1) / 2), C.Wall, M.Plaster, { CanQuery = true })
	for _, y in { 6, 13, 21, 28 } do
		Kit.neon(ctx, m, "TiraLuz", V(0.7, 0.15, z1 - z0 - 1), CF(s.X0 + 6, y, (z0 + z1) / 2), C.Cyan, 0.3)
	end
	-- Barandillas de cristal del carril abierto (tramos B: se ven desde el vestíbulo)
	for k = 2, s.Flights, 2 do
		local yTop = s.Y0 + k * s.Rise
		local yBot = yTop - s.Rise
		Kit.railing(ctx, m, V(s.X0 + 0.2, yBot, z1), V(s.X0 + 0.2, yTop, z0 + 0.2))
	end
	-- Pared del fondo de la escalera (con un mural de ecuaciones y fotos a lo alto)
	Kit.box(ctx, m, "InnerWall", V(s.X1 - s.X0, F1 - F0, 0.6), CF((s.X0 + s.X1) / 2, (F0 + F1) / 2, z1 + s.Far + 0.3), C.WallWarm, M.Plaster, { CanQuery = true })
	local mural = Kit.wallScreen(ctx, m, CF(-6, 11.5, z1 + s.Far - 0.05), 8, 4.5, "Equations")
	mural.Name = "Mural"
	Furniture.picture(Kit.furn(ctx, m), at(ctx, -9, 4.5, z1 + s.Far - 0.05), 2.2, 2.6, m)
	Furniture.picture(Kit.furn(ctx, m), at(ctx, -3, 4.5, z1 + s.Far - 0.05), 2.2, 2.6, m)
	-- Aro de luz colgando en el hueco (se ve desde todas las plantas)
	local ring = Kit.cyl(ctx, m, "AroHueco", 0.5, 9, CF(-6, 38.5, -15.5), rgb(255, 240, 210), M.Neon)
	ring.CastShadow = false
	Kit.cyl(ctx, m, "AroHuecoDentro", 0.52, 8, CF(-6, 38.5, -15.5), C.Dark)
	for _, a in { 0, 2.1, 4.2 } do
		Kit.deco(ctx, m, "Cable", V(0.08, 5.6, 0.08), CF(-6 + math.cos(a) * 4.3, 41.4, -15.5 + math.sin(a) * 4.3), C.Dark, nil, nil, true)
	end
	Kit.light(ctx, ring, 40, 1.3, rgb(255, 236, 200), "Escalera")
	Kit.anomaly(ring)
	Kit.anomaly(m:FindFirstChild("AroHuecoDentro") :: Instance)
	return m
end

---------------------------------------------------------------------
-- Planta baja
---------------------------------------------------------------------
local function groundFloor(ctx: Kit.Ctx, parent: Instance)
	local g = Kit.group(parent, "PlantaBaja")
	local y = F0
	-- Tabiques
	local walls = Kit.group(g, "Tabiques")
	partition(ctx, walls, "Z", -20, -32, -6, y, CG, { op(-22, -16, y, y + 9.5) })
	partition(ctx, walls, "X", -6, -34, -20, y, CG)
	partition(ctx, walls, "Z", 0, -32, -6, y, CG, { op(-31.5, -25.5, y, y + 9.5) }, rgb(220, 224, 230))
	partition(ctx, walls, "X", -6, 0, 12, y, CG)
	partition(ctx, walls, "Z", -12, -6, 18, y, CG, { op(-2, 12, y, y + 11) })
	partition(ctx, walls, "Z", 0, -6, 4, y, CG, { op(-3, 3, y, y + 9.5) })
	partition(ctx, walls, "X", 4, 0, 12, y, CG)
	Kit.door(ctx, walls, -20, y, -19, 90, 6, 9.3, rgb(120, 84, 56), true)
	Kit.door(ctx, walls, 0, y, -28.5, -90, 6, 9.3, rgb(70, 74, 84), true)
	Kit.door(ctx, walls, 0, y, 0, 90, 6, 9.3, C.White, false)
	Kit.door(ctx, walls, 12, y, -28.5, -90, 6, 9.3, rgb(70, 74, 84), true)
	local sotano = Kit.deco(ctx, walls, "CartelSotano", V(5, 1.2, 0.1), CF(-0.4, 11.3, -28.5) * ANG(0, math.pi / 2, 0), rgb(240, 200, 40), nil, nil, true)
	Kit.signText(sotano, "SÓTANO · GARAJE", Enum.NormalId.Front, rgb(30, 30, 30), rgb(240, 200, 40))

	---------------------------------------------------------------- Vestíbulo
	local hall = Kit.group(g, "Vestibulo")
	overlay(ctx, hall, "HallFloor", -20, 0, -32, -6, y, rgb(214, 208, 196), M.Marble)
	rug(ctx, hall, -16, y + 0.06, -26, 6.5, 7, rgb(40, 52, 80), rgb(150, 200, 255))
	Kit.ceilingLamp(ctx, hall, -16, CG, -20, "Vestibulo", "Ring")
	Kit.ceilingLamp(ctx, hall, -16, CG, -10, "Vestibulo")
	Kit.switch(ctx, hall, -19.6, y + 4, -30.5, -90, "Vestibulo")
	-- Perchero con la bata de repuesto, sombrero y paraguas; zapatos en el suelo
	local rack = Kit.group(hall, "Perchero")
	Kit.cyl(ctx, rack, "Pie", 0.3, 1.6, CF(-19, y + 0.15, -30.6), C.Dark, M.Metal)
	Kit.cyl(ctx, rack, "Palo", 6.5, 0.3, CF(-19, y + 3.4, -30.6), C.WoodDark, M.Wood, true)
	Kit.deco(ctx, rack, "Bata", V(1.6, 3.6, 0.8), CF(-19, y + 4.6, -30.1), rgb(240, 240, 232), M.Fabric)
	Kit.deco(ctx, rack, "Quemadura", V(0.6, 0.6, 0.05), CF(-19.3, y + 4, -29.68), rgb(60, 50, 40), M.Fabric)
	Kit.cyl(ctx, rack, "Sombrero", 0.5, 1.4, CF(-19, y + 6.9, -30.6), rgb(60, 40, 90), M.Fabric)
	for i = 0, 2 do
		for side = -1, 1, 2 do
			Kit.deco(ctx, hall, "Zapato", V(1, 0.4, 0.5), CF(-19.3, y + 0.2, -27.5 + i * 1.4 + side * 0.3), ({ C.Dark, rgb(120, 70, 40), rgb(200, 60, 50) })[i + 1])
		end
	end
	-- Consola con llaves, cajas y planos, fotos, reloj raro, plantas
	local console = Kit.box(ctx, hall, "Consola", V(1.6, 3, 5), CF(-19.1, y + 1.5, -14), C.WoodDark, M.Wood)
	Props.scatter(ctx, hall, { -19.8, -18.4, -16.4, -11.6 }, y + 3, 5, { "Papers", "Gadget", "Mug", "Bulb", "Chip" })
	for i, z in { -27, -22, -8 } do
		Furniture.picture(Kit.furn(ctx, hall), at(ctx, -19.65, y + 6.5 + (i % 2), z, -90), 2.2, 2.8, hall)
	end
	local blueprint = Kit.deco(ctx, hall, "PlanoEnmarcado", V(0.15, 3, 4.4), CF(-19.62, y + 6, -12), rgb(40, 80, 170), nil, nil, true)
	Kit.screen(ctx, blueprint, "Plans", Enum.NormalId.Right)
	Kit.doc(blueprint, "Plano enmarcado", "«MÁQUINA LUNAR · versión 12». Hay tachones por todas partes. En una esquina: «Falta: 1 condensador de grieta, 3 bobinas cuánticas y valor».", "CosmePlanoLunar")
	Furniture.clock(Kit.furn(ctx, hall), at(ctx, -19.7, y + 11, -15, -90), hall)
	Props.make(ctx, hall, "Plant", CF(-11, y, -31))
	Props.make(ctx, hall, "Plant", CF(-13, y, -7.5))
	local photo = Kit.deco(ctx, hall, "FotoAntigua", V(0.12, 2, 2.6), CF(-19.65, y + 9.5, -18) , rgb(150, 120, 90), M.Wood, nil, true)
	Kit.doc(photo, "Foto antigua", "Dos científicos jóvenes delante de una máquina enorme. Uno es Cosme, con el pelo todavía oscuro. El otro lleva perilla y sonríe como en un anuncio. Detrás pone: «Cosme y Cósimo. Día 1 del proyecto Grieta».", "CosmeFotoCosimo")
	-- Un robot pequeño que pasa por el suelo del vestíbulo
	Kit.robot(ctx, hall, -16, y + 0.06, -30, "Mini", { { -16, -30 }, { -16, -10 }, { -14, -16 }, { -18, -24 } }, 2.4)
	-- Rincón bajo la escalera: trastos
	local nook = Kit.group(hall, "BajoEscalera")
	for i = 0, 3 do
		Props.make(ctx, nook, if i % 2 == 0 then "Crate" else "Barrel", CF(-9.5 + (i % 2) * 2.2, y, -22 + i * 2.3))
	end
	Props.make(ctx, nook, "CableRun", CF(-9, y, -14))

	---------------------------------------------------------------- Despacho (y la torre)
	local office = Kit.group(g, "Despacho")
	rug(ctx, office, -27, y, -19, 8, 10, rgb(110, 40, 40))
	Kit.ceilingLamp(ctx, office, -27, CG, -19, "Despacho")
	Kit.ceilingLamp(ctx, office, -39, CG, -22, "Despacho", "Industrial")
	Kit.switch(ctx, office, -20.4, y + 4, -14.5, 90, "Despacho")
	-- Mesa con tres monitores (ecuaciones, mapa y planos) y su silla
	local furn = Kit.furn(ctx, office, rgb(90, 62, 40))
	local desk = Furniture.desk(furn, at(ctx, -27, y, -10, 0), { Width = 8, Computer = false, Chair = true }, office)
	desk.Name = "MesaDespacho"
	local kinds = { "Equations", "Map", "Plans" }
	for i = -1, 1 do
		local screen = Kit.monitor(ctx, office, CF(-27 + i * 2.7, y + 3.02, -9.6) * ANG(0, i * -0.25, 0), 2.4, 1.6, kinds[i + 2])
		if i == 0 then
			Furniture.usable(screen, "Computer", { On = true })
		end
	end
	Props.scatter(ctx, office, { -30.8, -23.2, -11.2, -10.6 }, y + 3.02, 3, { "Mug", "Papers", "Keyboard" })
	local hint1 = Kit.deco(ctx, office, "DocumentoMision", V(1.2, 0.04, 1.6), CF(-30, y + 3.05, -9.6) * ANG(0, 0.3, 0), rgb(250, 246, 230), nil, nil, true)
	Kit.doc(hint1, "Informe «Componentes perdidos»", "Lista de componentes que faltan para la máquina del espacio-tiempo:\n• Condensador de grieta (lo tiene un pez contable)\n• Bobina cuántica (en la granja de Julián, dentro de una gallina, creo)\n• Cristal de los Pliegues (no tocar con la mano)\n\nNota: pedir ayuda a la criatura de al lado.", "CosmeComponentes")
	-- Caja fuerte (se abre y dentro hay una pista)
	local safe = Kit.group(office, "CajaFuerte")
	Kit.box(ctx, safe, "Cuerpo", V(3, 3.4, 2.6), CF(-32.4, y + 1.7, -30.4), rgb(60, 64, 72), M.DiamondPlate)
	local safeDoor = Kit.box(ctx, safe, "Puerta", V(2.6, 3, 0.2), CF(-32.4, y + 1.7, -29.0), rgb(80, 84, 92), M.Metal, { CanCollide = false })
	safeDoor:SetAttribute("Hinge", at(ctx, -33.7, y + 1.7, -29.0))
	safeDoor:SetAttribute("Closed", safeDoor.CFrame)
	safeDoor:SetAttribute("Swing", math.rad(-100))
	Kit.cylX(ctx, safe, "Rueda", 0.2, 1.2, CF(-32.4, y + 1.9, -28.8) * ANG(0, math.pi / 2, 0), C.Chrome, M.Metal)
	Kit.prompt(safeDoor, "Abrir la caja fuerte", "🔐 Caja fuerte", "Safe", { Title = "Dentro de la caja fuerte", Text = "Un sobre: «PARA LA CRIATURA, SI ME PASA ALGO». Dentro, unas coordenadas: X 66 · Y -B · Z ∞, y un dibujo de una puerta detrás de una estantería del sótano con tres libros marcados: FÍSICA, TIEMPO, LUNA.", PropId = "CosmeCajaFuerte" })
	-- Archivador con cajones que se abren, estanterías, pizarra, fotos de lugares extraños
	local cab = Kit.group(office, "Archivador")
	Kit.box(ctx, cab, "Cuerpo", V(2.4, 4.4, 2.2), CF(-22, y + 2.2, -30.6), C.Steel, M.Metal)
	for k = 0, 2 do
		local drawer = Kit.box(ctx, cab, "Cajon", V(2, 1.2, 1.8), CF(-22, y + 0.9 + k * 1.35, -30.3), rgb(176, 182, 190), M.Metal, { CanCollide = false })
		Kit.deco(ctx, cab, "Tirador", V(0.8, 0.12, 0.12), CF(-22, y + 1.2 + k * 1.35, -29.38), C.Dark, M.Metal):SetAttribute("FollowDrawer", drawer.Name .. k)
		drawer.Name = "Cajon" .. k
		drawer:SetAttribute("SlideDir", ctx.Site:VectorToWorldSpace(V(0, 0, 1)))
		Kit.prompt(drawer, "Abrir el cajón", "🗄️ Archivador", "Drawer", { Slide = 1.6, Text = ({ "Fichas: «Anomalía 14: lluvia hacia arriba en el parque».", "Fotos de un pez con corbata.", "Recibos de 200 batidos de apio." })[k + 1] })
	end
	Props.shelf(ctx, office, CF(-27, y, -7.0), 8, 9)
	Furniture.whiteboard(Kit.furn(ctx, office), at(ctx, -33.5, y - 1.5, -16, -90), 5, office)
	for i, kind in { "Stars", "Anomalies", "Map" } do
		local foto = Kit.wallScreen(ctx, office, CF(-26.5 + i * 3.2, y + 9.5, -31.45) * ANG(0, math.pi, 0), 2.6, 2, kind)
		foto.Name = "FotoLugarExtrano"
	end
	local hint2 = Kit.deco(ctx, office, "Expediente", V(1.4, 0.3, 1.8), CF(-21.6, y + 4.55, -30.6), rgb(200, 160, 90), nil, nil, true)
	Kit.doc(hint2, "Expediente «Valmar 2»", "Tres Valmar distintas vistas a la vez desde la torre. En una todo es gris y nadie inventa nada. «Si alguna vez la encuentro, no me quedaré allí. O sí. No lo sé.»", "CosmeExpediente")
	-- Torre: sillón de leer, globo terráqueo con la luna pegada y un telescopio pequeño
	local tf = Kit.furn(ctx, office, nil, rgb(120, 60, 50))
	Furniture.armchair(tf, at(ctx, -42, y, -25, 135), rgb(120, 60, 50), office)
	local globe = Kit.group(office, "Globo")
	Kit.cyl(ctx, globe, "Pie", 2.6, 0.3, CF(-38, y + 1.3, -27), C.WoodDark, M.Wood, true)
	Kit.ball(ctx, globe, "Tierra", 1.8, CF(-38, y + 3.3, -27), rgb(60, 120, 200), M.SmoothPlastic)
	Kit.ball(ctx, globe, "Luna", 0.5, CF(-37, y + 4.3, -27), rgb(220, 220, 220), M.Slate)
	Props.make(ctx, office, "Lamp", CF(-44, y, -19))
	Props.scatter(ctx, office, { -33, -21, -26, -13 }, y, 6, { "Book", "Papers", "Blueprint", "CableRun" })

	---------------------------------------------------------------- Sala de estar
	local living = Kit.group(g, "Salon")
	rug(ctx, living, -24, y, 4, 12, 9, rgb(70, 80, 110))
	Kit.ceilingLamp(ctx, living, -24, CG, 0, "Salon", "Ring")
	Kit.ceilingLamp(ctx, living, -24, CG, 12, "Salon")
	Kit.switch(ctx, living, -12.4, y + 4, -4, 90, "Salon")
	local lf = Kit.furn(ctx, living, rgb(110, 80, 52), rgb(196, 170, 140), C.Cyan)
	Furniture.sofa(lf, at(ctx, -24, y, 8.2, 0), rgb(196, 170, 140), 4, living)
	Furniture.armchair(lf, at(ctx, -31, y, 2, -60), rgb(110, 90, 140), living)
	Furniture.coffeeTable(lf, at(ctx, -25, y, 3.4), 5, 2.6, living)
	-- La tele: solo da gráficos científicos
	local tv = Kit.wallScreen(ctx, living, CF(-24, y + 6, -5.65) * ANG(0, math.pi, 0), 9, 5, "Graph")
	tv.Name = "TeleCientifica"
	Kit.prompt(tv, "Ver la tele", "📺 Canal de ecuaciones", "Screen", { Title = "Canal 66: Ciencia sin pausa", Text = "Hoy en el canal 66: «Cómo doblar el espacio-tiempo con una pinza de la ropa». Le sigue: «Grietas en el cielo: ¿hay que preocuparse? (Sí)».", PropId = "CosmeTele" })
	Kit.box(ctx, living, "MuebleTele", V(8, 2, 2), CF(-24, y + 1, -5), C.WoodDark, M.Wood)
	Props.scatter(ctx, living, { -27.6, -20.4, -5.8, -4.2 }, y + 2, 4, { "Radio", "Gadget", "Book", "Plant" })
	-- Mando raro en la mesa (enciende el portal defectuoso de la esquina)
	local remote = Kit.deco(ctx, living, "MandoRaro", V(0.6, 0.25, 1.4), CF(-24, y + 1.62, 3.4) * ANG(0, 0.4, 0), rgb(60, 60, 70), nil, nil, true)
	Kit.neon(ctx, living, "BotonMando", V(0.3, 0.1, 0.3), CF(-24, y + 1.78, 3.4), C.Magenta)
	Kit.prompt(remote, "Pulsar el mando raro", "🎛️ Mando raro", "Experiment", { Effect = "MiniPortal", Target = "PortalDefectuoso", Text = "En la esquina se abre un portal chiquitito… y se cierra con un hipido. Huele a palomitas de otra dimensión." })
	Props.scatter(ctx, living, { -27.2, -25, 2.6, 4.2 }, y + 1.5, 3, { "Mug", "Book", "Food" })
	-- Máquina junto al sofá (la «máquina de siestas»)
	local napper = Kit.group(living, "MaquinaSiestas")
	Kit.box(ctx, napper, "Cuerpo", V(2.4, 4.4, 2.4), CF(-17.2, y + 2.2, 8), rgb(150, 156, 170), M.Metal)
	local dome = Kit.ball(ctx, napper, "Cupula", 2, CF(-17.2, y + 4.8, 8), C.Cyan, M.Neon, 0.3)
	for k = 0, 2 do
		Kit.neon(ctx, napper, "Piloto", V(0.3, 0.3, 0.1), CF(-17.8 + k * 0.6, y + 3, 6.75), ({ C.Red, C.Yellow, C.Green })[k + 1])
	end
	Kit.spin(napper:FindFirstChild("Cupula") :: Instance, 0.2, "Y")
	Kit.prompt(dome, "Encender", "🌀 Máquina de siestas", "Machine", { Target = "MaquinaSiestas", Text = "La máquina hace «bzzzt» y el sofá parece de repente MUY cómodo." })
	-- Lámpara experimental (bola de plasma en un trípode) y pared de ecuaciones
	local lamp = Kit.group(living, "LamparaExperimental")
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		Kit.deco(ctx, lamp, "Pata", V(0.2, 5.4, 0.2), CF(-32.4 + math.cos(a) * 0.7, y + 2.6, 11 + math.sin(a) * 0.7) * ANG(math.cos(a) * 0.15, 0, -math.sin(a) * 0.15), C.Dark, M.Metal)
	end
	local plasma = Kit.ball(ctx, lamp, "Plasma", 1.8, CF(-32.4, y + 6, 11), C.Magenta, M.Neon, 0.25)
	Kit.light(ctx, plasma, 14, 1, C.Magenta, "Salon")
	Kit.fx(plasma, "Energy", 6)
	local eq1 = Kit.wallScreen(ctx, living, CF(-30.5, y + 7.5, -5.65) * ANG(0, math.pi, 0), 5, 4.5, "Equations")
	eq1.Name = "ParedEcuaciones"
	Kit.wallScreen(ctx, living, CF(-16, y + 9, -5.65) * ANG(0, math.pi, 0), 5, 3.5, "Equations").Name = "ParedEcuaciones"
	local poster = Kit.deco(ctx, living, "Poster", V(0.15, 4, 3.2), CF(-12.38, y + 7, 15), rgb(20, 30, 60), nil, nil, true)
	Kit.signText(poster, "LA REALIDAD ES SOLO UNA OPCIÓN", Enum.NormalId.Left, rgb(150, 220, 255), rgb(20, 30, 60))
	-- Estanterías con libros e inventos
	Props.shelf(ctx, living, CF(-18, y, 17.1) * ANG(0, 0, 0), 7, 8, "Lab")
	for _, p in { { -33, -4.5 }, { -13.5, 16.6 } } do
		Props.make(ctx, living, "Plant", CF(p[1], y, p[2]))
	end
	-- Portal defectuoso en la esquina (aparece unos segundos de vez en cuando: el cliente lo enciende)
	local broken = PortalSystem.build(ctx, living, CF(-32.4, y + 2.9, 15.4) * ANG(0, -math.pi / 2, 0), 1.6, { Name = "PortalDefectuoso", Color = C.Magenta, Depth = 0.9, Layers = 7, Broken = true, NoCoils = true, Stand = 0.5, Destination = 4 })
	broken:AddTag("CosmeFlicker")
	Props.scatter(ctx, living, { -33, -14, -5, 17 }, y + 0.08, 5, { "Book", "Clothes", "CableRun", "Gadget" })

	---------------------------------------------------------------- Comedor
	local dining = Kit.group(g, "Comedor")
	overlay(ctx, dining, "Floor", -12, 0, -6, 18, y, rgb(196, 160, 118), M.WoodPlanks)
	Kit.ceilingLamp(ctx, dining, -5, CG, 9, "Comedor", "Industrial")
	Kit.ceilingLamp(ctx, dining, -5, CG, 0, "Comedor")
	Kit.switch(ctx, dining, -11.6, y + 4, 14, -90, "Comedor")
	local df = Kit.furn(ctx, dining, rgb(110, 80, 52))
	local table_ = Furniture.table(df, at(ctx, -5, y, 9), 4, 7, rgb(110, 80, 52), dining)
	table_.Name = "MesaComedor"
	for _, p in { { -8.3, 7 }, { -8.3, 11 }, { -1.7, 7 }, { -1.7, 11 } } do
		Furniture.chair(df, at(ctx, p[1], y, p[2], if p[1] < -5 then -90 else 90), rgb(40, 40, 46), dining)
	end
	Props.scatter(ctx, dining, { -6.6, -3.4, 6, 12 }, y + 3.15, 6, { "Food", "Mug", "Bottle", "Papers", "Gadget" })
	Furniture.picture(Kit.furn(ctx, dining), at(ctx, -6, y + 7, -5.35, 180), 4, 3, dining)
	local comida = Kit.deco(ctx, dining, "CartelComida", V(3, 3.8, 0.12), CF(-1.6, y + 7.5, 17.4), rgb(250, 248, 240), nil, nil, true)
	Kit.signText(comida, "COMIDA = ENERGÍA\n(e=mc²)", Enum.NormalId.Front, rgb(40, 40, 60), rgb(250, 248, 240))
	Props.make(ctx, dining, "Plant", CF(-11, y, -5))

	---------------------------------------------------------------- Cocina
	local kitchen = Kit.group(g, "Cocina")
	overlay(ctx, kitchen, "TileFloor", 0, 12, 4, 18, y, rgb(226, 230, 232), M.Marble)
	Kit.ceilingLamp(ctx, kitchen, 6, CG, 11, "Cocina", "Bar")
	Kit.switch(ctx, kitchen, 0.5, y + 4, 4.4, 180, "Cocina")
	local kf = Kit.furn(ctx, kitchen)
	Furniture.kitchenRun(kf, at(ctx, 10.7, y, 11, 90), 12, kitchen)
	Furniture.kitchenRun(kf, at(ctx, 5, y, 16.7, 0), 7, kitchen)
	-- Nevera con pantalla
	local fridge = Kit.group(kitchen, "NeveraPantalla")
	Kit.box(ctx, fridge, "Cuerpo", V(3.4, 7.4, 2.8), CF(1.9, y + 3.7, 5.5), rgb(200, 206, 212), M.Metal)
	Kit.deco(ctx, fridge, "Junta", V(3.42, 0.1, 2.82), CF(1.9, y + 5, 5.5), C.Dark)
	local fscreen = Kit.deco(ctx, fridge, "Pantalla", V(0.05, 1.6, 1.4), CF(3.63, y + 4.8, 5.5), rgb(30, 40, 60), M.SmoothPlastic, nil, true)
	Kit.screen(ctx, fscreen, "Text", Enum.NormalId.Right, "Batidos de apio: 3\nMoral: alta")
	Kit.prompt(fscreen, "Mirar la pantalla", "🧊 Nevera con pantalla", "Doc", { Title = "Nevera con pantalla", Text = "«Hola, criatura. Quedan 3 batidos de apio cuántico, 1 lasaña cuadrada y un tarro que dice NO ABRIR HASTA EL AÑO QUE VIENE (lo abrí ayer).»", PropId = "CosmeNevera" })
	-- Cafetera modificada (vapor), microondas temporal, impresora de comida, botellas raras
	local coffee = Kit.group(kitchen, "CafeteraModificada")
	Kit.box(ctx, coffee, "Cuerpo", V(1.6, 2, 1.4), CF(10.8, y + 4.65, 13), rgb(60, 60, 70), M.Metal)
	local spout = Kit.cyl(ctx, coffee, "Chimenea", 1.4, 0.5, CF(10.8, y + 6.3, 13.2), C.Chrome, M.Metal)
	Kit.neon(ctx, coffee, "Bobina", V(1.7, 0.2, 1.5), CF(10.8, y + 5.2, 13), C.Orange)
	Kit.fx(spout, "Steam", 5)
	Kit.prompt(spout, "Hacer café", "☕ Cafetera modificada", "Experiment", { Effect = "Coffee", Text = "La cafetera sirve el café de ayer. Literalmente: viaja 24 horas atrás. Está frío, pero puntual." })
	local micro = Kit.group(kitchen, "MicroondasTemporal")
	Kit.box(ctx, micro, "Cuerpo", V(1.8, 1.4, 2.6), CF(10.9, y + 4.4, 7), C.White, M.Metal)
	local mglass = Kit.deco(ctx, micro, "Puerta", V(0.05, 1, 1.6), CF(9.98, y + 4.4, 6.8), C.Dark, M.Glass, nil, true)
	Kit.neon(ctx, micro, "Reloj", V(0.05, 0.3, 0.5), CF(9.98, y + 4.7, 8), C.Green)
	Kit.prompt(mglass, "Usar el microondas", "⏲️ Microondas temporal", "Experiment", { Effect = "Zap", Text = "El reloj del microondas marca -00:30. Lo que metes sale más crudo que antes. Es un microondas temporal." })
	local printer = Kit.group(kitchen, "ImpresoraComida")
	Kit.box(ctx, printer, "Cuerpo", V(2.6, 2.6, 2.2), CF(5, y + 4.95, 16.6), rgb(230, 232, 236), M.SmoothPlastic)
	Kit.neon(ctx, printer, "Boquilla", V(0.3, 0.6, 0.3), CF(5, y + 4.6, 15.6), C.Orange)
	Kit.prompt(printer:FindFirstChild("Cuerpo") :: BasePart, "Imprimir comida", "🖨️ Impresora de comida", "Experiment", { Effect = "Printer", Text = "La impresora imprime una lasaña perfectamente cuadrada. Sabe a lasaña. Y un poco a tinta." })
	local shelfK = Kit.box(ctx, kitchen, "Balda", V(1, 0.25, 9), CF(11.4, y + 8, 11), C.WoodDark, M.Wood)
	shelfK.CanCollide = false
	for i = 0, 6 do
		Props.make(ctx, kitchen, if i % 2 == 0 then "Bottle" else "Jar", CF(11.4, y + 8.125, 7 + i * 1.3))
	end
	local labels = Kit.deco(ctx, kitchen, "EtiquetaBotellas", V(0.05, 0.6, 3), CF(10.85, y + 7.6, 11), rgb(250, 248, 230), nil, nil, true)
	Kit.signText(labels, "ZUMO DE ANTIMATERIA · NO BEBER", Enum.NormalId.Left, rgb(160, 40, 40), rgb(250, 248, 230))
	Props.scatter(ctx, kitchen, { 9.6, 11.8, 8.5, 16 }, y + 3.65, 3, { "Mug", "Food", "Bottle" })
	-- Robots pequeños que van y vienen por la encimera
	Kit.robot(ctx, kitchen, 10.7, y + 3.65, 9, "Mini", { { 10.7, 9 }, { 10.7, 15 } }, 1.2)
	Kit.robot(ctx, kitchen, 3, y + 3.65, 16.5, "Mini", { { 2.5, 16.5 }, { 7.5, 16.5 } }, 1)
	Props.make(ctx, kitchen, "Plant", CF(1, y, 17))

	---------------------------------------------------------------- Baño de abajo
	local bath = Kit.group(g, "Aseo")
	overlay(ctx, bath, "TileFloor", 0, 12, -6, 4, y, rgb(200, 214, 220), M.Marble)
	Kit.ceilingLamp(ctx, bath, 6, CG, -1, "Aseo")
	Kit.switch(ctx, bath, 0.4, y + 4, 3.4, -90, "Aseo")
	local bf = Kit.furn(ctx, bath)
	Furniture.toilet(bf, at(ctx, 10.6, y, -4.4, 90), bath)
	Furniture.vanity(bf, at(ctx, 4.5, y, 3.1, 0), "Aseo", bath)
	Furniture.shower(bf, at(ctx, 9.4, y, 1.2, 0), 4, bath)
	Furniture.towelRail(bf, at(ctx, 3.5, y, -5.6, 180), bath)
	local brush = Kit.group(bath, "CepilloInventado")
	Kit.deco(ctx, brush, "Cepillo3000", V(0.3, 1.2, 0.3), CF(5.8, y + 3.6, 3.2), C.Cyan, M.Neon)
	Kit.doc(Kit.deco(ctx, bath, "Instrucciones", V(1, 1.4, 0.05), CF(2.6, y + 5.5, 3.6), rgb(250, 248, 240), nil, nil, true), "Instrucciones del cepillo 3000", "«Cepillo de dientes cuántico. Limpia los dientes que tienes y los que tendrás. No usar en dimensiones con dientes de más.»")

	---------------------------------------------------------------- Bajada al sótano (rellano de arriba)
	local down = Kit.group(g, "BajadaSotano")
	overlay(ctx, down, "Floor", 0, 12, -32, -25, y, rgb(150, 150, 146), M.Concrete)
	for i = 0, 5 do
		Kit.deco(ctx, down, "Franja", V(1, 0.02, 0.6), CF(0.5 + i * 2, y + 0.07, -25.4) * ANG(0, 0.6, 0), C.Yellow)
	end
	Kit.railing(ctx, down, V(0.4, y, -25), V(5.7, y, -25), 3.4, false)
	local warn = Kit.deco(ctx, down, "Aviso", V(4, 2, 0.1), CF(6, y + 8, -31.4), rgb(240, 200, 40), nil, nil, true)
	Kit.signText(warn, "¡CUIDADO!\nSÓTANO (Y OTRAS COSAS)", Enum.NormalId.Back, rgb(30, 30, 30), rgb(240, 200, 40))
	Kit.ceilingLamp(ctx, down, 6, CG, -28.5, "BajadaSotano", "Industrial")
	Kit.switch(ctx, down, 11.4, y + 4, -30.8, 90, "BajadaSotano")
	for i = 0, 2 do
		Props.make(ctx, down, if i == 1 then "Barrel" else "Crate", CF(1.6 + i * 2.6, y, -31) * ANG(0, i * 0.4, 0))
	end
	Props.make(ctx, down, "CableRun", CF(9, y, -30))
	-- Mangueras de cables que bajan por la pared
	for i = 0, 3 do
		Kit.deco(ctx, down, "CableBajada", V(0.3, CG - y, 0.3), CF(11.3, (CG + y) / 2, -31.3 + i * 0.45), ({ C.Dark, C.Red, C.Blue, C.Yellow })[i + 1], M.Rubber)
	end
	return g
end

---------------------------------------------------------------------
-- Planta alta
---------------------------------------------------------------------
local function upperFloor(ctx: Kit.Ctx, parent: Instance)
	local u = Kit.group(parent, "PlantaAlta")
	local y = F1
	local walls = Kit.group(u, "Tabiques")
	partition(ctx, walls, "Z", -20, -32, -6, y, CU, { op(-22, -16, y, y + 9.5) })
	partition(ctx, walls, "X", -6, -34, -20, y, CU)
	partition(ctx, walls, "Z", -20, -6, 18, y, CU, { op(-2, 4, y, y + 9.5) })
	partition(ctx, walls, "Z", -12, -6, 18, y, CU, { op(-2, 4, y, y + 9.5) })
	partition(ctx, walls, "X", 8, -20, -12, y, CU, { op(-19, -13, y, y + 9.5) })
	partition(ctx, walls, "X", -6, -12, 0, y, CU, { op(-11.5, -0.5, y + 1, CU - 1, "glass") })
	partition(ctx, walls, "X", -6, 0, 12, y, CU)
	partition(ctx, walls, "Z", 0, -32, -6, y, CU, { op(-31.5, -25.5, y, y + 9.5), op(-24, -8, y + 2, y + 12, "glass") }, rgb(40, 44, 54))
	Kit.door(ctx, walls, -20, y, -19, 90, 6, 9.3, rgb(120, 84, 56), true)
	Kit.door(ctx, walls, -20, y, 1, 90, 6, 9.3, rgb(60, 40, 80), true)
	Kit.door(ctx, walls, -12, y, 1, -90, 6, 9.3, rgb(70, 74, 84), true)
	Kit.door(ctx, walls, -16, y, 8, 0, 6, 9.3, C.White, false)
	Kit.door(ctx, walls, 0, y, -28.5, -90, 6, 9.3, rgb(30, 34, 44), true)
	-- Barandilla de la galería sobre el hueco de la escalera
	Kit.railing(ctx, walls, V(-12.2, y, -25), V(-12.2, y, -6.4))

	---------------------------------------------------------------- Pasillo
	local hall = Kit.group(u, "Pasillo")
	rug(ctx, hall, -16, y, -12, 4, 30, rgb(120, 40, 50))
	Kit.ceilingLamp(ctx, hall, -16, CU, -24, "Pasillo")
	Kit.ceilingLamp(ctx, hall, -16, CU, -2, "Pasillo")
	Kit.switch(ctx, hall, -19.6, y + 4, -26, -90, "Pasillo")
	for i, z in { -28, -4, 6 } do
		Furniture.picture(Kit.furn(ctx, hall), at(ctx, -19.65, y + 6.5, z, -90), 2.6, 2.2, hall)
	end
	Props.make(ctx, hall, "Plant", CF(-19, y, -31))
	local corkboard = Kit.deco(ctx, hall, "TableroCorcho", V(0.15, 4, 6), CF(-19.62, y + 6.5, -11), rgb(190, 150, 100), M.Fabric, nil, true)
	Props.postits(ctx, hall, CF(-19.5, y + 6.5, -11) * ANG(0, -math.pi / 2, 0), 5, 3.4, 9)
	Kit.doc(corkboard, "Tablero de corcho", "Pósits por todas partes:\n«Comprar apio» · «Arreglar el portal del salón (otra vez)» · «¿La luna tiene garaje?» · «NO dejar a Pip solo con el microondas» · «La criatura de al lado tiene talento. Vigilar.»", "CosmeCorcho")
	Kit.robot(ctx, hall, -16, y + 0.08, -28, "Limpiador", { { -16, -28 }, { -16, 5 } }, 1.8)

	---------------------------------------------------------------- Biblioteca científica (y la torre)
	local lib = Kit.group(u, "Biblioteca")
	Kit.ceilingLamp(ctx, lib, -27, CU, -19, "Biblioteca", "Ring")
	Kit.ceilingLamp(ctx, lib, -39, CU, -22, "Biblioteca")
	Kit.switch(ctx, lib, -20.4, y + 4, -23, 90, "Biblioteca")
	rug(ctx, lib, -27, y, -19, 9, 9, rgb(60, 50, 90), rgb(240, 200, 120))
	-- Estanterías altas (una por tema) y libros interactivos
	local topics = {
		{ "FÍSICA", -28, -6.95, 0, 10 },
		{ "MATEMÁTICAS", -20.9, -27.5, 90, 7 },
		{ "ASTRONOMÍA", -20.9, -10.5, 90, 6 },
		{ "INGENIERÍA", -31.6, -9.5, 0, 0 },
	}
	for i, t in topics do
		if t[5] > 0 then
			local sh = Props.shelf(ctx, lib, CF(t[2], y, t[3]) * ANG(0, math.rad(t[4]), 0), t[5], 12)
			sh.Name = "Estanteria_" .. t[1]
			local tag = Kit.deco(ctx, sh, "Rotulo", V(3, 0.7, 0.1), CF(t[2], y + 12.5, t[3]) * ANG(0, math.rad(t[4]), 0) * CF(0, 0, -0.9), C.Dark, nil, nil, true)
			Kit.signText(tag, t[1], Enum.NormalId.Front, rgb(240, 220, 160), C.Dark)
		end
	end
	local bookTexts = {
		{ "Física para inventores impacientes", "Capítulo 1: «Si funciona a la primera, es que no lo has entendido». Capítulo 2: «Si no funciona, súbele la potencia».", "CosmeLibroFisica" },
		{ "El espacio-tiempo, doblado como una servilleta", "Subrayado a mano: «Una grieta es una arruga en la servilleta. Si tiras del borde correcto, se cierra. Si tiras del incorrecto, sale un pez».", "CosmeLibroTiempo" },
		{ "Atlas de la Luna", "Un mapa de la luna con una cruz roja y una nota: «Aquí aparcaré. Hay sitio».", "CosmeLibroLuna" },
		{ "Programación para robots con sentimientos", "Página doblada: «Si tu robot pregunta para qué sirve, abrázalo. Luego revisa sus tornillos».", "CosmeLibroRobots" },
	}
	for i, b in bookTexts do
		local book = Kit.deco(ctx, lib, "LibroInteractivo", V(0.5, 1.7, 1.2), CF(-31 + i * 2, y + 0.2 + 2.2 * i + 0.95, -7.3), ({ C.Red, C.Blue, C.Yellow, C.Green })[i], nil, nil, true)
		Kit.neon(ctx, lib, "BrilloLibro", V(0.52, 0.2, 1.22), CF(-31 + i * 2, y + 0.2 + 2.2 * i + 1.6, -7.3), C.Cyan, 0.3)
		Kit.doc(book, b[1], b[2], b[3])
	end
	-- Escalera de biblioteca, mesa de lectura con lámpara, sillones y globo celeste
	local ladder = Kit.group(lib, "EscaleraBiblioteca")
	for _, x in { -24.5, -22.5 } do
		Kit.deco(ctx, ladder, "Larguero", V(0.25, 12.4, 0.25), CF(x, y + 6, -8.6) * ANG(-0.15, 0, 0), C.WoodDark, M.Wood)
	end
	for k = 1, 10 do
		Kit.deco(ctx, ladder, "Peldano", V(2.2, 0.2, 0.25), CF(-23.5, y + k * 1.15, -8.6 + 0.17 * (k - 6)), C.WoodDark, M.Wood)
	end
	local lf = Kit.furn(ctx, lib, rgb(90, 62, 40), rgb(130, 60, 50))
	Furniture.table(lf, at(ctx, -27, y, -24), 5, 3.2, rgb(90, 62, 40), lib)
	Props.scatter(ctx, lib, { -29.2, -24.8, -25.4, -22.6 }, y + 3.15, 6, { "Book", "Papers", "Lamp", "Mug", "Blueprint" })
	Furniture.chair(lf, at(ctx, -27, y, -27, 180), rgb(90, 62, 40), lib)
	Furniture.armchair(lf, at(ctx, -41, y, -27, 150), rgb(130, 60, 50), lib)
	Furniture.armchair(lf, at(ctx, -42.5, y, -17, 30), rgb(130, 60, 50), lib)
	local celestial = Kit.group(lib, "GloboCeleste")
	Kit.cyl(ctx, celestial, "Pie", 3, 0.3, CF(-40, y + 1.5, -22), C.WoodDark, M.Wood, true)
	Kit.ball(ctx, celestial, "Esfera", 2.4, CF(-40, y + 4.1, -22), rgb(20, 30, 70), M.Glass, 0.3)
	Kit.ball(ctx, celestial, "Estrella", 0.5, CF(-40, y + 4.1, -22), C.Yellow, M.Neon)
	-- Estantes curvos en la torre (uno por lado)
	local T = Layout.Tower
	for i = 0, 15 do
		local theta = (i + 0.5) / 16 * math.pi * 2
		if T.X + T.R * math.cos(theta) < Layout.House.X0 - 1.5 and i % 2 == 0 then
			local r = T.R - 1.3
			local cf = CF(T.X + r * math.cos(theta), y, T.Z + r * math.sin(theta)) * ANG(0, -(theta + math.pi / 2) + math.pi, 0)
			Kit.box(ctx, lib, "EstanteTorre", V(3, 2.8, 1.4), cf * CF(0, 1.4, 0), C.WoodDark, M.Wood, { CanQuery = false })
			Props.bookRow(ctx, lib, cf * CF(0, 2.8, 0), 2.6, 1)
		end
	end
	Props.scatter(ctx, lib, { -33, -21, -15, -8 }, y + 0.08, 5, { "Book", "Papers" })
	-- Un libro que flota solo (anomalía)
	local floating = Kit.deco(ctx, lib, "LibroFlotante", V(1.2, 0.25, 1.6), CF(-36, y + 7.5, -22) * ANG(0.3, 0.5, 0.1), C.Purple, nil, nil, true)
	Kit.anomaly(floating)
	Kit.spin(floating, 0.08, "Y")
	Kit.fx(floating, "Dust", 4)

	---------------------------------------------------------------- Sala de ordenadores
	local comp = Kit.group(u, "Ordenadores")
	overlay(ctx, comp, "Floor", 0, 12, -32, -6, y, rgb(40, 44, 54), M.DiamondPlate)
	for _, z in { -27, -15 } do
		local bar = Kit.ceilingLamp(ctx, comp, 6, CU, z, "Ordenadores", "Bar", C.Cyan)
		bar.Color = C.Cyan
	end
	Kit.switch(ctx, comp, 0.4, y + 4, -24.8, -90, "Ordenadores")
	-- Pared de pantallas (3 × 3) sobre la mesa larga, con seis monitores más
	local wallKinds = { "Map", "Coords", "Camera", "Anomalies", "Sim", "Graph", "Camera", "Stars", "Coords" }
	for row = 0, 2 do
		for col = 0, 2 do
			Kit.wallScreen(ctx, comp, CF(11.45, y + 5.2 + row * 3.3, -24 + col * 5) * ANG(0, math.pi / 2, 0), 4.6, 3, wallKinds[row * 3 + col + 1])
		end
	end
	local cdesk = Kit.box(ctx, comp, "MesaLarga", V(3, 0.3, 18), CF(9.6, y + 3, -19), C.Dark, M.Metal)
	for _, z in { -27.5, -10.5 } do
		Kit.box(ctx, comp, "PataMesa", V(2.6, 2.85, 0.4), CF(9.6, y + 1.43, z), C.Dark, M.Metal)
	end
	local monitorKinds = { "Equations", "Map", "Coords", "Sim", "Anomalies", "Graph" }
	for i, kind in monitorKinds do
		local screen = Kit.monitor(ctx, comp, CF(10.2, y + 3.15, -26.5 + i * 2.6) * ANG(0, math.pi / 2, 0), 2.2, 1.5, kind)
		if i == 3 then
			Kit.prompt(screen, "Usar el ordenador", "💻 Ordenador central", "Screen", { Title = "Ordenador central de Cosme", Text = "> ANOMALÍAS ACTIVAS: 7\n> Coordenadas más intensas: 66-B (crece 3 cm cada noche)\n> Cámara del jardín: un pez con corbata mirando la casa\n> Simulación del portal: estable al 66 %\n> Próximo objetivo: «LUNA» (faltan piezas)", PropId = "CosmeOrdenador" })
		end
	end
	Props.scatter(ctx, comp, { 8.4, 10.8, -28, -10 }, y + 3.15, 5, { "Keyboard", "Mug", "Chip", "Papers" })
	local cf = Kit.furn(ctx, comp)
	for _, z in { -24, -20 } do
		Furniture.officeChair(cf, at(ctx, 7.2, y, z, -90), rgb(30, 30, 34), comp)
	end
	-- Servidores con luces, refrigeración y cables
	for i = 0, 3 do
		local rack = Kit.group(comp, "Servidor")
		local x = 1.8 + i * 2.6
		Kit.box(ctx, rack, "Armario", V(2.2, 8, 2.4), CF(x, y + 4, -7.6), rgb(26, 28, 34), M.Metal)
		for k = 0, 9 do
			Kit.neon(ctx, rack, "Led", V(1.6, 0.08, 0.05), CF(x, y + 1 + k * 0.7, -8.82), ({ C.Cyan, C.Green, C.Blue, C.Magenta })[(k + i) % 4 + 1], 0.2)
		end
	end
	local cooler = Kit.group(comp, "Refrigeracion")
	Kit.box(ctx, cooler, "Unidad", V(2.6, 4, 3), CF(10.5, y + 2, -30.4), rgb(200, 205, 210), M.Metal)
	local fan = Kit.cylX(ctx, cooler, "Ventilador", 0.2, 2, CF(10.5, y + 2.6, -28.85) * ANG(0, math.pi / 2, 0), C.Dark)
	Kit.spin(fan, 1.2, "X")
	Kit.fx(Kit.neon(ctx, cooler, "Rejilla", V(2, 0.2, 0.2), CF(10.5, y + 4.1, -30.4), C.Cyan, 0.4), "Steam", 3)
	for i = 0, 3 do
		Props.make(ctx, comp, "CableRun", CF(3 + i * 2, y + 0.08, -12 - i * 3))
	end
	local panel = Kit.wallScreen(ctx, comp, CF(6, y + 10.5, -6.35), 3.6, 2.4, "Graph")
	panel.Name = "PanelControl"

	---------------------------------------------------------------- Habitación de Cosme
	local bed = Kit.group(u, "Dormitorio")
	rug(ctx, bed, -27, y, 6, 8, 10, rgb(60, 70, 120), rgb(170, 200, 255))
	Kit.ceilingLamp(ctx, bed, -27, CU, 6, "Dormitorio", "Ring", rgb(180, 190, 255))
	Kit.switch(ctx, bed, -20.4, y + 4, -3.4, 90, "Dormitorio")
	local bf = Kit.furn(ctx, bed, rgb(70, 60, 80), rgb(60, 70, 120), C.Purple)
	Furniture.bed(bf, at(ctx, -30.4, y, 12, -90), 4.6, bed)
	Furniture.nightstand(bf, at(ctx, -32.8, y, 16.3, -90), nil, bed)
	Furniture.wardrobe(bf, at(ctx, -27, y, -4.7, 180), 6, bed)
	Furniture.desk(bf, at(ctx, -21.4, y, 13, 90), { Width = 6, Computer = true, Chair = false }, bed)
	Props.scatter(ctx, bed, { -22.6, -20.4, 10.2, 15.8 }, y + 3.02, 4, { "Blueprint", "Chip", "Gadget", "Mug" })
	-- Lámpara rara (de lava) en la mesita, ropa tirada, dron, prototipos y libros
	local lava = Kit.group(bed, "LamparaRara")
	Kit.cyl(ctx, lava, "Base", 0.8, 0.9, CF(-32.8, y + 2.6, 15.8), C.Dark, M.Metal)
	local lavaGlass = Kit.cyl(ctx, lava, "Lava", 1.8, 0.8, CF(-32.8, y + 3.9, 15.8), C.Orange, M.Neon, false, 0.25)
	Kit.light(ctx, lavaGlass, 10, 0.8, C.Orange, "Dormitorio")
	for _, p in { { -23, 7 }, { -29, -1 }, { -32, 5 } } do
		Props.make(ctx, bed, "Clothes", CF(p[1], y + 0.08, p[2]))
	end
	Kit.robot(ctx, bed, -27, y + 9, 8, "Dron", { { -27, 8 }, { -24, 2 }, { -30, 2 } }, 1.4)
	Props.scatter(ctx, bed, { -33, -21, -5, 17 }, y + 0.08, 5, { "Book", "Gadget", "Battery", "Pile" })
	local plans = Kit.wallScreen(ctx, bed, CF(-22, y + 7.5, 17.65), 3.2, 3.2, "Plans")
	plans.Name = "PlanosDormitorio"
	Kit.doc(plans, "Planos junto a la cama", "Cosme duerme aquí, pero su cerebro nunca para. Esta noche ha dibujado: «Cohete de bolsillo», «Ascensor a la luna (con música)» y «Portal para ir al baño sin levantarse».", "CosmePlanosCama")
	local proto = Kit.group(bed, "Prototipo")
	Kit.box(ctx, proto, "Base", V(2, 1.4, 2), CF(-32.5, y + 0.7, -1), rgb(120, 126, 136), M.Metal)
	Kit.ball(ctx, proto, "Esfera", 1.4, CF(-32.5, y + 2.1, -1), C.Green, M.Neon, 0.2)

	---------------------------------------------------------------- Baño de arriba
	local bath = Kit.group(u, "BanoArriba")
	overlay(ctx, bath, "TileFloor", -20, -12, 8, 18, y, rgb(180, 196, 190), M.Marble)
	Kit.ceilingLamp(ctx, bath, -16, CU, 13, "BanoArriba")
	Kit.switch(ctx, bath, -12.6, y + 4, 8.4, 180, "BanoArriba")
	local bbf = Kit.furn(ctx, bath)
	Furniture.toilet(bbf, at(ctx, -19, y, 13.5, -90), bath)
	Furniture.vanity(bbf, at(ctx, -16, y, 17.1, 0), "BanoArriba", bath)
	Furniture.shower(bbf, at(ctx, -14.2, y, 12.5, 0), 3.4, bath)
	Props.make(ctx, bath, "Bottle", CF(-17.2, y + 3, 17))

	---------------------------------------------------------------- Sala de experimentos
	local exp = Kit.group(u, "Experimentos")
	overlay(ctx, exp, "Floor", -12, 12, -6, 18, y, rgb(70, 76, 88), M.DiamondPlate)
	for _, p in { { -6, 6 }, { 6, 6 }, { 0, 14 } } do
		Kit.ceilingLamp(ctx, exp, p[1], CU, p[2], "Experimentos", "Industrial", rgb(220, 240, 255))
	end
	Kit.switch(ctx, exp, -11.6, y + 4, 5, -90, "Experimentos")
	-- Mesas metálicas con tubos, cristales y matraces
	for i, p in { { -9.5, 12, 90 }, { 10, -1, -90 }, { 10, 8, -90 } } do
		local tbl = Kit.group(exp, "MesaMetal")
		local top = Kit.box(ctx, tbl, "Tablero", V(6, 0.3, 2.8), CF(p[1], y + 3, p[2]) * ANG(0, math.rad(p[3]), 0), C.Steel, M.DiamondPlate)
		for _, sx in { -1, 1 } do
			Kit.box(ctx, tbl, "Pata", V(0.3, 2.85, 2.4), CF(p[1], y + 1.43, p[2]) * ANG(0, math.rad(p[3]), 0) * CF(sx * 2.7, 0, 0), C.Dark, M.Metal)
		end
		local w = if p[3] == 0 then 6 else 2.8
		local d = if p[3] == 0 then 2.8 else 6
		Props.scatter(ctx, tbl, { p[1] - w / 2, p[1] + w / 2, p[2] - d / 2, p[2] + d / 2 }, y + 3.15, 6, Props.Lab)
		top:SetAttribute("Surface", true)
	end
	-- Brazo mecánico que gira, generador, bobina de Tesla con rayos
	local arm = Kit.group(exp, "BrazoMecanico")
	Kit.cyl(ctx, arm, "Base", 1, 2.4, CF(-8, y + 0.5, -2), C.Orange, M.Metal, true)
	local arm2 = Kit.group(arm, "Giratorio")
	Kit.box(ctx, arm2, "Hombro", V(1, 4, 1), CF(-8, y + 3, -2), C.Orange, M.Metal, { CanCollide = false })
	Kit.box(ctx, arm2, "Antebrazo", V(0.8, 0.8, 3.6), CF(-8, y + 4.8, -0.4) * ANG(0.3, 0, 0), C.Orange, M.Metal, { CanCollide = false })
	Kit.box(ctx, arm2, "Pinza", V(1, 0.4, 0.8), CF(-8, y + 4.2, 1.4), C.Dark, M.Metal, { CanCollide = false })
	Kit.spin(arm2, 0.08, "Y")
	arm2:SetAttribute("SpinCenter", at(ctx, -8, y + 3, -2))
	local tesla = Kit.group(exp, "BobinaTesla")
	Kit.cyl(ctx, tesla, "Base", 1.2, 3, CF(7.6, y + 0.6, 13.6), C.Dark, M.Metal, true)
	Kit.cyl(ctx, tesla, "Bobina", 5, 1.2, CF(7.6, y + 3.7, 13.6), rgb(200, 120, 60), M.Metal, true)
	local toroid = Kit.cyl(ctx, tesla, "Toroide", 0.8, 3.2, CF(7.6, y + 6.6, 13.6), C.Chrome, M.Metal)
	local spark = Kit.neon(ctx, tesla, "Chispa", V(0.6, 0.6, 0.6), CF(7.6, y + 7.3, 13.6), rgb(220, 230, 255), 0.1)
	Kit.fx(spark, "Sparks", 14)
	local target = Kit.neon(ctx, tesla, "Pararrayos", V(0.5, 3, 0.5), CF(10.8, y + 1.5, 16.8), C.Cyan, 0.2)
	Kit.beam(spark, target, rgb(210, 230, 255), 0.2, 8)
	Kit.light(ctx, spark, 14, 1.2, rgb(200, 220, 255))
	Kit.prompt(toroid, "Activar la bobina", "⚡ Bobina de Tesla", "Experiment", { Effect = "Tesla", Target = "BobinaTesla", Text = "¡KRZZZT! Un rayo violeta salta al pararrayos. Se te ponen los pelos de punta (literalmente)." })
	-- Esfera que flota sobre un campo magnético
	local field = Kit.group(exp, "CampoMagnetico")
	Kit.cyl(ctx, field, "Plataforma", 0.6, 3, CF(-2, y + 0.3, 10), C.Dark, M.Metal, true)
	for k = 0, 2 do
		Kit.cyl(ctx, field, "AnilloCampo", 0.15, 2.6 - k * 0.6, CF(-2, y + 0.7 + k * 0.1, 10), C.Cyan, M.Neon)
	end
	local orb = Kit.ball(ctx, field, "EsferaFlotante", 1.6, CF(-2, y + 4, 10), C.Purple, M.Neon, 0.1)
	Kit.anomaly(orb)
	Kit.spin(orb, 0.25, "Y")
	Kit.light(ctx, orb, 12, 1, C.Purple)
	Kit.fx(orb, "Energy", 8)
	Kit.prompt(field:FindFirstChild("Plataforma") :: BasePart, "Subir el campo", "🧲 Campo magnético", "Experiment", { Effect = "Float", Target = "CampoMagnetico", Text = "La esfera sube, baja y da una vuelta de campana. Cosme lo llama «el yoyó gravitatorio»." })
	-- Giroscopio y péndulo que se mueven, generador con anillos
	local gyro = Kit.group(exp, "Giroscopio")
	Kit.cyl(ctx, gyro, "Pie", 3, 0.3, CF(10, y + 4.65, 8), C.Chrome, M.Metal)
	local spinRing = Kit.group(gyro, "Aros")
	for k = 0, 2 do
		local ring = Kit.cylX(ctx, spinRing, "Aro", 0.15, 2.2 - k * 0.4, CF(10, y + 6.6, 8) * ANG(k * 1.1, k * 0.7, 0), ({ C.Yellow, C.Cyan, C.Magenta })[k + 1], M.Neon)
		ring.Transparency = 0.2
	end
	Kit.spin(spinRing, 0.6, "Y")
	spinRing:SetAttribute("SpinCenter", at(ctx, 10, y + 6.6, 8))
	Kit.anomaly(spinRing)
	local gen = Kit.group(exp, "Generador")
	Kit.box(ctx, gen, "Cuerpo", V(3.4, 3.6, 3.4), CF(-9, y + 1.8, 4), rgb(80, 86, 100), M.Metal)
	local gcore = Kit.cyl(ctx, gen, "Nucleo", 2, 1.4, CF(-9, y + 4.6, 4), C.Green, M.Neon, false, 0.2)
	Kit.light(ctx, gcore, 12, 1, C.Green, "Experimentos")
	Kit.prompt(gcore, "Encender el generador", "🔋 Generador", "Machine", { Target = "Generador", Text = "El generador ronronea. Las luces de toda la casa parpadean un momento. Ups." })
	Props.scatter(ctx, exp, { -11, 11, -5, 17 }, y + 0.08, 8, { "CableRun", "Crate", "Pile", "Barrel" })
	Kit.robot(ctx, exp, 2, y + 0.08, 2, "Mini", { { 2, 2 }, { -4, 6 }, { 2, 12 }, { 6, 6 } }, 2)
	local board = Kit.wallScreen(ctx, exp, CF(11.65, y + 7, 15) * ANG(0, math.pi / 2, 0), 4, 3, "Sim")
	Kit.doc(board, "Pizarra de experimentos", "«Experimento 412: ¿Puede un portal abrirse dentro de otro portal? Respuesta: sí. ¿Debería? No.»", "CosmePizarra")
	return u
end

function Interior.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "Interior")
	mainStair(ctx, m)
	groundFloor(ctx, m)
	upperFloor(ctx, m)
	return m
end

return Interior
