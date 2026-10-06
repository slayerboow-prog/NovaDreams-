-- Prueba del paquete P8e · SAGA DE LA GRIETA, RAREZAS Y ALIADOS (Lune, fuera de Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-saga.luau
--
-- Comprueba:
--   1. Las escenas escritas a mano del arco de la Grieta (Happenings/Cielo) existen, están en el índice,
--      pasan la validación del motor y abren con el comentario de las cinco preguntas de la regla de oro.
--   2. Gramática de descubrimiento: plano de situación → reacción → inserto (o el cielo) en las de cámara;
--      ambiente, luz e intensidad de música; las ligeras no tienen cámara.
--   3. Variantes y condiciones: cada variante se elige con su condición y cambia lo que se ve; las frases
--      con If/IfNot salen una u otra (nunca las dos, nunca ninguna).
--   4. Las misiones lanzan las escenas nuevas en el mismo paso que la cinemática vieja (no cambia el
--      número de pasos), y las escenas ligeras salen como efecto (Effects.Scene) donde toca.
--   5. Continuidad (W-05): las marcas y recuerdos de la Saga que antes nadie leía ahora los cita alguien.
--   6. Escritura: sin parrafadas (> 150 caracteres) ni dobletes de género en los archivos del paquete,
--      menos narrador que antes, y las frases que comprueban otras pruebas siguen ahí.

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")

local check = L.check

local Sequencer = L.load("src/shared/LifeStory/Sequencer")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Locations = L.load("src/shared/LifeStory/Locations")
local Cast = L.load("src/shared/LifeStory/Cast")
local Catalog = L.load("src/shared/StoryFxCatalog")
local SkyMoods = L.load("src/shared/SkyMoods")
local SkyRift = L.load("src/shared/SkyRift")
local ActorMoods = L.load("src/shared/LifeStory/ActorMoods")
local StoryCreatures = L.load("src/shared/LifeStory/StoryCreatures")
local Quests = L.load("src/shared/LifeStory/Quests")

local CIELO_PATH = "src/shared/LifeStory/Happenings/Cielo.luau"
local MISSION_FILES = {
	"src/shared/LifeStory/Misiones/Saga_Acto1.luau",
	"src/shared/LifeStory/Misiones/Saga_Acto2.luau",
	"src/shared/LifeStory/Misiones/Saga_Acto3.luau",
	"src/shared/LifeStory/Misiones/Saga_Acto4.luau",
	"src/shared/LifeStory/Misiones/Rarezas.luau",
	"src/shared/LifeStory/Misiones/Aliados.luau",
	"src/shared/LifeStory/Misiones/Loco_Nino.luau",
}

-- Las escenas del arco de la Grieta: id → { Light = escena ligera?, Mission, Phase (fase de SkyRift) }
local ARC = {
	Grieta_Rasguno = { Light = true, Mission = "Loco_N1_Cosme", Phase = "Rasguno" },
	Grieta_Caen = { Mission = "Saga_02_Grieta", Phase = "Crece" },
	Grieta_Grande = { Light = true, Mission = "Saga_05_Perdidas", Phase = "Grande" },
	Grieta_Coser = { Mission = "Saga_06_Coser", Phase = "Abierta", New = true },
	Grieta_Rota = { Mission = "Saga_12_Graduacion", Phase = "Rota", New = true },
	Grieta_Inminente = { Light = true, Mission = "Saga_18_Precio", Phase = "Inminente" },
	Grieta_Fusion = { Mission = "Saga_23_Fusion", Phase = "Fusion", New = true },
	Grieta_Final = { Mission = "Saga_24_Final", Phase = "Ultima", New = true },
}
-- Qué cinemática vieja sustituye cada una (el mismo paso de la misma misión)
local REPLACES = { Grieta_Coser = "Saga_Coser", Grieta_Rota = "Saga_Grieta2", Grieta_Fusion = "Saga_Fusion", Grieta_Final = "Saga_Final" }

local ctx = {
	Fx = Catalog.names(),
	SkyMoods = SkyMoods.names(),
	Moods = ActorMoods.names(),
	Creatures = StoryCreatures.names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
}

local cieloSource = fs.readFile(CIELO_PATH)

-- Un juez de condiciones de mentira (en el juego: HappeningService.checker con la partida)
local function judge(facts: { [string]: any })
	return function(req: { [string]: any }): boolean
		for _, f in req.Flags or {} do
			if not (facts.Flags or {})[f] then
				return false
			end
		end
		for _, f in req.NotFlags or {} do
			if (facts.Flags or {})[f] then
				return false
			end
		end
		for _, m in req.Memories or {} do
			if not (facts.Memories or {})[m] then
				return false
			end
		end
		for _, m in req.NotMemories or {} do
			if (facts.Memories or {})[m] then
				return false
			end
		end
		if req.MemoriesAtLeast then
			local n = 0
			for _, m in req.MemoriesAtLeast.Of do
				if (facts.Memories or {})[m] then
					n += 1
				end
			end
			if n < req.MemoriesAtLeast.N then
				return false
			end
		end
		return true
	end
end

local function textsOf(def: { [string]: any }): { string }
	local out = {}
	for _, line in (def.Tracks or {}).Dialogue or {} do
		table.insert(out, line.T)
	end
	return out
end

local function has(list: { string }, fragment: string): boolean
	for _, t in list do
		if type(t) == "string" and t:find(fragment, 1, true) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
print("1. Las escenas del arco de la Grieta existen, están registradas y se validan")
---------------------------------------------------------------------
for id, info in ARC do
	local def = HappeningIndex.get(id)
	check(def ~= nil and HappeningIndex.groupOf(id) == "Cielo", id .. ": está en el índice (grupo Cielo)")
	if not def then
		continue
	end
	local errors = Sequencer.validate(id, def, ctx)
	for _, e in errors do
		print("     " .. e)
	end
	check(#errors == 0, id .. ": pasa la validación del motor")
	check(SkyRift.Phases[info.Phase] ~= nil, id .. ": corresponde a la fase " .. info.Phase .. " de la Grieta")
	if info.New or info.Light then
		-- El comentario de las cinco preguntas, justo antes de la definición
		local at = cieloSource:find("\n\t" .. id .. " = {", 1, true)
		local before = at and cieloSource:sub(math.max(1, at - 1400), at) or ""
		-- (el comentario va entre las dos últimas rayas «-----» antes de la definición)
		local rules = {}
		for pos in before:gmatch("()%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-") do
			if #rules == 0 or pos > rules[#rules] + 40 then
				table.insert(rules, pos)
			end
		end
		local block = if #rules >= 2 then before:sub(rules[#rules - 1], rules[#rules]) else ""
		local ok = true
		for _, q in { "¿Qué está pasando?", "¿Por qué?", "¿Qué siente el personaje?", "¿Qué ve el jugador?", "¿Qué quiero que sienta el jugador?" } do
			if not block:find(q, 1, true) then
				ok = false
				print("     falta «" .. q .. "»")
			end
		end
		check(ok, id .. ": abre con las cinco preguntas de la regla de oro")
	end
	check(Sequencer.isLight(def) == (info.Light == true), id .. (if info.Light then ": ligera (sin cámara: la conversación sigue)" else ": con cámara"))
end
-- Ninguna se llama como una cinemática vieja (el validador lo prohíbe: se sustituyen, no se pisan)
local Cinematics = L.load("src/shared/LifeStory/Cinematics")
for id in ARC do
	check(Cinematics[id] == nil, id .. ": no pisa el nombre de una cinemática vieja")
end

---------------------------------------------------------------------
print("2. Gramática de descubrimiento, ambiente, luz y música")
---------------------------------------------------------------------
for id, info in ARC do
	if not info.New then
		continue
	end
	local def = HappeningIndex.get(id)
	local ex = Sequencer.expand(def, Sequencer.resolve(def, judge({})))
	local camera = ex.Tracks.Camera or {}
	table.sort(camera, function(a, b)
		return (a.At or 0) < (b.At or 0)
	end)
	local first = camera[1]
	local establishing = first and first.At == 0 and (first.Preset == "General" or (first.From and (first.From[2] or Vector3.zero).Magnitude > 20) or (first.Shot and first.Shot:find("^General")))
	check(establishing, id .. ": empieza con un plano de situación")
	local reaction, insert, sky = false, false, false
	for _, shot in camera do
		local name = shot.Shot or ""
		if name:find("^Reaccion") then
			reaction = true
		end
		if name:find("^Inserto") then
			insert = true
		end
		-- Mirar la Grieta (Look/LookTo = "Grieta") cuenta como inserto: el objeto del descubrimiento es el cielo
		if (shot.LookTo and shot.LookTo[1] == "Grieta") or (shot.Look and shot.Look[1] == "Grieta") then
			sky = true
		end
	end
	check(reaction, id .. ": tiene plano de reacción")
	check(insert or sky, id .. ": tiene inserto (un objeto o la Grieta)")
	check(sky, id .. ": la cámara mira la Grieta del cielo")
	check(#(def.Tracks.Ambience or {}) > 0, id .. ": ambiente (nunca silencio absoluto)")
	local intensity = false
	for _, m in def.Tracks.Music or {} do
		if m.Intensity then
			intensity = true
		end
	end
	check(intensity, id .. ": música por intensidad")
	local skyEvent = false
	for _, s in def.Tracks.Sky or {} do
		if s.Rift or s.Mood then
			skyEvent = true
		end
	end
	check(skyEvent, id .. ": la Grieta se enciende (pista Sky)")
	check(def.Skippable ~= false, id .. ": se puede saltar")
	-- Entradas andando, nada de aparecer de golpe en plano cerrado
	local timeline = Sequencer.compile(id, def)
	check(timeline.Duration >= 20 and timeline.Duration <= 40, ("%s: dura lo justo (%.1f s)"):format(id, timeline.Duration))
end
check(HappeningIndex.get("Grieta_Fusion").Tracks.Actors ~= nil and (function()
	for _, a in HappeningIndex.get("Grieta_Fusion").Tracks.Actors do
		if a.Enter and a.Enter.Key == "Cosimo" and a.Enter.Walk == true then
			return true
		end
	end
	return false
end)(), "Grieta_Fusion: Cósimo entra ANDANDO (sin teletransporte)")
local finalLight = false
for _, l in HappeningIndex.get("Grieta_Final").Tracks.Light do
	if l.Preset == "Atardecer" then
		finalLight = true
	end
end
check(finalLight, "Grieta_Final: al cerrarse la Grieta, la luz pasa de noche a amanecer dorado")

---------------------------------------------------------------------
print("3. Variantes y condiciones")
---------------------------------------------------------------------
do
	local final = HappeningIndex.get("Grieta_Final")
	local base = Sequencer.resolve(final, judge({}))
	local perd = Sequencer.resolve(final, judge({ Flags = { CosimoPerdonado = true } }))
	local arr = Sequencer.resolve(final, judge({ Flags = { CosimoArregla66B = true } }))
	check(base.Variant == nil and perd.Variant == 1 and arr.Variant == 2, "Grieta_Final: variante según lo que decidiste con Cósimo en el monte")
	local t0 = textsOf(Sequencer.expand(final, base))
	local t1 = textsOf(Sequencer.expand(final, perd))
	local t2 = textsOf(Sequencer.expand(final, arr))
	check(has(t1, "afeitado") and not has(t0, "afeitado"), "…perdonado: se ha afeitado la perilla")
	check(has(t2, "66-B") and not has(t0, "66-B"), "…arregla la 66-B: vuelve mañana a arreglarla")
	local withMemory = textsOf(Sequencer.expand(final, Sequencer.resolve(final, judge({ Memories = { CoserElCielo = true } }))))
	check(has(withMemory, "primer anclaje") and not has(withMemory, "Aquí empezó todo"), "…si recuerdas «Coser el cielo», Cosme cita el primer anclaje (y no la otra frase)")
	check(has(t0, "Aquí empezó todo") and not has(t0, "primer anclaje"), "…si no, la frase de siempre (nunca las dos)")

	local fusion = HappeningIndex.get("Grieta_Fusion")
	local restos = {}
	for _, m in { "BuzonPasado", "PerroBinario", "Piso13", "NubePerdida" } do
		restos[m] = true
	end
	check(Sequencer.resolve(fusion, judge({ Memories = restos })).Variant == 1, "Grieta_Fusion: con 4 Restos de la Grieta, la colección brilla (variante «Restos»)")
	check(Sequencer.resolve(fusion, judge({ Memories = { BuzonPasado = true } })).Variant == nil, "…con menos, la escena de siempre")
	local trampa = textsOf(Sequencer.expand(fusion, Sequencer.resolve(fusion, judge({ Flags = { TrampaCosimo = true } }))))
	local no = textsOf(Sequencer.expand(fusion, Sequencer.resolve(fusion, judge({}))))
	check(has(trampa, "Ha picado") and not has(no, "Ha picado"), "…si le tendiste una trampa, Cosme lo comenta")
	local grieta = textsOf(Sequencer.expand(fusion, Sequencer.resolve(fusion, judge({ Memories = { GrietaEnElCielo = true } }))))
	check(has(grieta, "rasguño"), "…y recuerda el rasguño del primer día («La grieta en el cielo»)")

	local coser = HappeningIndex.get("Grieta_Coser")
	local barrio = Sequencer.resolve(coser, judge({ Flags = { VecinosNotanRarezas = true } }))
	check(barrio.Variant == 1 and has(textsOf(Sequencer.expand(coser, barrio)), "Ramón"), "Grieta_Coser: si el barrio vio las rarezas, Pip ve a Ramón en la ventana")

	local rota = HappeningIndex.get("Grieta_Rota")
	local fiesta = textsOf(Sequencer.expand(rota, Sequencer.resolve(rota, judge({ Memories = { FiestaFinDelMundo = true } }))))
	local sinFiesta = textsOf(Sequencer.expand(rota, Sequencer.resolve(rota, judge({}))))
	check(has(fiesta, "números del cielo") and not has(sinFiesta, "números del cielo") and has(sinFiesta, "cremallera"), "Grieta_Rota: Omar ata cabos con la cuenta atrás de la fiesta (o Sara, si no estuviste)")
	-- Todas las variantes de todas las escenas se pueden escribir (expand) sin errores
	local okAll = true
	for id in ARC do
		local def = HappeningIndex.get(id)
		for i in def.Variants or {} do
			local ok = pcall(Sequencer.compile, id, def, { Variant = i, Gates = {} })
			okAll = okAll and ok
		end
	end
	check(okAll, "todas las variantes se compilan")
end

---------------------------------------------------------------------
print("4. Las misiones lanzan las escenas nuevas (mismo paso, mismo número de pasos)")
---------------------------------------------------------------------
local function stepWith(quest: { [string]: any }, id: string): (number?, { [string]: any }?)
	for i, step in quest.Steps do
		if step.Type == "Cinematic" and step.Id == id then
			return i, step
		end
	end
	return nil, nil
end
local EXPECTED_STEPS = { Saga_06_Coser = 5, Saga_12_Graduacion = 5, Saga_23_Fusion = 8, Saga_24_Final = 4 }
for id, old in REPLACES do
	local mission = ARC[id].Mission
	local quest = Quests[mission]
	local index = quest and stepWith(quest, id)
	check(index ~= nil and stepWith(quest, old) == nil, ("%s: el paso de cine es ahora %s (antes %s)"):format(mission, id, old))
	check(quest and #quest.Steps == EXPECTED_STEPS[mission], ("%s: sigue teniendo %d pasos (las partidas a medias no se mueven)"):format(mission, EXPECTED_STEPS[mission]))
end
-- Las escenas ligeras: efecto de una conversación o de una respuesta
local function sceneEffect(quest: { [string]: any }, sceneId: string): boolean
	local found = false
	local function scan(effects: any)
		if type(effects) == "table" and effects.Scene == sceneId then
			found = true
		end
	end
	for _, d in quest.Dialogues or {} do
		scan(d.Effects)
		for _, line in d.Lines or {} do
			for _, option in line.Options or {} do
				scan(option.Effects)
			end
		end
	end
	for _, step in quest.Steps do
		scan(step.Effects)
	end
	return found
end
for id, info in ARC do
	if info.Light then
		check(sceneEffect(Quests[info.Mission], id), ("%s: la lanza %s"):format(id, info.Mission))
	end
end
check(stepWith(Quests.Saga_02_Grieta, "Grieta_Caen") ~= nil, "Saga_02_Grieta sigue lanzando Grieta_Caen")
-- El rasguño se ve en cuanto contestas a Cosme (la marca GrietaVista llega con la respuesta)
do
	local prueba = Quests.Loco_N1_Cosme.Dialogues.Prueba
	local both = 0
	for _, line in prueba.Lines do
		for _, option in line.Options or {} do
			if option.Effects and option.Effects.Scene == "Grieta_Rasguno" and table.find(option.Effects.Flags or {}, "GrietaVista") then
				both += 1
			end
		end
	end
	check(both == 2, "Loco_N1_Cosme: digas lo que digas, el rasguño aparece en el cielo mientras Cosme lo mira")
end
-- Las conversaciones que siguen a las escenas ya no repiten con el narrador lo que se acaba de ver
check(not has((function()
	local t = {}
	for _, l in Quests.Saga_24_Final.Dialogues.Final.Lines do
		table.insert(t, l.T or "")
	end
	return t
end)(), "La aguja sube"), "Saga_24_Final: el narrador ya no cuenta la última costura (se ve en Grieta_Final)")
check(not has((function()
	local t = {}
	for _, l in Quests.Saga_06_Coser.Dialogues.Voz.Lines do
		table.insert(t, l.T or "")
	end
	return t
end)(), "La aguja sube como un cohete"), "Saga_06_Coser: el narrador ya no cuenta la costura (se ve en Grieta_Coser)")
check(not has((function()
	local t = {}
	for _, l in Quests.Saga_12_Graduacion.Dialogues.Cosimo.Lines do
		table.insert(t, l.T or "")
	end
	return t
end)(), "cremallera gigante"), "Saga_12_Graduacion: la costura que se rompe se ve, no se cuenta")

---------------------------------------------------------------------
print("5. Continuidad: lo que hiciste en la Saga, alguien lo recuerda")
---------------------------------------------------------------------
-- Recoge todas las condiciones (If de líneas, opciones, pasos y actores) de todas las misiones y escenas
local readFlags, readMemories, readChoices = {}, {}, {}
local function collect(req: any)
	if type(req) ~= "table" then
		return
	end
	for _, f in req.Flags or {} do
		readFlags[f] = true
	end
	for _, f in req.NotFlags or {} do
		readFlags[f] = true
	end
	for _, m in req.Memories or {} do
		readMemories[m] = true
	end
	for _, m in req.NotMemories or {} do
		readMemories[m] = true
	end
	for k in req.Choices or {} do
		readChoices[k] = true
	end
	if type(req.MemoriesAtLeast) == "table" then
		for _, m in req.MemoriesAtLeast.Of or {} do
			readMemories[m] = true
		end
	end
end
local function walk(value: any, depth: number)
	if type(value) ~= "table" or depth > 12 then
		return
	end
	if value.If then
		collect(value.If)
	end
	if value.IfNot then
		collect(value.IfNot)
	end
	for k, v in value do
		if k ~= "If" and k ~= "IfNot" then
			walk(v, depth + 1)
		end
	end
end
for _, quest in Quests do
	walk(quest.Steps, 0)
	walk(quest.Dialogues, 0)
	walk(quest.Actors, 0)
	collect(quest.Requires)
end
for _, def in HappeningIndex.all() do
	walk(def.Tracks, 0)
	walk(def.Variants, 0)
end
-- Lo que la auditoría (§4.3, anexo D) marcó como «se escribe y nadie lo lee» en la Saga y los aliados
local MUST_FLAGS = {
	"AmigoDeCosme", "SecretoCosme", "SabeDeCosimo", "OyoAncla", "ConoceConsorcio", "CronosTeConoce", "VecinosNotanRarezas",
	"CosimoTeHaVisto", "AyudanteOficial", "EnseñasteCredencial", "SabeFusion", "SabeQueEsAncla", "PerdonaACosme", "EnfadoConCosme",
	"FiestaSaboteada", "EquipoRescate", "CompisSabenGrieta", "CoordenadasCosimo", "BuenRodaje", "GrabacionLaboratorio", "MalvadoAyudo",
	"CosmeRecuerda", "AliadosReunidos", "ConsorcioCaido", "TrampaCosimo", "CosimoPerdonado", "CosimoArregla66B", "FusionDetenida",
	"CancillerGatonia", "RexAbogado", "PatrullaRatones", "CronosLimpio", "NaveEnElFinal", "GnomosEnPie", "MalvadoAprendeBondad",
	"PunteriaDeCampeon", "AliadoCompis", "AliadoCronos",
}
local MUST_MEMORIES = {
	"ConociCosme", "GrietaEnElCielo", "DonEscamas", "VentanillaAduana", "CosasPerdidas", "CoserElCielo", "AyudanteCosme",
	"ProyectoFusion", "EresElAncla", "FiestaFinDelMundo", "CronosAliado", "GraduacionInterdimensional", "EquipoRescate",
	"PresidenteBigotes", "EpisodioEspecial", "RescateCosme", "TuNombre", "CosmeRecuerda", "TodosLosAliados", "CaidaConsorcio",
	"ElTrato", "GranFusion", "EmperadorBigotes", "LosClones", "RatonPerez", "TirachinasAbu", "GuardiaGatuna", "AbogadoRex",
	"MuelaDelJuicio", "ExpedienteCronos", "TemporadaFinal", "ConsejoGnomos", "ClasesDeBondad",
}
local missing = {}
for _, f in MUST_FLAGS do
	if not readFlags[f] then
		table.insert(missing, "marca " .. f)
	end
end
for _, m in MUST_MEMORIES do
	if not readMemories[m] then
		table.insert(missing, "recuerdo " .. m)
	end
end
for _, m in missing do
	print("     nadie lee: " .. m)
end
check(#missing == 0, ("las %d marcas y %d recuerdos de la Saga y los aliados los cita alguien después"):format(#MUST_FLAGS, #MUST_MEMORIES))
check(readChoices.Trato and readChoices.Alegato and readChoices.Declaracion and readChoices.Espias and readChoices.Leccion, "las decisiones de la Saga y los aliados (el trato, el alegato, la declaración, los espías, la lección) se recuerdan")
-- Y que esas marcas existan de verdad (las escribe alguna misión): no se cita algo que nunca pasa
local written = {}
local function collectWrites(value: any, depth: number)
	if type(value) ~= "table" or depth > 12 then
		return
	end
	for k, v in value do
		if (k == "Flags") and type(v) == "table" and value.If ~= v then
			for _, f in v do
				if type(f) == "string" then
					written[f] = true
				end
			end
		end
		if k ~= "If" and k ~= "IfNot" and k ~= "Requires" then
			collectWrites(v, depth + 1)
		end
	end
end
for _, quest in Quests do
	collectWrites(quest.Rewards, 0)
	collectWrites(quest.Steps, 0)
	collectWrites(quest.Dialogues, 0)
	if quest.Memory then
		written[quest.Memory] = true
	end
end
local ghost = {}
for _, f in MUST_FLAGS do
	if not written[f] then
		table.insert(ghost, f)
	end
end
for _, m in MUST_MEMORIES do
	if not written[m] then
		table.insert(ghost, m)
	end
end
for _, g in ghost do
	print("     nadie escribe: " .. g)
end
check(#ghost == 0, "todas las marcas y recuerdos citados los escribe alguna misión")

---------------------------------------------------------------------
print("6. Escritura")
---------------------------------------------------------------------
local long, doublets, narrator, total = {}, {}, 0, 0
for _, path in MISSION_FILES do
	local source = fs.readFile(path)
	for line in source:gmatch("[^\n]+") do
		local speaker, text = line:match('S = "([%w_]+)", T = "(.-[^\\])"')
		if speaker and text then
			total += 1
			if speaker == "Narrador" then
				narrator += 1
			end
			if (utf8.len(text) or #text) > 150 then
				table.insert(long, ("%s: %s…"):format(path:match("[^/]+$"), text:sub(1, 60)))
			end
		end
		for _, pattern in { "[Bb]ienvenido o bienvenida", "[Ff]avorito o favorita", "[Dd]uque o [Dd]uquesa", "chiquitín o chiquitina", "[Hh]ija, hijo", "[Vv]en sola, ven solo" } do
			if line:find(pattern) then
				table.insert(doublets, path:match("[^/]+$") .. ": " .. pattern)
			end
		end
	end
end
for _, l in long do
	print("     parrafada: " .. l)
end
check(#long == 0, "ninguna frase de más de 150 caracteres (se parten en tiempos)")
for _, d in doublets do
	print("     doblete: " .. d)
end
check(#doublets == 0, "sin dobletes de género (token {o/a} o forma neutra)")
local share = narrator / math.max(total, 1)
check(share < 0.26, ("el narrador habla menos (%.0f %% de %d frases; antes, 33 %%)"):format(share * 100, total))
-- Frases que comprueban otras pruebas (test-lifestory, test-mision-grieta…): siguen ahí
local all = ""
for _, path in MISSION_FILES do
	all ..= fs.readFile(path)
end
for _, fragment in {
	"…Cósimo.", "He hablado de más", "Alguien del otro lado tira de ella", "Hay cosas que perdemos", "Ya te he visto, Ancla",
	"¿Por qué me pesan las piernas?", "Te ha cogido con el pico", "Todos los gatos hablamos", "Solo a latas", "Son robots, no palomas",
	"por aula es el máximo legal", "Firmo yo por los dos", "La verdad no necesita sello", "Lees la letra pequeña", "aviones de Andrómeda",
	"jefa de turno", "Id a espiar a vuestra abuela", "multado tres veces", "del Cojín: tu título sigue en vigor",
} do
	check(all:find(fragment, 1, true) ~= nil, "sigue la frase «" .. fragment .. "»")
end

L.finish("test-saga")
