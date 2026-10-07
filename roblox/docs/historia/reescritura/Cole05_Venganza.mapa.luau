-- Mapa del guion reescrito de Cole05_Venganza (lo lee scripts/audit/aplicar-reescritura.luau).
-- En el juego son 10 pasos: 1-8 coinciden con los PASO 1-8 del guion; la confesión (paso 9) recoge
-- los PASO 9-20 (la confesión, el concurso y lo que pasa con Iker) y el final (paso 10), los 21-24.
return {
	Prefijo = "Cole05",
	Pasos = {
		["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["4.1"] = "4.1", ["4.2"] = "4.2", ["4.3"] = "4.3",
		["5"] = 5, ["5.1"] = "5.1", ["5.2"] = "5.2", ["5.3"] = "5.3", ["5.4"] = "5.4",
		["6"] = 6, ["7"] = 7, ["8"] = 8,
		["9"] = 9, ["10"] = 9, ["11"] = 9, ["12"] = 9, ["13"] = 9, ["14"] = 9, ["15"] = 9, ["16"] = 9,
		["17"] = 9, ["18"] = 9, ["19"] = 9, ["20"] = 9,
		["21"] = 10, ["22"] = 10, ["23"] = 10, ["24"] = 10,
	},
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben" },
	Variables = {
		culpable = { Choice = "Culpable" },
		malotes = { Choice = "Malotes" },
		nombre_grupo = { Choice = "NombreGrupo" },
		ayudaste_a_mateo = { Flag = "AyudasteAMateo" },
		bruno_hablaste_con_el = { If = { Choices = { Malotes = "Hablar" } } },
		["bruno_hablaste_con_el"] = { If = { Choices = { Malotes = "Hablar" } } },
		iker_en_grupo = { Flag = "IkerEnElGrupo" },
		iker_en_prueba = { If = { Choices = { IkerFinal = "Perdon" } } },
		iker_distancia = { If = { Choices = { IkerFinal = "Lucia" } } },
		["el jugador responde"] = { If = {} },
	},
	-- (lo de «tú hablaste conmigo» solo si en Cole04 fuiste a hablar con Bruno, como antes)
	SiTexto = {
		{ "Tú lo sabes, ¿verdad?", { Flags = { "Bruno_HablasteConEl" } } },
		{ "Tú hablaste conmigo.", { Flags = { "Bruno_HablasteConEl" } } },
		{ "Sabes que no miento.", { Flags = { "Bruno_HablasteConEl" } } },
	},
	-- «Musica: Investigación» no es válida: Calma explorando, Tension con las pistas
	Musica = { ["4"] = { "Calma" }, ["5"] = { "Tension" } },
	Informe = "El juego tiene 10 pasos y el guion 24: los PASO 9-20 (la confesión, el concurso de preguntas, lo que decidís con Iker) se cuentan en la conversación de la confesión (paso 9, la que sale al acusar) y los 21-24 en la del final (paso 10). El concurso de preguntas no es un minijuego en esta misión: sus preguntas quedan como elecciones de la conversación. «Musica: Investigación» del PASO 4 no es válida: se usa Calma en la exploración y Tension en las pistas. «bruno_hablaste_con_el» = Choices.Malotes == Hablar (Cole04). Si Iker entra en el grupo queda la marca que ya usa el juego, Flags.IkerEnElGrupo (Choices.IkerFinal = Grupo), para que pueda aparecer con el grupo después; «en prueba» del guion es la opción Perdon del juego y «distancia», la opción Lucia. El «FLASH VISUAL» (recuerdo de una frase de Bruno) es un plano corto con la frase; no hay un efecto de «recuerdo» en el motor, así que va como plano y frase.",
}
