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
			Duration = 39.1,
			Anchors = { Sitio = "Place:HabitacionResidencia", Yo = "Player" },
			Tracks = {
				Light = { { At = 0, Fade = 1.5, Preset = "Noche" } },
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Ambience = { { At = 0, Fade = 1.5, Kind = "Interior" } },
				Camera = { { At = 0, Duration = 39.1, To = { "Sitio", V(-14, 12, 18) }, Fov = 60, From = { "Sitio", V(-26, 18, 30) }, Look = { "Sitio", V(0, 2, 0) } } },
				Dialogue = {
					{ At = 0.4, S = "Pip", T = "Necesito hablar contigo. Segundo mensaje. Es sobre Cosme.", To = "Yo" },
					{ At = 5.3, S = "Pip", T = "No quería hacerlo durante tu graduación.", To = "Yo" },
					{ At = 9.8, S = "Pip", T = "Pero ya no puedo esperar.", To = "Yo" },
					{ At = 12.4, S = "Pip", T = "Hola, criatura. Perdón.", To = "Yo" },
					{ At = 15.8, S = "Pip", T = "¿Cómo ha ido tu primer día?", To = "Yo" },
					{ At = 18.5, S = "Pip", T = "Cosme estaría orgulloso.", To = "Yo" },
					{ At = 22, S = "Pip", T = "He encontrado algo en el garaje.", To = "Yo" },
					{ At = 25.9, S = "Pip", T = "Algo que dejó preparado antes de desaparecer.", To = "Yo" },
					{ At = 30, S = "Yo", T = "¿Qué?" },
					{ At = 32.5, S = "Pip", T = "No puedo decírtelo por teléfono. Ven cuando puedas. Y… Feliz primer día.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["14"] = { Effects = { Scene = "Uni01_G6_7" } } },
}
