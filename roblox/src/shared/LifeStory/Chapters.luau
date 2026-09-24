-- Chapters: los capítulos de la vida. Cada capítulo agrupa misiones principales en orden y
-- corresponde a una etapa (bebé, niño, adolescente...). Añadir un capítulo = añadir datos aquí.
--
--   Id, Order        -> identificador y orden en la vida
--   Stage            -> etapa en la que ocurre ({ Min, Max })
--   Enabled          -> false mientras su contenido (colegio, casa de bebé...) no exista en el juego
--   TitleKey         -> título que se ve en la tarjeta ("Primeros pasos")
--   IntroKey/OutroKey-> texto al empezar y al terminar (pantalla de capítulo)
--   Main             -> misiones principales, en orden
--   Next             -> capítulo siguiente (si la etapa lo permite)
--   IntroCinematic / OutroCinematic -> escena de cámara en lugar de la pantalla de texto (Cinematics.luau)
--   Music            -> música de fondo mientras dura el capítulo (Config.Audio.Music)

export type Chapter = {
	Id: string,
	Order: number,
	Stage: { Min: string?, Max: string? },
	Enabled: boolean,
	TitleKey: string,
	IntroKey: string,
	OutroKey: string,
	Main: { string },
	Next: string?,
	Requires: { [string]: any }?, -- requisitos (decisiones, marcas) además de la etapa
	Loop: string?, -- día normal que se repite entre los grandes momentos (misión con DayPlan)
	IntroCinematic: string?,
	OutroCinematic: string?,
	Music: string?,
}

local Chapters: { [string]: Chapter } = {
	-- FASE 2 · Bebé (5-10 min) en la casa familiar de Los Pinos.
	Bebe_PrimerosPasos = {
		Id = "Bebe_PrimerosPasos",
		Order = 10,
		Stage = { Min = "Bebe", Max = "Bebe" },
		Enabled = true,
		TitleKey = "CHAPTER.BEBE.TITLE",
		IntroKey = "CHAPTER.BEBE.INTRO",
		OutroKey = "CHAPTER.BEBE.OUTRO",
		Main = { "Bebe_AprendeACaminar", "Bebe_ExploraLaCasa", "Bebe_HoraDeSalir" },
		Next = "Nino_ElColegio",
		IntroCinematic = "Bebe_Nacimiento",
		Music = "Nacimiento",
	},

	-- Niño: el colegio (unas 5 horas, de 6 a 12 años). Grandes momentos repartidos y, entre ellos,
	-- días de cole generados (DayPlans): clases jugables, recreo, recados, excursiones, exámenes.
	Nino_ElColegio = {
		Id = "Nino_ElColegio",
		Order = 20,
		Stage = { Min = "Nino", Max = "Nino" },
		Enabled = true,
		TitleKey = "CHAPTER.NINO.TITLE",
		IntroKey = "CHAPTER.NINO.INTRO",
		OutroKey = "CHAPTER.NINO.OUTRO",
		Main = {
			"Nino_PrimerDiaColegio",
			"Nino_MiSemana",
			"Nino_Recados",
			"Nino_PrimerExamen",
			"Nino_Excursion",
			"Nino_SegundoTrimestre",
			"Nino_FinDePrimaria",
		},
		Next = "Adolescente_Instituto",
		Loop = "Nino_Jornada",
		IntroCinematic = "Nino_PrimerDia",
		Music = "TemaValmar",
	},

	-- Adolescente: el instituto (unas 5 horas) y la gran decisión: universidad o trabajar.
	Adolescente_Instituto = {
		Id = "Adolescente_Instituto",
		Order = 30,
		Stage = { Min = "Adolescente", Max = "Adolescente" },
		Enabled = true,
		TitleKey = "CHAPTER.INSTITUTO.TITLE",
		IntroKey = "CHAPTER.INSTITUTO.INTRO",
		OutroKey = "CHAPTER.INSTITUTO.OUTRO",
		Main = { "Adol_NuevoInstituto", "Adol_PrimerTrabajo", "Adol_ElFuturo" },
		Next = "Joven_Universidad",
		Loop = "Adol_Jornada",
	},

	-- Adulto joven: la universidad (unas 5 horas), solo si elegiste una carrera.
	Joven_Universidad = {
		Id = "Joven_Universidad",
		Order = 40,
		Stage = { Min = "AdultoJoven", Max = "Adulto" },
		Requires = { Flags = { "VaALaUniversidad" } },
		Enabled = true,
		TitleKey = "CHAPTER.UNIVERSIDAD.TITLE",
		IntroKey = "CHAPTER.UNIVERSIDAD.INTRO",
		OutroKey = "CHAPTER.UNIVERSIDAD.OUTRO",
		Main = { "Uni_PrimerDia", "Uni_PrimerSemestre", "Uni_SegundoSemestre", "Uni_Practicas", "Uni_TercerSemestre", "Uni_Graduacion" },
		Next = "Adulto_NuevaVida",
		Loop = "Uni_Jornada",
		IntroCinematic = "Uni_PrimerDia",
		Music = "VidaAdulta",
	},

	-- Puente antiguo (de niño a adulto en dos minutos). Desactivado: ahora hay colegio e instituto de verdad.
	Nino_Puente = {
		Id = "Nino_Puente",
		Order = 25,
		Stage = { Min = "Nino", Max = "Adolescente" },
		Enabled = false,
		TitleKey = "CHAPTER.NINO_PUENTE.TITLE",
		IntroKey = "CHAPTER.NINO_PUENTE.INTRO",
		OutroKey = "CHAPTER.NINO_PUENTE.OUTRO",
		Main = { "Nino_TuBarrio" },
		Music = "TemaValmar",
	},

	-- Capítulo puente, jugable YA en el mapa actual: mientras no exista la infancia,
	-- los personajes empiezan de adultos (como en la v0.1) y esta es su primera historia.
	Adulto_NuevaVida = {
		Id = "Adulto_NuevaVida",
		Order = 50,
		Stage = { Min = "AdultoJoven" },
		Enabled = true,
		TitleKey = "CHAPTER.NUEVA_VIDA.TITLE",
		IntroKey = "CHAPTER.NUEVA_VIDA.INTRO",
		OutroKey = "CHAPTER.NUEVA_VIDA.OUTRO",
		Main = { "Adulto_LlegadaValmar", "Adulto_PrimerSueldo", "Adulto_ConoceLaRegion" },
		IntroCinematic = "Adulto_Llegada",
		OutroCinematic = "Adulto_TuCiudad",
	},
}

return Chapters
