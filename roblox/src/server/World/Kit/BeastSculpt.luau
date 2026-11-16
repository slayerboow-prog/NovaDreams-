--!strict
-- BeastSculpt (servidor): los 24 monstruos del cartel de Valmar, pieza a pieza (estilo de bloques, colores lisos,
-- caras con ojos, cejas, hocico y dientes). BeastKit.beast los usa en lugar del cuerpo genérico.
--
--   BeastSculpt.frame(id) → { Root = Vector3, Hip = number }?   tamaño del tronco y largo de las piernas (en «k»)
--   BeastSculpt.build(ctx, id)                                 monta las piezas (Pierna/Brazo/Pata/Ala/Cola se articulan)
--
-- Coordenadas en unidades de k (la escala de la especie), relativas al centro del tronco; -Z es delante, +X la derecha.

local BeastSculpt = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB
local SMOOTH = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local WHITE = rgb(250, 250, 250)
local BLACK = rgb(18, 16, 16)
local IVORY = rgb(238, 230, 205)
local METAL = rgb(185, 190, 198)
local WOOD = rgb(112, 76, 46)

type Ctx = { Model: Model, Root: BasePart, Sp: any, K: number, Hip: number, Limb: any, Eye: any, Mat: any }
type Opt = { [string]: any }

-- BISEL: las piezas grandes llevan los bordes escalonados (tres bloques en cruz) para que la silueta no sea
-- una caja: el aspecto de figura de bloques del cartel, no de Minecraft
local BEVEL = {
	Tronco = true, Cabeza = true, Pecho = true, Pata = true, Pierna = true, Brazo = true, Muslo = true, Joroba = true, Puno = true,
	Hombro = true, Hombrera = true, Hocico = true, Torax = true, Cola = true, Falda = true, Pie = true, Bota = true, Pezuna = true,
	Zarpa = true, Mano = true, Guantelete = true, Grebas = true, Cuello = true, Morro = true, Maza = true, Hombros = true,
}

local function tools(x: Ctx)
	local k = x.K
	local S = {}
	-- «lupa»: lo que se monte entre S.head(...) y S.body() crece desde su centro (cabezas grandes del cartel)
	local zoom: Opt? = nil
	function S.head(center: Vector3, scale: number, offset: Vector3?, mirror: boolean?)
		-- (las cabezas, a su tamaño: nada de cabezones; la lupa queda para las alas)
		if not mirror then
			zoom = nil
			return
		end
		zoom = { C = center, S = scale, O = offset or Vector3.zero, Mirror = mirror }
	end
	function S.body()
		zoom = nil
	end
	function S.B(name: string, size: Vector3, pos: Vector3, color: Color3, o: Opt?): BasePart
		local opt: Opt = o or {}
		if zoom then
			local c, off = zoom.C, zoom.O
			if zoom.Mirror and pos.X < 0 then
				c, off = V3(-c.X, c.Y, c.Z), V3(-off.X, off.Y, off.Z)
			end
			pos = c + off + (pos - c) * zoom.S
			size = size * zoom.S
		end
		local cf = CFrame.new(pos * k) * CFrame.Angles(math.rad(opt.rx or 0), math.rad(opt.ry or 0), math.rad(opt.rz or 0))
		local shape = if opt.ball then Enum.PartType.Ball elseif opt.cyl then Enum.PartType.Cylinder elseif opt.wedge then Enum.PartType.Wedge else nil
		local material = if opt.glow then NEON elseif opt.glass then Enum.Material.Glass else SMOOTH
		local small = math.min(size.X, size.Y, size.Z)
		local bevel = if BEVEL[name] and not shape and not opt.alpha and small >= 0.5 and x.Sp.Body ~= "Masa" then math.min(0.2, small * 0.16) else 0
		local core = if bevel > 0 then size - V3(0, 2 * bevel, 2 * bevel) else size
		local p = x.Limb(x.Model, x.Root, name, core * k, cf, color, material, shape, opt.on)
		if bevel > 0 then
			for _, d in { V3(2 * bevel, 0, 2 * bevel), V3(2 * bevel, 2 * bevel, 0) } do
				local b = x.Limb(x.Model, x.Root, "Bisel", (size - d) * k, cf, color, material, nil, p)
				if opt.glow then
					b.CastShadow = false
				end
			end
		end
		if opt.glow then
			p.CastShadow = false
		end
		if opt.alpha then
			p.Transparency = opt.alpha
		end
		return p
	end
	-- las dos mitades (derecha e izquierda): ry y rz se reflejan; «on» puede ser { [1] = derecha, [-1] = izquierda }
	function S.M(name: string, size: Vector3, pos: Vector3, color: Color3, o: Opt?): { [number]: BasePart }
		local out = {}
		for _, s in { 1, -1 } do
			local opt: Opt = table.clone(o or {})
			opt.ry = (opt.ry or 0) * s
			opt.rz = (opt.rz or 0) * s
			if type(opt.on) == "table" then
				opt.on = opt.on[s]
			end
			out[s] = S.B(name, size, V3(pos.X * s, pos.Y, pos.Z), color, opt)
		end
		return out
	end
	-- ojos en la cara (z = el plano de delante): bloque, brillo blanco y ceja enfadada
	function S.eyes(ex: number, ey: number, z: number, w: number, h: number, color: Color3, o: Opt?)
		local opt: Opt = o or {}
		h = h * 0.65 -- (rasgados: mirada de depredador, no de peluche)
		S.M("Cuenca", V3(w * 1.25, h * 1.9, 0.05), V3(ex, ey - h * 0.1, z - 0.01), rgb(14, 12, 12))
		S.M("Ojo", V3(w, h, 0.08), V3(ex, ey, z - 0.03), color, { glow = opt.glow, rz = -8 })
		if opt.pupil then
			S.M("Pupila", V3(w * 0.18, h * 0.95, 0.06), V3(ex, ey, z - 0.08), opt.pupil)
		end
		if opt.brow then
			S.M("Ceja", V3(w * 1.7, math.max(0.12, h * 0.75), 0.16), V3(ex - w * 0.05, ey + h * 0.75, z - 0.07), opt.brow, { rz = opt.browAngle or 26 })
		end
	end
	function S.light(color: Color3, range: number)
		local l = Instance.new("PointLight")
		l.Color = color
		l.Range = range * k
		l.Brightness = 1.4
		l.Shadows = false
		l.Parent = x.Root
	end
	function S.sparks(part: BasePart, color: Color3, rate: number)
		local e = Instance.new("ParticleEmitter")
		e.Name = "Chispas"
		e.Color = ColorSequence.new(color)
		e.LightEmission = 0.9
		e.Size = NumberSequence.new(0.35 * k, 0)
		e.Lifetime = NumberRange.new(0.5, 1)
		e.Rate = rate
		e.Speed = NumberRange.new(1, 3)
		e.SpreadAngle = Vector2.new(60, 60)
		e.Acceleration = Vector3.new(0, 4, 0)
		e.Parent = part
	end
	return S
end
type Tools = typeof(tools(({} :: any) :: Ctx))

---------------------------------------------------------------------
-- Plantillas
---------------------------------------------------------------------

-- Lobo (salvaje gris o ártico blanco)
local function wolf(S: Tools, c: Opt)
	local body, dark, light = c.Body, c.Dark, c.Light
	S.B("Tronco", V3(1.8, 1.5, 3.0), V3(0, 0, 0), body)
	S.B("Lomo", V3(1.5, 0.35, 2.4), V3(0, 0.8, 0.2), dark)
	S.B("Pecho", V3(1.5, 1.3, 0.7), V3(0, -0.05, -1.45), light)
	S.B("Barriga", V3(1.4, 0.3, 2.2), V3(0, -0.72, 0.1), light)
	S.B("Cuello", V3(1.7, 1.4, 1.0), V3(0, 0.45, -1.3), body)
	S.B("Melena", V3(1.5, 0.4, 1.0), V3(0, 1.2, -1.2), dark, { rx = -10 })
	S.head(V3(0, 0.95, -2.1), 1.3, V3(0, 0.3, -0.25))
	S.B("Cabeza", V3(1.6, 1.4, 1.4), V3(0, 0.95, -2.1), body)
	S.B("Frente", V3(0.7, 0.3, 0.3), V3(0, 1.55, -2.7), dark)
	S.B("Hocico", V3(0.9, 0.35, 0.8), V3(0, 0.8, -3.15), body)
	S.B("Mandibula", V3(0.85, 0.32, 0.75), V3(0, 0.46, -3.12), light)
	S.B("Nariz", V3(0.38, 0.28, 0.2), V3(0, 0.9, -3.6), BLACK)
	S.B("Boca", V3(0.7, 0.1, 0.05), V3(0, 0.63, -3.52), BLACK)
	S.M("Colmillo", V3(0.1, 0.26, 0.1), V3(0.27, 0.5, -3.5), IVORY)
	S.M("Diente", V3(0.08, 0.14, 0.08), V3(0.12, 0.55, -3.52), IVORY)
	S.M("Encia", V3(0.3, 0.12, 0.05), V3(0.22, 0.7, -3.52), rgb(120, 40, 40))
	if c.Scar then
		S.B("Cicatriz", V3(0.07, 0.75, 0.05), V3(-0.4, 1.15, -2.84), rgb(160, 110, 110), { rz = -25 })
	end
	S.M("Mejilla", V3(0.3, 0.55, 0.7), V3(0.85, 0.6, -2.0), light, { wedge = true, ry = 180, rz = -10 })
	S.eyes(0.4, 1.12, -2.8, 0.32, 0.26, c.Eye, { glow = true, brow = dark })
	S.M("Oreja", V3(0.32, 0.8, 0.55), V3(0.5, 2.0, -1.95), body, { wedge = true, ry = 90 })
	S.M("OrejaDentro", V3(0.06, 0.5, 0.3), V3(0.55, 1.88, -2.13), light, { wedge = true, ry = 90 })
	S.B("Cana", V3(0.9, 0.35, 0.65), V3(0, 1.15, -2.95), body, { wedge = true })
	S.body()
	for _, z in { -1.05, 1.05 } do
		local legs = S.M("Pata", V3(0.62, 1.9, 0.62), V3(0.55, -1.6, z), body)
		S.M("Zarpa", V3(0.7, 0.3, 0.85), V3(0.55, -2.4, z - 0.08), dark, { on = legs })
		S.M("Garra", V3(0.08, 0.12, 0.2), V3(0.42, -2.47, z - 0.6), IVORY, { on = legs })
		S.M("Garra", V3(0.08, 0.12, 0.2), V3(0.68, -2.47, z - 0.6), IVORY, { on = legs })
		S.M("Pelo", V3(0.78, 0.4, 0.78), V3(0.55, -0.85, z), dark, { on = legs })
	end
	-- pelo: gorguera blanca a los lados del pecho, mechones en el lomo
	S.M("Gorguera", V3(0.45, 1.1, 0.9), V3(0.9, 0.15, -1.45), light, { rz = 10 })
	S.B("Gorguera", V3(1.2, 0.5, 0.5), V3(0, -0.75, -1.65), light)
	for i = 0, 2 do
		S.B("Mechon", V3(0.9 - i * 0.15, 0.3, 0.45), V3(0, 1.05 - i * 0.05, -0.5 + i * 0.7), dark, { rx = -20 })
	end
	S.M("Costado", V3(0.15, 0.7, 2.0), V3(0.95, 0.2, 0.3), dark)
	local tail = S.B("Cola", V3(0.75, 0.75, 1.6), V3(0, 0.86, 2.15), body, { rx = -35 })
	S.B("Cola2", V3(0.6, 0.6, 0.9), V3(0, 1.25, 2.7), dark, { rx = -45, on = tail })
	S.B("PuntaCola", V3(0.55, 0.55, 0.55), V3(0, 1.55, 3.0), light, { rx = -35, on = tail })
	if c.Frost then
		for i = -1, 1 do
			S.B("Escarcha", V3(0.3, 0.6, 0.3), V3(0.15 * i, 1.15, 0.6 * i + 0.3), rgb(190, 235, 255), { glass = true, rz = 15 * i, alpha = 0.15 })
		end
	end
end

-- Persona (o criatura de pie): tronco = raíz, devuelve brazos y piernas para colgarles cosas
local function biped(S: Tools, b: Opt): ({ [number]: BasePart }, { [number]: BasePart })
	local T, A, L = b.T, b.A, b.L
	local legX = b.LegX or (T.X / 2 - L.X / 2 - 0.05)
	local legs = S.M("Pierna", L, V3(legX, -T.Y / 2 - L.Y / 2 + 0.1, 0), b.Legs)
	local arms
	if b.ArmsForward then
		local sy = T.Y / 2 - A.X / 2
		arms = S.M("Brazo", A, V3(T.X / 2 + A.X / 2, sy - A.Y / 2 * math.cos(math.rad(80)), -A.Y / 2 * math.sin(math.rad(80))), b.Arms, { rx = 80 })
	else
		arms = S.M("Brazo", A, V3(T.X / 2 + A.X / 2 + 0.02, T.Y / 2 - A.Y / 2 - (b.ArmDrop or 0), 0), b.Arms)
	end
	return arms, legs
end

-- Punto de la mano (al final del brazo colgando)
local function hand(T: Vector3, A: Vector3, side: number, drop: number?): Vector3
	return V3(side * (T.X / 2 + A.X / 2 + 0.02), T.Y / 2 - A.Y - (drop or 0) + 0.25, 0)
end

-- Espada en la mano derecha, de pie delante del brazo (al alzar el brazo, apunta al enemigo)
local function sword(S: Tools, arm: BasePart, h: Vector3, blade: Color3, len: number, glowEdge: Color3?)
	local g = h + V3(0, 0, -0.55)
	S.B("Empunadura", V3(0.2, 0.7, 0.2), g, rgb(60, 40, 28), { on = arm })
	S.B("Pomo", V3(0.26, 0.2, 0.26), g + V3(0, -0.42, 0), rgb(150, 125, 60), { on = arm })
	S.B("Guarda", V3(0.18, 0.16, 0.8), g + V3(0, 0.4, 0), rgb(150, 125, 60), { on = arm })
	S.B("Hoja", V3(0.1, len, 0.34), g + V3(0, 0.48 + len / 2, 0), blade, { on = arm })
	S.B("Punta", V3(0.09, 0.3, 0.2), g + V3(0, 0.6 + len, 0), blade, { on = arm })
	if glowEdge then
		S.B("Filo", V3(0.12, len * 0.95, 0.08), g + V3(0, 0.48 + len / 2, -0.17), glowEdge, { on = arm, glow = true })
	end
end

-- Túnica con capucha (nigromante, cultista, mago oscuro)
local function robed(S: Tools, c: Opt)
	local T, A, L = V3(1.8, 2.0, 1.1), V3(0.75, 1.9, 0.75), V3(0.8, 1.9, 0.8)
	local arms, legs = biped(S, { T = T, A = A, L = L, Legs = c.Dark, Arms = c.Robe })
	S.B("Tronco", T, V3(0, 0, 0), c.Robe)
	S.B("Falda", V3(1.95, 1.55, 1.2), V3(0, -1.7, 0), c.Robe)
	S.B("FaldaBajo", V3(2.05, 0.3, 1.3), V3(0, -2.35, 0), c.Trim)
	S.B("Franja", V3(0.32, 3.5, 0.06), V3(0, -0.9, -0.62), c.Trim)
	S.B("Cinturon", V3(1.85, 0.25, 1.15), V3(0, -0.75, 0), c.Belt)
	S.B("Hebilla", V3(0.35, 0.3, 0.06), V3(0, -0.75, -0.6), rgb(210, 180, 90))
	S.B("Capa", V3(2.15, 0.5, 1.3), V3(0, 0.85, 0.02), c.Dark)
	S.B("CapaAtras", V3(2.0, 3.6, 0.15), V3(0, -0.8, 0.62), c.Dark)
	-- capucha con la cara en sombra y los ojos que brillan
	S.head(V3(0, 1.85, 0.1), 1.2, V3(0, 0.18, 0))
	S.B("Cabeza", V3(1.8, 1.8, 1.7), V3(0, 1.85, 0.1), c.Robe)
	S.B("Pico", V3(0.7, 0.55, 0.7), V3(0, 2.75, 0.45), c.Robe, { rx = 25 })
	S.B("Sombra", V3(1.25, 1.2, 0.06), V3(0, 1.75, -0.76), rgb(10, 10, 14))
	S.M("Borde", V3(0.2, 1.5, 0.1), V3(0.72, 1.75, -0.78), c.Trim)
	S.B("BordeArriba", V3(1.6, 0.2, 0.1), V3(0, 2.5, -0.78), c.Trim)
	S.eyes(0.3, 1.88, -0.8, 0.26, 0.13, c.Eye, { glow = true, glint = false })
	if c.Skin then
		S.B("Barbilla", V3(0.7, 0.3, 0.06), V3(0, 1.3, -0.8), c.Skin)
	end
	if c.Beard then
		S.B("Barba", V3(1.0, 1.1, 0.25), V3(0, 1.1, -0.86), c.Beard)
		S.B("PuntaBarba", V3(0.6, 0.6, 0.2), V3(0, 0.4, -0.84), c.Beard)
		S.B("Bigote", V3(0.9, 0.18, 0.12), V3(0, 1.6, -0.9), c.Beard)
	end
	S.body()
	-- mangas anchas y manos
	S.M("Manga", V3(0.95, 0.5, 0.95), V3(1.29, -0.7, 0), c.Trim, { on = arms })
	S.M("Mano", V3(0.55, 0.35, 0.55), V3(1.29, -1.1, 0), c.Hand, { on = arms })
	S.M("Bota", V3(0.85, 0.35, 0.95), V3(0.45, -2.75, -0.05), BLACK, { on = legs })
	-- izquierda: orbe; derecha: bastón
	if c.Orb then
		local orb = S.B("Orbe", V3(0.8, 0.8, 0.8), V3(-1.29, -1.35, -0.45), c.Orb, { ball = true, glow = true, on = arms[-1] })
		S.sparks(orb, c.Orb, 8)
		S.light(c.Orb, 12)
	end
	local h = V3(1.29, -1.05, -0.3)
	S.B("Baston", V3(0.18, 4.2, 0.18), h + V3(0, 0.6, 0), WOOD, { on = arms[1] })
	if c.Top == "Calavera" then
		S.B("Calavera", V3(0.55, 0.5, 0.5), h + V3(0, 2.85, 0), IVORY, { on = arms[1] })
		for _, dx in { -0.12, 0.12 } do
			S.B("Cuenca", V3(0.13, 0.13, 0.04), h + V3(dx, 2.9, -0.26), c.Orb or c.Eye, { glow = true, on = arms[1] })
		end
	else
		S.B("Garra", V3(0.5, 0.3, 0.5), h + V3(0, 2.7, 0), rgb(50, 45, 55), { on = arms[1] })
		local gem = S.B("Gema", V3(0.4, 0.75, 0.4), h + V3(0, 3.15, 0), c.Gem, { glow = true, rz = 0, on = arms[1] })
		S.sparks(gem, c.Gem, 5)
	end
end

-- Gólem (de arena, de piedra con musgo o de lava)
local function golem(S: Tools, c: Opt)
	local T, A, L = V3(3.0, 2.6, 1.8), V3(1.3, 2.6, 1.3), V3(1.3, 1.6, 1.3)
	local arms, legs = biped(S, { T = T, A = A, L = L, Legs = c.Main, Arms = c.Main, ArmDrop = 0.3, LegX = 0.85 })
	S.B("Tronco", T, V3(0, 0, 0), c.Main)
	S.B("Pecho", V3(2.6, 1.2, 0.3), V3(0, 0.5, -0.95), c.Light)
	S.B("Vientre", V3(2.0, 0.9, 0.25), V3(0, -0.75, -0.92), c.Dark)
	S.B("Espalda", V3(2.6, 1.8, 0.4), V3(0, 0.3, 1.0), c.Dark)
	S.B("Cabeza", V3(1.6, 1.4, 1.5), V3(0, 1.7, -0.35), c.Main)
	S.B("Frente", V3(1.7, 0.35, 0.3), V3(0, 2.15, -1.05), c.Dark)
	S.B("Mandibula", V3(1.3, 0.4, 0.3), V3(0, 1.15, -1.05), c.Dark)
	S.B("Boca", V3(0.8, 0.12, 0.05), V3(0, 1.38, -1.12), BLACK)
	S.eyes(0.38, 1.82, -1.1, 0.34, 0.22, c.Glow, { glow = true, glint = false, brow = c.Dark, browAngle = 15 })
	S.M("Hombro", V3(1.6, 0.9, 1.6), V3(2.15, 1.05, 0), c.Dark, { on = arms })
	S.M("RocaHombro", V3(0.8, 0.6, 0.8), V3(2.3, 1.65, 0.2), c.Light, { on = arms, rz = -15 })
	S.M("Puno", V3(1.7, 1.3, 1.7), V3(2.17, -1.9, -0.05), c.Dark, { on = arms })
	S.M("Nudillos", V3(1.5, 0.35, 0.25), V3(2.17, -1.7, -0.95), c.Light, { on = arms })
	S.M("Pie", V3(1.5, 0.5, 1.8), V3(0.85, -2.85, -0.15), c.Dark, { on = legs })
	if c.Moss then
		S.M("Musgo", V3(1.5, 0.25, 1.4), V3(2.15, 1.55, 0.05), c.Moss, { on = arms })
		S.B("MusgoCabeza", V3(1.4, 0.25, 1.2), V3(0, 2.45, -0.3), c.Moss)
		S.B("MusgoPecho", V3(0.9, 0.5, 0.1), V3(-0.7, 0.9, -1.12), c.Moss)
		S.B("MusgoEspalda", V3(1.8, 0.4, 0.2), V3(0.2, 1.1, 1.25), c.Moss)
	end
	if c.Cracks then
		S.B("Grieta", V3(0.15, 1.8, 0.06), V3(0.4, 0.1, -1.12), c.Glow, { glow = true, rz = 20 })
		S.B("Grieta", V3(0.15, 1.2, 0.06), V3(-0.6, -0.2, -1.12), c.Glow, { glow = true, rz = -30 })
		S.B("Grieta", V3(0.7, 0.15, 0.06), V3(0.75, -0.5, -1.12), c.Glow, { glow = true, rz = -25 })
		S.M("GrietaBrazo", V3(0.06, 1.6, 0.15), V3(2.84, -0.3, 0), c.Glow, { glow = true, on = arms, rx = 15 })
		S.M("GrietaPierna", V3(0.15, 1.0, 0.06), V3(0.85, -2.0, -0.67), c.Glow, { glow = true, on = legs, rz = 15 })
		S.M("GrietaPuno", V3(0.15, 0.15, 1.75), V3(2.17, -2.2, -0.05), c.Glow, { glow = true, on = arms })
		S.light(c.Glow, 14)
	end
	if c.MouthGlow then
		S.B("Fauces", V3(0.9, 0.28, 0.06), V3(0, 1.38, -1.14), c.Glow, { glow = true })
	end
	if c.Wood then
		S.M("Corteza", V3(0.22, 2.3, 0.1), V3(0.85, -0.1, -0.93), c.Dark, { rz = 4 })
		S.M("Corteza", V3(0.18, 1.8, 0.1), V3(0.35, -0.3, -0.98), c.Dark, { rz = -6 })
		S.M("Rama", V3(0.32, 1.7, 0.32), V3(2.35, 2.25, 0.2), c.Dark, { rz = -25, on = arms })
		S.M("Hojas", V3(1.3, 0.8, 1.3), V3(2.8, 3.1, 0.2), c.Leaf, { on = arms })
		S.M("Hojas", V3(0.8, 0.6, 0.8), V3(2.4, 2.55, -0.45), c.Leaf, { on = arms })
		S.M("RamaCabeza", V3(0.26, 1.5, 0.26), V3(0.5, 2.95, -0.25), c.Dark, { rz = -22 })
		S.M("HojasCabeza", V3(1.0, 0.7, 1.0), V3(0.85, 3.7, -0.25), c.Leaf)
		S.B("HojasCentro", V3(1.4, 0.8, 1.2), V3(0, 3.0, -0.1), c.Leaf)
		S.M("Raiz", V3(0.32, 0.32, 1.0), V3(0.85, -3.0, -1.1), c.Dark, { rx = 20, on = legs })
		S.M("Raiz", V3(0.3, 0.3, 0.8), V3(1.35, -1.9, -0.9), c.Dark, { rx = 30, on = arms })
		for i = 0, 2 do
			S.B("Hongo", V3(0.4, 0.15, 0.4), V3(-1.0 + i * 0.25, -0.4 + i * 0.5, -0.98), c.Glow, { glow = true })
		end
	end
	if c.Ice then
		local ice = rgb(200, 238, 255)
		S.M("Cristal", V3(0.5, 1.3, 0.5), V3(2.2, 2.05, 0.1), ice, { glass = true, alpha = 0.15, rz = -20, on = arms })
		S.M("Cristal", V3(0.35, 0.9, 0.35), V3(2.55, 1.85, -0.35), ice, { glass = true, alpha = 0.15, rz = -40, on = arms })
		S.B("Cristal", V3(0.6, 1.5, 0.6), V3(0.5, 1.6, 1.15), ice, { glass = true, alpha = 0.15, rz = 15 })
		S.B("Cristal", V3(0.5, 1.2, 0.5), V3(-0.6, 1.45, 1.05), ice, { glass = true, alpha = 0.15, rz = -20 })
		S.B("Cristal", V3(0.4, 0.9, 0.4), V3(0, 2.75, -0.2), ice, { glass = true, alpha = 0.15 })
		S.B("Grieta", V3(0.12, 1.4, 0.06), V3(0.3, 0.2, -1.12), c.Glow, { glow = true, rz = 15 })
		S.light(c.Glow, 10)
	end
	if c.Horns then
		S.M("Cuerno", V3(0.42, 1.0, 0.42), V3(0.8, 2.6, -0.35), c.Horns, { rz = -32 })
		S.M("Cuerno2", V3(0.3, 0.75, 0.3), V3(1.12, 3.3, -0.35), c.Horns, { rz = -10 })
		S.M("PuntaCuerno", V3(0.2, 0.45, 0.2), V3(1.1, 3.8, -0.35), c.Glow, { glow = true, rz = 15 })
	end
	if c.Flames then
		for _, p in { V3(2.1, 1.75, 0), V3(2.4, 2.1, 0.3), V3(1.9, 2.0, -0.3) } do
			S.M("Llama", V3(0.45, 0.9, 0.45), p, if p.Z == 0 then c.Glow else rgb(255, 220, 90), { glow = true, on = arms, rz = -10 })
		end
		local top = S.B("Llama", V3(0.6, 1.0, 0.6), V3(0, 2.75, -0.3), c.Glow, { glow = true })
		S.sparks(top, c.Glow, 14)
	end
	if c.Crown then
		S.B("Tocado", V3(1.8, 0.3, 1.6), V3(0, 2.5, -0.35), c.Crown)
		S.M("TocadoLado", V3(0.25, 1.2, 1.2), V3(0.9, 1.8, -0.2), c.Crown)
		S.B("Joya", V3(0.35, 0.35, 0.08), V3(0, 2.15, -1.22), c.Glow, { glow = true })
		S.B("Emblema", V3(0.6, 0.6, 0.08), V3(0, 0.55, -1.13), c.Glow, { glow = true, rz = 45 })
	end
end

-- Demonio (menor, de fuego o supremo)
local function demon(S: Tools, c: Opt)
	local skin, dark, horn = c.Skin, c.Dark, c.Horn
	local T, A = V3(2.6, 2.4, 1.4), V3(1.15, 2.4, 1.15)
	local arms, legs = biped(S, { T = T, A = A, L = V3(1.15, 2.0, 1.15), Legs = dark, Arms = skin })
	S.B("Tronco", T, V3(0, 0, 0), skin)
	S.M("Pectoral", V3(1.05, 0.7, 0.1), V3(0.6, 0.55, -0.72), c.Pec)
	S.B("Abdomen", V3(0.95, 1.0, 0.08), V3(0, -0.35, -0.71), c.Abs)
	S.B("Cinturon", V3(2.65, 0.38, 1.45), V3(0, -1.05, 0), BLACK)
	S.B("Hebilla", V3(0.45, 0.35, 0.06), V3(0, -1.05, -0.74), rgb(210, 175, 70))
	S.B("Taparrabos", V3(1.2, 1.0, 0.1), V3(0, -1.65, -0.74), rgb(30, 24, 26))
	S.head(V3(0, 2.05, -0.05), 1.15, V3(0, 0.15, 0))
	S.B("Cabeza", V3(1.8, 1.7, 1.6), V3(0, 2.05, -0.05), skin)
	S.B("Frente", V3(1.6, 0.3, 0.2), V3(0, 2.55, -0.9), dark)
	S.eyes(0.45, 2.25, -0.85, 0.3, 0.2, rgb(255, 220, 60), { glow = true, glint = false, brow = dark, browAngle = 24 })
	S.B("Nariz", V3(0.3, 0.3, 0.15), V3(0, 1.95, -0.92), dark)
	S.B("Boca", V3(1.0, 0.3, 0.06), V3(0, 1.55, -0.86), rgb(50, 10, 12))
	S.M("Colmillo", V3(0.14, 0.28, 0.08), V3(0.32, 1.52, -0.9), WHITE)
	S.M("Colmillo", V3(0.12, 0.22, 0.08), V3(0.14, 1.62, -0.9), WHITE)
	S.M("Oreja", V3(0.2, 0.5, 0.4), V3(0.98, 2.15, 0), skin, { rz = -30 })
	S.M("Cuerno", V3(0.5, 0.48, 0.48), V3(0.85, 2.95, -0.1), horn, { rz = -35 })
	S.M("Cuerno2", V3(0.4, 0.8, 0.4), V3(1.15, 3.45, -0.05), horn, { rz = -15 })
	S.M("Cuerno3", V3(0.28, 0.65, 0.28), V3(1.08, 4.0, 0.05), horn, { rz = 22 })
	S.body()
	S.M("Mano", V3(1.18, 0.5, 1.18), V3(1.89, -1.0, 0), dark, { on = arms })
	S.M("Garra", V3(0.15, 0.3, 0.15), V3(1.89, -1.35, -0.45), BLACK, { on = arms })
	S.M("Pezuna", V3(1.25, 0.5, 1.25), V3(0.71, -3.0, -0.05), BLACK, { on = legs })
	local tail = S.B("Cola", V3(0.3, 0.3, 1.8), V3(0, -0.95, 1.45), dark, { rx = 30 })
	S.B("PuntaCola", V3(0.55, 0.12, 0.55), V3(0, -1.45, 2.3), BLACK, { ry = 45, on = tail })
	if c.Armor then
		S.M("Hombrera", V3(1.5, 0.7, 1.5), V3(1.89, 1.15, 0), c.Armor, { on = arms })
		S.M("PuaHombro", V3(0.25, 0.8, 0.25), V3(2.05, 1.85, -0.3), c.Armor, { rz = -30, on = arms })
		S.M("PuaHombro", V3(0.22, 0.65, 0.22), V3(2.3, 1.7, 0.35), c.Armor, { rz = -50, on = arms })
		S.B("Peto", V3(2.2, 0.9, 0.18), V3(0, 0.6, -0.78), c.Armor)
		S.B("Runa", V3(0.3, 0.5, 0.06), V3(0, 0.6, -0.89), c.Glow, { glow = true, rz = 45 })
		S.M("Grebas", V3(1.25, 1.0, 1.25), V3(0.71, -2.3, -0.03), c.Armor, { on = legs })
	end
	if c.Wings then
		local wings = S.M("Ala", V3(3.4, 0.12, 2.2), V3(2.6, 1.7, 0.95), c.Wing, { rz = 22 })
		S.M("HuesoAla", V3(3.5, 0.26, 0.26), V3(2.6, 1.75, -0.12), dark, { rz = 22, on = wings })
		S.M("Dedo", V3(0.14, 0.13, 2.0), V3(2.1, 1.55, 0.95), dark, { rz = 22, ry = 10, on = wings })
		S.M("Dedo", V3(0.14, 0.13, 2.0), V3(3.3, 2.05, 0.95), dark, { rz = 22, ry = -10, on = wings })
		S.M("GarraAla", V3(0.2, 0.4, 0.2), V3(4.25, 2.45, -0.15), horn, { on = wings })
	end
	if c.Fire then
		S.B("Grieta", V3(0.14, 1.4, 0.06), V3(0.35, 0.1, -0.75), c.Glow, { glow = true, rz = 18 })
		S.B("Grieta", V3(0.14, 1.0, 0.06), V3(-0.45, -0.2, -0.75), c.Glow, { glow = true, rz = -22 })
		S.M("ManoFuego", V3(0.7, 0.7, 0.7), V3(1.89, -1.5, 0), c.Glow, { glow = true, on = arms })
		for i, p in { V3(0, 3.1, -0.1), V3(0.45, 2.95, 0.1), V3(-0.45, 2.95, 0.1) } do
			S.B("Llama", V3(0.42, 0.8, 0.42), p, if i == 1 then rgb(255, 220, 90) else c.Glow, { glow = true })
		end
		local core = S.B("Brasa", V3(0.2, 0.2, 0.2), V3(0, 3.5, 0), c.Glow, { glow = true })
		S.sparks(core, c.Glow, 16)
		S.light(c.Glow, 14)
	end
end

-- Dragón a cuatro patas (de hielo o infernal)
local function dragon(S: Tools, c: Opt)
	local body, belly, spike, dark = c.Body, c.Belly, c.Spike, c.Dark
	S.B("Tronco", V3(2.0, 1.8, 3.4), V3(0, 0, 0), body)
	S.B("Barriga", V3(1.7, 0.35, 3.0), V3(0, -0.8, 0), belly)
	S.B("Pecho", V3(1.8, 1.6, 0.8), V3(0, 0.2, -1.6), belly)
	S.B("Cuello", V3(1.0, 1.7, 1.0), V3(0, 1.35, -2.05), body, { rx = -30 })
	S.B("CuelloDelante", V3(0.7, 1.6, 0.2), V3(0, 1.2, -2.5), belly, { rx = -30 })
	S.head(V3(0, 2.3, -3.0), 1.25, V3(0, 0.2, -0.15))
	S.B("Cabeza", V3(1.3, 1.1, 1.5), V3(0, 2.3, -2.75), body)
	S.B("Hocico", V3(0.95, 0.65, 1.1), V3(0, 2.15, -3.75), body)
	S.B("Cana", V3(0.95, 0.4, 0.8), V3(0, 2.68, -3.55), body, { wedge = true })
	S.B("Mandibula", V3(0.85, 0.28, 1.1), V3(0, 1.72, -3.6), belly, { rx = -8 })
	S.B("Boca", V3(0.8, 0.12, 0.9), V3(0, 1.9, -3.65), rgb(120, 20, 20))
	S.M("Diente", V3(0.1, 0.2, 0.1), V3(0.35, 1.78, -4.15), WHITE)
	S.M("Diente", V3(0.1, 0.2, 0.1), V3(0.38, 1.78, -3.75), WHITE)
	S.M("Nariz", V3(0.14, 0.1, 0.06), V3(0.22, 2.4, -4.3), BLACK)
	S.eyes(0.48, 2.5, -3.5, 0.26, 0.2, c.Eye, { glow = true, glint = false, brow = dark, browAngle = 22 })
	S.M("Cuerno", V3(0.28, 0.28, 1.3), V3(0.42, 2.95, -2.15), spike, { rx = -35, ry = -10 })
	S.M("Cuerno", V3(0.2, 0.2, 0.8), V3(0.62, 2.55, -2.1), spike, { rx = -20, ry = -25 })
	S.M("Aleta", V3(0.12, 0.5, 0.5), V3(0.68, 2.2, -2.5), spike, { rz = -30 })
	S.body()
	-- púas por el cuello, el lomo y la cola
	for i = 0, 6 do
		local y = if i < 2 then 2.85 - i * 0.6 else 1.15
		local z = if i < 2 then -2.2 + i * 0.5 else -1.6 + (i - 2) * 0.75
		S.B("Pua", V3(0.22, 0.55, 0.45), V3(0, y, z), spike, { rx = -20, glass = c.Icy, glow = c.GlowSpikes })
	end
	-- alas: membrana (Ala, gira desde el cuerpo), hueso delante y dedos
	S.head(V3(1.0, 1.3, 0), c.WingScale or 1.3, nil, true)
	local wings = S.M("Ala", V3(3.4, 0.12, 2.2), V3(2.7, 1.35, 0.1), c.Wing, { rz = 22, alpha = c.WingAlpha })
	S.M("HuesoAla", V3(3.5, 0.28, 0.28), V3(2.7, 1.38, -1.0), body, { rz = 22, on = wings })
	S.M("Dedo", V3(0.15, 0.14, 2.0), V3(2.2, 1.18, 0.05), body, { rz = 22, ry = 10, on = wings })
	S.M("Dedo", V3(0.15, 0.14, 2.0), V3(3.4, 1.65, 0.05), body, { rz = 22, ry = -10, on = wings })
	S.M("GarraAla", V3(0.2, 0.4, 0.2), V3(4.35, 2.05, -1.05), spike, { on = wings })
	S.body()
	for _, z in { -1.1, 1.1 } do
		local legs = S.M("Pata", V3(0.85, 1.75, 0.85), V3(0.85, -1.65, z), body)
		S.M("Muslo", V3(1.0, 0.9, 1.2), V3(0.95, -0.8, z), body, { on = legs })
		S.M("Pie", V3(1.0, 0.3, 1.15), V3(0.85, -2.4, z - 0.15), dark, { on = legs })
		S.M("Una", V3(0.16, 0.2, 0.3), V3(0.6, -2.42, z - 0.8), WHITE, { on = legs })
		S.M("Una", V3(0.16, 0.2, 0.3), V3(1.1, -2.42, z - 0.8), WHITE, { on = legs })
	end
	local tail = S.B("Cola", V3(0.95, 0.85, 2.0), V3(0, 0.15, 2.6), body)
	S.B("Cola2", V3(0.7, 0.62, 1.8), V3(0, 0.05, 4.4), body, { on = tail })
	S.B("Cola3", V3(0.45, 0.42, 1.6), V3(0, -0.05, 6.0), body, { on = tail })
	S.B("PuntaCola", V3(0.95, 0.14, 0.95), V3(0, -0.05, 7.05), spike, { ry = 45, on = tail })
	for i = 0, 2 do
		S.B("PuaCola", V3(0.18, 0.4, 0.4), V3(0, 0.7 - i * 0.12, 2.6 + i * 1.6), spike, { rx = -25, on = tail })
	end
	if c.Cracks then
		for i = -1, 1 do
			S.B("Brasa", V3(1.2, 0.08, 0.15), V3(0, -0.98, i * 0.9), c.Eye, { glow = true })
		end
		S.B("BrasaPecho", V3(0.15, 1.2, 0.06), V3(0.3, 0.2, -2.02), c.Eye, { glow = true, rz = 15 })
		S.light(c.Eye, 14)
	end
	if c.Icy then
		for i = -1, 1 do
			S.B("Cristal", V3(0.35, 0.8, 0.35), V3(0.5 * i, 1.2, 0.4 + i * 0.3), rgb(200, 240, 255), { glass = true, rz = 25 * i, alpha = 0.2 })
		end
	end
end

---------------------------------------------------------------------
-- Las 24 recetas
---------------------------------------------------------------------
type Recipe = { Root: Vector3, Hip: number, Build: (Tools) -> () }
local R: { [string]: Recipe } = {}

-- BOSQUE ETÉREO ------------------------------------------------------
R.LoboBosque = {
	Root = V3(1.8, 1.5, 3.0),
	Hip = 1.8,
	Build = function(S)
		wolf(S, { Body = rgb(100, 102, 108), Dark = rgb(58, 60, 66), Light = rgb(190, 190, 186), Eye = rgb(255, 190, 60), Scar = true })
	end,
}

R.OsoGigante = {
	Root = V3(2.8, 2.4, 3.8),
	Hip = 1.3,
	Build = function(S)
		local body, dark, tan = rgb(112, 68, 40), rgb(72, 42, 24), rgb(196, 152, 108)
		S.B("Tronco", V3(2.8, 2.4, 3.8), V3(0, 0, 0), body)
		S.B("Joroba", V3(2.5, 0.7, 1.9), V3(0, 1.4, -0.8), body)
		S.B("Lomo", V3(2.2, 0.3, 2.6), V3(0, 1.25, 0.6), dark)
		S.B("Barriga", V3(2.3, 0.4, 3.0), V3(0, -1.1, 0), rgb(140, 92, 58))
		S.M("Pelo", V3(0.4, 0.7, 0.9), V3(1.45, 0.5, -1.0), dark)
		S.M("Pelo", V3(0.4, 0.6, 0.8), V3(1.45, 0.2, 1.1), dark)
		S.head(V3(0, 1.2, -2.5), 1.15, V3(0, 0.25, -0.2))
		S.B("Cabeza", V3(2.2, 2.0, 1.8), V3(0, 1.2, -2.5), body)
		S.B("Frente", V3(1.4, 0.4, 0.3), V3(0, 2.0, -3.35), dark)
		S.B("Hocico", V3(1.2, 0.85, 0.8), V3(0, 0.85, -3.75), tan)
		S.B("Nariz", V3(0.6, 0.35, 0.25), V3(0, 1.17, -4.18), BLACK)
		S.B("Boca", V3(0.9, 0.38, 0.06), V3(0, 0.62, -4.16), rgb(110, 25, 25))
		S.M("Diente", V3(0.14, 0.2, 0.08), V3(0.3, 0.74, -4.2), WHITE)
		S.M("Diente", V3(0.14, 0.18, 0.08), V3(0.3, 0.5, -4.2), WHITE)
		S.M("Mejilla", V3(0.4, 0.9, 1.0), V3(1.15, 0.9, -2.5), dark)
		S.M("Oreja", V3(0.75, 0.75, 0.75), V3(0.85, 2.25, -2.35), body, { ball = true })
		S.M("OrejaDentro", V3(0.42, 0.42, 0.42), V3(0.85, 2.25, -2.62), tan, { ball = true })
		S.eyes(0.5, 1.55, -3.4, 0.3, 0.28, rgb(200, 120, 40), { glow = true, brow = dark })
		S.body()
		for _, z in { -1.3, 1.3 } do
			local legs = S.M("Pata", V3(1.0, 1.4, 1.0), V3(0.9, -1.8, z), body)
			S.M("Zarpa", V3(1.1, 0.35, 1.2), V3(0.9, -2.33, z - 0.05), dark, { on = legs })
			for j = -1, 1 do
				S.M("Una", V3(0.14, 0.14, 0.3), V3(0.9 + j * 0.33, -2.4, z - 0.72), IVORY, { on = legs })
			end
		end
		S.B("Rabo", V3(0.6, 0.6, 0.6), V3(0, 0.6, 1.95), body, { ball = true })
	end,
}

R.AranaBosque = {
	Root = V3(1.6, 1.0, 1.6),
	Hip = 1.0,
	Build = function(S)
		local body, dark, red = rgb(52, 36, 30), rgb(30, 22, 20), rgb(150, 40, 30)
		S.B("Torax", V3(1.7, 1.1, 1.7), V3(0, 0.05, 0), body)
		S.B("Pelo", V3(1.3, 0.25, 1.4), V3(0, 0.65, 0), dark)
		S.B("Cabeza", V3(1.35, 1.0, 0.9), V3(0, 0.15, -1.2), body)
		S.B("Abdomen", V3(2.9, 2.6, 3.0), V3(0, 0.75, 2.1), body, { ball = true })
		S.B("Marca", V3(0.9, 0.15, 1.3), V3(0, 2.05, 2.1), red, { glow = true })
		S.B("Marca", V3(0.5, 0.15, 0.5), V3(0, 1.98, 1.15), red, { glow = true, ry = 45 })
		S.M("Mancha", V3(0.2, 1.0, 1.4), V3(1.42, 0.8, 2.1), dark)
		S.eyes(0.28, 0.4, -1.65, 0.3, 0.3, rgb(255, 40, 30), { glow = true, glint = false })
		S.M("OjoPeq", V3(0.16, 0.16, 0.06), V3(0.12, 0.62, -1.68), rgb(255, 40, 30), { glow = true })
		S.M("OjoPeq", V3(0.16, 0.16, 0.06), V3(0.55, 0.15, -1.66), rgb(255, 40, 30), { glow = true })
		S.M("Quelicero", V3(0.28, 0.6, 0.3), V3(0.25, -0.35, -1.65), dark, { rx = 15 })
		S.M("Colmillo", V3(0.14, 0.3, 0.14), V3(0.25, -0.75, -1.75), red, { rx = 25 })
		-- patas en arco: suben hasta la rodilla (por encima del cuerpo) y bajan abiertas hasta el suelo
		local ground = -1.5
		for i, z in { -0.6, -0.2, 0.2, 0.6 } do
			local psi = (2.5 - i) * 22 -- (las de delante apuntan delante; las de detrás, atrás)
			local dir = V3(math.cos(math.rad(psi)), 0, -math.sin(math.rad(psi)))
			local base = V3(0.7, 0.35, z)
			local L1, a = 1.8, 42
			local up = V3(0, 1, 0)
			local knee = base + dir * (L1 * math.cos(math.rad(a))) + up * (L1 * math.sin(math.rad(a)))
			local legs = S.M("Pata", V3(L1, 0.32, 0.32), base + dir * (L1 / 2 * math.cos(math.rad(a))) + up * (L1 / 2 * math.sin(math.rad(a))), body, { rz = a, ry = psi })
			S.M("Rodilla", V3(0.42, 0.42, 0.42), knee, red, { on = legs })
			local reach, h = 1.1, knee.Y - ground
			local L2 = math.sqrt(reach * reach + h * h)
			local mid = knee + dir * (reach / 2) - up * (h / 2)
			S.M("Tramo", V3(0.28, L2, 0.28), mid, dark, { rz = math.deg(math.atan2(reach, h)), ry = psi, on = legs })
			S.M("PeloPata", V3(0.4, 0.4, 0.4), knee - up * 0.45 + dir * 0.15, body, { on = legs, rz = 20, ry = psi })
		end
		-- pelo en la barriga
		for j = 0, 7 do
			local ang = j / 8 * math.pi * 2
			S.B("PeloBarriga", V3(0.4, 0.4, 0.4), V3(math.cos(ang) * 1.38, 0.75 + math.sin(ang) * 1.2, 2.1 + (if j % 2 == 0 then 0.5 else -0.5)), dark, { rx = 20 * j, ry = 15 * j })
		end
	end,
}

-- LLANURAS SALVAJES --------------------------------------------------
R.JabaliSierra = {
	Root = V3(1.9, 1.6, 2.8),
	Hip = 0.9,
	Build = function(S)
		local body, dark, snout = rgb(100, 62, 42), rgb(58, 36, 26), rgb(176, 122, 100)
		S.B("Tronco", V3(1.9, 1.6, 2.8), V3(0, 0, 0), body)
		S.B("Barriga", V3(1.6, 0.3, 2.2), V3(0, -0.7, 0), rgb(132, 90, 66))
		S.B("Hombros", V3(2.0, 1.4, 1.0), V3(0, 0.25, -1.0), body)
		for i = 0, 5 do
			local h = if i < 3 then 0.6 else 0.45
			S.B("Cresta", V3(0.5, h, 0.42), V3(0, 0.85 + h / 2 - (if i < 3 then 0 else 0.1), -1.3 + i * 0.42), dark, { rx = -15 })
		end
		S.head(V3(0, 0.3, -1.85), 1.25, V3(0, 0.15, -0.2))
		S.B("Cabeza", V3(1.5, 1.4, 1.3), V3(0, 0.3, -1.85), body)
		S.B("Hocico", V3(1.0, 0.75, 0.6), V3(0, 0.0, -2.75), snout)
		S.M("Narina", V3(0.18, 0.22, 0.05), V3(0.22, 0.05, -3.06), BLACK)
		S.B("Boca", V3(0.8, 0.08, 0.05), V3(0, -0.28, -3.06), BLACK)
		S.M("Colmillo", V3(0.18, 0.35, 0.18), V3(0.45, -0.1, -2.8), IVORY)
		S.M("PuntaColmillo", V3(0.14, 0.32, 0.14), V3(0.5, 0.22, -2.95), IVORY, { rx = -30, rz = -10 })
		S.M("Oreja", V3(0.25, 0.6, 0.45), V3(0.6, 1.15, -1.7), dark, { wedge = true, ry = 90 })
		S.B("Cana", V3(1.0, 0.4, 0.6), V3(0, 0.55, -2.5), body, { wedge = true })
		S.eyes(0.4, 0.58, -2.5, 0.22, 0.2, rgb(230, 45, 30), { glow = true, glint = false, brow = dark })
		S.body()
		for _, z in { -0.95, 0.95 } do
			local legs = S.M("Pata", V3(0.52, 1.0, 0.55), V3(0.6, -1.2, z), body)
			S.M("Pezuna", V3(0.58, 0.25, 0.62), V3(0.6, -1.58, z - 0.02), BLACK, { on = legs })
		end
		local tail = S.B("Cola", V3(0.18, 0.18, 0.6), V3(0, 0.45, 1.65), body, { rx = -30 })
		S.B("Mechon", V3(0.3, 0.3, 0.3), V3(0, 0.65, 1.95), dark, { on = tail })
	end,
}

R.SaqueadorNomada = { -- Bandido
	Root = V3(2.0, 2.0, 1.1),
	Hip = 1.9,
	Build = function(S)
		local skin, hair, shirt, vest, pants, boot = rgb(226, 176, 136), rgb(66, 42, 28), rgb(170, 128, 88), rgb(96, 62, 40), rgb(92, 72, 58), rgb(48, 34, 26)
		local T, A = V3(2.0, 2.0, 1.1), V3(0.9, 2.0, 0.9)
		local arms, legs = biped(S, { T = T, A = A, L = V3(0.95, 2.0, 0.95), Legs = pants, Arms = shirt })
		S.B("Tronco", T, V3(0, 0, 0), shirt)
		S.M("Chaleco", V3(0.62, 2.02, 1.14), V3(0.7, 0, 0), vest)
		S.B("ChalecoAtras", V3(2.02, 2.02, 0.1), V3(0, 0, 0.55), vest)
		S.B("Correa", V3(0.3, 2.7, 0.06), V3(0, 0.05, -0.59), boot, { rz = 40 })
		S.B("Cinturon", V3(2.05, 0.3, 1.15), V3(0, -0.85, 0), boot)
		S.B("Hebilla", V3(0.35, 0.25, 0.06), V3(0, -0.85, -0.6), rgb(210, 175, 80))
		S.B("Bolsa", V3(0.4, 0.45, 0.3), V3(-0.75, -1.05, -0.5), vest)
		S.head(V3(0, 1.8, 0), 1.25, V3(0, 0.2, 0))
		S.B("Cabeza", V3(1.6, 1.6, 1.5), V3(0, 1.8, 0), skin)
		S.B("Pelo", V3(1.7, 0.45, 1.6), V3(0, 2.6, 0.05), hair)
		S.B("Nuca", V3(1.7, 1.2, 0.35), V3(0, 2.0, 0.65), hair)
		S.M("Patilla", V3(0.2, 0.75, 1.2), V3(0.82, 2.05, 0.15), hair)
		S.B("Flequillo", V3(0.55, 0.3, 0.15), V3(-0.35, 2.4, -0.76), hair)
		S.B("Flequillo", V3(0.45, 0.25, 0.15), V3(0.3, 2.45, -0.76), hair)
		S.B("Panuelo", V3(1.66, 0.75, 1.56), V3(0, 1.38, 0), rgb(92, 30, 26))
		S.B("Nudo", V3(0.4, 0.35, 0.3), V3(0, 1.5, 0.85), rgb(92, 30, 26))
		S.B("Pico", V3(0.5, 0.5, 0.08), V3(0, 1.05, -0.8), rgb(80, 26, 22), { rz = 45 })
		S.B("Cicatriz", V3(0.06, 0.55, 0.04), V3(0.32, 1.95, -0.77), rgb(170, 100, 90), { rz = 20 })
		S.eyes(0.35, 1.92, -0.75, 0.22, 0.25, rgb(120, 100, 80), { brow = hair, browAngle = 18 })
		S.body()
		S.M("Hombrera", V3(1.0, 0.4, 1.0), V3(1.47, 0.82, 0), vest, { on = arms })
		S.M("Brazal", V3(0.98, 0.45, 0.98), V3(1.47, -0.4, 0), boot, { on = arms })
		S.M("Mano", V3(0.95, 0.45, 0.95), V3(1.47, -0.8, 0), skin, { on = arms })
		S.M("Bota", V3(1.0, 0.85, 1.05), V3(0.48, -2.48, -0.03), boot, { on = legs })
		sword(S, arms[1], hand(T, A, 1), METAL, 2.3)
	end,
}

R.Minotauro = {
	Root = V3(2.6, 2.4, 1.4),
	Hip = 1.9,
	Build = function(S)
		local fur, skin, chest, horn = rgb(86, 56, 40), rgb(124, 86, 62), rgb(168, 126, 96), rgb(236, 222, 188)
		local T, A = V3(2.6, 2.4, 1.4), V3(1.1, 2.3, 1.1)
		local arms, legs = biped(S, { T = T, A = A, L = V3(1.15, 2.0, 1.15), Legs = fur, Arms = skin })
		S.B("Tronco", T, V3(0, 0, 0), skin)
		S.M("Pectoral", V3(1.05, 0.7, 0.1), V3(0.58, 0.5, -0.72), chest)
		S.B("Abdomen", V3(1.0, 0.9, 0.08), V3(0, -0.35, -0.71), chest)
		S.B("Correa", V3(0.35, 3.1, 0.07), V3(0, 0.2, -0.74), rgb(70, 46, 30), { rz = -40 })
		S.B("Cinturon", V3(2.65, 0.38, 1.45), V3(0, -1.05, 0), rgb(60, 40, 28))
		S.B("Hebilla", V3(0.4, 0.3, 0.06), V3(0, -1.05, -0.74), rgb(200, 170, 80))
		S.B("Taparrabos", V3(1.2, 1.1, 0.1), V3(0, -1.65, -0.74), rgb(200, 186, 150))
		S.B("Pelo", V3(1.8, 0.6, 0.6), V3(0, 1.3, 0.55), fur)
		S.head(V3(0, 2.05, -0.1), 1.2, V3(0, 0.2, 0))
		S.B("Cabeza", V3(1.8, 1.7, 1.7), V3(0, 2.05, -0.1), fur)
		S.B("Mechon", V3(0.9, 0.35, 0.9), V3(0, 3.0, -0.1), rgb(60, 38, 26))
		S.B("Hocico", V3(1.3, 0.8, 0.6), V3(0, 1.68, -1.2), rgb(140, 100, 76))
		S.B("Morro", V3(1.1, 0.3, 0.1), V3(0, 1.92, -1.52), rgb(120, 84, 64))
		S.M("Narina", V3(0.24, 0.1, 0.05), V3(0.34, 1.9, -1.58), BLACK)
		S.eyes(0.45, 2.3, -0.95, 0.26, 0.2, rgb(255, 60, 40), { glow = true, glint = false, brow = rgb(50, 32, 22) })
		S.M("Oreja", V3(0.55, 0.25, 0.35), V3(1.1, 2.25, 0.0), fur, { rz = -20 })
		S.M("Cuerno", V3(1.0, 0.44, 0.44), V3(1.3, 2.6, -0.1), horn, { rz = 10 })
		S.M("Cuerno2", V3(0.4, 1.0, 0.4), V3(1.85, 3.15, -0.1), horn, { rz = -10 })
		S.M("Cuerno3", V3(0.3, 0.6, 0.3), V3(1.78, 3.85, -0.1), horn, { rz = 25 })
		S.M("PuntaCuerno", V3(0.2, 0.3, 0.2), V3(1.62, 4.2, -0.1), rgb(90, 80, 70), { rz = 35 })
		S.body()
		S.M("Hombrera", V3(1.35, 0.5, 1.35), V3(1.87, 1.0, 0), rgb(116, 116, 124), { on = arms })
		S.M("Brazal", V3(1.15, 0.5, 1.15), V3(1.87, -0.5, 0), rgb(116, 116, 124), { on = arms })
		S.M("Mano", V3(1.15, 0.5, 1.15), V3(1.87, -0.95, 0), fur, { on = arms })
		S.M("Pezuna", V3(1.25, 0.5, 1.25), V3(0.71, -3.0, -0.05), BLACK, { on = legs })
		local h = hand(T, A, 1)
		local g = h + V3(0, 0, -0.6)
		S.B("Mango", V3(0.22, 3.2, 0.22), g + V3(0, 0.8, 0), WOOD, { on = arms[1] })
		S.B("HojaHacha", V3(0.14, 1.0, 1.0), g + V3(0, 2.0, -0.6), rgb(150, 152, 162), { on = arms[1] })
		S.B("Filo", V3(0.15, 1.2, 0.16), g + V3(0, 2.0, -1.12), rgb(215, 220, 228), { on = arms[1] })
		S.B("Contra", V3(0.14, 0.6, 0.5), g + V3(0, 2.0, 0.35), rgb(120, 122, 132), { on = arms[1] })
	end,
}

-- PANTANO MALDITO ----------------------------------------------------
R.SlimeToxico = {
	Root = V3(2.6, 2.6, 2.6),
	Hip = 0.2,
	Build = function(S)
		local green, core = rgb(88, 176, 52), rgb(40, 110, 30)
		S.B("Cabeza", V3(3.0, 2.8, 3.0), V3(0, -0.1, 0), green, { alpha = 0.22 })
		S.B("Nucleo", V3(2.2, 2.0, 2.2), V3(0, -0.3, 0.1), core, { alpha = 0.1 })
		S.B("Reflejo", V3(0.9, 0.25, 0.06), V3(-0.8, 1.05, -1.53), rgb(220, 255, 200), { alpha = 0.2 })
		S.M("Ojo", V3(0.55, 0.3, 0.06), V3(0.55, 0.35, -1.53), rgb(230, 255, 60), { glow = true, rz = -15 })
		S.M("Ceja", V3(0.75, 0.16, 0.06), V3(0.52, 0.6, -1.54), rgb(20, 50, 16), { rz = 25 })
		S.B("Boca", V3(1.3, 0.45, 0.05), V3(0, -0.45, -1.53), rgb(14, 30, 10))
		for i = -2, 2 do
			S.B("Diente", V3(0.12, 0.2, 0.05), V3(i * 0.26, -0.3 - (i % 2) * 0.28, -1.56), rgb(220, 230, 190))
		end
		S.B("Craneo", V3(0.8, 0.7, 0.7), V3(0.3, -0.4, 0.5), IVORY, { alpha = 0.35 })
		S.B("Hueso", V3(1.2, 0.15, 0.15), V3(-0.4, -0.9, 0.2), IVORY, { alpha = 0.35, rz = 30 })
		for i, p in { V3(0.9, -1.45, -1.2), V3(-1.1, -1.45, 0.6), V3(0.3, -1.45, 1.2), V3(-0.6, 1.35, 0.4) } do
			S.B("Gota", V3(0.45, 0.25, 0.45), p, green, { alpha = 0.2 })
		end
		for _, p in { V3(0.5, -0.6, 0.4), V3(-0.5, 0.1, 0.6), V3(0.2, 0.6, 0.9) } do
			S.B("Burbuja", V3(0.3, 0.3, 0.3), p, rgb(200, 255, 170), { ball = true, alpha = 0.3 })
		end
	end,
}

R.CocodriloMutado = {
	Root = V3(2.2, 1.0, 4.2),
	Hip = 0.7,
	Build = function(S)
		local body, dark, belly = rgb(60, 102, 52), rgb(38, 70, 36), rgb(156, 170, 98)
		S.B("Tronco", V3(2.2, 1.0, 4.2), V3(0, 0, 0), body)
		S.B("Barriga", V3(1.9, 0.25, 3.8), V3(0, -0.45, 0), belly)
		for z = -1.6, 1.61, 0.53 do
			S.B("Escama", V3(0.3, 0.4, 0.35), V3(0, 0.65, z), dark)
			S.M("Escama", V3(0.28, 0.3, 0.33), V3(0.55, 0.6, z + 0.2), dark)
		end
		S.B("Cabeza", V3(1.7, 0.8, 1.3), V3(0, 0.15, -2.7), body)
		S.M("Bulto", V3(0.45, 0.35, 0.45), V3(0.5, 0.7, -2.6), body)
		S.eyes(0.5, 0.72, -2.83, 0.3, 0.22, rgb(255, 220, 60), { glow = true, glint = false, pupil = BLACK })
		S.B("Morro", V3(1.3, 0.42, 2.0), V3(0, 0.32, -4.25), body, { rx = 10 })
		S.B("MandibulaBaja", V3(1.2, 0.3, 1.9), V3(0, -0.22, -4.2), belly, { rx = -10 })
		S.B("Boca", V3(1.1, 0.1, 1.7), V3(0, 0.05, -4.2), rgb(170, 40, 40))
		for _, z in { -3.6, -4.1, -4.6, -5.0 } do
			S.M("Diente", V3(0.12, 0.25, 0.12), V3(0.55, 0.0 + (z + 3.6) * -0.12, z), WHITE)
			S.M("DienteBajo", V3(0.12, 0.22, 0.12), V3(0.5, 0.05 + (z + 3.6) * 0.15, z - 0.2), WHITE)
		end
		S.M("Narina", V3(0.12, 0.08, 0.12), V3(0.25, 0.75, -5.1), BLACK)
		for _, z in { -1.4, 1.4 } do
			local legs = S.M("Pata", V3(0.6, 0.85, 0.6), V3(1.1, -0.75, z), body)
			S.M("Pie", V3(0.85, 0.2, 0.85), V3(1.15, -1.1, z - 0.1), dark, { on = legs })
		end
		local tail = S.B("Cola", V3(1.3, 0.8, 2.0), V3(0, 0, 3.1), body)
		S.B("Cola2", V3(0.9, 0.6, 1.8), V3(0, -0.05, 4.95), body, { on = tail })
		S.B("Cola3", V3(0.5, 0.4, 1.6), V3(0, -0.1, 6.6), body, { on = tail })
		for i = 0, 3 do
			S.B("EscamaCola", V3(0.25, 0.35, 0.35), V3(0, 0.5 - i * 0.08, 2.6 + i * 1.1), dark, { on = tail })
		end
	end,
}

R.Nigromante = {
	Root = V3(1.8, 2.0, 1.1),
	Hip = 1.8,
	Build = function(S)
		robed(S, { Robe = rgb(36, 38, 46), Dark = rgb(22, 22, 28), Trim = rgb(46, 104, 52), Belt = rgb(60, 50, 40), Eye = rgb(110, 255, 120), Hand = rgb(150, 162, 140), Orb = rgb(90, 255, 110), Top = "Calavera" })
	end,
}

-- DESIERTO DORADO ----------------------------------------------------
R.EscorpionGigante = {
	Root = V3(1.8, 0.8, 2.2),
	Hip = 0.8,
	Build = function(S)
		local body, dark, red = rgb(62, 28, 28), rgb(36, 16, 18), rgb(176, 42, 32)
		S.B("Torax", V3(1.8, 0.8, 2.0), V3(0, 0, -0.2), body)
		S.B("Placa", V3(1.5, 0.15, 1.8), V3(0, 0.45, -0.2), dark)
		S.B("Cabeza", V3(1.2, 0.6, 0.5), V3(0, 0.05, -1.4), body)
		S.M("Ojo", V3(0.18, 0.18, 0.18), V3(0.25, 0.42, -1.2), rgb(255, 50, 30), { glow = true })
		S.B("Segmento", V3(1.6, 0.75, 0.7), V3(0, 0.05, 1.0), body)
		S.B("Segmento", V3(1.4, 0.7, 0.6), V3(0, 0.1, 1.6), dark)
		local tail = S.B("Cola", V3(0.7, 0.65, 0.8), V3(0, 0.4, 2.1), body, { rx = -40 })
		S.B("Cola2", V3(0.65, 0.6, 0.75), V3(0, 1.0, 2.45), dark, { rx = -70, on = tail })
		S.B("Cola3", V3(0.6, 0.55, 0.7), V3(0, 1.7, 2.5), body, { rx = -100, on = tail })
		S.B("Cola4", V3(0.55, 0.5, 0.65), V3(0, 2.3, 2.25), dark, { rx = -140, on = tail })
		S.B("Bulbo", V3(0.6, 0.55, 0.6), V3(0, 2.55, 1.8), red, { on = tail })
		S.B("Aguijon", V3(0.18, 0.18, 0.6), V3(0, 2.35, 1.4), red, { rx = 40, glow = true, on = tail })
		S.M("BrazoPinza", V3(0.5, 0.5, 1.2), V3(1.0, 0.05, -1.7), red, { ry = -25 })
		S.M("Codo", V3(0.55, 0.55, 0.55), V3(1.3, 0.1, -2.3), dark)
		S.M("Pinza", V3(1.1, 0.75, 1.2), V3(1.35, 0.1, -2.9), red)
		S.M("Dedo", V3(0.3, 0.34, 1.1), V3(1.0, 0.1, -3.9), red, { ry = 10 })
		S.M("Dedo", V3(0.3, 0.34, 1.0), V3(1.72, 0.1, -3.85), dark, { ry = -12 })
		S.M("PuntaDedo", V3(0.2, 0.22, 0.3), V3(1.12, 0.1, -4.5), BLACK, { ry = 25 })
		for _, z in { -0.6, -0.1, 0.4, 0.9 } do
			local legs = S.M("Pata", V3(1.3, 0.22, 0.22), V3(1.45, 0.15, z), body, { rz = 25 })
			S.M("Tramo", V3(0.22, 1.4, 0.22), V3(2.1, -0.5, z), dark, { rz = 12, on = legs })
		end
	end,
}

R.Momia = {
	Root = V3(1.9, 2.0, 1.1),
	Hip = 1.8,
	Build = function(S)
		local band, dark = rgb(222, 210, 176), rgb(176, 160, 124)
		local T, A = V3(1.9, 2.0, 1.1), V3(0.8, 1.9, 0.8)
		local arms, legs = biped(S, { T = T, A = A, L = V3(0.85, 1.9, 0.85), Legs = band, Arms = band, ArmsForward = true })
		S.B("Tronco", T, V3(0, 0, 0), band)
		for i = 0, 3 do
			S.B("Venda", V3(1.94, 0.13, 1.14), V3(0, 0.7 - i * 0.45, 0), dark, { rz = if i % 2 == 0 then 6 else -6 })
		end
		S.head(V3(0, 1.75, 0), 1.2, V3(0, 0.15, 0))
		S.B("Cabeza", V3(1.5, 1.5, 1.4), V3(0, 1.75, 0), band)
		S.B("VendaCabeza", V3(1.54, 0.14, 1.44), V3(0, 2.15, 0), dark, { rz = 8 })
		S.B("VendaCabeza", V3(1.54, 0.14, 1.44), V3(0, 1.3, 0), dark, { rz = -6 })
		S.B("Rendija", V3(1.2, 0.36, 0.05), V3(0, 1.8, -0.71), rgb(40, 30, 22))
		S.eyes(0.3, 1.8, -0.73, 0.18, 0.14, rgb(255, 190, 60), { glow = true, glint = false })
		S.body()
		S.B("Suelta", V3(0.25, 0.9, 0.05), V3(0.4, -1.4, -0.58), band, { rz = 10 })
		for s = -1, 1, 2 do
			for i = 0, 2 do
				S.B("VendaBrazo", V3(0.84, 0.12, 0.84), V3(s * 1.35, 0.55 - i * 0.05, -0.35 - i * 0.55), dark, { rx = 80, on = arms[s] })
			end
			S.B("VendaPierna", V3(0.89, 0.12, 0.89), V3(s * 0.48, -1.7, 0), dark, { on = legs[s], rz = 6 })
			S.B("VendaPierna", V3(0.89, 0.12, 0.89), V3(s * 0.48, -2.3, 0), dark, { on = legs[s], rz = -6 })
		end
		S.B("Colgante", V3(0.15, 0.7, 0.05), V3(1.35, 0.1, -1.4), band, { on = arms[1] })
	end,
}

R.GuardianDesierto = { -- Guardián de arena
	Root = V3(3.0, 2.6, 1.8),
	Hip = 1.5,
	Build = function(S)
		golem(S, { Main = rgb(170, 128, 70), Dark = rgb(118, 84, 44), Light = rgb(198, 160, 100), Glow = rgb(255, 214, 80), Crown = rgb(120, 84, 36) })
	end,
}

-- RUINAS ANTIGUAS ----------------------------------------------------
R.EsqueletoGuerrero = {
	Root = V3(1.6, 1.9, 0.9),
	Hip = 1.9,
	Build = function(S)
		local bone, dark = rgb(234, 228, 210), rgb(40, 34, 30)
		local T, A = V3(1.6, 1.9, 0.9), V3(0.38, 1.9, 0.38)
		local arms, legs = biped(S, { T = T, A = A, L = V3(0.4, 2.0, 0.4), Legs = bone, Arms = bone, LegX = 0.42 })
		S.B("Columna", V3(0.35, 1.9, 0.35), V3(0, 0, 0.2), bone)
		for i = 0, 3 do
			S.B("Costilla", V3(1.5 - i * 0.1, 0.16, 0.85), V3(0, 0.65 - i * 0.38, 0), bone)
		end
		S.B("Esternon", V3(0.2, 1.2, 0.1), V3(0, 0.2, -0.43), bone)
		S.B("Pelvis", V3(1.2, 0.4, 0.7), V3(0, -0.9, 0), bone)
		S.B("Taparrabos", V3(1.0, 0.8, 0.08), V3(0, -1.3, -0.4), rgb(96, 70, 46), { rx = 5 })
		S.head(V3(0, 1.75, 0), 1.3, V3(0, 0.2, 0))
		S.B("Cabeza", V3(1.4, 1.3, 1.3), V3(0, 1.75, 0), bone)
		S.B("Mandibula", V3(1.1, 0.35, 1.0), V3(0, 1.02, -0.12), bone)
		S.eyes(0.33, 1.85, -0.65, 0.38, 0.38, BLACK, { glint = false })
		S.M("Pupila", V3(0.12, 0.12, 0.04), V3(0.33, 1.83, -0.71), rgb(255, 70, 50), { glow = true })
		S.B("Nariz", V3(0.15, 0.22, 0.05), V3(0, 1.52, -0.67), BLACK)
		for i = -2, 2 do
			S.B("Diente", V3(0.12, 0.14, 0.05), V3(i * 0.15, 1.22, -0.64), if i % 2 == 0 then bone else rgb(200, 190, 165))
		end
		S.B("Boca", V3(0.8, 0.06, 0.04), V3(0, 1.15, -0.65), dark)
		S.body()
		S.M("Hombro", V3(0.5, 0.5, 0.5), V3(1.0, 0.95, 0), bone, { ball = true, on = arms })
		S.M("Mano", V3(0.45, 0.35, 0.45), V3(1.0, -1.0, 0), bone, { on = arms })
		S.M("Rodilla", V3(0.5, 0.35, 0.5), V3(0.42, -1.95, 0), bone, { on = legs })
		S.M("Pie", V3(0.5, 0.25, 0.75), V3(0.42, -2.75, -0.15), bone, { on = legs })
		sword(S, arms[1], hand(T, A, 1), rgb(140, 110, 90), 2.0)
		S.B("Escudo", V3(0.15, 1.5, 1.5), V3(-1.3, -0.4, -0.1), rgb(120, 82, 50), { cyl = true, on = arms[-1] })
		S.B("Umbo", V3(0.2, 0.5, 0.5), V3(-1.4, -0.4, -0.1), rgb(150, 150, 150), { cyl = true, on = arms[-1] })
	end,
}

R.GuardianPiedra = { -- Gólem de piedra
	Root = V3(3.0, 2.6, 1.8),
	Hip = 1.5,
	Build = function(S)
		golem(S, { Main = rgb(126, 124, 116), Dark = rgb(86, 84, 80), Light = rgb(154, 152, 144), Glow = rgb(140, 255, 120), Moss = rgb(92, 136, 58) })
	end,
}

R.Cultista = {
	Root = V3(1.8, 2.0, 1.1),
	Hip = 1.8,
	Build = function(S)
		robed(S, { Robe = rgb(34, 40, 76), Dark = rgb(22, 24, 46), Trim = rgb(176, 146, 72), Belt = rgb(70, 40, 30), Eye = rgb(200, 230, 255), Hand = rgb(210, 180, 150), Skin = rgb(200, 170, 140), Gem = rgb(255, 50, 40) })
	end,
}

-- MONTAÑAS HELADAS ---------------------------------------------------
R.LoboArtico = {
	Root = V3(1.8, 1.5, 3.0),
	Hip = 1.8,
	Build = function(S)
		wolf(S, { Body = rgb(208, 214, 222), Dark = rgb(132, 146, 166), Light = rgb(236, 240, 246), Eye = rgb(120, 220, 255), Frost = true })
	end,
}

R.GolemHielo = { -- Gigante de hielo
	Root = V3(3.0, 2.8, 1.8),
	Hip = 1.7,
	Build = function(S)
		local fur, light, dark, beard = rgb(92, 106, 140), rgb(150, 162, 190), rgb(52, 60, 90), rgb(196, 206, 222)
		local T, A = V3(3.0, 2.8, 1.8), V3(1.3, 2.6, 1.3)
		local arms, legs = biped(S, { T = T, A = A, L = V3(1.3, 1.8, 1.3), Legs = fur, Arms = fur, LegX = 0.8 })
		S.B("Tronco", T, V3(0, 0, 0), fur)
		S.B("Pecho", V3(2.4, 1.4, 0.2), V3(0, 0.45, -0.95), light)
		S.B("Cinturon", V3(3.05, 0.45, 1.85), V3(0, -1.1, 0), rgb(70, 52, 40))
		S.B("Hebilla", V3(0.6, 0.5, 0.08), V3(0, -1.1, -0.95), rgb(150, 160, 175))
		S.B("Taparrabos", V3(1.4, 1.0, 0.12), V3(0, -1.75, -0.95), rgb(60, 70, 100))
		S.M("Pelaje", V3(1.6, 0.7, 1.6), V3(2.15, 1.05, 0), light, { on = arms })
		S.head(V3(0, 2.0, -0.35), 1.15, V3(0, 0.1, 0))
		S.B("Cabeza", V3(2.0, 1.6, 1.8), V3(0, 2.0, -0.35), fur)
		S.B("Cara", V3(1.5, 1.0, 0.1), V3(0, 2.05, -1.27), light)
		S.B("Barba", V3(1.6, 0.55, 0.35), V3(0, 1.3, -1.2), beard)
		S.B("Boca", V3(0.8, 0.22, 0.05), V3(0, 1.6, -1.33), rgb(30, 36, 60))
		S.M("Colmillo", V3(0.14, 0.22, 0.06), V3(0.28, 1.71, -1.37), WHITE)
		S.B("Nariz", V3(0.35, 0.35, 0.2), V3(0, 2.0, -1.4), dark)
		S.eyes(0.42, 2.3, -1.32, 0.28, 0.2, rgb(150, 225, 255), { glow = true, glint = false, brow = dark, browAngle = 24 })
		S.B("Melena", V3(2.4, 0.9, 1.4), V3(0, 2.1, 0.35), light)
		S.M("Pelaje", V3(0.5, 0.8, 1.4), V3(1.1, 1.6, -0.3), light, { rz = -15 })
		S.body()
		S.M("Mano", V3(1.35, 0.6, 1.35), V3(2.17, -0.95, 0), light, { on = arms })
		S.M("Pie", V3(1.45, 0.45, 1.7), V3(0.8, -3.1, -0.15), light, { on = legs })
		local h = hand(T, A, 1)
		local g = h + V3(0, 0, -0.75)
		S.B("Mango", V3(0.3, 3.0, 0.3), g + V3(0, 0.7, 0), WOOD, { on = arms[1] })
		S.B("Maza", V3(1.4, 1.1, 1.1), g + V3(0, 2.6, 0), rgb(122, 128, 140), { on = arms[1] })
		S.B("Banda", V3(0.2, 1.16, 1.16), g + V3(0, 2.6, 0), rgb(80, 86, 96), { on = arms[1] })
	end,
}

R.DracoHielo = { -- Dragón de hielo
	Root = V3(2.0, 1.8, 3.4),
	Hip = 1.6,
	Build = function(S)
		dragon(S, { Body = rgb(58, 96, 156), Belly = rgb(150, 182, 214), Spike = rgb(196, 226, 246), Dark = rgb(30, 50, 96), Eye = rgb(170, 240, 255), Wing = rgb(110, 175, 245), WingAlpha = 0.1, Icy = true, WingScale = 1.35 })
	end,
}

-- TIERRAS OSCURAS ----------------------------------------------------
R.CaballeroCorrupto = { -- Caballero sombrío
	Root = V3(2.2, 2.2, 1.3),
	Hip = 1.9,
	Build = function(S)
		local armor, dark, trim, purple = rgb(46, 46, 58), rgb(24, 24, 32), rgb(92, 86, 112), rgb(176, 96, 255)
		local T, A = V3(2.2, 2.2, 1.3), V3(1.0, 2.1, 1.0)
		local arms, legs = biped(S, { T = T, A = A, L = V3(1.0, 2.0, 1.0), Legs = armor, Arms = armor })
		S.B("Tronco", T, V3(0, 0, 0), armor)
		S.B("Peto", V3(2.0, 1.3, 0.2), V3(0, 0.35, -0.72), trim)
		S.B("Runa", V3(0.25, 0.6, 0.06), V3(0, 0.35, -0.84), purple, { glow = true })
		S.B("Cinturon", V3(2.25, 0.3, 1.35), V3(0, -0.85, 0), dark)
		S.M("Escarcela", V3(0.95, 0.8, 0.15), V3(0.5, -1.35, -0.68), trim, { rx = -8 })
		S.B("Capa", V3(2.1, 3.4, 0.15), V3(0, -0.5, 0.75), rgb(44, 20, 62))
		S.head(V3(0, 1.95, 0), 1.15, V3(0, 0.12, 0))
		S.B("Cabeza", V3(1.5, 1.6, 1.5), V3(0, 1.95, 0), armor)
		S.B("Visera", V3(1.2, 0.2, 0.05), V3(0, 2.0, -0.76), BLACK)
		S.eyes(0.3, 2.0, -0.78, 0.25, 0.1, purple, { glow = true, glint = false })
		S.B("Cresta", V3(0.2, 0.5, 1.4), V3(0, 2.95, 0), dark)
		S.M("CuernoYelmo", V3(0.22, 0.65, 0.22), V3(0.62, 2.95, 0), dark, { rz = -25 })
		S.B("Babera", V3(1.2, 0.5, 0.1), V3(0, 1.45, -0.77), trim)
		S.body()
		S.M("Hombrera", V3(1.4, 0.7, 1.4), V3(1.62, 1.1, 0), dark, { on = arms })
		S.M("PuaHombro", V3(0.22, 0.65, 0.22), V3(1.75, 1.7, -0.3), trim, { rz = -30, on = arms })
		S.M("PuaHombro", V3(0.22, 0.55, 0.22), V3(1.95, 1.6, 0.3), trim, { rz = -45, on = arms })
		S.M("Guantelete", V3(1.08, 0.7, 1.08), V3(1.62, -0.7, 0), dark, { on = arms })
		S.M("Grebas", V3(1.06, 0.9, 1.1), V3(0.55, -2.45, -0.03), dark, { on = legs })
		S.M("Rodillera", V3(1.08, 0.35, 0.3), V3(0.55, -1.8, -0.5), trim, { on = legs })
		sword(S, arms[1], hand(T, A, 1), rgb(52, 50, 64), 2.7, purple)
		S.light(purple, 10)
	end,
}

R.Demonio = { -- Demonio menor
	Root = V3(2.6, 2.4, 1.4),
	Hip = 1.9,
	Build = function(S)
		demon(S, { Skin = rgb(150, 34, 32), Dark = rgb(90, 18, 22), Horn = rgb(44, 28, 28), Pec = rgb(170, 52, 48), Abs = rgb(128, 28, 30), Glow = rgb(255, 140, 40) })
	end,
}

R.MagoOscuro = {
	Root = V3(1.8, 2.0, 1.1),
	Hip = 1.8,
	Build = function(S)
		robed(S, { Robe = rgb(66, 42, 104), Dark = rgb(36, 24, 60), Trim = rgb(150, 110, 230), Belt = rgb(40, 30, 50), Eye = rgb(120, 210, 255), Hand = rgb(180, 170, 200), Orb = rgb(180, 100, 255), Gem = rgb(190, 110, 255) })
	end,
}

-- TIERRAS VOLCÁNICAS -------------------------------------------------
R.ElementalFuego = {
	Root = V3(1.8, 2.0, 1.2),
	Hip = 1.4,
	Build = function(S)
		local orange, yellow, red, rock = rgb(255, 128, 30), rgb(255, 214, 70), rgb(230, 60, 20), rgb(64, 30, 20)
		local T, A = V3(1.8, 2.0, 1.2), V3(0.9, 1.8, 0.9)
		local arms, legs = biped(S, { T = T, A = A, L = V3(0.9, 1.5, 0.9), Legs = red, Arms = orange })
		S.B("Tronco", T, V3(0, 0, 0), orange)
		S.B("Nucleo", V3(0.6, 0.6, 0.08), V3(0, 0.3, -0.62), yellow, { glow = true, rz = 45 })
		S.B("Roca", V3(0.8, 0.6, 0.15), V3(0.5, -0.4, -0.65), rock, { rz = 10 })
		S.B("Roca", V3(0.6, 0.5, 0.15), V3(-0.5, 0.6, -0.65), rock, { rz = -15 })
		S.M("RocaBrazo", V3(0.95, 0.5, 0.6), V3(1.35, 0.1, -0.1), rock, { on = arms })
		S.M("LlamaPierna", V3(0.7, 0.6, 0.7), V3(0.4, -2.7, 0), yellow, { glow = true, on = legs })
		S.head(V3(0, 1.85, 0), 1.15, V3(0, 0.12, 0))
		S.B("Cabeza", V3(1.6, 1.6, 1.4), V3(0, 1.85, 0), rgb(255, 176, 50))
		S.M("Ojo", V3(0.32, 0.38, 0.06), V3(0.38, 1.95, -0.72), rgb(60, 20, 10))
		S.B("Boca", V3(0.7, 0.18, 0.06), V3(0, 1.45, -0.72), rgb(90, 30, 10))
		S.M("CejaFuego", V3(0.5, 0.12, 0.08), V3(0.38, 2.25, -0.72), red, { glow = true, rz = 20 })
		for i, p in { V3(0, 2.95, 0), V3(0.5, 2.8, 0.1), V3(-0.5, 2.8, 0.1), V3(0.25, 3.3, 0.2), V3(-0.3, 3.2, -0.1) } do
			S.B("Llama", V3(0.45, 0.8, 0.45), p, if i % 2 == 0 then orange else yellow, { glow = true, rz = (i - 3) * 10 })
		end
		S.body()
		S.M("Hombro", V3(0.7, 0.6, 0.7), V3(1.35, 1.1, 0), yellow, { glow = true, on = arms })
		S.M("ManoFuego", V3(0.7, 0.7, 0.7), V3(1.35, -0.95, 0), yellow, { glow = true, on = arms })
		local top = S.B("Corazon", V3(0.2, 0.2, 0.2), V3(0, 3.4, 0), yellow, { glow = true })
		S.sparks(top, rgb(255, 160, 40), 18)
		S.light(rgb(255, 140, 40), 16)
	end,
}

R.GolemLava = { -- Gólem de lava
	Root = V3(3.0, 2.6, 1.8),
	Hip = 1.5,
	Build = function(S)
		golem(S, { Main = rgb(58, 44, 40), Dark = rgb(36, 28, 26), Light = rgb(80, 60, 52), Glow = rgb(255, 120, 30), Cracks = true })
	end,
}

R.DragonInfernal = {
	Root = V3(2.0, 1.8, 3.4),
	Hip = 1.6,
	Build = function(S)
		dragon(S, { Body = rgb(48, 30, 30), Belly = rgb(96, 40, 30), Spike = rgb(30, 20, 20), Dark = rgb(24, 14, 14), Eye = rgb(255, 120, 30), Wing = rgb(150, 30, 24), Cracks = true, WingScale = 1.65 })
	end,
}

---------------------------------------------------------------------
-- Segundo cartel: más plantillas
---------------------------------------------------------------------

-- Bestia grande a cuatro patas (bestia salvaje con cuernos, tigre, criatura venenosa, bestia sombría)
local function beast(S: Tools, c: Opt)
	local body, dark, belly = c.Body, c.Dark, c.Belly
	S.B("Tronco", V3(2.2, 1.8, 3.4), V3(0, 0, 0), body)
	S.B("Lomo", V3(1.8, 0.35, 2.8), V3(0, 0.95, 0.1), dark)
	S.B("Barriga", V3(1.9, 0.3, 2.8), V3(0, -0.82, 0), belly)
	S.B("Hombros", V3(2.4, 1.8, 1.3), V3(0, 0.25, -1.1), body)
	S.B("Pecho", V3(1.8, 1.3, 0.5), V3(0, -0.05, -1.85), belly)
	S.B("Cabeza", V3(1.7, 1.5, 1.6), V3(0, 0.7, -2.5), body)
	S.B("Hocico", V3(1.1, 0.7, 0.8), V3(0, 0.35, -3.65), c.Muzzle or belly)
	S.B("Cana", V3(1.1, 0.35, 0.6), V3(0, 0.88, -3.55), body, { wedge = true })
	S.B("Nariz", V3(0.5, 0.25, 0.15), V3(0, 0.62, -4.06), BLACK)
	S.B("Boca", V3(0.95, 0.14, 0.05), V3(0, 0.12, -4.06), rgb(40, 10, 10))
	S.M("Colmillo", V3(0.11, 0.26, 0.08), V3(0.32, 0.06, -4.08), IVORY)
	S.M("Diente", V3(0.08, 0.16, 0.08), V3(0.14, 0.1, -4.08), IVORY)
	S.eyes(0.45, 0.98, -3.3, 0.3, 0.26, c.Eye, { glow = true, brow = dark, browAngle = 24 })
	if c.Ears then
		S.M("Oreja", V3(0.25, 0.55, 0.42), V3(0.62, 1.6, -2.3), c.Ears, { wedge = true, ry = 90 })
	end
	for _, z in { -1.2, 1.2 } do
		local legs = S.M("Pata", V3(0.85, 1.8, 0.85), V3(0.78, -1.7, z), body)
		S.M("Muslo", V3(1.0, 0.9, 1.15), V3(0.85, -0.85, z), body, { on = legs })
		S.M("Zarpa", V3(0.95, 0.32, 1.05), V3(0.78, -2.45, z - 0.08), dark, { on = legs })
		S.M("Garra", V3(0.1, 0.14, 0.25), V3(0.58, -2.53, z - 0.62), IVORY, { on = legs })
		S.M("Garra", V3(0.1, 0.14, 0.25), V3(0.98, -2.53, z - 0.62), IVORY, { on = legs })
	end
	local tail = S.B("Cola", V3(0.35, 0.35, 2.0), V3(0, 0.75, 2.55), body, { rx = -20 })
	S.B("PuntaCola", V3(0.5, 0.5, 0.6), V3(0, 1.1, 3.5), dark, { rx = -20, on = tail })
	if c.Horns then
		S.M("Cuerno", V3(1.0, 0.42, 0.42), V3(1.2, 1.35, -2.3), c.Horns, { rz = 10 })
		S.M("Cuerno2", V3(0.36, 0.85, 0.36), V3(1.65, 1.85, -2.3), c.Horns, { rz = -20 })
		S.M("PuntaCuerno", V3(0.24, 0.45, 0.24), V3(1.55, 2.35, -2.35), dark, { rz = 30 })
	end
	if c.Mane then
		S.B("Melena", V3(2.6, 2.0, 1.0), V3(0, 0.8, -1.85), c.Mane)
		S.B("Flequillo", V3(1.4, 0.45, 1.1), V3(0, 1.55, -2.4), c.Mane)
		S.M("Barbas", V3(0.4, 0.8, 0.6), V3(0.7, -0.15, -2.6), c.Mane)
	end
	if c.Stripes then
		for _, z in { -1.3, -0.5, 0.3, 1.1 } do
			S.M("Raya", V3(0.08, 1.3, 0.3), V3(1.12, 0.25, z), BLACK, { rz = 10 })
			S.B("RayaLomo", V3(1.5, 0.06, 0.3), V3(0, 1.14, z + 0.2), BLACK)
		end
		S.B("RayaFrente", V3(0.15, 0.45, 0.05), V3(0, 1.2, -3.32), BLACK)
		S.M("RayaFrente", V3(0.1, 0.4, 0.05), V3(0.38, 1.25, -3.32), BLACK, { rz = 20 })
		S.M("Mejilla", V3(0.35, 0.6, 0.7), V3(0.88, 0.45, -2.75), belly, { wedge = true, ry = 180, rz = -10 })
		S.M("RayaPata", V3(0.88, 0.1, 0.88), V3(0.78, -1.3, -1.2), BLACK)
	end
	if c.Spikes then
		for i = 0, 5 do
			local p = S.B("Pua", V3(0.3, 0.85, 0.42), V3(0, 1.4, -1.5 + i * 0.6), c.Spikes, { rx = -25, glow = c.SpikeGlow })
			p.CastShadow = false
		end
		S.M("PuaHombro", V3(0.26, 0.75, 0.32), V3(1.15, 1.05, -1.1), c.Spikes, { rz = -40, glow = c.SpikeGlow })
	end
	if c.Veins then
		S.M("Vena", V3(0.06, 0.9, 0.15), V3(1.12, 0.05, 0.4), c.Veins, { glow = true, rz = 30 })
		S.M("Vena", V3(0.06, 0.7, 0.15), V3(1.12, 0.1, -0.5), c.Veins, { glow = true, rz = -25 })
		S.B("Baba", V3(0.15, 0.4, 0.15), V3(0.25, -0.15, -4.05), c.Veins, { glow = true })
		S.light(c.Veins, 10)
	end
	if c.Wisps then
		local e = Instance.new("ParticleEmitter")
		e.Name = "Sombra"
		e.Color = ColorSequence.new(rgb(30, 0, 50), c.Wisps)
		e.Transparency = NumberSequence.new(0.4, 1)
		e.Size = NumberSequence.new(0.8, 1.8)
		e.Lifetime = NumberRange.new(0.8, 1.4)
		e.Rate = 8
		e.Speed = NumberRange.new(0.5, 1.5)
		e.Parent = S.B("Humo", V3(0.2, 0.2, 0.2), V3(0, 0.5, 0), c.Wisps, { alpha = 1 })
	end
end

-- Guerrero (bandidos, nómadas, saqueadores, muertos, caballeros y arqueros espectrales, reyes)
local function warrior(S: Tools, c: Opt)
	local T, A, L, H = c.T or V3(2.0, 2.0, 1.1), c.A or V3(0.9, 2.0, 0.9), c.L or V3(0.95, 2.0, 0.95), c.H or V3(1.6, 1.6, 1.5)
	local a = c.Alpha
	local arms, legs = biped(S, { T = T, A = A, L = L, Legs = c.Pants, Arms = c.Sleeve or c.Shirt, ArmsForward = c.ArmsForward })
	if a then
		for _, p in arms do
			p.Transparency = a
		end
		for _, p in legs do
			p.Transparency = a
		end
	end
	local hy, fz = T.Y / 2 + H.Y / 2, -H.Z / 2
	local ax = T.X / 2 + A.X / 2 + 0.02
	local lx = T.X / 2 - L.X / 2 - 0.05
	local foot = -T.Y / 2 - L.Y + 0.1
	local handY = T.Y / 2 - A.Y + 0.2
	S.B("Tronco", T, V3(0, 0, 0), c.Shirt, { alpha = a })
	S.B("Cinturon", V3(T.X + 0.05, 0.3, T.Z + 0.05), V3(0, -T.Y / 2 + 0.15, 0), c.Belt or rgb(48, 34, 26), { alpha = a })
	S.B("Hebilla", V3(0.35, 0.25, 0.06), V3(0, -T.Y / 2 + 0.15, -T.Z / 2 - 0.05), c.Buckle or rgb(190, 160, 80), { alpha = a })
	if c.Vest then
		S.M("Chaleco", V3(T.X * 0.31, T.Y + 0.02, T.Z + 0.04), V3(T.X * 0.35, 0, 0), c.Vest, { alpha = a })
		S.B("Correa", V3(0.3, T.Y * 1.35, 0.06), V3(0, 0.05, -T.Z / 2 - 0.04), c.Belt or rgb(48, 34, 26), { rz = 40, alpha = a })
	end
	if c.Armor then
		S.B("Peto", V3(T.X * 0.9, T.Y * 0.62, 0.2), V3(0, T.Y * 0.15, -T.Z / 2 - 0.08), c.Armor, { alpha = a })
		S.M("Hombrera", V3(A.X + 0.45, 0.6, A.Z + 0.45), V3(ax, T.Y / 2 - 0.12, 0), c.Armor, { on = arms, alpha = a })
		S.M("Guantelete", V3(A.X + 0.1, 0.65, A.Z + 0.1), V3(ax, handY + 0.1, 0), c.Armor2 or c.Armor, { on = arms, alpha = a })
		S.M("Grebas", V3(L.X + 0.1, 0.95, L.Z + 0.12), V3(lx, foot + 0.48, -0.03), c.Armor2 or c.Armor, { on = legs, alpha = a })
		S.M("Escarcela", V3(L.X, 0.8, 0.15), V3(lx, -T.Y / 2 - 0.35, -T.Z / 2 - 0.06), c.Armor2 or c.Armor, { rx = -8, alpha = a })
		if c.Glow then
			S.B("Runa", V3(0.25, 0.6, 0.06), V3(0, T.Y * 0.15, -T.Z / 2 - 0.2), c.Glow, { glow = true })
		end
		if c.Spikes then
			S.M("PuaHombro", V3(0.24, 0.75, 0.24), V3(ax + 0.15, T.Y / 2 + 0.45, -0.25), c.Spikes, { rz = -30, on = arms })
			S.M("PuaHombro", V3(0.22, 0.6, 0.22), V3(ax + 0.35, T.Y / 2 + 0.35, 0.3), c.Spikes, { rz = -50, on = arms })
		end
	elseif not c.ArmsForward then
		S.M("Brazal", V3(A.X + 0.06, 0.45, A.Z + 0.06), V3(ax, handY + 0.5, 0), c.Belt or rgb(48, 34, 26), { on = arms, alpha = a })
		S.M("Mano", V3(A.X + 0.05, 0.45, A.Z + 0.05), V3(ax, handY, 0), c.Skin, { on = arms, alpha = a })
	end
	S.M("Bota", V3(L.X + 0.05, 0.8, L.Z + 0.1), V3(lx, foot + 0.4, -0.03), c.Boot or rgb(48, 34, 26), { on = legs, alpha = a })
	if c.Cape then
		S.B("Capa", V3(T.X * 0.95, T.Y + L.Y * 0.75, 0.12), V3(0, -L.Y * 0.37, T.Z / 2 + 0.08), c.Cape, { alpha = a })
		S.B("CapaCuello", V3(T.X + 0.1, 0.35, T.Z + 0.15), V3(0, T.Y / 2 - 0.1, 0.02), c.Cape, { alpha = a })
	end
	-- cabeza
	local eyeC = c.Eye or rgb(120, 100, 80)
	if c.Helm then
		S.B("Cabeza", H, V3(0, hy, 0), c.Helm, { alpha = a })
		S.B("Visera", V3(H.X * 0.8, 0.2, 0.05), V3(0, hy + 0.05, fz - 0.01), BLACK)
		S.eyes(H.X * 0.2, hy + 0.05, fz - 0.02, 0.26, 0.14, eyeC, { glow = true })
		S.B("Babera", V3(H.X * 0.8, 0.5, 0.1), V3(0, hy - 0.5, fz - 0.03), c.Armor2 or c.Helm, { alpha = a })
		S.B("Cresta", V3(0.2, 0.45, H.Z * 0.9), V3(0, hy + H.Y / 2 + 0.2, 0), c.Armor2 or c.Helm, { alpha = a })
		if c.HelmHorns then
			S.M("CuernoYelmo", V3(0.26, 0.9, 0.26), V3(H.X * 0.45, hy + H.Y / 2 + 0.25, 0), c.HelmHorns, { rz = -28 })
			S.M("PuntaCuerno", V3(0.18, 0.5, 0.18), V3(H.X * 0.62, hy + H.Y / 2 + 0.85, 0), c.Glow or c.HelmHorns, { rz = -10, glow = c.Glow ~= nil })
		end
	else
		S.B("Cabeza", H, V3(0, hy, 0), c.Skin, { alpha = a })
		S.eyes(H.X * 0.22, hy + 0.12, fz, 0.22, 0.25, eyeC, { glow = c.EyeGlow, brow = c.Brow or c.Hair or rgb(40, 30, 24), browAngle = 18 })
		S.B("Nariz", V3(0.25, 0.3, 0.15), V3(0, hy - 0.12, fz - 0.05), c.Skin:Lerp(BLACK, 0.12), { alpha = a })
		if not c.Mask then
			S.B("Boca", V3(0.5, 0.1, 0.05), V3(0, hy - 0.45, fz - 0.02), rgb(70, 30, 26))
		end
		if c.Hair then
			S.B("Pelo", V3(H.X + 0.1, 0.45, H.Z + 0.1), V3(0, hy + H.Y / 2 - 0.05, 0.05), c.Hair)
			S.B("Nuca", V3(H.X + 0.1, 1.2, 0.35), V3(0, hy + 0.2, H.Z / 2 - 0.1), c.Hair)
		end
		if c.Hood then
			S.B("Capucha", V3(H.X + 0.25, 0.5, H.Z + 0.25), V3(0, hy + H.Y / 2, 0.05), c.Hood, { alpha = a })
			S.M("CapuchaLado", V3(0.2, H.Y + 0.1, H.Z + 0.2), V3(H.X / 2 + 0.08, hy, 0.08), c.Hood, { alpha = a })
			S.B("CapuchaAtras", V3(H.X + 0.25, H.Y + 0.2, 0.25), V3(0, hy - 0.05, H.Z / 2 + 0.1), c.Hood, { alpha = a })
			S.B("PicoCapucha", V3(0.6, 0.5, 0.6), V3(0, hy + H.Y / 2 + 0.2, 0.5), c.Hood, { rx = 25, alpha = a })
			S.B("SombraFrente", V3(H.X, 0.35, 0.06), V3(0, hy + 0.5, fz - 0.03), rgb(20, 16, 14))
		end
		if c.Turban then
			S.B("Turbante", V3(H.X + 0.15, 0.6, H.Z + 0.15), V3(0, hy + H.Y / 2 - 0.05, 0), c.Turban)
			S.B("Vuelta", V3(H.X + 0.2, 0.2, H.Z + 0.2), V3(0, hy + H.Y / 2 - 0.3, 0), c.Turban:Lerp(BLACK, 0.15), { rz = 6 })
			S.B("Faldon", V3(0.4, 0.9, 0.12), V3(0.3, hy, H.Z / 2 + 0.1), c.Turban, { rz = 12 })
		end
		if c.Band then
			S.B("Cinta", V3(H.X + 0.06, 0.22, H.Z + 0.06), V3(0, hy + 0.48, 0), c.Band)
			S.M("CintaCola", V3(0.18, 0.7, 0.08), V3(0.2, hy + 0.15, H.Z / 2 + 0.06), c.Band, { rz = 15 })
		end
		if c.Mask then
			S.B("Panuelo", V3(H.X + 0.06, 0.72, H.Z + 0.06), V3(0, hy - 0.42, 0), c.Mask)
			S.B("PicoPanuelo", V3(0.5, 0.5, 0.08), V3(0, hy - 0.8, fz - 0.05), c.Mask:Lerp(BLACK, 0.12), { rz = 45 })
		end
		if c.Beard then
			S.B("Barba", V3(H.X * 0.9, 0.55, 0.25), V3(0, hy - 0.55, fz - 0.05), c.Beard)
		end
		if c.Scar then
			S.B("Cicatriz", V3(0.06, 0.55, 0.04), V3(H.X * 0.2, hy + 0.15, fz - 0.03), rgb(150, 90, 80), { rz = 20 })
		end
		if c.Zombie then
			S.B("Herida", V3(0.35, 0.25, 0.05), V3(-0.35, hy - 0.25, fz - 0.03), rgb(90, 20, 20))
			S.B("Mandibula", V3(0.7, 0.25, 0.3), V3(0, hy - 0.75, fz + 0.12), c.Skin:Lerp(BLACK, 0.2), { rx = 12 })
			S.B("Roto", V3(0.5, 0.6, 0.06), V3(0.45, -0.25, -T.Z / 2 - 0.02), c.Skin:Lerp(BLACK, 0.1))
			for i = 0, 2 do
				S.B("Costilla", V3(0.45, 0.08, 0.04), V3(0.45, -0.05 - i * 0.18, -T.Z / 2 - 0.06), IVORY)
			end
			S.B("Harapo", V3(0.5, 0.5, 0.06), V3(-0.5, -T.Y / 2 - 0.3, -T.Z / 2 - 0.02), c.Shirt, { rz = 12 })
			S.B("HarapoPierna", V3(0.4, 0.4, 0.06), V3(lx, foot + 1.2, -L.Z / 2 - 0.02), c.Skin, { on = legs[1] })
		end
	end
	if c.Crown then
		S.B("Corona", V3(H.X + 0.12, 0.3, H.Z + 0.12), V3(0, hy + H.Y / 2 + 0.12, 0), c.Crown)
		for _, z in { -1, 1 } do
			S.M("PicoCorona", V3(0.2, 0.5, 0.2), V3(H.X * 0.38, hy + H.Y / 2 + 0.5, z * H.Z * 0.32), c.Crown)
		end
		S.B("PicoCorona", V3(0.24, 0.65, 0.2), V3(0, hy + H.Y / 2 + 0.55, fz + 0.05), c.Crown)
		S.B("Joya", V3(0.22, 0.22, 0.06), V3(0, hy + H.Y / 2 + 0.12, fz - 0.1), c.Glow or rgb(80, 160, 255), { glow = true })
	end
	-- arma
	local h = V3(ax, T.Y / 2 - A.Y + 0.25, 0)
	local w = c.Weapon
	if c.ArmsForward then
		w = nil
	end
	if w == "Espada" then
		sword(S, arms[1], h, c.Blade or METAL, c.BladeLen or 2.2, c.BladeGlow)
	elseif w == "Lanza" then
		S.B("Asta", V3(0.18, 5.0, 0.18), h + V3(0, 0.9, -0.55), WOOD, { on = arms[1] })
		S.B("PuntaLanza", V3(0.12, 0.75, 0.35), h + V3(0, 3.75, -0.55), METAL, { on = arms[1] })
		S.B("Borla", V3(0.32, 0.32, 0.32), h + V3(0, 3.2, -0.55), c.Band or rgb(150, 40, 30), { on = arms[1] })
	elseif w == "Hacha" then
		local g = h + V3(0, 0, -0.55)
		S.B("Mango", V3(0.2, 2.6, 0.2), g + V3(0, 0.6, 0), WOOD, { on = arms[1] })
		S.B("HojaHacha", V3(0.12, 0.8, 0.8), g + V3(0, 1.6, -0.5), rgb(130, 132, 140), { on = arms[1] })
		S.B("Filo", V3(0.13, 0.95, 0.14), g + V3(0, 1.6, -0.92), rgb(205, 210, 218), { on = arms[1] })
	elseif w == "Cimitarra" then
		sword(S, arms[1], h, METAL, 1.6)
		S.B("Curva", V3(0.1, 0.7, 0.32), h + V3(0, 0.55 + 2.25, -0.75), METAL, { on = arms[1], rx = -25 })
	elseif w == "Arco" then
		local hl = V3(-ax, h.Y, 0)
		local bow = c.BowColor or WOOD
		S.B("Arco", V3(0.16, 1.3, 0.16), hl + V3(0, 0, -0.45), bow, { on = arms[-1], glow = c.BowGlow })
		S.B("ArcoArriba", V3(0.13, 1.2, 0.13), hl + V3(0, 1.15, -0.25), bow, { rx = -20, on = arms[-1], glow = c.BowGlow })
		S.B("ArcoAbajo", V3(0.13, 1.2, 0.13), hl + V3(0, -1.15, -0.25), bow, { rx = 20, on = arms[-1], glow = c.BowGlow })
		S.B("Cuerda", V3(0.03, 3.0, 0.03), hl + V3(0, 0, 0.05), rgb(230, 230, 220), { on = arms[-1] })
		S.B("Carcaj", V3(0.5, 1.4, 0.5), V3(0.45, 0.3, T.Z / 2 + 0.25), rgb(90, 60, 40), { rz = 20, alpha = a })
		S.B("Flechas", V3(0.36, 0.4, 0.36), V3(0.7, 1.05, T.Z / 2 + 0.25), c.Glow or WHITE, { rz = 20, glow = c.Glow ~= nil })
	end
	if c.Glow and a then
		S.sparks(S.B("Nucleo", V3(0.3, 0.3, 0.3), V3(0, 0.3, 0), c.Glow, { glow = true, alpha = 0.5 }), c.Glow, 6)
		S.light(c.Glow, 10)
	end
	return arms, legs
end

-- Espectro flotante (espíritu del bosque, espíritu maldito, espectro glacial, espectro del vacío)
local function ghost(S: Tools, c: Opt)
	local a = c.Alpha or 0.3
	S.B("Tronco", V3(1.8, 1.9, 1.1), V3(0, 0, 0), c.Body, { alpha = a })
	S.B("Estela", V3(1.6, 0.9, 1.0), V3(0, -1.35, 0.05), c.Body, { alpha = a + 0.1 })
	S.B("Estela", V3(1.15, 0.8, 0.8), V3(0, -2.05, 0.15), c.Body, { alpha = a + 0.2, rz = 6 })
	S.B("Estela", V3(0.65, 0.7, 0.5), V3(0.1, -2.7, 0.3), c.Body, { alpha = a + 0.3, rz = 12 })
	local arms = S.M("Brazo", V3(0.6, 1.7, 0.6), V3(1.22, 0.1, 0), c.Body, { alpha = a })
	for _, dz in { -0.22, 0.05 } do
		S.M("Garra", V3(0.12, 0.4, 0.12), V3(1.22, -0.9, dz - 0.1), c.Glow, { glow = true, on = arms })
	end
	if c.Hood then
		S.B("Cabeza", V3(1.6, 1.6, 1.5), V3(0, 1.75, 0.05), c.Hood)
		S.B("Pico", V3(0.6, 0.5, 0.6), V3(0, 2.6, 0.4), c.Hood, { rx = 25 })
		S.B("Sombra", V3(1.1, 1.1, 0.06), V3(0, 1.65, -0.71), rgb(8, 10, 10))
		S.eyes(0.27, 1.75, -0.74, 0.25, 0.14, c.Eye, { glow = true })
		S.B("CapaFantasma", V3(2.0, 0.5, 1.3), V3(0, 0.85, 0.02), c.Hood)
	else
		S.B("Cabeza", V3(1.4, 1.4, 1.3), V3(0, 1.75, 0), c.Body, { alpha = a })
		S.eyes(0.3, 1.85, -0.65, 0.28, 0.2, c.Eye, { glow = true })
		S.B("Boca", V3(0.5, 0.35, 0.05), V3(0, 1.35, -0.66), rgb(10, 14, 16))
	end
	local core = S.B("Nucleo", V3(0.6, 0.6, 0.6), V3(0, 0.3, -0.2), c.Glow, { glow = true, ball = true })
	S.sparks(core, c.Glow, 8)
	S.light(c.Glow, 12)
	if c.Leaves then
		for i = -2, 2 do
			S.B("Hoja", V3(0.35, 0.65, 0.14), V3(i * 0.32, 2.65 - math.abs(i) * 0.12, -0.15), c.Leaves, { rz = i * 15, glow = true })
		end
		S.M("Enredadera", V3(0.66, 0.15, 0.66), V3(1.22, 0.4, 0), c.Leaves, { on = arms })
		S.B("Enredadera", V3(1.84, 0.15, 1.14), V3(0, -0.4, 0), c.Leaves, { rz = 8 })
	end
	if c.Ice then
		local ice = rgb(210, 240, 255)
		for i = -1, 1 do
			S.B("Carambano", V3(0.25, 0.8, 0.25), V3(i * 0.4, 2.65, 0), ice, { glass = true, alpha = 0.15, rz = i * 15 })
		end
		S.M("CarambanoHombro", V3(0.25, 0.7, 0.25), V3(1.1, 1.2, 0), ice, { glass = true, alpha = 0.15, rz = -30, on = arms })
		S.B("Corona", V3(1.5, 0.2, 1.4), V3(0, 2.45, 0), ice, { glass = true, alpha = 0.2 })
	end
	if c.Horns then
		S.M("Cuerno", V3(0.25, 0.8, 0.25), V3(0.55, 2.65, 0), c.Horns, { rz = -25 })
	end
	if c.Chains then
		S.M("Cadena", V3(0.7, 0.25, 0.7), V3(1.22, -0.5, 0), rgb(70, 70, 76), { on = arms })
		S.B("Cadena", V3(0.25, 1.2, 0.12), V3(0.6, -1.2, -0.56), rgb(70, 70, 76), { rz = 15 })
	end
end

-- Patas en arco (araña, mantis): suben a la rodilla y bajan abiertas al suelo
local function archLegs(S: Tools, zs: { number }, baseX: number, baseY: number, L1: number, a: number, reach: number, ground: number, w: number, upper: Color3, knee: Color3, lower: Color3, fan: number)
	local up = V3(0, 1, 0)
	for i, z in zs do
		local psi = ((#zs + 1) / 2 - i) * fan
		local dir = V3(math.cos(math.rad(psi)), 0, -math.sin(math.rad(psi)))
		local base = V3(baseX, baseY, z)
		local kneeP = base + dir * (L1 * math.cos(math.rad(a))) + up * (L1 * math.sin(math.rad(a)))
		local legs = S.M("Pata", V3(L1, w, w), base + dir * (L1 / 2 * math.cos(math.rad(a))) + up * (L1 / 2 * math.sin(math.rad(a))), upper, { rz = a, ry = psi })
		S.M("Rodilla", V3(w * 1.3, w * 1.3, w * 1.3), kneeP, knee, { on = legs })
		local h = kneeP.Y - ground
		local L2 = math.sqrt(reach * reach + h * h)
		S.M("Tramo", V3(w * 0.9, L2, w * 0.9), kneeP + dir * (reach / 2) - up * (h / 2), lower, { rz = math.deg(math.atan2(reach, h)), ry = psi, on = legs })
	end
end

---------------------------------------------------------------------
-- Recetas del segundo cartel
---------------------------------------------------------------------

-- BOSQUE ETÉREO
R.EspirituBosque = {
	Root = V3(1.8, 1.9, 1.1),
	Hip = 2.0,
	Build = function(S)
		ghost(S, { Body = rgb(80, 220, 190), Glow = rgb(150, 255, 220), Eye = rgb(220, 255, 240), Leaves = rgb(90, 220, 110), Alpha = 0.35 })
	end,
}

R.BandidoBosque = {
	Root = V3(2.0, 2.0, 1.1),
	Hip = 1.9,
	Build = function(S)
		warrior(S, { Shirt = rgb(70, 90, 52), Pants = rgb(70, 58, 44), Vest = rgb(86, 60, 40), Skin = rgb(214, 168, 128), Hood = rgb(52, 74, 40),
			Mask = rgb(40, 50, 34), Eye = rgb(130, 110, 80), Brow = rgb(50, 36, 26), Scar = true, Weapon = "Hacha" })
	end,
}

R.GuardianAncestral = {
	Root = V3(3.0, 2.6, 1.8),
	Hip = 1.5,
	Build = function(S)
		golem(S, { Main = rgb(96, 70, 44), Dark = rgb(60, 42, 26), Light = rgb(124, 94, 60), Glow = rgb(130, 255, 120), Moss = rgb(72, 128, 52),
			Leaf = rgb(66, 150, 58), Wood = true, MouthGlow = true })
	end,
}

-- LLANURAS SALVAJES
R.BestiaSalvaje = {
	Root = V3(2.2, 1.8, 3.4),
	Hip = 1.7,
	Build = function(S)
		beast(S, { Body = rgb(92, 60, 40), Dark = rgb(56, 36, 24), Belly = rgb(130, 96, 68), Muzzle = rgb(120, 88, 66), Eye = rgb(255, 90, 50),
			Horns = rgb(220, 206, 172), Mane = rgb(54, 34, 22), Ears = rgb(80, 52, 34) })
	end,
}

R.Depredador = {
	Root = V3(3.0, 2.6, 1.7),
	Hip = 1.6,
	Build = function(S)
		local fur, skin, dark, horn = rgb(46, 42, 44), rgb(82, 72, 70), rgb(28, 26, 28), rgb(206, 194, 166)
		local T, A = V3(3.0, 2.6, 1.7), V3(1.3, 2.9, 1.3)
		local arms, legs = biped(S, { T = T, A = A, L = V3(1.25, 1.7, 1.25), Legs = fur, Arms = fur, LegX = 0.8 })
		S.B("Tronco", T, V3(0, 0, 0), fur)
		S.B("Joroba", V3(2.6, 1.0, 1.4), V3(0, 1.3, 0.3), dark)
		S.M("Pectoral", V3(1.2, 0.8, 0.12), V3(0.65, 0.5, -0.88), skin)
		S.B("Abdomen", V3(1.2, 1.0, 0.1), V3(0, -0.45, -0.87), skin)
		S.B("Cabeza", V3(1.6, 1.5, 1.6), V3(0, 1.65, -0.75), fur)
		S.B("Frente", V3(1.7, 0.4, 0.35), V3(0, 2.05, -1.45), dark)
		S.B("Hocico", V3(1.1, 0.7, 0.55), V3(0, 1.3, -1.75), skin)
		S.B("Boca", V3(0.9, 0.2, 0.05), V3(0, 1.12, -2.03), rgb(40, 8, 8))
		S.M("Colmillo", V3(0.12, 0.3, 0.08), V3(0.32, 1.12, -2.06), IVORY)
		S.M("Narina", V3(0.16, 0.1, 0.05), V3(0.22, 1.5, -2.04), BLACK)
		S.eyes(0.38, 1.82, -1.6, 0.26, 0.2, rgb(255, 50, 30), { glow = true, brow = dark, browAngle = 26 })
		S.M("Cuerno", V3(0.9, 0.38, 0.38), V3(1.05, 2.25, -0.7), horn, { rz = 15 })
		S.M("Cuerno2", V3(0.32, 0.8, 0.32), V3(1.45, 2.7, -0.7), horn, { rz = -18 })
		for i = 0, 3 do
			S.B("Pua", V3(0.3, 0.7, 0.4), V3(0, 1.9 - i * 0.15, -0.2 + i * 0.45), dark, { rx = -30 })
		end
		S.M("Mano", V3(1.4, 0.7, 1.4), V3(2.17, -1.35, 0), skin, { on = arms })
		for _, dx in { -0.4, 0, 0.4 } do
			S.M("Garra", V3(0.14, 0.4, 0.14), V3(2.17 + dx, -1.85, -0.5), IVORY, { on = arms })
		end
		S.M("Pie", V3(1.35, 0.4, 1.6), V3(0.8, -2.95, -0.15), skin, { on = legs })
	end,
}

R.GuerreroNomada = {
	Root = V3(2.0, 2.0, 1.1),
	Hip = 1.9,
	Build = function(S)
		warrior(S, { Shirt = rgb(150, 112, 72), Pants = rgb(96, 70, 48), Vest = rgb(110, 76, 48), Skin = rgb(176, 124, 86), Hair = rgb(30, 22, 18),
			Band = rgb(170, 40, 30), Eye = rgb(90, 70, 50), Beard = rgb(36, 26, 20), Weapon = "Lanza" })
	end,
}

R.AcechadorPradera = { -- Tigre salvaje
	Root = V3(2.2, 1.8, 3.4),
	Hip = 1.7,
	Build = function(S)
		beast(S, { Body = rgb(214, 120, 40), Dark = rgb(160, 80, 24), Belly = rgb(236, 226, 206), Muzzle = rgb(236, 226, 206), Eye = rgb(255, 210, 60),
			Stripes = true, Ears = rgb(190, 100, 30) })
	end,
}

R.ReyLlanuras = { -- hombre león con armadura
	Root = V3(2.8, 2.6, 1.6),
	Hip = 1.9,
	Build = function(S)
		local fur, mane, gold, dark = rgb(196, 148, 78), rgb(116, 70, 34), rgb(200, 158, 60), rgb(70, 48, 30)
		local T, A = V3(2.8, 2.6, 1.6), V3(1.25, 2.6, 1.25)
		local arms, legs = biped(S, { T = T, A = A, L = V3(1.25, 2.0, 1.25), Legs = fur, Arms = fur })
		S.B("Tronco", T, V3(0, 0, 0), fur)
		S.B("Peto", V3(2.6, 1.6, 0.25), V3(0, 0.4, -0.85), gold)
		S.B("Emblema", V3(0.6, 0.6, 0.06), V3(0, 0.45, -1.0), rgb(255, 210, 90), { glow = true, rz = 45 })
		S.B("Cinturon", V3(2.85, 0.4, 1.65), V3(0, -1.1, 0), dark)
		S.B("Faldon", V3(1.4, 1.1, 0.12), V3(0, -1.7, -0.85), rgb(140, 30, 26))
		S.B("Melena", V3(2.8, 2.6, 1.2), V3(0, 2.35, 0.45), mane)
		S.M("MelenaLado", V3(0.6, 2.2, 1.6), V3(1.15, 2.2, -0.15), mane)
		S.B("MelenaBarba", V3(1.6, 0.8, 0.6), V3(0, 1.35, -0.75), mane)
		S.B("Cabeza", V3(1.7, 1.6, 1.6), V3(0, 2.25, -0.2), fur)
		S.B("Hocico", V3(1.0, 0.7, 0.6), V3(0, 1.9, -1.25), rgb(230, 200, 150))
		S.B("Nariz", V3(0.4, 0.25, 0.12), V3(0, 2.18, -1.58), rgb(60, 30, 26))
		S.B("Boca", V3(0.8, 0.3, 0.05), V3(0, 1.7, -1.56), rgb(70, 14, 14))
		S.M("Colmillo", V3(0.12, 0.28, 0.08), V3(0.28, 1.72, -1.6), IVORY)
		S.eyes(0.42, 2.45, -1.0, 0.28, 0.22, rgb(255, 190, 50), { glow = true, brow = mane, browAngle = 24 })
		S.M("Oreja", V3(0.22, 0.45, 0.4), V3(0.65, 3.25, -0.2), fur, { wedge = true, ry = 90 })
		S.M("Hombrera", V3(1.7, 0.75, 1.7), V3(2.05, 1.15, 0), gold, { on = arms })
		S.M("PuaHombro", V3(0.26, 0.8, 0.26), V3(2.3, 1.8, 0), gold, { rz = -35, on = arms })
		S.M("Brazal", V3(1.32, 0.7, 1.32), V3(2.05, -0.6, 0), gold, { on = arms })
		S.M("Mano", V3(1.3, 0.55, 1.3), V3(2.05, -1.15, 0), fur, { on = arms })
		for _, dx in { -0.35, 0, 0.35 } do
			S.M("Garra", V3(0.13, 0.35, 0.13), V3(2.05 + dx, -1.55, -0.5), IVORY, { on = arms })
		end
		S.M("Grebas", V3(1.35, 1.0, 1.4), V3(0.73, -2.35, -0.03), gold, { on = legs })
		local tail = S.B("Cola", V3(0.3, 0.3, 2.0), V3(0, -1.0, 1.6), fur, { rx = 30 })
		S.B("PuntaCola", V3(0.55, 0.55, 0.6), V3(0, -1.55, 2.5), mane, { on = tail })
		S.light(rgb(255, 200, 80), 14)
	end,
}

-- PANTANO MALDITO
R.InsectoGigante = { -- mantis
	Root = V3(1.4, 1.0, 2.4),
	Hip = 1.3,
	Build = function(S)
		local body, light, dark = rgb(68, 120, 48), rgb(130, 180, 72), rgb(40, 76, 30)
		S.B("Abdomen", V3(1.5, 1.0, 2.8), V3(0, 0.15, 1.3), body)
		for i = 0, 3 do
			S.B("Banda", V3(1.54, 0.12, 0.3), V3(0, 0.6, 0.3 + i * 0.6), dark)
		end
		S.M("Ala", V3(0.75, 0.1, 2.6), V3(0.42, 0.75, 1.15), rgb(170, 220, 120), { alpha = 0.45, ry = 6 })
		S.B("Torax", V3(1.0, 1.7, 1.0), V3(0, 1.0, -0.8), body, { rx = -20 })
		S.B("Cabeza", V3(1.3, 0.8, 0.8), V3(0, 2.0, -1.4), light)
		S.M("OjoGrande", V3(0.42, 0.55, 0.42), V3(0.6, 2.1, -1.45), rgb(210, 255, 80), { glow = true })
		S.M("Mandibula", V3(0.18, 0.4, 0.18), V3(0.2, 1.55, -1.75), dark, { rz = 20 })
		S.M("Antena", V3(0.07, 0.07, 1.4), V3(0.25, 2.55, -1.9), dark, { rx = 40, ry = -15 })
		local arms = S.M("Brazo", V3(0.32, 1.2, 0.32), V3(0.55, 1.35, -1.75), body, { rx = 30 })
		S.M("Guadana", V3(0.14, 1.5, 0.38), V3(0.55, 1.35, -2.45), light, { rx = -35, on = arms })
		S.M("Filo", V3(0.15, 1.3, 0.08), V3(0.55, 1.4, -2.65), rgb(230, 255, 180), { rx = -35, on = arms })
		archLegs(S, { -0.2, 0.5, 1.2 }, 0.55, 0.2, 1.4, 45, 0.9, -1.8, 0.24, body, dark, dark, 25)
	end,
}

R.CriaturaVenenosa = {
	Root = V3(2.2, 1.8, 3.4),
	Hip = 1.7,
	Build = function(S)
		beast(S, { Body = rgb(86, 40, 98), Dark = rgb(50, 22, 60), Belly = rgb(130, 76, 140), Muzzle = rgb(110, 60, 120), Eye = rgb(190, 255, 80),
			Spikes = rgb(160, 255, 80), SpikeGlow = true, Veins = rgb(160, 255, 80), Ears = rgb(70, 30, 80) })
	end,
}

R.MuertoViviente = {
	Root = V3(2.0, 2.0, 1.1),
	Hip = 1.9,
	Build = function(S)
		warrior(S, { Shirt = rgb(84, 80, 66), Pants = rgb(60, 56, 48), Sleeve = rgb(126, 146, 106), Skin = rgb(126, 146, 106), Hair = rgb(40, 40, 34),
			Eye = rgb(190, 255, 120), EyeGlow = true, Zombie = true, ArmsForward = true, Boot = rgb(50, 44, 38) })
	end,
}

R.EspirituCorrupto = { -- Espíritu maldito
	Root = V3(1.8, 1.9, 1.1),
	Hip = 2.0,
	Build = function(S)
		ghost(S, { Body = rgb(70, 140, 90), Glow = rgb(130, 255, 120), Eye = rgb(150, 255, 120), Hood = rgb(30, 40, 32), Chains = true, Alpha = 0.4 })
	end,
}

R.DevoradorPantano = {
	Root = V3(3.2, 2.8, 2.0),
	Hip = 1.5,
	Build = function(S)
		local skin, dark, glow, horn = rgb(52, 62, 50), rgb(30, 38, 28), rgb(150, 255, 80), rgb(74, 62, 50)
		local T, A = V3(3.2, 2.8, 2.0), V3(1.4, 2.9, 1.4)
		local arms, legs = biped(S, { T = T, A = A, L = V3(1.4, 1.6, 1.4), Legs = dark, Arms = skin, ArmDrop = 0.3, LegX = 0.9 })
		S.B("Tronco", T, V3(0, 0, 0), skin)
		S.B("Barriga", V3(2.4, 1.6, 0.25), V3(0, -0.4, -1.05), rgb(80, 92, 66))
		S.B("Musgo", V3(1.6, 0.6, 0.2), V3(-0.6, 1.0, -1.08), rgb(70, 110, 40))
		S.B("Cabeza", V3(2.2, 1.6, 1.8), V3(0, 1.9, -0.65), skin)
		S.B("Frente", V3(2.3, 0.4, 0.4), V3(0, 2.45, -1.4), dark)
		S.B("Fauces", V3(1.8, 0.9, 0.06), V3(0, 1.55, -1.57), glow, { glow = true })
		for i = -3, 3 do
			S.B("Diente", V3(0.14, 0.3, 0.08), V3(i * 0.26, 1.88, -1.61), IVORY)
			S.B("Diente", V3(0.14, 0.26, 0.08), V3(i * 0.26 + 0.13, 1.18, -1.61), IVORY)
		end
		S.eyes(0.62, 2.2, -1.55, 0.3, 0.22, glow, { glow = true, brow = dark, browAngle = 26 })
		S.M("Cuerno", V3(1.1, 0.5, 0.5), V3(1.4, 2.6, -0.6), horn, { rz = 15 })
		S.M("Cuerno2", V3(0.42, 1.0, 0.42), V3(1.95, 3.15, -0.6), horn, { rz = -15 })
		S.M("PuntaCuerno", V3(0.28, 0.55, 0.28), V3(1.9, 3.8, -0.6), glow, { glow = true, rz = 20 })
		for i = 0, 3 do
			S.B("Pua", V3(0.4, 0.9, 0.5), V3(0, 1.7 - i * 0.1, 0.4 + i * 0.5), dark, { rx = -30 })
		end
		for _, p in { V3(0.4, 1.1, -1.65), V3(-0.5, 1.0, -1.65), V3(1.0, 0.2, -1.12) } do
			S.B("Baba", V3(0.18, 0.6, 0.18), p, glow, { glow = true, alpha = 0.2 })
		end
		S.M("Mano", V3(1.6, 0.8, 1.6), V3(2.32, -1.55, 0), dark, { on = arms })
		for _, dx in { -0.45, 0, 0.45 } do
			S.M("Garra", V3(0.16, 0.5, 0.16), V3(2.32 + dx, -2.1, -0.6), IVORY, { on = arms })
		end
		S.M("Pie", V3(1.6, 0.45, 1.9), V3(0.9, -2.95, -0.2), dark, { on = legs })
		S.light(glow, 16)
	end,
}

-- DESIERTO DORADO
R.SerpienteDuna = {
	Root = V3(1.6, 1.4, 3.0),
	Hip = 0.4,
	Build = function(S)
		local sand, band, belly = rgb(196, 160, 96), rgb(120, 84, 48), rgb(230, 206, 150)
		for i = 0, 6 do
			local sz = 1.35 - i * 0.12
			S.B("Cuerpo", V3(sz, sz * 0.85, 1.6), V3(math.sin(i * 1.1) * 0.5, -0.15, 0.2 + i * 1.4), if i % 2 == 0 then sand else band)
		end
		S.B("Cuello", V3(0.95, 1.8, 0.95), V3(0, 0.8, -1.0), sand, { rx = -15 })
		S.B("Capucha", V3(2.1, 1.9, 0.25), V3(0, 1.45, -1.05), sand, { rx = -15 })
		S.B("Dibujo", V3(0.8, 0.8, 0.06), V3(0, 1.55, -1.21), band, { rx = -15, rz = 45 })
		S.B("PanzaCuello", V3(0.7, 1.6, 0.1), V3(0, 0.75, -1.47), belly, { rx = -15 })
		S.B("Cabeza", V3(1.15, 0.75, 1.4), V3(0, 2.35, -1.6), sand)
		S.B("Cana", V3(1.15, 0.3, 0.6), V3(0, 2.85, -1.75), band, { wedge = true })
		S.eyes(0.4, 2.5, -2.3, 0.24, 0.2, rgb(255, 200, 40), { glow = true, pupil = BLACK, brow = band })
		S.M("Colmillo", V3(0.1, 0.35, 0.1), V3(0.3, 1.9, -2.2), IVORY)
		S.B("Lengua", V3(0.1, 0.06, 0.6), V3(0, 2.05, -2.55), rgb(200, 40, 50))
	end,
}

R.SaqueadorDesierto = {
	Root = V3(2.0, 2.0, 1.1),
	Hip = 1.9,
	Build = function(S)
		warrior(S, { Shirt = rgb(176, 146, 104), Pants = rgb(120, 96, 70), Vest = rgb(96, 64, 40), Skin = rgb(170, 120, 84), Turban = rgb(196, 176, 140),
			Mask = rgb(150, 50, 36), Eye = rgb(90, 70, 50), Brow = rgb(30, 22, 18), Weapon = "Cimitarra", Belt = rgb(110, 30, 26) })
	end,
}

R.ColosoArena = {
	Root = V3(3.0, 2.6, 1.8),
	Hip = 1.5,
	Build = function(S)
		golem(S, { Main = rgb(196, 152, 66), Dark = rgb(140, 100, 40), Light = rgb(228, 188, 100), Glow = rgb(255, 210, 70), Crown = rgb(110, 76, 30), Horns = rgb(110, 76, 30) })
	end,
}

-- RUINAS ANTIGUAS
R.CaballeroEspectral = {
	Root = V3(2.2, 2.2, 1.3),
	Hip = 1.9,
	Build = function(S)
		warrior(S, { T = V3(2.2, 2.2, 1.3), A = V3(1.0, 2.1, 1.0), L = V3(1.0, 2.0, 1.0), Shirt = rgb(90, 140, 200), Pants = rgb(70, 110, 170),
			Armor = rgb(120, 170, 220), Armor2 = rgb(70, 110, 160), Helm = rgb(110, 160, 215), Eye = rgb(170, 230, 255), Glow = rgb(140, 210, 255),
			Weapon = "Espada", Blade = rgb(170, 220, 255), BladeLen = 2.4, BladeGlow = rgb(140, 210, 255), Alpha = 0.35, Cape = rgb(60, 90, 140) })
	end,
}

R.MagoAntiguo = {
	Root = V3(1.8, 2.0, 1.1),
	Hip = 1.8,
	Build = function(S)
		robed(S, { Robe = rgb(104, 66, 38), Dark = rgb(60, 38, 22), Trim = rgb(196, 170, 100), Belt = rgb(70, 46, 28), Eye = rgb(140, 210, 255), Hand = rgb(210, 180, 150),
			Beard = rgb(220, 220, 214), Gem = rgb(120, 200, 255), Orb = rgb(120, 200, 255) })
	end,
}

R.ArqueroEspectral = {
	Root = V3(2.0, 2.0, 1.1),
	Hip = 1.9,
	Build = function(S)
		warrior(S, { Shirt = rgb(90, 130, 170), Pants = rgb(70, 100, 140), Skin = rgb(150, 200, 235), Hood = rgb(60, 90, 130), Eye = rgb(170, 230, 255), EyeGlow = true,
			Glow = rgb(140, 210, 255), Weapon = "Arco", BowColor = rgb(140, 210, 255), BowGlow = true, Alpha = 0.35, Belt = rgb(50, 70, 100), Boot = rgb(50, 70, 100) })
	end,
}

R.ReyRuinas = {
	Root = V3(2.4, 2.4, 1.4),
	Hip = 2.0,
	Build = function(S)
		warrior(S, { T = V3(2.4, 2.4, 1.4), A = V3(1.1, 2.3, 1.1), L = V3(1.1, 2.1, 1.1), H = V3(1.6, 1.7, 1.6), Shirt = rgb(60, 66, 84), Pants = rgb(50, 54, 70),
			Armor = rgb(90, 100, 124), Armor2 = rgb(56, 62, 80), Helm = rgb(84, 94, 118), Eye = rgb(130, 200, 255), Glow = rgb(120, 190, 255), Spikes = rgb(56, 62, 80),
			Crown = rgb(214, 176, 70), Cape = rgb(40, 52, 110), Weapon = "Espada", Blade = rgb(150, 200, 255), BladeLen = 3.0, BladeGlow = rgb(120, 190, 255) })
		S.light(rgb(120, 190, 255), 14)
	end,
}

-- MONTAÑAS HELADAS
R.GolemEscarcha = { -- Gólem de hielo
	Root = V3(3.0, 2.6, 1.8),
	Hip = 1.5,
	Build = function(S)
		golem(S, { Main = rgb(140, 182, 214), Dark = rgb(92, 130, 170), Light = rgb(196, 222, 242), Glow = rgb(150, 235, 255), Ice = true })
	end,
}

R.EspectroGlacial = {
	Root = V3(1.8, 1.9, 1.1),
	Hip = 2.0,
	Build = function(S)
		ghost(S, { Body = rgb(160, 210, 245), Glow = rgb(170, 240, 255), Eye = rgb(200, 250, 255), Ice = true, Alpha = 0.35 })
	end,
}

R.DragonInvierno = {
	Root = V3(2.0, 1.8, 3.4),
	Hip = 1.6,
	Build = function(S)
		dragon(S, { Body = rgb(70, 120, 186), Belly = rgb(176, 210, 240), Spike = rgb(210, 240, 255), Dark = rgb(36, 60, 110), Eye = rgb(170, 245, 255),
			Wing = rgb(120, 180, 240), WingAlpha = 0.1, Icy = true, WingScale = 1.8 })
		S.light(rgb(150, 220, 255), 16)
	end,
}

-- TIERRAS OSCURAS
R.BestiaSombria = {
	Root = V3(2.2, 1.8, 3.4),
	Hip = 1.7,
	Build = function(S)
		beast(S, { Body = rgb(34, 30, 44), Dark = rgb(18, 16, 24), Belly = rgb(60, 52, 76), Muzzle = rgb(48, 42, 60), Eye = rgb(200, 110, 255),
			Spikes = rgb(150, 80, 230), SpikeGlow = true, Ears = rgb(24, 20, 30), Wisps = rgb(170, 90, 255) })
	end,
}

R.CriaturaVacio = { -- Espectro del vacío
	Root = V3(1.8, 1.9, 1.1),
	Hip = 2.0,
	Build = function(S)
		ghost(S, { Body = rgb(40, 24, 66), Glow = rgb(170, 90, 255), Eye = rgb(220, 160, 255), Hood = rgb(20, 14, 30), Horns = rgb(30, 20, 40), Alpha = 0.3 })
	end,
}

R.SenorSombras = {
	Root = V3(2.4, 2.4, 1.4),
	Hip = 2.0,
	Build = function(S)
		warrior(S, { T = V3(2.4, 2.4, 1.4), A = V3(1.1, 2.3, 1.1), L = V3(1.1, 2.1, 1.1), H = V3(1.6, 1.7, 1.6), Shirt = rgb(30, 26, 38), Pants = rgb(24, 20, 30),
			Armor = rgb(40, 34, 52), Armor2 = rgb(20, 18, 26), Helm = rgb(34, 30, 44), Eye = rgb(200, 100, 255), Glow = rgb(190, 80, 255), Spikes = rgb(70, 50, 90),
			HelmHorns = rgb(24, 20, 30), Cape = rgb(44, 16, 60), Weapon = "Espada", Blade = rgb(40, 36, 50), BladeLen = 3.2, BladeGlow = rgb(190, 80, 255) })
		local e = Instance.new("ParticleEmitter")
		e.Name = "Sombra"
		e.Color = ColorSequence.new(rgb(30, 0, 50), rgb(170, 90, 255))
		e.Transparency = NumberSequence.new(0.4, 1)
		e.Size = NumberSequence.new(1, 2.2)
		e.Lifetime = NumberRange.new(0.8, 1.4)
		e.Rate = 8
		e.Speed = NumberRange.new(0.5, 1.5)
		e.Parent = S.B("Humo", V3(0.2, 0.2, 0.2), V3(0, 0, 0), rgb(170, 90, 255), { alpha = 1 })
		S.light(rgb(190, 80, 255), 16)
	end,
}

-- TIERRAS VOLCÁNICAS
R.DemonioFuego = {
	Root = V3(2.6, 2.4, 1.4),
	Hip = 1.9,
	Build = function(S)
		demon(S, { Skin = rgb(186, 66, 28), Dark = rgb(96, 28, 14), Horn = rgb(30, 22, 20), Pec = rgb(206, 90, 40), Abs = rgb(150, 46, 20), Glow = rgb(255, 160, 40), Fire = true })
	end,
}

R.DemonioSupremo = {
	Root = V3(2.6, 2.4, 1.4),
	Hip = 1.9,
	Build = function(S)
		demon(S, { Skin = rgb(106, 20, 24), Dark = rgb(48, 10, 14), Horn = rgb(24, 18, 18), Pec = rgb(126, 30, 32), Abs = rgb(84, 14, 18), Glow = rgb(255, 110, 30),
			Armor = rgb(36, 30, 32), Wings = true, Wing = rgb(90, 16, 20) })
		S.light(rgb(255, 110, 30), 12)
	end,
}

R.TitanVolcan = {
	Root = V3(3.0, 2.6, 1.8),
	Hip = 1.5,
	Build = function(S)
		golem(S, { Main = rgb(46, 36, 32), Dark = rgb(26, 20, 18), Light = rgb(70, 52, 44), Glow = rgb(255, 100, 20), Cracks = true, Horns = rgb(24, 18, 16), Flames = true, MouthGlow = true })
	end,
}

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------
BeastSculpt.Recipes = R

function BeastSculpt.frame(id: string): { Root: Vector3, Hip: number }?
	local r = R[id]
	if not r then
		return nil
	end
	return { Root = r.Root, Hip = r.Hip }
end

function BeastSculpt.build(x: Ctx, id: string)
	local r = R[id]
	if r then
		r.Build(tools(x))
	end
end

return BeastSculpt
