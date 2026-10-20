-- Mapa del guion reescrito de Saga_22_Ancla (lo lee scripts/audit/aplicar-reescritura.luau).
-- 3 PASO = 3 pasos del juego: Cósimo en tu puerta (de 20:00 a 06:00, el horario de siempre), la decisión
-- Trato (No / Trampa, los valores que lee Saga_23) y la escena de cierre.
return {
	Prefijo = "Saga_22",
	Hablantes = { ["Doctor Cósimo"] = "Cosimo", ["DOCTOR CÓSIMO"] = "Cosimo" },
	Variables = {
		-- (los recuerdos de la quiebra del Consorcio, Saga_21, y de la cinta del archivo, Saga_09)
		caida_consorcio = { If = { Memories = { "CaidaConsorcio" } } },
		consorcio_caido = { If = { Flags = { "ConsorcioCaido" } } },
		eres_el_ancla = { If = { Memories = { "EresElAncla" } } },
		-- (las dos rutas de la decisión Trato del juego: no se renombra nada)
		["ruta rechazo"] = { If = { Choices = { Trato = "No" } } },
		["ruta trampa"] = { If = { Choices = { Trato = "Trampa" } } },
		decision_trato_cosimo = { Choice = "Trato", Valores = { rechazo = "No", Rechazo = "No", no = "No", trampa = "Trampa", Trampa = "Trampa" } },
		trampa_cosimo = { Flag = "TrampaCosimo" },
	},
	Informe = "La mecánica es la de siempre: Cósimo llama a la puerta de tu casa (la que tengas; la escena es en la puerta, con su horario de 20:00 a 06:00), su oferta, la decisión Trato (No / Trampa, los valores que ya lee Saga_23; trampa_cosimo es la marca TrampaCosimo que ya pone el juego) y el cierre. Las variantes van con el recuerdo CaidaConsorcio (Saga_21) y el recuerdo EresElAncla (la cinta del archivo, Saga_09). «Ven solo… o sola» va con su {solo/sola}. Las flores que muerden son un objeto de atrezo sin daño: no hay sistema para guardarlas en casa o en el álbum (pendiente). La llamada a Cosme por el teléfono de siempre queda como frase.",
}
