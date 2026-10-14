-- UNIVERSIDAD 06 · «LA GRADUACIÓN» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.36.
--
-- Último repaso y examen final → la nota → prepararte (qué te pones; tu familia y {abu} vienen) → la
-- facultad llena: despedirte del grupo cuatro, de Luca, de Beltrán → la ceremonia y el diploma →
-- cinemática → la foto → la celebración en la Cafetería Central con todos los de siempre: un brindis
-- donde cada uno recuerda algo que VIVISTE (desde el primer día de colegio) → «Has terminado tu etapa
-- universitaria». Da el título de tu carrera (con tu nota media) y la marca Graduado.
--
-- El final de capítulo son tres escenas escritas a mano (Happenings/Universidad.luau): la ceremonia
-- (Uni06_Ceremonia: subes tú a por el diploma), el brindis (Uni06_Brindis: cada recuerdo depende de lo
-- que viviste) y el cierre (Uni06_Final: la cafetería se vacía, {abu} y el reloj, tu casa de noche).

local V = Vector3.new

local CON_LEIRE = { Flags = { "ConocesALeire" } }
local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }

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
	-- Leire hace la foto (la de la cámara de su abuelo); llega andando desde la entrada del campus
	{ Npc = "Leire", Place = "$Carrera.Facultad", Offset = V(-8, 0, 8), If = CON_LEIRE, Enter = "Universidad" },
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
	-- Los de la universidad: tus compañeros de cuarto y el grupo cuatro
	{ Npc = "Ivan", Place = "CafeteriaCentral", Offset = V(-2, 0, 7) },
	{ Npc = "Candela", Place = "CafeteriaCentral", Offset = V(-4, 0, 6) },
	{ Npc = "Julia", Place = "CafeteriaCentral", Offset = V(4, 0, 7) },
	{ Npc = "Adrian", Place = "CafeteriaCentral", Offset = V(6, 0, 6) },
	{ Npc = "Carla", Place = "CafeteriaCentral", Offset = V(7, 0, 3) },
}
-- El cierre: los demás se van andando (el paso ya no los necesita); se quedan {abu}, tu familia, Lola
-- y Omar recogiendo
local CIERRE = {
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 6) },
	{ Npc = "Omar", Place = "CafeteriaCentral", Offset = V(3, 0, 3) },
	{ Npc = "Familia", Place = "CafeteriaCentral", Offset = V(-8, 0, -2) },
	{ Npc = "Abu", Place = "CafeteriaCentral", Offset = V(-9, 0, 1), Mode = "Sit" },
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
	Requires = { Completed = { "UniEx4_TFG" }, StageProgress = 0.9 },
	Npcs = { "Beltran", "Julia", "Adrian", "Carla", "Pablo", "Luca", "Familia", "Abu", "Mateo", "Lola", "Omar", "Sara", "Nico", "Leire", "Hugo", "Bruno", "Ivan", "Candela" },
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
		{ Type = "Cinematic", Id = "Uni06_Ceremonia", Actors = CEREMONIA },
		{ Type = "Cinematic", Id = "Uni_Graduacion", Actors = CEREMONIA },
		{ Type = "Scene", Dialogue = "Foto", Actors = CEREMONIA },

		-- La celebración
		{ Type = "Reach", Place = "CafeteriaCentral", Text = "Celebración en la Cafetería Central: Lola ha cerrado para vosotros", Actors = FIESTA },
		{ Type = "Cinematic", Id = "Uni06_Brindis", Actors = FIESTA },
		{ Type = "Cinematic", Id = "Uni06_Final", Actors = CIERRE },
	},

	Dialogues = {
		Nota = { Lines = {
			{ S = "Beltran", T = "Último examen corregido. Enhorabuena: con esto, terminas la carrera. Con buena nota, además.", If = { LastGradeAtLeast = 7 } },
			{ S = "Beltran", T = "Último examen corregido. Aprobado. Lo importante es que terminas. Y que sabes más que cuando llegaste.", If = { LastGradeBelow = 7 } },
			{ S = "Beltran", T = "Treinta años viendo entrar y salir gente. Algunos se me olvidan. Tú no. Y no pienso decir por qué." },
		} },
		Preparacion = { Lines = {
			{ S = "Familia", T = "¡Toga y birrete! A ver, date la vuelta. …Estás guapísim{o/a}. Perdón, es que me emociono." },
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
		Foto = { Lines = {
			{ S = "Narrador", T = "Birretes al aire. Todos a la vez. El grupo cuatro, Luca, tu familia.", Shot = "General" },
			{ S = "Leire", T = "¡Quietos! Esta la hago yo, con la cámara de mi abuelo. Nada de móviles. Como en la orla del instituto.", If = CON_LEIRE, Shot = "Medio:Leire" },
			{ S = "Familia", T = "¿Salgo bien? No, espera. Ahora. ¡Ahora sí!", Shot = "Medio:Familia", Beat = "Sonrie" },
			{ S = "Narrador", T = "Clic. Una foto que vas a enseñar muchas veces. Probablemente más de las necesarias.", Pause = 0.6 },
		} },
	},
}
