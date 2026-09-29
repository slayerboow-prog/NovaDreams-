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
--     Wait       { GameMinutes } o { UntilHour }  dejar pasar tiempo de juego (o esperar a una hora)
--     Group      { Steps }                         varios objetivos en cualquier orden
--     Moment     { }                               un momento narrativo que se muestra y sigue
--     Transition { Seconds?, SetStage?, Cinematic? } pantalla "Han pasado varios años…" (y cambio de etapa);
--                                                  con Cinematic, en vez de la pantalla se ve esa escena de cámara
--     Cinematic  { Id }                            una escena de cámara (Cinematics.luau); la historia sigue al acabar
--   Cada paso puede llevar If = { requisitos } para saltarse si no se cumplen (ramas por decisiones).
--   Rewards    { Money?, Flags?, Remember? = { { Npc, Fact } }, SetStage? }
--   MomentKey  el acontecimiento de vida que se muestra y se guarda en la biografía al terminar
--   MomentSting efecto de sonido del momento (Config.Audio.Stings); por defecto "Momento", false = ninguno

local SchoolLife = require(script.Parent.SchoolLife)

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
	Description: string?, -- quién te lo pide y por qué, en una frase sencilla (se ve al ofrecerla y al empezar)
	Type: string?,
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
		Description = "Acabas de nacer y tu familia te mira con ilusión. Hoy te toca levantarte y dar tus primeros pasos hasta tu abu.",
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
		Description = "Ya caminas. Tu casa está llena de cosas nuevas: la cocina, la tele, los juguetes… y tu familia quiere enseñártelas.",
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
		Description = "Por el ventanal se ve Valmar, la ciudad donde vas a crecer. Asómate: ahí fuera te espera tu vida.",
		Requires = { Completed = { "Bebe_ExploraLaCasa" } },
		Steps = {
			{ Type = "Event", Event = "LookedOutside", Place = "Ventanal", TextKey = "QUEST.BEBE_SALIR.S1" },
			-- (amanece: el primer día de cole empieza por la mañana, sin esperar a que abra el colegio)
			{ Type = "Transition", Seconds = 5, SetStage = "Nino", TextKey = "TRANSITION.ANOS_DESPUES", Cinematic = "Bebe_AnosDespues", Clock = 7.5 },
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
		Description = "Tu familia confía en ti: te pide que compres el material del cole y unas medicinas, y que vuelvas a casa.",
		Requires = { Completed = { "Cole06_Examen" }, StageProgress = 0.36 },
		Steps = {
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Libreria" }, Place = "Libreria", TextKey = "QUEST.RECADOS.MATERIAL" },
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Farmacia" }, Place = "Farmacia", TextKey = "QUEST.RECADOS.MEDICINAS" },
			{ Type = "Reach", Place = "CasaFamiliar", TextKey = "QUEST.RECADOS.VOLVER" },
		},
		Rewards = { Money = 25 },
		MomentKey = "MOMENT.PRIMEROS_RECADOS",
	},

	-- Día normal de cole (se repite entre los grandes momentos; los pasos los genera DayPlans)
	Nino_Jornada = {
		Kind = "Main",
		TitleKey = "QUEST.DIA_COLE.TITLE",
		Description = "Un día normal de cole: clases, recreo con tus amigos y vuelta a casa. Los días normales también cuentan.",
		DayPlan = "SchoolDay",
		Repeatable = true,
		Steps = {},
		Dialogues = SchoolLife.Dialogues, -- el recreo y la comida con tus compañeros
		MomentKey = "MOMENT.DIA_COLE",
		MomentSting = false,
	},

	-----------------------------------------------------------------
	-- ADOLESCENTE · EL INSTITUTO (unas 5 horas): las misiones están en Misiones/Ins*.luau; aquí, el día normal
	-----------------------------------------------------------------
	Adol_Jornada = {
		Kind = "Main",
		TitleKey = "QUEST.DIA_INSTITUTO.TITLE",
		Description = "Un día normal de instituto: clases, amigos y, a veces, algo que hacer después.",
		DayPlan = "HighSchoolDay",
		Repeatable = true,
		Steps = {},
		Dialogues = SchoolLife.Dialogues, -- el recreo y la comida con tus compañeros
		MomentKey = "MOMENT.DIA_INSTITUTO",
		MomentSting = false,
	},

	-----------------------------------------------------------------
	-- UNIVERSIDAD (unas 5 horas). "$Carrera.X" = lo de la carrera que elegiste (Subjects.Degrees)
	-----------------------------------------------------------------
	Uni_Jornada = {
		Kind = "Main",
		TitleKey = "QUEST.DIA_UNI.TITLE",
		Description = "Un día normal de universidad: clases de tu carrera, estudio y la vida del campus.",
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
		Description = "Ya eres mayor para salir a jugar. Conoce el parque y el colegio de tu barrio.",
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
		Description = "Acabas de llegar a Valmar para empezar una vida nueva. Necesitas un sitio donde vivir y algo que comer.",
		Steps = {
			{ Type = "Reach", Place = "PlazaCentro", TextKey = "QUEST.LLEGADA.PLAZA" },
			{ Type = "Event", Event = "HomeClaimed", TextKey = "QUEST.LLEGADA.CASA", If = { NotFlags = { "TieneHogar" } } }, -- si ya te independizaste en la universidad, no hace falta
			{ Type = "Event", Event = "Ate", TextKey = "QUEST.LLEGADA.COMER" },
		},
		Rewards = { Money = 100, Flags = { "TieneHogar" } },
		MomentKey = "MOMENT.PRIMER_HOGAR",
	},
	Adulto_PrimerSueldo = {
		Kind = "Main",
		TitleKey = "QUEST.SUELDO.TITLE",
		Description = "Para vivir en Valmar hace falta dinero. Busca un trabajo y gánate tu primer sueldo.",
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
		Description = "Valmar es mucho más que el centro. Elige a dónde ir de excursión y descubre la región.",
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
		Description = "Una niña ha perdido su mochila en el parque y está muy preocupada. Ayúdala a encontrarla.",
		Offer = { Place = "Colegio" },
		OfferKey = "QUEST.MOCHILA.OFFER",
		-- (de niño, y después de la mochila de Cole02: antes se ofrecía a adultos, o a la vez que la otra)
		Requires = { Stage = { Min = "Nino", Max = "Nino" }, Completed = { "Cole02_Mochila" }, Hours = { From = 8, To = 20 } },
		Steps = {
			{ Type = "Reach", Place = "Parque", TextKey = "QUEST.MOCHILA.BUSCA" },
			{ Type = "Reach", Place = "Colegio", TextKey = "QUEST.MOCHILA.DEVUELVE" },
		},
		Rewards = { Money = 15 },
		MomentKey = "MOMENT.AYUDASTE_NINO",
	},
	Side_MedicinasUrgentes = {
		Kind = "Side",
		TitleKey = "QUEST.MEDICINAS.TITLE",
		Description = "Alguien necesita sus medicinas hoy mismo. Correos te pide que lleves el paquete al centro de salud.",
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
		Description = "Hace buen día en Playa Dorada. Tómate un descanso: merienda algo y mira el atardecer.",
		Offer = { Place = "Playa" },
		OfferKey = "QUEST.PLAYA.OFFER",
		Requires = { Hours = { From = 18, To = 21 } },
		Steps = {
			{ Type = "Event", Event = "Ate", TextKey = "QUEST.PLAYA.MERIENDA" },
			{ Type = "Wait", GameMinutes = 60, MaxSeconds = 90, TextKey = "QUEST.PLAYA.ATARDECER" },
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
