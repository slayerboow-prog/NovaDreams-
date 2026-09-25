-- MISIÓN 09 · «EL MISTERIO DEL COLEGIO» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.19.
--
-- Rumores en el recreo → una nota vieja en tu taquilla: «NO ENTRES» → cuatro pistas (el anuario de
-- 1998 en la biblioteca, el tablero de llaves de Ramón, el trofeo viejo del almacén, la puerta) →
-- pedir permiso a Ramón o colarte en el recreo → el candado (año + llave; si fallas, piensas otra
-- vez) → dentro: pupitres viejos, una caja olvidada… y la foto de la clase de 1998 con una niña de
-- jersey amarillo → hablar con Lucía → la cápsula del tiempo de tu clase (se abrirá el último día).

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }
local PERMISO = { Choices = { Entrar = "Permiso" } }
local COLARSE = { Choices = { Entrar = "Colarse" } }

local RECREO = {
	{ Npc = "Nico", Place = "Patio", Offset = V(-3, 0, 2) },
	{ Npc = "Sara", Place = "Patio", Offset = V(3, 0, 2) },
	{ Npc = "Omar", Place = "Patio", Offset = V(0, 0, 5) },
	{ Npc = "Iker", Place = "Patio", Offset = V(6, 0, 4), If = CON_IKER },
	{ Npc = "Mateo", Place = "Patio", Offset = V(-6, 0, 4), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "Patio", Offset = V(-5, 0, -1), If = CON_HUGO },
}

-- Investigando: tus amigos te siguen; Marisa y Ramón, en su sitio
local AMIGOS = {
	{ Npc = "Sara", Mode = "Follow" },
	{ Npc = "Omar", Mode = "Follow" },
	{ Npc = "Iker", Mode = "Follow", If = CON_IKER },
}
local PISTAS = {
	{ Npc = "Marisa", Place = "SpotBibliotecaria" },
	{ Npc = "Ramon", Place = "Conserjeria", Offset = V(-2, 0, 0) },
	{ Npc = "Sara", Mode = "Follow" },
	{ Npc = "Omar", Mode = "Follow" },
	{ Npc = "Iker", Mode = "Follow", If = CON_IKER },
}

local PUERTA = {
	{ Npc = "Sara", Place = "SalaCerradaPuerta", Offset = V(-3, 0, 3) },
	{ Npc = "Omar", Place = "SalaCerradaPuerta", Offset = V(3, 0, 3) },
	{ Npc = "Nico", Place = "SalaCerradaPuerta", Offset = V(0, 0, 5) },
	{ Npc = "Iker", Place = "SalaCerradaPuerta", Offset = V(5, 0, 5), If = CON_IKER },
	{ Npc = "Ramon", Place = "SalaCerradaPuerta", Offset = V(-5, 0, 5), If = PERMISO },
}
local DENTRO = {
	{ Npc = "Sara", Place = "SalaCerrada", Offset = V(-3, 0, 2) },
	{ Npc = "Omar", Place = "SalaCerrada", Offset = V(3, 0, 2) },
	{ Npc = "Nico", Place = "SalaCerrada", Offset = V(0, 0, 4) },
	{ Npc = "Iker", Place = "SalaCerrada", Offset = V(5, 0, 4), If = CON_IKER },
	{ Npc = "Ramon", Place = "SalaCerrada", Offset = V(-5, 0, 5), If = PERMISO },
}
-- Si te colaste, Ramón aparece en la puerta cuando encontráis la foto
local DENTRO_FOTO = {
	DENTRO[1], DENTRO[2], DENTRO[3], DENTRO[4],
	{ Npc = "Ramon", Place = "SalaCerrada", Offset = V(-5, 0, 5) },
}
local CLASE = {
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	{ Npc = "Sara", Place = "AulaA", Offset = V(-2, 0, -3) },
	{ Npc = "Omar", Place = "AulaA", Offset = V(3, 0, -2) },
	{ Npc = "Nico", Place = "AulaA", Offset = V(4, 0, 3) },
	{ Npc = "Iker", Place = "AulaA", Offset = V(-4, 0, 2), If = CON_IKER },
}

return {
	Id = "Cole09_Misterio",
	Kind = "Main",
	Title = "El misterio del colegio",
	Description = "Al fondo del pasillo hay una puerta que nunca se abre. Y en tu taquilla, una nota: «NO ENTRES».",
	Chapter = "Nino_ElColegio",
	AgeRange = { 9, 9 },
	Duration = { 25, 35 },
	Difficulty = 3,
	Type = "Historia · Misterio",
	Requires = { Completed = { "Cole08_Torneo" }, StageProgress = 0.62 },
	Npcs = { "Nico", "Sara", "Omar", "Iker", "Mateo", "Hugo", "Marisa", "Ramon", "Lucia" },
	Locations = { "Patio", "TaquillaColegio", "BibliotecaColegio", "Conserjeria", "AlmacenColegio", "SalaCerradaPuerta", "SalaCerrada", "AulaA" },
	Next = { "Cole10_Festival" },
	Outcomes = { "Permiso o a escondidas", "Devolver la foto, enseñarla o guardar el secreto", "Qué metes en la cápsula" },

	Moment = "El secreto de la sala cerrada",
	Memory = "MisterioColegio",
	Rewards = { Items = { FotoLucia = 1 } },

	Props = {
		Nota = { Kind = "Papel", Name = "Tu taquilla", Prompt = "Abrir la taquilla", Place = "TaquillaColegio", Dialogue = "Nota", Once = true },
		Anuario = { Kind = "Libro", Name = "El anuario de 1998", Prompt = "Hojear", Place = "BibliotecaColegio", Offset = V(5, 0, -3), Color = Color3.fromRGB(150, 40, 40), Dialogue = "Pista_Anuario", Once = true },
		Llaves = { Kind = "Marcador", Name = "El tablero de llaves", Prompt = "Mirar las llaves", Place = "Conserjeria", Offset = V(2, 0, -1), Dialogue = "Pista_Llaves", Once = true },
		TrofeoViejo = { Kind = "Trofeo", Name = "Un trofeo viejo", Prompt = "Limpiar el polvo", Place = "AlmacenColegio", Offset = V(-3, 0, 2), Dialogue = "Pista_Trofeo", Once = true },
		Puerta = { Kind = "Marcador", Name = "La puerta del fondo", Prompt = "Mirar la puerta", Place = "SalaCerradaPuerta", Dialogue = "Pista_Puerta", Once = true },
		Colarse = { Kind = "Marcador", Name = "La puerta del fondo", Prompt = "Colarte en el recreo", Place = "SalaCerradaPuerta", Offset = V(0, 0, 1) },
		Pupitre = { Kind = "Asiento", Name = "Un pupitre viejo", Prompt = "Mirar el pupitre", Place = "SalaCerrada", Offset = V(-4, 0, -2), Dialogue = "Dentro_Pupitre", Once = true },
		Caja = { Kind = "Caja", Name = "Una caja de lata", Prompt = "Abrir la caja", Place = "SalaCerrada", Offset = V(4, 0, -2), Color = Color3.fromRGB(200, 170, 60), Dialogue = "Dentro_Caja", Once = true },
		Estanteria = { Kind = "Trofeo", Name = "Trofeos y medallas", Prompt = "Mirar los trofeos", Place = "SalaCerrada", Offset = V(6, 0, 1), Dialogue = "Dentro_Trofeos", Once = true },
		Foto = { Kind = "Papel", Name = "Una foto enmarcada", Prompt = "Mirar la foto", Place = "SalaCerrada", Offset = V(0, 0, -5), Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Unos días después del torneo…", Seconds = 3 },
		{ Type = "Reach", Place = "Patio", Text = "Sal al recreo: tus amigos no hablan de otra cosa", Actors = RECREO },
		{ Type = "Scene", Dialogue = "Rumores", Actors = RECREO },
		{ Type = "Use", Prop = "Nota", Text = "Vuelve a tu taquilla (en el pasillo) a por el almuerzo", Actors = AMIGOS },
		{ Type = "Scene", Dialogue = "TrasNota", Actors = AMIGOS },

		-- Cuatro pistas, en el orden que quieras
		{ Type = "Group", Text = "Investiga el misterio",
			Steps = {
				{ Type = "Use", Prop = "Anuario", Text = "El anuario viejo de la biblioteca" },
				{ Type = "Use", Prop = "Llaves", Text = "El tablero de llaves de la conserjería" },
				{ Type = "Use", Prop = "TrofeoViejo", Text = "Algo brilla en el almacén del gimnasio" },
				{ Type = "Use", Prop = "Puerta", Text = "La puerta del fondo del pasillo" },
			},
			Actors = PISTAS },
		{ Type = "Scene", Dialogue = "Codigo", Actors = AMIGOS },

		-- ¿Permiso o a escondidas?
		{ Type = "Choice", Key = "Entrar", Text = "¿Pides permiso a Ramón (conserjería) o te cuelas en el recreo (la puerta)?",
			Options = {
				{ Id = "Permiso", Npc = "Ramon", Text = "Pedir permiso a Ramón", Dialogue = "Permiso_Ramon", Effects = { Rel = { Ramon = 6 }, Traits = { Responsabilidad = 1 } } },
				{ Id = "Colarse", Prop = "Colarse", Text = "Colarte en el recreo", Dialogue = "Colarse", Effects = { Traits = { Valentia = 1 } } },
			},
			Actors = PISTAS },
		{ Type = "Reach", Place = "SalaCerradaPuerta", Text = "Ve a la puerta del fondo del pasillo", Actors = PUERTA },

		-- El candado: si fallas, vuelves a pensar
		{ Type = "Choice", Key = "Candado", Text = "El candado tiene seis ruedas de números. ¿Qué código pruebas?",
			Options = {
				{ Id = "131998", Text = "1 3 1 9 9 8", Dialogue = "Candado_AlReves", Stay = true },
				{ Id = "199813", Text = "1 9 9 8 1 3", Dialogue = "Candado_Bien", Effects = { Traits = { Curiosidad = 2 } } },
				{ Id = "199800", Text = "1 9 9 8 0 0", Dialogue = "Candado_SinLlave", Stay = true },
				{ Id = "123456", Text = "1 2 3 4 5 6", Dialogue = "Candado_Nico", Stay = true, Effects = { Traits = { Humor = 1 } } },
			},
			Actors = PUERTA },

		-- Dentro
		{ Type = "Scene", Dialogue = "Dentro", Teleport = "SalaCerrada", Actors = DENTRO },
		{ Type = "Group", Text = "Explora la sala", Need = 2,
			Steps = {
				{ Type = "Use", Prop = "Pupitre", Text = "Un pupitre viejo" },
				{ Type = "Use", Prop = "Caja", Text = "Una caja de lata" },
				{ Type = "Use", Prop = "Estanteria", Text = "La estantería de trofeos" },
			},
			Actors = DENTRO },
		{ Type = "Use", Prop = "Foto", Text = "En la pared hay una foto enmarcada", Actors = DENTRO },
		{ Type = "Scene", Dialogue = "LaFoto", Actors = DENTRO_FOTO, Props = { "Foto" } },

		-- Lucía
		{ Type = "Reach", Place = "AulaA", Text = "Busca a Lucía en clase", Actors = CLASE },
		{ Type = "Talk", Npc = "Lucia", Dialogue = "Lucia_Foto", Text = "Enséñale la foto a Lucía", Actors = CLASE,
			Effects = { Flags = { "CapsulaDelTiempo" } } },
		{ Type = "Choice", Key = "Capsula", Text = "¿Qué metes tú en la cápsula del tiempo de la clase?",
			Options = {
				{ Id = "Carta", Text = "Una carta para tu «yo» del último día de cole", Effects = { Traits = { Responsabilidad = 1 } } },
				{ Id = "Dibujo", Text = "Un dibujo de tu grupo", Effects = { Traits = { Creatividad = 1 }, Rel = { Omar = 3 } } },
				{ Id = "Prediccion", Text = "Una predicción: «Nico será futbolista»", Effects = { Traits = { Humor = 1 }, Rel = { Nico = 3 } } },
				{ Id = "Pregunta", Text = "Una pregunta para el futuro: «¿Seguimos siendo amigos?»", Effects = { Traits = { Empatia = 1 }, Rel = { Sara = 2, Omar = 2, Nico = 2 } } },
			},
			Actors = CLASE },
		{ Type = "Scene", Dialogue = "Capsula", Actors = CLASE },
	},

	Dialogues = {
		Rumores = { Lines = {
			{ S = "Nico", T = "Es un FANTASMA. Un fantasma de un niño que se quedó castigado para siempre. Por eso está cerrada." },
			{ S = "Sara", T = "Los fantasmas no existen. Es un laboratorio secreto. De química. Probablemente con explosiones." },
			{ S = "Omar", T = "Yo creo que es donde guardan los bocadillos que se deja la gente. Una sala entera de bocadillos." },
			{ S = "Iker", T = "Según mis datos, esa puerta lleva cerrada desde antes de que naciéramos. Nadie tiene la llave. Nadie.", If = CON_IKER },
			{ S = "Mateo", T = "En mi otro cole también había una sala así. Era el cuarto de la fregona. Pero esta parece más misteriosa.", If = AMIGO_MATEO },
			{ S = "Hugo", T = "En un libro que leí, detrás de una puerta así había un pasadizo al otro lado del mundo.", If = CON_HUGO },
			{ S = "Omar", T = "Bueno, voy a por mi almuerzo a la taquilla. Tanto misterio me da hambre. {nombre}, ¿vienes?" },
		} },
		Nota = { Lines = {
			{ S = "Narrador", T = "Abres la taquilla. Tu almuerzo sigue ahí. Pero detrás, encajado en una rendija de la chapa, hay un papel amarillento." },
			{ S = "Narrador", T = "Está escrito con rotulador gordo, con letra de niño: «NO ENTRES EN LA SALA DEL FONDO. ES NUESTRA. — L.»" },
			{ S = "Narrador", T = "Y más abajo, más pequeño: «Si de verdad quieres entrar: el año en que 4.º A ganó… y la llave que nadie toca.»" },
		} },
		TrasNota = { Lines = {
			{ S = "Omar", T = "¿«NO ENTRES»? Ahora TENGO que entrar. Es como cuando dicen «no mires». Miras." },
			{ S = "Sara", T = "El papel es viejísimo. Mira qué amarillo. Esto lleva ahí muchos años." },
			{ S = "Iker", T = "Tengo una libreta nueva. La he llamado «Caso: la sala del fondo».", If = CON_IKER },
			{ S = "Sara", T = "Necesitamos pistas: el año, la llave… y saber quién es «L.». Vamos a investigar." },
		} },
		Pista_Anuario = { Lines = {
			{ S = "Marisa", T = "¿El anuario de 1998? Qué curioso: nadie lo ha pedido en años. Toma, con cuidado, que tiene más años que tú." },
			{ S = "Narrador", T = "Página de 4.º A, curso 1998. Hay una foto de toda la clase… pero la han arrancado. Solo queda la esquina." },
			{ S = "Narrador", T = "Debajo pone: «4.º A, ¡campeones del concurso de ciencias!». Y una lista de nombres. Uno está rodeado con un corazón: «Lucía»." },
			{ S = "Sara", T = "¿Lucía? ¿Una Lucía de 1998? ¿Qué edad tendrá ahora Lucía? …No. No puede ser." },
		} },
		Pista_Llaves = { Lines = {
			{ S = "Ramon", T = "¿Las llaves? Aquí están todas: gimnasio, comedor, biblioteca… Cada una con su número." },
			{ S = "Narrador", T = "Hay un gancho con una llave pequeñita y oxidada. El número 13. Tiene un lazo amarillo atado." },
			{ S = "Ramon", T = "Esa no se toca. La 13 no la he usado nunca. Me la dio una niña hace muchos años y me hizo prometer que la guardaría." },
			{ S = "Ramon", T = "Y yo las promesas las cumplo. Aunque las haga una niña de nueve años con un jersey amarillo." },
		} },
		Pista_Trofeo = { Lines = {
			{ S = "Narrador", T = "Entre balones pinchados y conos, un trofeo lleno de polvo. Le soplas. ¡Achís!" },
			{ S = "Narrador", T = "La placa dice: «1.er premio Concurso de Ciencias · 4.º A · 1998». Tiene pegada una pegatina amarilla." },
			{ S = "Omar", T = "4.º A ganó en 1998. Ese es el año, ¿no? ¡El año en que 4.º A ganó!" },
		} },
		Pista_Puerta = { Lines = {
			{ S = "Narrador", T = "La puerta del fondo del pasillo. Madera vieja, un candado de seis ruedas de números." },
			{ S = "Narrador", T = "Grabado en el marco, muy pequeñito: «Sala de 4.º A. Promoción 1998. ¡Prohibido a los mayores!»" },
			{ S = "Sara", T = "Seis números. El año tiene cuatro. Faltan dos… como el número de una llave." },
		} },
		Codigo = { Lines = {
			{ S = "Sara", T = "A ver, recapitulemos. El año en que 4.º A ganó: 1998. La llave que nadie toca: la 13." },
			{ S = "Omar", T = "Y «L.» es una niña de jersey amarillo que le hizo prometer cosas a Ramón. Esto es mejor que una serie." },
			{ S = "Sara", T = "Ahora hay que abrir la puerta. Y hay dos formas: pedir permiso a Ramón… o entrar en el recreo, cuando no mira nadie." },
			{ S = "Iker", T = "Estadísticamente, a los que se cuelan los pillan el ochenta por ciento de las veces.", If = CON_IKER },
		} },
		Permiso_Ramon = { Lines = {
			{ S = "Ramon", T = "¿Que queréis abrir la sala del fondo? Vaya, vaya. Por fin alguien." },
			{ S = "Ramon", T = "Os doy permiso con una condición: el candado lo abrís vosotros. Si sabéis el código, es que os lo habéis ganado." },
			{ S = "Ramon", T = "Y yo voy detrás, que la sala tiene muchos años y el suelo cruje." },
		} },
		Colarse = { Lines = {
			{ S = "Narrador", T = "Recreo. El pasillo está vacío. Solo se oye el reloj y, a lo lejos, a Nico gritando «¡GOL!»." },
			{ S = "Omar", T = "(susurrando) Si nos pillan, yo solo pasaba por aquí. Buscando… un bocadillo." },
		} },
		Candado_AlReves = { Lines = {
			{ S = "Narrador", T = "Clic… clac. Nada. El candado no se abre." },
			{ S = "Sara", T = "Espera. La nota decía primero el año y DESPUÉS la llave. Lo has puesto al revés." },
		} },
		Candado_SinLlave = { Lines = {
			{ S = "Narrador", T = "Clic… clac. Nada." },
			{ S = "Omar", T = "El año está bien, creo. Pero ¿y la llave que nadie toca? ¿Qué número tenía?" },
		} },
		Candado_Nico = { Lines = {
			{ S = "Nico", T = "¡Pon uno, dos, tres, cuatro, cinco, seis! ¡Nadie cambia la contraseña que viene de fábrica!" },
			{ S = "Narrador", T = "Clic… clac. Nada." },
			{ S = "Sara", T = "Nico. Por favor." },
		} },
		Candado_Bien = { Lines = {
			{ S = "Narrador", T = "1… 9… 9… 8… 1… 3. ¡CLAC! El candado se abre. La puerta cruje muy despacio." },
			{ S = "Nico", T = "Si sale un fantasma, yo me quedo detrás de Omar." },
			{ S = "Omar", T = "Y yo detrás de {nombre}." },
		} },
		Dentro = { Lines = {
			{ S = "Narrador", T = "Polvo, luz entrando por una ventana alta, y… pupitres. Pupitres viejos de madera, como de otra época." },
			{ S = "Narrador", T = "Hay dibujos en las paredes, una estantería con trofeos y una caja de lata en una mesa." },
			{ S = "Sara", T = "No es un laboratorio. Es… un aula. Un aula de hace muchísimos años." },
			{ S = "Ramon", T = "Esta era el aula de 4.º A antes de la reforma. Nadie la ha vuelto a usar. Bueno… casi nadie.", If = PERMISO },
		} },
		Dentro_Pupitre = { Lines = {
			{ S = "Narrador", T = "En la tapa del pupitre alguien grabó con mucho cuidado: «L. estuvo aquí. 1998. Seré profe.»" },
			{ S = "Omar", T = "«Seré profe». Qué niña más decidida." },
		} },
		Dentro_Caja = { Lines = {
			{ S = "Narrador", T = "Dentro de la caja hay cartas dobladas, un cromo, una cinta de pelo amarilla y un papel: «CÁPSULA DEL TIEMPO. Abrir en 2008»." },
			{ S = "Sara", T = "¡2008! Se les olvidó abrirla. Lleva cerrada desde entonces." },
		} },
		Dentro_Trofeos = { Lines = {
			{ S = "Narrador", T = "Medallas de cartón, un trofeo de «mejor disfraz» y un diploma: «Al grupo más curioso del colegio»." },
			{ S = "Nico", T = "Nosotros tendríamos que tener uno de esos. «Al grupo más… algo»." },
		} },
		LaFoto = { Lines = {
			{ S = "Narrador", T = "Es la foto que falta en el anuario: la clase de 4.º A de 1998, todos sonriendo delante de esta misma pizarra." },
			{ S = "Narrador", T = "En la primera fila, una niña con jersey amarillo, coletas y una sonrisa que conoces muy bien." },
			{ S = "Sara", T = "Es… ¡es LUCÍA! ¡Nuestra Lucía! ¡Fue a esta clase! ¡Fue a NUESTRO colegio!" },
			{ S = "Ramon", T = "¡Ajá! ¡Os pillé! ¿Qué hacéis aquí dentro en el recreo?", If = COLARSE },
			{ S = "Ramon", T = "…Ah. Habéis encontrado la foto. Bueno. Esta vez no digo nada. Pero la próxima, se pide permiso.", If = COLARSE, Effects = { Rel = { Ramon = -2 } } },
			{ S = "Ramon", T = "Sí. La niña del jersey amarillo. La que me dio la llave 13. Y ahora es vuestra profe. Qué rápido pasa todo.", If = PERMISO },
			{ S = "Ramon", T = "Id a enseñársela. Creo que le va a hacer mucha ilusión. Aunque primero igual se pone roja." },
		} },
		Lucia_Foto = { Lines = {
			{ S = "Lucia", T = "¿Qué traéis ahí, con esas caras? A ver…" },
			{ S = "Lucia", T = "…" },
			{ S = "Lucia", T = "¿De dónde habéis sacado esto? ¡Esa soy yo! ¡Con nueve años! ¡Y esas coletas!" },
			{ S = "Lucia", T = "La nota de la taquilla también era mía. Esa taquilla era mía, ¿sabéis? Escondimos la sala para que nadie encontrara nuestra cápsula." },
			{ S = "Lucia", T = "Y nos olvidamos de abrirla. Nos hicimos mayores y… se nos olvidó. Qué tonta." },
			{ Ask = "¿Qué haces con la foto?", Options = {
				{ T = "Devolvérsela: «Es tuya. Te la hemos traído.»", Effects = { Choice = { FotoLucia = "Devolver" }, Rel = { Lucia = 10 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Lucia", T = "Gracias. De verdad. Os voy a hacer una copia a cada uno. Esta la pongo en mi mesa." },
				} },
				{ T = "Enseñársela a toda la clase", Effects = { Choice = { FotoLucia = "Clase" }, Rel = { Lucia = 5, Nico = 3 }, Traits = { Humor = 1 } }, Then = {
					{ S = "Nico", T = "¡ATENCIÓN TODOS! ¡LUCÍA CON COLETAS!" },
					{ S = "Lucia", T = "¡Nico! …Vale, vale. Sí. Era yo. Y era la mejor de la clase en ciencias, que conste." },
				} },
				{ T = "Guardar el secreto: «No se lo diremos a nadie»", Effects = { Choice = { FotoLucia = "Secreto" }, Flags = { "SecretoLucia" }, Rel = { Lucia = 8 }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Lucia", T = "¿Un secreto entre nosotros? Me parece perfecto. Tomad una copia cada uno. Y ni una palabra de las coletas." },
				} },
			} },
			{ S = "Lucia", T = "Tengo una idea. Mañana abrimos juntos la cápsula de mi clase… y vosotros dejáis la vuestra en la sala." },
			{ S = "Lucia", T = "Y la abriremos el último día de colegio. El último de verdad. Os lo prometo. Esta vez no se me olvida." },
		} },
		Capsula = { Lines = {
			{ S = "Narrador", T = "Al día siguiente, toda la clase entra en la sala del fondo. Lucía lee en voz alta las cartas de su clase. Se ríe. Se emociona." },
			{ S = "Narrador", T = "Después, cada uno mete algo en una caja nueva. Ramón la cierra con el candado. Código nuevo. Secreto." },
			{ S = "Lucia", T = "«Cápsula del tiempo de 4.º A. Abrir el último día de colegio». Hecho." },
			{ S = "Omar", T = "¿Y si se nos olvida?" },
			{ S = "Sara", T = "No se nos va a olvidar. Lo he apuntado en tres sitios." },
			{ S = "Narrador", T = "Lucía te da una copia de la foto de 1998. La guardas en la mochila." },
		} },
	},
}
