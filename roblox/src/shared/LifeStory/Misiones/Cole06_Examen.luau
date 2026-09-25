-- MISIÓN 06 · «EL EXAMEN IMPOSIBLE» (20-25 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.16.
--
-- Lucía anuncia el examen → conseguir los apuntes en la biblioteca (Marisa) → elegir compañero de
-- estudio → sesión de estudio → por la noche, en casa: repasar más (segundos extra en el examen), ver
-- la tele o pedir ayuda a Abu → el examen (10 preguntas) → la nota. Si suspendes: «Recuperación».

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }

local BIBLIOTECA = {
	{ Npc = "Marisa", Place = "SpotBibliotecaria" },
	{ Npc = "Sara", Place = "BibliotecaColegio", Offset = V(-4, 0, 0) },
	{ Npc = "Iker", Place = "SpotInformanteBiblioteca" },
	{ Npc = "Mateo", Place = "BibliotecaColegio", Offset = V(4, 0, -2), If = AMIGO_MATEO },
}

return {
	Id = "Cole06_Examen",
	Kind = "Main",
	Title = "El examen imposible",
	Description = "Mañana hay examen de Matemáticas. «El más difícil del trimestre», dice Lucía. Tienes un día.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 8, 9 },
	Duration = { 20, 25 },
	Difficulty = 3,
	Type = "Historia · Estudios",
	Requires = { Completed = { "Cole05_Venganza" }, StageProgress = 0.30 },
	Npcs = { "Lucia", "Marisa", "Sara", "Iker", "Mateo", "Nico", "Familia", "Abu" },
	Locations = { "AulaA", "BibliotecaColegio", "ApuntesBiblioteca", "HomeSalon" },
	Next = { "Nino_Recados" },
	Outcomes = { "Aprobado con esfuerzo", "Sobresaliente", "Suspenso → Recuperación" },

	Moment = "Tu primer examen de verdad",
	Rewards = { Money = 10 },

	Props = {
		Apuntes = { Kind = "Libro", Name = "Apuntes de Matemáticas", Prompt = "Coger los apuntes", Place = "ApuntesBiblioteca", Offset = V(-6, 0, 3), Dialogue = "CogerApuntes", Once = true, Color = Color3.fromRGB(60, 120, 200) },
		MesaSola = { Kind = "Marcador", Name = "Una mesa libre", Prompt = "Estudiar sin nadie", Place = "BibliotecaColegio", Offset = V(6, 0, 4) },
	},

	Steps = {
		{ Type = "Transition", Text = "Al día siguiente…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase", Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Scene", Dialogue = "Anuncio", Actors = {
			{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
			{ Npc = "Nico", Place = "AulaA", Offset = V(4, 0, 3) },
			{ Npc = "Sara", Place = "AulaA", Offset = V(-2, 0, -3) },
		} },

		-- Los apuntes
		{ Type = "Reach", Place = "BibliotecaColegio", Text = "Ve a la biblioteca a por los apuntes", Actors = BIBLIOTECA },
		{ Type = "Talk", Npc = "Marisa", Dialogue = "Marisa", Text = "Pregunta a Marisa, la bibliotecaria", Actors = BIBLIOTECA },
		{ Type = "Use", Prop = "Apuntes", Text = "Coge los apuntes de la mesa", Actors = BIBLIOTECA },

		-- ¿Con quién estudias?
		{ Type = "Choice", Key = "CompaneroEstudio", Text = "¿Con quién estudias? (habla con quien elijas o siéntate sin nadie)",
			Options = {
				{ Id = "Sara", Npc = "Sara", Text = "Con Sara", Dialogue = "Con_Sara", Effects = { Rel = { Sara = 5 } } },
				{ Id = "Iker", Npc = "Iker", Text = "Con Iker", Dialogue = "Con_Iker", Effects = { Rel = { Iker = 5 } } },
				{ Id = "Mateo", Npc = "Mateo", Text = "Con Mateo", Dialogue = "Con_Mateo", Effects = { Rel = { Mateo = 5 } } },
				{ Id = "Solo", Prop = "MesaSola", Text = "Sin nadie", Dialogue = "Sin_Nadie", Effects = { Traits = { Responsabilidad = 1 } } },
			},
			Actors = BIBLIOTECA },
		{ Type = "Class", Subject = "Matematicas", Mode = "Estudio", Place = "BibliotecaColegio", Text = "Estudia en la biblioteca",
			Effects = { Flags = { "Estudiaste" } }, Actors = BIBLIOTECA },
		{ Type = "Scene", Dialogue = "TrasEstudiar", Actors = BIBLIOTECA },

		-- La noche antes
		{ Type = "Transition", Text = "Esa noche, en casa…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Noche", Teleport = "HomeSalon",
			Actors = { { Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) }, { Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2) } } },
		{ Type = "Class", Subject = "Matematicas", Mode = "Estudio", Place = "HomeSalon", Text = "Repasa un poco más", If = { Flags = { "EstudiasteMas" } },
			Actors = { { Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) }, { Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2) } } },

		-- El examen
		{ Type = "Transition", Text = "El día del examen…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase: hoy es el examen", Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Scene", Dialogue = "Nervios", Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Class", Subject = "Matematicas", Mode = "Examen", Place = "AulaA", Text = "El examen de Matemáticas",
			Bonus = { If = { Flags = { "EstudiasteMas" } }, Seconds = 6 },
			Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Scene", Dialogue = "Aprobado", If = { LastGradeAtLeast = 5 }, Effects = { Memory = "PrimerExamen" },
			Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Scene", Dialogue = "Suspenso", If = { LastGradeBelow = 5 }, Effects = { Flags = { "SuspendisteExamen" }, Later = { { AfterMinutes = 1, Start = "Cole06b_Recuperacion" } } },
			Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Reach", Place = "BibliotecaColegio", Text = "Devuelve los apuntes a Marisa", Actors = { { Npc = "Marisa", Place = "SpotBibliotecaria" } } },
		{ Type = "Talk", Npc = "Marisa", Dialogue = "Devolver", Text = "Devuélvele los apuntes", Effects = { Take = { ApuntesBiblioteca = 1 } },
			Actors = { { Npc = "Marisa", Place = "SpotBibliotecaria" } } },
	},

	Dialogues = {
		Anuncio = { Lines = {
			{ S = "Lucia", T = "Atención. Mañana hay examen de Matemáticas. Sumas, restas, multiplicaciones y problemas." },
			{ S = "Lucia", T = "No os voy a mentir: es el examen más difícil del trimestre." },
			{ S = "Nico", T = "¿MAÑANA? ¡Pero si mañana hay partido en la tele!" },
			{ S = "Sara", T = "Yo ya he empezado a repasar. Hace tres semanas." },
			{ S = "Lucia", T = "En la biblioteca hay apuntes. Marisa os los presta. Y estudiar con alguien ayuda más de lo que creéis." },
		} },

		Marisa = { Lines = {
			{ S = "Marisa", T = "(susurrando) Hola, cielo. ¿Vienes por los apuntes de Matemáticas? Todo el mundo viene hoy por lo mismo." },
			{ S = "Marisa", T = "Están en la mesa grande. Te los apunto a tu nombre. Me los devuelves después del examen, ¿trato?" },
			{ S = "Marisa", T = "Y un consejo: no estudies con el estómago vacío. Los números se pegan mejor con un bocadillo." },
		}, Effects = { Remember = { { Npc = "Marisa", Fact = "SeConocen" } } } },
		CogerApuntes = { Lines = {
			{ S = "Narrador", T = "Los apuntes están llenos de dibujitos en los márgenes. Alguien de otro curso los usó antes… y dibujaba fatal." },
		}, Effects = { Items = { ApuntesBiblioteca = 1 } } },

		Con_Sara = { Lines = {
			{ S = "Sara", T = "¡Genial! Tengo un plan: cuarenta minutos de ejercicios, cinco de descanso, y repetir. Sin excusas." },
			{ S = "Yo", T = "¿Cuarenta minutos seguidos?" },
			{ S = "Sara", T = "Vale, veinte. Pero concentración total." },
		} },
		Con_Iker = { Lines = {
			{ S = "Iker", T = "¿Conmigo? ¡Nadie estudia nunca conmigo! Dato curioso: explicar algo a otro es la mejor forma de aprenderlo." },
			{ S = "Iker", T = "Bueno, ¿empezamos por las tablas? Tengo un truco para la del nueve con los dedos." },
		} },
		Con_Mateo = { Lines = {
			{ S = "Mateo", T = "¿Estudiamos juntos? Menos mal. Yo estoy… un poquito muy nervioso." },
			{ S = "Yo", T = "¿Has estudiado?" },
			{ S = "Mateo", T = "Más o menos." },
			{ S = "Yo", T = "Eso significa que no." },
			{ S = "Mateo", T = "Exacto. Por eso te necesito." },
		} },
		Sin_Nadie = { Lines = {
			{ S = "Narrador", T = "Te sientas en una mesa libre, junto a la ventana. Silencio. Solo tú y los números." },
		} },
		TrasEstudiar = { Lines = {
			{ S = "Sara", T = "Bien. Si mañana repasas otra vez en casa, el examen es tuyo.", If = { Choices = { CompaneroEstudio = "Sara" } } },
			{ S = "Iker", T = "Oye… gracias. Ha sido la mejor tarde en la biblioteca. Y eso que vengo todas.", If = { Choices = { CompaneroEstudio = "Iker" } } },
			{ S = "Mateo", T = "¡Ya me sé la del nueve! Mañana… a lo mejor no suspendo. A lo mejor.", If = { Choices = { CompaneroEstudio = "Mateo" } } },
			{ S = "Narrador", T = "Recoges tus cosas. La cabeza te echa un poco de humo, pero de humo bueno.", If = { Choices = { CompaneroEstudio = "Solo" } } },
		} },

		Noche = { Lines = {
			{ S = "Familia", T = "Te veo con cara de examen. ¿Mañana es el gordo?" },
			{ Ask = "¿Qué haces esta noche?", Options = {
				{ T = "Repasar un poco más antes de dormir", Effects = { Flags = { "EstudiasteMas" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Familia", T = "Así me gusta. Pero a las diez, a la cama, que un cerebro cansado no suma bien." },
				} },
				{ T = "Pedir ayuda a Abu", Effects = { Flags = { "EstudiasteMas" }, Rel = { Abu = 5 } }, Then = {
					{ S = "Abu", T = "¿Matemáticas? En mis tiempos contábamos con garbanzos. Trae, que te enseño un truco de cuando vendía fruta en el mercado." },
				} },
				{ T = "Ver el partido. Ya he estudiado bastante.", Effects = { Traits = { Humor = 1 } }, Then = {
					{ S = "Familia", T = "Bueno… tú sabrás. Pero mañana no me digas que no te avisé." },
				} },
			} },
		} },

		Nervios = { Lines = {
			{ S = "Narrador", T = "Hoja en blanco. Lápiz afilado. El reloj de la pared hace un ruido que antes nunca habías oído." },
			{ S = "Lucia", T = "Tenéis tiempo. Leed bien cada pregunta. Y respirad." },
			{ S = "Narrador", T = "Anoche repasaste. Te sientes con más calma: tendrás un poco más de tiempo para pensar.", If = { Flags = { "EstudiasteMas" } } },
		} },
		Aprobado = { Lines = {
			{ S = "Lucia", T = "Ya tengo las notas. {nombre}… aprobado. Y se nota el trabajo." },
			{ S = "Lucia", T = "Un sobresaliente. Estoy muy impresionada. De verdad.", If = { LastGradeAtLeast = 9 } },
			{ S = "Sara", T = "¡Lo sabía! El plan de los veinte minutos funciona.", If = { Choices = { CompaneroEstudio = "Sara" } } },
			{ S = "Mateo", T = "¡He aprobado yo también! ¡Por los pelos, pero aprobado!", If = { Choices = { CompaneroEstudio = "Mateo" } } },
			{ S = "Iker", T = "Dato curioso: estudiar acompañado mejora la nota. Acabamos de demostrarlo.", If = { Choices = { CompaneroEstudio = "Iker" } } },
		} },
		Suspenso = { Lines = {
			{ S = "Lucia", T = "{nombre}, ven un momento." },
			{ S = "Lucia", T = "Esta vez no ha salido. Pero un examen no dice quién eres: dice lo que te falta por practicar." },
			{ S = "Lucia", T = "Esta tarde hago clases de repaso. Si vienes, te doy otra oportunidad. ¿Trato?" },
			{ S = "Yo", T = "…Trato." },
		} },
		Devolver = { Lines = {
			{ S = "Marisa", T = "¡Los apuntes! Enteros y sin manchas de chocolate. Te acabas de ganar un sitio en mi lista de favoritos. No se lo digas a nadie." },
		} },
	},
}
