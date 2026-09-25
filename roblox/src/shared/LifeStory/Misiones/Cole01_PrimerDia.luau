-- MISIÓN 01 · «EL PRIMER DÍA» (15-20 min)
-- Ficha de diseño completa: docs/historia/11-misiones-episodicas.md, apartado 11.7.
--
-- Casa (despertar, vestirse, mochila, desayuno) → camino (el balón de Dani) → entrada con gente →
-- encontrar a tu tutora → recorrer el colegio con tres informantes → tu aula → elegir sitio →
-- presentarte → Matemáticas → recreo con un grupo → los libros de Mateo → cena en casa.

local V = Vector3.new

-- Quién está dónde (se repite en varios pasos: así los actores no desaparecen entre escenas)
local FAMILIA_DORMITORIO = { Npc = "Familia", Place = "CasaDespertar" }
local FAMILIA_COCINA = { Npc = "Familia", Place = "HomeCocina", Offset = V(-1.5, 0, 2.5) }
local ABU_SALON = { Npc = "Abu", Place = "HomeSalon", Offset = V(11, 0, -2.5), Talk = "Abu_Suerte" }
local FAMILIA_CON_TIGO = { Npc = "Familia", Mode = "Follow", If = { Choices = { Acompanante = "Familia" } } }
local DANI = { Npc = "Dani", Place = "CaminoAlCole", Offset = V(3, 0, 0) }

local ENTRADA = {
	{ Npc = "Ramon", Place = "SpotProfesorEntrada" },
	{ Npc = "Alumno1", Place = "EntradaColegio", Offset = V(6, 0, -8), Mode = "Wander", Radius = 6, Prompt = false },
	{ Npc = "Alumno2", Place = "EntradaColegio", Offset = V(-8, 0, -10), Mode = "Wander", Radius = 6, Prompt = false },
	{ Npc = "Alumno3", Place = "EntradaColegio", Offset = V(10, 0, -12), Mode = "Wander", Radius = 8, Prompt = false },
	{ Npc = "Alumno4", Place = "EntradaColegio", Offset = V(-12, 0, -6), Mode = "Wander", Radius = 6, Prompt = false },
	{ Npc = "Mayor1", Place = "SpotPadres3", Offset = V(2, 0, 0), Mode = "Wander", Radius = 5, Prompt = false },
	{ Npc = "Madre", Place = "SpotPadres1", Mode = "Wave", Prompt = false },
	{ Npc = "Padre", Place = "SpotPadres2", Bark = "Pórtate bien, ¿eh? ¡Y come la fruta!" },
}

local PROFES = {
	{ Npc = "Lucia", Place = "PasilloColegio", Offset = V(3, 0, 3) },
	{ Npc = "Andres", Place = "PasilloColegio", Offset = V(-4, 0, 1), Talk = "Andres_Pista" },
	{ Npc = "Marta", Place = "PasilloColegio", Offset = V(-1, 0, 6), Talk = "Marta_Pista" },
}

-- La clase de 1.º A, sentada (pupitres por orden: 1-4 primera fila… la pizarra queda delante)
local function seated(npc: string, index: number): { [string]: any }
	return { Npc = npc, Place = "PupitreA", Index = index, Offset = V(2.4, 0, 0), Mode = "Sit", Look = V(-1, 0, 0), Prompt = false }
end
local CLASE = {
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	seated("Iker", 1),
	seated("Sara", 2),
	seated("Vega", 4),
	seated("Omar", 5),
	seated("Alex", 6),
	seated("Bruno", 9),
	seated("Ruben", 10),
	seated("Mateo", 12),
	seated("Hugo", 8),
	seated("Nico", 13),
}

local RECREO = {
	{ Npc = "Nico", Place = "SpotGrupoDeportistas", Offset = V(-1.5, 0, 0) },
	{ Npc = "Alex", Place = "SpotGrupoDeportistas", Offset = V(1.5, 0, 1), Talk = "Alex_Recreo" },
	{ Npc = "Omar", Place = "SpotGrupoArtistas", Offset = V(-1.5, 0, 0) },
	{ Npc = "Vega", Place = "SpotGrupoArtistas", Offset = V(1.5, 0, 1), Talk = "Vega_Recreo" },
	{ Npc = "Sara", Place = "SpotGrupoEstudiantes", Offset = V(-1.5, 0, 0) },
	{ Npc = "Iker", Place = "SpotGrupoEstudiantes", Offset = V(1.5, 0, 1), Talk = "Iker_Recreo" },
	{ Npc = "Bruno", Place = "Patio", Offset = V(14, 0, -8), Bark = "¿Y tú qué miras?" },
	{ Npc = "Ruben", Place = "Patio", Offset = V(16, 0, -7), Bark = "Jejeje. Nada, nada." },
	{ Npc = "Hugo", Place = "Patio", Offset = V(15, 0, -10), Bark = "…Hola." },
}
local MATEO_PATIO = { Npc = "Mateo", Place = "Patio", Offset = V(4, 0, -12) }

local function with(list: { any }, ...): { any }
	local out = table.clone(list)
	for _, extra in { ... } do
		table.insert(out, extra)
	end
	return out
end

return {
	Id = "Cole01_PrimerDia",
	Kind = "Main",
	Title = "El primer día",
	Description = "Hoy empiezas el colegio. Nuevos lugares, nuevas caras… y un montón de cosas que aprender.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 6, 6 },
	Duration = { 15, 20 },
	Difficulty = 1,
	Type = "Historia",
	Npcs = { "Familia", "Abu", "Dani", "Ramon", "Andres", "Marta", "Lucia", "Nico", "Sara", "Omar", "Mateo", "Bruno", "Ruben", "Hugo", "Alex", "Vega", "Iker" },
	Locations = { "HomeDormitorio", "HomeCocina", "CaminoAlCole", "EntradaColegio", "PasilloColegio", "BibliotecaColegio", "ComedorColegio", "Patio", "GimnasioColegio", "CampoColegio", "AulaA", "CasaFamiliar" },
	Next = { "Cole02_Mochila" },
	Outcomes = { "Amigo de Mateo o no", "Sitio en clase (Sara, Nico o Mateo)", "Grupo del recreo", "Llegaste tarde o a tiempo" },

	Moment = "Tu primer día de colegio",
	Memory = "PrimerDiaCole",
	Rewards = { Money = 10 },

	Props = {
		Armario = { Kind = "Armario", Name = "Armario", Prompt = "Abrir", Place = "CasaArmario", Offset = V(-5.2, 0, 4.8), Look = V(1, 0, 0), Dialogue = "Armario" },
		Mochila = { Kind = "Mochila", Name = "Tu mochila nueva", Prompt = "Preparar", Place = "CasaMochila", Offset = V(2.5, 0, 2), Dialogue = "Mochila", Once = true },
		Desayuno = { Kind = "Desayuno", Name = "Desayuno", Prompt = "Desayunar", Place = "CasaDesayuno", Offset = V(-1.5, 0, -1), Dialogue = "Desayuno", Once = true },
		Almohada = { Kind = "Almohada", Name = "Tu cama", Prompt = "Hacer la cama", Place = "CasaCama", Offset = V(-3, 0, -2.5), Dialogue = "Cama", Once = true },
		Espejo = { Kind = "Espejo", Name = "Espejo", Prompt = "Mirarte", Place = "CasaEspejo", Offset = V(6, 0, 6.4), Look = V(0, 0, -1), Dialogue = "Espejo", Once = true },
		BalonDani = { Kind = "Balon", Name = "Balón", Prompt = false, Place = "CaminoAlCole", Offset = V(-4, 0, 2), Color = Color3.fromRGB(250, 120, 40) },
		AsientoSara = { Kind = "Asiento", Name = "Delante, junto a Sara", Prompt = "Sentarte aquí", Place = "PupitreA", Index = 3, Offset = V(2.4, 0, 0) },
		AsientoNico = { Kind = "Asiento", Name = "Al fondo, junto a Nico", Prompt = "Sentarte aquí", Place = "PupitreA", Index = 14, Offset = V(2.4, 0, 0) },
		AsientoMateo = { Kind = "Asiento", Name = "Junto al niño callado", Prompt = "Sentarte aquí", Place = "PupitreA", Index = 11, Offset = V(2.4, 0, 0) },
		Libro1 = { Kind = "Libro", Name = "Libro de Mateo", Prompt = "Recoger", Place = "Patio", Offset = V(2, 0, -10), Once = true, Color = Color3.fromRGB(200, 60, 60) },
		Libro2 = { Kind = "Libro", Name = "Libro de Mateo", Prompt = "Recoger", Place = "Patio", Offset = V(6.5, 0, -9), Once = true, Color = Color3.fromRGB(60, 120, 200), Spin = 70 },
		Libro3 = { Kind = "Libro", Name = "Cuaderno de Mateo", Prompt = "Recoger", Place = "Patio", Offset = V(5, 0, -14.5), Once = true, Color = Color3.fromRGB(80, 170, 90), Spin = -30 },
		Libro4 = { Kind = "Libro", Name = "Álbum de cromos", Prompt = "Recoger", Place = "Patio", Offset = V(1, 0, -13.5), Once = true, Color = Color3.fromRGB(240, 200, 40), Spin = 10 },
	},

	Steps = {
		-----------------------------------------------------------------
		-- ESCENA 1 · Casa: despertar
		-----------------------------------------------------------------
		{ Type = "Scene", Dialogue = "Despertar", Teleport = "HomeDormitorio", Text = "Despierta: hoy empiezas el cole",
			Actors = { FAMILIA_DORMITORIO, ABU_SALON } },

		-----------------------------------------------------------------
		-- ESCENA 2 · Prepararse (en cualquier orden; la cama y el espejo son opcionales)
		-----------------------------------------------------------------
		{ Type = "Group", Text = "Prepárate para el cole",
			Steps = {
				{ Type = "Use", Prop = "Armario", Text = "Vístete (el armario del dormitorio)" },
				{ Type = "Use", Prop = "Mochila", Text = "Prepara la mochila" },
				{ Type = "Use", Prop = "Desayuno", Text = "Desayuna en la cocina" },
			},
			Props = { "Almohada", "Espejo" },
			Actors = { FAMILIA_COCINA, ABU_SALON },
			Nudge = { After = 110, Every = 80, S = "Familia", T = "¡{nombre}! ¡Que vas a llegar tarde!" },
			Late = { After = 330, Flags = { "LlegasTarde" } } },

		{ Type = "Talk", Npc = "Familia", Dialogue = "Salida", Text = "Dile a {familia} que ya estás listo",
			Actors = { FAMILIA_COCINA, ABU_SALON } },

		-----------------------------------------------------------------
		-- ESCENA 3 · El camino: el balón de Dani
		-----------------------------------------------------------------
		{ Type = "Reach", Place = "CaminoAlCole", Text = "Ve hacia el colegio (sigue la luz)",
			Actors = { FAMILIA_CON_TIGO, DANI }, Props = { "BalonDani" } },
		{ Type = "Scene", Dialogue = "DaniBalon", Actors = { FAMILIA_CON_TIGO, DANI }, Props = { "BalonDani" } },
		{ Type = "MiniGame", Game = "Timing", Title = "Pásale el balón a Dani", Icon = "⚽", Hint = "Pulsa cuando la aguja esté en la zona verde",
			Rounds = 3, Need = 1, Zone = 0.28, Speed = 0.8,
			Win = { Flags = { "PaseADani" }, Rel = { Dani = 10 }, Traits = { Deportividad = 1 } },
			Lose = { Flags = { "FallastePase" } },
			Actors = { FAMILIA_CON_TIGO, DANI }, Props = { "BalonDani" } },
		{ Type = "Scene", Dialogue = "DaniGracias", Actors = { FAMILIA_CON_TIGO, DANI } },

		-----------------------------------------------------------------
		-- ESCENA 4 · La entrada: mucha gente
		-----------------------------------------------------------------
		{ Type = "Reach", Place = "EntradaColegio", Text = "Llega a la entrada del colegio",
			Late = { After = 200, Flags = { "LlegasTarde" } },
			Actors = with(ENTRADA, FAMILIA_CON_TIGO) },
		{ Type = "Scene", Dialogue = "Entrada", Actors = with(ENTRADA, FAMILIA_CON_TIGO) },
		{ Type = "Talk", Npc = "Lucia", Dialogue = "ConoceLucia", Text = "Busca a tu tutora: lleva un jersey amarillo",
			Actors = with(PROFES, ENTRADA[1]) },

		-----------------------------------------------------------------
		-- ESCENA 5 · Conocer el colegio (tres informantes)
		-----------------------------------------------------------------
		{ Type = "Group", Text = "Conoce el colegio", Need = 7,
			Steps = {
				{ Type = "Reach", Place = "BibliotecaColegio", Text = "La biblioteca" },
				{ Type = "Reach", Place = "ComedorColegio", Text = "El comedor" },
				{ Type = "Reach", Place = "Patio", Text = "El patio" },
				{ Type = "Reach", Place = "GimnasioColegio", Text = "El gimnasio" },
				{ Type = "Reach", Place = "CampoColegio", Text = "El campo de fútbol" },
				{ Type = "Talk", Npc = "Iker", Dialogue = "Info_Iker", Text = "Habla con el niño de las gafas (biblioteca)" },
				{ Type = "Talk", Npc = "Vega", Dialogue = "Info_Vega", Text = "Habla con la niña de las pegatinas (comedor)" },
				{ Type = "Talk", Npc = "Ramon", Dialogue = "Info_Ramon", Text = "Habla con Ramón, el conserje (puerta del gimnasio)" },
			},
			Actors = {
				{ Npc = "Iker", Place = "SpotInformanteBiblioteca" },
				{ Npc = "Vega", Place = "SpotInformanteComedor" },
				{ Npc = "Ramon", Place = "SpotGimnasioPuerta" },
			} },
		{ Type = "Reach", Place = "AulaA", Text = "Encuentra tu aula: 1.º A (dentro del edificio)", Actors = CLASE },

		-----------------------------------------------------------------
		-- ESCENA 6 · Primera clase
		-----------------------------------------------------------------
		{ Type = "Scene", Dialogue = "Bienvenida", Actors = CLASE },
		{ Type = "Choice", Key = "Asiento", Text = "Elige dónde sentarte (las sillas brillantes)",
			Options = {
				{ Id = "Sara", Prop = "AsientoSara", Text = "Delante, junto a Sara", Effects = { Rel = { Sara = 8 }, Traits = { Curiosidad = 1 } } },
				{ Id = "Nico", Prop = "AsientoNico", Text = "Al fondo, junto a Nico", Effects = { Rel = { Nico = 8 }, Traits = { Deportividad = 1 } } },
				{ Id = "Mateo", Prop = "AsientoMateo", Text = "Junto al niño callado", Effects = { Rel = { Mateo = 8 }, Traits = { Empatia = 1 } } },
			},
			Actors = CLASE },
		{ Type = "Scene", Dialogue = "Presentaciones", If = { Choices = { Asiento = "Sara" } },
			Teleport = { Place = "PupitreA", Index = 3, Offset = V(2.4, 0, 0) }, Actors = CLASE },
		{ Type = "Scene", Dialogue = "Presentaciones", If = { Choices = { Asiento = "Nico" } },
			Teleport = { Place = "PupitreA", Index = 14, Offset = V(2.4, 0, 0) }, Actors = CLASE },
		{ Type = "Scene", Dialogue = "Presentaciones", If = { Choices = { Asiento = "Mateo" } },
			Teleport = { Place = "PupitreA", Index = 11, Offset = V(2.4, 0, 0) }, Actors = CLASE },
		{ Type = "Class", Subject = "Matematicas", Mode = "Clase", Place = "AulaA", Text = "Tu primera clase: Matemáticas", Actors = CLASE },

		-----------------------------------------------------------------
		-- ESCENA 7 · Recreo: tres grupos
		-----------------------------------------------------------------
		{ Type = "Scene", Dialogue = "Timbre", Actors = CLASE },
		{ Type = "Reach", Place = "Patio", Text = "¡Recreo! Sal al patio", Actors = RECREO },
		{ Type = "Choice", Key = "GrupoRecreo", Text = "Acércate a uno de los grupos",
			Options = {
				{ Id = "Deportistas", Npc = "Nico", Text = "Los deportistas (la cancha)", Dialogue = "Grupo_Deportistas",
					Effects = { Rel = { Nico = 6, Alex = 6 }, Traits = { Deportividad = 1 } } },
				{ Id = "Artistas", Npc = "Omar", Text = "Los artistas (la zona de juegos)", Dialogue = "Grupo_Artistas",
					Effects = { Rel = { Omar = 6, Vega = 6 }, Traits = { Creatividad = 1 } } },
				{ Id = "Estudiantes", Npc = "Sara", Text = "Los curiosos (junto al edificio)", Dialogue = "Grupo_Estudiantes",
					Effects = { Rel = { Sara = 6, Iker = 6 }, Traits = { Curiosidad = 1 } } },
			},
			Actors = RECREO },

		-----------------------------------------------------------------
		-- ESCENA 8 · El problema: a Mateo se le caen los libros
		-----------------------------------------------------------------
		{ Type = "Scene", Dialogue = "LibrosCaen", Actors = with(RECREO, MATEO_PATIO),
			Props = { "Libro1", "Libro2", "Libro3", "Libro4" } },
		{ Type = "Group", Text = "¿Ayudas a Mateo a recoger sus cosas?",
			Steps = {
				{ Type = "Use", Prop = "Libro1", Text = "Libro rojo" },
				{ Type = "Use", Prop = "Libro2", Text = "Libro azul" },
				{ Type = "Use", Prop = "Libro3", Text = "Cuaderno verde" },
				{ Type = "Use", Prop = "Libro4", Text = "Álbum de cromos" },
			},
			Effects = { Flags = { "AyudasteAMateo" }, Rel = { Mateo = 15 }, Traits = { Empatia = 2 }, Memory = "PrimerAmigo",
				Later = { { AfterHours = 1, Start = "Eco_MateoDibujo" } } },
			Timeout = { After = 45, OnlyIfUntouched = true, Flags = { "IgnorasteAMateo" }, Rel = { Mateo = -5 },
				Later = { { AfterHours = 1, Start = "Eco_MateoSolo" } } },
			Actors = with(RECREO, MATEO_PATIO) },
		{ Type = "Scene", Dialogue = "MateoGracias", If = { Flags = { "AyudasteAMateo" } }, Actors = with(RECREO, MATEO_PATIO) },
		{ Type = "Scene", Dialogue = "MateoSolo", If = { Flags = { "IgnorasteAMateo" } }, Actors = with(RECREO, MATEO_PATIO) },

		-----------------------------------------------------------------
		-- FINAL · Vuelta a casa y cena
		-----------------------------------------------------------------
		{ Type = "Scene", Dialogue = "FinDeClases", Actors = { { Npc = "Lucia", Place = "Patio", Offset = V(0, 0, -16) } } },
		{ Type = "Reach", Place = "CasaFamiliar", Text = "Vuelve a casa" },
		{ Type = "Scene", Dialogue = "Cena", Teleport = "HomeCocina",
			Actors = { FAMILIA_COCINA, { Npc = "Abu", Place = "HomeCocina", Offset = V(1.5, 0, -3) } } },
	},

	Dialogues = {
		Despertar = { Lines = {
			{ S = "Narrador", T = "Los Pinos, 7:30 de la mañana. Hoy no es un día cualquiera." },
			{ S = "Familia", T = "¡Buenos días, {nombre}! Arriba, que hoy es un día MUY importante." },
			{ S = "Yo", T = "Mmmm… ¿qué día?" },
			{ S = "Familia", T = "¡Tu primer día de cole! Mochila nueva, profe nueva, amigos nuevos…" },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "Cinco minutitos más…", Effects = { Traits = { Humor = 1 } }, Then = {
					{ S = "Familia", T = "¿Cinco minutitos? Eso decía yo a tu edad. Y siempre llegaba tarde. ¡Arriba!" },
				} },
				{ T = "¡Ya estoy despierto! ¡Ya estoy despierto!", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Familia", T = "¡Así me gusta! Energía de campeón." },
				} },
				{ T = "¿Y si no voy? Me duele… la tripa.", Effects = { Traits = { Humor = 1 } }, Then = {
					{ S = "Familia", T = "Qué casualidad: justo hoy. Eso son nervios, cariño. Se pasan en cuanto llegas." },
					{ S = "Familia", T = "A mí me pasaba igual. Y mira: sobreviví." },
				} },
			} },
			{ S = "Familia", T = "Tienes que vestirte, preparar la mochila y desayunar. El cole empieza a las nueve." },
			{ S = "Familia", T = "Yo estoy en la cocina. Si tardas mucho, llegarás tarde… ¡y la profe lo notará!" },
			{ S = "Narrador", T = "Pulsa E junto a los objetos que brillan para usarlos." },
		} },

		Armario = { Lines = {
			{ S = "Narrador", T = "Tres opciones colgadas. Tres versiones de ti para tu primer día." },
			{ Ask = "¿Qué te pones?", Options = {
				{ T = "La camiseta de dinosaurios 🦖", Effects = { Choice = { Ropa = "Dinosaurios" }, Traits = { Humor = 1 } }, Then = {
					{ S = "Yo", T = "El T-Rex me da poderes. Es un hecho científico." },
				} },
				{ T = "La sudadera azul del cole", Effects = { Choice = { Ropa = "Sudadera" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Yo", T = "Con el escudo del cole. Así ya parezco de allí." },
				} },
				{ T = "La camisa elegante de las fotos", Effects = { Choice = { Ropa = "Camisa" } }, Then = {
					{ S = "Yo", T = "Impecable. Aunque pica un poquito el cuello." },
				} },
			} },
		} },

		Mochila = { Lines = {
			{ S = "Narrador", T = "Estuche, cuaderno, lápices de colores… y en el cajón, tu cromo de la suerte." },
			{ Ask = "¿Te llevas el cromo?", Options = {
				{ T = "¡Claro! Un portero legendario nunca falla.", Effects = { Flags = { "LlevaCromo" }, Items = { CromoSuerte = 1 } }, Then = {
					{ S = "Yo", T = "Al bolsillo pequeño. Para emergencias." },
				} },
				{ T = "Mejor no, no vaya a perderse.", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Yo", T = "Se queda en casa, a salvo. Solo lo del cole." },
				} },
			} },
			{ S = "Narrador", T = "Mochila lista. La encontrarás en tu inventario (tecla E)." },
		}, Effects = { Items = { MochilaCole = 1 } } },

		Desayuno = { Lines = {
			{ S = "Familia", T = "¡Siéntate, que se enfría! ¿Qué te apetece?" },
			{ Ask = "Para desayunar…", Options = {
				{ T = "Tostadas con tomate", Effects = { Needs = { Hunger = 45, Energy = 10 } }, Then = {
					{ S = "Familia", T = "Como tu abu. Con su chorrito de aceite." },
				} },
				{ T = "Cereales con leche", Effects = { Needs = { Hunger = 40, Energy = 15 } }, Then = {
					{ S = "Yo", T = "¡Los que tienen un dinosaurio en la caja!" },
				} },
				{ T = "Fruta… y un poquito de chocolate", Effects = { Needs = { Hunger = 35, Energy = 20 }, Traits = { Humor = 1 } }, Then = {
					{ S = "Familia", T = "Un poquito, he dicho. POQUITO." },
				} },
			} },
			{ S = "Familia", T = "Y bebe algo, que en el cole se corre mucho." },
		} },

		Cama = { Lines = {
			{ S = "Narrador", T = "Estiras la sábana, colocas la almohada… queda casi perfecta." },
			{ S = "Familia", T = "¿Has hecho la cama TÚ SOLO? ¡Hoy es un día histórico!" },
		}, Effects = { Traits = { Responsabilidad = 1 }, Rel = { Familia = 3 } } },

		Espejo = { Lines = {
			{ S = "Narrador", T = "Te miras al espejo. Ensayas." },
			{ Ask = "¿Cómo te presentarás?", Options = {
				{ T = "«Hola, soy {nombre}. ¡Me alegro de conoceros!»", Effects = { Traits = { Valentia = 1 } } },
				{ T = "«¿Qué pasa, gente? Soy {nombre} y vengo a ganar.»", Effects = { Traits = { Humor = 1 } } },
				{ T = "(Sonríes y ya está. Con eso vale.)", Effects = { Traits = { Empatia = 1 } } },
			} },
			{ S = "Narrador", T = "Perfecto. Ya tienes tu frase preparada." },
		}, Effects = { Flags = { "EnsayoEspejo" } } },

		Abu_Suerte = { Lines = {
			{ S = "Abu", T = "Ven aquí, que te vea. ¡Qué mayor! Parece que fue ayer cuando gateabas por esta alfombra." },
			{ S = "Abu", T = "Un consejo de tu abu: en el cole, el que ayuda a los demás nunca está solo." },
		}, Effects = { Rel = { Abu = 3 } } },

		Salida = { Lines = {
			{ S = "Yo", T = "¡Listo todo! Ropa, mochila y desayuno." },
			{ S = "Familia", T = "Deja que te vea… ¡Qué elegancia!", If = { Choices = { Ropa = "Camisa" } } },
			{ S = "Familia", T = "Con los dinosaurios. Muy tú. ¡Me encanta!", If = { Choices = { Ropa = "Dinosaurios" } } },
			{ S = "Familia", T = "¡Con la sudadera del cole! Pareces de sexto.", If = { Choices = { Ropa = "Sudadera" } } },
			{ S = "Familia", T = "Aunque… son las nueve menos cuarto. ¡Corre!", If = { Flags = { "LlegasTarde" } } },
			{ S = "Familia", T = "El cole está cerca. ¿Quieres que te acompañe?" },
			{ Ask = "¿Vas solo o acompañado?", Options = {
				{ T = "Sí, acompáñame, porfa.", Effects = { Choice = { Acompanante = "Familia" }, Rel = { Familia = 3 } }, Then = {
					{ S = "Familia", T = "¡Claro que sí! Pero en la puerta me das un beso rapidito, que ya sé que da vergüenza." },
				} },
				{ T = "¡Voy yo solo, que ya soy mayor!", Effects = { Choice = { Acompanante = "Solo" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Familia", T = "Vale, vale, que ya eres mayor. Ve por la acera y sigue la luz. Te miro desde la ventana." },
				} },
			} },
		} },

		DaniBalon = { Lines = {
			{ S = "Narrador", T = "Un balón naranja rueda hasta tus pies. Un niño pequeño viene corriendo detrás." },
			{ S = "Dani", T = "¡Eh! ¡EH! ¡Ese es mi balón! ¿Me lo pasas? ¡Porfa, porfa, porfa!" },
			{ S = "Familia", T = "Venga, pásaselo. Pero con cuidado, que es pequeñito.", If = { Choices = { Acompanante = "Familia" } } },
		} },

		DaniGracias = { Lines = {
			{ S = "Dani", T = "¡HALA! ¡Qué pase! ¡Eres como los de la tele!", If = { Flags = { "PaseADani" } } },
			{ S = "Dani", T = "Jajaja, se ha ido a la farola. No pasa nada, ¡ya lo cojo yo!", If = { Flags = { "FallastePase" } } },
			{ S = "Dani", T = "Me llamo Dani. Tengo cinco años y MEDIO." },
			{ S = "Dani", T = "Mi hermano Mateo también empieza hoy en tu cole. Es un poco… vergonzoso. No habla casi." },
			{ S = "Dani", T = "¡Si lo ves, dile que Dani dice que se ría más! ¡Adiós!" },
		}, Effects = { Remember = { { Npc = "Dani", Fact = "SeConocen" } } } },

		Entrada = { Lines = {
			{ S = "Narrador", T = "La puerta del colegio es un hervidero: mochilas, abrazos, un autobús amarillo y muchísimo ruido." },
			{ S = "Ramon", T = "¡Buenos días, buenos días! ¡Los mayores, por la izquierda; los de primero, por la puerta grande!" },
			{ S = "Ramon", T = "Uy, ¿y tú? Cara nueva. Me llamo Ramón, soy el conserje. Si algo se rompe, se pierde o se atasca: Ramón." },
			{ S = "Ramon", T = "¿Llegando a las nueve y cuarto el primer día? Tranquilidad, lo apunto en mi libreta de secretos. Jejeje.", If = { Flags = { "LlegasTarde" } } },
			{ S = "Familia", T = "Bueno… aquí te dejo. ¡Pásalo genial! Te espero para cenar y me lo cuentas TODO.", If = { Choices = { Acompanante = "Familia" } } },
			{ S = "Ramon", T = "Tu tutora es Lucía. Está en el vestíbulo. La reconocerás: jersey amarillo y una risa que se oye desde aquí." },
		}, Effects = { Remember = { { Npc = "Ramon", Fact = "SeConocen" } } } },

		Andres_Pista = { Lines = {
			{ S = "Andres", T = "¿Yo, tu tutor? ¡Ojalá! Soy Andrés, el de Educación Física. Me verás con silbato." },
			{ S = "Andres", T = "Lucía es la del jersey amarillo. Y no corras por el pasillo… todavía." },
		} },
		Marta_Pista = { Lines = {
			{ S = "Marta", T = "Hola, cielo. Soy Marta, la profe de música. El piano del fondo es mío." },
			{ S = "Marta", T = "¿Buscas a Lucía? Mira: la amarilla que se está riendo. No tiene pérdida." },
		} },

		ConoceLucia = { Lines = {
			{ S = "Lucia", T = "¡Hola! Tú debes de ser {nombre}. Yo soy Lucía, tu tutora de 1.º A." },
			{ S = "Lucia", T = "Llegas justo a tiempo. Buena señal.", If = { NotFlags = { "LlegasTarde" } } },
			{ S = "Lucia", T = "Un poquito tarde, ¿eh? Hoy te lo perdono. Mañana, a las nueve en punto.", If = { Flags = { "LlegasTarde" } } },
			{ S = "Lucia", T = "Antes de empezar, tengo una misión para ti: conoce el colegio. El patio, la cancha, el campo y el gimnasio." },
			{ S = "Lucia", T = "Por el camino encontrarás gente que te contará cosas. Y luego… encuentra tú solito tu aula. Es la de 1.º A." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "¡Hecho! Me encanta explorar.", Effects = { Traits = { Valentia = 1 }, Rel = { Lucia = 3 } }, Then = {
					{ S = "Lucia", T = "Eso quiero ver. ¡Suerte, y a explorar!" },
				} },
				{ T = "¿Y si me pierdo?", Effects = { Rel = { Lucia = 3 } }, Then = {
					{ S = "Lucia", T = "Entonces preguntas. Preguntar no es de perdidos: es de listos." },
				} },
			} },
		}, Effects = { Remember = { { Npc = "Lucia", Fact = "SeConocen" } } } },

		Info_Iker = { Lines = {
			{ S = "Iker", T = "Shhh… es la biblioteca. Hola. Soy Iker. Dato curioso: aquí hay más de dos mil libros. Me he leído cuarenta y siete." },
			{ S = "Iker", T = "Si buscas 1.º A, está en el edificio principal, a la izquierda del vestíbulo. La otra es 1.º B. Y al fondo, la de música." },
			{ Ask = "¿Qué le contestas?", Options = {
				{ T = "¡Qué listo eres!", Effects = { Rel = { Iker = 5 } }, Then = { { S = "Iker", T = "Ya lo sé. Digo… gracias." } } },
				{ T = "¿Y cuánto mide una pista de tenis?", Effects = { Traits = { Curiosidad = 1 }, Rel = { Iker = 3 } }, Then = {
					{ S = "Iker", T = "¡Veintitrés metros y setenta y siete centímetros! Por fin alguien pregunta." },
				} },
			} },
		} },
		Info_Vega = { Lines = {
			{ S = "Vega", T = "¿Te gustan las pegatinas? Esta brilla en la oscuridad. Y esta huele a fresa." },
			{ S = "Vega", T = "Consejo de experta del comedor: los jueves hay macarrones. Y NUNCA te sientes en la mesa de los de sexto." },
		}, Effects = { Rel = { Vega = 4 } } },
		Info_Ramon = { Lines = {
			{ S = "Ramon", T = "¡Anda, si es la exploración oficial! Esto es el gimnasio. Y al fondo, detrás de la canasta, está el almacén." },
			{ S = "Ramon", T = "En el almacén no se entra sin permiso. Balones, colchonetas… y cosas que llevan AÑOS ahí dentro." },
			{ S = "Ramon", T = "Y si alguna vez pierdes algo en este cole, pregúntame. Yo encuentro de todo." },
		}, Effects = { Flags = { "SabeDelAlmacen" } } },

		Bienvenida = { Lines = {
			{ S = "Lucia", T = "¡Mirad quién ha encontrado el aula! Chicos, chicas: hoy tenemos a alguien nuevo en clase." },
			{ S = "Nico", T = "¿Juegas al fútbol? Necesitamos uno para el recreo." },
			{ S = "Sara", T = "Nico, déjale llegar. Hola. Soy Sara. Tengo ya los deberes de mañana hechos." },
			{ S = "Bruno", T = "Otro más… Como si no fuéramos ya muchos." },
			{ S = "Lucia", T = "Bruno. Eso no se dice. Buscad sitio, que empezamos." },
		} },

		Presentaciones = { Lines = {
			{ S = "Sara", T = "Has elegido bien: aquí delante se entiende todo. Y la pizarra no tiene reflejos.", If = { Choices = { Asiento = "Sara" } } },
			{ S = "Nico", T = "¡Bien! Desde aquí se ve la ventana y el campo. Si miras mucho, Lucía te pilla.", If = { Choices = { Asiento = "Nico" } } },
			{ S = "Narrador", T = "El niño de al lado te mira un segundo y vuelve a su cuaderno. Tiene un álbum de cromos debajo del estuche.", If = { Choices = { Asiento = "Mateo" } } },
			{ S = "Ruben", T = "Psst. Te has sentado en la fila de los guays. Jejeje.", If = { Choices = { Asiento = "Mateo" } } },
			{ S = "Lucia", T = "Vamos a presentarnos. Cada uno dice su nombre y algo que le guste. {nombre}, empiezas tú." },
			{ Ask = "Te toca. ¿Qué dices?", Options = {
				{ T = "Soy {nombre} y me encanta el fútbol.", Effects = { Choice = { Gusto = "Futbol" } }, Then = {
					{ S = "Nico", T = "¡LO SABÍA! ¡Recreo, partido, tú y yo!" },
				} },
				{ T = "Soy {nombre} y me gusta dibujar.", Effects = { Choice = { Gusto = "Dibujar" } }, Then = {
					{ S = "Omar", T = "(Omar levanta el pulgar sin dejar de dibujar)" },
				} },
				{ T = "Soy {nombre} y me encantan los experimentos.", Effects = { Choice = { Gusto = "Ciencia" } }, Then = {
					{ S = "Sara", T = "¿Experimentos de verdad? ¿Con volcanes? Tenemos que hablar." },
				} },
				{ T = "Soy {nombre} y me gusta… dormir cinco minutitos más.", Effects = { Choice = { Gusto = "Dormir" }, Traits = { Humor = 1 } }, Then = {
					{ S = "Narrador", T = "Toda la clase se ríe. Hasta Lucía." },
					{ S = "Lucia", T = "Tomo nota para cuando llegues tarde." },
				} },
			} },
			{ S = "Lucia", T = "Muy bien. Y ahora… ¡matemáticas! Sin quejas, que se oyen desde aquí." },
		} },

		Timbre = { Lines = {
			{ S = "Narrador", T = "¡RIIIING!" },
			{ S = "Lucia", T = "¡Recreo! Tenéis quince minutos. Nada de subirse a la valla, Nico." },
			{ S = "Nico", T = "¡Yo no he hecho nada! …Todavía." },
		} },

		Grupo_Deportistas = { Lines = {
			{ S = "Nico", T = "¡Has venido! Esta es Álex. Es portera. Nadie le mete gol. Bueno, yo a veces." },
			{ S = "Alex", T = "Nunca. Nunca me ha metido gol. Hola." },
			{ S = "Nico", T = "¡Tú dijiste que te gusta el fútbol! Mañana juegas con nosotros.", If = { Choices = { Gusto = "Futbol" } } },
			{ Ask = "¿Qué dices?", Options = {
				{ T = "Te apuesto a que yo sí te marco, Álex.", Effects = { Rel = { Alex = 5 }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Alex", T = "Apuesta aceptada. El que pierda lleva los balones una semana." },
				} },
				{ T = "Yo mejor de defensa, que corro mucho.", Effects = { Rel = { Nico = 5 } }, Then = {
					{ S = "Nico", T = "¡Un defensa! ¡Justo lo que nos faltaba!" },
				} },
			} },
		} },
		Grupo_Artistas = { Lines = {
			{ S = "Omar", T = "…Espera. No te muevas. Te estoy dibujando." },
			{ S = "Vega", T = "Omar dibuja a todo el mundo. Es su forma de decir hola." },
			{ S = "Omar", T = "Ya está. Te he puesto una capa. Quedas mejor con capa." },
			{ S = "Omar", T = "¿Tú también dibujas? Mañana te dejo mi rotulador dorado.", If = { Choices = { Gusto = "Dibujar" } } },
			{ Ask = "¿Qué dices?", Options = {
				{ T = "¡Hala! ¡Me encanta! ¿Me lo regalas?", Effects = { Rel = { Omar = 6 } }, Then = {
					{ S = "Omar", T = "Cuando lo termine. Los dibujos buenos se terminan despacio." },
				} },
				{ T = "¿Y a Vega qué le has puesto?", Effects = { Rel = { Vega = 5 }, Traits = { Humor = 1 } }, Then = {
					{ S = "Vega", T = "Alas. De mariposa. Evidentemente." },
				} },
			} },
		} },
		Grupo_Estudiantes = { Lines = {
			{ S = "Sara", T = "Estábamos discutiendo una cosa importantísima: ¿las hormigas duermen?" },
			{ S = "Iker", T = "Sí. Doscientas cincuenta siestas de un minuto al día. Lo leí." },
			{ S = "Sara", T = "Eso hay que comprobarlo EXPERIMENTALMENTE." },
			{ S = "Sara", T = "¡Tú dijiste que te gustan los experimentos! Estás dentro.", If = { Choices = { Gusto = "Ciencia" } } },
			{ Ask = "¿Qué dices?", Options = {
				{ T = "Yo vigilo el hormiguero con vosotros.", Effects = { Rel = { Sara = 6, Iker = 4 }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Sara", T = "¡Equipo científico formado! Mañana traigo lupa." },
				} },
				{ T = "¿Y los peces? ¿Los peces duermen?", Effects = { Rel = { Iker = 6 } }, Then = {
					{ S = "Iker", T = "…No lo sé. Por primera vez en mi vida, NO LO SÉ." },
				} },
			} },
		} },

		Alex_Recreo = { Lines = {
			{ S = "Alex", T = "Soy la portera. Si Nico te dice que me ha metido gol alguna vez, miente." },
		} },
		Vega_Recreo = { Lines = {
			{ S = "Vega", T = "Omar está dibujando una nube con forma de bocadillo. Todas sus nubes tienen forma de bocadillo." },
		} },
		Iker_Recreo = { Lines = {
			{ S = "Iker", T = "¿Sabías que el recreo se inventó para que los cerebros descansen? Bueno, lo he leído en algún sitio." },
		} },

		LibrosCaen = { Lines = {
			{ S = "Narrador", T = "¡PLAF! A tu lado, un niño tropieza y todo lo que llevaba sale volando: libros, un cuaderno y un álbum de cromos." },
			{ S = "Ruben", T = "¡Jajajaja! ¡Mirad al nuevo número dos!" },
			{ S = "Mateo", T = "…" },
			{ S = "Narrador", T = "Es el niño callado de clase. Mateo. El hermano de Dani.", If = { Flags = { "PaseADani" } } },
			{ S = "Narrador", T = "Puedes ayudarle a recogerlo todo… o seguir con tu recreo." },
		} },
		MateoGracias = { Lines = {
			{ S = "Mateo", T = "G-gracias. Nadie… Bueno. Gracias." },
			{ S = "Mateo", T = "¿Fuiste tú quien le pasó el balón a mi hermano esta mañana? No para de hablar de ti.", If = { Flags = { "PaseADani" } } },
			{ S = "Mateo", T = "Dani dice que alguien esta mañana casi le da a una farola con su balón. ¿Fuiste tú? Jeje.", If = { Flags = { "FallastePase" } } },
			{ S = "Mateo", T = "Me llamo Mateo. Colecciono cromos. Tengo repetido el portero legendario, por si… por si lo quieres." },
			{ S = "Yo", T = "¡Yo tengo ese cromo! Es mi cromo de la suerte.", If = { Flags = { "LlevaCromo" } } },
			{ S = "Mateo", T = "¿En serio? Entonces… somos del mismo equipo.", If = { Flags = { "LlevaCromo" } } },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "¿Mañana te sientas conmigo?", Effects = { Rel = { Mateo = 8 } }, Then = {
					{ S = "Mateo", T = "(Mateo sonríe por primera vez en todo el día) Vale." },
				} },
				{ T = "Tu hermano dice que te rías más.", Effects = { Rel = { Mateo = 5 }, Traits = { Humor = 1 } }, Then = {
					{ S = "Mateo", T = "Jajaja… Dani siempre dice eso. Es un pesado. Pero tiene razón." },
				} },
			} },
		} },
		MateoSolo = { Lines = {
			{ S = "Narrador", T = "Mateo recoge sus cosas él solo, sin levantar la vista. Rubén sigue riéndose." },
			{ S = "Narrador", T = "Mateo se va a comer su bocadillo al rincón más lejano del patio." },
		} },

		FinDeClases = { Lines = {
			{ S = "Narrador", T = "El resto del día pasa volando: más clases, más nombres nuevos, más ruido." },
			{ S = "Lucia", T = "¡Hasta mañana! Y recordad: mañana, con la mochila. ¡Que siempre hay alguno que se la deja!" },
			{ S = "Ramon", T = "(desde la puerta) ¡O que la pierde! ¡Jejeje!" },
		} },

		Cena = { Lines = {
			{ S = "Familia", T = "¡Por fin! Siéntate, que he hecho macarrones. ¿Y bien? ¿Qué tal tu primer día?" },
			{ S = "Abu", T = "Cuéntanoslo todo. Con detalles, que yo ya no me entero de nada." },
			{ Ask = "¿Qué les cuentas primero?", Options = {
				{ T = "¡He hecho un amigo! Se llama Mateo.", If = { Flags = { "AyudasteAMateo" } }, Effects = { Rel = { Familia = 3 } }, Then = {
					{ S = "Abu", T = "¿Ves? Lo que te dije: el que ayuda nunca está solo." },
				} },
				{ T = "Me he sentado con Sara. ¡Sabe muchísimo!", If = { Choices = { Asiento = "Sara" } }, Then = {
					{ S = "Familia", T = "Una buena compañera de pupitre vale oro. Ya verás en los exámenes." },
				} },
				{ T = "Nico dice que mañana juego al fútbol con ellos.", If = { Choices = { GrupoRecreo = "Deportistas" } }, Then = {
					{ S = "Familia", T = "¡Pues habrá que lavar esas zapatillas!" },
				} },
				{ T = "Un niño que se llama Omar me ha dibujado con capa.", If = { Choices = { GrupoRecreo = "Artistas" } }, Then = {
					{ S = "Abu", T = "¡Un superhéroe en la familia! Ya era hora." },
				} },
				{ T = "Hemos investigado si las hormigas duermen.", If = { Choices = { GrupoRecreo = "Estudiantes" } }, Then = {
					{ S = "Abu", T = "¿Y duermen? …¿No? ¿Todavía no lo sabéis? Qué emoción." },
				} },
				{ T = "Ha sido un rollo. Bueno… no tanto.", Effects = { Traits = { Humor = 1 } }, Then = {
					{ S = "Familia", T = "«No tanto» en idioma de niño significa «me lo he pasado genial». Lo sé." },
				} },
			} },
			{ S = "Familia", T = "¿Y ese niño que se cayó? ¿Nadie le ayudó? Mañana, si le ves solo, ve con él.", If = { Flags = { "IgnorasteAMateo" } } },
			{ S = "Familia", T = "Qué orgullo, de verdad. Primer día: superado." },
			{ S = "Narrador", T = "Primer día de colegio: completado. Pero esto… no ha hecho más que empezar." },
		} },
	},
}
