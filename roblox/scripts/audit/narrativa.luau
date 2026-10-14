-- Auditoría narrativa y cinematográfica (estática) de las misiones de la historia.
-- No arranca el juego: lee los datos (Quests + MissionIndex, Chapters, Cast) y saca un informe de lo
-- que el validador no mira porque no es un error de datos, sino de PUESTA EN ESCENA y CONTINUIDAD:
--
--   1. Cadena de cada misión: cómo empieza (capítulo, Offer, Later.Start), pasos, final (Moment,
--      Rewards, Memory) y si tiene escena de cámara (Cinematic / Happening).
--   2. Conversaciones con alguien que HABLA pero no está en la escena del paso (sale en la caja: chat).
--   3. Conversaciones solo de narrador / del jugador (texto sin actuación).
--   4. Saltos del jugador (Teleport) y en qué pasos caen justo después de una conversación (corte seco).
--   5. Actores que desaparecen de golpe entre un paso y el siguiente (SceneService los destruye).
--   6. Frases largas (parrafadas), monólogos (muchas seguidas del mismo), líneas repetidas entre misiones.
--   7. Continuidad: marcas, recuerdos y decisiones que se ESCRIBEN y nadie LEE (en los datos).
--   8. Voz de cada personaje: cuántas frases dice y en cuántas misiones.
--   9. Acotaciones escritas en el texto («(desde lejos)…») y dobletes de género («encargado o encargada»).
--
-- Uso (desde roblox/):  lune run scripts/audit/narrativa.luau [resumen|todo]
--                       lune run scripts/audit/narrativa.luau dialogos <IdMision>   (guion de una misión)
-- Informe completo en docs/historia/auditoria-narrativa-cinematica.md (apartado de anexos).

local process = require("@lune/process")
local H = require("../lib/StoryHarness")
local ROOT, loadModule = H.ROOT, H.loadModule

local Quests = H.Quests
local Chapters = loadModule(ROOT .. "/shared/LifeStory/Chapters")
local Cast = loadModule(ROOT .. "/shared/LifeStory/Cast")
local FULL = process.args[1] == "todo"

-- Modo guion: imprime todas las conversaciones de una misión (quién dice qué, preguntas y ramas)
if process.args[1] == "dialogos" then
	local quest = Quests[process.args[2] or ""]
	if not quest then
		print("Misión desconocida: " .. tostring(process.args[2]))
		process.exit(1)
	end
	local function out(lines: any, indent: string)
		for _, l in lines or {} do
			if type(l) ~= "table" then
				continue
			end
			if l.Ask then
				print(indent .. "? " .. tostring(l.Ask))
				for _, o in l.Options or {} do
					print(indent .. "  > " .. tostring(o.T))
					out(o.Then, indent .. "    ")
				end
			elseif l.T then
				print(indent .. tostring(l.S or "Narrador") .. ": " .. l.T .. (if l.If then "  [If]" else ""))
			end
		end
	end
	local names = {}
	for name in quest.Dialogues or {} do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		print("## " .. name)
		local d = quest.Dialogues[name]
		out(d.Lines or d, "  ")
	end
	process.exit(0)
end

local LONG_LINE = 150 -- caracteres: más es una parrafada en un bocadillo
local MONOLOGUE = 5 -- frases seguidas del mismo personaje

local chapterOf: { [string]: string } = {}
for id, chapter in Chapters do
	for _, questId in chapter.Main or {} do
		chapterOf[questId] = id
	end
	if chapter.Loop then
		chapterOf[chapter.Loop] = id
	end
end

local ids = {}
for id in Quests do
	table.insert(ids, id)
end
table.sort(ids)

-- Quién lanza cada misión (Later.Start en cualquier efecto, Start en diálogos…)
local startedBy: { [string]: { string } } = {}
local function scanStarts(owner: string, node: any, seen: { [any]: boolean })
	if type(node) ~= "table" or seen[node] then
		return
	end
	seen[node] = true
	for k, v in node do
		if (k == "Start" or k == "StartQuest") and type(v) == "string" then
			startedBy[v] = startedBy[v] or {}
			if not table.find(startedBy[v], owner) then
				table.insert(startedBy[v], owner)
			end
		end
		scanStarts(owner, v, seen)
	end
end
for _, id in ids do
	scanStarts(id, Quests[id], {})
end

---------------------------------------------------------------------
-- Continuidad: escrito vs leído
---------------------------------------------------------------------
local written = { Flags = {}, Memories = {}, Choices = {}, Facts = {} }
local read = { Flags = {}, Memories = {}, Choices = {} }
local READ_KEYS = { If = true, Requires = true, IfNot = true, Offer = true, Unless = true, When = true }
local function addTo(set, key, where)
	set[key] = set[key] or {}
	if not table.find(set[key], where) then
		table.insert(set[key], where)
	end
end
local function walk(owner: string, node: any, reading: boolean, seen: { [any]: boolean }, parentKey: any)
	if type(node) ~= "table" or seen[node] then
		return
	end
	seen[node] = true
	-- Un paso de decisión escribe su Key
	if node.Type == "Choice" and type(node.Key) == "string" then
		addTo(written.Choices, node.Key, owner)
	end
	for k, v in node do
		local nowReading = reading or READ_KEYS[k] == true
		if k == "Flags" or k == "NotFlags" then
			if type(v) == "table" then
				for _, flag in v do
					if type(flag) == "string" then
						addTo(if nowReading then read.Flags else written.Flags, flag, owner)
					end
				end
			end
		elseif k == "Memory" and type(v) == "string" and not nowReading then
			addTo(written.Memories, v, owner)
		elseif (k == "Memories" or k == "NotMemories") and type(v) == "table" then
			for _, m in v do
				if type(m) == "string" then
					addTo(if nowReading then read.Memories else written.Memories, m, owner)
				end
			end
		elseif (k == "MemoriesAtLeast" or k == "MemoriesFewer") and type(v) == "table" then
			for _, m in v.Of or {} do
				addTo(read.Memories, m, owner)
			end
		elseif (k == "Choices" or k == "NotChoices") and type(v) == "table" and nowReading then
			for key in v do
				addTo(read.Choices, key, owner)
			end
		elseif k == "Choice" and type(v) == "table" and not nowReading then
			for key in v do
				if type(key) == "string" then
					addTo(written.Choices, key, owner)
				end
			end
		elseif k == "Remember" and type(v) == "table" then
			for _, r in v do
				if type(r) == "table" and r.Fact then
					addTo(written.Facts, tostring(r.Npc) .. "." .. tostring(r.Fact), owner)
				end
			end
		end
		walk(owner, v, nowReading, seen, k)
	end
end
for _, id in ids do
	walk(id, Quests[id], false, {}, nil)
end
for id, chapter in Chapters do
	walk("capítulo " .. id, chapter, false, {}, nil)
end
-- Las escenas del motor (Happenings) también leen (If/IfNot/Variants) y escriben (Effects) la partida
local HappeningIndex = loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
local sceneIds = {}
for id in HappeningIndex.all() do
	table.insert(sceneIds, id)
end
table.sort(sceneIds)
for _, id in sceneIds do
	walk("escena " .. id, HappeningIndex.get(id), false, {}, nil)
end

---------------------------------------------------------------------
-- Escenas: hablantes, saltos, actores
---------------------------------------------------------------------
local function speakersOf(lines: any, out: { [string]: number }, stats: { [string]: any })
	for _, line in lines or {} do
		if type(line) ~= "table" then
			continue
		end
		if line.Ask then
			stats.Asks += 1
			for _, option in line.Options or {} do
				speakersOf(option.Then, out, stats)
			end
		elseif line.T then
			local s = line.S or "Narrador"
			out[s] = (out[s] or 0) + 1
			stats.Lines += 1
			local len = utf8.len(line.T) or #line.T
			if len > LONG_LINE then
				table.insert(stats.Long, { S = s, Len = len, T = line.T })
			end
			if line.A or line.G then
				stats.Acted += 1
			end
			if line.If then
				stats.Conditional += 1
			end
			if s == stats.LastS then
				stats.Run += 1
				if stats.Run >= MONOLOGUE and not stats.MonologueMarked then
					stats.MonologueMarked = true
					table.insert(stats.Monologues, s)
				end
			else
				stats.LastS = s
				stats.Run = 1
				stats.MonologueMarked = false
			end
			table.insert(stats.All, { S = s, T = line.T })
		end
	end
end

local function newStats()
	return { Lines = 0, Asks = 0, Acted = 0, Conditional = 0, Long = {}, Monologues = {}, All = {}, Run = 0 }
end

local report = {}
local offScreen = {} -- { Quest, Step, Dialogue, Speakers }
local narratorOnly = {}
local hardCuts = {}
local popOuts = {}
local globalLines: { [string]: { string } } = {}
local voice: { [string]: { Lines: number, Quests: { [string]: boolean }, Samples: { string } } } = {}
local totals = { Quests = 0, Steps = 0, Scenes = 0, Talks = 0, Cinematics = 0, Teleports = 0, Lines = 0, Acted = 0, Conditional = 0, Long = 0 }

local function actorSet(step: any): { [string]: boolean }
	local set = {}
	for _, a in step.Actors or {} do
		if type(a) == "table" and a.Npc then
			set[a.Npc] = true
		end
	end
	return set
end

-- Personajes que traen otros sistemas aunque no estén en Actors (la familia en casa, los del colegio)
local SchoolLife = loadModule(ROOT .. "/shared/LifeStory/SchoolLife")
local function broughtElsewhere(npc: string): boolean
	return SchoolLife.livesAtSchool and SchoolLife.livesAtSchool(npc) or false
end

for _, id in ids do
	local quest = Quests[id]
	totals.Quests += 1
	local dialogues = quest.Dialogues or {}
	local stats = newStats()
	local row = {
		Id = id,
		Kind = quest.Kind,
		Chapter = chapterOf[id] or quest.Chapter or "-",
		Steps = 0,
		Scenes = 0,
		Talks = 0,
		Cine = 0,
		Teleports = 0,
		Start = "",
		End = "",
	}
	-- Cómo empieza
	local starts = {}
	if chapterOf[id] then
		table.insert(starts, "capítulo")
	end
	if quest.Offer then
		table.insert(starts, if quest.Offer.Place then "Offer:" .. tostring(quest.Offer.Place) elseif quest.Offer.Event then "Offer:" .. tostring(quest.Offer.Event) else "Offer")
	end
	if quest.Canon then
		table.insert(starts, "canon")
	end
	if startedBy[id] then
		table.insert(starts, "Later/Start")
	end
	if quest.DayPlan then
		table.insert(starts, "DayPlan")
	end
	row.Start = table.concat(starts, "+")
	if row.Start == "" then
		row.Start = "¿?"
	end
	local ends = {}
	if quest.Moment or quest.MomentKey then
		table.insert(ends, "momento")
	end
	if quest.Rewards then
		table.insert(ends, "premio")
	end
	if quest.Memory then
		table.insert(ends, "recuerdo")
	end
	row.End = table.concat(ends, "+")

	local steps = quest.Steps or {}
	local prev: any = nil
	local prevWasScene = false
	local prevCovers = false -- el paso anterior tapa la pantalla (Transition / Cinematic): el salto no se ve
	for index, step in steps do
		row.Steps += 1
		totals.Steps += 1
		local where = ("%s#%d"):format(id, index)
		local actors = actorSet(step)
		if step.Teleport then
			row.Teleports += 1
			totals.Teleports += 1
			if (prevWasScene or step.Type == "Scene") and not prevCovers and step.Type ~= "Transition" then
				table.insert(hardCuts, { Where = where, Type = step.Type, To = if type(step.Teleport) == "table" then step.Teleport.Place else step.Teleport })
			end
		end
		if step.Type == "Cinematic" or step.Cinematic then
			row.Cine += 1
			totals.Cinematics += 1
		end
		local dlgName = step.Dialogue
		if step.Type == "Scene" then
			row.Scenes += 1
			totals.Scenes += 1
		elseif step.Type == "Talk" then
			row.Talks += 1
			totals.Talks += 1
		end
		if dlgName and dialogues[dlgName] then
			local spk = {}
			local s2 = newStats()
			speakersOf(dialogues[dlgName].Lines or dialogues[dlgName], spk, s2)
			local missing = {}
			local real = 0
			for s in spk do
				if s ~= "Yo" and s ~= "Narrador" then
					real += 1
					if not actors[s] and not (step.Type == "Talk" and step.Npc == s) and not broughtElsewhere(s) then
						table.insert(missing, s)
					end
				end
			end
			if #missing > 0 then
				table.sort(missing)
				table.insert(offScreen, { Where = where, Dialogue = dlgName, Missing = table.concat(missing, ",") })
			end
			if real == 0 and s2.Lines > 0 then
				table.insert(narratorOnly, { Where = where, Dialogue = dlgName, Lines = s2.Lines })
			end
		end
		-- Actores que se van de golpe al pasar al siguiente paso
		-- (un paso sin Actors deja la escena vacía; una cinemática sin Actors hereda los del paso anterior)
		local inherits = (step.Type == "Cinematic" and step.Actors == nil)
		if prev and prev.Actors and not inherits then
			local gone = {}
			for npc in actorSet(prev) do
				if not actors[npc] then
					table.insert(gone, npc)
				end
			end
			if #gone > 0 and not step.Teleport then
				table.sort(gone)
				table.insert(popOuts, { Where = where, Gone = table.concat(gone, ","), Empty = step.Actors == nil })
			end
		end
		prevWasScene = step.Type == "Scene" or step.Type == "Talk"
		prevCovers = step.Type == "Transition" or step.Type == "Cinematic"
		if not inherits then
			prev = step
		end
	end
	-- Estadística de todas sus conversaciones
	local names = {}
	for name in dialogues do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local d = dialogues[name]
		local spk = {}
		speakersOf(if type(d) == "table" then (d.Lines or d) else nil, spk, stats)
		for s, n in spk do
			voice[s] = voice[s] or { Lines = 0, Quests = {}, Samples = {} }
			voice[s].Lines += n
			voice[s].Quests[id] = true
		end
	end
	for _, entry in stats.All do
		local text = entry.T
		if (utf8.len(text) or #text) >= 25 then
			globalLines[text] = globalLines[text] or {}
			if not table.find(globalLines[text], id) then
				table.insert(globalLines[text], id)
			end
		end
		local v = voice[entry.S]
		if v and #v.Samples < 3 and (utf8.len(text) or #text) > 30 then
			table.insert(v.Samples, text)
		end
	end
	totals.Lines += stats.Lines
	totals.Acted += stats.Acted
	totals.Conditional += stats.Conditional
	totals.Long += #stats.Long
	row.Lines = stats.Lines
	row.Acted = stats.Acted
	row.Cond = stats.Conditional
	row.Long = #stats.Long
	row.Mono = #stats.Monologues
	table.insert(report, row)
end

---------------------------------------------------------------------
-- Salida
---------------------------------------------------------------------
local function pct(a, b)
	return if b > 0 then math.floor(a / b * 100 + 0.5) else 0
end

print("# Auditoría narrativa (estática)\n")
print(("Misiones %d · pasos %d · escenas (Scene) %d · charlas (Talk) %d · cinemáticas %d · saltos del jugador %d"):format(
	totals.Quests, totals.Steps, totals.Scenes, totals.Talks, totals.Cinematics, totals.Teleports))
print(("Frases %d · con gesto marcado (A/G) %d (%d%%) · que dependen de lo vivido (If) %d (%d%%) · parrafadas >%d car. %d"):format(
	totals.Lines, totals.Acted, pct(totals.Acted, totals.Lines), totals.Conditional, pct(totals.Conditional, totals.Lines), LONG_LINE, totals.Long))

print("\n## 1. Cadena por misión (inicio · pasos · escenas/charlas/cine · saltos · final)\n")
print("| Misión | Tipo | Capítulo | Empieza por | Pasos | Scene | Talk | Cine | Teleport | Frases | Gesto | If | Parraf. | Monól. | Final |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for _, r in report do
	if FULL or r.Kind == "Main" or r.Steps >= 4 then
		print(("| %s | %s | %s | %s | %d | %d | %d | %d | %d | %d | %d | %d | %d | %d | %s |"):format(
			r.Id, tostring(r.Kind), r.Chapter, r.Start, r.Steps, r.Scenes, r.Talks, r.Cine, r.Teleports, r.Lines, r.Acted, r.Cond, r.Long, r.Mono, r.End))
	end
end

print(("\n## 2. Hablan sin estar en la escena del paso (%d) — su frase sale en la caja, sin cuerpo ni mirada\n"):format(#offScreen))
for i, o in offScreen do
	if FULL or i <= 60 then
		print(("- %s (%s): %s"):format(o.Where, o.Dialogue, o.Missing))
	end
end

print(("\n## 3. Conversaciones solo de narrador o del jugador (%d)\n"):format(#narratorOnly))
for i, o in narratorOnly do
	if FULL or i <= 60 then
		print(("- %s (%s): %d frases"):format(o.Where, o.Dialogue, o.Lines))
	end
end

print(("\n## 4. Saltos del jugador pegados a una conversación sin pantalla que los tape (%d) — corte seco sin fundido\n"):format(#hardCuts))
for _, o in hardCuts do
	print(("- %s (%s) → %s"):format(o.Where, tostring(o.Type), tostring(o.To)))
end

print(("\n## 5. Actores que desaparecen de golpe al cambiar de paso (%d)\n"):format(#popOuts))
for i, o in popOuts do
	if FULL or i <= 80 then
		print(("- %s: %s%s"):format(o.Where, o.Gone, if o.Empty then " (el paso no tiene reparto: se van todos)" else ""))
	end
end

print("\n## 6. Frases repetidas en varias misiones\n")
local dups = {}
for text, where in globalLines do
	if #where > 1 then
		table.insert(dups, { T = text, W = where })
	end
end
table.sort(dups, function(a, b)
	return #a.W > #b.W
end)
for i, d in dups do
	if FULL or i <= 30 then
		print(("- «%s» → %s"):format(d.T, table.concat(d.W, ", ")))
	end
end
print(("(%d frases repetidas)"):format(#dups))

print("\n## 7. Continuidad: se escribe y nadie lo lee en los datos\n")
for _, kind in { "Flags", "Memories", "Choices" } do
	local list = {}
	for key, owners in written[kind] do
		if not read[kind][key] then
			table.insert(list, key .. " (" .. table.concat(owners, ",") .. ")")
		end
	end
	table.sort(list)
	local total = 0
	for _ in written[kind] do
		total += 1
	end
	print(("### %s: %d de %d sin leer en los datos"):format(kind, #list, total))
	for i, line in list do
		if FULL or i <= 400 then
			print("- " .. line)
		end
	end
end
do
	local list = {}
	for key, owners in written.Facts do
		table.insert(list, key .. " (" .. table.concat(owners, ",") .. ")")
	end
	table.sort(list)
	print(("### Remember (hechos de NPC, solo los lee el código con recall): %d"):format(#list))
	for _, line in list do
		print("- " .. line)
	end
end

print("\n## 8. Voz de cada personaje (frases · misiones · ejemplos)\n")
local people = {}
for s, v in voice do
	local n = 0
	for _ in v.Quests do
		n += 1
	end
	table.insert(people, { S = s, Lines = v.Lines, Quests = n, Samples = v.Samples })
end
table.sort(people, function(a, b)
	return a.Lines > b.Lines
end)
for i, p in people do
	if FULL or i <= 45 then
		local bio = Cast.People and Cast.People[p.S] and Cast.People[p.S].Bio or (Cast[p.S] and Cast[p.S].Bio) or ""
		print(("- **%s** · %d frases · %d misiones · %s"):format(p.S, p.Lines, p.Quests, bio))
		for _, sample in p.Samples do
			print("    > " .. sample)
		end
	end
end

print("\n## 9. Acotaciones escritas en el texto y dobletes de género\n")
local directions, doublets = {}, {}
for _, id in ids do
	local seen = {}
	local function scanLines(lines: any)
		for _, line in lines or {} do
			if type(line) ~= "table" or seen[line] then
				continue
			end
			seen[line] = true
			for _, option in line.Options or {} do
				scanLines(option.Then)
			end
			local text = line.T
			if type(text) == "string" then
				if string.find(text, "^%(") or string.find(text, "%((desde[^)]*)%)") or string.find(text, "%((al teléfono)%)") then
					table.insert(directions, ("%s · %s: %s"):format(id, tostring(line.S or "Narrador"), text))
				end
				-- Palabras seguidas: «encargado o encargada», «bienvenida, bienvenido» (raíz de 3 letras o más)
				local words = {}
				for raw in string.gmatch(text, "%S+") do
					table.insert(words, (string.lower((string.gsub(raw, "[,.;:¡!¿?«»…()]", "")))))
				end
				for i = 1, #words - 1 do
					local a, b, c = words[i], words[i + 1], words[i + 2]
					local stemA = string.match(a, "^(...+)[oa]$")
					if stemA and b == "o" and c and string.match(c, "^(...+)[oa]$") == stemA and c ~= a then
						table.insert(doublets, ("%s · %s: «%s o %s»"):format(id, tostring(line.S or "Narrador"), a, c))
					elseif stemA and string.match(b, "^(...+)[oa]$") == stemA and b ~= a then
						table.insert(doublets, ("%s · %s: «%s, %s»"):format(id, tostring(line.S or "Narrador"), a, b))
					end
				end
			end
		end
	end
	for _, d in Quests[id].Dialogues or {} do
		scanLines(if type(d) == "table" then (d.Lines or d) else nil)
	end
end
print(("### Acotaciones (%d) — la acción va escrita en vez de hecha por el actor"):format(#directions))
for i, line in directions do
	if FULL or i <= 40 then
		print("- " .. line)
	end
end
print(("\n### Dobletes de género (%d)"):format(#doublets))
for _, line in doublets do
	print("- " .. line)
end

---------------------------------------------------------------------
-- 10. Continuidad leída por el CÓDIGO (no por los datos)
---------------------------------------------------------------------
-- El apartado 7 solo mira los datos de las misiones. Una marca o un recuerdo puede leerlo el código
-- (StoryContext, SchoolLife, el diario…): aquí se separa lo que de verdad nadie lee.
print("\n## 10. Continuidad: lo «sin leer» del apartado 7, separando lo que sí lee el código\n")
do
	local DATA_DIRS = { [ROOT .. "/shared/LifeStory/Misiones"] = true }
	local DATA_FILES = { [ROOT .. "/shared/LifeStory/Quests.luau"] = true }
	local sources: { { Path: string, Text: string } } = {}
	local fs = require("@lune/fs")
	local function collect(dir: string)
		if DATA_DIRS[dir] then
			return
		end
		for _, name in fs.readDir(dir) do
			local path = dir .. "/" .. name
			if fs.isDir(path) then
				collect(path)
			elseif name:match("%.luau$") and not DATA_FILES[path] then
				table.insert(sources, { Path = path:gsub("^" .. ROOT .. "/", ""), Text = fs.readFile(path) })
			end
		end
	end
	collect(ROOT)
	local function readByCode(key: string): string?
		local quoted, dotted = '"' .. key .. '"', "." .. key
		for _, source in sources do
			local text = source.Text
			local at = text:find(quoted, 1, true)
			if not at then
				local dot = text:find(dotted, 1, true)
				-- (.Clave seguida de algo que no sea letra: Flags.Clave, Memories.Clave)
				if dot then
					local after = text:sub(dot + #dotted, dot + #dotted)
					if not after:match("[%w_]") then
						at = dot
					end
				end
			end
			if at then
				return source.Path
			end
		end
		return nil
	end
	for _, kind in { "Flags", "Memories", "Choices" } do
		local nobody, byCode = {}, {}
		for key, owners in written[kind] do
			if not read[kind][key] then
				local where = readByCode(key)
				if where then
					table.insert(byCode, ("%s (→ %s)"):format(key, where))
				else
					table.insert(nobody, key .. " (" .. table.concat(owners, ",") .. ")")
				end
			end
		end
		table.sort(nobody)
		table.sort(byCode)
		print(("### %s: %d no los lee nadie · %d solo el código"):format(kind, #nobody, #byCode))
		for i, line in nobody do
			if FULL or i <= 60 then
				print("- " .. line)
			end
		end
		if FULL then
			for _, line in byCode do
				print("- (código) " .. line)
			end
		end
	end
end

---------------------------------------------------------------------
-- 11. Progreso de la cinematización (fase 2, §6.1 de la auditoría)
---------------------------------------------------------------------
-- Cuenta los campos NUEVOS (todos opcionales) del formato congelado en la §6.1, por etapa, para ver
-- cuánto se ha escenificado: escenas escritas a mano (Stage), líneas con interlocutor (To), pausa (Pause,
-- Beat), plano pedido (Shot), gesto/emoción marcados (A/G), entradas y salidas andando (Enter/Exit),
-- saltos tapados (Teleport con Fade) y cinemáticas del motor nuevo (Happenings) frente a las viejas.
-- Y los problemas que deberían BAJAR: hablan fuera de escena, actores que desaparecen, cortes secos.
print("\n## 11. Progreso de la cinematización por etapa (campos nuevos de la §6.1)\n")
do
	local HappeningIndex = loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
	local Cinematics = loadModule(ROOT .. "/shared/LifeStory/Cinematics")
	local STAGES = { "Bebe", "Nino", "Adolescente", "AdultoJoven", "Adulto", "-" }
	local function stageOf(id: string): string
		local chapter = chapterOf[id] and Chapters[chapterOf[id]]
		local stage = chapter and chapter.Stage and chapter.Stage.Min
		if not stage then
			local req = Quests[id].Requires
			stage = req and req.Stage and req.Stage.Min
		end
		return if stage and table.find(STAGES, stage) then stage else "-"
	end
	local function bucket()
		return {
			Scenes = 0, Staged = 0, Lines = 0, Narrator = 0, To = 0, Pause = 0, Shot = 0, Acted = 0,
			Enter = 0, Exit = 0, Teleports = 0, Faded = 0, CineNew = 0, CineOld = 0, OffScreen = 0, PopOuts = 0, HardCuts = 0,
		}
	end
	local byStage: { [string]: any } = {}
	for _, stage in STAGES do
		byStage[stage] = bucket()
	end
	local total = bucket()
	local function add(stage: string, key: string, n: number?)
		byStage[stage][key] += n or 1
		total[key] += n or 1
	end
	local function countLines(stage: string, lines: any, seen: { [any]: boolean })
		for _, line in lines or {} do
			if type(line) ~= "table" or seen[line] then
				continue
			end
			seen[line] = true
			for _, option in line.Options or {} do
				countLines(stage, option.Then, seen)
			end
			if line.T then
				add(stage, "Lines")
				if (line.S or "Narrador") == "Narrador" then
					add(stage, "Narrator")
				end
				if line.To then
					add(stage, "To")
				end
				if line.Pause or line.Beat then
					add(stage, "Pause")
				end
				if line.Shot then
					add(stage, "Shot")
				end
				if line.A or line.G then
					add(stage, "Acted")
				end
			end
		end
	end
	for _, id in ids do
		local quest = Quests[id]
		local stage = stageOf(id)
		local seen = {}
		for _, d in quest.Dialogues or {} do
			countLines(stage, if type(d) == "table" then (d.Lines or d) else nil, seen)
		end
		local function scanSteps(steps: any)
			for _, step in steps or {} do
				if type(step) ~= "table" then
					continue
				end
				if step.Type == "Scene" then
					add(stage, "Scenes")
					if step.Stage then
						add(stage, "Staged")
					end
				end
				if step.Teleport then
					add(stage, "Teleports")
					if type(step.Teleport) == "table" and (step.Teleport.Fade or step.Teleport.Walk) then
						add(stage, "Faded")
					end
				end
				if step.Type == "Cinematic" or step.Cinematic then
					local cid = step.Id or step.Cinematic
					if type(cid) == "string" and HappeningIndex.has(cid) then
						add(stage, "CineNew")
					elseif type(cid) == "string" and Cinematics[cid] then
						add(stage, "CineOld")
					end
				end
				for _, actor in step.Actors or {} do
					if type(actor) == "table" then
						if actor.Enter then
							add(stage, "Enter")
						end
						if actor.Exit then
							add(stage, "Exit")
						end
					end
				end
				scanSteps(step.Steps)
			end
		end
		scanSteps(quest.Steps)
	end
	local function questOf(where: string): string
		return (where:match("^(.-)#"))
	end
	for _, o in offScreen do
		add(stageOf(questOf(o.Where)), "OffScreen")
	end
	for _, o in popOuts do
		add(stageOf(questOf(o.Where)), "PopOuts")
	end
	for _, o in hardCuts do
		add(stageOf(questOf(o.Where)), "HardCuts")
	end
	print("| Etapa | Scene | a mano (Stage) | Frases | Narrador | To | Pausa | Shot | A/G | Enter | Exit | Saltos (tapados) | Cine nuevo/viejo | Fuera de escena ↓ | Desaparecen ↓ | Cortes secos ↓ |")
	print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	local function row(name: string, b: any)
		print(("| %s | %d | %d | %d | %d%% | %d | %d | %d | %d (%d%%) | %d | %d | %d (%d) | %d/%d | %d | %d | %d |"):format(
			name, b.Scenes, b.Staged, b.Lines, pct(b.Narrator, b.Lines), b.To, b.Pause, b.Shot, b.Acted, pct(b.Acted, b.Lines),
			b.Enter, b.Exit, b.Teleports, b.Faded, b.CineNew, b.CineOld, b.OffScreen, b.PopOuts, b.HardCuts))
	end
	for _, stage in STAGES do
		if byStage[stage].Lines > 0 or byStage[stage].Scenes > 0 then
			row(if stage == "-" then "(sin etapa)" else stage, byStage[stage])
		end
	end
	row("**Total**", total)
	local happenings = 0
	for _ in HappeningIndex.all() do
		happenings += 1
	end
	print(("\nEscenas del motor nuevo escritas: %d (grupos: %s) · cinemáticas viejas: %d"):format(happenings, table.concat(HappeningIndex.Groups or {}, ", "), (function()
		local n = 0
		for _, def in Cinematics do
			if type(def) == "table" and def.Duration then
				n += 1
			end
		end
		return n
	end)()))
end
