-- Mapa del guion reescrito de Ins01_NuevoInstituto (lo lee scripts/audit/aplicar-reescritura.luau).
-- 19 PASO = 19 pasos del juego. Es la transición de etapa (Niño → Adolescente): la estructura, los
-- teletransportes y las decisiones (Veterano, SitioInstituto) no cambian.
return {
	Prefijo = "Ins01",
	-- (la cinemática Ins01_Parada se queda como está: lee lo que hiciste antes —llegar tarde a la parada, la promesa del cole, el nombre del grupo, Hugo y Mateo— con sus variantes; su texto nuevo (PASO 4) está fundido a mano en la escena)
	Pasos = { ["4"] = false },
	Variables = {
		["mateo esta en el grupo"] = { If = { Flags = { "AyudasteAMateo" } } },
		["aparece mateo"] = { If = { Flags = { "AyudasteAMateo" } } },
		["hugo esta"] = { If = { Flags = { "HugoConElGrupo" } } },
		["hugo esta en el grupo"] = { If = { Flags = { "HugoConElGrupo" } } },
		["iker esta en el grupo"] = { If = { Flags = { "IkerEnElGrupo" } } },
		["la promesa fue «nuevos»"] = { If = { Choices = { Promesa = "Nuevos" } } },
		["la promesa fue nuevos"] = { If = { Choices = { Promesa = "Nuevos" } } },
		["fue «banco»"] = { If = { Choices = { Promesa = "Banco" } } },
		["fue banco"] = { If = { Choices = { Promesa = "Banco" } } },
		["la eleccion de primaria fue empezar de cero"] = { If = { Choices = { AdiosBruno = "DeCero" } } },
		-- (a quién miras en clase es solo una acotación: lo que dice Javier después vale para todos)
		["mira a omar"] = { If = {} },
		["mira a leire"] = { If = {} },
		["mira a bruno"] = { If = {} },
	},
	Informe = "La mecánica es la de siempre (transición, parada, autobús, entrada, la broma del veterano, el tablón, el tutor, dónde te sientas, clases, recreo con Leire y la cena). Las variantes van con las marcas de primaria: AyudasteAMateo (Mateo en el grupo), HugoConElGrupo, IkerEnElGrupo, la promesa del último día (Choices.Promesa: Nuevos/Banco/Juntos) y AdiosBruno = DeCero. A quién miras en clase de Historia no es una decisión del juego: lo que dice Javier sale siempre.",
}
