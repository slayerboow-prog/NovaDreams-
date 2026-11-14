-- Mapa del guion de Deriva_00_Canto (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión (Misiones/Deriva_ActoI) tiene 4 pasos: 1 llegar a la anomalía, 2 aguantar dentro el escaneo,
-- 3 atracar en la Vigía, 4 cinemática con la doctora Ivo. Las frases suenan por radio al EMPEZAR cada paso.
return {
	Prefijo = "Canto",
	Pasos = {
		["1"] = 2, -- al llegar: empieza el escaneo (y la interferencia)
		["2"] = 3, -- escaneo terminado: «llévalo a la Vigía»
	},
	Informe = "La Deriva, Acto I (expansión espacial), hora 2. La cinemática de la Vigía está en Happenings/Deriva (Deriva_Vigia_Ivo); aquí, la radio.",
}
