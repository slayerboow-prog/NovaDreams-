-- DialogueUI (cliente): las conversaciones de las misiones, como en un juego de rol.
--   * Lo que dice cada personaje sale en un bocadillo encima de él (UI/SpeechBubbles), escribiéndose
--     letra a letra; la caja de abajo queda para el nombre, "Toca para seguir" y tus respuestas.
--     El narrador (y quien no está en la escena o no se ve) sale en la caja, como siempre.
--   * Clic, toque, Espacio o E: termina de escribir la línea / pasa a la siguiente.
--   * Cuando te preguntan algo, tus respuestas aparecen como botones (teclas 1-4).
--   * La cámara se acerca a quien habla (si está en la escena) y vuelve a su sitio al acabar.
--   * Voz: la del perfil del personaje (StoryAudio). Mientras hay conversación, el personaje no anda.
-- Lo que se ve lo decide el servidor (DialogueService); aquí solo se muestra y se contesta.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local StoryAudio = require(script.Parent.StoryAudio)
local Cinematics = require(script.Parent.Cinematics)
local LifeStory = require(script.Parent.LifeStory)
local ActorLife = require(script.Parent.ActorLife)
local DayLight = require(script.Parent.DayLight)
local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)

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
local boxPadding: UIPadding
local textLabel: TextLabel
local hint: TextLabel
local optionsFrame: Frame

local queue: { { [string]: any } } = {}
local running = false
local advanceSignal: BindableEvent
local skipTyping = false
local typed = true -- la línea ya se ha escrito entera (el siguiente toque pasa a la siguiente)
local bubbleOf: Instance? = nil -- quién tiene ahora el bocadillo de la conversación
local lineSerial = 0
local BUBBLE_DISTANCE = 55
local open = false
local savedCamera: { Type: Enum.CameraType, CFrame: CFrame }? = nil
-- Trozos de conversación ya en cola o ya contestados ("token:seq"): si el servidor reenvía uno
-- (por si se perdió), no se enseña dos veces
local queuedKeys: { [string]: boolean } = {}
local answeredKeys: { [string]: boolean } = {}
local closedTokens: { [number]: boolean } = {}
local currentAsk: BindableEvent? = nil
local currentToken: number? = nil -- la conversación que se está enseñando -- la pregunta abierta (se cierra si el servidor corta)

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

-- Cámara de conversación, como en una película:
--   * Cambia de plano según quién habla: por encima de tu hombro, primer plano de quien habla,
--     plano de los dos (al empezar) y contraplano cuando hablas tú. Al cambiar de persona, corte seco;
--     si sigue la misma, la cámara se desliza.
--   * Durante la frase la cámara se acerca muy despacio y se mece un poco (cámara en mano).
--   * El fondo se desenfoca y quien habla queda nítido.
local shot: { From: CFrame, To: CFrame, Start: number, Blend: number, Focus: Vector3 }? = nil
local shotCount = 0
local lastActor: Instance? = nil
local cameraConnection: RBXScriptConnection? = nil

local function smoothstep(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function startCameraLoop()
	if cameraConnection then
		return
	end
	cameraConnection = RunService.RenderStepped:Connect(function()
		local current = shot
		if not current then
			return
		end
		local camera = workspace.CurrentCamera
		local t = os.clock() - current.Start
		local base = current.From:Lerp(current.To, smoothstep(t / current.Blend))
		local push = math.min(t, 10) * 0.07 -- se acerca despacio
		local clock = os.clock()
		local sway = CFrame.Angles(math.sin(clock * 0.63) * 0.004, math.sin(clock * 0.47 + 1) * 0.005, math.sin(clock * 0.31) * 0.002)
		camera.CFrame = base * CFrame.new(0, 0, -push) * sway
		DayLight.setFocus((current.Focus - camera.CFrame.Position).Magnitude)
	end)
end

local function stopCameraLoop()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	shot = nil
	shotCount = 0
	lastActor = nil
	DayLight.setFocus(nil)
end

local function frame(line: { [string]: any })
	local camera = workspace.CurrentCamera
	local me = headOf(player.Character)
	local them = headOf(line.Actor)
	if line.Me then
		-- Hablas tú: la cámara te mira desde el lado de con quien hablabas
		them = headOf(lastActor) or them
	end
	if not me or not them or line.Narrator or (me - them).Magnitude > 60 then
		return
	end
	if not savedCamera then
		savedCamera = { Type = camera.CameraType, CFrame = camera.CFrame }
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local flat = Vector3.new(them.X - me.X, 0, them.Z - me.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	local forward = flat.Unit -- de ti hacia el otro
	local right = forward:Cross(Vector3.yAxis)
	local distance = flat.Magnitude
	shotCount += 1
	local changed = line.Actor ~= lastActor
	local goal: CFrame
	local focus: Vector3
	if line.Me then
		-- Contraplano: por encima del hombro del otro, mirándote a ti
		goal = CFrame.lookAt(them + forward * 4.2 - right * 1.6 + Vector3.new(0, 0.7, 0), me + Vector3.new(0, -0.2, 0))
		focus = me
	elseif shotCount == 1 then
		-- Al empezar: los dos de perfil
		local middle = (me + them) / 2
		goal = CFrame.lookAt(middle + right * (distance * 0.8 + 5) + Vector3.new(0, 1.2, 0), middle + Vector3.new(0, -0.3, 0))
		focus = middle
	elseif changed or shotCount % 3 ~= 0 then
		-- Por encima de tu hombro
		goal = CFrame.lookAt(me - forward * 4.5 + right * 1.8 + Vector3.new(0, 0.9, 0), them + Vector3.new(0, -0.2, 0))
		focus = them
	else
		-- Primer plano de quien habla (un poco de lado; con sitio arriba para su bocadillo)
		goal = CFrame.lookAt(them - forward * 4.6 + right * 1.2 + Vector3.new(0, 0.3, 0), them + Vector3.new(0, 0.5, 0))
		focus = them
	end
	local from = if shot and not changed then camera.CFrame else goal
	if shotCount == 1 then
		from = camera.CFrame -- la primera vez la cámara viaja desde donde estaba
	end
	shot = { From = from, To = goal, Start = os.clock(), Blend = if from == goal then 0.01 else 0.6, Focus = focus }
	if not line.Me then
		lastActor = line.Actor
	end
	startCameraLoop()
end

-- Te vuelves hacia quien te habla, poco a poco (unos 0,3 s), si estás de pie y cerca
local TURN_SECONDS = 0.3
local turnSerial = 0
local turnedFor: Instance? = nil
local function turnPlayerTowards(model: Instance?)
	if not model or model == turnedFor then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local them = headOf(model)
	if not root or not humanoid or not them or root.Anchored or humanoid.Sit or humanoid.Health <= 0 then
		return
	end
	local flat = Vector3.new(them.X - root.Position.X, 0, them.Z - root.Position.Z)
	if flat.Magnitude < 1 or flat.Magnitude > 25 then
		return
	end
	turnedFor = model
	local from = root.CFrame
	local goal = CFrame.lookAt(root.Position, root.Position + flat)
	if goal.LookVector:Dot(from.LookVector) > 0.985 then
		return
	end
	turnSerial += 1
	local serial = turnSerial
	humanoid.AutoRotate = false
	task.spawn(function()
		local start = os.clock()
		while serial == turnSerial and root.Parent do
			local t = math.min(1, (os.clock() - start) / TURN_SECONDS)
			local eased = t * t * (3 - 2 * t)
			root.CFrame = CFrame.new(root.Position) * from.Rotation:Lerp(goal.Rotation, eased)
			if t >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if serial == turnSerial and humanoid.Parent then
			humanoid.AutoRotate = true
		end
	end)
end

local function restoreCamera()
	stopCameraLoop()
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
	}, { Theme.corner(10), Theme.stroke(0.35), create("UIGradient", { Rotation = 90, Color = Theme.Sheen }) })
	create("UISizeConstraint", { MaxSize = Vector2.new(640, math.huge), Parent = box })
	boxPadding = create("UIPadding", {
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
		BackgroundColor3 = C.Panel,
		FontFace = Theme.TitleFace,
		TextSize = 17,
		TextColor3 = NAME_COLORS.Other,
		Text = "",
		Parent = box,
	}, {
		Theme.corner(5),
		Theme.stroke(0.2),
		create("UIGradient", { Rotation = 90, Color = Theme.Sheen }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 18) }),
	})

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

-- Con bocadillo, la caja se encoge a una pastilla pequeña que solo dice "Toca para seguir" (el nombre
-- y la frase ya van en el bocadillo); sin él, vuelve a ser la caja entera con el nombre encima
local compact = false
local function setCompact(on: boolean)
	if compact == on then
		return
	end
	compact = on
	box.Size = UDim2.fromOffset(if on then 230 else 640, 0)
	box.BackgroundTransparency = if on then 0.25 else 0.08
	boxPadding.PaddingTop = UDim.new(0, if on then 8 else 22)
	boxPadding.PaddingBottom = UDim.new(0, if on then 8 else 14)
	hint.TextSize = if on then 15 else 12
	hint.Size = UDim2.new(1, 0, 0, if on then 18 else 14)
	hint.TextXAlignment = if on then Enum.TextXAlignment.Center else Enum.TextXAlignment.Right
	hint.TextColor3 = if on then C.Text else C.Muted
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
	-- Quien habla se mueve al hablar (cabeza, manos, el gesto de la frase); los demás le miran
	local speakingModel = if line.Narrator then nil else line.Actor
	if not line.Me and not line.Narrator then
		turnPlayerTowards(speakingModel) -- y tú te vuelves hacia quien te habla
	end
	local plainText = line.Text or ""
	ActorLife.speak(speakingModel, line.Emotion, (utf8.len(plainText) or #plainText) / TYPE_SPEED + 0.8)
	-- Bocadillo encima de quien habla (si está en la escena y cerca); si no, el texto va en la caja
	lineSerial += 1
	local serial = lineSerial
	if bubbleOf and bubbleOf ~= speakingModel then
		SpeechBubbles.hide(bubbleOf)
		bubbleOf = nil
	end
	local bubbled = false
	local head = headOf(speakingModel)
	local camera = workspace.CurrentCamera
	if speakingModel and head and camera and (head - camera.CFrame.Position).Magnitude < BUBBLE_DISTANCE then
		bubbled = SpeechBubbles.show(speakingModel, plainText, {
			Name = line.Name,
			NameColor = if line.Me then NAME_COLORS.Me:Lerp(Color3.new(0, 0, 0), 0.35) else nil,
			Hold = true,
			Typing = TYPE_SPEED,
		})
	end
	if bubbled then
		bubbleOf = speakingModel
	end
	textLabel.Visible = not bubbled
	setCompact(bubbled)
	if bubbled then
		nameTag.Visible = false -- ya sale en el bocadillo
	end
	if bubbled then
		-- Si su bocadillo no se ve en tu pantalla (fuera de plano, tapado…), el texto va también en la caja
		task.spawn(function()
			task.wait(0.35)
			while lineSerial == serial and open and not textLabel.Visible do
				if not SpeechBubbles.isOnScreen(speakingModel) then
					setCompact(false)
					nameTag.Visible = line.Name ~= nil
					textLabel.Visible = true
					break
				end
				task.wait(0.25)
			end
		end)
	end
	-- Escribir
	skipTyping = false
	typed = false
	local plain = line.Text or ""
	local total = utf8.len(plain) or #plain
	textLabel.MaxVisibleGraphemes = 0
	textLabel.Text = full
	hint.Visible = bubbled -- con bocadillo, la caja solo dice "Toca para seguir"
	local shown = 0
	while shown < total and not skipTyping do
		shown = math.min(total, shown + math.max(1, math.floor(TYPE_SPEED * task.wait())))
		textLabel.MaxVisibleGraphemes = shown
	end
	textLabel.MaxVisibleGraphemes = -1
	if bubbled then
		SpeechBubbles.reveal(speakingModel)
	end
	typed = true
	hint.Visible = true
	advanceSignal.Event:Wait()
	ActorLife.quiet(speakingModel)
end

local function ask(prompt: string?, options: { string }): number
	setCompact(false) -- las respuestas van en la caja entera
	for _, child in optionsFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if prompt and prompt ~= "" then
		textLabel.Visible = true
		nameTag.Visible = true
		nameTag.Text = player.DisplayName
		nameTag.TextColor3 = NAME_COLORS.Me
		textLabel.TextColor3 = C.Muted
		textLabel.MaxVisibleGraphemes = -1
		textLabel.Text = escapeRich(prompt)
	end
	local chosen: number? = nil
	local picked = Instance.new("BindableEvent")
	currentAsk = picked
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
	currentAsk = nil
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
	ActorLife.conversation(value)
	if value then
		box.Visible = true
		setControls(false)
	else
		box.Visible = false
		if bubbleOf then
			SpeechBubbles.hide(bubbleOf)
			bubbleOf = nil
		end
		textLabel.Visible = true
		setCompact(false)
		restoreCamera()
		setControls(true)
		turnSerial += 1
		turnedFor = nil
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
	end
end

-- Corta todo lo que se esté enseñando (el servidor cortó la conversación, has muerto…): la caja se
-- cierra y vuelven controles, cámara y giro, pase lo que pase
local function forceClose()
	table.clear(queue)
	skipTyping = true
	advanceSignal:Fire()
	if currentAsk then
		currentAsk:Fire()
	end
end

local processQueue: () -> ()

local function process()
	if running then
		return
	end
	running = true
	-- Si algo falla a mitad de una conversación, la caja se cierra igual (antes se quedaba
	-- "hablando" para siempre y el HUD entero seguía escondido)
	local ok, err = pcall(processQueue)
	if not ok then
		warn("[DialogueUI] " .. tostring(err))
		table.clear(queue)
		table.clear(queuedKeys) -- si el servidor lo reenvía, se vuelve a enseñar
	end
	if not pcall(setOpen, false) then
		open = false
		player:SetAttribute("InDialogue", nil)
	end
	running = false
end

processQueue = function()
	while #queue > 0 do
		local payload = table.remove(queue, 1) :: { [string]: any }
		-- Si hay una escena de cámara (o una esperando su turno), la conversación espera a que termine
		while Cinematics.isPlaying() do
			task.wait(0.2)
		end
		if closedTokens[payload.Token] then
			continue -- el servidor ya cortó esta conversación
		end
		currentToken = payload.Token
		-- Una conversación nueva tampoco se abre encima de un momento o una pantalla de capítulo
		-- (como mucho se espera un rato: la conversación nunca se queda sin salir)
		local since = os.clock()
		while not open and LifeStory.isShowing() and os.clock() - since < 15 do
			task.wait(0.2)
			while Cinematics.isPlaying() do
				task.wait(0.2)
			end
		end
		setOpen(true)
		for _, line in payload.Lines or {} do
			if closedTokens[payload.Token] then
				break
			end
			showLine(line)
		end
		local key = ("%s:%s"):format(tostring(payload.Token), tostring(payload.Seq))
		queuedKeys[key] = nil
		answeredKeys[key] = true
		if closedTokens[payload.Token] then
			continue
		end
		if payload.Options then
			local index = ask(payload.Ask, payload.Options)
			if closedTokens[payload.Token] then
				continue
			end
			Remote:FireServer("Next", payload.Token, index, payload.Seq)
			-- Lo siguiente llega enseguida (la respuesta del otro); la caja sigue abierta
			local waited = 0
			while #queue == 0 and waited < 3 do
				waited += task.wait(0.05)
			end
		else
			Remote:FireServer("Next", payload.Token, nil, payload.Seq)
			if payload.Final then
				-- ¿Viene otra conversación justo detrás? Si no, se cierra
				local waited = 0
				while #queue == 0 and waited < 0.25 do
					waited += task.wait(0.05)
				end
			end
		end
	end
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
			local key = ("%s:%s"):format(tostring(payload.Token), tostring(payload.Seq))
			if payload.Seq ~= nil and (queuedKeys[key] or answeredKeys[key]) then
				return -- reenvío de algo que ya se está enseñando o ya se contestó
			end
			queuedKeys[key] = true
			table.insert(queue, payload)
			task.spawn(process)
		elseif kind == "Close" then
			-- El servidor corta la conversación (moriste, la historia cambió…): se cierra todo,
			-- también una pregunta abierta, y vuelven los controles y la cámara
			if payload and payload.Token then
				closedTokens[payload.Token] = true
			end
			forceClose()
		end
	end)
	-- Redes de seguridad: al morir se cierra; al reaparecer (o tras un teletransporte que cambie de
	-- personaje) los controles y la cámara vuelven aunque algo se quedara a medias
	local function watchCharacter(character: Model)
		if not open then
			pcall(restoreCamera)
			setControls(true)
		end
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				if currentToken then
					closedTokens[currentToken] = true
				end
				if open then
					for _, pending in queue do
						closedTokens[pending.Token] = true
					end
					forceClose()
				end
			end)
		end
	end
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not open or optionsFrame.Visible then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Space or key == Enum.KeyCode.Return or key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonA
			or (input.UserInputType == Enum.UserInputType.MouseButton1 and not processed) then
			if typed then
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
		if typed then
			advanceSignal:Fire()
		else
			skipTyping = true
		end
	end)
end

return DialogueUI
