-- Mapa del guion de Vertice_05_Luz (lo lee scripts/audit/aplicar-reescritura.luau).
-- 4 pasos: 1 Abril en el andén, 2 la etiqueta (Use: su conversación es «Caja»), 3 la decisión, 4 el cierre
-- (escena Vertice_Cierre, no se toca: Ofelia anuncia la Liquidación Total).
return {
	Prefijo = "Vertice5",
	Pasos = {
		["1"] = 1,
		["2"] = 2,
	},
	Dialogos = { ["2"] = "Caja" },
	Informe = "Saga 2 · Vértice. La mecánica es la de siempre: Abril, leer la etiqueta de la caja (da la etiqueta), la decisión (VerticeVerdad) y la escena del cierre con el holograma de Ofelia Brum (canon: se queda en Vértice; «V.» es solo un guiño a Varkun).",
}
