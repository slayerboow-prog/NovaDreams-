-- Prueba del paquete P8d · PROFESIÓN Y VIDA ADULTA (escenas escritas a mano y su continuidad).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-adulto.luau
--
-- Comprueba:
--   1. Las escenas de Happenings/Adulto están bien escritas (Sequencer.validate con todo el contexto) y
--      cada una explica la regla de oro (las cinco preguntas) en su comentario.
--   2. Registro: si el grupo "Adulto" está en HappeningIndex, las misiones las lanzan como escena de cine;
--      si todavía no, como conversación con las mismas frases (Adu_Escenas.paso, sin romper nada).
--   3. Variantes: con cada carrera o trabajo solo habla TU jefe; llegar tarde, lo del verano, la promesa a
--      Abu, la concha, el despido, el ascenso, la lluvia o el invierno cambian lo que se dice.
--   4. Misiones: los pasos nuevos en su sitio, el montaje de etapa (Transition en Adu03, sin
--      Rewards.SetStage), ascenso y despido enganchados con Later, la policía con Promoted, los veteranos
--      con Ernesto y Lola, el metro sin narrador, y que el validador las da por buenas.
--   5. Escritura: sin dobletes «o encargada», sin {abu}/{grupo} en las escenas (allí no se rellenan).

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local H = require("./lib/StoryHarness")

local check = L.check

local ROOT = "src/shared/LifeStory"
local Sequencer = L.load(ROOT .. "/Sequencer")
local Conditions = L.load(ROOT .. "/Conditions")
local Cast = L.load(ROOT .. "/Cast")
local Locations = L.load(ROOT .. "/Locations")
local EventCatalog = L.load(ROOT .. "/EventCatalog")
local Escenas = L.load(ROOT .. "/Happenings/Adulto")
local RealIndex = L.load(ROOT .. "/HappeningIndex")
local Cinematics = L.load(ROOT .. "/Cinematics")

local SCENES = {
	"Adu01_PrimerDia",
	"Adu01_Firma",
	"Adu01_PrimerTurno",
	"Adu01_Buzon",
	"Adu_Ascenso",
	"Adu_Despido",
	"Adu_DespidoCasa",
	"Adu_AscensoRango",
	"Adu02_Hospital",
	"Adu02_Orilla",
	"Adu03_Banco",
	"Adulto_Bienvenida",
}

---------------------------------------------------------------------
print("1. Escenas bien escritas")
---------------------------------------------------------------------
local ctx = {
	Fx = L.load("src/shared/StoryFxCatalog").names(),
	SkyMoods = L.load("src/shared/SkyMoods").names(),
	Moods = L.load(ROOT .. "/ActorMoods").names(),
	Creatures = L.load(ROOT .. "/StoryCreatures").names(),
	Places = Locations.Places,
	Zones = Locations.Zones,
	Cast = Cast.People,
	Events = EventCatalog.Names,
	Poses = L.load(ROOT .. "/Emotion").Poses,
}
local source = fs.readFile(ROOT .. "/Happenings/Adulto.luau")
local count = 0
for _ in Escenas do
	count += 1
end
check(count == #SCENES, ("el grupo tiene las %d escenas del paquete (hay %d)"):format(#SCENES, count))
for _, id in SCENES do
	local def = Escenas[id]
	if not def then
		check(false, "existe la escena " .. id)
		continue
	end
	local errors = Sequencer.validate(id, def, ctx)
	for _, e in errors do
		print("     " .. e)
	end
	check(#errors == 0, ("escena %s sin errores"):format(id))
	check(Cinematics[id] == nil, ("%s no se llama igual que una cinemática vieja"):format(id))
	check(def.Skippable == true, ("%s se puede saltar"):format(id))
	-- Regla de oro: el comentario de encima responde a las cinco preguntas
	local at = source:find("\n\t" .. id .. " = {", 1, true)
	local before = at and source:sub(math.max(1, at - 1400), at) or ""
	local block = before:match(".*%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-\n(.*)") or before
	local golden = block:find("¿Qué está pasando?", 1, true)
		and block:find("¿Por qué?", 1, true)
		and block:find("¿Qué siente el personaje?", 1, true)
		and block:find("¿Qué ve el jugador?", 1, true)
		and block:find("¿Qué quiero que sienta?", 1, true)
	check(golden ~= nil, ("%s responde a las cinco preguntas de la regla de oro"):format(id))
	local tracks = def.Tracks or {}
	check(tracks.Ambience ~= nil and #tracks.Ambience > 0, ("%s tiene sonido ambiente"):format(id))
	check(tracks.Camera ~= nil and #tracks.Camera > 0, ("%s abre con un plano de situación"):format(id))
	for _, line in tracks.Dialogue or {} do
		local text = line.T or ""
		if text:find("{abu}", 1, true) or text:find("{grupo}", 1, true) then
			check(false, ("%s: «%s» usa una variable que la escena no rellena"):format(id, text))
		end
	end
end

---------------------------------------------------------------------
print("2. Registro (HappeningIndex) y pasos de misión")
---------------------------------------------------------------------
local registered = table.find(RealIndex.Groups, "Adulto") ~= nil
if registered then
	for _, id in SCENES do
		check(RealIndex.has(id), id .. " está registrada")
	end
else
	print('  ℹ️  El grupo "Adulto" aún no está en HappeningIndex.GROUPS (lo lleva P7). Línea que hay que añadir:')
	print('       local GROUPS = { "Cielo", …, "Adulto" }')
end
-- Sin registrar: el paso es una conversación con las mismas frases
L.mock(ROOT .. "/HappeningIndex", {
	has = function()
		return false
	end,
})
L.reset(ROOT .. "/Misiones/Adu_Escenas")
local Fallback = L.load(ROOT .. "/Misiones/Adu_Escenas")
local fb = Fallback.paso("Adu01_PrimerDia", Fallback.JEFE)
check(fb.Type == "Scene" and type(fb.Dialogue) == "table" and #fb.Dialogue.Lines > 0 and fb.Actors == Fallback.JEFE, "sin registrar: conversación con las frases de la escena y el mismo reparto")
local cleanFallback = true
for _, id in SCENES do
	for _, line in Fallback.lineas(id).Lines do
		if line.Shot or line.To or (line.If and (line.If.Late ~= nil or line.If.Items ~= nil)) or (line.Pause and line.Pause > 1.5) then
			cleanFallback = false
		end
		if line.Beat and not ({ Mira = true, Baja = true, Aparta = true, Piensa = true, Respira = true })[line.Beat] then
			cleanFallback = false
		end
	end
	check(#Fallback.lineas(id).Lines > 0, id .. " tiene frases para jugarse como conversación")
end
check(cleanFallback, "como conversación: sin planos, sin Late/Items, pausas cortas y Beats de StageDirector")
check(Fallback.montaje("Joven_Adulto") == nil, "sin el montaje de P7, Adu03 acaba con el rótulo solo")
-- Registrado: escena de cine
local fakeIndex = {
	has = function(id)
		return Escenas[id] ~= nil or id == "Joven_Adulto"
	end,
}
L.mock(ROOT .. "/HappeningIndex", fakeIndex)
L.reset(ROOT .. "/Misiones/Adu_Escenas")
local Real = L.load(ROOT .. "/Misiones/Adu_Escenas")
local cine = Real.paso("Adu02_Hospital", { { Npc = "Abu" } }, { If = { Flags = { "X" } } })
check(cine.Type == "Cinematic" and cine.Id == "Adu02_Hospital" and cine.If.Flags[1] == "X", "registrada: paso Cinematic con su Id, su reparto y lo que se le añada")
check(Real.montaje("Joven_Adulto") == "Joven_Adulto", "con el montaje de P7: Transition.Cinematic = Joven_Adulto")
L.mock(ROOT .. "/HappeningIndex", RealIndex)

---------------------------------------------------------------------
print("3. Variantes y continuidad")
---------------------------------------------------------------------
-- Una partida de mentira → la función de condiciones del servidor (Flags, Choices, Memories, Items…)
local function profile(p: { [string]: any }): (req: { [string]: any }) -> boolean
	local flags = {}
	for _, f in p.Flags or {} do
		flags[f] = true
	end
	local choices = {}
	for k, v in p.Choices or {} do
		choices[k] = { V = v }
	end
	local memories = {}
	for _, m in p.Memories or {} do
		memories[m] = { D = 1 }
	end
	local completed = {}
	for _, q in p.Completed or {} do
		completed[q] = true
	end
	local c = {
		Rel = {},
		Traits = {},
		Memories = memories,
		Stage = "AdultoJoven",
		ClockTime = 12,
		Weekday = 1,
		Completed = completed,
		Flags = flags,
		Choices = choices,
		Discovered = {},
		StageProgress = 0.5,
		Season = p.Season,
		Weather = p.Weather,
	}
	return function(req)
		local rest = table.clone(req)
		if rest.Items then
			for item, n in rest.Items do
				if ((p.Items or {})[item] or 0) < n then
					return false
				end
			end
			rest.Items = nil
		end
		if rest.Late ~= nil then
			if (p.Late == true) ~= rest.Late then
				return false
			end
			rest.Late = nil
		end
		return Conditions.check(rest, c)
	end
end

local function play(id: string, p: { [string]: any }): ({ { [string]: any } }, { [string]: any })
	local def = Escenas[id]
	local expanded = Sequencer.expand(def, Sequencer.resolve(def, profile(p)))
	return expanded.Tracks.Dialogue or {}, expanded
end

local function says(lines, who: string?, fragment: string): boolean
	for _, line in lines do
		if (who == nil or line.S == who) and (line.T or ""):find(fragment, 1, true) then
			return true
		end
	end
	return false
end

local function speakers(lines): { [string]: boolean }
	local set = {}
	for _, line in lines do
		set[line.S] = true
	end
	return set
end

-- Cada camino: solo habla su jefe
local PATHS = {
	{ Boss = "Nuria", P = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Medicina" } } },
	{ Boss = "Sofia", P = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Ingenieria" } } },
	{ Boss = "Montse", P = { Flags = { "Graduado" }, Choices = { Estudios = "Derecho" } } },
	{ Boss = "Ignacio", P = { Flags = { "Graduado" }, Choices = { Estudios = "Economia" } } },
	{ Boss = "Lola", P = { Flags = { "EmpiezaATrabajar" }, Choices = { Empleo = "Barista" } } },
	{ Boss = "Paco", P = { Flags = { "EmpiezaATrabajar" }, Choices = { Empleo = "Reponedor" } } },
	{ Boss = "Ernesto", P = { Flags = { "EmpiezaATrabajar" }, Choices = { Empleo = "Repartidor" } } },
}
local BOSSES = { Nuria = true, Sofia = true, Montse = true, Ignacio = true, Lola = true, Paco = true, Ernesto = true }
for _, sceneId in { "Adu01_PrimerDia", "Adu01_Firma", "Adu_Ascenso", "Adu_Despido" } do
	local ok = true
	for _, path in PATHS do
		local lines, ex = play(sceneId, path.P)
		local who = speakers(lines)
		local used = {}
		for _, ev in ex.Tracks.Actors or {} do
			if ev.Use then
				used[ev.Use.Key] = true
			end
		end
		for boss in BOSSES do
			local should = boss == path.Boss
			if (who[boss] == true) ~= should or (used[boss] == true) ~= should then
				ok = false
				print(("     %s con %s: habla o sale %s"):format(sceneId, path.Boss, boss))
			end
		end
	end
	check(ok, sceneId .. ": en cada uno de los siete caminos solo está y habla tu jefe")
end
do
	local lines = play("Adu01_PrimerTurno", PATHS[5].P)
	check(says(lines, "Omar", "Encargad{o/a}") and says(lines, "Lola", "Turno cerrado"), "Primer turno (cafetería): Omar sale de la cocina y Lola cierra el turno")
	local lines2 = play("Adu01_PrimerTurno", PATHS[1].P)
	check(#lines2 == 0, "Primer turno: con carrera no hay nada (el paso tampoco sale)")
end

-- Llegar tarde (el paso Reach marca LlegasTardeContrato) y llegar tarde también a las prácticas
local ing = PATHS[2].P
local onTime = play("Adu01_PrimerDia", ing)
local late = play("Adu01_PrimerDia", { Flags = { "Graduado", "OfertaTrabajo", "LlegasTardeContrato" }, Choices = ing.Choices })
local twice = play("Adu01_PrimerDia", { Flags = { "Graduado", "OfertaTrabajo", "LlegasTardeContrato", "LlegasTardePracticas" }, Choices = ing.Choices })
check(says(onTime, "Sofia", "Justo a tiempo") and not says(onTime, "Sofia", "margen de error"), "a tiempo: Sofía te recibe contenta")
check(says(late, "Sofia", "margen de error") and not says(late, "Sofia", "Justo a tiempo") and not says(late, "Sofia", "Tarde a las prácticas"), "tarde: Sofía te lo dice")
check(says(twice, "Sofia", "Tarde a las prácticas"), "tarde dos primeros días seguidos (prácticas y contrato): lo recuerda")
-- Lo que hiciste aquel verano (Ins04)
local cafe = PATHS[5].P
check(says(play("Adu01_PrimerTurno", { Flags = { "EmpiezaATrabajar", "BuenTrabajo" }, Choices = cafe.Choices }), "Lola", "bandeja entera"), "Lola recuerda que le dijiste lo de la bandeja (BuenTrabajo)")
check(says(play("Adu01_PrimerTurno", { Flags = { "EmpiezaATrabajar", "MentisteEntrevista" }, Choices = PATHS[6].P.Choices }), "Paco", "Sin mentir"), "Paco sabe que mentiste en la entrevista (MentisteEntrevista)")
-- Ascenso: tu primer caso y tu TFG
local asc = play("Adu_Ascenso", { Flags = { "Graduado" }, Choices = { Estudios = "Ingenieria", PrimerCaso = "Lanzarse", TemaTFG = "Practicas" } })
check(says(asc, "Sofia", "Te lanzaste") and says(asc, "Sofia", "trabajo de fin de grado") and not says(asc, "Sofia", "vale oro"), "ascenso: Sofía recuerda que te lanzaste en tu primer caso y tu TFG de las prácticas")
-- Despido: tarde, la mentira, el ascenso
local fired = play("Adu_Despido", { Flags = { "Graduado", "LlegasTardeContrato", "Ascendido" }, Choices = { Estudios = "Medicina" } })
check(says(fired, "Nuria", "llegaste tarde") and says(fired, "Nuria", "te ascendí"), "despido: Nuria menciona aquel primer día y tu ascenso")
-- Esa noche: la promesa a Abu y la concha
local home = play("Adu_DespidoCasa", { Choices = { PromesaAbu = "Volver" }, Items = { ConchaAbu = 1 } })
check(says(home, "Familia", "al mar, como le prometiste") and says(home, "Familia", "concha") and not says(home, "Familia", "cosas bonitas"), "en casa: tu familia recuerda tu promesa a Abu (volver al mar) y la concha")
local home2 = play("Adu_DespidoCasa", { Choices = { PromesaAbu = "CosasBonitas" } })
check(says(home2, "Familia", "cosas bonitas") and not says(home2, "Familia", "concha"), "…o la de hacer cosas bonitas (y sin concha, no la nombra)")
-- Hospital y orilla
check(says(play("Adu02_Hospital", { Flags = { "Despedido" } }), "Familia", "lo del trabajo"), "hospital: tu familia no le ha contado a Abu lo del despido")
check(says(play("Adu02_Hospital", { Flags = { "Ascendido" } }), "Familia", "ascenso"), "hospital: Abu presume de tu ascenso")
check(says(play("Adu02_Orilla", { Weather = "Lluvia" }), "Abu", "el mar con lluvia") and not says(play("Adu02_Orilla", {}), "Abu", "el mar con lluvia"), "la orilla: si llueve, Abu lo dice")
check(says(play("Adu02_Orilla", { Season = "Invierno" }), "Yo", "chaqueta"), "la orilla: en invierno le das tu chaqueta")
-- El banco
local bench = play("Adu03_Banco", { Flags = { "ConocesALeire", "Despedido" }, Memories = { "AtardecerConAbu" } })
check(says(bench, "Leire", "toma") and says(bench, "Nico", "lo del trabajo") and says(bench, "Yo", "le prometí volver"), "el banco: Leire (si la conoces), el despido y la promesa a Abu")
check(not says(play("Adu03_Banco", {}), "Leire", "toma"), "el banco: sin conocer a Leire, no está")
-- Policía
local cop = play("Adu_AscensoRango", { Flags = { "Antecedentes", "Detenido" }, Completed = { "Adu03_Reencuentro" } })
check(says(cop, "Ines", "expediente de menores") and says(cop, "Bruno", "esposas"), "ascenso en la policía: Inés recuerda tu expediente y Bruno las esposas")
local _, copEx = play("Adu_AscensoRango", {})
local brunoIn = false
for _, ev in copEx.Tracks.Actors do
	if ev.Enter and ev.Enter.Key == "Bruno" then
		brunoIn = true
	end
end
check(not brunoIn, "…y Bruno solo entra si ya es policía (después del reencuentro)")

-- Entradas andando y salidas andando
local function walks(id: string): (boolean, boolean)
	local enter, exit = false, false
	for _, ev in Escenas[id].Tracks.Actors or {} do
		if ev.Enter and ev.Enter.Walk then
			enter = true
		elseif ev.Exit and ev.Exit.Walk then
			exit = true
		end
	end
	return enter, exit
end
local e1, x1 = walks("Adulto_Bienvenida")
check(e1 and x1, "bienvenida: Ernesto y Lola llegan andando y se van andando")
check((walks("Adu_DespidoCasa")), "esa noche: tu familia entra andando")

---------------------------------------------------------------------
print("4. Misiones")
---------------------------------------------------------------------
local Quests = H.loadModule(H.ROOT .. "/shared/LifeStory/Quests")
local Validate = H.loadModule(H.ROOT .. "/shared/LifeStory/Validate")
local report = Validate.report()
local mine = {
	"Adu01_PrimerContrato", "Adu02_Atardecer", "Adu03_Reencuentro", "Eco_Factura", "Adu_Ascenso", "Eco_Despido",
	"Adu_AscensoPolicia", "Adulto_LlegadaValmar", "Adulto_PrimerSueldo", "MetroS_PrimerDiaUni", "MetroS_Cartera",
	"MetroS_PrimerTrabajo", "Loco_D1_Lunes", "Loco_D2_Deuda", "Loco_D3_Tostadora", "Loco_D4_Gnomos", "Loco_D5_Malvado",
}
for _, id in mine do
	check(Quests[id] ~= nil and not report.BadQuests[id], id .. " existe y pasa el validador")
end
for _, e in report.Errors do
	print("     " .. e)
end
check(#report.Errors == 0, "el validador no da errores")

local function stepWith(questId: string, id: string): number?
	for i, step in Quests[questId].Steps do
		if (step.Type == "Cinematic" and step.Id == id) or (step.Type == "Scene" and type(step.Dialogue) == "table" and step.Dialogue.Lines[1] and step.Dialogue.Lines[1].T == Escenas[id].Tracks.Dialogue[1].T) then
			return i
		end
	end
	-- (la primera frase puede llevar If: se busca cualquiera)
	for i, step in Quests[questId].Steps do
		if step.Type == "Scene" and type(step.Dialogue) == "table" then
			local want = Fallback.lineas(id).Lines
			if #want > 0 and #step.Dialogue.Lines == #want and step.Dialogue.Lines[#want].T == want[#want].T then
				return i
			end
		end
	end
	return nil
end
local adu01 = Quests.Adu01_PrimerContrato
local function index(questId: string, pred: (step: any) -> boolean): number?
	for i, step in Quests[questId].Steps do
		if pred(step) then
			return i
		end
	end
	return nil
end
local contrato = index("Adu01_PrimerContrato", function(s)
	return s.Dialogue == "Contrato"
end)
local primerDia, firma = stepWith("Adu01_PrimerContrato", "Adu01_PrimerDia"), stepWith("Adu01_PrimerContrato", "Adu01_Firma")
check(primerDia and contrato and firma and primerDia == contrato - 1 and firma == contrato + 1, "Adu01: llegada → contrato → firma")
local turno = stepWith("Adu01_PrimerContrato", "Adu01_PrimerTurno")
check(turno and adu01.Steps[turno].If and adu01.Steps[turno].If.NotFlags[1] == "Graduado", "Adu01: el primer turno al mando (sin carrera) sustituye al resumen del narrador")
local buzon, facturas = stepWith("Adu01_PrimerContrato", "Adu01_Buzon"), index("Adu01_PrimerContrato", function(s)
	return s.Dialogue == "Facturas"
end)
check(buzon and facturas and buzon == facturas - 1, "Adu01: el buzón antes de decidir qué hacer con las facturas")
local narrator, total = 0, 0
for _, dialogue in adu01.Dialogues do
	for _, line in dialogue.Lines do
		if line.S then
			total += 1
			narrator += if line.S == "Narrador" then 1 else 0
		end
	end
end
check(narrator == 0, ("Adu01: ninguna frase del narrador (antes, el 41 %%); %d frases"):format(total))
local despidos = 0
for _, later in adu01.Rewards.Later do
	if later.Start == "Eco_Despido" then
		despidos += 1
		check(later.If and ((later.If.Flags or {})[1] == "LlegasTardeContrato" or (later.If.Flags or {})[1] == "MentisteEntrevista"), "el despido llega si llegaste tarde el primer día o mentiste en tu primera entrevista")
	end
end
check(despidos == 2, "Adu01 engancha el despido (Later) por dos motivos")
local laterAsc = Quests.Adu02_Atardecer.Rewards.Later and Quests.Adu02_Atardecer.Rewards.Later[1]
check(laterAsc and laterAsc.Start == "Adu_Ascenso" and laterAsc.If.NotFlags[1] == "Despedido", "Adu02 engancha el ascenso (si no te han despedido)")
check(stepWith("Adu02_Atardecer", "Adu02_Hospital") ~= nil and stepWith("Adu02_Atardecer", "Adu02_Orilla") ~= nil, "Adu02: el hospital y la orilla, escenificados")
check(index("Adu02_Atardecer", function(s)
	return s.Type == "Cinematic" and s.Id == "Adu02_Atardecer"
end) ~= nil, "Adu02: el atardecer final sigue")
local adu03 = Quests.Adu03_Reencuentro
local last = adu03.Steps[#adu03.Steps]
check(adu03.Rewards.SetStage == nil and last.Type == "Transition" and last.SetStage == "Adulto", "Adu03: la vida adulta llega con un paso Transition, no como premio")
check(last.Cinematic == (if RealIndex.has("Joven_Adulto") then "Joven_Adulto" else nil), "Adu03: con el montaje Joven_Adulto de P7 si ya existe")
check(stepWith("Adu03_Reencuentro", "Adu03_Banco") ~= nil, "Adu03: el banco del parque, escenificado")
local asc2 = Quests.Adu_Ascenso
check(asc2.Requires.NotFlags[1] == "Despedido" and stepWith("Adu_Ascenso", "Adu_Ascenso") ~= nil, "Adu_Ascenso: escena con tu jefe y respuesta")
local eco = Quests.Eco_Despido
check(stepWith("Eco_Despido", "Adu_Despido") ~= nil and stepWith("Eco_Despido", "Adu_DespidoCasa") ~= nil, "Eco_Despido: el despacho y esa noche en casa")
check(index("Eco_Despido", function(s)
	return s.Type == "Event" and s.Event == "JobTaskDone"
end) ~= nil, "Eco_Despido: vuelves a trabajar en un tablón de verdad (JobService)")
check(eco.Dialogues.Reaccion.Effects.Flags[1] == "Despedido", "Eco_Despido: queda la marca Despedido (la recuerdan Abu, el grupo…)")
local cop2 = Quests.Adu_AscensoPolicia
check(cop2.Steps[1].Event == "Promoted" and cop2.Steps[1].Match.Institution == "Policia" and cop2.Offer.Place == "Policia", "Adu_AscensoPolicia: Inés te la ofrece en la comisaría y la cierra el aviso Promoted de la policía")
local llegada = Quests.Adulto_LlegadaValmar
check(llegada.Steps[1].TextKey == "QUEST.LLEGADA.PLAZA" and stepWith("Adulto_LlegadaValmar", "Adulto_Bienvenida") == 2 and llegada.Steps[#llegada.Steps].Actors[1].Npc == "Lola", "veteranos: bienvenida de Ernesto y Lola, y Lola en la cafetería")
check(Quests.Adulto_PrimerSueldo.Steps[1].Actors[1].Npc == "Ernesto" and Quests.Adulto_PrimerSueldo.Steps[1].TextKey == "QUEST.SUELDO.TRABAJA", "veteranos: Ernesto te ofrece trabajo en Correos")
local metroNarrator = 0
for _, id in { "MetroS_PrimerDiaUni", "MetroS_Cartera", "MetroS_PrimerTrabajo" } do
	for _, dialogue in Quests[id].Dialogues do
		for _, line in dialogue.Lines do
			metroNarrator += if line.S == "Narrador" then 1 else 0
		end
	end
end
check(metroNarrator == 0, "metro: ninguna frase del narrador (antes, el 100 %)")

---------------------------------------------------------------------
print("5. Escritura")
---------------------------------------------------------------------
local doublets = {}
for _, file in { "Adu01_PrimerContrato", "Adu02_Atardecer", "Adu03_Reencuentro", "Adu_Consecuencias", "Adu_Profesion", "Loco_Adulto", "Metro_Secundarias" } do
	local text = fs.readFile(ROOT .. "/Misiones/" .. file .. ".luau")
	for word in text:gmatch("(%a+o o %a+a)[%s%.,]") do
		table.insert(doublets, file .. ": " .. word)
	end
	for word in text:gmatch("[Bb]ienvenid[oa],? o? ?bienvenid[oa]") do
		table.insert(doublets, file .. ": " .. word)
	end
end
for _, d in doublets do
	print("     " .. d)
end
check(#doublets == 0, "sin dobletes de género («encargado o encargada»): {o/a}")
local flagsRead = {}
for _, f in { "LlegasTardeContrato", "LlegasTardePracticas", "BuenTrabajo", "MentisteEntrevista", "PromesaAbu", "ConchaAbu", "Despedido", "Ascendido", "PrimerCaso", "TemaTFG", "AtardecerConAbu", "Antecedentes", "Detenido", "AdiosBruno", "ConocesALeire", "AyudasteAMateo" } do
	if not source:find("%f[%w]" .. f .. "%f[%W]") then
		table.insert(flagsRead, f)
	end
end
check(#flagsRead == 0, "las escenas leen la continuidad (" .. (if #flagsRead == 0 then "todo" else "faltan: " .. table.concat(flagsRead, ", ")) .. ")")

L.finish("test-adulto")
