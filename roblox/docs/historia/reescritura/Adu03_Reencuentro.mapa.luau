-- Mapa del guion reescrito de Adu03_Reencuentro (lo lee scripts/audit/aplicar-reescritura.luau).
-- 21 PASO = 15 pasos del juego con los subpasos de cada amigo (Leire, Hugo y Mateo solo si están en tu
-- vida: el If de cada subpaso). El PASO 15 es el montaje de cambio de etapa (Montaje_Joven_Adulto):
-- diseño fijo comprobado por test-etapas, no se cambia.
return {
	Prefijo = "Adu03",
	-- (la foto de siempre —la cinemática Adu03_Foto, «Todos otra vez»— se queda; las frases del PASO 10
	-- salen justo después)
	Despues = { "10" },
	Pasos = { ["15"] = false },
	-- (en el banco: Leire y Mateo solo si están en tu vida)
	CondicionHablante = { Leire = { Flags = { "ConocesALeire" } }, Mateo = { Flags = { "AyudasteAMateo" } } },
	-- (Lucía y tu sueño de niño: cada «Ejemplo» solo si tu sueño y tu carrera coinciden; «lo has cumplido»
	-- no se puede decir sin saber cuál, así que no sale)
	SiTexto = {
		-- (opciones de la elección y notas que se colaban como frases del jugador: no salen)
		{ "Omar abre la cafetería.", { Nunca = true } },
		-- (notas de diseño del guion que no son frases de nadie: no salen)
		{ "No está trabajando.", { Nunca = true } },
		{ "Está guardando objetos personales en una caja.", { Nunca = true } },
		{ "Esto comunica inmediatamente que algo está cambiando.", { Nunca = true } },
		{ "Querías salvar vidas.", { Choices = { SuenoInfancia = "Medicina", Estudios = "Medicina" } } },
		{ "Y ahora trabajas en un hospital.", { Choices = { SuenoInfancia = "Medicina", Estudios = "Medicina" } } },
		{ "Querías inventar cosas que no existían.", { Choices = { SuenoInfancia = "Ingenieria", Estudios = "Ingenieria" } } },
		{ "Y ahora las diseñas.", { Choices = { SuenoInfancia = "Ingenieria", Estudios = "Ingenieria" } } },
		{ "Querías defender a quien no podía hacerlo.", { Choices = { SuenoInfancia = "Derecho", Estudios = "Derecho" } } },
		{ "Querías tener tu propio negocio.", { Choices = { SuenoInfancia = "Economia", Estudios = "Economia" } } },
		{ "Lo dijiste con diez años.", { Nunca = true } },
		{ "Y lo has cumplido.", { Nunca = true } },
	},
	Variables = {
		["esta"] = { If = {} },
		["existe"] = { If = {} },
		["el jugador tarda"] = { Nunca = true },
		["el jugador fue barista"] = { If = { Choices = { Empleo = "Barista" } } },
		["el recuerdo del primer dia"] = { If = { Memories = { "PrimerDiaCole" } } },
		["estudio ingenieria"] = { If = { Choices = { Estudios = "Ingenieria" } } },
		["no estudio ingenieria"] = { If = { NotChoices = { Estudios = "Ingenieria" } } },
		["el jugador fue despedido"] = { If = { Flags = { "Despedido" } } },
		["fue ascendido"] = { If = { Flags = { "Ascendido" } } },
		atardecer_con_abu = { If = { Memories = { "AtardecerConAbu" } } },
		["atardecer_con_abu == true"] = { If = { Memories = { "AtardecerConAbu" } } },
		["atardecer con abu true"] = { If = { Memories = { "AtardecerConAbu" } } },
		["coinciden sueno"] = { If = {} },
		["profesion"] = { If = {} },
		primer_grupo = { If = { Memories = { "PrimerGrupo" } } },
	},
	Informe = "La mecánica es la de siempre: el notición de Omar en la cafetería, invitar al grupo (al menos tres; Leire, Hugo y Mateo solo si están en tu vida), Lucía (directora del colegio, como ya era en el juego), ayudar en la cocina (el minijuego de siempre: fallar no bloquea), la inauguración, la foto (Adu03_Foto), el banco del parque (Adu03_Banco) y el montaje de cambio de etapa, que no se cambia.",
}
