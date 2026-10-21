-- Cinemateca: la lista de TODAS las escenas del juego, para verlas una por una y revisarlas (modo pruebas,
-- server/Services/CinematecaService + client/UI/Cinemateca). Cuentas puras: se prueba con Lune
-- (scripts/test-cinemateca.luau).
--
-- Qué entra:
--   * todas las escenas del motor (shared/LifeStory/HappeningIndex): las 21 de capítulo (Capitulos), los
--     montajes, la Grieta, Tefra, las de los guiones reescritos… y las ligeras (acontecimientos sin cámara)
--   * todas las conversaciones de las misiones (Dialogues de cada misión, con su escenificación)
-- Cada entrada: { Key, Kind = "Escena" | "Ligera" | "Conversación", Id (escena) | Quest + Dialogue,
--   Group (saga / capítulo / planeta), Title, Place? (dónde pasa: el sitio del paso o de sus actores),
--   Actors? (los del paso, con su sitio y su marca: { Npc, Place, Offset?, Index?, Mode? }), Before? (el
--   último sitio al que te llevó la misión antes) }. Orden: por grupo y nombre.
-- (La invasión de la Grieta no es una escena: es un acontecimiento del servidor; no sale aquí.)

local Cinemateca = {}

local function safeRequire(name: string): any
	local ok, module = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	return if ok then module else nil
end

-- Grupo de una misión: la saga, el planeta o su capítulo
local function missionGroup(questId: string?, quest: { [string]: any }?, chapterOf: { [string]: string }, chapterName: { [string]: string }): string?
	if type(questId) ~= "string" then
		return nil
	end
	if questId:sub(1, 5) == "Tefra" then
		return "🪐 Tefra (planeta)"
	elseif questId:sub(1, 5) == "Saga_" or questId:sub(1, 6) == "Varkun" then
		return "🌌 Saga de la Grieta"
	elseif questId:sub(1, 5) == "Loco_" then
		return "🛸 Misiones locas"
	end
	local chapter = (quest and quest.Chapter) or chapterOf[questId]
	if chapter and chapterName[chapter] then
		return "📖 " .. chapterName[chapter]
	end
	return if quest and quest.Kind == "Side" then "🧩 Secundarias" else "📖 Otras misiones"
end

local GROUP_NAMES = {
	Capitulos = "🎬 Capítulos (cabeceras, finales y fotos)",
	Cielo = "🌌 Saga de la Grieta",
	Etapas = "⏳ Montajes de etapa",
	Colegio = "🎒 El colegio",
	Instituto = "🏫 El instituto",
	Universidad = "🎓 La universidad",
	Adulto = "💼 La vida adulta",
	Tefra = "🪐 Tefra (planeta)",
	Guion = "📝 Guiones reescritos",
}

local cached: { { [string]: any } }? = nil

-- La lista entera (se calcula una vez)
function Cinemateca.list(): { { [string]: any } }
	if cached then
		return cached
	end
	local HappeningIndex = safeRequire("HappeningIndex")
	local Quests = safeRequire("Quests") or {}
	local Chapters = safeRequire("Chapters") or {}
	local GuionOverlay = safeRequire("GuionOverlay")
	local Strings = safeRequire("Strings")
	local Sequencer = safeRequire("Sequencer")

	local chapterOf, chapterName = {}, {}
	for id, chapter in Chapters do
		if type(chapter) == "table" then
			local name = id
			if Strings and chapter.TitleKey then
				local ok, text = pcall(Strings.get, chapter.TitleKey)
				if ok and type(text) == "string" then
					name = text
				end
			end
			chapterName[id] = name
			for _, field in { "Main", "Side" } do
				for _, qid in (type(chapter[field]) == "table" and chapter[field]) or {} do
					if type(qid) == "string" then
						chapterOf[qid] = id
					end
				end
			end
		end
	end

	-- De qué misión es cada escena (la pide un paso o un efecto, o la trae su guion) y dónde pasa: el sitio
	-- del paso, el de sus actores (con sus marcas: así los suplentes salen donde tienen que estar) o el
	-- último sitio al que te llevó la misión antes (v125.5: sin esto se ponían donde estabas, en un prado)
	local sceneQuest: { [string]: string } = {}
	local scenePlace: { [string]: string } = {}
	local sceneActors: { [string]: { { [string]: any } } } = {}
	local scenePrev: { [string]: string } = {}
	local dialoguePlace: { [string]: { [string]: string } } = {}
	local dialogueActors: { [string]: { [string]: { { [string]: any } } } } = {}
	local dialoguePrev: { [string]: { [string]: string } } = {}
	local function actorsOf(step: { [string]: any }): { { [string]: any } }?
		local out = nil
		for _, a in (type(step.Actors) == "table" and step.Actors) or {} do
			if type(a) == "table" and type(a.Npc) == "string" and type(a.Place) == "string" then
				out = out or {}
				table.insert(out, { Npc = a.Npc, Place = a.Place, Offset = a.Offset, Index = a.Index, Mode = a.Mode })
			end
		end
		return out
	end
	local function firstPlace(step: { [string]: any }, actors: { { [string]: any } }?): string?
		if type(step.Place) == "string" then
			return step.Place
		end
		return actors and actors[1] and actors[1].Place or nil
	end
	for qid, quest in Quests do
		if type(quest) ~= "table" then
			continue
		end
		local last: string? = nil
		local seen: { [any]: boolean } = {}
		local function walk(steps: any)
			if type(steps) ~= "table" or seen[steps] then
				return
			end
			seen[steps] = true
			for _, st in steps do
				if type(st) ~= "table" then
					continue
				end
				local actors = actorsOf(st)
				local place = firstPlace(st, actors)
				local ids = {}
				if st.Type == "Cinematic" and type(st.Id) == "string" then
					table.insert(ids, st.Id)
				end
				if type(st.Cinematic) == "string" then
					table.insert(ids, st.Cinematic)
				end
				if type(st.Effects) == "table" and type(st.Effects.Scene) == "string" then
					table.insert(ids, st.Effects.Scene)
				end
				for _, id in ids do
					if not sceneQuest[id] then
						sceneQuest[id] = qid
						scenePlace[id] = place
						sceneActors[id] = actors
						scenePrev[id] = last
					end
				end
				if type(st.Dialogue) == "string" then
					dialoguePlace[qid] = dialoguePlace[qid] or {}
					dialogueActors[qid] = dialogueActors[qid] or {}
					dialoguePrev[qid] = dialoguePrev[qid] or {}
					if dialoguePlace[qid][st.Dialogue] == nil and dialogueActors[qid][st.Dialogue] == nil then
						dialoguePlace[qid][st.Dialogue] = place
						dialogueActors[qid][st.Dialogue] = actors
						dialoguePrev[qid][st.Dialogue] = last
					end
				end
				walk(st.Steps)
				if place then
					last = place
				end
			end
		end
		walk(quest.Steps)
		-- (escenas que salen de una frase de una conversación: Effects.Scene en sus líneas)
		local function lines(node: any, dname: string?, guard: { [any]: boolean })
			if type(node) ~= "table" or guard[node] then
				return
			end
			guard[node] = true
			for k, v in node do
				if k == "Scene" and type(v) == "string" and not sceneQuest[v] then
					sceneQuest[v] = qid
					if dname and dialoguePlace[qid] then
						scenePlace[v] = dialoguePlace[qid][dname]
						sceneActors[v] = dialogueActors[qid][dname]
						scenePrev[v] = dialoguePrev[qid][dname]
					end
				elseif type(v) == "table" then
					lines(v, dname or (if type(k) == "string" and node == quest.Dialogues then k else nil), guard)
				end
			end
		end
		lines(quest.Dialogues, nil, {})
	end
	if GuionOverlay then
		local okAll, guiones = pcall(GuionOverlay.all)
		for qid, def in (if okAll and type(guiones) == "table" then guiones else {}) do
			for id in def.Scenes or {} do
				sceneQuest[id] = sceneQuest[id] or qid
			end
		end
	end

	local out: { { [string]: any } } = {}
	-- Escenas del motor
	for id, def in (if HappeningIndex then HappeningIndex.all() else {}) do
		local group = HappeningIndex.groupOf(id) or "?"
		local qid = sceneQuest[id]
		local label = if group == "Capitulos" or group == "Etapas"
			then GROUP_NAMES[group]
			else (missionGroup(qid, qid and Quests[qid] or nil, chapterOf, chapterName) or GROUP_NAMES[group] or ("🎬 " .. group))
		local light = Sequencer and Sequencer.isLight(def) or false
		table.insert(out, {
			Key = "E:" .. id,
			Kind = if light then "Ligera" else "Escena",
			Id = id,
			Quest = qid,
			Group = label,
			Title = id .. (if light then " · ligera" else ""),
			Place = scenePlace[id],
			Actors = sceneActors[id],
			Before = scenePrev[id],
		})
	end
	-- Conversaciones de las misiones (con su escenificación)
	for qid, quest in Quests do
		if type(quest) == "table" and type(quest.Dialogues) == "table" then
			local group = missionGroup(qid, quest, chapterOf, chapterName) or "📖 Otras misiones"
			for name, dialogue in quest.Dialogues do
				if type(name) == "string" and type(dialogue) == "table" then
					table.insert(out, {
						Key = ("D:%s/%s"):format(qid, name),
						Kind = "Conversación",
						Quest = qid,
						Dialogue = name,
						Group = group,
						Title = ("💬 %s · %s"):format(qid, name),
						Place = dialoguePlace[qid] and dialoguePlace[qid][name] or nil,
						Actors = dialogueActors[qid] and dialogueActors[qid][name] or nil,
						Before = dialoguePrev[qid] and dialoguePrev[qid][name] or nil,
					})
				end
			end
		end
	end
	table.sort(out, function(a, b)
		if a.Group ~= b.Group then
			return a.Group < b.Group
		end
		return a.Title < b.Title
	end)
	for i, entry in out do
		entry.Index = i
	end
	cached = out
	return out
end

-- Lo que se manda a la pantalla (corto: índice, clave, tipo, grupo, título)
function Cinemateca.brief(): { { [string]: any } }
	local out = {}
	for _, e in Cinemateca.list() do
		table.insert(out, { I = e.Index, K = e.Key, T = e.Title, G = e.Group, C = e.Kind })
	end
	return out
end

-- Busca (sin mayúsculas ni tildes) en el título y el grupo
function Cinemateca.norm(text: string): string
	local s = text:lower()
	for from, to in { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n" } do
		s = s:gsub(from, to)
	end
	return s
end

function Cinemateca.filter(list: { { [string]: any } }, query: string?): { { [string]: any } }
	local q = if type(query) == "string" then Cinemateca.norm(query):gsub("^%s+", ""):gsub("%s+$", "") else ""
	if q == "" then
		return list
	end
	local out = {}
	for _, e in list do
		local hay = Cinemateca.norm(tostring(e.T or e.Title or "") .. " " .. tostring(e.G or e.Group or ""))
		if hay:find(q, 1, true) then
			table.insert(out, e)
		end
	end
	return out
end

-- La entrada por su clave o por su índice
function Cinemateca.get(keyOrIndex: any): { [string]: any }?
	local list = Cinemateca.list()
	if type(keyOrIndex) == "number" then
		return list[keyOrIndex]
	end
	for _, e in list do
		if e.Key == keyOrIndex then
			return e
		end
	end
	return nil
end

return Cinemateca
