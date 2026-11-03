-- Prueba de los TEXTOS que ve el jugador (ortografía, nombres, largo para el móvil, marcas, 13+).
--
-- Uso (desde roblox/): lune run scripts/test-textos.luau          (falla si algo no cumple)
--                      lune run scripts/test-textos.luau informe  (lo lista todo y no falla)
--
-- Lee los datos reales: misiones (Quests, con los guiones reescritos encima), escenas (HappeningIndex),
-- textos por clave (Strings), tiendas (ShopItems) y capítulos (Chapters). Además mira las frases
-- («cadenas con espacios») de todo src/ para lo prohibido (Nova, NV-7, marcas reales, palabrotas).
--
-- Reglas (informe en docs/historia/auditoria-textos-misiones.md):
--   1. Objetivo de un paso: dice QUÉ y DÓNDE en ≤ Limits.Objective letras (la tarjeta del móvil).
--      Una decisión (paso Choice) es una pregunta con su contexto: ≤ Limits.Question letras.
--   2. Frase de diálogo o de escena: ≤ Limits.Line letras (el bocadillo del móvil: 230 px a 17 pt).
--   3. Rótulo de transición («Junio. El calor…»): ≤ Limits.Card letras.
--   4. Sin «Nova», «NovaLife» ni «NV-7» (la nave es la HX-7 Halcón), sin marcas reales y sin palabrotas.
--   5. Ortografía: palabras que siempre llevan tilde o eñe, «¿» y «¡» de apertura, sin espacios dobles.
--   6. Nombres: un personaje se escribe siempre igual (Cósimo, no Cosimo).

local fs = require("@lune/fs")
local process = require("@lune/process")
local L = require("./lib/ModuleLoader")

local REPORT = process.args[1] == "informe"
local Limits = { Objective = 64, Question = 120, Line = 160, Card = 140 }

local Quests = L.load("src/shared/LifeStory/Quests")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Strings = L.load("src/shared/LifeStory/Strings")
local ShopItems = L.load("src/shared/LifeStory/ShopItems")
local Chapters = L.load("src/shared/LifeStory/Chapters")
local Cast = L.load("src/shared/LifeStory/Cast")

local failures: { [string]: { string } } = {}
local function fail(rule: string, where: string, text: string)
	failures[rule] = failures[rule] or {}
	table.insert(failures[rule], ("%s: %s"):format(where, text))
end

local function resolve(s: string): string
	if s:match("^[%u%d_]+%.[%u%d_%.]+$") and Strings.has(s) then
		return Strings.get(s)
	end
	return s
end

-- Cómo se ve en pantalla: {o/a} con la forma más larga, {count}/{total} con un número, {x} con un nombre
local function shown(s: string): string
	s = s:gsub("{([^}/]*)/([^}]*)}", function(a, b)
		return if #a >= #b then a else b
	end)
	s = s:gsub("{count}", "9"):gsub("{total}", "9"):gsub("{[%w_]+}", "Nombre")
	return s
end
local function len(s: string): number
	return utf8.len(s) or #s
end

---------------------------------------------------------------------
-- 1. Recoger los textos (con su tipo: objetivo, frase, rótulo o interfaz)
---------------------------------------------------------------------
type Entry = { Where: string, Text: string, Kind: string }
local entries: { Entry } = {}
local function add(where: string, text: any, kind: string)
	if type(text) == "string" and text ~= "" then
		table.insert(entries, { Where = where, Text = resolve(text), Kind = kind })
	end
end

local TEXT_KEYS = {
	Title = true, TitleKey = true, Description = true, OfferKey = true, Prompt = true, Moment = true, MomentKey = true,
	Hint = true, CaughtLine = true, Bark = true, Ask = true, Bye = true, Sub = true, Label = true, Toast = true,
	Message = true, Header = true, Footer = true, Subtitle = true, Name = true,
}
local SILENT_STEPS = { Cinematic = true, Scene = true, Moment = true } -- (Moment: la tarjeta del recuerdo)
local seen: { [any]: boolean } = {}
local function walk(node: any, where: string, parentKey: string?)
	if type(node) ~= "table" or seen[node] then
		return
	end
	seen[node] = true
	local isLine = node.S ~= nil or node.Speaker ~= nil
	local isStep = type(node.Type) == "string" and parentKey == "Steps"
	for k, v in node do
		if type(v) == "string" then
			if (k == "T" or k == "Text") and isLine then
				add(where, v, "Line")
			elseif (k == "Text" or k == "TextKey") and isStep then
				add(where, v, if node.Type == "Transition" then "Card" elseif node.Type == "Choice" then "Question" elseif SILENT_STEPS[node.Type] then "Ui" else "Objective")
			elseif k == "Text" or k == "T" or TEXT_KEYS[k] then
				if not (k == "Name" and not v:find(" ") and not v:find("[\128-\255]")) then -- (Name = id interno)
					add(where, v, "Ui")
				end
			end
		elseif type(v) == "table" then
			local child = if type(k) == "number" then where .. "#" .. k else where .. "." .. tostring(k)
			walk(v, child, if type(k) == "number" then parentKey else tostring(k))
		end
	end
end

for id, quest in Quests do
	walk(quest, tostring(id))
end
for id, def in HappeningIndex.all() do
	walk(def, "escena " .. id)
end
for key, value in Strings.es do
	add("Strings " .. key, value, "Ui")
end
walk(ShopItems, "ShopItems")
walk(Chapters, "Chapters")

---------------------------------------------------------------------
-- 2. Las frases sueltas de todo src/ (para lo prohibido)
---------------------------------------------------------------------
local function literals(src: string): { { line: number, s: string } }
	local out = {}
	local i, n, line = 1, #src, 1
	while i <= n do
		local c = src:sub(i, i)
		if c == "\n" then
			line += 1
			i += 1
		elseif c == "-" and src:sub(i, i + 1) == "--" then
			local long = src:match("^%-%-%[(=*)%[", i)
			local e
			if long then
				e = (src:find("]" .. long .. "]", i, true) or n) + #long + 2
			else
				e = src:find("\n", i, true) or n + 1
			end
			for _ in src:sub(i, e - 1):gmatch("\n") do
				line += 1
			end
			i = e
		elseif c == '"' or c == "'" or c == "`" then
			local j, buf = i + 1, {}
			while j <= n do
				local d = src:sub(j, j)
				if d == "\\" then
					table.insert(buf, src:sub(j, j + 1))
					j += 2
				elseif d == c or d == "\n" then
					break
				else
					table.insert(buf, d)
					j += 1
				end
			end
			table.insert(out, { line = line, s = table.concat(buf) })
			i = j + 1
		elseif c == "[" and src:match("^%[=*%[", i) then
			local eq = src:match("^%[(=*)%[", i)
			local s0 = i + #eq + 2
			local e = src:find("]" .. eq .. "]", s0, true) or n
			local body = src:sub(s0, e - 1)
			table.insert(out, { line = line, s = body })
			for _ in body:gmatch("\n") do
				line += 1
			end
			i = e + #eq + 2
		else
			i += 1
		end
	end
	return out
end
local sourceTexts: { Entry } = {}
local function walkDir(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			walkDir(path)
		elseif name:match("%.luau$") then
			for _, lit in literals(fs.readFile(path)) do
				if lit.s:find(" ") then
					table.insert(sourceTexts, { Where = path:sub(5) .. ":" .. lit.line, Text = lit.s, Kind = "Source" })
				end
			end
		end
	end
end
walkDir("src")

---------------------------------------------------------------------
-- 3. Las reglas
---------------------------------------------------------------------
-- Palabras sueltas (en minúsculas; las letras con tilde cuentan como letra)
local function words(s: string): { string }
	local out = {}
	for w in s:gmatch("[%a\128-\255]+") do
		table.insert(out, w)
	end
	return out
end

-- 4. Prohibido (en cualquier texto del juego, también en las frases sueltas del código)
local BANNED = { "Nova", "NovaLife", "NovaDreams", "NV" } -- (NV-7: la nave es la HX-7 Halcón)
local BRANDS = {
	"McDonald", "Burger King", "Coca%-Cola", "Pepsi", "Starbucks", "Nike", "Adidas", "Puma", "iPhone", "Samsung",
	"Fortnite", "Minecraft", "PlayStation", "Xbox", "Nintendo", "Netflix", "YouTube", "TikTok", "Instagram",
	"WhatsApp", "Facebook", "Google", "Amazon", "Ferrari", "Lamborghini", "Porsche", "Mercedes%-Benz", "BMW", "Audi",
	"Disney", "Pokémon", "Pokemon", "Marvel", "Spotify", "Lego", "LEGO", "Red Bull", "Fanta", "Zara", "Ikea", "IKEA",
}
local PROFANITY = { "mierda", "joder", "puta", "puto", "coño", "gilipollas", "cabrón", "cabron", "hostia", "follar", "polla", "zorra", "maricón" }
local profanity = {}
for _, w in PROFANITY do
	profanity[w] = true
end
local function wordIn(s: string, w: string): boolean
	-- palabra entera: ni letra ni letra con tilde a los lados
	local from = 1
	while true do
		local a, b = s:find(w, from)
		if not a then
			return false
		end
		local before = if a > 1 then s:sub(a - 1, a - 1) else " "
		local after = s:sub(b + 1, b + 1)
		if not before:match("[%w\128-\255]") and not (after:match("[%a\128-\255]")) then
			return true
		end
		from = b + 1
	end
end
local function forbidden(e: Entry)
	for _, w in BANNED do
		if wordIn(e.Text, w) and not (w == "NV" and not e.Text:find("NV%-?%d")) then
			fail("Nova / NV-7", e.Where, e.Text)
		end
	end
	for _, w in BRANDS do
		if wordIn(e.Text, w) then
			fail("Marca real", e.Where, e.Text)
		end
	end
	for _, w in words(e.Text:lower()) do
		if profanity[w] then
			fail("Palabrota (13+)", e.Where, e.Text)
		end
	end
end

-- 5. Palabras que nunca se escriben así (siempre llevan tilde o eñe)
local MISSPELT = {}
for wrong, right in {
	aqui = "aquí", alli = "allí", ahi = "ahí", tambien = "también", despues = "después", facil = "fácil",
	dificil = "difícil", musica = "música", telefono = "teléfono", rapido = "rápido", rapida = "rápida",
	pagina = "página", camara = "cámara", energia = "energía", mision = "misión", cancion = "canción",
	informacion = "información", corazon = "corazón", jardin = "jardín", ninos = "niños", -- («Nina» es un nombre y «¡nino, nino!», la sirena)
	nina_ = "",
	manana = "mañana", companero = "compañero", companera = "compañera", espanol = "español", sabado = "sábado",
	miercoles = "miércoles", jovenes = "jóvenes", examenes = "exámenes", arbol = "árbol", arboles = "árboles",
	lapiz = "lápiz", autobus = "autobús", policia = "policía", dia = "día", dias = "días", todavia = "todavía",
	ademas = "además", quizas = "quizás", asi = "así", atras = "atrás", detras = "detrás", jamas = "jamás",
	adios = "adiós", cafe = "café", sofa = "sofá", ingenieria = "ingeniería", biologia = "biología",
	quimica = "química", fisica = "física", matematicas = "matemáticas", geografia = "geografía",
	tecnologia = "tecnología", heroe = "héroe", heroes = "héroes", periodico = "periódico", mecanico = "mecánico",
	oceano = "océano", unica = "única", unico = "único", publico = "público", magico = "mágico",
	increible = "increíble", tecnico = "técnico", electrico = "eléctrico", comun = "común", algun = "algún",
	ningun = "ningún", segun = "según", razon = "razón", accion = "acción", atencion = "atención",
	direccion = "dirección", estacion = "estación", leccion = "lección", opcion = "opción", situacion = "situación",
	solucion = "solución", conversacion = "conversación", habitacion = "habitación", reunion = "reunión",
	television = "televisión", avion = "avión", camion = "camión", raton = "ratón", boton = "botón",
	salon = "salón", balon = "balón", montana = "montaña", senor = "señor", senora = "señora",
	pequeno = "pequeño", pequena = "pequeña", dueno = "dueño", ensenar = "enseñar", anos = "años",
	tu_ = "", galactico = "galáctico", planetas_ = "", nave_ = "", halcon = "halcón", ultimos = "últimos",
	numeros = "números", minimo = "mínimo", maximo = "máximo", rapidos = "rápidos", facilmente = "fácilmente",
	practica_ = "", examen_ = "", tio = "tío", tia = "tía", via = "vía", rio = "río", frio = "frío",
	garaje_ = "", sotano = "sótano", lampara = "lámpara", pajaro = "pájaro", murcielago = "murciélago",
	medico = "médico", medica = "médica", clinica = "clínica", farmacia_ = "", ultima = "última",
} do
	if right ~= "" then
		MISSPELT[wrong] = right
	end
end
-- Nombres del reparto con tilde: la forma sin tilde es un error («Cosimo» → «Cósimo»)
local function unaccent(s: string): string
	for a, b in { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["Á"] = "A", ["É"] = "E", ["Í"] = "I", ["Ó"] = "O", ["Ú"] = "U" } do
		s = s:gsub(a, b)
	end
	return s
end
local NAMES: { [string]: string } = {}
for _, person in Cast.People do
	local name = if type(person.Name) == "string" then resolve(person.Name) else nil
	for _, w in (if name then words(name) else {}) do
		if w:find("[\128-\255]") and w:match("^%u") and unaccent(w) ~= w and not unaccent(w):find("[\128-\255]") then
			NAMES[unaccent(w)] = w
		end
	end
end
-- Formas sin tilde que también son palabras («Tú»/«tu», «Tomé»/«tome»): no cuentan
for _, ok in { "Tu", "Tome" } do
	NAMES[ok] = nil
end
for _, extra in { "Cósimo", "Halcón", "Tálasa", "Umbría", "Nácara", "Vértice" } do
	NAMES[unaccent(extra)] = extra
end

-- Nombres propios que coinciden con una palabra mal escrita («Nina», la de Siroco)
local NAMES_OK = { Nina = true }

local function spelling(e: Entry)
	local t = e.Text
	for _, w in words(t) do
		local right = if w:match("^%u") and NAMES_OK[w] then nil else MISSPELT[w:lower()]
		if right then
			fail("Ortografía", e.Where, ("«%s» → «%s»: %s"):format(w, right, t))
		end
		if NAMES[w] then
			fail("Nombre mal escrito", e.Where, ("«%s» → «%s»: %s"):format(w, NAMES[w], t))
		end
	end
	if t:find("%S  +%S") then
		fail("Espacios dobles", e.Where, t)
	end
	-- «¿» y «¡» de apertura (en lo que se lee: frases y objetivos)
	if e.Kind ~= "Source" then
		local _, q = t:gsub("%?", "")
		local _, oq = t:gsub("¿", "")
		if q > oq then
			fail("Falta «¿»", e.Where, t)
		end
		local _, x = t:gsub("!", "")
		local _, ox = t:gsub("¡", "")
		if x > ox then
			fail("Falta «¡»", e.Where, t)
		end
	end
end

-- 1b. Forma del objetivo: empieza en mayúscula (o «¡», «¿», ««», un número o un emoji) y sin punto final
local function objectiveShape(e: Entry)
	if e.Kind ~= "Objective" then
		return
	end
	local t = e.Text
	if t:match("^%l") then
		fail("Objetivo en minúscula", e.Where, t)
	end
	if t:match("[^%.]%.$") then
		fail("Objetivo con punto final", e.Where, t)
	end
end

local function length(e: Entry)
	local limit = Limits[e.Kind]
	if limit and len(shown(e.Text)) > limit then
		fail(("Largo (%s > %d)"):format(e.Kind, limit), e.Where, ("[%d] %s"):format(len(shown(e.Text)), e.Text))
	end
end

-- Un mismo texto puede salir muchas veces (días generados, guion y misión): se cuenta una vez
local dedupe: { [string]: boolean } = {}
for _, e in entries do
	local key = e.Kind .. "\0" .. e.Text
	if not dedupe[key] then
		dedupe[key] = true
		forbidden(e)
		spelling(e)
		objectiveShape(e)
		length(e)
	end
end
for _, e in sourceTexts do
	forbidden(e)
end

---------------------------------------------------------------------
-- 4. Resultado
---------------------------------------------------------------------
local rules = {}
for rule in failures do
	table.insert(rules, rule)
end
table.sort(rules)
local total = 0
for _, rule in rules do
	local list = failures[rule]
	table.sort(list)
	total += #list
	print(("\n✗ %s (%d)"):format(rule, #list))
	for i, line in list do
		if REPORT or i <= 15 then
			print("   " .. line)
		end
	end
end
print(("\nTextos revisados: %d (y %d frases del código). Fallos: %d"):format(#entries, #sourceTexts, total))
if total > 0 and not REPORT then
	process.exit(1)
end
print("✓ Textos en orden")
