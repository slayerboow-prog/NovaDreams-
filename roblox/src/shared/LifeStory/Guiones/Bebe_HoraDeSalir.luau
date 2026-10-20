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
			Duration = 34.9,
			Anchors = { L_CasaFamiliar = "Place:CasaFamiliar", L_HomeSalon = "Place:HomeSalon", L_Ventanal = "Place:Ventanal", Sitio = "Place:Ventanal", Yo = "Player" },
			Tracks = {
				Light = { { At = 15.5, Fade = 1, Preset = "InteriorCalido" } },
				Ambience = { { At = 0, Kind = "Casa" }, { At = 5.5, Fade = 1.2, Kind = "Calle" }, { At = 15.5, Fade = 1, Kind = "Casa" } },
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:L_HomeSalon" },
					{ At = 2.4, Duration = 2, Shot = "Reaccion:Yo" },
					{ At = 4.4, Duration = 3.8, Shot = "Pan:L_HomeSalon>L_Ventanal" },
					{ At = 8.2, Duration = 2, Shot = "Seguir:Yo" },
					{ At = 10.2, Duration = 2, Shot = "Medio:Yo" },
					{ At = 12.2, Duration = 2, Shot = "Inserto:Yo" },
					{ At = 14.2, Duration = 2, Shot = "Hombro:Yo>L_Ventanal" },
					{
						At = 16.2,
						Duration = 3,
						To = { "L_CasaFamiliar", V(25, 64, 44) },
						Cut = "Dip",
						From = { "L_CasaFamiliar", V(-45, 60, 50) },
						Look = { "L_CasaFamiliar", V(30, 0, 0) },
						Shake = 0.15,
					},
					{ At = 19.21, Duration = 2, Shot = "Dolly:L_Ventanal" },
					{
						At = 21.21,
						Duration = 8.6,
						To = { "L_CasaFamiliar", V(25, 64, 44) },
						Cut = "Dip",
						From = { "L_CasaFamiliar", V(-45, 60, 50) },
						Look = { "L_CasaFamiliar", V(30, 0, 0) },
						Shake = 0.15,
					},
					{ At = 29.83, Duration = 4.4, Shot = "PrimerPlano:Yo" },
				},
				Dialogue = {
					{ At = 4.4, S = "Narrador", T = "Hay cosas que no caben dentro de una casa." },
					{ At = 16.2, S = "Narrador", T = "Y ahí fuera… hay todo un mundo." },
					{ At = 21.2, S = "Narrador", T = "Todavía no sabes dónde vas a ir." },
					{ At = 24.3, S = "Narrador", T = "Ni a quién vas a conocer." },
					{ At = 26.9, S = "Narrador", T = "Ni en quién vas a convertirte." },
					{ At = 29.8, S = "Narrador", T = "Pero algún día… todo eso será parte de tu historia." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
	},
	Steps = {},
}
