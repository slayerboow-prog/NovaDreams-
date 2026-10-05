-- Laboratory: el laboratorio de inventos de la planta baja y el sótano de Cosme, como el plano del
-- dueño (docs/referencias/plano-casa-cosme.png; medidas en CosmeHouse/Layout).
--
--   * Laboratorio de inventos (planta baja, detrás del comedor): la MÁQUINA REDONDA en el centro (el
--     cilindro de energía de cristal sobre su plataforma, con anillos que giran, seis bobinas y haces),
--     pizarras con dibujos, mesas con monitores, estanterías y robots (como el panel del render).
--   * Sótano (debajo de la casa, MÁS grande de lo que parece: «¿cómo cabe todo esto aquí?»):
--     el pasillo con la escalera en medio, la sala del portal (el aro GIGANTE con el vórtice morado y
--     la plataforma de luz en el suelo, que se activa y cambia de destino: CosmeHouse/PortalSystem),
--     el taller (con la estantería secreta: CosmeHouse/SecretRoom) y el almacén.
--     (El garaje del sótano, con el segundo coche, lo pone CosmeHouse/Garage.)

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local PortalSystem = require(script.Parent.PortalSystem)
local Furniture = require(script.Parent.Parent.Furniture)

local Laboratory = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local F0 = Layout.F0
local FB = Layout.FB
local TOP = Layout.CEIL.B
local WALL = rgb(58, 64, 78)
local WALL2 = rgb(44, 48, 60)

local function op(a: number, b: number, bottom: number, top: number, kind: string?): Kit.Opening
	return { A = a, B = b, Bottom = bottom, Top = top, Kind = kind }
end

local function wall(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, a: number, b: number, openings: { Kit.Opening }?, color: Color3?)
	return Kit.wall(ctx, parent, axis, fixed, a, b, FB - 1, TOP, { Thick = 1, Name = "InnerWall", Color = color or WALL, Material = M.Concrete, Openings = openings, Frame = C.Dark })
end

local function door(a: number, b: number): Kit.Opening
	return op(a, b, FB, FB + 9.5)
end

-- Aro de piezas (para los anillos que giran de las máquinas)
local function ring(ctx: Kit.Ctx, parent: Instance, name: string, center: CFrame, radius: number, n: number, color: Color3, thick: number): Model
	local m = Kit.group(parent, name)
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		local seg = 2 * math.pi * radius / n + 0.12
		local glow = i % 4 == 0
		local p = Kit.deco(ctx, m, if glow then "Luz" else "Segmento", V(seg, thick, thick * 1.4), center * CF(math.cos(a) * radius, math.sin(a) * radius, 0) * ANG(0, 0, a + math.pi / 2), if glow then color else rgb(90, 96, 112), if glow then M.Neon else M.DiamondPlate, nil, true)
		p.CastShadow = false
	end
	return m
end
Laboratory.ring = ring

---------------------------------------------------------------------
-- Laboratorio de inventos (planta baja)
---------------------------------------------------------------------
local MC = V(-13, F0, 15) -- centro de la máquina redonda

local function machine(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "MaquinaEspacioTiempo")
	local cx, cz = MC.X, MC.Z
	local y = F0
	-- Plataforma redonda con dos escalones y círculos de luz
	Kit.disc(ctx, m, "Plataforma", cx, cz, 4.6, y + 0.5, 0.5, rgb(60, 64, 76), M.DiamondPlate)
	Kit.disc(ctx, m, "Plataforma", cx, cz, 3.6, y + 1, 0.5, rgb(70, 74, 88), M.DiamondPlate)
	for k = 0, 1 do
		local r = Kit.cyl(ctx, m, "AnilloSuelo", 0.06, 9 - k * 2.2, CF(cx, y + 0.53 + k * 0.5, cz), if k == 0 then C.Cyan else C.Purple, M.Neon)
		r.Transparency = 0.2
		Kit.cyl(ctx, m, "HuecoSuelo", 0.07, 8.6 - k * 2.2, CF(cx, y + 0.535 + k * 0.5, cz), rgb(66, 70, 84), M.DiamondPlate)
	end
	-- El cilindro de energía: tubo de cristal, núcleo de neón que gira, tapas y anillos
	local base = y + 1
	Kit.cyl(ctx, m, "Base", 1.2, 4.4, CF(cx, base + 0.6, cz), C.Dark, M.Metal, true)
	Kit.cyl(ctx, m, "Tubo", 7.2, 3.2, CF(cx, base + 4.8, cz), rgb(160, 210, 255), M.Glass, true, 0.6)
	local energy = Kit.cyl(ctx, m, "Energia", 7, 1.5, CF(cx, base + 4.8, cz), C.Cyan, M.Neon, false, 0.1)
	Kit.light(ctx, energy, 26, 1.6, C.Cyan)
	Kit.fx(energy, "Energy", 14)
	Kit.spin(energy, 0.3, "Y")
	Kit.cyl(ctx, m, "Tapa", 1.2, 4.4, CF(cx, base + 9, cz), C.Dark, M.Metal, true)
	Kit.cyl(ctx, m, "Conducto", Layout.CEIL.G - (base + 9.6), 1.6, CF(cx, (base + 9.6 + Layout.CEIL.G) / 2, cz), rgb(120, 126, 136), M.Metal, true)
	for k = 0, 2 do
		local band = Kit.cyl(ctx, m, "AnilloTubo", 0.35, 3.5, CF(cx, base + 2.6 + k * 2.2, cz), if k == 1 then C.Purple else C.Cyan, M.Neon)
		band.Transparency = 0.15
	end
	-- Dos anillos que giran alrededor del cilindro (como un giroscopio)
	local center = Kit.world(ctx, CF(cx, base + 4.8, cz))
	for i, spec in { { 3.4, 0.12, "Y", 0 }, { 3.0, -0.18, "Y", math.pi / 2 } } do
		local r = ring(ctx, m, "AnilloGiratorio" .. i, CF(cx, base + 4.8, cz) * ANG(0, spec[4], 0), spec[1], 20, ({ C.Cyan, C.Purple })[i], 0.4)
		Kit.spin(r, spec[2], spec[3])
		r:SetAttribute("SpinCenter", center)
		r:SetAttribute("MachinePart", true)
		Kit.anomaly(r)
	end
	-- Seis bobinas alrededor con haces de energía hasta el cilindro
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local x, z = cx + math.cos(a) * 5.6, cz + math.sin(a) * 5.6
		local coil = Kit.group(m, "BobinaGrande")
		Kit.cyl(ctx, coil, "Base", 0.6, 2, CF(x, y + 0.3, z), C.Dark, M.Metal, true)
		Kit.cyl(ctx, coil, "Nucleo", 5, 0.9, CF(x, y + 3, z), rgb(70, 74, 86), M.Metal, true)
		for k = 0, 4 do
			Kit.cyl(ctx, coil, "Espira", 0.2, 1.5, CF(x, y + 1.3 + k * 0.85, z), rgb(200, 120, 60), M.Metal)
		end
		local tip = Kit.ball(ctx, coil, "Punta", 1.1, CF(x, y + 5.9, z), if i % 2 == 0 then C.Cyan else C.Purple, M.Neon, 0.1)
		local b = Kit.beam(tip, energy, if i % 2 == 0 then C.Cyan else C.Purple, 0.25, 10)
		b.CurveSize0 = 1.5
		b.CurveSize1 = -1
		if i % 2 == 0 then
			Kit.fx(tip, "Sparks", 8)
		end
	end
	-- Consolas delante (simulación, coordenadas y el destino) y su aviso
	local console = Kit.group(m, "Consola")
	for i, kind in { "Sim", "Coords", "Portal" } do
		local x = cx - 4.6 + (i - 1) * 3.4
		local desk = Kit.box(ctx, console, "Mueble", V(3, 3, 1.4), CF(x, y + 1.5, 6.6), rgb(50, 54, 66), M.Metal)
		Kit.deco(ctx, console, "Tablero", V(3, 0.2, 1.6), CF(x, y + 3.2, 6.4) * ANG(0.35, 0, 0), C.Dark, M.Metal, nil, true)
		for k = 0, 4 do
			Kit.neon(ctx, console, "Boton", V(0.3, 0.12, 0.3), CF(x - 1.2 + k * 0.6, y + 3.3, 6.4) * ANG(0.35, 0, 0), ({ C.Red, C.Green, C.Yellow, C.Cyan })[k % 4 + 1])
		end
		local screen = Kit.monitor(ctx, console, CF(x, y + 3, 7.1), 2.6, 1.6, kind, "ESTABLE 66 %")
		if i == 2 then
			Kit.prompt(desk, "Encender la máquina", "🌀 Máquina del espacio-tiempo", "Machine", { Target = "MaquinaEspacioTiempo", PropId = "CosmeMaquina", Text = "Los anillos aceleran, las bobinas escupen rayos y el cilindro se pone azul eléctrico… «¡Faltan piezas!», dice una pantalla." }, 0.5)
		elseif i == 1 then
			Kit.doc(screen, "Simulación de la máquina", "MÁQUINA DEL ESPACIO-TIEMPO v12\n• Anillos: 2/3 girando\n• Bobinas: 6/6\n• Condensador de grieta: FALTA\n• Destino programado: LUNA\n• Probabilidad de llegar entero: 66 %\n\n«Necesito al vecino para la prueba final.»", "CosmeSimulacion")
		end
	end
	return m
end

local function inventions(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Laboratorio")
	local y = F0
	machine(ctx, m)
	-- Suelo oscuro técnico, luces (aro LED y lámparas) y franjas de luz en el techo
	Kit.box(ctx, m, "Floor", V(26, 0.06, 20), CF(-9, y + 0.03, 14), rgb(56, 62, 78), M.DiamondPlate, { CanQuery = true, CastShadow = false })
	Kit.ceilingLamp(ctx, m, -4, Layout.CEIL.G, 9, "Laboratorio", "Ring", rgb(200, 230, 255))
	Kit.ceilingLamp(ctx, m, -4, Layout.CEIL.G, 20, "Laboratorio", "Bar", rgb(220, 240, 255))
	Kit.switch(ctx, m, -11.5, y + 4, 4.4, 180, "Laboratorio")
	for _, x in { -20, -2 } do
		Kit.neon(ctx, m, "TiraTecho", V(0.3, 0.12, 18), CF(x, Layout.CEIL.G - 0.15, 14), C.Cyan, 0.2)
	end
	-- Pizarras con dibujos (paredes del garaje y del aseo)
	local wb1 = Kit.wallScreen(ctx, m, CF(-21.45, y + 6.5, 8.5) * ANG(0, -math.pi / 2, 0), 6, 3.6, "Equations")
	wb1.Name = "PizarraInventos"
	Kit.doc(wb1, "Pizarra de inventos", "Dibujos de un cohete con forma de tostadora, un perro robot y una flecha enorme que dice «LUNA →». Abajo: «Paso 1: máquina. Paso 2: piezas. Paso 3: ¡vecino!».", "CosmePizarraInventos")
	local wb2 = Kit.wallScreen(ctx, m, CF(3.65, y + 6.5, 18) * ANG(0, math.pi / 2, 0), 6, 3.6, "Plans")
	wb2.Name = "PizarraInventos"
	local notes = Kit.deco(ctx, m, "PizarraBlanca", V(0.12, 3.6, 5), CF(3.62, y + 6.5, 11.5), rgb(244, 244, 240), nil, nil, true)
	Kit.signText(notes, "IDEAS DE HOY:\n· coche que vuela (casi)\n· portal de bolsillo\n· apio infinito", Enum.NormalId.Left, rgb(40, 60, 120), rgb(244, 244, 240))
	-- Mesas de trabajo con monitores contra la pared del aseo
	for _, z in { 12, 18.5 } do
		local bm = Kit.group(m, "MesaTrabajo")
		Kit.box(ctx, bm, "Tablero", V(2.8, 0.3, 5.4), CF(2.2, y + 3, z), rgb(120, 96, 70), M.Wood)
		for _, sz in { -1, 1 } do
			Kit.box(ctx, bm, "Pata", V(2.4, 2.85, 0.3), CF(2.2, y + 1.43, z + sz * 2.4), C.Dark, M.Metal)
		end
		Kit.monitor(ctx, bm, CF(2.9, y + 3.15, z) * ANG(0, math.pi / 2, 0), 2.2, 1.4, if z < 15 then "Graph" else "Map")
		Props.scatter(ctx, bm, { 0.9, 3.4, z - 2.5, z + 2.5 }, y + 3.15, 5, Props.Lab)
	end
	-- Estantería de inventos, robot grande apagado y un robot que pasea
	Props.shelf(ctx, m, CF(-21.1, y, 19) * ANG(0, -math.pi / 2, 0), 5, 9, "Lab").Name = "EstanteriaInventos"
	local bot = Kit.group(m, "RobotGrande")
	Kit.box(ctx, bot, "Piernas", V(2.2, 3.4, 1.3), CF(-20.6, y + 1.7, 5.6), rgb(160, 166, 180), M.Metal)
	Kit.box(ctx, bot, "Torso", V(3, 3, 1.8), CF(-20.6, y + 4.9, 5.6), rgb(180, 186, 200), M.Metal)
	Kit.box(ctx, bot, "Cabeza", V(1.8, 1.4, 1.4), CF(-20.6, y + 7.1, 5.6), rgb(200, 205, 215), M.Metal)
	Kit.neon(ctx, bot, "Ojos", V(0.05, 0.3, 1.2), CF(-19.68, y + 7.2, 5.6), C.Red, 0.3)
	Kit.doc(bot:FindFirstChild("Torso") :: BasePart, "Robot «Pip 0»", "El primer intento de Pip. Placa: «PIP 0 — demasiado sincero. Desconectado por decirle a Cosme que su pelo parece un experimento.»", "CosmePip0")
	Kit.robot(ctx, m, -6, y + 0.06, 21, "Mini", { { -6, 21 }, { -18, 22 }, { -19, 11 } }, 2.2)
	Props.scatter(ctx, m, { -21, -16, 5, 9 }, y + 0.06, 4, { "Crate", "CableRun", "Pile" })
	Props.scatter(ctx, m, { -20, -8, 21, 23 }, y + 0.06, 4, { "Screws", "Papers", "Tool", "Battery" })
	-- Puerta de atrás (a la terraza)
	Kit.door(ctx, m, -4, y, Layout.House.Z1, 180, 6, 9.3, rgb(70, 74, 84), true)
	return m
end

---------------------------------------------------------------------
-- Sótano: cascarón, suelo, techo y tabiques
---------------------------------------------------------------------
local function shell(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Cascaron")
	local B = { X0 = Layout.Basement.X0, X1 = Layout.Basement.X1, Z0 = Layout.Basement.Z0, Z1 = 32 }
	Kit.slab(ctx, m, "Floor", B, FB, 1, nil, rgb(74, 80, 92), M.Concrete)
	-- Techo (debajo de la losa del jardín), con el hueco de la escalera
	Kit.slab(ctx, m, "Ceiling", B, TOP, 0.2, require(script.Parent.Exterior).coreHoles(), rgb(40, 44, 52), M.Concrete)
	-- Muros de fuera (contra la tierra); el trozo de atrás del taller lo pone SecretRoom
	wall(ctx, m, "X", B.Z0, B.X0 - 0.5, B.X1 + 0.5)
	wall(ctx, m, "X", B.Z1, B.X0 - 0.5, 16)
	wall(ctx, m, "X", B.Z1, 40, B.X1 + 0.5)
	wall(ctx, m, "Z", B.X0, B.Z0, B.Z1)
	wall(ctx, m, "Z", B.X1, B.Z0, B.Z1)
	-- Tabiques: pasillo | portales, almacén | taller, portales | taller, garaje | pasillo, pasillo | almacén
	wall(ctx, m, "Z", 16, B.Z0, -8, { door(-25, -19) }, WALL2)
	wall(ctx, m, "Z", 16, Layout.Core.Z1, B.Z1, { door(17, 23) })
	wall(ctx, m, "X", 8, 16, B.X1, { door(37, 43) })
	wall(ctx, m, "Z", -8, B.Z0, B.Z1, { door(-25, -19) }, WALL2)
	wall(ctx, m, "X", Layout.Core.Z1, -8, 4, { door(-5, 1) })
	Kit.door(ctx, m, 16, FB, -22, -90, 6, 9.3, rgb(60, 50, 90), true)
	Kit.door(ctx, m, 16, FB, 20, -90, 6, 9.3, rgb(90, 80, 70), true)
	Kit.door(ctx, m, 40, FB, 8, 0, 6, 9.3, rgb(60, 50, 90), true)
	Kit.door(ctx, m, -8, FB, -22, 90, 6, 9.3, rgb(70, 74, 84), true)
	Kit.door(ctx, m, -2, FB, Layout.Core.Z1, 180, 6, 9.3, rgb(90, 80, 70), true)
	return m
end

---------------------------------------------------------------------
-- Pasillo del sótano (con la escalera en medio)
---------------------------------------------------------------------
local function corridor(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "PasilloSotano")
	for _, p in { { 4, -24 }, { -2, -6 } } do
		Kit.ceilingLamp(ctx, m, p[1], TOP, p[2], "PasilloSotano", "Bar", C.Cyan)
	end
	Kit.switch(ctx, m, 15.4, FB + 4, -14, -90, "PasilloSotano")
	-- Rayas de peligro en el suelo (como el sótano del render) y tiras de luz
	for i = 0, 11 do
		Kit.deco(ctx, m, "Franja", V(1.4, 0.04, 0.6), CF(-6 + i * 1.9, FB + 0.02, -12.6) * ANG(0, 0.7, 0), if i % 2 == 0 then C.Yellow else C.Dark, nil, nil, true)
	end
	for i = 0, 7 do
		Kit.neon(ctx, m, "TiraSuelo", V(1.6, 0.05, 0.2), CF(-6 + i * 3, FB + 0.03, -31.3), C.Cyan, 0.3)
	end
	for i, kind in { "Map", "Coords" } do
		Kit.wallScreen(ctx, m, CF(-2 + i * 6, FB + 6.5, -31.45) * ANG(0, math.pi, 0), 4, 2.6, kind)
	end
	local sign = Kit.deco(ctx, m, "Cartel", V(0.1, 1.2, 5), CF(15.45, FB + 10.4, -22), C.Dark, nil, nil, true)
	Kit.signText(sign, "PORTAL →", Enum.NormalId.Left, C.Cyan, C.Dark)
	local sign2 = Kit.deco(ctx, m, "Cartel", V(0.1, 1.2, 5), CF(-7.45, FB + 10.4, -22), C.Dark, nil, nil, true)
	Kit.signText(sign2, "← GARAJE", Enum.NormalId.Right, C.Yellow, C.Dark)
	for i = 0, 2 do
		Props.make(ctx, m, "Crate", CF(12 - i * 2.6, FB, -30.4) * ANG(0, i, 0))
	end
	Props.make(ctx, m, "Barrel", CF(-6.4, FB, -30.6))
	Props.scatter(ctx, m, { -7, -4, -18, -4 }, FB, 4, { "CableRun", "Pile" })
	-- Mangueras de cables que bajan por la pared y tuberías por el techo
	for i = 0, 3 do
		Kit.deco(ctx, m, "CableBajada", V(0.3, TOP - FB, 0.3), CF(-7.3, (TOP + FB) / 2, -14 + i * 0.45), ({ C.Dark, C.Red, C.Blue, C.Yellow })[i + 1], M.Rubber)
	end
	for i = 0, 2 do
		Kit.cylX(ctx, m, "Tuberia", 22, 0.6, CF(4, TOP - 0.8 - i * 0.8, -30.8), ({ rgb(160, 120, 70), rgb(120, 126, 136), rgb(60, 130, 90) })[i + 1], M.Metal)
	end
	return m
end

---------------------------------------------------------------------
-- Sala del portal: el aro gigante con el vórtice morado y la plataforma de luz
---------------------------------------------------------------------
local PC = V(30, FB, -4) -- pie del portal (el aro mira a -Z, hacia la puerta)

local function portalRoom(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "SalaPortales")
	local cy = FB + 5.9
	-- Suelo oscuro con la plataforma de luz delante del portal (círculos que brillan)
	Kit.box(ctx, m, "Floor", V(28, 0.06, 40), CF(30, FB + 0.03, -12), rgb(30, 26, 48), M.Slate, { CanQuery = true, CastShadow = false })
	local pad = V(30, FB, -10.5)
	Kit.disc(ctx, m, "Plataforma", pad.X, pad.Z, 4.6, FB + 0.4, 0.4, rgb(50, 46, 72), M.DiamondPlate)
	for k = 0, 2 do
		local r = Kit.cyl(ctx, m, "CirculoSuelo", 0.06, 8.6 - k * 2.6, CF(pad.X, FB + 0.43, pad.Z), if k % 2 == 0 then C.Purple else C.Cyan, M.Neon)
		r.Transparency = 0.15
		Kit.cyl(ctx, m, "HuecoSuelo", 0.07, 8.0 - k * 2.6, CF(pad.X, FB + 0.435, pad.Z), rgb(50, 46, 72), M.DiamondPlate)
	end
	local padGlow = Kit.neon(ctx, m, "LuzPlataforma", V(1.2, 0.1, 1.2), CF(pad.X, FB + 0.45, pad.Z), C.Purple, 0.4)
	local padLight = Kit.light(ctx, padGlow, 16, 1.2, C.Purple, nil, "Surface")
	if padLight then
		(padLight :: SurfaceLight).Face = Enum.NormalId.Top
	end
	-- Luces del techo en aro (moradas) y el interruptor
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local lamp = Kit.neon(ctx, m, "LuzAro", V(3, 0.3, 0.8), CF(30 + math.cos(a) * 9, TOP - 0.4, -12 + math.sin(a) * 9) * ANG(0, -a, 0), C.Purple, 0.1)
		if i % 2 == 0 then
			Kit.light(ctx, lamp, 24, 1.1, rgb(190, 150, 255), "Portales")
		else
			lamp:AddTag("RoomLight")
			lamp:SetAttribute("Room", "Portales")
			lamp:SetAttribute("OnColor", lamp.Color)
			lamp:SetAttribute("OnMaterial", "Neon")
		end
	end
	Kit.switch(ctx, m, 16.6, FB + 4, -26, 90, "Portales")
	-- El portal GIGANTE con el vórtice morado, de pie, mirando a la puerta
	local portal = PortalSystem.build(ctx, m, CF(PC.X, cy, PC.Z), 4.6, { Name = "PortalGigante", Color = C.Purple, Depth = 5, Layers = 14, Spin = 0.15, Stand = cy - FB - 4.6 - 0.8, Destination = 1, Arms = 6 })
	portal:SetAttribute("Main", true)
	-- Gran anillo exterior que gira despacio (en el mismo plano)
	local outer = ring(ctx, m, "AnilloExterior", CF(PC.X, cy, PC.Z + 0.6), 5.6, 30, C.Cyan, 0.5)
	Kit.spin(outer, -0.05, "Z")
	outer:SetAttribute("SpinCenter", Kit.at(ctx, PC.X, cy, PC.Z + 0.6))
	Kit.anomaly(outer)
	-- Bobinas a los lados del portal
	for _, sx in { -1, 1 } do
		local x = PC.X + sx * 7.6
		local coil = Kit.group(m, "BobinaPortal")
		Kit.cyl(ctx, coil, "Base", 0.6, 2.4, CF(x, FB + 0.3, PC.Z), C.Dark, M.Metal, true)
		Kit.cyl(ctx, coil, "Nucleo", 7, 1, CF(x, FB + 4, PC.Z), rgb(70, 74, 86), M.Metal, true)
		for k = 0, 5 do
			Kit.cyl(ctx, coil, "Espira", 0.2, 1.6, CF(x, FB + 1.5 + k * 0.95, PC.Z), rgb(200, 120, 60), M.Metal)
		end
		local tip = Kit.ball(ctx, coil, "Punta", 1.2, CF(x, FB + 8, PC.Z), C.Purple, M.Neon, 0.1)
		Kit.fx(tip, "Sparks", 6)
	end
	-- Consola: activar el portal y cambiar de destino (y su pantalla con el destino)
	local main = Kit.group(m, "ConsolaPortal")
	Kit.box(ctx, main, "Mueble", V(5, 3.2, 1.8), CF(21.5, FB + 1.6, -14), rgb(50, 46, 70), M.Metal)
	Kit.deco(ctx, main, "Tablero", V(5, 0.2, 2), CF(21.5, FB + 3.4, -14.2) * ANG(-0.35, 0, 0), C.Dark, M.Metal, nil, true)
	local lever = Kit.neon(ctx, main, "Palanca", V(0.4, 1.4, 0.4), CF(23.1, FB + 4.1, -14.4), C.Red)
	Kit.prompt(lever, "Activar el portal", "🌀 Portal gigante", "Portal", { Target = "PortalGigante", PropId = "CosmePortalGigante" }, 0.8)
	local dial = Kit.neon(ctx, main, "Selector", V(0.9, 0.3, 0.9), CF(19.9, FB + 3.7, -14.3), C.Cyan)
	Kit.prompt(dial, "Cambiar de destino", "🧭 Selector de destino", "PortalDial", { Target = "PortalGigante" })
	Kit.monitor(ctx, main, CF(21.5, FB + 3.2, -13.4) * ANG(0, math.pi, 0), 3, 1.8, "Portal", PortalSystem.Destinations[1].Name)
	-- Pantallas en las paredes, la pizarra del portal (como el panel del render) y cajas
	for i, kind in { "Portal", "Stars", "Sim" } do
		Kit.wallScreen(ctx, m, CF(43.45, FB + 6.5, -28 + i * 5) * ANG(0, math.pi / 2, 0), 3.6, 2.4, kind, PortalSystem.Destinations[1].Name)
	end
	local board = Kit.wallScreen(ctx, m, CF(24, FB + 6.5, -31.45) * ANG(0, math.pi, 0), 5, 3.4, "Equations")
	Kit.doc(board, "Pizarra de la sala del portal", "«Destinos probados: espacio profundo ✔, los Pliegues ✔ (no tocar nada), bosque de otra Valmar ✔, la Luna ✘ (nos quedamos cortos), 66-B ✘✘✘ (NO)».", "CosmePizarraPortales")
	local spiral = Kit.deco(ctx, m, "PizarraEspiral", V(4, 3.4, 0.12), CF(34, FB + 6.5, -31.42), rgb(26, 30, 44), M.Slate, nil, true)
	Kit.signText(spiral, "OTRAS\nCERCANÍAS\n🌀", Enum.NormalId.Back, rgb(210, 220, 255), rgb(26, 30, 44))
	for i = 0, 3 do
		Props.make(ctx, m, if i % 2 == 0 then "Crate" else "Barrel", CF(18 + (i % 2) * 2.4, FB, 3.4 + math.floor(i / 2) * 2.4))
	end
	Props.make(ctx, m, "Plant", CF(17.5, FB, -30.5))
	Props.scatter(ctx, m, { 17, 22, -30, -18 }, FB, 4, { "CableRun", "Pile" })
	-- Mesa con ordenador (como el panel del portal del render)
	Furniture.desk(Kit.furn(ctx, m, rgb(40, 40, 50)), Kit.at(ctx, 41.6, FB, -24, -90), { Width = 5, Computer = true, Chair = true }, m)
	return m
end

---------------------------------------------------------------------
-- Taller (zona de trabajo) y almacén
---------------------------------------------------------------------
local function workshop(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Taller")
	for _, p in { { 24, 16 }, { 36, 24 } } do
		Kit.ceilingLamp(ctx, m, p[1], TOP, p[2], "Taller", "Industrial", rgb(255, 236, 200))
	end
	Kit.switch(ctx, m, 16.6, FB + 4, 25, 90, "Taller")
	-- Bancos de trabajo con tableros de herramientas y cajoneras rojas
	local benches = { { 26, 9.6, 0 }, { 42.4, 18, 90 }, { 42.4, 26, 90 } }
	for i, b in benches do
		local bm = Kit.group(m, "BancoTrabajo")
		local w, d = if b[3] == 0 then 12 else 2.8, if b[3] == 0 then 2.8 else 6
		Kit.box(ctx, bm, "Tablero", V(w, 0.35, d), CF(b[1], FB + 3.2, b[2]), rgb(150, 108, 72), M.Wood)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Kit.box(ctx, bm, "Pata", V(0.3, 3, 0.3), CF(b[1] + sx * (w / 2 - 0.3), FB + 1.5, b[2] + sz * (d / 2 - 0.3)), C.Dark, M.Metal)
			end
		end
		Props.scatter(ctx, bm, { b[1] - w / 2, b[1] + w / 2, b[2] - d / 2, b[2] + d / 2 }, FB + 3.37, if b[3] == 0 then 9 else 5, { "Tool", "Screws", "Chip", "Gadget", "Battery", "Coil", "Clipboard" })
		Props.make(ctx, bm, "Lamp", CF(b[1] - w / 2 + 0.7, FB + 3.37, b[2] - d / 2 + 0.7))
		local drawer = Kit.box(ctx, bm, "Cajon", V(1.6, 0.8, 0.2), CF(b[1] + (if b[3] == 0 then 4 else 0), FB + 2.4, b[2] + (if b[3] == 0 then 1.5 else 0)), C.Red, M.Metal, { CanCollide = false })
		if b[3] ~= 0 then
			drawer.CFrame = Kit.world(ctx, CF(b[1] - 1.5, FB + 2.4, b[2]) * ANG(0, math.pi / 2, 0))
		end
		drawer:SetAttribute("SlideDir", ctx.Site:VectorToWorldSpace(if b[3] == 0 then V(0, 0, -1) else V(-1, 0, 0)))
		Kit.prompt(drawer, "Abrir el cajón", "🧰 Cajón de herramientas", "Drawer", { Slide = 1.2, Text = ({ "Llaves inglesas, un destornillador sónico de juguete y un pósit: «la llave de 66 no existe, no la busques».", "Tornillos ordenados por dimensión de origen.", "Un mapa del sótano. Hay una estantería dibujada con tres libros marcados." })[i] })
	end
	-- Panel de herramientas colgadas
	local board = Kit.deco(ctx, m, "PanelHerramientas", V(12, 5, 0.2), CF(26, FB + 7.5, 8.6), rgb(200, 160, 110), M.WoodPlanks, nil, true)
	board.Name = "PanelHerramientas"
	for k = 0, 9 do
		Kit.deco(ctx, m, "HerramientaColgada", V(0.3, ctx.Rand.range(0.8, 2), 0.15), CF(21 + k * 1.1, FB + 6 + (k % 2) * 2, 8.78), if k % 3 == 0 then C.Red else C.Chrome, M.Metal)
	end
	-- Armario de herramientas rojo (el del render) y prototipos en pedestales
	local chest = Kit.group(m, "ArmarioHerramientas")
	Kit.box(ctx, chest, "Cuerpo", V(4.4, 4.2, 2), CF(36, FB + 2.1, 30.6), rgb(200, 40, 40), M.Metal)
	for k = 0, 4 do
		Kit.deco(ctx, chest, "Cajonera", V(4, 0.08, 0.06), CF(36, FB + 0.8 + k * 0.8, 29.58), C.Chrome, M.Metal)
	end
	local items = {
		{ "Monopatín flotante", "Prototipo 7: flota a dos palmos del suelo. En curvas, flota hacia la izquierda. Siempre.", C.Magenta, 1.8 },
		{ "Mochila cohete", "Prototipo 12: sube muy bien. Bajar está «en desarrollo».", C.Orange, 2 },
		{ "Rayo encogedor", "Prototipo 19: encoge cosas un 66 %. Funcionó con una gallina. Al revés.", C.Green, 1.2 },
	}
	for i, it in items do
		local x, z = 19, 13 + i * 4.6
		local ped = Kit.group(m, "Pedestal")
		local base = Kit.box(ctx, ped, "Pedestal", V(2.6, 3, 2.6), CF(x, FB + 1.5, z), rgb(40, 44, 56), M.Marble)
		Kit.neon(ctx, ped, "Borde", V(2.7, 0.15, 2.7), CF(x, FB + 3.05, z), it[3], 0.2)
		Kit.box(ctx, ped, "Prototipo", V(it[4] * 1.2, it[4] * 0.8, it[4] * 0.8), CF(x, FB + 3.1 + it[4] * 0.4, z), it[3]:Lerp(C.Steel, 0.5), M.Metal, { CanCollide = false })
		Kit.glass(ctx, ped, "Vitrina", V(2.4, 2.8, 2.4), CF(x, FB + 4.5, z), rgb(200, 230, 245), 0.75, false)
		Kit.doc(base, it[1], it[2], "CosmeProto" .. i)
	end
	Props.scatter(ctx, m, { 30, 40, 12, 22 }, FB, 5, { "Crate", "Barrel", "CableRun", "Pile" })
	Kit.robot(ctx, m, 30, FB, 16, "Mini", { { 30, 16 }, { 36, 22 }, { 28, 24 } }, 2)
	return m
end

local function storage(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Almacen")
	for _, p in { { -2, 16 }, { 8, 26 } } do
		Kit.ceilingLamp(ctx, m, p[1], TOP, p[2], "Almacen", "Industrial")
	end
	Kit.switch(ctx, m, -6, FB + 4, 9.1, 0, "Almacen")
	-- Estanterías con cajas a lo largo de las paredes y una fila en medio
	for _, z in { 12, 18, 24 } do
		Props.shelf(ctx, m, CF(-7.1, FB, z) * ANG(0, -math.pi / 2, 0), 5.6, 9, if z == 18 then "Lab" else "Boxes")
	end
	for _, x in { -4, 3, 10 } do
		Props.shelf(ctx, m, CF(x, FB, 31.1), 6, 9, if x == 3 then "Lab" else "Boxes")
	end
	for _, x in { 3, 10 } do
		Props.shelf(ctx, m, CF(x, FB, 25.5) * ANG(0, math.pi, 0), 6, 7, "Boxes")
	end
	for i = 0, 5 do
		Props.make(ctx, m, if i % 3 == 0 then "Barrel" else "Crate", CF(13.5 - (i % 2) * 2.4, FB, 10.4 + math.floor(i / 2) * 2.4))
	end
	-- Máquinas viejas tapadas con sábanas y una carretilla
	Kit.box(ctx, m, "MaquinaTapada", V(4, 3.6, 2.4), CF(-4.4, FB + 1.8, 28), rgb(220, 218, 210), M.Fabric)
	local cart = Kit.group(m, "Carretilla")
	Kit.box(ctx, cart, "Plataforma", V(2.4, 0.3, 3.6), CF(6, FB + 0.6, 13), C.Orange, M.Metal)
	Kit.deco(ctx, cart, "Asa", V(2.4, 3, 0.2), CF(6, FB + 2.1, 14.7), C.Dark, M.Metal)
	for _, sx in { -1, 1 } do
		Kit.cylX(ctx, cart, "Rueda", 0.4, 0.9, CF(6 + sx * 1.1, FB + 0.45, 13), C.Dark, M.Rubber)
	end
	Kit.doc(Kit.deco(ctx, m, "Inventario", V(2, 2.6, 0.1), CF(-6, FB + 6, 9.1) * ANG(0, math.pi, 0), rgb(250, 248, 236), nil, nil, true), "Inventario del almacén", "Cajas 1-40: tornillos (muchos). Caja 41: tornillos que no son de esta dimensión. Caja 42: NO ABRIR (es la caja de las tostadoras).", "CosmeInventario")
	return m
end

function Laboratory.build(ctx: Kit.Ctx, root: Instance): Model
	inventions(ctx, root)
	local m = Kit.group(root, "Sotano")
	shell(ctx, m)
	corridor(ctx, m)
	portalRoom(ctx, m)
	workshop(ctx, m)
	storage(ctx, m)
	return m
end

return Laboratory
