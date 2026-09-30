-- MISIONES LOCAS · INFANCIA (secundarias). Ciencia ficción gamberra con Cosme, el vecino del garaje.
-- Ficha de diseño: docs/historia/12-misiones-locas.md
--
--   Loco_N1_Cosme     «El vecino del garaje»          el microondas temporal → 🔵 Pistola de burbujas cuánticas
--   Loco_N2_Bigotes   «Bigotes, emperador de Gatonia» cucarachas cazarrecompensas → 👑 Corona del emperador
--   Loco_N3_Pollo     «La gallina de seis metros»     huir y encoger a Petra → 🔬 Rayo encogedor
--   Loco_N4_Clones    «Deberes clónicos»              tres clones en el cole → 📸 Foto con tus clones
--   Loco_N5_Perez     «La huelga del Ratón Pérez»     persecución nocturna → 🪙 Moneda del Ratón Pérez
--   Loco_N6_Tirachinas «El tirachinas del campeón»   desde el primer día de cole: prácticas y palomas robot → 🪃 Tirachinas
--
-- Todo es de dibujos animados: los «malos» no se hacen daño, se desintegran en chispas y vuelven a
-- su planeta (o a su tamaño, o a su botón de deshacer).

local V = Vector3.new

local NINO = { Stage = { Min = "Nino", Max = "Nino" } }
local function after(...)
	return { Stage = { Min = "Nino", Max = "Nino" }, Completed = { ... } }
end

local COSME_GARAJE = { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) }

return {
	---------------------------------------------------------------------
	-- N1 · El vecino del garaje
	---------------------------------------------------------------------
	{
		Id = "Loco_N1_Cosme",
		Kind = "Side",
		Canon = true, -- Saga de la Grieta, misión 1 (docs/historia/13-saga-de-la-grieta.md): siempre en el mapa
		Title = "El vecino del garaje",
		Description = "¡BUM! Del garaje del vecino sale humo verde. Y una voz: «¡NADIE TOQUE NADA QUE BRILLE!»",
		Type = "Saga de la Grieta · Acto I (1/6)",
		Duration = { 12, 18 },
		Npcs = { "Cosme", "Bigotes" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "¡BUM! Humo verde en el garaje del vecino…",
		Requires = NINO,
		Moment = "Conociste a Cosme, el inventor del garaje",
		Memory = "ConociCosme",
		Rewards = { Items = { PistolaBurbujas = 1 }, Flags = { "AmigoDeCosme", "GrietaVista" } },
		Props = {
			Tornillo = { Kind = "Cristal", Name = "El tornillo cuántico", Prompt = "Recoger", Place = "FuenteParque", Offset = V(3, 0, 2), Dialogue = "Tornillo", Once = true },
			Bobina = { Kind = "Maquina", Name = "Una bobina… dentro de un helado", Prompt = "Sacarla del helado", Place = "Heladeria", Offset = V(3, 0, 3), Color = Color3.fromRGB(250, 180, 220), Dialogue = "Bobina", Once = true },
			Gato = { Kind = "Gato", Name = "Bigotes (con un chip en el collar)", Prompt = "Coger el chip", Place = "JuegosColegio", Offset = V(2, 0, 2), Dialogue = "Chip", Once = true },
			Microondas = { Kind = "Maquina", Name = "El microondas temporal", Prompt = false, Place = "GarajeCosme", Offset = V(-3, 0, 0) },
		},
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Presentacion", Text = "Habla con el vecino (lleno de hollín)",
				Actors = { COSME_GARAJE }, Props = { "Microondas" } },
			{ Type = "Group", Text = "Recupera las 3 piezas del microondas temporal",
				Steps = {
					{ Type = "Use", Prop = "Tornillo", Text = "El tornillo cuántico (cerca de la fuente del parque)" },
					{ Type = "Use", Prop = "Bobina", Text = "La bobina de gominola (en la heladería)" },
					{ Type = "Use", Prop = "Gato", Text = "El chip (lo tiene el gato del cole)" },
				} },
			{ Type = "Reach", Place = "GarajeCosme", Text = "Lleva las piezas al garaje de Cosme",
				Actors = { COSME_GARAJE }, Props = { "Microondas" } },
			{ Type = "Scene", Dialogue = "Prueba", Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3), Mode = "Cheer" } }, Props = { "Microondas" } },
		},
		Dialogues = {
			Presentacion = { Lines = {
				{ S = "Cosme", T = "¡COF! ¡Cof! …Ah. Una criatura. Hola, criatura. No te asustes: el humo verde es normal. El humo morado, no. El humo morado, corre." },
				{ S = "Cosme", T = "Soy Cosme. Inventor. Genio. Vecino. En ese orden." },
				{ S = "Yo", T = "¿Qué ha explotado?" },
				{ S = "Cosme", T = "Mi microondas temporal. Calienta la comida… en el pasado. Así está caliente desde antes de tener hambre. Brillante. Revolucionario. Ha explotado.", A = "Shrug" },
				{ S = "Cosme", T = "Y han salido volando tres piezas: el tornillo cuántico, la bobina de gominola y el chip de mi abuela. No preguntes por el chip de mi abuela." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«¡Te ayudo a buscarlas!»", Effects = { Rel = { Cosme = 5 }, Traits = { Valentia = 1 } }, Then = {
						{ S = "Cosme", T = "¿Ayudar? ¿Gratis? Qué concepto tan raro. Me gusta. Tú vales para esto." },
					} },
					{ T = "«¿El chip de tu abuela?»", Effects = { Rel = { Cosme = 3 }, Traits = { Curiosidad = 1 } }, Then = {
						{ S = "Cosme", T = "Mi abuela era una calculadora. Larga historia. Muy triste. Muchos decimales." },
					} },
				} },
				{ S = "Cosme", T = "Una cosa, criatura: si alguna pieza te habla, no le hagas caso. Las piezas mienten." },
			} },
			Tornillo = { Lines = {
				{ S = "Narrador", T = "Junto a la fuente hay un tornillo que brilla. Cuando lo coges, durante un segundo ves el parque en blanco y negro, lleno de dinosaurios." },
				{ S = "Narrador", T = "Parpadeas. Ya no. Mejor no pensarlo mucho." },
			} },
			Bobina = { Lines = {
				{ S = "Narrador", T = "Un niño se está comiendo un helado de fresa con una bobina de metal dentro. Dice que sabe «a martes»." },
				{ Ask = "¿Cómo la consigues?", Options = {
					{ T = "Le cambias la bobina por tu merienda", Effects = { Traits = { Empatia = 1 } }, Then = {
						{ S = "Narrador", T = "Trato hecho. El niño te mira muy serio y dice: «El martes vuelve». Vale." },
					} },
					{ T = "Le dices que es un helado del futuro y que ya ha caducado", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Narrador", T = "Te la da con cara de asco. Técnicamente no mentías: viene del pasado. Casi." },
					} },
				} },
			} },
			Chip = { Lines = {
				{ S = "Narrador", T = "Bigotes, el gato del colegio, lleva el chip enganchado al collar. Te mira. Tú le miras. Él suspira." },
				{ S = "Bigotes", T = "Cría humana. Coge tu chip y vete. Y no le digas a nadie que puedo hablar. Tengo una reputación." },
				{ S = "Yo", T = "¡¿El gato habla?!" },
				{ S = "Bigotes", T = "Todos los gatos hablamos. Solo que no con vosotros. …Este chip me ha soltado la lengua. Ya me callo. Miau. Ya está. Miau." },
			}, Effects = { Flags = { "BigotesHabla" } } },
			Prueba = { Lines = {
				{ S = "Cosme", T = "¡Tornillo, bobina, chip! ¡Y… ya! Vamos a calentar este bocadillo de chorizo al martes pasado." },
				{ S = "Narrador", T = "El microondas zumba. Brilla. Hace «ding». Dentro hay un bocadillo… un poco mordido." },
				{ S = "Cosme", T = "¿Quién ha mordido mi bocadillo en el pasado? …Fui yo. El martes pasado. Ya decía yo que el martes tenía hambre." },
				{ S = "Cosme", T = "Toma, criatura. Por las piezas. Iba a ser un desintegrador de materia, pero solo hace burbujas. Burbujas cuánticas. Existen en tres dimensiones a la vez.", A = "Point" },
				{ S = "Narrador", T = "Recibes la 🔵 Pistola de burbujas cuánticas (úsala desde tu mochila)." },
				{ Ask = "Cosme te mira muy serio: «¿Se lo vas a contar a tu familia?»", Options = {
					{ T = "«Será nuestro secreto de vecinos.»", Effects = { Flags = { "SecretoCosme" }, Rel = { Cosme = 5 } }, Then = {
						{ S = "Cosme", T = "Buena criatura. Pásate cuando quieras. Pero llama antes. Tres veces. Luego dos. Luego tararea algo." },
					} },
					{ T = "«Se lo voy a contar. Todo.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Cosme", T = "Cuéntaselo. No te va a creer nadie. Esa es la ventaja de ser un genio: la verdad suena a mentira." },
						{ S = "Narrador", T = "Esa noche se lo cuentas a {familia}. Te dice que qué imaginación. Y te pone más puré." },
					} },
				} },
				{ S = "Narrador", T = "Al salir del garaje, Cosme se queda mirando el cielo. Encima de Los Pinos hay una línea verde, finísima, como un rasguño en el aire." },
				{ S = "Cosme", T = "Criatura… ¿eso estaba ahí antes? …No. No estaba. Vete a casa. Mañana hablamos. Mañana… hablamos." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- N2 · Bigotes, emperador de Gatonia
	---------------------------------------------------------------------
	{
		Id = "Loco_N2_Bigotes",
		Kind = "Side",
		Title = "Bigotes, emperador de Gatonia",
		Description = "Bigotes, el gato del cole, te ha dejado una nota en la mochila. Con la pata. Pone «SOCORRO».",
		Type = "Misión loca · Infancia (2/5)",
		Duration = { 10, 15 },
		Npcs = { "Bigotes", "Cucaracha1", "Cucaracha2", "Cucaracha3" },
		Offer = { Place = "Patio" },
		OfferKey = "En tu mochila hay una nota escrita con una pata: «SOCORRO. Firmado: el gato».",
		Requires = after("Loco_N1_Cosme"),
		Moment = "Salvaste al emperador de los gatos",
		Memory = "EmperadorBigotes",
		Rewards = { Items = { CoronaBigotes = 1 } },
		Props = {
			Bigotes = { Kind = "Gato", Name = "Bigotes", Prompt = "Hablar con el gato", Place = "JuegosColegio", Offset = V(2, 0, 2), Dialogue = "Socorro", Once = true },
			Globos = { Kind = "Caja", Name = "Una caja de globos de agua", Prompt = "Coger globos de agua", Place = "Patio", Offset = V(-4, 0, 3), Color = Color3.fromRGB(80, 160, 255), Dialogue = "Globos", Once = true },
			Nave = { Kind = "Nave", Name = "La nave de las cucarachas", Place = "Patio", Offset = V(0, 0, -14), Height = 14, Prompt = false },
		},
		Steps = {
			{ Type = "Use", Prop = "Bigotes", Text = "Busca a Bigotes en la zona de juegos del cole" },
			{ Type = "Use", Prop = "Globos", Text = "Arma: una caja de globos de agua (en el patio)", Props = { "Nave" } },
			{ Type = "Fight", Place = "Patio", Respawn = "JuegosColegio", Action = "Lanzar globo de agua 🎈", HP = 2, BeamColor = Color3.fromRGB(80, 170, 255),
				Text = "¡Las cucarachas cazarrecompensas! Échalas con globos de agua ({count}/{total})",
				CaughtLine = "¡Te pillé, larva! …Uy, que tú no eres el gato. Suéltate y vuelve a empezar.",
				Props = { "Nave" },
				Enemies = {
					{ Npc = "Cucaracha1", Offset = V(-6, 0, -6), Speed = 11, Hurt = "¡Mis antenas! ¡Están mojadas!", Bye = "¡Nos vamos! ¡Pero volveremos cuando se sequen!" },
					{ Npc = "Cucaracha2", Offset = V(6, 0, -6), Speed = 11, Hurt = "¡Antenas! ¡Antenas mojadas!", Bye = "¡Antenaaas!" },
					{ Npc = "Cucaracha3", Offset = V(0, 0, -9), Speed = 12, HP = 3, Hurt = "¡Soldado, fórmense! …Ah, que estoy solo.", Bye = "¡Retirada táctica! ¡Crujiente nos espera!" },
				} },
			{ Type = "Scene", Dialogue = "Gracias", Props = { "Bigotes" } },
		},
		Dialogues = {
			Socorro = { Lines = {
				{ S = "Bigotes", T = "Por fin. Cría humana. Escucha bien, porque solo lo diré una vez y luego fingiré que no he hablado." },
				{ S = "Bigotes", T = "No soy un gato. Bueno: sí soy un gato. Pero también soy Bigotes XVII, emperador exiliado de Gatonia, planeta de los gatos, en la nebulosa del Ovillo." },
				{ S = "Yo", T = "¿Y qué haces en mi cole?" },
				{ S = "Bigotes", T = "Aquí me dan jamón en el comedor. Y nadie me busca. …Nadie me buscaba. Las cucarachas cazarrecompensas de Crujiente me han encontrado." },
				{ S = "Bigotes", T = "Solo hay una cosa que odian más que las zapatillas: el agua. Ya sabes lo que tienes que hacer. Yo te miraré desde aquí. Con dignidad." },
			} },
			Globos = { Lines = {
				{ S = "Narrador", T = "Una caja de globos de agua para la fiesta de fin de curso. La fiesta de fin de curso puede esperar." },
				{ S = "Narrador", T = "Una nave del tamaño de una furgoneta aterriza en medio del patio. Nadie más la ve. Los adultos nunca ven nada." },
			} },
			Gracias = { Lines = {
				{ S = "Bigotes", T = "Bien hecho. Muy bien hecho. Para ser un humano, lanzas con bastante elegancia." },
				{ S = "Bigotes", T = "Como emperador, te concedo un favor imperial. Uno. No lo malgastes." },
				{ Ask = "¿Qué pides?", Options = {
					{ T = "«¡Déjame tocarte la barriga!»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Bigotes", T = "…Te concedo cualquier cosa del universo y pides eso. …Tres segundos. UNO. DOS. Suficiente." },
						{ S = "Narrador", T = "Es la barriga más suave del cosmos. Él lo sabe. Por eso se hace el digno." },
					} },
					{ T = "«Un título de noble de Gatonia.»", Effects = { Flags = { "DuqueDeGatonia" } }, Then = {
						{ S = "Bigotes", T = "Te nombro… Duque o Duquesa del Cojín, Guardián del Rayo de Sol de las Cuatro de la Tarde. Es un título muy importante en Gatonia." },
					} },
					{ T = "«Que sigas en el cole con nosotros.»", Effects = { Traits = { Empatia = 1 }, Rel = { Bigotes = 10 } }, Then = {
						{ S = "Bigotes", T = "…Cría humana. Eso no es un favor para ti. …Pero acepto. Por el jamón. Solo por el jamón." },
					} },
				} },
				{ S = "Bigotes", T = "Toma. Mi corona de viaje. Mide dos centímetros. En Gatonia es enorme." },
				{ S = "Narrador", T = "Recibes 👑 la Corona del emperador Bigotes." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- N3 · La gallina de seis metros
	---------------------------------------------------------------------
	{
		Id = "Loco_N3_Pollo",
		Kind = "Side",
		Title = "La gallina de seis metros",
		Description = "Cosme tiene cara de culpable. Mucha. «¿Has oído algo raro de Villaverde? ¿No? ¿Nada de… gallinas?»",
		Type = "Misión loca · Infancia (3/5)",
		Duration = { 12, 18 },
		Npcs = { "Cosme", "Julian", "PolloGigante" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme te hace señas desde el garaje. Parece MUY culpable.",
		Requires = after("Loco_N1_Cosme"),
		Moment = "Encogiste a una gallina gigante",
		Memory = "GallinaGigante",
		Rewards = { Items = { RayoEncogedor = 1 } },
		Props = {
			Huevo = { Kind = "Huevo", Name = "Un huevo del tamaño de una lavadora", Prompt = "Mirar el huevo", Place = "GranjaGranero", Offset = V(4, 0, 4), Dialogue = "Huevo", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Culpa", Text = "Cosme quiere contarte algo (con cara de culpable)", Actors = { COSME_GARAJE } },
			{ Type = "Transition", Text = "Cosme conduce su furgoneta. Que vuela. Un poquito. Solo en las curvas.", Seconds = 4, Teleport = "Granja" },
			{ Type = "Talk", Npc = "Julian", Dialogue = "Granjero", Text = "Habla con Julián, el granjero",
				Actors = { { Npc = "Julian", Place = "Granja", Offset = V(3, 0, 3) }, { Npc = "Cosme", Place = "Granja", Offset = V(-3, 0, 3) } } },
			{ Type = "Use", Prop = "Huevo", Text = "Algo enorme hay junto al granero…",
				Actors = { { Npc = "Cosme", Mode = "Follow" } } },
			{ Type = "Escape", Place = "GranjaSilo", Respawn = "GranjaGranero", Catch = 5, Text = "¡PETRA TE HA VISTO! ¡Corre hasta el silo!",
				CaughtLine = "¡¡¡CLOC!!! (Te ha cogido con el pico y te ha dejado otra vez junto al granero. Con cariño. Mucho cariño.)",
				Actors = { { Npc = "PolloGigante", Place = "GranjaGranero", Offset = V(-10, 0, -6), Mode = "Hunt", Speed = 12, Scale = 2.4, Prompt = false } } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Rayo", Text = "¡Cosme está en el silo con algo en la mano!",
				Actors = { { Npc = "Cosme", Place = "GranjaSilo", Offset = V(3, 0, 2) } } },
			{ Type = "Fight", Place = "GranjaSilo", Respawn = "GranjaSilo", Action = "Disparar el rayo encogedor", HP = 5, BeamColor = Color3.fromRGB(190, 90, 255), Catch = 5,
				Text = "Encoge a Petra con el rayo ({count}/{total})",
				CaughtLine = "¡¡CLOC!! (Te ha dado un abrazo de ala. Pesa como un sofá.)",
				Actors = { { Npc = "Cosme", Place = "GranjaSilo", Offset = V(3, 0, 2), Mode = "Cheer" } },
				Enemies = {
					{ Npc = "PolloGigante", Offset = V(-12, 0, -8), Speed = 10, Scale = 2.4, HP = 5, Hurt = "¿¿Cloc?? (Ha bajado un poco. Del tamaño de un camión a una furgoneta.)", Bye = "¡Pío! (Petra vuelve a medir lo que mide una gallina. Se va corriendo al gallinero, ofendidísima.)" },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = { { Npc = "Cosme", Place = "GranjaSilo", Offset = V(3, 0, 2) }, { Npc = "Julian", Place = "GranjaSilo", Offset = V(-3, 0, 3) } } },
		},
		Dialogues = {
			Culpa = { Lines = {
				{ S = "Cosme", T = "Criatura. Pregunta rápida, totalmente teórica: si un rayo agrandador se disparara SIN QUERER hacia Villaverde… ¿qué animal crees que alcanzaría?" },
				{ S = "Yo", T = "¿Una… vaca?" },
				{ S = "Cosme", T = "Ojalá. Una vaca grande es solo una vaca con más filetes. No. Una gallina. Una gallina de seis metros. Se llama Petra. Está muy disgustada." },
				{ S = "Cosme", T = "El rayo agrandador era para hacer los bocadillos más grandes. La ciencia es así: buscas bocadillos, encuentras gallinas." },
				{ S = "Cosme", T = "Sube a la furgoneta. Y no toques el botón rojo. Ni el azul. En realidad no toques nada. Siéntate encima de tus manos." },
			} },
			Granjero = { Lines = {
				{ S = "Julian", T = "Hombre, Cosme. Ya sabía yo que esto era cosa tuya. Esta mañana tenía doce gallinas. Ahora tengo once… y un edificio con plumas." },
				{ S = "Julian", T = "Petra está en el granero. Pone huevos del tamaño de una lavadora. No es mala. Solo está muy asustada. Y es muy, muy grande." },
				{ S = "Cosme", T = "Tranquilo, Julián. Tengo un plan. Tengo un rayo encogedor. Bueno, tengo las piezas de un rayo encogedor. Y un destornillador. Dame cinco minutos." },
			} },
			Huevo = { Lines = {
				{ S = "Narrador", T = "Un huevo gigante, calentito. Encima, alguien ha escrito con barro: «NO TOCAR». Con una pata de gallina." },
				{ S = "Narrador", T = "Detrás de ti, el suelo tiembla. Una sombra enorme. Un «CLOC» que hace vibrar las ventanas." },
				{ S = "Cosme", T = "¡Criatura! ¡Mamá gallina te ha visto con su huevo! ¡CORRE HACIA EL SILO! ¡Yo… yo tengo que ir a por una cosa! ¡Muy importante! ¡No es huir!" },
			} },
			Rayo = { Lines = {
				{ S = "Cosme", T = "¡Aquí! ¡Rápido! Rayo encogedor, recién montado. Tiene un solo defecto: apunta con los ojos cerrados." },
				{ S = "Yo", T = "¿Por qué con los ojos cerrados?" },
				{ S = "Cosme", T = "Porque si ves la cara de pena que pone Petra, no disparas. Venga. Varias veces. Es una gallina muy grande.", A = "Point" },
			} },
			Final = { Lines = {
				{ S = "Julian", T = "Petra ya mide lo que tiene que medir. Y está en el gallinero, sentada encima de su huevo. Que ahora es normal. Gracias, chaval… gracias, criatura. Se me pega." },
				{ S = "Cosme", T = "Quédate el rayo encogedor. Ya no encoge mucho, la verdad: se ha gastado. Pero hace «bzzzt» y da cosquillas. Es un buen recuerdo." },
				{ S = "Narrador", T = "Recibes el 🔬 Rayo encogedor." },
				{ Ask = "¿Qué le dices a Cosme en la furgoneta de vuelta?", Options = {
					{ T = "«La próxima vez, bocadillos normales.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Cosme", T = "¿Bocadillos normales? Qué vida más triste. …Bueno. Vale. Esta semana, normales." },
					} },
					{ T = "«¡Ha sido lo mejor de mi vida!»", Effects = { Rel = { Cosme = 6 }, Traits = { Valentia = 1 } }, Then = {
						{ S = "Cosme", T = "Pues esto no es nada, criatura. Espera a que te hable del martes en que me convertí en perchero." },
					} },
				} },
			} },
		},
	},

	---------------------------------------------------------------------
	-- N4 · Deberes clónicos
	---------------------------------------------------------------------
	{
		Id = "Loco_N4_Clones",
		Kind = "Side",
		Title = "Deberes clónicos",
		Description = "Tienes una montaña de deberes. Cosme tiene una clonadora. ¿Qué podría salir mal?",
		Type = "Misión loca · Infancia (4/5)",
		Duration = { 12, 18 },
		Npcs = { "Cosme", "Clon1", "Clon2", "Clon3", "Lucia" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme te enseña una caja con un botón: «CLONAR». Tú tienes muchos deberes…",
		Requires = after("Loco_N1_Cosme"),
		Moment = "El día que hubo cuatro como tú en clase",
		Memory = "LosClones",
		Rewards = { Items = { FotoClones = 1 } },
		Props = {
			Clonadora = { Kind = "Maquina", Name = "La clonadora de bolsillo", Prompt = "Pulsar CLONAR", Place = "HomeDormitorio", Offset = V(2, 0, 1), Color = Color3.fromRGB(80, 200, 160), Dialogue = "Clonar", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Oferta", Text = "Cosme quiere enseñarte su nuevo invento", Actors = { COSME_GARAJE } },
			{ Type = "Use", Prop = "Clonadora", Text = "Vuelve a casa y usa la clonadora en tu cuarto" },
			{ Type = "Talk", Npc = "Lucia", Dialogue = "Lucia", Text = "Al día siguiente, en el cole… Lucía quiere hablar contigo",
				Actors = {
					{ Npc = "Lucia", Place = "EntradaColegio", Offset = V(0, 0, 4) },
					{ Npc = "Clon2", Place = "EntradaColegio", Offset = V(-5, 0, 7), Mode = "Dance", Prompt = false },
				} },
			{ Type = "Fight", Place = "Patio", Respawn = "EntradaColegio", Action = "Pulsar su botón de deshacer", HP = 1, BeamColor = Color3.fromRGB(120, 255, 200), Catch = 3,
				Text = "Tus clones van a abrazarte (y no te sueltan). Pulsa su botón de deshacer ({count}/{total})",
				CaughtLine = "¡ABRAZO GRUPAL! (Tardas un rato en soltarte. Vuelves a la entrada.)",
				Enemies = {
					{ Npc = "Clon1", Offset = V(-6, 0, 0), Speed = 12, Bye = "¡Pero si aún no me había comido los de Lengua! *pop*" },
					{ Npc = "Clon2", Offset = V(6, 0, 0), Speed = 12, Bye = "♪ Me voy, me voy, me vooooy ♪ *pop*" },
					{ Npc = "Clon3", Offset = V(0, 0, 8), Speed = 14, Bye = "¡Esto es un golpe de Estado! ¡Recurriré! *pop*" },
				} },
			{ Type = "Scene", Dialogue = "Deberes", Actors = { { Npc = "Lucia", Place = "Patio", Offset = V(0, 0, 4) } } },
		},
		Dialogues = {
			Oferta = { Lines = {
				{ S = "Cosme", T = "¿Deberes? ¿Otra vez? Qué sistema educativo más primitivo. En Gatonia los gatos aprenden durmiendo. Lo sé porque me lo contó un gato." },
				{ S = "Cosme", T = "Toma: clonadora de bolsillo. Un botón, un clon. El clon hace tus deberes. Tú juegas. Todos contentos." },
				{ S = "Yo", T = "¿Y dónde está la trampa?" },
				{ S = "Cosme", T = "¿Trampa? Ninguna. Bueno. A veces los clones salen… con personalidad. Pero es un porcentaje pequeño. Del cien por cien.", A = "Shrug" },
			} },
			Clonar = { Lines = {
				{ S = "Narrador", T = "Pulsas el botón. ¡PLOP! Hay alguien igual que tú en tu cuarto. Te mira. Mira tus deberes. Se come el cuaderno de Lengua." },
				{ S = "Narrador", T = "Pulsas otra vez, para arreglarlo. ¡PLOP! Otro clon. Este solo sabe cantar. Canta la tabla del siete. Mal." },
				{ S = "Narrador", T = "Pulsas otra vez. ¡PLOP! El tercero se sube a la silla: «¡Yo seré vuestro líder!». Dejas de pulsar el botón." },
				{ S = "Narrador", T = "Esa noche duermes en la alfombra. Los tres clones duermen en tu cama. Roncan igual que tú. Qué horror." },
			} },
			Lucia = { Lines = {
				{ S = "Lucia", T = "{nombre}. Pregunta rápida. ¿Tienes… hermanos? ¿Trillizos? ¿Cuatrillizos?" },
				{ S = "Lucia", T = "Porque hoy has llegado cuatro veces a clase. Una de ellas se ha comido la plastilina. Otra ha hecho un musical. Y la otra se ha presentado a delegada contra otro tú." },
				{ S = "Narrador", T = "Detrás de Lucía, uno de tus clones baila. En el patio, los otros dos te han visto. Abren los brazos. Vienen a abrazarte." },
				{ S = "Lucia", T = "No sé qué está pasando. No quiero saberlo. Quiero que, cuando vuelva de la sala de profes, haya UNO de ti." },
			} },
			Deberes = { Lines = {
				{ S = "Lucia", T = "Así me gusta. Uno. Un {nombre} por aula es el máximo legal." },
				{ S = "Lucia", T = "Y ahora: los deberes. ¿Quién los ha hecho?" },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Los ha hecho un clon. Y se ha comido la mitad.»", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Lucia = 4 } }, Then = {
						{ S = "Lucia", T = "Lo más raro que he oído en veinte años de profe. Y me lo creo, fíjate. Mañana los traes. Hechos por ti." },
					} },
					{ T = "«Yo. Con mucho esfuerzo. Y mucha ayuda.»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Lucia", T = "Mucha ayuda. Ya. La letra es tuya en tres versiones. Mañana, una versión. La buena." },
					} },
				} },
				{ S = "Narrador", T = "Antes de irse, uno de los clones hizo una foto de los cuatro. La encuentras en tu mochila: cuatro {nombre} haciendo el signo de la victoria." },
				{ S = "Narrador", T = "Recibes 📸 la Foto con tus clones." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- N5 · La huelga del Ratón Pérez
	---------------------------------------------------------------------
	{
		Id = "Loco_N5_Perez",
		Kind = "Side",
		Title = "La huelga del Ratón Pérez",
		Description = "Se te ha caído un diente. Lo pones bajo la almohada. A medianoche alguien refunfuña debajo de tu cama.",
		Type = "Misión loca · Infancia (5/5)",
		Duration = { 10, 15 },
		Npcs = { "RatonPerez", "RataLadrona" },
		Offer = { Place = "HomeDormitorio" },
		OfferKey = "¡Se te ha caído un diente! ¿Lo pones bajo la almohada esta noche?",
		Requires = { Stage = { Min = "Nino", Max = "Nino" }, Completed = { "Loco_N1_Cosme" }, Hours = { From = 20, To = 7 } },
		Moment = "La noche que ayudaste al Ratón Pérez",
		Memory = "RatonPerez",
		Rewards = { Items = { MonedaPerez = 1 }, Money = 50 },
		Steps = {
			{ Type = "Scene", Dialogue = "Huelga", Actors = { { Npc = "RatonPerez", Place = "HomeDormitorio", Offset = V(1, 0, 2) } } },
			{ Type = "Chase", Npc = "RataLadrona", Catch = 6, Text = "¡La Rata Ladrona se lleva la bolsa de dientes! ¡Atrápala!",
				Actors = {
					{ Npc = "RataLadrona", Place = "CasaFamiliar", Offset = V(3, 0, 6), Mode = "Flee", Speed = 15, Prompt = false,
						Route = { "CasaFamiliar", "CaminoAlGaraje", "Parque", "FuenteParque" } },
					{ Npc = "RatonPerez", Mode = "Follow" },
				} },
			{ Type = "Scene", Dialogue = "Recuperada", Actors = { { Npc = "RataLadrona", Place = "FuenteParque", Offset = V(2, 0, 2) }, { Npc = "RatonPerez", Place = "FuenteParque", Offset = V(-2, 0, 2) } } },
		},
		Dialogues = {
			Huelga = { Lines = {
				{ S = "Narrador", T = "Medianoche. Debajo de tu cama, alguien refunfuña. Enciendes la linterna." },
				{ S = "RatonPerez", T = "¡Apaga eso! Soy el Ratón Pérez. Sí, ese. Y estoy en huelga. Trescientos años recogiendo dientes. Ni un día de vacaciones. Ni una paga extra." },
				{ S = "RatonPerez", T = "¿Sabes cuántos dientes hay en el mundo? Yo sí. Todos. Me los sé todos. Algunos por su nombre." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«¡Tienes razón! ¡Viva la huelga!»", Effects = { Traits = { Rebeldia = 1 }, Rel = { RatonPerez = 5 } }, Then = {
						{ S = "RatonPerez", T = "¡Por fin alguien con conciencia de clase! ¡De clase de primaria, pero conciencia!" },
					} },
					{ T = "«Pero… ¿y mi moneda?»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "RatonPerez", T = "Todos igual. Moneda, moneda, moneda. Nadie pregunta «¿y tú qué tal, Ratón?»." },
					} },
				} },
				{ S = "Narrador", T = "De repente, por la ventana entra una sombra. Una rata con antifaz agarra la bolsa de dientes del Ratón Pérez y salta afuera." },
				{ S = "RatonPerez", T = "¡LA RATA LADRONA! ¡Con esos dientes se hace el polvo de hada del mercado negro! ¡Detenla! ¡Yo tengo las piernas de tres centímetros!" },
			} },
			Recuperada = { Lines = {
				{ S = "RataLadrona", T = "¡Vale, vale! ¡Me rindo! ¡Tú corres más que un gato con prisa!" },
				{ S = "RatonPerez", T = "La bolsa. Ahora. …Y ya que estamos: ¿por qué robas dientes?" },
				{ S = "RataLadrona", T = "Porque nadie contrata a ratas. Todo el mundo contrata ratones. Es discriminación de roedor." },
				{ Ask = "El Ratón Pérez te mira. «Tú decides qué hacemos con ella.»", Options = {
					{ T = "«Contrátala. Así tienes vacaciones.»", Effects = { Traits = { Empatia = 2 }, Flags = { "RataContratada" } }, Then = {
						{ S = "RatonPerez", T = "…¿Una ayudante? ¿Vacaciones? ¿Yo? ¿En la playa? …¡¿EN LA PLAYA?!" },
						{ S = "RataLadrona", T = "¿Yo, con contrato? ¿Con seguro dental? ¡Qué ironía!" },
					} },
					{ T = "«Que devuelva todo y pida perdón.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "RataLadrona", T = "Perdón. …Perdón de verdad. A los dientes también." },
						{ S = "RatonPerez", T = "Aceptado. Pero la próxima vez, te muerdo la cola. Con cariño." },
					} },
				} },
				{ S = "RatonPerez", T = "Toma. No es la moneda de siempre. Es una de las de antes: oro de verdad, del año 1702. Me la dio un pirata por su último diente." },
				{ S = "Narrador", T = "Recibes 🪙 la Moneda del Ratón Pérez (y 50 monedas de las normales, «para gastos»)." },
				{ S = "RatonPerez", T = "Y ahora, a dormir. Que mañana tienes cole. Y yo, a lo mejor, playa." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- N6 · El tirachinas de {abu} (disponible en cuanto empiezas el cole)
	---------------------------------------------------------------------
	{
		Id = "Loco_N6_Tirachinas",
		Kind = "Side",
		Title = "El tirachinas del campeón",
		Description = "{abu} dice que fue campeón del Gran Torneo de Tirachinas de 1962. Y que su tirachinas sigue en el baúl.",
		Type = "Misión loca · Infancia (6/6)",
		Duration = { 10, 15 },
		Npcs = { "Abu", "Cosme", "PalomaRobot1", "PalomaRobot2", "PalomaRobot3" },
		Offer = { Place = "HomeSalon" },
		OfferKey = "Tu abu te guiña un ojo: «¿Sabías que fui campeón de tirachinas? Todavía lo guardo…»",
		Requires = { Stage = { Min = "Nino", Max = "Nino" }, Completed = { "Cole01_PrimerDia" } },
		Moment = "{abu} te regaló su tirachinas de campeón",
		Memory = "TirachinasAbu",
		Rewards = {}, -- (el tirachinas se da al abrir el baúl)
		Props = {
			Baul = { Kind = "Caja", Name = "El baúl de tu abu", Prompt = "Abrir el baúl", Place = "HomeSalon", Offset = V(-3, 0, 2), Color = Color3.fromRGB(120, 80, 45), Dialogue = "Baul", Once = true },
			Latas = { Kind = "Marcador", Name = "Latas vacías en fila", Place = "Parque", Offset = V(0, 0, 10), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Abu", Dialogue = "Campeon", Text = "Habla con {abu}", Actors = { { Npc = "Abu", Place = "HomeSalon", Offset = V(2, 0, 2) } } },
			-- (el tirachinas es tuyo al abrir el baúl: {abu} te lo da ahí, y lo usas en el parque)
			{ Type = "Use", Prop = "Baul", Text = "Abre el baúl de {abu}", Effects = { Items = { Tirachinas = 1 } }, Actors = { { Npc = "Abu", Place = "HomeSalon", Offset = V(2, 0, 2) } } },
			{ Type = "Reach", Place = "Parque", Text = "Vamos al parque a practicar con latas (solo latas)",
				Actors = { { Npc = "Abu", Mode = "Follow" } } },
			{ Type = "MiniGame", Game = "Timing", Title = "Práctica: derriba las latas", Icon = "🥫", Hint = "Suelta la goma justo en la zona verde",
				Rounds = 5, Need = 3, Zone = 0.28, Speed = 0.9,
				Win = { Flags = { "PunteriaDeCampeon" }, Rel = { Abu = 4 } }, Lose = { Traits = { Humor = 1 } },
				Props = { "Latas" }, Actors = { { Npc = "Abu", Place = "Parque", Offset = V(3, 0, 2), Mode = "Cheer" } } },
			{ Type = "Scene", Dialogue = "Palomas", Props = { "Latas" },
				Actors = { { Npc = "Abu", Place = "Parque", Offset = V(3, 0, 2) }, { Npc = "Cosme", Place = "Parque", Offset = V(-4, 0, 4) } } },
			{ Type = "Fight", Place = "Parque", Respawn = "Parque", Action = "Disparar el tirachinas 🪃", HP = 2, BeamColor = Color3.fromRGB(160, 110, 60),
				Text = "¡Las palomas robot de Cosme roban bocadillos! Apágalas con el tirachinas ({count}/{total})",
				CaughtLine = "¡Cucurrú-bip! (Te han quitado la merienda. Vuelves al banco del parque.)",
				Actors = { { Npc = "Abu", Place = "Parque", Offset = V(3, 0, 2), Mode = "Cheer" }, { Npc = "Cosme", Place = "Parque", Offset = V(-4, 0, 4) } },
				Enemies = {
					{ Npc = "PalomaRobot1", Offset = V(-8, 0, -6), Speed = 12, Hurt = "¡Cucurrú-error!", Bye = "Cucurrú… apagando… (Se queda quieta y se echa a dormir en modo ahorro.)" },
					{ Npc = "PalomaRobot2", Offset = V(8, 0, -6), Speed = 12, Hurt = "¡Bip! ¡Miga detectada! ¡Ah, no, bellota!", Bye = "Cucurrú-bip-bip… (Apagada.)" },
					{ Npc = "PalomaRobot3", Offset = V(0, 0, -10), Speed = 13, HP = 3, Hurt = "¡Este bocadillo de chorizo es MÍO!", Bye = "…Error 404: bocadillo no encontrado. (Suelta el bocadillo y se apaga.)" },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = { { Npc = "Abu", Place = "Parque", Offset = V(3, 0, 2) }, { Npc = "Cosme", Place = "Parque", Offset = V(-4, 0, 4) } } },
		},
		Dialogues = {
			Campeon = { Lines = {
				{ S = "Abu", T = "¿Ya vas al cole? ¡Qué mayor! Entonces ya tienes edad para saber un secreto de familia." },
				{ S = "Abu", T = "En 1962 gané el Gran Torneo de Tirachinas de Valmar. Derribé cuarenta latas seguidas. Y una lata que no era una lata: era el sombrero del alcalde. Pero eso no contó." },
				{ S = "Abu", T = "Mi tirachinas está en el baúl. Te lo doy… con una regla de oro. Nunca, nunca, NUNCA a personas ni a animales de verdad. Solo a latas." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«¡Prometido! Solo a latas.»", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Abu = 4 } }, Then = {
						{ S = "Abu", T = "Así me gusta. Un campeón de verdad sabe cuándo NO disparar." },
					} },
					{ T = "«¿Y al sombrero del alcalde?»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Abu", T = "…Eso fue un accidente. Un accidente muy bien apuntado. ¡Solo latas!" },
					} },
				} },
			} },
			Baul = { Lines = {
				{ S = "Narrador", T = "Fotos viejas, una medalla oxidada que pone «1962», un cromo de un futbolista con bigote… y un tirachinas de madera, con la goma nueva. {abu} la cambió ayer. Ya lo tenía pensado." },
			} },
			Palomas = { Lines = {
				{ S = "Narrador", T = "De repente: «¡CUCURRÚ-BIP!». Tres palomas metálicas bajan en picado y se llevan los bocadillos de los niños del parque." },
				{ S = "Cosme", T = "¡Mis drones! ¡Los programé para recoger migas del parque! Se ve que han decidido que un bocadillo entero es una miga muy grande. Tienen lógica. Mala, pero lógica." },
				{ S = "Abu", T = "Son robots, no palomas. La regla sigue en pie: a animales de verdad, nunca. A robots ladrones de bocadillos… eso es otra cosa. ¡A ellas!" },
				{ S = "Cosme", T = "Apunta al botón de la espalda. Una bellota en el botón y se apagan. Bueno, dos. O tres. No las hice muy bien." },
			} },
			Final = { Lines = {
				{ S = "Cosme", T = "Drones recuperados. Los reprogramaré para algo útil. Como regar. O cantar. …Regar." },
				{ S = "Abu", T = "¿Has visto qué puntería? Se hereda. El tirachinas ya es tuyo. Cuídalo. Y recuerda la regla." },
				{ S = "Narrador", T = "Recibes 🪃 el tirachinas de {abu}. Úsalo desde la mochila o la barra rápida: dispara bellotas que hacen «¡plof!»." },
			} },
		},
	},
}
