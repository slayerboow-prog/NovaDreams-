-- CommandRenderer: dibuja el menú de comandos (abajo a la izquierda).
--
--   ╔ 👑 COMANDOS ───────────── ⌃ ╗   <- pestaña con la corona y el botón para ocultarlo
--   ║▌ 💬 Hablar          Marta   > ║   <- el elegido: azul intenso con brillo y ">" (el selector se desliza)
--   ║▌ ✋ Interactuar              ║
--   ║▌ 🎒 Inventario               ║
--   ║▌ 🗺 Mapa                     ║
--   ║            ⌄                 ║   <- desplegar: ver todos los comandos
--   ╚═════════════════════════════╝
--
-- Solo dibuja; qué comandos salen y qué hacen lo decide CommandMenu.
-- Las flechas se dibujan con marcos (UI/Icons): no dependen de la fuente del móvil.

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud
local rgb = Color3.fromRGB

local CommandRenderer = {}
CommandRenderer.__index = CommandRenderer

local S = HudLayout.Sizes
local HEADER = S.CommandHeader
local PITCH = S.CommandPitch
local ROW_H = PITCH - 4
local LEFT = 16 -- sitio para el filo de la izquierda
local SLIDE = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

export type Item = { Label: string, Detail: string?, Icon: string, Group: boolean?, Accent: boolean?, Badge: boolean? }

function CommandRenderer.new(parent: Instance, touch: boolean)
	local self = setmetatable({}, CommandRenderer)
	self.Rows = {}
	self.Items = {}
	self.Selected = 0
	self.First = 1
	self.Window = if touch then 4 else 5
	self.Collapsed = false
	self.Expanded = false
	self.Visible = true
	self.HoverCallback = nil :: ((number) -> ())?
	self.ActivateCallback = nil :: ((number) -> ())?
	self.ToggleCallback = nil :: (() -> ())?
	self.ExpandCallback = nil :: (() -> ())?
	self.Touch = touch
	self.Width = S.CommandWidth

	local root = Theme.hudPanel({
		Name = "CommandMenu",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(self.Width, HEADER),
		BackgroundTransparency = 0.38,
		CornerRadius = 12,
		ClipsDescendants = false,
		Parent = parent,
	})
	Theme.bevel(root)
	Theme.halo(root, H.Glow, 8, 14)
	self.Root = root

	-- Filo lateral brillante (a la izquierda, a todo lo alto)
	create("Frame", {
		Name = "Rail",
		Position = UDim2.fromOffset(5, HEADER + 6),
		Size = UDim2.new(0, 4, 1, -(HEADER + 14)),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = root,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = Theme.EdgeGradient }),
	})

	-- Pestaña del título: corona + COMANDOS + botón de ocultar
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = root,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIGradient", { Color = ColorSequence.new(rgb(70, 60, 190), rgb(20, 90, 220)), Transparency = NumberSequence.new(0.1, 0.5) }),
	})
	self.Header = header
	Icons.new("corona", { Name = "Crown", Position = UDim2.fromOffset(12, 5), Size = UDim2.fromOffset(24, 24), ZIndex = 4, Parent = header })
	self.HeaderText = Theme.title({
		Name = "Title",
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.new(1, -90, 1, 0),
		TextSize = 19,
		TextStrokeTransparency = 0.5,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "COMANDOS",
		ZIndex = 4,
		Parent = header,
	})
	-- Botón para ocultar / mostrar el menú (también Tab, o ← / → en la cruceta)
	local toggle = create("TextButton", {
		Name = "Toggle",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(30, 26),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.3,
		Text = "",
		ZIndex = 5,
		Parent = header,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	Theme.edge(toggle, H.Glow, 1.5)
	self.ToggleIcon = Icons.chevron({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 14), Rotation = 90, Thickness = 2.5, ZIndex = 6, Parent = toggle })
	self.Toggle = toggle
	Theme.pressable(toggle)
	toggle.Activated:Connect(function()
		if self.ToggleCallback then
			self.ToggleCallback()
		end
	end)
	-- Tocar la pestaña cuando está oculto también lo abre. En el móvil, tocar la pestaña lo oculta y
	-- lo muestra: el botón ˅ solo mide unos 15 píxeles en un teléfono y costaba acertar
	local headerHit = create("TextButton", { Name = "HeaderHit", Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = header })
	headerHit.Activated:Connect(function()
		if (self.Collapsed or self.Touch) and self.ToggleCallback then
			self.ToggleCallback()
		end
	end)

	-- Lista (en un CanvasGroup para entrar y salir con fundido)
	local list = create("CanvasGroup", {
		Name = "List",
		Position = UDim2.fromOffset(0, HEADER + 4),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = root,
	})
	self.List = list
	-- Selector: el fondo azul brillante del elegido, que se desliza de una fila a otra
	local selector = create("Frame", {
		Name = "Selector",
		Position = UDim2.fromOffset(LEFT - 4, 0),
		Size = UDim2.new(1, -(LEFT + 2), 0, ROW_H),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 2,
		Parent = list,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 9) }),
		create("UIGradient", { Color = ColorSequence.new(rgb(40, 140, 255), rgb(22, 70, 215)) }),
	})
	Theme.edge(selector, H.Glow, 2)
	Theme.halo(selector, H.Glow, 8, 12)
	Icons.chevron({ Name = "Arrow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(12, 16), Thickness = 3, ZIndex = 4, Parent = selector })
	self.Selector = selector
	self.Holder = create("Frame", { Name = "Rows", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = list })

	-- Desplegar ⌄ (ver todos)
	local more = create("TextButton", {
		Name = "More",
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(80, 20),
		BackgroundTransparency = 1,
		Text = "",
		Visible = false,
		ZIndex = 4,
		Parent = root,
	})
	self.MoreIcon = Icons.chevron({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 18), Rotation = 90, Color = H.Glow, Thickness = 3, ZIndex = 4, Parent = more })
	self.More = more
	more.Activated:Connect(function()
		if self.ExpandCallback then
			self.ExpandCallback()
		end
	end)
	self.Hint = Theme.label({
		Name = "Hint",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, LEFT, 1, -4),
		Size = UDim2.new(1, -LEFT - 8, 0, 14),
		TextSize = 12,
		TextColor3 = C.Muted,
		TextStrokeTransparency = 0.6,
		Text = "",
		Visible = not touch,
		ZIndex = 4,
		Parent = root,
	})
	return self
end

function CommandRenderer:setHeader(text: string)
	Theme.setText(self.HeaderText, string.upper(text))
end

function CommandRenderer:setHint(text: string)
	self.Hint.Text = text
end

-- Cuántas filas se ven (sin desplegar / desplegado)
function CommandRenderer:setWindow(rows: number)
	self.Window = math.max(1, rows)
	self:window()
end

-- Alto de la lista y del panel según las filas que se ven
function CommandRenderer:resize()
	local shown = if self.Collapsed then 0 else math.min(#self.Rows, self.Window)
	local listH = shown * PITCH
	local extra = #self.Rows > self.Window and not self.Collapsed
	self.More.Visible = extra
	local footer = if self.Collapsed then 0 else S.CommandFooter
	local hint = if self.Touch or self.Collapsed then 0 else S.CommandHint
	self.List.Size = UDim2.new(1, 0, 0, listH)
	self.List.Visible = not self.Collapsed
	self.Hint.Visible = hint > 0
	self.More.Position = UDim2.new(0.5, 0, 1, -(hint + 4))
	local height = HEADER + (if self.Collapsed then 0 else listH + footer + hint)
	TweenService:Create(self.Root, FADE, { Size = UDim2.fromOffset(self.Width, height) }):Play()
	self.ToggleIcon.Rotation = if self.Collapsed then -90 else 90
	self.MoreIcon.Rotation = if self.Expanded then -90 else 90
	local rail = self.Root:FindFirstChild("Rail") :: Frame?
	if rail then
		rail.Visible = not self.Collapsed
	end
end

local function paintRow(row: { [string]: any }, on: boolean)
	row.Label.TextColor3 = if on then Color3.new(1, 1, 1) else C.Text
	row.Label.FontFace = if on then Theme.TitleFace else Font.fromEnum(Theme.FontBold)
	row.Detail.TextColor3 = if on then rgb(200, 230, 255) else C.Muted
	row.Body.BackgroundTransparency = if on then 1 else 0.35
end

-- items: lo que se enseña; selected: cuál va elegido; motion: "push" (entra un submenú),
-- "pop" (se vuelve atrás) o nil (solo ha cambiado lo que hay alrededor)
-- Rellena una fila ya hecha con otro comando (sin destruirla: así no parpadea al cambiar lo de alrededor)
local function refill(row: { [string]: any }, item: Item)
	Theme.setText(row.Label, item.Label)
	Theme.setText(row.Detail, item.Detail or "")
	row.Accent.BackgroundColor3 = if item.Accent then H.Gold else H.Violet
	if row.IconName ~= item.Icon then
		row.IconName = item.Icon
		if row.Icon then
			row.Icon:Destroy()
		end
		row.Icon = Icons.new(item.Icon, { Name = "Icon", Position = UDim2.fromOffset(16, 6), Size = UDim2.fromOffset(ROW_H - 12, ROW_H - 12), ZIndex = 4, Parent = row.Button })
	end
	if (item.Badge == true) ~= (row.BadgeDot ~= nil) then
		if row.BadgeDot then
			row.BadgeDot:Destroy()
			row.BadgeDot = nil
		else
			row.BadgeDot = create("Frame", { Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 16, 0, 6), BackgroundColor3 = rgb(255, 70, 90), ZIndex = 5, Parent = row.Button }, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }),
			})
		end
	end
end

function CommandRenderer:setItems(items: { Item }, selected: number, motion: string?)
	if motion == nil and #items == #self.Rows and #items > 0 then
		-- Mismo número de filas: se cambia el contenido en su sitio (sin rehacerlas ni parpadear)
		self.Items = items
		for i, item in items do
			refill(self.Rows[i], item)
		end
		local old = self.Rows[self.Selected]
		if old then
			paintRow(old, false)
		end
		self.Selected = selected
		for i, row in self.Rows do
			paintRow(row, i == selected)
		end
		self:window(false)
		return
	end
	for _, row in self.Rows do
		row.Button:Destroy()
	end
	self.Rows = {}
	self.Items = items
	for i, item in items do
		local button = create("TextButton", {
			Name = "Row" .. i,
			Position = UDim2.fromOffset(LEFT - 4, 0),
			Size = UDim2.new(1, -(LEFT + 2), 0, ROW_H),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 3,
			Parent = self.Holder,
		})
		-- Fondo oscuro translúcido con filo de color a la izquierda
		local body = create("Frame", {
			Name = "Body",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = H.NavyLight,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = button,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 9) }),
			create("UIGradient", { Transparency = NumberSequence.new(0, 0.6) }),
		})
		local accent = create("Frame", {
			Name = "Accent",
			Position = UDim2.fromOffset(6, 7),
			Size = UDim2.new(0, 3, 1, -14),
			BackgroundColor3 = if item.Accent then H.Gold else H.Violet,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = button,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local icon = Icons.new(item.Icon, { Name = "Icon", Position = UDim2.fromOffset(16, 6), Size = UDim2.fromOffset(ROW_H - 12, ROW_H - 12), ZIndex = 4, Parent = button })
		local label = Theme.label({
			Name = "Label",
			Position = UDim2.fromOffset(ROW_H + 12, 0),
			Size = UDim2.new(0.62, -(ROW_H + 12), 1, 0),
			Font = Theme.FontBold,
			Text = item.Label,
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextStrokeTransparency = 0.6,
			ZIndex = 4,
			Parent = button,
		})
		local detail = Theme.label({
			Name = "Detail",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -30, 0, 0),
			Size = UDim2.new(0.38, -20, 1, 0),
			Text = item.Detail or "",
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 4,
			Parent = button,
		})
		local badgeDot = nil
		if item.Badge then
			badgeDot = create("Frame", { Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 16, 0, 6), BackgroundColor3 = rgb(255, 70, 90), ZIndex = 5, Parent = button }, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }),
			})
		end
		local row = { Button = button, Body = body, Label = label, Detail = detail, Accent = accent, Icon = icon, IconName = item.Icon, BadgeDot = badgeDot }
		paintRow(row, i == selected)
		table.insert(self.Rows, row)

		button.MouseEnter:Connect(function()
			if self.HoverCallback and not self.Touch then
				self.HoverCallback(i)
			end
		end)
		button.SelectionGained:Connect(function()
			if self.HoverCallback then
				self.HoverCallback(i)
			end
		end)
		button.Activated:Connect(function()
			if self.ActivateCallback then
				self.ActivateCallback(i)
			end
		end)
	end
	self.Selected = selected
	self:window(true)
	self:resize()

	if motion then
		-- Entrada: fundido y desplazamiento (de la derecha al abrir un submenú, de la izquierda al volver)
		self.List.GroupTransparency = 1
		self.Holder.Position = UDim2.fromOffset(if motion == "pop" then -26 else 26, 0)
		TweenService:Create(self.List, FADE, { GroupTransparency = 0 }):Play()
		TweenService:Create(self.Holder, FADE, { Position = UDim2.fromOffset(0, 0) }):Play()
	end
end

-- Qué filas se ven (el elegido siempre dentro) y dónde va cada una
function CommandRenderer:window(instant: boolean?)
	local n = #self.Rows
	local size = math.min(self.Window, n)
	self.First = math.clamp(self.Selected - size + 1, 1, math.max(1, n - size + 1))
	if self.Selected < self.First then
		self.First = self.Selected
	end
	self.First = math.clamp(self.First, 1, math.max(1, n - size + 1))
	for i, row in self.Rows do
		local shown = i >= self.First and i < self.First + size
		row.Button.Visible = shown
		if shown then
			row.Button.Position = UDim2.fromOffset(LEFT - 4, (i - self.First) * PITCH)
		end
	end
	self:placeSelector(instant)
	self:resize()
end

function CommandRenderer:placeSelector(instant: boolean?)
	local selector = self.Selector
	if self.Selected < 1 or self.Selected > #self.Rows then
		selector.Visible = false
		return
	end
	selector.Visible = true
	local target = UDim2.fromOffset(LEFT - 4, (self.Selected - self.First) * PITCH)
	if instant then
		selector.Position = target
	else
		TweenService:Create(selector, SLIDE, { Position = target }):Play()
	end
end

function CommandRenderer:select(index: number)
	if index == self.Selected then
		return
	end
	local old = self.Rows[self.Selected]
	if old then
		paintRow(old, false)
	end
	self.Selected = index
	local row = self.Rows[index]
	if row then
		paintRow(row, true)
	end
	self:window(false)
end

-- Destello al aceptar
function CommandRenderer:flash(index: number)
	local row = self.Rows[index]
	if not row then
		return
	end
	Theme.pop(row.Button, 1.06)
	Theme.pop(self.Selector, 1.06)
end

-- Sacudida suave (no se puede)
function CommandRenderer:shake(index: number)
	local row = self.Rows[index]
	if not row then
		return
	end
	local start = row.Button.Position
	task.spawn(function()
		for _, x in { 8, -6, 4, -2, 0 } do
			row.Button.Position = start + UDim2.fromOffset(x, 0)
			task.wait(0.03)
		end
	end)
end

function CommandRenderer:setCollapsed(collapsed: boolean)
	self.Collapsed = collapsed
	self:resize()
end

function CommandRenderer:setExpanded(expanded: boolean, rows: number)
	self.Expanded = expanded
	self:setWindow(rows)
end

function CommandRenderer:setVisible(visible: boolean)
	if self.Visible == visible then
		return
	end
	self.Visible = visible
	self.Root.Visible = visible
	if visible then
		self.List.GroupTransparency = 1
		self.Holder.Position = UDim2.fromOffset(-30, 0)
		TweenService:Create(self.List, FADE, { GroupTransparency = 0 }):Play()
		TweenService:Create(self.Holder, FADE, { Position = UDim2.fromOffset(0, 0) }):Play()
	end
end

return CommandRenderer
