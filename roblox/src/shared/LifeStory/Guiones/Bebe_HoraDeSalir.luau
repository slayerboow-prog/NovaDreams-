-- GUION REESCRITO de Bebe_HoraDeSalir (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Bebe_HoraDeSalir.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Bebe_HoraDeSalir
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Bebe_HoraDeSalir.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Bebe_HoraDeSalir.md",
	Scenes = {
		Bebe_VentanalFamilia = {
			Skippable = true,
			Duration = 37,
			Anchors = { L_CasaFamiliar = "Place:CasaFamiliar", L_HomeSalon = "Place:HomeSalon", L_Ventanal = "Place:Ventanal", Sitio = "Place:Ventanal", Yo = "Player" },
			Tracks = {
				Light = { { At = 15.5, Fade = 1, Preset = "InteriorCalido" } },
				Ambience = { { At = 0, Kind = "Casa" }, { At = 5.5, Fade = 1.2, Kind = "Calle" }, { At = 15.5, Fade = 1, Kind = "Casa" } },
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:L_HomeSalon" },
					{ At = 2.4, Duration = 2, Shot = "Reaccion:Yo" },
					{ At = 4.4, Duration = 3.5, Shot = "Pan:L_HomeSalon>L_Ventanal" },
					{ At = 7.86, Duration = 2, Shot = "Seguir:Yo" },
					{ At = 9.86, Duration = 2, Shot = "Medio:Yo" },
					{ At = 11.86, Duration = 2, Shot = "Inserto:Yo" },
					{ At = 13.86, Duration = 2, Shot = "Hombro:Yo>L_Ventanal" },
					{
						At = 15.86,
						Duration = 5.1,
						To = { "L_CasaFamiliar", V(25, 64, 44) },
						Cut = "Dip",
						From = { "L_CasaFamiliar", V(-45, 60, 50) },
						Look = { "L_CasaFamiliar", V(30, 0, 0) },
						Shake = 0.15,
					},
					{ At = 20.95, Duration = 2, Shot = "Dolly:L_Ventanal" },
					{
						At = 22.95,
						Duration = 8.2,
						To = { "L_CasaFamiliar", V(25, 64, 44) },
						Cut = "Dip",
						From = { "L_CasaFamiliar", V(-45, 60, 50) },
						Look = { "L_CasaFamiliar", V(30, 0, 0) },
						Shake = 0.15,
					},
					{ At = 31.19, Duration = 5.1, Shot = "PrimerPlano:Yo" },
				},
				Dialogue = {
					{ At = 4.4, S = "Narrador", T = "Hay cosas que no caben dentro de una casa." },
					{ At = 15.9, S = "Narrador", T = "Y ahí fuera…" },
					{ At = 18.8, S = "Narrador", T = "hay todo un mundo." },
					{ At = 23, S = "Narrador", T = "Todavía no sabes dónde vas a ir." },
					{ At = 25.9, S = "Narrador", T = "Ni a quién vas a conocer." },
					{ At = 28.4, S = "Narrador", T = "Ni en quién vas a convertirte." },
					{ At = 31.2, S = "Narrador", T = "Pero algún día…" },
					{ At = 33.2, S = "Narrador", T = "todo eso será parte de tu historia." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
	},
	Steps = {},
}
