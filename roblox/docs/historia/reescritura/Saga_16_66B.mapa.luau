-- Mapa del guion reescrito de Saga_16_66B (lo lee scripts/audit/aplicar-reescritura.luau).
-- 5 PASO = 5 pasos del juego (la llegada a la 66-B, mirar la plaza, tu yo malvado, la huida y la rejilla).
return {
	Prefijo = "Saga_16",
	Variables = {
		-- (las coordenadas que te dio Bigotes en Gatonia, Saga_14)
		coordenadas_66b_obtenidas = { If = { Flags = { "CoordenadasCosimo" } } },
		["coordenadas 66b obtenidas"] = { If = { Flags = { "CoordenadasCosimo" } } },
	},
	Informe = "La mecánica es la de siempre: cruzar a la Valmar 66-B, mirar la plaza, hablar con tu yo malvado (el mapa y ConoceTuMalvado), huir de los drones hasta la universidad malvada (Escape) y la entrada al laboratorio subterráneo. Lo que dice Pip de las coordenadas sale con CoordenadasCosimo (Saga_14) y lo de la grabación con GrabacionLaboratorio (Saga_15).",
}
