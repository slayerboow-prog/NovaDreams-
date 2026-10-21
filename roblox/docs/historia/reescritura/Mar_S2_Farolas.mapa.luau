-- Mapa del guion de Mar_S2_Farolas (lo lee scripts/audit/aplicar-reescritura.luau).
-- 3 pasos: Lía (Talk «Lia»), un turno de farolero/a (Event MarJobDone, MarJobService) y Lía (Talk «Gracias»).
return {
	Prefijo = "MarS2",
	Pasos = { ["1"] = 1, ["2"] = 2, ["3"] = 3 },
	Dialogos = { ["1"] = "Lia", ["3"] = "Gracias" },
	Hablantes = { Protagonista = "Yo", ["Lía"] = "Lia" },
	Informe = "Secundaria del mar (fase 1). El turno es el oficio de farolero/a de siempre (Services/MarJobService), con su paga.",
}
