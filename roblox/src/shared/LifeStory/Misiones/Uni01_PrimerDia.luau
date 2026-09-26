-- UNIVERSIDAD 01 · «PRIMER DÍA EN EL CAMPUS» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.31.
--
-- La despedida en casa ({abu} te da su reloj) → el bus al Campus → un campus enorme: Luca, voluntario
-- de Erasmus → recoger el horario en secretaría → encontrar TU facultad ("$Carrera.Facultad") →
-- conocer a la profesora Beltrán y a tus compañeros → la primera clase → descubrir el campus (2 de 3:
-- biblioteca, cafetería, deportes) → con quién comes → por la noche, el grupo de siempre por mensajes.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_LEIRE = { Flags = { "ConocesALeire" } }
local function carrera(value: string): any
	return { Choices = { Estudios = value } }
end

local CASA = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2), Mode = "Sit" },
}
local ENTRADA = {
	{ Npc = "Luca", Place = "Universidad", Offset = V(3, 0, 5), Mode = "Wave" },
	{ Npc = "Sara", Place = "Universidad", Offset = V(-6, 0, 8) },
	{ Npc = "Alumno1", Place = "Universidad", Offset = V(10, 0, 12), Mode = "Wander", Radius = 12 },
	{ Npc = "Alumno2", Place = "Universidad", Offset = V(-10, 0, 14), Mode = "Wander", Radius = 12 },
	{ Npc = "Alumno3", Place = "Universidad", Offset = V(0, 0, 16), Mode = "Wander", Radius = 12 },
}
local FACULTAD = {
	{ Npc = "Beltran", Place = "$Carrera.Facultad", Offset = V(0, 0, 6) },
	{ Npc = "Julia", Place = "$Carrera.Facultad", Offset = V(-4, 0, 3) },
	{ Npc = "Adrian", Place = "$Carrera.Facultad", Offset = V(4, 0, 3) },
	{ Npc = "Carla", Place = "$Carrera.Facultad", Offset = V(-6, 0, -1) },
	{ Npc = "Mateo", Place = "$Carrera.Facultad", Offset = V(6, 0, -1), If = { Flags = { "AyudasteAMateo" }, Choices = { Estudios = "Ingenieria" } } },
}
local CAMPUS = {
	{ Npc = "Luca", Mode = "Follow" },
	{ Npc = "Sara", Place = "Biblioteca", Offset = V(3, 0, 3) },
	{ Npc = "Julia", Place = "Universidad", Offset = V(-12, 0, 4), Mode = "Chat" },
	{ Npc = "Adrian", Place = "Universidad", Offset = V(-14, 0, 6), Mode = "Chat" },
}

return {
	Id = "Uni01_PrimerDia",
	Kind = "Main",
	Title = "Primer día en el campus",
	Description = "Septiembre. Un campus enorme, una facultad que es solo tuya y gente de todas partes. Empieza la universidad.",
	Chapter = "Joven_Universidad",
	AgeRange = { 18, 18 },
	Duration = { 20, 30 },
	Difficulty = 1,
	Type = "Historia · Nueva etapa",
	Npcs = { "Familia", "Abu", "Luca", "Sara", "Beltran", "Julia", "Adrian", "Carla", "Mateo", "Omar", "Nico", "Leire", "Hugo" },
	Locations = { "HomeSalon", "ParadaBus", "Universidad", "$Carrera.Facultad", "Biblioteca", "EstadioUniversitario" },
	Next = { "Uni02_ElProyecto" },
	Outcomes = { "Con quién comes el primer día", "Qué descubres del campus" },

	Moment = "Tu primer día de universidad",
	Memory = "PrimerDiaUni",
	Rewards = { Items = { CarnetUniversitario = 1, RelojAbu = 1 } },

	Props = {
		Secretaria = { Kind = "Marcador", Name = "Secretaría de alumnos", Prompt = "Recoger el horario", Place = "Universidad", Offset = V(-4, 0, 3), Dialogue = "Secretaria", Once = true },
		CarnetBiblio = { Kind = "Libro", Name = "Mostrador de la biblioteca", Prompt = "Hacerte el carnet", Place = "Biblioteca", Dialogue = "Biblioteca", Once = true },
		Cafeteria = { Kind = "Kiosco", Name = "Cafetería del campus", Prompt = "Pedir algo", Place = "Universidad", Offset = V(-12, 0, 2), Color = Color3.fromRGB(150, 90, 50), Dialogue = "Cafeteria", Once = true },
		Deportes = { Kind = "Marcador", Name = "Oficina de deportes", Prompt = "Mirar actividades", Place = "EstadioUniversitario", Dialogue = "Deportes", Once = true },
		MesaSola = { Kind = "Asiento", Name = "Una mesa libre", Prompt = "Comer a tu aire", Place = "Universidad", Offset = V(-8, 0, -2) },
	},

	Steps = {
		{ Type = "Transition", Text = "Septiembre. Tienes dieciocho años.", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Despedida", Teleport = "HomeSalon", Actors = CASA },
		{ Type = "Event", Event = "Traveled", Match = { Town = "Campus Valmar" }, Place = "ParadaBus", Text = "Coge el autobús al Campus Valmar" },
		{ Type = "Reach", Place = "Universidad", Text = "Llega a la entrada principal de la universidad", Actors = ENTRADA },
		{ Type = "Scene", Dialogue = "Campus", Actors = ENTRADA },
		{ Type = "Use", Prop = "Secretaria", Text = "Recoge tu horario en secretaría", Actors = ENTRADA },

		-- Tu facultad
		{ Type = "Reach", Place = "$Carrera.Facultad", Text = "Encuentra tu facultad (sale en el horario)", Actors = FACULTAD,
			Nudge = { After = 150, Every = 120, S = "Luca", T = "(mensaje) ¿Perdido? Todos los edificios son iguales el primer día. Busca el cartel con el nombre de tu facultad." } },
		{ Type = "Scene", Dialogue = "Beltran", Actors = FACULTAD },
		{ Type = "Class", Subject = "$Carrera.Asignatura1", Mode = "Clase", Place = "$Carrera.Facultad", Text = "Tu primera clase de universidad", Actors = FACULTAD },

		-- El campus
		{ Type = "Group", Text = "Descubre el campus (al menos dos sitios)", Need = 2,
			Steps = {
				{ Type = "Use", Prop = "CarnetBiblio", Text = "La biblioteca" },
				{ Type = "Use", Prop = "Cafeteria", Text = "La cafetería" },
				{ Type = "Use", Prop = "Deportes", Text = "La zona deportiva (estadio)" },
			},
			Actors = CAMPUS },
		{ Type = "Choice", Key = "ComidaUni", Text = "Hora de comer. ¿Con quién? (habla con quien elijas o busca una mesa libre)",
			Options = {
				{ Id = "Luca", Npc = "Luca", Text = "Con Luca", Dialogue = "Come_Luca", Effects = { Rel = { Luca = 8 } } },
				{ Id = "Sara", Npc = "Sara", Text = "Con Sara, como siempre", Dialogue = "Come_Sara", Effects = { Rel = { Sara = 5 } } },
				{ Id = "Clase", Npc = "Julia", Text = "Con la gente de tu clase", Dialogue = "Come_Clase", Effects = { Rel = { Julia = 5, Adrian = 5 } } },
				{ Id = "Sola", Prop = "MesaSola", Text = "A tu aire", Dialogue = "Come_Sola", Effects = { Traits = { Curiosidad = 1 } } },
			},
			Actors = {
				{ Npc = "Luca", Place = "Universidad", Offset = V(-10, 0, -4) },
				{ Npc = "Sara", Place = "Universidad", Offset = V(-6, 0, -6) },
				{ Npc = "Julia", Place = "Universidad", Offset = V(-12, 0, 4), Mode = "Chat" },
				{ Npc = "Adrian", Place = "Universidad", Offset = V(-14, 0, 6), Mode = "Chat" },
			} },

		-- Por la noche
		{ Type = "Transition", Text = "Esa noche…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Mensajes", Teleport = "HomeSalon", Actors = CASA },
	},

	Dialogues = {
		Despedida = { Lines = {
			{ S = "Familia", T = "¿Llevas todo? ¿El carnet? ¿Agua? ¿El cargador? Perdona. Es la costumbre." },
			{ S = "Familia", T = "¡Universidad! ¡{nombre} en la universidad! Me acuerdo de cuando no llegabas al pomo de la puerta." },
			{ S = "Abu", T = "Ven aquí. Toma. Era mío. Lo llevé el día que empecé a trabajar. Ahora te toca a ti." },
			{ S = "Narrador", T = "{abu} te da un reloj viejo, con la correa gastada. Todavía funciona. Hace tic-tac muy bajito." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Lo voy a cuidar. Prometido.»", Effects = { Rel = { Abu = 6 } }, Then = {
					{ S = "Abu", T = "Ya lo sé. Por eso te lo doy." },
				} },
				{ T = "Le das un abrazo sin decir nada", Effects = { Rel = { Abu = 8 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Abu", T = "(bajito) Ay… Venga, venga, que pierdes el autobús." },
				} },
			} },
		} },
		Campus = { Lines = {
			{ S = "Narrador", T = "El campus es una ciudad dentro de la ciudad: facultades, jardines, bicis, gente de todas partes hablando en cuatro idiomas." },
			{ S = "Luca", T = "Ciao! ¿Primer año? Se te nota: todos los de primero miráis hacia arriba. Soy Luca, voluntario de bienvenida. De Bolonia." },
			{ S = "Luca", T = "Primer paso: secretaría, a por el horario. Sin horario no existes. Es un poco como la pasta sin sal." },
			{ S = "Sara", T = "¡{nombre}! Te he visto desde la facultad de Ciencias. ¡Estamos en el mismo campus! Esto va a ser genial." },
		} },
		Secretaria = { Lines = {
			{ S = "Narrador", T = "Cola, sello, papel. Tu horario: lunes a las nueve, en la facultad. Y un plano del campus con tu edificio rodeado." },
			{ S = "Narrador", T = "Facultad de Medicina. Anatomía a primera hora del lunes. Empieza fuerte.", If = carrera("Medicina") },
			{ S = "Narrador", T = "Facultad de Ingeniería. Física el primer día. Sofía, la del laboratorio, da una asignatura en segundo.", If = carrera("Ingenieria") },
			{ S = "Narrador", T = "Facultad de Derecho. Derecho Civil el primer día. El edificio parece un juzgado. Probablemente a propósito.", If = carrera("Derecho") },
			{ S = "Narrador", T = "Facultad de Economía. Microeconomía el primer día. Hay una pantalla con la bolsa en el vestíbulo.", If = carrera("Economia") },
		} },
		Beltran = { Lines = {
			{ S = "Beltran", T = "Buenos días. Soy la profesora Beltrán. Llevo treinta años aquí. He visto entrar a muchos. Y salir a casi todos." },
			{ S = "Beltran", T = "Aquí nadie va a perseguiros para que estudiéis. La libertad es vuestra. La responsabilidad, también." },
			{ S = "Julia", T = "(a tu lado, susurrando) He traído tres bolígrafos por si se me acaba la tinta. Y un cuarto por si acaso. ¿Quieres uno?" },
			{ S = "Adrian", T = "(delante) Profesora, ¿habrá trabajos en grupo? Porque yo suelo coordinar." },
			{ S = "Beltran", T = "Habrá. Y coordinará quien el grupo decida, no quien lo pida primero." },
			{ S = "Narrador", T = "La puerta se abre. Entra una chica corriendo, sin aliento, diez minutos tarde. Se sienta en la última fila. Es Carla." },
			{ S = "Mateo", T = "¡{nombre}! ¡Lo sabía! Te dije que quería entender cómo funcionan las cosas. Pues aquí estamos. Juntos otra vez.", If = { Flags = { "AyudasteAMateo" }, Choices = { Estudios = "Ingenieria" } } },
		} },
		Biblioteca = { Lines = {
			{ S = "Narrador", T = "La misma biblioteca que fotografiaste con Leire hace años. Ahora tienes carnet. Y la estudiante dormida sobre el libro… sigue ahí. O es otra.", If = { Choices = { Club = "Fotografia" } } },
			{ S = "Narrador", T = "Una biblioteca de tres plantas, silenciosa, con sillones junto a las ventanas. Te dan un carnet con tu foto. Sales fatal, como en todos." },
			{ S = "Sara", T = "Mi sitio es ese, el de la ventana. Si alguna vez estudias aquí, te guardo el de al lado." },
		} },
		Cafeteria = { Lines = {
			{ S = "Narrador", T = "Un café de máquina que sabe a cartón y un bocadillo sorprendentemente bueno." },
			{ S = "Luca", T = "Consejo de veterano: el bocadillo, sí. El café, nunca. El café se toma en la ciudad, en la Cafetería Central." },
			{ S = "Luca", T = "Allí trabaja Omar, ¿no? ¡Tu amigo! Lo conozco: me ha dado croquetas gratis dos veces.", If = { Memories = { "ElRumor" } } },
		} },
		Deportes = { Lines = {
			{ S = "Narrador", T = "Fútbol, baloncesto, atletismo, escalada, yoga… Una chica reparte folletos del equipo de baloncesto. Es Álex. Te reconoce." },
			{ S = "Alex", T = "¡No me lo creo! ¡{nombre}! Estoy en el equipo de la universidad. Si quieres, hay pruebas el jueves. Como en el instituto." },
		} },
		Come_Luca = { Lines = {
			{ S = "Luca", T = "¡Bravo! Te enseño el truco del comedor: si llegas a las dos menos cinco, no hay cola y quedan croquetas." },
			{ S = "Luca", T = "Yo también llegué solo hace un año. No conocía a nadie. Por eso me hice voluntario: para que nadie coma solo el primer día." },
		} },
		Come_Sara = { Lines = {
			{ S = "Sara", T = "Como en el colegio. Pero con peor comida. Y yo con gafas nuevas. Por lo demás, igual." },
			{ S = "Sara", T = "¿Te acuerdas de cuando éramos del tamaño de esta mesa? Técnicamente, más pequeños." },
		} },
		Come_Clase = { Lines = {
			{ S = "Julia", T = "¡Siéntate! Estamos comparando horarios. Adrián ya ha hecho una tabla de colores." },
			{ S = "Adrian", T = "Es para organizarnos. Alguien tiene que hacerlo. ¿Carla? Se ha ido corriendo otra vez. Qué rara." },
		} },
		Come_Sola = { Lines = {
			{ S = "Narrador", T = "Comes a tu aire, mirando el campus. Por primera vez en tu vida, nadie sabe quién eres. Da miedo. Y también da una sensación de libertad enorme." },
		} },
		Mensajes = { Lines = {
			{ S = "Narrador", T = "Tu móvil vibra. El grupo de siempre sigue vivo." },
			{ S = "Omar", T = "(mensaje) ¿QUÉ TAL EL PRIMER DÍA? Yo he pelado cuarenta kilos de patatas. Lola dice que tengo futuro." },
			{ S = "Nico", T = "(mensaje) Entreno con el juvenil de Altamar. Me han llamado «el nuevo». Tengo diecinueve años de «nuevo» por delante." },
			{ S = "Leire", T = "(mensaje) Primer día en la escuela de cine. Aquí todos hablan en planos. Me siento en casa. Os echo de menos.", If = CON_LEIRE },
			{ S = "Hugo", T = "(mensaje) La facultad de Periodismo tiene una redacción de verdad. Ya he escrito mi primer artículo. Era sobre piratas.", If = CON_HUGO },
			{ S = "Familia", T = "¿Qué tal ha ido? ¿Has comido? ¿Has hecho amigos? Cuéntamelo todo. Bueno, lo que quieras." },
			{ S = "Narrador", T = "Esa noche, antes de dormir, das cuerda al reloj de {abu}. Tic-tac. Empieza algo nuevo." },
		} },
	},
}
