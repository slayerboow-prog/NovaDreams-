-- Mapa del guion reescrito de Saga_19_Recuerdos (lo lee scripts/audit/aplicar-reescritura.luau).
-- 6 PASO = 3 pasos del juego (el 2 es el grupo de los sitios: el microondas, la granja de Villaverde y el
-- anclaje del cielo). Cada recuerdo de Cosme sale solo si lo viviste (la marca o el recuerdo que lo guarda).
return {
	Prefijo = "Saga_19",
	Variables = {
		-- (Cosme recordó tu nombre al final de Saga_18: el recuerdo TuNombre)
		["existe el recuerdo"] = { If = { Memories = { "TuNombre" } } },
		["el recuerdo"] = { If = { Memories = { "TuNombre" } } },
		["no existe"] = { If = { NotMemories = { "TuNombre" } } },
		-- (en la granja: lo que dice Cosme vale para todos)
		existe = { If = {} },
		clones_conocidos = { If = { Memories = { "LosClones" } } },
		tirachinas_abu = { If = { Memories = { "TirachinasAbu" } } },
		calcetines_perdidos = { If = { Memories = { "CosasPerdidas" } } },
		credencial_cosme = { If = { Flags = { "AyudanteOficial" } } },
		vecino_secreto = { If = { Flags = { "SecretoCosme" } } },
		cosme_rescatado = { If = { Flags = { "CosmeRescatado" } } },
		cosme_recuerda_tu_nombre = { If = {} },
	},
	Informe = "La mecánica es la de siempre: la lista de Pip, llevar a Cosme al microondas del garaje, a la granja de Villaverde y al anclaje del cielo, y la escena en la que vuelve. Cada recuerdo de Cosme sale solo si lo viviste: su nombre (el recuerdo TuNombre de Saga_18), los clones (LosClones), el tirachinas de Abu (TirachinasAbu), los calcetines (CosasPerdidas, Saga_05), la credencial (AyudanteOficial, Saga_07), el vecino secreto (SecretoCosme, Loco_N1) y el rescate (CosmeRescatado, Saga_17). No se crean marcas nuevas.",
}
