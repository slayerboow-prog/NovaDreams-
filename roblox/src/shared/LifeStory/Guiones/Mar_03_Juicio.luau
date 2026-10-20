-- GUION REESCRITO de Mar_03_Juicio (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_03_Juicio.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_03_Juicio
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_03_Juicio.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_03_Juicio.md",
	Dialogues = {
		Guardia = {
			Lines = {
				{
					S = "GuardiaConsejo",
					T = "Tú. El de las burbujas. Un seco nadando por Nácara. Hacía cien años que no pasaba.",
					To = "Yo",
					A = "HandsOnHips",
					Effects = { Scene = "Mar03_G1_Musica" },
				},
				{ S = "GuardiaConsejo", T = "No te asustes. Aquí no se hace daño a nadie. Pero la Guardiana quiere verte. Ahora.", To = "Yo" },
				{ S = "GuardiaConsejo", T = "Entra por la puerta del medio. Y no toques nada.", To = "Yo", G = "Point" },
			},
		},
		Veredicto = {
			Lines = {
				{
					S = "Maresa",
					T = "Me han contado lo de tu turno. Las algas no mienten, y las perlas-farola tampoco.",
					To = "Yo",
					Effects = { Scene = "Mar03_G5_Musica" },
				},
				{ S = "Maresa", T = "Has cumplido la primera prueba. Hay más. Siempre hay más.", To = "Yo", A = "Nod" },
				{ S = "Maresa", T = "Puedes quedarte en Nácara. Alquila una concha en el barrio, si quieres dormir con aire.", To = "Yo" },
				{ S = "Maresa", T = "Pero recuerda: la Marea Callada no te quiere aquí. Y algunos de los míos, tampoco.", To = "Yo", A = "ThinkChin" },
			},
		},
	},
	Scenes = {
		Mar03_G1_Musica = { Light = true, Duration = 19.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Mar03_G2 = {
			Skippable = true,
			Duration = 42.7,
			Anchors = { L_Mar_Consejo = "Place:Mar_Consejo", Sitio = "Place:Mar_Consejo", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Maresa", Npc = "Maresa" } }, { At = 0, Use = { Key = "Ilun", Npc = "Ilun" } } },
				Camera = {
					{ At = 0.4, Duration = 5.6, Shot = "General:L_Mar_Consejo" },
					{ At = 5.99, Duration = 11.2, Shot = "Medio:Maresa" },
					{ At = 17.23, Duration = 9.4, Shot = "Reaccion:Ilun" },
					{ At = 26.61, Duration = 15.5, Shot = "PrimerPlano:Maresa" },
				},
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "El Consejo de las Corrientes. Cultivo, Luz, Guardia, Canto y Viaje." },
					{ At = 6, S = "Maresa", T = "Así que este es el seco que trajo Ilun.", To = "Yo", A = "ThinkChin" },
					{ At = 9.6, S = "Maresa", T = "Cien años sin ver a uno de los vuestros aquí abajo. Y ahora llega uno… con una concha que canta.", To = "Yo" },
					{ At = 17.2, S = "Ilun", T = "Me sacó de una red, Guardiana. Una red de los suyos, pero me sacó.", To = "Yo", A = "Shrug" },
					{ At = 22.7, S = "Maresa", T = "Lo sé. Por eso no estás castigado. Todavía.", To = "Yo", A = "Nod" },
					{
						At = 26.6,
						S = "Maresa",
						T = "Escucha, seco. Tu gente apagó el faro y se olvidó del pacto. Nosotros no olvidamos nada: lo cantamos.",
						To = "Yo",
					},
					{ At = 34.6, S = "Maresa", T = "Si quieres quedarte en Nácara, tendrás que servir a una Corriente, como todos. Con tus manos.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Tema" } },
			},
		},
		Mar03_G5_Musica = { Light = true, Duration = 27.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {
		["2"] = { Set = { Id = "Mar03_G2" } },
		["3"] = { Set = { Text = "¿Por qué ha bajado un seco a Nácara?" } },
		["4"] = { Set = { Text = "Primera prueba: haz un turno para una Corriente" } },
	},
}
