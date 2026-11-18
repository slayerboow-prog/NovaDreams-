-- ACTO II · LA COALICIÓN (2/3): MIASMA, SIROCO y NIVALIS (18-11-2026; biblia: docs/historia/historia-principal-15h.md).
-- Capítulos Coalicion_Miasma, Coalicion_Siroco y Coalicion_Nivalis. Cada mundo: llegar (hay que volar allí), entender
-- su herida, ganarse a su gente con una decisión difícil y cerrar su grieta en terreno hostil.
--   MIASMA  ciudades colgadas sobre niebla tóxica; abajo vive el Anclaje Seis, al que dejaron caer. La grieta está abajo.
--   SIROCO  desierto, agua que se compra con deudas; el pozo más hondo es una grieta y alguien cobra por cerrarla.
--   NIVALIS noche eterna desde que el Consorcio apagó su sol artificial; los faroles mantienen fuera la oscuridad.
-- Para +17: tragedia, humor seco (Cosme, ILEN), decisiones grises. Todo se juega.

local V = Vector3.new

local function at(npc: string, place: string, x: number, z: number, mode: string?): { [string]: any }
	return { Npc = npc, Place = place, Offset = V(x, 0, z), Mode = mode }
end
local COSME_SIGUE = { Npc = "Cosme", Mode = "Follow" }
local SOREL_SIGUE = { Npc = "Sorel", Mode = "Follow" }

local function main(chapter: string, t: { [string]: any }): { [string]: any }
	t.Kind = "Main"
	t.Chapter = chapter
	t.AgeRange = t.AgeRange or { 18, 45 }
	t.Difficulty = t.Difficulty or 4
	return t
end

return {
	---------------------------------------------------------------------
	-- MIASMA · 1
	---------------------------------------------------------------------
	main("Coalicion_Miasma", {
		Id = "Mia01_Niebla",
		Title = "Respirar a medias",
		Description = "Miasma: ciudades colgadas de cables sobre un mar de niebla venenosa. Dicen que debajo no vive nadie. Dicen.",
		Duration = { 20, 25 },
		Type = "La Coalición · Miasma",
		Next = { "Mia02_Bajo" },
		Moment = "Llegaste a Miasma",
		Npcs = { "Cosme", "Sorel", "MaraSolis", "BrumaTaller", "ILEN" },
		Locations = { "Miasma_Plataforma", "Miasma_Taller", "Miasma_BordeLastre" },
		Rewards = { Money = 5500 },
		Props = {
			Mascara = { Kind = "Caja", Name = "Máscaras de filtro en una taquilla", Prompt = "Coger una máscara", Place = "Miasma_Taller", Offset = V(-4, 0, 2), Dialogue = "Mascara", Once = true },
			Cable = { Kind = "Maquina", Name = "Un cable cortado que cuelga hacia la niebla", Prompt = "Examinar el corte", Place = "Miasma_BordeLastre", Offset = V(4, 0, 6), Dialogue = "Corte", Once = true },
			Nota = { Kind = "Papel", Name = "Una nota atada al cable", Prompt = "Leer la nota", Place = "Miasma_BordeLastre", Offset = V(-4, 0, 8), Dialogue = "Nota", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "PlanetLanded", Match = { Planet = "Miasma" }, Text = "Vuela a Miasma (el planeta verde de nubes) y aterriza" },
			{ Type = "Scene", Dialogue = "Llegada", Actors = { at("MaraSolis", "Miasma_Plataforma", 4, 4), at("Cosme", "Miasma_Plataforma", -3, 2) } },
			{ Type = "Reach", Place = "Miasma_Taller", Text = "Mara te lleva al taller: sin máscara no aguantarás ni diez minutos", Actors = { at("BrumaTaller", "Miasma_Taller", 3, 4), COSME_SIGUE } },
			{ Type = "Use", Prop = "Mascara", Text = "Coge una máscara de filtro" },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Miasma" }, Text = "Usa la máscara cuando suba el nivel de toxinas (mira el medidor)" },
			{ Type = "Reach", Place = "Miasma_BordeLastre", Text = "Ve al Borde del Lastre, donde se cortaron los cables del Anclaje Seis", Actors = { at("MaraSolis", "Miasma_BordeLastre", 0, 4), SOREL_SIGUE } },
			{ Type = "Group", Text = "Investiga el borde",
				Steps = {
					{ Type = "Use", Prop = "Cable", Text = "El cable cortado" },
					{ Type = "Use", Prop = "Nota", Text = "La nota atada al cable" },
				} },
			{ Type = "Scene", Dialogue = "Verdad", Actors = { at("MaraSolis", "Miasma_BordeLastre", 0, 4) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "Ciudades enteras colgando de cables sobre un mar verde y espeso que se mueve como si respirara. Góndolas oxidadas cruzan de un anclaje a otro." },
				{ S = "MaraSolis", T = "Mara Solis, capitana del Anclaje Siete. ¿Coalición? ¿Otra empresa que viene a salvarnos? La última fue el Consorcio. Nos dejaron una grieta en el fondo y una factura." },
				{ S = "Cosme", T = "Nosotros no cobramos, señora. Bueno, yo cobro, pero en conversación." },
				{ S = "ILEN", T = "Aviso: el aire exterior contiene catorce compuestos que yo calificaría de «poco recomendables». Y dos que calificaría de «¿en serio?»." },
			} },
			Mascara = { Lines = {
				{ S = "Narrador", T = "La máscara huele a goma vieja y a quien la usó antes. Por dentro, alguien ha rayado una marca por cada día que sobrevivió con ella puesta. Hay muchas." },
			} },
			Corte = { Lines = {
				{ S = "Narrador", T = "El cable no se rompió: lo cortaron. Con una cizalla industrial, limpio. Del otro lado, la niebla. Abajo, muy abajo, luces." },
			} },
			Nota = { Lines = {
				{ S = "Narrador", T = "Un papel plastificado, atado con alambre: «Anclaje Seis. Seguimos aquí. 2.300 personas. No nos olvidéis». Fecha: hace once años." },
			} },
			Verdad = { Lines = {
				{ S = "MaraSolis", T = "Hace once años, cuando el Consorcio abrió la grieta, la niebla subió. Los anclajes pesaban demasiado. El Consejo de Miasma decidió soltar el Seis para que los demás no cayeran." },
				{ S = "MaraSolis", T = "Mi padre cortó ese cable. Le ordenaron hacerlo. Luego se tiró detrás." },
				{ S = "MaraSolis", T = "Siguen vivos. A veces oímos una canción por la radio, desde abajo. Y la grieta está debajo de ellos. Si queréis cerrarla, tendréis que bajar a la niebla. Y mirarles a la cara." },
			}, Effects = { Rel = { MaraSolis = 6 } } },
		},
	}),

	main("Coalicion_Miasma", {
		Id = "Mia02_Bajo",
		Title = "Los que dejamos caer",
		Description = "Bajar en góndola a la niebla, al Anclaje Seis. Hace once años que nadie de arriba lo hace.",
		Duration = { 20, 25 },
		Type = "La Coalición · Miasma",
		Next = { "Mia03_Fondo" },
		Moment = "Bajaste al Anclaje Seis",
		Npcs = { "Cosme", "Sorel", "MaraSolis", "ComandanteAndres", "ILEN" },
		Locations = { "Miasma_Gondolas", "Miasma_GondolaNiebla", "Miasma_Antena" },
		Rewards = { Money = 5500 },
		Props = {
			Freno = { Kind = "Maquina", Name = "El freno de la góndola, oxidado", Prompt = "Soltar el freno", Place = "Miasma_Gondolas", Offset = V(3, 0, 2), Dialogue = "Freno", Once = true },
			Antena = { Kind = "Maquina", Name = "La antena del Seis", Prompt = "Reparar la antena", Place = "Miasma_Antena", Offset = V(0, 0, 4), Dialogue = "Antena", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Miasma_Gondolas", Text = "Ve a las góndolas con Mara", Actors = { at("MaraSolis", "Miasma_Gondolas", 2, 4), SOREL_SIGUE } },
			{ Type = "Use", Prop = "Freno", Text = "Suelta el freno de la góndola" },
			{ Type = "MiniGame", Game = "Timing", Title = "Bajar a la niebla", Icon = "🚡", Hint = "El cable cruje: frena en el verde para que la góndola no se desboque",
				Rounds = 4, Need = 3, Zone = 0.24, Speed = 1.05,
				Win = { Flags = { "GondolaSuave" } }, Lose = { Flags = { "GondolaGolpe" } } },
			{ Type = "Scene", Dialogue = "Abajo", Actors = { at("ComandanteAndres", "Miasma_GondolaNiebla", 0, 8), at("MaraSolis", "Miasma_GondolaNiebla", -4, 2) } },
			{ Type = "Event", Event = "BeastKilled", Count = 8, Match = { Planet = "Miasma" }, Text = "Las bestias de la niebla atacan el Seis cada noche. Defiéndelo ({count}/{total})" },
			{ Type = "Use", Prop = "Antena", Text = "Repara la antena del Seis para que puedan hablar con arriba" },
			{ Type = "Choice", Key = "MiaSeis", Text = "El Seis quiere subir. Pero si 2.300 personas suben de golpe, los anclajes de arriba no aguantarán el peso. ¿Qué propones?",
				Options = {
					{ Id = "Todos", Text = "Que suban todos poco a poco, reforzando los anclajes con material de la Coalición", Effects = { Flags = { "SeisSube" }, Rel = { ComandanteAndres = 8, MaraSolis = 4 } } },
					{ Id = "Ninos", Text = "Que suban primero los enfermos y los críos; el resto, cuando se cierre la grieta", Effects = { Flags = { "SeisPrioridad" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("ComandanteAndres", "Miasma_GondolaNiebla", 0, 8), at("MaraSolis", "Miasma_GondolaNiebla", -4, 2) } },
		},
		Dialogues = {
			Freno = { Lines = {
				{ S = "MaraSolis", T = "Nadie ha bajado en once años. El cable aguanta. Creo. Si no aguanta, lo sabremos enseguida." },
				{ S = "ILEN", T = "Os diría las probabilidades, pero Sorel me ha pedido que deje de decir probabilidades." },
			} },
			Abajo = { Lines = {
				{ S = "Narrador", T = "La niebla se abre y aparece el Anclaje Seis: una ciudad oxidada, inclinada, encendida con hogueras. Gente con máscaras remendadas mira la góndola como si fuera un fantasma." },
				{ S = "ComandanteAndres", T = "Comandante Andrés, del Seis. ¿Mara? ¿Mara Solis? Eres igual que tu padre." },
				{ S = "MaraSolis", T = "Él cortó vuestro cable." },
				{ S = "ComandanteAndres", T = "Lo sé. Y luego bajó con nosotros. Saltó. Vivió nueve años aquí abajo. Nos enseñó a filtrar el aire. Está enterrado junto a la antena." },
				{ S = "Narrador", T = "Mara no dice nada. Se quita la máscara un segundo para secarse los ojos, y vuelve a ponérsela." },
			} },
			Antena = { Lines = {
				{ S = "Narrador", T = "Junto a la antena, una tumba con una placa: «Solis. Cortó el cable. Bajó a pedir perdón. Se lo dimos»." },
				{ S = "Narrador", T = "La antena chisporrotea y se enciende. Por primera vez en once años, el Seis puede hablar con arriba." },
			} },
		},
	}),

	main("Coalicion_Miasma", {
		Id = "Mia03_Fondo",
		Title = "El fondo de la niebla",
		Description = "Debajo del Anclaje Seis, en el fondo de todo, la grieta de Miasma escupe niebla. Allí abajo no hay cables. Ni vuelta atrás fácil.",
		Duration = { 22, 28 },
		Difficulty = 5,
		Type = "La Coalición · Miasma",
		Moment = "Cerraste la grieta de Miasma",
		Npcs = { "Cosme", "Sorel", "MaraSolis", "ComandanteAndres", "ILEN" },
		Locations = { "Miasma_GondolaNiebla", "Miasma_Torre" },
		Rewards = { Money = 8000, Flags = { "GrietaMiasmaCerrada" } },
		Props = {
			Ancla = { Kind = "Cristal", Name = "El ancla de la grieta, envuelta en niebla", Prompt = "Colocar el disruptor", Place = "Miasma_GondolaNiebla", Offset = V(0, 0, 12), Dialogue = "Ancla", Once = true },
			Filtro = { Kind = "Maquina", Name = "Un filtro de aire abandonado del Consorcio", Prompt = "Arrancar el filtro", Place = "Miasma_GondolaNiebla", Offset = V(-8, 0, 4), Dialogue = "Filtro", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Miasma_GondolaNiebla", Text = "Baja al fondo, donde nace la niebla", Actors = { SOREL_SIGUE } },
			{ Type = "Use", Prop = "Filtro", Text = "Arranca el viejo filtro del Consorcio para limpiar el aire alrededor de la grieta" },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Planet = "Miasma" }, Text = "La niebla está llena de bestias que han cruzado. Abre paso ({count}/{total})", Actors = { SOREL_SIGUE } },
			{ Type = "Use", Prop = "Ancla", Text = "Coloca el disruptor en el ancla de la grieta" },
			{ Type = "MiniGame", Game = "Timing", Title = "Cerrar la grieta de Miasma", Icon = "🌀", Hint = "Sincroniza el disruptor con los pulsos de la grieta: pulsa en el verde",
				Rounds = 5, Need = 3, Zone = 0.22, Speed = 1.2,
				Win = { Flags = { "MiasmaCierreLimpio" } }, Lose = { Flags = { "MiasmaCierreSucio" } } },
			{ Type = "Scene", Dialogue = "Sorel", Actors = { at("Sorel", "Miasma_GondolaNiebla", -3, 4, "Sit") } },
			{ Type = "Reach", Place = "Miasma_Torre", Text = "Sube con Sorel a la torre del Siete antes de que se le acabe el filtro", Actors = { SOREL_SIGUE } },
			{ Type = "Scene", Dialogue = "Cielo", Actors = { at("MaraSolis", "Miasma_Torre", 3, 3), at("ComandanteAndres", "Miasma_Torre", -3, 3), at("Cosme", "Miasma_Torre", 0, 6) } },
		},
		Dialogues = {
			Filtro = { Lines = {
				{ S = "Narrador", T = "Una máquina enorme con el logotipo del Consorcio, oxidada. Una placa: «Unidad de contención de residuos. Desactivada por recorte de costes»." },
				{ S = "Narrador", T = "Recorte de costes. Once años de niebla por un recorte de costes." },
			} },
			Ancla = { Lines = {
				{ S = "Narrador", T = "El ancla late en la niebla como un corazón enfermo. Cada once segundos, la niebla sube un poco más." },
			} },
			Sorel = { Lines = {
				{ S = "Narrador", T = "La grieta se cierra con un estruendo sordo. La niebla deja de subir. Pero Sorel se ha sentado en el suelo, tosiendo: su filtro está roto." },
				{ S = "Sorel", T = "Estoy bien. Estoy… un poco mareada. ¿Siempre dan vueltas las cosas aquí abajo?" },
				{ S = "ILEN", T = "Nivel de oxígeno de Sorel: preocupante. Recomiendo subir. Ya. Esta vez no estoy siendo sarcástica." },
			} },
			Cielo = { Lines = {
				{ S = "Narrador", T = "Sorel se recupera con oxígeno de la torre. Y mientras, la niebla de Miasma empieza a bajar. Despacio. Por primera vez en once años, desde lo alto del Siete se ven los tejados del Seis." },
				{ S = "MaraSolis", T = "Los veo. Les veo las caras. Están saludando." },
				{ S = "ComandanteAndres", T = "Miasma se une a la Coalición. Los de arriba y los de abajo. Juntos, por primera vez." },
				{ S = "Cosme", T = "Tres grietas cerradas. Digo dos. Dos de siete. Las matemáticas a esta edad son como las escaleras: se suben con esfuerzo." },
				{ S = "Sorel", T = "(con la mascarilla de oxígeno, débil) La próxima vez el filtro lo reviso yo. …Gracias por subirme." },
			}, Effects = { Rel = { Sorel = 8, MaraSolis = 6 } } },
		},
	}),

	---------------------------------------------------------------------
	-- SIROCO
	---------------------------------------------------------------------
	main("Coalicion_Siroco", {
		Id = "Sir01_Sed",
		Title = "El precio del agua",
		Description = "Siroco: un desierto donde el agua se compra a crédito y las deudas se heredan. Alguien ha puesto precio a cerrar la grieta.",
		Duration = { 20, 25 },
		Type = "La Coalición · Siroco",
		Next = { "Sir02_Deuda" },
		Moment = "Llegaste a Siroco",
		Npcs = { "Cosme", "Sorel", "RafaQuiroga", "LuzPozo", "ILEN" },
		Locations = { "Siroco_Plataforma", "Siroco_Zoco", "Siroco_Fuente" },
		Rewards = { Money = 5500 },
		Props = {
			Fuente = { Kind = "Maquina", Name = "La fuente pública, con un candado", Prompt = "Mirar el candado", Place = "Siroco_Fuente", Offset = V(0, 0, 4), Dialogue = "Fuente", Once = true },
			Libro = { Kind = "Libro", Name = "El libro de deudas del aguador", Prompt = "Leer el libro", Place = "Siroco_Zoco", Offset = V(4, 0, 2), Dialogue = "Deudas", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "PlanetLanded", Match = { Planet = "Siroco" }, Text = "Vuela a Siroco (el planeta de arena) y aterriza" },
			{ Type = "Scene", Dialogue = "Llegada", Actors = { at("Cosme", "Siroco_Plataforma", 3, 2), at("Sorel", "Siroco_Plataforma", -3, 2) } },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Siroco" }, Text = "El calor de Siroco mata en una hora: usa su contramedida cuando el medidor suba" },
			{ Type = "Reach", Place = "Siroco_Fuente", Text = "Ve a la fuente pública de la ciudad", Actors = { COSME_SIGUE } },
			{ Type = "Use", Prop = "Fuente", Text = "Mira la fuente" },
			{ Type = "Reach", Place = "Siroco_Zoco", Text = "Ve al zoco a buscar al aguador", Actors = { at("RafaQuiroga", "Siroco_Zoco", 2, 4), COSME_SIGUE } },
			{ Type = "Use", Prop = "Libro", Text = "El aguador ha dejado su libro abierto. Léelo" },
			{ Type = "Talk", Npc = "RafaQuiroga", Dialogue = "Rafa", Text = "Habla con Rafa Quiroga, el aguador", Actors = { at("RafaQuiroga", "Siroco_Zoco", 2, 4) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "Dunas hasta el horizonte. Una ciudad de adobe alrededor de un arco de piedra. El aire tiembla de calor. En las paredes, carteles: «AGUA. PAGA HOY, BEBE MAÑANA»." },
				{ S = "Cosme", T = "En mi mapa pone «llevar agua». Debí ser más específico. Debí poner «llevar MUCHA agua»." },
				{ S = "ILEN", T = "Temperatura exterior: 54 grados. Temperatura de mi paciencia con los chistes de Cosme: similar." },
			} },
			Fuente = { Lines = {
				{ S = "Narrador", T = "La fuente pública tiene un candado grueso y una placa nueva: «Propiedad de Aguas del Pozo S.L., filial del Consorcio Umbral»." },
			} },
			Deudas = { Lines = {
				{ S = "Narrador", T = "Páginas y páginas de nombres y cantidades. Algunas deudas vienen de abuelos. Una línea en rojo: «Familia Pozo. Deuda total. Ejecutar el lunes»." },
			} },
			Rafa = { Lines = {
				{ S = "RafaQuiroga", T = "Rafa Quiroga, aguador. Sí, cobro el agua. No, no me gusta. Si no la cobro yo, la cobra alguien peor." },
				{ S = "RafaQuiroga", T = "El pozo más hondo de Siroco es vuestra grieta. El Consorcio sacaba agua del otro lado. Cuando se fueron, vendieron el pozo a Luz Pozo." },
				{ S = "RafaQuiroga", T = "Luz cobra a todo el desierto por el agua de esa grieta. Si la cerráis, se acaba el agua. Y Luz tiene a medio desierto con rifles para que nadie la toque." },
			} },
		},
	}),

	main("Coalicion_Siroco", {
		Id = "Sir02_Deuda",
		Title = "Luz Pozo",
		Description = "La dueña del agua de Siroco. Una mujer que no hace nada por maldad: hace todo por miedo. Y tiene un ejército.",
		Duration = { 20, 25 },
		Type = "La Coalición · Siroco",
		Next = { "Sir03_Tormenta" },
		Moment = "Te enfrentaste a Luz Pozo",
		Npcs = { "Cosme", "Sorel", "RafaQuiroga", "LuzPozo", "Saqueador1", "Saqueador2", "ILEN" },
		Locations = { "Siroco_CasaLuz", "Siroco_Arco" },
		Rewards = { Money = 5500 },
		Props = {
			Mapa = { Kind = "Papel", Name = "Planos de un acuífero, en la mesa de Luz", Prompt = "Mirar los planos", Place = "Siroco_CasaLuz", Offset = V(-4, 0, 2), Dialogue = "Planos", Once = true },
		},
		Steps = {
			{ Type = "Escape", Place = "Siroco_CasaLuz", Respawn = "Siroco_Arco", Catch = 4,
				Text = "Cruza hasta la casa de Luz Pozo sin que te paren sus guardias",
				CaughtLine = "(Un guardia te empuja de vuelta a la plaza.) La señora no recibe a extranjeros. Fuera.",
				Actors = {
					{ Npc = "Saqueador1", Place = "Siroco_Arco", Offset = V(10, 0, 12), Mode = "Hunt", Speed = 9, Prompt = false },
					{ Npc = "Saqueador2", Place = "Siroco_Arco", Offset = V(-10, 0, 14), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Use", Prop = "Mapa", Text = "En la mesa de Luz hay unos planos. Míralos" },
			{ Type = "Talk", Npc = "LuzPozo", Dialogue = "Luz", Text = "Luz Pozo te ha visto. Habla con ella", Actors = { at("LuzPozo", "Siroco_CasaLuz", 2, 4) } },
			{ Type = "Choice", Key = "SirLuz", Text = "Los planos muestran un acuífero natural, enorme, bajo el desierto. Luz lo sabe y lo calla para no perder el negocio. ¿Qué haces?",
				Options = {
					{ Id = "Trato", Text = "Ofrecerle un trato: que dirija el acuífero para todos, sin deudas, y la Coalición la protege", Effects = { Flags = { "LuzTrato" }, Rel = { LuzPozo = 8 } } },
					{ Id = "Publico", Text = "Contárselo a todo Siroco desde el arco: el agua es de todos", Effects = { Flags = { "LuzExpuesta" }, Rel = { RafaQuiroga = 8, LuzPozo = -10 }, Traits = { Rebeldia = 1 } } },
				},
				Actors = { at("LuzPozo", "Siroco_CasaLuz", 2, 4) } },
			{ Type = "Fight", Place = "Siroco_CasaLuz", Respawn = "Siroco_CasaLuz", Action = "Golpe ⚔", HP = 5, If = { Choices = { SirLuz = "Publico" } },
				Text = "Los guardias de Luz no te dejarán salir con los planos. Ábrete paso ({count}/{total})",
				CaughtLine = "(Te tiran contra la pared de adobe. Te levantas con los planos todavía en la mano.)",
				Enemies = {
					{ Npc = "Saqueador1", Offset = V(8, 0, 6), Speed = 11, HP = 3, Bye = "¡Vale! ¡Vale! Yo también tengo sed, ¿sabes?" },
					{ Npc = "Saqueador2", Offset = V(-8, 0, 6), Speed = 11, HP = 3, Bye = "Si de verdad hay agua para todos… vete. Corre." },
				} },
			{ Type = "Scene", Dialogue = "Despues", Actors = { at("RafaQuiroga", "Siroco_Arco", 2, 4), at("Cosme", "Siroco_Arco", -2, 4) } },
		},
		Dialogues = {
			Planos = { Lines = {
				{ S = "Narrador", T = "Un estudio geológico del Consorcio, de hace veinte años. Bajo el desierto hay un acuífero natural que daría agua a todo Siroco durante siglos. Al margen, a mano: «No divulgar. Afecta al modelo de negocio»." },
			} },
			Luz = { Lines = {
				{ S = "LuzPozo", T = "Así que has visto los planos. Siéntate. ¿Agua? Invita la casa. Es broma: aquí nada es gratis." },
				{ S = "LuzPozo", T = "Mi madre murió de sed cuando yo tenía doce años porque no podía pagar. Me juré que yo nunca tendría sed. Y no la tengo." },
				{ S = "LuzPozo", T = "Si cierras la grieta, el desierto se queda sin el agua del pozo. El acuífero tardaría meses en abrirse. Meses de sed. ¿Quién paga eso?" },
			} },
			Despues = { Lines = {
				{ S = "RafaQuiroga", T = "Agua bajo nuestros pies. Doscientos años pagando por agua que estaba bajo nuestros pies." },
				{ S = "RafaQuiroga", T = "Abriremos el acuífero. Necesitaremos tiempo. Y que la grieta se cierre antes de la tormenta de fuego, o la tormenta la abrirá del todo." },
				{ S = "Cosme", T = "¿Tormenta de fuego? En mi mapa no pone nada de tormentas de fuego." },
				{ S = "RafaQuiroga", T = "Su mapa está muy incompleto, abuelo." },
			} },
		},
	}),

	main("Coalicion_Siroco", {
		Id = "Sir03_Tormenta",
		Title = "Tormenta de fuego",
		Description = "Cada once años, el desierto de Siroco arde. Este año la tormenta llega con la grieta abierta en el centro. Hay que cerrarla dentro de la tormenta.",
		Duration = { 22, 28 },
		Difficulty = 5,
		Type = "La Coalición · Siroco",
		Moment = "Cerraste la grieta de Siroco en la tormenta",
		Npcs = { "Cosme", "Sorel", "RafaQuiroga", "LuzPozo", "ILEN" },
		Locations = { "Siroco_Cementerio", "Siroco_PlazaArco" },
		Rewards = { Money = 8000, Flags = { "GrietaSirocoCerrada" } },
		Props = {
			Ancla = { Kind = "Cristal", Name = "El ancla de la grieta, en el fondo del pozo", Prompt = "Colocar el disruptor", Place = "Siroco_Cementerio", Offset = V(0, 0, 10), Dialogue = "Ancla", Once = true },
			Tumba = { Kind = "Marcador", Name = "Una tumba con una cantimplora encima", Prompt = "Mirar la tumba", Place = "Siroco_Cementerio", Offset = V(-6, 0, 4), Dialogue = "Tumba", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Siroco_Cementerio", Text = "El pozo de la grieta está bajo el viejo cementerio. Llega antes que la tormenta", Actors = { SOREL_SIGUE } },
			{ Type = "Use", Prop = "Tumba", Text = "Una tumba junto al pozo" },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Planet = "Siroco" }, Text = "La tormenta empuja a las bestias del desierto hacia el pozo. Aguanta ({count}/{total})", Actors = { SOREL_SIGUE } },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Siroco" }, Text = "La tormenta de fuego está encima: protégete del calor" },
			{ Type = "Use", Prop = "Ancla", Text = "Coloca el disruptor en el ancla" },
			{ Type = "MiniGame", Game = "Timing", Title = "Cerrar la grieta de Siroco", Icon = "🌀", Hint = "El viento te empuja: sincroniza el disruptor en el verde",
				Rounds = 5, Need = 3, Zone = 0.2, Speed = 1.25,
				Win = { Flags = { "SirocoCierreLimpio" } }, Lose = { Flags = { "SirocoCierreSucio" } } },
			{ Type = "Reach", Place = "Siroco_PlazaArco", Text = "Vuelve a la ciudad: algo pasa en la plaza", Actors = { SOREL_SIGUE } },
			{ Type = "Scene", Dialogue = "Lluvia", Actors = { at("RafaQuiroga", "Siroco_PlazaArco", 2, 4), at("LuzPozo", "Siroco_PlazaArco", -4, 4), at("Cosme", "Siroco_PlazaArco", 0, 8) } },
		},
		Dialogues = {
			Tumba = { Lines = {
				{ S = "Narrador", T = "Una tumba pequeña con una cantimplora oxidada encima. Grabado: «Ana Pozo. Murió de sed. Su hija nunca la tendrá»." },
				{ S = "Narrador", T = "Hay flores frescas. En el desierto, flores frescas cuestan más que el agua." },
			} },
			Ancla = { Lines = {
				{ S = "Narrador", T = "En el fondo del pozo, el ancla brilla entre la arena que cae. La tormenta ruge arriba como un tren que no termina de pasar." },
			} },
			Lluvia = { Lines = {
				{ S = "Narrador", T = "Cuando la grieta se cierra, la tormenta de fuego se queda sin lo que la alimentaba. Y entonces pasa algo que nadie en Siroco ha visto en su vida: llueve." },
				{ S = "Narrador", T = "Gente en la plaza con la cara hacia arriba. Niños que no saben qué es. Viejos que lloran. Luz Pozo, sola en medio de la plaza, empapada." },
				{ S = "LuzPozo", T = "Llevaba treinta años sin mojarme. Se me había olvidado cómo era. …Mi madre habría bailado." },
				{ S = "RafaQuiroga", T = "Siroco se une a la Coalición. Con agua para todos. Y yo voy a romper ese libro de deudas página por página." },
				{ S = "Cosme", T = "Tres de siete. Ahora sí. He contado con los dedos." },
				{ S = "ILEN", T = "Detecto cierta humedad en la cara de Cosme. Asumo que es la lluvia." },
				{ S = "Cosme", T = "Es la lluvia." },
			}, Effects = { Rel = { RafaQuiroga = 8, Cosme = 4 } } },
		},
	}),

	---------------------------------------------------------------------
	-- NIVALIS
	---------------------------------------------------------------------
	main("Coalicion_Nivalis", {
		Id = "Niv01_Noche",
		Title = "La noche larga",
		Description = "Nivalis lleva siete años de noche. El Consorcio apagó su sol artificial cuando dejó de ser rentable. Solo los faroles mantienen fuera lo que vive en la oscuridad.",
		Duration = { 20, 25 },
		Type = "La Coalición · Nivalis",
		Next = { "Niv02_Faroles" },
		Moment = "Llegaste a Nivalis",
		Npcs = { "Cosme", "Sorel", "Tila", "PrincesaIlse", "ILEN" },
		Locations = { "Nivalis_Plataforma", "Nivalis_Plaza", "Nivalis_Biblioteca" },
		Rewards = { Money = 5500 },
		Props = {
			Farol = { Kind = "Maquina", Name = "Un farol apagado en la calle", Prompt = "Volver a encender el farol", Place = "Nivalis_Plaza", Offset = V(6, 0, 4), Dialogue = "Farol", Once = true },
			Contrato = { Kind = "Papel", Name = "El contrato del sol, enmarcado", Prompt = "Leer el contrato", Place = "Nivalis_Biblioteca", Offset = V(0, 0, 4), Dialogue = "Contrato", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "PlanetLanded", Match = { Planet = "Nivalis" }, Text = "Vuela a Nivalis (el planeta helado) y aterriza" },
			{ Type = "Scene", Dialogue = "Llegada", Actors = { at("Tila", "Nivalis_Plataforma", 3, 4), at("Cosme", "Nivalis_Plataforma", -3, 2) } },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Nivalis" }, Text = "El frío y la oscuridad de Nivalis matan: usa su contramedida cuando el medidor suba" },
			{ Type = "Reach", Place = "Nivalis_Plaza", Text = "Ve a la plaza con Tila", Actors = { { Npc = "Tila", Mode = "Follow" } } },
			{ Type = "Use", Prop = "Farol", Text = "Un farol de la plaza se ha apagado. Enciéndelo antes de que llegue algo" },
			{ Type = "Event", Event = "BeastKilled", Count = 6, Match = { Planet = "Nivalis" }, Text = "Algo ha entrado por la zona oscura. Échalo ({count}/{total})" },
			{ Type = "Reach", Place = "Nivalis_Biblioteca", Text = "La princesa Ilse te espera en la biblioteca", Actors = { at("PrincesaIlse", "Nivalis_Biblioteca", 2, 4) } },
			{ Type = "Use", Prop = "Contrato", Text = "Lee el contrato enmarcado de la pared" },
			{ Type = "Talk", Npc = "PrincesaIlse", Dialogue = "Ilse", Text = "Habla con la princesa Ilse", Actors = { at("PrincesaIlse", "Nivalis_Biblioteca", 2, 4) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "Oscuridad total. Nieve que cae sin hacer ruido. Y en medio, una ciudad iluminada solo por faroles de luz amarilla, uno cada diez metros, como un collar en la nada." },
				{ S = "Tila", T = "No salgáis de la luz. Nunca. Ni un paso. Lo que vive en la oscuridad no se ve hasta que está encima." },
				{ S = "Cosme", T = "«Llevar luz», ponía en mi mapa. Traigo una linterna. ¿Cuenta?" },
				{ S = "Tila", T = "Una linterna aquí es como un caramelo para un oso. Apágala." },
			} },
			Farol = { Lines = {
				{ S = "Narrador", T = "Giras la manivela del farol. La luz vuelve con un parpadeo. Fuera del círculo amarillo, algo se retira con un ruido de uñas sobre hielo." },
			} },
			Contrato = { Lines = {
				{ S = "Narrador", T = "«Contrato de suministro solar. El Consorcio Umbral proporcionará luz y calor a Nivalis a cambio del 40 % de su producción de cristal. Cláusula 19: el Consorcio podrá interrumpir el suministro si deja de ser rentable»." },
				{ S = "Narrador", T = "Cláusula 19. Siete años de noche por la cláusula 19." },
			} },
			Ilse = { Lines = {
				{ S = "PrincesaIlse", T = "Princesa Ilse. Mi padre firmó ese contrato. Cuando apagaron el sol, se encerró en la torre y no ha vuelto a hablar." },
				{ S = "PrincesaIlse", T = "El sol artificial sigue ahí arriba, en la montaña. Apagado. Lo alimentaba la grieta. Si la cerráis sin volver a encender el sol, Nivalis se congelará del todo." },
				{ S = "PrincesaIlse", T = "Hay que hacer las dos cosas a la vez. Y la grieta está en la zona oscura. Donde no llega ningún farol." },
			}, Effects = { Rel = { PrincesaIlse = 6 } } },
		},
	}),

	main("Coalicion_Nivalis", {
		Id = "Niv02_Faroles",
		Title = "Un camino de luz",
		Description = "Para llegar a la grieta hay que cruzar la zona oscura. Y para cruzarla, hay que llevar la luz contigo, farol a farol.",
		Duration = { 20, 25 },
		Type = "La Coalición · Nivalis",
		Next = { "Niv03_Sol" },
		Moment = "Abriste un camino de luz en Nivalis",
		Npcs = { "Cosme", "Sorel", "Tila", "PrincesaIlse", "ILEN" },
		Locations = { "Nivalis_TorreFarol", "Nivalis_Farol1", "Nivalis_Farol2", "Nivalis_Farol3" },
		Rewards = { Money = 5500 },
		Props = {
			F1 = { Kind = "Maquina", Name = "Farol de camino 1", Prompt = "Encender el farol", Place = "Nivalis_Farol1", Offset = V(0, 0, 2), Dialogue = "Farol", Once = true },
			F2 = { Kind = "Maquina", Name = "Farol de camino 2", Prompt = "Encender el farol", Place = "Nivalis_Farol2", Offset = V(0, 0, 2), Dialogue = "Farol", Once = true },
			F3 = { Kind = "Maquina", Name = "Farol de camino 3", Prompt = "Encender el farol", Place = "Nivalis_Farol3", Offset = V(0, 0, 2), Dialogue = "Farol3", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Nivalis_TorreFarol", Text = "Ve a la torre del farolero con Tila", Actors = { { Npc = "Tila", Mode = "Follow" } } },
			{ Type = "Group", Text = "Enciende los faroles del camino hacia la zona oscura", Actors = { { Npc = "Tila", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "F1", Text = "El primer farol" },
					{ Type = "Use", Prop = "F2", Text = "El segundo farol" },
					{ Type = "Use", Prop = "F3", Text = "El tercer farol" },
				} },
			{ Type = "Event", Event = "BeastKilled", Count = 8, Match = { Planet = "Nivalis" }, Text = "La oscuridad responde a la luz. Defiende el camino ({count}/{total})" },
			{ Type = "Scene", Dialogue = "Tila", Actors = { at("Tila", "Nivalis_Farol3", 2, 2) } },
			{ Type = "Choice", Key = "NivTila", Text = "Tila quiere quedarse vigilando el último farol para que no se apague mientras bajáis a la grieta. Si algo viene, estará sola en la oscuridad. ¿Qué haces?",
				Options = {
					{ Id = "Dejar", Text = "Dejar que se quede: el camino de vuelta depende de ese farol", Effects = { Flags = { "TilaFarol" }, Rel = { Tila = 4 } } },
					{ Id = "Sorel", Text = "Pedirle a Sorel que se quede con ella", Effects = { Flags = { "SorelFarol" }, Rel = { Sorel = 4, Tila = 6 } } },
				},
				Actors = { at("Tila", "Nivalis_Farol3", 2, 2) } },
		},
		Dialogues = {
			Farol = { Lines = {
				{ S = "Narrador", T = "El farol se enciende. Un círculo de luz amarilla sobre la nieve. Un paso más hacia la oscuridad." },
			} },
			Farol3 = { Lines = {
				{ S = "Narrador", T = "El último farol. Más allá, la zona oscura: un negro tan espeso que parece una pared. Dentro, a lo lejos, un resplandor violeta. La grieta." },
			} },
			Tila = { Lines = {
				{ S = "Tila", T = "Mi hermano era farolero. Una noche se le apagó este farol. Le encontramos por la mañana… bueno, por la noche, aquí siempre es de noche. Le encontramos." },
				{ S = "Tila", T = "Desde entonces no dejo que se apague ninguno. Si este se apaga mientras estáis dentro, no encontraréis el camino de vuelta." },
			} },
		},
	}),

	main("Coalicion_Nivalis", {
		Id = "Niv03_Sol",
		Title = "Encender el sol",
		Description = "Cerrar la grieta en la zona oscura y, al mismo tiempo, volver a encender el sol artificial de la montaña. Si falla una de las dos cosas, Nivalis muere.",
		Duration = { 22, 28 },
		Difficulty = 5,
		Type = "La Coalición · Nivalis",
		Moment = "Devolviste el sol a Nivalis",
		Npcs = { "Cosme", "Sorel", "Tila", "PrincesaIlse", "ILEN" },
		Locations = { "Nivalis_Pasadizo", "Nivalis_Mirador" },
		Rewards = { Money = 8000, Flags = { "GrietaNivalisCerrada" } },
		Props = {
			Ancla = { Kind = "Cristal", Name = "El ancla de la grieta, en la oscuridad", Prompt = "Colocar el disruptor", Place = "Nivalis_Pasadizo", Offset = V(0, 0, 10), Dialogue = "Ancla", Once = true },
			Sol = { Kind = "Maquina", Name = "El panel del sol artificial", Prompt = "Desviar la energía de la grieta al sol", Place = "Nivalis_Pasadizo", Offset = V(-8, 0, 4), Dialogue = "Panel", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Nivalis_Pasadizo", Text = "Entra en la zona oscura y llega a la grieta", Actors = { COSME_SIGUE } },
			{ Type = "Event", Event = "BeastKilled", Count = 10, Match = { Planet = "Nivalis" }, Text = "En la oscuridad hay cosas que no se ven hasta que atacan. Sobrevive ({count}/{total})", Actors = { COSME_SIGUE } },
			{ Type = "Use", Prop = "Sol", Text = "Prepara el desvío de energía hacia el sol de la montaña" },
			{ Type = "Use", Prop = "Ancla", Text = "Coloca el disruptor en el ancla" },
			{ Type = "MiniGame", Game = "Timing", Title = "Cerrar y encender a la vez", Icon = "☀", Hint = "Dos pulsos a la vez: cierra la grieta y pasa la energía al sol, en el verde",
				Rounds = 6, Need = 4, Zone = 0.2, Speed = 1.2,
				Win = { Flags = { "NivalisCierreLimpio" } }, Lose = { Flags = { "NivalisCierreSucio" } } },
			{ Type = "Reach", Place = "Nivalis_Mirador", Text = "Sube al mirador de la ciudad", Actors = { COSME_SIGUE } },
			{ Type = "Scene", Dialogue = "Amanecer", Actors = { at("PrincesaIlse", "Nivalis_Mirador", 3, 3), at("Tila", "Nivalis_Mirador", -3, 3), at("Cosme", "Nivalis_Mirador", 0, 6) } },
		},
		Dialogues = {
			Panel = { Lines = {
				{ S = "Cosme", T = "Esto lo diseñó alguien que odiaba a la humanidad. Doscientos botones y ninguno pone «encender»." },
				{ S = "ILEN", T = "Botón 117. Luego el 4. Luego reza." },
				{ S = "Cosme", T = "¿Eso de rezar es técnico?" },
				{ S = "ILEN", T = "Es estadístico." },
			} },
			Ancla = { Lines = {
				{ S = "Narrador", T = "El ancla brilla violeta en la negrura. A su alrededor, la nieve no cae: flota." },
			} },
			Amanecer = { Lines = {
				{ S = "Narrador", T = "Sobre la montaña, un punto de luz. Luego una línea. Luego el sol artificial de Nivalis se enciende y la luz cae sobre la ciudad como agua." },
				{ S = "Narrador", T = "Siete años de noche. La gente sale a las calles y se tapa los ojos con las manos y no puede dejar de mirar." },
				{ S = "PrincesaIlse", T = "Mi padre ha salido de la torre. Está en el balcón. Llorando como un niño. No le había visto llorar nunca." },
				{ S = "Tila", T = "Los faroles. Ya no hacen falta los faroles. …No sé qué hacer con las manos." },
				{ S = "PrincesaIlse", T = "Nivalis se une a la Coalición. Y rompemos la cláusula 19." },
				{ S = "Cosme", T = "Cuatro de siete. Quedan tres. A este paso me jubilo de héroe." },
				{ S = "ILEN", T = "Recibo una transmisión de Valmar. Prioridad máxima. Es Brenn." },
				{ S = "Narrador", T = "La voz de Brenn, cortada por interferencias: «…Varn ha vuelto… con un ejército… dicen que la Marea ya ha tocado Umbría… volved…»" },
			}, Effects = { Rel = { PrincesaIlse = 8, Tila = 6 } } },
		},
	}),
}
