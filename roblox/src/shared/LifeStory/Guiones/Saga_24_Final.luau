-- GUION REESCRITO de Saga_24_Final (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_24_Final.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_24_Final
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_24_Final.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_24_Final.md",
	Dialogues = {
		Final = {
			Lines = {
				{ S = "Cosimo", T = "Ya está. Ya no eres el Ancla. Ahora eres solo una persona. Con todo lo bueno y lo malo que eso tiene.", To = "Yo" },
				{
					S = "Cosme",
					T = "Te lo digo ahora que tengo todos los recuerdos: estoy orgulloso de ti. Desde el primer día.",
					To = "Yo",
					If = { Memories = { "CosmeRecuerda" } },
				},
				{ S = "Sorel", T = "Se ha cerrado. De verdad. Mira el cielo.", To = "Yo", If = { Memories = { "CosmeRecuerda" } } },
				{ S = "Brenn", T = "Mi hermano habría querido ver esto.", To = "Yo", If = { Memories = { "CosmeRecuerda" } } },
				{ S = "Kael", T = "Guerrero. Hoy no ha caído nadie. Apúntalo: no pasa a menudo.", To = "Yo", If = { Memories = { "CosmeRecuerda" } } },
				{ S = "Pip", T = "Doctor. Hay una señal. Muy débil. Viene del otro lado de la costura.", To = "Yo", If = { Memories = { "CosmeRecuerda" } } },
				{ S = "Pip", T = "Es la baliza del laboratorio del Sur. La de Lía. Sigue emitiendo.", To = "Yo", If = { Memories = { "CosmeRecuerda" } } },
				{ S = "Cosme", T = "Eso no es posible.", To = "Yo", If = { Memories = { "CosmeRecuerda" } } },
				{ S = "Pip", T = "No. Pero está ahí.", To = "Yo", If = { Memories = { "CosmeRecuerda" } } },
				{
					S = "Narrador",
					T = "FIN DE LA SAGA DE LA GRIETA. La Grieta está cerrada. Pero algo, al otro lado, sigue llamando.",
					If = { Memories = { "CosmeRecuerda" } },
				},
				{
					Ask = "¿Qué le dices a Cosme?",
					Options = {
						{
							T = "«Gracias por no dejar de vigilar el cielo.»",
							Effects = { Rel = { Cosme = 20 } },
							Then = { { S = "Cosme", T = "Alguien tenía que hacerlo. Me alegro de que al final no fuera solo yo." } },
						},
						{
							T = "«¿Y ahora qué?»",
							Effects = { Rel = { Cosme = 15 }, Traits = { Curiosidad = 2 } },
							Then = { { S = "Cosme", T = "Ahora, por primera vez en dos años, voy a dormir una noche entera. Mañana ya veremos." } },
						},
					},
				},
			},
		},
		Garaje = {
			Lines = {
				{ S = "Cosme", T = "Esa pieza va al revés.", To = "Yo" },
				{ S = "Cosimo", T = "Va al revés porque tú la habrías puesto al revés. En mi mundo también lo hacías.", To = "Yo" },
				{
					S = "Cosimo",
					T = "Y no me mires así. Voy a quedarme. Ya veré qué hago con un mundo que intenté borrar.",
					To = "Yo",
					If = { Flags = { "CosimoPerdonado" } },
				},
				{
					S = "Cosimo",
					T = "Date prisa. Mañana vuelvo a la 66-B. Tengo un mundo entero que reparar.",
					To = "Yo",
					If = { Flags = { "CosimoArregla66B" } },
				},
				{
					S = "Pip",
					T = "Llevan tres horas discutiendo. Es lo más parecido a una familia que ha habido en este garaje desde la Caída.",
					To = "Yo",
					If = { Flags = { "CosimoArregla66B" } },
				},
				{
					S = "Cosme",
					T = "Hay que cerrarla desde los dos lados a la vez. Él desde el suyo, yo desde aquí.",
					To = "Yo",
					If = { Flags = { "ConsorcioCaido" } },
				},
				{ S = "Cosme", T = "Y tú en el centro. Donde empezó todo para ti: el patio de la Academia.", To = "Yo", If = { Flags = { "ConsorcioCaido" } } },
			},
		},
	},
	Scenes = {},
	Steps = { ["2"] = { Set = { Text = "Ve al patio de la Academia, donde clavaste el primer anclaje" } } },
}
