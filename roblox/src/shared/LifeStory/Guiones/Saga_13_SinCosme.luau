-- GUION REESCRITO de Saga_13_SinCosme (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_13_SinCosme.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_13_SinCosme
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_13_SinCosme.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_13_SinCosme.md",
	Dialogues = {
		Cuaderno = {
			Lines = {
				{ S = "Narrador", T = "El cuaderno de Cosme. Coordenadas, cálculos y una página con el título «Si me pasa algo»." },
				{ S = "Narrador", T = "1. G-4: el refugio de la gente de Bigotes. Él sabe llegar a la 66-B." },
				{ S = "Narrador", T = "2. La capitana Ñoz vende información de todas las dimensiones. Cara, pero nunca falla." },
				{ S = "Narrador", T = "3. Que no vaya sin compañía." },
				{ S = "Narrador", T = "Debajo, más pequeñ{o/a}, tachado pero legible: «Dile que estoy orgulloso. Por si acaso»." },
			},
		},
		Mando = {
			Lines = {
				{ S = "Narrador", T = "En el banco de trabajo, un mando de salto entre dimensiones, a medio montar." },
				{ S = "Pip", T = "Lo dejó casi terminado. Siempre deja las cosas casi terminadas. Dame diez minutos.", To = "Yo" },
			},
		},
		Pip = {
			Lines = {
				{ S = "Pip", T = "Llevo ciento doce días manteniendo el garaje igual que lo dejó. Por si vuelve.", To = "Yo" },
				{ S = "Pip", T = "La lectura de la Grieta sube cada noche. Él sabría qué hacer. Yo solo sé medirla.", To = "Yo" },
				{ S = "Pip", T = "He calculado nuestras posibilidades de traerle de vuelta solos. No le voy a decir el número.", To = "Yo" },
				{ S = "Pip", T = "Pero con un equipo, los números cambian.", To = "Yo" },
				{ S = "Pip", T = "El doctor dejó dicho que usted sabría qué hacer. No sé si lo creía o lo deseaba. Pero aquí estamos.", To = "Yo" },
				{
					S = "Pip",
					T = "Desde su ceremonia, el garaje está en silencio. Nunca pensé que echaría de menos sus explosiones.",
					If = { Memories = { "GraduacionInterdimensional" } },
				},
				{
					S = "DonEscamas",
					T = "Usted me sacó del parque delante del Consorcio. Ahora me toca a mí ayudar a sacar a alguien.",
					If = { Memories = { "DonEscamas" } },
				},
				{
					S = "Pip",
					T = "Además, tiene la credencial del laboratorio. Eso le convierte en responsable en su ausencia.",
					G = "Nod",
					If = { Flags = { "AyudanteOficial" } },
				},
			},
		},
		Plan = {
			Lines = {
				{ S = "Sorel", T = "Primero G-4, luego la capitana, luego la 66-B. Y luego volvemos. Todos.", To = "Yo" },
				{
					S = "Brenn",
					T = "Kael no puede saberlo oficialmente. Extraoficialmente, ha dicho que no quiere enterarse de nada hasta que volvamos.",
					To = "Yo",
				},
				{ S = "Pip", T = "Iré con ustedes. El doctor me pidió que no fuera sin compañía. Por una vez, voy a obedecerle sin discutir.", To = "Yo" },
				{
					S = "Narrador",
					T = "Te llevas el cuaderno de Cosme. Ya hay un equipo de rescate: dos guerreros de la Academia, un androide, un desertor del Consorcio y tú.",
				},
			},
		},
	},
	Scenes = {},
	Steps = {},
}
