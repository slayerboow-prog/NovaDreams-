-- GUION REESCRITO de Adulto_PrimerSueldo (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Adulto_PrimerSueldo.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Adulto_PrimerSueldo
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Adulto_PrimerSueldo.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Adulto_PrimerSueldo.md",
	Scenes = {
		Adulto_Sueldo_G1_Fin = {
			Light = true,
			Duration = 23.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Lola", Npc = "Lola" } }, { At = 0, Use = { Key = "Ernesto", Npc = "Ernesto" } } },
				Dialogue = {
					{ At = 0.4, S = "Ernesto", T = "Primer día.", To = "Yo" },
					{ At = 2.4, S = "Ernesto", T = "Muy bien.", To = "Yo" },
					{ At = 5.4, S = "Ernesto", T = "Mañana será más difícil.", To = "Yo" },
					{ At = 7.9, S = "Ernesto", T = "Eso significa que vas bien.", To = "Yo" },
					{ At = 10.5, S = "Lola", T = "¿Y esto?", To = "Yo" },
					{ At = 12.6, S = "Yo", T = "Mi primer sueldo." },
					{ At = 14.6, S = "Lola", T = "Entonces hoy invito yo.", To = "Yo" },
					{ At = 17.1, S = "Lola", T = "Guárdalo.", To = "Yo" },
					{ At = 20, S = "Lola", T = "Los primeros sueldos se recuerdan.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Adulto_Sueldo_G1_Fin" } } },
}
