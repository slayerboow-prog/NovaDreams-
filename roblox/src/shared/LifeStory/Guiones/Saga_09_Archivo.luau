-- GUION REESCRITO de Saga_09_Archivo (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_09_Archivo.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_09_Archivo
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_09_Archivo.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_09_Archivo.md",
	Dialogues = {
		Caja = {
			Lines = {
				{
					S = "Narrador",
					T = "Dentro de la caja: los planos de la aguja, una bata quemada y una foto de Cosme con una mujer joven delante de una máquina.",
				},
				{ S = "Narrador", T = "Y una memoria con una etiqueta escrita a mano: «Lía. La noche»." },
			},
		},
		Cosme = {
			Lines = {
				{ S = "Cosme", T = "Pip. Te dije que nunca.", To = "Yo" },
				{ S = "Pip", T = "Y también me dijo que, si alguna vez tenía que elegir entre obedecerle y cuidarle, le cuidara.", To = "Yo" },
				{
					S = "Cosme",
					T = "Cósimo quiere la Fusión: juntar su Valmar con la nuestra. Para eso necesita que el Ancla desaparezca.",
					To = "Yo",
					If = { NotFlags = { "SabeFusion" } },
				},
				{
					S = "Cosme",
					T = "La Fusión que viste en su oficina. Para eso necesita que el Ancla desaparezca.",
					To = "Yo",
					If = { Flags = { "SabeFusion" } },
				},
				{
					S = "Cosme",
					T = "Que te vayas de este mundo o que la costura se rompa del todo. El Consorcio le paga el resto.",
					To = "Yo",
					If = { Flags = { "SabeFusion" } },
				},
				{ S = "Pip", T = "Tome. Es suya. Es su historia también.", To = "Yo", If = { Flags = { "SabeFusion" } } },
				{
					Ask = "Cosme te mira. ¿Qué le dices?",
					Options = {
						{
							T = "«Me has estado vigilando todo este tiempo. Gracias.»",
							Effects = { Flags = { "PerdonaACosme" }, Rel = { Cosme = 12 }, Traits = { Empatia = 2 } },
							Then = { { S = "Cosme", T = "No me des las gracias. Lía te sacó de allí. Yo solo he intentado que no fuera para nada." } },
						},
						{
							T = "«¿Por qué no me lo dijiste antes?»",
							Effects = { Flags = { "EnfadoConCosme" }, Rel = { Cosme = 4 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Cosme", T = "Porque hasta que el núcleo brilló en tu mano no estaba seguro de que fueras tú. Y porque no sabía cómo decírtelo." },
								{ S = "Cosme", T = "Tienes razón. Debí hacerlo antes. Lo siento." },
							},
						},
					},
				},
			},
		},
		Pip = {
			Lines = {
				{ S = "Pip", T = "Buenas noches. Estoy a punto de desobedecer al doctor por primera vez.", To = "Yo" },
				{ S = "Pip", T = "Él cree que le protege no contándoselo. Yo creo que ya no le protege. Solo le deja a oscuras.", To = "Yo" },
				{ S = "Pip", T = "Usted ya oyó la palabra «Ancla». Esta noche sabrá qué significa.", To = "Yo" },
			},
		},
		Proyector = {
			Lines = {
				{ S = "Narrador", T = "La grabación. El laboratorio de Lía, en el Sur. Fuera se oyen sirenas. Es la noche de la Caída." },
				{ S = "Narrador", T = "En la pantalla del laboratorio aparece una cara. Es Cosme, más viejo, con una cicatriz. Cósimo." },
				{ S = "Cosimo", T = "Lía. Otra vez tú. En mi mundo no llegaste a construir nada. Aquí me lo estás poniendo difícil.", To = "Yo" },
				{ S = "Lia", T = "No vas a abrirla.", To = "Yo" },
				{ S = "Narrador", T = "La puerta del laboratorio se abre. Entra corriendo alguien joven, perdido en la evacuación. Eres tú." },
				{ S = "Narrador", T = "La grieta se abre en mitad del laboratorio. Tira de todo. De las mesas. De Lía. De ti." },
				{ S = "Narrador", T = "Y de golpe se frena. Se agarra a algo. A ti." },
				{ S = "Lia", T = "¡Fuera! ¡Corre y no mires atrás!", To = "Yo" },
				{ S = "Narrador", T = "La imagen tiembla. Lía ya no está. La grieta deja de crecer." },
				{ S = "Pip", T = "El doctor encontró esta grabación entre los restos. Tardó un año en atreverse a verla.", To = "Yo" },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
