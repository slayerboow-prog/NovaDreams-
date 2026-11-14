-- GUION REESCRITO de Deriva_01_Misericordia (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Deriva_01_Misericordia.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Deriva_01_Misericordia
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Deriva_01_Misericordia.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Deriva_01_Misericordia.md",
	Scenes = {
		Deriva1_G1_Entra = {
			Light = true,
			Duration = 23,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
					{ At = 0, Use = { Key = "Pip", Npc = "Pip" } },
					{ At = 0, Use = { Key = "NILDA", Npc = "NILDA" } },
				},
				Dialogue = {
					{
						At = 0.4,
						S = "NILDA",
						T = "Ahí está. La Misericordia. Sin motores, sin luces… y con la baliza médica encendida.",
						To = "Yo",
						G = "Point",
					},
					{
						At = 7.2,
						S = "Cosme",
						T = "Las balizas no se encienden solas, criatura. Alguien quiere que la encontremos. O alguien quiere ver quién viene.",
						To = "Yo",
						A = "HandsOnHips",
					},
					{ At = 16.1, S = "Pip", T = "Señor, en la Deriva las cosas sí se encienden solas. Por eso no viene nadie.", To = "Yo", A = "ArmsCrossed" },
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
		Deriva1_G2_Entra = {
			Light = true,
			Duration = 16.4,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "NILDA", Npc = "NILDA" } }, { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = {
					{
						At = 0.4,
						S = "NILDA",
						T = "Corriente al cien por cien. El sistema de seguridad se ha reiniciado. La puerta del puente está abierta.",
						To = "Yo",
						A = "ThinkChin",
					},
					{
						At = 8.6,
						S = "Cosme",
						T = "Ve despacio. Lo que haya en ese puente lleva dos años esperando a que alguien lo escuche.",
						To = "Yo",
						G = "Point",
					},
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
		},
		Deriva1_G3_Entra = {
			Light = true,
			Duration = 14.1,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } }, { At = 0, Use = { Key = "NILDA", Npc = "NILDA" } } },
				Dialogue = {
					{
						At = 0.4,
						S = "Cosme",
						T = "Lo tienes. Sal de ahí ya. No me gusta que estés tanto tiempo en una nave que huele a cerrado.",
						To = "Yo",
						A = "Happy",
						Mood = "Joy",
					},
					{ At = 7.8, S = "NILDA", T = "El núcleo guarda la grabación del atraque. Tres letras. No es mucho.", To = "Yo", A = "Nod" },
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
		Deriva1_G4_Entra = {
			Light = true,
			Duration = 14.1,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "NILDA", Npc = "NILDA" } }, { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = {
					{ At = 0.4, S = "NILDA", T = "Contactos. Tres. Estaban parados detrás del casco, esperando a que salieras.", To = "Yo", A = "ThinkChin" },
					{ At = 6.6, S = "Cosme", T = "Hilanderos. No han venido a por ti: han venido a por el núcleo. Que no se lo lleven.", To = "Yo", A = "Lean" },
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
		Deriva1_G5_Entra = {
			Light = true,
			Duration = 14.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } }, { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } } },
				Dialogue = {
					{ At = 0.4, S = "Pip", T = "Señor, no estaban aquí por casualidad. Sabían que alguien iba a entrar hoy.", To = "Yo", A = "Shrug" },
					{
						At = 6.6,
						S = "Cosme",
						T = "Entonces alguien les avisó. Lleva el núcleo a Alba. Y de esto, ni una palabra a nadie de Cénit.",
						To = "Yo",
						A = "HandsOnHips",
					},
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Deriva1_G1_Entra" } },
		["4"] = { Effects = { Scene = "Deriva1_G2_Entra" } },
		["7"] = { Effects = { Scene = "Deriva1_G3_Entra" } },
		["8"] = { Effects = { Scene = "Deriva1_G4_Entra" } },
		["9"] = { Effects = { Scene = "Deriva1_G5_Entra" } },
	},
}
