-- GUION REESCRITO de Ins03_QueQuieresSer (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Ins03_QueQuieresSer.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Ins03_QueQuieresSer
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Ins03_QueQuieresSer.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Ins03_QueQuieresSer.md",
	Dialogues = {
		Comisaria = {
			Effects = { Traits = { Curiosidad = 1, Responsabilidad = 1 } },
			Lines = {
				{ S = "Ines", T = "Mucha gente cree que este trabajo son persecuciones.", To = "Yo" },
				{ S = "Ines", T = "Casi siempre es escuchar.", To = "Yo" },
				{ S = "Yo", T = "Quiero defender a quien no pueda defenderse.", If = { Choices = { SuenoInfancia = "Derecho" } } },
				{ S = "Ines", T = "Caso cerrado.", To = "Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "Escuchar a los dos antes de decidir nada",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = { { S = "Ines", T = "Eso es. Al final la maceta era de los dos: la compraron juntos hace veinte años. Se habían olvidado." } },
						},
						{
							T = "Buscar pruebas: tiques, fotos, testigos",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = { { S = "Ines", T = "Muy bien. Una foto de hace años lo aclara: la compraron a medias. Se ríen. Caso cerrado." } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Derecho" } },
							Then = { { S = "Ines", T = "Te veo con toga o con placa. Cualquiera de las dos te queda bien." } },
						},
						{ T = "Es interesante, pero no es lo mío.", Then = { { S = "Ines", T = "Perfecto. Lo importante es que ahora sabes que esto existe." } } },
					},
				},
			},
		},
		Empresa = {
			Effects = { Traits = { Creatividad = 1, Curiosidad = 1 } },
			Lines = {
				{ S = "Marcos", T = "Tengo una empresa. Bueno…", To = "Yo" },
				{ S = "Marcos", T = "La empresa me tiene a mí.", To = "Yo" },
				{
					Ask = "¿Tu idea?",
					Options = {
						{
							T = "Alquilarlas por horas a turistas en la playa",
							Effects = { Traits = { Creatividad = 1 } },
							Then = { { S = "Marcos", T = "¡Anda! Eso no lo habíamos pensado. Lo apunto. Si funciona, te pago en helados." } },
						},
						{
							T = "Preguntar a la gente por qué no las compra",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = { { S = "Marcos", T = "La pregunta más importante de cualquier negocio. Resulta que… el rojo no gusta. Las pintaremos de azul." } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Economia" } },
							Then = { { S = "Marcos", T = "Estudia números y aprende a escuchar. Con eso se montan las mejores empresas." } },
						},
						{
							T = "Es interesante, pero no es lo mío.",
							Then = { { S = "Marcos", T = "Normal. Esto no es para todo el mundo. Yo tampoco sabía que era para mí." } },
						},
					},
				},
			},
		},
		Estadio = {
			Effects = { Traits = { Empatia = 1, Responsabilidad = 1 } },
			Lines = {
				{ S = "Irene", T = "¡Al trote! Soy Irene. Entrenadora y fisioterapeuta.", To = "Yo" },
				{ S = "Irene", T = "Tu medalla del torneo del colegio… Yo empecé igual.", To = "Yo", If = { Memories = { "PrimerTorneo" } } },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Hoy no. Si corres, te lesionas un año.»",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = { { S = "Irene", T = "Duro, pero correcto. Cuidar a alguien a veces es decirle que no." } },
						},
						{
							T = "«Vamos a ponerle hielo y luego decidimos.»",
							Effects = { Traits = { Empatia = 1 } },
							Then = { { S = "Irene", T = "Muy bien: primero cuidar, luego decidir. Al final no pudo correr, pero te lo agradeció." } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Deporte" } },
							Then = { { S = "Irene", T = "Entrena, estudia y cuida tu cuerpo. Y ven a verme cuando quieras." } },
						},
						{
							T = "Es interesante, pero no es lo mío.",
							Then = { { S = "Irene", T = "Vale. Pero sigue moviéndote. El cuerpo lo agradece toda la vida." } },
						},
					},
				},
			},
		},
		Estudio = {
			Effects = { Traits = { Creatividad = 2 } },
			Lines = {
				{ S = "Toni", T = "Hola. Tú debes de ser {nombre}.", To = "Yo" },
				{ S = "Leire", T = "Te dije que mi tío habla en planos.", To = "Yo", If = { Flags = { "ConocesALeire" } } },
				{ S = "Toni", T = "Es una enfermedad.", To = "Yo", If = { Flags = { "ConocesALeire" } } },
				{ S = "Yo", T = "Quiero hacer cosas que la gente no olvide. Volvemos al cine.", If = { Choices = { SuenoInfancia = "Arte" } } },
				{ S = "Yo", T = "Junto a la ventana. Delante de las butacas vacías." },
				{ S = "Toni", T = "Cuenta algo.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Dónde le pones?",
					Options = {
						{
							T = "Junto a la ventana, con luz natural",
							Effects = { Traits = { Creatividad = 1 } },
							Then = { { S = "Toni", T = "¡Primer plano, luz de ventana! Eso es lo que haría yo. Queda precioso." } },
						},
						{
							T = "Delante de las butacas vacías: cuenta una historia",
							Effects = { Traits = { Creatividad = 1 } },
							Then = { { S = "Toni", T = "Un plano que cuenta algo por sí solo. Eso no se enseña: se tiene." } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Audiovisual" } },
							Then = { { S = "Toni", T = "Pues coge una cámara, aunque sea la del móvil, y no pares de mirar." } },
						},
						{
							T = "Es interesante, pero no es lo mío.",
							Then = { { S = "Toni", T = "Me parece bien. Pero ahora ya ves las películas de otra forma. No hay vuelta atrás." } },
						},
					},
				},
			},
		},
		Hospital = {
			Lines = {
				{ S = "Nuria", T = "¡Bienvenida la cantera!", To = "Yo" },
				{ S = "Nuria", T = "Soy Nuria. Medicina de urgencias.", To = "Yo" },
				{ S = "Yo", T = "Quiero salvar vidas. Volvemos al hospital.", If = { Choices = { SuenoInfancia = "Medicina" } } },
				{ S = "Nuria", T = "¿Qué harías primero? A — Tranquilizarlo.", To = "Yo" },
				{ S = "Nuria", T = "B — Observar el brazo sin moverlo. Exacto.", To = "Yo" },
				{ S = "Nuria", T = "Antes de ayudar a alguien, tienes que conseguir que se sienta segur{o/a}.", To = "Yo", Pause = 0.9 },
				{ S = "Nuria", T = "¿Te ves trabajando aquí? Perfecto.", To = "Yo" },
				{ S = "Nuria", T = "Saber lo que no quieres también es avanzar.", To = "Yo" },
				{
					Ask = "¿Qué haces primero?",
					Options = {
						{
							T = "Tranquilizarle: le preguntas su nombre y le hablas",
							Effects = { Traits = { Empatia = 1 } },
							Then = { { S = "Nuria", T = "Exacto. Un paciente tranquilo se deja ayudar. La mitad de la medicina es hablar bien." } },
						},
						{
							T = "Mirar el brazo con cuidado sin moverlo",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = { { S = "Nuria", T = "Bien: no mover, observar, avisar. Luego una radiografía. Tienes buen instinto." } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Medicina" } },
							Then = { { S = "Nuria", T = "Entonces estudia mucha biología. Y aprende a dormir en cualquier sitio. Te hará falta." } },
						},
						{ T = "Es interesante, pero no es lo mío.", Then = { { S = "Nuria", T = "Muy bien. Saber lo que no quieres también es saber mucho." } } },
					},
				},
			},
		},
		Laboratorio = {
			Effects = { Traits = { Curiosidad = 1, Valentia = 1 } },
			Lines = {
				{ S = "Sofia", T = "¡Pasa! Aquí rompemos cosas para aprender por qué se rompen.", To = "Yo" },
				{ S = "Yo", T = "Quiero inventar cosas que no existen.", If = { Choices = { SuenoInfancia = "Ingenieria" } } },
				{ S = "Sara", T = "Sabía que acabarías aquí.", To = "Yo", If = { Choices = { Club = "Robotica" } } },
				{ S = "Sara", T = "Aunque yo habría puesto otra pieza.", To = "Yo", If = { Choices = { Club = "Robotica" } } },
				{ S = "Sofia", T = "Por eso tú haces robots y {él/ella} hace puentes.", To = "Yo", If = { Choices = { Club = "Robotica" } } },
				{ S = "Sofia", T = "¿Te ves trabajando en esto?", To = "Yo" },
				{
					Ask = "¿Cómo lo arreglas?",
					Options = {
						{
							T = "Añadir triángulos: son más fuertes",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = {
								{
									S = "Sofia",
									T = "¡Triángulos! ¿Quién te lo ha contado? Los puentes de verdad están llenos. Aguanta dos kilos y medio. Récord del día.",
								},
							},
						},
						{
							T = "Probar, romper y volver a probar",
							Effects = { Traits = { Valentia = 1 } },
							Then = { { S = "Sofia", T = "El método de los ingenieros de verdad. Tres puentes rotos después: aguanta dos kilos. ¡Bien!" } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Ingenieria" } },
							Then = { { S = "Sofia", T = "Pues en unos años nos vemos por aquí. Te guardo una bata." } },
						},
						{ T = "Es interesante, pero no es lo mío.", Then = { { S = "Sofia", T = "Vale. Pero si un día te aburres, aquí siempre hay algo roto." } } },
					},
				},
			},
		},
		Reflexion = {
			Lines = {
				{ S = "Carmen", T = "Bueno, {nombre}. ¿Qué has descubierto?", To = "Yo", Effects = { Scene = "Ins03_G6_Musica" } },
				{ S = "Carmen", T = "El hospital te removió algo.", To = "Yo", If = { Flags = { "Interes_Medicina" } } },
				{ S = "Nico", T = "¿Médico? Te dejo practicar conmigo.", To = "Yo", If = { Flags = { "Interes_Medicina" } } },
				{ S = "Carmen", T = "Sofía me ha dicho que tus puentes aguantan más de lo esperado.", To = "Yo", If = { Flags = { "Interes_Ingenieria" } } },
				{ S = "Carmen", T = "Inés dice que sabes escuchar a las dos partes.", To = "Yo", If = { Flags = { "Interes_Derecho" } } },
				{ S = "Carmen", T = "Marcos va a cambiar el color de sus bicicletas. Por tu culpa.", To = "Yo", If = { Flags = { "Interes_Economia" } } },
				{ S = "Carmen", T = "Tobías pregunta si vas a volver al taller.", To = "Yo", If = { Flags = { "Interes_Oficio" } } },
				{ S = "Carmen", T = "Con Tobías, eso casi es una oferta de trabajo.", To = "Yo", Pause = 0.9, If = { Flags = { "Interes_Oficio" } } },
				{ S = "Carmen", T = "Lola dice que tienes cabeza de cocina.", To = "Yo", If = { Flags = { "Interes_Cocina" } } },
				{ S = "Omar", T = "Lo sabía. Socios.", To = "Yo", If = { Flags = { "Interes_Cocina" } } },
				{
					S = "Carmen",
					T = "Irene se fijó en que cuidaste primero a una persona y después pensaste en ganar.",
					To = "Yo",
					If = { Flags = { "Interes_Deporte" } },
				},
				{ S = "Carmen", T = "Toni ya te llama “la cámara”.", To = "Yo", If = { Flags = { "Interes_Audiovisual" } } },
				{ S = "Carmen", T = "Viniendo de él, es casi un título.", To = "Yo", Pause = 0.9, If = { Flags = { "Interes_Audiovisual" } } },
				{ S = "Leire", T = "Mi tío no se lo dice a cualquiera. Bueno… sí.", To = "Yo", If = { Flags = { "ConocesALeire" } } },
				{ S = "Leire", T = "Pero esta vez lo dice en serio.", To = "Yo", If = { Flags = { "ConocesALeire" } } },
				{ S = "Carmen", T = "Y ahora quiero preguntarte algo distinto. No qué quieres ser.", To = "Yo" },
				{ S = "Carmen", T = "¿Cómo te sientes con tu futuro?", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Cómo te sientes con tu futuro?",
					Options = {
						{
							T = "«Creo que ya sé lo que me gusta.»",
							Effects = { Choice = { Orientacion = "Claro" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Carmen", T = "Eso está bien. Pero no cierres ninguna puerta demasiado pronto.", To = "Yo" } },
						},
						{
							T = "«Tengo más dudas que antes.»",
							Effects = { Choice = { Orientacion = "Dudas" }, Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Carmen", T = "Entonces has mirado de verdad.", To = "Yo" },
								{ S = "Carmen", T = "Las dudas también son una forma de avanzar.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«Me gustan muchas cosas a la vez.»",
							Effects = { Choice = { Orientacion = "Muchas" }, Traits = { Creatividad = 1 } },
							Then = {
								{ S = "Carmen", T = "A mí también me pasaba. Y mírame.", To = "Yo" },
								{ S = "Carmen", T = "Ahora ayudo a otros a descubrir lo suyo.", To = "Yo" },
							},
						},
					},
				},
				{ S = "Omar", T = "Yo ya lo tengo claro. Quiero trabajar con Lola.", To = "Yo" },
				{ S = "Omar", T = "O comer donde trabaje Lola.", To = "Yo", Pause = 0.9 },
				{ S = "Carmen", T = "Guárdalo. Dentro de unos años lo vas a volver a leer.", To = "Yo" },
				{ S = "Carmen", T = "Y probablemente te vas a reír.", To = "Yo", Pause = 0.9 },
				{ S = "Carmen", T = "O quizá descubras que ya lo sabías.", To = "Yo" },
				{ S = "Javier", T = "¿Y?", To = "Yo" },
				{ S = "Carmen", T = "Todavía no lo saben. Y eso es exactamente como tiene que ser.", To = "Yo" },
				{ S = "Javier", T = "Entonces ha salido bien.", To = "Yo" },
			},
		},
		Restaurante = {
			Effects = { Rel = { Omar = 3 }, Traits = { Empatia = 1, Responsabilidad = 1 } },
			Lines = {
				{ S = "Omar", T = "He llegado primero. Era una cuestión de prioridades.", To = "Yo" },
				{ S = "Lola", T = "Que no quieras trabajar aquí no significa que no puedas aprender a cocinar.", To = "Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "Organizar: primero lo que tarda más",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = { { S = "Lola", T = "¡Cabeza de chef! Así se sale de un lío. Las cuatro mesas, servidas." } },
						},
						{
							T = "Pedir ayuda a Omar: en equipo, más rápido",
							Effects = { Rel = { Omar = 3 }, Traits = { Empatia = 1 } },
							Then = { { S = "Lola", T = "Una cocina es un equipo o no es nada. Muy bien. Y tu amigo pela patatas como un campeón." } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Cocina" } },
							Then = { { S = "Lola", T = "Pues aprende a cocinar para tu familia. Ese es el primer restaurante de todo el mundo." } },
						},
						{
							T = "Es interesante, pero no es lo mío.",
							Then = { { S = "Lola", T = "No pasa nada. Pero la tortilla, llévatela. Eso sí es obligatorio." } },
						},
					},
				},
			},
		},
		Taller = {
			Effects = { Traits = { Curiosidad = 1, Humor = 1 } },
			Lines = {
				{ S = "Tomas", T = "Pasa. No muerdo. El coche sí, si metes la mano donde no debes.", To = "Yo" },
				{ S = "Tomas", T = "Aquí no hace falta saberlo todo.", To = "Yo" },
				{ S = "Tomas", T = "Hace falta querer aprender.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué crees?",
					Options = {
						{
							T = "La batería",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = { { S = "Tomas", T = "¡La batería! Tienes oído. Muchos adultos no lo saben. Cambiamos y… ¡brum! Arrancado." } },
						},
						{
							T = "No tengo ni idea, pero quiero verlo",
							Effects = { Traits = { Humor = 1 } },
							Then = { { S = "Tomas", T = "Esa es la mejor respuesta que me han dado nunca. Era la batería. Ahora ya lo sabes." } },
						},
					},
				},
				{
					Ask = "¿Te ves trabajando en esto?",
					Options = {
						{
							T = "Sí. Me lo imagino perfectamente.",
							Effects = { Flags = { "Interes_Oficio" } },
							Then = { { S = "Tomas", T = "Pues cuando quieras, vente un verano. Te enseño lo que sé. Que es bastante." } },
						},
						{
							T = "Es interesante, pero no es lo mío.",
							Then = { { S = "Tomas", T = "Bien. Pero si algún día se te estropea la bici, ya sabes dónde estoy." } },
						},
					},
				},
			},
		},
	},
	Scenes = {
		Ins03_G2_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Actors = { { At = 0, Use = { Key = "Nico", Npc = "Nico" } } }, Dialogue = { { At = 0.4, S = "Nico", T = "¡{nombre}! Aquí.", To = "Yo" } } },
		},
		Ins03_G6_Musica = { Light = true, Duration = 95.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
	},
	Steps = { ["1"] = { Effects = { Scene = "Ins03_G2_Entra" } } },
}
