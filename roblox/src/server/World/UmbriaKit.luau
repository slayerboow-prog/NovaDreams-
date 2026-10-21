-- UmbriaKit (servidor): las FORMAS y los COLORES de Raíz Honda, la capital de Umbría (marco común de los
-- planetas: World/PlanetCityBuilder con el plano shared/Cosmos/UmbriaCity; World/PlanetWorld con la
-- superficie shared/Cosmos/Umbria). Solo piezas (ninguna malla nueva).
--
-- Estilo (diseno-mundos §3.5.7): nada está construido «encima» del árbol, todo crece con él. Casas
-- talladas en tocones con puerta redonda, una empalizada de raíces vivas, arcos de raíz que cruzan el
-- barrio por encima, vainas que cuelgan, setas sombrilla que brillan en azul y verde, farolillos de seta,
-- el Vivero de semilleros y las barricadas contra el Enjambre. Fuera: el Árbol Madre (un tronco de 120 studs
-- que se pierde en la niebla), troncos gigantes hasta el horizonte, setas, helechos, esporeras y la baliza
-- de la Compañía Torca en el Claro Muerto. Sin metal a la vista (salvo lo que trajeron de fuera).

local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Kit.Palette)

local Kit = {}

local function PlanetCityBuilder(): any
	return require(script.Parent.PlanetCityBuilder) :: any
end

local V3 = Vector3.new
local CFn = CFrame.new
local ANG = CFrame.Angles
local rgb = Color3.fromRGB
local M = Enum.Material

local YAW = { N = 0, S = math.pi, E = -math.pi / 2, W = math.pi / 2 }

local C = {
	Bark = rgb(86, 64, 46),
	BarkDark = rgb(58, 42, 32),
	BarkLight = rgb(120, 92, 64),
	Moss = rgb(74, 110, 58),
	Leaf = rgb(52, 92, 46),
	LeafDark = rgb(34, 64, 36),
	Glow = { rgb(110, 240, 220), rgb(150, 255, 140), rgb(130, 170, 255) },
	Amber = rgb(240, 170, 60),
	Cap = { rgb(170, 70, 60), rgb(200, 150, 80), rgb(120, 90, 160) },
	Spore = rgb(220, 255, 150),
	Metal = rgb(140, 146, 156),
	Swarm = rgb(200, 210, 225),
}
Kit.C = C

Kit.Colors = {
	Floor = rgb(88, 66, 46),
	FloorMaterial = M.WoodPlanks,
	Wall = C.Bark,
	Metal = C.BarkDark,
	Lamp = C.Glow[1],
	Light = rgb(255, 214, 150),
	Sign = rgb(40, 30, 22),
	SignText = rgb(220, 255, 180),
	Pad = rgb(92, 70, 50),
	PadRing = rgb(150, 255, 140),
	PadLight = rgb(200, 255, 180),
	Poi = C.BarkDark,
	PoiLight = C.Glow[2],
}

Palette.Styles.UmbriaCorteza = Palette.Styles.UmbriaCorteza or {
	Wall = { rgb(96, 70, 50), rgb(106, 80, 56), rgb(88, 64, 46) },
	WallMaterial = M.Wood,
	Trim = rgb(60, 44, 32),
	TrimMaterial = M.WoodPlanks,
	Glass = rgb(200, 150, 70),
	Bay = 9,
	WindowW = 3.2,
	WindowH = 4.4,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.UmbriaFlor = Palette.Styles.UmbriaFlor or {
	Wall = { rgb(200, 170, 140), rgb(214, 184, 150), rgb(190, 160, 130) },
	WallMaterial = M.Wood,
	Trim = rgb(110, 150, 80),
	TrimMaterial = M.Grass,
	Glass = rgb(160, 210, 150),
	Bay = 9,
	WindowW = 3.4,
	WindowH = 4.6,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}

---------------------------------------------------------------------
-- Herramientas
---------------------------------------------------------------------
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, decor: boolean?, extra: { [string]: any }?): BasePart
	local props: { [string]: any } = { Name = name, Size = size, CFrame = cf, Color = color, Material = mat, Parent = parent }
	for k, v in extra or {} do
		props[k] = v
	end
	return if decor then Builder.decor(props) else Builder.part(props)
end

local function cyl(parent: Instance, name: string, base: CFrame, height: number, diameter: number, color: Color3, mat: Enum.Material, decor: boolean?): BasePart
	return part(parent, name, V3(height, diameter, diameter), base * CFn(0, height / 2, 0) * ANG(0, 0, math.pi / 2), color, mat, decor, { Shape = Enum.PartType.Cylinder })
end

local function ball(parent: Instance, name: string, at: CFrame, d: number, color: Color3, mat: Enum.Material, decor: boolean?): BasePart
	return part(parent, name, V3(d, d, d), at, color, mat, decor, { Shape = Enum.PartType.Ball })
end

local function glow(parent: Instance, color: Color3, range: number, brightness: number, enabled: boolean?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Enabled = enabled ~= false
	l.Parent = parent
end

-- Una «viga» entre dos puntos (raíces, lianas, postes): una pieza cuadrada de sección s
local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, s: number, color: Color3, mat: Enum.Material, decor: boolean?): BasePart
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	return part(parent, name, V3(s, s, len), cf, color, mat, decor)
end

-- Seta: pie y sombrero (con láminas que brillan por debajo)
local function mushroom(parent: Instance, base: CFrame, h: number, capD: number, cap: Color3, glowColor: Color3, light: boolean)
	cyl(parent, "Pie", base, h, math.max(1, capD * 0.18), rgb(220, 210, 190), M.SmoothPlastic, true)
	local under = cyl(parent, "Laminas", base * CFn(0, h - 0.3, 0), 0.6, capD * 0.92, glowColor, M.Neon, true)
	cyl(parent, "Sombrero", base * CFn(0, h, 0), capD * 0.16, capD, cap, M.SmoothPlastic, true)
	cyl(parent, "Copete", base * CFn(0, h + capD * 0.16, 0), capD * 0.1, capD * 0.6, cap, M.SmoothPlastic, true)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		ball(parent, "Mota", base * CFn(math.cos(a) * capD * 0.32, h + capD * 0.17, math.sin(a) * capD * 0.32), capD * 0.09, rgb(240, 236, 220), M.SmoothPlastic, true)
	end
	if light then
		glow(under, glowColor, capD * 2.4, 1.2)
	end
	return under
end

---------------------------------------------------------------------
-- Las formas del plano
---------------------------------------------------------------------
Kit.Shapes = {}

-- Casa-tocón: un tocón enorme vaciado, con puerta redonda, ventanas de luz y un tejado de setas
Kit.Shapes.Tocon = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.CF(b.X, b.Z, 0)
	local R = b.R or 9
	local H = b.Height or 20
	cyl(m, "Tronco", base, H, R * 2, C.Bark, M.Wood)
	cyl(m, "Corte", base * CFn(0, H, 0), 0.6, R * 2 - 0.4, C.BarkLight, M.WoodPlanks)
	cyl(m, "Anillo", base * CFn(0, H + 0.6, 0), 0.3, R * 1.2, rgb(150, 116, 80), M.WoodPlanks, true)
	-- raíces que bajan al suelo
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		local top = (base * CFn(math.cos(a) * R * 0.85, H * 0.35, math.sin(a) * R * 0.85)).Position
		local foot = (base * CFn(math.cos(a) * (R + 4), 0, math.sin(a) * (R + 4))).Position
		beam(m, "Raiz", top, foot, 2.2, C.BarkDark, M.Wood, true)
	end
	-- puerta redonda (mira al centro del barrio)
	local toCenter = math.atan2(-b.X, -b.Z)
	local front = base * ANG(0, toCenter + math.pi, 0)
	cyl(m, "Puerta", front * CFn(0, 0, -R + 0.2) * CFn(0, 3.2, 0) * ANG(math.pi / 2, 0, 0) * CFn(0, -0.3, 0), 0.6, 6.4, rgb(130, 60, 40), M.WoodPlanks, true)
	ball(m, "Pomo", front * CFn(1.6, 3.4, -R - 0.4), 0.5, C.Amber, M.Neon, true)
	for _, a in { -0.6, 0.6 } do
		local win = part(m, "Ventana", V3(2, 2, 0.4), front * ANG(0, a, 0) * CFn(0, H * 0.6, -R + 0.05), rgb(130, 100, 60), M.Glass, true)
		PlanetCityBuilder().nightGlow(win, rgb(130, 100, 60), rgb(255, 200, 110))
	end
	-- setas en el tejado y musgo
	mushroom(m, base * CFn(R * 0.3, H + 0.6, R * 0.2), 4, 6, C.Cap[(string.byte(b.Id, -1) % 3) + 1], C.Glow[2], false)
	mushroom(m, base * CFn(-R * 0.4, H + 0.6, -R * 0.3), 2.6, 3.6, C.Cap[((string.byte(b.Id, -1) + 1) % 3) + 1], C.Glow[1], false)
	cyl(m, "Musgo", base * CFn(0, H * 0.2, 0), 1.2, R * 2 + 0.3, C.Moss, M.Grass, true)
	Builder.streamable(m)
	return m
end

-- Seta sombrilla gigante (la plaza): brilla por debajo y da luz de noche y de día
Kit.Shapes.SetaGigante = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.CF(b.X, b.Z, 0)
	local H = b.Height or 28
	cyl(m, "Pie", base, H, (b.R or 4) * 2, rgb(226, 216, 196), M.SmoothPlastic)
	cyl(m, "Anillo", base * CFn(0, H * 0.7, 0), 1, (b.R or 4) * 2 + 3, rgb(236, 230, 214), M.SmoothPlastic, true)
	mushroom(m, base * CFn(0, H - 0.1, 0), 0.1, 30, if b.X < 0 then C.Cap[1] else C.Cap[3], if b.X < 0 then C.Glow[1] else C.Glow[3], true)
	Builder.streamable(m)
	return m
end

-- El Vivero: semilleros bajo un techo de hojas, con bancales de brotes que brillan
Kit.Shapes.Vivero = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local frame = ctx.CF(b.X, b.Z, 0, YAW[b.Face or "N"])
	local w, d = b.W or 24, b.D or 16
	local H = b.Height or 14
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 }, { 0, -1 }, { 0, 1 } } do
		part(m, "Poste", V3(1, H, 1), frame * CFn(s[1] * (w / 2 - 0.5), H / 2, s[2] * (d / 2 - 0.5)), C.Bark, M.Wood)
	end
	part(m, "TechoHojas", V3(w + 3, 0.8, d + 3), frame * CFn(0, H + 0.4, 0) * ANG(0, 0, math.rad(4)), C.Leaf, M.Grass)
	part(m, "TechoHojas2", V3(w - 2, 0.8, d - 2), frame * CFn(0, H + 1.4, 0) * ANG(0, 0, math.rad(-3)), C.LeafDark, M.Grass, true)
	for i = -1, 1 do
		part(m, "Bancal", V3(w - 6, 1.6, 2.6), frame * CFn(0, 0.8, i * 4.4), C.BarkDark, M.WoodPlanks)
		part(m, "Tierra", V3(w - 7, 0.4, 2), frame * CFn(0, 1.75, i * 4.4), rgb(60, 44, 30), M.Grass, true)
		for k = -3, 3 do
			ball(m, "Brote", frame * CFn(k * 2.6, 2.4, i * 4.4), 0.9, C.Glow[2], M.Neon, true)
		end
	end
	local lamp = ball(m, "Farolillo", frame * CFn(0, H - 2, 0), 1.4, C.Amber, M.Neon, true)
	glow(lamp, C.Amber, 26, 1.2)
	Builder.streamable(m)
	return m
end

-- Torre de vigía: una plataforma sobre cuatro troncos, con escala de cuerda y un cuerno de alarma
Kit.Shapes.Vigia = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.CF(b.X, b.Z, 0)
	local R = b.R or 5
	local H = b.Height or 36
	for _, s in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		part(m, "Pata", V3(1.4, H, 1.4), base * CFn(s[1] * (R - 1), H / 2, s[2] * (R - 1)) * ANG(s[2] * 0.03, 0, -s[1] * 0.03), C.Bark, M.Wood)
	end
	part(m, "Plataforma", V3(R * 2 + 2, 1, R * 2 + 2), base * CFn(0, H, 0), C.BarkLight, M.WoodPlanks)
	part(m, "TechoHojas", V3(R * 2 + 4, 1, R * 2 + 4), base * CFn(0, H + 7, 0), C.Leaf, M.Grass)
	for _, s in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		part(m, "Puntal", V3(0.6, 7, 0.6), base * CFn(s[1] * R, H + 3.5, s[2] * R), C.BarkDark, M.Wood, true)
	end
	part(m, "Cuerno", V3(1, 1, 4), base * CFn(R + 1, H + 3, 0) * ANG(0, 0.6, 0.3), rgb(230, 210, 170), M.SmoothPlastic, true)
	for i = 1, 7 do
		part(m, "Peldano", V3(2.4, 0.3, 0.3), base * CFn(0, i * H / 8, -R - 0.4), C.BarkDark, M.Wood, true)
	end
	local lamp = ball(m, "Farol", base * CFn(0, H + 5, 0), 1.6, C.Glow[2], M.Neon, true)
	glow(lamp, C.Glow[2], 40, 1.4)
	Builder.streamable(m)
	return m
end

-- Lienzo de la empalizada de raíces vivas: troncos verticales trenzados, musgo y alguna seta
Kit.Shapes.Empalizada = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local H = b.Height or 14
	local along = (x1 - x0) >= (z1 - z0)
	local len = if along then x1 - x0 else z1 - z0
	local n = math.max(2, math.floor(len / 5))
	ctx.box(m, "Trenzado", x0, x1, z0 + (if along then 1.5 else 0), z1 - (if along then 1.5 else 0), 0, H * 0.55, C.BarkDark, M.Wood)
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local x = if along then x0 + t * len else (x0 + x1) / 2
		local z = if along then (z0 + z1) / 2 else z0 + t * len
		local h = H * (0.75 + ((i * 7) % 5) * 0.08)
		cyl(m, "Raiz", ctx.CF(x, z, 0), h, 3 + (i % 3) * 0.6, if i % 2 == 0 then C.Bark else C.BarkLight, M.Wood)
		if i % 4 == 1 then
			cyl(m, "Musgo", ctx.CF(x, z, h - 1), 1.2, 3.6, C.Moss, M.Grass, true)
		end
	end
	Builder.streamable(m)
	return m
end

-- Arco de raíz: una raíz gigante que sale del suelo, pasa por encima del barrio y vuelve a bajar
Kit.Shapes.ArcoRaiz = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local a = ctx.W(b.X0, b.Z0, -2)
	local c = ctx.W(b.X1, b.Z1, -2)
	local H = b.Height or 40
	local prev = a
	local n = 7
	for i = 1, n do
		local t = i / n
		local p = a:Lerp(c, t) + V3(0, math.sin(t * math.pi) * H, 0)
		beam(m, "Raiz", prev, p, 5.5 - math.sin(t * math.pi) * 1.6, if i % 2 == 0 then C.Bark else C.BarkDark, M.Wood, true)
		if i > 1 and i < n and i % 2 == 0 then
			-- una liana que cuelga y un farolillo de seta
			local hang = p - V3(0, 10, 0)
			beam(m, "Liana", p, hang, 0.35, C.Leaf, M.Grass, true)
			local f = ball(m, "Farolillo", CFn(hang), 1.2, C.Glow[1], M.Neon, true)
			if i == 4 then
				glow(f, C.Glow[1], 22, 1)
			end
		end
		prev = p
	end
	return m
end

-- Vaina colgante: una casa-capullo que cuelga de un arco, con su cuerda y su ventana redonda
Kit.Shapes.VainaColgante = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local H = b.Height or 30
	local top = ctx.W(b.X, b.Z, H + 12)
	local at = CFn(ctx.W(b.X, b.Z, H))
	beam(m, "Cuerda", top, at.Position + V3(0, 4, 0), 0.4, rgb(190, 170, 120), M.Fabric, true)
	ball(m, "Vaina", at, 8, rgb(170, 140, 90), M.Wood, true)
	ball(m, "VainaBaja", at * CFn(0, -2.6, 0), 6, rgb(150, 120, 80), M.Wood, true)
	local win = part(m, "Ventana", V3(1.8, 1.8, 0.4), at * CFn(0, 0.4, -3.9), rgb(255, 200, 110), M.Neon, true)
	if string.byte(b.Id, -1) % 2 == 0 then
		glow(win, rgb(255, 200, 120), 16, 0.8)
	end
	return m
end

-- Barricada contra el Enjambre: troncos cruzados y estacas
Kit.Shapes.Barricada = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local frame = ctx.CF(b.X, b.Z, 0, YAW[b.Face or "N"])
	local w = b.W or 20
	local H = b.Height or 6
	for i = 0, 2 do
		part(m, "Tronco", V3(w, 1.6, 1.6), frame * CFn(0, 0.8 + i * 1.7, (i % 2) * 0.4), C.Bark, M.Wood)
	end
	for k = -3, 3 do
		part(m, "Estaca", V3(0.7, H + 2, 0.7), frame * CFn(k * w / 7, H / 2, -1.6) * ANG(-0.5, 0, 0), C.BarkLight, M.Wood, true)
	end
	part(m, "Red", V3(w * 0.6, H * 0.8, 0.2), frame * CFn(w * 0.1, H * 0.6, 1.2), rgb(220, 220, 200), M.Fabric, true, { Transparency = 0.5 })
	return m
end

---------------------------------------------------------------------
-- Box, farolillos, sima, lo que se recoge y los extras
---------------------------------------------------------------------
function Kit.dressBox(ctx: any, model: Model, b: { [string]: any }, cf: CFrame, info: { [string]: any })
	local w, d = b.W or 20, b.D or 20
	local top = (info and info.Top) or ctx.City.topOf(b)
	-- raíces que abrazan el edificio y un techo de musgo
	for _, s in { -1, 1 } do
		local foot = (cf * CFn(s * (w / 2 + 2.5), 0, -d / 2 + 1)).Position
		local over = (cf * CFn(s * (w / 2 - 1), top + 3, 0)).Position
		local back = (cf * CFn(s * (w / 2 + 2), 0, d / 2 - 1)).Position
		beam(model, "RaizAbrazo", foot, over, 3, C.BarkDark, M.Wood, true)
		beam(model, "RaizAbrazo", over, back, 3, C.Bark, M.Wood, true)
	end
	part(model, "TechoMusgo", V3(w + 1, 1, d + 1), cf * CFn(0, top + 0.4, 0), C.Moss, M.Grass, true)
	if b.Style == "UmbriaFlor" then
		-- pétalos enormes alrededor del tejado (la Flor del Mirador)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			part(model, "Petalo", V3(7, 0.6, 12), cf * CFn(math.cos(a) * w * 0.45, top + 2.5, math.sin(a) * d * 0.45) * ANG(0, -a + math.pi / 2, 0) * ANG(0.5, 0, 0), if k % 2 == 0 then rgb(240, 150, 190) else rgb(250, 200, 220), M.SmoothPlastic, true)
		end
		ball(model, "Pistilo", cf * CFn(0, top + 3, 0), 5, rgb(255, 220, 100), M.Neon, true)
	else
		mushroom(model, cf * CFn(w * 0.3, top + 0.8, 0), 3, 5, C.Cap[2], C.Glow[1], false)
	end
	-- farolillo de seta junto a la puerta
	ball(model, "FarolilloPuerta", cf * CFn(w / 2 - 1.4, 7.5, -d / 2 - 0.9), 1.2, C.Glow[2], M.Neon, true)
end

-- Farolillo de seta (la farola de Raíz Honda): pie de raíz y un sombrerillo que se enciende de noche
function Kit.lamp(ctx: any, parent: Instance, cf: CFrame)
	local m = Builder.model("StreetLamp", parent)
	part(m, "Pie", V3(1.4, 1, 1.4), cf * CFn(0, 0.5, 0), C.BarkDark, M.Wood)
	part(m, "Tallo", V3(0.6, 8, 0.6), cf * CFn(0, 5, 0) * ANG(0, 0, 0.05), C.Bark, M.Wood)
	part(m, "Hoja", V3(2.4, 0.3, 1.2), cf * CFn(0.9, 4, 0) * ANG(0, 0, -0.5), C.Leaf, M.Grass, true)
	local bulb = Builder.decor({ Name = "Sombrerillo", Size = V3(2.6, 1, 2.6), CFrame = cf * CFn(0, 9.4, 0), Color = C.Glow[(math.floor(cf.Position.X) % 3) + 1], Material = M.SmoothPlastic, Tags = { "StreetLamp" }, Parent = m })
	glow(bulb, bulb.Color, 24, 1.4, false)
	return m
end

function Kit.pit(ctx: any, parent: Instance, p: { [string]: any })
	if p.Kind ~= "Disc" then
		return
	end
	local m = Builder.model("Sima", parent)
	local base = ctx.CF(p.X, p.Z, 0)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local top = (base * CFn(math.cos(a) * (p.R + 2), 1, math.sin(a) * (p.R + 2))).Position
		local deep = (base * CFn(math.cos(a) * p.R * 0.5, -p.Depth + 2, math.sin(a) * p.R * 0.5)).Position
		beam(m, "RaizSima", top, deep, 2.4, C.BarkDark, M.Wood, true)
	end
	local f = ball(m, "Hongos", base * CFn(0, -p.Depth + 3, 0), 3, C.Glow[1], M.Neon, true)
	glow(f, C.Glow[1], 24, 1.2)
end

function Kit.gather(ctx: any, parent: Instance, g: { [string]: any })
	local base = ctx.CF(g.X, g.Z, 0.9)
	if g.Item == "SedaLiana" then
		for k = 0, 2 do
			beam(parent, "Liana", (base * CFn((k - 1) * 1.2, 14, 0)).Position, (base * CFn((k - 1) * 1.6, 0.4, 1)).Position, 0.4, C.Leaf, M.Grass, true)
		end
		ball(parent, "Capullo", base * CFn(0, 6, 0.4), 1.6, rgb(240, 240, 230), M.Fabric, true)
	else
		local r = cyl(parent, "RaizHerida", base, 3, 3, C.Bark, M.Wood, true)
		local drop = ball(parent, "Savia", base * CFn(0, 3.2, -1.2), 1.4, C.Amber, M.Neon, true)
		glow(drop, C.Amber, 10, 0.8)
		local _ = r
	end
end

function Kit.extras(ctx: any, model: Model)
	local decor = Builder.model("Empalizada y raíces", model)
	for _, d in ctx.City.Decor or {} do
		local shape = Kit.Shapes[d.Shape]
		if shape then
			shape(ctx, decor, d)
		end
	end
	local m = Builder.model("Detalles", model)
	-- el ascensor de liana del Claro: dos postes, la cesta y la cuerda que sube a las copas
	for _, x in { -46, 46 } do
		part(m, "PosteAscensor", V3(2, 30, 2), ctx.CF(x, -46, 15), C.Bark, M.Wood)
		beam(m, "CuerdaAscensor", ctx.W(x, -46, 30), ctx.W(x * 0.2, -120, 220), 0.5, rgb(190, 170, 120), M.Fabric, true)
	end
	part(m, "Cesta", V3(6, 3, 6), ctx.CF(-46, -40, 1.5), rgb(170, 140, 90), M.Fabric)
	-- helechos y setas pequeñas por las esquinas del barrio
	local spots = { { -60, -110 }, { 60, -112 }, { -120, -40 }, { 120, -60 }, { -122, 60 }, { 122, 92 }, { -60, 116 }, { 100, 116 }, { -50, -10 }, { 50, 60 } }
	for i, p in spots do
		if i % 2 == 0 then
			mushroom(m, ctx.CF(p[1], p[2], 0.9), 2 + (i % 3), 3 + (i % 4), C.Cap[(i % 3) + 1], C.Glow[(i % 3) + 1], i % 4 == 0)
		else
			for k = 0, 4 do
				local a = k / 5 * math.pi * 2
				part(m, "Fronda", V3(1.2, 0.3, 6), ctx.CF(p[1], p[2], 1.6) * ANG(0, a, 0) * CFn(0, 0, 2.6) * ANG(0.45, 0, 0), C.Leaf, M.Grass, true)
			end
		end
	end
	-- velas por los que no han vuelto, en la plaza
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		part(m, "Vela", V3(0.4, 1, 0.4), ctx.CF(math.cos(a) * 6, 76 + math.sin(a) * 6, 1.4), rgb(240, 230, 200), M.SmoothPlastic, true)
		ball(m, "Llama", ctx.CF(math.cos(a) * 6, 76 + math.sin(a) * 6, 2.1), 0.35, rgb(255, 190, 100), M.Neon, true)
	end
	-- semilla plantada en el centro de la plaza (cada nacimiento planta una)
	cyl(m, "Arriate", ctx.CF(0, 76, 0.9), 1, 8, C.BarkDark, M.WoodPlanks)
	local sprout = ball(m, "Retono", ctx.CF(0, 76, 3), 2, C.Glow[2], M.Neon, true)
	glow(sprout, C.Glow[2], 20, 1)
end

---------------------------------------------------------------------
-- Fuera: el bosque gigante, el Árbol Madre, la baliza y lo demás
---------------------------------------------------------------------
function Kit.decor(folder: Instance, d: { [string]: any })
	local base = CFn(d.Pos) * ANG(0, d.Turn, 0)
	if d.Kind == "Arbol" then
		-- tronco gigante que se pierde en la niebla, con raíces y una copa enorme
		local dia = 14 + d.Size * 2.4
		local h = 260 + d.Size * 18
		cyl(folder, "Tronco", base * CFn(0, -4, 0), h, dia, if d.Roll > 0.5 then C.Bark else C.BarkDark, M.Wood)
		for k = 0, 3 do
			local a = k / 4 * math.pi * 2 + d.Roll
			beam(folder, "Raiz", (base * CFn(math.cos(a) * dia * 0.4, dia * 0.7, math.sin(a) * dia * 0.4)).Position, (base * CFn(math.cos(a) * dia * 1.1, -1, math.sin(a) * dia * 1.1)).Position, dia * 0.22, C.BarkDark, M.Wood, false)
		end
		cyl(folder, "Copa", base * CFn(0, h - 6, 0), 14, dia * 5, if d.Roll > 0.3 then C.Leaf else C.LeafDark, M.Grass, true)
		cyl(folder, "Copa2", base * CFn(dia * 0.8, h - 30, 0), 10, dia * 3.4, C.LeafDark, M.Grass, true)
	elseif d.Kind == "SetaGrande" then
		local h = 4 + d.Size * 0.8
		mushroom(folder, base, h, 4 + d.Size * 0.7, C.Cap[math.floor(d.Roll * 3) + 1], C.Glow[math.floor(d.Roll * 3) + 1], d.Roll > 0.85)
	elseif d.Kind == "Esporera" then
		local s = 2 + d.Size * 0.3
		for k = 0, 2 do
			ball(folder, "Esporera", base * CFn((k - 1) * s * 0.8, s * 0.4, (k % 2) * s * 0.5), s * (1 - k * 0.2), C.Spore, M.Neon, true)
		end
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(C.Spore)
		e.Size = NumberSequence.new(0.3, 0.05)
		e.Lifetime = NumberRange.new(3, 5)
		e.Speed = NumberRange.new(1, 2)
		e.Rate = 3
		e.Parent = folder:FindFirstChildWhichIsA("BasePart") or folder
	else
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			part(folder, "Fronda", V3(1.4, 0.3, 3 + d.Size * 0.4), base * ANG(0, a, 0) * CFn(0, 1.2, 1.4 + d.Size * 0.2) * ANG(0.5, 0, 0), C.Leaf, M.Grass, true)
		end
	end
end

function Kit.poi(model: Model, p: { [string]: any }, at: Vector3): BasePart?
	local base = CFn(at)
	if p.Id == "Umbria_Baliza" then
		local main = part(model, "Base", V3(8, 3, 8), base * CFn(0, 1.5, 0), C.Metal, M.DiamondPlate)
		for _, s in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
			part(model, "Pata", V3(0.8, 30, 0.8), base * CFn(s[1] * 2.2, 16, s[2] * 2.2) * ANG(s[2] * 0.06, 0, -s[1] * 0.06), C.Metal, M.Metal)
		end
		local top = ball(model, "Luz", base * CFn(0, 32, 0), 2.4, rgb(255, 60, 50), M.Neon, true)
		glow(top, rgb(255, 80, 60), 40, 2)
		part(model, "Cartel", V3(5, 2, 0.3), base * CFn(0, 4.5, -4.2), rgb(40, 40, 46), M.Metal, true)
		-- tocones alrededor: lo que dejó el Enjambre
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			cyl(model, "Tocon", base * CFn(math.cos(a) * (16 + k % 3 * 6), -0.5, math.sin(a) * (16 + k % 3 * 6)), 3 + k % 3, 5 + k % 4, C.BarkLight, M.Wood)
		end
		return main
	elseif p.Id == "Umbria_Templo" then
		local main = part(model, "Altar", V3(10, 4, 10), base * CFn(0, 2, 0), rgb(110, 120, 100), M.Slate)
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			part(model, "Piedra", V3(3, 10 - (k % 3) * 2, 3), base * CFn(math.cos(a) * 12, 4, math.sin(a) * 12) * ANG(0.08 * (k % 2), a, 0), rgb(100, 110, 90), M.Slate)
		end
		local mark = part(model, "Marca", V3(4, 4, 0.2), base * CFn(0, 6, -5.1), C.Glow[1], M.Neon, true)
		glow(mark, C.Glow[1], 18, 0.8)
		return main
	elseif p.Id == "Umbria_Nido" then
		local main = ball(model, "Nido", base * CFn(0, 6, 0), 16, rgb(100, 80, 56), M.Wood, false)
		ball(model, "Hueco", base * CFn(0, 5, -7), 6, rgb(20, 16, 12), M.SmoothPlastic, true)
		return main
	elseif p.Id == "Umbria_VainaEnea" then
		local main = ball(model, "Vaina", base * CFn(0, 7, 0), 8, rgb(170, 140, 90), M.Wood, false)
		part(model, "Cuerda", V3(0.4, 14, 0.4), base * CFn(0, 17, 0), rgb(190, 170, 120), M.Fabric, true)
		return main
	end
	return nil
end

-- El Árbol Madre: al norte del barrio, un tronco de 120 studs con raíces enormes que sube hasta la niebla
function Kit.world(folder: Instance, S: any)
	local O = S.Origin
	local w = Instance.new("Model")
	w.Name = "ArbolMadre"
	w.Parent = folder
	local tx, tz = 0, -210
	local gy = S.heightAt(O.X + tx, O.Z + tz)
	local base = CFn(O.X + tx, gy - 6, O.Z + tz)
	cyl(w, "Tronco", base, 900, 120, C.Bark, M.Wood)
	cyl(w, "Corteza", base * CFn(0, 0, 0), 300, 126, C.BarkDark, M.Wood, true)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local top = (base * CFn(math.cos(a) * 50, 90, math.sin(a) * 50)).Position
		local foot = (base * CFn(math.cos(a) * 130, 0, math.sin(a) * 130)).Position
		beam(w, "RaizMadre", top, foot, 22, if k % 2 == 0 then C.Bark else C.BarkDark, M.Wood, false)
	end
	-- la savia dorada que baja por la corteza y los anillos de setas que brillan
	for i = 0, 5 do
		local a = i * 1.1
		part(w, "Savia", V3(4, 60, 1), base * ANG(0, a, 0) * CFn(0, 120 + i * 70, -62.5), C.Amber, M.Neon, true, { Transparency = 0.2 })
		for k = 0, 3 do
			local b2 = a + k * 0.25
			local f = ball(w, "SetaTronco", base * ANG(0, b2, 0) * CFn(0, 60 + i * 80 + k * 4, -63), 4 + k, C.Glow[(i % 3) + 1], M.Neon, true)
			if k == 0 and i % 2 == 0 then
				glow(f, C.Glow[(i % 3) + 1], 50, 1.4)
			end
		end
	end
	-- la copa, muy arriba, y lianas que cuelgan
	cyl(w, "Copa", base * CFn(0, 880, 0), 40, 1200, C.LeafDark, M.Grass, true)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		beam(w, "Liana", (base * CFn(math.cos(a) * 200, 870, math.sin(a) * 200)).Position, (base * CFn(math.cos(a) * 190, 300, math.sin(a) * 190)).Position, 1.2, C.Leaf, M.Grass, true)
	end
end

return Kit
