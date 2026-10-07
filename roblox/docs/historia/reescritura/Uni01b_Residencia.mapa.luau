-- Mapa del guion reescrito de Uni01b_Residencia (lo lee scripts/audit/aplicar-reescritura.luau).
-- El juego tiene 9 pasos: las llaves con Doña Pilar, los compis, deshacer la maleta, las normas de la
-- nevera, la compra, guardarla, la primera cena, la conversación de la cena y dormir.
-- Los PASO 1-4 del guion (llegar, subir, la puerta, personalizar) son diseño sin frases: no cambian nada.
return {
	Prefijo = "Uni01b",
	Pasos = {
		["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false,
		["5"] = "2", -- conoces a Iván (la escena de los compis)
		["6"] = "8", -- la primera cena
		["7"] = "8", -- la primera noche
		["8"] = "8", -- la llamada de Pip
	},
	Hablantes = { ["Iván"] = "Ivan" },
	Informe = "La mecánica es la de siempre (las llaves, los compis, la maleta, las normas de la nevera, la compra, la cena y dormir). Personalizar la habitación (PASO 4) sería un sistema de decoración nuevo: no se hace (pendiente). Conocer a Iván va en la escena de los compis; la cena, la primera noche y la llamada de Pip van en la conversación de la cena (no hay una llamada de teléfono jugable en este paso).",
}
