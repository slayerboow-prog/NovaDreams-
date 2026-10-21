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
--   * Fase 2 del cine (docs/cine/auditoria-sistema.md): retrato de quien habla a la izquierda del
--     texto (la cara de su personaje si está en la escena; si no, su inicial con el color de su ropa:
--     shared/LifeStory/DialogueLook), velocidad del texto del menú (Lento, Normal, Rápido o
--     Instantáneo: shared/LifeStory/TextSpeed, atributo TextSpeed), «tic» suave al escribir (🔔 Efectos;
--     callado con la voz y en Instantáneo) y el texto acompasado con la voz si se sabe lo que dura.
--     Tocar una vez: la frase sale entera; otra vez: la siguiente.
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
local SceneReport = require(script.Parent.SceneReport)
-- Cortes de escena (morir, reaparecer, irte a otro lugar): SceneClient avisa (si existe)
local SceneClient: any = nil
pcall(function()
	SceneClient = require(script.Parent.SceneClient) :: any
end)
local RideState = require(ReplicatedStorage.Shared.RideState)
local StageDirector = require(ReplicatedStorage.Shared.LifeStory.StageDirector)
local ReadingTime = require(ReplicatedStorage.Shared.LifeStory.ReadingTime)
local TextSpeed = require(ReplicatedStorage.Shared.LifeStory.TextSpeed)
local DialogueLook = require(ReplicatedStorage.Shared.LifeStory.DialogueLook)
-- El reparto (color de la ropa y brillo para la insignia del retrato) y el «tic» de tecleo (si existen)
local CastPeople: { [string]: any }? = nil
pcall(function()
	CastPeople = (require(ReplicatedStorage.Shared.LifeStory.Cast) :: any).People
end)
local SoundFx: any = nil
pcall(function()
	SoundFx = require(script.Parent.SoundFx) :: any
end)
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

local TYPE_SPEED = TextSpeed.Rates.Normal -- letras por segundo (la de siempre; la elegida: speedNow)
local TOUCH = UserInputService.TouchEnabled
local NAME_COLORS = {
	Me = Color3.fromRGB(110, 190, 255),
	Other = Color3.fromRGB(255, 205, 90),
}

local gui: ScreenGui
local box: Frame
local nameTag: TextLabel
local boxPadding: UIPadding
local textLabel: TextLabel
local textRow: Frame -- retrato + texto, uno al lado del otro
local portrait: Frame
local portraitInitial: TextLabel
local portraitView: ViewportFrame
local portraitImage: ImageLabel
local portraitIcon: TextLabel
local portraitStroke: UIStroke
local hint: TextLabel
local optionsFrame: Frame
local boxList: UIListLayout
local nameHolder: Frame
-- Las medidas de ahora (DialogueLook.layout: a la medida de la pantalla, en píxeles de verdad)
local L: DialogueLook.Layout = DialogueLook.layout(1366, 768)
local applyLayout: () -> ()
local fitWidth: number? = nil -- (la caja, más ancha si con la letra mínima aún no cabía: DialogueLook.fit)

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
local savedCamera: { Type: Enum.CameraType, CFrame: CFrame, Fov: number? }? = nil
local lastActorId: string? = nil -- (el id de quien te hablaba: tus respuestas se encuadran con él)
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
		if Cinematics.isOnScreen() then
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
		-- (y, a mitad de un travelling, tampoco rozando una pared: CameraShots.clearOff)
		local placed = base * CFrame.new(0, 0, -push) * sway
		local okClear, cleared = pcall(CameraShots.clearOff, placed, CineCamera.wallProbe())
		camera.CFrame = if okClear then cleared else placed
		-- (el campo de visión del plano: antes se quedaba el del juego, 70, y el plano de hombro de 45
		-- salía lejos y con tu cabeza en medio)
		if current.Fov then
			local k = smoothstep(t / math.max(current.Blend, 0.2))
			camera.FieldOfView = current.FromFov + (current.Fov - current.FromFov) * k
		end
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
	lastActorId = nil
	DayLight.setFocus(nil)
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

-- La altura de alguien respecto a un adulto (de los pies a la cabeza, 4,5 studs a escala 1): los planos
-- de un niño o un bebé a su medida (CameraShots.preset con scales)
local function scaleOf(model: Instance?): number?
	if not model or not model:IsA("Model") then
		return nil
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not head or not root or not humanoid then
		return nil
	end
	local feet = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
	local size = (head.Position.Y - feet) / 4.5
	return if size > 0.2 and size < 3 then size else nil
end
local stageScales: { [string]: number } = {} -- (las de la última llamada a stagePositions)

-- Las cabezas de todos los de la escena (y la tuya como "Yo"), por su id
local function stagePositions(line: { [string]: any }?): { [string]: Vector3 }
	local positions: { [string]: Vector3 } = {}
	stageScales = {}
	local me = headOf(player.Character)
	if me then
		positions.Yo = me
		stageScales.Yo = scaleOf(player.Character) :: any
	end
	local ok, cast = pcall(ActorLife.cast)
	for _, model in if ok and type(cast) == "table" then cast else {} do
		local id = modelId(model)
		local head = headOf(model)
		if id and head and (not me or (head - me).Magnitude < 60) then
			positions[id] = head
			stageScales[id] = scaleOf(model) :: any
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
local function frameShot(spec: string?, line: { [string]: any }?, from: string?, retried: boolean?): boolean
	if not spec or RideState.inVehicle(player) then
		return false
	end
	local positions = stagePositions(line)
	if not positions.Yo then
		return false
	end
	local ok, startCf, goalCf, seconds, focus = pcall(StageDirector.camera, spec, positions, CameraShots, { From = from or (line and line.Id), Scales = stageScales })
	if ok and SceneReport.injected("Director", "Camera") then
		ok, startCf = false, "fallo inyectado (prueba): Camera"
	end
	if not ok then
		-- (el plano no se pudo calcular: se avisa y la conversación sigue con el plano que había)
		SceneReport.report("Director", currentToken, "Camera", startCf)
		return false
	end
	if not startCf or not goalCf then
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
	-- (en el plano de situación, quien dice la frase tiene que verse: sin pared ni nadie delante)
	local speakerId = from or (line and line.Id)
	if spec == "General" and type(speakerId) == "string" and positions[speakerId] then
		table.insert(keep, positions[speakerId])
	end
	-- (la pareja del plano; antes se llamaba `line` y tapaba la frase: el grupo y el plano medio de
	-- repuesto recibían la pareja en vez de la frase)
	local axis = nil
	local pair = if CameraShots and CameraShots.pair then CameraShots.pair(spec) else nil
	if pair then
		local pa = positions[if pair[1] == "Player" then "Yo" else pair[1]]
		local pb = positions[if pair[2] == "Player" then "Yo" else pair[2]]
		axis = if pa and pb then { pa, pb } else nil
	end
	-- (bajo techo sin ser una sala del cielo, CameraShots.fit lo detecta solo: Interior = nil)
	local interior = if CineCamera.inInterior() then true else nil
	-- (los que tienen que salir: tú, quien habla y a quien habla; no el que pasa por la sala de al lado)
	local crowd = { positions.Yo }
	for _, id in { line and line.Id, line and line.To } do
		local p = if type(id) == "string" then positions[id] else nil
		if p and p ~= positions.Yo then
			table.insert(crowd, p)
		end
	end
	-- (quien sale mira a con quien habla: la cámara nunca en su nuca; y no más cerca de su cara de lo
	-- que deja el campo de visión del plano)
	local front = nil
	local subjectId = if CameraShots.subjects then CameraShots.subjects(spec)[1] else nil
	local subjectHead = if subjectId then positions[if subjectId == "Player" then "Yo" else subjectId] else nil
	if subjectHead then
		local otherId = if subjectId == "Yo" or subjectId == "Player" then (line and line.Id) else "Yo"
		local other = if otherId then positions[otherId] else nil
		if other and other ~= subjectHead then
			front = other - subjectHead
		end
	end
	local preset = CameraShots.preset(spec)
	local minimum = CameraShots.minDistance(spec, if type(preset) == "table" then preset.Fov else nil)
	-- (Wide: el plano de situación no se acorta bajo techo, para que quepa el grupo)
	local wide = spec == "General"
	local a, choice = CineCamera.fit(startCf, center, { Interior = interior, Keep = keep, Line = axis, Crowd = crowd, Front = front, Min = minimum, Wide = wide, Fov = if type(preset) == "table" then preset.Fov else nil })
	local b = CineCamera.fit(goalCf, center, { Interior = interior, Keep = keep, Line = axis, Choice = choice, Crowd = crowd, Front = front, Min = minimum, Wide = wide, Fov = if type(preset) == "table" then preset.Fov else nil })
	-- Por encima del hombro, pero con la cabeza de quien queda de espaldas pegada a la cámara (una pared
	-- detrás la acerca): su nuca llenaba media pantalla. O girado para esquivar a otro hasta quedar
	-- pegado a la cara de quien habla. Entonces, plano medio de quien está enfrente.
	local kind, args = CameraShots.parsePreset(spec)
	if kind == "Hombro" and #args == 2 then
		local near = positions[if args[1] == "Player" then "Yo" else args[1]]
		local far = positions[if args[2] == "Player" then "Yo" else args[2]]
		if (near and (near - b.Position).Magnitude < CameraShots.SHOULDER_MIN) or (far and (far - b.Position).Magnitude < CameraShots.SHOULDER_FAR_MIN) then
			return frameShot("Medio:" .. args[2], line, from, true)
		end
	end
	-- Un plano de alguien (medio, primer plano, reacción) con la cabeza de otro pegada a la cámara: la
	-- suya llenaba media pantalla. Es un plano por encima de su hombro: se hace como tal.
	local intruder = if retried then nil else CameraShots.nearIntruder(spec, positions, b)
	if intruder then
		return frameShot("Hombro:" .. intruder .. ">" .. (args[1] :: string), line, from, true)
	end
	-- (si el dolly atravesaría algo por el camino, una farola o un tabique, el plano se queda quieto)
	if CameraShots and CameraShots.clearPath and not CameraShots.clearPath(a.Position, b.Position, CineCamera.probe()) then
		a = b
	end
	if not savedCamera then
		savedCamera = { Type = camera.CameraType, CFrame = camera.CFrame, Fov = camera.FieldOfView }
	end
	camera.CameraType = Enum.CameraType.Scriptable
	-- La primera vez la cámara viaja desde donde estaba; luego, corte (o travelling si el plano lo es)
	local first = shot == nil
	local travelling = seconds ~= nil and seconds > 0.05
	shotCount += 1
	local preset = if CameraShots and CameraShots.preset then CameraShots.preset(spec) else nil
	local fov = if type(preset) == "table" and type(preset.Fov) == "number" then preset.Fov else CameraShots.DEFAULT_FOV
	-- (un plano fijo deriva despacio hacia la cara mientras se dice la frase: StageDirector.drift)
	local drifting = not first and not travelling and spec ~= "General"
	shot = {
		From = if first then camera.CFrame else a,
		To = if drifting then StageDirector.drift(b, center, minimum) else b,
		Start = os.clock(),
		Blend = if first then 0.6 elseif travelling then seconds :: number elseif drifting then StageDirector.DRIFT_SECONDS else 0.01,
		Focus = center,
		Fov = fov,
		FromFov = if first or travelling then camera.FieldOfView else fov,
	}
	startCameraLoop()
	return true
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
	-- Con los mismos planos con nombre que las conversaciones escenificadas (el de hombro como el del
	-- aula, con su campo de visión y su plano medio de repuesto si no cabe): de perfil al empezar, por
	-- encima de tu hombro, y cada tres frases un primer plano de quien habla. Si no se puede (alguien
	-- sin id en el reparto), los planos de antes.
	-- (el id de la frase: un dependiente o alguien de la calle no está en el reparto de la escena, pero su
	-- cabeza sí está en stagePositions con ese id)
	local other = if line.Me then (lastActorId or modelId(lastActor or line.Actor)) else (if type(line.Id) == "string" and line.Id ~= "Yo" then line.Id else modelId(line.Actor))
	if other and other ~= "Yo" then
		local nextCount = shotCount + 1
		local changed = line.Actor ~= lastActor
		local spec = if line.Me
			then "Hombro:" .. other .. ">Yo"
			elseif nextCount == 1 then "DosPlanos:Yo," .. other
			elseif changed or nextCount % 3 ~= 0 then "Hombro:Yo>" .. other
			else "PrimerPlano:" .. other
		if frameShot(spec, line) then
			if not line.Me then
				lastActor = line.Actor
				lastActorId = other
			end
			return
		end
	end
	if not savedCamera then
		savedCamera = { Type = camera.CameraType, CFrame = camera.CFrame, Fov = camera.FieldOfView }
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
	goal = CineCamera.fit(goal, focus, { Interior = if CineCamera.inInterior() then true else nil })
	local from = if shot and not changed then camera.CFrame else goal
	if shotCount == 1 then
		from = camera.CFrame -- la primera vez la cámara viaja desde donde estaba
	end
	shot = { From = from, To = goal, Start = os.clock(), Blend = if from == goal then 0.01 else 0.6, Focus = focus, Fov = CameraShots.DEFAULT_FOV, FromFov = camera.FieldOfView }
	if not line.Me then
		lastActor = line.Actor
	end
	startCameraLoop()
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
		-- Si hay una escena de cámara en pantalla, ella devuelve la cámara al acabar. (Una que solo
		-- espera turno en la cola aún no tiene la cámara: si se atasca —H4— nadie la devolvería.)
		if Cinematics.isOnScreen() then
			return
		end
		local ok = pcall(function()
			CineCamera.restore(saved.CFrame, if smooth then { Seconds = StageDirector.EXIT_SECONDS, Fov = saved.Fov } else { Instant = true, Fov = saved.Fov } :: any)
		end)
		if not ok then
			CineCamera.restore(saved.CFrame) -- (a donde estaba, sin atravesar paredes, o detrás de ti)
		end
		if not ok or not smooth then
			workspace.CurrentCamera.FieldOfView = saved.Fov or CameraShots.DEFAULT_FOV
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
		-- (fuera de la muesca y de la barra de Roblox del móvil)
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		Parent = player:WaitForChild("PlayerGui"),
	})

	L = DialogueLook.layout(workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y)
	box = create("TextButton", {
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -L.Bottom),
		Size = UDim2.fromOffset(L.Width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.08,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = gui,
	}, { Theme.corner(10), Theme.stroke(0.35), create("UIGradient", { Rotation = 90, Color = Theme.Sheen }) })
	-- (sin UIScale: las medidas son ya las de esta pantalla —DialogueLook.layout— y se rehacen al
	-- girar el móvil o cambiar el tamaño de la ventana; antes la UIScale del móvil no bajaba de 0,8 y
	-- la caja tapaba media pantalla)
	boxPadding = create("UIPadding", {
		PaddingLeft = UDim.new(0, DialogueLook.Padding),
		PaddingRight = UDim.new(0, DialogueLook.Padding),
		PaddingTop = UDim.new(0, DialogueLook.PadTop),
		PaddingBottom = UDim.new(0, DialogueLook.PadBottom),
		Parent = box,
	})
	boxList = create("UIListLayout", { Padding = UDim.new(0, DialogueLook.ListGap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })

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

	-- Retrato + texto en una fila (la caja crece hacia arriba con frases largas: AutomaticSize)
	textRow = create("Frame", {
		Name = "TextRow",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = box,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, DialogueLook.Gap),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = textRow,
	})
	local side = DialogueLook.Portrait
	portrait = create("Frame", {
		Name = "Portrait",
		Size = UDim2.fromOffset(side, side),
		BackgroundColor3 = Color3.fromRGB(60, 130, 210),
		LayoutOrder = 0,
		Visible = false,
		Parent = textRow,
	}, { create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	portraitStroke = create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.35, Thickness = 2, Parent = portrait })
	portraitInitial = create("TextLabel", {
		Name = "Initial",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = Theme.TitleFace,
		TextSize = 28,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "",
		Parent = portrait,
	})
	portraitImage = create("ImageLabel", {
		Name = "Headshot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		Visible = false,
		Parent = portrait,
	}, { create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	portraitView = create("ViewportFrame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 170, 175),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-0.4, -0.6, -1),
		Visible = false,
		Parent = portrait,
	}, { create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	portraitIcon = create("TextLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 4, 1, 4),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = C.Panel,
		TextSize = 15,
		Text = "",
		Visible = false,
		ZIndex = 3,
		Parent = portrait,
	}, { create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })

	textLabel = create("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextSize = DialogueLook.TextSize,
		TextColor3 = C.Text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		RichText = true,
		Text = "",
		LayoutOrder = 1,
		Parent = textRow,
	})
	optionsFrame = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
		Parent = box,
	})
	create("UIListLayout", { Name = "Rows", Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = optionsFrame })
	hint = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, DialogueLook.HintSize),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextSize = DialogueLook.HintSize - 1,
		TextColor3 = C.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = if game:GetService("UserInputService").TouchEnabled then "Toca para seguir »" else "Clic o Espacio »",
		LayoutOrder = 3,
		Parent = box,
	})

	-- El nombre flota encima de la caja (un UIListLayout no lo debe colocar)
	nameHolder = create("Frame", {
		Name = "NameHolder",
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = box,
	})
	nameTag.Parent = nameHolder
	applyLayout()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		pcall(applyLayout)
	end)
end

-- Con bocadillo, la caja se encoge a una pastilla pequeña que solo dice "Toca para seguir" (el nombre
-- y la frase ya van en el bocadillo); sin él, vuelve a ser la caja entera con el nombre encima
local compact = false
local function sizeCompact()
	local on = compact
	box.Size = UDim2.fromOffset(if on then math.min(230, L.Width) else (fitWidth or L.Width), 0)
	box.BackgroundTransparency = if on then 0.25 else 0.08
	-- (la pastilla del móvil, alta como un botón: se toca bien, ≥ 44 px)
	boxPadding.PaddingTop = UDim.new(0, if on then (if TOUCH then 13 else 8) else L.PadTop)
	boxPadding.PaddingBottom = UDim.new(0, if on then (if TOUCH then 13 else 8) else L.PadBottom)
	hint.TextSize = if on then L.HintSize + 2 else L.HintSize
	hint.Size = UDim2.new(1, 0, 0, if on then 18 else L.HintSize + 1)
	hint.TextXAlignment = if on then Enum.TextXAlignment.Center else Enum.TextXAlignment.Right
	hint.TextColor3 = if on then C.Text else C.Muted
end
local function setCompact(on: boolean)
	if compact == on then
		return
	end
	compact = on
	sizeCompact()
end

-- Pone las medidas de la pantalla de ahora (DialogueLook.layout): ancho, márgenes, letra, retrato y el
-- nombre encima de la caja (fuera de ella, sin pisar la frase)
applyLayout = function()
	local view = workspace.CurrentCamera.ViewportSize
	L = DialogueLook.layout(view.X, view.Y)
	fitWidth = nil
	box.Position = UDim2.new(0.5, 0, 1, -L.Bottom)
	boxPadding.PaddingLeft = UDim.new(0, L.Padding)
	boxPadding.PaddingRight = UDim.new(0, L.Padding)
	boxList.Padding = UDim.new(0, L.ListGap)
	local tl = textRow:FindFirstChildOfClass("UIListLayout")
	if tl then
		tl.Padding = UDim.new(0, L.Gap)
	end
	portrait.Size = UDim2.fromOffset(L.Portrait, L.Portrait)
	portraitInitial.TextSize = math.floor(L.Portrait * 0.46)
	local icon = math.max(16, math.floor(L.Portrait * 0.4))
	portraitIcon.Size = UDim2.fromOffset(icon, icon)
	portraitIcon.TextSize = math.max(11, icon - 9)
	textLabel.TextSize = L.TextSize
	textLabel.Size = UDim2.new(1, if portrait.Visible then -(L.Portrait + L.Gap) else 0, 0, 0)
	nameTag.TextSize = L.NameSize
	nameTag.Size = UDim2.fromOffset(0, L.NameHeight)
	local pad = nameTag:FindFirstChildOfClass("UIPadding")
	if pad then
		pad.PaddingLeft = UDim.new(0, if L.Small then 10 else 14)
		pad.PaddingRight = UDim.new(0, if L.Small then 12 else 18)
	end
	-- (el soporte del nombre está arriba, dentro del relleno: el nombre sube el relleno y su alto)
	nameTag.Position = UDim2.fromOffset(-L.Padding + 4, -(L.PadTop + L.NameHeight + 2))
	sizeCompact()
end

local function escapeRich(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- La frase en la caja (con su retrato) o no (va en el bocadillo: la caja es la pastilla «Toca para seguir»)
local function setTextShown(on: boolean)
	textLabel.Visible = on
	textRow.Visible = on
end

---------------------------------------------------------------------
-- Retrato de quien habla (DialogueLook): su cara si está en la escena; si no, su inicial
---------------------------------------------------------------------

local faceOf: Instance? = nil -- de quién es la cara que hay en el retrato
local portraitBadge: DialogueLook.Badge? = nil

-- Copia de su cabeza (y lo que lleva en ella: pelo, gafas, gorra) para el ViewportFrame. nil si no se puede
local BODY = { HumanoidRootPart = true, UpperTorso = true, LowerTorso = true, Torso = true }
local function faceCopy(model: Instance): (Model?, CFrame?)
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return nil, nil
	end
	local holder = Instance.new("Model")
	holder.Name = "Cara"
	local function copy(part: BasePart)
		local ok, clone = pcall(function()
			return part:Clone()
		end)
		if ok and clone then
			for _, d in clone:GetDescendants() do
				if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui") then
					d:Destroy()
				end
			end
			clone.Anchored = true
			clone.Parent = holder
		end
	end
	copy(head)
	local headPos = head.Position
	local n = 0
	for _, d in model:GetDescendants() do
		if n >= 30 then
			break
		end
		if d ~= head and d:IsA("BasePart") and not BODY[d.Name] and d.Transparency < 1 and (d.Position - headPos).Magnitude < 1.6 + head.Size.Y * 0.5 then
			copy(d)
			n += 1
		end
	end
	if #holder:GetChildren() == 0 then
		holder:Destroy()
		return nil, nil
	end
	-- La cámara delante de su cara, un poco por encima, con la cabeza (y el pelo) dentro
	local size = math.max(head.Size.Y, 0.6)
	local look = head.CFrame.LookVector
	local eye = headPos + Vector3.new(0, size * 0.1, 0)
	return holder, CFrame.lookAt(eye + look * size * 3.4 + Vector3.new(0, size * 0.25, 0), eye)
end

local function clearFace()
	faceOf = nil
	for _, child in portraitView:GetChildren() do
		child:Destroy()
	end
	portraitView.Visible = false
end

-- Pone el retrato de la frase (o lo quita: el narrador, y una acotación entera, no llevan)
local function setPortrait(line: { [string]: any }?)
	local badge = if line then DialogueLook.badge(line, CastPeople, StageDirector.RemoteIcons) else nil
	portraitBadge = badge
	local shown = badge ~= nil and badge.Show
	portrait.Visible = shown
	textLabel.Size = UDim2.new(1, if shown then -(L.Portrait + L.Gap) else 0, 0, 0)
	if not shown or not badge or not line then
		clearFace()
		portraitImage.Visible = false
		return
	end
	local c = badge.Color
	portrait.BackgroundColor3 = Color3.fromRGB(c[1], c[2], c[3])
	portraitInitial.Text = badge.Initial
	local ring = badge.Ring
	portraitStroke.Color = if ring then Color3.fromRGB(ring[1], ring[2], ring[3]) else Color3.fromRGB(255, 255, 255)
	portraitStroke.Transparency = if ring then 0 else 0.35
	portraitStroke.Thickness = if ring then 3 else 2
	portraitIcon.Text = badge.Icon or ""
	portraitIcon.Visible = badge.Icon ~= nil
	-- Su cara (si está en la escena)
	local model: Instance? = if line.Me then player.Character else line.Actor
	local face = false
	if DialogueLook.wantsFace(line, model ~= nil and model.Parent ~= nil) then
		if faceOf == model and #portraitView:GetChildren() > 0 then
			face = true
		else
			clearFace()
			local ok, holder, view = pcall(faceCopy, model :: Instance)
			if ok and holder and view then
				local cam = Instance.new("Camera")
				cam.FieldOfView = 30
				cam.CFrame = view
				cam.Parent = portraitView
				holder.Parent = portraitView
				portraitView.CurrentCamera = cam
				faceOf = model
				face = true
			end
		end
	else
		clearFace()
	end
	portraitView.Visible = face
	-- Tú, sin tu personaje cerca: la foto de tu avatar de Roblox (si no carga, se ve la inicial debajo)
	local headshot = not face and line.Me == true and player.UserId > 0
	portraitImage.Image = if headshot then ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(player.UserId) else ""
	portraitImage.Visible = headshot
	portraitInitial.Visible = not face
end

-- La velocidad elegida en el menú (atributo TextSpeed, que pone el servidor al entrar)
local function speedNow(): string
	return TextSpeed.sanitize(player:GetAttribute(TextSpeed.Attribute))
end

-- «Tic» de tecleo (🔔 Efectos); callado mientras suena o se espera la voz de la frase
local function typeBlip()
	if not SoundFx or type(SoundFx.play) ~= "function" then
		return
	end
	local okVoice, done = pcall(StoryAudio.isVoiceDone)
	if okVoice and done == false then
		return
	end
	pcall(SoundFx.play, "DialogoTecla")
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
	pcall(setPortrait, line) -- (quién habla; el narrador, sin retrato)
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
	local voiced = false
	if line.Voice and not line.Me and not caption then
		StoryAudio.speak(line.Voice, line.Text or "")
		StoryAudio.waitVoice() -- (el texto sale con la voz: como mucho WaitText s de espera)
		voiced = true
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
	-- Velocidad: la del menú; Lento/Normal se acompasan con la voz si se sabe lo que dura (H2)
	local speed = speedNow()
	local chars = utf8.len(plainText) or #plainText
	local voiceSeconds = nil
	if voiced and type((StoryAudio :: any).voiceLength) == "function" then
		local okLen, len = pcall((StoryAudio :: any).voiceLength)
		voiceSeconds = if okLen and type(len) == "number" then len else nil
	end
	local rate = TextSpeed.paced(speed, chars, voiceSeconds)
	local instant = rate <= 0
	-- (cuánto «habla» el cuerpo: lo que se tarda en escribir; de golpe, lo de la velocidad normal)
	local bodyRate = if instant then TYPE_SPEED else rate
	local typingSeconds = if staged then StageDirector.typingSeconds(plainText, bodyRate) else chars / bodyRate
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
	-- (y solo si el bocadillo cabe en pantalla, por debajo de la franja de arriba: en un plano cerrado
	-- con la cabeza arriba salía cortado y no se leía; entonces el texto va en la caja de abajo)
	local function bubbleFits(): boolean
		if not head or not camera then
			return false
		end
		local cf = if shot and shot.To then shot.To else camera.CFrame
		local fov = if shot and shot.Fov then shot.Fov else camera.FieldOfView
		local rel = cf:PointToObjectSpace(head + Vector3.new(0, 2.6, 0))
		if rel.Z > -0.5 then
			return false
		end
		local y = rel.Y / (-rel.Z * math.tan(math.rad(fov) / 2)) -- (-1 abajo, 1 arriba)
		return y < 0.55
	end
	if speakingModel and not line.Me and not caption and head and camera and (head - camera.CFrame.Position).Magnitude < BUBBLE_DISTANCE and bubbleFits() then
		bubbled = SpeechBubbles.show(speakingModel, plainText, {
			Name = line.Name,
			NameColor = if line.Me then NAME_COLORS.Me:Lerp(Color3.new(0, 0, 0), 0.35) else nil,
			Hold = true,
			Story = true, -- (encima de todo: las paredes no la tapan)
			Typing = if instant then nil else rate,
			Pauses = if #pauses > 0 and not instant then pauses else nil,
		})
	elseif caption and bubbleOf then
		SpeechBubbles.hide(bubbleOf)
		bubbleOf = nil
	end
	if bubbled then
		bubbleOf = speakingModel
		pcall(SpeechBubbles.mute, speakingModel, false)
	end
	setTextShown(not bubbled)
	setCompact(bubbled)
	if bubbled then
		nameTag.Visible = false -- ya sale en el bocadillo
	end
	if bubbled then
		-- Si su bocadillo no se ve en tu pantalla (fuera de plano, tapado…), el texto va también en la caja
		-- (y vuelve al bocadillo en cuanto se ve otra vez: nunca la misma frase en los dos sitios).
		-- Solo cuenta si deja de verse un rato (al girarse la cámara hacia quien habla no), y vuelve al
		-- bocadillo cuando lleva un momento visible. Mientras va en la caja, el bocadillo está CALLADO
		-- (SpeechBubbles.mute): antes, al volver a verse, salían los dos a la vez un instante (H5).
		task.spawn(function()
			task.wait(0.35)
			local hiddenFor, shownFor = 0, 0
			local last = os.clock()
			while lineSerial == serial and open do
				local now = os.clock()
				local dt = now - last
				last = now
				local onScreen = SpeechBubbles.isOnScreen(speakingModel)
				hiddenFor = if onScreen then 0 else hiddenFor + dt
				shownFor = if onScreen then shownFor + dt else 0
				local inBox = textLabel.Visible
				if not inBox and hiddenFor >= 1 then
					inBox = true
				elseif inBox and shownFor >= 0.3 then
					inBox = false
				end
				if inBox ~= textLabel.Visible then
					-- (primero se calla uno y luego sale el otro: nunca los dos)
					if inBox then
						pcall(SpeechBubbles.mute, speakingModel, true)
					end
					setCompact(not inBox)
					nameTag.Visible = inBox and line.Name ~= nil
					setTextShown(inBox)
					if not inBox then
						pcall(SpeechBubbles.mute, speakingModel, false)
					end
				end
				task.wait()
			end
			if lineSerial ~= serial then
				pcall(SpeechBubbles.mute, speakingModel, false)
			end
		end)
	end
	-- Escribir (si está escenificada, parándose en «…» y en los puntos)
	skipTyping = false
	typed = false
	local total = chars
	textLabel.MaxVisibleGraphemes = if instant then -1 else 0
	textLabel.Text = full
	-- (la letra con la que cabe en el 40 % del alto de la pantalla: DialogueLook.fit; nunca < MinText)
	local fitSize, _, _, width = DialogueLook.fit(L, chars, portrait.Visible, nil, nameTag.Visible)
	textLabel.TextSize = fitSize
	fitWidth = if width ~= L.Width then width else nil
	sizeCompact()
	hint.Visible = bubbled -- con bocadillo, la caja solo dice "Toca para seguir"
	local started = os.clock()
	local shown = if instant then total else 0
	local every = if instant then 0 else TextSpeed.blipEvery(rate)
	while shown < total and not skipTyping and not closing do
		task.wait()
		local before = shown
		shown = StageDirector.revealed(os.clock() - started, rate, total, pauses)
		textLabel.MaxVisibleGraphemes = shown
		if TextSpeed.blip(before, shown, every) then
			typeBlip()
		end
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

-- by: quien hace la pregunta (la frase que manda el servidor con AskBy). Sin él, la pregunta es para ti
-- («¿Qué le dices?», «¿Qué haces?»): no la dice nadie, así que no lleva nombre ni retrato (antes salía
-- con TU nombre y tu cara, como si la dijeras tú: v124, «Sibuastian» encima de «¿Le echas una mano?»)
local function ask(prompt: string?, options: { string }, staged: boolean?, by: { [string]: any }?): number
	lineSerial += 1 -- (la frase de antes ya no mueve la caja)
	if staged and stage.Last then
		-- Te toca contestar: plano de reacción sobre ti, desde quien te ha hablado
		pcall(frameShot, "Reaccion:Yo", nil, stage.Last)
	end
	setCompact(false) -- las respuestas van en la caja entera
	for _, child in optionsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local speaker = if type(by) == "table" and not by.Narrator and type(by.Name) == "string" then by else nil
	local hasPrompt = prompt ~= nil and prompt ~= ""
	if hasPrompt then
		setTextShown(true)
		if speaker then
			pcall(setPortrait, speaker)
			nameTag.Visible = true
			nameTag.Text = speaker.Name
			nameTag.TextColor3 = if speaker.Me then NAME_COLORS.Me else NAME_COLORS.Other
			textLabel.TextColor3 = C.Text
			textLabel.Text = escapeRich(prompt :: string)
		else
			pcall(setPortrait, nil)
			nameTag.Visible = false
			nameTag.Text = ""
			textLabel.TextColor3 = C.Muted
			textLabel.Text = "<i>" .. escapeRich(prompt :: string) .. "</i>"
		end
		textLabel.MaxVisibleGraphemes = -1
	end
	-- Medidas: todo (nombre, pregunta y respuestas) en el 40 % del alto (DialogueLook.fit)
	local labels = {}
	for i, option in options do
		labels[i] = ("%d.  %s"):format(i, option)
	end
	local promptChars = if hasPrompt then (utf8.len(prompt :: string) or #(prompt :: string)) else 0
	local size, fits, _, width = DialogueLook.fit(L, promptChars, hasPrompt and portrait.Visible, labels, hasPrompt and nameTag.Visible)
	if not fits and hasPrompt and portrait.Visible then
		-- (muchas respuestas en una pantalla baja: fuera el retrato antes que pasar del 40 %)
		pcall(setPortrait, nil)
		size, fits, _, width = DialogueLook.fit(L, promptChars, false, labels, nameTag.Visible)
	end
	if hasPrompt then
		textLabel.TextSize = size
	end
	fitWidth = if width ~= L.Width then width else nil
	sizeCompact()
	local optionSize = math.max(DialogueLook.MinText, math.min(L.OptionSize, size))
	local columns = DialogueLook.columns(L, #options)
	local rows = optionsFrame:FindFirstChild("Rows") :: UIListLayout?
	if rows then
		rows.Padding = UDim.new(0, L.OptionGap)
	end
	local chosen: number? = nil
	local picked = Instance.new("BindableEvent")
	currentAsk = picked
	local row: Frame? = nil
	for i in options do
		if (i - 1) % columns == 0 then
			-- Una fila de `columns` respuestas, una al lado de otra (de dos en dos en el móvil)
			row = create("Frame", {
				Name = "Row" .. math.ceil(i / columns),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = i,
				Parent = optionsFrame,
			}, {
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, L.OptionGap),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})
		end
		local gaps = (columns - 1) * L.OptionGap
		local button = Theme.button({
			Name = "Option" .. i,
			Size = UDim2.new(1 / columns, -gaps / columns, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = labels[i],
			TextSize = optionSize,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.Font,
			LayoutOrder = i,
			Parent = row,
		})
		create("UIPadding", {
			PaddingLeft = UDim.new(0, L.OptionPadX),
			PaddingRight = UDim.new(0, L.OptionPadX),
			PaddingTop = UDim.new(0, L.OptionPadY),
			PaddingBottom = UDim.new(0, L.OptionPadY),
			Parent = button,
		})
		-- (cada respuesta es un botón cómodo de tocar: al menos DialogueLook.TouchTarget de alto; en el
		-- ordenador también, y así las de una fila miden lo mismo)
		create("UISizeConstraint", { MinSize = Vector2.new(0, L.Touch), Parent = button })
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
		setTextShown(true)
		setCompact(false)
		pcall(setPortrait, nil) -- (fuera la copia de la cara)
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
local retriedTokens: { [any]: boolean } = {} -- conversaciones que ya pidieron que se les reenvíe tras un fallo


local function process()
	if running then
		return
	end
	running = true
	-- Si algo falla a mitad de una conversación, la caja se cierra igual (antes se quedaba
	-- "hablando" para siempre y el HUD entero seguía escondido)
	local ok, err = pcall(processQueue)
	local failedToken = currentToken
	if not ok then
		-- Fase 3: se avisa al servidor (Controllers/SceneReport) y la conversación se retoma: se pide
		-- al servidor que vuelva a mandar el trozo (una vez por conversación); si vuelve a fallar, la
		-- caja se queda cerrada y el vigilante del servidor la sigue sola
		SceneReport.report("Dialogue", failedToken, "Play", err, "Abort")
		table.clear(queue)
		table.clear(queuedKeys) -- si el servidor lo reenvía, se vuelve a enseñar
	end
	if not pcall(setOpen, false) then
		open = false
		player:SetAttribute("InDialogue", nil)
		pcall(function()
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
			end
		end)
		pcall(setControls, true)
	end
	running = false
	if not ok then
		if failedToken ~= nil and not closedTokens[failedToken] and not retriedTokens[failedToken] then
			retriedTokens[failedToken] = true
			for key in answeredKeys do
				if key:sub(1, #tostring(failedToken) + 1) == tostring(failedToken) .. ":" then
					answeredKeys[key] = nil -- (el trozo que falló se puede volver a enseñar)
				end
			end
			pcall(function()
				Remote:FireServer("Again", failedToken)
			end)
		end
		SceneReport.recover("Dialogue")
	end
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

-- Espera a que acabe la escena en pantalla, con tope propio (H4: antes, si una cinemática se atascaba,
-- la conversación esperaba para siempre). Pasado SceneWaitMax s se avisa y la conversación sale igual.
local sceneWaitSince: number? = nil
local function waitScene(token: any)
	local since = sceneWaitSince or os.clock()
	sceneWaitSince = since
	while sceneBusy() do
		if os.clock() - since > DialogueUI.SceneWaitMax then
			SceneReport.report("Dialogue", token, "SceneWait", ("la escena en pantalla no acabó en %d s"):format(math.floor(DialogueUI.SceneWaitMax)), "Watchdog")
			break
		end
		task.wait(0.2)
	end
end

processQueue = function()
	while #queue > 0 do
		local payload = table.remove(queue, 1) :: { [string]: any }
		-- Si hay una escena de cámara (o una esperando su turno), la conversación espera a que termine
		sceneWaitSince = nil
		waitScene(payload.Token)
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
		local function titled(): boolean
			local ok, on = pcall(function()
				return require(script.Parent.HappeningClient).titleOnScreen()
			end)
			return ok and on == true
		end
		while not open and (LifeStory.isShowing() or titled()) and os.clock() - since < 15 do
			task.wait(0.2)
			waitScene(payload.Token)
		end
		sceneWaitSince = nil
		SceneReport.check("Dialogue", "Open")
		setOpen(true)
		pcall(StoryAudio.prefetchDialogue, payload.Lines) -- (las voces de lo que viene, ya generándose)
		-- (fase 3: cada frase en su pcall con aviso; una que falla se salta y la conversación sigue. Si
		-- fallan LineFailures seguidas, se corta y se retoma desde el servidor: process)
		local failedLines = 0
		for _, line in payload.Lines or {} do
			if closedTokens[payload.Token] then
				break
			end
			if SceneReport.guard("Dialogue", payload.Token, "Line", showLine, line) then
				failedLines = 0
			else
				failedLines += 1
				pcall(StoryAudio.stopVoice)
				if failedLines >= DialogueUI.LineFailures then
					error(("%d frases seguidas fallaron"):format(failedLines), 0)
				end
			end
		end
		local key = ("%s:%s"):format(tostring(payload.Token), tostring(payload.Seq))
		queuedKeys[key] = nil
		answeredKeys[key] = true
		if closedTokens[payload.Token] then
			continue
		end
		if payload.Options then
			askToken, askSeq = payload.Token, payload.Seq
			SceneReport.check("Dialogue", "Ask")
			local index = ask(payload.Ask, payload.Options, stageToken == payload.Token, payload.AskBy)
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

DialogueUI.AliveEvery = 20 -- cada cuánto se avisa al servidor de que la conversación sigue en pantalla
DialogueUI.SceneWaitMax = 200 -- tope de la espera a que acabe una escena (más que Cinematics.HoldMax)
DialogueUI.LineFailures = 3 -- frases seguidas que pueden fallar antes de cortar y pedir que se reenvíe

function DialogueUI.isOpen(): boolean
	return open
end

-- Un toque: acaba la pausa, termina de escribir la línea o pasa a la siguiente
-- (TextSpeed.tapAction: una vez, la frase sale entera; otra vez, la siguiente)
function DialogueUI.tap()
	local action = TextSpeed.tapAction({ Holding = holding, Typed = typed, SinceTyped = os.clock() - typedAt, Guard = ReadingTime.TAP_GUARD })
	if action == "SkipHold" then
		skipHold = true -- (una pausa o un tiempo de actuación: se acaba ya)
	elseif action == "Finish" then
		skipTyping = true -- (se ve entera ya; el siguiente toque pasa)
	elseif action == "Advance" then
		advanceSignal:Fire()
	end
end

-- (pruebas) lo que se ve ahora en la caja
function DialogueUI._view(): { [string]: any }
	return {
		Text = textLabel and textLabel.Text,
		Graphemes = textLabel and textLabel.MaxVisibleGraphemes,
		TextShown = textLabel and textLabel.Visible,
		Typed = typed,
		Portrait = portrait and portrait.Visible,
		Initial = portraitInitial and portraitInitial.Text,
		Face = portraitView and portraitView.Visible,
		Badge = portraitBadge,
		Box = box,
		Name = nameTag and nameTag.Visible and nameTag.Text or nil,
		TextSize = textLabel and textLabel.TextSize,
		Layout = L,
		Options = optionsFrame,
	}
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
	-- «Sigo aquí»: mientras la conversación está en pantalla (o en cola, esperando a que acabe una
	-- escena), el servidor no la da por abandonada (DialogueService.alive). Sin esto, a los 3 minutos de
	-- mandar un trozo el servidor la acababa o elegía la primera respuesta aunque siguieras leyendo.
	task.spawn(function()
		while true do
			task.wait(DialogueUI.AliveEvery)
			pcall(function()
				local tokens = {}
				if open and currentToken ~= nil and not closedTokens[currentToken] then
					tokens[currentToken] = true
				end
				for _, pending in queue do
					if pending.Token ~= nil and not closedTokens[pending.Token] then
						tokens[pending.Token] = true
					end
				end
				for token in tokens do
					Remote:FireServer("Alive", token)
				end
			end)
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
