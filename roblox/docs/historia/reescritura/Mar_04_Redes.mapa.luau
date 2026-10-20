-- Mapa del guion de Mar_04_Redes (lo lee scripts/audit/aplicar-reescritura.luau).
-- 5 pasos: Tomé (Talk «Tome»), el kelp del norte (Reach), la persecución (Event MarChase: la lleva
-- Services/SeaCivService), Sargo (Talk «Sargo») y la decisión (Choice MarSargo; sin frases de guion: las
-- opciones son las de la misión).
return {
	Prefijo = "Mar04",
	Pasos = { ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4 },
	Dialogos = { ["1"] = "Tome", ["4"] = "Sargo" },
	Hablantes = { Protagonista = "Yo", ["Tomé"] = "Tome" },
	Informe = "Acto I del mar (4/4 de la fase 1). Tomé vive en los Jardines y Sargo aparece en el kelp solo para quien juega la persecución (Services/SeaCivService: huye por un camino fijo, espera si te quedas atrás y vuelve a empezar si tardas más de 150 s). La decisión no lleva frases propias: el resultado se ve en la próxima fase (cadena «El joven de la Marea Callada»).",
}
