-- UNIVERSIDAD · LA VIDA EN EL CAMPUS (misiones principales del capítulo Joven_Universidad, entre las de siempre).
-- Ficha de diseño: docs/historia/14-universidad-real.md
--
--   Uni01b_Residencia  «La residencia»          tus compañeros de cuarto (Iván y Candela, de tu clase), las normas,
--                                               la primera compra en el súper, la nevera y tu primera cena
--   UniEx1_Enero       «Los exámenes de enero»  1.º, primer cuatrimestre: estudiar, examen teórico y prueba física
--   UniEx2_Junio       «Junio (y julio)»        fin de 1.º: examen final; si suspendes, recuperación en julio
--   UniEx3_Parcial     «El parcial imposible»   2.º y 3.º: el examen más difícil de la carrera y su prueba física
--   UniEx4_TFG         «El trabajo de fin de grado»  4.º: el TFG, la defensa ante el tribunal y la última prueba física
--
-- El ciclo es el de una universidad de verdad: clases (septiembre-enero), exámenes de enero, clases
-- (febrero-mayo), exámenes de junio, recuperación en julio, siguiente curso. Cada examen es de TU carrera
-- ("$Carrera.Asignatura1/2") y cada prueba física también ("$Carrera.Fisico": circuito a tiempo).

local V = Vector3.new

local CUARTO = {
	{ Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2) },
	{ Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2) },
}
local COCINA = {
	{ Npc = "Ivan", Place = "CocinaResidencia", Offset = V(-3, 0, 2) },
	{ Npc = "Candela", Place = "CocinaResidencia", Offset = V(3, 0, 2) },
}
local CLASE_EXAMEN = {
	{ Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) },
	{ Npc = "Candela", Place = "$Carrera.Facultad", Offset = V(-4, 0, 3) },
	{ Npc = "Ivan", Place = "$Carrera.Facultad", Offset = V(4, 0, 3) },
}
local ESTADIO = {
	{ Npc = "Ivan", Place = "EstadioUniversitario", Offset = V(-6, 0, 4), Mode = "Cheer" },
	{ Npc = "Candela", Place = "EstadioUniversitario", Offset = V(6, 0, 4), Mode = "Cheer" },
}

-- Resultado de un examen (se guarda como marca para poder mirar después otra nota, la de la prueba física)
local function resultado(prefijo: string, curso: string): { { [string]: any } }
	return {
		{ Type = "Transition", If = { LastGradeAtLeast = 5 }, Seconds = 4, Effects = { Flags = { prefijo .. "Aprobado" } },
			Text = "📋 Notas de " .. curso .. ": ¡APROBADO!" },
		{ Type = "Transition", If = { LastGradeBelow = 5 }, Seconds = 4, Effects = { Flags = { prefijo .. "Suspenso" } },
			Text = "📋 Notas de " .. curso .. ": suspenso. Toca recuperación." },
	}
end

local function flags(...): any
	return { Flags = { ... } }
end

return {
	---------------------------------------------------------------------
	-- La residencia
	---------------------------------------------------------------------
	{
		Id = "Uni01b_Residencia",
		Kind = "Main",
		Title = "La residencia",
		Description = "Una habitación para tres, una cocina para cuarenta y una nevera que ya no es la de tu casa. Empieza la independencia.",
		Chapter = "Joven_Universidad",
		AgeRange = { 18, 18 },
		Duration = { 25, 35 },
		Difficulty = 1,
		Type = "Historia · Independencia",
		Requires = { Completed = { "Uni01_PrimerDia" } },
		Npcs = { "Ivan", "Candela", "Portero" },
		Locations = { "Residencia", "HabitacionResidencia", "CocinaResidencia", "Supermercado" },
		Next = { "Uni02_ElProyecto" },
		Outcomes = { "Las normas del cuarto (y de la nevera)", "Qué cocinas la primera noche" },
		Moment = "Tu primera semana en la residencia",
		Memory = "Residencia",
		Rewards = { Items = { LlaveResidencia = 1 } },
		Props = {
			Nevera = { Kind = "Armario", Name = "La nevera compartida", Prompt = "Guardar la compra", Place = "CocinaResidencia", Offset = V(-4, 0, 0), Dialogue = "Nevera", Once = true },
			Cama = { Kind = "Almohada", Name = "Tu cama (la de la ventana)", Prompt = "Deshacer la maleta", Place = "HabitacionResidencia", Offset = V(0, 0, -2), Dialogue = "Maleta", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Portero", Dialogue = "Llaves", Text = "Doña Pilar, la conserje, te da las llaves",
				Actors = { { Npc = "Portero", Place = "Residencia", Offset = V(0, 0, 4) } } },
			{ Type = "Scene", Dialogue = "Compis", Teleport = "HabitacionResidencia", Actors = CUARTO },
			{ Type = "Use", Prop = "Cama", Text = "Deshaz la maleta", Actors = CUARTO },
			{ Type = "Choice", Key = "Normas", Text = "Iván propone normas del cuarto. ¿Qué norma de la nevera votas?",
				Options = {
					{ Id = "Etiquetas", Text = "Cada uno su balda, con etiquetas (Candela aplaude)", Effects = { Rel = { Candela = 6 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Compartida", Text = "Nevera compartida: todo es de todos (Iván aplaude)", Effects = { Rel = { Ivan = 6 }, Traits = { Empatia = 1 } } },
					{ Id = "Turnos", Text = "Compra por turnos: una semana cada uno", Effects = { Rel = { Ivan = 3, Candela = 3 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = CUARTO },
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Supermercado" }, Count = 2, Place = "Supermercado",
				Text = "Ve al supermercado y haz tu primera compra ({count}/{total} bolsas)",
				Nudge = { After = 200, Every = 150, S = "Candela", T = "(mensaje) Te recuerdo que los tápers de tu familia se acaban el domingo. Lo he calculado." } },
			{ Type = "Use", Prop = "Nevera", Text = "Guarda la compra en la nevera de la residencia", Actors = COCINA },
			{ Type = "Event", Event = "Ate", Text = "Tu primera cena de independiente: cómete algo (desde la mochila)", Actors = COCINA },
			{ Type = "Scene", Dialogue = "Cena", Actors = COCINA },
			{ Type = "Event", Event = "Slept", Text = "Duerme en tu cama de la residencia",
				Actors = { { Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2), Mode = "Sit" } } },
		},
		Dialogues = {
			Llaves = { Lines = {
				{ S = "Portero", T = "¿Primer año? Habitación 214. Tercer piso, al fondo, la de la puerta que chirría. Aquí tienes la llave." },
				{ S = "Portero", T = "Normas: nada de fuego en las habitaciones, nada de mascotas (hablo contigo, Iván, sé lo del gallo), y la cocina se deja limpia. Limpia de VERDAD." },
				{ S = "Portero", T = "Llevo cuarenta años aquí. He visto entrar a chavales que no sabían freír un huevo. Y salir… sin saber freír un huevo, la mayoría. Tú intenta ser la excepción." },
			} },
			Compis = { Lines = {
				{ S = "Ivan", T = "¡Hombre! ¡El o la de la cama de la ventana! Soy Iván. De Villaverde. Estamos en la misma clase, te vi en la matrícula." },
				{ S = "Candela", T = "Candela. También de tu clase. Os he hecho un horario de limpieza plastificado. Tenéis colores. El tuyo es el verde. No se negocia." },
				{ S = "Ivan", T = "Aviso importante: en la nevera hay tres botellas de zumo de mora. Casero. De mi abuela. Son sagradas. Podéis tocar todo menos eso. Todo. Menos. Eso." },
				{ S = "Candela", T = "Y mis tápers llevan etiqueta con fecha. Si falta uno, lo sabré. Siempre lo sé." },
				{ S = "Narrador", T = "Tienes la sensación de que este año va a ser muy largo. Y muy divertido." },
			} },
			Maleta = { Lines = {
				{ S = "Narrador", T = "Ropa, el reloj de {abu}, una foto del grupo de siempre… y siete tápers etiquetados por tu familia con la letra de siempre: «LUNES — COMER CALIENTE»." },
				{ S = "Narrador", T = "Pegas la foto encima de la cama. Ya parece un poco tu sitio." },
			} },
			Nevera = { Lines = {
				{ S = "Narrador", T = "La nevera compartida de la cuarta planta. Cuarenta estudiantes, una nevera. Hay un yogur de 2019 que ya tiene nombre propio." },
				{ S = "Narrador", T = "Guardas tu compra en la balda con tu etiqueta verde. Candela la ha hecho ella. Tiene un dibujito. Es un brócoli.", If = { Choices = { Normas = "Etiquetas" } } },
				{ S = "Narrador", T = "Guardas la compra donde cabe. Iván te choca la mano: «Ahora todo es de todos». Todo menos el zumo de mora. Eso lo dice con los ojos.", If = { Choices = { Normas = "Compartida" } } },
				{ S = "Narrador", T = "Esta semana te toca a ti la compra de los tres. Guardas todo y apuntas en la pizarra: «Semana 1: yo». Candela lo subraya.", If = { Choices = { Normas = "Turnos" } } },
				{ S = "Narrador", T = "Ahora comer depende de ti: si no compras, no hay. Si no cocinas, no hay. Si Iván tiene hambre, tampoco hay." },
			} },
			Cena = { Lines = {
				{ S = "Ivan", T = "¡Primera cena de independientes! Yo he hecho… cereales. Con zumo de mora. No me juzguéis." },
				{ S = "Candela", T = "Yo, arroz con verduras. Pesado en gramos. Hay para tres. …No me miréis así. Hay para tres." },
				{ Ask = "¿Qué aportas a la cena?", Options = {
					{ T = "La tortilla que te enseñó tu familia", Effects = { Rel = { Ivan = 4, Candela = 4 }, Flags = { "SabeCocinar" } }, Then = {
						{ S = "Ivan", T = "…¿Esto lo has hecho TÚ? Me caso con esta tortilla. Bueno, no. Pero casi." },
					} },
					{ T = "Tu último táper de casa, para compartir", Effects = { Rel = { Ivan = 3, Candela = 3 }, Traits = { Empatia = 1 } }, Then = {
						{ S = "Candela", T = "Sabe a casa. …Perdón. Me he emocionado con unas lentejas. Es el primer día." },
					} },
					{ T = "Pan con pan. Es lo que hay", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Ivan", T = "El famoso bocadillo de pan. Clásico de primero. El año que viene serás un chef. O no." },
					} },
				} },
				{ S = "Narrador", T = "Cenáis los tres en la cocina compartida, rodeados de estudiantes de todas partes. Alguien pone música. Alguien quema una sartén. Es perfecto." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Los exámenes de enero (1.º, primer cuatrimestre)
	---------------------------------------------------------------------
	{
		Id = "UniEx1_Enero",
		Kind = "Main",
		Title = "Los exámenes de enero",
		Description = "Primer cuatrimestre. La biblioteca abre 24 horas, la cafetería vende más café que nunca y Candela ha plastificado un calendario de exámenes.",
		Chapter = "Joven_Universidad",
		AgeRange = { 18, 18 },
		Duration = { 25, 35 },
		Difficulty = 2,
		Type = "Historia · Exámenes",
		Requires = { Completed = { "Uni02_ElProyecto" }, StageProgress = 0.18 },
		Npcs = { "Ivan", "Candela", "Beltran" },
		Locations = { "HabitacionResidencia", "Biblioteca", "$Carrera.Facultad", "EstadioUniversitario" },
		Next = { "Uni03_PrimerTrabajo" },
		Outcomes = { "Cómo estudias", "Examen teórico y prueba física", "Recuperación si suspendes" },
		Moment = "Tus primeros exámenes de universidad",
		Memory = "ExamenesEnero",
		Steps = {
			{ Type = "Transition", Text = "Enero. Época de exámenes.", Seconds = 3 },
			{ Type = "Scene", Dialogue = "Panico", Teleport = "HabitacionResidencia", Actors = CUARTO },
			{ Type = "Choice", Key = "MetodoEnero", Text = "¿Cómo vas a estudiar?",
				Options = {
					{ Id = "Candela", Text = "Con el horario plastificado de Candela", Effects = { Flags = { "EstudioEnero" }, Rel = { Candela = 4 } } },
					{ Id = "Biblioteca", Text = "A tu ritmo, en la biblioteca", Effects = { Flags = { "EstudioEnero" }, Traits = { Responsabilidad = 1 } } },
					{ Id = "UltimaNoche", Text = "La noche antes, con Iván y mucho café", Effects = { Rel = { Ivan = 4 }, Traits = { Humor = 1 } } },
				},
				Actors = CUARTO },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Estudio", Place = "Biblioteca", Text = "Estudia en la biblioteca", If = flags("EstudioEnero"),
				Actors = { { Npc = "Candela", Place = "Biblioteca", Offset = V(3, 0, 2), If = { Choices = { MetodoEnero = "Candela" } } } } },
			{ Type = "Scene", Dialogue = "Nochecita", If = { Choices = { MetodoEnero = "UltimaNoche" } }, Actors = CUARTO },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Examen", Place = "$Carrera.Facultad", Text = "Examen teórico de enero (tu carrera)",
				Bonus = { If = flags("EstudioEnero"), Seconds = 5 }, Actors = CLASE_EXAMEN },
			resultado("Enero", "enero")[1],
			resultado("Enero", "enero")[2],
			{ Type = "Scene", Dialogue = "Fisica", Actors = ESTADIO },
			{ Type = "Class", Subject = "$Carrera.Fisico", Mode = "Circuito", Place = "EstadioUniversitario", Text = "Prueba física de tu carrera (circuito a tiempo)", Actors = ESTADIO },
			-- Recuperación (febrero) si suspendiste la teoría
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Estudio", Place = "Biblioteca", Text = "Recuperación: vuelve a estudiar", If = flags("EneroSuspenso"),
				Actors = { { Npc = "Candela", Place = "Biblioteca", Offset = V(3, 0, 2) } } },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Examen", Place = "$Carrera.Facultad", Text = "Examen de recuperación", If = flags("EneroSuspenso"),
				Bonus = { Seconds = 5 }, Actors = CLASE_EXAMEN },
			{ Type = "Scene", Dialogue = "Fin", Actors = CUARTO, Teleport = "HabitacionResidencia" },
		},
		Dialogues = {
			Panico = { Lines = {
				{ S = "Candela", T = "Quedan nueve días, cuatro horas y doce minutos para el primer examen. Lo he calculado. Os he hecho un horario a cada uno." },
				{ S = "Ivan", T = "Yo tengo un método: mirar los apuntes muy fuerte la noche antes. Nunca ha funcionado. Pero tengo fe." },
				{ S = "Narrador", T = "En la universidad no hay deberes cada día. Nadie te persigue. Todo se juega en unas semanas. Y lo sabes." },
			} },
			Nochecita = { Lines = {
				{ S = "Ivan", T = "Son las tres de la mañana. Llevo cuatro cafés. Veo los apuntes en tres dimensiones. ¿Tú también ves a un señor con perilla en la página doce?" },
				{ S = "Narrador", T = "No. Nadie ve a nadie con perilla. …¿Verdad? Mejor irse a dormir un par de horas." },
			} },
			Fisica = { Lines = {
				{ S = "Narrador", T = "En tu carrera no solo cuentan los exámenes: el cuerpo también se evalúa. La prueba física es un circuito por el estadio, contra el reloj." },
				{ S = "Narrador", T = "Medicina: el circuito de urgencias, llevando camillas y material de un box a otro.", If = { Choices = { Estudios = "Medicina" } } },
				{ S = "Narrador", T = "Ingeniería: la visita de obra, con casco y planos, de un punto de inspección a otro.", If = { Choices = { Estudios = "Ingenieria" } } },
				{ S = "Narrador", T = "Derecho: la carrera de los juzgados, entregando escritos antes de que cierren las ventanillas.", If = { Choices = { Estudios = "Derecho" } } },
				{ S = "Narrador", T = "Economía: el cierre de la bolsa, llevando órdenes de compra antes de que suene la campana.", If = { Choices = { Estudios = "Economia" } } },
				{ S = "Ivan", T = "¡Vamos, que tú puedes! ¡Yo lo hice ayer y casi me desmayo, así que tú seguro que mejor!" },
			} },
			Fin = { Lines = {
				{ S = "Candela", T = "Aprobado. Te lo dije: el horario plastificado nunca falla.", If = { Flags = { "EneroAprobado" }, Choices = { MetodoEnero = "Candela" } } },
				{ S = "Ivan", T = "¡APROBADO! ¡Esto hay que celebrarlo! Con zumo de mora. …Con MI zumo de mora. Un vasito. Pequeño.", If = flags("EneroAprobado") },
				{ S = "Candela", T = "Suspender el primero le pasa a casi todo el mundo. Lo importante es que en la recuperación ya sabías cómo era.", If = flags("EneroSuspenso") },
				{ S = "Narrador", T = "El primer cuatrimestre se acaba. Empieza el segundo. Y la residencia, sin que te des cuenta, ya es tu casa." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Junio (y julio): fin de primer curso
	---------------------------------------------------------------------
	{
		Id = "UniEx2_Junio",
		Kind = "Main",
		Title = "Junio (y julio)",
		Description = "Fin de primer curso. El examen final de la asignatura más dura. Si sale mal, julio. Y en julio, el campus se queda vacío y hace un calor horrible.",
		Chapter = "Joven_Universidad",
		AgeRange = { 19, 19 },
		Duration = { 25, 35 },
		Difficulty = 2,
		Type = "Historia · Exámenes",
		Requires = { Completed = { "Uni03_PrimerTrabajo" }, StageProgress = 0.36 },
		Npcs = { "Ivan", "Candela", "Beltran" },
		Locations = { "Biblioteca", "$Carrera.Facultad", "EstadioUniversitario" },
		Next = { "Uni04_Practicas" },
		Outcomes = { "Estudiar en grupo o solo", "El final de junio", "Julio si suspendes" },
		Moment = "Aprobaste primero de carrera",
		Memory = "PrimerCurso",
		Rewards = { Money = 50 },
		Steps = {
			{ Type = "Transition", Text = "Junio. El calor, las persianas bajadas y los apuntes por el suelo.", Seconds = 3 },
			{ Type = "Scene", Dialogue = "GrupoEstudio", Teleport = "HabitacionResidencia", Actors = CUARTO },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", Text = "Grupo de estudio en la biblioteca",
				Effects = { Flags = { "EstudioJunio" } },
				Actors = {
					{ Npc = "Ivan", Place = "Biblioteca", Offset = V(-3, 0, 2), Mode = "Sit" },
					{ Npc = "Candela", Place = "Biblioteca", Offset = V(3, 0, 2) },
				} },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Examen", Place = "$Carrera.Facultad", Text = "Examen final de junio",
				Bonus = { If = flags("EstudioJunio"), Seconds = 5 }, Actors = CLASE_EXAMEN },
			resultado("Junio", "junio")[1],
			resultado("Junio", "junio")[2],
			{ Type = "Class", Subject = "$Carrera.Fisico", Mode = "Circuito", Place = "EstadioUniversitario", Text = "Prueba física de final de curso", Actors = ESTADIO },
			-- Julio: la convocatoria extraordinaria
			{ Type = "Transition", Text = "Julio. El campus vacío. Solo quedan los que tienen que recuperar… y los ventiladores.", Seconds = 4, If = flags("JunioSuspenso") },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", Text = "Estudia para julio", If = flags("JunioSuspenso") },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Examen", Place = "$Carrera.Facultad", Text = "Convocatoria de julio", If = flags("JunioSuspenso"),
				Bonus = { Seconds = 5 }, Actors = CLASE_EXAMEN },
			{ Type = "Scene", Dialogue = "Verano", Actors = CUARTO, Teleport = "HabitacionResidencia" },
		},
		Dialogues = {
			GrupoEstudio = { Lines = {
				{ S = "Candela", T = "Grupo de estudio. Reglas: móviles en la caja, descanso de cinco minutos cada cincuenta, y Iván no puede traer zumo de mora a la biblioteca." },
				{ S = "Ivan", T = "Protesto. …Denegado. Vale. Lo traeré en un termo. Nadie sabrá nada." },
			} },
			Verano = { Lines = {
				{ S = "Ivan", T = "¡PRIMERO DE CARRERA TERMINADO! ¡Soy oficialmente un estudiante de segundo! Casi un adulto. Casi." },
				{ S = "Candela", T = "Este verano vuelvo a casa. Pero el año que viene… ¿seguimos en la misma habitación? He hecho una lista de pros. No hay contras." },
				{ S = "Narrador", T = "Recoges la habitación para el verano. La foto del grupo de siempre ahora tiene al lado otra: los tres en la cocina, con una sartén quemada de fondo." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- El parcial imposible (2.º-3.º)
	---------------------------------------------------------------------
	{
		Id = "UniEx3_Parcial",
		Kind = "Main",
		Title = "El parcial imposible",
		Description = "Todos en la facultad hablan de él: el examen de la profesora Beltrán que nadie aprueba a la primera. Te toca.",
		Chapter = "Joven_Universidad",
		AgeRange = { 20, 20 },
		Duration = { 25, 35 },
		Difficulty = 3,
		Type = "Historia · Exámenes",
		Requires = { Completed = { "Uni04_Practicas" }, StageProgress = 0.54 },
		Npcs = { "Beltran", "Ivan", "Candela" },
		Locations = { "$Carrera.Facultad", "Biblioteca", "EstadioUniversitario" },
		Next = { "Uni05_PrimerPiso" },
		Outcomes = { "La tutoría con Beltrán", "El parcial", "La prueba física más dura" },
		Moment = "Aprobaste el parcial imposible",
		Memory = "ParcialImposible",
		Steps = {
			{ Type = "Transition", Text = "Tercer curso. El parcial imposible.", Seconds = 3 },
			{ Type = "Talk", Npc = "Beltran", Dialogue = "Tutoria", Text = "Ve a la tutoría de la profesora Beltrán",
				Actors = { { Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) } } },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Estudio", Place = "Biblioteca", Text = "Estudia lo que Beltrán te ha dicho que mires", Effects = { Flags = { "EstudioParcial" } } },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Estudio", Place = "HabitacionResidencia", Text = "Repaso final en la residencia (Iván hace de profe)",
				Actors = { { Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2) } } },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Examen", Place = "$Carrera.Facultad", Text = "El parcial imposible",
				Bonus = { If = flags("TutoriaBeltran"), Seconds = 5 }, Actors = CLASE_EXAMEN },
			resultado("Parcial", "el parcial")[1],
			resultado("Parcial", "el parcial")[2],
			{ Type = "Class", Subject = "$Carrera.Fisico", Mode = "Circuito", Place = "EstadioUniversitario", Text = "La prueba física de tercero (la más dura)", Actors = ESTADIO },
			{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Examen", Place = "$Carrera.Facultad", Text = "Segunda oportunidad del parcial", If = flags("ParcialSuspenso"),
				Bonus = { Seconds = 5 }, Actors = CLASE_EXAMEN },
			{ Type = "Scene", Dialogue = "Nota", Actors = { { Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) } } },
		},
		Dialogues = {
			Tutoria = { Lines = {
				{ S = "Beltran", T = "Vienes a la tutoría antes del parcial. Eso solo lo hace uno de cada diez. Los otros nueve vienen después, a llorar." },
				{ S = "Beltran", T = "Te diré un secreto: mi examen no es imposible. Solo pregunta lo que de verdad hay que saber para ejercer. Lo que no se puede copiar." },
				{ Ask = "¿Qué le preguntas?", Options = {
					{ T = "«¿Qué es lo que más falla la gente?»", Effects = { Flags = { "TutoriaBeltran" }, Rel = { Beltran = 5 } }, Then = {
						{ S = "Beltran", T = "Estudian para aprobar, no para entender. Entiende el tema cuatro y el resto sale solo. No se lo digas a nadie." },
					} },
					{ T = "«¿Por qué es usted tan dura?»", Effects = { Flags = { "TutoriaBeltran" }, Traits = { Valentia = 1 } }, Then = {
						{ S = "Beltran", T = "Porque dentro de unos años alguien va a confiar en ti. Un paciente, un cliente, un puente. Prefiero ser dura yo ahora que la vida después." },
					} },
				} },
			} },
			Nota = { Lines = {
				{ S = "Beltran", T = "Has aprobado mi parcial. En treinta años lo he dicho pocas veces con esta cara. Enhorabuena.", If = flags("ParcialAprobado") },
				{ S = "Beltran", T = "No aprobaste a la primera. Casi nadie lo hace. Pero volviste, y en la segunda lo entendiste. Eso es lo que quería ver.", If = flags("ParcialSuspenso") },
				{ S = "Narrador", T = "En el pasillo, alguien ha escrito en el tablón: «Superviviente del parcial de Beltrán». Añades tu nombre debajo de otros cuarenta." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- El trabajo de fin de grado (4.º)
	---------------------------------------------------------------------
	{
		Id = "UniEx4_TFG",
		Kind = "Main",
		Title = "El trabajo de fin de grado",
		Description = "Cuarto curso. Lo último que te separa del título: tu TFG, defenderlo delante de un tribunal y la prueba física final de tu carrera.",
		Chapter = "Joven_Universidad",
		AgeRange = { 21, 21 },
		Duration = { 30, 40 },
		Difficulty = 3,
		Type = "Historia · Exámenes",
		Requires = { Completed = { "Uni05_PrimerPiso" }, StageProgress = 0.72 },
		Npcs = { "Beltran", "Ivan", "Candela" },
		Locations = { "Biblioteca", "$Carrera.Facultad", "EstadioUniversitario" },
		Next = { "Uni06_Graduacion" },
		Outcomes = { "El tema del TFG", "La defensa ante el tribunal", "La última prueba física" },
		Moment = "Defendiste tu trabajo de fin de grado",
		Memory = "TFG",
		Rewards = { Items = { TFG = 1 } },
		Steps = {
			{ Type = "Transition", Text = "Cuarto curso. El último.", Seconds = 3 },
			{ Type = "Choice", Key = "TemaTFG", Text = "¿Sobre qué haces tu trabajo de fin de grado?",
				Options = {
					{ Id = "Practicas", Text = "Sobre el caso de tus prácticas", Effects = { Traits = { Responsabilidad = 1 } } },
					{ Id = "Valmar", Text = "Sobre algo de Valmar (tu ciudad)", Effects = { Traits = { Curiosidad = 1 } } },
					{ Id = "Raro", Text = "Sobre «fenómenos inexplicables en Los Pinos» (a Beltrán le va a dar algo)", Effects = { Traits = { Humor = 1 }, Flags = { "TFGRaro" } } },
				} },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", Text = "Escribe tu TFG (biblioteca)" },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", Text = "Corrige tu TFG (otra vez; siempre hay otra vez)",
				Actors = { { Npc = "Candela", Place = "Biblioteca", Offset = V(3, 0, 2) } } },
			{ Type = "Scene", Dialogue = "Ensayo",
				Actors = { { Npc = "Ivan", Place = "Biblioteca", Offset = V(-3, 0, 3) }, { Npc = "Candela", Place = "Biblioteca", Offset = V(3, 0, 3) } } },
			{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Examen", Place = "$Carrera.Facultad", Text = "La defensa del TFG ante el tribunal",
				Bonus = { Seconds = 4 }, Actors = CLASE_EXAMEN },
			{ Type = "Class", Subject = "$Carrera.Fisico", Mode = "Circuito", Place = "EstadioUniversitario", Text = "La última prueba física de la carrera", Actors = ESTADIO },
			{ Type = "Scene", Dialogue = "Tribunal", Actors = CLASE_EXAMEN },
		},
		Dialogues = {
			Ensayo = { Lines = {
				{ S = "Ivan", T = "Yo hago de tribunal malvado. «Señor o señora estudiante: ¿y eso para qué sirve?» …¿Qué tal? Llevo cuatro años ensayando esa cara." },
				{ S = "Candela", T = "Yo cronometro. Tienes quince minutos. Si te pasas, suena mi alarma. Es una sirena de barco. Me la regalaron." },
				{ S = "Narrador", T = "Ensayas cinco veces. A la quinta, Iván aplaude y Candela no toca la sirena. Es un buen presagio." },
			} },
			Tribunal = { Lines = {
				{ S = "Beltran", T = "El tribunal ha deliberado. Trabajo sólido, defensa clara, y ha respondido bien a la pregunta trampa. Aprobado." },
				{ S = "Beltran", T = "«Fenómenos inexplicables en Los Pinos». Nunca había leído un TFG con un capítulo sobre una gallina gigante. Tiene bibliografía. Muy seria. …Aprobado.", If = flags("TFGRaro") },
				{ S = "Ivan", T = "(desde el público) ¡ESO ES! ¡ESE O ESA ES MI COMPAÑERO O COMPAÑERA DE CUARTO!" },
				{ S = "Narrador", T = "Recibes 📘 tu Trabajo de Fin de Grado, encuadernado. Solo falta la graduación." },
			} },
		},
	},
}
