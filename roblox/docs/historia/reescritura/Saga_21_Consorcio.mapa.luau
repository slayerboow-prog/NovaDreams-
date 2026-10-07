-- Mapa del guion reescrito de Saga_21_Consorcio (lo lee scripts/audit/aplicar-reescritura.luau).
-- 4 PASO = 3 pasos del juego (el guion tiene dos «PASO 1»: la pelea y su final van al asalto). El asalto
-- (apartar a la seguridad), el pendrive de Don Escamas en el servidor y la quiebra con el agente Glub.
return {
	Prefijo = "Saga_21",
	Hablantes = { ["Otro NPC"] = "@Vecino", ["Agente Glub"] = "Glub" },
	Variables = {
		-- (si te detectan, la pelea del juego te devuelve al punto seguro: no se sabe cuándo pasa)
		["el jugador es detectado"] = { Nunca = true },
		recuerdo_proyecto_fusion = { If = { Flags = { "SabeFusion" } } },
		sabe_fusion = { If = { Flags = { "SabeFusion" } } },
		deuda_galactica = { If = { Flags = { "DeudaGalactica" } } },
		recuerdo_equipo_rescate = { If = { Memories = { "EquipoRescate" } } },
		gris_arrepentida = { If = { Flags = { "GrisArrepentida" } } },
		consorcio_caido = { Flag = "ConsorcioCaido" },
		cosimo_sin_financiacion = { If = {} },
	},
	Informe = "La mecánica es la de siempre: el asalto a la oficina de MegaVerso (la de Saga_08; no hay sótano ni sala de servidores nueva: el servidor es el objeto de siempre), apartar a la seguridad sin violencia, enchufar el pendrive con forma de pez y la quiebra con el agente Glub del Banco Galáctico (ConsorcioCaido y el recuerdo CaidaConsorcio). Las variantes van con las marcas reales: GrisArrepentida (Saga_11), DeudaGalactica, SabeFusion (Saga_08) y el recuerdo EquipoRescate. Si te detectan, la pelea ya te devuelve al punto seguro; lo que dice Candela en ese momento no tiene cuándo salir (pendiente). Las pantallas apagadas y las noticias por la ciudad serían un sistema de frases de ambiente nuevo (pendiente); cosimo_sin_financiacion no se crea (nada la lee).",
}
