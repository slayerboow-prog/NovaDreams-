-- Mapa del guion reescrito de Saga_17_Rescate (lo lee scripts/audit/aplicar-reescritura.luau).
-- El juego: 1 el pasillo del laboratorio (Fight), 2 la cápsula de Cosme, 3 la huida al portal (Escape) y
-- 4 en casa (Cosme no sabe quién eres). El guion (5 PASO): preparación e infiltración (antes y durante
-- el pasillo), el laboratorio (la cápsula), la trampa y el escape (la huida).
-- MEMORIA DE COSME: en Saga_18 Cosme no recuerda nada («Cosme recordó tu nombre» es su final). Para que
-- encaje, Cosme está lúcido un momento en el laboratorio y durante la huida, y al cruzar la Grieta lo
-- pierde: la vuelta al garaje es la escena de siempre (no reconoce a Pip; solo murmura «…Criatura»). Las
-- frases del guion en el garaje, en las que Cosme lo recuerda todo, no salen.
return {
	Prefijo = "Saga_17",
	Pasos = { ["1"] = "1", ["2"] = "1", ["3"] = "2", ["4"] = "3", ["5"] = "3" },
	SiTexto = {
		{ "Has mantenido todo igual.", { Nunca = true } },
		{ "Definitivamente no todo.", { Nunca = true } },
		{ "Por venir a buscarme.", { Nunca = true } },
		{ "Tarde: habla con Pip.", { Nunca = true } },
	},
	Informe = "La mecánica es la de siempre: el pasillo del laboratorio (desconectar a los guardias), abrir la cápsula, la huida al portal del garaje con Cosme y la escena en casa. Para que encaje con Saga_18 (Cosme ha perdido la memoria), Cosme está lúcido un momento en el laboratorio y en la huida («Criatura…», «Has crecido», «¿Has cuidado de la criatura?») y al cruzar la Grieta la pierde: la vuelta al garaje es la escena de siempre (no reconoce a Pip; antes de dormirse murmura «…Criatura»). Las frases del guion en el garaje en las que lo recuerda todo («Has mantenido todo igual», «Gracias por venir a buscarme») no salen. La pantalla final (FUSIÓN 87 %, ANCLA LOCALIZADA, CÓSIMO ACTIVO) queda como nota: sería un plano nuevo en la escena de casa (pendiente).",
}
