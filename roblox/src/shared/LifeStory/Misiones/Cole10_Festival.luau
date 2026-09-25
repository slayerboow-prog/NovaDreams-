-- MISIÓN 10 · «EL FESTIVAL» (30-40 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.20.
--
-- Lucía anuncia el festival de primavera → eliges tu responsabilidad (decoración con Vega, música con
-- Marta, comida con Omar, fotos con Sara o teatro con Hugo) → la preparas → el día del festival: tu
-- familia viene, y hay imprevistos (el viento, el altavoz, una niña perdida, el puesto de Bruno) →
-- tu parte sale bien (o regular) → el concurso de talentos: subes al escenario o animas → cierre.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }

local DECORACION = { Choices = { Festival = "Decoracion" } }
local MUSICA = { Choices = { Festival = "Musica" } }
local COMIDA = { Choices = { Festival = "Comida" } }
local FOTOS = { Choices = { Festival = "Fotos" } }
local TEATRO = { Choices = { Festival = "Teatro" } }
local SUBES = { Flags = { "SubesAlEscenario" } }

local CLASE = {
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	{ Npc = "Marta", Place = "PizarraA", Offset = V(0, 0, 4), Look = V(1, 0, 0) },
	{ Npc = "Vega", Place = "AulaA", Offset = V(-4, 0, 2) },
	{ Npc = "Omar", Place = "AulaA", Offset = V(3, 0, -2) },
	{ Npc = "Sara", Place = "AulaA", Offset = V(-2, 0, -3) },
	{ Npc = "Nico", Place = "AulaA", Offset = V(4, 0, 3) },
	{ Npc = "Hugo", Place = "AulaA", Offset = V(-5, 0, -2), If = CON_HUGO },
	{ Npc = "Iker", Place = "AulaA", Offset = V(6, 0, -1), If = CON_IKER },
	{ Npc = "Mateo", Place = "AulaA", Offset = V(1, 0, 5), If = AMIGO_MATEO },
}

-- El día del festival: el patio lleno de gente
local FESTIVAL = {
	{ Npc = "Lucia", Place = "Patio", Offset = V(0, 0, 8) },
	{ Npc = "Marta", Place = "Patio", Offset = V(4, 0, 10) },
	{ Npc = "Andres", Place = "Patio", Offset = V(-6, 0, 10) },
	{ Npc = "Familia", Place = "Patio", Offset = V(-10, 0, 4), Mode = "Wave" },
	{ Npc = "Abu", Place = "Patio", Offset = V(-12, 0, 6) },
	{ Npc = "Ramon", Place = "Patio", Offset = V(12, 0, 8) },
	{ Npc = "Nico", Place = "Patio", Offset = V(-3, 0, 2) },
	{ Npc = "Sara", Place = "Patio", Offset = V(3, 0, 2) },
	{ Npc = "Omar", Place = "Patio", Offset = V(0, 0, -3) },
	{ Npc = "Vega", Place = "Patio", Offset = V(7, 0, -2) },
	{ Npc = "Hugo", Place = "Patio", Offset = V(-6, 0, -2), If = CON_HUGO },
	{ Npc = "Mateo", Place = "Patio", Offset = V(5, 0, 5), If = AMIGO_MATEO },
	{ Npc = "Bruno", Place = "Patio", Offset = V(14, 0, -6), Bark = "¡Limonada! ¡La mejor limonada de Valmar! …¿Nadie?" },
	{ Npc = "Ruben", Place = "Patio", Offset = V(16, 0, -4) },
	{ Npc = "Alumno2", Place = "Patio", Offset = V(-14, 0, -8), Mode = "Idle" },
	{ Npc = "Alumno1", Place = "Patio", Offset = V(10, 0, 14), Mode = "Wander", Radius = 8 },
	{ Npc = "Alumno3", Place = "Patio", Offset = V(-8, 0, 14), Mode = "Wander", Radius = 8 },
}

return {
	Id = "Cole10_Festival",
	Kind = "Main",
	Title = "El festival",
	Description = "El festival de primavera del colegio: cada uno tiene una tarea. Y el día del festival, nada sale como estaba previsto.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 10, 10 },
	Duration = { 30, 40 },
	Difficulty = 3,
	Type = "Historia · Evento del colegio",
	Requires = { Completed = { "Cole09_Misterio" }, StageProgress = 0.72 },
	Npcs = { "Lucia", "Marta", "Andres", "Vega", "Omar", "Sara", "Nico", "Hugo", "Iker", "Mateo", "Bruno", "Ruben", "Ramon", "Familia", "Abu", "Alumno2" },
	Locations = { "AulaA", "Patio", "AulaMusica", "ComedorColegio", "GimnasioColegio", "JuegosColegio", "Vestibulo" },
	Next = { "Cole11_Proyecto" },
	Outcomes = { "Tu tarea en el festival", "Qué imprevistos resuelves", "Subir al escenario o animar", "Ayudar (o no) a Bruno" },

	Moment = "El festival de primavera",
	Memory = "ElFestival",
	Rewards = { Items = { FotoFestival = 1 }, Money = 10 },

	Props = {
		-- Decoración
		Guirnalda1 = { Kind = "Marcador", Name = "Guirnalda de banderines", Prompt = "Colgar", Place = "Patio", Offset = V(-8, 0, 6), Color = Color3.fromRGB(240, 90, 90), Dialogue = "Deco_Guirnalda", Once = true },
		Guirnalda2 = { Kind = "Marcador", Name = "Farolillos de papel", Prompt = "Colgar", Place = "Patio", Offset = V(8, 0, 6), Color = Color3.fromRGB(250, 200, 60), Dialogue = "Deco_Farolillos", Once = true },
		Cartel = { Kind = "Mural", Name = "El cartel del festival", Prompt = "Pintar", Place = "Patio", Offset = V(0, 0, 12), Dialogue = "Deco_Cartel", Once = true },
		-- Comida
		Harina = { Kind = "Caja", Name = "Harina y azúcar", Prompt = "Coger", Place = "ComedorColegio", Offset = V(-3, 0, 2), Color = Color3.fromRGB(245, 240, 225), Dialogue = "Comida_Harina", Once = true },
		Huevos = { Kind = "Caja", Name = "Una caja de huevos", Prompt = "Coger con cuidado", Place = "ComedorColegio", Offset = V(3, 0, 2), Color = Color3.fromRGB(230, 200, 150), Dialogue = "Comida_Huevos", Once = true },
		-- Fotos
		Foto1 = { Kind = "Marcador", Name = "El escenario", Prompt = "Hacer una foto", Place = "Patio", Offset = V(0, 0, 10), Dialogue = "Foto_Escenario", Once = true },
		Foto2 = { Kind = "Marcador", Name = "Los columpios", Prompt = "Hacer una foto", Place = "JuegosColegio", Dialogue = "Foto_Columpios", Once = true },
		Foto3 = { Kind = "Marcador", Name = "La entrada del cole", Prompt = "Hacer una foto", Place = "Vestibulo", Dialogue = "Foto_Entrada", Once = true },
		-- Imprevistos
		Farolillos = { Kind = "Marcador", Name = "¡Los farolillos se vuelan!", Prompt = "Sujetar", Place = "Patio", Offset = V(10, 0, 4), Color = Color3.fromRGB(250, 200, 60), Spin = true, Dialogue = "Imp_Farolillos", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Llega la primavera a Valmar…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase", Actors = CLASE },
		{ Type = "Scene", Dialogue = "Anuncio", Actors = CLASE },
		{ Type = "Choice", Key = "Festival", Text = "¿De qué te encargas en el festival? (habla con quien lo organiza)",
			Options = {
				{ Id = "Decoracion", Npc = "Vega", Text = "Decoración, con Vega", Dialogue = "Elige_Decoracion", Effects = { Rel = { Vega = 5 } } },
				{ Id = "Musica", Npc = "Marta", Text = "Música, con Marta", Dialogue = "Elige_Musica", Effects = { Rel = { Marta = 5 } } },
				{ Id = "Comida", Npc = "Omar", Text = "Comida, con Omar", Dialogue = "Elige_Comida", Effects = { Rel = { Omar = 5 } } },
				{ Id = "Fotos", Npc = "Sara", Text = "Fotos, con Sara", Dialogue = "Elige_Fotos", Effects = { Rel = { Sara = 5 } } },
				{ Id = "Teatro", Npc = "Hugo", Text = "Teatro, con Hugo", Dialogue = "Elige_Teatro", If = CON_HUGO, Effects = { Rel = { Hugo = 6 } } },
			},
			Actors = CLASE },

		-- La preparación: cada tarea, la suya
		{ Type = "Reach", Place = "Patio", Text = "Ve al patio a decorar con Vega", If = DECORACION,
			Actors = { { Npc = "Vega", Place = "Patio", Offset = V(0, 0, 4) } } },
		{ Type = "Group", Text = "Decora el patio", If = DECORACION,
			Steps = {
				{ Type = "Use", Prop = "Guirnalda1", Text = "Cuelga la guirnalda de banderines" },
				{ Type = "Use", Prop = "Guirnalda2", Text = "Cuelga los farolillos" },
				{ Type = "Use", Prop = "Cartel", Text = "Pinta el cartel del festival" },
			},
			Effects = { Traits = { Creatividad = 2 }, Rel = { Vega = 5 } },
			Actors = { { Npc = "Vega", Mode = "Follow" } } },

		{ Type = "Reach", Place = "AulaMusica", Text = "Ve al aula de música a ensayar", If = MUSICA,
			Actors = { { Npc = "Marta", Place = "AulaMusica", Offset = V(0, 0, 4) } } },
		{ Type = "Scene", Dialogue = "Ensayo_Musica", If = MUSICA, Actors = { { Npc = "Marta", Place = "AulaMusica", Offset = V(0, 0, 4) } } },
		{ Type = "MiniGame", Game = "Timing", Title = "Ensayo: toca a tiempo", Icon = "🎵", Hint = "Toca la nota cuando la aguja esté en verde",
			Rounds = 6, Need = 4, Zone = 0.25, Speed = 1, If = MUSICA,
			Win = { Flags = { "TareaBrillante" }, Rel = { Marta = 4 }, Traits = { Creatividad = 1 } }, Lose = { Traits = { Humor = 1 } },
			Actors = { { Npc = "Marta", Place = "AulaMusica", Offset = V(0, 0, 4) } } },

		{ Type = "Reach", Place = "ComedorColegio", Text = "Ve al comedor: Omar te espera con el delantal puesto", If = COMIDA,
			Actors = { { Npc = "Omar", Place = "ComedorColegio", Offset = V(0, 0, 4) } } },
		{ Type = "Group", Text = "Reúne los ingredientes", If = COMIDA,
			Steps = {
				{ Type = "Use", Prop = "Harina", Text = "Harina y azúcar" },
				{ Type = "Use", Prop = "Huevos", Text = "Los huevos (con cuidado)" },
			},
			Actors = { { Npc = "Omar", Place = "ComedorColegio", Offset = V(0, 0, 4) } } },
		{ Type = "MiniGame", Game = "Timing", Title = "Decora las magdalenas", Icon = "🧁", Hint = "Pon la guinda cuando la aguja esté en verde",
			Rounds = 6, Need = 4, Zone = 0.26, Speed = 1, If = COMIDA,
			Win = { Flags = { "TareaBrillante" }, Rel = { Omar = 4 } }, Lose = { Traits = { Humor = 1 } },
			Actors = { { Npc = "Omar", Place = "ComedorColegio", Offset = V(0, 0, 4) } } },

		{ Type = "Group", Text = "Haz las fotos para el mural del festival", If = FOTOS,
			Steps = {
				{ Type = "Use", Prop = "Foto1", Text = "El escenario (patio)" },
				{ Type = "Use", Prop = "Foto2", Text = "Los columpios (zona de juegos)" },
				{ Type = "Use", Prop = "Foto3", Text = "La entrada del cole" },
			},
			Effects = { Traits = { Curiosidad = 2 }, Rel = { Sara = 5 }, Flags = { "TareaBrillante" } },
			Actors = { { Npc = "Sara", Mode = "Follow" } } },

		{ Type = "Reach", Place = "GimnasioColegio", Text = "Ve al gimnasio a ensayar la obra", If = TEATRO,
			Actors = { { Npc = "Hugo", Place = "GimnasioColegio", Offset = V(0, 0, 4) }, { Npc = "Nico", Place = "GimnasioColegio", Offset = V(4, 0, 3) } } },
		{ Type = "Scene", Dialogue = "Ensayo_Teatro", If = TEATRO,
			Actors = { { Npc = "Hugo", Place = "GimnasioColegio", Offset = V(0, 0, 4) }, { Npc = "Nico", Place = "GimnasioColegio", Offset = V(4, 0, 3) } } },
		{ Type = "MiniGame", Game = "Timing", Title = "Ensayo: di tu frase a tiempo", Icon = "🎭", Hint = "Habla cuando la aguja esté en verde",
			Rounds = 5, Need = 3, Zone = 0.25, Speed = 1, If = TEATRO,
			Win = { Flags = { "TareaBrillante" }, Rel = { Hugo = 4 } }, Lose = { Traits = { Humor = 1 } },
			Actors = { { Npc = "Hugo", Place = "GimnasioColegio", Offset = V(0, 0, 4) }, { Npc = "Nico", Place = "GimnasioColegio", Offset = V(4, 0, 3) } } },

		-- El día del festival
		{ Type = "Transition", Text = "El viernes, el día del festival…", Seconds = 3 },
		{ Type = "Reach", Place = "Patio", Text = "Ve al patio: ¡empieza el festival!", Actors = FESTIVAL },
		{ Type = "Scene", Dialogue = "Apertura", Actors = FESTIVAL },
		{ Type = "Group", Text = "¡Imprevistos! Resuelve al menos tres", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "Farolillos", Text = "El viento se lleva los farolillos" },
				{ Type = "Talk", Npc = "Ramon", Dialogue = "Imp_Altavoz", Text = "El altavoz no suena: avisa a Ramón" },
				{ Type = "Talk", Npc = "Alumno2", Dialogue = "Imp_Perdida", Text = "Una niña de 1.º llora junto a la valla" },
				{ Type = "Talk", Npc = "Bruno", Dialogue = "Imp_Bruno", Text = "Al puesto de limonada de Bruno no va nadie" },
			},
			Actors = FESTIVAL },
		{ Type = "Scene", Dialogue = "TuParte", Actors = FESTIVAL },
		{ Type = "Scene", Dialogue = "Talentos", Actors = FESTIVAL },
		{ Type = "MiniGame", Game = "Timing", Title = "¡Tu número en el escenario!", Icon = "🎤", Hint = "Sigue el ritmo: pulsa en la zona verde",
			Rounds = 5, Need = 3, Zone = 0.26, Speed = 1, If = SUBES,
			Win = { Flags = { "AplausoFinal" }, Traits = { Valentia = 1 } }, Lose = { Traits = { Humor = 1 } },
			Actors = FESTIVAL },
		{ Type = "Scene", Dialogue = "Cierre", Actors = FESTIVAL },
		{ Type = "Cinematic", Id = "Cole10_Festival", Actors = FESTIVAL },
	},

	Dialogues = {
		Anuncio = { Lines = {
			{ S = "Lucia", T = "¡Noticia! El viernes que viene celebramos el festival de primavera. Vendrán las familias, habrá puestos, música, teatro…" },
			{ S = "Marta", T = "♪ …y un concurso de talentos ♪ …perdón, lo digo cantando sin querer." },
			{ S = "Lucia", T = "Con lo que se recaude en los puestos compraremos libros nuevos para la biblioteca. Marisa está emocionadísima." },
			{ S = "Lucia", T = "Cada uno elige una tarea. Hablad con quien la organiza: Vega, la decoración; Marta, la música; Omar, la comida; Sara, las fotos." },
			{ S = "Hugo", T = "Y… yo he escrito una obra de teatro. De piratas. Si alguien quiere… no hace falta, ¿eh?", If = CON_HUGO },
			{ S = "Iker", T = "Según mis datos, el año pasado se vendieron cuarenta y dos magdalenas. Este año podemos batirlo.", If = CON_IKER },
		} },
		Elige_Decoracion = { Lines = {
			{ S = "Vega", T = "¡Bien! Tengo un plan: banderines rojos, farolillos amarillos y un cartel ENORME. Con purpurina. Mucha purpurina." },
		} },
		Elige_Musica = { Lines = {
			{ S = "Marta", T = "♪ Qué alegría ♪ Tocaremos la canción del festival. Tú llevarás el ritmo. ¿Tienes buen oído? Lo vamos a averiguar." },
		} },
		Elige_Comida = { Lines = {
			{ S = "Omar", T = "SABÍA que vendrías. Magdalenas. Vamos a hacer las mejores magdalenas de la historia. Y a probar muchas. Por control de calidad." },
		} },
		Elige_Fotos = { Lines = {
			{ S = "Sara", T = "Documentaremos el festival científicamente. Es decir: fotos. Muchas fotos. Con buena luz." },
		} },
		Elige_Teatro = { Lines = {
			{ S = "Hugo", T = "¿De verdad? ¿Quieres hacer la obra conmigo? Se llama «La isla de las mil llaves». Como el libro. Nico hará de loro." },
			{ S = "Nico", T = "¡Soy un loro con mucha personalidad!" },
		} },

		Deco_Guirnalda = { Lines = { { S = "Vega", T = "¡Más arriba! ¡Un poco a la izquierda! ¡Perfecto! Bueno, casi. Perfecto." } } },
		Deco_Farolillos = { Lines = { { S = "Narrador", T = "Los farolillos amarillos se balancean con el aire. Con el sol a través parecen de miel." } } },
		Deco_Cartel = { Lines = {
			{ S = "Narrador", T = "Pintas «FESTIVAL DE PRIMAVERA» con letras gordas. Vega añade purpurina. Y más purpurina. El patio brilla." },
			{ S = "Vega", T = "Somos un gran equipo. Mira, te has manchado la nariz de purpurina. Te queda bien." },
		} },
		Ensayo_Musica = { Lines = {
			{ S = "Marta", T = "La canción tiene un ritmo sencillo: pom… pom… pom-pom. Tú llevas el tambor. Escucha y toca en el momento justo." },
		} },
		Comida_Harina = { Lines = { { S = "Omar", T = "Harina, azúcar… y un poquito de harina en la cara, que es lo que hacen los cocineros de verdad." } } },
		Comida_Huevos = { Lines = { { S = "Omar", T = "Con cuidado… con cuidado… ¡Ninguno roto! Somos unos profesionales." } } },
		Foto_Escenario = { Lines = { { S = "Sara", T = "El escenario vacío, antes de la fiesta. Es la foto del «antes». Luego haremos la del «después»." } } },
		Foto_Columpios = { Lines = { { S = "Narrador", T = "Clic. Un columpio se mueve solo con el viento. Sara dice que es tu mejor foto. Tú también lo crees." } } },
		Foto_Entrada = { Lines = { { S = "Sara", T = "La puerta del cole. Por aquí entraste el primer día. Dentro de nada, todo el mundo entrará por aquí a la fiesta." } } },
		Ensayo_Teatro = { Lines = {
			{ S = "Hugo", T = "Tu papel es el de capitán. Solo tienes una frase importante: «¡La llave número mil estaba en nuestro corazón!»" },
			{ S = "Nico", T = "¡Cruac! ¡Cruac! ¿Los loros dicen cruac? ¡Da igual! ¡CRUAC!" },
			{ S = "Hugo", T = "Nunca nadie había querido hacer una obra mía. Gracias." },
		} },

		Apertura = { Lines = {
			{ S = "Narrador", T = "El patio está lleno: puestos, globos, música, familias. Huele a magdalenas y a limonada." },
			{ S = "Familia", T = "¡{nombre}! ¡Qué bonito está todo! ¿Esto lo habéis hecho vosotros?" },
			{ S = "Abu", T = "En mis tiempos el festival era una mesa con galletas. Esto es como una feria." },
			{ S = "Lucia", T = "¡Bienvenidos todos al festival de primavera!" },
			{ S = "Narrador", T = "Y justo entonces… sopla un viento fuertísimo. Se oye un «¡Ay!» y un «¡Mis farolillos!». Y el altavoz hace «¡PFFFZZ!»." },
			{ S = "Lucia", T = "¡{nombre}! ¿Puedes echar una mano? Pasan cosas por todas partes." },
		} },
		Imp_Farolillos = { Lines = {
			{ S = "Narrador", T = "Saltas y agarras la cuerda justo a tiempo. Vega la ata a la farola con un nudo doble." },
			{ S = "Vega", T = "¡Me has salvado los farolillos! Esto se merece purpurina extra." },
		}, Effects = { Rel = { Vega = 4 }, Traits = { Responsabilidad = 1 } } },
		Imp_Altavoz = { Lines = {
			{ S = "Ramon", T = "¿Que no suena? A ver… ¡claro! Alguien ha desenchufado el cable para cargar un móvil." },
			{ S = "Ramon", T = "Listo. Buen aviso. Treinta años de conserje y el problema siempre es un cable." },
		}, Effects = { Rel = { Ramon = 4 } } },
		Imp_Perdida = { Lines = {
			{ S = "Alumno2", T = "(llorando) No encuentro a mi mamá… Había mucha gente y… y ahora no la veo." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Te agachas y le das la mano: «La buscamos juntos»", Effects = { Traits = { Empatia = 2 }, Choice = { NinaPerdida = "Juntos" } }, Then = {
					{ S = "Narrador", T = "Dais una vuelta por el patio. Enseguida aparece su madre, que la estaba buscando por la otra puerta." },
					{ S = "Alumno2", T = "¡Gracias! Cuando sea mayor quiero ser como tú." },
				} },
				{ T = "La llevas con Lucía, que sabe qué hacer", Effects = { Traits = { Responsabilidad = 2 }, Rel = { Lucia = 3 }, Choice = { NinaPerdida = "Lucia" } }, Then = {
					{ S = "Lucia", T = "Bien hecho. Lo anuncio por el altavoz… ¡que ya funciona! Y su madre llega corriendo en un minuto." },
				} },
			} },
		} },
		Imp_Bruno = { Lines = {
			{ S = "Bruno", T = "¿Qué miras? Ya sé que no viene nadie. La limonada está buenísima. Pero nadie se acerca a mi puesto." },
			{ S = "Ruben", T = "(Rubén, bajito:) Es que Bruno grita «¡COMPRAD!» y la gente se asusta." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Le ayudas: «Déjame a mí, sonríe y ofrece probarla gratis»", Effects = { Rel = { Bruno = 8, Ruben = 4 }, Traits = { Empatia = 1 }, Choice = { FestivalBruno = "Ayudar" } }, Then = {
					{ S = "Narrador", T = "Pruebas gratis, sonrisas… En cinco minutos hay cola en el puesto de Bruno." },
					{ S = "Bruno", T = "…Vale. Ha funcionado. No te lo voy a agradecer en voz alta. …Gracias. En voz baja." },
				} },
				{ T = "Le compras un vaso y le dices que está buena", Effects = { Rel = { Bruno = 4 }, Spend = 2, Choice = { FestivalBruno = "Comprar" } }, Then = {
					{ S = "Bruno", T = "¿A que sí? ¡A que está buena! …Ya van dos vasos. Uno era mío, pero cuenta." },
				} },
				{ T = "Le dejas con su puesto: tienes otras cosas que hacer", Effects = { Choice = { FestivalBruno = "Nada" } }, Then = {
					{ S = "Bruno", T = "Ya. Como todos." },
				} },
			} },
		} },

		TuParte = { Lines = {
			{ S = "Familia", T = "¿Los banderines y el cartel los habéis hecho vosotros? ¡Hasta brillan!", If = DECORACION },
			{ S = "Narrador", T = "Suena la canción del festival. Tú llevas el tambor: pom… pom… pom-pom. Nadie se equivoca. Bueno, casi nadie.", If = MUSICA },
			{ S = "Omar", T = "¡Las magdalenas se han acabado en veinte minutos! ¡Récord! Iker lo ha apuntado.", If = COMIDA },
			{ S = "Sara", T = "Nuestro mural de fotos está lleno de gente mirándolo. Las del «antes» y las del «después»: ¡funciona!", If = FOTOS },
			{ S = "Narrador", T = "La obra de Hugo arranca aplausos. Tú dices tu frase: «¡La llave número mil estaba en nuestro corazón!». Nico hace de loro con demasiada energía.", If = TEATRO },
			{ S = "Lucia", T = "Lo habéis hecho de maravilla. Se nota que habéis ensayado.", If = { Flags = { "TareaBrillante" } } },
			{ S = "Lucia", T = "No todo ha salido perfecto… pero así son las fiestas de verdad. ¡A todos les ha encantado!", If = { NotFlags = { "TareaBrillante" } } },
		} },
		Talentos = { Lines = {
			{ S = "Marta", T = "♪ Y ahora… ¡el concurso de talentos! ♪ ¿Quién se atreve a subir al escenario?" },
			{ S = "Omar", T = "Yo no. Mi talento es comer magdalenas y ya lo he demostrado." },
			{ Ask = "¿Subes al escenario?", Options = {
				{ T = "Subo a cantar la canción del festival", Effects = { Flags = { "SubesAlEscenario" }, Choice = { Talento = "Cantar" } }, Then = {
					{ S = "Marta", T = "♪ ¡Qué valiente! ♪ Yo te acompaño con el piano." },
				} },
				{ T = "Subo a contar chistes con Nico", Effects = { Flags = { "SubesAlEscenario" }, Choice = { Talento = "Chistes" }, Rel = { Nico = 4 } }, Then = {
					{ S = "Nico", T = "¿Por qué el libro de mates está triste? ¡Porque tiene muchos problemas! …¡Ríete, {nombre}, que es tu turno!" },
				} },
				{ T = "Me quedo abajo animando a los demás", Effects = { Choice = { Talento = "Animar" }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Narrador", T = "Aplaudes más fuerte que nadie. Mateo sube a hacer un truco de magia y te busca con la mirada. Le sonríes. Le sale perfecto.", If = AMIGO_MATEO },
					{ S = "Narrador", T = "Aplaudes más fuerte que nadie. Cada vez que alguien se pone nervioso en el escenario, te busca con la mirada y le sonríes.", If = { NotFlags = { "AyudasteAMateo" } } },
				} },
			} },
		} },
		Cierre = { Lines = {
			{ S = "Narrador", T = "El público se pone en pie. Tu familia aplaude y {abu} silba con dos dedos. Nadie sabía que sabía hacer eso.", If = { Flags = { "AplausoFinal" } } },
			{ S = "Narrador", T = "Te tiembla la voz a mitad de número… y el público aplaude más fuerte para ayudarte. Acabas riéndote. Todos se ríen contigo.", If = { Flags = { "SubesAlEscenario" }, NotFlags = { "AplausoFinal" } } },
			{ S = "Lucia", T = "¡Gracias a todos! Con lo recaudado, la biblioteca tendrá libros nuevos. Y creo que alguno será de piratas." },
			{ S = "Bruno", T = "El puesto de limonada ha recaudado más que el de magdalenas. …Casi. Gracias a {nombre}.", If = { Choices = { FestivalBruno = "Ayudar" } } },
			{ S = "Familia", T = "Qué día tan bonito. Me he hecho una foto con todo tu grupo. Esta va a la nevera." },
		} },
	},
}
