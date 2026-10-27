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
-- Tiempo de lectura (shared/LifeStory/ReadingTime): cada subtítulo (y su bocadillo) se queda al menos
-- lo que se tarda en leerlo; si el siguiente llega antes, espera a que se haya leído.
-- Tocar para seguir (escenas de CONVERSACIÓN, Sequencer.canAdvance): un toque (en una escena ligera,
-- en el subtítulo) pasa a la frase siguiente; el servidor adelanta el reloj de la escena. En las de
-- acción no: van sincronizadas con la línea de tiempo (allí el Sequencer las estira para leer).
-- Fase 7 (alcance de la escena, HappeningService): si eres ESPECTADOR (estás cerca de un acontecimiento
-- del mundo de otro: Scope = "World") ves lo que pasa en el mundo (efectos, sonido, cielo) sin perder la
-- cámara ni el control. Si PARTICIPAS (Scope = "Group": la misma escena, en el mismo paso, cerca) la ves
-- entera con tu cámara, con sus actores y sin esconder a quien la vive contigo; las esperas y los
-- toques los decide quien la empezó; «Saltar» solo te saca a ti.
-- La escena llega ya resuelta del servidor (variante y condiciones: Variant, Gates) y se expande igual
-- que allí (Sequencer.compile): los dos ven lo mismo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local HappeningIndex = require(ReplicatedStorage.Shared.LifeStory.HappeningIndex)
local Sequencer = require(ReplicatedStorage.Shared.LifeStory.Sequencer)
local CameraShots = require(ReplicatedStorage.Shared.CameraShots)
local ActorMoods = require(ReplicatedStorage.Shared.LifeStory.ActorMoods)
local Emotion = require(ReplicatedStorage.Shared.LifeStory.Emotion)
local SkyMoods = require(ReplicatedStorage.Shared.SkyMoods)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local SceneDirector = require(ReplicatedStorage.Shared.LifeStory.SceneDirector)
local StageDirector = require(ReplicatedStorage.Shared.LifeStory.StageDirector)
local ReadingTime = require(ReplicatedStorage.Shared.LifeStory.ReadingTime)
local Theme = require(script.Parent.Parent.UI.Theme)
local SceneGuis = require(script.Parent.Parent.UI.SceneGuis)
local SceneChain = require(script.Parent.Parent.UI.SceneChain)
local StoryFx = require(script.Parent.StoryFx)
local CineCamera = require(script.Parent.CineCamera)
local SceneReport = require(script.Parent.SceneReport)

local HappeningClient = {}

local player = Players.LocalPlayer
local BAR = 0.11
-- (el rótulo: en el tercio de abajo, encima de la banda negra de los subtítulos, sobre su banda oscura)
local TITLE_Y = 0.7
local TITLE_BAND = 0.24
local TITLE_BAND_DARK = 0.35

type ClientRun = {
	Serial: number,
	Id: string,
	Def: { [string]: any },
	Timeline: Sequencer.Timeline,
	StartAt: number,
	Paused: number,
	Late: number?, -- segundos que esperó a que acabara otra escena de cámara antes de empezar
	Hold: number?, -- segundo de la escena en el que está parada (espera)
	ResumedAfter: number, -- la última espera ya superada
	Anchors: { [string]: CFrame },
	Names: { [string]: string },
	Voices: { [string]: string },
	PrefetchedTo: number?, -- (hasta qué segundo de la escena ya se han adelantado las voces)
	Args: { [string]: any },
	Light: boolean,
	Scaled: { [any]: any }?, -- (cada plano a la medida de quien sale: CameraShots.scaleShot)
	Spectator: boolean,
	Participant: boolean?,
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
	FitShot: { [string]: any }?, -- (CameraShots.fit) el plano del que es FitChoice
	FitChoice: number?, -- el giro elegido al empezar ese plano
	StillShot: { [string]: any }?, -- (CameraShots.travelBlocked) el plano del que es Still
	Still: boolean?, -- ese travelling atravesaría algo: se queda quieto en su final
	AmbienceOn: boolean,
	IntensityOn: boolean,
	MusicPlayed: boolean?, -- (escena sin cine que pidió una pieza con Play: al acabar se cierra)
	LightId: string?,
	Died: boolean,
	CanAdvance: boolean, -- conversación: un toque pasa a la frase siguiente
	CaptionHold: ReadingTime.Hold, -- hasta cuándo se está leyendo el subtítulo de ahora
	LineSerial: number, -- cuántas frases han salido ya en pantalla
	LineShownAt: number, -- os.clock() de la última frase en pantalla
	Pending: { () -> () }, -- frases que esperan a que se lea la anterior, en orden (un toque saca la primera)
	-- Rótulo primero, frase después; cada frase en su sitio (shared/LifeStory/SceneTiming)
	TitleUntil: number?, -- os.clock() hasta el que hay un rótulo en pantalla (las frases esperan)
	CaptionLocated: boolean?, -- el subtítulo en pantalla es de un personaje (no del narrador)
	PendingLocated: { [any]: boolean }?, -- frases de personaje que esperan turno
	-- Fase 3 (fallos): desde cuándo está parada en una espera y su tope; pasos fallidos; cortada por fallos
	HoldSince: number?,
	HoldLimit: number?,
	StepFailures: number?,
	Aborted: boolean?,
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

-- Las cabezas (en el mundo) de unos nombres de un plano con nombre
local function headsOf(run: ClientRun, names: { string }, resolve: CameraShots.Resolver): { Vector3 }
	local list = {}
	for _, name in names do
		local ref = if name == "Yo" or name == "Player" then "Player" elseif (run.Def.Anchors or {})[name] then name else "Actor:" .. name
		local cf = resolve(ref)
		if cf then
			table.insert(list, cf.Position + Vector3.new(0, 1.5, 0))
		end
	end
	return list
end

-- Las cabezas de todos los de la escena (tú y sus actores): CameraShots.fit no deja la cámara en la
-- sala de al lado, con una pared entre ella y todos
local function crowdOf(run: ClientRun, resolve: CameraShots.Resolver): { Vector3 }
	local names, seen = { "Player" }, {}
	for _, d in ((run.Def.Tracks or {}).Actors or {}) :: { any } do
		local spec = if type(d) == "table" then (d.Spawn or d.Enter or d.Use) else nil
		if type(spec) == "table" and type(spec.Key) == "string" and not seen[spec.Key] then
			seen[spec.Key] = true
			table.insert(names, "Actor:" .. spec.Key)
		end
	end
	local list = {}
	for _, name in names do
		local ok, cf = pcall(resolve, name)
		if ok and cf then
			table.insert(list, cf.Position + Vector3.new(0, 1.5, 0))
		end
	end
	return list
end

-- Lo alto que es alguien comparado con un adulto (de los pies a la cabeza; 1 = adulto), o nil
local function sizeOf(model: Instance?): number?
	if not model or not model:IsA("Model") then
		return nil
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not head or not humanoid or not root then
		return nil
	end
	local feet = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
	return math.clamp((head.Position.Y - feet) / 4.5, 0.3, 1.5)
end

-- Lo que CameraShots.fit tiene que respetar en un plano con nombre: las caras que tienen que verse
-- (Keep) y la pareja del plano (Line: la regla de los 180°)
local function fitOptions(run: ClientRun, shot: { [string]: any }, resolve: CameraShots.Resolver): { [string]: any }
	if type(shot.Shot) ~= "string" then
		return { Crowd = crowdOf(run, resolve), Fov = if type(shot.Fov) == "number" then shot.Fov elseif type(shot.Fov) == "table" then shot.Fov[#shot.Fov] else nil }
	end
	local pair = CameraShots.pair(shot.Shot)
	local line = if pair then headsOf(run, pair, resolve) else nil
	-- (quien sale: hacia dónde mira, para no ponerle la cámara en la nuca; y lo más cerca que puede
	-- quedar la cámara de su cara con este campo de visión)
	local front = nil
	local subject = CameraShots.subjects(shot.Shot)[1]
	if subject then
		local ref = if subject == "Yo" or subject == "Player" then "Player" elseif (run.Def.Anchors or {})[subject] then nil else "Actor:" .. subject
		local ok, cf = pcall(function()
			return if ref then resolve(ref) else nil
		end)
		if ok and cf then
			front = cf.LookVector
		end
	end
	local fov = if type(shot.Fov) == "number" then shot.Fov elseif type(shot.Fov) == "table" then shot.Fov[#shot.Fov] else nil
	return {
		Keep = headsOf(run, CameraShots.subjects(shot.Shot), resolve),
		Line = if line and #line == 2 then line else nil,
		Crowd = crowdOf(run, resolve),
		Front = front,
		Min = CameraShots.minDistance(shot.Shot, fov),
		Fov = fov,
	}
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
-- La interfaz fuera mientras dura la escena (de Roblox, solo la mochila) y al acabar como estaba:
-- UI/SceneGuis (con otra escena aún en marcha no se enciende nada; lo que se cerró durante la escena
-- no vuelve)
local function hideOtherGuis(except: ScreenGui): () -> ()
	return SceneGuis.hide(except, { Skip = { StoryFlash = true } })
end

local function fadeText(label: TextLabel, visible: boolean, seconds: number)
	TweenService:Create(label, TweenInfo.new(seconds), {
		TextTransparency = if visible then 0 else 1,
		TextStrokeTransparency = if visible then 0.6 else 1,
	}):Play()
end

local advance: (ClientRun) -> () -- (tocar para seguir: más abajo, junto a showLine)
local cutToElsewhere: (ClientRun) -> () -- (corte a otro sitio: más abajo, junto a showLine)

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
		-- (en la banda, pegado abajo: si crece por encima de ella, crece hacia arriba y no se sale)
		AnchorPoint = if run.Light then Vector2.new(0.5, 0.5) else Vector2.new(0.5, 1),
		Position = if run.Light then UDim2.new(0.5, 0, 0.84, 0) else UDim2.new(0.5, 0, 1, -4),
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
	-- (en un móvil apaisado la banda deja ~33 px: el subtítulo puede crecer un poco por encima de ella
	-- para que una frase larga quepa en 2 líneas legibles; shared/LifeStory/DialogueLook.captionFits, H3)
	Theme.create("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 13, Parent = ui.Caption })
	Theme.create("UISizeConstraint", { MinSize = Vector2.new(0, 44), Parent = ui.Caption })
	-- El rótulo y su subtítulo van en columna (como en Controllers/Cinematics): si el rótulo ocupa dos
	-- líneas (en el móvil, «Pasan los años… y llega el instituto.»), el subtítulo baja en vez de quedar
	-- encima. Antes iban a alturas fijas (0.44 y 0.52) con el rótulo en una caja de 50 px.
	-- El rótulo, en el tercio de abajo y sobre una BANDA OSCURA (v125.5: «El mar» salía en medio de la
	-- pantalla, encima de la cara de Abu). La banda se funde por los lados y solo se ve con el rótulo.
	ui.TitleBand = Theme.create("Frame", {
		Name = "TitleBand",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, TITLE_Y),
		Size = UDim2.fromScale(1, TITLE_BAND),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = gui,
	})
	Theme.create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.18, 0),
			NumberSequenceKeypoint.new(0.82, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = ui.TitleBand,
	})
	local titleBlock = Theme.create("Frame", {
		Name = "TitleBlock",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, TITLE_Y),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = gui,
	})
	Theme.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = titleBlock,
	})
	ui.TitleBlock = titleBlock
	ui.Title = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Text = "",
		Font = Theme.FontBold,
		TextSize = if (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 900) then 30 else 42,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = titleBlock,
	})
	ui.Sub = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Text = "",
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.Colors.Gold,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = titleBlock,
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
	if run.CanAdvance then
		-- Tocar para seguir: «Toca para seguir »» junto al subtítulo; en una escena ligera (sigues
		-- jugando) solo cuenta tocar el subtítulo, para no quitarte el control de la cámara
		ui.TapHint = Theme.label({
			AnchorPoint = if run.Light then Vector2.new(0.5, 0) else Vector2.new(1, 1),
			Position = if run.Light then UDim2.new(0.5, 0, 0.84 + BAR / 2, -2) else UDim2.new(0.97, 0, 1 - BAR, -4),
			Size = UDim2.fromOffset(170, 16),
			Text = if run.Light
				then (if UserInputService.TouchEnabled then "Toca el texto para seguir »" else "Clic en el texto para seguir »")
				else (if UserInputService.TouchEnabled then "Toca para seguir »" else "Clic o Espacio »"),
			TextSize = 13,
			TextXAlignment = if run.Light then Enum.TextXAlignment.Center else Enum.TextXAlignment.Right,
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			ZIndex = 6,
			Parent = gui,
		})
		if run.Light then
			-- (solo el centro: a los lados están el joystick y el botón de saltar del móvil)
			ui.CaptionTap = Theme.create("TextButton", {
				Name = "CaptionTap",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.84, 0),
				Size = UDim2.new(0.36, 0, BAR, 12),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Visible = false,
				ZIndex = 8,
				Parent = gui,
			})
			ui.CaptionTap.Activated:Connect(function()
				advance(run)
			end)
		end
	end
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
		OnEnter = if params and params.Teleport and not run.Spectator and not run.Participant
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

-- Quién dice una frase de la escena y qué dice (el texto que se ve y se oye).
-- La acotación del principio («(susurrando) …», «(se ríe) …») se convierte en acción, como en las
-- conversaciones (StageDirector): sale del texto y, si era la línea entera, queda como subtítulo en
-- cursiva sin bocadillo ni voz. Las del narrador son su forma de contar: se quedan.
local function lineText(run: ClientRun, line: { [string]: any }): (string?, string, { [string]: any }?)
	local who = line.Speaker or line.S
	local text = Strings.get(line.Text or line.T or "", run.Args)
	local direction = nil
	if who ~= nil and who ~= "Narrador" then
		local ok, clean, d = pcall(StageDirector.direction, text)
		if ok and d then
			text, direction = clean, d
		end
	end
	return who, text, direction
end

-- Las voces de las frases de los próximos segundos se generan ya (StoryAudio.prefetch): así suenan a la
-- vez que su subtítulo
local function prefetchVoices(run: ClientRun, t: number)
	local lookahead = require(ReplicatedStorage.Shared.Config).Audio.Voices.Lookahead or 10
	local from = math.max(run.PrefetchedTo or -1, t)
	if run.Spectator or from > t + lookahead * 0.5 then
		return
	end
	local to = t + lookahead
	run.PrefetchedTo = to
	local list = {}
	for _, e in Sequencer.due(run.Timeline, from, to, "Client") do
		if (e.Track == "Lines" or e.Track == "Dialogue") and Sequencer.passes(e.Data, run.Inputs) then
			local who, text, direction = lineText(run, e.Data)
			local voice = run.Voices[who or ""]
			if voice and who ~= "Yo" and not (direction and direction.Whole) then
				table.insert(list, { Role = voice, Text = text })
			end
		end
	end
	if #list > 0 then
		pcall(function()
			require(script.Parent.StoryAudio).prefetch(list)
		end)
	end
end

local function showLine(run: ClientRun, line: { [string]: any })
	local ui = run.Ui
	local who, text, direction = lineText(run, line)
	local whole = direction ~= nil and direction.Whole == true
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
	-- Cuánto se queda: lo que dice la escena, pero nunca menos de lo que se tarda en leerla
	local seconds = math.max(tonumber(line.Duration) or 0, ReadingTime.seconds(text))
	local now = os.clock()
	-- Rótulo primero, frase después: con un rótulo grande en pantalla, la frase espera a que se vaya
	-- (antes salían a la vez: «La cocina, la tele…» encima de la frase de Abu)
	if run.TitleUntil and run.TitleUntil > now then
		run.CaptionHold.FreeAt = math.max(run.CaptionHold.FreeAt, run.TitleUntil)
	end
	local located = who ~= nil and who ~= "Narrador"
	local showAt, hideAt = ReadingTime.schedule(run.CaptionHold, now, seconds)
	seconds = hideAt - showAt
	local function display()
		if run.Stopped then
			return
		end
		run.LineSerial += 1
		run.LineShownAt = os.clock()
		run.CaptionLocated = located
		local shownUi = run.Ui
		if shownUi then
			local shown = if whole then ("<i>%s</i>"):format(text) else text
			shownUi.Caption.Text = if name and name ~= "" and not whole then ('<font color="#FFC43C"><b>%s:</b></font> %s'):format(name, shown) else shown
			fadeText(shownUi.Caption, true, 0.25)
			if shownUi.TapHint then
				fadeText(shownUi.TapHint, true, 0.25)
			end
			if shownUi.CaptionTap then
				shownUi.CaptionTap.Visible = true
			end
			shownUi.CaptionToken = (shownUi.CaptionToken or 0) + 1
			local token = shownUi.CaptionToken
			task.delay(seconds, function()
				if run.Ui and run.Ui.CaptionToken == token then
					fadeText(run.Ui.Caption, false, 0.35)
					if run.Ui.TapHint then
						fadeText(run.Ui.TapHint, false, 0.35)
					end
					if run.Ui.CaptionTap then
						run.Ui.CaptionTap.Visible = false
					end
				end
			end)
		end
		local voice = run.Voices[who or ""]
		if voice and not whole then
			pcall(function()
				require(script.Parent.StoryAudio).speak(voice, text, nil, { Seconds = seconds }) -- (mientras se ve)
			end)
		end
		if model then
			local mood = ActorMoods.get(line.Mood)
			local emotion = line.A or (mood and mood.Pose) or (direction and direction.Gesture) or Emotion.of({ S = who, T = text }, text)
			pcall(function()
				require(script.Parent.ActorLife).speak(model, emotion, seconds, line.G)
			end)
			-- (con cámara de cine el texto va en el subtítulo de abajo: el bocadillo lo repetía y, con la
			-- cabeza cerca del borde de arriba, quedaba cortado bajo la franja negra. Solo en las escenas
			-- ligeras, sin cámara, donde es el único texto)
			if line.Bubble ~= false and not whole and run.Light then
				-- (el bocadillo dura lo mismo que el subtítulo que acompaña)
				pcall(function()
					require(script.Parent.Parent.UI.SpeechBubbles).show(model, text, { Name = name, Seconds = seconds, Story = true })
				end)
			end
		end
	end
	if showAt <= now + 0.01 then
		display()
	else
		-- La anterior aún se está leyendo: esta espera su turno (se queda en pantalla dentro del plano
		-- siguiente). Un toque, si la escena lo deja, la saca ya.
		table.insert(run.Pending, display)
		if located then
			run.PendingLocated = run.PendingLocated or {}
			;(run.PendingLocated :: any)[display] = true
		end
		task.delay(showAt - now, function()
			local index = table.find(run.Pending, display)
			if index then
				table.remove(run.Pending, index)
				display()
			end
		end)
	end
end

-- Corte a otro sitio (un plano que entra con Dip o Fade): la frase de un personaje que aún se veía
-- (o que esperaba turno) no pasa al plano nuevo, ni su voz. La del narrador sí sigue (no es de ningún
-- sitio). Antes la frase de Lucía en la puerta del colegio salía encima del plano de tu casa.
cutToElsewhere = function(run: ClientRun)
	local waiting = run.PendingLocated
	if waiting then
		for i = #run.Pending, 1, -1 do
			if waiting[run.Pending[i]] then
				table.remove(run.Pending, i)
			end
		end
		table.clear(waiting)
	end
	if not run.CaptionLocated then
		return
	end
	run.CaptionLocated = false
	ReadingTime.release(run.CaptionHold)
	local ui = run.Ui
	if ui then
		ui.CaptionToken = (ui.CaptionToken or 0) + 1
		fadeText(ui.Caption, false, 0.2)
		if ui.TapHint then
			fadeText(ui.TapHint, false, 0.2)
		end
		if ui.CaptionTap then
			ui.CaptionTap.Visible = false
		end
	end
	pcall(function()
		require(script.Parent.StoryAudio).stopVoice()
	end)
end

-- Tocar para seguir: si una frase espera a que se lea la anterior, sale ya; si no, el servidor salta a
-- la siguiente (Sequencer.advanceTarget). Un toque recién salida la frase no cuenta (doble toque).
advance = function(run: ClientRun)
	if not run.CanAdvance or run.Stopped or run.Skipped or run.Hold or run.Spectator or run.Participant then
		return
	end
	if os.clock() - run.LineShownAt < ReadingTime.TAP_GUARD then
		return
	end
	ReadingTime.release(run.CaptionHold)
	if #run.Pending > 0 then
		local first = table.remove(run.Pending, 1) :: () -> ()
		first()
		return
	end
	run.LineShownAt = os.clock() -- (hasta que llegue la siguiente, otro toque no vuelve a pedirlo)
	tell("Advance", run.Serial)
end

-- Pista Acting: un gesto en TU pantalla (como las cinemáticas de siempre): "Yo" = tu personaje,
-- "Todos" = tú y la gente de tu escena (ActorLife.cast), o alguien de la escena por su clave
local function playActing(run: ClientRun, d: { [string]: any })
	local ActorLife = require(script.Parent.ActorLife)
	local who = d.Who
	local models: { Model } = {}
	if who == "Yo" or who == "Player" then
		if player.Character then
			table.insert(models, player.Character)
		end
	elseif who == "Todos" then
		local okCast, list = pcall(ActorLife.cast)
		for _, model in (if okCast and type(list) == "table" then list else {}) do
			table.insert(models, model)
		end
		if player.Character and not table.find(models, player.Character) then
			table.insert(models, player.Character)
		end
	elseif type(who) == "string" then
		local model = actorModel(who)
		if not model then
			pcall(function()
				model = ActorLife.find(who)
			end)
		end
		if model then
			table.insert(models, model)
		end
	end
	for _, model in models do
		pcall(ActorLife.play, model, d.Play, d.Duration)
	end
end

-- Hasta cuándo hay un rótulo de escena en pantalla (DialogueUI no abre una conversación encima)
local titleUntil = 0
function HappeningClient.titleOnScreen(): boolean
	return os.clock() < titleUntil
end

local function showTitle(run: ClientRun, d: { [string]: any })
	local ui = run.Ui
	local text = Strings.get(d.Text or "", run.Args)
	-- (el mismo rótulo que ya está poniendo la historia —«Por la tarde…»— no se repite encima, y nunca
	-- encima de una conversación abierta)
	local same = false
	pcall(function()
		same = require(script.Parent.LifeStory).screenShowing(text)
	end)
	if not ui or same or player:GetAttribute("InDialogue") == true then
		return
	end
	titleUntil = os.clock() + (d.Duration or 3) + 0.6
	run.TitleUntil = titleUntil
	ui.Title.Text = text
	ui.Sub.Text = if d.Sub then Strings.get(d.Sub, run.Args) else ""
	fadeText(ui.Title, true, 0.6)
	fadeText(ui.Sub, true, 0.6)
	if ui.TitleBand then
		TweenService:Create(ui.TitleBand, TweenInfo.new(0.6), { BackgroundTransparency = TITLE_BAND_DARK }):Play()
	end
	ui.TitleToken = (ui.TitleToken or 0) + 1
	local token = ui.TitleToken
	task.delay(d.Duration or 3, function()
		if run.Ui and run.Ui.TitleToken == token then
			fadeText(run.Ui.Title, false, 0.6)
			fadeText(run.Ui.Sub, false, 0.6)
			if run.Ui.TitleBand then
				TweenService:Create(run.Ui.TitleBand, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			end
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
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 25
		sound.RollOffMaxDistance = 700
		pcall(function() -- (los efectos de las escenas: control 🔔 Efectos)
			sound.SoundGroup = require(script.Parent.SoundFx).group("SFX")
		end)
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

-- Luz de relleno de noche (SceneDirector.KeyLight): una luz que va con la cámara, arriba y a un lado,
-- para que de noche las caras no sean siluetas negras. Solo en tu pantalla; se quita con undoMood.
local function stopKeyLight(run: ClientRun)
	local r: any = run
	local key = r.KeyLight
	if key then
		r.KeyLight = nil
		pcall(function()
			key.Conn:Disconnect()
		end)
		pcall(function()
			key.Part:Destroy()
		end)
	end
end

local function startKeyLight(run: ClientRun)
	stopKeyLight(run)
	local part = Instance.new("Part")
	part.Name = "LuzRelleno"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	local light = Instance.new("PointLight")
	light.Brightness = SceneDirector.KEY.Brightness
	light.Range = SceneDirector.KEY.Range
	light.Color = SceneDirector.KEY.Color
	light.Shadows = false
	light.Parent = part
	local camera = workspace.CurrentCamera
	part.CFrame = camera.CFrame * CFrame.new(SceneDirector.KEY_OFFSET)
	part.Parent = camera
	local conn = RunService.RenderStepped:Connect(function()
		part.CFrame = camera.CFrame * CFrame.new(SceneDirector.KEY_OFFSET)
	end)
	local r: any = run
	r.KeyLight = { Part = part, Conn = conn }
end

-- Deshace ambiente, intensidad y luz de esta escena (siempre: final, salto, muerte, fallo)
local function undoMood(run: ClientRun, fade: number?)
	stopKeyLight(run)
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
	if w.Input and not run.Spectator and not run.Participant then
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

-- Fase 6 (un solo motor): las cinemáticas de siempre (cabeceras de capítulo, fotos…) son ya escenas de
-- este motor (Happenings/Capitulos) y, si llegan mientras hay otra con cámara, ESPERAN SU TURNO EN EL
-- SERVIDOR (HappeningService, Queue / AfterScene). Antes esta pantalla esperaba a la cinemática vieja
-- (WAIT_CINEMATIC); ya no hay a quién esperar: la escena empieza a la hora que dice el servidor.
SceneChain.addScreen(function()
	return onScreen > 0
end)
-- Cuántas de las escenas en pantalla son de las de siempre (Legacy): lo pregunta el puente de
-- compatibilidad Controllers/Cinematics (isOnScreen), que usan la caja de diálogo, el prólogo, la
-- cámara a pie… igual que antes
local legacyOnScreen = 0
local lastRun: { [string]: any }? = nil
-- La última escena que se vio en esta pantalla: { Id, Shot, Shots, T, Duration, Skipped } (Cinemateca)
function HappeningClient.lastRun(): { [string]: any }?
	return lastRun
end
-- La escena con cámara que se ve AHORA: { Id, Shot, Shots, T } (Cinemateca: comentar a mitad)
function HappeningClient.nowRun(): { [string]: any }?
	for _, run in runs do
		if not run.Stopped and not run.Light and not run.Spectator then
			return {
				Id = run.Id,
				Shot = (run :: any).ShotNumber,
				Shots = #run.Timeline.Shots,
				T = math.floor(sceneTime(run) * 10 + 0.5) / 10,
			}
		end
	end
	return nil
end
function HappeningClient.legacyOnScreen(): boolean
	return legacyOnScreen > 0
end
-- Salta las escenas de las de siempre que estén en pantalla (como el botón «Saltar»): el puente
-- Controllers/Cinematics.interrupt
function HappeningClient.skipLegacy(): boolean
	local any = false
	for _, run in runs do
		if run.Def and run.Def.Legacy == true and not run.Skipped and not run.Stopped and run.Def.Skippable ~= false then
			run.Skipped = true
			tell("Skip", run.Serial)
			any = true
		end
	end
	return any
end
-- Fase 3: pasos que pueden fallar antes de cortar la escena (la cámara que falla en cada fotograma) y
-- margen del vigilante de cada espera sobre su tope
HappeningClient.MaxStepFailures = 4
HappeningClient.WaitGrace = 15
local function stepFailed(run: any)
	run.StepFailures = (run.StepFailures or 0) + 1
	if run.StepFailures >= HappeningClient.MaxStepFailures and not run.Stopped then
		run.Stopped = true
		run.Aborted = true
		SceneReport.report("Happening", run.Id, "Steps", ("%d pasos fallidos: se corta"):format(run.StepFailures), "Abort")
	end
end
-- Escenas que el servidor paró mientras esperaban su turno (no se ponen al acabar la espera)
local stoppedEarly: { [number]: boolean } = {}

local function play(payload: { [string]: any })
	local source = HappeningIndex.get(payload.Id)
	if not source or type(payload.Run) ~= "number" then
		return
	end
	local late = 0
	if stoppedEarly[payload.Run] then
		stoppedEarly[payload.Run] = nil
		tell("Done", payload.Run)
		return
	end
	-- La misma escena que en el servidor: su variante y sus condiciones ya resueltas
	local okCompile, timeline = pcall(function()
		SceneReport.check("Happening", "Compile") -- (pruebas: la escena no se puede preparar)
		return Sequencer.compile(payload.Id, source, {
			Variant = if type(payload.Variant) == "number" then payload.Variant else nil,
			Gates = if type(payload.Gates) == "table" then payload.Gates else nil,
		})
	end)
	if not okCompile then
		SceneReport.report("Happening", payload.Id, "Compile", timeline, "Abort")
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
		Paused = late + (tonumber(payload.Paused) or 0), -- (quien llega a mitad: las pausas que ya lleva)
		Late = if late > 0 then late else nil,
		Hold = nil,
		ResumedAfter = -1,
		Anchors = payload.Anchors or {},
		Names = payload.Names or {},
		Voices = payload.Voices or {},
		Args = payload.Args or {},
		Light = payload.Light == true,
		Spectator = payload.Spectator == true,
		Participant = payload.Participant == true, -- (alcance Group: vives la escena de otro jugador)
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
		CanAdvance = false,
		CaptionHold = ReadingTime.newHold(),
		LineSerial = 0,
		LineShownAt = -math.huge,
		Pending = {},
	}
	-- ¿Conversación? (un toque pasa a la frase siguiente). Los espectadores solo miran.
	if payload.Spectator ~= true then
		local okAdvance, can = pcall(Sequencer.canAdvance, timeline)
		run.CanAdvance = okAdvance and can == true
	end
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
	-- Fase 7: quienes viven la escena contigo no se esconden de tus planos; si es la de otro (Group), ves
	-- sus actores (y los tuyos de la misión se apartan mientras tanto: nunca dos Nicos)
	pcall(function()
		local SceneClient = require(script.Parent.SceneClient)
		if type(payload.Companions) == "table" then
			SceneClient.setCompanions("Escena" .. run.Serial, payload.Companions)
		end
		if run.Participant and type(payload.Host) == "number" then
			SceneClient.shareScene("Escena" .. run.Serial, payload.Host)
		end
	end)
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
		if def.Legacy == true then
			legacyOnScreen += 1
			run.LegacyCounted = true
		end
		restoreGuis = hideOtherGuis(run.Ui.Gui)
		setControls(false)
		SceneChain.started() -- (si venía de otra escena, la cortina negra del puente se va)
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
		-- Director automático (shared/LifeStory/SceneDirector): lo que la escena no dice (ambiente del
		-- sitio, luz de la hora y, de noche, luz de relleno en las caras)
		pcall(function()
			local clock = player:GetAttribute("StoryClock")
			if type(clock) ~= "number" then
				clock = game:GetService("Lighting").ClockTime
			end
			local auto = SceneDirector.mood(def, clock, run.Light)
			if auto.Ambience then
				applyAmbience(run, { Kind = auto.Ambience, Fade = 1.5 })
			end
			if auto.Light then
				applyLight(run, { Preset = auto.Light, Fade = 1.2, Weight = auto.Weight })
			end
			if auto.KeyLight then
				startKeyLight(run)
			end
		end)
		StoryFx.setShakeSink(function(strength, seconds)
			table.insert(run.Impulses, { At = sceneTime(run), Strength = strength, Seconds = seconds })
		end)
	end
	-- Tocar para seguir en una escena de cine: tocar la pantalla (no el botón «Saltar»), clic, Espacio,
	-- Enter, E o el botón A del mando. (En una escena ligera solo el subtítulo: buildUi.)
	local tapConnection: RBXScriptConnection? = nil
	if cinematic and run.CanAdvance then
		tapConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if UserInputService:GetFocusedTextBox() then
				return
			end
			local key = input.KeyCode
			local kind = input.UserInputType
			local pressed = key == Enum.KeyCode.Space or key == Enum.KeyCode.Return or key == Enum.KeyCode.E or key == Enum.KeyCode.ButtonA
			local tapped = (kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1) and not processed
			if (pressed and not processed) or tapped then
				advance(run)
			end
		end)
	end
	local resolve = CameraShots.composite(resolver(run))
	local clockStart = os.clock()
	local endLimit = run.Timeline.Duration
		+ 1.5
		+ (if type(def.Until) == "table" then Sequencer.untilTimeout(def.Until) + 3 else 0)
	local ok, err = pcall(function()
		SceneReport.check("Happening", "Play") -- (pruebas: la escena entera falla al empezar)
		while not run.Stopped do
			local t = sceneTime(run)
			-- ¿Llega una espera? La escena se para ahí hasta que el servidor diga
			if not run.Hold then
				local w = Sequencer.nextWait(run.Timeline, run.ResumedAfter)
				if w and t >= w.At then
					run.Hold = w.At
					t = w.At
					local d = (w :: any).Data or {}
					run.HoldLimit = math.min(tonumber(d.Timeout or d.Seconds) or Sequencer.MAX_WAIT, Sequencer.MAX_WAIT)
				end
			end
			-- Vigilante de cada espera: el servidor la acaba (Resume) como mucho a su tope; si ese aviso no
			-- llega (se perdió, el servidor se atascó), la escena sigue sola en tu pantalla y se avisa
			if run.Hold then
				run.HoldSince = run.HoldSince or os.clock()
				local limit = (run.HoldLimit or Sequencer.MAX_WAIT) + HappeningClient.WaitGrace
				if SceneReport.injected("Happening", "WaitWatchdog") then
					limit = 0
				end
				if os.clock() - run.HoldSince > limit then
					SceneReport.report("Happening", run.Id, "Wait", ("la espera del segundo %.1f no acabó en %d s"):format(run.Hold, math.floor(limit)), "Watchdog")
					run.ResumedAfter = run.Hold
					run.Hold = nil
					run.HoldSince, run.HoldLimit = nil, nil
					pcall(endWait, run)
					t = sceneTime(run)
				end
			else
				run.HoldSince, run.HoldLimit = nil, nil
			end
			prefetchVoices(run, t)
			-- Sucesos de cliente que tocan
			if t > run.Cursor then
				for _, e in Sequencer.due(run.Timeline, run.Cursor, t, "Client") do
					local d = e.Data
					if not Sequencer.passes(d, run.Inputs) then
						continue
					end
					local track = e.Track
					-- (quien solo mira un acontecimiento del mundo —alcance World— ve lo que pasa en el
					-- mundo: efectos, sonido y cielo; sin cámara, sin frases y sin perder el control)
					if run.Spectator and track ~= "Fx" and track ~= "Sound" and track ~= "Sky" then
						continue
					end
					-- (fase 3: cada suceso en su pcall con aviso; si falla, se salta y la escena sigue)
					local okStep = SceneReport.guard("Happening", run.Id, track, function()
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
					elseif track == "Acting" then
						playActing(run, d)
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
					end)
					if not okStep then
						stepFailed(run)
					end
				end
				run.Cursor = t
			end
			-- Cámara (fase 3: en su pcall con aviso; si falla en cada fotograma, la escena se corta)
			local okShot = SceneReport.guard("Happening", run.Id, "Shot", function()
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
				-- (a la medida de quien sale: un bebé o un niño, CameraShots.scaleShot)
				if shot then
					run.Scaled = run.Scaled or {}
					local scaled = run.Scaled[shot]
					if scaled == nil then
						scaled = shot
						local subject = if type(shot.Shot) == "string" then CameraShots.subjects(shot.Shot)[1] else nil
						if subject and #CameraShots.subjects(shot.Shot) == 1 then
							local isMe = subject == "Yo" or subject == "Player"
							local model = if isMe then player.Character else actorModel(subject)
							local size = sizeOf(model)
							if size then
								scaled = CameraShots.scaleShot(shot, if isMe then "Player" else "Actor:" .. subject, size)
							end
						end
						run.Scaled[shot] = scaled
					end
					shot = scaled
				end
				if shot then
					camera.CameraType = Enum.CameraType.Scriptable
					if shot ~= run.ShotIndex then
						local hadShot = run.ShotIndex ~= nil
						run.ShotIndex = shot
						run.ShotNumber = ((run :: any).ShotNumber or 0) + 1 -- (Cinemateca: en qué plano iba)
						-- Plano con Lock (los planos con nombre): las anclas se quedan donde estaban al empezar
						run.ShotResolve = if shot.Lock
							then CameraShots.composite(CameraShots.locked(resolver(run), function(name: string): boolean
								local kind, value = name:match("^(%a+):(.+)$")
								return kind ~= "Actor" or actorModel(value) ~= nil
							end))
							else nil
						local cut = shot.Cut
						local ui = run.Ui
						if hadShot and (cut == "Dip" or cut == "Fade") then
							cutToElsewhere(run) -- (la frase de un personaje no pasa al plano de otro sitio)
						end
						if ui and (cut == "Dip" or cut == "Fade") then
							ui.Black.BackgroundTransparency = 0
							TweenService:Create(ui.Black, TweenInfo.new(if cut == "Fade" then 0.9 else 0.4), { BackgroundTransparency = 1 }):Play()
						elseif cut == "Flash" then
							StoryFx.flash(0.75, Color3.new(1, 1, 1), 0.45)
						elseif cut == "Whip" and hadShot then
							-- (v130) Barrido rápido: la cámara gira de donde estaba al plano nuevo en WHIP_SECONDS,
							-- con un silbido (sorpresas, cambios de sitio con prisa)
							run.WhipFrom, run.WhipAt = camera.CFrame, os.clock()
							pcall(function()
								playSound(run, { Play = "Whoosh", Volume = 0.8 })
							end)
						end
					end
					local impulse = math.max(CameraShots.impulse(run.Timeline.Shakes, t), CameraShots.impulse(run.Impulses, t))
					local shotResolve = run.ShotResolve or resolve
					-- Un travelling que atravesaría una pared, una farola o a alguien (llegaste por otro lado,
					-- tu coche aparcado al lado): se queda quieto en su final (CameraShots.travelBlocked)
					if run.StillShot ~= shot then
						run.StillShot, run.Still = shot, false
						if CameraShots.kind(shot) == "Travel" then
							pcall(function()
								local points = {}
								for k = 0, 8 do
									local raw = CameraShots.cframe(shot, k / 8, shotResolve, 0, 0)
									local look = CameraShots.point(shotResolve, shot.Look)
									if raw and look then
										table.insert(points, (CineCamera.fit(raw, look, fitOptions(run, shot, shotResolve))).Position)
									end
								end
								run.Still = CameraShots.travelBlocked(points, CineCamera.probe())
							end)
						end
					end
					if run.Still then
						u = 1
					end
					local cf = CameraShots.cframe(shot, u, shotResolve, os.clock() - clockStart, impulse)
					if cf then
						local focus = CameraShots.point(shotResolve, shot.Look)
							or (if shot.Orbit then (resolve(shot.Orbit) :: any) and resolve(shot.Orbit).Position else nil)
						if focus then
							-- Sin paredes ni cabezas delante (CameraShots.fit): el giro que se elige al
							-- empezar el plano se mantiene hasta que acaba (la cámara no salta a mitad)
							if run.FitShot ~= shot then
								run.FitShot, run.FitChoice = shot, nil
							end
							local opts = fitOptions(run, shot, shotResolve)
							opts.Choice = run.FitChoice
							local fitted, choice = CineCamera.fit(cf, focus, opts)
							cf = fitted
							-- (fit solo cambia de giro si el de antes ya no deja ver la cara)
							run.FitChoice = choice or run.FitChoice
						end
						-- (Whip) los primeros instantes del plano, girando desde el anterior
						local whipFrom, whipAt = run.WhipFrom, run.WhipAt
						if whipFrom and whipAt then
							local w = (os.clock() - whipAt) / CameraShots.WHIP_SECONDS
							if w >= 1 then
								run.WhipFrom, run.WhipAt = nil, nil
							else
								cf = whipFrom:Lerp(cf, CameraShots.ease("In", w))
							end
						end
						camera.CFrame = cf
						-- Foco: a lo que mira el plano; con Rack, el foco pasa a otro punto mientras dura (cambio
						-- de foco: primero nítido uno, luego el otro)
						local focusDistance = if focus then (focus - cf.Position).Magnitude else nil
						local rackPoint = if shot.Rack then CameraShots.point(shotResolve, shot.Rack) else nil
						if focusDistance and rackPoint then
							focusDistance = focusDistance + ((rackPoint - cf.Position).Magnitude - focusDistance) * CameraShots.ease(nil, u)
						end
						pcall(function()
							require(script.Parent.DayLight).setFocus(focusDistance)
						end)
					end
					camera.FieldOfView = CameraShots.fov(shot, u) or previousFov
				end
			end
			end)
			if not okShot then
				stepFailed(run)
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
		SceneReport.report("Happening", run.Id, "Play", err, "Abort")
	end
	if tapConnection then
		tapConnection:Disconnect()
	end
	table.clear(run.Pending)
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
		-- ¿Viene otra escena detrás (la cabecera del capítulo, la escena siguiente de la misión)? La
		-- pantalla se queda en negro y sin interfaz hasta que empiece (UI/SceneChain)
		if ui and not run.Died then
			pcall(SceneChain.bridge)
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
		if run.LegacyCounted then
			run.LegacyCounted = nil
			legacyOnScreen = math.max(0, legacyOnScreen - 1)
		end
		if onScreen == 0 and not SceneChain.active() then
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
	-- (Cinemateca: dónde iba la escena al acabar o saltarla, para la revisión)
	lastRun = {
		Id = run.Id,
		Shot = (run :: any).ShotNumber,
		Shots = #run.Timeline.Shots,
		T = math.floor(sceneTime(run) * 10 + 0.5) / 10,
		Duration = run.Timeline.Duration,
		Skipped = run.Skipped == true,
	}
	pcall(function()
		local SceneClient = require(script.Parent.SceneClient)
		SceneClient.setCompanions("Escena" .. run.Serial, nil)
		SceneClient.shareScene("Escena" .. run.Serial, nil)
	end)
	if not run.Spectator then
		tell("Done", run.Serial)
	end
	-- (después de un fallo, la red de seguridad: si ya no queda nada en pantalla, todo vuelve)
	if not ok or run.Aborted then
		SceneReport.recover("Happening")
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
	local found = require(script.Parent.Parent.UI.ServerWait).remote("Happening")
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
		elseif kind == "Party" and run and type(payload.Companions) == "table" then
			-- (Group) alguien se ha unido a la escena o la ha dejado
			pcall(function()
				require(script.Parent.SceneClient).setCompanions("Escena" .. run.Serial, payload.Companions)
			end)
		elseif kind == "Pause" and run then
			run.Hold = payload.At
			if payload.Freeze then
				-- (Cinemateca: parada para comentar; el vigilante de esperas no la sigue sola enseguida)
				run.HoldSince = os.clock()
				run.HoldLimit = 900
			end
		elseif kind == "Shift" and run then
			-- Tocar para seguir: el servidor ha adelantado el reloj hasta la frase siguiente
			if type(payload.Paused) == "number" then
				run.Paused = payload.Paused + (run.Late or 0)
			end
			ReadingTime.release(run.CaptionHold)
		elseif kind == "Resume" and run then
			run.Paused = if type(payload.Paused) == "number" then payload.Paused + (run.Late or 0) else run.Paused
			run.Inputs = payload.Inputs or run.Inputs
			run.ResumedAfter = run.Hold or run.ResumedAfter
			run.Hold = nil
			endWait(run)
		elseif kind == "Stop" and run then
			run.Stopped = true
			run.Skipped = payload.Skipped == true or run.Skipped
		elseif kind == "Stop" and type(payload.Run) == "number" then
			stoppedEarly[payload.Run] = true -- (aún esperaba a que acabara otra escena)
			task.delay(35, function() -- (fase 6: ya no hay espera en la pantalla; lo que tarde en llegar)
				stoppedEarly[payload.Run] = nil
			end)
		end
	end)
end

return HappeningClient
