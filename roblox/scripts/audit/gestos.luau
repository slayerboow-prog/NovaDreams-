-- Gestos escritos en los guiones reescritos (fase 4 del sistema de cine, docs/cine/auditoria-sistema.md).
--
-- Uso (desde roblox/):
--   lune run scripts/audit/gestos.luau cobertura              cuántas frases de los guiones generados
--                                                             llevan un gesto o una emoción escritos
--   lune run scripts/audit/gestos.luau proponer <IdMision>…   qué acotación se pondría a cada frase
--   lune run scripts/audit/gestos.luau escribir <IdMision>…   las escribe en docs/historia/reescritura/
--                                                             <IdMision>.md (solo en frases sin acotación)
--   (en lugar de los ids, --todas: todos los guiones aplicados)
--
-- Las acotaciones se escriben en la FUENTE (el .md del guion), como las escribiría un guionista:
-- «COSME: (señala) ¡Mira eso!». Después se regenera el guion con scripts/audit/aplicar-reescritura.luau
-- (los guiones de src/shared/LifeStory/Guiones son generados: no se tocan a mano). Cada acotación es
-- una de las palabras que el importador ya entiende (Reescritura.gestureOf): si no la entiende, no se
-- escribe.
--
-- Cómo se elige (Gestos.propose, puro): por lo que dice la frase (saludo, risa, señalar, miedo, enfado,
-- tristeza, sí, no, duda, alegría, sorpresa, pregunta) y, si la frase no dice nada especial, por cómo es
-- quien habla (Cosme en jarras y señalando, Pip con los brazos cruzados…), alternando los de su
-- estilo. Nunca en el narrador ni en una frase que el
-- importador junta con la anterior (dos frases cortas seguidas de quien habla), para que el guion
-- generado sea el mismo salvo los gestos. Después de escribir se vuelve a leer el guion: si alguna
-- frase cambia (texto, quien habla, cuántas hay), esa acotación se deshace.

local fs = require("@lune/fs")
local process = require("@lune/process")

local Reescritura = require("../lib/Reescritura")

local DIR = "docs/historia/reescritura"
local norm = Reescritura.norm

local Gestos = {}

-- Las palabras que se escriben (todas las entiende Reescritura.gestureOf)
Gestos.Words = {
	Wave = "saluda",
	Laugh = "se ríe",
	Point = "señala",
	Fear = "asustado",
	Angry = "enfadado",
	Sad = "triste",
	Shame = "avergonzado",
	Nod = "asiente",
	No = "niega con la cabeza",
	Shrug = "se encoge de hombros",
	Think = "pensativo",
	Joy = "sonríe",
	Surprise = "sorprendido",
	Ask = "levanta una ceja",
	Crossed = "cruza los brazos",
	Hips = "brazos en jarra",
	Palm = "se lleva la mano a la frente",
	Lean = "se inclina hacia delante",
	Away = "aparta la mirada",
	Nervous = "nervioso",
	Clap = "aplaude",
}

-- Cómo es cada uno cuando no dice nada especial (se va alternando)
Gestos.Styles = {
	Cosme = { "Hips", "Point", "Joy", "Lean" },
	Pip = { "Crossed", "Shrug", "Crossed", "Think" },
	Bigotes = { "Crossed", "Think" },
	Cosimo = { "Joy", "Hips", "Lean" },
	Varkun = { "Think", "Lean", "Away" },
	Abu = { "Joy", "Nod", "Lean" },
	Familia = { "Joy", "Hips", "Nod" },
	Lucia = { "Joy", "Think", "Nod" },
	Ramon = { "Hips", "Crossed", "Nod" },
	Marta = { "Joy", "Nod" },
	Marisa = { "Think", "Nod" },
	Nico = { "Joy", "Shrug", "Point" },
	Sara = { "Joy", "Nod", "Think" },
	Omar = { "Hips", "Shrug", "Joy" },
	Mateo = { "Think", "Nod" },
	Paula = { "Joy", "Point" },
	Dani = { "Shrug", "Joy" },
	Bruno = { "Crossed", "Hips" },
	Ruben = { "Crossed", "Shrug" },
	Vega = { "Think", "Crossed" },
	Leire = { "Joy", "Think" },
	DonEscamas = { "Nervous", "Joy", "Lean" },
	NILDA = { "Think", "Nod" },
	Funcionaria = { "Crossed", "Shrug" },
	Yo = {}, -- (tú: solo si la frase lo pide)
}
Gestos.DefaultStyle = { "Nod", "Think", "Joy" }

-- La frase en minúsculas y sin tildes, CON la puntuación (norm la quita), sin «¡¿«—» delante
local PLAIN = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n", ["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n" }
function Gestos.plain(text: string): string
	local s = text:lower()
	for a, b in PLAIN do
		s = s:gsub(a, b)
	end
	s = s:gsub("%s+", " ")
	-- (lo de delante que no es una letra: ¡ ¿ « — … comillas y espacios)
	while #s > 0 and not s:sub(1, 1):match("%w") do
		local c = s:byte(1)
		local size = if c >= 0xF0 then 4 elseif c >= 0xE0 then 3 elseif c >= 0xC0 then 2 else 1
		s = s:sub(size + 1)
	end
	return s
end

local function has(p: string, list: { string }): boolean
	for _, w in list do
		if p:find(w, 1, true) then
			return true
		end
	end
	return false
end
local function starts(n: string, list: { string }): boolean
	for _, w in list do
		if n:sub(1, #w) == w then
			return true
		end
	end
	return false
end

-- La acotación (clave de Gestos.Words) para una frase, o nil. state: { [speaker]: contador } para
-- alternar las neutras. speaker = clave del reparto ("Cosme", "Yo"…).
function Gestos.propose(speaker: string, text: string, state: { [string]: number }): string?
	if speaker == "Narrador" or speaker == "" or speaker:sub(1, 1) == "@" then
		return nil
	end
	local raw = text
	local n = Gestos.plain(text)
	local p = " " .. n .. " "
	local fw = n:match("^(%a+)") or ""
	local exclaim = raw:find("!", 1, true) ~= nil
	local question = raw:find("?", 1, true) ~= nil
	-- Lo que dice la frase
	if ({ hola = true, adios = true, buenas = true })[fw] or starts(n, { "buenos dias", "hasta luego", "hasta manana", "hasta pronto", "nos vemos" }) or p:find(" bienvenid", 1, true) then
		return "Wave"
	end
	if has(p, { " jaja", " jeje", " ja, ja", " je, je", " que risa" }) then
		return "Laugh"
	end
	if has(p, { " cuidado", " corre ", " corred", " socorro", " agachate", " cubrete", " escondete", " no te muevas", " que es eso", " huye", " al suelo" }) then
		return "Fear"
	end
	if has(p, { " basta ", " basta.", " estoy hart", " como te atreves", " callate", " fuera de aqui", " me tienes hart", " no tiene gracia" }) then
		return "Angry"
	end
	if has(p, { " ni se te ocurra", " ni lo suenes", " ya te lo dije", " te lo dije" }) then
		return "Crossed"
	end
	if ({ mira = true, mirad = true, fijate = true, alli = true, ahi = true, alla = true })[fw] or starts(n, { "por alli", "por ahi", "aqui esta", "eso de ahi" }) or has(p, { " mira eso", " mirad", " alli arriba", " ahi arriba" }) then
		return "Point"
	end
	if has(p, { " lo siento", " echo de menos", " ya no esta", " se ha ido", " nunca volvio", " te voy a echar", " me duele", " que pena", " ojala " }) then
		return "Sad"
	end
	if has(p, { " que verguenza", " me da verguenza", " culpa mia", " me he equivocado", " perdona", " perdon" }) or fw == "uy" or fw == "ups" then
		return "Shame"
	end
	if starts(n, { "otra vez no", "que desastre", "ay, madre", "ay madre" }) then
		return "Palm"
	end
	if starts(n, { "en serio", "como que", "que?", "no puede ser", "madre mia", "anda,", "anda!" }) or ({ imposible = true, vaya = true, ostras = true, increible = true, guau = true, hala = true })[fw] or (question and exclaim) then
		return "Surprise"
	end
	-- («Sí» con tilde es asentir; «Si soy…» sin tilde es una condición)
	local yes = raw:lower():gsub("^[%s%p¡¿«“—]+", ""):sub(1, 3) == "s\xC3\xAD"
	if fw == "si" and not yes then
		fw = ""
	end
	if not question and (({ si = true, vale = true, claro = true, exacto = true, entendido = true, cierto = true, exactamente = true, perfecto = true })[fw] or starts(n, { "de acuerdo", "por supuesto", "eso es", "muy bien", "trato hecho", "hecho." })) then
		return "Nod"
	end
	if not question and ({ no = true, nunca = true, jamas = true })[fw] and n:sub(1, 5) ~= "no se" then
		return "No"
	end
	if not question and starts(n, { "ni hablar", "de eso nada", "para nada" }) then
		return "No"
	end
	if starts(n, { "no se", "quiza", "puede que", "a lo mejor", "bueno,", "da igual", "que mas da", "supongo", "tal vez", "ni idea", "yo que se" }) then
		return "Shrug"
	end
	if ({ mmm = true, hmm = true, mmmm = true, veamos = true, interesante = true, curioso = true })[fw] or starts(n, { "me pregunto", "a ver", "deja que lo piense" }) or raw:match("…%s*$") ~= nil then
		return "Think"
	end
	if has(p, { " genial", " que bien", " bravo", " lo hemos conseguido", " lo conseguimos", " lo has conseguido", " gracias", " me encanta", " perfecto", " enhorabuena", " felicidades", " orgullos" }) then
		return "Joy"
	end
	if question then
		return if speaker == "Yo" then nil else "Ask"
	end
	if speaker == "Yo" then
		return nil
	end
	-- Neutra: según quien habla (se van alternando los de su estilo)
	local count = (state[speaker] or 0) + 1
	state[speaker] = count
	local style = Gestos.Styles[speaker] or Gestos.DefaultStyle
	if #style == 0 then
		return nil
	end
	return style[(count - 1) % #style + 1]
end

-- ¿La frase va con la anterior en el mismo bocadillo? (Reescritura.build junta dos cortas seguidas de
-- quien habla): ahí no se escribe nada, para que el guion generado no cambie
local function len(s: string): number
	return utf8.len(s) or #s
end
local function sameSpeaker(prev: { [string]: any }?, item: { [string]: any }): boolean
	return prev ~= nil and (prev.S == item.S or (prev.Key ~= nil and prev.Key == item.Key))
end

-- Quién habla: el nombre del guion («COSME», «TÚ», «Abuela») → la clave del reparto, o nil
local castByNorm: { [string]: string } = {}
function Gestos.setCast(people: { [string]: any })
	table.clear(castByNorm)
	for key, person in people do
		castByNorm[norm(key)] = key
		if type(person) == "table" and type(person.Name) == "string" then
			castByNorm[norm(person.Name)] = castByNorm[norm(person.Name)] or key
		end
	end
end
local TITLES = { "profe ", "profesora ", "profesor ", "senor ", "senora ", "don ", "dona ", "la ", "el " }
function Gestos.speakerKey(raw: string, hablantes: { [string]: any }?): string?
	if hablantes and type(hablantes[raw]) == "string" then
		return hablantes[raw]
	end
	local bare = raw:gsub("%.+$", ""):gsub("%s*%(.-%)%s*$", "")
	local n = norm(bare)
	if Reescritura.SpeakerAliases[n] then
		return Reescritura.SpeakerAliases[n]
	end
	if castByNorm[n] then
		return castByNorm[n]
	end
	for _, t in TITLES do
		if n:sub(1, #t) == t and castByNorm[n:sub(#t + 1)] then
			return castByNorm[n:sub(#t + 1)]
		end
	end
	return nil
end

-- Frases que el importador junta con otra de forma que esta herramienta no ve (las encontró la
-- comprobación del guion generado: con la acotación, el guion cambiaba de estructura). No se tocan.
Gestos.Skip = {
	Adu01_PrimerContrato = { ["Abu quiere verte."] = true }, -- (Mamá/Papá, tras otra frase de la familia)
	Adu02_Atardecer = { ["Gracias."] = true }, -- (Abu, en la escena de la orilla)
	Adu03_Reencuentro = { ["¿Omar?"] = true, ["¿Todos?"] = true },
	Saga_06_Coser = { ["Y tú…"] = true },
	Saga_07_Costuras = { ["Yo no puedo."] = true },
}

export type Proposal = { Line: number, S: string, T: string, Key: string, Word: string }

-- Las propuestas de un guion (sin tocarlo). hablantes: el de su mapa (opcional)
function Gestos.proposals(source: string, hablantes: { [string]: any }?, id: string?): { Proposal }
	local doc = Reescritura.parse(source)
	local skip = (id and Gestos.Skip[id]) or {}
	local out = {}
	local state = {}
	for _, step in doc.Steps do
		local prev = nil
		for _, item in step.Items do
			if item.K == "Line" then
				local key = type(item.S) == "string" and Gestos.speakerKey(item.S, hablantes) or nil
				item.Key = key
				-- (a lo seguro: solo la primera frase de cada racha de quien habla; las de detrás pueden ir
				-- en su mismo bocadillo y una acotación las separaría. Se probó a mirar también lo largo de
				-- cada frase, como el importador, y el guion generado cambiaba en 17 misiones)
				local merged = sameSpeaker(prev, item)
				if key and type(item.T) == "string" and item.T ~= "" and not item.T:match("^%(") and not Reescritura.isStageText(item.T) then
					-- (se propone para todas, también las que ya llevan acotación: así la cuenta de las
					-- neutras es siempre la misma y volver a escribir no añade nada: idempotente)
					local kind = Gestos.propose(key, item.T, state)
					local word = kind and Gestos.Words[kind]
					if word and item.Gesture == nil and not merged and not skip[item.T] and Reescritura.gestureOf(word) then
						table.insert(out, { Line = item.Line, S = key, T = item.T, Key = kind :: string, Word = word })
					end
				end
				-- (una acotación suelta —«…», «Pausa.»— no es una frase: el importador la quita y junta lo
				-- de antes con lo de después)
				if type(item.T) == "string" and item.T ~= "" and not Reescritura.isStageText(item.T) then
					prev = item
				end
			end
		end
	end
	return out
end

-- Escribe «(acotación) » delante de la frase en su línea del .md. Devuelve la línea nueva o nil.
local function insertAt(line: string, text: string, word: string): string?
	if type(line) ~= "string" then
		return nil
	end
	local head = text:sub(1, math.min(#text, 18))
	-- (sin partir una letra UTF-8)
	while #head > 1 and (head:byte(#head) or 0) >= 0x80 and utf8.len(head) == nil do
		head = head:sub(1, -2)
	end
	local at = line:find(head, 1, true)
	if not at then
		return nil
	end
	-- (si va entre comillas, delante de la comilla)
	for _, q in { "«", "“", '"' } do
		if at > #q and line:sub(at - #q, at - 1) == q then
			at -= #q
			break
		end
	end
	return line:sub(1, at - 1) .. "(" .. word .. ") " .. line:sub(at)
end

-- Lo que el importador lee de cada frase (para comprobar que solo cambia la acotación)
local function readLines(source: string): { { [string]: any } }
	local doc = Reescritura.parse(source)
	local list = {}
	for _, step in doc.Steps do
		for _, item in step.Items do
			if item.K == "Line" then
				table.insert(list, { Line = item.Line, S = item.S, T = item.T, Gesture = item.Gesture })
			end
		end
	end
	return list
end

-- Escribe las propuestas en el guion. Devuelve el texto nuevo, cuántas se han escrito y cuáles.
function Gestos.write(source: string, hablantes: { [string]: any }?, id: string?): (string, number, { Proposal })
	local lines = string.split(source, "\n")
	local original = string.split(source, "\n")
	local before = readLines(source)
	local written: { [number]: Proposal } = {}
	for _, p in Gestos.proposals(source, hablantes, id) do
		local changed = not written[p.Line] and insertAt(lines[p.Line], p.T, p.Word)
		if changed then
			lines[p.Line] = changed
			written[p.Line] = p
		end
	end
	-- Comprobar: las mismas frases, con el mismo texto y quien habla; solo cambia la acotación de las
	-- escritas. Lo que no cuadra se deshace (y se vuelve a comprobar)
	for _ = 1, 30 do
		local after = readLines(table.concat(lines, "\n"))
		local bad: { number } = {}
		local count = math.max(#after, #before)
		for i = 1, count do
			local a, b = after[i], before[i]
			if not a or not b then
				-- (cambia el número de frases: lo escrito desde la primera diferencia, fuera)
				local from = (a and a.Line) or (b and b.Line) or 0
				for line in written do
					if line >= from - 3 then
						table.insert(bad, line)
					end
				end
				break
			end
			local p = written[a.Line]
			if a.S ~= b.S or a.T ~= b.T or a.Line ~= b.Line or (p and a.Gesture ~= p.Word) or (not p and a.Gesture ~= b.Gesture) then
				table.insert(bad, a.Line)
				if b.Line ~= a.Line then
					table.insert(bad, b.Line)
				end
				if not written[a.Line] and not written[b.Line] then
					-- (la frase que cambia no es de las escritas: la culpa es de una de antes)
					local nearest = nil
					for line in written do
						if line <= math.max(a.Line, b.Line) and (nearest == nil or line > nearest) then
							nearest = line
						end
					end
					if nearest then
						table.insert(bad, nearest)
					end
				end
			end
		end
		if #bad == 0 then
			break
		end
		for _, line in bad do
			if written[line] then
				lines[line] = original[line]
				written[line] = nil
			end
		end
	end
	local list = {}
	for _, p in written do
		table.insert(list, p)
	end
	table.sort(list, function(a, b)
		return a.Line < b.Line
	end)
	return table.concat(lines, "\n"), #list, list
end

-- Cobertura de un guion generado: frases (con quien habla, sin el narrador) con A, G o Mood; y lo
-- mismo contando solo las que empiezan un turno (la primera frase de cada uno cuando le toca hablar)
function Gestos.coverage(guion: { [string]: any }): (number, number, number, number)
	local total, acted, turns, turnsActed = 0, 0, 0, 0
	local seen = {}
	local function isLine(t: any): boolean
		return type(t) == "table" and type(t.S) == "string" and type(t.T) == "string"
	end
	local function visit(t: any)
		if type(t) ~= "table" or seen[t] then
			return
		end
		seen[t] = true
		local previous: string? = nil
		for _, v in ipairs(t) do
			if isLine(v) then
				if v.S ~= "Narrador" and v.S ~= previous then
					turns += 1
					if v.A ~= nil or v.G ~= nil or v.Mood ~= nil then
						turnsActed += 1
					end
				end
				previous = v.S
			end
		end
		if isLine(t) and t.S ~= "Narrador" then
			total += 1
			if t.A ~= nil or t.G ~= nil or t.Mood ~= nil then
				acted += 1
			end
		end
		for _, v in t do
			visit(v)
		end
	end
	visit(guion)
	return acted, total, turnsActed, turns
end

-- Leer como el importador (formato libre: nombres del reparto y del mapa). L = scripts/lib/ModuleLoader.
-- Devuelve los Hablantes del mapa de esa misión (o nil). Lo usan esta herramienta y test-reescritura.
local knownNames: { [string]: boolean }? = nil
function Gestos.prepare(L: any, id: string): { [string]: any }?
	if not knownNames then
		local Cast = L.load("src/shared/LifeStory/Cast")
		Gestos.setCast(Cast.People)
		local names = {}
		for key, person in Cast.People do
			names[norm(key)] = true
			if type(person) == "table" and type(person.Name) == "string" then
				names[norm(person.Name)] = true
			end
		end
		knownNames = names
	end
	local mapaPath = DIR .. "/" .. id .. ".mapa"
	local mapa = if fs.isFile(mapaPath .. ".luau") then L.load(mapaPath) else nil
	local known = knownNames :: { [string]: boolean }
	Reescritura.knownSpeaker = function(raw: string): boolean
		local n = norm(raw)
		return known[n] == true or Reescritura.SpeakerAliases[n] ~= nil or (mapa ~= nil and mapa.Hablantes ~= nil and mapa.Hablantes[raw] ~= nil)
	end
	return mapa and mapa.Hablantes
end

local mode = process.args[1]
if mode == nil or not ({ cobertura = true, proponer = true, escribir = true })[mode] then
	return Gestos
end

local L = require("../lib/ModuleLoader")
if mode == "cobertura" then
	local sumA, sumT, sumTA, sumTT = 0, 0, 0, 0
	local files = fs.readDir("src/shared/LifeStory/Guiones")
	table.sort(files)
	for _, file in files do
		if file:match("%.luau$") then
			local id = file:gsub("%.luau$", "")
			local g = L.load("src/shared/LifeStory/Guiones/" .. id)
			local a, t, ta, tt = Gestos.coverage(g)
			sumA += a
			sumT += t
			sumTA += ta
			sumTT += tt
			print(("%-28s %4d / %4d  %3d %%   turnos %4d / %4d  %3d %%"):format(id, a, t, if t > 0 then math.floor(a * 100 / t + 0.5) else 0, ta, tt, if tt > 0 then math.floor(ta * 100 / tt + 0.5) else 0))
		end
	end
	print(("TOTAL %d / %d = %.1f %% · al empezar un turno %d / %d = %.1f %%"):format(sumA, sumT, if sumT > 0 then sumA * 100 / sumT else 0, sumTA, sumTT, if sumTT > 0 then sumTA * 100 / sumTT else 0))
	return
end

local ids = {}
for i = 2, #process.args do
	if process.args[i] == "--todas" then
		-- (todos los guiones aplicados: los que tienen datos generados)
		for _, file in fs.readDir("src/shared/LifeStory/Guiones") do
			if file:match("%.luau$") then
				table.insert(ids, (file:gsub("%.luau$", "")))
			end
		end
	else
		table.insert(ids, process.args[i])
	end
end
table.sort(ids)
local totalWritten = 0
for _, id in ids do
	local path = DIR .. "/" .. id .. ".md"
	local hablantes = Gestos.prepare(L, id)
	local source = fs.readFile(path)
	if mode == "proponer" then
		for _, p in Gestos.proposals(source, hablantes, id) do
			print(("%5d  %-10s (%s) %s"):format(p.Line, p.S, p.Word, p.T:sub(1, 70)))
		end
	else
		local text, n = Gestos.write(source, hablantes, id)
		if n > 0 then
			fs.writeFile(path, text)
		end
		totalWritten += n
		print(("%s: %d acotaciones escritas"):format(id, n))
	end
end
if mode == "escribir" then
	print(("TOTAL: %d acotaciones escritas"):format(totalWritten))
end
