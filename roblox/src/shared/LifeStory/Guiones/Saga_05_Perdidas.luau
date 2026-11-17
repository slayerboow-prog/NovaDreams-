-- GUION REESCRITO de Saga_05_Perdidas (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_05_Perdidas.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_05_Perdidas
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_05_Perdidas.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_05_Perdidas.md",
	Dialogues = {
		Balon = {
			Lines = { { S = "Narrador", T = "Un balón pequeñ{o/a}, gastado. Con rotulador: «De Teo». Nico tenía un hermano pequeñ{o/a} que se llamaba Teo." } },
		},
		DevolverBalon = {
			Lines = {
				{ S = "Nico", T = "Es de Teo. Lo llevaba siempre.", To = "Yo" },
				{ S = "Nico", T = "Yo le solté la mano cuando corríamos. Un segundo. Fue suficiente.", To = "Yo" },
				{ S = "Nico", T = "…Gracias por traérmelo. No sé si quería volver a verlo. Pero gracias.", To = "Yo" },
			},
		},
		DevolverDiario = {
			Lines = {
				{ S = "Lucia", T = "Lo escribí en el refugio, mientras esperábamos. Para no pensar.", To = "Yo" },
				{ S = "Lucia", T = "La última página dice: «Si alguien lee esto, que sepa que lo intentamos».", To = "Yo" },
				{ S = "Lucia", T = "Gracias. Hay cosas que perdemos y no sabemos cuánto pesaban hasta que vuelven.", To = "Yo" },
				{ S = "Narrador", T = "Del gimnasio llega un ruido enorme. Como si toda la montaña de objetos se moviera a la vez." },
			},
		},
		DevolverLlaves = {
			Lines = {
				{ S = "Ramon", T = "Las llaves de mi casa. La casa ya no existe. Las llaves sí.", To = "Yo" },
				{ S = "Ramon", T = "Gracias. Las guardaré. Algún día volveré al Sur y abriré lo que quede de la puerta.", To = "Yo" },
			},
		},
		Diario = {
			Lines = {
				{ S = "Narrador", T = "Un diario de tapas amarillas. En la portada: «Lucía. Evacuación del Sur». Escrito durante la noche de la Caída." },
				{
					Ask = "¿Lo abres?",
					Options = {
						{ T = "No. No es mío.", Effects = { Rel = { Lucia = 3 }, Traits = { Responsabilidad = 1 } } },
						{
							T = "Solo la primera página…",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Narrador", T = "Primera página: «Hora 2. No hay luz. Los niños preguntan por sus padres y no sé qué decirles»." },
								{ S = "Narrador", T = "Cierras el diario.", Pause = 0.6 },
							},
						},
					},
				},
			},
		},
		Final = {
			Lines = {
				{ S = "Pip", T = "Neutralizado. Los objetos vuelven a ser solo objetos.", To = "Yo" },
				{ S = "Pip", T = "Esta vez lo ha visto medio Distrito Central. Ya no se podrá ocultar.", To = "Yo" },
				{ S = "Pip", T = "Y la Grieta sigue creciendo. El doctor Cosme dice que hay que cerrarla. Esta semana.", To = "Yo" },
				{ S = "Narrador", T = "Entre los restos queda un calcetín de niño, chamuscado. Nadie lo reclama. Te lo guardas." },
			},
		},
		Llaves = {
			Lines = { { S = "Narrador", T = "Un manojo de llaves con una etiqueta escrita a mano: «Casa. Calle del Molino, 14». Es la letra de Ramón." } },
		},
		Ramon = {
			Lines = {
				{ S = "Ramon", T = "Treinta años cuidando este edificio. Primero colegio, luego refugio, ahora Academia.", To = "Yo" },
				{ S = "Ramon", T = "Esta noche el gimnasio se ha llenado hasta el techo. Mochilas, zapatos, juguetes. Todo de la noche de la Caída.", To = "Yo" },
				{ S = "Ramon", T = "Hay cosas con nombre. He reconocido una chaqueta. Era de mi vecino del Sur.", To = "Yo" },
				{ S = "Pip", T = "La Grieta absorbió muchas cosas aquella noche. Ahora las está devolviendo. No sabemos por qué.", To = "Yo" },
				{ S = "Pip", T = "El doctor Cosme sugiere devolver primero lo que tenga dueño vivo. Lo demás… lo catalogaremos.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_05_G4_Entra = {
			Light = true,
			Duration = 18.4,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{
						At = 0.4,
						S = "Narrador",
						T = "Los objetos se juntan y se levantan. Una figura enorme hecha de mochilas, zapatos y chaquetas. Algo de la Grieta la mueve por dentro.",
					},
					{ At = 10.7, S = "Pip", T = "No es un recuerdo. Es una bestia que usa los restos como armadura. Golpee donde brilla.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Saga_05_G4_Entra" } } },
}
