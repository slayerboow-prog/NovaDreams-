-- GUION REESCRITO de Cole02_Mochila (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Cole02_Mochila.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Cole02_Mochila
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Cole02_Mochila.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Cole02_Mochila.md",
	Dialogues = {
		Alex_Pista = {
			Lines = {
				{ S = "Alex", T = "Vale. Tres canastas.", To = "Yo", If = { Flags = { "CanastasAlex" } }, Effects = { Scene = "Cole02_Mochila_G15_Musica" } },
				{ S = "Alex", T = "Un trato es un trato.", To = "Yo", Shot = "PrimerPlano:Alex", If = { Flags = { "CanastasAlex" } } },
				{ S = "Alex", T = "Ni una. Uf.", To = "Yo", If = { Flags = { "SinCanastas" } } },
				{ S = "Alex", T = "Mira… Te lo voy a contar igual.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Alex", T = "Pero que no se entere nadie.", To = "Yo", Pause = 0.9 },
				{ S = "Alex", T = "Rubén pasó por aquí con una mochila azul. Hace un rato.", To = "Yo", Shot = "Hombro:Alex>Yo" },
				{ S = "Alex", T = "Se metió ahí.", To = "Yo", Shot = "General" },
				{ S = "Alex", T = "En el almacén. Y Rubén solo hace estas cosas cuando Bruno se lo pide.", To = "Yo", Shot = "PrimerPlano:Alex" },
				{ S = "Yo", T = "Ramón dijo que nadie puede entrar ahí.", If = { Flags = { "SabeDelAlmacen" } } },
				{ S = "Alex", T = "Entonces ya sabes lo que toca.", To = "Yo", If = { Flags = { "SabeDelAlmacen" } } },
			},
		},
		Alex_Reto = {
			Lines = {
				{ S = "Alex", T = "Hola. ¿Buscas algo?", To = "Yo", Shot = "Medio:Alex", Effects = { Scene = "Cole02_Mochila_G13_Musica" } },
				{ S = "Alex", T = "Tienes cara de buscar algo.", To = "Yo", Shot = "PrimerPlano:Alex" },
				{ S = "Yo", T = "Mi mochila. ¿Has visto a alguien con una mochila azul?" },
				{ S = "Alex", T = "Puede. Puede que sí.", To = "Yo" },
				{ S = "Alex", T = "Pero la información es cara.", To = "Yo", Shot = "PPP:Alex" },
				{ S = "Alex", T = "Trato. Mete tres canastas.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Alex", T = "Si las metes, te lo cuento.", To = "Yo" },
				{ S = "Alex", T = "Y además me debes una por aquella apuesta. Me acuerdo.", To = "Yo", If = { Flags = { "ApuestaAlex" } } },
			},
		},
		Almacen_Entra = {
			Lines = {
				{ S = "Narrador", T = "Huele a goma. A polvo. Y a secretos.", Shot = "General", Effects = { Scene = "Cole02_Mochila_G17_Musica" } },
				{ S = "Yo", T = "Ahí.", Shot = "Reaccion:Yo" },
				{ S = "Narrador", T = "Hay varias. Pero una de ellas…", Shot = "General" },
				{ S = "Narrador", T = "es la tuya.", Shot = "General" },
			},
		},
		Almacen_Gris = {
			Lines = {
				{ S = "Narrador", T = "Dentro hay un libro de piratas.", Shot = "General" },
				{ S = "Yo", T = "¿Hugo? El amigo de Bruno…", Shot = "Reaccion:Yo" },
				{ S = "Narrador", T = "Y resulta que también lee libros de piratas." },
				{ S = "Narrador", T = "Curioso.", Shot = "Reaccion:Yo" },
			},
		},
		Almacen_Roja = { Lines = { { S = "Narrador", T = "No es la tuya.", Shot = "General" } } },
		Almacen_Verde = { Lines = { { S = "Narrador", T = "No. Definitivamente no.", Shot = "General" } } },
		Broma_Gorra = {
			Lines = {
				{ S = "Ruben", T = "¿Y mi gorra? ¿Dónde está mi gorra?", To = "Yo", Shot = "Reaccion:Yo", If = { Choices = { MochilaRuben = "Broma" } } },
				{ S = "Ruben", T = "Ah. Ya. Ja. Ja. Muy gracioso.", To = "Yo", Shot = "PrimerPlano:Ruben", If = { Choices = { MochilaRuben = "Broma" } } },
				{ S = "Ruben", T = "Vale. Ha tenido gracia. Un poco.", To = "Yo", Shot = "Reaccion:Ruben", If = { Choices = { MochilaRuben = "Broma" } } },
			},
		},
		Buscar_Papelera = {
			Lines = {
				{ S = "Yo", T = "Vale. Esto ya no es un despiste.", Shot = "Reaccion:Yo" },
				{ S = "Yo", T = "Alguien se la ha llevado.", Shot = "PrimerPlano:Yo" },
			},
		},
		Buscar_Pupitre = { Lines = { { S = "Narrador", T = "Nada. Definitivamente no es tu mochila.", Shot = "General" } } },
		Buscar_Taquilla = { Lines = { { S = "Narrador", T = "Aquí tampoco. La mochila ni siquiera cabría.", Shot = "General" } } },
		Deduccion = {
			Lines = {
				{ S = "Narrador", T = "Una firma.", Shot = "General", Effects = { Scene = "Cole02_Mochila_G11_Musica" } },
				{ S = "Narrador", T = "Un llavero.", Shot = "General" },
				{ S = "Narrador", T = "Huellas hacia el gimnasio.", Shot = "General" },
				{ S = "Narrador", T = "Algo de tu mochila.", Shot = "General" },
				{ S = "Narrador", T = "Alguien con sudadera morada fue hacia el patio.", If = { Flags = { "PistaSara" } } },
				{ S = "Narrador", T = "Omar vio a alguien corriendo hacia el gimnasio.", If = { Flags = { "PistaOmar" } } },
				{ S = "Narrador", T = "Alguien habló del «sitio de siempre».", If = { Flags = { "PistaIker" } } },
				{ S = "Narrador", T = "Mateo vio a Rubén. Y Bruno se lo pidió.", If = { Flags = { "PistaMateo" } } },
				{ S = "Yo", T = "Todo apunta al gimnasio.", Shot = "PrimerPlano:Yo" },
				{ S = "Yo", T = "Entonces allí es donde voy.", Pause = 0.9 },
			},
		},
		Encargo = {
			Lines = {
				{
					S = "Lucia",
					T = "¡Buenos días! {nombre}, ¿me haces un favor?",
					To = "Yo",
					Shot = "General",
					Effects = { Scene = "Cole02_Mochila_G3_Musica" },
				},
				{ S = "Lucia", T = "Lleva esta lista a Ramón, a conserjería.", To = "Yo", Shot = "Medio:Yo" },
				{ S = "Lucia", T = "Es muy fácil. Se la das y vuelves.", To = "Yo", Shot = "General" },
				{ S = "Lucia", T = "Deja la mochila en tu silla. No tardarás nada.", To = "Yo", Shot = "Hombro:Yo>Lucia" },
				{ S = "Narrador", T = "No le das importancia.", Shot = "Reaccion:Ruben" },
			},
		},
		Lucia_Final = {
			Lines = {
				{ S = "Lucia", T = "¿Qué hacéis los dos aquí?", To = "Yo", Shot = "Seguir:Lucia", Effects = { Scene = "Cole02_Mochila_G21_Musica" } },
				{ S = "Lucia", T = "¿No os ha dicho Ramón que aquí no se entra?", To = "Yo", Shot = "PrimerPlano:Lucia" },
				{ S = "Lucia", T = "Rubén. Explícamelo.", To = "Yo", If = { Choices = { MochilaRuben = "Profe" } } },
				{ S = "Ruben", T = "Fue… una broma. Bruno me dijo que lo hiciera.", To = "Yo", If = { Choices = { MochilaRuben = "Profe" } } },
				{ S = "Bruno", T = "Yo solo…", To = "Yo", Shot = "Reaccion:Bruno" },
				{ S = "Lucia", T = "Ya hablaremos después.", To = "Yo" },
				{ S = "Ruben", T = "Lo siento, {nombre}. De verdad.", To = "Yo", Shot = "Medio:Ruben" },
				{ S = "Lucia", T = "Gracias por contármelo. Hablaré con los dos.", To = "Yo", Shot = "PrimerPlano:Lucia" },
				{ S = "Lucia", T = "Esto no es una tradición. Es una mala decisión.", To = "Yo", Pause = 0.9 },
				{ S = "Ruben", T = "Nada, profe. Estábamos buscando un balón.", To = "Yo", If = { Choices = { MochilaRuben = "Perdon" } } },
				{ S = "Ruben", T = "Y lo hemos encontrado.", To = "Yo", Shot = "General" },
				{ S = "Lucia", T = "Ya. Un balón azul con forma de mochila. Los dos a clase. Vamos.", To = "Yo", Shot = "Reaccion:Lucia" },
				{ S = "Ruben", T = "¡Me ha gritado, profe!", To = "Yo", If = { Choices = { MochilaRuben = "Enfado" } } },
				{ S = "Lucia", T = "Normal. Yo también me enfadaría si alguien escondiera mi mochila.", To = "Yo", Shot = "Reaccion:Lucia" },
				{ S = "Lucia", T = "Pero la próxima vez… respira. Y ven a buscarme.", To = "Yo", Shot = "PrimerPlano:Lucia" },
				{ S = "Ruben", T = "¡Profe! ¡Me ha escondido la gorra!", To = "Yo", If = { Choices = { MochilaRuben = "Broma" } } },
				{ S = "Lucia", T = "Y tú le has escondido la mochila.", To = "Yo", Shot = "Reaccion:Lucia" },
				{ S = "Lucia", T = "Empate técnico. Ahora os devolvéis las cosas.", To = "Yo", Shot = "DosPlanos:Yo,Lucia", Pause = 0.9 },
				{ S = "Lucia", T = "Y se acabaron las bromas.", To = "Yo" },
				{ S = "Narrador", T = "Recuperas tus cosas. Todo sigue dentro.", Shot = "General" },
				{ S = "Narrador", T = "Hugo no dice nada. Pero parece incómodo.", Shot = "Lateral:Hugo" },
				{ S = "Narrador", T = "Quizá haya más en esta historia de lo que parece.", Shot = "General" },
				{ S = "Narrador", T = "Has recuperado tu mochila.", Shot = "PrimerPlano:Yo" },
				{ S = "Narrador", T = "Pero acabas de entrar en un problema mucho más grande.", Pause = 0.9 },
				{ S = "Narrador", T = "Algunas bromas duran cinco minutos. Algunas decisiones… mucho más.", Shot = "General" },
			},
		},
		Lucia_Pregunta = {
			Lines = {
				{ S = "Lucia", T = "¿Qué pasa, {nombre}?", To = "Yo", Shot = "Seguir:Lucia", Effects = { Scene = "Cole02_Mochila_G8_Musica" } },
				{ S = "Lucia", T = "Tienes cara de haber visto un fantasma.", To = "Yo", Shot = "PrimerPlano:Lucia" },
				{ S = "Yo", T = "Mi mochila. La dejé aquí y… ya no está.", Shot = "Reaccion:Yo" },
				{ S = "Lucia", T = "Vaya.", To = "Yo", Shot = "Reaccion:Lucia" },
				{ S = "Lucia", T = "Las mochilas no desaparecen solas.", To = "Yo", Shot = "Medio:Lucia" },
				{ S = "Lucia", T = "Pregunta a tus compañeros.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "Alguien habrá visto algo.", To = "Yo" },
				{ S = "Lucia", T = "Yo avisaré a Ramón.", To = "Yo", Shot = "Seguir:Lucia" },
				{ S = "Lucia", T = "Y no te preocupes. Vamos a encontrarla.", To = "Yo", Shot = "Reaccion:Yo" },
			},
		},
		NoEsta = {
			Lines = {
				{ S = "Narrador", T = "No está. Ni en la silla. Ni debajo.", Shot = "General", Effects = { Scene = "Cole02_Mochila_G6_Musica" } },
				{ S = "Yo", T = "No puede ser.", Shot = "PrimerPlano:Yo" },
				{ S = "Yo", T = "Y el cromo de la suerte estaba dentro…", Shot = "Reaccion:Yo", If = { Flags = { "LlevaCromo" } } },
				{ S = "Narrador", T = "Tu mochila ya no está contigo. Busca.", Pause = 0.9, If = { Flags = { "LlevaCromo" } } },
				{ S = "Narrador", T = "Quizá alguien la haya movido.", If = { Flags = { "LlevaCromo" } } },
			},
		},
		Pista_Envoltorio = {
			Lines = {
				{ S = "Narrador", T = "Chicle de fresa. Huele a fresa.", Shot = "General" },
				{ S = "Narrador", T = "Y no demuestra absolutamente nada. A veces una pista…", Pause = 0.9 },
				{ S = "Narrador", T = "es simplemente basura." },
			},
		},
		Pista_Huella = {
			Lines = { { S = "Narrador", T = "Zapatillas pequeñas. Van hacia el gimnasio.", Shot = "General" }, { S = "Narrador", T = "Alguien iba corriendo." } },
		},
		Pista_Llavero = { Lines = { { S = "Yo", T = "B… Bruno.", Shot = "PrimerPlano:Yo" } } },
		Pista_Papel = {
			Lines = {
				{ S = "Narrador", T = "Alguien ha dibujado una pequeña calavera. Debajo hay una letra.", Shot = "General" },
				{ S = "Narrador", T = "R.", Shot = "General" },
			},
		},
		Pista_Pegatina = {
			Lines = {
				{ S = "Yo", T = "Mi cromo.", Shot = "Reaccion:Yo", If = { Flags = { "LlevaCromo" } } },
				{ S = "Narrador", T = "Se cayó de la mochila.", If = { Flags = { "LlevaCromo" } } },
				{ S = "Narrador", T = "Es la pegatina que llevaba tu mochila.", Shot = "General", If = { NotFlags = { "LlevaCromo" } } },
				{ S = "Yo", T = "Mi mochila ha pasado por aquí.", Shot = "Reaccion:Yo" },
			},
		},
		Ramon_Lista = {
			Lines = {
				{ S = "Ramon", T = "¡La lista!", To = "Yo", Effects = { Scene = "Cole02_Mochila_G4_Musica" } },
				{ S = "Ramon", T = "Gracias.", To = "Yo", Shot = "General" },
				{ S = "Ramon", T = "Veinte nombres. Veinte mochilas. Veinte bocadillos. Y un conserje.", To = "Yo", Shot = "Medio:Ramon" },
				{ S = "Ramon", T = "¿Sabes cuántas cosas pierde un colegio en un año? Trescientas doce.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Ramon", T = "Las tengo apuntadas.", To = "Yo", Shot = "PPP:Ramon" },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«¿Y dónde van todas esas cosas?»",
							Effects = { Rel = { Ramon = 3 }, Traits = { Curiosidad = 1 } },
							Then = {
								{ S = "Ramon", T = "Algunas llegan a objetos perdidos.", To = "Yo" },
								{ S = "Ramon", T = "Otras aparecen en lugares imposibles. Y alguna… nunca vuelve.", To = "Yo" },
							},
						},
						{
							T = "«¡Me tengo que ir! ¡Me espera Lucía!»",
							Effects = { Traits = { Responsabilidad = 1 } },
							Then = {
								{ S = "Ramon", T = "¡Corre, corre! Qué responsabilidad tan grande para alguien tan pequeñ{o/a}.", To = "Yo" },
								{ S = "Narrador", T = "Mejor volver.", Shot = "Reaccion:Yo" },
							},
						},
					},
				},
			},
		},
		Ruben_Aparece = {
			Lines = {
				{ S = "Ruben", T = "¿Buscas esto?", To = "Yo", Shot = "Reaccion:Yo", Effects = { Scene = "Cole02_Mochila_G19_Musica" } },
				{ S = "Ruben", T = "Era una broma. Bruno dijo que a los nuevos había que darles la bienvenida. Es una tradición.", To = "Yo", Shot = "General" },
				{ S = "Yo", T = "Mateo te vio. Bruno te dijo que lo hicieras.", Shot = "PrimerPlano:Yo", If = { Flags = { "PistaMateo" } } },
				{ S = "Ruben", T = "Mateo es un chivato. Bueno. Da igual.", To = "Yo" },
				{ S = "Ruben", T = "Ahí la tienes. Está entera.", To = "Yo", Shot = "General" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "«¡No tiene ninguna gracia!»",
							Effects = { Choice = { MochilaRuben = "Enfado" }, Flags = { "Ruben_Rival" }, Rel = { Bruno = -5, Ruben = -15 }, Traits = { Valentia = 2 } },
							Then = {
								{ S = "Yo", T = "¡No tiene ninguna gracia!" },
								{ S = "Yo", T = "¡Me he pasado la mañana buscándola!" },
								{ S = "Ruben", T = "Vale, vale. No grites. Era solo una broma.", To = "Yo", Shot = "Reaccion:Ruben" },
							},
						},
						{
							T = "«Vale. Pero no vuelvas a hacerlo.»",
							Effects = { Choice = { MochilaRuben = "Perdon" }, Flags = { "Ruben_Perdonado" }, Rel = { Ruben = 15 }, Traits = { Empatia = 2 } },
							Then = {
								{ S = "Yo", T = "Vale. Te perdono. Pero no vuelvas a hacerlo." },
								{ S = "Ruben", T = "¿En serio? Vale. Gracias.", To = "Yo", Shot = "Reaccion:Ruben" },
								{ S = "Ruben", T = "Bruno no perdona nunca a nadie.", To = "Yo" },
							},
						},
						{
							T = "«Esto se lo tiene que saber Lucía.»",
							Effects = {
								Choice = { MochilaRuben = "Profe" },
								Flags = { "AvisasteALucia" },
								Rel = { Bruno = -10, Lucia = 5, Ruben = -5 },
								Traits = { Responsabilidad = 2 },
							},
							Then = {
								{ S = "Yo", T = "Esto se lo tiene que saber Lucía." },
								{ S = "Ruben", T = "¡No! ¡Espera! Bruno me va a… Bueno. Se va a enfadar.", To = "Yo", Shot = "Reaccion:Ruben" },
							},
						},
						{
							T = "«Devolverle la broma.»",
							Effects = { Choice = { MochilaRuben = "Broma" }, Flags = { "BromaDeVuelta" }, Rel = { Ruben = 5 }, Traits = { Humor = 2 } },
							Then = { { S = "Narrador", T = "Rubén deja la mochila en el suelo. Y una idea aparece. Una idea pequeña. Y bastante traviesa.", Shot = "General" } },
						},
					},
				},
			},
		},
		Testigo_Iker = {
			Lines = {
				{ S = "Iker", T = "(susurrando) Oí algo.", To = "Yo", Shot = "General", Effects = { Scene = "Cole02_Mochila_G9_4_Musica" } },
				{ S = "Iker", T = "«La mochila azul». «Al sitio de siempre».", To = "Yo", Shot = "PrimerPlano:Iker" },
				{ S = "Iker", T = "Y después se rieron.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Iker", T = "Dato curioso. El sitio de siempre suele ser donde nadie mira.", To = "Yo", Shot = "PPP:Iker" },
				{ S = "Nico", T = "¡Qué fuerte! Si pillo al que ha sido…", To = "Yo", Shot = "Reaccion:Nico" },
				{ S = "Nico", T = "le reto a una carrera. Y le gano.", To = "Yo" },
			},
		},
		Testigo_Mateo = {
			Lines = {
				{
					S = "Mateo",
					T = "{nombre}…",
					To = "Yo",
					Shot = "General",
					If = { Flags = { "AyudasteAMateo" } },
					Effects = { Scene = "Cole02_Mochila_G9_1_Musica" },
				},
				{ S = "Mateo", T = "Yo lo vi. Fue Rubén.", To = "Yo", Shot = "Reaccion:Mateo", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Mateo", T = "Bruno le dijo que lo hiciera.", To = "Yo", Shot = "PrimerPlano:Mateo", If = { Flags = { "AyudasteAMateo" } } },
				{ S = "Mateo", T = "No dije nada porque… me dio miedo. Perdona.", To = "Yo", Shot = "Hombro:Yo>Mateo", If = { Flags = { "AyudasteAMateo" } } },
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Gracias por contármelo. Has sido valiente.»",
							Effects = { Flags = { "PistaMateo" }, Rel = { Mateo = 10 }, Traits = { Empatia = 1 } },
							Then = { { S = "Mateo", T = "¿Yo? ¿Valiente? Nadie me había dicho eso.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
						{
							T = "«¿Por qué no lo dijiste antes?»",
							Effects = { Flags = { "PistaMateo" }, Rel = { Mateo = -3 } },
							Then = { { S = "Mateo", T = "Ya… Lo siento. Es que Bruno da miedo.", To = "Yo", If = { Flags = { "AyudasteAMateo" } } } },
						},
					},
				},
			},
		},
		Testigo_Omar = {
			Lines = {
				{ S = "Omar", T = "Espera.", To = "Yo", Shot = "General", Effects = { Scene = "Cole02_Mochila_G9_3_Musica" } },
				{ S = "Omar", T = "Lo tengo dibujado.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Dibujo casi todo lo que pasa aquí.", To = "Yo", Shot = "Reaccion:Yo" },
				{ S = "Omar", T = "Mira. Va hacia el gimnasio. No vi su cara. Iba demasiado rápido.", To = "Yo", Shot = "General" },
				{ S = "Omar", T = "Los dibujos rápidos salen borrosos.", To = "Yo" },
			},
		},
		Testigo_Sara = {
			Lines = {
				{ S = "Sara", T = "¿Una mochila azul?", To = "Yo", Shot = "Medio:Sara", Effects = { Scene = "Cole02_Mochila_G9_2_Musica" } },
				{ S = "Sara", T = "Sí. Hace unos diez minutos. Salió por la ventana.", To = "Yo", Shot = "PrimerPlano:Sara" },
				{ S = "Sara", T = "Iba hacia el patio. La llevaba alguien con prisa.", To = "Yo", Shot = "Hombro:Sara>Yo" },
				{ S = "Sara", T = "Y llevaba una sudadera morada. Eso es importante.", To = "Yo", Shot = "PPP:Sara" },
			},
		},
	},
	Scenes = {
		Cole02_Mochila_G11_Musica = { Light = true, Duration = 33.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G12_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Mayor2", Npc = "Mayor2" } }, { At = 0, Use = { Key = "Mayor1", Npc = "Mayor1" } } },
				Dialogue = {
					{ At = 0.4, S = "Mayor1", T = "¡Ni la toques! ¡Esa es nuestra canasta!", To = "Yo" },
					{ At = 3.7, S = "Mayor2", T = "Álex siempre gana. Siempre.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Tension" } },
			},
		},
		Cole02_Mochila_G13_Musica = { Light = true, Duration = 28, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole02_Mochila_G15_Musica = { Light = true, Duration = 34.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G16_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Narrador", T = "Nadie parece estar mirando." } }, Music = { { At = 0, Intensity = "Tension" } } },
		},
		Cole02_Mochila_G17_Musica = { Light = true, Duration = 13.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G19_Musica = { Light = true, Duration = 21.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G1_Fin = {
			Light = true,
			Duration = 23.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Ruben", Npc = "Ruben" } }, { At = 0, Use = { Key = "Bruno", Npc = "Bruno" } } },
				Dialogue = {
					{ At = 3.8, S = "Narrador", T = "Han pasado unos días." },
					{ At = 6.1, S = "Narrador", T = "Ya conoces los pasillos." },
					{ At = 8.6, S = "Narrador", T = "Algunas caras ya empiezan a resultarte familiares." },
					{ At = 12.5, S = "Narrador", T = "Y algunas personas… empiezan a mostrar quiénes son." },
					{ At = 16.4, S = "Bruno", T = "Psst.", To = "Yo" },
					{ At = 18.5, S = "Bruno", T = "Luego.", To = "Yo" },
					{ At = 20.5, S = "Ruben", T = "Vale.", To = "Yo", Mood = "Joy" },
				},
				Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 11.3, Intensity = "Descubrimiento" } },
				Titles = { { At = 0.4, Duration = 3.2, Text = "Unos días después…" } },
			},
		},
		Cole02_Mochila_G21_Musica = { Light = true, Duration = 92.5, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole02_Mochila_G3_Musica = { Light = true, Duration = 19.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole02_Mochila_G4_Musica = { Light = true, Duration = 19.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole02_Mochila_G5_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 1.3, S = "Yo", T = "¿Y mi mochila?" } }, Music = { { At = 0, Intensity = "Tension" } } },
		},
		Cole02_Mochila_G6_Musica = { Light = true, Duration = 18, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G8_Musica = { Light = true, Duration = 29.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G9_1_Musica = { Light = true, Duration = 14, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G9_2_Musica = { Light = true, Duration = 17.1, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G9_3_Musica = { Light = true, Duration = 18.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Cole02_Mochila_G9_4_Musica = { Light = true, Duration = 22.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = {
		["1"] = { Effects = { Scene = "Cole02_Mochila_G1_Fin" } },
		["10"] = { Set = { Text = "Busca pistas en el patio" } },
		["11"] = { Effects = { Scene = "Cole02_Mochila_G12_Entra" } },
		["12"] = { Set = { Text = "Sigue las pistas hasta el gimnasio" } },
		["14"] = { Set = { Text = "¡Mete 3 canastas!" } },
		["15"] = { Effects = { Scene = "Cole02_Mochila_G16_Entra" } },
		["16"] = { Set = { Text = "Ve al almacén del gimnasio" } },
		["18"] = { Set = { Text = "Revisa las mochilas del almacén" } },
		["2"] = { Set = { Text = "Ve a clase (1.º A)" } },
		["20"] = { Set = { Text = "Esconde la gorra de Rubén" } },
		["4"] = { Effects = { Scene = "Cole02_Mochila_G5_Entra" } },
		["5"] = { Set = { Text = "Vuelve a clase" } },
		["7"] = { Set = { Text = "Busca tu mochila en el aula" } },
		["9"] = { Set = { Text = "Pregunta a tus compañeros" } },
	},
}
