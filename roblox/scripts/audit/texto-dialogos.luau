-- Revisión del TEXTO de los diálogos de la historia (ortografía y forma, no el contenido).
-- No arranca el juego: lee las misiones ya con sus guiones aplicados (Quests + GuionOverlay) y las escenas
-- del motor (escenas de los guiones y Happenings), y avisa de:
--   * ¿? y ¡! sin su pareja, y «», (), {} sin cerrar
--   * huecos {…} que el juego no rellena (los válidos: {o/a}, {nombre}, {Saludo}, {count}, {total}…)
--   * espacios dobles, espacio antes de , . ; : ? ! …
--   * la misma palabra dos veces seguidas («de de»)
--   * frases que empiezan en minúscula (suele ser un trozo de otra frase mal unido)
--   * frases sin signo al final
-- Uso (desde roblox/): lune run scripts/audit/texto-dialogos.luau [todo]
--   sin «todo»: el resumen y hasta 12 ejemplos por tipo; con «todo», todos.

local process = require("@lune/process")
local H = require("../lib/StoryHarness")
local GuionOverlay = H.loadModule(H.ROOT .. "/shared/LifeStory/GuionOverlay")
local HappeningIndex = H.loadModule(H.ROOT .. "/shared/LifeStory/HappeningIndex")
local Strings = H.loadModule(H.ROOT .. "/shared/LifeStory/Strings")
local ALL = process.args[1] == "todo"

-- Huecos que el juego rellena (shared/LifeStory/Strings y DialogueService)
local TOKENS = { grupo = true, familia = true, abu = true, genero = true, nombre = true, Nombre = true, Saludo = true, saludo = true, count = true, total = true, name = true, edad = true, curso = true, dinero = true, pareja = true, hijo = true, ciudad = true, trabajo = true, mascota = true }
local REPEAT_OK = { ja = true, je = true, ji = true, jo = true, no = true, ["sí"] = true, si = true, muy = true, bla = true, toc = true, tic = true, pip = true, ay = true, eh = true, oh = true, ah = true, uy = true, hm = true, mm = true, venga = true, vale = true, ya = true, corre = true, vamos = true, uno = true, dos = true, tres = true, ["rápido"] = true, ["más"] = true, nunca = true, bien = true }

local problems: { [string]: { string } } = {}
local order = { "¿?", "¡!", "«»", "()", "{}", "hueco", "espacios", "repetida", "minúscula", "sin punto" }
local function add(kind: string, where: string, text: string)
	problems[kind] = problems[kind] or {}
	table.insert(problems[kind], ("%s · «%s»"):format(where, text))
end

local function count(s: string, pattern: string): number
	local _, n = s:gsub(pattern, "")
	return n
end

local seen: { [string]: boolean } = {}
local total = 0
local function check(where: string, text: any, isOption: boolean?)
	if type(text) ~= "string" or text == "" then
		return
	end
	local key = where .. "\0" .. text
	if seen[key] then
		return
	end
	seen[key] = true
	total += 1
	-- (una clave de Strings, «DLG.NICO.RECREO»: se revisa su texto)
	if text:match("^[%u%d_%.]+$") and text:find(".", 1, true) then
		local ok, resolved = pcall(Strings.get, text)
		if ok and type(resolved) == "string" and resolved ~= text then
			text = resolved
		end
	end
	-- (por frases: «¿Qué? Vale.» tiene que llevar su ¿ en la primera)
	if count(text, "¿") ~= count(text, "%?") then
		add("¿?", where, text)
	end
	if count(text, "¡") ~= count(text, "!") then
		add("¡!", where, text)
	end
	if count(text, "«") ~= count(text, "»") then
		add("«»", where, text)
	end
	if count(text, "%(") ~= count(text, "%)") then
		add("()", where, text)
	end
	if count(text, "{") ~= count(text, "}") then
		add("{}", where, text)
	end
	for inner in text:gmatch("{(.-)}") do
		if not inner:find("/", 1, true) and not TOKENS[inner] then
			add("hueco", where, text)
			break
		end
	end
	if text:find("  ", 1, true) or text:find(" [,%.;:%?!]") or text:match("^%s") or text:match("%s$") then
		add("espacios", where, text)
	end
	local prev = nil
	for word in text:lower():gmatch("[%wáéíóúüñ]+") do
		if word == prev and not REPEAT_OK[word] and #word > 1 then
			add("repetida", where, text)
			break
		end
		prev = word
	end
	-- (empieza en minúscula: un trozo de otra frase. No cuentan «(acotación)», «…sigue» ni las mayúsculas con tilde)
	local first = text:gsub("^[%s¿¡«\"']+", "")
	local lowerAccent = first:sub(1, 2) == "á" or first:sub(1, 2) == "é" or first:sub(1, 2) == "í" or first:sub(1, 2) == "ó" or first:sub(1, 2) == "ú" or first:sub(1, 2) == "ñ"
	if first:match("^[a-z]") or lowerAccent then
		add("minúscula", where, text)
	end
	if not isOption and not text:match("[%.!%?…»\"%)]%s*$") and not text:match("[%.!%?…]»%s*$") then
		add("sin punto", where, text)
	end
end

local function walkLines(where: string, lines: any)
	for i, line in (type(lines) == "table" and lines) or {} do
		if type(line) == "table" then
			check(("%s[%d] %s"):format(where, i, tostring(line.S or "")), line.T)
			if line.Ask then
				check(("%s[%d] pregunta"):format(where, i), line.Ask)
			end
			for j, option in line.Options or {} do
				check(("%s[%d] opción %d"):format(where, i, j), option.T, true)
				walkLines(("%s[%d].%d"):format(where, i, j), option.Then)
			end
		end
	end
end

for id, quest in H.Quests do
	for name, dialogue in quest.Dialogues or {} do
		walkLines(id .. "/" .. name, dialogue.Lines)
	end
end
local function walkScene(id: string, scene: any)
	for i, d in (scene and scene.Tracks and scene.Tracks.Dialogue) or {} do
		check(("escena %s[%d] %s"):format(id, i, tostring(d.S or "")), d.T)
	end
	for _, variant in (scene and scene.Variants) or {} do
		for i, d in (variant.Tracks and variant.Tracks.Dialogue) or {} do
			check(("escena %s (variante)[%d] %s"):format(id, i, tostring(d.S or "")), d.T)
		end
	end
end
for id, scene in GuionOverlay.scenes() do
	walkScene(id, scene)
end
if HappeningIndex.all then
	for id, scene in HappeningIndex.all() do
		walkScene(id, scene)
	end
end

print(("Frases revisadas: %d"):format(total))
local found = 0
for _, kind in order do
	local list = problems[kind] or {}
	table.sort(list)
	found += #list
	print(("\n## %s: %d"):format(kind, #list))
	for i, p in list do
		if not ALL and i > 12 then
			print(("  … y %d más"):format(#list - 12))
			break
		end
		print("  " .. p)
	end
end
print(("\nTotal: %d avisos"):format(found))
