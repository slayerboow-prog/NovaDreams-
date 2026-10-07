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
--     aquí se desvanece y reaparece (los fijos del mapa ya los funde SceneClient). La gente de los
--     sitios (PlaceLifeService: atributos FadeIn / FadeOut) aparece y se va fundiéndose. Los actores
--     que dejan tu escena (SceneService: atributo FadeOut, al llegar a donde se iban) se desvanecen.
--   * Miradas en grupo: en una conversación TODO el reparto de tu escena que está cerca mira a quien
--     habla (no solo quien ya ha hablado). Quien habla mira a quien le habla: la línea puede decirlo
--     (To = "Sara"); si no, quien contesta a la pregunta de otro personaje le mira a él, y quien
--     comenta lo que dijo otro le mira un momento y luego te mira a ti (shared/LifeStory/ActorStaging).
--   * Escuchando no son estatuas: asienten un poco de vez en cuando, cargan el peso, apartan la vista
--     un instante… y según su emoción (ActorMoods: Nervous mira alrededor y se toca las manos, Shame
--     baja la cabeza y evita la mirada, Sad mira al suelo, Angry sostiene la mirada).
--   * Emociones (alegría, tristeza, enfado, sorpresa, nervios, vergüenza): postura, ritmo de los
--     gestos y mirada, sin exagerar (shared/LifeStory/ActorMoods: Tempo, Head, Open, Gaze, Fidget,
--     Recoil). La sorpresa da un paso atrás y se para.
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
local ActorMoods = require(ReplicatedStorage.Shared.LifeStory.ActorMoods)
local ActorStaging = require(ReplicatedStorage.Shared.LifeStory.ActorStaging)
local Joints = require(ReplicatedStorage.Shared.Joints)
local WorkAnim = require(script.Parent.WorkAnim)
local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)

-- ¿Está PunchAnim moviendo este cuerpo (golpe o guardia)? (se pide al usarlo: en las pruebas puede no estar)
local PunchAnim: any = false
local function punchBusy(model: Model): boolean
	if PunchAnim == false then
		local ok, mod = pcall(require, script.Parent.PunchAnim)
		PunchAnim = if ok and type(mod) == "table" then mod else nil
	end
	return PunchAnim ~= nil and PunchAnim.busy(model)
end

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
	Joints: { [string]: any }, -- Motor6D o AnimationConstraint (shared/Joints)
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
	RootJoint: any?, -- LowerTorso.Root: para girar el cuerpo entero sin mover la raíz
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
	NodAt: number, -- (escuchando) cuándo asiente la próxima vez
	NodStart: number, -- cuándo empezó el último asentimiento
	ListenGlanceAt: number, -- (escuchando) cuándo aparta la vista un instante
	ListenGlanceUntil: number,
	ListenGlance: Vector2?,
	Recoil: number, -- 0..1: paso atrás de la sorpresa (suave)
	Phase: number, -- reloj de los gestos al hablar (va al ritmo de la emoción)
}

local rigs: { [Model]: Rig } = {}
local active: { Rig } = {}
local waiting: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- esperando a que llegue entero

-- Conversación en curso
local conversation = false
local speaker: Model? = nil
local listeners: { [Model]: boolean } = {}
-- A quién habla quien habla ahora (To de la línea o lo que se deduce: ActorStaging.addressee) y a quién
-- mira un momento al empezar (al que acaba de hablar)
local addressee: Model? = nil -- nil = a ti
local ackModel: Model? = nil
local ackUntil = 0
local lastLine: { Model: Model, Question: boolean, At: number, Me: boolean }? = nil
-- Lo que pide la conversación escenificada (DialogueUI → ActorLife.stageGaze): a quién habla la línea
-- (To: manda sobre lo deducido) y una mirada de un momento de quien habla ("Down" / "Away")
local stageTo: any = nil -- nil (no lo dice) · "Player" · el modelo
local stageLook: string? = nil
local stageLookUntil = 0

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

type Fade = { Model: Model, Parts: { Instance }, From: number, To: number, Start: number, Seconds: number, Done: (() -> ())? }
local fades: { Fade } = {}
local fadeWatched: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function fadeModel(model: Model, from: number, to: number, seconds: number, onDone: (() -> ())?)
	-- Un fundido nuevo sustituye al que tuviera a medias (se iba y vuelve: no se pelean)
	for i = #fades, 1, -1 do
		if fades[i].Model == model then
			table.remove(fades, i)
		end
	end
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			table.insert(parts, d)
		end
	end
	table.insert(fades, { Model = model, Parts = parts, From = from, To = to, Start = os.clock(), Seconds = seconds, Done = onDone })
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
		if model:GetAttribute("FadeOut") then
			return -- (se está yendo: ya se desvanece)
		end
		fadeModel(model, 0, 1, 0.3, function()
			task.delay(0.1, function()
				if model.Parent and not model:GetAttribute("FadeOut") then
					fadeModel(model, 1, 0, 0.4)
				end
			end)
		end)
	end)
	-- Deja tu escena (SceneService): se desvanece donde está y el servidor lo quita. Si el paso siguiente
	-- le vuelve a necesitar mientras tanto, reaparece
	model:GetAttributeChangedSignal("FadeOut"):Connect(function()
		if model:GetAttribute("FadeOut") then
			fadeModel(model, 0, 1, ActorStaging.FadeSeconds)
		else
			fadeModel(model, 1, 0, 0.4)
		end
	end)
	if model:GetAttribute("FadeOut") then
		fadeModel(model, 0, 1, 0.2) -- (llegó a tu pantalla cuando ya se iba)
	end
end

-- ¿Se está yendo de tu escena? (ya no es del reparto: ni habla ni le miran)
local function isLeaving(model: Instance?): boolean
	return model ~= nil and model:GetAttribute("Leaving") == true
end

-- Sus articulaciones: Motor6D o AnimationConstraint (las articulaciones nuevas de Roblox: su C0 es el
-- CFrame de Attachment0; shared/Joints). Antes solo Motor6D: con las nuevas no respiraban, ni
-- miraban, ni gesticulaban. Root: la de la cadera con la raíz (gira todo el cuerpo), en LowerTorso.
local function rigJoints(model: Model): ({ [string]: any }, any?)
	local joints = {}
	for _, name in JOINTS do
		joints[name] = Joints.find(model, name)
	end
	local rootJoint = Joints.find(model, "Root", "LowerTorso")
	if rootJoint and Joints.part1(rootJoint) == model:FindFirstChild("LowerTorso") then
		joints.Root = rootJoint
	else
		rootJoint = nil
	end
	return joints, rootJoint
end

-- Al aplicar el aspecto (AvatarService, al aparecer y al cambiar de edad) Roblox cambia las piezas
-- del cuerpo y con ellas las articulaciones: las viejas ya no mueven nada. Se vuelven a buscar.
-- Devuelve true si ha cambiado algo.
local function refreshJoints(rig: any): boolean
	if not Joints.stale(rig.Joints, rig.Model) then
		return false
	end
	local joints, rootJoint = rigJoints(rig.Model)
	if not joints.Neck then
		return false
	end
	rig.Joints, rig.RootJoint = joints, rootJoint
	rig.Hip = Joints.find(rig.Model, "LeftHip") or rig.Model:FindFirstChild("LeftHip", true)
	return true
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
	local joints, rootJoint = rigJoints(model)
	if not joints.Neck or punchBusy(model) then
		return "wait" -- (a media animación de PunchAnim sus C0 no son la postura base)
	end
	local base = {}
	for name, joint in joints do
		base[name] = Joints.c0(joint)
	end
	local t = now()
	local rig: Rig = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Head = head,
		Joints = joints,
		Base = base,
		Hip = Joints.find(model, "LeftHip") or model:FindFirstChild("LeftHip", true),
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
		RootJoint = rootJoint,
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
		NodAt = t + 2 + math.random() * 3,
		NodStart = -10,
		ListenGlanceAt = t + 4 + math.random() * 5,
		ListenGlanceUntil = 0,
		ListenGlance = nil,
		Recoil = 0,
		Phase = t,
	}
	WorkAnim.clear(rig.WorkPose)
	rigs[model] = rig
	waiting[model] = nil
	if isScene(model) then
		watchFade(model)
	end
	-- Gente de los sitios (PlaceLifeService): aparece fundiéndose y se va igual (nadie de golpe)
	if model:GetAttribute("FadeIn") then
		fadeModel(model, 1, 0, 0.7)
		model:GetAttributeChangedSignal("FadeOut"):Connect(function()
			if model:GetAttribute("FadeOut") then
				fadeModel(model, 0, 1, 0.6)
			end
		end)
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
	-- Correr empieza por encima de 13 y se deja por debajo de 12 (con un solo umbral parpadeaba entre
	-- andar y correr; los de Speed 14 corren y los de 12 andan). BaseAnim recuerda si ya iba corriendo.
	local runFrom = (if rig.BaseAnim == "Run" then 12 else 13) * scale
	if sitting(rig) then
		setBase(rig, nil)
	elseif rig.Speed > runFrom then
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
-- Escenas de la historia: el servidor dice a quién mira un actor con su atributo LookAt (Vector3,
-- "Player", el id del reparto o "Key:<clave de la escena>"). Lo que no sabe resolver aquí (la Grieta,
-- los actores por clave) lo resuelve quien se registre (Controllers/HappeningClient).
local lookResolver: ((any) -> Vector3?)? = nil
function ActorLife.setLookResolver(fn: ((any) -> Vector3?)?)
	lookResolver = fn
end
local function lookAtAttribute(rig: Rig): Vector3?
	local target = rig.Model:GetAttribute("LookAt")
	if target == nil then
		return nil
	end
	if typeof(target) == "Vector3" then
		return target
	elseif target == "Player" then
		return headPosition(player.Character)
	end
	if lookResolver then
		local ok, point = pcall(lookResolver, target)
		if ok and point then
			return point
		end
	end
	if type(target) == "string" then
		return headPosition(ActorLife.find(target))
	end
	return nil
end

-- ¿Es de TU escena? (los actores de tu historia)
local function isMine(model: Instance): boolean
	local scenes = workspace:FindFirstChild("StoryScenes")
	local mine = scenes and scenes:FindFirstChild("Scene_" .. player.UserId)
	return mine ~= nil and model:IsDescendantOf(mine)
end

-- ¿Está en la conversación? Quien habla, quien ya ha hablado (y tú) y, además, todo el reparto de tu
-- escena que esté cerca de quien habla: en una conversación todos miran a quien habla
local function inTalk(rig: Rig): boolean
	if not conversation then
		return false
	end
	if rig.Model == speaker or listeners[rig.Model] then
		return true
	end
	if rig.Me or not speaker or not speaker.Parent or isLeaving(rig.Model) or not isMine(rig.Model) then
		return false
	end
	local at = headPosition(speaker)
	return at ~= nil and (at - rig.Head.Position).Magnitude < ActorStaging.GroupRadius
end

-- La emoción con la que actúa ahora: la que dura (atributo Mood) o, mientras dice su frase, la de la frase
local function actingOf(rig: Rig, t: number): ActorMoods.Acting
	local mood = rig.Model:GetAttribute("Mood")
	if mood == nil and t < rig.TalkUntil + 0.5 then
		mood = ActorMoods.fromPose(rig.Gesture) or ActorMoods.fromPose(rig.Emotion)
	end
	return ActorMoods.acting(mood)
end

-- Cómo cambia la mirada con la emoción (mirando a alguien): devuelve (yaw extra, pitch extra)
local function moodGaze(rig: Rig, acting: ActorMoods.Acting, t: number): (number, number)
	local side = if math.sin(rig.Seed * 7.3) >= 0 then 1 else -1
	local gaze = acting.Gaze
	local yaw, pitch = 0, acting.Head
	if gaze == "Avoid" then
		-- Vergüenza: aparta la mirada y baja la cabeza; de vez en cuando levanta los ojos un instante
		if math.sin(t * 0.8 + rig.Seed) < 0.8 then
			yaw += math.rad(24) * side
			pitch -= 0.12
		end
	elseif gaze == "Down" then
		if math.sin(t * 0.6 + rig.Seed) < 0.5 then
			pitch -= 0.08
		end
	end
	return yaw, pitch
end

-- Escuchando: de vez en cuando aparta la vista un instante (con nervios, a menudo y alrededor)
local function listenGlance(rig: Rig, acting: ActorMoods.Acting, t: number): Vector2?
	if acting.Gaze == "Hold" then
		return nil -- (enfadado: sostiene la mirada)
	end
	if t > rig.ListenGlanceAt then
		local around = acting.Gaze == "Around"
		rig.ListenGlanceAt = t + (if around then 1.2 + math.random() * 1.6 else 4 + math.random() * 6)
		if around or math.random() < 0.6 then
			local spread = if around then math.random(25, 60) else math.random(12, 30)
			rig.ListenGlance = Vector2.new(math.rad(spread) * (if math.random() < 0.5 then -1 else 1), math.rad(math.random(-8, 4)))
			rig.ListenGlanceUntil = t + (if around then 0.45 + math.random() * 0.4 else 0.6 + math.random() * 0.5)
		end
	end
	if t < rig.ListenGlanceUntil then
		return rig.ListenGlance
	end
	return nil
end

local function lookTarget(rig: Rig, t: number): (number, number, boolean)
	local talkingHere = inTalk(rig)
	local forced = not rig.Me and not talkingHere and lookAtAttribute(rig)
	if forced then
		local yaw, pitch = aim(rig, forced)
		if yaw then
			return yaw, math.clamp(pitch :: number, -math.rad(35), math.rad(40)), true
		end
	end
	local myHead = headPosition(player.Character)
	-- En una conversación: quien habla mira a quien le habla (a ti, o al personaje al que contesta);
	-- todos los demás miran a quien habla
	if talkingHere then
		local target: Vector3? = nil
		local acting = actingOf(rig, t)
		if rig.Model == speaker then
			if rig.Me then
				-- Tú contestas a quien te ha hablado (o al primero que escucha)
				target = headPosition(addressee)
				if not target then
					for other in listeners do
						if other ~= rig.Model then
							target = headPosition(other)
							break
						end
					end
				end
			else
				if stageTo == "Player" then
					target = myHead -- (la línea dice que te habla a ti)
				elseif typeof(stageTo) == "Instance" and stageTo ~= rig.Model then
					target = headPosition(stageTo)
				elseif ackModel and t < ackUntil then
					target = headPosition(ackModel) -- (mira un momento al que acaba de hablar)
				end
				target = target or headPosition(addressee) or myHead
				-- La línea pide una mirada de un momento: al suelo o a otro lado
				if stageLook and t < stageLookUntil then
					local yaw0, pitch0 = aim(rig, target)
					if yaw0 then
						if stageLook == "Down" then
							return yaw0 * 0.5, -math.rad(28), true
						end
						return yaw0 + math.rad(35) * (if math.sin(rig.Seed) >= 0 then 1 else -1), -math.rad(4), true
					end
				end
			end
			-- Al hablar a veces se aparta la mirada un momento (pensando lo que dice); enfadado, no
			if acting.Gaze ~= "Hold" and math.sin(t * 0.9 + rig.Seed) > 0.93 then
				return rig.BodyYaw + math.rad(18) * math.sign(math.sin(rig.Seed)), math.rad(6), true
			end
		else
			target = headPosition(speaker)
		end
		if target then
			local yaw, pitch = aim(rig, target)
			if yaw then
				local yawMood, pitchMood = 0, 0
				if not rig.Me then
					yawMood, pitchMood = moodGaze(rig, acting, t)
					if rig.Model ~= speaker then
						local glance = listenGlance(rig, acting, t)
						if glance then
							yawMood += glance.X
							pitchMood += glance.Y
						end
					end
				end
				return yaw + yawMood, math.clamp((pitch :: number) + pitchMood, -math.rad(35), math.rad(30)), true
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
	"Scared", "Hurt", -- (las de las emociones que duran: atributo Mood, shared/LifeStory/ActorMoods)
	"Nervous", "Ashamed", -- (nervios y vergüenza: frase o emoción que dura)
}
-- Gestos cortos: duran esto (segundos) desde que empieza la frase o el gesto
local SHORT = { Nod = 1.6, No = 1.6, Shrug = 1.6, Clap = 1.9, WaveLite = 1.8, Facepalm = 2.4 }

-- Cuánto mueven las manos al hablar según la emoción
local GESTURE = {
	Calm = 0.7, Happy = 1, Sad = 0.3, Angry = 1.3, Surprised = 0.8, Thinking = 0.25, Ask = 0.8, Shrug = 0.6, Nod = 0.5, No = 0.7,
	ArmsCrossed = 0.15, HandsOnHips = 0.2, Facepalm = 0.2, Clap = 0.2, ThinkChin = 0.2, WaveLite = 0.5,
	Nervous = 0.35, Ashamed = 0.2,
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
	local inConversation = inTalk(rig)
	-- Escuchando (en la conversación sin ser quien habla): asiente de vez en cuando, poco
	local listening = inConversation and rig.Model ~= speaker and not rig.Me and not talking
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
		and rig.Model:GetAttribute("Mood") == nil
	updateIdleAct(rig, t, calm)

	-- La emoción que dura (escenas: atributo Mood): su postura se queda puesta (algo menos al hablar)
	local moodName = rig.Model:GetAttribute("Mood")
	local mood = ActorMoods.get(moodName)
	local moodPose = mood and mood.Pose
	-- Cómo actúa con su emoción (la que dura o la de la frase): ritmo, postura abierta o cerrada, inquietud
	local moodActing = actingOf(rig, t)
	-- El ritmo de cabeza y manos al hablar: un reloj propio que corre más o menos deprisa según la
	-- emoción (sin saltos al cambiar de frase)
	rig.Phase += dt * moodActing.Tempo
	local tg = rig.Phase
	for _, name in POSE_NAMES do
		local want = if rig.Emotion == name and (talking or sinceLine < 2.5) then 1 else 0
		if moodPose == name then
			want = math.max(want, if talking then 0.65 else 1)
		end
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
	-- Nervios: cambia el peso de pierna más a menudo
	sway += moodActing.Fidget * math.sin(t * 1.9 + seed * 3) * 0.6 * rig.Still

	-- Cabeza
	local neckPitch = rig.Pitch * 0.8 * lookMul + w.np * workNeck + rig.SacPitch
	local neckYaw = rig.Yaw * 0.65 * lookMul + w.ny * workNeck + rig.SacYaw
	local neckRoll = w.nr * workNeck - sway * 0.02
	neckPitch += talk * (math.sin(tg * 7.3 + seed) * 0.035 + math.sin(tg * 11.1 + seed * 2) * 0.015)
	neckYaw += talk * math.sin(tg * 3.4 + seed) * 0.045
	-- Escuchando: un asentimiento pequeño de vez en cuando (enfadado no; triste, más despacio)
	if listening and moodActing.Gaze ~= "Hold" and t > rig.NodAt then
		rig.NodStart = t
		rig.NodAt = t + (3 + math.random() * 4) / math.max(0.5, moodActing.Tempo)
	end
	local nodT = t - rig.NodStart
	if nodT < 0.8 then
		neckPitch -= math.sin(nodT / 0.8 * math.pi * 2) ^ 2 * 0.06
	end
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

	-- Nervios (se toca las manos, hombros algo subidos) y vergüenza (cabeza baja, mirada a un lado,
	-- encogido): poco, sin exagerar
	local nervous = P.Nervous or 0
	local ashamed = P.Ashamed or 0
	local shameSide = if math.sin(seed * 7.3) >= 0 then 1 else -1
	neckPitch -= nervous * 0.04 + ashamed * 0.2
	neckYaw += ashamed * 0.12 * shameSide
	waistPitch += ashamed * 0.04 + nervous * 0.015
	-- Postura abierta (alegría, sorpresa) o cerrada (tristeza, vergüenza, nervios)
	waistPitch -= moodActing.Open * 0.025

	-- Emociones que duran: miedo (encogido, temblando) y herido (doblado, la cabeza baja)
	local scared = P.Scared or 0
	local hurt = P.Hurt or 0
	local shiver = ActorMoods.tremble(moodName, t, seed)
	neckPitch += -scared * 0.18 - hurt * 0.26 + shiver
	neckYaw += shiver * 0.6
	waistPitch += scared * 0.1 + hurt * 0.16
	waistRoll += hurt * 0.07 + shiver * 0.5

	-- Brazos (solo si no están andando ni haciendo un gesto de animación)
	local armWeight = if busyArms then 0 else 1
	local g = talk * (GESTURE[rig.Gesture or rig.Emotion] or 0.7) * armWeight
	local rX = g * (0.22 + 0.2 * math.sin(tg * 2.1 + seed)) -- adelante
	local rZ = g * (0.1 + 0.08 * math.sin(tg * 1.7 + seed)) -- hacia fuera
	local rElbow = g * (0.45 + 0.35 * math.sin(tg * 2.6 + seed))
	local lX = g * (0.12 + 0.14 * math.sin(tg * 1.9 + seed + 2))
	local lZ = g * (0.06 + 0.06 * math.sin(tg * 1.3 + seed + 1))
	local lElbow = g * (0.3 + 0.25 * math.sin(tg * 2.3 + seed + 2))
	-- Abierta: los brazos algo separados del cuerpo; cerrada: pegados
	rZ += moodActing.Open * 0.05 * armWeight
	lZ += moodActing.Open * 0.05 * armWeight
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
	local cower = scared * armWeight
	if cower > 0.001 then
		-- Miedo: las manos delante de la cara, los hombros arriba
		rX, rTwist, rZ, rElbow = mix(rX, 1.1, cower), mix(rTwist, 0.5, cower), mix(rZ, -0.35, cower), mix(rElbow, 1.9, cower)
		lX, lTwist, lZ, lElbow = mix(lX, 1.1, cower), mix(lTwist, 0.5, cower), mix(lZ, -0.35, cower), mix(lElbow, 1.9, cower)
		shoulderUp += cower * 0.16
	end
	local ache = hurt * armWeight
	if ache > 0.001 then
		-- Herido: una mano al costado, el otro brazo cuelga
		rX, rTwist, rZ, rElbow = mix(rX, 0.35, ache), mix(rTwist, 0.9, ache), mix(rZ, -0.45, ache), mix(rElbow, 1.35, ache)
		lX, lZ, lElbow = mix(lX, 0.05, ache), mix(lZ, 0.02, ache), mix(lElbow, 0.1, ache)
		shoulderUp -= ache * 0.06
	end
	local fidget = nervous * armWeight
	if fidget > 0.001 then
		-- Nervios: las manos juntas delante, frotándose un poco
		local rub = math.sin(t * 6 + seed) * 0.06
		rX, rTwist, rZ, rElbow = mix(rX, 0.55, fidget), mix(rTwist, 0.9, fidget), mix(rZ, -0.45 + rub, fidget), mix(rElbow, 1.25, fidget)
		lX, lTwist, lZ, lElbow = mix(lX, 0.55, fidget), mix(lTwist, 0.9, fidget), mix(lZ, -0.45 - rub, fidget), mix(lElbow, 1.25, fidget)
		shoulderUp += fidget * 0.04
	end
	local shy = ashamed * armWeight
	if shy > 0.001 then
		-- Vergüenza: los brazos pegados al cuerpo, los hombros caídos
		rZ -= shy * 0.08
		lZ -= shy * 0.08
		shoulderUp -= shy * 0.04
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

	-- Aplicar (encima de la animación: C0 es la postura base de cada articulación). Mientras da un
	-- golpe o tiene la guardia puesta, esas C0 las mueve PunchAnim: si las escribiéramos aquí también,
	-- según el orden del frame se borraba el puñetazo (en tu pantalla casi no se veían tus golpes)
	if punchBusy(rig.Model) then
		return
	end
	local J, B = rig.Joints, rig.Base
	Joints.setC0(J.Neck, B.Neck * CFrame.Angles(neckPitch, neckYaw, neckRoll))
	if J.Waist then
		Joints.setC0(J.Waist, B.Waist * CFrame.Angles(waistPitch, waistYaw, waistRoll))
	end
	if J.Root and not rig.Me then
		-- Sorpresa: retrocede un poco y se para (solo en tu pantalla; poco)
		rig.Recoil = smooth(rig.Recoil, if (P.Surprised or 0) > 0.3 and not seated then 1 else 0, if (P.Surprised or 0) > 0.3 then 9 else 2, dt)
		Joints.setC0(J.Root, B.Root * CFrame.new(0, 0, rig.Recoil * 0.3 * rig.Scale) * CFrame.Angles(0, rig.BodyYaw, 0))
	end
	if J.RightShoulder then
		Joints.setC0(J.RightShoulder, B.RightShoulder * CFrame.new(0, shoulderUp, 0) * CFrame.Angles(rX, rTwist, rZ))
	end
	if J.LeftShoulder then
		Joints.setC0(J.LeftShoulder, B.LeftShoulder * CFrame.new(0, shoulderUp, 0) * CFrame.Angles(lX, -lTwist, -lZ))
	end
	if J.RightElbow then
		Joints.setC0(J.RightElbow, B.RightElbow * CFrame.Angles(rElbow, 0, 0))
	end
	if J.LeftElbow then
		Joints.setC0(J.LeftElbow, B.LeftElbow * CFrame.Angles(lElbow, 0, 0))
	end
end

local function rest(rig: Rig)
	for name, joint in rig.Joints do
		Joints.setC0(joint, rig.Base[name])
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
			if model:IsA("Model") and model:GetAttribute("NpcId") == npcId and not isLeaving(model) then
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
		if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and not isLeaving(model) then
			table.insert(list, model)
		end
	end
	return list
end

-- Gestos que mueven también las piernas (sentado no se pueden hacer)
local FULL_BODY = { Cheer = true, Laugh = true, Dance = true }
-- Cuántos bailes ha empezado cada uno (para que parar uno viejo no corte el nuevo)
local danceIds: { [Rig]: number } = setmetatable({}, { __mode = "k" }) :: any
-- Posturas de UsePose en las que está sentado o tumbado (en las otras, grifo, nevera…, está de pie)
local SEATED_POSES = { Sit = true, Sofa = true, Lie = true, Type = true, Piano = true }

local function seated(rig: Rig): boolean
	local pose = rig.Model:GetAttribute("UsePose")
	if rig.Humanoid.Sit or rig.Model:GetAttribute("Seated") or (type(pose) == "string" and SEATED_POSES[pose]) then
		return true
	end
	-- Npc.sit dobla las piernas y guarda la postura original
	return rig.Hip ~= nil and rig.Hip:GetAttribute("BaseC0") ~= nil
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
	-- Sentado, las de cuerpo entero (celebrar, reírse, bailar) le ponían de pie en la silla: celebrar
	-- se cambia por aplaudir (solo brazos) y las otras no se hacen
	if FULL_BODY[name] and seated(rig) then
		if name == "Cheer" then
			ActorLife.gesture(model, "Clap")
		end
		return
	end
	local t = track(rig, name)
	if t then
		t:Play(0.2)
		if name == "Dance" then
			-- Solo lo para el último baile: si baila otra vez antes, el aviso del anterior no lo corta
			local id = (danceIds[rig] or 0) + 1
			danceIds[rig] = id
			task.delay(seconds or 4, function()
				if danceIds[rig] == id then
					t:Stop(0.5)
				end
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
	addressee = nil
	ackModel = nil
	ackUntil = 0
	lastLine = nil
	stageTo, stageLook, stageLookUntil = nil, nil, 0
end

-- A quién habla una línea: To = modelo, id del reparto ("Sara") o "Player"/"Jugador" (a ti). nil si a ti.
local function resolveTo(to: any): any
	if typeof(to) == "Instance" then
		return if to == player.Character then "Player" else to
	end
	if type(to) ~= "string" or to == "" then
		return nil
	end
	if ActorStaging.isPlayer(to) then
		return "Player"
	end
	return ActorLife.find(to) or "Player"
end

-- Apunta quién habla y a quién (ActorStaging.addressee): la mirada de todos se ordena con esto
local function noteLine(model: Model, emotion: string?, to: any, text: string?)
	local t = now()
	local me = player.Character
	local isMe = model == me
	local prev = if lastLine and lastLine.Model.Parent
		then { Speaker = lastLine.Model, Question = lastLine.Question, IsPlayer = lastLine.Me, Since = t - lastLine.At }
		else nil
	addressee, ackModel, ackUntil = nil, nil, 0
	if isMe then
		-- Tú le contestas a quien te ha hablado
		local target = resolveTo(to)
		addressee = if typeof(target) == "Instance" then target elseif prev and not prev.IsPlayer then prev.Speaker else nil
	else
		local target, ack, ackSeconds = ActorStaging.addressee({ Speaker = model, To = resolveTo(to) }, prev)
		if typeof(target) == "Instance" and target ~= model then
			addressee = target
		end
		if typeof(ack) == "Instance" and ack ~= model then
			ackModel, ackUntil = ack, t + ackSeconds
		end
	end
	lastLine = { Model = model, Question = ActorStaging.isQuestion(emotion, text), At = t, Me = isMe }
end

-- La conversación escenificada (DialogueUI) dice quién habla, a quién y si mira un momento a otro
-- sitio: speakerId = id del reparto o "Player" (todo el reparto cercano le mira); to = a quién habla
-- ("Player"/"Yo" o un id); look = "Down" / "Away" (un momento). Todo nil: se acabó la conversación.
-- (Los mismos datos van en los atributos del jugador StageSpeaker / StageTo / StageGaze.)
function ActorLife.stageGaze(speakerId: string?, to: string?, look: string?)
	if speakerId == nil and to == nil and look == nil then
		stageTo, stageLook, stageLookUntil = nil, nil, 0
		return
	end
	if conversation and type(speakerId) == "string" then
		local model = if ActorStaging.isPlayer(speakerId) then player.Character else ActorLife.find(speakerId)
		if model then
			speaker = model
			listeners[model] = true
		end
	end
	stageTo = resolveTo(to)
	if typeof(stageTo) == "Instance" then
		listeners[stageTo] = true
	end
	stageLook = if look == "Down" or look == "Away" then look else nil
	stageLookUntil = if stageLook then now() + 1.6 else 0
end

-- Alguien dice una frase: mueve la cabeza y las manos durante `seconds`, con la emoción de la frase.
-- gesture (opcional): un gesto de encima a la vez (el campo Gesture de la línea, G en la misión)
-- to (opcional): a quién le habla (To de la línea: "Sara", "Player"…; si no, se deduce)
-- text (opcional): la frase (para saber si es una pregunta: quien conteste mirará a quien pregunta)
function ActorLife.speak(model: Instance?, emotion: string?, seconds: number, gesture: string?, to: any?, text: string?)
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
		pcall(noteLine, model, emotion, to, text)
		if addressee then
			listeners[addressee] = true
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
	-- Los saltos del jugador de la historia, tapados con un fundido (Controllers/SceneDip)
	task.spawn(function()
		local ok, err = pcall(function()
			require(script.Parent.SceneDip).init()
		end)
		if not ok then
			warn("[ActorLife] SceneDip: " .. tostring(err))
		end
	end)
	-- Los actores de tu escena (también los que no se animan: lejos, sin cuerpo R15) se desvanecen al irse
	task.spawn(function()
		local scenes = workspace:WaitForChild("StoryScenes", 60)
		if not scenes then
			return
		end
		local function watch(child: Instance)
			if child:IsA("Model") then
				watchFade(child)
			end
		end
		local function watchFolder(folder: Instance)
			if folder.Name ~= "Scene_" .. player.UserId then
				return
			end
			for _, child in folder:GetChildren() do
				watch(child)
			end
			folder.ChildAdded:Connect(watch)
		end
		for _, folder in scenes:GetChildren() do
			watchFolder(folder)
		end
		scenes.ChildAdded:Connect(watchFolder)
	end)
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
					refreshJoints(rig)
					-- La postura base se lee al empezar (quieto está como lo dejó el servidor: si le cambiaron
					-- el tamaño, se usa el nuevo). Con la guardia puesta no: los brazos en guardia se quedarían
					-- como su postura de descanso; entonces se deja la que tenía
					-- Lo mismo si PunchAnim lo está moviendo (un golpe, apuntar…): sus C0 no son la base
					local owner = if rig.Me then player else nil
					local blocking = rig.Model:GetAttribute("Blocking") == true
						or (owner ~= nil and owner:GetAttribute("Blocking") == true)
					if blocking or punchBusy(rig.Model) then
						pcall(rescale, rig) -- (la de antes, al tamaño de ahora)
					else
						for name, joint in rig.Joints do
							rig.Base[name] = Joints.c0(joint)
						end
						rig.Scale = scaleOf(rig.Model)
					end
					rig.BodyWorld = headingOf(rig.Root.CFrame)
					-- Si otro ya le pone animaciones (el servidor), aquí no se le pone la base
					if rig.Own and next(rig.Tracks) == nil then
						local animator = rig.Humanoid:FindFirstChildOfClass("Animator")
						if animator and #animator:GetPlayingAnimationTracks() > 0 then
							rig.Own = false
						end
					end
				elseif refreshJoints(rig) then
					-- Piezas nuevas: su C0 de ahora es su postura base (nadie las ha tocado aún). Si PunchAnim
					-- lo está moviendo, solo las que no tenían base (las demás llevan su golpe)
					local moving = punchBusy(rig.Model)
					for name, joint in rig.Joints do
						if not moving or rig.Base[name] == nil then
							rig.Base[name] = Joints.c0(joint)
						end
					end
					rig.Scale = scaleOf(rig.Model)
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

-- Para las pruebas (scripts/test-joints.luau)
ActorLife._rigJoints = rigJoints

return ActorLife
