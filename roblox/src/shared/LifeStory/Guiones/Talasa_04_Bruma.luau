-- GUION REESCRITO de Talasa_04_Bruma (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Talasa_04_Bruma.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Talasa_04_Bruma
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Talasa_04_Bruma.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Talasa_04_Bruma.md",
	Dialogues = {
		Coria = {
			Lines = {
				{
					S = "AlmiranteCoria",
					T = "Has hecho lo correcto. No lo parece. Casi nunca lo parece.",
					To = "Yo",
					Shot = "Medio:AlmiranteCoria",
					A = "Nod",
					Effects = { Scene = "Talasa4_G2_Musica" },
				},
				{ S = "AlmiranteCoria", T = "Una barca robada es una barca menos para evacuar a todos. Bruma lo sabe.", To = "Yo" },
				{ S = "AlmiranteCoria", T = "No la encerraré. Pero esta noche las Balsas me odian un poco más.", To = "Yo", A = "Sad" },
			},
		},
		Despues = {
			Lines = {
				{
					S = "Bruma",
					T = "Mira los pilotes. El coral sube ya por las balsas. Cada noche, un palmo más.",
					To = "Yo",
					Shot = "Medio:Bruma",
					G = "Point",
					Effects = { Scene = "Talasa4_G3_Musica" },
				},
				{ S = "Cosme", T = "Esto no se arregla con barcas, Bruma. Hay que pararlo abajo.", To = "Yo", A = "ThinkChin" },
				{
					S = "Bruma",
					T = "Seis familias en mar abierto. Gracias. Toma una perla: esta es por los que todavía podemos sacar.",
					To = "Yo",
					A = "Happy",
					If = { Flags = { "BrumaAyudada" } },
				},
				{
					S = "Bruma",
					T = "Ya sé quién avisó. No me mires así. Yo tampoco sé si habría salido bien.",
					To = "Yo",
					A = "No",
					If = { Flags = { "BrumaDelatada" } },
				},
			},
		},
		Plan = {
			Lines = {
				{
					S = "Bruma",
					T = "Esta noche me llevo una barca del Consejo. Una grande. Caben seis familias de las Balsas.",
					To = "Yo",
					Shot = "Medio:Bruma",
					Effects = { Scene = "Talasa4_G1_Musica" },
				},
				{ S = "Bruma", T = "La patrulla vigila el Muelle. Si alguien la entretiene un rato, la barca sale sin un ruido.", To = "Yo", G = "Point" },
				{
					S = "Bruma",
					T = "(susurrando) Si me pillan, me encierran. Si no lo intento, se hunden con las balsas. Tú decides si me miras o me ayudas.",
					To = "Yo",
				},
			},
		},
	},
	Scenes = {
		Talasa4_G1_Musica = { Light = true, Duration = 25.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Talasa4_G2_Musica = { Light = true, Duration = 18.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Talasa4_G3_Musica = { Light = true, Duration = 27, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = {},
}
