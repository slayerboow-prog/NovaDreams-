-- GUION REESCRITO de Miasma_01_Asedio (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Miasma_01_Asedio.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Miasma_01_Asedio
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Miasma_01_Asedio.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Miasma_01_Asedio.md",
	Dialogues = {
		Cantina = {
			Lines = {
				{
					S = "BrumaTaller",
					T = "¿Otro forastero, Mara? ¿Este también viene a por el gas o a por tus rutas?",
					To = "Yo",
					Shot = "Medio:BrumaTaller",
					Effects = { Scene = "Miasma1_G3_Musica" },
				},
				{ S = "MaraSolis", T = "Este viene a por un caldo de musgo, Bruma. Y a ayudar, si se deja.", To = "Yo", A = "Shrug" },
				{
					S = "MaraSolis",
					T = "Siete Anclajes había en Miasma. Quedamos nosotros. A los otros seis se los tragó la niebla.",
					To = "Yo",
					A = "ThinkChin",
				},
				{
					S = "MaraSolis",
					T = "Mi hijo, Leo, quiere ser piloto de la Defensa. Tiene quince años. Yo quiero sacarlo de aquí antes.",
					To = "Yo",
					A = "Sad",
				},
				{ S = "BrumaTaller", T = "Si te quedas, forastero, en la Plaza falta comida y en mi taller faltan manos. Elige.", To = "Yo" },
			},
		},
		Filtro = {
			Lines = {
				{
					S = "MaraSolis",
					T = "¿Notas el picor en la garganta? Es la niebla. En Lastre sube casi hasta las pasarelas.",
					To = "Yo",
					Effects = { Scene = "Miasma1_G2_Musica" },
				},
				{ S = "MaraSolis", T = "Mira tu medidor. Si se pone rojo, toses, te mareas y te caes. Aquí nadie se muere de golpe.", To = "Yo", G = "Point" },
				{ S = "MaraSolis", T = "Toma: una máscara de filtro y dos cápsulas de aire limpio. Regalo de la casa. La próxima, la pagas.", To = "Yo" },
				{ S = "MaraSolis", T = "Una cápsula, ahora. Respira hondo. Eso es el aire de antes de la niebla, embotellado.", To = "Yo" },
				{ Effects = { Items = { CapsulaAire = 2, MascaraFiltro = 1 } } },
			},
		},
		Llegada = {
			Lines = {
				{
					S = "MaraSolis",
					T = "¡Eh, tú! ¡El de la nave bonita! ¿Has aterrizado en mitad de un asedio a propósito?",
					To = "Yo",
					Shot = "Medio:MaraSolis",
					A = "Surprised",
					Effects = { Scene = "Miasma1_G1_Musica" },
				},
				{ S = "MaraSolis", T = "Mara Solís. Contrabandista. No lo digas muy alto: aquí la Defensa tiene oídos hasta en los globos.", To = "Yo" },
				{ S = "MaraSolis", T = "Esas luces son la flota del Dominio Talar. Quieren nuestro gas. Llevan tres semanas esperando.", To = "Yo" },
				{ S = "MaraSolis", T = "Y lo de abajo es la niebla. Si caes, no hay suelo: hay veneno. Ven, que te enseño a respirar aquí.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Miasma1_G1_Musica = { Light = true, Duration = 31.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Miasma1_G2_Musica = { Light = true, Duration = 31, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Miasma1_G3_Musica = { Light = true, Duration = 35.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
