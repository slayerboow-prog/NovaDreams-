-- Quests: las misiones de la historia de vida, escritas como datos.
-- Para el jugador no son "misiones": son cosas que le pasan en su vida. Por eso al terminar no sale
-- "MISIÓN COMPLETADA +100 XP", sino un Momento ("Has terminado tu primer día de colegio").
--
-- Campos de una misión:
--   Kind       "Main" (capítulo) o "Side" (secundaria)
--   TitleKey   título en la tarjeta de objetivo
--   Requires   requisitos (ver Conditions.luau). Si solo falla la hora, la misión "espera".
--   Offer      (solo Side) cuándo se ofrece: { Place = "Colegio" } al llegar, o { Event = "...", Match = {...} }
--   OfferKey   (solo Side) quién te la pide y qué dice ("¿Me ayudas a buscar mi mochila?")
--   Repeatable / Cooldown (segundos reales) para secundarias que pueden repetirse
--   Steps      pasos en orden. Tipos:
--     Reach      { Place }                         ir a un lugar de Locations
--     Event      { Event, Match?, Count? }         que ocurra algo en otro sistema (trabajar, comer, dormir...)
--     Talk       { Npc, Place? }                   hablar con un personaje (Place: la línea guía lleva hasta él)
--     Choice     { Key, PromptKey, Options }       una decisión; se guarda en Choices[Key]
--     Wait       { GameMinutes }                   dejar pasar tiempo de juego
--     Group      { Steps }                         varios objetivos en cualquier orden
--     Moment     { }                               un momento narrativo que se muestra y sigue
--     Transition { Seconds?, SetStage?, Cinematic? } pantalla "Han pasado varios años…" (y cambio de etapa);
--                                                  con Cinematic, en vez de la pantalla se ve esa escena de cámara
--     Cinematic  { Id }                            una escena de cámara (Cinematics.luau); la historia sigue al acabar
--   Cada paso puede llevar If = { requisitos } para saltarse si no se cumplen (ramas por decisiones).
--   Rewards    { Money?, Flags?, Remember? = { { Npc, Fact } }, SetStage? }
--   MomentKey  el acontecimiento de vida que se muestra y se guarda en la biografía al terminar
--   MomentSting efecto de sonido del momento (Config.Audio.Stings); por defecto "Momento", false = ninguno

export type Step = { [string]: any }
export type Quest = {
	Kind: "Main" | "Side",
	TitleKey: string,
	Requires: { [string]: any }?,
	Offer: { [string]: any }?,
	OfferKey: string?,
	Repeatable: boolean?,
	Cooldown: number?,
	Steps: { Step },
	Rewards: { [string]: any }?,
	MomentKey: string?,
	MomentSting: (string | boolean)?,
	DayPlan: string?, -- día generado (DayPlans.luau): los pasos se crean al empezar
	-- Misiones episódicas (Misiones/*.luau, docs/historia/11): escenas, diálogos y minijuegos
	Title: string?,
	Moment: string?,
	Memory: string?,
	Props: { [string]: any }?,
	Actors: { { [string]: any } }?,
	Dialogues: { [string]: any }?,
}

local Quests: { [string]: Quest } = {
	-----------------------------------------------------------------
	-- FASE 2 · BEBÉ (5-10 min) en la casa familiar. Los eventos Baby* los emite BabyService.
	-- Enseña: moverse, interactuar, la línea guía, las necesidades, la familia y la ciudad.
	-----------------------------------------------------------------
	Bebe_AprendeACaminar = {
		Kind = "Main",
		TitleKey = "QUEST.BEBE_CAMINAR.TITLE",
		Steps = {
			{ Type = "Event", Event = "BabyStood", TextKey = "QUEST.BEBE_CAMINAR.S1" },
			{ Type = "Event", Event = "BabySteps", Count = 5, TextKey = "QUEST.BEBE_CAMINAR.S2" },
			{ Type = "Talk", Npc = "Familia_Abu", Place = "FamiliaAbu", TextKey = "QUEST.BEBE_CAMINAR.S3" },
			{ Type = "Cinematic", Id = "Bebe_PrimerosPasos" },
		},
		MomentKey = "MOMENT.PRIMEROS_PASOS",
		MomentSting = false, -- la cinemática ya tiene su música
	},
	Bebe_ExploraLaCasa = {
		Kind = "Main",
		TitleKey = "QUEST.BEBE_CASA.TITLE",
		Requires = { Completed = { "Bebe_AprendeACaminar" } },
		Steps = {
			{
				Type = "Group",
				TextKey = "QUEST.BEBE_CASA.S1",
				Steps = {
					{ Type = "Reach", Place = "HomeCocina", TextKey = "QUEST.BEBE_CASA.COCINA" },
					{ Type = "Event", Event = "BabyInteract", Match = { Object = "Tele" }, TextKey = "QUEST.BEBE_CASA.TELE" },
					{ Type = "Event", Event = "BabyInteract", Match = { Object = "Juguetes" }, TextKey = "QUEST.BEBE_CASA.JUGUETES" },
				},
			},
			{ Type = "Talk", Npc = "Familia_Padre", Place = "FamiliaPadre", TextKey = "QUEST.BEBE_CASA.S2" },
		},
		MomentKey = "MOMENT.CONOCES_FAMILIA",
	},
	Bebe_HoraDeSalir = {
		Kind = "Main",
		TitleKey = "QUEST.BEBE_SALIR.TITLE",
		Requires = { Completed = { "Bebe_ExploraLaCasa" } },
		Steps = {
			{ Type = "Event", Event = "LookedOutside", Place = "Ventanal", TextKey = "QUEST.BEBE_SALIR.S1" },
			{ Type = "Transition", Seconds = 5, SetStage = "Nino", TextKey = "TRANSITION.ANOS_DESPUES", Cinematic = "Bebe_AnosDespues" },
		},
		MomentKey = "MOMENT.YA_ERES_NINO",
	},

	-----------------------------------------------------------------
	-- NIÑO · EL COLEGIO (unas 5 horas: estos grandes momentos + días de cole generados). Las clases se juegan (ClassService):
	-- preguntas, notas, Educación Física en la pista. Recreo con Nico, Sara y Omar (SchoolService).
	-----------------------------------------------------------------
	Nino_Recados = {
		Kind = "Main",
		TitleKey = "QUEST.RECADOS.TITLE",
		Requires = { Completed = { "Cole06_Examen" }, StageProgress = 0.36 },
		Steps = {
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Libreria" }, Place = "Libreria", TextKey = "QUEST.RECADOS.MATERIAL" },
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Farmacia" }, Place = "Farmacia", TextKey = "QUEST.RECADOS.MEDICINAS" },
			{ Type = "Reach", Place = "CasaFamiliar", TextKey = "QUEST.RECADOS.VOLVER" },
		},
		Rewards = { Money = 25 },
		MomentKey = "MOMENT.PRIMEROS_RECADOS",
	},
	Nino_Excursion = {
		Kind = "Main",
		TitleKey = "QUEST.EXCURSION.TITLE",
		Requires = { Completed = { "Nino_Recados" }, StageProgress = 0.5 },
		Steps = {
			{ Type = "Reach", Place = "Bomberos", TextKey = "QUEST.EXCURSION.IR" },
			{ Type = "Wait", GameMinutes = 45, TextKey = "QUEST.EXCURSION.MIRA" },
			{ Type = "Moment", TextKey = "MOMENT.CAMION_BOMBEROS" },
			{ Type = "Class", Subject = "EducacionFisica", Mode = "Circuito", Place = "Pista", TextKey = "QUEST.EXCURSION.PARTIDO" },
		},
		MomentKey = "MOMENT.EXCURSION",
	},
	Nino_SegundoTrimestre = {
		Kind = "Main",
		TitleKey = "QUEST.TRIMESTRE.TITLE",
		Requires = { Completed = { "Nino_Excursion" }, StageProgress = 0.7 },
		Steps = {
			{ Type = "Class", Subject = "Historia", Mode = "Clase", Place = "Aula", TextKey = "QUEST.TRIMESTRE.HISTORIA" },
			{ Type = "Class", Subject = "Lengua", Mode = "Clase", Place = "Aula", TextKey = "QUEST.COLE.CLASE" },
			{ Type = "Talk", Npc = "Sara", Place = "Patio", TextKey = "QUEST.TRIMESTRE.SARA" },
			{ Type = "Class", Subject = "Ciencias", Mode = "Estudio", Place = "Aula", TextKey = "QUEST.TRIMESTRE.PROYECTO" },
			{ Type = "Class", Subject = "Musica", Mode = "Examen", Place = "AulaMusica", TextKey = "QUEST.TRIMESTRE.CONCIERTO" },
		},
		Rewards = { Money = 15 },
		MomentKey = "MOMENT.PROYECTO_SARA",
	},
	Nino_FinDePrimaria = {
		Kind = "Main",
		TitleKey = "QUEST.FIN_PRIMARIA.TITLE",
		Requires = { Completed = { "Nino_SegundoTrimestre" }, StageProgress = 0.94 },
		Steps = {
			{ Type = "Class", Subject = "Lengua", Mode = "Examen", Place = "Aula", TextKey = "QUEST.COLE.EXAMEN" },
			{ Type = "Class", Subject = "Matematicas", Mode = "Examen", Place = "Aula", TextKey = "QUEST.COLE.EXAMEN" },
			{ Type = "Reach", Place = "Patio", TextKey = "QUEST.FIN_PRIMARIA.FIESTA" },
			{
				Type = "Group",
				TextKey = "QUEST.FIN_PRIMARIA.DESPIDE",
				Steps = {
					{ Type = "Talk", Npc = "Nico", TextKey = "QUEST.COLE.HABLA_NICO" },
					{ Type = "Talk", Npc = "Sara", TextKey = "QUEST.COLE.HABLA_SARA" },
					{ Type = "Talk", Npc = "Omar", TextKey = "QUEST.COLE.HABLA_OMAR" },
				},
			},
			{ Type = "Cinematic", Id = "Nino_FinPrimaria" },
			{ Type = "Transition", SetStage = "Adolescente", TextKey = "TRANSITION.INSTITUTO", Cinematic = "Nino_AInstituto" },
		},
		Rewards = { Money = 30 },
		MomentKey = "MOMENT.FIN_PRIMARIA",
		MomentSting = false,
	},

	-- Día normal de cole (se repite entre los grandes momentos; los pasos los genera DayPlans)
	Nino_Jornada = {
		Kind = "Main",
		TitleKey = "QUEST.DIA_COLE.TITLE",
		DayPlan = "SchoolDay",
		Repeatable = true,
		Steps = {},
		MomentKey = "MOMENT.DIA_COLE",
		MomentSting = false,
	},

	-----------------------------------------------------------------
	-- ADOLESCENTE · EL INSTITUTO (unas 5 horas): nuevo instituto, primer trabajo y decidir el futuro
	-----------------------------------------------------------------
	Adol_NuevoInstituto = {
		Kind = "Main",
		TitleKey = "QUEST.INSTITUTO.TITLE",
		Steps = {
			{ Type = "Event", Event = "Traveled", Match = { Town = "Campus Valmar" }, Place = "ParadaBus", TextKey = "QUEST.INSTITUTO.BUS" },
			{ Type = "Reach", Place = "Instituto", TextKey = "QUEST.INSTITUTO.BUSCA" },
			{ Type = "Class", Subject = "HistoriaInstituto", Mode = "Clase", Place = "AulaInstituto", TextKey = "QUEST.COLE.CLASE" },
			{ Type = "Class", Subject = "MatematicasInstituto", Mode = "Clase", Place = "AulaInstituto", TextKey = "QUEST.COLE.CLASE" },
		},
		MomentKey = "MOMENT.NUEVO_INSTITUTO",
	},
	Adol_PrimerTrabajo = {
		Kind = "Main",
		TitleKey = "QUEST.VERANO.TITLE",
		Requires = { Completed = { "Adol_NuevoInstituto" }, StageProgress = 0.35 },
		Steps = {
			{ Type = "Event", Event = "JobTaskDone", Count = 3, TextKey = "QUEST.VERANO.TRABAJA" },
		},
		Rewards = { Money = 50 },
		MomentKey = "MOMENT.PRIMER_TRABAJO",
	},
	Adol_ElFuturo = {
		Kind = "Main",
		TitleKey = "QUEST.FUTURO.TITLE",
		Requires = { Completed = { "Adol_PrimerTrabajo" }, StageProgress = 0.93 },
		Steps = {
			{ Type = "Class", Subject = "Tecnologia", Mode = "Examen", Place = "AulaInstituto", TextKey = "QUEST.COLE.EXAMEN" },
			{ Type = "Reach", Place = "Universidad", TextKey = "QUEST.FUTURO.VISITA" },
			{
				Type = "Choice",
				Key = "Estudios",
				PromptKey = "QUEST.FUTURO.PREGUNTA",
				TextKey = "QUEST.FUTURO.DECIDE",
				Options = {
					{ Id = "Medicina", TextKey = "QUEST.FUTURO.OPT_MEDICINA", Flags = { "VaALaUniversidad" } },
					{ Id = "Ingenieria", TextKey = "QUEST.FUTURO.OPT_INGENIERIA", Flags = { "VaALaUniversidad" } },
					{ Id = "Derecho", TextKey = "QUEST.FUTURO.OPT_DERECHO", Flags = { "VaALaUniversidad" } },
					{ Id = "Economia", TextKey = "QUEST.FUTURO.OPT_ECONOMIA", Flags = { "VaALaUniversidad" } },
					{ Id = "Trabajar", TextKey = "QUEST.FUTURO.OPT_TRABAJAR", Flags = { "EmpiezaATrabajar" } },
				},
			},
			{ Type = "Transition", SetStage = "AdultoJoven", TextKey = "TRANSITION.MAYOR_EDAD", Cinematic = "Adol_Selectividad" },
		},
		MomentKey = "MOMENT.DECIDES_FUTURO",
		MomentSting = false,
	},

	Adol_Jornada = {
		Kind = "Main",
		TitleKey = "QUEST.DIA_INSTITUTO.TITLE",
		DayPlan = "HighSchoolDay",
		Repeatable = true,
		Steps = {},
		MomentKey = "MOMENT.DIA_INSTITUTO",
		MomentSting = false,
	},

	-----------------------------------------------------------------
	-- UNIVERSIDAD (unas 5 horas). "$Carrera.X" = lo de la carrera que elegiste (Subjects.Degrees)
	-----------------------------------------------------------------
	Uni_PrimerDia = {
		Kind = "Main",
		TitleKey = "QUEST.UNI_DIA1.TITLE",
		Steps = {
			{ Type = "Reach", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.BUSCA_FACULTAD" },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Clase", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CLASE" },
			{ Type = "Reach", Place = "Biblioteca", TextKey = "QUEST.UNI.DESCUBRE_BIBLIOTECA" },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Estudio", Place = "Biblioteca", TextKey = "QUEST.UNI.ESTUDIA" },
		},
		MomentKey = "MOMENT.UNI_EMPIEZA",
	},
	Uni_PrimerSemestre = {
		Kind = "Main",
		TitleKey = "QUEST.UNI_SEM1.TITLE",
		Requires = { Completed = { "Uni_PrimerDia" }, StageProgress = 0.15 },
		Steps = {
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Clase", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CLASE" },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Clase", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CLASE" },
			{ Type = "Event", Event = "JobTaskDone", Count = 2, TextKey = "QUEST.UNI.TRABAJO_PARCIAL" },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", TextKey = "QUEST.UNI.ESTUDIA" },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Examen", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.EXAMEN" },
		},
		Rewards = { Money = 100 },
		MomentKey = "MOMENT.UNI_SEMESTRE1",
	},
	Uni_SegundoSemestre = {
		Kind = "Main",
		TitleKey = "QUEST.UNI_SEM2.TITLE",
		Requires = { Completed = { "Uni_PrimerSemestre" }, StageProgress = 0.35 },
		Steps = {
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Clase", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CLASE" },
			{ Type = "Reach", Place = "EstadioUniversitario", TextKey = "QUEST.UNI.PARTIDO" },
			{ Type = "Wait", GameMinutes = 40, TextKey = "QUEST.UNI.ANIMA" },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Clase", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CLASE" },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", TextKey = "QUEST.UNI.ESTUDIA" },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Examen", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.EXAMEN" },
		},
		Rewards = { Money = 100 },
		MomentKey = "MOMENT.UNI_SEMESTRE2",
	},
	Uni_Practicas = {
		Kind = "Main",
		TitleKey = "QUEST.UNI_PRACTICAS.TITLE",
		Requires = { Completed = { "Uni_SegundoSemestre" }, StageProgress = 0.55 },
		Steps = {
			{ Type = "Reach", Place = "$Carrera.LugarPracticas", TextKey = "QUEST.UNI.PRACTICAS_IR" },
			{ Type = "Class", Subject = "$Carrera.Practica", Mode = "Practica", Place = "$Carrera.LugarPracticas", TextKey = "QUEST.UNI.PRACTICAS_DIA1" },
			{ Type = "Class", Subject = "$Carrera.Practica", Mode = "Practica", Place = "$Carrera.LugarPracticas", TextKey = "QUEST.UNI.PRACTICAS_DIA2" },
		},
		Rewards = { Money = 150 },
		MomentKey = "MOMENT.UNI_PRACTICAS",
	},
	Uni_TercerSemestre = {
		Kind = "Main",
		TitleKey = "QUEST.UNI_SEM3.TITLE",
		Requires = { Completed = { "Uni_Practicas" }, StageProgress = 0.75 },
		Steps = {
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Clase", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CLASE" },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Clase", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CLASE" },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Estudio", Place = "Biblioteca", TextKey = "QUEST.UNI.ESTUDIA" },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Examen", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.EXAMEN" },
		},
		Rewards = { Money = 100 },
		MomentKey = "MOMENT.UNI_SEMESTRE3",
	},
	Uni_Graduacion = {
		Kind = "Main",
		TitleKey = "QUEST.UNI_GRADUACION.TITLE",
		Requires = { Completed = { "Uni_TercerSemestre" }, StageProgress = 0.93 },
		Steps = {
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", TextKey = "QUEST.UNI.REPASO" },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Examen", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.EXAMEN_FINAL" },
			{ Type = "Reach", Place = "$Carrera.Facultad", TextKey = "QUEST.UNI.CEREMONIA" },
			{ Type = "Cinematic", Id = "Uni_Graduacion" },
		},
		Rewards = { Money = 500, Degree = "$Carrera.Titulo", Flags = { "Graduado" } },
		MomentKey = "MOMENT.GRADUADO",
		MomentSting = false,
	},

	Uni_Jornada = {
		Kind = "Main",
		TitleKey = "QUEST.DIA_UNI.TITLE",
		DayPlan = "UniversityDay",
		Repeatable = true,
		Steps = {},
		MomentKey = "MOMENT.DIA_UNI",
		MomentSting = false,
	},

	-----------------------------------------------------------------
	-- PUENTE TEMPORAL DE NIÑO (hasta que existan las fases 4-8)
	-----------------------------------------------------------------
	Nino_TuBarrio = {
		Kind = "Main",
		TitleKey = "QUEST.BARRIO.TITLE",
		Steps = {
			{ Type = "Reach", Place = "Parque", TextKey = "QUEST.BARRIO.PARQUE" },
			{ Type = "Reach", Place = "Colegio", TextKey = "QUEST.BARRIO.COLEGIO" },
			{ Type = "Moment", TextKey = "MOMENT.TU_COLEGIO" },
			{ Type = "Transition", Seconds = 6, SetStage = "AdultoJoven", TextKey = "TRANSITION.CRECES", Cinematic = "Nino_Creces" },
		},
		MomentKey = "MOMENT.YA_ERES_ADULTO",
	},

	-----------------------------------------------------------------
	-- CAPÍTULO PUENTE (jugable ya): "Una nueva vida en Valmar"
	-----------------------------------------------------------------
	Adulto_LlegadaValmar = {
		Kind = "Main",
		TitleKey = "QUEST.LLEGADA.TITLE",
		Steps = {
			{ Type = "Reach", Place = "PlazaCentro", TextKey = "QUEST.LLEGADA.PLAZA" },
			{ Type = "Event", Event = "HomeClaimed", TextKey = "QUEST.LLEGADA.CASA" },
			{ Type = "Event", Event = "Ate", TextKey = "QUEST.LLEGADA.COMER" },
		},
		Rewards = { Money = 100, Flags = { "TieneHogar" } },
		MomentKey = "MOMENT.PRIMER_HOGAR",
	},
	Adulto_PrimerSueldo = {
		Kind = "Main",
		TitleKey = "QUEST.SUELDO.TITLE",
		Requires = { Completed = { "Adulto_LlegadaValmar" } },
		Steps = {
			{ Type = "Event", Event = "JobTaskDone", Count = 3, TextKey = "QUEST.SUELDO.TRABAJA" },
		},
		Rewards = { Money = 150 },
		MomentKey = "MOMENT.PRIMER_SUELDO",
	},
	Adulto_ConoceLaRegion = {
		Kind = "Main",
		TitleKey = "QUEST.REGION.TITLE",
		Requires = { Completed = { "Adulto_PrimerSueldo" } },
		Steps = {
			{
				Type = "Choice",
				Key = "PrimeraExcursion",
				PromptKey = "QUEST.REGION.PREGUNTA",
				TextKey = "QUEST.REGION.DECIDE",
				Options = {
					{ Id = "Campus", TextKey = "QUEST.REGION.OPT_CAMPUS" },
					{ Id = "Playa", TextKey = "QUEST.REGION.OPT_PLAYA" },
					{ Id = "Campo", TextKey = "QUEST.REGION.OPT_CAMPO" },
				},
			},
			{ Type = "Reach", Place = "ParadaBus", TextKey = "QUEST.REGION.PARADA" },
			{ Type = "Reach", Place = "Universidad", TextKey = "QUEST.REGION.IR_CAMPUS", If = { Choices = { PrimeraExcursion = "Campus" } } },
			{ Type = "Reach", Place = "Playa", TextKey = "QUEST.REGION.IR_PLAYA", If = { Choices = { PrimeraExcursion = "Playa" } } },
			{ Type = "Reach", Place = "Granja", TextKey = "QUEST.REGION.IR_CAMPO", If = { Choices = { PrimeraExcursion = "Campo" } } },
		},
		Rewards = { Money = 100 },
		MomentKey = "MOMENT.CONOCES_REGION",
	},

	-----------------------------------------------------------------
	-- SECUNDARIAS (salen de lugares y de lo que haces; no todas están siempre)
	-----------------------------------------------------------------
	Side_MochilaPerdida = {
		Kind = "Side",
		TitleKey = "QUEST.MOCHILA.TITLE",
		Offer = { Place = "Colegio" },
		OfferKey = "QUEST.MOCHILA.OFFER",
		Requires = { Hours = { From = 8, To = 20 } },
		Steps = {
			{ Type = "Reach", Place = "Parque", TextKey = "QUEST.MOCHILA.BUSCA" },
			{ Type = "Reach", Place = "Colegio", TextKey = "QUEST.MOCHILA.DEVUELVE" },
		},
		Rewards = { Money = 40, Remember = { { Npc = "Lucia", Fact = "DevolvioMochila" } } },
		MomentKey = "MOMENT.AYUDASTE_NINO",
	},
	Side_MedicinasUrgentes = {
		Kind = "Side",
		TitleKey = "QUEST.MEDICINAS.TITLE",
		Offer = { Event = "JobTaskDone", Match = { JobId = "Repartidor" } },
		OfferKey = "QUEST.MEDICINAS.OFFER",
		Repeatable = true,
		Cooldown = 1800,
		Requires = { Hours = { From = 8, To = 21 } },
		Steps = {
			{ Type = "Reach", Place = "CentroSalud", TextKey = "QUEST.MEDICINAS.LLEVA" },
		},
		Rewards = { Money = 60 },
		MomentKey = "MOMENT.MEDICINAS",
	},
	Side_TardeDePlaya = {
		Kind = "Side",
		TitleKey = "QUEST.PLAYA.TITLE",
		Offer = { Place = "Playa" },
		OfferKey = "QUEST.PLAYA.OFFER",
		Requires = { Hours = { From = 10, To = 21 } },
		Steps = {
			{ Type = "Event", Event = "Ate", TextKey = "QUEST.PLAYA.MERIENDA" },
			{ Type = "Wait", GameMinutes = 60, TextKey = "QUEST.PLAYA.ATARDECER" },
		},
		Rewards = { Flags = { "TardeDePlaya" } },
		MomentKey = "MOMENT.TARDE_PLAYA",
	},
}

-- Misiones episódicas: un archivo por misión (Misiones/*.luau, listadas en MissionIndex)
for _, entry in require(script.Parent.MissionIndex) do
	for _, mission in (if entry.Id then { entry } else entry) do
		mission.Kind = mission.Kind or "Main"
		mission.TitleKey = mission.TitleKey or mission.Title
		mission.MomentKey = mission.MomentKey or mission.Moment
		Quests[mission.Id] = mission
	end
end

return Quests
