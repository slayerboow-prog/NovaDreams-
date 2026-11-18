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
--   IntroCinematic / OutroCinematic -> escena de cámara en lugar de la pantalla de texto (Cinematics.luau o
--                                      una escena del motor de Happenings).
--                       Como una serie: cada capítulo tiene su cabecera y su final. Si el capítulo acaba
--                       con un cambio de etapa, el final es el montaje (Happenings/Etapas, en el paso
--                       Transition de su última misión) y aquí no hace falta Outro: la cabecera del
--                       siguiente espera en la cola de la pantalla a que acabe el montaje.
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
	-- (17-11-2026, el dueño) SIN PRÓLOGO: el juego empieza en la ACADEMIA DE GUERREROS ESPACIALES, que es el
	-- tutorial y donde se aprenden las habilidades (Misiones/Academia). Los personajes nuevos nacen adolescentes
	-- (Config.NewCharacterStage) y al jurar como guerreros pasan a adultos jóvenes.
	Academia_Guerreros = {
		Id = "Academia_Guerreros",
		Order = 5,
		Stage = { Min = "Adolescente", Max = "Adolescente" },
		Requires = { NotCompleted = { "Ins01_NuevoInstituto", "Cole12_UltimoDia" } }, -- (quien jugó la infancia antigua o ya iba por el instituto, lo sigue)
		Enabled = true,
		TitleKey = "La Academia de Guerreros",
		IntroKey = "Hace dos años, la Caída: las bestias de la Grieta arrasaron los distritos de fuera. Hoy entras en la Academia para recuperarlos.",
		OutroKey = "Has jurado como guerrero espacial. Tu nombre no está en la pared. Todavía.",
		Main = { "Acad01_Llegada", "Acad02_Tecnicas", "Acad03_PrimeraCaza", "Acad04_Espiritu", "Acad05_Juramento" },
		Next = "Guerrero_Primeras",
		Music = "TemaValmar",
	},

	-- (17-11-2026) Después del juramento: las primeras misiones de guerrero espacial (Misiones/Guerrero): patrullas
	-- en los distritos de caza, el primer despegue, el primer planeta y el ascenso a guerrero de primera.
	Guerrero_Primeras = {
		Id = "Guerrero_Primeras",
		Order = 42,
		Stage = { Min = "AdultoJoven" },
		Requires = { Flags = { "GuerreroEspacial" } },
		Enabled = true,
		TitleKey = "Guerrero espacial",
		IntroKey = "El uniforme no protege de nada. Patrullas en los distritos perdidos, tu primera nave y un mundo que nadie de Valmar ha pisado.",
		OutroKey = "Guerrero de primera. Lo que atacó Valmar viene de fuera, y no ha terminado.",
		Main = { "Gue01_Patrulla", "Gue02_MasLejos", "Gue03_Despegue", "Gue04_OtroMundo", "Gue05_Ascenso" },
		Next = "Reconquista_Valmar",
		Music = "VidaAdulta",
	},

	-- (18-11-2026) ACTO II · LA COALICIÓN (Misiones/Coalicion_*; biblia: docs/historia/historia-principal-15h.md):
	-- la Marea Gris amenaza los siete mundos con grietas del Consorcio; hay que cerrarlas una a una y unir los mundos.
	Coalicion_Marea = {
		Id = "Coalicion_Marea",
		Order = 45,
		Stage = { Min = "AdultoJoven" },
		Requires = { Flags = { "UmbralResuelto" } },
		Enabled = true,
		TitleKey = "La Coalición · La Marea Gris",
		IntroKey = "Todas las radios de Valmar captan el mismo sonido, cada once segundos. Viene de siete sitios a la vez.",
		OutroKey = "Siete mundos, siete grietas. La Coalición despega hacia el primero.",
		Main = { "Mar01_Senal", "Mar02_Coalicion" },
		Next = "Coalicion_Tefra",
		Music = "VidaAdulta",
	},
	Coalicion_Tefra = {
		Id = "Coalicion_Tefra",
		Order = 46,
		Stage = { Min = "AdultoJoven" },
		Requires = { Flags = { "Coalicion" } },
		Enabled = true,
		TitleKey = "La Coalición · Tefra",
		IntroKey = "Un mundo volcánico en guerra desde hace noventa años. Cosme vuelve a casa.",
		OutroKey = "La grieta de Tefra está cerrada. Por primera vez en noventa años, no cae ni una bomba.",
		Main = { "Tef01_Llegada", "Tef02_Tregua", "Tef03_Pozo" },
		Next = "Adulto_TuVida",
		Music = "VidaAdulta",
	},

	-- (18-11-2026) LA GRIETA: PROYECTO UMBRAL (Misiones/Grieta_Umbral): la historia principal después de la primera
	-- bandera. Sustituye a la Saga de la Grieta de antes. Una voz en la Grieta, una cápsula de otro mundo, el archivo del
	-- Consejo, la venganza de Brenn, el otro lado y la decisión final.
	Grieta_Umbral = {
		Id = "Grieta_Umbral",
		Order = 44,
		Stage = { Min = "AdultoJoven" },
		Requires = { Flags = { "Reconquista1" } },
		Enabled = true,
		TitleKey = "La Grieta: Proyecto Umbral",
		IntroKey = "A las 3:12 de cada noche, una voz humana habla desde dentro de la Grieta. Alguien en Valmar sabe por qué.",
		OutroKey = "Has decidido el destino de la Grieta. Lo que había al otro lado ya sabe que existimos.",
		Main = { "Gri01_Senal", "Gri02_Capsula", "Gri03_Umbral", "Gri04_Brenn", "Gri05_OtroLado", "Gri06_Decision" },
		Next = "Coalicion_Marea",
		Music = "VidaAdulta",
	},

	-- (17-11-2026) LA RECONQUISTA (Misiones/Reconquista): el asentamiento sale a recuperar el planeta, zona a zona,
	-- en terreno hostil (cada misión cuenta las bestias solo de su zona)
	Reconquista_Valmar = {
		Id = "Reconquista_Valmar",
		Order = 43,
		Stage = { Min = "AdultoJoven" },
		Requires = { Flags = { "GuerreroDePrimera" } },
		Enabled = true,
		TitleKey = "La Reconquista",
		IntroKey = "Dos años detrás de una empalizada. Hoy el asentamiento sale a recuperar lo que la Caída se llevó: zona a zona, bestia a bestia.",
		OutroKey = "La primera bandera ondea en el norte. Quedan siete regiones. Y el cielo.",
		Main = { "Rec01_Baliza", "Rec02_Agua", "Rec03_Pantano", "Rec04_Campus", "Rec05_Bandera" },
		Next = "Grieta_Umbral",
		Music = "VidaAdulta",
	},

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
		IntroCinematic = "Bebe_NacimientoCuna", -- (escena del motor: Happenings/Colegio)
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
			"Cole01_PrimerDia", -- misiones episódicas (Misiones/, docs/historia/11)
			"Cole02_Mochila",
			"Cole03_Grupo",
			"Cole04_Malotes",
			"Cole05_Venganza",
			"Cole06_Examen",
			"Nino_Recados",
			"Cole07_Excursion",
			"Cole08_Torneo",
			"Cole09_Misterio",
			"Cole10_Festival",
			"Cole11_Proyecto",
			"Cole12_UltimoDia",
		},
		Next = "Adolescente_Instituto",
		Loop = "Nino_Jornada",
		IntroCinematic = "Cole01_Amanecer",
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
		Main = { "Ins01_NuevoInstituto", "Ins02_Clubes", "Ins03_QueQuieresSer", "Pan1_MalasCompanias", "Pan2_LaNoche", "Ins04_PrimerEmpleo", "Pan3_Cruce", "Ins05_ElRumor", "Ins06_LaGranDecision" },
		Next = "Joven_Universidad",
		Loop = "Adol_Jornada",
		IntroCinematic = "Ins_Entrada", -- (el final: Montaje_Adolescente_Joven, en Ins06)
		Music = "TemaValmar",
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
		-- El ciclo de una carrera de verdad: residencia, cuatrimestres, exámenes (teóricos y físicos), recuperaciones, TFG
		Main = {
			"Uni01_PrimerDia", "Uni01b_Residencia", "Uni02_ElProyecto", "UniEx1_Enero", "Uni03_PrimerTrabajo", "UniEx2_Junio",
			"Uni04_Practicas", "UniEx3_Parcial", "Uni05_PrimerPiso", "UniEx4_TFG", "Uni06_Graduacion",
		},
		Next = "Adulto_VolarDelNido",
		Loop = "Uni_Jornada",
		IntroCinematic = "Uni_PrimerDia",
		OutroCinematic = "Uni_FinCapitulo",
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
	-- Adulto joven: después del instituto (con carrera o trabajando). Primer contrato, {abu} y el reencuentro.
	Adulto_VolarDelNido = {
		Id = "Adulto_VolarDelNido",
		Order = 45,
		Stage = { Min = "AdultoJoven" },
		Requires = { Completed = { "Ins06_LaGranDecision" } },
		Enabled = true,
		TitleKey = "Volar del nido",
		IntroKey = "Tu vida adulta empieza de verdad: trabajo, facturas… y la gente que te importa.",
		OutroKey = "Has volado del nido. Y el nido sigue ahí cuando vuelves.",
		Main = { "Adu01_PrimerContrato", "Adu02_Atardecer", "Adu03_Reencuentro" },
		IntroCinematic = "Nido_Entrada",
		OutroCinematic = "Nido_Fin", -- (después del Montaje_Joven_Adulto de Adu03)
		Music = "VidaAdulta",
	},
	Adulto_NuevaVida = {
		Id = "Adulto_NuevaVida",
		Order = 50,
		Stage = { Min = "AdultoJoven" },
		Requires = { NotCompleted = { "Ins06_LaGranDecision" }, NotFlags = { "GuerreroEspacial" } }, -- quien ya jugaba antes (sin infancia jugada ni Academia)
		Enabled = true,
		TitleKey = "CHAPTER.NUEVA_VIDA.TITLE",
		IntroKey = "CHAPTER.NUEVA_VIDA.INTRO",
		OutroKey = "CHAPTER.NUEVA_VIDA.OUTRO",
		Main = { "Adulto_LlegadaValmar", "Adulto_PrimerSueldo", "Adulto_ConoceLaRegion" },
		IntroCinematic = "Adulto_Llegada",
		OutroCinematic = "Adulto_TuCiudad",
	},

	-- Adulto: después de «Volar del nido» (o de «Una nueva vida», los veteranos). Tu vida sigue: días
	-- normales (trabajo, recados, tardes libres) mientras pasan los años (Config.LifeStory.StageHours.Adulto),
	-- y cuando ya has vivido casi toda la etapa, mirar atrás. La saga, las misiones locas y los trabajos
	-- siguen en el mapa todo el tiempo.
	Adulto_TuVida = {
		Id = "Adulto_TuVida",
		Order = 60,
		Stage = { Min = "Adulto" },
		Enabled = true,
		TitleKey = "Tu vida de guerrero",
		IntroKey = "Tu vida es tuya: caza en los distritos y en las regiones, mejora tu equipo, viaja a los planetas… Y Cosme sigue en su garaje: la Saga de la Grieta te espera en el mapa.",
		OutroKey = "Toda una vida defendiendo Valmar y los mundos de más allá. Y la historia sigue.",
		Main = { "Adulto_MirarAtras" }, -- el final de la vida: Vida_MirarAtras (Happenings/Etapas)
		Loop = "Adulto_Jornada",
		IntroCinematic = "TuVida_Entrada",
		Music = "VidaAdulta",
	},
}

return Chapters
