-- GUION REESCRITO de Cole01_PrimerDia (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Cole01_PrimerDia.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Cole01_PrimerDia
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Cole01_PrimerDia.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Cole01_PrimerDia.md",
	Dialogues = {
		Armario = {
			Lines = {
				{
					Ask = "¿Qué te pones?",
					Options = {
						{
							T = "«Camiseta de dinosaurios.»",
							Effects = { Choice = { Ropa = "Dinosaurios" }, Traits = { Humor = 1 } },
							Then = { { S = "Yo", T = "El T-Rex me da poderes." }, { S = "Yo", T = "Es un hecho científico.", Pause = 0.9 } },
						},
						{
							T = "«Sudadera azul del colegio.»",
							Effects = { Choice = { Ropa = "Sudadera" }, Traits = { Responsabilidad = 1 } },
							Then = { { S = "Yo", T = "Con el escudo del cole." }, { S = "Yo", T = "Así ya parezco de allí." } },
						},
						{
							T = "«Camisa elegante.»",
							Effects = { Choice = { Ropa = "Camisa" } },
							Then = { { S = "Yo", T = "Impecable. Aunque pica un poquito el cuello." } },
						},
					},
				},
			},
		},
		Cena = {
			Lines = {
				{
					S = "Familia",
					T = "¡Por fin! Siéntate. He hecho macarrones.",
					To = "Yo",
					Shot = "Reaccion:Familia",
					Effects = { Scene = "Cole01_G28_Musica" },
				},
				{ S = "Familia", T = "¿Y bien? ¿Qué tal tu primer día?", To = "Yo", Shot = "Hombro:Yo>Familia" },
				{ S = "Abu", T = "Cuéntanoslo todo. Con detalles.", To = "Yo", Shot = "PrimerPlano:Abu" },
				{ S = "Abu", T = "Que yo ya no me entero de nada.", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "Y lo de llegar tarde…", To = "Yo", If = { Flags = { "LlegasTarde" } } },
				{
					S = "Familia",
					T = "Mañana salimos cinco minutos antes. Los cinco minutitos.",
					To = "Yo",
					Shot = "Reaccion:Yo",
					If = { Flags = { "LlegasTarde" } },
				},
				{
					S = "Abu",
					T = "¿Y los dinosaurios? ¿Han causado sensación?",
					To = "Yo",
					Shot = "Reaccion:Abu",
					A = "Happy",
					If = { Choices = { Ropa = "Dinosaurios" } },
				},
				{
					Ask = "¿Qué cuentas primero?",
					Options = {
						{
							T = "«¡He hecho un amigo! Se llama Mateo.»",
							If = { Flags = { "AyudasteAMateo" } },
							Effects = { Rel = { Familia = 3 } },
							Then = { { S = "Abu", T = "¿Ves? El que ayuda nunca está solo.", To = "Yo" } },
						},
						{
							T = "«Me he sentado con Sara. ¡Sabe muchísimo!»",
							If = { Choices = { Asiento = "Sara" } },
							Then = {
								{ S = "Familia", T = "Una buena compañera de pupitre vale oro.", To = "Yo" },
								{ S = "Familia", T = "Ya lo verás en los exámenes.", To = "Yo" },
							},
						},
						{
							T = "«Nico dice que mañana juego al fútbol con ellos.»",
							If = { Choices = { GrupoRecreo = "Deportistas" } },
							Then = { { S = "Familia", T = "Pues habrá que lavar esas zapatillas.", To = "Yo" } },
						},
						{
							T = "«Un niño que se llama Omar me ha dibujado con capa.»",
							If = { Choices = { GrupoRecreo = "Artistas" } },
							Then = { { S = "Abu", T = "¡Un superhéroe en la familia! Ya era hora.", To = "Yo" } },
						},
						{
							T = "«Hemos investigado si las hormigas duermen.»",
							If = { Choices = { GrupoRecreo = "Estudiantes" } },
							Then = { { S = "Abu", T = "¿Y duermen? ¿No? ¿Todavía no lo sabéis? Qué emoción.", To = "Yo" } },
						},
						{
							T = "«Ha sido un rollo.»",
							Effects = { Traits = { Humor = 1 } },
							Then = {
								{ S = "Yo", T = "Bueno… No tanto.", Pause = 0.9 },
								{ S = "Familia", T = "«No tanto» en idioma de niño significa «me lo he pasado genial».", To = "Yo" },
								{ S = "Familia", T = "¿Y ese niño que estaba solo?", To = "Yo", Shot = "Reaccion:Yo", If = { Flags = { "IgnorasteAMateo" } } },
								{
									S = "Familia",
									T = "¿Nadie le ayudó? Mañana, si lo ves solo… Ve con él. ¿Vale? Qué orgullo. Primer día. Superado.",
									To = "Yo",
									Shot = "PrimerPlano:Yo",
								},
								{ S = "Narrador", T = "Un día parece pequeñ{o/a} cuando lo estás viviendo. Pero algunos días…", Shot = "PrimerPlano:Yo" },
								{ S = "Narrador", T = "empiezan cosas que tardan años en terminar.", Pause = 0.9 },
								{ S = "Narrador", T = "Primer día de colegio. Completado. Y esto…", Shot = "General" },
								{ S = "Narrador", T = "no ha hecho más que empezar.", Shot = "General" },
							},
						},
					},
				},
				{ S = "Narrador", T = "Mañana volverás. Y algunas de las personas que has conocido hoy… todavía estarán ahí.", Shot = "General" },
			},
		},
		ConoceLucia = {
			Lines = {
				{ S = "Lucia", T = "Hola.", To = "Yo", Shot = "Reaccion:Lucia", Effects = { Scene = "Cole01_G10_Musica" } },
				{ S = "Lucia", T = "Tú debes de ser {nombre}. Soy Lucía. Tu tutora de 1.º A.", To = "Yo", Shot = "Medio:Lucia" },
				{ S = "Lucia", T = "Ya estás aquí. Buena señal.", To = "Yo", If = { NotFlags = { "LlegasTarde" } } },
				{ S = "Lucia", T = "Un poquito tarde, ¿eh? Hoy te lo perdono.", To = "Yo", Shot = "PrimerPlano:Lucia", If = { Flags = { "LlegasTarde" } } },
				{ S = "Lucia", T = "Mañana, un poco antes.", To = "Yo", If = { Flags = { "LlegasTarde" } } },
				{ S = "Ramon", T = "Apuntado en mi libreta, Lucía.", To = "Yo", If = { Flags = { "LlegasTarde" } } },
				{ S = "Lucia", T = "Antes de empezar…", To = "Yo", Shot = "Reaccion:Lucia" },
				{ S = "Lucia", T = "Tengo una misión para ti. Conoce el colegio.", To = "Yo", Shot = "Hombro:Yo>Lucia" },
				{ S = "Lucia", T = "Biblioteca. Comedor. Patio. Gimnasio. Campo. Todo.", To = "Yo", Shot = "General" },
				{ S = "Lucia", T = "Por el camino encontrarás gente. Y después…", To = "Yo" },
				{ S = "Lucia", T = "Encuentra tu aula tú sol{o/a}. 1.º A.", To = "Yo", Shot = "PrimerPlano:Lucia" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«¡Hecho! Me encanta explorar.»",
							Effects = { Rel = { Lucia = 3 }, Traits = { Valentia = 1 } },
							Then = { { S = "Lucia", T = "Eso quiero ver. Suerte.", To = "Yo" } },
						},
						{
							T = "«¿Y si me pierdo?»",
							Effects = { Rel = { Lucia = 3 } },
							Then = {
								{ S = "Lucia", T = "Entonces preguntas. Preguntar no es de perdidos. Es de listos.", To = "Yo" },
								{ S = "Andres", T = "¿Yo, tu tutor? ¡Ojalá! Soy Andrés. Educación Física.", To = "Yo" },
								{ S = "Andres", T = "Me reconocerás por el silbato.", To = "Yo" },
								{ S = "Andres", T = "Y no corras por el pasillo. Todavía.", To = "Yo" },
								{ S = "Marta", T = "Hola, cielo. Soy Marta.", To = "Yo" },
								{ S = "Marta", T = "Ese piano del fondo es mío. ¿Buscas a Lucía?", To = "Yo", Shot = "General" },
								{ S = "Marta", T = "La del jersey amarillo. No tiene pérdida.", To = "Yo" },
							},
						},
					},
				},
			},
		},
		DaniBalon = {
			Lines = {
				{ S = "Dani", T = "¡Eh! ¡EH!", To = "Yo", Shot = "Seguir:Dani", Effects = { Scene = "Cole01_G5_Musica" } },
				{ S = "Dani", T = "¡Ese es mi balón! ¿Me lo pasas? ¡Porfa, porfa, porfa!", To = "Yo", Shot = "Medio:Dani" },
				{ S = "Familia", T = "Venga. Pásaselo. Pero con cuidado. Es pequeñito.", To = "Yo", If = { Choices = { Acompanante = "Familia" } } },
			},
		},
		DaniGracias = {
			Lines = {
				{ S = "Dani", T = "¡HALA!", To = "Yo", If = { Flags = { "PaseADani" } }, Effects = { Scene = "Cole01_G7_Musica" } },
				{ S = "Dani", T = "¡Qué pase! ¡Eres como los de la tele!", To = "Yo", Shot = "Reaccion:Yo", If = { Flags = { "PaseADani" } } },
				{
					S = "Dani",
					T = "Jajaja. Se ha ido a la farola. No pasa nada. ¡Ya lo cojo yo!",
					To = "Yo",
					Shot = "General",
					If = { Flags = { "FallastePase" } },
				},
				{ S = "Dani", T = "Me llamo Dani. Tengo cinco años y MEDIO.", To = "Yo", Shot = "Medio:Dani" },
				{
					S = "Dani",
					T = "Mi hermano Mateo también empieza hoy en tu cole. Es un poco… vergonzoso. No habla casi.",
					To = "Yo",
					Shot = "PrimerPlano:Dani",
				},
				{ S = "Dani", T = "Si lo ves… dile que Dani dice que se ría más.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Dani", T = "¡Adiós!", To = "Yo", Shot = "Seguir:Dani" },
				{ S = "Narrador", T = "Primer nombre nuevo. Primer encuentro.", Shot = "Reaccion:Yo" },
				{ S = "Narrador", T = "Y todavía no sabes que Mateo será importante." },
			},
		},
		Desayuno = {
			Lines = {
				{ S = "Familia", T = "Siéntate. Que se enfría.", To = "Yo", Shot = "General" },
				{
					Ask = "Para desayunar…",
					Options = {
						{
							T = "«Tostadas con tomate.»",
							Effects = { Needs = { Energy = 10, Hunger = 45 } },
							Then = { { S = "Familia", T = "Como tu abu. Con su chorrito de aceite.", To = "Yo" } },
						},
						{ T = "«Cereales con leche.»", Effects = { Needs = { Energy = 15, Hunger = 40 } }, Then = { { S = "Yo", T = "Los del dinosaurio." } } },
						{
							T = "«Fruta… y un poquito de chocolate.»",
							Effects = { Needs = { Energy = 20, Hunger = 35 }, Traits = { Humor = 1 } },
							Then = { { S = "Familia", T = "Un poquito. POQUITO. Y bebe algo.", To = "Yo" }, { S = "Familia", T = "En el colegio se corre mucho.", To = "Yo" } },
						},
					},
				},
			},
		},
		Despertar = {
			Lines = {
				{ S = "Familia", T = "Buenos días, {nombre}.", To = "Yo", Shot = "Seguir:Familia", Effects = { Scene = "Cole01_G1_Musica" } },
				{ S = "Familia", T = "Arriba. Hoy empieza el colegio.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Yo", T = "¿Hoy?", Shot = "PrimerPlano:Yo" },
				{ S = "Familia", T = "Hoy.", To = "Yo" },
				{ S = "Familia", T = "Mochila nueva. Profe nueva. Compañeros nuevos.", To = "Yo", Shot = "Medio:Familia", A = "Happy" },
				{ S = "Familia", T = "Y probablemente alguna aventura que no tenemos prevista.", To = "Yo" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Cinco minutitos más…»",
							Effects = { Traits = { Humor = 1 } },
							Then = {
								{ S = "Familia", T = "Cinco minutitos… Eso decía yo a tu edad.", To = "Yo" },
								{ S = "Familia", T = "Y siempre llegaba tarde.", To = "Yo" },
							},
						},
						{ T = "«¡Ya voy! ¡Ya voy!»", Effects = { Traits = { Responsabilidad = 1 } }, Then = { { S = "Familia", T = "Así me gusta.", To = "Yo" } } },
						{
							T = "«¿Y si no voy? Me duele… la tripa.»",
							Effects = { Traits = { Humor = 1 } },
							Then = {
								{ S = "Familia", T = "Qué casualidad. Justo hoy. Eso son nervios.", To = "Yo", Shot = "PrimerPlano:Familia" },
								{ S = "Familia", T = "Se pasan cuando llegas.", To = "Yo" },
							},
						},
					},
				},
			},
		},
		Entrada = {
			Lines = {
				{ S = "Narrador", T = "Mochilas. Abrazos. Gritos.", Shot = "General", Effects = { Scene = "Cole01_G9_Musica" } },
				{ S = "Narrador", T = "Y muchísimas caras que todavía no conoces." },
				{ S = "Ramon", T = "¡Buenos días! ¡Los mayores por la izquierda!", To = "Yo", Shot = "Medio:Ramon" },
				{ S = "Ramon", T = "¡Los de primero por la puerta grande!", To = "Yo" },
				{ S = "Ramon", T = "Uy. ¿Y tú?", To = "Yo", Shot = "Reaccion:Ramon" },
				{ S = "Ramon", T = "Cara nueva. Soy Ramón. El conserje.", To = "Yo", Shot = "Medio:Ramon" },
				{ S = "Ramon", T = "Si algo se rompe, se pierde o se atasca… Ramón.", To = "Yo" },
				{ S = "Ramon", T = "¿Llegando tarde el primer día?", To = "Yo", If = { Flags = { "LlegasTarde" } } },
				{
					S = "Ramon",
					T = "Tranquil{o/a}. Lo apunto en mi libreta de secretos. Jejeje.",
					To = "Yo",
					Shot = "PrimerPlano:Ramon",
					If = { Flags = { "LlegasTarde" } },
				},
				{
					S = "Familia",
					T = "Bueno… Aquí te dejo. Pásalo genial. Y me lo cuentas TODO.",
					To = "Yo",
					Shot = "Hombro:Yo>Familia",
					If = { Choices = { Acompanante = "Familia" } },
				},
				{ S = "Ramon", T = "Tu tutora es Lucía. Jersey amarillo.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Ramon", T = "Y una risa que se oye desde aquí.", To = "Yo" },
			},
		},
		FinDeClases = {
			Lines = {
				{ S = "Narrador", T = "Más clases.", Shot = "General", Effects = { Scene = "Cole01_G26_Musica" } },
				{ S = "Narrador", T = "Más nombres.", Shot = "General" },
				{ S = "Narrador", T = "Y más preguntas de las que tenías esta mañana.", Shot = "General" },
				{ S = "Lucia", T = "¡Hasta mañana! Y recordad…", To = "Yo", Shot = "Medio:Lucia" },
				{ S = "Lucia", T = "Mañana, con la mochila.", To = "Yo", Pause = 0.9 },
				{ S = "Ramon", T = "¡O que la pierde! Jejeje.", To = "Yo", Shot = "Reaccion:Ramon" },
			},
		},
		Grupo_Artistas = {
			Lines = {
				{ S = "Omar", T = "Espera. No te muevas. Te estoy dibujando.", To = "Yo" },
				{ S = "Vega", T = "Omar dibuja a todo el mundo.", To = "Yo" },
				{ S = "Vega", T = "Es su forma de decir hola.", To = "Yo" },
				{ S = "Omar", T = "Ya está. Te he puesto una capa.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Quedas mejor con capa.", To = "Yo" },
				{ S = "Omar", T = "¿Tú también dibujas? Mañana te dejo mi rotulador dorado.", To = "Yo", If = { Choices = { Gusto = "Dibujar" } } },
				{
					Ask = "¿Qué dices?",
					Options = {
						{
							T = "«¡Hala! ¿Me lo regalas?»",
							Effects = { Rel = { Omar = 6 } },
							Then = { { S = "Omar", T = "Cuando lo termine. Los dibujos buenos se terminan despacio.", To = "Yo" } },
						},
						{
							T = "«¿Y a Vega qué le has puesto?»",
							Effects = { Rel = { Vega = 5 }, Traits = { Humor = 1 } },
							Then = { { S = "Vega", T = "Alas. De mariposa. Evidentemente.", To = "Yo" } },
						},
					},
				},
			},
		},
		Grupo_Deportistas = {
			Lines = {
				{ S = "Nico", T = "¡Has venido! Esta es Álex. Es portera. Nadie le mete gol.", To = "Yo" },
				{ S = "Alex", T = "Nadie.", To = "Yo" },
				{ S = "Nico", T = "Bueno… Yo a veces.", To = "Yo" },
				{ S = "Alex", T = "Nunca.", To = "Yo" },
				{ S = "Nico", T = "Tú dijiste que te gusta el fútbol.", To = "Yo", If = { Choices = { Gusto = "Futbol" } } },
				{ S = "Nico", T = "Mañana juegas con nosotros.", To = "Yo", If = { Choices = { Gusto = "Futbol" } } },
				{
					Ask = "¿Qué dices?",
					Options = {
						{
							T = "«Te apuesto a que yo sí te marco, Álex.»",
							Effects = { Flags = { "ApuestaAlex" }, Rel = { Alex = 5 }, Traits = { Valentia = 1 } },
							Then = { { S = "Alex", T = "Apuesta aceptada. El que pierda lleva los balones una semana.", To = "Yo" } },
						},
						{
							T = "«Yo mejor de defensa, que corro mucho.»",
							Effects = { Rel = { Nico = 5 } },
							Then = { { S = "Nico", T = "¡Alguien en defensa! ¡Justo lo que nos faltaba!", To = "Yo" } },
						},
					},
				},
			},
		},
		Grupo_Estudiantes = {
			Lines = {
				{ S = "Sara", T = "Estamos discutiendo una cosa importantísima.", To = "Yo" },
				{ S = "Sara", T = "¿Las hormigas duermen?", To = "Yo", Shot = "PrimerPlano:Sara" },
				{ S = "Iker", T = "Sí. Doscientas cincuenta siestas de un minuto al día.", To = "Yo" },
				{ S = "Sara", T = "Eso hay que comprobarlo.", To = "Yo" },
				{ S = "Sara", T = "Experimentalmente.", To = "Yo", Shot = "Reaccion:Sara" },
				{ S = "Sara", T = "Tú dijiste que te gustan los experimentos. Estás dentro.", To = "Yo", If = { Choices = { Gusto = "Ciencia" } } },
				{
					Ask = "¿Qué dices?",
					Options = {
						{
							T = "«Yo vigilo el hormiguero con vosotros.»",
							Effects = { Rel = { Iker = 4, Sara = 6 }, Traits = { Curiosidad = 1 } },
							Then = { { S = "Sara", T = "¡Equipo científico formado! Mañana traigo lupa.", To = "Yo" } },
						},
						{
							T = "«¿Y los peces? ¿Los peces duermen?»",
							Effects = { Rel = { Iker = 6 } },
							Then = { { S = "Iker", T = "No lo sé. Por primera vez en mi vida… NO LO SÉ.", To = "Yo", Pause = 0.9 } },
						},
					},
				},
			},
		},
		Info_Iker = {
			Lines = {
				{ S = "Iker", T = "Shhh. Es la biblioteca.", To = "Yo", Shot = "General" },
				{ S = "Iker", T = "Soy Iker. Dato curioso.", To = "Yo", Shot = "PrimerPlano:Iker" },
				{ S = "Iker", T = "Aquí hay más de dos mil libros.", To = "Yo" },
				{ S = "Iker", T = "Me he leído cuarenta y siete.", To = "Yo", Pause = 0.9 },
				{
					Ask = "¿Qué le contestas?",
					Options = {
						{ T = "«¡Qué listo eres!»", Effects = { Rel = { Iker = 5 } }, Then = { { S = "Iker", T = "Ya lo sé. Digo… Gracias.", To = "Yo" } } },
						{
							T = "«¿Cuánto mide una pista de tenis?»",
							Effects = { Rel = { Iker = 3 }, Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Iker", T = "¡Veintitrés metros y setenta y siete centímetros!", To = "Yo" },
								{ S = "Iker", T = "Por fin alguien pregunta.", To = "Yo", Shot = "Reaccion:Iker" },
							},
						},
					},
				},
			},
		},
		Info_Ramon = {
			Lines = {
				{ S = "Ramon", T = "¡Anda! ¡La exploración oficial!", To = "Yo" },
				{ S = "Ramon", T = "Esto es el gimnasio.", To = "Yo", Shot = "General" },
				{ S = "Ramon", T = "Y al fondo está el almacén.", To = "Yo", Shot = "General" },
				{ S = "Ramon", T = "Ahí no se entra sin permiso. Balones. Colchonetas.", To = "Yo", Shot = "General" },
				{ S = "Ramon", T = "Y cosas que llevan años ahí dentro. Si pierdes algo…", To = "Yo" },
				{ S = "Ramon", T = "Pregúntame. Yo encuentro de todo.", To = "Yo", Shot = "PrimerPlano:Ramon" },
			},
		},
		Info_Vega = {
			Lines = {
				{ S = "Vega", T = "¿Te gustan las pegatinas?", To = "Yo" },
				{ S = "Vega", T = "Esta brilla en la oscuridad.", To = "Yo", Shot = "General" },
				{ S = "Vega", T = "Y esta huele a fresa. Consejo de experta.", To = "Yo", Shot = "General" },
				{ S = "Vega", T = "Los jueves hay macarrones.", To = "Yo" },
				{ S = "Vega", T = "Y nunca te sientes en la mesa de sexto.", To = "Yo", Pause = 0.9 },
			},
		},
		MateoGracias = {
			Lines = {
				{
					S = "Mateo",
					T = "G-gracias. Nadie… Bueno. Gracias.",
					To = "Yo",
					Shot = "Medio:Mateo",
					A = "Happy",
					If = { Flags = { "AyudasteAMateo" } },
					Effects = { Scene = "Cole01_G24_Musica" },
				},
				{ S = "Mateo", T = "¿Fuiste tú quien le pasó el balón a mi hermano?", To = "Yo", If = { Flags = { "PaseADani", "AyudasteAMateo" } } },
				{ S = "Mateo", T = "No para de hablar de ti.", To = "Yo", If = { Flags = { "PaseADani", "AyudasteAMateo" } } },
				{
					S = "Mateo",
					T = "Dani dice que alguien casi le da a una farola con su balón. ¿Fuiste tú?",
					To = "Yo",
					If = { Flags = { "FallastePase", "AyudasteAMateo" } },
				},
				{
					S = "Mateo",
					T = "Me llamo Mateo. Colecciono cromos.",
					To = "Yo",
					Shot = "Reaccion:Mateo",
					A = "Happy",
					If = { Flags = { "FallastePase", "AyudasteAMateo" } },
				},
				{
					S = "Mateo",
					T = "Tengo repetido el portero legendario. Por si… Por si lo quieres.",
					To = "Yo",
					Shot = "General",
					If = { Flags = { "FallastePase", "AyudasteAMateo" } },
				},
				{ S = "Yo", T = "¡Yo tengo ese cromo! Es mi cromo de la suerte.", If = { Flags = { "LlevaCromo", "AyudasteAMateo" } } },
				{ S = "Mateo", T = "¿En serio?", To = "Yo", If = { Flags = { "LlevaCromo", "AyudasteAMateo" } } },
				{ S = "Mateo", T = "Entonces… Somos del mismo equipo.", To = "Yo", Shot = "PrimerPlano:Mateo", If = { Flags = { "AyudasteAMateo" } } },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«¿Mañana te sientas conmigo?»",
							Effects = { Rel = { Mateo = 8 } },
							Then = { { S = "Mateo", T = "Vale.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
						{
							T = "«Tu hermano dice que te rías más.»",
							Effects = { Rel = { Mateo = 5 }, Traits = { Humor = 1 } },
							Then = { { S = "Mateo", T = "Jajaja… Dani siempre dice eso. Es un pesado. Pero tiene razón.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
					},
				},
			},
		},
		MateoSolo = {
			Lines = {
				{
					S = "Ruben",
					T = "Jejeje. El nuevo número dos.",
					To = "Yo",
					Shot = "Reaccion:Ruben",
					If = { NotFlags = { "AyudasteAMateo" } },
					Effects = { Scene = "Cole01_G25_Musica" },
				},
				{ S = "Narrador", T = "Mateo no dice nada.", Shot = "General", If = { NotFlags = { "AyudasteAMateo" } } },
				{ S = "Narrador", T = "A veces no hacer nada también deja una huella.", Shot = "Seguir:Mateo", If = { NotFlags = { "AyudasteAMateo" } } },
			},
		},
		Mochila = {
			Lines = {
				{ S = "Narrador", T = "Estuche. Cuaderno. Lápices.", Shot = "General" },
				{ S = "Narrador", T = "Y algo que llevas contigo desde hace tiempo.", Shot = "General" },
				{
					Ask = "¿Te llevas el cromo?",
					Options = {
						{
							T = "«¡Claro! Me llevo el cromo.»",
							Effects = { Flags = { "LlevaCromo" }, Items = { CromoSuerte = 1 } },
							Then = { { S = "Yo", T = "Al bolsillo pequeño. Para emergencias." } },
						},
						{
							T = "«Mejor no. No quiero perderlo.»",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = { { S = "Yo", T = "Se queda aquí. A salvo." } },
						},
					},
				},
			},
		},
		Presentaciones = {
			Lines = {
				{
					S = "Sara",
					T = "Has elegido bien. Aquí delante se entiende todo.",
					To = "Yo",
					If = { Choices = { Asiento = "Sara" } },
					Effects = { Scene = "Cole01_G15_16_17_Musica" },
				},
				{ S = "Sara", T = "Y la pizarra no tiene reflejos.", To = "Yo", If = { Choices = { Asiento = "Sara" } } },
				{
					S = "Nico",
					T = "¡Bien! Desde aquí se ve la ventana y el campo. Si miras mucho… Lucía te pilla.",
					To = "Yo",
					If = { Choices = { Asiento = "Nico" } },
				},
				{ S = "Mateo", T = "…Hola.", To = "Yo", Shot = "PrimerPlano:Mateo", If = { Choices = { Asiento = "Mateo" } } },
				{
					S = "Ruben",
					T = "Psst. Te has sentado en la fila de los guays. Jejeje.",
					To = "Yo",
					Shot = "Reaccion:Ruben",
					If = { Choices = { Asiento = "Mateo" } },
				},
				{ S = "Lucia", T = "Vamos a presentarnos.", To = "Yo", If = { Choices = { Asiento = "Mateo" } } },
				{ S = "Lucia", T = "Cada uno dice su nombre y algo que le guste.", To = "Yo", Shot = "General" },
				{ S = "Lucia", T = "{nombre}. Empiezas tú.", To = "Yo", Shot = "PrimerPlano:Yo" },
				{
					Ask = "Te toca. ¿Qué dices?",
					Options = {
						{
							T = "«Me encanta el fútbol.»",
							Effects = { Choice = { Gusto = "Futbol" } },
							Then = { { S = "Nico", T = "¡LO SABÍA! Recreo. Partido. Tú y yo.", To = "Yo" } },
						},
						{ T = "«Me gusta dibujar.»", Effects = { Choice = { Gusto = "Dibujar" } }, Then = { { S = "Omar", T = "Mola.", To = "Yo" } } },
						{
							T = "«Me encantan los experimentos.»",
							Effects = { Choice = { Gusto = "Ciencia" } },
							Then = { { S = "Sara", T = "¿Experimentos de verdad? ¿Con volcanes? Tenemos que hablar.", To = "Yo" } },
						},
						{
							T = "«Me gusta… dormir cinco minutitos más.»",
							Effects = { Choice = { Gusto = "Dormir" }, Traits = { Humor = 1 } },
							Then = {
								{ S = "Nico", T = "¡Jajajaja!", To = "Yo" },
								{ S = "Lucia", T = "Tomo nota para cuando llegues tarde.", To = "Yo", Shot = "PrimerPlano:Lucia" },
								{ S = "Lucia", T = "Se nota que lo traías ensayado. Así da gusto. Muy bien. Y ahora…", To = "Yo", If = { Flags = { "EnsayoEspejo" } } },
								{ S = "Lucia", T = "Matemáticas.", To = "Yo", Shot = "General" },
								{ S = "Nico", T = "¿Ya?", To = "Yo" },
								{ S = "Lucia", T = "Ya.", To = "Yo" },
							},
						},
					},
				},
				{ S = "Nico", T = "Luego te enseño el campo.", To = "Yo", Shot = "Hombro:Yo>Nico", If = { Choices = { Asiento = "Nico" } } },
				{ S = "Lucia", T = "Nico.", To = "Yo", If = { Choices = { Asiento = "Nico" } } },
				{ S = "Nico", T = "Yo no he dicho nada.", To = "Yo", If = { Choices = { Asiento = "Nico" } } },
				{
					S = "Mateo",
					T = "Si quieres… Luego te puedo enseñar dónde está el patio.",
					To = "Yo",
					Shot = "Hombro:Yo>Mateo",
					If = { Choices = { Asiento = "Mateo" } },
				},
				{ S = "Mateo", T = "Dani dice que conoces el fútbol.", To = "Yo", Shot = "PrimerPlano:Mateo", If = { Choices = { Asiento = "Mateo" } } },
			},
		},
		Salida = {
			Lines = {
				{ S = "Yo", T = "¡Listo!", Shot = "Medio:Yo", Effects = { Scene = "Cole01_G3_Musica" } },
				{ S = "Yo", T = "Ropa.", Shot = "General" },
				{ S = "Yo", T = "Mochila.", Shot = "General" },
				{ S = "Yo", T = "Desayuno. Todo.", Shot = "General" },
				{ S = "Familia", T = "A ver.", To = "Yo" },
				{ S = "Familia", T = "Qué elegancia.", To = "Yo", If = { Choices = { Ropa = "Camisa" } } },
				{ S = "Familia", T = "Con los dinosaurios. Muy tú.", To = "Yo", If = { Choices = { Ropa = "Dinosaurios" } } },
				{ S = "Familia", T = "Con la sudadera del cole. Pareces de sexto.", To = "Yo", If = { Choices = { Ropa = "Sudadera" } } },
				{ S = "Familia", T = "Aunque…", To = "Yo", If = { Flags = { "LlegasTarde" } } },
				{ S = "Familia", T = "Mira qué hora es. ¡Corre!", To = "Yo", Shot = "PrimerPlano:Familia" },
				{ S = "Familia", T = "El colegio está cerca.", To = "Yo" },
				{ S = "Familia", T = "¿Quieres que te acompañe?", To = "Yo" },
				{
					Ask = "¿Vas por tu cuenta o con compañía?",
					Options = {
						{
							T = "«Sí, acompáñame, porfa.»",
							Effects = { Choice = { Acompanante = "Familia" }, Rel = { Familia = 3 } },
							Then = {
								{ S = "Familia", T = "Claro. Pero en la puerta me das un beso rapidito.", To = "Yo" },
								{ S = "Familia", T = "Que ya sé que da vergüenza.", To = "Yo" },
							},
						},
						{
							T = "«¡Voy yo solo, que ya soy mayor!»",
							Effects = { Choice = { Acompanante = "Solo" }, Traits = { Valentia = 1 } },
							Then = {
								{ S = "Familia", T = "Vale. Que ya eres mayor. Ve por la acera. Y sigue la luz.", To = "Yo" },
								{ S = "Familia", T = "Te miro desde la ventana.", To = "Yo" },
							},
						},
					},
				},
			},
		},
		Timbre = {
			Lines = {
				{ S = "Nico", T = "¡Recreo!", To = "Yo", Shot = "General", Effects = { Scene = "Cole01_G19_Musica" } },
				{ S = "Lucia", T = "Quince minutos. Y nada de subirse a la valla, Nico.", To = "Yo", Shot = "PrimerPlano:Lucia" },
				{ S = "Nico", T = "¡Yo no he hecho nada! Todavía.", To = "Yo", Shot = "Reaccion:Nico" },
			},
		},
	},
	Scenes = {
		Cole01_Bienvenida = {
			Skippable = true,
			Duration = 44.2,
			Anchors = { L_AulaA = "Place:AulaA", Sitio = "Place:AulaA", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Bruno", Npc = "Bruno" } },
					{ At = 0, Use = { Key = "Lucia", Npc = "Lucia" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Ambience = { { At = 0, Kind = "Colegio" } },
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:L_AulaA" },
					{ At = 2.4, Duration = 2, Shot = "Hombro:Yo>L_AulaA" },
					{ At = 4.4, Duration = 10.4, Shot = "Reaccion:Lucia" },
					{ At = 14.79, Duration = 5.3, Shot = "Lateral:Sara" },
					{ At = 20.09, Duration = 4.4, Shot = "PrimerPlano:Nico" },
					{ At = 24.46, Duration = 2.5, Shot = "Reaccion:Sara" },
					{ At = 26.96, Duration = 4.7, Shot = "PrimerPlano:Sara" },
					{ At = 31.61, Duration = 3.7, Shot = "Reaccion:Bruno" },
					{ At = 35.27, Duration = 2.5, Shot = "PrimerPlano:Lucia" },
					{ At = 37.77, Duration = 2.5, Shot = "Medio:Yo" },
					{ At = 40.27, Duration = 3.2, Shot = "Pan:L_AulaA" },
				},
				Dialogue = {
					{ At = 4.4, S = "Lucia", T = "¡Mirad quién ha encontrado el aula!", To = "Yo", IfNot = { Flags = { "LlegasTarde" } } },
					{ At = 7.7, S = "Lucia", T = "¡Mirad quién ha encontrado el aula! Un poquito tarde…", To = "Yo", If = { Flags = { "LlegasTarde" } } },
					{ At = 12.3, S = "Lucia", T = "Pero la ha encontrado.", To = "Yo", If = { Flags = { "LlegasTarde" } } },
					{ At = 14.8, S = "Lucia", T = "Chicos, chicas. Hoy tenemos a alguien nuevo. Se llama {nombre}.", To = "Yo" },
					{ At = 20.1, S = "Nico", T = "¿Juegas al fútbol? Necesitamos uno para el recreo.", To = "Yo" },
					{ At = 24.5, S = "Sara", T = "Nico. Déjale llegar.", To = "Yo" },
					{ At = 27, S = "Sara", T = "Hola. Soy Sara. Ya tengo hechos los deberes de mañana.", To = "Yo" },
					{ At = 31.6, S = "Bruno", T = "Otro más. Como si no fuéramos ya muchos.", To = "Yo" },
					{ At = 35.3, S = "Lucia", T = "Bruno. Eso no se dice.", To = "Yo" },
					{ At = 37.8, S = "Lucia", T = "{nombre}. Busca sitio.", To = "Yo" },
					{ At = 40.3, S = "Lucia", T = "Elige bien. Es para todo el curso.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole01_G10_Musica = { Light = true, Duration = 39.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole01_G12_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Narrador", T = "1.º A." } }, Music = { { At = 0, Intensity = "Descubrimiento" } } },
		},
		Cole01_G15_16_17_Musica = { Light = true, Duration = 47, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole01_G18_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Primeras clases. Primeras horas. Y poco a poco…" },
					{ At = 4.6, S = "Narrador", T = "empiezas a descubrir quién es quién." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole01_G19_Musica = { Light = true, Duration = 11.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole01_G1_Musica = { Light = true, Duration = 21.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole01_G20_Entra = {
			Light = true,
			Duration = 17.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Hugo", Npc = "Hugo" } },
					{ At = 0, Use = { Key = "Alex", Npc = "Alex" } },
					{ At = 0, Use = { Key = "Iker", Npc = "Iker" } },
					{ At = 0, Use = { Key = "Vega", Npc = "Vega" } },
					{ At = 0, Use = { Key = "Ruben", Npc = "Ruben" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Ruben", T = "Jejeje. Nada, nada.", To = "Yo" },
					{ At = 2.9, S = "Hugo", T = "…Hola.", To = "Yo" },
					{ At = 5.4, S = "Alex", T = "Si Nico dice que me ha metido gol… Miente.", To = "Yo" },
					{ At = 9.2, S = "Vega", T = "Todas sus nubes tienen forma de bocadillo.", To = "Yo" },
					{ At = 13.9, S = "Iker", T = "Bueno. Lo he leído en algún sitio.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole01_G24_Musica = { Light = true, Duration = 36, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole01_G25_Musica = { Light = true, Duration = 11.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole01_G26_Musica = { Light = true, Duration = 18.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole01_G27_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Esta mañana no conocías a nadie." },
					{ At = 3.5, S = "Narrador", T = "Ahora ya tienes algunos nombres." },
					{ At = 6.6, S = "Narrador", T = "Y mañana… volverás a verlos." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole01_G28_Musica = { Light = true, Duration = 32.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole01_G2_Entra = {
			Light = true,
			Duration = 32,
			Anchors = { A_Familia = "Place:FamiliaPadre", Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Anchor = "A_Familia", Key = "Familia", Npc = "Familia" } } },
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Los Pinos. Primera hora de la mañana." },
					{ At = 3.8, S = "Narrador", T = "Hoy no es un día cualquiera." },
					{ At = 6.6, S = "Narrador", T = "Prepárate para el colegio." },
					{ At = 9.3, S = "Narrador", T = "Estiras la sábana. Colocas la almohada. No está perfecta." },
					{ At = 14.2, S = "Narrador", T = "Pero es tu primera cama hecha." },
					{ At = 17.1, S = "Familia", T = "¿La has hecho tú sol{o/a}?", To = "Yo" },
					{ At = 19.8, S = "Familia", T = "Hoy es un día histórico.", To = "Yo" },
					{ At = 22.3, S = "Narrador", T = "Antes de conocer a nadie…" },
					{ At = 24.9, S = "Narrador", T = "tienes que decidir cómo quieres presentarte." },
					{ At = 28.8, S = "Narrador", T = "Perfecto." },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole01_G3_Musica = { Light = true, Duration = 33.8, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole01_G4_Entra = {
			Light = true,
			Duration = 13.9,
			Anchors = { A_Familia = "Place:FamiliaPadre", Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, If = { Choices = { Acompanante = "Familia" } }, Use = { Anchor = "A_Familia", Key = "Familia", Npc = "Familia" } } },
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Primer día. Primera mochila." },
					{ At = 3.2, S = "Narrador", T = "Primer camino al colegio." },
					{ At = 5.8, S = "Familia", T = "¿Nervioso?", To = "Yo", If = { Choices = { Acompanante = "Familia" } } },
					{ At = 8.3, S = "Yo", T = "Un poco.", If = { Choices = { Acompanante = "Familia" } } },
					{ At = 10.8, S = "Familia", T = "Normal.", To = "Yo", If = { Choices = { Acompanante = "Familia" } } },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole01_G5_Musica = { Light = true, Duration = 13.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole01_G7_Musica = { Light = true, Duration = 37.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole01_G8_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { A_Familia = "Place:FamiliaPadre", Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Anchor = "A_Familia", Key = "Familia", Npc = "Familia" } } },
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Los Pinos. Tu colegio." },
					{ At = 2.9, S = "Familia", T = "Pórtate bien, ¿eh? ¡Y come la fruta!", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" } },
			},
		},
		Cole01_G9_Musica = { Light = true, Duration = 45.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole01_LibrosCaen = {
			Skippable = true,
			Duration = 38.3,
			Anchors = { L_Patio = "Place:Patio", Sitio = "Place:Patio", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Ruben", Npc = "Ruben" } },
					{ At = 0, Use = { Key = "Bruno", Npc = "Bruno" } },
					{ At = 0, Use = { Key = "Mateo", Npc = "Mateo" } },
					{ At = 11.73, Mood = { Mood = "Joy", Key = "Bruno" } },
				},
				Ambience = { { At = 0, Kind = "Colegio" } },
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:L_Patio" },
					{ At = 2.4, Duration = 2, Shot = "Seguir:Mateo" },
					{ At = 4.4, Duration = 2, Shot = "General:Sitio" },
					{ At = 6.4, Duration = 2.5, Shot = "Reaccion:Mateo" },
					{ At = 8.9, Duration = 2.7, Shot = "Reaccion:Ruben" },
					{ At = 11.63, Duration = 2, Shot = "Reaccion:Bruno" },
					{ At = 13.63, Duration = 2, Shot = "PPP:Mateo" },
					{ At = 15.63, Duration = 6, Shot = "General:L_Patio" },
					{ At = 21.64, Duration = 2, Shot = "General:Sitio" },
					{ At = 23.64, Duration = 12, Shot = "Reaccion:Yo" },
					{ At = 35.61, Duration = 2, Shot = "PrimerPlano:Mateo" },
				},
				Dialogue = {
					{ At = 6.4, S = "Ruben", T = "¡Jajajaja!", To = "Yo" },
					{ At = 8.9, S = "Ruben", T = "¡Mirad al nuevo número dos!", To = "Yo" },
					{ At = 15.6, S = "Narrador", T = "Hay momentos en los que puedes mirar hacia otro lado. O puedes acercarte." },
					{ At = 23.6, S = "Yo", T = "El hermano de Dani. Y su álbum de cromos. Como el mío.", If = { Flags = { "PaseADani", "LlevaCromo" } } },
					{ At = 28.3, S = "Yo", T = "Es Mateo. El hermano de Dani. El del balón.", If = { Flags = { "PaseADani" }, NotFlags = { "LlevaCromo" } } },
					{ At = 32.2, S = "Yo", T = "Ese álbum… Es de cromos. Como el mío.", If = { Flags = { "LlevaCromo" }, NotFlags = { "PaseADani" } } },
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Cole01_G2_Entra" } },
		["11"] = { Effects = { Scene = "Cole01_G12_Entra" }, Set = { Text = "Conoce el colegio." } },
		["12"] = { Set = { Text = "Encuentra el aula 1.º A." } },
		["17"] = { Effects = { Scene = "Cole01_G18_Entra" } },
		["18"] = { Set = { Text = "Completa tu primera clase de Matemáticas." } },
		["19"] = { Effects = { Scene = "Cole01_G20_Entra" } },
		["20"] = { Set = { Text = "Sal al patio." } },
		["21"] = { Set = { Text = "Decide con quién pasar tu primer recreo." } },
		["23"] = { Set = { Text = "Ayuda a Mateo a recoger sus cosas." } },
		["26"] = { Effects = { Scene = "Cole01_G27_Entra" } },
		["27"] = { Set = { Text = "Vuelve a casa." } },
		["3"] = { Effects = { Scene = "Cole01_G4_Entra" } },
		["6"] = { Set = { Text = "Pásale el balón a Dani." } },
		["7"] = { Effects = { Scene = "Cole01_G8_Entra" } },
	},
}
