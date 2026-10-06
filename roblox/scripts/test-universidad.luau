-- Prueba del paquete P8c · UNIVERSIDAD (escenas de Happenings/Universidad.luau y las misiones Uni*).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-universidad.luau            (las comprobaciones)
--   lune run scripts/test-universidad.luau tiempos    (además, el guion con tiempos de cada variante)
--
-- Comprueba:
--   1. Las escenas existen, están en HappeningIndex (grupo "Universidad") y validan (Sequencer.validate
--      con los lugares, el reparto, las emociones y los efectos de verdad).
--   2. Cada escena empieza con el comentario de la regla de oro (las cinco preguntas).
--   3. Las misiones las lanzan (paso Cinematic con su Id) y siguen teniendo los mismos pasos.
--   4. Las variantes se resuelven: con distintas partidas (marcas, decisiones, recuerdos, objetos) sale
--      lo que toca (la cita con cada persona, el reloj o no, llegar tarde, el equipo unido…), sin huecos
--      raros y con la escena entera dentro de un tiempo razonable.
--   5. Continuidad (W-05): las escenas leen lo que se escribió antes (lista de marcas, decisiones,
--      recuerdos y objetos), y lo que leen existe en alguna misión.
--   6. Quien habla está en la escena (C-09): en las conversaciones de las misiones Uni y en las escenas.
--   7. Sin dobletes de género («o sola», «o nerviosa»…) ni acotaciones escritas en las escenas.

local fs = require("@lune/fs")
local process = require("@lune/process")
local L = require("./lib/ModuleLoader")

local check = L.check
local SHOW = process.args[1] == "tiempos"

local Sequencer = L.load("src/shared/LifeStory/Sequencer")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Locations = L.load("src/shared/LifeStory/Locations")
local Cast = L.load("src/shared/LifeStory/Cast")
local Catalog = L.load("src/shared/StoryFxCatalog")
local SkyMoods = L.load("src/shared/SkyMoods")
local ActorMoods = L.load("src/shared/LifeStory/ActorMoods")
local StoryCreatures = L.load("src/shared/LifeStory/StoryCreatures")
local Conditions = L.load("src/shared/LifeStory/Conditions")

local GROUP_PATH = "src/shared/LifeStory/Happenings/Universidad"
local Group = L.load(GROUP_PATH)
local source = fs.readFile(GROUP_PATH .. ".luau")

-- Escena → misión y paso que la lanza
local SCENES = {
	Uni01_Campus = { Quest = "Uni01_PrimerDia", File = "Uni01_PrimerDia" },
	Uni01_Beltran = { Quest = "Uni01_PrimerDia", File = "Uni01_PrimerDia" },
	Uni01_Mensajes = { Quest = "Uni01_PrimerDia", File = "Uni01_PrimerDia" },
	Uni02_Reunion = { Quest = "Uni02_ElProyecto", File = "Uni02_ElProyecto" },
	Uni05_Visita = { Quest = "Uni05_PrimerPiso", File = "Uni05_PrimerPiso" },
	UniS_Cita_Invitacion = { Quest = "UniS_Cita", File = "Uni_Secundarias" },
	Uni06_Ceremonia = { Quest = "Uni06_Graduacion", File = "Uni06_Graduacion" },
	Uni06_Brindis = { Quest = "Uni06_Graduacion", File = "Uni06_Graduacion" },
	Uni06_Final = { Quest = "Uni06_Graduacion", File = "Uni06_Graduacion" },
}
-- Cuántos pasos tenía cada misión antes del paquete (las partidas guardadas apuntan a un paso)
local STEP_COUNT = {
	Uni01_PrimerDia = 14,
	Uni01b_Residencia = 9,
	Uni02_ElProyecto = 17,
	Uni03_PrimerTrabajo = 21,
	Uni04_Practicas = 9,
	Uni05_PrimerPiso = 11,
	Uni06_Graduacion = 14,
	UniS_Cita = 6,
}

-- Todas las misiones (para buscar quién escribe cada marca)
local Quests = L.load("src/shared/LifeStory/Quests")
local function questById(id: string): any
	if type(Quests.get) == "function" then
		return Quests.get(id)
	end
	return (Quests.All or Quests)[id]
end

---------------------------------------------------------------------
print("1. Las escenas existen, están registradas y validan")
---------------------------------------------------------------------
local ctx = {
	Fx = Catalog.names(),
	SkyMoods = SkyMoods.names(),
	Moods = ActorMoods.names(),
	Creatures = StoryCreatures.names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
}
check(table.find(HappeningIndex.Groups, "Universidad") ~= nil, "el grupo Universidad está en HappeningIndex")
for id in SCENES do
	local def = Group[id]
	check(def ~= nil, ("la escena %s existe"):format(id))
	if def then
		check(HappeningIndex.get(id) == def, ("%s se encuentra con HappeningIndex.get"):format(id))
		local errors = Sequencer.validate(id, def, ctx)
		for _, e in errors do
			print("     " .. e)
		end
		check(#errors == 0, ("%s valida sin errores"):format(id))
		check(def.Skippable ~= false, ("%s se puede saltar"):format(id))
	end
end
for id in Group do
	check(SCENES[id] ~= nil, ("la escena %s está en la lista de la prueba"):format(id))
end

---------------------------------------------------------------------
print("2. Regla de oro: las cinco preguntas encima de cada escena")
---------------------------------------------------------------------
for id in SCENES do
	local at = source:find("\n\t" .. id .. " = {", 1, true)
	local before = if at then source:sub(math.max(1, at - 2400), at) else ""
	-- El bloque de comentario entre las dos líneas de guiones de encima de la escena
	local lines = before:split("\n")
	local block, seps = {}, 0
	for i = #lines, 1, -1 do
		local line = lines[i]
		if line:match("^%s*%-%-%-%-%-%-%-%-%-%-+%s*$") then
			seps += 1
			if seps == 2 then
				break
			end
		elseif seps == 1 then
			table.insert(block, 1, line)
		end
	end
	block = table.concat(block, "\n")
	local ok = true
	for _, q in { "¿Qué pasa?", "¿Por qué?", "¿Qué siente", "¿Qué ve el jugador?", "¿Qué quiero que sienta?" } do
		if not block:find(q, 1, true) then
			ok = false
			print(("     %s: falta «%s»"):format(id, q))
		end
	end
	check(ok, ("%s responde a las cinco preguntas"):format(id))
end

---------------------------------------------------------------------
print("3. Las misiones lanzan las escenas y conservan sus pasos")
---------------------------------------------------------------------
local function eachStep(steps: any, fn: (any) -> ())
	for _, step in steps or {} do
		fn(step)
		if step.Type == "Group" then
			eachStep(step.Steps, fn)
		end
	end
end
for id, info in SCENES do
	local quest = questById(info.Quest)
	check(quest ~= nil, ("la misión %s existe"):format(info.Quest))
	local found = false
	eachStep(quest and quest.Steps, function(step)
		if (step.Type == "Cinematic" and step.Id == id) or step.Cinematic == id then
			found = true
		end
	end)
	check(found, ("%s la lanza %s"):format(id, info.Quest))
end
for questId, n in STEP_COUNT do
	local quest = questById(questId)
	check(quest and #quest.Steps == n, ("%s sigue teniendo %d pasos (tiene %s)"):format(questId, n, tostring(quest and #quest.Steps)))
end
-- Las escenas con decisiones siguen en conversaciones (DialogueService); la escena de cine no pregunta
for id, def in Group do
	for _, line in (def.Tracks or {}).Dialogue or {} do
		check(line.Ask == nil, ("%s: sin preguntas dentro de la escena"):format(id))
	end
end

---------------------------------------------------------------------
print("4. Variantes: cada partida ve lo suyo")
---------------------------------------------------------------------
-- Una partida de mentira: marcas, decisiones, recuerdos y objetos (lo que mira Conditions + Items)
local function save(spec: { [string]: any }): (req: { [string]: any }) -> boolean
	local flags, choices, memories, items = {}, {}, {}, {}
	for _, f in spec.Flags or {} do
		flags[f] = true
	end
	for k, v in spec.Choices or {} do
		choices[k] = { V = v }
	end
	for _, m in spec.Memories or {} do
		memories[m] = { D = 1 }
	end
	for k, v in spec.Items or {} do
		items[k] = v
	end
	return function(req)
		for k, v in req do
			if k == "Items" then
				for item, n in v do
					if (items[item] or 0) < n then
						return false
					end
				end
			elseif k == "Late" then
				if (spec.Late == true) ~= v then
					return false
				end
			end
		end
		local rest = table.clone(req)
		rest.Items, rest.Late = nil, nil
		if next(rest) == nil then
			return true
		end
		return Conditions.check(rest, {
			Stage = "AdultoJoven",
			Flags = flags,
			Choices = choices,
			Memories = memories,
			Completed = {},
			Rel = {},
			Traits = {},
		})
	end
end

-- Lo que se ve de una escena con una partida: (frases, duración, variante)
local function play(id: string, spec: { [string]: any }): ({ any }, number, string?)
	local def = Group[id]
	local choice = Sequencer.resolve(def, save(spec))
	local timeline = Sequencer.compile(id, def, choice)
	local lines = {}
	for _, e in timeline.Events do
		if e.Track == "Dialogue" then
			table.insert(lines, e.Data)
		end
	end
	local variant = choice.Variant and def.Variants[choice.Variant]
	return lines, timeline.Duration, variant and variant.Name or nil
end
local function says(lines: { any }, who: string, piece: string): boolean
	for _, line in lines do
		if line.S == who and line.T:find(piece, 1, true) then
			return true
		end
	end
	return false
end
-- Ninguna frase se pisa con la anterior (las que tienen At fijo van detrás de las variables)
local function noOverlap(id: string, lines: { any }, label: string)
	local ok = true
	for i = 2, #lines do
		local a, b = lines[i - 1], lines[i]
		if not b.Alt and b.At + 0.01 < a.At + a.Duration then
			ok = false
			print(("     %s (%s): «%s» empieza en %.1f y «%s» acaba en %.1f"):format(id, label, b.T:sub(1, 30), b.At, a.T:sub(1, 30), a.At + a.Duration))
		end
	end
	check(ok, ("%s (%s): las frases no se pisan"):format(id, label))
end
local function dump(id: string, label: string, lines: { any }, duration: number)
	if not SHOW then
		return
	end
	print(("   ── %s · %s · %.1f s"):format(id, label, duration))
	for _, l in lines do
		print(("      %5.1f–%5.1f  %-9s %s"):format(l.At, l.At + l.Duration, l.S, l.T))
	end
end

local PARTIDAS = {
	Nueva = {},
	Completa = {
		Flags = {
			"ConocesALeire", "AyudasteAMateo", "HugoConElGrupo", "TorneoGanado", "SabeCocinar", "TitoDescubierto",
			"EquipoUnido", "LlegasTardeReunion", "ReyDeLaPista", "TienePareja", "OfertaTrabajo", "TFGRaro",
		},
		Choices = {
			Estudios = "Ingenieria", ComidaUni = "Luca", Cita = "Carla", ErrorInforme = "Decir", CompiPiso = "Sara",
			Convivencia = "Llamar", LookGraduacion = "Dinosaurios", AdiosBruno = "DeCero", TemaTFG = "Raro",
		},
		Memories = { "PrimerDiaCole", "PrimerAmigo", "MochilaPerdida", "MisterioColegio", "ElFestival", "CasiSuspendo", "ElRumor", "PrimerSueldo", "ZumoDeMora", "PrimerPiso", "MetroPrimerDia" },
		Items = { RelojAbu = 1 },
	},
	Distinta = {
		Flags = { "HacesTodo", "AmistadEspecial", "TorneoPerdido", "LlegasTardeReunion" },
		Choices = { Estudios = "Derecho", ComidaUni = "Sola", Cita = "Adrian", ErrorInforme = "Silencio", CompiPiso = "Resi", Convivencia = "Hacerlo", LookGraduacion = "Elegante", TemaTFG = "Valmar" },
		Memories = { "PrimerDiaCole" },
	},
}

for id in SCENES do
	for label, spec in PARTIDAS do
		local lines, duration = play(id, spec)
		dump(id, label, lines, duration)
		check(#lines >= 2, ("%s (%s): tiene diálogo"):format(id, label))
		check(duration > 8 and duration < 150, ("%s (%s): dura %.0f s (entre 8 y 150)"):format(id, label, duration))
		noOverlap(id, lines, label)
	end
end

-- Lo que debe salir en cada partida
do
	local nueva = play("Uni06_Brindis", PARTIDAS.Nueva)
	local completa = play("Uni06_Brindis", PARTIDAS.Completa)
	local distinta = play("Uni06_Brindis", PARTIDAS.Distinta)
	check(#completa > #nueva + 10, "el brindis de una vida completa tiene muchos más recuerdos que el de una partida vacía")
	check(says(completa, "Carla", "primera vez que llegué a tiempo"), "brindis: Carla recuerda la cita (TienePareja + Cita = Carla)")
	check(not says(completa, "Julia", "dos helados"), "brindis: Julia no habla de una cita que no fue con ella")
	check(says(distinta, "Adrian", "algo bonito"), "brindis: Adrián recuerda la amistad (AmistadEspecial + Cita = Adrian)")
	check(not says(completa, "Carla", "más tarde que yo"), "brindis: si Carla fue tu cita, recuerda la cita y no lo de llegar tarde")
	local porPersona = {}
	for _, line in completa do
		porPersona[line.S] = (porPersona[line.S] or 0) + 1
	end
	for who, n in porPersona do
		check(n <= (if who == "Omar" then 3 elseif who == "Lola" then 2 else 1), ("brindis: %s dice un solo recuerdo (%d frases)"):format(who, n))
	end
	check(says(completa, "Ivan", "tortilla"), "brindis: Iván recuerda la tortilla (SabeCocinar)")
	check(says(completa, "Candela", "no existía"), "brindis: Candela recuerda a Tito (TitoDescubierto)")
	check(says(nueva, "Candela", "ochenta y siete"), "brindis: sin Tito, Candela recuerda el horario de limpieza")
	check(says(distinta, "Julia", "casi sin ayuda"), "brindis: Julia recuerda que lo hiciste todo (HacesTodo)")
	check(says(distinta, "Carla", "más tarde que yo"), "brindis: Carla recuerda que llegaste tarde (LlegasTardeReunion)")
	check(says(completa, "Abu", "planta"), "brindis: {abu} recuerda la planta del primer piso (PrimerPiso)")
	check(says(nueva, "Abu", "naciste"), "brindis: {abu} siempre cierra con el día que naciste")
end
do
	local con = play("Uni05_Visita", PARTIDAS.Completa)
	local sin = play("Uni05_Visita", PARTIDAS.Distinta)
	check(says(con, "Abu", "Lo llevas"), "visita: con el reloj (objeto RelojAbu), {abu} lo ve")
	check(says(sin, "Yo", "No lo llevo") and says(sin, "Abu", "se pierden"), "visita: sin el reloj, {abu} lo nota")
	check(not says(con, "Abu", "se pierden"), "visita: una sola de las dos frases del reloj")
	check(says(con, "Sara", "cuadrante"), "visita: vives con Sara y sale a saludar (CompiPiso)")
	check(says(sin, "Candela", "etiquetada"), "visita: vives con Iván y Candela (CompiPiso = Resi)")
	check(says(con, "Abu", "tortilla"), "visita: {abu} sabe lo de la tortilla (SabeCocinar)")
	check(says(con, "Abu", "llamaste"), "visita: {abu} sabe que llamaste a casa (Convivencia = Llamar)")
end
do
	for _, npc in { "Julia", "Adrian", "Luca", "Carla" } do
		local lines, _, variant = play("UniS_Cita_Invitacion", { Choices = { Cita = npc } })
		check(variant == npc, ("cita: invitas a %s → su variante"):format(npc))
		local own = false
		for _, line in lines do
			if line.S == npc then
				own = true
			end
		end
		check(own, ("cita: %s está y contesta en persona"):format(npc))
		local def = Group.UniS_Cita_Invitacion
		local merged = Sequencer.merge(def, table.find({ "Julia", "Adrian", "Luca", "Carla" }, npc))
		check(Sequencer.actorKeys(merged)[npc] ~= nil, ("cita: %s es un actor de la escena"):format(npc))
	end
end
do
	local tarde = play("Uni02_Reunion", PARTIDAS.Completa)
	local puntual = play("Uni02_Reunion", PARTIDAS.Nueva)
	check(says(tarde, "Adrian", "tampoco has llegado puntual"), "reunión: si llegaste tarde, Adrián te lo apunta (LlegasTardeReunion)")
	check(not says(puntual, "Adrian", "tampoco has llegado puntual"), "reunión: si llegaste a tiempo, no")
end
do
	local a = play("Uni06_Ceremonia", PARTIDAS.Completa)
	local b = play("Uni06_Ceremonia", PARTIDAS.Distinta)
	check(says(a, "Beltran", "valor de confesar"), "ceremonia: Beltrán habla del error confesado (ErrorInforme = Decir)")
	check(says(b, "Beltran", "los que no"), "ceremonia: si lo callaste, Beltrán lo dice de otra manera")
	check(says(a, "Beltran", "un equipo"), "ceremonia: el grupo que se hizo equipo (EquipoUnido)")
	check(says(b, "Beltran", "una persona por cinco"), "ceremonia: el grupo que llevaste tú (HacesTodo)")
	check(says(a, "Beltran", "trabajo esperando"), "ceremonia: la oferta de las prácticas (OfertaTrabajo)")
	check(says(a, "Beltran", "gallina"), "ceremonia: el TFG raro (TFGRaro)")
	check(says(b, "Beltran", "Valmar"), "ceremonia: el TFG sobre Valmar (TemaTFG)")
	check(says(a, "Abu", "dinosaurios"), "ceremonia: la sudadera de dinosaurios (LookGraduacion)")
end
do
	local a = play("Uni06_Final", PARTIDAS.Completa)
	local b = play("Uni06_Final", PARTIDAS.Nueva)
	check(says(a, "Yo", "once y diez"), "final: con el reloj, miras la hora")
	check(says(b, "Yo", "No llevo reloj"), "final: sin el reloj, no")
	local narr = 0
	for _, line in a do
		if line.S == "Narrador" then
			narr += 1
		end
	end
	check(narr < #a / 2, "final: ya no es solo narrador")
end
do
	local a = play("Uni01_Mensajes", PARTIDAS.Completa)
	local b = play("Uni01_Mensajes", PARTIDAS.Distinta)
	check(says(a, "Luca", "dos menos cinco"), "mensajes: comiste con Luca y te escribe (ComidaUni)")
	check(says(b, "Yo", "a mi aire"), "mensajes: comiste a tu aire y lo cuentas (ComidaUni = Sola)")
	check(says(a, "Leire", "cine") and not says(b, "Leire", "cine"), "mensajes: Leire solo si la conoces")
end

---------------------------------------------------------------------
print("5. Continuidad: lo que leen las escenas existe y se escribe antes")
---------------------------------------------------------------------
local READS = {
	Flags = {
		"LlegasTardeReunion", "SabeCocinar", "TitoDescubierto", "TienePareja", "AmistadEspecial", "EquipoUnido",
		"HacesTodo", "OfertaTrabajo", "TFGRaro", "ReyDeLaPista", "ConocesALeire", "AyudasteAMateo",
	},
	Choices = { "ComidaUni", "Cita", "ErrorInforme", "CompiPiso", "Convivencia", "LookGraduacion", "TemaTFG", "AdiosBruno" },
	Memories = { "ZumoDeMora", "PrimerPiso", "MetroPrimerDia", "MochilaPerdida", "PrimerDiaCole" },
	Items = { "RelojAbu" },
}
-- Lo que leen las escenas (todas sus condiciones, en todas las variantes)
local read = { Flags = {}, Choices = {}, Memories = {}, Items = {} }
local function collect(req: any)
	if type(req) ~= "table" then
		return
	end
	for _, f in req.Flags or {} do
		read.Flags[f] = true
	end
	for _, f in req.NotFlags or {} do
		read.Flags[f] = true
	end
	for k in req.Choices or {} do
		read.Choices[k] = true
	end
	for k in req.NotChoices or {} do
		read.Choices[k] = true
	end
	for _, m in req.Memories or {} do
		read.Memories[m] = true
	end
	for k in req.Items or {} do
		read.Items[k] = true
	end
end
local function scanTracks(tracks: any)
	for _, list in tracks or {} do
		for _, d in list do
			if type(d) == "table" then
				collect(d.If)
				collect(d.IfNot)
			end
		end
	end
end
for _, def in Group do
	scanTracks(def.Tracks)
	for _, v in def.Variants or {} do
		collect(v.If)
		scanTracks(v.Tracks)
	end
end
for kind, list in READS do
	for _, name in list do
		check(read[kind][name] == true, ("las escenas leen %s %s"):format(kind, name))
	end
end
-- Y alguien lo escribe (en los datos de alguna misión)
local everything = ""
for _, path in fs.readDir("src/shared/LifeStory/Misiones") do
	everything ..= fs.readFile("src/shared/LifeStory/Misiones/" .. path)
end
for _, name in READS.Flags do
	check(everything:find('"' .. name .. '"', 1, true) ~= nil, ("alguna misión escribe la marca %s"):format(name))
end
for _, name in READS.Choices do
	check(everything:find("Key = \"" .. name .. "\"", 1, true) ~= nil or everything:find(name .. " = \"", 1, true) ~= nil, ("alguna misión decide %s"):format(name))
end
for _, name in READS.Memories do
	check(everything:find('Memory = "' .. name .. '"', 1, true) ~= nil, ("alguna misión deja el recuerdo %s"):format(name))
end
check(everything:find("RelojAbu = 1", 1, true) ~= nil, "Uni01 da el reloj (RelojAbu)")

---------------------------------------------------------------------
print("6. Quien habla está en la escena")
---------------------------------------------------------------------
-- Conversaciones de las misiones Uni: quien habla tiene que estar en los actores del paso (o ser con
-- quien hablas en un Talk). Las misiones no repiten actores entre pasos: se mira solo el paso.
local function actorSet(step: any): { [string]: boolean }
	local set = {}
	for _, a in step.Actors or {} do
		set[a.Npc] = true
	end
	if step.Npc then
		set[step.Npc] = true
	end
	return set
end
local function speakersOf(lines: any, out: { [string]: boolean })
	for _, line in lines or {} do
		if type(line) == "table" then
			if line.S and line.S ~= "Narrador" and line.S ~= "Yo" then
				out[line.S] = true
			end
			for _, option in line.Options or {} do
				speakersOf(option.Then, out)
			end
		end
	end
end
local UNI = { "Uni01_PrimerDia", "Uni01b_Residencia", "Uni02_ElProyecto", "Uni03_PrimerTrabajo", "Uni04_Practicas", "Uni05_PrimerPiso", "Uni06_Graduacion", "UniEx1_Enero", "UniEx2_Junio", "UniEx3_Parcial", "UniEx4_TFG", "UniS_Cita" }
for _, questId in UNI do
	local quest = questById(questId)
	local missing = {}
	for index, step in quest.Steps do
		if step.Type == "Scene" and step.Dialogue and quest.Dialogues[step.Dialogue] then
			local spk = {}
			speakersOf(quest.Dialogues[step.Dialogue].Lines, spk)
			local here = actorSet(step)
			for s in spk do
				if not here[s] then
					table.insert(missing, ("#%d %s: %s"):format(index, step.Dialogue, s))
				end
			end
		end
	end
	for _, m in missing do
		print("     " .. questId .. " " .. m)
	end
	check(#missing == 0, ("%s: en sus conversaciones solo habla quien está"):format(questId))
end
-- En las escenas: quien habla es un actor de la escena (o el narrador, tú, o un mensaje 📱)
for id, def in Group do
	local away = {}
	local function look(tracks: any, label: string)
		local keys = Sequencer.actorKeys({ Tracks = tracks })
		for _, line in tracks.Dialogue or {} do
			local s = line.S
			local phone = line.T:find("📱", 1, true) ~= nil
			if not (s == "Narrador" or s == "Yo" or phone or keys[s] ~= nil) then
				table.insert(away, ("%s (%s)"):format(s, label))
			end
		end
	end
	look(def.Tracks, "base")
	for i, v in def.Variants or {} do
		look(Sequencer.merge(def, i).Tracks, v.Name or tostring(i))
	end
	if #away > 0 then
		print("     " .. id .. ": " .. table.concat(away, ", "))
	end
	check(#away == 0, ("%s: quien habla es un actor de la escena (o un mensaje 📱)"):format(id))
end

---------------------------------------------------------------------
print("7. Escritura: sin dobletes de género ni acotaciones en las escenas")
---------------------------------------------------------------------
local DOUBLETS = { "solo o sola", "sola o solo", "nervioso o nerviosa", "helado o helada", "pequeño o pequeña", "guapísimo o guapísima", "contratado o contratada", "adulto o adulta", "bienvenida, bienvenido", "bienvenido o bienvenida", "el o la ", "ESE O ESA", "compañero o compañera", "chaval o chavala", "tranquilo o tranquila", "listo o lista" }
for _, file in { "Uni01_PrimerDia", "Uni02_ElProyecto", "Uni03_PrimerTrabajo", "Uni04_Practicas", "Uni05_PrimerPiso", "Uni06_Graduacion", "Uni_Vida", "Uni_Secundarias", "Uni_Consecuencias", "Loco_Uni" } do
	local text = fs.readFile("src/shared/LifeStory/Misiones/" .. file .. ".luau"):lower()
	local found = {}
	for _, d in DOUBLETS do
		if text:find(d:lower(), 1, true) then
			table.insert(found, d)
		end
	end
	if #found > 0 then
		print("     " .. file .. ": " .. table.concat(found, ", "))
	end
	check(#found == 0, ("%s: sin dobletes de género"):format(file))
end
for id, def in Group do
	local bad = {}
	local function scan(tracks: any)
		for _, line in tracks.Dialogue or {} do
			if line.T:match("^%(") then
				table.insert(bad, line.T)
			end
		end
	end
	scan(def.Tracks)
	for i in def.Variants or {} do
		scan(Sequencer.merge(def, i).Tracks)
	end
	check(#bad == 0, ("%s: sin acotaciones escritas (la acción la hace el actor)"):format(id))
end

L.finish("test-universidad")
