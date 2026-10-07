-- GUION REESCRITO de Adulto_MirarAtras (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Adulto_MirarAtras.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Adulto_MirarAtras
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Adulto_MirarAtras.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Adulto_MirarAtras.md",
	Scenes = {
		Vida_G3_Entra = {
			Light = true,
			Duration = 10.3,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Toda una vida en Valmar." },
					{ At = 3.8, S = "Narrador", T = "Y la historia sigue." },
					{ At = 6.9, S = "Narrador", T = "Porque la ciudad no se para." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Vida_G3_Entra" } } },
}
