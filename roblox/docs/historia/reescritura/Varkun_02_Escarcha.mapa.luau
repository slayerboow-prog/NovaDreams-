-- Mapa del guion de Varkun_02_Escarcha (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión tiene 3 pasos «Event» (Services/VarkunService): 1 llegar a la anomalía, 2 escanearla (aquí
-- habla Varkun por primera vez y aparece la Rueca), 3 aguantar hasta que la Rueca se va.
return {
	Prefijo = "Varkun2",
	Pasos = {
		["1"] = 1, -- al llegar a la anomalía
		["2"] = 2, -- (al empezar el paso 2: «veinte segundos»)
		["3"] = 3, -- (al empezar el paso 3: la voz de Varkun y la Rueca)
		["4"] = 4, -- la Rueca se va
	},
	Informe = "Prólogo del espacio de la Saga 2 (villano aprobado por el dueño). Sin cinemáticas: la nave sigue volando y las frases suenan por radio al cumplir cada paso.",
}
