-- Mapa del guion reescrito de Cole08_Torneo (lo lee scripts/audit/aplicar-reescritura.luau).
-- Sus 38 PASO son los 38 pasos del juego (sale de la exportación).
return {
	Prefijo = "Cole08",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben", ["Andrés"] = "Andres" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	-- El grito con el nombre del grupo: el nombre real que elegiste en Cole03 (no las cuatro variantes)
	-- (cada variante del grito solo sale con su nombre de grupo: así se oye el que elegiste)
	PorTexto = { NombreGrupo = { "Los Imparables", "La Patrulla Valmar", "Los del Banco Azul", "Los Dinosaurios" } },
	Reemplazos = {
		["¡Ese es mi [tu nombre]!"] = "¡Esa es mi estrella!",
		["¡Ese es mi {nombre}!"] = "¡Esa es mi estrella!",
	},
	Variables = {
		deporte = { Choice = "Deporte" },
		capitan = { Choice = "Capitan", Valores = { OtroFutbol = "Otro", OtroBaloncesto = "Otro", OtroAtletismo = "Otro" } },
		["capitan otrofutbol"] = { If = { Choices = { Capitan = "Otro", Deporte = "Futbol" } } },
		["capitan otrobaloncesto"] = { If = { Choices = { Capitan = "Otro", Deporte = "Baloncesto" } } },
		["capitan otroatletismo"] = { If = { Choices = { Capitan = "Otro", Deporte = "Atletismo" } } },
		estrategia = { Choice = "Estrategia" },
		malotes = { Choice = "Malotes" },
		nombre_grupo = { Choice = "NombreGrupo" },
		hugo_con_el_grupo = { Flag = "HugoConElGrupo" },
		bruno_hablaste_con_el = { If = { Choices = { Malotes = "Hablar" } } },
		-- (ni hablaste con Bruno ni le acusaste)
		["no ocurrio ninguna de las anteriores"] = { If = { NotChoices = { Malotes = "Hablar" }, NotFlags = { "AcusasteABruno" } } },
		["si no ocurrio ninguna de las anteriores"] = { If = { NotChoices = { Malotes = "Hablar" }, NotFlags = { "AcusasteABruno" } } },
		ganaste = { If = { Flags = { "TorneoGanado" } } },
		perdiste = { If = { Flags = { "TorneoPerdido" } } },
		["torneo ganado"] = { If = { Flags = { "TorneoGanado" } } },
		["torneo perdido"] = { If = { Flags = { "TorneoPerdido" } } },
		corresponde = { If = {} },
		["cualquiera de los tres deportes"] = { If = {} },
		puerta_pasillo_vista = { Flag = "PuertaPasilloVista" },
		futbol = { If = { Choices = { Deporte = "Futbol" } } },
		baloncesto = { If = { Choices = { Deporte = "Baloncesto" } } },
		atletismo = { If = { Choices = { Deporte = "Atletismo" } } },
		["futbol defensa"] = { If = { Choices = { Deporte = "Futbol", Posicion = "Defensa" } } },
		["futbol delantero"] = { If = { Choices = { Deporte = "Futbol", Posicion = "Delantero" } } },
		["futbol portero"] = { If = { Choices = { Deporte = "Futbol", Posicion = "Portero" } } },
		["consigue una buena racha"] = { If = { Flags = { "BuenEntreno" } } },
		falla = { If = { NotFlags = { "BuenEntreno" } } },
		["falla demasiado"] = { If = { NotFlags = { "BuenEntreno" } } },
		["ocurrio ninguna de las anteriores"] = { If = {} },
	},
	Informe = "Los minijuegos de cada deporte (Futbol / Timing / circuito de la pista) se juegan igual. El grito del grupo: de las cuatro variantes escritas solo sale la del nombre que elegiste en Cole03 (Choices.NombreGrupo). «¡Ese es mi [tu nombre]!» pasa a «¡Esa es mi estrella!» (neutro). hugo_con_el_grupo = Flags.HugoConElGrupo; bruno_hablaste_con_el = Choices.Malotes == Hablar; ganaste/perdiste = Flags.TorneoGanado / TorneoPerdido. La marca nueva Flags.PuertaPasilloVista queda guardada para Cole09.",
}
