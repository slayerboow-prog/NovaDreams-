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
	local height = 9 * s
	Builder.part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.3 * s, 1.3 * s),
		CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Trunk,
		Material = Enum.Material.Wood,
		Parent = m,
	})
	local crownY = base.Y + height + 1.5 * s
	local blobs = {
		{ Vector3.new(0, 1.5, 0), 9 },
		{ Vector3.new(2.6, 0, 1.2), 7 },
		{ Vector3.new(-2.4, 0.3, -1.4), 7 },
		{ Vector3.new(0.8, -0.6, -2.6), 6.5 },
		{ Vector3.new(-1.2, -0.4, 2.6), 6.5 },
	}
	local color = leafColor()
	for _, b in blobs do
		local d = b[2] * s
		Builder.decor({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(d, d, d),
			CFrame = CFrame.new(Vector3.new(base.X, crownY, base.Z) + b[1] * s),
			Color = color:Lerp(leafColor(), 0.4),
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
	local color = Color3.fromRGB(46, 84, 48)
	for i, d in { 4.2, 3.9, 3.4, 2.7, 1.8 } do
		Builder.decor({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(d, d, d) * s,
			CFrame = CFrame.new(base + Vector3.new(0, (1.6 + i * 2.4) * s, 0)),
			Color = color,
			Material = Enum.Material.LeafyGrass,
			Parent = m,
		})
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
	for i = 1, 8 do
		local leaf = CFrame.new(top) * CFrame.Angles(0, math.rad(i * 45 + math.random(-10, 10)), 0) * CFrame.Angles(math.rad(-28), 0, 0) * CFrame.new(0, 0, -3.8)
		Builder.decor({
			Name = "Frond",
			Size = Vector3.new(1.8, 0.15, 8),
			CFrame = leaf,
			Color = Color3.fromRGB(78, 136, 60):Lerp(Color3.fromRGB(110, 150, 70), math.random()),
			Material = Enum.Material.Grass,
			Parent = m,
		})
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
