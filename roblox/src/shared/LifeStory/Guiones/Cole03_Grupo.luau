-- GUION REESCRITO de Cole03_Grupo (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Cole03_Grupo.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Cole03_Grupo
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Cole03_Grupo.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Cole03_Grupo.md",
	Dialogues = {
		Banquillo = {
			Lines = {
				{ S = "Andres", T = "¡Final! Y ahora… todos a dar la mano.", To = "Yo", Shot = "General", Effects = { Scene = "Cole03_G16_Musica" } },
				{ S = "Andres", T = "Todos, Bruno.", To = "Yo", Shot = "Reaccion:Bruno" },
				{ S = "Bruno", T = "Vale.", To = "Yo" },
				{
					S = "Nico",
					T = "¡HEMOS GANADO! ¡HEMOS GANADO A BRUNO!",
					To = "Yo",
					Shot = "Reaccion:Nico",
					A = "Happy",
					If = { Flags = { "PartidoGanado" } },
				},
				{ S = "Nico", T = "¡Esto hay que contárselo a mis nietos!", To = "Yo", If = { Flags = { "PartidoGanado" } } },
				{ S = "Nico", T = "Empate. Bueno. Un empate contra Bruno es como ganar. Casi.", To = "Yo", If = { Flags = { "PartidoEmpate" } } },
				{ S = "Nico", T = "Hemos perdido. Pero…", To = "Yo", If = { Flags = { "PartidoPerdido" } } },
				{ S = "Nico", T = "¿Habéis visto esa jugada?", To = "Yo", Shot = "PrimerPlano:Nico" },
				{ S = "Nico", T = "La próxima les ganamos.", To = "Yo" },
				{ S = "Sara", T = "He contado los pases. Veintitrés.", To = "Yo", Shot = "Reaccion:Sara" },
				{ S = "Sara", T = "Somos un equipo con futuro. Los datos no mienten.", To = "Yo" },
				{ S = "Omar", T = "Lo he dibujado todo.", To = "Yo", Shot = "Reaccion:Omar" },
				{ S = "Omar", T = "Toma. Sales tú marcando. Más o menos así fue.", To = "Yo", Shot = "General" },
				{ S = "Mateo", T = "Yo… he tocado el balón dos veces.", To = "Yo", Shot = "PrimerPlano:Mateo", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Mateo", T = "Dos. Es mi récord.", To = "Yo", Shot = "Reaccion:Mateo" },
				{ S = "Hugo", T = "Buen partido. En serio.", To = "Yo", Shot = "Reaccion:Hugo" },
				{
					Ask = "¿Qué dices al grupo?",
					Options = {
						{ T = "«¡Somos un equipazo!»", Effects = { Rel = { Nico = 3, Omar = 3, Sara = 3 }, Traits = { Deportividad = 1 } } },
						{
							T = "«Omar, casi te comes el bocadillo en plena jugada.»",
							Effects = { Rel = { Omar = 4 }, Traits = { Humor = 1 } },
							Then = { { S = "Omar", T = "Estaba defendiéndolo. Es distinto.", To = "Yo" } },
						},
						{
							T = "«Lo mejor ha sido jugar juntos.»",
							Effects = { Rel = { Mateo = 3, Nico = 3, Omar = 3, Sara = 3 }, Traits = { Empatia = 1 } },
							Then = {
								{ S = "Nico", T = "Oye… Ahora somos un grupo, ¿no?", To = "Yo", Shot = "General" },
								{ S = "Nico", T = "Los grupos tienen nombre. Es la ley.", To = "Yo", Pause = 0.9 },
							},
						},
					},
				},
				{
					Ask = "¿Vas?",
					Options = {
						{ T = "¡Sí! ¡Nos vemos allí!", Effects = { Choice = { Permiso = "Directo" } } },
						{
							T = "Primero pido permiso en casa.",
							Effects = { Choice = { Permiso = "Casa" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Sara", T = "Muy responsable. Te esperamos en la puerta de tu casa." } },
						},
					},
				},
			},
		},
		Bicho1 = {
			Lines = {
				{ S = "Sara", T = "¡Ahí!", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "No respires. Seis patas. Caparazón verde. Y…", To = "Yo", Shot = "PPP:Sara", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "¡BRILLA!", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "¡Síguelo! ¡La ciencia no espera!", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
			},
		},
		Bicho2 = {
			Lines = {
				{ S = "Sara", T = "Ahí.", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "Fíjate. Cuando le da el sol…", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "cambia de color. Es iridiscente.", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
				{
					Ask = "¿Qué dices?",
					Options = {
						{
							T = "«¿Iri-qué?»",
							Effects = { Traits = { Humor = 1 } },
							Then = { { S = "Sara", T = "Iridiscente. Como las pompas de jabón. Te lo apunto.", To = "Yo", If = { Choices = { Invitacion = "Sara" } } } },
						},
						{
							T = "«Como las pompas de jabón, ¿no?»",
							Effects = { Rel = { Sara = 3 }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Sara", T = "¡Exacto! ¡Por fin alguien de mi nivel!", To = "Yo", If = { Choices = { Invitacion = "Sara" } } } },
						},
					},
				},
			},
		},
		Bicho3 = {
			Lines = {
				{ S = "Sara", T = "Espera.", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "Registro científico número uno.", To = "Yo", Shot = "Medio:Sara", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "Descubridores. Sara y {nombre}. Fecha… Hoy.", To = "Yo", Shot = "General", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "Oye… Ha sido el mejor recreo de mi vida.", To = "Yo", Shot = "PrimerPlano:Sara", If = { Choices = { Invitacion = "Sara" } } },
				{ S = "Sara", T = "Gracias por venir.", To = "Yo", Shot = "Reaccion:Yo", If = { Choices = { Invitacion = "Sara" } } },
			},
		},
		ElGato = {
			Lines = {
				{ S = "Omar", T = "Por cierto… ¿Sabéis que en el cole vive un gato?", To = "Yo", Effects = { Scene = "Cole03_G25_Musica" } },
				{ S = "Omar", T = "Naranja. Duerme detrás del gimnasio.", To = "Yo", Shot = "General" },
				{ S = "Sara", T = "Nadie sabe de quién es. Ramón le deja agua.", To = "Yo" },
				{ S = "Omar", T = "Pero dice que no es suyo.", To = "Yo" },
				{ S = "Omar", T = "Esta semana no le he visto.", To = "Yo", Shot = "Reaccion:Omar" },
				{ S = "Omar", T = "A lo mejor tiene hambre.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "¿Me ayudáis a buscarlo?", To = "Yo" },
				{
					Ask = "¿Buscaréis al gato?",
					Options = {
						{
							T = "«¡Claro! Mañana lo buscamos.»",
							Effects = {
								Choice = { GatoColegio = "Buscar" },
								Later = { { AfterMinutes = 3, Start = "Side_GatoDelCole" } },
								Rel = { Omar = 4 },
								Traits = { Empatia = 1 },
							},
							Then = { { S = "Omar", T = "Sabía que dirías que sí. Le llamo Bigotes. En secreto.", To = "Yo" } },
						},
						{
							T = "«Seguro que está bien. Los gatos saben cuidarse.»",
							Effects = { Choice = { GatoColegio = "Nobuscar" } },
							Then = { { S = "Omar", T = "Ya… Seguramente.", To = "Yo" } },
						},
					},
				},
			},
		},
		FaltanJugadores = {
			Lines = {
				{ S = "Nico", T = "¡EH!", To = "Yo", Shot = "General", Effects = { Scene = "Cole03_G12_Musica" } },
				{ S = "Nico", T = "¡Vosotros!", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Nico", T = "Nos faltan jugadores. Bruno dice que si no somos cinco… perdemos sin jugar.", To = "Yo", Shot = "Seguir:Nico" },
				{ S = "Omar", T = "Yo no sé jugar. Pero puedo ponerme de portero.", To = "Yo" },
				{ S = "Omar", T = "Soy muy bueno no moviéndome.", To = "Yo" },
				{ S = "Sara", T = "Estadísticamente… Con cinco jugadores nuestras probabilidades suben.", To = "Yo" },
				{ S = "Nico", T = "¿Eso significa que ganamos?", To = "Yo" },
				{ S = "Sara", T = "Significa que tenemos más posibilidades.", To = "Yo" },
				{ S = "Nico", T = "Me vale.", To = "Yo" },
				{ S = "Mateo", T = "¿Yo… también puedo jugar?", To = "Yo", Shot = "Reaccion:Mateo", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Nico", T = "¡Claro! ¡Cuantos más, mejor!", To = "Yo", Shot = "PrimerPlano:Nico" },
			},
		},
		Mural_Cielo = {
			Lines = {
				{ S = "Omar", T = "El cielo. Azul. Pero no cualquier azul.", To = "Yo" },
				{ S = "Omar", T = "Azul de «hoy no hay deberes».", To = "Yo" },
				{
					Ask = "¿Qué le añades?",
					Options = {
						{
							T = "«Un sol con gafas.»",
							Effects = { Traits = { Humor = 1 } },
							Then = { { S = "Omar", T = "Un sol que se protege del sol. Me gusta.", To = "Yo" } },
						},
						{
							T = "«Un cohete.»",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = { { S = "Omar", T = "Rumbo a Marte. Sara lo va a aprobar.", To = "Yo" } },
						},
					},
				},
			},
		},
		Mural_Colegio = {
			Lines = {
				{ S = "Omar", T = "Ahora el colegio.", To = "Yo" },
				{ S = "Omar", T = "Y tiene que aparecer Ramón.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Porque si no… no es nuestro colegio.", To = "Yo", Shot = "Medio:Omar" },
				{ S = "Omar", T = "Mira su cara. Le va a encantar.", To = "Yo", Shot = "Reaccion:Omar" },
			},
		},
		Mural_Nosotros = {
			Lines = {
				{ S = "Omar", T = "Y aquí… nosotros.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Tú. Yo. Y los que vengan. Dejo espacio.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Siempre hay que dejar espacio.", To = "Yo", Shot = "PrimerPlano:Omar" },
				{ S = "Omar", T = "No suelo dejar pintar a nadie en mis dibujos.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Contigo es distinto.", To = "Yo", Shot = "Reaccion:Yo" },
			},
		},
		NombreGrupo = {
			Lines = {
				{ S = "Nico", T = "Oye. Ahora somos un grupo.", To = "Yo", Effects = { Scene = "Cole03_G26_Musica" } },
				{ S = "Nico", T = "Y los grupos tienen nombre. Es la ley.", To = "Yo", Shot = "General" },
				{
					Ask = "¿Cómo os llamáis?",
					Options = {
						{ T = "«Los Imparables.»", Effects = { Choice = { NombreGrupo = "Los Imparables" } } },
						{ T = "«La Patrulla Valmar.»", Effects = { Choice = { NombreGrupo = "La Patrulla Valmar" } } },
						{ T = "«Los del Banco Azul.»", Effects = { Choice = { NombreGrupo = "Los del Banco Azul" } } },
						{ T = "«Los Dinosaurios.»", If = { Choices = { Ropa = "Dinosaurios" } }, Effects = { Choice = { NombreGrupo = "Los Dinosaurios" } } },
					},
				},
				{ S = "Nico", T = "¡{grupo}! ¡Me encanta! ¡Grito de guerra!", To = "Yo", Shot = "PrimerPlano:Nico" },
				{ S = "Omar", T = "Foto. Tenemos que hacernos una foto.", To = "Yo" },
				{ S = "Sara", T = "Todos juntos. Tres.", To = "Yo" },
				{ S = "Sara", T = "Dos.", To = "Yo", Shot = "General" },
				{ S = "Sara", T = "Uno…", To = "Yo", Shot = "General" },
			},
		},
		Parque_Canasta = {
			Lines = {
				{ S = "Nico", T = "Reto. El que meta desde más lejos…", To = "Yo" },
				{ S = "Nico", T = "elige el helado de todos.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Cómo tiras?",
					Options = {
						{
							T = "«Tiro lejano. A lo grande.»",
							Effects = { Traits = { Valentia = 1 } },
							Then = { { S = "Nico", T = "¡NO! ¡Eso ha sido chiripa!", To = "Yo", Shot = "Reaccion:Nico", Pause = 0.9 } },
						},
						{
							T = "«Bandeja, sin arriesgar.»",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = { { S = "Nico", T = "Ha sido… un fallo táctico. No digas nada.", To = "Yo", Shot = "Reaccion:Nico" } },
						},
					},
				},
			},
		},
		Parque_Columpio = {
			Lines = {
				{ S = "Omar", T = "Mira.", To = "Yo" },
				{ S = "Omar", T = "Cuando subes muy alto…", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "las nubes parecen dibujos.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Esa es un dragón. Comiéndose un bocadillo.", To = "Yo", Shot = "General" },
				{ S = "Yo", T = "Tú ves bocadillos en todas partes." },
				{ S = "Omar", T = "Y tú…", To = "Yo" },
				{ S = "Omar", T = "cuando te conozca más, también.", To = "Yo", Shot = "PrimerPlano:Omar" },
			},
		},
		Parque_Estanque = {
			Lines = {
				{ S = "Sara", T = "Experimento.", To = "Yo" },
				{ S = "Sara", T = "¿Qué flota?", To = "Yo", Shot = "General" },
				{ S = "Sara", T = "Una hoja.", To = "Yo", Shot = "General" },
				{ S = "Sara", T = "Una piedra.", To = "Yo", Shot = "General" },
				{ S = "Sara", T = "Una piña.", To = "Yo", Shot = "General" },
				{
					Ask = "¿Qué flotará?",
					Options = {
						{
							T = "«La hoja y la piña.»",
							Effects = { Rel = { Sara = 4 }, Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Sara", T = "¡Correcto! La piña tiene aire dentro.", To = "Yo" },
								{ S = "Sara", T = "Serías {un científico estupendo/una científica estupenda}.", To = "Yo" },
							},
						},
						{
							T = "«La piedra, que es muy valiente.»",
							Effects = { Rel = { Sara = 2 }, Traits = { Humor = 1 } },
							Then = { { S = "Sara", T = "La piedra ha sido valiente. Pero poco eficiente.", To = "Yo", Shot = "Reaccion:Sara", G = "Laugh" } },
						},
					},
				},
			},
		},
		Parque_Kiosco = {
			Lines = {
				{ S = "Omar", T = "Helados. Por fin.", To = "Yo", Shot = "General" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«¡Invito yo a todos!»",
							Effects = { Items = { Helado = 1 }, Rel = { Mateo = 3, Nico = 3, Omar = 3, Sara = 3 }, Spend = 8 },
							Then = {
								{ S = "Omar", T = "Eres la mejor persona que conozco. Después de mi abuela.", To = "Yo", If = { NotFlags = { "SinDinero" } } },
								{ S = "Narrador", T = "No te llega.", Shot = "Reaccion:Yo", If = { Flags = { "SinDinero" } } },
								{ S = "Mateo", T = "No pasa nada. Yo tengo mi paga. Invito yo.", To = "Yo", If = { Flags = { "SinDinero" } } },
								{ S = "Mateo", T = "Nunca había invitado a nadie.", To = "Yo", Shot = "PrimerPlano:Mateo", If = { Flags = { "SinDinero" } } },
							},
						},
						{
							T = "«Uno para mí.»",
							Effects = { Items = { Helado = 1 }, Spend = 2 },
							Then = {
								{ S = "Omar", T = "¿Me das un poquito? Solo la puntita.", To = "Yo", If = { NotFlags = { "SinDinero" } } },
								{ S = "Narrador", T = "Omar comparte el suyo contigo sin decir nada.", Shot = "General", If = { Flags = { "SinDinero" } } },
								{ S = "Narrador", T = "Algunas amistades empiezan con cosas pequeñas.", Shot = "Reaccion:Yo" },
							},
						},
					},
				},
			},
		},
		Permiso = {
			Lines = {
				{
					S = "Yo",
					T = "¿Puedo ir al parque con mis amigos? ¡Porfa!",
					If = { Choices = { Permiso = "Casa" } },
					Effects = { Scene = "Cole03_G19_Musica" },
				},
				{ S = "Yo", T = "Volvemos antes de cenar.", If = { Choices = { Permiso = "Casa" } } },
				{ S = "Familia", T = "¿Amigos?", To = "Yo", Shot = "Reaccion:Familia", If = { Choices = { Permiso = "Casa" } } },
				{
					S = "Familia",
					T = "¿Ya tienes amigos? Eso es maravilloso.",
					To = "Yo",
					Shot = "PrimerPlano:Familia",
					Pause = 0.9,
					If = { Choices = { Permiso = "Casa" } },
				},
				{ S = "Familia", T = "Claro que sí. Antes de cenar.", To = "Yo", Shot = "Medio:Familia", If = { Choices = { Permiso = "Casa" } } },
				{ S = "Familia", T = "Y nada de subirse a los árboles.", To = "Yo", Pause = 0.9, If = { Choices = { Permiso = "Casa" } } },
				{ S = "Yo", T = "Vale.", Shot = "Reaccion:Yo", If = { Choices = { Permiso = "Casa" } } },
				{ S = "Familia", T = "Lo digo porque te conozco.", To = "Yo", If = { Choices = { Permiso = "Casa" } } },
			},
		},
		PrePartido = {
			Lines = {
				{ S = "Andres", T = "Partido amistoso. A-MIS-TO-SO.", To = "Yo", Shot = "General", Effects = { Scene = "Cole03_G14_Musica" } },
				{ S = "Andres", T = "Sin empujones.", To = "Yo", Shot = "Reaccion:Nico" },
				{ S = "Andres", T = "Sin trampas.", To = "Yo", Shot = "Reaccion:Bruno" },
				{ S = "Andres", T = "Y dando la mano al final. ¿Entendido?", To = "Yo", Shot = "General" },
				{ S = "Narrador", T = "Todos: «Sí.»" },
				{ S = "Bruno", T = "Sí. Claro.", To = "Yo", Shot = "PrimerPlano:Bruno" },
				{ S = "Bruno", T = "Mirad quién viene. El que se chiva a los profes.", To = "Yo", If = { Flags = { "AvisasteALucia" } } },
				{ S = "Ruben", T = "Suerte. Pero no mucha.", To = "Yo", Shot = "Reaccion:Ruben", If = { Flags = { "Ruben_Perdonado" } } },
				{ S = "Ruben", T = "Hoy me toca ganar. Por lo de la gorra.", To = "Yo", If = { Flags = { "BromaDeVuelta" } } },
				{ S = "Bruno", T = "Esto va a ser muy fácil.", To = "Yo", Shot = "PrimerPlano:Bruno" },
				{ S = "Bruno", T = "Cinco minutos y os vais llorando.", To = "Yo" },
				{ S = "Hugo", T = "Bruno… Es solo un partido.", To = "Yo", Shot = "Reaccion:Hugo" },
				{ S = "Nico", T = "¿Dónde juegas?", To = "Yo", Shot = "PrimerPlano:Bruno" },
				{
					Ask = "Elige tu posición",
					Options = {
						{
							T = "«Delante: ¡a marcar goles!»",
							Effects = { Choice = { Posicion = "Delantero" }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Nico", T = "¡Dúo de ataque! Tú y yo. Que tiemble Álex.", To = "Yo" },
								{ S = "Alex", T = "Estoy aquí.", To = "Yo" },
								{ S = "Nico", T = "Ya. Era una forma de hablar.", To = "Yo" },
							},
						},
						{
							T = "«Defensa: que no pase nadie.»",
							Effects = { Choice = { Posicion = "Defensa" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Sara", T = "Un muro humano. Sólido. Me gusta.", To = "Yo" } },
						},
						{
							T = "«Portería: que Omar descanse.»",
							Effects = { Choice = { Posicion = "Portero" }, Rel = { Omar = 4 } },
							Then = {
								{ S = "Omar", T = "¡Gracias! Yo defenderé el bocadillo.", To = "Yo" },
								{ S = "Sara", T = "Eso sí que parece una misión importante.", To = "Yo", Shot = "Reaccion:Sara" },
								{ S = "Andres", T = "¡Preparados…! ¡PRRRRIII!", To = "Yo" },
							},
						},
					},
				},
			},
		},
		Quedada = {
			Lines = {
				{ S = "Nico", T = "¡Estamos todos!", To = "Yo", Shot = "General", Effects = { Scene = "Cole03_G20_Musica" } },
				{ S = "Omar", T = "Yo me he traído merienda. Por si acaso.", To = "Yo" },
				{ S = "Sara", T = "Has traído merienda para cuatro horas.", To = "Yo" },
				{ S = "Omar", T = "Por si acaso.", To = "Yo" },
				{ S = "Nico", T = "¡Al parque!", To = "Yo", Shot = "Reaccion:Mateo" },
				{ S = "Narrador", T = "Por primera vez… no vas solo.", Shot = "General" },
			},
		},
		Suenos = {
			Lines = {
				{ S = "Sara", T = "Pregunta importante.", To = "Yo", Shot = "General", Effects = { Scene = "Cole03_G24_Musica" } },
				{ S = "Sara", T = "¿Qué queréis ser de mayores?", To = "Yo", Shot = "General" },
				{ S = "Nico", T = "Futbolista. Obvio. Luego entrenador.", To = "Yo" },
				{ S = "Nico", T = "Luego presidente del club.", To = "Yo" },
				{ S = "Omar", T = "Dibujante de cómics.", To = "Yo" },
				{ S = "Omar", T = "De los que salen en las tiendas.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Con mi nombre en la portada.", To = "Yo" },
				{ S = "Sara", T = "Yo, astronauta. O científica. O las dos.", To = "Yo" },
				{ S = "Sara", T = "Científica en el espacio.", To = "Yo" },
				{ S = "Mateo", T = "Yo… Veterinario.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Mateo", T = "Para cuidar animales que nadie quiere.", To = "Yo", Shot = "PrimerPlano:Mateo" },
				{ S = "Sara", T = "Me gusta.", To = "Yo", Shot = "Reaccion:Sara" },
				{ S = "Sara", T = "¿Y tú, {nombre}?", To = "Yo", Shot = "Medio:Sara" },
				{
					Ask = "¿Qué quieres ser de mayor?",
					Options = {
						{
							T = "«Salvar vidas en un hospital.»",
							Effects = { Choice = { SuenoInfancia = "Medicina" }, Traits = { Empatia = 1 } },
							Then = { { S = "Mateo", T = "Tú curas a las personas. Yo a los animales. Somos un equipo.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
						{
							T = "«Inventar cosas que no existen.»",
							Effects = { Choice = { SuenoInfancia = "Ingenieria" }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Sara", T = "¡Me haces un cohete! ¡Y yo lo piloto!", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
						{
							T = "«Defender a la gente en los juzgados.»",
							Effects = { Choice = { SuenoInfancia = "Derecho" }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Nico", T = "Pues ya puedes empezar.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } },
								{ S = "Nico", T = "Defiéndeme de los deberes.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } },
							},
						},
						{
							T = "«Tener mi propia tienda o empresa.»",
							Effects = { Choice = { SuenoInfancia = "Economia" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Omar", T = "Que sea una tienda de bocadillos. Yo te hago el cartel.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
						{
							T = "«Ser artista.»",
							Effects = { Choice = { SuenoInfancia = "Arte" }, Traits = { Creatividad = 1 } },
							Then = { { S = "Omar", T = "¡Lo sabía! Haremos un cómic juntos.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
						{
							T = "«Deportista profesional.»",
							Effects = { Choice = { SuenoInfancia = "Deporte" }, Traits = { Deportividad = 1 } },
							Then = {
								{ S = "Nico", T = "¡En mi equipo! ¡Fichado!", To = "Yo", If = { Flags = { "AyudasteAMateo" } } },
								{ S = "Narrador", T = "Ninguno de vosotros lo sabe todavía.", Shot = "General" },
								{ S = "Narrador", T = "Pero dentro de muchos años…", Pause = 0.9 },
								{ S = "Narrador", T = "recordarás esta conversación.", Shot = "PrimerPlano:Yo" },
							},
						},
					},
				},
			},
		},
		Timbre = {
			Lines = {
				{ S = "Lucia", T = "Y por eso las plantas…", To = "Yo", Shot = "General", Effects = { Scene = "Cole03_G4_Musica" } },
				{ S = "Lucia", T = "Nico.", To = "Yo", Shot = "Reaccion:Lucia" },
				{ S = "Nico", T = "¿Sí?", To = "Yo", Shot = "Reaccion:Nico" },
				{ S = "Lucia", T = "El balón no se lanza dentro del aula.", To = "Yo" },
				{ S = "Nico", T = "¡Si todavía no lo he sacado!", To = "Yo" },
				{ S = "Lucia", T = "Exactamente. Y por eso sé que vas a intentarlo.", To = "Yo", Shot = "PPP:Lucia" },
				{ S = "Nico", T = "¡Vamos!", To = "Yo", Shot = "Reaccion:Nico", A = "Happy" },
			},
		},
	},
	Mission = { Set = { MomentKey = "Ya tienes tu grupo de amigos." } },
	Scenes = {
		Cole03_G12_Musica = { Light = true, Duration = 39.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole03_G13_Fin = {
			Light = true,
			Duration = 4.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Bruno", Npc = "Bruno" } } },
				Dialogue = { { At = 0.4, S = "Bruno", T = "Vaya. Habéis conseguido reunir gente.", To = "Yo" } },
			},
		},
		Cole03_G14_Musica = { Light = true, Duration = 40.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole03_G15_Entra = {
			Light = true,
			Duration = 18,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Hugo", Npc = "Hugo" } },
					{ At = 0, Use = { Key = "Bruno", Npc = "Bruno" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Nico", T = "¡Aquí!", To = "Yo", If = { Choices = { Posicion = "Portero" } } },
					{ At = 2.4, S = "Sara", T = "¡A la izquierda!", To = "Yo" },
					{ At = 4.5, S = "Omar", T = "¡Cuidado con mi bocadillo!", To = "Yo" },
					{ At = 7.1, S = "Bruno", T = "¡Vamos!", To = "Yo" },
					{ At = 9.1, S = "Hugo", T = "Toma.", To = "Yo" },
					{ At = 11.2, S = "Nico", T = "¡GOLAZO!", To = "Yo", If = { Flags = { "PartidoGanado" } } },
					{ At = 13.2, S = "Narrador", T = "Un partido no se decide por una jugada. Sigue jugando.", If = { Flags = { "PartidoPerdido" } } },
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
		Cole03_G16_Musica = { Light = true, Duration = 53, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole03_G17_Fin = {
			Light = true,
			Duration = 11.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } }, { At = 0, Use = { Key = "Nico", Npc = "Nico" } } },
				Dialogue = {
					{ At = 3.8, S = "Nico", T = "Hay un parque cerca. Canasta. Columpios. Y helados.", To = "Yo" },
					{ At = 7.8, S = "Omar", T = "Has dicho la palabra mágica. Helados.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
				Titles = { { At = 0.4, Duration = 3.2, Text = "Por la tarde…" } },
			},
		},
		Cole03_G19_Musica = { Light = true, Duration = 26.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole03_G1_Fin = {
			Light = true,
			Duration = 22.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Lucia", Npc = "Lucia" } } },
				Dialogue = {
					{ At = 3.8, S = "Narrador", T = "Una semana puede parecer poco." },
					{ At = 6.6, S = "Narrador", T = "Pero a los siete años…" },
					{ At = 9.9, S = "Narrador", T = "una semana es tiempo suficiente para empezar a sentir que un lugar es tuyo." },
					{ At = 15.1, S = "Lucia", T = "Muy bien. Hoy vamos a hablar de algo que estáis viendo todos los días.", To = "Yo" },
					{ At = 20.1, S = "Lucia", T = "Las plantas.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 11.1, Intensity = "Descubrimiento" } },
				Titles = { { At = 0.4, Duration = 3.2, Text = "Una semana después…" } },
			},
		},
		Cole03_G20_Musica = { Light = true, Duration = 19.5, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole03_G21_Entra = {
			Light = true,
			Duration = 16.5,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Mateo", Npc = "Mateo" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Nico", T = "¡Por aquí!", To = "Yo" },
					{ At = 2.4, S = "Sara", T = "Esa no es la ruta más corta.", To = "Yo" },
					{ At = 5.1, S = "Nico", T = "Es la más divertida.", To = "Yo" },
					{ At = 7.4, S = "Omar", T = "Yo voto por la que tenga sombra.", To = "Yo" },
					{ At = 10.3, S = "Mateo", T = "En mi otro cole había un parque así.", To = "Yo" },
					{ At = 13.4, S = "Mateo", T = "Pero nunca íbamos todos.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole03_G24_Musica = { Light = true, Duration = 40.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole03_G25_Musica = { Light = true, Duration = 24.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole03_G26_Musica = { Light = true, Duration = 23, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole03_G27 = {
			Skippable = true,
			Duration = 60.3,
			Anchors = {
				Grieta = "Rift",
				L_SpotGrupoDeportistas = "Place:SpotGrupoDeportistas",
				L_SpotParqueCanasta = "Place:SpotParqueCanasta",
				Sitio = "Place:SpotParqueReunion",
				Yo = "Player",
			},
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
					{ At = 0, Use = { Key = "Mateo", Npc = "Mateo" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 4.55, Mood = { Mood = "Joy", Key = "Omar" } },
					{ At = 12.55, Mood = { Mood = "Joy", Key = "Mateo" } },
				},
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:Sitio" },
					{ At = 2.4, Duration = 2, Shot = "Medio:Nico" },
					{ At = 4.45, Duration = 2, Shot = "Reaccion:Omar" },
					{ At = 6.45, Duration = 2, Shot = "Reaccion:Sara" },
					{ At = 8.45, Duration = 2, Shot = "Reaccion:Mateo" },
					{ At = 10.45, Duration = 2, Shot = "Hombro:Yo>Mateo" },
					{ At = 12.45, Duration = 2, Shot = "Reaccion:Mateo" },
					{ At = 14.45, Duration = 2, Shot = "General:Sitio" },
					{ At = 16.45, Duration = 3.4, Shot = "General:L_SpotGrupoDeportistas" },
					{ At = 19.85, Duration = 5.1, Shot = "General:Sitio" },
					{ At = 24.98, Duration = 4.7, Shot = "General:Sitio" },
					{ At = 29.65, Duration = 12.5, Shot = "General:L_SpotParqueCanasta" },
					{ At = 42.11, Duration = 2, Shot = "General:L_SpotParqueCanasta" },
					{ At = 44.11, Duration = 2, Shot = "General:Sitio" },
					{
						At = 46.11,
						Duration = 2,
						To = { "Yo", V(1.3, 2.3, 3.3), true },
						Cut = "Dip",
						Fov = { 70, 60 },
						From = { "Yo", V(1.4, 1.7, 3.6), true },
						Look = { "Yo", V(0, 1.6, 0) },
						LookTo = { "Grieta" },
					},
					{
						At = 48.11,
						Duration = 4.6,
						To = { "Sitio", V(25, 64, 44) },
						Cut = "Dip",
						From = { "Sitio", V(-45, 60, 50) },
						Look = { "Sitio", V(30, 0, 0) },
						Shake = 0.15,
					},
					{ At = 52.73, Duration = 6.9, Shot = "General:Sitio" },
				},
				Dialogue = {
					{ At = 2.4, S = "Nico", T = "¡{grupo}!", To = "Yo" },
					{ At = 20.7, S = "Narrador", T = "Un día normal. Un parque. Cinco niños. Y una fotografía." },
					{ At = 25, S = "Narrador", T = "En ese momento… ninguno sabe lo importante que será esta imagen." },
					{ At = 29.7, S = "Narrador", T = "Pero algún día… mirarás atrás." },
					{ At = 32.4, S = "Nico", T = "¿Te acuerdas de cuando éramos los Imparables?", To = "Yo" },
					{ At = 36.1, S = "Omar", T = "Todavía tengo el dibujo.", To = "Yo" },
					{ At = 38.5, S = "Sara", T = "Técnicamente seguimos siendo los Imparables.", To = "Yo" },
					{ At = 48.1, S = "Narrador", T = "Algunas amistades duran un verano. Otras duran años. Y algunas…" },
					{ At = 52.7, S = "Narrador", T = "aunque cambien… nunca desaparecen del todo." },
				},
				Music = { { At = 0, Intensity = "Intima" } },
				Titles = { { At = 16.5, Duration = 3.2, Text = "📸 ¡Patata!" }, { At = 56.2, Duration = 3.2, Text = "EL GRUPO — COMPLETADA" } },
			},
			Sting = "Momento",
		},
		Cole03_G3_Entra = {
			Light = true,
			Duration = 26.5,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Lucia", Npc = "Lucia" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Lucia", T = "¿Por qué creéis que las plantas buscan la luz?", To = "Yo" },
					{ At = 4.1, S = "Sara", T = "Porque realizan fotosíntesis.", To = "Yo" },
					{ At = 6.8, S = "Sara", T = "Técnicamente utilizan la luz para producir energía.", To = "Yo" },
					{ At = 10.8, S = "Nico", T = "Yo también lo sabía.", To = "Yo" },
					{ At = 13, S = "Sara", T = "No lo sabías.", To = "Yo" },
					{ At = 15.1, S = "Nico", T = "Lo estaba pensando.", To = "Yo" },
					{ At = 17.3, S = "Omar", T = "Yo solo sé que esta tiene hambre.", To = "Yo" },
					{ At = 20.2, S = "Lucia", T = "Las plantas no comen bocadillos, Omar.", To = "Yo" },
					{ At = 23.5, S = "Omar", T = "Todavía no lo sabemos.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole03_G4_Musica = { Light = true, Duration = 22.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole03_G5_Entra = {
			Light = true,
			Duration = 11.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Nico", T = "¡{nombre}!", To = "Yo" },
					{ At = 2.4, S = "Omar", T = "Ven aquí.", To = "Yo" },
					{ At = 4.5, S = "Sara", T = "¡Rápido!", To = "Yo" },
					{ At = 7.5, S = "Narrador", T = "Tres amigos. Tres planes. Y solo un recreo." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole03_G6_Entra = {
			Light = true,
			Duration = 56,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Nico", T = "¡Calienta! Hoy hay partido.", To = "Yo" },
					{ At = 3, S = "Nico", T = "Jugamos contra los de Bruno.", To = "Yo" },
					{ At = 5.7, S = "Nico", T = "Me falta alguien bueno.", To = "Yo" },
					{ At = 9, S = "Nico", T = "Y tú eres gente buena. Eso creo.", To = "Yo" },
					{ At = 12, S = "Nico", T = "Pero antes… Tres penaltis.", To = "Yo" },
					{ At = 14.5, S = "Nico", T = "Si metes dos, eres titular.", To = "Yo" },
					{
						At = 17.2,
						S = "Nico",
						T = "Y encima dijiste que te gusta el fútbol. Me acuerdo de TODO.",
						To = "Yo",
						If = { Choices = { Gusto = "Futbol" } },
					},
					{ At = 21.6, S = "Omar", T = "Ven.", To = "Yo" },
					{ At = 23.7, S = "Omar", T = "Lucía me deja pintar esta parte.", To = "Yo" },
					{ At = 26.6, S = "Omar", T = "El cielo. El colegio. Y nosotros.", To = "Yo" },
					{ At = 29.5, S = "Omar", T = "Tú dibujas una parte. Yo otra. Trabajo en equipo. Y luego merendamos. Tengo hambre.", To = "Yo" },
					{ At = 35.3, S = "Sara", T = "¡Rápido!", To = "Yo" },
					{ At = 37.3, S = "Sara", T = "He visto un escarabajo rarísimo.", To = "Yo" },
					{ At = 40.2, S = "Sara", T = "Verde. Brillante. Y no aparece en mi libro.", To = "Yo" },
					{ At = 43.7, S = "Sara", T = "Puede ser una especie nueva.", To = "Yo" },
					{ At = 47.3, S = "Sara", T = "Si lo descubrimos nosotros…", To = "Yo" },
					{ At = 50, S = "Sara", T = "le ponemos nuestro nombre.", To = "Yo" },
					{ At = 52.5, S = "Sara", T = "«Escarabajus Sara-y-{nombre}».", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole03_G7_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, If = { Choices = { Invitacion = "Nico" } }, Use = { Key = "Nico", Npc = "Nico" } } },
				Dialogue = {
					{ At = 0.4, S = "Nico", T = "Dos de tres. Si metes dos… titular.", To = "Yo", If = { Choices = { Invitacion = "Nico" } } },
					{ At = 3.5, S = "Nico", T = "¡Lo sabía!", To = "Yo", If = { Choices = { Invitacion = "Nico" }, Flags = { "Cole03_P7_Gana" } } },
					{
						At = 5.5,
						S = "Nico",
						T = "Bueno. Has venido a jugar. Eso es lo importante.",
						To = "Yo",
						If = { Choices = { Invitacion = "Nico" }, Flags = { "Cole03_P7_Pierde" } },
					},
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Cole03_G1_Fin" } },
		["10"] = { Set = { Text = "¡Se ha ido volando hacia la cancha!" } },
		["11"] = { Set = { Text = "¡Ahora está junto al edificio!" } },
		["13"] = { Effects = { Scene = "Cole03_G13_Fin" }, Set = { Text = "Ve al campo de fútbol" } },
		["14"] = { Effects = { Scene = "Cole03_G15_Entra" } },
		["15"] = { Set = { Text = "¡Partido contra el equipo de Bruno!" } },
		["17"] = { Effects = { Scene = "Cole03_G17_Fin" } },
		["18"] = { Set = { Text = "Pide permiso en casa" } },
		["2"] = { Effects = { Scene = "Cole03_G3_Entra" }, Set = { Text = "Ve a clase" } },
		["20"] = { Effects = { Scene = "Cole03_G21_Entra" } },
		["21"] = { Set = { Text = "Ve al parque con tus amigos" } },
		["22"] = { Set = { Text = "Pasa la tarde en el parque" } },
		["23"] = { Set = { Text = "Siéntate con tus amigos" } },
		["27"] = { Set = { Id = "Cole03_G27" } },
		["4"] = { Effects = { Scene = "Cole03_G5_Entra" } },
		["5"] = { Effects = { Scene = "Cole03_G6_Entra" }, Set = { Text = "Sal al recreo" } },
		["6"] = { Effects = { Scene = "Cole03_G7_Entra" }, Set = { Text = "¿Con quién vas?" } },
		["7"] = {
			Set = {
				Text = "Calienta: tres penaltis",
				Lose = { Flags = { "Cole03_P7_Pierde" }, Rel = { Nico = 2 } },
				Win = { Flags = { "Cole03_P7_Gana" }, Rel = { Nico = 4 }, Traits = { Deportividad = 1 } },
			},
		},
		["8"] = { Set = { Text = "Pinta el mural con Omar" } },
		["9"] = { Set = { Text = "Sigue al escarabajo" } },
	},
}
