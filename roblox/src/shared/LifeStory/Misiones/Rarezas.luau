-- RAREZAS DE LA GRIETA: secundarias cortas (10-15 min) con cosas absurdas que se cuelan por la Grieta.
-- Ficha de diseño: docs/historia/13-saga-de-la-grieta.md («Secundarias»)
--
-- Todas piden haber visto la Grieta (Saga_02) y dan una pieza de la colección «Restos de la Grieta».
-- Seis por etapa (tres lotes):
--   Rareza_Buzon      Niño         «El buzón que escribe al pasado»
--   Rareza_Farola     Niño         «La farola que canta ópera» (de noche)
--   Rareza_Perro      Adolescente  «El perro que ladra en binario»
--   Rareza_Espaguetis Adolescente  «Lluvia de espaguetis»
--   Rareza_Piso13     Universidad  «El piso 13»
--   Rareza_Reloj      Universidad  «El reloj que va hacia atrás»
--   Rareza_Semaforo   Adulto       «El semáforo con opiniones»
--   Rareza_Nube       Adulto       «La nube que te sigue»
--   Rareza_Columpio   Niño         «El columpio que va al pasado»
--   Rareza_Sombra     Niño         «La sombra que se escapa»
--   Rareza_Espejo     Adolescente  «El espejo que contesta»
--   Rareza_Palomas    Adolescente  «Las palomas que hacen cola»
--   Rareza_Cafe       Universidad  «La máquina de café que da consejos»
--   Rareza_Eco        Universidad  «El eco del estadio»
--   Rareza_Contestador Adulto      «El contestador de 1999»
--   Rareza_GatoCaja   Adulto       «El gato que está y no está»
--   Rareza_Helado     Niño         «El helado que sabe a recuerdos»
--   Rareza_Charco     Niño         «El charco sin fondo»
--   Rareza_Cancion    Adolescente  «La canción que no se acaba»
--   Rareza_Taquilla   Adolescente  «La taquilla que da a otra taquilla»
--   Rareza_Fotocopiadora Universidad «La fotocopiadora que copia personas»
--   Rareza_Wifi       Universidad  «El wifi que se conecta a 1987»
--   Rareza_Lavadora   Adulto       «La lavadora multiversal»
--   Rareza_Cajero     Adulto       «El cajero que da minutos»

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
	---------------------------------------------------------------------
	-- SEGUNDO LOTE
	---------------------------------------------------------------------

	---------------------------------------------------------------------
	-- Niño · El columpio que va al pasado
	---------------------------------------------------------------------
	{
		Id = "Rareza_Columpio",
		Kind = "Side",
		Title = "El columpio que va al pasado",
		Description = "Un columpio del parque, cuanto más alto subes, más atrás te lleva en el tiempo. Solo un poquito. Solo un rato.",
		Type = "Rareza de la Grieta · Infancia",
		Duration = { 10, 14 },
		Npcs = { "Pip", "Abu" },
		Offer = { Place = "ColumpiosParque" },
		OfferKey = "Un columpio del parque brilla un poco verde. Cuando te columpias, el parque se ve… antiguo",
		Requires = rareza(NINO),
		Moment = "Te columpiaste hasta la infancia de tu abu",
		Memory = "ColumpioPasado",
		Rewards = { Items = { CadenaColumpio = 1 } },
		Props = {
			Columpio = { Kind = "Asiento", Name = "El columpio verde", Prompt = "Columpiarte", Place = "ColumpiosParque", Offset = V(0, 0, 3), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Columpio", Once = true },
			Iniciales = { Kind = "Banco", Name = "Unas iniciales grabadas en el banco", Prompt = "Mirar las iniciales", Place = "ColumpiosParque", Offset = V(-4, 0, 2), Dialogue = "Iniciales", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Columpio", Text = "Súbete al columpio verde" },
			{ Type = "Transition", Text = "Subes. Y subes. El parque se vuelve de color sepia. Los coches son redondos. Un niño con gorra graba algo en un banco con una navaja de juguete.", Seconds = 4, Teleport = "ColumpiosParque" },
			{ Type = "Use", Prop = "Iniciales", Text = "Mira qué ha grabado el niño en el banco" },
			{ Type = "Talk", Npc = "Abu", Dialogue = "Abu", Text = "Vuelve al presente y pregúntale a {abu}",
				Actors = { { Npc = "Abu", Place = "Home", Offset = V(2, 0, 3), Mode = "Sit" } } },
		},
		Dialogues = {
			Columpio = { Lines = {
				{ S = "Narrador", T = "Cada vez que el columpio llega arriba, el cielo cambia un poco de color. Como si pasaras las páginas de un álbum de fotos muy viejo." },
			} },
			Iniciales = { Lines = {
				{ S = "Narrador", T = "El niño ya se ha ido. En el banco pone, recién grabado: «Aquí estuvo el mejor columpiador de Valmar». Y unas iniciales. Son las de {abu}." },
				{ S = "Narrador", T = "El columpio se frena solo. El parque recupera sus colores. En el banco de hoy, casi borradas, siguen las mismas letras." },
			} },
			Abu = { Lines = {
				{ S = "Abu", T = "¿Las iniciales del banco? ¡Claro que las hice yo! Tenía tu edad. Me castigaron una semana sin postre. Mereció la pena." },
				{ S = "Abu", T = "¿Y tú cómo sabes lo de la navaja de juguete? Eso no se lo he contado nunca a nadie… Bueno. Da igual. Toma: la cadenita de aquel columpio. La guardé cuando lo cambiaron. Ahora es tuya." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Niño · La sombra que se escapa
	---------------------------------------------------------------------
	{
		Id = "Rareza_Sombra",
		Kind = "Side",
		Title = "La sombra que se escapa",
		Description = "Tu sombra se ha despegado y se ha ido a jugar sola. Sin ti no puede volver a casa. Y sin ella, tú no haces sombra.",
		Type = "Rareza de la Grieta · Infancia",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "Patio" },
		OfferKey = "Miras al suelo y… no tienes sombra. A lo lejos, una sombra con tu forma se ríe y sale corriendo",
		Requires = rareza(NINO, { Hours = { From = 9, To = 19 } }),
		Moment = "Recuperaste tu sombra (que solo quería jugar)",
		Memory = "SombraEscapada",
		Rewards = { Items = { TizaSombra = 1 } },
		Steps = {
			{ Type = "Reach", Place = "JuegosColegio", Text = "Tu sombra ha ido a la zona de juegos" },
			{ Type = "Reach", Place = "Parque", Text = "¡Ahora está en el parque! Síguela" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip la ha acorralado junto a la fuente",
				Actors = { { Npc = "Pip", Place = "FuenteParque", Offset = V(-2, 0, 2) } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Su sombra estaba jugando al escondite con las sombras de los árboles. Iba ganando. Las sombras son muy buenas escondiéndose: es su trabajo." },
				{ S = "Pip", T = "Un poco de Grieta le dio vida. No quería escaparse de usted: quería jugar con usted. Y usted estaba en clase." },
				{ S = "Narrador", T = "Tu sombra se acerca, arrastrando los pies, como cuando te pillan. Se pega otra vez a tus zapatillas. Al principio va un segundo por detrás. Luego ya no." },
				{ S = "Pip", T = "Consejo: juegue con ella de vez en cuando. Al atardecer se estira mucho. Le encanta. Tome, una tiza: dibuje su contorno en el suelo. Así sabrá dónde vive." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adolescente · El espejo que contesta
	---------------------------------------------------------------------
	{
		Id = "Rareza_Espejo",
		Kind = "Side",
		Title = "El espejo que contesta",
		Description = "El espejo de tu cuarto ha empezado a opinar sobre tu pelo. Y sobre tu vida. Sobre todo sobre tu vida.",
		Type = "Rareza de la Grieta · Adolescencia",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "HomeDormitorio" },
		OfferKey = "Te miras al espejo y el reflejo, en vez de peinarse, se cruza de brazos: «¿En serio vas a salir así?»",
		Requires = rareza(ADOLESCENTE),
		Moment = "Le enseñaste a tu reflejo a ser amable",
		Memory = "EspejoContesta",
		Rewards = { Items = { EsquirlaEspejo = 1 } },
		Props = {
			Espejo = { Kind = "Espejo", Name = "Tu espejo (con opiniones)", Place = "HomeDormitorio", Offset = V(0, 0, 3), Prompt = false },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Reflejo", Props = { "Espejo" } },
			{ Type = "Choice", Key = "Espejo", Text = "Tu reflejo dice que eres «un desastre con patas». ¿Qué le contestas?", Props = { "Espejo" },
				Options = {
					{ Id = "Amable", Text = "«Hoy no. Pero dime algo bueno, que tú me conoces mejor que nadie»", Effects = { Traits = { Empatia = 2 } } },
					{ Id = "Humor", Text = "Hacerle muecas hasta que se ría", Effects = { Traits = { Humor = 2 } } },
					{ Id = "Tapar", Text = "Taparlo con una toalla", Effects = { Traits = { Rebeldia = 1 } } },
				} },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pregúntale a Pip qué le pasa al espejo",
				Actors = { { Npc = "Pip", Place = "HomeDormitorio", Offset = V(3, 0, 2) } } },
		},
		Dialogues = {
			Reflejo = { Lines = {
				{ S = "Narrador", T = "(Tu reflejo) «Ese grano. Esa camiseta. Esa cara de sueño. Y lo de ayer en clase… Madre mía, lo de ayer.»" },
				{ S = "Narrador", T = "Lo raro es que dice exactamente lo que piensas tú de ti mismo los días malos. Con tu voz. Pero en alto." },
			} },
			Pip = { Lines = {
				{ S = "Narrador", T = "(Tu reflejo, sonrojado) «…Tienes buena risa. Y ayudas a la gente aunque nadie mire. Y ese pelo… bueno, el pelo no. Pero lo demás, sí.»", If = { Choices = { Espejo = "Amable" } } },
				{ S = "Narrador", T = "(Tu reflejo, llorando de la risa) «¡Para! ¡Para, que me meo! Vale, vale: eres gracioso. Lo admito.»", If = { Choices = { Espejo = "Humor" } } },
				{ S = "Narrador", T = "(Desde debajo de la toalla, ofendido) «Muy maduro. Muy maduro.» …Al rato, flojito: «Perdona. Me he pasado.»", If = { Choices = { Espejo = "Tapar" } } },
				{ S = "Pip", T = "Un reflejo con un poquito de Grieta dentro. Repite lo que usted piensa de sí mismo. Por eso decía cosas feas: usted se las dice a veces." },
				{ S = "Pip", T = "Ya está arreglado. Se le ha caído un trocito de cristal. Si lo mira, verá su reflejo sonriendo. Aunque usted no sonría. Es un truco. Funciona." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adolescente · Las palomas que hacen cola
	---------------------------------------------------------------------
	{
		Id = "Rareza_Palomas",
		Kind = "Side",
		Title = "Las palomas que hacen cola",
		Description = "Cuarenta palomas hacen cola en Correos. Con número. Quieren enviar una carta. Nadie sabe a dónde.",
		Type = "Rareza de la Grieta · Adolescencia",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "Correos" },
		OfferKey = "En Correos hay una cola de palomas. Todas con su numerito. La 37 te mira con impaciencia",
		Requires = rareza(ADOLESCENTE),
		Moment = "Ayudaste a cuarenta palomas a enviar una carta",
		Memory = "PalomasCola",
		Rewards = { Items = { PlumaCartero = 1 } },
		Props = {
			Paloma = { Kind = "Animal", Name = "La paloma número 1 (la jefa)", Prompt = "Coger su carta", Place = "Correos", Offset = V(2, 0, 3), Color = Color3.fromRGB(150, 150, 170), Dialogue = "Carta", Once = true },
			Buzon = { Kind = "Kiosco", Name = "El buzón de «Otras dimensiones»", Prompt = "Echar la carta", Place = "Correos", Offset = V(-3, 0, 4), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Enviar", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Paloma", Text = "Habla (más o menos) con la paloma jefa" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip sabe leer paloma",
				Actors = { { Npc = "Pip", Place = "Correos", Offset = V(3, 0, 2) } } },
			{ Type = "Use", Prop = "Buzon", Text = "Echa la carta por el buzón que nadie ve" },
		},
		Dialogues = {
			Carta = { Lines = {
				{ S = "Narrador", T = "La paloma jefa te da una carta con el pico. Está escrita con patitas. Mucho «cu-rú» y un dibujo de un pan." },
			} },
			Pip = { Lines = {
				{ S = "Pip", T = "Dice: «Queridas palomas de la dimensión del pan infinito: aquí nos tiran migas de dos en dos. Llevadnos con vosotras. O mandad pan.»" },
				{ S = "Pip", T = "Al lado de Correos hay un buzón pequeñito que solo se ve si has visto la Grieta. Es de «Otras dimensiones». Casi nadie lo usa. Las palomas sí." },
			} },
			Enviar = { Lines = {
				{ S = "Narrador", T = "La carta entra con un «plop» verde. Cuarenta palomas aplauden con las alas. La 37 te da una pluma. Parece un sello de agradecimiento." },
				{ S = "Narrador", T = "Al día siguiente, en la plaza, cae del cielo una barra de pan con lacito. Las palomas la comparten. Por turnos. Con número." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Universidad · La máquina de café que da consejos
	---------------------------------------------------------------------
	{
		Id = "Rareza_Cafe",
		Kind = "Side",
		Title = "La máquina de café que da consejos",
		Description = "La máquina de café de la biblioteca ya no da café. Da consejos. Muy buenos. Demasiado buenos.",
		Type = "Rareza de la Grieta · Universidad",
		Duration = { 10, 14 },
		Npcs = { "Ivan", "Candela" },
		Offer = { Place = "Biblioteca" },
		OfferKey = "Metes una moneda en la máquina de café. En vez de café, sale un papelito: «Llama a tu familia. Hace una semana que no lo haces»",
		Requires = rareza(UNI, { Completed = { "Saga_02_Grieta", "Uni01b_Residencia" } }),
		Moment = "Aceptaste un consejo de una máquina de café",
		Memory = "CafeConsejos",
		Rewards = { Items = { VasoConsejos = 1 } },
		Props = {
			Maquina = { Kind = "Maquina", Name = "La máquina de café (consejera)", Prompt = "Pedir un consejo", Place = "Biblioteca", Offset = V(3, 0, 3), Color = Color3.fromRGB(120, 80, 50), Dialogue = "Consejo", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Maquina", Text = "Pídele un consejo a la máquina" },
			{ Type = "Talk", Npc = "Candela", Dialogue = "Compis", Text = "Iván y Candela también han recibido consejos",
				Actors = { { Npc = "Candela", Place = "Biblioteca", Offset = V(-3, 0, 3) }, { Npc = "Ivan", Place = "Biblioteca", Offset = V(-5, 0, 2), Mode = "Sit" } } },
			{ Type = "Choice", Key = "Cafe", Text = "La máquina ofrece un trato: «Un consejo al día para siempre… o un café normal para siempre». ¿Qué eliges?",
				Options = {
					{ Id = "Cafe", Text = "Café normal: tus decisiones, las tomas tú", Effects = { Traits = { Responsabilidad = 2 } } },
					{ Id = "Consejos", Text = "Consejos: ¿quién dice que no a un buen consejo?", Effects = { Traits = { Curiosidad = 1 } } },
				},
				Actors = { { Npc = "Candela", Place = "Biblioteca", Offset = V(-3, 0, 3) } } },
			{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Ivan", Place = "Biblioteca", Offset = V(-5, 0, 2) }, { Npc = "Candela", Place = "Biblioteca", Offset = V(-3, 0, 3) } } },
		},
		Dialogues = {
			Consejo = { Lines = {
				{ S = "Narrador", T = "Otro papelito: «El examen del jueves cae el tema 4. No el 3. El 4. Y come algo verde, por favor.»" },
			} },
			Compis = { Lines = {
				{ S = "Ivan", T = "A mí me ha dicho que deje de echarle azúcar al zumo de mora. ¡Al zumo de mora! ¿Quién se cree que es?" },
				{ S = "Candela", T = "A mí me ha dicho que no todo cabe en un Excel. …Le he puesto una queja formal. En Excel." },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "La máquina suelta un café. Solo café. Humeante, normal, perfecto. Por el lateral cae un vasito de cartón con un último papel dentro: «Buena decisión».", If = { Choices = { Cafe = "Cafe" } } },
				{ S = "Narrador", T = "La máquina suelta un papelito: «Consejo 1: no le hagas caso a todo lo que dice una máquina». Luego se apaga. Parece contenta.", If = { Choices = { Cafe = "Consejos" } } },
				{ S = "Candela", T = "Apunto: «Máquina de café con criterio». Pestaña «Cosas imposibles». Fila 47." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Universidad · El eco del estadio
	---------------------------------------------------------------------
	{
		Id = "Rareza_Eco",
		Kind = "Side",
		Title = "El eco del estadio",
		Description = "En el estadio universitario, el eco no repite lo que gritas. Repite lo que gritarás dentro de un año.",
		Type = "Rareza de la Grieta · Universidad",
		Duration = { 10, 14 },
		Npcs = { "Ivan" },
		Offer = { Place = "EstadioUniversitario" },
		OfferKey = "Iván grita «¡hola!» en el estadio vacío. El eco contesta: «¡He aprobado Anatomía!»",
		Requires = rareza(UNI, { Completed = { "Saga_02_Grieta", "Uni01b_Residencia" } }),
		Moment = "Oíste a tu yo del futuro en el eco del estadio",
		Memory = "EcoFuturo",
		Rewards = { Items = { SilbatoEco = 1 } },
		Props = {
			Grada = { Kind = "Asiento", Name = "La grada del eco", Prompt = "Gritar algo", Place = "EstadioUniversitario", Offset = V(0, 0, 6), Dialogue = "Grito", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Ivan", Dialogue = "Ivan", Text = "Iván ha descubierto el eco del futuro",
				Actors = { { Npc = "Ivan", Place = "EstadioUniversitario", Offset = V(3, 0, 4), Mode = "Cheer" } } },
			{ Type = "Use", Prop = "Grada", Text = "Grita algo desde la grada" },
			{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Ivan", Place = "EstadioUniversitario", Offset = V(3, 0, 4) } } },
		},
		Dialogues = {
			Ivan = { Lines = {
				{ S = "Ivan", T = "¡{nombre}! ¡El eco sabe cosas! Le he gritado «¿apruebo?» y me ha dicho «¡he aprobado Anatomía!». Con MI voz. Pero más… segura." },
				{ S = "Ivan", T = "Grita tú. Pero algo bonito, ¿eh? Que igual contesta algo triste y me pongo a llorar. Soy de lágrima fácil. Tú ya lo sabes." },
			} },
			Grito = { Lines = {
				{ S = "Narrador", T = "Gritas tu nombre. El estadio vacío se lo piensa. Y el eco, con tu voz, pero un año mayor, contesta: «¡Gracias por no rendirte!»." },
				{ S = "Narrador", T = "No sabes de qué se da las gracias tu yo del futuro. Pero suena contento. Muy contento." },
			} },
			Final = { Lines = {
				{ S = "Ivan", T = "«Gracias por no rendirte». Tío. Eso se va a cumplir. Lo sé. Tengo un pálpito. Y el eco tiene un pálpito. Somos dos pálpitos." },
				{ S = "Narrador", T = "En la grada, donde gritaste, hay un silbato que antes no estaba. Si soplas, no suena. Se oye un segundo después." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adulto · El contestador de 1999
	---------------------------------------------------------------------
	{
		Id = "Rareza_Contestador",
		Kind = "Side",
		Title = "El contestador de 1999",
		Description = "Tu móvil recibe mensajes de voz de un contestador de 1999. Son de alguien de tu familia. De cuando eras un bebé.",
		Type = "Rareza de la Grieta · Vida adulta",
		Duration = { 10, 14 },
		Npcs = { "Familia", "Pip" },
		Offer = { Place = "Home" },
		OfferKey = "Tienes un mensaje de voz. Número desconocido. Fecha: 1999",
		Requires = rareza(ADULTO),
		Moment = "Oíste un mensaje de 1999 dedicado a ti",
		Memory = "Contestador1999",
		Rewards = { Items = { CintaContestador = 1 } },
		Props = {
			Telefono = { Kind = "Pantalla", Name = "Tu móvil (con un mensaje de 1999)", Prompt = "Escuchar el mensaje", Place = "HomeSalon", Offset = V(0, 0, 3), Color = Color3.fromRGB(40, 40, 50), Dialogue = "Mensaje", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Telefono", Text = "Escucha el mensaje" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pregúntale a Pip cómo es posible",
				Actors = { { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) } } },
			{ Type = "Talk", Npc = "Familia", Dialogue = "Familia", Text = "Díselo a {familia}",
				Actors = { { Npc = "Familia", Place = "CasaFamiliar", Offset = V(2, 0, 3) } } },
		},
		Dialogues = {
			Mensaje = { Lines = {
				{ S = "Narrador", T = "(Una voz que conoces, pero más joven) «Hola, cosa pequeña. Esto es una prueba del contestador nuevo. Estás dormido en la cuna. Roncas. Muy fuerte para ser tan pequeño.»" },
				{ S = "Narrador", T = "«No sé para qué te grabo esto, si no lo vas a oír. Bueno. Por si algún día… que sepas que eres lo mejor que nos ha pasado. Fin del mensaje. ¿Cómo se para esto? ¿Este botón?»" },
			} },
			Pip = { Lines = {
				{ S = "Pip", T = "La Grieta a veces cruza cables de años distintos. Los mensajes que nadie escuchó se quedan flotando. Y un día encuentran a quien iban dirigidos." },
				{ S = "Pip", T = "Le he pasado el mensaje a una cinta. Así no se pierde. Las cintas son más cabezotas que los móviles." },
			} },
			Familia = { Lines = {
				{ S = "Familia", T = "¿Un mensaje de 1999? ¿Del contestador de la casa vieja? …Me acuerdo. Lo grabé una noche que no podía dormir. Pensé que se había borrado." },
				{ S = "Familia", T = "…Lo que decía era verdad. Lo sigue siendo. No me hagas repetirlo, que me emociono. Anda, quédate a cenar." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adulto · El gato del supermercado (dentro y fuera de la caja)
	---------------------------------------------------------------------
	{
		Id = "Rareza_GatoCaja",
		Kind = "Side",
		Title = "El gato que está y no está",
		Description = "En el supermercado hay un gato dentro de una caja. Y el mismo gato fuera de la caja. A la vez. El encargado está muy estresado.",
		Type = "Rareza de la Grieta · Vida adulta",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "Supermercado" },
		OfferKey = "En el pasillo 3 hay un gato dentro de una caja. Y el mismo gato sentado encima de la caja. Te miran los dos",
		Requires = rareza(ADULTO),
		Moment = "Decidiste dónde estaba un gato cuántico",
		Memory = "GatoCuantico",
		Rewards = { Items = { CascabelCuantico = 1 } },
		Props = {
			Caja = { Kind = "Caja", Name = "Una caja con un gato (quizá)", Prompt = "Abrir la caja", Place = "Supermercado", Offset = V(2, 0, 3), Dialogue = "Abrir", Once = true },
			Gato = { Kind = "Gato", Name = "Un gato (quizá el mismo)", Place = "Supermercado", Offset = V(4, 0, 3), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip ha venido a por yogures (y a por el gato)", Props = { "Gato" },
				Actors = { { Npc = "Pip", Place = "Supermercado", Offset = V(-2, 0, 3) } } },
			{ Type = "Use", Prop = "Caja", Text = "Abre la caja", Props = { "Gato" } },
			{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Pip", Place = "Supermercado", Offset = V(-2, 0, 3) } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Un gato de la Grieta. Está dentro y fuera de la caja a la vez hasta que alguien mira. En la dimensión de los gatos esto es normal. Aquí, el encargado ha llamado a tres veterinarios." },
				{ S = "Pip", T = "Hay que abrir la caja. Cuando alguien mira, el gato tiene que decidir dónde está. Normalmente elige donde haya comida." },
			} },
			Abrir = { Lines = {
				{ S = "Narrador", T = "Abres la caja. Por un segundo hay dos gatos. Se miran. Uno bosteza. El otro se ofende. Y… solo queda uno. Dentro de la caja. Como si nada." },
			} },
			Final = { Lines = {
				{ S = "Pip", T = "Gato decidido. Caja ocupada. Encargado más tranquilo. Ha dejado un cascabel: a veces suena y a veces no. Aunque no lo muevas. Es cuántico. O está roto." },
				{ S = "Pip", T = "Y he comprado los yogures. Los de fresa no: siguen raros." },
			} },
		},
	},
	---------------------------------------------------------------------
	-- TERCER LOTE
	---------------------------------------------------------------------

	---------------------------------------------------------------------
	-- Niño · El helado que sabe a recuerdos
	---------------------------------------------------------------------
	{
		Id = "Rareza_Helado",
		Kind = "Side",
		Title = "El helado que sabe a recuerdos",
		Description = "En la heladería hay un sabor nuevo, de color verde Grieta. No sabe a fresa ni a chocolate: sabe a un recuerdo.",
		Type = "Rareza de la Grieta · Infancia",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "Heladeria" },
		OfferKey = "En la heladería hay un sabor nuevo: «Sabor Recuerdo». Es verde. Brilla un poquito",
		Requires = rareza(NINO),
		Moment = "Probaste un helado que sabía a recuerdos",
		Memory = "HeladoRecuerdos",
		Rewards = { Items = { CucuruchoRecuerdos = 1 } },
		Props = {
			Cubeta = { Kind = "Kiosco", Name = "La cubeta del «Sabor Recuerdo»", Prompt = "Pedir una bola", Place = "Heladeria", Offset = V(0, 0, 3), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Bola", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Cubeta", Text = "Pide una bola del sabor nuevo" },
			{ Type = "Choice", Key = "Sabor", Text = "La heladera dice que cada bola sabe a un recuerdo distinto. ¿Cuál pides para la segunda?",
				Options = {
					{ Id = "Cumple", Text = "El de tu mejor cumpleaños", Effects = { Traits = { Humor = 1 } } },
					{ Id = "Abu", Text = "Uno de {abu} cuando era pequeño", Effects = { Traits = { Empatia = 2 } } },
					{ Id = "Manana", Text = "Uno de mañana (¿se puede?)", Effects = { Traits = { Curiosidad = 2 } } },
				},
				Actors = { { Npc = "Pip", Place = "Heladeria", Offset = V(3, 0, 2) } } },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip ha venido a por un helado (de tornillos)",
				Actors = { { Npc = "Pip", Place = "Heladeria", Offset = V(3, 0, 2) } } },
		},
		Dialogues = {
			Bola = { Lines = {
				{ S = "Narrador", T = "Das un lametazo. De repente estás otra vez en tu primer día de colegio: el olor a lápiz nuevo, los nervios en la barriga, la mochila que pesaba más que tú." },
				{ S = "Narrador", T = "Otro lametazo y vuelves a la heladería. Tienes la lengua verde y los ojos un poco húmedos. Es un helado muy fuerte." },
			} },
			Pip = { Lines = {
				{ S = "Narrador", T = "Segunda bola: sabe a tarta, a velas, a una canción desafinada. Te ríes solo. La heladera también se ríe. No sabe por qué.", If = { Choices = { Sabor = "Cumple" } } },
				{ S = "Narrador", T = "Segunda bola: sabe a un pueblo pequeño, a pan con chocolate y a un niño con gorra que se columpia muy alto. Es {abu}. Con tu edad.", If = { Choices = { Sabor = "Abu" } } },
				{ S = "Narrador", T = "Segunda bola: no sabe a nada. Y luego, de golpe, a un bocadillo de chorizo que todavía no te has comido. Mañana, seguramente.", If = { Choices = { Sabor = "Manana" } } },
				{ S = "Pip", T = "Leche de la Grieta. Una vaca de otra dimensión se asomó por un agujerito y la heladera la ordeñó sin preguntar. Así se hacen los negocios en Valmar." },
				{ S = "Pip", T = "Ya se ha acabado la cubeta. Quédese el cucurucho. Si lo huele, se acordará. Yo pedí de tornillos. Sabe a martes." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Niño · El charco sin fondo
	---------------------------------------------------------------------
	{
		Id = "Rareza_Charco",
		Kind = "Side",
		Title = "El charco sin fondo",
		Description = "En el parque hay un charco que no refleja el cielo de Valmar. Refleja otro. Con dos lunas. Y algo amarillo flota hacia arriba.",
		Type = "Rareza de la Grieta · Infancia",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "Parque" },
		OfferKey = "Miras un charco del parque. Dentro se ven dos lunas. Aquí solo hay una",
		Requires = rareza(NINO),
		Moment = "Devolviste un patito de otra dimensión al agua",
		Memory = "CharcoSinFondo",
		Rewards = { Items = { PatitoDosLunas = 1 } },
		Props = {
			Charco = { Kind = "Moco", Name = "Un charco con dos lunas", Prompt = "Asomarte al charco", Place = "Parque", Offset = V(3, 0, 5), Color = Color3.fromRGB(90, 140, 220), Dialogue = "Charco", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Charco", Text = "Asómate al charco" },
			{ Type = "Reach", Place = "EstanqueParque", Text = "El patito quiere nadar: llévalo al estanque" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip está en el estanque (con un flotador)",
				Actors = { { Npc = "Pip", Place = "EstanqueParque", Offset = V(-3, 0, 2) } } },
		},
		Dialogues = {
			Charco = { Lines = {
				{ S = "Narrador", T = "En el charco se ve un cielo morado con dos lunas. Y un patito de goma que cae… hacia arriba. Sale del charco, te da en la nariz y se queda en tu mano." },
				{ S = "Narrador", T = "Hace «cuic». Pero al revés: «kiuc». Te mira. Mira el estanque. Vuelve a mirarte. Está claro lo que quiere." },
			} },
			Pip = { Lines = {
				{ S = "Narrador", T = "Dejas el patito en el estanque. Nada un poco. Luego, feliz, flota hacia arriba unos centímetros y se queda ahí, en el aire, sobre el agua." },
				{ S = "Pip", T = "En su dimensión, las cosas caen hacia el cielo. Por eso allí los patos llevan piedras en los bolsillos. Este se cayó por un charco que conectaba con la Grieta." },
				{ S = "Pip", T = "El charco ya se ha secado. El patito no puede volver. Pero dice «kiuc», que en su idioma es «aquí se está bien». Quédese uno de sus primos: vinieron tres." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adolescente · La canción que no se acaba
	---------------------------------------------------------------------
	{
		Id = "Rareza_Cancion",
		Kind = "Side",
		Title = "La canción que no se acaba",
		Description = "Por los altavoces del instituto suena una canción de otra dimensión. Es tan pegadiza que nadie puede dejar de cantarla. Y no tiene final.",
		Type = "Rareza de la Grieta · Adolescencia",
		Duration = { 12, 16 },
		Npcs = { "Pip" },
		Offer = { Place = "PatioInstituto" },
		OfferKey = "Todo el patio canta la misma canción. «Na-na-na-naaa…». Tú también. No puedes parar",
		Requires = rareza(ADOLESCENTE),
		Moment = "Le pusiste final a la canción más pegadiza del multiverso",
		Memory = "CancionPegadiza",
		Rewards = { Items = { PartituraSinFin = 1 } },
		Props = {
			Altavoz = { Kind = "Pantalla", Name = "El altavoz del patio (verde)", Place = "PatioInstituto", Offset = V(0, 0, 6), Color = Color3.fromRGB(120, 255, 160), Prompt = false },
			Estrofa1 = { Kind = "Papel", Name = "Un trozo de partitura pegado en un árbol", Prompt = "Coger la partitura", Place = "Parque", Offset = V(3, 0, 3), Dialogue = "Estrofa", Once = true },
			Estrofa2 = { Kind = "Papel", Name = "Un trozo de partitura en un libro", Prompt = "Coger la partitura", Place = "Libreria", Offset = V(0, 0, 3), Dialogue = "Estrofa", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip ha venido con tapones (no le sirven)",
				Props = { "Altavoz" }, Actors = { { Npc = "Pip", Place = "PatioInstituto", Offset = V(3, 0, 4) } } },
			{ Type = "Group", Text = "Busca los trozos del final de la canción",
				Steps = {
					{ Type = "Use", Prop = "Estrofa1", Text = "Uno en el parque" },
					{ Type = "Use", Prop = "Estrofa2", Text = "Otro en la librería" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "El final de la canción", Icon = "🎶", Hint = "Canta la última nota justo cuando se encienda el altavoz",
				Rounds = 5, Need = 3, Zone = 0.28, Speed = 1,
				Win = { Flags = { "CancionAfinada" } }, Lose = { Traits = { Humor = 1 } },
				Props = { "Altavoz" }, Actors = { { Npc = "Pip", Place = "PatioInstituto", Offset = V(3, 0, 4), Mode = "Cheer" } } },
			{ Type = "Scene", Dialogue = "Final", Props = { "Altavoz" }, Actors = { { Npc = "Pip", Place = "PatioInstituto", Offset = V(3, 0, 4) } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "Na-na-na-naaa… Perdón. Es una canción de la dimensión de los estribillos. Allí las canciones no tienen final. Se cantan hasta que alguien se desmaya." },
				{ S = "Pip", T = "Se coló por la Grieta y se metió en los altavoces. Pero sin final. El final se quedó enganchado por ahí, a trozos. Si lo encontramos y lo cantamos, se acaba." },
				{ S = "Pip", T = "Dese prisa. El profesor de Matemáticas lleva dos horas cantando. Ha empezado a hacer coreografía." },
			} },
			Estrofa = { Lines = {
				{ S = "Narrador", T = "Un trozo de partitura, con notas verdes. Al cogerlo, la canción se oye un poco más bajito. Como si se diera cuenta de que se acaba." },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "Cantas la última nota. Perfecta. La canción termina con un «¡tachán!». Todo el patio se calla. Luego, un aplauso enorme. El profe de Matemáticas hace una reverencia.", If = { Flags = { "CancionAfinada" } } },
				{ S = "Narrador", T = "Cantas la última nota. Fatal. Pero es una nota final, y la canción lo acepta. Se acaba con un «¿tachán?». Todo el patio respira. Alguien grita: «¡Gracias!».", If = { NotFlags = { "CancionAfinada" } } },
				{ S = "Pip", T = "Aquí tiene la partitura completa. Guárdela bien. Y no la tararee nunca. Nunca. Ni en la ducha." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adolescente · La taquilla que da a otra taquilla
	---------------------------------------------------------------------
	{
		Id = "Rareza_Taquilla",
		Kind = "Side",
		Title = "La taquilla que da a otra taquilla",
		Description = "Tu taquilla del instituto está conectada con una taquilla de otra dimensión. Alguien te deja notas. Tiene tu letra, pero no es tu letra.",
		Type = "Rareza de la Grieta · Adolescencia",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "Instituto" },
		OfferKey = "Abres tu taquilla. Dentro hay una nota que no has escrito: «¿Tú también estás harto de Matemáticas?»",
		Requires = rareza(ADOLESCENTE),
		Moment = "Hiciste amistad con alguien de otra dimensión a través de una taquilla",
		Memory = "TaquillaDimensional",
		Rewards = { Items = { NotaTaquilla = 1 } },
		Props = {
			Taquilla = { Kind = "Armario", Name = "Tu taquilla (conectada con otra)", Prompt = "Leer la nota", Place = "Instituto", Offset = V(3, 0, 3), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Nota", Once = true },
			Respuesta = { Kind = "Armario", Name = "Tu taquilla (otra vez)", Prompt = "Mirar si ha contestado", Place = "Instituto", Offset = V(3, 0, 3), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Respuesta", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Taquilla", Text = "Lee la nota de tu taquilla" },
			{ Type = "Choice", Key = "Taquilla", Text = "¿Qué le contestas a quien escribe desde la otra taquilla?",
				Options = {
					{ Id = "Amigos", Text = "«¿Quién eres? ¿Quieres ser mi amigo?»", Effects = { Traits = { Empatia = 2 } } },
					{ Id = "Deberes", Text = "«¿Me pasas los deberes de Matemáticas?»", Effects = { Traits = { Rebeldia = 1 } } },
					{ Id = "Chiste", Text = "Un chiste malo de los tuyos", Effects = { Traits = { Humor = 2 } } },
				} },
			{ Type = "Use", Prop = "Respuesta", Text = "Mira si ha contestado" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Enséñale las notas a Pip",
				Actors = { { Npc = "Pip", Place = "PatioInstituto", Offset = V(3, 0, 2) } } },
		},
		Dialogues = {
			Nota = { Lines = {
				{ S = "Narrador", T = "«¿Tú también estás harto de Matemáticas? Aquí nos las dan en verso. Rima todo. Hasta la raíz cuadrada. P. D.: ¿Tu taquilla también huele a bocadillo?»" },
				{ S = "Narrador", T = "La letra se parece a la tuya. Pero más inclinada. Como si la hubieras escrito corriendo. O en otra dimensión." },
			} },
			Respuesta = { Lines = {
				{ S = "Narrador", T = "Nueva nota: «¡Sí! Me llamo como tú. Vivo en tu calle. Pero en mi Valmar el mar está arriba. Amigos para siempre. Y para todas las dimensiones.»", If = { Choices = { Taquilla = "Amigos" } } },
				{ S = "Narrador", T = "Nueva nota: «Te paso los deberes. Pero aquí las Matemáticas son en verso: ‘Dos más dos, qué dolor, son cuatro, sí, señor’. Tu profe no lo va a entender.»", If = { Choices = { Taquilla = "Deberes" } } },
				{ S = "Narrador", T = "Nueva nota: «JAJAJA. Aquí ese chiste es ilegal. Me lo voy a aprender. P. D.: ¿Tienes más?»", If = { Choices = { Taquilla = "Chiste" } } },
			} },
			Pip = { Lines = {
				{ S = "Pip", T = "Una taquilla cosida con otra por un hilito de la Grieta. Al otro lado hay un instituto igual que el suyo. Y alguien igual que usted. Bueno, parecido." },
				{ S = "Pip", T = "El hilito se va a soltar pronto. Guárdese la última nota. Las amistades de otra dimensión son como las de verano: duran poco, pero se recuerdan mucho." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Universidad · La fotocopiadora que copia personas
	---------------------------------------------------------------------
	{
		Id = "Rareza_Fotocopiadora",
		Kind = "Side",
		Title = "La fotocopiadora que copia personas",
		Description = "Candela se apoyó en la fotocopiadora de la facultad y le dio sin querer al botón. Ahora hay tres Candelas. Dos son de papel. Y se han escapado.",
		Type = "Rareza de la Grieta · Universidad",
		Duration = { 12, 16 },
		Npcs = { "Candela" },
		Offer = { Place = "FacultadIngenieria" },
		OfferKey = "Candela te llama muy nerviosa: «Tengo un problema. En realidad, tengo dos. Y son yo»",
		Requires = rareza(UNI, { Completed = { "Saga_02_Grieta", "Uni01b_Residencia" } }),
		Moment = "Recogiste a dos Candelas de papel",
		Memory = "FotocopiasVivas",
		Rewards = { Items = { TonerVerde = 1 } },
		Props = {
			Maquina = { Kind = "Maquina", Name = "La fotocopiadora (con un brillo verde)", Place = "FacultadIngenieria", Offset = V(0, 0, 4), Color = Color3.fromRGB(120, 255, 160), Prompt = false },
			Copia1 = { Kind = "Papel", Name = "Una Candela de papel (leyendo)", Prompt = "Doblar a la copia", Place = "Biblioteca", Offset = V(-3, 0, 3), Dialogue = "Copia1", Once = true },
			Copia2 = { Kind = "Papel", Name = "Una Candela de papel (haciendo un Excel)", Prompt = "Doblar a la copia", Place = "Universidad", Offset = V(4, 0, 3), Dialogue = "Copia2", Once = true },
			Deshacer = { Kind = "Maquina", Name = "El botón «Deshacer» de la fotocopiadora", Prompt = "Pulsar «Deshacer»", Place = "FacultadIngenieria", Offset = V(1, 0, 3), Dialogue = "Deshacer", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Candela", Dialogue = "Candela", Text = "Candela te espera junto a la fotocopiadora", Props = { "Maquina" },
				Actors = { { Npc = "Candela", Place = "FacultadIngenieria", Offset = V(3, 0, 3) } } },
			{ Type = "Group", Text = "Encuentra a las Candelas de papel",
				Steps = {
					{ Type = "Use", Prop = "Copia1", Text = "Una ha ido a la biblioteca" },
					{ Type = "Use", Prop = "Copia2", Text = "La otra está en el campus" },
				} },
			{ Type = "Use", Prop = "Deshacer", Text = "Vuelve a la fotocopiadora y pulsa «Deshacer»", Props = { "Maquina" } },
			{ Type = "Scene", Dialogue = "Final", Props = { "Maquina" }, Actors = { { Npc = "Candela", Place = "FacultadIngenieria", Offset = V(3, 0, 3), Mode = "Cheer" } } },
		},
		Dialogues = {
			Candela = { Lines = {
				{ S = "Candela", T = "Me apoyé en la fotocopiadora. Le di al botón con el codo. Salieron dos hojas. Las hojas eran yo. Se levantaron, me dijeron «hola» y se fueron. Muy educadas, eso sí." },
				{ S = "Candela", T = "Son de papel. Si llueve, se estropean. Si hay viento, salen volando. Y lo peor: tienen mis contraseñas. Hay que traerlas antes de que hagan algo que yo no haría. O que sí haría." },
			} },
			Copia1 = { Lines = {
				{ S = "Narrador", T = "La Candela de papel está leyendo un libro de cuatrocientas páginas. Ya va por la trescientos. Cuando la doblas con cuidado, dice «gracias» con un crujido." },
			} },
			Copia2 = { Lines = {
				{ S = "Narrador", T = "La otra Candela de papel ha hecho un Excel de todas las nubes del cielo. Por tamaño. Y por forma. Se deja doblar, pero antes guarda el archivo." },
			} },
			Deshacer = { Lines = {
				{ S = "Narrador", T = "Metes las dos copias por la bandeja y pulsas «Deshacer». La máquina ronronea, escupe un cartucho de tóner verde y se apaga. Las copias han vuelto a ser papel en blanco." },
			} },
			Final = { Lines = {
				{ S = "Candela", T = "Gracias. De verdad. Ha sido rarísimo verme desde fuera. Hablo muy rápido. Y hago mucho así con las manos. Me he caído bien, eso sí." },
				{ S = "Candela", T = "El tóner es para ti. Yo lo apunto en mi Excel de «cosas imposibles». Pestaña nueva: «Fotocopias con vida propia». Fila 1." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Universidad · El wifi que se conecta a 1987
	---------------------------------------------------------------------
	{
		Id = "Rareza_Wifi",
		Kind = "Side",
		Title = "El wifi que se conecta a 1987",
		Description = "En la residencia ha aparecido una red wifi nueva: «Grieta_1987». Si te conectas, internet es de 1987. Y alguien de 1987 te está escribiendo.",
		Type = "Rareza de la Grieta · Universidad",
		Duration = { 10, 14 },
		Npcs = { "Ivan" },
		Offer = { Place = "Residencia" },
		OfferKey = "Iván te enseña el móvil: «Hay un wifi nuevo. Se llama Grieta_1987. Y la página de inicio tiene fuego animado»",
		Requires = rareza(UNI, { Completed = { "Saga_02_Grieta", "Uni01b_Residencia" } }),
		Moment = "Chateaste con alguien de 1987",
		Memory = "Wifi1987",
		Rewards = { Items = { ModemPitido = 1 } },
		Props = {
			Router = { Kind = "Maquina", Name = "Un módem viejísimo (que pita)", Prompt = "Conectarte", Place = "Residencia", Offset = V(2, 0, 3), Color = Color3.fromRGB(200, 200, 190), Dialogue = "Conexion", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Ivan", Dialogue = "Ivan", Text = "Iván ha encontrado un wifi rarísimo",
				Actors = { { Npc = "Ivan", Place = "Residencia", Offset = V(-3, 0, 3), Mode = "Sit" } } },
			{ Type = "Use", Prop = "Router", Text = "Conéctate al wifi de 1987" },
			{ Type = "Choice", Key = "Wifi", Text = "Alguien de 1987 te escribe: «Hola, ¿de dónde eres?». ¿Qué le contestas?",
				Options = {
					{ Id = "Verdad", Text = "«Del futuro. En serio»", Effects = { Traits = { Valentia = 1, Curiosidad = 1 } } },
					{ Id = "Consejo", Text = "«Da igual. Te doy un consejo: no tires los cómics»", Effects = { Traits = { Empatia = 1, Humor = 1 } } },
				},
				Actors = { { Npc = "Ivan", Place = "Residencia", Offset = V(-3, 0, 3) } } },
			{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Ivan", Place = "Residencia", Offset = V(-3, 0, 3), Mode = "Cheer" } } },
		},
		Dialogues = {
			Ivan = { Lines = {
				{ S = "Ivan", T = "{nombre}, mira. «Grieta_1987». Me conecté y la página tardó cuatro minutos en cargar. Cuatro. Hice un zumo de mora mientras tanto." },
				{ S = "Ivan", T = "Y hay un chat. Con letras verdes. Alguien pregunta «¿hay alguien ahí?». Yo no me atrevo. Tú eres más valiente. Y yo tengo el zumo en la mano." },
			} },
			Conexion = { Lines = {
				{ S = "Narrador", T = "El módem hace «piiiii-krrrrr-chiiiii». Tarda. Mucho. La pantalla se pone verde. Un cursor parpadea. Alguien escribe: «Hola. Soy Marisa. Tengo 15 años. Es 1987. ¿Y tú?»" },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "«¿Del futuro? ¡Qué guay! ¿Hay coches voladores? …¿No? ¿Y entonces para qué sirve el futuro?». Se ríe en mayúsculas. Os despedís. «Hasta el futuro», escribe.", If = { Choices = { Wifi = "Verdad" } } },
				{ S = "Narrador", T = "«¿Los cómics? Vale… Me los guardaré. Por si acaso.» Se desconecta. Iván busca en el internet de hoy: una tal Marisa de Valmar tiene la colección de cómics más valiosa del país.", If = { Choices = { Wifi = "Consejo" } } },
				{ S = "Ivan", T = "Se ha ido el wifi. Y ha dejado el módem. Pita cuando lo miras. Quédatelo tú: yo con los aparatos que pitan me pongo nervioso. Me recuerdan al microondas." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adulto · La lavadora multiversal
	---------------------------------------------------------------------
	{
		Id = "Rareza_Lavadora",
		Kind = "Side",
		Title = "La lavadora multiversal",
		Description = "Metes calcetines en la lavadora. Salen otros. De otras dimensiones. Uno lleva perilla. Otro es de gato. Otro canta.",
		Type = "Rareza de la Grieta · Vida adulta",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "HomeCocina" },
		OfferKey = "Abres la lavadora. No están tus calcetines. Hay uno con perilla, uno de gato y uno que tararea",
		Requires = rareza(ADULTO),
		Moment = "Devolviste los calcetines de otras dimensiones",
		Memory = "LavadoraMultiversal",
		Rewards = { Items = { PinzaMultiversal = 1 } },
		Props = {
			Lavadora = { Kind = "Maquina", Name = "Tu lavadora (con un brillo verde)", Prompt = "Sacar la ropa", Place = "HomeCocina", Offset = V(2, 0, 1), Color = Color3.fromRGB(235, 240, 245), Dialogue = "Ropa", Once = true },
			Programa = { Kind = "Maquina", Name = "Tu lavadora (programa «Devolver»)", Prompt = "Poner el programa «Devolver»", Place = "HomeCocina", Offset = V(2, 0, 1), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Devolver", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Lavadora", Text = "Saca la ropa de la lavadora" },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Llévale los calcetines raros a Pip",
				Actors = { { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) } } },
			{ Type = "Use", Prop = "Programa", Text = "Vuelve a casa y pon el programa que dice Pip" },
		},
		Dialogues = {
			Ropa = { Lines = {
				{ S = "Narrador", T = "Un calcetín negro con una perilla bordada. Un calcetín diminuto con cuatro dedos (de gato). Y uno de rayas que tararea algo parecido a la ópera." },
				{ S = "Narrador", T = "Tus calcetines no están. En su lugar, pegada al tambor, hay una nota: «Perdón, nos hemos llevado los suyos. Son muy cómodos. Firmado: la dimensión de al lado»." },
			} },
			Pip = { Lines = {
				{ S = "Pip", T = "Su lavadora centrifuga tan fuerte que ha abierto un agujerito en la Grieta. Por ahí se pasan calcetines entre dimensiones. Es la causa de los calcetines desparejados de todo el universo." },
				{ S = "Pip", T = "Solución: el programa «Devolver». Está entre «Algodón» y «Delicado». Nadie lo usa porque nadie lo ve. Hay que haber visto la Grieta." },
			} },
			Devolver = { Lines = {
				{ S = "Narrador", T = "Pones el programa «Devolver». La lavadora gira hacia el otro lado. Hace «¡flop!». Al abrirla, están tus calcetines. Todos. Hasta uno que perdiste hace diez años." },
				{ S = "Narrador", T = "Y una pinza de tender verde, de regalo, con una nota: «Gracias por los calcetines. Os los devolvemos lavados. Esta pinza seca en tres dimensiones a la vez»." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Adulto · El cajero que da minutos
	---------------------------------------------------------------------
	{
		Id = "Rareza_Cajero",
		Kind = "Side",
		Title = "El cajero que da minutos",
		Description = "El cajero del banco ya no da dinero. Da minutos. Billetes de diez minutos. La cola da la vuelta a la manzana.",
		Type = "Rareza de la Grieta · Vida adulta",
		Duration = { 10, 14 },
		Npcs = { "Pip" },
		Offer = { Place = "Banco" },
		OfferKey = "Sacas dinero del cajero y sale un billete que pone «10 minutos». La señora de detrás ya lleva cuarenta",
		Requires = rareza(ADULTO),
		Moment = "Decidiste qué hacer con diez minutos de más",
		Memory = "CajeroDeTiempo",
		Rewards = { Items = { BilleteMinutos = 1 } },
		Props = {
			Cajero = { Kind = "Pantalla", Name = "El cajero (que da minutos)", Prompt = "Sacar un billete", Place = "Banco", Offset = V(2, 0, 3), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Billete", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Cajero", Text = "Saca un billete del cajero" },
			{ Type = "Choice", Key = "Minutos", Text = "Tienes diez minutos de más en la mano. ¿Qué haces con ellos?",
				Options = {
					{ Id = "Siesta", Text = "Una siesta. Diez minutos exactos", Effects = { Traits = { Humor = 1 } } },
					{ Id = "Llamar", Text = "Llamar a {familia}, que hace mucho", Effects = { Traits = { Empatia = 2 } } },
					{ Id = "Devolver", Text = "Devolverlos al cajero: no son tuyos", Effects = { Traits = { Responsabilidad = 2 } } },
				} },
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Pip ha venido a arreglar el cajero",
				Actors = { { Npc = "Pip", Place = "Banco", Offset = V(-3, 0, 3) } } },
		},
		Dialogues = {
			Billete = { Lines = {
				{ S = "Narrador", T = "Un billete verde que pone «10 minutos». Cuando lo tocas, el reloj del banco se para un momento, como esperando a ver qué haces." },
			} },
			Pip = { Lines = {
				{ S = "Narrador", T = "Te sientas en un banco (de los de sentarse) y duermes diez minutos exactos. Te despiertas como nuevo. El reloj no se ha movido. Es la mejor siesta de tu vida.", If = { Choices = { Minutos = "Siesta" } } },
				{ S = "Narrador", T = "Llamas a {familia}. Habláis de todo y de nada. Al colgar, el reloj no se ha movido. Pero tú sí: te has movido por dentro.", If = { Choices = { Minutos = "Llamar" } } },
				{ S = "Narrador", T = "Metes el billete otra vez en el cajero. La pantalla se pone roja de vergüenza: «Nadie había devuelto nunca un minuto». Escupe un billete de regalo.", If = { Choices = { Minutos = "Devolver" } } },
				{ S = "Pip", T = "Un cable del cajero se enganchó en la Grieta, en la dimensión donde se guarda el tiempo que nadie usa. Por eso daba minutos. Ya está arreglado." },
				{ S = "Pip", T = "Quédese un billete. No lo gaste en tonterías. Bueno, sí: en tonterías bonitas. Para eso está el tiempo de más." },
			} },
		},
	},
}
