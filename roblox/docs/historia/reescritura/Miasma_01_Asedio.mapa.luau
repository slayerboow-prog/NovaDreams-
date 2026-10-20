-- Mapa del guion de Miasma_01_Asedio (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión tiene 7 pasos: 1 la llegada (escena Miasma_Llegada, no se toca), 2 hablar con Mara en la
-- plataforma, 3 ir al borde de Lastre, 4 la máscara y las cápsulas, 5 usar una cápsula, 6 entrar en la
-- cantina, 7 la conversación de la cantina.
return {
	Prefijo = "Miasma1",
	Pasos = {
		["1"] = 2, -- Mara en la plataforma
		["2"] = 4, -- el borde de Lastre: máscara y cápsulas (los objetos los da la frase de siempre)
		["3"] = 7, -- la cantina El Lastre
	},
	Informe = "Saga 2 · Miasma (marco común de los planetas). La mecánica es la de siempre: la llegada (escena Miasma_Llegada), seguir a Mara, el regalo de la máscara y las cápsulas (efecto de la frase del juego), usar una cápsula (HazardCountered) y la cantina.",
}
