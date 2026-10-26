-- Mapa del guion de Talasa_04_Bruma (lo lee scripts/audit/aplicar-reescritura.luau).
-- 6 pasos: 1 Bruma, 2 la decisión, 3 los cangrejos de coral (Fight), 4 llevarse a la patrulla (si la
-- ayudaste), 5 la Almirante Coria (si avisaste), 6 después, en las Balsas.
return {
	Prefijo = "Talasa4",
	Pasos = {
		["1"] = 1,
		["2"] = 5,
		["3"] = 6,
	},
	Variables = {
		bruma_ayudada = { Flag = "BrumaAyudada" },
		bruma_delatada = { Flag = "BrumaDelatada" },
	},
	Informe = "Saga 2 · Tálasa. La mecánica es la de siempre: Bruma, la decisión (TalasaBruma), los cangrejos de coral negro en el Muelle (se deshacen en arena), la huida de la patrulla o la charla con Coria según lo que elegiste y la escena de después, con una frase distinta en cada rama.",
}
