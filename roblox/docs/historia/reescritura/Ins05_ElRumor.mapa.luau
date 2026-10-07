-- Mapa del guion reescrito de Ins05_ElRumor (lo lee scripts/audit/aplicar-reescritura.luau).
-- 17 PASO = 13 pasos del juego (el 4 es el grupo de las pistas: la captura, Leire, Bruno y la grada).
return {
	Prefijo = "Ins05",
	-- (la cinemática Ins05_DiaDespues se queda como está: lee lo que hiciste antes —cómo hablaste con Nico, Darío, las pulseras con el nombre del grupo, la guerra de montajes— con sus variantes; el PASO 13 del guion queda para fundirlo a mano con ella)
	Pasos = { ["13"] = false },
	Informe = "La mecánica es la de siempre: la foto que circula, las cuatro pistas del recreo, la deducción, Nico y Darío en la pista, Omar en el banco del parque y la cinemática del día después (Ins05_DiaDespues, la de siempre: lee cómo hablaste con Nico, lo de Darío y el nombre del grupo; se puede saltar).",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		{ "Es el personaje emocionalmente más importante.", { Nunca = true } },
		{ "El antiguo chico que podía iniciar un conflicto ahora es uno de los primeros en recibir a Omar.", { Nunca = true } },
		{ "Es una consecuencia directa de su desarrollo.", { Nunca = true } },
	},
}
