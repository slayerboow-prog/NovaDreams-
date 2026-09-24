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
	},

	-- FASE 4 · Niño. Se activa cuando exista el sistema de clases (fase 5).
	Nino_ElColegio = {
		Id = "Nino_ElColegio",
		Order = 20,
		Stage = { Min = "Nino", Max = "Nino" },
		Enabled = false,
		TitleKey = "CHAPTER.NINO.TITLE",
		IntroKey = "CHAPTER.NINO.INTRO",
		OutroKey = "CHAPTER.NINO.OUTRO",
		Main = { "Nino_PrimerDiaColegio" },
	},

	-- PUENTE TEMPORAL (mientras no esté la infancia completa, fases 4-8): un vistazo al barrio de niño
	-- y un salto en el tiempo hasta la vida adulta. Se desactiva cuando se active Nino_ElColegio.
	Nino_Puente = {
		Id = "Nino_Puente",
		Order = 25,
		Stage = { Min = "Nino", Max = "Adolescente" },
		Enabled = true,
		TitleKey = "CHAPTER.NINO_PUENTE.TITLE",
		IntroKey = "CHAPTER.NINO_PUENTE.INTRO",
		OutroKey = "CHAPTER.NINO_PUENTE.OUTRO",
		Main = { "Nino_TuBarrio" },
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
	},
}

return Chapters
