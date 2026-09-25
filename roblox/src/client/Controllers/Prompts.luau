-- Prompts: carteles de "pulsa E" con el estilo de la interfaz (panel azul marino con borde azul).
--   [ E ]  Interactuar              <- ActionText del ProximityPrompt
--          Recoger objeto           <- ObjectText
-- Si hay que mantener pulsado, una barra se va llenando. En móvil se toca el cartel.
-- Cambia todos los ProximityPrompt del juego al estilo personalizado (solo en este dispositivo).

local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local Prompts = {}

local player = Players.LocalPlayer

local GAMEPAD_NAMES = {
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonL1] = "LB",
	[Enum.KeyCode.ButtonR1] = "RB",
}

local function keyText(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Touch then
		return "👆"
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return GAMEPAD_NAMES[prompt.GamepadKeyCode] or prompt.GamepadKeyCode.Name
	end
	local text = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
	if text == "" then
		text = prompt.KeyboardKeyCode.Name
	end
	return string.upper(text)
end

local function adornee(prompt: ProximityPrompt): Instance?
	local parent = prompt.Parent
	if parent and (parent:IsA("BasePart") or parent:IsA("Attachment")) then
		return parent
	elseif parent and parent:IsA("Model") then
		return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType, gui: Instance)
	local target = adornee(prompt)
	if not target then
		return
	end
	local billboard = create("BillboardGui", {
		Name = "Prompt",
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(380, 64),
		StudsOffset = Vector3.new(0, 1.2, 0),
		ResetOnSpawn = false,
		Active = true,
		Adornee = target,
		Parent = gui,
	})
	local card = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 56),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.1,
		AutoButtonColor = false,
		Text = "",
		Parent = billboard,
	}, {
		Theme.corner(14),
		create("UIStroke", { Color = C.Accent, Thickness = 2, Transparency = 0.15 }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(26, 44, 80), rgb(10, 18, 34)) }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 16) }),
	})
	-- Más pequeño en pantallas bajas (móvil)
	local size = math.clamp(workspace.CurrentCamera.ViewportSize.Y / 850, 0.6, 1)
	local scale = create("UIScale", { Scale = size * 0.8, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = size }):Play()

	local key = create("Frame", {
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.fromOffset(0, 7),
		BackgroundColor3 = rgb(20, 36, 70),
		Parent = card,
	}, { Theme.corner(10), create("UIStroke", { Color = C.Accent, Thickness = 2 }) })
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = keyText(prompt, inputType), Font = Theme.FontBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Parent = key })
	local texts = create("Frame", {
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.fromOffset(0, 56),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = card,
	})
	create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = texts })
	Theme.label({ Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Text = prompt.ActionText, Font = Theme.FontBold, TextSize = 18, LayoutOrder = 1, Parent = texts })
	if prompt.ObjectText ~= "" then
		Theme.label({ Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, Text = prompt.ObjectText, TextSize = 13, TextColor3 = C.Muted, LayoutOrder = 2, Parent = texts })
	end

	-- Barra de "mantener pulsado"
	local track = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.new(1, -20, 0, 4),
		BackgroundColor3 = rgb(20, 30, 52),
		BorderSizePixel = 0,
		Visible = prompt.HoldDuration > 0,
		Parent = card,
	}, { Theme.corner(2) })
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Parent = track }, { Theme.corner(2) })
	local holdTween: Tween? = nil
	local connections = {
		prompt.PromptButtonHoldBegan:Connect(function()
			if prompt.HoldDuration > 0 then
				holdTween = TweenService:Create(fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
				holdTween:Play()
			end
		end),
		prompt.PromptButtonHoldEnded:Connect(function()
			if holdTween then
				holdTween:Cancel()
			end
			fill.Size = UDim2.fromScale(0, 1)
		end),
		prompt.Triggered:Connect(function()
			TweenService:Create(key, TweenInfo.new(0.1), { BackgroundColor3 = C.Accent }):Play()
		end),
		prompt.TriggerEnded:Connect(function()
			TweenService:Create(key, TweenInfo.new(0.2), { BackgroundColor3 = rgb(20, 36, 70) }):Play()
		end),
	}
	-- Tocar el cartel (móvil) o hacer clic en él
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end)
	card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end)

	prompt.PromptHidden:Once(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		billboard:Destroy()
	end)
end

local function customize(instance: Instance)
	if instance:IsA("ProximityPrompt") then
		instance.Style = Enum.ProximityPromptStyle.Custom
	end
end

function Prompts.init()
	local gui = player:WaitForChild("PlayerGui")
	for _, instance in workspace:GetDescendants() do
		customize(instance)
	end
	workspace.DescendantAdded:Connect(customize)
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			show(prompt, inputType, gui)
		end
	end)
end

return Prompts
