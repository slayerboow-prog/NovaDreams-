-- Mapa del guion reescrito de Adulto_MirarAtras (lo lee scripts/audit/aplicar-reescritura.luau).
-- El epílogo de la vida: 1 vuelve a la casa donde creciste, 2 la cinemática Vida_MirarAtras, 3 el momento.
-- REGLA: nunca se enseña un recuerdo que el jugador no vivió. La cinemática de siempre ya elige cada
-- recuerdo por sus marcas reales; el guion nuevo es un documento de dirección (álbum, fotos por etapa,
-- microflashbacks, «si existe…») que el importador no puede convertir sin riesgo de enseñar recuerdos no
-- vividos, así que la cinemática no se cambia y el guion queda en el informe para montarla a mano.
return {
	Prefijo = "Vida",
	Pasos = { ["1"] = false, ["2"] = false },
	Variables = {
		saga_grieta_completada = { If = { Flags = { "SagaCompleta" } } },
	},
	Informe = "La mecánica es la de siempre: volver a la casa familiar, la cinemática Vida_MirarAtras y el momento final. La cinemática NO se cambia: la de siempre ya enseña cada recuerdo solo si lo viviste (sus marcas reales), y el guion nuevo es un documento de dirección (el álbum con una foto por etapa, microflashbacks de 1-3 s, «si existe…», Pip y la Grieta solo con SagaCompleta) que hay que montar a mano para no enseñar nunca un recuerdo no vivido. La línea de tiempo «MI VIDA» y el álbum persistente son un sistema nuevo (pendiente).",
}
