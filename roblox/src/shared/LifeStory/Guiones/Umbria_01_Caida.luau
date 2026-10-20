-- GUION REESCRITO de Umbria_01_Caida (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Umbria_01_Caida.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Umbria_01_Caida
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Umbria_01_Caida.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Umbria_01_Caida.md",
	Dialogues = {
		Llegada = {
			Lines = {
				{
					S = "Garza",
					T = "Tú eres a quien mandaron. Bien. Me llamo Garza. Nací aquí. Hace mucho.",
					To = "Yo",
					Shot = "Medio:Garza",
					A = "Nod",
					Effects = { Scene = "Umbria1_G1_Musica" },
				},
				{
					S = "Garza",
					T = "Veinte años fuera y el Árbol Madre sigue igual. Nosotros no. Mira la empalizada: antes no hacía falta.",
					To = "Yo",
					G = "Point",
				},
				{ S = "Garza", T = "Hay máquinas que se comen la madera y hacen más máquinas. Vamos a ver por dónde entran. Abajo, al Suelo.", To = "Yo" },
			},
		},
		Mascarilla = {
			Lines = {
				{
					S = "Garza",
					T = "Eso son esporas. Las esporeras sueltan polvo que brilla. Bonito. Y te deja sin respirar.",
					To = "Yo",
					Shot = "Medio:Garza",
					A = "ThinkChin",
					Effects = { Scene = "Umbria1_G2_Musica" },
				},
				{ S = "Garza", T = "Mira tu medidor. Abajo sube; en la ciudad, poco; en un refugio, nada. Al anochecer llueven esporas.", To = "Yo", G = "Point" },
				{ S = "Garza", T = "Toma: mascarilla de hojas, dos tarros de ungüento de savia y un farolillo de setas para la noche.", To = "Yo" },
				{ S = "Garza", T = "Úntate el ungüento debajo de la nariz. Huele a miel. Mi madre me lo ponía de pequeñ{o/a}.", To = "Yo", A = "ThinkChin" },
				{ Effects = { Items = { FarolSetas = 1, MascarillaHojas = 1, UnguentoSavia = 2 } } },
			},
		},
		Vuelta = {
			Lines = {
				{
					S = "Garza",
					T = "Ramas peladas, astillas, y ni una sola hoja en el suelo. Han pasado por aquí. Muchas.",
					To = "Yo",
					Shot = "Medio:Garza",
					A = "ThinkChin",
					Effects = { Scene = "Umbria1_G3_Musica" },
				},
				{ S = "Garza", T = "La alcaldesa Savia quiere vernos. Va a pedirme que me quede a defender la ciudad.", To = "Yo", A = "Shrug" },
				{ S = "Garza", T = "Yo vine a cobrar un trabajo y a irme. Eso es lo que hago siempre.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Umbria1_G1_Musica = { Light = true, Duration = 24.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Umbria1_G2_Musica = { Light = true, Duration = 31.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Umbria1_G3_Musica = { Light = true, Duration = 20.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
