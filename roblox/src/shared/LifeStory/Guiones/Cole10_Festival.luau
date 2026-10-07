-- GUION REESCRITO de Cole10_Festival (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Cole10_Festival.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Cole10_Festival
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Cole10_Festival.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Cole10_Festival.md",
	Dialogues = {
		Anuncio = {
			Lines = {
				{ S = "Lucia", T = "Atención, clase. Gracias.", To = "Yo", Effects = { Scene = "Cole10_G3_Musica" } },
				{ S = "Marta", T = "¡Y música!", To = "Yo" },
				{ S = "Nico", T = "¡Y comida!", To = "Yo" },
				{ S = "Omar", T = "¡He oído comida!", To = "Yo" },
				{ S = "Lucia", T = "Habrá puestos, música, teatro y concurso de talentos.", To = "Yo" },
				{ S = "Marisa", T = "¡He oído «libros»! Cada uno elegirá una tarea.", To = "Yo", Pause = 0.9 },
				{ S = "Hugo", T = "Yo… He escrito una obra de teatro.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Hugo", T = "Si alguien quiere participar.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Nico", T = "¡YO!", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Hugo", T = "Gracias.", To = "Yo", If = { Flags = { "HugoConElGrupo" } } },
				{ S = "Iker", T = "Según mis datos, el año pasado se vendieron cuarenta y dos magdalenas.", To = "Yo", If = { Flags = { "IkerEnElGrupo" } } },
				{ S = "Iker", T = "Podemos superar esa cifra.", To = "Yo", Pause = 0.9, If = { Flags = { "IkerEnElGrupo" } } },
				{ S = "Omar", T = "Ese es el espíritu.", To = "Yo", If = { Flags = { "IkerEnElGrupo" } } },
			},
		},
		Apertura = {
			Lines = {
				{ S = "Familia", T = "¡{nombre}! ¡Qué bonito está todo!", To = "Yo", Effects = { Scene = "Cole10_G19_Musica" } },
				{ S = "Abu", T = "En mis tiempos teníamos una mesa y cuatro galletas.", To = "Yo" },
				{ S = "Abu", T = "Esto parece una feria.", To = "Yo", Pause = 0.9 },
				{ S = "Lucia", T = "Bienvenidos al festival de primavera. Y entonces…", To = "Yo" },
			},
		},
		Cierre = {
			Lines = {
				{
					S = "Abu",
					T = "¡Eso sí que no lo hacía cuando tenía tu edad!",
					To = "Yo",
					If = { Flags = { "AplausoFinal" } },
					Effects = { Scene = "Cole10_G24_Musica" },
				},
				{ S = "Lucia", T = "Eso también es valentía.", To = "Yo", If = { NotFlags = { "AplausoFinal" } } },
				{ S = "Lucia", T = "Gracias a todos.", To = "Yo" },
				{ S = "Marisa", T = "¡LIBROS!", To = "Yo", Pause = 0.9 },
				{ S = "Bruno", T = "El puesto ha funcionado.", To = "Yo", If = { Choices = { FestivalBruno = "Ayudar" } } },
				{ S = "Ruben", T = "Ya lo has dicho.", To = "Yo", Pause = 0.9, If = { Choices = { FestivalBruno = "Ayudar" } } },
				{ S = "Bruno", T = "Rubén.", To = "Yo", If = { Choices = { FestivalBruno = "Ayudar" } } },
			},
		},
		Comida_Harina = { Lines = { { S = "Omar", T = "Harina.", To = "Yo" } } },
		Comida_Huevos = { Lines = { { S = "Omar", T = "¡Ni uno roto!", To = "Yo", If = { Flags = { "TareaBrillante" } } } } },
		Deco_Cartel = { Lines = { { S = "Vega", T = "Ahora formas parte de la decoración.", To = "Yo" } } },
		Deco_Farolillos = { Lines = { { S = "Vega", T = "Parece que el patio está sonriendo.", To = "Yo" } } },
		Deco_Guirnalda = { Lines = { { S = "Vega", T = "Un poco más arriba. Ahora a la izquierda. ¡Perfecto!", To = "Yo" } } },
		Ensayo_Musica = { Lines = { { S = "Marta", T = "No pienses demasiado. Ahí está. Ya suena a festival.", To = "Yo", Effects = { Scene = "Cole10_G8_Musica" } } } },
		Ensayo_Teatro = {
			Lines = {
				{ S = "Hugo", T = "Tu frase llega al final. Es importante.", To = "Yo" },
				{ S = "Yo", T = "¿Qué digo? ¡La llave número mil estaba en nuestro corazón!" },
				{ S = "Nico", T = "¡CRUAC!", To = "Yo" },
				{ S = "Hugo", T = "Y tú eres un loro.", To = "Yo" },
				{ S = "Nico", T = "¡Un loro profesional!", To = "Yo" },
				{ S = "Hugo", T = "Nunca nadie había querido hacer una obra mía. Gracias.", To = "Yo" },
			},
		},
		Foto_Columpios = { Lines = { { S = "Sara", T = "Esta es buena. No sé por qué. Pero lo es.", To = "Yo" } } },
		Foto_Entrada = { Lines = { { S = "Sara", T = "Aquí empezó todo. ¿Te acuerdas?", To = "Yo" } } },
		Foto_Escenario = { Lines = { { S = "Sara", T = "Primera fotografía. Antes de que empiece todo.", To = "Yo" } } },
		Imp_Altavoz = {
			Lines = {
				{ S = "Ramon", T = "A ver… Aquí está. Desenchufado.", To = "Yo" },
				{ S = "Ramon", T = "Treinta años de conserje.", To = "Yo" },
				{ S = "Ramon", T = "Y siempre acaba siendo un cable.", To = "Yo" },
			},
		},
		Imp_Bruno = {
			Lines = {
				{ S = "Ruben", T = "Tenemos cero clientes.", To = "Yo" },
				{ S = "Bruno", T = "No son cero. Somos nosotros dos.", To = "Yo" },
				{ S = "Ruben", T = "Eso son dos. Por primera vez no está enfadado. Está decepcionado.", To = "Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "Le ayudas: «Déjame a mí, sonríe y ofrece probarla gratis»",
							Effects = { Choice = { FestivalBruno = "Ayudar" }, Rel = { Bruno = 8, Ruben = 4 }, Traits = { Empatia = 1 } },
							Then = {
								{ S = "Narrador", T = "Pruebas gratis, sonrisas… En cinco minutos hay cola en el puesto de Bruno." },
								{ S = "Bruno", T = "…Vale. Ha funcionado. No te lo voy a agradecer en voz alta. …Gracias. En voz baja." },
							},
						},
						{
							T = "Le compras un vaso y le dices que está buena",
							Effects = { Choice = { FestivalBruno = "Comprar" }, Rel = { Bruno = 4 }, Spend = 2 },
							Then = { { S = "Bruno", T = "¿A que sí? ¡A que está buena! …Ya van dos vasos. Uno era mío, pero cuenta." } },
						},
						{
							T = "Le dejas con su puesto: tienes otras cosas que hacer",
							Effects = { Choice = { FestivalBruno = "Nada" } },
							Then = { { S = "Bruno", T = "Ya. Como todos." } },
						},
					},
				},
			},
		},
		Imp_Farolillos = { Lines = { { S = "Vega", T = "¡Lo has conseguido! ¡No hemos perdido ni uno!", To = "Yo" } } },
		Imp_Perdida = {
			Lines = {
				{ S = "Alumno4", T = "No encuentro a mi mamá.", To = "Yo" },
				{ S = "Yo", T = "La buscamos juntos. Llevarla con Lucía." },
				{ S = "Lucia", T = "Has hecho bien en traerla.", To = "Yo" },
				{ S = "Lucia", T = "empatia +2 o responsabilidad +2.", To = "Yo" },
				{
					Ask = "¿Qué haces?",
					Options = {
						{
							T = "Te agachas y le das la mano: «La buscamos juntos»",
							Effects = { Choice = { NinaPerdida = "Juntos" }, Traits = { Empatia = 2 } },
							Then = {
								{ S = "Narrador", T = "Dais una vuelta por el patio. Enseguida aparece su madre, que la estaba buscando por la otra puerta." },
								{ S = "Alumno2", T = "¡Gracias! Cuando sea mayor quiero ser como tú." },
							},
						},
						{
							T = "La llevas con Lucía, que sabe qué hacer",
							Effects = { Choice = { NinaPerdida = "Lucia" }, Rel = { Lucia = 3 }, Traits = { Responsabilidad = 2 } },
							Then = { { S = "Lucia", T = "Bien hecho. Lo anuncio por el altavoz… ¡que ya funciona! Y su madre llega corriendo en un minuto." } },
						},
					},
				},
			},
		},
		Talentos = {
			Lines = {
				{ S = "Marta", T = "Y ahora… ¡Concurso de talentos!", To = "Yo", Effects = { Scene = "Cole10_G22_Musica" } },
				{ S = "Marta", T = "Niños levantando las manos. Otros escondiéndose.", To = "Yo" },
				{ S = "Omar", T = "Yo no existo.", To = "Yo" },
				{ S = "Marta", T = "¿Quién se atreve? Yo te acompaño.", To = "Yo" },
				{ S = "Nico", T = "Esto va a ser histórico. O vergonzoso.", To = "Yo" },
				{ S = "Nico", T = "Cuando otro niño duda…", To = "Yo" },
				{
					Ask = "¿Subes al escenario?",
					Options = {
						{
							T = "Subo a cantar la canción del festival",
							Effects = { Choice = { Talento = "Cantar" }, Flags = { "SubesAlEscenario" } },
							Then = { { S = "Marta", T = "♪ ¡Qué valiente! ♪ Yo te acompaño con el piano." } },
						},
						{
							T = "Subo a contar chistes con Nico",
							Effects = { Choice = { Talento = "Chistes" }, Flags = { "SubesAlEscenario" }, Rel = { Nico = 4 } },
							Then = { { S = "Nico", T = "¿Por qué el libro de mates está triste? ¡Porque tiene muchos problemas! …¡Ríete, {nombre}, que es tu turno!" } },
						},
						{
							T = "Me quedo abajo animando a los demás",
							Effects = { Choice = { Talento = "Animar" }, Traits = { Empatia = 1 } },
							Then = {
								{
									S = "Narrador",
									T = "Aplaudes más fuerte que nadie. Mateo sube a hacer un truco de magia y te busca con la mirada. Le sonríes. Le sale perfecto.",
									If = { Flags = { "AyudasteAMateo" } },
								},
								{
									S = "Narrador",
									T = "Aplaudes más fuerte que nadie. Cada vez que alguien se pone nervioso en el escenario, te busca con la mirada y le sonríes.",
									If = { NotFlags = { "AyudasteAMateo" } },
								},
							},
						},
					},
				},
			},
		},
		TuParte = {
			Lines = {
				{ S = "Familia", T = "¿Vosotros habéis hecho todo esto?", To = "Yo" },
				{ S = "Vega", T = "¡Todo!", To = "Yo" },
				{ S = "Omar", T = "¡Se han acabado! ¡VEINTE MINUTOS!", To = "Yo" },
				{ S = "Iker", T = "Exactamente diecinueve minutos y treinta y ocho segundos.", To = "Yo", If = { Flags = { "IkerEnElGrupo" } } },
				{ S = "Omar", T = "¡Eso!", To = "Yo", If = { Flags = { "IkerEnElGrupo" } } },
				{ S = "Sara", T = "Antes y después.", To = "Yo" },
				{ S = "Nico", T = "¡CRUAC!", To = "Yo" },
				{ S = "Lucia", T = "Lo habéis hecho de maravilla.", To = "Yo", If = { Flags = { "TareaBrillante" } } },
				{ S = "Lucia", T = "No todo ha salido perfecto.", To = "Yo", If = { NotFlags = { "TareaBrillante" } } },
				{ S = "Lucia", T = "Pero así son las fiestas de verdad.", To = "Yo", If = { NotFlags = { "TareaBrillante" } } },
				{ S = "Lucia", T = "Y ha sido un día precioso.", To = "Yo", If = { NotFlags = { "TareaBrillante" } } },
			},
		},
	},
	Scenes = {
		Cole10_G10_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = { { At = 0.4, S = "Omar", T = "Bienvenid{o/a} a la cocina. No comas nada.", To = "Yo" } },
			},
		},
		Cole10_G12_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Omar", Npc = "Omar" } } },
				Dialogue = { { At = 0.4, S = "Omar", T = "Mira eso. Son demasiado bonitas para comerlas.", To = "Yo" } },
			},
		},
		Cole10_G16_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Hugo", Npc = "Hugo" } } },
				Dialogue = {
					{ At = 0.4, S = "Hugo", T = "Esa es.", To = "Yo", If = { Flags = { "TareaBrillante" } } },
					{ At = 2.9, S = "Hugo", T = "Bien. No pasa nada. A mí también me pasa.", To = "Yo", If = { NotFlags = { "TareaBrillante" } } },
				},
			},
		},
		Cole10_G18_Entra = {
			Light = true,
			Duration = 11.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Ruben", Npc = "Ruben" } }, { At = 0, Use = { Key = "Bruno", Npc = "Bruno" } } },
				Dialogue = {
					{ At = 0.4, S = "Bruno", T = "¡Limonada! ¡La mejor de Valmar!", To = "Yo" },
					{ At = 3.4, S = "Ruben", T = "Bruno, estás gritando.", To = "Yo" },
					{ At = 5.9, S = "Bruno", T = "¡Eso ayuda!", To = "Yo" },
					{ At = 8.4, S = "Ruben", T = "No parece.", To = "Yo" },
				},
			},
		},
		Cole10_G19_Musica = { Light = true, Duration = 16.4, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole10_G1_Fin = {
			Light = true,
			Duration = 3.7,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Narrador", T = "El curso seguía avanzando." } }, Music = { { At = 0, Intensity = "Descubrimiento" } } },
		},
		Cole10_G22_Musica = { Light = true, Duration = 20.9, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole10_G24_Musica = { Light = true, Duration = 21, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Intima" } } } },
		Cole10_G25 = {
			Skippable = true,
			Duration = 30.7,
			Anchors = { L_FamiliaPadre = "Place:FamiliaPadre", Sitio = "Place:Patio", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Hugo", Npc = "Hugo" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
					{ At = 0, Use = { Key = "Bruno", Npc = "Bruno" } },
					{ At = 0, Use = { Key = "Vega", Npc = "Vega" } },
					{ At = 0, Use = { Key = "Lucia", Npc = "Lucia" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
				},
				Camera = {
					{ At = 0.4, Duration = 2, Shot = "General:Sitio" },
					{ At = 2.4, Duration = 2, Shot = "General:Sitio" },
					{ At = 4.4, Duration = 2, Shot = "Medio:Omar" },
					{ At = 6.4, Duration = 2, Shot = "Medio:Vega" },
					{ At = 8.4, Duration = 2, Shot = "PrimerPlano:Hugo" },
					{ At = 10.4, Duration = 2, Shot = "Reaccion:Bruno" },
					{ At = 12.4, Duration = 2, Shot = "Medio:Yo" },
					{ At = 14.4, Duration = 2, Shot = "Dolly:Lucia" },
					{ At = 16.4, Duration = 2, Shot = "General:L_FamiliaPadre" },
					{ At = 18.4, Duration = 11.6, Shot = "Seguir:Yo" },
				},
				Dialogue = {
					{ At = 18.4, S = "Omar", T = "Ha sido un buen día.", To = "Yo" },
					{ At = 20.9, S = "Sara", T = "Técnicamente, muy buen día.", To = "Yo" },
					{ At = 23.6, S = "Nico", T = "Y todavía queda mañana. ¿Hay magdalenas?", To = "Yo" },
					{ At = 27.3, S = "Omar", T = "No. Me he comido la última.", To = "Yo" },
				},
				Music = { { At = 0, Intensity = "Intima" } },
			},
			Sting = "Momento",
		},
		Cole10_G3_Musica = {
			Light = true,
			Duration = 42.8,
			Anchors = { Yo = "Player" },
			Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" }, { At = 21.4, Intensity = "Intima" } } },
		},
		Cole10_G4_Entra = {
			Light = true,
			Duration = 27.9,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Hugo", Npc = "Hugo" } },
					{ At = 0, Use = { Key = "Sara", Npc = "Sara" } },
					{ At = 0, Use = { Key = "Vega", Npc = "Vega" } },
					{ At = 0, Use = { Key = "Marta", Npc = "Marta" } },
					{ At = 0, Use = { Key = "Omar", Npc = "Omar" } },
					{ At = 0, Use = { Key = "Nico", Npc = "Nico" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Vega", T = "¡Sabía que vendrías! Banderines, farolillos y un cartel enorme. Y purpurina.", To = "Yo" },
					{ At = 6.6, S = "Marta", T = "♪ Pom, pom, pom-pom. ♪", To = "Yo" },
					{ At = 9.1, S = "Omar", T = "Magdalenas. Muchas.", To = "Yo" },
					{ At = 11.6, S = "Sara", T = "Documentaremos todo. Antes, durante y después.", To = "Yo" },
					{ At = 15.7, S = "Sara", T = "Quiero que podamos recordar cómo era este día.", To = "Yo" },
					{ At = 19.8, S = "Hugo", T = "¿De verdad?", To = "Yo" },
					{ At = 22.3, S = "Nico", T = "¡Yo soy el loro!", To = "Yo" },
					{ At = 24.8, S = "Hugo", T = "Sí. Lo eres.", To = "Yo" },
				},
			},
		},
		Cole10_G8_Musica = { Light = true, Duration = 6.5, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Descubrimiento" } } } },
		Cole10_G9_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Marta", Npc = "Marta" } } },
				Dialogue = { { At = 0.4, S = "Marta", T = "No fallaste ni una. Algunas se escaparon. Pero aprendiste.", To = "Yo" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Cole10_G1_Fin" } },
		["11"] = { Effects = { Scene = "Cole10_G12_Entra" } },
		["15"] = { Effects = { Scene = "Cole10_G16_Entra" } },
		["17"] = { Effects = { Scene = "Cole10_G18_Entra" } },
		["25"] = { Set = { Id = "Cole10_G25" } },
		["3"] = { Effects = { Scene = "Cole10_G4_Entra" } },
		["8"] = { Effects = { Scene = "Cole10_G9_Entra" } },
		["9"] = { Effects = { Scene = "Cole10_G10_Entra" } },
	},
}
