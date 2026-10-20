-- Observatory: el tejado de la casa de Cosme (plano del dueño, «Planta de techo / terraza» y el alzado;
-- en el render, la torre redonda de la izquierda y la torre-portal de la derecha).
--
--   * La CÚPULA DE OBSERVACIÓN (n.º 19): una torre redonda de dos tambores de cristal apilados, con aros
--     de metal, y entre los dos el «platillo» (un disco ancho de tejado con barandilla y anillo de luz);
--     arriba, un anillo de cristal de observación, la antena parabólica y la antena. Dentro del tambor
--     de abajo (adonde llega la escalera): el telescopio enorme que el jugador usa (aviso «Telescope»),
--     mesas con pantallas de mapas estelares, el globo holográfico y la radio de onda corta.
--   * Paneles solares (n.º 16), a la izquierda.
--   * Torre de experimentos (n.º 17): cilindro de metal con tubos que brillan y, flotando encima, el
--     VÓRTICE azul y morado (portal con espiral) que se ve desde la calle. Antena satélite (n.º 18).
--   * Terraza chill (n.º 20): sofás, mesa con sombrilla, plantas, guirnalda de luces y el resonador lunar.

local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)
local Layout = require(script.Parent.Layout)
local PortalSystem = require(script.Parent.PortalSystem)
local Laboratory = require(script.Parent.Laboratory)
local Furniture = require(script.Parent.Parent.Furniture)

local Observatory = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local M = Enum.Material
local C = Kit.Colors

local D = Layout.Dome
local F2 = Layout.F2
local TOP = D.Top
local TRIM = rgb(40, 42, 48)
local STEEL = rgb(160, 166, 176)

-- Aro de metal (o de neón) alrededor de un tambor: segmentos en un círculo horizontal
local function band(ctx: Kit.Ctx, parent: Instance, name: string, cx: number, cz: number, r: number, y: number, h: number, color: Color3, material: Enum.Material, n: number?)
	local count = n or 28
	for i = 0, count - 1 do
		local a = (i + 0.5) / count * math.pi * 2
		local p = Kit.deco(ctx, parent, name, V(2 * math.pi * r / count + 0.15, h, 0.5), CF(cx + math.cos(a) * r, y, cz + math.sin(a) * r) * ANG(0, -(a + math.pi / 2), 0), color, material, nil, true)
		p.CastShadow = false
	end
end

-- Disco ancho de tejado (el «platillo») con su canto de metal y el anillo de luz por debajo
local function saucer(ctx: Kit.Ctx, parent: Instance, name: string, r: number, y: number, thick: number)
	local disc = Kit.disc(ctx, parent, name, D.X, D.Z, r, y + thick, thick, rgb(228, 230, 234), M.SmoothPlastic)
	disc.Reflectance = 0.1
	Kit.cyl(ctx, parent, "Canto", thick + 0.3, r * 2 + 0.6, CF(D.X, y + thick / 2, D.Z), TRIM, M.Metal, true)
	local glow = Kit.cyl(ctx, parent, "AnilloLuz", 0.2, r * 2 + 0.4, CF(D.X, y - 0.15, D.Z), C.Cyan, M.Neon)
	glow.CastShadow = false
	Kit.cyl(ctx, parent, "AnilloLuzHueco", 0.22, r * 2 - 1.2, CF(D.X, y - 0.15, D.Z), rgb(228, 230, 234), M.SmoothPlastic)
	return disc
end

---------------------------------------------------------------------
-- La cúpula de observación: dos tambores de cristal, el platillo, la parabólica y la antena
---------------------------------------------------------------------
local function dome(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "CupulaObservacion")
	-- Tambor de abajo (al que llega la escalera): cristal todo alrededor con montantes, puerta a la terraza
	Kit.ringWall(ctx, m, D.X, D.Z, D.R, F2 - 0.5, TOP, {
		Segments = 28, Name = "TamborBajo", PieceName = "Wall", Color = TRIM, Material = M.Metal, Frame = TRIM,
		Window = { Bottom = F2 + 0.4, Top = TOP - 0.6 }, GlassTransparency = 0.4,
		Doors = { { Theta = math.pi, Top = F2 + 9.5, Width = 1 } },
	})
	band(ctx, m, "AroMetal", D.X, D.Z, D.R + 0.45, F2 - 0.2, 0.9, TRIM, M.Metal)
	band(ctx, m, "AroMetal", D.X, D.Z, D.R + 0.45, TOP - 0.3, 0.8, STEEL, M.Metal)
	band(ctx, m, "AroNeon", D.X, D.Z, D.R + 0.6, TOP - 0.9, 0.2, C.Cyan, M.Neon)
	-- El platillo (disco ancho de tejado) con barandilla en el borde
	saucer(ctx, m, "Platillo", D.DiscR, TOP, 1)
	for i = 0, 15 do
		local a = (i + 0.5) / 16 * math.pi * 2
		local r = D.DiscR - 0.6
		Kit.deco(ctx, m, "Poste", V(0.25, 2.4, 0.25), CF(D.X + math.cos(a) * r, TOP + 2.2, D.Z + math.sin(a) * r), STEEL, M.Metal, nil, true)
	end
	band(ctx, m, "Pasamanos", D.X, D.Z, D.DiscR - 0.6, TOP + 3.4, 0.25, STEEL, M.Metal, 32)
	band(ctx, m, "CristalBarandilla", D.X, D.Z, D.DiscR - 0.6, TOP + 2.2, 2.2, rgb(200, 230, 245), M.Glass, 32)
	-- Tambor de arriba: anillo de cristal de observación con aros de metal y su tejadillo
	local uy0, uy1 = TOP + 1, D.UpperTop
	Kit.ringWall(ctx, m, D.X, D.Z, D.UpperR, uy0, uy1, {
		Segments = 20, Name = "TamborAlto", PieceName = "Wall", Color = TRIM, Material = M.Metal, Frame = TRIM,
		Window = { Bottom = uy0 + 0.5, Top = uy1 - 0.5 }, GlassTransparency = 0.35,
	})
	band(ctx, m, "AroMetal", D.X, D.Z, D.UpperR + 0.4, uy0 + 0.3, 0.6, STEEL, M.Metal, 20)
	band(ctx, m, "AroNeon", D.X, D.Z, D.UpperR + 0.5, (uy0 + uy1) / 2, 0.18, C.Cyan, M.Neon, 20)
	local cap = Kit.disc(ctx, m, "Tejadillo", D.X, D.Z, D.UpperR + 2, uy1 + 0.8, 0.8, rgb(228, 230, 234), M.SmoothPlastic)
	cap.Reflectance = 0.1
	Kit.cyl(ctx, m, "CantoTejadillo", 1.1, (D.UpperR + 2) * 2 + 0.4, CF(D.X, uy1 + 0.4, D.Z), TRIM, M.Metal, true)
	-- Dentro del tambor de arriba: luz y una esfera estelar que gira (se ve desde la calle)
	local orb = Kit.ball(ctx, m, "EsferaEstelar", 3.4, CF(D.X, (uy0 + uy1) / 2, D.Z), rgb(120, 170, 255), M.ForceField, 0.15)
	Kit.anomaly(orb)
	Kit.spin(orb, 0.06, "Y")
	Kit.light(ctx, orb, 16, 1.2, rgb(150, 200, 255))
	Kit.cyl(ctx, m, "Pedestal", uy0 + 1 - (TOP + 1), 1, CF(D.X, (TOP + 1 + uy0 + 1) / 2, D.Z), TRIM, M.Metal, true)
	-- Antena parabólica grande encima (gira despacio) y la antena con su luz
	local dish = Kit.group(m, "Parabolica")
	local by = uy1 + 0.8
	Kit.box(ctx, dish, "Base", V(2.4, 1, 2.4), CF(D.X - 2.5, by + 0.5, D.Z), TRIM, M.Metal)
	Kit.cyl(ctx, dish, "Mastil", 4, 0.6, CF(D.X - 2.5, by + 3, D.Z), STEEL, M.Metal, true)
	local aim = CF(D.X - 2.5, by + 5.5, D.Z) * ANG(0, math.rad(200), 0) * ANG(math.rad(55), 0, 0)
	local plate = Kit.cylX(ctx, dish, "Plato", 0.4, 7.5, aim * ANG(0, math.pi / 2, 0), rgb(232, 234, 238), M.SmoothPlastic)
	plate.CastShadow = true
	Kit.cylX(ctx, dish, "Centro", 0.5, 1.8, aim * CF(0, 0, -0.3) * ANG(0, math.pi / 2, 0), rgb(200, 200, 205), M.Metal)
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2
		Kit.deco(ctx, dish, "Brazo", V(0.15, 0.15, 4), aim * CF(math.cos(a) * 1.5, math.sin(a) * 1.5, -1.9) * ANG(math.sin(a) * 0.35, -math.cos(a) * 0.35, 0), C.Dark, M.Metal)
	end
	local rx = Kit.ball(ctx, dish, "Receptor", 0.8, aim * CF(0, 0, -3.9), C.Red, M.Neon)
	Kit.anomaly(rx)
	Kit.spin(dish, 0.02, "Y")
	dish:SetAttribute("SpinCenter", Kit.at(ctx, D.X - 2.5, by + 3, D.Z))
	Kit.anomaly(dish:FindFirstChild("Plato") :: Instance)
	local ant = Kit.group(m, "Antena")
	Kit.box(ctx, ant, "Mastil", V(0.35, 9, 0.35), CF(D.X + 3, by + 4.5, D.Z + 1), STEEL, M.Metal)
	for k = 1, 4 do
		Kit.deco(ctx, ant, "Varilla", V(2.6 - k * 0.45, 0.12, 0.12), CF(D.X + 3, by + 3 + k * 1.3, D.Z + 1) * ANG(0, k * 0.4, 0), STEEL, M.Metal)
	end
	Kit.ball(ctx, ant, "Luz", 0.5, CF(D.X + 3, by + 9.2, D.Z + 1), C.Red, M.Neon)
	return m
end

-- Alfombra redonda con estrellas
local function rugStars(ctx: Kit.Ctx, parent: Instance, x: number, y: number, z: number)
	Kit.cyl(ctx, parent, "Alfombra", 0.08, 6, CF(x, y + 0.04, z), rgb(30, 34, 70), M.Fabric)
	local R = ctx.Rand
	for _ = 1, 8 do
		local a, r = R.range(0, math.pi * 2), R.range(0.5, 2.6)
		Kit.deco(ctx, parent, "Estrella", V(0.3, 0.03, 0.3), CF(x + math.cos(a) * r, y + 0.1, z + math.sin(a) * r) * ANG(0, a, 0), rgb(250, 230, 150), M.Neon)
	end
end

---------------------------------------------------------------------
-- Dentro del tambor de abajo: telescopio, mesas de control, globo holográfico y radio
---------------------------------------------------------------------
local function observatoryRoom(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Observatorio")
	local y = F2
	-- Barandillas del hueco de la escalera (llega por el carril de la derecha)
	local K = Layout.Core
	local s = Layout.Stairs.Hall
	local z0 = s.Z0 + s.Near
	Kit.railing(ctx, m, V(K.X0 - 0.2, y, z0), V(K.X0 - 0.2, y, K.Z1 + 0.2))
	Kit.railing(ctx, m, V(K.X1 + 0.2, y, z0), V(K.X1 + 0.2, y, K.Z1 + 0.2))
	Kit.railing(ctx, m, V(K.X0 - 0.2, y, K.Z1 + 0.2), V(K.X1 + 0.2, y, K.Z1 + 0.2))
	Kit.railing(ctx, m, V(K.X0 + 6, y, z0 - 0.2), V(K.X1 + 0.2, y, z0 - 0.2))
	-- Alfombra con estrellas y aro de luz LED colgando en el centro
	rugStars(ctx, m, -1, y, 1)
	local halo = Kit.ceilingLamp(ctx, m, D.X, TOP, D.Z, "Observatorio", "Ring", rgb(190, 220, 255))
	local _ = halo
	Kit.switch(ctx, m, D.X - D.R + 1.4, y + 4, -5.5, 90, "Observatorio")
	-- Telescopio enorme (pilar, montura de horquilla y tubo hacia el cielo, a través del cristal)
	local tele = Kit.group(m, "Telescopio")
	local tx, tz = -0.5, 7
	Kit.cyl(ctx, tele, "Pilar", 4, 2, CF(tx, y + 2, tz), rgb(60, 64, 76), M.Metal, true)
	Kit.box(ctx, tele, "Horquilla", V(3.6, 3, 0.6), CF(tx, y + 5.4, tz), rgb(200, 205, 215), M.Metal, { CanCollide = false })
	local aim = CF(tx, y + 6.4, tz) * ANG(0, math.rad(-90), 0) * ANG(0, 0, math.rad(-50))
	local tube = Kit.cylX(ctx, tele, "Tubo", 9, 2, aim * CF(-1.2, 0, 0), rgb(236, 236, 240), M.SmoothPlastic)
	tube.CanCollide = false
	Kit.cylX(ctx, tele, "Boca", 0.6, 2.4, aim * CF(-5.9, 0, 0), C.Dark, M.Metal)
	Kit.cylX(ctx, tele, "Lente", 0.1, 1.9, aim * CF(-6.25, 0, 0), rgb(120, 200, 255), M.Glass, 0.3)
	Kit.cylX(ctx, tele, "Buscador", 2.6, 0.5, aim * CF(-1.6, 1.3, 0), C.Dark, M.Metal)
	local eye = Kit.cylX(ctx, tele, "Ocular", 0.9, 0.5, aim * CF(3.6, -0.3, 0), C.Dark, M.Metal)
	for k = 0, 2 do
		Kit.neon(ctx, tele, "Anillo", V(0.15, 2.05, 2.05), aim * CF(-4.2 + k * 2.4, 0, 0), C.Cyan, 0.4).Shape = Enum.PartType.Cylinder
	end
	local prompt = Kit.prompt(eye, "Mirar por el telescopio", "🔭 Telescopio", "Telescope", { PropId = "CosmeTelescopio" })
	prompt.MaxActivationDistance = 10
	prompt:SetAttribute("Aim", Kit.world(ctx, aim * ANG(0, math.pi / 2, 0)))
	Furniture.officeChair(Kit.furn(ctx, m), Kit.at(ctx, -3.4, y, 4, 210), rgb(30, 30, 34), m)
	-- Mesas de control con pantallas (al otro lado del hueco)
	local f = Kit.furn(ctx, m)
	for _, z in { -4.5, 2.5 } do
		Kit.box(ctx, m, "MesaControl", V(2.6, 0.3, 5.6), CF(18.4, y + 3, z), rgb(30, 34, 44), M.Metal)
		Kit.box(ctx, m, "PieMesa", V(0.4, 2.85, 5.2), CF(19.3, y + 1.43, z), rgb(30, 34, 44), M.Metal)
		for k, kind in { "Stars", "Coords", "Anomalies" } do
			Kit.monitor(ctx, m, CF(18.9, y + 3.15, z - 3.6 + k * 1.8) * ANG(0, -math.pi / 2, 0), 1.6, 1.1, kind)
		end
		Furniture.officeChair(f, Kit.at(ctx, 16.9 + 0.1, y, z, 90), rgb(30, 30, 34), m)
		Props.scatter(ctx, m, { 17.4, 18, z - 2.6, z + 2.6 }, y + 3.15, 2, { "Mug", "Papers", "Clipboard" })
	end
	local mainScreen = Kit.monitor(ctx, m, CF(18.9, y + 3.15, -1) * ANG(0, -math.pi / 2, 0), 2.4, 1.5, "Stars")
	Kit.prompt(mainScreen, "Mirar la pantalla", "🛰️ Centro de control", "Screen", { Title = "Centro de control", Text = "SATÉLITE «PIP-SAT»: en órbita (más o menos)\nANTENAS: escuchando la grieta\nMENSAJE CAPTADO ANOCHE: «…socio… la fusión… pronto…»\nRUTA A LA LUNA: 384.400 km · combustible: apio", PropId = "CosmeControl" })
	-- Globo holográfico que flota y radio de onda corta
	local holo = Kit.group(m, "GloboHolografico")
	Kit.cyl(ctx, holo, "Proyector", 1, 2.4, CF(1.6, y + 0.5, 8.6), TRIM, M.Metal, true)
	local globe = Kit.ball(ctx, holo, "Holograma", 2.6, CF(1.6, y + 3.4, 8.6), C.Cyan, M.ForceField, 0.2)
	Kit.anomaly(globe)
	Kit.spin(globe, 0.1, "Y")
	Kit.fx(globe, "Dust", 5)
	local radio = Kit.group(m, "Radio")
	Kit.box(ctx, radio, "Rack", V(2, 4.4, 2), CF(17.4, y + 2.2, 6), rgb(60, 50, 40), M.Metal)
	for k = 0, 3 do
		Kit.neon(ctx, radio, "Dial", V(0.05, 0.4, 0.4), CF(16.38, y + 3.4, 5.2 + k * 0.55), ({ C.Orange, C.Green, C.Orange, C.Red })[k + 1], 0.2)
	end
	Kit.prompt(radio:FindFirstChild("Rack") :: BasePart, "Escuchar la radio", "📻 Radio de onda corta", "Doc", { Title = "Radio de onda corta", Text = "Entre el ruido se oye una voz de presentador de concursos: «…y el premio de hoy es… ¡OTRA VALMAR!». Luego, aplausos enlatados. Cosme ha pegado un pósit: «NO CONTESTAR».", PropId = "CosmeRadio" })
	Props.scatter(ctx, m, { -3, 2, -8, -3 }, y, 3, { "Book", "Papers", "CableRun" })
	return m
end

---------------------------------------------------------------------
-- Torre de experimentos (con el vórtice encima) y antena satélite
---------------------------------------------------------------------
local function experimentTower(ctx: Kit.Ctx, parent: Instance)
	local P = Layout.PortalTower
	local t = Kit.group(parent, "TorrePortal")
	local y = F2
	local top = y + 17
	-- Base escalonada, cuerpo de metal con ojos de buey y anillos de neón
	Kit.cyl(ctx, t, "Base", 1.4, P.R * 2 + 2.4, CF(P.X, y + 0.7, P.Z), rgb(90, 94, 104), M.DiamondPlate, true)
	Kit.cyl(ctx, t, "Cuerpo", top - y - 1.4, P.R * 2, CF(P.X, (y + 1.4 + top) / 2, P.Z), rgb(120, 126, 140), M.Metal, true)
	for i, h in { 4, 8.5, 13 } do
		local ring = Kit.cyl(ctx, t, "AnilloNeon", 0.45, P.R * 2 + 0.3, CF(P.X, y + h, P.Z), if i % 2 == 0 then C.Cyan else C.Purple, M.Neon)
		ring.Transparency = 0.1
		ring.CastShadow = false
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 - math.pi / 2
		local win = Kit.neon(ctx, t, "OjoDeBuey", V(0.3, 1.8, 1.8), CF(P.X + math.cos(a) * P.R, y + 6.3, P.Z + math.sin(a) * P.R) * ANG(0, -a, 0), rgb(140, 210, 255), 0.2)
		win.Shape = Enum.PartType.Cylinder
	end
	-- Tubos que brillan por fuera (cristal con un núcleo de luz) y tuberías de cobre
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.3
		local x, z = P.X + math.cos(a) * (P.R + 0.7), P.Z + math.sin(a) * (P.R + 0.7)
		Kit.cyl(ctx, t, "TuboCristal", top - y - 2.6, 0.9, CF(x, (y + 1.4 + top - 1.2) / 2, z), rgb(170, 220, 255), M.Glass, false, 0.5)
		local core = Kit.cyl(ctx, t, "TuboLuz", top - y - 3, 0.4, CF(x, (y + 1.4 + top - 1.2) / 2, z), if i % 2 == 0 then C.Cyan else C.Purple, M.Neon, false, 0.1)
		core.CastShadow = false
	end
	Kit.cyl(ctx, t, "Tuberia", top - y - 1, 0.7, CF(P.X - P.R - 1.6, (y + top) / 2, P.Z), rgb(170, 120, 70), M.Metal)
	-- Plataforma de arriba y el VÓRTICE flotando encima (mirando a la calle), con su espiral
	Kit.cyl(ctx, t, "Plataforma", 1, P.R * 2 + 3, CF(P.X, top + 0.5, P.Z), rgb(70, 74, 86), M.DiamondPlate, true)
	local ring = Kit.cyl(ctx, t, "AnilloPlataforma", 0.3, P.R * 2 + 3.2, CF(P.X, top + 0.2, P.Z), C.Cyan, M.Neon)
	ring.CastShadow = false
	local vc = CF(P.X, top + 7.8, P.Z)
	local portal = PortalSystem.build(ctx, t, vc, 5, { Name = "Vortice", Color = C.Purple, Depth = 3, Layers = 10, Spin = 0.3, NoCoils = true, Destination = 1, Arms = 6 })
	portal:SetAttribute("Decor", true)
	-- La espiral: anillo exterior que gira (azul) y otro más grande (morado) en sentido contrario
	local outer = Laboratory.ring(ctx, t, "EspiralVortice", vc * CF(0, 0, -0.6), 6.6, 30, C.Cyan, 0.5)
	Kit.spin(outer, 0.08, "Z")
	outer:SetAttribute("SpinCenter", Kit.world(ctx, vc))
	Kit.anomaly(outer)
	local outer2 = Laboratory.ring(ctx, t, "EspiralVortice", vc * CF(0, 0, -0.9), 7.6, 34, C.Purple, 0.35)
	Kit.spin(outer2, -0.05, "Z")
	outer2:SetAttribute("SpinCenter", Kit.world(ctx, vc))
	Kit.anomaly(outer2)
	-- Rayos que suben de la plataforma al vórtice
	local plate = t:FindFirstChild("Plataforma") :: BasePart
	local core = portal:FindFirstChild("Nucleo", true) :: BasePart?
	if plate and core then
		local b = Kit.beam(plate, core, C.Cyan, 0.5, 10)
		b.CurveSize0 = 3
		b.CurveSize1 = -3
	end
	-- Encender la torre (aviso de máquina)
	local panel = Kit.box(ctx, t, "PanelTorre", V(1.6, 2.4, 0.4), CF(P.X, y + 2.6, P.Z - P.R - 0.3), rgb(50, 54, 66), M.Metal)
	Kit.neon(ctx, t, "BotonTorre", V(0.6, 0.6, 0.1), CF(P.X, y + 2.9, P.Z - P.R - 0.55), C.Red)
	Kit.prompt(panel, "Encender la torre", "🌀 Torre de experimentos", "Machine", { Target = "TorrePortal", PropId = "CosmeTorre", Text = "La torre zumba, los tubos se ponen a hervir de luz y el vórtice de arriba gira más rápido. Desde la calle, los vecinos aplauden. O huyen." })
	-- Antena satélite (n.º 18)
	local A = Layout.Antenna
	local sat = Kit.group(parent, "AntenaSatelite")
	Kit.box(ctx, sat, "Base", V(2.2, 1, 2.2), CF(A.X, y + 0.5, A.Z), TRIM, M.Metal)
	Kit.cyl(ctx, sat, "Mastil", 5, 0.5, CF(A.X, y + 3.5, A.Z), STEEL, M.Metal, true)
	local aim = CF(A.X, y + 6.2, A.Z) * ANG(0, math.rad(160), 0) * ANG(math.rad(50), 0, 0)
	Kit.cylX(ctx, sat, "Plato", 0.3, 4.6, aim * ANG(0, math.pi / 2, 0), rgb(232, 234, 238), M.SmoothPlastic)
	Kit.ball(ctx, sat, "Receptor", 0.5, aim * CF(0, 0, -2.2), C.Red, M.Neon)
	Kit.doc(sat:FindFirstChild("Base") :: BasePart, "Antena satélite", "«PIP-SAT 2: canal de bajada». Recibe mensajes del satélite… y, a veces, de otra Valmar.", "CosmeSatelite")
	return t
end

---------------------------------------------------------------------
-- Paneles solares y terraza chill
---------------------------------------------------------------------
local function solar(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "PanelesSolares")
	local S = Layout.Solar
	local y = F2
	for row = 0, 5 do
		for col = 0, 1 do
			local x, z = S.X0 + 4.5 + col * 8.2, S.Z0 + 5.5 + row * 6.2
			local base = CF(x, y, z)
			for _, sx in { -3, 3 } do
				Kit.deco(ctx, m, "Pata", V(0.3, 2.1, 0.3), base * CF(sx, 1.05, 1.6), STEEL, M.Metal, nil, true)
				Kit.deco(ctx, m, "Pata", V(0.3, 0.8, 0.3), base * CF(sx, 0.4, -1.6), STEEL, M.Metal, nil, true)
			end
			local tilt = base * CF(0, 1.3, 0) * ANG(math.rad(-18), 0, 0)
			local panel = Kit.deco(ctx, m, "PlacaSolar", V(7.6, 0.25, 4.6), tilt, rgb(22, 38, 90), M.Glass, nil, true)
			panel.Reflectance = 0.3
			for k = 1, 4 do
				Kit.deco(ctx, m, "Celda", V(0.08, 0.27, 4.4), tilt * CF(-3.8 + k * 1.52, 0, 0), rgb(150, 160, 180), M.Metal)
			end
		end
	end
	local inv = Kit.box(ctx, m, "Inversor", V(2.4, 3, 1.4), CF(38.6, y + 1.5, 20), rgb(200, 204, 210), M.Metal)
	Kit.neon(ctx, m, "Piloto", V(0.05, 0.3, 0.3), CF(37.88, y + 2.4, 20), C.Green)
	Kit.doc(inv, "Inversor solar", "«Energía de hoy: 66 kWh. Energía que se ha comido el portal: 66 kWh. Saldo: 0. Como siempre.»", "CosmeInversor")
	Kit.deco(ctx, m, "Canaleta", V(0.6, 0.4, 36), CF(39.2, y + 0.2, 2), TRIM, M.Metal, nil, true)
	return m
end

local function chill(ctx: Kit.Ctx, parent: Instance)
	local m = Kit.group(parent, "Azotea")
	local y = F2
	-- Suelo de tarima en la terraza chill
	Kit.box(ctx, m, "Tarima", V(16, 0.1, 29.4), CF(-13.8, y + 0.05, -5.3), rgb(160, 112, 72), M.WoodPlanks, { CanQuery = true, CastShadow = false })
	local f = Kit.furn(ctx, m, rgb(80, 80, 86), rgb(232, 226, 210), C.Cyan)
	Furniture.sofa(f, Kit.at(ctx, -19.6, y + 0.1, -4, -90), rgb(232, 226, 210), 3, m)
	Furniture.coffeeTable(f, Kit.at(ctx, -15.2, y + 0.1, -4, 90), 4.4, 2.4, m)
	Props.make(ctx, m, "Mug", CF(-15.2, y + 1.6, -4.4))
	-- Mesa redonda con sombrilla y sillas
	Kit.cyl(ctx, m, "Mesa", 0.3, 4, CF(-17, y + 3, -15), C.White, M.SmoothPlastic, true)
	Kit.cyl(ctx, m, "PieMesa", 2.85, 0.5, CF(-17, y + 1.48, -15), TRIM, M.Metal, true)
	for _, p in { { -19.8, -15, -90 }, { -17, -17.8, 0 } } do
		Furniture.chair(f, Kit.at(ctx, p[1], y + 0.1, p[2], p[3]), rgb(80, 80, 86), m)
	end
	Kit.cyl(ctx, m, "Palo", 8.5, 0.3, CF(-17, y + 4.4, -15), C.White, M.Metal, true)
	local cloth = Kit.ellipsoid(ctx, m, "Lona", V(9, 1.4, 9), CF(-17, y + 8.6, -15), rgb(40, 130, 110), M.Fabric)
	cloth.CastShadow = true
	-- Plantas en macetas por todo el borde y una guirnalda de luces
	for _, p in { { -20.5, -19 }, { -20.5, 8 }, { -7, -19 }, { -20.5, 2 }, { -9, 9 } } do
		Props.make(ctx, m, "Plant", CF(p[1], y + 0.1, p[2]))
	end
	for _, z in { -18.6, 8.6 } do
		Kit.box(ctx, m, "PosteLuces", V(0.3, 7, 0.3), CF(-21, y + 3.5, z), TRIM, M.Metal)
	end
	for i = 0, 12 do
		local z = -18.6 + i * 27.2 / 12
		Kit.ball(ctx, m, "Bombilla", 0.4, CF(-21, y + 6.6 - math.sin(i / 12 * math.pi) * 1.2, z), rgb(255, 220, 150), M.Neon)
	end
	-- La máquina experimental: el resonador lunar (gira y se enciende)
	local mach = Kit.group(m, "ResonadorLunar")
	local mx, mz = -17.5, 4
	Kit.cyl(ctx, mach, "Base", 1.2, 4.6, CF(mx, y + 0.6, mz), rgb(60, 64, 76), M.DiamondPlate, true)
	Kit.cyl(ctx, mach, "Columna", 4, 1.2, CF(mx, y + 3.2, mz), STEEL, M.Metal, true)
	local spinner = Kit.group(mach, "Rotor")
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		Kit.deco(ctx, spinner, "Brazo", V(3.6, 0.35, 0.5), CF(mx, y + 5.6, mz) * ANG(0, a, 0) * CF(1.8, 0, 0), C.Chrome, M.Metal, nil, true)
		Kit.ball(ctx, spinner, "Esfera", 1, CF(mx, y + 5.6, mz) * ANG(0, a, 0) * CF(3.7, 0, 0), if k % 2 == 0 then C.Cyan else C.Magenta, M.Neon, 0.1)
	end
	Kit.spin(spinner, 0.15, "Y")
	spinner:SetAttribute("SpinCenter", Kit.at(ctx, mx, y + 5.6, mz))
	local top = Kit.ball(ctx, mach, "Cristal", 1.6, CF(mx, y + 6.2, mz), rgb(220, 240, 255), M.Neon, 0.1)
	Kit.light(ctx, top, 14, 1.1, rgb(200, 230, 255))
	Kit.fx(top, "Energy", 8)
	Kit.prompt(mach:FindFirstChild("Base") :: BasePart, "Encender el resonador", "🌕 Resonador lunar", "Machine", { Target = "ResonadorLunar", PropId = "CosmeResonador", Text = "El resonador apunta a la luna y zumba. Durante un segundo, la luna parece… más cerca. Muy poco. Pero más cerca." })
	-- Satélite de prueba en su soporte
	local sat = Kit.group(m, "SatelitePrueba")
	Kit.box(ctx, sat, "Soporte", V(1, 3, 1), CF(-8, y + 1.5, 6), TRIM, M.Metal)
	Kit.box(ctx, sat, "Cuerpo", V(2, 2, 2), CF(-8, y + 4, 6), rgb(220, 180, 60), M.Foil)
	for _, s in { -1, 1 } do
		Kit.deco(ctx, sat, "Panel", V(3.2, 0.1, 1.6), CF(-8 + s * 2.6, y + 4, 6), rgb(30, 50, 110), M.Glass, nil, true)
	end
	Kit.doc(sat:FindFirstChild("Cuerpo") :: BasePart, "Satélite de prueba", "«PIP-SAT 2». El primero sigue dando vueltas a la Tierra. Este se queda aquí, por si acaso. Pip le habla por las noches.", "CosmeSateliteMaqueta")
	-- Barandilla de cristal en el borde de la azotea (por dentro del peto)
	local U = Layout.Upper
	Kit.railing(ctx, m, V(U.X0 + 0.6, y, U.Z0 + 0.6), V(U.X1 - 0.6, y, U.Z0 + 0.6), 2.4)
	Kit.railing(ctx, m, V(U.X0 + 0.6, y, U.Z0 + 0.6), V(U.X0 + 0.6, y, U.Z1 - 0.6), 2.4)
	Props.scatter(ctx, m, { -21, -16, 9, 11 }, y, 2, { "Crate", "Pile" })
	return m
end

function Observatory.build(ctx: Kit.Ctx, root: Instance): Model
	local m = Kit.group(root, "Tejado")
	dome(ctx, m)
	observatoryRoom(ctx, m)
	experimentTower(ctx, m)
	solar(ctx, m)
	chill(ctx, m)
	return m
end

return Observatory
