-- ContextStrip: la tira de acciones de AHORA (lo que antes salía arriba del todo en COMANDOS): hablar
-- con quien tienes delante, entrar, comprar billete, montar, bajarse, saludar, atacar, disparar,
-- apuntar, recargar, robar, detener… Va junto a los botones (nunca dentro del ValPhone): son cosas
-- que se usan al momento. Solo dibuja; qué acciones hay y qué hacen lo decide Commands/CommandMenu.
--
--   Ordenador -> una columna de píldoras encima de la lista de teclas, abajo a la derecha
--                (HudLayout.Items.Context). La de abajo es la más importante. La elegida va en azul
--                (ratón encima o cruceta ↑ ↓) y dice su tecla: «E» si es algo del mapa (la tecla de
--                usar), «Enter» si no.
--   Móvil     -> la burbuja «Acciones» del racimo de botones (TouchLayout, hueco Contexto) con el
--                icono de la primera acción y cuántas hay; con una sola, tocarla la hace; con varias,
--                se abre esta lista a su izquierda y un toque en una píldora la hace.
--   Si hay más de las que caben, la última píldora es «⋯ Más» y pasa de página: ninguna se pierde.
--
--        ┌──────────────────────────────┐
--        │ ACCIONES                     │
--        │ 🎫 Comprar billete  Taquilla  │
--        │▌💬 Hablar           Marta   E │  <- la elegida (azul) con su tecla
--        └──────────────────────────────┘

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud
local rgb = Color3.fromRGB

local ContextStrip = {}
ContextStrip.__index = ContextStrip

local PITCH = HudLayout.Sizes.ContextPitch
local CHIP_H = PITCH - 6
local CAPTION = 24
local QUICK = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SELECTED = ColorSequence.new(rgb(40, 140, 255), rgb(22, 70, 215))
local PLAIN = ColorSequence.new(rgb(255, 255, 255), rgb(170, 185, 215))

export type Item = { Label: string, Detail: string?, Icon: string, Accent: boolean?, Group: boolean?, Key: string?, Back: boolean? }

function ContextStrip.new(parent: ScreenGui, touch: boolean)
	local self = setmetatable({}, ContextStrip)
	self.Touch = touch
	self.Items = {} :: { Item }
	self.Chips = {} :: { TextButton }
	self.Selected = 0
	self.Rows = 4
	self.Page = 1
	self.Shown = false
	self.Title = "Acciones"
	self.ActivateCallback = nil :: ((number) -> ())?
	self.HoverCallback = nil :: ((number) -> ())?
	self.CloseCallback = nil :: (() -> ())?

	-- (móvil) tocar fuera de la lista la cierra
	if touch then
		local scrim = create("TextButton", {
			Name = "ContextScrim",
			Size = UDim2.new(1, 4000, 1, 4000),
			Position = UDim2.fromOffset(-2000, -2000),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.8,
			AutoButtonColor = false,
			Text = "",
			Visible = false,
			ZIndex = 1,
			Parent = parent,
		})
		scrim.Activated:Connect(function()
			if self.CloseCallback then
				self.CloseCallback()
			end
		end)
		self.Scrim = scrim
	end
	local root = create("Frame", {
		Name = "ContextStrip",
		AnchorPoint = Vector2.new(1, 1),
		Size = UDim2.fromOffset(HudLayout.Sizes.ContextWidth, CAPTION + PITCH),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = parent,
	})
	self.Root = root
	self.Caption = Theme.title({
		Name = "Caption",
		AnchorPoint = Vector2.new(1, 1),
		Size = UDim2.fromOffset(HudLayout.Sizes.ContextWidth - 8, 20),
		TextSize = 15,
		Text = "ACCIONES",
		TextColor3 = H.SelectLight,
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		Parent = root,
	})
	return self
end

-- Coloca la tira (HudLayout.Items.Context) y cuántas píldoras caben
function ContextStrip:place(placement: HudLayout.Placement, rows: number)
	self.Rows = math.max(1, rows)
	HudLayout.apply(self.Root, placement, true)
	self:render()
end

-- (móvil) abre la lista pegada a la burbuja: at = esquina de abajo a la derecha (en el lienzo)
function ContextStrip:anchorAt(position: UDim2)
	self.Root.AnchorPoint = Vector2.new(1, 1)
	self.Root.Position = position
end

local function paint(chip: TextButton, on: boolean, accent: boolean?)
	local body = chip:FindFirstChild("Body") :: Frame?
	local gradient = body and body:FindFirstChild("Tint") :: UIGradient?
	if gradient then
		gradient.Color = if on then SELECTED else PLAIN
	end
	if body then
		body.BackgroundColor3 = if on then Color3.new(1, 1, 1) else H.Navy
		body.BackgroundTransparency = if on then 0.05 else 0.22
	end
	local edge = chip:FindFirstChild("Edge", true) :: UIStroke?
	if edge then
		edge.Color = if on then H.Glow elseif accent then H.Gold else H.Edge
		edge.Transparency = if on then 0 else 0.35
	end
	local label = chip:FindFirstChild("Label") :: TextLabel?
	if label then
		label.FontFace = if on then Theme.TitleFace else Font.fromEnum(Theme.FontBold)
	end
	local key = chip:FindFirstChild("Key") :: TextLabel?
	if key then
		key.Visible = on and key.Text ~= ""
	end
end

function ContextStrip:buildChip(index: number, item: Item, slot: number): TextButton
	local width = HudLayout.Sizes.ContextWidth
	local chip = create("TextButton", {
		Name = if index > 0 then "Chip" .. index else "ChipMore",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, -(slot - 1) * PITCH),
		Size = UDim2.fromOffset(width, CHIP_H),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = self.Root,
	})
	local body = create("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = chip,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIGradient", { Name = "Tint", Rotation = 90, Color = PLAIN }),
	})
	create("UIStroke", { Name = "Edge", Color = if item.Accent then H.Gold else H.Edge, Thickness = 1.6, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = body })
	-- Lo que tienes delante lleva un filo dorado a la izquierda
	if item.Accent then
		create("Frame", { Name = "Accent", Position = UDim2.fromOffset(5, 9), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = H.Gold, BorderSizePixel = 0, ZIndex = 5, Parent = chip }, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
	end
	if index > 0 then
		Icons.new(item.Icon, { Name = "Icon", Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(CHIP_H - 16, CHIP_H - 16), ZIndex = 5, Parent = chip })
	else
		for i = 1, 3 do
			Icons.dot({ Name = "Dot" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(18 + (i - 1) * 9, CHIP_H / 2), Size = UDim2.fromOffset(6, 6), ZIndex = 5, Parent = chip })
		end
	end
	local keyRoom = if self.Touch then 14 else 58
	Theme.label({
		Name = "Label",
		Position = UDim2.fromOffset(CHIP_H + 4, 0),
		Size = UDim2.new(0.56, -(CHIP_H + 4), 1, 0),
		Font = Theme.FontBold,
		TextSize = 16,
		Text = item.Label,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextStrokeTransparency = 0.6,
		ZIndex = 5,
		Parent = chip,
	})
	Theme.label({
		Name = "Detail",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -keyRoom, 0, 0),
		Size = UDim2.new(0.44, -keyRoom, 1, 0),
		TextSize = 13,
		Text = item.Detail or "",
		TextColor3 = C.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Parent = chip,
	})
	if item.Group then
		Icons.chevron({ Name = "Open", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(9, 14), Thickness = 2.5, Color = H.Glow, ZIndex = 6, Parent = chip })
	end
	-- (ordenador) la tecla de la elegida
	if not self.Touch and not item.Group then
		local key = Theme.label({
			Name = "Key",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(46, 22),
			BackgroundColor3 = H.Navy,
			BackgroundTransparency = 0.15,
			Font = Theme.FontBold,
			TextSize = 12,
			Text = item.Key or "",
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = false,
			ZIndex = 6,
			Parent = chip,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = key })
		create("UIStroke", { Color = H.Glow, Transparency = 0.3, Parent = key })
	end
	paint(chip, false, item.Accent)
	chip.MouseEnter:Connect(function()
		if index > 0 and self.HoverCallback then
			self.HoverCallback(index)
		end
	end)
	Theme.pressable(chip)
	chip.Activated:Connect(function()
		if index == 0 then
			self:nextPage()
		elseif self.ActivateCallback then
			self.ActivateCallback(index)
		end
	end)
	chip:SetAttribute("Index", index)
	return chip
end

-- Página a la vista: qué acciones salen (con «⋯ Más» si no caben todas)
function ContextStrip:pageItems(): ({ number }, boolean)
	local count = #self.Items
	local rows = self.Rows
	if count <= rows then
		local all = {}
		for i = 1, count do
			table.insert(all, i)
		end
		return all, false
	end
	local per = math.max(1, rows - 1)
	local pages = math.ceil(count / per)
	if self.Page > pages then
		self.Page = 1
	end
	local list = {}
	for i = (self.Page - 1) * per + 1, math.min(count, self.Page * per) do
		table.insert(list, i)
	end
	return list, true
end

function ContextStrip:render()
	for _, chip in self.Chips do
		chip:Destroy()
	end
	self.Chips = {}
	local list, more = self:pageItems()
	for slot, index in list do
		local chip = self:buildChip(index, self.Items[index], slot)
		self.Chips[index] = chip
		paint(chip, index == self.Selected, self.Items[index].Accent)
	end
	local used = #list
	if more then
		used += 1
		local count = #self.Items
		local per = math.max(1, self.Rows - 1)
		local chip = self:buildChip(0, { Label = "Más", Detail = ("%d/%d"):format(self.Page, math.ceil(count / per)), Icon = "mas" }, used)
		self.MoreChip = chip
	else
		self.MoreChip = nil
	end
	self.Caption.Position = UDim2.new(1, -4, 1, -(used * PITCH) - 2)
	Theme.setText(self.Caption, string.upper(self.Title))
	self.Root.Size = UDim2.fromOffset(HudLayout.Sizes.ContextWidth, CAPTION + math.max(1, self.Rows) * PITCH)
end

-- items: las acciones; selected: la elegida (0 = ninguna); title: el título de arriba
function ContextStrip:setItems(items: { Item }, selected: number, title: string?)
	local same = #items == #self.Items and (title or "Acciones") == self.Title
	if same then
		for i, item in items do
			local old = self.Items[i]
			if old.Label ~= item.Label or old.Detail ~= item.Detail or old.Icon ~= item.Icon or old.Accent ~= item.Accent or old.Group ~= item.Group then
				same = false
				break
			end
		end
	end
	self.Items = items
	self.Title = title or "Acciones"
	if same then
		-- Lo mismo de antes: solo cambia la tecla de la elegida (sin rehacer las píldoras bajo el ratón)
		for i, chip in self.Chips do
			local key = chip:FindFirstChild("Key") :: TextLabel?
			if key and items[i] then
				Theme.setText(key, items[i].Key or "")
			end
		end
	else
		self:render()
	end
	self:select(selected)
end

function ContextStrip:select(index: number)
	self.Selected = index
	-- Si la elegida está en otra página, se va a esa página
	if index > 0 and #self.Items > self.Rows then
		local per = math.max(1, self.Rows - 1)
		local page = math.ceil(index / per)
		if page ~= self.Page then
			self.Page = page
			self:render()
		end
	end
	for i, chip in self.Chips do
		paint(chip, i == index, self.Items[i] and self.Items[i].Accent)
	end
end

function ContextStrip:nextPage()
	self.Page += 1
	self:render()
end

-- Destella la píldora al usarla
function ContextStrip:flash(index: number)
	local chip = self.Chips[index]
	local body = chip and chip:FindFirstChild("Body") :: Frame?
	if body then
		body.BackgroundTransparency = 0
		TweenService:Create(body, QUICK, { BackgroundTransparency = 0.22 }):Play()
	end
end

function ContextStrip:setVisible(value: boolean)
	self.Shown = value
	self.Root.Visible = value
	if self.Scrim then
		self.Scrim.Visible = value
	end
end

-- Todas las píldoras que existen ahora (pruebas): { [índice] = píldora }
function ContextStrip:chips(): { [number]: TextButton }
	return self.Chips
end

return ContextStrip
