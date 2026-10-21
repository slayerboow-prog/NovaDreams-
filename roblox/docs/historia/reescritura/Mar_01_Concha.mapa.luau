-- Mapa del guion de Mar_01_Concha (lo lee scripts/audit/aplicar-reescritura.luau).
-- 5 pasos: Ruinas (Reach), arco de kelp (Reach), Ilun en la plaza (Talk «Plaza»), el paseo por la ciudad
-- (Group de dos Reach) e Ilun otra vez (Talk «Secreto»).
return {
	Prefijo = "Mar01",
	Pasos = { ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5 },
	Dialogos = { ["3"] = "Plaza", ["5"] = "Secreto" },
	Hablantes = { Protagonista = "Yo" },
	Informe = "Acto I del mar (1/4). Ilun vive en el agua (Services/SeaCivService): no es actor de la escena. La ruta es la de las perlas de guía de la fase 0 (shared/Sea/Nacara.Route).",
}
