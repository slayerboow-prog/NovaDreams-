-- GUION REESCRITO de Mar_02_Burbuja (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_02_Burbuja.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_02_Burbuja
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_02_Burbuja.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_02_Burbuja.md",
	Dialogues = {
		Bartolo = {
			Lines = {
				{
					S = "Bartolo",
					T = "¡Un seco! ¡Un cliente! ¡Un cliente seco! Hoy es mi día de suerte.",
					To = "Yo",
					A = "HandsOnHips",
					Effects = { Scene = "Mar02_G3_Musica" },
				},
				{
					S = "Bartolo",
					T = "Bartolo, desguacero. Todo lo que se hunde, yo lo encuentro. Y lo vendo. Con descuento para amigos.",
					To = "Yo",
					G = "Point",
				},
				{ S = "Bartolo", T = "Mira esto: un timón auténtico de barco pirata. Bueno, de un pedal de playa. Pero tiene mucha historia.", To = "Yo" },
				{
					S = "Bartolo",
					T = "Te propongo un trato. Tráeme tres conchas bonitas de aquí cerca y te doy algo especial. Palabra de desguacero.",
					To = "Yo",
					A = "ThinkChin",
				},
			},
		},
		Oriana = {
			Lines = {
				{
					S = "Oriana",
					T = "Así que tú eres el seco del que habla todo el mundo. Ilun no sabe guardar un secreto ni debajo del agua.",
					To = "Yo",
					A = "Nod",
					Effects = { Scene = "Mar02_G1_Musica" },
				},
				{ S = "Oriana", T = "Escucha. Aquí no puedes quedarte mucho: tu botella no es eterna, aunque la cúpula ayude.", To = "Yo" },
				{
					S = "Oriana",
					T = "Al este de las Ruinas, en el talud, hay una cueva con aire. La llamamos La Burbuja. Es la posada de los secos.",
					To = "Yo",
					G = "Point",
				},
				{ S = "Oriana", T = "Pregunta por Bartolo. Si te vende algo, regatea. Si te lo regala, sospecha.", To = "Yo" },
			},
		},
		Trueque = {
			Lines = {
				{
					S = "Bartolo",
					T = "¡Preciosas! Esta de espiral la vendo mañana por el triple. No se lo digas a Oriana.",
					To = "Yo",
					A = "Happy",
					Effects = { Scene = "Mar02_G5_Musica" },
				},
				{ S = "Bartolo", T = "Toma, lo prometido. Una brújula que no apunta al norte. Apunta a lo que más quieres encontrar. O eso dicen.", To = "Yo" },
				{ S = "Bartolo", T = "A mí me apunta siempre a la cocina. Será que tengo hambre.", To = "Yo", A = "Shrug" },
				{ S = "Bartolo", T = "Duerme aquí cuando quieras: las camas se alquilan baratas. Y si la Guardia te pregunta, no me conoces.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Mar02_G1_Musica = { Light = true, Duration = 32.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Mar02_G3_Musica = { Light = true, Duration = 32, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Mar02_G5_Musica = { Light = true, Duration = 30.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
	},
	Steps = {
		["2"] = { Set = { Text = "Ve a La Burbuja, la posada de los secos" } },
		["4"] = { Set = { Text = "Busca tres conchas bonitas cerca de la posada" } },
	},
}
