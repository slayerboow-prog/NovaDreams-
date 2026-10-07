-- Mapa del guion reescrito de Saga_02_Grieta (lo lee scripts/audit/aplicar-reescritura.luau).
-- 9 PASO = 6 pasos del juego (el 3 es el grupo de los tres cráteres: 3.1 parque, 3.2 cole, 3.3 camino).
-- La estructura, la migración (por fecha) y las marcas de la misión no cambian: solo los textos.
return {
	Prefijo = "Saga_02",
	Hablantes = { ["BIGOTES XVII"] = "Bigotes" },
	Variables = {
		["el jugador no guardo el secreto"] = { If = { NotFlags = { "SecretoCosme" } } },
		["el jugador guardo el secreto"] = { If = { Flags = { "SecretoCosme" } } },
		["el jugador tiene bigotes_habla"] = { If = { Flags = { "BigotesHabla" } } },
		["el jugador tiene bigotes habla"] = { If = { Flags = { "BigotesHabla" } } },
		-- («Si no:» detrás de «Si el jugador tiene bigotes_habla:»)
		no = { If = { NotFlags = { "BigotesHabla" } } },
		-- la reacción «¡Cúbrete!» de la cinemática (la espera Cubrirse de Grieta_Caen)
		["el jugador lo hace"] = { If = { Input = "Cubrirse" } },
		["lo hace"] = { If = { Input = "Cubrirse" } },
		-- (en un paso Reach no hay forma de saber si te paras o preguntas: esas frases no salen)
		["el jugador se detiene"] = { If = { Flags = { "Saga02_NoExiste" } } },
		["el jugador pregunta"] = { If = { Flags = { "Saga02_NoExiste" } } },
		-- (nada las lee: no se crean)
		bigotes_grieta_advertencia = { If = {} },
		voz_desconocida = { If = {} },
		grieta_acto1_02_completada = { If = {} },
		grieta_creciendo = { If = {} },
		cosimo_introducido = { If = {} },
		cosimo_referencia_01 = { If = {} },
		moneda_66b_obtenida = { If = {} },
		bigotes_advirtio = { If = {} },
		pip_confia_jugador = { If = {} },
	},
	Informe = "La mecánica es la de siempre: el medidor de Cosme, la cinemática Grieta_Caen (se queda su cámara, los meteoritos, los cráteres que se encienden y la espera «¡Cúbrete!»: las frases de Pip según te cubras o no van con esa espera), los tres cráteres con su objeto (calcetín, paraguas, moneda 66-B, que ya se guardan como hasta ahora), Bigotes, el garaje y la escena de la perilla. La migración por fecha de esta misión no se toca. Las marcas nuevas del guion (grieta_creciendo, cosimo_introducido, voz_desconocida, moneda_66b_obtenida, bigotes_advirtio…) no las lee ninguna misión: no se crean. Lo que Pip dice si te paras o le preguntas en el camino al garaje no tiene mecánica (un paso Reach no sabe si te paras): esas frases no salen (pendiente: una charla opcional con Pip).",
}
