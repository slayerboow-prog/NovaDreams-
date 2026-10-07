-- Mapa del guion reescrito de Cole11_Proyecto (lo lee scripts/audit/aplicar-reescritura.luau).
-- Formato libre («PASO n · TÍTULO»); sus 19 PASO son los 19 pasos del juego.
return {
	Prefijo = "Cole11",
	-- las variantes por compañero (el guion las escribe una detrás de otra): cada una, solo con el suyo
	PorHablante = { Companero = { "Sara", "Nico", "Iker", "Mateo", "Hugo" } },
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben", ["Andrés"] = "Andres" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	Variables = {
		companero = { Choice = "Companero" },
		tema = { Choice = "Tema" },
		rol = { Choice = "Rol" },
		discusion = { Choice = "Discusion" },
		-- «Si está presente:» (Nico, el tercero del equipo)
		["esta presente"] = { If = { Choices = { Companero = "Nico" } } },
	},
	Informe = "Se conservan el compañero (Choices.Companero), el tema (Huerto/Robot/Mascotas/Museo: Choices.Tema), el rol (Choices.Rol) y la discusión (Choices.Discusion), con sus minijuegos y la presentación con preguntas del jurado. «Estoy orgulloso/a de ti» y «Jefe o jefa de proyecto» van con {o/a}. La maqueta en 3 fases que evoluciona a la vista no se hace: el minijuego actual (Timing) es de una fase y no hay maqueta física que cambie (pendiente). Las listas de «Resultado según tema» del guion (Huerto: …, Robot: …) son notas de diseño, no frases: van al informe. test-reescritura recorre todas las combinaciones compañero × tema × rol y comprueba que ninguna frase la dice alguien que no está en tu equipo y que toda marca que se lee la pone alguien.",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		-- (notas de diseño del guion que no son frases de nadie: no salen)
		{ "Es un pequeñ{o/a} momento de crecimiento personal.", { Nunca = true } },
		{ "Es un pequeño momento de crecimiento personal.", { Nunca = true } },
		{ "Y lo mismo con cada compañero disponible.", { Nunca = true } },
	},
}
