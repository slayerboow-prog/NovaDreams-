-- VIDA ADULTA 03 · «EL REENCUENTRO» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.40.
--
-- Lola se jubila y le deja la cafetería a Omar. Omar reabre «La Cafetería de Omar» y quiere a TODOS en la
-- inauguración → invitar al grupo por la ciudad (cada uno en su vida adulta: Nico futbolista, Sara
-- bióloga, Bruno policía, Leire cineasta, Hugo escritor, Mateo ingeniero) → visitar a Lucía, ahora
-- directora del colegio: ¿cumpliste tu sueño de niño? → ayudar a Omar en la cocina (minijuego) →
-- la inauguración, el discurso de Lola, la foto → por la noche, el banco del parque, como a los diez
-- años, y una promesa nueva. Cierra el capítulo «Volar del nido».

local V = Vector3.new

local CON_LEIRE = { Flags = { "ConocesALeire" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local function sueno(infancia: string, estudios: string): any
	return { Choices = { SuenoInfancia = infancia, Estudios = estudios }, Flags = { "Graduado" } }
end

local AMIGOS = {
	{ Npc = "Nico", Place = "EstadioAltamar", Offset = V(0, 0, 6) },
	{ Npc = "Sara", Place = "Universidad", Offset = V(3, 0, 5) },
	{ Npc = "Bruno", Place = "Policia", Offset = V(0, 0, 5) },
	{ Npc = "Leire", Place = "Ocio", Offset = V(0, 0, 5), If = CON_LEIRE },
	{ Npc = "Hugo", Place = "Biblioteca", Offset = V(3, 0, 3), If = CON_HUGO },
	{ Npc = "Mateo", Place = "OficinasFinanciero", Offset = V(0, 0, 5), If = AMIGO_MATEO },
}
local COCINA = {
	{ Npc = "Omar", Place = "CafeteriaCentral", Offset = V(0, 0, 4) },
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(4, 0, 5) },
}
local FIESTA = {
	{ Npc = "Omar", Place = "CafeteriaCentral", Offset = V(0, 0, 4) },
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(4, 0, 5) },
	{ Npc = "Nico", Place = "CafeteriaCentral", Offset = V(-4, 0, 3) },
	{ Npc = "Sara", Place = "CafeteriaCentral", Offset = V(-2, 0, 6) },
	{ Npc = "Bruno", Place = "CafeteriaCentral", Offset = V(6, 0, 1) },
	{ Npc = "Leire", Place = "CafeteriaCentral", Offset = V(-6, 0, 1), If = CON_LEIRE },
	{ Npc = "Hugo", Place = "CafeteriaCentral", Offset = V(2, 0, 7), If = CON_HUGO },
	{ Npc = "Mateo", Place = "CafeteriaCentral", Offset = V(-5, 0, 6), If = AMIGO_MATEO },
	{ Npc = "Lucia", Place = "CafeteriaCentral", Offset = V(7, 0, 5) },
	{ Npc = "Familia", Place = "CafeteriaCentral", Offset = V(-8, 0, -2) },
}
local BANCO = {
	{ Npc = "Omar", Place = "Parque", Offset = V(-2, 0, 4), Mode = "Sit" },
	{ Npc = "Nico", Place = "Parque", Offset = V(0, 0, 4), Mode = "Sit" },
	{ Npc = "Sara", Place = "Parque", Offset = V(2, 0, 4), Mode = "Sit" },
	{ Npc = "Leire", Place = "Parque", Offset = V(4, 0, 5), If = CON_LEIRE },
	{ Npc = "Mateo", Place = "Parque", Offset = V(-4, 0, 5), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "Parque", Offset = V(5, 0, 3), If = CON_HUGO },
}

return {
	Id = "Adu03_Reencuentro",
	Kind = "Main",
	Title = "El reencuentro",
	Description = "Lola se jubila y le deja la cafetería a Omar. Omar quiere a todo el grupo en la inauguración. A TODO el grupo.",
	Chapter = "Adulto_VolarDelNido",
	AgeRange = { 24, 25 },
	Duration = { 25, 35 },
	Difficulty = 1,
	Type = "Historia · Amistad",
	Requires = { Completed = { "Adu02_Atardecer" } },
	Npcs = { "Omar", "Lola", "Nico", "Sara", "Bruno", "Leire", "Hugo", "Mateo", "Lucia", "Familia" },
	Locations = { "CafeteriaCentral", "EstadioAltamar", "Universidad", "Policia", "Ocio", "Biblioteca", "OficinasFinanciero", "EntradaColegio", "Parque" },
	Outcomes = { "A quién invitas primero", "Lo que le cuentas a Lucía", "La promesa nueva del banco" },

	Moment = "El reencuentro del grupo",
	Memory = "ElReencuentro",
	Rewards = { Items = { FotoReencuentro = 1 } },

	Steps = {
		{ Type = "Transition", Text = "Unos meses después…", Seconds = 3 },
		{ Type = "Reach", Place = "CafeteriaCentral", Text = "Omar te ha escrito: «VEN YA. NOTICIÓN.»", Actors = COCINA },
		{ Type = "Scene", Dialogue = "Noticia", Actors = COCINA },

		-- Invitar al grupo
		{ Type = "Group", Text = "Invita al grupo a la inauguración (al menos tres)", Need = 3,
			Steps = {
				{ Type = "Talk", Npc = "Nico", Dialogue = "Nico", Text = "Nico (estadio de Altamar)" },
				{ Type = "Talk", Npc = "Sara", Dialogue = "Sara", Text = "Sara (universidad)" },
				{ Type = "Talk", Npc = "Bruno", Dialogue = "Bruno", Text = "Bruno (comisaría)" },
				{ Type = "Talk", Npc = "Leire", Dialogue = "Leire", Text = "Leire (el cine)", If = CON_LEIRE },
				{ Type = "Talk", Npc = "Hugo", Dialogue = "Hugo", Text = "Hugo (biblioteca del campus)", If = CON_HUGO },
				{ Type = "Talk", Npc = "Mateo", Dialogue = "Mateo", Text = "Mateo (oficinas del distrito financiero)", If = AMIGO_MATEO },
			},
			Actors = AMIGOS },

		-- Lucía
		{ Type = "Reach", Place = "EntradaColegio", Text = "Invita también a Lucía: ahora es la directora del colegio",
			Actors = { { Npc = "Lucia", Place = "EntradaColegio", Offset = V(0, 0, 5) } } },
		{ Type = "Talk", Npc = "Lucia", Dialogue = "Lucia", Text = "Habla con Lucía",
			Actors = { { Npc = "Lucia", Place = "EntradaColegio", Offset = V(0, 0, 5) } } },

		-- La cocina y la fiesta
		{ Type = "Reach", Place = "CafeteriaCentral", Text = "Vuelve a la cafetería: Omar necesita ayuda en la cocina", Actors = COCINA },
		{ Type = "MiniGame", Game = "Timing", Title = "La tortilla perfecta", Icon = "🍳", Hint = "Dale la vuelta en el momento justo",
			Rounds = 5, Need = 3, Zone = 0.25, Speed = 1,
			Win = { Flags = { "TortillaPerfecta" }, Rel = { Omar = 5 } }, Lose = { Traits = { Humor = 1 } }, Actors = COCINA },
		{ Type = "Scene", Dialogue = "Inauguracion", Actors = FIESTA },
		{ Type = "Cinematic", Id = "Adu03_Foto", Actors = FIESTA },

		-- El banco del parque
		{ Type = "Transition", Text = "Esa noche…", Seconds = 3 },
		{ Type = "Reach", Place = "Parque", Text = "Ve al banco del parque: el grupo te espera", Actors = BANCO },
		{ Type = "Scene", Dialogue = "Banco", Actors = BANCO },
	},

	Dialogues = {
		Noticia = { Lines = {
			{ S = "Lola", T = "Me jubilo. Cuarenta años detrás de esta barra. Ya está. Me voy a la playa a no hacer nada. Lo he decidido." },
			{ S = "Omar", T = "Y… me la deja a mí. ¡A MÍ! La cafetería. Se va a llamar «La Cafetería de Omar». Bueno, se llama igual, pero con mi nombre." },
			{ S = "Omar", T = "Reabro el sábado. Y quiero a todo el grupo. A TODO. Como en el colegio. Tú eres el encargado o la encargada de invitarles." },
			{ S = "Lola", T = "Ya era mío el mejor ayudante de verano. Ahora es mío el mejor sucesor. Qué bien lo he hecho todo.", If = { Choices = { Empleo = "Barista" } } },
		} },
		Nico = { Lines = {
			{ S = "Nico", T = "¡{nombre}! ¡Mira, uniforme del primer equipo! Firmé el mes pasado. Jugador de Altamar. Profesional. Todavía no me lo creo." },
			{ S = "Nico", T = "¿Omar abre la cafetería? ¡Voy! Llevo diez bocadillos de deuda con él desde el instituto. Es el momento de pagar." },
			{ S = "Nico", T = "Y oye… lo de tu predicción de la cápsula del tiempo. «Nico será futbolista». La tengo enmarcada.", If = { Choices = { Capsula = "Prediccion" } } },
		} },
		Sara = { Lines = {
			{ S = "Sara", T = "¡{nombre}! Tengo una noticia científica. He descubierto una especie nueva de hongo. Le han puesto mi nombre. «Mycena sarae». Es diminuto. Es precioso." },
			{ S = "Sara", T = "¿La inauguración de Omar? Iré. Llevaré a mi hongo. En un tarro. Es muy tranquilo." },
		} },
		Bruno = { Lines = {
			{ S = "Bruno", T = "Agente Bruno, para servirle. …Sí, soy policía. Inés me enseñó todo. Me paso el día ayudando a gente mayor a cruzar y buscando gatos." },
			{ S = "Bruno", T = "Hace un tiempo te puse las esposas. Y hoy me invitas a una fiesta. La vida es muy rara. Me alegro de que sea así.", If = { Flags = { "Detenido" } } },
			{ S = "Bruno", T = "¿Me invitas tú? ¿Después de todo lo del colegio? …Vale. Iré. Gracias. De verdad.", If = { NotChoices = { AdiosBruno = "DeCero" } } },
			{ S = "Bruno", T = "¿Una fiesta del grupo? Claro que voy. Empezamos de cero, ¿no? Pues esto es el diez.", If = { Choices = { AdiosBruno = "DeCero" } } },
		} },
		Leire = { Lines = {
			{ S = "Leire", T = "Estreno mi primer documental el mes que viene. Es sobre Valmar. Salís todos. Sin permiso. Lo siento. Bueno, no lo siento." },
			{ S = "Leire", T = "¿La cafetería de Omar? Allí estaré. Con la cámara de mi abuelo. Como siempre." },
		} },
		Hugo = { Lines = {
			{ S = "Hugo", T = "Mira: mi primera novela. «La isla de las mil llaves: la venganza». Es de piratas. Obviamente. Te la dedico en la primera página." },
			{ S = "Hugo", T = "«Para quien encontró mi libro en un almacén y me sacó de donde no quería estar.» …Ya. Me emociono yo solo." },
		} },
		Mateo = { Lines = {
			{ S = "Mateo", T = "Ingeniero en TecnoVal. Estoy en el proyecto de la pasarela del río. ¿Tu idea de los amortiguadores? Funciona. Ya no vibra.", If = { Choices = { Estudios = "Ingenieria" } } },
			{ S = "Mateo", T = "Ingeniero en TecnoVal. Diseño puentes. Mi padre dice que soy el fontanero más caro de la historia.", If = { NotChoices = { Estudios = "Ingenieria" } } },
			{ S = "Mateo", T = "La fiesta de Omar… Claro que voy. Aquel primer día me ayudaste con los libros. Todo empezó ahí." },
		} },
		Lucia = { Lines = {
			{ S = "Lucia", T = "¡{nombre}! Ahora soy la directora. Sí, la de las coletas. Tengo despacho y todo. Y la foto de 1998 en la pared." },
			{ S = "Lucia", T = "Cuéntame: ¿qué ha sido de tu vida?" },
			{ S = "Narrador", T = "Le cuentas que querías salvar vidas… y que ahora trabajas en el hospital. Lucía se queda callada un momento.", If = sueno("Medicina", "Medicina") },
			{ S = "Narrador", T = "Le cuentas que querías inventar cosas que no existen… y que ahora las diseñas en TecnoVal. Lucía sonríe.", If = sueno("Ingenieria", "Ingenieria") },
			{ S = "Narrador", T = "Le cuentas que querías defender a quien no puede defenderse… y que ahora eres abogado o abogada.", If = sueno("Derecho", "Derecho") },
			{ S = "Narrador", T = "Le cuentas que querías tener tu propio negocio… y que ahora ayudas a otros a abrir el suyo.", If = sueno("Economia", "Economia") },
			{ S = "Lucia", T = "Lo dijiste a los diez años en un banco del parque. Y lo has cumplido. Eso, {nombre}, es lo más bonito que puede oír una profesora.", If = { Flags = { "Graduado" } } },
			{ S = "Lucia", T = "Lo importante no es si se cumple lo que dijiste de pequeño. Es si eres feliz con lo que has hecho. Y se te ve feliz." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Gracias por aquel primer día. Y por todos los demás.»", Effects = { Rel = { Lucia = 10 } }, Then = {
					{ S = "Lucia", T = "Venga, que me haces llorar en la puerta del colegio. Y aquí me ven los alumnos." },
				} },
				{ T = "«¿Puedo venir a contarle a tus alumnos lo que hago?»", Effects = { Rel = { Lucia = 8 }, Flags = { "CharlaColegio" } }, Then = {
					{ S = "Lucia", T = "¡Me encantaría! El día de las profesiones. Como el que tuviste tú en el instituto, pero con niños que preguntan «¿y por qué?» cada minuto." },
				} },
			} },
			{ S = "Lucia", T = "¿Y la fiesta de Omar? Claro que voy. Ese niño se comía mi bocadillo de la mesa cuando no miraba." },
		} },
		Inauguracion = { Lines = {
			{ S = "Narrador", T = "La cafetería está llena. Todos. Como en el patio del colegio, pero más altos." },
			{ S = "Lola", T = "Unas palabras, que me lo ha pedido Omar. Cuarenta años aquí. He visto crecer a medio Valmar. Y a este grupo, entero." },
			{ S = "Lola", T = "Omar: cuida la cafetería. Y cuida a esta gente. Que la gente es lo único que no se puede comprar con la caja registradora." },
			{ S = "Omar", T = "La tortilla de hoy la ha hecho {nombre}. Perfecta. Bueno, casi. Perfecta según mis estándares, que son altísimos.", If = { Flags = { "TortillaPerfecta" } } },
			{ S = "Omar", T = "La tortilla de hoy la ha hecho {nombre}. Se le ha roto un poco. Nadie lo va a notar. Todos lo vais a notar.", If = { NotFlags = { "TortillaPerfecta" } } },
			{ S = "Omar", T = "Y yo quiero decir… que sin vosotros no habría abierto nada. Ni la cafetería ni el bocadillo del primer día. Gracias. Ya está. No lloro. Es la cebolla." },
			{ S = "Sara", T = "Técnicamente, hoy no hay cebolla en el menú." },
		} },
		Banco = { Lines = {
			{ S = "Narrador", T = "El banco del parque. El mismo. Os sentáis como a los diez años, apretados. Ahora ya no cabéis." },
			{ S = "Nico", T = "Prometimos quedar aquí cada verano. Y lo hemos cumplido. Casi siempre. Vale, algunos veranos no.", If = { Choices = { Promesa = "Banco" } } },
			{ S = "Omar", T = "Prometimos seguir juntos pasara lo que pasara. Y aquí estamos. Con trabajos, con casas… y juntos.", If = { Choices = { Promesa = "Juntos" } } },
			{ S = "Sara", T = "Prometimos conocer gente nueva sin olvidarnos. Técnicamente, lo hemos cumplido al cien por cien.", If = { Choices = { Promesa = "Nuevos" } } },
			{ S = "Narrador", T = "Nico pregunta: «¿Os acordáis del nombre del grupo?». Y todos lo decís a la vez: «{grupo}». Os reís como tontos.", If = { Memories = { "PrimerGrupo" } } },
			{ Ask = "¿Qué promesa nueva hacéis?", Options = {
				{ T = "«Cuando tengamos hijos, que sean amigos como nosotros.»", Effects = { Choice = { PromesaAdulta = "Hijos" } }, Then = {
					{ S = "Omar", T = "Y que se sienten en este banco. Y que tampoco quepan." },
				} },
				{ T = "«Un viaje juntos, todos, antes de los treinta.»", Effects = { Choice = { PromesaAdulta = "Viaje" } }, Then = {
					{ S = "Sara", T = "Propongo Villaverde. La granja. Donde se perdió Mateo. Por nostalgia científica." },
				} },
				{ T = "«Nada de promesas: esto ya es para siempre.»", Effects = { Choice = { PromesaAdulta = "Siempre" }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Nico", T = "…Eso ha sido muy bonito. Que nadie diga nada. Que nadie diga NADA." },
				} },
			} },
			{ S = "Narrador", T = "Os quedáis hasta tarde. Hablando de todo y de nada. Como siempre. Como nunca." },
		} },
	},
}
