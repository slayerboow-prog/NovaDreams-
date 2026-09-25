-- Consecuencias del instituto: misiones pequeñas que nacen de lo que hiciste (Later), horas después.

local V = Vector3.new

return {
	{
		Id = "Eco_Leire",
		Kind = "Side",
		Title = "Leire",
		Description = "Leire tiene algo para ti.",
		Type = "Consecuencia (2 h después de «El nuevo instituto», si te acercaste a Leire)",
		Duration = { 2, 4 },
		Npcs = { "Leire" },
		Requires = { Stage = { Min = "Adolescente", Max = "Adolescente" } },
		Moment = "Leire te regaló una foto",
		Steps = {
			{ Type = "Talk", Npc = "Leire", Dialogue = "Foto", Text = "Leire te está buscando",
				Actors = { { Npc = "Leire", Place = "CercaDeTi", Offset = V(0, 0, -5), Mode = "Wave" } } },
		},
		Dialogues = {
			Foto = { Lines = {
				{ S = "Leire", T = "Eh. Toma. He revelado el carrete. Te hice una foto el primer día sin que te dieras cuenta. Perdón. Bueno, no mucho." },
				{ S = "Narrador", T = "Es una foto en blanco y negro: tú, en el primer día de instituto, mirando el edificio con cara de «¿dónde me he metido?»." },
				{ S = "Leire", T = "El primer día pensé que aquí no iba a tener a nadie. Y viniste tú. Eso no se me va a olvidar." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«La guardo. Y la próxima, nos hacemos una juntos.»", Effects = { Rel = { Leire = 8 } }, Then = {
						{ S = "Leire", T = "Regla del club: nada de fotos de uno mismo. …Pero por una vez, vale." },
					} },
					{ T = "«¡Salgo fatal!»", Effects = { Rel = { Leire = 5 }, Traits = { Humor = 1 } }, Then = {
						{ S = "Leire", T = "Sales como eres. Eso nunca es salir fatal." },
					} },
				} },
			}, Effects = { Items = { FotoDeLeire = 1 } } },
		},
	},

	{
		Id = "Eco_LeireSola",
		Kind = "Side",
		Title = "La chica nueva",
		Description = "Leire sigue comiendo sola.",
		Type = "Consecuencia (2 h después de «El nuevo instituto», si no te acercaste)",
		Duration = { 2, 4 },
		Npcs = { "Leire" },
		Requires = { Stage = { Min = "Adolescente", Max = "Adolescente" } },
		Moment = "Una segunda oportunidad con Leire",
		Steps = {
			{ Type = "Talk", Npc = "Leire", Dialogue = "Sola", Text = "Leire está sola otra vez. ¿Esta vez te acercas?",
				Actors = { { Npc = "Leire", Place = "CercaDeTi", Offset = V(0, 0, -6), Mode = "Sit" } },
				Timeout = { After = 90, OnlyIfUntouched = true, Rel = { Leire = -3 } } },
		},
		Dialogues = {
			Sola = { Lines = {
				{ S = "Leire", T = "¿Tú otra vez? El primer día pasaste de largo. No pasa nada. Todo el mundo pasa de largo." },
				{ S = "Leire", T = "…Vale, sí pasa. Un poco." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Tienes razón. Lo siento. ¿Empezamos otra vez?»", Effects = { Flags = { "ConocesALeire" }, Rel = { Leire = 10 }, Traits = { Empatia = 1 } }, Then = {
						{ S = "Leire", T = "…Vale. Soy Leire. Vengo del norte. Hago fotos. Y no me gusta que me pregunten por la cámara." },
					} },
					{ T = "«Omar trae aceitunas. ¿Te vienes?»", Effects = { Flags = { "ConocesALeire" }, Rel = { Leire = 8, Omar = 2 } }, Then = {
						{ S = "Leire", T = "¿Aceitunas? …Eso ya es otra cosa." },
					} },
				} },
			} },
		},
	},
}
