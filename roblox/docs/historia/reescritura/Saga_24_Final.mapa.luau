-- Mapa del guion reescrito de Saga_24_Final (lo lee scripts/audit/aplicar-reescritura.luau).
-- 4 PASO = 4 pasos del juego (el garaje, ir al patio del cole, la cinemática Grieta_Final y el final).
return {
	Prefijo = "Saga_24",
	-- (la cinemática Grieta_Final se queda como está —su cámara, sus variantes por lo que decidiste con
	-- Cósimo, sus 33 s—: ya dice el principio del PASO 3; el cierre —«Ya no eres un Ancla», «Criatura»,
	-- «Estoy orgulloso de ti»— abre la conversación final del paso 4, justo después)
	Pasos = { ["3"] = "4" },
	Lineas = { ["3"] = { { 852, 1002 } } },
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
		guardia_gatuna = { If = { Memories = { "GuardiaGatuna" } } },
		abogado_rex = { If = { Memories = { "AbogadoRex" } } },
		muela_del_juicio = { If = { Memories = { "MuelaDelJuicio" } } },
		consejo_gnomos = { If = { Memories = { "ConsejoGnomos" } } },
		expediente_cronos = { If = { Memories = { "ExpedienteCronos" } } },
		clases_de_bondad = { If = { Memories = { "ClasesDeBondad" } } },
		-- (los recuerdos de cada misión de aliado: Aliado_Bigotes, Aliado_Rex, Aliado_Perez, Aliado_Cronos,
		-- Aliado_Noz, Aliado_Gnomos y Aliado_Malvado)
		temporada_final = { If = { Memories = { "TemporadaFinal" } } },
		coser_el_cielo = { If = { Memories = { "CoserElCielo" } } },
		conoci_cosme = { If = { Memories = { "ConociCosme" } } },
	},
	Informe = "La mecánica es la de siempre: el garaje, ir al patio del cole (donde clavaste el primer anclaje), la cinemática Grieta_Final de siempre (su cámara, sus 33 s y sus variantes por lo que decidiste con Cósimo; ya dice el principio del PASO 3, con «aquella noche» en vez de «2003») y, justo después, el cierre del guion (Cósimo: «Ya no eres un Ancla»; Cosme: «Criatura», «Estoy orgulloso de ti») abre la conversación final y el final con Cosme. «2003» pasa a «aquella noche»: la Grieta se abrió la noche en que naciste y el año depende de tu partida. Las variantes van con las marcas reales: CosimoPerdonado / CosimoArregla66B (Saga_23), ConsorcioCaido, el recuerdo CosmeRecuerda, AliadosReunidos y los mensajes de cada aliado con el recuerdo de su misión (GuardiaGatuna, AbogadoRex, MuelaDelJuicio, ExpedienteCronos, TemporadaFinal de la Capitana Ñoz, ConsejoGnomos, ClasesDeBondad) y AliadoCompis. Coser la Grieta es la cinemática de siempre (no hay una mecánica de mantener pulsado). La aguja dorada no va al inventario (no hay objeto) y la luz final en el cielo es parte de la escena, sin marcas nuevas.",
	-- («después de lo del monte»: solo si viviste la batalla del monte, el recuerdo GranFusion)
	SiTexto = {
		{ "Después de lo del monte", { Memories = { "GranFusion" } } },
	},
	-- (la minuta de Rex, que el guion cuenta con acotaciones: la frase del juego)
	ConservarFrases = {
		{ Conversacion = "Garaje", Marcas = { "AbogadoRex" }, Tras = "Éxito total." },
	},
}
