-- Restaurant: ventanas del trabajo en el restaurante.
--   Camarero: tras escuchar al cliente, elige qué ha pedido.
--   Barman: lista de comandas; para cada plato elige sus ingredientes y pulsa "Preparar".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)

local create = Theme.create
local C = Theme.Colors

local Restaurant = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Restaurant") :: RemoteEvent

local bar: { Token: string, Window: Frame, Rebuild: ({ any }) -> () }? = nil

local function takeOrder(token: string, options: { string }, tableId: number)
	local choice = Dialog.choose(("🧾 Mesa %d: ¿qué ha pedido el cliente?"):format(tableId), "Elige exactamente lo que te ha dicho.", options)
	Remote:FireServer("OrderChoice", token, choice)
end

local function openBar(token: string, dishes: { any }, recipes: { string })
	local window, content = Dialog.window("Bar", "🍳 Barra · comandas", Vector2.new(600, 460))
	local left = create("ScrollingFrame", {
		Size = UDim2.new(0, 210, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
	local right = create("Frame", { Size = UDim2.new(1, -226, 1, 0), Position = UDim2.fromOffset(226, 0), BackgroundTransparency = 1, Parent = content })
	local title = Theme.label({ Size = UDim2.new(1, 0, 0, 30), Font = Theme.FontBold, TextSize = 18, TextWrapped = true, Parent = right })
	Theme.label({ Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 30), TextSize = 13, TextColor3 = C.Muted, Text = "Elige los ingredientes del plato.", Parent = right })
	local grid = create("Frame", { Size = UDim2.new(1, 0, 0, 200), Position = UDim2.fromOffset(0, 56), BackgroundTransparency = 1, Parent = right })
	create("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 42), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	local prepare = Theme.button({ Size = UDim2.new(0.6, -4, 0, 48), Position = UDim2.new(0, 0, 1, -52), Text = "Preparar ✅", BackgroundColor3 = Color3.fromRGB(0, 150, 80), Parent = right })
	local book = Theme.button({ Size = UDim2.new(0.4, -4, 0, 48), Position = UDim2.new(0.6, 4, 1, -52), Text = "📖 Recetas", Parent = right })
	local recipeText = Theme.label({
		Size = UDim2.new(1, 0, 1, -60),
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Panel,
		Text = table.concat(recipes, "\n"),
		TextSize = 14,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Visible = false,
		ZIndex = 5,
		Parent = right,
	})
	book.Activated:Connect(function()
		recipeText.Visible = not recipeText.Visible
	end)

	local selected: { OrderId: number, Index: number }? = nil
	local chosen: { [string]: boolean } = {}
	local current: { any } = dishes

	local function showDish(entry: any?)
		for _, child in grid:GetChildren() do
			if child:IsA("GuiButton") then
				child:Destroy()
			end
		end
		chosen = {}
		if not entry then
			selected = nil
			title.Text = if #current > 0 then "← Elige una comanda" else "No hay comandas pendientes"
			prepare.Visible = false
			return
		end
		selected = { OrderId = entry.OrderId, Index = entry.Index }
		title.Text = ("Mesa %d · %s"):format(entry.TableId, entry.Dish)
		prepare.Visible = true
		for i, ingredient in entry.Options do
			local button = Theme.button({ Text = ingredient, TextSize = 15, LayoutOrder = i, Parent = grid })
			button.Activated:Connect(function()
				chosen[ingredient] = not chosen[ingredient] or nil
				button.BackgroundColor3 = if chosen[ingredient] then Color3.fromRGB(0, 120, 170) else C.PanelLight
			end)
		end
	end

	local function rebuild(list: { any })
		current = list
		for _, child in left:GetChildren() do
			if child:IsA("GuiButton") then
				child:Destroy()
			end
		end
		local keep = nil
		for i, entry in list do
			local button = Theme.button({ Size = UDim2.new(1, -8, 0, 52), Text = ("Mesa %d\n%s"):format(entry.TableId, entry.Dish), TextSize = 14, TextWrapped = true, LayoutOrder = i, Parent = left })
			button.Activated:Connect(function()
				showDish(entry)
			end)
			if selected and entry.OrderId == selected.OrderId and entry.Index == selected.Index then
				keep = entry
			end
		end
		if not keep then
			showDish(if #list > 0 then list[1] else nil)
		end
	end

	prepare.Activated:Connect(function()
		if not selected then
			return
		end
		local list = {}
		for ingredient in chosen do
			table.insert(list, ingredient)
		end
		Remote:FireServer("Prepare", token, selected.OrderId, selected.Index, list)
	end)

	rebuild(dishes)
	bar = { Token = token, Window = window, Rebuild = rebuild }

	-- Si te alejas de la barra, se cierra
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local origin = root and root.Position
	local watch = RunService.Heartbeat:Connect(function()
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if origin and r and (r.Position - origin).Magnitude > 16 and window.Parent then
			window:Destroy()
		end
	end)
	window.Destroying:Connect(function()
		watch:Disconnect()
		if bar and bar.Window == window then
			bar = nil
		end
		Remote:FireServer("CloseBar", token)
	end)
end

function Restaurant.init()
	Remote.OnClientEvent:Connect(function(action, token, a, b)
		if action == "TakeOrder" then
			takeOrder(token, a, b)
		elseif action == "Bar" then
			openBar(token, a, b)
		elseif action == "BarUpdate" then
			if bar and bar.Token == token and bar.Window.Parent then
				bar.Rebuild(a)
			end
		end
	end)
end

return Restaurant
