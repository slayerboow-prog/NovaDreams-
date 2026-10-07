-- GUION REESCRITO de Saga_22_Ancla (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_22_Ancla.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_22_Ancla
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_22_Ancla.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_22_Ancla.md",
	Dialogues = {
		Oferta = {
			Lines = {
				{ S = "Cosimo", T = "Buenas noches. Perdona la hora. Traigo flores. De la 66-B. Muerden un poco. No las toques.", To = "Yo", Pause = 1.8 },
				{ S = "Cosimo", T = "Son temperamentales. Bonita casa. Bonita vida. Te la has ganado.", To = "Yo" },
				{ S = "Cosimo", T = "Me habéis arruinado el Consorcio. Muy bien hecho. Me impresionas.", To = "Yo", If = { Memories = { "CaidaConsorcio" } } },
				{ S = "Cosimo", T = "Así que esta es tu vida.", To = "Yo" },
				{ S = "Cosimo", T = "Familia. Amigos. Trabajo. Recuerdos. Todo lo que yo perdí.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "Ya viste la cinta del archivo.", To = "Yo", If = { Memories = { "EresElAncla" } } },
				{ S = "Cosimo", T = "Entonces sabes lo que eres.", To = "Yo", Pause = 0.9, If = { Memories = { "EresElAncla" } } },
				{ S = "Cosimo", T = "Y sabes por qué estoy aquí.", To = "Yo", If = { Memories = { "EresElAncla" } } },
				{ S = "Cosimo", T = "He venido a negociar. Como la gente civilizada. Con perilla.", To = "Yo" },
				{ S = "Cosimo", T = "En mi Valmar puedo darte la vida perfecta. El mejor trabajo. La casa más grande.", To = "Yo" },
				{ S = "Cosimo", T = "Un gato que te hace caso.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "Solo tienes que venir conmigo. Soltar el Ancla. Nada más.", To = "Yo" },
				{ S = "Cosimo", T = "No te estoy pidiendo que destruyas nada.", To = "Yo" },
				{ S = "Cosimo", T = "Solo que me dejes volver.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "¿Sabes lo que es quedarse al otro lado veinte años? Solo.", To = "Yo" },
				{ S = "Cosimo", T = "Porque alguien te soltó la mano.", To = "Yo" },
				{ S = "Cosimo", T = "Yo solo quiero volver. A lo grande.", To = "Yo" },
				{ S = "Cosimo", T = "Con las dos Valmar para mí.", To = "Yo" },
				{ S = "Cosimo", T = "Y entonces nadie volverá a dejarme fuera.", To = "Yo" },
			},
		},
		Respuesta = {
			Lines = {
				{ S = "Cosimo", T = "¿No? Así de simple. Qué predecible. Como él.", To = "Yo", Pause = 0.9, If = { Choices = { Trato = "No" } } },
				{ S = "Cosimo", T = "Os parecéis tanto que da rabia.", To = "Yo", If = { Choices = { Trato = "No" } } },
				{
					S = "Cosimo",
					T = "Nos veremos en el Monte del Silencio, Ancla. Trae a quien quieras. Yo traeré el final.",
					To = "Yo",
					If = { Choices = { Trato = "No" } },
				},
				{ S = "Cosimo", T = "¿Aceptas? ¡Maravilloso!", To = "Yo", Pause = 0.9, If = { Choices = { Trato = "Trampa" } } },
				{
					S = "Cosimo",
					T = "Nos vemos en la cima del monte. Mañana a medianoche. Ven solo. O sola.",
					To = "Yo",
					If = { Choices = { Trato = "Trampa" } },
				},
				{ S = "Cosimo", T = "…¿Por qué sonríes así? Bah. Será la emoción.", To = "Yo", If = { Choices = { Trato = "Trampa" } } },
				{ S = "Narrador", T = "Cósimo se va. Te quedas mirando las flores que muerden.", Pause = 0.9, If = { Choices = { Trato = "Trampa" } } },
				{ S = "Narrador", T = "Mañana es la Gran Fusión.", Pause = 0.9, If = { Choices = { Trato = "Trampa" } } },
				{
					S = "Cosme",
					T = "Llamando… Estaba esperando la llamada. ¿Ha venido? Entonces ya empezó. No estás solo.",
					To = "Yo",
					If = { Choices = { Trato = "Trampa" } },
				},
				{
					S = "Narrador",
					T = "Entonces comprende: «Me has engañado.»",
					Pause = 0.9,
					If = { Choices = { Trato = "Trampa" }, Flags = { "TrampaCosimo" } },
				},
				{ S = "Narrador", T = "No sabes si son un regalo, una amenaza o ambas cosas.", If = { Choices = { Trato = "Trampa" } } },
				{ S = "Cosimo", T = "Segunda fase", To = "Yo", If = { Choices = { Trato = "Trampa" } } },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
