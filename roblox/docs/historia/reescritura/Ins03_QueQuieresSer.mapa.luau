-- Mapa del guion reescrito de Ins03_QueQuieresSer (lo lee scripts/audit/aplicar-reescritura.luau).
-- 14 PASO = 6 pasos del juego (el 4 es el grupo de las ocho profesiones, al menos cuatro).
return {
	Prefijo = "Ins03",
	-- (la cinemática Ins03_Carmen se queda como está: lee lo que hiciste antes —Bruno de compañero de pupitre, Leire y su tío, tu club— con sus variantes; el PASO 3 del guion queda para fundirlo a mano con ella)
	Pasos = { ["3"] = false },
	Hablantes = { ["Niño/a"] = "Yo", ["Niña"] = "Yo", ["Niño"] = "Yo" },
	Variables = {
		["conoces a leire"] = { If = { Flags = { "ConocesALeire" } } },
		["conoces_a_leire"] = { If = { Flags = { "ConocesALeire" } } },
		["primer club"] = { If = { Memories = { "PrimerClub" } } },
		["primer_club"] = { If = { Memories = { "PrimerClub" } } },
		["primer torneo"] = { If = { Memories = { "PrimerTorneo" } } },
		["primer_torneo"] = { If = { Memories = { "PrimerTorneo" } } },
		sueno_infancia = { Choice = "SuenoInfancia" },
		["sueno infancia"] = { Choice = "SuenoInfancia" },
		-- (el juego no guarda qué quiere ser Bruno: esas frases no salen)
		["bruno esta relacionado"] = { Nunca = true },
	},
	Informe = "La mecánica es la de siempre: la charla de Carmen (cinemática Ins03_Carmen), visitar al menos cuatro profesiones (hospital, laboratorio, comisaría, oficinas, taller, cafetería, estadio y cine) y la reflexión final. Los recuerdos breves de cada profesión salen con tu sueño de primaria (Choices.SuenoInfancia, de Cole03): «Niño/a» es el protagonista de pequeño. Lo de Leire va con ConocesALeire; el primer club y el torneo, con sus recuerdos (PrimerClub, PrimerTorneo). El juego no guarda qué quiere ser Bruno: sus frases de la comisaría no salen.",
}
