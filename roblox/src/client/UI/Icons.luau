-- Icons: todos los iconos de la interfaz en un solo sitio.
--
--   Icons.new("casa", { Size = …, Parent = … })  -> un marco con el icono dentro
--   Icons.set(icono, "luna")                      -> cambia el icono (p. ej. sol -> luna)
--   Icons.glyph("casa")                           -> el emoji de reserva (para textos y avisos)
--
-- Los iconos son de línea, blancos sobre transparente (assets/icons/*.svg). Cuando se suben a Roblox
-- con scripts/upload-icons.sh, sus ids quedan en UI/IconIds y se usan como imagen (se pueden teñir).
-- Mientras no estén subidos se usa un emoji: solo emojis antiguos (Unicode 9 o anterior), que se ven
-- en todos los móviles. Nada de "✦", "▸", "◂", "☰" ni "🪨": en muchos móviles salen como cajas vacías.
--
-- Las flechas, el más, el menos, el rombo y los puntos se dibujan con marcos (Icons.chevron…):
-- así nunca dependen de la fuente.

local Theme = require(script.Parent.Theme)
local IconIds = require(script.Parent.IconIds)

local create = Theme.create

local Icons = {}

-- Nombre -> emoji de reserva
Icons.Fallback = {
	casa = "🏠",
	tienda = "🛒",
	coche = "🚗",
	telefono = "📱",
	mapa = "🗺️",
	mochila = "🎒",
	espada = "⚔️",
	escudo = "🛡️",
	gestos = "😀",
	pesca = "🐟",
	mercadillo = "🛍️",
	hablar = "💬",
	interactuar = "✋",
	correr = "🏃",
	saltar = "⬆️",
	esquivar = "💨",
	objetivo = "🎯",
	rayo = "⚡",
	comida = "🍴",
	cara = "😊",
	corazon = "❤️",
	sol = "☀️",
	nube = "☁️",
	lluvia = "🌧️",
	tormenta = "⛈️",
	nieve = "🌨️",
	niebla = "🌫️",
	luna = "🌙",
	corona = "👑",
	flecha = "⬆️",
	mas = "➕",
	menos = "➖",
	linterna = "🔦",
	camara = "📷",
	piedra = "🥌", -- (🪨 no se ve en muchos móviles)
	bajarse = "⬇️",
	misiones = "📋",
	personaje = "⭐",
	menu = "⚙️",
	puerta = "🚪",
	escuela = "🏫",
	trabajo = "💼",
	cama = "🛏️",
	sirena = "🚨",
	dinero = "💵",
	mando = "🎮",
	bici = "🚲",
	asiento = "💺",
	lugar = "📍",
	saludar = "👋",
	robar = "💸",
	detener = "🚔",
	liberar = "🔓",
	registrar = "🔦",
	hacienda = "🏛️",
	viviendas = "🏠",
	carrera = "🎖️",
	musica = "🎵",
	claxon = "📯",
	timbre = "🔔",
	volver = "⬅️",
	habilidades = "✨",
	pistola = "🔫",
	recargar = "🔄",
	disparar = "💥",
	agacharse = "🔽", -- (agacharse y tumbarse: Controllers/Stances)
	tumbarse = "⏬",
}

-- Tipos del tiempo (shared/Seasons) -> icono
Icons.Weather = {
	Despejado = "sol",
	Nublado = "nube",
	Lluvia = "lluvia",
	Tormenta = "tormenta",
	Nieve = "nieve",
	Niebla = "niebla",
}

function Icons.image(name: string): string?
	local id = (IconIds :: any)[name]
	return if type(id) == "string" and id ~= "" then id else nil
end

function Icons.glyph(name: string): string
	return Icons.Fallback[name] or name
end

local function fill(holder: Frame, name: string, color: Color3?)
	for _, child in holder:GetChildren() do
		if child.Name == "Image" or child.Name == "Glyph" then
			child:Destroy()
		end
	end
	local image = Icons.image(name)
	if image then
		create("ImageLabel", {
			Name = "Image",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = image,
			ImageColor3 = color or Color3.new(1, 1, 1),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = holder.ZIndex,
			Parent = holder,
		})
	else
		create("TextLabel", {
			Name = "Glyph",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = Icons.glyph(name),
			TextScaled = true,
			Font = Theme.FontBold,
			TextColor3 = color or Color3.new(1, 1, 1),
			ZIndex = holder.ZIndex,
			Parent = holder,
		})
	end
	holder:SetAttribute("Icon", name)
end

-- Un icono dentro de un marco transparente. props: Size, Position, AnchorPoint, ZIndex, Parent, Name, Color
function Icons.new(name: string, props: { [string]: any }): Frame
	local color = props.Color
	local frameProps = { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromOffset(24, 24) }
	for key, value in props do
		if key ~= "Color" then
			frameProps[key] = value
		end
	end
	local holder = create("Frame", frameProps)
	fill(holder, name, color)
	return holder
end

function Icons.set(holder: Frame, name: string, color: Color3?)
	if holder:GetAttribute("Icon") == name and color == nil then
		return
	end
	fill(holder, name, color)
end

-- Tiñe el icono (imagen o emoji: el emoji conserva sus colores, solo cambia si es texto normal)
function Icons.tint(holder: Frame, color: Color3)
	local image = holder:FindFirstChild("Image") :: ImageLabel?
	if image then
		image.ImageColor3 = color
	end
end

---------------------------------------------------------------------
-- Formas dibujadas con marcos (no dependen de la fuente)
---------------------------------------------------------------------
local function bar(parent: Instance, length: number, thickness: number, center: UDim2, rotation: number, color: Color3, z: number)
	return create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = UDim2.new(length, 0, 0, thickness),
		Rotation = rotation,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = parent,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
end

local function shape(props: { [string]: any }): (Frame, Color3, number, number)
	local color = props.Color or Color3.new(1, 1, 1)
	local thickness = props.Thickness or 3
	local frameProps = { Name = props.Name or "Shape", BackgroundTransparency = 1, Size = UDim2.fromOffset(18, 18) }
	for key, value in props do
		if key ~= "Color" and key ~= "Thickness" and key ~= "Name" then
			frameProps[key] = value
		end
	end
	local holder = create("Frame", frameProps)
	return holder, color, thickness, holder.ZIndex
end

-- ">" (Rotation 90 = hacia abajo, 180 = "<", -90 = hacia arriba)
function Icons.chevron(props: { [string]: any }): Frame
	local holder, color, thickness, z = shape(props)
	bar(holder, 0.62, thickness, UDim2.fromScale(0.5, 0.3), 45, color, z)
	bar(holder, 0.62, thickness, UDim2.fromScale(0.5, 0.7), -45, color, z)
	return holder
end

function Icons.plus(props: { [string]: any }): Frame
	local holder, color, thickness, z = shape(props)
	bar(holder, 0.8, thickness, UDim2.fromScale(0.5, 0.5), 0, color, z)
	bar(holder, 0.8, thickness, UDim2.fromScale(0.5, 0.5), 90, color, z)
	return holder
end

function Icons.minus(props: { [string]: any }): Frame
	local holder, color, thickness, z = shape(props)
	bar(holder, 0.8, thickness, UDim2.fromScale(0.5, 0.5), 0, color, z)
	return holder
end

-- Rombo con borde (el ◆ de "MISIÓN PRINCIPAL")
function Icons.diamond(props: { [string]: any }): Frame
	local holder, color, thickness, z = shape(props)
	local inner = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.66, 0.66),
		Rotation = 45,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = holder,
	}, { create("UIStroke", { Color = color, Thickness = thickness * 0.7 }) })
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.34, 0.34),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = inner,
	})
	return holder
end

-- Punto redondo (viñeta "•")
function Icons.dot(props: { [string]: any }): Frame
	local color = props.Color or Color3.new(1, 1, 1)
	local frameProps = { Name = props.Name or "Dot", BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7) }
	for key, value in props do
		if key ~= "Color" and key ~= "Name" then
			frameProps[key] = value
		end
	end
	return create("Frame", frameProps, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
end

return Icons
