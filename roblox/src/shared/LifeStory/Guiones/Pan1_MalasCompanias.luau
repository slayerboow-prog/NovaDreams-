-- GUION REESCRITO de Pan1_MalasCompanias (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Pan1_MalasCompanias.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Pan1_MalasCompanias
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Pan1_MalasCompanias.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Pan1_MalasCompanias.md",
	Dialogues = {
		Bruno = {
			Lines = {
				{ S = "Bruno", T = "Oye. Me he enterado de lo de Rayo.", To = "Yo", Effects = { Scene = "Pan1_G15_Musica" } },
				{ S = "Bruno", T = "En el instituto se entera todo el mundo de todo.", To = "Yo" },
				{ S = "Bruno", T = "Yo era el malo del colegio. ¿Te acuerdas? Molaba.", To = "Yo" },
				{ S = "Bruno", T = "Hasta que dejó de molar. Rayo es eso. Pero en mayor.", To = "Yo" },
				{ S = "Bruno", T = "Hiciste bien en volver. De verdad.", To = "Yo", If = { Flags = { "RechazasteLaPandilla" } } },
				{ S = "Bruno", T = "Solo… Ten cuidado. Con Rayo, un día son los recreativos.", To = "Yo", If = { Choices = { Pellas = "Ir" } } },
				{ S = "Bruno", T = "Y otro día es otra cosa.", To = "Yo", Pause = 0.9, If = { Choices = { Pellas = "Ir" } } },
				{ S = "Rayo", T = "Carismático. Popular. Y precisamente por eso peligroso.", To = "Yo" },
				{ S = "Rayo", T = "Entiendo por qué quiero seguirle.", To = "Yo" },
				{ S = "Nerea", T = "No es simplemente “la chica buena”.", To = "Yo" },
				{ S = "Bruno", T = "Ya no es el niño que intimidaba.", To = "Yo" },
				{ S = "Bruno", T = "Ahora reconoce algo de sí mismo en Rayo.", To = "Yo" },
				{
					S = "Narrador",
					T = "Presentarla como: «El jugador está descubriendo quién es cuando sus amigos empiezan a tirar de él en direcciones diferentes.»",
				},
			},
		},
		Casa = {
			Lines = {
				{
					S = "Familia",
					T = "Ha llamado Javier. Dice que esta tarde no estabas en clase. ¿Me lo explicas? Ya. Vale. Te creo.",
					To = "Yo",
					If = { Choices = { Pellas = "Ir" } },
				},
				{ S = "Abu", T = "Las mentiras pesan más que la mochila, cariño.", To = "Yo", If = { Choices = { Pellas = "Ir" } } },
				{ S = "Abu", T = "Lo digo por experiencia.", To = "Yo", Pause = 0.9, If = { Choices = { Pellas = "Ir" } } },
				{ S = "Familia", T = "Me enfada. Mucho. Pero me alegra que me lo cuentes. Una semana sin paga.", To = "Yo", If = { Choices = { Pellas = "Ir" } } },
				{ S = "Familia", T = "Y después lo hablamos.", To = "Yo", If = { Choices = { Pellas = "Ir" } } },
				{ S = "Familia", T = "¿Qué tal el día? Tienes cara de haber aprendido algo.", To = "Yo", If = { Choices = { Pellas = "Clase" } } },
				{
					S = "Familia",
					T = "Omar me ha contado que hoy has ayudado a una chica de cuarto. Qué bien.",
					To = "Yo",
					If = { Choices = { Pellas = "Nerea" } },
				},
				{ S = "Abu", T = "A veces ser valiente no significa hacer ruido.", To = "Yo", If = { Choices = { Pellas = "Nerea" } } },
				{ S = "Abu", T = "A veces significa decir que no.", To = "Yo", Pause = 0.9, If = { Choices = { Pellas = "Nerea" } } },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Me encontraba mal y me fui a dar una vuelta» (mentira)",
							Effects = { Flags = { "MentisteFamilia" }, Rel = { Familia = -5 }, Traits = { Rebeldia = 1 } },
							Then = {
								{ S = "Familia", T = "…Ya. Vale. Te creo. Esta vez." },
								{ S = "Abu", T = "(desde el sillón, sin mirarte) Las mentiras pesan más que la mochila, cariño. Lo digo por experiencia." },
							},
						},
						{
							T = "«Me fui con unos de 4.º. Me equivoqué.»",
							Effects = { Rel = { Familia = 3 }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Familia", T = "Me enfada. Mucho. Pero me alegra que me lo cuentes. Una semana sin paga, y lo hablamos." } },
						},
					},
					If = { Choices = { Pellas = "Ir" } },
				},
			},
		},
		Comics = {
			Lines = {
				{ S = "Nerea", T = "Mira. Son pequeños cómics.", To = "Yo" },
				{ S = "Nerea", T = "No se los he enseñado a nadie.", To = "Yo" },
				{ S = "Nerea", T = "Rayo dice que dibujar es de críos.", To = "Yo", Pause = 0.9 },
				{ S = "Nerea", T = "Pero Rayo dice muchas cosas.", To = "Yo" },
			},
		},
		Muro = {
			Lines = {
				{ S = "Rayo", T = "Este muro es nuestro. Cada uno pone su firma. Pon la tuya.", To = "Yo" },
				{
					Ask = "¿Qué haces con el espray?",
					Options = {
						{
							T = "«Pintas tu firma, grande»",
							Effects = { Flags = { "Pintada" }, Rel = { Rayo = 4 }, Traits = { Rebeldia = 1 } },
							Then = { { S = "Rayo", T = "Eso. Ahora eres de los nuestros.", To = "Yo" } },
						},
						{
							T = "«Pintas un dibujo bonito»",
							Effects = { Flags = { "Pintada" }, Rel = { Nerea = 4 }, Traits = { Creatividad = 1, Rebeldia = 1 } },
							Then = {
								{ S = "Nerea", T = "Eso está bien. Muy bien.", To = "Yo", Pause = 0.9 },
								{ S = "Nerea", T = "Aunque sigue siendo pintar donde no se puede.", To = "Yo" },
							},
						},
						{ T = "«Devuelves el espray»", Effects = { Rel = { Nerea = 3, Rayo = -4 }, Traits = { Valentia = 1 } } },
					},
				},
				{ S = "Rayo", T = "Vale. Qué miedo tenéis todos a todo. Ya te lo pensarás. Pero su tono cambia.", To = "Yo" },
				{ S = "Rayo", T = "Ya no parece estar bromeando.", To = "Yo" },
			},
		},
		Rayo = {
			Lines = {
				{ S = "Rayo", T = "Eh, tú. Sí. Tú. Te he visto.", To = "Yo" },
				{ S = "Rayo", T = "No eres como los demás.", To = "Yo" },
				{ S = "Rayo", T = "Tienes pinta de saber divertirte.", To = "Yo" },
				{ S = "Rayo", T = "Después del recreo nos vamos a los recreativos. Javier ni se entera.", To = "Yo" },
				{ S = "Nerea", T = "Ni siquiera levanta la cabeza. Eso dice siempre.", To = "Yo" },
				{ S = "Rayo", T = "Porque siempre funciona.", To = "Yo" },
				{ S = "Nerea", T = "Yo voy porque no tengo nada mejor que hacer. Tú verás.", To = "Yo" },
				{ S = "Omar", T = "{nombre}… Esos se meten en líos. Todo el rato. Yo me vuelvo a clase.", To = "Yo" },
				{ S = "Omar", T = "Tú haz lo que quieras.", To = "Yo" },
			},
		},
		Recreativos = {
			Lines = {
				{ S = "Rayo", T = "¿Ves? Allí te hacen estar quieto seis horas. Aquí mandas tú.", To = "Yo" },
				{ S = "Nerea", T = "Más seria. La primera vez también me lo pareció.", To = "Yo" },
				{ S = "Nerea", T = "Luego llegan las notas.", To = "Yo" },
				{ S = "Nerea", T = "Y las llamadas a casa.", To = "Yo", Pause = 0.9 },
				{ S = "Rayo", T = "Siempre pensando en lo peor.", To = "Yo" },
			},
		},
		Salida = {
			Lines = {
				{ S = "Rayo", T = "Mira quién sale de clase.", To = "Yo" },
				{ S = "Rayo", T = "¿Qué tal la Revolución Francesa?", To = "Yo", Pause = 0.9 },
				{ S = "Rayo", T = "¿Te has divertido mucho?", To = "Yo" },
				{ S = "Nerea", T = "Javier ha llamado a nuestras casas. Hiciste bien.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Pan1_G10_Entra = {
			Light = true,
			Duration = 10.1,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Javier", Npc = "Javier" } } },
				Dialogue = {
					{ At = 0.4, S = "Javier", T = "La Historia no trata solo de lo que pasó.", To = "Yo" },
					{ At = 4.1, S = "Javier", T = "También trata de por qué la gente tomó determinadas decisiones.", To = "Yo" },
				},
			},
		},
		Pan1_G15_Musica = { Light = true, Duration = 56.5, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Pan1_G4_Entra = {
			Light = true,
			Duration = 39.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Javier", Npc = "Javier" } },
					{ At = 0, Use = { Key = "Rayo", Npc = "Rayo" } },
					{ At = 0, Use = { Key = "Nerea", Npc = "Nerea" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Rayo", T = "Sabía que tenías algo. Venga. No mires tanto.", To = "Yo" },
					{ At = 4.4, S = "Rayo", T = "Si dudas, te arrepientes.", To = "Yo" },
					{ At = 7, S = "Javier", T = "¿Volviendo a clase por tu propio pie? Me alegra el día.", To = "Yo" },
					{ At = 11.7, S = "Javier", T = "Hoy toca Revolución Francesa.", To = "Yo" },
					{ At = 14.6, S = "Javier", T = "Y es bastante mejor de lo que suena.", To = "Yo" },
					{ At = 18, S = "Rayo", T = "¡Pringado! Tú te lo pierdes.", To = "Yo" },
					{ At = 20.8, S = "Nerea", T = "¿Y a ti qué te importa?", To = "Yo" },
					{ At = 24.2, S = "Nerea", T = "¿Has visto mis dibujos?", To = "Yo" },
					{ At = 27.6, S = "Nerea", T = "Nadie mira mis dibujos. Vale. Hoy no voy.", To = "Yo" },
					{ At = 32.2, S = "Nerea", T = "Pero no te acostumbres a mandarme.", To = "Yo" },
					{ At = 35.4, S = "Rayo", T = "¿Nerea se queda? Tú. Me acuerdo de tu cara.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["3"] = { Effects = { Scene = "Pan1_G4_Entra" } }, ["9"] = { Effects = { Scene = "Pan1_G10_Entra" } } },
}
