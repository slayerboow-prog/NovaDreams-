-- Mapa del guion reescrito de Ins06_LaGranDecision (lo lee scripts/audit/aplicar-reescritura.luau).
-- 35 PASO = 27 pasos del juego con sus subpasos (los planes de cada amigo). Es el CAMBIO DE ETAPA
-- (Adolescente → Adulto): la estructura, las notas de selectividad, la decisión Futuro y la transición
-- final (Adol_Selectividad) no cambian; solo los textos. No se inventan marcas que nada pone.
return {
	Prefijo = "Ins06",
	-- El PASO 27 es el montaje de cambio de etapa (Adol_Selectividad): diseño fijo que comprueba test-etapas
	-- (la cinemática Ins06_Noche se queda como está: lee lo que hiciste antes —tu primer día, tus dudas, tu sueño de niño, la comisaría, el ahorro y el primer sueldo— con sus variantes; su texto nuevo (PASO 22) está fundido a mano en la escena)
	-- (la cinemática Ins06_Graduacion se queda como está: lee lo que hiciste antes —el ascensor, el nombre del grupo, la delegada, la foto de Leire y Bruno— con sus variantes; su texto nuevo (PASO 26) está fundido a mano en la escena)
	Pasos = { ["27"] = false, ["22"] = false, ["26"] = false },
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
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		-- (opciones de la elección y notas que se colaban como frases del jugador: no salen)
		{ "Siempre disponible", { Nunca = true } },
		-- (Nico: lo de Omar solo si se lo dijiste aparte, Ins05; lo del estadio solo si viviste el cruce y te redimiste, Pan3)
		{ "Oye…", { Choices = { HablasNico = "Privado" } } },
		{ "Nunca te lo he dicho bien.", { Choices = { HablasNico = "Privado" } } },
		{ "Gracias por lo de Omar.", { Choices = { HablasNico = "Privado" } } },
		{ "Por decírmelo a la cara.", { Choices = { HablasNico = "Privado" } } },
		{ "Y aquel día…", { Memories = { "ElCruce" }, Flags = { "Redimido" } } },
		{ "Cuando soltaste la bolsa de camisetas.", { Memories = { "ElCruce" }, Flags = { "Redimido" } } },
		{ "Ese día supe que seguías siendo tú.", { Memories = { "ElCruce" }, Flags = { "Redimido" } } },
		-- (notas de diseño del guion que no son frases de nadie: no salen)
		{ "Está comiendo.", { Nunca = true } },
		{ "Tú, en medio.", { Nunca = true } },
	},
}
