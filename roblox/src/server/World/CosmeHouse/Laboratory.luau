-- Laboratory: el sótano de Cosme (docs/historia/casa-cosme.md, puntos 8, 19-21). Ocupa casi toda la
-- manzana bajo tierra: es MUCHO más grande que la casa («¿cómo cabe todo esto aquí?»).
--
--   * Pasillo del sótano (con la estantería secreta al fondo: CosmeHouse/SecretRoom)
--   * Laboratorio principal: 48 × 48 y 22 de alto, pasarelas con escalera, grúa, robots, ordenadores,
--     contenedores, tubos, generadores… y en el centro la MÁQUINA DEL ESPACIO-TIEMPO: tres anillos que
--     giran alrededor de un portal con profundidad, bobinas, cristales, consolas, cables y energía.
--   * Sala de prototipos, almacén, sala de energía (el cilindro de energía) y la sala de portales
--     (redonda, con el portal GIGANTE que se activa y cambia de destino: CosmeHouse/PortalSystem).
--   * La bajada desde la casa: escalera de cuatro tramos (Layout.Stairs.Sotano).

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

---------------------------------------------------------------------
-- Cascarón: suelo, muros, techo y tabiques
---------------------------------------------------------------------
local function shell(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Cascaron")
	local B = Layout.Basement
	Kit.slab(ctx, m, "Floor", B, FB, 1, nil, rgb(74, 80, 92), M.Concrete)
	-- Techo (debajo de la losa del jardín), con los huecos de las dos escaleras
	local holes = require(script.Parent.Exterior).coreHoles()
	Kit.slab(ctx, m, "Ceiling", B, TOP, 0.2, holes, rgb(40, 44, 52), M.Concrete)
	-- Muros de fuera (contra la tierra)
	wall(ctx, m, "X", B.Z0, B.X0 - 0.5, B.X1 + 0.5)
	wall(ctx, m, "X", B.Z1, B.X0 - 0.5, B.X1 + 0.5)
	wall(ctx, m, "Z", B.X0, B.Z0, B.Z1)
	wall(ctx, m, "Z", B.X1, B.Z0, B.Z1)
	-- Núcleo de la escalera (x 0..12, z -32..-6): puertas abajo al pasillo y a la sala de energía
	wall(ctx, m, "Z", 0, -32, -6, { door(-31.5, -25.5) }, WALL2)
	wall(ctx, m, "Z", 12, -34, -6, { door(-31.5, -25.5) }, WALL2)
	wall(ctx, m, "X", -32, 0, 12, nil, WALL2)
	wall(ctx, m, "X", -6, 0, 12, nil, WALL2)
	-- Pasillo (x -30..0, z -34..-24)
	wall(ctx, m, "X", -34, -30, 0)
	wall(ctx, m, "X", -24, -48, 0, { op(-24, -6, FB, FB + 14) })
	-- (la pared x = -30 con la estantería secreta la pone SecretRoom)
	-- Laboratorio / prototipos / almacén
	wall(ctx, m, "Z", 0, -6, 24, { door(6, 12) })
	wall(ctx, m, "X", 24, -48, 12, { door(-30, -22), door(3, 9) })
	wall(ctx, m, "Z", 12, -6, 46, { door(-4, 2) })
	-- Sala de energía: lado norte (puerta al pasillito de la sala de portales) y el núcleo del garaje
	wall(ctx, m, "X", -34, 12, 46)
	wall(ctx, m, "X", 8, 12, 34, { door(26, 32) })
	wall(ctx, m, "Z", 34, -20, 8, nil, WALL2)
	wall(ctx, m, "X", -20, 34, 46, { door(37, 43) }, WALL2)
	wall(ctx, m, "X", 6, 34, 46, nil, WALL2)
	wall(ctx, m, "Z", 25, 8, 11.6)
	wall(ctx, m, "Z", 33, 8, 11.6)
	return m
end

---------------------------------------------------------------------
-- Bajada desde la casa (núcleo de la derecha)
---------------------------------------------------------------------
function Laboratory.coreStairs(ctx: Kit.Ctx, parent: Instance, stair: { [string]: any }, name: string)
	local m = Kit.group(parent, name)
	for k = 1, stair.Flights do
		Kit.flight(ctx, m, stair, k, Layout.flight(stair, k), rgb(90, 96, 108), M.DiamondPlate)
	end
	for _, l in Layout.landings(stair) do
		if l.K < stair.Flights then
			Kit.box(ctx, m, "Rellano", V(l.X1 - l.X0, 0.8, l.Z1 - l.Z0), CF((l.X0 + l.X1) / 2, l.Y - 0.4, (l.Z0 + l.Z1) / 2), rgb(90, 96, 108), M.DiamondPlate, { CanQuery = true })
			local lamp = Kit.neon(ctx, m, "LuzRellano", V(3, 0.2, 0.4), CF((l.X0 + l.X1) / 2, l.Y + 8, if l.Near then l.Z0 + 0.6 else l.Z1 - 0.6), C.Cyan, 0.1)
			Kit.light(ctx, lamp, 14, 0.9, rgb(200, 230, 255))
		end
	end
	-- Espina central de arriba abajo
	local z0, z1 = stair.Z0 + stair.Near, stair.Z0 + stair.Near + stair.Run
	local yLow = stair.Y0 + stair.Flights * stair.Rise
	Kit.box(ctx, m, "InnerWall", V(0.6, stair.Y0 - yLow, z1 - z0), CF(stair.X0 + 6, (stair.Y0 + yLow) / 2, (z0 + z1) / 2), WALL2, M.Concrete, { CanQuery = true })
	for k = 1, 4 do
		Kit.neon(ctx, m, "Flecha", V(0.7, 0.4, 2), CF(stair.X0 + 6, stair.Y0 - k * 6, (z0 + z1) / 2), C.Yellow, 0.2)
	end
	return m
end

---------------------------------------------------------------------
-- La máquina del espacio-tiempo (lo MÁS importante)
---------------------------------------------------------------------
local MC = V(-26, FB, 2) -- centro de la máquina en el suelo del laboratorio

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

local function machine(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "MaquinaEspacioTiempo")
	local cx, cz = MC.X, MC.Z
	-- Plataforma con dos escalones alrededor
	Kit.disc(ctx, m, "Plataforma", cx, cz, 9.5, FB + 0.75, 0.75, rgb(60, 64, 76), M.DiamondPlate)
	Kit.disc(ctx, m, "Plataforma", cx, cz, 8, FB + 1.5, 0.75, rgb(70, 74, 88), M.DiamondPlate)
	for k = 0, 2 do
		local r = Kit.cyl(ctx, m, "AnilloSuelo", 0.08, 15.4 - k * 3, CF(cx, FB + 1.54, cz), if k == 1 then C.Cyan else C.Purple, M.Neon)
		r.Transparency = 0.2
		Kit.cyl(ctx, m, "HuecoSuelo", 0.09, 15 - k * 3, CF(cx, FB + 1.545, cz), rgb(70, 74, 88), M.DiamondPlate)
	end
	-- El portal en el centro (con su túnel hacia atrás) mirando a la entrada
	local top = FB + 1.5
	local pc = CF(cx, top + 9.5, cz)
	local portal = PortalSystem.build(ctx, m, pc, 3.4, { Name = "PortalMaquina", Color = C.Cyan, Depth = 4.5, Layers = 11, Spin = 0.2, Stand = 9.5 - 4.2, Destination = 4 })
	portal:SetAttribute("Machine", true)
	-- Tres anillos que giran (como un giroscopio gigante) alrededor del portal
	local center = Kit.world(ctx, pc)
	for i, spec in { { 8, 0.12, "Y", 0 }, { 7.1, -0.18, "Y", math.pi / 2 }, { 6.2, 0.25, "X", 0 } } do
		local r = ring(ctx, m, "AnilloGiratorio" .. i, pc * ANG(0, spec[4], 0) * (if spec[3] == "X" then ANG(math.pi / 2, 0, 0) else CFrame.identity), spec[1], 28, ({ C.Cyan, C.Purple, C.Magenta })[i], 0.7)
		Kit.spin(r, spec[2], spec[3])
		r:SetAttribute("SpinCenter", center)
		r:SetAttribute("MachinePart", true)
		Kit.anomaly(r)
	end
	-- Bobinas alrededor (seis), con haces de energía hasta el centro
	local core = portal:FindFirstChild("Nucleo", true) :: BasePart
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local x, z = cx + math.cos(a) * 10.5, cz + math.sin(a) * 10.5
		local coil = Kit.group(m, "BobinaGrande")
		Kit.cyl(ctx, coil, "Base", 1, 3, CF(x, FB + 0.5, z), C.Dark, M.Metal, true)
		Kit.cyl(ctx, coil, "Nucleo", 8, 1.4, CF(x, FB + 5, z), rgb(70, 74, 86), M.Metal, true)
		for k = 0, 7 do
			Kit.cyl(ctx, coil, "Espira", 0.25, 2.2, CF(x, FB + 2 + k * 0.85, z), rgb(200, 120, 60), M.Metal)
		end
		local tip = Kit.ball(ctx, coil, "Punta", 1.6, CF(x, FB + 9.6, z), if i % 2 == 0 then C.Cyan else C.Purple, M.Neon, 0.1)
		if core then
			local b = Kit.beam(tip, core, if i % 2 == 0 then C.Cyan else C.Purple, 0.3, 10)
			b.CurveSize0 = 3
			b.CurveSize1 = -2
		end
		if i % 2 == 0 then
			Kit.fx(tip, "Sparks", 8)
		end
		-- Cristales en la base de cada bobina
		Kit.neon(ctx, coil, "Cristal", V(0.8, 2.4, 0.8), CF(x + math.cos(a) * 1.4, FB + 1.9, z + math.sin(a) * 1.4) * ANG(0.2, a, 0.15), if i % 2 == 0 then C.Magenta else C.Cyan, 0.1)
		-- Cables del suelo hasta la plataforma
		local mid = V((x + cx) / 2, FB + 0.15, (z + cz) / 2)
		Kit.deco(ctx, coil, "CableGordo", V(0.5, 0.3, 4.5), CF(mid.X, FB + 0.15, mid.Z) * ANG(0, math.atan2(-(cx - x), -(cz - z)), 0) * CF(0, 0, -1), C.Dark, M.Rubber, nil, true)
	end
	-- Consolas delante (pantallas con la simulación y las coordenadas) y su aviso
	local console = Kit.group(m, "Consola")
	for i, kind in { "Sim", "Coords", "Portal" } do
		local x = cx - 4.5 + (i - 1) * 4.5
		local desk = Kit.box(ctx, console, "Mueble", V(4, 3.2, 1.6), CF(x, FB + 1.6, cz - 12.4), rgb(50, 54, 66), M.Metal)
		Kit.deco(ctx, console, "Tablero", V(4, 0.2, 1.8), CF(x, FB + 3.4, cz - 12.6) * ANG(-0.35, 0, 0), C.Dark, M.Metal, nil, true)
		for k = 0, 5 do
			Kit.neon(ctx, console, "Boton", V(0.3, 0.12, 0.3), CF(x - 1.5 + k * 0.6, FB + 3.5, cz - 12.6) * ANG(-0.35, 0, 0), ({ C.Red, C.Green, C.Yellow, C.Cyan })[k % 4 + 1])
		end
		local screen = Kit.monitor(ctx, console, CF(x, FB + 3.2, cz - 12) * ANG(0, math.pi, 0), 3.4, 2, kind, "ESTABLE 66 %")
		if i == 2 then
			Kit.prompt(desk, "Encender la máquina", "🌀 Máquina del espacio-tiempo", "Machine", { Target = "MaquinaEspacioTiempo", PropId = "CosmeMaquina", Text = "Los anillos aceleran, las bobinas escupen rayos y el portal del centro enseña la luna… casi. «¡Faltan piezas!», dice una pantalla." }, 0.5)
		elseif i == 1 then
			Kit.doc(screen, "Simulación de la máquina", "MÁQUINA DEL ESPACIO-TIEMPO v12\n• Anillos: 3/3 girando\n• Bobinas: 6/6\n• Condensador de grieta: FALTA\n• Destino programado: LUNA\n• Probabilidad de llegar entero: 66 %\n\n«Necesito al vecino para la prueba final.»", "CosmeSimulacion")
		end
	end
	-- Luz general de la máquina (de colores)
	local halo = Kit.neon(ctx, m, "Halo", V(1, 1, 1), CF(cx, FB + 18, cz), C.Purple, 1)
	Kit.anomaly(halo)
	Kit.light(ctx, halo, 40, 1.4, C.Purple)
	return m
end

---------------------------------------------------------------------
-- Laboratorio principal
---------------------------------------------------------------------
local function mainLab(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Laboratorio")
	machine(ctx, m)
	-- Luces de techo
	for _, p in { { -38, -14 }, { -12, -14 }, { -38, 14 }, { -12, 14 }, { -26, -18 }, { -26, 20 } } do
		Kit.ceilingLamp(ctx, m, p[1], TOP, p[2], "Laboratorio", "Industrial", rgb(230, 240, 255))
	end
	Kit.switch(ctx, m, -3, FB + 4, -23.4, 180, "Laboratorio")
	-- Rayas de peligro alrededor de la máquina y en la entrada
	for i = 0, 7 do
		Kit.deco(ctx, m, "Franja", V(1.4, 0.04, 0.6), CF(-23 + i * 2, FB + 0.02, -22) * ANG(0, 0.7, 0), C.Yellow, nil, nil, true)
	end
	-- Pasarelas: escalera junto a la pared oeste y pasarela en forma de L (oeste y norte)
	local walk = Kit.group(m, "Pasarelas")
	local yW = FB + 11
	local stairSpec = { X0 = -47.5, Y0 = FB, Rise = 11 }
	local steps = 14
	for i = 1, steps do
		local top = FB + i * (11 / steps)
		local z0 = -20 + (i - 1) * 1.3
		local h = top - FB + 0.3
		Kit.box(ctx, walk, "Step", V(5, h, 1.3), CF(-45, top - h / 2, z0 + 0.65), rgb(80, 86, 98), M.DiamondPlate, { CanQuery = true })
	end
	local _ = stairSpec
	Kit.railing(ctx, walk, V(-42.3, FB, -20), V(-42.3, yW, -1.8), 3.4, false)
	Kit.box(ctx, walk, "Pasarela", V(5, 0.6, 25.8), CF(-45, yW - 0.3, 10.6), rgb(80, 86, 98), M.DiamondPlate, { CanQuery = true })
	Kit.box(ctx, walk, "Pasarela", V(40, 0.6, 5), CF(-22.5, yW - 0.3, 21), rgb(80, 86, 98), M.DiamondPlate, { CanQuery = true })
	Kit.railing(ctx, walk, V(-42.3, yW, -1.8), V(-42.3, yW, 18.3), 3.4, false)
	Kit.railing(ctx, walk, V(-42.3, yW, 18.3), V(-2.5, yW, 18.3), 3.4, false)
	Kit.railing(ctx, walk, V(-2.5, yW, 18.3), V(-2.5, yW, 23.4), 3.4, false)
	for _, p in { { -45, 4 }, { -45, 16 }, { -36, 21 }, { -24, 21 }, { -12, 21 }, { -4, 21 } } do
		Kit.box(ctx, walk, "Pilar", V(0.8, yW - 0.6 - FB, 0.8), CF(p[1], (FB + yW - 0.6) / 2, p[2]), rgb(60, 64, 76), M.Metal)
	end
	-- En la pasarela: ordenador de vigilancia, cajas y una silla
	Kit.box(ctx, walk, "MesaPasarela", V(4, 0.3, 2), CF(-30, yW + 2.6, 22.4), C.Dark, M.Metal)
	Kit.box(ctx, walk, "PieMesa", V(3.6, 2.6, 0.4), CF(-30, yW + 1.3, 23), C.Dark, M.Metal)
	Kit.monitor(ctx, walk, CF(-30, yW + 2.75, 22.8) * ANG(0, 0, 0), 2.6, 1.6, "Camera")
	Props.make(ctx, walk, "Crate", CF(-45, yW, 20))
	Props.make(ctx, walk, "Crate", CF(-14, yW, 22))
	-- Grúa puente: carriles en las paredes, puente, carro, cable y un contenedor colgado
	local crane = Kit.group(m, "Grua")
	for _, z in { -23, 23 } do
		Kit.box(ctx, crane, "Carril", V(46, 1, 1), CF(-24, TOP - 2.5, z), C.Yellow, M.Metal)
		for _, x in { -46, -24, -2 } do
			Kit.box(ctx, crane, "Mensula", V(1, 1, 0.8), CF(x, TOP - 3.4, z + (if z > 0 then 0.6 else -0.6)), C.Dark, M.Metal)
		end
	end
	Kit.box(ctx, crane, "Puente", V(2, 1.6, 47), CF(-10, TOP - 1.7, 0), C.Yellow, M.Metal)
	Kit.box(ctx, crane, "Carro", V(2.6, 1.4, 2.6), CF(-10, TOP - 3.2, 8), C.Dark, M.Metal)
	Kit.box(ctx, crane, "Cable", V(0.2, 7, 0.2), CF(-10, TOP - 7.4, 8), C.Dark, M.Metal, { CanCollide = false })
	Kit.box(ctx, crane, "Gancho", V(0.8, 1, 0.8), CF(-10, TOP - 11.4, 8), C.Chrome, M.Metal, { CanCollide = false })
	Kit.box(ctx, crane, "ContenedorColgado", V(3, 3, 3), CF(-10, TOP - 13.4, 8), C.Orange, M.Metal, { CanCollide = false })
	-- Contenedores, bidones y cajas en el rincón noroeste
	for i, p in { { -38, -21, 0 }, { -38, -21, 1 }, { -31, -21, 0 } } do
		local cont = Kit.box(ctx, m, "Contenedor", V(6.4, 5.8, 3.6), CF(p[1], FB + 2.9 + p[3] * 5.8, p[2]), ({ rgb(60, 110, 160), rgb(170, 70, 50), rgb(70, 130, 80) })[i], M.CorrodedMetal)
		cont.Name = "Contenedor"
		Kit.deco(ctx, m, "Rotulo", V(3, 1, 0.1), CF(p[1], FB + 3.4 + p[3] * 5.8, p[2] + 1.85), C.White, nil, nil, true)
	end
	for i = 0, 4 do
		Props.make(ctx, m, if i % 2 == 0 then "Barrel" else "Crate", CF(-41.2, FB, -17 + i * 2.4))
	end
	-- Generadores grandes bajo la pasarela (con haces de energía)
	for _, z in { 8, 12.6 } do
		local gen = Kit.group(m, "GeneradorGrande")
		Kit.cyl(ctx, gen, "Cuerpo", 8, 4.4, CF(-45, FB + 4, z), rgb(80, 86, 100), M.Metal, true)
		local core = Kit.cyl(ctx, gen, "Nucleo", 6, 2.2, CF(-42.8, FB + 4, z), C.Green, M.Neon, false, 0.2)
		core.Size = V(6, 2.2, 2.2)
		Kit.fx(core, "Energy", 6)
	end
	-- Mesas de trabajo caóticas (cuatro), con cientos de cosas
	local benches = { { -14, 6, 0 }, { -8, 16, 90 }, { -38, -6, 90 }, { -21, -19.5, 0 } }
	for _, b in benches do
		local bm = Kit.group(m, "MesaTrabajo")
		local w, d = if b[3] == 0 then 8 else 3, if b[3] == 0 then 3 else 8
		Kit.box(ctx, bm, "Tablero", V(w, 0.3, d), CF(b[1], FB + 3, b[2]), rgb(120, 96, 70), M.Wood)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Kit.box(ctx, bm, "Pata", V(0.3, 2.85, 0.3), CF(b[1] + sx * (w / 2 - 0.3), FB + 1.43, b[2] + sz * (d / 2 - 0.3)), C.Dark, M.Metal)
			end
		end
		Props.scatter(ctx, bm, { b[1] - w / 2, b[1] + w / 2, b[2] - d / 2, b[2] + d / 2 }, FB + 3.15, 10, Props.Lab)
		Props.make(ctx, bm, "Lamp", CF(b[1] - w / 2 + 0.6, FB + 3.15, b[2] - d / 2 + 0.6))
	end
	-- Ordenadores de la pared este
	local desk = Kit.box(ctx, m, "MesaOrdenadores", V(3, 0.3, 10), CF(-1.8, FB + 3, -16), C.Dark, M.Metal)
	Kit.box(ctx, m, "PieMesa", V(0.4, 2.85, 9.6), CF(-0.6, FB + 1.43, -16), C.Dark, M.Metal)
	for i, kind in { "Coords", "Graph", "Map", "Camera" } do
		Kit.monitor(ctx, m, CF(-1.4, FB + 3.15, -20.5 + i * 2.4) * ANG(0, math.pi / 2, 0), 2.1, 1.4, kind)
	end
	local _ = desk
	Furniture.officeChair(Kit.furn(ctx, m), Kit.at(ctx, -4.2, FB, -16, -90), rgb(30, 30, 34), m)
	-- Pantallas grandes en la pared sur
	for i, kind in { "Anomalies", "Equations", "Plans" } do
		Kit.wallScreen(ctx, m, CF(-46 + i * 5.5, FB + 9, -23.45) * ANG(0, math.pi, 0), 5, 3.4, kind)
	end
	local note = Kit.wallScreen(ctx, m, CF(-28, FB + 9, -23.45) * ANG(0, math.pi, 0), 5, 3.4, "Text", "¿CÓMO CABE TODO ESTO AQUÍ?\n(no preguntes)")
	note.Name = "Cartel"
	-- Robot grande (apagado, de pie) y robot que pasea; tubos y válvulas en la pared este
	local bot = Kit.group(m, "RobotGrande")
	Kit.box(ctx, bot, "Piernas", V(2.4, 4, 1.4), CF(-4, FB + 2, 18), rgb(160, 166, 180), M.Metal)
	Kit.box(ctx, bot, "Torso", V(3.6, 3.4, 2), CF(-4, FB + 5.7, 18), rgb(180, 186, 200), M.Metal)
	Kit.box(ctx, bot, "Cabeza", V(2, 1.6, 1.6), CF(-4, FB + 8.2, 18), rgb(200, 205, 215), M.Metal)
	Kit.neon(ctx, bot, "Ojos", V(1.4, 0.3, 0.05), CF(-4, FB + 8.3, 17.18), C.Red, 0.3)
	for _, s in { -1, 1 } do
		Kit.box(ctx, bot, "Brazo", V(0.9, 3.6, 0.9), CF(-4 + s * 2.3, FB + 5.4, 18), rgb(160, 166, 180), M.Metal)
	end
	Kit.doc(bot:FindFirstChild("Torso") :: BasePart, "Robot «Pip 0»", "El primer intento de Pip. Placa: «PIP 0 — demasiado sincero. Desconectado por decirle a Cosme que su pelo parece un experimento.»", "CosmePip0")
	Kit.robot(ctx, m, -18, FB, -2, "Mini", { { -18, -2 }, { -18, 12 }, { -34, 14 }, { -34, -10 } }, 2.5)
	for i = 0, 2 do
		Kit.cylX(ctx, m, "Tuberia", 44, 0.8, CF(-24, TOP - 1 - i * 1.1, 23.2) * CFrame.identity, ({ rgb(160, 120, 70), rgb(120, 126, 136), rgb(60, 130, 90) })[i + 1], M.Metal)
	end
	for _, x in { -40, -20, -8 } do
		local valve = Kit.cylX(ctx, m, "Valvula", 0.3, 1.4, CF(x, TOP - 1, 22.6) * ANG(0, math.pi / 2, 0), C.Red, M.Metal)
		valve.Shape = Enum.PartType.Cylinder
	end
	-- Columna de energía (como la de la imagen del laboratorio de inventos)
	local column = Kit.group(m, "ColumnaEnergia")
	Kit.cyl(ctx, column, "Base", 1.2, 5, CF(-36, FB + 0.6, 12), C.Dark, M.Metal, true)
	Kit.cyl(ctx, column, "Tapa", 1.2, 5, CF(-36, TOP - 0.6, 12), C.Dark, M.Metal, true)
	Kit.cyl(ctx, column, "Tubo", TOP - FB - 2.4, 3.4, CF(-36, (FB + TOP) / 2, 12), rgb(160, 210, 255), M.Glass, true, 0.6)
	local energy = Kit.cyl(ctx, column, "Energia", TOP - FB - 2.6, 1.6, CF(-36, (FB + TOP) / 2, 12), C.Cyan, M.Neon, false, 0.15)
	Kit.light(ctx, energy, 24, 1.6, C.Cyan)
	Kit.fx(energy, "Energy", 14)
	Kit.spin(energy, 0.3, "Y")
	Props.scatter(ctx, m, { -46, -2, -22, 22 }, FB, 26, Props.Floor)
	Props.scatter(ctx, m, { -24, -4, -22, -14 }, FB, 8, { "Screws", "Papers", "Tool", "Chip", "Battery" })
	return m
end

---------------------------------------------------------------------
-- Pasillo, prototipos, almacén, energía y sala de portales
---------------------------------------------------------------------
local function corridor(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "PasilloSotano")
	for _, x in { -24, -8 } do
		Kit.ceilingLamp(ctx, m, x, TOP, -29, "PasilloSotano", "Bar", C.Cyan)
	end
	Kit.switch(ctx, m, -0.6, FB + 4, -24.8, 90, "PasilloSotano")
	for i = 0, 9 do
		Kit.neon(ctx, m, "TiraSuelo", V(1.6, 0.05, 0.2), CF(-27 + i * 3, FB + 0.03, -33.3), C.Cyan, 0.3)
	end
	for i, kind in { "Map", "Coords" } do
		Kit.wallScreen(ctx, m, CF(-20 + i * 6, FB + 7, -33.45) * ANG(0, math.pi, 0), 4, 2.6, kind)
	end
	local sign = Kit.deco(ctx, m, "Cartel", V(6, 1.4, 0.1), CF(-15, FB + 15.5, -24.6), C.Dark, nil, nil, true)
	Kit.signText(sign, "LABORATORIO →", Enum.NormalId.Front, C.Cyan, C.Dark)
	for i = 0, 2 do
		Props.make(ctx, m, "Crate", CF(-6 - i * 3, FB, -33) * ANG(0, i, 0))
	end
	Props.make(ctx, m, "Barrel", CF(-1.6, FB, -32.5))
	Props.scatter(ctx, m, { -26, -14, -33, -30 }, FB, 4, { "CableRun", "Pile" })
	return m
end

local function prototypes(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Prototipos")
	Kit.ceilingLamp(ctx, m, 6, TOP, 2, "Prototipos", "Industrial")
	Kit.ceilingLamp(ctx, m, 6, TOP, 16, "Prototipos", "Industrial")
	Kit.switch(ctx, m, 0.6, FB + 4, 13, -90, "Prototipos")
	local items = {
		{ "Monopatín flotante", "Prototipo 7: flota a dos palmos del suelo. En curvas, flota hacia la izquierda. Siempre.", C.Magenta, 1.8 },
		{ "Mochila cohete", "Prototipo 12: sube muy bien. Bajar está «en desarrollo».", C.Orange, 2 },
		{ "Rayo encogedor", "Prototipo 19: encoge cosas un 66 %. Funcionó con una gallina. Al revés.", C.Green, 1.2 },
		{ "Perro robot", "Prototipo 23: ladra en binario. Le gusta la batería del vecino.", C.Cyan, 1.6 },
		{ "Reloj del tiempo", "Prototipo 31: adelanta 5 minutos… la realidad. Solo usar si llegas tarde.", C.Yellow, 0.9 },
		{ "Casco lector de mentes", "Prototipo 40: solo lee la mente de los peces. Están muy preocupados por algo.", C.Purple, 1.3 },
	}
	local spots = { { 2, -2 }, { 10, 6 }, { 2, 17 }, { 10, 13 }, { 2, 21.5 }, { 10, 20 } }
	for i, it in items do
		local x, z = spots[i][1], spots[i][2]
		local left = x < 6
		local ped = Kit.group(m, "Pedestal")
		local base = Kit.box(ctx, ped, "Pedestal", V(3, 3, 3), CF(x, FB + 1.5, z), rgb(40, 44, 56), M.Marble)
		Kit.neon(ctx, ped, "Borde", V(3.1, 0.15, 3.1), CF(x, FB + 3.05, z), it[3], 0.2)
		local obj = Kit.box(ctx, ped, "Prototipo", V(it[4] * 1.4, it[4], it[4]), CF(x, FB + 3.1 + it[4] / 2, z), it[3]:Lerp(C.Steel, 0.5), M.Metal, { CanCollide = false })
		Kit.neon(ctx, ped, "Luz", V(it[4] * 0.5, 0.2, it[4] * 1.02), CF(x, FB + 3.1 + it[4] * 0.7, z), it[3], 0.2)
		Kit.glass(ctx, ped, "Vitrina", V(2.8, 3, 2.8), CF(x, FB + 4.6, z), rgb(200, 230, 245), 0.75, false)
		local label = Kit.deco(ctx, ped, "Etiqueta", V(0.05, 0.6, 2.4), CF(x + (if left then 1.53 else -1.53), FB + 2.2, z), C.White, nil, nil, true)
		Kit.signText(label, it[1], if left then Enum.NormalId.Right else Enum.NormalId.Left, C.Dark, C.White)
		Kit.doc(base, it[1], it[2], "CosmeProto" .. i)
		local _ = obj
	end
	local shelf = Props.shelf(ctx, m, CF(6, FB, 23.1), 5, 8, "Lab")
	shelf.Name = "EstanteriaPrototipos"
	Props.scatter(ctx, m, { 0.5, 11.5, -5.5, 23 }, FB, 6, { "CableRun", "Crate", "Pile" })
	return m
end

local function storage(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Almacen")
	for _, x in { -36, -16, 4 } do
		Kit.ceilingLamp(ctx, m, x, TOP, 34, "Almacen", "Industrial")
	end
	Kit.switch(ctx, m, -21.4, FB + 4, 24.6, 0, "Almacen")
	-- Filas de estanterías (con pasillo central y hueco frente a la puerta)
	for _, z in { 29, 39.5 } do
		for _, x in { -42, -35, -18, -11, -4 } do
			Props.shelf(ctx, m, CF(x, FB, z) * ANG(0, if z > 34 then 0 else math.pi, 0), 6, 10, if x % 2 == 0 then "Boxes" else "Lab")
		end
	end
	for i = 0, 7 do
		Props.make(ctx, m, if i % 3 == 0 then "Barrel" else "Crate", CF(-46 + (i % 2) * 2.4, FB, 26 + i * 2.4))
	end
	for i = 0, 5 do
		Props.make(ctx, m, "Crate", CF(8 + (i % 2) * 2.4, FB, 38 + math.floor(i / 2) * 2.4) * ANG(0, i * 0.3, 0))
	end
	-- Máquinas viejas tapadas con sábanas y una carretilla
	for _, p in { { -28, 44 }, { -22, 44 } } do
		Kit.box(ctx, m, "MaquinaTapada", V(4, 3.6, 2.4), CF(p[1], FB + 1.8, p[2]), rgb(220, 218, 210), M.Fabric)
	end
	local cart = Kit.group(m, "Carretilla")
	Kit.box(ctx, cart, "Plataforma", V(2.4, 0.3, 3.6), CF(-30, FB + 0.6, 34.5), C.Orange, M.Metal)
	Kit.deco(ctx, cart, "Asa", V(2.4, 3, 0.2), CF(-30, FB + 2.1, 36.2), C.Dark, M.Metal)
	for _, sx in { -1, 1 } do
		Kit.cylX(ctx, cart, "Rueda", 0.4, 0.9, CF(-30 + sx * 1.1, FB + 0.45, 34.5), C.Dark, M.Rubber)
	end
	Kit.doc(Kit.deco(ctx, m, "Inventario", V(2, 2.6, 0.1), CF(-24, FB + 6, 24.6) * ANG(0, math.pi, 0), rgb(250, 248, 236), nil, nil, true), "Inventario del almacén", "Cajas 1-40: tornillos (muchos). Caja 41: tornillos que no son de esta dimensión. Caja 42: NO ABRIR (es la caja de las tostadoras).", "CosmeInventario")
	Props.scatter(ctx, m, { -47, 11, 33, 35 }, FB, 4, { "CableRun" })
	return m
end

local function energyRoom(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Energia")
	for _, p in { { 20, -27 }, { 38, -27 }, { 22, -2 } } do
		Kit.ceilingLamp(ctx, m, p[1], TOP, p[2], "Energia", "Industrial", rgb(255, 230, 190))
	end
	Kit.switch(ctx, m, 12.6, FB + 4, -24, -90, "Energia")
	-- El cilindro de energía (reactor) con anillos y haces hasta el techo
	local reactor = Kit.group(m, "CilindroEnergia")
	local rx, rz = 18, -13
	Kit.cyl(ctx, reactor, "Base", 1.6, 7, CF(rx, FB + 0.8, rz), C.Dark, M.DiamondPlate, true)
	Kit.cyl(ctx, reactor, "Tubo", 14, 5, CF(rx, FB + 8.6, rz), rgb(160, 210, 255), M.Glass, true, 0.55)
	local core = Kit.cyl(ctx, reactor, "Nucleo", 13.6, 2.4, CF(rx, FB + 8.6, rz), C.Cyan, M.Neon, false, 0.1)
	Kit.light(ctx, core, 30, 2, C.Cyan)
	Kit.fx(core, "Energy", 20)
	for k = 0, 3 do
		local ring = Kit.cyl(ctx, reactor, "Anillo", 0.5, 6, CF(rx, FB + 3 + k * 3.6, rz), if k % 2 == 0 then C.Purple else C.Cyan, M.Neon)
		ring.Transparency = 0.15
	end
	Kit.cyl(ctx, reactor, "Tapa", 1.6, 7, CF(rx, FB + 16.4, rz), C.Dark, M.DiamondPlate, true)
	Kit.cyl(ctx, reactor, "Conducto", TOP - FB - 17.2, 2, CF(rx, (FB + 17.2 + TOP) / 2, rz), rgb(120, 126, 136), M.Metal, true)
	Kit.prompt(core, "Mirar el reactor", "⚡ Cilindro de energía", "Machine", { Target = "CilindroEnergia", PropId = "CosmeReactor", Text = "El cilindro zumba. Una etiqueta: «Energía de grieta embotellada. Agitar antes de usar. O mejor, no agitar»." })
	-- Generadores en fila (pared sur), cuadros eléctricos con pantallas, baterías y cables
	for i = 0, 5 do
		local x = 15 + i * 5.2
		local gen = Kit.group(m, "Generador")
		Kit.box(ctx, gen, "Cuerpo", V(4, 5, 2.6), CF(x, FB + 2.5, -32.4), rgb(90, 96, 110), M.Metal)
		Kit.neon(ctx, gen, "Indicador", V(2.6, 0.3, 0.05), CF(x, FB + 4.2, -31.08), if i % 2 == 0 then C.Green else C.Yellow, 0.2)
		local fan = Kit.cylX(ctx, gen, "Ventilador", 0.2, 2.2, CF(x, FB + 2.2, -31.05) * ANG(0, math.pi / 2, 0), C.Dark)
		Kit.spin(fan, 0.8, "X")
	end
	for i, kind in { "Graph", "Coords", "Sim" } do
		Kit.wallScreen(ctx, m, CF(45.45, FB + 7, -32 + i * 3.4) * ANG(0, math.pi / 2, 0), 3, 2.2, kind)
	end
	for i = 0, 3 do
		local panel = Kit.box(ctx, m, "CuadroElectrico", V(0.8, 4, 3), CF(12.9, FB + 5, 0 - i * 4 - 6), rgb(170, 176, 186), M.Metal)
		Kit.neon(ctx, m, "Piloto", V(0.1, 0.3, 0.3), CF(13.33, FB + 6.2, 0 - i * 4 - 6), ({ C.Red, C.Green })[i % 2 + 1])
		local _ = panel
	end
	for i = 0, 5 do
		Props.make(ctx, m, "Battery", CF(30 + (i % 3) * 0.9, FB, -2 - math.floor(i / 3) * 0.9))
	end
	for i = 0, 3 do
		Kit.deco(ctx, m, "CableGrueso", V(0.6, 0.4, 24), CF(25 + i * 0.8, FB + 0.2, -14) * ANG(0, 0.04 * i, 0), ({ C.Dark, C.Red, C.Yellow, C.Blue })[i + 1], M.Rubber, nil, true)
	end
	-- Tuberías a lo largo de la pared sur, extintores, rayas en el suelo y armarios de baterías
	for i = 0, 2 do
		Kit.cylX(ctx, m, "Tuberia", 33, 0.7, CF(29, FB + 7.5 + i * 0.9, -33.1), ({ rgb(160, 120, 70), rgb(120, 126, 136), rgb(60, 130, 90) })[i + 1], M.Metal)
	end
	for _, x in { 14, 44 } do
		Kit.cyl(ctx, m, "Extintor", 1.6, 0.6, CF(x, FB + 0.8, -21), C.Red, M.Metal)
	end
	for i = 0, 9 do
		Kit.deco(ctx, m, "Franja", V(1.4, 0.04, 0.6), CF(15 + i * 2.8, FB + 0.02, -29.8) * ANG(0, 0.7, 0), if i % 2 == 0 then C.Yellow else C.Dark, nil, nil, true)
	end
	for i = 0, 2 do
		local rack = Kit.box(ctx, m, "ArmarioBaterias", V(2.4, 6, 1.6), CF(27 + i * 3, FB + 3, -21), rgb(60, 66, 80), M.Metal)
		for k = 0, 3 do
			Kit.neon(ctx, m, "Carga", V(1.6, 0.25, 0.05), CF(27 + i * 3, FB + 1.5 + k * 1.2, -21.82), if k < 3 then C.Green else C.Yellow, 0.2)
		end
		local _ = rack
	end
	local warn = Kit.deco(ctx, m, "Aviso", V(5, 2.2, 0.1), CF(29, FB + 10, 7.4), C.Yellow, nil, nil, true)
	Kit.signText(warn, "⚡ ALTA TENSIÓN\n(Y ALTA DIMENSIÓN)", Enum.NormalId.Front, C.Dark, C.Yellow)
	Props.scatter(ctx, m, { 13, 33, -19, 7 }, FB, 6, { "Crate", "Barrel", "Pile" })
	return m
end

local function portalRoom(ctx: Kit.Ctx, parent: Instance)
	local P = Layout.PortalTower
	local m = Kit.group(parent, "SalaPortales")
	Kit.ringWall(ctx, m, P.X, P.Z, 16, FB - 1, TOP, { Segments = 24, Color = rgb(36, 32, 56), Material = M.Concrete, Name = "ParedSala", PieceName = "InnerWall", Doors = { { Theta = math.pi * 1.5, Top = FB + 10, Width = 1 } } })
	-- Suelo con círculos de luz y dibujo de portal
	for k = 0, 3 do
		local r = Kit.cyl(ctx, m, "CirculoSuelo", 0.06, 28 - k * 6, CF(P.X, FB + 0.03, P.Z), if k % 2 == 0 then C.Purple else C.Cyan, M.Neon)
		r.Transparency = 0.3
		Kit.cyl(ctx, m, "HuecoSuelo", 0.07, 27.4 - k * 6, CF(P.X, FB + 0.035, P.Z), rgb(30, 26, 48), M.Slate)
	end
	-- Luces del techo en aro
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local lamp = Kit.neon(ctx, m, "LuzAro", V(3, 0.3, 0.8), CF(P.X + math.cos(a) * 11, TOP - 0.4, P.Z + math.sin(a) * 11) * ANG(0, -a, 0), C.Purple, 0.1)
		if i % 2 == 0 then
			Kit.light(ctx, lamp, 26, 1.1, rgb(190, 150, 255), "Portales")
		else
			lamp:AddTag("RoomLight")
			lamp:SetAttribute("Room", "Portales")
			lamp:SetAttribute("OnColor", lamp.Color)
			lamp:SetAttribute("OnMaterial", "Neon")
		end
	end
	Kit.switch(ctx, m, 25.6, FB + 4, 9.5, -90, "Portales")
	-- El portal GIGANTE al fondo, mirando a la puerta, con anillos y bobinas alrededor
	local pz = P.Z + 7
	local portal = PortalSystem.build(ctx, m, CF(P.X, FB + 10.5, pz), 7, { Name = "PortalGigante", Color = C.Purple, Depth = 6, Layers = 14, Spin = 0.15, Stand = 10.5 - 7 - 1.12, Destination = 1, Arms = 6 })
	portal:SetAttribute("Main", true)
	-- Gran anillo exterior que gira despacio (en el mismo plano)
	local outer = ring(ctx, m, "AnilloExterior", CF(P.X, FB + 10.5, pz + 0.6), 10.2, 36, C.Cyan, 0.6)
	Kit.spin(outer, -0.05, "Z")
	outer:SetAttribute("SpinCenter", Kit.at(ctx, P.X, FB + 10.5, pz + 0.6))
	Kit.anomaly(outer)
	-- Rampa / tarima delante del portal
	Kit.box(ctx, m, "Tarima", V(12, 0.6, 6), CF(P.X, FB + 0.3, pz - 4.5), rgb(60, 56, 80), M.DiamondPlate)
	-- Consolas: activar el portal y cambiar de destino (y pantallas con el destino)
	local main = Kit.group(m, "ConsolaPortal")
	Kit.box(ctx, main, "Mueble", V(5, 3.2, 1.8), CF(P.X, FB + 1.6, P.Z - 3), rgb(50, 46, 70), M.Metal)
	Kit.deco(ctx, main, "Tablero", V(5, 0.2, 2), CF(P.X, FB + 3.4, P.Z - 3.2) * ANG(-0.35, 0, 0), C.Dark, M.Metal, nil, true)
	local lever = Kit.neon(ctx, main, "Palanca", V(0.4, 1.4, 0.4), CF(P.X + 1.6, FB + 4.1, P.Z - 3.4), C.Red)
	Kit.prompt(lever, "Activar el portal", "🌀 Portal gigante", "Portal", { Target = "PortalGigante", PropId = "CosmePortalGigante" }, 0.8)
	local dial = Kit.neon(ctx, main, "Selector", V(0.9, 0.3, 0.9), CF(P.X - 1.6, FB + 3.7, P.Z - 3.3), C.Cyan)
	Kit.prompt(dial, "Cambiar de destino", "🧭 Selector de destino", "PortalDial", { Target = "PortalGigante" })
	Kit.monitor(ctx, main, CF(P.X, FB + 3.2, P.Z - 2.4) * ANG(0, math.pi, 0), 3, 1.8, "Portal", PortalSystem.Destinations[1].Name)
	for _, side in { -1, 1 } do
		local x = P.X + side * 9
		local c = Kit.group(m, "ConsolaLateral")
		Kit.box(ctx, c, "Mueble", V(3, 3.2, 1.6), CF(x, FB + 1.6, P.Z - 1) * ANG(0, side * 0.5, 0), rgb(50, 46, 70), M.Metal)
		Kit.monitor(ctx, c, CF(x, FB + 3.2, P.Z - 0.6) * ANG(0, math.pi + side * 0.5, 0), 2.6, 1.6, if side < 0 then "Portal" else "Sim", PortalSystem.Destinations[1].Name)
	end
	local function onWall(deg: number, r: number, y: number): CFrame
		local a = math.rad(deg)
		return CF(P.X + math.cos(a) * r, y, P.Z + math.sin(a) * r) * ANG(0, math.pi / 2 - a, 0)
	end
	for i, deg in { 200, 225, 315, 340 } do
		Kit.wallScreen(ctx, m, onWall(deg, 15.1, FB + 8), 3.4, 2.4, if i % 2 == 0 then "Portal" else "Stars", PortalSystem.Destinations[1].Name)
	end
	-- Pizarra con dibujos y cajas de piezas
	local board = Kit.wallScreen(ctx, m, onWall(160, 15.1, FB + 7), 4, 3, "Equations")
	Kit.doc(board, "Pizarra de la sala de portales", "«Destinos probados: espacio profundo ✔, los Pliegues ✔ (no tocar nada), bosque de otra Valmar ✔, la Luna ✘ (nos quedamos cortos), 66-B ✘✘✘ (NO)».", "CosmePizarraPortales")
	for i = 0, 3 do
		Props.make(ctx, m, if i % 2 == 0 then "Crate" else "Barrel", CF(P.X + 12 - i * 1.2, FB, P.Z + 7 + i * 2))
	end
	Props.scatter(ctx, m, { P.X - 8, P.X + 8, P.Z - 12, P.Z - 6 }, FB, 5, { "CableRun", "Pile" })
	return m
end

function Laboratory.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "Sotano")
	shell(ctx, m)
	Laboratory.coreStairs(ctx, m, Layout.Stairs.Sotano, "BajadaSotano")
	corridor(ctx, m)
	mainLab(ctx, m)
	prototypes(ctx, m)
	storage(ctx, m)
	energyRoom(ctx, m)
	portalRoom(ctx, m)
	return m
end

return Laboratory
