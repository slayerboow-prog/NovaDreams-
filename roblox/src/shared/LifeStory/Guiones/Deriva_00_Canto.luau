-- GUION REESCRITO de Deriva_00_Canto (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Deriva_00_Canto.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Deriva_00_Canto
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Deriva_00_Canto.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Deriva_00_Canto.md",
	Scenes = {
		Canto_G1_Entra = {
			Light = true,
			Duration = 22.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "NILDA", Npc = "NILDA" } }, { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = {
					{ At = 0.4, S = "NILDA", T = "Ya la tengo delante. No es luz: es el escáner dibujando algo que no entiende.", To = "Yo", A = "ThinkChin" },
					{ At = 6.7, S = "NILDA", T = "Y el ruido no viene de fuera. Lo oigo dentro de mis propios circuitos. Como una nota que no se acaba.", To = "Yo" },
					{
						At = 14.7,
						S = "Cosme",
						T = "Aguanta dentro. Treinta segundos. Si la pantalla se vuelve loca, no toques nada y respira.",
						To = "Yo",
						A = "HandsOnHips",
					},
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
		Canto_G2_Entra = {
			Light = true,
			Duration = 14.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "NILDA", Npc = "NILDA" } }, { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = {
					{ At = 0.4, S = "NILDA", T = "Escaneo completo. Ya no canta. O ya no la oigo, que no es lo mismo.", To = "Yo", A = "ThinkChin" },
					{
						At = 6,
						S = "Cosme",
						T = "Llévalo a la Vigía, la estación del Instituto. Pregunta por Ivo. Si alguien sabe qué es eso, es ella.",
						To = "Yo",
						A = "Nervous",
						Mood = "Fear",
					},
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Canto_G1_Entra" } }, ["2"] = { Effects = { Scene = "Canto_G2_Entra" } } },
}
