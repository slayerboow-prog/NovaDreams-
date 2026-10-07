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
				{ S = "Pip", T = "Técnicamente… Ya no está. No tiene llave. Tú.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Sabía que funcionaría.", To = "Yo" },
				{ S = "Pip", T = "Y esperaba equivocarme.", To = "Yo", Pause = 0.9 },
			},
		},
		Mando = {
			Lines = {
				{ S = "Pip", T = "¿Quieres que la lea yo?", To = "Yo" },
				{ S = "Yo", T = "Léela. La leeré yo. No hay respuesta incorrecta." },
				{ S = "Pip", T = "No dejó instrucciones sobre cómo encontrarlo.", To = "Yo", Pause = 0.9 },
				{ S = "Pip", T = "Dejó instrucciones sobre cómo empezar.", To = "Yo", Pause = 0.9 },
			},
		},
		Pip = {
			Lines = {
				{ S = "Pip", T = "Hola, criatura. No sabía cómo recibirte. Yo tampoco.", To = "Yo" },
				{ S = "Pip", T = "Cosme siempre decía que las malas noticias debían servirse con algo dulce. No dejó dulces.", To = "Yo" },
				{
					S = "Pip",
					T = "Desde su graduación, aquí no huele a batido de apio. Nunca pensé que lo echaría de menos.",
					If = { Memories = { "GraduacionInterdimensional" } },
				},
				{
					S = "DonEscamas",
					T = "Tú me sacaste de un estanque en un cubo. Ahora me toca a mí sacar a alguien. Aunque sea desde una pecera.",
					If = { Memories = { "DonEscamas" } },
				},
				{
					S = "Pip",
					T = "Además, usted es ayudante oficial. Lo pone la credencial. Eso le convierte en jefe en funciones.",
					G = "Nod",
					If = { Flags = { "AyudanteOficial" } },
				},
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
