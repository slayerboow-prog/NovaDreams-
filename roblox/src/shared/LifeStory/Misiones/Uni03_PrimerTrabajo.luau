-- UNIVERSIDAD 03 · «EL PRIMER TRABAJO» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.33.
--
-- Hace falta dinero (libros, transporte, lo que querías ahorrar) → tu perfil de empleo en la
-- biblioteca (la carta de recomendación del instituto ayuda) → ofertas (cafetería con Omar y Lola,
-- reparto con Ernesto, clases particulares a Alba) → entrevista → primer día → la jornada (trabajo de
-- verdad con JobService, o tres clases con Alba) → el conflicto: te piden cubrir un turno la víspera
-- de un examen → el examen (bonus si no cubriste) → tu primera nómina.

local V = Vector3.new

local CAFE = { Choices = { TrabajoUni = "Cafeteria" } }
local REPARTO = { Choices = { TrabajoUni = "Reparto" } }
local CLASES = { Choices = { TrabajoUni = "Clases" } }
local CARTA = { Flags = { "TieneCartaRecomendacion" } }

local OFERTAS = {
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 4) },
	{ Npc = "Omar", Place = "CafeteriaCentral", Offset = V(3, 0, 2) },
	{ Npc = "Ernesto", Place = "Correos", Offset = V(0, 0, 4) },
	{ Npc = "Rocio", Place = "Biblioteca", Offset = V(4, 0, 3) },
}
local TRABAJO = {
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 4), If = CAFE },
	{ Npc = "Omar", Place = "CafeteriaCentral", Offset = V(3, 0, 2), If = CAFE },
	{ Npc = "Ernesto", Place = "Correos", Offset = V(0, 0, 4), If = REPARTO },
	{ Npc = "Alba", Place = "Biblioteca", Offset = V(2, 0, 3), Scale = 0.65, If = CLASES },
	{ Npc = "Rocio", Place = "Biblioteca", Offset = V(-3, 0, 4), If = CLASES },
}
local ALBA = {
	{ Npc = "Alba", Place = "Biblioteca", Offset = V(2, 0, 3), Scale = 0.65 },
}

return {
	Id = "Uni03_PrimerTrabajo",
	Kind = "Main",
	Title = "El primer trabajo",
	Description = "Los libros, el bus, la vida… Hace falta un trabajo que encaje con las clases. Y aprender a decir que no.",
	Chapter = "Joven_Universidad",
	AgeRange = { 19, 19 },
	Duration = { 20, 30 },
	Difficulty = 2,
	Type = "Historia · Trabajo",
	Requires = { Completed = { "Uni02_ElProyecto" }, StageProgress = 0.36 },
	Npcs = { "Familia", "Lola", "Omar", "Ernesto", "Rocio", "Alba", "Beltran" },
	Locations = { "HomeSalon", "Biblioteca", "CafeteriaCentral", "Correos", "$Carrera.Facultad" },
	Next = { "Uni04_Practicas" },
	Outcomes = { "Cafetería, reparto o clases particulares", "Cubrir el turno o estudiar", "Tu primera nómina" },

	Moment = "Tu primer trabajo de universitario",
	Memory = "PrimerTrabajoUni",
	Rewards = { Money = 120, Items = { ContratoTrabajo = 1 } },

	Props = {
		Ordenador = { Kind = "Marcador", Name = "Ordenadores de la biblioteca", Prompt = "Crear tu perfil de empleo", Place = "Biblioteca", Offset = V(-4, 0, 2), Dialogue = "Perfil", Once = true },
		OfertaCafe = { Kind = "Papel", Name = "Oferta: cafetería (tardes)", Prompt = "Leer", Place = "CafeteriaCentral", Offset = V(-3, 0, 3), Dialogue = "Oferta_Cafe", Once = true },
		OfertaReparto = { Kind = "Papel", Name = "Oferta: reparto (fines de semana)", Prompt = "Leer", Place = "Correos", Offset = V(-3, 0, 3), Dialogue = "Oferta_Reparto", Once = true },
		OfertaClases = { Kind = "Papel", Name = "Anuncio: «Busco profe particular»", Prompt = "Leer", Place = "Biblioteca", Offset = V(6, 0, -2), Dialogue = "Oferta_Clases", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Enero. La cuesta de enero.", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Cuentas", Teleport = "HomeSalon",
			Actors = { { Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) } } },
		{ Type = "Use", Prop = "Ordenador", Text = "Crea tu perfil de empleo en la biblioteca del campus" },
		{ Type = "Group", Text = "Mira las ofertas (al menos dos)", Need = 2,
			Steps = {
				{ Type = "Use", Prop = "OfertaCafe", Text = "Cafetería Central" },
				{ Type = "Use", Prop = "OfertaReparto", Text = "Correos" },
				{ Type = "Use", Prop = "OfertaClases", Text = "Tablón de la biblioteca" },
			},
			Actors = OFERTAS },
		{ Type = "Choice", Key = "TrabajoUni", Text = "¿Qué trabajo coges? (habla con quien contrata)",
			Options = {
				{ Id = "Cafeteria", Npc = "Lola", Text = "Cafetería, con Lola (y Omar en la cocina)", Dialogue = "Entrevista_Lola", Effects = { Rel = { Lola = 4, Omar = 4 } } },
				{ Id = "Reparto", Npc = "Ernesto", Text = "Reparto, con Ernesto", Dialogue = "Entrevista_Ernesto", Effects = { Rel = { Ernesto = 4 } } },
				{ Id = "Clases", Npc = "Rocio", Text = "Clases particulares a Alba", Dialogue = "Entrevista_Rocio", Effects = { Rel = { Rocio = 4 } } },
			},
			Actors = OFERTAS },

		-- La jornada
		{ Type = "Reach", Place = "CafeteriaCentral", Text = "Primer día en la cafetería", If = CAFE, Actors = TRABAJO, Late = { After = 240, Flags = { "LlegasTardeTrabajoUni" } } },
		{ Type = "Reach", Place = "Correos", Text = "Primer día en Correos", If = REPARTO, Actors = TRABAJO, Late = { After = 240, Flags = { "LlegasTardeTrabajoUni" } } },
		{ Type = "Reach", Place = "Biblioteca", Text = "Primera clase con Alba (biblioteca del campus)", If = CLASES, Actors = TRABAJO, Late = { After = 240, Flags = { "LlegasTardeTrabajoUni" } } },
		{ Type = "Scene", Dialogue = "PrimerDia", Actors = TRABAJO },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Barista" }, Count = 3, If = CAFE, Place = "CafeteriaCentral",
			Text = "Empieza el turno (tablón de trabajo) y sirve cafés ({count}/{total})", Actors = TRABAJO },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Repartidor" }, Count = 3, If = REPARTO, Place = "Correos",
			Text = "Empieza el turno (tablón de trabajo) y reparte ({count}/{total})", Actors = TRABAJO },
		{ Type = "Talk", Npc = "Alba", Dialogue = "Clase1", Text = "Clase 1: las fracciones", If = CLASES, Actors = ALBA },
		{ Type = "MiniGame", Game = "Timing", Title = "Explica las fracciones con dinosaurios", Icon = "🦕", Hint = "Cada explicación, en su momento",
			Rounds = 5, Need = 3, Zone = 0.26, Speed = 1, If = CLASES,
			Win = { Flags = { "AlbaEntiende" }, Rel = { Alba = 6 } }, Lose = { Traits = { Humor = 1 } }, Actors = ALBA },
		{ Type = "Talk", Npc = "Alba", Dialogue = "Clase2", Text = "Clase 2: el examen de Alba", If = CLASES, Actors = ALBA },

		-- El conflicto
		{ Type = "Scene", Dialogue = "Conflicto", Actors = TRABAJO },
		{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Estudio", Place = "Biblioteca", Text = "Estudia para el examen de mañana", If = { NotFlags = { "CubristeTurno" } } },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Barista" }, Count = 2, If = { Flags = { "CubristeTurno" }, Choices = { TrabajoUni = "Cafeteria" } }, Place = "CafeteriaCentral",
			Text = "Cubre el turno de la noche ({count}/{total})", Actors = TRABAJO },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Repartidor" }, Count = 2, If = { Flags = { "CubristeTurno" }, Choices = { TrabajoUni = "Reparto" } }, Place = "Correos",
			Text = "Cubre el reparto de la tarde ({count}/{total})", Actors = TRABAJO },
		{ Type = "Talk", Npc = "Alba", Dialogue = "ClaseExtra", Text = "Clase extra con Alba", If = { Flags = { "CubristeTurno" }, Choices = { TrabajoUni = "Clases" } }, Actors = ALBA },
		{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Examen", Place = "$Carrera.Facultad", Text = "El examen",
			Bonus = { If = { NotFlags = { "CubristeTurno" } }, Seconds = 5 },
			Actors = { { Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) } } },

		-- La nómina
		{ Type = "Scene", Dialogue = "Nomina", Actors = TRABAJO },
	},

	Dialogues = {
		Cuentas = { Lines = {
			{ S = "Familia", T = "Los libros de este cuatrimestre… ¿cuánto? ¿Por un libro? ¿Está escrito en oro?" },
			{ S = "Familia", T = "Te ayudamos en lo que podamos, ya lo sabes. Pero quizá un trabajito de unas horas te vendría bien." },
			{ S = "Familia", T = "Y lo de la cámara que querías desde el instituto… podrías acercarte por fin.", If = { Choices = { Meta = "Camara" } } },
			{ S = "Familia", T = "Lo que ahorraste aquel verano te ha venido muy bien. Pero se va acabando.", If = { Choices = { Meta = "Ahorro" } } },
		} },
		Perfil = { Lines = {
			{ S = "Narrador", T = "Nombre, estudios, disponibilidad: tardes libres y fines de semana. Y la parte difícil: «¿Qué te hace especial?»" },
			{ S = "Narrador", T = "Adjuntas la carta de recomendación de tu primer verano. «Puntual, honesto y con ganas de aprender.» Valía oro, sí.", If = CARTA },
			{ S = "Narrador", T = "Pones tu primer trabajo de verano. Y el club del instituto. Todo cuenta.", If = { NotFlags = { "TieneCartaRecomendacion" } } },
		} },
		Oferta_Cafe = { Lines = { { S = "Narrador", T = "«Cafetería Central busca camarero/a de tardes. Horario flexible para estudiantes. Preguntar por Lola.»" } } },
		Oferta_Reparto = { Lines = { { S = "Narrador", T = "«Correos: repartidores de fin de semana. Buena paga. Imprescindible conocer Valmar (y no temer a los perros).»" } } },
		Oferta_Clases = { Lines = { { S = "Narrador", T = "«Busco profe particular para mi hija Alba (9 años). Matemáticas. Mucha paciencia. Llamar a Rocío.» Hay dinosaurios dibujados en el papel." } } },

		Entrevista_Lola = { Lines = {
			{ S = "Lola", T = "¡{nombre}! ¡Mi mejor ayudante de verano! Bueno, mi único ayudante de verano. ¿Buscas trabajo? Estás contratado o contratada. Esa es la entrevista.", If = { Choices = { Empleo = "Barista" } } },
			{ S = "Lola", T = "¿Una carta de recomendación? A ver… ¡de Paco! Si Paco dice algo bueno de alguien, es que es un santo. Contratado o contratada.", If = { Flags = { "TieneCartaRecomendacion" }, Choices = { Empleo = "Reponedor" } } },
			{ S = "Lola", T = "Siéntate. ¿Sabes llevar tres cafés a la vez? No. Nadie sabe. Aprenderás. Empiezas el lunes." },
			{ S = "Omar", T = "(desde la cocina) ¡Vamos a trabajar juntos! ¡Como en el festival! ¡Pero con sueldo!" },
		} },
		Entrevista_Ernesto = { Lines = {
			{ S = "Ernesto", T = "¡Anda, el terror del perro del 14! ¿Vuelves? Te guardo la ruta de siempre.", If = { Choices = { Empleo = "Repartidor" } } },
			{ S = "Ernesto", T = "Fines de semana, paquetes y piernas. ¿Te ves? Pues empiezas el sábado." },
		} },
		Entrevista_Rocio = { Lines = {
			{ S = "Rocio", T = "¡Hola! Soy Rocío, la madre de Alba. Trabajo de noche en el hospital y no llego a ayudarla con los deberes." },
			{ S = "Rocio", T = "Alba odia las matemáticas. Pero adora los dinosaurios. Si consigues unir las dos cosas, eres un genio." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Las fracciones con dinosaurios. Tengo un plan.»", Effects = { Traits = { Creatividad = 1 } }, Then = {
					{ S = "Rocio", T = "¡Me encanta! Estás contratado o contratada. Martes y jueves en la biblioteca del campus." },
				} },
				{ T = "«Con paciencia. Yo también odiaba algo y alguien me ayudó.»", Effects = { Traits = { Empatia = 1 } }, Then = {
					{ S = "Rocio", T = "Eso es justo lo que necesita. Martes y jueves, en la biblioteca del campus." },
				} },
			} },
		} },

		PrimerDia = { Lines = {
			{ S = "Lola", T = "Delantal, sonrisa y ¡a la barra! Esta vez sin tirar bandejas, ¿eh?", If = CAFE },
			{ S = "Ernesto", T = "Mochila, mapa y paquetes. El perro del 14 ya no ladra. Ahora me ladra a mí.", If = REPARTO },
			{ S = "Alba", T = "¿Tú eres la profe? ¿O el profe? Da igual. ¿Te gustan los dinosaurios? Porque si no, esto no va a funcionar.", If = CLASES },
			{ S = "Narrador", T = "Llegas tarde al primer día. Nadie dice nada. Pero lo notas.", If = { Flags = { "LlegasTardeTrabajoUni" } } },
		} },
		Clase1 = { Lines = {
			{ S = "Alba", T = "Las fracciones no sirven para nada. NADA." },
			{ S = "Narrador", T = "Dibujas un tiranosaurio que se come la mitad de una pizza. Luego un cuarto. Alba deja de protestar." },
			{ S = "Alba", T = "…¿Y si se come tres cuartos? ¿Le duele la tripa? ¿Y por qué? ¿Y por qué es un cuarto y no un cinco?" },
		} },
		Clase2 = { Lines = {
			{ S = "Alba", T = "¡He sacado un siete en el examen de fracciones! ¡UN SIETE! ¡El tiranosaurio y yo lo hemos conseguido!", If = { Flags = { "AlbaEntiende" } } },
			{ S = "Alba", T = "He sacado un cinco. Aprobado. Todavía no entiendo por qué el tiranosaurio no se come la pizza entera.", If = { NotFlags = { "AlbaEntiende" } } },
			{ S = "Rocio", T = "No sabes lo que significa esto para nosotras. Gracias." },
		}, Effects = { Rel = { Alba = 4, Rocio = 4 } } },
		Conflicto = { Lines = {
			{ S = "Lola", T = "{nombre}, emergencia: esta noche falta alguien. ¿Puedes cubrir el turno? Te lo pago doble.", If = CAFE },
			{ S = "Ernesto", T = "Tengo cuarenta paquetes y nadie para repartirlos esta tarde. ¿Me echas una mano? Pago extra.", If = REPARTO },
			{ S = "Rocio", T = "Mañana Alba tiene el examen final de matemáticas y está nerviosísima. ¿Podrías darle una clase extra esta tarde?", If = CLASES },
			{ S = "Narrador", T = "El problema: mañana tienes examen. Y todavía no has repasado." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Aceptar: el trabajo es el trabajo", Effects = { Flags = { "CubristeTurno" }, Money = 30, Rel = { Lola = 4, Ernesto = 4, Rocio = 4 } }, Then = {
					{ S = "Narrador", T = "Aceptas. Te llevarás el dinero extra… y llegarás al examen con menos repaso." },
				} },
				{ T = "Decir que no, con educación: «Mañana tengo examen»", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Lola = -1, Ernesto = -1, Rocio = -1 } }, Then = {
					{ S = "Lola", T = "Claro, claro. Los estudios primero. Lo arreglo con otra persona. Suerte mañana.", If = CAFE },
					{ S = "Ernesto", T = "Entendido. Primero el examen. Ya me apaño con los perros.", If = REPARTO },
					{ S = "Rocio", T = "Lo entiendo perfectamente. Le diré a Alba que confíe en el tiranosaurio.", If = CLASES },
				} },
				{ T = "Proponer a Omar para cubrirlo", If = CAFE, Effects = { Rel = { Omar = 3, Lola = 2 } }, Then = {
					{ S = "Omar", T = "¿Turno doble? ¿Con croquetas gratis a las tres de la mañana? Hecho. Tú a estudiar." },
				} },
			} },
		} },
		ClaseExtra = { Lines = {
			{ S = "Alba", T = "¿Otra vez fracciones? …Vale. Pero hoy el dinosaurio es un triceratops." },
			{ S = "Narrador", T = "Una hora más de dinosaurios y pizzas. Alba sale sonriendo. Tú sales pensando en tu examen de mañana." },
		} },
		Nomina = { Lines = {
			{ S = "Narrador", T = "Tu primera nómina de verdad. Con tu nombre, tus horas y hasta impuestos. Te sientes muy adulto o adulta. Un poco." },
			{ S = "Narrador", T = "El examen fue bien: habías repasado. Trabajar y estudiar a la vez se puede, si sabes decir que no a tiempo.", If = { NotFlags = { "CubristeTurno" }, LastGradeAtLeast = 6 } },
			{ S = "Narrador", T = "El examen fue regular: llegaste sin repasar. El dinero extra está bien, pero la próxima vez quizá digas que no.", If = { Flags = { "CubristeTurno" }, LastGradeBelow = 6 } },
			{ S = "Omar", T = "¡Primera nómina! Esto hay que celebrarlo. Invito yo a croquetas. Bueno, invita Lola. Pero se lo pido yo.", If = CAFE },
			{ S = "Alba", T = "Te he hecho un dibujo. Eres tú. Con un tiranosaurio. Es para tu nevera.", If = CLASES },
		} },
	},
}
