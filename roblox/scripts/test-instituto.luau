-- Prueba del paquete P8b · ADOLESCENTE (lune run scripts/test-instituto.luau, desde roblox/).
--
-- 1. Las escenas del instituto (shared/LifeStory/Happenings/Instituto) existen, están en el índice
--    (HappeningIndex) y pasan el validador del motor (Sequencer.validate, con todo el contexto).
-- 2. Cada escena responde a las cinco preguntas de la regla de oro (comentario encima).
-- 3. Variantes y frases con condiciones: se resuelven con partidas distintas (lo que hiciste cambia lo
--    que se dice) y ningún tramo del diálogo se pisa con el siguiente ni se sale de la escena.
-- 4. Continuidad: las escenas y las misiones leen las marcas, recuerdos y decisiones de antes.
-- 5. Las misiones lanzan sus escenas (pasos Cinematic) y siguen pasando el validador.
-- 6. El día normal de instituto (Adol_Jornada) tiene sus propias frases, no las del colegio.

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

local Sequencer = L.load("src/shared/LifeStory/Sequencer")
local HappeningIndex = L.load("src/shared/LifeStory/HappeningIndex")
local Conditions = L.load("src/shared/LifeStory/Conditions")
local Locations = L.load("src/shared/LifeStory/Locations")
local Cast = L.load("src/shared/LifeStory/Cast")
local Config = L.load("src/shared/Config")
local Quests = L.load("src/shared/LifeStory/Quests")
local DayPlans = L.load("src/shared/LifeStory/DayPlans")
local SchoolLife = L.load("src/shared/LifeStory/SchoolLife")
local Validate = L.load("src/shared/LifeStory/Validate")

local SCENES = {
	"Ins01_Parada",
	"Ins03_Carmen",
	"Pan2_Alarma",
	"Pan3_Oferta",
	"Ins05_DiaDespues",
	"Ins06_Noche",
	"Ins06_Graduacion",
}
-- Qué paso de qué misión lanza cada escena
local LAUNCHED_BY = {
	Ins01_Parada = "Ins01_NuevoInstituto",
	Ins03_Carmen = "Ins03_QueQuieresSer",
	Pan2_Alarma = "Pan2_LaNoche",
	Pan3_Oferta = "Pan3_Cruce",
	Ins05_DiaDespues = "Ins05_ElRumor",
	Ins06_Noche = "Ins06_LaGranDecision",
	Ins06_Graduacion = "Ins06_LaGranDecision",
}

---------------------------------------------------------------------
print("1. Las escenas existen, están en el índice y pasan el validador")
---------------------------------------------------------------------
local ctx = {
	Fx = L.load("src/shared/StoryFxCatalog").names(),
	SkyMoods = L.load("src/shared/SkyMoods").names(),
	Moods = L.load("src/shared/LifeStory/ActorMoods").names(),
	Creatures = L.load("src/shared/LifeStory/StoryCreatures").names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
	Events = L.load("src/shared/LifeStory/EventCatalog").Names,
	Poses = L.load("src/shared/LifeStory/Emotion").Poses,
	Music = Config.Audio.Music,
}
check(table.find(HappeningIndex.Groups, "Instituto") ~= nil, "el grupo «Instituto» está en HappeningIndex")
local inGroup = 0
for id in HappeningIndex.all() do
	if HappeningIndex.groupOf(id) == "Instituto" then
		inGroup += 1
	end
end
check(inGroup == #SCENES, ("las %d escenas del grupo son las de esta prueba (hay %d)"):format(#SCENES, inGroup))
for _, id in SCENES do
	local def = HappeningIndex.get(id)
	check(def ~= nil and HappeningIndex.groupOf(id) == "Instituto", id .. " existe y es del instituto")
	if def then
		local errors = Sequencer.validate(id, def, ctx)
		for _, e in errors do
			print("     " .. e)
		end
		check(#errors == 0, id .. " pasa el validador del motor")
		check(def.Skippable == true, id .. " se puede saltar")
		check(def.Tracks.Ambience ~= nil and #def.Tracks.Ambience > 0, id .. " tiene sonido ambiente (nunca silencio)")
		local general = false
		for _, shot in def.Tracks.Camera or {} do
			general = general or (shot.At == 0 and type(shot.Shot) == "string")
		end
		check(general, id .. " empieza con un plano de situación (con nombre)")
	end
end

---------------------------------------------------------------------
print("2. La regla de oro: las cinco preguntas encima de cada escena")
---------------------------------------------------------------------
local source = fs.readFile("src/shared/LifeStory/Happenings/Instituto.luau")
for _, id in SCENES do
	-- El comentario entre la escena de antes y esta
	local at = source:find("\n\t" .. id .. " = {", 1, true) or 0
	local from = 1
	for pos in source:gmatch("()\n\t[%w_]+ = {\n") do
		if pos < at then
			from = pos + 1
		end
	end
	local lastBlock = if at > 0 then source:sub(from, at) else ""
	local ok = lastBlock:find("¿Qué está pasando?", 1, true)
		and lastBlock:find("¿Por qué?", 1, true)
		and lastBlock:find("¿Qué siente?", 1, true)
		and lastBlock:find("¿Qué ve el jugador?", 1, true)
		and lastBlock:find("¿Qué debe sentir?", 1, true)
	check(ok ~= nil, id .. " responde a las cinco preguntas")
end

---------------------------------------------------------------------
print("3. Variantes, frases con condiciones y tramos que no se pisan")
---------------------------------------------------------------------
-- Una partida de mentira con Conditions (más Items y Late, como HappeningService.checker)
local function profile(spec: { [string]: any }): (req: { [string]: any }) -> boolean
	local flags, choices, memories = {}, {}, {}
	for _, f in spec.Flags or {} do
		flags[f] = true
	end
	for k, v in spec.Choices or {} do
		choices[k] = { V = v }
	end
	for _, m in spec.Memories or {} do
		memories[m] = { At = 0 }
	end
	local c = {
		Stage = "Adolescente",
		ClockTime = 12,
		Weekday = 2,
		Completed = {},
		Flags = flags,
		Choices = choices,
		Discovered = {},
		Rel = spec.Rel or {},
		Traits = {},
		Memories = memories,
		StageProgress = 1,
	}
	return function(req)
		local rest = table.clone(req)
		if rest.Late ~= nil then
			if (spec.Late == true) ~= (rest.Late == true) then
				return false
			end
			rest.Late = nil
		end
		if rest.Items ~= nil then
			for item, n in rest.Items do
				if ((spec.Items or {})[item] or 0) < n then
					return false
				end
			end
			rest.Items = nil
		end
		return (Conditions.check(rest, c :: any))
	end
end

-- Partidas: una «vacía» (personaje nuevo), las más largas (todo lo opcional a la vez) y la de la prueba larga
local PROFILES = {
	Nuevo = {},
	Largo = {
		Flags = { "ConocesALeire", "HugoConElGrupo", "AyudasteAMateo", "IkerEnElGrupo", "LlegasTardeParada", "LlegasTardeInstituto", "Pillado", "Hurto", "MentisteFamilia", "MontajeDario", "Camino_Delincuente", "TeReiste" },
		Choices = {
			Promesa = "Nuevos", NombreGrupo = "Los del Banco Azul", SitioInstituto = "Bruno", RecreoIns = "Explorar",
			PrimerDiaIns = "Acompanado", Meta = "Ahorro", Sueldo = "Familia", Orientacion = "Dudas", SuenoInfancia = "Ingenieria",
			HablasNico = "Publico", Dario = "Javier", Plan = "Frenar", Veterano = "Dudar", Foto = "Frenar",
		},
		Memories = { "PrimerClub" },
		Items = { FotoDeLeire = 1 },
		Rel = { Rayo = 10, Nico = 10 },
	},
	Leo = {
		Flags = { "ConocesALeire", "HugoConElGrupo", "AyudasteAMateo", "IkerEnElGrupo", "Redimido" },
		Choices = {
			Promesa = "Juntos", NombreGrupo = "Los Imparables", SitioInstituto = "Bruno", RecreoIns = "Explorar",
			PrimerDiaIns = "Solo", Meta = "Camara", Sueldo = "Mitad", Orientacion = "Dudas", SuenoInfancia = "Ingenieria",
			HablasNico = "Privado", Dario = "Perdon", Plan = "Frenar", Veterano = "Creer", Foto = "Frenar", Bruno = "Confiar",
		},
		Memories = { "PrimerClub" },
		Items = { FotoDeLeire = 1 },
		Rel = { Rayo = 20, Nico = 12 },
	},
	Distantes = {
		Flags = { "Hurto", "Escapaste" },
		Choices = { Plan = "Ir", HablasNico = "Publico", Dario = "Venganza", Promesa = "Banco", NombreGrupo = "Los Dinosaurios" },
		Rel = { Rayo = -5, Nico = -6 },
	},
}

local function expanded(id: string, who: string): ({ [string]: any }, { [string]: any }, any)
	local def = HappeningIndex.get(id) :: any
	local choice = Sequencer.resolve(def, profile(PROFILES[who]))
	local tl = Sequencer.compile(id, def, choice)
	return tl.Def, choice, tl
end

local function textOf(def: { [string]: any }): string
	local parts = {}
	for _, line in def.Tracks.Dialogue or {} do
		table.insert(parts, line.T)
	end
	return table.concat(parts, "\n")
end

local function has(def, fragment: string): boolean
	return textOf(def):find(fragment, 1, true) ~= nil
end

for _, id in SCENES do
	for who in PROFILES do
		local def, _, tl = expanded(id, who)
		local lines = def.Tracks.Dialogue or {}
		local overlaps = {}
		local prev = nil
		for _, line in lines do
			if prev and line.At < prev.At + prev.Duration + (prev.After or 0) - 1e-6 then
				table.insert(overlaps, ("«%s…» empieza en %.1f y la anterior acaba en %.1f"):format(line.T:sub(1, 24), line.At, prev.At + prev.Duration + (prev.After or 0)))
			end
			prev = line
		end
		local last = lines[#lines]
		local lastEnd = if last then last.At + last.Duration + (last.After or 0) else 0
		for _, o in overlaps do
			print("     " .. o)
		end
		check(#overlaps == 0, ("%s (%s): las frases no se pisan"):format(id, who))
		check(lastEnd <= tl.Duration + 1e-6, ("%s (%s): el diálogo cabe en la escena (%.1f de %.1f s)"):format(id, who, lastEnd, tl.Duration))
		check(#lines > 0, ("%s (%s): hay diálogo"):format(id, who))
	end
end

-- Lo que hiciste cambia lo que se dice
local leoParada = expanded("Ins01_Parada", "Leo")
check(has(leoParada, "Pero en el recreo sí. ¡Lo prometimos!") and has(leoParada, "Los Imparables: eso no lo separa"), "Parada: Nico recuerda la promesa y Omar el nombre del grupo")
check(has(leoParada, "Antes que el autobús") and not has(leoParada, "¡Por fin!"), "Parada: llegas a tiempo")
local largoParada = expanded("Ins01_Parada", "Largo")
check(has(largoParada, "¡Por fin!") and has(largoParada, "Los del Banco Azul") and has(largoParada, "gente nueva"), "Parada: llegas tarde, otra promesa, otro nombre")
check(not has(expanded("Ins01_Parada", "Nuevo"), "Imparables"), "Parada: sin grupo del colegio, nadie se inventa un nombre")
check(has(expanded("Ins03_Carmen", "Leo"), "¿Vamos juntos a la comisaría?") and has(expanded("Ins03_Carmen", "Leo"), "Mi tío. Claro"), "Carmen: Bruno (tu compañero de pupitre) te habla bajito; Leire y su tío")
check(has(expanded("Ins03_Carmen", "Leo"), "tu club también cuenta"), "Carmen: se acuerda de que estás en un club")
local oferta = expanded("Pan3_Oferta", "Leo")
check(has(oferta, "Cincuenta pavos por tarde") and has(oferta, "Tú no viniste") and has(oferta, "A ti te hace caso"), "Oferta: Rayo recuerda que no fuiste al súper y que frenaste a Nerea")
check(has(expanded("Pan3_Oferta", "Largo"), "tú no dijiste nada") and has(expanded("Pan3_Oferta", "Largo"), "mentiras pesan"), "Oferta: te pillaron (y mentiste en casa)")
local _, distChoice = expanded("Pan3_Oferta", "Distantes")
check(distChoice.Variant == 1 and has(expanded("Pan3_Oferta", "Distantes"), "Tú corriste más que yo"), "Oferta: si os lleváis mal, la variante «Distantes»; escapaste corriendo")
local _, leoOferta = expanded("Pan3_Oferta", "Leo")
check(leoOferta.Variant == nil, "Oferta: con buena relación, la escena de siempre")
local dia = expanded("Ins05_DiaDespues", "Leo")
check(has(dia, "He hecho pulseras para todos") and has(dia, "La he borrado. Fue una idiotez.") and has(dia, "Pone «Los Imparables»"), "Día después: Darío pidió perdón por privado; pulseras con el nombre del grupo")
check(has(dia, "sin nadie delante") and not has(dia, "delante de todo el equipo"), "Día después: Nico recuerda que se lo dijiste aparte")
local diaLargo = expanded("Ins05_DiaDespues", "Largo")
check(has(diaLargo, "De verdad. Era una tontería") and has(diaLargo, "delante de todo el equipo") and has(diaLargo, "Te reíste, y me lo dijiste"), "Día después: Darío entra a pedir perdón; Nico, delante de todos; Omar recuerda que te reíste")
local diaDist, diaDistChoice = expanded("Ins05_DiaDespues", "Distantes")
check(diaDistChoice.Variant == 1 and has(diaDist, "guerra de montajes"), "Día después: si Nico y tú acabasteis mal, Nico no levanta la vista; la guerra de montajes")
local darioEnters = false
for _, e in diaLargo.Tracks.Actors do
	darioEnters = darioEnters or (e.Enter ~= nil and e.Enter.Key == "Dario")
end
local darioAbsent = true
for _, e in expanded("Ins05_DiaDespues", "Leo").Tracks.Actors do
	darioAbsent = darioAbsent and not (e.Enter ~= nil and e.Enter.Key == "Dario")
end
check(darioEnters and darioAbsent, "Día después: Darío solo entra (andando) si se lo contaste a Javier")
local noche = expanded("Ins06_Noche", "Leo")
check(has(noche, "te fuiste sin mirar atrás") and has(noche, "las dudas son buena señal") and has(noche, "Inventar cosas que no existen") and has(noche, "Saliste de algo difícil"), "Noche: tu primer día, tus dudas, tu sueño de niño y que saliste de algo difícil")
local nocheLarga = expanded("Ins06_Noche", "Largo")
check(has(nocheLarga, "hasta la puerta") and has(nocheLarga, "comisaría") and has(nocheLarga, "ahorraste") and has(nocheLarga, "primer sueldo") and has(nocheLarga, "Todavía estás a tiempo") and not has(nocheLarga, "Saliste de algo difícil"), "Noche: la comisaría, el ahorro, la cena del primer sueldo y el camino que llevas")
local grad = expanded("Ins06_Graduacion", "Leo")
check(has(grad, "Algunos esperasteis un ascensor") and has(grad, "Los Imparables. Promoción") and has(grad, "Te aprendiste el instituto") == false and has(grad, "te aprendiste el instituto entero"), "Graduación: el ascensor, el nombre del grupo, tu primer recreo")
check(has(grad, "Esta foto la hago yo") and has(grad, "Yo también me quedé una tuya") and has(grad, "nunca te copié"), "Graduación: Leire (y su foto del primer día) y Bruno, tu compañero de pupitre")
local gradLargo = expanded("Ins06_Graduacion", "Largo")
check(has(gradLargo, "preguntasteis a la delegada") and has(gradLargo, "campo de batalla") and has(gradLargo, "lo de llegar tarde el primer día"), "Graduación: la delegada, la guerra de montajes y que llegaste tarde")
check(not has(expanded("Ins06_Graduacion", "Nuevo"), "Esta foto la hago yo"), "Graduación: sin conocer a Leire, Leire no hace la foto")
local flash = false
for _, shot in grad.Tracks.Camera do
	flash = flash or shot.Cut == "Flash"
end
check(flash, "Graduación: el destello de la foto de la orla")

---------------------------------------------------------------------
print("4. Continuidad: se leen las marcas, recuerdos y decisiones de antes")
---------------------------------------------------------------------
-- Todo lo que leen las escenas y las misiones del paquete
local read: { [string]: boolean } = {}
local function collect(req: any)
	if type(req) ~= "table" then
		return
	end
	for kind, value in req do
		if kind == "Flags" or kind == "NotFlags" or kind == "Memories" or kind == "NotMemories" then
			for _, name in value do
				read[name] = true
			end
		elseif kind == "Choices" or kind == "NotChoices" or kind == "Rel" or kind == "RelBelow" or kind == "Items" then
			for name in value do
				read[name] = true
			end
		end
	end
end
local function walk(node: any, seen: { [any]: boolean })
	if type(node) ~= "table" or seen[node] then
		return
	end
	seen[node] = true
	for k, v in node do
		if (k == "If" or k == "IfNot" or k == "Requires") and type(v) == "table" then
			collect(v)
		end
		walk(v, seen)
	end
end
for _, id in SCENES do
	walk(HappeningIndex.get(id), {})
end
for _, questId in { "Ins01_NuevoInstituto", "Ins02_Clubes", "Ins03_QueQuieresSer", "Ins04_PrimerEmpleo", "Ins05_ElRumor", "Ins06_LaGranDecision", "Pan1_MalasCompanias", "Pan2_LaNoche", "Pan3_Cruce" } do
	walk(Quests[questId], {})
end
walk(SchoolLife.Dialogues, {})
local HOOKS = {
	NombreGrupo = "el nombre del grupo (Cole03)",
	Promesa = "la promesa del último día de cole (Cole12)",
	SuenoInfancia = "tu sueño de cuando tenías diez años (Cole03)",
	SitioInstituto = "dónde te sentaste el primer día (Ins01)",
	RecreoIns = "con quién pasaste el primer recreo (Ins01)",
	PrimerDiaIns = "cómo te fuiste el primer día (Ins01)",
	PrimerDiaInstituto = "el recuerdo del primer día de instituto (Ins01)",
	PrimerClub = "tu club (Ins02)",
	Club = "qué club elegiste (Ins02)",
	Orientacion = "cómo saliste de la semana de las profesiones (Ins03)",
	QueQuieresSer = "el recuerdo de la semana de las profesiones (Ins03)",
	Perfil = "tu perfil del taller de empleo (Ins04)",
	BuenTrabajo = "que hiciste bien tu primer trabajo (Ins04)",
	Sueldo = "qué hiciste con tu primer sueldo (Ins04)",
	MentisteFamilia = "la mentira en casa (Pan1)",
	Pillado = "que te pillaron en el súper (Pan2)",
	LaNoche = "el recuerdo de la noche del súper (Pan2)",
	ElCruce = "el recuerdo del cruce de caminos (Pan3)",
	HablasNico = "cómo hablaste con Nico (Ins05)",
	MontajeDario = "la guerra de montajes (Ins05)",
	EmpiezaATrabajar = "que decidiste trabajar (Ins06)",
	FotoDeLeire = "la foto que te regaló Leire (Eco_Leire)",
	LlegasTardeParada = "llegar tarde a la parada (Ins01)",
}
local names = {}
for name in HOOKS do
	table.insert(names, name)
end
table.sort(names)
for _, name in names do
	check(read[name] == true, "se lee: " .. HOOKS[name])
end

---------------------------------------------------------------------
print("5. Las misiones lanzan sus escenas y pasan el validador")
---------------------------------------------------------------------
for _, id in SCENES do
	local questId = LAUNCHED_BY[id]
	local quest = Quests[questId]
	local found = nil
	for i, step in (quest and quest.Steps) or {} do
		if step.Type == "Cinematic" and step.Id == id then
			found = { Index = i, Step = step }
		end
	end
	check(found ~= nil, ("%s lanza %s"):format(questId, id))
	if found then
		-- Quien la escena toma prestado (Use) está en el reparto del paso (si no, saldría de la nada)
		local cast = {}
		for _, spec in found.Step.Actors or {} do
			cast[spec.Npc] = true
		end
		local missing = {}
		for _, e in (HappeningIndex.get(id) :: any).Tracks.Actors do
			if e.Use and not cast[e.Use.Npc] then
				table.insert(missing, e.Use.Npc)
			end
		end
		check(#missing == 0, ("%s: los actores prestados están en el paso (%s)"):format(id, table.concat(missing, ", ")))
	end
end
-- La comisaría ya no salta en seco: el paso que te lleva allí es una escena con fundido
local problems = Validate.run()
local mine = {}
for _, p in problems.Errors or problems do
	local text = tostring(p)
	if text:find("Ins0") or text:find("Pan") or text:find("Instituto") or text:find("Adol") then
		table.insert(mine, text)
	end
end
for _, e in mine do
	print("     " .. e)
end
check(#mine == 0, "el validador no da errores en las misiones del instituto")

-- Sin dobletes «encargado o encargada»: el token {o/a}
local doublets = {}
for _, file in fs.readDir("src/shared/LifeStory/Misiones") do
	if file:match("^Ins") or file:match("^Pan") or file == "Loco_Adolescente.luau" then
		local text = fs.readFile("src/shared/LifeStory/Misiones/" .. file)
		for a, b in text:gmatch("(%a+)o o (%a+)a[%s%.,]") do
			if a == b then
				table.insert(doublets, file .. ": " .. a .. "o o " .. b .. "a")
			end
		end
		if text:find("o u orgullosa", 1, true) or text:find("ienvenida, bienvenido", 1, true) or text:find("rara o raro", 1, true) then
			table.insert(doublets, file)
		end
	end
end
for _, d in doublets do
	print("     " .. d)
end
check(#doublets == 0, "sin dobletes de género en las misiones del instituto")

---------------------------------------------------------------------
print("6. El día normal de instituto tiene sus propias frases")
---------------------------------------------------------------------
local adol = Quests.Adol_Jornada
local nino = Quests.Nino_Jornada
local rng = L.Random.new(11)
local usedAdol, usedNino = {}, {}
for _ = 1, 80 do
	for _, step in DayPlans.generate("HighSchoolDay", rng).Steps do
		if step.Dialogue then
			usedAdol[step.Dialogue] = true
		end
	end
	for _, step in DayPlans.generate("SchoolDay", rng).Steps do
		if step.Dialogue then
			usedNino[step.Dialogue] = true
		end
	end
end
local allExist, shared = true, {}
for name in usedAdol do
	allExist = allExist and adol.Dialogues[name] ~= nil
	if usedNino[name] then
		table.insert(shared, name)
	end
end
for name in usedNino do
	allExist = allExist and nino.Dialogues[name] ~= nil
end
check(next(usedAdol) ~= nil and allExist, "las conversaciones del día de instituto y del de cole existen")
check(#shared == 0, "el instituto no repite las conversaciones del colegio (" .. table.concat(shared, ", ") .. ")")
local kidLines = {}
for name in usedNino do
	for _, line in nino.Dialogues[name].Lines do
		if line.T then
			kidLines[line.T] = true
		end
	end
end
local repeated = {}
for name in usedAdol do
	for _, line in adol.Dialogues[name].Lines do
		if line.T and kidLines[line.T] then
			table.insert(repeated, line.T)
		end
	end
end
check(#repeated == 0, "ninguna frase del colegio se repite en el instituto")
check(not textOf({ Tracks = { Dialogue = adol.Dialogues.Ins_Recreo_Omar and adol.Dialogues.Ins_Recreo_Omar.Lines or {} } }):find("Mitad para ti", 1, true), "con 15 años nadie te dice «¡Mitad para ti, mitad para mí!»")
local lunch = SchoolLife.lunchActors("Sara", "Instituto")
check(lunch[1].Bark ~= SchoolLife.LunchBarks.Sara, "en el comedor del instituto, Sara dice otra cosa que en el del cole")

L.finish("test-instituto")
