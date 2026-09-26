-- SupermarketUI (cliente): la parte que ves en los supermercados.
--   * Carrito (a la derecha): lo que llevas, cuánto suma y un botón "−" para devolver cosas.
--   * Ticket al pagar (caja o autocobro): la lista, el total y "Pagar con tarjeta".
--   * Cajero/a: los productos del cliente en la cinta; pulsas cada uno para pasarlo por el lector
--     (pip). Si el cliente paga en efectivo, eliges el cambio correcto.
--   * Charcutería: pides producto y gramos; el charcutero ve el pedido y lo corta y pesa.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local SoundFx = require(script.Parent.SoundFx)
local Format = require(ReplicatedStorage.Shared.Format)
local Groceries = require(ReplicatedStorage.Shared.Groceries)

local SupermarketUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Supermarket") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local gui: ScreenGui
local cartPanel: Frame
local cartList: Frame
local cartTotal: TextLabel
local waiting: TextLabel

---------------------------------------------------------------------
-- Carrito
---------------------------------------------------------------------
local function refreshCart()
	local raw = player:GetAttribute("Cart")
	for _, child in cartList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if typeof(raw) ~= "string" then
		cartPanel.Visible = false
		return
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok then
		cartPanel.Visible = false
		return
	end
	cartPanel.Visible = true
	for i, item in data.Items do
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = i, Parent = cartList })
		Theme.label({
			Size = UDim2.new(1, -36, 1, 0),
			Text = ("%s %d× %s  %s"):format(item.Icon, item.Count, item.Name, Format.money(item.Price * item.Count)),
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local minus = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(28, 22), Text = "−", TextSize = 16, Parent = row })
		minus.Activated:Connect(function()
			Remote:FireServer("Return", item.Id)
		end)
	end
	cartTotal.Text = ("Total: %s · paga en una caja 🧾"):format(Format.money(data.Total))
	cartPanel.Size = UDim2.fromOffset(250, math.min(360, 64 + #data.Items * 28))
end

---------------------------------------------------------------------
-- Ticket
---------------------------------------------------------------------
local function receipt(token: string, list: { any }, total: number, mode: string)
	waiting.Visible = false
	local height = math.min(460, 170 + #list * 26)
	local window, content, close = Dialog.window("SuperReceipt", "🧾 Ticket · " .. mode, Vector2.new(400, height))
	local scroll = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -64),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	for i, item in list do
		Theme.label({
			Size = UDim2.new(1, -10, 0, 24),
			Text = ("%s %d× %s ........ %s"):format(item.Icon, item.Count, item.Name, Format.money(item.Price * item.Count)),
			TextSize = 14,
			LayoutOrder = i,
			Parent = scroll,
		})
	end
	local payButton = Theme.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 50),
		Text = ("💳 Pagar %s"):format(Format.money(total)),
		TextSize = 20,
		BackgroundColor3 = rgb(0, 150, 80),
		Parent = content,
	})
	local paid = false
	payButton.Activated:Connect(function()
		paid = true
		Remote:FireServer("Pay", token)
		SoundFx.play("Aviso", 1, 1.4)
		window:Destroy()
	end)
	window.Destroying:Connect(function()
		if not paid then
			Remote:FireServer("CancelPay", token)
		end
	end)
	local _ = close
end

---------------------------------------------------------------------
-- Cajero: pasar productos y dar el cambio
---------------------------------------------------------------------
local function scan(token: string, list: { any }, customer: string)
	local window, content = Dialog.window("SuperScan", ("🧾 Cobrando a %s"):format(customer), Vector2.new(520, 400))
	local info = Theme.label({ Size = UDim2.new(1, 0, 0, 24), Text = "Pulsa cada producto para pasarlo por el lector:", TextSize = 14, TextColor3 = C.Muted, Parent = content })
	local _ = info
	local belt = create("Frame", { Size = UDim2.new(1, 0, 1, -30), Position = UDim2.fromOffset(0, 28), BackgroundColor3 = rgb(25, 25, 28), BorderSizePixel = 0, Parent = content })
	Theme.corner(10).Parent = belt
	Theme.padding(8).Parent = belt
	create("UIGridLayout", { CellSize = UDim2.fromOffset(110, 64), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = belt })
	for i, item in list do
		local button = Theme.button({
			Text = ("%s\n%d× %s"):format(item.Icon, item.Count, item.Name),
			TextSize = 12,
			TextWrapped = true,
			LayoutOrder = i,
			BackgroundColor3 = C.PanelLight,
			Parent = belt,
		})
		local done = false
		button.Activated:Connect(function()
			if done then
				return
			end
			done = true
			button.BackgroundColor3 = rgb(0, 150, 80)
			button.Text = ("✅ %s\n%s"):format(item.Icon, Format.money(item.Price * item.Count))
			SoundFx.play("Aviso", 0.8, 1.8) -- pip del lector
			Remote:FireServer("Scan", token, i)
		end)
	end
	window:SetAttribute("Token", token)
end

local function change(token: string, total: number, paid: number, options: { number })
	local window, content = Dialog.window("SuperScan", "💶 El cliente paga en efectivo", Vector2.new(460, 300))
	Theme.label({
		Size = UDim2.new(1, 0, 0, 60),
		Text = ("Total: %s\nEl cliente te da %s. ¿Cuánto cambio le devuelves?"):format(Format.money(total), Format.money(paid)),
		TextSize = 17,
		TextWrapped = true,
		Parent = content,
	})
	local row = create("Frame", { Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 90), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = row })
	for _, value in options do
		local button = Theme.button({ Size = UDim2.fromOffset(120, 64), Text = Format.money(value), TextSize = 22, BackgroundColor3 = C.PanelLight, Parent = row })
		button.Activated:Connect(function()
			Remote:FireServer("Change", token, value)
		end)
	end
	local _ = window
end

---------------------------------------------------------------------
-- Charcutería
---------------------------------------------------------------------
local function picker(content: Frame, y: number, title: string, options: { any }, labelOf: (any) -> string, onPick: (any) -> ())
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, y), Text = title, TextSize = 14, TextColor3 = C.Muted, Parent = content })
	local row = create("Frame", { Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromOffset(0, y + 24), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = row })
	local buttons = {}
	for _, option in options do
		local button = Theme.button({ Size = UDim2.fromOffset(88, 52), Text = labelOf(option), TextSize = 12, TextWrapped = true, BackgroundColor3 = C.PanelLight, Parent = row })
		button.Activated:Connect(function()
			for _, b in buttons do
				b.BackgroundColor3 = C.PanelLight
			end
			button.BackgroundColor3 = C.Accent
			onPick(option)
		end)
		table.insert(buttons, button)
	end
end

local function deliMenu(products: { any }, grams: { number })
	local _, content = Dialog.window("SuperDeli", "🔪 Charcutería · pide al corte", Vector2.new(500, 330))
	local chosen, weight = nil, nil
	local confirm: TextButton
	local function update()
		if chosen and weight then
			confirm.Text = ("Pedir %d g de %s (%s)"):format(weight, chosen.Name, Format.money(math.max(1, math.ceil(chosen.Per100 * weight / 100))))
			confirm.BackgroundColor3 = rgb(0, 150, 80)
		end
	end
	picker(content, 0, "¿Qué quieres?", products, function(p)
		return ("%s\n%s"):format(p.Icon, p.Name)
	end, function(p)
		chosen = p
		update()
	end)
	picker(content, 90, "¿Cuánto?", grams, function(g)
		return ("%d g"):format(g)
	end, function(g)
		weight = g
		update()
	end)
	confirm = Theme.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, 0, 0, 48), Text = "Elige producto y peso", TextSize = 16, BackgroundColor3 = C.PanelLight, Parent = content })
	confirm.Activated:Connect(function()
		if chosen and weight then
			Remote:FireServer("DeliOrder", chosen.Id, weight)
			Dialog.close("SuperDeli")
		end
	end)
end

local function deliWork(token: string, orderText: string, customer: string)
	local products = Groceries.Deli
	local grams = Groceries.DeliGrams
	local _, content = Dialog.window("SuperDeliWork", "🔪 Pedido de " .. customer, Vector2.new(500, 360))
	Theme.label({ Size = UDim2.new(1, 0, 0, 30), Text = "Te piden: " .. orderText, Font = Theme.FontBold, TextSize = 18, Parent = content })
	local chosen, weight = nil, nil
	picker(content, 36, "Producto", products, function(p)
		return ("%s\n%s"):format(p.Icon, p.Name)
	end, function(p)
		chosen = p
	end)
	picker(content, 126, "Peso en la báscula", grams, function(g)
		return ("%d g"):format(g)
	end, function(g)
		weight = g
	end)
	local serve = Theme.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, 0, 0, 48), Text = "🔪 Cortar, pesar y entregar", TextSize = 16, BackgroundColor3 = rgb(0, 150, 80), Parent = content })
	serve.Activated:Connect(function()
		if chosen and weight then
			SoundFx.play("Clic", 1, 0.7)
			Remote:FireServer("DeliServe", token, chosen.Id, weight)
		end
	end)
end

---------------------------------------------------------------------
function SupermarketUI.init()
	gui = create("ScreenGui", { Name = "SupermarketGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	cartPanel = Theme.panel({
		Name = "Cart",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(250, 120),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = cartPanel
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "🛒 Tu carrito", Font = Theme.FontBold, TextSize = 16, Parent = cartPanel })
	cartList = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -50),
		Position = UDim2.fromOffset(0, 24),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = cartPanel,
	})
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = cartList })
	cartTotal = Theme.label({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 22), TextSize = 13, TextColor3 = C.Money, Font = Theme.FontBold, Parent = cartPanel })
	waiting = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(420, 36),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = C.Panel,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		Parent = gui,
	})
	Theme.corner(10).Parent = waiting

	player:GetAttributeChangedSignal("Cart"):Connect(refreshCart)
	refreshCart()

	Remote.OnClientEvent:Connect(function(action, a, b, c, d)
		if action == "Receipt" then
			receipt(a, b, c, d)
		elseif action == "Waiting" then
			waiting.Text = a or ""
			waiting.Visible = a ~= nil
			if a then
				task.delay(20, function()
					if waiting.Text == a then
						waiting.Visible = false
					end
				end)
			end
		elseif action == "Scan" then
			scan(a, b, c)
		elseif action == "ScanDone" then
			Dialog.close("SuperScan")
			waiting.Text = b
			waiting.Visible = true
			task.delay(8, function()
				waiting.Visible = false
			end)
		elseif action == "Change" then
			change(a, b, c, d)
		elseif action == "CloseScan" then
			Dialog.close("SuperScan")
			waiting.Visible = false
		elseif action == "DeliMenu" then
			deliMenu(a, b)
		elseif action == "DeliWork" then
			deliWork(a, b, c)
		elseif action == "CloseDeli" then
			Dialog.close("SuperDeliWork")
		end
	end)
end

return SupermarketUI
