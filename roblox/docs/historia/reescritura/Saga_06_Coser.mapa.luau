-- Mapa del guion reescrito de Saga_06_Coser (lo lee scripts/audit/aplicar-reescritura.luau).
-- 8 PASO = 5 pasos del juego (el 2 es el grupo de los tres anclajes: parque, patio del cole y plaza).
return {
	Prefijo = "Saga_06",
	-- (la cinemática Grieta_Coser se queda como está (su música por intensidad y la variante en la que Pip ve a Ramón en la ventana si el barrio vio las rarezas): el PASO 4 del guion ya es lo que cuenta)
	Pasos = { ["4"] = false },
	Variables = {
		-- (lo que se sabe del Consorcio: la tarjeta de los agentes de Saga_03 y la ventanilla de Saga_04)
		["el jugador tiene la informacion del consorcio"] = { If = { Flags = { "ConoceConsorcio" } } },
		-- (la palabra «Ancla» que se oye en la ventanilla de Saga_04)
		["el jugador conoce la informacion del ancla"] = { If = { Flags = { "OyoAncla" } } },
	},
	Informe = "La mecánica es la de siempre: el plan de Cosme en el garaje, los tres anclajes (parque, patio del cole y plaza), la pelea con los agentes grises por la aguja, la cinemática Grieta_Coser de siempre (con su música y la variante de Ramón en la ventana; el guion nuevo cuenta lo mismo) y la voz de Cósimo al final. Lo que Don Escamas dice del Consorcio sale con ConoceConsorcio (la tarjeta de los agentes, Saga_03) y lo de las anclas con OyoAncla (Saga_04): son las marcas que ya guarda la saga.",
}
