-- DayPlans: los "días normales" que llenan cada etapa entre los grandes momentos de la historia.
-- Cada etapa dura unas horas (Config.LifeStory.StageHours). Los momentos clave (primer día, excursión,
-- exámenes, graduación…) se reparten por esas horas, y entre uno y otro se juegan días generados:
-- un día de cole, de instituto o de universidad, cada vez distinto (asignaturas al azar y días especiales).
--
-- DayPlans.generate(planId, rng) -> { TitleKey, Steps } con pasos normales de misión (Quests.luau).

local DayPlans = {}

type Step = { [string]: any }

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

local function schoolDay(rng: Random)
	local roll = rng:NextNumber()
	local steps: { Step } = { { Type = "Reach", Place = "EntradaColegio", TextKey = "QUEST.DIA.LLEGA_COLE" } }
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
		table.insert(steps, { Type = "Wait", GameMinutes = 40, TextKey = "QUEST.DIA.EXCURSION_DISFRUTA" })
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
	-- Recreo con un amigo y última clase
	local friend = pick(rng, FRIENDS)
	table.insert(steps, { Type = "Reach", Place = "Patio", TextKey = "QUEST.PRIMER_DIA.RECREO" })
	table.insert(steps, { Type = "Talk", Npc = friend, Place = "Patio", TextKey = FRIEND_TEXT[friend] })
	if #steps < 7 then
		table.insert(steps, class(subjects[3][1], "Clase", subjects[3][2]))
	end
	table.insert(steps, { Type = "Reach", Place = "CasaFamiliar", TextKey = "QUEST.PRIMER_DIA.VOLVER" })
	return { TitleKey = title, Steps = steps }
end

---------------------------------------------------------------------
-- Instituto (adolescente)
---------------------------------------------------------------------
local HIGH_SUBJECTS = { "HistoriaInstituto", "MatematicasInstituto", "Tecnologia" }

local function highSchoolDay(rng: Random)
	local roll = rng:NextNumber()
	local steps: { Step } = { { Type = "Reach", Place = "Instituto", TextKey = "QUEST.DIA.LLEGA_INSTITUTO" } }
	local title = "QUEST.DIA_INSTITUTO.TITLE"
	local subjects = pickMany(rng, HIGH_SUBJECTS, 3)
	if roll < 0.2 then
		title = "QUEST.DIA_TRABAJO.TITLE"
		table.insert(steps, class(subjects[1], "Clase", "AulaInstituto"))
		table.insert(steps, { Type = "Event", Event = "JobTaskDone", Count = 2, TextKey = "QUEST.DIA.TRABAJO" })
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
	table.insert(steps, { Type = "Talk", Npc = friend, Place = "PatioInstituto", TextKey = FRIEND_TEXT[friend] })
	table.insert(steps, class(subjects[3], "Clase", "AulaInstituto"))
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
		table.insert(steps, { Type = "Wait", GameMinutes = 40, TextKey = "QUEST.UNI.ANIMA" })
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

DayPlans.Plans = {
	SchoolDay = schoolDay,
	HighSchoolDay = highSchoolDay,
	UniversityDay = universityDay,
}

function DayPlans.generate(planId: string, rng: Random): { TitleKey: string, Steps: { Step } }?
	local plan = DayPlans.Plans[planId]
	return plan and plan(rng)
end

return DayPlans
