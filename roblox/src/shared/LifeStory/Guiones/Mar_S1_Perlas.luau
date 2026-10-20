-- GUION REESCRITO de Mar_S1_Perlas (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_S1_Perlas.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_S1_Perlas
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_S1_Perlas.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_S1_Perlas.md",
	Dialogues = {
		Perlas = {
			Lines = {
				{
					S = "Oriana",
					T = "¡Mis perlas! Las tres. Y sin un arañazo. ¿Seguro que eres seco?",
					To = "Yo",
					A = "Happy",
					Effects = { Scene = "MarS1_G2_Musica" },
				},
				{ S = "Oriana", T = "La corriente brava pasa cada pocos días y se lleva lo que no está atado. Hoy me ha tocado a mí.", To = "Yo" },
				{ S = "Oriana", T = "Toma, por las molestias. Y cuando vengas a la Lonja, te guardo las perlas más bonitas.", To = "Yo", A = "Nod" },
			},
		},
	},
	Scenes = {
		MarS1_G2_Musica = { Light = true, Duration = 21.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
	},
	Steps = { ["1"] = { Set = { Text = "Busca las tres perlas de Oriana por Nácara" } } },
}
