-- Mapa del guion reescrito de Ins04_PrimerEmpleo (lo lee scripts/audit/aplicar-reescritura.luau).
-- El juego tiene 21 pasos y TRES trabajos (Empleo = Barista con Lola, Reponedor con Paco, Repartidor con
-- Ernesto), cada uno con su entrevista, su llegada, sus tareas en el tablón de trabajo y su sueldo.
-- El guion propone ocho rutas (taller, cocina, audiovisual, deporte, empresa, comunidad, laboratorio,
-- jurídico): solo la cocina es un trabajo del juego (la cafetería de Lola). Las demás no existen aquí:
-- sus frases no salen, y las conversaciones de cada trabajo conservan delante sus frases propias.
return {
	Prefijo = "Ins04",
	Pasos = {
		["1"] = "1", -- transición
		["2"] = "2", -- el mensaje / el deseo del verano
		["3"] = "4", -- el taller de Carmen (perfil)
		["4"] = false, -- dónde trabajar: la decisión del juego (habla con quien contrata) no cambia
		["5"] = "7", -- el primer día (transición)
		["6"] = "11", -- el primer día en el trabajo
		["7"] = "15", -- el error / el imprevisto
		["8"] = "15",
		["9"] = "15",
		["10"] = "19", -- fin de turno y sueldo
		["11"] = "19",
		["12"] = "20", -- vuelta a casa (transición)
		["13"] = "21", -- la cena
		["14"] = "21",
		["15"] = "21",
		["16"] = "21",
	},
	Hablantes = {
		["Tobías"] = "Tomas",
		["Mensaje de Carmen"] = "Carmen",
		["Mensaje de Nerea"] = "Nerea",
		["Mensaje de Rayo"] = "Rayo",
		["Mensaje de Leire"] = "Leire",
		["Compañero"] = "@Compañero",
		["Compañera"] = "@Compañera",
	},
	-- (Rayo y Nerea solo escriben si los conociste)
	CondicionHablante = {
		Nerea = { Completed = { "Pan1_MalasCompanias" } },
		Rayo = { Completed = { "Pan1_MalasCompanias" } },
		Leire = { Flags = { "ConocesALeire" } },
	},
	ConservarFrases = { "PrimerDia", "Imprevisto", "Sueldo", "Cena" },
	Variables = {
		["ruta cocina"] = { If = { Choices = { Empleo = "Barista" } } },
		["ruta taller"] = { Nunca = true },
		["ruta audiovisual"] = { Nunca = true },
		["ruta deporte"] = { Nunca = true },
		["ruta empresa"] = { Nunca = true },
		["ruta comunidad"] = { Nunca = true },
		["ruta laboratorio"] = { Nunca = true },
		["ruta proyecto jurídico / comunitario"] = { Nunca = true },
		["ruta proyecto juridico / comunitario"] = { Nunca = true },
		["ruta proyecto juridico comunitario"] = { Nunca = true },
		["el jugador trabajo con lola"] = { If = { Choices = { Empleo = "Barista" } } },
		["trabajo con lola"] = { If = { Choices = { Empleo = "Barista" } } },
		["el jugador trabajo con toni"] = { Nunca = true },
		["trabajo con tobias"] = { Nunca = true },
		["conoces a leire"] = { If = { Flags = { "ConocesALeire" } } },
		-- (el error del primer día no es una mecánica: sus frases salen en el imprevisto, sin condición)
		["el jugador se equivoca"] = { If = {} },
	},
	Informe = "La mecánica es la de siempre: el deseo del verano, el taller de Carmen, buscar ofertas, elegir trabajo (cafetería, súper o Correos) y su entrevista, llegar puntual, las tareas del tablón de trabajo, el imprevisto, el sueldo (por la economía de siempre) y la cena. El guion propone ocho rutas de primer trabajo; el juego tiene tres trabajos y solo la cocina coincide (la cafetería de Lola): esa ruta sale con Empleo = Barista y las demás (taller, audiovisual, deporte, empresa, comunidad, laboratorio, jurídico) no salen (pendiente: más trabajos de verano). Las conversaciones de cada trabajo (primer día, imprevisto, sueldo y cena) conservan delante sus frases propias de Paco y Ernesto. Los mensajes de Rayo y Nerea solo llegan si hiciste Pan1 (los conociste); el de Leire, con ConocesALeire.",
	-- (opciones de la elección y notas que se colaban como frases del jugador: no salen)
	SiTexto = {
		{ "Guardar el dinero. Comprar algo", { Nunca = true } },
		{ "Invitar a la familia a algo.", { Nunca = true } },
		{ "Ayudar con un gasto de casa.", { Nunca = true } },
	},
}
