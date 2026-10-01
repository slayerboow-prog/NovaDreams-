-- Nature: árboles, palmeras, cipreses, arbustos, setos y parterres de flores.

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local AssetLibrary = require(script.Parent.AssetLibrary)

local Nature = {}

local C = Palette.Nature

local function leafColor(): Color3
	return Palette.pick(C.Leaves)
end

-- Árbol de hoja ancha: tronco que se estrecha, raíces, 2-4 ramas principales y una copa frondosa
-- hecha de muchos racimos (bolas y bloques girados, cada uno con su tono de verde).
--
--   * Los racimos principales (núcleo, punta de cada rama y copete) dan la silueta; los de relleno
--     llevan la etiqueta LeafDetail y, con el nivel gráfico Bajo, el cliente los esconde
--     (Controllers/MaterialDetail): el árbol sigue entero pero se pintan la mitad de piezas.
--   * Las raíces también son detalle (LeafDetail). El tronco choca; ramas, raíces y copa no.
--   * La forma sale de un Random propio con semilla en la posición: el mismo sitio da siempre el
--     mismo árbol y no se gastan números de math.random (no cambia el resto de la ciudad al azar).
local DARK_LEAF = Color3.fromRGB(34, 56, 32)
local SUN_LEAF = Color3.fromRGB(150, 168, 88)
local WARM_LEAF = Color3.fromRGB(128, 150, 70)
local COOL_LEAF = Color3.fromRGB(52, 96, 62)

-- Generador de números al azar con semilla (Park-Miller; como Random de Roblox, pero también
-- funciona al construir el mapa con Lune, que no trae Random)
type Rng = { NextNumber: (Rng, number?, number?) -> number, NextInteger: (Rng, number, number) -> number, s: number }
local RngClass = {}
RngClass.__index = RngClass
function RngClass.NextNumber(self: Rng, a: number?, b: number?): number
	self.s = (self.s * 16807) % 2147483647
	local x = (self.s - 1) / 2147483646
	if a and b then
		return a + (b - a) * x
	end
	return x
end
function RngClass.NextInteger(self: Rng, a: number, b: number): number
	return math.min(b, a + math.floor(self:NextNumber() * (b - a + 1)))
end

local function treeRandom(base: Vector3): Rng
	local seed = math.floor(math.abs(base.X * 7.31 + base.Z * 13.17 + base.Y * 3.7) * 10) % 2147483646 + 1
	local rng = setmetatable({ s = seed }, RngClass) :: any
	rng:NextNumber() -- (los primeros números de semillas parecidas se parecen: se descarta uno)
	rng:NextNumber()
	return rng
end

-- Un racimo de hojas: bola o bloque girado, con su tono (más oscuro abajo, más claro arriba)
local function cluster(m: Instance, rng: Rng, center: Vector3, d: number, tone: Color3, shade: number, pivot: Vector3, detail: boolean, block: boolean)
	local color = tone:Lerp(DARK_LEAF, 0.3 * (1 - shade)):Lerp(SUN_LEAF, 0.22 * shade)
	color = color:Lerp(if rng:NextNumber() < 0.5 then WARM_LEAF else COOL_LEAF, rng:NextNumber() * 0.18)
	local tags = { "Sway" } -- la copa se mece con el viento (Controllers/ObjectMotion)
	if detail then
		table.insert(tags, "LeafDetail")
	end
	local leaves = Builder.decor({
		Name = "Leaves",
		Shape = if block then Enum.PartType.Block else Enum.PartType.Ball,
		Size = if block then Vector3.new(d, d * 0.72, d * 0.9) else Vector3.new(d, d, d),
		CFrame = CFrame.new(center) * (if block
			then CFrame.Angles(rng:NextNumber(-0.7, 0.7), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.7, 0.7))
			else CFrame.identity),
		Color = color,
		Material = Enum.Material.LeafyGrass,
		Tags = tags,
		Attributes = { Pivot = pivot },
		Parent = m,
	})
	leaves.CastShadow = d >= 2.5 -- la copa da sombra (solo los racimos que se notan)
	return leaves
end

function Nature.tree(parent: Instance, base: Vector3, scale: number?)
	local asset = AssetLibrary.spawn("Tree", parent, CFrame.new(base) * CFrame.Angles(0, math.random() * math.pi * 2, 0), scale)
	if asset then
		return asset
	end
	local rng = treeRandom(base)
	local s = scale or (0.85 + rng:NextNumber() * 0.4)
	local m = Builder.model("Tree", parent)
	local height = (8 + rng:NextNumber() * 2.5) * s
	-- Tronco un poco inclinado (ningún árbol crece perfectamente recto)
	local lean = CFrame.Angles(math.rad(rng:NextInteger(-5, 5)), rng:NextNumber() * math.pi * 2, math.rad(rng:NextInteger(-5, 5)))
	local foot = CFrame.new(base) * lean
	-- Tronco en dos tramos: abajo más grueso, arriba más fino (se estrecha hacia la copa)
	local lowH, topH = height * 0.58, height * 0.5
	Builder.part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(lowH, 1.35 * s, 1.35 * s),
		CFrame = foot * CFrame.new(0, lowH / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Trunk,
		Material = Enum.Material.Wood,
		Parent = m,
	})
	Builder.part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(topH, 0.95 * s, 0.95 * s),
		CFrame = foot * CFrame.new(0, height - topH / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Trunk:Lerp(Color3.fromRGB(90, 70, 52), 0.3),
		Material = Enum.Material.Wood,
		CanQuery = false,
		Parent = m,
	})
	-- Raíces: el pie del tronco se abre hacia el suelo (no chocan; detalle)
	if rng:NextNumber() < 0.65 then
		local roots = rng:NextInteger(2, 3)
		local yaw0 = rng:NextNumber() * math.pi * 2
		for i = 1, roots do
			local yaw = yaw0 + i * math.pi * 2 / roots + rng:NextNumber(-0.4, 0.4)
			Builder.decor({
				Name = "Root",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(2 * s, 0.55 * s, 0.55 * s),
				CFrame = CFrame.new(base) * CFrame.Angles(0, yaw, 0) * CFrame.new(0.75 * s, 0.25 * s, 0) * CFrame.Angles(0, 0, math.rad(-22)),
				Color = C.Trunk:Lerp(Color3.fromRGB(70, 58, 44), 0.35),
				Material = Enum.Material.Wood,
				Tags = { "LeafDetail" },
				Parent = m,
			})
		end
	end
	-- Ramas principales: salen del tronco hacia arriba y hacia fuera; en su punta va un racimo grande
	local top = (foot * CFrame.new(0, height, 0)).Position
	local up = foot.UpVector
	local tone = leafColor()
	local tips: { Vector3 } = {}
	local branches = if s > 1.05 then rng:NextInteger(3, 4) else rng:NextInteger(2, 3)
	local yaw0 = rng:NextNumber() * math.pi * 2
	for i = 1, branches do
		local yaw = yaw0 + i * math.pi * 2 / branches + rng:NextNumber(-0.35, 0.35)
		local rise = math.rad(rng:NextInteger(35, 55)) -- ángulo sobre la horizontal
		local length = (3.4 + rng:NextNumber() * 1.6) * s
		local from = foot * CFrame.new(0, height * rng:NextNumber(0.55, 0.78), 0) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, rise)
		Builder.decor({ Name = "Branch", Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, 0.55 * s, 0.55 * s), CFrame = from * CFrame.new(length / 2, 0, 0), Color = C.Trunk, Material = Enum.Material.Wood, Parent = m })
		table.insert(tips, (from * CFrame.new(length, 0, 0)).Position)
	end
	-- Copa: núcleo grande, un racimo en la punta de cada rama, copete y relleno alrededor.
	-- Cuántos racimos, según el tamaño del árbol (8 a 16).
	local total = math.clamp(math.floor(8 + (s - 0.8) * 12 + rng:NextInteger(0, 2)), 8, 16)
	local crown = top + up * (1.4 * s)
	local made = 0
	local function add(center: Vector3, d: number, detail: boolean, block: boolean)
		local shade = math.clamp(0.5 + (center - crown):Dot(up) / (4 * s), 0, 1)
		cluster(m, rng, center, d, tone, shade, top, detail, block)
		made += 1
	end
	add(crown, (6.6 + rng:NextNumber()) * s, false, false)
	for _, tip in tips do
		add(tip + up * (0.9 * s), (4.4 + rng:NextNumber() * 1.3) * s, false, false)
	end
	add(crown + up * ((2.4 + rng:NextNumber()) * s) + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * s, (4.4 + rng:NextNumber()) * s, false, rng:NextNumber() < 0.3)
	-- Relleno: racimos más pequeños repartidos por la superficie de la copa
	while made < total do
		local a = rng:NextNumber() * math.pi * 2
		local y = rng:NextNumber(-0.55, 1)
		local r = (3 + rng:NextNumber() * 1.2) * s * math.sqrt(1 - y * y * 0.6)
		local center = crown + Vector3.new(math.cos(a) * r, y * 2.6 * s, math.sin(a) * r)
		add(center, (2.8 + rng:NextNumber() * 1.6) * s, true, rng:NextNumber() < 0.4)
	end
	return m
end

-- Ciprés mediterráneo: alto y estrecho. Copa en forma de llama hecha de varios husos (elipsoides)
-- apilados y algo desplazados, cada uno con su tono: ya no es un único bloque liso.
function Nature.cypress(parent: Instance, base: Vector3)
	local asset = AssetLibrary.spawn("Pine", parent, CFrame.new(base) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	if asset then
		return asset
	end
	local m = Builder.model("Cypress", parent)
	local rng = treeRandom(base)
	local s = 0.9 + rng:NextNumber() * 0.3
	Builder.part({ Name = "Trunk", Size = Vector3.new(0.8, 2, 0.8), CFrame = CFrame.new(base + Vector3.new(0, 1, 0)), Color = C.Trunk, Material = Enum.Material.Wood, Parent = m })
	local color = Color3.fromRGB(46, 78, 46):Lerp(Color3.fromRGB(64, 92, 54), rng:NextNumber())
	local tall = (9 + rng:NextNumber() * 3) * s
	local foot = base + Vector3.new(0, 1.2, 0)
	-- { ancho, alto, altura del centro (fracción de la copa), detalle }
	local shapes = {
		{ 4.2, tall * 0.62, 0.34, false },
		{ 3.6, tall * 0.5, 0.6, false },
		{ 2.6, tall * 0.36, 0.84, false },
		{ 3, tall * 0.34, 0.3, true },
		{ 2.6, tall * 0.3, 0.55, true },
	}
	for i, shape in shapes do
		local a = rng:NextNumber() * math.pi * 2
		local off = if shape[4] then 0.9 * s else 0.15 * s
		local shade = shape[3]
		local leaves = Builder.decor({
			Name = "Leaves",
			Size = Vector3.new(shape[1] * s, shape[2], shape[1] * s),
			CFrame = CFrame.new(foot + Vector3.new(math.cos(a) * off, tall * shape[3], math.sin(a) * off)),
			Color = color:Lerp(Color3.fromRGB(30, 52, 34), 0.25 * (1 - shade)):Lerp(Color3.fromRGB(120, 140, 80), 0.15 * shade + rng:NextNumber() * 0.06),
			Material = Enum.Material.LeafyGrass,
			Tags = if shape[4] then { "Sway", "LeafDetail" } else { "Sway" },
			Attributes = { Pivot = foot },
			Parent = m,
		})
		leaves.CastShadow = i <= 3
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere -- rellena la caja de la pieza: un elipsoide
		mesh.Parent = leaves
	end
	return m
end

-- Palmera: tronco curvado en segmentos + hojas colgantes
function Nature.palm(parent: Instance, base: Vector3)
	local asset = AssetLibrary.spawn("Palm", parent, CFrame.new(base) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	if asset then
		return asset
	end
	local m = Builder.model("Palm", parent)
	local lean = math.rad(math.random(-8, 8))
	local yaw = math.rad(math.random(0, 359))
	local cf = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
	for i = 1, 5 do
		local seg = 3.2
		cf = cf * CFrame.Angles(lean, 0, 0)
		Builder.part({
			Name = "Trunk",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(seg + 0.2, 1.1 - i * 0.08, 1.1 - i * 0.08),
			CFrame = cf * CFrame.new(0, seg / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = C.PalmTrunk,
			Material = Enum.Material.Wood,
			Parent = m,
		})
		cf = cf * CFrame.new(0, seg, 0)
	end
	local top = cf.Position
	-- Hojas en dos tramos: suben un poco y luego caen (como una palmera de verdad)
	for i = 1, 8 do
		local yawLeaf = CFrame.Angles(0, math.rad(i * 45 + math.random(-12, 12)), 0)
		local color = Color3.fromRGB(70, 118, 54):Lerp(Color3.fromRGB(116, 142, 70), math.random())
		local inner = CFrame.new(top) * yawLeaf * CFrame.Angles(math.rad(14 + math.random(0, 10)), 0, 0)
		Builder.decor({ Name = "Frond", Size = Vector3.new(1.9, 0.15, 4.4), CFrame = inner * CFrame.new(0, 0, -2.1), Color = color, Material = Enum.Material.Grass, Tags = { "Sway" }, Attributes = { Pivot = top, Leaf = true }, Parent = m })
		local outer = inner * CFrame.new(0, 0, -4.1) * CFrame.Angles(math.rad(-48), 0, 0)
		Builder.decor({ Name = "Frond", Size = Vector3.new(1.4, 0.12, 4.4), CFrame = outer * CFrame.new(0, 0, -2), Color = color:Lerp(Color3.fromRGB(150, 150, 80), 0.2), Material = Enum.Material.Grass, Tags = { "Sway" }, Attributes = { Pivot = top, Leaf = true }, Parent = m })
	end
	for i = 1, 3 do
		Builder.decor({
			Name = "Coconut",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.8, 0.8, 0.8),
			CFrame = CFrame.new(top + Vector3.new(math.cos(i * 2.1) * 0.6, -0.6, math.sin(i * 2.1) * 0.6)),
			Color = Color3.fromRGB(110, 84, 50),
			Tags = { "Sway" },
			Attributes = { Pivot = top },
			Parent = m,
		})
	end
	return m
end

function Nature.bush(parent: Instance, base: Vector3, size: number?)
	local model = AssetLibrary.spawn("Bush", parent, CFrame.new(base) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	if model then
		model.Name = "Bush" -- así el cliente sabe que es un arbusto (se aparta al pasar)
		return
	end
	local d = size or (2.5 + math.random() * 1.5)
	Builder.decor({
		Name = "Bush",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(d, d * 0.8, d),
		CFrame = CFrame.new(base + Vector3.new(0, d * 0.3, 0)),
		Color = leafColor():Lerp(C.Hedge, 0.5),
		Material = Enum.Material.LeafyGrass,
		Parent = parent,
	})
end

-- Piedra pequeña en el suelo: si pasas corriendo encima, tropiezas (ReactMotion en el cliente)
function Nature.stone(parent: Instance, base: Vector3, size: number?)
	local d = size or (0.8 + math.random() * 0.7)
	return Builder.part({
		Name = "Piedra",
		Size = Vector3.new(d * 1.3, d * 0.7, d),
		CFrame = CFrame.new(base + Vector3.new(0, d * 0.3, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, math.rad(math.random(-10, 10))),
		Color = Color3.fromRGB(120 + math.random(-12, 12), 116 + math.random(-12, 12), 108 + math.random(-12, 12)),
		Material = if math.random() < 0.5 then Enum.Material.Slate else Enum.Material.Rock,
		Tags = { "Piedra" },
		Parent = parent,
	})
end

-- Seto recto entre dos puntos (a nivel del suelo)
function Nature.hedge(parent: Instance, from: Vector3, to: Vector3, height: number?)
	local h = height or 3
	local length = (to - from).Magnitude
	Builder.part({
		Name = "Hedge",
		Size = Vector3.new(1.6, h, length),
		CFrame = Builder.facing((from + to) / 2, to - from) * CFrame.new(0, h / 2, 0),
		Color = C.Hedge,
		Material = Enum.Material.LeafyGrass,
		Parent = parent,
	})
end

-- Parterre: jardinera de piedra con flores
function Nature.flowerBed(parent: Instance, cf: CFrame, width: number, depth: number)
	local m = Builder.model("FlowerBed", parent)
	Builder.part({ Name = "Border", Size = Vector3.new(width, 1.2, depth), CFrame = cf * CFrame.new(0, 0.6, 0), Color = Color3.fromRGB(206, 196, 178), Material = Enum.Material.Limestone, Parent = m })
	Builder.decor({ Name = "Soil", Size = Vector3.new(width - 0.8, 0.2, depth - 0.8), CFrame = cf * CFrame.new(0, 1.25, 0), Color = Color3.fromRGB(92, 66, 46), Material = Enum.Material.Ground, Parent = m })
	local count = math.floor(width * depth / 5)
	for _ = 1, count do
		local x = (math.random() - 0.5) * (width - 1.4)
		local z = (math.random() - 0.5) * (depth - 1.4)
		Builder.decor({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.9, 0.9, 0.9),
			CFrame = cf * CFrame.new(x, 1.7, z),
			Color = Palette.pick(C.Flowers),
			Material = Enum.Material.SmoothPlastic,
			Parent = m,
		})
	end
	return m
end

return Nature
