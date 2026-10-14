-- Mapa del guion reescrito de Pan1_MalasCompanias (lo lee scripts/audit/aplicar-reescritura.luau).
-- 15 PASO = 15 pasos del juego (las tres ramas de Pellas: recreativos y muro, clase, o Nerea y sus cómics).
return {
	Prefijo = "Pan1",
	Variables = {
		rechazaste_pandilla = { Flag = "RechazasteLaPandilla" },
		-- (la partida de los recreativos es un evento del juego: no guarda si ganas o pierdes)
		["el jugador gana"] = { Nunca = true },
		pierde = { Nunca = true },
		-- (las ramas de la conversación en casa: lo que elegiste en Pellas)
		["ruta hizo pellas"] = { If = { Choices = { Pellas = "Ir" } } },
		["ruta volvio a clase"] = { If = { Choices = { Pellas = "Clase" } } },
		["ruta ayudo a nerea"] = { If = { Choices = { Pellas = "Nerea" } } },
		["ruta a"] = { If = {} },
		["ruta b"] = { If = {} },
		["ruta c"] = { If = {} },
	},
	Informe = "La mecánica es la de siempre: el recreo con Rayo y Nerea, la decisión Pellas (irte con ellos, volver a clase o convencer a Nerea) y su rama (recreativos y el muro con el espray, la clase de Historia, los cómics de Nerea), la noche en casa y Bruno en la puerta. La partida de los recreativos no guarda si ganas o pierdes: esas frases no salen. «rechazaste_pandilla» es la marca RechazasteLaPandilla que ya pone el juego.",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		{ "Puede invitarle posteriormente a planes de mayor riesgo.", { Nunca = true } },
	},
}
