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
			Duration = 20.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Ya sabes caminar." },
					{ At = 2.9, S = "Narrador", T = "Ahora toca descubrir para qué sirve todo lo demás." },
					{ At = 7.3, S = "Narrador", T = "Este lugar huele bien." },
					{ At = 9.8, S = "Narrador", T = "Y parece que aquí ocurre algo importante." },
					{ At = 13.5, S = "Narrador", T = "Primera lección de la vida:" },
					{ At = 16.2, S = "Narrador", T = "no todo lo que puedes tocar es un juguete." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Bebe_Casa_G1_2_Fin = {
			Light = true,
			Duration = 6.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = { { At = 0.4, S = "Narrador", T = "Y esto… ¿para qué sirve?" }, { At = 2.9, S = "Narrador", T = "Misterio resuelto. Probablemente." } },
			},
		},
		Bebe_Casa_G1_3_Fin = {
			Light = true,
			Duration = 6.5,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.9, S = "Narrador", T = "Buena decisión." }, { At = 3.4, S = "Narrador", T = "Casi perfecta." } } },
		},
		Bebe_Casa_G2_Fin = {
			Skippable = true,
			Duration = 45.6,
			Anchors = { A_Familia = "Place:FamiliaPadre", L_HomeCocina = "Place:HomeCocina", Sitio = "Place:FamiliaPadre", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Anchor = "A_Familia", Key = "Familia", Npc = "Familia" } }, { At = 25.64, Mood = { Mood = "Joy", Key = "Familia" } } },
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:L_HomeCocina" },
					{ At = 2.4, Duration = 3.3, Shot = "Reaccion:Familia" },
					{ At = 5.7, Duration = 2.8, Shot = "Seguir:Yo" },
					{ At = 8.5, Duration = 2.5, Shot = "Hombro:Yo>Familia" },
					{ At = 11, Duration = 2.5, Shot = "Reaccion:Yo" },
					{ At = 13.5, Duration = 3.7, Shot = "Inserto:Familia" },
					{ At = 17.16, Duration = 2, Shot = "Medio:Familia" },
					{ At = 19.16, Duration = 6.4, Shot = "PrimerPlano:Yo" },
					{ At = 25.54, Duration = 5.2, Shot = "PrimerPlano:Familia" },
					{ At = 30.7, Duration = 2, Shot = "Reaccion:Yo" },
					{ At = 32.7, Duration = 3.4, Shot = "Reaccion:Familia" },
					{ At = 36.1, Duration = 2, Shot = "Reaccion:Yo" },
					{ At = 38.1, Duration = 6.8, Shot = "General:L_HomeCocina" },
				},
				Dialogue = {
					{ At = 2.4, S = "Familia", T = "Vaya, vaya. ¿Otra vez de excursión?", To = "Yo" },
					{ At = 5.7, S = "Familia", T = "Ya has recorrido media casa.", To = "Yo" },
					{ At = 8.5, S = "Familia", T = "¿Tienes hambre?", To = "Yo" },
					{ At = 11, S = "Familia", T = "Eso me parecía.", To = "Yo" },
					{ At = 13.5, S = "Familia", T = "Aquí tienes, pequeñ{o/a} explorador{/a}.", To = "Yo" },
					{ At = 19.2, S = "Familia", T = "Primero aprendiste a caminar.", To = "Yo" },
					{ At = 22, S = "Familia", T = "Ahora ya quieres conocer toda la casa.", To = "Yo" },
					{ At = 25.5, S = "Familia", T = "Como sigas así, mañana te vas a querer escapar por la puerta.", To = "Yo", Mood = "Joy" },
					{ At = 33.6, S = "Familia", T = "No. Ni se te ocurra.", To = "Yo" },
					{ At = 38.1, S = "Narrador", T = "La casa ya no parece tan grande." },
					{ At = 41.2, S = "Narrador", T = "Pero fuera hay un mundo entero esperando." },
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
