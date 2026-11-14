-- CraftingUI (cliente): el libro de recetas del TALLER (Services/CraftingService; recetas en shared/Crafting).
--   * Pestañas por categoría (Armas, Armaduras, Pociones, Herramientas, Munición, Materiales).
--   * Cada receta: lo que sale, su nivel y su banco, y los materiales con lo que tienes / lo que hace falta
--     (en verde lo que te sobra, en rojo lo que falta). «Fabricar» y «×5».
--   * Con la mesa plegable solo se fabrican las recetas de Mesa; las demás salen apagadas («en un Taller»).
-- El servidor lo comprueba todo; aquí solo se enseña y se pide. Se cierra con ✖ o al alejarse del Taller.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local SoundFx = require(script.Parent.SoundFx)
local Crafting = require(ReplicatedStorage.Shared.Crafting)
local Items = require(ReplicatedStorage.Shared.Items)

local CraftingUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local gui: ScreenGui
local panel: Frame?
local remote: RemoteEvent
local state = { Bench = "Taller", Have = {} :: { [string]: number }, Tab = "Armas" }
local render: (() -> ())? = nil

local ORE_NAMES = { Hierro = "⛏ Hierro", Cobalto = "⛏ Cobalto", Cristal = "⛏ Cristal", Obsidiana = "⛏ Obsidiana" }
local function short(id: string): string
	local item = Items.get(id)
	if item then
		return item.Icon .. " " .. item.Name
	end
	return ORE_NAMES[id] or id
end

local function close(tell: boolean?)
	if panel then
		panel:Destroy()
		panel = nil
		render = nil
		if tell then
			remote:FireServer("Close")
		end
	end
end

function CraftingUI.isOpen(): boolean
	return panel ~= nil
end

local function open()
	local keep = panel ~= nil
	close(false)
	if not keep then
		SoundFx.play("MenuAbrir")
	end
	local frame = Theme.panel({ Name = "Crafting", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 540), Parent = gui })
	panel = frame
	Dialog.closeOthers("Crafting")
	Theme.padding(14).Parent = frame
	local closeButton = Theme.button({ Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(34, 30), Text = "✖", TextSize = 18, Parent = frame })
	closeButton.Activated:Connect(function()
		close(true)
	end)
	local side = Theme.touchWindow(frame, closeButton, not keep)
	local benchName = if state.Bench == "Mesa" then "🧰 Mesa plegable (solo recetas de Mesa)" else "🛠 Taller · Mesa, Forja y Alquimia"
	Theme.title({ Size = UDim2.new(1, -(side + 6), 0, 26), Text = benchName, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	local top = math.max(34, side + 2)
	-- pestañas
	local tabs = create("ScrollingFrame", { Name = "Tabs", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, 38), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = frame })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabs })
	local list = create("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(0, top + 46), Size = UDim2.new(1, 0, 1, -(top + 46)), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = frame })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local function draw()
		for _, ch in tabs:GetChildren() do
			if ch:IsA("GuiButton") then
				ch:Destroy()
			end
		end
		for i, cat in Crafting.Categories do
			local b = Theme.button({ Size = UDim2.fromOffset(if Theme.isTouch() then 118 else 104, 32), Text = cat, TextSize = 14, LayoutOrder = i, Parent = tabs })
			if cat == state.Tab then
				b.BackgroundColor3 = rgb(70, 130, 210)
			end
			b.Activated:Connect(function()
				SoundFx.play("MenuOk")
				state.Tab = cat
				draw()
			end)
		end
		for _, ch in list:GetChildren() do
			if ch:IsA("Frame") then
				ch:Destroy()
			end
		end
		local order = 0
		for _, r in Crafting.Recipes do
			if r.Category == state.Tab then
				order += 1
				local available = Crafting.benchHas(state.Bench, r)
				local times = Crafting.times(r, state.Have)
				local card = create("Frame", { Size = UDim2.new(1, -8, 0, if Theme.isTouch() then 86 else 78), BackgroundColor3 = rgb(24, 30, 46), BackgroundTransparency = 0.15, LayoutOrder = order, Parent = list })
				Theme.corner(8).Parent = card
				Theme.padding(8).Parent = card
				local level = Crafting.Levels[r.Level] or ""
				local bench = Crafting.Benches[r.Bench]
				local makes = if r.Makes > 1 then (" ×%d"):format(r.Makes) else ""
				Theme.label({ Size = UDim2.new(1, -190, 0, 22), Text = short(r.Id) .. makes, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
				Theme.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, -190, 0, 16), Text = ("%s · %s %s"):format(level, bench.Icon, bench.Name), TextSize = 12, TextColor3 = C.Muted, Parent = card })
				-- materiales: tienes/hacen falta
				local parts = {}
				local keys = {}
				for id in r.Needs do
					table.insert(keys, id)
				end
				table.sort(keys)
				for _, id in keys do
					local need = r.Needs[id]
					local have = state.Have[id] or 0
					local color = if have >= need then "#8CF09A" else "#FF7A6E"
					table.insert(parts, ('%s <font color="%s">%d/%d</font>'):format(short(id), color, have, need))
				end
				Theme.label({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, -190, 0, 30), Text = table.concat(parts, "   "), RichText = true, TextWrapped = true, TextSize = 12, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
				local function craftButton(text: string, n: number, x: number)
					local btn = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(if n == 1 then 104 else 64, if Theme.isTouch() then 40 else 34), Text = text, TextSize = 14, Parent = card })
					if not available or times < n then
						btn.BackgroundColor3 = rgb(60, 62, 70)
						btn.TextColor3 = rgb(150, 150, 160)
					end
					btn.Activated:Connect(function()
						if not available then
							SoundFx.play("MenuNo")
							return
						end
						SoundFx.play("MenuOk")
						remote:FireServer("Craft", r.Id, n)
					end)
				end
				if available then
					craftButton("Fabricar", 1, -70)
					craftButton("×5", 5, 0)
				else
					Theme.label({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(170, 34), Text = "Solo en un Taller de ciudad", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = card })
				end
			end
		end
	end
	render = draw
	draw()
	-- se cierra solo si te alejas (de la mesa plegable no: va contigo)
	if state.Bench ~= "Mesa" then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local origin = root and root.Position
		task.spawn(function()
			while panel == frame do
				task.wait(0.5)
				local now = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not now or not origin or (now.Position - origin).Magnitude > 18 then
					close(true)
				end
			end
		end)
	end
end

function CraftingUI.init()
	gui = create("ScreenGui", { Name = "CraftingGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 7, Parent = player:WaitForChild("PlayerGui") })
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.6, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	Dialog.registerBig("Crafting", function()
		close(true)
	end, function()
		return panel ~= nil
	end)
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Crafting") :: RemoteEvent
	remote.OnClientEvent:Connect(function(kind: string, a: any, b: any)
		if kind == "Open" and type(a) == "table" then
			state.Bench = if a.Bench == "Mesa" then "Mesa" else "Taller"
			state.Have = if type(a.Have) == "table" then a.Have else {}
			open()
		elseif kind == "Have" and type(a) == "table" then
			state.Have = a
			if render then
				render()
			end
		elseif kind == "Result" then
			SoundFx.play(if a then "MenuOk" else "MenuNo")
			local okHud, Hud = pcall(function()
				return require(script.Parent.Parent.UI.Hud) :: any
			end)
			if okHud and Hud.toast then
				Hud.toast(if a then "Success" else "Error", tostring(b or ""))
			end
		end
	end)
end

return CraftingUI
