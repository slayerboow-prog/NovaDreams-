-- Observatory: la torre redonda acristalada, el ático y la azotea de Cosme (docs/historia/casa-cosme.md,
-- puntos 7 y 18; en la imagen, la torre con la cúpula y la antena parabólica).
--
--   * Torre: paredes de cristal en las tres plantas (despacho, biblioteca y observatorio) y cúpula de
--     gajos de cristal con una rendija; dentro, un telescopio enorme que el jugador usa (aviso
--     «Telescope»: el cliente pone la cámara en el ocular y mira al cielo o a la ciudad).
--   * Ático acristalado (centro de control): mesas con pantallas de mapas estelares, coordenadas y
--     anomalías, radio, globo holográfico, la llegada de la escalera principal y salida a la azotea.
--   * Azotea: antena parabólica, antenas, un satélite de prueba y la máquina experimental (el
--     «resonador lunar», que gira y se enciende).

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local Furniture = require(script.Parent.Parent.Furniture)

local Observatory = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local T = Layout.Tower
local H = Layout.House
local F2 = Layout.F2
local TOP = Layout.CEIL.A -- techo del ático y base de la cúpula

local STONE = rgb(198, 192, 182)
local RENDER = rgb(240, 238, 232)
local TRIM = rgb(46, 48, 56)

local function skip(theta: number): boolean
	return T.X + T.R * math.cos(theta) > H.X0 - 0.4
end

-- Torre: tres plantas de paredes con cristaleras y la cúpula
local function tower(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Torre")
	Kit.ringWall(ctx, m, T.X, T.Z, T.R, 0, 15.5, { Skip = skip, Window = { Bottom = 3, Top = 13 }, Color = STONE, Material = M.Concrete, Frame = TRIM, Name = "TorreBaja" })
	Kit.ringWall(ctx, m, T.X, T.Z, T.R, 15.5, 30.5, { Skip = skip, Window = { Bottom = 17.5, Top = 28.5 }, Color = RENDER, Material = M.Plaster, Frame = TRIM, Name = "TorreAlta" })
	Kit.ringWall(ctx, m, T.X, T.Z, T.R, 30.5, TOP, { Skip = skip, Window = { Bottom = 31.6, Top = TOP - 0.4 }, Color = TRIM, Material = M.Metal, Frame = TRIM, Name = "TorreObservatorio", GlassTransparency = 0.6 })
	-- Bandas oscuras entre plantas (por fuera) y aro de la base de la cúpula
	for _, y in { 15.5, 30.5 } do
		local band = Kit.cyl(ctx, m, "Banda", 0.8, T.R * 2 + 1.4, CF(T.X, y, T.Z), TRIM, M.Metal)
		band.CanCollide = false
	end
	Kit.cyl(ctx, m, "AroCupula", 1, T.R * 2 + 1.6, CF(T.X, TOP + 0.5, T.Z), TRIM, M.Metal, true)
	local glowRing = Kit.cyl(ctx, m, "AroLuz", 0.3, T.R * 2 + 1.7, CF(T.X, TOP + 1.05, T.Z), C.Cyan, M.Neon)
	glowRing.CastShadow = false
	-- Cúpula: gajos de cristal en tres bandas, con una rendija para el telescopio (hacia fuera, -X)
	local dome = Kit.group(m, "Cupula")
	local n = 16
	local base = TOP + 1
	local bands = { { 0, 0.5 }, { 0.5, 1.0 }, { 1.0, 1.4 } }
	for b, band in bands do
		local phi = (band[1] + band[2]) / 2
		local rr = T.R * math.cos(phi)
		local h = T.R * (band[2] - band[1]) + 0.15
		for i = 0, n - 1 do
			local theta = (i + 0.5) / n * math.pi * 2
			local slit = (i == 7 or i == 8) and b >= 2
			if not slit then
				local pos = Vector3.new(T.X + rr * math.cos(theta), base + T.R * math.sin(phi), T.Z + rr * math.sin(theta))
				local tangent = Vector3.new(-math.sin(theta), 0, math.cos(theta))
				local meridian = Vector3.new(-math.sin(phi) * math.cos(theta), math.cos(phi), -math.sin(phi) * math.sin(theta))
				local cf = CFrame.fromMatrix(pos, tangent, meridian)
				local width = 2 * math.pi * T.R * math.cos(band[1]) / n + 0.1
				local glass = Kit.glass(ctx, dome, "GajoCupula", V(width, h, 0.25), cf, rgb(180, 220, 245), 0.45, false)
				glass.Name = "GajoCupula"
				Kit.deco(ctx, dome, "Nervio", V(0.25, h, 0.35), cf * CF(width / 2, 0, 0), TRIM, M.Metal, nil, true)
			end
		end
	end
	Kit.ball(ctx, dome, "Remate", 2, CF(T.X, base + T.R - 0.3, T.Z), TRIM, M.Metal)
	Kit.ball(ctx, dome, "LuzRemate", 0.7, CF(T.X, base + T.R + 0.8, T.Z), C.Red, M.Neon)
	-- Telescopio enorme (pilar, montura de horquilla y tubo hacia la rendija)
	local tele = Kit.group(m, "Telescopio")
	local tx, tz = T.X - 2.5, T.Z
	Kit.cyl(ctx, tele, "Pilar", 4, 2, CF(tx, F2 + 2, tz), rgb(60, 64, 76), M.Metal, true)
	Kit.box(ctx, tele, "Horquilla", V(0.6, 3, 3.6), CF(tx, F2 + 5.4, tz), rgb(200, 205, 215), M.Metal, { CanCollide = false })
	local aim = CF(tx, F2 + 6.4, tz) * ANG(0, 0, math.rad(-50)) -- inclinado hacia la rendija (-X y arriba)
	local tube = Kit.cylX(ctx, tele, "Tubo", 11, 2, aim * CF(-1.5, 0, 0), rgb(236, 236, 240), M.SmoothPlastic)
	tube.CanCollide = false
	Kit.cylX(ctx, tele, "Boca", 0.6, 2.4, aim * CF(-7.2, 0, 0), C.Dark, M.Metal)
	Kit.cylX(ctx, tele, "Lente", 0.1, 1.9, aim * CF(-7.55, 0, 0), rgb(120, 200, 255), M.Glass, 0.3)
	Kit.cylX(ctx, tele, "Buscador", 2.6, 0.5, aim * CF(-2, 1.3, 0), C.Dark, M.Metal)
	local eye = Kit.cylX(ctx, tele, "Ocular", 0.9, 0.5, aim * CF(4.4, -0.3, 0), C.Dark, M.Metal)
	for k = 0, 2 do
		Kit.neon(ctx, tele, "Anillo", V(0.15, 2.05, 2.05), aim * CF(-5 + k * 2.6, 0, 0), C.Cyan, 0.4).Shape = Enum.PartType.Cylinder
	end
	local prompt = Kit.prompt(eye, "Mirar por el telescopio", "🔭 Telescopio", "Telescope", { PropId = "CosmeTelescopio" })
	prompt.MaxActivationDistance = 10
	prompt:SetAttribute("Aim", Kit.world(ctx, aim * ANG(0, math.pi / 2, 0)))
	-- Mapas estelares y una silla para mirar
	Furniture.officeChair(Kit.furn(ctx, m), Kit.at(ctx, T.X + 3.2, F2, T.Z + 3.2, 225), rgb(30, 30, 34), m)
	for i = 0, 1 do
		local a = math.rad(213.75 + i * 22.5)
		local x, z = T.X + math.cos(a) * 8.75, T.Z + math.sin(a) * 8.75
		Kit.wallScreen(ctx, m, CF(x, F2 + 2.6, z) * ANG(0, math.pi / 2 - a, 0), 2.6, 1.6, "Stars")
	end
	Props.scatter(ctx, m, { T.X - 4, T.X + 4, T.Z + 4, T.Z + 6 }, F2, 3, { "Book", "Papers", "Blueprint" })
	return m
end

---------------------------------------------------------------------
-- Ático acristalado (centro de control)
---------------------------------------------------------------------
local function op(a: number, b: number, bottom: number, top: number, kind: string?): Kit.Opening
	return { A = a, B = b, Bottom = bottom, Top = top, Kind = kind }
end

local function attic(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Atico")
	local glass = { Color = TRIM, Material = M.Metal, Name = "Wall", Frame = TRIM, GlassTransparency = 0.6 }
	local function with(openings: { Kit.Opening }): any
		local o = table.clone(glass)
		o.Openings = openings
		return o
	end
	local tz0, tz1 = T.Z - math.sqrt(T.R ^ 2 - (H.X0 - T.X) ^ 2), T.Z + math.sqrt(T.R ^ 2 - (H.X0 - T.X) ^ 2)
	Kit.wall(ctx, m, "X", H.Z0, H.X0 - 0.5, 0.5, F2 - 0.5, TOP, with({ op(-33.5, -0.5, F2 + 0.6, TOP - 0.6, "glass") }))
	Kit.wall(ctx, m, "Z", H.X0, H.Z0, -6, F2 - 0.5, TOP, with({ op(-31.5, tz0 - 0.2, F2 + 0.6, TOP - 0.6, "glass"), op(tz0, tz1, F2, TOP), op(tz1 + 0.2, -6.5, F2 + 0.6, TOP - 0.6, "glass") }))
	Kit.wall(ctx, m, "X", -6, H.X0 - 0.5, 0.5, F2 - 0.5, TOP, with({ op(-27, -21, F2, F2 + 9.5), op(-19, -1, F2 + 0.6, TOP - 0.6, "glass") }))
	Kit.wall(ctx, m, "Z", 0, H.Z0, -6, F2 - 0.5, TOP, with({ op(-31.5, -25.5, F2, F2 + 9.5), op(-24, -7, F2 + 0.6, TOP - 0.6, "glass") }))
	Kit.door(ctx, m, -24, F2, -6, 180, 6, 9.3, TRIM, true)
	Kit.door(ctx, m, 0, F2, -28.5, -90, 6, 9.3, TRIM, true)
	-- Techo con un lucernario sobre el hueco de la escalera
	local hole = require(script.Parent.Exterior).stairHole()
	local roofRect = { X0 = H.X0 - 0.5, X1 = 0.5, Z0 = H.Z0 - 0.5, Z1 = -5.5 }
	Kit.slab(ctx, m, "AticoTecho", roofRect, TOP + 1, 1, { hole }, TRIM, M.Metal)
	Kit.slab(ctx, m, "Ceiling", { X0 = H.X0, X1 = 0, Z0 = H.Z0, Z1 = -6 }, TOP, 0.1, { hole }, rgb(30, 34, 44), M.SmoothPlastic)
	Kit.glass(ctx, m, "Lucernario", V(hole.X1 - hole.X0, 0.3, hole.Z1 - hole.Z0), CF((hole.X0 + hole.X1) / 2, TOP + 0.8, (hole.Z0 + hole.Z1) / 2), rgb(190, 225, 245), 0.5, true)
	-- Barandillas del hueco de la escalera
	Kit.railing(ctx, m, V(-6, F2, -25.2), V(-0.4, F2, -25.2))
	Kit.railing(ctx, m, V(-12.2, F2, -25), V(-12.2, F2, -6.4))
	-- Luces
	for _, p in { { -26, -24 }, { -18, -12 }, { -30, -12 } } do
		Kit.ceilingLamp(ctx, m, p[1], TOP, p[2], "Control", "Ring", rgb(180, 220, 255))
	end
	Kit.switch(ctx, m, -27.8, F2 + 4, -6.6, 0, "Control")
	-- Mesas con pantallas (mapas estelares, coordenadas, anomalías) y sillas
	local f = Kit.furn(ctx, m)
	for _, d in { { -29, -10.8 }, { -16, -10.8 } } do
		local desk = Kit.box(ctx, m, "MesaControl", V(6, 0.3, 2.6), CF(d[1], F2 + 3, d[2]), rgb(30, 34, 44), M.Metal)
		Kit.box(ctx, m, "PieMesa", V(5.6, 2.85, 0.4), CF(d[1], F2 + 1.43, d[2] + 1), rgb(30, 34, 44), M.Metal)
		for k, kind in { "Stars", "Coords", "Anomalies" } do
			Kit.monitor(ctx, m, CF(d[1] - 4 + k * 2, F2 + 3.15, d[2] + 0.5), 1.8, 1.2, kind)
		end
		Furniture.officeChair(f, Kit.at(ctx, d[1], F2, d[2] - 2.6, 0), rgb(30, 30, 34), m)
		Props.scatter(ctx, m, { d[1] - 2.8, d[1] + 2.8, d[2] - 1.2, d[2] - 0.6 }, F2 + 3.15, 3, { "Mug", "Papers", "Keyboard", "Clipboard" })
		local _ = desk
	end
	local mainScreen = Kit.wallScreen(ctx, m, CF(-30.5, F2 + 7, -6.4), 6, 3.6, "Stars")
	Kit.prompt(mainScreen, "Mirar la pantalla", "🛰️ Centro de control", "Screen", { Title = "Centro de control", Text = "SATÉLITE «PIP-SAT»: en órbita (más o menos)\nANTENAS: escuchando la grieta\nMENSAJE CAPTADO ANOCHE: «…socio… la fusión… pronto…»\nRUTA A LA LUNA: 384.400 km · combustible: apio", PropId = "CosmeControl" })
	-- Globo holográfico que flota y radio de onda corta
	local holo = Kit.group(m, "GloboHolografico")
	Kit.cyl(ctx, holo, "Proyector", 1, 2.4, CF(-29, F2 + 0.5, -17), TRIM, M.Metal, true)
	local globe = Kit.ball(ctx, holo, "Holograma", 3.2, CF(-29, F2 + 4, -17), C.Cyan, M.ForceField, 0.2)
	Kit.anomaly(globe)
	Kit.spin(globe, 0.1, "Y")
	Kit.fx(globe, "Dust", 5)
	local radio = Kit.group(m, "Radio")
	Kit.box(ctx, radio, "Rack", V(3, 5, 2.4), CF(-32, F2 + 2.5, -30), rgb(60, 50, 40), M.Metal)
	for k = 0, 3 do
		Kit.neon(ctx, radio, "Dial", V(0.5, 0.5, 0.05), CF(-32.8 + k * 0.6, F2 + 3.6, -28.78), ({ C.Orange, C.Green, C.Orange, C.Red })[k + 1], 0.2)
	end
	Kit.prompt(radio:FindFirstChild("Rack") :: BasePart, "Escuchar la radio", "📻 Radio de onda corta", "Doc", { Title = "Radio de onda corta", Text = "Entre el ruido se oye una voz de presentador de concursos: «…y el premio de hoy es… ¡OTRA VALMAR!». Luego, aplausos enlatados. Cosme ha pegado un pósit: «NO CONTESTAR».", PropId = "CosmeRadio" })
	Props.scatter(ctx, m, { -33, -14, -24, -14 }, F2, 5, { "CableRun", "Book", "Papers" })
	return m
end

---------------------------------------------------------------------
-- Azotea: parabólica, antenas, satélite y máquina experimental
---------------------------------------------------------------------
local function roof(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Azotea")
	-- Antena parabólica grande (en la esquina de delante, sobre la sala de ordenadores)
	local dish = Kit.group(m, "Parabolica")
	Kit.box(ctx, dish, "Base", V(2.4, 1, 2.4), CF(9, F2 + 0.5, -23), TRIM, M.Metal)
	Kit.cyl(ctx, dish, "Mastil", 5, 0.6, CF(9, F2 + 3.5, -23), C.Steel, M.Metal, true)
	local aim = CF(9, F2 + 6.5, -23) * ANG(0, math.rad(30), 0) * ANG(math.rad(55), 0, 0)
	local plate = Kit.cylX(ctx, dish, "Plato", 0.4, 8, aim * ANG(0, math.pi / 2, 0), rgb(230, 232, 236), M.SmoothPlastic)
	plate.CastShadow = true
	Kit.cylX(ctx, dish, "Centro", 0.5, 2, aim * CF(0, 0, -0.3) * ANG(0, math.pi / 2, 0), rgb(200, 200, 205), M.Metal)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		Kit.deco(ctx, dish, "Brazo", V(0.15, 0.15, 4.4), aim * CF(math.cos(a) * 1.6, math.sin(a) * 1.6, -2.1) * ANG(math.sin(a) * 0.35, -math.cos(a) * 0.35, 0), C.Dark, M.Metal)
	end
	local rx = Kit.ball(ctx, dish, "Receptor", 0.8, aim * CF(0, 0, -4.2), C.Red, M.Neon)
	Kit.anomaly(rx)
	Kit.light(ctx, rx, 8, 0.6, C.Red)
	Kit.spin(dish, 0.02, "Y")
	dish:SetAttribute("SpinCenter", Kit.at(ctx, 9, F2 + 3.5, -23))
	Kit.anomaly(dish:FindFirstChild("Plato") :: Instance)
	-- Antenas en las esquinas
	for _, p in { { -32, 16 }, { 10, 16 }, { -32, -4 } } do
		local ant = Kit.group(m, "Antena")
		Kit.box(ctx, ant, "Mastil", V(0.4, 10, 0.4), CF(p[1], F2 + 5, p[2]), C.Steel, M.Metal)
		for k = 1, 4 do
			Kit.deco(ctx, ant, "Varilla", V(3 - k * 0.5, 0.15, 0.15), CF(p[1], F2 + 4 + k * 1.3, p[2]) * ANG(0, k * 0.4, 0), C.Steel, M.Metal)
		end
		Kit.ball(ctx, ant, "Luz", 0.5, CF(p[1], F2 + 10.2, p[2]), C.Red, M.Neon)
	end
	-- Satélite de prueba en su soporte
	local sat = Kit.group(m, "SatelitePrueba")
	Kit.box(ctx, sat, "Soporte", V(1, 3, 1), CF(-28, F2 + 1.5, 12), TRIM, M.Metal)
	Kit.box(ctx, sat, "Cuerpo", V(2, 2, 2), CF(-28, F2 + 4, 12), rgb(220, 180, 60), M.Foil)
	for _, s in { -1, 1 } do
		Kit.deco(ctx, sat, "Panel", V(3.2, 0.1, 1.6), CF(-28 + s * 2.6, F2 + 4, 12), rgb(30, 50, 110), M.Glass, nil, true)
	end
	Kit.doc(sat:FindFirstChild("Cuerpo") :: BasePart, "Satélite de prueba", "«PIP-SAT 2». El primero sigue dando vueltas a la Tierra. Este se queda aquí, por si acaso. Pip le habla por las noches.", "CosmeSatelite")
	-- La máquina experimental: el resonador lunar (gira y se enciende)
	local mach = Kit.group(m, "ResonadorLunar")
	local mx, mz = -8, 13
	Kit.cyl(ctx, mach, "Base", 1.4, 6, CF(mx, F2 + 0.7, mz), rgb(60, 64, 76), M.DiamondPlate, true)
	Kit.cyl(ctx, mach, "Columna", 5, 1.4, CF(mx, F2 + 3.9, mz), C.Steel, M.Metal, true)
	local spinner = Kit.group(mach, "Rotor")
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		Kit.deco(ctx, spinner, "Brazo", V(5, 0.4, 0.6), CF(mx, F2 + 6.6, mz) * ANG(0, a, 0) * CF(2.5, 0, 0), C.Chrome, M.Metal, nil, true)
		Kit.ball(ctx, spinner, "Esfera", 1.2, CF(mx, F2 + 6.6, mz) * ANG(0, a, 0) * CF(5.1, 0, 0), if k % 2 == 0 then C.Cyan else C.Magenta, M.Neon, 0.1)
	end
	Kit.spin(spinner, 0.15, "Y")
	spinner:SetAttribute("SpinCenter", Kit.at(ctx, mx, F2 + 6.6, mz))
	local top = Kit.ball(ctx, mach, "Cristal", 1.8, CF(mx, F2 + 7.4, mz), rgb(220, 240, 255), M.Neon, 0.1)
	Kit.light(ctx, top, 16, 1.2, rgb(200, 230, 255))
	Kit.fx(top, "Energy", 8)
	Kit.prompt(mach:FindFirstChild("Base") :: BasePart, "Encender el resonador", "🌕 Resonador lunar", "Machine", { Target = "ResonadorLunar", PropId = "CosmeResonador", Text = "El resonador apunta a la luna y zumba. Durante un segundo, la luna parece… más cerca. Muy poco. Pero más cerca." })
	-- Depósito de agua, bancos y plantas
	Kit.cyl(ctx, m, "Deposito", 5, 4, CF(6, F2 + 2.5, 14), rgb(160, 166, 176), M.CorrodedMetal, true)
	local f = Kit.furn(ctx, m, rgb(120, 84, 56))
	Furniture.bench(f, Kit.at(ctx, -20, F2, 16.4, 0), 5, rgb(120, 84, 56), m)
	for _, p in { { -33, 16.5 }, { -14, 16.5 }, { 11, 8 }, { 11, -2 } } do
		Props.make(ctx, m, "Plant", CF(p[1], F2, p[2]))
	end
	Props.scatter(ctx, m, { -30, 10, 0, 16 }, F2, 6, { "CableRun", "Crate", "Pile" })
	return m
end

function Observatory.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "Observatorio")
	tower(ctx, m)
	attic(ctx, m)
	roof(ctx, m)
	return m
end

return Observatory
