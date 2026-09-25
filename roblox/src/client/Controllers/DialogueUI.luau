-- DialogueUI (cliente): las conversaciones de las misiones, como en un juego de rol.
--   * Caja abajo en el centro con el nombre de quien habla y el texto escribiéndose letra a letra.
--   * Clic, toque, Espacio o E: termina de escribir la línea / pasa a la siguiente.
--   * Cuando te preguntan algo, tus respuestas aparecen como botones (teclas 1-4).
--   * La cámara se acerca a quien habla (si está en la escena) y vuelve a su sitio al acabar.
--   * Voz: la del perfil del personaje (StoryAudio). Mientras hay conversación, el personaje no anda.
-- Lo que se ve lo decide el servidor (DialogueService); aquí solo se muestra y se contesta.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local StoryAudio = require(script.Parent.StoryAudio)
local Cinematics = require(script.Parent.Cinematics)

local create = Theme.create
local C = Theme.Colors

local DialogueUI = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent

local TYPE_SPEED = 55 -- letras por segundo
local NAME_COLORS = {
	Me = Color3.fromRGB(110, 190, 255),
	Other = Color3.fromRGB(255, 205, 90),
}

local gui: ScreenGui
local box: Frame
local nameTag: TextLabel
local textLabel: TextLabel
local hint: TextLabel
local optionsFrame: Frame

local queue: { { [string]: any } } = {}
local running = false
local advanceSignal: BindableEvent
local skipTyping = false
local open = false
local savedCamera: { Type: Enum.CameraType, CFrame: CFrame }? = nil

---------------------------------------------------------------------
-- Controles y cámara
---------------------------------------------------------------------

local function setControls(enabled: boolean)
	pcall(function()
		local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript) :: any
		local controls = module:GetControls()
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end)
end

local function headOf(model: Instance?): Vector3?
	if not model or not model:IsA("Model") or not model.Parent then
		return nil
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	if head then
		return head.Position
	end
	local pivot = model:GetPivot()
	return pivot.Position + Vector3.new(0, 2, 0)
end

-- Encuadre de "por encima del hombro": detrás del jugador mirando a quien habla (o al revés)
local function frame(line: { [string]: any })
	local camera = workspace.CurrentCamera
	local me = headOf(player.Character)
	local them = headOf(line.Actor)
	if not me or not them or line.Narrator or (me - them).Magnitude > 60 then
		return
	end
	if not savedCamera then
		savedCamera = { Type = camera.CameraType, CFrame = camera.CFrame }
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local from, to = me, them
	if line.Me then
		-- Habla el jugador: la cámara, desde el lado del otro, le mira a la cara
		from, to = them, me
	end
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	local forward = flat.Unit
	local right = forward:Cross(Vector3.yAxis)
	local position = from - forward * 4.5 + right * 1.8 + Vector3.new(0, 0.9, 0)
	local goal = CFrame.lookAt(position, to + Vector3.new(0, -0.2, 0))
	TweenService:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = goal }):Play()
end

local function restoreCamera()
	local camera = workspace.CurrentCamera
	if savedCamera then
		camera.CameraType = if savedCamera.Type == Enum.CameraType.Scriptable then Enum.CameraType.Custom else savedCamera.Type
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
		savedCamera = nil
	end
end

---------------------------------------------------------------------
-- Caja de diálogo
---------------------------------------------------------------------

local function build()
	gui = create("ScreenGui", {
		Name = "DialogueUI",
		ResetOnSpawn = false,
		DisplayOrder = 6,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 850, 0.65, 1.25)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	box = create("TextButton", {
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -84),
		Size = UDim2.fromOffset(640, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.08,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = gui,
	}, { Theme.corner(14), Theme.stroke(0.7) })
	create("UISizeConstraint", { MaxSize = Vector2.new(640, math.huge), Parent = box })
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
		PaddingTop = UDim.new(0, 22),
		PaddingBottom = UDim.new(0, 14),
		Parent = box,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })

	nameTag = create("TextLabel", {
		Name = "NameTag",
		Position = UDim2.fromOffset(4, -36),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.PanelLight,
		Font = Theme.FontBold,
		TextSize = 16,
		TextColor3 = NAME_COLORS.Other,
		Text = "",
		Parent = box,
	}, { Theme.corner(8), create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })

	textLabel = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextSize = 19,
		TextColor3 = C.Text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		RichText = true,
		Text = "",
		LayoutOrder = 1,
		Parent = box,
	})
	optionsFrame = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
		Parent = box,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = optionsFrame })
	hint = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = C.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = if game:GetService("UserInputService").TouchEnabled then "▼  Toca para seguir" else "▼  Clic o Espacio",
		LayoutOrder = 3,
		Parent = box,
	})

	-- El nombre flota encima de la caja (un UIListLayout no lo debe colocar)
	local holder = create("Frame", {
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = box,
	})
	nameTag.Parent = holder
	nameTag.Position = UDim2.fromOffset(-10, -48)

end

local function escapeRich(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Escribe una línea letra a letra; devuelve cuando el jugador pasa a la siguiente
local function showLine(line: { [string]: any })
	nameTag.Visible = line.Name ~= nil and not line.Narrator
	nameTag.Text = line.Name or ""
	nameTag.TextColor3 = if line.Me then NAME_COLORS.Me else NAME_COLORS.Other
	textLabel.TextColor3 = if line.Narrator then Color3.fromRGB(200, 205, 215) else C.Text
	local full = escapeRich(line.Text or "")
	if line.Narrator then
		full = "<i>" .. full .. "</i>"
	end
	frame(line)
	if line.Voice and not line.Me then
		StoryAudio.speak(line.Voice, line.Text or "")
	end
	-- Escribir
	skipTyping = false
	local plain = line.Text or ""
	local total = utf8.len(plain) or #plain
	textLabel.MaxVisibleGraphemes = 0
	textLabel.Text = full
	hint.Visible = false
	local shown = 0
	while shown < total and not skipTyping do
		shown = math.min(total, shown + math.max(1, math.floor(TYPE_SPEED * task.wait())))
		textLabel.MaxVisibleGraphemes = shown
	end
	textLabel.MaxVisibleGraphemes = -1
	hint.Visible = true
	advanceSignal.Event:Wait()
end

local function ask(prompt: string?, options: { string }): number
	for _, child in optionsFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if prompt and prompt ~= "" then
		nameTag.Visible = true
		nameTag.Text = player.DisplayName
		nameTag.TextColor3 = NAME_COLORS.Me
		textLabel.TextColor3 = C.Muted
		textLabel.MaxVisibleGraphemes = -1
		textLabel.Text = escapeRich(prompt)
	end
	local chosen: number? = nil
	local picked = Instance.new("BindableEvent")
	for i, option in options do
		local button = Theme.button({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = ("%d.  %s"):format(i, option),
			TextSize = 17,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.Font,
			LayoutOrder = i,
			Parent = optionsFrame,
		})
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			Parent = button,
		})
		button.Activated:Connect(function()
			if not chosen then
				chosen = i
				picked:Fire()
			end
		end)
	end
	optionsFrame.Visible = true
	hint.Visible = false
	local keys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six }
	ContextActionService:BindActionAtPriority("DialogueOptions", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			local index = table.find(keys, input.KeyCode)
			if index and index <= #options and not chosen then
				chosen = index
				picked:Fire()
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, table.unpack(keys))
	picked.Event:Wait()
	ContextActionService:UnbindAction("DialogueOptions")
	picked:Destroy()
	optionsFrame.Visible = false
	return chosen or 1
end

local function setOpen(value: boolean)
	if open == value then
		return
	end
	open = value
	player:SetAttribute("InDialogue", if value then true else nil) -- la mochila no se abre con la E mientras hablas
	if value then
		box.Visible = true
		setControls(false)
	else
		box.Visible = false
		restoreCamera()
		setControls(true)
	end
end

local function process()
	if running then
		return
	end
	running = true
	while #queue > 0 do
		local payload = table.remove(queue, 1) :: { [string]: any }
		-- Si hay una escena de cámara, la conversación espera a que termine
		while Cinematics.isPlaying() do
			task.wait(0.2)
		end
		setOpen(true)
		for _, line in payload.Lines or {} do
			showLine(line)
		end
		if payload.Options then
			local index = ask(payload.Ask, payload.Options)
			Remote:FireServer("Next", payload.Token, index)
			-- Lo siguiente llega enseguida (la respuesta del otro); la caja sigue abierta
			local waited = 0
			while #queue == 0 and waited < 3 do
				waited += task.wait(0.05)
			end
		else
			Remote:FireServer("Next", payload.Token)
			if payload.Final then
				-- ¿Viene otra conversación justo detrás? Si no, se cierra
				local waited = 0
				while #queue == 0 and waited < 0.25 do
					waited += task.wait(0.05)
				end
			end
		end
	end
	setOpen(false)
	running = false
end

function DialogueUI.isOpen(): boolean
	return open
end

function DialogueUI.init()
	advanceSignal = Instance.new("BindableEvent")
	build()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Dialogue") :: RemoteEvent
	Remote.OnClientEvent:Connect(function(kind: string, payload: { [string]: any })
		if kind == "Show" then
			table.insert(queue, payload)
			task.spawn(process)
		elseif kind == "Close" then
			table.clear(queue)
			skipTyping = true
			advanceSignal:Fire()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not open or optionsFrame.Visible then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Space or key == Enum.KeyCode.Return or key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonA
			or (input.UserInputType == Enum.UserInputType.MouseButton1 and not processed) then
			if hint.Visible then
				advanceSignal:Fire()
			else
				skipTyping = true
			end
		end
	end)
	-- Tocar la caja: si está escribiendo, termina la línea; si no, pasa a la siguiente
	box.MouseButton1Down:Connect(function()
		if optionsFrame.Visible then
			return
		end
		if hint.Visible then
			advanceSignal:Fire()
		else
			skipTyping = true
		end
	end)
end

return DialogueUI
