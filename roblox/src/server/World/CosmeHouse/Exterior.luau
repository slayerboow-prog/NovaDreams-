-- Exterior: la parcela de Cosme por fuera (docs/historia/casa-cosme.md, referencia
-- docs/referencias/casa-cosme.png): casa moderna de dos plantas con torre redonda acristalada,
-- garaje abierto, paneles solares, valla de madera, jardín delantero con el robot buzón y el cartel
-- «NO ENTRAR», jardín trasero con terraza, barbacoa, máquina enterrada y un experimento «que no
-- debería estar ahí», y la torre-portal con el vórtice azul encima.
--
-- También: la losa del jardín (techo del sótano, con los huecos de las dos escaleras), los forjados
-- de la casa y del garaje, y el hueco en el terreno para el sótano (Exterior.terrain, al arrancar).

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local PortalSystem = require(script.Parent.PortalSystem)
local Builder = require(script.Parent.Parent.Builder)

local Exterior = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local STONE = rgb(198, 192, 182)
local RENDER = rgb(240, 238, 232)
local CLAD = rgb(150, 104, 68)
local TRIM = rgb(46, 48, 56)
local GRASS = rgb(98, 140, 70)

local H = Layout.House
local G = Layout.Garage
local T = Layout.Tower
local S = Layout.Stairs

-- Huecos de las escaleras que bajan al sótano (en la losa del jardín y en los suelos de abajo)
function Exterior.coreHoles(): { { [string]: number } }
	return {
		{ X0 = S.Sotano.X0, X1 = S.Sotano.X1, Z0 = S.Sotano.Z0 + S.Sotano.Near, Z1 = S.Sotano.Z0 + S.Sotano.Near + S.Sotano.Run + S.Sotano.Far },
		{ X0 = S.Garaje.X0, X1 = S.Garaje.X1, Z0 = S.Garaje.Z0 + S.Garaje.Near, Z1 = S.Garaje.Z0 + S.Garaje.Near + S.Garaje.Run + S.Garaje.Far },
	}
end

-- Hueco de la escalera principal (planta alta y azotea)
function Exterior.stairHole(): { [string]: number }
	local s = S.Hall
	return { X0 = s.X0, X1 = s.X1, Z0 = s.Z0 + s.Near, Z1 = s.Z0 + s.Near + s.Run + s.Far }
end

local function towerSkip(theta: number): boolean
	-- El lado de la torre que queda dentro de la casa va abierto
	return T.X + T.R * math.cos(theta) > H.X0 - 0.4
end
Exterior.towerSkip = towerSkip

---------------------------------------------------------------------
-- Suelo: losa del jardín (y techo del sótano) y forjados
---------------------------------------------------------------------
local function ground(ctx: Kit.Ctx, m: Instance)
	local lot = Layout.Lot
	-- (con el nombre de las manzanas: la misma hierba que el resto del barrio)
	Kit.slab(ctx, m, "BlockGround", lot, 0, 2, Exterior.coreHoles(), GRASS, M.Grass)
	-- Planta baja de la casa (y la torre) y del garaje
	local floors = Kit.group(m, "Forjados")
	Kit.slab(ctx, floors, "Floor", H, Layout.F0, 1, { Exterior.coreHoles()[1] }, rgb(178, 136, 94), M.WoodPlanks)
	Kit.disc(ctx, floors, "Floor", T.X, T.Z, T.R, Layout.F0, 1, rgb(178, 136, 94), M.WoodPlanks)
	Kit.slab(ctx, floors, "Floor", G, Layout.F0, 1, { Exterior.coreHoles()[2] }, rgb(120, 122, 126), M.Concrete)
	-- Planta alta y azotea (con el hueco de la escalera principal), con su techo blanco debajo
	local hole = Exterior.stairHole()
	for _, level in { { Layout.F1, "Floor", rgb(170, 128, 88), M.WoodPlanks }, { Layout.F2, "RoofDeck", rgb(170, 168, 160), M.Concrete } } do
		Kit.slab(ctx, floors, level[2], H, level[1], 1, { hole }, level[3], level[4])
		Kit.slab(ctx, floors, "Ceiling", H, level[1] - 1, 0.1, { hole }, C.White, M.SmoothPlastic)
		Kit.disc(ctx, floors, level[2], T.X, T.Z, T.R, level[1], 1, level[3], level[4])
		Kit.disc(ctx, floors, "Ceiling", T.X, T.Z, T.R - 0.4, level[1] - 1, 0.1, C.White, M.SmoothPlastic)
	end
	-- Techo del garaje (con placas solares encima)
	Kit.slab(ctx, floors, "GarageRoof", G, Layout.CEIL.G + 1, 1, nil, rgb(90, 92, 98), M.Concrete)
	Kit.slab(ctx, floors, "Ceiling", G, Layout.CEIL.G, 0.1, nil, rgb(200, 200, 196), M.SmoothPlastic)
end

---------------------------------------------------------------------
-- Fachadas de la casa
---------------------------------------------------------------------
local function op(a: number, b: number, bottom: number, top: number, kind: string?): Kit.Opening
	return { A = a, B = b, Bottom = bottom, Top = top, Kind = kind }
end

local function facades(ctx: Kit.Ctx, m: Instance)
	local f = Kit.group(m, "Fachadas")
	local g = { Color = STONE, Material = M.Concrete, Name = "Wall", Frame = TRIM }
	local u = { Color = RENDER, Material = M.Plaster, Name = "Wall", Frame = TRIM }
	local p = { Color = RENDER, Material = M.Plaster, Name = "Parapet" }
	local function band(opts: any, extra: any): any
		local o = table.clone(opts)
		for k, v in extra or {} do
			o[k] = v
		end
		return o
	end
	local y0, y1, y2, y3 = 0, 15.5, 30.5, 33
	-- Fachada (z = -32)
	Kit.wall(ctx, f, "X", H.Z0, H.X0 - 0.5, H.X1 + 0.5, y0, y1, band(g, { Openings = {
		op(-31, -23, 4, 12, "window"), op(-19.5, -12.5, 1, 10), op(-11, -1, 3, y1, "glass"), op(3, 9, 6, 11, "window"),
	} }))
	Kit.wall(ctx, f, "X", H.Z0, H.X0 - 0.5, H.X1 + 0.5, y1, y2, band(u, { Openings = {
		op(-31, -23, 18, 27, "window"), op(-19, -13, 18, 27, "window"), op(-11, -1, y1, 29, "glass"), op(2, 10, 19, 27, "window"),
	} }))
	Kit.wall(ctx, f, "X", H.Z0, 0, H.X1 + 0.5, y2, y3, p)
	-- Lateral izquierdo (x = -34): la torre abre la casa
	local tz0, tz1 = T.Z - math.sqrt(T.R ^ 2 - (H.X0 - T.X) ^ 2), T.Z + math.sqrt(T.R ^ 2 - (H.X0 - T.X) ^ 2)
	Kit.wall(ctx, f, "Z", H.X0, H.Z0, H.Z1, y0, y1, band(g, { Openings = { op(tz0, tz1, 1, y1), op(-2, 14, 3, 13, "glass") } }))
	Kit.wall(ctx, f, "Z", H.X0, H.Z0, H.Z1, y1, y2, band(u, { Openings = { op(tz0, tz1, y1, y2), op(0, 12, 18, 27, "window") } }))
	Kit.wall(ctx, f, "Z", H.X0, -6, H.Z1, y2, y3, p)
	-- Trasera (z = 18): terraza y balcón
	Kit.wall(ctx, f, "X", H.Z1, H.X0 - 0.5, H.X1 + 0.5, y0, y1, band(g, { Openings = {
		op(-29, -23, 1, 10), op(-21, -14, 3, 13, "glass"), op(-10, -4, 1, 10), op(2, 10, 5, 11, "window"),
	} }))
	Kit.wall(ctx, f, "X", H.Z1, H.X0 - 0.5, H.X1 + 0.5, y1, y2, band(u, { Openings = {
		op(-30, -24, 16, 25), op(-18, -14, 21, 26, "window"), op(-10, -2, 18, 27, "glass"), op(1, 7, 16, 25),
	} }))
	Kit.wall(ctx, f, "X", H.Z1, H.X0 - 0.5, H.X1 + 0.5, y2, y3, p)
	-- Lateral derecho (x = 12): la puerta del garaje y ventanas por encima de su tejado
	Kit.wall(ctx, f, "Z", H.X1, H.Z0, H.Z1, y0, y1, band(g, { Openings = { op(-31.5, -25.5, 1, 10), op(8, 15, 5, 11, "window") } }))
	Kit.wall(ctx, f, "Z", H.X1, H.Z0, H.Z1, y1, y2, band(u, { Openings = { op(0, 12, 18, 27, "window") } }))
	Kit.wall(ctx, f, "Z", H.X1, H.Z0, H.Z1, y2, y3, p)
	-- Revestimiento de madera en la planta alta (listones verticales) y franja oscura entre plantas
	for _, x in { -33, -21.5, 10.8 } do
		Kit.deco(ctx, f, "Revestimiento", V(1.6, 13, 0.3), CF(x + 0.8, 23, H.Z0 - 0.65), CLAD, M.WoodPlanks, nil, true)
	end
	Kit.deco(ctx, f, "Imposta", V(H.X1 - H.X0 + 1.6, 0.8, 0.4), CF((H.X0 + H.X1) / 2, 15.5, H.Z0 - 0.7), TRIM, M.Metal, nil, true)
	Kit.deco(ctx, f, "Imposta", V(H.X1 - H.X0 + 1.6, 0.8, 0.4), CF((H.X0 + H.X1) / 2, 15.5, H.Z1 + 0.7), TRIM, M.Metal, nil, true)
	Kit.deco(ctx, f, "Albardilla", V(H.X1 - H.X0 + 1.6, 0.4, 1.6), CF((H.X0 + H.X1) / 2, 33.2, H.Z1), TRIM, M.Metal, nil, true)
	-- Hiedra trepando por la fachada (como en la imagen)
	for i = 0, 7 do
		Kit.deco(ctx, f, "Hiedra", V(1.4, 2.2, 0.4), CF(-33 + (i % 3) * 0.8, 3 + i * 3.2, H.Z0 - 0.7) * ANG(0, 0, i * 0.3), rgb(70, 130, 60), M.LeafyGrass)
	end
	-- Cámara de seguridad y antena pequeña en la fachada
	local cam = Kit.group(f, "CamaraSeguridad")
	Kit.deco(ctx, cam, "Soporte", V(0.3, 0.3, 1.2), CF(-21, 13, H.Z0 - 1.1), TRIM)
	Kit.deco(ctx, cam, "Camara", V(0.9, 0.8, 1.6), CF(-21, 12.6, H.Z0 - 2) * ANG(-0.4, 0.3, 0), C.White)
	Kit.neon(ctx, cam, "Piloto", V(0.15, 0.15, 0.1), CF(-21, 12.7, H.Z0 - 2.85), C.Red)
end

---------------------------------------------------------------------
-- Garaje por fuera
---------------------------------------------------------------------
local function garageShell(ctx: Kit.Ctx, m: Instance)
	local f = Kit.group(m, "GarajeFuera")
	local wall = { Color = rgb(70, 74, 84), Material = M.Concrete, Name = "Wall", Frame = TRIM }
	-- Frente abierto (puerta enrollada arriba), lateral con ventanas y fondo
	Kit.wall(ctx, f, "X", G.Z0, G.X0, G.X1 + 0.5, 0, 16, { Color = wall.Color, Material = wall.Material, Name = "Wall", Openings = { op(15, 43, 1, 13) } })
	Kit.wall(ctx, f, "Z", G.X1, G.Z0, G.Z1, 0, 16, { Color = wall.Color, Material = wall.Material, Name = "Wall", Frame = TRIM, Openings = { op(-30, -22, 6, 12, "window") } })
	Kit.wall(ctx, f, "X", G.Z1, G.X0, G.X1 + 0.5, 0, 16, { Color = wall.Color, Material = wall.Material, Name = "Wall" })
	-- Marco de la puerta, persiana enrollada y luz azul del interior que se escapa
	Kit.deco(ctx, f, "Persiana", V(28, 1.6, 1.4), CF(29, 13.2, G.Z0 + 0.9), rgb(200, 200, 196), M.Metal, nil, true)
	for _, x in { 15, 43 } do
		Kit.deco(ctx, f, "MarcoPuerta", V(0.6, 12, 1.4), CF(x, 7, G.Z0 - 0.2), TRIM, M.Metal, nil, true)
	end
	local strip = Kit.neon(ctx, f, "TiraNeon", V(28, 0.25, 0.3), CF(29, 13.9, G.Z0 - 0.7), C.Cyan)
	Kit.light(ctx, strip, 18, 1.2, C.Cyan, nil, "Surface")
	local sign = Kit.deco(ctx, f, "Rotulo", V(12, 1.6, 0.3), CF(29, 15.2, G.Z0 - 0.75), rgb(250, 214, 70), M.SmoothPlastic, nil, true)
	Kit.signText(sign, "TALLER DE COSME", Enum.NormalId.Front, rgb(40, 30, 20), rgb(250, 214, 70))
	-- Placas solares en el tejado del garaje (3 filas)
	local solar = Kit.group(f, "PlacasSolares")
	for row = 0, 2 do
		for col = 0, 3 do
			local x, z = 17 + col * 7.4, -26 + row * 10
			local base = CF(x, Layout.CEIL.G + 1, z)
			Kit.deco(ctx, solar, "Pata", V(0.3, 2.2, 0.3), base * CF(0, 1.1, 2), C.Steel, M.Metal, nil, true)
			Kit.deco(ctx, solar, "Pata", V(0.3, 0.8, 0.3), base * CF(0, 0.4, -2), C.Steel, M.Metal, nil, true)
			local panel = Kit.deco(ctx, solar, "PlacaSolar", V(7, 0.25, 5), base * CF(0, 1.3, 0) * ANG(math.rad(16), 0, 0), rgb(24, 40, 90), M.Glass, nil, true)
			panel.Reflectance = 0.25
			for k = 1, 3 do
				Kit.deco(ctx, solar, "Celda", V(0.08, 0.27, 4.8), base * CF(0, 1.3, 0) * ANG(math.rad(16), 0, 0) * CF(-3.5 + k * 1.75, 0, 0), rgb(150, 160, 180), M.Metal)
			end
		end
	end
	-- Conducto de cables del tejado a la torre-portal
	Kit.deco(ctx, f, "Conducto", V(1.2, 1.2, 22), CF(40, Layout.CEIL.G + 1.6, -5), rgb(60, 64, 72), M.Metal, nil, true)
end

---------------------------------------------------------------------
-- Porche y jardín delantero
---------------------------------------------------------------------
local function fence(ctx: Kit.Ctx, parent: Instance, a: Vector3, b: Vector3, height: number?)
	local h = height or 3.2
	local m = Kit.group(parent, "Valla")
	local d = b - a
	local len = d.Magnitude
	local yaw = math.atan2(-d.X, -d.Z)
	local mid = (a + b) / 2
	for _, y in { h * 0.35, h * 0.8 } do
		Kit.box(ctx, m, "Larguero", V(0.25, 0.35, len), CF(mid.X, y, mid.Z) * ANG(0, yaw, 0), rgb(140, 96, 62), M.WoodPlanks, { CanQuery = false })
	end
	local n = math.max(1, math.floor(len / 1.2))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		Kit.box(ctx, m, if i % 4 == 0 then "Poste" else "Tabla", V(if i % 4 == 0 then 0.6 else 0.15, h, 0.8), CF(p.X, h / 2, p.Z) * ANG(0, yaw, 0), rgb(150, 104, 68), M.WoodPlanks, { CanQuery = false })
	end
	return m
end
Exterior.fence = fence

local function flowers(ctx: Kit.Ctx, parent: Instance, x0: number, x1: number, z0: number, z1: number, n: number)
	local R = ctx.Rand
	local colors = { rgb(240, 80, 120), rgb(250, 210, 70), rgb(160, 110, 240), rgb(255, 255, 255), rgb(255, 140, 60), rgb(90, 160, 255) }
	for _ = 1, n do
		local x, z = R.range(x0, x1), R.range(z0, z1)
		Kit.deco(ctx, parent, "Tallo", V(0.12, 1, 0.12), CF(x, 0.5, z), rgb(70, 130, 60))
		Kit.ball(ctx, parent, "Flor", R.range(0.5, 0.8), CF(x, 1.1, z), R.pick(colors), M.SmoothPlastic)
	end
end

local function bush(ctx: Kit.Ctx, parent: Instance, x: number, z: number, s: number?)
	local size = s or 3
	local b = Kit.ball(ctx, parent, "Arbusto", size, CF(x, size * 0.4, z), rgb(70, 124, 58), M.LeafyGrass)
	b.Size = V(size, size * 0.8, size)
end

local function tree(ctx: Kit.Ctx, parent: Instance, x: number, z: number, h: number?)
	local m = Kit.group(parent, "Arbol")
	local height = h or 16
	Kit.cyl(ctx, m, "Tronco", height * 0.6, 1.6, CF(x, height * 0.3, z), rgb(110, 80, 52), M.Wood, true)
	local R = ctx.Rand
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		local leaves = Kit.ball(ctx, m, "Copa", R.range(6, 9), CF(x + math.cos(a) * 2.5, height * 0.68 + R.range(-1, 2), z + math.sin(a) * 2.5), rgb(70, 140, 60):Lerp(rgb(110, 170, 70), R.next()), M.LeafyGrass)
		if i > 3 then
			leaves:AddTag("LeafDetail")
		end
	end
	Kit.ball(ctx, m, "Copa", 9, CF(x, height * 0.8, z), rgb(80, 150, 64), M.LeafyGrass)
	return m
end
Exterior.tree = tree

local function frontYard(ctx: Kit.Ctx, m: Instance)
	local y = Kit.group(m, "JardinDelantero")
	-- Camino de la calle a la puerta y entrada del garaje
	Kit.box(ctx, y, "Camino", V(7, 0.2, 13), CF(-16, 0.1, -43.5), rgb(206, 196, 178), M.Pavement)
	Kit.box(ctx, y, "Vado", V(30, 0.15, 18), CF(29, 0.075, -41), rgb(170, 168, 164), M.Concrete)
	for i = 0, 3 do
		Kit.deco(ctx, y, "Losa", V(2.4, 0.06, 1.6), CF(-16 + (if i % 2 == 0 then -1.5 else 1.5), 0.23, -48 + i * 3), rgb(180, 172, 160), M.Slate)
	end
	-- Porche: tarima, escalón, marquesina con columnas y luces
	local porch = Kit.group(y, "Porche")
	Kit.box(ctx, porch, "Tarima", V(12, 1, 5), CF(-16, 0.5, -34.5), rgb(160, 116, 76), M.WoodPlanks, { CanQuery = true })
	Kit.box(ctx, porch, "Escalon", V(8, 0.5, 1.5), CF(-16, 0.25, -37.75), rgb(160, 116, 76), M.WoodPlanks)
	for _, x in { -21.5, -10.5 } do
		Kit.box(ctx, porch, "Columna", V(0.8, 10, 0.8), CF(x, 6, -36.4), TRIM, M.Metal)
	end
	Kit.box(ctx, porch, "Marquesina", V(14, 0.6, 6), CF(-16, 11.3, -35), TRIM, M.Metal)
	for _, x in { -19, -13 } do
		local spot = Kit.neon(ctx, porch, "Foco", V(0.8, 0.1, 0.8), CF(x, 10.95, -35), rgb(255, 230, 190))
		Kit.light(ctx, spot, 14, 1.2, rgb(255, 226, 180), nil, "Spot")
	end
	Kit.deco(ctx, porch, "Felpudo", V(5, 0.06, 2.4), CF(-16, 1.03, -33.6), rgb(90, 60, 40), M.Fabric, nil, true)
	local mat = Kit.deco(ctx, porch, "FelpudoTexto", V(4.6, 0.02, 2), CF(-16, 1.07, -33.6), rgb(90, 60, 40), M.Fabric, nil, true)
	Builder.sign(mat, "¿VIENES DEL FUTURO?", Enum.NormalId.Top, rgb(240, 220, 160), rgb(90, 60, 40))
	-- Puerta principal grande (se abre)
	Kit.door(ctx, y, -16, Layout.F0, H.Z0, 180, 7, 9, rgb(60, 44, 32), false)
	-- Valla de madera (con hueco para el camino y el vado)
	fence(ctx, y, V(-49.5, 0, -49), V(-19.5, 0, -49))
	fence(ctx, y, V(-12.5, 0, -49), V(12, 0, -49))
	fence(ctx, y, V(-49.5, 0, -49), V(-49.5, 0, -14))
	-- Cancela abierta
	Kit.box(ctx, y, "Cancela", V(3.2, 3, 0.3), CF(-21.1, 1.6, -47.5) * ANG(0, math.rad(70), 0), rgb(150, 104, 68), M.WoodPlanks, { CanQuery = false })
	-- Robot buzón (en la imagen: una caja con cara junto al camino)
	local mailbox = Kit.group(y, "RobotBuzon")
	Kit.box(ctx, mailbox, "Pie", V(0.6, 2.4, 0.6), CF(-21, 1.2, -45), TRIM, M.Metal)
	Kit.box(ctx, mailbox, "Cuerpo", V(2.2, 1.8, 1.6), CF(-21, 3.3, -45), rgb(200, 205, 215), M.Metal)
	Kit.neon(ctx, mailbox, "Ojos", V(1.4, 0.3, 0.05), CF(-21, 3.6, -45.82), C.Cyan)
	Kit.deco(ctx, mailbox, "Ranura", V(1.4, 0.15, 0.05), CF(-21, 2.9, -45.82), TRIM)
	Kit.deco(ctx, mailbox, "Antena", V(0.08, 1, 0.08), CF(-20.4, 4.7, -45), TRIM)
	Kit.ball(ctx, mailbox, "Bombilla", 0.35, CF(-20.4, 5.3, -45), C.Red, M.Neon)
	Kit.doc(mailbox:FindFirstChild("Cuerpo") :: BasePart, "Carta en el buzón", "«Estimado vecino Cosme: le rogamos que deje de abrir portales en el jardín. Firmado: la comunidad de vecinos.»\n\nDebajo, escrito a lápiz: «Las coordenadas del sábado son 66-B. Que no se entere el pez.»", "CosmeBuzon")
	-- Cartel «NO ENTRAR» en un panel de madera, junto al vado (como en la imagen)
	local board = Kit.group(y, "CartelNoEntrar")
	for _, x in { 8.5, 11.5 } do
		Kit.box(ctx, board, "Poste", V(0.5, 6, 0.5), CF(x, 3, -45), rgb(120, 84, 56), M.Wood)
	end
	local panel = Kit.box(ctx, board, "Tablero", V(4.4, 3.6, 0.3), CF(10, 3.8, -45.2), rgb(150, 104, 68), M.WoodPlanks)
	local red = Kit.deco(ctx, board, "Cartel", V(3.6, 2.4, 0.1), CF(10, 4, -45.4), rgb(200, 40, 40), M.SmoothPlastic, nil, true)
	Kit.signText(red, "NO ENTRAR\n¡LABORATORIO!", Enum.NormalId.Front, rgb(255, 255, 255), rgb(200, 40, 40))
	Kit.doc(panel, "Cartel «NO ENTRAR»", "NO ENTRAR. Peligro: portales, rayos, gallinas gigantes y matemáticas avanzadas.\n\n(Letra pequeña: «Si eres mi vecino, sí puedes entrar. Trae batido de apio.»)")
	-- Caja «NO TOCAR», máquina medio desmontada, antena pequeña, cables y plantas
	local box = Kit.box(ctx, y, "CajaNoTocar", V(2.4, 2, 2.4), CF(-8, 1, -40), rgb(230, 190, 50), M.Metal)
	local label = Kit.deco(ctx, y, "Etiqueta", V(2, 0.8, 0.05), CF(-8, 1.2, -41.25), rgb(30, 30, 30), nil, nil, true)
	Kit.signText(label, "NO TOCAR", Enum.NormalId.Front, rgb(255, 220, 60), rgb(30, 30, 30))
	Kit.prompt(box, "Tocar", "📦 Caja «NO TOCAR»", "Experiment", { Effect = "Zap", Text = "¡ZAS! Un chispazo te pone el pelo de punta. Ahora entiendes el peinado de Cosme." })
	local machine = Kit.group(y, "MaquinaDesmontada")
	Kit.box(ctx, machine, "Carcasa", V(4, 3, 3), CF(-36, 1.5, -40), rgb(120, 126, 136), M.Metal)
	Kit.box(ctx, machine, "Tapa", V(4.2, 0.3, 3.2), CF(-36, 3.6, -38.4) * ANG(-0.9, 0, 0), rgb(120, 126, 136), M.Metal)
	Kit.cyl(ctx, machine, "Engranaje", 0.4, 2, CF(-33.4, 0.2, -41), rgb(200, 150, 60), M.Metal)
	Props.make(ctx, machine, "Pile", CF(-38.5, 0, -42.5))
	Props.make(ctx, machine, "CableRun", CF(-34, 0, -38))
	Kit.neon(ctx, machine, "Testigo", V(0.4, 0.4, 0.1), CF(-35, 2.2, -41.55), C.Orange)
	local antenna = Kit.group(y, "AntenaPequena")
	Kit.box(ctx, antenna, "Mastil", V(0.3, 7, 0.3), CF(-44, 3.5, -36), C.Steel, M.Metal)
	for i = 1, 3 do
		Kit.deco(ctx, antenna, "Varilla", V(2.6 - i * 0.5, 0.12, 0.12), CF(-44, 4 + i * 1, -36), C.Steel, M.Metal)
	end
	Kit.ball(ctx, antenna, "Luz", 0.4, CF(-44, 7.2, -36), C.Red, M.Neon)
	-- Árbol grande, arbustos, flores, farolillos y un robot limpiador que hace la ronda del camino
	tree(ctx, y, -40, -44, 18)
	for _, p in { { -26, -36 }, { -6, -36 }, { -2, -36 }, { -47, -26 }, { 5, -46 } } do
		bush(ctx, y, p[1], p[2], 3)
	end
	flowers(ctx, y, -30, -24, -47, -38, 16)
	flowers(ctx, y, -10, -2, -47, -43, 12)
	for _, p in { { -19.5, -40 }, { -12.5, -40 }, { -19.5, -46 }, { -12.5, -46 } } do
		local lamp = Kit.group(y, "Farolillo")
		Kit.box(ctx, lamp, "Poste", V(0.35, 2.2, 0.35), CF(p[1], 1.1, p[2]), TRIM, M.Metal)
		local bulb = Kit.neon(ctx, lamp, "Luz", V(0.6, 0.6, 0.6), CF(p[1], 2.5, p[2]), rgb(255, 230, 180))
		if p[2] == -40 then
			Kit.light(ctx, bulb, 10, 0.8, rgb(255, 226, 180))
		end
	end
	Props.make(ctx, y, "CableRun", CF(-28, 0, -34))
	Kit.robot(ctx, y, -15, 0.2, -44, "Limpiador", { { -15, -44 }, { -17, -39 }, { -15, -38.5 }, { -14, -46 } }, 2)
end

---------------------------------------------------------------------
-- Terraza, balcón y jardín trasero
---------------------------------------------------------------------
local function backGarden(ctx: Kit.Ctx, m: Instance)
	local g = Kit.group(m, "JardinTrasero")
	local D = Layout.Deck
	-- Terraza (tarima) y balcón de arriba (con columnas y barandilla de cristal)
	Kit.box(ctx, g, "Floor", V(D.X1 - D.X0, 1, D.Z1 - D.Z0), CF((D.X0 + D.X1) / 2, 0.5, (D.Z0 + D.Z1) / 2), rgb(160, 116, 76), M.WoodPlanks, { CanQuery = true })
	Kit.box(ctx, g, "Escalon", V(D.X1 - D.X0, 0.5, 1.5), CF((D.X0 + D.X1) / 2, 0.25, D.Z1 + 0.75), rgb(150, 108, 70), M.WoodPlanks)
	Kit.box(ctx, g, "BalconSuelo", V(D.X1 - D.X0, 1, 6), CF((D.X0 + D.X1) / 2, Layout.F1 - 0.5, H.Z1 + 3), rgb(170, 168, 160), M.Concrete, { CanQuery = true })
	for _, x in { D.X0 + 0.5, -11, D.X1 - 0.5 } do
		Kit.box(ctx, g, "Columna", V(0.8, 14, 0.8), CF(x, 1 + 7, H.Z1 + 5.6), TRIM, M.Metal)
	end
	Kit.railing(ctx, g, V(D.X0, Layout.F1, H.Z1 + 5.8), V(D.X1, Layout.F1, H.Z1 + 5.8))
	Kit.railing(ctx, g, V(D.X0 + 0.2, Layout.F1, H.Z1 + 0.6), V(D.X0 + 0.2, Layout.F1, H.Z1 + 5.8))
	Kit.railing(ctx, g, V(D.X1 - 0.2, Layout.F1, H.Z1 + 0.6), V(D.X1 - 0.2, Layout.F1, H.Z1 + 5.8))
	-- Muebles de la terraza: mesa con sombrilla y sillas, tumbonas y barbacoa
	local furn = Kit.furn(ctx, g, rgb(120, 84, 56), rgb(220, 220, 210), C.Orange)
	local Furniture = require(script.Parent.Parent.Furniture)
	Furniture.table(furn, Kit.at(ctx, -6, 1, 22.5), 5, 3.2, rgb(110, 80, 52))
	for _, p in { { -9, 22.5, -90 }, { -3, 22.5, 90 } } do
		Furniture.chair(furn, Kit.at(ctx, p[1], 1, p[2], p[3]), rgb(60, 60, 66))
	end
	local umbrella = Kit.group(g, "Sombrilla")
	Kit.cyl(ctx, umbrella, "Palo", 9, 0.3, CF(-6, 5.5, 22.5), C.White, M.Metal, true)
	local cloth = Kit.cyl(ctx, umbrella, "Lona", 0.6, 9, CF(-6, 9.8, 22.5), rgb(40, 140, 120), M.Fabric)
	cloth.CastShadow = true
	Props.make(ctx, g, "Food", CF(-6.5, 4.15, 22.2))
	Props.make(ctx, g, "Mug", CF(-4.8, 4.15, 23))
	for _, x in { -30, -25 } do
		local lounger = Kit.group(g, "Tumbona")
		Kit.box(ctx, lounger, "Base", V(2.6, 1, 6), CF(x, 1.5, 22), C.White, M.SmoothPlastic)
		Kit.box(ctx, lounger, "Respaldo", V(2.6, 2.6, 0.5), CF(x, 2.8, 19.4) * ANG(math.rad(-25), 0, 0), C.White, M.SmoothPlastic)
		local seat = Furniture.seatPart(lounger, Kit.at(ctx, x, 2.2, 22))
		Furniture.usable(seat, "Sit")
	end
	local bbq = Kit.group(g, "Barbacoa")
	Kit.box(ctx, bbq, "Mueble", V(5, 3, 2.4), CF(6, 2.5, 23.5), rgb(80, 84, 92), M.Brick)
	Kit.box(ctx, bbq, "Parrilla", V(3, 0.2, 1.8), CF(5.5, 4.1, 23.5), C.Dark, M.DiamondPlate)
	local coals = Kit.neon(ctx, bbq, "Brasas", V(2.6, 0.1, 1.4), CF(5.5, 4.05, 23.5), C.Orange, 0.2)
	Kit.fx(coals, "Steam", 5)
	Kit.box(ctx, bbq, "Chimenea", V(0.8, 4, 0.8), CF(7.8, 6, 24.2), C.Dark, M.Metal)
	Props.make(ctx, bbq, "Food", CF(3.9, 4, 23.4))
	-- Plantas en macetas a lo largo de la terraza y luces de jardín
	for i = 0, 5 do
		Props.make(ctx, g, "Plant", CF(-33 + i * 8.5, 1, 25.2))
	end
	-- Árboles, setos, flores y bancos
	tree(ctx, g, -42, 38, 17)
	tree(ctx, g, -10, 44, 15)
	tree(ctx, g, 44, 44, 14)
	for _, p in { { -46, 26 }, { -46, 31 }, { -30, 46 }, { 2, 46 }, { 47, 30 }, { 47, 20 } } do
		bush(ctx, g, p[1], p[2], 3.4)
	end
	flowers(ctx, g, -36, -16, 28, 32, 24)
	flowers(ctx, g, 2, 12, 40, 47, 12)
	for _, p in { { -26, 42, 0 }, { 6, 36, 90 } } do
		Furniture.bench(furn, Kit.at(ctx, p[1], 0, p[2], p[3]), 5, rgb(120, 84, 56))
	end
	-- Camino de losas hasta la torre-portal
	for i = 0, 9 do
		Kit.deco(ctx, g, "Losa", V(2.6, 0.06, 2), CF(-20 + i * 4, 0.03, 32 + math.sin(i) * 1.5), rgb(190, 180, 166), M.Slate)
	end
	-- Antenas y tubos que salen del suelo (vienen del sótano) y la máquina enterrada
	local tubes = Kit.group(g, "Tubos")
	for i, p in ipairs({ { -38, 30 }, { -34, 33 }, { 12, 30 }, { 14, 40 } }) do
		local h = 2 + (i % 3)
		Kit.cyl(ctx, tubes, "Tubo", h, 0.8, CF(p[1], h / 2, p[2]), rgb(120, 126, 136), M.Metal, true)
		Kit.cylX(ctx, tubes, "Codo", 1.6, 0.8, CF(p[1] + 0.6, h, p[2]), rgb(120, 126, 136), M.Metal)
		local vent = Kit.neon(ctx, tubes, "Respiradero", V(0.5, 0.5, 0.5), CF(p[1] + 1.4, h, p[2]), C.Green, 0.3)
		Kit.fx(vent, "Steam", 3)
	end
	for _, p in { { -46, 46 }, { 22, 46 } } do
		local ant = Kit.group(g, "Antena")
		Kit.box(ctx, ant, "Mastil", V(0.4, 12, 0.4), CF(p[1], 6, p[2]), C.Steel, M.Metal)
		for k = 1, 4 do
			Kit.deco(ctx, ant, "Brazo", V(3.2 - k * 0.5, 0.15, 0.15), CF(p[1], 6 + k * 1.4, p[2]) * ANG(0, k * 0.5, 0), C.Steel, M.Metal)
		end
		Kit.ball(ctx, ant, "Luz", 0.5, CF(p[1], 12.2, p[2]), C.Red, M.Neon)
	end
	local buried = Kit.group(g, "MaquinaEnterrada")
	Kit.box(ctx, buried, "Monticulo", V(8, 1.2, 6), CF(-20, 0.6, 40), rgb(110, 90, 60), M.Ground)
	Kit.box(ctx, buried, "Carcasa", V(5, 2.4, 3), CF(-20, 1.4, 40) * ANG(0, 0, 0.25), rgb(150, 110, 60), M.CorrodedMetal)
	Kit.cylX(ctx, buried, "Rueda", 0.6, 3, CF(-17.8, 2.2, 41.6) * ANG(0, math.pi / 2, 0), rgb(120, 90, 50), M.CorrodedMetal)
	local led = Kit.neon(ctx, buried, "Luz", V(0.4, 0.4, 0.1), CF(-19, 2.3, 38.4), C.Green)
	Kit.light(ctx, led, 8, 0.6, C.Green)
	Kit.doc(buried:FindFirstChild("Carcasa") :: BasePart, "Placa oxidada", "«PROTOTIPO 0 — EXCAVADORA TEMPORAL. Enterrada en el futuro, desenterrada en el pasado. No intentar arrancar en martes.»", "CosmeMaquinaEnterrada")
	-- El experimento «que no debería estar ahí»: una roca que flota sobre un cristal que zumba
	local exp = Kit.group(g, "ExperimentoFlotante")
	Kit.box(ctx, exp, "Pedestal", V(3, 1.2, 3), CF(-4, 0.6, 38), rgb(80, 84, 96), M.Slate)
	local crystal = Kit.neon(ctx, exp, "Cristal", V(1.2, 2.6, 1.2), CF(-4, 2.5, 38) * ANG(0, 0.6, 0), C.Magenta, 0.15)
	local rock = Kit.ball(ctx, exp, "RocaFlotante", 2.8, CF(-4, 6.4, 38), rgb(110, 100, 120), M.Basalt)
	Kit.anomaly(rock)
	Kit.spin(rock, 0.05, "Y")
	Kit.fx(crystal, "Energy", 10)
	Kit.light(ctx, crystal, 12, 1.2, C.Magenta)
	Kit.beam(crystal, rock, C.Magenta, 0.25)
	Kit.prompt(crystal, "Tocar el cristal", "💎 Experimento raro", "Experiment", { Effect = "Float", Text = "La roca da media vuelta en el aire y te saluda. Las rocas no saludan. Esta sí." })
	-- Valla del jardín trasero (madera) por los tres lados
	fence(ctx, g, V(-49.5, 0, -14), V(-49.5, 0, 49.5))
	fence(ctx, g, V(-49.5, 0, 49.5), V(49.5, 0, 49.5))
	fence(ctx, g, V(49.5, 0, 49.5), V(49.5, 0, 6))
	-- Robot jardinero que cuida las flores
	Kit.robot(ctx, g, -30, 0, 30, "Jardinero", { { -30, 30 }, { -18, 31 }, { -18, 36 }, { -36, 36 } }, 1.6)
	-- Luciérnagas por la noche
	local ff = Kit.neon(ctx, g, "Luciernagas", V(1, 1, 1), CF(-28, 0.5, 34), rgb(255, 250, 160), 1)
	Kit.fx(ff, "Fireflies", 4)
end

---------------------------------------------------------------------
-- Torre-portal (en el jardín, encima de la sala de portales del sótano): vórtice azul arriba
---------------------------------------------------------------------
local function portalTower(ctx: Kit.Ctx, m: Instance)
	local P = Layout.PortalTower
	local t = Kit.group(m, "TorrePortal")
	-- Base de piedra, cuerpo metálico con ventanas de ojo de buey y anillos de neón
	Kit.cyl(ctx, t, "Base", 4, P.R * 2 + 2, CF(P.X, 2, P.Z), rgb(120, 116, 110), M.Slate, true)
	Kit.cyl(ctx, t, "Cuerpo", 20, P.R * 2, CF(P.X, 14, P.Z), rgb(96, 100, 112), M.DiamondPlate, true)
	Kit.cyl(ctx, t, "Cuello", 6, P.R * 1.4, CF(P.X, 27, P.Z), rgb(80, 84, 96), M.Metal, true)
	for i, y in { 6, 12, 18, 23 } do
		local ring = Kit.cyl(ctx, t, "AnilloNeon", 0.5, P.R * 2 + 0.3, CF(P.X, y, P.Z), if i % 2 == 0 then C.Cyan else C.Blue, M.Neon)
		ring.Transparency = 0.1
		ring.CastShadow = false
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + 0.4
		local win = Kit.neon(ctx, t, "OjoDeBuey", V(0.3, 2, 2), CF(P.X + math.cos(a) * P.R, 15, P.Z + math.sin(a) * P.R) * ANG(0, -a, 0), rgb(120, 200, 255), 0.2)
		win.Shape = Enum.PartType.Cylinder
	end
	-- Tuberías que suben por fuera
	for _, a in { 0.9, 2.6 } do
		Kit.cyl(ctx, t, "Tuberia", 24, 0.9, CF(P.X + math.cos(a) * (P.R + 0.6), 12, P.Z + math.sin(a) * (P.R + 0.6)), rgb(160, 120, 70), M.Metal, true)
	end
	-- Plataforma y vórtice (portal de pie, mirando a la calle)
	Kit.cyl(ctx, t, "Plataforma", 1, P.R * 2 + 3, CF(P.X, 30.5, P.Z), rgb(70, 74, 86), M.DiamondPlate, true)
	local portal = PortalSystem.build(ctx, t, CF(P.X, 36.6, P.Z), 4.5, { Name = "Vortice", Color = C.Cyan, Depth = 3, Layers = 8, Spin = 0.3, NoCoils = true, Stand = 1.3, Destination = 1 })
	portal:SetAttribute("Decor", true)
	local beacon = portal:FindFirstChild("Nucleo", true) :: BasePart?
	if beacon then
		local up = Kit.neon(ctx, t, "HazCielo", V(0.5, 0.5, 0.5), CF(P.X, 42, P.Z), C.Cyan, 1)
		Kit.anomaly(up)
		local top = Kit.neon(ctx, t, "HazCieloArriba", V(0.5, 0.5, 0.5), CF(P.X, 90, P.Z), C.Cyan, 1)
		Kit.anomaly(top)
		local b = Kit.beam(up, top, C.Cyan, 1.4)
		b.Transparency = NumberSequence.new(0.5, 1)
	end
end

function Exterior.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "Exterior")
	ground(ctx, m)
	facades(ctx, m)
	garageShell(ctx, m)
	frontYard(ctx, m)
	backGarden(ctx, m)
	portalTower(ctx, m)
	return m
end

-- Al arrancar el servidor (World/TerrainBuilder): se vacía el terreno donde va el sótano
function Exterior.terrain(terrain: Terrain, site: CFrame)
	local B = Layout.Basement
	local size = Vector3.new(B.X1 - B.X0 + 8, 40, B.Z1 - B.Z0 + 8)
	local center = site * CFrame.new((B.X0 + B.X1) / 2, -14, (B.Z0 + B.Z1) / 2)
	terrain:FillBlock(center, size, Enum.Material.Air)
end

return Exterior
