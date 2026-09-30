-- DayPlans: los "días normales" que llenan cada etapa entre los grandes momentos de la historia.
-- Cada etapa dura unas horas (Config.LifeStory.StageHours). Los momentos clave (primer día, excursión,
-- exámenes, graduación…) se reparten por esas horas, y entre uno y otro se juegan días generados:
-- un día de cole, de instituto o de universidad, cada vez distinto (asignaturas al azar y días especiales).
--
-- DayPlans.generate(planId, rng) -> { TitleKey, Steps } con pasos normales de misión (Quests.luau).

local DayPlans = {}

local SCHOOL = require(script.Parent.Parent.Config).SchoolDay
local SchoolLife = require(script.Parent.SchoolLife)

-- Ninguna espera de un día de cole depende solo del reloj: como mucho estos minutos de juego
-- (en horario de clase el reloj va a Config.SchoolDay.ClockSpeed: 20 min de juego ≈ 40 s reales), y
-- además cada espera lleva MaxSeconds: pase lo que pase con el reloj, se acaba en ese tiempo real.
DayPlans.MaxWaitMinutes = 30
DayPlans.MaxWaitSeconds = 120

type Step = { [string]: any }

-- Llegar tarde: si tardas más de esto (segundos reales, sin contar cuando el cole está cerrado) en
-- llegar a la puerta, queda la marca y va a tu historial (ConductService: se entera tu familia)
DayPlans.LateSeconds = 240
local function late(): { [string]: any }
	return { After = DayPlans.LateSeconds, Flags = { "LlegasTardeAlCole" }, Conduct = "LlegarTarde" }
end

local function class(subject: string, mode: string, place: string, textKey: string?): Step
	return { Type = "Class", Subject = subject, Mode = mode, Place = place, TextKey = textKey or "QUEST.COLE.CLASE" }
end

local function pick<T>(rng: Random, list: { T }): T
	return list[rng:NextInteger(1, #list)]
end

-- Elige n elementos distintos
local function pickMany<T>(rng: Random, list: { T }, n: number): { T }
	local pool = table.clone(list)
	local out = {}
	for _ = 1, math.min(n, #pool) do
		table.insert(out, table.remove(pool, rng:NextInteger(1, #pool)))
	end
	return out
end

---------------------------------------------------------------------
-- Colegio (niño)
---------------------------------------------------------------------
local SCHOOL_SUBJECTS = {
	{ "Matematicas", "Aula" },
	{ "Lengua", "Aula" },
	{ "Ciencias", "Aula" },
	{ "Historia", "Aula" },
	{ "Arte", "Aula" },
	{ "Musica", "AulaMusica" },
}
local FRIENDS = { "Nico", "Sara", "Omar" }
local FRIEND_TEXT = { Nico = "QUEST.COLE.HABLA_NICO", Sara = "QUEST.COLE.HABLA_SARA", Omar = "QUEST.COLE.HABLA_OMAR" }
local LUNCH_TEXT = { Nico = "QUEST.COLE.COME_NICO", Sara = "QUEST.COLE.COME_SARA", Omar = "QUEST.COLE.COME_OMAR" }

-- La comida en el comedor (de 14:00 a 15:00), como una escena de verdad:
--   1) vas al comedor: tus compañeros ya están sentados comiendo y la profe de guardia vigila
--   2) coges tu bandeja en la barra ("Coger comida"; si no lo haces en un rato, la historia sigue)
--   3) te sientas con tu amigo del día y habláis (conversación corta)
--   4) terminas de comer hasta que vuelven las clases (como mucho unos minutos de juego)
local function lunch(steps: { Step }, friend: string, school: string)
	local actors = SchoolLife.lunchActors(friend, school)
	local instituto = school == "Instituto"
	table.insert(steps, { Type = "Reach", Place = if instituto then "ComedorInstituto" else "ComedorColegio", TextKey = "QUEST.COLE.COMEDOR", Actors = actors })
	table.insert(steps, {
		Type = "Event", Event = "SchoolMeal", Place = if instituto then "BarraInstituto" else "BarraComedor",
		TextKey = "QUEST.COLE.BANDEJA", Actors = actors, Timeout = { After = 75 },
	})
	table.insert(steps, { Type = "Talk", Npc = friend, Dialogue = "Comida_" .. friend, TextKey = LUNCH_TEXT[friend], Actors = actors })
	table.insert(steps, { Type = "Wait", UntilHour = SCHOOL.LunchTo, GameMinutes = 20, MaxSeconds = 60, TextKey = "QUEST.COLE.COMIENDO", Actors = actors })
end

-- Recreo: el amigo del día te espera en el patio (va andando desde donde esté) y habláis un momento
local function recess(steps: { Step }, friend: string, school: string, reach: boolean?)
	local patio = if school == "Instituto" then "PatioInstituto" else "Patio"
	if reach then
		table.insert(steps, { Type = "Reach", Place = patio, TextKey = "QUEST.PRIMER_DIA.RECREO", Actors = SchoolLife.recessActors(friend, school) })
	end
	table.insert(steps, {
		Type = "Talk", Npc = friend, Place = patio, Dialogue = "Recreo_" .. friend, TextKey = FRIEND_TEXT[friend],
		Actors = SchoolLife.recessActors(friend, school),
	})
end

local function schoolDay(rng: Random)
	local roll = rng:NextNumber()
	local steps: { Step } = { { Type = "Reach", Place = "EntradaColegio", TextKey = "QUEST.DIA.LLEGA_COLE", Late = late() } }
	local title = "QUEST.DIA_COLE.TITLE"
	local subjects = pickMany(rng, SCHOOL_SUBJECTS, 3)
	if roll < 0.15 then
		-- Día de deporte
		title = "QUEST.DIA_DEPORTE.TITLE"
		table.insert(steps, class("EducacionFisica", "Circuito", "Pista", "QUEST.COLE.EF"))
		table.insert(steps, class("EducacionFisica", "Circuito", "Pista", "QUEST.DIA.PARTIDO"))
		table.insert(steps, class(subjects[1][1], "Clase", subjects[1][2]))
	elseif roll < 0.27 then
		-- Examen sorpresa
		title = "QUEST.DIA_EXAMEN.TITLE"
		table.insert(steps, class(subjects[1][1], "Clase", subjects[1][2]))
		table.insert(steps, class(subjects[2][1], "Examen", subjects[2][2], "QUEST.COLE.EXAMEN"))
	elseif roll < 0.37 then
		-- Excursión por el barrio
		title = "QUEST.DIA_EXCURSION.TITLE"
		local destination = pick(rng, { "Parque", "Bomberos", "CentroSalud", "Columpios" })
		table.insert(steps, { Type = "Reach", Place = destination, TextKey = "QUEST.DIA.EXCURSION" })
		table.insert(steps, { Type = "Wait", GameMinutes = 30, MaxSeconds = 90, TextKey = "QUEST.DIA.EXCURSION_DISFRUTA" })
		table.insert(steps, class(subjects[1][1], "Clase", subjects[1][2]))
	elseif roll < 0.47 then
		-- Día con recado a la vuelta
		title = "QUEST.DIA_RECADO.TITLE"
		table.insert(steps, class(subjects[1][1], "Clase", subjects[1][2]))
		table.insert(steps, class(subjects[2][1], "Clase", subjects[2][2]))
		local shop = pick(rng, { "Libreria", "Farmacia", "Heladeria" })
		table.insert(steps, { Type = "Event", Event = "BoughtItem", Match = { ShopId = shop }, Place = shop, TextKey = "QUEST.DIA.RECADO" })
	else
		-- Día normal
		table.insert(steps, class(subjects[1][1], "Clase", subjects[1][2]))
		table.insert(steps, class(subjects[2][1], "Clase", subjects[2][2]))
	end
	-- Recreo con un amigo
	local friend = pick(rng, FRIENDS)
	recess(steps, friend, "Colegio", true)
	-- Comida en el comedor (de 14:00 a 15:00) y clases de la tarde hasta las 17:00
	lunch(steps, friend, "Colegio")
	table.insert(steps, class(subjects[3][1], "Clase", subjects[3][2], "QUEST.COLE.TARDE"))
	table.insert(steps, { Type = "Wait", UntilHour = SCHOOL.End, GameMinutes = 30, MaxSeconds = 90, TextKey = "QUEST.COLE.ULTIMA_HORA" })
	table.insert(steps, { Type = "Reach", Place = "CasaFamiliar", TextKey = "QUEST.PRIMER_DIA.VOLVER" })
	return { TitleKey = title, Steps = steps }
end

---------------------------------------------------------------------
-- Instituto (adolescente)
---------------------------------------------------------------------
local HIGH_SUBJECTS = { "HistoriaInstituto", "MatematicasInstituto", "Tecnologia" }

local function highSchoolDay(rng: Random)
	local roll = rng:NextNumber()
	local steps: { Step } = { { Type = "Reach", Place = "Instituto", TextKey = "QUEST.DIA.LLEGA_INSTITUTO", Late = late() } }
	local title = "QUEST.DIA_INSTITUTO.TITLE"
	local subjects = pickMany(rng, HIGH_SUBJECTS, 3)
	local work = false
	if roll < 0.2 then
		title = "QUEST.DIA_TRABAJO.TITLE"
		table.insert(steps, class(subjects[1], "Clase", "AulaInstituto"))
		work = true -- el trabajo, al salir de clase (abajo)
	elseif roll < 0.35 then
		title = "QUEST.DIA_ENTRENO.TITLE"
		table.insert(steps, class("EducacionFisica", "Circuito", "PistaInstituto", "QUEST.DIA.ENTRENO"))
		table.insert(steps, class(subjects[1], "Clase", "AulaInstituto"))
	elseif roll < 0.5 then
		title = "QUEST.DIA_EXAMEN.TITLE"
		table.insert(steps, class(subjects[1], "Estudio", "AulaInstituto", "QUEST.DIA.REPASO"))
		table.insert(steps, class(subjects[1], "Examen", "AulaInstituto", "QUEST.COLE.EXAMEN"))
	else
		table.insert(steps, class(subjects[1], "Clase", "AulaInstituto"))
		table.insert(steps, class(subjects[2], "Clase", "AulaInstituto"))
	end
	local friend = pick(rng, FRIENDS)
	recess(steps, friend, "Instituto")
	-- Comida en el comedor del instituto con el grupo
	lunch(steps, friend, "Instituto")
	table.insert(steps, class(subjects[3], "Clase", "AulaInstituto"))
	if work then
		-- Después de la última clase, a trabajar. Schedule = false: no es un paso del instituto (antes iba
		-- entre clases y a las 17:00, al cerrar el instituto, el día desaparecía de la lista)
		table.insert(steps, { Type = "Event", Event = "JobTaskDone", Count = 2, TextKey = "QUEST.DIA.TRABAJO", Schedule = false })
	end
	return { TitleKey = title, Steps = steps }
end

---------------------------------------------------------------------
-- Universidad (adulto joven). "$Carrera.X" se resuelve con la carrera elegida.
---------------------------------------------------------------------
local function universityDay(rng: Random)
	local roll = rng:NextNumber()
	local first = pick(rng, { "$Carrera.Asignatura1", "$Carrera.Asignatura2" })
	local second = if first == "$Carrera.Asignatura1" then "$Carrera.Asignatura2" else "$Carrera.Asignatura1"
	local steps: { Step } = { { Type = "Reach", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.BUSCA_FACULTAD" } }
	local title = "QUEST.DIA_UNI.TITLE"
	if roll < 0.2 then
		title = "QUEST.DIA_UNI_TRABAJO.TITLE"
		table.insert(steps, class(first, "Clase", "$Carrera.Facultad", "QUEST.UNI.CLASE"))
		table.insert(steps, { Type = "Event", Event = "JobTaskDone", Count = 2, TextKey = "QUEST.UNI.TRABAJO_PARCIAL" })
	elseif roll < 0.35 then
		title = "QUEST.DIA_UNI_PARTIDO.TITLE"
		table.insert(steps, class(first, "Clase", "$Carrera.Facultad", "QUEST.UNI.CLASE"))
		table.insert(steps, { Type = "Reach", Place = "EstadioUniversitario", TextKey = "QUEST.UNI.PARTIDO" })
		table.insert(steps, { Type = "Wait", GameMinutes = 40, MaxSeconds = 90, TextKey = "QUEST.UNI.ANIMA" })
	elseif roll < 0.5 then
		title = "QUEST.DIA_UNI_PARCIAL.TITLE"
		table.insert(steps, class(first, "Estudio", "Biblioteca", "QUEST.UNI.ESTUDIA"))
		table.insert(steps, class(first, "Examen", "$Carrera.Facultad", "QUEST.UNI.EXAMEN"))
	else
		table.insert(steps, class(first, "Clase", "$Carrera.Facultad", "QUEST.UNI.CLASE"))
		table.insert(steps, class(second, "Clase", "$Carrera.Facultad", "QUEST.UNI.CLASE"))
	end
	table.insert(steps, class(second, "Estudio", "Biblioteca", "QUEST.UNI.ESTUDIA"))
	return { TitleKey = title, Steps = steps }
end

---------------------------------------------------------------------
-- Vida adulta: un día normal (trabajo, recados o una tarde libre). Sin horario: uno por día de juego.
---------------------------------------------------------------------
local function adultDay(rng: Random)
	local roll = rng:NextNumber()
	local steps: { Step } = {}
	local title
	if roll < 0.5 then
		title = "Un día de trabajo"
		table.insert(steps, { Type = "Event", Event = "JobTaskDone", Count = 3, Text = "Trabaja: haz 3 tareas de tu trabajo ({count}/{total}) · los tablones de «Trabajar» están por toda la ciudad" })
		table.insert(steps, { Type = "Event", Event = "Ate", Text = "Después del trabajo, come algo" })
	elseif roll < 0.75 then
		title = "Día de recados"
		table.insert(steps, { Type = "Event", Event = "BoughtItem", Text = "Haz la compra: compra algo en una tienda" })
		table.insert(steps, { Type = "Event", Event = "Ate", Text = "Come algo en casa o fuera" })
	else
		title = "Tarde libre"
		local place = pick(rng, { "Playa", "Parque" })
		table.insert(steps, { Type = "Reach", Place = place, Text = "Tarde libre: ve a {place}" })
		table.insert(steps, { Type = "Wait", GameMinutes = 30, MaxSeconds = 90, Text = "Disfruta de la tarde (Cosme sigue en su garaje, por si te aburres)" })
	end
	return { TitleKey = title, Steps = steps }
end

DayPlans.Plans = {
	SchoolDay = schoolDay,
	HighSchoolDay = highSchoolDay,
	UniversityDay = universityDay,
	AdultDay = adultDay,
}

function DayPlans.generate(planId: string, rng: Random): { TitleKey: string, Steps: { Step } }?
	local plan = DayPlans.Plans[planId]
	return plan and plan(rng)
end

return DayPlans
