-- VerticeKit (servidor): las formas, colores y luces de DISTRITO CERO, la capital de Vértice (el KIT del
-- marco común: World/PlanetCityBuilder lo usa con el plano shared/Cosmos/VerticeCity;
-- docs/planetas/talasa-vertice.md).
--
-- Megaciudad de alta tecnología: cubiertas de cristal oscuro con cantos de neón colgadas sobre el hueco,
-- torres de cristal con líneas de luz (rosa, cian, amarillo), hologramas, el raíl del mag-lev, cámaras
-- con su luz roja y, en el cielo, los anillos de los Astilleros Orbitales y los paneles de la Cúpula. Ni
-- madera ni lona (eso es Tálasa), ni basalto (Tefra). Todo con piezas, casi todo de adorno.
--
-- Lo de la ciudad se dibuja a Y = 0 (la cubierta) y PlanetCityBuilder lo sube; lo de fuera (kit.poi,
-- kit.decor, kit.world) va en coordenadas del mundo.

local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Kit.Palette)

local Kit = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB
local M = Enum.Material

local C = {
	Deck = rgb(34, 36, 48),
	DeckLight = rgb(58, 62, 80),
	Glass = rgb(90, 120, 170),
	GlassDark = rgb(30, 40, 70),
	White = rgb(232, 236, 244),
	Steel = rgb(110, 116, 130),
	Pink = rgb(255, 70, 190),
	Cyan = rgb(60, 230, 255),
	Yellow = rgb(255, 220, 60),
	Red = rgb(255, 40, 60),
	Bronze = rgb(176, 130, 70),
}
local NEONS = { C.Pink, C.Cyan, C.Yellow }
Kit.Colors = {
	Metal = C.Steel,
	Lamp = C.Cyan,
	Floor = C.Deck,
	FloorMaterial = M.Glass,
	Light = rgb(230, 240, 255),
	Sign = rgb(16, 16, 26),
	SignText = C.Cyan,
	Wall = C.GlassDark,
	Pad = rgb(60, 64, 80),
	PadRing = C.Pink,
	PadLight = C.Cyan,
	Poi = C.Steel,
	PoiLight = C.Pink,
}

-- Estilos de edificio (Kit/Building): cristal oscuro con muro cortina, neón de anuncio y chapa del Rastro
Palette.Styles.VerticeCristal = {
	Wall = { rgb(40, 46, 70), rgb(50, 56, 84), rgb(34, 40, 62) },
	WallMaterial = M.Glass,
	Trim = rgb(200, 210, 230),
	TrimMaterial = M.Metal,
	Glass = rgb(70, 140, 200),
	Bay = 6,
	WindowW = 5.2,
	WindowH = 8,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
	Curtain = true,
}
Palette.Styles.VerticeNeon = {
	Wall = { rgb(236, 238, 246), rgb(226, 228, 238) },
	WallMaterial = M.SmoothPlastic,
	Trim = C.Pink,
	TrimMaterial = M.Neon,
	Glass = rgb(60, 80, 120),
	Bay = 7,
	WindowW = 6,
	WindowH = 7,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.VerticeChapa = {
	Wall = { rgb(70, 66, 74), rgb(84, 76, 70), rgb(60, 62, 70) },
	WallMaterial = M.CorrodedMetal,
	Trim = C.Yellow,
	TrimMaterial = M.Metal,
	Glass = rgb(60, 60, 50),
	Bay = 8,
	WindowW = 3.4,
	WindowH = 3.4,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}

local DROP = 90 -- (del Nivel Medio al Nivel Bajo)

local function glowAtNight(p: BasePart, day: Color3, night: Color3, on: number?, off: number?)
	p:AddTag("NightWindow")
	p:SetAttribute("DayColor", day)
	p:SetAttribute("NightColor", night)
	p:SetAttribute("OnAt", on or 18)
	p:SetAttribute("OffAt", off or 31)
end

local function neonOf(seed: number): Color3
	return NEONS[(math.floor(math.abs(seed)) % #NEONS) + 1]
end

-- Las cubiertas: losa de cristal oscuro con canto de neón y, debajo, la viga y unos pocos pilares que
-- bajan al Nivel Bajo
function Kit.floor(ctx: any, parent: Instance, f: { [string]: any }): boolean
	local top = 0.9
	local m = Builder.model(f.Id or "Cubierta", parent)
	if f.Kind == "Disc" then
		local topY = if f.Deck == "Plataforma" then 0.45 else top
		ctx.column(m, "Losa", ctx.W(f.X, f.Z, -2), topY + 2, f.R * 2, C.Deck, M.Glass)
		local ring = ctx.column(m, "Canto", ctx.W(f.X, f.Z, -2.6), 0.8, f.R * 2 + 1, C.Cyan, M.Neon, true)
		glowAtNight(ring, C.Cyan, rgb(140, 250, 255))
		ctx.column(m, "Pilar", ctx.W(f.X, f.Z, -DROP), DROP - 2, 10, C.Steel, M.Concrete, true)
		return true
	end
	local x0, x1, z0, z1 = f.X0, f.X1, f.Z0, f.Z1
	local color = if f.Deck == "Rastro" then rgb(52, 48, 50) elseif f.Deck == "Plaza" then C.DeckLight else C.Deck
	local material = if f.Deck == "Rastro" then M.DiamondPlate elseif f.Deck == "Plaza" then M.Marble else M.Glass
	ctx.box(m, "Losa", x0, x1, z0, z1, -1.6, top, color, material)
	local edge = if f.Deck == "Rastro" then C.Yellow elseif f.Deck == "Avenida" then C.Pink else C.Cyan
	for i, e in { { x0 - 0.4, x1 + 0.4, z0 - 0.4, z0 + 0.2 }, { x0 - 0.4, x1 + 0.4, z1 - 0.2, z1 + 0.4 } } do
		local strip = ctx.box(m, "Neon" .. i, e[1], e[2], e[3], e[4], -1.8, -0.9, edge, M.Neon, true)
		glowAtNight(strip, edge, edge)
	end
	if f.Deck == "Plaza" or f.Deck == "Avenida" then
		-- las aceras-cinta: franjas luminosas que «llevan» a la gente
		for k = 1, 2 do
			local zz = z0 + (z1 - z0) * k / 3
			ctx.box(m, "Cinta" .. k, x0 + 4, x1 - 4, zz - 1.2, zz + 1.2, top - 0.02, top + 0.05, rgb(90, 96, 120), M.Metal, true)
			ctx.box(m, "CintaLuz" .. k, x0 + 4, x1 - 4, zz - 0.15, zz + 0.15, top + 0.05, top + 0.1, edge, M.Neon, true)
		end
	end
	if f.Deck ~= "Pasarela" then
		ctx.box(m, "Viga", x0 + 2, x1 - 2, (z0 + z1) / 2 - 2, (z0 + z1) / 2 + 2, -6, -1.6, C.Steel, M.Metal, true)
		for _, p in { { x0 + 6, z0 + 6 }, { x1 - 6, z1 - 6 } } do
			ctx.column(m, "Pilar", ctx.W(p[1], p[2], -DROP), DROP - 1.6, 6, C.Steel, M.Concrete, true)
		end
	end
	return true
end

-- Farola de Distrito Cero: poste fino de acero con una barra de neón cian
function Kit.lamp(_ctx: any, parent: Instance, cf: CFrame)
	local m = Builder.model("StreetLamp", parent)
	Builder.part({ Name = "Pie", Size = V3(1, 0.4, 1), CFrame = cf * CFrame.new(0, 0.2, 0), Color = C.Steel, Material = M.Metal, Parent = m })
	Builder.part({ Name = "Poste", Size = V3(0.4, 11, 0.4), CFrame = cf * CFrame.new(0, 5.6, 0), Color = rgb(200, 206, 220), Material = M.Metal, Parent = m })
	local bar = Builder.decor({ Name = "Barra", Size = V3(0.5, 3.2, 0.5), CFrame = cf * CFrame.new(0, 9.4, 0.4), Color = C.Cyan, Material = M.Neon, Tags = { "StreetLamp" }, Parent = m })
	local light = Instance.new("PointLight")
	light.Range = 26
	light.Brightness = 1.5
	light.Color = rgb(150, 240, 255)
	light.Shadows = false
	light.Enabled = false
	light.Parent = bar
	return m
end

-- Lo de los edificios Box: aristas de neón y una pantalla de anuncio encima de la puerta
function Kit.dressBox(_ctx: any, model: Model, b: { [string]: any }, cf: CFrame, info: { [string]: any })
	local w, d = b.W or 20, b.D or 20
	local top = info.Top or 14
	local neon = if b.Kind == "Clinica" or b.Kind == "Ascensor" then C.Yellow else neonOf(b.X + b.Z)
	local band = Builder.decor({ Name = "Cornisa", Size = V3(w + 0.6, 0.5, d + 0.6), CFrame = cf * CFrame.new(0, top + 0.1, 0), Color = neon, Material = M.Neon, Parent = model })
	glowAtNight(band, neon, neon)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Builder.decor({ Name = "Arista", Size = V3(0.4, top, 0.4), CFrame = cf * CFrame.new(sx * (w / 2 + 0.2), top / 2, sz * (d / 2 + 0.2)), Color = neon, Material = M.Neon, Parent = model })
		end
	end
	if b.Kind == "Tienda" or b.Kind == "Arcade" or b.Kind == "Museo" then
		local ad = Builder.decor({ Name = "Anuncio", Size = V3(math.min(w * 0.6, 14), 4, 0.3), CFrame = cf * CFrame.new(0, top + 3, -d / 2 - 0.3), Color = rgb(20, 20, 30), Material = M.SmoothPlastic, Parent = model })
		Builder.sign(ad, if b.Kind == "Museo" then "LA LUZ ES NUESTRA" elseif b.Kind == "Arcade" then "INSERT COIN" else "¡OFERTA!", Enum.NormalId.Front, neon, rgb(20, 20, 30))
	end
	Builder.streamable(model)
end

Kit.Shapes = {}

-- La Torre de Ventas: cristal oscuro escalonado, aristas de neón, el logo holográfico y la antena
function Kit.Shapes.Torre(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local H = b.Height or 160
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local steps = { { 1, 0.42 }, { 0.82, 0.3 }, { 0.62, 0.28 } }
	local y = 0.9
	for i, s in steps do
		local hw, hd = (x1 - x0) / 2 * s[1], (z1 - z0) / 2 * s[1]
		local h = H * s[2]
		ctx.box(m, "Cuerpo" .. i, cx - hw, cx + hw, cz - hd, cz + hd, y, y + h, C.GlassDark, M.Glass)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Builder.decor({ Name = "Arista", Size = V3(0.6, h, 0.6), CFrame = ctx.CF(cx + sx * hw, cz + sz * hd, y + h / 2), Color = if i == 2 then C.Pink else C.Cyan, Material = M.Neon, Parent = m })
			end
		end
		-- líneas de planta (cada pocas plantas, un filo de luz)
		for k = 1, 3 do
			local band = ctx.box(m, "Planta" .. i .. k, cx - hw - 0.2, cx + hw + 0.2, cz - hd - 0.2, cz + hd + 0.2, y + h * k / 4, y + h * k / 4 + 0.4, C.White, M.Neon, true)
			glowAtNight(band, rgb(150, 160, 190), C.White)
		end
		y += h
	end
	ctx.column(m, "Antena", ctx.W(cx, cz, y), 30, 1.4, C.Steel, M.Metal, true)
	local tip = ctx.ball(m, "Baliza", ctx.W(cx, cz, y + 30), 2.4, C.Red, M.Neon, true)
	glowAtNight(tip, C.Red, C.Red, 0, 99)
	-- el logo holográfico flotando delante (la «M» de MegaVerso: dos barras y una V)
	local logoY = 0.9 + H * 0.42 + 10
	for i, part in { { -5, 0 }, { 5, 0 }, { -2.5, -0.5 }, { 2.5, 0.5 } } do
		local tilt = if i > 2 then math.rad(if i == 3 then 25 else -25) else 0
		Builder.decor({ Name = "Logo" .. i, Size = V3(1.6, 14, 0.4), CFrame = ctx.CF(cx + part[1], z0 - 4, logoY) * CFrame.Angles(0, 0, tilt), Color = C.Pink, Material = M.Neon, Transparency = 0.25, Parent = m })
	end
	ctx.sign(m, "MEGAVERSO · TORRE DE VENTAS", ctx.CF(cx, z0 - 0.4, 12, math.pi), 30, 3)
	ctx.box(m, "Puertas", cx - 6, cx + 6, z0 - 0.6, z0 + 0.4, 0.9, 10, C.Glass, M.Glass, true)
	Builder.streamable(m)
	return m
end

-- Torre de oficinas cilíndrica: anillos de luz cada pocas plantas
function Kit.Shapes.Rascacielos(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local R, H = b.R or 10, b.Height or 100
	ctx.column(m, "Fuste", ctx.W(b.X, b.Z, 0.9), H, R * 2, C.GlassDark, M.Glass)
	for k = 1, 6 do
		local ring = ctx.column(m, "Anillo" .. k, ctx.W(b.X, b.Z, 0.9 + H * k / 7), 0.6, R * 2 + 0.6, if k % 2 == 0 then C.Cyan else C.Yellow, M.Neon, true)
		glowAtNight(ring, ring.Color, ring.Color)
	end
	ctx.column(m, "Tejado", ctx.W(b.X, b.Z, 0.9 + H), 2, R * 1.4, C.Steel, M.Metal, true)
	Builder.streamable(m)
	return m
end

-- La pantalla gigante de la plaza: un poste y una pantalla de dos caras
function Kit.Shapes.Holo(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local H = b.Height or 30
	ctx.column(m, "Poste", ctx.W(b.X, b.Z, 0.9), H * 0.55, 3, C.Steel, M.Metal)
	ctx.column(m, "Base", ctx.W(b.X, b.Z, 0.9), 1.4, (b.R or 6) * 2, C.Deck, M.Metal)
	local screen = Builder.part({ Name = "Pantalla", Size = V3(22, 12, 1), CFrame = ctx.CF(b.X, b.Z, 0.9 + H * 0.55 + 6, math.rad(30)), Color = rgb(18, 18, 30), Material = M.SmoothPlastic, Parent = m })
	Builder.sign(screen, "¡GRACIAS POR SU COMPRA!", Enum.NormalId.Front, C.Pink, rgb(18, 18, 30))
	Builder.sign(screen, "LIQUIDACIÓN TOTAL · TODO DEBE IRSE", Enum.NormalId.Back, C.Yellow, rgb(18, 18, 30))
	local frame = Builder.decor({ Name = "Marco", Size = V3(23, 13, 0.6), CFrame = screen.CFrame * CFrame.new(0, 0, 0.4), Color = C.Cyan, Material = M.Neon, Transparency = 0.3, Parent = m })
	glowAtNight(frame, C.Cyan, C.Cyan)
	Builder.streamable(m)
	return m
end

-- La estación del mag-lev: andén, marquesina de cristal, el raíl que cruza el barrio y el tren flotando
function Kit.Shapes.Maglev(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local H = b.Height or 16
	ctx.box(m, "Anden", x0, x1, z0, z1, 0.9, 2, C.DeckLight, M.Marble)
	for _, x in { x0 + 2, x1 - 2 } do
		for _, z in { z0 + 2, z1 - 2 } do
			ctx.box(m, "Columna", x - 0.6, x + 0.6, z - 0.6, z + 0.6, 2, H, C.White, M.Metal, true)
		end
	end
	local roof = ctx.box(m, "Marquesina", x0 - 2, x1 + 2, z0 - 2, z1 + 2, H, H + 0.6, C.Glass, M.Glass, true)
	roof.Transparency = 0.4
	-- el raíl, a la altura del andén, de un lado al otro del barrio (y más allá)
	local railZ = (z0 + z1) / 2
	ctx.box(m, "Rail", -260, 260, railZ - 1.5, railZ + 1.5, 3.4, 4.2, C.Steel, M.Metal, true)
	local guide = ctx.box(m, "RailLuz", -260, 260, railZ - 0.3, railZ + 0.3, 4.2, 4.4, C.Cyan, M.Neon, true)
	glowAtNight(guide, C.Cyan, C.Cyan)
	-- el tren (tres vagones redondeados flotando sobre el raíl)
	for k = 0, 2 do
		local cx = x0 + 4 + k * 12
		ctx.box(m, "Vagon" .. k, cx, cx + 11, railZ - 2.6, railZ + 2.6, 5.2, 10, C.White, M.SmoothPlastic, true)
		ctx.box(m, "Ventanas" .. k, cx + 0.5, cx + 10.5, railZ - 2.7, railZ + 2.7, 7.4, 9, C.GlassDark, M.Glass, true)
		ctx.box(m, "Franja" .. k, cx, cx + 11, railZ - 2.7, railZ + 2.7, 6, 6.4, C.Pink, M.Neon, true)
	end
	ctx.sign(m, "MAG-LEV · DISTRITO CERO", ctx.CF((x0 + x1) / 2, z1 + 0.4, H - 2, 0), 16, 2)
	Builder.streamable(m)
	return m
end

-- Los bloques iguales del Barrio Plantilla: caja blanca con ventanas en rejilla y la luz de cada piso
function Kit.Shapes.Bloque(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local H = b.Height or 60
	ctx.box(m, "Cuerpo", x0, x1, z0, z1, 0.9, H, rgb(214, 216, 224), M.SmoothPlastic)
	for k = 1, 6 do
		local y = 0.9 + H * k / 7
		for side, z in { z0 - 0.15, z1 + 0.15 } do
			local win = ctx.box(m, "Ventanas" .. k .. side, x0 + 1.5, x1 - 1.5, z - 0.1, z + 0.1, y - 2, y + 1, rgb(60, 70, 96), M.Glass, true)
			glowAtNight(win, rgb(60, 70, 96), rgb(250, 230, 180), 18 + (k % 3) * 0.6, 23 + (k % 2) * 2)
		end
	end
	ctx.box(m, "Numero", x0 + 2, x0 + 6, z0 - 0.3, z0 - 0.1, H - 6, H - 2, C.Yellow, M.Neon, true)
	Builder.streamable(m)
	return m
end

-- Recoger: montones de chips y cajas rotas de luz embotellada
function Kit.gather(ctx: any, parent: Instance, g: { [string]: any })
	if g.Item == "Vertice_LuzEmbotellada" then
		ctx.box(parent, "Caja", g.X - 1.6, g.X + 1.6, g.Z - 1.2, g.Z + 1.2, 0.9, 3, rgb(90, 80, 70), M.WoodPlanks, true)
		for k = 0, 2 do
			local bottle = ctx.column(parent, "Botella" .. k, ctx.W(g.X - 0.9 + k * 0.9, g.Z, 3), 1.4, 0.6, rgb(255, 240, 170), M.Neon, true)
			bottle.Transparency = 0.2
		end
		return
	end
	for k = 0, 4 do
		ctx.box(parent, "Chatarra" .. k, g.X - 1.5 + (k % 3), g.X - 0.3 + (k % 3), g.Z - 1 + k * 0.4, g.Z + k * 0.4, 0.9, 1.4 + k * 0.3, if k % 2 == 0 then rgb(40, 120, 60) else rgb(80, 84, 96), M.Metal, true)
	end
end

-- Lo propio de Distrito Cero: la estatua del Primer Cliente, las cámaras, hologramas y anuncios
function Kit.extras(ctx: any, model: Model)
	local m = Builder.model("DistritoCero", model)
	-- La estatua del Primer Cliente: un señor de bronce sonriente con su bolsa de la compra
	local sx, sz = 0, 92
	ctx.column(m, "Pedestal", ctx.W(sx, sz, 0.9), 3, 10, rgb(220, 222, 230), M.Marble)
	local plinth = ctx.column(m, "Aro", ctx.W(sx, sz, 3.9), 0.4, 10.4, C.Yellow, M.Neon, true)
	glowAtNight(plinth, C.Yellow, C.Yellow)
	local base = 3.9
	ctx.box(m, "Piernas", sx - 1.2, sx + 1.2, sz - 0.7, sz + 0.7, base, base + 4.6, C.Bronze, M.Metal)
	ctx.box(m, "Torso", sx - 1.8, sx + 1.8, sz - 1, sz + 1, base + 4.6, base + 8.6, C.Bronze, M.Metal)
	ctx.ball(m, "Cabeza", ctx.W(sx, sz, base + 10), 2.6, C.Bronze, M.Metal)
	ctx.box(m, "Sonrisa", sx - 0.7, sx + 0.7, sz - 1.32, sz - 1.22, base + 9.5, base + 9.8, rgb(250, 250, 250), M.Neon, true)
	ctx.box(m, "Brazo", sx + 1.8, sx + 2.6, sz - 0.4, sz + 0.4, base + 5, base + 8.4, C.Bronze, M.Metal, true)
	ctx.box(m, "Bolsa", sx + 2.2, sx + 4.2, sz - 0.8, sz + 0.8, base + 3.2, base + 5.6, C.Bronze, M.Metal, true)
	ctx.box(m, "BrazoSaludo", sx - 2.6, sx - 1.8, sz - 0.4, sz + 0.4, base + 8, base + 11.4, C.Bronze, M.Metal, true)
	ctx.sign(m, "EL PRIMER CLIENTE · GRACIAS POR ELEGIRNOS", ctx.CF(sx, sz - 5.1, 2.4, math.pi), 9, 1.2)
	-- Las cámaras de MegaVerso (poste, cabeza y piloto rojo): las que suben la vigilancia
	for i, c in ctx.City.Cameras do
		ctx.box(m, "PosteCamara" .. i, c.X - 0.25, c.X + 0.25, c.Z - 0.25, c.Z + 0.25, 0.9, 9, C.Steel, M.Metal, true)
		ctx.box(m, "Camara" .. i, c.X - 0.6, c.X + 0.6, c.Z - 1.2, c.Z + 0.6, 8.6, 9.6, C.White, M.SmoothPlastic, true)
		local pilot = ctx.ball(m, "Piloto" .. i, ctx.W(c.X, c.Z - 1.3, 9.1), 0.5, C.Red, M.Neon, true)
		glowAtNight(pilot, C.Red, C.Red, 0, 99)
	end
	-- Hologramas de oferta flotando sobre la plaza y la Avenida (paneles de dos caras)
	for i, h in { { -30, 60, "−50 % · SOLO HOY" }, { 30, 128, "PUNTÚA A TU VECINO" }, { -110, 74, "OFERTA RELÁMPAGO" }, { -136, 110, "TODO DEBE IRSE" }, { 100, 60, "TU CASA, NUESTRA CASA" } } do
		local panel = Builder.decor({ Name = "Holo" .. i, Size = V3(11, 4.4, 0.2), CFrame = ctx.CF(h[1], h[2], 11, if i % 2 == 0 then 0 else math.pi), Color = neonOf(i), Material = M.Neon, Transparency = 0.6, Parent = m })
		Builder.sign(panel, h[3], Enum.NormalId.Front, rgb(255, 255, 255))
		Builder.sign(panel, h[3], Enum.NormalId.Back, rgb(255, 255, 255))
		ctx.column(m, "Emisor" .. i, ctx.W(h[1], h[2], 0.9), 1.6, 1.2, C.Steel, M.Metal, true)
	end
	-- Árboles de plástico en macetas (algunos han «mutado» con la luz)
	for i, p in { { -52, 124 }, { 52, 64 }, { -52, 64 }, { -70, 108 }, { 144, 136 } } do
		ctx.column(m, "Maceta" .. i, ctx.W(p[1], p[2], 0.9), 1.6, 4, C.White, M.SmoothPlastic, true)
		ctx.box(m, "TroncoPlastico" .. i, p[1] - 0.3, p[1] + 0.3, p[2] - 0.3, p[2] + 0.3, 2.5, 7, rgb(200, 190, 210), M.SmoothPlastic, true)
		ctx.ball(m, "CopaPlastico" .. i, ctx.W(p[1], p[2], 8), 4.4, if i == 4 then C.Yellow else rgb(90, 230, 170), M.SmoothPlastic, true)
	end
	-- La puerta trasera del Rastro: señales amarillas pintadas a mano
	ctx.sign(m, "↓ EL RASTRO · AQUÍ SE HABLA ALTO", ctx.CF(-104, -10.6, 4, math.pi), 10, 1.4, rgb(30, 26, 20), C.Yellow)
	Builder.streamable(m)
end

-- Basura del Nivel Bajo: montones de pantallas y carros
function Kit.decor(folder: Instance, d: { [string]: any })
	local m = Builder.model(d.Kind, folder)
	local s = 2 + d.Size * 0.25
	for k = 0, 2 do
		Builder.decor({ Name = "Trasto", Size = V3(s, s * 0.5, s * 0.7), CFrame = CFrame.new(d.Pos + V3((k - 1) * s * 0.5, s * 0.25 + k * s * 0.3, 0)) * CFrame.Angles(0, d.Turn + k, math.rad(10 * k)), Color = if k == 1 then rgb(40, 40, 54) else rgb(90, 86, 96), Material = M.Metal, Parent = m })
	end
end

-- Los puntos de interés del Nivel Bajo
function Kit.poi(model: Model, p: { [string]: any }, at: Vector3): BasePart?
	if p.Id == "Vertice_Vertedero" then
		local main: BasePart? = nil
		for k = 0, 4 do
			local pile = Builder.part({ Name = "Monte" .. k, Shape = Enum.PartType.Ball, Size = V3(26 - k * 3, 14 - k, 22 - k * 2), CFrame = CFrame.new(at + V3(-30 + k * 16, 2, (k % 2) * 14 - 7)), Color = rgb(70 + k * 6, 66, 72), Material = M.CorrodedMetal, Parent = model })
			main = main or pile
		end
		for k = 0, 3 do
			local screen = Builder.decor({ Name = "PantallaRota" .. k, Size = V3(6, 4, 0.4), CFrame = CFrame.new(at + V3(-20 + k * 14, 9, -4)) * CFrame.Angles(math.rad(20), k, math.rad(15)), Color = neonOf(k), Material = M.Neon, Transparency = 0.4, Parent = model })
			glowAtNight(screen, screen.Color, screen.Color)
		end
		return main
	elseif p.Id == "Vertice_Cementerio" then
		local main: BasePart? = nil
		for k = 0, 4 do
			local board = Builder.part({ Name = "Cartel" .. k, Size = V3(26, 12, 1), CFrame = CFrame.new(at + V3(-40 + k * 20, 14 + (k % 2) * 4, k * 3)) * CFrame.Angles(0, math.rad(10 * k), math.rad(if k == 2 then 12 else 0)), Color = neonOf(k + 1):Lerp(rgb(40, 40, 50), 0.5), Material = M.SmoothPlastic, Parent = model })
			Builder.part({ Name = "Pata" .. k, Size = V3(1.2, 14, 1.2), CFrame = CFrame.new(at + V3(-40 + k * 20, 7, k * 3)), Color = C.Steel, Material = M.Metal, Parent = model })
			main = main or board
		end
		return main
	elseif p.Id == "Vertice_Central" then
		local main = Builder.part({ Name = "Central", Size = V3(50, 30, 34), CFrame = CFrame.new(at + V3(0, 15, 0)), Color = rgb(60, 60, 70), Material = M.Concrete, Parent = model })
		for k = 0, 2 do
			local chimney = Builder.part({ Name = "Torre" .. k, Shape = Enum.PartType.Cylinder, Size = V3(40, 8, 8), CFrame = CFrame.new(at + V3(-16 + k * 16, 40, 10)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(80, 80, 90), Material = M.Concrete, Parent = model })
			local glow = Builder.decor({ Name = "Luz" .. k, Shape = Enum.PartType.Ball, Size = V3(6, 6, 6), CFrame = chimney.CFrame * CFrame.new(20, 0, 0), Color = rgb(255, 240, 170), Material = M.Neon, Parent = model })
			glowAtNight(glow, glow.Color, glow.Color, 0, 99)
		end
		return main
	end
	return nil
end

-- Lo de fuera: el horizonte de torres del resto de Vértice (una caja y una línea de luz cada una), los
-- carriles del tráfico aéreo, los paneles de la Cúpula y los anillos de los Astilleros Orbitales.
function Kit.world(folder: Instance, S: any)
	local m = Instance.new("Folder")
	m.Name = "CieloVertice"
	m.Parent = folder
	local O = S.Origin
	local ground = O.Y + 30
	local r = S.rng(4242)
	-- El horizonte: torres alrededor del barrio, más altas cuanto más lejos
	for k = 0, 47 do
		local a = k / 48 * math.pi * 2 + r() * 0.08
		local dist = 300 + r() * 520
		local x, z = O.X + math.cos(a) * dist, O.Z + math.sin(a) * dist
		local w = 26 + r() * 30
		local h = 80 + r() * 220 + dist * 0.12
		Builder.decor({ Name = "Torre" .. k, Size = V3(w, h, w * (0.7 + r() * 0.6)), CFrame = CFrame.new(x, ground + h / 2, z) * CFrame.Angles(0, a, 0), Color = if k % 3 == 0 then rgb(40, 44, 66) else rgb(26, 28, 44), Material = M.Glass, Parent = m })
		local stripe = Builder.decor({ Name = "Linea" .. k, Size = V3(w + 0.4, 1.2, 1), CFrame = CFrame.new(x, ground + h * (0.4 + r() * 0.5), z) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -w * 0.4), Color = neonOf(k), Material = M.Neon, Parent = m })
		glowAtNight(stripe, stripe.Color, stripe.Color, 0, 99)
	end
	-- Los carriles del tráfico aéreo (líneas de luz flotando a dos alturas, con lanzaderas quietas)
	for lane = 0, 3 do
		local y = O.Y + S.padY() + 50 + lane * 35
		local horizontal = lane % 2 == 0
		local off = (lane - 1.5) * 180
		local cf = if horizontal then CFrame.new(O.X, y, O.Z + off) else CFrame.new(O.X + off, y, O.Z)
		local size = if horizontal then V3(1800, 0.6, 3) else V3(3, 0.6, 1800)
		Builder.decor({ Name = "Carril" .. lane, Size = size, CFrame = cf, Color = neonOf(lane), Material = M.Neon, Transparency = 0.5, Parent = m })
		for s = -2, 2 do
			local p = if horizontal then V3(s * 220 + lane * 30, 2, 0) else V3(0, 2, s * 220 + lane * 30)
			Builder.decor({ Name = "Lanzadera" .. lane .. s, Size = if horizontal then V3(9, 3, 4) else V3(4, 3, 9), CFrame = cf + p, Color = C.White, Material = M.SmoothPlastic, Parent = m })
		end
	end
	-- La Cúpula: paneles de anuncio colgados del «cielo» falso
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = O + V3(math.cos(a) * 700, 620, math.sin(a) * 700)
		local panel: BasePart = Builder.decor({ Name = "PanelCupula" .. k, Size = V3(220, 90, 4), CFrame = CFrame.new(p, O + V3(0, 300, 0)), Color = neonOf(k + 2):Lerp(rgb(255, 255, 255), 0.3), Material = M.Neon, Transparency = 0.55, Parent = m })
		glowAtNight(panel, panel.Color, panel.Color, 7, 23) -- (la Cúpula se apaga a las 23:00)
	end
	-- Los anillos de los Astilleros Orbitales: un aro inclinado de segmentos en lo alto del cielo
	local center = O + V3(-300, 1400, -1600)
	local ringR = 900
	local tilt = CFrame.Angles(math.rad(68), math.rad(20), 0)
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local seg = 2 * math.pi * ringR / 24 + 4
		local cf = CFrame.new(center) * tilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -ringR)
		Builder.decor({ Name = "Anillo" .. k, Size = V3(seg, 6, 22), CFrame = cf, Color = if k % 4 == 0 then rgb(255, 210, 120) else rgb(200, 190, 230), Material = M.Neon, Transparency = 0.35, CastShadow = false, Parent = m })
	end
end

return Kit
