-- Mapa del guion reescrito de Loco_N1_Cosme (lo lee scripts/audit/aplicar-reescritura.luau).
-- 7 PASO = 4 pasos del juego (el 2 es el grupo de las tres piezas: 2.1 tornillo, 2.2 bobina, 2.3 chip).
return {
	Prefijo = "Loco_N1",
	-- (el niño de la heladería no está en el reparto: lo cuenta el narrador)
	Hablantes = { ["NIÑO"] = "@Niño", ["NIÑA"] = "@Niña" },
	Variables = {
		-- las marcas que ya guarda el juego
		marca_secreto_cosme = { Flag = "SecretoCosme" },
		secreto_cosme = { Flag = "SecretoCosme" },
		marca_grieta_vista = { Flag = "GrietaVista" },
		bigotes_habla = { Flag = "BigotesHabla" },
		-- (nada las lee: la diferencia ya la dan la relación y el rasgo de cada opción)
		decision_cosme = { If = {} },
		confianza_cosme = { If = {} },
		relacion_cosme_desde_infancia = { If = {} },
		grieta_resonancia_01 = { If = {} },
	},
	Informe = "La mecánica es la de siempre (hablar con Cosme, las tres piezas con su objeto, volver al garaje y la prueba). Las marcas del guion se guardan con las que ya usa la historia: marca_secreto_cosme/secreto_cosme → SecretoCosme, marca_grieta_vista → GrietaVista, bigotes_habla → BigotesHabla (la da la conversación del chip, como antes). decision_cosme, confianza_cosme, relacion_cosme_desde_infancia y grieta_resonancia_01 no las lee ninguna misión: no se crean (la diferencia ya la dan la relación con Cosme y el rasgo de cada opción). Las dos respuestas posibles a «¿Dónde has encontrado eso?» se dicen las dos, una detrás de otra (el guion las da como «OPCIÓN» sin efectos). Los SFX (golpe, zumbido, explosión) y el humo de colores no tienen pista propia: pendiente de sonido/efectos.",
}
