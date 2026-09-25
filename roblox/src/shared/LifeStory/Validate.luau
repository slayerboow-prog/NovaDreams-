-- Validate: revisa que los datos de la historia estén bien escritos (claves de texto que existen,
-- lugares que existen, misiones que existen, pasos con el tipo correcto...).
-- El servidor lo ejecuta al arrancar y avisa en Output; también se usa en las pruebas automáticas.

local Chapters = require(script.Parent.Chapters)
local Quests = require(script.Parent.Quests)
local Locations = require(script.Parent.Locations)
local Stages = require(script.Parent.Stages)
local Strings = require(script.Parent.Strings)
local Roles = require(script.Parent.Parent.Roles)
local Cinematics = require(script.Parent.Cinematics)
local Config = require(script.Parent.Parent.Config)
local Subjects = require(script.Parent.Subjects)
local DayPlans = require(script.Parent.DayPlans)
local Cast = require(script.Parent.Cast)
local Memories = require(script.Parent.Memories)
local Items = require(script.Parent.Parent.Items)

local Validate = {}

local STEP_TYPES = {
	Reach = { "Place" },
	Event = { "Event" },
	Talk = { "Npc" },
	Choice = { "Key", "Options" },
	Scene = { "Dialogue" },
	Use = { "Prop" },
	MiniGame = { "Game" },
	Chase = { "Npc" },
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
}
local TRAITS = { Humor = true, Empatia = true, Valentia = true, Responsabilidad = true, Curiosidad = true, Deportividad = true, Creatividad = true }
local EFFECTS = {
	Flags = true, Unflags = true, Rel = true, Traits = true, Memory = true, Remember = true, Items = true, Take = true,
	Needs = true, Money = true, Spend = true, Choice = true, Gesture = true, Say = true, Later = true, After = true,
	OnlyIfUntouched = true, Degree = true, SetStage = true, Teleport = true,
}
-- Una clave de texto es MAYÚSCULAS.CON.PUNTOS; cualquier otra cosa es un texto ya escrito
local function isKey(value: string): boolean
	return value:match("^[%u%d_]+%.[%u%d_%.]+$") ~= nil
end

-- Revisa una misión episódica: diálogos, objetos, actores y a quién se habla en cada paso
function Validate.mission(id: string, quest: { [string]: any }, err: (string, ...any) -> (), helpers: { [string]: any })
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
		end
	end
	for i, s in quest.Steps do
		checkStep(id .. ".s" .. i, s)
	end
end

function Validate.run(): { string }
	local errors = {}
	local seen = {}
	local function err(fmt: string, ...)
		local message = fmt:format(...)
		-- Los días generados repiten los mismos textos: cada problema se cuenta una vez
		local key = message:gsub("%.dia%d+", "")
		if not seen[key] then
			seen[key] = true
			table.insert(errors, key)
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
		for _, id in req.Completed or {} do
			if not Quests[id] then
				err("%s: requiere una misión que no existe '%s'", where, id)
			end
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
	local function step(where: string, s: { [string]: any }, inGroup: boolean)
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
				step(where .. ".g" .. i, child, true)
			end
		end
		if s.SetStage and not Stages.isValid(s.SetStage) then
			err("%s: etapa desconocida '%s'", where, s.SetStage)
		end
		requirements(where .. ".If", s.If)
	end

	for id, quest in Quests do
		text(id, quest.TitleKey)
		text(id, quest.MomentKey)
		requirements(id, quest.Requires)
		if quest.Kind == "Side" then
			if quest.Offer and quest.Offer.Place and not Locations.Places[quest.Offer.Place] then
				err("%s: Offer con lugar desconocido '%s'", id, quest.Offer.Place)
			end
			text(id, quest.OfferKey)
		elseif quest.Kind ~= "Main" then
			err("%s: Kind debe ser Main o Side", id)
		end
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
		if quest.Dialogues or quest.Props or quest.Actors then
			Validate.mission(id, quest, err, {
				place = checkPlace,
				lines = lines,
				effects = effects,
				requirements = requirements,
			})
		end
	end
	for id, quest in Quests do
		if quest.Kind == "Side" and not quest.Offer and not startedLater[id] then
			err("%s: secundaria sin Offer que nadie lanza (Later.Start)", id)
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
	end

	for id, cine in Cinematics do
		local where = "cinemática " .. id
		if type(cine.Duration) ~= "number" or cine.Duration <= 0 then
			err("%s: falta Duration", where)
		end
		for name, anchor in cine.Anchors or {} do
			local kind, value = anchor:match("^(%a+):(.+)$")
			if anchor ~= "Player" and not (kind == "Place" and Locations.Places[value]) and not (kind == "Zone" and table.find(Locations.Zones, value)) then
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
		for _, field in { "Asignatura1", "Asignatura2", "Practica" } do
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
	return errors
end

return Validate
