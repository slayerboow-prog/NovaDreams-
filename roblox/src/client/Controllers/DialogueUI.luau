-- DialogueUI (cliente): las conversaciones de las misiones, como en un juego de rol.
--   * Lo que dice cada personaje sale en un bocadillo encima de él (UI/SpeechBubbles), escribiéndose
--     letra a letra; la caja de abajo queda para el nombre, "Toca para seguir" y tus respuestas.
--     El narrador (y quien no está en la escena o no se ve) sale en la caja, como siempre.
--   * Clic, toque, Espacio o E: termina de escribir la línea / pasa a la siguiente.
--   * Cuando te preguntan algo, tus respuestas aparecen como botones (teclas 1-4).
--   * La cámara se acerca a quien habla (si está en la escena) y vuelve a su sitio al acabar.
--   * Voz: la del perfil del personaje (StoryAudio). Mientras hay conversación, el personaje no anda.
--   * Si el servidor la corta ("Close"), mueres o desaparece tu personaje, la conversación se cierra
--     del todo (aunque estuviera escribiendo o esperando respuesta) y vuelven la cámara y los controles.
--   * Si empieza una cinemática con la conversación abierta, la cámara de la escena manda; al acabar,
--     la conversación retoma su plano. Los controles se cuentan en Controls (no se devuelven a medias).
-- Lo que se ve lo decide el servidor (DialogueService); aquí solo se muestra y se contesta.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local StoryAudio = require(script.Parent.StoryAudio)
local Cinematics = require(script.Parent.Cinematics)
local ActorLife = require(script.Parent.ActorLife)
local DayLight = require(script.Parent.DayLight)
local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)
local Controls = require(script.Parent.Controls)
local CineCamera = require(script.Parent.CineCamera)

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
local typed = true -- la línea ya se ha escrito entera (el siguiente toque pasa a la siguiente)
local bubbleOf: Instance? = nil -- quién tiene ahora el bocadillo de la conversación
local lineSerial = 0
local BUBBLE_DISTANCE = 55
local open = false
local closing = false -- se ha cerrado (servidor, muerte…): todo lo que espera sale sin contestar
local activePick: BindableEvent? = nil -- la pregunta que espera respuesta (para poder cerrarla)
local savedCamera: { Type: Enum.CameraType, CFrame: CFrame }? = nil

---------------------------------------------------------------------
-- Controles y cámara
---------------------------------------------------------------------

local function setControls(enabled: boolean)
	if enabled then
		Controls.enable("Dialogo")
	else
		Controls.disable("Dialogo")
	end
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
		if not current or Cinematics.isPlaying() then
			return -- (durante una cinemática la cámara es suya; al acabar, se retoma este plano)
		end
		local camera = workspace.CurrentCamera
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
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
	if not Cinematics.isPlaying() then
		camera.CameraType = Enum.CameraType.Scriptable
	end
	local flat = Vector3.new(them.X - me.X, 0, them.Z - me.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	local forward = flat.Unit -- de ti hacia el otro
	local right = forward:Cross(Vector3.yAxis)
	local distance = flat.Magnitude
	-- Dentro de una casa los planos son más cortos (y ninguno atraviesa paredes: CineCamera.clamp)
	local k = if CineCamera.inInterior() then 0.7 else 1
	local clamp = CineCamera.clamp
	shotCount += 1
	local changed = line.Actor ~= lastActor
	local goal: CFrame
	local focus: Vector3
	if line.Me then
		-- Contraplano: por encima del hombro del otro, mirándote a ti
		local at = clamp(them, them + (forward * 4.2 - right * 1.6) * k + Vector3.new(0, 0.7, 0))
		goal = CFrame.lookAt(at, me + Vector3.new(0, -0.2, 0))
		focus = me
	elseif shotCount == 1 then
		-- Al empezar: los dos de perfil
		local middle = (me + them) / 2
		local side = if k < 1 then math.min(distance * 0.8 + 3, CineCamera.InteriorRadius) else distance * 0.8 + 5
		local at = clamp(middle, middle + right * side + Vector3.new(0, 1.2, 0))
		goal = CFrame.lookAt(at, middle + Vector3.new(0, -0.3, 0))
		focus = middle
	elseif changed or shotCount % 3 ~= 0 then
		-- Por encima de tu hombro
		local at = clamp(me, me + (-forward * 4.5 + right * 1.8) * k + Vector3.new(0, 0.9, 0))
		goal = CFrame.lookAt(at, them + Vector3.new(0, -0.2, 0))
		focus = them
	else
		-- Primer plano de quien habla (un poco de lado; con sitio arriba para su bocadillo). Nunca más
		-- atrás que la mitad del camino hasta ti: si estáis cerca, la cámara no se mete dentro de tu cabeza
		local back = math.min(3.6, distance * 0.55)
		local at = clamp(them, them - forward * back + right * 1.2 * k + Vector3.new(0, 0.3, 0))
		goal = CFrame.lookAt(at, them + Vector3.new(0, 0.5, 0))
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

local function restoreCamera()
	stopCameraLoop()
	local saved = savedCamera
	savedCamera = nil
	if not saved or Cinematics.isPlaying() then
		return -- (con una cinemática en marcha, la cámara la devuelve ella al acabar)
	end
	local camera = workspace.CurrentCamera
	-- Vuelve donde estaba antes de hablar (o detrás de ti, mirando al frente) y luego al juego
	CineCamera.restore(saved.CFrame)
	if saved.Type ~= Enum.CameraType.Scriptable and camera.CameraType ~= saved.Type then
		camera.CameraType = saved.Type
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

local function escapeRich(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Escribe una línea letra a letra; devuelve cuando el jugador pasa a la siguiente
local function showLine(line: { [string]: any })
	if closing then
		return
	end
	StoryAudio.stopVoice() -- la frase anterior no sigue sonando por encima de esta
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
	if bubbled then
		-- Si su bocadillo no se ve en tu pantalla (fuera de plano, tapado…), el texto va también en la caja
		task.spawn(function()
			task.wait(0.35)
			while lineSerial == serial and open and not textLabel.Visible do
				if not SpeechBubbles.isOnScreen(speakingModel) then
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
	while shown < total and not skipTyping and not closing do
		shown = math.min(total, shown + math.max(1, math.floor(TYPE_SPEED * task.wait())))
		textLabel.MaxVisibleGraphemes = shown
	end
	textLabel.MaxVisibleGraphemes = -1
	if bubbled then
		SpeechBubbles.reveal(speakingModel)
	end
	typed = true
	hint.Visible = true
	if not closing then
		advanceSignal.Event:Wait()
	end
	StoryAudio.stopVoice()
	ActorLife.quiet(speakingModel)
end

local function ask(prompt: string?, options: { string }): number?
	if closing then
		return nil
	end
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
	activePick = picked
	if not closing then
		picked.Event:Wait()
	end
	activePick = nil
	ContextActionService:UnbindAction("DialogueOptions")
	picked:Destroy()
	optionsFrame.Visible = false
	if closing then
		return nil -- cerrada sin contestar
	end
	return chosen or 1
end

local function setOpen(value: boolean)
	if open == value then
		return
	end
	open = value
	player:SetAttribute("InDialogue", if value then true else nil) -- la mochila no se abre con la E mientras hablas
	ActorLife.conversation(value)
	CineCamera.quietLabels("Dialogo", value) -- sin nombres ni iconos flotantes en los primeros planos
	if value then
		box.Visible = true
		setControls(false)
	else
		StoryAudio.stopVoice()
		box.Visible = false
		if bubbleOf then
			SpeechBubbles.hide(bubbleOf)
			bubbleOf = nil
		end
		textLabel.Visible = true
		restoreCamera()
		setControls(true)
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
	end
	if not pcall(setOpen, false) then
		open = false
		player:SetAttribute("InDialogue", nil)
		pcall(setControls, true)
	end
	closing = false
	running = false
	-- Lo que llegó después de cerrar (una conversación nueva) se muestra ahora
	if #queue > 0 then
		task.spawn(process)
	end
end

processQueue = function()
	while #queue > 0 do
		if closing then
			break
		end
		local payload = table.remove(queue, 1) :: { [string]: any }
		-- Si hay una escena de cámara, la conversación espera a que termine
		while Cinematics.isPlaying() and not closing do
			task.wait(0.2)
		end
		if closing then
			break
		end
		setOpen(true)
		for _, line in payload.Lines or {} do
			showLine(line)
			if closing then
				break
			end
		end
		if closing then
			break -- cerrada a medias: no se contesta al servidor
		end
		if payload.Options then
			local index = ask(payload.Ask, payload.Options)
			if closing or not index then
				break
			end
			Remote:FireServer("Next", payload.Token, index)
			-- Lo siguiente llega enseguida (la respuesta del otro); la caja sigue abierta
			local waited = 0
			while #queue == 0 and waited < 3 and not closing do
				waited += task.wait(0.05)
			end
		else
			Remote:FireServer("Next", payload.Token)
			if payload.Final then
				-- ¿Viene otra conversación justo detrás? Si no, se cierra
				local waited = 0
				while #queue == 0 and waited < 0.25 and not closing do
					waited += task.wait(0.05)
				end
			end
		end
	end
end

function DialogueUI.isOpen(): boolean
	return open
end

-- Cierra la conversación en este cliente: lo que estaba escribiendo o esperando sale enseguida,
-- y al salir process() devuelve la cámara y los controles
local function closeLocal()
	table.clear(queue)
	StoryAudio.stopVoice()
	if not running then
		if open then
			pcall(setOpen, false)
		end
		return
	end
	closing = true
	skipTyping = true
	advanceSignal:Fire()
	if activePick then
		activePick:Fire()
	end
end
DialogueUI.close = closeLocal

-- Si mueres o desaparece tu personaje a media conversación, se cierra (si no, la cámara se
-- quedaba fija y los controles apagados). El servidor debería cancelar también la suya.
local function watchCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(function()
			if open or running then
				closeLocal()
			end
		end)
	end
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
			closeLocal()
		end
	end)
	player.CharacterAdded:Connect(function(character)
		task.spawn(watchCharacter, character)
	end)
	player.CharacterRemoving:Connect(function()
		if open or running then
			closeLocal()
		end
	end)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if not open or optionsFrame.Visible then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Space or key == Enum.KeyCode.Return or key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonA
			or ((input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not processed) then
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
