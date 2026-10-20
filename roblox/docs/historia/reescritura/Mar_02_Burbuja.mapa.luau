-- Mapa del guion de Mar_02_Burbuja (lo lee scripts/audit/aplicar-reescritura.luau).
-- 5 pasos: Oriana (Talk «Oriana»), La Burbuja (Reach), Bartolo (Talk «Bartolo»), las tres conchas (Group de
-- Use) y el trueque (Talk «Trueque»).
return {
	Prefijo = "Mar02",
	Pasos = { ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5 },
	Dialogos = { ["1"] = "Oriana", ["3"] = "Bartolo", ["5"] = "Trueque" },
	Hablantes = { Protagonista = "Yo" },
	Informe = "Acto I del mar (2/4). Oriana y Bartolo viven en el agua (NacaraService y SeaCivService): no son actores de la escena. La brújula de Bartolo es parte del guion, no un objeto de la mochila (fase 1).",
}
