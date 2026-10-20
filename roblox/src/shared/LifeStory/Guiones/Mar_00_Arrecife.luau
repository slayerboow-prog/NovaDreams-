-- GUION REESCRITO de Mar_00_Arrecife (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Mar_00_Arrecife.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Mar_00_Arrecife
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Mar_00_Arrecife.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Mar_00_Arrecife.md",
	Dialogues = {
		Concha = {
			Lines = {
				{
					S = "Ilun",
					T = "Vale. Esto no ha pasado. Yo no estaba atrapado. Estaba… inspeccionando la red.",
					To = "Yo",
					A = "Shrug",
					Effects = { Scene = "Mar00_G3_Musica" },
				},
				{ S = "Ilun", T = "Bueno, sí. Estaba atrapado. Gracias, seco.", To = "Yo", A = "Happy" },
				{ S = "Ilun", T = "Tranquil{o/a}, «seco» no es un insulto. Así llamamos a los que vivís arriba, donde no hay agua.", To = "Yo" },
				{ S = "Ilun", T = "Soy Ilun. Hondario. Ya sabes: cola, branquias, toda la colección.", To = "Yo", G = "Point" },
				{ S = "Ilun", T = "Toma. Es una concha que canta. Cuando bajes al agua, escúchala.", To = "Yo" },
				{ S = "Narrador", T = "La concha vibra en la mano. Suena como una canción muy lejana, muy honda." },
				{ S = "Ilun", T = "Una cosa. No se lo cuentes a nadie. Los mayores dicen que los secos se olvidaron de nosotros.", To = "Yo", A = "ThinkChin" },
				{ S = "Ilun", T = "Pero tú me has sacado de una red. Así que tú no cuentas como seco. Del todo.", To = "Yo", A = "Happy" },
			},
		},
	},
	Scenes = {
		Mar00_G2_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Narrador", T = "Tres nudos. Duros de sal. Pero se sueltan." } }, Music = { { At = 0, Intensity = "Tension" } } },
		},
		Mar00_G3_Musica = { Light = true, Duration = 50.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {
		["1"] = { Effects = { Scene = "Mar00_G2_Entra" }, Set = { Text = "Bucea en el jardín de coral del sur" } },
		["2"] = { Set = { Text = "Suelta los tres nudos de la red" } },
	},
}
