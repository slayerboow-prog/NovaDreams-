-- GUION REESCRITO de Saga_23_Fusion (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_23_Fusion.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_23_Fusion
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_23_Fusion.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_23_Fusion.md",
	Dialogues = {
		Llegada = {
			Lines = {
				{ S = "Cosimo", T = "Has venido. Y no vienes sin compañía. Lo sabía.", To = "Yo", If = { Choices = { Trato = "No" } } },
				{
					S = "Cosimo",
					T = "Aceptaste. Y traes un ejército. Ya sabía que mentías. Esperaba equivocarme.",
					To = "Yo",
					If = { Choices = { Trato = "Trampa" } },
				},
				{
					S = "Cosimo",
					T = "Sin Consorcio, sin dinero, sin nadie. Solo yo y la máquina. Así el final es solo mío.",
					To = "Yo",
					If = { Flags = { "ConsorcioCaido" } },
				},
				{ S = "Cosme", T = "Cósimo. Todavía estás a tiempo. Apágala.", To = "Yo", If = { Flags = { "ConsorcioCaido" } } },
				{
					S = "Cosimo",
					T = "¿Para volver a qué? Tú tuviste a Lía. Yo tuve una máquina y una tumba. ¡Drones!",
					To = "Yo",
					If = { Flags = { "ConsorcioCaido" } },
				},
			},
		},
		Rendicion = {
			Lines = {
				{ S = "Cosimo", T = "Veinte años preparando esto.", To = "Yo" },
				{ S = "Cosimo", T = "Y me gana un guerrero recién salido de la Academia, con un androide, un desertor y un puñado de cadetes.", To = "Yo" },
				{
					S = "Cosme",
					T = "Alguien me dijo que debí contar las cosas antes. Tenía razón. Así que lo digo ahora.",
					To = "Yo",
					If = { Flags = { "EnfadoConCosme" } },
				},
				{
					S = "Cosme",
					T = "Alguien me perdonó una noche en mi garaje sin que me lo mereciera. Ahora me toca a mí.",
					To = "Yo",
					If = { Flags = { "PerdonaACosme" } },
				},
				{ S = "Cosme", T = "Cósimo. Eres lo que yo habría sido sin Lía. No voy a odiarte por eso.", To = "Yo", If = { Flags = { "PerdonaACosme" } } },
				{ S = "Cosme", T = "Pero no voy a dejar que nadie más pague por lo que perdiste.", To = "Yo", If = { Flags = { "PerdonaACosme" } } },
				{ S = "Cosimo", T = "…Eres insoportable, Cosme. Siempre lo has sido. En todos los mundos.", To = "Yo", If = { Flags = { "PerdonaACosme" } } },
				{
					S = "Narrador",
					T = "La máquina de la Fusión se apaga. Pero la Grieta sigue abierta en el cielo, enorme, temblando.",
					If = { Flags = { "PerdonaACosme" } },
				},
				{ S = "Cosme", T = "Ya no tira nadie de ella. Solo falta cerrarla. Para siempre.", To = "Yo", If = { Flags = { "PerdonaACosme" } } },
				{
					Ask = "Cósimo te mira a ti. «¿Y tú qué harías conmigo, Ancla?»",
					Options = {
						{
							T = "«Que vuelva. Que empiece de cero. En esta Valmar.»",
							Effects = { Flags = { "CosimoPerdonado" }, Traits = { Empatia = 2 } },
							Then = { { S = "Cosimo", T = "¿Aquí? ¿En el mundo que intenté borrar? …No sé si sabré. Pero lo intentaré. Gracias." } },
						},
						{
							T = "«Que vuelva a la 66-B. A arreglar lo que rompió.»",
							Effects = { Flags = { "CosimoArregla66B" }, Traits = { Responsabilidad = 2 } },
							Then = {
								{ S = "Cosimo", T = "¿Arreglar la 66-B? ¿Lo que yo mismo rompí? …Es lo único que me queda por hacer bien. Acepto." },
								{
									S = "TuMalvado",
									T = "Yo iré con él. Alguien tiene que vigilar que cumpla.",
									To = "Cosimo",
									Shot = "Medio:TuMalvado",
									If = { Flags = { "AliadoMalvado" } },
								},
							},
						},
					},
				},
			},
		},
		Restos = {
			Lines = {
				{
					S = "Pip",
					T = "Los restos de la Grieta que devolvió a su sitio están reaccionando. La Grieta los reconoce como suyos. Le frenan.",
					To = "Yo",
				},
			},
		},
	},
	Scenes = {
		Saga_23_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = { { At = 0.4, S = "Pip", T = "¡La Grieta está tirando del Ancla! ¡Aguante en la cima! ¡No deje que le arrastre!", To = "Yo" } },
			},
		},
		Saga_23_G4_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Kael", Npc = "Kael" } } },
				Dialogue = { { At = 0.4, S = "Kael", T = "¡Academia, conmigo! ¡Nadie se queda atrás!", To = "Yo" } },
			},
		},
		Saga_23_G6_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosimo", Npc = "Cosimo" } } },
				Dialogue = { { At = 0.4, S = "Cosimo", T = "¿Qué es esto? ¿Por qué me cuesta moverme?", To = "Yo" } },
			},
		},
		Saga_23_G7_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosimo", Npc = "Cosimo" } } },
				Dialogue = { { At = 0.4, S = "Cosimo", T = "Ven, Ancla. Acabemos con esto tú y yo.", To = "Yo" } },
			},
		},
	},
	Steps = {
		["2"] = { Effects = { Scene = "Saga_23_G3_Entra" } },
		["3"] = { Effects = { Scene = "Saga_23_G4_Entra" } },
		["5"] = { Effects = { Scene = "Saga_23_G6_Entra" } },
		["6"] = { Effects = { Scene = "Saga_23_G7_Entra" } },
	},
}
