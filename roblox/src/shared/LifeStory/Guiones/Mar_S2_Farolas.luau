-- GUION REESCRITO de Mar_S2_Farolas (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_S2_Farolas.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_S2_Farolas
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_S2_Farolas.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_S2_Farolas.md",
	Dialogues = {
		Gracias = {
			Lines = {
				{
					S = "Lia",
					T = "¿Lo ves? Ahora lo hondo se queda donde tiene que estar: lejos.",
					To = "Yo",
					A = "Happy",
					Effects = { Scene = "MarS2_G3_Musica" },
				},
				{
					S = "Lia",
					T = "Los mayores dicen que antes los secos también cargaban perlas. Que el faro de la Punta y nuestras perlas eran amigos.",
					To = "Yo",
				},
				{ S = "Lia", T = "Vuelve cuando quieras. De noche pago más: es cuando más falta haces.", To = "Yo", A = "Nod" },
			},
		},
		Lia = {
			Lines = {
				{
					S = "Lia",
					T = "¡Por fin unas manos! Aunque sean secas. Ilun está castigado por subir a la superficie a buscarte.",
					To = "Yo",
					A = "HandsOnHips",
					Effects = { Scene = "MarS2_G1_Musica" },
				},
				{ S = "Lia", T = "¿Ves las perlas-farola del paseo? De día guardan luz. De noche la sueltan. Pero hay que cargarlas.", To = "Yo", G = "Point" },
				{ S = "Lia", T = "El tablón de los faroleros está en el paseo. Haz una ronda, solo una, y verás qué bonito se pone Nácara.", To = "Yo" },
			},
		},
	},
	Scenes = {
		MarS2_G1_Musica = { Light = true, Duration = 25.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		MarS2_G3_Musica = { Light = true, Duration = 22, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = { ["2"] = { Set = { Text = "Haz un turno de farolero/a" } } },
}
