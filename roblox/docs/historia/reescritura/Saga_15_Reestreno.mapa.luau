-- Mapa del guion reescrito de Saga_15_Reestreno (lo lee scripts/audit/aplicar-reescritura.luau).
-- 3 PASO = 3 pasos del juego (la Capitana Ñoz, el minijuego del reality y la grabación).
return {
	Prefijo = "Saga_15",
	Variables = {
		-- (el minijuego de la grabación: ganar es el resultado del paso 2; cada pulsación no se sabe)
		["el jugador obtiene buen resultado"] = { Gana = "2" },
		["pulsa demasiado pronto"] = { Nunca = true },
		["pulsa demasiado tarde"] = { Nunca = true },
		-- (la primera visita de la nave: la misión loca Loco_U1_Monte)
		["el jugador completo la luz del monte del silencio"] = { If = { Completed = { "Loco_U1_Monte" } } },
		["completo la luz del monte del silencio"] = { If = { Completed = { "Loco_U1_Monte" } } },
	},
	Informe = "La mecánica es la de siempre: la Capitana Ñoz baja de la nave, el minijuego de la grabación (Timing) y la escena final (el pase VIP).",
}
