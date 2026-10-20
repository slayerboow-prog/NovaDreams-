-- Mapa del guion de Umbria_01_Caida (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión tiene 7 pasos: 1 la llegada (escena Umbria_Llegada, no se toca), 2 Garza en el claro, 3 bajar
-- al Suelo Hondo, 4 las esporas en aviso, 5 la mascarilla y el ungüento, 6 untarse el ungüento, 7 la plaza.
return {
	Prefijo = "Umbria1",
	Pasos = {
		["1"] = 2, -- Garza en el Claro del Ascensor
		["2"] = 5, -- la mascarilla, el ungüento y el farolillo (los objetos los da la frase de siempre)
		["3"] = 7, -- de vuelta en la plaza
	},
	Informe = "Saga 2 · Umbría (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Umbria_Llegada), bajar con Garza al Suelo Hondo, las esporas en aviso (HazardChanged), la mascarilla y el ungüento (efecto de la frase del juego), untarse (HazardCountered) y la charla en la plaza.",
}
