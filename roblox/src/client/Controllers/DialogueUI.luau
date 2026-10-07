-- DialogueUI (cliente): las conversaciones de las misiones, como en un juego de rol.
--   * Lo que dice cada personaje sale en un bocadillo encima de él (UI/SpeechBubbles), escribiéndose
--     letra a letra; la caja de abajo queda para el nombre, "Toca para seguir" y tus respuestas.
--     El narrador (y quien no está en la escena o no se ve) sale en la caja, como siempre.
--   * Clic, toque (en la pantalla, la caja o el bocadillo), Espacio o E: termina de escribir la línea /
--     pasa a la siguiente. Las frases NO pasan solas: esperan a que toques (un toque justo al acabar de
--     escribirse no cuenta, ReadingTime.TAP_GUARD: un doble toque no se come una frase).
--   * Cuando te preguntan algo, tus respuestas aparecen como botones (teclas 1-4).
--   * La cámara se acerca a quien habla (si está en la escena) y vuelve a su sitio al acabar.
--   * Voz: la del perfil del personaje (StoryAudio). Mientras hay conversación, el personaje no anda.
--   * Escenificación automática (shared/LifeStory/StageDirector): plano general de situación al
--     empezar, planos de hombro o de dos según quién hable, plano de reacción en las preguntas,
--     pausas por la puntuación y las escritas (Pause, Beat), todo el reparto mira a quien habla, las
--     acotaciones («(susurrando)», «(al teléfono)») se hacen en vez de leerse y la cámara vuelve suave.
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
local Controls = require(script.Parent.Controls)
local CineCamera = require(script.Parent.CineCamera)
-- Cortes de escena (morir, reaparecer, irte a otro lugar): SceneClient avisa (si existe)
local SceneClient: any = nil
pcall(function()
	SceneClient = require(script.Parent.SceneClient) :: any
end)
local RideState = require(ReplicatedStorage.Shared.RideState)
local StageDirector = require(ReplicatedStorage.Shared.LifeStory.StageDirector)
local ReadingTime = require(ReplicatedStorage.Shared.LifeStory.ReadingTime)
-- Presets de plano (CameraShots.preset, si existe); si no, la geometría de StageDirector
local CameraShots: any = nil
pcall(function()
	CameraShots = require(ReplicatedStorage.Shared.CameraShots) :: any
end)

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
local closing = false -- se está cerrando (el servidor la cortó, moriste…): nada espera a que toques
local askToken: any, askSeq: any = nil, nil -- la pregunta abierta (conversación y trozo)
local typed = true -- la línea ya se ha escrito entera (el siguiente toque pasa a la siguiente)
local typedAt = 0 -- os.clock() de cuando acabó de escribirse
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
local currentAsk: BindableEvent? = nil -- la pregunta abierta (se cierra si el servidor corta)
local currentToken: number? = nil -- la conversación que se está enseñando
local currentApproach: { string }? = nil -- quién se acerca al empezar (lo dice el servidor)

---------------------------------------------------------------------
-- Controles y cámara
---------------------------------------------------------------------

-- (con Controls, que cuenta quién ha quitado el control: una cinemática que acabe con la
-- conversación abierta ya no te lo devuelve a mitad de la conversación)
local function setControls(enabled: boolean)
	pcall(function()
		if enabled then
			Controls.enable("Dialogo")
		else
			-- (se suelta solo si la conversación ya no está abierta: nunca te quedas sin control)
			Controls.disable("Dialogo", function()
				return open
			end)
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
local pausedByScene = false

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
		if Cinematics.isPlaying() then
			pausedByScene = true -- (durante una escena de cámara manda la escena)
			return
		end
		local camera = workspace.CurrentCamera
		if pausedByScene then
			pausedByScene = false
			camera.CameraType = Enum.CameraType.Scriptable -- (acabada la escena, otra vez la nuestra)
		elseif camera.CameraType ~= Enum.CameraType.Scriptable then
			return -- (alguien ha devuelto la cámara al juego: no se le quita)
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
	pausedByScene = false
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
	-- Sentado en un vehículo (conduciendo o de pasajero) la cámara sigue siendo la del vehículo: la de
	-- conversación nunca se la lleva (antes, en la moto, saltaba a un plano de diálogo)
	if RideState.inVehicle(player) then
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
	-- Sin paredes ni cabezas delante (y más cerca dentro de los edificios, que son pequeños)
	goal = CineCamera.fit(goal, focus, { Interior = CineCamera.inInterior() })
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

---------------------------------------------------------------------
-- Escenificación (StageDirector): planos con nombre, miradas, pausas
---------------------------------------------------------------------

local stage = StageDirector.newState() -- el director de la conversación que se enseña
local stageToken: any = nil -- (de qué conversación es)
local holding = false -- en una pausa, un tiempo de actuación o el plano de situación
local skipHold = false -- el jugador ha tocado: la pausa se acaba ya

local function modelId(model: Instance?): string?
	if not model then
		return nil
	end
	if model == player.Character then
		return "Yo"
	end
	local id = model:GetAttribute("NpcId")
	return if type(id) == "string" then id else nil
end

-- Las cabezas de todos los de la escena (y la tuya como "Yo"), por su id
local function stagePositions(line: { [string]: any }?): { [string]: Vector3 }
	local positions: { [string]: Vector3 } = {}
	local me = headOf(player.Character)
	if me then
		positions.Yo = me
	end
	local ok, cast = pcall(ActorLife.cast)
	for _, model in if ok and type(cast) == "table" then cast else {} do
		local id = modelId(model)
		local head = headOf(model)
		if id and head and (not me or (head - me).Magnitude < 60) then
			positions[id] = head
		end
	end
	if line then
		for _, pair in { { line.Id, line.Actor }, { line.To, line.ToActor } } do
			local id, model = pair[1], pair[2]
			local head = headOf(model)
			if type(id) == "string" and id ~= "Yo" and head and (not me or (head - me).Magnitude < 60) then
				positions[id] = head
			end
		end
	end
	return positions
end

-- Pone un plano con nombre ("Hombro:Yo>Nico"…). true si se ha podido (si falta alguien, la cámara se
-- queda como está)
local function frameShot(spec: string?, line: { [string]: any }?, from: string?): boolean
	if not spec or RideState.inVehicle(player) then
		return false
	end
	local positions = stagePositions(line)
	if not positions.Yo then
		return false
	end
	local ok, startCf, goalCf, seconds, focus = pcall(StageDirector.camera, spec, positions, CameraShots, { From = from or (line and line.Id) })
	if not ok or not startCf or not goalCf then
		return false
	end
	local camera = workspace.CurrentCamera
	local center: Vector3 = focus or positions.Yo
	-- Sin paredes ni cabezas delante (CameraShots.fit; más cerca dentro de los edificios, que son
	-- pequeños). Las caras que tienen que verse: quien habla y, en un plano de dos, el otro.
	local keep = {}
	for _, id in if CameraShots and CameraShots.subjects then CameraShots.subjects(spec) else {} do
		local p = positions[if id == "Player" then "Yo" else id]
		if p then
			table.insert(keep, p)
		end
	end
	local line = nil
	local pair = if CameraShots and CameraShots.pair then CameraShots.pair(spec) else nil
	if pair then
		local pa = positions[if pair[1] == "Player" then "Yo" else pair[1]]
		local pb = positions[if pair[2] == "Player" then "Yo" else pair[2]]
		line = if pa and pb then { pa, pb } else nil
	end
	local interior = CineCamera.inInterior()
	local a, choice = CineCamera.fit(startCf, center, { Interior = interior, Keep = keep, Line = line })
	local b = CineCamera.fit(goalCf, center, { Interior = interior, Keep = keep, Line = line, Choice = choice })
	-- (si el dolly atravesaría algo por el camino, una farola o un tabique, el plano se queda quieto)
	if CameraShots and CameraShots.clearPath and not CameraShots.clearPath(a.Position, b.Position, CineCamera.probe()) then
		a = b
	end
	if not savedCamera then
		savedCamera = { Type = camera.CameraType, CFrame = camera.CFrame }
	end
	camera.CameraType = Enum.CameraType.Scriptable
	-- La primera vez la cámara viaja desde donde estaba; luego, corte (o travelling si el plano lo es)
	local first = shot == nil
	local travelling = seconds ~= nil and seconds > 0.05
	shotCount += 1
	shot = {
		From = if first then camera.CFrame else a,
		To = b,
		Start = os.clock(),
		Blend = if first then 0.6 elseif travelling then seconds :: number else 0.01,
		Focus = center,
	}
	startCameraLoop()
	return true
end

-- Miradas: todo el reparto mira a quien habla. Se pide con atributos del jugador (solo en este cliente:
-- ActorLife los lee) y, mientras ActorLife no los use, con LookAt local en quien no tiene otro
local gazeSet: { [Instance]: any } = {} -- a quién le hemos puesto LookAt (y qué)
local function setGaze(line: { [string]: any }?, lookOverride: string?)
	local speakerId = if line and not line.Narrator then (if line.Me then "Player" else line.Id) else nil
	local to = line and line.To
	if to == "Yo" then
		to = "Player"
	end
	pcall(function()
		player:SetAttribute("StageSpeaker", speakerId)
		player:SetAttribute("StageTo", if type(to) == "string" then to else nil)
		player:SetAttribute("StageGaze", lookOverride)
	end)
	if type((ActorLife :: any).stageGaze) == "function" then
		pcall((ActorLife :: any).stageGaze, speakerId, to, lookOverride)
		return
	end
	if not speakerId then
		return
	end
	local speakerModel = line and line.Actor
	local ok, cast = pcall(ActorLife.cast)
	for _, model in if ok and type(cast) == "table" then cast else {} do
		pcall(function()
			local current = model:GetAttribute("LookAt")
			if model == speakerModel then
				if gazeSet[model] ~= nil and current == gazeSet[model] then
					model:SetAttribute("LookAt", nil)
				end
				gazeSet[model] = nil
			elseif current == nil or current == gazeSet[model] then
				model:SetAttribute("LookAt", speakerId)
				gazeSet[model] = speakerId
			end
		end)
	end
end

local function clearGaze()
	pcall(function()
		player:SetAttribute("StageSpeaker", nil)
		player:SetAttribute("StageTo", nil)
		player:SetAttribute("StageGaze", nil)
	end)
	if type((ActorLife :: any).stageGaze) == "function" then
		pcall((ActorLife :: any).stageGaze, nil, nil, nil)
	end
	for model, value in gazeSet do
		pcall(function()
			if model.Parent and model:GetAttribute("LookAt") == value then
				model:SetAttribute("LookAt", nil)
			end
		end)
	end
	table.clear(gazeSet)
end

-- Espera `seconds` (una pausa, un tiempo de actuación): un toque la acaba; se corta si se cierra.
-- done: además se acaba antes si eso se cumple
local function hold(seconds: number, done: (() -> boolean)?)
	if seconds <= 0 or closing then
		return
	end
	holding, skipHold = true, false
	local start = os.clock()
	while os.clock() - start < seconds and not skipHold and not closing and not closedTokens[currentToken] do
		if done and done() then
			break
		end
		task.wait(0.05)
	end
	holding = false
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

-- Vuelta de la cámara al juego. smooth: se desliza (StageDirector.EXIT_SECONDS) hasta donde estaba
-- (o detrás de ti); si no, de golpe (al morir o irte a otro lugar). Lo hace CineCamera.restore.
local function finishExit()
	-- (una conversación nueva coge la cámara: la vuelta de la anterior se corta)
	if type((CineCamera :: any).cancelRestore) == "function" then
		pcall((CineCamera :: any).cancelRestore)
	end
end

local function restoreCamera(smooth: boolean?)
	stopCameraLoop()
	if savedCamera then
		local saved = savedCamera
		savedCamera = nil
		-- Si hay una escena de cámara en marcha, ella devuelve la cámara al acabar
		if Cinematics.isPlaying() then
			return
		end
		local ok = pcall(function()
			CineCamera.restore(saved.CFrame, if smooth then { Seconds = StageDirector.EXIT_SECONDS } else { Instant = true } :: any)
		end)
		if not ok then
			CineCamera.restore(saved.CFrame) -- (a donde estaba, sin atravesar paredes, o detrás de ti)
		end
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
	-- Escala: suelo 0.8 en el móvil (texto legible); si la caja (más el nombre de encima) no cabe, baja
	Theme.popupScale(gui, { { Frame = box, Margin = 84 + 48 } })
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
	local staged = line.Stage == true
	local direction = if type(line.Direction) == "table" then line.Direction else {}
	local remote = direction.Remote
	local caption = direction.Whole == true -- la línea entera era una acotación: el actor la hace
	local displayName = line.Name
	if remote and displayName then
		displayName = (StageDirector.RemoteIcons[remote] or "📱") .. " " .. displayName
	end
	nameTag.Visible = displayName ~= nil and not line.Narrator
	nameTag.Text = displayName or ""
	nameTag.TextColor3 = if line.Me then NAME_COLORS.Me else NAME_COLORS.Other
	textLabel.TextColor3 = if line.Narrator or caption then Color3.fromRGB(200, 205, 215) else C.Text
	local full = escapeRich(line.Text or "")
	if line.Narrator or caption or direction.Whisper then
		full = "<i>" .. full .. "</i>"
	end
	StoryAudio.stopVoice() -- (una sola voz: la de la frase anterior se corta)
	-- (quien habla por teléfono no está en la escena: su frase va en la caja)
	local speakingModel = if line.Narrator or remote then nil else line.Actor
	if staged then
		-- Una conversación nueva: el director empieza de cero
		if stageToken ~= currentToken then
			stageToken = currentToken
			stage = StageDirector.newState()
		end
		local shotSpec = StageDirector.shotFor(stage, line)
		-- 1. Plano general de situación (y quien está lejos se acerca mientras)
		if shotSpec and not stage.Established and headOf(speakingModel) then
			local general = StageDirector.establish(stage)
			if frameShot(general, line) then
				local approach = currentApproach
				hold(StageDirector.ESTABLISH)
				if approach and #approach > 0 and not skipHold then
					-- (un poco más, como mucho, hasta que lleguen)
					hold(StageDirector.ESTABLISH_MAX - StageDirector.ESTABLISH, function()
						local me = headOf(player.Character)
						for _, id in approach do
							local them = headOf(ActorLife.find(id))
							if me and them and (them - me).Magnitude > StageDirector.APPROACH_STOP + 3 then
								return false
							end
						end
						return true
					end)
				end
			end
		end
		-- 2. El plano de la línea (hombro, de dos, primer plano…); si no se puede, la cámara de siempre
		local framed = shotSpec ~= nil and frameShot(shotSpec, line)
		if not framed and not line.Narrator and not remote then
			frame(line)
		end
		-- 3. Todo el reparto mira a quien habla
		setGaze(line, direction.Look)
		-- 4. Tiempo de actuación (respira, mira, piensa…) y pausa escrita, antes de hablar
		local beat = line.Beat
		if type(beat) == "table" and type(beat.Seconds) == "number" then
			if speakingModel and beat.Gesture then
				pcall(ActorLife.gesture, speakingModel, beat.Gesture, beat.Seconds)
			end
			if beat.Look then
				setGaze(line, if beat.Look == "To" then nil else beat.Look)
			end
			hold(math.min(beat.Seconds, StageDirector.MAX_BEAT))
			if beat.Look then
				setGaze(line, direction.Look)
			end
		end
		if type(line.Pause) == "number" then
			hold(math.min(line.Pause, StageDirector.MAX_PAUSE))
		end
		if closing or closedTokens[currentToken] then
			return
		end
	else
		frame(line)
	end
	if line.Voice and not line.Me and not caption then
		StoryAudio.speak(line.Voice, line.Text or "")
	end
	-- Quien habla se mueve al hablar (cabeza, manos, el gesto de la frase); los demás le miran
	if not line.Me and not line.Narrator then
		turnPlayerTowards(speakingModel) -- y tú te vuelves hacia quien te habla
	end
	local plainText = line.Text or ""
	local pauses, tail = {}, 0
	if staged then
		pauses, tail = StageDirector.pauses(plainText)
	end
	local typingSeconds = if staged then StageDirector.typingSeconds(plainText, TYPE_SPEED) else (utf8.len(plainText) or #plainText) / TYPE_SPEED
	ActorLife.speak(speakingModel, line.Emotion, typingSeconds + 0.8, line.Gesture, line.To, plainText)
	-- Bocadillo encima de quien habla (si está en la escena y cerca); si no, el texto va en la caja
	-- (una acotación entera no lleva bocadillo: es el subtítulo de lo que hace)
	lineSerial += 1
	local serial = lineSerial
	if bubbleOf and bubbleOf ~= speakingModel then
		SpeechBubbles.hide(bubbleOf)
		bubbleOf = nil
	end
	local bubbled = false
	local head = headOf(speakingModel)
	local camera = workspace.CurrentCamera
	-- (lo que dices tú va en la caja de abajo: encima de tu cabeza lo taparía tu propio personaje)
	if speakingModel and not line.Me and not caption and head and camera and (head - camera.CFrame.Position).Magnitude < BUBBLE_DISTANCE then
		bubbled = SpeechBubbles.show(speakingModel, plainText, {
			Name = line.Name,
			NameColor = if line.Me then NAME_COLORS.Me:Lerp(Color3.new(0, 0, 0), 0.35) else nil,
			Hold = true,
			Story = true, -- (encima de todo: las paredes no la tapan)
			Typing = TYPE_SPEED,
			Pauses = if #pauses > 0 then pauses else nil,
		})
	elseif caption and bubbleOf then
		SpeechBubbles.hide(bubbleOf)
		bubbleOf = nil
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
		-- (y vuelve al bocadillo en cuanto se ve otra vez: nunca la misma frase en los dos sitios).
		-- Solo cuenta si deja de verse un rato (al girarse la cámara hacia quien habla no)
		task.spawn(function()
			task.wait(0.35)
			local hiddenFor = 0
			while lineSerial == serial and open do
				local onScreen = SpeechBubbles.isOnScreen(speakingModel)
				hiddenFor = if onScreen then 0 else hiddenFor + 0.25
				local inBox = hiddenFor >= 1
				if inBox ~= textLabel.Visible then
					setCompact(not inBox)
					nameTag.Visible = inBox and line.Name ~= nil
					textLabel.Visible = inBox
				end
				task.wait(0.25)
			end
		end)
	end
	-- Escribir (si está escenificada, parándose en «…» y en los puntos)
	skipTyping = false
	typed = false
	local total = utf8.len(plainText) or #plainText
	textLabel.MaxVisibleGraphemes = 0
	textLabel.Text = full
	hint.Visible = bubbled -- con bocadillo, la caja solo dice "Toca para seguir"
	local started = os.clock()
	local shown = 0
	while shown < total and not skipTyping and not closing do
		task.wait()
		shown = StageDirector.revealed(os.clock() - started, TYPE_SPEED, total, pauses)
		textLabel.MaxVisibleGraphemes = shown
	end
	textLabel.MaxVisibleGraphemes = -1
	if bubbled then
		SpeechBubbles.reveal(speakingModel)
	end
	typed = true
	typedAt = os.clock()
	hint.Visible = true
	if staged and not closing then
		-- 5. Tras la pausa del final («…» o el punto), si era una pregunta: plano de reacción
		local reaction = StageDirector.reactionFor(line)
		if reaction then
			task.spawn(function()
				local at = os.clock()
				while os.clock() - at < tail and lineSerial == serial and not closing do
					task.wait(0.05)
				end
				if lineSerial == serial and not closing and open then
					pcall(frameShot, reaction, line, line.Id)
				end
			end)
		end
	end
	-- (si se cerró mientras escribía, no se espera a un toque que nunca llega: antes la caja se quedaba
	-- abierta, sin controles, hasta tocar la pantalla)
	if not closing and not closedTokens[currentToken] then
		advanceSignal.Event:Wait()
	end
	ActorLife.quiet(speakingModel)
	-- Silencio después de la frase (Pause = { After = … })
	if staged and type(line.After) == "number" then
		hold(math.min(line.After, StageDirector.MAX_PAUSE))
	end
end

local function ask(prompt: string?, options: { string }, staged: boolean?): number
	lineSerial += 1 -- (la frase de antes ya no mueve la caja)
	if staged and stage.Last then
		-- Te toca contestar: plano de reacción sobre ti, desde quien te ha hablado
		pcall(frameShot, "Reaccion:Yo", nil, stage.Last)
	end
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
			if index and index <= #options and not chosen and not Cinematics.isOnScreen() then
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
	pcall(CineCamera.quietLabels, "Dialogo", value)
	if not value then
		pcall(StoryAudio.stopVoice)
	end
	if value then
		finishExit() -- (si la cámara aún volvía de la conversación anterior, se queda en su sitio)
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
		pcall(clearGaze)
		holding, skipHold = false, false
		currentApproach = nil
		stageToken = nil
		restoreCamera(true) -- (suave: la cámara se desliza de vuelta al juego)
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
	closing = true
	table.clear(queue)
	skipTyping = true
	skipHold = true
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

-- ¿Hay una escena en pantalla (o esperando)? Las cinemáticas viejas y las del motor nuevo
local function sceneBusy(): boolean
	if Cinematics.isPlaying() then
		return true
	end
	local ok, playing = pcall(function()
		return require(script.Parent.HappeningClient).isPlaying()
	end)
	return ok and playing == true
end

processQueue = function()
	while #queue > 0 do
		local payload = table.remove(queue, 1) :: { [string]: any }
		-- Si hay una escena de cámara (o una esperando su turno), la conversación espera a que termine
		while sceneBusy() do
			task.wait(0.2)
		end
		if closedTokens[payload.Token] then
			continue -- el servidor ya cortó esta conversación
		end
		currentToken = payload.Token
		closing = false
		if payload.Approach then
			currentApproach = payload.Approach
		end
		-- Una conversación nueva tampoco se abre encima de un momento o una pantalla de capítulo
		-- (como mucho se espera un rato: la conversación nunca se queda sin salir)
		local since = os.clock()
		while not open and LifeStory.isShowing() and os.clock() - since < 15 do
			task.wait(0.2)
			while sceneBusy() do
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
			askToken, askSeq = payload.Token, payload.Seq
			local index = ask(payload.Ask, payload.Options, stageToken == payload.Token)
			askToken, askSeq = nil, nil
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

-- Un toque: acaba la pausa, termina de escribir la línea o pasa a la siguiente
function DialogueUI.tap()
	if holding then
		skipHold = true -- (una pausa o un tiempo de actuación: se acaba ya)
	elseif not typed then
		skipTyping = true -- (se ve entera ya; el siguiente toque pasa)
	elseif os.clock() - typedAt >= ReadingTime.TAP_GUARD then
		advanceSignal:Fire()
	end
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
			-- El servidor ya eligió por ti (tardaste mucho) y manda lo siguiente: la pregunta vieja se
			-- cierra (antes seguía en pantalla y lo que elegías no contaba)
			if currentAsk and askToken == payload.Token and type(payload.Seq) == "number" and type(askSeq) == "number" and payload.Seq > askSeq then
				currentAsk:Fire()
			end
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
	-- Muerte, reaparecer o teletransporte (SceneClient): se cierra y todo vuelve
	if SceneClient and type(SceneClient.onInterrupt) == "function" then
		pcall(SceneClient.onInterrupt, function(_reason: string)
			if open then
				if currentToken then
					closedTokens[currentToken] = true
				end
				for _, pending in queue do
					closedTokens[pending.Token] = true
				end
				forceClose()
			end
		end)
	end
	-- (si se quita el personaje sin morir —cambio de aspecto, reaparecer— también se cierra)
	player.CharacterRemoving:Connect(function()
		if open then
			if currentToken then
				closedTokens[currentToken] = true
			end
			for _, pending in queue do
				closedTokens[pending.Token] = true
			end
			forceClose()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		-- (durante una escena de cine la caja está escondida: no se pasan frases que no se ven)
		if not open or optionsFrame.Visible or Cinematics.isOnScreen() then
			return
		end
		-- (escribiendo en el chat: las teclas son para el chat, no para pasar frases)
		if processed and input.UserInputType == Enum.UserInputType.Keyboard then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Space or key == Enum.KeyCode.Return or key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonA
			or ((input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not processed) then
			DialogueUI.tap()
		end
	end)
	-- Tocar la caja: si está escribiendo, termina la línea; si no, pasa a la siguiente
	box.MouseButton1Down:Connect(function()
		if optionsFrame.Visible or Cinematics.isOnScreen() then
			return
		end
		DialogueUI.tap()
	end)
end

return DialogueUI
