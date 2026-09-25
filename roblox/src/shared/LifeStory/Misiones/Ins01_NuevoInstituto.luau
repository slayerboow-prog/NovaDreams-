-- INSTITUTO 01 · «EL NUEVO INSTITUTO» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.24.
--
-- Septiembre. La mañana en casa → la parada con tus amigos (ya no sois niños) → el autobús al Campus
-- Valmar → un instituto enorme: un veterano te toma el pelo → encontrar tu aula (tablón, delegada,
-- Iker) → Javier, el tutor, y la lista de clase (tu grupo se reparte; Bruno está en tu clase) → dónde
-- te sientas (Omar, Leire la nueva o Bruno) → Historia → el recreo: el grupo ya no está junto →
-- Leire come sola (hablar con ella o no: consecuencia 2 h después) → Matemáticas → vuelta a casa.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }
local BRUNO_DE_CERO = { Choices = { AdiosBruno = "DeCero" } }

local CASA = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2) },
}
local PARADA = {
	{ Npc = "Nico", Place = "ParadaBus", Offset = V(-3, 0, 2) },
	{ Npc = "Omar", Place = "ParadaBus", Offset = V(3, 0, 2) },
	{ Npc = "Sara", Place = "ParadaBus", Offset = V(0, 0, 4) },
	{ Npc = "Mateo", Place = "ParadaBus", Offset = V(-5, 0, 4), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "ParadaBus", Offset = V(5, 0, 4), If = CON_HUGO },
}
local ENTRADA = {
	{ Npc = "Veterano", Place = "Instituto", Offset = V(-4, 0, 6) },
	{ Npc = "Delegada", Place = "Instituto", Offset = V(6, 0, 4) },
	{ Npc = "Iker", Place = "Instituto", Offset = V(2, 0, 8), If = CON_IKER },
	{ Npc = "Omar", Mode = "Follow" },
	{ Npc = "Alumno1", Place = "Instituto", Offset = V(10, 0, 10), Mode = "Wander", Radius = 10 },
	{ Npc = "Alumno2", Place = "Instituto", Offset = V(-10, 0, 12), Mode = "Wander", Radius = 10 },
	{ Npc = "Alumno3", Place = "Instituto", Offset = V(0, 0, 14), Mode = "Wander", Radius = 10 },
	{ Npc = "Alumno4", Place = "Instituto", Offset = V(-6, 0, 16), Mode = "Wander", Radius = 10 },
}
local CLASE = {
	{ Npc = "Javier", Place = "AulaInstituto", Offset = V(0, 0, -6) },
	{ Npc = "Omar", Place = "AulaInstituto", Offset = V(3, 0, 0) },
	{ Npc = "Nico", Place = "AulaInstituto", Offset = V(-4, 0, 2) },
	{ Npc = "Leire", Place = "AulaInstituto", Offset = V(6, 0, 3) },
	{ Npc = "Bruno", Place = "AulaInstituto", Offset = V(-6, 0, -1) },
	{ Npc = "Iker", Place = "AulaInstituto", Offset = V(1, 0, 4), If = CON_IKER },
	{ Npc = "Alumno1", Place = "AulaInstituto", Offset = V(-2, 0, 5) },
	{ Npc = "Alumno4", Place = "AulaInstituto", Offset = V(4, 0, 6) },
}
local RECREO = {
	{ Npc = "Omar", Place = "PatioInstituto", Offset = V(0, 0, 3) },
	{ Npc = "Sara", Place = "PatioInstituto", Offset = V(3, 0, 2) },
	{ Npc = "Nico", Place = "PatioInstituto", Offset = V(14, 0, -4), Bark = "¡Pásala! ¡Aquí!" },
	{ Npc = "Mateo", Place = "PatioInstituto", Offset = V(-3, 0, 4), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "PatioInstituto", Offset = V(-4, 0, 1), If = CON_HUGO },
	{ Npc = "Leire", Place = "PatioInstituto", Offset = V(-16, 0, 8), Mode = "Sit" },
	{ Npc = "Veterano", Place = "PatioInstituto", Offset = V(12, 0, 6) },
	{ Npc = "Alumno2", Place = "PatioInstituto", Offset = V(16, 0, -2) },
	{ Npc = "Alumno3", Place = "PatioInstituto", Offset = V(12, 0, -6) },
}

return {
	Id = "Ins01_NuevoInstituto",
	Kind = "Main",
	Title = "El nuevo instituto",
	Description = "Septiembre. Un edificio enorme, gente mayor que tú, tu grupo repartido en clases distintas… y alguien nuevo que no conoce a nadie.",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 12, 13 },
	Duration = { 20, 30 },
	Difficulty = 1,
	Type = "Historia · Nueva etapa",
	Npcs = { "Familia", "Abu", "Nico", "Omar", "Sara", "Mateo", "Hugo", "Iker", "Veterano", "Delegada", "Javier", "Leire", "Bruno" },
	Locations = { "HomeSalon", "ParadaBus", "Instituto", "AulaInstituto", "PatioInstituto" },
	Next = { "Ins02_Clubes" },
	Outcomes = { "Dónde te sientas", "El grupo en el recreo", "Hablar con Leire o no" },

	Moment = "Tu primer día de instituto",
	Memory = "PrimerDiaInstituto",
	Rewards = { Items = { CarnetInstituto = 1 }, Later = {
		{ AfterHours = 2, Start = "Eco_Leire", If = { Flags = { "ConocesALeire" } } },
		{ AfterHours = 2, Start = "Eco_LeireSola", If = { Flags = { "IgnorasteALeire" } } },
	} },

	Props = {
		Tablon = { Kind = "Marcador", Name = "Tablón de clases", Prompt = "Buscar tu nombre", Place = "Instituto", Offset = V(3, 0, 10), Dialogue = "Tablon", Once = true },
		Ascensor = { Kind = "Marcador", Name = "«Ascensor de alumnos»", Prompt = "Esperar el ascensor", Place = "Instituto", Offset = V(-8, 0, 4), Dialogue = "Ascensor", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Tres meses después. Septiembre.", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Manana", Teleport = "HomeSalon", Actors = CASA },
		{ Type = "Reach", Place = "ParadaBus", Text = "Ve a la parada del autobús: tus amigos te esperan", Actors = PARADA,
			Nudge = { After = 120, Every = 90, S = "Omar", T = "(mensaje) ¿Dónde estás? El bus pasa en nada. Te guardo sitio. Y medio cruasán." } },
		{ Type = "Scene", Dialogue = "Parada", Actors = PARADA },
		{ Type = "Event", Event = "Traveled", Match = { Town = "Campus Valmar" }, Place = "ParadaBus", Text = "Coge el autobús al Campus Valmar", Actors = PARADA },

		-- Un instituto enorme
		{ Type = "Reach", Place = "Instituto", Text = "Busca la entrada del instituto", Actors = ENTRADA },
		{ Type = "Scene", Dialogue = "Entrada", Actors = ENTRADA },
		{ Type = "Choice", Key = "Veterano", Text = "¿Le haces caso al veterano (el «ascensor de alumnos») o buscas por tu cuenta?",
			Options = {
				{ Id = "Creer", Prop = "Ascensor", Text = "Esperar el ascensor", Dialogue = "Ascensor", Effects = { Traits = { Humor = 1 } } },
				{ Id = "Dudar", Npc = "Delegada", Text = "Preguntar a la delegada", Dialogue = "Delegada", Effects = { Traits = { Curiosidad = 1 } } },
			},
			Actors = ENTRADA },
		{ Type = "Use", Prop = "Tablon", Text = "Busca tu clase en el tablón", Actors = ENTRADA },
		{ Type = "Reach", Place = "AulaInstituto", Text = "Ve al aula de 1.º C", Actors = CLASE,
			Late = { After = 240, Flags = { "LlegasTardeInstituto" } } },
		{ Type = "Scene", Dialogue = "Tutor", Actors = CLASE },
		{ Type = "Choice", Key = "SitioInstituto", Text = "¿Dónde te sientas? (habla con quien elijas)",
			Options = {
				{ Id = "Omar", Npc = "Omar", Text = "Con Omar, como siempre", Dialogue = "Sit_Omar", Effects = { Rel = { Omar = 5 } } },
				{ Id = "Leire", Npc = "Leire", Text = "Con la chica nueva", Dialogue = "Sit_Leire", Flags = { "ConocesALeire" }, Effects = { Rel = { Leire = 8 }, Traits = { Empatia = 1 } } },
				{ Id = "Bruno", Npc = "Bruno", Text = "Con Bruno (¿empezar de cero?)", Dialogue = "Sit_Bruno", If = BRUNO_DE_CERO, Effects = { Rel = { Bruno = 8 } } },
			},
			Actors = CLASE },
		{ Type = "Class", Subject = "HistoriaInstituto", Mode = "Clase", Place = "AulaInstituto", Text = "Clase de Historia con Javier", Actors = CLASE },

		-- El recreo: el grupo, repartido
		{ Type = "Reach", Place = "PatioInstituto", Text = "Sal al recreo", Actors = RECREO },
		{ Type = "Scene", Dialogue = "Recreo", Actors = RECREO },
		{ Type = "Talk", Npc = "Leire", Dialogue = "Leire_Recreo", Text = "Leire come sola en un banco. ¿Vas?", If = { NotFlags = { "ConocesALeire" } },
			Timeout = { After = 60, OnlyIfUntouched = true, Flags = { "IgnorasteALeire" } },
			Actors = RECREO },
		{ Type = "Class", Subject = "MatematicasInstituto", Mode = "Clase", Place = "AulaInstituto", Text = "Clase de Matemáticas", Actors = CLASE },

		-- Vuelta a casa
		{ Type = "Transition", Text = "Por la tarde…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Cena", Teleport = "HomeSalon", Actors = CASA },
	},

	Dialogues = {
		Manana = { Lines = {
			{ S = "Familia", T = "¡{nombre}! Primer día de instituto. ¿Estás bien? ¿Tienes de todo? ¿Quieres que te acompañe?" },
			{ S = "Abu", T = "Déjale respirar, que ya es mayor. Bueno, un poco mayor. Lo justo." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Acompáñame hasta la puerta, porfa»", Effects = { Choice = { PrimerDiaIns = "Acompanado" }, Rel = { Familia = 4 } }, Then = {
					{ S = "Familia", T = "¡Hasta la puerta de casa! Ni un paso más, prometido. …Bueno, hasta la esquina." },
				} },
				{ T = "«Puedo ir por mi cuenta. Pero gracias.»", Effects = { Choice = { PrimerDiaIns = "Solo" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Familia", T = "Vale, vale. Qué rápido pasa todo. Ayer tenías la mochila más grande que tú." },
				} },
			} },
			{ S = "Abu", T = "Un consejo de los de antes: el primer día, sonríe a una persona que no conozcas. Solo a una. Ya verás." },
		} },
		Parada = { Lines = {
			{ S = "Narrador", T = "En la parada os miráis como si no os conocierais. Todos habéis crecido este verano. Omar, sobre todo: ahora es el más alto." },
			{ S = "Omar", T = "Lo sé. Me he chocado dos veces con el marco de la puerta. Mi madre dice que es la edad." },
			{ S = "Sara", T = "Me han puesto en el grupo bilingüe. No vamos a estar en la misma clase. Lo he comprobado tres veces." },
			{ S = "Nico", T = "Pero en el recreo sí. ¡Lo prometimos!", If = { Choices = { Promesa = "Juntos" } } },
			{ S = "Nico", T = "Prometimos conocer gente nueva sin olvidarnos. Pues hoy empieza la parte de «gente nueva».", If = { Choices = { Promesa = "Nuevos" } } },
			{ S = "Nico", T = "Y el banco del parque en verano sigue en pie. Eso no lo cambia ningún instituto.", If = { Choices = { Promesa = "Banco" } } },
			{ S = "Hugo", T = "He traído un libro por si nadie me habla. Pero espero no tener que leerlo.", If = CON_HUGO },
			{ S = "Omar", T = "¡El autobús! Ese que pone «Campus Valmar». Vamos, que yo me mareo si voy de pie." },
		} },
		Entrada = { Lines = {
			{ S = "Narrador", T = "El instituto es tres veces el colegio. Pasillos, escaleras, gente que parece adulta. Nadie os mira. O eso parece." },
			{ S = "Veterano", T = "¿Los de primero? Uy, qué pequeños. El aula de primero está en el tercer piso. Coged el ascensor de alumnos, ahí a la izquierda." },
			{ S = "Omar", T = "¿Hay ascensor de alumnos? Qué moderno. …¿Hay ascensor de alumnos?" },
		} },
		Ascensor = { Lines = {
			{ S = "Narrador", T = "Esperas delante de una puerta que pone «CUARTO DE LIMPIEZA». Pasa un minuto. Detrás, se oyen risas." },
			{ S = "Veterano", T = "¡Todos los años alguien cae! Tranqui, a mí me lo hicieron también. El aula de 1.º C está en la planta baja, al fondo." },
			{ S = "Omar", T = "Esto lo cuento en la cena y me río. Dentro de unos años." },
		} },
		Delegada = { Lines = {
			{ S = "Delegada", T = "¿El ascensor de alumnos? No existe. Todos los años lo dicen. Ignóralo." },
			{ S = "Delegada", T = "Los de primero estáis en la planta baja. Mira el tablón y busca tu nombre. Y si necesitas algo, soy la delegada de cuarto." },
		}, Effects = { Rel = { Delegada = 5 } } },
		Tablon = { Lines = {
			{ S = "Narrador", T = "Listas y listas de nombres. 1.º A, 1.º B, bilingüe… 1.º C: ahí estás. Y Omar. Y Nico. Y… Bruno." },
			{ S = "Omar", T = "¿Bruno? ¿Otra vez? Esto ya es el destino." },
			{ S = "Iker", T = "Yo también estoy en 1.º C. Me descargué el plano en julio: planta baja, tercera puerta, la de la ventana rota.", If = CON_IKER },
		} },

		Tutor = { Lines = {
			{ S = "Javier", T = "Buenos días, 1.º C. Soy Javier, vuestro tutor. Os daré Historia. Y alguna charla que no me habéis pedido.", If = { NotFlags = { "LlegasTardeInstituto" } } },
			{ S = "Javier", T = "Ah, llega {nombre}. El primer día, perdonado. Se pierde todo el mundo. Yo me perdí mi primer año de profe.", If = { Flags = { "LlegasTardeInstituto" } } },
			{ S = "Javier", T = "Aquí nadie os va a llevar de la mano. Pero si os perdéis, preguntad. Preguntar no es de pequeños: es de listos." },
			{ S = "Javier", T = "Tenemos una alumna nueva: Leire, que viene del norte. Leire, ¿quieres decir algo?" },
			{ S = "Leire", T = "No." },
			{ S = "Javier", T = "Directa. Me gusta. Sentaos donde queráis. El sitio de hoy suele ser el de todo el año, así que pensadlo." },
			{ S = "Bruno", T = "(desde el fondo) Eh, {nombre}. Aquí hay sitio. Si quieres. De cero, ¿no?", If = BRUNO_DE_CERO },
		} },
		Sit_Omar = { Lines = {
			{ S = "Omar", T = "Lo sabía. Te he guardado el sitio desde las ocho menos cuarto. Sabía que vendrías." },
		} },
		Sit_Leire = { Lines = {
			{ S = "Leire", T = "…Vale. Siéntate. Pero no me preguntes por la cámara. Todo el mundo me pregunta por la cámara." },
			{ S = "Leire", T = "…Es de mi abuelo. Es de carrete. Hace fotos de verdad. Bueno, ya te lo he contado. Qué rabia." },
		} },
		Sit_Bruno = { Lines = {
			{ S = "Bruno", T = "¿En serio? Vale. Normas: no me copies en los exámenes. Y yo tampoco a ti. Eso lo añado ahora." },
			{ S = "Bruno", T = "…Oye, que aquí no conozco a nadie tampoco. Está bien tener a alguien conocido." },
		} },

		Recreo = { Lines = {
			{ S = "Narrador", T = "El patio del instituto es enorme y cada grupo tiene su rincón. El vuestro… todavía no existe." },
			{ S = "Sara", T = "¡Os he encontrado! En mi clase hablan de cosas rarísimas. De series. Yo quería hablar de hongos." },
			{ S = "Narrador", T = "Nico juega al fútbol con los de segundo. Te saluda con la mano… y sigue jugando." },
			{ S = "Omar", T = "Nico ya tiene amigos nuevos. Está bien, ¿no? Está bien. Me lo digo a mí mismo." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "«Esto es nuestro rincón desde hoy.» Te sientas con Omar y Sara", Effects = { Choice = { RecreoIns = "Rincon" }, Rel = { Omar = 3, Sara = 3 } }, Then = {
					{ S = "Sara", T = "Declaramos este banco territorio del grupo. Con sus derechos y sus bocadillos." },
				} },
				{ T = "Vas a jugar con Nico y los de segundo", Effects = { Choice = { RecreoIns = "Nico" }, Rel = { Nico = 5 }, Traits = { Deportividad = 1 } }, Then = {
					{ S = "Nico", T = "¡{nombre}! ¡Menos mal! Estos de segundo son buenos, pero no se saben nuestras jugadas." },
				} },
				{ T = "Das una vuelta para conocer el instituto", Effects = { Choice = { RecreoIns = "Explorar" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Narrador", T = "Laboratorios, un gimnasio con gradas, una biblioteca con sillones… y, en un banco apartado, Leire comiendo sola.", If = { NotFlags = { "ConocesALeire" } } },
					{ S = "Narrador", T = "Laboratorios, un gimnasio con gradas, una biblioteca con sillones. Leire te saluda desde lejos con la cámara.", If = { Flags = { "ConocesALeire" } } },
				} },
			} },
		} },
		Leire_Recreo = { Lines = {
			{ S = "Leire", T = "¿Qué? Estoy bien sola. …Vale, no mucho." },
			{ S = "Leire", T = "En mi otra ciudad tenía un grupo. Ahora tengo una cámara y un bocadillo de chorizo. El bocadillo es buena compañía, pero no habla." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Vente con nosotros. Omar trae comida para todos.»", Effects = { Flags = { "ConocesALeire" }, Rel = { Leire = 10, Omar = 2 }, Traits = { Empatia = 2 } }, Then = {
					{ S = "Omar", T = "(desde lejos) ¡Es verdad! ¡Traigo de todo! ¡Hasta aceitunas!" },
					{ S = "Leire", T = "…Vale. Pero si son pesados, me vuelvo al banco." },
				} },
				{ T = "«¿Me enseñas qué fotos haces?»", Effects = { Flags = { "ConocesALeire" }, Rel = { Leire = 8 }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Leire", T = "Nadie me pregunta por las fotos. Solo por la cámara. …Mira. Esta es mi antigua calle. Y esta, el mar." },
				} },
			} },
		} },
		Cena = { Lines = {
			{ S = "Familia", T = "¡Cuéntalo todo! ¿Cómo es? ¿Es grande? ¿Te has perdido? ¿Has comido?" },
			{ S = "Familia", T = "¿El ascensor de alumnos? ¡A mí me lo hicieron también! Hay cosas que no cambian nunca.", If = { Choices = { Veterano = "Creer" } } },
			{ S = "Familia", T = "¿Una compañera nueva que se llama Leire? Qué bien que te hayas acercado. Empezar en una ciudad nueva es muy difícil.", If = { Flags = { "ConocesALeire" } } },
			{ S = "Abu", T = "¿Y a quién le sonreíste? …Ah, se nota. Se nota en la cara." },
			{ S = "Narrador", T = "Esa noche, antes de dormir, piensas que el instituto da un poco de miedo. Y que también tiene pinta de ser muy divertido." },
		} },
	},
}
