-- CommandRenderer: dibuja el menú de comandos (abajo a la izquierda).
--
--   ┌ ✦ COMANDOS ─────────┐     <- pestaña: el título (o con quién estás: "MARTA")
--   ▶ █ 💬 HABLAR   Marta  █     <- el elegido: brillante, más grande, desplazado y con el cursor ▶
--       🚪 ENTRAR   Tienda
--       🎒 OBJETOS
--       🗺 MAPA
--       ⋯  MÁS             ▸     <- grupo: abre un submenú
--
-- Solo dibuja; qué comandos salen y qué hacen lo decide CommandMenu.

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local CommandRenderer = {}
CommandRenderer.__index = CommandRenderer

local ROW_W, ROW_H = 250, 34
local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLIDE = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Colores propios del menú (azul noche con filo cian y un toque violeta)
local EDGE = rgb(110, 225, 255)
local VIOLET = rgb(150, 110, 255)
local IDLE = ColorSequence.new(rgb(22, 44, 96), rgb(8, 16, 40))
local ACTIVE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 255, 255)),
	ColorSequenceKeypoint.new(0.55, rgb(200, 240, 255)),
	ColorSequenceKeypoint.new(1, rgb(90, 190, 255)),
})

export type Item = { Label: string, Detail: string?, Icon: string, Group: boolean?, Accent: boolean?, Badge: boolean? }

function CommandRenderer.new(parent: Instance, touch: boolean)
	local self = setmetatable({}, CommandRenderer)
	self.Rows = {}
	self.Selected = 0
	self.HoverCallback = nil :: ((number) -> ())?
	self.ActivateCallback = nil :: ((number) -> ())?
	self.Touch = touch

	local root = create("Frame", {
		Name = "CommandMenu",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(ROW_W + 56, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	})
	self.Root = root
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = root })

	-- Pestaña del título: forma inclinada con el filo cian-violeta
	local tab = create("Frame", {
		Name = "Header",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 0,
		Parent = root,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		create("UIGradient", { Color = ColorSequence.new(VIOLET, rgb(40, 150, 255)), Rotation = 0 }),
		create("UIStroke", { Color = EDGE, Thickness = 1.5, Transparency = 0.2 }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 16) }),
	})
	self.HeaderText = Theme.label({
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = Theme.TitleFace,
		TextSize = 15,
		TextStrokeTransparency = 0.5,
		Text = "✦ COMANDOS",
		Parent = tab,
	})

	-- La lista va en un CanvasGroup para poder entrar y salir con fundido
	local list = create("CanvasGroup", {
		Name = "List",
		Size = UDim2.fromOffset(ROW_W + 56, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = root,
	})
	self.List = list
	self.Holder = create("Frame", { Size = UDim2.fromOffset(ROW_W + 56, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = list })
	create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Holder })
	create("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4), Parent = self.Holder })

	-- Cursor ▶ que se mueve hasta el comando elegido y late suavemente
	self.Cursor = Theme.label({
		Name = "Cursor",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(16, 20),
		Text = "▶",
		TextSize = 16,
		TextColor3 = C.Gold,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 5,
		Parent = list,
	})
	task.spawn(function()
		local t = 0
		while root.Parent do
			t += task.wait()
			local base = self.CursorY or 0
			self.Cursor.Position = UDim2.fromOffset(-1 + math.sin(t * 7) * 2.5, base)
		end
	end)

	self.Hint = Theme.label({
		Name = "Hint",
		Size = UDim2.fromOffset(ROW_W + 20, 14),
		TextSize = 11,
		TextColor3 = C.Muted,
		TextStrokeTransparency = 0.5,
		Text = "",
		LayoutOrder = 2,
		Visible = not touch,
		Parent = root,
	})
	return self
end

function CommandRenderer:setHeader(text: string)
	Theme.setText(self.HeaderText, "✦ " .. string.upper(text))
end

function CommandRenderer:setHint(text: string)
	self.Hint.Text = text
end

local function paint(row: { [string]: any }, on: boolean, instant: boolean?)
	local info = if instant then TweenInfo.new(0) else QUICK
	row.Fill.Color = if on then ACTIVE else IDLE
	row.Fill.Transparency = if on
		then NumberSequence.new(0)
		else NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.7, 0.25), NumberSequenceKeypoint.new(1, 0.75) })
	row.Label.TextColor3 = if on then C.Ink else C.Text
	row.Label.TextStrokeTransparency = if on then 1 else 0.6
	row.Detail.TextColor3 = if on then rgb(40, 70, 120) else C.Muted
	row.Arrow.TextColor3 = if on then C.Ink else C.Muted
	row.Stroke.Color = if on then EDGE else rgb(70, 120, 200)
	row.Stroke.Transparency = if on then 0 else 0.55
	row.Stroke.Thickness = if on then 2 else 1
	TweenService:Create(row.Scale, info, { Scale = if on then 1.06 else 1 }):Play()
	TweenService:Create(row.Inner, info, { Position = UDim2.fromOffset(if on then 12 else 0, 0) }):Play()
	TweenService:Create(row.Glow, info, { BackgroundTransparency = if on then 0.55 else 1 }):Play()
end

-- items: lo que se enseña; selected: cuál va elegido; motion: "push" (entra un submenú),
-- "pop" (se vuelve atrás) o nil (solo ha cambiado lo que hay alrededor)
function CommandRenderer:setItems(items: { Item }, selected: number, motion: string?)
	for _, row in self.Rows do
		row.Button:Destroy()
	end
	self.Rows = {}
	for i, item in items do
		local button = create("TextButton", {
			Name = "Row" .. i,
			Size = UDim2.fromOffset(ROW_W, ROW_H),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = i,
			Parent = self.Holder,
		})
		local scale = create("UIScale", { Parent = button })
		local inner = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = button })
		-- Halo detrás del elegido
		local glow = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 10, 1, 10),
			BackgroundColor3 = EDGE,
			BackgroundTransparency = 1,
			ZIndex = 0,
			Parent = inner,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
		local body = create("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 1,
			Parent = inner,
		}, {
			-- esquina izquierda recta y derecha redondeada: se lee como una lista que sale del borde
			create("UICorner", { CornerRadius = UDim.new(0, 9) }),
		})
		local fill = create("UIGradient", { Rotation = 0, Parent = body })
		local stroke = create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = body })
		-- Filo de color a la izquierda (dorado si es lo que tienes delante)
		create("Frame", {
			Size = UDim2.new(0, 4, 1, -8),
			Position = UDim2.fromOffset(4, 4),
			BackgroundColor3 = if item.Accent then C.Gold else VIOLET,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = body,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 2) }) })
		Theme.label({ Size = UDim2.fromOffset(26, ROW_H), Position = UDim2.fromOffset(12, 0), Text = item.Icon, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2, Parent = body })
		local label = Theme.label({
			Size = UDim2.new(0.62, -40, 1, 0),
			Position = UDim2.fromOffset(42, 0),
			FontFace = Theme.ItalicFace,
			Text = string.upper(item.Label),
			TextSize = 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Parent = body,
		})
		local detail = Theme.label({
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.new(0.38, 0, 1, 0),
			Position = UDim2.new(1, -24, 0, 0),
			Text = item.Detail or "",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Parent = body,
		})
		local arrow = Theme.label({ AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(18, ROW_H), Position = UDim2.new(1, -4, 0, 0), Text = if item.Group then "▸" else "", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2, Parent = body })
		if item.Badge then
			create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Position = UDim2.new(1, -30, 0.5, 0), BackgroundColor3 = rgb(255, 70, 90), ZIndex = 3, Parent = body }, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }),
			})
		end
		local row = { Button = button, Scale = scale, Inner = inner, Glow = glow, Fill = fill, Stroke = stroke, Label = label, Detail = detail, Arrow = arrow }
		paint(row, i == selected, true)
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
	self:placeCursor(true)

	if motion then
		-- Entrada: fundido y desplazamiento (de la derecha al abrir un submenú, de la izquierda al volver)
		self.List.GroupTransparency = 1
		self.Holder.Position = UDim2.fromOffset(if motion == "pop" then -26 else 26, 0)
		TweenService:Create(self.List, SLIDE, { GroupTransparency = 0 }):Play()
		TweenService:Create(self.Holder, SLIDE, { Position = UDim2.fromOffset(0, 0) }):Play()
	end
end

function CommandRenderer:placeCursor(instant: boolean?)
	local y = 2 + (self.Selected - 1) * (ROW_H + 3) + ROW_H / 2
	if self.Selected < 1 then
		self.Cursor.Visible = false
		return
	end
	self.Cursor.Visible = true
	if instant or not self.CursorY then
		self.CursorY = y
	else
		-- el cursor viaja hasta su sitio
		local from = self.CursorY
		local started = os.clock()
		task.spawn(function()
			while os.clock() - started < 0.12 do
				local a = (os.clock() - started) / 0.12
				self.CursorY = from + (y - from) * (1 - (1 - a) ^ 3)
				task.wait()
			end
			self.CursorY = y
		end)
	end
end

function CommandRenderer:select(index: number)
	if index == self.Selected then
		return
	end
	local old = self.Rows[self.Selected]
	if old then
		paint(old, false)
	end
	self.Selected = index
	local row = self.Rows[index]
	if row then
		paint(row, true)
	end
	self:placeCursor(false)
end

-- Destello al aceptar
function CommandRenderer:flash(index: number)
	local row = self.Rows[index]
	if not row then
		return
	end
	row.Scale.Scale = 1.13
	TweenService:Create(row.Scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.06 }):Play()
	row.Glow.BackgroundTransparency = 0.1
	TweenService:Create(row.Glow, TweenInfo.new(0.3), { BackgroundTransparency = 0.55 }):Play()
end

-- Sacudida suave (no se puede)
function CommandRenderer:shake(index: number)
	local row = self.Rows[index]
	if not row then
		return
	end
	task.spawn(function()
		for _, x in { 8, -6, 4, -2, 0 } do
			row.Inner.Position = UDim2.fromOffset(12 + x, 0)
			task.wait(0.03)
		end
	end)
end

function CommandRenderer:setVisible(visible: boolean)
	if self.Root.Visible == visible then
		return
	end
	self.Root.Visible = visible
	if visible then
		self.List.GroupTransparency = 1
		self.Holder.Position = UDim2.fromOffset(-30, 0)
		TweenService:Create(self.List, SLIDE, { GroupTransparency = 0 }):Play()
		TweenService:Create(self.Holder, SLIDE, { Position = UDim2.fromOffset(0, 0) }):Play()
	end
end

return CommandRenderer
