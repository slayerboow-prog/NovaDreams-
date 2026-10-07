-- GUION REESCRITO de Saga_06_Coser (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_06_Coser.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_06_Coser
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_06_Coser.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_06_Coser.md",
	Dialogues = {
		Plan = {
			Lines = {
				{ S = "Cosme", T = "Mi obra maestra. Bueno.", To = "Yo" },
				{ S = "Cosme", T = "La segunda fue un peine que peina hacia el pasado. No preguntes.", To = "Yo" },
				{ S = "Pip", T = "Funcionaba demasiado bien.", To = "Yo" },
				{ S = "Cosme", T = "Tres anclajes. Y esto…", To = "Yo" },
				{ S = "Yo", T = "¿Como un botón?" },
				{ S = "Cosme", T = "Exacto.", To = "Yo" },
				{ S = "DonEscamas", T = "El Consorcio ya sabe lo que vas a hacer.", To = "Yo", If = { Flags = { "ConoceConsorcio" } } },
				{ S = "DonEscamas", T = "Tienen agentes vigilando el parque y la plaza.", To = "Yo", If = { Flags = { "ConoceConsorcio" } } },
				{ S = "DonEscamas", T = "He calculado sus rutas.", To = "Yo", Pause = 0.9, If = { Flags = { "ConoceConsorcio" } } },
				{ S = "DonEscamas", T = "Si no te ven, no te ven.", To = "Yo", If = { Flags = { "ConoceConsorcio" } } },
				{ S = "DonEscamas", T = "Es contabilidad básica.", To = "Yo", Pause = 0.9, If = { Flags = { "ConoceConsorcio" } } },
				{
					Ask = "Antes de salir, le preguntas a Cosme:",
					Options = {
						{
							T = "«¿Quién es Cósimo de verdad?»",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Cosme", T = "Mi mejor amigo. Construimos juntos la máquina que abrió esto.", To = "Yo" },
								{ S = "Cosme", T = "Y él cayó al otro lado. Por mi culpa. O por la suya.", To = "Yo", Pause = 0.9 },
								{ S = "Cosme", T = "Llevo años sin saberlo.", To = "Yo" },
							},
						},
						{
							T = "«¿Por qué la Grieta tira hacia mí?»",
							Effects = { Traits = { Valentia = 1 } },
							Then = {
								{ S = "Cosme", T = "Porque eres importante. Para mí, desde luego. Para el universo… Un poquito también.", To = "Yo" },
								{ S = "Cosme", T = "Y no le hagas demasiado caso al pez cuando habla de anclas.", To = "Yo", If = { Flags = { "OyoAncla" } } },
								{ S = "DonEscamas", T = "¡Soy un profesional!", To = "Yo", If = { Flags = { "OyoAncla" } } },
								{ S = "Cosme", T = "Eres un pez.", To = "Yo", If = { Flags = { "OyoAncla" } } },
							},
						},
					},
				},
				{ S = "Cosme", T = "Esta noche cerramos la Grieta.", To = "Yo" },
				{ S = "Cosme", T = "Y esta vez no voy a dejar que nadie salga herido. Ni tú.", To = "Yo" },
			},
		},
		Voz = {
			Lines = {
				{ S = "Cosme", T = "¡LO HEMOS HECHO! ¡Cosido! ¡Como un calcetín!", To = "Yo" },
				{ S = "Pip", T = "Comparación técnicamente incorrecta.", To = "Yo" },
				{ S = "Cosme", T = "¡Somos unos genios! Tú eres un genio en miniatura. Yo soy uno grande.", To = "Yo" },
				{ S = "Pip", T = "Señor Cosme… Tenemos una transmisión.", To = "Yo" },
				{ S = "Cosimo", T = "Bravo, Cosme. Precioso trabajo de costura.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "Siempre fuiste el de las manualidades. Y tú… Hola.", To = "Yo", Pause = 0.9 },
				{ S = "Cosimo", T = "Por fin puedo verte la cara. Qué grande estás.", To = "Yo" },
				{ S = "Cosimo", T = "La última vez eras así de pequeñ{o/a}. Ya te he encontrado.", To = "Yo", Pause = 0.9 },
				{
					S = "Cosimo",
					T = "El tornillo luminoso también. Tres objetos. Nos veremos pronto. Las costuras… …siempre se sueltan.",
					To = "Yo",
					Pause = 0.9,
				},
				{ S = "Cosme", T = "Está completamente pálido.", To = "Yo" },
				{ S = "Pip", T = "Señor.", To = "Yo" },
				{ S = "Cosme", T = "Algún día, Pip. No hoy.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Hoy hemos cosido el cielo. Hoy… …a cenar. Te la quedas.", To = "Yo" },
				{ S = "Cosme", T = "Tú la has hecho funcionar. Siempre has sido tú.", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Mission = { Set = { MomentKey = "Cosiste el cielo de Valmar." } },
	Scenes = {
		Saga_06_G3_Entra = {
			Light = true,
			Duration = 19.5,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Cosme", Npc = "Cosme" } }, { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{ At = 0.4, S = "Cosme", T = "Solo falta activarla.", To = "Yo" },
					{ At = 2.7, S = "Pip", T = "Tenemos compañía. Dos agentes aparecen.", To = "Yo" },
					{ At = 6, S = "Pip", T = "No quieren detenernos.", To = "Yo" },
					{ At = 9.3, S = "Pip", T = "Quieren informar de nuestra posición.", To = "Yo" },
					{ At = 13.3, S = "Pip", T = "Control rutinario. Gracias por colaborar.", To = "Yo" },
					{ At = 16.8, S = "Yo", T = "No." },
				},
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Saga_06_G3_Entra" }, Set = { Text = "colocar los tres anclajes en Valmar." } } },
}
