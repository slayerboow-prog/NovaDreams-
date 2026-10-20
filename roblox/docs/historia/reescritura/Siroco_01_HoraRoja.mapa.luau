-- Mapa del guion de Siroco_01_HoraRoja (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión tiene 6 pasos: 1 la llegada (escena Siroco_Llegada, no se toca), 2 hablar con Rafa en la
-- plataforma, 3 correr al taller, 4 Nina y el agua, 5 beber agua fresca, 6 hablar con Nina.
return {
	Prefijo = "Siroco1",
	Pasos = {
		["1"] = 2, -- Rafa en la plataforma
		["2"] = 4, -- en el taller: la cantimplora y el agua (los objetos los da la frase de siempre)
		["3"] = 6, -- Nina y las deudas de Rafa
	},
	Informe = "Saga 2 · Siroco (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Siroco_Llegada), correr detrás de Rafa al taller, la cantimplora y el agua (efecto de la frase del juego), beber (HazardCountered) y la charla con Nina.",
}
