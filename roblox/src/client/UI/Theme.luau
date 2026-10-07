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

-- ¿Solo pantalla táctil (móvil o tableta sin teclado)?
function Theme.isTouch(): boolean
	return TOUCH_ONLY
end

-- Móvil: un texto importante nunca por debajo de min (en unidades de su pantalla)
function Theme.touchText(label: TextLabel | TextButton, min: number)
	if TOUCH_ONLY and label.TextSize < min then
		label.TextSize = min
	end
end

-- Escala de las ventanas en el móvil (la de UI/Dialog): alto / 560 o ancho / 1000, nunca bajo 0.6
function Theme.touchWindowScale(viewport: Vector2?): number
	local view = viewport or workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(view.Y / 560, view.X / 1000), 0.6, 1.25)
end

-- Móvil: ventanas de pantallas con una escala pequeña (llaves, nevera, ascensor…) salían a 0.6 con el
-- ✖ de 20 px. Les pone su propio UIScale (encima del de su pantalla) hasta la escala de las ventanas de
-- UI/Dialog sin salirse, agranda el ✖ (`close`) a ~36 px en pantalla y devuelve el lado del ✖ en
-- unidades (para dejarle sitio debajo). En el ordenador solo hace el salto de abrir (si `animate`).
function Theme.touchWindow(frame: GuiObject, close: GuiObject?, animate: boolean?): number
	local screen = frame:FindFirstAncestorOfClass("ScreenGui")
	local outer = screen and screen:FindFirstChildOfClass("UIScale")
	local g = if outer and outer.Scale > 0 then outer.Scale else 1
	local k = 1
	if TOUCH_ONLY then
		local view = workspace.CurrentCamera.ViewportSize
		local size = frame.Size
		local w, h = math.max(size.X.Offset, 1), math.max(size.Y.Offset, 1)
		local want = math.min(Theme.touchWindowScale(view), (view.Y - 20) / h, (view.X - 24) / w)
		k = math.max(1, want / g)
	end
	local scale = frame:FindFirstChild("PressScale") :: UIScale?
	if not scale then
		scale = Theme.create("UIScale", { Name = "PressScale", Parent = frame })
	end
	local s = scale :: UIScale
	s:SetAttribute("Base", k)
	if animate then
		s.Scale = 0.85 * k
		TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = k }):Play()
	else
		s.Scale = k
	end
	local side = if close then close.Size.Y.Offset else 0
	if close and TOUCH_ONLY then
		side = math.max(close.Size.X.Offset, close.Size.Y.Offset, math.ceil(36 / (g * k)))
		close.Size = UDim2.fromOffset(side, side)
	end
	return side
end

-- Escala de una pantalla en el móvil: suelo 0.8 (con 0.6 los textos salían de 7-10 px), pero cada
-- ventana de tamaño fijo tiene que caber entera; si no, se baja lo justo (nunca de 0.5).
local function touchFitScale(gui: ScreenGui, base: number, viewport: Vector2): number
	local s = base
	for _, child in gui:GetChildren() do
		-- (los paneles de trabajo se recortan solos: UI/HudLayout.jobPanel)
		if child:IsA("GuiObject") and child:GetAttribute("JobPanel") == nil and child.Size.X.Scale == 0 and child.Size.Y.Scale == 0 then
			local w, h = child.Size.X.Offset, child.Size.Y.Offset
			if w > 0 and h > 0 then
				s = math.min(s, (viewport.Y - 70) / h, (viewport.X - 24) / w)
			end
		end
	end
	return math.max(s, 0.5)
end

-- Encoge una pantalla en móviles pequeños (los paneles tienen tamaño fijo en píxeles)
function Theme.fit(gui: ScreenGui)
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local camera = workspace.CurrentCamera
	local function rescale()
		local size = camera.ViewportSize
		if TOUCH_ONLY then
			scale.Scale = touchFitScale(gui, math.clamp(math.min(size.Y / 820, size.X / 1300), 0.8, 1), size)
		else
			scale.Scale = math.clamp(math.min(size.Y / 820, size.X / 1300), 0.6, 1)
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	if TOUCH_ONLY then
		-- Las ventanas se crean después: se vuelve a mirar si caben
		gui.ChildAdded:Connect(function()
			task.defer(rescale)
		end)
	end
	rescale()
end

-- Escala de las ventanas emergentes (minijuegos, clase, conversación, mochila): como antes en el
-- ordenador (alto / 850, suelo 0.65); en el móvil suelo 0.8 para leer bien, pero si alguna de las
-- ventanas vigiladas (con su margen de abajo, en unidades) no cabe, se reduce lo justo.
function Theme.popupScale(gui: ScreenGui, watched: { { Frame: GuiObject, Margin: number? } }?): UIScale
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local camera = workspace.CurrentCamera
	local list = watched or {}
	local function rescale()
		local view = camera.ViewportSize
		if not TOUCH_ONLY then
			scale.Scale = math.clamp(view.Y / 850, 0.65, 1.25)
			return
		end
		local s = math.clamp(view.Y / 850, 0.8, 1.25)
		for _, entry in list do
			local abs = entry.Frame.AbsoluteSize
			if typeof(abs) == "Vector2" and abs.Y > 0 and scale.Scale > 0 then
				-- tamaño "natural" (sin esta escala) de la ventana
				local natural = abs / scale.Scale
				s = math.min(s, (view.Y - 70) / (natural.Y + (entry.Margin or 0)), (view.X - 24) / natural.X)
			end
		end
		s = math.max(s, 0.5)
		-- (con margen: el tamaño en píxeles se redondea y no queremos que la escala baile)
		if math.abs(s - scale.Scale) > 0.01 then
			scale.Scale = s
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	if TOUCH_ONLY then
		for _, entry in list do
			entry.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
		end
	end
	rescale()
	return scale
end

---------------------------------------------------------------------
-- HUD de juego: paneles azul marino translúcidos con filo azul eléctrico que brilla
---------------------------------------------------------------------
local rgb = Color3.fromRGB
Theme.Hud = {
	Navy = rgb(6, 14, 36),
	NavyLight = rgb(18, 38, 84),
	Edge = rgb(60, 150, 255), -- filo azul eléctrico
	Glow = rgb(110, 225, 255), -- brillo cian
	Select = rgb(24, 104, 255), -- lo elegido: azul intenso
	SelectLight = rgb(96, 196, 255),
	Violet = rgb(146, 104, 255),
	Gold = rgb(255, 204, 72),
	Pink = rgb(255, 92, 170),
	Track = rgb(8, 14, 30),
}
-- Degradado del filo: cian arriba, azul y un toque violeta abajo
Theme.EdgeGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(150, 235, 255)),
	ColorSequenceKeypoint.new(0.5, rgb(60, 150, 255)),
	ColorSequenceKeypoint.new(1, rgb(130, 100, 255)),
})
-- Relleno de los paneles: un poco más claro arriba (brillo) y más oscuro abajo
Theme.PanelSheen = ColorSequence.new(rgb(255, 255, 255), rgb(150, 165, 200))

-- Filo brillante: el borde y, por fuera, un halo suave (dos UIStroke, sin imágenes)
function Theme.edge(parent: GuiObject, color: Color3?, thickness: number?): UIStroke
	local stroke = Theme.create("UIStroke", {
		Name = "Edge",
		Color = color or Color3.new(1, 1, 1),
		Thickness = thickness or 2,
		Transparency = 0.1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
	if not color then
		Theme.create("UIGradient", { Rotation = 90, Color = Theme.EdgeGradient, Parent = stroke })
	end
	return stroke
end

-- Halo: un marco un poco más grande, transparente, con un borde ancho y muy suave
function Theme.halo(parent: GuiObject, color: Color3?, spread: number?, radius: number?): Frame
	local grow = spread or 6
	local frame = Theme.create("Frame", {
		Name = "Halo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, grow, 1, grow),
		BackgroundTransparency = 1,
		ZIndex = parent.ZIndex,
		Parent = parent,
	}, {
		Theme.create("UICorner", { CornerRadius = if radius then UDim.new(0, radius) else UDim.new(0, 12) }),
		Theme.create("UIStroke", { Color = color or Theme.Hud.Glow, Thickness = grow, Transparency = 0.82 }),
	})
	return frame
end

-- Panel del HUD: azul marino translúcido (se ve el mundo), filo eléctrico y brillo arriba
function Theme.hudPanel(props: { [string]: any }): Frame
	local defaults = {
		BackgroundColor3 = Theme.Hud.Navy,
		BackgroundTransparency = 0.32,
		BorderSizePixel = 0,
	}
	for key, value in props do
		defaults[key] = value
	end
	local radius = defaults.CornerRadius or 12
	defaults.CornerRadius = nil
	local frame = Theme.create("Frame", defaults, {
		Theme.create("UICorner", { CornerRadius = UDim.new(0, radius) }),
		Theme.create("UIGradient", { Rotation = 90, Color = Theme.PanelSheen }),
	})
	Theme.skinEdge(Theme.edge(frame))
	return frame
end

---------------------------------------------------------------------
-- Acentos de los cosméticos del pase (tema del HUD y del teléfono). Solo cambian COLORES (el filo de
-- los paneles, el fondo de pantalla del ValPhone): nunca tamaños ni posiciones. nil = el aspecto de siempre.
-- Los pone UI/BattlePassCosmetics (solo con el pase encendido y con lo que el servidor dice que llevas).
---------------------------------------------------------------------
local accents: { [string]: Color3? } = {}
local accentListeners: { [string]: { (Color3?) -> () } } = {}
local skinnedEdges: { [UIStroke]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- Degradado del filo con el acento del tema del HUD (nil = el de siempre)
function Theme.edgeGradient(accent: Color3?): ColorSequence
	if not accent then
		return Theme.EdgeGradient
	end
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, accent:Lerp(Color3.new(1, 1, 1), 0.45)),
		ColorSequenceKeypoint.new(0.5, accent),
		ColorSequenceKeypoint.new(1, accent:Lerp(Theme.Hud.Violet, 0.35)),
	})
end

local function paintEdge(stroke: UIStroke)
	local gradient = stroke:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = Theme.edgeGradient(accents.Hud)
	end
end

-- El filo de un panel del HUD sigue el tema del HUD equipado
function Theme.skinEdge(stroke: UIStroke): UIStroke
	skinnedEdges[stroke] = true
	if accents.Hud then
		paintEdge(stroke)
	end
	return stroke
end

function Theme.accent(kind: string): Color3?
	return accents[kind]
end

-- kind: "Hud" (filo de los paneles) o "Phone" (el ValPhone: fondo de pantalla, UI/Phone)
function Theme.setAccent(kind: string, color: Color3?)
	if accents[kind] == color then
		return
	end
	accents[kind] = color
	if kind == "Hud" then
		for stroke in skinnedEdges do
			pcall(paintEdge, stroke)
		end
	end
	for _, fn in accentListeners[kind] or {} do
		pcall(fn, color)
	end
end

-- Avisa cuando cambia ese acento (y enseguida con el de ahora, si hay)
function Theme.onAccent(kind: string, fn: (Color3?) -> ())
	accentListeners[kind] = accentListeners[kind] or {}
	table.insert(accentListeners[kind], fn)
	if accents[kind] then
		pcall(fn, accents[kind])
	end
end

-- Esquinas en bisel (las muescas en ángulo del marco de referencia): dos trazos brillantes
function Theme.bevel(frame: GuiObject, color: Color3?)
	local c = color or Theme.Hud.Glow
	local z = frame.ZIndex + 1
	for _, corner in { { Vector2.new(0, 0), UDim2.fromOffset(10, -1) }, { Vector2.new(1, 1), UDim2.new(1, -10, 1, 1) } } do
		Theme.create("Frame", {
			Name = "Bevel",
			AnchorPoint = corner[1],
			Position = corner[2],
			Size = UDim2.fromOffset(34, 3),
			BackgroundColor3 = c,
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = frame,
		}, { Theme.create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
end

-- Micro-animaciones (rápidas: 0,12-0,25 s)
Theme.Fast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Theme.Slide = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function scalerOf(object: GuiObject): UIScale
	local scale = object:FindFirstChild("PressScale") :: UIScale?
	if not scale then
		scale = Theme.create("UIScale", { Name = "PressScale", Parent = object })
	end
	return scale :: UIScale
end

-- Tamaño base de un objeto (1 = normal). Un objeto solo admite un UIScale: así el salto y el pulsado
-- no le quitan el tamaño que se le haya dado (p. ej. ventanas del HUD agrandadas en el móvil).
local function baseOf(scale: UIScale): number
	local base = scale:GetAttribute("Base")
	return if type(base) == "number" then base else 1
end

function Theme.setBaseScale(object: GuiObject, value: number)
	local scale = scalerOf(object)
	scale:SetAttribute("Base", value)
	scale.Scale = value
end

-- Al pulsar se encoge un poco y vuelve al soltar
function Theme.pressable(button: GuiButton)
	local scale = scalerOf(button)
	button.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Gamepad1 then
			TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.9 * baseOf(scale) }):Play()
		end
	end)
	button.InputEnded:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = baseOf(scale) }):Play()
	end)
end

-- Salto rápido (crece y vuelve): dinero que sube, nivel nuevo, misión cumplida…
function Theme.pop(object: GuiObject, amount: number?)
	local scale = scalerOf(object)
	local base = baseOf(scale)
	scale.Scale = base
	TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), { Scale = (amount or 1.18) * base }):Play()
end

-- Aparece deslizándose un poco y con fundido (CanvasGroup) o solo deslizándose
function Theme.appear(object: GuiObject, from: UDim2?)
	local target = object.Position
	if from then
		object.Position = from
	end
	if object:IsA("CanvasGroup") then
		object.GroupTransparency = 1
		TweenService:Create(object, Theme.Slide, { GroupTransparency = 0, Position = target }):Play()
	else
		TweenService:Create(object, Theme.Slide, { Position = target }):Play()
	end
end

-- Cambia un texto solo si es distinto (escribir el mismo texto cada frame también cuesta)
function Theme.setText(label: TextLabel | TextButton, text: string)
	if label.Text ~= text then
		label.Text = text
	end
end

return Theme
