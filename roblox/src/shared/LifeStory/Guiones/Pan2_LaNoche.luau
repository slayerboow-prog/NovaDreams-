-- GUION REESCRITO de Pan2_LaNoche (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Pan2_LaNoche.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Pan2_LaNoche
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Pan2_LaNoche.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Pan2_LaNoche.md",
	Dialogues = {
		Almacen = {
			Lines = {
				{ S = "Rayo", T = "¿Sabes qué es lo mejor de los sábados? Que no hay clase.", To = "Yo" },
				{ S = "Nerea", T = "Muy profundo.", To = "Yo" },
				{ S = "Rayo", T = "El súper de Paco cierra a las diez.", To = "Yo" },
				{ S = "Rayo", T = "La puerta del almacén no cierra bien. Entramos. Cogemos unas latas. Unas chuches. Y nos vamos.", To = "Yo", Pause = 0.9 },
				{ S = "Rayo", T = "Cinco minutos.", To = "Yo", Pause = 0.9 },
				{ S = "Nerea", T = "Eso es robar.", To = "Yo" },
				{ S = "Rayo", T = "No. Es coger unas cosas.", To = "Yo" },
				{ S = "Nerea", T = "Que tengan otro nombre no cambia lo que es.", To = "Yo" },
				{ S = "Rayo", T = "Paco tiene de sobra. Nadie se va a enterar.", To = "Yo", Pause = 0.9 },
				{ S = "Rayo", T = "Tú ya eres de los nuestros.", To = "Yo", If = { Flags = { "Pintada" } } },
				{ S = "Rayo", T = "Lo del muro fue el primer paso. Esto es el segundo.", To = "Yo", Pause = 0.9, If = { Flags = { "Pintada" } } },
				{ S = "Yo", T = "Voy." },
				{ S = "Rayo", T = "Eso quería oír. A las diez y media. Detrás del súper.", To = "Yo" },
				{ S = "Yo", T = "Paso. Esto ya no es una tontería." },
				{ S = "Rayo", T = "Tú sabrás. Luego no me vengas con que te aburres.", To = "Yo" },
				{ S = "Yo", T = "No lo hagáis. Os van a pillar. Nerea, tú tampoco." },
				{ S = "Rayo", T = "¿Ahora eres su madre? Nerea hace lo que quiere. ¿Verdad?", To = "Yo" },
				{ S = "Nerea", T = "Esta vez me quedo en casa. Lo siento, Rayo.", To = "Yo", If = { Flags = { "AmigaNerea" } } },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "Coges unas latas y unas chuches",
							Effects = { Flags = { "Hurto" }, Rel = { Rayo = 4 }, Traits = { Rebeldia = 2 } },
							Then = { { S = "Rayo", T = "¡Eso es! ¡Vámonos!" } },
						},
						{
							T = "Lo dejas todo en su sitio y te vas",
							Effects = { Flags = { "TeFuiste" }, Rel = { Nerea = 5, Rayo = -5 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Narrador", T = "Das media vuelta y sales. Rayo te llama algo desde dentro. No lo oyes. No quieres oírlo." },
								{ S = "Nerea", T = "(te alcanza en la calle) Espera. Yo tampoco quería. Me voy contigo." },
							},
						},
					},
				},
			},
		},
		Lunes = {
			Lines = {
				{ S = "Ines", T = "Hola otra vez. Nos conocimos durante la semana de las profesiones.", To = "Yo", If = { Flags = { "Interes_Derecho" } } },
				{ S = "Ines", T = "No pensaba que volveríamos a vernos así.", To = "Yo", If = { Flags = { "Interes_Derecho" } } },
				{ S = "Ines", T = "Tranquilidad. Nadie va a ir a la cárcel por unas latas.", To = "Yo" },
				{ S = "Ines", T = "Pero esto sí tiene consecuencias.", To = "Yo" },
				{ S = "Familia", T = "¿Estás bien? Vale. Ahora sí.", To = "Yo" },
				{ S = "Familia", T = "¿En qué estabas pensando?", To = "Yo" },
				{ S = "Familia", T = "Y no es la primera vez que me mientes.", To = "Yo", If = { Flags = { "MentisteFamilia" } } },
				{
					S = "Familia",
					T = "Lo del día que estabas “enfermo” tampoco me lo creí.",
					To = "Yo",
					Pause = 0.9,
					If = { Flags = { "MentisteFamilia" } },
				},
				{ S = "Paco", T = "Hmm. Treinta años con el súper abierto.", To = "Yo" },
				{ S = "Paco", T = "Nunca me habían entrado. Y has sido tú. No me lo esperaba.", To = "Yo", Pause = 0.9 },
				{ S = "Rayo", T = "Yo no he dicho nada. Que conste.", To = "Yo", If = { Rel = { Rayo = 5 } } },
				{ S = "Ines", T = "Sois menores. Y es la primera vez.", To = "Yo" },
				{ S = "Ines", T = "Tres turnos de servicio a la comunidad.", To = "Yo" },
				{ S = "Ines", T = "Y pedir perdón a Paco.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué le dices a Paco?",
					Options = {
						{
							T = "«Lo siento. De verdad. Te devuelvo todo y te lo pago.»",
							Effects = { Flags = { "PerdonPaco" } },
							Then = { { S = "Paco", T = "Hmm. Pedir perdón mirando a los ojos. Eso ya es algo.", To = "Yo" } },
						},
						{ T = "«No dices nada. Miras al suelo.»", Then = { { S = "Paco", T = "Ya. Hmm. No añade nada más.", To = "Yo" } } },
					},
				},
				{ S = "Ines", T = "Tres turnos. Bien hecho. ¿Sabes qué?", To = "Yo" },
				{ S = "Ines", T = "La mayoría de los chavales que vienen aquí no vuelven nunca a la comisaría.", To = "Yo" },
				{ S = "Ines", T = "Espero que tú seas de esos.", To = "Yo" },
				{ S = "Nerea", T = "Al final han ido Rayo y dos más.", To = "Yo", If = { Choices = { Plan = "No" } } },
				{ S = "Nerea", T = "Me he quedado en casa.", To = "Yo", Pause = 0.9, If = { Choices = { Plan = "Frenar" } } },
				{ S = "Nerea", T = "Rayo dice que alguien se ha chivado.", To = "Yo", Pause = 0.9 },
				{ S = "Nerea", T = "Dime que no has sido tú.", To = "Yo" },
				{ S = "Narrador", T = "Se oyen fragmentos: «Lo del supermercado…»" },
				{ S = "Narrador", T = "«Dicen que saltó la alarma…»" },
				{ S = "Narrador", T = "«Rayo está expulsado…»" },
				{ S = "Nerea", T = "Todo el instituto sabe lo del súper.", To = "Yo" },
				{ S = "Nerea", T = "Rayo está expulsado tres días.", To = "Yo", Pause = 0.9 },
				{ S = "Nerea", T = "Y tú… Te pillaron. Lo siento.", To = "Yo", If = { Flags = { "Pillado" } } },
				{ S = "Nerea", T = "Rayo dice que eres “de los buenos”.", To = "Yo", If = { Rel = { Rayo = 5 } } },
				{ S = "Nerea", T = "No sé si eso es un piropo.", To = "Yo", Pause = 0.9, If = { Rel = { Rayo = 5 } } },
				{ S = "Nerea", T = "Tú te libraste. Pero hay cámaras en la puerta del almacén.", To = "Yo", If = { Flags = { "Escapaste" } } },
				{ S = "Nerea", T = "Lo sabe todo el mundo menos Rayo.", To = "Yo", If = { Flags = { "Escapaste" } } },
				{ S = "Nerea", T = "Te fuiste a tiempo. Yo también.", To = "Yo", If = { Flags = { "TeFuiste" } } },
				{ S = "Nerea", T = "Creo que es lo más valiente que he hecho nunca.", To = "Yo", If = { Flags = { "TeFuiste" } } },
				{ S = "Nerea", T = "Tú no estabas. Mejor. Rayo…", To = "Yo", If = { NotChoices = { Plan = "Ir" } } },
				{ S = "Nerea", T = "En su casa no hay nadie nunca. No sé qué va a pasar.", To = "Yo" },
				{ S = "Nerea", T = "Supongo que crecer es esto. Hacer cosas.", To = "Yo" },
				{ S = "Nerea", T = "Y descubrir cuáles no quieres volver a hacer.", To = "Yo", Pause = 0.9 },
				{ S = "Nerea", T = "con una interfaz moral.", To = "Yo" },
			},
		},
		Mensajes = {
			Lines = {
				{ S = "Rayo", T = "¡JA! ¿Has visto? ¡Nadie nos pilla!", To = "Yo" },
				{ S = "Rayo", T = "Mañana nos comemos las chuches a la salud de Paco.", To = "Yo", Pause = 0.9 },
			},
		},
		Servicio = {
			Lines = {
				{
					S = "Nerea",
					T = "Rayo… ¿“Nadie se va a enterar”? ¡¿Esto es nadie?!",
					To = "Yo",
					Shot = "General",
					Pause = 0.9,
					Effects = { Scene = "Pan2_G7_Musica" },
				},
				{ S = "Rayo", T = "¡CORRED! ¡Cada uno por un lado!", To = "Yo" },
				{ S = "Rayo", T = "¡Nos vemos en el parque!", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Pan2_G5_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Rayo", Npc = "Rayo" } } },
				Dialogue = { { At = 0.4, S = "Rayo", T = "Pensaba que no venías. Sabía que vendrías.", To = "Yo" } },
			},
		},
		Pan2_G6_Entra = {
			Light = true,
			Duration = 12,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Rayo", Npc = "Rayo" } }, { At = 0, Use = { Key = "Nerea", Npc = "Nerea" } } },
				Dialogue = {
					{ At = 1.3, S = "Rayo", T = "Rápido. Coge lo que quieras. Y nos vamos.", To = "Yo" },
					{ At = 5, S = "Rayo", T = "¡Eso es! ¡Vámonos!", To = "Yo" },
					{ At = 7.5, S = "Nerea", T = "Espera. Yo tampoco quería. Me voy contigo.", To = "Yo" },
				},
			},
		},
		Pan2_G7_Musica = { Light = true, Duration = 11.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = { ["10"] = { Effects = { Scene = "Pan2_G6_Entra" } }, ["7"] = { Effects = { Scene = "Pan2_G5_Entra" } } },
}
