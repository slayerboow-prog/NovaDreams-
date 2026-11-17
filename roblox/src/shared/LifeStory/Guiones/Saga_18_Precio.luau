-- GUION REESCRITO de Saga_18_Precio (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_18_Precio.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_18_Precio
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_18_Precio.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_18_Precio.md",
	Dialogues = {
		Anuncio = {
			Lines = {
				{ S = "Cosimo", T = "Buenas noches, Valmar. Tengo un anuncio.", To = "Yo" },
				{
					S = "Cosimo",
					T = "La Gran Fusión se hará en el Monte del Silencio. Vuestra ciudad y la mía serán una sola. Sin más Caídas. Sin más bestias.",
					To = "Yo",
				},
				{ S = "Cosimo", T = "Solo falta una cosa: que el Ancla se canse de sujetar. Y todo el mundo se cansa. Es cuestión de tiempo.", To = "Yo" },
				{ S = "Cosimo", T = "Os espero. A todos.", To = "Yo" },
				{ S = "Pip", T = "Nos da tiempo. No sabemos cuánto, pero nos da tiempo.", To = "Yo" },
				{ S = "Pip", T = "Tiempo para que el doctor recupere la memoria. Y para prepararnos.", To = "Yo" },
			},
		},
		Nombre = {
			Lines = {
				{ S = "Cosme", T = "No sé quién eres. Pero cuando entras en este garaje, me siento menos perdido.", To = "Yo" },
				{ S = "Cosme", T = "Tengo un hueco aquí dentro. Muy grande. Cuando te miro, el hueco se hace más pequeñ{o/a}.", To = "Yo" },
				{ S = "Narrador", T = "Sorel os hace una foto: Cosme en la puerta del garaje, sin entender del todo, y tú a su lado." },
				{ S = "Narrador", T = "FIN DEL ACTO III. Cosme ha vuelto, pero sin sus recuerdos. Y la Gran Fusión tiene fecha." },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "Le cuentas cómo os conocisteis: el detector y las tres piezas",
							Effects = { Rel = { Cosme = 6 }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Cosme", T = "Un detector que reventó… y alguien que vino a ayudar sin preguntar. Eso me suena. No sé por qué, pero me suena." } },
						},
						{
							T = "Le dices tu nombre y le das la mano",
							Effects = { Rel = { Cosme = 8 }, Traits = { Empatia = 2 } },
							Then = { { S = "Cosme", T = "{nombre}… {nombre}. Eso sí lo sé. No sé nada más. Pero eso lo sé." } },
						},
					},
				},
			},
		},
	},
	Scenes = {},
	Steps = {},
}
