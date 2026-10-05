-- Exterior: la parcela de Cosme por fuera, como el render (docs/referencias/casa-cosme.png) y el plano
-- (docs/referencias/plano-casa-cosme.png; medidas en CosmeHouse/Layout).
--
--   * Casa moderna de dos plantas: planta baja de piedra cálida con ventanales, planta alta retranqueada
--     revestida de madera, cornisas oscuras con vuelo, terraza principal delante con barandilla de
--     cristal y jardineras con plantas colgando, porche con marquesina y escalones.
--   * A la derecha (desde la calle) el garaje abierto, de una planta, con marco de luz, la terraza lateral
--     y las placas solares en su tejado. Detrás, el mirador semicircular de cristal.
--   * Delante: valla de madera, césped, arbustos, flores, el árbol grande a la izquierda, farola, buzón
--     con su robot, el cartel «NO ENTRAR» (tablón de madera con la placa roja) a la derecha, la caja
--     «NO TOCAR», la máquina medio desmontada, la antena pequeña y el robot limpiador.
--   * Detrás: terraza de madera, jardín trasero (barbacoa, tumbonas, máquina enterrada, experimento
--     flotante) y la terraza-jardín lateral con su mesa con sombrilla y el observatorio pequeño.
--   * La cúpula de observación, la torre de experimentos con el vórtice y la azotea: CosmeHouse/Observatory.
--
-- También: la losa del jardín (techo del sótano, con el hueco de la escalera), los forjados, y el
-- hueco en el terreno para el sótano (Exterior.terrain, al arrancar).

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local Builder = require(script.Parent.Parent.Builder)
local Furniture = require(script.Parent.Parent.Furniture)

local Exterior = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

-- Paleta de la fachada del render: piedra cálida, madera de cedro, revoco claro y remates oscuros
Exterior.Stone = rgb(190, 178, 160)
Exterior.Wood = rgb(176, 116, 70)
Exterior.Render = rgb(236, 232, 224)
Exterior.Trim = rgb(40, 42, 48)
local STONE, WOOD, RENDER, TRIM = Exterior.Stone, Exterior.Wood, Exterior.Render, Exterior.Trim
local GRASS = rgb(96, 142, 66)
local DECK = rgb(160, 112, 72)
local LEAF = rgb(70, 132, 58)

local H = Layout.House
local U = Layout.Upper
local G = Layout.Garage
local F0, F1, F2 = Layout.F0, Layout.F1, Layout.F2

-- Hueco del núcleo de la escalera en las losas (de la planta baja hacia abajo y hacia arriba)
function Exterior.coreHoles(): { { [string]: number } }
	local c = Layout.Core
	local s = Layout.Stairs.Hall
	return { { X0 = c.X0, X1 = c.X1, Z0 = s.Z0 + s.Near, Z1 = c.Z1 } }
end

function Exterior.stairHole(): { [string]: number }
	return Exterior.coreHoles()[1]
end

local function op(a: number, b: number, bottom: number, top: number, kind: string?): Kit.Opening
	return { A = a, B = b, Bottom = bottom, Top = top, Kind = kind }
end
Exterior.op = op

---------------------------------------------------------------------
-- Suelo: losa del jardín (y techo del sótano) y forjados
---------------------------------------------------------------------
local function ground(ctx: Kit.Ctx, m: Instance)
	local lot = Layout.Lot
	local holes = Exterior.coreHoles()
	-- (con el nombre de las manzanas: la misma hierba que el resto del barrio)
	Kit.slab(ctx, m, "BlockGround", lot, 0, 2, holes, GRASS, M.Grass)
	local floors = Kit.group(m, "Forjados")
	-- Planta baja: tarima cálida (cada sala pone encima su acabado) y el garaje de hormigón
	Kit.slab(ctx, floors, "Floor", H, F0, 1, holes, rgb(178, 132, 88), M.WoodPlanks)
	Kit.slab(ctx, floors, "Floor", G, F0, 1, nil, rgb(110, 112, 118), M.Concrete)
	-- Planta alta (con el hueco de la escalera) y la terraza principal delante (encima del salón)
	Kit.slab(ctx, floors, "Floor", U, F1, 1, holes, rgb(170, 124, 84), M.WoodPlanks)
	Kit.slab(ctx, floors, "Terrace", { X0 = H.X0, X1 = H.X1, Z0 = H.Z0, Z1 = U.Z0 }, F1, 1, nil, DECK, M.WoodPlanks)
	Kit.slab(ctx, floors, "Ceiling", { X0 = H.X0, X1 = H.X1, Z0 = H.Z0, Z1 = H.Z1 }, F1 - 1, 0.1, holes, C.White, M.SmoothPlastic)
	-- Tejado del garaje (terraza lateral y placas solares)
	Kit.slab(ctx, floors, "GarageRoof", G, F1, 1, nil, rgb(150, 146, 140), M.Concrete)
	Kit.slab(ctx, floors, "Ceiling", G, F1 - 1, 0.1, nil, rgb(56, 60, 70), M.SmoothPlastic)
	-- Azotea (con el hueco de la escalera, que sube a la cúpula) y su techo blanco debajo
	Kit.slab(ctx, floors, "RoofDeck", U, F2, 1, holes, rgb(176, 172, 164), M.Concrete)
	Kit.slab(ctx, floors, "Ceiling", U, F2 - 1, 0.1, holes, C.White, M.SmoothPlastic)
	-- Mirador semicircular de la planta alta: suelo, techo y su techo blanco
	local B = Layout.Bay
	Kit.halfDisc(ctx, floors, "Floor", B.X, B.Z + 0.5, B.R, F1, 1, rgb(170, 124, 84), M.WoodPlanks)
	Kit.halfDisc(ctx, floors, "BayRoof", B.X, B.Z + 0.5, B.R + 1, F2, 1, TRIM, M.Metal)
	-- Terraza de madera de atrás
	local D = Layout.Deck
	Kit.box(ctx, floors, "Floor", V(D.X1 - D.X0, 1, D.Z1 - D.Z0), CF((D.X0 + D.X1) / 2, 0.5, (D.Z0 + D.Z1) / 2), DECK, M.WoodPlanks, { CanQuery = true })
	Kit.box(ctx, floors, "Escalon", V(D.X1 - D.X0, 0.5, 1.5), CF((D.X0 + D.X1) / 2, 0.25, D.Z1 + 0.75), DECK:Lerp(TRIM, 0.1), M.WoodPlanks)
end

---------------------------------------------------------------------
-- Fachadas de la casa
---------------------------------------------------------------------
-- Paneles de revestimiento pegados a una fachada (madera o piedra), por fuera
local function cladding(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, out: number, a: number, b: number, y0: number, y1: number, color: Color3, material: Enum.Material)
	local len = b - a
	local size = if axis == "X" then V(len, y1 - y0, 0.3) else V(0.3, y1 - y0, len)
	local cf = if axis == "X" then CF((a + b) / 2, (y0 + y1) / 2, fixed + out * 0.65) else CF(fixed + out * 0.65, (y0 + y1) / 2, (a + b) / 2)
	return Kit.deco(ctx, parent, "Revestimiento", size, cf, color, material, nil, true)
end

-- Listones verticales sobre un panel de madera (se ve la veta del render)
local function slats(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, out: number, a: number, b: number, y0: number, y1: number)
	local n = math.floor((b - a) / 1.6)
	for i = 1, n - 1 do
		local u = a + i * (b - a) / n
		local cf = if axis == "X" then CF(u, (y0 + y1) / 2, fixed + out * 0.85) else CF(fixed + out * 0.85, (y0 + y1) / 2, u)
		Kit.deco(ctx, parent, "Liston", V(0.12, y1 - y0, 0.12), cf, WOOD:Lerp(TRIM, 0.35), M.Wood)
	end
end

-- Cornisa oscura con vuelo (a lo largo de un borde)
local function eave(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, out: number, a: number, b: number, y: number, depth: number, height: number?)
	local h = height or 1.4
	local len = b - a
	local size = if axis == "X" then V(len, h, depth) else V(depth, h, len)
	local cf = if axis == "X" then CF((a + b) / 2, y, fixed + out * (depth / 2 - 0.5)) else CF(fixed + out * (depth / 2 - 0.5), y, (a + b) / 2)
	Kit.box(ctx, parent, "Cornisa", size, cf, TRIM, M.Metal, { CanQuery = false })
	-- Tira de luz cálida bajo el vuelo
	local lcf = if axis == "X" then CF((a + b) / 2, y - h / 2 - 0.05, fixed + out * (depth - 0.9)) else CF(fixed + out * (depth - 0.9), y - h / 2 - 0.05, (a + b) / 2)
	Kit.neon(ctx, parent, "LuzCornisa", if axis == "X" then V(len - 1, 0.1, 0.2) else V(0.2, 0.1, len - 1), lcf, rgb(255, 214, 160), 0.2)
end

-- Plantas que cuelgan (hiedra) por el borde de una terraza
local function vines(ctx: Kit.Ctx, parent: Instance, axis: string, fixed: number, out: number, a: number, b: number, yTop: number, n: number)
	local R = ctx.Rand
	for i = 0, n - 1 do
		local u = a + (i + 0.5) * (b - a) / n + R.range(-0.6, 0.6)
		local len = R.range(2.5, 6)
		local cf = if axis == "X" then CF(u, yTop - len / 2, fixed + out * 1.95) else CF(fixed + out * 1.95, yTop - len / 2, u)
		Kit.deco(ctx, parent, "Hiedra", if axis == "X" then V(R.range(1, 1.8), len, 0.4) else V(0.4, len, R.range(1, 1.8)), cf, LEAF:Lerp(rgb(110, 170, 70), R.next()), M.LeafyGrass, nil, len >= 3.5)
	end
end
Exterior.vines = vines

-- Jardinera con plantas (en una terraza)
local function planter(ctx: Kit.Ctx, parent: Instance, x: number, y: number, z: number, w: number, d: number)
	local m = Kit.group(parent, "Jardinera")
	Kit.box(ctx, m, "Jardinera", V(w, 1.6, d), CF(x, y + 0.8, z), TRIM, M.Metal, { CanQuery = false })
	Kit.deco(ctx, m, "Tierra", V(w - 0.3, 0.1, d - 0.3), CF(x, y + 1.62, z), rgb(80, 60, 40), M.Ground)
	local R = ctx.Rand
	for i = 0, math.floor(w / 1.6) - 1 do
		local bx = x - w / 2 + 0.8 + i * 1.6
		Kit.ellipsoid(ctx, m, "Mata", V(1.8, R.range(1.4, 2.4), math.min(d, 1.8)), CF(bx, y + 2.2, z), LEAF:Lerp(rgb(120, 175, 80), R.next()), M.LeafyGrass)
	end
	return m
end
Exterior.planter = planter

local function facades(ctx: Kit.Ctx, m: Instance)
	local f = Kit.group(m, "Fachadas")
	local stone = { Color = STONE, Material = M.Slate, Name = "Wall", Frame = TRIM, GlassTransparency = 0.45 }
	local wood = { Color = WOOD, Material = M.WoodPlanks, Name = "Wall", Frame = TRIM, GlassTransparency = 0.45 }
	local function with(base: any, openings: { Kit.Opening }): any
		local o = table.clone(base)
		o.Openings = openings
		return o
	end
	local y0, y1, y2, y3 = 0, F1 - 0.5, F2 - 0.5, F2 + 1.5
	------------------------------------------------------------ Planta baja (piedra)
	-- Delante (z = -32): ventanales del salón, puerta principal con cristalera al lado, despacho
	Kit.wall(ctx, f, "X", H.Z0, H.X0 - 0.5, H.X1 + 0.5, y0, y1, with(stone, {
		op(-20, -12, 4, 11, "window"), op(-6.5, 0.5, F0, F0 + 9.5), op(1, 3.4, F0, 11, "glass"),
		op(7, 21, 2.5, 11.5, "glass"), op(24, 37, 2.5, 11.5, "glass"),
	}))
	-- Lateral izquierdo (x = 40): salón y cocina
	Kit.wall(ctx, f, "Z", H.X1, H.Z0, H.Z1, y0, y1, with(stone, { op(-30.5, -27, 2.5, 11.5, "glass"), op(-4, 12, 4, 11, "window") }))
	-- Detrás (z = 24): puerta de la cocina a la terraza, ventanas, puerta y cristalera del laboratorio
	Kit.wall(ctx, f, "X", H.Z1, H.X0 - 0.5, H.X1 + 0.5, y0, y1, with(stone, {
		op(-20, -9, 2.5, 11.5, "glass"), op(-7, -1, F0, F0 + 9.5), op(7, 13, 7, 11, "window"),
		op(25, 31, F0, F0 + 9.5), op(33, 38.5, 4, 11, "window"),
	}))
	-- Lateral derecho detrás del garaje (x = -22, z 12..24): ventana del laboratorio
	Kit.wall(ctx, f, "Z", H.X0, G.Z1, H.Z1, y0, y1, with(stone, { op(15, 21, 4, 11, "window") }))
	------------------------------------------------------------ Planta alta (madera), retranqueada
	-- Delante (z = -20): cristalera del dormitorio, puerta a la terraza y cristalera de experimentos
	Kit.wall(ctx, f, "X", U.Z0, U.X0 - 0.5, U.X1 + 0.5, y1, y2, with(wood, {
		op(-20, 1, F1 + 1, F1 + 10.5, "glass"), op(7.5, 12.5, F1, F1 + 9.5), op(18, 38, F1 + 1, F1 + 10.5, "glass"),
	}))
	Kit.wall(ctx, f, "Z", U.X1, U.Z0, U.Z1, y1, y2, with(wood, { op(-17, -3, F1 + 2, F1 + 10, "window"), op(12, 20, F1 + 5, F1 + 10, "window") }))
	Kit.wall(ctx, f, "X", U.Z1, U.X0 - 0.5, U.X1 + 0.5, y1, y2, with(wood, {
		op(Layout.Bay.X - Layout.Bay.R, Layout.Bay.X + Layout.Bay.R, F1, F2 - 1),
		op(18, 26, F1 + 2, F1 + 10, "window"), op(30, 38, F1 + 6, F1 + 10, "window"),
	}))
	Kit.wall(ctx, f, "Z", U.X0, U.Z0, U.Z1, y1, y2, with(wood, { op(-16, 0, F1 + 2, F1 + 10, "glass") }))
	-- Paneles de piedra en las esquinas de arriba y listones en la madera (como el render)
	for _, x in { U.X0 + 1.5, U.X1 - 1.5 } do
		cladding(ctx, f, "X", U.Z0, -1, x - 1.5, x + 1.5, y1, y2, STONE, M.Slate)
	end
	slats(ctx, f, "X", U.Z0, -1, 1, 7.5, y1, y2)
	slats(ctx, f, "X", U.Z0, -1, 12.5, 18, y1, y2)
	slats(ctx, f, "Z", U.X1, 1, -3, 12, y1, y2)
	-- Paneles de madera en la planta baja (entre los ventanales) y franja de piedra oscura (zócalo)
	cladding(ctx, f, "X", H.Z0, -1, 21, 24, y0, y1, WOOD, M.WoodPlanks)
	cladding(ctx, f, "X", H.Z0, -1, 37, H.X1 + 0.5, y0, y1, WOOD, M.WoodPlanks)
	cladding(ctx, f, "X", H.Z0, -1, -11.5, -6.5, y0, y1, WOOD, M.WoodPlanks)
	slats(ctx, f, "X", H.Z0, -1, -11.5, -6.5, y0, y1)
	Kit.deco(ctx, f, "Zocalo", V(H.X1 - H.X0 + 1.2, 1.2, 0.4), CF((H.X0 + H.X1) / 2, 0.6, H.Z0 - 0.65), rgb(86, 82, 78), M.Slate, nil, true)
	------------------------------------------------------------ Cornisas oscuras con vuelo
	-- Tejado (todo alrededor) con su peto y el borde de la terraza principal
	eave(ctx, f, "X", U.Z0, -1, U.X0 - 2, U.X1 + 2, F2 + 0.3, 3)
	eave(ctx, f, "X", U.Z1, 1, U.X0 - 2, U.X1 + 2, F2 + 0.3, 3)
	eave(ctx, f, "Z", U.X1, 1, U.Z0 - 2, U.Z1 + 2, F2 + 0.3, 3)
	eave(ctx, f, "Z", U.X0, -1, U.Z0 - 2, U.Z1 + 2, F2 + 0.3, 3)
	eave(ctx, f, "X", H.Z0, -1, G.X0 - 1, H.X1 + 1.5, F1 - 0.2, 2.2, 1.6)
	eave(ctx, f, "Z", H.X1, 1, H.Z0 - 1, U.Z0, F1 - 0.2, 2.2, 1.6)
	-- Peto del tejado (bajo, oscuro)
	for _, w in { { "X", U.Z0 }, { "X", U.Z1 } } do
		Kit.box(ctx, f, "Parapet", V(U.X1 - U.X0 + 1, 1.6, 0.6), CF((U.X0 + U.X1) / 2, F2 + 0.8, w[2]), TRIM, M.Metal, { CanQuery = true })
	end
	for _, x in { U.X0, U.X1 } do
		Kit.box(ctx, f, "Parapet", V(0.6, 1.6, U.Z1 - U.Z0), CF(x, F2 + 0.8, (U.Z0 + U.Z1) / 2), TRIM, M.Metal, { CanQuery = true })
	end
	------------------------------------------------------------ Terraza principal (delante, arriba)
	local t = Kit.group(f, "TerrazaPrincipal")
	Kit.railing(ctx, t, V(G.X0 + 0.3, F1, H.Z0 + 0.4), V(H.X1 - 0.3, F1, H.Z0 + 0.4))
	Kit.railing(ctx, t, V(H.X1 - 0.4, F1, H.Z0 + 0.4), V(H.X1 - 0.4, F1, U.Z0 - 0.5))
	for i = 0, 6 do
		local x = H.X0 + 4 + i * 8.6
		if math.abs(x - 10) > 4 then
			planter(ctx, t, x, F1, H.Z0 + 1.8, 4.4, 1.6)
		end
	end
	vines(ctx, t, "X", H.Z0, -1, H.X0, H.X1, F1 + 0.2, 20)
	vines(ctx, t, "Z", H.X1, 1, H.Z0, U.Z0, F1 + 0.2, 5)
	-- Hiedra que trepa por la esquina de la planta alta (izquierda)
	vines(ctx, t, "Z", U.X1, 1, U.Z0 + 0.5, U.Z0 + 6, F2, 4)
	-- Muebles de la terraza principal: mesa redonda, sillas, tumbona y luces
	local tf = Kit.furn(ctx, t, rgb(60, 60, 66), rgb(230, 226, 214), C.Cyan)
	Kit.cyl(ctx, t, "MesaTerraza", 0.3, 4, CF(22, F1 + 2.9, -23), rgb(240, 240, 236), M.SmoothPlastic, true)
	Kit.cyl(ctx, t, "PieMesa", 2.75, 0.5, CF(22, F1 + 1.38, -23), TRIM, M.Metal, true)
	for _, p in { { 19.2, -23, -90 }, { 24.8, -23, 90 } } do
		Furniture.chair(tf, Kit.at(ctx, p[1], F1, p[2], p[3]), rgb(60, 60, 66), t)
	end
	Props.make(ctx, t, "Mug", CF(22, F1 + 3.05, -23))
	local lounger = Kit.group(t, "Tumbona")
	Kit.box(ctx, lounger, "Base", V(2.6, 1, 6), CF(34.5, F1 + 0.5, -24), C.White, M.SmoothPlastic)
	Kit.box(ctx, lounger, "Respaldo", V(2.6, 2.4, 0.5), CF(34.5, F1 + 1.8, -26.7) * ANG(math.rad(25), 0, 0), C.White, M.SmoothPlastic)
	Furniture.usable(Furniture.seatPart(lounger, Kit.at(ctx, 34.5, F1 + 1.2, -24)), "Sit")
	-- Cámara de seguridad en la esquina
	local cam = Kit.group(f, "CamaraSeguridad")
	Kit.deco(ctx, cam, "Soporte", V(0.3, 0.3, 1.2), CF(H.X0 + 1, 11.5, H.Z0 - 1.1), TRIM)
	Kit.deco(ctx, cam, "Camara", V(0.9, 0.8, 1.6), CF(H.X0 + 1, 11.1, H.Z0 - 2) * ANG(-0.4, -0.4, 0), C.White)
	Kit.neon(ctx, cam, "Piloto", V(0.15, 0.15, 0.1), CF(H.X0 + 1, 11.2, H.Z0 - 2.85), C.Red)
	------------------------------------------------------------ Mirador semicircular de cristal (detrás)
	local B = Layout.Bay
	local bay = Kit.group(f, "Mirador")
	Kit.ringWall(ctx, bay, B.X, B.Z, B.R, F1 - 1, F2 - 0.5, {
		Segments = 24, Name = "Cristalera", PieceName = "Wall", Color = TRIM, Material = M.Metal, Frame = TRIM,
		Window = { Bottom = F1 + 0.6, Top = F2 - 1.2 }, GlassTransparency = 0.35,
		Skip = function(theta: number): boolean
			return math.sin(theta) < 0.05
		end,
	})
	-- Aros de metal por fuera (arriba y abajo) y columnas hasta el suelo del jardín
	for _, y in { F1 - 0.4, F2 - 0.6 } do
		for i = 0, 11 do
			local a = (i + 0.5) / 12 * math.pi
			Kit.deco(ctx, bay, "AroMetal", V(2 * math.pi * (B.R + 0.6) / 24 + 0.2, 0.7, 0.5), CF(B.X + math.cos(a) * (B.R + 0.6), y, B.Z + math.sin(a) * (B.R + 0.6)) * ANG(0, -(a + math.pi / 2), 0), TRIM, M.Metal, nil, true)
		end
	end
	for i = 0, 4 do
		local a = (i + 0.5) / 5 * math.pi
		Kit.cyl(ctx, bay, "Columna", F1 - 1, 0.9, CF(B.X + math.cos(a) * (B.R - 0.8), (F1 - 1) / 2, B.Z + math.sin(a) * (B.R - 0.8)), TRIM, M.Metal, true)
	end
	local glow = Kit.neon(ctx, bay, "LuzMirador", V(2, 0.2, 2), CF(B.X, F1 - 1.15, B.Z + 4), C.Cyan, 0.3)
	Kit.light(ctx, glow, 16, 0.8, C.Cyan, nil, "Surface")
end

---------------------------------------------------------------------
-- Garaje por fuera (a la derecha, de una planta, abierto)
---------------------------------------------------------------------
local function garageShell(ctx: Kit.Ctx, m: Instance)
	local f = Kit.group(m, "GarajeFuera")
	local wall = { Color = STONE, Material = M.Slate, Name = "Wall", Frame = TRIM }
	local y1 = F1 - 0.5
	-- Frente: la boca abierta (puerta enrollada arriba); lateral con ventanas; fondo
	Kit.wall(ctx, f, "X", G.Z0, G.X0 - 0.5, G.X1, 0, y1, { Color = WOOD, Material = M.WoodPlanks, Name = "Wall", Openings = { op(G.X0 + 1.5, G.X1 - 1.5, F0, 11.5) } })
	Kit.wall(ctx, f, "Z", G.X0, G.Z0, G.Z1, 0, y1, { Color = wall.Color, Material = wall.Material, Name = "Wall", Frame = TRIM, Openings = { op(-26, -16, 4, 10, "window"), op(-4, 6, 4, 10, "window") } })
	Kit.wall(ctx, f, "X", G.Z1, G.X0 - 0.5, G.X1, 0, y1, { Color = wall.Color, Material = wall.Material, Name = "Wall" })
	slats(ctx, f, "X", G.Z0, -1, G.X0, G.X1, 11.6, y1)
	-- Marco oscuro de la boca, persiana enrollada y tira de luz azul que bordea la boca
	local mouth0, mouth1 = G.X0 + 1.5, G.X1 - 1.5
	local mid = (mouth0 + mouth1) / 2
	Kit.deco(ctx, f, "MarcoPuerta", V(mouth1 - mouth0 + 1.2, 0.8, 1.4), CF(mid, 11.9, G.Z0 - 0.2), TRIM, M.Metal, nil, true)
	for _, x in { mouth0 - 0.3, mouth1 + 0.3 } do
		Kit.deco(ctx, f, "MarcoPuerta", V(0.6, 11, 1.4), CF(x, 6.5, G.Z0 - 0.2), TRIM, M.Metal, nil, true)
		local side = Kit.neon(ctx, f, "TiraNeon", V(0.2, 10.4, 0.2), CF(x + (if x < mid then 0.45 else -0.45), 6.5, G.Z0 - 0.95), C.Cyan, 0.05)
		local _ = side
	end
	Kit.deco(ctx, f, "Persiana", V(mouth1 - mouth0, 1.4, 1.2), CF(mid, 11, G.Z0 + 1), rgb(200, 202, 206), M.Metal, nil, true)
	local strip = Kit.neon(ctx, f, "TiraNeon", V(mouth1 - mouth0, 0.2, 0.2), CF(mid, 11.4, G.Z0 - 0.95), C.Cyan, 0.05)
	Kit.light(ctx, strip, 16, 1.2, C.Cyan, nil, "Surface")
	-- Número de la casa (sin rótulos de taller: es la casa de Cosme)
	local num = Kit.deco(ctx, f, "NumeroCasa", V(2.4, 1.4, 0.2), CF(mouth0 - 2.2, 8.5, G.Z0 - 0.75), TRIM, M.Metal, nil, true)
	Kit.signText(num, "66", Enum.NormalId.Front, rgb(255, 220, 150), TRIM)
	-- Cornisa con vuelo y barandilla de cristal del tejado (terraza lateral)
	eave(ctx, f, "X", G.Z0, -1, G.X0 - 1.5, G.X1, F1 - 0.2, 2.2, 1.6)
	eave(ctx, f, "Z", G.X0, -1, G.Z0 - 1, G.Z1 + 1, F1 - 0.2, 2.2, 1.6)
	eave(ctx, f, "X", G.Z1, 1, G.X0 - 1.5, G.X1, F1 - 0.2, 2.2, 1.6)
	Kit.railing(ctx, f, V(G.X0 + 0.4, F1, G.Z0 + 0.4), V(G.X0 + 0.4, F1, G.Z1 - 0.4))
	Kit.railing(ctx, f, V(G.X0 + 0.4, F1, G.Z1 - 0.4), V(G.X1 - 0.2, F1, G.Z1 - 0.4))
	vines(ctx, f, "Z", G.X0, -1, G.Z0, G.Z1, F1 + 0.2, 12)
	-- Placas solares en la mitad de atrás del tejado del garaje (filas inclinadas)
	local solar = Kit.group(f, "PlacasSolares")
	for row = 0, 2 do
		for col = 0, 2 do
			local x, z = G.X0 + 4.5 + col * 6.6, -3 + row * 5.2
			local base = CF(x, F1, z)
			Kit.deco(ctx, solar, "Pata", V(0.3, 1.9, 0.3), base * CF(0, 0.95, 1.7), C.Steel, M.Metal, nil, true)
			Kit.deco(ctx, solar, "Pata", V(0.3, 0.7, 0.3), base * CF(0, 0.35, -1.7), C.Steel, M.Metal, nil, true)
			local tilt = base * CF(0, 1.15, 0) * ANG(math.rad(-18), 0, 0)
			local panel = Kit.deco(ctx, solar, "PlacaSolar", V(6.2, 0.25, 4.2), tilt, rgb(24, 40, 92), M.Glass, nil, true)
			panel.Reflectance = 0.3
			for k = 1, 3 do
				Kit.deco(ctx, solar, "Celda", V(0.08, 0.27, 4), tilt * CF(-3.1 + k * 1.55, 0, 0), rgb(150, 160, 180), M.Metal)
			end
		end
	end
	-- Terraza lateral (delante, en el tejado del garaje): sillas, mesa y plantas
	local lat = Kit.group(f, "TerrazaLateral")
	local lf = Kit.furn(ctx, lat, rgb(150, 104, 68), rgb(220, 214, 200), C.Cyan)
	Furniture.bench(lf, Kit.at(ctx, -40, F1, -20, -90), 6, rgb(150, 104, 68), lat)
	Kit.cyl(ctx, lat, "Mesita", 2.6, 2.4, CF(-36, F1 + 1.3, -20), C.White, M.Metal, true)
	for _, z in { -27, -12 } do
		planter(ctx, lat, -41.6, F1, z, 1.6, 4.4)
	end
	Props.make(ctx, lat, "Plant", CF(-26, F1, -8))
	Props.make(ctx, lat, "Plant", CF(-25, F1, -29))
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
		local post = i % 4 == 0
		Kit.box(ctx, m, if post then "Poste" else "Tabla", V(if post then 0.6 else 0.15, h + (if post then 0.4 else 0), 0.8), CF(p.X, (h + (if post then 0.4 else 0)) / 2, p.Z) * ANG(0, yaw, 0), rgb(150, 104, 68), M.WoodPlanks, { CanQuery = false })
		if not post then
			-- Punta de la tabla (valla de estacas)
			Kit.wedge(ctx, m, "Punta", V(0.15, 0.4, 0.4), CF(p.X, h + 0.2, p.Z) * ANG(0, yaw, 0) * CF(0, 0, 0.2), rgb(150, 104, 68), M.WoodPlanks)
		end
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
Exterior.flowers = flowers

local function bush(ctx: Kit.Ctx, parent: Instance, x: number, z: number, s: number?)
	local size = s or 3
	Kit.ellipsoid(ctx, parent, "Arbusto", V(size, size * 0.8, size), CF(x, size * 0.4, z), LEAF:Lerp(rgb(100, 150, 70), ctx.Rand.next()), M.LeafyGrass)
end
Exterior.bush = bush

-- Árbol frondoso (tronco con ramas y una copa de muchas bolas)
local function tree(ctx: Kit.Ctx, parent: Instance, x: number, z: number, h: number?)
	local m = Kit.group(parent, "Arbol")
	local height = h or 16
	local R = ctx.Rand
	Kit.cyl(ctx, m, "Tronco", height * 0.62, 1.8, CF(x, height * 0.31, z), rgb(104, 76, 50), M.Wood, true)
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2 + 0.4
		Kit.deco(ctx, m, "Rama", V(0.7, height * 0.3, 0.7), CF(x + math.cos(a) * 1.4, height * 0.62, z + math.sin(a) * 1.4) * ANG(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5), rgb(104, 76, 50), M.Wood, nil, true)
	end
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2
		local r = if i % 2 == 0 then 4 else 2.4
		local leaves = Kit.ball(ctx, m, "Copa", R.range(6, 9), CF(x + math.cos(a) * r, height * 0.72 + R.range(-1.5, 2.5), z + math.sin(a) * r), rgb(64, 132, 52):Lerp(rgb(116, 176, 72), R.next()), M.LeafyGrass)
		if i > 5 then
			leaves:AddTag("LeafDetail")
		end
	end
	Kit.ball(ctx, m, "Copa", 10, CF(x, height * 0.86, z), rgb(80, 150, 64), M.LeafyGrass)
	return m
end
Exterior.tree = tree

local function frontYard(ctx: Kit.Ctx, m: Instance)
	local y = Kit.group(m, "JardinDelantero")
	-- Camino de la calle a la puerta (losas) y vado del garaje
	Kit.box(ctx, y, "Camino", V(7, 0.2, 10), CF(-3, 0.1, -44), rgb(206, 196, 178), M.Pavement)
	Kit.box(ctx, y, "Vado", V(G.X1 - G.X0, 0.15, 17), CF((G.X0 + G.X1) / 2, 0.075, -40.5), rgb(176, 174, 170), M.Concrete)
	for i = 0, 3 do
		Kit.deco(ctx, y, "Losa", V(2.4, 0.06, 1.6), CF(-3 + (if i % 2 == 0 then -1.5 else 1.5), 0.23, -48 + i * 2.6), rgb(180, 172, 160), M.Slate)
	end
	-- Porche: tarima, escalones, marquesina con columnas y luces
	local porch = Kit.group(y, "Porche")
	Kit.box(ctx, porch, "Tarima", V(12, 1, 5.5), CF(-3, 0.5, -34.75), DECK, M.WoodPlanks, { CanQuery = true })
	Kit.box(ctx, porch, "Escalon", V(8, 0.5, 1.5), CF(-3, 0.25, -38.25), rgb(180, 172, 160), M.Slate)
	for _, x in { -8.5, 2.5 } do
		Kit.box(ctx, porch, "Columna", V(0.8, 10, 0.8), CF(x, 6, -37), TRIM, M.Metal)
	end
	Kit.box(ctx, porch, "Marquesina", V(14, 0.6, 6.5), CF(-3, 11.3, -35.25), TRIM, M.Metal)
	for _, x in { -6, 0 } do
		local spot = Kit.neon(ctx, porch, "Foco", V(0.8, 0.1, 0.8), CF(x, 10.95, -35), rgb(255, 230, 190))
		Kit.light(ctx, spot, 14, 1.2, rgb(255, 226, 180), nil, "Spot")
	end
	Kit.deco(ctx, porch, "Felpudo", V(5, 0.06, 2.4), CF(-3, 1.03, -33.4), rgb(90, 60, 40), M.Fabric, nil, true)
	local mat = Kit.deco(ctx, porch, "FelpudoTexto", V(4.6, 0.02, 2), CF(-3, 1.07, -33.4), rgb(90, 60, 40), M.Fabric, nil, true)
	Builder.sign(mat, "¿VIENES DEL FUTURO?", Enum.NormalId.Top, rgb(240, 220, 160), rgb(90, 60, 40))
	-- Plantas grandes en macetas a los lados de la puerta
	for _, x in { -8, 2 } do
		Props.make(ctx, porch, "Plant", CF(x, 1, -33.2))
	end
	-- Puerta principal grande (se abre)
	Kit.door(ctx, y, -3, F0, H.Z0, 180, 7, 9.5, rgb(64, 46, 34), false)
	-- Valla de madera de estacas (con hueco para el camino y el vado) y los lados
	fence(ctx, y, V(49.5, 0, -49), V(0.5, 0, -49))
	fence(ctx, y, V(-6.5, 0, -49), V(G.X1 + 0.5, 0, -49))
	fence(ctx, y, V(49.5, 0, -49), V(49.5, 0, -14))
	fence(ctx, y, V(-49.5, 0, -49), V(-49.5, 0, -36))
	fence(ctx, y, V(G.X0 - 0.5, 0, -49), V(-49.5, 0, -49))
	-- Farola de la acera (a la izquierda, como en el render)
	local lamp = Kit.group(y, "Farola")
	Kit.cyl(ctx, lamp, "Base", 0.8, 1.4, CF(46, 0.4, -47.5), TRIM, M.Metal, true)
	Kit.cyl(ctx, lamp, "Poste", 15, 0.6, CF(46, 8, -47.5), TRIM, M.Metal, true)
	Kit.deco(ctx, lamp, "Brazo", V(0.4, 0.4, 3.6), CF(46, 15.3, -46), TRIM, M.Metal, nil, true)
	Kit.deco(ctx, lamp, "Cabeza", V(1.6, 0.6, 2.4), CF(46, 15.1, -44.6), TRIM, M.Metal, nil, true)
	local bulb = Kit.neon(ctx, lamp, "Luz", V(1.2, 0.15, 2), CF(46, 14.75, -44.6), rgb(255, 236, 200))
	Kit.light(ctx, bulb, 30, 1.4, rgb(255, 230, 190), nil, "Spot")
	-- Buzón y, al lado, un robot pequeño de pie (como en el render)
	local mailbox = Kit.group(y, "Buzon")
	Kit.box(ctx, mailbox, "Pie", V(0.6, 2.6, 0.6), CF(-9.5, 1.3, -42.5), TRIM, M.Metal)
	Kit.box(ctx, mailbox, "Cuerpo", V(2.2, 1.6, 2.6), CF(-9.5, 3.4, -42.5), rgb(220, 222, 226), M.Metal)
	Kit.cylX(ctx, mailbox, "Tapa", 2.6, 2.2, CF(-9.5, 4.2, -42.5) * ANG(0, math.pi / 2, 0), rgb(220, 222, 226), M.Metal)
	Kit.deco(ctx, mailbox, "Bandera", V(0.1, 1, 0.5), CF(-8.3, 4.6, -42.1), C.Red, nil, nil, true)
	local mtext = Kit.deco(ctx, mailbox, "Nombre", V(1.6, 0.5, 0.05), CF(-9.5, 3.3, -43.82), TRIM, nil, nil, true)
	Kit.signText(mtext, "COSME", Enum.NormalId.Front, rgb(255, 220, 150), TRIM)
	Kit.doc(mailbox:FindFirstChild("Cuerpo") :: BasePart, "Carta en el buzón", "«Estimado vecino Cosme: le rogamos que deje de abrir portales en el jardín. Firmado: la comunidad de vecinos.»\n\nDebajo, escrito a lápiz: «Las coordenadas del sábado son 66-B. Que no se entere el pez.»", "CosmeBuzon")
	local bot = Kit.group(y, "RobotBuzon")
	Kit.box(ctx, bot, "Piernas", V(1.2, 1.4, 0.8), CF(-12.5, 0.7, -42.5), rgb(200, 204, 212), M.Metal)
	Kit.box(ctx, bot, "Cuerpo", V(1.8, 1.6, 1.2), CF(-12.5, 2.2, -42.5), rgb(232, 234, 238), M.SmoothPlastic)
	Kit.box(ctx, bot, "Cabeza", V(1.6, 1.2, 1.2), CF(-12.5, 3.6, -42.5), rgb(232, 234, 238), M.SmoothPlastic)
	Kit.neon(ctx, bot, "Ojos", V(1.1, 0.25, 0.05), CF(-12.5, 3.7, -43.12), C.Cyan)
	Kit.deco(ctx, bot, "Antena", V(0.08, 0.8, 0.08), CF(-12.5, 4.6, -42.5), TRIM)
	Kit.ball(ctx, bot, "Punta", 0.3, CF(-12.5, 5.05, -42.5), C.Red, M.Neon)
	for _, s in { -1, 1 } do
		Kit.deco(ctx, bot, "Brazo", V(0.35, 1.3, 0.35), CF(-12.5 + s * 1.1, 2.1, -42.5), rgb(200, 204, 212), M.Metal)
	end
	-- Cartel «NO ENTRAR»: tablón de madera con la placa roja y su triángulo de peligro (a la derecha)
	local board = Kit.group(y, "CartelNoEntrar")
	for _, x in { -48.5, -45.5 } do
		Kit.box(ctx, board, "Poste", V(0.6, 7, 0.6), CF(x, 3.5, -38), rgb(110, 78, 50), M.Wood)
	end
	local panel = Kit.box(ctx, board, "Tablero", V(5, 4.4, 0.4), CF(-47, 4.4, -38.2), rgb(150, 104, 68), M.WoodPlanks)
	for k = 0, 3 do
		Kit.deco(ctx, board, "Tabla", V(5, 0.08, 0.05), CF(-47, 2.5 + k * 1.1, -38.42), rgb(110, 78, 50), M.Wood)
	end
	local red = Kit.deco(ctx, board, "Cartel", V(3.8, 1.8, 0.1), CF(-47, 5.2, -38.45), rgb(200, 36, 36), M.SmoothPlastic, nil, true)
	Kit.signText(red, "NO ENTRAR", Enum.NormalId.Front, rgb(255, 255, 255), rgb(200, 36, 36))
	local warn = Kit.deco(ctx, board, "Peligro", V(1.4, 1.2, 0.1), CF(-47, 3.3, -38.45), rgb(250, 210, 50), M.SmoothPlastic, nil, true)
	Kit.signText(warn, "⚠", Enum.NormalId.Front, rgb(30, 30, 30), rgb(250, 210, 50))
	Kit.doc(panel, "Cartel «NO ENTRAR»", "NO ENTRAR. Peligro: portales, rayos, gallinas gigantes y matemáticas avanzadas.\n\n(Letra pequeña: «Si eres mi vecino, sí puedes entrar. Trae batido de apio.»)")
	-- Caja «NO TOCAR», máquina medio desmontada, antena pequeña y cables
	local box = Kit.box(ctx, y, "CajaNoTocar", V(2.4, 2, 2.4), CF(12, 1, -40), rgb(230, 190, 50), M.Metal)
	local label = Kit.deco(ctx, y, "Etiqueta", V(2, 0.8, 0.05), CF(12, 1.2, -41.25), rgb(30, 30, 30), nil, nil, true)
	Kit.signText(label, "NO TOCAR", Enum.NormalId.Front, rgb(255, 220, 60), rgb(30, 30, 30))
	Kit.prompt(box, "Tocar", "📦 Caja «NO TOCAR»", "Experiment", { Effect = "Zap", Text = "¡ZAS! Un chispazo te pone el pelo de punta. Ahora entiendes el peinado de Cosme." })
	local machine = Kit.group(y, "MaquinaDesmontada")
	Kit.box(ctx, machine, "Carcasa", V(4, 3, 3), CF(20, 1.5, -41), rgb(120, 126, 136), M.Metal)
	Kit.box(ctx, machine, "Tapa", V(4.2, 0.3, 3.2), CF(20, 3.6, -39.4) * ANG(-0.9, 0, 0), rgb(120, 126, 136), M.Metal)
	Kit.cyl(ctx, machine, "Engranaje", 0.4, 2, CF(22.6, 0.2, -42), rgb(200, 150, 60), M.Metal)
	Props.make(ctx, machine, "Pile", CF(17.5, 0, -43.5))
	Props.make(ctx, machine, "CableRun", CF(22, 0, -38.5))
	Kit.neon(ctx, machine, "Testigo", V(0.4, 0.4, 0.1), CF(21, 2.2, -42.55), C.Orange)
	local antenna = Kit.group(y, "AntenaPequena")
	Kit.box(ctx, antenna, "Mastil", V(0.3, 7, 0.3), CF(-16, 3.5, -36), C.Steel, M.Metal)
	for i = 1, 3 do
		Kit.deco(ctx, antenna, "Varilla", V(2.6 - i * 0.5, 0.12, 0.12), CF(-16, 4 + i * 1, -36), C.Steel, M.Metal)
	end
	Kit.ball(ctx, antenna, "Luz", 0.4, CF(-16, 7.2, -36), C.Red, M.Neon)
	-- Árbol grande frondoso a la izquierda, arbustos, setos, flores y farolillos del camino
	tree(ctx, y, 40, -42, 20)
	for _, p in { { 30, -36 }, { 6, -36.5 }, { 9, -36.5 }, { -14, -36.5 }, { -19, -36.5 }, { 47, -30 }, { 47, -22 }, { 33, -47 } } do
		bush(ctx, y, p[1], p[2], 3.2)
	end
	-- Seto bajo bajo los ventanales del salón
	for i = 0, 8 do
		Kit.ellipsoid(ctx, y, "Seto", V(3.4, 1.8, 2), CF(8 + i * 3.4, 0.9, -33.8), LEAF:Lerp(rgb(96, 150, 66), (i % 3) / 3), M.LeafyGrass)
	end
	flowers(ctx, y, 24, 36, -47, -40, 18)
	flowers(ctx, y, 4, 10, -47, -41, 12)
	flowers(ctx, y, -20, -12, -36, -34, 8)
	for _, p in { { -7, -40 }, { 1, -40 }, { -7, -46 }, { 1, -46 } } do
		local l = Kit.group(y, "Farolillo")
		Kit.box(ctx, l, "Poste", V(0.35, 2.2, 0.35), CF(p[1], 1.1, p[2]), TRIM, M.Metal)
		local b = Kit.neon(ctx, l, "Luz", V(0.6, 0.6, 0.6), CF(p[1], 2.5, p[2]), rgb(255, 230, 180))
		if p[2] == -40 then
			Kit.light(ctx, b, 10, 0.8, rgb(255, 226, 180))
		end
	end
	Props.make(ctx, y, "CableRun", CF(-14, 0, -34))
	Kit.robot(ctx, y, -2, 0.2, -44, "Limpiador", { { -2, -44 }, { -4, -40 }, { -2, -39 }, { -1, -46 } }, 2)
end

---------------------------------------------------------------------
-- Terraza trasera, jardín trasero y terraza-jardín lateral
---------------------------------------------------------------------
local function backGarden(ctx: Kit.Ctx, m: Instance)
	local g = Kit.group(m, "JardinTrasero")
	local D = Layout.Deck
	-- En la terraza: barbacoa, tumbonas, macetas y luces
	local furn = Kit.furn(ctx, g, rgb(120, 84, 56), rgb(220, 220, 210), C.Orange)
	for _, x in { 34, 37.5 } do
		local lounger = Kit.group(g, "Tumbona")
		Kit.box(ctx, lounger, "Base", V(2.6, 1, 6), CF(x, 1.5, 28), C.White, M.SmoothPlastic)
		Kit.box(ctx, lounger, "Respaldo", V(2.6, 2.6, 0.5), CF(x, 2.8, 25.4) * ANG(math.rad(-25), 0, 0), C.White, M.SmoothPlastic)
		Furniture.usable(Furniture.seatPart(lounger, Kit.at(ctx, x, 2.2, 28)), "Sit")
	end
	local bbq = Kit.group(g, "Barbacoa")
	Kit.box(ctx, bbq, "Mueble", V(5, 3, 2.4), CF(14, 2.5, 29.6), rgb(80, 84, 92), M.Brick)
	Kit.box(ctx, bbq, "Parrilla", V(3, 0.2, 1.8), CF(13.5, 4.1, 29.6), C.Dark, M.DiamondPlate)
	local coals = Kit.neon(ctx, bbq, "Brasas", V(2.6, 0.1, 1.4), CF(13.5, 4.05, 29.6), C.Orange, 0.2)
	Kit.fx(coals, "Steam", 5)
	Kit.box(ctx, bbq, "Chimenea", V(0.8, 4, 0.8), CF(15.8, 6, 30.2), C.Dark, M.Metal)
	Props.make(ctx, bbq, "Food", CF(11.9, 4, 29.5))
	for i = 0, 4 do
		Props.make(ctx, g, "Plant", CF(D.X0 + 2 + i * 6, 1, D.Z1 - 1))
	end
	-- Árboles, setos, flores, bancos y un camino de losas
	tree(ctx, g, -40, 42, 17)
	tree(ctx, g, 42, 44, 15)
	tree(ctx, g, 4, 46, 14)
	for _, p in { { -46, 36 }, { 30, 47 }, { 47, 30 }, { 47, 20 }, { -20, 47 }, { 47, 0 }, { 47, 10 } } do
		bush(ctx, g, p[1], p[2], 3.4)
	end
	flowers(ctx, g, 24, 40, 33, 37, 22)
	flowers(ctx, g, -20, -8, 40, 46, 14)
	Furniture.bench(furn, Kit.at(ctx, 30, 0, 42.5, 0), 5, rgb(120, 84, 56), g)
	for i = 0, 8 do
		Kit.deco(ctx, g, "Losa", V(2.6, 0.06, 2), CF(-12 + i * 4, 0.03, 36 + math.sin(i) * 1.5), rgb(190, 180, 166), M.Slate)
	end
	-- Tubos que salen del suelo (vienen del sótano) y la máquina enterrada
	local tubes = Kit.group(g, "Tubos")
	for i, p in ipairs({ { -18, 38 }, { -14, 42 }, { 36, 40 }, { 44, 36 } }) do
		local h = 2 + (i % 3)
		Kit.cyl(ctx, tubes, "Tubo", h, 0.8, CF(p[1], h / 2, p[2]), rgb(120, 126, 136), M.Metal, true)
		Kit.cylX(ctx, tubes, "Codo", 1.6, 0.8, CF(p[1] + 0.6, h, p[2]), rgb(120, 126, 136), M.Metal)
		local vent = Kit.neon(ctx, tubes, "Respiradero", V(0.5, 0.5, 0.5), CF(p[1] + 1.4, h, p[2]), C.Green, 0.3)
		Kit.fx(vent, "Steam", 3)
	end
	local buried = Kit.group(g, "MaquinaEnterrada")
	Kit.box(ctx, buried, "Monticulo", V(8, 1.2, 6), CF(-30, 0.6, 42), rgb(110, 90, 60), M.Ground)
	Kit.box(ctx, buried, "Carcasa", V(5, 2.4, 3), CF(-30, 1.4, 42) * ANG(0, 0, 0.25), rgb(150, 110, 60), M.CorrodedMetal)
	Kit.cylX(ctx, buried, "Rueda", 0.6, 3, CF(-27.8, 2.2, 43.6) * ANG(0, math.pi / 2, 0), rgb(120, 90, 50), M.CorrodedMetal)
	local led = Kit.neon(ctx, buried, "Luz", V(0.4, 0.4, 0.1), CF(-29, 2.3, 40.4), C.Green)
	Kit.light(ctx, led, 8, 0.6, C.Green)
	Kit.doc(buried:FindFirstChild("Carcasa") :: BasePart, "Placa oxidada", "«PROTOTIPO 0 — EXCAVADORA TEMPORAL. Enterrada en el futuro, desenterrada en el pasado. No intentar arrancar en martes.»", "CosmeMaquinaEnterrada")
	-- El experimento «que no debería estar ahí»: una roca que flota sobre un cristal que zumba
	local exp = Kit.group(g, "ExperimentoFlotante")
	Kit.box(ctx, exp, "Pedestal", V(3, 1.2, 3), CF(-2, 0.6, 40), rgb(80, 84, 96), M.Slate)
	local crystal = Kit.neon(ctx, exp, "Cristal", V(1.2, 2.6, 1.2), CF(-2, 2.5, 40) * ANG(0, 0.6, 0), C.Magenta, 0.15)
	local rock = Kit.ball(ctx, exp, "RocaFlotante", 2.8, CF(-2, 6.4, 40), rgb(110, 100, 120), M.Basalt)
	Kit.anomaly(rock)
	Kit.spin(rock, 0.05, "Y")
	Kit.fx(crystal, "Energy", 10)
	Kit.light(ctx, crystal, 12, 1.2, C.Magenta)
	Kit.beam(crystal, rock, C.Magenta, 0.25)
	Kit.prompt(crystal, "Tocar el cristal", "💎 Experimento raro", "Experiment", { Effect = "Float", Text = "La roca da media vuelta en el aire y te saluda. Las rocas no saludan. Esta sí." })
	-- Valla del jardín trasero (madera) por los tres lados
	fence(ctx, g, V(-49.5, 0, -36), V(-49.5, 0, 49.5))
	fence(ctx, g, V(-49.5, 0, 49.5), V(49.5, 0, 49.5))
	fence(ctx, g, V(49.5, 0, 49.5), V(49.5, 0, -14))
	-- Robot jardinero que cuida las flores y luciérnagas por la noche
	Kit.robot(ctx, g, 30, 0, 36, "Jardinero", { { 30, 36 }, { 40, 34 }, { 40, 38 }, { 24, 38 } }, 1.6)
	local ff = Kit.neon(ctx, g, "Luciernagas", V(1, 1, 1), CF(-10, 0.5, 42), rgb(255, 250, 160), 1)
	Kit.fx(ff, "Fireflies", 4)

	-- Terraza-jardín lateral (detrás del garaje): mesa con sombrilla, plantas y el observatorio pequeño
	local side = Kit.group(m, "JardinLateral")
	Kit.box(ctx, side, "Tarima", V(14, 0.4, 10), CF(-40, 0.2, 18), DECK, M.WoodPlanks, { CanQuery = true })
	local sf = Kit.furn(ctx, side, rgb(60, 60, 66), rgb(230, 226, 214), C.Orange)
	Kit.cyl(ctx, side, "Mesa", 0.3, 4.2, CF(-40, 3.1, 18), C.White, M.SmoothPlastic, true)
	Kit.cyl(ctx, side, "PieMesa", 2.7, 0.5, CF(-40, 1.75, 18), TRIM, M.Metal, true)
	for _, p in { { -42.8, 18, -90 }, { -37.2, 18, 90 }, { -40, 15.2, 0 } } do
		Furniture.chair(sf, Kit.at(ctx, p[1], 0.4, p[2], p[3]), rgb(60, 60, 66), side)
	end
	local umbrella = Kit.group(side, "Sombrilla")
	Kit.cyl(ctx, umbrella, "Palo", 9, 0.3, CF(-40, 4.9, 18), C.White, M.Metal, true)
	local cloth = Kit.ellipsoid(ctx, umbrella, "Lona", V(10, 1.6, 10), CF(-40, 9.2, 18), rgb(40, 130, 110), M.Fabric)
	cloth.CastShadow = true
	Props.make(ctx, side, "Mug", CF(-39.4, 3.25, 17.6))
	-- Observatorio pequeño (garita redonda con cúpula y telescopio asomando)
	local obs = Kit.group(side, "ObservatorioPequeno")
	Kit.cyl(ctx, obs, "Garita", 5, 4.6, CF(-44, 2.5, 28), rgb(220, 224, 230), M.SmoothPlastic, true)
	Kit.ellipsoid(ctx, obs, "Cupula", V(5, 3.6, 5), CF(-44, 5, 28), rgb(120, 170, 220), M.Glass, 0.3)
	Kit.cyl(ctx, obs, "Aro", 0.4, 5.2, CF(-44, 5, 28), TRIM, M.Metal, true)
	Kit.cylX(ctx, obs, "Telescopio", 3.4, 0.7, CF(-43, 6.2, 27.4) * ANG(0, 0.4, 0.7), rgb(236, 236, 240), M.SmoothPlastic)
	for _, p in { { -28, 28 }, { -48, 22 }, { -30, 14 } } do
		Props.make(ctx, side, "Plant", CF(p[1], 0, p[2]))
	end
	flowers(ctx, side, -36, -26, 26, 30, 10)
	bush(ctx, side, -48, 30, 3)
end

function Exterior.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "Exterior")
	ground(ctx, m)
	facades(ctx, m)
	garageShell(ctx, m)
	frontYard(ctx, m)
	backGarden(ctx, m)
	return m
end

-- Al arrancar el servidor (World/TerrainBuilder): se vacía el terreno donde va el sótano
function Exterior.terrain(terrain: Terrain, site: CFrame)
	local B = Layout.Basement
	local size = Vector3.new(B.X1 - B.X0 + 8, 30, B.Z1 - B.Z0 + 8)
	local center = site * CFrame.new((B.X0 + B.X1) / 2, -9, (B.Z0 + B.Z1) / 2)
	terrain:FillBlock(center, size, Enum.Material.Air)
end

return Exterior
