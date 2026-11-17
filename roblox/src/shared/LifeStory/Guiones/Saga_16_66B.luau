-- GUION REESCRITO de Saga_16_66B (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_16_66B.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_16_66B
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_16_66B.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_16_66B.md",
	Dialogues = {
		Cartel = {
			Lines = {
				{ S = "Narrador", T = "Un cartel enorme en la plaza: «Cósimo. Orden. Futuro.». Debajo, alguien ha escrito con pintura: «Lía vive»." },
				{ S = "Sorel", T = "Aquí también la conocían. Y alguien todavía se acuerda de ella.", To = "Yo" },
			},
		},
		Malvado = {
			Lines = {
				{ S = "Brenn", T = "Nos vas a delatar.", To = "Yo" },
				{ S = "Brenn", T = "Pero aquí nadie me ha preguntado nunca qué quiero. Tú tampoco. Nadie lo hace.", To = "Yo" },
				{
					Ask = "¿Qué le dices a tu otra versión?",
					Options = {
						{
							T = "«Ayúdanos. No tienes por qué seguir con él.»",
							Effects = { Flags = { "MalvadoAyudo" }, Traits = { Empatia = 1 } },
							Then = { { S = "TuMalvado", T = "…Nadie me había preguntado eso nunca. La entrada está bajo la torre del Consorcio. Yo no os lo he dicho." } },
						},
						{
							T = "«No me fío de ti.»",
							Effects = { Traits = { Valentia = 1 } },
							Then = { { S = "TuMalvado", T = "Haces bien. Yo tampoco me fío de mí. Pero la rejilla de la torre echa vapor verde. Por si te interesa." } },
						},
					},
				},
			},
		},
		Rejilla = {
			Lines = {
				{ S = "Narrador", T = "En la base de la torre, una rejilla deja salir vapor verde. Debajo, un pasillo largo iluminado en blanco." },
				{ S = "Sorel", T = "Es el pasillo de la imagen de Ñoz. Las mismas luces.", To = "Yo", If = { Flags = { "GrabacionLaboratorio" } } },
				{
					S = "Pip",
					T = "Coordenadas de Bigotes confirmadas. Descansen esta noche. Mañana entramos.",
					To = "Yo",
					If = { Flags = { "CoordenadasCosimo" } },
				},
				{ S = "Narrador", T = "Sorel dibuja un mapa de las calles de la 66-B con todo lo que habéis visto.", If = { Flags = { "CoordenadasCosimo" } } },
			},
		},
	},
	Scenes = {
		Saga_16_G1_Fin = {
			Light = true,
			Duration = 14.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "La Valmar de la 66-B. El cielo es de color ceniza. En cada esquina hay un altavoz con el logo del Consorcio." },
					{ At = 8.9, S = "Narrador", T = "La gente camina deprisa y sin hablar. Nadie mira hacia arriba." },
				},
			},
		},
		Saga_16_G4_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = { { At = 0.4, S = "Pip", T = "Drones de patrulla. Les han detectado. Corran hacia la torre del Consorcio.", To = "Yo" } },
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Saga_16_G1_Fin" } }, ["3"] = { Effects = { Scene = "Saga_16_G4_Entra" } } },
}
