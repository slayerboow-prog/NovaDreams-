-- Mapa del guion reescrito de Cole08_Torneo (lo lee scripts/audit/aplicar-reescritura.luau).
-- Sus 38 PASO son los 38 pasos del juego (sale de la exportación).
return {
	Prefijo = "Cole08",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben", ["Andrés"] = "Andres" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	-- El grito con el nombre del grupo: el nombre real que elegiste en Cole03 (no las cuatro variantes)
	Reemplazos = {
		["Los Imparables"] = "{grupo}",
		["La Patrulla Valmar"] = "{grupo}",
		["Los del Banco Azul"] = "{grupo}",
		["Los Dinosaurios"] = "{grupo}",
		["¡Ese es mi [tu nombre]!"] = "¡Esa es mi estrella!",
		["¡Ese es mi {nombre}!"] = "¡Esa es mi estrella!",
	},
	Variables = {
		deporte = { Choice = "Deporte" },
		capitan = { Choice = "Capitan" },
		estrategia = { Choice = "Estrategia" },
		malotes = { Choice = "Malotes" },
		nombre_grupo = { Choice = "NombreGrupo" },
		hugo_con_el_grupo = { Flag = "HugoConElGrupo" },
		bruno_hablaste_con_el = { If = { Choices = { Malotes = "Hablar" } } },
		ganaste = { If = { Flags = { "TorneoGanado" } } },
		perdiste = { If = { Flags = { "TorneoPerdido" } } },
		["torneo ganado"] = { If = { Flags = { "TorneoGanado" } } },
		["torneo perdido"] = { If = { Flags = { "TorneoPerdido" } } },
		corresponde = { If = {} },
		["cualquiera de los tres deportes"] = { If = {} },
		puerta_pasillo_vista = { Flag = "PuertaPasilloVista" },
	},
	Informe = "Los minijuegos de cada deporte (Futbol / Timing / circuito de la pista) se juegan igual. El grito del grupo usa el nombre real elegido en Cole03 ({grupo}) en vez de las cuatro variantes escritas. «¡Ese es mi [tu nombre]!» pasa a «¡Esa es mi estrella!» (neutro). hugo_con_el_grupo = Flags.HugoConElGrupo; bruno_hablaste_con_el = Choices.Malotes == Hablar; ganaste/perdiste = Flags.TorneoGanado / TorneoPerdido. La marca nueva Flags.PuertaPasilloVista queda guardada para Cole09.",
}
