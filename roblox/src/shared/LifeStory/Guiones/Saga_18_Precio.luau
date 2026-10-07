-- GUION REESCRITO de Saga_18_Precio (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_18_Precio.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_18_Precio
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_18_Precio.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_18_Precio.md",
	Dialogues = {
		Anuncio = {
			Lines = {
				{ S = "Cosme", T = "¿Esto sirve para algo?", To = "Yo" },
				{ S = "Pip", T = "Sí, señor. Usted lo inventó.", To = "Yo" },
				{ S = "Cosme", T = "Eso explica por qué no entiendo nada.", To = "Yo" },
				{ S = "Pip", T = "No. Eso no debería estar ocurriendo.", To = "Yo" },
				{ S = "Pip", T = "Incluso una pequeña pantalla dentro de una máquina.", To = "Yo" },
				{ S = "Cosimo", T = "Está perfectamente iluminado. ¡Buenos días, Valmar! Tengo un anuncio.", To = "Yo" },
				{ S = "Cosimo", T = "La Gran Fusión se celebrará en el Monte del Silencio.", To = "Yo" },
				{ S = "Cosimo", T = "Cuando el Ancla ya no sea una criatura.", To = "Yo" },
				{ S = "Cosimo", T = "Cuando sea una persona adulta. Con trabajo.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "Con responsabilidades. Y con facturas.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "Porque los adultos, querido público…", To = "Yo" },
				{ S = "Cosimo", T = "…están tan cansados que sueltan cualquier cosa. Hasta un universo.", To = "Yo" },
				{ S = "Pip", T = "Nos ha dado tiempo. Años.", To = "Yo" },
				{ S = "Pip", T = "Tiempo para que el señor recupere la memoria.", To = "Yo" },
				{ S = "Pip", T = "Y tiempo para prepararnos.", To = "Yo" },
				{ S = "Cosimo", T = "No se lo pierdan. Entradas ya disponibles en MegaVerso.", To = "Yo" },
				{ S = "Cosimo", T = "Nos vemos cuando seas adulto. Ancla.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "¿Quién era ese?", To = "Yo" },
				{ S = "Pip", T = "Un viejo amigo suyo.", To = "Yo" },
				{ S = "Cosme", T = "No me gusta.", To = "Yo" },
				{ S = "Pip", T = "A mí tampoco.", To = "Yo" },
			},
		},
		Nombre = {
			Lines = {
				{ S = "Cosme", T = "Mira. No sé quién eres. Pero cuando entras…", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Este garaje huele distinto. Huele a… Burbujas. ¿Tiene sentido? No tiene sentido.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Tengo un hueco aquí dentro. Muy grande. Y cuando te miro…", To = "Yo" },
				{ S = "Cosme", T = "El hueco se hace más pequeñ{o/a}. Un poquito.", To = "Yo" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Le cuentas lo del microondas temporal y el bocadillo del martes.»",
							Effects = { Flags = { "RecuerdoMicroondasCompartido" }, Rel = { Cosme = 6 }, Traits = { Humor = 1 } },
							Then = {
								{ S = "Cosme", T = "¿Un microondas que calienta en el pasado?", To = "Yo" },
								{ S = "Cosme", T = "Qué idea más estúpida. Y más genial. ¿Fue idea mía? Claro. Tenía que ser mía.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«Le dices tu nombre y le das la mano.»",
							Effects = { Flags = { "CosmeRecuerdaNombre" }, Rel = { Cosme = 8 }, Traits = { Empatia = 2 } },
							Then = {
								{
									S = "Cosme",
									T = "La música comienza muy suavemente. Criatura. Tú eres la criatura. No sé nada más. Pero eso sí lo sé.",
									To = "Yo",
									Pause = 0.9,
								},
							},
						},
					},
				},
				{ S = "Cosme", T = "Si existen suficientes recuerdos de Cosme, añadir pequeñas reacciones. Cuando hablas…", To = "Yo" },
				{ S = "Cosme", T = "Siento que ya he escuchado esa voz cientos de veces.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Y creo que siempre acababas rompiendo algo.", To = "Yo" },
				{ S = "Cosme", T = "Eso también me resulta familiar.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "¿Eso ha sido una foto?", To = "Yo" },
				{ S = "Candela", T = "Sí.", To = "Yo" },
				{ S = "Cosme", T = "¿Salgo bien?", To = "Yo" },
				{ S = "Candela", T = "Más o menos.", To = "Yo" },
				{ S = "Cosme", T = "Entonces es auténtica. No sé cuánto tardaré. En recordarlo todo.", To = "Yo" },
				{ S = "Cosme", T = "Pero creo que tengo tiempo. ¿Verdad? Bien.", To = "Yo" },
				{ S = "Cosme", T = "Entonces mañana trabajamos.", To = "Yo", Pause = 0.9 },
				{ S = "Narrador", T = "Algunos comentan: «¿Has visto el anuncio?»" },
				{ S = "Narrador", T = "«Dicen que será enorme.»" },
				{ S = "Narrador", T = "«No sé qué es MegaVerso, pero tienen mucha publicidad.»" },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
