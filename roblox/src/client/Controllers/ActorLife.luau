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
--
-- La usan DialogueUI (quién habla y con qué emoción) y Cinematics (gestos en las escenas de cámara).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Emotion = require(ReplicatedStorage.Shared.LifeStory.Emotion)

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
local JOINTS = { "Neck", "Waist", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow" }

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
}

local rigs: { [Model]: Rig } = {}
local active: { Rig } = {}

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

local function register(model: Model)
	if rigs[model] then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	if not humanoid or not root or not head or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	local owner = Players:GetPlayerFromCharacter(model)
	if owner and owner ~= player then
		return -- los avatares de otros jugadores ya tienen sus animaciones
	end
	if othersScene(model) then
		return
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
		return
	end
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
		IdleAltAt = now() + math.random(8, 25),
		LastPos = nil,
		Speed = 0,
		Yaw = 0,
		Pitch = 0,
		Talk = 0,
		TalkUntil = 0,
		Emotion = "Calm",
		EmotionAt = 0,
		Poses = {},
		GlanceAt = now() + math.random() * 3,
		Glance = nil,
		InterestAt = 0,
		Interested = false,
		ChatAt = now() + math.random() * 3,
		Partner = nil,
	}
	rigs[model] = rig
	model.AncestryChanged:Connect(function(_, parent)
		if parent == nil and rigs[model] then
			rigs[model] = nil
		end
	end)
end

local function consider(instance: Instance)
	if instance:IsA("Humanoid") then
		local model = instance.Parent
		if model and model:IsA("Model") then
			-- Esperar a que llegue el cuerpo entero (el mapa se carga por trozos)
			task.delay(0.5, function()
				if model.Parent then
					register(model)
				end
			end)
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
	-- Npc.sit dobla las piernas y guarda la postura original
	return rig.Hip ~= nil and rig.Hip:GetAttribute("BaseC0") ~= nil
end

local function updateBase(rig: Rig, t: number)
	if not rig.Own then
		return
	end
	if sitting(rig) then
		setBase(rig, nil)
	elseif rig.Speed > 13 then
		setBase(rig, "Run", math.clamp(rig.Speed / 18, 0.7, 1.4))
	elseif rig.Speed > 0.8 then
		setBase(rig, "Walk", math.clamp(rig.Speed / 11, 0.5, 1.6))
	elseif rig.BaseAnim == "Idle2" then
		local alt = rig.Tracks.Idle2
		if not alt or not alt.IsPlaying then
			setBase(rig, "Idle")
		end
	elseif t > rig.IdleAltAt and not conversation then
		-- De vez en cuando cambian de postura / miran alrededor
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

-- (yaw, pitch) para mirar a un punto, relativo al cuerpo. nil si queda detrás
local function aim(rig: Rig, target: Vector3): (number?, number?)
	local from = rig.Head.Position
	local offset = target - from
	if offset.Magnitude < 0.5 then
		return nil, nil
	end
	local dir = rig.Root.CFrame:VectorToObjectSpace(offset.Unit)
	local yaw = math.atan2(-dir.X, -dir.Z)
	if math.abs(yaw) > math.rad(115) then
		return nil, nil
	end
	local pitch = math.asin(math.clamp(dir.Y, -1, 1))
	return math.clamp(yaw, -math.rad(75), math.rad(75)), math.clamp(pitch, -math.rad(35), math.rad(30))
end

local function lookTarget(rig: Rig, t: number): (number, number)
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
				return math.rad(18) * math.sign(math.sin(rig.Seed)), math.rad(6)
			end
		else
			target = headPosition(speaker)
		end
		if target then
			local yaw, pitch = aim(rig, target)
			if yaw then
				return yaw, pitch :: number
			end
		end
		return 0, 0
	end
	if rig.Me then
		return 0, 0
	end
	-- Si pasas cerca, te miran un rato; luego apartan la vista y vuelven a mirarte
	local near = myHead ~= nil and (myHead - rig.Head.Position).Magnitude < (if rig.Partner then 10 else 16)
	if near then
		if t > rig.InterestAt then
			rig.Interested = not rig.Interested
			rig.InterestAt = t + (if rig.Interested then 2.5 + math.random() * 4 else 1.2 + math.random() * 2.5)
		end
		if rig.Interested then
			local yaw, pitch = aim(rig, myHead :: Vector3)
			if yaw then
				return yaw, pitch :: number
			end
		end
	else
		rig.Interested = false
	end
	-- Charlando con los de al lado: mira a su compañero
	if rig.Partner and rig.Partner.Parent then
		local yaw, pitch = aim(rig, headPosition(rig.Partner) or rig.Head.Position)
		if yaw then
			return yaw, pitch :: number
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
		return glance.X, glance.Y
	end
	return 0, 0
end

---------------------------------------------------------------------
-- Postura y gestos
---------------------------------------------------------------------

local POSE_NAMES = { "Happy", "Sad", "Angry", "Surprised", "Thinking", "Ask", "Shrug", "Nod", "No" }

-- Cuánto mueven las manos al hablar según la emoción
local GESTURE = { Calm = 0.7, Happy = 1, Sad = 0.3, Angry = 1.3, Surprised = 0.8, Thinking = 0.25, Ask = 0.8, Shrug = 0.6, Nod = 0.5, No = 0.7 }

local function actionPlaying(rig: Rig): boolean
	for name in Emotion.Animated do
		local t = rig.Tracks[name]
		if t and t.IsPlaying then
			return true
		end
	end
	return false
end

local function update(rig: Rig, t: number, dt: number)
	-- Velocidad (los NPCs del mapa se mueven sin física: se mide cuánto avanzan)
	local position = rig.Root.Position
	if rig.LastPos and dt > 0 then
		local moved = Vector3.new(position.X - rig.LastPos.X, 0, position.Z - rig.LastPos.Z).Magnitude / dt
		rig.Speed = smooth(rig.Speed, math.min(moved, 40), 10, dt)
	end
	rig.LastPos = position
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
				local moods = { "Calm", "Calm", "Happy", "Ask", "Nod", "Shrug", "Surprised" }
				rig.Emotion = moods[math.random(1, #moods)]
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

	-- Mirada
	local wantYaw, wantPitch = lookTarget(rig, t)
	rig.Yaw = smooth(rig.Yaw, wantYaw, 6, dt)
	rig.Pitch = smooth(rig.Pitch, wantPitch, 6, dt)

	-- Hablar y emoción
	local talking = t < rig.TalkUntil
	rig.Talk = smooth(rig.Talk, if talking then 1 else 0, if talking then 9 else 4, dt)
	local sinceLine = t - rig.EmotionAt
	for _, name in POSE_NAMES do
		local want = if rig.Emotion == name and (talking or sinceLine < 2.5) then 1 else 0
		-- Asentir y negar son un gesto corto; encogerse de hombros también
		if (name == "Nod" or name == "No" or name == "Shrug") and sinceLine > 1.6 then
			want = 0
		end
		rig.Poses[name] = smooth(rig.Poses[name] or 0, want, 5, dt)
	end
	local P = rig.Poses
	local seed = rig.Seed
	local talk = rig.Talk
	local busyArms = actionPlaying(rig) or rig.Speed > 0.8

	-- Cabeza
	local neckPitch = rig.Pitch * 0.8
	local neckYaw = rig.Yaw * 0.65
	local neckRoll = 0
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

	-- Torso: respira, acompaña la mirada, se encoge si está triste
	local breath = math.sin(t * (math.pi * 2 / (3.6 + (seed % 1.2))) + seed)
	local waistPitch = breath * 0.012 + rig.Pitch * 0.2 - (P.Sad or 0) * 0.09 + (P.Surprised or 0) * 0.05 + (P.Angry or 0) * -0.04
	local waistYaw = rig.Yaw * 0.35

	-- Brazos (solo si no están andando ni haciendo un gesto de animación)
	local armWeight = if busyArms then 0 else 1
	local g = talk * (GESTURE[rig.Emotion] or 0.7) * armWeight
	local rX = g * (0.22 + 0.2 * math.sin(t * 2.1 + seed)) -- adelante
	local rZ = g * (0.1 + 0.08 * math.sin(t * 1.7 + seed)) -- hacia fuera
	local rElbow = g * (0.45 + 0.35 * math.sin(t * 2.6 + seed))
	local lX = g * (0.12 + 0.14 * math.sin(t * 1.9 + seed + 2))
	local lZ = g * (0.06 + 0.06 * math.sin(t * 1.3 + seed + 1))
	local lElbow = g * (0.3 + 0.25 * math.sin(t * 2.3 + seed + 2))
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

	-- Aplicar (encima de la animación: C0 es la postura base de cada articulación)
	local J, B = rig.Joints, rig.Base
	J.Neck.C0 = B.Neck * CFrame.Angles(neckPitch, neckYaw, neckRoll)
	if J.Waist then
		J.Waist.C0 = B.Waist * CFrame.Angles(waistPitch, waistYaw, 0)
	end
	if J.RightShoulder then
		J.RightShoulder.C0 = B.RightShoulder * CFrame.new(0, shoulderUp, 0) * CFrame.Angles(rX, 0, rZ)
	end
	if J.LeftShoulder then
		J.LeftShoulder.C0 = B.LeftShoulder * CFrame.new(0, shoulderUp, 0) * CFrame.Angles(lX, 0, -lZ)
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
	if rig.Own then
		setBase(rig, nil)
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

-- Empieza o termina una conversación (la mirada de todos se organiza alrededor de quien habla)
function ActorLife.conversation(on: boolean)
	conversation = on
	if not on then
		speaker = nil
		table.clear(listeners)
	end
end

-- Alguien dice una frase: mueve la cabeza y las manos durante `seconds`, con la emoción de la frase
function ActorLife.speak(model: Instance?, emotion: string?, seconds: number)
	if not model or not model:IsA("Model") then
		return
	end
	register(model)
	local rig = rigs[model]
	speaker = model
	listeners[model] = true
	local me = player.Character
	if me then
		listeners[me] = true
		register(me)
	end
	if not rig then
		return
	end
	rig.Emotion = if emotion and (Emotion.Poses[emotion] or Emotion.Animated[emotion]) then emotion else "Calm"
	rig.EmotionAt = now()
	rig.TalkUntil = now() + math.max(0.8, seconds)
	if emotion and Emotion.Animated[emotion] then
		ActorLife.play(model, emotion, 3)
		rig.Emotion = if emotion == "Laugh" or emotion == "Cheer" or emotion == "Dance" then "Happy" else "Calm"
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
					-- Si otro ya le pone animaciones (el servidor), aquí no se le pone la base
					if rig.Own and next(rig.Tracks) == nil then
						local animator = rig.Humanoid:FindFirstChildOfClass("Animator")
						if animator and #animator:GetPlayingAnimationTracks() > 0 then
							rig.Own = false
						end
					end
				end
			end
			active = nextActive
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local t = now()
		for _, rig in active do
			if rig.Active and rig.Model.Parent then
				local ok, err = pcall(update, rig, t, dt)
				if not ok then
					warn("[ActorLife] " .. tostring(err))
					rig.Active = false
					rigs[rig.Model] = nil -- no se vuelve a intentar con este
				end
			end
		end
	end)

	-- Al reaparecer, tu personaje nuevo también
	player.CharacterAdded:Connect(function(character)
		task.delay(1, function()
			if character.Parent then
				register(character)
			end
		end)
	end)
end

return ActorLife
