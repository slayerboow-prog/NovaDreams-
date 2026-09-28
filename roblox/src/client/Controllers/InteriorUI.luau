-- InteriorUI (cliente): el panel del ascensor de los edificios (InteriorService).
-- Botones con cada planta (Planta baja, 1ª, 2ª… y la Azotea en la Torre de Valmar); la planta en la
-- que estás sale marcada, y en los pisos, quién vive en cada una (🙂 vecino, 👤 jugador, 🏷 en venta). Se cierra al elegir, con ✖ o al alejarse.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)

local InteriorUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local gui: ScreenGui
local panel: Frame?
local remote: RemoteEvent

local function close()
	if panel then
		panel:Destroy()
		panel = nil
	end
end

local function floorName(n: number): string
	if n == -1 then
		return "🌇 Azotea"
	elseif n == 0 then
		return "Planta baja"
	end
	return ("Planta %d"):format(n)
end

local function open(data: { [string]: any })
	close()
	SoundFx.play("MenuAbrir")
	local floors: { number } = {}
	if data.Roof then
		table.insert(floors, -1)
	end
	for n = data.Floors - 1, 0, -1 do
		table.insert(floors, n)
	end
	local columns = if #floors > 12 then 3 elseif #floors > 6 then 2 else 1
	local cell = if data.Labels and next(data.Labels) then 230 else 160
	local rows = math.ceil(#floors / columns)
	local frame = Theme.panel({
		Name = "Elevator",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(40 + columns * (cell + 10), 110 + math.min(rows, 10) * 46),
		Parent = gui,
	})
	panel = frame
	Theme.padding(14).Parent = frame
	local scale = create("UIScale", { Scale = 0.85, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	Theme.title({ Size = UDim2.new(1, -40, 0, 26), Text = "🏢 " .. (data.Title or "Ascensor"), TextSize = 20, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(34, 30), Text = "✖", TextSize = 18, Parent = frame }).Activated:Connect(close)
	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -40),
		CanvasSize = UDim2.fromOffset(0, rows * 46),
		ScrollBarThickness = 6,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = frame,
	})
	create("UIGridLayout", { CellSize = UDim2.fromOffset(cell, 40), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	for i, n in floors do
		local here = n == data.Current
		local label = data.Labels and data.Labels[tostring(n)]
		local button = Theme.button({
			Text = floorName(n) .. (if label then "  " .. label else "") .. (if here then "  ◀" else ""),
			TextSize = if label then 13 else 16,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = i,
			BackgroundColor3 = if here then rgb(40, 110, 200) else C.Panel,
			Parent = list,
		})
		button.Activated:Connect(function()
			SoundFx.play("MenuOk")
			remote:FireServer("Floor", n)
			close()
		end)
	end
	-- Se cierra solo si te alejas
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local origin = root and root.Position
	task.spawn(function()
		while panel == frame do
			task.wait(0.5)
			local now = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not now or not origin or (now.Position - origin).Magnitude > 14 then
				close()
			end
		end
	end)
end

function InteriorUI.init()
	gui = create("ScreenGui", { Name = "InteriorGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 7, Parent = player:WaitForChild("PlayerGui") })
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.6, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Interior", 30) :: RemoteEvent
	if remote then
		remote.OnClientEvent:Connect(function(kind: string, data: any)
			if kind == "Elevator" then
				open(data)
			end
		end)
	end
end

return InteriorUI
