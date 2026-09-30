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

-- Un toque en el móvil: soltar antes de esto y sin arrastrar más de estos píxeles
local TAP_TIME = 0.45
local TAP_SLOP = 12
local TAP_STILL = 0.15 -- (carteles de mantener: el dedo quieto encima este rato para empezar)

-- Se dibuja el cartel del "foco" (lo que hace la tecla E, lo elige el menú de comandos) y, encima,
-- los que usan otra tecla: esos también se activan al pulsarla, así que tienen que verse
local focus: ProximityPrompt? = nil
local managed = false -- hasta que el menú de comandos elija, se ven todos (por si no arrancara)
-- Cada cartel a la vista. Billboard/Key: nil hasta que se construye (solo cuando se va a ver: si
-- relayout lo iba a esconder nada más crearlo, no se construye). Cleanup: lo quita todo (una vez).
type Entry = {
	Prompt: ProximityPrompt,
	Gui: Instance,
	Billboard: BillboardGui?,
	Key: TextLabel?,
	InputType: Enum.ProximityPromptInputType,
	Connections: { RBXScriptConnection },
	Cleanup: () -> (),
}
local shown: { [ProximityPrompt]: Entry } = {}
local build: (entry: Entry, fresh: boolean) -> ()

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

-- Coloca los carteles: el del foco en su sitio y los de otras teclas apilados encima
local function relayout()
	local focusKey = if focus then focus.KeyboardKeyCode else Enum.KeyCode.E
	local extras = {}
	for prompt, entry in shown do
		if not managed or prompt == focus then
			build(entry, false)
			local billboard = entry.Billboard :: BillboardGui
			billboard.Enabled = true
			billboard.SizeOffset = Vector2.zero
		elseif prompt.KeyboardKeyCode ~= focusKey and prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown then
			-- (Unknown: el menú de comandos le quitó la tecla por coincidir con la del foco)
			table.insert(extras, prompt)
		elseif entry.Billboard then
			entry.Billboard.Enabled = false
		end
	end
	-- Siempre en el mismo orden (por tecla) para que no bailen al moverte
	table.sort(extras, function(a, b)
		return a.KeyboardKeyCode.Value < b.KeyboardKeyCode.Value
	end)
	for i, prompt in extras do
		local entry = shown[prompt]
		build(entry, false)
		local billboard = entry.Billboard :: BillboardGui
		billboard.Enabled = true;
		(entry.Key :: TextLabel).Text = keyText(prompt, entry.InputType)
		-- (SizeOffset va en alturas del cartel: cada uno, una fila más arriba)
		billboard.SizeOffset = Vector2.new(0, if focus then i else i - 1)
	end
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

-- Construye el cartel de verdad (una vez). fresh: acaba de aparecer (con el saltito); si no, es uno
-- que estaba escondido y ahora se ve (sale ya a su tamaño, como antes)
build = function(entry: Entry, fresh: boolean)
	if entry.Billboard then
		return
	end
	local prompt, inputType, gui = entry.Prompt, entry.InputType, entry.Gui
	local target = adornee(prompt)
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
		create("UIGradient", { Rotation = 90, Color = Theme.Night }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 16) }),
	})
	-- Más pequeño en pantallas bajas (móvil)
	local size = math.clamp(workspace.CurrentCamera.ViewportSize.Y / 850, 0.6, 1)
	local scale = create("UIScale", { Scale = if fresh then size * 0.8 else size, Parent = card })
	if fresh then
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = size }):Play()
	end

	local key = create("Frame", {
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.fromOffset(0, 7),
		BackgroundColor3 = rgb(20, 36, 70),
		Parent = card,
	}, { Theme.corner(10), create("UIStroke", { Color = C.Accent, Thickness = 2 }) })
	local keyLabel = Theme.label({ Size = UDim2.fromScale(1, 1), Text = keyText(prompt, inputType), Font = Theme.FontBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Parent = key })
	entry.Billboard, entry.Key = billboard :: BillboardGui, keyLabel
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
	local connections = entry.Connections
	for _, connection in {
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
	} do
		table.insert(connections, connection)
	end
	-- Tocar el cartel (móvil) o hacer clic en él. En el móvil solo cuenta un toque de verdad: el
	-- cartel flota en medio del mundo y el dedo que gira la cámara o mueve al personaje pasaba
	-- por encima y lo activaba solo. Así que: tocar y soltar sin arrastrar (o, si hay que mantener,
	-- dejar el dedo quieto encima).
	local press: { Input: InputObject, From: Vector3, At: number, Holding: boolean }? = nil
	local mouseHolding = false -- (el clic empezó en este cartel)
	local function cancelPress()
		if press and press.Holding then
			prompt:InputHoldEnd()
		end
		press = nil
	end
	table.insert(connections, card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseHolding = true
			prompt:InputHoldBegin()
		elseif input.UserInputType == Enum.UserInputType.Touch and input.UserInputState == Enum.UserInputState.Begin then
			local current = { Input = input, From = input.Position, At = os.clock(), Holding = false }
			press = current
			if prompt.HoldDuration > 0 then
				-- Mantener: empieza si el dedo sigue quieto encima un momento
				task.delay(TAP_STILL, function()
					if press == current and (input.Position - current.From).Magnitude <= TAP_SLOP and input.UserInputState ~= Enum.UserInputState.End then
						current.Holding = true
						prompt:InputHoldBegin()
					end
				end)
			end
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		-- El dedo se mueve: era para la cámara o el joystick, no para el cartel
		if press and input == press.Input and (input.Position - press.From).Magnitude > TAP_SLOP then
			cancelPress()
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		-- Soltar el clic solo corta si se pulsó en este cartel (un clic en otro sitio, p. ej.
		-- disparar, no corta lo que mantienes con la tecla)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if mouseHolding then
				mouseHolding = false
				prompt:InputHoldEnd()
			end
			return
		end
		if not press or input ~= press.Input then
			return
		end
		local current = press
		press = nil
		if current.Holding then
			prompt:InputHoldEnd()
		elseif prompt.HoldDuration <= 0 and os.clock() - current.At <= TAP_TIME and (input.Position - current.From).Magnitude <= TAP_SLOP then
			-- Toque corto y sin arrastrar: ahora sí
			prompt:InputHoldBegin()
			prompt:InputHoldEnd()
		end
	end))

end

local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType, gui: Instance)
	if not adornee(prompt) then
		return
	end
	-- (si ya había uno de este cartel, se quita antes)
	local old = shown[prompt]
	if old then
		old.Cleanup()
	end
	local closed = false
	local entry: Entry
	-- Se quita al esconderse, al destruirse el ProximityPrompt o al sacarlo del juego (antes solo al
	-- esconderse: si se destruía a la vista, el cartel y sus conexiones se quedaban para siempre)
	local function cleanup()
		if closed then
			return
		end
		closed = true
		if shown[prompt] == entry then
			shown[prompt] = nil
		end
		for _, connection in entry.Connections do
			connection:Disconnect()
		end
		table.clear(entry.Connections)
		if entry.Billboard then
			entry.Billboard:Destroy()
		end
		relayout()
	end
	entry = { Prompt = prompt, Gui = gui, Billboard = nil, Key = nil, InputType = inputType, Connections = {}, Cleanup = cleanup }
	shown[prompt] = entry
	table.insert(entry.Connections, prompt.PromptHidden:Once(cleanup))
	table.insert(entry.Connections, prompt.Destroying:Once(cleanup))
	table.insert(entry.Connections, prompt.AncestryChanged:Connect(function()
		if not prompt:IsDescendantOf(game) then
			cleanup()
		end
	end))
	-- Se construye ya si se va a ver (lo decide relayout, como antes); si no, cuando toque
	if not managed or prompt == focus or (prompt.KeyboardKeyCode ~= (if focus then focus.KeyboardKeyCode else Enum.KeyCode.E) and prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown) then
		build(entry, true)
	end
	relayout()
end

local function customize(instance: Instance)
	if instance:IsA("ProximityPrompt") then
		instance.Style = Enum.ProximityPromptStyle.Custom
	end
end

-- El menú de comandos dice cuál es el cartel que va con la E: ese se ve (y los de otras teclas)
function Prompts.setFocus(prompt: ProximityPrompt?)
	focus = prompt
	managed = true
	local entry = prompt and shown[prompt]
	if entry and entry.Key then
		entry.Key.Text = keyText(prompt :: ProximityPrompt, entry.InputType)
	end
	relayout()
end

-- ¿Hay un cartel a la vista que se activa con esta tecla? (para que otras cosas no la usen a la vez)
function Prompts.keyInUse(key: Enum.KeyCode): boolean
	for prompt in shown do
		if prompt.Enabled and prompt.KeyboardKeyCode == key then
			return true
		end
	end
	return false
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
