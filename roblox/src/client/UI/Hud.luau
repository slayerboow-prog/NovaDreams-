-- Hud: la interfaz principal (dinero, hora, necesidades, trabajo, avisos, botones).
-- Todo se crea por código, así que no hace falta diseñar nada en Studio.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Theme)

local create = Theme.create
local C = Theme.Colors

local Hud = {}

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui: ScreenGui
local toastList: Frame
local sleepOverlay: Frame

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------

local function buildMoney(parent: Instance)
	local panel = Theme.panel({
		Name = "Money",
		Size = UDim2.fromOffset(200, 48),
		Position = UDim2.fromOffset(16, 12),
		Parent = parent,
	})
	local label = Theme.label({
		Size = UDim2.fromScale(1, 1),
		Text = "$0",
		Font = Theme.FontBold,
		TextSize = 24,
		TextColor3 = C.Money,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = panel,
	})

	-- El número "sube" poco a poco en vez de saltar de golpe
	local shown = 0
	local target = 0
	local function update()
		target = player:GetAttribute("Money") or 0
	end
	player:GetAttributeChangedSignal("Money"):Connect(update)
	update()
	RunService.RenderStepped:Connect(function(dt)
		if shown ~= target then
			local step = (target - shown) * math.min(1, dt * 8)
			shown = if math.abs(target - shown) < 1 then target else shown + step
			label.Text = Format.money(math.floor(shown + 0.5))
		end
	end)
end

local function buildClock(parent: Instance)
	local panel = Theme.panel({
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(170, 48),
		Position = UDim2.new(0.5, 0, 0, 12),
		Parent = parent,
	})
	local time = Theme.label({
		Size = UDim2.new(1, 0, 0.62, 0),
		Font = Theme.FontBold,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = panel,
	})
	local day = Theme.label({
		Size = UDim2.new(1, 0, 0.38, 0),
		Position = UDim2.fromScale(0, 0.58),
		TextSize = 12,
		TextColor3 = C.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = panel,
	})
	RunService.RenderStepped:Connect(function()
		local clock = Lighting.ClockTime
		local icon = if clock >= 6.5 and clock < 19 then "☀" else "☾"
		time.Text = icon .. "  " .. Format.clock(clock)
		day.Text = "DÍA " .. tostring(workspace:GetAttribute("Day") or 1)
	end)
end

local function bar(parent: Instance, name: string, icon: string, color: Color3, order: number): (number) -> ()
	local row = create("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.label({ Size = UDim2.fromOffset(24, 22), Text = icon, TextSize = 16, Parent = row })
	local track = create("Frame", {
		Size = UDim2.new(1, -70, 0, 10),
		Position = UDim2.new(0, 26, 0.5, -5),
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		Parent = row,
	}, { Theme.corner(5) })
	local fill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = track,
	}, { Theme.corner(5) })
	local value = Theme.label({
		Size = UDim2.fromOffset(40, 22),
		Position = UDim2.new(1, -40, 0, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	return function(amount: number)
		local ratio = math.clamp(amount / Config.Needs.Max, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(ratio, 1) }):Play()
		fill.BackgroundColor3 = if amount <= Config.Needs.LowThreshold then C.Error else color
		value.Text = tostring(math.floor(amount))
	end
end

local function buildNeeds(parent: Instance)
	local panel = Theme.panel({
		Name = "Needs",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(230, 76),
		Position = UDim2.new(0, 16, 1, -16),
		Parent = parent,
	})
	Theme.padding(12).Parent = panel
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	local setHunger = bar(panel, "Hunger", "🍔", C.Hunger, 1)
	local setEnergy = bar(panel, "Energy", "⚡", C.Energy, 2)
	local function update()
		setHunger(player:GetAttribute("Hunger") or Config.Needs.Max)
		setEnergy(player:GetAttribute("Energy") or Config.Needs.Max)
	end
	player:GetAttributeChangedSignal("Hunger"):Connect(update)
	player:GetAttributeChangedSignal("Energy"):Connect(update)
	update()
end

local function buildJob(parent: Instance)
	local panel = Theme.panel({
		Name = "Job",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(280, 100),
		Position = UDim2.new(1, -16, 0, 12),
		Visible = false,
		Parent = parent,
	})
	Theme.padding(12).Parent = panel
	local title = Theme.label({ Size = UDim2.new(1, 0, 0, 20), Font = Theme.FontBold, TextSize = 18, Parent = panel })
	local taskLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.fromOffset(0, 22),
		TextSize = 14,
		TextColor3 = C.Muted,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = panel,
	})
	local quit = Theme.button({
		Size = UDim2.fromOffset(120, 22),
		Position = UDim2.new(0, 0, 1, -22),
		Text = "Dejar trabajo",
		TextSize = 13,
		BackgroundColor3 = Color3.fromRGB(120, 40, 40),
		Parent = panel,
	})
	quit.Activated:Connect(function()
		(Remotes:WaitForChild("QuitJob") :: RemoteEvent):FireServer()
	end)

	local function update()
		local jobId = player:GetAttribute("Job")
		local job = jobId and Config.Jobs[jobId]
		panel.Visible = job ~= nil
		if job then
			title.Text = "💼 " .. job.DisplayName .. "  ·  " .. Format.money(job.Pay)
			taskLabel.Text = player:GetAttribute("TaskText") or ""
		end
	end
	player:GetAttributeChangedSignal("Job"):Connect(update)
	player:GetAttributeChangedSignal("TaskText"):Connect(update)
	update()
end

local function buildButtons(parent: Instance, openStore: () -> ())
	local column = create("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(110, 110),
		Position = UDim2.new(0, 16, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), Parent = column })
	local home = Theme.button({ Size = UDim2.fromOffset(110, 44), Text = "🏠 Casa", Parent = column })
	home.Activated:Connect(function()
		(Remotes:WaitForChild("GoHome") :: RemoteEvent):FireServer()
	end)
	local store = Theme.button({
		Size = UDim2.fromOffset(110, 44),
		Text = "🛒 Tienda",
		BackgroundColor3 = Color3.fromRGB(150, 110, 20),
		Parent = column,
	})
	store.Activated:Connect(openStore)
end

---------------------------------------------------------------------
-- Avisos
---------------------------------------------------------------------

local TOAST_COLORS = {
	Success = C.Accent,
	Money = C.Money,
	Error = C.Error,
	Food = C.Hunger,
	Info = C.Muted,
	Sleep = C.Muted,
}

function Hud.toast(kind: string, text: string)
	local color = TOAST_COLORS[kind] or C.Muted
	local toast = Theme.panel({
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = toastList,
	})
	Theme.padding(10).Parent = toast
	local stroke = toast:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = color
	stroke.Transparency = 1
	local label = Theme.label({
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = text,
		Font = Theme.FontBold,
		TextColor3 = color,
		TextTransparency = 1,
		Parent = toast,
	})

	local fadeIn = TweenInfo.new(0.25)
	TweenService:Create(toast, fadeIn, { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(stroke, fadeIn, { Transparency = 0.3 }):Play()
	TweenService:Create(label, fadeIn, { TextTransparency = 0 }):Play()

	task.delay(3, function()
		local fadeOut = TweenInfo.new(0.4)
		TweenService:Create(toast, fadeOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, fadeOut, { Transparency = 1 }):Play()
		TweenService:Create(label, fadeOut, { TextTransparency = 1 }):Play()
		task.wait(0.45)
		toast:Destroy()
	end)
end

function Hud.sleep()
	sleepOverlay.Visible = true
	sleepOverlay.BackgroundTransparency = 1
	TweenService:Create(sleepOverlay, TweenInfo.new(0.8), { BackgroundTransparency = 0 }):Play()
	task.delay(Config.SleepSeconds - 0.8, function()
		local tween = TweenService:Create(sleepOverlay, TweenInfo.new(0.8), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		sleepOverlay.Visible = false
	end)
end

---------------------------------------------------------------------

function Hud.init(openStore: () -> ()): ScreenGui
	gui = create("ScreenGui", {
		Name = "NovaHud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- Escala la interfaz según el tamaño de pantalla (móvil / PC)
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 850, 0.65, 1.25)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	buildMoney(gui)
	buildClock(gui)
	buildNeeds(gui)
	buildJob(gui)
	buildButtons(gui, openStore)

	toastList = create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(600, 200),
		Position = UDim2.new(0.5, 0, 0, 72),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = toastList,
	})

	-- La pantalla negra de dormir va en su propio ScreenGui (sin UIScale) para cubrirlo todo
	local overlayGui = create("ScreenGui", {
		Name = "NovaSleep",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
		Parent = gui.Parent,
	})
	sleepOverlay = create("Frame", {
		Name = "Sleep",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		Visible = false,
		Parent = overlayGui,
	})
	Theme.label({
		Size = UDim2.fromScale(1, 1),
		Text = "Zzz...",
		Font = Theme.FontBold,
		TextSize = 40,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = sleepOverlay,
	})

	return gui
end

return Hud
