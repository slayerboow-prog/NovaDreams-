-- Store: ventana de la tienda (Game Passes y paquetes de dinero con Robux).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Theme)

local create = Theme.create
local C = Theme.Colors

local Store = {}

local player = Players.LocalPlayer
local window: Frame

local function card(parent: Instance, order: number, title: string, description: string, robux: number, id: number, owned: () -> boolean, buy: () -> ())
	local frame = Theme.panel({
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = C.PanelLight,
		BackgroundTransparency = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.padding(10).Parent = frame
	Theme.label({ Size = UDim2.new(1, -120, 0, 22), Text = title, Font = Theme.FontBold, TextSize = 18, Parent = frame })
	Theme.label({
		Size = UDim2.new(1, -120, 0, 32),
		Position = UDim2.fromOffset(0, 22),
		Text = description,
		TextSize = 13,
		TextColor3 = C.Muted,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = frame,
	})
	local button = Theme.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(110, 38),
		Position = UDim2.fromScale(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 170, 90),
		Parent = frame,
	})

	local function refresh()
		if id == 0 then
			button.Text = "Próximamente"
			button.BackgroundColor3 = C.PanelLight
			button.AutoButtonColor = false
		elseif owned() then
			button.Text = "✓ Tuyo"
			button.BackgroundColor3 = C.PanelLight
			button.AutoButtonColor = false
		else
			button.Text = "R$ " .. robux
		end
	end
	refresh()
	button.Activated:Connect(function()
		if id ~= 0 and not owned() then
			buy()
		end
	end)
	return refresh
end

function Store.open()
	window.Visible = true
end

function Store.close()
	window.Visible = false
end

function Store.init(parent: ScreenGui)
	window = Theme.panel({
		Name = "Store",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(460, 440),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 10,
		Parent = parent,
	})
	Theme.padding(16).Parent = window

	Theme.label({ Size = UDim2.new(1, -40, 0, 30), Text = "🛒 Tienda", Font = Theme.FontBold, TextSize = 24, Parent = window })
	local close = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromScale(1, 0),
		Text = "✕",
		Parent = window,
	})
	close.Activated:Connect(Store.close)

	local list = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -44),
		Position = UDim2.fromOffset(0, 44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = window,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	create("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = list })

	local order = 0
	local function section(text: string)
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = text, Font = Theme.FontBold, TextColor3 = C.Gold, LayoutOrder = order, Parent = list })
	end

	section("PASES (para siempre)")
	local passKeys = {}
	for key in Config.GamePasses do
		table.insert(passKeys, key)
	end
	table.sort(passKeys)
	for _, key in passKeys do
		local pass = Config.GamePasses[key]
		order += 1
		local refresh = card(list, order, pass.Name, pass.Description, pass.Robux, pass.Id, function()
			return player:GetAttribute("Pass_" .. key) == true
		end, function()
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
		end)
		player:GetAttributeChangedSignal("Pass_" .. key):Connect(refresh)
	end

	section("DINERO")
	for _, product in Config.DevProducts do
		order += 1
		card(list, order, product.Name, "+" .. Format.money(product.Cash) .. " para gastar en la ciudad.", product.Robux, product.Id, function()
			return false
		end, function()
			MarketplaceService:PromptProductPurchase(player, product.Id)
		end)
	end
end

return Store
