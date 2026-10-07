-- GUION REESCRITO de Saga_13_SinCosme (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_13_SinCosme.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_13_SinCosme
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_13_SinCosme.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_13_SinCosme.md",
	Dialogues = {
		Cuaderno = {
			Lines = {
				{ S = "Pip", T = "Técnicamente…", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Ya no está.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "No tiene llave.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Tú.", To = "Yo" },
			},
		},
		Mando = {
			Lines = {
				{ S = "Pip", T = "¿Quieres que la lea yo?", To = "Yo" },
				{ S = "Yo", T = "Léela." },
				{ S = "Yo", T = "La leeré yo." },
				{ S = "Yo", T = "No hay respuesta incorrecta." },
				{ S = "Pip", T = "No dejó instrucciones sobre cómo encontrarlo.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Dejó instrucciones sobre cómo empezar.", To = "Yo", Pause = 0.9 },
			},
		},
		Pip = {
			Lines = {
				{ S = "Pip", T = "No entra corriendo.", To = "Yo" },
				{ S = "Pip", T = "Hola, criatura.", To = "Yo" },
				{ S = "Pip", T = "No sabía cómo recibirte.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Yo tampoco.", To = "Yo" },
				{ S = "Pip", T = "Cosme siempre decía que las malas noticias debían servirse con algo dulce.", To = "Yo" },
				{ S = "Pip", T = "No dejó dulces.", To = "Yo" },
			},
		},
		Plan = {
			Lines = {
				{ S = "Pip", T = "Cosme dijo que siguieras las costuras.", To = "Yo" },
				{ S = "Pip", T = "Creo que acabamos de encontrar una.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Ese día…", To = "Yo" },
				{ S = "Pip", T = "Cosme sabía que volverías aquí.", To = "Yo", Pause = 1.8 },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
