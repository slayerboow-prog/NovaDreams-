-- Prueba de las escenas de la INFANCIA (paquete P8a: el bebé y el colegio), sin arrancar el juego.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-colegio.luau
--
-- Comprueba:
--   1. El grupo «Colegio» está en HappeningIndex y trae todas sus escenas; cada una pasa la validación del
--      motor, se puede saltar, tiene sonido ambiente y empieza con las cinco preguntas de la regla de oro.
--   2. Variantes: con distintas partidas (llegar tarde, el nombre del grupo, la nota, ganar o perder, lo
--      que metiste en la cápsula…) cada escena resuelve lo que toca, y las frases que quedan no se pisan.
--   3. Nadie aparece si no toca: los Use de quien depende de una decisión llevan su If; los que no, están
--      en el reparto del paso de la misión que lanza la escena.
--   4. Las misiones lanzan las escenas (paso Cinematic) y los saltos de las misiones del colegio llevan
--      fundido; no quedan acotaciones escritas de acción (las de voz o distancia, sí: las hace StageDirector).
--   5. Continuidad: las marcas, decisiones y recuerdos de la infancia se leen en alguna frase.
--   6. El validador de misiones no da errores en las misiones del paquete.

local fs = require("@lune/fs")
local process = require("@lune/process")
local H = require("./lib/StoryHarness")
local ROOT, loadModule = H.ROOT, H.loadModule

local failures = 0
local function check(ok: any, label: string)
	if ok then
		print("  ✅ " .. label)
	else
		failures += 1
		print("  ❌ " .. label)
	end
end

local HappeningIndex = loadModule(ROOT .. "/shared/LifeStory/HappeningIndex")
local Sequencer = loadModule(ROOT .. "/shared/LifeStory/Sequencer")
local Conditions = loadModule(ROOT .. "/shared/LifeStory/Conditions")
local Quests = loadModule(ROOT .. "/shared/LifeStory/Quests")
local Locations = loadModule(ROOT .. "/shared/LifeStory/Locations")
local Cast = loadModule(ROOT .. "/shared/LifeStory/Cast")
local ActorMoods = loadModule(ROOT .. "/shared/LifeStory/ActorMoods")
local StoryCreatures = loadModule(ROOT .. "/shared/LifeStory/StoryCreatures")
local Catalog = loadModule(ROOT .. "/shared/StoryFxCatalog")
local SkyMoods = loadModule(ROOT .. "/shared/SkyMoods")

local SCENES = {
	"Bebe_NacimientoCuna",
	"Bebe_PrimerosPasosAbu",
	"Bebe_VentanalFamilia",
	"Cole01_Bienvenida",
	"Cole01_LibrosCaen",
	"Cole04_LosVes",
	"Cole06_LaNota",
	"Cole08_Final",
	"Cole08_Medallas",
	"Cole09_LaFoto",
	"Cole12_Capsula",
	"Cole12_FotoClase",
	"Cole12_Despedida",
	"Cole12_FinDeEpisodio",
}
-- Qué misión lanza cada escena del colegio (las del bebé las lanzan Quests/Chapters/BabyService)
local LAUNCHED_BY = {
	Cole01_Bienvenida = "Cole01_PrimerDia",
	Cole01_LibrosCaen = "Cole01_PrimerDia",
	Cole04_LosVes = "Cole04_Malotes",
	Cole06_LaNota = "Cole06_Examen",
	Cole08_Final = "Cole08_Torneo",
	Cole08_Medallas = "Cole08_Torneo",
	Cole09_LaFoto = "Cole09_Misterio",
	Cole12_Capsula = "Cole12_UltimoDia",
	Cole12_FotoClase = "Cole12_UltimoDia",
	Cole12_Despedida = "Cole12_UltimoDia",
	Cole12_FinDeEpisodio = "Cole12_UltimoDia",
}
local MISSIONS = {
	"Cole01_PrimerDia", "Cole02_Mochila", "Cole03_Grupo", "Cole04_Malotes", "Cole05_Venganza", "Cole06_Examen",
	"Cole07_Excursion", "Cole08_Torneo", "Cole09_Misterio", "Cole10_Festival", "Cole11_Proyecto", "Cole12_UltimoDia",
	"Eco_MateoDibujo", "Eco_MateoSolo", "Eco_Ruben", "Side_GatoDelCole", "Eco_Hugo", "Cole06b_Recuperacion", "Eco_Periodico",
	"Prologo_Sueno",
}

---------------------------------------------------------------------
print("1. Escenas registradas, válidas y con la regla de oro")
---------------------------------------------------------------------
check(table.find(HappeningIndex.Groups, "Colegio") ~= nil, "el grupo Colegio está en HappeningIndex")
local source = fs.readFile(ROOT .. "/shared/LifeStory/Happenings/Colegio.luau")
local ctx = {
	Fx = Catalog.names(),
	SkyMoods = SkyMoods.names(),
	Moods = ActorMoods.names(),
	Creatures = StoryCreatures.names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
}
for _, id in SCENES do
	local def = HappeningIndex.get(id)
	check(def ~= nil and HappeningIndex.groupOf(id) == "Colegio", id .. " existe (grupo Colegio)")
	if not def then
		continue
	end
	local problems = Sequencer.validate(id, def, ctx)
	for _, p in problems do
		print("     " .. p)
	end
	check(#problems == 0, id .. ": pasa la validación del motor")
	check(def.Skippable == true, id .. ": se puede saltar")
	check(type(def.Tracks.Ambience) == "table" and #def.Tracks.Ambience > 0, id .. ": tiene sonido ambiente (nunca silencio)")
	check(type(def.Tracks.Camera) == "table" and #def.Tracks.Camera > 0, id .. ": tiene cámara (plano de situación)")
	-- Las cinco preguntas, en el comentario justo encima de la escena
	local at = source:find("\n\t" .. id .. " = {", 1, true)
	-- (el bloque de comentario entre la escena anterior y esta)
	local block = if at then source:sub(math.max(1, at - 900), at) else ""
	local previous = block:match(".*\n\t},\n(.*)$")
	block = previous or block
	local golden = block:find("¿Qué pasa?", 1, true) and block:find("¿Por qué?", 1, true) and block:find("¿Qué siente", 1, true)
		and block:find("¿Qué ve el jugador?", 1, true) and block:find("¿Qué quiero que sienta?", 1, true)
	check(golden, id .. ": responde a las cinco preguntas de la regla de oro")
end

---------------------------------------------------------------------
print("2. Variantes: cada partida ve lo suyo y las frases no se pisan")
---------------------------------------------------------------------
local function profile(p: { [string]: any }): { [string]: any }
	local choices = {}
	for k, v in p.Choices or {} do
		choices[k] = { V = v }
	end
	local flags, memories = {}, {}
	for _, f in p.Flags or {} do
		flags[f] = true
	end
	for _, m in p.Memories or {} do
		memories[m] = { D = 1 }
	end
	return {
		Stage = "Nino",
		ClockTime = 10,
		Weekday = 2,
		Completed = {},
		Flags = flags,
		Choices = choices,
		Discovered = {},
		Rel = p.Rel or {},
		Traits = p.Traits or {},
		Memories = memories,
		LastGrade = p.LastGrade,
	}
end
local function play(id: string, p: { [string]: any }): ({ any }, { [string]: any })
	local def = HappeningIndex.get(id)
	local c = profile(p)
	local opts = Sequencer.resolve(def, function(req)
		return (Conditions.check(req, c))
	end)
	local out = Sequencer.expand(def, opts)
	return out.Tracks.Dialogue or {}, out
end
local function said(lines: { any }, text: string): boolean
	for _, line in lines do
		if type(line.T) == "string" and line.T:find(text, 1, true) then
			return true
		end
	end
	return false
end
local function overlaps(lines: { any }): string?
	local prevEnd, prevText = -1, ""
	for _, line in lines do
		if line.At + 0.01 < prevEnd then
			return ("«%s» empieza antes de que acabe «%s»"):format(line.T:sub(1, 30), prevText:sub(1, 30))
		end
		prevEnd = line.At + line.Duration
		prevText = line.T
	end
	return nil
end

-- Partidas de prueba (las combinaciones que más cambian las escenas)
local PARTIDAS = {
	{ Name = "nueva, sin nada", Flags = {}, Choices = {} },
	{
		Name = "puntual, ayuda a todos, gana",
		Flags = { "PaseADani", "LlevaCromo", "AyudasteAMateo", "HugoConElGrupo", "IkerEnElGrupo", "ObjetoCromo", "Ruben_Perdonado", "TorneoGanado", "BuenEntreno", "EstudiasteMas" },
		Choices = { NombreGrupo = "La Patrulla Valmar", Deporte = "Futbol", Posicion = "Portero", Capitan = "Yo", Estrategia = "Todos", PreFinal = "Deportivo", TrasFinal = "Mano", CompaneroEstudio = "Mateo", Capsula = "Carta", Promesa = "Banco", Entrar = "Permiso" },
		Memories = { "SuenoGrieta", "PrimerAmigo", "PrimerGrupo" },
		Traits = { Deportividad = 6 },
		LastGrade = 9.5,
	},
	{
		Name = "tarde, rival de Rubén, pierde",
		Flags = { "LlegasTarde", "Ruben_Rival", "TorneoPerdido" },
		Choices = { NombreGrupo = "Los Dinosaurios", Deporte = "Atletismo", Capitan = "Otro", Estrategia = "Ataque", PreFinal = "Nada", TrasFinal = "Rincon", CompaneroEstudio = "Solo", Capsula = "Prediccion", Promesa = "Juntos", Entrar = "Colarse" },
		Memories = { "SegundaOportunidad" },
		LastGrade = 6,
	},
	{
		Name = "baloncesto, Omar de capitán",
		Flags = { "TorneoGanado" },
		Choices = { NombreGrupo = "Los Imparables", Deporte = "Baloncesto", Capitan = "Omar", Estrategia = "Paciencia", PreFinal = "Reto", TrasFinal = "Equipo", CompaneroEstudio = "Sara", Capsula = "Pregunta", Promesa = "Nuevos" },
		LastGrade = 7,
	},
}
local allFine = true
for _, partida in PARTIDAS do
	for _, id in SCENES do
		local lines = play(id, partida)
		local bad = overlaps(lines)
		if bad then
			allFine = false
			print(("     %s (%s): %s"):format(id, partida.Name, bad))
		end
	end
end
check(allFine, "en ninguna partida se pisan dos frases de una escena")

local P = PARTIDAS
do
	local lines = play("Cole01_Bienvenida", P[3])
	check(said(lines, "Un poquito tarde"), "Bienvenida: si llegaste tarde, Lucía lo dice")
	check(not said(play("Cole01_Bienvenida", P[2]), "Un poquito tarde"), "Bienvenida: si llegaste a tiempo, no")
	check(said(play("Cole01_LibrosCaen", P[2]), "hermano de Dani"), "Libros de Mateo: si le pasaste el balón a Dani, le reconoces")
	check(said(play("Cole04_LosVes", P[2]), "portero legendario") and said(play("Cole04_LosVes", P[3]), "foto del grupito"), "Los ves: Bruno tiene tu cromo o tu foto, según lo que llevabas")
	check(said(play("Cole04_LosVes", P[3]), "mochila") and said(play("Cole04_LosVes", P[2]), "Devuélveselo"), "Los ves: Rubén se acuerda de lo de la mochila (rival o perdonado)")
	check(said(play("Cole06_LaNota", P[2]), "sobresaliente") and said(play("Cole06_LaNota", P[3]), "Aprobado"), "La nota: sobresaliente o aprobado según la nota del examen")
	check(said(play("Cole06_LaNota", P[2]), "aprobado yo también") and said(play("Cole06_LaNota", P[4]), "veinte minutos"), "La nota: habla quien estudió contigo")
	check(said(play("Cole08_Final", P[2]), "¡Por La Patrulla Valmar!") and not said(play("Cole08_Final", P[2]), "Imparables"), "La final: el grito lleva el nombre del grupo (y solo ese)")
	check(said(play("Cole08_Final", P[2]), "portería") and said(play("Cole08_Final", P[2]), "Unas palabras"), "La final: tu puesto (misión 03) y tu capitanía")
	check(said(play("Cole08_Final", P[4]), "Soy el capitán") and said(play("Cole08_Final", P[4]), "Paciencia"), "La final: Omar capitán y el plan de la paciencia")
	check(said(play("Cole08_Final", P[3]), "contestar") and said(play("Cole08_Final", P[4]), "Ya veremos en el campo"), "La final: Bruno recuerda lo que le dijiste antes")
	check(said(play("Cole08_Medallas", P[2]), "el oro") and said(play("Cole08_Medallas", P[3]), "Plata"), "Medallas: oro o plata")
	check(said(play("Cole08_Medallas", P[2]), "darme la mano") and said(play("Cole08_Medallas", P[2]), "deportividad"), "Medallas: la mano a Bruno y el premio a la deportividad")
	check(said(play("Cole09_LaFoto", P[2]), "Dato curioso"), "La foto: Iker habla si está en el grupo")
	check(said(play("Cole12_Capsula", P[2]), "yo del último día") and said(play("Cole12_Capsula", P[3]), "Nico será futbolista"), "Cápsula: Lucía lee lo que metiste (carta, predicción…)")
	check(said(play("Cole12_Capsula", P[4]), "Los Imparables. Desde aquel banco"), "Cápsula: Nico dice el nombre del grupo")
	check(said(play("Cole12_Despedida", P[2]), "se me cayeron los libros") and said(play("Cole12_Despedida", P[3]), "comedor"), "Despedida: Mateo recuerda el primer día (o el comedor)")
	check(said(play("Cole12_Despedida", P[2]), "banco del parque") and said(play("Cole12_Despedida", P[3]), "puré"), "Despedida: la promesa que hicisteis")
	check(said(play("Cole12_FinDeEpisodio", P[3]), "¡LOS DINOSAURIOS!"), "Fin de episodio: el grito del grupo con su nombre")
	check(said(play("Bebe_NacimientoCuna", P[2]), "soñado") and not said(play("Bebe_NacimientoCuna", P[1]), "soñado"), "Nacimiento: Abu nota el sueño (si jugaste el prólogo)")
	-- Nadie de más: sin fútbol, Nico no sale en la final
	local _, out = play("Cole08_Final", P[3])
	local nico = false
	for _, d in out.Tracks.Actors do
		if d.Use and d.Use.Key == "Nico" then
			nico = true
		end
	end
	check(not nico, "La final: sin fútbol, Nico no aparece (su Use lleva If)")
end

---------------------------------------------------------------------
print("3. Los actores de cada escena están en el paso que la lanza")
---------------------------------------------------------------------
local stepsWith: { [string]: { any } } = {}
for mission in pairs(LAUNCHED_BY) do
	stepsWith[mission] = {}
end
for _, mid in { "Cole01_PrimerDia", "Cole04_Malotes", "Cole06_Examen", "Cole08_Torneo", "Cole09_Misterio", "Cole12_UltimoDia" } do
	for index, step in Quests[mid].Steps do
		if step.Type == "Cinematic" and HappeningIndex.groupOf(step.Id) == "Colegio" then
			table.insert(stepsWith[step.Id], { Mission = mid, Index = index, Step = step })
		end
	end
end
for id, mid in LAUNCHED_BY do
	local list = stepsWith[id]
	check(#list > 0 and list[1].Mission == mid, ("%s la lanza %s (paso Cinematic)"):format(id, mid))
	for _, entry in list do
		local cast = {}
		for _, actor in entry.Step.Actors or {} do
			cast[actor.Npc] = true
		end
		local missing = {}
		for _, d in HappeningIndex.get(id).Tracks.Actors or {} do
			if d.Use and d.If == nil and not cast[d.Use.Npc or d.Use.Key] then
				table.insert(missing, d.Use.Key)
			end
		end
		check(#missing == 0, ("%s#%d: los que toma prestados la escena están en el paso%s"):format(entry.Mission, entry.Index, if #missing > 0 then " (faltan " .. table.concat(missing, ", ") .. ")" else ""))
	end
end
check(#stepsWith.Cole08_Final == 3, "La final se lanza en los tres deportes")

---------------------------------------------------------------------
print("4. Saltos con fundido y acotaciones convertidas en acción")
---------------------------------------------------------------------
local hardCuts, written = {}, {}
-- Acotaciones de VOZ o de distancia: StageDirector las hace (voz baja, teléfono, desde lejos, llanto)
local VOICE = { "^%(susurr", "^%(bajito", "^%(al teléfono", "^%(desde ", "^%(por detrás", "^%(llorando" }
local function voiceOnly(text: string): boolean
	for _, pattern in VOICE do
		if text:match(pattern) then
			return true
		end
	end
	return false
end
local function walkLines(where: string, list: { any }?)
	for _, line in list or {} do
		if type(line.T) == "string" and line.S ~= "Narrador" and line.T:match("^%(") and not voiceOnly(line.T) then
			table.insert(written, where .. ": " .. line.T:sub(1, 40))
		end
		for _, option in line.Options or {} do
			walkLines(where, option.Then)
		end
	end
end
for _, mid in MISSIONS do
	local quest = Quests[mid]
	check(quest ~= nil, mid .. " existe")
	if not quest then
		continue
	end
	for index, step in quest.Steps or {} do
		if step.Teleport and not (type(step.Teleport) == "table" and step.Teleport.Fade) then
			local prev = quest.Steps[index - 1]
			local covered = prev and (prev.Type == "Transition" or prev.Type == "Cinematic")
			if not covered then
				table.insert(hardCuts, ("%s#%d"):format(mid, index))
			end
		end
	end
	for name, dlg in quest.Dialogues or {} do
		walkLines(mid .. "." .. name, dlg.Lines)
	end
end
for _, cut in hardCuts do
	print("     salto seco: " .. cut)
end
check(#hardCuts == 0, "ningún salto del jugador sin fundido en la infancia")
for _, w in written do
	print("     acotación escrita: " .. w)
end
check(#written == 0, "no quedan acotaciones de acción escritas en el texto (las de voz o distancia sí: las hace StageDirector)")

---------------------------------------------------------------------
print("5. Continuidad: lo que hiciste se recuerda")
---------------------------------------------------------------------
local read: { [string]: boolean } = {}
local function readReq(req: any)
	if type(req) ~= "table" then
		return
	end
	for _, key in { "Flags", "NotFlags", "Memories", "NotMemories" } do
		for _, v in req[key] or {} do
			read[v] = true
		end
	end
	for _, key in { "Choices", "NotChoices" } do
		for k in req[key] or {} do
			read[k] = true
		end
	end
end
local function walk(value: any, depth: number)
	if type(value) ~= "table" or depth > 12 then
		return
	end
	readReq(value.If)
	readReq(value.IfNot)
	for _, child in value do
		walk(child, depth + 1)
	end
end
walk(HappeningIndex.all(), 0)
for _, mid in MISSIONS do
	walk(Quests[mid], 0)
end
local HOOKS = {
	-- marcas
	-- (PistaHugo y Estudiaste se siguen guardando, pero el guion reescrito de Cole04/Cole06 ya no las
	-- lee: docs/historia/reescritura/Cole04_Malotes.informe.md y Cole06_Examen.informe.md)
	"LlegasTarde", "EnsayoEspejo", "PaseADani", "LlevaCromo", "ObjetoCromo", "Ruben_Rival", "Ruben_Perdonado",
	"EstudiasteMas", "SuspendisteExamen", "BuenEntreno", "DejasteMochila", "TorneoGanado", "TorneoPerdido",
	-- decisiones
	"NombreGrupo", "Ropa", "Posicion", "Capitan", "Estrategia", "PreFinal", "TrasFinal", "CompaneroEstudio", "Capsula",
	"Promesa", "Talento", "Entrar",
	-- recuerdos
	"SuenoGrieta", "PrimerAmigo", "SegundaOportunidad", "PrimerGrupo", "CasiSuspendo", "PrimeraExcursion", "ProyectoFinal",
}
local unread = {}
for _, key in HOOKS do
	if not read[key] then
		table.insert(unread, key)
	end
end
check(#unread == 0, "se leen todas las marcas, decisiones y recuerdos de la lista" .. (if #unread > 0 then " (faltan " .. table.concat(unread, ", ") .. ")" else ""))
check(source:find("NombreGrupo", 1, true) ~= nil, "las escenas del motor dicen el nombre del grupo (Choices.NombreGrupo)")

---------------------------------------------------------------------
print("6. Validador de misiones")
---------------------------------------------------------------------
local report = loadModule(ROOT .. "/shared/LifeStory/Validate").report()
local mine = {}
for _, e in report.Errors do
	if e:find("Cole", 1, true) or e:find("Prologo", 1, true) or e:find("Bebe_", 1, true) or e:find("Eco_", 1, true) then
		table.insert(mine, e)
		print("     " .. e)
	end
end
check(#mine == 0, "sin errores en las misiones y escenas del paquete")
check(#report.Errors == 0, ("el validador no da errores (%d)"):format(#report.Errors))

print("")
if failures == 0 then
	print("✅ test-colegio: todo correcto")
else
	print(("❌ test-colegio: %d comprobaciones fallan"):format(failures))
end
process.exit(if failures == 0 then 0 else 1)
