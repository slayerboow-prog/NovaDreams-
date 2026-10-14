-- Mapa del guion reescrito de Saga_08_MegaVerso (lo lee scripts/audit/aplicar-reescritura.luau).
-- 7 PASO = 4 pasos del juego (el 2 es el grupo de la información: folletos, ordenador y mapa).
return {
	Prefijo = "Saga_08",
	-- (la recepcionista de MegaVerso es la agente gris 2 del reparto)
	Hablantes = { Agente = "AgenteGris2", ["AGENTE DE MEGAVERSO"] = "AgenteGris2", Recepcionista = "AgenteGris2" },
	Informe = "La mecánica es la de siempre: la recepción de la oficina de MegaVerso, buscar información mientras nadie mira (folletos, ordenador y el mapa de la pared, que da SabeFusion como antes), la huida hasta la plaza del Distrito Financiero (Escape) y la escena de fuera. La recepcionista es la agente gris 2 del reparto. No se construye un edificio nuevo: es la oficina de siempre.",
}
