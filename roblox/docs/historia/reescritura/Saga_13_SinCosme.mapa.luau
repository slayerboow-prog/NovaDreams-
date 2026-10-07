-- Mapa del guion reescrito de Saga_13_SinCosme (lo lee scripts/audit/aplicar-reescritura.luau).
-- El juego: 1 Pip en el garaje, 2 lo que dejó Cosme (2.1 el cuaderno, 2.2 el mando), 3 Candela y el
-- equipo en la residencia, 4 el plan. El guion (5 PASO): volver al garaje, la caja, su contenido, la
-- primera casa (la primera costura) y la costura.
return {
	Prefijo = "Saga_13",
	Pasos = {
		["1"] = "1", -- volver al garaje: Pip
		["2"] = "2.1", -- la caja de Cosme: el cuaderno
		["3"] = "2.2", -- el contenido: el mando
		["4"] = "4", -- la primera costura: el plan
		["5"] = "4",
	},
	Informe = "La mecánica es la de siempre: Pip en el garaje, el cuaderno y el mando que dejó Cosme, el equipo de rescate con Candela en la residencia (CompisSabenGrieta, CuadernoCosme) y el plan. La caja de Cosme es el cuaderno (un objeto que ya existe) y su contenido sale al coger el mando; la primera costura y la costura van en la escena del plan. La conversación con Candela y el equipo (paso 3) no está en el guion y se queda como estaba.",
}
