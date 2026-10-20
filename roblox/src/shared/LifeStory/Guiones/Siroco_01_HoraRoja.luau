-- GUION REESCRITO de Siroco_01_HoraRoja (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Siroco_01_HoraRoja.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Siroco_01_HoraRoja
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Siroco_01_HoraRoja.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Siroco_01_HoraRoja.md",
	Dialogues = {
		Llegada = {
			Lines = {
				{
					S = "RafaQuiroga",
					T = "¡Eh! ¡Tú, el de la nave! ¿No ves la hora que es? ¡Es la hora roja, criatura del espacio!",
					To = "Yo",
					Shot = "Medio:RafaQuiroga",
					A = "Surprised",
					Effects = { Scene = "Siroco1_G1_Musica" },
				},
				{
					S = "RafaQuiroga",
					T = "Rafa Quiroga. El Zorro. Campe{ón/ona} de la Gran Vuelta. Bueno, lo fui. ¡Corre, que se te derriten las botas!",
					To = "Yo",
				},
				{ S = "RafaQuiroga", T = "Al taller. Por la sombra de los toldos. ¡Y no te quedes mirando el sol, que te deja ciego!", To = "Yo", G = "Point" },
			},
		},
		Nina = {
			Lines = {
				{
					S = "NinaQuiroga",
					T = "Soy Nina. La que arregla lo que mi padre rompe. Que es todo.",
					To = "Yo",
					A = "ThinkChin",
					Effects = { Scene = "Siroco1_G3_Musica" },
				},
				{ S = "RafaQuiroga", T = "¡Eso es mentira! Solo rompo lo importante.", To = "Yo", G = "Laugh" },
				{
					S = "NinaQuiroga",
					T = "Papá debe dinero a la Escudería Hierro. Mucho. Y sus cobradores no esperan a que acabe la hora roja.",
					To = "Yo",
					A = "Sad",
				},
				{ S = "RafaQuiroga", T = "Bah. Hoy no vendrán. Hace demasiado calor hasta para cobrar.", To = "Yo", A = "Happy" },
			},
		},
		Taller = {
			Lines = {
				{
					S = "NinaQuiroga",
					T = "¿Otra vez trayendo gente, papá? Aquí no cabe ni un tornillo más.",
					To = "Yo",
					Shot = "Medio:NinaQuiroga",
					Effects = { Scene = "Siroco1_G2_Musica" },
				},
				{ S = "RafaQuiroga", T = "Es un visitante, Nina. Un cliente, quizá. ¿Un cliente con dinero?", To = "Yo", A = "Shrug" },
				{ S = "NinaQuiroga", T = "Mira tu medidor de sed. En Siroco sube siempre, y al sol más. Si se pone rojo, te desmayas.", To = "Yo", G = "Point" },
				{ S = "NinaQuiroga", T = "Toma una cantimplora y dos botellas de agua fresca. Aquí el agua vale más que el dinero. Bebe una ya.", To = "Yo" },
				{ Effects = { Items = { AguaFresca = 2, Cantimplora = 1 } } },
			},
		},
	},
	Scenes = {
		Siroco1_G1_Musica = { Light = true, Duration = 24.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Siroco1_G2_Musica = { Light = true, Duration = 28.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Siroco1_G3_Musica = { Light = true, Duration = 23.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
