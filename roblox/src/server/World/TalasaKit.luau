-- TalasaKit (servidor): las formas, colores y luces de ABISALIA, la capital de Tálasa (el KIT del marco
-- común: World/PlanetCityBuilder lo usa con el plano shared/Cosmos/TalasaCity; docs/planetas/talasa-vertice.md).
--
-- Arquitectura del mar: cubiertas blancas sobre PILOTES que bajan al agua, balsas de madera con toldos de
-- lona, cristal blanco de laboratorio con franjas turquesa, el Faro de Mareas con su anillo de luz, y en
-- el cielo verde azulado TRES LUNAS y el Archipiélago Suspendido con sus cascadas. Nada de basalto ni de
-- yeso malva (eso es Tefra). Todo con piezas (sin mallas nuevas) y casi todo de adorno (sin colisión).
--
-- Lo de la ciudad se dibuja a Y = 0 (la cubierta) y PlanetCityBuilder lo sube a la meseta; lo de fuera
-- (kit.poi, kit.decor, kit.world) va en coordenadas del mundo.

local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Kit.Palette)

local Kit = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB
local M = Enum.Material

local C = {
	White = rgb(236, 242, 244),
	Pearl = rgb(214, 226, 230),
	Turq = rgb(52, 196, 190),
	TurqDeep = rgb(24, 120, 128),
	Deep = rgb(22, 52, 86),
	Glass = rgb(150, 220, 226),
	Wood = rgb(150, 112, 78),
	WoodDark = rgb(104, 76, 54),
	Canvas = rgb(232, 220, 196),
	CanvasB = rgb(214, 120, 90),
	Rope = rgb(196, 170, 120),
	Coral = rgb(236, 130, 140),
	CoralBlack = rgb(26, 20, 30),
	CoralPulse = rgb(110, 50, 170),
	Lamp = rgb(170, 255, 236),
	Stilt = rgb(120, 136, 140),
}
Kit.Colors = {
	Metal = rgb(140, 156, 160),
	Lamp = C.Lamp,
	Floor = C.White,
	FloorMaterial = M.SmoothPlastic,
	Light = rgb(200, 255, 246),
	Sign = C.Deep,
	SignText = rgb(170, 255, 240),
	Wall = C.White,
	Pad = rgb(220, 230, 232),
	PadRing = C.Turq,
	PadLight = rgb(180, 255, 245),
	Poi = C.Pearl,
	PoiLight = C.Lamp,
}

-- Estilos de edificio (Kit/Building): blanco de laboratorio con cristal turquesa; las compuertas, de
-- metal pintado con ojos de buey. (Se apuntan al cargar el kit: nada en Kit/Palette de los demás.)
Palette.Styles.TalasaLab = {
	Wall = { rgb(238, 244, 246), rgb(228, 238, 240), rgb(244, 248, 248) },
	WallMaterial = M.SmoothPlastic,
	Trim = C.Turq,
	TrimMaterial = M.Glass,
	Glass = rgb(90, 190, 196),
	Bay = 7,
	WindowW = 5.6,
	WindowH = 6,
	Lintels = false,
	Shutters = nil,
	Balconies = "Glass",
	Roof = "Flat",
	Curtain = true,
}
Palette.Styles.TalasaBlanco = {
	Wall = { rgb(240, 244, 242), rgb(226, 236, 236), rgb(214, 230, 232) },
	WallMaterial = M.SmoothPlastic,
	Trim = rgb(70, 170, 176),
	TrimMaterial = M.Metal,
	Glass = rgb(70, 160, 176),
	Bay = 8,
	WindowW = 4.6,
	WindowH = 5,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.TalasaCompuerta = {
	Wall = { rgb(232, 196, 70), rgb(222, 186, 64) },
	WallMaterial = M.Metal,
	Trim = rgb(40, 52, 60),
	TrimMaterial = M.DiamondPlate,
	Glass = rgb(60, 140, 170),
	Bay = 6,
	WindowW = 2.4,
	WindowH = 2.4,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}

local DECK_DEPTH = 30 -- (los pilotes bajan del todo bajo el agua)

local function glowAtNight(p: BasePart, day: Color3, night: Color3, on: number?, off: number?)
	p:AddTag("NightWindow")
	p:SetAttribute("DayColor", day)
	p:SetAttribute("NightColor", night)
	p:SetAttribute("OnAt", on or 18)
	p:SetAttribute("OffAt", off or 30)
end

local function stilt(ctx: any, parent: Instance, lx: number, lz: number, d: number?)
	ctx.column(parent, "Pilote", ctx.W(lx, lz, -DECK_DEPTH), DECK_DEPTH - 0.2, d or 2.2, C.Stilt, M.Concrete, true)
end

local function posts(ctx: any, parent: Instance, x0: number, x1: number, z0: number, z1: number, gap: number)
	local nx = math.max(1, math.floor((x1 - x0) / gap + 0.5))
	local nz = math.max(1, math.floor((z1 - z0) / gap + 0.5))
	for i = 0, nx do
		local x = x0 + 1.5 + (x1 - x0 - 3) * i / nx
		stilt(ctx, parent, x, z0 + 1.5)
		stilt(ctx, parent, x, z1 - 1.5)
	end
	for k = 1, nz - 1 do
		local z = z0 + 1.5 + (z1 - z0 - 3) * k / nz
		stilt(ctx, parent, x0 + 1.5, z)
		stilt(ctx, parent, x1 - 1.5, z)
	end
end

-- Las cubiertas: tablero, canto turquesa y pilotes; las balsas, de tablones con flotadores
function Kit.floor(ctx: any, parent: Instance, f: { [string]: any }): boolean
	local top = 0.9
	local m = Builder.model(f.Id or "Cubierta", parent)
	if f.Kind == "Disc" then
		local topY = if f.Deck == "Plataforma" then 0.45 else top -- (la plataforma de la nave asoma por encima)
		ctx.column(m, "Tablero", ctx.W(f.X, f.Z, -1.6), topY + 1.6, f.R * 2, C.White, M.SmoothPlastic)
		ctx.column(m, "Canto", ctx.W(f.X, f.Z, -2.2), 1.0, f.R * 2 + 1.2, C.Turq, M.Glass, true)
		local n = math.max(6, math.floor(f.R * 2 * math.pi / 26))
		for i = 1, n do
			local a = i / n * math.pi * 2
			stilt(ctx, m, f.X + math.cos(a) * (f.R - 3), f.Z + math.sin(a) * (f.R - 3), 3)
		end
		stilt(ctx, m, f.X, f.Z, 6)
		return true
	end
	local x0, x1, z0, z1 = f.X0, f.X1, f.Z0, f.Z1
	if f.Deck == "Balsa" then
		ctx.box(m, "Tablones", x0, x1, z0, z1, -1.2, top, C.Wood, M.WoodPlanks)
		ctx.box(m, "Borde", x0 - 0.6, x1 + 0.6, z0 - 0.6, z1 + 0.6, -1.9, -1.1, C.WoodDark, M.Wood, true)
		-- flotadores (bidones) en las esquinas y el medio
		for _, p in { { x0 + 3, z0 + 3 }, { x1 - 3, z0 + 3 }, { x0 + 3, z1 - 3 }, { x1 - 3, z1 - 3 }, { (x0 + x1) / 2, (z0 + z1) / 2 } } do
			Builder.decor({ Name = "Flotador", Shape = Enum.PartType.Cylinder, Size = V3(5, 4, 4), CFrame = ctx.CF(p[1], p[2], -12.6) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(220, 100, 60), Material = M.SmoothPlastic, Parent = m })
			stilt(ctx, m, p[1], p[2], 1.4)
		end
		return true
	end
	local color = if f.Deck == "Jardin" then rgb(210, 232, 220) elseif f.Deck == "Muelle" then rgb(196, 204, 204) else C.White
	local material = if f.Deck == "Muelle" then M.DiamondPlate elseif f.Deck == "Plaza" then M.Marble else M.SmoothPlastic
	ctx.box(m, "Tablero", x0, x1, z0, z1, -1.4, top, color, material)
	if f.Deck == "Plaza" then
		-- el suelo de la plaza: un mosaico de olas turquesa
		for i = 0, 3 do
			local zz = z0 + 10 + i * ((z1 - z0 - 20) / 3)
			ctx.box(m, "Ola", x0 + 6, x1 - 6, zz - 0.6, zz + 0.6, top - 0.02, top + 0.04, C.Turq, M.Glass, true)
		end
	end
	ctx.box(m, "Canto", x0 - 0.3, x1 + 0.3, z0 - 0.3, z1 + 0.3, -2.0, -1.2, C.TurqDeep, M.Metal, true)
	posts(ctx, m, x0, x1, z0, z1, if f.Deck == "Pasarela" then 30 else 26)
	return true
end

-- Farola del puerto: mástil blanco con farol de cristal turquesa
function Kit.lamp(_ctx: any, parent: Instance, cf: CFrame)
	local m = Builder.model("StreetLamp", parent)
	Builder.part({ Name = "Pie", Size = V3(1.2, 0.6, 1.2), CFrame = cf * CFrame.new(0, 0.3, 0), Color = C.TurqDeep, Material = M.Metal, Parent = m })
	Builder.part({ Name = "Mastil", Shape = Enum.PartType.Cylinder, Size = V3(9, 0.5, 0.5), CFrame = cf * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = C.White, Material = M.SmoothPlastic, Parent = m })
	local bulb = Builder.decor({ Name = "Farol", Shape = Enum.PartType.Ball, Size = V3(1.8, 1.8, 1.8), CFrame = cf * CFrame.new(0, 10, 0), Color = C.Lamp, Material = M.Glass, Transparency = 0.15, Tags = { "StreetLamp" }, Parent = m })
	local light = Instance.new("PointLight")
	light.Range = 28
	light.Brightness = 1.4
	light.Color = C.Lamp
	light.Shadows = false
	light.Enabled = false
	light.Parent = bulb
	return m
end

-- Lo de los edificios Box: franja turquesa en la cornisa (se enciende de noche) y lo de cada uno
function Kit.dressBox(_ctx: any, model: Model, b: { [string]: any }, cf: CFrame, info: { [string]: any })
	local w, d = b.W or 20, b.D or 20
	local top = info.Top or 14
	local band = Builder.decor({ Name = "Franja", Size = V3(w + 0.6, 0.6, d + 0.6), CFrame = cf * CFrame.new(0, top + 0.2, 0), Color = C.Turq, Material = M.Neon, Parent = model })
	glowAtNight(band, C.Turq, rgb(120, 255, 236))
	if b.Kind == "Compuerta" then
		-- la rueda de la puerta estanca, encima del dintel
		Builder.decor({ Name = "Rueda", Shape = Enum.PartType.Cylinder, Size = V3(0.4, 3, 3), CFrame = cf * CFrame.new(0, info.GroundTop + 1.4, -d / 2 - 0.4) * CFrame.Angles(0, math.pi / 2, 0), Color = rgb(200, 60, 50), Material = M.Metal, Parent = model })
	elseif b.Kind == "Laboratorio" then
		-- cúpula de cristal sobre el tejado (el observatorio)
		Builder.decor({ Name = "Cupula", Shape = Enum.PartType.Ball, Size = V3(14, 14, 14), CFrame = cf * CFrame.new(-w / 4, top + 0.5, 0), Color = C.Glass, Material = M.Glass, Transparency = 0.45, Parent = model })
		Builder.decor({ Name = "Telescopio", Shape = Enum.PartType.Cylinder, Size = V3(7, 1.4, 1.4), CFrame = cf * CFrame.new(-w / 4, top + 4, 0) * CFrame.Angles(0, 0, math.rad(55)), Color = C.Deep, Material = M.Metal, Parent = model })
	end
	Builder.streamable(model)
end

Kit.Shapes = {}

-- El Faro de Mareas (el Consejo): torre blanca escalonada, galería, anillo de luz y la linterna
function Kit.Shapes.Faro(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local R, H = b.R or 13, b.Height or 78
	local seg = 6
	for i = 0, seg - 1 do
		local y0 = i * H * 0.8 / seg
		local r = R * (1 - i * 0.07)
		ctx.column(m, "Torre" .. i, ctx.W(b.X, b.Z, y0), H * 0.8 / seg + 0.05, r * 2, if i % 2 == 0 then C.White else C.Pearl, M.SmoothPlastic)
		if i % 2 == 1 then
			ctx.column(m, "Banda" .. i, ctx.W(b.X, b.Z, y0 + 2), 1.2, r * 2 + 0.4, C.Turq, M.Neon, true)
		end
	end
	local gy = H * 0.8
	ctx.column(m, "Galeria", ctx.W(b.X, b.Z, gy), 1.2, R * 2.1, C.Deep, M.Metal)
	ctx.column(m, "Barandilla", ctx.W(b.X, b.Z, gy + 1.2), 2.2, R * 2.1 - 0.2, C.Glass, M.Glass, true)
	local lantern = ctx.column(m, "Linterna", ctx.W(b.X, b.Z, gy + 1.2), H * 0.13, R * 1.1, C.Lamp, M.Glass, true)
	lantern.Transparency = 0.25
	local core = ctx.ball(m, "Luz", ctx.W(b.X, b.Z, gy + 1.2 + H * 0.065), R * 0.8, rgb(240, 255, 250), M.Neon, true)
	ctx.light(core, rgb(200, 255, 245), 60, 2.5)
	ctx.column(m, "Techo", ctx.W(b.X, b.Z, gy + 1.2 + H * 0.13), 2, R * 1.4, C.Deep, M.Metal, true)
	ctx.ball(m, "Remate", ctx.W(b.X, b.Z, gy + 3.6 + H * 0.13), 2.4, C.Turq, M.Neon, true)
	-- el anillo de luz de la marea (flota alrededor, a media torre)
	ctx.column(m, "AnilloMarea", ctx.W(b.X, b.Z, H * 0.45), 0.8, R * 3.2, rgb(110, 240, 230), M.Neon, true).Transparency = 0.35
	-- la puerta del Consejo
	ctx.box(m, "Puerta", b.X - 3, b.X + 3, b.Z - R - 0.4, b.Z - R + 1, 0.9, 9, C.Deep, M.Glass, true)
	ctx.sign(m, "CONSEJO DE MAREAS", ctx.CF(b.X, b.Z - R - 0.6, 11.5, math.pi), 14, 2)
	Builder.streamable(m)
	return m
end

-- La antena del sónar: mástil, riostras y un plato
function Kit.Shapes.Antena(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local H = b.Height or 40
	ctx.column(m, "Base", ctx.W(b.X, b.Z, 0.9), 2, (b.R or 6) * 2, C.Pearl, M.Concrete)
	ctx.column(m, "Mastil", ctx.W(b.X, b.Z, 2.9), H, 1.6, C.White, M.Metal)
	for k = 0, 2 do
		local a = k * math.pi * 2 / 3
		Builder.decor({ Name = "Riostra", Size = V3(0.4, H * 0.7, 0.4), CFrame = ctx.CF(b.X + math.cos(a) * 2.6, b.Z + math.sin(a) * 2.6, 2.9 + H * 0.35) * CFrame.Angles(math.sin(a) * 0.08, 0, -math.cos(a) * 0.08), Color = C.Stilt, Material = M.Metal, Parent = m })
	end
	Builder.decor({ Name = "Plato", Shape = Enum.PartType.Cylinder, Size = V3(1, 12, 12), CFrame = ctx.CF(b.X, b.Z, 2.9 + H * 0.82) * CFrame.Angles(0, 0, math.rad(60)), Color = C.White, Material = M.SmoothPlastic, Parent = m })
	local tip = ctx.ball(m, "Baliza", ctx.W(b.X, b.Z, 3.2 + H), 1.4, rgb(255, 80, 80), M.Neon, true)
	glowAtNight(tip, tip.Color, rgb(255, 60, 60))
	Builder.streamable(m)
	return m
end

-- La boca del Tubo: un cilindro de cristal con su tubo que baja al mar
function Kit.Shapes.Tubo(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local R, H = b.R or 9, b.Height or 14
	ctx.column(m, "Anden", ctx.W(b.X, b.Z, 0.9), 0.4, R * 2, C.Pearl, M.Marble)
	local glass = ctx.column(m, "Cristal", ctx.W(b.X, b.Z, 1.3), H, R * 2, C.Glass, M.Glass)
	glass.Transparency = 0.55
	ctx.column(m, "Tapa", ctx.W(b.X, b.Z, 1.3 + H), 1, R * 2 + 0.6, C.White, M.SmoothPlastic)
	local ring = ctx.column(m, "Aro", ctx.W(b.X, b.Z, 1.3 + H - 1.6), 0.6, R * 2 + 0.3, C.Turq, M.Neon, true)
	glowAtNight(ring, C.Turq, rgb(140, 255, 240))
	-- el tubo de cristal que se hunde en el mar hacia la Cúpula Honda (dos tramos)
	for i, seg in { { 0, -8, 18 }, { -22, -24, 26 } } do
		local from = ctx.W(b.X - R + seg[1], b.Z, seg[2])
		Builder.decor({ Name = "TuboCristal" .. i, Shape = Enum.PartType.Cylinder, Size = V3(seg[3], 6, 6), CFrame = CFrame.new(from + V3(-seg[3] / 2, 0, 0)) * CFrame.Angles(0, 0, math.rad(if i == 1 then 35 else 20)), Color = C.Glass, Material = M.Glass, Transparency = 0.5, Parent = m })
	end
	ctx.sign(m, "EL TUBO", ctx.CF(b.X, b.Z + R + 0.4, H - 1, 0), 8, 1.8)
	Builder.streamable(m)
	return m
end

-- El Mercado del Arrecife: una cúpula de cristal medio hundida, con el coral negro trepando
function Kit.Shapes.Domo(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local R = b.R or 12
	ctx.column(m, "Zocalo", ctx.W(b.X, b.Z, 0.9), 1.4, R * 2, C.Pearl, M.Concrete)
	local dome = ctx.ball(m, "Cupula", ctx.W(b.X, b.Z, 2.3), R * 2, C.Glass, M.Glass)
	dome.Transparency = 0.4
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local p = ctx.W(b.X + math.cos(a) * R * 0.8, b.Z + math.sin(a) * R * 0.8, 2.5 + (k % 3) * 1.5)
		ctx.ball(m, "CoralNegro", p, 2.6 + (k % 2) * 1.6, C.CoralBlack, M.Slate, true)
		if k % 2 == 0 then
			local pulse = ctx.ball(m, "Pulso", p + V3(0, 1.4, 0), 0.9, C.CoralPulse, M.Neon, true)
			pulse:SetAttribute("CoralPulse", true)
		end
	end
	ctx.box(m, "Cinta", b.X - R, b.X + R, b.Z - R - 1.4, b.Z - R - 1.0, 2.5, 3.1, rgb(250, 210, 50), M.SmoothPlastic, true)
	ctx.sign(m, "CERRADO · CUARENTENA", ctx.CF(b.X, b.Z - R - 1.6, 4.6, math.pi), 10, 1.6, rgb(250, 210, 50), rgb(30, 30, 30))
	Builder.streamable(m)
	return m
end

-- Casita de balsa: caseta de tablas, toldo de lona a dos aguas y un farolillo
function Kit.Shapes.Balsa(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local R, H = b.R or 8, b.Height or 10
	local yaw = ((b.X * 7 + b.Z * 3) % 4) * math.pi / 2
	local cf = ctx.CF(b.X, b.Z, 0.9, yaw)
	local w = R * 1.6
	local bruma = b.Id:find("Bruma") ~= nil
	Builder.part({ Name = "Caseta", Size = V3(w, H * 0.6, w * 0.8), CFrame = cf * CFrame.new(0, H * 0.3, 0), Color = if bruma then rgb(90, 110, 130) else C.Wood, Material = M.WoodPlanks, Parent = m })
	for side = -1, 1, 2 do
		Builder.decor({ Name = "Toldo", Size = V3(w + 2, 0.3, w * 0.6), CFrame = cf * CFrame.new(0, H * 0.72, side * w * 0.22) * CFrame.Angles(side * math.rad(28), 0, 0), Color = if (b.X + b.Z) % 2 == 0 then C.Canvas else C.CanvasB, Material = M.Fabric, Parent = m })
	end
	Builder.decor({ Name = "Puerta", Size = V3(2.6, 5, 0.3), CFrame = cf * CFrame.new(0, 2.5, -w * 0.4 - 0.1), Color = C.WoodDark, Material = M.Wood, Parent = m })
	local lantern = Builder.decor({ Name = "Farolillo", Shape = Enum.PartType.Ball, Size = V3(1, 1, 1), CFrame = cf * CFrame.new(w * 0.35, 5.6, -w * 0.4 - 0.6), Color = rgb(140, 110, 80), Material = M.Neon, Parent = m })
	glowAtNight(lantern, rgb(140, 110, 80), rgb(255, 200, 120), 18.5, 29)
	-- cuerda de perlas (una por desaparecido) en la balsa de Bruma
	if bruma then
		for i = 0, 5 do
			Builder.decor({ Name = "Perla", Shape = Enum.PartType.Ball, Size = V3(0.6, 0.6, 0.6), CFrame = cf * CFrame.new(-w * 0.3 + i * 0.9, 6.4 - math.sin(i / 5 * math.pi) * 0.8, -w * 0.4 - 0.3), Color = rgb(250, 248, 240), Material = M.SmoothPlastic, Parent = m })
		end
	end
	Builder.streamable(m)
	return m
end

-- El taller de submarinos: nave de chapa abierta al mar con un submarino amarillo en grada
function Kit.Shapes.Hangar(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local H = b.Height or 16
	ctx.box(m, "ParedFondo", x0, x1, z1 - 1, z1, 0.9, H, rgb(200, 210, 214), M.CorrodedMetal)
	ctx.box(m, "ParedO", x0, x0 + 1, z0, z1, 0.9, H, rgb(200, 210, 214), M.CorrodedMetal)
	ctx.box(m, "ParedE", x1 - 1, x1, z0, z1, 0.9, H, rgb(200, 210, 214), M.CorrodedMetal)
	ctx.box(m, "Techo", x0 - 1, x1 + 1, z0 - 2, z1 + 1, H, H + 1, C.Deep, M.Metal)
	local band = ctx.box(m, "Franja", x0 - 1, x1 + 1, z0 - 2.1, z0 - 1.9, H - 1.6, H - 0.4, C.Turq, M.Neon, true)
	glowAtNight(band, C.Turq, rgb(120, 255, 236))
	-- el submarino (casco, torreta, ojo de buey)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2 + 2
	Builder.decor({ Name = "Casco", Shape = Enum.PartType.Cylinder, Size = V3(20, 7, 7), CFrame = ctx.CF(cx, cz, 5.4), Color = rgb(240, 196, 50), Material = M.SmoothPlastic, Parent = m })
	ctx.ball(m, "Morro", ctx.W(cx - 10, cz, 5.4), 7, rgb(240, 196, 50), M.SmoothPlastic, true)
	ctx.box(m, "Torreta", cx - 2, cx + 2.6, cz - 1.6, cz + 1.6, 8, 11.5, rgb(230, 186, 46), M.SmoothPlastic, true)
	ctx.ball(m, "Ojo", ctx.W(cx - 12.6, cz, 5.6), 2.2, C.Glass, M.Glass, true)
	ctx.box(m, "Grada", cx - 8, cx + 8, cz - 3, cz + 3, 0.9, 2.2, C.Stilt, M.DiamondPlate)
	ctx.sign(m, "TALLER DE SUBMARINOS", ctx.CF(cx, z0 - 2.2, H - 3.2, math.pi), 18, 2.2)
	Builder.streamable(m)
	return m
end

-- Recoger: cestos de algas de luz y nácar en los pilotes
function Kit.gather(ctx: any, parent: Instance, g: { [string]: any })
	if g.Item == "Talasa_Nacar" then
		ctx.column(parent, "PiloteNacar", ctx.W(g.X, g.Z, 0.9), 4, 2.4, rgb(232, 226, 240), M.Foil, true)
		return
	end
	ctx.column(parent, "Cesto", ctx.W(g.X, g.Z, 0.9), 1.6, 3, C.Rope, M.Fabric, true)
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		ctx.ball(parent, "AlgaLuz", ctx.W(g.X + math.cos(a) * 0.8, g.Z + math.sin(a) * 0.8, 2.6), 1.2, rgb(120, 255, 190), M.Neon, true)
	end
end

-- Lo propio de Abisalia: la Fuente de las Perlas, hologramas, barcas amarradas y la escalerilla de buceo
function Kit.extras(ctx: any, model: Model)
	local m = Builder.model("Abisalia", model)
	-- La Fuente de las Perlas (el monumento de la plaza): vaso, columna de agua y aros de perlas
	local fx, fz = 0, 86
	ctx.column(m, "VasoFuente", ctx.W(fx, fz, 0.9), 1.6, 18, C.Pearl, M.Marble)
	local agua = ctx.column(m, "AguaFuente", ctx.W(fx, fz, 2.4), 0.3, 16.4, rgb(60, 200, 210), M.Glass, true)
	agua.Transparency = 0.3
	local chorro = ctx.column(m, "Chorro", ctx.W(fx, fz, 2.4), 9, 1.6, rgb(160, 240, 245), M.Glass, true)
	chorro.Transparency = 0.45
	for ring = 1, 2 do
		local n, r, y = if ring == 1 then 12 else 8, if ring == 1 then 6.2 else 3.4, if ring == 1 then 3 else 7
		for k = 1, n do
			local a = k / n * math.pi * 2
			ctx.ball(m, "PerlaFuente", ctx.W(fx + math.cos(a) * r, fz + math.sin(a) * r, y), if ring == 1 then 1.1 else 0.8, rgb(250, 246, 236), M.SmoothPlastic, true)
		end
	end
	local glow = ctx.ball(m, "LuzFuente", ctx.W(fx, fz, 11.6), 1.8, rgb(170, 255, 236), M.Neon, true)
	ctx.light(glow, rgb(170, 255, 236), 26, 1.2)
	-- Hologramas de la plaza (paneles flotantes con avisos del Consejo)
	for i, h in { { -42, 60, "MAREA ALTA · 12 MIN" }, { 44, 62, "CUARENTENA: NO BAJAR DE −120 M" }, { 0, 46, "BIENVENIDA A ABISALIA" } } do
		local panel = Builder.decor({ Name = "Holo" .. i, Size = V3(10, 4, 0.2), CFrame = ctx.CF(h[1], h[2], 9.5, if i == 3 then math.pi else 0), Color = rgb(90, 240, 230), Material = M.Neon, Transparency = 0.55, Parent = m })
		Builder.sign(panel, h[3], Enum.NormalId.Front, rgb(230, 255, 252))
		Builder.sign(panel, h[3], Enum.NormalId.Back, rgb(230, 255, 252))
		ctx.column(m, "Proyector" .. i, ctx.W(h[1], h[2], 0.9), 2.4, 1.4, C.Deep, M.Metal, true)
	end
	-- Macetas de coral rosa (vivo y limpio) en las esquinas de la plaza
	for _, p in { { -48, 112 }, { 48, 112 }, { -48, 58 }, { 48, 58 } } do
		ctx.column(m, "Maceta", ctx.W(p[1], p[2], 0.9), 2, 4, C.White, M.SmoothPlastic, true)
		for k = 0, 2 do
			ctx.ball(m, "CoralRosa", ctx.W(p[1] + (k - 1) * 0.9, p[2] + (k % 2) * 0.6, 3.6 + k * 0.5), 1.6 - k * 0.2, C.Coral, M.Salt, true)
		end
	end
	-- Barcas amarradas al Muelle y a las Balsas (casco, borda y una vela)
	for i, bt in { { 70, 155, 0 }, { 145, 156, 0.2 }, { -156, 60, math.pi / 2 }, { -156, 110, math.pi / 2 } } do
		local cf = ctx.CF(bt[1], bt[2], -13.2, bt[3])
		Builder.decor({ Name = "Barca" .. i, Size = V3(5, 1.6, 12), CFrame = cf, Color = if i % 2 == 0 then rgb(230, 236, 236) else rgb(70, 140, 190), Material = M.SmoothPlastic, Parent = m })
		Builder.decor({ Name = "Borda" .. i, Size = V3(5.4, 0.4, 12.4), CFrame = cf * CFrame.new(0, 0.9, 0), Color = C.WoodDark, Material = M.Wood, Parent = m })
		if i <= 2 then
			Builder.decor({ Name = "Mastil" .. i, Size = V3(0.3, 8, 0.3), CFrame = cf * CFrame.new(0, 5, 1), Color = C.WoodDark, Material = M.Wood, Parent = m })
			Builder.decor({ Name = "Vela" .. i, Size = V3(0.15, 6, 4), CFrame = cf * CFrame.new(0, 5.4, -1.2), Color = C.Canvas, Material = M.Fabric, Parent = m })
		end
	end
	-- La escalerilla de buceo al final del Muelle (se baja al mar abierto por aquí)
	for k = 0, 5 do
		ctx.box(m, "Peldano" .. k, 159.2, 160.8, 138, 142, -1 - k * 2.4, -0.6 - k * 2.4, C.Stilt, M.Metal, true)
	end
	ctx.box(m, "BarandaE1", 159.4, 160.4, 137.4, 138, -14, 4, C.Turq, M.Metal, true)
	ctx.box(m, "BarandaE2", 159.4, 160.4, 142, 142.6, -14, 4, C.Turq, M.Metal, true)
	ctx.sign(m, "BUCEO · PRADERAS DE LUZ →", ctx.CF(156, 136.8, 5, math.pi), 9, 1.4)
	ctx.column(m, "PosteBuceo", ctx.W(156, 136.4, 0.9), 4, 0.4, C.White, M.Metal, true)
	-- Boyas que marcan la zona de buceo (fuera del barrio, en el mar)
	for i, by in { { 190, 140 }, { 230, 120 }, { 210, 190 } } do
		local buoy = ctx.ball(m, "Boya" .. i, ctx.W(by[1], by[2], -13.4), 2.6, rgb(250, 110, 60), M.SmoothPlastic, true)
		glowAtNight(buoy, buoy.Color, rgb(255, 150, 90))
	end
	-- El poste de los desaparecidos
	ctx.column(m, "PosteFotos", ctx.W(-54, 64, 0.9), 7, 1, C.WoodDark, M.Wood, true)
	ctx.box(m, "Fotos", -54.6, -53.4, 60, 68, 3, 7, rgb(240, 236, 226), M.Fabric, true)
	-- El cuadro de presiones del Faro (el oficio de técnico/a de presión)
	ctx.box(m, "CuadroPresion", 69, 71, 23.2, 24, 0.9, 6, C.Deep, M.Metal, true)
	for k = 0, 2 do
		ctx.ball(m, "Manometro" .. k, ctx.W(70, 23, 2.6 + k * 1.2), 0.9, if k == 1 then rgb(255, 210, 60) else rgb(240, 250, 250), M.Neon, true)
	end
	Builder.streamable(m)
end

-- Flora de los islotes: palmeras inclinadas y matas de coral rosa
function Kit.decor(folder: Instance, d: { [string]: any })
	local m = Builder.model(d.Kind, folder)
	if d.Kind == "Palmera" then
		local h = 10 + d.Size * 0.5
		local base = CFrame.new(d.Pos) * CFrame.Angles(math.rad(8 + d.Roll * 10), d.Turn, 0)
		Builder.decor({ Name = "Tronco", Size = V3(0.9, h, 0.9), CFrame = base * CFrame.new(0, h / 2, 0), Color = rgb(140, 110, 80), Material = M.Wood, Parent = m })
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			Builder.decor({ Name = "Hoja", Size = V3(1.6, 0.2, 7), CFrame = base * CFrame.new(0, h, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, -0.6, 3) * CFrame.Angles(math.rad(-18), 0, 0), Color = rgb(70, 160, 90), Material = M.LeafyGrass, Parent = m })
		end
	else
		local s = 1.6 + d.Size * 0.18
		for k = 0, 2 do
			Builder.decor({ Name = "Coral", Shape = Enum.PartType.Ball, Size = V3(s, s * 1.3, s), CFrame = CFrame.new(d.Pos + V3((k - 1) * s * 0.6, s * 0.4 + k * 0.3, (k % 2) * s * 0.5)), Color = if d.Roll > 0.5 then C.Coral else rgb(250, 190, 120), Material = M.Salt, Parent = m })
		end
	end
end

-- Los puntos de interés: las muestras de coral negro EN EL FONDO (su aviso abajo, una boya arriba), el
-- cementerio de submarinos y la Ballena Dormida (costillas gigantes sobre su islote)
function Kit.poi(model: Model, p: { [string]: any }, at: Vector3): BasePart?
	if p.Seabed then
		local S = require(game:GetService("ReplicatedStorage").Shared.Cosmos.Talasa)
		local floor = S.heightAt(at.X, at.Z)
		local sea = S.Origin.Y + S.WaterY
		local main: BasePart? = nil
		if p.Id == "Talasa_Cementerio" then
			for i = 0, 2 do
				local cf = CFrame.new(at.X + i * 16 - 16, floor + 2.6, at.Z + (i % 2) * 10) * CFrame.Angles(math.rad(8 * i), math.rad(40 * i), math.rad(14))
				local hull = Builder.part({ Name = "Pecio" .. i, Shape = Enum.PartType.Cylinder, Size = V3(18, 6, 6), CFrame = cf, Color = rgb(80, 86, 84), Material = M.CorrodedMetal, Parent = model })
				main = main or hull
				Builder.decor({ Name = "CoralPecio" .. i, Shape = Enum.PartType.Ball, Size = V3(4, 3, 4), CFrame = cf * CFrame.new(3, 2.6, 0), Color = C.CoralBlack, Material = M.Slate, Parent = model })
			end
		else
			main = Builder.part({ Name = "CoralNegro", Shape = Enum.PartType.Ball, Size = V3(5, 4, 5), CFrame = CFrame.new(at.X, floor + 1.6, at.Z), Color = C.CoralBlack, Material = M.Slate, Parent = model })
			for k = 0, 3 do
				local a = k / 4 * math.pi * 2
				Builder.decor({ Name = "Rama", Size = V3(0.8, 4 + k, 0.8), CFrame = CFrame.new(at.X + math.cos(a) * 2, floor + 3 + k * 0.4, at.Z + math.sin(a) * 2) * CFrame.Angles(math.cos(a) * 0.4, 0, math.sin(a) * 0.4), Color = C.CoralBlack, Material = M.Slate, Parent = model })
			end
			local pulse = Builder.decor({ Name = "Pulso", Shape = Enum.PartType.Ball, Size = V3(1.6, 1.6, 1.6), CFrame = CFrame.new(at.X, floor + 4.2, at.Z), Color = C.CoralPulse, Material = M.Neon, Parent = model })
			local l = Instance.new("PointLight")
			l.Range = 14
			l.Color = C.CoralPulse
			l.Brightness = 1.5
			l.Parent = pulse
		end
		-- la boya de arriba (para encontrarlo desde la superficie) y su cabo
		local buoy = Builder.decor({ Name = "BoyaMuestra", Shape = Enum.PartType.Ball, Size = V3(2.4, 2.4, 2.4), CFrame = CFrame.new(at.X, sea + 0.6, at.Z), Color = rgb(250, 210, 60), Material = M.SmoothPlastic, Parent = model })
		Builder.decor({ Name = "Cabo", Size = V3(0.2, math.max(1, sea - floor - 3), 0.2), CFrame = CFrame.new(at.X, (sea + floor + 3) / 2, at.Z), Color = C.Rope, Material = M.Fabric, Parent = model })
		glowAtNight(buoy, buoy.Color, rgb(255, 230, 90))
		return main
	end
	if p.Id == "Talasa_Ballena" then
		local main = Builder.part({ Name = "Craneo", Shape = Enum.PartType.Ball, Size = V3(26, 18, 22), CFrame = CFrame.new(at + V3(-40, 8, 0)), Color = rgb(236, 230, 214), Material = M.Limestone, Parent = model })
		for i = 0, 6 do
			local x = -22 + i * 10
			for side = -1, 1, 2 do
				Builder.part({ Name = "Costilla", Size = V3(2.4, 26 - math.abs(i - 3) * 2, 2.4), CFrame = CFrame.new(at + V3(x, 10, side * 9)) * CFrame.Angles(side * math.rad(-28), 0, 0), Color = rgb(232, 226, 210), Material = M.Limestone, Parent = model })
			end
		end
		for k = 0, 2 do
			local hut = Builder.part({ Name = "Choza", Size = V3(7, 5, 6), CFrame = CFrame.new(at + V3(-14 + k * 16, 2.5, 0)), Color = C.Wood, Material = M.WoodPlanks, Parent = model })
			local lamp = Builder.decor({ Name = "Farol", Shape = Enum.PartType.Ball, Size = V3(1, 1, 1), CFrame = hut.CFrame * CFrame.new(0, 3.4, -3.2), Color = rgb(150, 120, 90), Material = M.Neon, Parent = model })
			glowAtNight(lamp, rgb(150, 120, 90), rgb(255, 200, 120))
		end
		return main
	end
	return nil
end

-- Lo de fuera: las tres lunas, el Archipiélago Suspendido (islas que flotan con cascadas al mar), boyas de
-- la marea y el lomo lejano del Leviatán. Pocas piezas y todas de adorno: se ven de lejos.
function Kit.world(folder: Instance, S: any)
	local m = Instance.new("Folder")
	m.Name = "CieloTalasa"
	m.Parent = folder
	local O = S.Origin
	local sea = O.Y + S.WaterY
	-- Las tres lunas (Neon: brillan a través de la bruma)
	for i, moon in { { 600, 900, -1400, 150, rgb(230, 246, 240) }, { -900, 760, -1300, 90, rgb(200, 230, 255) }, { 200, 1150, -1700, 60, rgb(255, 236, 210) } } do
		local ball = Builder.decor({ Name = "Luna" .. i, Shape = Enum.PartType.Ball, Size = Vector3.one * moon[4], CFrame = CFrame.new(O + V3(moon[1], moon[2], moon[3])), Color = moon[5], Material = M.Neon, Transparency = 0.1, CastShadow = false, Parent = m })
		Builder.decor({ Name = "Halo" .. i, Shape = Enum.PartType.Ball, Size = Vector3.one * moon[4] * 1.25, CFrame = ball.CFrame, Color = moon[5], Material = M.Neon, Transparency = 0.85, CastShadow = false, Parent = m })
	end
	-- El Archipiélago Suspendido
	for i, isl in { { -520, 260, -560, 120 }, { 380, 330, -640, 90 }, { -200, 420, -820, 140 }, { 700, 280, 300, 80 } } do
		local center = O + V3(isl[1], isl[2], isl[3])
		local r = isl[4]
		Builder.decor({ Name = "IslaRoca" .. i, Shape = Enum.PartType.Ball, Size = V3(r, r * 0.7, r), CFrame = CFrame.new(center - V3(0, r * 0.2, 0)), Color = rgb(150, 140, 130), Material = M.Limestone, Parent = m })
		Builder.decor({ Name = "IslaPunta" .. i, Shape = Enum.PartType.Ball, Size = V3(r * 0.5, r * 0.6, r * 0.5), CFrame = CFrame.new(center - V3(0, r * 0.5, 0)), Color = rgb(130, 120, 112), Material = M.Limestone, Parent = m })
		Builder.decor({ Name = "IslaHierba" .. i, Shape = Enum.PartType.Cylinder, Size = V3(r * 0.1, r * 0.92, r * 0.92), CFrame = CFrame.new(center + V3(0, r * 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(90, 176, 120), Material = M.LeafyGrass, Parent = m })
		-- una mansión de la Corona (con su escudo) en las dos más grandes
		if r >= 120 then
			Builder.decor({ Name = "Mansion" .. i, Size = V3(r * 0.3, r * 0.16, r * 0.22), CFrame = CFrame.new(center + V3(r * 0.1, r * 0.25, 0)), Color = rgb(250, 250, 246), Material = M.SmoothPlastic, Parent = m })
			Builder.decor({ Name = "Escudo" .. i, Shape = Enum.PartType.Ball, Size = V3(r * 0.5, r * 0.36, r * 0.5), CFrame = CFrame.new(center + V3(r * 0.1, r * 0.25, 0)), Color = rgb(180, 240, 255), Material = M.ForceField, Transparency = 0.5, Parent = m })
		end
		-- la cascada que cae al mar
		local top = center.Y - r * 0.05
		local fall = top - sea
		Builder.decor({ Name = "Cascada" .. i, Size = V3(r * 0.12, fall, 3), CFrame = CFrame.new(center.X + r * 0.42, sea + fall / 2, center.Z), Color = rgb(200, 245, 250), Material = M.Glass, Transparency = 0.55, Parent = m })
		Builder.decor({ Name = "Espuma" .. i, Shape = Enum.PartType.Cylinder, Size = V3(1.2, r * 0.36, r * 0.36), CFrame = CFrame.new(center.X + r * 0.42, sea + 0.4, center.Z) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(240, 252, 255), Material = M.SmoothPlastic, Transparency = 0.2, Parent = m })
	end
	-- Boyas de la marea alrededor del barrio
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = O + V3(math.cos(a) * 260, 0, math.sin(a) * 260)
		local buoy = Builder.decor({ Name = "BoyaMarea" .. k, Size = V3(2, 5, 2), CFrame = CFrame.new(p.X, sea + 2, p.Z), Color = if k % 2 == 0 then rgb(240, 90, 60) else rgb(250, 250, 250), Material = M.SmoothPlastic, Parent = m })
		glowAtNight(buoy, buoy.Color, rgb(255, 120, 80))
	end
	-- El lomo lejano del Leviatán de las mareas (asoma del mar, quieto: «no es enemigo»)
	for k = 0, 4 do
		Builder.decor({ Name = "Leviatan" .. k, Shape = Enum.PartType.Ball, Size = V3(60 - k * 8, 18 - k * 2, 40 - k * 5), CFrame = CFrame.new(O + V3(-760 + k * 46, S.WaterY - 4 + math.sin(k) * 2, -520 - k * 10)), Color = rgb(40, 66, 80), Material = M.Slate, Parent = m })
	end
end

return Kit
