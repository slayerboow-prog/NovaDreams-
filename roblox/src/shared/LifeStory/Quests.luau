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
--     Talk       { Npc }                           hablar con un personaje (lo emite el futuro sistema de NPC)
--     Choice     { Key, PromptKey, Options }       una decisión; se guarda en Choices[Key]
--     Wait       { GameMinutes }                   dejar pasar tiempo de juego
--     Group      { Steps }                         varios objetivos en cualquier orden
--     Moment     { }                               un momento narrativo que se muestra y sigue
--     Transition { Seconds?, SetStage? }           pantalla "Han pasado varios años…" (y cambio de etapa)
--   Cada paso puede llevar If = { requisitos } para saltarse si no se cumplen (ramas por decisiones).
--   Rewards    { Money?, Flags?, Remember? = { { Npc, Fact } }, SetStage? }
--   MomentKey  el acontecimiento de vida que se muestra y se guarda en la biografía al terminar

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
}

local Quests: { [string]: Quest } = {
	-----------------------------------------------------------------
	-- FASE 2 · BEBÉ (datos listos; el capítulo está desactivado hasta tener la casa de bebé)
	-- Los eventos "BabyStood", "RoomVisited"... los emitirá el controlador de bebé.
	-----------------------------------------------------------------
	Bebe_AprendeACaminar = {
		Kind = "Main",
		TitleKey = "QUEST.BEBE_CAMINAR.TITLE",
		Steps = {
			{ Type = "Event", Event = "BabyStood", TextKey = "QUEST.BEBE_CAMINAR.S1" },
			{ Type = "Event", Event = "BabySteps", Count = 5, TextKey = "QUEST.BEBE_CAMINAR.S2" },
			{ Type = "Talk", Npc = "Familia_Abu", TextKey = "QUEST.BEBE_CAMINAR.S3" },
		},
		MomentKey = "MOMENT.PRIMEROS_PASOS",
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
					{ Type = "Event", Event = "RoomVisited", Match = { Room = "Salon" }, TextKey = "QUEST.BEBE_CASA.SALON" },
					{ Type = "Event", Event = "RoomVisited", Match = { Room = "Cocina" }, TextKey = "QUEST.BEBE_CASA.COCINA" },
					{ Type = "Event", Event = "RoomVisited", Match = { Room = "Dormitorio" }, TextKey = "QUEST.BEBE_CASA.DORMITORIO" },
				},
			},
			{ Type = "Talk", Npc = "Familia_Padre", TextKey = "QUEST.BEBE_CASA.S2" },
		},
		MomentKey = "MOMENT.CONOCES_FAMILIA",
	},
	Bebe_HoraDeSalir = {
		Kind = "Main",
		TitleKey = "QUEST.BEBE_SALIR.TITLE",
		Requires = { Completed = { "Bebe_ExploraLaCasa" } },
		Steps = {
			{ Type = "Event", Event = "LookedOutside", TextKey = "QUEST.BEBE_SALIR.S1" },
			{ Type = "Transition", Seconds = 5, SetStage = "Nino", TextKey = "TRANSITION.ANOS_DESPUES" },
		},
		MomentKey = "MOMENT.YA_ERES_NINO",
	},

	-----------------------------------------------------------------
	-- FASE 4 · NIÑO: primer día de colegio (datos listos; espera al sistema de clases)
	-----------------------------------------------------------------
	Nino_PrimerDiaColegio = {
		Kind = "Main",
		TitleKey = "QUEST.PRIMER_DIA.TITLE",
		Requires = { Hours = { From = 7, To = 15 }, Weekdays = { 1, 2, 3, 4, 5 } },
		Steps = {
			{ Type = "Event", Event = "LeftHome", TextKey = "QUEST.PRIMER_DIA.SALIR" },
			{ Type = "Reach", Place = "Colegio", TextKey = "QUEST.PRIMER_DIA.IR" },
			{ Type = "Event", Event = "EnteredClassroom", TextKey = "QUEST.PRIMER_DIA.AULA" },
			{ Type = "Talk", Npc = "Rol_Profesor", TextKey = "QUEST.PRIMER_DIA.PROFE" },
			{ Type = "Event", Event = "LessonCompleted", TextKey = "QUEST.PRIMER_DIA.CLASE" },
			{ Type = "Event", Event = "RecessStarted", TextKey = "QUEST.PRIMER_DIA.RECREO" },
			{ Type = "Talk", Npc = "Companero", TextKey = "QUEST.PRIMER_DIA.COMPANERO" },
			{ Type = "Reach", Place = "Home", TextKey = "QUEST.PRIMER_DIA.VOLVER" },
		},
		Rewards = { Money = 10 },
		MomentKey = "MOMENT.PRIMER_DIA_COLEGIO",
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

return Quests
