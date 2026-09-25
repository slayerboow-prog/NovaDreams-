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
	{
		Id = "Eco_Carta",
		Kind = "Side",
		Title = "Una carta",
		Description = "Te ha llegado una carta de tu primer trabajo.",
		Type = "Consecuencia (3 h después de «El primer empleo», si no mentiste en la entrevista)",
		Duration = { 2, 3 },
		Npcs = { "Familia" },
		Requires = { Stage = { Min = "Adolescente", Max = "AdultoJoven" } },
		Moment = "Tu primera carta de recomendación",
		Steps = {
			{ Type = "Talk", Npc = "Familia", Dialogue = "Carta", Text = "{familia} tiene una carta para ti",
				Actors = { { Npc = "Familia", Place = "CercaDeTi", Offset = V(0, 0, -5), Mode = "Wave" } } },
		},
		Dialogues = {
			Carta = { Lines = {
				{ S = "Familia", T = "Ha llegado esto. A tu nombre. Con sello de verdad. ¿Quién escribe cartas hoy en día?" },
				{ S = "Narrador", T = "«A quien corresponda: {nombre} trabajó con nosotros un verano. Puntual, honesto y con ganas de aprender. Lo contrataría otra vez.» Firma: Lola.", If = { Choices = { Empleo = "Barista" } } },
				{ S = "Narrador", T = "«A quien corresponda: {nombre} trabajó en este supermercado. Ni una caja mal puesta. Hmm. Recomendable.» Firma: Paco.", If = { Choices = { Empleo = "Reponedor" } } },
				{ S = "Narrador", T = "«A quien corresponda: {nombre} repartió en Valmar todo un verano. Ni un paquete perdido. El perro del 14 lo echa de menos.» Firma: Ernesto.", If = { Choices = { Empleo = "Repartidor" } } },
				{ S = "Familia", T = "Guárdala bien. Algún día, en tu primer trabajo de verdad, esto valdrá oro." },
			}, Effects = { Items = { CartaRecomendacion = 1 }, Traits = { Responsabilidad = 1 } } },
		},
	},

	{
		Id = "Eco_Nico",
		Kind = "Side",
		Title = "Nico",
		Description = "Nico quiere hablar contigo.",
		Type = "Consecuencia (3 h después de «El rumor»)",
		Duration = { 2, 4 },
		Npcs = { "Nico" },
		Requires = { Stage = { Min = "Adolescente", Max = "AdultoJoven" } },
		Moment = "Nico y tú, después del rumor",
		Steps = {
			{ Type = "Talk", Npc = "Nico", Dialogue = "Vuelve", Text = "Nico te está buscando",
				Actors = { { Npc = "Nico", Place = "CercaDeTi", Offset = V(0, 0, -5), Mode = "Wave" } } },
		},
		Dialogues = {
			Vuelve = { Lines = {
				{ S = "Nico", T = "Oye. Lo del otro día. Que me lo dijeras aparte… Me hiciste pensar sin hacerme quedar mal. Eso es de amigo de verdad.", If = { Choices = { HablasNico = "Privado" } } },
				{ S = "Nico", T = "Me he pasado días enfadado contigo por lo de delante del equipo. Pero tenías razón. Solo… la próxima vez, primero a mí, ¿vale?", If = { Choices = { HablasNico = "Publico" } } },
				{ S = "Nico", T = "He dejado de ir con Darío. No es mala persona, pero conmigo saca lo peor. Con vosotros, lo mejor." },
				{ S = "Nico", T = "Omar y yo hemos quedado el sábado. Me toca pagar el primero de los diez bocadillos. ¿Te vienes a verlo sufrir?" },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«No me lo pierdo.»", Effects = { Rel = { Nico = 6, Omar = 3 } }, Then = {
						{ S = "Nico", T = "¡Genial! Como en el colegio. Como siempre." },
					} },
					{ T = "«Me alegro de que lo hayáis arreglado.»", Effects = { Rel = { Nico = 4 } }, Then = {
						{ S = "Nico", T = "Yo también. Me alegro mucho. Casi tanto como de meter un gol." },
					} },
				} },
			} },
		},
	},
}
