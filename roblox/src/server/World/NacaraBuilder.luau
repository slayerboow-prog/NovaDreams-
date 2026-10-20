-- NacaraBuilder: construye la plaza de prueba de Nácara (fase 0, docs/mar/civilizacion-marina.md) UNA
-- vez en el servidor, después de World/OceanBuilder (cuando workspace.OceanReady). Lo llama
-- Services/NacaraService. Dónde y qué hay: shared/Sea/Nacara.
--
--   * Terreno: allana un disco de la Llanura Sumergida (Salt, el grano blanco del fondo del mar) y
--     rellena de AIRE la cúpula de la Lonja Honda (dentro no hay agua: se anda y se respira).
--   * Piezas (workspace.Nacara, modelos Atomic: con StreamingEnabled llegan enteros o no llegan):
--     plaza de nácar con anillos que brillan, la fuente-columna de la corriente, cuatro torres de coral
--     de luz con terrazas y cápsulas, dos conchas-casa, tres terrazas a distintas alturas, dos arcos de
--     kelp trenzado con perlas, perlas-farola, la cúpula de aire con cuatro puestos y los carteles.
--   * Luz: sobre todo Neon (coral y perlas) y pocas PointLight grandes (≤ 7, sin sombras).
--   * Presupuesto: Nacara.Budget piezas para TODO (edificios y gente; la gente la pone NacaraService con
--     NacaraBuilder.take). Sin materiales que cambia World/UserMaterials (mármol, pizarra, arena…):
--     SmoothPlastic con brillo de nácar, Neon, Glass, Fabric y Salt.
--
-- Etiquetas: SeaAirPocket en la burbuja de la cúpula (atributo Radius: DivingService rellena el aire
-- dentro) y NacaraDome. Atributo NacaraReady en workspace al terminar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)

local NacaraBuilder = {}

NacaraBuilder.State = "None"
NacaraBuilder.Stats = { Parts = 0, Lights = 0, Models = 0, Fills = 0, Seconds = 0 }

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad
local cos, sin, pi = math.cos, math.sin, math.pi

-- Colores de Nácara
local NACRE = rgb(218, 214, 234) -- nácar (blanco perla con un toque violeta; no blanco puro: bajo el agua deslumbraba)
local NACRE_WARM = rgb(226, 212, 204)
local NACRE_DARK = rgb(150, 160, 186)
local KELP = rgb(70, 110, 62)
local KELP_DARK = rgb(46, 76, 46)
local PEARL = rgb(236, 244, 255)
local CYAN = rgb(90, 235, 255)
local GLOWS = {
	Pink = { Body = rgb(236, 120, 170), Glow = rgb(255, 150, 210) },
	Violet = { Body = rgb(150, 100, 220), Glow = rgb(200, 150, 255) },
	Cyan = { Body = rgb(70, 190, 210), Glow = rgb(120, 245, 255) },
	Coral = { Body = rgb(240, 130, 100), Glow = rgb(255, 190, 140) },
}

local parts = 0
local lights = 0
NacaraBuilder.MaxLights = 7

local function folder(): Folder
	local f = workspace:FindFirstChild("Nacara")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Nacara"
		f.Parent = workspace
	end
	return f :: Folder
end
NacaraBuilder.folder = folder

local function model(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	pcall(function()
		(m :: any).LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh
	end)
	m.Parent = folder()
	NacaraBuilder.Stats.Models += 1
	return m
end
NacaraBuilder.model = model

-- Cuántas piezas quedan del presupuesto (NacaraService las pide para la gente)
function NacaraBuilder.left(): number
	return Nacara.Budget - parts
end
-- Apunta n piezas (las de la gente); false si no caben
function NacaraBuilder.take(n: number): boolean
	if parts + n > Nacara.Budget then
		return false
	end
	parts += n
	NacaraBuilder.Stats.Parts = parts
	return true
end
-- Reserva para la gente (8 Hondarios de ~36 piezas): los edificios no pasan de aquí
NacaraBuilder.PeopleReserve = 300

type Spec = { Size: Vector3, CFrame: CFrame, Color: Color3, Material: Enum.Material?, Shape: Enum.PartType?, Collide: boolean?, Transparency: number?, Name: string?, Reflect: number? }
local function part(parent: Instance, s: Spec): BasePart?
	if parts >= Nacara.Budget - NacaraBuilder.PeopleReserve then
		return nil
	end
	parts += 1
	local p = Instance.new("Part")
	p.Name = s.Name or "Pieza"
	p.Anchored = true
	p.Size = s.Size
	p.CFrame = s.CFrame
	p.Color = s.Color
	p.Material = s.Material or Enum.Material.SmoothPlastic
	local size = s.Size
	local round = s.Shape == Enum.PartType.Ball and (math.abs(size.X - size.Y) > 0.01 or math.abs(size.X - size.Z) > 0.01)
	if round then
		-- (en Roblox una bola es siempre redonda: las chafadas —cúpulas, conchas, pétalos— son un bloque
		-- con una malla de esfera, como ShoreDecor)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif s.Shape then
		p.Shape = s.Shape
	end
	p.Reflectance = s.Reflect or 0
	p.CanCollide = s.Collide == true
	p.CanTouch = false
	p.CanQuery = s.Collide == true
	p.CastShadow = false
	p.Transparency = s.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
NacaraBuilder._part = part

local function light(p: BasePart?, color: Color3, range: number, brightness: number)
	if not p or lights >= NacaraBuilder.MaxLights then
		return
	end
	lights += 1
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = p
end

-- Piezas con forma
local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local NEON, GLASS, SMOOTH, FABRIC = Enum.Material.Neon, Enum.Material.Glass, Enum.Material.SmoothPlastic, Enum.Material.Fabric
-- cilindro de pie (el eje de un Cylinder de Roblox es X: se gira 90° en Z)
local function upright(at: Vector3, yaw: number?): CFrame
	return CF(at) * ANG(0, yaw or 0, rad(90))
end
-- tramo entre dos puntos (cilindro)
local function between(parent: Instance, a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?, name: string?): BasePart?
	local d = b - a
	local len = d.Magnitude
	if len < 0.05 then
		return nil
	end
	local cf = CFrame.lookAt((a + b) / 2, b) * ANG(0, rad(90), 0)
	return part(parent, { Name = name or "Tramo", Shape = CYL, Size = V(len, thick, thick), CFrame = cf, Color = color, Material = material })
end

local W = Nacara.toWorld

---------------------------------------------------------------------
-- Terreno
---------------------------------------------------------------------
function NacaraBuilder.terrain(terrain: any)
	local c = Nacara.centerPosition()
	local y0 = Nacara.FloorY
	local function count()
		NacaraBuilder.Stats.Fills += 1
	end
	-- 1. Quitar lo que sobresale del fondo encima de la plaza (rocas, montículos): agua hasta 24 studs
	terrain:FillCylinder(CF(c + V(0, 12, 0)), 24, Nacara.Clear, Enum.Material.Water)
	count()
	-- 2. El suelo, plano: grano blanco (Salt) hasta justo debajo de las piezas de la plaza
	terrain:FillCylinder(CF(c - V(0, 7, 0)), 14, Nacara.Clear, Enum.Material.Salt)
	count()
	-- un borde que baja suave hacia la llanura (la plaza queda un poco hundida, como un anfiteatro)
	for i = 0, 11 do
		local a = i / 12 * pi * 2
		terrain:FillBall(c + V(cos(a) * (Nacara.Clear + 6), -3, sin(a) * (Nacara.Clear + 6)), 12, Enum.Material.Salt)
		count()
	end
	-- 3. La cúpula de aire: una burbuja de Aire (sin agua dentro); el suelo de debajo se vuelve a poner
	local d = Nacara.domeCenter()
	terrain:FillBall(d, Nacara.Dome.Air, Enum.Material.Air)
	terrain:FillCylinder(CF(d - V(0, 7, 0)), 14, Nacara.Dome.Air + 2, Enum.Material.Salt)
	count()
	count()
	return y0
end

---------------------------------------------------------------------
-- La plaza, la fuente y los arcos
---------------------------------------------------------------------
local function plaza(m: Model)
	local c = Nacara.centerPosition()
	-- suelo: disco de nácar con un borde más oscuro, dos anillos que brillan y la rosa del centro
	part(m, { Name = "Borde", Shape = CYL, Size = V(1.2, Nacara.Radius * 2 + 4, Nacara.Radius * 2 + 4), CFrame = upright(c + V(0, -0.2, 0)), Color = NACRE_DARK, Collide = true })
	part(m, { Name = "Suelo", Shape = CYL, Size = V(1, Nacara.Radius * 2, Nacara.Radius * 2), CFrame = upright(c + V(0, 0.1, 0)), Color = NACRE, Reflect = 0.12, Collide = true })
	for _, r in { 34, 18 } do
		part(m, { Name = "AnilloLuz", Shape = CYL, Size = V(0.12, r * 2, r * 2), CFrame = upright(c + V(0, 0.62, 0)), Color = if r == 34 then CYAN else rgb(255, 170, 220), Material = NEON, Transparency = 0.15 })
		part(m, { Name = "AnilloSuelo", Shape = CYL, Size = V(0.14, r * 2 - 2.2, r * 2 - 2.2), CFrame = upright(c + V(0, 0.64, 0)), Color = NACRE_WARM, Reflect = 0.1 })
	end
	-- la rosa de los vientos de las Corrientes: cinco pétalos de nácar alrededor de la fuente
	for i = 0, 4 do
		local a = i / 5 * pi * 2
		part(m, { Name = "Petalo", Shape = BALL, Size = V(7, 0.5, 2.8), CFrame = CF(c + V(cos(a) * 12, 0.7, sin(a) * 12)) * ANG(0, -a, 0), Color = rgb(210, 200, 236), Reflect = 0.2 })
	end
end

local function fountain(m: Model)
	local c = Nacara.centerPosition()
	-- pila de conchas
	part(m, { Name = "Pila", Shape = CYL, Size = V(2, 15, 15), CFrame = upright(c + V(0, 1.4, 0)), Color = NACRE_DARK, Collide = true })
	part(m, { Name = "PilaAgua", Shape = CYL, Size = V(0.3, 13, 13), CFrame = upright(c + V(0, 2.45, 0)), Color = rgb(60, 200, 230), Material = NEON, Transparency = 0.45 })
	for i, s in { { 10, 3.4 }, { 7, 6.4 }, { 4.6, 9.2 } } do
		local shell = part(m, { Name = "Concha" .. i, Shape = BALL, Size = V(s[1], s[1] * 0.32, s[1]), CFrame = CF(c + V(0, s[2], 0)), Color = NACRE, Reflect = 0.25, Collide = i == 1 })
		local _ = shell
		part(m, { Name = "Pie" .. i, Shape = CYL, Size = V(3, 1.1 + i * 0.1, 1.1 + i * 0.1), CFrame = upright(c + V(0, s[2] - 1.6, 0)), Color = NACRE_DARK })
	end
	-- la columna de la corriente: un chorro de luz que sube 40 studs con burbujas
	local column = part(m, { Name = "ColumnaCorriente", Shape = CYL, Size = V(40, 3.2, 3.2), CFrame = upright(c + V(0, 30, 0)), Color = CYAN, Material = NEON, Transparency = 0.62 })
	part(m, { Name = "ColumnaNucleo", Shape = CYL, Size = V(40, 1.1, 1.1), CFrame = upright(c + V(0, 30, 0)), Color = rgb(220, 255, 255), Material = NEON, Transparency = 0.3 })
	local pearl = part(m, { Name = "PerlaMayor", Shape = BALL, Size = V(4.4, 4.4, 4.4), CFrame = CF(c + V(0, 51, 0)), Color = PEARL, Material = NEON })
	light(pearl, rgb(200, 235, 255), 60, 1.6)
	if column then
		local e = Instance.new("ParticleEmitter")
		e.Name = "Burbujas"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate = 10
		e.Lifetime = NumberRange.new(4, 6)
		e.Speed = NumberRange.new(5, 8)
		e.Size = NumberSequence.new(0.35)
		e.LightEmission = 0.6
		e.Color = ColorSequence.new(rgb(200, 250, 255))
		e.EmissionDirection = Enum.NormalId.Right -- (el eje del cilindro de pie: hacia arriba)
		e.Parent = column
	end
	-- anillos de corriente alrededor de la columna (como un remolino tranquilo)
	for i = 1, 3 do
		part(m, { Name = "AnilloCorriente", Shape = CYL, Size = V(0.3, 8 - i, 8 - i), CFrame = upright(c + V(0, 14 + i * 9, 0)), Color = CYAN, Material = NEON, Transparency = 0.5 })
	end
end

-- Arco de kelp trenzado: dos cordones que se cruzan en semicírculo, hojas y perlas colgando
local function kelpArch(m: Model, item: { [string]: any })
	local base = W(item.X, item.Z, 0)
	local across = if item.Facing == "North" then V(1, 0, 0) else V(0, 0, 1)
	local span, height = 10, 16
	local n = 8
	for strand = 0, 1 do
		local prev: Vector3? = nil
		for i = 0, n do
			local a = pi * i / n
			local twist = sin(a * 6 + strand * pi) * 0.7
			local p = base + across * (cos(a) * span) + V(0, sin(a) * height + 0.6, 0) + V(0, 0, 0) + (if item.Facing == "North" then V(0, 0, twist) else V(twist, 0, 0))
			if prev then
				between(m, prev, p, 1.3 - strand * 0.25, if strand == 0 then KELP else KELP_DARK, FABRIC, "Kelp")
			end
			prev = p
		end
	end
	-- hojas largas que caen de lo alto y perlas que cuelgan
	for i = -2, 2 do
		local top = base + across * (i * 3.6) + V(0, height * (1 - (i / 3.2) ^ 2) + 0.4, 0)
		part(m, { Name = "Hoja", Size = V(0.15, 4.5, 1.2), CFrame = CF(top - V(0, 2.4, 0)) * ANG(0, if item.Facing == "North" then 0 else pi / 2, rad(i * 6)), Color = rgb(96, 150, 70), Material = FABRIC })
		if i % 2 == 0 then
			part(m, { Name = "PerlaColgante", Shape = BALL, Size = V(1.3, 1.3, 1.3), CFrame = CF(top - V(0, 5.2, 0)), Color = PEARL, Material = NEON })
		end
	end
end

---------------------------------------------------------------------
-- Torres de coral de luz
---------------------------------------------------------------------
local function tower(m: Model, item: { [string]: any }, index: number)
	local palette = GLOWS[item.Color] or GLOWS.Pink
	local base = W(item.X, item.Z, 0)
	local h = item.H
	-- el tronco: tramos que se estrechan y se tuercen un poco (como coral cultivado)
	local segs = 5
	local prev = base
	local tops = {}
	for i = 1, segs do
		local k = i / segs
		local lean = V(sin(index * 1.7 + i) * 1.6, 0, cos(index * 2.3 + i) * 1.6)
		local p = base + V(0, h * k, 0) + lean * k
		local thick = 6.2 - 3.6 * k
		between(m, prev, p, thick, palette.Body, SMOOTH, "Tronco")
		-- nudo que brilla en cada unión
		part(m, { Name = "Nudo", Shape = BALL, Size = V(thick * 1.05, thick * 0.55, thick * 1.05), CFrame = CF(p), Color = palette.Glow, Material = NEON, Transparency = 0.25 })
		tops[i] = p
		prev = p
	end
	-- ramas que se abren con puntas que brillan
	for b = 1, 6 do
		local from = tops[2 + (b % 3)]
		local a = b / 6 * pi * 2 + index
		local len = 7 + (b % 3) * 2.5
		local tip = from + V(cos(a) * len, 3 + (b % 2) * 3, sin(a) * len)
		between(m, from, tip, 1.3, palette.Body, SMOOTH, "Rama")
		part(m, { Name = "Punta", Shape = BALL, Size = V(1.9, 1.9, 1.9), CFrame = CF(tip), Color = palette.Glow, Material = NEON })
	end
	-- dos terrazas de nácar en la torre (a distintas alturas) con baranda que brilla
	for t, k in { 0.38, 0.7 } do
		local p = base + V(0, h * k, 0) + V(sin(index * 1.7 + 2) * 1.6, 0, cos(index * 2.3 + 2) * 1.6) * k
		local r = 7.5 - t * 1.5
		part(m, { Name = "Terraza", Shape = CYL, Size = V(0.8, r * 2, r * 2), CFrame = upright(p), Color = NACRE, Reflect = 0.15, Collide = true })
		part(m, { Name = "Baranda", Shape = CYL, Size = V(0.18, r * 2 + 0.4, r * 2 + 0.4), CFrame = upright(p + V(0, 0.5, 0)), Color = palette.Glow, Material = NEON, Transparency = 0.35 })
		-- casas-cápsula colgadas bajo la terraza (como frutos), con una ventana que brilla
		for c = 0, 1 do
			local a = index + c * pi + t
			local at = p + V(cos(a) * (r - 1.8), -3.2, sin(a) * (r - 1.8))
			part(m, { Name = "Capsula", Shape = BALL, Size = V(4.2, 5, 4.2), CFrame = CF(at), Color = NACRE_WARM, Reflect = 0.1 })
			part(m, { Name = "Ventana", Shape = BALL, Size = V(1.4, 1.6, 1.4), CFrame = CF(at + V(cos(a) * 1.8, 0.2, sin(a) * 1.8)), Color = rgb(255, 214, 150), Material = NEON })
		end
	end
	-- la corona: una perla grande arriba del todo
	local crown = part(m, { Name = "Corona", Shape = BALL, Size = V(3.6, 3.6, 3.6), CFrame = CF(tops[segs] + V(0, 1.4, 0)), Color = palette.Glow, Material = NEON })
	if index <= 2 then
		light(crown, palette.Glow, 40, 1.1)
	end
	-- raíz: bultos de coral en el suelo
	for r = 0, 3 do
		local a = r / 4 * pi * 2 + index
		part(m, { Name = "Raiz", Shape = BALL, Size = V(4, 2.4, 4), CFrame = CF(base + V(cos(a) * 3.6, 0.8, sin(a) * 3.6)), Color = palette.Body })
	end
end

---------------------------------------------------------------------
-- Conchas-casa, terrazas y perlas-farola
---------------------------------------------------------------------
local function shellHouse(m: Model, item: { [string]: any })
	local base = W(item.X, item.Z, 0)
	local r = item.R
	-- la cúpula de nácar (media bola) con costillas de vieira
	part(m, { Name = "Concha", Shape = BALL, Size = V(r * 2, r * 1.5, r * 2), CFrame = CF(base + V(0, 0.2, 0)), Color = NACRE, Reflect = 0.2, Collide = true })
	local toPlaza = (Nacara.centerPosition() - base) * V(1, 0, 1)
	local face = toPlaza.Unit
	local yaw = math.atan2(-face.X, -face.Z)
	for i = -3, 3 do
		local a = yaw + i * 0.42
		local dir = V(-sin(a), 0, -cos(a))
		part(m, { Name = "Costilla", Size = V(0.5, r * 0.75, r * 1.1), CFrame = CF(base + dir * (r * 0.45) + V(0, r * 0.32, 0)) * ANG(0, a, 0) * ANG(rad(-35), 0, 0), Color = NACRE_WARM, Reflect = 0.2 })
	end
	-- la puerta (arco que brilla) mirando a la plaza y dos ojos de buey
	local door = CF(base + face * (r * 0.92) + V(0, 2.6, 0)) * ANG(0, yaw, 0)
	part(m, { Name = "Puerta", Size = V(3.2, 4.8, 0.3), CFrame = door, Color = rgb(30, 50, 80) })
	part(m, { Name = "MarcoPuerta", Size = V(3.8, 0.4, 0.4), CFrame = door * CF(0, 2.5, 0), Color = CYAN, Material = NEON })
	for s = -1, 1, 2 do
		part(m, { Name = "OjoDeBuey", Shape = CYL, Size = V(0.3, 1.5, 1.5), CFrame = CF(base + face * (r * 0.8) + V(0, r * 0.45, 0) + V(face.Z, 0, -face.X) * (s * r * 0.45)) * ANG(0, yaw + pi / 2, 0), Color = rgb(255, 214, 150), Material = NEON })
	end
	-- una perla en la cima
	part(m, { Name = "Remate", Shape = BALL, Size = V(1.6, 1.6, 1.6), CFrame = CF(base + V(0, r * 0.78, 0)), Color = PEARL, Material = NEON })
end

local function terrace(m: Model, item: { [string]: any })
	local base = W(item.X, item.Z, 0)
	local h, r = item.H, item.R
	-- pie de coral y el plato de nácar
	part(m, { Name = "PieTerraza", Shape = CYL, Size = V(h, r * 0.7, r * 0.7), CFrame = upright(base + V(0, h / 2, 0)), Color = rgb(200, 150, 190) })
	part(m, { Name = "Terraza", Shape = CYL, Size = V(0.9, r * 2, r * 2), CFrame = upright(base + V(0, h, 0)), Color = NACRE, Reflect = 0.15, Collide = true })
	part(m, { Name = "BordeLuz", Shape = CYL, Size = V(0.16, r * 2 + 0.5, r * 2 + 0.5), CFrame = upright(base + V(0, h + 0.3, 0)), Color = rgb(255, 170, 220), Material = NEON, Transparency = 0.3 })
	-- una perla-farola en el borde
	part(m, { Name = "Perla", Shape = BALL, Size = V(1.5, 1.5, 1.5), CFrame = CF(base + V(r - 1, h + 2.4, 0)), Color = PEARL, Material = NEON })
	part(m, { Name = "Tallo", Shape = CYL, Size = V(1.8, 0.35, 0.35), CFrame = upright(base + V(r - 1, h + 1.2, 0)), Color = rgb(200, 150, 190) })
end

-- Rampas de kelp entre las terrazas (para verlas «unidas»)
local function ramps(m: Model)
	local list = { "Terraza1", "Terraza2", "Terraza3" }
	for i = 1, #list - 1 do
		local a, b = Nacara.ById[list[1]], Nacara.ById[list[i + 1]]
		between(m, W(a.X, a.Z, a.H + 0.5), W(b.X, b.Z, b.H + 0.5), 1.1, KELP, FABRIC, "RampaKelp")
	end
end

local function lamps(m: Model)
	local c = Nacara.centerPosition()
	local d = Nacara.domeCenter()
	for i = 0, 11 do
		local a = i / 12 * pi * 2 + 0.13
		local p = c + V(cos(a) * 24, 0, sin(a) * 24)
		if ((p - d) * V(1, 0, 1)).Magnitude > Nacara.Dome.Radius + 2.5 then
			-- tallo de coral curvo y la perla en su cuna de tres dedos
			part(m, { Name = "Tallo", Shape = CYL, Size = V(6.2, 0.5, 0.5), CFrame = upright(p + V(0, 3.4, 0)), Color = rgb(190, 170, 210) })
			for f = 0, 2 do
				local fa = f / 3 * pi * 2 + a
				part(m, { Name = "Dedo", Size = V(0.25, 1.4, 0.25), CFrame = CF(p + V(cos(fa) * 0.55, 6.9, sin(fa) * 0.55)) * ANG(sin(fa) * 0.4, 0, -cos(fa) * 0.4), Color = rgb(190, 170, 210) })
			end
			part(m, { Name = "PerlaFarola", Shape = BALL, Size = V(1.9, 1.9, 1.9), CFrame = CF(p + V(0, 7.6, 0)), Color = PEARL, Material = NEON })
		end
	end
	-- anémonas que brillan y almejas gigantes por el borde de la plaza (vida quieta del suelo)
	for i = 0, 17 do
		local a = i / 18 * pi * 2 + 0.5
		local p = c + V(cos(a) * (Nacara.Radius - 3.5), 0.5, sin(a) * (Nacara.Radius - 3.5))
		local blocked = false
		for _, item in Nacara.Layout do
			local q = W(item.X, item.Z, 0)
			if ((p - q) * V(1, 0, 1)).Magnitude < item.R + 2.5 then
				blocked = true
			end
		end
		if not blocked then
			if i % 3 == 0 then
				part(m, { Name = "Almeja", Shape = BALL, Size = V(3.4, 1.4, 2.6), CFrame = CF(p + V(0, 0.4, 0)) * ANG(0, a, 0), Color = rgb(120, 110, 170) })
				part(m, { Name = "Perla", Shape = BALL, Size = V(0.9, 0.9, 0.9), CFrame = CF(p + V(0, 1.1, 0)), Color = PEARL, Material = NEON })
			else
				local glow = if i % 2 == 0 then rgb(255, 150, 210) else CYAN
				part(m, { Name = "Anemona", Shape = CYL, Size = V(1.4, 1.2, 1.2), CFrame = upright(p + V(0, 0.5, 0)), Color = rgb(210, 120, 160) })
				part(m, { Name = "Tentaculos", Shape = BALL, Size = V(2.4, 1.2, 2.4), CFrame = CF(p + V(0, 1.5, 0)), Color = glow, Material = NEON, Transparency = 0.25 })
			end
		end
	end
end

-- Bosquecillo de kelp gigante alrededor de la plaza (fuera del disco): da fondo y silueta, y las algas
-- de cultivo de los Hondarios. Tallos de 5 tramos que se tuercen, con hojas y un flotador.
local function kelpRing(m: Model)
	local c = Nacara.centerPosition()
	for i = 0, 9 do
		local a = i / 10 * pi * 2 + 0.31
		-- (no delante de los arcos de entrada: norte y este)
		local dx, dz = cos(a), sin(a)
		if not ((dz < -0.85) or (dx > 0.85)) then
			local base = c + V(dx * (Nacara.Radius + 5 + (i % 3) * 3), 0, dz * (Nacara.Radius + 5 + (i % 3) * 3))
			local h = 26 + (i * 7) % 14
			local prev = base
			for k = 1, 5 do
				local p = base + V(sin(i + k * 0.9) * 1.6, h * k / 5, cos(i * 1.3 + k) * 1.6)
				between(m, prev, p, 0.9 - k * 0.08, if k % 2 == 0 then KELP else KELP_DARK, FABRIC, "TalloKelp")
				if k >= 2 then
					part(m, { Name = "HojaKelp", Size = V(0.12, 3.8, 1.3), CFrame = CF(p + V(0.8, -1.2, 0)) * ANG(0, i + k, rad(25)), Color = rgb(110, 150, 64), Material = FABRIC })
				end
				prev = p
			end
			part(m, { Name = "Flotador", Shape = BALL, Size = V(1.1, 1.1, 1.1), CFrame = CF(prev + V(0, 0.6, 0)), Color = rgb(150, 160, 70) })
		end
	end
end

---------------------------------------------------------------------
-- La cúpula de aire (Lonja Honda) y sus puestos
---------------------------------------------------------------------
local function dome(m: Model)
	local d = Nacara.domeCenter()
	local R = Nacara.Dome.Radius
	-- la membrana (media bola de «medusa de vidrio»: la mitad de abajo queda bajo el suelo)
	local bubble = part(m, { Name = "Membrana", Shape = BALL, Size = V(R * 2, R * 2, R * 2), CFrame = CF(d), Color = rgb(190, 235, 255), Material = GLASS, Transparency = 0.74 })
	if bubble then
		bubble:AddTag("SeaAirPocket")
		bubble:AddTag("NacaraDome")
		bubble:SetAttribute("Radius", Nacara.Dome.Air + 1)
		bubble:SetAttribute("NacaraTest", true)
	end
	-- el suelo seco (se anda) y el anillo del pie
	part(m, { Name = "SueloSeco", Shape = CYL, Size = V(1.2, (Nacara.Dome.Air + 1.5) * 2, (Nacara.Dome.Air + 1.5) * 2), CFrame = upright(d + V(0, 0.5, 0)), Color = rgb(196, 182, 172), Collide = true }) -- (arena de nácar tostada: el blanco deslumbraba bajo la lámpara)
	part(m, { Name = "PieCupula", Shape = CYL, Size = V(1.6, R * 2 + 2, R * 2 + 2), CFrame = upright(d + V(0, 0.2, 0)), Color = NACRE_DARK })
	part(m, { Name = "AnilloMembrana", Shape = CYL, Size = V(0.2, R * 2 + 0.6, R * 2 + 0.6), CFrame = upright(d + V(0, 1.2, 0)), Color = CYAN, Material = NEON, Transparency = 0.2 })
	-- costillas de nácar (cuatro meridianos de la media bola)
	for k = 0, 3 do
		local a = k / 4 * pi + pi / 8
		local prev: Vector3? = nil
		for i = 0, 6 do
			local e = pi * i / 6
			local p = d + V(cos(a) * cos(e) * R, sin(e) * R, sin(a) * cos(e) * R)
			if prev then
				between(m, prev, p, 0.55, NACRE, SMOOTH, "Costilla")
			end
			prev = p
		end
	end
	-- la lámpara del techo (una perla grande colgando) y su luz
	local top = part(m, { Name = "LamparaTecho", Shape = BALL, Size = V(3, 3, 3), CFrame = CF(d + V(0, R - 4.5, 0)), Color = rgb(255, 236, 200), Material = NEON })
	light(top, rgb(255, 230, 190), 30, 1)
	part(m, { Name = "Cordon", Shape = CYL, Size = V(3, 0.2, 0.2), CFrame = upright(d + V(0, R - 2.4, 0)), Color = NACRE_DARK })
	-- una entrada marcada hacia la fuente (dos postes con un arco de luz: por aquí se cruza la membrana)
	local into = (Nacara.centerPosition() - d) * V(1, 0, 1)
	local dir = into.Unit
	local side = V(-dir.Z, 0, dir.X)
	for s = -1, 1, 2 do
		part(m, { Name = "PosteEntrada", Shape = CYL, Size = V(7, 0.8, 0.8), CFrame = upright(d + dir * (R - 0.6) + side * (s * 3.4) + V(0, 3.5, 0)), Color = NACRE })
	end
	part(m, { Name = "ArcoEntrada", Size = V(0.5, 0.5, 7.6), CFrame = CFrame.lookAt(d + dir * (R - 0.6) + V(0, 7.2, 0), d + dir * (R - 0.6) + V(0, 7.2, 0) + side), Color = CYAN, Material = NEON })
end

-- Un puesto: mostrador, toldo de concha, lo que vende y un farolillo
local function stall(m: Model, s: { [string]: any })
	local x, z = Nacara.stallSpot(s)
	local at = W(x, z, 1.1)
	local d = Nacara.domeCenter()
	local inward = ((d - at) * V(1, 0, 1)).Unit
	local yaw = math.atan2(-inward.X, -inward.Z)
	local cf = CF(at) * ANG(0, yaw, 0) -- -Z del puesto mira al centro de la cúpula (el cliente)
	local width = if s.Keeper then 7 else 5.5
	part(m, { Name = "Mostrador", Size = V(width, 3, 2.2), CFrame = cf * CF(0, 1.5, 0), Color = NACRE_WARM, Reflect = 0.1, Collide = true })
	part(m, { Name = "Encimera", Size = V(width + 0.4, 0.3, 2.6), CFrame = cf * CF(0, 3.1, 0), Color = s.Color })
	-- toldo de concha (abanico inclinado)
	part(m, { Name = "Toldo", Shape = BALL, Size = V(width + 1.5, 0.6, 4.2), CFrame = cf * CF(0, 7.4, 0.8) * ANG(rad(-14), 0, 0), Color = s.Color })
	for side = -1, 1, 2 do
		part(m, { Name = "PalitoToldo", Shape = CYL, Size = V(4.4, 0.3, 0.3), CFrame = cf * CF(side * (width / 2 - 0.4), 5.2, 1.3) * ANG(0, 0, rad(90)), Color = NACRE_DARK })
	end
	-- lo que vende (tres montones)
	for i = -1, 1 do
		local ware = cf * CF(i * (width / 3.2), 3.75, 0)
		if s.Id == "Algas" then
			part(m, { Name = "Algas", Size = V(1.2, 1, 0.9), CFrame = ware * ANG(0, i * 0.4, 0), Color = rgb(60, 140 + i * 20, 70), Material = FABRIC })
		elseif s.Id == "Faroles" or s.Id == "Perlera" then
			part(m, { Name = "Perla", Shape = BALL, Size = V(1, 1, 1), CFrame = ware, Color = if i == 0 then rgb(255, 200, 240) else PEARL, Material = NEON })
		else
			part(m, { Name = "Peine", Size = V(1.4, 0.25, 0.8), CFrame = ware * ANG(0, i * 0.5, 0), Color = rgb(250, 220, 210), Reflect = 0.3 })
		end
	end
	-- su nombre en el toldo
	local board = part(m, { Name = "Rotulo", Size = V(width, 1.1, 0.2), CFrame = cf * CF(0, 5.6, -0.9), Color = rgb(24, 40, 70) })
	if board then
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = s.Name
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = rgb(230, 245, 255)
		label.Parent = gui
		board:SetAttribute("StallId", s.Id)
	end
end

---------------------------------------------------------------------
-- Carteles
---------------------------------------------------------------------
local function sign(m: Model, s: { [string]: any })
	local at = W(s.X, s.Z, 0)
	local target = if s.FaceDome then Nacara.domeCenter() else Nacara.centerPosition()
	local toward = ((target - at) * V(1, 0, 1))
	toward = if toward.Magnitude > 0.1 then toward.Unit else V(0, 0, 1)
	-- (el texto mira hacia quien llega: el de la entrada, hacia fuera de la plaza; el de la Lonja, hacia
	-- la fuente, de espaldas a la cúpula)
	toward = -toward
	local yaw = math.atan2(-toward.X, -toward.Z)
	local cf = CF(at) * ANG(0, yaw, 0)
	part(m, { Name = "PosteCartel", Shape = CYL, Size = V(s.H, 0.6, 0.6), CFrame = cf * CF(0, s.H / 2, 0.2) * ANG(0, 0, rad(90)), Color = NACRE_DARK })
	local board = part(m, { Name = "Cartel", Size = V(9, 3.4, 0.35), CFrame = cf * CF(0, s.H + 0.8, 0), Color = rgb(18, 34, 62), Collide = true })
	part(m, { Name = "MarcoCartel", Size = V(9.6, 0.3, 0.4), CFrame = cf * CF(0, s.H + 2.65, 0), Color = CYAN, Material = NEON })
	if board then
		board:SetAttribute("NacaraSign", s.Id)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = board
		local title = Instance.new("TextLabel")
		title.Name = "Titulo"
		title.Size = UDim2.fromScale(1, 0.58)
		title.BackgroundTransparency = 1
		title.Text = s.Text
		title.TextScaled = true
		title.Font = Enum.Font.GothamBold
		title.TextColor3 = rgb(235, 250, 255)
		title.Parent = gui
		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.Position = UDim2.fromScale(0.04, 0.6)
		sub.Size = UDim2.fromScale(0.92, 0.34)
		sub.BackgroundTransparency = 1
		sub.Text = s.Sub
		sub.TextScaled = true
		sub.Font = Enum.Font.Gotham
		sub.TextColor3 = rgb(150, 230, 245)
		sub.Parent = gui
	end
end

---------------------------------------------------------------------

function NacaraBuilder.sites()
	local plazaModel = model("Nacara_Plaza")
	local steps = {
		function()
			plaza(plazaModel)
			fountain(plazaModel)
		end,
		function()
			local arches = model("Nacara_Arcos")
			for _, item in Nacara.Layout do
				if item.Kind == "Arch" then
					kelpArch(arches, item)
				end
			end
		end,
		function()
			local index = 0
			for _, item in Nacara.Layout do
				if item.Kind == "Tower" then
					index += 1
					tower(model("Nacara_" .. item.Id), item, index)
				end
			end
		end,
		function()
			local homes = model("Nacara_Conchas")
			for _, item in Nacara.Layout do
				if item.Kind == "Shell" then
					shellHouse(homes, item)
				elseif item.Kind == "Terrace" then
					terrace(homes, item)
				end
			end
			ramps(homes)
		end,
		function()
			lamps(model("Nacara_Farolas"))
		end,
		function()
			kelpRing(model("Nacara_Kelp"))
		end,
		function()
			local market = model("Nacara_LonjaHonda")
			dome(market)
			for _, s in Nacara.Stalls do
				stall(market, s)
			end
		end,
		function()
			local signs = model("Nacara_Carteles")
			for _, s in Nacara.Signs do
				sign(signs, s)
			end
		end,
	}
	for _, fn in steps do
		local ok, err = pcall(fn)
		if not ok then
			warn("[NacaraBuilder] " .. tostring(err))
		end
	end
	NacaraBuilder.Stats.Parts = parts
	NacaraBuilder.Stats.Lights = lights
end

-- Construye todo (una vez). terrain = workspace.Terrain (o un doble en las pruebas)
function NacaraBuilder.build(terrain: any?)
	if NacaraBuilder.State ~= "None" then
		return
	end
	NacaraBuilder.State = "Building"
	local started = os.clock()
	local ok, err = pcall(NacaraBuilder.terrain, terrain or workspace.Terrain)
	if not ok then
		warn("[NacaraBuilder] terreno: " .. tostring(err))
	end
	NacaraBuilder.sites()
	NacaraBuilder.State = "Ready"
	NacaraBuilder.Stats.Seconds = os.clock() - started
	workspace:SetAttribute("NacaraReady", true)
	print(("[NacaraBuilder] Nácara (plaza de prueba) lista: %d piezas, %d luces, %d modelos, %.2f s"):format(parts, lights, NacaraBuilder.Stats.Models, NacaraBuilder.Stats.Seconds))
end

-- (pruebas) vuelve a empezar
function NacaraBuilder._reset()
	parts, lights = 0, 0
	NacaraBuilder.State = "None"
	NacaraBuilder.Stats = { Parts = 0, Lights = 0, Models = 0, Fills = 0, Seconds = 0 }
end

local _ = Ocean
return NacaraBuilder
