-- INSTITUTO 02 · «LOS CLUBES» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.25.
--
-- Feria de clubes en el patio → visitar puestos (baloncesto con Álex, teatro con Rubén, robótica con
-- Sara, periódico con Hugo, fotografía con Leire) → elegir club → la prueba de cada club es una
-- aventura distinta (tiros, audición, el robot que se escapa, el misterio de los murales, un paseo
-- fotográfico por el campus) → el primer evento del club cae el mismo día que el cumpleaños de Nico:
-- club, cumpleaños o intentar llegar a los dos.

local V = Vector3.new

local BALONCESTO = { Choices = { Club = "Baloncesto" } }
local TEATRO = { Choices = { Club = "Teatro" } }
local ROBOTICA = { Choices = { Club = "Robotica" } }
local PERIODICO = { Choices = { Club = "Periodico" } }
local FOTOGRAFIA = { Choices = { Club = "Fotografia" } }

local FERIA = {
	{ Npc = "Javier", Place = "PatioInstituto", Offset = V(0, 0, 10) },
	{ Npc = "Alex", Place = "PatioInstituto", Offset = V(-12, 0, 2) },
	{ Npc = "Ruben", Place = "PatioInstituto", Offset = V(-6, 0, 6) },
	{ Npc = "Sara", Place = "PatioInstituto", Offset = V(0, 0, 4) },
	{ Npc = "Hugo", Place = "PatioInstituto", Offset = V(6, 0, 6) },
	{ Npc = "Leire", Place = "PatioInstituto", Offset = V(12, 0, 2) },
	{ Npc = "Omar", Mode = "Follow" },
	{ Npc = "Alumno1", Place = "PatioInstituto", Offset = V(4, 0, -6), Mode = "Wander", Radius = 10 },
	{ Npc = "Alumno3", Place = "PatioInstituto", Offset = V(-4, 0, -6), Mode = "Wander", Radius = 10 },
}

local function club(npc: string, place: string, cond: any): { any }
	return {
		{ Npc = npc, Place = place, Offset = V(0, 0, 4), If = cond },
		{ Npc = "Omar", Mode = "Follow", If = cond },
	}
end

return {
	Id = "Ins02_Clubes",
	Kind = "Main",
	Title = "Los clubes",
	Description = "Feria de clubes en el instituto. Elige el tuyo… y descubre que cada club es un mundo.",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 13, 13 },
	Duration = { 20, 30 },
	Difficulty = 2,
	Type = "Historia · Instituto",
	Requires = { Completed = { "Ins01_NuevoInstituto" }, StageProgress = 0.12 },
	Npcs = { "Javier", "Alex", "Ruben", "Sara", "Hugo", "Leire", "Vega", "Omar", "Nico", "Veterano", "Delegada", "Toni" },
	Locations = { "PatioInstituto", "PistaInstituto", "AulaInstituto", "Universidad", "Biblioteca", "EstadioUniversitario", "Parque" },
	Next = { "Ins03_QueQuieresSer" },
	Outcomes = { "Tu club (cinco caminos)", "Publicar o proteger un secreto", "Club, cumpleaños o las dos cosas" },

	Moment = "Te apuntaste a tu primer club",
	Memory = "PrimerClub",
	Rewards = { Items = { InsigniaClub = 1 } },

	Props = {
		-- La feria
		PuestoBaloncesto = { Kind = "Kiosco", Name = "Puesto de baloncesto", Prompt = "Mirar", Place = "PatioInstituto", Offset = V(-12, 0, 0), Color = Color3.fromRGB(240, 120, 40), Dialogue = "Puesto_Baloncesto", Once = true },
		PuestoTeatro = { Kind = "Kiosco", Name = "Puesto de teatro", Prompt = "Mirar", Place = "PatioInstituto", Offset = V(-6, 0, 4), Color = Color3.fromRGB(160, 40, 60), Dialogue = "Puesto_Teatro", Once = true },
		PuestoRobotica = { Kind = "Kiosco", Name = "Puesto de robótica", Prompt = "Mirar", Place = "PatioInstituto", Offset = V(0, 0, 2), Color = Color3.fromRGB(150, 160, 170), Dialogue = "Puesto_Robotica", Once = true },
		PuestoPeriodico = { Kind = "Kiosco", Name = "Puesto del periódico", Prompt = "Mirar", Place = "PatioInstituto", Offset = V(6, 0, 4), Color = Color3.fromRGB(240, 240, 230), Dialogue = "Puesto_Periodico", Once = true },
		PuestoFotografia = { Kind = "Kiosco", Name = "Puesto de fotografía", Prompt = "Mirar", Place = "PatioInstituto", Offset = V(12, 0, 0), Color = Color3.fromRGB(40, 40, 50), Dialogue = "Puesto_Fotografia", Once = true },
		-- Robótica: el robot que se escapa
		Robot1 = { Kind = "Caja", Name = "¡El robot!", Prompt = "Atraparlo", Place = "AulaInstituto", Offset = V(4, 0, 4), Color = Color3.fromRGB(190, 200, 210), Spin = true, Dialogue = "Robot1", Once = true },
		Robot2 = { Kind = "Caja", Name = "¡El robot!", Prompt = "Atraparlo", Place = "PatioInstituto", Offset = V(-10, 0, 12), Color = Color3.fromRGB(190, 200, 210), Spin = true, Dialogue = "Robot2", Once = true },
		Robot3 = { Kind = "Caja", Name = "¡El robot!", Prompt = "Atraparlo", Place = "PistaInstituto", Color = Color3.fromRGB(190, 200, 210), Spin = true, Dialogue = "Robot3", Once = true },
		-- Periódico: los murales misteriosos
		MuralNocturno = { Kind = "Mural", Name = "Un mural nuevo", Prompt = "Examinar", Place = "PatioInstituto", Offset = V(-16, 0, 10), Dialogue = "Mural", Once = true },
		-- Fotografía: paseo por el campus
		FotoUni = { Kind = "Marcador", Name = "La universidad", Prompt = "Hacer una foto", Place = "Universidad", Dialogue = "Foto_Uni", Once = true },
		FotoBiblio = { Kind = "Marcador", Name = "La biblioteca del campus", Prompt = "Hacer una foto", Place = "Biblioteca", Dialogue = "Foto_Biblio", Once = true },
		FotoEstadio = { Kind = "Marcador", Name = "El estadio", Prompt = "Hacer una foto", Place = "EstadioUniversitario", Dialogue = "Foto_Estadio", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Unas semanas después…", Seconds = 3 },
		{ Type = "Reach", Place = "PatioInstituto", Text = "Ve al patio: hoy es la feria de clubes", Actors = FERIA },
		{ Type = "Scene", Dialogue = "Feria", Actors = FERIA },
		{ Type = "Group", Text = "Visita los puestos (al menos tres)", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "PuestoBaloncesto", Text = "Baloncesto" },
				{ Type = "Use", Prop = "PuestoTeatro", Text = "Teatro" },
				{ Type = "Use", Prop = "PuestoRobotica", Text = "Robótica" },
				{ Type = "Use", Prop = "PuestoPeriodico", Text = "Periódico" },
				{ Type = "Use", Prop = "PuestoFotografia", Text = "Fotografía" },
			},
			Actors = FERIA },
		{ Type = "Choice", Key = "Club", Text = "¿A qué club te apuntas? (habla con quien lo lleva)",
			Options = {
				{ Id = "Baloncesto", Npc = "Alex", Text = "Baloncesto, con Álex", Dialogue = "Apunta_Baloncesto", Effects = { Rel = { Alex = 5 } } },
				{ Id = "Teatro", Npc = "Ruben", Text = "Teatro, con Rubén", Dialogue = "Apunta_Teatro", Effects = { Rel = { Ruben = 5 } } },
				{ Id = "Robotica", Npc = "Sara", Text = "Robótica, con Sara", Dialogue = "Apunta_Robotica", Effects = { Rel = { Sara = 5 } } },
				{ Id = "Periodico", Npc = "Hugo", Text = "Periódico, con Hugo", Dialogue = "Apunta_Periodico", Effects = { Rel = { Hugo = 5 } } },
				{ Id = "Fotografia", Npc = "Leire", Text = "Fotografía, con Leire", Dialogue = "Apunta_Fotografia", Effects = { Rel = { Leire = 6 } } },
			},
			Actors = FERIA },

		-- Baloncesto: la prueba
		{ Type = "Reach", Place = "PistaInstituto", Text = "Ve a la pista: prueba del equipo", If = BALONCESTO, Actors = club("Alex", "PistaInstituto", BALONCESTO) },
		{ Type = "Scene", Dialogue = "Prueba_Baloncesto", If = BALONCESTO, Actors = club("Alex", "PistaInstituto", BALONCESTO) },
		{ Type = "MiniGame", Game = "Timing", Title = "Prueba: tiros desde la línea", Icon = "🏀", Hint = "Cada tiro, más difícil. Necesitas 4.",
			Rounds = 8, Need = 4, Zone = 0.24, Shrink = 0.025, Speed = 1.1, If = BALONCESTO,
			Win = { Flags = { "ClubTitular" }, Traits = { Deportividad = 1 } }, Lose = { Flags = { "ClubSuplente" } },
			Actors = club("Alex", "PistaInstituto", BALONCESTO) },

		-- Teatro: la audición
		{ Type = "Reach", Place = "AulaInstituto", Text = "Ve al aula de teatro: audición", If = TEATRO, Actors = club("Ruben", "AulaInstituto", TEATRO) },
		{ Type = "Scene", Dialogue = "Audicion", If = TEATRO, Actors = club("Ruben", "AulaInstituto", TEATRO) },
		{ Type = "MiniGame", Game = "Timing", Title = "Audición: di el texto con ritmo", Icon = "🎭", Hint = "Habla en la zona verde",
			Rounds = 6, Need = 4, Zone = 0.25, Speed = 1, If = TEATRO,
			Win = { Flags = { "ClubTitular" }, Traits = { Valentia = 1 } }, Lose = { Flags = { "ClubSuplente" }, Traits = { Humor = 1 } },
			Actors = club("Ruben", "AulaInstituto", TEATRO) },

		-- Robótica: el robot se escapa
		{ Type = "Reach", Place = "AulaInstituto", Text = "Ve al laboratorio de robótica (aula)", If = ROBOTICA, Actors = club("Sara", "AulaInstituto", ROBOTICA) },
		{ Type = "Scene", Dialogue = "Robotica", If = ROBOTICA, Actors = club("Sara", "AulaInstituto", ROBOTICA) },
		{ Type = "MiniGame", Game = "Timing", Title = "Programa al robot", Icon = "🤖", Hint = "Mete cada orden en la zona verde",
			Rounds = 5, Need = 3, Zone = 0.25, Speed = 1, If = ROBOTICA,
			Win = { Flags = { "ClubTitular" } }, Lose = { Flags = { "ClubSuplente" } },
			Actors = club("Sara", "AulaInstituto", ROBOTICA) },
		{ Type = "Use", Prop = "Robot1", Text = "¡El robot se ha escapado! Atrápalo", If = ROBOTICA, Actors = { { Npc = "Sara", Mode = "Follow" } } },
		{ Type = "Use", Prop = "Robot2", Text = "¡Se ha ido al patio!", If = ROBOTICA, Actors = { { Npc = "Sara", Mode = "Follow" } } },
		{ Type = "Use", Prop = "Robot3", Text = "¡Ahora va hacia la pista!", If = ROBOTICA, Actors = { { Npc = "Sara", Mode = "Follow" } },
			Effects = { Traits = { Curiosidad = 2 }, Rel = { Sara = 5 } } },

		-- Periódico: ¿quién pinta los murales?
		{ Type = "Scene", Dialogue = "Periodico", If = PERIODICO, Actors = club("Hugo", "PatioInstituto", PERIODICO) },
		{ Type = "Group", Text = "Investiga quién pinta los murales por la noche", If = PERIODICO,
			Steps = {
				{ Type = "Use", Prop = "MuralNocturno", Text = "Examina el mural nuevo" },
				{ Type = "Talk", Npc = "Veterano", Dialogue = "Pregunta_Veterano", Text = "Pregunta al veterano" },
				{ Type = "Talk", Npc = "Delegada", Dialogue = "Pregunta_Delegada", Text = "Pregunta a la delegada" },
			},
			Actors = {
				{ Npc = "Hugo", Mode = "Follow", If = PERIODICO },
				{ Npc = "Veterano", Place = "PatioInstituto", Offset = V(10, 0, 8), If = PERIODICO },
				{ Npc = "Delegada", Place = "PatioInstituto", Offset = V(-4, 0, -8), If = PERIODICO },
			} },
		{ Type = "Talk", Npc = "Vega", Dialogue = "Vega_Murales", Text = "Todas las pistas llevan a… Vega", If = PERIODICO,
			Actors = { { Npc = "Hugo", Mode = "Follow" }, { Npc = "Vega", Place = "PatioInstituto", Offset = V(-14, 0, 12) } } },

		-- Fotografía: paseo por el campus
		{ Type = "Scene", Dialogue = "Fotografia", If = FOTOGRAFIA, Actors = club("Leire", "PatioInstituto", FOTOGRAFIA) },
		{ Type = "Group", Text = "Paseo fotográfico por el campus", If = FOTOGRAFIA,
			Steps = {
				{ Type = "Use", Prop = "FotoUni", Text = "La universidad" },
				{ Type = "Use", Prop = "FotoBiblio", Text = "La biblioteca del campus" },
				{ Type = "Use", Prop = "FotoEstadio", Text = "El estadio" },
			},
			Effects = { Traits = { Creatividad = 2 }, Rel = { Leire = 6 }, Flags = { "ClubTitular" } },
			Actors = { { Npc = "Leire", Mode = "Follow" } } },

		-- El dilema del sábado
		{ Type = "Scene", Dialogue = "Dilema", Actors = {
			{ Npc = "Omar", Place = "PatioInstituto", Offset = V(2, 0, 3) },
			{ Npc = "Nico", Place = "PatioInstituto", Offset = V(-2, 0, 3) },
		} },
		{ Type = "Reach", Place = "PatioInstituto", Text = "El sábado: primer evento de tu club (patio del instituto)",
			If = { NotFlags = { "SoloCumple" } } },
		{ Type = "Scene", Dialogue = "EventoClub", If = { NotFlags = { "SoloCumple" } }, Actors = {
			{ Npc = "Alex", Place = "PatioInstituto", Offset = V(0, 0, 4), If = BALONCESTO },
			{ Npc = "Ruben", Place = "PatioInstituto", Offset = V(0, 0, 4), If = TEATRO },
			{ Npc = "Sara", Place = "PatioInstituto", Offset = V(0, 0, 4), If = ROBOTICA },
			{ Npc = "Hugo", Place = "PatioInstituto", Offset = V(0, 0, 4), If = PERIODICO },
			{ Npc = "Leire", Place = "PatioInstituto", Offset = V(0, 0, 4), If = FOTOGRAFIA },
		} },
		{ Type = "Reach", Place = "Parque", Text = "¡Corre al cumpleaños de Nico en el parque!", If = { Flags = { "IntentasLasDos" } },
			Late = { After = 300, Flags = { "LlegasTardeCumple" } } },
		{ Type = "Reach", Place = "Parque", Text = "Ve al cumpleaños de Nico en el parque", If = { Flags = { "SoloCumple" } } },
		{ Type = "Scene", Dialogue = "Cumple", If = { NotFlags = { "SoloClub" } }, Actors = {
			{ Npc = "Nico", Place = "Parque", Offset = V(0, 0, 4) },
			{ Npc = "Omar", Place = "Parque", Offset = V(3, 0, 5) },
			{ Npc = "Sara", Place = "Parque", Offset = V(-3, 0, 5) },
			{ Npc = "Leire", Place = "Parque", Offset = V(5, 0, 2), If = { Flags = { "ConocesALeire" } } },
			{ Npc = "Familia", Place = "Parque", Offset = V(-8, 0, 8) },
		} },
		{ Type = "Scene", Dialogue = "TrasElClub", If = { Flags = { "SoloClub" } } },
	},

	Dialogues = {
		Feria = { Lines = {
			{ S = "Javier", T = "Feria de clubes. Uno por persona, que luego no dormís. Elegid algo que os guste, no lo que elijan vuestros amigos." },
			{ S = "Omar", T = "Yo me apunto al tuyo. Lo que ha dicho Javier no me afecta. Soy inmune." },
			{ S = "Narrador", T = "Cinco puestos, cinco mundos: baloncesto, teatro, robótica, el periódico del instituto y fotografía." },
		} },
		Puesto_Baloncesto = { Lines = {
			{ S = "Alex", T = "¡{nombre}! Soy la capitana del equipo de primero. Hacemos prueba el martes. Sin favoritismos. Bueno, un poco." },
		} },
		Puesto_Teatro = { Lines = {
			{ S = "Ruben", T = "¿Teatro? Aquí se viene a hacer el ridículo con estilo. Yo empecé para no esconderme más. Funciona." },
			{ S = "Ruben", T = "Y… me alegro de verte. De verdad. Lo de la mochila fue hace mil años.", If = { Choices = { MochilaRuben = "Perdon" } } },
		} },
		Puesto_Robotica = { Lines = {
			{ S = "Sara", T = "Robótica: construimos robots que hacen cosas. Bueno, que INTENTAN hacer cosas. Este año, uno que reparte bocadillos." },
			{ S = "Omar", T = "¿Reparte bocadillos? Me apunto mentalmente." },
		} },
		Puesto_Periodico = { Lines = {
			{ S = "Hugo", T = "El periódico «La Voz del Campus». Somos tres. Buscamos gente que haga preguntas incómodas. Educadamente." },
			{ S = "Hugo", T = "Mi primer reportaje: alguien pinta murales por la noche en el patio. Nadie sabe quién. Es un misterio de verdad." },
		} },
		Puesto_Fotografia = { Lines = {
			{ S = "Leire", T = "Fotografía. El club soy yo. Y mi tío Toni, que viene los viernes y sabe de vídeo. No es un club muy grande." },
			{ S = "Leire", T = "Pero si vienes, salimos por el campus a hacer fotos. Enseña mucho más que el aula." },
		} },

		Apunta_Baloncesto = { Lines = { { S = "Alex", T = "¡Bien! El martes, prueba. Ven con zapatillas. Y con ganas. Las zapatillas son opcionales. Las ganas no." } } },
		Apunta_Teatro = { Lines = { { S = "Ruben", T = "¿De verdad? ¡Pasa al lado divertido! Audición mañana. Tranqui: suspende casi todo el mundo y luego entra igual." } } },
		Apunta_Robotica = { Lines = { { S = "Sara", T = "¡Sí! Tú, yo y un robot. Como en los viejos tiempos, pero con cables." } } },
		Apunta_Periodico = { Lines = { { S = "Hugo", T = "¡Genial! Tu primer caso: los murales. Llévate libreta. Y paciencia. Los buenos reportajes son lentos." } } },
		Apunta_Fotografia = { Lines = { { S = "Leire", T = "¿En serio? …Vale. Ya somos dos. Esto ya parece un club. Casi." } } },

		Prueba_Baloncesto = { Lines = {
			{ S = "Alex", T = "Tiros desde la línea. Ocho balones. Con cuatro, entras de titular. Con menos, entras igual, pero calientas banquillo." },
			{ S = "Omar", T = "Yo he venido de apoyo moral. Tengo hasta un cartel. Pone «ÁNIMO». Me he quedado sin cartulina para el nombre." },
		} },
		Audicion = { Lines = {
			{ S = "Ruben", T = "La audición: un monólogo de treinta segundos. Es de un pirata que ha perdido su barco. Tienes que decirlo con ritmo." },
			{ S = "Ruben", T = "¿Nervios? Yo el primer día me temblaban hasta las cejas. Respira y mira a un punto fijo." },
		} },
		Robotica = { Lines = {
			{ S = "Sara", T = "Este es Tornillo. Tiene dos ruedas, un sensor y mala suerte. Hay que programarle para que siga una línea." },
			{ S = "Sara", T = "Tú metes las órdenes. Yo miro el sensor. Omar mira… lo que quiera." },
		} },
		Robot1 = { Lines = {
			{ S = "Narrador", T = "¡Tornillo arranca solo y sale por la puerta! Casi lo tienes… ¡se escapa entre tus piernas!" },
			{ S = "Sara", T = "¡Le he puesto la velocidad máxima sin querer! ¡O queriendo! ¡Ya no lo sé!" },
		} },
		Robot2 = { Lines = {
			{ S = "Narrador", T = "Tornillo cruza el patio. Unos de cuarto lo graban con el móvil. Uno le aplaude. Se escapa otra vez." },
		} },
		Robot3 = { Lines = {
			{ S = "Narrador", T = "En la pista, Tornillo se choca con un cono, da una vuelta y se para. Lo coges. Está calentito. Parece contento." },
			{ S = "Sara", T = "¡Lo tenemos! Técnicamente, ha seguido una línea: la de la pista. Lo apunto como éxito." },
		} },

		Periodico = { Lines = {
			{ S = "Hugo", T = "Los murales aparecen los lunes por la mañana. Colores, pájaros, frases bonitas. El director está entre enfadado y encantado." },
			{ S = "Hugo", T = "Un buen periodista pregunta a varias personas y mira las pruebas. Nunca se fía de una sola." },
		} },
		Mural = { Lines = {
			{ S = "Narrador", T = "Un pájaro enorme de colores, y debajo: «Aquí también se puede volar». Hay purpurina pegada en la pintura." },
			{ S = "Hugo", T = "¿Purpurina? ¿Quién pinta un mural con purpurina?" },
			{ S = "Narrador", T = "Tú conoces a alguien que lo pone todo con purpurina.", If = { Choices = { Festival = "Decoracion" } } },
		} },
		Pregunta_Veterano = { Lines = {
			{ S = "Veterano", T = "Yo vi a alguien el viernes con una mochila rosa llena de botes. Alguien de primero, fijo." },
		} },
		Pregunta_Delegada = { Lines = {
			{ S = "Delegada", T = "La clave del gimnasio la tienen los clubes. El de arte usa el patio los viernes por la tarde. Solo una persona se queda hasta tarde." },
		} },
		Vega_Murales = { Lines = {
			{ S = "Vega", T = "…Vale. Soy yo. Lo hago porque el patio era gris y triste. Y porque nadie me ha pedido permiso para ser gris." },
			{ S = "Vega", T = "¿Vais a publicarlo? Si sale mi nombre, el director me va a hacer limpiarlo todo." },
			{ Ask = "¿Qué hacéis con el reportaje?", Options = {
				{ T = "Publicarlo sin su nombre: «El artista misterioso»", Effects = { Choice = { Reportaje = "Anonimo" }, Rel = { Vega = 10, Hugo = 3 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Hugo", T = "Un buen periodista también protege a sus fuentes. Lo he leído. Y ahora lo entiendo." },
				} },
				{ T = "Convencerla para pedir permiso al director y pintar a la luz del día", Effects = { Choice = { Reportaje = "Permiso" }, Rel = { Vega = 6, Hugo = 5 }, Traits = { Responsabilidad = 2 } }, Then = {
					{ S = "Vega", T = "¿Y si dice que no? …Vale. Si me acompañáis. Si dice que sí, el reportaje será mejor: «Una alumna pinta el instituto»." },
				} },
				{ T = "Publicar su nombre: la verdad es la verdad", Effects = { Choice = { Reportaje = "Nombre" }, Rel = { Vega = -8, Hugo = -2 }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Vega", T = "Genial. Gracias. De verdad, gracias por nada." },
					{ S = "Hugo", T = "…No sé si hemos hecho bien. A veces la verdad duele a alguien que no hacía daño." },
				} },
			} },
		}, Effects = { Flags = { "ClubTitular" } } },

		Fotografia = { Lines = {
			{ S = "Leire", T = "Regla del club: no se hacen fotos de uno mismo. Se hacen fotos de lo que ves. Mi abuelo decía que así se aprende a mirar." },
			{ S = "Leire", T = "Vamos al campus: la universidad, la biblioteca y el estadio. Algún día estudiaremos ahí. O no. Pero quiero verlo." },
		} },
		Foto_Uni = { Lines = {
			{ S = "Narrador", T = "La facultad, enorme, con gente con carpetas corriendo. Clic. Parece un sitio donde pasan cosas importantes." },
			{ S = "Leire", T = "Mi madre estudió aquí. Dice que fueron los mejores años. Y los más cansados." },
		} },
		Foto_Biblio = { Lines = { { S = "Narrador", T = "Una sala silenciosa llena de libros hasta el techo. Una estudiante dormida sobre un libro de anatomía. Clic. Leire se ríe bajito." } } },
		Foto_Estadio = { Lines = {
			{ S = "Narrador", T = "El estadio vacío al atardecer. Las gradas naranjas. Clic." },
			{ S = "Leire", T = "Esa es buena. Muy buena. …No se lo digas a nadie, pero eres mejor que yo encuadrando." },
		} },

		Dilema = { Lines = {
			{ S = "Nico", T = "¡{nombre}! El sábado es mi cumpleaños. Trece. En el parque, a las cinco. Hay tarta. Y mi abuela hace croquetas." },
			{ S = "Omar", T = "…Y el sábado a las cinco es el primer evento de tu club. Lo he mirado. Lo siento. Soy el mensajero de las malas noticias." },
			{ Ask = "¿Qué haces el sábado?", Options = {
				{ T = "El club: es mi primer compromiso de verdad", Effects = { Flags = { "SoloClub" }, Choice = { Sabado = "Club" }, Traits = { Responsabilidad = 1 }, Rel = { Nico = -4 } }, Then = {
					{ S = "Nico", T = "Ah. Vale. Lo entiendo. …Te guardo croquetas. Pocas." },
				} },
				{ T = "El cumpleaños de Nico: los amigos primero", Effects = { Flags = { "SoloCumple" }, Choice = { Sabado = "Cumple" }, Rel = { Nico = 8 } }, Then = {
					{ S = "Nico", T = "¡SÍ! Ya sabía yo. Te voy a dar la croqueta más grande." },
				} },
				{ T = "Intentar las dos cosas: el club y luego correr al parque", Effects = { Flags = { "IntentasLasDos" }, Choice = { Sabado = "Ambas" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Omar", T = "Ambicioso. Me gusta. Te dejo mi bono de autobús por si acaso." },
				} },
			} },
		} },
		EventoClub = { Lines = {
			{ S = "Narrador", T = "Primer partido del equipo de primero. Metes una canasta. Bueno, Álex dice que la mitad fue suya. Lo celebráis igual.", If = BALONCESTO },
			{ S = "Narrador", T = "El club de teatro hace una escena en el patio. Te toca decir: «¡Mi barco! ¡Mi precioso barco!». La gente se ríe. Rubén te choca la mano.", If = TEATRO },
			{ S = "Narrador", T = "Tornillo reparte su primer bocadillo. Solo uno. Luego se choca con una papelera. Pero el aplauso es enorme.", If = ROBOTICA },
			{ S = "Narrador", T = "Sale el primer número de «La Voz del Campus» con vuestro reportaje en portada. Hay gente leyéndolo en el patio. De verdad.", If = PERIODICO },
			{ S = "Narrador", T = "Leire y tú colgáis vuestras fotos en el pasillo. Una profesora se para delante de la del estadio más de un minuto.", If = FOTOGRAFIA },
			{ S = "Narrador", T = "Miras el reloj. Las cinco y cuarto. Hay que correr al parque.", If = { Flags = { "IntentasLasDos" } } },
		} },
		Cumple = { Lines = {
			{ S = "Nico", T = "¡{nombre}! ¡Has venido! ¡Justo a tiempo para la tarta!", If = { NotFlags = { "LlegasTardeCumple" } } },
			{ S = "Nico", T = "¡{nombre}! ¡Has llegado! Te hemos guardado la última porción de tarta. Omar ha tenido que defenderla con su vida.", If = { Flags = { "LlegasTardeCumple" } } },
			{ S = "Omar", T = "La he defendido con mi vida. Y con un tenedor." },
			{ S = "Leire", T = "Nico me invitó ayer. Es imposible decirle que no a Nico. Lo he intentado.", If = { Flags = { "ConocesALeire" } } },
			{ S = "Nico", T = "Trece años. Ya soy casi mayor. ¿Me veis más alto? Decid que sí." },
		}, Effects = { Rel = { Nico = 3 } } },
		TrasElClub = { Lines = {
			{ S = "Narrador", T = "Por la noche, Omar te manda una foto: Nico soplando las velas. Detrás, en una silla, un plato con croquetas y un papel: «Para {nombre}»." },
		} },
	},
}
