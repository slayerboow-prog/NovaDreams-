-- Mapa del guion de Talasa_05_Senal (lo lee scripts/audit/aplicar-reescritura.luau).
-- 4 pasos: 1 el sónar, 2 el cuaderno (Use: su conversación es «Cuaderno»), 3 la decisión, 4 el cierre
-- (escena Talasa_Cierre, no se toca).
return {
	Prefijo = "Talasa5",
	Pasos = {
		["1"] = 1,
		["2"] = 2,
	},
	Dialogos = { ["2"] = "Cuaderno" },
	Informe = "Saga 2 · Tálasa. La mecánica es la de siempre: el sónar con Noa, leer el cuaderno (da la página del cuaderno), la decisión (TalasaNoa) y la escena del cierre en el Faro, con el gancho de la Cúpula Honda.",
}
