-- Mapa del guion de Mar_03_Juicio (lo lee scripts/audit/aplicar-reescritura.luau).
-- 5 pasos: la Guardia (Talk «Guardia»), el juicio (escena del motor Mar_Juicio, Happenings/Mar), la decisión
-- (Choice MarJuicio), un turno de un oficio del mar (Event MarJobDone) y el veredicto (Talk «Veredicto»).
return {
	Prefijo = "Mar03",
	Pasos = { ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5 },
	Dialogos = { ["1"] = "Guardia", ["5"] = "Veredicto" },
	Hablantes = { Protagonista = "Yo", Guardia = "GuardiaConsejo" },
	Informe = "Acto I del mar (3/4). El juicio (PASO 2) es la escena del motor Mar_Juicio (shared/LifeStory/Happenings/Mar), con estas mismas frases, planos fijos en la Concha del Consejo y sin actores de la escena: Maresa e Ilun viven en el agua con su cola y la escena no puede crear gente con piernas debajo del agua. Las demás conversaciones son de la misión.",
}
