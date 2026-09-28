-- UNIVERSIDAD · SECUNDARIAS CON TUS COMPAÑEROS (vida de campus, con toques locos que enlazan con la saga).
-- Ficha de diseño: docs/historia/14-universidad-real.md
--
--   UniS_Zumo       «La guerra del zumo de mora»   alguien se bebe el zumo sagrado de Iván; Iván y Candela en guerra
--   UniS_Fiesta     «Fiesta en casa de Adrián»      la compra, la fiesta, el vecino y la agente Inés
--   UniS_Acampada   «Acampada en el monte»          tienda, hoguera, historias de miedo… y una visita de la nave
--   UniS_Playa      «Día de playa»                  voley, castillos de arena y Don Pinzas, cangrejo abogado
--   UniS_Pabellon0  «El pabellón que no sale en los mapas»  un edificio olvidado del campus: el laboratorio de Cosme y Cósimo
--   UniS_Cita       «Una cita (o algo así)»         con quien te gusta de tu clase: helado, atardecer y decir la verdad
--   UniS_Tito       «El compañero que no existe»    un cuarto compañero de cuarto que nadie recuerda… y el Consorcio
--
-- Todas necesitan la residencia (Uni01b) y se ofrecen en sitios del campus. Las que tocan la saga dejan
-- marcas (Flags) que la saga usará: VioPabellon0, TitoDescubierto, MorasDelMonte.

local V = Vector3.new

local function uni(extra: { [string]: any }?): { [string]: any }
	local req = { Stage = { Min = "AdultoJoven", Max = "AdultoJoven" }, Completed = { "Uni01b_Residencia" } }
	for key, value in extra or {} do
		req[key] = value
	end
	return req
end

local COCINA = {
	{ Npc = "Ivan", Place = "CocinaResidencia", Offset = V(-3, 0, 2) },
	{ Npc = "Candela", Place = "CocinaResidencia", Offset = V(3, 0, 2) },
}

return {
	---------------------------------------------------------------------
	-- La guerra del zumo de mora
	---------------------------------------------------------------------
	{
		Id = "UniS_Zumo",
		Kind = "Side",
		Title = "La guerra del zumo de mora",
		Description = "Falta una botella del zumo de mora de Iván. Iván acusa a Candela. Candela acusa a Iván de acusar. La habitación 214 está en guerra.",
		Type = "Universidad · Compañeros de cuarto",
		Duration = { 15, 20 },
		Npcs = { "Ivan", "Candela", "Portero", "Luca" },
		Offer = { Place = "CocinaResidencia" },
		OfferKey = "¡GRITOS en la cocina de la residencia! Algo de un zumo…",
		Requires = uni(),
		Moment = "Resolviste el misterio del zumo de mora",
		Memory = "ZumoDeMora",
		Rewards = { Items = { ZumoMora = 1 }, Flags = { "MorasDelMonte" } },
		Props = {
			Vaso = { Kind = "Papelera", Name = "La papelera de la cocina", Prompt = "Mirar dentro", Place = "CocinaResidencia", Offset = V(5, 0, -2), Dialogue = "Vaso", Once = true },
			Huellas = { Kind = "Huella", Name = "Huellas moradas en el pasillo", Prompt = "Seguir las huellas", Place = "Residencia", Offset = V(3, 0, 3), Dialogue = "Huellas", Once = true },
			Etiqueta = { Kind = "Papel", Name = "La etiqueta de la botella", Prompt = "Leer la etiqueta", Place = "CocinaResidencia", Offset = V(-5, 0, -2), Dialogue = "Etiqueta", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Guerra", Actors = COCINA },
			{ Type = "Group", Text = "Investiga quién se ha bebido el zumo",
				Actors = {
					{ Npc = "Ivan", Place = "CocinaResidencia", Offset = V(-3, 0, 2), Mode = "Sit" },
					{ Npc = "Candela", Place = "CocinaResidencia", Offset = V(3, 0, 2) },
					{ Npc = "Portero", Place = "Residencia", Offset = V(0, 0, 4) },
				},
				Steps = {
					{ Type = "Use", Prop = "Vaso", Text = "La papelera" },
					{ Type = "Use", Prop = "Huellas", Text = "El pasillo" },
					{ Type = "Use", Prop = "Etiqueta", Text = "La botella vacía" },
					{ Type = "Talk", Npc = "Portero", Dialogue = "Pilar", Text = "Doña Pilar (lo ve todo)" },
				} },
			{ Type = "Choice", Key = "Culpable", Text = "Ya sabes quién fue. ¿Cómo se lo dices?",
				Options = {
					{ Id = "Suave", Text = "Con tacto: sentarles a los dos y contarlo con calma", Effects = { Rel = { Ivan = 5, Candela = 5 }, Traits = { Empatia = 2 } } },
					{ Id = "Video", Text = "Con pruebas: el vídeo de la cámara de Candela", Effects = { Rel = { Candela = 4 }, Traits = { Humor = 1 } } },
				},
				Actors = COCINA },
			{ Type = "Scene", Dialogue = "Verdad", Actors = COCINA },
		},
		Dialogues = {
			Guerra = { Lines = {
				{ S = "Ivan", T = "¡FALTA UNA BOTELLA! ¡De las tres sagradas! ¡Candela, tú lo etiquetas todo, seguro que la etiquetaste y te la bebiste!" },
				{ S = "Candela", T = "Yo no bebo nada que no tenga fecha de caducidad. Tu zumo tiene una etiqueta que pone «de la abuela». ¿Eso qué es? ¿Un año? ¿Un siglo?" },
				{ S = "Ivan", T = "¡Es una calidad! ¡Guerra! ¡Declaro la guerra! ¡A partir de ahora esta cocina está dividida por una línea de cinta aislante!" },
				{ S = "Narrador", T = "Iván pega cinta aislante en el suelo. Candela pega cinta aislante de colores encima, más recta. Esto va a ir a peor." },
			} },
			Vaso = { Lines = {
				{ S = "Narrador", T = "En la papelera: un vaso con restos morados. Y… ¿un pijama? Un pijama de dinosaurios, manchado de morado. Talla de Iván." },
			} },
			Huellas = { Lines = {
				{ S = "Narrador", T = "Huellas moradas de pies descalzos. Van de la cocina a la habitación 214. En zigzag. Como quien camina dormido." },
			} },
			Etiqueta = { Lines = {
				{ S = "Narrador", T = "La etiqueta, con letra de abuela: «Zumo de mora. Moras del Monte del Silencio, cogidas de noche. NO BEBER DE MADRUGADA, que da sonambulismo. Te quiere, la abuela»." },
				{ S = "Narrador", T = "¿Moras del Monte del Silencio? ¿El monte de las luces raras? Apuntas eso para otro momento." },
			} },
			Pilar = { Lines = {
				{ S = "Portero", T = "¿El zumo? A las tres de la mañana vi a alguien en pijama de dinosaurios bebiendo de la botella a morro, con los ojos cerrados, cantando una jota." },
				{ S = "Portero", T = "Le dije «buenas noches» y me dijo «sí, abuela». Cuarenta años aquí. Lo he visto todo." },
			} },
			Verdad = { Lines = {
				{ S = "Narrador", T = "Os sentáis los tres en la cocina. Les cuentas lo que has descubierto, con calma.", If = { Choices = { Culpable = "Suave" } } },
				{ S = "Narrador", T = "Candela pone el vídeo de su cámara de seguridad «para tápers». Se ve a Iván, dormido, bebiendo zumo y bailando una jota.", If = { Choices = { Culpable = "Video" } } },
				{ S = "Ivan", T = "…¿Fui YO? ¿Dormido? ¿Cantando? …Mi abuela me lo advirtió. «No lo bebas de madrugada». Y yo, de madrugada, sin enterarme." },
				{ S = "Candela", T = "O sea, que llevas dos semanas acusándome de algo que hiciste tú en pijama de dinosaurios." },
				{ S = "Ivan", T = "…Perdón, Candela. De verdad. Te invito a zumo de mora. De día. Despierto." },
				{ S = "Candela", T = "Acepto. Y quito la cinta aislante. Pero me quedo la de colores. Era muy bonita." },
				{ S = "Narrador", T = "Fin de la guerra. Iván te regala la última botella «por detective». Recibes 🍇 una botella de zumo de mora del Monte del Silencio. No la bebas de madrugada." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Fiesta en casa de Adrián
	---------------------------------------------------------------------
	{
		Id = "UniS_Fiesta",
		Kind = "Side",
		Title = "Fiesta en casa de Adrián",
		Description = "Adrián ha invitado a toda la clase a su piso. «Traed algo de comer». Iván ya ha preparado el zumo de mora. De día, esta vez.",
		Type = "Universidad · Planes con la clase",
		Duration = { 15, 20 },
		Npcs = { "Adrian", "Julia", "Pablo", "Ivan", "Candela", "Vecino", "Ines" },
		Offer = { Place = "Universidad" },
		OfferKey = "Adrián reparte invitaciones: «FIESTA EN MI PISO ESTE SÁBADO. Traed comida.»",
		Requires = uni({ Hours = { From = 17, To = 23 } }),
		Moment = "La fiesta en casa de Adrián",
		Memory = "FiestaAdrian",
		Steps = {
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Supermercado" }, Place = "Supermercado", Text = "Compra algo para llevar a la fiesta" },
			{ Type = "Reach", Place = "CafeteriaCentral", Text = "Ve a la fiesta (Adrián vive encima de la cafetería del centro)",
				Actors = {
					{ Npc = "Adrian", Place = "CafeteriaCentral", Offset = V(0, 0, 5), Mode = "Wave" },
					{ Npc = "Julia", Place = "CafeteriaCentral", Offset = V(-5, 0, 6), Mode = "Dance" },
					{ Npc = "Pablo", Place = "CafeteriaCentral", Offset = V(5, 0, 7), Mode = "Chat" },
					{ Npc = "Ivan", Place = "CafeteriaCentral", Offset = V(-3, 0, 9), Mode = "Dance" },
					{ Npc = "Candela", Place = "CafeteriaCentral", Offset = V(3, 0, 9), Mode = "Chat" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "¡A bailar!", Icon = "🕺", Hint = "Pasos al ritmo de la música",
				Rounds = 5, Need = 3, Zone = 0.28, Speed = 1,
				Win = { Flags = { "ReyDeLaPista" }, Traits = { Humor = 1 } }, Lose = { Traits = { Humor = 1 } },
				Actors = {
					{ Npc = "Julia", Place = "CafeteriaCentral", Offset = V(-5, 0, 6), Mode = "Cheer" },
					{ Npc = "Ivan", Place = "CafeteriaCentral", Offset = V(-3, 0, 9), Mode = "Cheer" },
				} },
			{ Type = "Talk", Npc = "Vecino", Dialogue = "Vecino", Text = "Llaman a la puerta. Es el vecino de abajo…",
				Actors = { { Npc = "Vecino", Place = "CafeteriaCentral", Offset = V(0, 0, -4) }, { Npc = "Adrian", Place = "CafeteriaCentral", Offset = V(2, 0, 2) } } },
			{ Type = "Scene", Dialogue = "Final",
				Actors = {
					{ Npc = "Ines", Place = "CafeteriaCentral", Offset = V(0, 0, -4) },
					{ Npc = "Pablo", Place = "CafeteriaCentral", Offset = V(5, 0, 7), Mode = "Sit" },
					{ Npc = "Adrian", Place = "CafeteriaCentral", Offset = V(2, 0, 2) },
				} },
		},
		Dialogues = {
			Vecino = { Lines = {
				{ S = "Vecino", T = "Buenas noches. Vivo abajo. Tengo ochenta años, un perro que se asusta y una lámpara que está bailando sola por culpa de vuestra música." },
				{ Ask = "¿Qué haces?", Options = {
					{ T = "«Perdone. Bajamos la música ahora mismo. ¿Quiere un trozo de tarta?»", Effects = { Traits = { Empatia = 2 }, Flags = { "FiestaTranquila" } }, Then = {
						{ S = "Vecino", T = "¿Tarta? …Bueno. Un trozo. Pequeño. Y el perro también, si hay." },
						{ S = "Narrador", T = "El vecino se queda una hora. Resulta que en los años sesenta ganaba concursos de twist. Os enseña a todos. Es el mejor momento de la fiesta." },
					} },
					{ T = "«Es sábado, señor. Es lo normal.»", Effects = { Traits = { Rebeldia = 1 } }, Then = {
						{ S = "Vecino", T = "Lo normal. Ya. Pues lo normal es que llame a quien tenga que llamar. Buenas noches." },
					} },
				} },
			} },
			Final = { Lines = {
				{ S = "Ines", T = "Buenas noches, chavales. Me han llamado por… ¿un señor mayor bailando twist en el rellano? ¿Está todo bien?", If = { Flags = { "FiestaTranquila" } } },
				{ S = "Ines", T = "Buenas noches. Tenemos una queja por ruido. Música más baja, y a las doce se acaba. No me hagáis volver.", If = { NotFlags = { "FiestaTranquila" } } },
				{ S = "Ines", T = "¿Otra vez tú? Siempre estás donde pasan cosas raras. …Esta vez es solo una fiesta. Qué alivio." },
				{ S = "Pablo", T = "(tocando la guitarra, bajito) Esta canción se llama «Fiesta en casa de Adrián». La acabo de inventar. Tiene tres acordes y un vecino." },
				{ S = "Narrador", T = "A la una volvéis andando a la residencia. Iván lleva a Candela a caballito. Nadie sabe por qué. Nadie pregunta." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Acampada en el monte
	---------------------------------------------------------------------
	{
		Id = "UniS_Acampada",
		Kind = "Side",
		Title = "Acampada en el monte",
		Description = "Iván quiere acampar en el Monte del Silencio: «Para coger moras para mi abuela». Candela ha hecho una lista de 40 cosas. Tú llevas la linterna.",
		Type = "Universidad · Planes con la clase",
		Duration = { 20, 25 },
		Npcs = { "Ivan", "Candela", "Julia", "Luca", "Blorp" },
		Offer = { Place = "HabitacionResidencia" },
		OfferKey = "Iván entra en el cuarto con una tienda de campaña: «¡Este finde, ACAMPADA!»",
		Requires = uni({ Completed = { "Uni01b_Residencia", "UniS_Zumo" } }),
		Moment = "La acampada en el Monte del Silencio",
		Memory = "Acampada",
		Rewards = { Items = { TazaCampamento = 1 } },
		Props = {
			Tienda = { Kind = "Caja", Name = "La tienda de campaña (sin montar)", Prompt = "Montar la tienda", Place = "MonteSilencio", Offset = V(4, 0, 4), Color = Color3.fromRGB(60, 150, 90), Dialogue = "Tienda", Once = true },
			Hoguera = { Kind = "Cristal", Name = "La hoguera", Prompt = "Encender la hoguera", Place = "MonteSilencio", Offset = V(0, 0, 8), Color = Color3.fromRGB(255, 150, 60), Dialogue = "Hoguera", Once = true },
			Moras = { Kind = "Escarabajo", Name = "Un zarzal lleno de moras (que brillan un poco)", Prompt = "Coger moras", Place = "MonteSilencio", Offset = V(-6, 0, 6), Color = Color3.fromRGB(110, 40, 140), Dialogue = "Moras", Once = true },
			Luz = { Kind = "Nave", Name = "Una luz sobre el monte", Place = "MonteSilencio", Offset = V(0, 0, -10), Height = 30, Beam = false, Prompt = false },
		},
		Steps = {
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Supermercado" }, Place = "Supermercado", Text = "Compra comida para la acampada" },
			{ Type = "Reach", Place = "MonteSilencio", Text = "Sube al Monte del Silencio con el grupo",
				Actors = { { Npc = "Ivan", Mode = "Follow" }, { Npc = "Candela", Mode = "Follow" }, { Npc = "Julia", Mode = "Follow" }, { Npc = "Luca", Mode = "Follow" } } },
			{ Type = "Group", Text = "Prepara el campamento",
				Actors = {
					{ Npc = "Ivan", Place = "MonteSilencio", Offset = V(-4, 0, 8), Mode = "Chat" },
					{ Npc = "Candela", Place = "MonteSilencio", Offset = V(4, 0, 10), Mode = "Chat" },
					{ Npc = "Julia", Place = "MonteSilencio", Offset = V(-2, 0, 11), Mode = "Chat" },
					{ Npc = "Luca", Place = "MonteSilencio", Offset = V(2, 0, 12), Mode = "Chat" },
				},
				Steps = {
					{ Type = "Use", Prop = "Tienda", Text = "Monta la tienda" },
					{ Type = "Use", Prop = "Moras", Text = "Coge moras para la abuela de Iván" },
					{ Type = "Use", Prop = "Hoguera", Text = "Enciende la hoguera" },
				} },
			{ Type = "Scene", Dialogue = "Historias",
				Actors = {
					{ Npc = "Ivan", Place = "MonteSilencio", Offset = V(-3, 0, 10), Mode = "Sit" },
					{ Npc = "Candela", Place = "MonteSilencio", Offset = V(3, 0, 10), Mode = "Sit" },
					{ Npc = "Julia", Place = "MonteSilencio", Offset = V(-2, 0, 12), Mode = "Sit" },
					{ Npc = "Luca", Place = "MonteSilencio", Offset = V(2, 0, 12), Mode = "Sit" },
				} },
			{ Type = "Scene", Dialogue = "Visita", Props = { "Luz" },
				Actors = {
					{ Npc = "Blorp", Place = "MonteSilencio", Offset = V(0, 0, 4), Mode = "Wave" },
					{ Npc = "Ivan", Place = "MonteSilencio", Offset = V(-3, 0, 10), Mode = "Sit" },
					{ Npc = "Candela", Place = "MonteSilencio", Offset = V(3, 0, 10), Mode = "Sit" },
				} },
		},
		Dialogues = {
			Tienda = { Lines = {
				{ S = "Narrador", T = "Las instrucciones de la tienda vienen en sueco. Candela las traduce con el móvil. Iván monta la tienda al revés. Dos veces." },
			} },
			Moras = { Lines = {
				{ S = "Narrador", T = "Un zarzal enorme. Las moras brillan un poquito en la oscuridad. Como si tuvieran pilas. Iván dice que es normal. Candela dice que no lo es. Tú no dices nada, porque ya sabes de qué monte es esto." },
			} },
			Hoguera = { Lines = {
				{ S = "Narrador", T = "La hoguera prende a la tercera. Luca saca un paquete de nubes de azúcar de Bolonia. Dice que son mejores. Son iguales." },
			} },
			Historias = { Lines = {
				{ S = "Julia", T = "Historia de miedo. Hace años, en este monte, desaparecía gente. Una luz a las tres de la mañana. Y la gente volvía… diciendo que había salido en la tele." },
				{ S = "Luca", T = "En Bolonia tenemos una parecida, pero con un fantasma que corrige la pronunciación. Da mucho más miedo." },
				{ S = "Yo", T = "Esa historia es verdad. Yo estuve allí. Eran alienígenas de un reality.", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "Candela", T = "Claro. Y yo soy la reina de Inglaterra. Siguiente historia.", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "Ivan", T = "Mi abuela dice que las moras de este monte son mágicas. Que por eso su zumo da sonambulismo. Y que una vez una luz le pidió la receta." },
				{ Ask = "¿Qué historia cuentas tú?", Options = {
					{ T = "La del vecino inventor que cosió el cielo", Effects = { Traits = { Humor = 1 } }, If = { Flags = { "SagaActo1" } }, Then = {
						{ S = "Julia", T = "¿Coser el cielo? Tienes más imaginación que Pablo. Y Pablo escribe canciones sobre tostadoras." },
					} },
					{ T = "Una de miedo de verdad: el día del examen de Beltrán", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Ivan", T = "¡NO! ¡Esa no! ¡Esa da miedo de verdad!" },
					} },
				} },
			} },
			Visita = { Lines = {
				{ S = "Narrador", T = "A las tres de la mañana, una luz se enciende sobre el monte. Todos se callan. De la luz baja flotando una figura verde con antenas." },
				{ S = "Blorp", T = "¡Blorp! ¡Hola, terrícola! ¡Te reconocí desde la nave! Solo venía a por moras. La capitana está enganchada al zumo.", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "Blorp", T = "¡Blorp! Perdón por la interrupción. Solo venía a por moras. Mi capitana está enganchada a un zumo que vende una abuela de Villaverde. No pregunten.", If = { NotCompleted = { "Loco_U1_Monte" } } },
				{ S = "Ivan", T = "…¿Mi abuela vende zumo a los alienígenas? ¿MI ABUELA? …Eso explica el coche nuevo." },
				{ S = "Narrador", T = "Blorp coge un puñado de moras, saluda y se va flotando. Candela ha grabado todo. Al día siguiente, el vídeo solo se ve borroso. Nadie os cree." },
				{ S = "Narrador", T = "Recibes ⛺ la Taza de campamento del grupo, con cuatro nombres y un dibujo de un alienígena que hizo Julia." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Día de playa
	---------------------------------------------------------------------
	{
		Id = "UniS_Playa",
		Kind = "Side",
		Title = "Día de playa",
		Description = "Día libre, sol y toda la clase en Playa Dorada. Voley, castillos de arena… y un cangrejo del tamaño de un coche que reclama la playa con un contrato de 1734.",
		Type = "Universidad · Planes con la clase",
		Duration = { 15, 20 },
		Npcs = { "Julia", "Adrian", "Carla", "Ivan", "Candela", "DonPinzas" },
		Offer = { Place = "Playa" },
		OfferKey = "¡Tu clase está en la playa! Te hacen señas desde la red de voley",
		Requires = uni(),
		Moment = "El día de playa con la clase",
		Memory = "PlayaClase",
		Rewards = { Items = { PinzaDeOro = 1 } },
		Props = {
			Castillo = { Kind = "Caja", Name = "Tu castillo de arena", Prompt = "Construir el castillo", Place = "Playa", Offset = V(6, 0, 4), Color = Color3.fromRGB(230, 210, 160), Dialogue = "Castillo", Once = true },
		},
		Steps = {
			{ Type = "MiniGame", Game = "Timing", Title = "Voley playa: tu clase contra la de al lado", Icon = "🏐", Hint = "Remata en el momento justo",
				Rounds = 5, Need = 3, Zone = 0.26, Speed = 1.1,
				Win = { Flags = { "GanasteVoley" } }, Lose = { Traits = { Humor = 1 } },
				Actors = {
					{ Npc = "Julia", Place = "Playa", Offset = V(-4, 0, 3), Mode = "Cheer" },
					{ Npc = "Adrian", Place = "Playa", Offset = V(4, 0, 3), Mode = "Cheer" },
					{ Npc = "Ivan", Place = "Playa", Offset = V(-2, 0, 7), Mode = "Cheer" },
				} },
			{ Type = "Use", Prop = "Castillo", Text = "Concurso de castillos de arena",
				Actors = { { Npc = "Candela", Place = "Playa", Offset = V(8, 0, 6) }, { Npc = "Carla", Place = "Playa", Offset = V(10, 0, 4) } } },
			{ Type = "Fight", Place = "Playa", Respawn = "Playa", Action = "Echarle un cubo de agua dulce 🪣", HP = 6, BeamColor = Color3.fromRGB(120, 200, 255),
				Text = "¡Don Pinzas quiere desalojar la playa! Échale agua dulce (la odia)",
				CaughtLine = "¡Pinza legal! (Te pellizca el bañador con mucha educación. Vuelves a la orilla.)",
				Actors = {
					{ Npc = "Julia", Place = "Playa", Offset = V(-8, 0, 10), Mode = "Cheer" },
					{ Npc = "Ivan", Place = "Playa", Offset = V(-4, 0, 12), Mode = "Cheer" },
				},
				Enemies = {
					{ Npc = "DonPinzas", Offset = V(0, 0, -12), Speed = 9, Scale = 2, HP = 6,
						Hurt = "¡Agua dulce! ¡Protesto, señoría! ¡Esto es contrario al tratado de 1734!",
						Bye = "¡Me retiro a deliberar al fondo del mar! Pero el contrato sigue vigente… en Plutón." },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = {
					{ Npc = "Julia", Place = "Playa", Offset = V(-4, 0, 3), Mode = "Sit" },
					{ Npc = "Adrian", Place = "Playa", Offset = V(4, 0, 3), Mode = "Sit" },
					{ Npc = "Ivan", Place = "Playa", Offset = V(-2, 0, 7), Mode = "Sit" },
					{ Npc = "Candela", Place = "Playa", Offset = V(2, 0, 7), Mode = "Sit" },
				} },
		},
		Dialogues = {
			Castillo = { Lines = {
				{ S = "Narrador", T = "Candela construye una réplica exacta de la facultad, con escala. Carla hace un dragón. Tú haces… un castillo. Con foso. Y una bandera de patata frita." },
				{ S = "Narrador", T = "De repente la arena tiembla. Del mar sale un cangrejo enorme, con corbata y un maletín. Te mira por encima de las gafas." },
				{ S = "DonPinzas", T = "{Saludo}. Don Pinzas, abogado. Según el Tratado de las Mareas de 1734, esta playa pertenece a los crustáceos. Tienen diez minutos para desalojar. Firmen aquí." },
			} },
			Final = { Lines = {
				{ S = "Julia", T = "¿Hemos… luchado contra un cangrejo abogado? ¿Con cubos? Esto no lo pongo en mis memorias. Nadie me creería." },
				{ S = "Adrian", T = "Lo mejor ha sido cuando Iván ha intentado negociar con él. En crustáceo." },
				{ S = "Ivan", T = "¡Me ha entendido! Me ha dicho «clic, clic». Que es «hasta luego» en cangrejo. Seguro." },
				{ S = "Narrador", T = "Os quedáis hasta el atardecer. Nadie saca el móvil. Es de esas tardes que luego recuerdas sin saber muy bien por qué." },
				{ S = "Narrador", T = "En la arena, donde estaba Don Pinzas, hay una pinza dorada. Se le cayó. Recibes 🦀 la Pinza de oro de Don Pinzas." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- El pabellón que no sale en los mapas
	---------------------------------------------------------------------
	{
		Id = "UniS_Pabellon0",
		Kind = "Side",
		Title = "El pabellón que no sale en los mapas",
		Description = "En un mapa antiguo del campus, en la biblioteca, hay un edificio que no aparece en ningún otro: el «Pabellón 0». Candela dice que es un error de impresión. Tú no estás tan seguro.",
		Type = "Universidad · Lugares abandonados",
		Duration = { 20, 25 },
		Npcs = { "Candela", "Ivan", "AgenteGris1" },
		Offer = { Place = "Biblioteca" },
		OfferKey = "En la biblioteca, un mapa viejo del campus se cae de una estantería. Hay un edificio que no conoces…",
		Requires = uni(),
		Moment = "Encontraste el Pabellón 0",
		Memory = "Pabellon0",
		Rewards = { Items = { FotoCosmeCosimo = 1 }, Flags = { "VioPabellon0" } },
		Props = {
			Mapa = { Kind = "Papel", Name = "El mapa antiguo del campus", Prompt = "Mirar el mapa", Place = "Biblioteca", Offset = V(3, 0, 2), Dialogue = "Mapa", Once = true },
			Puerta = { Kind = "Armario", Name = "Una puerta tapiada entre los árboles", Prompt = "Empujar la puerta", Place = "ResidenciaCampus", Offset = V(18, 0, 10), Dialogue = "Puerta", Once = true },
			Pizarra = { Kind = "Mural", Name = "Una pizarra llena de fórmulas", Prompt = "Leer la pizarra", Place = "ResidenciaCampus", Offset = V(22, 0, 14), Color = Color3.fromRGB(40, 60, 50), Dialogue = "Pizarra", Once = true },
			Maquina = { Kind = "Maquina", Name = "Una máquina enorme cubierta con una sábana", Prompt = "Levantar la sábana", Place = "ResidenciaCampus", Offset = V(26, 0, 10), Dialogue = "Maquina", Once = true },
			Foto = { Kind = "Papel", Name = "Una foto en el suelo", Prompt = "Coger la foto", Place = "ResidenciaCampus", Offset = V(24, 0, 6), Dialogue = "Foto", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Mapa", Text = "Mira el mapa antiguo", Actors = { { Npc = "Candela", Place = "Biblioteca", Offset = V(4, 0, 3) } } },
			{ Type = "Use", Prop = "Puerta", Text = "Busca el Pabellón 0 detrás de la residencia (entre los árboles)",
				Actors = { { Npc = "Candela", Mode = "Follow" }, { Npc = "Ivan", Mode = "Follow" } } },
			{ Type = "Group", Text = "Explora el pabellón abandonado",
				Actors = { { Npc = "Candela", Mode = "Follow" }, { Npc = "Ivan", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Pizarra", Text = "La pizarra" },
					{ Type = "Use", Prop = "Maquina", Text = "La máquina tapada" },
					{ Type = "Use", Prop = "Foto", Text = "Algo en el suelo" },
				} },
			{ Type = "Escape", Place = "Residencia", Respawn = "ResidenciaCampus", Catch = 4,
				Text = "¡Un agente gris del Consorcio! Vuelve a la residencia sin que te atrape",
				CaughtLine = "Documentación, por favor. …Ah, que corre. Corra, corra. (Te suelta y vuelves junto al pabellón.)",
				Actors = {
					{ Npc = "Candela", Mode = "Follow" },
					{ Npc = "Ivan", Mode = "Follow" },
					{ Npc = "AgenteGris1", Place = "ResidenciaCampus", Offset = V(30, 0, 14), Mode = "Hunt", Speed = 11, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Final", Teleport = "HabitacionResidencia",
				Actors = { { Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2) }, { Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2) } } },
		},
		Dialogues = {
			Mapa = { Lines = {
				{ S = "Narrador", T = "Un mapa del campus de hace veinte años. Todo está igual… menos un edificio pequeño detrás de la residencia, entre los árboles: «Pabellón 0 — Laboratorio de Física Aplicada. ACCESO RESTRINGIDO»." },
				{ S = "Candela", T = "Pabellón 0 no existe. He hecho el recorrido de todos los edificios del campus. Tengo un Excel. No existe." },
				{ S = "Candela", T = "…Vale. Ahora tengo que ir a comprobarlo. Por el Excel." },
			} },
			Puerta = { Lines = {
				{ S = "Narrador", T = "Entre los árboles, una puerta tapiada con tablones viejos. Nadie la ve porque nadie mira aquí. Los tablones ceden al primer empujón." },
				{ S = "Ivan", T = "Si esto es una película de miedo, yo soy el que se queda fuera vigilando. Y el que sobrevive." },
			} },
			Pizarra = { Lines = {
				{ S = "Narrador", T = "Una pizarra llena de fórmulas. En una esquina, dibujado con tiza: un cielo, una línea que lo cruza… y una aguja. Debajo: «Proyecto Costura»." },
				{ S = "Narrador", T = "Hay dos firmas. Una letra redonda: «C.». Otra letra muy elegante, con florituras: «C.»." },
			} },
			Maquina = { Lines = {
				{ S = "Narrador", T = "Debajo de la sábana hay una máquina del tamaño de un coche, llena de cables y agujas. Tiene una placa: «Cosedora Dimensional, prototipo 1»." },
				{ S = "Narrador", T = "Tiene la parte de delante quemada. Como si hubiera explotado hacia dentro. Hace mucho tiempo. Casi tanto tiempo como tú tienes." },
			} },
			Foto = { Lines = {
				{ S = "Narrador", T = "Una foto. Dos jóvenes con bata delante de la máquina, sonriendo, con los pulgares arriba. Uno tiene el pelo de punta. Es Cosme. De joven." },
				{ S = "Narrador", T = "El otro es idéntico a él. Pero más peinado. Y con una sonrisa de anuncio de la tele. Por detrás: «Cosme y Cósimo. La noche antes de la prueba»." },
				{ S = "Narrador", T = "Unos pasos fuera. Alguien con traje gris mira por la ventana. Sonríe. Exactamente como en la foto." },
			} },
			Final = { Lines = {
				{ S = "Candela", T = "Vale. Resumen para mi Excel: edificio que no existe, máquina que explotó, dos señores iguales y un hombre de gris que nos persigue. Necesito una columna nueva." },
				{ S = "Ivan", T = "Yo necesito zumo de mora. De día." },
				{ S = "Narrador", T = "Guardas la foto de Cosme y Cósimo. Algún día tendrás que preguntarle a Cosme por esa noche. Recibes 📸 la foto de Cosme y Cósimo, jóvenes." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Una cita (o algo así) — opcional, con alguien de tu clase (nunca con otro jugador)
	---------------------------------------------------------------------
	{
		Id = "UniS_Cita",
		Kind = "Side",
		Title = "Una cita (o algo así)",
		Description = "Hay alguien de tu clase con quien siempre acabas hablando más de la cuenta. Iván dice que es obvio. Candela ha hecho un gráfico. ¿Te atreves a invitarle a un helado?",
		Type = "Universidad · Corazón (opcional)",
		Duration = { 15, 20 },
		Npcs = { "Julia", "Adrian", "Luca", "Carla", "Ivan", "Candela" },
		Offer = { Place = "HabitacionResidencia" },
		OfferKey = "Iván y Candela te miran con cara de «tenemos que hablar de alguien»…",
		Requires = uni({ Completed = { "Uni01b_Residencia", "UniEx1_Enero" } }),
		Moment = "Una tarde de helado y atardecer",
		Memory = "LaCita",
		Steps = {
			{ Type = "Scene", Dialogue = "Consejo",
				Actors = { { Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2), Mode = "Sit" }, { Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2) } } },
			{ Type = "Choice", Key = "Cita", Text = "¿A quién invitas a un helado? (habla con esa persona en el campus)",
				Options = {
					{ Id = "Julia", Npc = "Julia", Text = "Julia" },
					{ Id = "Adrian", Npc = "Adrian", Text = "Adrián" },
					{ Id = "Luca", Npc = "Luca", Text = "Luca" },
					{ Id = "Carla", Npc = "Carla", Text = "Carla" },
				},
				Actors = {
					{ Npc = "Julia", Place = "Universidad", Offset = V(-8, 0, 4) },
					{ Npc = "Adrian", Place = "Universidad", Offset = V(-4, 0, 6) },
					{ Npc = "Luca", Place = "Universidad", Offset = V(4, 0, 6) },
					{ Npc = "Carla", Place = "Universidad", Offset = V(8, 0, 4) },
				} },
			{ Type = "Scene", Dialogue = "Invitacion" },
			{ Type = "Event", Event = "BoughtItem", Match = { ShopId = "Heladeria" }, Place = "Heladeria", Text = "Compra dos helados en la heladería" },
			{ Type = "Reach", Place = "Playa", Hours = { From = 18, To = 22 }, Text = "Id a ver el atardecer a Playa Dorada (entre las 18:00 y las 22:00)" },
			{ Type = "Scene", Dialogue = "Atardecer" },
		},
		Dialogues = {
			Consejo = { Lines = {
				{ S = "Ivan", T = "Mira. Lo sabe toda la residencia. Cada vez que hablas de clase dices su nombre tres veces. Lo ha contado Candela." },
				{ S = "Candela", T = "Cuatro coma dos veces de media. Tengo un gráfico. Mi consejo profesional: invítale a un helado. Si sale mal, siempre te queda el helado." },
			} },
			Invitacion = { Lines = {
				{ S = "Julia", T = "¿Un helado? ¿Conmigo? …Vale. Pero yo elijo el sabor. Y no se lo digas a Adrián, que me pregunta todo.", If = { Choices = { Cita = "Julia" } } },
				{ S = "Adrian", T = "¿Un helado? ¿Tú y yo? …Sí. O sea, sí. Claro. Tengo un hueco a las seis. Lo tenía libre, no es que lo haya quitado ahora mismo.", If = { Choices = { Cita = "Adrian" } } },
				{ S = "Luca", T = "¿Gelato? ¿Conmigo? Mamma mia. En Bolonia esto es casi un compromiso. Aquí… también un poquito. Sí. Sí, sí.", If = { Choices = { Cita = "Luca" } } },
				{ S = "Carla", T = "¿Un helado? …¡Llego a tiempo! ¡Te lo prometo! Por primera vez en mi vida, llego a tiempo. Me pongo tres alarmas.", If = { Choices = { Cita = "Carla" } } },
			} },
			Atardecer = { Lines = {
				{ S = "Narrador", T = "Playa Dorada. El sol se esconde detrás del mar. Dos helados, un poco derretidos. Y un silencio que no es incómodo." },
				{ S = "Julia", T = "¿Sabes? El primer día de clase pensé que eras la persona más despistada del campus. …Sigo pensándolo. Pero me gusta.", If = { Choices = { Cita = "Julia" } } },
				{ S = "Adrian", T = "Siempre quiero mandar en todo. Contigo no me pasa. No sé si eso es bueno o malo. Creo que bueno.", If = { Choices = { Cita = "Adrian" } } },
				{ S = "Luca", T = "Cuando llegué aquí no conocía a nadie. Ahora hay alguien con quien quiero ver atardeceres. Eso es mejor que la pasta. Casi.", If = { Choices = { Cita = "Luca" } } },
				{ S = "Carla", T = "He llegado a tiempo. Y el atardecer también. Es la primera vez que no me pierdo nada importante. Gracias por invitarme.", If = { Choices = { Cita = "Carla" } } },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Me gustas. Me gustas mucho.»", Effects = { Flags = { "TienePareja" }, Traits = { Valentia = 2 } }, Then = {
						{ S = "Narrador", T = "Te mira. Sonríe. Te coge de la mano. No hace falta decir nada más. El sol termina de esconderse." },
					} },
					{ T = "«Eres de las mejores personas que he conocido aquí.»", Effects = { Flags = { "AmistadEspecial" }, Traits = { Empatia = 1 } }, Then = {
						{ S = "Narrador", T = "Sonríe. «Tú también». Chocáis los helados como si fueran copas. Una amistad así también es un tesoro." },
					} },
					{ T = "Te pones tan nervioso o nerviosa que se te cae el helado", Effects = { Traits = { Humor = 2 } }, Then = {
						{ S = "Narrador", T = "El helado aterriza en tu zapatilla. Os da un ataque de risa que dura cinco minutos. Te ofrece la mitad del suyo. Eso ya es una respuesta." },
					} },
				} },
			} },
		},
	},

	---------------------------------------------------------------------
	-- El compañero que no existe
	---------------------------------------------------------------------
	{
		Id = "UniS_Tito",
		Kind = "Side",
		Title = "El compañero que no existe",
		Description = "Hay un chico nuevo en tu habitación. Dice que se llama Tito y que siempre ha vivido aquí. Sale en todas vuestras fotos. Nadie recuerda haberle conocido.",
		Type = "Universidad · Misterio (saga de la Grieta)",
		Duration = { 15, 20 },
		Npcs = { "Tito", "Ivan", "Candela", "Portero" },
		Offer = { Place = "HabitacionResidencia" },
		OfferKey = "Hay alguien durmiendo en la cama de al lado. Te saluda: «¡Hola, compi!»",
		Requires = uni({ Completed = { "Uni01b_Residencia", "UniS_Pabellon0" } }),
		Moment = "Desenmascaraste al espía del Consorcio",
		Memory = "TitoEspia",
		Rewards = { Flags = { "TitoDescubierto" } },
		Props = {
			Fotos = { Kind = "Mural", Name = "El corcho de fotos", Prompt = "Mirar las fotos", Place = "HabitacionResidencia", Offset = V(0, 0, -4), Color = Color3.fromRGB(190, 150, 100), Dialogue = "Fotos", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Tito", Dialogue = "Hola", Text = "Habla con el «compañero» nuevo",
				Actors = { { Npc = "Tito", Place = "HabitacionResidencia", Offset = V(0, 0, 3) }, { Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2), Mode = "Sit" } } },
			{ Type = "Use", Prop = "Fotos", Text = "Mira las fotos del corcho",
				Actors = { { Npc = "Tito", Place = "HabitacionResidencia", Offset = V(0, 0, 3), Mode = "Wave" } } },
			{ Type = "Talk", Npc = "Portero", Dialogue = "Registro", Text = "Pregunta a Doña Pilar por el registro de la residencia",
				Actors = { { Npc = "Portero", Place = "Residencia", Offset = V(0, 0, 4) } } },
			{ Type = "Talk", Npc = "Tito", Dialogue = "Confrontar", Text = "Vuelve a la habitación y enfréntate a «Tito»",
				Actors = { { Npc = "Tito", Place = "HabitacionResidencia", Offset = V(0, 0, 3) }, { Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2) } } },
			{ Type = "Fight", Place = "HabitacionResidencia", Respawn = "Residencia", Action = "Quitarle la peluca 👱", HP = 3, BeamColor = Color3.fromRGB(200, 200, 60),
				Text = "¡«Tito» se quita la sonrisa y viene a por ti! Arráncale el disfraz",
				CaughtLine = "¡Oferta de fidelización! (Te intenta hacer firmar un contrato. Te escapas al pasillo.)",
				Actors = { { Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2), Mode = "Point" } },
				Enemies = {
					{ Npc = "Tito", Offset = V(0, 0, 3), Speed = 11, Hurt = "¡Compi! ¡Somos compis! ¡Los compis no se quitan la peluca!", Bye = "¡Informe a MegaVerso: el Ancla tiene amigos muy pesados! (Chispas grises. Fuera.)" },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = { { Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2) }, { Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2) } } },
		},
		Dialogues = {
			Hola = { Lines = {
				{ S = "Tito", T = "¡{Saludo}, compi! Soy Tito. Tu compañero de cuarto. De siempre. Desde el primer día. ¿No te acuerdas? Qué gracioso eres." },
				{ S = "Ivan", T = "(susurrando) Yo creo que sí me acuerdo de él. Creo. Me suena. Como una canción que no has oído nunca." },
				{ S = "Tito", T = "Por cierto, compi, ¿tú nunca has notado nada raro en tu vida? ¿Luces? ¿Grietas? ¿Un vecino con inventos? Pregunto por nada. Por curiosidad de compi." },
			} },
			Fotos = { Lines = {
				{ S = "Narrador", T = "El corcho de fotos: la primera cena, la fiesta de Adrián, el día de playa… Tito sale en todas. Siempre en el borde. Siempre sonriendo. Siempre mirando a cámara." },
				{ S = "Narrador", T = "Pero en la foto de la cocina, la sartén quemada tapa la mitad de la cara de Iván… y a Tito se le ve la oreja por detrás de la sartén. No puede estar ahí. La sartén está pegada a la pared." },
			} },
			Registro = { Lines = {
				{ S = "Portero", T = "¿Tito? Aquí no hay ningún Tito. Habitación 214: tú, Iván y Candela. Lo pone en mi libro. Mi libro no se equivoca desde 1984." },
				{ S = "Portero", T = "Aunque, ahora que lo dices… esta semana vino un señor de traje gris preguntando por «la habitación del Ancla». Le dije que aquí no alquilamos barcos." },
			} },
			Confrontar = { Lines = {
				{ S = "Candela", T = "Te lo digo con datos: no existes. No estás en mi Excel de limpieza. Nunca has fregado. NUNCA." },
				{ S = "Tito", T = "…Vaya. La del Excel. Siempre hay una del Excel." },
				{ S = "Narrador", T = "Tito sonríe. Una sonrisa demasiado ancha. De anuncio de la tele. Se quita las gafas: debajo hay unas gafas de sol. De noche." },
			} },
			Final = { Lines = {
				{ S = "Ivan", T = "¿Llevábamos tres meses viviendo con un espía? ¿Y le dejé mi pijama de dinosaurios? …Me lo ha devuelto limpio. Mejor que yo." },
				{ S = "Candela", T = "Ha dicho «el Ancla». Otra vez esa palabra. {nombre}, ¿hay algo que no nos estás contando?" },
				{ Ask = "¿Qué les dices?", Options = {
					{ T = "Les cuentas todo: Cosme, la Grieta, el Consorcio", Effects = { Flags = { "CompisSabenGrieta" }, Rel = { Ivan = 6, Candela = 6 } }, Then = {
						{ S = "Candela", T = "…Vale. Nueva hoja de Excel: «Cosas imposibles que son verdad». Contad conmigo." },
						{ S = "Ivan", T = "Y conmigo. No entiendo nada, pero contad conmigo. Llevo el zumo." },
					} },
					{ T = "«Es una larga historia. Algún día os lo cuento.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Candela", T = "Te doy de plazo hasta final de curso. Lo apunto." },
					} },
				} },
			} },
		},
	},
}
