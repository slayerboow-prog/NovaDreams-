-- GUION REESCRITO de Talasa_05_Senal (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Talasa_05_Senal.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Talasa_05_Senal
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Talasa_05_Senal.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Talasa_05_Senal.md",
	Dialogues = {
		Cuaderno = {
			Lines = {
				{
					S = "Narrador",
					T = "Un cuaderno de laboratorio con manchas negras. En la primera página: «Coral vivo. Dra. Noa Ferrán».",
					Shot = "General",
				},
				{ S = "Narrador", T = "En la última, una letra que tiembla: «Si sale mal, la culpa es mía. Solo mía»." },
				{ S = "Cosme", T = "La voluntaria es la científica que busca medio planeta. Y el chico de la Cúpula es su hijo.", To = "Yo", A = "ThinkChin" },
			},
		},
		Sonar = {
			Lines = {
				{
					S = "NoaFerran",
					T = "Escucha. Eso no es el coral. Es una voz. Viene de la Cúpula Honda.",
					To = "Yo",
					Shot = "Medio:NoaFerran",
					A = "Lean",
					Effects = { Scene = "Talasa5_G1_Musica" },
				},
				{ S = "Narrador", T = "Entre crujidos, una voz joven y cansada: «Mamá, ¿me oyes? Quedamos once. El aire da para pocos días»." },
				{ S = "NoaFerran", T = "Elio…", To = "Yo", A = "Nervous" },
				{ S = "Cosme", T = "¿Mamá? Noa, ¿quién es Elio?", To = "Yo", A = "Ask" },
				{ S = "NoaFerran", T = "Ahora no. Ahora no, por favor. Tengo que hablar con el Consejo.", To = "Yo", A = "No" },
			},
		},
	},
	Scenes = { Talasa5_G1_Musica = { Light = true, Duration = 26.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } } },
	Steps = {},
}
