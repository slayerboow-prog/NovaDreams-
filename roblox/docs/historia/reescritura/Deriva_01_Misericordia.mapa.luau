-- Mapa del guion de Deriva_01_Misericordia (lo lee scripts/audit/aplicar-reescritura.luau).
-- La misión (Misiones/Deriva_ActoI) tiene 10 pasos: 1 llegar al pecio, 2 atracar en la esclusa, 3 cinemática
-- de la entrada, 4 los tres fusibles (grupo), 5 entrar en el puente, 6 cinemática del último registro,
-- 7 sacar el núcleo, 8 volver a la nave, 9 la emboscada, 10 entregar en Alba. Las frases del guion suenan
-- por radio al cumplir los pasos que no son cinemáticas (Services/DerivaService avisa de cada uno).
return {
	Prefijo = "Deriva1",
	-- (las frases de cada PASO suenan al EMPEZAR el paso del juego: las lanza el paso anterior al cumplirse)
	Pasos = {
		["1"] = 2, -- al llegar al pecio: empieza «atraca en la esclusa»
		["2"] = 5, -- con los tres fusibles: empieza «entra en el puente»
		["3"] = 8, -- con el núcleo: empieza «vuelve a la nave»
		["4"] = 9, -- al soltar amarras: contactos
		["5"] = 10, -- los Hilanderos derribados: «llévalo a Alba»
	},
	-- (lo que pasa en Alba al entregar el núcleo es la escena ligera Deriva_Alba_Fin: Happenings/Deriva)
	Informe = "La Deriva, Acto I (expansión espacial). Dos cinemáticas propias (Happenings/Deriva) y tres registros que se escuchan andando; aquí, las frases por radio entre pasos. Tono para 13-15 años: hay muertos, fuera de plano.",
}
