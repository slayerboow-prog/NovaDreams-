-- Mapa del guion reescrito de Saga_11_Cronos (lo lee scripts/audit/aplicar-reescritura.luau).
-- 5 PASO = 5 pasos del juego (Cronos, la funcionaria, los formularios, la persecución y la agente pillada).
return {
	Prefijo = "Saga_11",
	Hablantes = {
		Cronos = "CazadorTiempo",
		CRONOS = "CazadorTiempo",
		["Agente Cronos"] = "CazadorTiempo",
		Agente = "AgenteGris2",
		["Agente gris"] = "AgenteGris2",
		["Otro NPC señala"] = "@Vecino",
	},
	Variables = {
		ventanilla_aduana = { If = { Memories = { "VentanillaAduana" } } },
	},
	Informe = "La mecánica es la de siempre: el agente Cronos y su formulario, la funcionaria de las ventanillas, los formularios del Consorcio, la persecución de la agente gris (Chase) y la escena final en la que Cronos cambia de bando (CronosAliado, que leen las misiones de los aliados). Lo que Cronos recuerda de las tres ventanillas sale con el recuerdo VentanillaAduana (Saga_04). La agente que habla al final es la agente gris 2 del reparto; si la recuerdas arrepentida o no, lo guarda la marca que ya pone la escena.",
}
