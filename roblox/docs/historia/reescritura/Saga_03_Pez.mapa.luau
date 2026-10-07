-- Mapa del guion reescrito de Saga_03_Pez (lo lee scripts/audit/aplicar-reescritura.luau).
-- 6 PASO = 4 pasos del juego (el 2 es el grupo de la huida: 2.1 el cubo, 2.2 la tarjeta).
return {
	Prefijo = "Saga_03",
	Hablantes = {
		["Don Escamas susurra"] = "DonEscamas",
		-- (los agentes grises del reparto: el que habla es el primero)
		AGENTE = "AgenteGris1",
		Agente = "AgenteGris1",
	},
	Variables = {
		-- La huida (Escape) no sabe si te escondes ni a qué distancia pasan los agentes: esas frases no salen.
		-- Si te pillan, el paso ya te devuelve al principio de la huida (como hasta ahora).
		["el jugador se esconde"] = { Nunca = true },
		["los agentes pasan cerca"] = { Nunca = true },
		["los agentes alcanzan al jugador"] = { Nunca = true },
		-- (ya has oído el nombre de Cósimo: la moneda de Saga_02)
		cosimo_introducido = { If = { Flags = { "SabeDeCosimo" } } },
		["cosimo_introducido = true"] = { If = { Flags = { "SabeDeCosimo" } } },
	},
	Informe = "La mecánica es la de siempre: hablar con Don Escamas en el estanque, el cubo y la tarjeta que se les cae a los agentes, la huida al garaje (Escape) y la escena de la pecera. La huida no sabe si te escondes, si los agentes pasan cerca o si te alcanzan (si te pillan, el paso te devuelve al principio, como antes): esas frases del guion no salen (pendiente: frases según la distancia a los agentes en EscapeService). Los agentes que hablan son los agentes grises del reparto (AgenteGris1).",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		{ "Hay un pez que habla.", { Nunca = true } },
	},
}
