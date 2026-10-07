-- GUION REESCRITO de Saga_19_Recuerdos (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_19_Recuerdos.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_19_Recuerdos
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_19_Recuerdos.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_19_Recuerdos.md",
	Dialogues = {
		Anclaje = {
			Lines = {
				{ S = "Cosme", T = "Eso. Yo conozco eso.", To = "Yo" },
				{ S = "Cosme", T = "Y yo… Yo me sentí orgulloso. No supe decírtelo.", To = "Yo", Shot = "General" },
			},
		},
		Gallina = {
			Lines = {
				{ S = "Julian", T = "Hombre, Cosme. ¿Vienes a disculparte con Petra? Ya iba siendo hora.", To = "Yo" },
				{ S = "Julian", T = "Solo han pasado… muchos años.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "¡AY! ¡La gallina! ¡La gallina de seis metros! ¡El rayo agrandador!", To = "Yo" },
				{ S = "Julian", T = "Sí. Ella tampoco lo ha olvidado.", To = "Yo" },
				{ S = "Cosme", T = "No sé por qué confiaba en ti.", To = "Yo", Pause = 0.9, If = { Flags = { "GallinaSeisMetros" } } },
				{ S = "Cosme", T = "Pero claramente lo hacía.", To = "Yo", If = { Flags = { "GallinaSeisMetros" } } },
			},
		},
		Lista = {
			Lines = {
				{ S = "Pip", T = "He hecho una lista de sitios donde el señor fue feliz.", To = "Yo" },
				{ S = "Cosme", T = "¿Yo fui feliz? ¿En sitios? ¿Con esta cara? Qué raro.", To = "Yo" },
				{ S = "Pip", T = "Es una lista corta. El señor no salía mucho.", To = "Yo" },
				{ S = "DonEscamas", T = "Eso explica muchas cosas.", To = "Yo" },
				{ S = "Pip", T = "Pero en casi todos estaba usted.", To = "Yo" },
				{ S = "Cosme", T = "Tú. Hay algo contigo.", To = "Yo" },
				{ S = "Cosme", T = "Sé tu nombre. Es lo único que sé segur{o/a}. Lo demás… ya veremos.", To = "Yo", If = { Memories = { "TuNombre" } } },
				{ S = "Cosme", T = "No sé quién eres. Pero no me pareces un desconocido.", To = "Yo", If = { NotMemories = { "TuNombre" } } },
				{ S = "Cosme", T = "Vamos. Pero volvemos pronto.", To = "Yo" },
				{ S = "Cosme", T = "Echo de menos una cosa que no sé cuál es.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Mirad también en los cacharros del garaje.", To = "Yo" },
				{ S = "DonEscamas", T = "Una mente se esconde donde menos te lo esperas.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "En una tostadora, por ejemplo.", To = "Yo" },
				{ S = "DonEscamas", T = "Yo nunca tiro una copia de seguridad.", To = "Yo", Pause = 0.9 },
			},
		},
		Microondas = {
			Lines = {
				{ S = "Pip", T = "Lo he reparado. Más o menos.", To = "Yo" },
				{ S = "Cosme", T = "Eso nunca es una frase tranquilizadora. …No. Martes. Era martes. Tú estabas aquí.", To = "Yo" },
				{ S = "Cosme", T = "Tenías las manos llenas de piezas.", To = "Yo" },
				{ S = "Cosme", T = "Yo te dije que no tocaras nada. Lo tocaste todo.", To = "Yo", Pause = 0.9 },
			},
		},
		Vuelve = {
			Lines = {
				{ S = "Pip", T = "Señor.", To = "Yo" },
				{ S = "Cosme", T = "Criatura. Esta vez no hay duda. Me acuerdo. De todo. El microondas. Las burbujas. El pez. La cinta.", To = "Yo" },
				{ S = "Cosme", T = "La cápsula. Y tú.", To = "Yo" },
				{ S = "Cosme", T = "Los clones.", To = "Yo", Pause = 0.9, If = { Memories = { "LosClones" } } },
				{ S = "Cosme", T = "El tirachinas de tu abu.", To = "Yo", If = { Memories = { "TirachinasAbu" } } },
				{ S = "Cosme", T = "Los calcetines. Nunca encontré el segundo.", To = "Yo", If = { Memories = { "CosasPerdidas" } } },
				{ S = "Cosme", T = "Mi credencial de ayudante.", To = "Yo", If = { Memories = { "AyudanteCosme" } } },
				{ S = "Cosme", T = "El vecino secreto.", To = "Yo", If = { Flags = { "SecretoCosme" } } },
				{
					S = "Cosme",
					T = "Me acuerdo de que viniste a por mí. A otra dimensión. Con zumo de mora.",
					To = "Yo",
					If = { Memories = { "RescateCosme" } },
				},
				{ S = "Pip", T = "Señor. Bienvenido. Otra vez. De verdad esta vez.", To = "Yo" },
				{ S = "Cosme", T = "Gracias. Ahora lo recuerdo.", To = "Yo" },
				{ S = "Cosme", T = "Sé qué me quitó Cósimo.", To = "Yo" },
				{ S = "Cosme", T = "No quería mis recuerdos.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Quería lo que había dentro de ellos.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Sé cómo liberar el Ancla.", To = "Yo" },
				{ S = "DonEscamas", T = "Eso suena bastante importante.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Lo sabe todo. Y viene a por ti.", To = "Yo" },
				{ S = "Cosme", T = "Necesitamos a todo el mundo.", To = "Yo", Pause = 0.9 },
				{ S = "Narrador", T = "O: «Nunca entendí por qué aquel microondas funcionaba.»" },
				{ S = "Narrador", T = "O: «Creo que todavía tengo aquella pieza.»" },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
