-- UNIVERSIDAD 06 · «LA GRADUACIÓN» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.36.
--
-- Último repaso y examen final → la nota → prepararte (qué te pones; tu familia y {abu} vienen) → la
-- facultad llena: despedirte del grupo cuatro, de Luca, de Beltrán → la ceremonia y el diploma →
-- cinemática → la foto → la celebración en la Cafetería Central con todos los de siempre: un brindis
-- donde cada uno recuerda algo que VIVISTE (desde el primer día de colegio) → «Has terminado tu etapa
-- universitaria». Da el título de tu carrera (con tu nota media) y la marca Graduado.

local V = Vector3.new

local CON_LEIRE = { Flags = { "ConocesALeire" } }
local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local function m(id: string): any
	return { Memories = { id } }
end
local function recuerdo(speaker: string, text: string, cond: any?): any
	return { S = speaker, T = text, If = cond }
end

local GRUPO = {
	{ Npc = "Julia", Place = "$Carrera.Facultad", Offset = V(-6, 0, 4) },
	{ Npc = "Adrian", Place = "$Carrera.Facultad", Offset = V(-3, 0, 5) },
	{ Npc = "Carla", Place = "$Carrera.Facultad", Offset = V(3, 0, 5) },
	{ Npc = "Pablo", Place = "$Carrera.Facultad", Offset = V(6, 0, 4) },
}
local CEREMONIA = {
	{ Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 10) },
	{ Npc = "Luca", Place = "$Carrera.Facultad", Offset = V(8, 0, 2) },
	{ Npc = "Familia", Place = "$Carrera.Facultad", Offset = V(-10, 0, 0), Mode = "Wave" },
	{ Npc = "Abu", Place = "$Carrera.Facultad", Offset = V(-12, 0, 2) },
	{ Npc = "Mateo", Place = "$Carrera.Facultad", Offset = V(10, 0, 6), If = { Flags = { "AyudasteAMateo" }, Choices = { Estudios = "Ingenieria" } } },
}
for _, actor in GRUPO do
	table.insert(CEREMONIA, actor)
end
local FIESTA = {
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 6) },
	{ Npc = "Omar", Place = "CafeteriaCentral", Offset = V(3, 0, 3) },
	{ Npc = "Sara", Place = "CafeteriaCentral", Offset = V(-3, 0, 3) },
	{ Npc = "Nico", Place = "CafeteriaCentral", Offset = V(5, 0, 0) },
	{ Npc = "Leire", Place = "CafeteriaCentral", Offset = V(-5, 0, 0), If = CON_LEIRE },
	{ Npc = "Mateo", Place = "CafeteriaCentral", Offset = V(-6, 0, 4), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "CafeteriaCentral", Offset = V(6, 0, 4), If = { Flags = { "HugoConElGrupo" } } },
	{ Npc = "Bruno", Place = "CafeteriaCentral", Offset = V(8, 0, -2) },
	{ Npc = "Familia", Place = "CafeteriaCentral", Offset = V(-8, 0, -2) },
	{ Npc = "Abu", Place = "CafeteriaCentral", Offset = V(-9, 0, 1), Mode = "Sit" },
	{ Npc = "Luca", Place = "CafeteriaCentral", Offset = V(2, 0, -4) },
}

return {
	Id = "Uni06_Graduacion",
	Kind = "Main",
	Title = "La graduación",
	Description = "Toga, birrete, tu nombre por el altavoz y todos los que importan en la sala. Terminas la universidad.",
	Chapter = "Joven_Universidad",
	AgeRange = { 22, 22 },
	Duration = { 25, 35 },
	Difficulty = 2,
	Type = "Historia · Final de capítulo",
	Requires = { Completed = { "Uni05_PrimerPiso" }, StageProgress = 0.93 },
	Npcs = { "Beltran", "Julia", "Adrian", "Carla", "Pablo", "Luca", "Familia", "Abu", "Mateo", "Lola", "Omar", "Sara", "Nico", "Leire", "Hugo", "Bruno" },
	Locations = { "Biblioteca", "$Carrera.Facultad", "CercaDeTi", "CafeteriaCentral" },
	Next = { "Adu01_PrimerContrato" },
	Outcomes = { "Tu nota media", "Qué te pones", "El brindis: los recuerdos de toda tu vida" },

	Moment = "Te graduaste",
	MomentSting = false,
	Memory = "Graduacion",
	Rewards = { Money = 500, Degree = "$Carrera.Titulo", Flags = { "Graduado" }, Items = { OrlaUniversidad = 1 } },

	Steps = {
		{ Type = "Transition", Text = "Junio del último curso.", Seconds = 3 },
		{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Estudio", Place = "Biblioteca", Text = "Último repaso en la biblioteca",
			Actors = { { Npc = "Julia", Place = "Biblioteca", Offset = V(-3, 0, 2) }, { Npc = "Adrian", Place = "Biblioteca", Offset = V(3, 0, 2) } } },
		{ Type = "Class", Subject = "$Carrera.Asignatura2", Mode = "Examen", Place = "$Carrera.Facultad", Text = "El último examen de la carrera",
			Actors = { { Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) } } },
		{ Type = "Scene", Dialogue = "Nota", Actors = { { Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) } } },

		-- Prepararse
		{ Type = "Transition", Text = "El día de la graduación…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Preparacion",
			Actors = { { Npc = "Familia", Place = "CercaDeTi", Offset = V(-3, 0, -4) }, { Npc = "Abu", Place = "CercaDeTi", Offset = V(3, 0, -4) } } },
		{ Type = "Reach", Place = "$Carrera.Facultad", Text = "Ve a tu facultad: la ceremonia empieza pronto", Actors = CEREMONIA },
		{ Type = "Group", Text = "Saluda antes de la ceremonia (al menos tres)", Need = 3,
			Steps = {
				{ Type = "Talk", Npc = "Julia", Dialogue = "Adios_Julia", Text = "Julia" },
				{ Type = "Talk", Npc = "Adrian", Dialogue = "Adios_Adrian", Text = "Adrián" },
				{ Type = "Talk", Npc = "Carla", Dialogue = "Adios_Carla", Text = "Carla" },
				{ Type = "Talk", Npc = "Pablo", Dialogue = "Adios_Pablo", Text = "Pablo" },
				{ Type = "Talk", Npc = "Luca", Dialogue = "Adios_Luca", Text = "Luca" },
			},
			Actors = CEREMONIA },
		{ Type = "Scene", Dialogue = "Ceremonia", Actors = CEREMONIA },
		{ Type = "Cinematic", Id = "Uni_Graduacion", Actors = CEREMONIA },
		{ Type = "Scene", Dialogue = "Foto", Actors = CEREMONIA },

		-- La celebración
		{ Type = "Reach", Place = "CafeteriaCentral", Text = "Celebración en la Cafetería Central: Lola ha cerrado para vosotros", Actors = FIESTA },
		{ Type = "Scene", Dialogue = "Brindis", Actors = FIESTA },
		{ Type = "Scene", Dialogue = "Final", Actors = FIESTA },
	},

	Dialogues = {
		Nota = { Lines = {
			{ S = "Beltran", T = "Último examen corregido. Enhorabuena: con esto, terminas la carrera. Con buena nota, además.", If = { LastGradeAtLeast = 7 } },
			{ S = "Beltran", T = "Último examen corregido. Aprobado. Lo importante es que terminas. Y que sabes más que cuando llegaste.", If = { LastGradeBelow = 7 } },
			{ S = "Beltran", T = "Treinta años viendo entrar y salir gente. Algunos se me olvidan. Tú no. Y no pienso decir por qué." },
		} },
		Preparacion = { Lines = {
			{ S = "Familia", T = "¡Toga y birrete! A ver, date la vuelta. …Estás guapísimo o guapísima. Perdón, es que me emociono." },
			{ Ask = "¿Qué llevas debajo de la toga?", Options = {
				{ T = "Tu mejor ropa: hoy es un día importante", Effects = { Choice = { LookGraduacion = "Elegante" } }, Then = {
					{ S = "Familia", T = "Impecable. Como para una foto que vas a enseñar el resto de tu vida." },
				} },
				{ T = "La sudadera de dinosaurios (si cabe)", Effects = { Choice = { LookGraduacion = "Dinosaurios" }, Traits = { Humor = 1 } }, Then = {
					{ S = "Familia", T = "¿La de los seis años? ¡No te puede caber! …Te cabe. Por los pelos. Esto es historia." },
				} },
				{ T = "Algo sencillo, que lo importante es el día", Effects = { Choice = { LookGraduacion = "Sencillo" } }, Then = {
					{ S = "Abu", T = "Bien dicho. La ropa no se acuerda de nada. Las personas, sí." },
				} },
			} },
			{ S = "Abu", T = "¿Llevas el reloj? …Lo llevas. Entonces vámonos, que no quiero llegar tarde a lo más importante de este año." },
		} },
		Adios_Julia = { Lines = { { S = "Julia", T = "¿Sabes qué? Ya no lo hago todo yo. Bueno, casi todo. Pero ahora duermo. Gracias por aquel proyecto." } } },
		Adios_Adrian = { Lines = { { S = "Adrian", T = "Mantuve la beca los cuatro años. Y aprendí a coordinar sin gritar. Casi. Si alguna vez necesitas un jefe que escuche, llámame." } } },
		Adios_Carla = { Lines = { { S = "Carla", T = "Mi hermano ha venido a verme. Dice que de mayor quiere ser «como la gente del grupo cuatro». No sé qué le hemos hecho." } } },
		Adios_Pablo = { Lines = {
			{ S = "Pablo", T = "Me gradúo. Y en septiembre, conservatorio. Doble vida: de día, lo que querían mis padres; de noche, lo que quiero yo.", If = { Flags = { "PabloMusica" } } },
			{ S = "Pablo", T = "Me gradúo, ¿te lo puedes creer? Yo tampoco. Ni mis padres. Sobre todo mis padres.", If = { NotFlags = { "PabloMusica" } } },
		} },
		Adios_Luca = { Lines = {
			{ S = "Luca", T = "Vine un año de Erasmus y me he quedado cinco. Es culpa de Valmar. Y de las croquetas. Y un poco tuya." },
			{ S = "Luca", T = "Y después de vivir juntos, sé todos tus secretos. Como que nunca friegas los domingos.", If = { Choices = { CompiPiso = "Luca" } } },
		} },
		Ceremonia = { Lines = {
			{ S = "Beltran", T = "Autoridades, familias, graduados. Me han pedido que diga unas palabras. Seré breve. Es mentira. Pero lo intentaré." },
			{ S = "Beltran", T = "Hoy no os lleváis solo un título. Os lleváis los errores que confesasteis, los grupos que sobrevivisteis y lo que aprendisteis de gente distinta a vosotros." },
			{ S = "Beltran", T = "Y el siguiente nombre: {nombre}." },
			{ S = "Narrador", T = "Subes. Te tiemblan las piernas. Beltrán te da el diploma y, muy bajito, te dice: «Sabía que llegarías»." },
			{ S = "Beltran", T = "(bajito) Y la empresa de tus prácticas ya me ha preguntado por ti. Tienes trabajo esperando.", If = { Flags = { "OfertaTrabajo" } } },
			{ S = "Familia", T = "(desde la grada, muy fuerte) ¡BRAVO, {nombre}! ¡ES DE MI FAMILIA! ¡DE MI FAMILIA!" },
		} },
		Foto = { Lines = {
			{ S = "Narrador", T = "Birretes al aire. Todos a la vez. El grupo cuatro, Luca, tu familia." },
			{ S = "Leire", T = "¡Quietos! Esta la hago yo, con la cámara de mi abuelo. Nada de móviles. Como en la orla del instituto.", If = CON_LEIRE },
			{ S = "Narrador", T = "Clic. Una foto que vas a enseñar muchas veces. Probablemente más de las necesarias." },
		} },
		Brindis = { Lines = {
			{ S = "Lola", T = "¡Cerrado por graduación! Hoy invita la casa. Bueno, invita Omar. La casa supervisa." },
			{ S = "Omar", T = "Propongo un brindis. Pero no uno cualquiera: cada uno tiene que decir algo de lo que se acuerde de {nombre}. Empiezo yo." },
			recuerdo("Omar", "Me acuerdo del primer día de colegio. Tú no me conocías y ya me estabas guardando la mitad de todo. Bueno, eso era yo contigo.", m("PrimerDiaCole")),
			recuerdo("Mateo", "Yo me acuerdo de mis libros por el suelo del pasillo. Y de alguien que se agachó a ayudarme. Todo empezó ahí.", m("PrimerAmigo")),
			recuerdo("Sara", "Yo me acuerdo de la mochila desaparecida. Fue nuestra primera investigación. Técnicamente, la primera de muchas.", m("MochilaPerdida")),
			recuerdo("Nico", "¡La final del torneo! Medalla de oro. Todavía la tengo colgada en mi cuarto. Bueno, la tuya no, la mía.", { Flags = { "TorneoGanado" } }),
			recuerdo("Nico", "La final del torneo. Plata. Y aun así fue el mejor día de mi vida. No se lo digáis a mi entrenador actual.", { Flags = { "TorneoPerdido" } }),
			recuerdo("Sara", "Y la sala cerrada. La foto de Lucía con coletas. Todavía me escribe por Navidad.", m("MisterioColegio")),
			recuerdo("Omar", "El festival. Las magdalenas. El concurso de talentos. La purpurina de Vega, que sigo encontrando en mi ropa.", m("ElFestival")),
			recuerdo("Familia", "Yo me acuerdo de aquel examen que casi suspendiste. Y de cómo lo arreglaste tú solo o sola, sin que nadie te obligara.", m("CasiSuspendo")),
			recuerdo("Leire", "Yo me acuerdo de un banco del instituto. Yo comía sola y apareció alguien. Nunca se lo agradecí bien. Gracias.", { Flags = { "ConocesALeire" } }),
			recuerdo("Omar", "Y la foto aquella del instituto. Tú plantaste cara. Yo nunca lo olvido. Por eso llevo todavía la pulsera.", m("ElRumor")),
			recuerdo("Bruno", "Yo… me acuerdo de que empezamos de cero. Y de que salió bien. Ahora soy policía. ¿Quién lo iba a decir?", { Choices = { AdiosBruno = "DeCero" } }),
			recuerdo("Bruno", "Yo me acuerdo de que éramos rivales. Ahora ya no me acuerdo de por qué. Enhorabuena, de verdad.", { NotChoices = { AdiosBruno = "DeCero" } }),
			recuerdo("Lola", "Yo me acuerdo de un chaval o chavala tirando una bandeja entera en su primer día. Mírate ahora.", m("PrimerSueldo")),
			recuerdo("Abu", "Y yo me acuerdo del día que naciste. Eras así de pequeño o pequeña. Y mírate. Con reloj y todo." ),
			{ S = "Omar", T = "¡Por {nombre}! ¡Y por todos los que vamos a seguir acordándonos!" },
			{ S = "Narrador", T = "Todos levantan el vaso. Omar llora. Dice que es por la cebolla de las croquetas. No hay cebolla." },
		} },
		Final = { Lines = {
			{ S = "Narrador", T = "Esa noche, en tu casa, dejas el diploma encima de la mesa. Al lado, el reloj de {abu}. Y la foto de hoy." },
			{ S = "Narrador", T = "Te acuerdas de cómo empezó tu vida: una mochila más grande que tú, un pasillo lleno de gente, alguien que te sonrió." },
			{ S = "Narrador", T = "Has terminado tu etapa universitaria. Empieza la vida profesional." },
		} },
	},
}
