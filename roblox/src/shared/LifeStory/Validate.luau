-- Validate (validador de misiones): revisa que los datos de la historia estén bien escritos y que
-- cada misión se pueda jugar de principio a fin:
--   * claves de texto, lugares (y su cadena de Fallback), misiones, capítulos y diálogos que existen;
--   * a quien hay que hablar está en la escena del paso o lo traen los sistemas de siempre
--     (compañeros y profes del colegio, la familia en casa);
--   * cada espera (Wait) tiene tope en minutos de juego Y en segundos reales (MaxSeconds);
--   * cada paso "Event" espera un evento que algún sistema emite de verdad (EventCatalog);
--   * cada decisión (Choice) tiene opciones que cierran la decisión, y las ramas (If con Choices)
--     preguntan por opciones que existen;
--   * recompensas válidas, siguiente capítulo/misión que existen, y ningún paso manda a un sitio de
--     otra etapa (un niño no va a dar clase a la universidad).
-- Validate.report() devuelve { Errors, Warnings, BadQuests }: el servidor NO activa una misión con
-- errores (BadQuests) y lo avisa en Output. Validate.run() = solo la lista de errores (pruebas).

local Chapters = require(script.Parent.Chapters)
local Quests = require(script.Parent.Quests)
local Locations = require(script.Parent.Locations)
local Stages = require(script.Parent.Stages)
local Strings = require(script.Parent.Strings)
local Roles = require(script.Parent.Parent.Roles)
local Cinematics = require(script.Parent.Cinematics)
local Emotion = require(script.Parent.Emotion)

-- Lo que puede estar haciendo un personaje en una escena (SceneService)
local ACTOR_MODES = {
	Idle = true, Sit = true, Wave = true, Cheer = true, Point = true, Dance = true, Laugh = true,
	Chat = true, Wander = true, Follow = true, Flee = true, Hunt = true,
}
local Config = require(script.Parent.Parent.Config)
local Subjects = require(script.Parent.Subjects)
local DayPlans = require(script.Parent.DayPlans)
local Cast = require(script.Parent.Cast)
local Memories = require(script.Parent.Memories)
local Items = require(script.Parent.Parent.Items)
local EventCatalog = require(script.Parent.EventCatalog)
local SchoolLife = require(script.Parent.SchoolLife)
local Schedules = require(script.Parent.Schedules)
local GameClock = require(script.Parent.Parent.GameClock)

local Validate = {}

-- Topes de las esperas
Validate.MaxWaitGameMinutes = 12 * 60 -- una espera no pasa de medio día de juego
Validate.MaxWaitSeconds = 600 -- ni de 10 minutos reales, pase lo que pase con el reloj

-- ¿Lo traen los sistemas de siempre (sin escena)? Compañeros y profes del colegio (SchoolService,
-- atributo StoryNpc) y la familia de casa (BabyService, marcas FamilySpot).
function Validate.ambientNpc(npc: any): boolean
	return type(npc) == "string" and (SchoolLife.livesAtSchool(npc) or npc:sub(1, 8) == "Familia_")
end

-- Qué colegio le toca a cada etapa (para las clases) y a qué sitios con horario no se manda a nadie
local CLASS_WINDOW = { Nino = "Colegio", Adolescente = "Instituto", AdultoJoven = "Universidad" }
local FORBIDDEN_WINDOW = {
	Bebe = { Colegio = true, Instituto = true, Universidad = true, Oficina = true },
	Nino = { Universidad = true, Oficina = true },
}

local STEP_TYPES = {
	Reach = { "Place" },
	Event = { "Event" },
	Talk = { "Npc" },
	Choice = { "Key", "Options" },
	Scene = { "Dialogue" },
	Use = { "Prop" },
	MiniGame = { "Game" },
	Chase = { "Npc" },
	Fight = { "Enemies" },
	Escape = {},
	Wait = { "GameMinutes" },
	Group = { "Steps" },
	Moment = {},
	Transition = {},
	Cinematic = { "Id" },
	Class = { "Subject", "Mode", "Place" },
}
local function isRef(value: any): boolean
	return type(value) == "string" and value:sub(1, 9) == "$Carrera."
end
local GROUP_CHILD = { Reach = true, Event = true, Talk = true, Use = true }
local NO_TEXT = { Moment = true, Transition = true, Cinematic = true, Scene = true, MiniGame = true }
local MINIGAMES = { Timing = true, Futbol = true }
local PROP_KINDS = {
	Mochila = true, Libro = true, Papel = true, Pegatina = true, Huella = true, Llavero = true, Envoltorio = true,
	Balon = true, Armario = true, Espejo = true, Desayuno = true, Almohada = true, Perchero = true, Papelera = true,
	Asiento = true, Canasta = true, Kiosco = true, Banco = true, Escarabajo = true, Mural = true, Gato = true,
	Autobus = true, Caja = true, Marcador = true, Animal = true, Trofeo = true,
	Nave = true, Portal = true, Maquina = true, Huevo = true, Cristal = true, Cohete = true, Moco = true, Pantalla = true,
}
local TRAITS = { Humor = true, Empatia = true, Valentia = true, Responsabilidad = true, Curiosidad = true, Deportividad = true, Creatividad = true, Rebeldia = true }
local EFFECTS = {
	Flags = true, Unflags = true, Rel = true, Traits = true, Memory = true, Remember = true, Items = true, Take = true,
	Needs = true, Money = true, Spend = true, Choice = true, Gesture = true, Say = true, Later = true, After = true,
	OnlyIfUntouched = true, Degree = true, SetStage = true, Teleport = true, Conduct = true,
}
-- Una clave de texto es MAYÚSCULAS.CON.PUNTOS; cualquier otra cosa es un texto ya escrito
local function isKey(value: string): boolean
	return value:match("^[%u%d_]+%.[%u%d_%.]+$") ~= nil
end

-- Revisa una misión episódica: diálogos, objetos, actores y a quién se habla en cada paso
-- (extraSteps: los pasos de los días generados de una misión con DayPlan, que no están en quest.Steps)
function Validate.mission(id: string, quest: { [string]: any }, err: (string, ...any) -> (), helpers: { [string]: any }, extraSteps: { { [string]: any } }?)
	local dialogues = quest.Dialogues or {}
	local props = quest.Props or {}
	local function dialogue(where: string, name: any)
		if type(name) == "string" and not dialogues[name] then
			err("%s: diálogo inexistente '%s'", where, name)
		end
	end
	local function actor(where: string, spec: { [string]: any })
		if not Cast.People[spec.Npc] then
			err("%s: actor que no está en el reparto '%s'", where, tostring(spec.Npc))
		end
		if spec.Mode ~= "Follow" then
			helpers.place(where, spec.Place or "CercaDeTi")
		end
		if spec.Mode ~= nil and not ACTOR_MODES[spec.Mode] then
			err("%s: modo de actor desconocido '%s'", where, tostring(spec.Mode))
		end
		for _, stop in spec.Route or {} do
			helpers.place(where .. ".Route", if type(stop) == "table" then stop.Place else stop)
		end
		dialogue(where, spec.Talk)
		helpers.requirements(where, spec.If)
	end
	local function prop(where: string, propId: string?)
		if propId and not props[propId] then
			err("%s: objeto inexistente '%s'", where, propId)
		end
	end
	for name, d in dialogues do
		helpers.lines(id .. ".dlg." .. name, d.Lines)
		helpers.effects(id .. ".dlg." .. name, d.Effects)
	end
	for propId, def in props do
		local where = id .. ".prop." .. propId
		if not PROP_KINDS[def.Kind or "Marcador"] then
			err("%s: tipo de objeto desconocido '%s'", where, tostring(def.Kind))
		end
		helpers.place(where, def.Place)
		dialogue(where, def.Dialogue)
		helpers.effects(where, def.Effects)
	end
	for i, spec in quest.Actors or {} do
		actor(id .. ".actor" .. i, spec)
	end
	local function checkStep(where: string, s: { [string]: any })
		for i, spec in s.Actors or {} do
			actor(where .. ".actor" .. i, spec)
		end
		for _, propId in s.Props or {} do
			prop(where, propId)
		end
		dialogue(where, s.Dialogue)
		if s.Type == "Use" then
			prop(where, s.Prop)
		elseif (s.Type == "Talk" or s.Type == "Chase") and not Cast.People[s.Npc] then
			err("%s: hablar con alguien que no está en el reparto '%s'", where, tostring(s.Npc))
		elseif s.Type == "Choice" then
			for _, option in s.Options or {} do
				prop(where, option.Prop)
				dialogue(where, option.Dialogue)
				if option.Npc and not Cast.People[option.Npc] then
					err("%s: opción con alguien que no está en el reparto '%s'", where, option.Npc)
				end
			end
		elseif s.Type == "Group" then
			for i, child in s.Steps do
				checkStep(where .. ".g" .. i, child)
			end
		elseif s.Type == "Fight" then
			if #(s.Enemies or {}) == 0 then
				err("%s: un combate necesita enemigos", where)
			end
			for i, enemy in s.Enemies or {} do
				actor(where .. ".enemy" .. i, { Npc = enemy.Npc, Place = enemy.Place or s.Place, Mode = enemy.Mode or "Hunt" })
			end
			if s.Respawn then
				helpers.place(where .. ".Respawn", if type(s.Respawn) == "table" then s.Respawn.Place else s.Respawn)
			end
		elseif s.Type == "Escape" then
			if not s.Place and not s.Seconds then
				err("%s: una huida necesita Place (a dónde huir) o Seconds (cuánto aguantar)", where)
			end
			if s.Respawn then
				helpers.place(where .. ".Respawn", if type(s.Respawn) == "table" then s.Respawn.Place else s.Respawn)
			end
		end
	end
	for i, s in quest.Steps do
		checkStep(id .. ".s" .. i, s)
	end
	for i, s in extraSteps or {} do
		checkStep(id .. ".dia.s" .. i, s)
	end
end

-- Descripción de cada misión: una frase sencilla (quién te lo pide y por qué) que el jugador ve en la
-- oferta, al empezar y en el diario. Devuelve los problemas ("Cole01: falta la descripción…").
Validate.MinDescription = 12 -- caracteres como mínimo (algo más que "Ayuda")
function Validate.descriptionProblems(quests: { [string]: { [string]: any } }): { string }
	local problems = {}
	for id, quest in quests do
		local text = quest.Description
		local trimmed = if type(text) == "string" then text:match("^%s*(.-)%s*$") else nil
		if not trimmed or trimmed == "" then
			table.insert(problems, ("%s: falta la descripción (Description: quién te lo pide y por qué)"):format(id))
		elseif isKey(trimmed) and not Strings.has(trimmed) then
			table.insert(problems, ("%s: la descripción es una clave que no existe '%s'"):format(id, trimmed))
		elseif (utf8.len(trimmed) or #trimmed) < Validate.MinDescription then
			table.insert(problems, ("%s: descripción demasiado corta ('%s'): di quién te lo pide y por qué"):format(id, trimmed))
		end
	end
	table.sort(problems)
	return problems
end

export type Report = { Errors: { string }, Warnings: { string }, BadQuests: { [string]: boolean } }

local cachedReport: Report? = nil

function Validate.report(): Report
	local errors = {}
	local warnings = {}
	local badQuests: { [string]: boolean } = {}
	local currentQuest: string? = nil -- misión que se está revisando (sus errores la invalidan)
	local seen = {}
	local function err(fmt: string, ...)
		local message = fmt:format(...)
		if currentQuest then
			badQuests[currentQuest] = true
		end
		-- Los días generados repiten los mismos textos: cada problema se cuenta una vez
		local key = message:gsub("%.dia%d+", "")
		if not seen[key] then
			seen[key] = true
			table.insert(errors, key)
		end
	end
	local function warnf(fmt: string, ...)
		local key = fmt:format(...):gsub("%.dia%d+", "")
		if not seen[key] then
			seen[key] = true
			table.insert(warnings, key)
		end
	end
	-- Decisiones: qué valores puede tener cada Choices[Clave] y quién pregunta por ellos
	local choiceValues: { [string]: { [string]: boolean } } = {}
	local choiceAsked: { { Where: string, Key: string, Value: any, Quest: string? } } = {}
	local function produces(key: any, value: any)
		if type(key) == "string" then
			choiceValues[key] = choiceValues[key] or {}
			choiceValues[key][tostring(value)] = true
		end
	end
	local function text(where: string, key: string?)
		if key and isKey(key) and not Strings.has(key) then
			err("%s: falta el texto '%s'", where, key)
		end
	end
	local function requirements(where: string, req: { [string]: any }?)
		if not req then
			return
		end
		if req.Stage then
			for _, s in { req.Stage.Min, req.Stage.Max } do
				if s and not Stages.isValid(s) then
					err("%s: etapa desconocida '%s'", where, s)
				end
			end
		end
		for _, list in { req.Completed or {}, req.NotCompleted or {} } do
			for _, id in list do
				if not Quests[id] then
					err("%s: requiere una misión que no existe '%s'", where, id)
				end
			end
		end
		for _, map in { req.Choices or {}, req.NotChoices or {} } do
			for key, value in map do
				table.insert(choiceAsked, { Where = where, Key = key, Value = value, Quest = currentQuest })
			end
		end
		if req.Hours and not (type(req.Hours.From) == "number" and type(req.Hours.To) == "number") then
			err("%s: Hours necesita From y To", where)
		end
		for npc in req.Rel or {} do
			if not Cast.People[npc] then
				err("%s: relación con un personaje que no existe '%s'", where, npc)
			end
		end
		for trait in req.Traits or {} do
			if not TRAITS[trait] then
				err("%s: rasgo desconocido '%s'", where, trait)
			end
		end
		for _, key in req.Memories or {} do
			if not Memories[key] then
				err("%s: recuerdo desconocido '%s'", where, key)
			end
		end
	end
	local startedLater: { [string]: boolean } = {}
	local function effects(where: string, e: { [string]: any }?)
		if type(e) ~= "table" then
			return
		end
		for key in e do
			if not EFFECTS[key] then
				err("%s: efecto desconocido '%s'", where, tostring(key))
			end
		end
		for npc in e.Rel or {} do
			if not Cast.People[npc] then
				err("%s: relación con un personaje que no existe '%s'", where, npc)
			end
		end
		for trait in e.Traits or {} do
			if not TRAITS[trait] then
				err("%s: rasgo desconocido '%s'", where, trait)
			end
		end
		for key, value in e.Choice or {} do
			produces(key, value)
		end
		for _, field in { "Money", "Spend" } do
			if e[field] ~= nil and (type(e[field]) ~= "number" or e[field] < 0 or e[field] ~= e[field]) then
				err("%s: %s debe ser un número positivo", where, field)
			end
		end
		if e.SetStage ~= nil and not Stages.isValid(e.SetStage) then
			err("%s: etapa desconocida '%s'", where, tostring(e.SetStage))
		end
		for _, key in (if type(e.Memory) == "table" then e.Memory else { e.Memory }) do
			if not Memories[key] then
				err("%s: recuerdo desconocido '%s'", where, tostring(key))
			end
		end
		for _, list in { e.Items or {}, e.Take or {} } do
			for id in list do
				if not Items.get(id) then
					err("%s: objeto de mochila desconocido '%s'", where, id)
				end
			end
		end
		for _, later in e.Later or {} do
			if later.Start then
				startedLater[later.Start] = true
				if not Quests[later.Start] then
					err("%s: Later.Start de una misión que no existe '%s'", where, later.Start)
				end
			end
			if not (later.AfterHours or later.AfterMinutes) then
				err("%s: Later necesita AfterHours o AfterMinutes", where)
			end
		end
	end
	local function checkPlace(where: string, id: any)
		if not isRef(id) and not Locations.Places[id] then
			err("%s: lugar desconocido '%s'", where, tostring(id))
		end
	end
	-- Diálogos: quién habla, preguntas con opciones, ramas
	local function lines(where: string, list: { any }?)
		for i, line in list or {} do
			local w = where .. ".l" .. i
			if line.S and line.S ~= "Yo" and line.S ~= "Narrador" and not Cast.People[line.S] then
				err("%s: habla alguien que no está en el reparto '%s'", w, tostring(line.S))
			end
			if line.A ~= nil and not Emotion.valid(line.A) then
				err("%s: gesto desconocido A = '%s'", w, tostring(line.A))
			end
			if line.G ~= nil and not Emotion.valid(line.G) then
				err("%s: gesto desconocido G = '%s' (mal escrito: no se haría)", w, tostring(line.G))
			end
			if type(line.T) == "string" then
				text(w, line.T)
			end
			if line.Ask then
				if not line.Options or #line.Options == 0 then
					err("%s: pregunta sin opciones", w)
				end
				for j, option in line.Options or {} do
					if not option.T then
						err("%s.o%d: opción sin texto", w, j)
					end
					effects(w .. ".o" .. j, option.Effects)
					requirements(w .. ".o" .. j, option.If)
					lines(w .. ".o" .. j, option.Then)
				end
			elseif not line.T and not line.Effects then
				err("%s: línea sin texto", w)
			end
			effects(w, line.Effects)
			requirements(w, line.If)
		end
	end
	-- Misión que se revisa ahora: sus actores y en qué etapas se juega
	local questDef: { [string]: any } = {}
	local questStages: { string } = {}
	local function hasActor(list: { { [string]: any } }?, npc: any): (boolean, boolean)
		for _, spec in list or {} do
			if spec.Npc == npc then
				return true, spec.If ~= nil
			end
		end
		return false, false
	end
	local function step(where: string, s: { [string]: any }, inGroup: boolean, groupActors: { { [string]: any } }?, parentIf: any?)
		local fields = STEP_TYPES[s.Type]
		if not fields then
			err("%s: tipo de paso desconocido '%s'", where, tostring(s.Type))
			return
		end
		if inGroup and not GROUP_CHILD[s.Type] then
			err("%s: un Group solo admite Reach, Event, Talk o Use", where)
		end
		for _, field in fields do
			if s[field] == nil then
				err("%s: al paso %s le falta '%s'", where, s.Type, field)
			end
		end
		text(where, s.TextKey)
		text(where, s.TextHere)
		if s.TextHere ~= nil and s.Type ~= "Reach" then
			err("%s: TextHere solo sirve en pasos Reach", where)
		end
		if not NO_TEXT[s.Type] and not s.TextKey and not s.Text then
			err("%s: el paso %s necesita Text o TextKey", where, s.Type)
		end
		if s.Type == "Reach" or s.Place ~= nil then
			checkPlace(where, s.Place)
		end
		if s.Type == "MiniGame" and not MINIGAMES[s.Game] then
			err("%s: minijuego desconocido '%s'", where, tostring(s.Game))
		end
		effects(where, s.Effects)
		effects(where .. ".Late", s.Late)
		effects(where .. ".Timeout", s.Timeout)
		effects(where .. ".Win", s.Win)
		effects(where .. ".Lose", s.Lose)
		effects(where .. ".Draw", s.Draw)
		if s.Nudge and not (s.Nudge.After and s.Nudge.T) then
			err("%s: Nudge necesita After y T", where)
		end
		if s.Teleport then
			checkPlace(where .. ".Teleport", if type(s.Teleport) == "table" then s.Teleport.Place else s.Teleport)
		end
		if s.Type == "Class" then
			if not isRef(s.Subject) and not Subjects.List[s.Subject] then
				err("%s: asignatura desconocida '%s'", where, tostring(s.Subject))
			end
			if not Subjects.Modes[s.Mode] then
				err("%s: modo de clase desconocido '%s'", where, tostring(s.Mode))
			end
		end
		if s.Type == "Cinematic" and not Cinematics[s.Id] then
			err("%s: cinemática desconocida '%s'", where, tostring(s.Id))
		end
		if s.Cinematic and not Cinematics[s.Cinematic] then
			err("%s: cinemática desconocida '%s'", where, tostring(s.Cinematic))
		end
		if s.Type == "Choice" then
			text(where, s.PromptKey)
			for _, option in s.Options or {} do
				text(where, option.TextKey)
				if not (option.Text or option.TextKey) then
					err("%s: opción '%s' sin texto", where, tostring(option.Id))
				end
				effects(where .. "." .. tostring(option.Id), option.Effects)
			end
		end
		if s.Type == "Group" then
			for i, child in s.Steps do
				step(where .. ".g" .. i, child, true, s.Actors, s.If)
			end
			if s.Need ~= nil and (type(s.Need) ~= "number" or s.Need < 1 or s.Need > #s.Steps) then
				err("%s: Need fuera de rango (1-%d)", where, #s.Steps)
			end
		end
		if s.SetStage and not Stages.isValid(s.SetStage) then
			err("%s: etapa desconocida '%s'", where, s.SetStage)
		end
		requirements(where .. ".If", s.If)

		-- ¿Está la persona con la que hay que hablar? (en la escena del paso, en la de la misión o la
		-- traen los sistemas de siempre). Si no, con diálogo hay plan B (se habla igual a los 15 s);
		-- sin diálogo, el paso no se podría cumplir.
		if s.Type == "Talk" or s.Type == "Chase" then
			local inStep, conditional = hasActor(s.Actors, s.Npc)
			if not inStep then
				inStep, conditional = hasActor(groupActors, s.Npc)
			end
			if not inStep then
				inStep, conditional = hasActor(questDef.Actors, s.Npc)
			end
			if s.Type == "Talk" and not inStep and not Validate.ambientNpc(s.Npc) then
				if s.Dialogue then
					warnf("%s: %s no está en la escena (se hablará con el plan B)", where, tostring(s.Npc))
				else
					err("%s: nadie trae a %s (ni la escena ni el colegio ni la familia)", where, tostring(s.Npc))
				end
			elseif conditional and not s.If and not parentIf then
				warnf("%s: %s solo está en la escena con una condición", where, tostring(s.Npc))
			end
		end
		-- Esperas: siempre con tope (de juego y real)
		if s.Type == "Wait" then
			if type(s.GameMinutes) ~= "number" or s.GameMinutes <= 0 or s.GameMinutes > Validate.MaxWaitGameMinutes then
				err("%s: Wait con GameMinutes fuera de rango (1-%d)", where, Validate.MaxWaitGameMinutes)
			end
			if type(s.MaxSeconds) ~= "number" or s.MaxSeconds <= 0 or s.MaxSeconds > Validate.MaxWaitSeconds then
				err("%s: Wait sin tope de tiempo real (MaxSeconds, como mucho %d s)", where, Validate.MaxWaitSeconds)
			end
		end
		-- Eventos que alguien emite de verdad
		if s.Type == "Event" and not EventCatalog.has(s.Event) then
			err("%s: nadie emite el evento '%s' (EventCatalog)", where, tostring(s.Event))
		end
		if s.Type == "Event" and s.Count ~= nil and (type(s.Count) ~= "number" or s.Count < 1) then
			err("%s: Count debe ser 1 o más", where)
		end
		-- Decisiones: Ids únicos, alguna opción cierra la decisión sin condiciones
		if s.Type == "Choice" then
			local ids = {}
			local closes = false
			for _, option in s.Options or {} do
				if option.Id == nil then
					err("%s: opción sin Id", where)
				elseif ids[option.Id] then
					err("%s: opción repetida '%s'", where, tostring(option.Id))
				end
				ids[option.Id or "?"] = true
				produces(s.Key, option.Id)
				closes = closes or (not option.Stay and not option.If)
			end
			if #(s.Options or {}) == 0 then
				err("%s: decisión sin opciones", where)
			elseif not closes then
				err("%s: ninguna opción cierra la decisión sin condiciones (podría quedarse sin salida)", where)
			end
		end
		-- Sitios de otra etapa
		local placeId = if isRef(s.Place) then nil else s.Place
		local window = placeId and Schedules.forPlace(placeId)
		if window and (s.Type == "Reach" or s.Type == "Class") then
			for _, stage in questStages do
				if FORBIDDEN_WINDOW[stage] and FORBIDDEN_WINDOW[stage][window.Id] then
					err("%s: manda a %s (%s) en la etapa %s", where, tostring(placeId), window.Name, stage)
				end
			end
		end
		if s.Type == "Class" and s.Mode ~= "Estudio" and window and #questStages == 1 then
			local expected = CLASS_WINDOW[questStages[1]]
			if expected and window.Id ~= expected then
				err("%s: clase en %s, pero en la etapa %s toca %s", where, window.Name, questStages[1], expected)
			end
		end
	end

	-- En qué etapas se juega cada misión (su capítulo o su Requires.Stage)
	local questChapter: { [string]: string } = {}
	for id, chapter in Chapters do
		for _, questId in chapter.Main do
			if questChapter[questId] and questChapter[questId] ~= id then
				err("misión %s: está en dos capítulos (%s y %s)", questId, questChapter[questId], id)
			end
			questChapter[questId] = id
		end
		if chapter.Loop then
			questChapter[chapter.Loop] = questChapter[chapter.Loop] or id
		end
	end
	local function stagesOf(questId: string, quest: { [string]: any }): { string }
		local range = (quest.Requires and quest.Requires.Stage)
			or (questChapter[questId] and Chapters[questChapter[questId]].Stage)
		local list = {}
		if not range then
			return list
		end
		for _, stage in Stages.Order or {} do
			if Stages.inRange(stage, range.Min, range.Max) then
				table.insert(list, stage)
			end
		end
		return list
	end

	for id, quest in Quests do
		currentQuest = id
		questDef = quest
		questStages = stagesOf(id, quest)
		text(id, quest.TitleKey)
		text(id, quest.MomentKey)
		requirements(id, quest.Requires)
		-- Lo que viene después (datos de diseño de las misiones episódicas)
		for _, nextId in quest.Next or {} do
			if not Quests[nextId] then
				err("%s: Next con una misión que no existe '%s'", id, tostring(nextId))
			end
		end
		if quest.Chapter and not Chapters[quest.Chapter] then
			err("%s: capítulo desconocido '%s'", id, tostring(quest.Chapter))
		end
		-- ¿Hay alguna hora en la que se pueda empezar? (pide la noche pero el sitio cierra de noche…)
		local hours = quest.Requires and quest.Requires.Hours
		local window = Schedules.forQuest(quest)
		if hours and window and type(hours.From) == "number" and type(hours.To) == "number" then
			local possible = false
			for quarter = 0, 95 do
				local t = quarter / 4
				if GameClock.isBetween(hours.From, hours.To, t) and Schedules.isOpen(window, t) then
					possible = true
					break
				end
			end
			if not possible then
				err("%s: nunca puede empezar: pide de %s a %s h y %s solo abre de %s a %s (¿Schedule = false?)", id, tostring(hours.From), tostring(hours.To), window.Name, tostring(window.From), tostring(window.To))
			end
		end
		if quest.Kind == "Main" and not questChapter[id] and not quest.Canon and not quest.Prologue then
			warnf("%s: principal que no está en ningún capítulo (nadie la empieza)", id)
		end
		if quest.Kind == "Main" and quest.Chapter and questChapter[id] and questChapter[id] ~= quest.Chapter then
			err("%s: dice ser del capítulo %s pero está en %s", id, quest.Chapter, questChapter[id])
		end
		if quest.Kind == "Side" then
			if quest.Offer and quest.Offer.Place and not Locations.Places[quest.Offer.Place] then
				err("%s: Offer con lugar desconocido '%s'", id, quest.Offer.Place)
			end
			text(id, quest.OfferKey)
		elseif quest.Kind ~= "Main" then
			err("%s: Kind debe ser Main o Side", id)
		end
		local generated: { { [string]: any } } = {}
		if quest.DayPlan then
			if not DayPlans.Plans[quest.DayPlan] then
				err("%s: DayPlan desconocido '%s'", id, quest.DayPlan)
			else
				-- Se generan muchos días de prueba y se revisa cada paso
				local rng = Random.new(1)
				for day = 1, 150 do
					local plan = DayPlans.generate(quest.DayPlan, rng)
					if plan then
						text(id .. ".dia" .. day, plan.TitleKey)
						for i, s in plan.Steps do
							step(id .. ".dia" .. day .. ".s" .. i, s, false)
							table.insert(generated, s)
						end
					end
				end
			end
		elseif #quest.Steps == 0 then
			err("%s: no tiene pasos", id)
		end
		for i, s in quest.Steps do
			step(id .. ".s" .. i, s, false)
		end
		if quest.Rewards and quest.Rewards.SetStage and not Stages.isValid(quest.Rewards.SetStage) then
			err("%s: SetStage desconocida", id)
		end
		effects(id .. ".Rewards", quest.Rewards)
		if quest.Memory and not Memories[quest.Memory] then
			err("%s: recuerdo desconocido '%s'", id, quest.Memory)
		end
		if quest.Dialogues or quest.Props or quest.Actors or #generated > 0 then
			Validate.mission(id, quest, err, {
				place = checkPlace,
				lines = lines,
				effects = effects,
				requirements = requirements,
			}, generated)
		end
		currentQuest = nil
	end
	for id, quest in Quests do
		if quest.Kind == "Side" and not quest.Offer and not startedLater[id] then
			err("%s: secundaria sin Offer que nadie lanza (Later.Start)", id)
		end
		if quest.Kind == "Side" and quest.Offer and quest.Offer.Event and not EventCatalog.has(quest.Offer.Event) then
			currentQuest = id
			err("%s: Offer con un evento que nadie emite '%s'", id, tostring(quest.Offer.Event))
			currentQuest = nil
		end
	end
	-- Cada misión dice quién te la pide y por qué (Description). Es un error, pero no impide activarla:
	-- sin contexto el jugador no entiende la historia, aunque la misión se pueda jugar.
	for _, problem in Validate.descriptionProblems(Quests) do
		err("%s", problem)
	end
	-- Ramas: un If que pregunta por una respuesta que ninguna decisión puede dar nunca se cumple
	for _, asked in choiceAsked do
		local values = choiceValues[asked.Key]
		if values and not values[tostring(asked.Value)] then
			currentQuest = asked.Quest
			err("%s: pregunta por %s = '%s', pero esa decisión no tiene esa opción", asked.Where, asked.Key, tostring(asked.Value))
			currentQuest = nil
		elseif not values then
			warnf("%s: pregunta por la decisión %s, que ninguna misión toma", asked.Where, asked.Key)
		end
	end

	for id, chapter in Chapters do
		if chapter.Id ~= id then
			err("capítulo %s: Id no coincide", id)
		end
		text(id, chapter.TitleKey)
		text(id, chapter.IntroKey)
		text(id, chapter.OutroKey)
		requirements(id, { Stage = chapter.Stage })
		for _, questId in chapter.Main do
			local quest = Quests[questId]
			if not quest then
				err("capítulo %s: misión inexistente '%s'", id, questId)
			elseif quest.Kind ~= "Main" then
				err("capítulo %s: '%s' no es Main", id, questId)
			end
		end
		if chapter.Loop and not (Quests[chapter.Loop] and Quests[chapter.Loop].DayPlan) then
			err("capítulo %s: Loop debe ser una misión con DayPlan ('%s')", id, chapter.Loop)
		end
		for _, field in { "IntroCinematic", "OutroCinematic" } do
			if chapter[field] and not Cinematics[chapter[field]] then
				err("capítulo %s: %s desconocida '%s'", id, field, chapter[field])
			end
		end
		if chapter.Music and not Config.Audio.Music[chapter.Music] then
			err("capítulo %s: música desconocida '%s'", id, chapter.Music)
		end
		if chapter.Next and not Chapters[chapter.Next] then
			err("capítulo %s: Next inexistente '%s'", id, chapter.Next)
		end
	end

	for id, place in Locations.Places do
		text("lugar " .. id, place.NameKey)
		if not (place.Model or place.Tag or place.Special or place.Between) then
			err("lugar %s: necesita Model, Tag, Special o Between", id)
		end
		for _, other in { place.Fallback, place.Between and place.Between[1], place.Between and place.Between[2] } do
			if other and not Locations.Places[other] then
				err("lugar %s: hace referencia a un lugar que no existe '%s'", id, other)
			end
		end
		if place.Child and not place.Model then
			err("lugar %s: Child necesita Model", id)
		end
		-- La cadena de planes B termina (sin vueltas)
		local visited = { [id] = true }
		local current = place.Fallback
		while current do
			if visited[current] then
				err("lugar %s: la cadena de Fallback da la vuelta en '%s'", id, current)
				break
			end
			visited[current] = true
			current = Locations.Places[current] and Locations.Places[current].Fallback
		end
	end

	for id, cine in Cinematics do
		local where = "cinemática " .. id
		if type(cine.Duration) ~= "number" or cine.Duration <= 0 then
			err("%s: falta Duration", where)
		end
		for name, anchor in cine.Anchors or {} do
			local kind, value = anchor:match("^(%a+):(.+)$")
			if anchor ~= "Player" and not (kind == "Place" and Locations.Places[value]) and not (kind == "Zone" and table.find(Locations.Zones, value)) and not (kind == "Actor" and Cast.People[value]) then
				err("%s: ancla %s no válida '%s'", where, name, anchor)
			end
		end
		local function point(p: any)
			if p and not (cine.Anchors or {})[p[1]] then
				err("%s: plano con ancla sin definir '%s'", where, tostring(p[1]))
			end
		end
		for _, shot in cine.Shots or {} do
			if shot.Orbit then
				point({ shot.Orbit })
			else
				point(shot.From)
				point(shot.To)
				point(shot.Look)
				point(shot.LookTo)
			end
		end
		for _, line in cine.Lines or {} do
			text(where, line.TextKey)
			if line.A ~= nil and not Emotion.valid(line.A) then
				err("%s: gesto desconocido A = '%s'", where, tostring(line.A))
			end
		end
		for _, anim in cine.Anims or {} do
			if not Emotion.Animated[anim.Play] then
				err("%s: gesto de animación desconocido '%s'", where, tostring(anim.Play))
			end
			if type(anim.At) ~= "number" or anim.At < 0 or anim.At > (cine.Duration or 0) then
				err("%s: gesto %s fuera de la escena (At)", where, tostring(anim.Play))
			end
			if anim.Who ~= "Player" and anim.Who ~= "Todos" and not Cast.People[anim.Who] then
				err("%s: gesto de alguien que no está en el reparto '%s'", where, tostring(anim.Who))
			end
		end
		local total = 0
		for _, shot in cine.Shots or {} do
			total += shot.Duration or 0
			if shot.Shake ~= nil and (type(shot.Shake) ~= "number" or shot.Shake < 0 or shot.Shake > 2) then
				err("%s: Shake debe ser un número entre 0 y 2", where)
			end
			local fov = shot.Fov
			if fov ~= nil then
				local list = if type(fov) == "table" then fov else { fov }
				for _, f in list do
					if type(f) ~= "number" or f < 10 or f > 110 then
						err("%s: Fov fuera de rango (10-110)", where)
					end
				end
			end
		end
		if total + 0.01 < (cine.Duration or 0) - 1.5 then
			err("%s: los planos duran %.1f s pero la escena %.1f s (la cámara se quedaría quieta)", where, total, cine.Duration)
		end
		for _, title in cine.Titles or {} do
			text(where, title.TextKey)
			text(where, title.SubKey)
		end
		if cine.Music and not Config.Audio.Music[cine.Music] then
			err("%s: música desconocida '%s'", where, cine.Music)
		end
		if cine.Sting and not Config.Audio.Stings[cine.Sting] then
			err("%s: efecto desconocido '%s'", where, cine.Sting)
		end
	end

	-- Lo que recuerdan los del colegio (SchoolLife.Callbacks): personajes y condiciones que existen
	for i, entry in SchoolLife.Callbacks or {} do
		local where = "recuerdo del colegio " .. i
		if not Cast.People[entry.Npc] then
			err("%s: personaje que no está en el reparto '%s'", where, tostring(entry.Npc))
		end
		if type(entry.T) ~= "string" or entry.T == "" then
			err("%s: sin texto", where)
		end
		requirements(where, entry.If)
	end

	for id, subject in Subjects.List do
		text("asignatura " .. id, subject.NameKey)
		text("asignatura " .. id, subject.Teacher)
	end
	for id, mode in Subjects.Modes do
		text("modo " .. id, mode.NameKey)
	end
	for id, degree in Subjects.Degrees do
		text("carrera " .. id, degree.NameKey)
		for _, field in { "Facultad", "LugarPracticas" } do
			if not Locations.Places[degree[field]] then
				err("carrera %s: lugar desconocido '%s'", id, tostring(degree[field]))
			end
		end
		for _, field in { "Asignatura1", "Asignatura2", "Practica", "Fisico" } do
			if not Subjects.List[degree[field]] then
				err("carrera %s: asignatura desconocida '%s'", id, tostring(degree[field]))
			end
		end
	end
	for _, grade in { 10, 8, 6.5, 5, 2 } do
		text("nota", Subjects.gradeKey(grade))
	end

	for id, role in Roles do
		text("rol " .. id, role.NameKey)
	end

	table.sort(errors)
	table.sort(warnings)
	cachedReport = { Errors = errors, Warnings = warnings, BadQuests = badQuests }
	return cachedReport :: Report
end

-- El último informe (o uno nuevo): lo usa el servidor para no activar misiones rotas
function Validate.cached(): Report
	return cachedReport or Validate.report()
end

-- ¿Se puede activar esta misión? (sin errores en el validador)
function Validate.questOk(questId: string): boolean
	return not Validate.cached().BadQuests[questId]
end

function Validate.run(): { string }
	return Validate.report().Errors
end

return Validate
