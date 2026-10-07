-- GUION REESCRITO de Ins02_Clubes (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Ins02_Clubes.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Ins02_Clubes
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Ins02_Clubes.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Ins02_Clubes.md",
	Dialogues = {
		Audicion = {
			Lines = {
				{ S = "Ruben", T = "Treinta segundos. Es un pirata que ha perdido su barco. Dramático. Pero no demasiado. ¿Nervios?", To = "Yo" },
				{ S = "Ruben", T = "A mí el primer día me temblaban hasta las cejas.", To = "Yo" },
			},
		},
		Cumple = {
			Lines = {
				{ S = "Nico", T = "¡{nombre}! ¡Justo a tiempo!", To = "Yo" },
				{ S = "Nico", T = "Has llegado antes de que Omar la terminara.", To = "Yo" },
				{ S = "Omar", T = "Yo estaba protegiéndola.", To = "Yo" },
				{ S = "Nico", T = "¿De quién?", To = "Yo" },
				{ S = "Omar", T = "De mí.", To = "Yo" },
				{ S = "Nico", T = "¡{nombre}! ¡Has llegado!", To = "Yo" },
				{ S = "Nico", T = "Te hemos guardado la última porción.", To = "Yo" },
				{ S = "Omar", T = "La he defendido con mi vida. Y con un tenedor.", To = "Yo" },
				{ S = "Leire", T = "Es imposible decirle que no. Lo he intentado.", To = "Yo", Pause = 0.9, If = { Flags = { "ConocesALeire" } } },
				{ S = "Nico", T = "Trece años. Ya soy casi mayor. ¿Me veis más alto? Vale. Decid que sí.", To = "Yo" },
			},
		},
		Dilema = {
			Lines = {
				{ S = "Nico", T = "¡{nombre}! El sábado cumplo trece. Bueno. Tres y diez.", To = "Yo" },
				{ S = "Omar", T = "Trece.", To = "Yo" },
				{ S = "Nico", T = "Eso. Cinco. Y mi abuela hace croquetas.", To = "Yo" },
				{ S = "Omar", T = "El sábado a las cinco tienes también tu primer evento del club.", To = "Yo" },
				{ S = "Nico", T = "Ah. Eso complica las cosas.", To = "Yo", Pause = 0.9 },
				{ S = "Yo", T = "El club. Es mi primer compromiso de verdad." },
				{ S = "Nico", T = "Ah. Vale. Otra. Te guardo croquetas. Pocas. ¡SÍ! Ya sabía yo.", To = "Yo" },
				{ S = "Nico", T = "Te voy a dar la croqueta más grande.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Ambicioso. Me gusta. Te dejo mi bono de autobús. Por si acaso.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué haces el sábado?",
					Options = {
						{
							T = "El club: es mi primer compromiso de verdad",
							Effects = { Choice = { Sabado = "Club" }, Flags = { "SoloClub" }, Rel = { Nico = -4 }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Nico", T = "Ah. Vale. Lo entiendo. …Te guardo croquetas. Pocas." } },
						},
						{
							T = "El cumpleaños de Nico: los amigos primero",
							Effects = { Choice = { Sabado = "Cumple" }, Flags = { "SoloCumple" }, Rel = { Nico = 8 } },
							Then = { { S = "Nico", T = "¡SÍ! Ya sabía yo. Te voy a dar la croqueta más grande." } },
						},
						{
							T = "Intentar las dos cosas: el club y luego correr al parque",
							Effects = { Choice = { Sabado = "Ambas" }, Flags = { "IntentasLasDos" }, Traits = { Valentia = 1 } },
							Then = { { S = "Omar", T = "Ambicioso. Me gusta. Te dejo mi bono de autobús por si acaso." } },
						},
					},
				},
			},
		},
		EventoClub = {
			Lines = {
				{ S = "Alex", T = "¡Vamos! Bueno. ¡Mi barco! ¡Mi precioso barco!", To = "Yo" },
				{ S = "Ruben", T = "¡Eso! Lo has vendido.", To = "Yo" },
				{ S = "Sara", T = "Solo uno. Pero uno.", To = "Yo", Pause = 0.9 },
				{ S = "Hugo", T = "Hay gente leyéndolo. La observa durante más de un minuto.", To = "Yo" },
				{ S = "Leire", T = "Eso es bueno. Cuando alguien se queda mirando.", To = "Yo" },
				{ S = "Omar", T = "Tenemos quince minutos.", To = "Yo" },
			},
		},
		Feria = {
			Lines = {
				{ S = "Javier", T = "Uno por persona. Que luego no dormís. Algunos alumnos ríen.", To = "Yo" },
				{ S = "Javier", T = "Elegid algo que os guste.", To = "Yo" },
				{ S = "Javier", T = "No lo que elijan vuestros amigos.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Yo me apunto al suyo.", To = "Yo" },
				{ S = "Javier", T = "¿Al mío?", To = "Yo" },
				{ S = "Omar", T = "A cualquiera que elija él.", To = "Yo" },
				{ S = "Javier", T = "Eso no era exactamente el mensaje.", To = "Yo" },
				{ S = "Omar", T = "Lo he entendido a mi manera.", To = "Yo" },
			},
		},
		Foto_Biblio = { Lines = { { S = "Leire", T = "Esa foto se queda.", To = "Yo" } } },
		Foto_Estadio = {
			Lines = {
				{ S = "Leire", T = "Esa es buena. Muy buena.", To = "Yo" },
				{ S = "Leire", T = "No se lo digas a nadie.", To = "Yo" },
				{ S = "Leire", T = "Eres mejor encuadrando que yo.", To = "Yo" },
			},
		},
		Foto_Uni = { Lines = { { S = "Leire", T = "Mi madre estudió aquí. Y los más cansados.", To = "Yo" } } },
		Fotografia = {
			Lines = {
				{ S = "Leire", T = "No hacemos fotos de nosotros.", To = "Yo" },
				{ S = "Leire", T = "Hacemos fotos de lo que vemos.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Mi abuelo decía que así se aprende a mirar. Vamos.", To = "Yo" },
			},
		},
		Mural = {
			Lines = {
				{ S = "Narrador", T = "Debajo: «Aquí también se puede volar.»" },
				{ S = "Hugo", T = "Esto reduce bastante la lista de sospechosos.", To = "Yo", Pause = 0.9 },
				{ S = "Hugo", T = "Tú conoces a alguien.", To = "Yo", If = { Flags = { "ElRecuerdoDeVegaDecorando" } } },
			},
		},
		Periodico = {
			Lines = {
				{ S = "Hugo", T = "Cada lunes aparece uno nuevo. Pájaros. Otra. Frases. Otra. Colores.", To = "Yo" },
				{ S = "Hugo", T = "El director está entre enfadado… …y encantado.", To = "Yo" },
			},
		},
		Pregunta_Delegada = {
			Lines = {
				{ S = "Delegada", T = "La llave del gimnasio la tienen los clubes.", To = "Yo" },
				{ S = "Delegada", T = "El club de arte usa el patio los viernes.", To = "Yo", Pause = 0.9 },
				{ S = "Delegada", T = "Y solo una persona se queda hasta tarde.", To = "Yo", Pause = 0.9 },
				{ S = "Hugo", T = "Tenemos una pista.", To = "Yo" },
			},
		},
		Pregunta_Veterano = { Lines = { { S = "Veterano", T = "Vi a alguien el viernes. Botes de pintura.", To = "Yo" } } },
		Prueba_Baloncesto = {
			Lines = {
				{ S = "Alex", T = "Tiros desde la línea. Ocho balones.", To = "Yo" },
				{ S = "Alex", T = "Con cuatro, entras de titular. Con menos… Entras igual.", To = "Yo" },
				{ S = "Omar", T = "¡Plan B!", To = "Yo" },
				{ S = "Alex", T = "Calientas banquillo.", To = "Yo" },
				{ S = "Omar", T = "Ah. Plan C.", To = "Yo" },
			},
		},
		Puesto_Baloncesto = {
			Lines = {
				{ S = "Alex", T = "¡{nombre}! Soy la capitana del equipo de primero.", To = "Yo" },
				{ S = "Alex", T = "Hacemos pruebas el martes. Sin favoritismos. Bueno… Un poco. Nada mal. Tenemos trabajo.", To = "Yo", Pause = 0.9 },
			},
		},
		Puesto_Fotografia = {
			Lines = {
				{ S = "Leire", T = "El club soy yo.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "¿Solo tú?", To = "Yo" },
				{ S = "Leire", T = "Y mi tío Toni. No es un club muy grande.", To = "Yo" },
				{ S = "Leire", T = "Pero salimos por el campus.", To = "Yo", Pause = 0.9 },
			},
		},
		Puesto_Periodico = {
			Lines = {
				{ S = "Hugo", T = "El periódico se llama «La Voz del Campus». Somos tres.", To = "Yo" },
				{ S = "Hugo", T = "Buscamos gente que haga preguntas incómodas. Mi primer reportaje…", To = "Yo" },
				{ S = "Hugo", T = "Alguien pinta murales por la noche. Nadie sabe quién.", To = "Yo" },
				{ S = "Hugo", T = "Eso sí es un misterio.", To = "Yo" },
			},
		},
		Puesto_Robotica = {
			Lines = {
				{ S = "Sara", T = "Construimos cosas que hacen cosas. Bueno…", To = "Yo" },
				{ S = "Sara", T = "Que intentan hacer cosas. Tornillo pita.", To = "Yo" },
				{ S = "Sara", T = "Este año queremos hacer uno que reparta bocadillos.", To = "Yo" },
				{ S = "Omar", T = "¿Bocadillos?", To = "Yo" },
				{ S = "Sara", T = "Sí.", To = "Yo" },
				{ S = "Omar", T = "Me apunto mentalmente.", To = "Yo" },
			},
		},
		Puesto_Teatro = {
			Lines = {
				{ S = "Ruben", T = "¿Teatro? Aquí se viene a hacer el ridículo. Con estilo.", To = "Yo" },
				{ S = "Ruben", T = "Yo empecé para no esconderme más.", To = "Yo" },
				{ S = "Ruben", T = "Y… Me alegro de verte.", To = "Yo", Pause = 0.9, If = { Flags = { "Ruben_Perdonado" } } },
				{ S = "Ruben", T = "Lo de la mochila fue hace mil años.", To = "Yo", If = { Flags = { "Ruben_Perdonado" } } },
			},
		},
		Robot1 = {
			Lines = {
				{ S = "Sara", T = "¡NO! Tornillo sale disparado.", To = "Yo" },
				{ S = "Sara", T = "¡Le he puesto la velocidad máxima! Sin querer. Creo.", To = "Yo" },
			},
		},
		Robot2 = { Lines = { { S = "Omar", T = "¡Va rápido!", To = "Yo" }, { S = "Sara", T = "¡Eso ya lo sé!", To = "Yo" } } },
		Robot3 = { Lines = { { S = "Sara", T = "¿Está bien? Tornillo pita. Está bien. Creo.", To = "Yo" } } },
		Robotica = {
			Lines = {
				{ S = "Sara", T = "Este es Tornillo. Dos ruedas.", To = "Yo" },
				{ S = "Sara", T = "Y mala suerte.", To = "Yo", Pause = 1.8 },
				{ S = "Omar", T = "Me cae bien.", To = "Yo" },
				{ S = "Sara", T = "Tú introduces las órdenes.", To = "Yo" },
				{ S = "Sara", T = "Yo controlo el sensor. Omar mira…", To = "Yo" },
				{ S = "Omar", T = "Bocadillos.", To = "Yo" },
				{ S = "Sara", T = "Eso.", To = "Yo" },
			},
		},
		TrasElClub = {
			Lines = {
				{ S = "Narrador", T = "Un pequeñ{o/a} papel: «Para {nombre}.»" },
				{ S = "Narrador", T = "A veces crecer también significa perderse algunas cosas." },
				{ S = "Narrador", T = "Pero eso no significa que dejen de importarte.", Pause = 0.9 },
				{ S = "Narrador", T = "Quizá crecer no consiste en saber quién quieres ser." },
				{ S = "Narrador", T = "Quizá empieza cuando descubres las cosas que quieres probar.", Pause = 0.9 },
			},
		},
		Vega_Murales = {
			Lines = {
				{ S = "Vega", T = "Vale. Soy yo. Lo hago porque el patio era gris.", To = "Yo", Pause = 0.9 },
				{ S = "Vega", T = "Y porque nadie me ha pedido permiso para ser gris.", To = "Yo", Pause = 0.9 },
				{ S = "Vega", T = "Pero no estaba haciendo daño a nadie. ¿Vais a publicarlo? ¿Anónimo?", To = "Yo" },
				{ S = "Hugo", T = "Lo he leído. Ahora lo entiendo.", To = "Yo", Pause = 0.9 },
				{ S = "Vega", T = "¿Y si dice que no? Vale. Si me acompañáis.", To = "Yo" },
				{ S = "Hugo", T = "El reportaje será mejor.", To = "Yo" },
				{ S = "Hugo", T = "«Una alumna pinta el instituto».", To = "Yo" },
				{ S = "Vega", T = "Ah. Vale. Gracias.", To = "Yo" },
				{ S = "Hugo", T = "No sé si hemos hecho bien.", To = "Yo", Pause = 0.9 },
				{ S = "Hugo", T = "A veces la verdad puede hacer daño a alguien que no estaba haciendo daño.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué hacéis con el reportaje?",
					Options = {
						{
							T = "Publicarlo sin su nombre: «El artista misterioso»",
							Effects = { Choice = { Reportaje = "Anonimo" }, Rel = { Hugo = 3, Vega = 10 }, Traits = { Empatia = 1 } },
							Then = { { S = "Hugo", T = "Un buen periodista también protege a sus fuentes. Lo he leído. Y ahora lo entiendo." } },
						},
						{
							T = "Convencerla para pedir permiso al director y pintar a la luz del día",
							Effects = { Choice = { Reportaje = "Permiso" }, Rel = { Hugo = 5, Vega = 6 }, Traits = { Responsabilidad = 2 } },
							Then = {
								{
									S = "Vega",
									T = "¿Y si dice que no? …Vale. Si me acompañáis. Si dice que sí, el reportaje será mejor: «Una alumna pinta el instituto».",
								},
							},
						},
						{
							T = "Publicar su nombre: la verdad es la verdad",
							Effects = { Choice = { Reportaje = "Nombre" }, Rel = { Hugo = -2, Vega = -8 }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Vega", T = "Genial. Gracias. De verdad, gracias por nada." },
								{ S = "Hugo", T = "…No sé si hemos hecho bien. A veces la verdad duele a alguien que no hacía daño." },
							},
						},
					},
				},
			},
		},
	},
	Scenes = {
		Ins02_G11_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Ruben", Npc = "Ruben" } } },
				Dialogue = {
					{ At = 0.4, S = "Ruben", T = "¡Eso! Has actuado como si te importara.", To = "Yo", If = { Flags = { "Ins02_P11_Gana" } } },
					{ At = 3.7, S = "Ruben", T = "Perfecto. Ahora sabemos qué tenemos que practicar.", To = "Yo" },
				},
			},
		},
		Ins02_G1_Fin = {
			Light = true,
			Duration = 7.4,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = {
					{ At = 0.4, S = "Omar", T = "Ya sabes moverte por aquí.", To = "Yo" },
					{ At = 3.9, S = "Omar", T = "Eso es oficialmente preocupante.", To = "Yo" },
				},
			},
		},
		Ins02_G5_Eleccion = {
			Light = true,
			Duration = 18.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Alex", Npc = "Alex" } },
					{ At = 0, Use = { Key = "Ruben", Npc = "Ruben" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
					{ At = 0, Use = { Key = "Hugo", Npc = "Hugo" } },
					{ At = 0, Use = { Key = "Leire", Npc = "Leire" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Alex", T = "¡Bien! El martes, prueba. Zapatillas. Y ganas.", To = "Yo", If = { Choices = { Club = "Baloncesto" } } },
					{ At = 0.4, S = "Sara", T = "¡Sí! Tú, yo y un robot.", To = "Yo", If = { Choices = { Club = "Robotica" } } },
					{ At = 0.4, S = "Ruben", T = "¿De verdad? Audición mañana. Y luego entra igual.", To = "Yo", If = { Choices = { Club = "Teatro" } } },
					{ At = 0.4, S = "Hugo", T = "¡Genial! Tu primer caso: los murales. Y paciencia.", To = "Yo", If = { Choices = { Club = "Periodico" } } },
					{ At = 0.4, S = "Leire", T = "¿En serio? Vale. Ya somos dos.", To = "Yo", If = { Choices = { Club = "Fotografia" } } },
					{ At = 3.7, S = "Sara", T = "Como en los viejos tiempos. Pero con cables.", To = "Yo", If = { Choices = { Club = "Robotica" } } },
					{ At = 4.1, S = "Leire", T = "Esto ya parece un club. Casi.", To = "Yo", If = { Choices = { Club = "Fotografia" } } },
					{ At = 4.1, S = "Alex", T = "Las zapatillas son opcionales. Las ganas no.", To = "Yo", If = { Choices = { Club = "Baloncesto" } } },
					{ At = 4.3, S = "Hugo", T = "Los buenos reportajes son lentos.", To = "Yo", If = { Choices = { Club = "Periodico" } } },
					{ At = 9.1, S = "Alex", T = "Ven.", To = "Yo" },
				},
			},
		},
		Ins02_G8_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Alex", Npc = "Alex" } } },
				Dialogue = {
					{ At = 0.4, S = "Alex", T = "Equipo de primero. No pasa nada.", To = "Yo" },
					{ At = 4.2, S = "Alex", T = "Mejorar también cuenta.", To = "Yo" },
				},
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Ins02_G1_Fin" } },
		["10"] = { Effects = { Scene = "Ins02_G11_Entra" } },
		["11"] = { Set = { Win = { Flags = { "ClubTitular", "Ins02_P11_Gana" }, Traits = { Valentia = 1 } } } },
		["5"] = { Effects = { Scene = "Ins02_G5_Eleccion" } },
		["7"] = { Effects = { Scene = "Ins02_G8_Entra" } },
	},
}
