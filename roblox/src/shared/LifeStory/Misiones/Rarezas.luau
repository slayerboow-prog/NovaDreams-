-- RAREZAS DE LA GRIETA: secundarias cortas (10-15 min) con cosas absurdas que se cuelan por la Grieta.
-- Ficha de diseño: docs/historia/13-saga-de-la-grieta.md («Secundarias»)
--
-- Todas piden haber visto la Grieta (Saga_02) y dan una pieza de la colección «Restos de la Grieta».
-- Dos por etapa (primer lote):
--   Rareza_Buzon      Niño         «El buzón que escribe al pasado»
--   Rareza_Farola     Niño         «La farola que canta ópera» (de noche)
--   Rareza_Perro      Adolescente  «El perro que ladra en binario»
--   Rareza_Espaguetis Adolescente  «Lluvia de espaguetis»
--   Rareza_Piso13     Universidad  «El piso 13»
--   Rareza_Reloj      Universidad  «El reloj que va hacia atrás»
--   Rareza_Semaforo   Adulto       «El semáforo con opiniones»
--   Rareza_Nube       Adulto       «La nube que te sigue»

local V = Vector3.new

local function rareza(stage: { [string]: string }, extra: { [string]: any }?): { [string]: any }
	local req = { Stage = stage, Completed = { "Saga_02_Grieta" } }
	for key, value in extra or {} do
		req[key] = value
	end
	return req
end

local NINO = { Min = "Nino", Max = "Nino" }
local ADOLESCENTE = { Min = "Adolescente", Max = "Adolescente" }
local UNI = { Min = "AdultoJoven", Max = "AdultoJoven" }
local ADULTO = { Min = "Adulto" }

return {
	---------------------------------------------------------------------
	-- Niño · El buzón que escribe al pasado
	---------------------------------------------------------------------
	{
		Id = "Rareza_Buzon",
		Kind = "Side",
		Title = "El buzón que escribe al pasado",
		Description = "El buzón amarillo de Correos devuelve las cartas… con fecha de ayer. Y con tu letra.",
		Type = "Rareza de la Grieta · Infancia",
		Duration = { 10, 15 },
		Npcs = { "Pip" },
		Offer = { Place = "Correos" },
		OfferKey = "El buzón de Correos hace «glup». Sale una carta. Va dirigida a ti. La letra es la tuya",
		Requires = rareza(NINO),
		Moment = "Te escribiste una carta a ti mismo (desde ayer)",
		Memory = "BuzonPasado",
		Rewards = { Items = { SelloDelAyer = 1 } },
		Props = {
			Buzon = { Kind = "Kiosco", Name = "El buzón amarillo", Prompt = "Coger la carta", Place = "Correos", Offset = V(0, 0, 4), Color = Color3.fromRGB(240, 200, 40), Dialogue = "Carta", Once = true },
			Fuente = { Kind = "Papel", Name = "Un papel mojado en la fuente", Prompt = "Coger el papel", Place = "FuenteParque", Offset = V(2, 0, 2), Dialogue = "Papel", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Buzon", Text = "Coge la carta del buzón" },
			{ Type = "Use", Prop = "Fuente", Text = "Ve a la fuente del parque, como dice la carta" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Cuéntaselo a Pip",
				Actors = { { Npc = "Pip", Place = "FuenteParque", Offset = V(-3, 0, 2) } } },
		},
		Dialogues = {
			Carta = { Lines = {
				{ S = "Narrador", T = "«Querido yo de ayer: soy tú, de hoy. Mañana, o sea hoy, ve a la fuente del parque. Allí hay algo que se nos olvidó. Firmado: tú. P. D.: No te comas el yogur de fresa. Está raro.»" },
				{ S = "Narrador", T = "La fecha del matasellos es la de ayer. La letra es la tuya. Tú no has escrito ninguna carta. Todavía." },
			} },
			Papel = { Lines = {
				{ S = "Narrador", T = "Un papel doblado, mojado, pegado al borde de la fuente. Pone, con tu letra: «¿Ves? Ya lo has encontrado. Ahora escribe tú la carta de ayer, que si no, se rompe el tiempo»." },
				{ S = "Narrador", T = "Dentro hay un sello. Brilla un poco verde. Como la línea del cielo." },
			} },
			Pip = { Lines = {
				{ S = "Pip", T = "Un sello del ayer. Lo que cae por la Grieta a veces se queda enredado en el tiempo. El señor Cosme lo llama «pelusa temporal»." },
				{ S = "Pip", T = "Consejo de robot: escriba la carta esta noche y échela al buzón. Así todo cuadra. Y no se coma el yogur de fresa." },
				{ S = "Yo", T = "¿Tú sabes lo del yogur?" },
				{ S = "Pip", T = "Yo lo sé todo sobre los yogures del barrio. Es mi única afición." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Niño · La farola que canta ópera
	---------------------------------------------------------------------
	{
		Id = "Rareza_Farola",
		Kind = "Side",
		Title = "La farola que canta ópera",
		Description = "Una farola del parque canta ópera por las noches. Los vecinos no pegan ojo. La farola dice que está ensayando.",
		Type = "Rareza de la Grieta · Infancia",
		Duration = { 10, 15 },
		Npcs = { "Pip" },
		Offer = { Place = "Parque" },
		OfferKey = "Una farola del parque está cantando ópera. Muy alto. Muy desafinado",
		Requires = rareza(NINO, { Hours = { From = 19, To = 23 } }),
		Moment = "Le enseñaste a cantar a una farola",
		Memory = "FarolaOpera",
		Rewards = { Items = { BombillaTenor = 1 } },
		Props = {
			Farola = { Kind = "Maquina", Name = "La farola tenor", Place = "Parque", Offset = V(4, 0, 6), Color = Color3.fromRGB(255, 230, 150), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Queja", Text = "Pip te espera junto a la farola",
				Props = { "Farola" }, Actors = { { Npc = "Pip", Place = "Parque", Offset = V(2, 0, 4) } } },
			{ Type = "MiniGame", Game = "Timing", Title = "Clase de canto", Icon = "🎶", Hint = "Da la nota justo cuando la bombilla brilla",
				Rounds = 5, Need = 3, Zone = 0.28, Speed = 1,
				Win = { Flags = { "FarolaAfinada" } }, Lose = { Traits = { Humor = 1 } },
				Props = { "Farola" }, Actors = { { Npc = "Pip", Place = "Parque", Offset = V(2, 0, 4), Mode = "Cheer" } } },
			{ Type = "Scene", Dialogue = "Final", Props = { "Farola" }, Actors = { { Npc = "Pip", Place = "Parque", Offset = V(2, 0, 4) } } },
		},
		Dialogues = {
			Queja = { Lines = {
				{ S = "Narrador", T = "(La farola) «¡FÍÍÍGAROOO! ¡FÍGARO, FÍGARO, FÍGAROOOO!»" },
				{ S = "Pip", T = "Le cayó encima una chispa de la Grieta y ahora cree que es tenor. Tenor de ópera. Ha pedido un camerino." },
				{ S = "Pip", T = "No podemos apagarla: la Grieta la ha dejado con voluntad propia. Pero podemos afinarla. Usted cante con ella. Yo no puedo: mi altavoz solo hace «bip»." },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "(La farola, muy bajito, afinadísima) «Fígaro… Fígaro…». Se apaga un momento. Cuando vuelve a encenderse, solo tararea. Los vecinos aplauden desde las ventanas.", If = { Flags = { "FarolaAfinada" } } },
				{ S = "Narrador", T = "(La farola, igual de desafinada, pero ahora a dúo contigo) Los vecinos cierran las ventanas. Alguien grita «¡bravo!». Con ironía, seguramente.", If = { NotFlags = { "FarolaAfinada" } } },
				{ S = "Pip", T = "Le ha regalado una bombilla de repuesto. Dice que es «para su futuro como artista». No sé qué significa. Suena caro." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adolescente · El perro que ladra en binario
	---------------------------------------------------------------------
	{
		Id = "Rareza_Perro",
		Kind = "Side",
		Title = "El perro que ladra en binario",
		Description = "Un perro del parque ladra «guau-guau, guau, guau-guau-guau». Pip dice que es código binario. Y que está pidiendo ayuda.",
		Type = "Rareza de la Grieta · Adolescencia",
		Duration = { 12, 16 },
		Npcs = { "Pip" },
		Offer = { Place = "JuegosParque" },
		OfferKey = "Un perro te ladra en un ritmo rarísimo. Largo, corto, corto, largo…",
		Requires = rareza(ADOLESCENTE),
		Moment = "Tradujiste los ladridos de un perro binario",
		Memory = "PerroBinario",
		Rewards = { Items = { ChapaBinaria = 1 } },
		Props = {
			Perro = { Kind = "Animal", Name = "Un perro que ladra en binario", Prompt = "Escuchar al perro", Place = "JuegosParque", Offset = V(3, 0, 3), Color = Color3.fromRGB(170, 120, 70), Dialogue = "Ladridos", Once = true },
			Libro = { Kind = "Libro", Name = "«Informática para torpes (1987)»", Prompt = "Buscar la tabla binaria", Place = "Biblioteca", Offset = V(0, 0, 4), Dialogue = "Tabla", Once = true },
			Hueso = { Kind = "Caja", Name = "Una caja enterrada junto al columpio", Prompt = "Desenterrar", Place = "ColumpiosParque", Offset = V(2, 0, 2), Dialogue = "Caja", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Perro", Text = "Escucha al perro" },
			{ Type = "Use", Prop = "Libro", Text = "Busca en la biblioteca cómo se lee el binario" },
			{ Type = "Use", Prop = "Hueso", Text = "Ve donde dice el perro: junto a los columpios" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Enséñaselo a Pip",
				Actors = { { Npc = "Pip", Place = "ColumpiosParque", Offset = V(-3, 0, 2) } } },
		},
		Dialogues = {
			Ladridos = { Lines = {
				{ S = "Narrador", T = "«Guau-guau. Guau. Guau-guau-guau. Guau.» El perro te mira como si fueras un poco lento. Lo vuelve a repetir. Más despacio." },
			} },
			Tabla = { Lines = {
				{ S = "Narrador", T = "Guau largo = 1, guau corto = 0. Traduces con la tabla del libro. El perro dice: «C-O-L-U-M-P-I-O. H-U-E-S-O. N-O-  E-S  M-Í-O». " },
				{ S = "Narrador", T = "Alguien ha subrayado la tabla con rotulador verde. En el margen: «Para Pip. Por si algún día lo necesita. — C.»" },
			} },
			Caja = { Lines = {
				{ S = "Narrador", T = "Una caja de metal. Dentro, un hueso de juguete que hace «bip», y una chapa con unos y ceros. El perro la mira, mueve la cola y se va. Misión cumplida, al parecer." },
			} },
			Pip = { Lines = {
				{ S = "Pip", T = "Esa chapa es mía. De cuando era un prototipo. El señor Cosme me la quitó para que no me escapara con los perros del parque. Yo quería ser perro. Es una etapa." },
				{ S = "Pip", T = "La Grieta despertó algo de código en ese perro. Y el código buscó a su dueño. …Qué raro me siento. Creo que esto es emoción. O un cortocircuito." },
				{ S = "Pip", T = "Quédesela usted. Yo ya no quiero ser perro. Quiero ser lo que soy. Un robot con amigos." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adolescente · Lluvia de espaguetis
	---------------------------------------------------------------------
	{
		Id = "Rareza_Espaguetis",
		Kind = "Side",
		Title = "Lluvia de espaguetis",
		Description = "Sobre la plaza del centro está lloviendo… espaguetis. Con tomate. Los paraguas no sirven de nada.",
		Type = "Rareza de la Grieta · Adolescencia",
		Duration = { 10, 15 },
		Npcs = { "Pip" },
		Offer = { Place = "PlazaCentro" },
		OfferKey = "Cae algo del cielo sobre la plaza. Es blando. Es largo. Son espaguetis",
		Requires = rareza(ADOLESCENTE),
		Moment = "Cerraste la nube de espaguetis de la plaza",
		Memory = "LluviaEspaguetis",
		Rewards = { Items = { TenedorCosmico = 1 } },
		Props = {
			Nube = { Kind = "Portal", Name = "Un agujerito de la Grieta que gotea pasta", Place = "PlazaCentro", Offset = V(0, 0, 8), Color = Color3.fromRGB(230, 200, 120), Prompt = false },
			Plato1 = { Kind = "Moco", Name = "Un montón de espaguetis", Prompt = "Recoger", Place = "PlazaCentro", Offset = V(-6, 0, 4), Color = Color3.fromRGB(240, 210, 130), Dialogue = "Recoger", Once = true },
			Plato2 = { Kind = "Moco", Name = "Espaguetis en la fuente", Prompt = "Recoger", Place = "PlazaCentro", Offset = V(6, 0, 4), Color = Color3.fromRGB(240, 210, 130), Dialogue = "Recoger", Once = true },
			Plato3 = { Kind = "Moco", Name = "Espaguetis en un banco", Prompt = "Recoger", Place = "PlazaCentro", Offset = V(0, 0, -6), Color = Color3.fromRGB(240, 210, 130), Dialogue = "Recoger", Once = true },
			Tenedor = { Kind = "Maquina", Name = "Un tenedor gigante clavado en el suelo", Prompt = "Enrollar el agujero", Place = "PlazaCentro", Offset = V(0, 0, 10), Dialogue = "Enrollar", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip ha venido con un paraguas (inútil)",
				Props = { "Nube" }, Actors = { { Npc = "Pip", Place = "PlazaCentro", Offset = V(3, 0, 5) } } },
			{ Type = "Group", Text = "Recoge los espaguetis antes de que se peguen al suelo", Props = { "Nube" },
				Steps = {
					{ Type = "Use", Prop = "Plato1", Text = "Los del suelo" },
					{ Type = "Use", Prop = "Plato2", Text = "Los de la fuente" },
					{ Type = "Use", Prop = "Plato3", Text = "Los del banco" },
				} },
			{ Type = "Use", Prop = "Tenedor", Text = "Enrolla el agujero con el tenedor gigante", Props = { "Nube" } },
			{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Pip", Place = "PlazaCentro", Offset = V(3, 0, 5), Mode = "Cheer" } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Un agujerito de la Grieta se ha abierto justo encima de una dimensión donde todo es pasta. Allí llueve pasta. Aquí, por culpa del agujero, también." },
				{ S = "Pip", T = "Plan: recoger los espaguetis antes de que se peguen, y enrollar el agujero como se enrolla la pasta. Con tenedor. Lo dice el manual del señor Cosme, página «emergencias italianas»." },
			} },
			Recoger = { Lines = {
				{ S = "Narrador", T = "Espaguetis al dente. Perfectos. Un poco de tomate. Huelen a domingo en casa de {abu}." },
			} },
			Enrollar = { Lines = {
				{ S = "Narrador", T = "Metes el tenedor en el agujero y giras. Una vuelta. Dos. El agujero se enrolla como un ovillo de pasta… y se cierra con un «slurp». Deja de llover." },
			} },
			Final = { Lines = {
				{ S = "Pip", T = "Agujero cerrado. Plaza limpia. Y ciento doce raciones de espaguetis para el comedor social. El señor Cosme estaría orgulloso. Y con hambre." },
				{ S = "Pip", T = "El tenedor se ha encogido. Ahora es de bolsillo. Dicen que en la dimensión de la pasta es un objeto sagrado. Guárdelo. Por si llueve." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Universidad · El piso 13
	---------------------------------------------------------------------
	{
		Id = "Rareza_Piso13",
		Kind = "Side",
		Title = "El piso 13",
		Description = "El ascensor de la biblioteca tiene un botón nuevo: el 13. La biblioteca tiene tres plantas.",
		Type = "Rareza de la Grieta · Universidad",
		Duration = { 12, 16 },
		Npcs = { "CazadorTiempo", "Candela" },
		Offer = { Place = "Biblioteca" },
		OfferKey = "En el ascensor de la biblioteca hay un botón que antes no estaba: el 13",
		Requires = rareza(UNI, { Completed = { "Saga_02_Grieta", "Uni01b_Residencia" } }),
		Moment = "Subiste al piso 13 (que no existe)",
		Memory = "Piso13",
		Rewards = { Items = { BotonPiso13 = 1 } },
		Props = {
			Boton = { Kind = "Maquina", Name = "El botón del piso 13", Prompt = "Pulsar el 13", Place = "Biblioteca", Offset = V(0, 0, 4), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Boton", Once = true },
			Mesa = { Kind = "Libro", Name = "Una mesa llena de exámenes que nadie ha escrito", Prompt = "Mirar los exámenes", Place = "Biblioteca", Offset = V(-4, 0, 6), Dialogue = "Examenes", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Candela", Dialogue = "Candela", Text = "Candela también ha visto el botón",
				Actors = { { Npc = "Candela", Place = "Biblioteca", Offset = V(3, 0, 3) } } },
			{ Type = "Use", Prop = "Boton", Text = "Pulsa el botón del 13" },
			{ Type = "Transition", Text = "El ascensor sube. Y sube. Y sube. Suena música de ascensor al revés. Se abren las puertas: una planta idéntica a la biblioteca, pero todo está en silencio. Muy en silencio.", Seconds = 4, Teleport = "Biblioteca" },
			{ Type = "Use", Prop = "Mesa", Text = "Investiga el piso 13" },
			{ Type = "Talk", Npc = "CazadorTiempo", Dialogue = "Cronos", Text = "Alguien te espera junto a la ventana",
				Actors = { { Npc = "CazadorTiempo", Place = "Biblioteca", Offset = V(4, 0, 8) }, { Npc = "Candela", Place = "Biblioteca", Offset = V(-3, 0, 3) } } },
		},
		Dialogues = {
			Candela = { Lines = {
				{ S = "Candela", T = "La biblioteca tiene tres plantas. Lo sé porque las he contado. Muchas veces. Me relaja contar plantas." },
				{ S = "Candela", T = "Y ahora hay un 13. Mi cerebro dice «no». Mi curiosidad dice «pulsa». Mi curiosidad siempre gana. Pulsa tú, que yo apunto." },
			} },
			Boton = { Lines = {
				{ S = "Narrador", T = "El botón está calentito. Al pulsarlo, se ilumina de verde. Como la línea del cielo." },
			} },
			Examenes = { Lines = {
				{ S = "Narrador", T = "Exámenes de todas las asignaturas. Con las respuestas. Todos con fecha de dentro de un mes. Uno tiene tu nombre. Está en blanco." },
				{ S = "Narrador", T = "Te pica la curiosidad. Pero algo te dice que, si lo lees, algo se rompe. Lo dejas donde estaba." },
			} },
			Cronos = { Lines = {
				{ S = "CazadorTiempo", T = "Ancla. El piso 13 es un pliegue. Aquí se guarda lo que todavía no ha pasado. Muy práctico para la Aduana. Muy mala idea para estudiantes." },
				{ S = "CazadorTiempo", T = "No has leído tu examen. Bien. La mayoría lo lee. Luego suspenden igual, por los nervios. El tiempo es así de rencoroso." },
				{ S = "CazadorTiempo", T = "Toma el botón. Sin él, el ascensor ya no subirá aquí. Y, por favor, no le cuentes a nadie que existe el piso 13. Hay una lista de espera de trescientos años." },
				{ S = "Candela", T = "Lo apunto en mi Excel de «cosas imposibles». Pestaña nueva: «Ascensores»." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Universidad · El reloj que va hacia atrás
	---------------------------------------------------------------------
	{
		Id = "Rareza_Reloj",
		Kind = "Side",
		Title = "El reloj que va hacia atrás",
		Description = "El reloj de la residencia va hacia atrás. Y cada vez que da la hora, a alguien se le «desaprende» algo.",
		Type = "Rareza de la Grieta · Universidad",
		Duration = { 12, 16 },
		Npcs = { "Ivan", "Portero" },
		Offer = { Place = "Residencia" },
		OfferKey = "El reloj de la entrada hace «cot-tic». Al revés. Iván se ha olvidado de cómo se atan los cordones",
		Requires = rareza(UNI, { Completed = { "Saga_02_Grieta", "Uni01b_Residencia" } }),
		Moment = "Arreglaste el reloj que desenseñaba cosas",
		Memory = "RelojAtras",
		Rewards = { Items = { EngranajeAlReves = 1 } },
		Props = {
			Reloj = { Kind = "Maquina", Name = "El reloj de la entrada (va al revés)", Place = "Residencia", Offset = V(0, 0, 5), Color = Color3.fromRGB(160, 120, 70), Prompt = false },
			Engranaje1 = { Kind = "Maquina", Name = "Un engranaje verde en la cocina", Prompt = "Coger el engranaje", Place = "CocinaResidencia", Offset = V(2, 0, 2), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Pieza", Once = true },
			Engranaje2 = { Kind = "Maquina", Name = "Un engranaje verde en tu cuarto", Prompt = "Coger el engranaje", Place = "HabitacionResidencia", Offset = V(-2, 0, 2), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Pieza", Once = true },
			Arreglar = { Kind = "Maquina", Name = "La tapa del reloj", Prompt = "Poner los engranajes al derecho", Place = "Residencia", Offset = V(0, 0, 4), Dialogue = "Arreglar", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Portero", Dialogue = "Pilar", Text = "Habla con Doña Pilar", Props = { "Reloj" },
				Actors = { { Npc = "Portero", Place = "Residencia", Offset = V(3, 0, 4) }, { Npc = "Ivan", Place = "Residencia", Offset = V(-3, 0, 4), Mode = "Sit" } } },
			{ Type = "Group", Text = "Busca los engranajes que se han escapado del reloj",
				Steps = {
					{ Type = "Use", Prop = "Engranaje1", Text = "En la cocina" },
					{ Type = "Use", Prop = "Engranaje2", Text = "En tu habitación" },
				} },
			{ Type = "Use", Prop = "Arreglar", Text = "Arregla el reloj", Props = { "Reloj" } },
			{ Type = "Scene", Dialogue = "Final", Props = { "Reloj" },
				Actors = { { Npc = "Portero", Place = "Residencia", Offset = V(3, 0, 4) }, { Npc = "Ivan", Place = "Residencia", Offset = V(-3, 0, 4), Mode = "Cheer" } } },
		},
		Dialogues = {
			Pilar = { Lines = {
				{ S = "Portero", T = "Cuarenta años con este reloj. Nunca se ha atrasado ni un minuto. Hoy se atrasa todo el rato. Y a propósito." },
				{ S = "Ivan", T = "{nombre}. Tengo una duda. ¿Los cordones van por dentro o por fuera? ¿Y el zumo… se bebe o se come? Hace una hora lo sabía." },
				{ S = "Portero", T = "Cada vez que el reloj da la hora hacia atrás, a alguien se le olvida algo que aprendió. Esta mañana, a la de la limpieza se le olvidó fregar. Está encantada." },
			} },
			Pieza = { Lines = {
				{ S = "Narrador", T = "Un engranaje verde, girando solo. Al revés. Cuando lo coges, se para, como avergonzado." },
			} },
			Arreglar = { Lines = {
				{ S = "Narrador", T = "Das la vuelta a los engranajes y los encajas. El reloj tose. Hace «tic-tac». Al derecho. Suena la hora: una campanada normal y aburrida. Maravillosa." },
			} },
			Final = { Lines = {
				{ S = "Ivan", T = "¡Cordones por fuera! ¡El zumo se bebe! ¡Y me he acordado de otra cosa: me debes dos euros de la fiesta!" },
				{ S = "Portero", T = "Muchas gracias. Toma: sobraba un engranaje. Va al revés. Dicen que, si lo giras, te olvidas de los malos ratos. Úsalo con cabeza." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adulto · El semáforo con opiniones
	---------------------------------------------------------------------
	{
		Id = "Rareza_Semaforo",
		Kind = "Side",
		Title = "El semáforo con opiniones",
		Description = "Un semáforo de la plaza ha empezado a opinar. De todo. En voz alta. Y no se pone en verde hasta que le das la razón.",
		Type = "Rareza de la Grieta · Vida adulta",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "PlazaFinanciera" },
		OfferKey = "Un semáforo en rojo te habla: «Esa corbata no pega con los zapatos». Hay atasco",
		Requires = rareza(ADULTO),
		Moment = "Negociaste con un semáforo",
		Memory = "SemaforoOpina",
		Rewards = { Items = { LuzAmbar = 1 } },
		Props = {
			Semaforo = { Kind = "Maquina", Name = "El semáforo opinador", Place = "PlazaFinanciera", Offset = V(3, 0, 5), Color = Color3.fromRGB(220, 40, 40), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip ha venido a ver el atasco",
				Props = { "Semaforo" }, Actors = { { Npc = "Pip", Place = "PlazaFinanciera", Offset = V(-2, 0, 4) } } },
			{ Type = "Choice", Key = "Semaforo", Text = "El semáforo pregunta: «¿Verdad que la piña en la pizza es un crimen?». Hay cuarenta coches esperando. ¿Qué haces?",
				Options = {
					{ Id = "Razon", Text = "Darle la razón (aunque no la tenga)", Effects = { Traits = { Empatia = 1 } } },
					{ Id = "Debate", Text = "Debatir con argumentos", Effects = { Traits = { Curiosidad = 1 } } },
					{ Id = "Escuchar", Text = "Preguntarle cómo se siente", Effects = { Traits = { Empatia = 2 } } },
				},
				Props = { "Semaforo" }, Actors = { { Npc = "Pip", Place = "PlazaFinanciera", Offset = V(-2, 0, 4) } } },
			{ Type = "Scene", Dialogue = "Final", Props = { "Semaforo" }, Actors = { { Npc = "Pip", Place = "PlazaFinanciera", Offset = V(-2, 0, 4) } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Una chispa de la Grieta le dio conciencia. Lleva cuarenta años mirando pasar coches sin poder decir nada. Ahora tiene muchas cosas que decir. Todas a la vez." },
				{ S = "Narrador", T = "(El semáforo) «¡Ese coche necesita un lavado! ¡Ese señor debería llamar a su madre! ¡La piña en la pizza es un crimen!»" },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "(El semáforo) «¡Por fin alguien sensato!». Se pone en verde. Los coches pasan. Te guiña el ámbar.", If = { Choices = { Semaforo = "Razon" } } },
				{ S = "Narrador", T = "(El semáforo) «…Vale. Tu argumento sobre el dulce y el salado es sólido. Me lo pensaré.». Se pone en verde, pensativo.", If = { Choices = { Semaforo = "Debate" } } },
				{ S = "Narrador", T = "(El semáforo, muy bajito) «…Nadie me había preguntado eso nunca. Me siento… solo. Todo el día aquí, en rojo, y todos con prisa.». Se pone en verde. Y se queda en ámbar un segundo más, como una sonrisa.", If = { Choices = { Semaforo = "Escuchar" } } },
				{ S = "Pip", T = "Le ha regalado su luz ámbar de repuesto. Es su forma de decir «gracias». O «precaución». En los semáforos es lo mismo." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adulto · La nube que te sigue
	---------------------------------------------------------------------
	{
		Id = "Rareza_Nube",
		Kind = "Side",
		Title = "La nube que te sigue",
		Description = "Hay una nube pequeñita que te sigue a todas partes. Solo llueve sobre ti. Parece que quiere algo.",
		Type = "Rareza de la Grieta · Vida adulta",
		Duration = { 12, 16 },
		Npcs = { "Pip" },
		Offer = { Place = "Home" },
		OfferKey = "Sales de casa y te empieza a llover encima. Solo a ti. Hay una nube del tamaño de un cojín sobre tu cabeza",
		Requires = rareza(ADULTO),
		Moment = "Llevaste a una nube perdida de vuelta a casa",
		Memory = "NubePerdida",
		Rewards = { Items = { GotaNube = 1 } },
		Props = {
			Nube = { Kind = "Cristal", Name = "Una nube pequeñita (y mojada)", Place = "Playa", Offset = V(0, 0, 6), Color = Color3.fromRGB(220, 230, 255), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pregúntale a Pip (con la nube encima)",
				Actors = { { Npc = "Pip", Place = "Home", Offset = V(3, 0, 4) } } },
			{ Type = "Reach", Place = "Parque", Text = "Llévala al parque: a ver si se queda con los árboles" },
			{ Type = "Reach", Place = "Playa", Text = "No quiere árboles. Quiere mar: llévala a la playa" },
			{ Type = "Scene", Dialogue = "Final", Props = { "Nube" }, Actors = { { Npc = "Pip", Place = "Playa", Offset = V(3, 0, 4), Mode = "Wave" } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Es una nube bebé. Se cayó por la Grieta y ha perdido a su familia. Le ha cogido cariño a usted. Por eso le llueve encima. Es un abrazo de nube." },
				{ S = "Pip", T = "Las nubes nacen del mar. Si la lleva a la playa, encontrará el camino. Consejo: no abra el paraguas. Se ofende." },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "En la playa, la nubecita se para. Mira el mar. Sobre el horizonte hay un banco de nubes grandes. Una de ellas hace «¡plic!»." },
				{ S = "Narrador", T = "La nubecita te llueve encima una última vez, flojito, y se va volando. Antes de irse, deja caer una gota que no se seca." },
				{ S = "Pip", T = "Una gota de nube. Dicen que, si la tiene en la mano en un día triste, sale el sol. Yo no lo he probado. Yo no tengo días tristes. Solo actualizaciones." },
			} },
		},
	},
}
