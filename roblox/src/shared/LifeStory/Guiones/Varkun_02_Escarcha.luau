-- GUION REESCRITO de Varkun_02_Escarcha (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Varkun_02_Escarcha.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Varkun_02_Escarcha
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Varkun_02_Escarcha.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Varkun_02_Escarcha.md",
	Scenes = {
		Varkun2_G1_Fin = {
			Light = true,
			Duration = 23.3,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "NILDA", Npc = "NILDA" } }, { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = {
					{
						At = 0.4,
						S = "NILDA",
						T = "Anomalía delante. No es una tormenta ni una nebulosa. Es un nudo. Un nudo de hilos de luz del tamaño de una casa.",
						To = "Yo",
					},
					{ At = 9.3, S = "Cosme", T = "Igual que los del carguero. Alguien está cosiendo el espacio por aquí, criatura.", To = "Yo" },
					{ At = 15.8, S = "NILDA", T = "Necesito escanearla desde dentro. Veinte segundos. No te alejes, que pierdo la señal.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Tension" }, { At = 11.3, Intensity = "Tension" } },
			},
		},
		Varkun2_G3_Entra = {
			Light = true,
			Duration = 45.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
					{ At = 0, Use = { Key = "Varkun", Npc = "Varkun" } },
					{ At = 0, Use = { Key = "NILDA", Npc = "NILDA" } },
				},
				Dialogue = {
					{ At = 0.4, S = "NILDA", T = "Escaneo completo. Espera. Hay una voz dentro de la señal.", To = "Yo" },
					{ At = 5.3, S = "Varkun", T = "Gracias por guardar mi hilo. Pocos saben tratar bien las cosas que se están acabando.", To = "Yo" },
					{ At = 12.1, S = "Cosme", T = "¿Quién eres? ¿Y qué haces cosiendo naves rotas?", To = "Yo" },
					{ At = 16.3, S = "Varkun", T = "No las coso. Les quito el hilo antes de que se rompan solas. Es más limpio. Y más amable.", To = "Yo" },
					{ At = 23.5, S = "Varkun", T = "Me llamo Varkun. En mi mundo me llamaban de otra forma. Pero ya no queda nadie que lo diga.", To = "Yo" },
					{ At = 30.8, S = "Narrador", T = "Al fondo, una rueda del tamaño de una luna gira despacio. En su centro, un huso negro. La Rueca." },
					{ At = 38.4, S = "NILDA", T = "Hilanderos saliendo de la Rueca. Aguanta, que esto no es una visita de cortesía.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Tema" } },
			},
		},
		Varkun2_G4_Entra = {
			Light = true,
			Duration = 31.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
					{ At = 0, Use = { Key = "Varkun", Npc = "Varkun" } },
					{ At = 0, Use = { Key = "NILDA", Npc = "NILDA" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Varkun", T = "No temas. Hoy solo he venido a mirar. Tu mundo aún no grita.", To = "Yo" },
					{ At = 5.5, S = "Varkun", T = "Pero todos los mundos gritan al final. Y cuando el tuyo lo haga, yo estaré allí.", To = "Yo" },
					{ At = 12, S = "Cosme", T = "Eso lo veremos, Deshilador. Yo también sé coser.", To = "Yo" },
					{ At = 16.2, S = "Pip", T = "Señor, se va. La Rueca se va.", To = "Yo" },
					{
						At = 19.1,
						S = "NILDA",
						T = "Mi abuela conoció ese nombre. Hay un archivo cerrado en mi memoria. Dice: «Para V., si alguna vez vuelve».",
						To = "Yo",
					},
					{ At = 27.5, S = "Cosme", T = "Criatura… esto acaba de empezar.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Varkun2_G1_Fin" } },
		["2"] = { Effects = { Scene = "Varkun2_G3_Entra" } },
		["3"] = { Effects = { Scene = "Varkun2_G4_Entra" } },
	},
}
