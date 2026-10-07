-- Interior: las plantas baja y alta de la casa de Cosme, sala a sala como el plano del dueño
-- (docs/referencias/plano-casa-cosme.png; medidas en CosmeHouse/Layout) y con el aspecto de los paneles
-- del render (docs/referencias/casa-cosme.png): suelos de madera cálida, aros de luz LED en el techo,
-- detalles de neón.
--
--   Núcleo de la escalera (centro): sube de la planta baja a la alta y a la cúpula del tejado, y por
--   debajo baja al sótano (las dos en el mismo hueco, una encima de otra).
--   Baja: vestíbulo/entrada (alfombra con el átomo y aro de luz), salón (sofás, tele de ecuaciones,
--   pizarra «LA REALIDAD ES SOLO UNA OPCIÓN», portal defectuoso), despacho (caja fuerte y pistas),
--   comedor (mesa de madera y lámparas colgantes), cocina (con su mesa de diario) y aseo.
--   (El laboratorio de inventos está en CosmeHouse/Laboratory; el garaje en CosmeHouse/Garage.)
--   Alta: pasillo, habitación de Cosme, biblioteca, baño, zona de experimentos, sala de ordenadores
--   y la sala de observación del mirador de cristal.
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

local F0, F1, F2 = Layout.F0, Layout.F1, Layout.F2
local CG, CU = Layout.CEIL.G, Layout.CEIL.U
local WARM = rgb(255, 232, 196) -- luz cálida de los aros LED
local OAK = rgb(186, 136, 90) -- tarima cálida (como el render)

local function op(a: number, b: number, bottom: number, top: number, kind: string?): Kit.Opening
	return { A = a, B = b, Bottom = bottom, Top = top, Kind = kind }
end

local function partition(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, a: number, b: number, y0: number, y1: number, openings: { Kit.Opening }?, color: Color3?)
	return Kit.wall(ctx, parent, axis, fixed, a, b, y0, y1, { Thick = 0.6, Name = "InnerWall", Color = color or C.Wall, Material = M.Plaster, Openings = openings, Frame = C.Dark })
end
Interior.partition = partition

-- Suelo de otro material encima del forjado (baldosas, piedra, tarima de otro tono)
local function overlay(ctx: Kit.Ctx, parent: Instance, name: string, x0: number, x1: number, z0: number, z1: number, y: number, color: Color3, material: Enum.Material)
	Kit.box(ctx, parent, name, V(x1 - x0, 0.06, z1 - z0), CF((x0 + x1) / 2, y + 0.03, (z0 + z1) / 2), color, material, { CanQuery = true, CastShadow = false })
end
Interior.overlay = overlay

local function rug(ctx: Kit.Ctx, parent: Instance, x: number, y: number, z: number, w: number, d: number, color: Color3, pattern: Color3?)
	Kit.deco(ctx, parent, "Alfombra", V(w, 0.08, d), CF(x, y + 0.1, z), color, M.Fabric, nil, true)
	if pattern then
		-- Dibujo de átomo (aro, dos órbitas y núcleo), como en la alfombra del vestíbulo del render
		local ring = Kit.cyl(ctx, parent, "DibujoAro", 0.02, math.min(w, d) * 0.62, CF(x, y + 0.15, z), pattern, M.Fabric)
		ring.Transparency = 0
		Kit.cyl(ctx, parent, "DibujoHueco", 0.025, math.min(w, d) * 0.54, CF(x, y + 0.155, z), color, M.Fabric)
		for k = 0, 1 do
			Kit.deco(ctx, parent, "Orbita", V(math.min(w, d) * 0.6, 0.03, 0.18), CF(x, y + 0.16, z) * ANG(0, 0.6 + k * 1.9, 0), pattern, M.Fabric)
		end
		Kit.cyl(ctx, parent, "DibujoNucleo", 0.03, math.min(w, d) * 0.12, CF(x, y + 0.17, z), pattern, M.Fabric)
	end
end
Interior.rug = rug

local function at(ctx: Kit.Ctx, x: number, y: number, z: number, yaw: number?): CFrame
	return Kit.at(ctx, x, y, z, yaw)
end

-- Aro de luz LED en el techo (como los de los paneles del render): aro de neón cálido, sin
-- bombilla a la vista. Cuenta como la luz de la sala.
local function ringLight(ctx: Kit.Ctx, parent: Instance, x: number, ceil: number, z: number, room: string, diameter: number?, color: Color3?)
	return Kit.ceilingLamp(ctx, parent, x, ceil, z, room, "Ring", color or WARM)
end
Interior.ringLight = ringLight

-- Tira de neón en el encuentro de la pared con el techo (luz indirecta de color)
local function cove(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, a: number, b: number, y: number, color: Color3)
	local len = b - a
	Kit.neon(ctx, parent, "TiraLed", if axis == "X" then V(len, 0.15, 0.15) else V(0.15, 0.15, len), if axis == "X" then CF((a + b) / 2, y, fixed) else CF(fixed, y, (a + b) / 2), color, 0.15)
end
Interior.cove = cove

---------------------------------------------------------------------
-- Núcleo de la escalera: Layout.Stairs.Hall (sube) y Layout.Stairs.Sotano (baja), en el mismo hueco
---------------------------------------------------------------------
local function core(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "EscaleraPrincipal")
	local s = Layout.Stairs.Hall
	local d = Layout.Stairs.Sotano
	local K = Layout.Core
	for k = 1, s.Flights do
		Kit.flight(ctx, m, s, k, Layout.flight(s, k), rgb(150, 104, 64), M.Wood)
	end
	local down = Kit.group(parent, "BajadaSotano")
	for k = 1, d.Flights do
		Kit.flight(ctx, down, d, k, Layout.flight(d, k), rgb(90, 96, 108), M.DiamondPlate)
	end
	-- Rellanos del fondo (los de cerca son el suelo de cada planta)
	for _, spec in { { s, m, rgb(150, 104, 64), M.Wood }, { d, down, rgb(90, 96, 108), M.DiamondPlate } } do
		for _, l in Layout.landings(spec[1]) do
			if not l.Near then
				Kit.box(ctx, spec[2], "Rellano", V(l.X1 - l.X0, 0.8, l.Z1 - l.Z0), CF((l.X0 + l.X1) / 2, l.Y - 0.4, (l.Z0 + l.Z1) / 2), spec[3], spec[4], { CanQuery = true })
			end
		end
	end
	-- Espina central (separa los dos carriles) de arriba abajo, con tiras de luz
	local z0, z1 = s.Z0 + s.Near, s.Z0 + s.Near + s.Run
	local yLow, yTop = Layout.FB, F2 + 1
	Kit.box(ctx, m, "InnerWall", V(0.6, yTop - yLow, z1 - z0), CF(K.X0 + 6, (yLow + yTop) / 2, (z0 + z1) / 2), C.Wall, M.Plaster, { CanQuery = true })
	for _, y in { -8, 5, 11, 18, 24 } do
		Kit.neon(ctx, m, "TiraLuz", V(0.7, 0.15, z1 - z0 - 1), CF(K.X0 + 6, y, (z0 + z1) / 2), C.Cyan, 0.3)
	end
	-- Paredes del núcleo: el fondo de arriba abajo y los lados desde donde empiezan los tramos.
	-- En la planta alta, el rellano solo abre al pasillo (los lados se cierran).
	Kit.box(ctx, m, "InnerWall", V(K.X1 - K.X0 + 0.6, F2 - Layout.FB, 0.6), CF((K.X0 + K.X1) / 2, (F2 + Layout.FB) / 2, K.Z1), C.WallWarm, M.Plaster, { CanQuery = true })
	for _, x in { K.X0, K.X1 } do
		Kit.box(ctx, m, "InnerWall", V(0.6, F2 - Layout.FB, K.Z1 - z0), CF(x, (F2 + Layout.FB) / 2, (z0 + K.Z1) / 2), C.WallWarm, M.Plaster, { CanQuery = true })
		Kit.box(ctx, m, "InnerWall", V(0.6, CU - F1, z0 - K.Z0), CF(x, (F1 + CU) / 2, (K.Z0 + z0) / 2), C.WallWarm, M.Plaster, { CanQuery = true })
	end
	-- Mural de ecuaciones y fotos en el fondo (se ven desde los rellanos)
	Kit.wallScreen(ctx, m, CF(7, 11, K.Z1 - 0.35), 4.6, 3, "Equations").Name = "Mural"
	Kit.wallScreen(ctx, m, CF(13, 24, K.Z1 - 0.35), 4.6, 3, "Plans").Name = "Mural"
	Furniture.picture(Kit.furn(ctx, m), at(ctx, 7, -10, K.Z1 - 0.35), 2.6, 2.2, m)
	-- Cartel del sótano en el arranque de la bajada
	local sign = Kit.deco(ctx, down, "CartelSotano", V(5.4, 1.1, 0.1), CF(7, 10.4, z0 - 0.1), rgb(240, 200, 40), nil, nil, true)
	Kit.signText(sign, "↓ SÓTANO · ↑ ARRIBA", Enum.NormalId.Front, rgb(30, 30, 30), rgb(240, 200, 40))
	sign.Name = "CartelSotano"
	-- Rayas de peligro en el borde de la bajada (como el sótano del render)
	for i = 0, 3 do
		Kit.deco(ctx, down, "Franja", V(1.2, 0.03, 0.5), CF(4.8 + i * 1.5, F0 + 0.03, z0 - 0.3) * ANG(0, 0.6, 0), if i % 2 == 0 then C.Yellow else C.Dark)
	end
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
	partition(ctx, walls, "Z", 4, -32, -12, y, CG, { op(-30, -23, y, y + 10), op(-19, -13, y, y + 10) })
	partition(ctx, walls, "X", -20, -22, 4, y, CG, { op(-8, 2, y, y + 10) })
	partition(ctx, walls, "Z", -10, -32, -20, y, CG, { op(-30, -24, y, y + 9.5) })
	partition(ctx, walls, "X", -12, 16, 40, y, CG, { op(20, 36, y, y + 10.5) })
	partition(ctx, walls, "X", 4, -22, 4, y, CG, { op(-12, -6, y, y + 9.5) })
	partition(ctx, walls, "Z", 16, Layout.Core.Z1, 24, y, CG, { op(14, 20, y, y + 9.5) })
	partition(ctx, walls, "Z", 4, Layout.Core.Z1, 24, y, CG)
	Kit.door(ctx, walls, -10, y, -27, 90, 6, 9.3, rgb(120, 84, 56), true)
	Kit.door(ctx, walls, -9, y, 4, 180, 6, 9.3, rgb(70, 74, 84), true)
	Kit.door(ctx, walls, 16, y, 17, -90, 6, 9.3, C.White, false)

	---------------------------------------------------------------- Vestíbulo / Entrada
	local hall = Kit.group(g, "Vestibulo")
	overlay(ctx, hall, "HallFloor", -10, 4, -32, -20, y, rgb(196, 150, 104), M.WoodPlanks)
	rug(ctx, hall, -3, y, -26, 6.5, 6.5, rgb(40, 52, 80), rgb(190, 210, 255))
	ringLight(ctx, hall, -3, CG, -26, "Vestibulo")
	Kit.switch(ctx, hall, -9.6, y + 4, -22, -90, "Vestibulo")
	cove(ctx, hall, "Z", -9.65, -23.5, -20.5, CG - 0.3, C.Cyan)
	-- Perchero con la bata de repuesto, sombrero y zapatos
	local rack = Kit.group(hall, "Perchero")
	Kit.cyl(ctx, rack, "Pie", 0.3, 1.6, CF(-8.6, y + 0.15, -30.6), C.Dark, M.Metal)
	Kit.cyl(ctx, rack, "Palo", 6.5, 0.3, CF(-8.6, y + 3.4, -30.6), C.WoodDark, M.Wood, true)
	Kit.deco(ctx, rack, "Bata", V(1.6, 3.6, 0.8), CF(-8.6, y + 4.6, -30.1), rgb(240, 240, 232), M.Fabric)
	Kit.deco(ctx, rack, "Quemadura", V(0.6, 0.6, 0.05), CF(-8.9, y + 4, -29.68), rgb(60, 50, 40), M.Fabric)
	Kit.cyl(ctx, rack, "Sombrero", 0.5, 1.4, CF(-8.6, y + 6.9, -30.6), rgb(60, 40, 90), M.Fabric)
	for i = 0, 2 do
		for side = -1, 1, 2 do
			Kit.deco(ctx, hall, "Zapato", V(1, 0.4, 0.5), CF(-6.5 + i * 1.4 + side * 0.3, y + 0.2, -31.2), ({ C.Dark, rgb(120, 70, 40), rgb(200, 60, 50) })[i + 1])
		end
	end
	-- Consola con llaves y cajas, plano enmarcado, foto antigua y reloj
	Kit.box(ctx, hall, "Consola", V(1.6, 3, 3), CF(-9.1, y + 1.5, -21.8), C.WoodDark, M.Wood)
	Props.scatter(ctx, hall, { -9.8, -8.4, -23.2, -20.4 }, y + 3, 3, { "Papers", "Gadget", "Mug", "Bulb" })
	local blueprint = Kit.deco(ctx, hall, "PlanoEnmarcado", V(0.15, 3, 2.6), CF(-9.62, y + 7, -21.8), rgb(40, 80, 170), nil, nil, true)
	Kit.screen(ctx, blueprint, "Plans", Enum.NormalId.Right)
	Kit.doc(blueprint, "Plano enmarcado", "«MÁQUINA LUNAR · versión 12». Hay tachones por todas partes. En una esquina: «Falta: 1 condensador de grieta, 3 bobinas cuánticas y valor».", "CosmePlanoLunar")
	local photo = Kit.deco(ctx, hall, "FotoAntigua", V(2.6, 2, 0.12), CF(-6, y + 7.5, -31.4), rgb(150, 120, 90), M.Wood, nil, true)
	Kit.doc(photo, "Foto antigua", "Dos científicos jóvenes delante de una máquina enorme. Uno es Cosme, con el pelo todavía oscuro. El otro lleva perilla y sonríe como en un anuncio. Detrás pone: «Cosme y Cósimo. Día 1 del proyecto Grieta».", "CosmeFotoCosimo")
	Furniture.clock(Kit.furn(ctx, hall), at(ctx, 3.65, y + 10.6, -21.5, 90), hall)
	-- Póster «GRANDES IDEAS» (como el del vestíbulo del render)
	local ideas = Kit.deco(ctx, hall, "Poster", V(0.12, 4, 3), CF(3.62, y + 6, -31) , rgb(244, 240, 228), nil, nil, true)
	Kit.signText(ideas, "GRANDES IDEAS\nEMPIEZAN\nAQUÍ", Enum.NormalId.Left, rgb(40, 50, 80), rgb(244, 240, 228))
	Props.make(ctx, hall, "Plant", CF(2.6, y, -21.5))
	-- Un robot pequeño que pasa por el suelo del vestíbulo
	Kit.robot(ctx, hall, -3, y + 0.06, -30, "Mini", { { -3, -30 }, { -3, -22 }, { -6, -24 }, { 0, -28 } }, 2.4)

	---------------------------------------------------------------- Despacho
	local office = Kit.group(g, "Despacho")
	rug(ctx, office, -16, y, -26, 7, 7, rgb(110, 40, 40))
	Kit.ceilingLamp(ctx, office, -16, CG, -26, "Despacho")
	Kit.switch(ctx, office, -10.4, y + 4, -22.5, 90, "Despacho")
	-- Mesa con tres monitores (ecuaciones, mapa y planos) y su silla
	local furn = Kit.furn(ctx, office, rgb(90, 62, 40))
	local desk = Furniture.desk(furn, at(ctx, -16, y, -21.8, 0), { Width = 8, Computer = false, Chair = true }, office)
	desk.Name = "MesaDespacho"
	local kinds = { "Equations", "Map", "Plans" }
	for i = -1, 1 do
		local screen = Kit.monitor(ctx, office, CF(-16 + i * 2.7, y + 3.02, -21.4) * ANG(0, math.pi + i * 0.25, 0), 2.4, 1.6, kinds[i + 2])
		if i == 0 then
			Furniture.usable(screen, "Computer", { On = true })
		end
	end
	Props.scatter(ctx, office, { -19.8, -12.2, -22.6, -22 }, y + 3.02, 3, { "Mug", "Papers", "Keyboard" })
	local hint1 = Kit.deco(ctx, office, "DocumentoMision", V(1.2, 0.04, 1.6), CF(-19, y + 3.05, -21.6) * ANG(0, 0.3, 0), rgb(250, 246, 230), nil, nil, true)
	Kit.doc(hint1, "Informe «Componentes perdidos»", "Lista de componentes que faltan para la máquina del espacio-tiempo:\n• Condensador de grieta (lo tiene un pez contable)\n• Bobina cuántica (en la granja de Julián, dentro de una gallina, creo)\n• Cristal de los Pliegues (no tocar con la mano)\n\nNota: pedir ayuda a la criatura de al lado.", "CosmeComponentes")
	-- Caja fuerte (se abre y dentro hay una pista)
	local safe = Kit.group(office, "CajaFuerte")
	Kit.box(ctx, safe, "Cuerpo", V(3, 3.4, 2.6), CF(-20.2, y + 1.7, -30.4), rgb(60, 64, 72), M.DiamondPlate)
	local safeDoor = Kit.box(ctx, safe, "Puerta", V(2.6, 3, 0.2), CF(-20.2, y + 1.7, -29.0), rgb(80, 84, 92), M.Metal, { CanCollide = false })
	safeDoor:SetAttribute("Hinge", at(ctx, -21.5, y + 1.7, -29.0))
	safeDoor:SetAttribute("Closed", safeDoor.CFrame)
	safeDoor:SetAttribute("Swing", math.rad(-100))
	Kit.cylX(ctx, safe, "Rueda", 0.2, 1.2, CF(-20.2, y + 1.9, -28.8) * ANG(0, math.pi / 2, 0), C.Chrome, M.Metal)
	Kit.prompt(safeDoor, "Abrir la caja fuerte", "🔐 Caja fuerte", "Safe", { Title = "Dentro de la caja fuerte", Text = "Un sobre: «PARA LA CRIATURA, SI ME PASA ALGO». Dentro, unas coordenadas: X 66 · Y -B · Z ∞, y un dibujo de una puerta detrás de una estantería del taller del sótano con tres libros marcados: FÍSICA, TIEMPO, LUNA.", PropId = "CosmeCajaFuerte" })
	-- Archivador con cajones que se abren y expediente encima
	local cab = Kit.group(office, "Archivador")
	Kit.box(ctx, cab, "Cuerpo", V(2.4, 4.4, 2.2), CF(-11.6, y + 2.2, -30.6), C.Steel, M.Metal)
	for k = 0, 2 do
		local drawer = Kit.box(ctx, cab, "Cajon", V(2, 1.2, 1.8), CF(-11.6, y + 0.9 + k * 1.35, -30.3), rgb(176, 182, 190), M.Metal, { CanCollide = false })
		Kit.deco(ctx, cab, "Tirador", V(0.8, 0.12, 0.12), CF(-11.6, y + 1.2 + k * 1.35, -29.38), C.Dark, M.Metal):SetAttribute("FollowDrawer", drawer.Name .. k)
		drawer.Name = "Cajon" .. k
		drawer:SetAttribute("SlideDir", ctx.Site:VectorToWorldSpace(V(0, 0, 1)))
		Kit.prompt(drawer, "Abrir el cajón", "🗄️ Archivador", "Drawer", { Slide = 1.6, Text = ({ "Fichas: «Anomalía 14: lluvia hacia arriba en el parque».", "Fotos de un pez con corbata.", "Recibos de 200 batidos de apio." })[k + 1] })
	end
	local hint2 = Kit.deco(ctx, office, "Expediente", V(1.4, 0.3, 1.8), CF(-11.6, y + 4.55, -30.6), rgb(200, 160, 90), nil, nil, true)
	Kit.doc(hint2, "Expediente «Valmar 2»", "Tres Valmar distintas vistas a la vez desde la cúpula. En una todo es gris y nadie inventa nada. «Si alguna vez la encuentro, no me quedaré allí. O sí. No lo sé.»", "CosmeExpediente")
	-- Estantería en la pared del garaje y fotos de lugares extraños sobre la mesa
	Props.shelf(ctx, office, CF(-21.1, y, -25.5) * ANG(0, -math.pi / 2, 0), 6, 9)
	for i, kind in { "Stars", "Anomalies", "Map" } do
		Kit.wallScreen(ctx, office, CF(-19.5 + i * 2.4, y + 8.6, -20.35), 2, 1.6, kind).Name = "FotoLugarExtrano"
	end
	local globe = Kit.group(office, "Globo")
	Kit.cyl(ctx, globe, "Pie", 2.6, 0.3, CF(-13, y + 1.3, -24.4), C.WoodDark, M.Wood, true)
	Kit.ball(ctx, globe, "Tierra", 1.8, CF(-13, y + 3.3, -24.4), rgb(60, 120, 200), M.SmoothPlastic)
	Kit.ball(ctx, globe, "Luna", 0.5, CF(-12, y + 4.3, -24.4), rgb(220, 220, 220), M.Slate)
	Props.scatter(ctx, office, { -21, -12, -30, -28 }, y, 3, { "Book", "Papers", "Blueprint" })

	---------------------------------------------------------------- Salón / Estar
	local living = Kit.group(g, "Salon")
	overlay(ctx, living, "Floor", 4, 40, -32, -12, y, OAK, M.WoodPlanks)
	rug(ctx, living, 31, y, -22, 9, 11, rgb(54, 70, 104))
	ringLight(ctx, living, 31, CG, -22, "Salon")
	ringLight(ctx, living, 14, CG, -22, "Salon")
	Kit.switch(ctx, living, 4.4, y + 4, -21.5, 90, "Salon")
	cove(ctx, living, "X", -12.35, 36.5, 39.5, CG - 0.3, C.Purple)
	local lf = Kit.furn(ctx, living, rgb(110, 80, 52), rgb(200, 176, 146), C.Cyan)
	Furniture.sofa(lf, at(ctx, 27, y, -22, -90), rgb(200, 176, 146), 3, living)
	Furniture.armchair(lf, at(ctx, 34, y, -29.4, 20), rgb(110, 90, 140), living)
	Furniture.coffeeTable(lf, at(ctx, 32.2, y, -22, 90), 5, 2.6, living)
	-- La tele (solo da gráficos científicos) en la pared de la izquierda, con su mueble
	local tv = Kit.wallScreen(ctx, living, CF(39.45, y + 5.6, -22) * ANG(0, math.pi / 2, 0), 8, 4.5, "Graph")
	tv.Name = "TeleCientifica"
	Kit.prompt(tv, "Ver la tele", "📺 Canal de ecuaciones", "Screen", { Title = "Canal 66: Ciencia sin pausa", Text = "Hoy en el canal 66: «Cómo doblar el espacio-tiempo con una pinza de la ropa». Le sigue: «Grietas en el cielo: ¿hay que preocuparse? (Sí)».", PropId = "CosmeTele" })
	Kit.box(ctx, living, "MuebleTele", V(2, 2, 8), CF(38.4, y + 1, -22), C.WoodDark, M.Wood)
	Props.scatter(ctx, living, { 37.6, 39.2, -25.6, -18.4 }, y + 2, 3, { "Radio", "Gadget", "Book" })
	-- Mando raro en la mesa (enciende el portal defectuoso de la esquina)
	local remote = Kit.deco(ctx, living, "MandoRaro", V(0.6, 0.25, 1.4), CF(32.2, y + 1.62, -22.6) * ANG(0, 0.4, 0), rgb(60, 60, 70), nil, nil, true)
	Kit.neon(ctx, living, "BotonMando", V(0.3, 0.1, 0.3), CF(32.2, y + 1.78, -22.6), C.Magenta)
	Kit.prompt(remote, "Pulsar el mando raro", "🎛️ Mando raro", "Experiment", { Effect = "MiniPortal", Target = "PortalDefectuoso", Text = "En la esquina se abre un portal chiquitito… y se cierra con un hipido. Huele a palomitas de otra dimensión." })
	Props.scatter(ctx, living, { 31, 33.4, -21.4, -19.6 }, y + 1.5, 2, { "Mug", "Book" })
	-- Máquina junto al sofá (la «máquina de siestas»)
	local napper = Kit.group(living, "MaquinaSiestas")
	Kit.box(ctx, napper, "Cuerpo", V(2.4, 4.4, 2.4), CF(26.6, y + 2.2, -29.6), rgb(150, 156, 170), M.Metal)
	local dome = Kit.ball(ctx, napper, "Cupula", 2, CF(26.6, y + 4.8, -29.6), C.Cyan, M.Neon, 0.3)
	for k = 0, 2 do
		Kit.neon(ctx, napper, "Piloto", V(0.1, 0.3, 0.3), CF(27.85, y + 3, -30.2 + k * 0.6), ({ C.Red, C.Yellow, C.Green })[k + 1])
	end
	Kit.spin(napper:FindFirstChild("Cupula") :: Instance, 0.2, "Y")
	Kit.prompt(dome, "Encender", "🌀 Máquina de siestas", "Machine", { Target = "MaquinaSiestas", Text = "La máquina hace «bzzzt» y el sofá parece de repente MUY cómodo." })
	-- Lámpara experimental (bola de plasma en un trípode)
	local lamp = Kit.group(living, "LamparaExperimental")
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		Kit.deco(ctx, lamp, "Pata", V(0.2, 5.4, 0.2), CF(38 + math.cos(a) * 0.7, y + 2.6, -30 + math.sin(a) * 0.7) * ANG(math.cos(a) * 0.15, 0, -math.sin(a) * 0.15), C.Dark, M.Metal)
	end
	local plasma = Kit.ball(ctx, lamp, "Plasma", 1.8, CF(38, y + 6, -30), C.Magenta, M.Neon, 0.25)
	Kit.light(ctx, plasma, 14, 1, C.Magenta, "Salon")
	Kit.fx(plasma, "Energy", 6)
	-- Pizarra «LA REALIDAD ES SOLO UNA OPCIÓN» (como la del salón del render) y pared de ecuaciones
	local chalk = Kit.deco(ctx, living, "Pizarra", V(3, 5.4, 0.2), CF(38, y + 6, -12.42), rgb(26, 34, 44), M.Slate, nil, true)
	Kit.signText(chalk, "LA REALIDAD\nES SOLO\nUNA OPCIÓN\n⚛", Enum.NormalId.Front, rgb(220, 236, 255), rgb(26, 34, 44))
	Kit.wallScreen(ctx, living, CF(18, y + 6.5, -12.35), 3.2, 4.5, "Equations").Name = "ParedEcuaciones"
	-- Estanterías entre los arcos y en la esquina
	Props.shelf(ctx, living, CF(4.95, y, -21) * ANG(0, -math.pi / 2, 0), 3.6, 9, "Lab")
	Props.shelf(ctx, living, CF(5.6, y, -31.1) * ANG(0, math.pi, 0), 2.6, 9)
	for _, p in { { 22.5, -30.5 }, { 21.5, -13.6 } } do
		Props.make(ctx, living, "Plant", CF(p[1], y, p[2]))
	end
	Furniture.picture(Kit.furn(ctx, living), at(ctx, 22.5, y + 7, -31.4, 180), 2.6, 3.4, living)
	-- Portal defectuoso en la esquina (aparece unos segundos de vez en cuando: el cliente lo enciende)
	local broken = PortalSystem.build(ctx, living, CF(7.4, y + 2.9, -14.4) * ANG(0, math.rad(-135), 0), 1.6, { Name = "PortalDefectuoso", Color = C.Magenta, Depth = 0.9, Layers = 7, Broken = true, NoCoils = true, Stand = 0.5, Destination = 4 })
	broken:AddTag("CosmeFlicker")
	Props.scatter(ctx, living, { 8, 22, -31, -26 }, y + 0.08, 4, { "Book", "Clothes", "CableRun", "Gadget" })

	---------------------------------------------------------------- Comedor
	local dining = Kit.group(g, "Comedor")
	overlay(ctx, dining, "Floor", -22, 4, -20, 4, y, rgb(196, 160, 118), M.WoodPlanks)
	-- Lámparas colgantes sobre la mesa de madera (como el comedor del render)
	Kit.ceilingLamp(ctx, dining, -16, CG, -3, "Comedor", "Industrial", WARM)
	Kit.ceilingLamp(ctx, dining, -16, CG, 1.5, "Comedor", "Industrial", WARM)
	ringLight(ctx, dining, -6, CG, -12, "Comedor")
	Kit.switch(ctx, dining, -21.6, y + 4, -16, -90, "Comedor")
	local df = Kit.furn(ctx, dining, rgb(130, 90, 56))
	local table_ = Furniture.table(df, at(ctx, -16, y, -1), 4, 7, rgb(130, 90, 56), dining)
	table_.Name = "MesaComedor"
	for _, p in { { -19.3, -3 }, { -19.3, 1 }, { -12.7, -3 }, { -12.7, 1 } } do
		Furniture.chair(df, at(ctx, p[1], y, p[2], if p[1] < -16 then -90 else 90), rgb(40, 40, 46), dining)
	end
	Props.scatter(ctx, dining, { -17.6, -14.4, -4, 2 }, y + 3.15, 5, { "Food", "Mug", "Bottle", "Papers", "Gadget" })
	-- Aparador en la pared del despacho, con cuadro y el cartel de la comida
	Kit.box(ctx, dining, "Aparador", V(9, 3, 1.6), CF(-15.5, y + 1.5, -19), C.WoodDark, M.Wood)
	Props.scatter(ctx, dining, { -19.6, -11.4, -19.6, -18.4 }, y + 3, 4, { "Plant", "Bottle", "Jar", "Radio" })
	Furniture.picture(Kit.furn(ctx, dining), at(ctx, -15.5, y + 7.5, -19.65, 180), 4, 3, dining)
	local comida = Kit.deco(ctx, dining, "CartelComida", V(0.12, 3.8, 3), CF(-21.62, y + 7, -2), rgb(250, 248, 240), nil, nil, true)
	Kit.signText(comida, "COMIDA = ENERGÍA\n(e=mc²)", Enum.NormalId.Right, rgb(40, 40, 60), rgb(250, 248, 240))
	Props.make(ctx, dining, "Plant", CF(2.6, y, 2.6))
	Props.make(ctx, dining, "Plant", CF(-21, y, 2.6))

	---------------------------------------------------------------- Cocina (con su mesa de diario)
	local kitchen = Kit.group(g, "Cocina")
	overlay(ctx, kitchen, "TileFloor", 16, 40, -12, 24, y, rgb(226, 230, 232), M.Marble)
	Kit.ceilingLamp(ctx, kitchen, 34, CG, 6, "Cocina", "Bar", WARM)
	ringLight(ctx, kitchen, 28, CG, -4, "Cocina")
	for _, z in { -0.5, 4.5 } do
		Kit.ceilingLamp(ctx, kitchen, 21, CG, z, "Cocina", "Industrial", WARM)
	end
	Kit.switch(ctx, kitchen, 16.4, y + 4, -10, 90, "Cocina")
	local kf = Kit.furn(ctx, kitchen)
	Furniture.kitchenRun(kf, at(ctx, 38.7, y, 5, 90), 14, kitchen)
	Furniture.kitchenRun(kf, at(ctx, 35.2, y, 22.7, 0), 7, kitchen)
	-- Mesa de madera de diario con sus sillas
	local mf = Kit.furn(ctx, kitchen, rgb(150, 104, 64))
	Furniture.table(mf, at(ctx, 21, y, 2), 4, 7, rgb(150, 104, 64), kitchen).Name = "MesaCocina"
	for _, p in { { 17.7, 0 }, { 17.7, 4 }, { 24.3, 0 }, { 24.3, 4 } } do
		Furniture.chair(mf, at(ctx, p[1], y, p[2], if p[1] < 21 then -90 else 90), rgb(240, 238, 230), kitchen)
	end
	Props.scatter(ctx, kitchen, { 19.6, 22.4, -1, 5 }, y + 3.15, 4, { "Food", "Mug", "Bottle" })
	-- Nevera con pantalla. Se come de ella gratis en cuanto conoces a Cosme (FridgeService: FridgeOwner)
	local fridge = Kit.group(kitchen, "NeveraPantalla")
	local fbody = Kit.box(ctx, fridge, "Cuerpo", V(2.8, 7.4, 3.4), CF(38.1, y + 3.7, -9.6), rgb(200, 206, 212), M.Metal)
	fbody:AddTag("Interact")
	fbody:SetAttribute("Use", "Fridge")
	fbody:SetAttribute("FridgeOwner", "Cosme")
	Kit.deco(ctx, fridge, "Junta", V(2.82, 0.1, 3.42), CF(38.1, y + 5, -9.6), C.Dark)
	local fscreen = Kit.deco(ctx, fridge, "Pantalla", V(0.05, 1.6, 1.4), CF(36.67, y + 4.8, -9.6), rgb(30, 40, 60), M.SmoothPlastic, nil, true)
	Kit.screen(ctx, fscreen, "Text", Enum.NormalId.Left, "Batidos de apio: 3\nMoral: alta")
	Kit.prompt(fscreen, "Mirar la pantalla", "🧊 Nevera con pantalla", "Doc", { Title = "Nevera con pantalla", Text = "«Hola, criatura. Quedan 3 batidos de apio cuántico, 1 lasaña cuadrada y un tarro que dice NO ABRIR HASTA EL AÑO QUE VIENE (lo abrí ayer).»", PropId = "CosmeNevera" })
	-- Cafetera modificada (vapor), microondas temporal, impresora de comida, botellas raras
	local coffee = Kit.group(kitchen, "CafeteraModificada")
	Kit.box(ctx, coffee, "Cuerpo", V(1.4, 2, 1.6), CF(38.8, y + 4.65, 9), rgb(60, 60, 70), M.Metal)
	local spout = Kit.cyl(ctx, coffee, "Chimenea", 1.4, 0.5, CF(39, y + 6.3, 9), C.Chrome, M.Metal)
	Kit.neon(ctx, coffee, "Bobina", V(1.5, 0.2, 1.7), CF(38.8, y + 5.2, 9), C.Orange)
	Kit.fx(spout, "Steam", 5)
	Kit.prompt(spout, "Hacer café", "☕ Cafetera modificada", "Experiment", { Effect = "Coffee", Text = "La cafetera sirve el café de ayer. Literalmente: viaja 24 horas atrás. Está frío, pero puntual." })
	local micro = Kit.group(kitchen, "MicroondasTemporal")
	Kit.box(ctx, micro, "Cuerpo", V(1.8, 1.4, 2.6), CF(38.9, y + 4.4, 2), C.White, M.Metal)
	local mglass = Kit.deco(ctx, micro, "Puerta", V(0.05, 1, 1.6), CF(37.98, y + 4.4, 1.8), C.Dark, M.Glass, nil, true)
	Kit.neon(ctx, micro, "Reloj", V(0.05, 0.3, 0.5), CF(37.98, y + 4.7, 3), C.Green)
	Kit.prompt(mglass, "Usar el microondas", "⏲️ Microondas temporal", "Experiment", { Effect = "Zap", Text = "El reloj del microondas marca -00:30. Lo que metes sale más crudo que antes. Es un microondas temporal." })
	local printer = Kit.group(kitchen, "ImpresoraComida")
	Kit.box(ctx, printer, "Cuerpo", V(2.6, 2.6, 2.2), CF(35.5, y + 4.95, 22.6), rgb(230, 232, 236), M.SmoothPlastic)
	Kit.neon(ctx, printer, "Boquilla", V(0.3, 0.6, 0.3), CF(35.5, y + 4.6, 21.6), C.Orange)
	Kit.prompt(printer:FindFirstChild("Cuerpo") :: BasePart, "Imprimir comida", "🖨️ Impresora de comida", "Experiment", { Effect = "Printer", Text = "La impresora imprime una lasaña perfectamente cuadrada. Sabe a lasaña. Y un poco a tinta." })
	local shelfK = Kit.box(ctx, kitchen, "Balda", V(7, 0.25, 1), CF(20, y + 7.5, 23.1), C.WoodDark, M.Wood)
	shelfK.CanCollide = false
	for i = 0, 5 do
		Props.make(ctx, kitchen, if i % 2 == 0 then "Bottle" else "Jar", CF(17.3 + i * 1.1, y + 7.625, 23.1))
	end
	local labels = Kit.deco(ctx, kitchen, "EtiquetaBotellas", V(3.6, 0.6, 0.05), CF(20, y + 7, 22.55), rgb(250, 248, 230), nil, nil, true)
	Kit.signText(labels, "ZUMO DE ANTIMATERIA · NO BEBER", Enum.NormalId.Front, rgb(160, 40, 40), rgb(250, 248, 230))
	-- Póster de la cocina del render («Comida = inventos»)
	local kp = Kit.deco(ctx, kitchen, "Poster", V(3, 3.8, 0.12), CF(28, y + 7, -11.62), rgb(250, 248, 240), nil, nil, true)
	Kit.signText(kp, "COMIDA\n=\nINVENTOS ♥", Enum.NormalId.Back, rgb(60, 50, 50), rgb(250, 248, 240))
	-- Robots pequeños que van y vienen por la encimera
	Kit.robot(ctx, kitchen, 38.7, y + 3.65, 4, "Mini", { { 38.7, -1 }, { 38.7, 11 } }, 1.2)
	Kit.robot(ctx, kitchen, 33, y + 3.65, 22.7, "Mini", { { 32.5, 22.7 }, { 37.5, 22.7 } }, 1)
	Props.make(ctx, kitchen, "Plant", CF(17.5, y, 22.5))
	Props.make(ctx, kitchen, "Plant", CF(17.5, y, -10.5))
	-- Puerta a la terraza de atrás
	Kit.door(ctx, kitchen, 28, y, 24, 180, 6, 9.3, rgb(70, 74, 84), true)

	---------------------------------------------------------------- Aseo
	local bath = Kit.group(g, "Aseo")
	overlay(ctx, bath, "TileFloor", 4, 16, Layout.Core.Z1, 24, y, rgb(200, 214, 220), M.Marble)
	Kit.ceilingLamp(ctx, bath, 10, CG, 16, "Aseo")
	Kit.switch(ctx, bath, 15.6, y + 4, 12.5, -90, "Aseo")
	local bf = Kit.furn(ctx, bath)
	Furniture.toilet(bf, at(ctx, 5.6, y, 21, -90), bath)
	Furniture.vanity(bf, at(ctx, 10, y, 22.8, 0), "Aseo", bath)
	Furniture.shower(bf, at(ctx, 6.6, y, 11.6, 0), 4, bath)
	Furniture.towelRail(bf, at(ctx, 4.4, y, 16.5, -90), bath)
	local brush = Kit.group(bath, "CepilloInventado")
	Kit.deco(ctx, brush, "Cepillo3000", V(0.3, 1.2, 0.3), CF(11.3, y + 3.6, 23.2), C.Cyan, M.Neon)
	Kit.doc(Kit.deco(ctx, bath, "Instrucciones", V(1, 1.4, 0.05), CF(13.2, y + 5.5, 23.62), rgb(250, 248, 240), nil, nil, true), "Instrucciones del cepillo 3000", "«Cepillo de dientes cuántico. Limpia los dientes que tienes y los que tendrás. No usar en dimensiones con dientes de más.»")
	return g
end

---------------------------------------------------------------------
-- Planta alta
---------------------------------------------------------------------
local function upperFloor(ctx: Kit.Ctx, parent: Instance)
	local u = Kit.group(parent, "PlantaAlta")
	local y = F1
	local walls = Kit.group(u, "Tabiques")
	partition(ctx, walls, "Z", 4, -20, -12, y, CU, { op(-19, -13, y, y + 9.5) })
	partition(ctx, walls, "Z", 16, -20, -12, y, CU, { op(-19, -13, y, y + 9.5) })
	partition(ctx, walls, "X", 6, 16, 40, y, CU, { op(19, 25, y, y + 9.5), op(31, 37, y, y + 9.5) })
	partition(ctx, walls, "Z", 28, 6, 24, y, CU)
	partition(ctx, walls, "Z", 16, Layout.Core.Z1, 24, y, CU)
	partition(ctx, walls, "X", Layout.Core.Z1, -22, 4, y, CU, { op(-18, -12, y, y + 9.5), op(-5, 1, y, y + 9.5) })
	partition(ctx, walls, "Z", -8, Layout.Core.Z1, 24, y, CU, { op(12, 21, y + 2, y + 9, "glass") }, rgb(40, 44, 54))
	Kit.door(ctx, walls, 4, y, -16, -90, 6, 9.3, rgb(70, 74, 84), true)
	Kit.door(ctx, walls, 16, y, -16, 90, 6, 9.3, rgb(60, 40, 80), true)
	Kit.door(ctx, walls, 22, y, 6, 0, 6, 9.3, rgb(120, 84, 56), true)
	Kit.door(ctx, walls, 34, y, 6, 0, 6, 9.3, C.White, false)
	Kit.door(ctx, walls, -15, y, Layout.Core.Z1, 180, 6, 9.3, rgb(30, 34, 44), true)
	Kit.door(ctx, walls, -2, y, Layout.Core.Z1, 180, 6, 9.3, rgb(40, 60, 90), true)

	---------------------------------------------------------------- Pasillo
	local hall = Kit.group(u, "Pasillo")
	overlay(ctx, hall, "Floor", 4, 16, -20, -12, y, OAK, M.WoodPlanks)
	rug(ctx, hall, 10, y, -16, 4, 6, rgb(120, 40, 50))
	ringLight(ctx, hall, 10, CU, -16, "Pasillo")
	Kit.switch(ctx, hall, 6, y + 4, -19.6, 0, "Pasillo")
	local corkboard = Kit.deco(ctx, hall, "TableroCorcho", V(2.8, 3, 0.15), CF(5.8, y + 6.5, -19.62), rgb(190, 150, 100), M.Fabric, nil, true)
	Props.postits(ctx, hall, CF(5.8, y + 6.5, -19.5) * ANG(0, math.pi, 0), 2.4, 2.4, 6)
	Kit.doc(corkboard, "Tablero de corcho", "Pósits por todas partes:\n«Comprar apio» · «Arreglar el portal del salón (otra vez)» · «¿La luna tiene garaje?» · «NO dejar a Pip solo con el microondas» · «La criatura de al lado tiene talento. Vigilar.»", "CosmeCorcho")
	Props.make(ctx, hall, "Plant", CF(14.6, y, -19))
	Kit.robot(ctx, hall, 10, y + 0.08, -18, "Limpiador", { { 7, -18 }, { 13, -18 }, { 10, -13 } }, 1.8)

	---------------------------------------------------------------- Habitación de Cosme
	local bed = Kit.group(u, "Dormitorio")
	overlay(ctx, bed, "Floor", 16, 40, -20, 6, y, rgb(150, 110, 76), M.WoodPlanks)
	rug(ctx, bed, 33, y, -10, 9, 9, rgb(60, 70, 120), rgb(170, 200, 255))
	ringLight(ctx, bed, 30, CU, -8, "Dormitorio", nil, rgb(190, 200, 255))
	Kit.switch(ctx, bed, 16.4, y + 4, -11.4, 90, "Dormitorio")
	cove(ctx, bed, "X", 5.65, 17, 39, CU - 0.3, C.Purple)
	local bf = Kit.furn(ctx, bed, rgb(70, 60, 80), rgb(60, 70, 120), C.Purple)
	Furniture.bed(bf, at(ctx, 35.2, y, -10, 90), 5.6, bed)
	Furniture.nightstand(bf, at(ctx, 38.5, y, -15, 90), nil, bed)
	Furniture.wardrobe(bf, at(ctx, 17.6, y, -2, -90), 6, bed)
	-- Dos mesas con monitores junto a la cristalera (como la habitación del render)
	for i, x in { 22, 28.5 } do
		Furniture.desk(bf, at(ctx, x, y, -18.4, 180), { Width = 6, Computer = true, Chair = true, Tower = i == 1 }, bed)
		Kit.monitor(ctx, bed, CF(x + 1.8, y + 2.9, -19) * ANG(0, -0.3, 0), 1.8, 1.1, if i == 1 then "Stars" else "Coords")
	end
	Props.scatter(ctx, bed, { 19.6, 31, -19.4, -18.6 }, y + 2.92, 3, { "Blueprint", "Chip", "Mug" })
	-- Pósters y planos en la pared del núcleo
	for i, t in { { "LA LUNA\nME ESPERA", rgb(30, 40, 80) }, { "E = mc²\n(y apio)", rgb(60, 30, 70) } } do
		local poster = Kit.deco(ctx, bed, "Poster", V(0.12, 3.6, 2.8), CF(16.38, y + 6.5, -9 + i * 3.2), t[2], nil, nil, true)
		Kit.signText(poster, t[1], Enum.NormalId.Right, rgb(230, 230, 255), t[2])
	end
	local plans = Kit.wallScreen(ctx, bed, CF(39.45, y + 7.5, -3) * ANG(0, math.pi / 2, 0), 3.2, 3.2, "Plans")
	plans.Name = "PlanosDormitorio"
	Kit.doc(plans, "Planos junto a la cama", "Cosme duerme aquí, pero su cerebro nunca para. Esta noche ha dibujado: «Cohete de bolsillo», «Ascensor a la luna (con música)» y «Portal para ir al baño sin levantarse».", "CosmePlanosCama")
	-- Lámpara rara (de lava) en la mesita, ropa tirada, dron, prototipo y libros
	local lava = Kit.group(bed, "LamparaRara")
	Kit.cyl(ctx, lava, "Base", 0.8, 0.9, CF(38.5, y + 2.6, -15.4), C.Dark, M.Metal)
	local lavaGlass = Kit.cyl(ctx, lava, "Lava", 1.8, 0.8, CF(38.5, y + 3.9, -15.4), C.Orange, M.Neon, false, 0.25)
	Kit.light(ctx, lavaGlass, 10, 0.8, C.Orange, "Dormitorio")
	for _, p in { { 25, -6 }, { 31, 2 }, { 20, 3 } } do
		Props.make(ctx, bed, "Clothes", CF(p[1], y + 0.08, p[2]))
	end
	Kit.robot(ctx, bed, 28, y + 8, -8, "Dron", { { 28, -8 }, { 24, -2 }, { 31, -2 } }, 1.4)
	local proto = Kit.group(bed, "Prototipo")
	Kit.box(ctx, proto, "Base", V(2, 1.4, 2), CF(38.5, y + 0.7, 3.5), rgb(120, 126, 136), M.Metal)
	Kit.ball(ctx, proto, "Esfera", 1.4, CF(38.5, y + 2.1, 3.5), C.Green, M.Neon, 0.2)
	Props.scatter(ctx, bed, { 30, 38, -4, 4 }, y + 0.08, 4, { "Book", "Gadget", "Battery", "Pile" })

	---------------------------------------------------------------- Biblioteca científica
	local lib = Kit.group(u, "Biblioteca")
	overlay(ctx, lib, "Floor", 16, 28, 6, 24, y, rgb(140, 100, 66), M.WoodPlanks)
	ringLight(ctx, lib, 22, CU, 15, "Biblioteca")
	Kit.switch(ctx, lib, 25.5, y + 4, 6.4, 180, "Biblioteca")
	rug(ctx, lib, 22, y, 15, 6, 8, rgb(60, 50, 90), rgb(240, 200, 120))
	local topics = { { "FÍSICA", 16.95, 11.5, -90, 7 }, { "ASTRONOMÍA", 16.95, 19.5, -90, 7 }, { "MATEMÁTICAS", 27.05, 11.5, 90, 7 }, { "INGENIERÍA", 27.05, 19.5, 90, 7 } }
	for _, t in topics do
		local sh = Props.shelf(ctx, lib, CF(t[2], y, t[3]) * ANG(0, math.rad(t[4]), 0), t[5], 10.5)
		sh.Name = "Estanteria_" .. t[1]
		local tag = Kit.deco(ctx, sh, "Rotulo", V(3, 0.7, 0.1), CF(t[2], y + 11, t[3]) * ANG(0, math.rad(t[4]), 0) * CF(0, 0, -0.9), C.Dark, nil, nil, true)
		Kit.signText(tag, t[1], Enum.NormalId.Front, rgb(240, 220, 160), C.Dark)
	end
	local bookTexts = {
		{ "Física para inventores impacientes", "Capítulo 1: «Si funciona a la primera, es que no lo has entendido». Capítulo 2: «Si no funciona, súbele la potencia».", "CosmeLibroFisica" },
		{ "El espacio-tiempo, doblado como una servilleta", "Subrayado a mano: «Una grieta es una arruga en la servilleta. Si tiras del borde correcto, se cierra. Si tiras del incorrecto, sale un pez».", "CosmeLibroTiempo" },
		{ "Atlas de la Luna", "Un mapa de la luna con una cruz roja y una nota: «Aquí aparcaré. Hay sitio».", "CosmeLibroLuna" },
		{ "Programación para robots con sentimientos", "Página doblada: «Si tu robot pregunta para qué sirve, abrázalo. Luego revisa sus tornillos».", "CosmeLibroRobots" },
	}
	for i, b in bookTexts do
		local z = 9 + i * 2
		local book = Kit.deco(ctx, lib, "LibroInteractivo", V(1.2, 1.7, 0.5), CF(17.6, y + 0.2 + 2.1 * i + 0.95, z) * ANG(0, math.pi / 2, 0), ({ C.Red, C.Blue, C.Yellow, C.Green })[i], nil, nil, true)
		Kit.neon(ctx, lib, "BrilloLibro", V(0.2, 0.2, 1.22), CF(17.95, y + 0.2 + 2.1 * i + 1.6, z), C.Cyan, 0.3)
		Kit.doc(book, b[1], b[2], b[3])
	end
	local ladder = Kit.group(lib, "EscaleraBiblioteca")
	for _, z in { 22, 24 - 0.3 } do
		Kit.deco(ctx, ladder, "Larguero", V(0.25, 10.4, 0.25), CF(18.6, y + 5, z - 1) * ANG(0, 0, 0.15), C.WoodDark, M.Wood)
	end
	local lf = Kit.furn(ctx, lib, rgb(90, 62, 40), rgb(130, 60, 50))
	Furniture.table(lf, at(ctx, 22, y, 20), 5, 3, rgb(90, 62, 40), lib)
	Props.scatter(ctx, lib, { 19.8, 24.2, 18.8, 21.2 }, y + 3.15, 5, { "Book", "Papers", "Lamp", "Mug", "Blueprint" })
	Furniture.chair(lf, at(ctx, 22, y, 17.4, 0), rgb(90, 62, 40), lib)
	Furniture.armchair(lf, at(ctx, 25.6, y, 9, 150), rgb(130, 60, 50), lib)
	local celestial = Kit.group(lib, "GloboCeleste")
	Kit.cyl(ctx, celestial, "Pie", 3, 0.3, CF(19, y + 1.5, 8.2), C.WoodDark, M.Wood, true)
	Kit.ball(ctx, celestial, "Esfera", 2.4, CF(19, y + 4.1, 8.2), rgb(20, 30, 70), M.Glass, 0.3)
	Kit.ball(ctx, celestial, "Estrella", 0.5, CF(19, y + 4.1, 8.2), C.Yellow, M.Neon)
	-- Un libro que flota solo (anomalía)
	local floating = Kit.deco(ctx, lib, "LibroFlotante", V(1.2, 0.25, 1.6), CF(22, y + 7.5, 12) * ANG(0.3, 0.5, 0.1), C.Purple, nil, nil, true)
	Kit.anomaly(floating)
	Kit.spin(floating, 0.08, "Y")
	Kit.fx(floating, "Dust", 4)
	Props.scatter(ctx, lib, { 19, 26, 9, 13 }, y + 0.08, 3, { "Book", "Papers" })

	---------------------------------------------------------------- Baño de arriba
	local bath = Kit.group(u, "BanoArriba")
	overlay(ctx, bath, "TileFloor", 28, 40, 6, 24, y, rgb(180, 196, 190), M.Marble)
	Kit.ceilingLamp(ctx, bath, 34, CU, 15, "BanoArriba")
	Kit.switch(ctx, bath, 37.5, y + 4, 6.4, 180, "BanoArriba")
	local bbf = Kit.furn(ctx, bath)
	Furniture.toilet(bbf, at(ctx, 38.4, y, 15, 90), bath)
	Furniture.vanity(bbf, at(ctx, 33, y, 22.8, 0), "BanoArriba", bath)
	Furniture.shower(bbf, at(ctx, 30.8, y, 9, 0), 4, bath)
	Props.make(ctx, bath, "Bottle", CF(34.2, y + 3, 22.6))

	---------------------------------------------------------------- Zona de trabajo / Experimentos
	local exp = Kit.group(u, "Experimentos")
	overlay(ctx, exp, "Floor", -22, 4, -20, Layout.Core.Z1, y, rgb(70, 76, 88), M.DiamondPlate)
	for _, p in { { -14, -12 }, { -4, -6 }, { -14, 2 } } do
		Kit.ceilingLamp(ctx, exp, p[1], CU, p[2], "Experimentos", "Industrial", rgb(220, 240, 255))
	end
	Kit.switch(ctx, exp, 3.6, y + 4, -11.5, -90, "Experimentos")
	cove(ctx, exp, "Z", -21.65, -19, 7.5, CU - 0.3, C.Cyan)
	-- Mesas metálicas con tubos, cristales y matraces (bajo las ventanas)
	for _, p in { { -19.6, -12, 90 }, { -19.6, -3, 90 }, { -9, -18.4, 0 } } do
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
	-- Brazo mecánico que gira, bobina de Tesla con rayos, generador
	local arm = Kit.group(exp, "BrazoMecanico")
	Kit.cyl(ctx, arm, "Base", 1, 2.4, CF(1.5, y + 0.5, -4), C.Orange, M.Metal, true)
	local arm2 = Kit.group(arm, "Giratorio")
	Kit.box(ctx, arm2, "Hombro", V(1, 4, 1), CF(1.5, y + 3, -4), C.Orange, M.Metal, { CanCollide = false })
	Kit.box(ctx, arm2, "Antebrazo", V(0.8, 0.8, 3.6), CF(1.5, y + 4.8, -2.4) * ANG(0.3, 0, 0), C.Orange, M.Metal, { CanCollide = false })
	Kit.box(ctx, arm2, "Pinza", V(1, 0.4, 0.8), CF(1.5, y + 4.2, -0.6), C.Dark, M.Metal, { CanCollide = false })
	Kit.spin(arm2, 0.08, "Y")
	arm2:SetAttribute("SpinCenter", at(ctx, 1.5, y + 3, -4))
	local tesla = Kit.group(exp, "BobinaTesla")
	Kit.cyl(ctx, tesla, "Base", 1.2, 3, CF(-19.5, y + 0.6, 4.5), C.Dark, M.Metal, true)
	Kit.cyl(ctx, tesla, "Bobina", 5, 1.2, CF(-19.5, y + 3.7, 4.5), rgb(200, 120, 60), M.Metal, true)
	local toroid = Kit.cyl(ctx, tesla, "Toroide", 0.8, 3.2, CF(-19.5, y + 6.6, 4.5), C.Chrome, M.Metal)
	local spark = Kit.neon(ctx, tesla, "Chispa", V(0.6, 0.6, 0.6), CF(-19.5, y + 7.3, 4.5), rgb(220, 230, 255), 0.1)
	Kit.fx(spark, "Sparks", 14)
	local target = Kit.neon(ctx, tesla, "Pararrayos", V(0.5, 3, 0.5), CF(-21, y + 1.5, 7.4), C.Cyan, 0.2)
	Kit.beam(spark, target, rgb(210, 230, 255), 0.2, 8)
	Kit.light(ctx, spark, 14, 1.2, rgb(200, 220, 255))
	Kit.prompt(toroid, "Activar la bobina", "⚡ Bobina de Tesla", "Experiment", { Effect = "Tesla", Target = "BobinaTesla", Text = "¡KRZZZT! Un rayo violeta salta al pararrayos. Se te ponen los pelos de punta (literalmente)." })
	-- Esfera que flota sobre un campo magnético
	local field = Kit.group(exp, "CampoMagnetico")
	Kit.cyl(ctx, field, "Plataforma", 0.6, 3, CF(-14, y + 0.3, -15.5), C.Dark, M.Metal, true)
	for k = 0, 2 do
		Kit.cyl(ctx, field, "AnilloCampo", 0.15, 2.6 - k * 0.6, CF(-14, y + 0.7 + k * 0.1, -15.5), C.Cyan, M.Neon)
	end
	local orb = Kit.ball(ctx, field, "EsferaFlotante", 1.6, CF(-14, y + 4, -15.5), C.Purple, M.Neon, 0.1)
	Kit.anomaly(orb)
	Kit.spin(orb, 0.25, "Y")
	Kit.light(ctx, orb, 12, 1, C.Purple)
	Kit.fx(orb, "Energy", 8)
	Kit.prompt(field:FindFirstChild("Plataforma") :: BasePart, "Subir el campo", "🧲 Campo magnético", "Experiment", { Effect = "Float", Target = "CampoMagnetico", Text = "La esfera sube, baja y da una vuelta de campana. Cosme lo llama «el yoyó gravitatorio»." })
	-- Giroscopio sobre una mesa
	local gyro = Kit.group(exp, "Giroscopio")
	Kit.cyl(ctx, gyro, "Pie", 3, 0.3, CF(-19.6, y + 4.65, -1.5), C.Chrome, M.Metal)
	local spinRing = Kit.group(gyro, "Aros")
	for k = 0, 2 do
		local ring = Kit.cylX(ctx, spinRing, "Aro", 0.15, 2.2 - k * 0.4, CF(-19.6, y + 6.6, -1.5) * ANG(k * 1.1, k * 0.7, 0), ({ C.Yellow, C.Cyan, C.Magenta })[k + 1], M.Neon)
		ring.Transparency = 0.2
	end
	Kit.spin(spinRing, 0.6, "Y")
	spinRing:SetAttribute("SpinCenter", at(ctx, -19.6, y + 6.6, -1.5))
	Kit.anomaly(spinRing)
	local gen = Kit.group(exp, "Generador")
	Kit.box(ctx, gen, "Cuerpo", V(3.4, 3.6, 3.4), CF(1.5, y + 1.8, -18.4), rgb(80, 86, 100), M.Metal)
	local gcore = Kit.cyl(ctx, gen, "Nucleo", 2, 1.4, CF(1.5, y + 4.6, -18.4), C.Green, M.Neon, false, 0.2)
	Kit.light(ctx, gcore, 12, 1, C.Green, "Experimentos")
	Kit.prompt(gcore, "Encender el generador", "🔋 Generador", "Machine", { Target = "Generador", Text = "El generador ronronea. Las luces de toda la casa parpadean un momento. Ups." })
	Props.scatter(ctx, exp, { -21, -16, -9, 7 }, y + 0.08, 5, { "CableRun", "Crate", "Pile", "Barrel" })
	Kit.robot(ctx, exp, -6, y + 0.08, -12, "Mini", { { -6, -12 }, { -12, -6 }, { -6, 0 }, { -2, -8 } }, 2)
	local board = Kit.wallScreen(ctx, exp, CF(-8.5, y + 7, Layout.Core.Z1 - 0.35), 4, 3, "Sim")
	Kit.doc(board, "Pizarra de experimentos", "«Experimento 412: ¿Puede un portal abrirse dentro de otro portal? Respuesta: sí. ¿Debería? No.»", "CosmePizarra")
	local wb = Kit.wallScreen(ctx, exp, CF(-20, y + 7, Layout.Core.Z1 - 0.35), 3.4, 3, "Equations")
	wb.Name = "PizarraDibujos"

	---------------------------------------------------------------- Sala de ordenadores
	local comp = Kit.group(u, "Ordenadores")
	overlay(ctx, comp, "Floor", -22, -8, Layout.Core.Z1, 24, y, rgb(40, 44, 54), M.DiamondPlate)
	for _, z in { 12, 20 } do
		local bar = Kit.ceilingLamp(ctx, comp, -15, CU, z, "Ordenadores", "Bar", C.Cyan)
		bar.Color = C.Cyan
	end
	Kit.switch(ctx, comp, -11.5, y + 4, 9.1, 0, "Ordenadores")
	-- Pared de pantallas (3 × 3) sobre la mesa larga, con monitores
	local wallKinds = { "Map", "Coords", "Camera", "Anomalies", "Sim", "Graph", "Camera", "Stars", "Coords" }
	for row = 0, 2 do
		for col = 0, 2 do
			Kit.wallScreen(ctx, comp, CF(-21.45, y + 5.2 + row * 2.6, 11.5 + col * 4.6) * ANG(0, -math.pi / 2, 0), 4.2, 2.3, wallKinds[row * 3 + col + 1])
		end
	end
	Kit.box(ctx, comp, "MesaLarga", V(3, 0.3, 13), CF(-19.6, y + 3, 16), C.Dark, M.Metal)
	for _, z in { 10.2, 21.8 } do
		Kit.box(ctx, comp, "PataMesa", V(2.6, 2.85, 0.4), CF(-19.6, y + 1.43, z), C.Dark, M.Metal)
	end
	local monitorKinds = { "Equations", "Map", "Coords", "Sim" }
	for i, kind in monitorKinds do
		local screen = Kit.monitor(ctx, comp, CF(-20.2, y + 3.15, 10.8 + i * 2.4) * ANG(0, -math.pi / 2, 0), 2.1, 1.4, kind)
		if i == 3 then
			Kit.prompt(screen, "Usar el ordenador", "💻 Ordenador central", "Screen", { Title = "Ordenador central de Cosme", Text = "> ANOMALÍAS ACTIVAS: 7\n> Coordenadas más intensas: 66-B (crece 3 cm cada noche)\n> Cámara del jardín: un pez con corbata mirando la casa\n> Simulación del portal: estable al 66 %\n> Próximo objetivo: «LUNA» (faltan piezas)", PropId = "CosmeOrdenador" })
		end
	end
	Props.scatter(ctx, comp, { -20.8, -18.4, 10, 22 }, y + 3.15, 4, { "Keyboard", "Mug", "Chip", "Papers" })
	local cfu = Kit.furn(ctx, comp)
	for _, z in { 13.5, 18.5 } do
		Furniture.officeChair(cfu, at(ctx, -17.4, y, z, 90), rgb(30, 30, 34), comp)
	end
	-- Servidores con luces, refrigeración y cables
	for i = 0, 2 do
		local rack = Kit.group(comp, "Servidor")
		local x = -20.5 + i * 2.6
		Kit.box(ctx, rack, "Armario", V(2.2, 8, 2.4), CF(x, y + 4, 22.6), rgb(26, 28, 34), M.Metal)
		for k = 0, 9 do
			Kit.neon(ctx, rack, "Led", V(1.6, 0.08, 0.05), CF(x, y + 1 + k * 0.7, 21.38), ({ C.Cyan, C.Green, C.Blue, C.Magenta })[(k + i) % 4 + 1], 0.2)
		end
	end
	local cooler = Kit.group(comp, "Refrigeracion")
	Kit.box(ctx, cooler, "Unidad", V(3, 4, 2.6), CF(-10, y + 2, 22.6), rgb(200, 205, 210), M.Metal)
	local fan = Kit.cylX(ctx, cooler, "Ventilador", 0.2, 2, CF(-10, y + 2.6, 21.25) * ANG(0, math.pi / 2, 0), C.Dark)
	Kit.spin(fan, 1.2, "X")
	Kit.fx(Kit.neon(ctx, cooler, "Rejilla", V(2, 0.2, 0.2), CF(-10, y + 4.1, 22.6), C.Cyan, 0.4), "Steam", 3)
	for i = 0, 2 do
		Props.make(ctx, comp, "CableRun", CF(-12 + i * 1.2, y + 0.08, 12 + i * 3))
	end

	---------------------------------------------------------------- Sala de observación (mirador de cristal)
	local obs = Kit.group(u, "Observacion")
	local B = Layout.Bay
	overlay(ctx, obs, "Floor", -8, 16, Layout.Core.Z1, 24, y, rgb(60, 66, 84), M.WoodPlanks)
	ringLight(ctx, obs, 4, CU, 16, "Observacion", nil, rgb(190, 220, 255))
	Kit.switch(ctx, obs, 1.5, y + 4, 9.1, 0, "Observacion")
	-- Aro de luz grande en el techo del mirador
	local halo = Kit.cyl(ctx, obs, "AroMirador", 0.3, 14, CF(B.X, CU - 0.4, B.Z + 5), rgb(190, 220, 255), M.Neon)
	halo.CastShadow = false
	Kit.cyl(ctx, obs, "AroMiradorHueco", 0.32, 13, CF(B.X, CU - 0.4, B.Z + 5), C.Dark)
	-- Dos sillones mirando al cristal, mesita y un telescopio de mano en su trípode
	local of = Kit.furn(ctx, obs, rgb(60, 60, 70), rgb(230, 226, 214), C.Cyan)
	Furniture.armchair(of, at(ctx, -1.5, y, 31, 180), rgb(230, 226, 214), obs)
	Furniture.armchair(of, at(ctx, 9.5, y, 31, 180), rgb(230, 226, 214), obs)
	Kit.cyl(ctx, obs, "Mesita", 2.4, 2, CF(4, y + 1.2, 33.5), C.White, M.Metal, true)
	Props.make(ctx, obs, "Mug", CF(4, y + 2.4, 33.5))
	local scope = Kit.group(obs, "Catalejo")
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		Kit.deco(ctx, scope, "Pata", V(0.15, 3.4, 0.15), CF(12 + math.cos(a) * 0.5, y + 1.6, 26 + math.sin(a) * 0.5) * ANG(math.sin(a) * 0.15, 0, -math.cos(a) * 0.15), C.Dark, M.Metal)
	end
	Kit.cylX(ctx, scope, "Tubo", 2.6, 0.5, CF(12, y + 3.5, 26) * ANG(0, -math.pi / 2, 0) * ANG(0, 0, 0.5), C.Chrome, M.Metal)
	-- Cartas estelares, plantas y una pantalla con la luna
	for i, kind in { "Stars", "Stars" } do
		Kit.wallScreen(ctx, obs, CF(-7.65, y + 6, 12 + i * 4) * ANG(0, -math.pi / 2, 0), 3, 2.2, kind)
	end
	local moon = Kit.wallScreen(ctx, obs, CF(15.65, y + 6, 16) * ANG(0, math.pi / 2, 0), 4, 3, "Stars")
	Kit.doc(moon, "Carta de la Luna", "«Distancia a la luna: 384.400 km. Distancia a la luna en portal: 3 pasos (si sale bien). Distancia a la luna en portal si sale mal: 66-B.»", "CosmeCartaLuna")
	for _, p in { { -6.5, 10 }, { 14.5, 10 }, { -4, 26 }, { 12, 31 } } do
		Props.make(ctx, obs, "Plant", CF(p[1], y, p[2]))
	end
	return u
end

function Interior.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "Interior")
	core(ctx, m)
	groundFloor(ctx, m)
	upperFloor(ctx, m)
	return m
end

return Interior
