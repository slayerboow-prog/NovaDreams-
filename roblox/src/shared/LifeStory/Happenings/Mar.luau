-- Escenas del MAR DE LOS HONDARIOS («La canción de lo hondo», fase 1: docs/mar/civilizacion-marina.md).
-- Formato: shared/LifeStory/Sequencer.luau. Las lanzan las misiones de Misiones/Mar_Acto1.
--
-- Sin actores de la escena a propósito: los Hondarios viven en el agua con su cola (Services/SeaCivService
-- los pone y los mueve: Maresa en su concha, Ilun a su lado durante el juicio) y el motor de escenas solo
-- sabe crear gente con piernas. La cámara usa planos fijos con anclas en la Concha del Consejo.
-- Las frases son las del guion docs/historia/reescritura/Mar_03_Juicio.md (PASO 2).

local V = Vector3.new

return {
	---------------------------------------------------------------------
	-- Mar_03 · EL JUICIO en la Concha del Consejo.
	--   ¿Qué está pasando? La Guardiana de la Marea juzga al primer seco que baja a Nácara en cien años.
	--   ¿Por qué? Ilun le llamó con su concha; la Guardia le ha visto nadando por la capital.
	--   ¿Qué siente el personaje? Maresa: desconfianza y curiosidad. Ilun: vergüenza y lealtad.
	--   ¿Qué ve el jugador? La gran concha con sus cinco puertas de luz, Maresa en su sillón e Ilun a un lado.
	--   ¿Qué quiero que sienta el jugador? Que es importante, que no es bienvenido del todo y que puede ganárselo.
	---------------------------------------------------------------------
	Mar_Juicio = {
		Duration = 43,
		Skippable = true,
		FadeIn = true,
		Sting = "Momento",
		Anchors = {
			Consejo = "Place:Mar_Consejo",
			Yo = "Player",
			Maresa = { Place = "Mar_Consejo", Offset = V(0, 8, -10) },
			Ilun = { Place = "Mar_Consejo", Offset = V(10, 7, -6) },
			Puertas = { Place = "Mar_Consejo", Offset = V(0, 9, 10) },
		},
		Tracks = {
			Camera = {
				{ At = 0, Duration = 6, Fixed = { "Consejo", V(-26, 16, 34) }, Look = { "Puertas" }, Fov = { 62, 54 }, Cut = "Fade" },
				{ At = 6, Duration = 11.2, Fixed = { "Maresa", V(4, 0, 11) }, Look = { "Maresa" }, Fov = 46, Cut = "Cut" },
				{ At = 17.2, Duration = 9.4, Fixed = { "Ilun", V(-4, 1, 8) }, Look = { "Ilun" }, Fov = 44, Cut = "Cut" },
				{ At = 26.6, Duration = 16.4, Fixed = { "Maresa", V(1.5, 0.6, 6) }, Look = { "Maresa" }, Fov = { 40, 34 }, Cut = "Cut" },
			},
			Dialogue = {
				{ At = 0.4, S = "Narrador", T = "El Consejo de las Corrientes. Cultivo, Luz, Guardia, Canto y Viaje." },
				{ At = 6, S = "Maresa", T = "Así que este es el seco que trajo Ilun.", To = "Yo", A = "ThinkChin" },
				{ At = 9.6, S = "Maresa", T = "Cien años sin ver a uno de los vuestros aquí abajo. Y ahora llega uno… con una concha que canta.", To = "Yo" },
				{ At = 17.2, S = "Ilun", T = "Me sacó de una red, Guardiana. Una red de los suyos, pero me sacó.", To = "Maresa", A = "Shrug" },
				{ At = 22.7, S = "Maresa", T = "Lo sé. Por eso no estás castigado. Todavía.", To = "Ilun", A = "Nod" },
				{ At = 26.6, S = "Maresa", T = "Escucha, seco. Tu gente apagó el faro y se olvidó del pacto. Nosotros no olvidamos nada: lo cantamos.", To = "Yo" },
				{ At = 34.6, S = "Maresa", T = "Si quieres quedarte en Nácara, tendrás que servir a una Corriente, como todos. Con tus manos.", To = "Yo" },
			},
			Sound = {
				{ At = 0.5, Play = "Hum", Pitch = 0.6, Volume = 0.5 },
			},
			Music = {
				{ At = 0, Intensity = "Tema" },
				{ At = 26, Intensity = "Tension" },
			},
			Titles = {
				{ At = 0.6, Text = "🐚 Nácara · Concha del Consejo", Sub = "El mar · «La canción de lo hondo»", Duration = 3 },
			},
		},
	},
}
