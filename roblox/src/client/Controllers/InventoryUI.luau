-- InventoryUI (cliente): la mochila al estilo Minecraft.
--   * Barra rápida abajo en el centro: 9 casillas. Teclas 1-9 (o tocar) para elegir;
--     pulsar otra vez la misma (o clic derecho) la usa: comer, montarte en tu bici, ponerte las gafas…
--     Al cambiar de casilla aparece el nombre del objeto encima, y se desvanece.
--   * Tecla E (o el botón 🎒): se abre la mochila con la pantalla oscurecida, tu personaje girando,
--     27 casillas + la barra rápida. Clic para coger un objeto (se queda pegado al ratón) y clic en otra
--     casilla para dejarlo o intercambiarlo. Clic derecho = usar. Q = tirar uno (comida y objetos).
-- El servidor (InventoryService) guarda el orden y valida todo; aquí solo se dibuja y se pide.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Items = require(ReplicatedStorage.Shared.Items)
local Theme = require(script.Parent.Parent.UI.Theme)
local Hud = require(script.Parent.Parent.UI.Hud)

local create = Theme.create

local InventoryUI = {}

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Remote: RemoteEvent

-- Colores de Minecraft
local MC = {
	Panel = Color3.fromRGB(198, 198, 198),
	Light = Color3.fromRGB(255, 255, 255),
	Shade = Color3.fromRGB(85, 85, 85),
	Slot = Color3.fromRGB(139, 139, 139),
	SlotDark = Color3.fromRGB(55, 55, 55),
	Text = Color3.fromRGB(63, 63, 63),
	Tooltip = Color3.fromRGB(16, 1, 16),
	TooltipBorder = Color3.fromRGB(40, 1, 90),
	Selected = Color3.fromRGB(255, 255, 255),
	InUse = Color3.fromRGB(255, 196, 60),
	Food = Color3.fromRGB(255, 170, 60),
}
local KIND_TEXT = {
	Food = "Comida · clic derecho para comer",
	Vehicle = "Vehículo · clic derecho para montarte",
	Wear = "Ropa · clic derecho para ponértelo",
	Thing = "Objeto",
	Prize = "Premio",
	Document = "Documento",
	Keepsake = "Recuerdo de tu historia",
}
local NUMBER_KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
}

local HOTBAR_SLOT = 50
local BAG_SLOT = 44
local GAP = 4

type SlotView = {
	Button: TextButton,
	Icon: TextLabel,
	Count: TextLabel,
	Hover: Frame,
	InUse: UIStroke,
}
type Entry = { i: string, n: number }

local slots: { Entry? } = {} -- lo que dice el servidor (1-36)
local hotbarViews: { SlotView } = {}
local bagViews: { [number]: SlotView } = {} -- casillas de la ventana (1-36)
local selected = 1
local held: number? = nil -- casilla cogida con el ratón
local focus: number? = nil -- casilla de la que se ven los detalles
local isOpen = false
local promptKeys: { [Enum.KeyCode]: number } = {} -- teclas que están usando los carteles de "pulsa E"

local gui: ScreenGui
local hotbar: Frame
local nameLabel: TextLabel
local nameToken = 0
local overlay: Frame
local window: Frame
local windowScale: UIScale
local viewport: ViewportFrame
local detailName: TextLabel
local detailKind: TextLabel
local detailDesc: TextLabel
local useButton: TextButton
local dropButton: TextButton
local cursorGui: ScreenGui
local ghost: TextLabel
local tooltip: Frame
local tooltipName: TextLabel
local tooltipText: TextLabel
local previewModel: Model? = nil

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function has(attribute: string, key: string): boolean
	local list = player:GetAttribute(attribute)
	return typeof(list) == "string" and string.find("," .. list .. ",", "," .. key .. ",", 1, true) ~= nil
end

local function itemAt(index: number?): (Items.Item?, number)
	local entry = index and slots[index]
	if not entry then
		return nil, 0
	end
	return Items.get(entry.i), entry.n or 1
end

local function inUse(item: Items.Item?): boolean
	if not item then
		return false
	end
	if item.Kind == "Vehicle" then
		return player:GetAttribute("Riding") == item.Ref
	elseif item.Kind == "Wear" then
		return has("Wearing", item.Ref or "")
	end
	return false
end

-- Borde en relieve de Minecraft: claro arriba-izquierda y oscuro abajo-derecha (o al revés = hundido)
local function bevel(frame: GuiObject, topLeft: Color3, bottomRight: Color3, thickness: number)
	local function edge(position: UDim2, size: UDim2, color: Color3)
		create("Frame", {
			Name = "Bevel",
			Position = position,
			Size = size,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = frame.ZIndex + 1,
			Parent = frame,
		})
	end
	edge(UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, thickness), topLeft)
	edge(UDim2.fromOffset(0, 0), UDim2.new(0, thickness, 1, 0), topLeft)
	edge(UDim2.new(0, 0, 1, -thickness), UDim2.new(1, 0, 0, thickness), bottomRight)
	edge(UDim2.new(1, -thickness, 0, 0), UDim2.new(0, thickness, 1, 0), bottomRight)
end

local function makeSlot(parent: Instance, size: number, order: number, zIndex: number): SlotView
	local button = create("TextButton", {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = MC.Slot,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		ZIndex = zIndex,
		Parent = parent,
	})
	bevel(button, MC.SlotDark, MC.Light, 2)
	local icon = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		TextScaled = true,
		Text = "",
		ZIndex = zIndex + 2,
		Parent = button,
	})
	local count = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -1),
		Size = UDim2.fromOffset(size - 6, 16),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(62, 62, 62),
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		ZIndex = zIndex + 3,
		Parent = button,
	})
	local hover = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = zIndex + 4,
		Parent = button,
	})
	local stroke = create("UIStroke", {
		Color = MC.InUse,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Enabled = false,
		Parent = button,
	})
	return { Button = button, Icon = icon, Count = count, Hover = hover, InUse = stroke }
end

local function paint(view: SlotView, index: number)
	local item, count = itemAt(index)
	local hidden = held == index -- el que llevas en el ratón deja la casilla vacía
	view.Icon.Text = if item and not hidden then item.Icon else ""
	view.Count.Text = if item and not hidden and count > 1 then tostring(count) else ""
	view.InUse.Enabled = not hidden and inUse(item)
end

---------------------------------------------------------------------
-- Barra rápida
---------------------------------------------------------------------

local function showName(index: number)
	local item = itemAt(index)
	nameToken += 1
	local token = nameToken
	if not item then
		nameLabel.TextTransparency = 1
		nameLabel.TextStrokeTransparency = 1
		return
	end
	nameLabel.Text = item.Name
	nameLabel.TextTransparency = 0
	nameLabel.TextStrokeTransparency = 0.2
	task.delay(1.8, function()
		if token == nameToken then
			TweenService:Create(nameLabel, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function refreshHotbar()
	for i, view in hotbarViews do
		paint(view, i)
		view.Button:FindFirstChild("SelectedFrame").Visible = i == selected
	end
end

local useSlot: (index: number) -> ()

local function chooseSlot(index: number)
	if index == selected then
		useSlot(index) -- elegir la que ya estaba elegida = usarla
		return
	end
	selected = index
	refreshHotbar()
	showName(index)
end

local function buildHotbar()
	hotbar = create("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(0, HOTBAR_SLOT + 8),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = gui,
	})
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		Parent = hotbar,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = hotbar,
	})
	for i = 1, Items.Hotbar do
		local view = makeSlot(hotbar, HOTBAR_SLOT, i, 2)
		-- Número de la tecla, pequeño arriba a la izquierda
		create("TextLabel", {
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = Color3.fromRGB(230, 230, 230),
			TextStrokeTransparency = 0.4,
			Text = tostring(i),
			ZIndex = 6,
			Parent = view.Button,
		})
		-- Marco grueso de la casilla elegida (como el de Minecraft)
		local selectedFrame = create("Frame", {
			Name = "SelectedFrame",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 6, 1, 6),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 8,
			Parent = view.Button,
		})
		create("UIStroke", { Color = MC.Selected, Thickness = 3, Parent = selectedFrame })
		view.Button.Activated:Connect(function()
			chooseSlot(i)
		end)
		view.Button.MouseButton2Click:Connect(function()
			useSlot(i)
		end)
		hotbarViews[i] = view
	end
	-- Botón de la mochila al final de la barra (en móvil no hay tecla E)
	local bag = create("TextButton", {
		Size = UDim2.fromOffset(HOTBAR_SLOT, HOTBAR_SLOT),
		BackgroundColor3 = MC.Panel,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Theme.FontBold,
		TextScaled = true,
		Text = "🎒",
		LayoutOrder = 100,
		ZIndex = 2,
		Parent = hotbar,
	})
	bevel(bag, MC.Light, MC.Shade, 2)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		Parent = bag,
	})
	bag.Activated:Connect(function()
		InventoryUI.toggle()
	end)

	nameLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -(HOTBAR_SLOT + 24)),
		Size = UDim2.fromOffset(300, 22),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = Color3.fromRGB(40, 40, 40),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Text = "",
		Parent = gui,
	})
end

---------------------------------------------------------------------
-- Ventana de la mochila
---------------------------------------------------------------------

local function refreshDetails()
	local index = held or focus
	local item, count = itemAt(index)
	if not item then
		detailName.Text = "Mochila"
		detailKind.Text = ""
		detailDesc.Text = "Clic en un objeto para cogerlo y clic en otra casilla para dejarlo.\nClic derecho: usar · Q: tirar uno."
		useButton.Visible = false
		dropButton.Visible = false
		return
	end
	detailName.Text = item.Icon .. "  " .. item.Name .. (if count > 1 then "  ×" .. count else "")
	detailKind.Text = KIND_TEXT[item.Kind] or ""
	detailDesc.Text = item.Desc
	local usable = item.Kind == "Food" or item.Kind == "Vehicle" or item.Kind == "Wear"
	useButton.Visible = usable
	if item.Kind == "Food" then
		useButton.Text = "Comer"
	elseif item.Kind == "Vehicle" then
		useButton.Text = if inUse(item) then "Bajarse" else "Montar"
	else
		useButton.Text = if inUse(item) then "Quitar" else "Poner"
	end
	dropButton.Visible = item.Kind == "Food" or item.Kind == "Thing"
end

local function refreshWindow()
	for index, view in bagViews do
		paint(view, index)
	end
	local item = itemAt(held)
	ghost.Text = if item then item.Icon else ""
	ghost.Visible = item ~= nil
	refreshDetails()
end

local function refreshAll()
	refreshHotbar()
	if isOpen then
		refreshWindow()
	end
end

local function mcButton(text: string, parent: Instance, order: number): TextButton
	local button = create("TextButton", {
		Size = UDim2.fromOffset(92, 28),
		BackgroundColor3 = Color3.fromRGB(111, 111, 111),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.5,
		Text = text,
		LayoutOrder = order,
		ZIndex = 12,
		Parent = parent,
	})
	bevel(button, Color3.fromRGB(170, 170, 170), Color3.fromRGB(40, 40, 40), 2)
	return button
end

local function onSlotClick(index: number)
	if held == nil then
		if slots[index] then
			held = index
			focus = index
		end
	else
		if held ~= index then
			-- Cambio al momento en pantalla (el servidor lo confirma enseguida)
			slots[held], slots[index] = slots[index], slots[held]
			Remote:FireServer("Move", held, index)
			if selected == held or selected == index then
				showName(selected)
			end
		end
		focus = index
		held = nil
	end
	refreshAll()
end

local function row(parent: Instance, from: number, to: number, order: number)
	local frame = create("Frame", {
		Size = UDim2.fromOffset(0, BAG_SLOT),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = 11,
		Parent = parent,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = frame,
	})
	for index = from, to do
		local view = makeSlot(frame, BAG_SLOT, index, 11)
		view.Button.Activated:Connect(function()
			onSlotClick(index)
		end)
		view.Button.MouseButton2Click:Connect(function()
			useSlot(index)
		end)
		view.Button.MouseEnter:Connect(function()
			view.Hover.Visible = true
			if held == nil and slots[index] then
				focus = index
				refreshDetails()
			end
			local item, count = itemAt(index)
			tooltip.Visible = item ~= nil and held == nil and not UserInputService.TouchEnabled
			if item then
				tooltipName.Text = item.Name .. (if count > 1 then " ×" .. count else "")
				tooltipText.Text = KIND_TEXT[item.Kind] or ""
			end
		end)
		view.Button.MouseLeave:Connect(function()
			view.Hover.Visible = false
			tooltip.Visible = false
		end)
		bagViews[index] = view
	end
	return frame
end

local function label(text: string, parent: Instance, order: number): TextLabel
	return create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = MC.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		LayoutOrder = order,
		ZIndex = 11,
		Parent = parent,
	})
end

local function buildWindow()
	-- Pantalla oscurecida detrás (como al abrir el inventario en Minecraft)
	overlay = create("TextButton", {
		Name = "InventoryOverlay",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 9,
		Parent = gui,
	})
	-- Clic fuera de la ventana con un objeto en la mano: se devuelve a su sitio
	-- Clic fuera de la ventana: si no llevas nada en la mano, se cierra la mochila
	overlay.Activated:Connect(function()
		if held then
			held = nil
			refreshAll()
		else
			InventoryUI.close()
		end
	end)

	local rowWidth = Items.Hotbar * BAG_SLOT + (Items.Hotbar - 1) * GAP
	window = create("Frame", {
		Name = "Inventory",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(rowWidth + 28, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = MC.Panel,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 10,
		Parent = overlay,
	})
	windowScale = create("UIScale", { Parent = window })
	bevel(window, MC.Light, MC.Shade, 3)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 14),
		Parent = window,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = window })

	-- Cabecera: título y cerrar
	local header = create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 11, Parent = window })
	local title = label("Inventario", header, 1)
	title.TextSize = 18
	local close = mcButton("✕", header, 2)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(1, 0)
	close.Size = UDim2.fromOffset(34, 28)
	close.TextSize = 18
	close.Activated:Connect(function()
		InventoryUI.close()
	end)

	-- Parte de arriba: tu personaje (girando) y los detalles del objeto
	local top = create("Frame", { Size = UDim2.new(1, 0, 0, 160), BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 11, Parent = window })
	viewport = create("ViewportFrame", {
		Size = UDim2.fromOffset(120, 160),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(170, 170, 170),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-1, -1, -1),
		ZIndex = 11,
		Parent = top,
	})
	bevel(viewport, MC.SlotDark, MC.Light, 2)
	local details = create("Frame", {
		Position = UDim2.fromOffset(132, 0),
		Size = UDim2.new(1, -132, 1, 0),
		BackgroundColor3 = MC.Slot,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = top,
	})
	bevel(details, MC.SlotDark, MC.Light, 2)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		Parent = details,
	})
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = details })
	detailName = label("", details, 1)
	detailName.TextColor3 = Color3.new(1, 1, 1)
	detailName.TextStrokeTransparency = 0.6
	detailName.TextSize = 17
	detailName.Size = UDim2.new(1, 0, 0, 22)
	detailName.TextTruncate = Enum.TextTruncate.AtEnd
	detailKind = label("", details, 2)
	detailKind.TextColor3 = MC.InUse
	detailKind.TextSize = 13
	detailDesc = label("", details, 3)
	detailDesc.TextColor3 = Color3.fromRGB(240, 240, 240)
	detailDesc.Font = Theme.Font
	detailDesc.TextSize = 13
	detailDesc.TextWrapped = true
	detailDesc.TextYAlignment = Enum.TextYAlignment.Top
	detailDesc.Size = UDim2.new(1, 0, 0, 58)
	local buttons = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 4, ZIndex = 11, Parent = details })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = buttons })
	useButton = mcButton("Usar", buttons, 1)
	dropButton = mcButton("Tirar uno", buttons, 2)
	useButton.Activated:Connect(function()
		local index = held or focus
		if index then
			useSlot(index)
		end
	end)
	dropButton.Activated:Connect(function()
		local index = held or focus
		if index then
			Remote:FireServer("Drop", index)
		end
	end)

	-- Mochila (10-36) y, separada, la barra rápida (1-9), como en Minecraft
	label("Mochila", window, 3)
	row(window, 10, 18, 4)
	row(window, 19, 27, 5)
	row(window, 28, 36, 6)
	create("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundTransparency = 1, LayoutOrder = 7, Parent = window })
	-- Botón grande para volver al juego (en móvil no hay tecla E ni Escape)
	local back = mcButton("⬅  Volver al juego", window, 100)
	back.Size = UDim2.new(1, 0, 0, 38)
	back.TextSize = 17
	back.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
	back.Activated:Connect(function()
		InventoryUI.close()
	end)
	row(window, 1, 9, 8)

	-- Lo que llevas en la mano y la etiqueta al pasar el ratón (sin escala, pegados al puntero)
	cursorGui = create("ScreenGui", {
		Name = "InventoryCursor",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 20,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	ghost = create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		TextScaled = true,
		Text = "",
		Visible = false,
		Parent = cursorGui,
	})
	tooltip = create("Frame", {
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = MC.Tooltip,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		Visible = false,
		Parent = cursorGui,
	})
	create("UIStroke", { Color = MC.TooltipBorder, Thickness = 2, Parent = tooltip })
	create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3), Parent = tooltip })
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = tooltip })
	tooltipName = create("TextLabel", {
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = Color3.new(1, 1, 1),
		LayoutOrder = 1,
		Parent = tooltip,
	})
	tooltipText = create("TextLabel", {
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		LayoutOrder = 2,
		Parent = tooltip,
	})
end

-- Tu personaje dentro de la ventana, girando despacio (o siguiendo el ratón)
local function buildPreview()
	if previewModel then
		previewModel:Destroy()
		previewModel = nil
	end
	local character = player.Character
	if not character then
		return
	end
	pcall(function()
		local wasArchivable = character.Archivable
		character.Archivable = true
		local clone = character:Clone()
		character.Archivable = wasArchivable
		for _, child in clone:GetDescendants() do
			if child:IsA("BaseScript") or child:IsA("Sound") or child:IsA("ProximityPrompt") then
				child:Destroy()
			elseif child:IsA("BasePart") then
				child.Anchored = true
			end
		end
		local world = viewport:FindFirstChildOfClass("WorldModel") or create("WorldModel", { Parent = viewport })
		clone:PivotTo(CFrame.new())
		clone.Parent = world
		previewModel = clone
		local _, size = clone:GetBoundingBox()
		local camera = viewport.CurrentCamera or create("Camera", { Parent = viewport })
		camera.FieldOfView = 30
		local distance = size.Y / (2 * math.tan(math.rad(15))) + 2
		camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.3, -distance), Vector3.new(0, 0.1, 0))
		viewport.CurrentCamera = camera
	end)
end

---------------------------------------------------------------------
-- Usar
---------------------------------------------------------------------

useSlot = function(index: number)
	local item = itemAt(index)
	if not item then
		return
	end
	if item.Kind == "Food" then
		Remote:FireServer("Use", index)
	elseif item.Kind == "Vehicle" then
		local vehicle = Remotes:FindFirstChild("Vehicle") :: RemoteEvent?
		if vehicle then
			if player:GetAttribute("Riding") == item.Ref then
				vehicle:FireServer("Dismount")
			else
				vehicle:FireServer("Spawn", item.Ref)
				InventoryUI.close()
			end
		end
	elseif item.Kind == "Wear" then
		local arcade = Remotes:FindFirstChild("Arcade") :: RemoteEvent?
		if arcade then
			arcade:FireServer("Wear", item.Ref)
		end
	else
		Hud.toast("Info", item.Icon .. " " .. item.Name .. ": se guarda en tu mochila.")
	end
end

---------------------------------------------------------------------
-- Abrir y cerrar
---------------------------------------------------------------------

function InventoryUI.open()
	if isOpen or player:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	isOpen = true
	held = nil
	focus = if slots[selected] then selected else nil
	buildPreview()
	overlay.Visible = true
	cursorGui.Enabled = true
	windowScale.Scale = 0.92
	TweenService:Create(windowScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	refreshAll()
end

function InventoryUI.close()
	if not isOpen then
		return
	end
	isOpen = false
	held = nil
	overlay.Visible = false
	cursorGui.Enabled = false
	tooltip.Visible = false
	if previewModel then
		previewModel:Destroy()
		previewModel = nil
	end
	refreshAll()
end

function InventoryUI.toggle()
	if isOpen then
		InventoryUI.close()
	else
		InventoryUI.open()
	end
end

---------------------------------------------------------------------

local function readSlots()
	table.clear(slots)
	local raw = player:GetAttribute("Inventory")
	if typeof(raw) ~= "string" then
		return
	end
	local ok, decoded = pcall(function()
		return game:GetService("HttpService"):JSONDecode(raw)
	end)
	if ok and type(decoded) == "table" then
		for i = 1, Items.Slots do
			local entry = decoded[i]
			if type(entry) == "table" and type(entry.i) == "string" then
				slots[i] = { i = entry.i, n = tonumber(entry.n) or 1 }
			end
		end
	end
	if held and not slots[held] then
		held = nil
	end
end

local function updateVisibility()
	local baby = player:GetAttribute("LifeStage") == "Bebe"
	hotbar.Visible = not baby
	if baby then
		InventoryUI.close()
	end
end

function InventoryUI.init()
	Remote = Remotes:WaitForChild("Inventory") :: RemoteEvent
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- usamos nuestra propia barra
	end)

	gui = create("ScreenGui", {
		Name = "InventoryUI",
		ResetOnSpawn = false,
		DisplayOrder = 3,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 850, 0.65, 1.25)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	buildHotbar()
	buildWindow()
	readSlots()
	refreshAll()
	updateVisibility()

	player:GetAttributeChangedSignal("Inventory"):Connect(function()
		readSlots()
		refreshAll()
	end)
	for _, attribute in { "Riding", "Wearing" } do
		player:GetAttributeChangedSignal(attribute):Connect(refreshAll)
	end
	player:GetAttributeChangedSignal("LifeStage"):Connect(updateVisibility)

	-- Teclas que ya usan los carteles de "pulsa E" que tienes delante: esas no abren la mochila
	ProximityPromptService.PromptShown:Connect(function(prompt)
		promptKeys[prompt.KeyboardKeyCode] = (promptKeys[prompt.KeyboardKeyCode] or 0) + 1
		local key = prompt.KeyboardKeyCode
		local connection
		connection = prompt.PromptHidden:Connect(function()
			connection:Disconnect()
			promptKeys[key] = math.max(0, (promptKeys[key] or 1) - 1)
		end)
	end)
	local function keyFree(key: Enum.KeyCode): boolean
		return (promptKeys[key] or 0) == 0
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() or player:GetAttribute("InDialogue") or player:GetAttribute("InMiniGame") then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.E and (isOpen or keyFree(key)) then
			InventoryUI.toggle()
		elseif key == Enum.KeyCode.Escape and isOpen then
			InventoryUI.close()
		elseif key == Enum.KeyCode.Q and isOpen then
			local index = held or focus
			if index then
				Remote:FireServer("Drop", index)
			end
		elseif NUMBER_KEYS[key] and keyFree(key) and hotbar.Visible then
			if isOpen and focus and focus ~= NUMBER_KEYS[key] then
				-- Como en Minecraft: con la mochila abierta, la tecla manda el objeto a esa casilla de la barra
				local target = NUMBER_KEYS[key]
				slots[focus], slots[target] = slots[target], slots[focus]
				Remote:FireServer("Move", focus, target)
				focus = target
				refreshAll()
			elseif not isOpen then
				chooseSlot(NUMBER_KEYS[key])
			end
		end
	end)

	-- El objeto en la mano y la etiqueta siguen al ratón; el personaje gira despacio
	RunService.RenderStepped:Connect(function()
		if not isOpen then
			return
		end
		local mouse = UserInputService:GetMouseLocation()
		ghost.Position = UDim2.fromOffset(mouse.X, mouse.Y)
		tooltip.Position = UDim2.fromOffset(mouse.X + 16, mouse.Y - 20)
		local model = previewModel
		if model and model.Parent then
			model:PivotTo(CFrame.Angles(0, os.clock() * 0.8, 0))
		end
	end)
	GuiService.MenuOpened:Connect(function()
		InventoryUI.close()
	end)
end

return InventoryUI
