-- NivalisKit (servidor): las FORMAS y los COLORES de Fortaleza Albor, la capital de Nivalis (marco común de
-- los planetas: World/PlanetCityBuilder lo usa con el plano shared/Cosmos/NivalisCity; World/PlanetWorld,
-- con la superficie shared/Cosmos/Nivalis). Solo piezas (ninguna malla nueva).
--
-- Estilo (diseno-mundos §3.4.7): piedra gris de mil años y hielo tallado; murallas con almenas, torres
-- con tejados-farol, casas de tejado empinado cubierto de nieve y un farol ámbar en lo alto, hogueras de
-- musgo en la plaza, la Estatua Rota de la Reina. Fuera: el Bosque de Escarcha, cristales de hielo, el
-- Palacio de Escarcha en la ladera norte y las auroras (verdes y rosas) colgando del cielo.
-- Aquí siempre es de noche: los faroles están siempre encendidos (sin StreetLamp); las ventanas de las
-- casas Box siguen el horario de noche de siempre (NightWindow).

local Builder = require(script.Parent.Builder)
local Palette = require(script.Parent.Kit.Palette)

local Kit = {}

local V3 = Vector3.new
local CFn = CFrame.new
local ANG = CFrame.Angles
local rgb = Color3.fromRGB
local M = Enum.Material

local YAW = { N = 0, S = math.pi, E = -math.pi / 2, W = math.pi / 2 }

local C = {
	Stone = rgb(118, 126, 140),
	StoneDark = rgb(84, 92, 108),
	StoneLight = rgb(150, 158, 172),
	Snow = rgb(238, 244, 252),
	Ice = rgb(172, 214, 240),
	IceDeep = rgb(110, 170, 214),
	Amber = rgb(255, 186, 104),
	Iron = rgb(40, 44, 54),
	Wood = rgb(74, 56, 44),
	Wool = { rgb(150, 54, 60), rgb(46, 104, 120), rgb(170, 128, 60), rgb(90, 70, 130) },
	Aurora = { rgb(90, 255, 170), rgb(120, 255, 210), rgb(255, 120, 200), rgb(170, 120, 255) },
	Banner = rgb(40, 70, 140),
}
Kit.C = C

Kit.Colors = {
	Floor = rgb(96, 104, 118),
	FloorMaterial = M.Slate,
	Wall = C.Stone,
	Metal = C.Iron,
	Lamp = C.Amber,
	Light = rgb(255, 200, 140),
	Sign = rgb(30, 34, 46),
	SignText = rgb(255, 210, 150),
	Pad = rgb(108, 116, 132),
	PadRing = rgb(110, 240, 200),
	PadLight = rgb(180, 255, 232),
	Poi = C.StoneDark,
	PoiLight = C.Amber,
}

-- Estilos de los edificios Box (Kit/Building): piedra con ventanas ámbar y hielo tallado
Palette.Styles.NivalisPiedra = Palette.Styles.NivalisPiedra or {
	Wall = { rgb(118, 124, 138), rgb(128, 134, 146), rgb(108, 116, 130) },
	WallMaterial = M.Slate,
	Trim = rgb(70, 76, 92),
	TrimMaterial = M.Basalt,
	Glass = rgb(150, 108, 66),
	Bay = 9,
	WindowW = 3,
	WindowH = 4.6,
	Lintels = true,
	Shutters = { rgb(60, 72, 96), rgb(96, 56, 50) },
	Balconies = "None",
	Roof = "Gable",
	RoofColor = rgb(58, 64, 80),
	RoofMaterial = M.Slate,
}
Palette.Styles.NivalisHielo = Palette.Styles.NivalisHielo or {
	Wall = { rgb(170, 206, 232), rgb(186, 216, 238), rgb(158, 198, 228) },
	WallMaterial = M.Ice,
	Trim = rgb(226, 238, 250),
	TrimMaterial = M.Marble,
	Glass = rgb(70, 120, 180),
	Bay = 8,
	WindowW = 3.4,
	WindowH = 6,
	Lintels = true,
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
Kit.part = part

local function cyl(parent: Instance, name: string, base: CFrame, height: number, diameter: number, color: Color3, mat: Enum.Material, decor: boolean?): BasePart
	return part(parent, name, V3(height, diameter, diameter), base * CFn(0, height / 2, 0) * ANG(0, 0, math.pi / 2), color, mat, decor, { Shape = Enum.PartType.Cylinder })
end

local function ball(parent: Instance, name: string, at: CFrame, d: number, color: Color3, mat: Enum.Material, decor: boolean?): BasePart
	return part(parent, name, V3(d, d, d), at, color, mat, decor, { Shape = Enum.PartType.Ball })
end

local function glow(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
end

-- Tejado a dos aguas (cumbrera a lo largo de X local): dos cuñas, con su capa de nieve encima
local function gable(parent: Instance, frame: CFrame, w: number, d: number, rise: number, color: Color3, snow: boolean)
	local half = d / 2
	part(parent, "TejadoN", V3(w, rise, half), frame * CFn(0, rise / 2, -half / 2), color, M.Slate, false, { ClassName = "WedgePart" })
	part(parent, "TejadoS", V3(w, rise, half), frame * CFn(0, rise / 2, half / 2) * ANG(0, math.pi, 0), color, M.Slate, false, { ClassName = "WedgePart" })
	if snow then
		part(parent, "NieveN", V3(w + 0.4, rise * 0.92, half * 0.92), frame * CFn(0, rise / 2 + 0.35, -half / 2 - 0.1), C.Snow, M.Snow, true, { ClassName = "WedgePart" })
		part(parent, "NieveS", V3(w + 0.4, rise * 0.92, half * 0.92), frame * CFn(0, rise / 2 + 0.35, half / 2 + 0.1) * ANG(0, math.pi, 0), C.Snow, M.Snow, true, { ClassName = "WedgePart" })
	end
end

-- Un farol ámbar de cristal (la luz de Nivalis): marco de hierro y cristal encendido
local function lantern(parent: Instance, at: CFrame, size: number, light: boolean?)
	part(parent, "FarolMarco", V3(size * 1.15, size * 0.18, size * 1.15), at * CFn(0, size * 0.6, 0), C.Iron, M.Metal, true)
	part(parent, "FarolBase", V3(size * 1.15, size * 0.18, size * 1.15), at * CFn(0, -size * 0.6, 0), C.Iron, M.Metal, true)
	local glass = part(parent, "FarolLuz", V3(size, size, size), at, C.Amber, M.Neon, true, { Transparency = 0.15 })
	if light then
		glow(glass, C.Amber, 22 + size * 2, 1.3)
	end
	return glass
end

local function yawOf(b: { [string]: any }): number
	return YAW[b.Face or "N"] or 0
end

---------------------------------------------------------------------
-- Las formas del plano
---------------------------------------------------------------------
Kit.Shapes = {}

-- Un lienzo de la Muralla Vieja: piedra, paso de ronda nevado y almenas hacia fuera
Kit.Shapes.Muralla = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local x0, x1, z0, z1 = ctx.City.footprint(b)
	local H = b.Height or 18
	ctx.box(m, "Lienzo", x0, x1, z0, z1, 0, H, C.Stone, M.Slate)
	ctx.box(m, "Zocalo", x0 - 0.4, x1 + 0.4, z0 - 0.4, z1 + 0.4, 0, 2.2, C.StoneDark, M.Basalt)
	ctx.box(m, "Ronda", x0 - 0.3, x1 + 0.3, z0 - 0.3, z1 + 0.3, H, H + 0.8, C.StoneLight, M.Cobblestone)
	ctx.box(m, "NieveRonda", x0, x1, z0, z1, H + 0.8, H + 1.3, C.Snow, M.Snow, true)
	-- almenas en el borde de fuera (el que mira lejos del centro)
	local along = (x1 - x0) >= (z1 - z0)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local len = if along then x1 - x0 else z1 - z0
	local n = math.floor(len / 7)
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		if along then
			local x = x0 + t * len
			local zo = if cz < 0 then z0 else z1 - 1.6
			local zi = if cz < 0 then z1 - 1.2 else z0
			ctx.box(m, "Almena", x - 1.6, x + 1.6, zo, zo + 1.6, H + 0.8, H + 4, C.Stone, M.Slate)
			ctx.box(m, "Pretil", x - 1.4, x + 1.4, zi, zi + 1.2, H + 0.8, H + 2.6, C.StoneLight, M.Slate, true)
			if i % 4 == 1 then
				local zf = if cz < 0 then z1 + 0.1 else z0 - 0.5
				ctx.box(m, "Caramb", x - 0.2, x + 0.2, zf, zf + 0.4, H - 2.6, H, C.Ice, M.Ice, true, { Transparency = 0.2 })
			end
		else
			local z = z0 + t * len
			local xo = if cx < 0 then x0 else x1 - 1.6
			local xi = if cx < 0 then x1 - 1.2 else x0
			ctx.box(m, "Almena", xo, xo + 1.6, z - 1.6, z + 1.6, H + 0.8, H + 4, C.Stone, M.Slate)
			ctx.box(m, "Pretil", xi, xi + 1.2, z - 1.4, z + 1.4, H + 0.8, H + 2.6, C.StoneLight, M.Slate, true)
			if i % 4 == 1 then
				local xf = if cx < 0 then x1 + 0.1 else x0 - 0.5
				ctx.box(m, "Caramb", xf, xf + 0.4, z - 0.2, z + 0.2, H - 2.6, H, C.Ice, M.Ice, true, { Transparency = 0.2 })
			end
		end
	end
	-- dos saeteras oscuras y un estandarte del Regente
	for _, t in { 0.3, 0.7 } do
		if along then
			local x = x0 + t * len
			local zi = if cz < 0 then z1 + 0.05 else z0 - 0.15
			ctx.box(m, "Saetera", x - 0.5, x + 0.5, zi, zi + 0.1, 7, 11, rgb(16, 20, 30), M.SmoothPlastic, true)
		else
			local z = z0 + t * len
			local xi = if cx < 0 then x1 + 0.05 else x0 - 0.15
			ctx.box(m, "Saetera", xi, xi + 0.1, z - 0.5, z + 0.5, 7, 11, rgb(16, 20, 30), M.SmoothPlastic, true)
		end
	end
	Builder.streamable(m)
	return m
end

-- Torre de esquina de la muralla: cilindro de piedra, corona almenada y tejado-farol
Kit.Shapes.TorreMuralla = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.CF(b.X, b.Z, 0)
	local R = b.R or 8
	local H = b.Height or 30
	cyl(m, "Fuste", base, H, R * 2, C.Stone, M.Slate)
	cyl(m, "Zocalo", base, 3, R * 2 + 1, C.StoneDark, M.Basalt)
	cyl(m, "Corona", base * CFn(0, H, 0), 2.4, R * 2 + 2, C.StoneLight, M.Cobblestone)
	cyl(m, "Tejado1", base * CFn(0, H + 2.4, 0), 3, R * 1.5, rgb(58, 64, 80), M.Slate)
	cyl(m, "Tejado2", base * CFn(0, H + 5.4, 0), 3, R * 0.95, rgb(58, 64, 80), M.Slate)
	cyl(m, "Nieve", base * CFn(0, H + 8.4, 0), 0.6, R * 0.95, C.Snow, M.Snow, true)
	lantern(m, base * CFn(0, H + 10.4, 0), 2.6, false)
	Builder.streamable(m)
	return m
end

-- La Torre del Farolero: alta, con la sala del farol arriba (luz que se ve desde todo el barrio)
Kit.Shapes.Torre = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.CF(b.X, b.Z, 0)
	local R = b.R or 7
	local H = b.Height or 40
	cyl(m, "Fuste", base, H - 8, R * 2, C.Stone, M.Slate)
	cyl(m, "Zocalo", base, 3, R * 2 + 1.2, C.StoneDark, M.Basalt)
	for i = 1, 3 do
		cyl(m, "Anillo", base * CFn(0, i * (H - 8) / 4, 0), 0.8, R * 2 + 0.6, C.StoneDark, M.Basalt, true)
	end
	part(m, "Puerta", V3(4, 7, 0.6), base * CFn(0, 3.5, R - 0.1), C.Wood, M.WoodPlanks, true)
	cyl(m, "Balcon", base * CFn(0, H - 8, 0), 1, R * 2 + 3, C.StoneLight, M.Cobblestone)
	local room = part(m, "SalaFarol", V3(R * 1.3, 5.5, R * 1.3), base * CFn(0, H - 4.25, 0), C.Amber, M.Neon, true, { Transparency = 0.2 })
	glow(room, C.Amber, 60, 2)
	for _, s in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		part(m, "Pilar", V3(0.7, 5.5, 0.7), base * CFn(s[1] * R * 0.68, H - 4.25, s[2] * R * 0.68), C.Iron, M.Metal, true)
	end
	cyl(m, "Tejado1", base * CFn(0, H - 1.5, 0), 2.4, R * 1.8, rgb(58, 64, 80), M.Slate)
	cyl(m, "Tejado2", base * CFn(0, H + 0.9, 0), 2.4, R * 1.1, rgb(58, 64, 80), M.Slate)
	cyl(m, "Aguja", base * CFn(0, H + 3.3, 0), 4, 1, C.Iron, M.Metal, true)
	Builder.streamable(m)
	return m
end

-- Casa de tejado-farol: piedra, tejado empinado nevado, farol en la cumbrera, ventanas ámbar, chimenea
Kit.Shapes.CasaFarol = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local frame = ctx.CF(b.X, b.Z, 0, yawOf(b))
	local w, d = b.W or 16, b.D or 14
	local H = b.Height or 24
	local wallH = math.floor(H * 0.5)
	local tone = string.byte(b.Id, -1) % 3
	local wall = if tone == 0 then C.Stone elseif tone == 1 then rgb(128, 132, 144) else rgb(108, 114, 128)
	part(m, "Muros", V3(w, wallH, d), frame * CFn(0, wallH / 2, 0), wall, M.Slate)
	part(m, "Zocalo", V3(w + 0.6, 2, d + 0.6), frame * CFn(0, 1, 0), C.StoneDark, M.Basalt)
	part(m, "Alero", V3(w + 1.4, 0.8, d + 1.4), frame * CFn(0, wallH + 0.4, 0), C.StoneDark, M.Basalt)
	gable(m, frame * CFn(0, wallH + 0.8, 0), w + 1.2, d + 1.4, H - wallH - 3, rgb(58, 64, 80), true)
	-- puerta y ventanas (delante, −Z local)
	part(m, "Puerta", V3(3.6, 6.6, 0.5), frame * CFn(0, 3.3 + 0.4, -d / 2 - 0.2), C.Wood, M.WoodPlanks, true)
	for _, x in { -w * 0.3, w * 0.3 } do
		part(m, "Ventana", V3(2.4, 3, 0.3), frame * CFn(x, wallH * 0.62, -d / 2 - 0.15), C.Amber, M.Neon, true, { Transparency = 0.25 })
		part(m, "Dintel", V3(3, 0.5, 0.5), frame * CFn(x, wallH * 0.62 + 1.8, -d / 2 - 0.2), C.StoneDark, M.Basalt, true)
	end
	-- esquinas de sillería, contraventanas y el escalón de la puerta
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(m, "Esquina", V3(1, wallH, 1), frame * CFn(sx * (w / 2 - 0.3), wallH / 2, sz * (d / 2 - 0.3)), C.StoneLight, M.Cobblestone, true)
		end
		part(m, "Contraventana", V3(0.9, 3.2, 0.25), frame * CFn(sx * w * 0.3 + sx * 1.7, wallH * 0.62, -d / 2 - 0.3), C.Wool[2]:Lerp(C.Iron, 0.5), M.Wood, true)
	end
	part(m, "Escalon", V3(5, 0.6, 1.6), frame * CFn(0, 0.3, -d / 2 - 0.8), C.StoneDark, M.Basalt, true)
	part(m, "MarcoPuerta", V3(4.6, 0.8, 0.7), frame * CFn(0, 7.3, -d / 2 - 0.25), C.StoneDark, M.Basalt, true)
	part(m, "VentanaAtras", V3(2.4, 3, 0.3), frame * CFn(0, wallH * 0.62, d / 2 + 0.15), C.Amber, M.Neon, true, { Transparency = 0.25 })
	-- carámbanos bajo el alero
	for i = -2, 2 do
		part(m, "Caramb", V3(0.3, 1.2 + (i % 2) * 0.8, 0.3), frame * CFn(i * w * 0.18, wallH - 0.2, -d / 2 - 0.6), C.Ice, M.Ice, true, { Transparency = 0.2 })
	end
	-- el farol de la cumbrera (lo que da nombre al barrio)
	lantern(m, frame * CFn(0, H - 0.4, 0), 1.8, tone == 0)
	-- chimenea con humo
	local chimney = part(m, "Chimenea", V3(1.8, 6, 1.8), frame * CFn(w * 0.32, wallH + (H - wallH) * 0.55, d * 0.18), C.StoneDark, M.Brick)
	if tone ~= 2 then
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Color = ColorSequence.new(rgb(190, 196, 210))
		smoke.Size = NumberSequence.new(1.2, 4)
		smoke.Transparency = NumberSequence.new(0.55, 1)
		smoke.Lifetime = NumberRange.new(4, 6)
		smoke.Speed = NumberRange.new(2, 3)
		smoke.Rate = 2
		smoke.EmissionDirection = Enum.NormalId.Top
		smoke.Parent = chimney
	end
	Builder.streamable(m)
	return m
end

-- Puesto del Mercado de Hielo: cuatro postes, mostrador, toldo de lana y un farolito
Kit.Shapes.Puesto = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local frame = ctx.CF(b.X, b.Z, 0, yawOf(b))
	local w, d = b.W or 10, b.D or 8
	local H = b.Height or 9
	local wool = C.Wool[(string.byte(b.Id, -2) % #C.Wool) + 1]
	for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		part(m, "Poste", V3(0.6, H, 0.6), frame * CFn(s[1] * (w / 2 - 0.4), H / 2, s[2] * (d / 2 - 0.4)), C.Wood, M.Wood)
	end
	part(m, "Mostrador", V3(w - 1, 3.4, 1.6), frame * CFn(0, 1.7, -d / 2 + 1.2), C.Wood, M.WoodPlanks)
	part(m, "Mercancia", V3(w - 2, 0.8, 1.2), frame * CFn(0, 3.8, -d / 2 + 1.2), wool, M.Fabric, true)
	part(m, "Toldo", V3(w + 1, 0.4, d + 1.6), frame * CFn(0, H + 0.6, -0.4) * ANG(math.rad(-10), 0, 0), wool, M.Fabric)
	part(m, "NieveToldo", V3(w + 0.6, 0.3, d + 1.2), frame * CFn(0, H + 0.95, -0.4) * ANG(math.rad(-10), 0, 0), C.Snow, M.Snow, true)
	lantern(m, frame * CFn(w / 2 - 1, H - 1.6, -d / 2 + 0.6), 1, false)
	return m
end

-- Hoguera de musgo: anillo de piedra, troncos y fuego (calienta: Nivalis.hazardContext)
Kit.Shapes.Hoguera = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.CF(b.X, b.Z, 0)
	local R = b.R or 2.5
	cyl(m, "Brasero", base, 2, R * 2, C.StoneDark, M.Basalt)
	cyl(m, "Borde", base * CFn(0, 2, 0), 0.5, R * 2 + 0.4, C.StoneLight, M.Cobblestone, true)
	for k = 0, 2 do
		part(m, "Tronco", V3(0.7, 0.7, R * 1.6), base * CFn(0, 2.4, 0) * ANG(0, k * math.pi / 3, 0), C.Wood, M.Wood, true)
	end
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + 0.4
		part(m, "Asiento", V3(3.4, 1, 1.2), base * CFn(math.cos(a) * (R + 3.4), 0.5, math.sin(a) * (R + 3.4)) * ANG(0, -a + math.pi / 2, 0), C.Wood, M.Wood, true)
	end
	local core = ball(m, "Brasas", base * CFn(0, 2.6, 0), R * 0.9, rgb(255, 120, 40), M.Neon, true)
	local fire = Instance.new("Fire")
	fire.Size = R * 2
	fire.Heat = 8
	fire.Color = rgb(255, 150, 60)
	fire.SecondaryColor = rgb(255, 80, 30)
	fire.Parent = core
	glow(core, rgb(255, 150, 70), 26, 2)
	return m
end

-- La Estatua Rota de la Reina Alva: pedestal, manto de piedra, sin cabeza; velas y su corona en el suelo
Kit.Shapes.Estatua = function(ctx: any, parent: Instance, b: { [string]: any }): Model
	local m = Builder.model(b.Id, parent)
	local base = ctx.CF(b.X, b.Z, 0, math.pi) -- (mira al sur, a la plaza)
	part(m, "Pedestal1", V3(8, 2, 8), base * CFn(0, 1, 0), C.StoneDark, M.Basalt)
	part(m, "Pedestal2", V3(6, 3, 6), base * CFn(0, 3.5, 0), C.Stone, M.Marble)
	cyl(m, "Manto", base * CFn(0, 5, 0), 6.5, 3.6, C.StoneLight, M.Marble)
	part(m, "Hombros", V3(3.8, 1.2, 2), base * CFn(0, 11.6, 0), C.StoneLight, M.Marble)
	part(m, "BrazoI", V3(0.9, 3.6, 0.9), base * CFn(-2.1, 9.8, -0.3) * ANG(math.rad(-12), 0, math.rad(8)), C.StoneLight, M.Marble)
	part(m, "Cuello", V3(1, 0.8, 1), base * CFn(0, 12.6, 0), C.StoneLight, M.Marble)
	part(m, "Rotura", V3(1.3, 0.25, 1.3), base * CFn(0, 13.05, 0) * ANG(0.2, 0.4, 0.15), C.StoneDark, M.Slate, true)
	part(m, "Bufanda", V3(4, 0.8, 2.2), base * CFn(0, 12.2, 0), rgb(150, 54, 60), M.Fabric, true)
	local crown = part(m, "Corona", V3(1.6, 0.8, 1.6), base * CFn(2.2, 4.4, -2.4) * ANG(0.3, 0.5, 0.6), rgb(255, 210, 110), M.Neon, true)
	glow(crown, rgb(255, 220, 140), 10, 0.8)
	for i = -2, 2 do
		local c = part(m, "Vela", V3(0.35, 0.9, 0.35), base * CFn(i * 0.9, 2.45, -3.4), rgb(246, 236, 210), M.SmoothPlastic, true)
		ball(m, "Llama", c.CFrame * CFn(0, 0.6, 0), 0.3, rgb(255, 196, 110), M.Neon, true)
	end
	part(m, "Placa", V3(3.6, 1.2, 0.2), base * CFn(0, 3.5, -3.05), rgb(200, 170, 100), M.Metal, true)
	Builder.streamable(m)
	return m
end

---------------------------------------------------------------------
-- Lo de encima de los Box, las farolas, el estanque, lo que se recoge y los extras de la plaza
---------------------------------------------------------------------
function Kit.dressBox(ctx: any, model: Model, b: { [string]: any }, cf: CFrame, info: { [string]: any })
	local w, d = b.W or 20, b.D or 20
	local top = (info and info.Top) or ctx.City.topOf(b)
	-- nieve en el tejado y carámbanos en la fachada
	part(model, "NieveTejado", V3(w + 0.4, 0.6, d + 0.4), cf * CFn(0, top + 0.1, 0), C.Snow, M.Snow, true)
	for i = -2, 2 do
		part(model, "Caramb", V3(0.35, 1.4 + (i % 2), 0.35), cf * CFn(i * w * 0.2, top - 3.4, -d / 2 - 0.4), C.Ice, M.Ice, true, { Transparency = 0.2 })
	end
	part(model, "Escalon", V3(9, 0.6, 2), cf * CFn(0, 0.3, -d / 2 - 1), C.StoneDark, M.Basalt, true)
	for _, sx in { -1, 1 } do
		part(model, "Jamba", V3(1, 11, 1), cf * CFn(sx * 4.8, 5.5, -d / 2 - 0.4), C.StoneLight, M.Cobblestone, true)
	end
	if b.Style == "NivalisHielo" then
		-- agujas de hielo transparente en las esquinas (el estilo del Palacio)
		for _, s in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			local at = cf * CFn(s[1] * (w / 2 - 0.8), 0, s[2] * (d / 2 - 0.8))
			cyl(model, "AgujaHielo", at, top + 6, 2.2, C.IceDeep, M.Glass, true)
			cyl(model, "Punta", at * CFn(0, top + 6, 0), 3, 1, C.Ice, M.Neon, true)
		end
	elseif b.Ground ~= "Closed" then
		-- un farol junto a la puerta
		lantern(model, cf * CFn(w / 2 - 1.6, 8, -d / 2 - 0.9), 1.2, true)
	end
end

function Kit.lamp(ctx: any, parent: Instance, cf: CFrame)
	local m = Builder.model("Farol", parent)
	part(m, "Pie", V3(1.6, 1.4, 1.6), cf * CFn(0, 0.7, 0), C.StoneDark, M.Basalt)
	part(m, "Poste", V3(0.5, 8.4, 0.5), cf * CFn(0, 5.6, 0), C.Iron, M.Metal)
	part(m, "Brazo", V3(0.3, 0.3, 1.8), cf * CFn(0, 9.4, -0.8), C.Iron, M.Metal, true)
	lantern(m, cf * CFn(0, 8.6, -1.6), 1.1, true)
	part(m, "Nieve", V3(1.4, 0.2, 1.4), cf * CFn(0, 1.45, 0), C.Snow, M.Snow, true)
	return m
end

function Kit.pit(ctx: any, parent: Instance, p: { [string]: any })
	if p.Kind ~= "Disc" then
		return
	end
	local m = Builder.model("EstanqueRoto", parent)
	local base = ctx.CF(p.X, p.Z, 0)
	-- el agua negra helada abajo y placas de hielo roto flotando (no se pisan: se cae)
	cyl(m, "AguaHelada", base * CFn(0, -p.Depth + 3, 0), 0.4, p.R * 2, rgb(30, 60, 96), M.Glass, true)
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		local r = p.R * (0.35 + (k % 3) * 0.18)
		part(m, "Placa", V3(3 + k % 2, 0.5, 2.5), base * CFn(math.cos(a) * r, -0.6, math.sin(a) * r) * ANG(0.1 * (k % 3), a, 0.08), C.Ice, M.Ice, true, { Transparency = 0.15 })
	end
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		part(m, "Orilla", V3(3.4, 1, 1.4), base * CFn(math.cos(a) * (p.R + 0.6), 0.3, math.sin(a) * (p.R + 0.6)) * ANG(0, -a, 0), C.Snow, M.Snow, true)
	end
end

function Kit.gather(ctx: any, parent: Instance, g: { [string]: any })
	local base = ctx.CF(g.X, g.Z, 0.9)
	if g.Item == "CristalEco" then
		for k = 0, 3 do
			local c = part(parent, "CristalEco", V3(0.8, 2.4 + k * 0.6, 0.8), base * CFn((k - 1.5) * 0.7, 1.2, (k % 2) * 0.6) * ANG(0.25 * (k - 1.5), 0, 0.2), rgb(140, 230, 255), M.Neon, true, { Transparency = 0.25 })
			if k == 0 then
				glow(c, rgb(140, 230, 255), 12, 0.9)
			end
		end
	else
		for k = 0, 2 do
			ball(parent, "Musgo", base * CFn((k - 1) * 1.1, 0.4, (k % 2) * 0.8), 1.6, rgb(120, 170, 130), M.Grass, true)
		end
		ball(parent, "Escarcha", base * CFn(0, 0.9, 0), 1, C.Snow, M.Snow, true)
	end
end

function Kit.extras(ctx: any, model: Model)
	local m = Builder.model("Detalles", model)
	-- arcos de las cuatro puertas de la muralla (dintel con su farol)
	for _, g in ctx.City.Gates do
		local alongX = g.Dir[2] ~= 0
		if alongX then
			ctx.box(m, "Dintel", g.X - 17, g.X + 17, g.Z - 3, g.Z + 3, 14, 19, C.Stone, M.Slate, true)
			ctx.box(m, "NieveDintel", g.X - 17, g.X + 17, g.Z - 3, g.Z + 3, 19, 19.5, C.Snow, M.Snow, true)
		else
			ctx.box(m, "Dintel", g.X - 3, g.X + 3, g.Z - 15, g.Z + 15, 14, 19, C.Stone, M.Slate, true)
			ctx.box(m, "NieveDintel", g.X - 3, g.X + 3, g.Z - 15, g.Z + 15, 19, 19.5, C.Snow, M.Snow, true)
		end
		lantern(m, ctx.CF(g.X, g.Z, 12.6), 1.6, false)
	end
	-- estandartes azules del Regente en el Patio de Armas
	for _, p in { { -50, -46 }, { 50, -46 }, { -50, 38 }, { 50, 38 } } do
		part(m, "Mastil", V3(0.5, 16, 0.5), ctx.CF(p[1], p[2], 8), C.Iron, M.Metal)
		part(m, "Estandarte", V3(0.2, 7, 3.2), ctx.CF(p[1], p[2], 11.5) * CFn(0, 0, 1.7), C.Banner, M.Fabric, true)
		part(m, "Emblema", V3(0.25, 1.6, 1.6), ctx.CF(p[1], p[2], 12) * CFn(0, 0, 1.7), rgb(200, 230, 255), M.Neon, true)
	end
	-- el bordillo de piedra de la Plaza de los Faroles y las franjas del Patio de Armas
	for k = 0, 27 do
		local a = k / 28 * math.pi * 2
		part(m, "Bordillo", V3(7.6, 1.2, 1.6), ctx.CF(math.cos(a) * 38.6, 80 + math.sin(a) * 38.6, 1) * ANG(0, -a + math.pi / 2, 0), C.StoneDark, M.Basalt, true)
	end
	for i = -5, 5 do
		ctx.box(m, "Franja", i * 10 - 0.6, i * 10 + 0.6, -52, 40, 0.9, 0.95, C.StoneDark, M.Basalt, true)
	end
	-- montones de nieve contra la muralla (por dentro)
	local R = ctx.City.Rect
	for i = 0, 7 do
		local x = -100 + i * 28 + (i % 2) * 6
		if math.abs(x) > 22 then
			part(m, "Ventisquero", V3(10, 3, 6), ctx.CF(x, R.Z0 + 12, 1) * ANG(0, 0, 0), C.Snow, M.Snow, false, { ClassName = "WedgePart" })
			part(m, "Ventisquero", V3(10, 3, 6), ctx.CF(x + 8, R.Z1 - 12, 1) * ANG(0, math.pi, 0), C.Snow, M.Snow, false, { ClassName = "WedgePart" })
		end
	end
	-- leña apilada junto a las hogueras y una carretilla de musgo
	for _, f in ctx.City.Fires do
		part(m, "Lena", V3(2.4, 1.2, 1.2), ctx.CF(f.X + 4.5, f.Z + 1.5, 0.6), C.Wood, M.Wood, true)
	end
	-- arcos de hielo tallado sobre la Calle Norte (lo que queda de los puentes de hielo de la reina)
	for _, z in { -70, -90 } do
		for _, x in { -13, 13 } do
			part(m, "PilarHielo", V3(2.4, 16, 2.4), ctx.CF(x, z, 8), C.Ice, M.Ice, true, { Transparency = 0.1 })
		end
		part(m, "ArcoHielo", V3(28.4, 2.2, 2.6), ctx.CF(0, z, 16.6), C.IceDeep, M.Glass, true, { Transparency = 0.2 })
		part(m, "ArcoNieve", V3(28.4, 0.5, 2.6), ctx.CF(0, z, 17.95), C.Snow, M.Snow, true)
		lantern(m, ctx.CF(0, z, 14.4), 1, false)
	end
	-- cajas, barriles y trineos del mercado
	for i, p in { { -44, 40 }, { 44, 40 }, { -40, 52 }, { 46, 52 }, { 52, -52 }, { -26, -50 } } do
		if i % 2 == 0 then
			cyl(m, "Barril", ctx.CF(p[1], p[2], 0.9), 2.4, 1.8, C.Wood, M.Wood, true)
		else
			part(m, "Caja", V3(2, 2, 2), ctx.CF(p[1], p[2], 1.9) * ANG(0, i, 0), C.Wood, M.WoodPlanks, true)
		end
	end
	for _, p in { { -78, 10 }, { 78, -6 } } do
		part(m, "Trineo", V3(3, 0.8, 6), ctx.CF(p[1], p[2], 1.6), C.Wood, M.WoodPlanks, true)
		for _, x in { -1.3, 1.3 } do
			part(m, "Patin", V3(0.3, 0.5, 6.6), ctx.CF(p[1] + x, p[2], 1.1), C.Iron, M.Metal, true)
		end
		part(m, "Carga", V3(2.4, 1.4, 3.4), ctx.CF(p[1], p[2], 2.7), C.Wool[2], M.Fabric, true)
	end
	part(m, "Carretilla", V3(3, 1.6, 2), ctx.CF(-26, 104, 0.8), C.Wood, M.WoodPlanks, true)
	ball(m, "MusgoCarga", ctx.CF(-26, 104, 2.1), 2, rgb(120, 170, 130), M.Grass, true)
end

---------------------------------------------------------------------
-- Fuera del barrio: flora, puntos de interés, el Palacio de Escarcha y las auroras
---------------------------------------------------------------------
-- (pino de escarcha: tronco y tres pisos girados, blancos de nieve; roca nevada; cristales de hielo)
function Kit.decor(folder: Instance, d: { [string]: any })
	local base = CFn(d.Pos) * ANG(0, d.Turn, 0)
	if d.Kind == "PinoEscarcha" then
		local h = 10 + d.Size * 1.2
		part(folder, "Tronco", V3(1.2, h * 0.4, 1.2), base * CFn(0, h * 0.2, 0), rgb(60, 48, 44), M.Wood, false)
		for i = 0, 2 do
			local s = (1 - i * 0.28) * (4 + d.Size * 0.45)
			local y = h * (0.3 + i * 0.22)
			part(folder, "Piso", V3(s, h * 0.24, s), base * CFn(0, y, 0) * ANG(0, (i % 2) * math.pi / 4, 0), rgb(48, 78, 82), M.Grass, true)
			part(folder, "Nieve", V3(s * 0.86, h * 0.08, s * 0.86), base * CFn(0, y + h * 0.13, 0) * ANG(0, (i % 2) * math.pi / 4, 0), C.Snow, M.Snow, true)
		end
	elseif d.Kind == "Cristal" then
		local h = 4 + d.Size * 0.6
		for k = 0, 2 do
			part(folder, "Cristal", V3(1.2 + k * 0.3, h * (1 - k * 0.25), 1.2 + k * 0.3), base * CFn((k - 1) * 1.2, h * 0.4, (k % 2) * 0.8) * ANG(0.3 * (k - 1), 0, 0.25 * (1 - k)), C.IceDeep, M.Glass, k > 0, { Transparency = 0.25 })
		end
	else
		local s = 3 + d.Size * 0.5
		ball(folder, "Roca", base * CFn(0, s * 0.2, 0), s, C.StoneDark, M.Slate, false)
		ball(folder, "Nieve", base * CFn(0, s * 0.45, 0), s * 0.7, C.Snow, M.Snow, true)
	end
end

function Kit.poi(model: Model, p: { [string]: any }, at: Vector3): BasePart?
	local base = CFn(at)
	if p.Id == "Nivalis_MiradorValle" then
		local main = part(model, "Balaustrada", V3(16, 3, 1.4), base * CFn(0, 1.5, -4), C.Stone, M.Slate)
		for i = -3, 3 do
			part(model, "Balaustre", V3(0.8, 3, 0.8), base * CFn(i * 2.2, 1.5, -4), C.StoneLight, M.Marble, true)
		end
		part(model, "Catalejo", V3(0.6, 0.6, 3), base * CFn(0, 4, -3) * ANG(0.3, 0, 0), C.Iron, M.Metal, true)
		lantern(model, base * CFn(-7, 4.5, -4), 1.2, true)
		return main
	elseif p.Id == "Nivalis_Fuentes" then
		local main = cyl(model, "Poza", base * CFn(0, -0.2, -10), 0.8, 14, rgb(120, 220, 255), M.Neon, false)
		main.Transparency = 0.4
		local steam = Instance.new("ParticleEmitter")
		steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		steam.Color = ColorSequence.new(rgb(230, 240, 255))
		steam.Size = NumberSequence.new(3, 8)
		steam.Transparency = NumberSequence.new(0.6, 1)
		steam.Lifetime = NumberRange.new(4, 7)
		steam.Speed = NumberRange.new(2, 4)
		steam.Rate = 4
		steam.EmissionDirection = Enum.NormalId.Top
		steam.Parent = main
		glow(main, rgb(160, 230, 255), 26, 1.2)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			ball(model, "Roca", base * CFn(math.cos(a) * 8, 0.5, -10 + math.sin(a) * 8), 3 + k % 2, C.StoneDark, M.Basalt, true)
		end
		return main
	elseif p.Id == "Nivalis_Antena" then
		local main = part(model, "Base", V3(10, 4, 10), base * CFn(0, 2, 0), C.StoneDark, M.Basalt)
		for _, s in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
			part(model, "Pata", V3(1, 44, 1), base * CFn(s[1] * 2.6, 24, s[2] * 2.6) * ANG(s[2] * 0.06, 0, -s[1] * 0.06), C.Iron, M.Metal)
		end
		for i = 1, 5 do
			part(model, "Travesano", V3(5.6 - i * 0.4, 0.4, 0.4), base * CFn(0, 4 + i * 7, 0), C.Iron, M.Metal, true)
		end
		local top = ball(model, "Faro", base * CFn(0, 47, 0), 4, C.Aurora[1], M.Neon, true)
		glow(top, C.Aurora[1], 60, 2)
		ball(model, "Anillo", base * CFn(0, 47, 0), 6, C.Aurora[3], M.ForceField, true)
		return main
	elseif p.Id == "Nivalis_Monasterio" then
		local main = part(model, "Nave", V3(26, 12, 14), base * CFn(0, 6, 0), C.StoneLight, M.Marble)
		gable(model, base * CFn(0, 12, 0), 27, 15, 6, rgb(70, 80, 100), true)
		cyl(model, "Campanario", base * CFn(14, 0, 0), 24, 7, C.StoneLight, M.Marble)
		cyl(model, "Cupula", base * CFn(14, 24, 0), 3, 5, C.IceDeep, M.Glass)
		local bell = ball(model, "Campana", base * CFn(14, 21, -3.2), 2.4, rgb(210, 180, 90), M.Metal, true)
		glow(bell, C.Amber, 14, 0.8)
		part(model, "Puerta", V3(4, 7, 0.4), base * CFn(0, 3.5, -7.1), C.Wood, M.WoodPlanks, true)
		return main
	elseif p.Id == "Nivalis_Cabana" then
		local main = part(model, "Cabana", V3(12, 7, 10), base * CFn(0, 3.5, 0), C.Wood, M.Wood)
		gable(model, base * CFn(0, 7, 0), 13, 11, 4, rgb(70, 54, 44), true)
		local chimney = part(model, "Chimenea", V3(1.6, 4, 1.6), base * CFn(4, 10, 2), C.StoneDark, M.Brick)
		local smoke = Instance.new("ParticleEmitter")
		smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
		smoke.Size = NumberSequence.new(1, 4)
		smoke.Transparency = NumberSequence.new(0.5, 1)
		smoke.Rate = 2
		smoke.Parent = chimney
		lantern(model, base * CFn(-4.5, 5, -5.6), 1, true)
		return main
	elseif p.Id == "Nivalis_LagoAhogados" then
		local main = part(model, "Cartel", V3(4, 2.4, 0.4), base * CFn(0, 3.4, 0) * ANG(0, 0, 0.12), C.Wood, M.WoodPlanks)
		part(model, "Palo", V3(0.4, 3, 0.4), base * CFn(0, 1.5, 0), C.Wood, M.Wood, true)
		Builder.sign(main, "HIELO FINO", Enum.NormalId.Front, rgb(255, 230, 200))
		return main
	end
	return nil
end

-- El Palacio de Escarcha (en la ladera norte) y las auroras que cuelgan del cielo del valle
function Kit.world(folder: Instance, S: any)
	local O = S.Origin
	local w = Instance.new("Model")
	w.Name = "Cielo y palacio"
	w.Parent = folder
	-- Palacio: alcázar de piedra con torres de hielo transparente y ventanas ámbar
	local px, pz = 0, -620
	local gy = S.heightAt(O.X + px, O.Z + pz)
	local pal = CFn(O.X + px, gy, O.Z + pz)
	part(w, "Zocalo", V3(130, 30, 70), pal * CFn(0, 5, 0), C.StoneDark, M.Basalt)
	part(w, "Cuerpo", V3(96, 34, 50), pal * CFn(0, 37, 0), C.StoneLight, M.Marble)
	part(w, "Galeria", V3(70, 16, 40), pal * CFn(0, 62, 0), C.Ice, M.Ice)
	for i = -3, 3 do
		part(w, "Ventana", V3(4, 9, 0.6), pal * CFn(i * 12, 38, -25.4), C.Amber, M.Neon, true, { Transparency = 0.2 })
	end
	for _, t in { { -54, 26, 70 }, { 54, 26, 70 }, { -30, -22, 92 }, { 30, -22, 92 }, { 0, 0, 120 } } do
		local tc = pal * CFn(t[1], 0, t[2])
		cyl(w, "Torre", tc, t[3], 14, C.Ice, M.Glass)
		cyl(w, "Corona", tc * CFn(0, t[3], 0), 6, 18, C.StoneLight, M.Marble)
		cyl(w, "Aguja", tc * CFn(0, t[3] + 6, 0), 18, 6, C.IceDeep, M.Glass)
		local tip = ball(w, "Luz", tc * CFn(0, t[3] + 25, 0), 4, rgb(150, 220, 255), M.Neon, true)
		if t[1] == 0 then
			glow(tip, rgb(150, 220, 255), 80, 2)
		end
	end
	-- Auroras: tres cortinas de paneles brillantes que ondulan sobre el norte del valle
	local r = S.rng(4242)
	for band = 0, 2 do
		local zc = -700 - band * 240
		local y = 520 + band * 90
		local n = 11
		for i = 0, n - 1 do
			local t = i / (n - 1)
			local x = -900 + t * 1800
			local z = zc + math.sin(t * math.pi * 2.2 + band) * 140
			local color = C.Aurora[((i + band) % #C.Aurora) + 1]
			local hgt = 180 + r() * 120
			part(w, "Aurora", V3(190, hgt, 2), CFn(O.X + x, O.Y + y + math.sin(t * 6 + band) * 40, O.Z + z) * ANG(0, math.sin(t * 5 + band) * 0.5, 0), color, M.Neon, true, { Transparency = 0.62 + r() * 0.12, CastShadow = false })
		end
	end
end

return Kit
