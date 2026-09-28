-- StoryContext: lo que el jugador necesita para ENTENDER su historia (y no solo seguir flechas).
--   * Tipo de cada misión con su etiqueta: ⭐ tu vida (principal), 🌀 misión loca, ❗ saga de la Grieta…
--   * Tarjeta de una misión: quién te lo pide y por qué (Description).
--   * «Anteriormente en tu vida…»: capítulo, etapa y las 2-3 últimas cosas importantes.
--   * «Mi historia» (diario): capítulos, personajes que conoces y recuerdos.
-- Solo LEE los datos guardados (data.Story, data.Life): lo usan LifeStoryService y las pruebas.

local Chapters = require(script.Parent.Chapters)
local Quests = require(script.Parent.Quests)
local Cast = require(script.Parent.Cast)
local Memories = require(script.Parent.Memories)
local StoryState = require(script.Parent.StoryState)

local StoryContext = {}

StoryContext.PrologueId = "Prologo_Sueno"

-- Nombre de cada etapa, para leerlo ("Estás en: la infancia")
StoryContext.StageNames = {
	Bebe = "Bebé",
	Nino = "Infancia (el colegio)",
	Adolescente = "Adolescencia (el instituto)",
	AdultoJoven = "Joven adulto",
	Adulto = "Vida adulta",
	Mayor = "La edad de la experiencia",
}

-- Tipos de misión: icono y etiqueta que se ven en la oferta, al empezar y en la tarjeta "Tu vida"
StoryContext.Kinds = {
	Prologo = { Icon = "✨", Label = "Prólogo" },
	Principal = { Icon = "⭐", Label = "Tu vida · historia principal" },
	Loca = { Icon = "🌀", Label = "Misión loca (con Cosme)" },
	Saga = { Icon = "❗", Label = "Saga de la Grieta" },
	Consecuencia = { Icon = "🔁", Label = "Consecuencia de lo que hiciste" },
	Secundaria = { Icon = "🔶", Label = "Secundaria" },
}

function StoryContext.kindOf(quest: { [string]: any }?): string
	if not quest then
		return "Secundaria"
	end
	local label = if type(quest.Type) == "string" then quest.Type else ""
	local id = if type(quest.Id) == "string" then quest.Id else ""
	if quest.Prologue then
		return "Prologo"
	elseif quest.Canon or label:find("^Saga de la Grieta") then
		return "Saga"
	elseif label:find("^Misión loca") or id:find("^Loco_") then
		return "Loca"
	elseif quest.Kind == "Main" then
		return "Principal"
	elseif label:find("^Consecuencia") then
		return "Consecuencia"
	end
	return "Secundaria"
end

function StoryContext.label(quest: { [string]: any }?): { Icon: string, Label: string, Kind: string }
	local kind = StoryContext.kindOf(quest)
	local info = StoryContext.Kinds[kind]
	return { Icon = info.Icon, Label = info.Label, Kind = kind }
end

-- Los personajes de la familia de casa se llaman distinto en las misiones del bebé
local ALIAS = { Familia_Abu = "Abu", Familia_Padre = "Familia", Familia_Madre = "Familia" }
local function castId(npc: any): string?
	if type(npc) ~= "string" then
		return nil
	end
	local id = ALIAS[npc] or npc
	return if Cast.People[id] then id else nil
end

-- Quién te pide la misión: Asker, el primero de Npcs o con quien se habla primero
function StoryContext.askerOf(quest: { [string]: any }?): string?
	if not quest then
		return nil
	end
	if castId(quest.Asker) then
		return castId(quest.Asker)
	end
	for _, npc in quest.Npcs or {} do
		if castId(npc) then
			return castId(npc)
		end
	end
	for _, step in quest.Steps or {} do
		if step.Type == "Talk" and castId(step.Npc) then
			return castId(step.Npc)
		end
	end
	return nil
end

-- Tarjeta de contexto de una misión (oferta o comienzo). El nombre puede ser una clave de Strings.
function StoryContext.card(questId: string, attributes: { [string]: any }?): { [string]: any }?
	local quest = Quests[questId]
	if not quest then
		return nil
	end
	local info = StoryContext.label(quest)
	local asker = StoryContext.askerOf(quest)
	return {
		QuestId = questId,
		TitleKey = quest.TitleKey or quest.Title,
		Description = quest.Description,
		Kind = info.Kind,
		Icon = info.Icon,
		Label = info.Label,
		Asker = if asker then Cast.nameOf(asker, attributes) else nil,
	}
end

---------------------------------------------------------------------
-- Quién es quién (una línea para el diario, sin destripar la historia)
---------------------------------------------------------------------
StoryContext.Who = {
	Familia = "Tu familia. Te cuida desde el día en que naciste.",
	Abu = "Tu abu. Calma, refranes e historias de cuando Valmar era un pueblo.",
	Lucia = "Tu tutora del colegio. Cariñosa y exigente.",
	Nico = "Compañero de clase. Deportista: para él todo es un reto.",
	Sara = "Compañera de clase. Curiosa, lista y muy rápida hablando.",
	Omar = "Compañero de clase. Tranquilo, siempre dibujando.",
	Mateo = "El chico nuevo del barrio. Tímido, colecciona cromos.",
	Dani = "El hermano pequeño de Mateo. Lo pregunta todo.",
	Bruno = "El jefe de «los malotes» del colegio.",
	Hugo = "Iba con Bruno sin querer. Le encantan los piratas.",
	Ruben = "El bromista del grupo de Bruno.",
	Leire = "Nueva en Valmar, siempre con su cámara vieja.",
	Rayo = "El que manda en el muelle. Gracioso… y peligroso.",
	Nerea = "De la pandilla de Rayo. Lista y sarcástica.",
	Javier = "Tu tutor del instituto y profe de Historia.",
	Carmen = "La orientadora del instituto. Te ayuda a decidir tu futuro.",
	Ivan = "Tu compañero de la residencia. Caótico y generoso.",
	Candela = "Tu compañera de la residencia. Organizadísima.",
	Beltran = "La profesora más exigente de tu facultad.",
	Cosme = "Tu vecino inventor, el del garaje. Sabe más de la Grieta de lo que dice.",
	Pip = "El robot mayordomo de Cosme. Muy educado y muy dramático.",
	Bigotes = "El gato del colegio. En secreto, emperador de Gatonia.",
	DonEscamas = "Un pez de otra dimensión que habla (demasiado).",
	CazadorTiempo = "Agente de la Aduana del Tiempo. Lleva cuarenta formularios encima.",
	Cosimo = "El antiguo socio de Cosme. Lleva perilla. Nada bueno.",
	RatonPerez = "El Ratón Pérez de verdad (y tiene problemas laborales).",
	PolloGigante = "Petra, una gallina de seis metros de Villaverde.",
	Rex = "Un velocirraptor. Tu compañero de piso. Sí, en serio.",
	Zoltan = "Una máquina que concede deseos… a su manera.",
	CapitanNoz = "Capitana alienígena. Graba un reality sobre la Tierra.",
}

function StoryContext.whoIs(id: string): string
	local line = StoryContext.Who[id]
	if line then
		return line
	end
	local person = Cast.People[id]
	local bio = person and person.Bio or ""
	local first = bio:match("^(.-[%.!?])%s") or bio
	return if first ~= "" then first else "Alguien de Valmar."
end

-- Cómo os lleváis (la relación va más o menos de -100 a 100)
function StoryContext.relationText(rel: number): string
	if rel >= 60 then
		return "💛 Os adoráis"
	elseif rel >= 25 then
		return "😊 Buenos amigos"
	elseif rel >= 8 then
		return "🙂 Os lleváis bien"
	elseif rel > -8 then
		return "🤝 Os conocéis"
	elseif rel > -30 then
		return "😒 Hay roces"
	end
	return "😠 Mal rollo"
end

---------------------------------------------------------------------
-- «Anteriormente en tu vida…»
---------------------------------------------------------------------

-- Momentos que no cuentan como «importantes» (se repiten cada día)
local function routineMoment(key: any): boolean
	return type(key) ~= "string" or key:find("^MOMENT%.DIA_") ~= nil or key == "MOMENT.CUMPLEANOS"
end

local memoryIconByText: { [string]: string } = {}
for _, memory in Memories do
	memoryIconByText[memory.Text] = memory.Icon
end

-- ¿Tiene ya una vida empezada? (para el resumen al volver)
function StoryContext.hasProgress(data: { [string]: any }?): boolean
	local story = data and data.Story
	if not story then
		return false
	end
	for id in story.Completed or {} do
		if id ~= StoryContext.PrologueId then
			return true
		end
	end
	return story.Chapter ~= nil or next(story.Chapters or {}) ~= nil
end

-- Las últimas cosas importantes (de la biografía): recuerdos, decisiones y momentos, de más
-- antigua a más nueva. Cada una: { Kind, Key, Args?, Icon }
function StoryContext.recent(data: { [string]: any }?, max: number?): { { [string]: any } }
	local events = (data and data.Story and data.Story.Events) or {}
	local limit = max or 3
	local picked = {}
	local seen = {}
	for i = #events, 1, -1 do
		local event = events[i]
		local kind = event.Y
		local key = event.K
		local wanted = (kind == "Memory" or kind == "Choice" or (kind == "Moment" and not routineMoment(key)))
		if wanted and type(key) == "string" and not seen[key] then
			seen[key] = true
			local icon = if kind == "Memory" then (memoryIconByText[key] or "💭") elseif kind == "Choice" then "🔀" else "✨"
			table.insert(picked, 1, { Kind = kind, Key = key, Args = event.A, Icon = icon })
			if #picked >= limit then
				break
			end
		end
	end
	-- Sin biografía (datos antiguos): las últimas misiones terminadas
	if #picked == 0 then
		local done = {}
		for id, at in (data and data.Story and data.Story.Completed) or {} do
			local quest = Quests[id]
			if quest and not quest.DayPlan and id ~= StoryContext.PrologueId and type(at) == "number" then
				table.insert(done, { Id = id, At = at })
			end
		end
		table.sort(done, function(a, b)
			return a.At > b.At
		end)
		for i = math.min(limit, #done), 1, -1 do
			local quest = Quests[done[i].Id]
			table.insert(picked, { Kind = "Quest", Key = quest.TitleKey or quest.Title, Icon = "✔" })
		end
	end
	return picked
end

-- El resumen (sin el objetivo actual: ese lo pone el servidor, que sabe los lugares)
function StoryContext.recap(data: { [string]: any }): { [string]: any }
	local story = data.Story or {}
	local stage = data.Life and data.Life.Stage
	local chapter = story.Chapter and Chapters[story.Chapter]
	return {
		ChapterTitleKey = chapter and chapter.TitleKey,
		ChapterIntroKey = chapter and chapter.IntroKey,
		Stage = stage,
		StageName = stage and StoryContext.StageNames[stage] or nil,
		Recent = StoryContext.recent(data, 3),
	}
end

---------------------------------------------------------------------
-- «Mi historia»: el diario
---------------------------------------------------------------------

local chapterOrder: { string } = {}
for id in Chapters do
	table.insert(chapterOrder, id)
end
table.sort(chapterOrder, function(a, b)
	return Chapters[a].Order < Chapters[b].Order
end)

-- Personajes que salen en una misión (reparto de la ficha y con quién se habla)
local function questPeople(quest: { [string]: any }): { string }
	local list = {}
	for _, npc in quest.Npcs or {} do
		table.insert(list, npc)
	end
	local function scan(steps: { any }?)
		for _, step in steps or {} do
			if step.Type == "Talk" then
				table.insert(list, step.Npc)
			end
			scan(step.Steps)
		end
	end
	scan(quest.Steps)
	return list
end

function StoryContext.journal(data: { [string]: any }, attributes: { [string]: any }?): { [string]: any }
	local story = data.Story or {}
	local s = StoryState.of(data)

	-- Capítulos: los terminados y el de ahora, en orden de la vida
	local chapters = {}
	if story.PrologueDone or (story.Completed and story.Completed[StoryContext.PrologueId]) then
		table.insert(chapters, { Id = "Prologo", TitleKey = "JOURNAL.PROLOGUE.TITLE", IntroKey = "JOURNAL.PROLOGUE.INTRO", Done = true, Prologue = true })
	end
	for _, id in chapterOrder do
		local chapter = Chapters[id]
		local done = story.Chapters ~= nil and story.Chapters[id] ~= nil
		local current = story.Chapter == id and not done
		if done or current then
			table.insert(chapters, { Id = id, TitleKey = chapter.TitleKey, IntroKey = chapter.IntroKey, Done = done, Current = current })
		end
	end

	-- Personajes: los que recuerdan algo de ti y los principales de lo que has vivido
	local met: { [string]: boolean } = {}
	for npc in story.NpcMemory or {} do
		local id = castId(npc)
		if id and s.knows(npc) then
			met[id] = true
		end
	end
	for questId in story.Completed or {} do
		local quest = Quests[questId]
		if quest and s.completed(questId) then
			for _, npc in questPeople(quest) do
				local id = castId(npc)
				if id and StoryContext.Who[id] then
					met[id] = true
				end
			end
		end
	end
	local people = {}
	for id in met do
		local rel = s.rel(id)
		table.insert(people, {
			Id = id,
			Name = Cast.nameOf(id, attributes),
			Who = StoryContext.whoIs(id),
			Rel = rel,
			RelText = StoryContext.relationText(rel),
		})
	end
	table.sort(people, function(a, b)
		if a.Rel ~= b.Rel then
			return a.Rel > b.Rel
		end
		return a.Id < b.Id
	end)

	-- Recuerdos (con su icono) y decisiones importantes, de más nuevo a más antiguo
	local memories = {}
	for key, entry in story.Memories or {} do
		local memory = Memories[key]
		if memory then
			table.insert(memories, { Key = key, Icon = memory.Icon, Text = memory.Text, T = type(entry) == "table" and entry.T or 0 })
		end
	end
	table.sort(memories, function(a, b)
		if a.T ~= b.T then
			return a.T > b.T
		end
		return a.Key < b.Key
	end)
	local choices = {}
	local events = story.Events or {}
	for i = #events, 1, -1 do
		local event = events[i]
		if event.Y == "Choice" and type(event.K) == "string" then
			table.insert(choices, { Icon = "🔀", Key = event.K })
			if #choices >= 15 then
				break
			end
		end
	end

	return { Chapters = chapters, People = people, Memories = memories, Choices = choices, Stage = data.Life and data.Life.Stage }
end

return StoryContext
