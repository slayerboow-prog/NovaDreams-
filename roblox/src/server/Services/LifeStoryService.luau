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
local LifeStory = ReplicatedStorage.Shared.LifeStory
local Chapters = require(LifeStory.Chapters)
local Quests = require(LifeStory.Quests)
local Locations = require(LifeStory.Locations)
local Conditions = require(LifeStory.Conditions)
local Stages = require(LifeStory.Stages)
local Validate = require(LifeStory.Validate)
local Subjects = require(LifeStory.Subjects)
local DayPlans = require(LifeStory.DayPlans)
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

local LifeStoryService = {}

local CFG = Config.LifeStory
local Remote: RemoteEvent

type Data = { [string]: any }
type Progress = {
	Step: number,
	Count: number,
	Sub: { [string]: boolean }?,
	WaitUntil: number?,
	Started: number,
	Kind: string,
}

-- Estado que no se guarda (se reconstruye al entrar)
type Runtime = {
	Spots: { [string]: LocationService.Spot }, -- lugar elegido para cada paso "Reach" en curso
	PendingOffer: string?,
	OfferedAt: number,
	Waiting: { QuestId: string, Reason: string }?,
	LastPublished: string?,
	LastRemote: number,
	Ready: boolean,
	ClassFor: string?, -- paso de clase que se está jugando ahora
	ClassWaitSince: { [string]: number }, -- desde cuándo se espera un aula que no aparece en el mapa -- el cliente ya escucha (si no, los avisos de capítulo se perderían)
	StepStart: { [string]: number }, -- misión -> cuándo empezó su paso actual (os.clock)
	NudgedAt: { [string]: number }, -- misión -> último "¡date prisa!"
	Fallback: { [string]: boolean }, -- misión -> ya se lanzó el plan B de este paso
	Busy: boolean, -- una conversación, un minijuego o una clase de la historia en marcha
}
local runtime: { [Player]: Runtime } = {}
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
		D = GameClock.now().Day,
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
	memory[npcId].Facts[fact] = GameClock.now().Day
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
	data.Life.Stage = stage
	data.Life.StageSeconds = 0
	local ages = Config.LifeStory.AgeRange[stage]
	if ages then
		data.Life.AgeYears = ages[1]
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
	story.Memories[key] = { D = GameClock.now().Day, T = os.time(), Q = questId, S = data.Life.Stage }
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
		InventoryService.add(player, id, count)
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
		story.Choices[key] = { V = value, D = GameClock.now().Day }
	end
	if effects.Gesture then
		SceneService.gesture(player, effects.Gesture.Npc, effects.Gesture.Anim or "Wave")
	end
	if effects.Say then
		DialogueService.bark(player, effects.Say.S, effects.Say.T)
	end
	if effects.Teleport then
		SceneService.teleport(player, effects.Teleport) -- un atajo, una escena que empieza en otro sitio
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
	end
	return args
end

local function trackedQuest(story: Data): string?
	if story.Tracked and story.Active[story.Tracked] then
		return story.Tracked
	end
	for id, prog in story.Active do
		if prog.Kind == "Main" then
			return id
		end
	end
	return next(story.Active)
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
	local trackedId = trackedQuest(story)
	if trackedId then
		local quest = Quests[trackedId]
		local prog: Progress = story.Active[trackedId]
		local step = stepsOf(trackedId, prog)[prog.Step]
		local tracked: { [string]: any } = { QuestId = trackedId, Kind = quest.Kind, TitleKey = titleOf(trackedId, prog) }
		if step then
			tracked.TextKey = step.Text or step.TextKey
			tracked.Args = placeArgs(step, prog, story)
			if step.Type == "Group" then
				tracked.Children = {}
				tracked.Need = step.Need
				for i, child in step.Steps do
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
			elseif step.Type == "Talk" or step.Type == "Use" or step.Type == "Choice" or step.Type == "Chase" then
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
		state.Tracked = tracked
	elseif rt.Waiting then
		local quest = Quests[rt.Waiting.QuestId]
		local req = quest.Requires or {}
		state.Waiting = {
			TitleKey = quest.TitleKey or quest.Title,
			Reason = rt.Waiting.Reason,
			From = req.Hours and req.Hours.From,
			To = req.Hours and req.Hours.To,
		}
	end
	for id in story.Active do
		if id ~= trackedId then
			table.insert(state.Others, { QuestId = id, TitleKey = titleOf(id, story.Active[id]) })
		end
	end
	table.sort(state.Others, function(a, b)
		return a.QuestId < b.QuestId
	end)

	player:SetAttribute("StoryTarget", target)
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

local function sendChoice(player: Player, questId: string, step: { [string]: any })
	local options = {}
	for _, option in step.Options do
		table.insert(options, { Id = option.Id, TextKey = option.Text or option.TextKey })
	end
	send(player, "Choice", { QuestId = questId, PromptKey = step.Prompt or step.PromptKey, Options = options })
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

-- Contexto de un diálogo: condiciones con lo que recuerda el personaje, efectos, cámara
local function dialogueContext(player: Player, data: Data, questId: string): DialogueService.Context
	local story = storyOf(data)
	return {
		check = function(condition)
			return (Conditions.check(condition, contextFor(player, data)))
		end,
		apply = function(effects)
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

-- Juega una conversación de la misión; onDone cuando termine. Si ya hay otra, se reintenta luego.
local function playDialogue(player: Player, data: Data, questId: string, name: any, onDone: () -> ()): boolean
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
	local started = DialogueService.play(player, dialogue, dialogueContext(player, data, questId), function()
		rt.Busy = false
		onDone()
	end)
	if not started then
		rt.Busy = false
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
	if not quest or not (quest.Props or quest.Actors or quest.Dialogues) then
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

local startInteractive -- se define más abajo
local story_defaults -- se define más abajo
local processLater -- se define más abajo
local resumeAll -- se define más abajo
local groupDone -- se define más abajo

-- Prepara el paso actual de una misión. Los pasos "instantáneos" (Moment, Transition, If que no
-- se cumple) se resuelven aquí mismo y se pasa al siguiente.
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
		prog.WaitUntil = nil
		if rt then
			rt.StepStart[questId] = os.clock()
			rt.NudgedAt[questId] = nil
			rt.Fallback[questId] = nil
		end
		if step.If and not Conditions.check(step.If, contextFor(player, data)) then
			prog.Step += 1
			continue
		end
		if step.Teleport then
			SceneService.teleport(player, step.Teleport)
		end
		if step.Type == "Moment" then
			moment(player, step.Text or step.TextKey or quest.MomentKey)
			applyEffects(player, data, step.Effects, questId)
			prog.Step += 1
			continue
		elseif step.Type == "Transition" then
			if step.Cinematic then
				CinematicService.play(player, step.Cinematic)
			else
				send(player, "Transition", { TextKey = step.Text or step.TextKey, Seconds = step.Seconds or 4 })
			end
			if step.SetStage then
				LifeStoryService.setStage(player, step.SetStage)
			end
			applyEffects(player, data, step.Effects, questId)
			prog.Step += 1
			continue
		elseif step.Type == "Wait" then
			prog.WaitUntil = GameClock.now().TotalMinutes + step.GameMinutes
		elseif step.Type == "Group" then
			prog.Sub = {}
		elseif step.Type == "Choice" then
			if not worldChoice(step) then
				sendChoice(player, questId, step)
			end
		elseif step.Type == "Cinematic" then
			-- La escena se ve en el cliente; la historia sigue cuando termina
			local duration = CinematicService.play(player, step.Id)
			local index = prog.Step
			task.delay(duration, function()
				local current = DataService.get(player)
				local now = current and storyOf(current).Active[questId]
				if now and now.Step == index then
					advance(player, current, questId)
				end
			end)
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
	if not step or not rt or not rt.Ready then
		return
	end
	local index = prog.Step
	local function stillHere(): boolean
		local current = DataService.get(player)
		local now = current and storyOf(current).Active[questId]
		return now ~= nil and now.Step == index
	end
	if step.Type == "Scene" then
		playDialogue(player, data, questId, step.Dialogue, function()
			if stillHere() then
				advance(player, data, questId)
			end
		end)
	elseif step.Type == "MiniGame" and not rt.Busy and not MiniGameService.isRunning(player) then
		rt.Busy = true
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
		end
		if storyOf(data).Active[questId] == prog then
			prog.Step += 1
			enterStep(player, data, questId)
		end
	end
end

local function startQuest(player: Player, data: Data, questId: string)
	local story = storyOf(data)
	if story.Active[questId] then
		return
	end
	local quest = Quests[questId]
	local prog: any = { Step = 1, Count = 0, Started = os.time(), Kind = quest.Kind }
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
			local sum, count = 0, 0
			for _, entry in data.Education.Subjects do
				sum += entry.Avg
				count += 1
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
	SceneService.clear(player, questId)
	giveRewards(player, data, quest.Rewards)
	if quest.Memory then
		LifeStoryService.addMemory(player, quest.Memory, questId)
	end
	if quest.MomentKey then
		local sting = if quest.MomentSting == false then nil else (quest.MomentSting or "Momento")
		local args = if quest.DayPlan then { n = story.Counters[questId] or 1 } else nil
		moment(player, quest.MomentKey, args, sting :: string?)
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

	local function enterChapter(id: string)
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
				enterChapter(nextChapter.Id)
			else
				story.Chapter = nil
			end
			continue
		end
		local ok, reason = Conditions.check(Quests[pending].Requires, contextFor(player, data))
		if ok then
			startQuest(player, data, pending)
			return -- startQuest ya publica
		elseif reason == "StageProgress" and chapter.Loop and Quests[chapter.Loop] then
			-- Aún no toca el siguiente gran momento: se vive un día normal (colegio, instituto, universidad)
			startQuest(player, data, chapter.Loop)
			return
		elseif Conditions.isWaitOnly(reason) then
			rt.Waiting = { QuestId = pending, Reason = reason :: string }
		end
		break
	end
	publish(player)
end

---------------------------------------------------------------------
-- Secundarias: aparecen según dónde estás, qué haces y qué hora es
---------------------------------------------------------------------

local function activeSideCount(story: Data): number
	local count = 0
	for _, prog in story.Active do
		if prog.Kind == "Side" then
			count += 1
		end
	end
	return count
end

local function canOffer(player: Player, data: Data, questId: string): boolean
	local story = storyOf(data)
	local quest = Quests[questId]
	local rt = runtime[player]
	if not rt or rt.PendingOffer or story.Active[questId] or activeSideCount(story) >= CFG.MaxActiveSide then
		return false
	end
	local done = story.Completed[questId]
	if done and (not quest.Repeatable or os.time() - done < (quest.Cooldown or 0)) then
		return false
	end
	local declined = story.Declined[questId]
	if declined and os.time() - declined < CFG.DeclineCooldown then
		return false
	end
	return (Conditions.check(quest.Requires, contextFor(player, data)))
end

local function offer(player: Player, questId: string)
	local rt = runtime[player]
	local quest = Quests[questId]
	rt.PendingOffer = questId
	rt.OfferedAt = os.clock()
	send(player, "Offer", { QuestId = questId, TitleKey = quest.TitleKey, TextKey = quest.OfferKey })
end

local function checkPlaceOffers(player: Player, data: Data)
	for questId, quest in Quests do
		if quest.Kind == "Side" and quest.Offer and quest.Offer.Place and canOffer(player, data, questId) then
			local spot = LocationService.resolve(player, quest.Offer.Place)
			if spot and LocationService.isAt(player, spot) then
				offer(player, questId)
				return
			end
		end
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

local function onStoryEvent(player: Player, name: string, payload: { [string]: any })
	local data = DataService.get(player)
	if not data or not runtime[player] then
		return
	end
	local story = storyOf(data)

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
	local busy = rt.Busy or DialogueService.isBusy(player) or MiniGameService.isRunning(player) or ClassService.isRunning(player)
	if busy then
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
	if rt.Fallback[questId] then
		return false
	end
	-- Planes B cuando el mapa no tiene el sitio del actor o del objeto
	if step.Type == "Talk" and step.Dialogue and since > 15 and not SceneService.actorOf(player, step.Npc) then
		rt.Fallback[questId] = true
		playDialogue(player, data, questId, step.Dialogue, function()
			StoryEvents.emit(player, "TalkDone", { Npc = step.Npc, Quest = questId })
		end)
	elseif step.Type == "Use" and since > 20 and not SceneService.hasProp(player, questId, step.Prop) then
		rt.Fallback[questId] = true
		interactProp(player, data, questId, step.Prop)
	elseif step.Type == "Choice" and worldChoice(step) and since > 20 then
		local present = false
		for _, option in step.Options do
			present = present or (option.Npc and SceneService.actorOf(player, option.Npc) ~= nil) or (option.Prop and SceneService.hasProp(player, questId, option.Prop))
		end
		if not present then
			rt.Fallback[questId] = true
			sendChoice(player, questId, step)
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

local function tickPlayer(player: Player, data: Data)
	local story = storyOf(data)
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
		elseif step.Type == "Wait" then
			if prog.WaitUntil and GameClock.now().TotalMinutes >= prog.WaitUntil then
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
			if rt.ClassFor == nil and not ClassService.isRunning(player) then
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
						local current = DataService.get(player)
						local now = current and storyOf(current).Active[questId]
						if now and now.Step == index then
							storyOf(current).LastGrade = result.Grade
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
	if not story.Discovered[key] then
		story.Discovered[key] = true
		send(player, "Discover", { Zone = zone })
		LifeStoryService.logEvent(player, "STORY.DISCOVER.ZONE", { zone = zone }, "Place")
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

local function slowTick(player: Player, data: Data)
	local rt = runtime[player]
	if rt.PendingOffer and os.clock() - rt.OfferedAt > 30 then
		rt.PendingOffer = nil -- nadie contestó: se volverá a ofrecer más adelante
	end
	discoverZone(player, data)
	checkPlaceOffers(player, data)
	processLater(player, data)
	refresh(player)
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
				story.Choices[step.Key] = { V = optionId, D = GameClock.now().Day }
				for _, flag in option.Flags or {} do
					story.Flags[flag] = true
				end
				applyEffects(player, data, option.Effects, questId)
				LifeStoryService.logEvent(player, option.Text or option.TextKey, nil, "Choice")
				advance(player, data, questId)
			end
			if option.Dialogue then
				return playDialogue(player, data, questId, option.Dialogue, commit)
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
		playDialogue(player, data, questId, def.Dialogue, done)
	else
		done()
	end
end

-- El jugador ha hablado con un actor o usado un objeto de una escena (lo avisa SceneService)
function LifeStoryService.interact(player: Player, kind: string, questId: string, id: string)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt or rt.Busy or DialogueService.isBusy(player) or MiniGameService.isRunning(player) then
		return
	end
	local story = storyOf(data)
	local prog = story.Active[questId]
	local quest = Quests[questId]
	if not prog or not quest then
		return
	end
	if kind == "Prop" then
		interactProp(player, data, questId, id)
		return
	end
	local step = stepsOf(questId, prog)[prog.Step]
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
		playDialogue(player, data, questId, talk.Dialogue, function()
			StoryEvents.emit(player, "TalkDone", { Npc = id, Quest = questId })
			StoryEvents.emit(player, "Talk", { Npc = id })
		end)
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
	if spec and spec.Talk then
		playDialogue(player, data, questId, spec.Talk, function()
			StoryEvents.emit(player, "Talk", { Npc = id })
		end)
	else
		DialogueService.bark(player, id, spec and spec.Bark or "¡Hola!")
		StoryEvents.emit(player, "Talk", { Npc = id })
	end
end

-- Consecuencias diferidas: lo que decidiste hace horas vuelve ahora
function processLater(player: Player, data: Data)
	local story = storyOf(data)
	local rt = runtime[player]
	if not story.Later or #story.Later == 0 or rt.Busy or DialogueService.isBusy(player) or data.Life.Stage == "Bebe" then
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
				if Conditions.check(quest.Requires, contextFor(player, data)) then
					startQuest(player, data, later.Start)
				else
					-- Aún no se dan las condiciones (otra etapa, otra hora): se vuelve a mirar más tarde
					later.At = clock + 300
					table.insert(story.Later, later)
				end
			end
			return -- una cosa cada vez
		end
	end
end

---------------------------------------------------------------------
-- Lo que pide el cliente (siempre validado)
---------------------------------------------------------------------

local function onRemote(player: Player, kind: any, questId: any, value: any)
	local data = DataService.get(player)
	local rt = runtime[player]
	if not data or not rt or type(kind) ~= "string" then
		return
	end
	if os.clock() - rt.LastRemote < 0.25 then
		return
	end
	rt.LastRemote = os.clock()
	local story = storyOf(data)

	if kind == "Sync" then
		if not rt.Ready then
			rt.Ready = true
			resumeAll(player)
			refresh(player)
		end
		publish(player, true)
	elseif kind == "Choose" and type(questId) == "string" and type(value) == "string" then
		if not rt.Busy then
			chooseOption(player, data, questId, value)
		end
	elseif kind == "Offer" and type(questId) == "string" and rt.PendingOffer == questId then
		rt.PendingOffer = nil
		if value == true and canOffer(player, data, questId) then
			startQuest(player, data, questId)
		else
			story.Declined[questId] = os.time()
		end
	elseif kind == "Track" and type(questId) == "string" and story.Active[questId] then
		story.Tracked = questId
		publish(player)
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
	}
	story_defaults(data)

	local story = storyOf(data)
	-- Quitar misiones que ya no existen (por si se borran de los datos en una actualización)
	-- y reiniciar esperas (el reloj del juego empieza de cero en cada servidor)
	for id, prog in story.Active do
		local quest = Quests[id]
		if not quest then
			story.Active[id] = nil
		elseif stepsOf(id, prog)[prog.Step] and stepsOf(id, prog)[prog.Step].Type == "Wait" then
			prog.WaitUntil = GameClock.now().TotalMinutes + stepsOf(id, prog)[prog.Step].GameMinutes
		elseif stepsOf(id, prog)[prog.Step] and stepsOf(id, prog)[prog.Step].Type == "Cinematic" then
			-- Se fue en mitad de una escena: al volver, la historia sigue desde el paso siguiente
			local index = prog.Step
			task.delay(4, function()
				local now = story.Active[id]
				if player.Parent and now and now.Step == index then
					advance(player, data, id)
				end
			end)
		elseif stepsOf(id, prog)[prog.Step] and stepsOf(id, prog)[prog.Step].Type == "Choice" then
			task.delay(4, function()
				if player.Parent and story.Active[id] and story.Active[id].Step == prog.Step then
					sendChoice(player, id, stepsOf(id, prog)[prog.Step])
				end
			end)
		end
	end
	-- Normalmente el cliente avisa con "Sync" en cuanto escucha; por si acaso, empezar igual a los 10 s
	task.delay(10, function()
		local rt = runtime[player]
		if rt and not rt.Ready then
			rt.Ready = true
			resumeAll(player)
			refresh(player)
		end
	end)
end

function LifeStoryService.init()
	for _, problem in Validate.run() do
		warn("[LifeStory] " .. problem)
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("LifeStory") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "LifeStory"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(onRemote)

	StoryEvents.connect(onStoryEvent)
	DataService.onLoaded(onLoaded)
	SceneService.onInteract = LifeStoryService.interact
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
			for player in runtime do
				local data = DataService.get(player)
				if data and runtime[player].Ready then
					local ok, err = pcall(function()
						growUp(player, data, CFG.TickSeconds)
						tickPlayer(player, data)
						if slow then
							slowTick(player, data)
						end
					end)
					if not ok then
						warn("[LifeStory] " .. tostring(err))
					end
				end
			end
		end
	end)
end

return LifeStoryService
