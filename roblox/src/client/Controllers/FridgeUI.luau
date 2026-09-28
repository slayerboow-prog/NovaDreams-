-- FridgeUI (cliente): el panel de la nevera de casa (FridgeService).
--   * Arriba, lo que hay dentro: "Comer" (se gasta uno) o "Coger" (a la mochila).
--   * Abajo, la comida que llevas en la mochila: "Guardar" (o "Guardar todo").
--   * Vacía y sin nada en la mochila: el aviso de ir al supermercado y un botón que pone el GPS
--     hacia el supermercado más cercano.
-- Se cierra con ✕ o al alejarse.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)

local FridgeUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors

local gui: ScreenGui
local panel: Frame?
local remote: RemoteEvent

local function close(tell: boolean?)
	if panel then
		panel:Destroy()
		panel = nil
		if tell then
			remote:FireServer("Fridge", "Close")
		end
	end
end

-- El supermercado más cercano (de los lugares del mapa)
local function nearestSupermarket(): Vector3?
	local landmarks = ReplicatedStorage:FindFirstChild("MapLandmarks")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local door = player:GetAttribute("InteriorDoor")
	local from = if typeof(door) == "Vector3" then door elseif root then root.Position else Vector3.zero
	local best, bestDistance = nil, math.huge
	for _, mark in (landmarks and landmarks:GetChildren()) or {} do
		local kind = mark:GetAttribute("Kind")
		local at = mark:GetAttribute("Position")
		if type(kind) == "string" and string.find(kind, "Supermercado", 1, true) and typeof(at) == "Vector3" then
			local d = (at - from).Magnitude
			if d < bestDistance then
				best, bestDistance = at, d
			end
		end
	end
	return best
end

local function row(parent: Instance, order: number, text: string, buttons: { { any } })
	local line = create("Frame", { Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	Theme.label({ Size = UDim2.new(1, -#buttons * 92, 1, 0), Text = text, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = line })
	for i, b in buttons do
		local button = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(i - 1) * 92, 0.5, 0), Size = UDim2.fromOffset(86, 30), Text = b[1], TextSize = 14, Parent = line })
		button.Activated:Connect(function()
			SoundFx.play("MenuOk")
			b[2]()
		end)
	end
end

local function open(data: { [string]: any })
	local keep = panel ~= nil
	close(false)
	if not keep then
		SoundFx.play("MenuAbrir")
	end
	local frame = Theme.panel({ Name = "Fridge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(420, 460), Parent = gui })
	panel = frame
	Theme.padding(14).Parent = frame
	if not keep then
		local scale = create("UIScale", { Scale = 0.85, Parent = frame })
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	Theme.title({ Size = UDim2.new(1, -40, 0, 26), Text = "🧊 Nevera · " .. tostring(data.Title or ""), TextSize = 19, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(34, 30), Text = "✖", TextSize = 18, Parent = frame }).Activated:Connect(function()
		close(true)
	end)
	local list = create("ScrollingFrame", { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -36), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = frame })
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local order = 0
	local function header(text: string)
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 24), Text = text, TextSize = 14, TextColor3 = C.Muted, LayoutOrder = order, Parent = list })
	end
	header(("DENTRO · caben %d más"):format(data.Space or 0))
	if #(data.Inside or {}) == 0 then
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 44), Text = "Está vacía: compra comida en el supermercado y guárdala aquí.", TextWrapped = true, TextSize = 14, LayoutOrder = order, Parent = list })
		local market = nearestSupermarket()
		if market then
			order += 1
			row(list, order, "🛒 Supermercado más cercano", {
				{ "Ir (GPS)", function()
					local ok, Gps = pcall(function()
						return require(script.Parent.Gps) :: any
					end)
					if ok and Gps.setManual then
						Gps.setManual(market, "Supermercado")
					end
					close(true)
				end },
			})
		end
	end
	for _, item in data.Inside or {} do
		order += 1
		row(list, order, ("%s %s ×%d"):format(item.Icon or "🍽", item.Name or item.Id, item.Count or 1), {
			{ "Comer", function()
				remote:FireServer("Fridge", "Eat", item.Id)
			end },
			{ "Coger", function()
				remote:FireServer("Fridge", "Take", item.Id)
			end },
		})
	end
	header("EN TU MOCHILA")
	if #(data.Bag or {}) == 0 then
		order += 1
		Theme.label({ Size = UDim2.new(1, 0, 0, 24), Text = "No llevas comida.", TextSize = 14, LayoutOrder = order, Parent = list })
	else
		order += 1
		row(list, order, "Toda la comida", { { "Guardar todo", function()
			remote:FireServer("Fridge", "StoreAll")
		end } })
	end
	for _, item in data.Bag or {} do
		order += 1
		row(list, order, ("%s %s ×%d"):format(item.Icon or "🍽", item.Name or item.Id, item.Count or 1), {
			{ "Guardar", function()
				remote:FireServer("Fridge", "Store", item.Id)
			end },
		})
	end
	-- Se cierra solo si te alejas
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local origin = root and root.Position
	task.spawn(function()
		while panel == frame do
			task.wait(0.5)
			local now = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not now or not origin or (now.Position - origin).Magnitude > 14 then
				close(true)
			end
		end
	end)
end

function FridgeUI.init()
	gui = create("ScreenGui", { Name = "FridgeGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 7, Parent = player:WaitForChild("PlayerGui") })
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.6, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Interact") :: RemoteEvent
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "Fridge" and type(data) == "table" then
			open(data)
		end
	end)
end

return FridgeUI
