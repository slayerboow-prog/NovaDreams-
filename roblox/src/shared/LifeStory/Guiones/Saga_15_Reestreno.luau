-- GUION REESCRITO de Saga_15_Reestreno (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_15_Reestreno.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_15_Reestreno
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_15_Reestreno.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_15_Reestreno.md",
	Dialogues = {
		Capitana = {
			Lines = {
				{
					S = "CapitanNoz",
					T = "Volvemos a vernos. La última vez saliste corriendo de este monte. Hoy vienes a buscarme. Interesante.",
					To = "Yo",
					If = { Completed = { "Loco_U1_Monte" } },
				},
				{
					S = "CapitanNoz",
					T = "Me han dicho que buscas algo. Mi nave ve a través de las grietas. Todo lo que pasa en cualquier dimensión, lo veo.",
					To = "Yo",
					If = { Completed = { "Loco_U1_Monte" } },
				},
				{
					S = "CapitanNoz",
					T = "¿El laboratorio del doctor Cósimo? Lo tengo. Con imagen y sonido.",
					To = "Yo",
					If = { Completed = { "Loco_U1_Monte" } },
				},
				{
					S = "CapitanNoz",
					T = "Pero no regalo nada. Mis sensores fallan cerca de la 66-B. Tú eres el Ancla: tu resonancia los puede afinar.",
					To = "Yo",
					If = { Completed = { "Loco_U1_Monte" } },
				},
				{ S = "Sorel", T = "¿Y qué le pasa a quien hace de antena?", To = "Yo", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Le duele un poco la cabeza. Nada más. Casi siempre.", To = "Yo", If = { Completed = { "Loco_U1_Monte" } } },
			},
		},
		Grabacion = {
			Lines = {
				{
					S = "CapitanNoz",
					T = "Señal limpia. Hacía años que no veía la 66-B tan clara. Aquí lo tienes.",
					To = "Yo",
					If = { Flags = { "Saga_15_P2_Gana" } },
				},
				{
					S = "Narrador",
					T = "En la pantalla: un laboratorio enorme bajo un campus. Hileras de cápsulas de cristal.",
					If = { Flags = { "Saga_15_P2_Gana" } },
				},
				{
					S = "Narrador",
					T = "En una de ellas, dormido, está Cosme. Respira. Tiene cables conectados a la cabeza.",
					If = { Flags = { "Saga_15_P2_Gana" } },
				},
				{ S = "Brenn", T = "Está vivo. Eso es lo que importa.", To = "Yo", If = { Flags = { "Saga_15_P2_Gana" } } },
				{ S = "Sorel", T = "¿Para qué le tienen conectado?", To = "Yo", If = { Flags = { "Saga_15_P2_Gana" } } },
				{
					S = "Pip",
					T = "Están leyendo lo que sabe. Todo lo que él y Lía averiguaron sobre la Grieta.",
					To = "Yo",
					If = { Flags = { "Saga_15_P2_Gana" } },
				},
				{
					S = "CapitanNoz",
					T = "Te dejo mi frecuencia. Si salís vivos de allí, avísame. Esa historia también valdrá mucho.",
					To = "Yo",
					If = { Flags = { "Saga_15_P2_Gana" } },
				},
			},
		},
	},
	Scenes = {
		Saga_15_G2_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "CapitanNoz", Npc = "CapitanNoz" } } },
				Dialogue = { { At = 0.4, S = "CapitanNoz", T = "Pon la mano en el panel. Cuando la luz se ponga roja, empuja con todo lo que tengas.", To = "Yo" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Saga_15_G2_Entra" } },
		["2"] = { Set = { Win = { Flags = { "BuenRodaje", "Saga_15_P2_Gana" }, Traits = { Valentia = 1 } } } },
	},
}
