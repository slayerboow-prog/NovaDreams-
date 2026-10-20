-- Mapa del guion reescrito de Cole06_Examen (lo lee scripts/audit/aplicar-reescritura.luau).
-- Sus 20 PASO son los 20 pasos del juego. (Este guion viene en el formato nuevo: «MISIÓN:», «Ir a»,
-- «Hablar», diálogos en dos líneas, «Tú:»…)
return {
	Prefijo = "Cole06",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben", ["Marisa"] = "Marisa", ["Bibliotecaria"] = "Marisa" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	Variables = {
		companero_estudio = { Choice = "CompaneroEstudio" },
		["estudiaste con sara"] = { If = { Choices = { CompaneroEstudio = "Sara" } } },
		["estudiaste con mateo"] = { If = { Choices = { CompaneroEstudio = "Mateo" } } },
		["estudiaste con iker"] = { If = { Choices = { CompaneroEstudio = "Iker" } } },
		["estudiaste solo"] = { If = { Choices = { CompaneroEstudio = "Solo" } } },
		["estudiaste sola"] = { If = { Choices = { CompaneroEstudio = "Solo" } } },
		aprobaste = { If = { LastGradeAtLeast = 5 } },
		suspendiste = { If = { LastGradeBelow = 5 } },
		["sacaste sobresaliente"] = { If = { LastGradeAtLeast = 9 } },
		-- (el examen es la clase de siempre: lo que pasa pregunta a pregunta se resume con la nota final)
		["cometes varios errores"] = { If = { LastGradeBelow = 5 } },
		["encadenas respuestas correctas"] = { If = { LastGradeAtLeast = 7 } },
	},
	Informe = "El estudio y el examen son las clases de siempre (ClassService: preguntas y nota) y la recuperación sigue igual (paso 18 con nota < 5). La nota del guion («nota ≥ 9», «entre 5 y 8», «< 5») se mira con las condiciones de nota del juego (LastGradeAtLeast / LastGradeBelow). Lo que el guion cuenta pregunta a pregunta («si cometes varios errores», «si encadenas respuestas correctas») no lo guarda la clase: se resume con la nota final. Marisa, la bibliotecaria, ya está en el reparto. Con quién estudias = Choices.CompaneroEstudio (Sara/Iker/Mateo/Solo). La marca Estudiaste se sigue guardando, pero el guion nuevo solo lee EstudiasteMas.",
}
