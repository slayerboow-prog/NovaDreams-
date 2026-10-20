-- Mapa del guion de Varkun_01_Costura (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión tiene 3 pasos «Event» (Services/VarkunService): 1 llegar al carguero, 2 derribar a las Agujas,
-- 3 atracar en la Cénit. Todo pasa volando: las frases son por radio (escenas ligeras al cumplir cada paso).
return {
	Prefijo = "Varkun1",
	Pasos = {
		["1"] = 1, -- al llegar al carguero destrozado
		["2"] = 2, -- al derribar a las tres Agujas
		["3"] = 3, -- (al empezar el paso 3: el carrete y «llévalo a la Cénit»)
		["4"] = 4, -- al atracar en la Cénit con el carrete
	},
	Informe = "Prólogo del espacio de la Saga 2 (villano aprobado por el dueño). Sin cinemáticas: la nave sigue volando y las frases suenan por radio al cumplir cada paso.",
}
