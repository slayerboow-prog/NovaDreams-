-- GUION REESCRITO de Uni01_PrimerDia (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Uni01_PrimerDia.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Uni01_PrimerDia
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Uni01_PrimerDia.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Uni01_PrimerDia.md",
	Scenes = {
		Uni01_G6_7 = {
			Skippable = true,
			Duration = 46.8,
			Anchors = { Sitio = "Place:HabitacionResidencia", Yo = "Player" },
			Tracks = {
				Light = { { At = 0, Fade = 1.5, Preset = "Noche" } },
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Ambience = { { At = 0, Fade = 1.5, Kind = "Interior" } },
				Camera = { { At = 0, Duration = 46.8, To = { "Sitio", V(-14, 12, 18) }, Fov = 60, From = { "Sitio", V(-26, 18, 30) }, Look = { "Sitio", V(0, 2, 0) } } },
				Dialogue = {
					{ At = 0.4, S = "Pip", T = "Necesito hablar contigo.", To = "Yo" },
					{ At = 2.9, S = "Pip", T = "Segundo mensaje.", To = "Yo" },
					{ At = 4.9, S = "Pip", T = "Es sobre Cosme.", To = "Yo" },
					{ At = 7, S = "Pip", T = "No quería hacerlo durante tu graduación.", To = "Yo" },
					{ At = 11.2, S = "Pip", T = "Pero ya no puedo esperar.", To = "Yo" },
					{ At = 13.7, S = "Pip", T = "Hola, criatura.", To = "Yo" },
					{ At = 16.7, S = "Pip", T = "Perdón.", To = "Yo" },
					{ At = 19.6, S = "Pip", T = "¿Cómo ha ido tu primer día?", To = "Yo" },
					{ At = 22.3, S = "Pip", T = "Cosme estaría orgulloso.", To = "Yo" },
					{ At = 25.7, S = "Pip", T = "He encontrado algo en el garaje.", To = "Yo" },
					{ At = 29.5, S = "Pip", T = "Algo que dejó preparado antes de desaparecer.", To = "Yo" },
					{ At = 33.1, S = "Yo", T = "¿Qué?" },
					{ At = 35.1, S = "Pip", T = "No puedo decírtelo por teléfono.", To = "Yo" },
					{ At = 38.9, S = "Pip", T = "Ven cuando puedas.", To = "Yo" },
					{ At = 41.1, S = "Pip", T = "Y…", To = "Yo" },
					{ At = 44, S = "Pip", T = "Feliz primer día.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["14"] = { Effects = { Scene = "Uni01_G6_7" } } },
}
