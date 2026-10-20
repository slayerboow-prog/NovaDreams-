-- Mapa del guion reescrito de Saga_18_Precio (lo lee scripts/audit/aplicar-reescritura.luau).
-- 2 PASO = 2 pasos del juego (el anuncio de Cósimo en las pantallas y sentarte con Cosme).
return {
	Prefijo = "Saga_18",
	Informe = "La mecánica es la de siempre: el anuncio de Cósimo (la Gran Fusión) y la conversación con Cosme, que no recuerda nada y acaba recordando tu nombre (el recuerdo TuNombre y la foto sin memoria). Encaja con Saga_17: Cosme pierde la memoria al cruzar la Grieta de vuelta.",
	-- (la acotación de la música se pegaba a la frase de Cosme; «el hueco se hace más pequeño» habla del
	-- hueco, no de ti: sin {o/a})
	SiTexto = { { "La música comienza muy suavemente.", { Nunca = true } } },
	SinGenero = { "El hueco se hace más pequeño." },
}
