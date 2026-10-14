-- Aplica un guion reescrito (docs/historia/reescritura/<IdMision>.md) a su misión del juego.
--
-- Uso (desde roblox/):
--   lune run scripts/audit/aplicar-reescritura.luau <IdMision>            valida, genera e informa
--   lune run scripts/audit/aplicar-reescritura.luau <IdMision> --check    solo valida (no escribe nada)
--   lune run scripts/audit/aplicar-reescritura.luau --todas               las que ya están aplicadas o tienen mapa
--   lune run scripts/audit/aplicar-reescritura.luau <IdMision> --pasos    los pasos del juego y los PASO del guion (para el mapa)
--   lune run scripts/audit/aplicar-reescritura.luau --leer <IdMision> <PASO>   cómo se ha leído un PASO
--
-- Qué hace:
--   1. Lee el guion (formato del encargo, tolerante: ver scripts/lib/Reescritura.luau) y, si existe,
--      su mapa docs/historia/reescritura/<IdMision>.mapa.luau (qué PASO va en qué paso del juego…).
--   2. Valida: la misión y los pasos existen, tipos de plano y música válidos, quien habla está en el
--      reparto, frases de más de 140 caracteres, {o/a} bien escrito (y corrige los «Bienvenido»,
--      «Tranquilo»… dirigidos al jugador), y las escenas nuevas con el validador del motor (Sequencer).
--   3. Escribe src/shared/LifeStory/Guiones/<IdMision>.luau (datos generados: cinemáticas con un plano
--      por PLANO, conversaciones con sus planos/gestos/pausas, elecciones con sus efectos, escenas
--      ligeras con las frases de los pasos jugables y la música de cada paso), lo apunta en
--      GuionOverlay.List y deja el informe en docs/historia/reescritura/<IdMision>.informe.md.
--      La mecánica de cada paso (ir a, saltar, coger, abrir…) no se toca: lo jugable sigue igual.
-- Con errores no escribe el guion (sí el informe) y sale con código 1.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local L = require("../lib/ModuleLoader")
local Reescritura = require("../lib/Reescritura")

local SRC = "src/shared/LifeStory"
local DIR = "docs/historia/reescritura"
local OUT = SRC .. "/Guiones"
local OVERLAY = SRC .. "/GuionOverlay.luau"

-- Los datos del juego SIN los guiones ya aplicados (para generar siempre desde la misión de verdad)
L.mock(SRC .. "/GuionOverlay", {
	List = {},
	apply = function() end,
	scenes = function()
		return {}
	end,
	all = function()
		return {}
	end,
})
local Quests = L.load(SRC .. "/Quests")
local Cast = L.load(SRC .. "/Cast")
local Locations = L.load(SRC .. "/Locations")
local Cinematics = L.load(SRC .. "/Cinematics")
local HappeningIndex = L.load(SRC .. "/HappeningIndex")
local Sequencer = L.load(SRC .. "/Sequencer")
local Memories = L.load(SRC .. "/Memories")
local Strings = L.load(SRC .. "/Strings")

-- Rasgos, decisiones y marcas que ya usa el juego (para mapear las del guion a las de siempre)
local traits, choiceKeys, flags, choiceValues = {}, {}, {}, {}
local function scan(value: any, seen: { [any]: boolean })
	if type(value) ~= "table" or seen[value] then
		return
	end
	seen[value] = true
	for k, v in value do
		if k == "Traits" or k == "TraitsBelow" then
			if type(v) == "table" then
				for name in v do
					if type(name) == "string" then
						traits[name] = true
					end
				end
			end
		elseif k == "Choice" or k == "Choices" or k == "NotChoices" then
			if type(v) == "table" then
				for name in v do
					if type(name) == "string" and k == "Choice" and type(v[name]) == "string" then
						local val = v[name]
						choiceValues[val] = if choiceValues[val] == nil or choiceValues[val] == name then name else false
					end
					if type(name) == "string" then
						choiceKeys[name] = true
					end
				end
			end
		elseif k == "Key" and type(v) == "string" and value.Options then
			choiceKeys[v] = true
			-- (decisión en el mundo: sus opciones son los valores)
			for _, opt in value.Options do
				if type(opt) == "table" and type(opt.Id) == "string" then
					choiceValues[opt.Id] = if choiceValues[opt.Id] == nil or choiceValues[opt.Id] == v then v else false
				end
			end
		elseif k == "Flags" or k == "NotFlags" or k == "Unflags" then
			if type(v) == "table" then
				for _, name in v do
					if type(name) == "string" then
						flags[name] = true
					end
				end
			end
		end
		scan(v, seen)
	end
end
scan(Quests, {})
scan(HappeningIndex.all(), {})

-- Nombres del reparto (clave y nombre visible) para reconocer «Ramón» solo en una línea
local knownNames: { [string]: boolean } = {}
for key, person in Cast.People do
	knownNames[Reescritura.norm(key)] = true
	if type(person) == "table" and type(person.Name) == "string" then
		knownNames[Reescritura.norm(person.Name)] = true
	end
end

local Shared = "src/shared"
local ctx = {
	Fx = L.load(Shared .. "/StoryFxCatalog").names(),
	SkyMoods = L.load(Shared .. "/SkyMoods").names(),
	Moods = L.load(SRC .. "/ActorMoods").names(),
	Creatures = L.load(SRC .. "/StoryCreatures").names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
}

local game = {
	Quests = Quests,
	Cast = Cast.People,
	Places = Locations.Places,
	Cinematics = Cinematics,
	Happenings = HappeningIndex.all(),
	Traits = traits,
	ChoiceKeys = choiceKeys,
	ChoiceValues = choiceValues, -- valor de una decisión → su clave (si solo hay una con ese valor)
	Flags = flags,
	Memories = Memories,
	Sequencer = Sequencer,
	SequencerCtx = ctx,
	Vector3 = roblox.Vector3,
	Strings = Strings.es,
}

---------------------------------------------------------------------
-- Informe en Markdown
---------------------------------------------------------------------
local function list(out: { string }, title: string, items: { string }, empty: string?)
	table.insert(out, "## " .. title .. "\n")
	if #items == 0 then
		table.insert(out, "_" .. (empty or "Nada.") .. "_\n")
	end
	for _, item in items do
		table.insert(out, "- " .. item)
	end
	table.insert(out, "")
end

local function informe(id: string, doc: any, R: any, wrote: boolean, extra: string?): string
	local out = {
		("# Informe de la reescritura · %s"):format(id),
		"",
		("Guion: `%s/%s.md` · generado por `lune run scripts/audit/aplicar-reescritura.luau %s`."):format(DIR, id, id),
		if wrote then ("Datos: `%s/%s.luau` (no se edita a mano: se regenera con la herramienta)."):format(OUT, id) else "**No se ha escrito el guion: hay errores.**",
		"",
		"La mecánica de cada paso del juego se conserva tal cual (tipo de paso, sitio, evento, objeto, decisiones del mundo): el guion cambia frases, planos, música y elecciones de las conversaciones.",
		"",
	}
	if extra then
		table.insert(out, extra)
		table.insert(out, "")
	end
	table.insert(out, "## Correspondencia de pasos\n")
	table.insert(out, "| PASO del guion | Tipo | Lugar | Paso del juego |")
	table.insert(out, "|---|---|---|---|")
	local quest = Quests[id]
	for _, row in R.Map do
		local target = "—"
		if row.Target then
			local st = Reescritura.stepAt(quest and quest.Steps or {}, row.Target)
			target = ("%s · %s%s"):format(row.Target, st and st.Type or "?", st and (st.Dialogue and " «" .. st.Dialogue .. "»" or st.Id and " «" .. st.Id .. "»" or st.Place and " @ " .. st.Place or st.Event and " (" .. st.Event .. ")" or st.Prop and " (" .. st.Prop .. ")") or "")
		end
		table.insert(out, ("| %s | %s | %s | %s |"):format(row.Num, row.Type, row.Place, target))
	end
	table.insert(out, "")
	list(out, "Errores", R.Errors, "Ninguno.")
	list(out, "Aplicado", R.Applied)
	list(out, "Adaptado (y por qué)", R.Adapted, "Nada: todo se aplicó tal cual.")
	list(out, "Género ({o/a}) corregido en frases dirigidas al jugador", R.Gender, "Ninguna corrección.")
	list(out, "Avisos", R.Warnings, "Ninguno.")
	list(out, "Notas del guion sin equivalente directo (bloques de dirección, minijuegos, memoria…)", R.Notes, "Ninguna.")
	table.insert(out, "## Cómo se traduce el formato\n")
	table.insert(out, "- **Cinemática** (paso Cinematic del juego): una escena del motor nueva (Happenings/Guion) con un plano de cámara por PLANO (presets de CameraShots: Medio, PrimerPlano, PPP, Hombro, DosPlanos, Lateral, Reaccion, Seguir, Inserto, Dolly, Pan, Tilt; «Cosme» → el actor, «Jugador» → tú, la Grieta/el cielo → plano hacia la Grieta, un sitio → su lugar de la misión, si no un plano general del lugar del paso), las frases con su tiempo y los gestos de la descripción (sonríe, se sorprende, señala…) como emoción/ademán del actor. Si la Grieta se ilumina, destello en el cielo.")
	table.insert(out, "- **Conversación** (Talk/Scene): las frases nuevas con su plano (los Dolly/Pan/Tilt, que la conversación no tiene, pasan a PrimerPlano/General/Medio; un objeto o un sitio, a General), gesto (A/G), pausas («Pausa.», «hace una pausa») y «baja la voz» como acotación. Las ELECCION son la pregunta con sus opciones; los efectos que ya daba el juego se conservan y se suman los del guion; las respuestas de cada rama son los grupos de frases que van justo detrás, en orden.")
	table.insert(out, "- **Paso jugable** (ir a, correr, saltar, coger, abrir el mapa…): no se quita el control. Las frases de antes de la acción suenan al empezar el paso (escena ligera que lanza el paso anterior al cumplirse) y las de después de un PLANO en que el jugador ya lo hace (salta, recoge, abre…), al cumplirlo (o en la conversación del objeto, si lo tiene).")
	table.insert(out, "- **Música**: Calma → Descubrimiento, Tension → Tension, Emocion → Intima, Accion → Tension, Epico → Tema, Comedia → Descubrimiento (intensidades de StoryAudio). En las conversaciones suena con una escena ligera al empezar.")
	table.insert(out, "- **Género**: lo que se le dice al jugador con {o/a} (Bienvenido, Tranquilo, Nervioso, tú solo…); `[tu nombre]` → `{nombre}`.")
	table.insert(out, "")
	local _ = doc
	return table.concat(out, "\n")
end

---------------------------------------------------------------------
-- La lista de GuionOverlay
---------------------------------------------------------------------
local function updateList(id: string, add: boolean)
	local source = fs.readFile(OVERLAY)
	local head, body, tail = source:match("^(.-GuionOverlay%.List = {\n)(.-)(}\n%-%- END GUIONES.*)$")
	if not head then
		error("GuionOverlay.luau: no encuentro la lista entre BEGIN/END GUIONES")
	end
	local ids = {}
	for existing in body:gmatch('"([%w_]+)"') do
		if existing ~= id then
			table.insert(ids, existing)
		end
	end
	if add then
		table.insert(ids, id)
	end
	table.sort(ids)
	local lines = {}
	for _, x in ids do
		table.insert(lines, ('\t"%s",\n'):format(x))
	end
	fs.writeFile(OVERLAY, head .. table.concat(lines) .. tail)
end

---------------------------------------------------------------------
-- Una misión
---------------------------------------------------------------------
-- (formato libre: un nombre solo en su línea es alguien que habla si está en el reparto o en el mapa)
local function setKnown(id: string)
	local mapaPath = ("%s/%s.mapa"):format(DIR, id)
	local mapa = if fs.isFile(mapaPath .. ".luau") then L.load(mapaPath) else nil
	Reescritura.knownSpeaker = function(raw: string): boolean
		local n = Reescritura.norm(raw)
		return knownNames[n] == true or Reescritura.SpeakerAliases[n] ~= nil or (mapa ~= nil and mapa.Hablantes ~= nil and mapa.Hablantes[raw] ~= nil)
	end
end

local function apply(id: string, checkOnly: boolean): boolean
	local path = ("%s/%s.md"):format(DIR, id)
	if not fs.isFile(path) then
		print(("❌ No existe %s"):format(path))
		return false
	end
	local mapa = nil
	local mapaPath = ("%s/%s.mapa"):format(DIR, id)
	if fs.isFile(mapaPath .. ".luau") then
		mapa = L.load(mapaPath)
	end
	-- (formato libre: un nombre solo en su línea es alguien que habla si está en el reparto o en el mapa)
	Reescritura.knownSpeaker = function(raw: string): boolean
		local n = Reescritura.norm(raw)
		return knownNames[n] == true or Reescritura.SpeakerAliases[n] ~= nil or (mapa ~= nil and mapa.Hablantes ~= nil and mapa.Hablantes[raw] ~= nil)
	end
	local doc = Reescritura.parse(fs.readFile(path))
	if doc.Id and doc.Id ~= id then
		print(("⚠️ El guion dice MISION: %s (el archivo es %s): se usa %s"):format(doc.Id, id, id))
	end
	doc.Id = id
	local guion, R = Reescritura.build(doc, game, mapa)
	print(("\n▶ %s · %d pasos en el guion · %d errores · %d avisos · %d adaptaciones"):format(id, #doc.Steps, #R.Errors, #R.Warnings, #R.Adapted))
	for _, e in R.Errors do
		print("  ❌ " .. e)
	end
	for _, w in R.Warnings do
		print("  ⚠️ " .. w)
	end
	local ok = #R.Errors == 0
	local header = ("-- GUION REESCRITO de %s (GENERADO: no se edita a mano).\n-- Fuente: %s · se regenera con: lune run scripts/audit/aplicar-reescritura.luau %s\n-- Formato: shared/LifeStory/GuionOverlay.luau · informe: %s/%s.informe.md\n"):format(id, path, id, DIR, id)
	local generated = if ok then Reescritura.serialize(guion, header) else nil
	if checkOnly then
		-- ¿Los datos escritos son los que saldrían ahora? (si la misión o el guion cambiaron, hay que regenerar)
		local file = ("%s/%s.luau"):format(OUT, id)
		if ok and fs.isFile(file) and fs.readFile(file) ~= generated then
			print(("  ❌ %s está desactualizado: vuelve a ejecutar la herramienta para %s"):format(file, id))
			ok = false
		end
		for _, a in R.Applied do
			print("  ✅ " .. a)
		end
		for _, a in R.Adapted do
			print("  ↪ " .. a)
		end
		return ok
	end
	if ok then
		if not fs.isDir(OUT) then
			fs.writeDir(OUT)
		end
		fs.writeFile(("%s/%s.luau"):format(OUT, id), generated :: string)
		updateList(id, true)
	end
	fs.writeFile(("%s/%s.informe.md"):format(DIR, id), informe(id, doc, R, ok, mapa and mapa.Informe or nil))
	print(if ok then ("  ✅ escrito %s/%s.luau y %s/%s.informe.md"):format(OUT, id, DIR, id) else "  ❌ con errores: solo se escribe el informe")
	return ok
end

local args = process.args
local checkOnly = table.find(args, "--check") ~= nil

-- --leer <IdMision> <PASO>: cómo se ha leído un PASO del guion (para ver por qué algo no sale)
if table.find(args, "--leer") then
	local id, num = nil, nil
	for _, a in args do
		if a:sub(1, 2) ~= "--" then
			if id then
				num = a
			else
				id = a
			end
		end
	end
	setKnown(tostring(id))
	local doc = Reescritura.parse(fs.readFile(("%s/%s.md"):format(DIR, tostring(id))))
	local function show(items: { any }, indent: string)
		for _, it in items do
			if it.K ~= "Blank" then
				print(("%s%s · línea %s · %s · %s"):format(indent, it.K, tostring(it.Line), tostring(it.S or it.Kind or it.Head or it.Name or ""), (tostring(it.T or it.Desc or it.If or "")):sub(1, 60)))
			end
			if it.K == "Block" then
				show(it.Items, indent .. "  ")
			elseif it.K == "Choice" then
				for _, o in it.Options do
					print(("%s  opción %s · %s%s · %d frases dentro"):format(indent, o.Letter, tostring(o.T), if o.Cond then " (si " .. o.Cond .. ")" else "", #(o.Items or {})))
					show(o.Items or {}, indent .. "    ")
				end
			end
		end
	end
	for _, s in doc.Steps do
		if s.Num == num then
			print(("PASO %s [%s] @ %s · música %s · condición %s"):format(s.Num, s.Type, s.Place, table.concat(s.Music, "→"), tostring(s.Cond)))
			show(s.Items, "  ")
		end
	end
	process.exit(0)
end

-- --pasos: los pasos de la misión en el juego y los PASO del guion (para escribir el mapa)
if table.find(args, "--pasos") then
	for _, a in args do
		if a:sub(1, 2) ~= "--" then
			local quest = Quests[a]
			if not quest then
				print("❌ No existe la misión " .. a)
				continue
			end
			print(("\n▶ %s en el juego (%d pasos)"):format(a, #quest.Steps))
			local function show(list: { any }, prefix: string)
				for i, st in list do
					local bits = {}
					for _, f in { "Dialogue", "Id", "Cinematic", "Place", "Event", "Prop", "Npc", "Key", "Game", "Stage" } do
						if st[f] ~= nil then
							table.insert(bits, ("%s=%s"):format(f, tostring(st[f])))
						end
					end
					if st.If then
						table.insert(bits, "If")
					end
					print(("  %s%d · %s %s · %s"):format(prefix, i, st.Type, table.concat(bits, " "), tostring(st.Text or st.TextKey or "")))
					if st.Steps then
						show(st.Steps, prefix .. i .. ".")
					end
				end
			end
			show(quest.Steps, "")
			local path = ("%s/%s.md"):format(DIR, a)
			if fs.isFile(path) then
				setKnown(a)
				local doc = Reescritura.parse(fs.readFile(path))
				print(("▶ %s en el guion (%d PASO)"):format(a, #doc.Steps))
				for _, s in doc.Steps do
					local lines = 0
					for _, it in s.Items do
						lines += if it.K == "Line" then 1 else 0
					end
					print(("  PASO %s [%s] @ %s · %d frases%s"):format(s.Num, s.Type, s.Place, lines, if s.Heading then " · " .. s.Heading else ""))
				end
			end
		end
	end
	process.exit(0)
end
local ids = {}
if table.find(args, "--todas") then
	for _, name in fs.readDir(DIR) do
		local id = name:match("^([%w_]+)%.md$")
		if id and (fs.isFile(("%s/%s.luau"):format(OUT, id)) or fs.isFile(("%s/%s.mapa.luau"):format(DIR, id))) then -- (solo las ya aplicadas o con su mapa)
			table.insert(ids, id)
		end
	end
	table.sort(ids)
else
	for _, a in args do
		if a:sub(1, 2) ~= "--" then
			table.insert(ids, (a:gsub("%.md$", ""):gsub("^.*/", "")))
		end
	end
end
if #ids == 0 then
	print("Uso: lune run scripts/audit/aplicar-reescritura.luau <IdMision> [--check] | --todas")
	process.exit(1)
end
local allOk = true
for _, id in ids do
	allOk = apply(id, checkOnly) and allOk
end
process.exit(if allOk then 0 else 1)
