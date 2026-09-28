-- Prueba de partida completa (QA automático) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-playthrough.luau            (todo: unos minutos)
--   lune run scripts/test-playthrough.luau rapido     (solo validador y una vida)
--
-- 1. El validador de misiones: sin errores, y detecta misiones rotas a propósito (que no se activan).
-- 2. Cada evento que esperan las misiones lo emite de verdad algún sistema (EventCatalog).
-- 3. Vidas enteras, de bebé a adulto, con varias formas de contestar (cada opción de cada decisión
--    en alguna de las vidas): cada misión principal termina, ningún paso se salta ni se repite, cada
--    conversación sale una vez, los personajes están cuando hay que hablar con ellos y las
--    recompensas llegan.
-- 4. "Romperlo": cada misión principal se juega aparte, a la vez que las demás (varios jugadores en
--    el mismo servidor), y a mitad se sale del juego en plena conversación (se guarda y se vuelve a
--    entrar), se muere en plena conversación, se toca dos veces seguidas a quien hay que hablar, se
--    toca a otro personaje durante una escena y se aleja del sitio al que hay que ir. Siempre tiene
--    que poder terminarse.
-- Si algo se queda atascado, el fallo se arregla en el juego, no en esta prueba.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local H = require("./lib/StoryHarness")
local ROOT, loadModule = H.ROOT, H.loadModule
local check, profiles, scenes = H.check, H.profiles, H.scenes
local Config = H.Config
local QUICK = (process.args[1] == "rapido")

local Validate = loadModule(ROOT .. "/shared/LifeStory/Validate")
local EventCatalog = loadModule(ROOT .. "/shared/LifeStory/EventCatalog")
local Chapters = loadModule(ROOT .. "/shared/LifeStory/Chapters")
local Quests = H.Quests
local Stages = loadModule(ROOT .. "/shared/LifeStory/Stages")
local Subjects = H.Subjects
local SchoolLife = loadModule(ROOT .. "/shared/LifeStory/SchoolLife")
local Log = loadModule(ROOT .. "/shared/Log")

-- Los avisos de desarrollo se guardan (no llenan la salida) para poder comprobarlos
local logLines: { string } = {}
Log.level = Log.Levels.Info
Log.sink = function(level, category, line)
	table.insert(logLines, level .. " " .. line)
end
local function logged(fragment: string): boolean
	for _, line in logLines do
		if line:find(fragment, 1, true) then
			return true
		end
	end
	return false
end

local Service, StoryEvents = H.boot()
local DialogueService = loadModule(ROOT .. "/server/Services/DialogueService")
H.lighting.ClockTime = 10 -- a media mañana: el colegio, el instituto y la oficina están abiertos

---------------------------------------------------------------------
-- Lo que pasa en la historia de cada jugador (observador de LifeStoryService)
---------------------------------------------------------------------
type Trace = {
	Steps: { [string]: { { Kind: string, Step: number, Type: string? } } },
	Dialogues: { [string]: number }, -- "misión|paso|diálogo" -> veces
	DialogueList: { { Quest: string, Step: number?, Name: string } },
	Recovers: { string },
	Invalid: { string },
	Done: { [string]: boolean },
}
local traces: { [any]: Trace } = {}
local function traceOf(player): Trace
	local trace = traces[player]
	if not trace then
		trace = { Steps = {}, Dialogues = {}, DialogueList = {}, Recovers = {}, Invalid = {}, Done = {} }
		traces[player] = trace
	end
	return trace
end
local dialogueIds = setmetatable({}, { __mode = "k" })
local nextDialogueId = 0
Service.observe(function(kind, player, questId, info)
	local trace = traceOf(player)
	if kind == "StepEnter" or kind == "StepSkip" or kind == "StepTimeout" then
		trace.Steps[questId] = trace.Steps[questId] or {}
		table.insert(trace.Steps[questId], { Kind = kind, Step = info.Step, Type = info.Type })
	elseif kind == "QuestStart" then
		trace.Steps[questId] = {}
	elseif kind == "QuestDone" then
		trace.Done[questId] = true
	elseif kind == "Dialogue" then
		local id = dialogueIds[info.Dialogue]
		if not id then
			nextDialogueId += 1
			id = nextDialogueId
			dialogueIds[info.Dialogue] = id
		end
		local key = ("%s|%s|%d"):format(questId, tostring(info.Step), id)
		trace.Dialogues[key] = (trace.Dialogues[key] or 0) + 1
		table.insert(trace.DialogueList, { Quest = questId, Step = info.Step, Name = info.Name })
	elseif kind == "Recover" then
		table.insert(trace.Recovers, questId .. ":" .. tostring(info.What))
	elseif kind == "QuestInvalid" then
		table.insert(trace.Invalid, questId)
	end
end)

-- Un perfil que se podría guardar en un DataStore: sin cosas de Roblox, sin NaN, y cada tabla o es
-- una lista o solo tiene claves de texto
local function dataStoreSafe(value: any, path: string, problems: { string })
	local kind = type(value)
	if kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			table.insert(problems, path .. ": número no válido")
		end
	elseif kind == "table" then
		local count, stringKeys, numberKeys = 0, 0, 0
		for k, v in value do
			count += 1
			if type(k) == "string" then
				stringKeys += 1
			elseif type(k) == "number" then
				numberKeys += 1
			else
				table.insert(problems, path .. ": clave rara " .. type(k))
			end
			dataStoreSafe(v, path .. "." .. tostring(k), problems)
		end
		if stringKeys > 0 and numberKeys > 0 then
			table.insert(problems, path .. ": mezcla de claves de texto y números")
		elseif numberKeys > 0 and numberKeys ~= #value then
			table.insert(problems, path .. ": lista con huecos")
		end
	elseif kind ~= "string" and kind ~= "boolean" and kind ~= "nil" then
		table.insert(problems, path .. ": " .. kind .. " no se puede guardar")
	end
end

---------------------------------------------------------------------
print("\n▶ 1. Validador de misiones")
---------------------------------------------------------------------
do
	local report = Validate.report()
	for _, e in report.Errors do
		print("    " .. e)
	end
	check(#report.Errors == 0, "Ninguna misión, capítulo o día generado tiene errores")
	check(next(report.BadQuests) == nil, "Todas las misiones se pueden activar")

	-- Romperlo a propósito: una misión con todos los fallos que el validador debe ver
	Quests.Test_Rota = {
		Kind = "Side",
		Title = "Misión rota (prueba)",
		TitleKey = "Misión rota",
		OfferKey = "¿Me ayudas?",
		Offer = { Event = "Talk", Match = { Npc = "Tester_Rota" } },
		Dialogues = { Hola = { Lines = { { S = "Nadie", T = "Hola" } } } },
		Steps = {
			{ Type = "Talk", Npc = "Hugo", Text = "Habla con alguien que no está" },
			{ Type = "Wait", GameMinutes = 30, Text = "Espera sin tope" },
			{ Type = "Event", Event = "EventoQueNadieEmite", Text = "Algo imposible" },
			{ Type = "Choice", Key = "Test", Text = "Decide", Options = { { Id = "A", Text = "A", Stay = true }, { Id = "A", Text = "B", Stay = true } } },
			{ Type = "Reach", Place = "LugarQueNoExiste", Text = "Ve a ningún sitio" },
			{ Type = "Scene", Dialogue = "NoExiste" },
			{ Type = "Moment", Text = "Rama imposible", If = { Choices = { Club = "NoExiste" } } },
		},
		Rewards = { Money = -5 },
	}
	local broken = Validate.report()
	local function found(fragment: string): boolean
		for _, e in broken.Errors do
			if e:find("Test_Rota", 1, true) and e:find(fragment, 1, true) then
				return true
			end
		end
		return false
	end
	check(found("nadie trae a Hugo"), "Detecta: hablar con alguien que nadie trae")
	check(found("sin tope de tiempo real"), "Detecta: espera sin tope real")
	check(found("EventoQueNadieEmite"), "Detecta: evento que nadie emite")
	check(found("opción repetida") and found("ninguna opción cierra"), "Detecta: decisión repetida o sin salida")
	check(found("LugarQueNoExiste"), "Detecta: lugar que no existe")
	check(found("diálogo inexistente"), "Detecta: diálogo que no existe")
	check(found("habla alguien que no está en el reparto"), "Detecta: habla alguien que no está en el reparto")
	check(found("Club = 'NoExiste'"), "Detecta: una rama que pregunta por una opción que no existe")
	check(found("Money debe ser"), "Detecta: recompensa no válida")
	check(broken.BadQuests.Test_Rota == true and not broken.BadQuests.Cole01_PrimerDia, "Solo la misión rota queda marcada")

	-- En el juego: la misión rota no se activa (y queda en el registro)
	local tester = H.newPlayer("Tester", "Adulto")
	task.wait(0.5)
	StoryEvents.emit(tester, "Talk", { Npc = "Tester_Rota" })
	task.wait(0.2)
	check(H.received(tester, "Offer", "Misión rota"), "La misión rota se ofrece (su oferta es válida)")
	H.fromClient(tester, "Offer", "Test_Rota", true)
	task.wait(0.2)
	check(profiles[tester].Story.Active.Test_Rota == nil, "Una misión con errores no se activa")
	check(table.find(traceOf(tester).Invalid, "Test_Rota") ~= nil and logged("[MISSION] failed Test_Rota"), "…y se avisa: [MISSION] failed")

	-- Una principal rota no bloquea el capítulo: se salta
	Quests.Test_Rota = nil
	check(#Validate.report().Errors == 0, "Sin la misión rota, todo vuelve a estar bien")
	H.leave(tester)
end

---------------------------------------------------------------------
print("\n▶ 2. Los eventos que esperan las misiones los emite algún sistema")
---------------------------------------------------------------------
do
	local emitted: { [string]: boolean } = {}
	local function scan(dir: string)
		for _, name in fs.readDir(dir) do
			local path = dir .. "/" .. name
			if fs.isDir(path) then
				scan(path)
			elseif name:match("%.luau$") then
				for event in fs.readFile(path):gmatch('StoryEvents%.emit%([^,]+,%s*"([%w_]+)"') do
					emitted[event] = true
				end
			end
		end
	end
	scan(ROOT .. "/server")
	local missing, unlisted = {}, {}
	for name in EventCatalog.Names do
		if not emitted[name] then
			table.insert(missing, name)
		end
	end
	for name in emitted do
		if not EventCatalog.Names[name] then
			table.insert(unlisted, name)
		end
	end
	table.sort(missing)
	table.sort(unlisted)
	check(#missing == 0, "Cada evento del catálogo se emite en el servidor " .. (if #missing > 0 then "(faltan: " .. table.concat(missing, ", ") .. ")" else ""))
	check(#unlisted == 0, "Cada evento que se emite está en el catálogo " .. (if #unlisted > 0 then "(sin apuntar: " .. table.concat(unlisted, ", ") .. ")" else ""))
end

---------------------------------------------------------------------
-- Jugador automático para partidas completas
---------------------------------------------------------------------

-- La opción que toca en la vida número `run` (así cada opción sale en alguna vida)
local function pickIndex(run: number, count: number, salt: number): number
	return ((run - 1 + salt) % count) + 1
end

local function visibleOptions(player, step)
	local list = {}
	for _, option in step.Options do
		if H.passes(player, option.If) then
			table.insert(list, option)
		end
	end
	return list
end

local choiceSalt: { [string]: number } = {}
local function doChoice(player, questId, step, run: number)
	local options = visibleOptions(player, step)
	if #options == 0 then
		options = step.Options
	end
	-- Las opciones "Stay" (acusar a quien no era) se prueban una vez y luego se elige otra
	player.Stayed = player.Stayed or {}
	local closing = {}
	for _, option in options do
		if not option.Stay or not player.Stayed[questId .. option.Id] then
			table.insert(closing, option)
		end
	end
	if #closing == 0 then
		closing = options
	end
	local option = closing[pickIndex(run, #closing, choiceSalt[step.Key] or 0)]
	if option.Stay then
		player.Stayed[questId .. option.Id] = true
	end
	if option.Npc then
		Service.interact(player, "Actor", questId, option.Npc)
	elseif option.Prop then
		Service.interact(player, "Prop", questId, option.Prop)
	else
		H.fromClient(player, "Choose", questId, option.Id)
	end
end

-- Hace lo que pide el paso (como H.doStep, pero las decisiones según la vida)
local function act(player, questId, step, run: number)
	if step.Type == "Choice" then
		doChoice(player, questId, step, run)
	else
		H.doStep(player, questId, step)
	end
end

-- Respuestas en las conversaciones: distintas en cada vida
local function answerFor(run: number)
	local n = 0
	return function(_, options)
		n += 1
		return pickIndex(run, #options, n)
	end
end

-- ¿Está la persona con la que hay que hablar? (en la escena o la traen los sistemas de siempre)
local function present(player, questId, npc): boolean
	local scene = scenes[player] and scenes[player][questId]
	if scene and scene.Actors[npc] then
		return true
	end
	return Validate.ambientNpc(npc)
end

-- Revisa lo que pasó en una misión terminada: pasos en orden, sin saltos ni repeticiones
local function stepsProblems(player, questId, prog): { string }
	local problems = {}
	local trace = traceOf(player)
	local events = trace.Steps[questId] or {}
	local total = if prog and prog.Steps then #prog.Steps else #(Quests[questId].Steps or {})
	local seen = {}
	local last = 0
	for _, event in events do
		if seen[event.Step] and event.Kind ~= "StepTimeout" then
			table.insert(problems, ("paso %d repetido"):format(event.Step))
		end
		if event.Kind ~= "StepTimeout" then
			seen[event.Step] = true
			if event.Step < last then
				table.insert(problems, ("paso %d después del %d"):format(event.Step, last))
			end
			last = event.Step
		end
	end
	for i = 1, total do
		if not seen[i] then
			table.insert(problems, ("paso %d saltado"):format(i))
		end
	end
	for key, count in trace.Dialogues do
		if key:sub(1, #questId + 1) == questId .. "|" and count > 1 then
			table.insert(problems, "conversación repetida " .. key)
		end
	end
	return problems
end

-- Recompensas de la misión en el perfil
local function rewardProblems(player, questId): { string }
	local quest = Quests[questId]
	local story = profiles[player].Story
	local problems = {}
	local rewards = quest.Rewards or {}
	for _, flag in rewards.Flags or {} do
		if not story.Flags[flag] and not table.find(rewards.Unflags or {}, flag) then
			table.insert(problems, "falta la marca " .. flag)
		end
	end
	for id in rewards.Items or {} do
		if (profiles[player].Items[id] or 0) < 1 and not (rewards.Take and rewards.Take[id]) then
			table.insert(problems, "falta el objeto " .. id)
		end
	end
	for _, key in (if type(rewards.Memory) == "table" then rewards.Memory else { rewards.Memory }) do
		if key and not (story.Memories and story.Memories[key]) then
			table.insert(problems, "falta el recuerdo " .. key)
		end
	end
	if quest.Memory and not (story.Memories and story.Memories[quest.Memory]) then
		table.insert(problems, "falta el recuerdo " .. quest.Memory)
	end
	return problems
end

-- El capítulo de una misión principal y su posición
local chapterOf: { [string]: string } = {}
for id, chapter in Chapters do
	for _, questId in chapter.Main do
		chapterOf[questId] = id
	end
end

-- La siguiente principal que tocará (para no tener que vivir días de relleno entre misiones)
local function nextPending(story): string?
	local chapter = story.Chapter and Chapters[story.Chapter]
	if not chapter then
		return nil
	end
	local passedActive = false
	for _, questId in chapter.Main do
		if story.Active[questId] then
			passedActive = true
		elseif not story.Completed[questId] then
			return questId
		end
	end
	return nil
end

local function bumpStageProgress(player)
	local data = profiles[player]
	local pending = nextPending(data.Story)
	local req = pending and Quests[pending].Requires
	local hours = Config.LifeStory.StageHours[data.Life.Stage]
	if req and req.StageProgress and hours then
		local want = (req.StageProgress + 0.005) * hours * 3600
		if (data.Life.StageSeconds or 0) < want then
			data.Life.StageSeconds = want
		end
	end
end

---------------------------------------------------------------------
print("\n▶ 3. Vidas enteras (cada decisión con cada opción en alguna vida)")
---------------------------------------------------------------------
local mainProblems: { [string]: { string } } = {}
local function problem(questId: string, text: string)
	mainProblems[questId] = mainProblems[questId] or {}
	if #mainProblems[questId] < 6 then
		table.insert(mainProblems[questId], text)
	end
end

local lives = if QUICK then 1 else 3
local lifeDone = 0
local lifeReports = {}
for run = 1, lives do
	task.spawn(function()
		local player = H.newPlayer("Vida" .. run)
		player.Answer = answerFor(run)
		local story = profiles[player].Story
		local stuckAt, stuckSince = nil, os.clock()
		local finished = false
		local completedMains = {}
		for _ = 1, 4000 do
			bumpStageProgress(player)
			local questId, prog, step = H.mainStep(player)
			if not (questId and step) and stuckAt ~= "(espera)" then
				stuckAt, stuckSince = "(espera)", os.clock()
			end
			if questId and step then
				local where = questId .. ":" .. prog.Step
				if where ~= stuckAt then
					stuckAt, stuckSince = where, os.clock()
				elseif os.clock() - stuckSince > 90 then
					problem(questId, ("atascada en el paso %d (%s) de la vida %d"):format(prog.Step, step.Type, run))
					break
				end
				if step.Type == "Talk" and step.Dialogue and Quests[questId].Dialogues and not present(player, questId, step.Npc) then
					problem(questId, ("paso %d: %s no está para hablar"):format(prog.Step, step.Npc))
				end
				act(player, questId, step, run)
			elseif story.Chapter == nil then
				finished = true
				break
			elseif os.clock() - stuckSince > 30 then
				problem("(vida " .. run .. ")", "nada que hacer y la historia no sigue (capítulo " .. tostring(story.Chapter) .. ")")
				break
			end
			-- Misiones de mitad de vida que no son principales (secundarias canónicas…): no se juegan aquí
			for id in story.Completed do
				if Quests[id] and Quests[id].Kind == "Main" and not completedMains[id] then
					completedMains[id] = true
					local trace = traceOf(player)
					if trace.Done[id] then
						for _, p in stepsProblems(player, id, nil) do
							problem(id, p .. " (vida " .. run .. ")")
						end
						for _, p in rewardProblems(player, id) do
							problem(id, p .. " (vida " .. run .. ")")
						end
					end
				end
			end
			task.wait(0.6)
		end
		local chapters = {}
		for id in story.Chapters do
			table.insert(chapters, id)
		end
		table.sort(chapters, function(a, b)
			return Chapters[a].Order < Chapters[b].Order
		end)
		lifeReports[run] = { Finished = finished, Chapters = chapters, Player = player }
		lifeDone += 1
	end)
	task.wait(1.3)
end
while lifeDone < lives do
	task.wait(1)
end
for run = 1, lives do
	local report = lifeReports[run]
	local player = report.Player
	local story = profiles[player].Story
	-- Cada capítulo terminado tiene todas sus principales terminadas (ninguna saltada)
	local incomplete = {}
	for _, chapterId in report.Chapters do
		for _, questId in Chapters[chapterId].Main do
			if not story.Completed[questId] or (story.Skipped and story.Skipped[questId]) then
				table.insert(incomplete, questId)
			end
		end
	end
	check(report.Finished and #incomplete == 0, ("Vida %d: de bebé a adulto (%s)%s"):format(run, table.concat(report.Chapters, " → "), if #incomplete > 0 then " · sin terminar: " .. table.concat(incomplete, ", ") else ""))
	check(#traceOf(player).Recovers == 0, ("Vida %d: el vigilante no ha tenido que arreglar nada (%s)"):format(run, table.concat(traceOf(player).Recovers, ", ")))
	local problems = {}
	dataStoreSafe(profiles[player], "perfil", problems)
	check(#problems == 0, ("Vida %d: el perfil se puede guardar en un DataStore %s"):format(run, table.concat(problems, "; ")))
end
local mainIds = {}
for id in mainProblems do
	table.insert(mainIds, id)
end
table.sort(mainIds)
for _, id in mainIds do
	print(("    %s: %s"):format(id, table.concat(mainProblems[id], " · ")))
end
check(#mainIds == 0, "Cada principal: pasos en orden sin saltos ni repeticiones, conversaciones una vez, personajes presentes, recompensas")


---------------------------------------------------------------------
print("\n▶ 4. Romperlo: cada principal a la vez, saliendo, muriendo y tocando de más")
---------------------------------------------------------------------

-- Un perfil justo al empezar la misión `questId` (lo anterior hecho, los requisitos cumplidos)
local function profileFor(questId: string)
	local chapterId = chapterOf[questId]
	local chapter = Chapters[chapterId]
	local quest = Quests[questId]
	local stage = chapter.Stage.Min or "Adulto"
	local profile = {
		Money = 500,
		Stats = { PlaySeconds = if chapterId == "Adulto_NuevaVida" then 3600 else 0 },
		Life = { Stage = stage, AgeYears = Config.LifeStory.AgeRange[stage][1], StageSeconds = 0 },
		Education = { Subjects = {}, Exams = {}, Degrees = {}, Attendance = 0 },
		Items = { MochilaCole = 1 },
		Story = {
			Version = 1, Chapter = chapterId, Chapters = {}, Active = {}, Completed = {}, Declined = {},
			Choices = {}, Flags = {}, Discovered = {}, NpcMemory = {}, Events = {}, Memories = {}, Traits = {},
		},
	}
	local story = profile.Story
	for id, other in Chapters do
		if other.Enabled and other.Order < chapter.Order and id ~= "Adulto_NuevaVida" then
			story.Chapters[id] = 1
			for _, mainId in other.Main do
				story.Completed[mainId] = 1
			end
		end
	end
	for _, mainId in chapter.Main do
		if mainId == questId then
			break
		end
		story.Completed[mainId] = 1
	end
	if chapterId == "Joven_Universidad" then
		story.Flags.VaALaUniversidad = true
		story.Choices.Estudios = { V = "Medicina", D = 1 }
	end
	if chapterId == "Adulto_NuevaVida" then
		story.Completed.Ins06_LaGranDecision = nil
	end
	-- Los requisitos de la misión
	local req = quest.Requires or {}
	for _, flag in req.Flags or {} do
		story.Flags[flag] = true
	end
	for key, value in req.Choices or {} do
		story.Choices[key] = { V = value, D = 1 }
	end
	for _, id in req.Completed or {} do
		story.Completed[id] = 1
	end
	for _, id in req.NotCompleted or {} do
		story.Completed[id] = nil
	end
	for _, key in req.Memories or {} do
		story.Memories[key] = { D = 1, T = 1 }
	end
	for npc, min in req.Rel or {} do
		story.NpcMemory[npc] = { Facts = {}, Affinity = 0, Rel = min + 1 }
	end
	for trait, min in req.Traits or {} do
		story.Traits[trait] = min
	end
	local hours = Config.LifeStory.StageHours[stage]
	if req.StageProgress and hours then
		profile.Life.StageSeconds = (req.StageProgress + 0.01) * hours * 3600
	end
	return profile
end

local breakProblems: { [string]: { string } } = {}
local breaksDone: { [string]: { string } } = {}
local function breakProblem(questId: string, text: string)
	breakProblems[questId] = breakProblems[questId] or {}
	table.insert(breakProblems[questId], text)
end
local function noted(questId: string, what: string)
	breaksDone[questId] = breaksDone[questId] or {}
	table.insert(breaksDone[questId], what)
end

local function waitFor(condition: () -> boolean, seconds: number): boolean
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		if condition() then
			return true
		end
		task.wait(0.1)
	end
	return condition()
end

local function dialoguesAt(player, questId, stepIndex): number
	local count = 0
	for _, entry in traceOf(player).DialogueList do
		if entry.Quest == questId and entry.Step == stepIndex then
			count += 1
		end
	end
	return count
end

-- Empieza (retenida: el jugador "está leyendo") la conversación con npc. Espera a que no haya otra
-- conversación ni el respiro tras la anterior, y lo intenta unas veces. true si empezó.
local function holdTalk(player, questId, npc): boolean
	player.Hold = true
	player.Held = {}
	for _ = 1, 4 do
		waitFor(function()
			local state = Service.debugState(player)
			return not DialogueService.isBusy(player) and not (state and state.Busy)
		end, 4)
		task.wait(1.4) -- el toque que cierra una conversación no abre otra (Guard.AfterDialogue)
		Service.interact(player, "Actor", questId, npc)
		if waitFor(function()
			return #player.Held > 0
		end, 1.5) then
			return true
		end
	end
	player.Hold = false
	return false
end

-- Juega una misión con todos los "rompimientos" que se puedan en ella
local function breakMission(questId: string, index: number)
	local profile = profileFor(questId)
	local player = H.newPlayer("Rompe" .. index, nil, nil, profile)
	player.Answer = answerFor(index)
	local started = waitFor(function()
		return profiles[player].Story.Active[questId] ~= nil
	end, 12)
	if not started then
		breakProblem(questId, "no empieza con sus requisitos cumplidos")
		H.leave(player)
		return
	end
	local pending = { Rejoin = true, Double = true, Other = true, Die = true, Away = true }
	local stuckAt, stuckSince = nil, os.clock()
	for _ = 1, 900 do
		local story = profiles[player].Story
		if story.Completed[questId] then
			break
		end
		local prog, step = H.questStep(player, questId)
		if not prog or not step then
			task.wait(0.3)
			continue
		end
		local where = prog.Step
		if where ~= stuckAt then
			stuckAt, stuckSince = where, os.clock()
		elseif os.clock() - stuckSince > 90 then
			breakProblem(questId, ("atascada en el paso %d (%s)"):format(prog.Step, step.Type))
			break
		end
		if player.Hold and step.Type ~= "Scene" and player.Held and #player.Held > 0 then
			H.release(player) -- se retuvo una conversación que no era la escena esperada
		end
		local talk = step.Type == "Talk" and step.Dialogue ~= nil and not (prog.Chatted and prog.Chatted[step.Npc])
		local episodic = Quests[questId].Dialogues ~= nil

		if pending.Rejoin and episodic and talk and present(player, questId, step.Npc) then
			-- 1) Salir del juego en plena conversación y volver
			pending.Rejoin = false
			if holdTalk(player, questId, step.Npc) then
				local stepBefore = prog.Step
				local saved = H.leave(player)
				local problems = {}
				dataStoreSafe(serde.decode("json", saved), "perfil", problems)
				if #problems > 0 then
					breakProblem(questId, "perfil que no se puede guardar: " .. problems[1])
				end
				task.wait(0.5)
				local old = player
				player = H.rejoin(old, saved)
				player.Answer = answerFor(index)
				local resumed = waitFor(function()
					local now = profiles[player].Story.Active[questId]
					return now ~= nil and now.Step == stepBefore and scenes[player] ~= nil and scenes[player][questId] ~= nil
				end, 12)
				if not resumed then
					breakProblem(questId, ("al volver no sigue en el paso %d con su escena"):format(stepBefore))
				elseif not present(player, questId, step.Npc) then
					breakProblem(questId, "al volver " .. step.Npc .. " no está")
				elseif DialogueService.isBusy(player) then
					breakProblem(questId, "al volver sigue una conversación a medias")
				else
					noted(questId, "salir y volver")
				end
			else
				player.Hold = false
				breakProblem(questId, "la conversación con " .. step.Npc .. " no empieza")
			end
			task.wait(0.4)
			continue
		end

		if pending.Double and episodic and talk and present(player, questId, step.Npc) and not DialogueService.isBusy(player) then
			-- 2) Tocar dos veces seguidas (y una tercera enseguida)
			pending.Double = false
			local stepIndex = prog.Step
			Service.interact(player, "Actor", questId, step.Npc)
			Service.interact(player, "Actor", questId, step.Npc)
			task.wait(0.35)
			Service.interact(player, "Actor", questId, step.Npc)
			task.wait(1.2)
			local count = dialoguesAt(player, questId, stepIndex)
			if count ~= 1 then
				breakProblem(questId, ("tocar tres veces seguidas a %s abre %d conversaciones"):format(step.Npc, count))
			else
				noted(questId, "doble toque")
			end
			continue
		end

		if pending.Other and step.Type == "Scene" and player.Hold then
			-- 3) Tocar a otro personaje en plena escena
			pending.Other = false
			local stepIndex = prog.Step
			local ok = waitFor(function()
				return player.Held ~= nil and #player.Held > 0
			end, 6)
			if ok then
				local before = #traceOf(player).DialogueList
				local scene = scenes[player] and scenes[player][questId]
				local touched = 0
				for npc in (scene and scene.Actors) or {} do
					Service.interact(player, "Actor", questId, npc)
					touched += 1
				end
				for id in (scene and scene.Props) or {} do
					Service.interact(player, "Prop", questId, id)
					touched += 1
				end
				task.wait(0.3)
				local now = profiles[player].Story.Active[questId]
				if #traceOf(player).DialogueList ~= before then
					breakProblem(questId, "tocar a otro en plena escena abre otra conversación")
				elseif not now or now.Step ~= stepIndex then
					breakProblem(questId, "tocar a otro en plena escena cambia el paso")
				else
					noted(questId, ("tocar a otros en la escena (%d)"):format(touched))
				end
			else
				breakProblem(questId, ("la escena del paso %d no empieza"):format(stepIndex))
			end
			H.release(player)
			task.wait(0.4)
			continue
		end

		if pending.Die and episodic and talk and present(player, questId, step.Npc) and not DialogueService.isBusy(player) then
			-- 4) Morir en plena conversación, volver del hospital y terminarla
			pending.Die = false
			local stepIndex = prog.Step
			if holdTalk(player, questId, step.Npc) then
				player:SetAttribute("Dead", true)
				StoryEvents.emit(player, "Died", {})
				task.wait(0.3)
				local state = Service.debugState(player)
				if DialogueService.isBusy(player) or player:GetAttribute("InDialogue") then
					breakProblem(questId, "al morir la conversación sigue abierta")
				elseif state and state.Busy then
					breakProblem(questId, "al morir la historia se queda ocupada")
				end
				task.wait(1)
				if #traceOf(player).DialogueList > 0 and dialoguesAt(player, questId, stepIndex) > 1 then
					breakProblem(questId, "estando muerto empieza otra conversación")
				end
				player:SetAttribute("Dead", nil)
				StoryEvents.emit(player, "Revived", {})
				H.release(player) -- respuestas de la conversación cortada: no cuentan
				task.wait(0.3)
				local now = profiles[player].Story.Active[questId]
				if not now or now.Step ~= stepIndex then
					breakProblem(questId, "al morir la conversación cuenta como hecha")
				else
					noted(questId, "morir y volver")
				end
			else
				breakProblem(questId, "la conversación con " .. step.Npc .. " no empieza (morir)")
			end
			continue
		end

		if pending.Away and step.Type == "Reach" then
			-- 5) Irse lejos y volver
			pending.Away = false
			local stepIndex = prog.Step
			player.At = "MuyLejos"
			task.wait(1.5)
			local now = profiles[player].Story.Active[questId]
			if not now or now.Step ~= stepIndex then
				breakProblem(questId, "irse lejos cuenta como haber llegado")
			else
				noted(questId, "irse lejos")
			end
		end

		-- Si lo siguiente es una escena, el jugador "leerá despacio" para poder tocar a otros en ella
		local steps = prog.Steps or Quests[questId].Steps
		local nextStep = steps[prog.Step + 1]
		if pending.Other and nextStep and nextStep.Type == "Scene" and not nextStep.If then
			player.Hold = true
			player.Held = {}
		end
		act(player, questId, step, index)
		task.wait(0.6)
	end
	local story = profiles[player].Story
	if not story.Completed[questId] then
		local prog, step = H.questStep(player, questId)
		breakProblem(questId, ("no termina (paso %s, %s)"):format(tostring(prog and prog.Step), tostring(step and step.Type)))
	else
		for _, p in rewardProblems(player, questId) do
			breakProblem(questId, p)
		end
	end
	if player:GetAttribute("InDialogue") or DialogueService.isBusy(player) then
		breakProblem(questId, "al terminar sigue en una conversación")
	end
	H.leave(player)
end

local mains = {}
for _, chapterId in { "Nino_ElColegio", "Adolescente_Instituto", "Joven_Universidad", "Adulto_VolarDelNido", "Adulto_NuevaVida" } do
	for _, questId in Chapters[chapterId].Main do
		if Quests[questId] and not Quests[questId].DayPlan then
			table.insert(mains, questId)
		end
	end
end
local running = 0
if QUICK then
	mains = {} -- (rápido: sin la parte de romper cada misión)
end
for i, questId in mains do
	running += 1
	task.spawn(function()
		local ok, err = pcall(breakMission, questId, i)
		if not ok then
			breakProblem(questId, "error: " .. tostring(err))
		end
		running -= 1
	end)
	task.wait(0.25)
end
while running > 0 do
	task.wait(1)
end
local total, clean = 0, 0
for _, questId in mains do
	total += 1
	local list = breakProblems[questId]
	if list then
		print(("    ❌ %s: %s"):format(questId, table.concat(list, " · ")))
	else
		clean += 1
		print(("    ✔ %s: %s"):format(questId, table.concat(breaksDone[questId] or { "sin rompimientos aplicables" }, ", ")))
	end
end
check(QUICK or clean == total, ("%d/%d principales aguantan salir y volver, morir, tocar de más e irse lejos (y terminan)"):format(clean, total))

print("\n▶ 5. Depuración: solo para el dueño")
do
	local DebugService = loadModule(ROOT .. "/server/Services/DebugService")
	DebugService.init()
	local owner = H.newPlayer("Duena", "Nino")
	owner.UserId = 1 -- el creador del juego (game.CreatorId)
	local normal = H.newPlayer("Normal", "Nino")
	task.wait(0.5)
	check(DebugService.allowed(owner) and not DebugService.allowed(normal), "Solo el creador del juego (o Studio, o Config.Debug.DebugUserIds) puede depurar")
	for _, command in { "/debug mission", "/debug npc", "/debug story", "/debug teleport PlazaCentro", "/debug resetmission", "/debug validate", "/debug hud", "/debug log" } do
		check(DebugService.handle(normal, command) == nil, "Un jugador normal no puede usar «" .. command .. "»")
	end
	H.debugRemote.OnServerEvent:Fire(normal, "Command", "/debug teleport PlazaCentro")
	task.wait(0.4)
	check(normal.DebugInbox == nil and normal.TeleportedTo == nil, "…ni desde el panel: no le llega nada ni se mueve")
	local lines = DebugService.handle(owner, "/debug mission")
	check(lines ~= nil and #lines >= 2 and table.concat(lines, "\n"):find("Cole01_PrimerDia", 1, true) ~= nil, "/debug mission: misión, paso y objetivo")
	lines = DebugService.handle(owner, "/debug story")
	check(lines ~= nil and table.concat(lines, "\n"):find("Etapa Nino", 1, true) ~= nil, "/debug story: etapa, edad, capítulo, decisiones, relaciones")
	check(DebugService.handle(owner, "/debug npc") ~= nil, "/debug npc: personajes de alrededor")
	task.wait(0.4)
	DebugService.handle(owner, "/debug teleport PlazaCentro")
	check(owner.TeleportedTo ~= nil, "/debug teleport <lugar>")
	lines = DebugService.handle(owner, "/debug validate")
	check(lines ~= nil and lines[1]:find("0 errores", 1, true) ~= nil, "/debug validate: pasa el validador")
	local before = profiles[owner].Story.Active.Cole01_PrimerDia
	profiles[owner].Story.Active.Cole01_PrimerDia.Step = 3
	lines = DebugService.handle(owner, "/debug resetmission")
	local after = profiles[owner].Story.Active.Cole01_PrimerDia
	check(lines ~= nil and before ~= nil and after ~= nil and after ~= before and after.Step <= 2, "/debug resetmission: la misión vuelve a empezar")
	DebugService.handle(owner, "/debug hud")
	local hud = nil
	for _, message in owner.DebugInbox or {} do
		if message.Kind == "Hud" and type(message.Payload) == "table" then
			hud = message.Payload
		end
	end
	check(hud ~= nil and hud.Mission and hud.Story and hud.Npcs and hud.Location and hud.Dialogue, "Panel de depuración: misión, vida, personajes cerca, dónde y conversación")
	H.leave(owner)
	H.leave(normal)
end

print("\n▶ 6. Registro de desarrollo")
check(logged("[MISSION] started") and logged("[MISSION] completed"), "[MISSION] started / completed")
check(logged("[OBJECTIVE]"), "[OBJECTIVE] pasos completados")
check(logged("[DIALOGUE] started") and logged("[DIALOGUE] ended") and (QUICK or logged("[DIALOGUE] cancelled")), "[DIALOGUE] started / ended / cancelled")

print(("\n%s"):format(if H.failures == 0 then "✅ Todo correcto" else ("❌ %d fallos"):format(H.failures)))
process.exit(if H.failures == 0 then 0 else 1)
