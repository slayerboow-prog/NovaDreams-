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
			Duration = 20.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Lola", Npc = "Lola" } }, { At = 0, Use = { Key = "Ernesto", Npc = "Ernesto" } } },
				Dialogue = {
					{ At = 0.4, S = "Ernesto", T = "Primer día. Muy bien. Mañana será más difícil.", To = "Yo" },
					{ At = 4.5, S = "Ernesto", T = "Eso significa que vas bien.", To = "Yo" },
					{ At = 7.2, S = "Lola", T = "¿Y esto?", To = "Yo" },
					{ At = 9.7, S = "Yo", T = "Mi primer sueldo." },
					{ At = 12.2, S = "Lola", T = "Entonces hoy invito yo. Guárdalo.", To = "Yo" },
					{ At = 16.3, S = "Lola", T = "Los primeros sueldos se recuerdan.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Adulto_Sueldo_G1_Fin" } } },
}
