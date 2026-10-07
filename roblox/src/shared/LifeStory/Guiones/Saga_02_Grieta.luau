-- GUION REESCRITO de Saga_02_Grieta (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_02_Grieta.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_02_Grieta
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_02_Grieta.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_02_Grieta.md",
	Dialogues = {
		Bigotes = {
			Lines = {
				{ S = "Bigotes", T = "Has tardado. Los humanos sois lentos.", To = "Yo", Effects = { Scene = "Saga_02_G4_Musica" } },
				{ S = "Bigotes", T = "Y deja de fingir que no sabes que hablo.", To = "Yo", If = { Flags = { "BigotesHabla" } } },
				{
					S = "Bigotes",
					T = "Te habla Bigotes XVII. Emperador. Exiliado. Deudor tuyo, por lo de las cucarachas. No te acostumbres.",
					If = { Memories = { "EmperadorBigotes" } },
				},
				{ S = "Bigotes", T = "Miau. Bueno. Ya lo sabes.", To = "Yo", If = { NotFlags = { "BigotesHabla" } } },
				{ S = "Bigotes", T = "La Grieta no es nueva.", To = "Yo" },
				{ S = "Yo", T = "¿La habías visto antes?" },
				{ S = "Bigotes", T = "Una vez. En Gatonia. Nosotros la llamamos «La Puerta Mal Cerrada».", To = "Yo" },
				{ S = "Yo", T = "¿Qué hay al otro lado?" },
				{ S = "Bigotes", T = "Problemas. Cucarachas. Cobradores.", To = "Yo" },
				{ S = "Bigotes", T = "Y gente que vende cosas. Mucha gente. Demasiada.", To = "Yo", Pause = 0.9 },
				{ S = "Bigotes", T = "Pero esta vez he oído una voz.", To = "Yo" },
				{ S = "Yo", T = "¿De quién?" },
				{ S = "Bigotes", T = "De un hombre. Muy elegante. Dijo tu nombre. Varias veces.", To = "Yo" },
				{ S = "Bigotes", T = "Como quien cuenta monedas. Yo tendría cuidado.", To = "Yo", Pause = 0.9 },
				{ S = "Bigotes", T = "Y no se lo digas a nadie.", To = "Yo" },
				{ S = "Bigotes", T = "Especialmente al inventor.", To = "Yo", Pause = 0.9 },
			},
		},
		Calcetin = {
			Lines = {
				{ S = "Pip", T = "Lectura dimensional elevada. Y olor a calcetín.", To = "Yo" },
				{ S = "Pip", T = "Otro universo. Mismo problema.", To = "Yo", Pause = 1.8 },
				{ S = "Pip", T = "¿Sabes cuánto tiempo llevo buscando? Prefiero no saberlo.", To = "Yo" },
			},
		},
		Medidor = {
			Lines = {
				{
					S = "Pip",
					T = "Señor Cosme, considero que el aparato está intentando decirnos algo.",
					To = "Yo",
					Pause = 0.9,
					Effects = { Scene = "Saga_02_G1_Musica" },
				},
				{ S = "Cosme", T = "¡Sí! Que funciona.", To = "Yo" },
				{ S = "Pip", T = "Lleva pitando tres horas.", To = "Yo" },
				{ S = "Cosme", T = "Entonces funciona muchísimo. ¡Criatura!", To = "Yo" },
				{ S = "Cosme", T = "Mi vecin{o/a} favorit{o/a}. Ven.", To = "Yo", If = { Flags = { "SecretoCosme", "AmigoDeCosme" } } },
				{ S = "Cosme", T = "Y cierra eso. La Grieta ha crecido.", To = "Yo", If = { Flags = { "SecretoCosme" } } },
				{ S = "Cosme", T = "Tenemos que hablar de lo de ayer.", To = "Yo", If = { NotFlags = { "SecretoCosme" } } },
				{ S = "Cosme", T = "Pero primero mira esto.", To = "Yo", Pause = 0.9, If = { NotFlags = { "SecretoCosme" } } },
				{ S = "Cosme", T = "Mi medidor de rarezas.", To = "Yo" },
				{ S = "Yo", T = "¿Qué mide?" },
				{ S = "Cosme", T = "Rarezas. Técnicamente, cosas que no deberían existir aquí. Exacto.", To = "Yo" },
				{ S = "Pip", T = "Señor, el nivel ha aumentado otra vez.", To = "Yo" },
				{ S = "Cosme", T = "¿Cuánto?", To = "Yo" },
				{ S = "Pip", T = "Demasiado.", To = "Yo" },
				{ S = "Cosme", T = "Esta mañana ha pitado tanto que Pip se ha reiniciado.", To = "Yo" },
				{ S = "Pip", T = "No me reinicié. Me tomé un descanso técnico.", To = "Yo" },
				{ S = "Cosme", T = "Se desmayó.", To = "Yo" },
				{ S = "Pip", T = "Con elegancia.", To = "Yo" },
				{ S = "Cosme", T = "Esta noche han caído cosas de la Grieta. Tres, como mínimo.", To = "Yo" },
				{ S = "Yo", T = "¿Cosas?" },
				{ S = "Cosme", T = "Cosas que no son de aquí.", To = "Yo" },
				{ S = "Cosme", T = "Tenemos que encontrarlas antes que alguien más.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "O algo más.", To = "Yo" },
				{
					Ask = "¿Qué dices?",
					Options = {
						{
							T = "«¿Qué puede haber ahí fuera?»",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = { { S = "Cosme", T = "Esa es una pregunta excelente.", To = "Yo" }, { S = "Cosme", T = "Y una pregunta peligrosa.", To = "Yo", Pause = 0.9 } },
						},
						{
							T = "«Yo voy a buscarlas.»",
							Effects = { Traits = { Valentia = 1 } },
							Then = {
								{ S = "Cosme", T = "¿Tú? Cada vez te pareces más a mí.", To = "Yo" },
								{ S = "Pip", T = "Señor, eso no es necesariamente bueno.", To = "Yo" },
								{ S = "Cosme", T = "Gracias, Pip.", To = "Yo" },
							},
						},
					},
				},
				{ S = "Cosme", T = "Pip irá contigo.", To = "Yo" },
				{ S = "Pip", T = "Será un honor. Aunque me gustaría dejar constancia de que nadie me ha preguntado.", To = "Yo" },
				{ S = "Cosme", T = "Porque sabía lo que ibas a decir.", To = "Yo" },
				{ S = "Pip", T = "Correcto.", To = "Yo" },
			},
		},
		Moneda = {
			Lines = {
				{ S = "Yo", T = "¿Qué pasa?" },
				{ S = "Pip", T = "Esa cara… No debería estar aquí.", To = "Yo" },
				{ S = "Pip", T = "Llévesela al señor Cosme. Ahora.", To = "Yo" },
			},
		},
		Paraguas = { Lines = { { S = "Pip", T = "Extraordinario. Y ligeramente húmedo.", To = "Yo" } } },
		Perilla = {
			Lines = {
				{ S = "Cosme", T = "Bueno. Muy raro. PPP — Ojos de Cosme.", To = "Yo" },
				{ S = "Pip", T = "Señor. ¿Es él?", To = "Yo" },
				{ S = "Cosme", T = "Sí.", To = "Yo" },
				{ S = "Yo", T = "¿Quién es?" },
				{ S = "Cosme", T = "Cósimo.", To = "Yo" },
				{ S = "Yo", T = "¿Quién es Cósimo?", Pause = 0.9 },
				{ S = "Cosme", T = "Un antiguo socio. Hace mucho tiempo.", To = "Yo" },
				{ S = "Yo", T = "¿Y qué tiene que ver con la Grieta?" },
				{ S = "Cosme", T = "Demasiado.", To = "Yo" },
				{ S = "Narrador", T = "¿Seguro que quieres abrirla?" },
				{ S = "Yo", T = "¿Qué habéis hecho?" },
				{ S = "Cosme", T = "Un error. Uno muy grande.", To = "Yo" },
				{ S = "Pip", T = "Señor Cosme…", To = "Yo" },
				{ S = "Cosme", T = "Todavía no. Tú te la quedas.", To = "Yo" },
				{ S = "Yo", T = "¿Por qué?" },
				{ S = "Cosme", T = "Porque él ya sabe que existes.", To = "Yo" },
				{ S = "Yo", T = "¿Quién?", Pause = 0.9 },
				{ S = "Cosme", T = "Cósimo. Vete a casa.", To = "Yo" },
				{ S = "Yo", T = "¿Por qué?" },
				{ S = "Cosme", T = "Porque mañana volveremos a hablar. Y esta vez… Te contaré la verdad.", To = "Yo" },
				{ S = "Pip", T = "Señor. ¿Cree que él nos ha encontrado?", To = "Yo" },
				{ S = "Cosme", T = "No. Creo que nos encontró hace mucho tiempo.", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Saga_02_G1_Musica = {
			Light = true,
			Duration = 92.4,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 46.2, Intensity = "Tension" } } },
		},
		Saga_02_G4_Musica = { Light = true, Duration = 51.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = {
		["3.1"] = { Set = { Text = "Investiga el cráter junto a la fuente." } },
		["3.2"] = { Set = { Text = "Investiga el cráter de la zona de juegos." } },
		["3.3"] = { Set = { Text = "Investiga el tercer cráter." } },
		["5"] = { Set = { Text = "Lleva los objetos al garaje de Cosme." } },
	},
}
