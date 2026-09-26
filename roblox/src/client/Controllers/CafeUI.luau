-- CafeUI (cliente): la parte que ves en las cafeterías.
--   * La carta (al pulsar "Pedir" en la caja): eliges hasta 3 cosas, ves el total y pagas.
--   * De barista: panel con los pedidos y sus pasos (✅ hecho, ➡️ el siguiente) y el tiempo que
--     lleva esperando cada cliente. Los carteles de los puestos solo los ve quien trabaja de barista.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Format = require(ReplicatedStorage.Shared.Format)

local CafeUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Cafe") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local MAX_ITEMS = 3

local gui: ScreenGui
local panel: Frame
local list: ScrollingFrame
local hint: TextLabel

---------------------------------------------------------------------
-- Carteles de los puestos: solo para el barista
---------------------------------------------------------------------
local staffPrompts: { ProximityPrompt } = {}

local function isBarista(): boolean
	return player:GetAttribute("Job") == "Barista"
end

local function trackPrompt(d: Instance)
	if d:IsA("ProximityPrompt") and d:GetAttribute("CafeStaff") then
		table.insert(staffPrompts, d)
		d.Enabled = isBarista()
	end
end

local function refreshPrompts()
	local on = isBarista()
	for i = #staffPrompts, 1, -1 do
		local p = staffPrompts[i]
		if p.Parent then
			p.Enabled = on
		else
			table.remove(staffPrompts, i)
		end
	end
end

---------------------------------------------------------------------
-- La carta
---------------------------------------------------------------------
local function openMenu(menu: { any }, baristaName: string?)
	local chosen: { string } = {}
	local byId = {}
	for _, item in menu do
		byId[item.Id] = item
	end
	local rows = math.ceil(#menu / 2)
	local window, content, close = Dialog.window("CafeMenu", "☕ La carta", Vector2.new(460, 190 + rows * 46))
	Theme.label({
		Size = UDim2.new(1, 0, 0, 20),
		Text = if baristaName then ("Hoy te atiende %s. Elige hasta %d cosas."):format(baristaName, MAX_ITEMS) else ("Elige hasta %d cosas: te lo preparan al momento."):format(MAX_ITEMS),
		TextSize = 14,
		TextColor3 = C.Muted,
		Parent = content,
	})
	local grid = create("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, rows * 46), BackgroundTransparency = 1, Parent = content })
	create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 40), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	local summary = Theme.label({ Position = UDim2.new(0, 0, 1, -76), Size = UDim2.new(1, 0, 0, 22), Text = "", TextSize = 14, TextWrapped = true, Parent = content })
	local pay = Theme.button({ Position = UDim2.new(0, 0, 1, -44), Size = UDim2.new(1, 0, 0, 40), Text = "Pedir y pagar", TextSize = 16, BackgroundColor3 = C.Accent, Parent = content })

	local function refresh()
		local names, total = {}, 0
		for _, id in chosen do
			table.insert(names, byId[id].Icon .. " " .. byId[id].Name)
			total += byId[id].Price
		end
		summary.Text = if #chosen == 0 then "Toca lo que quieras (otra vez para quitarlo)." else table.concat(names, " · ") .. "   ·   Total " .. Format.money(total)
		pay.AutoButtonColor = #chosen > 0
		pay.BackgroundTransparency = if #chosen > 0 then 0 else 0.5
	end
	for i, item in menu do
		local button = Theme.button({ LayoutOrder = i, Text = ("%s %s · %s"):format(item.Icon, item.Name, Format.money(item.Price)), TextSize = 14, Parent = grid })
		button.Activated:Connect(function()
			local at = table.find(chosen, item.Id)
			if at then
				table.remove(chosen, at)
			elseif #chosen < MAX_ITEMS then
				table.insert(chosen, item.Id)
			end
			refresh()
		end)
	end
	pay.Activated:Connect(function()
		if #chosen > 0 then
			Remote:FireServer("Order", chosen)
			window:Destroy()
		end
	end)
	close.Activated:Connect(function()
		window:Destroy()
	end)
	refresh()
end

---------------------------------------------------------------------
-- Panel del barista
---------------------------------------------------------------------
local function showWork(orders: { any })
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	panel.Visible = true
	hint.Text = if #orders == 0 then "Sin pedidos. Los clientes piden en la caja." else "Sigue los pasos en orden. La línea azul te lleva."
	local height = 0
	for i, order in orders do
		local names = {}
		for _, item in order.Items do
			table.insert(names, item.Icon .. " " .. item.Name)
		end
		local steps = {}
		local nextShown = false
		for _, t in order.Tasks do
			if t.Done then
				table.insert(steps, "✅ " .. t.Label)
			elseif not nextShown and i == 1 and not order.Ready then
				nextShown = true
				table.insert(steps, "➡️ <b>" .. t.Label .. "</b> (" .. t.Item .. ")")
			else
				table.insert(steps, "⬜ " .. t.Label)
			end
		end
		if order.Ready then
			table.insert(steps, "🛎️ <b>Entrégalo en la RECOGIDA</b>")
		end
		local lines = if i == 1 then #steps else 0
		local h = 46 + lines * 18
		local card = create("Frame", {
			Size = UDim2.new(1, -6, 0, h),
			BackgroundColor3 = if i == 1 then rgb(60, 44, 32) else rgb(40, 40, 46),
			BackgroundTransparency = 0.15,
			LayoutOrder = i,
			Parent = list,
		})
		Theme.corner(8).Parent = card
		Theme.padding(6).Parent = card
		local wait = order.Wait
		Theme.label({
			Size = UDim2.new(1, 0, 0, 18),
			Text = ("%s · %s"):format(order.Name, if wait >= 60 then ("%d min %02d s"):format(wait // 60, wait % 60) else ("%d s"):format(wait)),
			Font = Theme.FontBold,
			TextSize = 14,
			TextColor3 = if wait > 90 then rgb(255, 140, 120) else C.Text,
			Parent = card,
		})
		Theme.label({ Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 18), Text = table.concat(names, "  "), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
		if lines > 0 then
			Theme.label({
				Position = UDim2.fromOffset(0, 38),
				Size = UDim2.new(1, 0, 0, lines * 18),
				Text = table.concat(steps, "\n"),
				RichText = true,
				TextSize = 13,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextColor3 = C.Muted,
				Parent = card,
			})
		end
		height += h + 6
	end
	list.CanvasSize = UDim2.fromOffset(0, height)
end

---------------------------------------------------------------------

function CafeUI.init()
	gui = create("ScreenGui", { Name = "CafeGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	panel = Theme.panel({
		Name = "Barista",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(270, 330),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "☕ Barista · pedidos", Font = Theme.FontBold, TextSize = 16, Parent = panel })
	hint = Theme.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 30), Text = "", TextSize = 12, TextWrapped = true, TextColor3 = C.Muted, Parent = panel })
	list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 1, -56),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	for _, d in workspace:GetDescendants() do
		trackPrompt(d)
	end
	workspace.DescendantAdded:Connect(trackPrompt)
	player:GetAttributeChangedSignal("Job"):Connect(function()
		refreshPrompts()
		if not isBarista() then
			panel.Visible = false
		end
	end)

	Remote.OnClientEvent:Connect(function(action, a, b)
		if action == "Menu" then
			openMenu(a, b)
		elseif action == "Work" then
			showWork(a)
		elseif action == "Start" then
			panel.Visible = true
		elseif action == "Stop" then
			panel.Visible = false
		end
	end)
end

return CafeUI
