-- GUION REESCRITO de Vertice_01_Llegada (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Vertice_01_Llegada.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Vertice_01_Llegada
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Vertice_01_Llegada.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Vertice_01_Llegada.md",
	Dialogues = {
		Bienvenida = {
			Lines = {
				{
					S = "Gil",
					T = "¡Gracias por su compra! Soy Gil, empleado del mes. Cuarenta años seguidos, todos los meses.",
					To = "Yo",
					Shot = "Medio:Gil",
					G = "Wave",
					Effects = { Scene = "Vertice1_G2_Musica" },
				},
				{
					S = "Gil",
					T = "En Distrito Cero todo es de MegaVerso: las calles, las farolas, el cielo. Ustedes son clientes. Puntuación inicial: 500.",
					To = "Yo",
					A = "Happy",
				},
				{ S = "Cosme", T = "¿Y qué baja la puntuación, si se puede saber?", To = "Yo", A = "Ask" },
				{ S = "Gil", T = "Correr por la acera, sentarse sin consumir, mirar mal a una cámara. Las cámaras multan solas.", To = "Yo", A = "Nod" },
				{ S = "Gil", T = "(susurrando) Tomen. Una gorra que confunde a las cámaras y tres inhibidores. No se lo digan a nadie. Ni a mí.", To = "Yo" },
				{ S = "Gil", T = "Pruébenlo en la Avenida Rebajas. Allí hay más cámaras que clientes.", To = "Yo", A = "Shrug" },
			},
		},
		Llegada = {
			Lines = {
				{
					S = "Cosme",
					T = "Vértice, criatura. Un planeta entero que es una sola ciudad. Y una sola empresa.",
					To = "Yo",
					Shot = "Medio:Cosme",
					A = "HandsOnHips",
					Effects = { Scene = "Vertice1_G1_Musica" },
				},
				{ S = "Cosme", T = "Mira esas pantallas. Te sonríen. Las pantallas que sonríen siempre quieren algo.", To = "Yo", G = "Point" },
				{
					S = "Cosme",
					T = "Antes de bajar he leído el cartel de la plataforma: «Aterrizaje gratuito. Despegue, consultar tarifas».",
					To = "Yo",
					A = "ThinkChin",
				},
			},
		},
	},
	Scenes = {
		Vertice1_G1_Musica = { Light = true, Duration = 23.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Vertice1_G2_Musica = { Light = true, Duration = 44.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
	},
	Steps = {},
}
