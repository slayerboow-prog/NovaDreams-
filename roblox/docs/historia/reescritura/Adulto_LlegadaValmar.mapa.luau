-- Mapa del guion reescrito de Adulto_LlegadaValmar (lo lee scripts/audit/aplicar-reescritura.luau).
-- Primera misión del capítulo «Una nueva vida en Valmar» (empiezas de adulto). 4 PASO = 4 pasos del
-- juego: la plaza, la cinemática Adulto_Bienvenida, quedarte una casa (con su condición TieneHogar de
-- siempre) y comer algo (en la cafetería de Lola: el menú de siempre). Al terminar se desbloquea
-- Adulto_PrimerSueldo como hasta ahora. RUTA SIN INFANCIA: nada de recuerdos de la niñez.
return {
	Prefijo = "Adulto_Llegada",
	Variables = {
		-- (el juego no guarda cuánto tardas ni una elección «C» aquí: esas frases no salen)
		["tardo mucho"] = { Nunca = true },
		["elige c"] = { Nunca = true },
	},
	-- (a «¿Vienes de lejos?» el guion propone tres respuestas; en un paso de comer no hay elección: se
	-- queda la primera)
	SiTexto = {
		{ "De bastante lejos.", { Nunca = true } },
		{ "Prefiero no hablar de ello.", { Nunca = true } },
		{ "Cuando habla, continúa realizando tareas.", { Nunca = true } },
		{ "Es Ernesto.", { Nunca = true } },
	},
	Informe = "La mecánica es la de siempre: llegar a la plaza, la cinemática Adulto_Bienvenida, quedarte una casa (el sistema de casas de siempre; el paso sigue con su condición TieneHogar) y comer algo (el menú de la cafetería de siempre). Las cinemáticas «antes del paso 1» y de cierre del guion van dentro de los pasos que ya existen (no se añaden pasos). Elegir entre tres casas filtradas sería un sistema nuevo: se queda la versión del juego (pendiente). actitud_llegada, tipo_hogar_inicial y primera_comida_valmar no se crean (nada las lee). A «¿Vienes de lejos?» solo sale la primera respuesta (en un paso de comer no hay elección). La ruta no menciona la infancia. Los recordatorios de Lola y Ernesto son las frases de este paso: salen una vez, no se repiten.",
}
