-- Mapa del guion reescrito de Cole10_Festival (lo lee scripts/audit/aplicar-reescritura.luau).
-- Formato libre («PASO n · TÍTULO»); sus 25 PASO son los 25 pasos del juego.
return {
	Prefijo = "Cole10",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben", ["Marta"] = "Marta", ["Niña"] = "Alumno2", ["Niña perdida"] = "Alumno2" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	Variables = {
		festival = { Choice = "Festival" },
		talento = { Choice = "Talento" },
		festival_bruno = { Choice = "FestivalBruno" },
		nina_perdida = { Choice = "NinaPerdida" },
		iker = { If = { Flags = { "IkerEnElGrupo" } } },
		["ayudaste a bruno"] = { If = { Choices = { FestivalBruno = "Ayudar" } } },
		cole10_bruno_ayudado = { If = { Choices = { FestivalBruno = "Ayudar" } } },
		cole10_hugo_actuo = { If = { Flags = { "HugoConElGrupo" } } },
		["subes al escenario"] = { Flag = "SubesAlEscenario" },
		-- los minijuegos de cada tarea dan TareaBrillante al salir bien; el de los talentos, AplausoFinal
		["se completan correctamente"] = { If = { Flags = { "TareaBrillante" } } },
		["sale perfecto"] = { If = { Flags = { "TareaBrillante" } } },
		["sale normal"] = { If = { NotFlags = { "TareaBrillante" } } },
		falla = { If = { NotFlags = { "TareaBrillante" } } },
		["exito alto"] = { If = { Flags = { "AplausoFinal" } } },
		["rendimiento medio"] = { If = { NotFlags = { "AplausoFinal" } } },
	},
	Informe = "Se conservan las 5 tareas (Decoración/Música/Comida/Fotos/Teatro) con sus minijuegos, los imprevistos (farolillos, altavoz, la niña perdida, el puesto de Bruno) y los talentos. Marcas para el montaje del instituto: Choices.FestivalBruno (Ayudar = cole10_bruno_ayudado), Flags.SubesAlEscenario, Flags.AplausoFinal, Flags.TareaBrillante; «Hugo actuó» es Flags.HugoConElGrupo (si está en el grupo actúa con vosotros). La foto del festival es la cinemática final y el recuerdo de la misión: no hay álbum de fotos aparte. Lo que el guion pide de dirección (NPC con rutinas por el festival, luz de atardecer, ambiente sonoro) no se añade: el festival no tiene un decorado propio donde ponerlo barato (pendiente); la música y el ambiente de cada paso son los de las escenas.",
}
