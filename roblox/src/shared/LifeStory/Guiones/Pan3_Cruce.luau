-- GUION REESCRITO de Pan3_Cruce (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Pan3_Cruce.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Pan3_Cruce
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Pan3_Cruce.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Pan3_Cruce.md",
	Dialogues = {
		Carmen = {
			Lines = {
				{ S = "Carmen", T = "No la interroga. ¿Cómo estás? Puedes tardar.", To = "Yo" },
				{ S = "Nerea", T = "Quiero salir.", To = "Yo" },
				{ S = "Carmen", T = "Entonces vamos a buscar una puerta. ¿Estos son tuyos?", To = "Yo" },
				{ S = "Carmen", T = "Los jueves hay un taller de cómic en la biblioteca del campus.", To = "Yo" },
				{ S = "Carmen", T = "Lo lleva Toni, el tío de Leire.", To = "Yo", Pause = 0.9 },
				{ S = "Nerea", T = "¿Con gente que dibuja?", To = "Yo" },
				{ S = "Carmen", T = "Con gente que dibuja.", To = "Yo" },
				{ S = "Nerea", T = "Vale. Pero vienes conmigo el primer día.", To = "Yo", Pause = 0.9 },
				{ S = "Carmen", T = "Salir de un sitio así cuesta mucho.", To = "Yo" },
				{ S = "Carmen", T = "Hacerlo acompañado, un poco menos. Bien hecho.", To = "Yo", Pause = 0.9 },
			},
		},
		Espejo = {
			Lines = {
				{
					S = "Familia",
					T = "Te noto rar{o/a} últimamente. Llegas tarde. No hablas.",
					To = "Yo",
					If = { Flags = { "Camino_Delincuente" } },
					Effects = { Scene = "Pan3_G16_Musica" },
				},
				{ S = "Familia", T = "Sabes que puedes contarme lo que sea, ¿verdad? Lo que sea.", To = "Yo", If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Abu", T = "Desde el sillón. Yo también tuve malas compañías a tu edad.", To = "Yo", If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Abu", T = "Lo difícil no es entrar. Es salir. Pero se sale.", To = "Yo", Pause = 0.9, If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Familia", T = "Me ha llamado la madre de Nerea.", To = "Yo", If = { Choices = { Camino = "Alejarse" } } },
				{ S = "Familia", T = "Dice que su hija ha vuelto a dibujar.", To = "Yo", Pause = 0.9, If = { Choices = { Camino = "Alejarse" } } },
				{ S = "Familia", T = "Que ha sido gracias a ti. Ven aquí.", To = "Yo", If = { Choices = { Camino = "Alejarse" } } },
				{ S = "Familia", T = "Me ha contado Tobías que le has llevado a un chaval.", To = "Yo", If = { Choices = { Camino = "Salvar" } } },
				{
					S = "Familia",
					T = "Dice que llegó a las ocho menos cuarto. Qué orgullo me das.",
					To = "Yo",
					Pause = 0.9,
					If = { Choices = { Camino = "Salvar" } },
				},
				{ If = { Flags = { "Camino_Trabajador" }, Traits = { Rebeldia = 2 } }, Effects = { Flags = { "Redimido" } } },
			},
		},
		Estadio = {
			Lines = {
				{ S = "Rayo", T = "Tú grita: ”¡Camisetas, a diez!” Yo cobro.", To = "Yo" },
				{ S = "Rayo", T = "Si ves a un policía, silba.", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "¿{nombre}? ¿Qué haces con esas camisetas? Son falsas. Son de MI equipo. ¿En serio?", To = "Yo" },
				{ S = "Nico", T = "Es solo un negocio. No te metas. Vale. No me meto.", To = "Yo" },
				{ S = "Nico", T = "Pero no me hables en el recreo. No sé quién eres.", To = "Yo" },
				{ S = "Rayo", T = "¡Eh! ¡¿Adónde vas?!", To = "Yo" },
				{ S = "Nico", T = "Vámonos. Te invito a un bocadillo.", To = "Yo" },
				{ S = "Nico", T = "Y no se lo cuento a nadie. Bueno… A Omar sí.", To = "Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«Es solo un negocio. No te metas.»",
							Effects = { Money = 50, Rel = { Nico = -15 }, Traits = { Rebeldia = 1 } },
							Then = {
								{ S = "Nico", T = "…Vale. No me meto. Pero no me hables en el recreo. No sé quién eres." },
								{ S = "Narrador", T = "Esa tarde ganas cincuenta. Te pesan en el bolsillo más que cualquier mochila." },
							},
						},
						{
							T = "Dejas la bolsa en el suelo y te vas con Nico",
							Effects = { Flags = { "Camino_Trabajador", "Redimido" }, Rel = { Nico = 6, Rayo = -8 }, Traits = { Valentia = 2 }, Unflags = { "Camino_Delincuente" } },
							Then = {
								{ S = "Rayo", T = "¡Eh! ¿Adónde vas? ¡¿ADÓNDE VAS?!" },
								{ S = "Nico", T = "Vámonos. Te invito a un bocadillo. Y no se lo cuento a nadie. Bueno, a Omar sí. A Omar se lo cuento todo." },
							},
						},
					},
				},
			},
		},
		Nerea = {
			Lines = {
				{ S = "Nerea", T = "Me voy de la pandilla. Ya está.", To = "Yo" },
				{ S = "Nerea", T = "Estoy harta de correr. De mentir en casa.", To = "Yo" },
				{ S = "Nerea", T = "Y de que Rayo decida por mí.", To = "Yo", Pause = 0.9 },
				{
					S = "Nerea",
					T = "Desde la noche del súper no he vuelto a dormir bien. ¿Tú sí?",
					To = "Yo",
					If = { Flags = { "Hurto" }, Memories = { "LaNoche" } },
				},
				{ S = "Nerea", T = "Pero me da miedo. Si me voy… No tengo a nadie.", To = "Yo", Pause = 0.9 },
				{ S = "Nerea", T = "En mi clase soy “la de la pandilla de Rayo”. Nadie se me acerca.", To = "Yo" },
				{ S = "Nerea", T = "Tú me dijiste que mis dibujos eran buenos.", To = "Yo", If = { Flags = { "AmigaNerea" } } },
				{ S = "Nerea", T = "Nadie me había dicho eso. Nunca.", To = "Yo", Pause = 0.9, If = { Flags = { "AmigaNerea" } } },
				{ S = "Nerea", T = "Rayo te ha ofrecido lo de las camisetas, ¿no? A mí también. ¿Qué vas a hacer?", To = "Yo" },
			},
		},
		Salvar = {
			Lines = {
				{ S = "Rayo", T = "¿Tú otra vez? ¿Vienes a comprarme una camiseta? ¿Por qué haces esto?", To = "Yo" },
				{ S = "Rayo", T = "Tú siempre me has dicho que no a todo.", To = "Yo", Pause = 0.9, If = { RelBelow = { Rayo = 5 } } },
				{ S = "Rayo", T = "Eres la única persona que no me ha dejado tirado. Qué raro.", To = "Yo", Pause = 0.9, If = { RelBelow = { Rayo = 5 } } },
				{ S = "Rayo", T = "Estabas en todo conmigo. Podrías seguir.", To = "Yo", If = { Rel = { Rayo = 5 } } },
				{ S = "Rayo", T = "Y vienes a sacarme a mí.", To = "Yo", If = { Rel = { Rayo = 5 } } },
				{ S = "Rayo", T = "Porque te mereces algo mejor que correr delante de la policía. A las ocho. Vale.", To = "Yo" },
				{ S = "Rayo", T = "Pero si el viejo es un pesado, me piro. Qué pesad{o/a}. Vale. A las ocho.", To = "Yo" },
				{ S = "Rayo", T = "Y no se lo digas a nadie de la pandilla.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Porque te mereces algo mejor que correr delante de la policía.»",
							Effects = { Flags = { "RayoCambia" }, Rel = { Rayo = 10 } },
							Then = {
								{ S = "Rayo", T = "…A las ocho. Vale. Pero si el viejo es un pesado, me piro." },
								{ S = "Narrador", T = "No se pira. Al día siguiente llega a las ocho menos cuarto." },
							},
						},
						{
							T = "«Porque eres mi amigo. Aunque a veces no lo parezca.»",
							Effects = { Flags = { "RayoCambia" }, Rel = { Rayo = 12 }, Traits = { Empatia = 1 } },
							Then = { { S = "Rayo", T = "(se frota la cara) …Qué pesad{o/a}. Vale. A las ocho. Y no se lo digas a nadie de la pandilla." } },
						},
					},
				},
			},
		},
		Tomas = {
			Lines = {
				{ S = "Tomas", T = "¿Un chaval que se pasa el día desmontando motos que no son suyas? Hmm.", To = "Yo" },
				{ S = "Tomas", T = "Eso es talento mal usado.", To = "Yo" },
				{ S = "Tomas", T = "Que venga mañana a las ocho.", To = "Yo" },
				{ S = "Tomas", T = "Si llega a las ocho y cinco, que no venga. Si llega a las ocho…", To = "Yo", Pause = 0.9 },
				{ S = "Tomas", T = "Le enseño todo lo que sé.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Pan3_G16_Musica = { Light = true, Duration = 40.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Pan3_G2_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Rayo", Npc = "Rayo" } } },
				Dialogue = { { At = 0.4, S = "Rayo", T = "Mira quién viene. Pensaba que ya no te acordabas de mí.", To = "Yo" } },
			},
		},
		Pan3_G6_Entra = {
			Light = true,
			Duration = 20.1,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Nerea", Npc = "Nerea" } } },
				Dialogue = {
					{ At = 0.4, S = "Nerea", T = "Vale. Entonces ya sé qué vas a elegir. No discute. Eso duele más.", To = "Yo" },
					{ At = 5.8, S = "Nerea", T = "Por primera vez sonríe. No exageradamente. ¿De verdad? Vale. Entonces no voy sola.", To = "Yo" },
					{ At = 12.5, S = "Nerea", T = "¿Quieres salvar a Rayo? Eso va a ser difícil. Pero…", To = "Yo" },
					{ At = 16.9, S = "Nerea", T = "Gracias por intentarlo.", To = "Yo" },
				},
			},
		},
		Pan3_G9_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Actors = { { At = 0, Use = { Key = "Nerea", Npc = "Nerea" } } }, Dialogue = { { At = 0.4, S = "Nerea", T = "No sé si puedo.", To = "Yo" } } },
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Pan3_G2_Entra" } },
		["5"] = { Effects = { Scene = "Pan3_G6_Entra" } },
		["8"] = { Effects = { Scene = "Pan3_G9_Entra" } },
	},
}
