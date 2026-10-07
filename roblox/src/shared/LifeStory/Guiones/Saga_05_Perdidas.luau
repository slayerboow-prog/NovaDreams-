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
				{ S = "Nico", T = "¡MI BALÓN!", To = "Yo" },
				{ S = "Nico", T = "Lo agarra.", To = "Yo" },
				{ S = "Nico", T = "¡El del torneo!", To = "Yo" },
				{ S = "Nico", T = "¡Lo busqué por todas partes!", To = "Yo" },
				{ S = "Nico", T = "¿Dónde estaba?", To = "Yo" },
				{ S = "Nico", T = "¿En el gimnasio?", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "¿En el cielo?", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "Vale.", To = "Yo" },
				{ S = "Nico", T = "No voy a preguntar.", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "Bueno… sí voy a preguntar.", To = "Yo" },
				{ S = "Pip", T = "Recuperación completada.", To = "Yo" },
				{ S = "Nico", T = "Ese robot me cae bien.", To = "Yo" },
			},
		},
		DevolverDiario = {
			Lines = {
				{ S = "Lucia", T = "Mi diario.", To = "Yo" },
				{ S = "Lucia", T = "De cuando tenía tu edad.", To = "Yo" },
				{ S = "Lucia", T = "Lo perdí durante una excursión.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "¿Lo has leído?", To = "Yo" },
				{ S = "Lucia", T = "No contestes.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "No está enfadada.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "Lo guarda con cuidado.", To = "Yo" },
				{ S = "Lucia", T = "Gracias.", To = "Yo" },
				{ S = "Lucia", T = "Hay cosas que perdemos…", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Eso no lo hacía antes.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Detecto movimiento.", To = "Yo" },
				{ S = "Pip", T = "Mucho movimiento.", To = "Yo", Pause = 0.9 },
			},
		},
		DevolverLlaves = {
			Lines = {
				{ S = "Ramon", T = "Mis llaves.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "O que alguien las había encontrado.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "No funciona.", To = "Yo" },
				{ S = "Ramon", T = "Con estas se abre la sala del reloj.", To = "Yo" },
				{ S = "Ramon", T = "Nadie entra ahí desde entonces.", To = "Yo" },
				{ S = "Ramon", T = "Otro día te cuento.", To = "Yo" },
				{ S = "Ramon", T = "O no.", To = "Yo", Pause = 0.9 },
			},
		},
		Diario = {
			Lines = {
				{ S = "Narrador", T = "En la portada: «Lucía · 3.º B · 1998»" },
				{ S = "Narrador", T = "Y una segunda frase: «Si lo lees, eres un cotilla.»" },
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
								{ S = "Narrador", T = "Primera página: «Hoy he decidido que de mayor seré profe.»", Pause = 0.9 },
								{ S = "Narrador", T = "Debajo: «Y que no le leeré el diario a nadie.»" },
								{ S = "Narrador", T = "«Ni a los cotillas.»", Pause = 0.9 },
								{ S = "Pip", T = "Curiosidad satisfecha.", To = "Yo" },
								{ S = "Pip", T = "Privacidad intacta.", To = "Yo", Pause = 0.9 },
							},
						},
					},
				},
			},
		},
		Final = {
			Lines = {
				{ S = "Pip", T = "Hay un problema.", To = "Yo" },
				{ S = "Pip", T = "Esta vez lo ha visto todo el barrio.", To = "Yo" },
				{ S = "Pip", T = "Los vecinos.", To = "Yo" },
				{ S = "Pip", T = "El señor Cosme dice que hay que coserla.", To = "Yo", Pause = 1.8 },
				{ S = "Pip", T = "Ya.", To = "Yo" },
				{ S = "Pip", T = "No llega a abrirse.", To = "Yo" },
				{ S = "Pip", T = "Pero pulsa.", To = "Yo" },
				{ S = "Narrador", T = "No parece peligroso.", Pause = 0.9 },
				{ S = "Narrador", T = "Pero después de esta noche ya no estás segur{o/a} de qué cosas pueden ser normales.", Pause = 0.9 },
			},
		},
		Llaves = { Lines = { { S = "Pip", T = "Parece que alguien ha esperado mucho tiempo para recuperarlas.", To = "Yo", Pause = 0.9 } } },
		Ramon = {
			Lines = {
				{ S = "Ramon", T = "Treinta años de conserje.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "Treinta.", To = "Yo" },
				{ S = "Ramon", T = "He visto de todo.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "El gimnasio está lleno de cosas perdidas.", To = "Yo" },
				{ S = "Ramon", T = "Hay un bolso de 1950.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Confirmado.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "¿Y los devuelve aquí?", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Donde le parece.", To = "Yo" },
				{ S = "Ramon", T = "Cosme ha dicho algo de una…", To = "Yo" },
				{ S = "Ramon", T = "¿Papelera cósmica?", To = "Yo" },
				{ S = "Pip", T = "«Fallo de la papelera cósmica».", To = "Yo" },
				{ S = "Pip", T = "Es la explicación oficial del señor Cosme.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Claro.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_05_G4_Entra = {
			Light = true,
			Duration = 19,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{ At = 0.4, S = "Pip", T = "Identificación.", To = "Yo" },
					{ At = 3.4, S = "Pip", T = "No disponible.", To = "Yo" },
					{ At = 5.4, S = "Pip", T = "Solo queda un calcetín.", To = "Yo" },
					{ At = 7.8, S = "Pip", T = "Sin pareja.", To = "Yo" },
					{ At = 9.9, S = "Pip", T = "Monstruo emparejado.", To = "Yo" },
					{ At = 13, S = "Pip", T = "Bueno.", To = "Yo" },
					{ At = 16, S = "Pip", T = "Pero estará orgulloso.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_05_G4_Entra" } } },
}
