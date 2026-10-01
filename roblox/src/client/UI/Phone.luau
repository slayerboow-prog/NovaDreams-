-- Phone: el ValPhone, el teléfono del jugador (la marca de los carteles del metro: «📱 ValPhone 12 ·
-- Más batería que nunca»). Sustituye al antiguo menú COMANDOS de la izquierda: todo el menú del juego
-- son sus apps. Solo dibuja; qué apps hay y qué hacen lo decide Commands/CommandMenu.
--
--   Cerrado   -> asoma en la esquina de abajo a la izquierda (HudLayout.Items.Phone; al volante,
--                debajo de tu estado: Items.PhoneDrive) con la hora y el numerito de avisos.
--                Tocarlo (o Tab / Select del mando) lo sube entero con un muelle.
--   Abierto   -> barra de estado (hora del juego, cobertura «VAL 5G» y batería = tu energía), fondo
--                de pantalla de la marca (o el del tema del pase), el reloj grande, la cuadrícula de
--                apps con sus puntos rojos y el dock (Mapa, Misiones, Mensajes, Ajustes). Las apps
--                con pantalla propia (Ajustes, Mensajes, Cartera, listas como «Gestos del pase») se
--                abren dentro; las demás cierran el teléfono y abren su ventana de siempre.
--                Se cierra tocando fuera, con la barra de inicio de abajo (en una app: vuelve al
--                inicio), con ‹ (atrás), Tab, Retroceso o B.
--   Avisos    -> con el teléfono cerrado, una notificación baja encima (Items.PhoneBanner): mensajes
--                nuevos («📱 Abu Rosa quiere hablar contigo»), recompensas del pase por reclamar,
--                misión nueva… Tocarla abre esa app.
-- Ordenador: el ratón ilumina cada app al pasar; flechas para moverse, Enter para abrir.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Format = require(ReplicatedStorage.Shared.Format)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local HudLayout = require(script.Parent.HudLayout)
local PhoneApps = require(script.Parent.Parent.Commands.PhoneApps)

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local Phone = {}

local player = Players.LocalPlayer

local function color(list: { number }): Color3
	return rgb(list[1], list[2], list[3])
end

local BRAND = PhoneApps.Colors
local BODY = color(BRAND.Body)
local BEZEL = color(BRAND.Bezel)
local EDGE = color(BRAND.Edge)
local BADGE = color(BRAND.Badge)
local GLASS = rgb(255, 255, 255)
local INK = rgb(16, 18, 26)

local COLUMNS = 4
local SPRING = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local DROP = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local WEEKDAYS = { "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo" }
local MONTHS = { "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre" }

export type App = {
	Id: string,
	Name: string,
	Icon: string,
	Color: { number },
	Badge: number,
	Screen: string?,
	Group: boolean?,
}
export type Row = { Id: string?, Icon: string?, Label: string, Detail: string?, Value: string?, Color: { number }?, Unread: boolean?, Wrap: boolean? }

-- Fondo de pantalla: el de la marca o, con un tema de teléfono del pase, su color (UI/BattlePassCosmetics)
function Phone.wallpaper(accent: Color3?): ColorSequence
	local top, mid, bottom = color(BRAND.WallTop), color(BRAND.WallMid), color(BRAND.WallBottom)
	if accent then
		top = top:Lerp(accent, 0.35)
		mid = mid:Lerp(accent, 0.65)
		bottom = bottom:Lerp(accent, 0.45)
	end
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.55, mid),
		ColorSequenceKeypoint.new(1, bottom),
	})
end

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
local gui: ScreenGui? = nil
local touch = false
local parts: { [string]: any } = {}
local wallpapers: { UIGradient } = {}
local apps: { App } = {}
local appSignature = ""
local tiles: { [string]: { Button: TextButton, Tile: Frame, Ring: Frame, Badge: Frame, Label: TextLabel } } = {}
local focusables: { string } = {} -- ids en el orden de la cuadrícula (y el dock) para teclado y mando
local focusIndex = 0
local opened = false
local hidden = false -- (en conversaciones, de bebé sin apps…)
local driving = false -- al volante o a los mandos de un avión
local moving = false -- …y en marcha: no se abre (nunca tapa los mandos)
local screen: string? = nil -- pantalla abierta dentro del teléfono (nil = inicio)
local rows: { Row } = {}
local rowFocus = 0
local bannerSerial = 0
local bannerApp: string? = nil

-- Lo que conecta Commands/CommandMenu
Phone.LaunchCallback = nil :: ((string) -> ())? -- tocar una app (id)
Phone.RowCallback = nil :: ((string, number, Row) -> ())? -- tocar una fila de una pantalla (pantalla, índice, fila)
Phone.OpenedCallback = nil :: ((boolean) -> ())? -- se abre / se cierra
Phone.BlockedCallback = nil :: (() -> ())? -- se intenta abrir en marcha

---------------------------------------------------------------------
-- Piezas pequeñas
---------------------------------------------------------------------
local function corner(radius: number): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function wallpaperOn(frame: GuiObject)
	local gradient = create("UIGradient", { Name = "Wallpaper", Rotation = 120, Color = Phone.wallpaper(Theme.accent("Phone")), Parent = frame })
	table.insert(wallpapers, gradient)
	return gradient
end

-- Filo metálico del teléfono (claro arriba, más oscuro abajo)
local function metalEdge(frame: GuiObject, thickness: number)
	local stroke = create("UIStroke", { Name = "Metal", Color = Color3.new(1, 1, 1), Thickness = thickness, Transparency = 0.05, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rgb(235, 238, 248)),
			ColorSequenceKeypoint.new(0.5, EDGE),
			ColorSequenceKeypoint.new(1, rgb(70, 74, 92)),
		}),
		Parent = stroke,
	})
	return stroke
end

-- Icono de app: «squircle» de su color con brillo arriba y el icono blanco
local function appTile(parent: Instance, name: string, iconName: string, tint: { number }, size: number, z: number): Frame
	local base = color(tint)
	local tile = create("Frame", {
		Name = name,
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = parent,
	}, {
		corner(math.floor(size * 0.27)),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(base:Lerp(Color3.new(1, 1, 1), 0.22), base:Lerp(Color3.new(0, 0, 0), 0.18)) }),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.75, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	Icons.new(iconName, {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.58, 0.58),
		ZIndex = z + 1,
		Parent = tile,
	})
	return tile
end

local function badgeDot(parent: Instance, z: number): Frame
	local dot = create("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = BADGE,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = z,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5, Transparency = 0.1 }),
	})
	Theme.label({ Name = "Count", Size = UDim2.fromScale(1, 1), Font = Theme.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = z + 1, Parent = dot })
	return dot
end

local function setBadge(dot: Frame, count: number)
	dot.Visible = count > 0
	local label = dot:FindFirstChild("Count") :: TextLabel?
	if label then
		Theme.setText(label, if count > 9 then "9+" else tostring(count))
	end
end

local function clockText(): string
	return Format.clock(Lighting.ClockTime)
end

local function dateText(): string
	local ok, now = pcall(GameClock.now)
	if not ok or type(now) ~= "table" then
		return ""
	end
	return ("%s, %d de %s"):format(WEEKDAYS[now.Weekday] or "", now.DayOfMonth or 1, MONTHS[now.Month] or "")
end

---------------------------------------------------------------------
-- Barra de estado: hora, cobertura y batería
---------------------------------------------------------------------
local function buildStatusBar(parent: Instance, z: number): Frame
	local bar = create("Frame", { Name = "StatusBar", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = z, Parent = parent })
	Theme.label({ Name = "Time", Position = UDim2.fromOffset(22, 8), Size = UDim2.fromOffset(70, 20), Font = Theme.FontBold, TextSize = 15, Text = clockText(), ZIndex = z, Parent = bar })
	-- La isla (cámara) arriba en el centro
	create("Frame", { Name = "Island", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(86, 22), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = z + 2, Parent = bar }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	-- Cobertura: cuatro rayitas y «VAL»
	local signal = create("Frame", { Name = "Signal", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -86, 0, 11), Size = UDim2.fromOffset(20, 14), BackgroundTransparency = 1, ZIndex = z, Parent = bar })
	for i = 1, 4 do
		local h = 4 + i * 2.5
		create("Frame", { Name = "Bar" .. i, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, (i - 1) * 5, 1, 0), Size = UDim2.fromOffset(3.5, h), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z, Parent = signal }, { corner(1) })
	end
	Theme.label({ Name = "Carrier", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 9), Size = UDim2.fromOffset(24, 18), Font = Theme.FontBold, TextSize = 11, Text = "5G", TextXAlignment = Enum.TextXAlignment.Center, ZIndex = z, Parent = bar })
	-- Batería: tu energía
	local battery = create("Frame", { Name = "Battery", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 11), Size = UDim2.fromOffset(28, 14), BackgroundTransparency = 1, ZIndex = z, Parent = bar }, {
		corner(4),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.35, Thickness = 1.2 }),
	})
	create("Frame", { Name = "Nub", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 1, 0.5, 0), Size = UDim2.fromOffset(2.5, 5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = z, Parent = battery })
	create("Frame", { Name = "Fill", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z, Parent = battery }, { corner(2) })
	return bar
end

local function paintStatus(bar: Frame?)
	if not bar then
		return
	end
	local time = bar:FindFirstChild("Time") :: TextLabel?
	if time then
		Theme.setText(time, clockText())
	end
	local battery = bar:FindFirstChild("Battery")
	local fill = battery and battery:FindFirstChild("Fill") :: Frame?
	if fill then
		local level = PhoneApps.battery(player:GetAttribute("Energy"))
		fill.Size = UDim2.new((level / 100), -4 * (level / 100), 1, -4)
		fill.BackgroundColor3 = if level <= 20 then rgb(255, 69, 58) elseif level <= 40 then rgb(255, 214, 10) else Color3.new(1, 1, 1)
		battery:SetAttribute("Level", level)
	end
end

---------------------------------------------------------------------
-- Montar el teléfono
---------------------------------------------------------------------
local function buildPeek(parent: ScreenGui)
	local peek = create("TextButton", {
		Name = "PhonePeek",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(HudLayout.Sizes.PhonePeek.X, HudLayout.Sizes.PhonePeek.Y),
		BackgroundColor3 = BODY,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 2,
		Parent = parent,
	}, { corner(26) })
	metalEdge(peek, 2.5)
	Theme.halo(peek, color(BRAND.Accent), 8, 30)
	local screenFrame = create("Frame", {
		Name = "Screen",
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = peek,
	}, { corner(20) })
	wallpaperOn(screenFrame)
	create("Frame", { Name = "Island", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(38, 11), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 5, Parent = screenFrame }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local time = Theme.title({ Name = "Time", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20), Size = UDim2.new(1, -8, 0, 30), TextSize = 26, Text = clockText(), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5, Parent = screenFrame })
	Theme.label({ Name = "Brand", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52), Size = UDim2.new(1, -8, 0, 16), Font = Theme.FontBold, TextSize = 12, Text = PhoneApps.Brand, TextColor3 = rgb(210, 230, 255), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5, Parent = screenFrame })
	-- Tres apps en pequeño (Mapa, Misiones, Mensajes): se nota que es el teléfono con el menú
	local mini = create("Frame", { Name = "Mini", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 76), Size = UDim2.fromOffset(72, 20), BackgroundTransparency = 1, ZIndex = 5, Parent = screenFrame })
	for i, id in { "Mapa", "Misiones", "Mensajes" } do
		local meta = PhoneApps.Catalog[id]
		local tile = appTile(mini, "Mini" .. i, meta.Icon, meta.Color, 20, 5)
		tile.Position = UDim2.fromOffset((i - 1) * 26, 0)
	end
	-- Abajo: la tecla (ordenador) o una flechita hacia arriba (móvil: «súbelo»)
	if touch then
		Icons.chevron({ Name = "Up", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.fromOffset(12, 16), Rotation = -90, Thickness = 3, ZIndex = 5, Parent = screenFrame })
	else
		local key = Theme.label({ Name = "Key", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.fromOffset(40, 16), BackgroundColor3 = INK, BackgroundTransparency = 0.35, Font = Theme.FontBold, TextSize = 11, Text = "Tab", TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6, Parent = screenFrame })
		key:SetAttribute("TouchText", true)
		create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = key })
	end
	local badge = badgeDot(peek, 8)
	badge.Position = UDim2.new(1, -6, 0, 6)
	badge.Size = UDim2.fromOffset(26, 26)
	peek.MouseEnter:Connect(function()
		TweenService:Create(peek, QUICK, { BackgroundColor3 = BODY:Lerp(color(BRAND.Accent), 0.25) }):Play()
	end)
	peek.MouseLeave:Connect(function()
		TweenService:Create(peek, QUICK, { BackgroundColor3 = BODY }):Play()
	end)
	Theme.pressable(peek)
	peek.Activated:Connect(function()
		Phone.toggle()
	end)
	parts.Peek = peek
	parts.PeekTime = time
	parts.PeekBadge = badge
end

local function buildBody(parent: ScreenGui)
	-- Fuera del teléfono: tocar cierra (y oscurece un poco el juego)
	local scrim = create("TextButton", {
		Name = "Scrim",
		Size = UDim2.new(1, 4000, 1, 4000),
		Position = UDim2.fromOffset(-2000, -2000),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 1,
		Parent = parent,
	})
	scrim.Activated:Connect(function()
		Phone.close()
	end)
	parts.Scrim = scrim

	local body = create("Frame", {
		Name = "ValPhone",
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = BODY,
		BorderSizePixel = 0,
		Visible = false,
		Active = true, -- (los toques dentro no llegan al juego ni al fondo que cierra)
		ZIndex = 3,
		Parent = parent,
	}, { corner(44) })
	body:SetAttribute("Open", false)
	metalEdge(body, 3)
	Theme.halo(body, color(BRAND.Accent), 10, 48)
	-- Botones laterales (volumen y encendido), de adorno
	for i, spec in { { -3, 120, 46 }, { -3, 176, 46 }, { 1, 150, 70 } } do
		create("Frame", {
			Name = "Side" .. i,
			AnchorPoint = Vector2.new(if spec[1] < 0 then 1 else 0, 0),
			Position = UDim2.new(if spec[1] < 0 then 0 else 1, spec[1], 0, spec[2]),
			Size = UDim2.fromOffset(3, spec[3]),
			BackgroundColor3 = EDGE,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = body,
		}, { corner(2) })
	end
	local screenFrame = create("Frame", {
		Name = "Screen",
		Position = UDim2.fromOffset(9, 9),
		Size = UDim2.new(1, -18, 1, -18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 4,
		Parent = body,
	}, { corner(36) })
	wallpaperOn(screenFrame)
	-- Dos manchas de luz en el fondo (profundidad, como un fondo de pantalla de verdad)
	for i, spec in { { 0.15, 0.22, 0.9, rgb(140, 120, 255) }, { 0.95, 0.75, 1.1, rgb(60, 230, 220) } } do
		create("Frame", {
			Name = "Glow" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(spec[1], spec[2]),
			Size = UDim2.fromScale(spec[3], spec[3] * 0.6),
			BackgroundColor3 = spec[4],
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = screenFrame,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	local statusBar = buildStatusBar(screenFrame, 8)
	parts.StatusBar = statusBar

	-- Inicio: el reloj grande, la cuadrícula de apps y el dock
	local home = create("Frame", { Name = "Home", Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -36), BackgroundTransparency = 1, ZIndex = 5, Parent = screenFrame })
	local widget = create("Frame", { Name = "Widget", Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -28, 0, 84), BackgroundTransparency = 1, ZIndex = 5, Parent = home })
	local bigTime = Theme.title({ Name = "Time", Size = UDim2.new(1, 0, 0, 50), TextSize = 46, Text = clockText(), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6, Parent = widget })
	local date = Theme.label({ Name = "Date", Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 18), Font = Theme.FontBold, TextSize = 14, Text = dateText(), TextColor3 = rgb(220, 232, 255), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6, Parent = widget })
	Theme.label({ Name = "Model", Position = UDim2.fromOffset(0, 68), Size = UDim2.new(1, 0, 0, 14), TextSize = 11, Text = PhoneApps.Model .. " · " .. PhoneApps.Slogan, TextColor3 = rgb(170, 200, 240), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = widget })
	local grid = create("ScrollingFrame", {
		Name = "Apps",
		Position = UDim2.fromOffset(0, 94),
		Size = UDim2.new(1, 0, 1, -(94 + 118)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
		ZIndex = 6,
		Parent = home,
	})
	local dock = create("Frame", {
		Name = "Dock",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -26),
		Size = UDim2.new(1, -20, 0, 88),
		BackgroundColor3 = GLASS,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = home,
	}, {
		corner(28),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.7, Thickness = 1 }),
	})
	parts.Home = home
	parts.Grid = grid
	parts.Dock = dock
	parts.BigTime = bigTime
	parts.Date = date

	-- Pantalla de una app (Ajustes, Mensajes, Cartera, listas)
	local app = create("Frame", { Name = "App", Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -36), BackgroundColor3 = rgb(12, 14, 24), BackgroundTransparency = 0.15, BorderSizePixel = 0, Visible = false, ZIndex = 10, Parent = screenFrame })
	local header = create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, ZIndex = 11, Parent = app })
	local back = create("TextButton", { Name = "Back", Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(44, 40), BackgroundTransparency = 1, Text = "", ZIndex = 12, Parent = header })
	Icons.chevron({ Name = "Arrow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 20), Rotation = 180, Thickness = 3.5, Color = color(BRAND.Accent), ZIndex = 13, Parent = back })
	back.Activated:Connect(function()
		Phone.back()
	end)
	local title = Theme.title({ Name = "Title", Position = UDim2.fromOffset(54, 8), Size = UDim2.new(1, -70, 0, 36), TextSize = 24, ZIndex = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header })
	local list = create("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 1, -(56 + 26)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
		ZIndex = 11,
		Parent = app,
	})
	parts.App = app
	parts.AppTitle = title
	parts.AppList = list

	-- Barra de inicio (gesto de inicio): en una app vuelve al inicio; en el inicio, cierra
	local homeBar = create("TextButton", { Name = "HomeBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.fromOffset(170, 24), BackgroundTransparency = 1, Text = "", ZIndex = 20, Parent = screenFrame })
	create("Frame", { Name = "Pill", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(120, 5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 21, Parent = homeBar }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	homeBar.Activated:Connect(function()
		if screen then
			Phone.home()
		else
			Phone.close()
		end
	end)
	parts.HomeBar = homeBar
	parts.Body = body
	parts.Screen = screenFrame
end

local function buildBanner(parent: ScreenGui)
	local size = HudLayout.Sizes.PhoneBanner
	local banner = create("CanvasGroup", {
		Name = "PhoneBanner",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = rgb(20, 22, 32),
		BackgroundTransparency = 0.08,
		GroupTransparency = 0,
		Visible = false,
		ZIndex = 5,
		Parent = parent,
	}, {
		corner(24),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(170, 180, 205)) }),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.7, Thickness = 1.2 }),
	})
	local holder = create("Frame", { Name = "IconHolder", Position = UDim2.fromOffset(14, 18), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, ZIndex = 6, Parent = banner })
	local app = Theme.label({ Name = "App", Position = UDim2.fromOffset(82, 12), Size = UDim2.new(1, -150, 0, 18), Font = Theme.FontBold, TextSize = 13, TextColor3 = rgb(190, 205, 235), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = banner })
	Theme.label({ Name = "When", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 12), Size = UDim2.fromOffset(60, 18), TextSize = 12, Text = "ahora", TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6, Parent = banner })
	local text = Theme.label({ Name = "Text", Position = UDim2.fromOffset(82, 32), Size = UDim2.new(1, -96, 0, 50), Font = Theme.FontBold, TextSize = 15, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6, Parent = banner })
	local hit = create("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 7, Parent = banner })
	hit.Activated:Connect(function()
		local target = bannerApp
		Phone.hideBanner()
		if Phone.blocked() then
			return
		end
		Phone.open()
		if target and Phone.LaunchCallback then
			Phone.LaunchCallback(target)
		end
	end)
	parts.Banner = banner
	parts.BannerIcon = holder
	parts.BannerApp = app
	parts.BannerText = text
end

---------------------------------------------------------------------
-- Colocación (HudLayout) y visibilidad
---------------------------------------------------------------------
local function placeAll(layout: HudLayout.Layout?)
	local now = layout or HudLayout.current()
	if not parts.Body then
		return
	end
	local peekSpot = if driving and touch then now.Items.PhoneDrive else now.Items.Phone
	HudLayout.apply(parts.Peek, peekSpot)
	local open = now.Items.PhoneOpen
	parts.Body.Size = UDim2.fromOffset(open.Size.X, open.Size.Y)
	parts.Body.AnchorPoint = open.Anchor
	parts.Body.Position = if opened then open.Position else open.Position + UDim2.fromOffset(0, open.Size.Y + 40)
	HudLayout.apply(parts.Banner, now.Items.PhoneBanner)
end

local function refreshPeek()
	if not parts.Peek then
		return
	end
	parts.Peek.Visible = not hidden and not opened and #apps > 0
	parts.Peek.BackgroundTransparency = if moving then 0.45 else 0
	local screenFrame = parts.Peek:FindFirstChild("Screen") :: Frame?
	if screenFrame then
		screenFrame.BackgroundTransparency = if moving then 0.5 else 0
	end
	parts.Peek:SetAttribute("Locked", moving)
end

---------------------------------------------------------------------
-- Apps (inicio)
---------------------------------------------------------------------
local function paintFocus()
	for id, tile in tiles do
		local on = focusables[focusIndex] == id
		tile.Ring.Visible = on or tile.Button:GetAttribute("Hover") == true
	end
	for i, row in parts.Rows or {} do
		local stroke = row:FindFirstChild("Focus") :: UIStroke?
		if stroke then
			stroke.Enabled = i == rowFocus
		end
	end
end

-- (un solo UIScale por objeto: el de Theme, con el tamaño base de «encima» y el salto al tocar)
local function hover(button: TextButton, tile: Frame, on: boolean)
	button:SetAttribute("Hover", on)
	Theme.setBaseScale(tile, if on then 1.08 else 1)
	paintFocus()
end

local function buildTile(parent: Instance, app: App, cell: Vector2, at: Vector2, showLabel: boolean)
	local button = create("TextButton", {
		Name = "App_" .. app.Id,
		Position = UDim2.fromOffset(at.X, at.Y),
		Size = UDim2.fromOffset(cell.X, cell.Y),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 7,
		Parent = parent,
	})
	button:SetAttribute("Command", app.Id)
	local size = math.floor(math.min(cell.X - 14, 58))
	local tile = appTile(button, "Tile", app.Icon, app.Color, size, 8)
	tile.AnchorPoint = Vector2.new(0.5, 0)
	tile.Position = UDim2.new(0.5, 0, 0, 4)
	local ring = create("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 8, 1, 8),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 7,
		Parent = tile,
	}, {
		corner(math.floor(size * 0.27) + 4),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2.5, Transparency = 0.05 }),
	})
	local badge = badgeDot(tile, 10)
	setBadge(badge, app.Badge)
	local label = Theme.label({
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, size + 8),
		Size = UDim2.new(1, 4, 0, 16),
		Font = Theme.FontBold,
		TextSize = 12,
		Text = app.Name,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextStrokeTransparency = 0.7,
		Visible = showLabel,
		ZIndex = 8,
		Parent = button,
	})
	button.MouseEnter:Connect(function()
		hover(button, tile, true)
	end)
	button.MouseLeave:Connect(function()
		hover(button, tile, false)
	end)
	button.Activated:Connect(function()
		Theme.pop(tile, 0.9)
		if Phone.LaunchCallback then
			Phone.LaunchCallback(app.Id)
		end
	end)
	tiles[app.Id] = { Button = button, Tile = tile, Ring = ring, Badge = badge, Label = label }
end

local function rebuildApps()
	if not parts.Grid then
		return
	end
	for _, tile in tiles do
		tile.Button:Destroy()
	end
	tiles = {}
	focusables = {}
	local dockApps, gridApps = PhoneApps.layout(apps)
	local open = HudLayout.current().Items.PhoneOpen.Size
	local inner = open.X - 18
	local padX = 10
	local cellW = math.floor((inner - padX * 2) / COLUMNS)
	local cell = Vector2.new(cellW, cellW + 22)
	for i, app in gridApps do
		local col = (i - 1) % COLUMNS
		local row = math.floor((i - 1) / COLUMNS)
		buildTile(parts.Grid, app, cell, Vector2.new(padX + col * cellW, 4 + row * (cell.Y + 6)), true)
		table.insert(focusables, app.Id)
	end
	local gridRows = math.ceil(#gridApps / COLUMNS)
	parts.Grid.CanvasSize = UDim2.fromOffset(0, 8 + gridRows * (cell.Y + 6))
	local dockW = inner - 20
	local dockCell = math.floor((dockW - 8) / COLUMNS)
	local first = (dockW - dockCell * #dockApps) / 2
	for i, app in dockApps do
		buildTile(parts.Dock, app, Vector2.new(dockCell, 84), Vector2.new(first + (i - 1) * dockCell, 4), true)
		table.insert(focusables, app.Id)
	end
	focusIndex = math.clamp(focusIndex, 0, #focusables)
	paintFocus()
end

-- La lista de apps (Commands/CommandMenu la rehace al cambiar algo). Solo se redibuja si cambia.
function Phone.setApps(list: { App })
	local signature = {}
	for _, app in list do
		table.insert(signature, ("%s|%s|%s"):format(app.Id, app.Name, app.Icon))
	end
	local key = table.concat(signature, ";")
	apps = list
	if key ~= appSignature then
		appSignature = key
		rebuildApps()
	else
		for _, app in list do
			local tile = tiles[app.Id]
			if tile then
				setBadge(tile.Badge, app.Badge)
			end
		end
	end
	if parts.PeekBadge then
		setBadge(parts.PeekBadge, PhoneApps.totalBadges(list))
	end
	refreshPeek()
end

function Phone.apps(): { App }
	return apps
end

---------------------------------------------------------------------
-- Pantallas dentro del teléfono
---------------------------------------------------------------------
local function clearRows()
	for _, row in parts.Rows or {} do
		row:Destroy()
	end
	parts.Rows = {}
end

local function buildRow(index: number, row: Row, y: number, width: number): (TextButton, number)
	local tall = if row.Wrap then 76 else 58
	local button = create("TextButton", {
		Name = "Row" .. index,
		Position = UDim2.fromOffset(10, y),
		Size = UDim2.fromOffset(width - 20, tall),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 12,
		Parent = parts.AppList,
	}, { corner(16) })
	create("UIStroke", { Name = "Focus", Color = color(BRAND.Accent), Thickness = 2, Enabled = false, Parent = button })
	local x = 12
	if row.Icon then
		local tile = appTile(button, "Tile", row.Icon, row.Color or { 70, 90, 140 }, 38, 13)
		tile.AnchorPoint = Vector2.new(0, 0.5)
		tile.Position = UDim2.new(0, 10, 0.5, 0)
		x = 58
	end
	local hasValue = row.Value ~= nil and row.Value ~= ""
	local label = Theme.label({
		Name = "Label",
		Position = UDim2.fromOffset(x, if row.Detail then 8 else 0),
		Size = UDim2.new(1, -(x + (if hasValue then 100 else 34)), 0, if row.Detail then 22 else tall),
		Font = Theme.FontBold,
		TextSize = 15,
		Text = row.Label,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 13,
		Parent = button,
	})
	if row.Detail then
		Theme.label({
			Name = "Detail",
			Position = UDim2.fromOffset(x, 30),
			Size = UDim2.new(1, -(x + (if hasValue then 100 else 34)), 0, tall - 36),
			TextSize = 13,
			Text = row.Detail,
			TextColor3 = C.Muted,
			TextWrapped = row.Wrap == true,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 13,
			Parent = button,
		})
	end
	if hasValue then
		Theme.label({ Name = "Value", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(92, 24), Font = Theme.FontBold, TextSize = 15, Text = row.Value :: string, TextColor3 = C.Money, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13, Parent = button })
	elseif row.Id ~= nil then
		Icons.chevron({ Name = "Go", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(9, 14), Thickness = 2.5, Color = C.Muted, ZIndex = 13, Parent = button })
	end
	if row.Unread then
		create("Frame", { Name = "Unread", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = color(BRAND.Accent), BorderSizePixel = 0, ZIndex = 14, Parent = button }, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
	end
	button.MouseEnter:Connect(function()
		TweenService:Create(button, QUICK, { BackgroundTransparency = 0.78 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, QUICK, { BackgroundTransparency = 0.9 }):Play()
	end)
	button.Activated:Connect(function()
		rowFocus = index
		paintFocus()
		if Phone.RowCallback and screen then
			Phone.RowCallback(screen, index, row)
		end
	end)
	label:SetAttribute("Row", index)
	return button, tall
end

-- Abre una pantalla dentro del teléfono: name (id de la pantalla), title y sus filas
function Phone.showScreen(name: string, title: string, list: { Row }, empty: string?)
	if not parts.App then
		return
	end
	screen = name
	rows = list
	rowFocus = 0
	clearRows()
	Theme.setText(parts.AppTitle, title)
	local width = HudLayout.current().Items.PhoneOpen.Size.X - 18
	local y = 6
	for i, row in list do
		local button, tall = buildRow(i, row, y, width)
		table.insert(parts.Rows, button)
		y += tall + 8
	end
	if #list == 0 and empty then
		local note = Theme.label({ Name = "Empty", Position = UDim2.fromOffset(20, 30), Size = UDim2.new(1, -40, 0, 60), Text = empty, TextColor3 = C.Muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 12, Parent = parts.AppList })
		table.insert(parts.Rows, note :: any)
	end
	parts.AppList.CanvasSize = UDim2.fromOffset(0, y + 10)
	parts.App.Visible = true
	parts.Home.Visible = false
	parts.App:SetAttribute("Screen", name)
	paintFocus()
end

-- Cambia el texto de una fila (p. ej. «🔊 Música: sí» -> «🔇 Música: no»)
function Phone.setRowLabel(index: number, text: string)
	local row = parts.Rows and parts.Rows[index]
	local label = row and row:FindFirstChild("Label") :: TextLabel?
	if label then
		label.Text = text
	end
	if rows[index] then
		rows[index].Label = text
	end
end

function Phone.screen(): string?
	return screen
end

function Phone.rows(): { Row }
	return rows
end

function Phone.home()
	screen = nil
	rows = {}
	clearRows()
	if parts.App then
		parts.App.Visible = false
		parts.App:SetAttribute("Screen", nil)
		parts.Home.Visible = true
	end
	paintFocus()
end

-- Atrás: en una app, al inicio; en el inicio, cierra
function Phone.back(): boolean
	if not opened then
		return false
	end
	if screen then
		Phone.home()
	else
		Phone.close()
	end
	return true
end

---------------------------------------------------------------------
-- Abrir y cerrar (con muelle)
---------------------------------------------------------------------
function Phone.blocked(): boolean
	return moving
end

function Phone.isOpen(): boolean
	return opened
end

function Phone.open(): boolean
	if not parts.Body or opened or hidden or #apps == 0 then
		return opened
	end
	if moving then
		if Phone.BlockedCallback then
			Phone.BlockedCallback()
		end
		return false
	end
	opened = true
	Phone.hideBanner()
	local spot = HudLayout.current().Items.PhoneOpen
	local body = parts.Body
	body.Visible = true
	body:SetAttribute("Open", true)
	body.Position = spot.Position + UDim2.fromOffset(0, spot.Size.Y + 40)
	TweenService:Create(body, SPRING, { Position = spot.Position }):Play()
	parts.Scrim.Visible = true
	parts.Scrim.BackgroundTransparency = 1
	TweenService:Create(parts.Scrim, TweenInfo.new(0.25), { BackgroundTransparency = 0.55 }):Play()
	paintStatus(parts.StatusBar)
	Theme.setText(parts.BigTime, clockText())
	Theme.setText(parts.Date, dateText())
	refreshPeek()
	if Phone.OpenedCallback then
		Phone.OpenedCallback(true)
	end
	return true
end

function Phone.close()
	if not opened then
		return
	end
	opened = false
	local spot = HudLayout.current().Items.PhoneOpen
	local body = parts.Body
	body:SetAttribute("Open", false)
	TweenService:Create(body, DROP, { Position = spot.Position + UDim2.fromOffset(0, spot.Size.Y + 40) }):Play()
	parts.Scrim.Visible = false
	Phone.home()
	task.delay(0.24, function()
		if not opened then
			body.Visible = false
		end
	end)
	focusIndex = 0
	paintFocus()
	refreshPeek()
	if Phone.OpenedCallback then
		Phone.OpenedCallback(false)
	end
end

function Phone.toggle()
	if opened then
		Phone.close()
	else
		Phone.open()
	end
end

-- En conversaciones y cinemáticas (o sin apps, de bebé) el teléfono se guarda
function Phone.setHidden(value: boolean)
	hidden = value
	if value then
		Phone.close()
		Phone.hideBanner()
	end
	refreshPeek()
end

-- Al volante o volando: asoma debajo de tu estado (móvil) y, en marcha, no se abre (y si estaba
-- abierto, se guarda: nunca tapa los mandos del vehículo)
function Phone.setVehicle(atWheel: boolean, inMotion: boolean)
	local moved = driving ~= atWheel
	driving = atWheel
	moving = atWheel and inMotion
	if moving and opened then
		Phone.close()
	end
	if moved then
		placeAll(nil)
	end
	refreshPeek()
end

---------------------------------------------------------------------
-- Teclado y mando: moverse por las apps (o las filas) y abrir
---------------------------------------------------------------------
function Phone.navigate(dx: number, dy: number)
	if not opened then
		return
	end
	if screen then
		if #rows > 0 then
			rowFocus = math.clamp((if rowFocus == 0 then 0 else rowFocus) + (if dy ~= 0 then dy else dx), 1, #rows)
		end
	elseif focusIndex == 0 then
		focusIndex = 1
	else
		focusIndex = PhoneApps.step(focusIndex, #focusables, COLUMNS, dx, dy)
	end
	paintFocus()
end

function Phone.accept(): boolean
	if not opened then
		return false
	end
	if screen then
		local row = rows[rowFocus]
		if row and Phone.RowCallback then
			Phone.RowCallback(screen, rowFocus, row)
		end
		return true
	end
	local id = focusables[math.max(focusIndex, 1)]
	if id and Phone.LaunchCallback then
		Phone.LaunchCallback(id)
	end
	return true
end

---------------------------------------------------------------------
-- Notificaciones (con el teléfono cerrado)
---------------------------------------------------------------------
function Phone.notify(data: { Icon: string?, App: string?, Title: string?, Text: string, Color: { number }? })
	if not parts.Banner or hidden or opened then
		return
	end
	bannerSerial += 1
	local serial = bannerSerial
	bannerApp = data.App
	local banner = parts.Banner
	for _, child in parts.BannerIcon:GetChildren() do
		child:Destroy()
	end
	local meta = data.App and PhoneApps.Catalog[data.App]
	local tile = appTile(parts.BannerIcon, "Tile", data.Icon or (meta and meta.Icon) or "telefono", data.Color or (meta and meta.Color) or { 60, 90, 160 }, 56, 6)
	tile.Position = UDim2.fromOffset(0, 0)
	Theme.setText(parts.BannerApp, string.upper(data.Title or (meta and meta.Name) or PhoneApps.Brand))
	Theme.setText(parts.BannerText, data.Text)
	banner:SetAttribute("App", data.App)
	local spot = HudLayout.current().Items.PhoneBanner
	banner.Visible = true
	banner.GroupTransparency = 1
	banner.Position = spot.Position + UDim2.fromOffset(0, 30)
	TweenService:Create(banner, SPRING, { Position = spot.Position, GroupTransparency = 0 }):Play()
	-- El teléfono que asoma da un saltito
	if parts.Peek and parts.Peek.Visible then
		Theme.pop(parts.Peek, 1.08)
	end
	task.delay(4.5, function()
		if serial == bannerSerial then
			Phone.hideBanner()
		end
	end)
end

function Phone.hideBanner()
	local banner = parts.Banner
	if not banner or not banner.Visible then
		return
	end
	bannerSerial += 1
	bannerApp = nil
	banner.Visible = false
end

---------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------
function Phone.mount(parent: ScreenGui, isTouch: boolean)
	gui = parent
	touch = isTouch
	wallpapers = {}
	buildPeek(parent)
	buildBody(parent)
	buildBanner(parent)
	HudLayout.onChanged(function(layout)
		placeAll(layout)
		rebuildApps()
	end)
	-- Tema del teléfono del pase: el fondo de pantalla toma su color
	Theme.onAccent("Phone", function(accent: Color3?)
		for _, gradient in wallpapers do
			gradient.Color = Phone.wallpaper(accent)
		end
	end)
	-- La hora (y la batería) se repasan cada pocos segundos
	local function tick()
		local text = clockText()
		Theme.setText(parts.PeekTime, text)
		if opened then
			Theme.setText(parts.BigTime, text)
			Theme.setText(parts.Date, dateText())
			paintStatus(parts.StatusBar)
		end
	end
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(tick)
	player:GetAttributeChangedSignal("Energy"):Connect(function()
		paintStatus(parts.StatusBar)
	end)
	paintStatus(parts.StatusBar)
	refreshPeek()
end

-- (pruebas) las piezas
function Phone._parts(): { [string]: any }
	return parts
end

function Phone._reset()
	gui = nil
	parts = {}
	wallpapers = {}
	apps = {}
	appSignature = ""
	tiles = {}
	focusables = {}
	focusIndex = 0
	opened = false
	hidden = false
	driving = false
	moving = false
	screen = nil
	rows = {}
	rowFocus = 0
	bannerSerial = 0
	bannerApp = nil
	Phone.LaunchCallback = nil
	Phone.RowCallback = nil
	Phone.OpenedCallback = nil
	Phone.BlockedCallback = nil
end

return Phone
