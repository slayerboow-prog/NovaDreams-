-- Builder: pequeñas herramientas para construir el mundo con Parts desde código.
-- Así el mapa entero vive en GitHub y no hace falta construirlo a mano en Studio.

local Builder = {}

-- Crea una pieza anclada. Acepta cualquier propiedad, más:
--   ClassName = "WedgePart" / "CornerWedgePart"... (por defecto "Part")
--   Tags = { "Tag1", ... }         -> etiquetas de CollectionService
--   Attributes = { Clave = valor } -> atributos
function Builder.part(props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "Parent" and key ~= "Tags" and key ~= "Attributes" and key ~= "ClassName" then
			(p :: any)[key] = value
		end
	end
	if props.Tags then
		for _, tag in props.Tags do
			p:AddTag(tag)
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

-- Pieza decorativa: sin colisiones ni consultas (más barata para el motor)
function Builder.decor(props: { [string]: any }): BasePart
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	-- Los detalles pequeños o planos no proyectan sombra: se nota poco y ahorra mucho
	local size = props.Size
	if size and (math.max(size.X, size.Y, size.Z) < 4 or math.min(size.X, size.Y, size.Z) < 0.2) then
		props.CastShadow = false
	end
	return Builder.part(props)
end

-- Optimiza un edificio para StreamingEnabled: se carga entero (sin medias fachadas)
-- y de lejos se ve una versión simplificada, lo que crea el horizonte urbano.
function Builder.streamable(model: Model)
	pcall(function()
		(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	pcall(function()
		(model :: any).LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh
	end)
end

-- CFrame en "position" mirando en horizontal hacia "direction".
-- (Usamos un giro en Y en vez de CFrame.lookAt: da el mismo resultado en Roblox
-- y también en Lune, que tiene un fallo con lookAt hacia +Z.)
function Builder.facing(position: Vector3, direction: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, math.atan2(-direction.X, -direction.Z), 0)
end

function Builder.model(name: string, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Cartel con texto pegado a una cara de la pieza.
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
	label.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
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

return Builder
