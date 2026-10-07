-- LifeStoryService: la historia de vida del jugador (la campaña principal).
--
-- Es una CAPA NARRATIVA: no duplica los demás sistemas, los escucha. Trabajar, comer, viajar,
-- dormir, llegar a un lugar o hablar con alguien avisan por StoryEvents; aquí se decide si eso
-- hace avanzar un capítulo, una misión principal o una secundaria.
--
-- Todo el contenido son datos (shared/LifeStory): capítulos, misiones, lugares y textos.
-- Todo se decide y se guarda en el servidor; el cliente solo dibuja lo que se le manda.
--
-- Lo que se guarda (data.Story y data.Life):
--   Life   = { Stage, AgeYears }
--   Story  = { Chapter, Chapters, Active, Completed, Declined, Choices, Flags, Discovered,
--              NpcMemory (Facts, Affinity, Rel), Events (biografía), Tracked,
--              Traits (rasgos del jugador), Memories (grandes recuerdos), Later (consecuencias diferidas),
--              Clock (segundos jugados con la historia) }
--
-- Misiones episódicas (docs/historia/11): escenas con actores y objetos (SceneService), diálogos con
-- respuestas (DialogueService) y minijuegos (MiniGameService). Hablar con un actor o usar un objeto
-- llega aquí (LifeStoryService.interact) y la misión decide qué pasa.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GameClock = require(ReplicatedStorage.Shared.GameClock)

-- Hasta cuándo dura un paso "Wait" (en minutos de juego):
--   GameMinutes = N          -> N minutos desde ahora
--   UntilHour = H            -> hasta las H de hoy (si ya han pasado, nada)
--   UntilHour + GameMinutes  -> hasta las H, pero como mucho N minutos (p. ej. la comida del cole)
local function waitTarget(step: { [string]: any }): number
	local now = GameClock.now()
	if step.UntilHour then
		local target = now.TotalMinutes - now.Hour * 60 - now.Minute + math.floor(step.UntilHour * 60)
		if target <= now.TotalMinutes then
			return now.TotalMinutes
		end
		if step.GameMinutes then
			target = math.min(target, now.TotalMinutes + step.GameMinutes)
		end
		return target
	end
	return now.TotalMinutes + (step.GameMinutes or 0)
end
local LifeStory = ReplicatedStorage.Shared.LifeStory
local Chapters = require(LifeStory.Chapters)
local Quests = require(LifeStory.Quests)
local Locations = require(LifeStory.Locations)
local Conditions = require(LifeStory.Conditions)
local Stages = require(LifeStory.Stages)
local Validate = require(LifeStory.Validate)
local Subjects = require(LifeStory.Subjects)
local DayPlans = require(LifeStory.DayPlans)
local Schedules = require(LifeStory.Schedules)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local LocationService = require(script.Parent.LocationService)
local RoleService = require(script.Parent.RoleService)
local CinematicService = require(script.Parent.CinematicService)
local ClassService = require(script.Parent.ClassService)
local SceneService = require(script.Parent.SceneService)
local DialogueService = require(script.Parent.DialogueService)
local MiniGameService = require(script.Parent.MiniGameService)
local InventoryService = require(script.Parent.InventoryService)
local NeedsService = require(script.Parent.NeedsService)
local Memories = require(LifeStory.Memories)
local StoryContext = require(LifeStory.StoryContext)
local ActorStaging = require(LifeStory.ActorStaging)
local StageDirector = require(LifeStory.StageDirector)
local HappeningIndex = require(LifeStory.HappeningIndex)
local Log = require(ReplicatedStorage.Shared.Log)
local RideState = require(ReplicatedStorage.Shared.RideState)
local SkyRift = require(ReplicatedStorage.Shared.SkyRift)
local Strings = require(LifeStory.Strings)
local Cast = require(LifeStory.Cast)
local SafeGround = require(ReplicatedStorage.Shared.SafeGround)
local Items = require(ReplicatedStorage.Shared.Items)
local MissionCombat = require(ReplicatedStorage.Shared.MissionCombat)
local EnemyStats = require(ReplicatedStorage.Shared.EnemyStats)
local DamageService = require(script.Parent.DamageService)

local LifeStoryService = {}

-- Un aviso en la pantalla del jugador (Notify: "Info", "Success", "Error"…)
local function notifyPlayer(player: Player, kind: string, text: string)
	pcall(function()
		local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Notify")
		if remote then
			(remote :: RemoteEvent):FireClient(player, kind, text)
		end
	end)
end

-- Quien quiera enterarse de lo que pasa en la historia (registro de desarrollo, pruebas, panel de
-- depuración): fn(kind, player, questId, info). kind = QuestStart, QuestDone, QuestInvalid,
-- StepEnter, StepDone, StepSkip, StepTimeout, Dialogue, Recover, PlaceSkipped (lugar que falta: { Place, Text }).
local observers: { (string, Player, string?, { [string]: any }?) -> () } = {}
function LifeStoryService.observe(fn: (string, Player, string?, { [string]: any }?) -> ())
	table.insert(observers, fn)
end
local function notify(kind: string, player: Player, questId: string?, info: { [string]: any }?)
	for _, fn in observers do
		local ok, err = pcall(fn, kind, player, questId, info)
		if not ok then
			Log.warn("DEBUG", "observador de la historia: %s", tostring(err))
		end
	end
end

local CFG = Config.LifeStory
local Remote: RemoteEvent

type Data = { [string]: any }
type Progress = {
	Step: number,
	Count: number,
	Sub: { [string]: boolean }?,
	Hp: { [string]: number }?, -- (Fight) vida (puntos) que le queda a cada enemigo (shared/EnemyStats)
	Caught: number?, -- (Escape/Fight) cuántas veces te han atrapado en este paso
	Retries: number?, -- (Fight) cuántas veces has caído en este combate y ha vuelto a empezar
	WaitUntil: number?,
	Started: number,
	Kind: string,
}

-- Estado que no se guarda (se reconstruye al entrar)
type Runtime = {
	Spots: { [string]: LocationService.Spot }, -- lugar elegido para cada paso "Reach" en curso
	ScheduleSpots: { [string]: any }?, -- sitios con horario ya buscados (para saber si ya estás dentro)
	PendingOffer: string?,
	OfferedAt: number,
	Waiting: { QuestId: string, Reason: string, From: number?, To: number? }?,
	LastPublished: string?,
	WarnedStuckPrologue: boolean?, -- (ya se apuntó el prólogo atascado en el registro)
	LastRemote: number,
	LastRemoteBy: { [string]: number }?, -- tipo de petición -> la última vez que se atendió (os.clock)
	QueuedRemote: { [string]: { any } }?, -- respuesta importante que llegó demasiado seguida: se atiende un poco después
	Ready: boolean,
	ClassFor: string?, -- paso de clase que se está jugando ahora
	ClassWaitSince: { [string]: number }, -- desde cuándo se espera un aula que no aparece en el mapa -- el cliente ya escucha (si no, los avisos de capítulo se perderían)
	StepStart: { [string]: number }, -- misión -> cuándo empezó su paso actual (os.clock)
	NudgedAt: { [string]: number }, -- misión -> último "¡date prisa!"
	Fallback: { [string]: boolean }, -- misión -> ya se lanzó el plan B de este paso
	Busy: boolean, -- una conversación, un minijuego o una clase de la historia en marcha
	Starting: boolean?, -- esperando a que el jugador aparezca para retomar la historia
	ChoiceSentAt: { [string]: number }, -- misión -> cuándo se mandó su ventana de decisión (0 = volver a mandarla)
	CaughtAt: number?, -- (Escape/Fight) la última vez que te atrapó un enemigo
	CanonSpots: { [string]: any }?, -- dónde empieza cada misión canónica (para su marca en el mapa)
	LastHit: number?, -- (Fight) último disparo (no se puede disparar más rápido que esto)
	BusySince: number?, -- desde cuándo está Busy (el vigilante lo suelta si se queda colgado)
	Watch: { [string]: { [string]: any } }?, -- (vigilante) última foto del progreso de cada misión
	Ticking: boolean?, -- su tick de la historia está en marcha (no se solapan)
	-- Prólogo («El sueño»)
	PrologueSince: number?, -- cuándo empezó (os.clock): tope PrologueMaxSeconds
	PrologueReplay: boolean?, -- lo vuelve a jugar desde «Mi historia»
	PrologueReturn: Vector3?, -- dónde estaba antes del sueño (para volver)
	PrologueTracked: string?, -- la misión que seguía antes (al volver a jugarlo)
	-- «Anteriormente en tu vida…» y contexto de las misiones
	AwaySeconds: number?, -- cuánto tiempo llevaba fuera al entrar
	RecapPending: boolean?, -- toca enseñar el resumen en cuanto no esté ocupado
	StagedScene: string?, -- "misión:paso" cuyo Stage (escena del motor) se está viendo
	JustOffered: string?, -- misión que acaba de aceptar en una oferta (ya vio su contexto)
	-- Escenas que esperan (conduces, o es una misión que no sigues): ver canAutoStart
	Engaged: { [string]: number }?, -- misión -> la última vez que el jugador hizo algo en ella (os.clock)
	HeldNotice: { [string]: boolean }?, -- avisos «📱 … quiere hablar contigo» ya mandados (misión:paso:motivo)
	CineHeld: { [string]: number }?, -- misión -> paso de escena de cine que espera a poder verse
	UntrackedPingAt: number?, -- último aviso de una misión que no sigues (como mucho uno por minuto)
	SceneSeen: { [string]: any }?, -- (inScene) valor de InScene/InCinematic visto y desde cuándo
	SceneAck: number?, -- (inScene) último latido de escena o CinematicSeen de su pantalla (os.clock)
	LocalClock: { Quest: string, Until: number }?, -- hora de una Transition puesta solo para ti (StoryClock)
	SceneGateSince: number?, -- (refresh) desde cuándo espera a que acabe una escena para entrar en el capítulo
	SceneGateWaiting: boolean?, -- (refresh) ya hay un hilo esperando a que acabe esa escena
}
local runtime: { [Player]: Runtime } = {}
local SCENE_GATE_MAX = 60 -- como mucho, cuánto espera la cabecera de un capítulo a que acabe otra escena
local PROLOGUE = StoryContext.PrologueId
local dayRng = Random.new()
local growUp -- se define más abajo

local chapterOrder: { string } = {}
for id in Chapters do
	table.insert(chapterOrder, id)
end
table.sort(chapterOrder, function(a, b)
	return Chapters[a].Order < Chapters[b].Order
end)

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function send(player: Player, kind: string, payload: { [string]: any })
	Remote:FireClient(player, kind, payload)
end

local function storyOf(data: Data): Data
	return data.Story
end

-- Pasos de una misión: los días generados (DayPlans) guardan los suyos en el progreso
local function stepsOf(questId: string, prog: Progress?): { { [string]: any } }
	if prog and (prog :: any).Steps then
		return (prog :: any).Steps
	end
	local quest = Quests[questId]
	return if quest then quest.Steps else {}
end

local function titleOf(questId: string, prog: Progress?): string
	return (prog and (prog :: any).TitleKey) or Quests[questId].TitleKey
end

-- Cuánto de la etapa actual se ha jugado (0 = recién empezada, 1 = su duración completa)
local function stageProgress(data: Data): number
	local hours = Config.LifeStory.StageHours[data.Life.Stage]
	if not hours or hours <= 0 then
		return 1
	end
	return (data.Life.StageSeconds or 0) / (hours * 3600)
end

-- Día de la vida del jugador (atributo LifeDay de CalendarService: se guarda con la partida y sigue
-- contando en cualquier servidor). Sin él (aún no ha cargado, pruebas), el día del servidor.
local function lifeDay(player: Player): number
	local day = player:GetAttribute("LifeDay")
	if type(day) == "number" and day >= 1 then
		return day
	end
	return GameClock.now().Day
end
LifeStoryService.lifeDay = lifeDay

local function contextFor(player: Player, data: Data): Conditions.Context
	local now = GameClock.now()
	local story = storyOf(data)
	local rel = {}
	for npc, entry in story.NpcMemory do
		rel[npc] = entry.Rel or 0
	end
	return {
		Rel = rel,
		Traits = story.Traits or {},
		Memories = story.Memories or {},
		LastGrade = story.LastGrade,
		Stage = data.Life.Stage,
		ClockTime = now.ClockTime,
		Weekday = now.Weekday,
		Completed = story.Completed,
		Flags = story.Flags,
		Choices = story.Choices,
		Discovered = story.Discovered,
		Duties = RoleService.dutiesOf(player),
		StageProgress = stageProgress(data),
		Season = workspace:GetAttribute("Season"),
		Weather = workspace:GetAttribute("Weather"),
		World = story.World, -- memoria del mundo (WorldMemoryService): condiciones World / NotWorld
	}
end

local function matchesPayload(match: { [string]: any }?, payload: { [string]: any }): boolean
	for key, value in match or {} do
		if payload[key] ~= value then
			return false
		end
	end
	return true
end

-- Guarda un acontecimiento en la biografía del personaje (LifeHistory lo mostrará)
function LifeStoryService.logEvent(player: Player, key: string, args: { [string]: any }?, kind: string?)
	local data = DataService.get(player)
	if not data then
		return
	end
	local events = storyOf(data).Events
	table.insert(events, {
		K = key,
		A = args,
		Y = kind or "Moment",
		S = data.Life.Stage,
		D = lifeDay(player),
		T = os.time(),
	})
	while #events > CFG.MaxLifeEvents do
		table.remove(events, 1)
	end
end

local function moment(player: Player, key: string, args: { [string]: any }?, sting: string?)
	send(player, "Moment", { TextKey = key, Args = args, Sting = sting })
	LifeStoryService.logEvent(player, key, args, "Moment")
end

-- ¿Está viendo una escena de cámara (cinemática o escena del motor)? Lo dicen los atributos del jugador:
-- InScene lo pone el SERVIDOR al lanzar la escena y lo quita al acabar (CinematicService); InCinematic
-- lo pone el cliente (en el servidor solo se ve si alguien lo copia). Vale cualquier valor «encendido»
-- (true, el nombre de la escena, un número). Por si alguien se olvida de quitarlo, pasado
-- SceneMaxSeconds seguido con el mismo valor deja de contar: la historia nunca se queda parada.
-- Con CinematicService.inScene (la respuesta buena), la escena cuenta cuando la pantalla CONFIRMA que
-- la está enseñando: su latido (Remotes.Scene "Beat", cada segundo) o CinematicSeen, en los últimos
-- SceneAckSeconds. Una escena que el servidor ha lanzado pero ninguna pantalla enseña (aún cargando,
-- o sin cliente) no para la historia.
LifeStoryService.SceneMaxSeconds = 180
LifeStoryService.SceneAckSeconds = 5

-- La pantalla del jugador dice que tiene una escena delante (latido o CinematicSeen)
function LifeStoryService.sceneBeat(player: Player)
	local rt = runtime[player]
	if rt then
		rt.SceneAck = os.clock()
	end
end
local function sceneFlag(value: any): boolean
	return value ~= nil and value ~= false and value ~= "" and value ~= 0
end
local function inScene(player: Player): boolean
	-- La respuesta buena es la de CinematicService.inScene (el mismo InScene, pero caduca las escenas
	-- colgadas). Si existe, manda para InScene; InCinematic se sigue mirando en el atributo
	local scene = nil
	local ok, authoritative = pcall(function()
		local fn = (CinematicService :: any).inScene
		if type(fn) ~= "function" then
			return nil
		end
		return fn(player) == true
	end)
	if ok and authoritative ~= nil then
		local rt0 = runtime[player]
		local confirmed = rt0 ~= nil and rt0.SceneAck ~= nil and os.clock() - rt0.SceneAck <= LifeStoryService.SceneAckSeconds
		scene = if authoritative and confirmed then (player:GetAttribute("SceneId") or "InScene") else nil
	else
		scene = player:GetAttribute("InScene")
	end
	local cine = player:GetAttribute("InCinematic")
	local rt = runtime[player]
	if not sceneFlag(scene) and not sceneFlag(cine) then
		if rt then
			rt.SceneSeen = nil
		end
		return false
	end
	if rt then
		local key = tostring(scene) .. "|" .. tostring(cine)
		local seen = rt.SceneSeen
		if not seen or seen.Key ~= key then
			seen = { Key = key, Since = os.clock() }
			rt.SceneSeen = seen
		end
		if os.clock() - seen.Since > LifeStoryService.SceneMaxSeconds then
			if not seen.Warned then
				seen.Warned = true
				Log.warn("WATCHDOG", "%s: la escena (%s) lleva más de %d s puesta; la historia sigue sin esperarla", player.Name, key, LifeStoryService.SceneMaxSeconds)
			end
			return false
		end
	end
	return true
end

-- ¿Está ya ocupado el jugador? (una conversación, un minijuego, una clase o una escena de cámara: no
-- se empieza otra cosa encima, ni salen avisos, ofertas o decisiones tapándola)
local function busy(player: Player): boolean
	local rt = runtime[player]
	if rt and (rt.Busy or rt.ClassFor ~= nil) then
		return true
	end
	return DialogueService.isBusy(player) or MiniGameService.isRunning(player) or ClassService.isRunning(player) or inScene(player)
end

-- ¿Muerto (esperando a reaparecer en el hospital), detenido o en un juicio? Entonces la historia no
-- le lleva de un sitio a otro (no se sale de la cárcel por una escena)
local function heldAway(player: Player): boolean
	return player:GetAttribute("Dead") == true or player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil
end

-- …o en el suelo (caído en combate / K.O.): tampoco empieza nada ni se le lleva a ningún sitio
-- hasta que se levante (se reintenta en la siguiente vuelta)
local function held(player: Player): boolean
	return heldAway(player) or player:GetAttribute("Fallen") ~= nil
end

---------------------------------------------------------------------
-- Memoria de los NPC (qué recuerdan de ti)
---------------------------------------------------------------------

function LifeStoryService.remember(player: Player, npcId: string, fact: string)
	local data = DataService.get(player)
	if not data then
		return
	end
	local memory = storyOf(data).NpcMemory
	memory[npcId] = memory[npcId] or { Facts = {}, Affinity = 0 }
	memory[npcId].Facts[fact] = lifeDay(player)
end

function LifeStoryService.recall(player: Player, npcId: string, fact: string): boolean
	local data = DataService.get(player)
	local entry = data and storyOf(data).NpcMemory[npcId]
	return entry ~= nil and entry.Facts[fact] ~= nil
end

function LifeStoryService.addAffinity(player: Player, npcId: string, amount: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	local memory = storyOf(data).NpcMemory
	memory[npcId] = memory[npcId] or { Facts = {}, Affinity = 0 }
	memory[npcId].Affinity = math.clamp(memory[npcId].Affinity + amount, 0, 5)
end

-- Relación con un personaje (-100..100): ayudar suma, ignorar o traicionar resta
function LifeStoryService.addRel(player: Player, npcId: string, amount: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	local memory = storyOf(data).NpcMemory
	memory[npcId] = memory[npcId] or { Facts = {}, Affinity = 0 }
	memory[npcId].Rel = math.clamp((memory[npcId].Rel or 0) + amount, -100, 100)
end

function LifeStoryService.getRel(player: Player, npcId: string): number
	local data = DataService.get(player)
	local entry = data and storyOf(data).NpcMemory[npcId]
	return entry and entry.Rel or 0
end

---------------------------------------------------------------------
-- Etapa de vida
---------------------------------------------------------------------

function LifeStoryService.getStage(player: Player): string?
	local data = DataService.get(player)
	return data and data.Life.Stage
end

local refresh -- se define más abajo

function LifeStoryService.setStage(player: Player, stage: string)
	local data = DataService.get(player)
	if not data or not Stages.isValid(stage) or data.Life.Stage == stage then
		return
	end
	local before = data.Life.Stage
	local previousAge = tonumber(data.Life.AgeYears) or 0
	data.Life.Stage = stage
	data.Life.StageSeconds = 0
	local ages = Config.LifeStory.AgeRange[stage]
	if ages then
		-- Al crecer, la edad de la etapa nueva… pero sin saltos de años de golpe: como mucho un año
		-- más que antes (si la etapa empieza más tarde, se toma su primera edad)
		local growing = Stages.isValid(before) and Stages.Rank[stage] > Stages.Rank[before]
		data.Life.AgeYears = if growing then math.max(ages[1], math.min(previousAge + 1, ages[2])) else ages[1]
	end
	player:SetAttribute("LifeStage", stage)
	player:SetAttribute("AgeYears", data.Life.AgeYears)
	LifeStoryService.logEvent(player, "STAGE." .. stage, nil, "Stage")
	task.defer(refresh, player)
end

---------------------------------------------------------------------
-- Efectos: lo que cambia en tu vida por una respuesta, un objeto, un paso o el final de una misión
--   Flags, Unflags, Rel = { Mateo = 15 }, Traits = { Empatia = 1 }, Memory = "PrimerAmigo" | { … },
--   Remember = { { Npc, Fact } }, Items = { MochilaCole = 1 }, Take = { … }, Needs = { Hunger, Energy },
--   Money, Choice = { Key = Valor }, Gesture = { Npc, Anim }, Say = { S, T },
--   Later = { { AfterHours | AfterMinutes, Flag?, Start?, Memory?, If? } }   (consecuencias diferidas)
---------------------------------------------------------------------

function LifeStoryService.addMemory(player: Player, key: string, questId: string?)
	local data = DataService.get(player)
	if not data then
		return
	end
	local story = storyOf(data)
	story.Memories = story.Memories or {}
	if story.Memories[key] then
		return
	end
	story.Memories[key] = { D = lifeDay(player), T = os.time(), Q = questId, S = data.Life.Stage }
	local memory = Memories[key]
	LifeStoryService.logEvent(player, if memory then memory.Text else key, nil, "Memory")
end

-- El camino de la vida (arco «La pandilla» del instituto): Responsable, Gamberro/a o Delincuente.
-- Sale de la Rebeldía acumulada y de la decisión final. Se guarda como atributo "Camino" del jugador
-- (lo pueden usar la interfaz y otros sistemas) y se avisa cuando cambia.
local CAMINO_TEXT = {
	Responsable = "😇 Tu reputación: persona responsable",
	Gamberro = "😈 Tu reputación: gamberro o gamberra",
	Delincuente = "🚨 Tu reputación: vas por el mal camino",
}
function LifeStoryService.updateCamino(player: Player, story: Data)
	local flags, traits = story.Flags, story.Traits or {}
	local rebeldia = traits.Rebeldia or 0
	local camino: string? = nil
	if flags.Camino_Delincuente then
		camino = "Delincuente"
	elseif rebeldia >= 3 and not flags.Camino_Trabajador then
		camino = "Gamberro"
	elseif flags.Camino_Trabajador or rebeldia > 0 or flags.RechazasteLaPandilla then
		camino = "Responsable"
	end
	if camino and player:GetAttribute("Camino") ~= camino then
		player:SetAttribute("Camino", camino)
		pcall(function()
			local notify = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Notify")
			if notify then
				(notify :: RemoteEvent):FireClient(player, "Info", CAMINO_TEXT[camino])
			end
		end)
	end
end

-- Regalos que no cabían en la mochila (Story.PendingItems): se apuntan como mucho hasta el máximo
-- de una casilla (Stack) y los objetos que ya no existen se tiran (si no, se quedaban para siempre)
local function queuePending(story: Data, id: string, count: number)
	local item = require(ReplicatedStorage.Shared.Items).get(id)
	if not item then
		return
	end
	story.PendingItems = story.PendingItems or {}
	story.PendingItems[id] = math.min((story.PendingItems[id] or 0) + count, item.Stack)
end

-- Cuántos de `id` caben ahora mismo en la mochila (lo que falta para llenar su casilla, o una casilla libre)
local function roomFor(player: Player, id: string): number
	local item = require(ReplicatedStorage.Shared.Items).get(id)
	if not item or not InventoryService.canAdd(player, id, 1) then
		return 0
	end
	return math.max(0, item.Stack - InventoryService.count(player, id))
end

local function applyEffects(player: Player, data: Data, effects: { [string]: any }?, questId: string?)
	if type(effects) ~= "table" then
		return
	end
	local story = storyOf(data)
	for _, flag in effects.Flags or {} do
		story.Flags[flag] = true
	end
	for _, flag in effects.Unflags or {} do
		story.Flags[flag] = nil
	end
	for npc, amount in effects.Rel or {} do
		LifeStoryService.addRel(player, npc, amount)
	end
	story.Traits = story.Traits or {}
	for trait, amount in effects.Traits or {} do
		story.Traits[trait] = (story.Traits[trait] or 0) + amount
	end
	LifeStoryService.updateCamino(player, story)
	local memory = effects.Memory
	if type(memory) == "string" then
		LifeStoryService.addMemory(player, memory, questId)
	elseif type(memory) == "table" then
		for _, key in memory do
			LifeStoryService.addMemory(player, key, questId)
		end
	end
	for _, entry in effects.Remember or {} do
		LifeStoryService.remember(player, entry.Npc, entry.Fact)
		LifeStoryService.addAffinity(player, entry.Npc, 1)
	end
	for id, count in effects.Items or {} do
		if not InventoryService.add(player, id, count) then
			-- Mochila llena: se avisa y se guarda hasta que hagas hueco (antes el regalo se perdía)
			pcall(function()
				local notify = ReplicatedStorage.Remotes:FindFirstChild("Notify") :: RemoteEvent?
				local item = require(ReplicatedStorage.Shared.Items).get(id)
				if notify then
					notify:FireClient(player, "Error", ("🎒 No te cabe «%s» en la mochila. Haz hueco y te llegará."):format(item and item.Name or id))
				end
			end)
			-- (se guarda con la partida: si sales antes de hacer hueco, te llega al volver)
			queuePending(storyOf(data), id, count)
		end
	end
	for id, count in effects.Take or {} do
		InventoryService.remove(player, id, math.min(count, InventoryService.count(player, id)))
	end
	if effects.Needs then
		NeedsService.change(player, effects.Needs.Hunger or 0, effects.Needs.Energy or 0)
	end
	if effects.Money and effects.Money > 0 then
		DataService.addMoney(player, effects.Money, true)
	end
	if effects.Spend then
		-- Pagar algo (helados…). Si no llega, queda la marca SinDinero para que la historia lo cuente.
		story.Flags.SinDinero = if DataService.spend(player, effects.Spend) then nil else true
	end
	for key, value in effects.Choice or {} do
		story.Choices[key] = { V = value, D = lifeDay(player) }
	end
	if effects.Gesture then
		SceneService.gesture(player, effects.Gesture.Npc, effects.Gesture.Anim or "Wave")
	end
	if effects.Say then
		DialogueService.bark(player, effects.Say.S, effects.Say.T)
	end
	if effects.Teleport and not heldAway(player) then
		SceneService.teleport(player, effects.Teleport) -- un atajo, una escena que empieza en otro sitio
	end
	if type(effects.World) == "table" then
		-- Lo que queda en el mundo (un cráter, alguien que se queda a vivir…): WorldMemoryService
		pcall(function()
			require(script.Parent.WorldMemoryService).apply(player, effects.World)
		end)
	end
	if type(effects.Scene) == "string" then
		-- Una escena del motor que no para la historia (efectos, actores…): HappeningService
		pcall(function()
			require(script.Parent.HappeningService).play(player, effects.Scene)
		end)
	end
	if type(effects.Conduct) == "string" then
		-- Algo que va a tu historial de comportamiento (llegar tarde al cole…): ConductService lo apunta
		StoryEvents.emit(player, "Misbehaved", { Crime = effects.Conduct })
	end
	story.Later = story.Later or {}
	for _, later in effects.Later or {} do
		local seconds = (later.AfterHours or 0) * 3600 + (later.AfterMinutes or 0) * 60
		table.insert(story.Later, {
			At = (story.Clock or 0) + seconds,
			Flag = later.Flag,
			Start = later.Start,
			Memory = later.Memory,
			If = later.If,
			From = questId,
		})
	end
end
LifeStoryService.applyEffects = applyEffects

---------------------------------------------------------------------
-- Publicar el estado al cliente (tarjeta "Tu vida" y línea guía)
---------------------------------------------------------------------


-- La carrera que eligió el jugador (para "$Carrera.Facultad", "$Carrera.Asignatura1"…)
local function degreeOf(story: Data): string?
	local choice = story.Choices.Estudios
	return choice and choice.V
end

local function stepPlace(step: { [string]: any }, story: Data): string?
	return Subjects.resolve(step.Place, degreeOf(story))
end

local function placeArgs(step: { [string]: any }, prog: Progress?, story: Data): { [string]: any }
	local args: { [string]: any } = {}
	local placeId = stepPlace(step, story)
	if placeId then
		local place = Locations.Places[placeId]
		args.placeKey = place and place.NameKey
	end
	local subjectId = Subjects.resolve(step.Subject, degreeOf(story))
	if subjectId and Subjects.List[subjectId] then
		args.subjectKey = Subjects.List[subjectId].NameKey
	end
	local degree = Subjects.Degrees[degreeOf(story) or ""]
	if degree then
		args.degreeKey = degree.NameKey
	end
	if step.Type == "Event" and (step.Count or 1) > 1 then
		args.count = if prog then prog.Count else 0
		args.total = step.Count
	elseif step.Type == "Fight" then
		args.count = if prog then prog.Count else 0
		args.total = #(step.Enemies or {})
	end
	return args
end

-- Horarios: si el paso actual te manda a un sitio con horario (colegio, instituto, universidad,
-- oficina) y está cerrado, la misión se queda en pausa hasta que abra. Si ya estás allí, sigue.
local function closedWindow(player: Player, data: Data, questId: string, prog: Progress): Schedules.Window?
	local story = storyOf(data)
	local step = stepsOf(questId, prog)[prog.Step]
	-- Solo las rutinas con horario (el día de cole, instituto, uni o trabajo, o las que lo piden con
	-- Schedule = true) esperan a que abra el sitio; las misiones de la historia y las locas se
	-- pueden jugar a cualquier hora (colarse en el patio del cole por la tarde, la noche de la Grieta…)
	local quest = Quests[questId]
	if not step or quest.Schedule == false or not (quest.DayPlan or quest.Schedule == true) then
		return nil
	end
	local window: Schedules.Window? = nil
	local placeId: string? = nil
	if step.Type == "Group" and step.Steps then
		for i, child in step.Steps do
			if not (prog.Sub and prog.Sub[tostring(i)]) then
				placeId = stepPlace(child, story)
				window = Schedules.forPlace(placeId)
				if window then
					break
				end
			end
		end
	else
		placeId = stepPlace(step, story)
		window = Schedules.forPlace(placeId)
	end
	local now = GameClock.now()
	if not window or Schedules.isOpen(window, now.ClockTime, now.Weekday) then
		return nil
	end
	-- ¿Ya estás allí? (dentro del colegio cuando cierra: puedes terminar lo que hacías)
	local rt = runtime[player]
	local me = LocationService.positionOf(player)
	if rt and me and placeId then
		rt.ScheduleSpots = rt.ScheduleSpots or {}
		local spot = rt.ScheduleSpots[placeId]
		if spot == nil then
			spot = LocationService.resolve(player, placeId) or false
			rt.ScheduleSpots[placeId] = spot
		end
		if spot and Vector3.new(spot.Position.X - me.X, 0, spot.Position.Z - me.Z).Magnitude < 180 then
			return nil
		end
	end
	return window
end

-- ¿Es una misión del cole? (el día de colegio o instituto, y las misiones que pasan en el cole)
local function schoolQuest(questId: string): boolean
	local quest = Quests[questId]
	return quest ~= nil and quest.Schedule ~= false and Schedules.isSchool(Schedules.forQuest(quest))
end

-- ¿El paso actual toca hacerlo en el cole? Si te manda a un sitio del colegio o del instituto, sí;
-- si te manda a otro sitio (volver a casa, un recado, el parque…), no; si no te manda a ningún
-- sitio (esperar, hablar con alguien…), depende de si la misión es del cole.
local function schoolStep(questId: string, prog: Progress): boolean
	local step = stepsOf(questId, prog)[prog.Step]
	if step and step.Schedule == false then
		return false -- un paso que se hace fuera del cole (el trabajo al salir del instituto)
	end
	if step and Quests[questId].Schedule ~= false then
		local window = Schedules.forStep(step, prog.Sub)
		if window then
			return Schedules.isSchool(window)
		end
		local hasPlace = step.Place ~= nil
		for _, child in step.Steps or {} do
			hasPlace = hasPlace or child.Place ~= nil
		end
		if hasPlace then
			return false
		end
	end
	return schoolQuest(questId)
end

-- Qué misiones se ven: en horario de cole, un niño o adolescente solo ve las misiones del cole;
-- cuando se acaba el cole, lo que toca hacer en el cole desaparece y vuelven las demás.
local function visibleQuest(data: Data, questId: string, prog: Progress): boolean
	local now = GameClock.now()
	if Schedules.isSchoolTime(now.ClockTime, now.Weekday) then
		local stage = data.Life.Stage
		return schoolQuest(questId) or (stage ~= "Nino" and stage ~= "Adolescente")
	end
	return not schoolStep(questId, prog)
end

local function trackedQuest(data: Data): string?
	local story = storyOf(data)
	if story.Tracked and story.Active[story.Tracked] and visibleQuest(data, story.Tracked, story.Active[story.Tracked]) then
		return story.Tracked
	end
	local first: string? = nil
	for id, prog in story.Active do
		if visibleQuest(data, id, prog) then
			if prog.Kind == "Main" then
				return id
			end
			first = first or id
		end
	end
	return first
end

-- Ninguna se ve ahora (el cole cerró, es fin de semana, o en horario de cole la principal no es del
-- cole): la que sigues, o la principal, se enseña igualmente en la tarjeta, en pausa y con cuándo
-- sigue (antes la tarjeta se quedaba vacía horas y parecía que no tenías misión).
local function laterQuest(data: Data): string?
	local story = storyOf(data)
	if story.Tracked and story.Active[story.Tracked] then
		return story.Tracked
	end
	local first: string? = nil
	for id, prog in story.Active do
		if prog.Kind == "Main" then
			return id
		end
		if not first or id < first then
			first = id
		end
	end
	return first
end

-- Cuándo sigue una misión que ahora no se ve: «AfterSchool» (en horario de cole: a las 17:00) o
-- «School» (fuera del horario de cole: cuando abra el colegio o el instituto, con sus días)
local function laterInfo(data: Data, questId: string, prog: Progress): (string, { [string]: any }?, number?)
	local now = GameClock.now()
	if Schedules.isSchoolTime(now.ClockTime, now.Weekday) then
		return "AfterSchool", nil, Config.SchoolDay.End
	end
	local window = Schedules.forStep(stepsOf(questId, prog)[prog.Step], prog.Sub)
	if not Schedules.isSchool(window) then
		window = Schedules.forQuest(Quests[questId])
	end
	if not Schedules.isSchool(window) then
		window = Schedules.Windows[if data.Life.Stage == "Adolescente" then "Instituto" else "Colegio"]
	end
	assert(window)
	return "School", { Name = window.Name, From = window.From, To = window.To, Weekdays = window.Weekdays }, window.From
end

local sceneTarget -- se define más abajo

local function spotKey(questId: string, prog: Progress, child: number?): string
	return ("%s:%d:%d"):format(questId, prog.Step, child or 0)
end

-- La línea guía lleva hasta el personaje con el que hay que hablar o el objeto que hay que usar
function sceneTarget(player: Player, questId: string, step: { [string]: any }): Vector3?
	local function actorPosition(npc: string?): Vector3?
		local model = npc and SceneService.actorOf(player, npc)
		return model and model:GetPivot().Position
	end
	local function propPosition(id: string?): Vector3?
		return if id then SceneService.propPosition(player, questId, id) else nil
	end
	if step.Type == "Talk" or step.Type == "Chase" then
		return actorPosition(step.Npc)
	elseif step.Type == "Fight" then
		for _, enemy in step.Enemies or {} do
			local position = actorPosition(enemy.Npc)
			if position then
				return position
			end
		end
	elseif step.Type == "Use" then
		return propPosition(step.Prop)
	elseif step.Type == "Choice" then
		for _, option in step.Options or {} do
			local position = actorPosition(option.Npc) or propPosition(option.Prop)
			if position then
				return position
			end
		end
	end
	return nil
end

local function publish(player: Player, force: boolean?)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt then
		return
	end
	local story = storyOf(data)
	local chapter = story.Chapter and Chapters[story.Chapter]
	local state: { [string]: any } = {
		ChapterTitleKey = chapter and chapter.TitleKey,
		ChapterMusic = chapter and chapter.Music,
		Stage = data.Life.Stage,
		Others = {},
	}

	local target: Vector3? = nil
	local trackedId = trackedQuest(data)
	-- La misión que estás jugando: los que te acompañan en otras misiones esperan (SceneService)
	if player:GetAttribute("StoryFocus") ~= trackedId then
		player:SetAttribute("StoryFocus", trackedId)
		if SceneService.refocus then
			SceneService.refocus(player) -- (un personaje que sale en dos misiones pasa a la que juegas)
		end
	end
	-- (la que se enseña en pausa no cambia StoryFocus: ahora no se juega)
	local laterId = if trackedId then nil else laterQuest(data)
	local shownId = trackedId or laterId
	if shownId then
		local trackedId = shownId
		local quest = Quests[trackedId]
		local prog: Progress = story.Active[trackedId]
		local step = stepsOf(trackedId, prog)[prog.Step]
		local tracked: { [string]: any } = { QuestId = trackedId, Kind = quest.Kind, TitleKey = titleOf(trackedId, prog) }
		-- De qué tipo es (⭐ principal, 🌀 loca, ❗ saga…) y por qué la haces
		local info = StoryContext.label(quest)
		tracked.Icon, tracked.Label, tracked.Type = info.Icon, info.Label, info.Kind
		tracked.Description = quest.Description
		if trackedId == PROLOGUE then
			-- Prólogo: la tarjeta de ayuda de este paso y "paso n de m" (solo cuentan los que enseñan algo)
			state.Prologue = true
			local n, total = 0, 0
			for i, s in stepsOf(trackedId, prog) do
				if s.Beat then
					total += 1
					if i <= prog.Step then
						n = total
					end
				end
			end
			tracked.Beat = step and step.Beat
			tracked.Hint = step and step.Hint
			tracked.StepNum, tracked.StepTotal = n, total
		end
		if step then
			tracked.TextKey = step.Text or step.TextKey
			tracked.Args = placeArgs(step, prog, story)
			-- Si ya estás allí (dentro del cole cuando toca ir al aula), no se te dice "ve al cole"
			local here = step.Type == "Reach" and rt.Spots[spotKey(trackedId, prog)]
			local me = here and LocationService.positionOf(player)
			if here and me and Vector3.new(here.Position.X - me.X, 0, here.Position.Z - me.Z).Magnitude < 150 then
				local text = tracked.TextKey
				if step.TextHere then
					tracked.TextKey = step.TextHere
				elseif type(text) == "string" and (text:find("^Ve al colegio") or text:find("^Ve al cole") or text:find("^Ve al instituto")) then
					tracked.TextKey = "Ya estás en {place}: entra y busca tu aula"
				end
			end
			if step.Type == "Group" then
				tracked.Children = {}
				-- Solo las tareas que te tocan (antes salían también las de otras carreras o de amigos que
				-- no hiciste, imposibles de cumplir, y el contador decía 0/12)
				local ctx = contextFor(player, data)
				local available = 0
				for _, child in step.Steps do
					if not child.If or Conditions.check(child.If, ctx) then
						available += 1
					end
				end
				tracked.Need = if step.Need then math.min(step.Need, available) else nil
				for i, child in step.Steps do
					if child.If and not Conditions.check(child.If, ctx) then
						continue
					end
					local done = prog.Sub ~= nil and prog.Sub[tostring(i)] == true
					table.insert(tracked.Children, { TextKey = child.Text or child.TextKey, Args = placeArgs(child, nil, story), Done = done })
					if not done and not target then
						if child.Type == "Reach" then
							local spot = rt.Spots[spotKey(trackedId, prog, i)]
							target = spot and spot.Position
						else
							target = sceneTarget(player, trackedId, child)
						end
					end
				end
			elseif step.Type == "Talk" or step.Type == "Use" or step.Type == "Choice" or step.Type == "Chase" or step.Type == "Fight" then
				target = sceneTarget(player, trackedId, step)
				if not target and step.Place then
					local spot = rt.Spots[spotKey(trackedId, prog)]
					target = spot and spot.Position
				end
			elseif step.Place then
				-- Reach, o un Talk/Event con lugar: la línea guía lleva hasta allí
				local spot = rt.Spots[spotKey(trackedId, prog)]
				target = spot and spot.Position
			end
		end
		-- Qué hay que hacer, aunque el paso no tenga texto (una escena, un minijuego): el HUD dice
		-- «Habla con…», «Mira la escena»… en vez de dejar la tarjeta en blanco
		if step then
			tracked.StepType = step.Type
			if type(step.Npc) == "string" then
				tracked.NpcKey = Cast.nameOf(step.Npc, { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") })
			end
		end
		if laterId then
			-- En pausa hasta luego: sin línea guía; el HUD dice cuándo sigue
			local later, closed, from = laterInfo(data, trackedId, prog)
			tracked.Later, tracked.Closed, tracked.From = later, closed, from
			target = nil
		else
			local closed = closedWindow(player, data, trackedId, prog)
			if closed then
				-- Cerrado: sin línea guía; el HUD dice a qué hora abre
				tracked.Closed = { Name = closed.Name, From = closed.From, To = closed.To, Weekdays = closed.Weekdays }
				target = nil
			end
		end
		state.Tracked = tracked
	elseif rt.Waiting then
		local quest = Quests[rt.Waiting.QuestId]
		local req = quest.Requires or {}
		state.Waiting = {
			TitleKey = quest.TitleKey or quest.Title,
			Reason = rt.Waiting.Reason,
			From = rt.Waiting.From or (req.Hours and req.Hours.From),
			To = rt.Waiting.To or (req.Hours and req.Hours.To),
		}
	end
	-- Las demás misiones. Las que no tocan ahora (en horario de cole solo se hacen las del cole; fuera
	-- de él, las que te mandan al cole esperan) siguen en la lista, marcadas: antes se escondían y
	-- parecía que habían desaparecido.
	local inSchool = Schedules.isSchoolTime(GameClock.now().ClockTime, GameClock.now().Weekday)
	for id, prog in story.Active do
		if id ~= shownId then
			local visible = visibleQuest(data, id, prog)
			table.insert(state.Others, {
				QuestId = id,
				TitleKey = titleOf(id, story.Active[id]),
				Kind = Quests[id] and Quests[id].Kind or "Side",
				Later = if visible then nil elseif inSchool then "AfterSchool" else "School",
			})
		end
	end
	table.sort(state.Others, function(a, b)
		if (a.Later ~= nil) ~= (b.Later ~= nil) then
			return a.Later == nil -- (primero las que se pueden hacer ya)
		end
		return a.QuestId < b.QuestId
	end)

	player:SetAttribute("StoryTarget", target)
	-- Qué control enseña ahora el prólogo ("Move", "Run", "Jump"…): lo pueden mirar otras partes de la interfaz
	player:SetAttribute("PrologueBeat", if state.Tracked and state.Tracked.QuestId == PROLOGUE then state.Tracked.Beat else nil)
	-- A quién hay que ir a buscar (y dónde): los compañeros y profes del colegio (SchoolService) se
	-- acercan andando si la escena no trae ya a ese personaje
	local needNpc, needPlace = nil, nil
	if trackedId and not (state.Tracked and state.Tracked.Closed) then
		local prog: Progress = story.Active[trackedId]
		local step = stepsOf(trackedId, prog)[prog.Step]
		local function wants(s: { [string]: any }?)
			if needNpc == nil and s and s.Type == "Talk" and type(s.Npc) == "string" then
				needNpc = s.Npc
				needPlace = if type(s.Place) == "string" then Subjects.resolve(s.Place, degreeOf(story)) else nil
			end
		end
		if step and step.Type == "Group" then
			for i, child in step.Steps do
				if not (prog.Sub and prog.Sub[tostring(i)]) then
					wants(child)
				end
			end
		else
			wants(step)
		end
	end
	player:SetAttribute("StoryNpc", needNpc)
	player:SetAttribute("StoryNpcPlace", needPlace)
	-- La Grieta del cielo: qué fase de la saga ve este jugador (la dibuja su cliente, Controllers/SkyRift)
	if SkyRift.stuckPrologue(story) and not rt.WarnedStuckPrologue then
		-- (prólogo activo con misiones de después ya hechas: la grieta se ve en Valmar, no en el sueño)
		rt.WarnedStuckPrologue = true
		warn(("[LifeStory] %s tiene el prólogo activo con misiones de después hechas: la grieta hace como si no estuviera"):format(player.Name))
	end
	player:SetAttribute("SkyRift", SkyRift.phaseFor(story))
	local encoded = HttpService:JSONEncode(state)
	if force or encoded ~= rt.LastPublished then
		rt.LastPublished = encoded
		send(player, "State", state)
	end
end

---------------------------------------------------------------------
-- Avanzar misiones
---------------------------------------------------------------------

local completeQuest -- se define más abajo
local advance -- se define más abajo
local ensureWeapon -- se define más abajo (armas prestadas de un combate)
local endPrologue -- se define más abajo

local function sendChoice(player: Player, questId: string, step: { [string]: any })
	local data = DataService.get(player)
	local ctx = if data then contextFor(player, data) else nil
	local options = {}
	for _, option in step.Options do
		-- Opciones con If (la nota de corte de una carrera…): solo se ven si se cumplen
		-- (el servidor rechazaría las demás)
		if not option.If or (ctx and Conditions.check(option.If, ctx)) then
			table.insert(options, { Id = option.Id, TextKey = option.Text or option.TextKey })
		end
	end
	local rt = runtime[player]
	if rt then
		rt.ChoiceSentAt[questId] = os.clock()
	end
	send(player, "Choice", { QuestId = questId, PromptKey = step.Prompt or step.PromptKey or step.Text or step.TextKey, Options = options })
end

-- ¿Se elige en el mundo (hablar con alguien, tocar un objeto) en vez de con una ventana?
local function worldChoice(step: { [string]: any }): boolean
	for _, option in step.Options or {} do
		if option.Npc or option.Prop then
			return true
		end
	end
	return false
end

local function questDialogue(questId: string, name: any): { [string]: any }?
	if type(name) == "table" then
		return name -- diálogo escrito directamente en el paso
	end
	local quest = Quests[questId]
	return quest and quest.Dialogues and quest.Dialogues[name]
end

-- Contexto de un diálogo: condiciones con lo que recuerda el personaje, efectos, cámara.
-- Los efectos de cada línea u opción se apuntan en el progreso (DlgApplied, se guarda): si sales a
-- mitad de la conversación y vuelves, se repite la charla pero no se cobra ni se gana dos veces.
local function dialogueContext(player: Player, data: Data, questId: string, label: string): DialogueService.Context
	local story = storyOf(data)
	local prog = story.Active[questId]
	return {
		check = function(condition)
			return (Conditions.check(condition, contextFor(player, data)))
		end,
		apply = function(effects, key)
			if key and prog and effects then
				local id = label .. key
				prog.DlgApplied = prog.DlgApplied or {}
				if prog.DlgApplied[id] then
					return
				end
				prog.DlgApplied[id] = true
			end
			applyEffects(player, data, effects, questId)
		end,
		actorOf = function(npc)
			return SceneService.actorOf(player, npc)
		end,
		args = function()
			local current = story.Choices.NombreGrupo
			return { grupo = if current then current.V else "" }
		end,
	}
end

---------------------------------------------------------------------
-- Lo que empieza SOLO (escenas, minijuegos, escenas de cine, decisiones, el plan B de un «habla
-- con…») nunca interrumpe:
--   · mientras vas en un vehículo (conduciendo o de pasajero: coche, moto, patinete, barco, autobús,
--     metro, tren, avión) espera a que te bajes, y te llega un aviso pequeño de móvil
--     («📱 Abu Rosa quiere hablar contigo — bájate para hablar»). Salvo los pasos pensados para
--     pasar dentro de un vehículo (InVehicle = true en el paso).
--   · de una misión que NO sigues, no empieza nunca sola: solo si hablas con alguien de su escena,
--     si la sigues (panel de misiones) o si acabas de hacer algo en ella (Engaged: hablaste con su
--     personaje, usaste su objeto, elegiste… y lo siguiente es una escena de esa misma misión).
-- Llegar a un sitio («Reach») sí se cumple al pasar conduciendo; lo que venga después espera.
---------------------------------------------------------------------
LifeStoryService.EngagedSeconds = 90 -- lo que dura «acabas de hacer algo en esta misión»

local function engage(player: Player, questId: string)
	local rt = runtime[player]
	if rt then
		rt.Engaged = rt.Engaged or {}
		;(rt.Engaged :: any)[questId] = os.clock()
	end
end

-- ¿Puede empezar ya solo este paso? Si no, por qué: "Ride" (va en un vehículo) o "Untracked"
-- (es de una misión que no sigue)
local function canAutoStart(player: Player, data: Data, questId: string, step: { [string]: any }?): (boolean, string?)
	if not (step and step.InVehicle) and RideState.inVehicle(player) then
		return false, "Ride"
	end
	if questId == PROLOGUE then
		return true, nil
	end
	-- La que sigues (aunque ahora no se vea en la tarjeta, p. ej. la del cole antes de ir) o la que
	-- enseña la tarjeta (en horario de cole, el día de cole)
	local story = storyOf(data)
	if story.Tracked == questId or trackedQuest(data) == questId then
		return true, nil
	end
	-- Sin ninguna seguida, la historia principal es la tuya
	local prog = story.Active[questId]
	if prog and prog.Kind == "Main" and not (story.Tracked and story.Active[story.Tracked]) then
		return true, nil
	end
	local rt = runtime[player]
	local at = rt and rt.Engaged and rt.Engaged[questId]
	if at and os.clock() - at <= LifeStoryService.EngagedSeconds then
		return true, nil
	end
	return false, "Untracked"
end
LifeStoryService.canAutoStart = function(player: Player, questId: string): (boolean, string?)
	local data = DataService.get(player)
	local prog = data and storyOf(data).Active[questId]
	if not data or not prog then
		return false, nil
	end
	return canAutoStart(player, data, questId, stepsOf(questId, prog)[prog.Step])
end

-- Quién habla primero en la conversación de un paso (para el aviso del móvil)
local function firstSpeaker(questId: string, step: { [string]: any }): string?
	local dialogue = step.Dialogue and questDialogue(questId, step.Dialogue)
	for _, line in (dialogue and (dialogue.Lines or dialogue)) or {} do
		if type(line) == "table" and type(line.S) == "string" and line.S ~= "Narrador" and line.S ~= "Yo" then
			return line.S
		end
	end
	if step.Type == "Talk" and type(step.Npc) == "string" then
		return step.Npc
	end
	return nil
end

-- Aviso pequeño, sin parar el juego (una vez por paso y motivo), de que algo de la historia te espera
local function holdNotice(player: Player, questId: string, step: { [string]: any }, stepIndex: number, reason: string)
	local rt = runtime[player]
	if not rt then
		return
	end
	rt.HeldNotice = rt.HeldNotice or {}
	local key = ("%s:%d:%s"):format(questId, stepIndex, reason)
	if (rt.HeldNotice :: any)[key] then
		return
	end
	-- (de misiones que no sigues, como mucho un aviso por minuto: al entrar puede haber varias esperando)
	if reason == "Untracked" then
		if rt.UntrackedPingAt and os.clock() - rt.UntrackedPingAt < 60 then
			return
		end
		rt.UntrackedPingAt = os.clock()
	end
	;(rt.HeldNotice :: any)[key] = true
	local quest = Quests[questId]
	local abu = DialogueService.speaker(player, "Abu")
	local familia = DialogueService.speaker(player, "Familia")
	local title = Strings.get(quest and quest.TitleKey or questId, { abu = abu or "", familia = familia or "" })
	local speakerId = firstSpeaker(questId, step)
	local who = if speakerId then DialogueService.speaker(player, speakerId) else nil
	local text
	if reason == "Ride" then
		text = if who then ("📱 %s quiere hablar contigo — bájate para hablar"):format(who)
			else ("📱 «%s» sigue cuando te bajes del vehículo"):format(title)
	else
		text = if who then ("📱 %s quiere hablar contigo («%s»). Ve a hablar con %s o síguela en Misiones."):format(who, title, who)
			else ("📱 «%s» te espera: síguela en Misiones para continuar."):format(title)
	end
	Log.info("MISSION", "%s: paso %d en espera (%s) · %s", questId, stepIndex, reason, player.Name)
	notify("Held", player, questId, { Step = stepIndex, Type = step.Type, Reason = reason })
	send(player, "Ping", { Icon = "📱", Text = text, Reason = reason, QuestId = questId })
end

-- La ventana de una decisión que sale sola: conduciendo o de una misión que no sigues, espera (y
-- se vuelve a intentar enseguida: ChoiceSentAt = 0)
local function autoChoice(player: Player, data: Data, questId: string, step: { [string]: any }): boolean
	local ok, why = canAutoStart(player, data, questId, step)
	if not ok then
		local rt = runtime[player]
		local prog = storyOf(data).Active[questId]
		if rt then
			rt.ChoiceSentAt[questId] = 0
		end
		if prog then
			holdNotice(player, questId, step, prog.Step, why or "Untracked")
		end
		return false
	end
	sendChoice(player, questId, step)
	return true
end

-- Juega una conversación de la misión; onDone cuando termine. Si ya hay otra, se reintenta luego.
-- label: de dónde sale la conversación si viene escrita en el paso (para recordar sus efectos)
local function playDialogue(player: Player, data: Data, questId: string, name: any, onDone: () -> (), label: string?): boolean
	local dialogue = questDialogue(questId, name)
	local rt = runtime[player]
	if not dialogue then
		warn(("[LifeStory] %s: no existe el diálogo %s"):format(questId, tostring(name)))
		task.spawn(onDone)
		return true
	end
	if not rt or rt.Busy then
		return false
	end
	rt.Busy = true
	rt.BusySince = os.clock()
	local tag = if type(name) == "string" then name else (label or "Paso")
	local started = DialogueService.play(player, dialogue, dialogueContext(player, data, questId, tag), function()
		rt.Busy = false
		rt.DialogueEndedAt = os.clock() -- el toque que cierra la conversación no abre otra
		onDone()
	end, function()
		-- Conversación cortada (murió, se fue, el vigilante): no cuenta, se podrá repetir
		rt.Busy = false
		rt.DialogueEndedAt = os.clock()
	end)
	if not started then
		rt.Busy = false
	else
		local prog = storyOf(data).Active[questId]
		notify("Dialogue", player, questId, { Dialogue = dialogue, Name = if type(name) == "string" then name else "(en el paso)", Step = prog and prog.Step })
	end
	return started
end

-- Actores y objetos que tiene que haber en escena en el paso actual de una misión
local function sceneFor(player: Player, data: Data, questId: string): ({ { [string]: any } }, { string })
	local quest = Quests[questId]
	local prog = storyOf(data).Active[questId]
	local step = prog and stepsOf(questId, prog)[prog.Step]
	local ctx = contextFor(player, data)
	local degree = degreeOf(storyOf(data))
	local actors, props = {}, {}
	local seenProp = {}
	local function addActors(list: { { [string]: any } }?)
		for _, spec in list or {} do
			if not spec.If or Conditions.check(spec.If, ctx) then
				-- "$Carrera.Facultad" -> la facultad de la carrera que elegiste
				local place = Subjects.resolve(spec.Place, degree)
				if place ~= spec.Place then
					spec = table.clone(spec)
					spec.Place = place
				end
				table.insert(actors, spec)
			end
		end
	end
	local function addProp(id: string?)
		local def = id and quest.Props and quest.Props[id]
		if id and def and not seenProp[id] and not (prog and prog.Used and prog.Used[id]) then
			if not def.If or Conditions.check(def.If, ctx) then
				seenProp[id] = true
				table.insert(props, id)
			end
		end
	end
	addActors(quest.Actors)
	if step then
		addActors(step.Actors)
		-- Una escena de cine sin reparto propio sigue con el del paso de antes (antes desaparecían todos
		-- justo en la foto de clase o en el final de la saga, y volvían a salir de golpe después)
		if step.Type == "Cinematic" and step.Actors == nil and prog and prog.Step > 1 then
			local before = stepsOf(questId, prog)[prog.Step - 1]
			addActors(before and before.Actors)
		end
		if step.Type == "Fight" then
			-- Los enemigos que quedan en pie: te persiguen y el botón es para atacar
			local enemies = {}
			for _, enemy in step.Enemies or {} do
				if not (prog.Sub and prog.Sub[enemy.Npc]) then
					local spec = table.clone(enemy)
					spec.Mode = spec.Mode or "Hunt"
					spec.Action = spec.Action or step.Action or "Atacar"
					-- Enemigo: sin cartel de «Interactuar»; se le ataca (botón de atacar, arma, rayo de la barra)
					spec.Enemy = true
					spec.Prompt = false
					spec.Place = spec.Place or step.Place
					-- Vida por puntos: el modelo la lleva en EnemyHealth / EnemyMaxHealth (su barra)
					spec.MaxHealth = EnemyStats.maxHealth(enemy, step)
					spec.Health = if prog.Hp and type(prog.Hp[enemy.Npc]) == "number" then prog.Hp[enemy.Npc] else spec.MaxHealth
					table.insert(enemies, spec)
				end
			end
			addActors(enemies)
		end
		for _, id in step.Props or {} do
			addProp(id)
		end
		if step.Type == "Use" then
			addProp(step.Prop)
		end
		for _, child in (if step.Type == "Group" then step.Steps else {}) do
			if child.Type == "Use" and not (prog.Sub and prog.Sub[tostring(table.find(step.Steps, child))]) then
				addProp(child.Prop)
			end
		end
		for _, option in (if step.Type == "Choice" then step.Options else {}) do
			addProp(option.Prop)
		end
	end
	return actors, props
end

local function updateScene(player: Player, data: Data, questId: string)
	local quest = Quests[questId]
	if not quest or not (quest.Props or quest.Actors or quest.Dialogues or quest.DayPlan) then
		return -- misión sencilla, sin escena
	end
	local actors, props = sceneFor(player, data, questId)
	-- Objetos en "$Carrera.X": se colocan donde toca según tu carrera
	local defs = quest.Props
	local degree = degreeOf(storyOf(data))
	for id, def in quest.Props or {} do
		local place = Subjects.resolve(def.Place, degree)
		if place ~= def.Place then
			if defs == quest.Props then
				defs = table.clone(quest.Props)
			end
			defs[id] = table.clone(def)
			defs[id].Place = place
		end
	end
	SceneService.set(player, questId, actors, props, defs)
end

---------------------------------------------------------------------
-- Volver a la escena al entrar: si te fuiste en mitad de una clase y apareces lejos,
-- el profe no puede ponerse a hablar sin ti. Se te devuelve al sitio de la escena.
---------------------------------------------------------------------

-- Pasos que ocurren en un sitio concreto con gente u objetos (los "Reach" ya te guían con la luz)
local PLACED_STEPS = { Scene = true, Class = true, Choice = true, MiniGame = true, Talk = true, Use = true, Group = true }
local RETURN_DISTANCE = 120 -- más lejos que esto de la escena = te has perdido

-- where = "Lugar" o { Place, Index?, Offset? } (un actor, un objeto, un pupitre…)
local function placePosition(player: Player, where: any): Vector3?
	local placeId = if type(where) == "table" then where.Place else where
	local place = type(placeId) == "string" and Locations.Places[placeId]
	if not place or place.Special == "NearPlayer" or (type(where) == "table" and where.Mode == "Follow") then
		return nil
	end
	local spot = if type(where) == "table"
		then LocationService.resolve(player, placeId, { Index = where.Index, Offset = where.Offset })
		else LocationService.resolve(player, placeId)
	return spot and spot.Position
end

-- Dónde ocurre el paso actual de una misión (nil si no está atado a un sitio)
local function sceneAnchor(player: Player, data: Data, questId: string): Vector3?
	local story = storyOf(data)
	local prog = story.Active[questId]
	local steps = prog and stepsOf(questId, prog)
	local step = steps and steps[prog.Step]
	if not step or not PLACED_STEPS[step.Type] then
		return nil
	end
	if step.Teleport then
		return placePosition(player, step.Teleport)
	end
	if step.Place then
		return placePosition(player, Subjects.resolve(step.Place, degreeOf(story)))
	end
	-- El centro de la gente y los objetos de la escena (el aula, el patio…)
	local actors, props = sceneFor(player, data, questId)
	local quest = Quests[questId]
	local sum, count = Vector3.zero, 0
	local points = {}
	local function add(spec: { [string]: any }?)
		local position = spec and spec.Place and placePosition(player, spec)
		if position then
			sum += position
			count += 1
			table.insert(points, position)
		end
	end
	for _, spec in actors do
		add(spec)
	end
	for _, id in props do
		add(quest.Props and quest.Props[id])
	end
	if count > 0 then
		local center = sum / count
		-- Un paso repartido por la ciudad (un grupo de tareas: el tornillo en el parque, la bobina en
		-- la heladería, el chip en el colegio…) no tiene UN sitio: el centro de todos es un punto
		-- cualquiera entre medias. Antes te llevaba ahí cada vez que entrabas («apareces siempre en
		-- el mismo sitio»); ahora te quedas donde lo dejaste y el GPS te guía.
		for _, position in points do
			local offset = position - center
			if Vector3.new(offset.X, 0, offset.Z).Magnitude > RETURN_DISTANCE then
				return nil
			end
		end
		return center
	end
	-- Si no, el último sitio al que te llevó la misión
	local ctx = contextFor(player, data)
	for i = prog.Step - 1, math.max(1, prog.Step - 6), -1 do
		local prev = steps[i]
		if prev and (not prev.If or Conditions.check(prev.If, ctx)) then
			local position = (prev.Teleport and placePosition(player, prev.Teleport)) or (prev.Place and placePosition(player, prev.Place))
			if position then
				return position
			end
		end
	end
	return nil
end

-- Si la misión que estabas jugando pasa en otro sitio, te lleva allí (una sola vez, al entrar).
-- only = solo mira esa misión (al reaparecer: la que sigues)
local function returnToScene(player: Player, data: Data, only: string?)
	local story = storyOf(data)
	local root = LocationService.positionOf(player)
	if not root or held(player) then
		return -- (muerto o detenido: se queda donde está)
	end
	local ids = {}
	if only then
		if story.Active[only] then
			table.insert(ids, only)
		end
	else
		if story.Tracked and story.Active[story.Tracked] then
			table.insert(ids, story.Tracked)
		end
		for id in story.Active do
			if id ~= story.Tracked then
				table.insert(ids, id)
			end
		end
	end
	for _, questId in ids do
		local anchor = sceneAnchor(player, data, questId)
		if anchor then
			local offset = anchor - root
			if Vector3.new(offset.X, 0, offset.Z).Magnitude > RETURN_DISTANCE then
				SceneService.teleportTo(player, anchor)
			end
			return
		end
	end
end

local startInteractive -- se define más abajo

-- Escena de cine de un paso: se ve en el cliente y la historia sigue cuando termina (o la salta;
-- si su pantalla no avisa, al cabo de un rato)
-- Si quien lleva la escena de este paso está lejos (llegaste al borde del parque y la escena es en
-- su centro), te acerca a él con un fundido (ActorStaging.gatherSpot). Sin Teleport en el paso.
local function gatherForStep(player: Player, questId: string, step: { [string]: any })
	if step.Teleport or held(player) then
		return
	end
	pcall(function()
		local speakers: { string } = {}
		local kind = if step.Type == "Cinematic" then "Cinematic" else "Scene"
		if kind == "Cinematic" then
			local def = HappeningIndex.get(step.Id)
			for _, line in ((def and def.Tracks) or {}).Dialogue or {} do
				if type(line) == "table" and type(line.S) == "string" and line.S ~= "Yo" and not table.find(speakers, line.S) then
					table.insert(speakers, line.S)
				end
			end
		else
			local dialogue = questDialogue(questId, step.Dialogue)
			speakers = StageDirector.castOf(dialogue and (dialogue.Lines or dialogue))
		end
		local lead = ActorStaging.lead(step.Actors, speakers)
		local me = LocationService.positionOf(player)
		if not lead or not me then
			return
		end
		local spot = LocationService.resolve(player, lead.Place, { Index = lead.Index, Offset = lead.Offset })
		local target = spot and ActorStaging.gatherSpot(me, spot.Position, kind)
		if target then
			SceneService.teleportTo(player, target, { Dip = true })
		end
	end)
end

local function playCinematicStep(player: Player, questId: string, step: { [string]: any }, index: number)
	gatherForStep(player, questId, step)
	local rt = runtime[player]
	if rt and rt.CineHeld then
		rt.CineHeld[questId] = nil
	end
	local duration = CinematicService.play(player, step.Id)
	CinematicService.waitFor(player, step.Id, duration, function()
		local current = DataService.get(player)
		local now = current and storyOf(current).Active[questId]
		if now and now.Step == index then
			advance(player, current, questId)
		end
	end)
end
local story_defaults -- se define más abajo
local processLater -- se define más abajo
local resumeAll -- se define más abajo
local groupDone -- se define más abajo
local hitEnemy -- se define más abajo

---------------------------------------------------------------------
-- Armas prestadas de un combate (Weapon = "RayoEncogedor" en un paso Fight): al empezar el paso
-- aparece en tu mochila / barra rápida (con aviso), vuelve si la pierdes (reaparecer, volver a
-- entrar) y se devuelve al acabar el paso o la misión. Se usa desde la barra (también en el móvil)
-- o con el botón que sale sobre el enemigo. story.Loans = { [objeto] = misión } (se guarda: así se
-- devuelve aunque la misión se cancele o salgas del juego a medias).
---------------------------------------------------------------------
local function loanStep(story: Data, itemId: string): (string?, { [string]: any }?)
	for questId, prog in story.Active do
		local step = stepsOf(questId, prog)[prog.Step]
		if step and step.Type == "Fight" and step.Weapon == itemId then
			return questId, step
		end
	end
	return nil, nil
end

-- Devuelve lo prestado que ya no toca (la misión acabó, cambió de paso o ya no existe)
local function returnLoans(player: Player, data: Data)
	local story = storyOf(data)
	for itemId in story.Loans or {} do
		if not loanStep(story, itemId) then
			story.Loans[itemId] = nil
			if InventoryService.count(player, itemId) > 0 then
				InventoryService.remove(player, itemId, 1)
			end
		end
	end
	if story.Loans and next(story.Loans) == nil then
		story.Loans = nil
	end
end

-- Que tengas el arma del combate (si ya era tuya, nada). announce: decirlo en pantalla
function ensureWeapon(player: Player, data: Data, questId: string, prog: Progress, step: { [string]: any }, announce: boolean?)
	local itemId = step.Weapon
	local item = type(itemId) == "string" and Items.get(itemId) or nil
	if not item then
		return
	end
	local story = storyOf(data)
	-- Idempotente: se llama al empezar el paso, en cada vuelta del combate, al reaparecer y al volver a
	-- entrar; si ya lo tienes (prestado o tuyo), no te da otro
	local has, given = InventoryService.ensure(player, itemId)
	if has and not given then
		if announce then
			notifyPlayer(player, "Success", ("%s Tienes el %s en tu barra: tócalo (o pulsa «%s» cerca) para usarlo."):format(item.Icon, item.Name, step.Action or "Atacar"))
		end
		return
	end
	if given then
		story.Loans = story.Loans or {}
		story.Loans[itemId] = questId
		notifyPlayer(player, "Success", ("%s Recibes el %s: está en tu barra. Tócalo (o pulsa «%s» cerca) para usarlo."):format(item.Icon, item.Name, step.Action or "Atacar"))
	elseif announce then
		-- Mochila llena: el botón sobre el enemigo sigue sirviendo
		notifyPlayer(player, "Info", ("%s Tu mochila está llena: pulsa «%s» cerca para usar el %s."):format(item.Icon, step.Action or "Atacar", item.Name))
	end
end

-- Vuelve a comprobar las armas prestadas de tus combates (lo mismo que al reaparecer o al volver a
-- entrar). Idempotente: nunca da una segunda copia.
function LifeStoryService.ensureLoans(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	for questId, prog in storyOf(data).Active do
		local step = stepsOf(questId, prog)[prog.Step]
		if step and step.Type == "Fight" and step.Weapon then
			ensureWeapon(player, data, questId, prog, step)
		end
	end
end

-- El enemigo de pie más cercano de un combate (a menos de range studs, en horizontal)
local function nearestEnemy(player: Player, prog: Progress, step: { [string]: any }, range: number): { [string]: any }?
	local me = LocationService.positionOf(player)
	if not me then
		return nil
	end
	local alive = {}
	for _, enemy in step.Enemies or {} do
		if not (prog.Sub and prog.Sub[enemy.Npc]) then
			table.insert(alive, enemy)
		end
	end
	local best = MissionCombat.nearest(alive, me, range, function(enemy)
		local model = SceneService.actorOf(player, enemy.Npc)
		return if model then model:GetPivot().Position else nil
	end)
	return best
end

-- El combate de misión en el que estás (questId: de esa misión; si no, el primero que haya)
local function fightOf(story: Data, questId: string?): (string?, Progress?, { [string]: any }?)
	for id, prog in story.Active do
		if questId == nil or id == questId then
			local step = stepsOf(id, prog)[prog.Step]
			if step and step.Type == "Fight" then
				return id, prog, step
			end
		end
	end
	return nil, nil, nil
end

-- Un impacto a un enemigo, con el ritmo máximo de MissionCombat (la pistola de agua dispara 8 veces por
-- segundo: no puede tumbar a nadie en un parpadeo)
local function strike(player: Player, data: Data, questId: string, prog: Progress, step: { [string]: any }, enemy: { [string]: any }, kind: string?): boolean
	local rt = runtime[player]
	if not rt then
		return false
	end
	local now = os.clock()
	if MissionCombat.ready(rt.LastHit, now) then
		rt.LastHit = now
		local how = kind or "Attack"
		-- (el modelo se coge antes: si este golpe le tumba, SceneService.defeat lo quita de los actores
		-- y luego no habría a quién poner el número ni el «Down»)
		local model = SceneService.actorOf(player, enemy.Npc)
		local counted, dealt, health, max, down = hitEnemy(player, data, questId, prog, step, enemy, how, EnemyStats.Sources[how] or EnemyStats.HitDamage, {})
		if counted then
			-- El número que sale encima (Controllers/HealthBars): como cualquier otro daño
			DamageService.notify(player, model or SceneService.actorOf(player, enemy.Npc), { Amount = dealt, Health = health, Max = max, Down = down, Kind = how })
		end
	end
	return true
end

-- Usar el arma prestada desde la barra: dispara al enemigo que quede más cerca (hasta 80 studs)
local WEAPON_RANGE = 80
function LifeStoryService.useWeapon(player: Player, itemId: string): boolean
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt then
		return false
	end
	local story = storyOf(data)
	local questId, step = loanStep(story, itemId)
	local prog = questId and story.Active[questId]
	if not questId or not step or not prog then
		return false
	end
	local best = nearestEnemy(player, prog, step, WEAPON_RANGE)
	if not best then
		notifyPlayer(player, "Info", "Acércate más para disparar.")
		return true
	end
	strike(player, data, questId, prog, step, best, "Gadget")
	return true
end

-- El botón de atacar (CombatController, hueco «Ataque»; también el clic): le da al enemigo más cercano
-- del combate en el que estás. Devuelve false si no estás en ningún combate o no hay nadie a tiro.
function LifeStoryService.missionAttack(player: Player): boolean
	local data = DataService.get(player)
	if not data or not runtime[player] or busy(player) or player:GetAttribute("Dead") or player:GetAttribute("Fallen") then
		return false
	end
	local story = storyOf(data)
	local questId, prog, step = fightOf(story, nil)
	if not questId or not prog or not step then
		return false
	end
	local best = nearestEnemy(player, prog, step, MissionCombat.Range)
	if not best then
		return false
	end
	return strike(player, data, questId, prog, step, best)
end

-- Daño a un enemigo de misión (lo manda DamageService: balas, golpes, poderes, piedras). Devuelve
-- (cuenta, daño hecho, vida que le queda, vida máxima, ¿ha caído?)
function LifeStoryService.enemyHit(player: Player, model: Model, kind: string, amount: number, info: { [string]: any }?): (boolean, number?, number?, number?, boolean?)
	local data = DataService.get(player)
	if not data or not runtime[player] then
		return false
	end
	local questId = model:GetAttribute(MissionCombat.ATTR)
	local npc = model:GetAttribute("NpcId")
	if type(questId) ~= "string" or type(npc) ~= "string" then
		return false
	end
	local id, prog, step = fightOf(storyOf(data), questId)
	if not id or not prog or not step or (prog.Sub and prog.Sub[npc]) then
		return false
	end
	for _, enemy in step.Enemies or {} do
		if enemy.Npc == npc then
			if kind == "Attack" or kind == "Gadget" then
				-- (el botón tiene su ritmo máximo, como siempre)
				local rt = runtime[player]
				local now = os.clock()
				if not MissionCombat.ready(rt.LastHit, now) then
					return false
				end
				rt.LastHit = now
			end
			return hitEnemy(player, data, id, prog, step, enemy, kind, amount, info or {})
		end
	end
	return false
end

-- (de antes) Un impacto del botón de atacar a un enemigo de misión
function LifeStoryService.hitModel(player: Player, model: Model): boolean
	return (LifeStoryService.enemyHit(player, model, "Attack", EnemyStats.Sources.Attack, {}))
end

-- Ayuda al apuntar (móvil): el enemigo de pie por el que pasa cerca un disparo
function LifeStoryService.aimAssist(player: Player, origin: Vector3, direction: Vector3, range: number): Model?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local questId, prog, step = fightOf(storyOf(data), nil)
	if not questId or not prog or not step then
		return nil
	end
	for _, enemy in step.Enemies or {} do
		if not (prog.Sub and prog.Sub[enemy.Npc]) then
			local model = SceneService.actorOf(player, enemy.Npc)
			if model and MissionCombat.aimed(origin, direction, model:GetPivot().Position, range) then
				return model
			end
		end
	end
	return nil
end

-- Prepara el paso actual de una misión. Los pasos "instantáneos" (Moment, Transition, If que no
-- se cumple) se resuelven aquí mismo y se pasa al siguiente.
---------------------------------------------------------------------
-- Hora solo para ti (M-01). Un paso Transition que dice una hora («Esa noche…», «Al día siguiente…»,
-- Clock = 7.5) mueve el reloj del servidor si juegas solo. Con más gente el reloj es de todos y no se
-- toca: el servidor pone en el jugador el atributo StoryClock (hora 0-24) y el cliente pinta la luz
-- de esa hora solo en su pantalla, con fundido, hasta que el atributo se quita (nil). Se quita al
-- acabar (o quitarse) la misión que lo pidió, con otra Transition de esa misión que no dice hora,
-- y como mucho a los LocalClockSeconds (luego manda otra vez el reloj de todos).
---------------------------------------------------------------------
LifeStoryService.LocalClockSeconds = 300

local function setLocalClock(player: Player, questId: string, clock: number)
	local rt = runtime[player]
	player:SetAttribute("StoryClock", clock % 24)
	if rt then
		rt.LocalClock = { Quest = questId, Until = os.clock() + LifeStoryService.LocalClockSeconds }
	end
end

local function clearLocalClock(player: Player)
	local rt = runtime[player]
	if rt then
		rt.LocalClock = nil
	end
	if player:GetAttribute("StoryClock") ~= nil then
		player:SetAttribute("StoryClock", nil)
	end
end

-- (en cada vuelta) ¿Sigue valiendo la hora local?
local function checkLocalClock(player: Player, data: Data)
	local rt = runtime[player]
	local lc = rt and rt.LocalClock
	if not lc then
		return
	end
	if os.clock() > lc.Until or not storyOf(data).Active[lc.Quest] then
		clearLocalClock(player)
	end
end

local function enterStep(player: Player, data: Data, questId: string)
	local story = storyOf(data)
	local quest = Quests[questId]
	local rt = runtime[player]
	while true do
		local prog: Progress? = story.Active[questId]
		if not prog then
			return
		end
		local step = stepsOf(questId, prog)[prog.Step]
		if not step then
			completeQuest(player, data, questId)
			return
		end
		prog.Count = 0
		prog.Sub = nil
		prog.Hp = nil
		prog.WaitUntil = nil
		prog.Chatted = nil -- con quién se ha charlado ya en este paso (no se repite la conversación)
		prog.DlgApplied = nil -- efectos de conversaciones ya aplicados en este paso
		if rt then
			rt.StepStart[questId] = os.clock()
			rt.NudgedAt[questId] = nil
			rt.Fallback[questId] = nil
		end
		if step.If and not Conditions.check(step.If, contextFor(player, data)) then
			notify("StepSkip", player, questId, { Step = prog.Step, Type = step.Type, Reason = "If" })
			prog.Step += 1
			continue
		end
		notify("StepEnter", player, questId, { Step = prog.Step, Type = step.Type })
		if step.Teleport and not heldAway(player) then
			LifeStoryService.teleportStep(player, step.Teleport)
		end
		if step.Type == "Moment" then
			moment(player, step.Text or step.TextKey or quest.MomentKey)
			applyEffects(player, data, step.Effects, questId)
			notify("StepDone", player, questId, { Step = prog.Step, Type = step.Type })
			prog.Step += 1
			continue
		elseif step.Type == "Transition" then
			-- La hora del día va con lo que dice («Esa noche…», «Al día siguiente…»): si juegas solo
			-- en el servidor, el reloj salta (como al dormir); con más gente, el reloj es de todos
			-- Con más gente, la hora cambia SOLO en tu pantalla (atributo StoryClock, ver setLocalClock):
			-- antes salía «Esa noche…» con el cielo de día
			local clock = step.Clock or LifeStoryService.clockFor(step.Text or step.TextKey)
			local localClock = false
			if clock and #Players:GetPlayers() <= 1 then
				clearLocalClock(player)
				pcall(function()
					require(script.Parent.WorldService).skipTo(clock)
				end)
			elseif clock then
				localClock = true
				setLocalClock(player, questId, clock)
			elseif rt and rt.LocalClock and rt.LocalClock.Quest == questId then
				-- «Un mes después…»: la noche de antes ya no vale
				clearLocalClock(player)
			end
			if step.Cinematic then
				CinematicService.play(player, step.Cinematic)
			else
				send(player, "Transition", {
					TextKey = step.Text or step.TextKey,
					Seconds = step.Seconds or 4,
					Clock = clock, -- (la hora de la que habla el texto, si dice una)
					LocalClock = if localClock then true else nil, -- solo en tu pantalla (StoryClock)
				})
			end
			if step.SetStage then
				LifeStoryService.setStage(player, step.SetStage)
			end
			applyEffects(player, data, step.Effects, questId)
			notify("StepDone", player, questId, { Step = prog.Step, Type = step.Type })
			prog.Step += 1
			continue
		elseif step.Type == "Wait" then
			prog.WaitUntil = waitTarget(step)
		elseif step.Type == "Group" then
			prog.Sub = {}
		elseif step.Type == "Fight" then
			prog.Sub = {}
			prog.Hp = {}
			returnLoans(player, data)
			ensureWeapon(player, data, questId, prog, step, true)
		elseif step.Type == "Choice" then
			if not worldChoice(step) then
				autoChoice(player, data, questId, step)
			end
		elseif step.Type == "Use" and step.Prop and prog.Used and prog.Used[step.Prop] then
			-- Ya lo cogiste antes de tiempo (se veía en el paso anterior): el paso está hecho (antes se
			-- quedaba sin objeto que coger, sin GPS, esperando)
			local index = prog.Step
			task.defer(function()
				local current = DataService.get(player)
				local now = current and storyOf(current).Active[questId]
				if now and now.Step == index then
					advance(player, current, questId)
				end
			end)
		elseif step.Type == "Event" and step.Event == "BabyStood" and story.Flags.BebeDePie then
			-- Ya se puso de pie antes de que empezara la misión (el botón ya no sale): paso hecho
			local index = prog.Step
			task.defer(function()
				local current = DataService.get(player)
				local now = current and storyOf(current).Active[questId]
				if now and now.Step == index then
					advance(player, current, questId)
				end
			end)
		elseif step.Type == "Event" and step.Event == "LicenseEarned" and type(step.Match) == "table" and type(step.Match.License) == "string" then
			-- ¿Ya tienes ese carnet? Entonces el paso está hecho (antes la autoescuela no te dejaba
			-- examinarte otra vez y la misión se quedaba atascada para siempre)
			local ok, has = pcall(function()
				return require(script.Parent.VehicleService).hasLicense(player, step.Match.License)
			end)
			if ok and has then
				local index = prog.Step
				task.defer(function()
					local current = DataService.get(player)
					local now = current and storyOf(current).Active[questId]
					if now and now.Step == index then
						advance(player, current, questId)
					end
				end)
			end
		elseif step.Type == "Cinematic" then
			-- La escena se ve en el cliente; la historia sigue cuando termina. Conduciendo (o de una
			-- misión que no sigues) espera: se ve al bajarte (stepTimers la lanza)
			local ok, why = canAutoStart(player, data, questId, step)
			if ok then
				playCinematicStep(player, questId, step, prog.Step)
			elseif rt then
				rt.CineHeld = rt.CineHeld or {}
				;(rt.CineHeld :: any)[questId] = prog.Step
				holdNotice(player, questId, step, prog.Step, why or "Untracked")
			end
		end
		break
	end
	if rt then
		-- Los lugares del paso anterior ya no sirven
		for key in rt.Spots do
			if key:sub(1, #questId + 1) == questId .. ":" then
				rt.Spots[key] = nil
			end
		end
	end
	updateScene(player, data, questId)
	startInteractive(player, data, questId)
	publish(player)
end

-- Pasos que empiezan solos: una conversación de escena o un minijuego
function startInteractive(player: Player, data: Data, questId: string)
	local story = storyOf(data)
	local prog = story.Active[questId]
	local step = prog and stepsOf(questId, prog)[prog.Step]
	local rt = runtime[player]
	if not step or not rt or not rt.Ready or player:GetAttribute("Dead") or player:GetAttribute("Fallen") or player:GetAttribute("KO") or busy(player) then
		return -- (muerto, en el suelo u ocupado: se reintenta luego)
	end
	local index = prog.Step
	local function stillHere(): boolean
		local current = DataService.get(player)
		local now = current and storyOf(current).Active[questId]
		return now ~= nil and now.Step == index
	end
	if player:GetAttribute("Dead") then
		return -- en el hospital no empieza ninguna escena (se reintenta al volver)
	end
	if step.Type == "Scene" or step.Type == "MiniGame" then
		-- Conduciendo, o de una misión que no sigues: espera (se reintenta en cada vuelta: stepTimers)
		local ok, why = canAutoStart(player, data, questId, step)
		if not ok then
			holdNotice(player, questId, step, index, why or "Untracked")
			return
		end
	end
	if step.Type == "Scene" and rt.StagedScene ~= questId .. ":" .. index then
		-- (por si te subiste justo ahora: la escena nunca empieza contigo montado, salvo InVehicle)
		if not step.InVehicle then
			CinematicService.leaveVehicle(player)
		end
		gatherForStep(player, questId, step)
	end
	if step.Type == "Scene" and type(step.Stage) == "string" and rt.StagedScene ~= questId .. ":" .. index then
		-- Stage = "IdDeEscena": la conversación la hace una escena del motor escrita a mano (Happenings)
		-- en lugar de la conversación escenificada sola. Al acabar (o saltarla) se dan los efectos de
		-- la conversación del paso y la historia sigue. Si la escena no puede empezar, se juega la
		-- conversación de siempre.
		local ok, HappeningService = pcall(function()
			return require(script.Parent.HappeningService)
		end)
		if ok and HappeningService.has(step.Stage) then
			rt.Busy = true
			rt.BusySince = os.clock()
			local playedOk, duration = pcall(CinematicService.play, player, step.Stage)
			if playedOk and type(duration) == "number" and duration > 0 then
				rt.StagedScene = questId .. ":" .. index
				CinematicService.waitFor(player, step.Stage, duration, function()
					rt.Busy = false
					rt.StagedScene = nil
					local current = DataService.get(player)
					if current and stillHere() then
						local dialogue = questDialogue(questId, step.Dialogue)
						if dialogue and dialogue.Effects then
							applyEffects(player, current, dialogue.Effects, questId)
						end
						advance(player, current, questId)
					end
				end)
				return
			end
			rt.Busy = false
		end
	end
	if step.Type == "Scene" then
		if rt.StagedScene == questId .. ":" .. index then
			return -- (su escena del motor está en marcha)
		end
		playDialogue(player, data, questId, step.Dialogue, function()
			if stillHere() then
				advance(player, data, questId)
			end
		end, "Scene")
	elseif step.Type == "MiniGame" then
		rt.Busy = true
		rt.BusySince = os.clock()
		local spec = step
		if step.PositionFrom then
			-- La posición que elegiste antes (delantero, defensa, portero) cambia las jugadas
			local choice = story.Choices[step.PositionFrom]
			spec = table.clone(step)
			spec.Position = choice and choice.V or "Delantero"
		end
		local started = MiniGameService.start(player, spec, function(result)
			rt.Busy = false
			if not stillHere() then
				return
			end
			story.LastGame = { Won = result.Won, Score = result.Score, Against = result.Against }
			applyEffects(player, data, if result.Won then step.Win else step.Lose, questId)
			if result.Detail and result.Detail.Draw then
				applyEffects(player, data, step.Draw, questId)
			end
			advance(player, data, questId)
		end)
		if not started then
			rt.Busy = false
			advance(player, data, questId) -- nunca bloquear la historia
		end
	end
end

function advance(player: Player, data: Data, questId: string)
	local prog = storyOf(data).Active[questId]
	if prog then
		local step = stepsOf(questId, prog)[prog.Step]
		local rt = runtime[player]
		if step then
			-- Lo que pasa al cumplir el paso (y si tardaste demasiado: "llegaste tarde")
			if step.Late and rt and rt.StepStart[questId] and os.clock() - rt.StepStart[questId] > step.Late.After then
				applyEffects(player, data, step.Late, questId)
			end
			applyEffects(player, data, step.Effects, questId)
			notify("StepDone", player, questId, { Step = prog.Step, Type = step.Type })
			Log.info("OBJECTIVE", "%s: paso %d (%s) completado · %s", questId, prog.Step, tostring(step.Type), player.Name)
			-- Lo has cumplido tú (hablar, usar, elegir, jugar…): lo que siga de esta misión puede
			-- empezar solo aunque no sea la que sigues. Llegar a un sitio o esperar no cuenta (se
			-- cumple al pasar por delante conduciendo: la escena que venga espera a que la sigas).
			if step.Type ~= "Reach" and step.Type ~= "Wait" then
				engage(player, questId)
			end
		end
		if storyOf(data).Active[questId] == prog then
			prog.Step += 1
			enterStep(player, data, questId)
		end
	end
end

-- Pasos añadidos a misiones que ya existían: el progreso se guarda como el NÚMERO de paso, así que a
-- quien estaba a medias se le corre el número para que siga en el mismo paso (y no uno antes).
-- STEP_INSERTS[misión][versión] = los números de paso NUEVOS de esa versión (en la lista nueva, de
-- menor a mayor). prog.V guarda la versión de los pasos con la que se empezó (sin V: la 1).
local STEP_INSERTS: { [string]: { [number]: { number } } } = {
	-- Escenas escritas a mano de la vida adulta (P8d)
	Adu01_PrimerContrato = { [2] = { 7, 9, 17 } }, -- Adu01_PrimerDia, Adu01_Firma, Adu01_Buzon
	Adu02_Atardecer = { [2] = { 4, 13 } }, -- Adu02_Hospital, Adu02_Orilla
	Adu03_Reencuentro = { [2] = { 13 } }, -- Adu03_Banco
	Adulto_LlegadaValmar = { [2] = { 2 } }, -- Adulto_Bienvenida
	-- Escenas del motor que se metieron sin apuntar la versión (las partidas no guardan V)
	Cole09_Misterio = { [2] = { 14 } }, -- Cinematic Cole09_LaFoto
	Saga_02_Grieta = { [2] = { 2 } }, -- Cinematic Grieta_Caen
}
-- Desde cuándo existen esos pasos (os.time, la fecha del commit que los metió): una partida sin V
-- empezada después ya tenía la lista nueva y no se le corre nada; una empezada antes, sí.
local STEP_SINCE: { [string]: { [number]: number } } = {
	Cole09_Misterio = { [2] = 1791291138 }, -- 2026-10-06 12:52:18 UTC
	Saga_02_Grieta = { [2] = 1790879853 }, -- 2026-10-01 18:37:33 UTC
}
local function stepsVersion(questId: string): number
	local latest = 1
	for version in STEP_INSERTS[questId] or {} do
		latest = math.max(latest, version)
	end
	return latest
end
LifeStoryService.stepsVersion = stepsVersion

-- Pone al día el número de paso de una partida guardada con pasos de una versión anterior
local function migrateSteps(questId: string, prog: { [string]: any })
	local inserts = STEP_INSERTS[questId]
	local latest = stepsVersion(questId)
	local version = tonumber(prog.V)
	if not version then
		version = 1
		local started = tonumber(prog.Started)
		for v, since in STEP_SINCE[questId] or {} do
			if started and started >= since then
				version = math.max(version, v)
			end
		end
	end
	if not inserts or version >= latest or type(prog.Step) ~= "number" then
		if inserts then
			prog.V = latest
		end
		return
	end
	local step = prog.Step
	for v = version + 1, latest do
		for _, index in inserts[v] or {} do
			if index <= step then
				step += 1
			end
		end
	end
	prog.Step = step
	prog.V = latest
end
LifeStoryService.migrateSteps = migrateSteps

local function startQuest(player: Player, data: Data, questId: string)
	local story = storyOf(data)
	if story.Active[questId] then
		return
	end
	local quest = Quests[questId]
	if not quest or not Validate.questOk(questId) then
		-- Misión con errores en sus datos (validador): no se activa, para no dejar a nadie atascado
		Log.error("MISSION", "failed %s: no pasa el validador, no se activa (%s)", questId, player.Name)
		notify("QuestInvalid", player, questId, nil)
		return
	end
	Log.info("MISSION", "started %s (%s)", questId, player.Name)
	local prog: any = { Step = 1, Count = 0, Started = os.time(), Kind = quest.Kind, V = if STEP_INSERTS[questId] then stepsVersion(questId) else nil }
	if quest.DayPlan then
		-- Día generado: cada vez con asignaturas y sorpresas distintas
		local plan = DayPlans.generate(quest.DayPlan, dayRng)
		if plan then
			prog.Steps = plan.Steps
			prog.TitleKey = plan.TitleKey
		end
		story.Counters = story.Counters or {}
		story.Counters[questId] = (story.Counters[questId] or 0) + 1
	end
	story.Active[questId] = prog
	if quest.Kind == "Main" then
		story.Tracked = questId
	end
	-- Ya ha empezado: lo que se esperaba (otra misión, la hora de abrir) ya no cuenta
	if runtime[player] then
		runtime[player].Waiting = nil
	end
	notify("QuestStart", player, questId, nil)
	-- Tarjeta de contexto al empezar: qué tipo de misión es, quién te lo pide y por qué. Sale antes que
	-- la primera conversación (la cola del cliente la enseña primero). No en los días normales que se
	-- repiten ni si acaba de aceptarla en una oferta (esa ya lo contaba).
	local rt = runtime[player]
	local offered = rt ~= nil and rt.JustOffered == questId
	if rt then
		rt.JustOffered = nil
	end
	if not offered and not quest.DayPlan and not quest.Repeatable and not quest.Prologue and quest.Description then
		local card = StoryContext.card(questId, { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") })
		if card then
			send(player, "QuestIntro", card)
		end
	end
	enterStep(player, data, questId)
end

local function giveRewards(player: Player, data: Data, rewards: { [string]: any }?)
	if not rewards then
		return
	end
	local story = storyOf(data)
	-- Dinero, marcas, recuerdos, objetos, relaciones… (los mismos efectos que en las misiones)
	applyEffects(player, data, rewards)
	if rewards.Degree then
		-- Título conseguido ("$Carrera.Titulo" -> "Grado_Medicina") con la nota media de la carrera
		local title = Subjects.resolve(rewards.Degree, degreeOf(story))
		if title then
			-- (solo las asignaturas de tu carrera: antes contaban también las del cole y el instituto)
			local degree = Subjects.Degrees[degreeOf(story) or ""]
			local own: { [string]: boolean } = {}
			for _, key in { "Asignatura1", "Asignatura2", "Practica", "Fisico" } do
				if degree and degree[key] then
					own[degree[key]] = true
				end
			end
			local sum, count = 0, 0
			for subjectId, entry in data.Education.Subjects do
				if own[subjectId] and type(entry.Avg) == "number" then
					sum += entry.Avg
					count += 1
				end
			end
			data.Education.Degrees[title] = { Grade = if count > 0 then math.round(sum / count * 10) / 10 else 5, At = os.time() }
		end
	end
	if rewards.SetStage then
		LifeStoryService.setStage(player, rewards.SetStage)
	end
end

function completeQuest(player: Player, data: Data, questId: string)
	local story = storyOf(data)
	local quest = Quests[questId]
	story.Active[questId] = nil
	story.Completed[questId] = os.time()
	if story.Tracked == questId then
		story.Tracked = nil
	end
	if quest.DayPlan then
		-- un día normal (cole, instituto, uni) por día de TU vida (CalendarService: se guarda con la
		-- partida; antes era el día del servidor y al volver a entrar se olvidaba)
		story.LoopDay = lifeDay(player)
		story.LoopLife = if player:GetAttribute("LifeDay") ~= nil then true else nil
	end
	Log.info("MISSION", "completed %s (%s)", questId, player.Name)
	notify("QuestDone", player, questId, nil)
	SceneService.clear(player, questId)
	returnLoans(player, data) -- (lo prestado se devuelve; si la recompensa es ese objeto, llega ahora)
	giveRewards(player, data, quest.Rewards)
	if quest.Memory then
		LifeStoryService.addMemory(player, quest.Memory, questId)
	end
	if quest.MomentKey then
		local sting = if quest.MomentSting == false then nil else (quest.MomentSting or "Momento")
		local args = if quest.DayPlan then { n = story.Counters[questId] or 1 } else nil
		moment(player, quest.MomentKey, args, sting :: string?)
	end
	if questId == PROLOGUE then
		endPrologue(player, data, "Done") -- vuelta a la vida real (y empieza el primer capítulo)
		return
	end
	refresh(player)
end

---------------------------------------------------------------------
-- Capítulos y misiones principales: qué toca ahora en tu vida
---------------------------------------------------------------------

local function chapterFits(chapter: Chapters.Chapter, stage: string, story: Data): boolean
	if not chapter.Enabled or not Stages.inRange(stage, chapter.Stage.Min, chapter.Stage.Max) then
		return false
	end
	-- Requisitos del capítulo (decisiones y marcas: "fue a la universidad"…); la hora no cuenta aquí
	return (Conditions.check(chapter.Requires, {
		Stage = stage,
		ClockTime = 12,
		Weekday = 1,
		Completed = story.Completed,
		Flags = story.Flags,
		Choices = story.Choices,
		Discovered = story.Discovered,
	}))
end

-- Por qué espera una misión con horario: está cerrado a esta hora, o hoy no abre (el fin de semana)
local function closedWait(questId: string, window: Schedules.Window?, weekday: number): { [string]: any }
	if window and not Schedules.opensOn(window, weekday) then
		return { QuestId = questId, Reason = "Weekdays" }
	end
	return { QuestId = questId, Reason = "Hours", From = window and window.From, To = window and window.To }
end

local function pickChapter(story: Data, stage: string): string?
	for _, id in chapterOrder do
		if not story.Chapters[id] and chapterFits(Chapters[id], stage, story) then
			return id
		end
	end
	return nil
end

function refresh(player: Player)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt then
		return
	end
	local story = storyOf(data)
	local stage = data.Life.Stage

	-- Durante el prólogo (el sueño) no empieza ningún capítulo: el primero llega al despertar
	if story.Active[PROLOGUE] then
		publish(player)
		return
	end

	-- Una escena de cámara en marcha (el montaje del cambio de etapa, el final de un capítulo): la
	-- cabecera del capítulo siguiente y su primera misión esperan a que acabe (antes salían las dos
	-- escenas a la vez). Como mucho SCENE_GATE_MAX s; al acabar, se vuelve a mirar.
	-- (la cabecera que acaba de entrar en este mismo repaso no hace esperar a su primera misión: eso
	-- ya lo ordena la cola de escenas del cliente)
	local enteredNow = false
	local function sceneGate(): boolean
		if enteredNow or not CinematicService.inScene(player) then
			rt.SceneGateSince = nil
			return false
		end
		rt.SceneGateSince = rt.SceneGateSince or os.clock()
		if os.clock() - (rt.SceneGateSince :: number) > SCENE_GATE_MAX then
			return false -- (una escena colgada no para la historia)
		end
		if not rt.SceneGateWaiting then
			rt.SceneGateWaiting = true
			task.spawn(function()
				pcall(CinematicService.waitUntilFree, player, SCENE_GATE_MAX)
				rt.SceneGateWaiting = nil
				if runtime[player] == rt then
					refresh(player)
				end
			end)
		end
		publish(player)
		return true
	end

	local function enterChapter(id: string)
		enteredNow = true
		story.Chapter = id
		local chapter = Chapters[id]
		if chapter.IntroCinematic then
			CinematicService.play(player, chapter.IntroCinematic)
		else
			send(player, "Chapter", { TitleKey = chapter.TitleKey, TextKey = chapter.IntroKey, Phase = "Intro" })
		end
		LifeStoryService.logEvent(player, chapter.TitleKey, nil, "Chapter")
	end

	for _ = 1, #chapterOrder + 1 do -- como mucho, recorrer todos los capítulos una vez
		local chapter = story.Chapter and Chapters[story.Chapter]
		-- Si el capítulo terminó justo cuando cambió la etapa (la última misión hace crecer al
		-- personaje), se da por terminado aquí; la pantalla de cambio de etapa ya lo ha contado.
		if chapter and not story.Chapters[chapter.Id] and not chapterFits(chapter, stage, story) then
			local allDone = true
			for _, questId in chapter.Main do
				allDone = allDone and story.Completed[questId] ~= nil
			end
			if allDone then
				story.Chapters[chapter.Id] = os.time()
			end
		end
		if not chapter or story.Chapters[chapter.Id] or not chapterFits(chapter, stage, story) then
			local nextId = pickChapter(story, stage)
			if not nextId then
				story.Chapter = nil
				break
			end
			if sceneGate() then
				return
			end
			enterChapter(nextId)
			chapter = Chapters[nextId]
		end
		assert(chapter)

		-- ¿Hay ya una principal en marcha?
		local mainActive = false
		for _, prog in story.Active do
			if prog.Kind == "Main" then
				mainActive = true
				break
			end
		end
		if mainActive then
			break
		end

		-- Siguiente principal del capítulo
		rt.Waiting = nil
		local pending: string? = nil
		for _, questId in chapter.Main do
			if not story.Completed[questId] then
				pending = questId
				break
			end
		end
		if not pending then
			-- Capítulo terminado
			story.Chapters[chapter.Id] = os.time()
			if chapter.OutroCinematic then
				CinematicService.play(player, chapter.OutroCinematic)
			else
				send(player, "Chapter", { TitleKey = chapter.TitleKey, TextKey = chapter.OutroKey, Phase = "Outro" })
			end
			local nextChapter = chapter.Next and Chapters[chapter.Next]
			if nextChapter and not story.Chapters[nextChapter.Id] and chapterFits(nextChapter, stage, story) then
				if sceneGate() then
					return -- (el final de este capítulo se está viendo: luego entra el siguiente)
				end
				enterChapter(nextChapter.Id)
			else
				story.Chapter = nil
			end
			continue
		end
		if not Validate.questOk(pending) then
			-- Una principal rota no puede bloquear la vida entera: se salta (y queda anotado)
			Log.error("MISSION", "failed %s: datos con errores, se salta para no bloquear el capítulo (%s)", pending, player.Name)
			notify("QuestInvalid", player, pending, nil)
			story.Skipped = story.Skipped or {}
			story.Skipped[pending] = os.time()
			story.Completed[pending] = os.time()
			continue
		end
		local ok, reason = Conditions.check(Quests[pending].Requires, contextFor(player, data))
		local now = GameClock.now()
		local clock, weekday = now.ClockTime, now.Weekday
		local window = Schedules.forQuest(Quests[pending])
		-- Un niño o adolescente en horario de cole solo ve las misiones del cole: una principal que no
		-- es del cole (los recados, la noche con la pandilla) espera a que acabe el cole (antes empezaba
		-- y no se veía hasta las 17:00)
		local afterSchool = (stage == "Nino" or stage == "Adolescente") and Quests[pending].Schedule ~= false
			and not Schedules.isSchool(window) and Schedules.isSchoolTime(clock, weekday)
		if ok and not Schedules.isOpen(window, clock, weekday) then
			-- Toca, pero el sitio está cerrado a esta hora (el colegio no abre de noche ni el fin de semana)
			rt.Waiting = closedWait(pending, window, weekday)
		elseif ok and afterSchool then
			rt.Waiting = { QuestId = pending, Reason = "Hours", From = Config.SchoolDay.End }
		elseif ok then
			-- (la primera del capítulo es la cabecera: espera a que acabe el montaje de antes)
			if pending == chapter.Main[1] and sceneGate() then
				return
			end
			startQuest(player, data, pending)
			return -- startQuest ya publica
		elseif reason == "StageProgress" and chapter.Loop and Quests[chapter.Loop] then
			-- Aún no toca el siguiente gran momento: se vive un día normal (colegio, instituto, universidad),
			-- uno por día de juego: si el de hoy ya está hecho, el siguiente es mañana cuando abra
			local loopWindow = Schedules.forQuest(Quests[chapter.Loop])
			if story.LoopDay == lifeDay(player) then
				rt.Waiting = { QuestId = chapter.Loop, Reason = "Hours", From = if loopWindow then loopWindow.From else Config.SchoolDay.Opens }
			elseif Schedules.isOpen(loopWindow, clock, weekday) then
				startQuest(player, data, chapter.Loop)
				return
			else
				rt.Waiting = closedWait(chapter.Loop, loopWindow, weekday)
			end
		elseif Conditions.isWaitOnly(reason) then
			rt.Waiting = { QuestId = pending, Reason = reason :: string }
		end
		break
	end
	publish(player)
end

---------------------------------------------------------------------
-- Prólogo («El sueño»): tutorial de controles jugable, antes del primer capítulo
-- La misión está en Misiones/Prologo_Sueno.luau y pasa en la isla del sueño (World/Kit/DreamIsland).
-- Mientras dura: atributo InPrologue = true, solo avanza el prólogo y no empieza ningún capítulo.
-- En el sueño el bebé es un poco mayor (atributo LifeStage = "Nino"; lo guardado sigue siendo Bebe):
-- así puede correr y saltar, y al despertar BabyService lo devuelve a su cuna.
-- Pase lo que pase (saltar, error, tope de tiempo, salir del juego) se vuelve al juego normal.
---------------------------------------------------------------------

local function completedSomething(story: Data): boolean
	for id in story.Completed do
		if id ~= PROLOGUE then
			return true
		end
	end
	return false
end

-- ¿Le toca el prólogo? Solo a un personaje nuevo que aún no ha empezado su vida (y una sola vez)
function LifeStoryService.needsPrologue(data: Data): boolean
	local story = storyOf(data)
	return CFG.Prologue == true
		and not story.PrologueDone
		and data.Life.Stage == CFG.NewCharacterStage
		and story.Chapter == nil
		and next(story.Chapters) == nil
		and not completedSomething(story)
end

-- Lo da por visto (aunque no se haya podido jugar): así nunca vuelve a bloquear a nadie
local function markPrologue(story: Data, result: string)
	if not story.PrologueDone then
		story.PrologueDone = os.time()
	end
	story.PrologueResult = result
end

local function startPrologue(player: Player, data: Data, replay: boolean): boolean
	local story = storyOf(data)
	local rt = runtime[player]
	if not rt or story.Active[PROLOGUE] then
		return false
	end
	if not Quests[PROLOGUE] or not Validate.questOk(PROLOGUE) then
		Log.error("MISSION", "prólogo con errores en sus datos: no se juega (%s)", player.Name)
		if not replay then
			markPrologue(story, "Error")
		end
		return false
	end
	-- Sin isla del sueño (mapa sin construir): directamente al juego normal
	if not LocationService.resolve(player, "PrologoInicio") then
		Log.warn("MISSION", "no hay isla del sueño (PrologoInicio): se salta el prólogo (%s)", player.Name)
		if not replay then
			markPrologue(story, "Unavailable")
		end
		return false
	end
	rt.PrologueSince = os.clock()
	rt.PrologueReplay = replay
	rt.PrologueReturn = LocationService.positionOf(player)
	rt.PrologueTracked = story.Tracked
	player:SetAttribute("InPrologue", true)
	if data.Life.Stage == "Bebe" then
		player:SetAttribute("LifeStage", "Nino") -- en el sueño eres un poco mayor
	end
	Log.info("MISSION", "prólogo: empieza%s (%s)", if replay then " (repetición)" else "", player.Name)
	local ok, err = pcall(startQuest, player, data, PROLOGUE)
	if not ok or not story.Active[PROLOGUE] then
		Log.error("MISSION", "prólogo: no se pudo empezar (%s): %s", player.Name, tostring(err))
		endPrologue(player, data, "Error")
		return false
	end
	return true
end
LifeStoryService.startPrologue = startPrologue

-- Cierra el prólogo (terminado, saltado, con error o por tiempo) y vuelve a la vida real
function endPrologue(player: Player, data: Data, result: string)
	local story = storyOf(data)
	local rt = runtime[player]
	local replay = rt ~= nil and rt.PrologueReplay == true
	if story.Active[PROLOGUE] then
		story.Active[PROLOGUE] = nil
		-- Si estaba hablando con Cosme o viendo el tornillo, la conversación se corta
		if DialogueService.isBusy(player) then
			pcall(DialogueService.cancel, player, "prologo")
		end
		if rt then
			rt.Busy = false
		end
	end
	pcall(SceneService.clear, player, PROLOGUE)
	if not replay then
		markPrologue(story, result)
	end
	if story.Tracked == PROLOGUE or story.Tracked == nil then
		story.Tracked = if rt and rt.PrologueTracked and story.Active[rt.PrologueTracked] then rt.PrologueTracked else nil
	end
	-- Vuelta a la vida real: el bebé, a su cuna (BabyService lo pone ahí al volver a ser bebé); los
	-- demás, donde estaban antes de dormirse
	local realStage = data.Life.Stage
	if player:GetAttribute("LifeStage") ~= realStage then
		player:SetAttribute("LifeStage", realStage)
	end
	pcall(function()
		if realStage == "Bebe" then
			SceneService.teleport(player, "Cuna")
		elseif rt and rt.PrologueReturn then
			SceneService.teleportTo(player, rt.PrologueReturn)
		end
	end)
	player:SetAttribute("PrologueBeat", nil)
	player:SetAttribute("InPrologue", nil)
	if rt then
		rt.PrologueSince, rt.PrologueReplay, rt.PrologueReturn, rt.PrologueTracked = nil, nil, nil, nil
		-- Lo que estaba a medias sigue como si no hubiera pasado el tiempo (sin "llegas tarde")
		for questId in story.Active do
			rt.StepStart[questId] = os.clock()
		end
		rt.Watch = nil
	end
	Log.info("MISSION", "prólogo: termina (%s) (%s)", result, player.Name)
	notify("PrologueEnd", player, PROLOGUE, { Result = result })
	refresh(player) -- (sin prólogo activo: empieza el primer capítulo, con su escena del nacimiento)
end
LifeStoryService.endPrologue = function(player: Player, result: string?)
	local data = DataService.get(player)
	if data and storyOf(data).Active[PROLOGUE] then
		endPrologue(player, data, result or "Skipped")
	end
end

---------------------------------------------------------------------
-- «Anteriormente en tu vida…»: resumen corto al volver al juego
---------------------------------------------------------------------

local function recapPayload(player: Player, data: Data): { [string]: any }
	local story = storyOf(data)
	local payload = StoryContext.recap(data)
	local trackedId = trackedQuest(data)
	if trackedId then
		local prog: Progress = story.Active[trackedId]
		local step = stepsOf(trackedId, prog)[prog.Step]
		payload.Objective = {
			QuestId = trackedId,
			TitleKey = titleOf(trackedId, prog),
			TextKey = step and (step.Text or step.TextKey),
			Args = step and placeArgs(step, prog, story),
			Icon = StoryContext.label(Quests[trackedId]).Icon,
		}
	end
	return payload
end
LifeStoryService.recapPayload = recapPayload

local function sendRecap(player: Player, data: Data)
	local rt = runtime[player]
	if rt then
		rt.RecapPending = nil
	end
	storyOf(data).RecapAt = os.time()
	send(player, "Recap", recapPayload(player, data))
	notify("Recap", player, nil, nil)
end

-- Al volver: si ya tenía una vida empezada y llevaba un rato fuera. Nunca encima de una conversación,
-- un minijuego o una clase: entonces espera (slowTick lo manda cuando esté libre).
local function queueRecap(player: Player, data: Data)
	local rt = runtime[player]
	if not rt or not StoryContext.hasProgress(data) or storyOf(data).Active[PROLOGUE] then
		return
	end
	if (rt.AwaySeconds or math.huge) < (CFG.RecapMinAwaySeconds or 0) then
		return
	end
	if busy(player) or held(player) then
		rt.RecapPending = true
		return
	end
	sendRecap(player, data)
end

---------------------------------------------------------------------
-- Secundarias: aparecen según dónde estás, qué haces y qué hora es
---------------------------------------------------------------------

local function activeSideCount(story: Data): number
	local count = 0
	for questId, prog in story.Active do
		-- Las canónicas (la saga) no cuentan: con una en marcha te siguen ofreciendo secundarias
		if prog.Kind == "Side" and not (Quests[questId] and Quests[questId].Canon) then
			count += 1
		end
	end
	return count
end

local function canOffer(player: Player, data: Data, questId: string): boolean
	local story = storyOf(data)
	local quest = Quests[questId]
	local rt = runtime[player]
	if not rt or story.Active[questId] then
		return false
	end
	-- Nada se ofrece en mitad de una conversación, una escena o una clase (el aviso taparía lo que pasa)
	if rt.Busy or DialogueService.isBusy(player) or player:GetAttribute("InDialogue") or inScene(player) then
		return false
	end
	-- Las canónicas (la saga) no esperan: no cuentan para el límite de secundarias ni se pueden rechazar
	if not quest.Canon and (rt.PendingOffer or activeSideCount(story) >= CFG.MaxActiveSide) then
		return false
	end
	local done = story.Completed[questId]
	if done and (not quest.Repeatable or os.time() - done < (quest.Cooldown or 0)) then
		return false
	end
	local declined = story.Declined[questId]
	if declined and not quest.Canon and os.time() - declined < CFG.DeclineCooldown then
		return false
	end
	-- Solo las rutinas (DayPlan o Schedule) esperan a que abra el sitio: no se ofrece ir al colegio de
	-- noche. Las de la historia y las locas pasan cuando pasan (la saga cose el cielo en el patio a las 21:00)
	local routine = quest.DayPlan ~= nil or quest.Schedule == true or type(quest.Schedule) == "string"
	if routine and not Schedules.isOpen(Schedules.forQuest(quest), GameClock.now().ClockTime, GameClock.now().Weekday) then
		return false
	end
	-- Ofertas de un oficio (Offer.Job = "Policia"): solo si de verdad trabajas en él (tu trabajo, estar de
	-- servicio en ese rol o tener ya puntos de carrera en él). No se ofrece ascender en la policía a quien
	-- solo pasa por delante de la comisaría.
	if quest.Offer and type(quest.Offer.Job) == "string" and not LifeStoryService.hasJob(player, quest.Offer.Job) then
		return false
	end
	return (Conditions.check(quest.Requires, contextFor(player, data)))
end

-- ¿Trabaja el jugador en ese oficio? (atributo Job, de servicio en RoleService o puntos de carrera)
function LifeStoryService.hasJob(player: Player, jobId: string): boolean
	if player:GetAttribute("Job") == jobId or player:GetAttribute("RankInst") == jobId then
		return true
	end
	local points = player:GetAttribute("Career_" .. jobId)
	if type(points) == "number" and points > 0 then
		return true
	end
	local ok, duties = pcall(RoleService.dutiesOf, player)
	return ok and type(duties) == "table" and duties[jobId] ~= nil
end

-- ¿Hay algo de la historia que impida que alguien de la calle te pida un favor ahora mismo? (los
-- encargos de la ciudad, CityErrandService). Las mismas reglas que las secundarias: nada en mitad de
-- una conversación, una escena, una clase o un minijuego, ni con una propuesta de la historia en
-- pantalla, ni en el prólogo; y en horario de cole, si sigues una misión principal, tampoco (toca
-- el cole). Devuelve el motivo ("Busy" o "Story") o nil si no hay nada.
function LifeStoryService.errandBlock(player: Player): string?
	local rt = runtime[player]
	if busy(player) or held(player) or player:GetAttribute("InDialogue") or player:GetAttribute("InPrologue") then
		return "Busy"
	end
	if rt and rt.PendingOffer then
		return "Busy"
	end
	local data = DataService.get(player)
	if data and Schedules.isSchoolTime(GameClock.now().ClockTime, GameClock.now().Weekday) then
		local id = trackedQuest(data)
		local quest = id and Quests[id]
		if quest and quest.Kind == "Main" then
			return "Story"
		end
	end
	return nil
end

local function offer(player: Player, questId: string)
	local rt = runtime[player]
	local quest = Quests[questId]
	if RideState.inVehicle(player) then
		return -- (conduciendo no sale ninguna tarjeta con botones: se ofrecerá cuando vayas a pie)
	end
	rt.PendingOffer = questId
	rt.OfferedAt = os.clock()
	-- Con su contexto: tipo (⭐/🌀/❗), quién te lo pide y por qué (Description)
	local card = StoryContext.card(questId, { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") }) or {}
	send(player, "Offer", {
		QuestId = questId,
		TitleKey = quest.TitleKey,
		TextKey = quest.OfferKey,
		Description = card.Description,
		Icon = card.Icon,
		Label = card.Label,
		Type = card.Kind,
		Asker = card.Asker,
	})
end

local function checkPlaceOffers(player: Player, data: Data)
	if RideState.inVehicle(player) then
		return -- (pasar por delante conduciendo no ofrece ni empieza nada: al bajarte allí, sí)
	end
	for questId, quest in Quests do
		if quest.Kind == "Side" and quest.Offer and quest.Offer.Place and canOffer(player, data, questId) then
			local spot = LocationService.resolve(player, quest.Offer.Place)
			if spot and LocationService.isAt(player, spot) then
				if quest.Canon then
					-- Misión canónica: empieza sola al llegar (su marca estaba en el mapa)
					moment(player, quest.OfferKey or quest.TitleKey, nil, "Momento")
					startQuest(player, data, questId)
					-- Y pasa a ser la que juegas (tarjeta, GPS y quién te acompaña), como al aceptar una
					local story = storyOf(data)
					if story.Active[questId] and not story.Active[PROLOGUE] then
						story.Tracked = questId
						publish(player)
					end
				else
					offer(player, questId)
				end
				return
			end
		end
	end
end

-- Misiones canónicas disponibles: marca en el mapa y en el mundo hasta que las haces.
-- Se publican en el atributo CanonMarks (JSON): { { Id, Title, X, Y, Z, From?, To? } }
local function updateCanonMarks(player: Player, data: Data)
	local rt = runtime[player]
	local story = storyOf(data)
	local ctx = contextFor(player, data)
	local marks = {}
	rt.CanonSpots = rt.CanonSpots or {}
	for questId, quest in Quests do
		if quest.Canon and quest.Offer and quest.Offer.Place and not story.Active[questId] and not story.Completed[questId] then
			local req = quest.Requires
			local hours = req and req.Hours
			if hours then
				req = table.clone(req)
				req.Hours = nil
			end
			if Conditions.check(req, ctx) then
				local spot = rt.CanonSpots[questId]
				if not spot or not spot.Instance:IsDescendantOf(workspace) then
					spot = LocationService.resolve(player, quest.Offer.Place)
					rt.CanonSpots[questId] = spot
				end
				if spot then
					table.insert(marks, {
						Id = questId,
						Title = quest.Title,
						X = math.round(spot.Position.X), Y = math.round(spot.Position.Y), Z = math.round(spot.Position.Z),
						From = hours and hours.From, To = hours and hours.To,
					})
				end
			end
		end
	end
	table.sort(marks, function(a, b)
		return a.Id < b.Id
	end)
	local encoded = HttpService:JSONEncode(marks)
	if player:GetAttribute("CanonMarks") ~= encoded then
		player:SetAttribute("CanonMarks", encoded)
	end
end

---------------------------------------------------------------------
-- Eventos de otros sistemas
---------------------------------------------------------------------

-- ¿Grupo terminado? (Need = cuántas cosas de la lista hacen falta; si no, todas)
function groupDone(step: { [string]: any }, sub: { [string]: boolean }, ctx: Conditions.Context?): boolean
	local done = 0
	for _ in sub do
		done += 1
	end
	-- Solo cuentan las tareas que existen para este jugador (las que tienen un If que no se cumple, no)
	local available = #step.Steps
	if ctx then
		available = 0
		for _, child in step.Steps do
			if not child.If or Conditions.check(child.If, ctx) then
				available += 1
			end
		end
	end
	return done >= math.min(step.Need or available, available)
end

-- Al reaparecer en el hospital: vuelta a donde pasa la misión (el sitio del paso actual o su escena).
-- Si entretanto te han detenido (tenías estrellas) o sigues muerto, te quedas donde estás.
local function afterRevive(player: Player)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt or not rt.Ready or not player.Parent or held(player) then
		return
	end
	-- Solo la misión que SIGUES (la del panel y el GPS): antes valía el Teleport del paso de cualquier
	-- misión activa, y una secundaria que no seguías te llevaba a la otra punta de la ciudad (M-02).
	-- (el fundido lo pone SceneService.teleport/teleportTo)
	local questId = trackedQuest(data)
	if not questId then
		return
	end
	local story = storyOf(data)
	local prog = story.Active[questId]
	local step = prog and stepsOf(questId, prog)[prog.Step]
	if step and step.Teleport then
		SceneService.teleport(player, step.Teleport)
		return
	end
	returnToScene(player, data, questId)
end

local function onStoryEvent(player: Player, name: string, payload: { [string]: any })
	local data = DataService.get(player)
	if not data or not runtime[player] then
		return
	end
	local story = storyOf(data)
	if name == "Died" or name == "Arrested" then
		-- Al morir o al ser detenido se corta la conversación (no cuenta: se repetirá al volver,
		-- no desde la celda); los controles vuelven solos
		DialogueService.cancel(player, name)
		-- Y el minijuego: no cuenta como perdido (no se llama a su final) y la historia no se queda
		-- ocupada; el paso se vuelve a proponer al volver (stepTimers: startInteractive)
		if MiniGameService.isRunning(player) then
			pcall(MiniGameService.cancel, player)
			runtime[player].Busy = false
		end
	end
	if name == "Revived" and not payload.Jailed then
		-- (se espera un poco: al avisar, el hospital aún no ha quitado "Dead" y puede detenerte justo después)
		task.delay(1, function()
			local ok, err = pcall(afterRevive, player)
			if not ok then
				warn("[LifeStory] " .. tostring(err))
			end
		end)
	end

	local ids = {}
	for id in story.Active do
		table.insert(ids, id)
	end
	for _, questId in ids do
		local prog: Progress? = story.Active[questId]
		local step = prog and stepsOf(questId, prog)[prog.Step]
		if not prog or not step then
			continue
		end
		local function hits(s: { [string]: any }): boolean
			if s.Type == "Event" then
				return s.Event == name and matchesPayload(s.Match, payload)
			elseif s.Type == "Talk" then
				-- Con diálogo, cuenta al TERMINAR la conversación de la misión (no vale saludar de pasada)
				-- La conversación de una misión solo cuenta para esa misión (dos misiones pueden pedir hablar con la misma persona)
				if s.Dialogue then
					return name == "TalkDone" and payload.Npc == s.Npc and (payload.Quest == nil or payload.Quest == questId)
				end
				return name == "Talk" and payload.Npc == s.Npc
			elseif s.Type == "Use" then
				return name == "PropUsed" and payload.Prop == s.Prop
			end
			return false
		end
		if step.Type == "Group" then
			local sub = prog.Sub or {}
			prog.Sub = sub
			local changed = false
			for i, child in step.Steps do
				local key = tostring(i)
				if not sub[key] and hits(child) then
					sub[key] = true
					changed = true
					applyEffects(player, data, child.Effects, questId)
				end
			end
			if groupDone(step, sub, contextFor(player, data)) then
				advance(player, data, questId)
			elseif changed then
				updateScene(player, data, questId)
				publish(player)
			end
		elseif hits(step) then
			prog.Count += 1
			if prog.Count >= (step.Count or 1) then
				advance(player, data, questId)
			else
				publish(player)
			end
		end
	end

	-- ¿Este evento abre una secundaria?
	for questId, quest in Quests do
		local trigger = quest.Offer
		if quest.Kind == "Side" and trigger and trigger.Event == name and matchesPayload(trigger.Match, payload) then
			if canOffer(player, data, questId) then
				offer(player, questId)
				break
			end
		end
	end
end

---------------------------------------------------------------------
-- Comprobaciones periódicas: llegar a lugares, esperas, hora del día, zonas nuevas
---------------------------------------------------------------------

local function checkReach(player: Player, data: Data, questId: string, prog: Progress, step: { [string]: any }, child: number?): boolean
	local rt = runtime[player]
	local key = spotKey(questId, prog, child)
	local spot = rt.Spots[key]
	if not spot or not spot.Instance:IsDescendantOf(workspace) then
		spot = LocationService.resolve(player, stepPlace(step, storyOf(data)) or "")
		rt.Spots[key] = spot
		if spot then
			publish(player)
		end
	end
	if spot and LocationService.isAt(player, spot) then
		-- Hours = { From, To }: solo cuenta si llegas a esa hora (la luz del monte sale de madrugada)
		if step.Hours and not Conditions.check({ Hours = step.Hours }, contextFor(player, data)) then
			return false
		end
		storyOf(data).Discovered[stepPlace(step, storyOf(data)) or "?"] = true
		return true
	end
	return false
end

local interactProp -- se define más abajo

-- Prisas, tiempo límite y planes B para que ningún paso se quede atascado. true = el paso cambió.
local function stepTimers(player: Player, data: Data, questId: string, prog: Progress, step: { [string]: any }): boolean
	local rt = runtime[player]
	local since = os.clock() - (rt.StepStart[questId] or os.clock())
	if busy(player) or player:GetAttribute("Dead") then
		return false
	end
	-- "¡Vas a llegar tarde!": alguien te mete prisa (una vez, o cada Every segundos)
	local nudge = step.Nudge
	if nudge and since > nudge.After then
		local last = rt.NudgedAt[questId]
		if not last or (nudge.Every and os.clock() - last > nudge.Every) then
			rt.NudgedAt[questId] = os.clock()
			DialogueService.bark(player, nudge.S, nudge.T)
		end
	end
	-- Si no haces nada, la historia sigue por otro camino ("no ayudaste a Mateo")
	local touched = prog.Sub ~= nil and next(prog.Sub) ~= nil
	if step.Timeout and since > step.Timeout.After and not (step.Timeout.OnlyIfUntouched and touched) then
		applyEffects(player, data, step.Timeout, questId)
		notify("StepTimeout", player, questId, { Step = prog.Step, Type = step.Type })
		if storyOf(data).Active[questId] == prog then
			prog.Step += 1
			enterStep(player, data, questId)
		end
		return true
	end
	-- Escenas y minijuegos que no pudieron empezar (había otra conversación): se reintentan
	if (step.Type == "Scene" or step.Type == "MiniGame") and since > 2 then
		startInteractive(player, data, questId)
		return false
	end
	-- Escena de cine que esperaba (ibas conduciendo, o no seguías la misión): en cuanto se pueda
	if step.Type == "Cinematic" and rt.CineHeld and rt.CineHeld[questId] == prog.Step then
		local ok, why = canAutoStart(player, data, questId, step)
		if ok then
			playCinematicStep(player, questId, step, prog.Step)
		else
			holdNotice(player, questId, step, prog.Step, why or "Untracked")
		end
		return false
	end
	-- La ventana de una decisión puede perderse (otra ventana encima, un toque rechazado porque había
	-- una conversación): mientras no se elija, se vuelve a mandar
	if step.Type == "Choice" and (not worldChoice(step) or rt.Fallback[questId]) and os.clock() - (rt.ChoiceSentAt[questId] or 0) > 15 then
		autoChoice(player, data, questId, step)
	end
	if rt.Fallback[questId] then
		return false
	end
	-- Planes B cuando el mapa no tiene el sitio del actor o del objeto
	-- (la conversación o el objeto del plan B salen solos: conduciendo o sin seguir la misión, esperan)
	local planB = (step.Type == "Talk" and step.Dialogue and since > 15 and not SceneService.actorOf(player, step.Npc))
		or (step.Type == "Use" and since > 20 and not SceneService.hasProp(player, questId, step.Prop))
	local planOk, planWhy = true, nil
	if planB then
		planOk, planWhy = canAutoStart(player, data, questId, step)
		if not planOk then
			holdNotice(player, questId, step, prog.Step, planWhy or "Untracked")
			return false
		end
	end
	if step.Type == "Talk" and planB then
		rt.Fallback[questId] = true
		playDialogue(player, data, questId, step.Dialogue, function()
			StoryEvents.emit(player, "TalkDone", { Npc = step.Npc, Quest = questId })
		end, "Talk:" .. tostring(step.Npc))
	elseif step.Type == "Use" and planB then
		rt.Fallback[questId] = true
		interactProp(player, data, questId, step.Prop)
	elseif step.Type == "Choice" and worldChoice(step) and since > 20 then
		local present = false
		for _, option in step.Options do
			present = present or (option.Npc and SceneService.actorOf(player, option.Npc) ~= nil) or (option.Prop and SceneService.hasProp(player, questId, option.Prop))
		end
		if not present then
			rt.Fallback[questId] = true
			autoChoice(player, data, questId, step)
		end
	elseif step.Type == "Group" and since > 25 then
		-- Lo que no está en el mapa se da por hecho
		local sub = prog.Sub or {}
		prog.Sub = sub
		local changed = false
		for i, child in step.Steps do
			local key = tostring(i)
			local missing = (child.Type == "Use" and not SceneService.hasProp(player, questId, child.Prop))
				or (child.Type == "Talk" and not SceneService.actorOf(player, child.Npc))
			local available = not child.If or Conditions.check(child.If, contextFor(player, data))
			if not sub[key] and missing and available then
				sub[key] = true
				changed = true
			end
		end
		rt.Fallback[questId] = true
		if changed and groupDone(step, sub, contextFor(player, data)) then
			advance(player, data, questId)
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Vigilante de atascos: busca pasos que ya no pueden avanzar (falta un actor, un objeto o el sitio
-- en el mapa, el enemigo no aparece, la historia se quedó "ocupada", la decisión se perdió…) y los
-- arregla: vuelve a montar la escena, reenvía la decisión o da el paso por hecho. Lo normal
-- (el jugador aún no ha ido, está leyendo) no se toca. Todo queda en el registro [WATCHDOG].
---------------------------------------------------------------------

LifeStoryService.Watchdog = {
	Every = 2, -- cada cuánto mira cada misión (s)
	BusyStuck = 6, -- "ocupada" sin conversación ni minijuego: se suelta
	Respawn = 6, -- falta un actor u objeto que la escena debería tener: se vuelve a montar
	MaxRespawns = 3,
	ChoiceResend = 45, -- decisión (ventana) sin respuesta: se vuelve a mandar
	MissingPlace = 30, -- el sitio no existe en el mapa (ni su plan B): el paso se da por hecho
	MissingEnemy = 30, -- el enemigo no aparece: cuenta como vencido
	Optional = 180, -- paso Optional = true sin avances: se da por hecho
}

local function recover(player: Player, questId: string, what: string, fmt: string, ...)
	Log.warn("WATCHDOG", "%s · %s: " .. fmt, player.Name, questId, ...)
	notify("Recover", player, questId, { What = what })
end

-- El sitio del paso no está en el mapa y el vigilante lo da por hecho (M-03): antes la historia
-- seguía en silencio y el jugador no sabía por qué. Ahora se le dice, como parte de la historia
LifeStoryService.MissingPlaceText = "Al final no hace falta ir a {place}. La historia sigue."
local function missingPlaceNotice(player: Player, questId: string, placeId: string?)
	local place = placeId and Locations.Places[placeId]
	local name = if place and place.NameKey then Strings.get(place.NameKey) else "ese sitio"
	local text = Strings.get(LifeStoryService.MissingPlaceText, { place = name })
	notifyPlayer(player, "Info", text)
	Log.warn("MISSION", "%s · %s: falta el lugar '%s' en el mapa; paso saltado con aviso", player.Name, questId, tostring(placeId))
	notify("PlaceSkipped", player, questId, { Place = placeId, Text = text })
end

-- ¿Qué personajes y objetos necesita el paso para poder cumplirse?
local function neededBy(step: { [string]: any }, prog: Progress): ({ string }, { string })
	local npcs, props = {}, {}
	local function add(s: { [string]: any }, key: string?)
		if key and prog.Sub and prog.Sub[key] then
			return
		end
		if s.Type == "Talk" or s.Type == "Chase" then
			table.insert(npcs, s.Npc)
		elseif s.Type == "Use" then
			table.insert(props, s.Prop)
		end
	end
	if step.Type == "Group" then
		for i, child in step.Steps or {} do
			add(child, tostring(i))
		end
	elseif step.Type == "Choice" then
		for _, option in step.Options or {} do
			if option.Npc then
				table.insert(npcs, option.Npc)
			end
			if option.Prop then
				table.insert(props, option.Prop)
			end
		end
	elseif step.Type == "Fight" then
		for _, enemy in step.Enemies or {} do
			if not (prog.Sub and prog.Sub[enemy.Npc]) then
				table.insert(npcs, enemy.Npc)
			end
		end
	else
		add(step)
	end
	return npcs, props
end

local function watchdog(player: Player, data: Data, questId: string, prog: Progress, step: { [string]: any }): boolean
	local rt = runtime[player]
	local W = LifeStoryService.Watchdog
	local now = os.clock()
	rt.Watch = rt.Watch or {}
	local subCount = 0
	for _ in prog.Sub or {} do
		subCount += 1
	end
	local key = ("%d:%d:%d"):format(prog.Step, prog.Count or 0, subCount)
	local watch = rt.Watch[questId]
	if not watch or watch.Key ~= key then
		watch = { Key = key, Since = now, Checked = 0, Respawns = 0, Missing = {} }
		rt.Watch[questId] = watch
	end
	if now - watch.Checked < W.Every then
		return false
	end
	watch.Checked = now
	local stalled = now - watch.Since

	-- 1) La historia se quedó "ocupada" sin nada en marcha: nadie podría hablar ni usar nada
	if rt.Busy and not DialogueService.isBusy(player) and not MiniGameService.isRunning(player)
		and now - (rt.BusySince or now) > W.BusyStuck then
		rt.Busy = false
		recover(player, questId, "Busy", "la historia estaba ocupada sin conversación ni minijuego: liberada")
	end
	-- (durante una escena de cámara tampoco: la decisión no se reenvía encima de la escena)
	local busy = rt.Busy or DialogueService.isBusy(player) or MiniGameService.isRunning(player) or ClassService.isRunning(player) or inScene(player)
	if busy then
		return false
	end

	-- 2) Falta alguien u algo que la escena debería tener: se vuelve a montar (actores a su sitio)
	local npcs, props = neededBy(step, prog)
	if #npcs > 0 or #props > 0 then
		local actors, sceneProps = sceneFor(player, data, questId)
		local missing = {}
		for _, npc in npcs do
			for _, spec in actors do
				if spec.Npc == npc and not SceneService.actorOf(player, npc) then
					table.insert(missing, npc)
					break
				end
			end
		end
		for _, id in props do
			if table.find(sceneProps, id) and not SceneService.hasProp(player, questId, id) then
				table.insert(missing, id)
			end
		end
		for _, id in missing do
			watch.Missing[id] = watch.Missing[id] or now
		end
		if #missing > 0 and stalled > W.Respawn * (watch.Respawns + 1) and watch.Respawns < W.MaxRespawns then
			watch.Respawns += 1
			SceneService.respawn(player, questId)
			updateScene(player, data, questId)
			recover(player, questId, "Respawn", "faltan en la escena (%s): se vuelve a montar (intento %d)", table.concat(missing, ", "), watch.Respawns)
		end
		-- Combate: un enemigo que no aparece nunca cuenta como vencido
		if step.Type == "Fight" then
			for _, enemy in step.Enemies or {} do
				local since = watch.Missing[enemy.Npc]
				if since and now - since > W.MissingEnemy and not SceneService.actorOf(player, enemy.Npc)
					and not (prog.Sub and prog.Sub[enemy.Npc]) then
					prog.Sub = prog.Sub or {}
					prog.Sub[enemy.Npc] = true
					prog.Count += 1
					recover(player, questId, "Enemy", "%s no aparece: cuenta como vencido", enemy.Npc)
					if prog.Count >= #(step.Enemies or {}) then
						advance(player, data, questId)
						return true
					end
				end
			end
		end
	end

	-- 3) El sitio al que hay que ir no existe en el mapa (ni su plan B): el paso se da por hecho
	local function placeMissing(s: { [string]: any }): boolean
		local placeId = stepPlace(s, storyOf(data))
		if not placeId then
			return false
		end
		return LocationService.resolve(player, placeId) == nil
	end
	if (step.Type == "Reach" or (step.Type == "Escape" and step.Place)) and stalled > W.MissingPlace and not step.Hours and placeMissing(step) then
		recover(player, questId, "Place", "el sitio '%s' no está en el mapa: paso dado por hecho", tostring(step.Place))
		missingPlaceNotice(player, questId, stepPlace(step, storyOf(data)))
		advance(player, data, questId)
		return true
	elseif step.Type == "Group" and stalled > W.MissingPlace then
		local changed = false
		for i, child in step.Steps or {} do
			local k = tostring(i)
			if child.Type == "Reach" and not (prog.Sub and prog.Sub[k]) and not child.Hours and placeMissing(child) then
				prog.Sub = prog.Sub or {}
				prog.Sub[k] = true
				changed = true
				recover(player, questId, "Place", "el sitio '%s' no está en el mapa: tarea dada por hecha", tostring(child.Place))
				missingPlaceNotice(player, questId, stepPlace(child, storyOf(data)))
			end
		end
		if changed and groupDone(step, prog.Sub or {}, contextFor(player, data)) then
			advance(player, data, questId)
			return true
		end
	end

	-- 4) La ventana de la decisión se perdió (otra ventana la tapó, se reinició la interfaz…)
	if step.Type == "Choice" and not worldChoice(step) and stalled > W.ChoiceResend * ((watch.Resent or 0) + 1) then
		watch.Resent = (watch.Resent or 0) + 1
		if watch.Resent <= 3 then
			autoChoice(player, data, questId, step)
			Log.info("WATCHDOG", "%s · %s: decisión sin respuesta, se vuelve a mostrar", player.Name, questId)
		end
	end

	-- 5) Paso opcional que no avanza: no bloquea la misión
	if step.Optional and stalled > W.Optional then
		recover(player, questId, "Optional", "paso opcional %d sin avances: se da por hecho", prog.Step)
		advance(player, data, questId)
		return true
	end
	return false
end

-- Segundos reales que tiene que haber estado abierto el cole para contar como novillos (si el día de
-- cole empezó justo antes de cerrar, no cuenta)
local NOVILLOS_SECONDS = 150

local function tickPlayer(player: Player, data: Data)
	local story = storyOf(data)
	if story.Loans then
		returnLoans(player, data)
	end
	checkLocalClock(player, data)
	local ids = {}
	for id in story.Active do
		table.insert(ids, id)
	end
	-- Durante el prólogo solo avanza el sueño (lo demás que estuviera a medias espera tal cual)
	if story.Active[PROLOGUE] then
		ids = { PROLOGUE }
		-- Si se ha caído del sueño o ha reaparecido lejos (reinicio del personaje), vuelve a la isla
		local start = LocationService.resolve(player, "PrologoInicio")
		local me = LocationService.positionOf(player)
		if start and me and (start.Position - me).Magnitude > 400 and not player:GetAttribute("Dead") then
			SceneService.teleport(player, "PrologoInicio")
		end
	end
	for _, questId in ids do
		local prog: Progress? = story.Active[questId]
		local step = prog and stepsOf(questId, prog)[prog.Step]
		if not prog or not step then
			continue
		end
		local closed = closedWindow(player, data, questId, prog)
		if closed then
			-- El sitio al que toca ir está cerrado: se sigue cuando abra (y el reloj de "llegas tarde"
			-- no corre mientras tanto)
			local rt = runtime[player]
			-- Novillos: tenías un día de cole por delante, no llegaste ni a la puerta y el cole ya ha
			-- cerrado. Se entera tu familia (ConductService) y queda la marca. Solo una vez por día.
			if rt and Quests[questId].DayPlan and Schedules.isSchool(closed) and prog.Step == 1 and not prog.Novillos then
				local since = os.clock() - (rt.StepStart[questId] or os.clock())
				if GameClock.now().ClockTime >= closed.To and since >= NOVILLOS_SECONDS then
					prog.Novillos = true
					applyEffects(player, data, { Flags = { "HizoNovillos" }, Conduct = "Novillos" }, questId)
				end
			end
			if rt then
				rt.StepStart[questId] = os.clock()
			end
			continue
		end
		if watchdog(player, data, questId, prog, step) then
			continue -- el vigilante ha arreglado un atasco (el paso cambió)
		end
		if stepTimers(player, data, questId, prog, step) then
			continue -- el paso cambió (se acabó el tiempo, plan B…)
		end
		if step.Type == "Reach" then
			if checkReach(player, data, questId, prog, step) then
				advance(player, data, questId)
			end
		elseif step.Type == "Chase" then
			-- Persecución: alcanzar al personaje que huye (si no está en la escena, se da por alcanzado)
			local model = SceneService.actorOf(player, step.Npc)
			local me = LocationService.positionOf(player)
			local rt = runtime[player]
			local since = os.clock() - (rt.StepStart[questId] or os.clock())
			if model and me then
				local offset = model:GetPivot().Position - me
				if Vector3.new(offset.X, 0, offset.Z).Magnitude <= (step.Catch or 7) then
					advance(player, data, questId)
				end
			elseif since > 10 then
				advance(player, data, questId)
			end
		elseif step.Type == "Escape" or step.Type == "Fight" then
			-- Te persiguen: si te atrapan, una consecuencia corta y segura (SceneService.catch): en una
			-- huida vuelves al punto de partida (a empezar); en un combate te deja a unos pasos, en el
			-- suelo, y quien te atrapó descansa unos segundos (el Respawn de un combate suele ser un
			-- modelo, el silo o un edificio: antes te metía DENTRO y te quedabas atascado bajo tierra)
			local rt = runtime[player]
			local busy = rt.Busy or DialogueService.isBusy(player)
			if step.Type == "Fight" then
				ensureWeapon(player, data, questId, prog, step)
			end
			local fallen = player:GetAttribute("Fallen") ~= nil
			if not busy and not fallen and (not rt.CaughtAt or os.clock() - rt.CaughtAt > SafeGround.CatchCooldown) then
				local by = SceneService.caught(player, questId, step.Catch or 3.5)
				if by then
					rt.CaughtAt = os.clock()
					prog.Caught = (prog.Caught or 0) + 1
					DialogueService.bark(player, by, step.CaughtLine or "¡Te tengo!")
					-- En un combate, el que te atrapa te quita vida (su daño: shared/EnemyStats); sin vida,
					-- caes en combate y el paso vuelve a empezar (fightFell)
					local hurt, fell = 0, false
					if step.Type == "Fight" then
						for _, enemy in step.Enemies or {} do
							if enemy.Npc == by then
								hurt = EnemyStats.damageToPlayer(enemy)
							end
						end
						if hurt > 0 then
							local okHurt, down = pcall(DamageService.hurtPlayer, player, hurt)
							fell = okHurt and down == true
						end
					end
					if not fell then -- (si has caído, ya lo dice fightFell)
						notifyPlayer(player, "Info", if step.Type == "Escape" then "¡Te ha pillado! Vuelves a empezar la huida."
							elseif hurt > 0 then ("¡Te ha pillado! −%d ❤️ Aléjate un poco y vuelve a intentarlo."):format(hurt)
							else "¡Te ha pillado! Aléjate un poco y vuelve a intentarlo.")
					end
					SceneService.catch(player, questId, by, if step.Type == "Escape" then step.Respawn else nil)
					if step.Type == "Escape" then
						rt.StepStart[questId] = os.clock()
					end
					StoryEvents.emit(player, "Caught", { Quest = questId, By = by })
				end
			end
			if step.Type == "Escape" then
				local since = os.clock() - (rt.StepStart[questId] or os.clock())
				local reached = step.Place ~= nil and checkReach(player, data, questId, prog, step)
				if reached or (step.Seconds and since >= step.Seconds) then
					advance(player, data, questId)
				end
			end
		elseif step.Type == "Wait" then
			-- Se acaba a la hora de juego que toca… o, pase lo que pase con el reloj, a los MaxSeconds reales
			local rt = runtime[player]
			local since = os.clock() - (rt.StepStart[questId] or os.clock())
			if (prog.WaitUntil and GameClock.now().TotalMinutes >= prog.WaitUntil) or (step.MaxSeconds and since >= step.MaxSeconds) then
				advance(player, data, questId)
			end
		elseif step.Type == "Group" then
			local sub = prog.Sub or {}
			prog.Sub = sub
			local changed = false
			for i, child in step.Steps do
				local key = tostring(i)
				if not sub[key] and child.Type == "Reach" and checkReach(player, data, questId, prog, child, i) then
					sub[key] = true
					changed = true
					applyEffects(player, data, child.Effects, questId)
				end
			end
			if groupDone(step, sub, contextFor(player, data)) then
				advance(player, data, questId)
			elseif changed then
				publish(player)
			end
		elseif step.Type == "Class" then
			-- Clase: al llegar al aula empieza sola; si el aula no existe en el mapa, empieza igual a los 8 s
			local rt = runtime[player]
			local key = spotKey(questId, prog)
			-- (conduciendo o en el autobús no empieza: la clase espera a que te bajes)
			if not busy(player) and not held(player) and not RideState.inVehicle(player) then
				local arrived = checkReach(player, data, questId, prog, step)
				if not arrived and not rt.Spots[key] then
					rt.ClassWaitSince[key] = rt.ClassWaitSince[key] or os.clock()
					arrived = os.clock() - rt.ClassWaitSince[key] > 8
				end
				if arrived then
					local subjectId = Subjects.resolve(step.Subject, degreeOf(story))
					local index = prog.Step
					rt.ClassFor = key
					local extra = nil
					if step.Bonus and Conditions.check(step.Bonus.If, contextFor(player, data)) then
						extra = step.Bonus.Seconds -- quien estudió tiene más tiempo por pregunta
					end
					local started = ClassService.start(player, { Subject = subjectId, Mode = step.Mode or "Clase", ExtraSeconds = extra }, function(result)
						rt.ClassFor = nil
						if result.Aborted then
							return -- (cortada: murió, detenido… no cuenta y se repetirá)
						end
						local current = DataService.get(player)
						local now = current and storyOf(current).Active[questId]
						if now and now.Step == index then
							-- (la nota que miran las misiones es la del último examen, no la de cualquier clase)
							if (step.Mode or "Clase") == "Examen" then
								storyOf(current).LastGrade = result.Grade
							end
							advance(player, current, questId)
						end
					end)
					if not started then
						rt.ClassFor = nil
						advance(player, data, questId) -- nunca bloquear la historia
					end
				end
			end
		elseif step.Place then
			-- Paso que se completa con un evento, pero con lugar: solo se busca para la línea guía
			checkReach(player, data, questId, prog, step)
		end
	end
end

local lastZone: { [Player]: string } = setmetatable({}, { __mode = "k" }) :: any -- último barrio en el que se le vio
local function discoverZone(player: Player, data: Data)
	if data.Life.Stage == "Bebe" then
		return -- el bebé todavía no ha salido de casa
	end
	local position = LocationService.positionOf(player)
	if not position then
		return
	end
	local zone = LocationService.zoneAt(position)
	local key = "Zone:" .. zone
	local story = storyOf(data)
	local first = not story.Discovered[key]
	if first then
		story.Discovered[key] = true
		send(player, "Discover", { Zone = zone })
		LifeStoryService.logEvent(player, "STORY.DISCOVER.ZONE", { zone = zone }, "Place")
	end
	-- Aviso al entrar en otro barrio (lo usan las misiones del pase de temporada: «visita 3 barrios»)
	if lastZone[player] ~= zone then
		lastZone[player] = zone
		if require(game:GetService("ReplicatedStorage").Shared.BattlePass.Config).Enabled then
			StoryEvents.emit(player, "ZoneEntered", { Zone = zone, First = first })
		end
	end
end

-- El tiempo jugado en la etapa hace crecer al personaje: un cumpleaños cada cierto tiempo
-- (de 6 a 12 años en el colegio, de 13 a 17 en el instituto, de 18 a 22 en la universidad…)
function growUp(player: Player, data: Data, seconds: number)
	local life = data.Life
	life.StageSeconds = (life.StageSeconds or 0) + seconds
	data.Story.Clock = (data.Story.Clock or 0) + seconds -- reloj de la historia (consecuencias diferidas)
	local ages = CFG.AgeRange[life.Stage]
	local hours = CFG.StageHours[life.Stage]
	if not ages or not hours or hours <= 0 then
		return
	end
	local years = ages[2] - ages[1] + 1
	local age = math.min(ages[2], ages[1] + math.floor(life.StageSeconds / (hours * 3600 / years)))
	if age > (life.AgeYears or 0) then
		life.AgeYears = age
		player:SetAttribute("AgeYears", age)
		moment(player, "MOMENT.CUMPLEANOS", { edad = age }, "Momento")
	end
end

-- Cada parte del repaso va aparte: si una falla (un dato roto), las demás y el refresh siguen
-- (antes un error en una cortaba el resto y la historia no avanzaba nunca más)
local function guarded(what: string, player: Player, fn: (...any) -> ...any, ...: any)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn(("[LifeStory] %s falló para %s: %s"):format(what, player.Name, tostring(err)))
	end
end
LifeStoryService._guarded = guarded

local function slowTick(player: Player, data: Data)
	local rt = runtime[player]
	-- (la tarjeta puede esperar hasta 20 s a que acabe una conversación y luego se ve 28 s: se le da
	-- tiempo de sobra, o un "sí" al final de la tarjeta no hacía nada)
	if rt.PendingOffer and os.clock() - rt.OfferedAt > 55 then
		rt.PendingOffer = nil -- nadie contestó: se volverá a ofrecer más adelante
	end
	local story = storyOf(data)
	story.LastSeen = os.time()
	if story.Active[PROLOGUE] then
		-- En el sueño no se ofrece nada ni vuelven consecuencias. Con tope: si se atasca, se despierta
		rt.PrologueSince = rt.PrologueSince or os.clock()
		if os.clock() - rt.PrologueSince > (CFG.PrologueMaxSeconds or 480) then
			guarded("endPrologue", player, endPrologue, player, data, "Timeout")
		end
		return
	end
	if rt.RecapPending and not busy(player) and not held(player) then
		guarded("sendRecap", player, sendRecap, player, data)
	end
	guarded("discoverZone", player, discoverZone, player, data)
	guarded("checkPlaceOffers", player, checkPlaceOffers, player, data)
	guarded("updateCanonMarks", player, updateCanonMarks, player, data)
	guarded("processLater", player, processLater, player, data)
	guarded("pendingItems", player, function()
		-- Regalos de misiones que no cabían en la mochila: en cuanto hay hueco, llegan
		-- (lo que quepa, aunque no sea todo: antes, si no cabía entero, no llegaba nunca)
		local pending = storyOf(data).PendingItems
		if type(pending) == "table" then
			for id, count in pending do
				local item = if type(id) == "string" then require(ReplicatedStorage.Shared.Items).get(id) else nil
				local n = if item and type(count) == "number" and count == count then math.min(math.floor(count), item.Stack) else 0
				if n <= 0 then
					pending[id] = nil -- (roto o ya no existe ese objeto)
					continue
				end
				local give = math.min(n, roomFor(player, id))
				if give > 0 and InventoryService.add(player, id, give) then
					if give >= n then
						pending[id] = nil
					else
						pending[id] = n - give
					end
				end
			end
			if next(pending) == nil then
				storyOf(data).PendingItems = nil
			end
		elseif pending ~= nil then
			storyOf(data).PendingItems = nil
		end
	end)
	guarded("refresh", player, refresh, player)
end

---------------------------------------------------------------------
-- Decidir y actuar: elegir una opción, hablar con un actor, usar un objeto
---------------------------------------------------------------------

-- Elige una opción de un paso Choice (desde la ventana, hablando con alguien o tocando un objeto)
local function chooseOption(player: Player, data: Data, questId: string, optionId: string): boolean
	local story = storyOf(data)
	local prog = story.Active[questId]
	local step = prog and Quests[questId] and stepsOf(questId, prog)[prog.Step]
	if not step or step.Type ~= "Choice" then
		return false
	end
	for _, option in step.Options do
		if option.Id == optionId and (not option.If or Conditions.check(option.If, contextFor(player, data))) then
			local index = prog.Step
			local function commit()
				local now = story.Active[questId]
				if not now or now.Step ~= index then
					return
				end
				if option.Stay then
					-- Opción que no cierra la decisión (acusar a quien no era): efectos y vuelta a pensar
					applyEffects(player, data, option.Effects, questId)
					if not worldChoice(step) then
						sendChoice(player, questId, step)
					end
					return
				end
				story.Choices[step.Key] = { V = optionId, D = lifeDay(player) }
				for _, flag in option.Flags or {} do
					story.Flags[flag] = true
				end
				applyEffects(player, data, option.Effects, questId)
				LifeStoryService.logEvent(player, option.Text or option.TextKey, nil, "Choice")
				advance(player, data, questId)
			end
			if option.Dialogue then
				return playDialogue(player, data, questId, option.Dialogue, commit, "Option:" .. tostring(option.Id))
			end
			commit()
			return true
		end
	end
	return false
end

-- Usar o examinar un objeto de la escena
function interactProp(player: Player, data: Data, questId: string, propId: string)
	local quest = Quests[questId]
	local story = storyOf(data)
	local prog = story.Active[questId]
	local def = quest and quest.Props and quest.Props[propId]
	if not prog or not def then
		return
	end
	-- Solo los objetos que están ahora en la escena (uno de un paso que aún no toca no se coge)
	local _, sceneProps = sceneFor(player, data, questId)
	if not table.find(sceneProps, propId) then
		return
	end
	local step = stepsOf(questId, prog)[prog.Step]
	-- ¿Tocar este objeto ES elegir? (sentarse en un sitio, coger una mochila…)
	if step and step.Type == "Choice" then
		for _, option in step.Options do
			if option.Prop == propId then
				chooseOption(player, data, questId, option.Id)
				return
			end
		end
	end
	local index = prog.Step
	local function done()
		local now = story.Active[questId]
		if not now then
			return
		end
		applyEffects(player, data, def.Effects, questId)
		if def.Once then
			now.Used = now.Used or {}
			now.Used[propId] = true
			SceneService.removeProp(player, questId, propId)
		end
		if now.Step == index then
			StoryEvents.emit(player, "PropUsed", { Prop = propId, Quest = questId })
		end
	end
	if def.Dialogue then
		playDialogue(player, data, questId, def.Dialogue, done, "Prop:" .. propId)
	else
		done()
	end
end

-- Guardas contra conversaciones que se repiten (un toque de más en el móvil, el mismo toque que
-- cierra una conversación, volver a acercarte a alguien…). Funciones puras: se prueban con Lune.
LifeStoryService.Guard = {
	AfterDialogue = 1.2, -- segundos tras acabar una conversación en los que no se empieza otra
	Repeat = 1.0, -- dos toques seguidos al mismo personaje u objeto cuentan como uno
	Bark = 8, -- una frase suelta del mismo personaje, como mucho cada tantos segundos
}

-- ¿Se atiende este toque? (rt: estado del jugador; key: "Actor:Nico", "Prop:Libro"…)
function LifeStoryService.Guard.allow(rt: { [string]: any }, key: string, now: number): boolean
	local guard = LifeStoryService.Guard
	if rt.DialogueEndedAt and now - rt.DialogueEndedAt < guard.AfterDialogue then
		return false
	end
	rt.LastTouch = rt.LastTouch or {}
	local last = rt.LastTouch[key]
	if last and now - last < guard.Repeat then
		return false
	end
	rt.LastTouch[key] = now
	return true
end

-- ¿Puede decir ya otra frase suelta este personaje?
function LifeStoryService.Guard.bark(rt: { [string]: any }, npc: string, now: number): boolean
	rt.BarkAt = rt.BarkAt or {}
	local last = rt.BarkAt[npc]
	if last and now - last < LifeStoryService.Guard.Bark then
		return false
	end
	rt.BarkAt[npc] = now
	return true
end

-- El jugador ha hablado con un actor o usado un objeto de una escena (lo avisa SceneService)
-- Daño por puntos a un enemigo del combate (rayo, globo de agua, bala, golpe, piedra…). La vida va
-- en prog.Hp (se guarda con la misión) y en los atributos del modelo (su barra de vida). A los 0
-- puntos CAE: se cae al suelo y se desvanece (SceneService.defeat) y cuenta para el paso; cuando
-- caen todos, el paso está hecho. Devuelve (cuenta, daño hecho, vida, vida máxima, caído).
local function setEnemyHealth(player: Player, npc: string, health: number, max: number)
	pcall(function()
		local model = SceneService.actorOf(player, npc)
		if model and (model :: any).SetAttribute then
			model:SetAttribute("EnemyMaxHealth", max)
			model:SetAttribute("EnemyHealth", health)
		end
	end)
end

function hitEnemy(player: Player, data: Data, questId: string, prog: Progress, step: { [string]: any }, enemy: { [string]: any }, kind: string?, amount: number?, info: { [string]: any }?): (boolean, number?, number?, number?, boolean?)
	local how = kind or "Attack"
	local max = EnemyStats.maxHealth(enemy, step)
	local hp = prog.Hp or {}
	prog.Hp = hp
	local before = if type(hp[enemy.Npc]) == "number" then hp[enemy.Npc] else max
	if before <= 0 or (prog.Sub and prog.Sub[enemy.Npc]) then
		return false
	end
	local dealt = EnemyStats.damageFrom(how, amount, info and info.Weapon, EnemyStats.toyHurts(enemy))
	if dealt <= 0 then
		-- (un daño de 0: no quita vida)
		return true, 0, before, max, false
	end
	local after, down = EnemyStats.apply(before, dealt)
	hp[enemy.Npc] = after
	-- Shrink = 0.4: el rayo encogedor lo deja en el 40 % de su tamaño cuando cae
	local shrinkTo = if enemy.Shrink then (enemy.Scale or 1) * (1 - (1 - enemy.Shrink) * EnemyStats.lost(after, max)) else nil
	-- (el rayo desde la mano solo con el botón de la misión o su arma; las balas y los golpes ya se ven)
	SceneService.hit(player, questId, enemy.Npc, step.BeamColor, shrinkTo, { Beam = how == "Attack" or how == "Gadget" })
	setEnemyHealth(player, enemy.Npc, after, max)
	if not down then
		if enemy.Hurt and before >= max then
			DialogueService.bark(player, enemy.Npc, enemy.Hurt)
		end
		return true, dealt, after, max, false
	end
	local sub = prog.Sub or {}
	prog.Sub = sub
	sub[enemy.Npc] = true
	prog.Count += 1
	pcall(function()
		local model = SceneService.actorOf(player, enemy.Npc)
		if model and (model :: any).SetAttribute then
			model:SetAttribute("EnemyDown", true)
		end
	end)
	SceneService.defeat(player, questId, enemy.Npc, if enemy.Shrink then "Shrink" else "Fall")
	if enemy.Bye then
		DialogueService.bark(player, enemy.Npc, enemy.Bye)
	end
	StoryEvents.emit(player, "EnemyDefeated", { Quest = questId, Npc = enemy.Npc })
	if prog.Count >= #(step.Enemies or {}) then
		advance(player, data, questId)
	else
		publish(player)
	end
	return true, dealt, after, max, true
end

---------------------------------------------------------------------
-- Caer en combate (misión): te quedas sin vida -> en el suelo unos segundos (pantalla «HAS CAÍDO
-- EN COMBATE») y el combate vuelve a empezar desde el principio del paso, sin perder la misión:
-- los enemigos vuelven con la vida entera y tú con la tuya, en el sitio de salida del combate.
---------------------------------------------------------------------
function LifeStoryService.retryFight(player: Player, data: Data, questId: string)
	local story = storyOf(data)
	local prog = story.Active[questId]
	local step = prog and stepsOf(questId, prog)[prog.Step]
	if not prog or not step or step.Type ~= "Fight" then
		return
	end
	-- Detenido, en un juicio o muerto mientras estabas en el suelo: no se reintenta (no te saca de la
	-- cárcel ni del hospital con el arma de la misión)
	if held(player) then
		return
	end
	prog.Sub = {}
	prog.Hp = {}
	prog.Count = 0
	prog.Retries = (prog.Retries or 0) + 1
	local rt = runtime[player]
	if rt then
		rt.StepStart[questId] = os.clock()
		rt.CaughtAt = os.clock()
	end
	for _, enemy in step.Enemies or {} do
		local max = EnemyStats.maxHealth(enemy, step)
		setEnemyHealth(player, enemy.Npc, max, max)
	end
	updateScene(player, data, questId) -- (los que habían caído vuelven)
	if step.Respawn or step.Place then
		LifeStoryService.teleportStep(player, step.Respawn or step.Place)
	end
	ensureWeapon(player, data, questId, prog, step)
	notifyPlayer(player, "Info", "🔁 ¡Otra vez! El combate vuelve a empezar.")
	notify("FightRetry", player, questId, { Step = prog.Step, Type = "Fight" })
	StoryEvents.emit(player, "FightRetry", { Quest = questId })
	publish(player)
end

-- (DamageService) Has caído en combate: si es el de una misión, se reintenta el paso al levantarte
function LifeStoryService.fightFell(player: Player)
	local data = DataService.get(player)
	local questId, prog = nil, nil
	if data then
		questId, prog = fightOf(storyOf(data), nil)
	end
	local stepIndex = prog and prog.Step
	notifyPlayer(player, "Error", if questId then "💫 Has caído en combate. Vuelves a intentarlo enseguida…" else "💫 Has caído en combate.")
	local fellWith = player.Character
	task.delay(EnemyStats.PlayerFallSeconds, function()
		if not player.Parent then
			return
		end
		-- Mientras estabas en el suelo te han detenido (K.O. con un agente cerca), estás en un juicio,
		-- has muerto o ya tienes otro personaje: solo te levantas, sin reintento (el reintento te
		-- llevaría al combate con el arma de la misión, fuera de la cárcel o del hospital)
		if heldAway(player) or player.Character ~= fellWith then
			DamageService.getUp(player, false)
			return
		end
		DamageService.getUp(player, true)
		local current = DataService.get(player)
		local now = current and questId and storyOf(current).Active[questId]
		if current and questId and now and now.Step == stepIndex then
			LifeStoryService.retryFight(player, current, questId)
		end
	end)
end

-- La hora que pide el texto de una transición (o nil si no dice ninguna)
function LifeStoryService.clockFor(text: string?): number?
	if type(text) ~= "string" then
		return nil
	end
	local t = string.lower(text)
	if string.find(t, "noche", 1, true) then
		return 21.5
	elseif string.find(t, "tarde", 1, true) then
		return 17
	elseif string.find(t, "mañana", 1, true) or string.find(t, "al día siguiente", 1, true) or string.find(t, "el día de", 1, true) or string.find(t, "el día del", 1, true) then
		return 8.5
	end
	return nil
end

-- Lleva al jugador al sitio de un paso y, un momento después, comprueba que ha llegado (si seguía
-- sentado, en un vehículo o el mapa no estaba cargado, se vuelve a intentar)
function LifeStoryService.teleportStep(player: Player, where: any)
	if not held(player) then
		SceneService.teleport(player, where)
	end
	local placeId = if type(where) == "table" then where.Place else where
	task.spawn(function()
		for _ = 1, 3 do
			task.wait(1.2)
			if not player.Parent or held(player) then
				return
			end
			local spot = LocationService.resolve(player, placeId)
			if not spot or LocationService.isAt(player, spot) then
				return
			end
			SceneService.teleport(player, where)
		end
	end)
end

function LifeStoryService.interact(player: Player, kind: string, questId: string, id: string)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt or busy(player) or player:GetAttribute("Dead") or player:GetAttribute("Fallen") then
		return
	end
	local story = storyOf(data)
	local prog = story.Active[questId]
	local quest = Quests[questId]
	if not prog or not quest then
		return
	end
	local step = stepsOf(questId, prog)[prog.Step]
	-- 0) Combate: el botón del enemigo es atacar (va antes del filtro de toques dobles: aquí pulsar
	-- seguido ES lo que hay que hacer, y ya tiene su propio ritmo máximo)
	if step and step.Type == "Fight" then
		for _, enemy in step.Enemies or {} do
			if enemy.Npc == id then
				if not (prog.Sub and prog.Sub[id]) then
					strike(player, data, questId, prog, step, enemy)
				end
				return
			end
		end
	end
	if not LifeStoryService.Guard.allow(rt, kind .. ":" .. id, os.clock()) then
		return
	end
	-- Desde un vehículo no se habla ni se usa nada de la historia (se abriría la conversación con la
	-- cámara encima mientras conduces): primero bájate
	if not (step and step.InVehicle) and RideState.inVehicle(player) then
		pcall(function()
			local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Notify")
			if remote then
				(remote :: RemoteEvent):FireClient(player, "Info", "Bájate del vehículo para hablar.")
			end
		end)
		return
	end
	-- Lo has tocado tú: esta misión es la que estás haciendo ahora (lo que siga puede empezar solo)
	engage(player, questId)
	if kind == "Prop" then
		interactProp(player, data, questId, id)
		return
	end
	-- 0b) Una escena que esperaba (no sigues esta misión, o ibas conduciendo): hablar con alguien
	-- de la escena la empieza
	if step and (step.Type == "Scene" or step.Type == "MiniGame") then
		local inScene = false
		for _, list in { quest.Actors or {}, step.Actors or {} } do
			for _, spec in list do
				if spec.Npc == id then
					inScene = true
				end
			end
		end
		if inScene then
			startInteractive(player, data, questId)
			return
		end
	end
	-- 1) Hablar con este personaje ES elegir (unirte a un grupo del recreo…)
	if step and step.Type == "Choice" then
		for _, option in step.Options do
			if option.Npc == id then
				chooseOption(player, data, questId, option.Id)
				return
			end
		end
	end
	-- 2) La misión pide hablar con él: su conversación de la misión
	local talk: { [string]: any }? = nil
	if step and step.Type == "Talk" and step.Npc == id then
		talk = step
	elseif step and step.Type == "Group" then
		for i, child in step.Steps do
			if child.Type == "Talk" and child.Npc == id and not (prog.Sub and prog.Sub[tostring(i)]) then
				talk = child
				break
			end
		end
	end
	if talk and talk.Dialogue then
		prog.Chatted = prog.Chatted or {}
		if prog.Chatted[id] then
			-- Esta conversación ya se tuvo en este paso: no se repite (solo se vuelve a avisar)
			StoryEvents.emit(player, "TalkDone", { Npc = id, Quest = questId })
			return
		end
		local index = prog.Step
		playDialogue(player, data, questId, talk.Dialogue, function()
			local now = story.Active[questId]
			if now and now.Step == index then
				now.Chatted = now.Chatted or {}
				now.Chatted[id] = true
			end
			StoryEvents.emit(player, "TalkDone", { Npc = id, Quest = questId })
			StoryEvents.emit(player, "Talk", { Npc = id })
		end, "Talk:" .. id)
		return
	end
	-- 3) Si no, lo que ese actor tenga que decir en esta escena (o saluda)
	local spec: { [string]: any }? = nil
	for _, list in { quest.Actors or {}, (step and step.Actors) or {} } do
		for _, candidate in list do
			if candidate.Npc == id then
				spec = candidate
			end
		end
	end
	prog.Chatted = prog.Chatted or {}
	if spec and spec.Talk and not prog.Chatted[id] then
		-- Su charla de esta escena, una vez por paso; después, como mucho una frase suelta de vez en cuando
		local index = prog.Step
		playDialogue(player, data, questId, spec.Talk, function()
			local now = story.Active[questId]
			if now and now.Step == index then
				now.Chatted = now.Chatted or {}
				now.Chatted[id] = true
			end
			StoryEvents.emit(player, "Talk", { Npc = id })
		end, "Chat:" .. id)
	else
		if LifeStoryService.Guard.bark(rt, id, os.clock()) then
			DialogueService.bark(player, id, spec and spec.Bark or "¡Hola!")
		end
		StoryEvents.emit(player, "Talk", { Npc = id })
	end
end

-- (Depuración del dueño: /debug resetmission) Vuelve a empezar una misión activa desde el paso 1.
-- Sin id: la que se está siguiendo. Corta la conversación o el minijuego y rehace la escena.
function LifeStoryService.resetQuest(player: Player, questId: string?): (boolean, string)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt then
		return false, "sin datos"
	end
	local story = storyOf(data)
	local id = questId or story.Tracked
	if not id then
		for activeId in story.Active do
			id = activeId
			break
		end
	end
	if not id or not story.Active[id] then
		return false, "no hay esa misión activa"
	end
	DialogueService.cancel(player, "reset")
	MiniGameService.cancel(player)
	rt.Busy = false
	story.Active[id] = nil
	if rt.Watch then
		rt.Watch[id] = nil
	end
	SceneService.clear(player, id)
	Log.warn("DEBUG", "%s reinicia la misión %s", player.Name, id)
	startQuest(player, data, id)
	return true, id
end

-- (Modo pruebas: saltar de etapa) Deja las misiones en marcha que ya no pegan con la etapa nueva:
-- las principales de un capítulo que no es de esa etapa (los recados del cole, el día de cole…) y
-- las que piden otra edad. Si no, una principal de niño seguía activa y el capítulo de adulto no
-- empezaba nunca. No cuentan como hechas (si vuelves a ser niño, se pueden jugar). Corta la
-- conversación o el minijuego en marcha. Devuelve las misiones quitadas.
function LifeStoryService.dropOutgrown(player: Player, stage: string): { string }
	local data = DataService.get(player)
	local rt = runtime[player]
	local dropped = {}
	if not data or not rt or not Stages.isValid(stage) then
		return dropped
	end
	local story = storyOf(data)
	-- Principales que caben en la etapa nueva: las de los capítulos que le tocan (y su día normal)
	local fits: { [string]: boolean } = {}
	for _, id in chapterOrder do
		local chapter = Chapters[id]
		if chapterFits(chapter, stage, story) then
			for _, questId in chapter.Main do
				fits[questId] = true
			end
			if chapter.Loop then
				fits[chapter.Loop] = true
			end
		end
	end
	for id, prog in story.Active do
		local quest = Quests[id]
		local req = quest and quest.Requires
		local wrongAge = type(req) == "table" and type(req.Stage) == "table" and not Stages.inRange(stage, req.Stage.Min, req.Stage.Max)
		local wrongChapter = type(prog) == "table" and prog.Kind == "Main" and not fits[id]
		if id ~= PROLOGUE and (not quest or wrongAge or wrongChapter) then
			table.insert(dropped, id)
		end
	end
	if #dropped == 0 then
		return dropped
	end
	pcall(DialogueService.cancel, player, "etapa")
	pcall(MiniGameService.cancel, player)
	rt.Busy = false
	rt.Waiting = nil
	for _, id in dropped do
		story.Active[id] = nil
		if rt.Watch then
			rt.Watch[id] = nil
		end
		if story.Tracked == id then
			story.Tracked = nil
		end
		pcall(SceneService.clear, player, id)
	end
	Log.warn("DEBUG", "%s cambia a %s: deja %s", player.Name, stage, table.concat(dropped, ", "))
	return dropped
end

-- Estado de la historia de un jugador para depurar (panel del dueño, /debug, pruebas)
function LifeStoryService.debugState(player: Player): { [string]: any }?
	local rt = runtime[player]
	local data = DataService.get(player)
	if not rt or not data then
		return nil
	end
	local story = storyOf(data)
	local active = {}
	for id, prog in story.Active do
		local step = stepsOf(id, prog)[prog.Step]
		local watch = rt.Watch and rt.Watch[id]
		active[id] = {
			Step = prog.Step,
			Steps = #stepsOf(id, prog),
			Type = step and step.Type,
			Text = step and (step.Text or step.TextKey),
			Npc = step and step.Npc,
			Place = step and step.Place,
			Count = prog.Count,
			Kind = prog.Kind,
			StalledFor = if watch then math.floor(os.clock() - watch.Since) else 0,
		}
	end
	return {
		Ready = rt.Ready,
		Busy = rt.Busy,
		InDialogue = DialogueService.isBusy(player),
		Waiting = rt.Waiting,
		Tracked = story.Tracked,
		Chapter = story.Chapter,
		Stage = data.Life.Stage,
		Age = data.Life.AgeYears,
		Active = active,
	}
end

-- Consecuencias diferidas: lo que decidiste hace horas vuelve ahora
function processLater(player: Player, data: Data)
	local story = storyOf(data)
	local rt = runtime[player]
	if not story.Later or #story.Later == 0 or busy(player) or data.Life.Stage == "Bebe" then
		return
	end
	local clock = story.Clock or 0
	for i = #story.Later, 1, -1 do
		local later = story.Later[i]
		if clock >= later.At and (not later.If or Conditions.check(later.If, contextFor(player, data))) then
			table.remove(story.Later, i)
			if later.Flag then
				story.Flags[later.Flag] = true
			end
			if later.Memory then
				LifeStoryService.addMemory(player, later.Memory, later.From)
			end
			local quest = later.Start and Quests[later.Start]
			if quest and not story.Active[later.Start] and not story.Completed[later.Start] then
				-- (las consecuencias de lo que hiciste llegan aunque lleves el máximo de secundarias: son
				-- el resultado de tus actos, no una oferta que puedas rechazar)
				if Conditions.check(quest.Requires, contextFor(player, data)) then
					startQuest(player, data, later.Start)
				else
					-- Aún no se dan las condiciones (otra etapa, otra hora): se vuelve a mirar más tarde (la
					-- marca y el recuerdo ya se dieron: no se repiten)
					table.insert(story.Later, { Start = later.Start, At = clock + 300, If = later.If, From = later.From })
				end
			end
			return -- una cosa cada vez
		end
	end
end

-- Empieza la historia del jugador cuando ya ha aparecido donde lo dejó (PositionService):
-- primero se le devuelve a la escena si está lejos, luego se montan actores y conversaciones.
local function becomeReady(player: Player)
	local rt = runtime[player]
	if not rt or rt.Ready or rt.Starting then
		return
	end
	rt.Starting = true
	local deadline = os.clock() + 10
	while player.Parent and not player:GetAttribute("SpawnReady") and os.clock() < deadline do
		task.wait(0.2)
	end
	if runtime[player] ~= rt then
		return -- se fue mientras tanto
	end
	local data = DataService.get(player)
	if data then
		local ok, err = pcall(returnToScene, player, data)
		if not ok then
			warn("[LifeStory] " .. tostring(err))
		end
	end
	rt.Ready = true
	rt.Starting = false
	if data then
		-- Personaje nuevo: primero el prólogo (el sueño). Quien vuelve: «Anteriormente en tu vida…»
		-- (antes de retomar las escenas, para que el resumen salga antes que cualquier conversación)
		local dreaming = false
		if LifeStoryService.needsPrologue(data) then
			local ok, started = pcall(startPrologue, player, data, false)
			dreaming = ok and started == true
			if not ok then
				Log.error("MISSION", "prólogo: %s", tostring(started))
				pcall(endPrologue, player, data, "Error")
			end
		end
		if not dreaming then
			queueRecap(player, data)
		end
	end
	resumeAll(player)
	refresh(player)
	publish(player, true)
end

---------------------------------------------------------------------
-- Lo que pide el cliente (siempre validado)
---------------------------------------------------------------------

-- Peticiones del cliente: como mucho una de cada tipo cada REMOTE_GAP segundos
local REMOTE_GAP = 0.25
local IMPORTANT_REMOTES = { Choose = true, Offer = true, Prologue = true, Track = true, Sync = true }

local function onRemote(player: Player, kind: any, questId: any, value: any)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt or type(kind) ~= "string" then
		return
	end
	local story = storyOf(data)
	if kind == "CinematicDone" or kind == "CinematicSeen" then
		if type(questId) == "string" and #questId < 80 then
			if kind == "CinematicDone" then
				CinematicService.clientDone(player, questId)
			else
				LifeStoryService.sceneBeat(player)
				CinematicService.clientSeen(player, questId)
			end
		end
		return
	end
	if kind == "Attack" then
		-- El botón de atacar en un combate de misión (tiene su propio ritmo: MissionCombat.HitGap)
		LifeStoryService.missionAttack(player)
		return
	end
	-- Límite por tipo de petición (antes uno para todas: «Sí» a una oferta justo después de elegir una
	-- respuesta se perdía en silencio). Las respuestas importantes no se tiran: la última que llega
	-- demasiado seguida se atiende al acabar la espera.
	local now = os.clock()
	rt.LastRemoteBy = rt.LastRemoteBy or {}
	local lastBy = rt.LastRemoteBy :: { [string]: number }
	local gap = now - (lastBy[kind] or -math.huge)
	if gap < REMOTE_GAP then
		local key = kind .. "|" .. tostring(questId)
		local queued = 0
		for _ in rt.QueuedRemote or {} do
			queued += 1
		end
		if IMPORTANT_REMOTES[kind] and #key < 120 and queued < 8 then
			rt.QueuedRemote = rt.QueuedRemote or {}
			local queue = rt.QueuedRemote :: { [string]: { any } }
			local waiting = queue[key] ~= nil
			queue[key] = { questId, value }
			if not waiting then
				task.delay(REMOTE_GAP - gap + 0.02, function()
					local entry = queue[key]
					queue[key] = nil
					if entry and runtime[player] == rt then
						onRemote(player, kind, entry[1], entry[2])
					end
				end)
			end
		end
		return
	end
	lastBy[kind] = now
	rt.LastRemote = now

	if kind == "Sync" then
		if rt.Ready then
			publish(player, true)
		else
			task.spawn(becomeReady, player)
		end
	elseif kind == "Choose" and type(questId) == "string" and type(value) == "string" then
		if (busy(player) or not chooseOption(player, data, questId, value)) and story.Active[questId] then
			rt.ChoiceSentAt[questId] = 0 -- rechazada (había una conversación…): la ventana vuelve a salir luego
		end
	elseif kind == "Offer" and type(questId) == "string" and rt.PendingOffer == questId then
		rt.PendingOffer = nil
		if value == true and canOffer(player, data, questId) then
			rt.JustOffered = questId -- ya vio quién se lo pide y por qué: sin tarjeta de comienzo
			startQuest(player, data, questId)
			-- La que acabas de aceptar es la que juegas ahora (panel, GPS y quién te acompaña); al
			-- terminarla vuelve la principal. Se puede cambiar tocando otra en el panel.
			if story.Active[questId] and not story.Active[PROLOGUE] then
				story.Tracked = questId
				publish(player)
			end
		elseif value ~= true then
			story.Declined[questId] = os.time()
		end
		-- (si dijiste que sí pero justo empezaba una conversación o una escena, no cuenta como "no":
		-- se te volverá a ofrecer en un rato)
	elseif kind == "Track" and type(questId) == "string" and story.Active[questId] and not story.Active[PROLOGUE] then
		story.Tracked = questId
		publish(player)
	elseif kind == "Prologue" then
		-- El prólogo: "Skip" (botón Saltar), "MapOpened" (ha abierto el mapa) o "Replay" (desde «Mi historia»)
		if questId == "Skip" and story.Active[PROLOGUE] then
			endPrologue(player, data, "Skipped")
		elseif questId == "MapOpened" and story.Active[PROLOGUE] then
			StoryEvents.emit(player, "MapOpened", {})
		elseif questId == "Replay" and not story.Active[PROLOGUE] and not busy(player) and not held(player) then
			startPrologue(player, data, true)
		end
	elseif kind == "Journal" then
		-- «Mi historia»: capítulos, personajes que conoces y recuerdos
		send(player, "Journal", StoryContext.journal(data, { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") }))
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------

-- Campos nuevos de la historia para personajes guardados antes de que existieran
function story_defaults(data: Data)
	local story = storyOf(data)
	story.Traits = story.Traits or {}
	story.Memories = story.Memories or {}
	story.Later = story.Later or {}
	story.Clock = story.Clock or 0
	story.Counters = story.Counters or {}
end

-- Al entrar (o volver) al juego: se rehacen las escenas y lo que estuviera a medias
function resumeAll(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	for questId in storyOf(data).Active do
		local rt = runtime[player]
		if rt then
			rt.StepStart[questId] = os.clock()
		end
		updateScene(player, data, questId)
		startInteractive(player, data, questId)
	end
end

local function onLoaded(player: Player, data: Data)
	if not Stages.isValid(data.Life.Stage) then
		-- Personaje nuevo: nace bebé. Quien ya había jugado antes de la historia de vida sigue adulto.
		local veteran = data.Stats and data.Stats.PlaySeconds and data.Stats.PlaySeconds > 0
		data.Life.Stage = if veteran then CFG.VeteranStage else CFG.NewCharacterStage
		LifeStoryService.logEvent(player, "STAGE." .. data.Life.Stage, nil, "Stage")
	end
	-- Edad: si no tiene (o es menor que la de su etapa, como los veteranos que cargaban con 0 años),
	-- la primera edad de su etapa
	local ages = CFG.AgeRange[data.Life.Stage]
	if ages and (tonumber(data.Life.AgeYears) or 0) < ages[1] then
		data.Life.AgeYears = ages[1]
	end
	player:SetAttribute("LifeStage", data.Life.Stage)
	player:SetAttribute("AgeYears", data.Life.AgeYears)
	runtime[player] = {
		Spots = {},
		OfferedAt = 0,
		LastRemote = 0,
		Ready = false,
		ClassWaitSince = {},
		StepStart = {},
		NudgedAt = {},
		Fallback = {},
		Busy = false,
		ChoiceSentAt = {},
	}
	story_defaults(data)

	local story = storyOf(data)
	-- El último día normal (LoopDay) se cuenta en días de TU vida (CalendarService, se guarda): vale
	-- en cualquier servidor. Los de partidas viejas eran días del servidor (empezaba de cero en cada
	-- uno): esos no sirven aquí (podrían coincidir con el número de hoy y dejarte sin día de cole)
	if not (story.LoopLife and player:GetAttribute("LifeDay") ~= nil) then
		story.LoopDay = nil
		story.LoopLife = nil
	end
	-- Cuánto tiempo ha estado fuera (para «Anteriormente en tu vida…»)
	runtime[player].AwaySeconds = os.time() - (tonumber(story.LastSeen) or 0)
	-- Se fue en mitad del prólogo: cuenta como visto y vuelve a su vida (se puede repetir desde «Mi historia»)
	if story.Active[PROLOGUE] then
		story.Active[PROLOGUE] = nil
		if story.Tracked == PROLOGUE then
			story.Tracked = nil
		end
		if not story.PrologueDone then
			story.PrologueDone = os.time()
			story.PrologueResult = "Left"
		end
	end
	-- Quitar misiones que ya no existen (por si se borran de los datos en una actualización)
	-- y reiniciar esperas (el reloj del juego empieza de cero en cada servidor)
	for id, prog in story.Active do
		local quest = Quests[id]
		-- Nada de una captura a medias sobrevive al guardado (no se vuelve a quedar atascado al entrar)
		SafeGround.cleanProgress(prog)
		if quest then
			migrateSteps(id, prog)
		end
		if not quest then
			story.Active[id] = nil
		elseif stepsOf(id, prog)[prog.Step] and stepsOf(id, prog)[prog.Step].Type == "Wait" then
			prog.WaitUntil = waitTarget(stepsOf(id, prog)[prog.Step])
		elseif stepsOf(id, prog)[prog.Step] and stepsOf(id, prog)[prog.Step].Type == "Cinematic" then
			-- Se fue en mitad de una escena: al volver, la historia sigue desde el paso siguiente
			local index = prog.Step
			task.delay(4, function()
				local now = story.Active[id]
				if player.Parent and now and now.Step == index then
					advance(player, data, id)
				end
			end)
		elseif stepsOf(id, prog)[prog.Step] and stepsOf(id, prog)[prog.Step].Type == "Choice" and not worldChoice(stepsOf(id, prog)[prog.Step]) then
			-- (las decisiones "en el mundo" —sentarte en un sitio, ir con un grupo— se vuelven a hacer
			-- andando, sin ventana; y se compara con el paso de ahora, no consigo mismo)
			local index = prog.Step
			task.delay(4, function()
				local now = story.Active[id]
				local step = now and now.Step == index and stepsOf(id, now)[index]
				if player.Parent and step and step.Type == "Choice" then
					autoChoice(player, data, id, step)
				end
			end)
		end
	end
	-- Normalmente el cliente avisa con "Sync" en cuanto escucha; por si acaso, empezar igual a los 10 s
	task.delay(10, function()
		becomeReady(player)
	end)
end

function LifeStoryService.init()
	local report = Validate.report()
	for _, problem in report.Errors do
		Log.error("VALIDATE", "%s", problem)
	end
	for _, problem in report.Warnings do
		Log.info("VALIDATE", "%s", problem)
	end
	if next(report.BadQuests) then
		local bad = {}
		for id in report.BadQuests do
			table.insert(bad, id)
		end
		table.sort(bad)
		Log.error("VALIDATE", "misiones que no se activarán: %s", table.concat(bad, ", "))
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("LifeStory") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "LifeStory"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(onRemote)
	-- El latido de las escenas (SceneClient → Remotes.Scene "Beat"; el remoto lo crea CinematicService)
	task.spawn(function()
		pcall(function()
			local scene = remotes:WaitForChild("Scene", 15)
			if scene and scene:IsA("RemoteEvent") then
				(scene :: RemoteEvent).OnServerEvent:Connect(function(player: Player, kind: any)
					if kind == "Beat" then
						LifeStoryService.sceneBeat(player)
					end
				end)
			end
		end)
	end)

	StoryEvents.connect(onStoryEvent)
	DataService.onLoaded(onLoaded)
	SceneService.onInteract = LifeStoryService.interact
	-- El arma prestada de un combate, usada desde la barra, dispara al enemigo de la misión
	pcall(function()
		require(script.Parent.GadgetService).missionUse = LifeStoryService.useWeapon
	end)
	-- Disparos (también la pistola de agua) y golpes a un enemigo de misión cuentan en el combate
	pcall(function()
		local CombatService = require(script.Parent.CombatService) :: any
		CombatService.missionAim = LifeStoryService.aimAssist
	end)
	-- El daño por puntos (DamageService): la vida de los enemigos la lleva la misión; si caes en un
	-- combate de misión, se reintenta el paso
	pcall(function()
		DamageService.enemyHit = LifeStoryService.enemyHit
		DamageService.playerFell = LifeStoryService.fightFell
	end)
	-- Frases sueltas: el bocadillo sale encima del actor de tu escena
	DialogueService.setActorFinder(function(player, npc)
		return SceneService.actorOf(player, npc)
	end)
	Players.PlayerRemoving:Connect(function(player)
		runtime[player] = nil
	end)

	task.spawn(function()
		local sinceSlow = 0
		while true do
			task.wait(CFG.TickSeconds)
			sinceSlow += CFG.TickSeconds
			local slow = sinceSlow >= CFG.RefreshSeconds
			if slow then
				sinceSlow = 0
			end
			for player, rt in runtime do
				local data = DataService.get(player)
				-- Cada jugador en su propio hilo: si algo de uno espera (el mapa, una escena), los demás
				-- siguen; y si su tick anterior no ha acabado, este se salta (no se solapan).
				if data and rt.Ready and not rt.Ticking then
					rt.Ticking = true
					task.spawn(function()
						local ok, err = pcall(function()
							growUp(player, data, CFG.TickSeconds)
							tickPlayer(player, data)
							if slow then
								slowTick(player, data)
							end
						end)
						rt.Ticking = false
						if not ok then
							Log.error("MISSION", "error en la historia de %s: %s", player.Name, tostring(err))
						end
					end)
				end
			end
		end
	end)
end

return LifeStoryService
