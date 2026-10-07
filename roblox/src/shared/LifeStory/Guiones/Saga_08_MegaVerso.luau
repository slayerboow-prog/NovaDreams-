-- GUION REESCRITO de Saga_08_MegaVerso (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_08_MegaVerso.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_08_MegaVerso
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_08_MegaVerso.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_08_MegaVerso.md",
	Dialogues = {
		Folleto = {
			Lines = {
				{ S = "Narrador", T = "El folleto parece una publicidad normal." },
				{ S = "Narrador", T = "Hasta que lees la letra pequeña.", Pause = 0.9 },
				{ S = "Narrador", T = "No es una empresa que quiera venderte una casa." },
				{ S = "Narrador", T = "Quiere quedarse con el lugar donde está tu casa.", Pause = 0.9 },
			},
		},
		Fuera = {
			Lines = {
				{ S = "Narrador", T = "Has salido. Pero no has salido solo." },
				{ S = "Narrador", T = "Solo estuvo ahí un segundo." },
				{ S = "Narrador", T = "Pero sabía que estabas dentro.", Pause = 0.9 },
				{ S = "Narrador", T = "MegaVerso no está intentando encontrar la Grieta. Ya la encontró." },
				{ S = "Narrador", T = "Y parece saber exactamente dónde estás tú." },
				{ S = "Narrador", T = "Pero cuando escucha: «Cosme»" },
			},
		},
		Mapa = { Lines = { { S = "Narrador", T = "Tres lugares. Tus anclajes." } } },
		Ordenador = { Lines = { { S = "Yo", T = "Mi graduación. Hablan de mi graduación.", Pause = 0.9 } } },
		Recepcion = {
			Lines = {
				{ S = "Narrador", T = "El edificio no estaba aquí la última vez." },
				{ S = "Narrador", T = "Pero parece llevar años aquí.", Pause = 0.9 },
				{ S = "AgenteGris2", T = "¡Bienvenid{o/a} a MegaVerso S.A.!", To = "Yo" },
				{ S = "AgenteGris2", T = "¿Viene por las vacaciones dimensionales?", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "¿Por la tarjeta de fidelización?", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "¿O por la Gran Fusión? ¡Qué adorable! Sírvase usted mismo.", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "Las cámaras solo graban a los adultos.", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "Es nuestra política de privacidad. Laboratorio… Cosme.", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "Un momento, por favor.", To = "Yo", Pause = 0.9 },
				{ S = "AgenteGris2", T = "Voy a consultar con mi…", To = "Yo" },
				{ S = "AgenteGris2", T = "…con la máquina de café. Sírvase usted mismo.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Vengo a informarme. Soy de un colegio. Trabajo de clase.»",
							Effects = { Traits = { Humor = 1 } },
							Then = {
								{
									S = "AgenteGris2",
									T = "¡Qué adorable! Sírvase usted mismo. Las cámaras solo graban a los adultos. Es nuestra política de privacidad.",
								},
							},
						},
						{
							T = "Enseñas la credencial de ayudante de Cosme",
							Effects = { Flags = { "EnseñasteCredencial" }, Traits = { Valentia = 1 } },
							Then = {
								{
									S = "AgenteGris2",
									T = "¿Laboratorio… Cosme? …Un momento, por favor. Voy a consultar con mi… con la máquina de café. Sírvase usted mismo.",
								},
							},
						},
					},
				},
			},
		},
	},
	Scenes = {
		Saga_08_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "AgenteGris2", Npc = "AgenteGris2" } } },
				Dialogue = { { At = 2.2, S = "AgenteGris2", T = "Que no salga. Dos segundos. Por favor.", To = "Yo" } },
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Saga_08_G3_Entra" } } },
}
