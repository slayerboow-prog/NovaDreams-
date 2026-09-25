-- MISIÓN 11 · «EL PROYECTO FINAL» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.21.
--
-- Lucía anuncia el proyecto de Ciencias («Un invento para mejorar Valmar») → eliges compañero (Omar
-- siempre está) → tema y rol → investigar (biblioteca, Ramón, {abu}, la fuente del parque) →
-- materiales (cartón del almacén y cartulinas de la librería) → una discusión en el equipo →
-- construir la maqueta → la noche antes, un desastre → la presentación delante de las familias → nota.
-- Si el proyecto sale premiado, una hora después sale en el periódico de Valmar (Eco_Periodico).

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }

local HUERTO = { Choices = { Tema = "Huerto" } }
local ROBOT = { Choices = { Tema = "Robot" } }
local MASCOTAS = { Choices = { Tema = "Mascotas" } }
local MUSEO = { Choices = { Tema = "Museo" } }

local CLASE = {
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	{ Npc = "Omar", Place = "AulaA", Offset = V(3, 0, -2) },
	{ Npc = "Sara", Place = "AulaA", Offset = V(-2, 0, -3) },
	{ Npc = "Nico", Place = "AulaA", Offset = V(4, 0, 3) },
	{ Npc = "Iker", Place = "AulaA", Offset = V(-4, 0, 2), If = CON_IKER },
	{ Npc = "Mateo", Place = "AulaA", Offset = V(1, 0, 5), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "AulaA", Offset = V(-5, 0, -2), If = CON_HUGO },
}

-- Tu equipo: Omar y el compañero que elegiste (te siguen mientras investigas)
local EQUIPO = {
	{ Npc = "Omar", Mode = "Follow" },
	{ Npc = "Sara", Mode = "Follow", If = { Choices = { Companero = "Sara" } } },
	{ Npc = "Nico", Mode = "Follow", If = { Choices = { Companero = "Nico" } } },
	{ Npc = "Iker", Mode = "Follow", If = { Choices = { Companero = "Iker" } } },
	{ Npc = "Mateo", Mode = "Follow", If = { Choices = { Companero = "Mateo" } } },
	{ Npc = "Hugo", Mode = "Follow", If = { Choices = { Companero = "Hugo" } } },
}
local function equipoEn(place: string): { any }
	return {
		{ Npc = "Omar", Place = place, Offset = V(3, 0, 2) },
		{ Npc = "Sara", Place = place, Offset = V(-3, 0, 2), If = { Choices = { Companero = "Sara" } } },
		{ Npc = "Nico", Place = place, Offset = V(-3, 0, 2), If = { Choices = { Companero = "Nico" } } },
		{ Npc = "Iker", Place = place, Offset = V(-3, 0, 2), If = { Choices = { Companero = "Iker" } } },
		{ Npc = "Mateo", Place = place, Offset = V(-3, 0, 2), If = { Choices = { Companero = "Mateo" } } },
		{ Npc = "Hugo", Place = place, Offset = V(-3, 0, 2), If = { Choices = { Companero = "Hugo" } } },
	}
end
local TALLER = equipoEn("AulaA")

local INVESTIGAR = {
	{ Npc = "Marisa", Place = "SpotBibliotecaria" },
	{ Npc = "Ramon", Place = "Conserjeria", Offset = V(-2, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(4, 0, 0) },
}
for _, actor in EQUIPO do
	table.insert(INVESTIGAR, actor)
end

-- El día de la presentación: la clase y las familias
local PRESENTACION = {
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	{ Npc = "Familia", Place = "AulaA", Offset = V(-6, 0, 8), Mode = "Wave" },
	{ Npc = "Abu", Place = "AulaA", Offset = V(-3, 0, 9) },
	{ Npc = "Andres", Place = "AulaA", Offset = V(6, 0, 8) },
	{ Npc = "Bruno", Place = "AulaA", Offset = V(8, 0, 2) },
}
for _, actor in TALLER do
	table.insert(PRESENTACION, actor)
end

local CASA = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2) },
}

return {
	Id = "Cole11_Proyecto",
	Kind = "Main",
	Title = "El proyecto final",
	Description = "El último proyecto de Ciencias de primaria: «Un invento para mejorar Valmar». Se presenta delante de las familias.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 10, 10 },
	Duration = { 25, 35 },
	Difficulty = 3,
	Type = "Historia · Estudios",
	Requires = { Completed = { "Cole10_Festival" }, StageProgress = 0.82 },
	Npcs = { "Lucia", "Omar", "Sara", "Nico", "Iker", "Mateo", "Hugo", "Marisa", "Ramon", "Abu", "Familia", "Andres", "Bruno" },
	Locations = { "AulaA", "BibliotecaColegio", "Conserjeria", "HomeSalon", "FuenteParque", "AlmacenColegio", "Libreria" },
	Next = { "Cole12_UltimoDia" },
	Outcomes = { "Compañero, tema y rol", "Cómo resolvéis la discusión", "Qué hacéis con el desastre", "La nota (y el periódico)" },

	Moment = "El proyecto final de primaria",
	Memory = "ProyectoFinal",
	Rewards = { Items = { Maqueta = 1 }, Money = 10, Later = { { AfterHours = 1, Start = "Eco_Periodico", If = { Flags = { "ProyectoPremiado" } } } } },

	Props = {
		LibroCiencias = { Kind = "Libro", Name = "Libros de inventos", Prompt = "Investigar", Place = "BibliotecaColegio", Offset = V(5, 0, -3), Color = Color3.fromRGB(60, 150, 90), Dialogue = "Inv_Biblioteca", Once = true },
		Fuente = { Kind = "Marcador", Name = "La fuente del parque", Prompt = "Medir y observar", Place = "FuenteParque", Dialogue = "Inv_Fuente", Once = true },
		Carton = { Kind = "Caja", Name = "Cajas de cartón para reciclar", Prompt = "Coger", Place = "AlmacenColegio", Offset = V(2, 0, -2), Color = Color3.fromRGB(190, 150, 100), Dialogue = "Mat_Carton", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Las últimas semanas de primaria…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase", Actors = CLASE },
		{ Type = "Class", Subject = "Ciencias", Mode = "Clase", Place = "AulaA", Text = "Clase de Ciencias", Actors = CLASE },
		{ Type = "Scene", Dialogue = "Anuncio", Actors = CLASE },
		{ Type = "Choice", Key = "Companero", Text = "Omar ya está en tu equipo. ¿Quién es el tercero? (habla con quien elijas)",
			Options = {
				{ Id = "Sara", Npc = "Sara", Text = "Sara", Dialogue = "Con_Sara", Effects = { Rel = { Sara = 5 } } },
				{ Id = "Nico", Npc = "Nico", Text = "Nico", Dialogue = "Con_Nico", Effects = { Rel = { Nico = 5 } } },
				{ Id = "Iker", Npc = "Iker", Text = "Iker", Dialogue = "Con_Iker", If = CON_IKER, Effects = { Rel = { Iker = 5 } } },
				{ Id = "Mateo", Npc = "Mateo", Text = "Mateo", Dialogue = "Con_Mateo", If = AMIGO_MATEO, Effects = { Rel = { Mateo = 5 } } },
				{ Id = "Hugo", Npc = "Hugo", Text = "Hugo", Dialogue = "Con_Hugo", If = CON_HUGO, Effects = { Rel = { Hugo = 5 } } },
			},
			Actors = CLASE },
		{ Type = "Scene", Dialogue = "TemaYRol", Actors = TALLER },

		-- Investigar
		{ Type = "Group", Text = "Investiga para el proyecto (tres fuentes)", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "LibroCiencias", Text = "Libros de inventos (biblioteca)" },
				{ Type = "Talk", Npc = "Ramon", Dialogue = "Inv_Ramon", Text = "Entrevista a Ramón (conserjería)" },
				{ Type = "Talk", Npc = "Abu", Dialogue = "Inv_Abu", Text = "Entrevista a {abu} (en casa)" },
				{ Type = "Use", Prop = "Fuente", Text = "Observa la fuente del parque" },
			},
			Actors = INVESTIGAR },

		-- Materiales
		{ Type = "Use", Prop = "Carton", Text = "Coge cartón para reciclar (almacén del gimnasio)", Actors = EQUIPO },
		{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Libreria" }, Place = "Libreria", Text = "Compra cartulinas en la librería", Actors = EQUIPO,
			Nudge = { After = 90, Every = 90, S = "Omar", T = "Yo pongo la mitad de las cartulinas. Bueno, un tercio. Tengo dos monedas." } },

		-- Discusión y maqueta
		{ Type = "Reach", Place = "AulaA", Text = "Vuelve a clase a montar la maqueta", Actors = TALLER },
		{ Type = "Scene", Dialogue = "Discusion", Actors = TALLER },
		{ Type = "MiniGame", Game = "Timing", Title = "Monta la maqueta", Icon = "✂️", Hint = "Pega cada pieza cuando la aguja esté en verde",
			Rounds = 6, Need = 4, Zone = 0.25, Speed = 1,
			Win = { Flags = { "MaquetaBonita" }, Traits = { Creatividad = 1 } }, Lose = { Traits = { Humor = 1 } },
			Actors = TALLER },

		-- La noche antes
		{ Type = "Transition", Text = "La noche antes de la presentación…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Desastre", Teleport = "HomeSalon", Actors = CASA },

		-- La presentación
		{ Type = "Transition", Text = "El día de la presentación…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase: las familias ya están llegando", Actors = PRESENTACION },
		{ Type = "Scene", Dialogue = "Nervios", Actors = PRESENTACION },
		{ Type = "Class", Subject = "Ciencias", Mode = "Examen", Place = "AulaA", Text = "Presenta el proyecto (las preguntas del jurado)",
			Bonus = { If = { Flags = { "MaquetaBonita" } }, Seconds = 5 }, Actors = PRESENTACION },
		{ Type = "Scene", Dialogue = "Resultado", Actors = PRESENTACION },
	},

	Dialogues = {
		Anuncio = { Lines = {
			{ S = "Lucia", T = "Último proyecto de primaria. El tema: «Un invento para mejorar Valmar». Equipos de tres." },
			{ S = "Lucia", T = "Tenéis que investigar, construir una maqueta y presentarla. Y lo presentaréis… delante de las familias." },
			{ S = "Nico", T = "¿Delante de las FAMILIAS? ¿Con mi abuela? Mi abuela se ríe de TODO." },
			{ S = "Omar", T = "{nombre}, tú y yo en el mismo equipo. No es una pregunta. Bueno, sí es una pregunta. ¿Vale?" },
			{ S = "Lucia", T = "Perfecto. Ahora os falta el tercero." },
		} },
		Con_Sara = { Lines = { { S = "Sara", T = "Acepto. Tengo tres cuadernos de ideas. Uno se titula «Ideas que no le he contado a nadie». Hoy lo abrimos." } } },
		Con_Nico = { Lines = { { S = "Nico", T = "¡Sí! ¡Vamos a hacer algo que explote! …De forma segura. Lucía me está mirando." } } },
		Con_Iker = { Lines = { { S = "Iker", T = "Acepto. Yo me encargo de los datos. Los datos convencen a los jurados. Lo he leído." } } },
		Con_Mateo = { Lines = { { S = "Mateo", T = "¿Yo? Vale. Se me dan bien los dibujos técnicos. Mi padre es fontanero y me enseña." } } },
		Con_Hugo = { Lines = { { S = "Hugo", T = "¡Sí! He leído muchos libros de inventores. La mitad eran de piratas inventores, pero cuenta." } } },

		TemaYRol = { Lines = {
			{ S = "Omar", T = "Bueno, equipo. ¿Qué inventamos?" },
			{ Ask = "¿Cuál es vuestro invento?", Options = {
				{ T = "Un huerto en el patio del cole", Effects = { Choice = { Tema = "Huerto" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Omar", T = "Tomates del cole. Lechugas del cole. Ensalada del cole. Me gusta todo de esta idea." },
				} },
				{ T = "Un robot que recoge basura del parque", Effects = { Choice = { Tema = "Robot" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Omar", T = "Un robot. ¿Le podemos poner nombre? Se llama Bocadillo. No hay más que hablar." },
				} },
				{ T = "Un tablón para encontrar mascotas perdidas", Effects = { Choice = { Tema = "Mascotas" }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Omar", T = "Como Bigotes, el gato del cole. Seguro que Bigotes lo aprobaría. Con un maullido." },
				} },
				{ T = "Un museo del colegio con la sala cerrada", If = { Flags = { "CapsulaDelTiempo" } }, Effects = { Choice = { Tema = "Museo" }, Traits = { Creatividad = 1 }, Rel = { Lucia = 3 } }, Then = {
					{ S = "Omar", T = "¡Con la foto de Lucía! Bueno… si Lucía quiere. Le preguntamos primero." },
				} },
			} },
			{ Ask = "¿Qué haces tú en el equipo?", Options = {
				{ T = "Organizo: alguien tiene que llevar el calendario", Effects = { Choice = { Rol = "Lider" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Omar", T = "Jefe o jefa de proyecto. Te hago una chapa. De cartón, que es lo que hay." },
				} },
				{ T = "Investigo: buscar datos es lo mío", Effects = { Choice = { Rol = "Investigador" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Omar", T = "Tú buscas, yo te acompaño y traigo galletas. Es un sistema perfecto." },
				} },
				{ T = "Construyo la maqueta", Effects = { Choice = { Rol = "Constructor" }, Traits = { Creatividad = 1 } }, Then = {
					{ S = "Omar", T = "Manos de artista. Yo te paso el pegamento. Sin comérmelo." },
				} },
				{ T = "Presento delante de todos", Effects = { Choice = { Rol = "Presentador" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Omar", T = "¿Delante de las familias? Qué valor. Yo me pongo al lado y sujeto la maqueta con cara seria." },
				} },
			} },
		} },

		Inv_Biblioteca = { Lines = {
			{ S = "Marisa", T = "¿Inventos? Estantería azul, arriba. Y el de las ideas locas, abajo: es el que más se presta." },
			{ S = "Narrador", T = "Un huerto escolar da comida para veinte familias al año. Hay colegios con gallinas. Omar lee eso dos veces.", If = HUERTO },
			{ S = "Narrador", T = "Hay robots de cartón que funcionan con un motor pequeño y una pinza. Solo hace falta paciencia.", If = ROBOT },
			{ S = "Narrador", T = "La mayoría de mascotas perdidas aparece a menos de tres calles de casa. Un buen tablón ayuda mucho.", If = MASCOTAS },
			{ S = "Narrador", T = "Un museo pequeño puede ser una vitrina y una historia bien contada. Marisa te enseña el anuario de 1998 otra vez.", If = MUSEO },
		}, Effects = { Traits = { Curiosidad = 1 } } },
		Inv_Ramon = { Lines = {
			{ S = "Ramon", T = "¿Una entrevista? ¿A mí? Espera, que me peino." },
			{ S = "Ramon", T = "En el patio hay un rincón con sol todo el día. Allí crecía un limonero cuando yo empecé. Buen sitio para un huerto.", If = HUERTO },
			{ S = "Ramon", T = "Cada lunes recojo del parque una bolsa entera de papeles. Si vuestro robot me ayuda, os invito a un zumo.", If = ROBOT },
			{ S = "Ramon", T = "Yo encontré a Bigotes en una caja, bajo la lluvia. Si hubiera tenido un tablón, habría encontrado a su familia.", If = MASCOTAS },
			{ S = "Ramon", T = "Tengo en la conserjería cosas de todas las épocas del cole. Un museo… me haría mucha ilusión.", If = MUSEO },
		}, Effects = { Rel = { Ramon = 3 } } },
		Inv_Abu = { Lines = {
			{ S = "Abu", T = "¿Una entrevista para el colegio? ¡Qué importante! Pregunta, pregunta." },
			{ S = "Abu", T = "Cuando tenía tu edad, en casa teníamos huerto. Lo más importante: regar temprano y tener paciencia.", If = HUERTO },
			{ S = "Abu", T = "¿Un robot? En mis tiempos el robot era tu hermano mayor, y recogía cuando se lo mandaban. Me parece buena idea.", If = ROBOT },
			{ S = "Abu", T = "Una vez perdimos a un perro que se llamaba Chispa. Lo encontró la panadera. Los vecinos son el mejor tablón.", If = MASCOTAS },
			{ S = "Abu", T = "¿Un museo del colegio? Yo fui a ese colegio, ¿lo sabías? Te puedo prestar la foto de mi clase.", If = MUSEO },
		}, Effects = { Rel = { Abu = 5 } } },
		Inv_Fuente = { Lines = {
			{ S = "Narrador", T = "Mides cuánto tarda en llenarse un vaso en la fuente. Sara diría que es un experimento. Tú lo apuntas todo." },
			{ S = "Omar", T = "Doce segundos. Y yo me he bebido tres vasos. Por la ciencia." },
		}, Effects = { Traits = { Curiosidad = 1 } } },
		Mat_Carton = { Lines = {
			{ S = "Narrador", T = "Cajas de cartón de todos los tamaños. Andrés dice que podéis llevaros las que queráis «menos la de los conos»." },
		} },

		Discusion = { Lines = {
			{ S = "Narrador", T = "Toca montar la maqueta. Y entonces empiezan los problemas." },
			{ S = "Sara", T = "Hay que hacerlo exacto: cada medida con regla. Si no, no es ciencia.", If = { Choices = { Companero = "Sara" } } },
			{ S = "Nico", T = "¡Hay que hacerlo ENORME y con luces! ¡Que se vea desde la puerta!", If = { Choices = { Companero = "Nico" } } },
			{ S = "Iker", T = "Primero hay que hacer una tabla con todos los datos. Luego la maqueta. Luego otra tabla.", If = { Choices = { Companero = "Iker" } } },
			{ S = "Mateo", T = "Yo… creo que mi dibujo no vale. Mejor hacedlo vosotros.", If = { Choices = { Companero = "Mateo" } } },
			{ S = "Hugo", T = "¿Y si le añadimos una historia? Toda maqueta necesita una historia. Y un pirata.", If = { Choices = { Companero = "Hugo" } } },
			{ S = "Omar", T = "Yo solo quiero que no nos enfademos. Y merendar. Pero sobre todo lo primero." },
			{ Ask = "¿Cómo lo resolvéis?", Options = {
				{ T = "Juntar las dos ideas: un poco de cada", Effects = { Choice = { Discusion = "Juntar" }, Traits = { Empatia = 1 }, Rel = { Omar = 3, Sara = 2, Nico = 2, Iker = 2, Mateo = 2, Hugo = 2 } }, Then = {
					{ S = "Omar", T = "¡Eso! Exacto Y con luces. Con historia Y con datos. Somos unos genios de la diplomacia." },
				} },
				{ T = "Votar, y lo que salga", Effects = { Choice = { Discusion = "Votar" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Omar", T = "Votación. Dos contra uno. Bueno, uno contra uno contra uno. Otra vez. …Ya está: gana la mezcla." },
				} },
				{ T = "Decidir tú, que para algo lo has pensado", Effects = { Choice = { Discusion = "Decidir" }, Traits = { Valentia = 1 }, Rel = { Omar = -1, Sara = -2, Nico = -2, Iker = -2, Hugo = -2 } }, Then = {
					{ S = "Omar", T = "Vale… lo hacemos como dices. Pero que conste que ha sido un poco de «porque sí»." },
				} },
			} },
			{ S = "Mateo", T = "¿De verdad os gusta mi dibujo? Vale. Entonces lo hago bien grande.", If = { Choices = { Companero = "Mateo" } } },
		} },

		Desastre = { Lines = {
			{ S = "Familia", T = "{nombre}, teléfono. Es Omar. Dice que es una emergencia de maqueta." },
			{ S = "Omar", T = "(al teléfono) Mi hermano pequeño… se ha sentado encima. Encima de la maqueta. Está bien. El hermano. La maqueta no." },
			{ Ask = "¿Qué hacéis?", Options = {
				{ T = "Llamar al equipo y arreglarla juntos (en casa de Omar)", Effects = { Flags = { "ArregloEnEquipo" }, Traits = { Responsabilidad = 1 }, Rel = { Omar = 6 } }, Then = {
					{ S = "Narrador", T = "Pasáis la tarde entre pegamento y cinta. Queda un poco torcida… pero es vuestra. Y lleva una tirita de cartón." },
				} },
				{ T = "Pedir ayuda a {familia}", Effects = { Flags = { "AyudaFamilia" }, Rel = { Familia = 6 } }, Then = {
					{ S = "Familia", T = "¿Pegamento, tijeras y nervios? Tengo las tres cosas. Vamos." },
					{ S = "Abu", T = "Y yo sé hacer las esquinas rectas con una regla y un libro gordo. Truco de los de antes." },
				} },
				{ T = "Presentarla rota… y contar lo que pasó con humor", Effects = { Flags = { "MaquetaRota" }, Traits = { Humor = 2 } }, Then = {
					{ S = "Omar", T = "¿Presentarla… así? Bueno. Diremos que ha sobrevivido a un terremoto. Un terremoto de cuatro años." },
				} },
			} },
		} },

		Nervios = { Lines = {
			{ S = "Lucia", T = "Bienvenidas, familias. Hoy cada equipo presenta su invento para Valmar. Después, el jurado hará algunas preguntas." },
			{ S = "Familia", T = "(desde el fondo) ¡Ánimo, {nombre}!" },
			{ S = "Omar", T = "Me tiemblan las rodillas. ¿A ti te tiemblan? A mí las dos." },
			{ S = "Bruno", T = "(Bruno, al pasar) Suerte. Yo he hecho un volcán. Otra vez. Es un clásico." },
		} },
		Resultado = { Lines = {
			{ S = "Narrador", T = "Explicas vuestro huerto: dónde iría, qué plantaríais, quién lo regaría. Ramón levanta el pulgar desde la puerta.", If = HUERTO },
			{ S = "Narrador", T = "El robot «Bocadillo» abre y cierra la pinza. Todo el público hace «ooooh». Omar hace una reverencia.", If = ROBOT },
			{ S = "Narrador", T = "Enseñáis el tablón de mascotas con una foto de Bigotes. Media clase dice «ooooh».", If = MASCOTAS },
			{ S = "Narrador", T = "Presentáis el museo del colegio con la foto de 1998. Lucía se tapa la cara… y luego aplaude la primera.", If = MUSEO },
			{ S = "Omar", T = "Y… esta es la tirita. Esta maqueta ha vivido mucho. Como nosotros.", If = { Flags = { "ArregloEnEquipo" } } },
			{ S = "Narrador", T = "Cuentas lo del hermano de Omar. Las familias se ríen. Luego aplauden la idea más todavía.", If = { Flags = { "MaquetaRota" } } },
			{ S = "Lucia", T = "Buen trabajo, equipo. Una presentación clara, con datos y con ganas. Un sobresaliente.", If = { LastGradeAtLeast = 8 },
				Effects = { Flags = { "ProyectoPremiado" } } },
			{ S = "Lucia", T = "Y este proyecto… lo vamos a mandar al periódico de Valmar. Merece que lo conozca todo el barrio.", If = { LastGradeAtLeast = 8 } },
			{ S = "Lucia", T = "Una idea muy bonita. La presentación se os ha hecho un poco cuesta arriba, pero el invento es bueno. Aprobado.", If = { LastGradeBelow = 8 } },
			{ S = "Familia", T = "Pase lo que pase, qué orgullo me das. Muchísimo. Ya no sé cómo decirlo más." },
			{ S = "Lucia", T = "Queda una semana de colegio. La última. Aprovechadla." },
		} },
	},
}
