-- Mapa del guion de Nivalis_01_Oscuras (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión tiene 6 pasos: 1 la llegada (escena Nivalis_Llegada, no se toca), 2 ir al Mirador, 3 el frío
-- llega a aviso, 4 Tila en la hoguera (el abrigo y la sopa), 5 tomarse la sopa, 6 Tila y la hora del silencio.
return {
	Prefijo = "Nivalis1",
	Pasos = {
		["1"] = 4, -- Tila en la hoguera: el abrigo y la sopa (los objetos los da la frase de siempre)
		["2"] = 6, -- Tila, la aurora robada y la hora del silencio
	},
	Informe = "Saga 2 · Nivalis (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Nivalis_Llegada), salir al Mirador, el frío en aviso (HazardChanged), el abrigo y la sopa (efecto de la frase del juego), tomarse la sopa (HazardCountered) y la charla con Tila.",
}
