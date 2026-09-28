-- ActorLife (cliente): que los personajes parezcan vivos.
--
-- Todo se hace en tu pantalla (suave, sin cargar al servidor) y encima de sus animaciones:
--   * Respiran: el pecho y los hombros suben y bajan un poco, cada uno a su ritmo.
--   * Miran: giran la cabeza (y un poco el torso) hacia ti cuando pasas cerca, apartan la mirada
--     al rato, echan vistazos alrededor… En una conversación miran a quien habla.
--   * Hablan con el cuerpo: mientras dicen su frase mueven la cabeza y las manos, y lo hacen
--     según la emoción de la frase (shared/LifeStory/Emotion): contentos, tristes, enfadados,
--     sorprendidos, pensando, preguntando, asintiendo, negando… Si la frase lo pide, saludan,
--     celebran, se ríen, señalan o bailan (animaciones de Roblox).
--   * Los personajes fijos del mapa (profes, dependientes, gente de la calle) respiran, caminan
--     con animación de andar cuando se mueven y cambian de postura de vez en cuando (antes eran
--     maniquís). Los de las escenas de la historia ya los anima el servidor (SceneService): aquí
--     solo se les añade la mirada, la respiración y los gestos.
--   * Hacen su oficio: si el servidor les pone el atributo "Work" (barrer, apuntar en la carpeta,
--     cobrar, cocinar, tejer…), mueven los brazos con esa tarea y llevan su objeto en la mano
--     (WorkAnim). Cuando hablan contigo o andan, lo dejan y vuelven a él después.
--   * Esperando no son estatuas: cargan el peso de un pie a otro, cruzan los brazos, se ponen en
--     jarras, se estiran o miran el móvil un rato (los mayores), y los ojos dan saltitos al mirar.
--   * Se giran hacia quien les habla: si la cabeza no llega, gira el cuerpo poco a poco (solo en tu
--     pantalla, con la articulación Root: el servidor no se entera y no hay tirones).
--   * Fundidos: si un actor de tu escena no puede llegar andando, el servidor sube su atributo Fade y
--     aquí se desvanece y reaparece (los fijos del mapa ya los funde SceneClient).
--
-- Solo se calculan los 32 más cercanos a la cámara; los fijos del mapa algo más lejos siguen con su
-- animación de andar o de estar de pie (medio segundo a medio segundo, barato), para que nadie se deslice.
--
-- La usan DialogueUI (quién habla, con qué emoción y con qué gesto) y Cinematics (gestos en las escenas).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Emotion = require(ReplicatedStorage.Shared.LifeStory.Emotion)
local WorkAnim = require(script.Parent.WorkAnim)
local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)

local ActorLife = {}

local player = Players.LocalPlayer

-- Animaciones R15 de Roblox (las mismas que usan los avatares)
local ANIMS = {
	Idle = "rbxassetid://507766666",
	Idle2 = "rbxassetid://507766951", -- mirar alrededor
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
	Wave = "rbxassetid://507770239",
	Cheer = "rbxassetid://507770677",
	Laugh = "rbxassetid://507770818",
	Point = "rbxassetid://507770453",
	Dance = "rbxassetid://507771019",
}

local ACTIVE_DISTANCE = 95 -- más lejos no se nota: no se calcula
local MAX_ACTIVE = 32
local AMBIENT_DISTANCE = 260 -- los fijos del mapa hasta aquí siguen andando con animación (sin gestos)
local JOINTS = { "Neck", "Waist", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow" }
local HEAD_YAW = math.rad(75) -- lo más que gira la cabeza sola; más allá gira el cuerpo
local BODY_START = math.rad(40) -- a partir de aquí el cuerpo acompaña (si está hablando con alguien)
local BODY_MAX = math.rad(115) -- lo más que se gira el cuerpo en tu pantalla (más, lo gira el servidor)
local TAU = math.pi * 2

type Rig = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Head: BasePart,
	Joints: { [string]: Motor6D },
	Base: { [string]: CFrame },
	Hip: Instance?,
	Own: boolean, -- el cliente pone la animación base (andar, estar de pie): NPCs fijos del mapa
	Me: boolean, -- tu propio personaje (solo se anima al hablar)
	Seed: number,
	Active: boolean,
	Tracks: { [string]: AnimationTrack },
	BaseAnim: string?,
	IdleAltAt: number,
	LastPos: Vector3?,
	Speed: number,
	Yaw: number,
	Pitch: number,
	Talk: number, -- 0..1: cuánto está hablando ahora
	TalkUntil: number,
	Emotion: string,
	EmotionAt: number,
	Poses: { [string]: number }, -- peso de cada postura (0..1), suave
	GlanceAt: number,
	Glance: Vector2?, -- (yaw, pitch) de un vistazo; nil = mirar al frente
	InterestAt: number, -- hasta cuándo te mira / cuándo vuelve a mirarte
	Interested: boolean,
	ChatAt: number, -- (modo Chat) cuándo cambia de turno la charla
	Partner: Model?,
	WorkName: string?, -- tarea (atributo "Work") para la que están hechos sus objetos
	WorkW: number, -- 0..1: cuánto está haciendo su tarea ahora (suave)
	WorkPose: WorkAnim.Pose,
	Attention: number, -- 0..1: cuánto te está mirando (deja la tarea para mirarte)
	Props: { WorkAnim.HeldProp },
	Scale: number, -- tamaño (Model:GetScale): un niño da pasos más cortos
	LastPosAt: number,
	RootJoint: Motor6D?, -- LowerTorso.Root: para girar el cuerpo entero sin mover la raíz
	BodyYaw: number, -- cuánto está girado el cuerpo respecto a la raíz (radianes)
	BodyWorld: number, -- hacia dónde mira el cuerpo en el mundo (así no salta si el servidor gira la raíz)
	BodyGoal: number?, -- hacia dónde quiere mirar el cuerpo (mundo); nil = de frente
	BodyGoalAt: number,
	SacYaw: number, -- saltitos de los ojos/cabeza al mirar (sacadas)
	SacPitch: number,
	SacGoalYaw: number,
	SacGoalPitch: number,
	SacAt: number,
	Still: number, -- 0..1: parado de pie sin hacer nada (carga el peso de un pie a otro)
	Gesture: string?, -- gesto de encima de la frase (G = "Clap"…)
	GestureAt: number,
	GestureUntil: number,
	IdleAct: string?, -- lo que hace mientras espera: ArmsCrossed, HandsOnHips, Stretch, Phone
	IdleActAt: number, -- cuándo se le ocurre la próxima
	IdleActUntil: number,
	IdleWork: string?, -- (Phone) el móvil en la mano, hasta que acaba de guardarlo
}

local rigs: { [Model]: Rig } = {}
local active: { Rig } = {}
local waiting: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- esperando a que llegue entero

-- Conversación en curso
local conversation = false
local speaker: Model? = nil
local listeners: { [Model]: boolean } = {}

local function now(): number
	return os.clock()
end

local function smooth(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

local function mix(a: number, b: number, w: number): number
	return a + (b - a) * w
end

-- Ángulo entre -pi y pi
local function wrap(angle: number): number
	return (angle + math.pi) % TAU - math.pi
end

-- Hacia dónde mira (en horizontal) una pieza: el mismo ángulo que CFrame.Angles(0, yaw, 0)
local function headingOf(cf: CFrame): number
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function scaleOf(model: Model): number
	local ok, scale = pcall(function()
		return model:GetScale()
	end)
	return if ok and type(scale) == "number" and scale > 0 then scale else 1
end

---------------------------------------------------------------------
-- Registro de personajes
---------------------------------------------------------------------

local function isScene(model: Instance): boolean
	local scenes = workspace:FindFirstChild("StoryScenes")
	return scenes ~= nil and model:IsDescendantOf(scenes)
end

-- ¿Es de la escena de otro jugador? (tú no la ves: no se anima)
local function othersScene(model: Instance): boolean
	local scenes = workspace:FindFirstChild("StoryScenes")
	local mine = scenes and scenes:FindFirstChild("Scene_" .. player.UserId)
	return scenes ~= nil and model:IsDescendantOf(scenes) and not (mine and model:IsDescendantOf(mine))
end

---------------------------------------------------------------------
-- Fundidos (actores de tu escena que no pueden llegar andando: atributo Fade)
---------------------------------------------------------------------

type Fade = { Parts: { Instance }, From: number, To: number, Start: number, Seconds: number, Done: (() -> ())? }
local fades: { Fade } = {}
local fadeWatched: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function fadeModel(model: Model, from: number, to: number, seconds: number, onDone: (() -> ())?)
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			table.insert(parts, d)
		end
	end
	table.insert(fades, { Parts = parts, From = from, To = to, Start = os.clock(), Seconds = seconds, Done = onDone })
end

local function stepFades(t: number)
	for i = #fades, 1, -1 do
		local f = fades[i]
		local k = math.clamp((t - f.Start) / f.Seconds, 0, 1)
		local value = f.From + (f.To - f.From) * k
		for _, p in f.Parts do
			(p :: any).LocalTransparencyModifier = value
		end
		if k >= 1 then
			table.remove(fades, i)
			if f.Done then
				task.spawn(f.Done)
			end
		end
	end
end

-- Se desvanece (el servidor lo cambia de sitio a los 0.35 s) y reaparece
local function watchFade(model: Model)
	if fadeWatched[model] or CollectionService:HasTag(model, "StaticNpc") then
		return -- (a los fijos del mapa ya los funde SceneClient)
	end
	fadeWatched[model] = true
	model:GetAttributeChangedSignal("Fade"):Connect(function()
		fadeModel(model, 0, 1, 0.3, function()
			task.delay(0.1, function()
				if model.Parent then
					fadeModel(model, 1, 0, 0.4)
				end
			end)
		end)
	end)
end

-- Registra a un personaje. Devuelve "wait" si aún no ha llegado entero a tu pantalla (se reintenta)
local function register(model: Model): string
	if rigs[model] then
		return "ok"
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return "no"
	end
	local owner = Players:GetPlayerFromCharacter(model)
	if owner and owner ~= player then
		return "no" -- los avatares de otros jugadores ya tienen sus animaciones
	end
	if othersScene(model) then
		return "no"
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	if not root or not head then
		return "wait"
	end
	local joints, base = {}, {}
	for _, name in JOINTS do
		local joint = model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			joints[name] = joint
			base[name] = joint.C0
		end
	end
	if not joints.Neck then
		return "wait"
	end
	-- La articulación de la cadera con la raíz (gira todo el cuerpo): está en LowerTorso
	local lower = model:FindFirstChild("LowerTorso")
	local rootJoint = lower and lower:FindFirstChild("Root")
	if rootJoint and rootJoint:IsA("Motor6D") then
		joints.Root = rootJoint
		base.Root = rootJoint.C0
	else
		rootJoint = nil
	end
	local t = now()
	local rig: Rig = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Head = head,
		Joints = joints,
		Base = base,
		Hip = model:FindFirstChild("LeftHip", true),
		Own = owner == nil and not isScene(model),
		Me = owner == player,
		Seed = math.random() * 100,
		Active = false,
		Tracks = {},
		BaseAnim = nil,
		IdleAltAt = t + math.random(8, 25),
		LastPos = nil,
		Speed = 0,
		Yaw = 0,
		Pitch = 0,
		Talk = 0,
		TalkUntil = 0,
		Emotion = "Calm",
		EmotionAt = 0,
		Poses = {},
		GlanceAt = t + math.random() * 3,
		Glance = nil,
		InterestAt = 0,
		Interested = false,
		ChatAt = t + math.random() * 3,
		Partner = nil,
		WorkName = nil,
		WorkW = 0,
		WorkPose = {} :: any,
		Attention = 0,
		Props = {},
		Scale = scaleOf(model),
		LastPosAt = t,
		RootJoint = rootJoint :: Motor6D?,
		BodyYaw = 0,
		BodyWorld = headingOf(root.CFrame),
		BodyGoal = nil,
		BodyGoalAt = 0,
		SacYaw = 0,
		SacPitch = 0,
		SacGoalYaw = 0,
		SacGoalPitch = 0,
		SacAt = t,
		Still = 0,
		Gesture = nil,
		GestureAt = 0,
		GestureUntil = 0,
		IdleAct = nil,
		IdleActAt = t + 6 + math.random() * 14,
		IdleActUntil = 0,
		IdleWork = nil,
	}
	WorkAnim.clear(rig.WorkPose)
	rigs[model] = rig
	waiting[model] = nil
	if isScene(model) then
		watchFade(model)
	end
	model.AncestryChanged:Connect(function(_, parent)
		if parent == nil and rigs[model] then
			rigs[model] = nil
		end
	end)
	return "ok"
end

-- Lo intenta hasta que el cuerpo entero ha llegado (el mapa se carga por trozos; antes, si llegaba
-- el humanoide antes que la cabeza, ese personaje se quedaba sin animar para siempre)
local function tryRegister(model: Model, attempt: number)
	if rigs[model] or not model.Parent then
		waiting[model] = nil
		return
	end
	local ok, status = pcall(register, model)
	if ok and status == "wait" and attempt < 12 then
		waiting[model] = true
		task.delay(0.5 + attempt * 0.5, tryRegister, model, attempt + 1)
	else
		waiting[model] = nil
	end
end

local function consider(instance: Instance)
	if instance:IsA("Humanoid") then
		local model = instance.Parent
		if model and model:IsA("Model") and not waiting[model] then
			waiting[model] = true
			-- Esperar un poco a que llegue el cuerpo entero
			task.delay(0.5, tryRegister, model, 0)
		end
	end
end

---------------------------------------------------------------------
-- Animaciones
---------------------------------------------------------------------

local function animatorOf(rig: Rig): Animator?
	local animator = rig.Humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		if not rig.Own then
			return nil
		end
		-- Personaje fijo del mapa sin animador: le ponemos uno solo en tu pantalla
		local ok, created = pcall(function()
			local a = Instance.new("Animator")
			a.Parent = rig.Humanoid
			return a
		end)
		animator = if ok then created else nil
	end
	return animator
end

local function track(rig: Rig, name: string): AnimationTrack?
	local existing = rig.Tracks[name]
	if existing then
		return existing
	end
	local animator = animatorOf(rig)
	if not animator then
		return nil
	end
	local ok, loaded = pcall(function()
		local animation = Instance.new("Animation")
		animation.AnimationId = ANIMS[name]
		local t = animator:LoadAnimation(animation)
		if Emotion.Animated[name] then
			t.Priority = Enum.AnimationPriority.Action
			t.Looped = name == "Dance"
		else
			t.Priority = if name == "Idle" or name == "Idle2" then Enum.AnimationPriority.Idle else Enum.AnimationPriority.Movement
			t.Looped = name ~= "Idle2"
		end
		return t
	end)
	if ok and loaded then
		rig.Tracks[name] = loaded
		return loaded
	end
	return nil
end

-- Andar / correr / estar de pie (solo los personajes fijos del mapa: los demás ya los anima alguien)
local function setBase(rig: Rig, name: string?, speed: number?)
	if rig.BaseAnim ~= name then
		if rig.BaseAnim then
			local old = rig.Tracks[rig.BaseAnim]
			if old then
				old:Stop(0.3)
			end
		end
		rig.BaseAnim = name
		if name then
			local t = track(rig, name)
			if t then
				t:Play(0.3)
				if name == "Idle" then
					-- Que no respiren todos a la vez
					pcall(function()
						t.TimePosition = math.random() * math.max(0.1, t.Length)
					end)
				end
			end
		end
	end
	if name and speed then
		local t = rig.Tracks[name]
		if t then
			t:AdjustSpeed(speed)
		end
	end
end

local function sitting(rig: Rig): boolean
	if rig.Humanoid.Sit then
		return true
	end
	-- Sentado en una escena o en una silla del mapa (Npc.setPose: UsePose = "Sit"…)
	if rig.Model:GetAttribute("UsePose") ~= nil then
		return true
	end
	-- Npc.sit dobla las piernas y guarda la postura original
	return rig.Hip ~= nil and rig.Hip:GetAttribute("BaseC0") ~= nil
end

-- Andar al paso de sus pies: el ritmo de la animación va con la velocidad Y con su tamaño (un niño
-- pequeño da más pasos para ir igual de rápido; antes parecía que patinaba)
local function updateBase(rig: Rig, t: number)
	if not rig.Own then
		return
	end
	local scale = rig.Scale
	if sitting(rig) then
		setBase(rig, nil)
	elseif rig.Speed > 13 * scale then
		setBase(rig, "Run", math.clamp(rig.Speed / (18 * scale), 0.7, 1.6))
	elseif rig.Speed > 0.8 then
		setBase(rig, "Walk", math.clamp(rig.Speed / (11 * scale), 0.5, 1.8))
	elseif rig.BaseAnim == "Idle2" then
		local alt = rig.Tracks.Idle2
		if not alt or not alt.IsPlaying then
			setBase(rig, "Idle")
		end
	elseif t > rig.IdleAltAt and not conversation and rig.WorkName == nil then
		-- De vez en cuando cambian de postura / miran alrededor (si no están con su tarea)
		rig.IdleAltAt = t + math.random(14, 30)
		setBase(rig, "Idle2")
	else
		setBase(rig, "Idle")
	end
end

---------------------------------------------------------------------
-- Adónde mira cada uno
---------------------------------------------------------------------

local function headPosition(model: Instance?): Vector3?
	if not model or not model:IsA("Model") or not model.Parent then
		return nil
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	return head and head.Position
end

-- (yaw, pitch) para mirar a un punto, relativo a la raíz (sin límite: el cuerpo puede ayudar a girar)
local function aim(rig: Rig, target: Vector3): (number?, number?)
	local from = rig.Head.Position
	local offset = target - from
	if offset.Magnitude < 0.5 then
		return nil, nil
	end
	local dir = rig.Root.CFrame:VectorToObjectSpace(offset.Unit)
	local yaw = math.atan2(-dir.X, -dir.Z)
	local pitch = math.asin(math.clamp(dir.Y, -1, 1))
	return yaw, math.clamp(pitch, -math.rad(35), math.rad(30))
end

-- Adónde quiere mirar: (yaw relativo a la raíz, pitch, ¿está pendiente de alguien?). Si está pendiente
-- (le hablan, habla, te mira de cerca, charla con otro) el cuerpo le acompaña cuando la cabeza no llega.
local function lookTarget(rig: Rig, t: number): (number, number, boolean)
	local myHead = headPosition(player.Character)
	-- En una conversación: quien habla te mira (o mira a quien le escucha); los demás miran a quien habla
	if conversation and (listeners[rig.Model] or rig.Model == speaker) then
		local target: Vector3? = nil
		if rig.Model == speaker then
			if rig.Me then
				for other in listeners do
					if other ~= rig.Model then
						target = headPosition(other)
						break
					end
				end
			else
				target = myHead
			end
			-- Al hablar a veces se aparta la mirada un momento (pensando lo que dice)
			if math.sin(t * 0.9 + rig.Seed) > 0.93 then
				return rig.BodyYaw + math.rad(18) * math.sign(math.sin(rig.Seed)), math.rad(6), true
			end
		else
			target = headPosition(speaker)
		end
		if target then
			local yaw, pitch = aim(rig, target)
			if yaw then
				return yaw, pitch :: number, true
			end
		end
		return rig.BodyYaw, 0, true
	end
	if rig.Me then
		return 0, 0, false
	end
	-- Si pasas cerca, te miran un rato; luego apartan la vista y vuelven a mirarte
	local distance = if myHead then (myHead - rig.Head.Position).Magnitude else math.huge
	local near = distance < (if rig.Partner then 10 else 16)
	if near then
		if t > rig.InterestAt then
			rig.Interested = not rig.Interested
			rig.InterestAt = t + (if rig.Interested then 2.5 + math.random() * 4 else 1.2 + math.random() * 2.5)
		end
		if rig.Interested then
			local yaw, pitch = aim(rig, myHead :: Vector3)
			if yaw then
				-- Muy cerca (y sin estar liado con su tarea) se vuelve hacia ti; de lejos solo te mira
				return yaw, pitch :: number, distance < 9 and rig.WorkW < 0.3
			end
		end
	else
		rig.Interested = false
	end
	-- Charlando con los de al lado: mira a su compañero
	if rig.Partner and rig.Partner.Parent then
		local yaw, pitch = aim(rig, headPosition(rig.Partner) or rig.Head.Position)
		if yaw then
			return yaw, pitch :: number, true
		end
	end
	-- Vistazos alrededor
	if t > rig.GlanceAt then
		rig.GlanceAt = t + 2 + math.random() * 4.5
		rig.Glance = if math.random() < 0.45
			then nil
			else Vector2.new(math.rad(math.random(-45, 45)), math.rad(math.random(-12, 8)))
	end
	local glance = rig.Glance
	if glance then
		return rig.BodyYaw + glance.X, glance.Y, false
	end
	return rig.BodyYaw, 0, false
end

-- El cuerpo acompaña a la mirada: si la cabeza tendría que girar mucho hacia quien le habla, se da la
-- vuelta poco a poco (y se queda así mientras siga pendiente). Se cuenta en el mundo: si el servidor
-- gira la raíz a la vez (SceneService), el cuerpo no da un salto.
local function updateBody(rig: Rig, wantYaw: number, engaged: boolean, seated: boolean, t: number, dt: number)
	local rootHeading = headingOf(rig.Root.CFrame)
	local free = rig.RootJoint ~= nil and not rig.Me and rig.Speed <= 0.8 and not seated
	if not free then
		-- Andando o sentado: de frente (la raíz ya mira hacia donde va)
		rig.BodyYaw = smooth(rig.BodyYaw, 0, 6, dt)
		rig.BodyWorld = rootHeading + rig.BodyYaw
		rig.BodyGoal = nil
		return
	end
	if engaged and math.abs(wrap(wantYaw - rig.BodyYaw)) > BODY_START then
		rig.BodyGoal = rootHeading + wantYaw * 0.8 -- casi de frente: el último trozo lo pone la cabeza
		rig.BodyGoalAt = t
	elseif engaged and rig.BodyGoal then
		rig.BodyGoalAt = t
	elseif rig.BodyGoal and t - rig.BodyGoalAt > 3.5 then
		rig.BodyGoal = nil -- ya no está pendiente: vuelve a su postura
	end
	local goal = math.clamp(if rig.BodyGoal then wrap(rig.BodyGoal - rootHeading) else 0, -BODY_MAX, BODY_MAX)
	local diff = wrap(rootHeading + goal - rig.BodyWorld)
	rig.BodyWorld += diff * (1 - math.exp(-2.4 * dt))
	rig.BodyYaw = math.clamp(wrap(rig.BodyWorld - rootHeading), -BODY_MAX, BODY_MAX)
	rig.BodyWorld = rootHeading + rig.BodyYaw
end

---------------------------------------------------------------------
-- Postura y gestos
---------------------------------------------------------------------

local POSE_NAMES = {
	"Happy", "Sad", "Angry", "Surprised", "Thinking", "Ask", "Shrug", "Nod", "No",
	"ArmsCrossed", "HandsOnHips", "Facepalm", "Clap", "ThinkChin", "WaveLite", "Stretch",
}
-- Gestos cortos: duran esto (segundos) desde que empieza la frase o el gesto
local SHORT = { Nod = 1.6, No = 1.6, Shrug = 1.6, Clap = 1.9, WaveLite = 1.8, Facepalm = 2.4 }

-- Cuánto mueven las manos al hablar según la emoción
local GESTURE = {
	Calm = 0.7, Happy = 1, Sad = 0.3, Angry = 1.3, Surprised = 0.8, Thinking = 0.25, Ask = 0.8, Shrug = 0.6, Nod = 0.5, No = 0.7,
	ArmsCrossed = 0.15, HandsOnHips = 0.2, Facepalm = 0.2, Clap = 0.2, ThinkChin = 0.2, WaveLite = 0.5,
}

-- Charlas entre ellos (modo Chat): con qué ánimo dice cada uno lo suyo
local CHAT_MOODS = { "Calm", "Calm", "Happy", "Ask", "Nod", "Shrug", "Surprised", "ThinkChin", "HandsOnHips" }

-- Qué hacen mientras esperan, según la edad (se elige al azar; se repite alguno para que salga más)
local IDLE_ACTS = {
	Nino = { "HandsOnHips", "Stretch", "Look", "Look" },
	Adolescente = { "ArmsCrossed", "Phone", "Phone", "HandsOnHips", "Look" },
	Mayor = { "ArmsCrossed", "ArmsCrossed", "Look", "Look", "Stretch" },
	Adulto = { "ArmsCrossed", "ArmsCrossed", "HandsOnHips", "Phone", "Phone", "Stretch", "Look" },
}
local IDLE_SECONDS = { ArmsCrossed = { 6, 14 }, HandsOnHips = { 3, 6 }, Phone = { 6, 12 }, Stretch = { 2.4, 2.4 } }

local function actionPlaying(rig: Rig): boolean
	for name in Emotion.Animated do
		local t = rig.Tracks[name]
		if t and t.IsPlaying then
			return true
		end
	end
	return false
end

-- ¿Le está poniendo el servidor un gesto (saludar, celebrar…)? Solo se mira al elegir qué hacer
local function serverActing(rig: Rig): boolean
	local animator = rig.Humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return false
	end
	for _, t in animator:GetPlayingAnimationTracks() do
		if t.Priority == Enum.AnimationPriority.Action and not rig.Tracks[t.Name] then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Tarea de trabajo y objetos en la mano (solo en tu pantalla)
---------------------------------------------------------------------

local function clearProps(rig: Rig)
	WorkAnim.clearProps(rig.Props)
end

local function makeProps(rig: Rig, work: WorkAnim.Work)
	rig.Props = WorkAnim.makeProps(rig.Model, work)
end

local function showProps(rig: Rig, shown: boolean)
	WorkAnim.showProps(rig.Props, shown)
end

-- Mientras espera, de vez en cuando hace algo (cruzar los brazos, ponerse en jarras, estirarse,
-- mirar el móvil, echar un vistazo largo). Lo deja en cuanto pasa algo (le hablan, anda…).
local function updateIdleAct(rig: Rig, t: number, calm: boolean)
	if rig.IdleAct and (not calm or t > rig.IdleActUntil) then
		rig.IdleAct = nil
		rig.IdleActAt = t + 10 + math.random() * 18
	end
	if rig.IdleAct or not calm or t < rig.IdleActAt then
		return
	end
	rig.IdleActAt = t + 12 + math.random() * 18
	if serverActing(rig) then
		return
	end
	local age = rig.Model:GetAttribute("Age")
	local options = IDLE_ACTS[if type(age) == "string" and IDLE_ACTS[age] then age else "Adulto"]
	local act = options[math.random(1, #options)]
	if act == "Look" then
		-- Un vistazo largo a un lado (los fijos del mapa, además, con su animación de mirar alrededor)
		rig.Glance = Vector2.new(math.rad(math.random(50, 75)) * (if math.random() < 0.5 then -1 else 1), math.rad(math.random(-5, 6)))
		rig.GlanceAt = t + 2.5 + math.random() * 1.5
		return
	end
	local seconds = IDLE_SECONDS[act]
	rig.IdleAct = act
	rig.IdleActUntil = t + seconds[1] + math.random() * (seconds[2] - seconds[1])
	if act == "Phone" then
		rig.IdleWork = "Phone"
	end
end

local function update(rig: Rig, t: number, dt: number)
	-- Velocidad (los NPCs del mapa se mueven sin física: se mide cuánto avanzan). Se cuenta con el
	-- tiempo de verdad desde la última medida (al volver a estar cerca no sale un pico falso)
	local position = rig.Root.Position
	local since = t - rig.LastPosAt
	if rig.LastPos and since > 0 and since < 0.6 then
		local moved = Vector3.new(position.X - rig.LastPos.X, 0, position.Z - rig.LastPos.Z).Magnitude / since
		rig.Speed = smooth(rig.Speed, math.min(moved, 40), 6, dt)
	elseif since >= 0.6 then
		rig.Speed = 0
	end
	rig.LastPos = position
	rig.LastPosAt = t
	updateBase(rig, t)

	-- Modo Chat (escenas): charlan entre ellos por turnos, con gestos
	if rig.Model:GetAttribute("Chat") and not conversation then
		if not rig.Partner or not rig.Partner.Parent then
			local best, bestDistance = nil, 12
			for other in rigs do
				if other ~= rig.Model and other:GetAttribute("Chat") then
					local d = (other:GetPivot().Position - position).Magnitude
					if d < bestDistance then
						best, bestDistance = other, d
					end
				end
			end
			rig.Partner = best
		end
		if t > rig.ChatAt then
			local speaking = math.random() < 0.5
			rig.ChatAt = t + (if speaking then 2 + math.random() * 3 else 1.5 + math.random() * 2.5)
			if speaking then
				rig.Emotion = CHAT_MOODS[math.random(1, #CHAT_MOODS)]
				rig.EmotionAt = t
				rig.TalkUntil = rig.ChatAt
				if math.random() < 0.12 then
					ActorLife.play(rig.Model, "Laugh")
				end
			end
		end
	elseif rig.Partner then
		rig.Partner = nil
	end

	-- Mirada y cuerpo
	local seated = sitting(rig)
	local wantYaw, wantPitch, engaged = lookTarget(rig, t)
	updateBody(rig, wantYaw, engaged, seated, t, dt)
	local headYaw = wrap(wantYaw - rig.BodyYaw)
	if math.abs(headYaw) > math.rad(115) then
		headYaw, wantPitch = 0, 0 -- queda detrás: no se retuerce (si le importa, ya se girará el cuerpo)
	end
	headYaw = math.clamp(headYaw, -HEAD_YAW, HEAD_YAW)
	-- Más despacio cuanto más lejos tiene que girar (un giro grande no es un latigazo)
	local rate = 7 - math.min(math.abs(headYaw - rig.Yaw), 1.2) * 3
	rig.Yaw = smooth(rig.Yaw, headYaw, rate, dt)
	rig.Pitch = smooth(rig.Pitch, wantPitch, rate, dt)
	-- Sacadas: los ojos no se quedan fijos, dan saltitos rápidos alrededor de lo que miran
	if t > rig.SacAt then
		rig.SacAt = t + 0.35 + math.random() * 1.6
		rig.SacGoalYaw = (math.random() - 0.5) * 0.09
		rig.SacGoalPitch = (math.random() - 0.5) * 0.05
	end
	rig.SacYaw = smooth(rig.SacYaw, rig.SacGoalYaw, 28, dt)
	rig.SacPitch = smooth(rig.SacPitch, rig.SacGoalPitch, 28, dt)

	-- Hablar y emoción
	-- Con su bocadillo de texto a la vista (Npc.say, UI/SpeechBubbles) también está hablando: deja la
	-- tarea y gesticula
	if not rig.Me and (rig.Model:GetAttribute("Says") ~= nil or SpeechBubbles.isSpeaking(rig.Model)) then
		rig.TalkUntil = math.max(rig.TalkUntil, t + 0.25)
	end
	local talking = t < rig.TalkUntil
	rig.Talk = smooth(rig.Talk, if talking then 1 else 0, if talking then 9 else 4, dt)
	local sinceLine = t - rig.EmotionAt
	if rig.Gesture and t >= rig.GestureUntil then
		rig.Gesture = nil
	end
	local talk = rig.Talk
	local acting = actionPlaying(rig)
	local inConversation = conversation and (listeners[rig.Model] or rig.Model == speaker)
	local attrWork = rig.Model:GetAttribute("Work")

	-- Lo que hace mientras espera (solo de pie, parado, sin tarea ni charla)
	local calm = not rig.Me
		and not talking
		and talk < 0.05
		and not inConversation
		and not acting
		and rig.Speed < 0.3
		and not seated
		and attrWork == nil
		and rig.Partner == nil
		and not rig.Model:GetAttribute("Chat")
	updateIdleAct(rig, t, calm)

	for _, name in POSE_NAMES do
		local want = if rig.Emotion == name and (talking or sinceLine < 2.5) then 1 else 0
		-- Asentir, negar, encogerse de hombros, aplaudir… son un gesto corto
		local short = SHORT[name]
		if short and sinceLine > short then
			want = 0
		end
		if rig.Gesture == name and t < rig.GestureUntil then
			want = 1
		end
		if rig.IdleAct == name then
			want = 1
		end
		rig.Poses[name] = smooth(rig.Poses[name] or 0, want, if rig.IdleAct == name then 2.5 else 5, dt)
	end
	local P = rig.Poses
	local seed = rig.Seed
	local busyArms = acting or rig.Speed > 0.8

	-- Su tarea (barrer, apuntar, cobrar…): la deja al hablar, al andar o al hacer un gesto. El móvil
	-- de mientras espera (IdleAct Phone) va igual, y se guarda antes de soltarlo.
	if rig.IdleWork and rig.IdleAct ~= "Phone" and rig.WorkW < 0.05 then
		rig.IdleWork = nil
	end
	local workName = if attrWork ~= nil then attrWork else rig.IdleWork
	local work = if rig.Me then nil else WorkAnim.get(workName)
	if workName ~= rig.WorkName then
		rig.WorkName = if type(workName) == "string" then workName else nil
		clearProps(rig)
		if work then
			makeProps(rig, work)
		end
	end
	local working = work ~= nil
		and not talking
		and talk < 0.05
		and not inConversation
		and not acting
		and (rig.Speed <= 0.8 or work.Walk == true)
		and (attrWork ~= nil or rig.IdleAct == "Phone")
	rig.WorkW = smooth(rig.WorkW, if working then 1 else 0, if working then 2.5 else 6, dt)
	rig.Attention = smooth(rig.Attention, if rig.Interested or rig.Partner then 1 else 0, 3, dt)
	local W = rig.WorkW
	local w = rig.WorkPose
	WorkAnim.clear(w)
	if work and W > 0.001 then
		work.Pose(t, seed, w)
	end
	showProps(rig, W > 0.5)
	-- Metido en su tarea casi no mira alrededor; si te acercas, levanta la vista
	local absorbed = W * (1 - w.Look) * (1 - rig.Attention)
	local lookMul = 1 - absorbed * 0.8
	local workNeck = W * (1 - 0.75 * rig.Attention)

	-- De pie sin hacer nada: carga el peso de un pie a otro (el torso se mece un poco, despacio)
	rig.Still = smooth(rig.Still, if rig.Speed < 0.3 and not seated and not rig.Me then 1 - talk * 0.6 else 0, 2, dt)
	local sway = math.sin(t * (TAU / (8 + seed % 4)) + seed) * rig.Still

	-- Cabeza
	local neckPitch = rig.Pitch * 0.8 * lookMul + w.np * workNeck + rig.SacPitch
	local neckYaw = rig.Yaw * 0.65 * lookMul + w.ny * workNeck + rig.SacYaw
	local neckRoll = w.nr * workNeck - sway * 0.02
	neckPitch += talk * (math.sin(t * 7.3 + seed) * 0.035 + math.sin(t * 11.1 + seed * 2) * 0.015)
	neckYaw += talk * math.sin(t * 3.4 + seed) * 0.045
	neckPitch += (P.Happy or 0) * (0.07 + math.abs(math.sin(t * 6)) * 0.04)
	neckPitch -= (P.Sad or 0) * 0.32
	neckPitch -= (P.Angry or 0) * 0.1
	neckPitch += (P.Surprised or 0) * 0.16
	neckPitch += (P.Thinking or 0) * 0.14
	neckRoll += (P.Thinking or 0) * 0.14 + (P.Ask or 0) * 0.17 * math.sign(math.sin(seed) + 0.01) + (P.Shrug or 0) * 0.12
	neckPitch += (P.Nod or 0) * math.sin(math.min(sinceLine, 1.6) * math.pi * 3.2) * 0.2
	neckYaw += (P.No or 0) * math.sin(math.min(sinceLine, 1.6) * math.pi * 3.6) * 0.28
	local facepalm = P.Facepalm or 0
	neckPitch -= facepalm * 0.24
	neckYaw += facepalm * math.sin(t * 5 + seed) * 0.07
	neckPitch += (P.ThinkChin or 0) * 0.1 + (P.ArmsCrossed or 0) * 0.03 + (P.Stretch or 0) * 0.3
	neckRoll += (P.ThinkChin or 0) * 0.1 + (P.HandsOnHips or 0) * 0.06

	-- Torso: respira, acompaña la mirada, se encoge si está triste
	local breath = math.sin(t * (TAU / (3.6 + (seed % 1.2))) + seed)
	local waistPitch = breath * 0.012 + rig.Pitch * 0.2 * lookMul - (P.Sad or 0) * 0.09 + (P.Surprised or 0) * 0.05 + (P.Angry or 0) * -0.04 + w.wp * W
	waistPitch += (P.ArmsCrossed or 0) * 0.03 + (P.HandsOnHips or 0) * 0.04 + (P.Stretch or 0) * 0.12 - facepalm * 0.05
	local waistYaw = rig.Yaw * 0.35 * lookMul + w.wy * W
	local waistRoll = w.wr * W + sway * 0.035

	-- Brazos (solo si no están andando ni haciendo un gesto de animación)
	local armWeight = if busyArms then 0 else 1
	local g = talk * (GESTURE[rig.Gesture or rig.Emotion] or 0.7) * armWeight
	local rX = g * (0.22 + 0.2 * math.sin(t * 2.1 + seed)) -- adelante
	local rZ = g * (0.1 + 0.08 * math.sin(t * 1.7 + seed)) -- hacia fuera
	local rElbow = g * (0.45 + 0.35 * math.sin(t * 2.6 + seed))
	local lX = g * (0.12 + 0.14 * math.sin(t * 1.9 + seed + 2))
	local lZ = g * (0.06 + 0.06 * math.sin(t * 1.3 + seed + 1))
	local lElbow = g * (0.3 + 0.25 * math.sin(t * 2.3 + seed + 2))
	local rTwist, lTwist = 0, 0
	local shoulderUp = breath * 0.015
	-- Posturas
	local think = (P.Thinking or 0) * armWeight
	rX += think * 0.9
	rElbow += think * 1.7
	local shrug = (P.Shrug or 0) * armWeight
	shoulderUp += shrug * 0.22
	rZ += shrug * 0.35
	lZ += shrug * 0.35
	rElbow += shrug * 0.9
	lElbow += shrug * 0.9
	local ask = (P.Ask or 0) * armWeight
	rZ += ask * 0.15
	lZ += ask * 0.15
	rElbow += ask * 0.5
	local surprised = (P.Surprised or 0) * armWeight
	rX += surprised * 0.35
	lX += surprised * 0.35
	rElbow += surprised * 0.8
	lElbow += surprised * 0.8
	local sad = (P.Sad or 0) * armWeight
	shoulderUp -= sad * 0.08
	local angry = (P.Angry or 0) * armWeight
	rElbow += angry * 0.4
	lElbow += angry * 0.4
	-- Posturas de brazos enteros: llevan el brazo a su sitio (manos donde deben, no sumadas)
	local crossed = (P.ArmsCrossed or 0) * armWeight
	if crossed > 0.001 then
		-- Brazos cruzados: el izquierdo por encima del derecho
		rX, rTwist, rZ, rElbow = mix(rX, 0.9, crossed), mix(rTwist, 1.4, crossed), mix(rZ, -0.8, crossed), mix(rElbow, 1.5, crossed)
		lX, lTwist, lZ, lElbow = mix(lX, 1.0, crossed), mix(lTwist, 1.3, crossed), mix(lZ, -0.8, crossed), mix(lElbow, 1.4, crossed)
	end
	local hips = (P.HandsOnHips or 0) * armWeight
	if hips > 0.001 then
		-- En jarras: manos en la cintura, codos hacia fuera
		rX, rTwist, rZ, rElbow = mix(rX, -0.7, hips), mix(rTwist, 0.6, hips), mix(rZ, 0.3, hips), mix(rElbow, 1.25, hips)
		lX, lTwist, lZ, lElbow = mix(lX, -0.7, hips), mix(lTwist, 0.6, hips), mix(lZ, 0.3, hips), mix(lElbow, 1.25, hips)
	end
	local chin = (P.ThinkChin or 0) * armWeight
	if chin > 0.001 then
		-- La mano en la barbilla y el otro brazo por delante sujetando el codo
		local tap = math.sin(t * 3.1 + seed) * 0.05
		rX, rTwist, rZ, rElbow = mix(rX, 1.4, chin), mix(rTwist, 1.0, chin), mix(rZ, -0.8, chin), mix(rElbow, 1.8 + tap, chin)
		lX, lTwist, lZ, lElbow = mix(lX, 0.5, chin), mix(lTwist, 1.3, chin), mix(lZ, -0.6, chin), mix(lElbow, 1.5, chin)
	end
	local palm = facepalm * armWeight
	if palm > 0.001 then
		-- La mano a la frente
		rX, rTwist, rZ, rElbow = mix(rX, 1.9, palm), mix(rTwist, 0.8, palm), mix(rZ, -0.8, palm), mix(rElbow, 1.4, palm)
	end
	local clap = (P.Clap or 0) * armWeight
	if clap > 0.001 then
		-- Aplaude: las manos se juntan delante del pecho una y otra vez
		local open = math.abs(math.sin(t * 7 + seed)) * 0.42
		rX, rTwist, rZ, rElbow = mix(rX, 1.1, clap), mix(rTwist, 0.4, clap), mix(rZ, -0.8 + open, clap), mix(rElbow, 0.6, clap)
		lX, lTwist, lZ, lElbow = mix(lX, 1.1, clap), mix(lTwist, 0.4, clap), mix(lZ, -0.8 + open, clap), mix(lElbow, 0.6, clap)
	end
	local wave = (P.WaveLite or 0) * armWeight
	if wave > 0.001 then
		-- Saludo corto: la mano arriba, moviéndola de lado a lado
		local side = math.sin(t * 9 + seed)
		rX, rTwist, rZ, rElbow = mix(rX, 1.2, wave), mix(rTwist, 0, wave), mix(rZ, 0.6 + side * 0.16, wave), mix(rElbow, 2.0 + side * 0.12, wave)
	end
	local stretch = (P.Stretch or 0) * armWeight
	if stretch > 0.001 then
		-- Se estira: los dos brazos arriba
		rX, rTwist, rZ, rElbow = mix(rX, 2.9, stretch), mix(rTwist, 0, stretch), mix(rZ, 0.05, stretch), mix(rElbow, 0.25, stretch)
		lX, lTwist, lZ, lElbow = mix(lX, 2.9, stretch), mix(lTwist, 0, stretch), mix(lZ, 0.05, stretch), mix(lElbow, 0.25, stretch)
		shoulderUp += stretch * 0.08
	end
	-- Tarea
	rX += w.rx * W
	rZ += w.rz * W
	rTwist += w.rt * W
	rElbow += w.re * W
	lX += w.lx * W
	lZ += w.lz * W
	lTwist += w.lt * W
	lElbow += w.le * W

	-- Aplicar (encima de la animación: C0 es la postura base de cada articulación)
	local J, B = rig.Joints, rig.Base
	J.Neck.C0 = B.Neck * CFrame.Angles(neckPitch, neckYaw, neckRoll)
	if J.Waist then
		J.Waist.C0 = B.Waist * CFrame.Angles(waistPitch, waistYaw, waistRoll)
	end
	if J.Root and not rig.Me then
		J.Root.C0 = B.Root * CFrame.Angles(0, rig.BodyYaw, 0)
	end
	if J.RightShoulder then
		J.RightShoulder.C0 = B.RightShoulder * CFrame.new(0, shoulderUp, 0) * CFrame.Angles(rX, rTwist, rZ)
	end
	if J.LeftShoulder then
		J.LeftShoulder.C0 = B.LeftShoulder * CFrame.new(0, shoulderUp, 0) * CFrame.Angles(lX, -lTwist, -lZ)
	end
	if J.RightElbow then
		J.RightElbow.C0 = B.RightElbow * CFrame.Angles(rElbow, 0, 0)
	end
	if J.LeftElbow then
		J.LeftElbow.C0 = B.LeftElbow * CFrame.Angles(lElbow, 0, 0)
	end
end

local function rest(rig: Rig)
	for name, joint in rig.Joints do
		joint.C0 = rig.Base[name]
	end
	-- Lejos no se ve: fuera objetos (se vuelven a poner al acercarte)
	clearProps(rig)
	rig.WorkName = nil
	rig.WorkW = 0
	rig.IdleAct = nil
	rig.IdleWork = nil
	rig.BodyYaw = 0
	rig.BodyGoal = nil
	-- (la animación de andar o de estar de pie sigue: la lleva el bucle lento de init)
end

-- Le han cambiado el tamaño (los compañeros crecen contigo): la postura base de cada articulación
-- se escala igual (C0 cambia de sitio, no de giro)
local function rescale(rig: Rig)
	local scale = scaleOf(rig.Model)
	if math.abs(scale - rig.Scale) < 0.005 then
		return
	end
	local ratio = scale / rig.Scale
	rig.Scale = scale
	for name, base in rig.Base do
		rig.Base[name] = base.Rotation + base.Position * ratio
	end
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------

-- El personaje de una escena tuya (o fijo del mapa) por su id del reparto ("Nico", "Abu"…)
function ActorLife.find(npcId: string): Model?
	local scenes = workspace:FindFirstChild("StoryScenes")
	local mine = scenes and scenes:FindFirstChild("Scene_" .. player.UserId)
	if mine then
		for _, model in mine:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("NpcId") == npcId then
				return model
			end
		end
	end
	for _, model in CollectionService:GetTagged("StaticNpc") do
		if model:IsA("Model") and model:GetAttribute("NpcId") == npcId then
			return model
		end
	end
	return nil
end

-- Todos los personajes de tu escena ahora mismo
function ActorLife.cast(): { Model }
	local list = {}
	local scenes = workspace:FindFirstChild("StoryScenes")
	local mine = scenes and scenes:FindFirstChild("Scene_" .. player.UserId)
	for _, model in if mine then mine:GetChildren() else {} do
		if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
			table.insert(list, model)
		end
	end
	return list
end

-- Un gesto de animación (Wave, Cheer, Laugh, Point, Dance) una vez
function ActorLife.play(model: Instance?, name: string, seconds: number?)
	if not model or not model:IsA("Model") or not ANIMS[name] then
		return
	end
	register(model)
	local rig = rigs[model]
	if not rig then
		return
	end
	local t = track(rig, name)
	if t then
		t:Play(0.2)
		if name == "Dance" then
			task.delay(seconds or 4, function()
				t:Stop(0.5)
			end)
		end
	end
end

-- Un gesto: de animación (Wave, Cheer, Laugh, Point, Dance) o de postura (Clap, Facepalm,
-- ArmsCrossed, HandsOnHips, ThinkChin, WaveLite… cualquiera de Emotion.Poses). Las posturas cortas
-- (aplaudir, saludar, la mano a la frente) duran lo suyo; las otras, `seconds` (2.5 si no se dice).
function ActorLife.gesture(model: Instance?, name: string?, seconds: number?)
	if not model or not model:IsA("Model") or type(name) ~= "string" then
		return
	end
	if Emotion.Animated[name] then
		ActorLife.play(model, name, seconds or 3)
		return
	end
	if not Emotion.Poses[name] or name == "Calm" then
		return
	end
	register(model)
	local rig = rigs[model]
	if not rig then
		return
	end
	local t = now()
	rig.Gesture = name
	rig.GestureAt = t
	rig.GestureUntil = t + (SHORT[name] or math.max(2.5, seconds or 2.5))
	rig.IdleAct = nil
end

-- Empieza o termina una conversación (la mirada de todos se organiza alrededor de quien habla)
function ActorLife.conversation(on: boolean)
	conversation = on
	-- Siempre de cero: quien habló en una escena de cámara o en otra charla no cuenta en esta
	speaker = nil
	table.clear(listeners)
end

-- Alguien dice una frase: mueve la cabeza y las manos durante `seconds`, con la emoción de la frase.
-- gesture (opcional): un gesto de encima a la vez (el campo Gesture de la línea, G en la misión)
function ActorLife.speak(model: Instance?, emotion: string?, seconds: number, gesture: string?)
	if not model or not model:IsA("Model") then
		return
	end
	register(model)
	local rig = rigs[model]
	-- Quién habla y quién escucha solo cuenta dentro de una conversación (DialogueUI). Las frases de
	-- las escenas de cámara (Cinematics) no dejan a nadie apuntado como oyente para después.
	if conversation then
		speaker = model
		listeners[model] = true
		local me = player.Character
		if me then
			listeners[me] = true
			register(me)
		end
	end
	if not rig then
		return
	end
	rig.Emotion = if emotion and (Emotion.Poses[emotion] or Emotion.Animated[emotion]) then emotion else "Calm"
	rig.EmotionAt = now()
	rig.TalkUntil = now() + math.max(0.8, seconds)
	rig.IdleAct = nil
	if emotion and Emotion.Animated[emotion] then
		ActorLife.play(model, emotion, 3)
		rig.Emotion = if emotion == "Laugh" or emotion == "Cheer" or emotion == "Dance" then "Happy" else "Calm"
	end
	if gesture and gesture ~= emotion then
		ActorLife.gesture(model, gesture, seconds)
	end
end

-- Deja de hablar (el jugador pasó la línea)
function ActorLife.quiet(model: Instance?)
	local rig = model and rigs[model :: Model]
	if rig then
		rig.TalkUntil = math.min(rig.TalkUntil, now())
	end
end

function ActorLife.init()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Humanoid") then
			consider(descendant)
		end
	end
	workspace.DescendantAdded:Connect(consider)

	-- Quién está cerca (cada medio segundo): solo esos se animan
	task.spawn(function()
		while true do
			task.wait(0.5)
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position or Vector3.zero
			local t = now()
			local list = {}
			for model, rig in rigs do
				if not model.Parent then
					rigs[model] = nil
					continue
				end
				local distance = (rig.Root.Position - from).Magnitude
				local wanted = distance < ACTIVE_DISTANCE
				if rig.Me then
					wanted = conversation or rig.Talk > 0.01
				end
				if wanted then
					table.insert(list, { Rig = rig, Distance = distance })
				elseif not rig.Active and rig.Own then
					-- Lejos (o fuera de los 32): sin gestos, pero si anda, anda con animación (no se desliza)
					if distance < AMBIENT_DISTANCE then
						local position = rig.Root.Position
						local since = t - rig.LastPosAt
						if rig.LastPos and since > 0 and since < 2 then
							rig.Speed = Vector3.new(position.X - rig.LastPos.X, 0, position.Z - rig.LastPos.Z).Magnitude / since
						else
							rig.Speed = 0
						end
						rig.LastPos = position
						rig.LastPosAt = t
						pcall(updateBase, rig, t)
					elseif rig.BaseAnim then
						pcall(setBase, rig, nil)
					end
				end
			end
			table.sort(list, function(a, b)
				return a.Distance < b.Distance
			end)
			local nextActive, keep = {}, {}
			for i, entry in list do
				if i > MAX_ACTIVE then
					break
				end
				table.insert(nextActive, entry.Rig)
				keep[entry.Rig] = true
			end
			for _, rig in active do
				if not keep[rig] and rig.Model.Parent then
					rig.Active = false
					pcall(rest, rig)
				end
			end
			for _, rig in nextActive do
				if not rig.Active then
					rig.Active = true
					-- La postura base se lee al empezar (quieto está como lo dejó el servidor: si le cambiaron
					-- el tamaño, se usa el nuevo)
					for name, joint in rig.Joints do
						rig.Base[name] = joint.C0
					end
					rig.Scale = scaleOf(rig.Model)
					rig.BodyWorld = headingOf(rig.Root.CFrame)
					-- Si otro ya le pone animaciones (el servidor), aquí no se le pone la base
					if rig.Own and next(rig.Tracks) == nil then
						local animator = rig.Humanoid:FindFirstChildOfClass("Animator")
						if animator and #animator:GetPlayingAnimationTracks() > 0 then
							rig.Own = false
						end
					end
				else
					pcall(rescale, rig)
				end
			end
			-- Entre el 33 y más allá: los que se quedaron fuera también se miden la próxima vez
			for i = MAX_ACTIVE + 1, #list do
				local rig = list[i].Rig
				if rig.Own and not rig.Active then
					local position = rig.Root.Position
					local since = t - rig.LastPosAt
					rig.Speed = if rig.LastPos and since > 0 and since < 2
						then Vector3.new(position.X - rig.LastPos.X, 0, position.Z - rig.LastPos.Z).Magnitude / since
						else 0
					rig.LastPos = position
					rig.LastPosAt = t
					pcall(updateBase, rig, t)
				end
			end
			active = nextActive
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local t = now()
		if #fades > 0 then
			stepFades(t)
		end
		for _, rig in active do
			if rig.Active and rig.Model.Parent then
				local ok, err = pcall(update, rig, t, dt)
				if not ok then
					warn("[ActorLife] " .. tostring(err))
					rig.Active = false
					pcall(rest, rig)
					rigs[rig.Model] = nil -- no se vuelve a intentar con este
				end
			end
		end
	end)

	-- Al reaparecer, tu personaje nuevo también
	player.CharacterAdded:Connect(function(character)
		task.delay(1, tryRegister, character, 0)
	end)
end

return ActorLife
