-- TradeUI (cliente): intercambio entre jugadores y mercadillo.
--   * Toca a otro jugador y elige "🤝 Comerciar" en su menú (PlayerMenuUI). Si acepta, se abre la ventana:
--     a la izquierda lo que das tú (toca tus cosas para añadirlas y pon dinero), a la derecha lo que
--     te da. Los dos pulsan "Aceptar" y, tras una cuenta atrás corta, se hace el cambio.
--   * App "🛍️ Mercadillo" del teléfono: comprar lo que venden otros y poner tus cosas a la venta.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local Format = require(ReplicatedStorage.Shared.Format)
local Items = require(ReplicatedStorage.Shared.Items)
local Trade = require(ReplicatedStorage.Shared.Trade)

local TradeUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Trade") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB
local GREY = rgb(50, 52, 60)

-- Lo que llevas en la mochila que se puede intercambiar: { {Id, Name, Icon, Count} }
local function myItems(): { any }
	local list = {}
	local ok, slots = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Inventory") or "[]")
	end)
	for _, slot in if ok and typeof(slots) == "table" then slots else {} do
		if typeof(slot) == "table" and slot.i and Trade.tradeable(slot.i) then
			local item = Items.get(slot.i) :: any
			table.insert(list, { Id = slot.i, Name = item.Name, Icon = item.Icon, Count = slot.n or 1 })
		end
	end
	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)
	return list
end

local function money(): number
	return player:GetAttribute("Money") or 0
end

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function scroller(parent: Instance, props: { [string]: any }): ScrollingFrame
	local frame = create("ScrollingFrame", {
		BackgroundColor3 = rgb(8, 14, 28),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	for k, v in props do
		(frame :: any)[k] = v
	end
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
	Theme.padding(4).Parent = frame
	return frame
end

---------------------------------------------------------------------
-- Ventana del intercambio
---------------------------------------------------------------------
local tradeWindow: Frame? = nil
local parts: { [string]: any } = {}
local myOffer: { [string]: number } = {}
local myMoney = 0

local function sendOffer()
	Remote:FireServer("Offer", myOffer, myMoney)
end

local function offerRows(frame: ScrollingFrame, list: { any }, money_: number, editable: boolean)
	clear(frame)
	for i, it in list do
		local text = ("%s %s × %d"):format(it.Icon, it.Name, it.Count)
		if editable then
			local b = Theme.button({ Size = UDim2.new(1, 0, 0, 30), Text = text .. "  ➖", TextSize = 13, LayoutOrder = i, Parent = frame })
			b.Activated:Connect(function()
				local n = (myOffer[it.Id] or 0) - 1
				myOffer[it.Id] = if n > 0 then n else nil
				sendOffer()
			end)
		else
			Theme.label({ Size = UDim2.new(1, 0, 0, 26), Text = text, TextSize = 13, LayoutOrder = i, Parent = frame })
		end
	end
	if money_ > 0 then
		Theme.label({ Size = UDim2.new(1, 0, 0, 26), Text = "💵 " .. Format.money(money_), TextSize = 14, TextColor3 = C.Money, LayoutOrder = 100, Parent = frame })
	end
	if #list == 0 and money_ == 0 then
		Theme.label({ Size = UDim2.new(1, 0, 0, 26), Text = "(nada todavía)", TextSize = 12, TextColor3 = C.Muted, LayoutOrder = 1, Parent = frame })
	end
end

local function refreshBag()
	local bag = parts.Bag :: ScrollingFrame
	if not bag then
		return
	end
	clear(bag)
	local list = myItems()
	if #list == 0 then
		Theme.label({ Size = UDim2.new(1, 0, 0, 26), Text = "No tienes nada que se pueda intercambiar.", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = bag })
	end
	for i, it in list do
		local left = it.Count - (myOffer[it.Id] or 0)
		local b = Theme.button({
			Size = UDim2.new(1, 0, 0, 28),
			Text = ("%s %s (%d)  ➕"):format(it.Icon, it.Name, left),
			TextSize = 12,
			LayoutOrder = i,
			BackgroundColor3 = if left > 0 then GREY else rgb(30, 30, 34),
			Parent = bag,
		})
		b.Activated:Connect(function()
			if left > 0 then
				myOffer[it.Id] = (myOffer[it.Id] or 0) + 1
				sendOffer()
			end
		end)
	end
end

local function closeTrade()
	if tradeWindow then
		local w = tradeWindow
		tradeWindow = nil
		w:Destroy()
	end
	parts = {}
end

local function openTrade(themName: string)
	closeTrade()
	myOffer, myMoney = {}, 0
	local window, content, close = Dialog.window("Trade", "🤝 Intercambio con " .. themName, Vector2.new(620, 430))
	tradeWindow = window
	local _ = close -- la ✖ cierra la ventana y eso cancela (Destroying)
	window.Destroying:Connect(function()
		if tradeWindow == window then
			tradeWindow = nil
			Remote:FireServer("Cancel")
		end
	end)
	local colW = UDim2.new(0.5, -6, 0, 0)
	-- Izquierda: lo tuyo
	local left = create("Frame", { Size = UDim2.new(0.5, -6, 1, -52), BackgroundTransparency = 1, Parent = content })
	Theme.label({ Size = UDim2.new(1, 0, 0, 20), Text = "Tú das", Font = Theme.FontBold, TextSize = 15, Parent = left })
	parts.Mine = scroller(left, { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 110) })
	local moneyRow = create("Frame", { Position = UDim2.fromOffset(0, 138), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = left })
	Theme.label({ Size = UDim2.new(0, 70, 1, 0), Text = "💵 Dinero:", TextSize = 13, Parent = moneyRow })
	local box = create("TextBox", {
		Position = UDim2.fromOffset(74, 0),
		Size = UDim2.new(1, -74, 1, 0),
		BackgroundColor3 = rgb(8, 14, 28),
		TextColor3 = C.Text,
		PlaceholderText = "0",
		Text = "",
		Font = Theme.Font,
		TextSize = 14,
		ClearTextOnFocus = false,
		Parent = moneyRow,
	}, { Theme.corner(8) })
	box.FocusLost:Connect(function()
		local n = math.floor(tonumber((box.Text:gsub("[^%d]", ""))) or 0)
		myMoney = math.clamp(n, 0, math.min(money(), Trade.MaxMoney))
		box.Text = if myMoney > 0 then tostring(myMoney) else ""
		sendOffer()
	end)
	parts.MoneyBox = box
	Theme.label({ Position = UDim2.fromOffset(0, 172), Size = UDim2.new(1, 0, 0, 18), Text = "Tu mochila (toca para añadir):", TextSize = 12, TextColor3 = C.Muted, Parent = left })
	parts.Bag = scroller(left, { Position = UDim2.fromOffset(0, 192), Size = UDim2.new(1, 0, 1, -192) })
	-- Derecha: lo suyo
	local right = create("Frame", { Position = UDim2.new(0.5, 6, 0, 0), Size = UDim2.new(0.5, -6, 1, -52), BackgroundTransparency = 1, Parent = content })
	parts.ThemTitle = Theme.label({ Size = UDim2.new(1, 0, 0, 20), Text = themName .. " da", Font = Theme.FontBold, TextSize = 15, Parent = right })
	parts.Theirs = scroller(right, { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 1, -22) })
	local _ = colW
	-- Abajo: estado y botones
	parts.Status = Theme.label({ Position = UDim2.new(0, 0, 1, -46), Size = UDim2.new(0.5, 0, 0, 40), Text = "", TextSize = 13, TextWrapped = true, Parent = content })
	local accept = Theme.button({ Position = UDim2.new(0.5, 6, 1, -44), Size = UDim2.new(0.5, -6, 0, 40), Text = "✅ Aceptar", TextSize = 16, BackgroundColor3 = C.Accent, Parent = content })
	parts.Accept = accept
	parts.Accepted = false
	accept.Activated:Connect(function()
		Remote:FireServer("Accept", not parts.Accepted)
	end)
	refreshBag()
end

local function showSession(s: { [string]: any })
	if not tradeWindow then
		openTrade(s.Them.Name)
	end
	-- El servidor manda: lo que de verdad hay en tu oferta
	myOffer = {}
	for _, it in s.Me.Items do
		myOffer[it.Id] = it.Count
	end
	myMoney = s.Me.Money
	if parts.MoneyBox and not parts.MoneyBox:IsFocused() then
		parts.MoneyBox.Text = if myMoney > 0 then tostring(myMoney) else ""
	end
	offerRows(parts.Mine, s.Me.Items, s.Me.Money, true)
	offerRows(parts.Theirs, s.Them.Items, s.Them.Money, false)
	parts.ThemTitle.Text = s.Them.Name .. " da" .. (if s.Them.Accepted then "  ✅" else "")
	parts.Accepted = s.Me.Accepted
	parts.Accept.Text = if s.Me.Accepted then "↩️ Ya no acepto" else "✅ Aceptar"
	parts.Accept.BackgroundColor3 = if s.Me.Accepted then GREY else C.Accent
	refreshBag()
	if s.Counting then
		parts.Status.Text = ("⏳ Los dos habéis aceptado. Se hace en %d s… (revisa bien lo que te dan)"):format(s.Seconds)
		parts.Status.TextColor3 = C.Gold
	elseif s.Me.Accepted then
		parts.Status.Text = "Esperando a que " .. s.Them.Name .. " acepte…"
		parts.Status.TextColor3 = C.Muted
	elseif s.Them.Accepted then
		parts.Status.Text = s.Them.Name .. " ya ha aceptado. ¿Aceptas tú?"
		parts.Status.TextColor3 = C.Money
	else
		parts.Status.Text = "Pon lo que das y pulsa Aceptar."
		parts.Status.TextColor3 = C.Muted
	end
end

---------------------------------------------------------------------
-- Mercadillo
---------------------------------------------------------------------
local market: { any } = {}
local marketWindow: Frame? = nil
local marketTab = "Comprar"
local renderMarket: () -> ()

local function sellPanel(list: ScrollingFrame)
	local items = myItems()
	if #items == 0 then
		Theme.label({ Size = UDim2.new(1, 0, 0, 40), Text = "No tienes nada que se pueda vender (comida y objetos de la mochila).", TextSize = 13, TextColor3 = C.Muted, TextWrapped = true, Parent = list })
	end
	for i, it in items do
		local row = create("Frame", { Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, LayoutOrder = i, Parent = list })
		Theme.label({ Size = UDim2.new(0.42, 0, 1, 0), Text = ("%s %s (%d)"):format(it.Icon, it.Name, it.Count), TextSize = 13, TextWrapped = true, Parent = row })
		local count = 1
		local countLabel = Theme.label({ Position = UDim2.new(0.42, 30, 0, 0), Size = UDim2.fromOffset(28, 36), Text = "1", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Parent = row })
		local minus = Theme.button({ Position = UDim2.new(0.42, 0, 0, 4), Size = UDim2.fromOffset(28, 28), Text = "-", TextSize = 16, Parent = row })
		local plus = Theme.button({ Position = UDim2.new(0.42, 60, 0, 4), Size = UDim2.fromOffset(28, 28), Text = "+", TextSize = 16, Parent = row })
		minus.Activated:Connect(function()
			count = math.max(1, count - 1)
			countLabel.Text = tostring(count)
		end)
		plus.Activated:Connect(function()
			count = math.min(it.Count, count + 1)
			countLabel.Text = tostring(count)
		end)
		local price = create("TextBox", {
			Position = UDim2.new(0.42, 94, 0, 4),
			Size = UDim2.fromOffset(70, 28),
			BackgroundColor3 = rgb(8, 14, 28),
			TextColor3 = C.Text,
			PlaceholderText = "precio",
			Text = "",
			Font = Theme.Font,
			TextSize = 13,
			ClearTextOnFocus = false,
			Parent = row,
		}, { Theme.corner(6) })
		local sell = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(78, 32), Text = "Vender", TextSize = 13, BackgroundColor3 = C.Accent, Parent = row })
		sell.Activated:Connect(function()
			local p = math.floor(tonumber((price.Text:gsub("[^%d]", ""))) or 0)
			if p < Trade.Market.MinPrice then
				price.PlaceholderText = "¡pon precio!"
				return
			end
			Remote:FireServer("List", it.Id, count, p)
		end)
	end
	local mine = 0
	for _, l in market do
		if l.SellerId == player.UserId then
			mine += 1
			local row = create("Frame", { Size = UDim2.new(1, -8, 0, 32), BackgroundTransparency = 1, LayoutOrder = 1000 + mine, Parent = list })
			Theme.label({ Size = UDim2.new(1, -90, 1, 0), Text = ("🏷️ A la venta: %s %s × %d por %s"):format(l.Icon, l.Name, l.Count, Format.money(l.Price)), TextSize = 12, TextColor3 = C.Gold, TextWrapped = true, Parent = row })
			local remove = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(80, 28), Text = "Quitar", TextSize = 12, Parent = row })
			remove.Activated:Connect(function()
				Remote:FireServer("Unlist", l.Id)
			end)
		end
	end
	Theme.label({ Size = UDim2.new(1, 0, 0, 34), Text = ("El mercadillo se queda un %d %%. Tus cosas no salen de la mochila hasta que alguien las compra."):format(Trade.Market.Fee * 100), TextSize = 11, TextColor3 = C.Muted, TextWrapped = true, LayoutOrder = 2000, Parent = list })
end

local function buyPanel(list: ScrollingFrame)
	local any = false
	for i, l in market do
		if l.SellerId ~= player.UserId then
			any = true
			local row = create("Frame", { Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, LayoutOrder = i, Parent = list })
			Theme.label({ Size = UDim2.new(1, -96, 1, 0), Text = ("%s <b>%s × %d</b> · %s\n<font color=\"#a5b2c8\">vende %s</font>"):format(l.Icon, l.Name, l.Count, Format.money(l.Price), l.Seller), RichText = true, TextSize = 13, TextWrapped = true, Parent = row })
			local buy = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 3), Size = UDim2.fromOffset(88, 30), Text = "Comprar", TextSize = 13, BackgroundColor3 = if money() >= l.Price then C.Accent else GREY, Parent = row })
			buy.Activated:Connect(function()
				Remote:FireServer("Buy", l.Id)
			end)
		end
	end
	if not any then
		Theme.label({ Size = UDim2.new(1, 0, 0, 40), Text = "Ahora mismo nadie de este servidor vende nada. ¡Pon tú algo a la venta!", TextSize = 13, TextColor3 = C.Muted, TextWrapped = true, Parent = list })
	end
end

function renderMarket()
	local window = marketWindow
	if not window then
		return
	end
	local list = window:FindFirstChild("List", true) :: ScrollingFrame
	for _, b in window:FindFirstChild("Tabs", true):GetChildren() do
		if b:IsA("TextButton") then
			b.BackgroundColor3 = if b.Name == marketTab then C.Accent else GREY
		end
	end
	clear(list)
	if marketTab == "Comprar" then
		buyPanel(list)
	else
		sellPanel(list)
	end
end

local function openMarket()
	local window, content = Dialog.window("Market", "🛍️ Mercadillo", Vector2.new(520, 430))
	marketWindow = window
	window.Destroying:Connect(function()
		if marketWindow == window then
			marketWindow = nil
		end
	end)
	local tabs = create("Frame", { Name = "Tabs", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = tabs })
	for _, name in { "Comprar", "Vender" } do
		local b = Theme.button({ Name = name, Size = UDim2.fromOffset(120, 34), Text = if name == "Comprar" then "🛒 Comprar" else "🏷️ Vender", TextSize = 14, Parent = tabs })
		b.Activated:Connect(function()
			marketTab = name
			renderMarket()
		end)
	end
	local list = scroller(content, { Name = "List", Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -42) })
	local _ = list
	renderMarket()
	Remote:FireServer("Market")
end

---------------------------------------------------------------------

-- Pregunta de Dialog.choose que se cierra sola a los `seconds` (cuando la invitación caduca en el
-- servidor). onAnswer recibe la elección (o nil si la cierra); si caduca, no se llama.
local function chooseFor(seconds: number?, title: string, body: string?, options: { string }, onAnswer: (number?) -> ())
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local before: { [Instance]: boolean } = {}
	local dialogs = playerGui and playerGui:FindFirstChild("Dialogs")
	for _, child in (if dialogs then dialogs:GetChildren() else {}) do
		before[child] = true
	end
	local expired = false
	task.spawn(function()
		local choice = Dialog.choose(title, body, options)
		if not expired then
			onAnswer(choice)
		end
	end)
	-- (Dialog.choose crea su ventana antes de esperar: la ventana nueva es la de esta pregunta)
	dialogs = playerGui and playerGui:FindFirstChild("Dialogs")
	local window: Instance? = nil
	for _, child in (if dialogs then dialogs:GetChildren() else {}) do
		if not before[child] and string.sub(child.Name, 1, 6) == "Choose" then
			window = child
		end
	end
	if window and type(seconds) == "number" and seconds > 0 then
		task.delay(seconds, function()
			if window.Parent then
				expired = true
				window:Destroy()
			end
		end)
	end
end

function TradeUI.init()
	Hud.addButton("🛍️ Mercadillo", rgb(190, 90, 150), 6, openMarket)

	Remote.OnClientEvent:Connect(function(action, a)
		if action == "Invite" then
			-- (se cierra sola cuando caduca la invitación)
			chooseFor(a.Seconds, "🤝 " .. a.Name .. " quiere intercambiar", "¿Abrir la ventana de intercambio? Nada cambia de manos hasta que los dos aceptéis.", { "Sí, vamos", "Ahora no" }, function(choice)
				Remote:FireServer("Answer", a.UserId, choice == 1)
			end)
		elseif action == "Session" then
			showSession(a)
		elseif action == "Closed" then
			local w = tradeWindow
			tradeWindow = nil
			if w then
				w:Destroy()
			end
			parts = {}
			if a then
				Hud.toast("Info", a)
			end
		elseif action == "Market" then
			market = a
			renderMarket()
		end
	end)
	player:GetAttributeChangedSignal("Inventory"):Connect(function()
		if tradeWindow then
			refreshBag()
		end
		if marketWindow and marketTab == "Vender" then
			renderMarket()
		end
	end)
end

return TradeUI
