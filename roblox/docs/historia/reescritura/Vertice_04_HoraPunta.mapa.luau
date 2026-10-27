-- Mapa del guion de Vertice_04_HoraPunta (lo lee scripts/audit/aplicar-reescritura.luau).
-- 5 pasos: 1 Gil avisa, 2 los drones de cobro (Fight), 3 el dron de la Contable (solo si te quedaste el
-- dinero), 4 la hora punta (Escape), 5 Abril en el ascensor.
return {
	Prefijo = "Vertice4",
	Pasos = {
		["1"] = 1,
		["2"] = 5,
	},
	Variables = {
		dinero_cuenta = { Flag = "VerticeDineroCuenta" },
	},
	Informe = "Saga 2 · Vértice. La mecánica es la de siempre: Gil (con una frase más si te quedaste el dinero), apagar a los drones de cobro (y al dron dorado de la Contable si te quedaste el dinero), la carrera de la hora punta y Abril en el ascensor.",
}
