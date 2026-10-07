-- Mapa del guion reescrito de Saga_24_Final (lo lee scripts/audit/aplicar-reescritura.luau).
-- 4 PASO = 4 pasos del juego (el garaje, ir al patio del cole, la cinemática Grieta_Final y el final).
return {
	Prefijo = "Saga_24",
	-- (la Grieta se abrió la noche en que naciste: el año depende de tu partida, así que «2003» es «aquella noche»)
	Reemplazos = {
		["en 2003"] = "aquella noche",
		["Como en 2003."] = "Como aquella noche.",
	},
	Variables = {
		cosimo_perdonado = { If = { Flags = { "CosimoPerdonado" } } },
		cosimo_arregla_66b = { If = { Flags = { "CosimoArregla66B" } } },
		consorcio_caido = { If = { Flags = { "ConsorcioCaido" } } },
		cosme_recuerda = { If = { Memories = { "CosmeRecuerda" } } },
		aliados_reunidos = { If = { Flags = { "AliadosReunidos" } } },
		aliado_compis = { If = { Flags = { "AliadoCompis" } } },
		guardia_gatuna = { If = { Flags = { "AliadoBigotes" } } },
		abogado_rex = { If = { Flags = { "AliadoRex" } } },
		muela_del_juicio = { If = { Flags = { "AliadoPerez" } } },
		consejo_gnomos = { If = { Flags = { "AliadoGnomos" } } },
		expediente_cronos = { If = { Flags = { "AliadoCronos" } } },
		clases_de_bondad = { If = { Flags = { "AliadoMalvado" } } },
		-- (no existen en el juego: esas frases no salen)
		temporada_final = { Nunca = true },
		coser_el_cielo = { If = { Memories = { "CoserElCielo" } } },
		conoci_cosme = { If = { Completed = { "Loco_N1_Cosme" } } },
	},
	Informe = "La mecánica es la de siempre: el garaje, ir al patio del cole (donde clavaste el primer anclaje), la cinemática Grieta_Final (se cuenta con el guion nuevo) y el final con Cosme. «2003» pasa a «aquella noche»: la Grieta se abrió la noche en que naciste y el año depende de tu partida. Las variantes van con las marcas reales: CosimoPerdonado / CosimoArregla66B (Saga_23), ConsorcioCaido, el recuerdo CosmeRecuerda, AliadosReunidos y los mensajes de cada aliado con su marca Aliado* (Bigotes, Rex, Pérez, gnomos, Cronos, tu yo malvado, los compis); temporada_final (la Capitana Ñoz) no existe como aliado: no sale. Coser la Grieta es la cinemática de siempre (no hay una mecánica de mantener pulsado). La aguja dorada no va al inventario (no hay objeto) y la luz final en el cielo es parte de la escena, sin marcas nuevas.",
}
