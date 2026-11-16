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
	if c.Crown then
		S.B("Tocado", V3(1.8, 0.3, 1.6), V3(0, 2.5, -0.35), c.Crown)
		S.M("TocadoLado", V3(0.25, 1.2, 1.2), V3(0.9, 1.8, -0.2), c.Crown)
		S.B("Joya", V3(0.35, 0.35, 0.08), V3(0, 2.15, -1.22), c.Glow, { glow = true })
		S.B("Emblema", V3(0.6, 0.6, 0.08), V3(0, 0.55, -1.13), c.Glow, { glow = true, rz = 45 })
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

R.Demonio = {
	Root = V3(2.6, 2.4, 1.4),
	Hip = 1.9,
	Build = function(S)
		local skin, dark, horn = rgb(150, 34, 32), rgb(90, 18, 22), rgb(44, 28, 28)
		local T, A = V3(2.6, 2.4, 1.4), V3(1.15, 2.4, 1.15)
		local arms, legs = biped(S, { T = T, A = A, L = V3(1.15, 2.0, 1.15), Legs = dark, Arms = skin })
		S.B("Tronco", T, V3(0, 0, 0), skin)
		S.M("Pectoral", V3(1.05, 0.7, 0.1), V3(0.6, 0.55, -0.72), rgb(214, 66, 60))
		S.B("Abdomen", V3(0.95, 1.0, 0.08), V3(0, -0.35, -0.71), rgb(176, 36, 40))
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
