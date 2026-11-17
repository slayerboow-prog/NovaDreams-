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
				{ S = "Cosimo", T = "Buenas noches. Perdona la hora. Vengo solo. Ya no me queda nadie a quien mandar.", To = "Yo" },
				{
					S = "Cosimo",
					T = "Me habéis dejado sin el Consorcio. Bien hecho. Nadie lo había conseguido en cuarenta mundos.",
					To = "Yo",
					If = { Memories = { "CaidaConsorcio" } },
				},
				{
					S = "Cosimo",
					T = "Viste la grabación. Sabes lo que eres. Y sabes por qué estoy en tu puerta.",
					To = "Yo",
					If = { Memories = { "EresElAncla" } },
				},
				{
					S = "Cosimo",
					T = "En mi mundo, Lía murió antes de construir nada. Yo me quedé solo con la máquina y la culpa.",
					To = "Yo",
					If = { Memories = { "EresElAncla" } },
				},
				{
					S = "Cosimo",
					T = "La Fusión no es una conquista. Es una corrección. Dos Valmar rotas hacen una entera.",
					To = "Yo",
					If = { Memories = { "EresElAncla" } },
				},
				{
					S = "Cosimo",
					T = "En el mundo fusionado, la Caída nunca ocurrió. Lía está viva. Tu casa del Sur sigue en pie.",
					To = "Yo",
					If = { Memories = { "EresElAncla" } },
				},
				{ S = "Cosimo", T = "Solo tienes que soltar el Ancla. Venir conmigo. Dejar de sujetar.", To = "Yo", If = { Memories = { "EresElAncla" } } },
				{ S = "Yo", T = "¿Y los que viven aquí ahora?", If = { Memories = { "EresElAncla" } } },
				{
					S = "Cosimo",
					T = "Algunos se fusionarán con su otra versión. Otros… no encajarán. Toda corrección tiene un margen de error.",
					To = "Yo",
					If = { Memories = { "EresElAncla" } },
				},
			},
		},
		Respuesta = {
			Lines = {
				{ S = "Cosimo", T = "Ya. Como él. Siempre prefiriendo un mundo roto que uno arreglado por mí.", To = "Yo", If = { Choices = { Trato = "No" } } },
				{
					S = "Cosimo",
					T = "Te espero en el Monte del Silencio. Trae a quien quieras. Yo llevaré el final.",
					To = "Yo",
					If = { Choices = { Trato = "No" } },
				},
				{ S = "Cosimo", T = "Aceptas. Bien. En la cima del monte, mañana a medianoche.", To = "Yo", If = { Choices = { Trato = "Trampa" } } },
				{
					S = "Cosimo",
					T = "…No me mires así. Sé reconocer una mentira. Pero vendré igual. No me queda otra.",
					To = "Yo",
					If = { Choices = { Trato = "Trampa" } },
				},
				{
					S = "Narrador",
					T = "Cósimo se va. Te quedas en la puerta con las manos frías. Llamas a Cosme. Contesta al primer tono: estaba esperando.",
					If = { Choices = { Trato = "Trampa" } },
				},
			},
		},
	},
	Scenes = {
		Saga_22_G2_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosimo", Npc = "Cosimo" } } },
				Dialogue = { { At = 0.4, S = "Cosimo", T = "Piénsalo. Pero no tardes. La costura no aguanta mucho más.", To = "Yo" } },
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Saga_22_G2_Entra" } } },
}
