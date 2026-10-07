-- Mapa del guion reescrito de Saga_23_Fusion (lo lee scripts/audit/aplicar-reescritura.luau).
-- 8 PASO = 8 pasos del juego (la cinemática Grieta_Fusion, la llegada, aguantar la Grieta 25 s, la oleada
-- de drones, los Restos —solo si tienes 4 o más—, Cósimo con o sin Restos y la rendición). El horario
-- (22:00-04:00) y la variante de los Restos no cambian.
return {
	Prefijo = "Saga_23",
	-- (la cinemática Grieta_Fusion se queda como está (su plano de reacción, la variante de los Restos que brillan y lo que Cosme dice si le tendiste una trampa o recuerdas el rasguño): el PASO 1 del guion ya es lo que cuenta)
	Pasos = { ["1"] = false },
	Variables = {
		decision_trato_cosimo = { Choice = "Trato", Valores = { No = "No", no = "No", Rechazo = "No", Trampa = "Trampa", trampa = "Trampa" } },
		trampa_cosimo = { If = { Flags = { "TrampaCosimo" } } },
		consorcio_caido = { If = { Flags = { "ConsorcioCaido" } } },
		perdona_cosme = { If = { Flags = { "PerdonaACosme" } } },
		enfado_con_cosme = { If = { Flags = { "EnfadoConCosme" } } },
		cosimo_perdonado = { Flag = "CosimoPerdonado" },
		cosimo_arregla_66b = { Flag = "CosimoArregla66B" },
		-- (nunca hay K.O.: si te pillan, un aliado te saca y sigues; esas frases no tienen cuándo salir)
		["el jugador es atrapado"] = { Nunca = true },
		["el jugador es alcanzado"] = { Nunca = true },
	},
	Informe = "La mecánica es la de siempre: la cinemática Grieta_Fusion de siempre (con su reacción, sus variantes y su música; el guion nuevo cuenta lo mismo), la llegada a la cima, aguantar 25 segundos el tirón de la Grieta (la versión de siempre, con sus zonas seguras), la oleada de drones con tus aliados (los que vinieron: sus marcas Aliado*), los Restos si tienes 4 o más, Cósimo y la rendición con la decisión final (CosimoPerdonado / CosimoArregla66B, las marcas que lee Saga_24). Las variantes van con la decisión Trato de Saga_22 (No / Trampa), ConsorcioCaido, PerdonaACosme / EnfadoConCosme. Sin K.O. ni hospital: si te alcanzan, el paso te recoloca y sigues (las frases de «si te atrapan» no tienen cuándo salir). Los micro-recuerdos de los Restos son frases cortas de la escena, sin pausar el juego.",
}
