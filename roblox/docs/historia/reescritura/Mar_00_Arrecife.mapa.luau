-- Mapa del guion de Mar_00_Arrecife (lo lee scripts/audit/aplicar-reescritura.luau).
-- 3 pasos: llegar al jardín de coral (Reach), soltar los tres nudos de la red (Group de Use) y hablar con
-- Ilun (Talk «Concha»: SeaCivService le acerca a la red; la conversación es la de la misión).
return {
	Prefijo = "Mar00",
	Pasos = { ["1"] = 1, ["2"] = 2, ["3"] = 3 },
	Dialogos = { ["3"] = "Concha" },
	Hablantes = { Protagonista = "Yo" },
	Informe = "Prólogo del mar (fase 1, docs/mar/civilizacion-marina.md). Ilun no es actor de la escena: vive en el agua con su cola (Services/SeaCivService) y se acerca a la red mientras te toca hablar con él. Las frases de los pasos de nadar son del narrador.",
}
