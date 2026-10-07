-- Mapa del guion reescrito de Nino_Recados (lo lee scripts/audit/aplicar-reescritura.luau).
-- 3 PASO = 3 pasos del juego: comprar en la librería, comprar en la farmacia y volver a casa.
return {
	Prefijo = "Nino_Recados",
	Hablantes = {
		["Mamá/Papá"] = "Familia",
		-- (las tiendas no tienen dependiente en el reparto: lo que dicen lo cuenta el narrador)
		["Dependiente/a"] = "@Dependiente",
		["Dependienta"] = "@Dependiente",
		["Dependiente"] = "@Dependiente",
		["Farmacéutico/a"] = "@Farmacéutico",
		["Farmacéutica"] = "@Farmacéutico",
		["Farmacéutico"] = "@Farmacéutico",
		["Vecino"] = "@Vecino",
		["Vecina"] = "@Vecino",
	},
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	Variables = {
		["el jugador revisa de nuevo la lista"] = { If = {} },
		["recado_recordo_todo = true"] = { If = {} },
		recado_recordo_todo = { If = {} },
		["todos los objetos entregados"] = { If = {} },
		-- (sin mecánica en esta misión: esas frases no salen)
		ayuda = { Nunca = true },
		["vuelve correctamente sin activar navegacion"] = { Nunca = true },
		recado_ayudo_a_alguien = { Nunca = true },
		["recado_ayudo_a_alguien = true"] = { Nunca = true },
		["el jugador olvido algo durante el recorrido"] = { Nunca = true },
	},
	Informe = "La mecánica es la de siempre (comprar en la librería y en la farmacia con BoughtItem, volver a casa); sin marcas ni medicinas reales. La librería y la farmacia no tienen dependiente en el reparto del juego: lo que dicen sale como frase del narrador («Dependiente: «…»»). El favor opcional al vecino no tiene mecánica en esta misión: sus frases («si ayuda») quedan sin salir (pendiente: un paso opcional). «recado_se_oriento_solo» (volver sin activar el GPS) no se marca: el paso Reach no sabe si el GPS estuvo encendido y añadirlo sería tocar LifeStoryService/Gps (pendiente); sus frases quedan sin salir. «recado_recordo_todo» siempre es verdad (no se puede terminar sin comprar las dos cosas).",
}
