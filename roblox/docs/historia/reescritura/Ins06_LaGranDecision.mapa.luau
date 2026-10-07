-- Mapa del guion reescrito de Ins06_LaGranDecision (lo lee scripts/audit/aplicar-reescritura.luau).
-- 35 PASO = 27 pasos del juego con sus subpasos (los planes de cada amigo). Es el CAMBIO DE ETAPA
-- (Adolescente → Adulto): la estructura, las notas de selectividad, la decisión Futuro y la transición
-- final (Adol_Selectividad) no cambian; solo los textos. No se inventan marcas que nada pone.
return {
	Prefijo = "Ins06",
	-- El PASO 27 es el montaje de cambio de etapa (Adol_Selectividad): diseño fijo que comprueba test-etapas
	Pasos = { ["27"] = false },
	Variables = {
		primer_dia_instituto = { If = { Memories = { "PrimerDiaInstituto" } } },
		que_quieres_ser = { If = { Memories = { "QueQuieresSer" } } },
		primer_sueldo = { If = { Memories = { "PrimerSueldo" } } },
		conoces_a_leire = { If = { Flags = { "ConocesALeire" } } },
		-- (estudiar en la biblioteca es una clase del juego: no sabe si te distraes)
		["el jugador se distrae"] = { Nunca = true },
		["elige trabajar"] = { If = { Choices = { Futuro = "Trabajar" } } },
		["elige universidad"] = { If = { Choices = { Futuro = "Universidad" } } },
		["corresponde a la etapa universitaria"] = { If = { Choices = { Futuro = "Universidad" } } },
		["los imparables"] = { If = { Choices = { NombreGrupo = "Los Imparables" } } },
		["la patrulla valmar"] = { If = { Choices = { NombreGrupo = "La Patrulla Valmar" } } },
		["los del banco azul"] = { If = { Choices = { NombreGrupo = "Los del Banco Azul" } } },
		["los dinosaurios"] = { If = { Choices = { NombreGrupo = "Los Dinosaurios" } } },
	},
	Informe = "Es la transición de etapa (Adolescente → Adulto): la estructura es la de siempre (los planes de los amigos, Carmen, las puertas abiertas, la selectividad y sus notas, la convocatoria de julio, la noche de la decisión, la decisión Futuro, la graduación y la transición Adol_Selectividad, que no se cambia: el montaje de cambio de etapa tiene un diseño fijo comprobado por test-etapas). Las variantes van con lo que ya guarda el juego: los recuerdos PrimerDiaInstituto, QueQuieresSer y PrimerSueldo, ConocesALeire, las decisiones de la etapa (Veterano, RecreoIns, SitioInstituto, Camino, Reportaje, Orientacion, Empleo, Meta, Futuro…) y el nombre del grupo (Choices.NombreGrupo). No se crean marcas nuevas: si el guion pide una que nada pone, la frase no sale. «Si el jugador se distrae» en la biblioteca no es una mecánica: esas frases no salen.",
}
