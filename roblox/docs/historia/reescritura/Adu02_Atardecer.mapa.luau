-- Mapa del guion reescrito de Adu02_Atardecer (lo lee scripts/audit/aplicar-reescritura.luau).
-- 17 PASO = 17 pasos del juego (la llamada, el hospital, la decisión ViajeAbu —coche con carnet de la
-- autoescuela o autobús—, la playa, la concha, la promesa y el atardecer).
return {
	Prefijo = "Adu02",
	Variables = {
		["el jugador estudio medicina"] = { If = { Choices = { Estudios = "Medicina" } } },
		["estudio otra profesion"] = { If = { NotChoices = { Estudios = "Medicina" } } },
		["memoria de universidad"] = { If = { Memories = { "PrimerDiaUni" } } },
		["la memoria correspondiente"] = { If = {} },
		-- (no hay tiempo ni recorrido que el juego sepa en ese momento: esas frases no salen)
		["el sistema meteorologico indica lluvia"] = { Nunca = true },
		["hace frio"] = { Nunca = true },
		["pasan por una calle antigua"] = { Nunca = true },
		["pasan por una panaderia"] = { Nunca = true },
		["pasan por una plaza"] = { Nunca = true },
	},
	-- (lo dice el jugador a Abu, que puede ser abuela o abuelo: sin barra)
	Reemplazos = { ["¿Estás despierto/a?"] = "¿No duermes?", ["Ya no eres un niño."] = "Ya no eres {un niño/una niña}." },
	Informe = "La mecánica es la de siempre: la llamada, el hospital (Adu02_Hospital), sentarte con Abu, la decisión ViajeAbu (el carnet en la autoescuela, que ya existe, o el autobús), recoger a Abu, la playa (Adu02_Orilla), la concha (el objeto de siempre), la promesa (PromesaAbu) y el atardecer. Abu camina despacio con la mecánica de acompañar de siempre.",
}
