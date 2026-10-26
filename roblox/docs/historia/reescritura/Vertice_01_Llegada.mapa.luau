-- Mapa del guion de Vertice_01_Llegada (lo lee scripts/audit/aplicar-reescritura.luau).
-- 6 pasos: 1 la llegada (escena Vertice_Llegada, no se toca), 2 Cosme, 3 la plaza, 4 Gil en la estatua,
-- 5 la vigilancia en aviso (HazardChanged), 6 que vuelva a la normalidad (inhibidor o el Arcade).
return {
	Prefijo = "Vertice1",
	Pasos = {
		["1"] = 2,
		["2"] = 4,
	},
	Informe = "Saga 2 · Vértice (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Vertice_Llegada), Cosme, la plaza, Gil (la gorra y los inhibidores son la recompensa) y el medidor de vigilancia en aviso y de vuelta a la normalidad.",
}
