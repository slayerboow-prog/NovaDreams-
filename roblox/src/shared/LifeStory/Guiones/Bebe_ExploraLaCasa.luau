-- GUION REESCRITO de Bebe_ExploraLaCasa (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Bebe_ExploraLaCasa.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Bebe_ExploraLaCasa
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Bebe_ExploraLaCasa.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Bebe_ExploraLaCasa.md",
	Scenes = {
		Bebe_Casa_G1_1_1_Fin = {
			Light = true,
			Duration = 18.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Ya sabes caminar." },
					{ At = 2.5, S = "Narrador", T = "Ahora toca descubrir para qué sirve todo lo demás." },
					{ At = 6.4, S = "Narrador", T = "Este lugar huele bien." },
					{ At = 8.7, S = "Narrador", T = "Y parece que aquí ocurre algo importante." },
					{ At = 12.1, S = "Narrador", T = "Primera lección de la vida:" },
					{ At = 14.8, S = "Narrador", T = "no todo lo que puedes tocar es un juguete." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Bebe_Casa_G1_2_Fin = {
			Light = true,
			Duration = 9.3,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Y esto…" },
					{ At = 2.4, S = "Narrador", T = "¿para qué sirve?" },
					{ At = 4.5, S = "Narrador", T = "Misterio resuelto." },
					{ At = 6.6, S = "Narrador", T = "Probablemente." },
				},
			},
		},
		Bebe_Casa_G1_3_Fin = {
			Light = true,
			Duration = 5.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.9, S = "Narrador", T = "Buena decisión." }, { At = 2.9, S = "Narrador", T = "Casi perfecta." } } },
		},
		Bebe_Casa_G2_Fin = {
			Skippable = true,
			Duration = 45.4,
			Anchors = { A_Familia = "Place:FamiliaPadre", L_HomeCocina = "Place:HomeCocina", Sitio = "Place:FamiliaPadre", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Anchor = "A_Familia", Key = "Familia", Npc = "Familia" } }, { At = 25.09, Mood = { Mood = "Joy", Key = "Familia" } } },
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:L_HomeCocina" },
					{ At = 2.4, Duration = 4.5, Shot = "Reaccion:Familia" },
					{ At = 6.86, Duration = 2.7, Shot = "Seguir:Yo" },
					{ At = 9.56, Duration = 2.1, Shot = "Hombro:Yo>Familia" },
					{ At = 11.61, Duration = 2.1, Shot = "Reaccion:Yo" },
					{ At = 13.66, Duration = 3.4, Shot = "Inserto:Familia" },
					{ At = 17.01, Duration = 2, Shot = "Medio:Familia" },
					{ At = 19.01, Duration = 6, Shot = "PrimerPlano:Yo" },
					{ At = 24.99, Duration = 4.5, Shot = "PrimerPlano:Familia" },
					{ At = 29.5, Duration = 2, Shot = "Reaccion:Yo" },
					{ At = 31.5, Duration = 5, Shot = "Reaccion:Familia" },
					{ At = 36.49, Duration = 2, Shot = "Reaccion:Yo" },
					{ At = 38.49, Duration = 6.3, Shot = "General:L_HomeCocina" },
				},
				Dialogue = {
					{ At = 2.4, S = "Familia", T = "Vaya, vaya.", To = "Yo" },
					{ At = 4.4, S = "Familia", T = "¿Otra vez de excursión?", To = "Yo" },
					{ At = 6.9, S = "Familia", T = "Ya has recorrido media casa.", To = "Yo" },
					{ At = 9.6, S = "Familia", T = "¿Tienes hambre?", To = "Yo" },
					{ At = 11.6, S = "Familia", T = "Eso me parecía.", To = "Yo" },
					{ At = 13.7, S = "Familia", T = "Aquí tienes, pequeñ{o/a} explorador{/a}.", To = "Yo" },
					{ At = 19, S = "Familia", T = "Primero aprendiste a caminar.", To = "Yo" },
					{ At = 21.8, S = "Familia", T = "Ahora ya quieres conocer toda la casa.", To = "Yo" },
					{ At = 25, S = "Familia", T = "Como sigas así, mañana te vas a querer escapar por la puerta.", To = "Yo", Mood = "Joy" },
					{ At = 32.4, S = "Familia", T = "No.", To = "Yo" },
					{ At = 34.4, S = "Familia", T = "Ni se te ocurra.", To = "Yo" },
					{ At = 38.5, S = "Narrador", T = "La casa ya no parece tan grande." },
					{ At = 41.4, S = "Narrador", T = "Pero fuera hay un mundo entero esperando." },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
	},
	Steps = {
		["1.1"] = { Effects = { Scene = "Bebe_Casa_G1_1_1_Fin" } },
		["1.2"] = { Effects = { Scene = "Bebe_Casa_G1_2_Fin" } },
		["1.3"] = { Effects = { Scene = "Bebe_Casa_G1_3_Fin" } },
		["2"] = { Effects = { Scene = "Bebe_Casa_G2_Fin" } },
	},
}
