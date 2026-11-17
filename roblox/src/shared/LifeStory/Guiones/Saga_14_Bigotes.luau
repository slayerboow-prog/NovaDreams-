-- GUION REESCRITO de Saga_14_Bigotes (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_14_Bigotes.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_14_Bigotes
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_14_Bigotes.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_14_Bigotes.md",
	Dialogues = {
		Presidente = {
			Lines = {
				{ S = "Bigotes", T = "Así que has llegado. En tu mundo me ves dentro de un gato callejero. Este es mi cuerpo de verdad.", To = "Yo" },
				{
					S = "Bigotes",
					T = "Mi pueblo me eligió para guiarles después de perder nuestro mundo. Lo que queda de él está en estas calles.",
					To = "Yo",
				},
				{ S = "Bigotes", T = "El Consorcio abrió una grieta sobre nuestra ciudad. Primero vinieron las bestias. Después, ellos, a cobrar.", To = "Yo" },
				{ S = "Sorel", T = "Buscamos la dimensión 66-B. Se han llevado a alguien.", To = "Yo" },
				{ S = "Bigotes", T = "A Cosme. Lo sé. Lo vi a través de la Grieta.", To = "Yo" },
				{ S = "Bigotes", T = "La 66-B es el mundo de Cósimo. Allí no queda nadie libre. Solo trabajadores del Consorcio.", To = "Yo" },
				{
					S = "Bigotes",
					T = "Te daré las coordenadas. Y un consejo: su laboratorio en tu mundo está bajo el campus abandonado. Bajo tierra.",
					To = "Yo",
				},
				{ S = "Brenn", T = "El campus. Donde hay más bestias que en ningún otro distrito. Ahora entiendo por qué.", To = "Yo" },
				{ S = "Bigotes", T = "Toma este collar. Es la señal de mi pueblo. En cualquier refugio de los míos, te abrirán la puerta.", To = "Yo" },
				{ S = "Narrador", T = "Primera pieza del rescate: las coordenadas de la 66-B. Al salir, los guardias felinos inclinan la cabeza a tu paso." },
			},
		},
	},
	Scenes = {
		Saga_14_G1_Fin = {
			Light = true,
			Duration = 24.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{
						At = 0.4,
						S = "Narrador",
						T = "Al otro lado hay otra Valmar: las mismas calles, llenas de tiendas de refugiados. Felinos altos como personas.",
					},
					{ At = 9.1, S = "Narrador", T = "Dos guardias felinos te ven. Para ellos, un humano que cruza un portal es una amenaza. Bajan las lanzas." },
					{ At = 17.3, S = "Pip", T = "No luche contra ellos. No son el enemigo. Corra hasta la plaza: allí está quien manda.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Saga_14_G1_Fin" } } },
}
