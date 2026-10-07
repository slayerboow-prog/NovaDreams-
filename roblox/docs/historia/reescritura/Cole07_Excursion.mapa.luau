-- Mapa del guion reescrito de Cole07_Excursion (lo lee scripts/audit/aplicar-reescritura.luau).
-- En el juego son 16 pasos y el guion trae 16 PASO (más los objetivos 8.x y 11.x de los Group).
return {
	Prefijo = "Cole07",
	Hablantes = {
		["Mamá/Papá"] = "Familia",
		["Profe Lucía"] = "Lucia",
		["Ramón"] = "Ramon",
		["Álex"] = "Alex",
		["Rubén"] = "Ruben",
		["Julián"] = "Julian",
		-- quien se pierde en la granja: Mateo si es tu amigo (ayudaste_a_mateo); si no, Omar
		["Compañero"] = { { S = "Mateo", If = { Flags = { "AyudasteAMateo" } } }, { S = "Omar", If = { NotFlags = { "AyudasteAMateo" } } } },
		["Compañera"] = { { S = "Mateo", If = { Flags = { "AyudasteAMateo" } } }, { S = "Omar", If = { NotFlags = { "AyudasteAMateo" } } } },
	},
	Sujetos = { ["Compañero"] = "Mateo" },
	-- En el juego, Petra es la gallina gigante de la Saga: la gallina de Paula se llama Remedios
	Reemplazos = { ["Petra"] = "Remedios" },
	Variables = {
		asiento_bus = { Choice = "AsientoBus" },
		ayudaste_a_mateo = { Flag = "AyudasteAMateo" },
		nombre_grupo = { Choice = "NombreGrupo" },
	},
	Informe = "Quien se pierde en la granja es Mateo si es tu amigo (Flags.AyudasteAMateo) y Omar si no, como en el juego: las frases del «Compañero» del guion salen dos veces, una con cada uno y su condición. La gallina «Petra» del guion se llama Remedios (Petra es la gallina gigante de la Saga de la Grieta). Las actividades de la granja (gallinas, huerto, caballos, tractor), el minijuego del grano (Timing), las pistas y la foto de grupo se juegan igual; el torneo al volver lo abre la misión siguiente como siempre.",
}
