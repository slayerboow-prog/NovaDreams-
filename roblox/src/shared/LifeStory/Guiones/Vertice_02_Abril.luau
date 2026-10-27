-- GUION REESCRITO de Vertice_02_Abril (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Vertice_02_Abril.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Vertice_02_Abril
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Vertice_02_Abril.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Vertice_02_Abril.md",
	Dialogues = {
		Abril = {
			Lines = {
				{
					S = "AbrilCruz",
					T = "¿Os manda Gil? Gil no manda a nadie. Gil tiene miedo hasta de su sombra.",
					To = "Yo",
					Shot = "Medio:AbrilCruz",
					Effects = { Scene = "Vertice2_G1_Musica" },
				},
				{ S = "AbrilCruz", T = "Soy Abril. Arreglo la Cúpula y las farolas. Lo que MegaVerso rompe y no paga.", To = "Yo", G = "Point" },
				{ S = "Cosme", T = "Una mecánica. Por fin alguien que habla mi idioma, criatura.", To = "Yo", A = "Happy" },
				{ S = "AbrilCruz", T = "Aquí abajo nadie se fía de la gente de fuera. Haced un turno de técnico en la plaza.", To = "Yo", A = "No" },
				{ S = "AbrilCruz", T = "Dos paneles antes del apagón. Si salen bien, hablamos. Si no, gracias por su compra.", To = "Yo", A = "Nod" },
			},
		},
		Prueba = {
			Lines = {
				{
					S = "AbrilCruz",
					T = "Los dos paneles a la primera. La mitad de los técnicos de MegaVerso no lo consigue.",
					To = "Yo",
					Shot = "Medio:AbrilCruz",
					A = "Happy",
					Effects = { Scene = "Vertice2_G2_Musica" },
				},
				{ S = "AbrilCruz", T = "Toma mi chapa de técnica. Con ella te dejan subir donde no dejan a nadie.", To = "Yo", A = "Lean" },
				{ S = "AbrilCruz", T = "(susurrando) Llevo años arreglando la Cúpula. Y cuanto más la arreglo, menos me creo lo que hay detrás.", To = "Yo" },
				{ S = "Cosme", T = "¿Y qué hay detrás de un cielo falso?", To = "Yo", A = "ThinkChin" },
				{ S = "AbrilCruz", T = "No lo sé. Nunca me he atrevido a mirar. Pero el Museo de la Luz guarda los anuncios de antes.", To = "Yo", A = "Sad" },
			},
		},
	},
	Scenes = {
		Vertice2_G1_Musica = { Light = true, Duration = 32.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Vertice2_G2_Musica = { Light = true, Duration = 33.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
