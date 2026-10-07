-- Reescritura: lee un guion reescrito (docs/historia/reescritura/<IdMision>.md), lo valida y genera
-- el guion de la misión para el juego (shared/LifeStory/Guiones/<IdMision>.luau, ver GuionOverlay).
--
-- Lo usa scripts/audit/aplicar-reescritura.luau (la herramienta) y scripts/test-reescritura.luau.
--
--   Reescritura.parse(texto)                    -> doc (misión, pasos, planos, frases, elecciones…)
--   Reescritura.build(doc, juego, mapa)         -> guion (datos), informe (lo aplicado y lo adaptado)
--   Reescritura.serialize(guion)                -> el código Luau del módulo generado
--
-- El formato es el del encargo (MISION / PASO n [Tipo] @ Lugar / Reparto / Musica / PLANO / Nombre: frase
-- / ELECCION) y tolera las desviaciones habituales: comillas tipográficas, «→», «MISIÓN», «PASO 1.1»,
-- «PASO n · TÍTULO», «En escena:», diálogos en dos líneas («Profe Lucía:» + «—frase»), «Tú:», «Pausa.»,
-- «🪧 RÓTULO:», «Si x = y:», «Condición: …», «OBJETIVO(S):», «Efecto: a · b», separadores «⸻», bloques
-- (MINIJUEGO, SFX, CHARLA OPCIONAL, FLAG DE MEMORIA, MOMENTO DE BIOGRAFÍA…).
--
-- `mapa` (opcional, docs/historia/reescritura/<IdMision>.mapa.luau) corrige lo que no se puede adivinar:
--   Pasos     = { ["1"] = 1, ["1.1"] = "2.1", ["7"] = false }   PASO del guion -> paso del juego
--               (n, "n.m" = hijo de un Group, false = no se aplica: va al informe)
--   Sujetos   = { Valmar = "Grande:PrologoInicio", Tornillo = "Lugar:PrologoTornillo", Silueta = "Cosme" }
--   Hablantes = { ["Dependienta"] = "Libreria_Dependiente" }
--   Variables = { ropa = { Choice = "Ropa" }, ayudaste_a_mateo = { Flag = "AyudasteAMateo" } }
--   Dialogos  = { ["5"] = "Sueno" }       en qué conversación van las frases de un PASO
--   Rotulos   = { ["9"] = "Prologo_Cierre" }  conserva los rótulos de esa cinemática vieja en la nueva
--   SinGenero = { "texto exacto" }          frases que NO hay que pasar a {o/a}
--   Prefijo   = "Prologo"                    prefijo de los ids de las escenas nuevas

-- Palabras que empiezan una frase dicha y acaban en -a/-e como un verbo («Para que…», «Ese es…»)
-- Principios de narración («Sus ojos brillan.», «Un pato de goma gira…», «Dentro se ve…»)
local NARR_START = {}
for _, w in { "su", "sus", "un", "una", "unos", "unas", "otro", "otra", "dentro", "detras", "despues", "entonces", "mientras", "lentamente", "de", "en", "al", "del", "fuera", "arriba", "abajo", "alrededor", "finalmente", "luego", "poco" } do
	NARR_START[w] = true
end
-- Títulos de plano en mayúsculas («INSERTO», «PRIMER PLANO DE COSME»): no cierran una elección
local CAMERA_WORDS = {}
for _, w in { "inserto", "primer plano", "primerplano", "general", "plano general", "medio", "plano medio", "reaccion", "hombro", "contraplano", "dos planos", "dosplanos", "lateral", "seguir", "dolly", "pan", "tilt", "ppp", "camara", "pausa", "silencio", "corte", "corte a negro", "fundido" } do
	CAMERA_WORDS[w] = true
end
local STAGE1 = {}
for _, w in { "sonrie", "asiente", "suspira", "duda", "silencio", "pausa", "mira", "rie", "traga", "parpadea", "tose", "calla", "niega", "gira", "senala", "beat", "corte", "fundido", "negro", "oscuridad", "clac", "clonk", "bip", "boom", "zas", "plof", "crack", "estornuda", "bosteza", "risas", "aplausos", "primerplano", "inserto", "reaccion", "dosplanos", "lateral", "seguir", "dolly", "tilt", "ppp", "todos", "familia", "camara", "general", "medio", "hombro", "llora", "grita", "salta", "corre" } do
	STAGE1[w] = true
end
local NOT_VERB = {}
for _, w in { "para", "a", "pero", "que", "porque", "esta", "este", "ese", "esa", "nunca", "siempre", "ahora", "donde", "como", "cuando", "nadie", "nada", "toda", "oye", "venga", "vale", "hasta", "desde", "entre", "sobre", "contra", "bueno", "madre", "padre", "tarde", "noche", "otra", "otre", "alguna", "ninguna", "cada", "una", "de", "ya", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "noventa", "fuera", "espera", "toma", "venga", "genial", "perfecte", "quieta", "alerta", "mentira", "verdade", "nadie" } do
	NOT_VERB[w] = true
end

local Reescritura = {}

Reescritura.PlanoTypes = {
	General = true,
	Medio = true,
	PrimerPlano = true,
	PPP = true,
	Hombro = true,
	DosPlanos = true,
	Lateral = true,
	Reaccion = true,
	Seguir = true,
	Inserto = true,
	Dolly = true,
	Pan = true,
	Tilt = true,
}
-- Música del guion -> intensidad de StoryAudio (Sequencer.Intensities)
Reescritura.Music = {
	Calma = "Descubrimiento",
	Tension = "Tension",
	Emocion = "Intima",
	Accion = "Tension",
	Epico = "Tema",
	Comedia = "Descubrimiento",
}
Reescritura.MAX_LINE = 140

---------------------------------------------------------------------
-- Texto
---------------------------------------------------------------------
local ACCENTS = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n", ["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n", ["Ü"] = "u" }

local function trim(s: string): string
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function norm(s: string): string
	s = s:lower()
	for a, b in ACCENTS do
		s = s:gsub(a, b)
	end
	s = s:gsub("[%c%p]", " "):gsub("%s+", " ")
	return trim(s)
end
Reescritura.norm = norm
function Reescritura.deepClone(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = Reescritura.deepClone(v)
	end
	return out
end
-- Notas de dirección que se cuelan como frases: «Si reportaje = Anonimo, Vega observa…», «No bloquear el
-- juego.», «Esto deberá tener valor en futuras misiones.», «Celebran juntos.», «Ambos sonríen.»
local function looksLikeDirection(s: string): boolean
	if s:find("«", 1, true) or s:find("?", 1, true) or s:find("!", 1, true) then
		return false
	end
	local n = " " .. norm(s) .. " "
	if s:match("^Si%s") and s:find("=", 1, true) then
		return true
	end
	-- («PrimerPlano.», «Inserto.»: un plano suelto)
	local bare = n:gsub("%s", "")
	if bare == "primerplano" or bare == "inserto" or bare == "general" or bare == "reaccion" or bare == "dosplanos" or bare == "hombro" or bare == "ppp" or bare == "seguir" or bare == "dolly" or bare == "tilt" then
		return true
	end
	-- («2. Ve a los personajes actuando.»: una lista numerada del guion)
	if s:match("^%d+[%.%)]%s") then
		return true
	end
	-- («Esto permite que su arco…», «Esto refuerza que…»: una nota para el equipo)
	local e1, e2 = n:match("^ (%S+) (%S+)")
	if e1 == "esto" and e2 and ({ permite = true, puede = true, hara = true, refuerza = true, sirve = true, ayuda = true, demuestra = true, convierte = true, crea = true, establece = true, introduce = true, prepara = true, genera = true, transmite = true, refleja = true, representa = true, muestra = true, marca = true, cierra = true, abre = true, conecta = true, sustituye = true })[e2] then
		return true
	end
	-- («No acelerar las escenas…», «No hacerlo como chiste.»: una instrucción)
	local w1, w2 = n:match("^ (%S+) (%S+)")
	if w1 == "no" and w2 and (w2:match("[aei]r$") or w2:match("[aei]rl[oae]s?$")) then
		return true
	end
	-- («No hace ninguna broma.», «No contesta.»: lo que alguien no hace)
	if w1 == "no" and w2 and ({ hace = true, dice = true, contesta = true, responde = true, sonrie = true, mira = true, habla = true })[w2] then
		return true
	end
	-- («Pequeño silencio.», «Silencio largo.»)
	if w1 == "silencio" or w1 == "pausa" or ((w1 == "pequeno" or w1 == "largo" or w1 == "breve") and (w2 == "silencio" or w2 == "pausa")) then
		return true
	end
	for _, w in { " debera ", " deberan ", " debe ", " deben ", " bloquear ", " futuras misiones ", " el jugador ", " la jugadora ", " gameplay ", " camara ", " plano ", " escena ", " escenas ", " presentarla ", " presentarlo " } do
		if n:find(w, 1, true) then
			return true
		end
	end
	local fw = n:match("^ (%S+)") or ""
	if fw == "ambos" or fw == "ambas" or fw == "mientras" then
		return true
	end
	-- («Preparación: Calma»: la música de una parte)
	for _, mus in { "calma", "tension", "emocion", "accion", "epico", "comedia" } do
		if n:match(" " .. mus .. " $") and s:find(":", 1, true) then
			return true
		end
	end
	if s:find("->", 1, true) or s:find("→", 1, true) then
		return true -- («General -> Hombro -> PrimerPlano»: una lista de planos)
	end
	-- (un verbo en plural al principio, en una línea corta: «Celebran juntos.», «Sonríen.»)
	local words = 0
	for _ in s:gmatch("%S+") do
		words += 1
	end
	-- («Estudiantes pasan alrededor.»: alguien en plural haciendo algo)
	local sw = n:match("^ %S+ (%S+)") or ""
	if words <= 4 and fw:match("s$") and #fw >= 5 and #sw >= 4 and (sw:match("an$") or sw:match("en$")) and not NOT_VERB[fw] then
		return true
	end
	if words <= 2 and s:match("^%u") and #fw >= 6 and (fw:match("an$") or fw:match("en$")) and not NOT_VERB[fw] and fw ~= "alguien" and fw ~= "tambien" then
		return true
	end
	return false
end

-- Quita comillas de los extremos: “…”, «…», "…"
local function unquote(s: string): string
	s = trim(s)
	for _, pair in { { "“", "”" }, { "«", "»" }, { '"', '"' }, { "„", "“" }, { "‘", "’" } } do
		if s:sub(1, #pair[1]) == pair[1] and s:sub(-#pair[2]) == pair[2] and #s > #pair[1] + #pair[2] then
			return trim(s:sub(#pair[1] + 1, -#pair[2] - 1))
		end
	end
	return s
end
Reescritura.unquote = unquote

local function len(s: string): number
	return utf8.len(s) or #s
end

-- «→», «—>», «=>» -> «->»
local function arrows(s: string): string
	return (s:gsub("→", "->"):gsub("⟶", "->"):gsub("—>", "->"):gsub("=>", "->"))
end

-- «— frase», «– frase» o «- frase» → «frase» (la raya es de varios bytes: no vale una clase [—–])
local function dashed(s: string): string?
	for _, dash in { "—", "–", "-" } do
		if s:sub(1, #dash) == dash then
			return (s:sub(#dash + 1):gsub("^%s+", ""))
		end
	end
	return nil
end

local function camel(s: string): string
	local out = {}
	for word in norm(s):gmatch("%S+") do
		table.insert(out, word:sub(1, 1):upper() .. word:sub(2))
	end
	return table.concat(out)
end
Reescritura.camel = camel

---------------------------------------------------------------------
-- 1. Leer el guion
---------------------------------------------------------------------
-- Cabeceras de bloque (lo que va debajo se guarda como notas del bloque, para el informe)
local BLOCKS = {
	{ "^minijuego", "Minijuego" },
	{ "^sfx", "Sfx" },
	{ "^charla opcional", "Charla" },
	{ "^comentarios al pasar", "Comentarios" },
	{ "^flag de memoria", "Memoria" },
	{ "^flags?$", "Memoria" },
	{ "^sistema de memoria", "Memoria" },
	{ "^consecuencias futuras", "Consecuencias" },
	{ "^momento de biografia", "Momento" },
	{ "^al terminar", "Momento" },
	{ "^cierre del capitulo", "Cierre" },
	{ "^objetivo desbloqueado", "Desbloqueo" },
	{ "^direccion", "Direccion" },
	{ "^opcion [a-z] ", "Rama" },
	{ "^notas?", "Nota" },
}

local function blockOf(head: string): string?
	local n = norm(head)
	for _, rule in BLOCKS do
		if n:find(rule[1]) then
			return rule[2]
		end
	end
	return nil
end

-- ¿Parece «Nombre:» de quien habla? (1-4 palabras, con mayúscula)
local NOT_SPEAKERS = {
	resumen = true,
	reparto = true,
	musica = true,
	["en escena"] = true,
	objetivo = true,
	objetivos = true,
	eleccion = true,
	condicion = true,
	efecto = true,
	efectos = true,
	transicion = true,
	rotulo = true,
	nota = true,
	mision = true,
	paso = true,
	plano = true,
	sfx = true,
	minijuego = true,
	consecuencias = true,
	gameplay = true,
	jugabilidad = true,
	mecanica = true,
	control = true,
	controles = true,
}
-- Cabeceras de nota que parecen «Nombre:» (instrucciones del guion, no personajes)
local NOT_PERSON = { "al ", "segun", "cuando", "tras ", "despues", "antes", "durante", "mientras", "sistema", "resultado", "descripcion", "ejemplo", "actualizar", "guardar", "registrar", "desbloquear", "opcion", "cinematica", "nota", "efecto", "pista", "recompensa", "logro", "momento", "titulo", "texto", "hud", "interfaz", "objetivo", "variable", "flag", "marca", "condicion", "consecuencia", "camara", "plano", "ambiente", "sonido", "luz", "iluminacion", "direccion", "qa", "transicion", "musica", "fin ", "inicio", "estado", "si ", "en caso", "comentario", "importante", "regla", "variante", "rama", "ruta", "puntuacion", "nota final", "premio", "alternancia", "numero", "objetos", "sino", "utilizar", "hay", "conservar", "aparece", "escribe", "mantener", "independientemente", "casa", "parada", "instituto", "feria", "teatro", "investigacion", "fotografia", "cumpleanos", "final", "hospital", "mural", "bromas", "recreo", "debe", "deben", "primero", "segundo", "tercero", "finalmente", "usar", "utilizar", "registrar", "entonces", "de repente", "despues de", "mas tarde", "debajo", "encima", "detras", "dentro", "en el ", "en ella", "nivel", "recibes", "recibe ", "primera pagina", "segunda pagina", "ultima pagina", "pantalla", "cartel", "letrero", "nota:", "elementos", "escena", "lugar", "decorado", "desde", "cada", "aprobado", "sobresaliente", "suspenso", "notable", "insuficiente", "con nota", "nota " }
-- Cabecera de una opción: «A) texto» o «OPCIÓN A — «texto»» (esta solo dentro de una elección)
local function optionHead(s: string, inChoice: boolean): (string?, string?)
	local letter, text = s:match("^([A-H])[%)%.]%s*(.*)$")
	if letter then
		return letter, text
	end
	if inChoice then
		-- «A — «No. Es de Lucía.»»
		local l3, rest3 = s:match("^([A-H])%s+\226\128\148%s*(.+)$")
		if not l3 then
			l3, rest3 = s:match("^([A-H])%s+\226\128\147%s*(.+)$")
		end
		if not l3 then
			l3, rest3 = s:match("^([A-H])%s+%-%s+(.+)$")
		end
		if l3 and (rest3:match("^«") or rest3:match("^\"")) then
			return l3, rest3
		end
	end
	if inChoice and norm(s):match("^opcion%s+[a-h]%f[^%w]") then
		-- (el original: «OPCIÓN A — «texto»»: la letra es la primera mayúscula suelta tras la palabra)
		local l2, rest = s:match("^%S+%s+([A-Ha-h])%s*(.*)$")
		if l2 then
			rest = rest:gsub("^[:%s]+", "")
			rest = rest:gsub("^\226\128\148%s*", ""):gsub("^\226\128\147%s*", ""):gsub("^%-%s*", "")
			-- (solo si es una frase entre comillas: «OPCIÓN A — LOS ARTISTAS» es una rama, no una respuesta)
			if rest:match("^«") or rest:match("^\"") then
				return l2:upper(), rest
			end
		end
	end
	return nil, nil
end
local function isDecisionHead(n: string): boolean
	return n:find("^eleccion") ~= nil or n:find("^decision del jugador") ~= nil or n == "decision" or n:find("^decision:") ~= nil
end
local function speakerHead(s: string): (string?, string?)
	local name, rest = s:match("^([^:]+):%s*(.*)$")
	if not name or len(name) > 32 then
		return nil, nil
	end
	name = trim((name:gsub("%*", "")))
	if name == "" or not (name:match("^%u") or name:match("^Á") or name:match("^É") or name:match("^Í") or name:match("^Ó") or name:match("^Ú") or name:match("^Ñ") or name:match("^¿")) or name:find("—", 1, true) or name:find("%d%d") then
		return nil, nil
	end
	local words = 0
	for _ in name:gmatch("%S+") do
		words += 1
	end
	if words > 4 then
		return nil, nil
	end
	local n = norm(name)
	if NOT_SPEAKERS[n] or n:find("^si ") or n:find("^opcion") or blockOf(name) or name:upper() == name and (words > 1 or len(name) > 6) and not (Reescritura.knownSpeaker and Reescritura.knownSpeaker(name)) then
		return nil, nil
	end
	-- «Se descubren: …», «Puede recordar: …»: una frase, no un nombre (la segunda palabra va en minúscula)
	local second = name:match("^%S+%s+(%S+)")
	-- «Lucía lee:», «Omar dice:», «Nico susurra:»: quien habla es el primero (el verbo sobra)
	local SPEECH = { lee = true, dice = true, susurra = true, grita = true, responde = true, pregunta = true, contesta = true, lee_en_voz_alta = true, murmura = true, anuncia = true, explica = true }
	if second and words == 2 and SPEECH[norm(second)] then
		return name:match("^(%S+)"), rest
	end
	if second and second:match("^%l") and not second:match("^de$") and not second:match("^del$") then
		return nil, nil
	end
	if name:match("^%u%)") then
		return nil, nil -- («B) «Defensa»: …» es una opción, no alguien que habla)
	end
	for _, prefix in NOT_PERSON do
		if n:sub(1, #prefix) == prefix then
			return nil, nil
		end
	end
	return name, rest
end

export type Item = { [string]: any }
export type Step = { [string]: any }
export type Doc = { Id: string?, Title: string?, Summary: string?, Steps: { Step }, Blocks: { Item }, Problems: { string } }

function Reescritura.parse(source: string): Doc
	local doc: Doc = { Steps = {}, Blocks = {}, Problems = {} }
	local step: Step? = nil
	local block: Item? = nil -- bloque abierto (sus líneas van dentro)
	local choice: Item? = nil -- elección abierta (sus opciones y efectos)
	local pendingSpeaker: string? = nil -- «Nombre:» sin frase: la frase viene en la línea siguiente
	local cond: string? = nil -- «Si …:» abierto (hasta otro «Si», un plano después de sus frases, una elección o un separador)
	local condLines = 0
	local condAny = false
	local lineNo = 0
	local lastPushed: Item? = nil
	-- «RUTA B · COCINA»: lo que sigue (hasta otra RUTA o el PASO siguiente) solo vale en esa ruta
	local routeCond: string? = nil
	local function push(item: Item)
		item.Line = lineNo
		if routeCond and item.K == "Line" then
			item.RouteIf = routeCond
		end
		if cond and item.K ~= "Blank" then
			condAny = true
		end
		if item.K ~= "Blank" and item.K ~= "Pause" then
			lastPushed = item
		end
		if choice and choice.InlineEnd and #choice.Options > 0 and item.K ~= "Choice" then
			if lineNo <= choice.InlineEnd then
				-- (respuesta dentro de la opción: va a sus frases)
				if item.K ~= "Blank" then
					local option = choice.Options[#choice.Options]
					if option.T == nil and item.K == "Note" then
						option.T = unquote(item.T) -- (el texto de una opción con condición)
						return
					end
					-- «capitan = Yo · valentia +1» justo debajo de la opción (sin «->»): sus efectos
					if item.K == "Note" and #(option.Items or {}) == 0 and (item.T:find("=", 1, true) or item.T:match("[%+%-]%s*%d+%s*$") or item.T:match("[%+%-]%s*%d+%s*·")) then
						table.insert(option.Effects, item.T)
						return
					end
					option.Items = option.Items or {}
					if cond and item.K == "Line" then
						item.If = cond
						condLines += 1
					end
					table.insert(option.Items, item)
				end
				return
			end
			choice = nil
		end
		if choice and #choice.Options == 0 and item.K ~= "Blank" and item.K ~= "Choice" and item.K ~= "Block" then
			-- («Pregunta:» y debajo «¿Qué haces?»: es el texto de la elección)
			if item.K == "Line" and item.S and norm(item.S) == "pregunta" then
				choice.Name = (choice.Name ~= nil and choice.Name ~= "") and choice.Name or unquote(item.T or "")
				return
			end
			-- (frases entre «ELECCION» y la primera opción: la pregunta que se dice antes de elegir)
			if cond and item.K == "Line" then
				item.If = cond
			end
			choice.Lead = choice.Lead or {}
			table.insert(choice.Lead, item)
			return
		end
		if item.K ~= "Blank" and item.K ~= "Choice" then
			choice = nil -- (otra cosa: la elección ya acabó)
		end
		if cond and item.K == "Line" then
			item.If = cond
			condLines += 1
		end
		if block and item.K ~= "Blank" then
			table.insert(block.Items, item)
		elseif step then
			table.insert(step.Items, item)
		else
			table.insert(doc.Blocks, item)
		end
	end
	local function closeBlock()
		block = nil
	end
	-- Elecciones con las respuestas DENTRO de cada opción (A) …, sus frases, B) …, sus frases…): se
	-- reconocen porque hay frases entre una opción y la siguiente. Entonces la última opción llega
	-- hasta el siguiente separador, PASO, ELECCION o bloque. inlineEnd[línea de la ELECCION] = última línea.
	-- Guion en formato libre (sin «PLANO Tipo -> Sujeto»): planos «PLANO 1 — General», nombres sueltos,
	-- frases seguidas de quien habla
	local freeForm = not source:find("\nPLANO%s+%a+%s*%->") and not source:find("^PLANO%s+%a+%s*%->")
	local currentSpeaker: string? = nil
	local pendingPlano: Item? = nil
	local inlineEnd: { [number]: number } = {}
	local siAhead: { [number]: boolean } = {}
	local effectList = false
	local pendingBare = false
	local askNext = false
	local stepSubtitle = false
	local awaitOptionText: any = nil
	local condNext = false
	local lastCond: string? = nil
	do
		local all = {}
		for raw in (source .. "\n"):gmatch("([^\n]*)\n") do
			table.insert(all, trim(arrows(raw:gsub("\r", ""))))
		end
		-- siAhead[línea]: viene otro «Si …:» enseguida (en las 8 líneas siguientes con texto, sin separador):
		-- un plano entre medias no cierra el «Si» de antes (es la otra variante de lo mismo)
		for k = 1, #all do
			local seenLines = 0
			local j = k + 1
			while j <= #all and seenLines < 8 do
				local t = all[j]
				if t ~= "" then
					if t:match("^[⸻]+$") or t:match("^%-%-%-+$") or t:match("^PASO%s") then
						break
					end
					if t:match("^Si%s+.-:%s*$") or t:match("^SI%s") then
						siAhead[k] = true
						break
					end
					seenLines += 1
				end
				j += 1
			end
		end
		local i = 1
		while i <= #all do
			if isDecisionHead(norm(all[i])) then
				local j = i + 1
				local options, content, lastOption = 0, false, nil
				local inline = false
				while j <= #all do
					local s = all[j]
					local ns = norm(s)
					local separator = s:match("^[⸻]+$") or s:match("^%-%-%-+$")
					if separator then
						-- (un separador entre opciones no acaba la elección: «⸻» y luego «B) …»)
						local k = j + 1
						while k <= #all and all[k] == "" do
							k += 1
						end
						if not (all[k] and optionHead(all[k], true)) then
							break
						end
					elseif s:match("^PASO%s") or isDecisionHead(ns) or s:match("^%d+%.%d+%s*[—–%-]") or (blockOf((s:gsub(":%s*$", ""))) and s:match(":%s*$") and not optionHead(s, true)) or (s:upper() == s and s:match("%u%u%u%u") and not optionHead(s, true) and not CAMERA_WORDS[norm(s)] and not s:find("!", 1, true) and not s:find("?", 1, true) and not s:find(":", 1, true)) then
						break
					end
					if s:match("^[A-H][%)%.]%s") or optionHead(s, true) then
						options += 1
						if content and options > 1 then
							inline = true
						end
						lastOption = j
					elseif s ~= "" and not s:match("^%->") and not ns:find("^efectos? ") and options > 0 then
						content = true
					end
					j += 1
				end
				if inline then
					inlineEnd[i] = j - 1
				end
				i = j
			else
				i += 1
			end
		end
	end
	for raw in (source .. "\n"):gmatch("([^\n]*)\n") do
		lineNo += 1
		local s = trim(arrows(raw:gsub("\r", "")))
		s = s:gsub("^%*%*(.-)%*%*$", "%1") -- (negritas de Markdown)
		s = s:gsub("^#+%s*", "")
		local n = norm(s)
		if s == "" or s:match("^[⸻—%-_=*]+$") then
			if pendingSpeaker == nil then
				if s ~= "" and not (cond and not condAny) then
					cond = nil -- (un separador acaba el «Si …:»; una línea en blanco, no; un «Si» sin frases aún, tampoco)
				end
				-- (la elección sigue abierta: a veces las opciones van separadas por líneas en blanco)
				push({ K = "Blank" })
				if block and block.Kind ~= "Rama" and #block.Items > 0 then
					-- (un bloque acaba en la primera línea en blanco después de su contenido)
					block.Closed = true
				end
			end
			continue
		end
		if block and block.Closed then
			closeBlock()
		end
		-- MISION: Id — Título
		local id, title = nil, nil
		if n:find("^mision ") then
			id, title = s:match("^[^:]+:%s*([%w_]+)%s*(.*)$")
			title = title and title:gsub("^[—–%-:%s]+", "")
		end
		if id then
			doc.Id = id
			doc.Title = unquote(title)
			continue
		end
		local summary = s:match("^Resumen:%s*(.*)$")
		if summary then
			doc.Summary = summary
			continue
		end
		-- PASO n [Tipo] @ Lugar   |   PASO n · TÍTULO
		local num, rest = s:match("^PASO%s+([%d%.]+)%s*(.*)$")
		if num then
			num = num:gsub("%.$", "")
			local kind, place = rest:match("^%[(.-)%]%s*@?%s*(.*)$")
			local heading = nil
			if not kind then
				heading = trim(rest)
				for _, sep in { "·", "—", "–", "-", ":" } do
					if heading:sub(1, #sep) == sep then
						heading = trim(heading:sub(#sep + 1))
					end
				end
				-- «PASO 3 · ESCENA — EL RUMOR», «PASO 14 · CINEMÁTICA — LA FOTO»: el tipo sale del título
				local nh = norm(heading)
				kind = if nh:find("cinematica", 1, true) then "Cinematic" elseif nh:find("^escena") then "Scene" elseif nh:find("^transicion") then "Transition" else ""
				place = ""
				local p = heading:match("@%s*(.*)$")
				if p then
					place = p
				end
			end
			step = { Num = num, Type = trim(kind), Place = trim(place), Heading = heading, Cast = {}, Music = {}, Items = {}, Objectives = {}, Line = lineNo }
			table.insert(doc.Steps, step)
			block, choice, pendingSpeaker, cond = nil, nil, nil, nil
			currentSpeaker = nil
			stepSubtitle = true
			routeCond = nil
			continue
		end
		-- Sub-paso sin «PASO»: «9.1 — Mateo» (hereda el lugar, el reparto y la música del PASO)
		local subNum, subRest = s:match("^(%d+%.%d+)%s+(.*)$")
		local subHead = subRest and (dashed(subRest) or (if subRest:sub(1, 2) == "·" then trim(subRest:sub(3)) else subRest))
		if subNum and step and subNum:match("^(%d+)%.") == step.Num:match("^(%d+)") then
			local parent = step
			step = { Num = subNum, Type = parent.Type, Place = parent.Place, Heading = trim(subHead), Cast = table.clone(parent.Cast), Music = table.clone(parent.Music), Items = {}, Objectives = {}, Line = lineNo, Sub = true }
			table.insert(doc.Steps, step)
			block, choice, pendingSpeaker, cond = nil, nil, nil, nil
			currentSpeaker = nil
			stepSubtitle = true
			routeCond = nil
			continue
		end
		local cast = s:match("^Reparto:%s*(.*)$") or s:match("^En escena:%s*(.*)$")
		if cast and step then
			for name in cast:gmatch("[^,;]+") do
				table.insert(step.Cast, trim((name:gsub("%b()", ""))))
			end
			continue
		end
		local music = if n:find("^musica ") or n == "musica" then s:match("^[^:]+:%s*(.*)$") else nil
		if music and step then
			for part in (music .. "->"):gmatch("(.-)%->") do
				part = trim(part)
				if part ~= "" then
					table.insert(step.Music, part)
				end
			end
			continue
		end
		-- PLANO Tipo -> Sujeto | Descripción
		-- «PLANO 3 — PrimerPlano» (formato libre): la descripción va en la línea siguiente
		local fnum, frest = s:match("^PLANO%s+(%d+)%s*(.*)$")
		if fnum and step then
			local fkind = trim(dashed(frest) or frest)
			fkind = (fkind:gsub("%s", ""))
			if Reescritura.PlanoTypes[fkind] then
				push({ K = "Plano", Kind = fkind, Subject = "", Desc = "", Pending = true })
				pendingPlano = step.Items[#step.Items] or (block and block.Items[#block.Items])
				currentSpeaker = nil
				continue
			end
		end
		if pendingPlano and step and not s:match("^%u[%wáéíóúñ]*:%s*$") then
			-- (la línea de debajo del plano: su sujeto y descripción)
			pendingPlano.Desc = s
			pendingPlano.Subject = s
			pendingPlano.Pending = nil
			pendingPlano = nil
			continue
		end
		pendingPlano = nil
		local ptype, prest = s:match("^PLANO%s+(%a+)%s*%->%s*(.*)$")
		if not ptype then
			ptype, prest = s:match("^PLANO%s+(%a+)%s*[:%-]%s*(.*)$")
		end
		if ptype then
			local subject, desc = prest:match("^(.-)%s*|%s*(.*)$")
			subject = subject or prest
			local a, b = subject:match("^(.-)%s*%->%s*(.*)$")
			pendingSpeaker = nil
			if cond and condLines > 0 and not siAhead[lineNo] then
				cond = nil -- (un plano nuevo después de las frases del «Si …:» lo cierra)
			end
			push({ K = "Plano", Kind = ptype, Subject = trim(a or subject), Subject2 = b and trim(b) or nil, Desc = desc or "" })
			continue
		end
		-- «Algo ha aparecido en el gimnasio» justo debajo del PASO: es su subtítulo
		if stepSubtitle and s ~= "" then
			stepSubtitle = false
			if s:match("^«.*»$") then
				push({ K = "Note", T = s })
				continue
			end
		end
		-- «ORIGEN: VALMAR» (todo en mayúsculas, con dos puntos): un texto en una pantalla → lo lee el narrador
		if step and s:upper() == s and s:match("^[^:]+:%s*%S") and s:match("%u%u") and len(s) <= 60 and not s:match("^PLANO") and not isDecisionHead(n) and not blockOf((s:match("^([^:]+)"))) and not optionHead(s, true) and not s:match("^PASO") and not n:find("^musica") and not n:find("^rotulo") and not n:find("^transicion") and not n:find("^objetivo") then
			pendingSpeaker = nil
			push({ K = "Line", S = "Narrador", T = "«" .. s .. "»", Read = true })
			continue
		end
		-- «Cosme +5» suelto (una lista de relaciones): no es una frase
		if s:match("^%S+%s+[%+%-]%d+%.?$") and not s:find("«", 1, true) then
			pendingSpeaker = nil
			push({ K = "Note", T = s })
			continue
		end
		-- «RUTA A · TALLER», «RUTA B — VOLVIÓ A CLASE», «RUTA C»: una rama entera
		do
			local rest = s:match("^RUTA%s+(.*)$")
			if rest and s:upper() == s and step and not rest:match("^DEL?%s") and not rest:match("^AL%s") then
				local name = rest:match("^%u%s+[·:—–%-]+%s*(.+)$") or rest:match("^[·:—–%-]+%s*(.+)$") or rest
				routeCond = "ruta " .. trim(name)
				cond = nil
				push({ K = "Note", T = s })
				continue
			end
		end
		-- (la condición de un «Si:» suelto, en la línea de debajo)
		if condNext and s ~= "" then
			condNext = false
			if not s:find("«", 1, true) and len(s) <= 60 then
				cond = trim((s:gsub("[:%.]$", "")))
				condLines = 0
			condAny = false
				continue
			end
		end
		if awaitOptionText and s ~= "" then
			local o = awaitOptionText
			awaitOptionText = nil
			if s:match("^«.*»$") then
				o.T = unquote(s)
				continue
			end
		end
		-- «DECISIÓN» y debajo «¿Qué haces?» entre comillas: es la pregunta
		if askNext and s ~= "" then
			askNext = false
			local q = s:match("^«(.*)»$")
			if q and choice and not choice.Name then
				choice.Name = q
				continue
			end
		end
		-- «OPCIÓN» suelto y debajo «Estaba junto a la fuente.»: lo que puede responder el jugador
		-- «RÓTULO» solo y debajo «Algo ha cambiado en Valmar.»
		if n == "rotulo" and step then
			push({ K = "Title", T = "" })
			pendingSpeaker = "@rotulo"
			continue
		end
		if n == "opcion" or n == "opcion:" or (not choice and n:match("^opcion [a-h]$")) then
			pendingSpeaker = "Yo"
			pendingBare = false
			continue
		end
		-- «bigotes_habla = true» suelto: un efecto del PASO, no una frase
		if step and s:match("^[%l_][%w_]*%s*=%s*[%w_]+$") and s:find("_", 1, true) then
			-- (debajo de una opción: es de esa opción)
			if choice and #choice.Options > 0 and (not choice.InlineEnd or lineNo <= choice.InlineEnd) then
				table.insert(choice.Options[#choice.Options].Effects, s)
				pendingSpeaker = nil
				continue
			end
			step.Effects = step.Effects or {}
			table.insert(step.Effects, s)
			pendingSpeaker = nil
			continue
		end
		-- ELECCION[ — nombre]:
		if isDecisionHead(n) then
			askNext = true
			-- «ELECCION — ¿Qué cuentas primero?» → la pregunta (si es una pregunta; «— ROPA» es solo un nombre)
			local name = nil
			local dashAt = s:find("—", 1, true) or s:find("–", 1, true)
			if dashAt then
				name = trim((s:sub(dashAt):gsub("^[—–%s]+", ""):gsub(":%s*$", "")))
				if name == "" or not name:find("?", 1, true) then
					name = nil
				end
			end
			cond = nil
			choice = { K = "Choice", Name = name and trim(name) or nil, Options = {}, InlineEnd = inlineEnd[lineNo] }
			push(choice)
			pendingSpeaker = nil
			continue
		end
		-- Opción de una elección: A) "texto" -> efectos
		local letter, otext = optionHead(s, choice ~= nil)
		if letter and choice then
			effectList = false
			local t, eff = otext:match("^(.-)%s*%->%s*(.*)$")
			local option = { Letter = letter, T = unquote(t or otext), Effects = {} }
			-- «A) Si ayudaste_a_mateo:» + «¡He hecho un amigo!» en la línea siguiente: opción con condición
			local ocond = option.T:match("^Si%s+(.-)%s*:$")
			if ocond then
				option.Cond = ocond
				option.T = nil
				awaitOptionText = option -- (el texto viene en la línea de debajo)
			end
			if eff and eff ~= "" then
				table.insert(option.Effects, eff)
			end
			-- «F) Opción universal:» y debajo «Ha sido un rollo.»: lo de debajo es lo que dice la opción
			if option.T and option.T:match(":%s*$") then
				awaitOptionText = option
			end
			table.insert(choice.Options, option)
			continue
		end
		if choice and #choice.Options > 0 then
			local more = s:match("^%->%s*(.*)$") or s:match("^Efectos?:%s*(.*)$")
			if more then
				if more ~= "" then
					table.insert(choice.Options[#choice.Options].Effects, more)
				end
				-- («Efectos:» y debajo una lista «* Cosme +5»)
				effectList = s:match("^Efectos?:%s*$") ~= nil
				continue
			end
			local bullet = effectList and s:match("^[%*%-•]%s+(.*)$")
			if bullet then
				table.insert(choice.Options[#choice.Options].Effects, bullet)
				continue
			end
			if s ~= "" then
				effectList = false
			end
		end
		-- Planos en prosa, en una lista numerada: «1. General del patio lleno de alumnos.»,
		-- «2. Seguir a Nico corriendo…», «5. Primer plano de Lucía»
		local pn, pfirst, prest2 = s:match("^(%d+)[%.%)]%s+(%S+)%s*(.*)$")
		if pn and step then
			local w = norm(pfirst)
			local second = norm(prest2):match("^(%S+)")
			local KIND = { general = "General", medio = "Medio", ppp = "PPP", hombro = "Hombro", lateral = "Lateral", reaccion = "Reaccion", seguir = "Seguir", inserto = "Inserto", dolly = "Dolly", pan = "Pan", paneo = "Pan", tilt = "Tilt", travelling = "Dolly", contraplano = "Hombro" }
			local pk = KIND[w]
			local restText = prest2
			if w == "primer" and second == "plano" then
				pk, restText = "PrimerPlano", prest2:gsub("^%S+%s*", "")
			elseif w == "primerisimo" then
				pk, restText = "PPP", prest2:gsub("^%S+%s+%S+%s*", "")
			elseif w == "plano" and (second == "general" or second == "medio") then
				pk, restText = (if second == "general" then "General" else "Medio"), prest2:gsub("^%S+%s*", "")
			elseif w == "dos" and second == "planos" then
				pk, restText = "DosPlanos", prest2:gsub("^%S+%s*", "")
			end
			if pk then
				local subject = trim((restText:gsub("^de la%s+", ""):gsub("^del%s+", ""):gsub("^de%s+", ""):gsub("^al%s+", ""):gsub("^a la%s+", ""):gsub("^a%s+", ""):gsub("^sobre%s+", ""):gsub("^hacia%s+", ""):gsub("^por%s+", ""):gsub("%.$", "")))
				pendingSpeaker = nil
				if cond and condLines > 0 then
					cond = nil
				end
				push({ K = "Plano", Kind = pk, Subject = subject, Desc = s })
				continue
			end
		end
		-- 🪧 «texto» (rótulo sin la palabra RÓTULO)
		local sign = s:match("^🪧%s*(.+)$")
		if sign and not n:find("rotulo", 1, true) then
			push({ K = "Title", T = unquote(sign) })
			continue
		end
		-- Cabecera de sección en mayúsculas («CIERRE», «EPÍLOGO»): cierra el «Si …:» y el bloque abierto
		if s:upper() == s and s:match("%u%u%u") and not s:find(":", 1, true) and len(s) <= 40 and not blockOf(s) and not s:find("!", 1, true) and not s:find("?", 1, true) and not s:match("^OBJETIVOS?$") and not (freeForm and Reescritura.knownSpeaker and Reescritura.knownSpeaker(s)) then
			cond = nil
			currentSpeaker = nil
			closeBlock()
			push({ K = "Note", T = s })
			continue
		end
		local stepEffect = s:match("^%->%s*(.*)$")
		if stepEffect and step then
			-- (efecto suelto del PASO: «-> pista_sara = true»)
			step.Effects = step.Effects or {}
			table.insert(step.Effects, stepEffect)
			continue
		end
		if n == "pausa" or n == "pausa breve" or n == "pausa larga" or n:find("^silencio$") then
			push({ K = "Pause", Seconds = if n == "pausa breve" then 0.5 elseif n == "pausa larga" then 1.5 else 0.9 })
			continue
		end
		-- 🪧 RÓTULO: texto (o en la línea siguiente entre «»)
		local rotulo = if n:sub(1, 16):find("rotulo", 1, true) and s:find(":", 1, true) then s:match(":%s*(.*)$") else nil
		if rotulo then
			push({ K = "Title", T = unquote(rotulo) })
			pendingSpeaker = "@rotulo"
			continue
		end
		local transition = if n:find("^transicion ") and s:find(":", 1, true) then s:match("^[^:]+:%s*(.*)$") else nil
		if transition then
			push({ K = "Title", T = unquote(transition), Transition = true })
			continue
		end
		local condition = if n:find("^condicion ") and s:find(":", 1, true) then s:match("^[^:]+:%s*(.*)$") else nil
		if condition and step then
			local hasLines = false
			for _, it in step.Items do
				hasLines = hasLines or it.K == "Line" or it.K == "Choice"
			end
			if hasLines then
				-- (a mitad del PASO: vale para lo que viene, como un «Si …:»)
				cond = trim((condition:gsub("%.$", "")))
				condLines = 0
			condAny = false
			else
				step.Cond = trim((condition:gsub("%.$", "")))
			end
			continue
		end
		local ifc = s:match("^Si%s+(.-)%s*:$") or s:match("^Si%s+(.-)%s*:%s*$") or s:match("^SI%s+(.-)%s*:?%s*$")
		if not ifc and len(s) <= 40 and s:match("^Si%s+[^,%.:;¡!¿?…]+$") then
			ifc = s:match("^Si%s+(.+)$") -- («Si iker en el grupo» sin dos puntos)
		end
		if not ifc and len(s) <= 40 and s:match("^Si%s+%l[^,:;¡!¿?…]*%.$") then
			-- («Si hugo con el grupo.»: nombra a alguien o una variable → es una condición; «Si quieres.» se dice)
			local named = s:find("_", 1, true) ~= nil
			for w in s:gmatch("%S+") do
				named = named or (Reescritura.knownSpeaker ~= nil and w:match("^%l") ~= nil and Reescritura.knownSpeaker((w:gsub("%.$", ""))))
			end
			if named then
				ifc = s:match("^Si%s+(.-)%.$")
			end
		end
		-- «Si:» solo y la condición en la línea de debajo («sueno infancia = Medicina»)
		if s == "Si:" or s == "SI:" or s == "Si existe:" or s == "SI EXISTE:" or s == "Si existe" then
			condNext = true
			continue
		end
		if ifc then
			-- «SI NO» / «Si no:» detrás de «SI conoces_a_leire»: lo contrario de la condición de antes
			if norm(ifc) == "no" and lastCond then
				local k, v = lastCond:match("^([%w_ ]-)%s*=%s*(.+)$")
				if k and not lastCond:find(" y ", 1, true) then
					ifc = trim(k) .. " != " .. trim(v)
				elseif not lastCond:find(" y ", 1, true) and not norm(lastCond):find("^no ") then
					ifc = "no " .. lastCond
				end
			end
			cond = ifc
			lastCond = ifc
			condLines = 0
			condAny = false
			continue
		end
		local objective = s:match("^OBJETIVOS?:%s*(.*)$") or s:match("^Objetivos?:%s*(.*)$") or s:match("^OBJETIVOS?()$") and "" or s:match("^Objetivo mostrado:%s*(.*)$")
		if objective and step then
			closeBlock()
			block = { K = "Block", Kind = "Objetivo", Head = s, Items = {} }
			if objective ~= "" then
				table.insert(step.Objectives, unquote(objective))
			end
			push({ K = "Objective", T = objective })
			block = { K = "Block", Kind = "Objetivo", Head = s, Items = {}, Closed = false }
			table.insert(step.Items, block)
			continue
		end
		local listItem = s:match("^[%-•·]%s+(.*)$") or (block and block.Kind == "Objetivo" and s:match("^«.*»$"))
		if listItem and block and block.Kind == "Objetivo" and step then
			currentSpeaker = nil
			table.insert(step.Objectives, unquote(listItem))
			continue
		end
		local kind = blockOf((s:gsub(":%s*$", "")))
		if kind and (s:match(":%s*$") or s:upper() == s or kind == "Rama" or kind == "Charla") then
			closeBlock()
			cond = nil
			block = { K = "Block", Kind = kind, Head = s, Items = {} }
			if step then
				table.insert(step.Items, block)
			else
				table.insert(doc.Blocks, block)
			end
			continue
		end
		-- La frase de un «Nombre:» de la línea anterior (o el texto de un rótulo)
		if pendingSpeaker then
			local text = dashed(s) or s
			if pendingSpeaker == "@rotulo" then
				local last = (if block then block.Items else (step and step.Items or doc.Blocks))
				local title = last[#last]
				if title and title.K == "Title" and title.T == "" then
					title.T = unquote(text)
				elseif title and title.K == "Title" then
					title.Sub = unquote(text)
				end
				pendingSpeaker = nil
				continue
			end
			local nextSpeaker, nextText = speakerHead(s)
			if nextSpeaker and nextText == "" then
				pendingSpeaker = nextSpeaker -- («Andrés:» y debajo otro «Andrés:»: el de abajo es el bueno)
				pendingBare = false
				currentSpeaker = nextSpeaker
				continue
			end
			-- (formato libre: «Omar» y debajo «Saca su bocadillo.»: es una acotación, la frase viene después)
			-- (solo tras un nombre suelto: tras «COSME:» lo de debajo es su frase)
			if freeForm and pendingBare and not s:find("?", 1, true) and not s:find("!", 1, true) and not s:find("«", 1, true) and not s:find("…", 1, true) then
				local fw = s:match("^(%S+)")
				local nwords = 0
				for _ in s:gmatch("%S+") do
					nwords += 1
				end
				local nfw = fw and norm(fw) or ""
				local verbish = fw ~= nil and fw:match("^%u") ~= nil and (nfw:match("a$") or nfw:match("e$")) ~= nil and nwords <= 6 and s:match("%.$") ~= nil and not NOT_VERB[nfw]
				-- («Marca» suelto, sin punto: es un título del guion, no una frase)
				local bare = nwords == 1 and s:match("[%.!%?»…]$") == nil
				local personalWords = false
				local nsl = " " .. norm(s) .. " "
				for _, w in { " yo ", " me ", " mi ", " te ", " tu ", " nos ", " os ", " hola ", " gracias ", " vale " } do
					personalWords = personalWords or nsl:find(w, 1, true) ~= nil
				end
				local stageStart = ({ todos = true, todas = true, el = true, la = true, los = true, las = true, se = true })[nfw] == true
				local lowerStart = s:match("^%l") ~= nil -- («debe cambiar inmediatamente.»: sigue una nota)
				local fw2 = s:match("^(%S+%s+%S+)")
				local startsWithName = (fw ~= nil and Reescritura.knownSpeaker ~= nil and (Reescritura.knownSpeaker(fw) or (fw2 ~= nil and Reescritura.knownSpeaker(fw2)))) or (NARR_START[nfw] == true and not personalWords)
				local narrative0 = nsl:find(" jugador", 1, true) or nsl:find(" camara", 1, true) or nsl:find(" plano ", 1, true)
				if (verbish and not personalWords) or s:match(":%s*$") or bare or startsWithName or narrative0 or lowerStart then
					push({ K = "Note", T = s })
					continue
				end
			end
			if looksLikeDirection(s) then
				push({ K = "Note", T = s }) -- (una nota de dirección debajo de «Familia:»: la frase viene después)
				continue
			end
			if s:match("^%*") then
				push({ K = "Note", T = s }) -- («Ramón:» y debajo una lista de acotaciones: no es su frase)
				continue
			end
			local speaker = pendingSpeaker
			pendingSpeaker = nil
			currentSpeaker = speaker
			local gesture, t = text:match("^%((.-)%)%s*(.*)$")
			push({ K = "Line", S = speaker, T = unquote(t or text), Gesture = gesture })
			continue
		end
		local speaker, text = speakerHead(s)
		-- «Folleto:», «Etiqueta:», «Destino:» (una palabra que no es nadie del reparto) y debajo lo que pone:
		-- es un rótulo que se lee, no alguien que habla
		if speaker and text == "" and not speaker:find("%s") and Reescritura.knownSpeaker and not Reescritura.knownSpeaker(speaker) then
			currentSpeaker = nil
			push({ K = "Note", T = s })
			continue
		end
		if speaker then
			currentSpeaker = speaker
			if text == "" then
				pendingSpeaker = speaker
				pendingBare = false
				continue
			end
			text = dashed(text) or text
			local gesture, t = text:match("^%((.-)%)%s*(.*)$")
			if gesture and t == "" then
				push({ K = "Line", S = speaker, T = "", Gesture = gesture })
			else
				push({ K = "Line", S = speaker, T = unquote(t or text), Gesture = gesture })
			end
			continue
		end
		local dash = dashed(s)
		local last = step and step.Items[#step.Items]
		if dash and last and last.K == "Line" then
			push({ K = "Line", S = last.S, T = unquote(dash) })
			continue
		end
		-- Formato libre: un nombre solo en su línea («Ramón») es quien habla en la siguiente
		if freeForm and step and Reescritura.knownSpeaker and Reescritura.knownSpeaker(s) and not s:match("[%.!%?…]$") then
			pendingSpeaker = s
			pendingBare = true
			currentSpeaker = s
			continue
		end
		-- Formato libre: las frases que siguen a quien habla son suyas (hasta un plano, una acotación o
		-- alguien nuevo). Acotación = una palabra suelta («Sonríe.», «Silencio.») o empieza por un nombre
		if freeForm and currentSpeaker and step and len(s) <= 140 then
			local words = 0
			for _ in s:gmatch("%S+") do
				words += 1
			end
			local first = norm(s):match("^(%S+)")
			local firstTwo = s:match("^(%S+%s+%S+)")
			local starts = first and Reescritura.knownSpeaker and (Reescritura.knownSpeaker(first) or (firstTwo ~= nil and Reescritura.knownSpeaker(firstTwo)))
			-- (una palabra suelta: «Sonríe.», «Silencio.» son acotación; «Treinta.», «Bueno.», «Nunca.» se dicen)
			local single = norm(s):gsub("[%p%s]", "")
			local singleStage = STAGE1[single] or (s:match("^%u") ~= nil and (single:match("a$") or single:match("e$")) ~= nil and not NOT_VERB[single]) or s:match("[%.!%?…»]$") == nil
			local stage = (words == 1 and singleStage and not ({ ["sí."] = true, ["si."] = true, ["no."] = true, ["vale."] = true, ["gracias."] = true, ["claro."] = true, ["ya."] = true })[s:lower()])
				or starts
				or first == "la" or first == "el" or first == "los" or first == "las" or first == "todos" or first == "se"
				or (s:upper() == s and not s:find("!", 1, true) and not s:find("?", 1, true))
			-- (solo si suena a frase dicha: pregunta, exclamación, puntos suspensivos, comillas o primera y
			-- segunda persona; «Mira alrededor.», «Su expresión cambia.» son acotaciones)
			local ns = " " .. norm(s) .. " "
			local personal = false
			for _, w in { " yo ", " me ", " mi ", " mis ", " te ", " tu ", " tus ", " nos ", " os ", " hola ", " si ", " vale ", " bueno ", " pues ", " creo ", " gracias ", " vamos ", " oye ", " claro ", " nuestro ", " nuestra ", " vosotros ", " contigo ", " conmigo ", " aqui ", " lo prometi ", " he ", " has ", " hemos ", " habeis ", " estoy ", " estas ", " estamos ", " soy ", " eres ", " somos ", " usted ", " ustedes ", " vuestro ", " vuestra ", " mio ", " tuyo ", " senor ", " oiga ", " por favor ", " tengo ", " tienes ", " puedo ", " puedes ", " quiero ", " quieres ", " sabes ", " vale ", " venga " } do
				if ns:find(w, 1, true) then
					personal = true
					break
				end
			end
			local marks = s:find("?", 1, true) or s:find("!", 1, true) or s:find("…", 1, true) or s:find("«", 1, true)
			local spoken = (marks ~= nil or personal) and s:match("^[%*%-•]") == nil and s:match("[%.!%?»…]$") ~= nil and not s:match("^No%s+%l+r%s")
			-- («Cara a cara.», «Lo de la limonada estuvo bien.»: frase corta detrás de quien habla, que no
			-- empieza como una acotación (un nombre, «El/La…», «Un/Otro…», un verbo «Mira…/Saca…»), es suya
			if not spoken and words >= 2 and words <= 8 and s:match("[%.]$") and s:match("^[%*%-•]") == nil then
				local fw1 = s:match("^(%S+)") or ""
				local nfw1 = norm(fw1):gsub("[%p]", "")
				local verbish1 = fw1:match("^%u") ~= nil and (nfw1:match("a$") or nfw1:match("e$")) ~= nil and not NOT_VERB[nfw1]
				-- (notas de dirección: «No debe aparecer…», «No hacerlo como chiste.», «Silencio breve.»)
				local second1 = norm(s):match("^%S+%s+(%S+)") or ""
				second1 = second1:gsub("[%p]", "")
				local direction = ns:find(" debe ", 1, true) or ns:find(" deben ", 1, true) or ns:find(" debera ", 1, true)
					or (nfw1 == "no" and (second1:match("[aei]r$") or second1:match("[aei]rl[oa]s?$") or second1:match("[aei]rse$")) ~= nil)
					or STAGE1[nfw1] or nfw1 == "silencio" or nfw1 == "pausa"
				local narrative = direction or ns:find(" jugador", 1, true) or ns:find(" camara", 1, true) or ns:find(" plano", 1, true) or ns:find(" escena", 1, true)
				if not starts and not NARR_START[nfw1] and not verbish1 and not narrative and not ({ la = true, el = true, los = true, las = true, todos = true, se = true })[nfw1] then
					spoken = true
				end
			end
			-- («Treinta.»: una palabra suelta que no es acotación, detrás de quien habla, es suya)
			if words == 1 and not stage and s:match("[%.!%?…]$") then
				local prev = lastPushed
				-- (solo justo detrás de una frase suya o de una pausa: «Mochilas.», «Llaves.» tras una
				-- descripción son un inventario, no una frase)
				local lastNote = prev and prev.K == "Note" and prev.T or ""
				spoken = prev ~= nil and (prev.K == "Line" or (prev.K == "Note" and Reescritura.knownSpeaker ~= nil and Reescritura.knownSpeaker(lastNote:match("^(%S+)") or "")))
			end
			if spoken and not stage and not looksLikeDirection(s) then
				push({ K = "Line", S = currentSpeaker, T = unquote(s) })
				continue
			end
			-- («Mira sus llaves.», «Saca un pequeño llavero.»: acotación corta en medio; quien habla sigue)
			local fw = s:match("^(%S+)")
			local nfw = fw and norm(fw) or ""
			local shortStage = fw ~= nil and fw:match("^%u") ~= nil and (nfw:match("a$") or nfw:match("e$")) ~= nil and words <= 6 and s:match("%.$") ~= nil and not personal and not NOT_VERB[nfw]
			-- (una línea de narración corta a quien habla: mejor perder una frase que poner la narración en
			-- boca de alguien)
			if not stage and not shortStage then
				currentSpeaker = nil
			end
		end
		-- «Primera página:» y debajo «Hoy he decidido…»: un texto que se lee → lo cuenta el narrador
		if not currentSpeaker and step and s:match("^«.+»$") then
			local prev = lastPushed
			local label = prev and prev.K == "Note" and type(prev.T) == "string" and prev.T:match(":%s*$") and len(prev.T) <= 40 and prev.T or nil
			if label then
				local nl = " " .. norm(label) .. " "
				local lw = 0
				for _ in label:gmatch("%S+") do
					lw += 1
				end
				local fw0 = label:match("^(%S+)") or ""
				if lw > 4 or label:match("^%d") or (Reescritura.knownSpeaker and Reescritura.knownSpeaker((fw0:gsub(":$", "")))) then
					label = nil
				else
					for _, w in { " puede ", " debe ", " jugador ", " pensando ", " recordar ", " dice ", " decir ", " si ", " opcion ", " objetivo ", " despues ", " y ", " mision ", " empieza ", " descripcion ", " resumen ", " frase ", " no ", " pregunta ", " ejemplo ", " evitar ", " nunca ", " primera ", " segunda ", " tercera ", " sino ", " sustituye ", " esto ", " biografia ", " registrar ", " guardar " } do
						if nl:find(w, 1, true) then
							label = nil
							break
						end
					end
				end
			end
			if label then
				-- («Texto:», «Título:» no se dicen: solo lo que pone)
				local nlabel = norm(label):gsub("[:%s]+$", "")
				local said = if nlabel == "texto" or nlabel == "titulo" or nlabel == "rotulo" then s else trim(label) .. " " .. s
				push({ K = "Line", S = "Narrador", T = said, Read = true })
				continue
			elseif prev and prev.K == "Line" and prev.Read then
				push({ K = "Line", S = "Narrador", T = s, Read = true })
				continue
			end
		end
		push({ K = "Note", T = s })
	end
	if not doc.Id then
		table.insert(doc.Problems, "falta la línea «MISION: <Id> — <Título>»")
	end
	return doc
end

---------------------------------------------------------------------
-- 2. Del guion a los datos del juego
---------------------------------------------------------------------
-- Gestos por palabras (en la descripción de un PLANO o en la acotación de una frase).
-- A = postura de la frase (Emotion), G = ademán animado, Mood = emoción en las escenas del motor.
local GESTURES = {
	{ "sonrisa desaparece", { A = "Sad", Mood = "Sad" } },
	{ "deja de sonreir", { A = "Sad", Mood = "Sad" } },
	{ "intenta sonreir", { A = "Nervous", Mood = "Nervous" } },
	{ "sonrie", { A = "Happy", Mood = "Joy" } },
	{ "sonrisa", { A = "Happy", Mood = "Joy" } },
	{ "se rie", { G = "Laugh", Mood = "Joy" } },
	{ "rie", { G = "Laugh", Mood = "Joy" } },
	{ "risa", { G = "Laugh", Mood = "Joy" } },
	{ "sorprend", { A = "Surprised", Mood = "Surprise" } },
	{ "abre los ojos", { A = "Surprised", Mood = "Surprise" } },
	{ "completamente quieto", { A = "Surprised", Mood = "Surprise" } },
	{ "levanta una ceja", { A = "Ask" } },
	{ "curiosidad", { A = "Thinking" } },
	{ "duda", { A = "Thinking" } },
	{ "pensativ", { A = "ThinkChin" } },
	{ "seriedad", { A = "Calm", Mood = "Calm" } },
	{ "serio", { A = "Calm", Mood = "Calm" } },
	{ "tranquiliz", { A = "Calm", Mood = "Calm" } },
	{ "senala", { G = "Point" } },
	{ "saluda", { G = "Wave" } },
	{ "aplaude", { A = "Clap" } },
	{ "abraza", { A = "Happy", Mood = "Joy" } },
	{ "emocionad", { A = "Happy", Mood = "Joy" } },
	{ "triste", { A = "Sad", Mood = "Sad" } },
	{ "tristeza", { A = "Sad", Mood = "Sad" } },
	{ "suspira", { A = "Sad" } },
	{ "enfad", { A = "Angry", Mood = "Angry" } },
	{ "cruza los brazos", { A = "ArmsCrossed" } },
	{ "nervios", { A = "Nervous", Mood = "Nervous" } },
	{ "averguenz", { A = "Ashamed", Mood = "Shame" } },
	{ "verguenza", { A = "Ashamed", Mood = "Shame" } },
	{ "asiente", { A = "Nod" } },
	{ "niega", { A = "No" } },
	{ "encoge", { A = "Shrug" } },
	{ "quitar importancia", { A = "Shrug" } },
	{ "miedo", { A = "Nervous", Mood = "Fear" } },
	{ "asust", { A = "Nervous", Mood = "Fear" } },
}
local function gestureOf(text: string?): { [string]: any }?
	if type(text) ~= "string" or text == "" then
		return nil
	end
	local n = " " .. norm(text) .. " "
	for _, rule in GESTURES do
		if n:find(" " .. rule[1], 1, true) then
			return rule[2]
		end
	end
	return nil
end
Reescritura.gestureOf = gestureOf

-- Acotaciones de VOZ o DISTANCIA que StageDirector ya convierte en acción: se dejan al principio de la
-- frase con la forma que reconoce (susurrando, al teléfono, desde lejos…). Devuelve esa acotación o nil.
local VOICE_DIRECTIONS = {
	{ "susurr", "susurrando" },
	{ "bajito", "bajito" },
	{ "en voz baja", "susurrando" },
	{ "baja la voz", "susurrando" },
	{ "telefono", "al teléfono" },
	{ "mensaje", "por mensaje" },
	{ "altavoz", "por el altavoz" },
	{ "desde lejos", "desde lejos" },
	{ "desde la puerta", "desde la puerta" },
	{ "desde el fondo", "desde el fondo" },
	{ "por detras", "por detrás" },
	{ "llorando", "llorando" },
}
local function stagedDirection(text: string): string?
	local n = norm(text)
	for _, rule in VOICE_DIRECTIONS do
		if n:find(rule[1], 1, true) then
			return rule[2]
		end
	end
	return nil
end

-- Correcciones de género en lo que se le dice al jugador (las que se aplican, al informe)
local GENDER = {
	{ "Bienvenido", "Bienvenid{o/a}" },
	{ "bienvenido", "bienvenid{o/a}" },
	{ "Tranquilo", "Tranquil{o/a}" },
	{ "tranquilo", "tranquil{o/a}" },
	{ "Nervioso", "Nervios{o/a}" },
	{ "nervioso", "nervios{o/a}" },
	{ "tú solo", "tú sol{o/a}" },
	{ "Tú solo", "Tú sol{o/a}" },
	{ "explorador", "explorador{/a}" },
	{ "pequeño", "pequeñ{o/a}" },
	{ "Listo", "List{o/a}" },
	{ "listo", "list{o/a}" },
	{ "preparado", "preparad{o/a}" },
	{ "Preparado", "Preparad{o/a}" },
	{ "cansado", "cansad{o/a}" },
	{ "asustado", "asustad{o/a}" },
	{ "Asustado", "Asustad{o/a}" },
	{ "seguro", "segur{o/a}" },
	{ "valiente", "valiente" },
	{ "solito", "solit{o/a}" },
	{ "campeón", "campe{ón/ona}" },
	{ "Campeón", "Campe{ón/ona}" },
	{ "un científico o una científica estupendo/a", "{un científico estupendo/una científica estupenda}" },
	{ "estupendo/a", "estupend{o/a}" },
	{ "más tranquilo", "más tranquil{o/a}" },
	{ "Jefe o jefa", "Jef{e/a}" },
	{ "jefe o jefa", "jef{e/a}" },
	{ "orgulloso/a", "orgullos{o/a}" },
	{ "Orgulloso/a", "Orgullos{o/a}" },
	{ "preparado/a", "preparad{o/a}" },
	{ "Preparado/a", "Preparad{o/a}" },
	{ "Bienvenido/a", "Bienvenid{o/a}" },
	{ "bienvenido/a", "bienvenid{o/a}" },
	{ "Listo/a", "List{o/a}" },
	{ "listo/a", "list{o/a}" },
	{ "Seguro/a", "Segur{o/a}" },
	{ "seguro/a", "segur{o/a}" },
	{ "pequeño/a", "pequeñ{o/a}" },
	{ "Niño/a", "Niñ{o/a}" },
	{ "niño/a", "niñ{o/a}" },
	{ "sentado/a", "sentad{o/a}" },
	{ "raro/a", "rar{o/a}" },
	{ "pesado/a", "pesad{o/a}" },
	{ "enfermo/a", "enferm{o/a}" },
	{ "Hijo/Hija", "{Hijo/Hija}" },
	{ "Él/Ella", "{Él/Ella}" },
	{ "él/ella", "{él/ella}" },
	{ "vecino/a favorito/a", "vecin{o/a} favorit{o/a}" },
	{ "Señor/a", "Señor{/a}" },
}
-- Palabra completa (sin letras pegadas a los lados)
local function replaceWord(text: string, word: string, by: string): (string, number)
	local count = 0
	local out = {}
	local i = 1
	while true do
		local a, b = text:find(word, i, true)
		if not a then
			table.insert(out, text:sub(i))
			break
		end
		local before = if a > 1 then text:sub(a - 1, a - 1) else ""
		local after = text:sub(b + 1, b + 1)
		local inToken = text:sub(b + 1, b + 1) == "{" or before == "{" or text:sub(a, b + 1):find("}", 1, true)
		if before:match("[%w\128-\255]") or after:match("[%w\128-\255{]") or inToken then
			table.insert(out, text:sub(i, b))
		else
			table.insert(out, text:sub(i, a - 1) .. by)
			count += 1
		end
		i = b + 1
	end
	return table.concat(out), count
end
function Reescritura.genderFix(text: string): (string, { string })
	local fixes = {}
	-- (primero las que ya traen «/a» o «o …»: «Listo/a» antes que «Listo»)
	local ordered = {}
	for _, rule in GENDER do
		if rule[1]:find("/", 1, true) or rule[1]:find(" o ", 1, true) then
			table.insert(ordered, rule)
		end
	end
	for _, rule in GENDER do
		if not (rule[1]:find("/", 1, true) or rule[1]:find(" o ", 1, true)) then
			table.insert(ordered, rule)
		end
	end
	for _, rule in ordered do
		if rule[1] ~= rule[2] and text:find(rule[1], 1, true) and not text:find(rule[2], 1, true) then
			local fixed, count = replaceWord(text, rule[1], rule[2])
			if count > 0 then
				text = fixed
				table.insert(fixes, rule[1] .. " → " .. rule[2])
			end
		end
	end
	return Reescritura.slashFix(text, fixes)
end

function Reescritura.slashFix(text: string, fixes: { string }): (string, { string })
	-- (cualquier otra palabra con barra: «Encargado/a» → «Encargad{o/a}», «Jefe/a» → «Jef{e/a}»,
	-- «Bienvenido/Bienvenida» → «Bienvenid{o/a}», «Señor/a» → «Señor{/a}»)
	local generic = {
		{ "(%a+)o/(%a+)a([^%a])", function(stem, stem2, after)
			if stem2 == stem then
				return stem .. "{o/a}" .. after
			end
			return nil
		end },
		{ "(%a+)os/as([^%a{])", "%1{os/as}%2" },
		{ "(%a+)o/a([^%a{])", "%1{o/a}%2" },
		{ "(%a+)e/a([^%a{])", "%1{e/a}%2" },
		{ "(%a+)r/a([^%a{])", "%1r{/a}%2" },
	}
	for _, g in generic do
		local before = text
		text = (text .. " "):gsub(g[1], g[2]):sub(1, -2)
		if text ~= before then
			table.insert(fixes, "palabra con barra → {masc/fem}")
		end
	end
	return text, fixes
end

-- ¿Está bien escrito cada {masc/fem}?
function Reescritura.genderTokensOk(text: string): (boolean, string?)
	local depth = 0
	for c in text:gmatch("[{}]") do
		depth += if c == "{" then 1 else -1
		if depth < 0 or depth > 1 then
			return false, "llaves desparejadas"
		end
	end
	if depth ~= 0 then
		return false, "llaves desparejadas"
	end
	for inner in text:gmatch("{([^{}]*)}") do
		if not inner:match("^%a+$") and not inner:match("^[^/]*/[^/]*$") then
			return false, ("«{%s}» no es {masculino/femenino} ni {nombre}"):format(inner)
		end
	end
	return true, nil
end

local SPEAKER_ALIASES = {
	-- (personajes de la saga con otro nombre en el reparto)
	cronos = "CazadorTiempo",
	["agente cronos"] = "CazadorTiempo",
	["bigotes xvii"] = "Bigotes",
	narrador = "Narrador",
	narradora = "Narrador",
	voz = "Narrador",
	protagonista = "Yo",
	tu = "Yo",
	yo = "Yo",
	jugador = "Yo",
	jugadora = "Yo",
	madre = "Familia",
	padre = "Familia",
	mama = "Familia",
	papa = "Familia",
	["mama papa"] = "Familia",
	["mama o papa"] = "Familia",
	["madre padre"] = "Familia",
	progenitor = "Familia",
	familia = "Familia",
	abu = "Abu",
	abuela = "Abu",
	abuelo = "Abu",
	["abu rosa"] = "Abu",
	["abu tomas"] = "Abu",
	todos = "@Todos",
	["respuesta del jugador"] = "Yo",
	["respuesta del protagonista"] = "Yo",
	todas = "@Todos",
	["todos a la vez"] = "@Todos",
	["la clase"] = "@Todos",
	["los ninos"] = "@Todos",
	["el grupo"] = "@Todos",
	["todo el grupo"] = "@Todos",
}
Reescritura.SpeakerAliases = SPEAKER_ALIASES
local TITLES = { "profe ", "profesora ", "profesor ", "senor ", "senora ", "don ", "dona ", "la ", "el " }

-- Cosas que son el jugador en un PLANO
local PLAYER_WORDS = { "jugador", "jugadora", "protagonista", "yo", "tu", "bebe" }
local SKY_WORDS = { "grieta", "cielo", "destello", "estrella", "estrellas", "chispa", "rift" }
local BIG_WORDS = { "valmar", "ciudad", "barrio", "los pinos", "region", "calle", "entorno", "pueblo" }
local STOP = { de = true, del = true, la = true, el = true, los = true, las = true, al = true, en = true, y = true, que = true, un = true, una = true, con = true, por = true, a = true }

local function words(s: string): { string }
	local out = {}
	for w in norm(s):gmatch("%S+") do
		if not STOP[w] and #w >= 3 then
			table.insert(out, w)
		end
	end
	return out
end

local function splitCamel(s: string): string
	return (s:gsub("(%l)(%u)", "%1 %2"))
end

local function hasWord(list: { string }, n: string): boolean
	local padded = " " .. n .. " "
	for _, w in list do
		if padded:find(" " .. w .. " ", 1, true) then
			return true
		end
	end
	return false
end

-- Lo que hace falta saber del juego (lo carga la herramienta con los módulos de verdad)
export type Game = {
	Quests: { [string]: any },
	Cast: { [string]: any },
	Places: { [string]: any },
	Cinematics: { [string]: any },
	Happenings: { [string]: any },
	Traits: { [string]: boolean },
	ChoiceKeys: { [string]: boolean },
	Flags: { [string]: boolean },
	Memories: { [string]: any },
	Sequencer: any,
}

local PLAYABLE = { Reach = true, Event = true, Use = true, Group = true, Choice = true, Class = true, MiniGame = true, Fight = true, Chase = true, Escape = true, Wait = true }

local function categoryOfGame(step: { [string]: any }): string
	if step.Type == "Cinematic" or (step.Type == "Transition" and step.Cinematic) then
		return "cine"
	elseif (step.Type == "Talk" or step.Type == "Scene") and step.Dialogue then
		return "talk"
	elseif step.Type == "Transition" or step.Type == "Moment" then
		return "text"
	end
	return "play"
end

local function categoryOfScript(kind: string): string
	local n = norm(kind)
	if n:find("cinematic") or n:find("cinematica") then
		return "cine"
	elseif n:find("transition") or n:find("transicion") then
		return "text"
	elseif n:find("talk") or n:find("hablar") or n:find("scene") or n:find("escena") then
		return "talk"
	end
	return "play"
end

-- Ruta de un paso ("3" o "3.2") -> la tabla del paso
local function stepAt(steps: { any }, path: string): { [string]: any }?
	local list: any = steps
	local node = nil
	for part in path:gmatch("[^%.]+") do
		local i = tonumber(part)
		if not i or type(list) ~= "table" then
			return nil
		end
		node = list[i]
		if type(node) ~= "table" then
			return nil
		end
		list = node.Steps
	end
	return node
end
Reescritura.stepAt = stepAt

-- Mapa por defecto PASO del guion -> paso del juego: en orden, cada PASO entero al siguiente paso del
-- juego (prefiriendo uno del mismo tipo a 1-2 pasos), los «n.m» al hijo m del Group n si lo hay.
local function defaultMap(doc: Doc, steps: { any }): { [string]: any }
	local map = {}
	-- Guion sacado de la exportación (exportar-dialogos): tantos PASO enteros como pasos tiene la misión.
	-- Entonces cada PASO n es el paso n y cada «n.m», el hijo m del Group n (o el paso n si no lo es).
	local integers = 0
	for _, s in doc.Steps do
		if s.Num:match("^%d+$") then
			integers += 1
		end
	end
	if integers == #steps then
		for _, s in doc.Steps do
			local major, minor = s.Num:match("^(%d+)%.(%d+)$")
			if major then
				local node = steps[tonumber(major)]
				map[s.Num] = if node and node.Type == "Group" and node.Steps and node.Steps[tonumber(minor)] then major .. "." .. minor else major
			else
				map[s.Num] = s.Num
			end
		end
		return map
	end
	local g = 1
	local lastMajor: { [string]: string } = {}
	for _, s in doc.Steps do
		local major, minor = s.Num:match("^(%d+)%.(%d+)$")
		if major then
			local parent = lastMajor[major]
			local node = parent and stepAt(steps, parent)
			if node and node.Type == "Group" and node.Steps and node.Steps[tonumber(minor)] then
				map[s.Num] = parent .. "." .. minor
			else
				map[s.Num] = parent or tostring(math.max(g - 1, 1))
			end
			continue
		end
		if g > #steps then
			map[s.Num] = tostring(#steps)
			lastMajor[s.Num] = tostring(#steps)
			continue
		end
		local want = categoryOfScript(s.Type)
		local pick = g
		for k = g, math.min(g + 2, #steps) do
			if categoryOfGame(steps[k]) == want then
				pick = k
				break
			end
		end
		map[s.Num] = tostring(pick)
		lastMajor[s.Num] = tostring(pick)
		g = pick + 1
	end
	return map
end
Reescritura.defaultMap = defaultMap

-- El informe
local function newReport()
	return { Applied = {}, Adapted = {}, Errors = {}, Warnings = {}, Gender = {}, Map = {}, Notes = {} }
end

function Reescritura.build(doc: Doc, game: Game, mapa: { [string]: any }?): ({ [string]: any }, { [string]: any })
	local m = mapa or {}
	local R = newReport()
	local function applied(fmt: string, ...)
		table.insert(R.Applied, fmt:format(...))
	end
	local function adapted(fmt: string, ...)
		table.insert(R.Adapted, fmt:format(...))
	end
	local function errorf(fmt: string, ...)
		table.insert(R.Errors, fmt:format(...))
	end
	local function warnf(fmt: string, ...)
		local text = fmt:format(...)
		if not table.find(R.Warnings, text) then
			table.insert(R.Warnings, text)
		end
	end
	for _, p in doc.Problems do
		errorf("%s", p)
	end
	local quest = doc.Id and game.Quests[doc.Id]
	if not quest then
		errorf("la misión «%s» no existe en el juego", tostring(doc.Id))
		return {}, R
	end
	local steps = quest.Steps or {}
	local prefix = m.Prefijo or doc.Id
	local guion = { Source = "docs/historia/reescritura/" .. doc.Id .. ".md", Steps = {}, Dialogues = {}, Scenes = {} }
	local Seq = game.Sequencer

	---------------------------------------------------------------
	-- Mapa de pasos
	---------------------------------------------------------------
	-- Lineas = { ["1"] = { { 514, 565 }, { 676, 700 } } }: de ese PASO solo valen esas líneas del guion
	-- (cuando el PASO mezcla lo que el juego puede contar con un diseño que no cabe en el paso)
	for _, s in doc.Steps do
		local ranges = m.Lineas and m.Lineas[s.Num]
		if ranges then
			local kept = {}
			for _, it in s.Items do
				local ln = it.Line or 0
				local inside = false
				for _, r in ranges do
					inside = inside or (ln >= r[1] and ln <= r[2])
				end
				if inside or it.K == "Blank" then
					table.insert(kept, it)
				end
			end
			s.Items = kept
		end
	end
	local map = defaultMap(doc, steps)
	for k, v in m.Pasos or {} do
		map[k] = if v == false then false else tostring(v)
	end
	-- Escenas = { ["1"] = "Bebe_VentanalFamilia" }: ese PASO reescribe una escena del motor que lanza otro
	-- sistema (no un paso de la misión): la misma escena, con el guion nuevo
	for k, sid in m.Escenas or {} do
		if game.Happenings[sid] then
			map[k] = "@" .. sid
		else
			errorf("Escenas: «%s» no es una escena del motor", tostring(sid))
		end
	end
	for _, s in doc.Steps do
		local target = map[s.Num]
		if target and target:sub(1, 1) ~= "@" and not stepAt(steps, target) then
			errorf("PASO %s: el paso %s no existe en la misión (tiene %d)", s.Num, target, #steps)
			map[s.Num] = false
		end
	end

	---------------------------------------------------------------
	-- Quién habla
	---------------------------------------------------------------
	local castByNorm: { [string]: string } = {}
	for key, person in game.Cast do
		castByNorm[norm(key)] = key
		castByNorm[norm(splitCamel(key))] = key
		if type(person) == "table" and type(person.Name) == "string" then
			castByNorm[norm(person.Name)] = castByNorm[norm(person.Name)] or key
		end
	end
	local unknownSpeakers: { [string]: boolean } = {}
	local function speakerOf(raw: string, where: string): string?
		if m.Hablantes and m.Hablantes[raw] then
			return m.Hablantes[raw]
		end
		-- («Todos.»: el punto sobra)
		if raw:match("%.$") and #raw > 1 then
			return speakerOf((raw:gsub("%.+$", "")), where)
		end
		-- «COSME (fuera de cámara)»: quien habla es Cosme
		local bare = raw:match("^(.-)%s*%(.-%)%s*$")
		if bare and bare ~= "" and bare ~= raw then
			return speakerOf(bare, where)
		end
		local n = norm(raw)
		if SPEAKER_ALIASES[n] then
			return SPEAKER_ALIASES[n]
		end
		if castByNorm[n] then
			return castByNorm[n]
		end
		for _, t in TITLES do
			if n:sub(1, #t) == t and castByNorm[n:sub(#t + 1)] then
				return castByNorm[n:sub(#t + 1)]
			end
		end
		if not unknownSpeakers[raw] then
			unknownSpeakers[raw] = true
			warnf("%s: «%s» no está en el reparto del juego: sus frases no se aplican (si es alguien, ponlo en Hablantes del mapa)", where, raw)
		end
		return nil
	end

	---------------------------------------------------------------
	-- Sujetos de los planos -> actor, jugador, cielo o lugar
	---------------------------------------------------------------
	local missionPlaces: { string } = {}
	local function addPlace(p: any)
		if type(p) == "string" and game.Places[p] and not table.find(missionPlaces, p) then
			table.insert(missionPlaces, p)
		end
	end
	local function walkSteps(list: { any })
		for _, st in list do
			if type(st) == "table" then
				addPlace(st.Place)
				addPlace(type(st.Teleport) == "table" and st.Teleport.Place or st.Teleport)
				for _, a in (type(st.Actors) == "table" and st.Actors) or {} do
					addPlace(type(a) == "table" and a.Place)
				end
				if st.Steps then
					walkSteps(st.Steps)
				end
			end
		end
	end
	walkSteps(steps)
	for _, a in quest.Actors or {} do
		addPlace(a.Place)
	end
	for _, prop in quest.Props or {} do
		addPlace(type(prop) == "table" and prop.Place)
	end
	local actorPlace: { [string]: string } = {}
	for _, a in quest.Actors or {} do
		if a.Npc and a.Place then
			actorPlace[a.Npc] = actorPlace[a.Npc] or a.Place
		end
	end
	for _, place in m.Lugares or {} do
		addPlace(place)
	end
	for key, place in m.Actores or {} do
		actorPlace[key] = place
		addPlace(place)
	end
	local function placeFor(text: string): string?
		local n = norm(text)
		local best, bestScore = nil, 0
		for _, p in missionPlaces do
			local rawName = game.Places[p].NameKey or ""
			local name = norm((game.Strings and game.Strings[rawName]) or rawName)
			local keyWords = norm(splitCamel(p))
			local score = 0
			if name == n then
				score = 100
			elseif name ~= "" and (name:find(n, 1, true) or n:find(name, 1, true)) then
				score = 50
			end
			for _, w in words(text) do
				if (" " .. name .. " "):find(" " .. w .. " ", 1, true) then
					score += 10
				elseif (" " .. keyWords .. " "):find(" " .. w .. " ", 1, true) then
					score += 6
				elseif #w >= 5 and (name:find(w:sub(1, #w - 2), 1, true)) then
					score += 4
				end
			end
			if score > bestScore then
				best, bestScore = p, score
			end
		end
		return best
	end
	-- Sujeto -> { Kind = "Actor"|"Yo"|"Sky"|"Place"|"Big"|"None", Key?, Place? }
	local function subjectOf(raw: string?, castKeys: { [string]: boolean }): { [string]: any }
		if not raw or raw == "" then
			return { Kind = "None" }
		end
		local override = m.Sujetos and m.Sujetos[raw]
		if type(override) == "string" then
			local kind, value = override:match("^(%a+):(.+)$")
			if kind == "Grande" then
				return { Kind = "Big", Place = value }
			elseif kind == "Lugar" then
				return { Kind = "Place", Place = value }
			elseif override == "Cielo" then
				return { Kind = "Sky" }
			elseif override == "Yo" then
				return { Kind = "Yo" }
			end
			return { Kind = "Actor", Key = override }
		end
		local n = norm(raw)
		if hasWord(PLAYER_WORDS, n) or n:find("mano del", 1, true) or n:find("pies", 1, true) then
			if not (n:find("madre", 1, true) or n:find("padre", 1, true)) then
				return { Kind = "Yo" }
			end
		end
		local who = SPEAKER_ALIASES[n] or castByNorm[n]
		if not who then
			for _, t in TITLES do
				if n:sub(1, #t) == t and castByNorm[n:sub(#t + 1)] then
					who = castByNorm[n:sub(#t + 1)]
				end
			end
		end
		if not who and m.Hablantes and m.Hablantes[raw] then
			who = m.Hablantes[raw]
		end
		if who and who ~= "Narrador" then
			if who == "Yo" then
				return { Kind = "Yo" }
			end
			return { Kind = "Actor", Key = who }
		end
		-- «Mano de la madre», «Cosme → …»: el primer personaje que se nombra
		for _, w in words(raw) do
			local k = SPEAKER_ALIASES[w] or castByNorm[w]
			if k and k ~= "Narrador" and k ~= "Yo" and castKeys[k] then
				return { Kind = "Actor", Key = k }
			end
		end
		if hasWord(SKY_WORDS, n) then
			return { Kind = "Sky" }
		end
		local place = placeFor(raw)
		if place then
			return { Kind = "Place", Place = place }
		end
		if hasWord(BIG_WORDS, n) then
			return { Kind = "Big" }
		end
		return { Kind = "None", Raw = raw }
	end

	---------------------------------------------------------------
	-- Variables y efectos de las elecciones
	---------------------------------------------------------------
	local choiceKeyByNorm: { [string]: string } = {}
	for key in game.ChoiceKeys do
		choiceKeyByNorm[norm(key)] = key
	end
	local traitByNorm: { [string]: string } = {}
	for key in game.Traits do
		traitByNorm[norm(key)] = key
	end
	local flagByNorm: { [string]: string } = {}
	for key in game.Flags do
		flagByNorm[norm(splitCamel(key))] = key
		flagByNorm[norm(key)] = key
	end
	local function variable(name: string): { [string]: any }
		local v = m.Variables and (m.Variables[name] or m.Variables[norm(name)])
		if v then
			return v
		end
		local n = norm((name:gsub("_", " ")))
		if choiceKeyByNorm[n] or choiceKeyByNorm[n:gsub(" ", "")] then
			return { Choice = choiceKeyByNorm[n] or choiceKeyByNorm[n:gsub(" ", "")] }
		end
		if flagByNorm[n] or flagByNorm[n:gsub(" ", "")] then
			return { Flag = flagByNorm[n] or flagByNorm[n:gsub(" ", "")] }
		end
		return { New = camel((name:gsub("_", " "))) }
	end
	-- «Valentia +1; decisión prologo = Ayudar; …» -> Effects
	local function effectsOf(list: { string }, where: string): ({ [string]: any }, { string })
		local e: { [string]: any } = {}
		local notes = {}
		for _, chunk in list do
			for part in (chunk .. ";"):gmatch("([^;·]+)") do
				part = trim(part)
				local np = norm(part)
				if part == "" or np:find("^continua") or np:find("^sigue") or np:find("^pasa a") then
					continue
				end
				local name, amount = part:match("^([^%+%-]-)%s*([%+%-]%s*%d+)%.?$")
				if name then
					amount = tonumber((amount:gsub("%s", ""))) :: any
					local nn = norm(name):gsub("^relacion con ", ""):gsub("^rel ", ""):gsub("^afinidad con ", ""):gsub("^confianza de ", ""):gsub("^amistad con ", "")
					for _, t in TITLES do
						if nn:sub(1, #t) == t and castByNorm[nn:sub(#t + 1)] then
							nn = nn:sub(#t + 1)
						end
					end
					if traitByNorm[nn] then
						e.Traits = e.Traits or {}
						e.Traits[traitByNorm[nn]] = (e.Traits[traitByNorm[nn]] or 0) + amount
						continue
					end
					local who = castByNorm[nn] or SPEAKER_ALIASES[nn]
					if who and who ~= "Narrador" and who ~= "Yo" then
						e.Rel = e.Rel or {}
						e.Rel[who] = (e.Rel[who] or 0) + amount
						continue
					end
					if nn:find("^[%a]+$") then
						-- (un rasgo nuevo: el juego guarda cualquier rasgo, pero se apunta)
						local key = camel(nn)
						e.Traits = e.Traits or {}
						e.Traits[key] = (e.Traits[key] or 0) + amount
						table.insert(notes, ("rasgo nuevo «%s» (%s)"):format(key, part))
						continue
					end
				end
				-- «bruno_confianza += 3» / «rel_mateo -= 2»: relación con ese personaje
				local pkey, pop, pnum = part:match("^([%w_]+)%s*([%+%-])=%s*(%d+)$")
				if pkey then
					local who = nil
					for w in (pkey:gsub("_", " ")):gmatch("%S+") do
						who = who or castByNorm[norm(w)]
					end
					local amount = (tonumber(pnum) or 0) * (if pop == "-" then -1 else 1)
					if who then
						e.Rel = e.Rel or {}
						e.Rel[who] = (e.Rel[who] or 0) + amount
					else
						table.insert(notes, ("sin equivalente: «%s»"):format(part))
					end
					continue
				end
				local dkey, dval = nil, nil
				if np:find("^decision ") then
					dkey, dval = (part:gsub("^%S+%s+", "")):match("^([%w_]+)%s*=%s*(.+)$")
				end
				if not dkey then
					dkey, dval = part:match("^([%w_]+)%s*=%s*(.+)$")
				end
				if dkey then
					dval = trim(unquote(dval))
					local v = variable(dkey)
					if not v.Flag and not v.Choice and not v.New then
						-- (una variable que el mapa define como condición: la decisión ya la da la opción del juego)
						table.insert(notes, ("«%s» no se guarda aparte (el mapa la deja como condición o ya la da el juego)"):format(part))
						continue
					end
					local bool = norm(dval) == "true" or norm(dval) == "si" or norm(dval) == "verdadero"
					local isFalse = norm(dval) == "false" or norm(dval) == "no" or norm(dval) == "falso"
					if v.Flag or ((bool or isFalse) and not v.Choice) then
						local flag = v.Flag or v.New
						if isFalse then
							e.Unflags = e.Unflags or {}
							table.insert(e.Unflags, flag)
						else
							e.Flags = e.Flags or {}
							table.insert(e.Flags, flag)
						end
						if v.New then
							table.insert(notes, ("marca nueva «%s» (%s)"):format(flag, part))
						end
					else
						local key = v.Choice or v.New
						e.Choice = e.Choice or {}
						e.Choice[key] = (v.Valores and (v.Valores[dval] or v.Valores[norm(dval)])) or (camel(dval):gsub("^%l", string.upper))
						if v.New then
							table.insert(notes, ("decisión nueva «%s» (%s)"):format(key, part))
						end
					end
					continue
				end
				local flag = part:match("^[Ff]lag:?%s*([%w_]+)") or part:match("^[Mm]arca:?%s*([%w_]+)")
				if flag then
					local v = variable(flag)
					e.Flags = e.Flags or {}
					if v.Flag or v.New then
						table.insert(e.Flags, v.Flag or v.New)
					end
					continue
				end
				local memory = part:match("^[Rr]ecuerdo%s+([%w_]+)")
				if memory and game.Memories[memory] then
					e.Memory = memory
					continue
				end
				table.insert(notes, ("sin equivalente: «%s»"):format(part))
			end
		end
		local _ = where
		return e, notes
	end
	-- «ropa = Camisa», «llegó tarde», «pase_a_dani y lleva_cromo», «asiento = Nico» -> Conditions
	local function conditionOf(raw: string, where: string): { [string]: any }?
		local c: { [string]: any } = {}
		-- La NOTA del último examen (Conditions: LastGradeAtLeast / LastGradeBelow): «nota ≥ 9», «nota < 5»,
		-- «nota final ≥ 5», «nota entre 5 y 8»
		local nraw = norm((raw:gsub("≥", " ge "):gsub("≤", " le "):gsub(">=", " ge "):gsub("<=", " le "):gsub(">", " gt "):gsub("<", " lt ")))
		local lo, hi = nraw:match("^nota%s*%a*%s*entre (%d+) y (%d+)$")
		if lo then
			return { LastGradeAtLeast = tonumber(lo), LastGradeBelow = tonumber(hi) + 1 }
		end
		local op, value = nraw:match("^nota%s*%a*%s+(%a%a)%s+(%d+[%.,]?%d*)$")
		if op and (op == "ge" or op == "gt" or op == "le" or op == "lt") then
			local n = tonumber((value:gsub(",", "."))) or 0
			if op == "ge" then
				return { LastGradeAtLeast = n }
			elseif op == "gt" then
				return { LastGradeAtLeast = n + 0.01 }
			elseif op == "lt" then
				return { LastGradeBelow = n }
			else
				return { LastGradeBelow = n + 0.01 }
			end
		end
		for part in ((raw:gsub("%s+%+%s+", " y "):gsub("%s+Y%s+", " y ")) .. " y "):gmatch("(.-)%s+y%s+") do
			part = trim(part)
			-- («EXISTE conoces_a_leire», «además existe primer_club»: lo que importa es la marca)
			part = trim((part:gsub("^[Aa]demás%s+", ""):gsub("^[Ee][Xx][Ii][Ss][Tt][Ee]%s+[Rr][Ee][Cc][Uu][Ee][Rr][Dd][Oo]%s+", "recuerdo "):gsub("^[Ee][Xx][Ii][Ss][Tt][Ee]%s+", ""):gsub("^[Nn][Oo]%s+[Ee][Xx][Ii][Ss][Tt][Ee]%s+", "no ")))
			-- («recuerdo la_noche»: un recuerdo del juego)
			local memName = part:match("^recuerdo%s+([%w_]+)$")
			if memName then
				local key = camel(memName)
				if game.Memories[key] or game.Memories[memName] then
					c.Memories = c.Memories or {}
					table.insert(c.Memories, if game.Memories[key] then key else memName)
					continue
				end
			end
			if part == "" then
				continue
			end
			-- «deportividad >= 4», «valentia < 2»: un rasgo (Conditions: Traits / TraitsBelow)
			local tnorm = norm((part:gsub("≥", " ge "):gsub("≤", " le "):gsub(">=", " ge "):gsub("<=", " le "):gsub(">", " gt "):gsub("<", " lt ")))
			local tname, top, tnum = tnorm:match("^(%a+) (%a%a) (%-?%d+)$")
			-- «Rayo >= 5», «Rayo < 0»: la relación con alguien del reparto (Conditions: Rel / RelBelow)
			if tname and castByNorm[tname] and not traitByNorm[tname] then
				local n = tonumber(tnum) or 0
				if top == "ge" or top == "gt" then
					c.Rel = c.Rel or {}
					c.Rel[castByNorm[tname]] = if top == "gt" then n + 1 else n
				else
					c.RelBelow = c.RelBelow or {}
					c.RelBelow[castByNorm[tname]] = if top == "le" then n + 1 else n
				end
				continue
			end
			if tname and traitByNorm[tname] then
				local n = tonumber(tnum) or 0
				if top == "ge" or top == "gt" then
					c.Traits = c.Traits or {}
					c.Traits[traitByNorm[tname]] = if top == "gt" then n + 1 else n
				else
					c.TraitsBelow = c.TraitsBelow or {}
					c.TraitsBelow[traitByNorm[tname]] = if top == "le" then n + 1 else n
				end
				continue
			end
			-- «Si Ataque:»: el valor de una decisión del juego (Estrategia = Ataque)
			local asValue = not part:find("%s") and not part:find("=", 1, true) and game.ChoiceValues and (game.ChoiceValues[part] or game.ChoiceValues[camel(part)])
			if asValue and not (m.Variables and m.Variables[part]) and not flagByNorm[norm((part:gsub("_", " ")))] then
				c.Choices = c.Choices or {}
				c.Choices[asValue] = if game.ChoiceValues[part] then part else camel(part)
				continue
			end
			if part:find("[<>]") or part:find("≥", 1, true) or part:find("≤", 1, true) then
				warnf("%s: la condición «%s» compara números: no se convierte (la decide la mecánica del paso)", where, part)
				continue
			end
			local mv = m.Variables and (m.Variables[part] or m.Variables[norm(part)])
			if mv and (mv.Gana or mv.Pierde or mv.Empata) then
				-- (el resultado de un minijuego: una marca nueva que el paso pone al ganar/perder/empatar)
				local path = tostring(mv.Gana or mv.Pierde or mv.Empata)
				local field = if mv.Gana then "Win" elseif mv.Pierde then "Lose" else "Draw"
				local flag = ("%s_P%s_%s"):format(m.Prefijo or doc.Id, (path:gsub("%.", "_")), if mv.Gana then "Gana" elseif mv.Pierde then "Pierde" else "Empata")
				local mini = stepAt(steps, path)
				if mini and (mini.Type == "MiniGame" or mini.Type == "Class") then
					local p = guion.Steps[path] or {}
					guion.Steps[path] = p
					p.Set = p.Set or {}
					local base = p.Set[field] or (if type(mini[field]) == "table" then table.clone(mini[field]) else {})
					base.Flags = if base.Flags then table.clone(base.Flags) else {}
					if not table.find(base.Flags, flag) then
						table.insert(base.Flags, flag)
					end
					p.Set[field] = base
					c.Flags = c.Flags or {}
					table.insert(c.Flags, flag)
				else
					warnf("%s: «%s» habla del resultado del paso %s, que no es un minijuego", where, part, path)
				end
				continue
			end
			if mv and mv.Nunca then
				-- (algo que el juego no puede saber: «si el jugador se esconde» en una huida → la frase no sale)
				c.Nunca = true
				continue
			end
			if mv and mv.If then
				-- (condición escrita a mano en el mapa: «llegó tarde» → { Flags = { "LlegasTarde" } })
				for field, value in mv.If do
					c[field] = if type(value) == "table" then table.clone(value) else value
				end
				continue
			end
			-- «primer grupo», «primer_torneo»: un recuerdo del juego con ese nombre
			if not mv and not part:find("=", 1, true) then
				local nm = part:gsub("^[Nn][Oo]%s+", "")
				local mk = camel((nm:gsub(" ", "_")))
				if game.Memories[mk] and not flagByNorm[norm((nm:gsub("_", " ")))] then
					if part:find("^[Nn][Oo]%s+") then
						c.NotMemories = c.NotMemories or {}
						table.insert(c.NotMemories, mk)
					else
						c.Memories = c.Memories or {}
						table.insert(c.Memories, mk)
					end
					continue
				end
			end
			-- «malotes != Ignorar» / «malotes ≠ Ignorar»: cualquier decisión menos esa
			local nkey, nvalue = part:match("^([%w_ ]-)%s*!=%s*(.+)$")
			if not nkey then
				nkey, nvalue = part:match("^([%w_ ]-)%s*≠%s*(.+)$")
			end
			if nkey then
				local v = variable((trim(nkey):gsub(" ", "_")))
				local ck = v.Choice or v.New
				nvalue = trim(unquote(nvalue))
				c.NotChoices = c.NotChoices or {}
				c.NotChoices[ck] = (v.Valores and (v.Valores[nvalue] or v.Valores[norm(nvalue)])) or camel(nvalue)
				continue
			end
			local key, value = part:match("^([%w_ ]-)%s*=%s*(.+)$")
			local negate = false
			if not key then
				negate = part:find("^[Nn][Oo] ") ~= nil
				key = part:gsub("^[Nn][Oo] ", "")
			end
			key = trim(key)
			if value then
				value = trim(unquote(value))
			end
			-- «NO lo hace» con «lo hace» en el mapa como condición: la contraria
			local mvn = negate and m.Variables and (m.Variables[key] or m.Variables[norm(key)])
			if mvn and mvn.If and next(mvn.If) == nil then
				c.Nunca = true -- (lo contrario de «siempre»: nunca)
				continue
			end
			if mvn and mvn.If then
				for field, val in mvn.If do
					if field == "Flags" then
						c.NotFlags = table.clone(val)
					elseif field == "NotFlags" then
						c.Flags = table.clone(val)
					elseif field == "Choices" then
						c.NotChoices = table.clone(val)
					elseif field == "NotChoices" then
						c.Choices = table.clone(val)
					elseif field == "Input" then
						c.NotInput = val
					elseif field == "Completed" then
						c.NotCompleted = table.clone(val)
					elseif field == "Memories" then
						c.NotMemories = table.clone(val)
					end
				end
				continue
			end
			if mvn and mvn.Nunca then
				continue -- (lo contrario de algo que nunca pasa: siempre)
			end
			local v = variable((key:gsub(" ", "_")))
			if value and not v.Choice and (norm(value) == "false" or norm(value) == "no") then
				negate, value = true, nil
			elseif value and (norm(value) == "true" or norm(value) == "si") then
				value = nil
			end
			if value and not v.Flag then
				local ck = v.Choice or v.New
				c.Choices = c.Choices or {}
				local cv = (v.Valores and (v.Valores[value] or v.Valores[norm(value)])) or camel(value)
				-- («adios_bruno = decero»: el valor del juego con sus mayúsculas, DeCero)
				if game.ChoiceValues and game.ChoiceValues[cv] == nil then
					for known in game.ChoiceValues do
						if type(known) == "string" and norm(known):gsub("%s", "") == norm(value):gsub("%s", "") then
							cv = known
							break
						end
					end
				end
				c.Choices[ck] = cv
			else
				local flag = v.Flag or v.New
				if negate then
					c.NotFlags = c.NotFlags or {}
					table.insert(c.NotFlags, flag)
				else
					c.Flags = c.Flags or {}
					table.insert(c.Flags, flag)
				end
			end
			if v.New then
				warnf("%s: condición «%s» con una variable que el juego aún no guarda (%s)", where, part, v.New)
			end
		end
		-- (una lista vacía no es una condición: «NotFlags = {}» sobra)
		for k, v in c do
			if type(v) == "table" and next(v) == nil then
				c[k] = nil
			end
		end
		return if next(c) then c else nil
	end

	---------------------------------------------------------------
	-- Frases
	---------------------------------------------------------------
	local noGender: { [string]: boolean } = {}
	for _, t in m.SinGenero or {} do
		noGender[t] = true
	end
	local function cleanText(t: string, speaker: string, where: string): string
		if utf8.len(t) == nil then
			errorf("%s: texto con UTF-8 roto: «%s»", where, t)
		end
		t = t:gsub("%[[Tt]u nombre%]", "{nombre}"):gsub("%[nombre%]", "{nombre}"):gsub("%[nombre del jugador%]", "{nombre}")
		t = t:gsub("%[nombre_grupo%]", "{grupo}")
		for from, to in m.Reemplazos or {} do
			t = t:gsub(from:gsub("%p", "%%%0"), (to:gsub("%%", "%%%%")))
		end
		if speaker == "Yo" and not noGender[t] then
			-- (lo que dice el jugador de sí mismo con barra: «tranquilo/a» → «tranquil{o/a}»)
			local fixed, fixes = Reescritura.slashFix(t, {})
			if #fixes > 0 then
				table.insert(R.Gender, ("%s · %s: «%s» → «%s»"):format(where, speaker, t, fixed))
				t = fixed
			end
		end
		if speaker ~= "Yo" and not noGender[t] then
			local fixed, fixes = Reescritura.genderFix(t)
			if #fixes > 0 then
				table.insert(R.Gender, ("%s · %s: «%s» → «%s»"):format(where, speaker, t, fixed))
				t = fixed
			end
		end
		local ok, why = Reescritura.genderTokensOk(t)
		if not ok then
			errorf("%s: %s en «%s»", where, why or "?", t)
		end
		if len(t) > Reescritura.MAX_LINE then
			warnf("%s: frase de %d caracteres (más de %d): «%s»", where, len(t), Reescritura.MAX_LINE, t)
		end
		return t
	end

	---------------------------------------------------------------
	-- Validación del guion (tipos de plano, música)
	---------------------------------------------------------------
	local function musicOf(s: Step): { string }
		local out = {}
		for _, raw in (m.Musica and m.Musica[s.Num]) or s.Music do
			local key = raw:gsub("%b()", "")
			-- («Comedia al principio»: vale la primera palabra si es una música)
			local firstWord = norm(key):match("^(%S+)")
			for name in Reescritura.Music do
				if firstWord and norm(name) == firstWord then
					key = name
				end
			end
			key = norm(key)
			local found = nil
			for name in Reescritura.Music do
				if norm(name) == key then
					found = name
				end
			end
			if found then
				table.insert(out, Reescritura.Music[found])
			else
				errorf("PASO %s: música «%s» no válida (Calma, Tension, Emocion, Accion, Epico, Comedia)", s.Num, raw)
			end
		end
		return out
	end
	for _, s in doc.Steps do
		for _, item in s.Items do
			if item.K == "Plano" and not Reescritura.PlanoTypes[item.Kind] then
				errorf("PASO %s (línea %d): tipo de plano «%s» no válido", s.Num, item.Line, item.Kind)
			end
		end
	end

	---------------------------------------------------------------
	-- Un PASO del guion -> frases con plano, gesto, pausa y rama
	---------------------------------------------------------------
	-- Devuelve una lista de «bloques» en orden: { K = "Line", S, T, Shot, A, G, Pause, Plano, If }, { K = "Plano" },
	-- { K = "Choice", Options = { { T, Effects, Then = { líneas } } } }, { K = "Title" }
	local function insertLine(list: { Item }, l: Item)
		if l.K == "Multi" then
			for _, x in l.Items do
				insertLine(list, x)
			end
			return
		end
		-- (la misma frase dos veces seguidas: las variantes «o» del guion que quedan iguales, p. ej. con {grupo})
		local last = list[#list]
		if last and last.K == "Line" and last.S == l.S and last.T == l.T and last.If == nil and l.If == nil then
			return
		end
		-- «Lucía: ¡Mirad…!» y debajo «Si llegó tarde: Lucía: ¡Mirad…!»: la primera es la de los demás casos
		if last and last.K == "Line" and last.S == l.S and last.T == l.T and last.If == nil and last.IfNot == nil and l.If ~= nil then
			last.IfNot = l.If
		end
		table.insert(list, l)
	end
	local function linesOf(s: Step, castKeys: { [string]: boolean }): { Item }
		local out = {}
		local lastPlano: Item? = nil
		local pause = 0
		local items = s.Items
		local i = 1
		local function line(item: Item, where: string): Item?
			-- Quien habla depende de la partida («Compañero» = Mateo u Omar): una frase por cada uno, con su If
			local alts = m.Hablantes and type(m.Hablantes[item.S]) == "table" and m.Hablantes[item.S]
			if alts and not item.AltDone then
				local multi = { K = "Multi", Items = {} }
				for _, alt in alts do
					local copy = table.clone(item)
					copy.S, copy.AltIf, copy.AltDone = alt.S, alt.If, true
					local l = line(copy, where)
					if l then
						table.insert(multi.Items, l)
					end
				end
				return if #multi.Items > 0 then multi else nil
			end
			local speaker = if item.AltDone then item.S else speakerOf(item.S, where)
			if not speaker then
				return nil
			end
			local text = item.T or ""
			if speaker:sub(1, 1) == "@" then
				-- (varios a la vez: lo dice el narrador como coro)
				speaker = "Narrador"
				text = ("%s: «%s»"):format((item.S:gsub("%.+$", "")), text)
			end
			local l: Item = { K = "Line", S = speaker, Plano = lastPlano, Src = item.Line }
			if item.Gesture then
				local g = gestureOf(item.Gesture)
				local voice = stagedDirection(item.Gesture)
				if voice and text ~= "" then
					text = "(" .. voice .. ") " .. text -- (StageDirector la convierte en acción)
				elseif g then
					l.A, l.G, l.Mood = g.A, g.G, g.Mood
				elseif text == "" then
					text = "(" .. item.Gesture .. ")"
				else
					adapted("PASO %s (línea %d): la acotación «(%s)» no tiene gesto en el juego: se queda solo la frase", s.Num, item.Line, item.Gesture)
				end
			end
			if text == "" then
				return nil
			end
			l.T = cleanText(text, speaker, ("PASO %s (línea %d)"):format(s.Num, item.Line))
			if lastPlano then
				local g = gestureOf(lastPlano.Desc)
				local subj = subjectOf(lastPlano.Subject, castKeys)
				if g and subj.Kind == "Actor" and subj.Key == speaker and not l.A and not l.G then
					l.A, l.G, l.Mood = g.A, g.G, g.Mood
				end
				if norm(lastPlano.Desc):find("pausa", 1, true) then
					pause = math.max(pause, 0.6)
				end
				if norm(lastPlano.Desc):find("baja la voz", 1, true) and not text:find("^%(") then
					l.T = "(susurrando) " .. l.T
				end
			end
			if pause > 0 then
				l.Pause = pause
				pause = 0
			end
			-- Condición de la frase («Si ropa = Camisa:») y la del PASO entero («Condición: asiento = Nico.»)
			local rawIf = item.If
			if item.RouteIf then
				rawIf = if rawIf then item.RouteIf .. " y " .. rawIf else item.RouteIf
			end
			local c = if rawIf then conditionOf(rawIf, ("PASO %s (línea %d)"):format(s.Num, item.Line)) else nil
			if c and c.Nunca then
				return nil
			end
			local sc = if s.Cond then conditionOf(s.Cond, ("PASO %s"):format(s.Num)) else nil
			if item.AltIf then
				sc = sc or {}
				for field, value in item.AltIf do
					sc[field] = if type(value) == "table" then table.clone(value) else value
				end
			end
			if sc then
				c = c or {}
				for field, value in sc do
					if type(value) == "table" and type(c[field]) == "table" and c[field] ~= value then
						for k, v in value do
							if type(k) == "number" then
								table.insert(c[field], v)
							else
								c[field][k] = v
							end
						end
					else
						c[field] = value
					end
				end
			end
			-- PorHablante = { Companero = { "Sara", "Nico" } }: lo que dice uno de ellos solo sale si es él
			-- el elegido (las variantes por compañero que el guion escribe sin «Si …»)
			-- PorTexto = { NombreGrupo = { "Los Imparables", … } }: la frase que nombra uno de esos valores
			-- solo sale si es el elegido («¡Por Los Imparables!» o «¡Por La Patrulla Valmar!»…)
			for key, values in m.PorTexto or {} do
				for _, value in values do
					if l.T and norm(l.T):find(norm(value), 1, true) and not (c and c.Choices and c.Choices[key]) then
						c = c or {}
						c.Choices = c.Choices or {}
						c.Choices[key] = value
						break
					end
				end
			end
			-- SiTexto = { { "chistes de matemáticas", { Choices = { Talento = "Chistes" } } } }: la frase que contiene
			-- ese trozo lleva esa condición (variantes que el guion escribe con un título suelto, sin «Si …»)
			for _, pair in m.SiTexto or {} do
				if l.T and norm(l.T):find(norm(pair[1]), 1, true) then
					c = c or {}
					for field, value in pair[2] do
						if type(value) == "table" then
							c[field] = c[field] or {}
							for k, v in value do
								if type(k) == "number" then
									if not table.find(c[field], v) then
										table.insert(c[field], v)
									end
								else
									c[field][k] = v
								end
							end
						else
							c[field] = value
						end
					end
				end
			end
			-- (SiTexto con { Nunca = true }: esa frase no sale)
			if c and c.Nunca then
				return nil
			end
			-- CondicionHablante = { Mateo = { Flags = { "AyudasteAMateo" } } }: lo que dice alguien solo sale con esa
			-- marca (sus recuerdos, si no los vivió, no se dicen)
			local ch = m.CondicionHablante and m.CondicionHablante[speaker]
			if ch then
				c = c or {}
				for field, value in ch do
					if type(value) == "table" and #value > 0 then
						c[field] = c[field] or {}
						for _, v in value do
							if not table.find(c[field], v) then
								table.insert(c[field], v)
							end
						end
					elseif type(value) == "table" then
						c[field] = c[field] or {}
						for k, v in value do
							c[field][k] = c[field][k] or v
						end
					end
				end
			end
			for key, who in m.PorHablante or {} do
				if table.find(who, speaker) and not (c and ((c.Choices and c.Choices[key]) or (c.NotChoices and c.NotChoices[key]))) then
					c = c or {}
					c.Choices = c.Choices or {}
					c.Choices[key] = speaker
				end
			end
			l.If = c
			lastPlano = nil
			return l
		end
		while i <= #items do
			local item = items[i]
			if item.K == "Plano" then
				lastPlano = item
				table.insert(out, { K = "Plano", Plano = item })
			elseif item.K == "Pause" then
				pause += item.Seconds
			elseif item.K == "Line" then
				local l = line(item, ("PASO %s (línea %d)"):format(s.Num, item.Line))
				if l then
					insertLine(out, l)
				end
			elseif item.K == "Title" then
				table.insert(out, { K = "Title", T = item.T, Sub = item.Sub, Transition = item.Transition })
			elseif item.K == "Choice" and (#item.Options == 0 or item.Lead) then
				-- (lo que se dice antes de elegir; una ELECCION sin opciones se queda solo en frases)
				for _, it in item.Lead or {} do
					if it.K == "Plano" then
						lastPlano = it
						table.insert(out, { K = "Plano", Plano = it })
					elseif it.K == "Pause" then
						pause += it.Seconds
					elseif it.K == "Line" then
						local l = line(it, ("PASO %s (línea %d)"):format(s.Num, it.Line))
						if l then
							insertLine(out, l)
						end
					end
				end
				item.Lead = nil
				if #item.Options > 0 then
					continue -- (vuelve a mirar esta misma elección, ya sin lo de antes)
				end
			elseif item.K == "Choice" then
				local options = {}
				for _, o in item.Options do
					local effects, notes = effectsOf(o.Effects, ("PASO %s · opción %s"):format(s.Num, o.Letter))
					for _, note in notes do
						adapted("PASO %s · opción %s: %s", s.Num, o.Letter, note)
					end
					table.insert(options, { Letter = o.Letter, T = cleanText(o.T or ("Opción " .. o.Letter), "Yo", ("PASO %s · opción %s"):format(s.Num, o.Letter)), Effects = effects, Then = {}, Cond = o.Cond and conditionOf(o.Cond, ("PASO %s · opción %s"):format(s.Num, o.Letter)) or nil })
				end
				-- Respuestas escritas dentro de cada opción
				if item.InlineEnd then
					for k, o in item.Options do
						lastPlano = nil
						for _, it in o.Items or {} do
							if it.K == "Plano" then
								lastPlano = it
							elseif it.K == "Pause" then
								pause += it.Seconds
							elseif it.K == "Line" then
								local l = line(it, ("PASO %s · respuesta %s"):format(s.Num, o.Letter))
								if l then
									insertLine(options[k].Then, l)
								end
							end
						end
					end
					table.insert(out, { K = "Choice", Ask = item.Name, Options = options, Src = item.Line })
					lastPlano = nil
					i += 1
					continue
				end
				-- Las respuestas: los grupos de frases (separados por línea en blanco) justo después,
				-- uno por opción y en orden. Los planos de antes valen para la primera frase de cada rama.
				local j = i + 1
				local shared: Item? = nil
				while j <= #items and (items[j].K == "Blank" or items[j].K == "Plano") do
					if items[j].K == "Plano" then
						shared = items[j]
					end
					j += 1
				end
				-- (si el guion separa CADA frase con una línea en blanco, los «grupos» son frases sueltas que
				-- siguen sin más: no son las respuestas de cada opción, sino lo que viene después para todos)
				local noSplit = false
				do
					local sizes, cur, k2 = {}, 0, j
					while k2 <= #items and #sizes <= #options do
						local it = items[k2]
						if it.K == "Blank" then
							if cur > 0 then
								table.insert(sizes, cur)
								cur = 0
							end
						elseif it.K == "Line" then
							cur += 1
						elseif it.K ~= "Plano" and it.K ~= "Pause" then
							break
						end
						k2 += 1
					end
					if cur > 0 then
						table.insert(sizes, cur)
					end
					local allSingle = #sizes > #options
					for n = 1, math.min(#sizes, #options + 1) do
						allSingle = allSingle and sizes[n] == 1
					end
					noSplit = allSingle
				end
				local branch = 1
				local groupStarted = false
				while not noSplit and j <= #items and branch <= #options do
					local it = items[j]
					if it.K == "Blank" then
						if groupStarted then
							branch += 1
							groupStarted = false
						end
					elseif it.K == "Line" then
						lastPlano = if not groupStarted then shared else lastPlano
						local l = line(it, ("PASO %s · respuesta %s"):format(s.Num, options[branch].Letter))
						if l then
							insertLine(options[branch].Then, l)
						end
						groupStarted = true
					elseif it.K == "Plano" then
						lastPlano = it
					elseif it.K == "Pause" then
						pause += it.Seconds
					else
						break
					end
					j += 1
				end
				if noSplit then
					j = i + 1 -- (lo de después sigue como frases de todos)
				elseif branch <= #options and not (branch == #options and groupStarted) then
					local filled = 0
					for _, o in options do
						filled += if #o.Then > 0 then 1 else 0
					end
					if filled < #options then
						adapted("PASO %s: la elección tiene %d opciones y solo %d grupos de respuesta detrás: las demás ramas siguen sin respuesta propia", s.Num, #options, filled)
					end
				end
				i = j - 1
				table.insert(out, { K = "Choice", Ask = item.Name, Options = options, Src = item.Line })
				lastPlano = nil
			elseif item.K == "Block" then
				table.insert(out, { K = "Block", Block = item })
			end
			i += 1
		end
		return out
	end

	---------------------------------------------------------------
	-- Planos -> cámara de una escena del motor
	---------------------------------------------------------------
	local MIN_SHOT = { General = 2.6, Dolly = 3, Pan = 3, Tilt = 2.6, Inserto = 2, Seguir = 2.6 }
	local SKY_FOV = { General = 70, Medio = 50, PrimerPlano = 38, PPP = 26, Inserto = 30, Reaccion = 45, Hombro = 55, DosPlanos = 60, Lateral = 55, Seguir = 60, Dolly = 45, Pan = 60, Tilt = 60 }
	local V = function(x, y, z)
		return { __v3 = { x, y, z } }
	end
	-- Un plano -> pista Camera. anchors: el mapa de anclas de la escena (se van añadiendo)
	local function cameraFor(plano: Item, at: number, duration: number, anchors: { [string]: any }, sitio: string, castKeys: { [string]: boolean }, uses: { [string]: boolean }, where: string): { [string]: any }
		local kind = plano.Kind
		local subj = subjectOf(plano.Subject, castKeys)
		local subj2 = plano.Subject2 and subjectOf(plano.Subject2, castKeys) or nil
		local function ref(sub: { [string]: any }): string?
			if sub.Kind == "Yo" then
				return "Yo"
			elseif sub.Kind == "Actor" and (castKeys[sub.Key] or game.Cast[sub.Key]) then
				uses[sub.Key] = true
				return sub.Key
			elseif sub.Kind == "Place" then
				local name = "L_" .. sub.Place
				anchors[name] = "Place:" .. sub.Place
				return name
			end
			return nil
		end
		local shot: { [string]: any } = { At = at, Duration = duration }
		if subj.Kind == "Sky" then
			anchors.Grieta = "Rift"
			local fov = SKY_FOV[kind] or 55
			if kind == "Tilt" or kind == "Pan" then
				shot.From = { "Yo", V(1.4, 1.7, 3.6), true }
				shot.To = { "Yo", V(1.3, 2.3, 3.3), true }
				shot.Look = { "Yo", V(0, 1.6, 0) }
				shot.LookTo = { "Grieta" }
				shot.Fov = { 70, fov }
			elseif kind == "Dolly" then
				shot.From = { "Yo", V(1.4, 2.2, 4.2), true }
				shot.To = { "Yo", V(1.1, 2.4, 2.8), true }
				shot.Look = { "Grieta" }
				shot.Fov = { 60, 40 }
			else
				shot.Fixed = { "Yo", V(1.4, 2.2, 3.6), true }
				shot.Look = { "Grieta" }
				shot.Fov = fov
				if kind == "PPP" or kind == "PrimerPlano" or kind == "Inserto" then
					shot.Shake = 0.15
				end
			end
			return shot
		end
		if subj.Kind == "Big" then
			local base = sitio
			if subj.Place then
				base = "L_" .. subj.Place
				anchors[base] = "Place:" .. subj.Place
			end
			if subj.Kind == "None" then
				adapted("%s: el plano %s de «%s» no tiene sitio en el juego: plano general del lugar del paso", where, kind, tostring(plano.Subject))
			end
			if kind == "Dolly" then
				shot.From = { base, V(-60, 75, 60) }
				shot.To = { base, V(-36, 52, 38) }
				shot.Look = { base, V(0, 2, 0) }
			elseif kind == "Pan" then
				shot.Fixed = { base, V(-30, 55, 40) }
				shot.Look = { base, V(-40, 5, -20) }
				shot.LookTo = { base, V(40, 5, -10) }
				shot.Fixed = nil
				shot.From = { base, V(-30, 55, 40) }
				shot.To = { base, V(-28, 55, 38) }
			elseif kind == "Tilt" then
				shot.From = { base, V(-24, 45, 30) }
				shot.To = { base, V(-24, 48, 30) }
				shot.Look = { base, V(0, 0, 0) }
				shot.LookTo = { base, V(0, 40, -40) }
			else
				shot.From = { base, V(-45, 60, 50) }
				shot.To = { base, V(25, 64, 44) }
				shot.Look = { base, V(30, 0, 0) }
				shot.Shake = 0.15
			end
			return shot
		end
		local a = ref(subj)
		if not a then
			-- (lo que no se encuentra: un plano del lugar del paso)
			adapted("%s: el plano %s de «%s» no se encuentra en la escena: plano General del lugar", where, kind, tostring(plano.Subject))
			shot.Shot = "General:" .. sitio
			return shot
		end
		if kind == "Hombro" or kind == "DosPlanos" then
			local b = subj2 and ref(subj2)
			if not b then
				b = if a == "Yo" then nil else "Yo"
			end
			if not b or b == a then
				shot.Shot = "Medio:" .. a
			else
				shot.Shot = ("%s:%s%s%s"):format(kind, a, if kind == "Hombro" then ">" else ",", b)
			end
		elseif kind == "Pan" and subj2 then
			local b = ref(subj2)
			shot.Shot = if b and b ~= a then ("Pan:%s>%s"):format(a, b) else "Pan:" .. a
		else
			shot.Shot = kind .. ":" .. a
		end
		return shot
	end

	-- Frases + planos -> escena del motor (cinemática o ligera)
	local function sceneFrom(blocks: { Item }, opts: { [string]: any }): ({ [string]: any }?, number)
		local light = opts.Light == true
		local sitio = opts.Sitio
		local anchors: { [string]: any } = { Yo = "Player" }
		local tracks: { [string]: any } = {}
		local uses: { [string]: boolean } = {}
		local camera, dialogue, actors, titles, sky = {}, {}, {}, {}, {}
		local t = opts.Start or 0.4
		local currentShot: { [string]: any }? = nil
		local shotStart = t
		local shotPlano: Item? = nil
		local function closeShot()
			if currentShot then
				local min = MIN_SHOT[shotPlano and shotPlano.Kind or ""] or 2
				if t - shotStart < 0.01 then
					min = math.min(min, 2) -- (un plano sin frases: solo lo que se tarda en verlo)
				end
				if t - shotStart < min then
					t = shotStart + min
				end
				currentShot.Duration = math.floor((t - shotStart) * 10 + 0.5) / 10
				currentShot.At = math.floor(shotStart * 100 + 0.5) / 100
				table.insert(camera, currentShot)
				currentShot = nil
			end
		end
		local count = 0
		for _, b in blocks do
			if b.K == "Plano" and not light then
				closeShot()
				shotStart = t
				shotPlano = b.Plano
				local subjKeys = opts.CastKeys
				currentShot = cameraFor(b.Plano, t, 1, anchors, sitio, subjKeys, uses, opts.Where)
				if currentShot.Shot == nil and #camera > 0 then
					currentShot.Cut = "Dip"
				end
				local subj = subjectOf(b.Plano.Subject, subjKeys)
				local g = gestureOf(b.Plano.Desc)
				if subj.Kind == "Actor" and (subjKeys[subj.Key] or game.Cast[subj.Key]) and g then
					uses[subj.Key] = true
					if g.G then
						table.insert(actors, { At = t + 0.2, Gesture = { Key = subj.Key, Play = g.G } })
					elseif g.Mood then
						table.insert(actors, { At = t + 0.1, Mood = { Key = subj.Key, Mood = g.Mood } })
					end
				end
				if subj.Kind == "Sky" and (norm(b.Plano.Desc):find("ilumin", 1, true) or norm(b.Plano.Desc):find("destello", 1, true) or norm(b.Plano.Desc):find("vibra", 1, true) or norm(b.Plano.Desc):find("cambia", 1, true) or norm(b.Plano.Desc):find("aparece", 1, true)) then
					anchors.Grieta = "Rift"
					table.insert(sky, { At = t + 0.3, Rift = "Flare", Strength = 0.8, Seconds = 2.2 })
				end
				if subj.Kind == "Actor" and (subjKeys[subj.Key] or game.Cast[subj.Key]) and (norm(b.Plano.Desc):find("mira hacia el cielo", 1, true) or norm(b.Plano.Desc):find("mira otra vez hacia la grieta", 1, true) or norm(b.Plano.Desc):find("observa la grieta", 1, true) or norm(b.Plano.Desc):find("vuelve a mirar la grieta", 1, true)) then
					anchors.Grieta = "Rift"
					table.insert(actors, { At = t + 0.2, Look = { Key = subj.Key, At = "Grieta" } })
				end
			elseif b.K == "Plano" and light then
				local subj = subjectOf(b.Plano.Subject, opts.CastKeys)
				local nd = norm(b.Plano.Desc)
				if subj.Kind == "Sky" and (nd:find("ilumin", 1, true) or nd:find("destello", 1, true) or nd:find("cambia", 1, true) or nd:find("aparece", 1, true) or nd:find("vibra", 1, true)) then
					anchors.Grieta = "Rift"
					table.insert(sky, { At = t, Rift = "Flare", Strength = 0.6, Seconds = 2 })
				end
			elseif b.K == "Line" then
				count += 1
				local before = b.Pause or 0
				t += before
				local entry: { [string]: any } = { At = math.floor(t * 10 + 0.5) / 10, S = b.S, T = b.T }
				if b.S ~= "Narrador" and b.S ~= "Yo" then
					if opts.CastKeys[b.S] or game.Cast[b.S] then
						uses[b.S] = true
						entry.To = "Yo"
					end
				end
				if b.Mood and b.S ~= "Narrador" and b.S ~= "Yo" then
					entry.Mood = b.Mood
				end
				if b.If then
					entry.If = b.If
				end
				if b.IfNot then
					entry.IfNot = b.IfNot
				end
				-- («Si NO te cubres»: IfNot = { Input = … } de la espera de la escena)
				if entry.If and entry.If.NotInput then
					entry.IfNot = { Input = entry.If.NotInput }
					entry.If = table.clone(entry.If)
					entry.If.NotInput = nil
					if next(entry.If) == nil then
						entry.If = nil
					end
				end
				table.insert(dialogue, entry)
				t += Seq.lineSeconds(b.T) + Seq.LINE_GAP
			elseif b.K == "Title" then
				table.insert(titles, { At = math.floor(t * 10 + 0.5) / 10, Text = b.T, Sub = b.Sub, Duration = 3.2 })
				t += 3.4
			end
		end
		closeShot()
		if count == 0 and #camera == 0 and #titles == 0 and #sky == 0 then
			return nil, 0
		end
		-- Lo que tienen en común todas las frases de alguien (si solo habla con fútbol, solo está con
		-- fútbol): su Use lleva esa condición
		local function commonIf(key: string): { [string]: any }?
			local common: { [string]: string }? = nil
			for _, d in dialogue do
				if d.S == key then
					local ch = d.If and d.If.Choices
					if not ch then
						return nil
					end
					if common == nil then
						common = table.clone(ch)
					else
						for k, v in common do
							if ch[k] ~= v then
								common[k] = nil
							end
						end
					end
				end
			end
			return if common and next(common) then { Choices = common } else nil
		end
		for key in uses do
			if key ~= "Yo" and game.Cast[key] and opts.Allowed and not opts.Allowed[key] then
				-- (no está en el paso que lanza la escena: habla sin que la escena lo traiga; sus planos y
				-- gestos pasan a un plano general)
				uses[key] = nil
				for _, shot in camera do
					if type(shot.Shot) == "string" and (shot.Shot:find(":" .. key, 1, true) or shot.Shot:find(">" .. key, 1, true) or shot.Shot:find("," .. key, 1, true)) then
						shot.Shot = "General:" .. (sitio or "Yo")
					end
				end
				for i = #actors, 1, -1 do
					local a = actors[i]
					local body = a.Look or a.Gesture or a.Mood
					if body and body.Key == key then
						table.remove(actors, i)
					end
				end
			end
		end
		for key in uses do
			if key ~= "Yo" and game.Cast[key] then
				local use: { [string]: any } = { Key = key, Npc = key }
				local place = actorPlace[key]
				if place then
					local anchor = "A_" .. key
					anchors[anchor] = "Place:" .. place
					use.Anchor = anchor
				end
				table.insert(actors, 1, { At = 0, Use = use, If = commonIf(key) })
			end
		end
		table.sort(actors, function(x, y)
			return (x.At or 0) < (y.At or 0)
		end)
		if not light and #camera > 0 then
			tracks.Camera = camera
		end
		if #dialogue > 0 then
			tracks.Dialogue = dialogue
		end
		if #actors > 0 then
			tracks.Actors = actors
		end
		if #titles > 0 then
			tracks.Titles = titles
		end
		if #sky > 0 then
			tracks.Sky = sky
		end
		if opts.Music and #opts.Music > 0 then
			local music = {}
			local step = if #opts.Music > 1 then t / #opts.Music else 0
			for k, intensity in opts.Music do
				table.insert(music, { At = math.floor((k - 1) * step * 10 + 0.5) / 10, Intensity = intensity })
			end
			tracks.Music = music
		end
		local scene: { [string]: any } = { Anchors = anchors, Tracks = tracks }
		if not light then
			scene.Skippable = true
		else
			scene.Light = true
		end
		local lastAt = t
		for _, d in dialogue do
			lastAt = math.max(lastAt, d.At + Seq.lineSeconds(d.T))
		end
		for _, ti in titles do
			lastAt = math.max(lastAt, ti.At + (ti.Duration or 3))
		end
		for _, sk in sky do
			lastAt = math.max(lastAt, sk.At + (sk.Seconds or 2))
		end
		for _, a in actors do
			lastAt = math.max(lastAt, (a.At or 0) + 0.5)
		end
		local duration = math.max(lastAt + 0.6, opts.MinDuration or 0)
		scene.Duration = math.ceil(duration * 10) / 10
		if sitio and not anchors[sitio] then
			anchors[sitio] = "Player"
		end
		return scene, duration
	end

	---------------------------------------------------------------
	-- Frases -> líneas de una conversación (DialogueService + StageDirector)
	---------------------------------------------------------------
	local DIALOGUE_SHOT = { General = "General", Medio = "Medio", PrimerPlano = "PrimerPlano", PPP = "PPP", Hombro = "Hombro", DosPlanos = "DosPlanos", Lateral = "Lateral", Reaccion = "Reaccion", Seguir = "Seguir", Inserto = "General", Dolly = "PrimerPlano", Pan = "General", Tilt = "Medio" }
	local function dialogueShot(plano: Item?, speaker: string, castKeys: { [string]: boolean }): string?
		if not plano then
			return nil
		end
		local kind = DIALOGUE_SHOT[plano.Kind] or "General"
		local subj = subjectOf(plano.Subject, castKeys)
		local function who(sub: { [string]: any }?): string?
			if not sub then
				return nil
			end
			if sub.Kind == "Yo" then
				return "Yo"
			elseif sub.Kind == "Actor" and (castKeys[sub.Key] or game.Cast[sub.Key]) then
				return sub.Key
			end
			return nil
		end
		local a = who(subj)
		if kind == "General" or not a then
			return "General"
		end
		if kind == "Hombro" or kind == "DosPlanos" then
			local b = who(plano.Subject2 and subjectOf(plano.Subject2, castKeys) or nil)
			if not b or b == a then
				b = if a == "Yo" then (if speaker ~= "Yo" and speaker ~= "Narrador" then speaker else nil) else "Yo"
			end
			if not b or b == a then
				return "Medio:" .. a
			end
			return ("%s:%s%s%s"):format(kind, a, if kind == "Hombro" then ">" else ",", b)
		end
		return kind .. ":" .. a
	end
	local function dialogueLines(blocks: { Item }, castKeys: { [string]: boolean }, oldLines: { any }?, where: string): { any }
		local out = {}
		-- Las opciones de la conversación vieja (por orden): sus efectos se conservan
		local oldAsks = {}
		local function collect(list: { any }?)
			for _, l in list or {} do
				if type(l) == "table" and l.Ask then
					table.insert(oldAsks, l)
				end
			end
		end
		collect(oldLines)
		local askIndex = 0
		local function convert(b: Item): { [string]: any }
			local l: { [string]: any } = { S = b.S, T = b.T }
			if b.S ~= "Narrador" and b.S ~= "Yo" then
				l.To = "Yo"
			end
			local shot = dialogueShot(b.Plano, b.S, castKeys)
			if shot then
				l.Shot = shot
			end
			if b.A then
				l.A = b.A
			end
			if b.G then
				l.G = b.G
			end
			if b.Pause then
				l.Pause = math.min(b.Pause, 3)
			end
			if b.If then
				l.If = b.If
				-- (en una conversación no hay esperas de escena: Input no vale)
				if l.If.Input ~= nil or l.If.NotInput ~= nil then
					l.If = table.clone(l.If)
					l.If.Input, l.If.NotInput = nil, nil
					if next(l.If) == nil then
						l.If = nil
					end
				end
			end
			if b.IfNot and not l.If then
				-- (las conversaciones solo entienden If: «no X» se escribe al revés)
				local neg: { [string]: any } = {}
				local ok = true
				for field, value in b.IfNot do
					if field == "Flags" then
						neg.NotFlags = value
					elseif field == "NotFlags" then
						neg.Flags = value
					elseif field == "Choices" then
						neg.NotChoices = value
					elseif field == "NotChoices" then
						neg.Choices = value
					elseif field == "LastGradeAtLeast" then
						neg.LastGradeBelow = value
					elseif field == "LastGradeBelow" then
						neg.LastGradeAtLeast = value
					else
						ok = false
					end
				end
				local count = 0
				for _, v in b.IfNot do
					count += if type(v) == "table" then #v + (if next(v) and #v == 0 then 1 else 0) else 1
				end
				if ok and count == 1 then
					l.If = neg
				end
			end
			return l
		end
		for _, b in blocks do
			if b.K == "Line" then
				table.insert(out, convert(b))
			elseif b.K == "Choice" then
				askIndex += 1
				local old = oldAsks[askIndex]
				local ask: { [string]: any } = { Ask = b.Ask or (old and old.Ask) or "¿Qué dices?", Options = {} }
				for k, o in b.Options do
					local oldOption = old and old.Options and old.Options[k]
					local option: { [string]: any } = if oldOption then table.clone(oldOption) else {}
					option.T = "«" .. o.T .. "»"
					if o.Cond and option.If == nil then
						option.If = o.Cond
					end
					-- Efectos: los del juego se quedan; se suma lo que pide el guion
					local effects = if oldOption and oldOption.Effects then table.clone(oldOption.Effects) else {}
					for field, value in o.Effects do
						if type(value) == "table" and type(effects[field]) == "table" then
							local mergedValue = table.clone(effects[field])
							if #value > 0 then
								for _, item in value do
									if not table.find(mergedValue, item) then
										table.insert(mergedValue, item)
									end
								end
							else
								for key, v in value do
									if mergedValue[key] ~= nil and mergedValue[key] ~= v then
										adapted("%s · opción %s: el guion pide %s.%s = %s y el juego ya da %s: se queda lo del juego", where, o.Letter, field, key, tostring(v), tostring(mergedValue[key]))
									else
										mergedValue[key] = v
									end
								end
							end
							effects[field] = mergedValue
						elseif effects[field] == nil then
							effects[field] = value
						end
					end
					if next(effects) then
						option.Effects = effects
					end
					local thenLines = {}
					for _, tb in o.Then do
						table.insert(thenLines, convert(tb))
					end
					option.Then = if #thenLines > 0 then thenLines else nil
					table.insert(ask.Options, option)
				end
				if old and old.Options and #old.Options ~= #b.Options then
					adapted("%s: la elección del juego tenía %d opciones y el guion trae %d", where, #old.Options, #b.Options)
				end
				table.insert(out, ask)
			end
		end
		-- Las frases viejas con efectos (marcas, objetos, relación…) los siguen dando: al final, sin texto
		for _, l in oldLines or {} do
			if type(l) == "table" and not l.Ask and type(l.Effects) == "table" then
				local effects = table.clone(l.Effects)
				effects.Scene = nil -- (las escenas de las frases viejas ya no tocan)
				if next(effects) then
					table.insert(out, { Effects = effects, If = l.If, IfNot = l.IfNot })
					adapted("%s: una frase del juego daba efectos (%s): se conservan al final de la conversación", where, table.concat((function()
						local keys = {}
						for k in effects do
							table.insert(keys, k)
						end
						table.sort(keys)
						return keys
					end)(), ", "))
				end
			end
		end
		if askIndex < #oldAsks then
			-- (una pregunta del juego guarda decisiones que usan otros pasos: no se puede perder)
			for k = askIndex + 1, #oldAsks do
				table.insert(out, oldAsks[k])
			end
			adapted("%s: la conversación del juego tenía %d preguntas y el guion %d: las que faltan se conservan tal cual al final (guardan decisiones que usa la historia)", where, #oldAsks, askIndex)
		end
		return out
	end

	---------------------------------------------------------------
	-- Paso a paso
	---------------------------------------------------------------
	-- Agrupar los PASO del guion por paso del juego
	local byTarget: { [string]: { Step } } = {}
	local dialogueTarget: { [string]: string } = {}
	local order: { string } = {}
	for _, s in doc.Steps do
		local target = map[s.Num]
		table.insert(R.Map, { Num = s.Num, Type = s.Type, Place = s.Place, Target = target })
		if target == false or target == nil then
			adapted("PASO %s [%s] @ %s: no corresponde a ningún paso del juego: no se aplica", s.Num, s.Type, s.Place)
			continue
		end
		-- Varios pasos con la MISMA conversación (Presentaciones con un If por asiento): una sola
		-- conversación con las frases de todos (las de cada PASO con su condición)
		local gs0 = if target:sub(1, 1) == "@" then nil else stepAt(steps, target)
		local dname = gs0 and (((gs0.Type == "Talk" or gs0.Type == "Scene") and gs0.Dialogue) or (gs0.Type == "Cinematic" and game.Happenings[gs0.Id or ""] and not game.Cinematics[gs0.Id or ""] and gs0.Id))
		if dname then
			local canonical = dialogueTarget[dname]
			if canonical and canonical ~= target then
				adapted("PASO %s: el paso %s del juego usa la misma conversación «%s» que el paso %s: sus frases van en ella%s", s.Num, target, dname, canonical, if s.Cond then " (con su condición: " .. s.Cond .. ")" else "")
				target = canonical
			else
				dialogueTarget[dname] = target
			end
		end
		if not byTarget[target] then
			byTarget[target] = {}
			table.insert(order, target)
		end
		table.insert(byTarget[target], s)
	end

	local sceneCount = 0
	local function newSceneId(tag: string): string
		sceneCount += 1
		return ("%s_G%s"):format(prefix, tag)
	end
	local stepPatches: { [string]: { [string]: any } } = guion.Steps
	local function patch(path: string): { [string]: any }
		stepPatches[path] = stepPatches[path] or {}
		return stepPatches[path]
	end
	-- Sitio de cada paso (para los planos de lugar)
	local lastPlace = missionPlaces[1] or "Player"
	local function siteOf(gs: { [string]: any }): string?
		local p = gs.Place or (type(gs.Teleport) == "table" and gs.Teleport.Place) or (type(gs.Teleport) == "string" and gs.Teleport)
		if type(p) == "string" and game.Places[p] then
			return p
		end
		if gs.Type == "Talk" and gs.Npc and actorPlace[gs.Npc] then
			return actorPlace[gs.Npc]
		end
		if gs.Type == "Use" and gs.Prop and quest.Props and quest.Props[gs.Prop] then
			return quest.Props[gs.Prop].Place
		end
		return nil
	end
	-- Actores que puede haber en las escenas de la misión
	local castKeys: { [string]: boolean } = {}
	for _, a in quest.Actors or {} do
		if a.Npc then
			castKeys[a.Npc] = true
		end
	end
	for _, npc in quest.Npcs or {} do
		castKeys[npc] = true
	end
	local function stepCast(gs: { [string]: any }): { [string]: boolean }
		local keys = table.clone(castKeys)
		for _, a in (type(gs.Actors) == "table" and gs.Actors) or {} do
			if type(a) == "table" and a.Npc then
				keys[a.Npc] = true
			end
		end
		if gs.Npc then
			keys[gs.Npc] = true
		end
		keys.Familia = keys.Familia or (game.Cast.Familia ~= nil and (castKeys.Familia_Padre or false)) or nil
		return keys
	end
	-- ¿La acción del paso ya está hecha en este plano? (salta, recoge, coge, abre…)
	local DONE_VERBS = { "salta", "recoge", "coge", "abre", "llega", "entra", "consigue", "atrapa", "termina", "encuentra", "lanza", "marca", "gana", "da un ultimo paso", "lo consigue", "logra" }
	local function isDonePlano(p: Item): boolean
		local subj = subjectOf(p.Subject, {})
		if subj.Kind ~= "Yo" then
			return false
		end
		local nd = " " .. norm(p.Desc) .. " "
		for _, v in DONE_VERBS do
			if nd:find(" " .. v, 1, true) then
				return true
			end
		end
		return false
	end
	local enterScenes: { [string]: string } = {} -- paso del juego -> escena al entrar (va en el anterior)
	-- Escenas ligeras que ya lanza un paso al cumplirse (las frases del principio del paso siguiente se
	-- añaden detrás, en la misma escena: un paso solo lanza una)
	local slotScenes: { [string]: { [string]: any } } = {}
	local topIndex = function(path: string): number
		return tonumber(path:match("^(%d+)")) or 0
	end

	for _, target in order do
		local scripts = byTarget[target]
		local gs = (if target:sub(1, 1) == "@" then { Type = "Cinematic", Id = target:sub(2) } else stepAt(steps, target)) :: { [string]: any }
		local cat = categoryOfGame(gs)
		local keys = stepCast(gs)
		local site = siteOf(gs) or lastPlace
		lastPlace = site
		local nums = {}
		local music = {}
		local blocks: { Item } = {}
		local objectives = {}
		local cond = nil
		for _, s in scripts do
			table.insert(nums, s.Num)
			for _, mu in musicOf(s) do
				if music[#music] ~= mu then
					table.insert(music, mu)
				end
			end
			for _, b in linesOf(s, keys) do
				table.insert(blocks, b)
			end
			for _, o in s.Objectives do
				table.insert(objectives, o)
			end
			cond = cond or s.Cond
			for _, item in s.Items do
				if item.K == "Block" then
					local notes = {}
					for _, it in item.Items do
						table.insert(notes, if it.K == "Line" then (it.S .. ": " .. (it.T or "")) else (it.T or it.Desc or ""))
					end
					table.insert(R.Notes, ("PASO %s · %s: %s"):format(s.Num, item.Head, table.concat(notes, " / ")))
				end
			end
		end
		local label = "PASO " .. table.concat(nums, "+")
		local gameLabel = ("paso %s del juego (%s%s)"):format(target, gs.Type, if gs.Dialogue then " «" .. gs.Dialogue .. "»" else (if gs.Id then " «" .. gs.Id .. "»" else ""))
		for _, s in scripts do
			local want = categoryOfScript(s.Type)
			if want ~= cat and not (want == "text" and cat == "cine") then
				local NAMES = { cine = "cinemática", talk = "conversación", play = "paso jugable", text = "transición" }
				adapted("PASO %s: el guion lo escribe como [%s] y en el juego es %s (%s): se conserva el tipo del juego y su mecánica", s.Num, s.Type, NAMES[cat] or cat, gs.Type)
			end
		end
		if cond then
			local c = conditionOf(cond, label)
			if c and not gs.If then
				adapted("%s: «Condición: %s» — el paso del juego no tiene condición: el paso sigue saliendo siempre (su mecánica no cambia) y la condición se pone en sus frases", label, cond)
			end
		end
		local hasLines = false
		for _, b in blocks do
			if b.K == "Line" or b.K == "Choice" then
				hasLines = true
			end
		end
		local function lineCount(list: { Item }): number
			local n = 0
			for _, b in list do
				if b.K == "Line" then
					n += 1
				elseif b.K == "Choice" then
					n += 1
					for _, o in b.Options do
						n += #o.Then
					end
				end
			end
			return n
		end
		if cat == "cine" then
			-- Cinemática: escena del motor nueva (un plano por PLANO)
			-- Una escena del motor que ya existía se reescribe con su misma id (la misión no cambia); una
			-- cinemática vieja de vuelo (Cinematics.luau) se cambia por una escena nueva
			local oldSceneId = gs.Id or gs.Cinematic
			local inPlace = type(oldSceneId) == "string" and game.Happenings[oldSceneId] ~= nil and not game.Cinematics[oldSceneId]
			-- Despues = { "14" }: las frases del guion van en una escena NUEVA que sale justo DESPUÉS de la
			-- de siempre (que no se toca: sus mensajes, sus actores…)
			local after = inPlace and m.Despues ~= nil and table.find(m.Despues, target) ~= nil
			if after then
				inPlace = false
			end
			local id = if inPlace then oldSceneId else newSceneId((table.concat(nums, "_"):gsub("%.", "_")))
			local blocksNoChoice = {}
			for _, b in blocks do
				if b.K == "Choice" then
					adapted("%s: hay una ELECCION dentro de una cinemática (el motor de escenas no tiene preguntas): sus frases van seguidas, sin elegir", label)
					for _, o in b.Options do
						for _, l in o.Then do
							table.insert(blocksNoChoice, l)
						end
						break
					end
				else
					table.insert(blocksNoChoice, b)
				end
			end
			local old = game.Cinematics[gs.Id or gs.Cinematic or ""] or game.Happenings[gs.Id or gs.Cinematic or ""]
			local keepTitles = m.Rotulos and m.Rotulos[nums[1]]
			if keepTitles then
				local src = game.Cinematics[keepTitles]
				local start = 0
				for _, b in blocksNoChoice do
					if b.K == "Line" then
						start += 1
					end
				end
				for _, title in (src and src.Titles) or {} do
					table.insert(blocksNoChoice, { K = "Title", T = title.TextKey, Sub = title.SubKey, Keep = true })
				end
				applied("%s: se conservan los rótulos de «%s» (explican el juego)", label, keepTitles)
			end
			-- Quién puede traer la escena: los actores del paso (y los que ya traía la escena de antes)
			local allowed: { [string]: boolean }? = nil
			if inPlace and (type(gs.Actors) == "table" or (old and old.Tracks and old.Tracks.Actors)) then
				allowed = {}
				for _, a in (type(gs.Actors) == "table" and gs.Actors) or {} do
					if type(a) == "table" and a.Npc then
						allowed[a.Npc] = true
					end
				end
				for _, a in (old and old.Tracks and old.Tracks.Actors) or {} do
					local body = a.Use or a.Spawn or a.Enter
					if body and (body.Npc or body.Key) then
						allowed[body.Npc or body.Key] = true
					end
				end
			end
			local scene = sceneFrom(blocksNoChoice, { Sitio = "Sitio", CastKeys = keys, Music = music, Where = label, Allowed = allowed })
			if scene then
				scene.Anchors.Sitio = "Place:" .. site
				if site == "Player" then
					scene.Anchors.Sitio = "Player"
				end
				if old then
					scene.FadeIn = old.FadeIn
					scene.FadeOut = old.FadeOut
					scene.AfterScene = old.AfterScene
					scene.Sting = old.Sting
					scene.Montaje = old.Montaje -- (montaje de cambio de etapa: de qué etapa a cuál)
					scene.Center = old.Center
					scene.Light = old.Light
					-- El ambiente y la luz de la escena de antes (la casa, el interior cálido…) se quedan
					for _, track in { "Ambience", "Light" } do
						if old.Tracks and old.Tracks[track] then
							scene.Tracks[track] = old.Tracks[track]
						end
					end
					if old.Music and #music == 0 then
						scene.Music = old.Music
					end
					-- La mecánica de la escena de antes se queda: el estado del mundo que cambia (cráteres…),
					-- las esperas del jugador («¡Cúbrete!») y lo que se da por hecho al saltarla
					for _, track in { "World", "Wait" } do
						if old.Tracks and old.Tracks[track] and not scene.Tracks[track] then
							scene.Tracks[track] = old.Tracks[track]
						end
					end
					scene.OnSkip = scene.OnSkip or old.OnSkip
				end
				-- Una escena del motor reescrita sin PLANO en el guion: se queda con la cámara (y los actores) de
				-- antes, para que siga siendo una cinemática
				if inPlace and old and old.Tracks and old.Tracks.Camera and not scene.Tracks.Camera then
					scene.Tracks.Camera = old.Tracks.Camera
					scene.Skippable = true
					local used = {}
					local merged = table.clone(old.Tracks.Actors or {})
					for _, a in merged do
						local body = a.Use or a.Spawn or a.Enter
						if body and body.Key then
							used[body.Key] = true
						end
					end
					for _, a in scene.Tracks.Actors or {} do
						if not (a.Use and used[a.Use.Key]) then
							table.insert(merged, a)
						end
					end
					scene.Tracks.Actors = merged
					-- (y los efectos que esa cámara sigue: meteoritos, temblores, el cielo)
					for _, track in { "Fx", "Shake", "Sky" } do
						if old.Tracks[track] and not scene.Tracks[track] then
							scene.Tracks[track] = old.Tracks[track]
						end
					end
					for name, anchor in old.Anchors or {} do
						scene.Anchors[name] = scene.Anchors[name] or anchor
					end
					adapted("%s: el guion no trae planos para «%s»: se conservan los de la escena de antes", label, id)
				end
				-- Una cinemática nueva sin PLANO en el guion: un plano general lento del sitio todo el rato
				if not inPlace and not scene.Tracks.Camera then
					scene.Tracks.Camera = { { At = 0, Duration = scene.Duration, From = { "Sitio", V(-26, 18, 30) }, To = { "Sitio", V(-14, 12, 18) }, Look = { "Sitio", V(0, 2, 0) }, Fov = 60 } }
					scene.Skippable = true
					adapted("%s: el guion no trae planos para la cinemática: un plano general lento del sitio", label)
				end
				-- (lo heredado de la escena de antes puede ir más allá del final nuevo)
				for _, list in scene.Tracks do
					for _, ev in list do
						local ending = if type(ev) == "table" and type(ev.At) == "number" then ev.At + math.max(tonumber(ev.Duration) or tonumber(ev.Seconds) or 0, 0.5) else 0
						if ending > scene.Duration then
							scene.Duration = math.ceil(ending * 10) / 10
						end
					end
				end
				-- (los rótulos conservados llevan su clave de Strings en Text: HappeningClient la traduce)
				guion.Scenes[id] = scene
				if scene.Duration > 90 then
					warnf("%s: la cinemática nueva dura %d s (se puede saltar, pero es larga: el guion trae %d planos)", label, math.floor(scene.Duration), #(scene.Tracks.Camera or {}))
				end
				if after then
					local old = game.Happenings[oldSceneId]
					local copy = Reescritura.deepClone(old)
					scene.AfterScene = old.AfterScene
					copy.AfterScene = id
					guion.Scenes[oldSceneId] = copy
					applied("%s → %s: escena nueva «%s» (%d planos, %d frases, %.1f s) justo después de «%s», que se queda como estaba", label, gameLabel, id, #(scene.Tracks.Camera or {}), #(scene.Tracks.Dialogue or {}), scene.Duration, oldSceneId)
				elseif inPlace then
					applied("%s → %s: la escena «%s» se cuenta con el guion nuevo (misma escena, %d planos, %d frases, %.1f s%s)", label, gameLabel, id, #(scene.Tracks.Camera or {}), #(scene.Tracks.Dialogue or {}), scene.Duration, if #music > 0 then ", música " .. table.concat(music, "→") else "")
				else
					local field = if gs.Type == "Cinematic" then "Id" else "Cinematic"
					patch(target).Set = { [field] = id }
					applied("%s → %s: cinemática nueva «%s» (%d planos, %d frases, %.1f s%s) en lugar de «%s»", label, gameLabel, id, #(scene.Tracks.Camera or {}), #(scene.Tracks.Dialogue or {}), scene.Duration, if #music > 0 then ", música " .. table.concat(music, "→") else "", tostring(oldSceneId))
				end
			end
		elseif cat == "talk" then
			-- Conversación: las frases nuevas (con su plano, gesto y pausa) y las elecciones con sus efectos
			local name = (m.Dialogos and m.Dialogos[nums[1]]) or gs.Dialogue
			local oldDialogue = quest.Dialogues and quest.Dialogues[name]
			local oldLines = oldDialogue and (oldDialogue.Lines or oldDialogue)
			local lines = dialogueLines(blocks, keys, oldLines, label)
			if #lines > 0 then
				if gs.Stage then
					patch(target).Set = { Stage = false }
					adapted("%s: el paso usaba la escena hecha a mano «%s»; ahora se escenifica la conversación nueva (StageDirector) con sus planos", label, gs.Stage)
				end
				-- Música: una escena ligera al empezar la conversación (dura lo que la conversación)
				if #music > 0 then
					local seconds = 2
					for _, b in blocks do
						if b.K == "Line" then
							seconds += Seq.lineSeconds(b.T) + 0.6
						end
					end
					local mid = newSceneId(table.concat(nums, "_"):gsub("%.", "_") .. "_Musica")
					local scene = sceneFrom({}, { Light = true, Sitio = "Sitio", CastKeys = keys, Music = music, MinDuration = seconds, Where = label })
					if not scene then
						scene = { Light = true, Anchors = { Yo = "Player" }, Duration = math.floor(seconds * 10 + 0.5) / 10, Tracks = { Music = {} } }
						for k, intensity in music do
							table.insert(scene.Tracks.Music, { At = if k == 1 then 0 else math.floor(seconds * (k - 1) / #music * 10 + 0.5) / 10, Intensity = intensity })
						end
					end
					guion.Scenes[mid] = scene
					local first = lines[1]
					if first then
						first.Effects = first.Effects or {}
						first.Effects.Scene = mid
					end
				end
				guion.Dialogues[name] = { Lines = lines }
				-- Efectos sueltos del PASO («-> pista_sara = true»): se suman a los de la conversación
				local loose = {}
				for _, s in scripts do
					for _, e in s.Effects or {} do
						table.insert(loose, e)
					end
				end
				if #loose > 0 then
					local extra, notes = effectsOf(loose, label)
					for _, note in notes do
						-- (una marca suelta que no existe en el juego no la lee nadie: no se crea)
						local newName = note:match("^marca nueva «(.-)»") or note:match("^decisión nueva «(.-)»")
						if newName then
							if type(extra.Flags) == "table" then
								local i = table.find(extra.Flags, newName)
								if i then
									table.remove(extra.Flags, i)
								end
								if #extra.Flags == 0 then
									extra.Flags = nil
								end
							end
							if type(extra.Choice) == "table" then
								extra.Choice[newName] = nil
								if next(extra.Choice) == nil then
									extra.Choice = nil
								end
							end
							adapted("%s: «%s» no la lee ninguna misión: no se crea", label, (note:match("%((.-)%)$") or newName))
						else
							adapted("%s: %s", label, note)
						end
					end
					local base = if oldDialogue and type(oldDialogue.Effects) == "table" then table.clone(oldDialogue.Effects) else {}
					local changed = false
					for field, value in extra do
						if type(value) == "table" and #value > 0 then
							local list = if type(base[field]) == "table" then table.clone(base[field]) else {}
							for _, item in value do
								if not table.find(list, item) then
									table.insert(list, item)
									changed = true
								end
							end
							base[field] = list
						elseif type(value) == "table" then
							local map = if type(base[field]) == "table" then table.clone(base[field]) else {}
							for k, v in value do
								if map[k] == nil then
									map[k] = v
									changed = true
								end
							end
							base[field] = map
						elseif base[field] == nil then
							base[field] = value
							changed = true
						end
					end
					if changed then
						guion.Dialogues[name].Effects = base
						applied("%s: efectos del guion sumados a la conversación «%s»: %s", label, name, table.concat(loose, " · "))
					end
				end
				applied("%s → %s: conversación «%s» con %d frases nuevas%s", label, gameLabel, name, lineCount(blocks), if #music > 0 then " (música " .. table.concat(music, "→") .. ")" else "")
			end
		else
			-- Decisión en el mundo (Choice) con una conversación por opción: los bloques «OPCIÓN A — …» del
			-- guion son, en orden, las conversaciones de cada opción
			if gs.Type == "Choice" and gs.Options then
				local ramas = {}
				for _, s in scripts do
					for _, item in s.Items do
						if item.K == "Block" and item.Kind == "Rama" then
							table.insert(ramas, { Step = s, Block = item })
						end
					end
				end
				for k, rama in ramas do
					local option = gs.Options[k]
					if option and option.Dialogue then
						local pseudo = { Num = rama.Step.Num, Type = "Talk", Items = rama.Block.Items, Cast = {}, Music = {}, Objectives = {}, Cond = nil }
						local rblocks = linesOf(pseudo, keys)
						local old = quest.Dialogues and quest.Dialogues[option.Dialogue]
						local lines = dialogueLines(rblocks, keys, old and (old.Lines or old), label .. " · " .. rama.Block.Head)
						if #lines > 0 then
							guion.Dialogues[option.Dialogue] = { Lines = lines }
							applied("%s → %s: «%s» es la conversación de la opción %s («%s», %d frases)", label, gameLabel, rama.Block.Head, tostring(option.Id), option.Dialogue, #lines)
						end
					elseif option then
						adapted("%s: «%s» — la opción %s del juego no tiene conversación propia: sus frases no se aplican", label, rama.Block.Head, tostring(option.Id))
					else
						adapted("%s: «%s» — el juego tiene %d opciones: esta sobra", label, rama.Block.Head, #gs.Options)
					end
				end
			end
			-- Paso jugable: la mecánica no se toca. Las frases de antes de la acción suenan al entrar (en una
			-- escena ligera que lanza el paso anterior al cumplirse) y las de después, al cumplirlo.
			-- Coger/usar un objeto que tiene su conversación: TODO lo del PASO (frases y elecciones, con los
			-- efectos que ya daba el juego: la ropa, el cromo…) va en esa conversación, que sale al usarlo
			local useProp = gs.Type == "Use" and quest.Props and quest.Props[gs.Prop]
			if useProp and useProp.Dialogue and hasLines then
				local old = quest.Dialogues and quest.Dialogues[useProp.Dialogue]
				local lines = dialogueLines(blocks, keys, old and (old.Lines or old), label)
				if #lines > 0 then
					guion.Dialogues[useProp.Dialogue] = { Lines = lines }
					applied("%s → %s: lo que pasa al usarlo va en la conversación del objeto «%s» (%d frases)", label, gameLabel, useProp.Dialogue, lineCount(blocks))
				end
				local planos = {}
				for _, b in blocks do
					if b.K == "Plano" then
						table.insert(planos, b)
					end
				end
				blocks = planos
			end
			local before, after = {}, {}
			local done = false
			for _, b in blocks do
				if b.K == "Plano" and isDonePlano(b.Plano) then
					done = true
				end
				if b.K == "Choice" and gs.Type == "Choice" then
					adapted("%s: la ELECCION del guion se toma en el mundo (paso Choice «%s»): se conservan las opciones del juego y sus efectos", label, tostring(gs.Key))
				elseif b.K == "Choice" then
					adapted("%s: ELECCION en un paso jugable del juego (%s): no hay conversación donde preguntarla; sus respuestas se dicen como frases", label, gs.Type)
					for _, o in b.Options do
						for _, l in o.Then do
							table.insert(if done then after else before, l)
						end
						break
					end
				else
					table.insert(if done then after else before, b)
				end
			end
			-- ¿Qué paso lanza las frases del principio? El de antes al cumplirse (en un Group, el que va
			-- antes del Group; sus hijos se hacen en cualquier orden y no tienen «antes»)
			local prevPath: string? = nil
			do
				local parentIdx, childIdx = target:match("^(%d+)%.(%d+)$")
				if not parentIdx then
					prevPath = if topIndex(target) > 1 then tostring(topIndex(target) - 1) else nil
				end
				local _ = childIdx
				local prev = prevPath and stepAt(steps, prevPath)
				local prevPatch = prevPath and stepPatches[prevPath]
				local ours = prevPath and slotScenes[prevPath]
				if not prev or (prev.Effects and prev.Effects.Scene) or (prevPatch and prevPatch.Effects and prevPatch.Effects.Scene and not (ours and ours.Light)) then
					prevPath = nil
				end
			end
			-- Hablar con alguien sin conversación propia (los pasos Talk de la familia): sus frases son una
			-- escena al terminar de hablar (con cámara, salvo que justo después venga una cinemática)
			local talkScene = gs.Type == "Talk" and not gs.Dialogue
			local talkLines = false
			for _, s in scripts do
				talkLines = talkLines or categoryOfScript(s.Type) == "talk"
			end
			local merge = (cat == "text" and gs.Type == "Transition") or (talkScene and talkLines) or (prevPath == nil and #before > 0)
			if merge then
				if prevPath == nil and #before > 0 and not talkScene and gs.Type ~= "Transition" then
					local n = 0
					for _, b in before do
						n += if b.K == "Line" then 1 else 0
					end
					if n > 0 then
						adapted("%s: no hay paso de antes que pueda lanzar las %d frases del principio (es el primero, o un objetivo de un Group, o el de antes ya lanza escena): suenan al cumplir el paso %s", label, n, target)
					end
				end
				for k = #before, 1, -1 do
					table.insert(after, 1, before[k])
				end
				before = {}
			end
			if #objectives > 0 then
				local text = objectives[1]
				if #objectives > 1 and gs.Type ~= "Group" then
					text = table.concat(objectives, " · ")
				end
				local set = patch(target).Set or {}
				if gs.Type == "Group" and #objectives > 1 then
					set.Text = objectives[1]
				else
					set.Text = text
				end
				patch(target).Set = set
				applied("%s → %s: objetivo «%s»", label, gameLabel, set.Text)
			end
			local function countLines(list: { Item }): number
				local n = 0
				for _, b in list do
					n += if b.K == "Line" then 1 else 0
				end
				return n
			end
			-- Al cumplirlo: si es un objeto con su conversación, en ella; si no, una escena ligera
			if countLines(after) > 0 then
				local prop = gs.Type == "Use" and quest.Props and quest.Props[gs.Prop]
				if prop and prop.Dialogue then
					local lines = dialogueLines(after, keys, nil, label)
					guion.Dialogues[prop.Dialogue] = { Lines = lines }
					applied("%s → %s: lo que pasa al cogerlo va en la conversación del objeto «%s» (%d frases)", label, gameLabel, prop.Dialogue, countLines(after))
				else
					local id = newSceneId(table.concat(nums, "_"):gsub("%.", "_") .. "_Fin")
					local nextStep = not target:find("%.") and steps[topIndex(target) + 1]
					local camera = talkScene and not (nextStep and categoryOfGame(nextStep) == "cine")
					local scene = sceneFrom(after, { Light = not camera, Sitio = "Sitio", CastKeys = keys, Music = if #before == 0 then music else nil, Where = label })
					if scene and camera then
						scene.Anchors.Sitio = if site ~= "Player" then "Place:" .. site else "Player"
						applied("%s → %s: hablar con %s no tiene conversación propia en el juego: sus frases son una escena con cámara al terminar de hablar (%d planos)", label, gameLabel, tostring(gs.Npc), #(scene.Tracks.Camera or {}))
					end
					if scene then
						if (gs.Effects and gs.Effects.Scene) then
							adapted("%s: el paso ya lanza la escena «%s» al cumplirse: las frases de después no se añaden", label, gs.Effects.Scene)
						else
							guion.Scenes[id] = scene
							patch(target).Effects = { Scene = id }
							slotScenes[target] = { Id = id, Blocks = after, Music = if #before == 0 then music else {}, Light = not camera, Keys = keys }
							applied("%s → %s: %d frases al cumplirlo (escena %s «%s», sin quitar el control)", label, gameLabel, countLines(after), if camera then "con cámara" else "ligera", id)
						end
					end
				end
			end
			if countLines(before) > 0 or (#music > 0 and countLines(after) == 0) then
				enterScenes[target] = "pending"
				local id = newSceneId(table.concat(nums, "_"):gsub("%.", "_") .. "_Entra")
				local scene = sceneFrom(before, { Light = true, Sitio = "Sitio", CastKeys = keys, Music = music, MinDuration = 10, Where = label })
				if scene then
					local ours = prevPath and slotScenes[prevPath]
					if ours then
						-- (el paso de antes ya lanza sus frases del final: estas van detrás, en la misma escena)
						local joined = table.clone(ours.Blocks)
						for _, b in before do
							table.insert(joined, b)
						end
						local joinedMusic = table.clone(ours.Music)
						for _, mu in music do
							table.insert(joinedMusic, mu)
						end
						local keysJoined = table.clone(ours.Keys)
						for k in keys do
							keysJoined[k] = true
						end
						local again = sceneFrom(joined, { Light = true, Sitio = "Sitio", CastKeys = keysJoined, Music = joinedMusic, MinDuration = 10, Where = label })
						guion.Scenes[ours.Id] = again
						ours.Blocks, ours.Music, ours.Keys = joined, joinedMusic, keysJoined
						applied("%s → %s: %d frases al empezar el paso (van detrás de las del final del paso %s, en su escena «%s»)", label, gameLabel, countLines(before), prevPath, ours.Id)
					elseif prevPath then
						guion.Scenes[id] = scene
						patch(prevPath).Effects = { Scene = id }
						slotScenes[prevPath] = { Id = id, Blocks = before, Music = music, Light = true, Keys = keys }
						applied("%s → %s: %d frases al empezar el paso (escena ligera «%s», la lanza el paso %s al cumplirse; el jugador no pierde el control)", label, gameLabel, countLines(before), id, prevPath)
					elseif not (gs.Effects and gs.Effects.Scene) and not (stepPatches[target] and stepPatches[target].Effects) then
						guion.Scenes[id] = scene
						patch(target).Effects = { Scene = id }
						adapted("%s: no hay paso de antes libre para lanzar las frases del principio: suenan al cumplir el paso %s", label, target)
					else
						adapted("%s: las %d frases del principio no tienen dónde sonar (los pasos de antes y este ya lanzan escena): no se aplican", label, countLines(before))
					end
				end
			end
			if not hasLines and #objectives == 0 then
				adapted("%s → %s: solo trae planos (sin frases): en un paso jugable no se quita el control, así que no se aplican", label, gameLabel)
			end
		end
		-- PLANO de pasos jugables (no se graban como cámara)
		if cat == "play" or cat == "text" then
			local n = 0
			for _, b in blocks do
				n += if b.K == "Plano" then 1 else 0
			end
			if n > 0 then
				adapted("%s: %d PLANO de un paso jugable (%s) no se convierten en cámara para no quitar el control; se usan para colocar las frases (antes/después de la acción) y los destellos de la Grieta", label, n, gs.Type)
			end
		end
	end

	-- Momento de la biografía (bloque «MOMENTO DE BIOGRAFÍA» / «Al terminar:», suelto o dentro de un PASO)
	local momentBlocks = {}
	for _, b in doc.Blocks do
		if b.K == "Block" then
			table.insert(momentBlocks, b)
		end
	end
	local lastTop = nil
	for _, s in doc.Steps do
		if not s.Sub then
			lastTop = s.Num:match("^(%d+)")
		end
	end
	for _, s in doc.Steps do
		for _, it in s.Items do
			if it.K == "Block" and it.Kind == "Momento" then
				-- («Al terminar:» en mitad de la misión es lo que pasa al acabar ese PASO, no el momento de la
				-- biografía: ese va al final)
				local midway = norm(it.Head or ""):find("^al terminar") ~= nil and s.Num:match("^(%d+)") ~= lastTop
				if not midway then
					table.insert(momentBlocks, it)
				end
			end
		end
	end
	local momentDone = false
	for _, b in momentBlocks do
		if b.Kind == "Momento" then
			local texts = {}
			for _, it in b.Items do
				-- («Ins03 = COMPLETADA», «Registrar: …»: notas, no la frase de la biografía)
				if it.T and it.T ~= "" and not norm(it.T):find("^descripcion") and not it.T:find("=", 1, true) and not it.T:match(":%s*$") then
					local t = it.T:gsub("^[Dd]escripci[^:]*:%s*", ""):gsub("^[Bb]iograf[^:]*:%s*", ""):gsub("^[Mm]omento[^:]*:%s*", "")
					-- («🏆 «Tu primer torneo»»: lo de dentro de las comillas)
					local inner = t:match("«(.-)»%s*$")
					if inner and not t:match("^«") and len(t) - len(inner) <= 8 then
						t = inner
					end
					table.insert(texts, unquote(trim(t)))
				end
			end
			local current = quest.MomentKey or quest.Moment
			if #texts > 0 and (current == texts[1] or (game.Strings and game.Strings[current or ""] == texts[1])) then
				momentDone = true -- (la misma frase que ya tenía)
			end
			if #texts > 0 and not momentDone then
				momentDone = true
				local key = quest.MomentKey or quest.Moment
				if type(key) == "string" and game.Strings and game.Strings[key] then
					-- (misma clave: las pruebas y la biografía guardada siguen valiendo; cambia la frase)
					guion.Strings = guion.Strings or {}
					guion.Strings[key] = texts[1]
					applied("Momento de la biografía: «%s» (texto nuevo de %s; antes «%s»)", texts[1], key, game.Strings[key])
				else
					guion.Mission = guion.Mission or { Set = {} }
					guion.Mission.Set.MomentKey = texts[1]
					applied("Momento de la biografía: «%s»", texts[1])
				end
				if #texts > 1 then
					table.insert(R.Notes, ("Descripción del momento (sin sitio en la biografía, que guarda una frase): «%s»"):format(table.concat(texts, " ", 2)))
				end
			end
		else
			local texts = {}
			for _, it in b.Items do
				table.insert(texts, if it.K == "Line" then (it.S .. ": " .. (it.T or "")) else (it.T or ""))
			end
			table.insert(R.Notes, ("%s: %s"):format(b.Head, table.concat(texts, " / ")))
		end
	end

	-- ConservarFrases = { "Rec_Taquilla" }: en esas conversaciones se quedan delante las frases del juego que
	-- dependen de lo vivido (las que tienen If), que el guion resume como «montaje según las marcas»
	for _, name in m.ConservarFrases or {} do
		local old = quest.Dialogues and quest.Dialogues[name]
		local new = guion.Dialogues[name]
		if old and new and new.Lines then
			local kept = {}
			for _, l in old.Lines or old do
				if type(l) == "table" and l.If and l.T and not l.Ask then
					local dup = false
					for _, n in new.Lines do
						dup = dup or (type(n) == "table" and n.T == l.T)
					end
					if not dup then
						table.insert(kept, table.clone(l))
					end
				end
			end
			for i, l in kept do
				table.insert(new.Lines, i, l)
			end
			applied("Conversación «%s»: se conservan delante %d frases del juego que dependen de lo vivido", name, #kept)
		elseif not old then
			errorf("ConservarFrases: la conversación «%s» no existe en el juego", name)
		end
	end

	-- Validación de las escenas generadas con el validador del motor
	if game.SequencerCtx then
		for id, scene in guion.Scenes do
			for _, message in Seq.validate(id, Reescritura.materialize(scene, game.Vector3), game.SequencerCtx) do
				errorf("escena %s: %s", id, message)
			end
		end
	end
	if not next(guion.Dialogues) then
		guion.Dialogues = nil
	end
	return guion, R
end

-- Cambia los { __v3 = {x, y, z} } por Vector3 de verdad (para validar)
function Reescritura.materialize(value: any, vector3: any): any
	if type(value) ~= "table" then
		return value
	end
	if value.__v3 then
		return vector3.new(value.__v3[1], value.__v3[2], value.__v3[3])
	end
	local out = {}
	for k, v in value do
		out[k] = Reescritura.materialize(v, vector3)
	end
	return out
end

---------------------------------------------------------------------
-- 3. Escribir el módulo
---------------------------------------------------------------------
local function isIdent(s: any): boolean
	return type(s) == "string" and s:match("^[%a_][%w_]*$") ~= nil and not ({ ["and"] = 1, ["or"] = 1, ["not"] = 1, ["end"] = 1, ["if"] = 1, ["then"] = 1, ["for"] = 1, ["in"] = 1, ["do"] = 1, ["true"] = 1, ["false"] = 1, ["nil"] = 1, ["local"] = 1, ["function"] = 1, ["return"] = 1, ["while"] = 1, ["repeat"] = 1, ["until"] = 1, ["else"] = 1, ["elseif"] = 1, ["break"] = 1 })[s]
end
local function quote(s: string): string
	return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
end
local function num(n: number): string
	if n == math.floor(n) then
		return tostring(math.floor(n))
	end
	return (("%.2f"):format(n):gsub("0+$", ""))
end
-- Orden de los campos (lo que más se lee, primero)
local FIELD_ORDER = { "Id", "Source", "At", "Light", "Skippable", "Duration", "FadeIn", "FadeOut", "AfterScene", "Anchors", "Tracks", "S", "T", "Text", "Sub", "TextKey", "SubKey", "Ask", "Options", "To", "Shot", "A", "G", "Mood", "Pause", "If", "Effects", "Then", "Set", "Lines" }
local RANK = {}
for i, k in FIELD_ORDER do
	RANK[k] = i
end
local function sortedKeys(t: { [any]: any }): { any }
	local keys = {}
	for k in t do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		local ra, rb = RANK[a] or 999, RANK[b] or 999
		if ra ~= rb then
			return ra < rb
		end
		return tostring(a) < tostring(b)
	end)
	return keys
end
local function isArray(t: { [any]: any }): boolean
	local n = 0
	for _ in t do
		n += 1
	end
	return n == #t
end
local function write(value: any, indent: string, out: { string })
	local kind = type(value)
	if kind == "string" then
		table.insert(out, quote(value))
	elseif kind == "number" then
		table.insert(out, num(value))
	elseif kind == "boolean" then
		table.insert(out, tostring(value))
	elseif kind == "table" then
		if value.__v3 then
			table.insert(out, ("V(%s, %s, %s)"):format(num(value.__v3[1]), num(value.__v3[2]), num(value.__v3[3])))
			return
		end
		if next(value) == nil then
			table.insert(out, "{}")
			return
		end
		-- Una línea si es corta (sin tablas grandes dentro)
		local flat = {}
		local simple = true
		local array = isArray(value)
		for _, k in (if array then nil else sortedKeys(value)) or {} do
			local v = value[k]
			if type(v) == "table" and not v.__v3 then
				local inner = {}
				write(v, "", inner)
				local s = table.concat(inner)
				if s:find("\n") then
					simple = false
					break
				end
				table.insert(flat, (if isIdent(k) then k else "[" .. (if type(k) == "string" then quote(k) else tostring(k)) .. "]") .. " = " .. s)
			else
				local inner = {}
				write(v, "", inner)
				table.insert(flat, (if isIdent(k) then k else "[" .. (if type(k) == "string" then quote(k) else tostring(k)) .. "]") .. " = " .. table.concat(inner))
			end
		end
		if array then
			for _, v in value do
				local inner = {}
				write(v, "", inner)
				local s = table.concat(inner)
				if s:find("\n") then
					simple = false
					break
				end
				table.insert(flat, s)
			end
		end
		local oneLine = "{ " .. table.concat(flat, ", ") .. " }"
		if simple and #oneLine + #indent <= 150 then
			table.insert(out, oneLine)
			return
		end
		local inner = indent .. "\t"
		table.insert(out, "{\n")
		if array then
			for _, v in value do
				table.insert(out, inner)
				write(v, inner, out)
				table.insert(out, ",\n")
			end
		else
			for _, k in sortedKeys(value) do
				table.insert(out, inner)
				table.insert(out, (if isIdent(k) then k else "[" .. (if type(k) == "string" then quote(k) else tostring(k)) .. "]") .. " = ")
				write(value[k], inner, out)
				table.insert(out, ",\n")
			end
		end
		table.insert(out, indent .. "}")
	elseif typeof(value) == "Vector3" then
		-- (lo heredado de una escena de antes: sus desplazamientos ya son Vector3)
		table.insert(out, ("V(%s, %s, %s)"):format(num(value.X), num(value.Y), num(value.Z)))
	else
		error("no se puede escribir un valor " .. kind)
	end
end

function Reescritura.serialize(guion: { [string]: any }, header: string): string
	local out = { header, "\nlocal V = Vector3.new\nlocal _ = V\n\nreturn " }
	write(guion, "", out)
	table.insert(out, "\n")
	return table.concat(out)
end

return Reescritura
