-- Mapa del guion reescrito de Pan2_LaNoche (lo lee scripts/audit/aplicar-reescritura.luau).
-- 16 PASO = 15 pasos del juego (el guion tiene dos «PASO 3»: el plan de Rayo y la decisión van juntos).
return {
	Prefijo = "Pan2",
	Informe = "La mecánica es la de siempre: el plan de Rayo en el parque y la decisión Plan (ir, frenarle o no ir), la noche del súper de Paco con la alarma (Pan2_Alarma), la huida al parque o la comisaría, el servicio a la comunidad en el Punto Limpio, los mensajes y el lunes. Lo que depende de tu relación con Rayo («Rayo >= 5») va con la relación de verdad (Conditions: Rel).",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		-- (notas de diseño del guion que no son frases de nadie: no salen)
		{ "No dices nada. Miras al suelo.", { Nunca = true } },
		{ "Al menos tuviste el valor de mirarme a los ojos.", { Nunca = true } },
	},
}
