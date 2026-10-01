-- GranjaJulian: la granja de Julián en Villaverde (la «Granja escuela»), donde pasa «La gallina de
-- seis metros» (Loco_N3_Pollo), la excursión del cole (Cole07_Excursion) y la visita a Petra de la
-- Saga de la Grieta (Saga_19_Recuerdos). Las demás granjas de Villaverde son las de siempre
-- (Civic.farm); esta es la única con el atributo Julian = true, y la historia solo usa esta.
--
-- Lo que hay (en un lote de 200 × 96 de Villaverde, con la calle al oeste):
--   * GRANERO grande en el que se entra: 56 de ancho × 44 de fondo, paredes de 30 y tejado a dos
--     aguas quebrado (estilo holandés) hasta 46 de alto. El portón está abierto de par en par (26 de
--     ancho × 25,6 de alto: cabe Petra, que mide unos 20) y mira al patio. Dentro: heno por el suelo,
--     pacas apiladas, comederos con grano, un pajar con escalera (se trepa), vigas, dos faroles y luz
--     que entra en rayos por las rendijas entre los tablones. Al fondo, el nido de paja de Petra
--     (StorySpot Granja_Nido, donde la misión pone los huevos gigantes) y junto a los comederos el
--     sitio donde come Petra (StorySpot Granja_Comedero).
--   * Patio de tierra delante del portón (StorySpot Granja_Patio: allí te deja la furgoneta de Cosme),
--     silo (Model "Silo", alto, con su escalerilla), gallinero con su corral y dos gallinas de verdad
--     (de código, picotean), sacos de pienso, carretilla con heno, tractor, abrevadero, valla con
--     portón de entrada y cartel.
--   * Los bancales siguen al otro lado del patio (las fincas de FarmService).
-- Rendimiento: lo grande hace sombra; los adornos no chocan ni proyectan sombra.

local Builder = require(script.Parent.Parent.Builder)
local Nature = require(script.Parent.Nature)
local StoryMarks = require(script.Parent.StoryMarks)
local GallinaGigante = require(script.Parent.GallinaGigante)

local GranjaJulian = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local C = CFrame.new
local rad = math.rad

local ROJO = rgb(163, 46, 40)
local ROJO_OSCURO = rgb(126, 34, 30)
local BLANCO = rgb(240, 236, 226)
local TEJADO = rgb(84, 78, 76)
local MADERA = rgb(150, 108, 66)
local MADERA_OSCURA = rgb(104, 74, 48)
local HENO = rgb(224, 190, 104)
local HENO_OSCURO = rgb(196, 160, 80)
local TIERRA = rgb(150, 118, 84)
local LUZ = rgb(255, 236, 180)

-- Medidas del granero (en sus ejes: X a lo ancho, Z hacia el fondo; el portón en Z = -FONDO/2)
GranjaJulian.Granero = {
	Ancho = 56,
	Fondo = 44,
	Pared = 30,
	Cumbrera = 46,
	Puerta = { Ancho = 26, Alto = 25.6 },
	Nido = V(14, 0, 0), -- centro del nido (en los ejes del granero)
	Comedero = V(-15, 0, -5), -- donde come Petra
}

-- Dónde está todo en el lote (u a lo largo de la calle, v hacia dentro desde la acera)
local GRANERO_U, GRANERO_V = -60, 48
local SILO_U, SILO_V = -24, 84
GranjaJulian.CultivosDesde = 24 -- los bancales empiezan aquí (u)

local function part(props: { [string]: any }): BasePart
	return Builder.part(props)
end

local function decor(props: { [string]: any }): BasePart
	return Builder.decor(props)
end

-- Mirar de pos hacia target (sin CFrame.lookAt: en Lune falla hacia +Z, ver Builder.facing)
local function lookAt(pos: Vector3, target: Vector3): CFrame
	local look = (target - pos).Unit
	local up = if math.abs(look.Y) > 0.99 then V(0, 0, 1) else V(0, 1, 0)
	local right = look:Cross(up).Unit
	return CFrame.fromMatrix(pos, right, right:Cross(look), -look)
end

-- Una pieza que va de a a b (en el mismo marco), con grosor t y ancho w (w a lo largo de "side")
local function beam(parent: Instance, frame: CFrame, a: Vector3, b: Vector3, t: number, color: Color3, material: Enum.Material?, name: string?, solid: boolean?): BasePart
	local mid = (a + b) / 2
	local dir = b - a
	local len = dir.Magnitude
	local cf = frame * lookAt(mid, b)
	local props = { Name = name or "Viga", Size = V(t, t, len), CFrame = cf, Color = color, Material = material or Enum.Material.Wood, Parent = parent }
	return if solid then part(props) else decor(props)
end

---------------------------------------------------------------------
-- El granero
---------------------------------------------------------------------
local function barn(parent: Instance, B: CFrame): Model
	local G = GranjaJulian.Granero
	local m = Builder.model("Granero", parent)
	local W, D, H = G.Ancho, G.Fondo, G.Pared
	local hw, hd = W / 2, D / 2
	local doorW, doorH = G.Puerta.Ancho, G.Puerta.Alto

	-- Suelo de tablones (y su orientación es la del granero: así la historia sabe dónde es "delante")
	local floor = part({ Name = "Suelo", Size = V(W, 0.4, D), CFrame = B * C(0, 0.2, 0), Color = rgb(138, 102, 68), Material = Enum.Material.WoodPlanks, Parent = m })
	m.PrimaryPart = floor
	-- Paja por el suelo
	for i, p in { { -8, -12, 9, 7 }, { 4, -4, 10, 8 }, { -18, 8, 8, 10 }, { 20, -14, 7, 6 }, { -4, 12, 12, 6 }, { 18, 14, 8, 8 } } do
		decor({ Name = "Paja", Size = V(p[3], 0.08, p[4]), CFrame = B * C(p[1], 0.44, p[2]) * CFrame.Angles(0, rad(i * 23), 0), Color = if i % 2 == 0 then HENO else HENO_OSCURO, Material = Enum.Material.Grass, Parent = m })
	end

	-- Paredes de tablones con rendijas (por las rendijas entra la luz): 5 franjas de 5,6 con 0,4 de hueco
	local function wall(x0: number, x1: number, z: number, along: string, y0: number?, y1: number?)
		for i = 0, 4 do
			local b0, b1 = math.max(i * 6, y0 or 0), math.min(i * 6 + 5.6, y1 or H)
			if b1 > b0 then
				local len = math.abs(x1 - x0)
				local mid = (x0 + x1) / 2
				local size = if along == "X" then V(len, b1 - b0, 1) else V(1, b1 - b0, len)
				local pos = if along == "X" then V(mid, (b0 + b1) / 2, z) else V(z, (b0 + b1) / 2, mid)
				part({ Name = "Pared", Size = size, CFrame = B * C(pos), Color = if i % 2 == 0 then ROJO else rgb(156, 42, 37), Material = Enum.Material.WoodPlanks, Parent = m })
			end
		end
	end
	wall(-hd, hd, -hw + 0.5, "Z") -- izquierda
	wall(-hd, hd, hw - 0.5, "Z") -- derecha
	wall(-hw + 1, hw - 1, hd - 0.5, "X") -- fondo
	-- Fachada: dos paños a los lados del portón y el dintel encima
	wall(-hw + 1, -doorW / 2, -hd + 0.5, "X")
	wall(doorW / 2, hw - 1, -hd + 0.5, "X")
	part({ Name = "Dintel", Size = V(doorW, H - doorH, 1), CFrame = B * C(0, (doorH + H) / 2, -hd + 0.5), Color = ROJO, Material = Enum.Material.WoodPlanks, Parent = m })

	-- Hastiales (el triángulo quebrado de delante y de detrás, por encima de las paredes)
	local knee = 18
	local kneeY = H + 10
	local top = G.Cumbrera
	for _, z in { -hd + 0.5, hd - 0.5 } do
		part({ Name = "Hastial", Size = V(knee * 2, kneeY - H, 1), CFrame = B * C(0, (H + kneeY) / 2, z), Color = ROJO, Material = Enum.Material.WoodPlanks, Parent = m })
		for _, s in { -1, 1 } do
			-- (cuña: el lado alto hacia dentro)
			part({ ClassName = "WedgePart", Name = "Hastial", Size = V(1, kneeY - H, hw - knee), CFrame = B * C(s * (knee + hw) / 2, (H + kneeY) / 2, z) * CFrame.Angles(0, rad(-90 * s), 0), Color = ROJO, Material = Enum.Material.WoodPlanks, Parent = m })
			part({ ClassName = "WedgePart", Name = "Hastial", Size = V(1, top - kneeY, knee), CFrame = B * C(s * knee / 2, (kneeY + top) / 2, z) * CFrame.Angles(0, rad(-90 * s), 0), Color = ROJO, Material = Enum.Material.WoodPlanks, Parent = m })
		end
	end
	-- Ventanuco del pajar y ojo de buey en la fachada
	decor({ Name = "Ventanuco", Size = V(8, 7, 0.2), CFrame = B * C(0, H + 5.5, -hd - 0.05), Color = rgb(52, 36, 28), Material = Enum.Material.WoodPlanks, Parent = m })
	for _, t in { { 8.8, 0.6, 0, H + 9.2 }, { 8.8, 0.6, 0, H + 1.8 }, { 0.6, 7.4, -4.1, H + 5.5 }, { 0.6, 7.4, 4.1, H + 5.5 } } do
		decor({ Name = "Marco", Size = V(t[1], t[2], 0.3), CFrame = B * C(t[3], t[4], -hd - 0.15), Color = BLANCO, Parent = m })
	end
	decor({ Name = "OjoDeBuey", Shape = Enum.PartType.Cylinder, Size = V(0.3, 3.4, 3.4), CFrame = B * C(0, top - 3.4, -hd - 0.1) * CFrame.Angles(0, rad(90), 0), Color = BLANCO, Parent = m })
	decor({ Name = "OjoDeBuey", Shape = Enum.PartType.Cylinder, Size = V(0.32, 2.6, 2.6), CFrame = B * C(0, top - 3.4, -hd - 0.12) * CFrame.Angles(0, rad(90), 0), Color = rgb(40, 34, 30), Parent = m })
	-- Cartel sobre el portón
	local sign = decor({ Name = "Cartel", Size = V(20, 2.8, 0.4), CFrame = B * C(0, (doorH + H) / 2, -hd - 0.3), Color = BLANCO, Parent = m })
	Builder.sign(sign, "GRANJA ESCUELA · VILLAVERDE", Enum.NormalId.Front, ROJO_OSCURO)

	-- Esquinas y marco del portón en blanco
	for _, x in { -hw, hw } do
		for _, z in { -hd, hd } do
			decor({ Name = "Esquina", Size = V(1.4, H, 1.4), CFrame = B * C(x, H / 2, z), Color = BLANCO, Material = Enum.Material.WoodPlanks, Parent = m })
		end
	end
	for _, x in { -doorW / 2 - 0.5, doorW / 2 + 0.5 } do
		decor({ Name = "MarcoPorton", Size = V(1, doorH, 1.4), CFrame = B * C(x, doorH / 2, -hd - 0.1), Color = BLANCO, Parent = m })
	end
	decor({ Name = "MarcoPorton", Size = V(doorW + 2, 1, 1.4), CFrame = B * C(0, doorH + 0.5, -hd - 0.1), Color = BLANCO, Parent = m })

	-- Tejado quebrado (cuatro faldones de pizarra) y cumbrera
	for _, s in { -1, 1 } do
		-- Faldón de abajo: del alero (con vuelo) a la rodilla
		local outer = V(s * (hw + 1.2), H - 1.2, 0)
		local inner = V(s * knee, kneeY, 0)
		local mid = (outer + inner) / 2
		local len = (inner - outer).Magnitude
		local normal = V(s * 0.7071, 0.7071, 0)
		part({ Name = "Tejado", Size = V(len, 0.8, D + 2.4), CFrame = B * C(mid + normal * 0.4) * CFrame.Angles(0, 0, rad(-45 * s)), Color = TEJADO, Material = Enum.Material.Slate, Parent = m })
		-- Faldón de arriba: de la rodilla a la cumbrera
		local a2 = V(s * knee, kneeY, 0)
		local b2 = V(0, top, 0)
		local slope = math.deg(math.atan2(top - kneeY, knee))
		local n2 = V(s * math.sin(rad(slope)), math.cos(rad(slope)), 0)
		part({ Name = "Tejado", Size = V((b2 - a2).Magnitude + 0.6, 0.8, D + 2.4), CFrame = B * C((a2 + b2) / 2 + n2 * 0.4) * CFrame.Angles(0, 0, rad(-slope * s)), Color = TEJADO, Material = Enum.Material.Slate, Parent = m })
		-- Remates blancos de los aleros de la fachada
		beam(m, B, V(s * (hw + 1.2), H - 1.0, -hd - 1.3), V(s * knee, kneeY + 0.3, -hd - 1.3), 0.6, BLANCO, Enum.Material.SmoothPlastic, "Remate")
		beam(m, B, V(s * knee, kneeY + 0.3, -hd - 1.3), V(0, top + 0.3, -hd - 1.3), 0.6, BLANCO, Enum.Material.SmoothPlastic, "Remate")
	end
	part({ Name = "Cumbrera", Size = V(1.4, 0.7, D + 2.6), CFrame = B * C(0, top + 0.55, 0), Color = rgb(64, 58, 56), Material = Enum.Material.Slate, Parent = m })
	-- Veleta
	decor({ Name = "Veleta", Size = V(0.3, 4, 0.3), CFrame = B * C(0, top + 2.8, -hd + 4), Color = rgb(40, 40, 44), Material = Enum.Material.Metal, Parent = m })
	decor({ Name = "Veleta", Size = V(0.2, 0.5, 3.2), CFrame = B * C(0, top + 4.2, -hd + 4) * CFrame.Angles(0, rad(30), 0), Color = rgb(40, 40, 44), Material = Enum.Material.Metal, Parent = m })

	-- Portón abierto de par en par: dos hojas rojas con la cruz blanca, giradas hacia fuera
	for _, s in { -1, 1 } do
		local hinge = V(s * doorW / 2, 0, -hd - 0.4)
		local dir = V(s * 0.34, 0, -0.94).Unit
		local center = hinge + dir * (doorW / 4) + V(0, doorH / 2 + 0.2, 0)
		local leafCf = B * CFrame.fromMatrix(center, dir, V(0, 1, 0))
		part({ Name = "HojaPorton", Size = V(doorW / 2, doorH - 0.4, 0.6), CFrame = leafCf, Color = ROJO, Material = Enum.Material.WoodPlanks, Parent = m })
		local lw, lh = doorW / 2, doorH - 0.4
		local diag = math.sqrt(lw * lw + lh * lh)
		local ang = math.atan2(lh, lw)
		for _, side in { -1, 1 } do
			for _, a in { ang, -ang } do
				decor({ Name = "Cruz", Size = V(diag - 1, 0.7, 0.2), CFrame = leafCf * C(0, 0, side * 0.4) * CFrame.Angles(0, 0, a), Color = BLANCO, Parent = m })
			end
		end
		for _, t in { { lw, 0.8, 0, lh / 2 - 0.4 }, { lw, 0.8, 0, -lh / 2 + 0.4 }, { 0.8, lh, lw / 2 - 0.4, 0 }, { 0.8, lh, -lw / 2 + 0.4, 0 } } do
			decor({ Name = "MarcoHoja", Size = V(t[1], t[2], 0.8), CFrame = leafCf * C(t[3], t[4], 0), Color = BLANCO, Parent = m })
		end
	end

	-- Dentro: tirantes y vigas (por encima de Petra), jabalcones en las paredes
	for _, z in { -16, -6, 4, 14 } do
		decor({ Name = "Tirante", Size = V(W - 2, 1.2, 1.2), CFrame = B * C(0, H - 0.6, z), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = m })
		decor({ Name = "Puente", Size = V(knee * 2, 1, 1), CFrame = B * C(0, kneeY - 0.8, z), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = m })
		for _, s in { -1, 1 } do
			beam(m, B, V(s * (hw - 1.2), H - 7, z), V(s * (hw - 7), H - 1.2, z), 0.8, MADERA_OSCURA, Enum.Material.Wood, "Jabalcon")
		end
	end
	decor({ Name = "Hilera", Size = V(1, 1, D - 2), CFrame = B * C(0, top - 1.4, 0), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = m })

	-- Pajar al fondo (a 14 de alto: por debajo pasa la gente, no Petra) con barandilla y escalera
	local loftZ0, loftZ1, loftY = 12, hd - 1, 14
	part({ Name = "Pajar", Size = V(W - 2, 0.8, loftZ1 - loftZ0), CFrame = B * C(0, loftY - 0.4, (loftZ0 + loftZ1) / 2), Color = MADERA, Material = Enum.Material.WoodPlanks, Parent = m })
	for _, x in { -18, -6, 6, 18 } do
		part({ Name = "PostePajar", Size = V(1, loftY - 0.8, 1), CFrame = B * C(x, (loftY - 0.8) / 2 + 0.4, loftZ0 + 0.5), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = m })
	end
	part({ Name = "Barandilla", Size = V(W - 8, 0.4, 0.4), CFrame = B * C(3, loftY + 3, loftZ0 + 0.3), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = m })
	for _, x in { -21, -9, 3, 15, 27 - 1.5 } do
		decor({ Name = "Balaustre", Size = V(0.4, 3, 0.4), CFrame = B * C(x, loftY + 1.5, loftZ0 + 0.3), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = m })
	end
	part({ ClassName = "TrussPart", Name = "Escalera", Size = V(2, loftY + 2, 2), CFrame = B * C(-24.5, (loftY + 2) / 2 + 0.4, loftZ0 - 1.2), Color = MADERA, Material = Enum.Material.Wood, Parent = m })

	-- Pacas de heno (se puede subir a ellas)
	local function bale(cf: CFrame, i: number)
		part({ Name = "Paca", Size = V(5, 2.6, 2.8), CFrame = cf, Color = if i % 2 == 0 then HENO else HENO_OSCURO, Material = Enum.Material.Grass, Parent = m })
	end
	local n = 0
	for _, p in {
		-- (x, fila de altura, z, giro)
		{ 22, 0, -18, 0 }, { 22, 0, -14.8, 0 }, { 22, 0, -11.6, 0 }, { 22, 1, -16.4, 0 }, { 22, 1, -13.2, 0 }, { 22, 2, -14.8, 0 },
		{ -22, 0, -18.5, 90 }, { -16.5, 0, -18.5, 90 }, { -19, 1, -18.5, 90 },
		{ -20, 0, 18, 0 }, { -14, 0, 18, 0 }, { -17, 1, 18, 0 },
	} do
		n += 1
		local y = if p[2] < 1 then 1.7 else 1.7 + p[2] * 2.6
		bale(B * C(p[1], y, p[3]) * CFrame.Angles(0, rad(p[4]), 0), n)
	end
	-- Encima del pajar
	for _, p in { { -10, 0, 16 }, { -4.5, 0, 16 }, { 1, 0, 16 }, { -7, 1, 16 }, { 12, 0, 18 }, { 17.5, 0, 18 } } do
		n += 1
		bale(B * C(p[1], loftY + 1.3 + p[2] * 2.6, p[3]), n)
	end
	for i, p in { { 22, 17, 7 }, { 6, 18, 5 } } do
		decor({ Name = "Monton", Shape = Enum.PartType.Ball, Size = V(p[3], p[3], p[3]), CFrame = B * C(p[1], loftY - p[3] * 0.2, p[2]), Color = if i == 1 then HENO else HENO_OSCURO, Material = Enum.Material.Grass, Parent = m })
	end

	-- Comederos con grano junto a la pared izquierda (ahí come Petra)
	for _, z in { -10, -1 } do
		part({ Name = "Comedero", Size = V(2.8, 1.8, 8), CFrame = B * C(-hw + 3, 1.3, z), Color = MADERA, Material = Enum.Material.WoodPlanks, Parent = m })
		decor({ Name = "Grano", Size = V(2.1, 0.2, 7.4), CFrame = B * C(-hw + 3, 2.25, z), Color = rgb(226, 182, 70), Material = Enum.Material.Sand, Parent = m })
	end
	decor({ Name = "Cubo", Shape = Enum.PartType.Cylinder, Size = V(2, 1.8, 1.8), CFrame = B * C(-hw + 3, 1.4, 5) * CFrame.Angles(0, 0, rad(90)), Color = rgb(150, 156, 164), Material = Enum.Material.Metal, Parent = m })
	-- Horca apoyada en la pared
	beam(m, B, V(hw - 1.6, 0.5, 4), V(hw - 2.4, 8, 6), 0.3, rgb(170, 130, 80), Enum.Material.Wood, "Horca")
	decor({ Name = "Horca", Size = V(1.4, 1.6, 0.15), CFrame = B * C(hw - 1.5, 8.6, 6.1) * CFrame.Angles(rad(-15), 0, 0), Color = rgb(120, 124, 130), Material = Enum.Material.Metal, Parent = m })

	-- Nido de paja de Petra (blando: se puede pisar)
	local nest = B * C(G.Nido)
	decor({ Name = "Nido", Shape = Enum.PartType.Cylinder, Size = V(0.6, 17, 17), CFrame = nest * C(0, 0.6, 0) * CFrame.Angles(0, 0, rad(90)), Color = HENO_OSCURO, Material = Enum.Material.Grass, Parent = m })
	for i = 0, 9 do
		local a = i * math.pi * 2 / 10
		decor({ Name = "Nido", Shape = Enum.PartType.Cylinder, Size = V(5.6, 2.6, 2.6), CFrame = nest * C(math.cos(a) * 8, 1.5, math.sin(a) * 8) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, rad(90), rad(8)), Color = if i % 2 == 0 then HENO else HENO_OSCURO, Material = Enum.Material.Grass, Parent = m })
	end
	for i = 1, 6 do
		local a = i * 1.7
		decor({ Name = "Brizna", Size = V(0.2, 0.2, 3.5), CFrame = nest * C(math.cos(a) * (10 + i % 3), 0.5, math.sin(a) * (10 + i % 3)) * CFrame.Angles(0, a * 2, 0), Color = HENO, Parent = m })
	end

	-- Faroles colgados de los tirantes (luz cálida, sin sombras: se nota poco y cuesta)
	for _, z in { -6, 14 } do
		decor({ Name = "Cadena", Size = V(0.15, 5, 0.15), CFrame = B * C(0, H - 3.7, z), Color = rgb(40, 40, 40), Material = Enum.Material.Metal, Parent = m })
		local lamp = decor({ Name = "Farol", Size = V(1.2, 1.6, 1.2), CFrame = B * C(0, H - 7, z), Color = rgb(255, 196, 110), Material = Enum.Material.Neon, Parent = m })
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 210, 150)
		light.Range = 30
		light.Brightness = 1.3
		light.Shadows = false
		light.Parent = lamp
	end

	-- Rayos de luz que entran por las rendijas de la pared derecha (y su mancha en el suelo)
	for i, z in { -14, -4, 6 } do
		local from = V(hw - 1, 18 + (i % 2) * 6, z)
		local to = V(hw - 18 - i * 2, 0.45, z + 3)
		local shaft = beam(m, B, from, to, 1, LUZ, Enum.Material.SmoothPlastic, "RayoDeLuz")
		shaft.Size = V(2.6, 0.5, shaft.Size.Z)
		shaft.Transparency = 0.9
		shaft.CastShadow = false
		decor({ Name = "ManchaDeLuz", Size = V(3, 0.06, 3), CFrame = B * C(to.X, 0.44, to.Z), Color = LUZ, Transparency = 0.6, CastShadow = false, Parent = m })
	end
	-- Polvo flotando en la luz
	local air = decor({ Name = "Polvo", Size = V(W - 8, 16, D - 8), CFrame = B * C(0, 12, 0), Transparency = 1, CastShadow = false, Parent = m })
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Polvo"
	dust.Color = ColorSequence.new(LUZ)
	dust.LightEmission = 0.5
	dust.Size = NumberSequence.new(0.12)
	dust.Transparency = NumberSequence.new(0.5, 1)
	dust.Lifetime = NumberRange.new(6, 10)
	dust.Rate = 5
	dust.Speed = NumberRange.new(0.2, 0.5)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Parent = air

	-- Marcas de la historia: el nido, donde come Petra (mira a los comederos) y el patio (mira al portón)
	StoryMarks.spot(m, "Granja_Nido", B * C(G.Nido + V(0, 2.9, 0)))
	StoryMarks.spot(m, "Granja_Comedero", B * C(G.Comedero + V(0, 2.9, 0)) * CFrame.Angles(0, rad(90), 0))
	return m
end

---------------------------------------------------------------------
-- Silo (alto, con escalerilla y tejadillo)
---------------------------------------------------------------------
local function silo(parent: Instance, S: CFrame): Model
	local m = Builder.model("Silo", parent)
	local base = part({ Name = "SiloBase", Size = V(11, 0.6, 11), CFrame = S * C(0, 0.3, 0), Color = rgb(170, 168, 160), Material = Enum.Material.Concrete, Parent = m })
	m.PrimaryPart = base
	part({ Name = "SiloCuerpo", Shape = Enum.PartType.Cylinder, Size = V(34, 10, 10), CFrame = S * C(0, 17.6, 0) * CFrame.Angles(0, 0, rad(90)), Color = rgb(206, 208, 212), Material = Enum.Material.Metal, Parent = m })
	for _, y in { 6, 13, 20, 27 } do
		decor({ Name = "Aro", Shape = Enum.PartType.Cylinder, Size = V(0.5, 10.3, 10.3), CFrame = S * C(0, y, 0) * CFrame.Angles(0, 0, rad(90)), Color = rgb(150, 154, 160), Material = Enum.Material.Metal, Parent = m })
	end
	part({ Name = "SiloTecho", Shape = Enum.PartType.Ball, Size = V(10.4, 10.4, 10.4), CFrame = S * C(0, 34.6, 0), Color = ROJO, Material = Enum.Material.Metal, Parent = m })
	part({ ClassName = "TrussPart", Name = "SiloEscalerilla", Size = V(1, 30, 1), CFrame = S * C(0, 15.6, -5.6), Color = rgb(120, 124, 130), Material = Enum.Material.Metal, Parent = m })
	return m
end

---------------------------------------------------------------------
-- Gallinero, tractor, carretilla y demás
---------------------------------------------------------------------
local function henhouse(parent: Instance, H: CFrame)
	local m = Builder.model("Gallinero", parent)
	part({ Name = "Caseta", Size = V(8, 5, 6), CFrame = H * C(0, 3.1, 0), Color = rgb(196, 150, 96), Material = Enum.Material.WoodPlanks, Parent = m })
	for _, s in { -1, 1 } do
		part({ Name = "Tejadillo", Size = V(9, 0.4, 4.4), CFrame = H * C(0, 6.6, s * 1.7) * CFrame.Angles(rad(28 * s), 0, 0), Color = ROJO_OSCURO, Material = Enum.Material.WoodPlanks, Parent = m })
	end
	decor({ Name = "Patas", Size = V(7.6, 0.6, 5.6), CFrame = H * C(0, 0.3, 0), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = m })
	decor({ Name = "Trampilla", Size = V(1.6, 1.8, 0.2), CFrame = H * C(-2, 2, -3.05), Color = rgb(52, 36, 28), Parent = m })
	beam(m, H, V(-2, 1.1, -3.1), V(-2, 0, -6.5), 0.2, MADERA, Enum.Material.WoodPlanks, "Rampa").Size = V(1.6, 0.2, 3.6)
	-- Corral de alambre (postes y dos hilos)
	local corners = { V(-7, 0, -4), V(7, 0, -4), V(7, 0, -12), V(-7, 0, -12) }
	for i, a in corners do
		decor({ Name = "Poste", Size = V(0.3, 3.4, 0.3), CFrame = H * C(a + V(0, 1.7, 0)), Color = MADERA, Material = Enum.Material.Wood, Parent = m })
		local b = corners[i % #corners + 1]
		if i ~= 1 then -- (por el lado de la caseta, abierto)
			for _, y in { 1.2, 2.8 } do
				part({ Name = "Alambre", Size = V(0.12, 0.12, (b - a).Magnitude), CFrame = H * lookAt((a + b) / 2 + V(0, y, 0), b + V(0, y, 0)), Color = rgb(170, 170, 175), Material = Enum.Material.Metal, Parent = m })
			end
		end
	end
	-- Dos gallinas de verdad picoteando (de código: World/Kit/GallinaGigante, se mueven en el cliente)
	for _, p in { { -3, -8, 30 }, { 3, -9.5, -110 } } do
		local hen = GallinaGigante.build(1.7, H * C(p[1], 0, p[2]) * CFrame.Angles(0, rad(p[3]), 0), { Simple = true })
		hen.Parent = m
	end
	-- Sacos de pienso y su comedero
	for i, p in { { 6, 2, 0 }, { 6.2, 3.4, 0.2 }, { 4.6, 2.2, 0.4 } } do
		local sack = decor({ Name = "SacoPienso", Size = V(1.6, 2.2, 1.1), CFrame = H * C(p[1] + 3, 1.1 + (if i == 2 then 2.1 else 0), p[2] - 2) * CFrame.Angles(0, p[3], if i == 2 then rad(80) else 0), Color = rgb(222, 206, 166), Material = Enum.Material.Fabric, Parent = m })
		if i == 1 then
			Builder.sign(sack, "PIENSO", Enum.NormalId.Front, rgb(120, 70, 30))
		end
	end
	decor({ Name = "ComederoGallinas", Size = V(4, 0.6, 1), CFrame = H * C(0, 0.3, -7), Color = MADERA, Material = Enum.Material.WoodPlanks, Parent = m })
	return m
end

local function tractor(parent: Instance, T: CFrame)
	local m = Builder.model("Tractor", parent)
	local red, dark = rgb(196, 36, 32), rgb(36, 36, 40)
	part({ Name = "Capo", Size = V(3.2, 3, 6.5), CFrame = T * C(0, 3.6, -2.8), Color = red, Material = Enum.Material.SmoothPlastic, Parent = m })
	decor({ Name = "Rejilla", Size = V(2.6, 2.2, 0.2), CFrame = T * C(0, 3.6, -6.1), Color = rgb(60, 60, 64), Material = Enum.Material.DiamondPlate, Parent = m })
	for _, s in { -1, 1 } do
		decor({ Name = "Faro", Shape = Enum.PartType.Ball, Size = V(0.7, 0.7, 0.7), CFrame = T * C(s * 1.2, 4.7, -6.1), Color = rgb(255, 245, 200), Material = Enum.Material.Neon, Parent = m })
	end
	part({ Name = "Chasis", Size = V(3, 1.4, 6), CFrame = T * C(0, 2.4, 2.4), Color = red, Parent = m })
	part({ Name = "Asiento", Size = V(1.8, 0.6, 1.8), CFrame = T * C(0, 3.6, 3.6), Color = dark, Parent = m })
	decor({ Name = "Volante", Shape = Enum.PartType.Cylinder, Size = V(0.2, 1.6, 1.6), CFrame = T * C(0, 5, 1.9) * CFrame.Angles(rad(-50), rad(90), 0), Color = dark, Parent = m })
	for _, x in { -2.1, 2.1 } do
		for _, z in { 1.6, 5.4 } do
			decor({ Name = "Cabina", Size = V(0.3, 5.4, 0.3), CFrame = T * C(x, 6, z), Color = dark, Material = Enum.Material.Metal, Parent = m })
		end
	end
	decor({ Name = "Techo", Size = V(4.8, 0.3, 4.6), CFrame = T * C(0, 8.8, 3.5), Color = red, Parent = m })
	decor({ Name = "Escape", Shape = Enum.PartType.Cylinder, Size = V(3, 0.4, 0.4), CFrame = T * C(1, 6.2, -4.5) * CFrame.Angles(0, 0, rad(90)), Color = rgb(70, 70, 74), Material = Enum.Material.Metal, Parent = m })
	for _, s in { -1, 1 } do
		part({ Name = "RuedaGrande", Shape = Enum.PartType.Cylinder, Size = V(1.8, 5.4, 5.4), CFrame = T * C(s * 2.6, 2.7, 3.4), Color = dark, Material = Enum.Material.Rubber, Parent = m })
		decor({ Name = "Llanta", Shape = Enum.PartType.Cylinder, Size = V(1.9, 2.6, 2.6), CFrame = T * C(s * 2.6, 2.7, 3.4), Color = rgb(240, 196, 40), Parent = m })
		part({ Name = "RuedaChica", Shape = Enum.PartType.Cylinder, Size = V(1.2, 3, 3), CFrame = T * C(s * 2.1, 1.5, -4.4), Color = dark, Material = Enum.Material.Rubber, Parent = m })
		decor({ Name = "Llanta", Shape = Enum.PartType.Cylinder, Size = V(1.3, 1.4, 1.4), CFrame = T * C(s * 2.1, 1.5, -4.4), Color = rgb(240, 196, 40), Parent = m })
	end
	return m
end

local function wheelbarrow(parent: Instance, W: CFrame)
	local m = Builder.model("Carretilla", parent)
	part({ Name = "Caja", Size = V(2.4, 1.2, 3.2), CFrame = W * C(0, 1.9, 0), Color = rgb(60, 120, 70), Material = Enum.Material.Metal, Parent = m })
	decor({ Name = "Heno", Shape = Enum.PartType.Ball, Size = V(2.6, 2.6, 2.6), CFrame = W * C(0, 2.5, 0), Color = HENO, Material = Enum.Material.Grass, Parent = m })
	decor({ Name = "Rueda", Shape = Enum.PartType.Cylinder, Size = V(0.4, 1.4, 1.4), CFrame = W * C(0, 0.7, -2), Color = rgb(36, 36, 40), Material = Enum.Material.Rubber, Parent = m })
	for _, s in { -1, 1 } do
		beam(m, W, V(s * 0.9, 1.4, -1.8), V(s * 1.1, 1.7, 3.2), 0.25, MADERA, Enum.Material.Wood, "Mango")
		decor({ Name = "Pata", Size = V(0.25, 1.4, 0.25), CFrame = W * C(s * 0.9, 0.7, 1.2), Color = MADERA, Material = Enum.Material.Wood, Parent = m })
	end
	return m
end

---------------------------------------------------------------------
-- La granja entera (m = el Model "Granja" del lote)
---------------------------------------------------------------------
function GranjaJulian.build(m: Model, lot: any)
	m:SetAttribute("Julian", true)
	local L, Dp = lot.Length, lot.Depth
	-- Un CFrame en el lote mirando en la dirección (du, dv)
	local function at(u: number, v: number, y: number, du: number, dv: number): CFrame
		return Builder.facing(lot.point(u, v, y), lot.point(u + du, v + dv, 0) - lot.point(u, v, 0))
	end

	-- Patio de tierra (delante del portón) y camino desde la entrada
	local u0, u1, v0, v1 = -38, GranjaJulian.CultivosDesde - 4, 6, Dp - 4
	part({ Name = "Patio", Size = V(v1 - v0, 0.3, u1 - u0), CFrame = at((u0 + u1) / 2, (v0 + v1) / 2, 0.15, 1, 0), Color = TIERRA, Material = Enum.Material.Ground, CastShadow = false, Parent = m })
	decor({ Name = "Camino", Size = V(8, 0.06, 40), CFrame = at(-14, 26, 0.32, 0, 1) * CFrame.Angles(0, rad(-25), 0), Color = rgb(176, 164, 140), Material = Enum.Material.Pebble, Parent = m })

	-- Granero (el portón mira al patio, +u) y silo
	local B = at(GRANERO_U, GRANERO_V, 0, 1, 0)
	barn(m, B)
	silo(m, at(SILO_U, SILO_V, 0, 0, -1))
	StoryMarks.spot(m, "Granja_Patio", B * C(0, 2.5, -GranjaJulian.Granero.Fondo / 2 - 18) * CFrame.Angles(0, math.pi, 0))

	-- Gallinero, tractor, carretilla, pacas fuera y abrevadero
	henhouse(m, at(14, 22, 0, 0, -1))
	tractor(m, at(10, 64, 0, 0, -1) * CFrame.Angles(0, rad(25), 0))
	wheelbarrow(m, B * C(-22, 0.3, -GranjaJulian.Granero.Fondo / 2 - 6) * CFrame.Angles(0, rad(140), 0))
	for i, p in { { -90, 30, 0 }, { -90, 35.2, 0 }, { -90, 32.6, 1 } } do
		part({ Name = "Paca", Size = V(2.8, 2.6, 5), CFrame = at(p[1], p[2], 1.6 + p[3] * 2.6, 0, -1) * CFrame.Angles(0, rad(90), 0), Color = if i % 2 == 0 then HENO else HENO_OSCURO, Material = Enum.Material.Grass, Parent = m })
	end
	part({ Name = "Abrevadero", Size = V(8, 1.6, 2.4), CFrame = at(-8, 70, 0.8, 1, 0), Color = rgb(120, 126, 134), Material = Enum.Material.Metal, Parent = m })
	decor({ Name = "Agua", Size = V(7.4, 0.1, 1.8), CFrame = at(-8, 70, 1.55, 1, 0), Color = rgb(90, 150, 190), Material = Enum.Material.Glass, Transparency = 0.3, Parent = m })

	-- Valla con portón de entrada (hueco en la del lado de la calle) y cartel
	local gate0, gate1 = -12, 2
	local wood = rgb(132, 96, 66)
	for _, v in { 2, Dp - 2 } do
		local spans = if v == 2 then { { -L / 2 + 2, gate0 }, { gate1, L / 2 - 2 } } else { { -L / 2 + 2, L / 2 - 2 } }
		for _, span in spans do
			local a, b = span[1], span[2]
			for _, y in { 2.4, 1.2 } do
				part({ Name = "Fence", Size = V(b - a, 0.4, 0.3), CFrame = at((a + b) / 2, v, y, 0, -1), Color = wood, Material = Enum.Material.Wood, Parent = m })
			end
			for u = a, b, 12 do
				decor({ Name = "Poste", Size = V(0.5, 3.2, 0.5), CFrame = at(u, v, 1.6, 0, -1), Color = wood, Material = Enum.Material.Wood, Parent = m })
			end
		end
	end
	for _, u in { gate0, gate1 } do
		part({ Name = "PostePorton", Size = V(0.8, 9, 0.8), CFrame = at(u, 2, 4.5, 0, -1), Color = wood, Material = Enum.Material.Wood, Parent = m })
	end
	local board = decor({ Name = "Cartel", Size = V(gate1 - gate0 + 1, 2.2, 0.4), CFrame = at((gate0 + gate1) / 2, 2, 8.2, 0, -1), Color = rgb(246, 238, 220), Parent = m })
	Builder.sign(board, "GRANJA ESCUELA DE VILLAVERDE", Enum.NormalId.Front, ROJO_OSCURO)
	Builder.sign(board, "GRANJA ESCUELA DE VILLAVERDE", Enum.NormalId.Back, ROJO_OSCURO)

	-- Árboles junto a la valla
	for _, p in { { -94, 8 }, { -94, 88 }, { 0, 90 } } do
		Nature.tree(m, lot.point(p[1], p[2], 0), 1.2)
	end
end

return GranjaJulian
