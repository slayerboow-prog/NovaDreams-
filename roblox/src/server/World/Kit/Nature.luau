-- Nature: árboles, palmeras, cipreses, arbustos, setos y parterres de flores.

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)
local AssetLibrary = require(script.Parent.AssetLibrary)

local Nature = {}

local C = Palette.Nature

local function leafColor(): Color3
	return Palette.pick(C.Leaves)
end

-- Árbol de hoja ancha: tronco + copa de varias esferas
function Nature.tree(parent: Instance, base: Vector3, scale: number?)
	local asset = AssetLibrary.spawn("Tree", parent, CFrame.new(base) * CFrame.Angles(0, math.random() * math.pi * 2, 0), scale)
	if asset then
		return asset
	end
	local s = scale or (0.85 + math.random() * 0.4)
	local m = Builder.model("Tree", parent)
	local height = (8 + math.random() * 2.5) * s
	-- Tronco un poco inclinado (ningún árbol crece perfectamente recto)
	local lean = CFrame.Angles(math.rad(math.random(-5, 5)), math.random() * math.pi * 2, math.rad(math.random(-5, 5)))
	local foot = CFrame.new(base) * lean
	Builder.part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.3 * s, 1.3 * s),
		CFrame = foot * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Trunk,
		Material = Enum.Material.Wood,
		Parent = m,
	})
	-- Dos ramas que salen hacia la copa
	for i = 1, 2 do
		local yaw = math.rad(i * 180 + math.random(-40, 40))
		local branch = foot * CFrame.new(0, height * 0.62, 0) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, math.rad(-50)) * CFrame.new(1.6 * s, 0, 0)
		Builder.decor({ Name = "Branch", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.4 * s, 0.6 * s, 0.6 * s), CFrame = branch, Color = C.Trunk, Material = Enum.Material.Wood, Parent = m })
	end
	-- Copa: bolas de distinto tamaño colocadas al azar (cada árbol es distinto). Las de abajo, más
	-- oscuras y las de arriba, más claras: parece que les da el sol desde arriba.
	local top = (foot * CFrame.new(0, height, 0)).Position
	local crown = Vector3.new(top.X, top.Y + 1.2 * s, top.Z)
	local leafTone = leafColor()
	local blobs = math.random(5, 7)
	for i = 1, blobs do
		local d = (i == 1 and 9 or (5.5 + math.random() * 3)) * s
		local a = math.random() * math.pi * 2
		local r = i == 1 and 0 or (2 + math.random() * 1.6) * s
		local y = i == 1 and 1.4 * s or (math.random() * 3 - 1.2) * s
		local shade = math.clamp(0.5 + y / (4 * s), 0, 1)
		Builder.decor({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(d, d, d),
			CFrame = CFrame.new(crown + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)),
			Color = leafTone:Lerp(Color3.fromRGB(34, 56, 32), 0.25 * (1 - shade)):Lerp(Color3.fromRGB(150, 168, 88), 0.18 * shade),
			Material = Enum.Material.LeafyGrass,
			Parent = m,
		})
	end
	return m
end

-- Ciprés mediterráneo: alto y estrecho
function Nature.cypress(parent: Instance, base: Vector3)
	local asset = AssetLibrary.spawn("Pine", parent, CFrame.new(base) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	if asset then
		return asset
	end
	local m = Builder.model("Cypress", parent)
	local s = 0.9 + math.random() * 0.3
	Builder.part({ Name = "Trunk", Size = Vector3.new(0.8, 2, 0.8), CFrame = CFrame.new(base + Vector3.new(0, 1, 0)), Color = C.Trunk, Material = Enum.Material.Wood, Parent = m })
	-- Copa en forma de llama: un elipsoide (SpecialMesh de esfera) y una punta más estrecha encima
	local color = Color3.fromRGB(46, 78, 46):Lerp(Color3.fromRGB(64, 92, 54), math.random())
	local tall = (9 + math.random() * 3) * s
	for i, shape in { { 4.2, tall, 0 }, { 2.8, tall * 0.45, tall * 0.42 } } do
		local leaves = Builder.decor({
			Name = "Leaves",
			Size = Vector3.new(shape[1] * s, shape[2], shape[1] * s),
			CFrame = CFrame.new(base + Vector3.new(0, 1.2 + tall / 2 + shape[3], 0)),
			Color = if i == 1 then color else color:Lerp(Color3.fromRGB(120, 140, 80), 0.15),
			Material = Enum.Material.LeafyGrass,
			Parent = m,
		})
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
		Builder.decor({ Name = "Frond", Size = Vector3.new(1.9, 0.15, 4.4), CFrame = inner * CFrame.new(0, 0, -2.1), Color = color, Material = Enum.Material.Grass, Parent = m })
		local outer = inner * CFrame.new(0, 0, -4.1) * CFrame.Angles(math.rad(-48), 0, 0)
		Builder.decor({ Name = "Frond", Size = Vector3.new(1.4, 0.12, 4.4), CFrame = outer * CFrame.new(0, 0, -2), Color = color:Lerp(Color3.fromRGB(150, 150, 80), 0.2), Material = Enum.Material.Grass, Parent = m })
	end
	for i = 1, 3 do
		Builder.decor({
			Name = "Coconut",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.8, 0.8, 0.8),
			CFrame = CFrame.new(top + Vector3.new(math.cos(i * 2.1) * 0.6, -0.6, math.sin(i * 2.1) * 0.6)),
			Color = Color3.fromRGB(110, 84, 50),
			Parent = m,
		})
	end
	return m
end

function Nature.bush(parent: Instance, base: Vector3, size: number?)
	if AssetLibrary.spawn("Bush", parent, CFrame.new(base) * CFrame.Angles(0, math.random() * math.pi * 2, 0)) then
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
