-- INSTITUTO 06 · «LA GRAN DECISIÓN» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.29.
--
-- Último curso. Cada amigo tiene un plan (y alguno no lo tiene) → Carmen repasa contigo lo que te
-- interesó (las marcas Interes_* de «¿Qué quieres ser?») → jornada de puertas abiertas en la
-- universidad → estudiar para la selectividad → el examen (bonus si estudiaste) → la noche antes de
-- decidir, en casa → LA DECISIÓN: Medicina, Ingeniería, Derecho, Economía o trabajar → graduación del
-- instituto y la orla → paso a la vida adulta (universidad o trabajo). Sustituye a Adol_ElFuturo.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }
local CON_LEIRE = { Flags = { "ConocesALeire" } }

local function interes(flag: string): any
	return { Flags = { flag } }
end
local function estudios(value: string): any
	return { Choices = { Estudios = value } }
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

		-- La decisión
		{ Type = "Transition", Text = "La noche antes de entregar la solicitud…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Noche", Teleport = "HomeSalon", Actors = CASA },
		{ Type = "Choice", Key = "Estudios", PromptKey = "QUEST.FUTURO.PREGUNTA", Text = "Decide qué quieres hacer al terminar el instituto",
			Options = {
				{ Id = "Medicina", TextKey = "QUEST.FUTURO.OPT_MEDICINA", Flags = { "VaALaUniversidad" } },
				{ Id = "Ingenieria", TextKey = "QUEST.FUTURO.OPT_INGENIERIA", Flags = { "VaALaUniversidad" } },
				{ Id = "Derecho", TextKey = "QUEST.FUTURO.OPT_DERECHO", Flags = { "VaALaUniversidad" } },
				{ Id = "Economia", TextKey = "QUEST.FUTURO.OPT_ECONOMIA", Flags = { "VaALaUniversidad" } },
				{ Id = "Trabajar", TextKey = "QUEST.FUTURO.OPT_TRABAJAR", Flags = { "EmpiezaATrabajar" } },
			},
			Actors = CASA },
		{ Type = "Scene", Dialogue = "Decidido", Actors = CASA },

		-- Graduación del instituto
		{ Type = "Reach", Place = "PatioInstituto", Text = "Ve a la graduación del instituto", Actors = GRADUACION },
		{ Type = "Scene", Dialogue = "Graduacion", Actors = GRADUACION },
		{ Type = "Transition", SetStage = "AdultoJoven", TextKey = "TRANSITION.MAYOR_EDAD", Cinematic = "Adol_Selectividad" },
	},

	Dialogues = {
		Plan_Sara = { Lines = {
			{ S = "Sara", T = "Biología. Luego un doctorado. Luego descubrir una especie nueva de hongo y ponerle mi nombre. Lo tengo en una hoja de cálculo." },
			{ S = "Sara", T = "¿Y tú? No me digas «no sé». Bueno, si no lo sabes, dilo. Es un dato válido." },
		} },
		Plan_Omar = { Lines = {
			{ S = "Omar", T = "Cocina. FP de cocina. Lola me ha dicho que si termino, me coge. Voy a hacer la mejor tortilla de Valmar. Lola dice que eso es imposible." },
			{ S = "Omar", T = "Da un poco de miedo, ¿sabes? Que se acabe esto. Pero me llevo la pulsera.", If = { Memories = { "ElRumor" } } },
		} },
		Plan_Nico = { Lines = {
			{ S = "Nico", T = "Me han llamado de las pruebas del club de Altamar. Juvenil. Si no sale, estudio para ser entrenador. Como Andrés." },
			{ S = "Nico", T = "Oye… nunca te lo he dicho bien: gracias por lo de Omar. Por decírmelo a la cara, aparte.", If = { Choices = { HablasNico = "Privado" } } },
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
		} },
		Plan_Mateo = { Lines = {
			{ S = "Mateo", T = "Ingeniería. Mi padre es fontanero y siempre dice que hay que entender cómo funcionan las cosas. Pues quiero entenderlas todas." },
			{ S = "Mateo", T = "Nunca te lo he dicho, pero el primer día, cuando me ayudaste con los libros… todo empezó ahí." },
		} },
		Plan_Iker = { Lines = {
			{ S = "Iker", T = "Estadística. Obviamente. Según mis cálculos, hay un noventa y dos por ciento de probabilidades de que me encante." },
		} },

		Carmen = { Lines = {
			{ S = "Carmen", T = "Pasa, {nombre}. ¿Te acuerdas de la semana de las profesiones? Tengo tu cuaderno apuntado aquí." },
			{ S = "Carmen", T = "Te vi con la doctora Nuria. Dijiste que te veías en un hospital.", If = interes("Interes_Medicina") },
			{ S = "Carmen", T = "Sofía todavía habla de tu puente de palillos. Eso es ingeniería pura.", If = interes("Interes_Ingenieria") },
			{ S = "Carmen", T = "Inés dijo que escuchabas a las dos partes. Eso es derecho, o policía, o mediación.", If = interes("Interes_Derecho") },
			{ S = "Carmen", T = "Marcos pintó las bicis de azul por tu idea. Economía, empresa… lo llevas dentro.", If = interes("Interes_Economia") },
			{ S = "Carmen", T = "Tomás, Lola, Irene, Toni… hay profesiones que se aprenden trabajando. No son menos: son otro camino.", If = { Flags = { "Interes_Oficio" } } },
			{ S = "Carmen", T = "Y tu primer trabajo de verano. Eso también dice mucho de ti.", If = { Memories = { "PrimerSueldo" } } },
			{ S = "Carmen", T = "Sé lo del estadio y lo de Rayo. No te voy a sermonear. Solo te digo una cosa: todavía puedes elegir otro camino. Siempre se puede.", If = { Flags = { "Camino_Delincuente" } } },
			{ S = "Carmen", T = "Y sé que saliste de algo difícil hace unos años. Eso dice más de ti que cualquier nota.", If = { Flags = { "Redimido" } } },
			{ S = "Carmen", T = "Pero te voy a decir lo mismo que hace años: no tienes que acertar. Tienes que elegir. Y si te equivocas, se cambia." },
			{ S = "Carmen", T = "Nadie se queda donde empieza. Ni siquiera yo: empecé estudiando química. Mírame." },
		}, Effects = { Rel = { Carmen = 5 } } },
		PuertasAbiertas = { Lines = {
			{ S = "Sofia", T = "¡Anda! ¡La persona de los triángulos! Bienvenida, bienvenido a la jornada de puertas abiertas.", If = interes("Interes_Ingenieria") },
			{ S = "Sofia", T = "¡Bienvenidos a la jornada de puertas abiertas! Aquí están todas las facultades: Medicina, Ingeniería, Derecho, Economía.", If = { NotFlags = { "Interes_Ingenieria" } } },
			{ S = "Narrador", T = "El campus es enorme. Gente con carpetas, bicicletas, un chico durmiendo en el césped con un libro en la cara." },
			{ S = "Sara", T = "Aquí vamos a estar el año que viene. O no. Pero da igual: hoy da gusto." },
		} },
		Nervios = { Lines = {
			{ S = "Omar", T = "Me he aprendido todo. Y lo he olvidado todo en el pasillo. ¿Es normal?" },
			{ S = "Javier", T = "Es normal. Respirad. Nadie es su nota. Pero hoy, por si acaso, haced buena letra." },
		} },
		Noche = { Lines = {
			{ S = "Narrador", T = "Tu cuarto está lleno de cosas de todas las épocas: la foto del grupo, el diploma de primaria, la insignia del club…" },
			{ S = "Familia", T = "¿No puedes dormir? Yo tampoco dormía la noche antes de decidir. Ven, que hay leche con cacao." },
			{ S = "Abu", T = "Mira, cariño. A tu edad yo quería enseñar en una escuela, y en casa dijeron que no. Acabé en un taller de costura. Fui feliz. Pero me quedé con las ganas." },
			{ S = "Abu", T = "Haz lo que te haga feliz. Y si no sale, vuelve a intentarlo. Aquí vamos a estar." },
			{ S = "Familia", T = "Y con el dinero que ahorraste en aquel verano, algo te ayudará.", If = { Choices = { Meta = "Ahorro" } } },
			{ S = "Narrador", T = "Cuando tenías diez años, en un banco del parque, dijiste qué querías ser. Te acuerdas perfectamente." },
		} },
		Decidido = { Lines = {
			{ S = "Familia", T = "¡Medicina! Vas a salvar vidas. Y a no dormir. Pero sobre todo lo primero.", If = estudios("Medicina") },
			{ S = "Familia", T = "¡Ingeniería! Siempre desmontabas todo. Ahora, además, sabrás montarlo.", If = estudios("Ingenieria") },
			{ S = "Familia", T = "¡Derecho! Siempre fuiste de defender a los demás. Desde el colegio.", If = estudios("Derecho") },
			{ S = "Familia", T = "¡Economía! Me alegro. Así me ayudas con las cuentas de casa.", If = estudios("Economia") },
			{ S = "Familia", T = "¿Trabajar ya? Es una decisión valiente. Y si algún día quieres estudiar, siempre estás a tiempo.", If = estudios("Trabajar") },
			{ S = "Abu", T = "Sea lo que sea, lo has elegido tú. Eso es lo que importa." },
		} },
		Graduacion = { Lines = {
			{ S = "Javier", T = "Promoción de este año: cuando llegasteis, no sabíais ni dónde estaba el aula. Algunos esperasteis un ascensor que no existe." },
			{ S = "Javier", T = "Hoy os vais sabiendo algo más importante: quiénes sois. Más o menos. Que ya es mucho." },
			{ S = "Narrador", T = "Os hacéis la foto de la orla. Omar con los ojos cerrados. Nico saltando. Sara en su sitio exacto. Tú, en medio." },
			{ S = "Leire", T = "Esta foto la hago yo. Con la cámara de mi abuelo. Nada de móviles.", If = CON_LEIRE },
			{ S = "Familia", T = "¡{nombre}! ¡Mírame! ¡Una más! ¡La última! ¡Bueno, otra!" },
			{ S = "Narrador", T = "El instituto se acaba. Empieza todo lo demás." },
		} },
	},
}
