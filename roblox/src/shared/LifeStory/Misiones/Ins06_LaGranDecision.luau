-- INSTITUTO 06 · «LA GRAN DECISIÓN» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.29.
--
-- Último curso. Cada amigo tiene un plan (y alguno no lo tiene) → Carmen repasa contigo lo que te
-- interesó (las marcas Interes_* de «¿Qué quieres ser?») → jornada de puertas abiertas en la
-- universidad → estudiar para la selectividad → el examen (bonus si estudiaste) → la noche antes de
-- decidir, en casa → LA DECISIÓN: universidad o trabajar (la nota de selectividad marca a qué carreras
-- puedes entrar; la carrera se elige el primer día en la universidad; si suspendes, julio) → graduación del
-- instituto y la orla → paso a la vida adulta (universidad o trabajo). Sustituye a Adol_ElFuturo.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }
local CON_LEIRE = { Flags = { "ConocesALeire" } }

local function interes(flag: string): any
	return { Flags = { flag } }
end

local PATIO = {
	{ Npc = "Sara", Place = "PatioInstituto", Offset = V(-4, 0, 2) },
	{ Npc = "Nico", Place = "PatioInstituto", Offset = V(10, 0, -3) },
	{ Npc = "Omar", Place = "PatioInstituto", Offset = V(0, 0, 4) },
	{ Npc = "Leire", Place = "PatioInstituto", Offset = V(5, 0, 2), If = CON_LEIRE },
	{ Npc = "Bruno", Place = "PatioInstituto", Offset = V(-10, 0, 6) },
	{ Npc = "Hugo", Place = "PatioInstituto", Offset = V(-6, 0, -3), If = CON_HUGO },
	{ Npc = "Mateo", Place = "PatioInstituto", Offset = V(3, 0, -4), If = AMIGO_MATEO },
	{ Npc = "Iker", Place = "PatioInstituto", Offset = V(7, 0, 6), If = CON_IKER },
}
local CASA = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2), Mode = "Sit" },
}
-- La noche: Abu ya está en su sillón; tu familia baja un poco después desde la cocina, andando
-- (Happenings/Instituto · Ins06_Noche)
local NOCHE = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0), Enter = { From = "HomeCocina", Delay = 14 } },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2), Mode = "Sit" },
}
local GRADUACION = {
	{ Npc = "Javier", Place = "PatioInstituto", Offset = V(0, 0, 10) },
	{ Npc = "Carmen", Place = "PatioInstituto", Offset = V(4, 0, 10) },
	{ Npc = "Familia", Place = "PatioInstituto", Offset = V(-10, 0, 6), Mode = "Wave" },
	{ Npc = "Abu", Place = "PatioInstituto", Offset = V(-12, 0, 8) },
}
for _, actor in PATIO do
	table.insert(GRADUACION, actor)
end

return {
	Id = "Ins06_LaGranDecision",
	Kind = "Main",
	Title = "La gran decisión",
	Description = "Último curso. Selectividad, planes, dudas… y una pregunta que nadie puede contestar por ti: ¿y ahora qué?",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 17, 18 },
	Duration = { 25, 35 },
	Difficulty = 3,
	Type = "Historia · Final de capítulo",
	Requires = { Completed = { "Ins05_ElRumor" }, StageProgress = 0.9 },
	Npcs = { "Sara", "Nico", "Omar", "Leire", "Bruno", "Hugo", "Mateo", "Iker", "Carmen", "Sofia", "Familia", "Abu", "Javier" },
	Locations = { "PatioInstituto", "AulaInstituto", "Universidad", "Biblioteca", "HomeSalon" },
	Next = { "Uni01_PrimerDia" },
	Outcomes = { "Medicina, Ingeniería, Derecho, Economía o trabajar", "Lo que te dice cada amigo", "La nota de selectividad" },

	Moment = "Decidiste tu futuro",
	MomentSting = false,
	Memory = "LaGranDecision",
	Rewards = { Items = { OrlaInstituto = 1 } },

	Steps = {
		{ Type = "Transition", Text = "Dos años después. El último curso.", Seconds = 3 },
		{ Type = "Reach", Place = "PatioInstituto", Text = "Sal al patio: tus amigos hablan del futuro", Actors = PATIO },
		{ Type = "Group", Text = "Pregunta a tus amigos qué van a hacer (al menos tres)", Need = 3,
			Steps = {
				{ Type = "Talk", Npc = "Sara", Dialogue = "Plan_Sara", Text = "Sara" },
				{ Type = "Talk", Npc = "Omar", Dialogue = "Plan_Omar", Text = "Omar" },
				{ Type = "Talk", Npc = "Nico", Dialogue = "Plan_Nico", Text = "Nico" },
				{ Type = "Talk", Npc = "Bruno", Dialogue = "Plan_Bruno", Text = "Bruno" },
				{ Type = "Talk", Npc = "Leire", Dialogue = "Plan_Leire", Text = "Leire", If = CON_LEIRE },
				{ Type = "Talk", Npc = "Hugo", Dialogue = "Plan_Hugo", Text = "Hugo", If = CON_HUGO },
				{ Type = "Talk", Npc = "Mateo", Dialogue = "Plan_Mateo", Text = "Mateo", If = AMIGO_MATEO },
				{ Type = "Talk", Npc = "Iker", Dialogue = "Plan_Iker", Text = "Iker", If = CON_IKER },
			},
			Actors = PATIO },

		-- Orientación y puertas abiertas
		{ Type = "Reach", Place = "AulaInstituto", Text = "Carmen te espera en su despacho (aula)",
			Actors = { { Npc = "Carmen", Place = "AulaInstituto", Offset = V(0, 0, -6) } } },
		{ Type = "Talk", Npc = "Carmen", Dialogue = "Carmen", Text = "Habla con Carmen",
			Actors = { { Npc = "Carmen", Place = "AulaInstituto", Offset = V(0, 0, -6) } } },
		{ Type = "Reach", Place = "Universidad", Text = "Jornada de puertas abiertas: visita la universidad",
			Actors = { { Npc = "Sofia", Place = "Universidad", Offset = V(0, 0, 5) }, { Npc = "Sara", Mode = "Follow" } } },
		{ Type = "Scene", Dialogue = "PuertasAbiertas", Actors = { { Npc = "Sofia", Place = "Universidad", Offset = V(0, 0, 5) }, { Npc = "Sara", Mode = "Follow" } } },

		-- Selectividad
		{ Type = "Class", Subject = "Tecnologia", Mode = "Estudio", Place = "Biblioteca", Text = "Estudia para la selectividad en la biblioteca del campus",
			Effects = { Flags = { "EstudiasteSelectividad" } }, Actors = { { Npc = "Sara", Place = "Biblioteca", Offset = V(3, 0, 2) } } },
		{ Type = "Scene", Dialogue = "Nervios", Actors = { { Npc = "Omar", Place = "AulaInstituto", Offset = V(3, 0, 0) }, { Npc = "Javier", Place = "AulaInstituto", Offset = V(0, 0, -6) } } },
		{ Type = "Class", Subject = "Tecnologia", Mode = "Examen", Place = "AulaInstituto", Text = "El examen de selectividad",
			Bonus = { If = { Flags = { "EstudiasteSelectividad" } }, Seconds = 5 },
			Actors = { { Npc = "Javier", Place = "AulaInstituto", Offset = V(0, 0, -6) } } },

		-- La nota de selectividad decide a qué carreras puedes entrar (notas de corte de la Universidad de Valmar)
		{ Type = "Transition", If = { LastGradeAtLeast = 8 }, Seconds = 5, Effects = { Flags = { "Acceso5", "Acceso6", "Acceso7", "Acceso8" } },
			Text = "📬 Nota de selectividad: ¡SOBRESALIENTE! Puedes entrar en cualquier carrera (Medicina pide un 8)." },
		{ Type = "Transition", If = { LastGradeAtLeast = 7, LastGradeBelow = 8 }, Seconds = 5, Effects = { Flags = { "Acceso5", "Acceso6", "Acceso7" } },
			Text = "📬 Nota de selectividad: notable alto. Ingeniería (7), Derecho (6) y Economía (5). Medicina pide un 8." },
		{ Type = "Transition", If = { LastGradeAtLeast = 6, LastGradeBelow = 7 }, Seconds = 5, Effects = { Flags = { "Acceso5", "Acceso6" } },
			Text = "📬 Nota de selectividad: bien. Puedes entrar en Derecho (6) y Economía (5)." },
		{ Type = "Transition", If = { LastGradeAtLeast = 5, LastGradeBelow = 6 }, Seconds = 5, Effects = { Flags = { "Acceso5" } },
			Text = "📬 Nota de selectividad: aprobado justo. Puedes entrar en Economía (5)." },
		{ Type = "Transition", If = { LastGradeBelow = 5 }, Seconds = 5, Effects = { Flags = { "SuspendeSelectividad" } },
			Text = "📬 Nota de selectividad: suspenso. Pero hay convocatoria extraordinaria en julio. Todavía no está todo perdido." },
		-- Convocatoria de julio (solo si suspendiste)
		{ Type = "Class", Subject = "Tecnologia", Mode = "Estudio", Place = "Biblioteca", Text = "Julio: estudia para la convocatoria extraordinaria",
			If = { Flags = { "SuspendeSelectividad" }, NotFlags = { "Acceso5" } } },
		{ Type = "Class", Subject = "Tecnologia", Mode = "Examen", Place = "AulaInstituto", Text = "La selectividad de julio (segunda oportunidad)",
			If = { Flags = { "SuspendeSelectividad" }, NotFlags = { "Acceso5" } }, Bonus = { Seconds = 5 } },
		{ Type = "Transition", If = { Flags = { "SuspendeSelectividad" }, NotFlags = { "Acceso5" }, LastGradeAtLeast = 6 }, Seconds = 5, Effects = { Flags = { "Acceso5", "Acceso6" } },
			Text = "📬 Julio: ¡aprobado con un bien! Derecho (6) y Economía (5) te esperan." },
		{ Type = "Transition", If = { Flags = { "SuspendeSelectividad" }, NotFlags = { "Acceso5" }, LastGradeAtLeast = 5, LastGradeBelow = 6 }, Seconds = 5, Effects = { Flags = { "Acceso5" } },
			Text = "📬 Julio: ¡aprobado! Puedes entrar en Economía (5)." },
		{ Type = "Transition", If = { Flags = { "SuspendeSelectividad" }, NotFlags = { "Acceso5" }, LastGradeBelow = 5 }, Seconds = 5,
			Text = "📬 Julio: otra vez suspenso. Este año no podrás ir a la universidad… pero puedes trabajar. Y volver a intentarlo más adelante." },

		-- La decisión
		{ Type = "Transition", Text = "La noche antes de entregar la solicitud…", Seconds = 3 },
		{ Type = "Cinematic", Id = "Ins06_Noche", Teleport = "HomeSalon", Actors = NOCHE },
		-- La carrera se elige el primer día, en la secretaría de la universidad (Uni01). Aquí: ¿universidad o trabajar?
		{ Type = "Choice", Key = "Futuro", PromptKey = "QUEST.FUTURO.PREGUNTA", Text = "Decide qué quieres hacer al terminar el instituto",
			Options = {
				{ Id = "Universidad", Text = "Ir a la universidad (vivirás en la residencia del campus; la carrera se elige allí)", Flags = { "VaALaUniversidad" }, If = { Flags = { "Acceso5" } } },
				{ Id = "Trabajar", TextKey = "QUEST.FUTURO.OPT_TRABAJAR", Flags = { "EmpiezaATrabajar" }, Effects = { Choice = { Estudios = "Trabajar" } } },
			},
			Actors = CASA },
		{ Type = "Scene", Dialogue = "Decidido", Actors = CASA },

		-- Graduación del instituto
		{ Type = "Reach", Place = "PatioInstituto", Text = "Ve a la graduación del instituto", Actors = GRADUACION },
		{ Type = "Cinematic", Id = "Ins06_Graduacion", Actors = GRADUACION },
		{ Type = "Transition", SetStage = "AdultoJoven", TextKey = "TRANSITION.MAYOR_EDAD", Cinematic = "Adol_Selectividad" },
	},

	Dialogues = {
		Plan_Sara = { Lines = {
			{ S = "Sara", T = "Biología. Luego un doctorado. Luego descubrir una especie nueva de hongo y ponerle mi nombre. Lo tengo en una hoja de cálculo." },
			{ S = "Sara", T = "¿Te acuerdas del primer día? Me había aprendido el plano entero y aun así me perdí. Ahora me pierdo menos.", If = { Memories = { "PrimerDiaInstituto" } } },
			{ S = "Sara", T = "¿Y tú? No me digas «no sé». Bueno, si no lo sabes, dilo. Es un dato válido.", Pause = 0.6, Beat = "Mira", To = "Yo" },
		} },
		Plan_Omar = { Lines = {
			{ S = "Omar", T = "Cocina. FP de cocina. Lola me ha dicho que si termino, me coge. Voy a hacer la mejor tortilla de Valmar. Lola dice que eso es imposible." },
			{ S = "Omar", T = "Da un poco de miedo, ¿sabes? Que se acabe esto. Pero me llevo la pulsera.", If = { Memories = { "ElRumor" } } },
		} },
		Plan_Nico = { Lines = {
			{ S = "Nico", T = "Me han llamado de las pruebas del club de Altamar. Juvenil. Si no sale, estudio para ser entrenador. Como Andrés." },
			{ S = "Nico", T = "Y aquel sábado viniste a mi cumple en vez de ir al club. Eso tampoco se me olvida.", If = { Choices = { Sabado = "Cumple" } } },
			{ S = "Nico", T = "Oye… nunca te lo he dicho bien: gracias por lo de Omar. Por decírmelo a la cara, aparte.", Pause = 0.8, Beat = "Baja", If = { Choices = { HablasNico = "Privado" } } },
			{ S = "Nico", T = "Y aquel día en el estadio, cuando soltaste la bolsa de camisetas… Ese día supe que seguías siendo tú.", Pause = 0.6, Beat = "Mira", To = "Yo", If = { Memories = { "ElCruce" }, Choices = { Camino = "Negocio" }, Flags = { "Redimido" } } },
		} },
		Plan_Bruno = { Lines = {
			{ S = "Bruno", T = "¿Yo? Policía. No te rías. Inés, la de la comisaría, dice que se me da bien que la gente me haga caso." },
			{ S = "Bruno", T = "Y que ahora sé cuándo hay que usarlo y cuándo no. Eso lo aprendí con vosotros. No se lo digas a nadie." },
			{ S = "Bruno", T = "Me creíste cuando todos decían que la foto era mía. Eso no se me olvida.", If = { Choices = { Bruno = "Confiar" } } },
			{ S = "Bruno", T = "También por gente como Rayo. Y como tú, últimamente. No te lo tomes a mal. Quiero ser el policía que te habría gustado encontrarte.", If = { Flags = { "Camino_Delincuente" } } },
		} },
		Plan_Leire = { Lines = {
			{ S = "Leire", T = "Comunicación audiovisual. En otra ciudad, probablemente. Mi tío dice que tengo que irme para volver con otra mirada." },
			{ S = "Leire", T = "Cuando llegué, pensé que aquí no tendría a nadie. Ahora me cuesta irme. Qué rabia." },
		} },
		Plan_Hugo = { Lines = {
			{ S = "Hugo", T = "Periodismo. O escribir novelas. O las dos cosas. Mi primera novela será de piratas. La segunda, también." },
			{ S = "Hugo", T = "Mi primer reportaje de verdad fue el de los murales de Vega. Contigo. Lo tengo enmarcado.", If = { Choices = { Reportaje = "Permiso" } } },
			{ S = "Hugo", T = "«El artista misterioso». Todavía nadie sabe que era Vega. Eso también es periodismo: saber callar.", If = { Choices = { Reportaje = "Anonimo" } } },
			{ S = "Hugo", T = "Lo de publicar el nombre de Vega… Tenías razón en que era verdad. Pero aprendí que la verdad también duele.", If = { Choices = { Reportaje = "Nombre" } } },
		} },
		Plan_Mateo = { Lines = {
			{ S = "Mateo", T = "Ingeniería. Mi padre es fontanero y siempre dice que hay que entender cómo funcionan las cosas. Pues quiero entenderlas todas." },
			{ S = "Mateo", T = "Nunca te lo he dicho, pero el primer día, cuando me ayudaste con los libros… todo empezó ahí." },
		} },
		Plan_Iker = { Lines = {
			{ S = "Iker", T = "Estadística. Obviamente. Según mis cálculos, hay un noventa y dos por ciento de probabilidades de que me encante." },
		} },

		Carmen = { Lines = {
			{ S = "Carmen", T = "Pasa, {nombre}. ¿Te acuerdas de la semana de las profesiones? Tengo tu cuaderno apuntado aquí.", If = { Memories = { "QueQuieresSer" } } },
			{ S = "Carmen", T = "Pasa, {nombre}. Último curso. Vamos a ver qué te ronda la cabeza.", If = { NotMemories = { "QueQuieresSer" } } },
			{ S = "Carmen", T = "En primero saliste de mi clase con más dudas que antes. ¿Te acuerdas? Te dije que era buena señal.", Pause = 0.6, If = { Choices = { Orientacion = "Dudas" } } },
			{ S = "Carmen", T = "Te vi con la doctora Nuria. Dijiste que te veías en un hospital.", If = interes("Interes_Medicina") },
			{ S = "Carmen", T = "Sofía todavía habla de tu puente de palillos. Eso es ingeniería pura.", If = interes("Interes_Ingenieria") },
			{ S = "Carmen", T = "Inés dijo que escuchabas a las dos partes. Eso es derecho, o policía, o mediación.", If = interes("Interes_Derecho") },
			{ S = "Carmen", T = "Marcos pintó las bicis de azul por tu idea. Economía, empresa… lo llevas dentro.", If = interes("Interes_Economia") },
			{ S = "Carmen", T = "Tobías, Lola, Irene, Toni… hay profesiones que se aprenden trabajando. No son menos: son otro camino.", If = { Flags = { "Interes_Oficio" } } },
			{ S = "Carmen", T = "Y tu primer trabajo de verano. Eso también dice mucho de ti.", If = { Memories = { "PrimerSueldo" } } },
			{ S = "Carmen", T = "Sé lo del estadio y lo de Rayo. No te voy a sermonear. Solo te digo una cosa: todavía puedes elegir otro camino. Siempre se puede.", If = { Flags = { "Camino_Delincuente" } } },
			{ S = "Carmen", T = "Y sé que saliste de algo difícil hace unos años. Eso dice más de ti que cualquier nota.", If = { Flags = { "Redimido" } } },
			{ S = "Carmen", T = "Pero te voy a decir lo mismo que hace años: no tienes que acertar. Tienes que elegir.", Pause = 0.8, Beat = "Mira", To = "Yo", Shot = "PrimerPlano:Carmen" },
			{ S = "Carmen", T = "Y si te equivocas, se cambia.", Pause = 0.8 },
			{ S = "Carmen", T = "Nadie se queda donde empieza. Ni siquiera yo: empecé estudiando química. Mírame." },
		}, Effects = { Rel = { Carmen = 5 } } },
		PuertasAbiertas = { Lines = {
			{ S = "Sofia", T = "¡Anda! ¡La persona de los triángulos! Bienvenid{o/a} a la jornada de puertas abiertas.", If = interes("Interes_Ingenieria") },
			{ S = "Sofia", T = "¡Bienvenidos a la jornada de puertas abiertas! Aquí están todas las facultades: Medicina, Ingeniería, Derecho, Economía.", If = { NotFlags = { "Interes_Ingenieria" } } },
			{ S = "Narrador", T = "El campus es enorme. Gente con carpetas, bicicletas, un chico durmiendo en el césped con un libro en la cara." },
			{ S = "Sara", T = "Aquí vamos a estar el año que viene. O no. Pero da igual: hoy da gusto." },
		} },
		Nervios = { Lines = {
			{ S = "Omar", T = "Me he aprendido todo. Y lo he olvidado todo en el pasillo. ¿Es normal?" },
			{ S = "Javier", T = "Es normal. Respirad. Nadie es su nota. Pero hoy, por si acaso, haced buena letra." },
		} },
		Decidido = { Lines = {
			{ S = "Familia", T = "¡A la universidad! Y a vivir en la residencia del campus… Te voy a echar de menos. Y a tu ropa sucia, no tanto.", A = "Happy", Shot = "Medio:Familia", If = { Choices = { Futuro = "Universidad" } } },
			{ S = "Familia", T = "Allí tendrás que hacerte la compra, la comida, la cama… Todo. Mañana te enseño a hacer una tortilla. Por si acaso. Por si acaso, dos.", If = { Choices = { Futuro = "Universidad" } } },
			{ S = "Familia", T = "Con tu nota puedes elegir cualquier carrera. ¡Cualquiera! Piénsalo bien antes de matricularte.", If = { Choices = { Futuro = "Universidad" }, Flags = { "Acceso8" } } },
			{ S = "Familia", T = "¿Trabajar ya?", Pause = 0.8, Beat = "Respira", A = "Surprised", Shot = "PrimerPlano:Familia", If = { Choices = { Futuro = "Trabajar" } } },
			{ S = "Familia", T = "Es una decisión valiente. Y si algún día quieres estudiar, siempre estás a tiempo.", Pause = 0.6, If = { Choices = { Futuro = "Trabajar" } } },
			{ S = "Familia", T = "Y quien te contrató aquel verano siempre dice que eres de fiar. Algo de eso habrá.", A = "Happy", If = { Flags = { "EmpiezaATrabajar", "BuenTrabajo" } } },
			{ S = "Abu", T = "Sea lo que sea, lo has elegido tú. Eso es lo que importa.", Pause = 1, Beat = "Mira", To = "Yo", Shot = "PrimerPlano:Abu" },
		} },
	},
}
