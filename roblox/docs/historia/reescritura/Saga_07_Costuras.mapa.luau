-- Mapa del guion reescrito de Saga_07_Costuras (lo lee scripts/audit/aplicar-reescritura.luau).
-- 7 PASO = 4 pasos del juego (el 2 es el grupo de los tres puntos que pitan: parque, plaza e instituto).
return {
	Prefijo = "Saga_07",
	-- (el recuerdo del anclaje solo si viviste «Coser el cielo»: nunca recuerdos no vividos)
	SiTexto = {
		-- (lo del ojo abierto, solo si Cósimo te habló por la costura)
		{ "Duermo con un ojo abierto.", { Flags = { "CosimoTeHaVisto" } } },
		{ "El otro también.", { Flags = { "CosimoTeHaVisto" } } },
		{ "Lo clavaste tú.", { Memories = { "CoserElCielo" } } },
		{ "Todavía tienes el barro de aquella noche en la memoria.", { Memories = { "CoserElCielo" } } },
	},
	Informe = "La mecánica es la de siempre: la credencial de ayudante con Cosme, la patrulla con el medidor (parque, plaza del centro y patio del instituto), las hilachas sueltas del parque (Fight) y el informe final. La marca AyudanteOficial la sigue poniendo el juego.",
}
