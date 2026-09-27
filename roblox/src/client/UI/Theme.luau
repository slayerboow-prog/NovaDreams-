-- Theme: colores, fuentes y pequeñas funciones para crear la interfaz por código.
--
-- Estilo "Kingdom Hearts 3": paneles azul noche con degradado y brillo arriba, borde fino azul
-- claro, títulos en negrita cursiva, y botones que se iluminan (blanco-cian) al pasar por encima
-- o al elegirlos con el mando. Todas las pantallas usan estas piezas, así que cambian a la vez.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = {}

Theme.Colors = {
	Panel = Color3.fromRGB(10, 22, 52),
	PanelLight = Color3.fromRGB(28, 62, 132),
	Stroke = Color3.fromRGB(150, 210, 255),
	Text = Color3.fromRGB(245, 249, 255),
	Muted = Color3.fromRGB(160, 184, 220),
	Accent = Color3.fromRGB(60, 160, 255),
	Highlight = Color3.fromRGB(200, 240, 255), -- lo elegido: blanco azulado
	Ink = Color3.fromRGB(8, 20, 50), -- texto oscuro sobre lo iluminado
	Money = Color3.fromRGB(110, 230, 120),
	Hunger = Color3.fromRGB(255, 196, 60),
	Energy = Color3.fromRGB(70, 150, 255),
	Health = Color3.fromRGB(90, 225, 90),
	Stamina = Color3.fromRGB(255, 150, 40),
	Error = Color3.fromRGB(255, 90, 90),
	Gold = Color3.fromRGB(255, 205, 70),
	Purple = Color3.fromRGB(180, 130, 255),
}

Theme.Font = Enum.Font.GothamMedium
Theme.FontBold = Enum.Font.GothamBold
-- Títulos: negrita cursiva (las cabeceras de los menús de KH3)
Theme.TitleFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
Theme.ItalicFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)

-- Degradados: el de "brillo" oscurece hacia abajo sin cambiar el color del panel (así sirve para
-- paneles de cualquier color); el de "elegido" es el blanco-cian de lo seleccionado.
Theme.Sheen = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(190, 200, 220)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 130, 160)),
})
Theme.Selected = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 205, 255))
-- Fondo de las ventanas grandes (mapa, mochila…): azul noche que se oscurece hacia abajo
Theme.Night = ColorSequence.new(Color3.fromRGB(30, 62, 132), Color3.fromRGB(6, 14, 38))

function Theme.create(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function Theme.corner(radius: number?): UICorner
	return Theme.create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

-- Borde azul claro, más brillante arriba (el filo de los menús de KH3)
function Theme.stroke(transparency: number?): UIStroke
	return Theme.create("UIStroke", {
		Color = Theme.Colors.Stroke,
		Transparency = transparency or 0.35,
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, {
		Theme.create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 170, 210)),
		}),
	})
end

function Theme.padding(px: number): UIPadding
	return Theme.create("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	})
end

local function sheen(): UIGradient
	return Theme.create("UIGradient", { Rotation = 90, Color = Theme.Sheen })
end

-- Panel azul noche semitransparente con brillo arriba y borde azul claro
function Theme.panel(props: { [string]: any }): Frame
	local defaults = {
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
	}
	for key, value in props do
		defaults[key] = value
	end
	return Theme.create("Frame", defaults, { Theme.corner(), Theme.stroke(), sheen() })
end

function Theme.label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextColor3 = Theme.Colors.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for key, value in props do
		defaults[key] = value
	end
	local face = defaults.FontFace
	defaults.FontFace = nil
	local label = Theme.create("TextLabel", defaults)
	if face then
		label.FontFace = face -- después de Font (si no, Font lo pisaría)
	end
	return label
end

-- Título en negrita cursiva
function Theme.title(props: { [string]: any }): TextLabel
	local label = Theme.label(props)
	label.FontFace = if props.Font then Font.fromEnum(props.Font) else Theme.TitleFace
	return label
end

-- Se ilumina al pasar el ratón o al elegirlo con el mando: borde blanco y un pequeño salto
local HOVER = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- (en pantallas táctiles no: allí no hay "pasar por encima" y se quedaría iluminado)
local TOUCH_ONLY = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
function Theme.hover(button: GuiButton, stroke: UIStroke?)
	if TOUCH_ONLY and not UserInputService.GamepadEnabled then
		return
	end
	local scale = Theme.create("UIScale", { Parent = button })
	local function set(on: boolean)
		TweenService:Create(scale, HOVER, { Scale = if on then 1.04 else 1 }):Play()
		if stroke then
			stroke.Color = if on then Theme.Colors.Highlight else Theme.Colors.Stroke
			stroke.Transparency = if on then 0 else 0.35
			stroke.Thickness = if on then 2 else 1.5
		end
	end
	button.MouseEnter:Connect(function()
		set(true)
	end)
	button.MouseLeave:Connect(function()
		set(false)
	end)
	button.SelectionGained:Connect(function()
		set(true)
	end)
	button.SelectionLost:Connect(function()
		set(false)
	end)
end

function Theme.button(props: { [string]: any }): TextButton
	local defaults = {
		BackgroundColor3 = Theme.Colors.PanelLight,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Theme.FontBold,
		TextColor3 = Theme.Colors.Text,
		TextSize = 16,
	}
	for key, value in props do
		defaults[key] = value
	end
	local stroke = Theme.stroke()
	local button = Theme.create("TextButton", defaults, { Theme.corner(6), stroke, sheen() })
	Theme.hover(button, stroke)
	return button
end

-- Encoge una pantalla en móviles pequeños (los paneles tienen tamaño fijo en píxeles)
function Theme.fit(gui: ScreenGui)
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local camera = workspace.CurrentCamera
	local function rescale()
		local size = camera.ViewportSize
		scale.Scale = math.clamp(math.min(size.Y / 820, size.X / 1300), 0.6, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
end

-- Cambia un texto solo si es distinto (escribir el mismo texto cada frame también cuesta)
function Theme.setText(label: TextLabel | TextButton, text: string)
	if label.Text ~= text then
		label.Text = text
	end
end

return Theme
