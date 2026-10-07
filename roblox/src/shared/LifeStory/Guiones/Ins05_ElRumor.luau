-- GUION REESCRITO de Ins05_ElRumor (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Ins05_ElRumor.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Ins05_ElRumor
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Ins05_ElRumor.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Ins05_ElRumor.md",
	Dialogues = {
		Dario = {
			Lines = {
				{ S = "Dario", T = "¿Qué pasa?", To = "Yo" },
				{ S = "Dario", T = "Era una broma.", To = "Yo", Pause = 0.9 },
				{ S = "Dario", T = "Se ha hecho viral.", To = "Yo" },
				{ S = "Dario", T = "Eso es bueno, ¿no?", To = "Yo" },
				{ S = "Dario", T = "Omar es famoso.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«Bórrala y pídele perdón.»",
							Effects = { Choice = { Dario = "Perdon" }, Traits = { Empatia = 1, Valentia = 1 } },
							Then = {
								{ S = "Yo", T = "Tú no la estás viviendo. Él sí." },
								{ S = "Dario", T = "…", To = "Yo" },
								{ S = "Dario", T = "No lo había visto así.", To = "Yo", Pause = 0.9 },
								{ S = "Dario", T = "Él no se reía.", To = "Yo" },
								{ S = "Dario", T = "Vale.", To = "Yo", Pause = 0.9 },
								{ S = "Narrador", T = "Escribe: «Perdón. La he liado.»" },
								{ S = "Dario", T = "¿Se lo mando?", To = "Yo" },
							},
						},
						{
							T = "«Se lo cuentas a Javier.»",
							Effects = { Choice = { Dario = "Javier" }, Rel = { Javier = 4 }, Traits = { Responsabilidad = 2 } },
							Then = {
								{ S = "Javier", T = "Gracias por contármelo.", To = "Yo" },
								{ S = "Javier", T = "Esto no es una broma.", To = "Yo", Pause = 0.9 },
								{ S = "Javier", T = "Es hacer daño delante de todos.", To = "Yo" },
								{ S = "Javier", T = "Me encargo.", To = "Yo" },
								{ S = "Javier", T = "Y hablaré con toda la clase.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«Le devuelves la broma.»",
							Effects = { Choice = { Dario = "Venganza" }, Flags = { "MontajeDario" }, Rel = { Omar = -2 }, Traits = { Humor = 1 } },
						},
					},
				},
				{ S = "Narrador", T = "Lo que empezó como una broma se convierte en una competición.", If = { Choices = { Dario = "Venganza" } } },
			},
		},
		Deduccion = {
			Lines = {
				{ S = "Sara", T = "Vale.", To = "Yo" },
				{ S = "Sara", T = "La foto se hizo aquí.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "DR.", To = "Yo" },
				{ S = "Sara", T = "Darío Ruiz.", To = "Yo" },
				{ S = "Sara", T = "Segundo curso. Equipo de fútbol.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "El nuevo amigo de Nico.", To = "Yo" },
				{ S = "Sara", T = "Y Nico…", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Nico la compartió primero.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Eso es lo que más me duele.", To = "Yo" },
			},
		},
		LaFoto = {
			Lines = {
				{ S = "Sara", T = "{nombre}, mira.", To = "Yo", Effects = { Scene = "Ins05_G3_Musica" } },
				{ S = "Sara", T = "Está en el grupo desde anoche.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Omar no ha venido.", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Omar no falta nunca.", To = "Yo" },
				{ S = "Sara", T = "Ni con fiebre.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué haces con la foto?",
					Options = {
						{
							T = "«Borradla. No tiene gracia.»",
							Effects = { Choice = { Foto = "Frenar" }, Rel = { Omar = 5, Sara = 3 }, Traits = { Valentia = 2 } },
							Then = { { S = "Leire", T = "+1", To = "Yo", Pause = 1.8 }, { S = "Sara", T = "+1", To = "Yo" }, { S = "Sara", T = "Tres alumnos más.", To = "Yo" } },
						},
						{
							T = "«No dices nada, pero no la reenvías.»",
							Effects = { Choice = { Foto = "Nada" } },
							Then = { { S = "Sara", T = "No reenviarla está bien.", To = "Yo" }, { S = "Sara", T = "Pero no sé si basta.", To = "Yo", Pause = 0.9 } },
						},
						{
							T = "«Se te escapa una sonrisa… y luego te sientes fatal.»",
							Effects = { Choice = { Foto = "Reiste" }, Flags = { "TeReiste" }, Traits = { Humor = -1 } },
							Then = { { S = "Sara", T = "Es Omar.", To = "Yo" }, { S = "Sara", T = "Nuestro Omar.", To = "Yo", Pause = 0.9 } },
						},
					},
				},
				{ S = "Javier", T = "Móviles fuera.", To = "Yo" },
				{ S = "Javier", T = "Y si alguien tiene algo que contarme…", To = "Yo" },
				{ S = "Javier", T = "Mi puerta está abierta.", To = "Yo" },
				{ S = "Sara", T = "En el recreo averiguamos quién la hizo.", To = "Yo" },
				{ S = "Sara", T = "Y buscamos a Omar.", To = "Yo", Pause = 0.9 },
			},
		},
		Nico = {
			Lines = {
				{ S = "Nico", T = "¿Vienes a ver el entreno?", To = "Yo" },
				{ S = "Nico", T = "…", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "¿Por qué me miras así?", To = "Yo" },
				{
					Ask = "¿Cómo hablas con Nico?",
					Options = {
						{
							T = "«Hablar con Nico a solas»",
							Effects = { Choice = { HablasNico = "Privado" }, Rel = { Nico = 3 }, Traits = { Empatia = 1 } },
							Then = {
								{ S = "Nico", T = "Darío me la pasó.", To = "Yo" },
								{ S = "Nico", T = "Todos se estaban riendo.", To = "Yo", Pause = 0.9 },
								{ S = "Nico", T = "Quería que se rieran conmigo.", To = "Yo" },
								{ S = "Nico", T = "Que me vieran como uno de ellos.", To = "Yo", Pause = 0.9 },
								{ S = "Nico", T = "No pensé que Omar la vería.", To = "Yo" },
								{ S = "Nico", T = "No pensé nada.", To = "Yo", Pause = 0.9 },
								{ S = "Nico", T = "Qué idiota.", To = "Yo" },
								{ S = "Nico", T = "Omar es…", To = "Yo" },
								{ S = "Nico", T = "Omar.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«Decírselo delante del equipo»",
							Effects = { Choice = { HablasNico = "Publico" }, Rel = { Nico = -6 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Nico", T = "¿Delante de todos?", To = "Yo", Pause = 0.9 },
								{ S = "Nico", T = "Vale.", To = "Yo", Pause = 0.9 },
								{ S = "Nico", T = "Me lo merezco.", To = "Yo" },
								{ S = "Nico", T = "Pero podías habérmelo dicho a mí primero.", To = "Yo", If = { Choices = { HablasNico = "Publico" } } },
							},
						},
					},
				},
				{
					S = "Narrador",
					T = "Por primera vez desde que conoces a Nico, no intenta defenderse.",
					Pause = 0.9,
					If = { Choices = { HablasNico = "Publico" } },
				},
				{ S = "Nico", T = "Voy a hablar con Omar.", To = "Yo" },
				{ S = "Nico", T = "Hoy.", To = "Yo", Pause = 0.9 },
				{ S = "Nico", T = "Te lo prometo.", To = "Yo" },
			},
		},
		Omar = {
			Lines = {
				{ S = "Omar", T = "El banco del verano.", To = "Yo", If = { Choices = { Promesa = "Banco" } }, Effects = { Scene = "Ins05_G10_Musica" } },
				{ S = "Omar", T = "Prometimos quedar aquí.", To = "Yo", Pause = 0.9, If = { Choices = { Promesa = "Banco" } } },
				{ S = "Omar", T = "No pensaba que algún día lo usaría para esconderme.", To = "Yo", If = { Choices = { Promesa = "Banco" } } },
				{ S = "Omar", T = "Hola.", To = "Yo" },
				{ S = "Omar", T = "Ya has visto la foto, ¿no?", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Todo el mundo la ha visto.", To = "Yo" },
				{ S = "Omar", T = "«Omar el Tragón».", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Ja.", To = "Yo" },
				{ S = "Omar", T = "Lo peor no es la foto.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Lo peor es que Nico la compartió.", To = "Yo", Pause = 1.5 },
				{ S = "Omar", T = "Nico.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«Te sientas a su lado sin decir nada.»",
							Effects = { Rel = { Omar = 8 }, Traits = { Empatia = 2 } },
							Then = { { S = "Omar", T = "Toma.", To = "Yo" }, { S = "Omar", T = "Tragones los dos.", To = "Yo", Pause = 0.9 } },
						},
						{
							T = "«Borré la foto del grupo. Y no va a volver.»",
							If = { Choices = { Foto = "Frenar" } },
							Effects = { Rel = { Omar = 10 } },
							Then = {
								{ S = "Omar", T = "¿Fuiste tú?", To = "Yo" },
								{ S = "Omar", T = "Leire me dijo que alguien había plantado cara.", To = "Yo", Pause = 0.9 },
								{ S = "Omar", T = "No sabía que eras tú.", To = "Yo" },
								{ S = "Omar", T = "Gracias.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«Nico está fatal. Quiere pedirte perdón.»",
							Effects = { Rel = { Nico = 3, Omar = 5 }, Traits = { Responsabilidad = 1 } },
							Then = {
								{ S = "Omar", T = "Que venga él.", To = "Yo" },
								{ S = "Omar", T = "Que me lo diga él.", To = "Yo", Pause = 0.9 },
								{ S = "Omar", T = "Si lo hace…", To = "Yo" },
								{ S = "Omar", T = "A lo mejor le perdono.", To = "Yo" },
							},
						},
						{
							T = "«Perdona. Yo también me reí al principio.»",
							If = { Flags = { "TeReiste" } },
							Effects = { Rel = { Omar = 6 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Omar", T = "Gracias por decírmelo.", To = "Yo" },
								{ S = "Omar", T = "Duele.", To = "Yo", Pause = 0.9 },
								{ S = "Omar", T = "Pero prefiero saberlo de ti.", To = "Yo" },
								{ S = "Omar", T = "Mañana vuelvo.", To = "Yo" },
								{ S = "Omar", T = "Pero tienes que venir a buscarme.", To = "Yo", Pause = 0.9 },
							},
						},
					},
				},
			},
		},
		Pista_Bruno = {
			Lines = {
				{ S = "Bruno", T = "Ya.", To = "Yo" },
				{ S = "Bruno", T = "Sé lo que dicen.", To = "Yo", Pause = 0.9 },
				{ S = "Bruno", T = "Que he sido yo.", To = "Yo" },
				{ S = "Bruno", T = "Siempre soy yo, ¿no?", To = "Yo", Pause = 0.9 },
				{ S = "Bruno", T = "Como en el colegio.", To = "Yo", If = { Flags = { "AcusasteABruno" } } },
				{ S = "Bruno", T = "Me acusaste sin pruebas.", To = "Yo", Pause = 0.9, If = { Flags = { "AcusasteABruno" } } },
				{ S = "Bruno", T = "Y tampoco fui yo.", To = "Yo", If = { Flags = { "AcusasteABruno" } } },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Te creo. Pero ayúdame. ¿Sabes algo?»",
							Effects = { Choice = { Bruno = "Confiar" }, Rel = { Bruno = 8 }, Traits = { Empatia = 1 } },
							Then = {
								{ S = "Bruno", T = "¿Me crees?", To = "Yo" },
								{ S = "Bruno", T = "Vale.", To = "Yo", Pause = 0.9 },
								{ S = "Bruno", T = "En el vestuario estaban enseñando el móvil de Darío.", To = "Yo" },
								{ S = "Bruno", T = "Darío Ruiz.", To = "Yo", Pause = 0.9 },
								{ S = "Bruno", T = "D. R.", To = "Yo" },
								{ S = "Bruno", T = "No me estoy chivando.", To = "Yo" },
								{ S = "Bruno", T = "Te lo cuento.", To = "Yo", Pause = 0.9 },
								{ S = "Bruno", T = "Que es distinto.", To = "Yo" },
							},
						},
						{
							T = "«Demuéstralo.»",
							Effects = { Choice = { Bruno = "Dudar" }, Rel = { Bruno = -4 } },
							Then = { { S = "Bruno", T = "No hay nada.", To = "Yo" }, { S = "Bruno", T = "Ahora déjame en paz.", To = "Yo" } },
						},
					},
				},
			},
		},
		Pista_Captura = {
			Lines = {
				{ S = "Narrador", T = "La primera persona que la compartió en el grupo fue Nico." },
				{ S = "Sara", T = "¿Nico?", To = "Yo", Pause = 0.9 },
				{ S = "Sara", T = "Nico y Omar se conocen desde los seis años.", To = "Yo", Pause = 0.9 },
			},
		},
		Pista_Leire = {
			Lines = {
				{ S = "Leire", T = "El montaje es malísimo.", To = "Yo" },
				{ S = "Leire", T = "Pero la foto original está bien hecha.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Está tomada desde arriba.", To = "Yo" },
				{ S = "Leire", T = "Teleobjetivo.", To = "Yo" },
				{ S = "Leire", T = "La luz es de tarde.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Y el fondo es la pista.", To = "Yo" },
				{ S = "Leire", T = "Alguien estaba en la grada durante un entrenamiento.", To = "Yo" },
				{ S = "Leire", T = "Y hacerle una foto así a alguien sin preguntarle…", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "No me gusta.", To = "Yo" },
				{ S = "Leire", T = "Cuenta conmigo.", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Ins05_G10_Musica = { Light = true, Duration = 33.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Ins05_G12_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = { { At = 0.4, S = "Omar", T = "¿List{o/a}?", To = "Yo" }, { At = 2.4, S = "Omar", T = "Vamos.", To = "Yo" } },
			},
		},
		Ins05_G3_Musica = { Light = true, Duration = 29.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Ins05_G6_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Actors = { { At = 0, Use = { Key = "Nico", Npc = "Nico" } } }, Dialogue = { { At = 0.4, S = "Nico", T = "¡{nombre}!", To = "Yo" } } },
		},
		Ins05_G9_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Narrador", T = "Segundo mensaje: «El banco.»" } } },
		},
	},
	Steps = {
		["11"] = { Effects = { Scene = "Ins05_G12_Entra" } },
		["5"] = { Effects = { Scene = "Ins05_G6_Entra" } },
		["8"] = { Effects = { Scene = "Ins05_G9_Entra" } },
	},
}
