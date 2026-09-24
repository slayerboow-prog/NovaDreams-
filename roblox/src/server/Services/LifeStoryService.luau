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
--              NpcMemory, Events (biografía), Tracked }

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
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local LocationService = require(script.Parent.LocationService)
local RoleService = require(script.Parent.RoleService)

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
	Ready: boolean, -- el cliente ya escucha (si no, los avisos de capítulo se perderían)
}
local runtime: { [Player]: Runtime } = {}

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

local function contextFor(player: Player, data: Data): Conditions.Context
	local now = GameClock.now()
	local story = storyOf(data)
	return {
		Stage = data.Life.Stage,
		ClockTime = now.ClockTime,
		Weekday = now.Weekday,
		Completed = story.Completed,
		Flags = story.Flags,
		Choices = story.Choices,
		Discovered = story.Discovered,
		Duties = RoleService.dutiesOf(player),
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

local function moment(player: Player, key: string, args: { [string]: any }?)
	send(player, "Moment", { TextKey = key, Args = args })
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
	player:SetAttribute("LifeStage", stage)
	LifeStoryService.logEvent(player, "STAGE." .. stage, nil, "Stage")
	task.defer(refresh, player)
end

---------------------------------------------------------------------
-- Publicar el estado al cliente (tarjeta "Tu vida" y línea guía)
---------------------------------------------------------------------

local function placeArgs(step: { [string]: any }, prog: Progress?): { [string]: any }
	local args: { [string]: any } = {}
	if step.Place then
		local place = Locations.Places[step.Place]
		args.placeKey = place and place.NameKey
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

local function spotKey(questId: string, prog: Progress, child: number?): string
	return ("%s:%d:%d"):format(questId, prog.Step, child or 0)
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
		Stage = data.Life.Stage,
		Others = {},
	}

	local target: Vector3? = nil
	local trackedId = trackedQuest(story)
	if trackedId then
		local quest = Quests[trackedId]
		local prog: Progress = story.Active[trackedId]
		local step = quest.Steps[prog.Step]
		local tracked: { [string]: any } = { QuestId = trackedId, Kind = quest.Kind, TitleKey = quest.TitleKey }
		if step then
			tracked.TextKey = step.TextKey
			tracked.Args = placeArgs(step, prog)
			if step.Type == "Group" then
				tracked.Children = {}
				for i, child in step.Steps do
					local done = prog.Sub ~= nil and prog.Sub[tostring(i)] == true
					table.insert(tracked.Children, { TextKey = child.TextKey, Args = placeArgs(child), Done = done })
					if not done and child.Type == "Reach" and not target then
						local spot = rt.Spots[spotKey(trackedId, prog, i)]
						target = spot and spot.Position
					end
				end
			elseif step.Type == "Reach" then
				local spot = rt.Spots[spotKey(trackedId, prog)]
				target = spot and spot.Position
			end
		end
		state.Tracked = tracked
	elseif rt.Waiting then
		local quest = Quests[rt.Waiting.QuestId]
		local req = quest.Requires or {}
		state.Waiting = {
			TitleKey = quest.TitleKey,
			Reason = rt.Waiting.Reason,
			From = req.Hours and req.Hours.From,
			To = req.Hours and req.Hours.To,
		}
	end
	for id in story.Active do
		if id ~= trackedId then
			table.insert(state.Others, { QuestId = id, TitleKey = Quests[id].TitleKey })
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

local function sendChoice(player: Player, questId: string, step: { [string]: any })
	local options = {}
	for _, option in step.Options do
		table.insert(options, { Id = option.Id, TextKey = option.TextKey })
	end
	send(player, "Choice", { QuestId = questId, PromptKey = step.PromptKey, Options = options })
end

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
		local step = quest.Steps[prog.Step]
		if not step then
			completeQuest(player, data, questId)
			return
		end
		prog.Count = 0
		prog.Sub = nil
		prog.WaitUntil = nil
		if step.If and not Conditions.check(step.If, contextFor(player, data)) then
			prog.Step += 1
			continue
		end
		if step.Type == "Moment" then
			moment(player, step.TextKey or quest.MomentKey)
			prog.Step += 1
			continue
		elseif step.Type == "Transition" then
			send(player, "Transition", { TextKey = step.TextKey, Seconds = step.Seconds or 4 })
			if step.SetStage then
				LifeStoryService.setStage(player, step.SetStage)
			end
			prog.Step += 1
			continue
		elseif step.Type == "Wait" then
			prog.WaitUntil = GameClock.now().TotalMinutes + step.GameMinutes
		elseif step.Type == "Group" then
			prog.Sub = {}
		elseif step.Type == "Choice" then
			sendChoice(player, questId, step)
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
	publish(player)
end

local function advance(player: Player, data: Data, questId: string)
	local prog = storyOf(data).Active[questId]
	if prog then
		prog.Step += 1
		enterStep(player, data, questId)
	end
end

local function startQuest(player: Player, data: Data, questId: string)
	local story = storyOf(data)
	if story.Active[questId] then
		return
	end
	local quest = Quests[questId]
	story.Active[questId] = { Step = 1, Count = 0, Started = os.time(), Kind = quest.Kind }
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
	if rewards.Money and rewards.Money > 0 then
		DataService.addMoney(player, rewards.Money, true)
	end
	for _, flag in rewards.Flags or {} do
		story.Flags[flag] = true
	end
	for _, entry in rewards.Remember or {} do
		LifeStoryService.remember(player, entry.Npc, entry.Fact)
		LifeStoryService.addAffinity(player, entry.Npc, 1)
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
	giveRewards(player, data, quest.Rewards)
	if quest.MomentKey then
		moment(player, quest.MomentKey)
	end
	refresh(player)
end

---------------------------------------------------------------------
-- Capítulos y misiones principales: qué toca ahora en tu vida
---------------------------------------------------------------------

local function chapterFits(chapter: Chapters.Chapter, stage: string): boolean
	return chapter.Enabled and Stages.inRange(stage, chapter.Stage.Min, chapter.Stage.Max)
end

local function pickChapter(story: Data, stage: string): string?
	for _, id in chapterOrder do
		if not story.Chapters[id] and chapterFits(Chapters[id], stage) then
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
		send(player, "Chapter", { TitleKey = chapter.TitleKey, TextKey = chapter.IntroKey, Phase = "Intro" })
		LifeStoryService.logEvent(player, chapter.TitleKey, nil, "Chapter")
	end

	for _ = 1, #chapterOrder + 1 do -- como mucho, recorrer todos los capítulos una vez
		local chapter = story.Chapter and Chapters[story.Chapter]
		if not chapter or story.Chapters[chapter.Id] or not chapterFits(chapter, stage) then
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
			send(player, "Chapter", { TitleKey = chapter.TitleKey, TextKey = chapter.OutroKey, Phase = "Outro" })
			local nextChapter = chapter.Next and Chapters[chapter.Next]
			if nextChapter and not story.Chapters[nextChapter.Id] and chapterFits(nextChapter, stage) then
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
		local step = prog and Quests[questId].Steps[prog.Step]
		if not prog or not step then
			continue
		end
		local function hits(s: { [string]: any }): boolean
			if s.Type == "Event" then
				return s.Event == name and matchesPayload(s.Match, payload)
			elseif s.Type == "Talk" then
				return name == "Talk" and payload.Npc == s.Npc
			end
			return false
		end
		if step.Type == "Group" then
			local sub = prog.Sub or {}
			prog.Sub = sub
			local all = true
			for i, child in step.Steps do
				local key = tostring(i)
				if not sub[key] and hits(child) then
					sub[key] = true
				end
				all = all and sub[key] == true
			end
			if all then
				advance(player, data, questId)
			else
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
		spot = LocationService.resolve(player, step.Place)
		rt.Spots[key] = spot
		if spot then
			publish(player)
		end
	end
	if spot and LocationService.isAt(player, spot) then
		storyOf(data).Discovered[step.Place] = true
		return true
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
		local step = prog and Quests[questId].Steps[prog.Step]
		if not prog or not step then
			continue
		end
		if step.Type == "Reach" then
			if checkReach(player, data, questId, prog, step) then
				advance(player, data, questId)
			end
		elseif step.Type == "Wait" then
			if prog.WaitUntil and GameClock.now().TotalMinutes >= prog.WaitUntil then
				advance(player, data, questId)
			end
		elseif step.Type == "Group" then
			local sub = prog.Sub or {}
			prog.Sub = sub
			local changed, all = false, true
			for i, child in step.Steps do
				local key = tostring(i)
				if not sub[key] and child.Type == "Reach" and checkReach(player, data, questId, prog, child, i) then
					sub[key] = true
					changed = true
				end
				all = all and sub[key] == true
			end
			if all then
				advance(player, data, questId)
			elseif changed then
				publish(player)
			end
		end
	end
end

local function discoverZone(player: Player, data: Data)
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

local function slowTick(player: Player, data: Data)
	local rt = runtime[player]
	if rt.PendingOffer and os.clock() - rt.OfferedAt > 30 then
		rt.PendingOffer = nil -- nadie contestó: se volverá a ofrecer más adelante
	end
	discoverZone(player, data)
	checkPlaceOffers(player, data)
	refresh(player)
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
			refresh(player)
		end
		publish(player, true)
	elseif kind == "Choose" and type(questId) == "string" and type(value) == "string" then
		local prog = story.Active[questId]
		local step = prog and Quests[questId] and Quests[questId].Steps[prog.Step]
		if not step or step.Type ~= "Choice" then
			return
		end
		for _, option in step.Options do
			if option.Id == value then
				story.Choices[step.Key] = { V = value, D = GameClock.now().Day }
				LifeStoryService.logEvent(player, option.TextKey, nil, "Choice")
				advance(player, data, questId)
				return
			end
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

local function onLoaded(player: Player, data: Data)
	if not Stages.isValid(data.Life.Stage) then
		data.Life.Stage = CFG.DefaultStage
	end
	player:SetAttribute("LifeStage", data.Life.Stage)
	runtime[player] = { Spots = {}, OfferedAt = 0, LastRemote = 0, Ready = false }

	local story = storyOf(data)
	-- Quitar misiones que ya no existen (por si se borran de los datos en una actualización)
	-- y reiniciar esperas (el reloj del juego empieza de cero en cada servidor)
	for id, prog in story.Active do
		local quest = Quests[id]
		if not quest then
			story.Active[id] = nil
		elseif quest.Steps[prog.Step] and quest.Steps[prog.Step].Type == "Wait" then
			prog.WaitUntil = GameClock.now().TotalMinutes + quest.Steps[prog.Step].GameMinutes
		elseif quest.Steps[prog.Step] and quest.Steps[prog.Step].Type == "Choice" then
			task.delay(4, function()
				if player.Parent and story.Active[id] and story.Active[id].Step == prog.Step then
					sendChoice(player, id, quest.Steps[prog.Step])
				end
			end)
		end
	end
	-- Normalmente el cliente avisa con "Sync" en cuanto escucha; por si acaso, empezar igual a los 10 s
	task.delay(10, function()
		local rt = runtime[player]
		if rt and not rt.Ready then
			rt.Ready = true
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
