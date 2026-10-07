-- Mapa del guion reescrito de Saga_14_Bigotes (lo lee scripts/audit/aplicar-reescritura.luau).
-- 4 PASO = 3 pasos del juego (la transición a Gatonia, la huida de la policía gatuna y el presidente
-- Bigotes XVII); el «nuevo cierre cinemático» (PASO 4) va al final de la conversación con Bigotes.
return {
	Prefijo = "Saga_14",
	Pasos = { ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "3" },
	Variables = {
		corresponde = { If = {} },
		-- (le salvaste de las cucarachas de pequeño: la misión loca Loco_N2_Bigotes)
		["bigotes emperador esta completado"] = { If = { Completed = { "Loco_N2_Bigotes" } } },
		["bigotes emperador no esta completado"] = { If = { NotCompleted = { "Loco_N2_Bigotes" } } },
	},
	Informe = "La mecánica es la de siempre: cruzar el portal a Gatonia, huir de la policía gatuna hasta el palacio (Escape) y hablar con el presidente Bigotes XVII (el collar diplomático y las coordenadas de Cósimo, que leen las misiones siguientes). El cierre del guion va al final de esa conversación (no se añade un paso).",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		{ "Esto es absurdo… pero este mundo tiene reglas.", { Nunca = true } },
	},
}
