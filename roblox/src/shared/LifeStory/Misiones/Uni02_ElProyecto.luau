-- UNIVERSIDAD 02 · «EL PROYECTO» (25-40 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.32.
--
-- Beltrán encarga un proyecto en grupo. Tu grupo: Julia (lo hace todo), Pablo (no aparece), Adrián
-- (quiere mandar) y Carla (siempre llega tarde). Primera reunión desastrosa → cómo lo gestionas
-- (hacerlo todo, repartir, hablar con la profesora, pedir cambiar de grupo —no se puede— o sentarlos a
-- hablar) → conocer a cada uno por separado y descubrir qué le pasa → reorganizar el equipo → trabajar
-- → ensayo → la presentación (bonus si el equipo está unido) → la nota. 3 h después: Eco_Concierto.

local V = Vector3.new

local HACES_TODO = { Flags = { "HacesTodo" } }
local UNIDO = { Flags = { "EquipoUnido" } }
local function carrera(value: string): any
	return { Choices = { Estudios = value } }
end

local CLASE = {
	{ Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) },
	{ Npc = "Julia", Place = "$Carrera.Facultad", Offset = V(-4, 0, 3) },
	{ Npc = "Adrian", Place = "$Carrera.Facultad", Offset = V(4, 0, 3) },
	{ Npc = "Carla", Place = "$Carrera.Facultad", Offset = V(-6, 0, -1) },
}
local REUNION = {
	{ Npc = "Julia", Place = "Biblioteca", Offset = V(-3, 0, 2) },
	{ Npc = "Adrian", Place = "Biblioteca", Offset = V(3, 0, 2) },
	{ Npc = "Carla", Place = "Biblioteca", Offset = V(0, 0, 5) },
}
local EQUIPO_TODO = {
	{ Npc = "Julia", Place = "Biblioteca", Offset = V(-3, 0, 2) },
	{ Npc = "Adrian", Place = "Biblioteca", Offset = V(3, 0, 2) },
	{ Npc = "Carla", Place = "Biblioteca", Offset = V(0, 0, 5) },
	{ Npc = "Pablo", Place = "Biblioteca", Offset = V(5, 0, -2) },
}
local CADA_UNO = {
	{ Npc = "Julia", Place = "Biblioteca", Offset = V(-3, 0, 2) },
	{ Npc = "Adrian", Place = "$Carrera.Facultad", Offset = V(3, 0, 4) },
	{ Npc = "Carla", Place = "Parque", Offset = V(2, 0, 4) },
	{ Npc = "Alumno3", Place = "Parque", Offset = V(4, 0, 5), Scale = 0.65, Mode = "Idle" },
	{ Npc = "Pablo", Place = "PlazaCentro", Offset = V(0, 0, 6) },
}
local PRESENTA = {
	{ Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) },
	{ Npc = "Julia", Place = "$Carrera.Facultad", Offset = V(-3, 0, 2) },
	{ Npc = "Adrian", Place = "$Carrera.Facultad", Offset = V(3, 0, 2) },
	{ Npc = "Carla", Place = "$Carrera.Facultad", Offset = V(-5, 0, 0) },
	{ Npc = "Pablo", Place = "$Carrera.Facultad", Offset = V(5, 0, 0) },
}

return {
	Id = "Uni02_ElProyecto",
	Kind = "Main",
	Title = "El proyecto",
	Description = "Un proyecto en grupo que cuenta la mitad de la nota. Tu grupo: una que lo hace todo, uno que no aparece, uno que quiere mandar y una que siempre llega tarde.",
	Chapter = "Joven_Universidad",
	AgeRange = { 18, 19 },
	Duration = { 25, 40 },
	Difficulty = 3,
	Type = "Historia · Trabajo en equipo",
	Requires = { Completed = { "Uni01_PrimerDia" }, StageProgress = 0.18 },
	Npcs = { "Beltran", "Julia", "Pablo", "Adrian", "Carla", "Alumno3" },
	Locations = { "$Carrera.Facultad", "Biblioteca", "Parque", "PlazaCentro" },
	Next = { "Uni03_PrimerTrabajo" },
	Outcomes = { "Cómo gestionas el grupo", "Qué descubres de cada uno", "Equipo unido o todo el trabajo para ti", "La nota" },

	Moment = "El proyecto del grupo imposible",
	Memory = "ElProyectoUni",
	Rewards = { Items = { FotoEquipoUni = 1 }, Later = { { AfterHours = 3, Start = "Eco_Concierto", If = { Flags = { "PabloMusica" } } } } },

	Steps = {
		{ Type = "Transition", Text = "Octubre. Primeros trabajos de verdad.", Seconds = 3 },
		{ Type = "Reach", Place = "$Carrera.Facultad", Text = "Ve a tu facultad: clase con Beltrán", Actors = CLASE },
		{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Clase", Place = "$Carrera.Facultad", Text = "Clase con la profesora Beltrán", Actors = CLASE },
		{ Type = "Scene", Dialogue = "Encargo", Actors = CLASE },

		-- La primera reunión
		{ Type = "Reach", Place = "Biblioteca", Text = "Primera reunión del grupo en la biblioteca", Actors = REUNION,
			Late = { After = 200, Flags = { "LlegasTardeReunion" } } },
		{ Type = "Scene", Dialogue = "Reunion", Actors = REUNION },
		{ Type = "Choice", Key = "Gestion", Text = "El grupo es un desastre. ¿Qué haces?",
			Options = {
				{ Id = "Todo", Text = "Lo hago yo todo, así al menos sale bien", Flags = { "HacesTodo" }, Effects = { Traits = { Responsabilidad = 1 } } },
				{ Id = "Repartir", Text = "Repartir tareas y fechas en un documento", Effects = { Traits = { Responsabilidad = 1 } } },
				{ Id = "Profesora", Text = "Hablar con la profesora Beltrán", Dialogue = "Gestion_Profesora", Effects = { Rel = { Beltran = 4 } } },
				{ Id = "Cambiar", Text = "Pedir que me cambien de grupo", Dialogue = "Gestion_Cambiar", Stay = true },
				{ Id = "Hablar", Text = "Hablar con cada uno: ¿qué le pasa?", Effects = { Traits = { Empatia = 1 } } },
			},
			Actors = REUNION },

		-- Conocer a cada uno
		{ Type = "Group", Text = "Habla con cada miembro del grupo por separado",
			Steps = {
				{ Type = "Talk", Npc = "Julia", Dialogue = "Julia", Text = "Julia (biblioteca)" },
				{ Type = "Talk", Npc = "Adrian", Dialogue = "Adrian", Text = "Adrián (en la facultad)" },
				{ Type = "Talk", Npc = "Carla", Dialogue = "Carla", Text = "Carla (en el parque)" },
				{ Type = "Talk", Npc = "Pablo", Dialogue = "Pablo", Text = "Pablo (dicen que está en la plaza del centro)" },
			},
			Actors = CADA_UNO },

		-- Reorganizar y trabajar
		{ Type = "Reach", Place = "Biblioteca", Text = "Reúne al grupo en la biblioteca: esta vez, los cinco", Actors = EQUIPO_TODO },
		{ Type = "Scene", Dialogue = "Reorganizar", Actors = EQUIPO_TODO },
		{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", Text = "Trabajad en el proyecto", Actors = EQUIPO_TODO },
		{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", Text = "Otra noche de proyecto… tú sola o solo", If = HACES_TODO,
			Effects = { Needs = { Energy = -25 } }, Actors = EQUIPO_TODO },
		{ Type = "MiniGame", Game = "Timing", Title = "Ensayo de la presentación", Icon = "🎤", Hint = "Pasa cada diapositiva a su tiempo",
			Rounds = 6, Need = 4, Zone = 0.25, Speed = 1,
			Win = { Flags = { "EnsayoBien" } }, Lose = { Traits = { Humor = 1 } }, Actors = EQUIPO_TODO },

		-- La presentación
		{ Type = "Transition", Text = "El día de la presentación…", Seconds = 3 },
		{ Type = "Reach", Place = "$Carrera.Facultad", Text = "Ve a la facultad: os toca presentar", Actors = PRESENTA },
		{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Examen", Place = "$Carrera.Facultad", Text = "La presentación (preguntas de Beltrán)",
			Bonus = { If = UNIDO, Seconds = 5 }, Actors = PRESENTA },
		{ Type = "Scene", Dialogue = "Resultado", Actors = PRESENTA },
	},

	Dialogues = {
		Encargo = { Lines = {
			{ S = "Beltran", T = "Proyecto en grupo. Cuenta la mitad de la nota. Los grupos los hago yo, que si no os juntáis siempre con los mismos." },
			{ S = "Beltran", T = "El tema: un caso clínico completo, del síntoma al tratamiento.", If = carrera("Medicina") },
			{ S = "Beltran", T = "El tema: diseñar un puente peatonal para el río de Valmar. Con cálculos, no con buenas intenciones.", If = carrera("Ingenieria") },
			{ S = "Beltran", T = "El tema: un juicio simulado. Un caso real de un vecino contra su ayuntamiento.", If = carrera("Derecho") },
			{ S = "Beltran", T = "El tema: un plan de empresa para un negocio de Valmar. Con números que cuadren.", If = carrera("Economia") },
			{ S = "Beltran", T = "Grupo cuatro: {nombre}, Julia, Pablo, Adrián y Carla." },
			{ S = "Adrian", T = "Perfecto. Yo coordino. Ya tengo un calendario." },
			{ S = "Julia", T = "Yo puedo hacer la introducción. Y el desarrollo. Y las conclusiones. Por si acaso." },
			{ S = "Beltran", T = "¿Pablo? ¿Alguien conoce a Pablo? …Lo que me temía." },
		} },
		Reunion = { Lines = {
			{ S = "Narrador", T = "Primera reunión. Adrián ha traído un calendario plastificado. Julia, tres carpetas. Pablo no ha venido." },
			{ S = "Adrian", T = "Esto se hace a mi manera o no se hace. No puedo sacar menos de un siete. No puedo." },
			{ S = "Julia", T = "No os preocupéis, si no llegáis, lo hago yo. Esta noche. Y mañana. Duermo poco, no pasa nada." },
			{ S = "Narrador", T = "Veinte minutos tarde, entra Carla corriendo, con la mochila abierta y la respiración entrecortada." },
			{ S = "Carla", T = "¡Perdón, perdón! No he podido antes. De verdad. …¿Qué me he perdido?" },
			{ S = "Narrador", T = "Tu móvil vibra. Un mensaje de Pablo: «voy luego 👍». No viene." },
		} },
		Gestion_Profesora = { Lines = {
			{ S = "Beltran", T = "¿Problemas en el grupo? Qué sorpresa. Cada año, en cada grupo." },
			{ S = "Beltran", T = "No voy a hacerlo por vosotros. Pero os voy a pedir un diario de grupo: quién hace qué, y cuándo. Lo leeré." },
			{ S = "Beltran", T = "Y un consejo: antes de decidir que alguien es un vago, pregúntale qué le pasa." },
		} },
		Gestion_Cambiar = { Lines = {
			{ S = "Beltran", T = "¿Cambiarte de grupo? No." },
			{ S = "Beltran", T = "En la vida no se eligen los compañeros de trabajo. Se aprende a trabajar con ellos. Piensa otra cosa." },
		} },

		Julia = { Lines = {
			{ S = "Julia", T = "Ya casi tengo la introducción. Y el índice. Y la bibliografía. Llevo dos noches sin dormir, pero está quedando bien." },
			{ S = "Julia", T = "Es que… si sale mal, es culpa mía. Siempre ha sido así. En el instituto siempre lo hacía yo todo." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«No tienes que cargar con todo. Confía un poco en los demás.»", Effects = { Flags = { "JuliaDelega" }, Rel = { Julia = 8 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Julia", T = "¿Y si no lo hacen bien? …Vale. Lo intento. Me quedo con la bibliografía. SOLO la bibliografía." },
				} },
				{ T = "«Genial, así acabamos antes.»", Effects = { Rel = { Julia = -2 } }, Then = {
					{ S = "Julia", T = "Sí… claro. Así acabamos antes. (Se le nota el cansancio en la cara.)" },
				} },
			} },
		} },
		Adrian = { Lines = {
			{ S = "Adrian", T = "¿Vienes a quejarte de que mando mucho? Todos lo hacen." },
			{ S = "Adrian", T = "Tengo una beca. Si bajo del siete, la pierdo. Y sin beca, no puedo estar aquí. Por eso lo quiero todo controlado." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Coordinar no es mandar: es escuchar y luego decidir. Te ayudamos.»", Effects = { Flags = { "AdrianEscucha" }, Rel = { Adrian = 8 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Adrian", T = "…Escuchar y luego decidir. Vale. Lo pruebo. Si sale mal, te echo la culpa. Es broma. Un poco." },
				} },
				{ T = "«Pues coordina tú solo, a ver qué tal.»", Effects = { Rel = { Adrian = -3 } }, Then = {
					{ S = "Adrian", T = "Muy bien. Ya lo hago yo. Como siempre." },
				} },
			} },
		} },
		Carla = { Lines = {
			{ S = "Narrador", T = "Carla está en el parque con un niño pequeño que se columpia. Te ve y se pone roja." },
			{ S = "Carla", T = "Es mi hermano. Mis padres trabajan por la tarde y yo lo recojo del colegio. Por eso llego tarde a todo." },
			{ S = "Carla", T = "No se lo he dicho a nadie. Me daba vergüenza que pensaran que pongo excusas." },
			{ Ask = "¿Qué le propones?", Options = {
				{ T = "«Hacemos las reuniones por la mañana, o por videollamada.»", Effects = { Flags = { "CarlaHorario" }, Rel = { Carla = 10 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Carla", T = "¿De verdad? Nadie me había propuesto cambiar nada por mí. Gracias. Por la mañana puedo con todo." },
				} },
				{ T = "«Tienes que organizarte mejor.»", Effects = { Rel = { Carla = -4 } }, Then = {
					{ S = "Carla", T = "Ya. Organizarme mejor. Claro." },
				} },
			} },
		} },
		Pablo = { Lines = {
			{ S = "Narrador", T = "En la plaza del centro, un chico toca la guitarra rodeado de gente. Toca muy bien. Es Pablo." },
			{ S = "Pablo", T = "¡Eh! ¿Eres del grupo? Perdona. No voy a clase casi nunca. Esa carrera la eligieron mis padres. Lo mío es esto." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«¿Y si haces la música y el vídeo de la presentación? Lo tuyo también sirve.»", Effects = { Flags = { "PabloMusica" }, Rel = { Pablo = 10 }, Traits = { Creatividad = 1 } }, Then = {
					{ S = "Pablo", T = "¿Una presentación con banda sonora? …Eso nunca lo ha hecho nadie. Vale. Cuenta conmigo. Esta vez, de verdad." },
				} },
				{ T = "«Aparece o se lo digo a Beltrán.»", Effects = { Rel = { Pablo = -4 }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Pablo", T = "Vale, vale. Iré. Pero no esperes mucho de mí." },
				} },
			} },
		} },

		Reorganizar = { Lines = {
			{ S = "Narrador", T = "Esta vez estáis los cinco. Pablo ha venido. Carla ha llegado la primera. Increíble.", If = { Flags = { "CarlaHorario" } } },
			{ S = "Narrador", T = "Esta vez estáis los cinco. Carla llega tarde otra vez. Pablo mira el móvil todo el rato.", If = { NotFlags = { "CarlaHorario" } } },
			{ Ask = "¿Cómo os organizáis?", Options = {
				{ T = "Cada uno en lo que se le da bien: Adrián coordina escuchando, Julia revisa, Carla por las mañanas, Pablo la música", If = { Flags = { "AdrianEscucha", "CarlaHorario", "PabloMusica" } },
					Effects = { Flags = { "EquipoUnido" }, Rel = { Julia = 4, Adrian = 4, Carla = 4, Pablo = 4 } }, Then = {
					{ S = "Adrian", T = "Voto a favor. Y lo digo sin calendario en la mano. Es un gran paso para mí." },
					{ S = "Pablo", T = "Ya tengo la canción de la intro. Se llama «Grupo cuatro». Es muy pegadiza." },
				} },
				{ T = "Repartir las partes a partes iguales y cada uno a lo suyo", Effects = { Choice = { Organizacion = "Partes" } }, Then = {
					{ S = "Julia", T = "Vale. Pero yo reviso lo de todos al final. No puedo evitarlo." },
				} },
				{ T = "Lo termino yo, que ya casi lo tengo", Effects = { Flags = { "HacesTodo" }, Rel = { Julia = -2, Adrian = -2 } }, Then = {
					{ S = "Narrador", T = "Nadie discute. A nadie le importa demasiado. A ti sí: te espera otra noche larga." },
				} },
			} },
		} },
		Resultado = { Lines = {
			{ S = "Narrador", T = "La presentación empieza con música de Pablo. Beltrán levanta una ceja. Al final, casi sonríe.", If = { Flags = { "PabloMusica" } } },
			{ S = "Beltran", T = "Buen trabajo, grupo cuatro. Se nota un equipo detrás. Eso no se puede fingir. Un sobresaliente.", If = { LastGradeAtLeast = 8, Flags = { "EquipoUnido" } } },
			{ S = "Beltran", T = "Buena nota. Aunque tengo la sensación de que aquí ha trabajado una persona más que las demás.", If = { LastGradeAtLeast = 6, Flags = { "HacesTodo" } } },
			{ S = "Beltran", T = "Aprobado. El trabajo cumple. El equipo… está en construcción.", If = { LastGradeBelow = 8, NotFlags = { "HacesTodo" } } },
			{ S = "Adrian", T = "¡Mantengo la beca! Gracias. En serio. A todos. Hasta a Pablo." },
			{ S = "Julia", T = "He dormido ocho horas esta semana. Seguidas. Es la primera vez desde el instituto.", If = { Flags = { "JuliaDelega" } } },
			{ S = "Narrador", T = "Estás agotado o agotada. Has sacado el proyecto adelante, pero casi a solas. La próxima vez, quizá, pedirás ayuda antes.", If = HACES_TODO },
			{ S = "Carla", T = "¿Una foto del grupo cuatro? Para el recuerdo. Pablo, deja la guitarra un segundo." },
		} },
	},
}
