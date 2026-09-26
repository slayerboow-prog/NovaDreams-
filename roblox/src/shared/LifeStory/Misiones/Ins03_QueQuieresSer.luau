-- INSTITUTO 03 · «¿QUÉ QUIERES SER?» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.26.
--
-- La semana de las profesiones: Carmen, la orientadora, os manda a visitar al menos cuatro sitios de
-- ocho (hospital, taller, comisaría, empresa, restaurante, laboratorio de la facultad, estadio, estudio
-- audiovisual). En cada uno haces algo de verdad y decides si te ves ahí (marca Interes_*). Si tu sueño
-- de la infancia está entre ellos, lo recuerdas. No hay que elegir nada: se trata de descubrir.

local V = Vector3.new

local function sueno(value: string): any
	return { Choices = { SuenoInfancia = value } }
end

-- Al final de cada visita: ¿te ves haciendo esto?
local function teVes(flag: string, who: string, yes: string, no: string): any
	return { Ask = "¿Te ves trabajando en esto?", Options = {
		{ T = "Sí. Me lo imagino perfectamente.", Effects = { Flags = { flag } }, Then = {
			{ S = who, T = yes },
		} },
		{ T = "Es interesante, pero no es lo mío.", Then = {
			{ S = who, T = no },
		} },
	} }
end

local PROFESIONALES = {
	{ Npc = "Nuria", Place = "Hospital", Offset = V(0, 0, 4) },
	{ Npc = "Tomas", Place = "Gasolinera", Offset = V(0, 0, 4) },
	{ Npc = "Ines", Place = "Policia", Offset = V(0, 0, 4) },
	{ Npc = "Marcos", Place = "OficinasFinanciero", Offset = V(0, 0, 4) },
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 4) },
	{ Npc = "Sofia", Place = "FacultadIngenieria", Offset = V(0, 0, 4) },
	{ Npc = "Irene", Place = "EstadioUniversitario", Offset = V(0, 0, 4) },
	{ Npc = "Toni", Place = "Ocio", Offset = V(0, 0, 4) },
}

local CLASE = {
	{ Npc = "Carmen", Place = "AulaInstituto", Offset = V(0, 0, -6) },
	{ Npc = "Javier", Place = "AulaInstituto", Offset = V(4, 0, -6) },
	{ Npc = "Omar", Place = "AulaInstituto", Offset = V(3, 0, 0) },
	{ Npc = "Leire", Place = "AulaInstituto", Offset = V(6, 0, 3), If = { Flags = { "ConocesALeire" } } },
	{ Npc = "Bruno", Place = "AulaInstituto", Offset = V(-6, 0, -1) },
	{ Npc = "Nico", Place = "AulaInstituto", Offset = V(-4, 0, 2) },
}

return {
	Id = "Ins03_QueQuieresSer",
	Kind = "Main",
	Title = "¿Qué quieres ser?",
	Description = "La semana de las profesiones. Ocho sitios, ocho trabajos… y ninguna obligación de elegir. Solo de descubrir.",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 13, 14 },
	Duration = { 25, 35 },
	Difficulty = 2,
	Type = "Historia · Orientación",
	Requires = { Completed = { "Ins02_Clubes" }, StageProgress = 0.25 },
	Npcs = { "Carmen", "Javier", "Omar", "Leire", "Bruno", "Nico", "Nuria", "Tomas", "Ines", "Marcos", "Lola", "Sofia", "Irene", "Toni" },
	Locations = { "AulaInstituto", "Hospital", "Gasolinera", "Policia", "OficinasFinanciero", "CafeteriaCentral", "FacultadIngenieria", "EstadioUniversitario", "Ocio" },
	Next = { "Pan1_MalasCompanias" },
	Outcomes = { "Qué sitios visitas (4 de 8)", "Qué te interesa (marcas Interes_*)", "Cómo sales de la orientación" },

	Moment = "La semana de las profesiones",
	Memory = "QueQuieresSer",
	Rewards = { Items = { CuadernoProfesiones = 1 } },

	Steps = {
		{ Type = "Transition", Text = "Antes de las vacaciones de invierno…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaInstituto", Text = "Ve a clase: hoy viene la orientadora", Actors = CLASE },
		{ Type = "Scene", Dialogue = "Carmen", Actors = CLASE },
		{ Type = "Group", Text = "Visita al menos cuatro profesiones (en cualquier orden)", Need = 4,
			Steps = {
				{ Type = "Talk", Npc = "Nuria", Dialogue = "Hospital", Text = "Medicina: el hospital" },
				{ Type = "Talk", Npc = "Sofia", Dialogue = "Laboratorio", Text = "Ingeniería: el laboratorio de la facultad" },
				{ Type = "Talk", Npc = "Ines", Dialogue = "Comisaria", Text = "Policía y leyes: la comisaría" },
				{ Type = "Talk", Npc = "Marcos", Dialogue = "Empresa", Text = "Empresa: las oficinas del distrito financiero" },
				{ Type = "Talk", Npc = "Tomas", Dialogue = "Taller", Text = "Mecánica: el taller de la gasolinera" },
				{ Type = "Talk", Npc = "Lola", Dialogue = "Restaurante", Text = "Cocina: la cafetería del centro" },
				{ Type = "Talk", Npc = "Irene", Dialogue = "Estadio", Text = "Deporte: el estadio universitario" },
				{ Type = "Talk", Npc = "Toni", Dialogue = "Estudio", Text = "Audiovisual: el cine" },
			},
			Actors = PROFESIONALES },
		{ Type = "Reach", Place = "AulaInstituto", Text = "Vuelve al instituto: Carmen quiere saber qué has descubierto", Actors = CLASE },
		{ Type = "Scene", Dialogue = "Reflexion", Actors = CLASE },
	},

	Dialogues = {
		Carmen = { Lines = {
			{ S = "Carmen", T = "Hola, 1.º C. Soy Carmen, la orientadora. Esta semana no hay clase normal: es la semana de las profesiones." },
			{ S = "Carmen", T = "Hay ocho sitios de Valmar que os abren las puertas. Visitad al menos cuatro. Preguntad, probad, meted las manos." },
			{ S = "Carmen", T = "Y una cosa importante: nadie tiene que decidir su futuro esta semana. Ni este año. Solo mirar. Mirar mucho." },
			{ S = "Bruno", T = "¿Y si ya sé lo que quiero ser?" },
			{ S = "Carmen", T = "Entonces visita también algo que no tenga nada que ver. A veces uno se sorprende." },
			{ S = "Omar", T = "Yo voy a visitar el restaurante primero. Por investigación. Y por la hora que es." },
		} },

		Hospital = { Lines = {
			{ S = "Nuria", T = "¡Bienvenida la cantera! Soy Nuria, médica de urgencias. Aquí nunca sabes qué va a entrar por esa puerta." },
			{ S = "Narrador", T = "✨ Cuando tenías diez años, en un banco del parque, dijiste que querías salvar vidas. Aquí se hace cada día.", If = sueno("Medicina") },
			{ S = "Nuria", T = "Llega un niño con el brazo hinchado. Se ha caído de la bici. Está asustado. Tú eres parte del equipo." },
			{ Ask = "¿Qué haces primero?", Options = {
				{ T = "Tranquilizarle: le preguntas su nombre y le hablas", Effects = { Traits = { Empatia = 1 } }, Then = {
					{ S = "Nuria", T = "Exacto. Un paciente tranquilo se deja ayudar. La mitad de la medicina es hablar bien." },
				} },
				{ T = "Mirar el brazo con cuidado sin moverlo", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Nuria", T = "Bien: no mover, observar, avisar. Luego una radiografía. Tienes buen instinto." },
				} },
			} },
			{ S = "Nuria", T = "Es duro: turnos de noche, días malos. Pero cuando alguien sale por la puerta andando… no hay nada igual." },
			teVes("Interes_Medicina", "Nuria", "Entonces estudia mucha biología. Y aprende a dormir en cualquier sitio. Te hará falta.", "Muy bien. Saber lo que no quieres también es saber mucho."),
		} },
		Laboratorio = { Lines = {
			{ S = "Sofia", T = "¡Pasa, pasa! Esto es el laboratorio de ingeniería. Aquí se rompen cosas… para que luego no se rompan." },
			{ S = "Narrador", T = "✨ De pequeño o pequeña querías «inventar cosas que no existen». Este sitio huele a eso.", If = sueno("Ingenieria") },
			{ S = "Sofia", T = "Este puente de palillos tiene que aguantar dos kilos. Ahora mismo aguanta… uno y medio. ¿Qué harías tú?" },
			{ Ask = "¿Cómo lo arreglas?", Options = {
				{ T = "Añadir triángulos: son más fuertes", Effects = { Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Sofia", T = "¡Triángulos! ¿Quién te lo ha contado? Los puentes de verdad están llenos. Aguanta dos kilos y medio. Récord del día." },
				} },
				{ T = "Probar, romper y volver a probar", Effects = { Traits = { Valentia = 1 } }, Then = {
					{ S = "Sofia", T = "El método de los ingenieros de verdad. Tres puentes rotos después: aguanta dos kilos. ¡Bien!" },
				} },
			} },
			{ S = "Sara", T = "(Sara aparece por la puerta) ¡Sabía que acabarías aquí! Yo vengo todas las semanas. Sofía ya me conoce.", If = { Choices = { Club = "Robotica" } } },
			teVes("Interes_Ingenieria", "Sofia", "Pues en unos años nos vemos por aquí. Te guardo una bata.", "Vale. Pero si un día te aburres, aquí siempre hay algo roto."),
		} },
		Comisaria = { Lines = {
			{ S = "Ines", T = "Hola. Soy Inés, agente de barrio. Mucha gente cree que esto es persecuciones. Casi todo es escuchar y ayudar." },
			{ S = "Narrador", T = "✨ En el parque dijiste que querías defender a quien no puede defenderse. Esto también es eso.", If = sueno("Derecho") },
			{ S = "Ines", T = "Viene una señora: dice que el vecino le ha robado la maceta. El vecino dice que la maceta es suya. ¿Qué haces?" },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Escuchar a los dos antes de decidir nada", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Ines", T = "Eso es. Al final la maceta era de los dos: la compraron juntos hace veinte años. Se habían olvidado." },
				} },
				{ T = "Buscar pruebas: tiques, fotos, testigos", Effects = { Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Ines", T = "Muy bien. Una foto de hace años lo aclara: la compraron a medias. Se ríen. Caso cerrado." },
				} },
			} },
			{ S = "Ines", T = "Si te gusta esto, también está el derecho: abogados, jueces, gente que se estudia las leyes para que sean justas." },
			teVes("Interes_Derecho", "Ines", "Te veo con toga o con placa. Cualquiera de las dos te queda bien.", "Perfecto. Lo importante es que ahora sabes que esto existe."),
		} },
		Empresa = { Lines = {
			{ S = "Marcos", T = "¡Hola, hola, pasa! Soy Marcos. Tengo una empresa de bicicletas. Bueno, la empresa me tiene a mí." },
			{ S = "Narrador", T = "✨ En el parque dijiste que querías tener tu propio negocio. Aquí tienes uno de verdad.", If = sueno("Economia") },
			{ S = "Marcos", T = "Problema real: nos sobran cien bicis rojas y nadie las compra. ¿Qué harías?" },
			{ Ask = "¿Tu idea?", Options = {
				{ T = "Alquilarlas por horas a turistas en la playa", Effects = { Traits = { Creatividad = 1 } }, Then = {
					{ S = "Marcos", T = "¡Anda! Eso no lo habíamos pensado. Lo apunto. Si funciona, te pago en helados." },
				} },
				{ T = "Preguntar a la gente por qué no las compra", Effects = { Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Marcos", T = "La pregunta más importante de cualquier negocio. Resulta que… el rojo no gusta. Las pintaremos de azul." },
				} },
			} },
			teVes("Interes_Economia", "Marcos", "Estudia números y aprende a escuchar. Con eso se montan las mejores empresas.", "Normal. Esto no es para todo el mundo. Yo tampoco sabía que era para mí."),
		} },
		Taller = { Lines = {
			{ S = "Tomas", T = "Pasa, que no muerdo. El coche sí, si le metes la mano donde no es. Soy Tomás. Cuarenta años arreglando motores." },
			{ S = "Tomas", T = "Este no arranca. Escucha: ¿oyes ese clic-clic? ¿Qué crees que es?" },
			{ Ask = "¿Qué crees?", Options = {
				{ T = "La batería", Effects = { Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Tomas", T = "¡La batería! Tienes oído. Muchos adultos no lo saben. Cambiamos y… ¡brum! Arrancado." },
				} },
				{ T = "No tengo ni idea, pero quiero verlo", Effects = { Traits = { Humor = 1 } }, Then = {
					{ S = "Tomas", T = "Esa es la mejor respuesta que me han dado nunca. Era la batería. Ahora ya lo sabes." },
				} },
			} },
			{ S = "Tomas", T = "Aquí no hace falta universidad. Hace falta paciencia, manos y ganas de aprender toda la vida." },
			teVes("Interes_Oficio", "Tomas", "Pues cuando quieras, vente un verano. Te enseño lo que sé. Que es bastante.", "Bien. Pero si algún día se te estropea la bici, ya sabes dónde estoy."),
		} },
		Restaurante = { Lines = {
			{ S = "Lola", T = "¡Delantal y manos limpias! Soy Lola. En mi cocina se grita, se corre… y se hace la mejor tortilla de Valmar." },
			{ S = "Omar", T = "(Omar ya está aquí, con delantal) He llegado primero. Era una cuestión de prioridades." },
			{ S = "Lola", T = "Hay cuatro mesas esperando y solo hay tiempo para una cosa. ¿Qué haces?" },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Organizar: primero lo que tarda más", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Lola", T = "¡Cabeza de chef! Así se sale de un lío. Las cuatro mesas, servidas." },
				} },
				{ T = "Pedir ayuda a Omar: en equipo, más rápido", Effects = { Traits = { Empatia = 1 }, Rel = { Omar = 3 } }, Then = {
					{ S = "Lola", T = "Una cocina es un equipo o no es nada. Muy bien. Y tu amigo pela patatas como un campeón." },
				} },
			} },
			teVes("Interes_Cocina", "Lola", "Pues aprende a cocinar para tu familia. Ese es el primer restaurante de todo el mundo.", "No pasa nada. Pero la tortilla, llévatela. Eso sí es obligatorio."),
		} },
		Estadio = { Lines = {
			{ S = "Irene", T = "¡Al trote! Soy Irene: entrenadora y fisioterapeuta. Aquí se trabaja con el cuerpo y con la cabeza." },
			{ S = "Narrador", T = "✨ En el parque dijiste que querías ser deportista. Aquí entrenan quienes lo consiguen… y quienes les ayudan.", If = sueno("Deporte") },
			{ S = "Irene", T = "Una atleta se ha torcido el tobillo. Quiere seguir corriendo la final. ¿Qué le dices?" },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Hoy no. Si corres, te lesionas un año.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Irene", T = "Duro, pero correcto. Cuidar a alguien a veces es decirle que no." },
				} },
				{ T = "«Vamos a ponerle hielo y luego decidimos.»", Effects = { Traits = { Empatia = 1 } }, Then = {
					{ S = "Irene", T = "Muy bien: primero cuidar, luego decidir. Al final no pudo correr, pero te lo agradeció." },
				} },
			} },
			{ S = "Irene", T = "Tu medalla del torneo del colegio… ¡qué recuerdo! Yo empecé igual.", If = { Memories = { "PrimerTorneo" } } },
			teVes("Interes_Deporte", "Irene", "Entrena, estudia y cuida tu cuerpo. Y ven a verme cuando quieras.", "Vale. Pero sigue moviéndote. El cuerpo lo agradece toda la vida."),
		} },
		Estudio = { Lines = {
			{ S = "Toni", T = "¡Hola! Soy Toni, el tío de Leire. Hacemos documentales. Hoy grabamos una entrevista en la sala del cine." },
			{ S = "Narrador", T = "✨ De pequeño o pequeña querías pintar cosas que la gente no olvidara. Aquí se pinta con luz.", If = sueno("Arte") },
			{ S = "Toni", T = "Tú eres la cámara. ¿Dónde pones al entrevistado?" },
			{ Ask = "¿Dónde le pones?", Options = {
				{ T = "Junto a la ventana, con luz natural", Effects = { Traits = { Creatividad = 1 } }, Then = {
					{ S = "Toni", T = "¡Primer plano, luz de ventana! Eso es lo que haría yo. Queda precioso." },
				} },
				{ T = "Delante de las butacas vacías: cuenta una historia", Effects = { Traits = { Creatividad = 1 } }, Then = {
					{ S = "Toni", T = "Un plano que cuenta algo por sí solo. Eso no se enseña: se tiene." },
				} },
			} },
			{ S = "Leire", T = "Te lo dije: mi tío habla en planos. Ya lo has comprobado.", If = { Flags = { "ConocesALeire" } } },
			teVes("Interes_Audiovisual", "Toni", "Pues coge una cámara, aunque sea la del móvil, y no pares de mirar.", "Me parece bien. Pero ahora ya ves las películas de otra forma. No hay vuelta atrás."),
		} },

		Reflexion = { Lines = {
			{ S = "Carmen", T = "Bueno, {nombre}. ¿Qué has descubierto esta semana?" },
			{ S = "Carmen", T = "Veo que el hospital te ha removido algo.", If = { Flags = { "Interes_Medicina" } } },
			{ S = "Carmen", T = "Sofía me ha dicho que tus puentes aguantan más que los suyos. Eso no lo dice nunca.", If = { Flags = { "Interes_Ingenieria" } } },
			{ S = "Carmen", T = "Inés dice que escuchas a las dos partes. Eso vale para la policía y para el derecho.", If = { Flags = { "Interes_Derecho" } } },
			{ S = "Carmen", T = "Marcos va a pintar las bicis de azul. Por tu culpa. Está encantado.", If = { Flags = { "Interes_Economia" } } },
			{ S = "Carmen", T = "Tomás pregunta si vas a volver al taller. Eso con Tomás es casi una oferta de trabajo.", If = { Flags = { "Interes_Oficio" } } },
			{ S = "Carmen", T = "Lola dice que tienes cabeza de cocina. No sé qué significa, pero suena a piropo.", If = { Flags = { "Interes_Cocina" } } },
			{ S = "Carmen", T = "Irene te ha visto cuidar a alguien antes que a una medalla. Eso es saber entrenar.", If = { Flags = { "Interes_Deporte" } } },
			{ S = "Carmen", T = "Toni ya te llama «la cámara». Viniendo de él, es un título.", If = { Flags = { "Interes_Audiovisual" } } },
			{ Ask = "¿Cómo te sientes con tu futuro?", Options = {
				{ T = "Creo que ya sé lo que me gusta", Effects = { Choice = { Orientacion = "Claro" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Carmen", T = "Qué bien. Aun así, déjate sorprender. Las mejores decisiones se toman sabiendo qué más había." },
				} },
				{ T = "Tengo más dudas que antes", Effects = { Choice = { Orientacion = "Dudas" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Carmen", T = "Eso es buena señal. Significa que has mirado de verdad. Las dudas son el principio de cualquier decisión buena." },
				} },
				{ T = "Me gustan muchas cosas a la vez", Effects = { Choice = { Orientacion = "Muchas" }, Traits = { Creatividad = 1 } }, Then = {
					{ S = "Carmen", T = "A mí también me pasaba. Y mírame: orientadora. Que es un poco de todo. Tranquilidad: hay tiempo." },
				} },
			} },
			{ S = "Omar", T = "Yo tengo clarísimo que quiero trabajar con Lola. O comer donde trabaje Lola. Una de las dos." },
			{ S = "Carmen", T = "Os doy un cuaderno para apuntar lo que habéis visto. Dentro de unos años lo leeréis y os reiréis. O no. Guardadlo." },
		} },
	},
}
