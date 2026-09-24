-- Theme: colores, fuentes y pequeñas funciones para crear la interfaz por código.

local Theme = {}

Theme.Colors = {
	Panel = Color3.fromRGB(16, 20, 28),
	PanelLight = Color3.fromRGB(32, 38, 50),
	Stroke = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(245, 247, 250),
	Muted = Color3.fromRGB(160, 170, 185),
	Accent = Color3.fromRGB(64, 156, 255),
	Money = Color3.fromRGB(90, 220, 120),
	Hunger = Color3.fromRGB(255, 150, 60),
	Energy = Color3.fromRGB(255, 215, 70),
	Error = Color3.fromRGB(255, 90, 90),
	Gold = Color3.fromRGB(255, 196, 60),
}

Theme.Font = Enum.Font.GothamMedium
Theme.FontBold = Enum.Font.GothamBold

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
	return Theme.create("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function Theme.stroke(transparency: number?): UIStroke
	return Theme.create("UIStroke", {
		Color = Theme.Colors.Stroke,
		Transparency = transparency or 0.88,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
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

-- Panel oscuro semitransparente con esquinas redondeadas
function Theme.panel(props: { [string]: any }): Frame
	local defaults = {
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}
	for key, value in props do
		defaults[key] = value
	end
	return Theme.create("Frame", defaults, { Theme.corner(), Theme.stroke() })
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
	return Theme.create("TextLabel", defaults)
end

function Theme.button(props: { [string]: any }): TextButton
	local defaults = {
		BackgroundColor3 = Theme.Colors.PanelLight,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Theme.FontBold,
		TextColor3 = Theme.Colors.Text,
		TextSize = 16,
	}
	for key, value in props do
		defaults[key] = value
	end
	return Theme.create("TextButton", defaults, { Theme.corner(10), Theme.stroke() })
end

return Theme
