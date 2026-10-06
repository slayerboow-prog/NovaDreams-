-- HappeningClient (cliente): reproduce en TU pantalla las escenas de la historia que dirige el servidor
-- (server/Services/HappeningService; datos en shared/LifeStory/Happenings/*, cuentas en Sequencer).
--
-- Con el mismo reloj que el servidor (workspace:GetServerTimeNow()) hace las pistas del cliente:
--   Camera  planos de cine (travelling, fijo, órbita, seguir a un actor o a un efecto, zoom, inclinación,
--           cámara en mano) con transiciones (corte, fundido rápido, fundido lento, destello) — CameraShots
--   Shake   golpes de temblor (y los de los efectos: impactos, grietas)
--   Fx      efectos del catálogo (Controllers/StoryFx): meteorito, impacto, portal (atravesarlo te lleva
--           al otro lado), grieta, orbe, aura, tormenta…
--   Sky     cielo puntual (capas de DayLight con shared/SkyMoods) y la Grieta que se enciende (SkyRift)
--   Sound / Music   sonidos del catálogo o de SoundFx, música de la escena (StoryAudio)
--   Lines   diálogo EN EL MUNDO: bocadillo encima de quien habla (SpeechBubbles), subtítulo con su
--           nombre en la banda de cine, voz sintetizada (StoryAudio) y gestos con la emoción (ActorLife)
--   Titles  rótulos grandes · Fade fundidos a negro
--   Wait    la escena se para: «¡Cúbrete!» (un botón o E/Espacio), o te devuelve el control con una
--           pista («Cruza el portal»); sigue cuando el servidor lo dice
--   Dialogue  diálogo con tiempos, pausas y planos por frase (como Lines; las miradas las gira el servidor)
--   Ambience  capa de sonido ambiente (StoryAudio.setAmbience)  · Music también por intensidad
--             (StoryAudio.setIntensity)   · Light  luz de cine (StoryFx.setLight)
--           Las tres se deshacen SIEMPRE: al acabar, al saltar, al morir y si la escena falla.
-- Bandas de cine, menús escondidos y controles parados mientras dura (salvo las escenas LIGERAS:
-- solo efectos, sigues jugando). Botón «Saltar»: el servidor deja hechas las consecuencias.
-- Si eres ESPECTADOR (estabas cerca de la escena de otro: Audience = "Nearby") solo ves los efectos.
-- La escena llega ya resuelta del servidor (variante y condiciones: Variant, Gates) y se expande igual
-- que allí (Sequencer.compile): los dos ven lo mismo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local HappeningIndex = require(ReplicatedStorage.Shared.LifeStory.HappeningIndex)
local Sequencer = require(ReplicatedStorage.Shared.LifeStory.Sequencer)
local CameraShots = require(ReplicatedStorage.Shared.CameraShots)
local ActorMoods = require(ReplicatedStorage.Shared.LifeStory.ActorMoods)
local Emotion = require(ReplicatedStorage.Shared.LifeStory.Emotion)
local SkyMoods = require(ReplicatedStorage.Shared.SkyMoods)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local StoryFx = require(script.Parent.StoryFx)

local HappeningClient = {}

local player = Players.LocalPlayer
local BAR = 0.11

type ClientRun = {
	Serial: number,
	Id: string,
	Def: { [string]: any },
	Timeline: Sequencer.Timeline,
	StartAt: number,
	Paused: number,
	Hold: number?, -- segundo de la escena en el que está parada (espera)
	ResumedAfter: number, -- la última espera ya superada
	Anchors: { [string]: CFrame },
	Names: { [string]: string },
	Voices: { [string]: string },
	Args: { [string]: any },
	Light: boolean,
	Spectator: boolean,
	Inputs: { [string]: boolean },
	Cursor: number,
	Fx: { [string]: any },
	FxList: { any },
	FxPos: { [string]: Vector3 },
	ActorCache: { [string]: CFrame },
	Impulses: { { [string]: any } },
	Stopped: boolean,
	Skipped: boolean,
	SkyLayer: string?,
	Waiting: { [string]: any }?,
	Free: boolean, -- en una espera con Control = "Player": mandas tú
	Ui: { [string]: any }?,
	ShotIndex: any, -- el plano que se está viendo
	ShotResolve: CameraShots.Resolver?, -- el de este plano (con Lock: anclas clavadas al empezar)
	AmbienceOn: boolean,
	IntensityOn: boolean,
	MusicPlayed: boolean?, -- (escena sin cine que pidió una pieza con Play: al acabar se cierra)
	LightId: string?,
	Died: boolean,
}

local runs: { [number]: ClientRun } = {}
local remote: RemoteEvent? = nil
-- Quién puso el ambiente y la intensidad de música (si se solapan dos escenas, quita la suya la última)
local ambienceOwner: number? = nil
local intensityOwner: number? = nil

-- StoryAudio (paquete de audio): llamada defensiva (si la función aún no existe, no pasa nada)
local function audioCall(name: string, ...: any): boolean
	local args = table.pack(...)
	local ok = pcall(function()
		local audio = require(script.Parent.StoryAudio) :: any
		local fn = audio and audio[name]
		if type(fn) == "function" then
			fn(table.unpack(args, 1, args.n))
		end
	end)
	return ok
end

local function serverNow(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then t else os.clock()
end

local function tell(kind: string, serial: number, value: any?)
	if remote then
		remote:FireServer(kind, serial, value)
	end
end

---------------------------------------------------------------------
-- Encontrar cosas: anclas, actores de la escena, efectos
---------------------------------------------------------------------
local function sceneFolder(): Instance?
	local scenes = workspace:FindFirstChild("StoryScenes")
	return scenes and scenes:FindFirstChild("Scene_" .. player.UserId)
end

local function actorModel(key: string): Model?
	local folder = sceneFolder()
	if not folder then
		return nil
	end
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("HappeningKey") == key then
			return child
		end
	end
	return nil
end

local function characterCFrame(): CFrame?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.CFrame
end

local function resolver(run: ClientRun): CameraShots.Resolver
	return function(name: string): CFrame?
		if name == "Player" then
			return characterCFrame()
		end
		local kind, value = name:match("^(%a+):(.+)$")
		if kind == "Actor" then
			local model = actorModel(value)
			if model and model.Parent then
				local ok, pivot = pcall(function()
					return model:GetPivot()
				end)
				if ok then
					run.ActorCache[value] = pivot
					return pivot
				end
			end
			return run.ActorCache[value] or characterCFrame()
		elseif kind == "Fx" then
			local handle = run.Fx[value]
			if handle then
				local ok, p = pcall(handle.Position)
				if ok and p then
					run.FxPos[value] = p
				end
			end
			local p = run.FxPos[value]
			return p and CFrame.new(p) or nil
		end
		return run.Anchors[name]
	end
end

-- Mirada de los actores de la escena (ActorLife pregunta aquí lo que no sabe: la Grieta, las claves)
local function lookPoint(target: any): Vector3?
	for _, run in runs do
		if target == "Rift" then
			for name, anchor in run.Def.Anchors or {} do
				if anchor == "Rift" and run.Anchors[name] then
					return run.Anchors[name].Position
				end
			end
		elseif type(target) == "string" and target:sub(1, 4) == "Key:" then
			local model = actorModel(target:sub(5))
			local head = model and model:FindFirstChild("Head") :: BasePart?
			if head then
				return head.Position
			end
		end
	end
	if target == "Rift" then
		local ok, p = pcall(function()
			return require(script.Parent.SkyRift).worldPoint()
		end)
		return if ok then p else nil
	end
	return nil
end

---------------------------------------------------------------------
-- Interfaz de la escena
---------------------------------------------------------------------
local function hideOtherGuis(except: ScreenGui): () -> ()
	local restored = {}
	for _, child in player:WaitForChild("PlayerGui"):GetChildren() do
		if child:IsA("ScreenGui") and child ~= except and child.Enabled and child.Name ~= "StoryFlash" then
			child.Enabled = false
			table.insert(restored, child)
		end
	end
	local backpack = true
	pcall(function()
		backpack = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	return function()
		for _, gui in restored do
			gui.Enabled = true
		end
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, backpack)
		end)
	end
end

local function fadeText(label: TextLabel, visible: boolean, seconds: number)
	TweenService:Create(label, TweenInfo.new(seconds), {
		TextTransparency = if visible then 0 else 1,
		TextStrokeTransparency = if visible then 0.6 else 1,
	}):Play()
end

local function buildUi(run: ClientRun): { [string]: any }
	local gui = Theme.create("ScreenGui", {
		Name = "Escena",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 52,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local ui: { [string]: any } = { Gui = gui }
	if not run.Light then
		ui.Top = Theme.create("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), Parent = gui })
		ui.Bottom = Theme.create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 0),
			Parent = gui,
		})
		TweenService:Create(ui.Top, TweenInfo.new(0.7), { Size = UDim2.fromScale(1, BAR) }):Play()
		TweenService:Create(ui.Bottom, TweenInfo.new(0.7), { Size = UDim2.fromScale(1, BAR) }):Play()
	end
	ui.Black = Theme.create("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = if run.Def.FadeIn and not run.Light then 0 else 1,
		ZIndex = 10,
		Parent = gui,
	})
	if run.Def.FadeIn and not run.Light then
		TweenService:Create(ui.Black, TweenInfo.new(1.4), { BackgroundTransparency = 1 }):Play()
	end
	ui.Caption = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = if run.Light then UDim2.new(0.5, 0, 0.84, 0) else UDim2.fromScale(0.5, 1 - BAR / 2),
		Size = UDim2.new(0.86, 0, BAR, -8),
		Text = "",
		TextSize = 20,
		TextScaled = true,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1,
		ZIndex = 5,
		Parent = gui,
	})
	Theme.create("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 12, Parent = ui.Caption })
	ui.Title = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.44),
		Size = UDim2.new(0.9, 0, 0, 50),
		Text = "",
		Font = Theme.FontBold,
		TextSize = if (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 900) then 30 else 42,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = gui,
	})
	ui.Sub = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.new(0.9, 0, 0, 26),
		Text = "",
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.Colors.Gold,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = gui,
	})
	ui.Hint = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, BAR, 12),
		Size = UDim2.new(0.8, 0, 0, 30),
		Text = "",
		TextSize = 20,
		Font = Theme.FontBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 7,
		Parent = gui,
	})
	if not run.Light and run.Def.Skippable ~= false then
		ui.Skip = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, BAR / 2, 0),
			Size = UDim2.fromOffset(120, 34),
			Text = Strings.get("CINE.SKIP"),
			TextSize = 15,
			ZIndex = 20,
			Parent = gui,
		})
		ui.Skip.Activated:Connect(function()
			if not run.Skipped and not run.Stopped then
				run.Skipped = true
				tell("Skip", run.Serial)
				TweenService:Create(ui.Black, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
			end
		end)
	end
	return ui
end

-- Botón grande de reacción («¡Cúbrete!»): un toque, E, Espacio o el botón A del mando
local function showInput(run: ClientRun, w: { [string]: any })
	local ui = run.Ui
	if not ui then
		return
	end
	local button = Theme.button({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromOffset(260, 74),
		Text = (w.Prompt or "¡Ahora!") .. (if UserInputService.TouchEnabled then "" else "  [E]"),
		TextSize = 26,
		ZIndex = 30,
		Parent = ui.Gui,
	})
	local scale = Theme.create("UIScale", { Scale = 0.6, Parent = button })
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local pulse = TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.08 })
	task.delay(0.25, function()
		pulse:Play()
	end)
	local done = false
	local connection: RBXScriptConnection? = nil
	local function press()
		if done then
			return
		end
		done = true
		tell("Input", run.Serial, w.Input)
		pulse:Cancel()
		button.Text = "✔"
		task.delay(0.3, function()
			button:Destroy()
		end)
		if connection then
			connection:Disconnect()
		end
	end
	button.Activated:Connect(press)
	connection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
			press()
		end
	end)
	ui.InputButton = button
	ui.InputCleanup = function()
		done = true
		pcall(function()
			pulse:Cancel()
		end)
		if connection then
			connection:Disconnect()
		end
		if button.Parent then
			button:Destroy()
		end
	end
end

local onScreen = 0 -- escenas con cámara en tu pantalla ahora

local function setControls(on: boolean)
	pcall(function()
		local Controls = require(script.Parent.Controls)
		if on then
			Controls.enable("Escena")
		else
			-- (con la comprobación: si la escena ya no está, el bloqueo se suelta solo)
			Controls.disable("Escena", function()
				return HappeningClient.isPlaying()
			end)
		end
	end)
end

---------------------------------------------------------------------
-- Las pistas
---------------------------------------------------------------------
local function pointFromSpec(run: ClientRun, spec: any): CFrame?
	if type(spec) ~= "table" then
		return nil
	end
	local base = CameraShots.composite(resolver(run))(spec[1])
	if not base then
		return nil
	end
	local offset = if typeof(spec[2]) == "Vector3" then spec[2] else Vector3.zero
	return if spec[3] then base * CFrame.new(offset) else CFrame.new(base.Position + offset) * base.Rotation
end

local function playFx(run: ClientRun, d: { [string]: any }, index: number)
	local anchorName = d.Anchor or "Player"
	local cf = pointFromSpec(run, { anchorName, d.Offset })
	if not cf then
		return
	end
	local to = if d.To then pointFromSpec(run, d.To) else nil
	local model: Model? = nil
	if anchorName == "Player" then
		model = player.Character
	elseif anchorName:sub(1, 6) == "Actor:" then
		model = actorModel(anchorName:sub(7))
	end
	local params = d.Params
	local extra = {
		To = to,
		Seconds = d.Seconds,
		Model = model,
		OnChain = function(chained)
			if d.Key then
				run.Fx[d.Key] = chained -- (la cámara sigue ahora al impacto)
			end
			table.insert(run.FxList, chained)
		end,
		OnEnter = if params and params.Teleport and not run.Spectator
			then function()
				tell("Portal", run.Serial, index)
			end
			else nil,
	}
	local handle = StoryFx.play(d.Play, cf, params, extra)
	if handle then
		if d.Key then
			run.Fx[d.Key] = handle
		end
		table.insert(run.FxList, handle)
	end
end

local function showLine(run: ClientRun, line: { [string]: any })
	local ui = run.Ui
	local who = line.Speaker or line.S
	local text = Strings.get(line.Text or line.T or "", run.Args)
	local model: Model? = nil
	if who == "Yo" then
		model = player.Character
	elseif type(who) == "string" and who ~= "Narrador" then
		model = actorModel(who)
		if not model then
			pcall(function()
				model = require(script.Parent.ActorLife).find(who)
			end)
		end
	end
	local name = run.Names[who or ""]
	if ui then
		ui.Caption.Text = if name and name ~= "" then ('<font color="#FFC43C"><b>%s:</b></font> %s'):format(name, text) else text
		fadeText(ui.Caption, true, 0.25)
		ui.CaptionToken = (ui.CaptionToken or 0) + 1
		local token = ui.CaptionToken
		task.delay(line.Duration or math.max(2.6, #text * 0.055), function()
			if run.Ui and run.Ui.CaptionToken == token then
				fadeText(run.Ui.Caption, false, 0.35)
			end
		end)
	end
	local voice = run.Voices[who or ""]
	if voice then
		pcall(function()
			require(script.Parent.StoryAudio).speak(voice, text)
		end)
	end
	if model then
		local mood = ActorMoods.get(line.Mood)
		local emotion = line.A or (mood and mood.Pose) or Emotion.of({ S = who, T = text }, text)
		local seconds = if line.S ~= nil and type(line.Duration) == "number" then line.Duration else nil
		pcall(function()
			require(script.Parent.ActorLife).speak(model, emotion, seconds or math.max(2, #text * 0.05), line.G)
		end)
		if line.Bubble ~= false then
			pcall(function()
				require(script.Parent.Parent.UI.SpeechBubbles).show(model, text, { Name = name, Seconds = seconds or math.max(2.5, #text * 0.06), Story = true })
			end)
		end
	end
end

local function showTitle(run: ClientRun, d: { [string]: any })
	local ui = run.Ui
	if not ui then
		return
	end
	ui.Title.Text = Strings.get(d.Text or "", run.Args)
	ui.Sub.Text = if d.Sub then Strings.get(d.Sub, run.Args) else ""
	fadeText(ui.Title, true, 0.6)
	fadeText(ui.Sub, true, 0.6)
	ui.TitleToken = (ui.TitleToken or 0) + 1
	local token = ui.TitleToken
	task.delay(d.Duration or 3, function()
		if run.Ui and run.Ui.TitleToken == token then
			fadeText(run.Ui.Title, false, 0.6)
			fadeText(run.Ui.Sub, false, 0.6)
		end
	end)
end

local function applySky(run: ClientRun, d: { [string]: any })
	if d.Rift then
		pcall(function()
			require(script.Parent.SkyRift).flare(d.Strength or 1, d.Seconds or 2)
		end)
	end
	if d.Mood ~= nil then
		local id = "Escena" .. run.Serial
		pcall(function()
			local DayLight = require(script.Parent.DayLight)
			local mood = d.Mood and SkyMoods.get(d.Mood)
			if mood then
				DayLight.pushLayer(id, mood, d.Fade or 1)
				run.SkyLayer = id
			else
				DayLight.popLayer(id, d.Fade or 1)
				run.SkyLayer = nil
			end
		end)
	end
end

local function playSound(run: ClientRun, d: { [string]: any })
	local at = if d.Anchor then pointFromSpec(run, { d.Anchor }) else nil
	local spec = require(ReplicatedStorage.Shared.StoryFxCatalog).Sounds[d.Play]
	if spec then
		local sound = Instance.new("Sound")
		sound.SoundId = spec.Id
		sound.Volume = (spec.Volume or 0.7) * (d.Volume or 1)
		sound.PlaybackSpeed = (spec.Pitch or 1) * (d.Pitch or 1)
		sound.RollOffMaxDistance = 700
		local holder: Instance = workspace
		if at then
			local p = Instance.new("Attachment")
			p.WorldPosition = at.Position
			p.Parent = workspace.Terrain
			holder = p
			task.delay(8, function()
				p:Destroy()
			end)
		end
		sound.Parent = holder
		sound:Play()
		task.delay(8, function()
			sound:Destroy()
		end)
	else
		pcall(function()
			require(script.Parent.SoundFx).play(d.Play, d.Volume, d.Pitch)
		end)
	end
end

local function applyFade(run: ClientRun, d: { [string]: any })
	local ui = run.Ui
	if ui then
		TweenService:Create(ui.Black, TweenInfo.new(d.Seconds or 0.5), { BackgroundTransparency = 1 - (d.To or 1) }):Play()
	end
end

-- Ambiente (pista Ambience): Kind = capa o false (quitarla)
local function applyAmbience(run: ClientRun, d: { [string]: any })
	if d.Kind == false or d.Kind == nil then
		if ambienceOwner == run.Serial then
			audioCall("setAmbience", nil, d.Fade)
			ambienceOwner = nil
		end
		run.AmbienceOn = false
		return
	end
	audioCall("setAmbience", d.Kind, d.Fade)
	run.AmbienceOn = true
	ambienceOwner = run.Serial
end

-- Música por intensidad (pista Music con Intensity, o Intensity de la escena)
local function applyIntensity(run: ClientRun, level: any, fade: number?)
	audioCall("setIntensity", level, fade)
	run.IntensityOn = true
	intensityOwner = run.Serial
end

-- Luz de cine (pista Light): Preset o false
local function applyLight(run: ClientRun, d: { [string]: any })
	local id = "EscenaLuz" .. run.Serial
	if StoryFx.setLight(id, d.Preset, d.Fade, d.Weight) then
		run.LightId = id
	else
		run.LightId = nil
	end
end

-- Deshace ambiente, intensidad y luz de esta escena (siempre: final, salto, muerte, fallo)
local function undoMood(run: ClientRun, fade: number?)
	if run.AmbienceOn or ambienceOwner == run.Serial then
		run.AmbienceOn = false
		if ambienceOwner == run.Serial or ambienceOwner == nil then
			audioCall("setAmbience", nil, fade)
			ambienceOwner = nil
		end
	end
	if run.IntensityOn or intensityOwner == run.Serial then
		run.IntensityOn = false
		if intensityOwner == run.Serial or intensityOwner == nil then
			audioCall("setIntensity", nil, fade)
			intensityOwner = nil
		end
	end
	-- (la capa de luz se quita aunque no se haya apuntado: quitar una que no está no hace nada)
	StoryFx.clearLight(run.LightId or ("EscenaLuz" .. run.Serial), fade)
	run.LightId = nil
end

local function startWait(run: ClientRun, w: { [string]: any })
	run.Waiting = w
	local ui = run.Ui
	if w.Input and not run.Spectator then
		showInput(run, w)
	end
	if ui and w.Hint then
		ui.Hint.Text = Strings.get(w.Hint, run.Args)
		fadeText(ui.Hint, true, 0.3)
	end
	if w.Control == "Player" and not run.Light and not run.Spectator then
		-- Mandas tú un momento: cámara y controles de vuelta
		run.Free = true
		setControls(true)
		pcall(function()
			require(script.Parent.CineCamera).restore(nil)
		end)
		if ui and ui.Top then
			TweenService:Create(ui.Top, TweenInfo.new(0.4), { Size = UDim2.fromScale(1, 0) }):Play()
			TweenService:Create(ui.Bottom, TweenInfo.new(0.4), { Size = UDim2.fromScale(1, 0) }):Play()
		end
	end
end

local function endWait(run: ClientRun)
	local ui = run.Ui
	if ui then
		if ui.InputCleanup then
			ui.InputCleanup()
			ui.InputCleanup = nil
		end
		fadeText(ui.Hint, false, 0.3)
	end
	if run.Free then
		run.Free = false
		setControls(false)
		if ui and ui.Top then
			TweenService:Create(ui.Top, TweenInfo.new(0.4), { Size = UDim2.fromScale(1, BAR) }):Play()
			TweenService:Create(ui.Bottom, TweenInfo.new(0.4), { Size = UDim2.fromScale(1, BAR) }):Play()
		end
	end
	run.Waiting = nil
end

---------------------------------------------------------------------
-- Reproducir
---------------------------------------------------------------------

-- ¿Hay una escena con cámara en tu pantalla? (los diálogos esperan). Se mira en las escenas vivas, no
-- en un contador: una escena parada, ligera o de espectador no cuenta, y ninguna cuenta pasado su tope
-- (lo más que puede durar con todas sus esperas + 10 s), así nadie se queda esperando para siempre.
function HappeningClient.isPlaying(): boolean
	local now = serverNow()
	for _, run in runs do
		if not run.Stopped and not run.Light and not run.Spectator then
			local ok, limit = pcall(Sequencer.maxDuration, run.Timeline)
			if now < run.StartAt + run.Paused + (if ok then limit else 0) + 10 then
				return true
			end
		end
	end
	return false
end

local function sceneTime(run: ClientRun): number
	local raw = serverNow() - run.StartAt - run.Paused
	if run.Hold and raw >= run.Hold then
		return run.Hold
	end
	return math.max(raw, -1)
end

local function play(payload: { [string]: any })
	local source = HappeningIndex.get(payload.Id)
	if not source or type(payload.Run) ~= "number" then
		return
	end
	-- La misma escena que en el servidor: su variante y sus condiciones ya resueltas
	local okCompile, timeline = pcall(Sequencer.compile, payload.Id, source, {
		Variant = if type(payload.Variant) == "number" then payload.Variant else nil,
		Gates = if type(payload.Gates) == "table" then payload.Gates else nil,
	})
	if not okCompile then
		warn("[HappeningClient] No se pudo preparar la escena " .. tostring(payload.Id) .. ": " .. tostring(timeline))
		tell("Done", payload.Run)
		return
	end
	local def = (timeline :: any).Def or source
	local run: ClientRun = {
		Serial = payload.Run,
		Id = payload.Id,
		Def = def,
		Timeline = timeline,
		StartAt = payload.StartAt or serverNow(),
		Paused = 0,
		Hold = nil,
		ResumedAfter = -1,
		Anchors = payload.Anchors or {},
		Names = payload.Names or {},
		Voices = payload.Voices or {},
		Args = payload.Args or {},
		Light = payload.Light == true,
		Spectator = payload.Spectator == true,
		Inputs = {},
		Cursor = -1,
		Fx = {},
		FxList = {},
		FxPos = {},
		ActorCache = {},
		Impulses = {},
		Stopped = false,
		Skipped = false,
		SkyLayer = nil,
		Waiting = nil,
		Free = false,
		Ui = nil,
		ShotIndex = nil,
		ShotResolve = nil,
		AmbienceOn = false,
		IntensityOn = false,
		LightId = nil,
		Died = false,
	}
	-- La Grieta: donde la ve tu pantalla ahora
	for name, anchor in def.Anchors or {} do
		if anchor == "Rift" then
			local ok, p = pcall(function()
				return require(script.Parent.SkyRift).worldPoint()
			end)
			if ok and p then
				run.Anchors[name] = CFrame.new(p)
			end
		end
	end
	runs[run.Serial] = run
	local cinematic = not run.Light and not run.Spectator
	local camera = workspace.CurrentCamera
	local previousFov = camera.FieldOfView
	local previousCFrame = camera.CFrame
	local restoreGuis: (() -> ())? = nil
	local audio: any = nil
	pcall(function()
		audio = require(script.Parent.StoryAudio)
	end)
	if not run.Spectator then
		run.Ui = buildUi(run)
	end
	if cinematic then
		onScreen += 1
		restoreGuis = hideOtherGuis(run.Ui.Gui)
		setControls(false)
		player:SetAttribute("InCinematic", true)
		pcall(function()
			require(script.Parent.CineCamera).quietLabels("Escena", true)
			require(script.Parent.DayLight).setCinematic(true)
		end)
		if audio then
			pcall(audio.cinematicStart, def.Music)
			pcall(audio.sting, def.Sting)
		end
		if def.Intensity then
			applyIntensity(run, def.Intensity)
		end
		StoryFx.setShakeSink(function(strength, seconds)
			table.insert(run.Impulses, { At = sceneTime(run), Strength = strength, Seconds = seconds })
		end)
	end
	local resolve = CameraShots.composite(resolver(run))
	local clockStart = os.clock()
	local endLimit = run.Timeline.Duration
		+ 1.5
		+ (if type(def.Until) == "table" then Sequencer.untilTimeout(def.Until) + 3 else 0)
	local ok, err = pcall(function()
		while not run.Stopped do
			local t = sceneTime(run)
			-- ¿Llega una espera? La escena se para ahí hasta que el servidor diga
			if not run.Hold then
				local w = Sequencer.nextWait(run.Timeline, run.ResumedAfter)
				if w and t >= w.At then
					run.Hold = w.At
					t = w.At
				end
			end
			-- Sucesos de cliente que tocan
			if t > run.Cursor then
				for _, e in Sequencer.due(run.Timeline, run.Cursor, t, "Client") do
					local d = e.Data
					if not Sequencer.passes(d, run.Inputs) then
						continue
					end
					local track = e.Track
					if run.Spectator and track ~= "Fx" and track ~= "Sound" then
						continue
					end
					if track == "Fx" then
						local index = table.find((def.Tracks or {}).Fx or {}, d) or 0
						playFx(run, d, index)
					elseif track == "Lines" or track == "Dialogue" then
						showLine(run, d)
					elseif track == "Ambience" then
						applyAmbience(run, d)
					elseif track == "Light" then
						applyLight(run, d)
					elseif track == "Titles" then
						showTitle(run, d)
					elseif track == "Sky" then
						applySky(run, d)
					elseif track == "Sound" then
						playSound(run, d)
					elseif track == "Music" then
						if d.Intensity ~= nil then
							applyIntensity(run, d.Intensity, d.Fade)
						elseif audio and d.Play then
							pcall(audio.cinematicStart, d.Play)
							-- (una escena sin pantalla de cine también la cierra al acabar: si no, la
							-- música de fondo no volvía nunca)
							run.MusicPlayed = true
						end
					elseif track == "Fade" then
						applyFade(run, d)
					elseif track == "Wait" then
						if run.Hold == e.At and not run.Waiting then
							startWait(run, d)
						end
					end
				end
				run.Cursor = t
			end
			-- Cámara
			if cinematic and not run.Free then
				-- (los planos con If/IfNot = { Input } solo si pasan: la alternativa de una frase)
				local shots = run.Timeline.Shots
				local filtered = shots
				for _, candidate in shots do
					if candidate.If ~= nil or candidate.IfNot ~= nil then
						filtered = {}
						for _, s in shots do
							if Sequencer.passes(s, run.Inputs) then
								table.insert(filtered, s)
							end
						end
						break
					end
				end
				local shot, u = CameraShots.active(filtered, t)
				if shot then
					camera.CameraType = Enum.CameraType.Scriptable
					if shot ~= run.ShotIndex then
						run.ShotIndex = shot
						-- Plano con Lock (los planos con nombre): las anclas se quedan donde estaban al empezar
						run.ShotResolve = if shot.Lock
							then CameraShots.composite(CameraShots.locked(resolver(run), function(name: string): boolean
								local kind, value = name:match("^(%a+):(.+)$")
								return kind ~= "Actor" or actorModel(value) ~= nil
							end))
							else nil
						local cut = shot.Cut
						local ui = run.Ui
						if ui and (cut == "Dip" or cut == "Fade") then
							ui.Black.BackgroundTransparency = 0
							TweenService:Create(ui.Black, TweenInfo.new(if cut == "Fade" then 0.9 else 0.4), { BackgroundTransparency = 1 }):Play()
						elseif cut == "Flash" then
							StoryFx.flash(0.75, Color3.new(1, 1, 1), 0.45)
						end
					end
					local impulse = math.max(CameraShots.impulse(run.Timeline.Shakes, t), CameraShots.impulse(run.Impulses, t))
					local shotResolve = run.ShotResolve or resolve
					local cf = CameraShots.cframe(shot, u, shotResolve, os.clock() - clockStart, impulse)
					if cf then
						camera.CFrame = cf
						local focus = CameraShots.point(shotResolve, shot.Look)
							or (if shot.Orbit then (resolve(shot.Orbit) :: any) and resolve(shot.Orbit).Position else nil)
						pcall(function()
							require(script.Parent.DayLight).setFocus(if focus then (focus - cf.Position).Magnitude else nil)
						end)
					end
					camera.FieldOfView = CameraShots.fov(shot, u) or previousFov
				end
			end
			-- Fin (si el servidor tarda en decir Stop, se espera un poco y se acaba igual)
			-- (con Until el servidor la deja parada en el último plano hasta el aviso: aquí solo un tope)
			if not run.Hold and t >= endLimit then
				break
			end
			if run.Def.FadeOut and run.Def.Until == nil and run.Ui and not run.Ui.FadingOut and t >= run.Timeline.Duration - 1.1 then
				run.Ui.FadingOut = true
				TweenService:Create(run.Ui.Black, TweenInfo.new(1), { BackgroundTransparency = 0 }):Play()
			end
			RunService.RenderStepped:Wait()
		end
	end)
	if not ok then
		warn("[HappeningClient] La escena falló; se devuelve el control: " .. tostring(err))
	end
	-- Recoger (ambiente, música y luz primero y por separado: si algo falla, se deshacen igual)
	pcall(undoMood, run, if run.Died then 0.3 else 1.5)
	if not cinematic and run.MusicPlayed and audio then
		pcall(audio.cinematicEnd)
	end
	pcall(endWait, run)
	for _, handle in run.FxList do
		StoryFx.stop(handle) -- (el portal se cierra, el orbe se apaga…)
	end
	if run.SkyLayer then
		pcall(function()
			require(script.Parent.DayLight).popLayer(run.SkyLayer :: string, 1.5)
		end)
	end
	if cinematic then
		StoryFx.setShakeSink(nil)
		pcall(function()
			require(script.Parent.StoryAudio).stopVoice()
		end)
		local ui = run.Ui
		if ui then
			TweenService:Create(ui.Black, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
			task.wait(0.35)
		end
		camera.FieldOfView = previousFov
		pcall(function()
			require(script.Parent.DayLight).setFocus(nil)
			require(script.Parent.DayLight).setCinematic(false)
			require(script.Parent.CineCamera).restore(previousCFrame)
			require(script.Parent.CineCamera).quietLabels("Escena", false)
		end)
		if restoreGuis then
			restoreGuis()
		end
		setControls(true)
		if audio then
			pcall(audio.cinematicEnd)
		end
		onScreen = math.max(0, onScreen - 1)
		local stillCine = false
		pcall(function()
			stillCine = require(script.Parent.Cinematics).isOnScreen()
		end)
		if onScreen == 0 and not stillCine then
			player:SetAttribute("InCinematic", nil)
		end
		if ui then
			if ui.Top then
				TweenService:Create(ui.Top, TweenInfo.new(0.5), { Size = UDim2.fromScale(1, 0) }):Play()
				TweenService:Create(ui.Bottom, TweenInfo.new(0.5), { Size = UDim2.fromScale(1, 0) }):Play()
			end
			TweenService:Create(ui.Black, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
		end
	end
	if run.Ui then
		local gui = run.Ui.Gui
		task.delay(0.8, function()
			gui:Destroy()
		end)
	end
	runs[run.Serial] = nil
	if not run.Spectator then
		tell("Done", run.Serial)
	end
end

function HappeningClient.init()
	pcall(function()
		require(script.Parent.ActorLife).setLookResolver(lookPoint)
	end)
	-- Al morir: la escena se acaba ya en tu pantalla (y el servidor la da por saltada). Ambiente, música
	-- y luz se quitan en el acto; la cámara y los controles, en la recogida de play.
	local function hookDeath(character: Model)
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 15)
			if humanoid and humanoid:IsA("Humanoid") then
				(humanoid :: Humanoid).Died:Connect(function()
					for _, run in runs do
						run.Died = true
						run.Stopped = true
						pcall(undoMood, run, 0.3)
					end
				end)
			end
		end)
	end
	if player.Character then
		hookDeath(player.Character)
	end
	player.CharacterAdded:Connect(hookDeath)
	-- Hora de la historia solo en tu pantalla (atributo StoryClock que pone LifeStoryService cuando hay más
	-- jugadores: «esa noche…»): la luz de esa hora como capa de DayLight, con fundido; se quita al
	-- borrarse el atributo. (Lighting.ClockTime no se toca: es del servidor.)
	local function applyStoryClock()
		local hour = player:GetAttribute("StoryClock")
		pcall(function()
			local DayLight = require(script.Parent.DayLight) :: any
			if type(hour) == "number" then
				local key = DayLight.sample(hour % 24)
				if type(key) == "table" then
					DayLight.pushLayer("StoryClock", key, 2.5)
				end
			else
				DayLight.popLayer("StoryClock", 2.5)
			end
		end)
	end
	player:GetAttributeChangedSignal("StoryClock"):Connect(applyStoryClock)
	applyStoryClock()
	-- Y lo que avisa SceneClient (muerte, reaparecer, teletransporte): la escena se acaba y se devuelve todo
	pcall(function()
		local SceneClient = require(script.Parent.SceneClient) :: any
		if type(SceneClient.onInterrupt) == "function" then
			SceneClient.onInterrupt(function(reason)
				for _, run in runs do
					-- (un portal de la propia escena te teletransporta a propósito, mientras mandas tú)
					if not run.Spectator and not (reason == "Teletransporte" and run.Free) then
						run.Died = reason == "Muerte" or run.Died
						run.Stopped = true
						pcall(undoMood, run, 0.3)
					end
				end
			end)
		end
	end)
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
	local found = remotes and remotes:WaitForChild("Happening", 30)
	if not found then
		return
	end
	remote = found :: RemoteEvent
	;(remote :: RemoteEvent).OnClientEvent:Connect(function(kind, payload)
		if type(payload) ~= "table" then
			return
		end
		local run = runs[payload.Run]
		if kind == "Play" then
			task.spawn(play, payload)
		elseif kind == "Pause" and run then
			run.Hold = payload.At
		elseif kind == "Resume" and run then
			run.Paused = payload.Paused or run.Paused
			run.Inputs = payload.Inputs or run.Inputs
			run.ResumedAfter = run.Hold or run.ResumedAfter
			run.Hold = nil
			endWait(run)
		elseif kind == "Stop" and run then
			run.Stopped = true
			run.Skipped = payload.Skipped == true or run.Skipped
		end
	end)
end

return HappeningClient
