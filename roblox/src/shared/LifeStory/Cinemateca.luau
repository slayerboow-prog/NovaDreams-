-- Cinemateca: la lista de TODAS las escenas del juego, para verlas una por una y revisarlas (modo pruebas,
-- server/Services/CinematecaService + client/UI/Cinemateca). Cuentas puras: se prueba con Lune
-- (scripts/test-cinemateca.luau).
--
-- Qué entra:
--   * todas las escenas del motor (shared/LifeStory/HappeningIndex): las 21 de capítulo (Capitulos), los
--     montajes, la Grieta, Tefra, las de los guiones reescritos… y las ligeras (acontecimientos sin cámara)
--   * todas las conversaciones de las misiones (Dialogues de cada misión, con su escenificación)
-- Cada entrada: { Key, Kind = "Escena" | "Ligera" | "Conversación", Id (escena) | Quest + Dialogue,
--   Group (saga / capítulo / planeta), Title, Place? (dónde pasa, si se sabe) }. Orden: por grupo y nombre.
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

	-- De qué misión es cada escena (la pide un paso o un efecto, o la trae su guion) y dónde pasa
	local sceneQuest: { [string]: string } = {}
	local scenePlace: { [string]: string } = {}
	local function scanSteps(qid: string, steps: any, seen: { [any]: boolean })
		if type(steps) ~= "table" or seen[steps] then
			return
		end
		seen[steps] = true
		for k, v in steps do
			if type(v) == "table" then
				local id = (v.Type == "Cinematic" and v.Id) or v.Cinematic or (v.Effects and v.Effects.Scene) or nil
				if type(id) == "string" then
					sceneQuest[id] = sceneQuest[id] or qid
					if type(v.Place) == "string" then
						scenePlace[id] = scenePlace[id] or v.Place
					end
				end
				scanSteps(qid, v, seen)
			elseif k == "Scene" and type(v) == "string" then
				sceneQuest[v] = sceneQuest[v] or qid
			end
		end
	end
	for qid, quest in Quests do
		if type(quest) == "table" then
			scanSteps(qid, quest.Steps, {})
			scanSteps(qid, quest.Dialogues, {})
		end
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
		})
	end
	-- Conversaciones de las misiones (con su escenificación)
	for qid, quest in Quests do
		if type(quest) == "table" and type(quest.Dialogues) == "table" then
			local group = missionGroup(qid, quest, chapterOf, chapterName) or "📖 Otras misiones"
			-- (dónde se habla: el paso que la usa)
			local placeOf: { [string]: string } = {}
			local function scan(steps: any, seen: { [any]: boolean })
				if type(steps) ~= "table" or seen[steps] then
					return
				end
				seen[steps] = true
				for _, st in steps do
					if type(st) == "table" then
						if type(st.Dialogue) == "string" and type(st.Place) == "string" then
							placeOf[st.Dialogue] = placeOf[st.Dialogue] or st.Place
						end
						scan(st.Steps, seen)
					end
				end
			end
			scan(quest.Steps, {})
			for name, dialogue in quest.Dialogues do
				if type(name) == "string" and type(dialogue) == "table" then
					table.insert(out, {
						Key = ("D:%s/%s"):format(qid, name),
						Kind = "Conversación",
						Quest = qid,
						Dialogue = name,
						Group = group,
						Title = ("💬 %s · %s"):format(qid, name),
						Place = placeOf[name],
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
