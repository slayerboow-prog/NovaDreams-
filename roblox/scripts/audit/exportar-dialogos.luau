-- Exportar los diálogos de la HISTORIA PRINCIPAL a un guion en Markdown (para revisarlo fuera del juego,
-- por ejemplo pegándolo en un asistente de IA y pidiéndole mejoras de guion y de cinemáticas).
--
-- Lee los datos reales (Chapters, Quests + Misiones/*, Strings, Cast, Locations, Cinematics y las escenas
-- del motor de Happenings/*) y escribe, EN ORDEN DE JUEGO (capítulo → misión → paso):
--   título del capítulo, su cabecera y su final; título y resumen de cada misión; y por paso: lugar,
--   quién está en escena, las frases (quién habla), las preguntas al jugador y a qué lleva cada respuesta,
--   las acotaciones (plano, gesto, pausa), las condiciones (variantes) en lenguaje sencillo y las
--   cinemáticas/escenas de cámara con sus frases.
--
-- Qué cuenta como historia PRINCIPAL:
--   * el prólogo (Prologo_Sueno);
--   * las misiones de la lista Main de cada capítulo activo (Chapters.luau), en ese orden;
--   * la Saga de la Grieta: las misiones Canon = true (las que marca CanonMarkers en el mapa).
-- Fuera: secundarias, consecuencias (Eco_*), misiones locas no canónicas, rarezas, aliados, metro,
-- profesiones y los «días normales» generados (Jornadas).
--
-- Uso (desde roblox/):  lune run scripts/audit/exportar-dialogos.luau
-- Escribe docs/historia/dialogos-historia-principal.md y, si pasa de LIMIT caracteres, también
-- docs/historia/dialogos-historia-principal-parteN.md (cortado por capítulos) para que quepa en un chat.

local fs = require("@lune/fs")
local H = require("../lib/StoryHarness")
local ROOT, loadModule = H.ROOT, H.loadModule

local Quests = H.Quests
local Chapters = loadModule(ROOT .. "/shared/LifeStory/Chapters")
local Cast = loadModule(ROOT .. "/shared/LifeStory/Cast")
local Strings = loadModule(ROOT .. "/shared/LifeStory/Strings")
local Locations = loadModule(ROOT .. "/shared/LifeStory/Locations")
local Cinematics = loadModule(ROOT .. "/shared/LifeStory/Cinematics")
local HappeningIndex = loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
local StageDirector = loadModule(ROOT .. "/shared/LifeStory/StageDirector")

local OUT_DIR = "docs/historia"
local OUT_NAME = "dialogos-historia-principal"
local LIMIT = 150000 -- caracteres por parte (lo que cabe con holgura en un mensaje de chat)

---------------------------------------------------------------------
-- Textos
---------------------------------------------------------------------
local TOKENS = {
	nombre = "[tu nombre]",
	abu = "Abu",
	ABU = "ABU",
	familia = "mamá/papá",
	Saludo = "Buenos días",
	grupo = "[nombre de tu grupo]",
}

-- Clave de Strings → texto; género neutro («vecin{o/a}» → «vecino/a»); variables del jugador legibles
local function txt(value: any, args: { [string]: any }?): string
	if value == nil then
		return ""
	end
	local s = tostring(value)
	s = Strings.es[s] or s
	s = StageDirector.genderize(s, nil)
	s = s:gsub("{(%w+)}", function(name)
		local v = (args and args[name]) or TOKENS[name]
		return if v ~= nil then tostring(v) else ("{" .. name .. "}")
	end)
	s = s:gsub("%$Carrera%.(%w+)", function(what)
		return "[" .. what:lower() .. " de tu carrera]"
	end)
	s = s:gsub("\n", " ")
	return s
end

local SPECIAL_NAMES = { Yo = "Tú", Familia = "Mamá/Papá", Abu = "Abu", Familia_Abu = "Abu", Familia_Padre = "Mamá/Papá" }

local function who(id: any): string
	if id == nil then
		return "Narrador"
	end
	id = tostring(id)
	if SPECIAL_NAMES[id] then
		return SPECIAL_NAMES[id]
	end
	if Cast.People[id] then
		return txt(Cast.nameOf(id))
	end
	return id
end

local function placeName(id: any): string
	if type(id) ~= "string" then
		return ""
	end
	if id:sub(1, 1) == "$" then
		return txt(id)
	end
	local p = Locations.Places[id]
	if p and p.NameKey then
		return txt(p.NameKey)
	end
	return id
end

-- «LlegasTarde» → «llegas tarde»
local function human(id: any): string
	local s = tostring(id)
	s = s:gsub("_", " ")
	s = s:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2"):gsub("(%a)(%d)", "%1 %2")
	return s:lower()
end

local function questTitle(id: string): string
	local q = Quests[id]
	if not q then
		return id
	end
	return txt(q.Title or q.TitleKey or id)
end

---------------------------------------------------------------------
-- Condiciones en lenguaje sencillo
---------------------------------------------------------------------
local function list(v: any, f: ((any) -> string)?): string
	local out = {}
	if type(v) == "table" then
		for _, x in v do
			table.insert(out, (f or human)(x))
		end
	else
		table.insert(out, (f or human)(v))
	end
	return table.concat(out, ", ")
end

-- «a», «b» y «c»
local function qlist(v: any): string
	local items = {}
	for _, x in (if type(v) == "table" then v else { v }) do
		table.insert(items, "«" .. human(x) .. "»")
	end
	if #items <= 1 then
		return items[1] or ""
	end
	return table.concat(items, ", ", 1, #items - 1) .. " y " .. items[#items]
end

-- Listas largas: las tres primeras y «…»
local function shortList(v: any): string
	local items = {}
	for i, x in v or {} do
		if i > 3 then
			table.insert(items, "…")
			break
		end
		table.insert(items, human(x))
	end
	return table.concat(items, ", ")
end

local function sortedPairs(t: { [any]: any }): { any }
	local keys = {}
	for k in t do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return keys
end

local function cond(req: any): string?
	if type(req) ~= "table" or next(req) == nil then
		return nil
	end
	local parts = {}
	local function add(s: string)
		table.insert(parts, s)
	end
	for _, k in sortedPairs(req) do
		local v = req[k]
		if k == "Flags" then
			add((if type(v) == "table" and #v > 1 then "tienes las marcas " else "tienes la marca ") .. qlist(v))
		elseif k == "NotFlags" then
			add((if type(v) == "table" and #v > 1 then "NO tienes las marcas " else "NO tienes la marca ") .. qlist(v))
		elseif k == "Memories" then
			add((if type(v) == "table" and #v > 1 then "tienes los recuerdos " else "tienes el recuerdo ") .. qlist(v))
		elseif k == "NotMemories" then
			add((if type(v) == "table" and #v > 1 then "NO tienes los recuerdos " else "NO tienes el recuerdo ") .. qlist(v))
		elseif k == "Choices" or k == "NotChoices" then
			for _, ck in sortedPairs(v) do
				local cv = v[ck]
				local opts = if type(cv) == "table" then table.concat(cv, " o ") else tostring(cv)
				if k == "Choices" then
					add("en «" .. human(ck) .. "» elegiste «" .. opts .. "»")
				else
					add("en «" .. human(ck) .. "» NO elegiste «" .. opts .. "»")
				end
			end
		elseif k == "Completed" then
			add("has terminado " .. list(v, function(x)
				return "«" .. questTitle(x) .. "»"
			end))
		elseif k == "NotCompleted" then
			add("NO has terminado " .. list(v, function(x)
				return "«" .. questTitle(x) .. "»"
			end))
		elseif k == "Rel" then
			for _, n in sortedPairs(v) do
				add(("tu relación con %s es de %s o más"):format(who(n), tostring(v[n])))
			end
		elseif k == "RelBelow" then
			for _, n in sortedPairs(v) do
				add(("tu relación con %s es menor que %s"):format(who(n), tostring(v[n])))
			end
		elseif k == "Traits" then
			for _, n in sortedPairs(v) do
				add(("tu rasgo %s es %s o más"):format(human(n), tostring(v[n])))
			end
		elseif k == "TraitsBelow" then
			for _, n in sortedPairs(v) do
				add(("tu rasgo %s es menor que %s"):format(human(n), tostring(v[n])))
			end
		elseif k == "Stage" then
			add(("etapa %s%s"):format(v.Min and ("desde " .. v.Min) or "", v.Max and (" hasta " .. v.Max) or ""))
		elseif k == "Hours" then
			add(("entre las %s:00 y las %s:00"):format(tostring(v.From), tostring(v.To)))
		elseif k == "StageProgress" then
			add(("has vivido el %d %% de la etapa"):format(math.floor(v * 100 + 0.5)))
		elseif k == "Input" then
			add("reaccionaste a tiempo («" .. human(v) .. "»)")
		elseif k == "Late" then
			add(if v then "llegaste tarde" else "llegaste a tiempo")
		elseif k == "Items" then
			for _, n in sortedPairs(v) do
				add(("llevas %s (%s)"):format(human(n), tostring(v[n])))
			end
		elseif k == "MemoriesAtLeast" then
			add(("tienes al menos %d de estos %d recuerdos: %s"):format(v.N or 0, #(v.Of or {}), shortList(v.Of)))
		elseif k == "MemoriesFewer" then
			add(("tienes menos de %d de estos %d recuerdos: %s"):format(v.N or 0, #(v.Of or {}), shortList(v.Of)))
		elseif k == "LastGradeBelow" then
			add("tu última nota es menor que " .. tostring(v))
		elseif k == "LastGradeAtLeast" then
			add("tu última nota es " .. tostring(v) .. " o más")
		elseif k == "Discovered" then
			add("ya has visitado " .. list(v, placeName))
		elseif k == "World" or k == "NotWorld" then
			local bits = {}
			for _, wk in sortedPairs(v) do
				table.insert(bits, if type(wk) == "number" then tostring(v[wk]) else tostring(wk) .. " = " .. tostring(v[wk]))
			end
			add((if k == "World" then "en el mundo: " else "en el mundo NO: ") .. table.concat(bits, ", "))
		elseif k == "Weekdays" then
			add("días de la semana " .. list(v, tostring))
		elseif k == "Season" then
			add("en " .. list(v, tostring))
		elseif k == "Weather" then
			add("con tiempo " .. list(v, tostring))
		elseif k == "OnDuty" then
			add("de servicio como " .. tostring(v))
		else
			add(human(k) .. " = " .. (if type(v) == "table" then list(v, tostring) else tostring(v)))
		end
	end
	return table.concat(parts, " y ")
end

local function condLabel(line: any): string
	local a = line.If and cond(line.If)
	local b = line.IfNot and cond(line.IfNot)
	if a and b then
		return "_(si " .. a .. "; y NO si " .. b .. ")_ "
	elseif a then
		return "_(si " .. a .. ")_ "
	elseif b then
		return "_(si NO se cumple: " .. b .. ")_ "
	end
	return ""
end

---------------------------------------------------------------------
-- Efectos (a qué lleva una respuesta)
---------------------------------------------------------------------
local function effectsText(e: any): string?
	if type(e) ~= "table" then
		return nil
	end
	local bits = {}
	if type(e.Rel) == "table" then
		for _, n in sortedPairs(e.Rel) do
			local d = e.Rel[n]
			table.insert(bits, ("%s %s%s"):format(who(n), if type(d) == "number" and d >= 0 then "+" else "", tostring(d)))
		end
	end
	if type(e.Traits) == "table" then
		for _, n in sortedPairs(e.Traits) do
			table.insert(bits, human(n) .. " +" .. tostring(e.Traits[n]))
		end
	end
	if type(e.Choice) == "table" then
		for _, k in sortedPairs(e.Choice) do
			table.insert(bits, "decisión «" .. human(k) .. "» = " .. tostring(e.Choice[k]))
		end
	end
	if e.Flags then
		table.insert(bits, "marca " .. qlist(e.Flags))
	end
	if type(e.Memory) == "string" then
		table.insert(bits, "recuerdo «" .. human(e.Memory) .. "»")
	end
	if type(e.Items) == "table" then
		table.insert(bits, "objeto " .. table.concat((function()
			local o = {}
			for _, n in sortedPairs(e.Items) do
				table.insert(o, human(n))
			end
			return o
		end)(), ", "))
	end
	if type(e.Later) == "table" then
		for _, l in e.Later do
			if type(l) == "table" and l.Start then
				table.insert(bits, ("más tarde empieza «%s»"):format(questTitle(l.Start)))
			end
		end
	end
	if e.Start then
		table.insert(bits, ("empieza «%s»"):format(questTitle(e.Start)))
	end
	if #bits == 0 then
		return nil
	end
	return table.concat(bits, "; ")
end

---------------------------------------------------------------------
-- Salida
---------------------------------------------------------------------
local out: { string } = {}
local function w(s: string?)
	table.insert(out, s or "")
end

-- Recuento para la comprobación final (por referencia de la frase: cada frase cuenta una vez)
local exported: { [any]: boolean } = {}
local stats = { Lines = 0, Asks = 0, Barks = 0, Scenes = 0, Missing = {} :: { string } }

local function acting(line: any): string
	local bits = {}
	if line.To and line.To ~= "Yo" then
		table.insert(bits, "a " .. who(line.To))
	end
	if line.Shot then
		local kind, rest = tostring(line.Shot):match("^([^:]+):?(.*)$")
		local people = {}
		for id in (rest or ""):gmatch("[^>,]+") do
			table.insert(people, if Cast.People[id] or SPECIAL_NAMES[id] then who(id) else id)
		end
		table.insert(bits, "plano " .. (kind or "") .. (if #people > 0 then " de " .. table.concat(people, " → ") else ""))
	end
	if line.A then
		table.insert(bits, "gesto " .. tostring(line.A))
	end
	if line.G then
		table.insert(bits, "ademán " .. tostring(line.G))
	end
	if line.Beat then
		table.insert(bits, "en la pausa: " .. tostring(line.Beat))
	end
	if line.Mood then
		table.insert(bits, "emoción " .. tostring(line.Mood))
	end
	if type(line.Pause) == "number" and line.Pause >= 0.5 then
		table.insert(bits, ("silencio %.1f s"):format(line.Pause))
	end
	if #bits == 0 then
		return ""
	end
	return " _[" .. table.concat(bits, " · ") .. "]_"
end

-- «texto» (sin doblar las comillas si el texto ya las trae)
local function quoted(s: string): string
	if s:sub(1, 2) == "«" or s:sub(1, 1) == "(" then
		return s
	end
	return "«" .. s .. "»"
end

local function speakerLine(speaker: any, text: any, line: any, indent: string)
	local s = tostring(speaker or "Narrador")
	local body = txt(text)
	local prefix = indent .. "- " .. condLabel(line) .. (if line.Alt then "_(o bien)_ " else "")
	if s == "Narrador" then
		w(prefix .. "_Narrador:_ _" .. body .. "_" .. acting(line))
	else
		w(prefix .. "**" .. who(s) .. ":** " .. body .. acting(line))
	end
end

local renderScene: (id: string, indent: string, seen: { [string]: boolean }, how: string?) -> ()

local function renderLines(lines: any, indent: string, seen: { [string]: boolean })
	for _, l in lines or {} do
		if type(l) ~= "table" then
			continue
		end
		if l.Ask then
			exported[l] = true
			stats.Asks += 1
			w(indent .. "- " .. condLabel(l) .. "❓ **Pregunta al jugador:** " .. txt(l.Ask))
			for _, o in l.Options or {} do
				local eff = effectsText(o.Effects)
				w(indent .. "  - ➤ " .. condLabel(o) .. quoted(txt(o.T)) .. (if eff then " _(efecto: " .. eff .. ")_" else ""))
				renderLines(o.Then, indent .. "    ", seen)
				if o.Effects and o.Effects.Scene then
					renderScene(o.Effects.Scene, indent .. "    ", seen)
				end
			end
		elseif l.T then
			exported[l] = true
			stats.Lines += 1
			speakerLine(l.S, l.T, l, indent)
			if l.Effects and l.Effects.Scene then
				renderScene(l.Effects.Scene, indent .. "  ", seen)
			end
		end
	end
end

---------------------------------------------------------------------
-- Escenas de cámara: Cinematics.luau (vuelos con subtítulos) y escenas del motor (Happenings)
---------------------------------------------------------------------
local function musicText(def: any): string?
	local bits = {}
	if type(def.Music) == "string" then
		table.insert(bits, def.Music)
	end
	if type(def.Intensity) == "string" then
		table.insert(bits, "intensidad " .. def.Intensity)
	end
	local tracks = def.Tracks
	for _, m in (tracks and tracks.Music) or {} do
		if type(m) == "table" then
			if m.Play then
				table.insert(bits, tostring(m.Play))
			elseif m.Intensity then
				table.insert(bits, "→ " .. tostring(m.Intensity))
			end
		end
	end
	if def.Sting then
		table.insert(bits, "efecto " .. tostring(def.Sting))
	end
	if #bits == 0 then
		return nil
	end
	return table.concat(bits, " ")
end

local function renderTracks(tracks: any, indent: string, seen: { [string]: boolean })
	if type(tracks) ~= "table" then
		return
	end
	-- Reparto: quién aparece, entra andando, sale
	local cast, enters, exits, seenCast = {}, {}, {}, {}
	for _, a in tracks.Actors or {} do
		local spec = a.Spawn or a.Enter or a.Use
		if type(spec) == "table" and (spec.Npc or spec.Creature) then
			local name = who(spec.Npc or spec.Creature)
			if not seenCast[name] then
				seenCast[name] = true
				table.insert(cast, name)
			end
			if a.Enter then
				table.insert(enters, name)
			end
		end
		if type(a.Exit) == "table" then
			local key = a.Exit.Key
			table.insert(exits, who(key))
		end
	end
	if #cast > 0 then
		local s = indent .. "- _En escena:_ " .. table.concat(cast, ", ")
		if #enters > 0 then
			s ..= " · _entran andando:_ " .. table.concat(enters, ", ")
		end
		if #exits > 0 then
			s ..= " · _salen:_ " .. table.concat(exits, ", ")
		end
		w(s)
	end
	-- Planos con nombre de la pista de cámara
	local shots, seenShot = {}, {}
	for _, c in tracks.Camera or {} do
		local name = c.Shot and tostring(c.Shot):match("^([^:]+)")
		if name and not seenShot[name] then
			seenShot[name] = true
			table.insert(shots, name)
		end
	end
	if tracks.Camera then
		w(indent .. ("- _Cámara:_ %d planos%s"):format(#tracks.Camera, if #shots > 0 then " (" .. table.concat(shots, ", ") .. ")" else ""))
	end
	for _, t in tracks.Titles or {} do
		local main = txt(t.Text or t.TextKey)
		local sub = t.Sub or t.SubKey
		w(indent .. "- " .. condLabel(t) .. "🪧 _Rótulo:_ «" .. main .. "»" .. (if sub then " — " .. txt(sub) else ""))
	end
	for _, wt in tracks.Wait or {} do
		w(indent .. "- " .. condLabel(wt) .. "⏸ _El jugador debe reaccionar:_ «" .. txt(wt.Prompt or wt.Input) .. "»")
	end
	-- Voces sobre la escena (subtítulos con tiempo)
	local timed = {}
	for _, l in tracks.Lines or {} do
		table.insert(timed, l)
	end
	table.sort(timed, function(a, b)
		return (a.At or 0) < (b.At or 0)
	end)
	for _, l in timed do
		if l.Text or l.TextKey or l.T then
			exported[l] = true
			stats.Lines += 1
			speakerLine(l.Speaker or l.S, l.Text or l.TextKey or l.T, l, indent)
		end
	end
	-- Diálogo en el mundo
	renderLines(tracks.Dialogue, indent, seen)
end

renderScene = function(id: string, indent: string, seen: { [string]: boolean }, how: string?)
	if type(id) ~= "string" then
		return
	end
	local label = how or "Escena de cámara"
	if seen[id] then
		w(indent .. ("- 🎬 **%s «%s»** _(la misma de antes, ver arriba)_"):format(label, id))
		return
	end
	seen[id] = true
	local hap = HappeningIndex.get(id)
	if hap then
		stats.Scenes += 1
		local extras = {}
		local music = musicText(hap)
		if music then
			table.insert(extras, "música: " .. music)
		end
		if hap.Montaje then
			table.insert(extras, ("montaje de cambio de etapa %s → %s"):format(tostring(hap.Montaje.From), tostring(hap.Montaje.To)))
		end
		w(indent .. ("- 🎬 **%s «%s»**%s"):format(label, id, if #extras > 0 then " _(" .. table.concat(extras, "; ") .. ")_" else ""))
		renderTracks(hap.Tracks, indent .. "  ", seen)
		for _, v in hap.Variants or {} do
			local c = cond(v.If)
			local names = {}
			for k in v.Tracks or {} do
				table.insert(names, tostring(k))
			end
			table.sort(names)
			w(indent .. ("  - 🔀 **Variante «%s»**%s: cambia %s por:"):format(tostring(v.Name or "?"), if c then " (si " .. c .. ")" else "", table.concat(names, ", ")))
			local before = #out
			renderTracks(v.Tracks, indent .. "    ", seen)
			if #out == before then
				w(indent .. "    - _(solo efectos de imagen y sonido, sin texto)_")
			end
		end
		return
	end
	local cine = Cinematics[id]
	if cine then
		stats.Scenes += 1
		local music = musicText(cine)
		w(indent .. ("- 🎬 **%s «%s»** _(vuelo de cámara, %s s, %d planos%s)_"):format(
			label,
			id,
			tostring(cine.Duration or "?"),
			#(cine.Shots or {}),
			if music then "; música: " .. music else ""
		))
		for _, t in cine.Titles or {} do
			w(indent .. "  - 🪧 _Rótulo:_ «" .. txt(t.TextKey or t.Text) .. "»" .. (if t.SubKey or t.Sub then " — " .. txt(t.SubKey or t.Sub) else ""))
		end
		for _, l in cine.Lines or {} do
			exported[l] = true
			stats.Lines += 1
			speakerLine(l.Speaker, l.TextKey or l.Text, l, indent .. "  ")
		end
		return
	end
	table.insert(stats.Missing, "escena " .. id)
	w(indent .. ("- 🎬 **%s «%s»** _(no está en los datos)_"):format(label, id))
end

---------------------------------------------------------------------
-- Misiones
---------------------------------------------------------------------
local STEP_NAMES = {
	Scene = "Escena",
	Talk = "Hablar",
	Reach = "Ir a",
	Use = "Usar",
	Group = "Varios objetivos (en cualquier orden)",
	Choice = "Decisión",
	Cinematic = "Cinemática",
	Transition = "Transición (pasa el tiempo)",
	MiniGame = "Minijuego",
	Fight = "Pelea",
	Chase = "Persecución",
	Escape = "Huida",
	Class = "Clase",
	Event = "Acción del jugador",
	Wait = "Esperar",
	Moment = "Momento",
}

local function actorList(actors: any): string?
	if type(actors) ~= "table" then
		return nil
	end
	local names, seenName = {}, {}
	for _, a in actors do
		if type(a) == "table" and a.Npc then
			local n = who(a.Npc)
			local c = a.If and cond(a.If)
			local label = n .. (if c then " (si " .. c .. ")" else "") .. (if a.Mode == "Follow" then " (te acompaña)" else "")
			if not seenName[label] then
				seenName[label] = true
				table.insert(names, label)
			end
		end
	end
	if #names == 0 then
		return nil
	end
	return table.concat(names, ", ")
end

local function stepPlace(step: any): string?
	if step.Place then
		return placeName(step.Place)
	end
	if type(step.Teleport) == "table" and step.Teleport.Place then
		return placeName(step.Teleport.Place)
	end
	local counts, best, bestN = {}, nil, 0
	for _, a in step.Actors or {} do
		if type(a) == "table" and a.Place then
			counts[a.Place] = (counts[a.Place] or 0) + 1
			if counts[a.Place] > bestN then
				best, bestN = a.Place, counts[a.Place]
			end
		end
	end
	return best and placeName(best)
end

local function renderMission(id: string)
	local q = Quests[id]
	if not q then
		table.insert(stats.Missing, "misión " .. id)
		w("### ⚠ Misión «" .. id .. "» (no está en los datos)")
		return
	end
	local dialogues = q.Dialogues or {}
	local used: { [string]: boolean } = {}
	local seenScenes: { [string]: boolean } = {}
	local props = q.Props or {}

	local function dialogue(name: any, indent: string, label: string?)
		if type(name) ~= "string" then
			return
		end
		local d = dialogues[name]
		if not d then
			table.insert(stats.Missing, ("diálogo %s.%s"):format(id, name))
			w(indent .. "- ⚠ _(diálogo «" .. name .. "» no encontrado)_")
			return
		end
		if used[name] then
			w(indent .. "- " .. (label or "") .. ("_(la misma conversación «%s» de arriba)_"):format(name))
			return
		end
		if label then
			w(indent .. "- " .. label)
			indent ..= "  "
		end
		used[name] = true
		renderLines(d.Lines or d, indent, seenScenes)
		if type(d.Effects) == "table" and d.Effects.Scene then
			renderScene(d.Effects.Scene, indent, seenScenes)
		end
	end

	local function propDialogue(propId: any, indent: string)
		local p = props[propId]
		if type(p) == "table" and p.Dialogue then
			dialogue(p.Dialogue, indent, ("🖐 _Al usar «%s»:_"):format(txt(p.Name or propId)))
		end
	end

	w(("### %s · «%s»"):format(id, questTitle(id)))
	w()
	if q.Description then
		w("**Resumen:** " .. txt(q.Description))
		w()
	end
	local meta = {}
	if q.Type then
		table.insert(meta, "Tipo: " .. txt(q.Type))
	end
	if type(q.AgeRange) == "table" then
		table.insert(meta, ("Edad: %s-%s años"):format(tostring(q.AgeRange[1]), tostring(q.AgeRange[2])))
	end
	if type(q.Duration) == "table" then
		table.insert(meta, ("Duración: %s-%s min"):format(tostring(q.Duration[1]), tostring(q.Duration[2])))
	end
	if #meta > 0 then
		w("_" .. table.concat(meta, " · ") .. "_")
		w()
	end
	if q.OfferKey or (q.Offer and q.Offer.Place) then
		w(("**Cómo empieza:** %s%s"):format(
			if q.Offer and q.Offer.Place then "al llegar a " .. placeName(q.Offer.Place) .. ". " else "",
			if q.OfferKey then "«" .. txt(q.OfferKey) .. "»" else ""
		))
		w()
	end
	local req = q.Requires and cond(q.Requires)
	if req then
		w("**Requisitos:** " .. req)
		w()
	end
	if type(q.Outcomes) == "table" and #q.Outcomes > 0 then
		local outcomes = {}
		for _, o in q.Outcomes do
			table.insert(outcomes, txt(o))
		end
		w("**Lo que puede cambiar:** " .. table.concat(outcomes, " · "))
		w()
	end
	local questCast = actorList(q.Actors)
	if questCast then
		w("**Presentes en toda la misión:** " .. questCast)
		w()
	end

	local barked: { [string]: boolean } = {}
	local scene = { Place = nil :: string?, Actors = nil :: string? } -- lo último que se dijo (para no repetirlo)
	local function renderStep(step: any, number: string, indent: string)
		local kind = STEP_NAMES[step.Type] or tostring(step.Type)
		local objective = step.Text or step.TextKey or step.Title
		local head = ("%s- **Paso %s · %s**"):format(indent, number, kind)
		if step.Type == "Talk" and step.Npc then
			head ..= " con " .. who(step.Npc)
		end
		if step.Type == "Reach" and step.Place then
			head ..= " " .. placeName(step.Place)
		end
		if objective then
			local args = { place = if step.Place then placeName(step.Place) else nil, count = 0, total = step.Count or step.Need or (if type(step.Enemies) == "table" then #step.Enemies else step.Enemies) or "N" }
			if not args.place and step.Match and step.Match.ShopId then
				args.place = placeName(step.Match.ShopId)
			end
			head ..= " — «" .. txt(objective, args) .. "»"
		end
		local c = step.If and cond(step.If)
		if c then
			head ..= " _(solo si " .. c .. ")_"
		end
		w(head)
		local sub = indent .. "  "
		local place = stepPlace(step)
		local actors = actorList(step.Actors)
		local bits = {}
		if place and place ~= scene.Place and not (step.Type == "Reach" and step.Place and not actors) then
			table.insert(bits, "_Lugar:_ " .. place)
		end
		if actors and actors ~= scene.Actors then
			table.insert(bits, "_En escena:_ " .. actors)
		end
		if place then
			scene.Place = place
		end
		if actors then
			scene.Actors = actors
		end
		if #bits > 0 then
			w(sub .. "- " .. table.concat(bits, " · "))
		end
		if step.Type == "MiniGame" and step.Hint then
			w(sub .. "- 🎮 _Cómo se juega:_ " .. txt(step.Hint))
		end
		-- Frases sueltas de los actores (al pasar cerca) y avisos si tardas
		for _, a in step.Actors or {} do
			if type(a) == "table" and a.Bark and not barked[a.Bark] then
				barked[a.Bark] = true
				stats.Barks += 1
				w(sub .. ("- 💬 _Comentario al pasar cerca de %s:_ «%s»"):format(who(a.Npc), txt(a.Bark)))
			end
		end
		if type(step.Nudge) == "table" and step.Nudge.T then
			stats.Barks += 1
			w(sub .. ("- ⏰ _Si tardas, %s dice:_ «%s»"):format(who(step.Nudge.S), txt(step.Nudge.T)))
		end
		if step.CaughtLine then
			stats.Barks += 1
			w(sub .. "- 🚨 _Si te atrapan:_ «" .. txt(step.CaughtLine) .. "»")
		end
		-- La conversación del paso
		if step.Dialogue then
			dialogue(step.Dialogue, sub)
		end
		-- Escenas de cámara
		if step.Type == "Cinematic" and step.Id then
			renderScene(step.Id, sub, seenScenes, "Cinemática")
		end
		if step.Type == "Transition" then
			if step.TextKey or step.Text then
				w(sub .. "- ⏳ _Pantalla de transición:_ «" .. txt(step.TextKey or step.Text) .. "»" .. (if step.SetStage then " _(pasas a la etapa " .. tostring(step.SetStage) .. ")_" else ""))
			end
			if step.Cinematic then
				renderScene(step.Cinematic, sub, seenScenes, "Montaje / cinemática de transición")
			end
		end
		if step.Type == "Moment" and (step.TextKey or step.Text) == nil then
			w(sub .. "- ✨ _Momento narrativo_")
		end
		if type(step.Effects) == "table" and step.Effects.Scene then
			renderScene(step.Effects.Scene, sub, seenScenes, "Escena al completarlo")
		end
		-- Objetos con conversación
		if step.Type == "Use" and step.Prop then
			propDialogue(step.Prop, sub)
		end
		for _, propId in step.Props or {} do
			propDialogue(propId, sub)
		end
		-- Decisiones: cada opción y a qué lleva
		if step.Type == "Choice" then
			if step.PromptKey then
				w(sub .. "- ❓ **Pregunta:** " .. txt(step.PromptKey))
			end
			for _, o in step.Options or {} do
				local eff = effectsText(o.Effects)
				if step.Key and o.Id then
					local pick = ("decisión «%s» = %s"):format(human(step.Key), tostring(o.Id))
					eff = if eff then pick .. "; " .. eff else pick
				end
				local label = txt(o.Text or o.TextKey or o.Id)
				w(sub .. "- ➤ " .. condLabel(o) .. "**Opción " .. quoted(label) .. "**" .. (if o.Npc then " (con " .. who(o.Npc) .. ")" else "") .. (if eff then " _(efecto: " .. eff .. ")_" else ""))
				if o.Dialogue then
					dialogue(o.Dialogue, sub .. "  ")
				end
				if o.Prop then
					propDialogue(o.Prop, sub .. "  ")
				end
			end
		end
		-- Conversaciones opcionales con los actores del paso (los que tienen Talk)
		for _, a in step.Actors or {} do
			if type(a) == "table" and type(a.Talk) == "string" then
				if not used[a.Talk] then
					dialogue(a.Talk, sub, ("🗨 _Charla opcional con %s (si te acercas a hablar):_"):format(who(a.Npc)))
				end
			end
		end
		-- Sub-pasos
		for i, s in step.Steps or {} do
			renderStep(s, number .. "." .. i, sub)
		end
	end

	-- Actores con charla en toda la misión
	for _, a in q.Actors or {} do
		if type(a) == "table" and type(a.Talk) == "string" then
			dialogue(a.Talk, "", ("🗨 _Charla opcional con %s:_"):format(who(a.Npc)))
		end
	end

	w("**Pasos:**")
	w()
	for i, step in q.Steps or {} do
		renderStep(step, tostring(i), "")
	end
	-- Diálogos que no cuelgan de un paso concreto (objetos sueltos, avisos que lanza el código…)
	local rest = {}
	for name in dialogues do
		if not used[name] then
			table.insert(rest, name)
		end
	end
	table.sort(rest)
	if #rest > 0 then
		w()
		w("**Otros diálogos de esta misión** _(los lanza un objeto, un actor o el propio juego, no un paso concreto):_")
		w()
		for _, name in rest do
			-- ¿De qué objeto es?
			local owner = nil
			for propId, p in props do
				if type(p) == "table" and p.Dialogue == name then
					owner = "al usar «" .. txt(p.Name or propId) .. "»"
				end
			end
			dialogue(name, "", ("«%s»%s:"):format(name, if owner then " _(" .. owner .. ")_" else ""))
		end
	end
	local final = q.Moment or q.MomentKey
	if final then
		w()
		w("**Al terminar (momento de la biografía):** «" .. txt(final) .. "»")
	end
	w()
	w("---")
	w()
end

---------------------------------------------------------------------
-- Orden de juego
---------------------------------------------------------------------
local CHAPTER_ORDER = {}
for id, c in Chapters do
	if c.Enabled ~= false then
		table.insert(CHAPTER_ORDER, id)
	end
end
table.sort(CHAPTER_ORDER, function(a, b)
	return Chapters[a].Order < Chapters[b].Order
end)

-- La saga (misiones canónicas), por actos y en su orden (Loco_N1_Cosme abre el acto I)
local sagaIds = {}
for id, q in Quests do
	if q.Canon then
		table.insert(sagaIds, id)
	end
end
local function sagaNumber(id: string): number
	if id == "Loco_N1_Cosme" then
		return 1
	end
	return tonumber(id:match("^Saga_(%d+)")) or 99
end
table.sort(sagaIds, function(a, b)
	return sagaNumber(a) < sagaNumber(b)
end)
local ACTS = {
	{ Key = "Acto I", Title = "Saga de la Grieta · Acto I «La Grieta»", When = "infancia: en paralelo al colegio (pilar dorado en el mapa)" },
	{ Key = "Acto II", Title = "Saga de la Grieta · Acto II", When = "adolescencia: en paralelo al instituto" },
	{ Key = "Acto III", Title = "Saga de la Grieta · Acto III", When = "adulto joven: en paralelo a la universidad / «Volar del nido»" },
	{ Key = "Acto IV", Title = "Saga de la Grieta · Acto IV y epílogo", When = "vida adulta: en paralelo a «Tu vida», antes de «Mirar atrás»" },
}
local function actOf(id: string): number
	local t = tostring(Quests[id].Type or "")
	if t:find("Acto IV", 1, true) or t:find("Epílogo", 1, true) then
		return 4
	elseif t:find("Acto III", 1, true) then
		return 3
	elseif t:find("Acto II", 1, true) then
		return 2
	end
	return 1
end
local sagaByAct = { {}, {}, {}, {} }
for _, id in sagaIds do
	table.insert(sagaByAct[actOf(id)], id)
end

-- Secciones: { Title, Render = fn, Missions = { ids } } en orden de juego
type Section = { Title: string, Intro: (() -> ())?, Missions: { string }, Outro: (() -> ())?, Label: string? }
local sections: { Section } = {}

local function chapterSection(id: string, extraNote: string?): Section
	local c = Chapters[id]
	local title = txt(c.TitleKey)
	return {
		Title = ("Capítulo «%s»"):format(title),
		Label = "Capítulo «" .. title .. "»",
		Intro = function()
			w(("_Id: %s · Etapa: %s%s%s_"):format(
				id,
				tostring(c.Stage and c.Stage.Min or "?"),
				if c.Stage and c.Stage.Max and c.Stage.Max ~= c.Stage.Min then "–" .. c.Stage.Max else "",
				if c.Music then " · Música de fondo: " .. c.Music else ""
			))
			w()
			if extraNote then
				w("> " .. extraNote)
				w()
			end
			local req = c.Requires and cond(c.Requires)
			if req then
				w("**Solo si:** " .. req)
				w()
			end
			w("**Texto de entrada del capítulo:** «" .. txt(c.IntroKey) .. "»")
			w()
			if c.IntroCinematic then
				local seen = {}
				renderScene(c.IntroCinematic, "", seen, "Cabecera del capítulo (cinemática)")
				w()
			end
			if c.Loop then
				w(("_Entre misión y misión se repite un «día normal» generado (%s): no se exporta, no es guion fijo._"):format(c.Loop))
				w()
			end
		end,
		Missions = c.Main,
		Outro = function()
			w("**Texto de cierre del capítulo:** «" .. txt(c.OutroKey) .. "»")
			w()
			if c.OutroCinematic then
				local seen = {}
				renderScene(c.OutroCinematic, "", seen, "Final del capítulo (cinemática)")
				w()
			end
		end,
	}
end

local function sagaSection(act: number): Section
	local a = ACTS[act]
	return {
		Title = a.Title,
		Label = a.Title,
		Intro = function()
			w("> Misiones canónicas de la saga (" .. a.When .. "). Se ven siempre en el mapa hasta hacerlas.")
			w()
		end,
		Missions = sagaByAct[act],
	}
end

table.insert(sections, {
	Title = "Prólogo",
	Label = "Prólogo",
	Intro = function()
		w("> Tutorial de controles contado como historia. Solo la primera vez, antes del nacimiento.")
		w()
	end,
	Missions = { "Prologo_Sueno" },
})
local SAGA_AFTER = { Nino_ElColegio = 1, Adolescente_Instituto = 2, Adulto_VolarDelNido = 3 }
local LEGACY = "Adulto_NuevaVida"
for _, id in CHAPTER_ORDER do
	if id == LEGACY then
		continue
	end
	if id == "Adulto_TuVida" then
		table.insert(sections, sagaSection(4))
	end
	local note = if id == "Joven_Universidad" then "Solo si en el instituto eliges ir a la universidad; si eliges trabajar, se pasa directamente a «Volar del nido»." else nil
	table.insert(sections, chapterSection(id, note))
	if SAGA_AFTER[id] then
		table.insert(sections, sagaSection(SAGA_AFTER[id]))
	end
end
if Chapters[LEGACY] and Chapters[LEGACY].Enabled ~= false then
	table.insert(sections, chapterSection(LEGACY, "Capítulo ALTERNATIVO: solo lo juega quien empezó la partida ya adulto (versiones antiguas, sin infancia jugada). Sustituye a todo lo anterior."))
end

---------------------------------------------------------------------
-- Prompt
---------------------------------------------------------------------
local function firstSentence(s: string): string
	local first = s:match("^(.-[%.!%?])%s") or s
	return first
end

local function castSummary(): { string }
	local lines = {}
	for _, id in Cast.Principales do
		local p = Cast.People[id]
		if p then
			local bio = firstSentence(txt(p.Bio))
			local extra = ""
			if p.Perfil and p.Perfil.Habla then
				extra = " Habla: " .. firstSentence(txt(p.Perfil.Habla.Vocabulario))
			end
			table.insert(lines, ("- **%s**: %s%s"):format(who(id), bio, extra))
		end
	end
	return lines
end

local function fullPrompt(partsNote: string?)
	w("## PROMPT PARA CHATGPT (copiar desde aquí)")
	w()
	w("Eres guionista y director de cinemáticas de videojuegos. Te paso el guion completo de la historia principal de mi juego para que me ayudes a mejorarlo.")
	w()
	w("**El juego.** Es «Real Life Simulator», un juego de Roblox para todos los públicos. Vives una vida entera en la ciudad ficticia de Valmar: naces, eres bebé, vas al colegio (Los Pinos), al instituto, quizá a la universidad, trabajas, tienes casa y, al final, de mayor, miras atrás. Las misiones son «cosas que te pasan en la vida» y tus decisiones cambian relaciones, recuerdos y escenas posteriores. En paralelo hay una línea fantástica y cómica, la «Saga de la Grieta»: una raja de luz en el cielo, el inventor Cosme (tu vecino del garaje), su robot Pip, su antiguo socio Cósimo y el Consorcio MegaVerso. Se juega mucho en móvil.")
	w()
	w("**El motor de cinemáticas.** Las escenas son líneas de tiempo con pistas: cámara, actores que entran y salen andando, gestos, miradas, diálogo, rótulos, música, ambiente y luz. Los planos con nombre son: General, Medio, PrimerPlano, PPP (primerísimo primer plano), Hombro (por encima del hombro de uno hacia otro), DosPlanos, Lateral, Reacción (la cara de quien escucha), Seguir (la cámara sigue a alguien), Inserto (detalle de un objeto), Dolly (la cámara se acerca o se aleja), Pan (giro horizontal) y Tilt (giro vertical). La música cambia por intensidad (Nada, Descubrimiento, Íntima, Tensión, Resolución, Tema). Cada frase puede llevar: a quién se habla, plano, gesto, una pausa con un gesto («beat») y condiciones (solo sale si el jugador hizo algo antes). Los cambios de etapa son montajes de unos 36 s con «fotos vivas» de tus recuerdos.")
	w()
	w("**Cómo leer el guion.**")
	w("- Está en orden de juego: capítulo → misión (con su identificador, p. ej. `Cole01_PrimerDia`) → pasos numerados (Paso 3, Paso 5.2…). Tras cada paso, entre comillas, el objetivo que ve el jugador en pantalla. «Lugar» y «En escena» solo se indican cuando cambian.")
	w("- «**Lucía:** texto» es quien habla. «Tú» es el jugador. _Narrador_ en cursiva son textos sin personaje (narración, transiciones, rótulos).")
	w("- «Mamá/Papá» y «Abu» dependen de la casa donde naces (Mamá o Papá; Abu Rosa o Abu Tomás). «[tu nombre]» es el nombre del jugador. «o/a» es el género del jugador (sale la forma que toque).")
	w("- _(si …)_ delante de una frase o de una opción = variante: solo sale si se cumple esa condición (una decisión, una marca, un recuerdo, una relación).")
	w("- ❓ es una pregunta al jugador y ➤ cada respuesta posible, con su efecto y las frases a las que lleva (la rama).")
	w("- 🎬 son las cinemáticas o escenas de cámara, con su música, reparto, planos, rótulos (🪧) y frases. _[plano …, gesto …]_ son las acotaciones actuales.")
	w("- 💬 son comentarios sueltos de un personaje al pasar; 🖐 lo que pasa al usar un objeto; 🗨 charlas opcionales.")
	w()
	w("**Reparto principal.**")
	w()
	for _, l in castSummary() do
		w(l)
	end
	w()
	w("**Lo que te pido.** Lee todo el guion y respóndeme con:")
	w()
	w("1. **Mejoras de guion:** diálogos más naturales, ritmo (escenas que se alargan o se quedan cortas), coherencia entre misiones y voz propia de cada personaje (que se reconozca quién habla sin ver el nombre).")
	w("2. **Cinemáticas:** qué escenas o pasos convertirías en cinemática y cómo: qué planos usarías (de la lista de arriba) en qué frases, qué música o intensidad, quién entra y sale, y qué gesto o silencio pondrías.")
	w("3. **Momentos que faltan:** escenas emotivas, giros, recompensas emocionales o momentos en que algún personaje debería recordar lo que hizo el jugador antes.")
	w("4. **Errores e incoherencias:** contradicciones, personajes que saben cosas que no deberían, frases repetidas, condiciones que no encajan, cambios de tono bruscos.")
	w("5. **Formato de la respuesta:** propuestas CONCRETAS agrupadas por misión, indicando siempre el identificador de la misión y el número de paso (por ejemplo: «`Cole01_PrimerDia` · Paso 15 (Cena): cambiar la frase de Abu por…; plano PrimerPlano de Abu; música Íntima»). Si propones una frase nueva, escríbela entera y di quién la dice. Empieza por las 10 mejoras más importantes de todo el juego y luego ve misión por misión.")
	w()
	w("Reglas: todo debe ser apto para todos los públicos (es Roblox: nada de violencia explícita, contenido adulto ni lenguaje ofensivo), sin marcas, productos, famosos ni lugares reales, en español de España, con frases cortas (máximo unos 150 caracteres por bocadillo) y sin dobletes de género (usa «o/a» o frases neutras).")
	if partsNote then
		w()
		w(partsNote)
	end
	w()
	w("## FIN DEL PROMPT · el guion empieza aquí")
	w()
end

---------------------------------------------------------------------
-- Generación
---------------------------------------------------------------------
-- Cada sección (y cada misión dentro) se escribe a su propio trozo, para poder repartirlo en partes
local function capture(fn: () -> ()): string
	local saved = out
	out = {}
	fn()
	local text = table.concat(out, "\n")
	out = saved
	return text
end

type Block = { Section: Section, Head: string, Missions: { { Id: string, Text: string } }, Tail: string }
local blocks: { Block } = {}
for _, sec in sections do
	local block: Block = { Section = sec, Head = "", Missions = {}, Tail = "" }
	block.Head = capture(function()
		w("# " .. sec.Title)
		w()
		if sec.Intro then
			sec.Intro()
		end
	end)
	for _, mid in sec.Missions do
		table.insert(block.Missions, {
			Id = mid,
			Text = capture(function()
				renderMission(mid)
			end),
		})
	end
	block.Tail = capture(function()
		if sec.Outro then
			sec.Outro()
		end
	end)
	table.insert(blocks, block)
end

local function blockText(b: Block): string
	local parts = { b.Head }
	for _, m in b.Missions do
		table.insert(parts, m.Text)
	end
	table.insert(parts, b.Tail)
	return table.concat(parts, "\n")
end

local function chars(s: string): number
	return utf8.len(s) or #s
end

---------------------------------------------------------------------
-- Comprobación: frases en los datos vs. frases exportadas
---------------------------------------------------------------------
local principal: { string } = {}
for _, sec in sections do
	for _, mid in sec.Missions do
		table.insert(principal, mid)
	end
end

local dataLines, dataMissing, dataAsks = 0, {}, 0
local function countData(lines: any, where: string)
	for _, l in lines or {} do
		if type(l) ~= "table" then
			continue
		end
		if l.Ask then
			dataAsks += 1
			if not exported[l] then
				table.insert(dataMissing, where .. ": pregunta " .. tostring(l.Ask))
			end
			for _, o in l.Options or {} do
				countData(o.Then, where)
			end
		elseif l.T then
			dataLines += 1
			if not exported[l] then
				table.insert(dataMissing, where .. ": " .. tostring(l.T))
			end
		end
	end
end
local missionLines = 0
for _, mid in principal do
	local q = Quests[mid]
	for name, d in (q and q.Dialogues) or {} do
		countData(d.Lines or d, mid .. "." .. name)
	end
end
missionLines = dataLines
-- Comentarios sueltos (Bark de los actores, avisos Nudge, CaughtLine): únicos por misión
local dataBarks = 0
for _, mid in principal do
	local seenBark: { [string]: boolean } = {}
	local function scan(steps: any)
		for _, st in steps or {} do
			for _, a in st.Actors or {} do
				if type(a) == "table" and a.Bark and not seenBark[a.Bark] then
					seenBark[a.Bark] = true
					dataBarks += 1
				end
			end
			if type(st.Nudge) == "table" and st.Nudge.T then
				dataBarks += 1
			end
			if st.CaughtLine then
				dataBarks += 1
			end
			scan(st.Steps)
		end
	end
	scan(Quests[mid] and Quests[mid].Steps)
end
-- Escenas que lanzan las misiones principales y los capítulos (cuentan todas sus frases, con variantes)
local sceneRefs: { [string]: boolean } = {}
local function collectScenes(node: any, seen: { [any]: boolean })
	if type(node) ~= "table" or seen[node] then
		return
	end
	seen[node] = true
	if node.Type == "Cinematic" and type(node.Id) == "string" then
		sceneRefs[node.Id] = true
	end
	if node.Type == "Transition" and type(node.Cinematic) == "string" then
		sceneRefs[node.Cinematic] = true
	end
	if type(node.Scene) == "string" then
		sceneRefs[node.Scene] = true
	end
	for _, v in node do
		collectScenes(v, seen)
	end
end
for _, mid in principal do
	collectScenes(Quests[mid], {})
end
for _, id in CHAPTER_ORDER do
	local c = Chapters[id]
	if c.IntroCinematic then
		sceneRefs[c.IntroCinematic] = true
	end
	if c.OutroCinematic then
		sceneRefs[c.OutroCinematic] = true
	end
end
local sceneCount = 0
for id in sceneRefs do
	sceneCount += 1
	local hap = HappeningIndex.get(id)
	if hap then
		local function tracks(t: any)
			for _, l in (t and t.Lines) or {} do
				if l.Text or l.TextKey or l.T then
					dataLines += 1
					if not exported[l] then
						table.insert(dataMissing, "escena " .. id .. ": " .. tostring(l.Text or l.TextKey))
					end
				end
			end
			countData(t and t.Dialogue, "escena " .. id)
		end
		tracks(hap.Tracks)
		for _, v in hap.Variants or {} do
			tracks(v.Tracks)
		end
	elseif Cinematics[id] then
		for _, l in Cinematics[id].Lines or {} do
			dataLines += 1
			if not exported[l] then
				table.insert(dataMissing, "cinemática " .. id .. ": " .. tostring(l.TextKey))
			end
		end
	end
end

-- Lo que queda fuera (para decirlo en el documento)
local excluded: { [string]: number } = {}
local principalSet = {}
for _, mid in principal do
	principalSet[mid] = true
end
local excludedTotal = 0
for id, q in Quests do
	if not principalSet[id] then
		local t = tostring(q.Type or (if q.DayPlan then "Día normal generado" elseif q.Kind == "Side" then "Secundaria" else "Otra"))
		t = t:match("^([^·%(]+)") or t
		t = t:gsub("%s+$", "")
		if q.DayPlan then
			t = "Día normal generado (Jornada)"
		elseif not Quests[id].Chapter and Chapters.Nino_Puente and table.find(Chapters.Nino_Puente.Main, id) then
			t = "Capítulo desactivado (puente antiguo)"
		end
		excluded[t] = (excluded[t] or 0) + 1
		excludedTotal += 1
	end
end

---------------------------------------------------------------------
-- Documento completo
---------------------------------------------------------------------
local function header(): string
	return capture(function()
		w("# Real Life Simulator · Guion de la historia principal")
		w()
		w("_Generado automáticamente desde los datos del juego con `lune run scripts/audit/exportar-dialogos.luau` (no editar a mano: se sobrescribe)._")
		w()
	end)
end

local function contents(): string
	return capture(function()
		w("## Índice (orden de juego)")
		w()
		for _, b in blocks do
			local ids = {}
			for _, m in b.Missions do
				table.insert(ids, "`" .. m.Id .. "`")
			end
			w("- **" .. b.Section.Title .. "**: " .. table.concat(ids, ", "))
		end
		w()
		local ex = {}
		for _, k in sortedPairs(excluded) do
			table.insert(ex, ("%s (%d)"):format(k, excluded[k]))
		end
		w(("_Fuera de este guion (no son historia principal): %d misiones: %s._"):format(excludedTotal, table.concat(ex, "; ")))
		w()
	end)
end


local body = {}
for _, b in blocks do
	table.insert(body, blockText(b))
end
local bodyText = table.concat(body, "\n")

local checkText = capture(function()
	w("## Comprobación")
	w()
	w(("- Misiones principales exportadas: %d (prólogo, capítulos y saga)."):format(#principal))
	w(("- Frases de diálogo en los datos de esas misiones: %d; en sus %d escenas de cámara: %d; total: %d."):format(missionLines, sceneCount, dataLines - missionLines, dataLines))
	w(("- Frases exportadas (cada una una vez): %d. Sin exportar: %d."):format(dataLines - #dataMissing, #dataMissing))
	w(("- Preguntas al jugador: %d exportadas de %d en los datos. Comentarios sueltos y avisos: %d exportados de %d."):format(stats.Asks, dataAsks, stats.Barks, dataBarks))
	if #stats.Missing > 0 then
		w("- Referencias que no están en los datos: " .. table.concat(stats.Missing, ", "))
	end
	w()
end)

local main = table.concat({ header(), capture(function()
	fullPrompt(nil)
end), contents(), bodyText, checkText }, "\n")
local mainPath = OUT_DIR .. "/" .. OUT_NAME .. ".md"
fs.writeFile(mainPath, main)

print(("%s: %d caracteres"):format(mainPath, chars(main)))
print(("Misiones principales: %d · frases en datos: %d (misiones %d + escenas %d, %d escenas) · sin exportar: %d"):format(
	#principal,
	dataLines,
	missionLines,
	dataLines - missionLines,
	sceneCount,
	#dataMissing
))
print(("Preguntas: %d/%d · comentarios/avisos: %d/%d · frases escritas: %d"):format(stats.Asks, dataAsks, stats.Barks, dataBarks, stats.Lines))
for _, m in dataMissing do
	print("  SIN EXPORTAR: " .. m)
end
for _, m in stats.Missing do
	print("  FALTA EN DATOS: " .. m)
end

---------------------------------------------------------------------
-- Partes (si no cabe en un mensaje)
---------------------------------------------------------------------
-- Borra partes viejas
for _, name in fs.readDir(OUT_DIR) do
	if name:match("^" .. OUT_NAME:gsub("%-", "%%-") .. "%-parte%d+%.md$") then
		fs.removeFile(OUT_DIR .. "/" .. name)
	end
end
if chars(main) <= LIMIT then
	return
end

local HEAD_RESERVE = 1200 -- el prompt corto de cada parte
local TOTAL_MARK = "@@TOTAL@@" -- (el número de partes aún no se sabe: se pone al final)
local firstPrompt = capture(function()
	fullPrompt("**Este guion va en varias partes porque es muy largo.** Esta es la PARTE 1 de " .. TOTAL_MARK .. ". Analiza ya esta parte con las instrucciones de arriba (empieza por sus mejoras más importantes). Después te pasaré las siguientes: analiza cada una igual, recordando lo anterior para la coherencia. En la última parte, termina con un resumen global de las 10 mejoras más importantes de todo el juego.")
end)
local parts: { { string } } = { {} }
local sizes = { chars(header()) + chars(firstPrompt) + chars(contents()) }
local function newPart()
	table.insert(parts, {})
	table.insert(sizes, HEAD_RESERVE)
end
local function add(text: string)
	local n = chars(text)
	table.insert(parts[#parts], text)
	sizes[#sizes] += n + 1
end
for _, b in blocks do
	local whole = blockText(b)
	local n = chars(whole)
	if sizes[#sizes] + n <= LIMIT then
		add(whole)
	elseif n + HEAD_RESERVE <= LIMIT then
		newPart()
		add(whole)
	else
		-- El capítulo no cabe entero: se corta por misiones (con la cabecera repetida)
		if sizes[#sizes] + chars(b.Head) > LIMIT * 0.8 then
			newPart()
		end
		add(b.Head)
		for _, m in b.Missions do
			if sizes[#sizes] + chars(m.Text) > LIMIT then
				newPart()
				add("# " .. b.Section.Title .. " (continuación)\n")
			end
			add(m.Text)
		end
		add(b.Tail)
	end
end

local total = #parts
for i, chunks in parts do
	local text
	if i == 1 then
		text = table.concat({ header(), (firstPrompt:gsub(TOTAL_MARK, tostring(total))), contents(), table.concat(chunks, "\n") }, "\n")
	else
		local intro = capture(function()
			w(("# Real Life Simulator · Guion de la historia principal · Parte %d de %d"):format(i, total))
			w()
			w(("**Parte %d de %d, continúa el análisis** del guion de mi juego de Roblox «Real Life Simulator» con las mismas instrucciones de la parte 1: mejoras de guion, ritmo y personajes; qué convertir en cinemática y con qué planos y música; momentos emotivos o giros que faltan; errores e incoherencias (también con lo de las partes anteriores); y propuestas concretas por identificador de misión y número de paso. Todo apto para todos los públicos y sin marcas reales."):format(i, total))
			if i == total then
				w("Es la ÚLTIMA parte: al acabar su análisis, termina con un resumen global de las 10 mejoras más importantes de todo el juego (partes 1 a " .. total .. ").")
			end
			w()
		end)
		text = intro .. "\n" .. table.concat(chunks, "\n")
	end
	if i == total then
		text ..= "\n" .. checkText
	end
	local path = ("%s/%s-parte%d.md"):format(OUT_DIR, OUT_NAME, i)
	fs.writeFile(path, text)
	print(("%s: %d caracteres"):format(path, chars(text)))
end
