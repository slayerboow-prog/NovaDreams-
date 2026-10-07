-- Mapa del guion reescrito de Saga_09_Archivo (lo lee scripts/audit/aplicar-reescritura.luau).
-- 4 PASO = 4 pasos del juego (Pip, el archivo, la cinta en el proyector y Cosme en la puerta).
return {
	Prefijo = "Saga_09",
	Variables = {
		sabe_fusion = { Flag = "SabeFusion" },
		["el jugador no tiene esa informacion"] = { If = { NotFlags = { "SabeFusion" } } },
	},
	Informe = "La mecánica es la de siempre: Pip, la caja del archivo, la cinta en el proyector (eres el Ancla: SabeQueEsAncla) y Cosme en la puerta con la decisión de perdonarle o enfadarte (PerdonaACosme / EnfadoConCosme, que leen las misiones siguientes). Lo que Cosme dice de la Fusión depende de SabeFusion (Saga_08).",
	-- (acotaciones del guion que no son frases: no salen)
	SiTexto = {
		{ "No se defiende.", { Nunca = true } },
		{ "No puede.", { Nunca = true } },
	},
}
