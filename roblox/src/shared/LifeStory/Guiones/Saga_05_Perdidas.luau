-- GUION REESCRITO de Saga_05_Perdidas (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_05_Perdidas.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_05_Perdidas
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_05_Perdidas.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_05_Perdidas.md",
	Dialogues = {
		DevolverBalon = {
			Lines = {
				{ S = "Nico", T = "¡MI BALÓN! ¡El del torneo!", To = "Yo" },
				{ S = "Nico", T = "¡Lo busqué por todas partes! ¿Dónde estaba? ¿En el gimnasio? ¿En el cielo? Vale. No voy a preguntar.", To = "Yo" },
				{ S = "Nico", T = "Bueno… sí voy a preguntar.", To = "Yo" },
				{ S = "Pip", T = "Recuperación completada.", To = "Yo" },
				{ S = "Nico", T = "Ese robot me cae bien.", To = "Yo" },
			},
		},
		DevolverDiario = {
			Lines = {
				{ S = "Lucia", T = "Mi diario. De cuando tenía tu edad.", To = "Yo" },
				{ S = "Lucia", T = "Lo perdí durante una excursión. ¿Lo has leído? No contestes. No está enfadada. Gracias.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "Hay cosas que perdemos…", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Eso no lo hacía antes.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Detecto movimiento. Mucho movimiento.", To = "Yo" },
			},
		},
		DevolverLlaves = {
			Lines = {
				{ S = "Ramon", T = "Mis llaves. O que alguien las había encontrado. No funciona.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Con estas se abre la sala del reloj.", To = "Yo" },
				{ S = "Ramon", T = "Nadie entra ahí desde entonces. Otro día te cuento. O no.", To = "Yo" },
			},
		},
		Diario = {
			Lines = {
				{ S = "Narrador", T = "En la portada: «Lucía · 3.º B · 1998»" },
				{ S = "Pip", T = "El objeto pertenece a otra persona.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Lo abres?",
					Options = {
						{
							T = "«No. Es de Lucía.»",
							Effects = { Rel = { Lucia = 3 }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Pip", T = "Buena decisión.", To = "Yo" } },
						},
						{
							T = "«Solo la primera página…»",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Narrador", T = "Debajo: «Y que no le leeré el diario a nadie.» «Ni a los cotillas.»", Pause = 0.9 },
								{ S = "Pip", T = "Curiosidad satisfecha. Privacidad intacta.", To = "Yo" },
							},
						},
					},
				},
			},
		},
		Final = {
			Lines = {
				{ S = "Pip", T = "Hay un problema. Esta vez lo ha visto todo el barrio. Los vecinos.", To = "Yo" },
				{ S = "Pip", T = "El señor Cosme dice que hay que coserla. Ya. No llega a abrirse. Pero pulsa.", To = "Yo", Pause = 1.8 },
				{ S = "Narrador", T = "No parece peligroso.", Pause = 0.9 },
				{ S = "Narrador", T = "Pero después de esta noche ya no estás segur{o/a} de qué cosas pueden ser normales.", Pause = 0.9 },
			},
		},
		Llaves = { Lines = { { S = "Pip", T = "Parece que alguien ha esperado mucho tiempo para recuperarlas.", To = "Yo", Pause = 0.9 } } },
		Ramon = {
			Lines = {
				{ S = "Ramon", T = "Treinta años de conserje. Treinta. He visto de todo.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "El gimnasio está lleno de cosas perdidas. Hay un bolso de 1950.", To = "Yo" },
				{ S = "Pip", T = "Confirmado. ¿Y los devuelve aquí? Donde le parece.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Cosme ha dicho algo de una… ¿Papelera cósmica?", To = "Yo" },
				{ S = "Pip", T = "«Fallo de la papelera cósmica».", To = "Yo" },
				{ S = "Pip", T = "Es la explicación oficial del señor Cosme. Claro.", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Saga_05_G4_Entra = {
			Light = true,
			Duration = 12.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{ At = 0.4, S = "Pip", T = "Identificación. No disponible.", To = "Yo" },
					{ At = 3.3, S = "Pip", T = "Solo queda un calcetín. Sin pareja. Monstruo emparejado. Bueno.", To = "Yo" },
					{ At = 9.5, S = "Pip", T = "Pero estará orgulloso.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_05_G4_Entra" } } },
}
