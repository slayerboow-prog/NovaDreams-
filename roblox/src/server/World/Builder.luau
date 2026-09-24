-- Builder: pequeñas herramientas para construir el mundo con Parts desde código.
-- Así el mapa entero vive en GitHub y no hace falta construirlo a mano en Studio.

local CollectionService = game:GetService("CollectionService")

local Builder = {}

-- Crea un Part anclado. Acepta cualquier propiedad de Part, más:
--   Tags = { "Tag1", ... }         -> etiquetas de CollectionService
--   Attributes = { Clave = valor } -> atributos
function Builder.part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "Parent" and key ~= "Tags" and key ~= "Attributes" then
			(p :: any)[key] = value
		end
	end
	if props.Tags then
		for _, tag in props.Tags do
			CollectionService:AddTag(p, tag)
		end
	end
	if props.Attributes then
		for name, value in props.Attributes do
			p:SetAttribute(name, value)
		end
	end
	p.Parent = props.Parent
	return p
end

function Builder.model(name: string, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Cartel con texto pegado a una cara del Part.
function Builder.sign(
	target: BasePart,
	text: string,
	face: Enum.NormalId?,
	textColor: Color3?,
	background: Color3?
): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = target

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = background or Color3.fromRGB(20, 24, 32)
	label.BackgroundTransparency = if background then 0 else 1
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.05, 0)
	padding.PaddingRight = UDim.new(0.05, 0)
	padding.PaddingTop = UDim.new(0.1, 0)
	padding.PaddingBottom = UDim.new(0.1, 0)
	padding.Parent = label

	return label
end

function Builder.prompt(parent: Instance, action: string, object: string?, hold: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object or ""
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

export type BuildingParams = {
	Name: string,
	Parent: Instance,
	-- Centro del edificio a nivel del suelo. La puerta mira hacia LookVector.
	CFrame: CFrame,
	Size: Vector3, -- X = ancho, Y = alto, Z = fondo
	WallColor: Color3,
	WallMaterial: Enum.Material?,
	RoofColor: Color3?,
	FloorColor: Color3?,
	FloorMaterial: Enum.Material?,
	Sign: string?,
	SignColor: Color3?,
	LightColor: Color3?,
}

-- Construye un edificio hueco (4 paredes con puerta, suelo, techo, luz y cartel).
-- Devuelve el Model y una función at(x, y, z) para colocar cosas dentro
-- usando coordenadas locales: -Z es la fachada (puerta), +Z el fondo.
function Builder.building(params: BuildingParams): (Model, (number, number, number) -> CFrame)
	local model = Builder.model(params.Name, params.Parent)
	local origin = params.CFrame
	local W, H, D = params.Size.X, params.Size.Y, params.Size.Z
	local T = 1 -- grosor de pared
	local doorW, doorH = 8, 10

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	local wall = {
		Color = params.WallColor,
		Material = params.WallMaterial or Enum.Material.SmoothPlastic,
		Parent = model,
	}
	local function wallPart(name: string, size: Vector3, cf: CFrame)
		local props = table.clone(wall)
		props.Name = name
		props.Size = size
		props.CFrame = cf
		return Builder.part(props)
	end

	-- Suelo
	Builder.part({
		Name = "Floor",
		Size = Vector3.new(W, 0.4, D),
		CFrame = at(0, 0.2, 0),
		Color = params.FloorColor or Color3.fromRGB(190, 170, 140),
		Material = params.FloorMaterial or Enum.Material.WoodPlanks,
		Parent = model,
	})

	-- Paredes
	wallPart("WallBack", Vector3.new(W, H, T), at(0, H / 2, D / 2 - T / 2))
	wallPart("WallLeft", Vector3.new(T, H, D), at(-W / 2 + T / 2, H / 2, 0))
	wallPart("WallRight", Vector3.new(T, H, D), at(W / 2 - T / 2, H / 2, 0))
	local sideW = (W - doorW) / 2
	wallPart("WallFrontL", Vector3.new(sideW, H, T), at(-(doorW / 2 + sideW / 2), H / 2, -D / 2 + T / 2))
	wallPart("WallFrontR", Vector3.new(sideW, H, T), at(doorW / 2 + sideW / 2, H / 2, -D / 2 + T / 2))
	wallPart("WallFrontTop", Vector3.new(doorW, H - doorH, T), at(0, doorH + (H - doorH) / 2, -D / 2 + T / 2))

	-- Ventanas decorativas en la fachada
	for _, side in { -1, 1 } do
		Builder.part({
			Name = "Window",
			Size = Vector3.new(math.min(sideW * 0.6, 10), H * 0.35, T + 0.3),
			CFrame = at(side * (doorW / 2 + sideW / 2), H * 0.5, -D / 2 + T / 2),
			Color = Color3.fromRGB(150, 200, 230),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
			Reflectance = 0.2,
			CanCollide = false,
			Parent = model,
		})
	end

	-- Techo
	local roof = Builder.part({
		Name = "Roof",
		Size = Vector3.new(W + 2, 1, D + 2),
		CFrame = at(0, H + 0.5, 0),
		Color = params.RoofColor or Color3.fromRGB(80, 80, 90),
		Parent = model,
	})

	-- Luz interior
	local light = Instance.new("PointLight")
	light.Range = math.max(W, D) * 0.9
	light.Brightness = 1.2
	light.Color = params.LightColor or Color3.fromRGB(255, 236, 205)
	light.Shadows = true
	light.Parent = Builder.part({
		Name = "CeilingLamp",
		Size = Vector3.new(3, 0.3, 3),
		CFrame = at(0, H - 0.2, 0),
		Color = Color3.fromRGB(255, 245, 220),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})

	-- Cartel sobre la puerta
	if params.Sign then
		local signPart = Builder.part({
			Name = "Sign",
			Size = Vector3.new(math.min(W * 0.7, 30), 3.5, 0.4),
			CFrame = at(0, doorH + 2.5, -D / 2 - 0.3),
			Color = params.SignColor or Color3.fromRGB(30, 34, 46),
			CanCollide = false,
			Parent = model,
		})
		Builder.sign(signPart, params.Sign, Enum.NormalId.Front)
	end

	model.PrimaryPart = roof
	return model, at
end

return Builder
