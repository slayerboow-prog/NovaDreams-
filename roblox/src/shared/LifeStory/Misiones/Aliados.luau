-- MISIONES DE ALIADOS: una por cada aliado de la Saga de la Grieta. Ficha: docs/historia/13-saga-de-la-grieta.md
--
-- Cada aliado vuelve antes del final para ganarse su sitio en «Todos los aliados» (saga 20): te pide ayuda,
-- se la das y te promete venir a la Gran Fusión. Todas piden su misión loca (o su misión de la saga)
-- y dejan una marca que la saga 20 usa para una frase extra.
--
--   Aliado_Bigotes  Universidad+  «La visita de Estado»        las cucarachas de Crujiente vuelven, ahora espías del Consorcio
--   Aliado_Rex      Universidad+  «Rex, abogado del Ancla»     MegaVerso te demanda por ser un Ancla «sin licencia»
--   Aliado_Perez    Universidad+  «La muela del juicio»        el Consorcio compra dientes para la máquina de la Fusión (de noche)
--   Aliado_Cronos   Universidad+  «El expediente de Cronos»    la Aduana investiga a Cronos por ayudar al Ancla
--   Aliado_Noz      Universidad+  «Final de temporada»         la Capitana Ñoz graba la promo del último episodio (de noche)
--   Aliado_Gnomos   Adulto        «El consejo de los jardines» gnomos de plástico espía en los jardines de Valmar (de noche)
--   Aliado_Malvado  Adulto        «Clases de ser bueno»        tu yo malvado quiere aprender a ser bueno
--
-- Continuidad: Cosme solo sale en frases con condición (puede estar secuestrado o sin memoria).

local V = Vector3.new

local UNI_O_MAS = { Min = "AdultoJoven" }
local ADULTO = { Min = "Adulto" }

return {
	---------------------------------------------------------------------
	-- Bigotes · La visita de Estado
	---------------------------------------------------------------------
	{
		Id = "Aliado_Bigotes",
		Kind = "Side",
		Title = "La visita de Estado",
		Description = "Bigotes, presidente de Gatonia (y emperador en el exilio), viene a Valmar en visita oficial. Las cucarachas de Crujiente han vuelto: ahora espían para el Consorcio.",
		Type = "Misión de aliado · Bigotes",
		Duration = { 15, 20 },
		Npcs = { "Bigotes", "GatoPolicia1", "Cucaracha1", "Cucaracha2", "Cucaracha3" },
		Offer = { Place = "Parque" },
		OfferKey = "En el parque hay una alfombra roja de dos centímetros de ancho. Al final, un gato con corona te mira",
		Requires = { Stage = UNI_O_MAS, Completed = { "Loco_N2_Bigotes", "Saga_14_Bigotes" } },
		Moment = "Protegiste la visita de Estado de Bigotes",
		Memory = "GuardiaGatuna",
		Rewards = { Items = { BandaCanciller = 1 }, Flags = { "CancillerGatonia" } },
		Props = {
			Portal = { Kind = "Portal", Name = "Portal a Gatonia", Place = "Parque", Offset = V(0, 0, 8), Prompt = false },
			Manguera = { Kind = "Maquina", Name = "La manguera de los jardineros", Prompt = "Coger la manguera", Place = "JuegosParque", Offset = V(-3, 0, 2), Color = Color3.fromRGB(60, 160, 80), Dialogue = "Manguera", Once = true },
			-- Aterriza: posada en el suelo, con patas y la rampa abierta hacia ti (las cucarachas salen por ella)
			Nave = { Kind = "Nave", Aterriza = true, Piloto = Color3.fromRGB(110, 70, 40), Name = "La nave de las cucarachas", Place = "Parque", Offset = V(0, 0, -21), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Bigotes", Dialogue = "Visita", Text = "El presidente Bigotes te espera al final de la alfombra",
				Props = { "Portal" },
				Actors = {
					{ Npc = "Bigotes", Place = "Parque", Offset = V(0, 0, 5) },
					{ Npc = "GatoPolicia1", Place = "Parque", Offset = V(3, 0, 6) },
				} },
			{ Type = "Use", Prop = "Manguera", Text = "Esta vez no hay globos: coge la manguera (junto a los juegos)", Props = { "Nave" } },
			{ Type = "Fight", Place = "Parque", Respawn = "JuegosParque", Action = "Regar 💦", HP = 2, BeamColor = Color3.fromRGB(80, 170, 255),
				Text = "¡Las cucarachas espías del Consorcio! Riégalas ({count}/{total})",
				CaughtLine = "¡Te pillé, larva grande! …Uy, cuánto has crecido. Suéltate y vuelve a empezar.",
				Props = { "Nave" },
				Actors = { { Npc = "Bigotes", Place = "Parque", Offset = V(0, 0, 5) } },
				Enemies = {
					{ Npc = "Cucaracha1", Offset = V(-6, 0, -6), Speed = 11, Hurt = "¡Mis antenas! ¡Y mi corbata!", Bye = "¡Dimito! ¡El Consorcio no paga las tintorerías!" },
					{ Npc = "Cucaracha2", Offset = V(6, 0, -6), Speed = 11, Hurt = "¡Otra vez agua! ¡Esto es acoso!", Bye = "¡Antenaaas! (Otra vez.)" },
					{ Npc = "Cucaracha3", Offset = V(0, 0, -9), Speed = 12, HP = 3, Hurt = "¡Soldado, fórmense! …Siguen sin venir.", Bye = "¡Retirada! ¡Y esta vez no volvemos! …Seguramente." },
				} },
			{ Type = "Scene", Dialogue = "Canciller", Props = { "Portal" },
				Actors = {
					{ Npc = "Bigotes", Place = "Parque", Offset = V(0, 0, 5) },
					{ Npc = "GatoPolicia1", Place = "Parque", Offset = V(3, 0, 6), Mode = "Cheer" },
				} },
		},
		Dialogues = {
			Visita = { Lines = {
				{ S = "Bigotes", T = "Humano. Ya no eres una cría. Pero sigues siendo humano. Nadie es perfecto.", Shot = "Medio:Bigotes" },
				{ S = "Bigotes", T = "{Duque/Duquesa} del Cojín: tu título sigue en vigor. Lo he vuelto a sellar yo mismo. Con la pata.", If = { Flags = { "DuqueDeGatonia" } } },
				-- Le pediste las coordenadas en su palacio de G-4 (Saga_14)
				{ S = "Bigotes", T = "En G-4 te di unas coordenadas en mi palacio. Sé que las usaste bien: el loco del garaje ha vuelto.", If = { Memories = { "PresidenteBigotes" } } },
				{ S = "Bigotes", T = "Vengo en visita oficial. Asunto: la Gran Fusión.", Beat = "Respira" },
				{ S = "Bigotes", T = "Si las dos Valmar se juntan, habrá dos de cada gato. Y un solo sofá. Inaceptable.", A = "Angry" },
				{ S = "Bigotes", T = "Y hay otro asunto. Las cucarachas de Crujiente. Dijeron que volverían cuando se secaran.", Beat = "Piensa" },
				{ S = "Bigotes", T = "Se han secado. Ahora espían para el Consorcio. Con corbata.", Shot = "PrimerPlano:Bigotes" },
				{ S = "GatoPolicia1", T = "Señor presidente: la nave enemiga ha aterrizado en el césped. Ha pisado una margarita.", To = "Bigotes", Shot = "DosPlanos:GatoPolicia1,Bigotes" },
				{ S = "Bigotes", T = "Humano: ya sabes lo que odian. Esta vez no hay globos. Hay manguera.", To = "Yo", G = "Point" },
				{ S = "Bigotes", T = "Yo miraré. Con dignidad. Desde lejos. Muy lejos del agua.", Beat = "Aparta" },
			} },
			Manguera = { Lines = {
				{ S = "Narrador", T = "Una manguera de riego, enrollada y con muchas ganas de trabajar. El jardinero no está. Seguro que no le importa." },
			} },
			Canciller = { Lines = {
				{ S = "Bigotes", T = "Mojadas otra vez. Hay especies que no aprenden. Las cucarachas. Y los que ponen piña en la pizza." },
				{ S = "Bigotes", T = "Por tus servicios al Imperio, te nombro Canciller de Gatonia en Valmar. Cargo para toda la vida.", Shot = "Medio:Bigotes" },
				{ S = "Bigotes", T = "Sueldo: una siesta al sol por semana.", Pause = 0.5 },
				{ S = "Bigotes", T = "Y escucha bien: cuando llegue la Gran Fusión, la Guardia Gatuna estará allí. Cuarenta gatos. En cuarenta cajas. Supervisando.", IfNot = { Flags = { "FusionDetenida" } }, To = "Yo" },
				{ S = "Bigotes", T = "La Gran Fusión ya pasó. La Guardia Gatuna llegó tarde: estaba durmiendo en cuarenta cajas. La próxima vez, supervisaremos.", If = { Flags = { "FusionDetenida" } }, To = "Yo" },
				{ S = "GatoPolicia1", T = "Y maullando al enemigo con desprecio. Llevamos siglos entrenando ese maullido." },
				{ S = "Narrador", T = "Recibes 🎗️ la Banda de Canciller de Gatonia. Huele a atún. Es un honor." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Rex · Rex, abogado del Ancla
	---------------------------------------------------------------------
	{
		Id = "Aliado_Rex",
		Kind = "Side",
		Title = "Rex, abogado del Ancla",
		Description = "El Consorcio MegaVerso te ha puesto una demanda: dice que eres un Ancla «sin licencia». Rex, ya en cuarto de Derecho, quiere defenderte. Gratis. Bueno, a cambio de jamón.",
		Type = "Misión de aliado · Rex",
		Duration = { 15, 22 },
		Npcs = { "Rex", "AgenteGris1" },
		Offer = { Place = "FacultadDerecho" },
		OfferKey = "Rex te espera en la puerta de la facultad con un papel en la boca. Es una demanda. A tu nombre",
		Requires = { Stage = UNI_O_MAS, Completed = { "Loco_U2_Rex", "Saga_09_Archivo" }, Flags = { "RexSeQueda" } },
		Moment = "Rex te defendió ante el tribunal (y ganó)",
		Memory = "AbogadoRex",
		Rewards = { Items = { TarjetaRex = 1 }, Flags = { "RexAbogado" } },
		Props = {
			Folleto = { Kind = "Papel", Name = "Un folleto de MegaVerso (con letra pequeñísima)", Prompt = "Leer la letra pequeña", Place = "OficinasFinanciero", Offset = V(3, 0, 3), Dialogue = "LetraPequena", Once = true },
			Caja = { Kind = "Caja", Name = "La caja de fotos de cuando eras bebé", Prompt = "Buscar tu partida de nacimiento", Place = "CasaFamiliar", Offset = V(2, 0, 2), Dialogue = "Partida", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Rex", Dialogue = "Encargo", Text = "Rex tiene algo para ti (en la boca)",
				Actors = { { Npc = "Rex", Place = "FacultadDerecho", Offset = V(2, 0, 3) } } },
			{ Type = "Group", Text = "Reúne las pruebas para el juicio",
				Steps = {
					{ Type = "Use", Prop = "Folleto", Text = "La letra pequeña de MegaVerso (el Distrito Financiero)" },
					{ Type = "Use", Prop = "Caja", Text = "Tu partida de nacimiento (la casa familiar)" },
				} },
			{ Type = "Choice", Key = "Alegato", Text = "Rex te deja decir la última palabra ante el tribunal. ¿Qué dices?",
				Options = {
					{ Id = "Corazon", Text = "«Yo no elegí ser el Ancla. Pero elijo quedarme. Esta es mi casa»", Effects = { Traits = { Empatia = 2 } } },
					{ Id = "Letra", Text = "Leer en voz alta la letra pequeña del folleto de MegaVerso", Effects = { Traits = { Curiosidad = 2 } } },
					{ Id = "Jamon", Text = "«Mi abogado es un velocirraptor. Yo que ustedes, retiraría la demanda»", Effects = { Traits = { Humor = 2 } } },
				},
				Actors = {
					{ Npc = "Rex", Place = "FacultadDerecho", Offset = V(2, 0, 3) },
					{ Npc = "AgenteGris1", Place = "FacultadDerecho", Offset = V(-3, 0, 4) },
				} },
			{ Type = "Scene", Dialogue = "Juicio",
				Actors = {
					{ Npc = "Rex", Place = "FacultadDerecho", Offset = V(2, 0, 3), Mode = "Cheer" },
					{ Npc = "AgenteGris1", Place = "FacultadDerecho", Offset = V(-3, 0, 4) },
				} },
		},
		Dialogues = {
			Encargo = { Lines = {
				{ S = "Rex", T = "{Saludo}. Perdona la baba. Me la han dado en mano y no tenía manos libres. Es una demanda. Contra ti." },
				{ S = "Rex", T = "«MegaVerso S.A. contra el Ancla». Dicen que ocupas una dimensión sin licencia.", Shot = "Medio:Rex" },
				{ S = "Rex", T = "Que la sujetas «sin permiso de la comunidad de propietarios del multiverso».", A = "Facepalm" },
				{ S = "Rex", T = "Si perdemos, te desanclan. O sea: te mandan a la 66-B.", Beat = "Respira", To = "Yo" },
				{ S = "Rex", T = "Y yo me quedo sin nadie que me defienda el jamón. Digo, que me deje el jamón.", A = "Ashamed" },
				{ S = "Rex", T = "Me defendiste ante la Aduana del Tiempo. Ahora me toca a mí.", Beat = "Mira", To = "Yo" },
				{ S = "Rex", T = "Estoy en cuarto. Tengo toga. Me la hice con una cortina. Necesito pruebas.", A = "HandsOnHips" },
			} },
			LetraPequena = { Lines = {
				{ S = "Narrador", T = "La letra es tan pequeña que hay que mirarla con los ojos entornados." },
				{ S = "Narrador", T = "«Cláusula 88: el Consorcio podrá quedarse con cualquier dimensión que no esté bien sujeta»." },
				{ S = "Narrador", T = "Justo debajo, más pequeño todavía: «Por eso hay que quitar el Ancla primero». Lo han escrito ellos. Con su propio bolígrafo." },
			} },
			Partida = { Lines = {
				{ S = "Narrador", T = "Entre fotos de bebé (en todas sales llorando, menos en una, con cara de sueño) está tu partida de nacimiento." },
				{ S = "Narrador", T = "Lugar de nacimiento: Valmar. Hora: la de la Grieta.", Pause = 0.6 },
				{ S = "Narrador", T = "Alguien ha escrito a lápiz, en el margen: «Aquí se queda. Es de aquí». Es la letra de tu familia.", Pause = 0.8 },
			} },
			Juicio = { Lines = {
				{ S = "AgenteGris1", T = "Señoría. El Ancla no tiene licencia. El Consorcio solicita que se le retire.", Shot = "Medio:AgenteGris1" },
				{ S = "AgenteGris1", T = "Con cuidado. O sin cuidado. Nos da igual.", A = "Shrug" },
				{ S = "Rex", T = "Protesto. Prueba número uno: la partida de nacimiento. Mi cliente nació aquí.", G = "Point", Shot = "Medio:Rex" },
				{ S = "Rex", T = "Nadie necesita licencia para ser de su casa.", Pause = 0.6 },
				{ S = "Rex", T = "Prueba número dos: la cláusula 88 del Consorcio. Quieren el Ancla fuera para quedarse con la dimensión.", To = "AgenteGris1" },
				{ S = "Rex", T = "Lo pone su folleto. En letra pequeña. Pero lo pone.", Beat = "Sonrie" },
				-- Tu alegato (la decisión de antes), dicho y actuado
				{ S = "Rex", T = "(Silencio. Rex te pone la mano, con garra y todo, sobre el hombro.)", If = { Choices = { Alegato = "Corazon" } }, Pause = 0.8 },
				{ S = "Yo", T = "Yo no elegí ser el Ancla. Pero elijo quedarme. Esta es mi casa.", If = { Choices = { Alegato = "Corazon" } } },
				{ S = "Narrador", T = "En la sala, alguien aplaude flojito.", If = { Choices = { Alegato = "Corazon" } } },
				{ S = "Narrador", T = "Lees la letra pequeña en voz alta. Muy despacio. El agente de MegaVerso se pone gris. Más gris de lo que ya era.", If = { Choices = { Alegato = "Letra" } } },
				{ S = "Yo", T = "Mi abogado es un velocirraptor. Yo que ustedes, retiraría la demanda.", If = { Choices = { Alegato = "Jamon" } } },
				{ S = "Rex", T = "(Sonríe. Con todos los dientes. Son muchos dientes.)", If = { Choices = { Alegato = "Jamon" } }, Shot = "PrimerPlano:Rex" },
				{ S = "AgenteGris1", T = "…El Consorcio retira la demanda. Por ahora.", Pause = 0.8, A = "Angry" },
				{ S = "AgenteGris1", T = "Esto no acaba aquí. Acaba en el Monte del Silencio. Ya lo verán.", IfNot = { Flags = { "FusionDetenida" } } },
				{ S = "Rex", T = "¡GRAAAAH! Perdón. Es mi primer juicio ganado.", G = "Cheer", Shot = "Medio:Rex" },
				{ S = "Rex", T = "Toma: mi tarjeta de abogado. Y apúntalo: cuando llegue esa batalla del monte, voy. Con garras y con código civil.", IfNot = { Flags = { "FusionDetenida" } }, To = "Yo" },
				{ S = "Rex", T = "Toma: mi tarjeta de abogado. Si el de la perilla vuelve a las andadas, le demando. Con garras y con código civil.", If = { Flags = { "FusionDetenida" } }, To = "Yo" },
				{ S = "Narrador", T = "Recibes 📇 la Tarjeta de Rex, abogado. Tiene un mordisco en una esquina. Es su firma." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Ratón Pérez · La muela del juicio
	---------------------------------------------------------------------
	{
		Id = "Aliado_Perez",
		Kind = "Side",
		Title = "La muela del juicio",
		Description = "Te han sacado la muela del juicio. Esa noche vuelve el Ratón Pérez: una muela del juicio vale por diez. Pero trae malas noticias: el Consorcio está comprando dientes.",
		Type = "Misión de aliado · Ratón Pérez",
		Duration = { 12, 18 },
		Npcs = { "RatonPerez", "AgenteGris1" },
		Offer = { Place = "Home" },
		OfferKey = "Te han sacado la muela del juicio. La tienes en un vaso. Algo refunfuña dentro del vaso",
		Requires = { Stage = UNI_O_MAS, Completed = { "Loco_N5_Perez", "Saga_08_MegaVerso" }, Hours = { From = 20, To = 7 } },
		Moment = "Recuperaste los dientes que robaba el Consorcio",
		Memory = "MuelaDelJuicio",
		Rewards = { Items = { CarnetSindical = 1 }, Money = 60, Flags = { "PatrullaRatones" } },
		Steps = {
			{ Type = "Scene", Dialogue = "Visita", Actors = { { Npc = "RatonPerez", Place = "Home", Offset = V(1, 0, 2) } } },
			{ Type = "Chase", Npc = "AgenteGris1", Catch = 6, Text = "¡Un agente de MegaVerso se lleva el saco de dientes! ¡Atrápalo!",
				Actors = {
					{ Npc = "AgenteGris1", Place = "Home", Offset = V(3, 0, 6), Mode = "Flee", Speed = 14, Prompt = false,
						Route = { "Parque", "FuenteParque" } },
					{ Npc = "RatonPerez", Mode = "Follow" },
				} },
			{ Type = "Scene", Dialogue = "Saco",
				Actors = {
					{ Npc = "AgenteGris1", Place = "FuenteParque", Offset = V(2, 0, 2) },
					{ Npc = "RatonPerez", Place = "FuenteParque", Offset = V(-2, 0, 2) },
				} },
		},
		Dialogues = {
			Visita = { Lines = {
				{ S = "RatonPerez", T = "¡Una muela del juicio! ¿Sabes lo que vale esto? Diez dientes normales.", A = "Surprised", Shot = "Medio:RatonPerez" },
				{ S = "RatonPerez", T = "Es la muela con más estudios de la boca." },
				{ S = "RatonPerez", T = "Hola, por cierto. Cuánto has crecido.", Beat = "Mira", To = "Yo" },
				{ S = "RatonPerez", T = "La última vez yo te llegaba por el tobillo. Ahora te llego por el cordón.", A = "Shrug" },
				-- La noche de la Rata Ladrona (Loco_N5_Perez)
				{ S = "RatonPerez", T = "Aún me acuerdo de aquella persecución hasta la fuente. Corrías más que un gato con prisa.", If = { Memories = { "RatonPerez" } } },
				{ S = "RatonPerez", T = "Y he vuelto de vacaciones. Gracias a ti tengo ayudante. La rata ya es jefa de turno. Hace horas extra. Me da un poco de miedo.", If = { Flags = { "RataContratada" } } },
				{ S = "RatonPerez", T = "Pero no he venido solo por la muela. Hay un problema. Alguien está comprando dientes. Miles. En el mercado negro. Pagan el triple." },
				{ S = "RatonPerez", T = "Es el Consorcio. Hacen polvo de hada con ellos. Para la máquina de su Gran Fusión.", Beat = "Respira", A = "Angry" },
				{ S = "RatonPerez", T = "Esa máquina funciona con sonrisas de niño. ¡Con SONRISAS!", Shot = "PrimerPlano:RatonPerez" },
				{ S = "Narrador", T = "Por la ventana entra un brazo de traje gris, coge el saco de dientes del Ratón Pérez y sale corriendo.", Pause = 0.4 },
				{ S = "Narrador", T = "Con zapatos de oficina. Muy rápido para llevar zapatos de oficina." },
				{ S = "RatonPerez", T = "¡OTRA VEZ NO! ¡Detenlo! ¡Yo sigo teniendo las piernas de tres centímetros!" },
			} },
			Saco = { Lines = {
				{ S = "AgenteGris1", T = "¡Vale, vale! Lo devuelvo. Yo solo cumplo órdenes. Y el Consorcio paga fatal. Ni siquiera tenemos seguro dental. Qué ironía." },
				{ S = "RatonPerez", T = "El saco. Ahora. …Y dile a tu jefe de la perilla que los dientes de Valmar tienen sindicato." },
				{ S = "RatonPerez", T = "Escúchame, Ancla. Porque sé lo que eres: me lo han contado los ratones del Consorcio.", Beat = "Mira", To = "Yo" },
				{ S = "RatonPerez", T = "Cuando llegue la batalla, la patrulla de ratones estará allí. Somos pequeños. Pero mordemos cables.", IfNot = { Flags = { "FusionDetenida" } }, G = "Point" },
				{ S = "RatonPerez", T = "La batalla del monte ya pasó, pero los ratones no olvidamos. Si el Consorcio vuelve, mordemos cables.", If = { Flags = { "FusionDetenida" } } },
				{ S = "RatonPerez", T = "Toma: tu carnet del sindicato. Miembro de honor. Y sesenta monedas por la muela. Precio de muela del juicio." },
				{ S = "RatonPerez", T = "No se lo digas a nadie, que luego todos quieren.", Pause = 0.4 },
				{ S = "Narrador", T = "Recibes 💳 el Carnet del Sindicato de Roedores (y 60 monedas)." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Cronos · El expediente de Cronos
	---------------------------------------------------------------------
	{
		Id = "Aliado_Cronos",
		Kind = "Side",
		Title = "El expediente de Cronos",
		Description = "La Aduana del Tiempo ha abierto un expediente al agente Cronos por «ayudar a un Ancla». Necesita firmas de gente de confianza. Y un sello. Siempre falta un sello.",
		Type = "Misión de aliado · Agente Cronos",
		Duration = { 15, 20 },
		Npcs = { "CazadorTiempo", "Abu", "Pip" },
		Offer = { Place = "Correos" },
		OfferKey = "El agente Cronos está en Correos, de pie junto a la ventanilla, sin sellos. Nunca le habías visto sin sellos",
		Requires = { Stage = UNI_O_MAS, Completed = { "Saga_11_Cronos" }, Flags = { "CronosAliado" } },
		Moment = "Salvaste al agente Cronos de su propio expediente",
		Memory = "ExpedienteCronos",
		Rewards = { Items = { Formulario42B = 1 }, Flags = { "CronosLimpio" } },
		Props = {
			Ventanilla = { Kind = "Kiosco", Name = "La ventanilla 42", Prompt = "Pedir el sello", Place = "Correos", Offset = V(-3, 0, 4), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Sello", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "CazadorTiempo", Dialogue = "Expediente", Text = "Habla con el agente Cronos",
				Actors = { { Npc = "CazadorTiempo", Place = "Correos", Offset = V(0, 0, 4), Mode = "Sit" } } },
			{ Type = "Group", Text = "Consigue las firmas para el expediente de Cronos",
				Actors = {
					{ Npc = "Abu", Place = "Home", Offset = V(2, 0, 3), Mode = "Sit" },
					{ Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) },
				},
				Steps = {
					{ Type = "Talk", Npc = "Abu", Dialogue = "FirmaAbu", Text = "La firma de {abu} (en casa)" },
					{ Type = "Talk", Npc = "Pip", Dialogue = "FirmaPip", Text = "La firma de Pip (el garaje)" },
					{ Type = "Use", Prop = "Ventanilla", Text = "El sello de la ventanilla 42 (Correos)" },
				} },
			{ Type = "Choice", Key = "Declaracion", Text = "La Inspectora del Tiempo te pregunta: «¿Ha ayudado el agente Cronos a un Ancla?». ¿Qué dices?",
				Options = {
					{ Id = "Verdad", Text = "«Sí. Y gracias a eso, esta dimensión sigue en su sitio»", Effects = { Traits = { Responsabilidad = 2 } } },
					{ Id = "Formulario", Text = "Rellenar el formulario 42-B con muy buena letra", Effects = { Traits = { Curiosidad = 1, Humor = 1 } } },
				},
				Actors = { { Npc = "CazadorTiempo", Place = "Correos", Offset = V(0, 0, 4) } } },
			{ Type = "Scene", Dialogue = "Veredicto", Actors = { { Npc = "CazadorTiempo", Place = "Correos", Offset = V(0, 0, 4), Mode = "Cheer" } } },
		},
		Dialogues = {
			Expediente = { Lines = {
				{ S = "CazadorTiempo", T = "Ancla. Me han abierto un expediente. A mí.", Shot = "Medio:CazadorTiempo", A = "Sad" },
				{ S = "CazadorTiempo", T = "Cuatrocientos años de carrera y ni una multa. Bueno, una. Por aparcar en 1830.", Beat = "Aparta" },
				{ S = "CazadorTiempo", T = "Motivo: «confraternizar con un Ancla». O sea, contigo. Alguien del Consorcio me ha denunciado.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Con un formulario falso. Sé que es falso: tiene faltas de ortografía.", A = "ArmsCrossed" },
				{ S = "CazadorTiempo", T = "Si pierdo, me mandan a archivar el Jurásico. Sin sellos. Allí los sellos se los comen los dinosaurios.", Beat = "Respira" },
				-- Te conoce desde el formulario 42 (Saga_04)
				{ S = "CazadorTiempo", T = "Le conozco desde el formulario 42. Sé de quién me puedo fiar.", If = { Flags = { "CronosTeConoce" } }, To = "Yo" },
				{ S = "CazadorTiempo", T = "Necesito dos firmas de gente de confianza y el sello de la ventanilla 42.", G = "Point" },
				{ S = "CazadorTiempo", T = "La conoces. Es la que te manda a otra ventanilla." },
			} },
			FirmaAbu = { Lines = {
				{ S = "Abu", T = "¿Firmar por un señor que brilla y lleva cuarenta formularios? Cariño, en mis tiempos a eso lo llamábamos «funcionario». Firmo. Con buena letra." },
				{ S = "Abu", T = "Y pon que es un señor muy educado. Una vez me ayudó con la declaración de la renta. De 1974. Ni sé cómo." },
			} },
			FirmaPip = { Lines = {
				{ S = "Pip", T = "Firmo. Mi firma es un código de barras. Es válida en catorce dimensiones y en el supermercado." },
				{ S = "Pip", T = "El señor Cosme firmaría también. Pero ahora no está. Firmo yo por los dos. Con dos códigos de barras.", If = { Flags = { "CosmeSecuestrado" } } },
			} },
			Sello = { Lines = {
				{ S = "Narrador", T = "La ventanilla 42 está abierta. La funcionaria te mira, mira el formulario, mira el reloj." },
				{ S = "Narrador", T = "«Esta es la ventanilla 42. Ah, pues sí. Es aquí». ¡Pum! Sello.", Pause = 0.5 },
				{ S = "Narrador", T = "Es la primera vez en la historia de la Aduana que alguien consigue un sello a la primera. Suena una campana." },
			} },
			Veredicto = { Lines = {
				{ S = "Narrador", T = "La Inspectora del Tiempo asiente despacio. «La verdad no necesita sello». Y luego lo sella igual. Es la costumbre.", If = { Choices = { Declaracion = "Verdad" } } },
				{ S = "Narrador", T = "La Inspectora del Tiempo mira tu letra con lupa. «Qué caligrafía. Qué márgenes». Se le escapa una lágrima. Sella tres veces.", If = { Choices = { Declaracion = "Formulario" } } },
				{ S = "CazadorTiempo", T = "Expediente archivado. Limpio. Sin manchas. Como un formulario nuevo." },
				{ S = "CazadorTiempo", T = "Ancla: me has devuelto el trabajo. Y el uniforme.", Beat = "Respira", To = "Yo", A = "Happy" },
				{ S = "CazadorTiempo", T = "Cuando llegue la Gran Fusión, estaré allí. De uniforme. Con todos mis sellos. Y esta vez, a tiempo.", IfNot = { Flags = { "FusionDetenida" } } },
				{ S = "CazadorTiempo", T = "La próxima vez que haya que salvar el universo, llegaré a tiempo. Lo pondré en la agenda. Con sello.", If = { Flags = { "FusionDetenida" } } },
				{ S = "Narrador", T = "Recibes 📋 el Formulario 42-B (sellado). Por detrás, Cronos ha escrito: «Gracias». Con sello." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Capitana Ñoz · Final de temporada
	---------------------------------------------------------------------
	{
		Id = "Aliado_Noz",
		Kind = "Side",
		Title = "Final de temporada",
		Description = "La Capitana Ñoz vuelve al Monte del Silencio: quieren cancelar su reality. Solo lo salvará un final de temporada a lo grande. Y necesita grabar la promo contigo.",
		Type = "Misión de aliado · Capitana Ñoz",
		Duration = { 15, 22 },
		Npcs = { "CapitanNoz", "Blorp", "Zarg" },
		Offer = { Place = "MonteSilencio" },
		OfferKey = "Otra vez la luz en el Monte del Silencio. Esta vez con un cartel: «¡ÚLTIMA TEMPORADA!»",
		Requires = { Stage = UNI_O_MAS, Completed = { "Saga_15_Reestreno" }, Hours = { From = 21, To = 5 } },
		Moment = "Grabaste la promo del final de temporada con la Capitana Ñoz",
		Memory = "TemporadaFinal",
		Rewards = { Items = { ClaquetaAlien = 1 }, Flags = { "NaveEnElFinal" } },
		Props = {
			Nave = { Kind = "Nave", Name = "La nave del reality", Place = "MonteSilencio", Offset = V(0, 0, -8), Height = 20, Prompt = false },
			Toma1 = { Kind = "Pantalla", Name = "Cámara alienígena: toma 1 (la plaza)", Prompt = "Grabar la toma", Place = "PlazaCentro", Offset = V(3, 0, 4), Color = Color3.fromRGB(90, 255, 120), Dialogue = "Toma1", Once = true },
			Toma2 = { Kind = "Pantalla", Name = "Cámara alienígena: toma 2 (la playa)", Prompt = "Grabar la toma", Place = "Playa", Offset = V(0, 0, 5), Color = Color3.fromRGB(90, 255, 120), Dialogue = "Toma2", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "CapitanNoz", Dialogue = "Cancelacion", Text = "La Capitana Ñoz baja de la nave",
				Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3) },
					{ Npc = "Blorp", Place = "MonteSilencio", Offset = V(-4, 0, 2), Mode = "Wave" },
				} },
			{ Type = "Group", Text = "Graba las tomas de la promo",
				Steps = {
					{ Type = "Use", Prop = "Toma1", Text = "Toma 1: «El Ancla pasea por su ciudad» (la plaza)" },
					{ Type = "Use", Prop = "Toma2", Text = "Toma 2: «El Ancla mira el mar, pensativo» (la playa)" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Última toma: ¡acción!", Icon = "🎬", Hint = "Di «¡Valmar no se fusiona!» justo cuando se encienda la luz roja",
				Rounds = 5, Need = 3, Zone = 0.26, Speed = 1,
				Win = { Flags = { "PromoPerfecta" } }, Lose = { Traits = { Humor = 1 } },
				Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3), Mode = "Point" },
					{ Npc = "Zarg", Place = "MonteSilencio", Offset = V(4, 0, 2) },
				} },
			{ Type = "Scene", Dialogue = "Contrato", Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3) },
					{ Npc = "Blorp", Place = "MonteSilencio", Offset = V(-4, 0, 2), Mode = "Cheer" },
					{ Npc = "Zarg", Place = "MonteSilencio", Offset = V(4, 0, 2) },
				} },
		},
		Dialogues = {
			Cancelacion = { Lines = {
				{ S = "CapitanNoz", T = "¡Mi estrella! ¡Qué alegría! Bueno, qué alegría a medias.", Shot = "Medio:CapitanNoz", G = "Wave" },
				{ S = "CapitanNoz", T = "Me quieren cancelar el programa. Trescientas temporadas y me cancelan. Por un concurso de cocina de Júpiter.", A = "Sad" },
				-- El episodio especial del rescate (Saga_15)
				{ S = "CapitanNoz", T = "Y eso que el episodio especial del rescate lo vieron hasta en los cráteres de la Luna.", If = { Memories = { "EpisodioEspecial" } } },
				{ S = "CapitanNoz", T = "Tú saliste en el primer episodio de esta temporada. El de la huida del monte. Aún lo repiten en los aviones de Andrómeda.", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "La audiencia solo quiere una cosa: el final. La Gran Fusión. En directo.", Beat = "Piensa" },
				{ S = "CapitanNoz", T = "El Ancla contra el de la perilla. Si lo emito, me renuevan diez temporadas.", G = "Point" },
				{ S = "Blorp", T = "¡Blorp! ¡Y a cambio la nave va a la batalla! ¡Con focos! ¡Y con palomitas para los aliados!", G = "Cheer" },
				{ S = "CapitanNoz", T = "Pero primero, la promo. Dos tomas en tu ciudad y una aquí arriba.", To = "Yo" },
				{ S = "CapitanNoz", T = "Tú solo tienes que ser tú. Pero más. Mucho más.", Beat = "Sonrie" },
				-- Ya rodaste con ella el reestreno (Saga_15): sabe cómo te mueves delante de la cámara
				{ S = "Blorp", T = "¡Blorp! Con la toma perfecta del reestreno, esto lo haces con los ojos cerrados.", If = { Flags = { "BuenRodaje" } } },
			} },
			Toma1 = { Lines = {
				{ S = "Narrador", T = "Paseas por la plaza mientras una cámara alienígena flota a tu lado. Un señor te pide un autógrafo." },
				{ S = "Narrador", T = "Cree que eres de la tele. Ahora, técnicamente, lo eres." },
			} },
			Toma2 = { Lines = {
				{ S = "Narrador", T = "Miras el mar con cara pensativa. La cámara hace zoom. Tanto zoom que se cae a la arena." },
				{ S = "Narrador", T = "Repetís la toma. Tres veces. La tercera, piensas de verdad.", Pause = 0.6 },
			} },
			Contrato = { Lines = {
				{ S = "CapitanNoz", T = "¡CORTEN! Eso ha sido… ¡eso ha sido televisión! La galaxia entera va a llorar. Hasta los que no tienen ojos.", If = { Flags = { "PromoPerfecta" } } },
				{ S = "CapitanNoz", T = "¡CORTEN! Se te ha trabado la frase tres veces. Da igual: la audiencia lo va a adorar. Lo real vende más que lo perfecto.", If = { NotFlags = { "PromoPerfecta" } } },
				{ S = "Zarg", T = "Contrato firmado. Cuando llegue la Gran Fusión, la nave estará sobre el monte.", Shot = "Medio:Zarg" },
				{ S = "Zarg", T = "Focos, cámaras y un rayo tractor para lo que haga falta." },
				{ S = "CapitanNoz", T = "Y tú saldrás en el cartel. En letras grandes. Más grandes que las mías.", To = "Yo" },
				{ S = "CapitanNoz", T = "…Bueno, igual de grandes. Toma, un recuerdo del rodaje.", Beat = "Piensa" },
				{ S = "Narrador", T = "Recibes 🎬 la Claqueta alienígena. Pone: «Terrícolas en apuros · Final de temporada · Toma 1 de 1»." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Gnomos · El consejo de los jardines
	---------------------------------------------------------------------
	{
		Id = "Aliado_Gnomos",
		Kind = "Side",
		Title = "El consejo de los jardines",
		Description = "Rigoberto te despierta de madrugada: el Consorcio ha llenado los jardines de Valmar de gnomos de plástico con cámaras. El Gran Gnomo convoca el consejo.",
		Type = "Misión de aliado · Los gnomos",
		Duration = { 15, 20 },
		Npcs = { "Gnomo1", "Gnomo2", "Gnomo3" },
		Offer = { Place = "Home" },
		OfferKey = "Rigoberto, tu gnomo, te tira de la manta. «¡Alarma! ¡Impostores de plástico!»",
		Requires = { Stage = ADULTO, Completed = { "Loco_D4_Gnomos", "Saga_08_MegaVerso" }, Hours = { From = 22, To = 5 } },
		Moment = "Presidiste el consejo de los jardines",
		Memory = "ConsejoGnomos",
		Rewards = { Items = { GorroGnomo = 1 }, Flags = { "GnomosEnPie" } },
		Props = {
			Espia1 = { Kind = "Trofeo", Name = "Un gnomo de plástico con una cámara en el gorro", Prompt = "Quitarle la cámara", Place = "Parque", Offset = V(4, 0, 4), Color = Color3.fromRGB(200, 60, 60), Dialogue = "Espia", Once = true },
			Espia2 = { Kind = "Trofeo", Name = "Un gnomo de plástico con antena", Prompt = "Quitarle la cámara", Place = "PlazaCentro", Offset = V(-4, 0, 4), Color = Color3.fromRGB(200, 60, 60), Dialogue = "Espia", Once = true },
			Espia3 = { Kind = "Trofeo", Name = "Un gnomo de plástico (que finge mucho)", Prompt = "Quitarle la cámara", Place = "CaminoAlGaraje", Offset = V(2, 0, 2), Color = Color3.fromRGB(200, 60, 60), Dialogue = "Espia", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Gnomo1", Dialogue = "Alarma", Text = "Rigoberto da la alarma",
				Actors = { { Npc = "Gnomo1", Place = "Home", Offset = V(4, 0, 6) } } },
			{ Type = "Group", Text = "Desactiva los gnomos espía del Consorcio",
				Steps = {
					{ Type = "Use", Prop = "Espia1", Text = "El del parque" },
					{ Type = "Use", Prop = "Espia2", Text = "El de la plaza" },
					{ Type = "Use", Prop = "Espia3", Text = "El del camino al garaje" },
				} },
			{ Type = "Choice", Key = "Espias", Text = "El Gran Gnomo pregunta qué hacemos con los gnomos de plástico. El consejo te escucha",
				Options = {
					{ Id = "Adoptar", Text = "«Adoptadlos. No tienen la culpa de ser de plástico»", Effects = { Traits = { Empatia = 2 } } },
					{ Id = "Reciclar", Text = "«Al contenedor amarillo. Es lo que dice la ley»", Effects = { Traits = { Responsabilidad = 2 } } },
					{ Id = "Devolver", Text = "«Devolvédselos al Consorcio. Con una nota muy maleducada»", Effects = { Traits = { Rebeldia = 1, Humor = 1 } } },
				},
				Actors = {
					{ Npc = "Gnomo3", Place = "Home", Offset = V(0, 0, 8) },
					{ Npc = "Gnomo1", Place = "Home", Offset = V(-3, 0, 9) },
					{ Npc = "Gnomo2", Place = "Home", Offset = V(3, 0, 9) },
				} },
			{ Type = "Scene", Dialogue = "Consejo",
				Actors = {
					{ Npc = "Gnomo3", Place = "Home", Offset = V(0, 0, 8) },
					{ Npc = "Gnomo1", Place = "Home", Offset = V(-3, 0, 9), Mode = "Cheer" },
					{ Npc = "Gnomo2", Place = "Home", Offset = V(3, 0, 9) },
				} },
		},
		Dialogues = {
			Alarma = { Lines = {
				{ S = "Gnomo1", T = "¡Gigante! ¡Despierta! ¡Emergencia de nivel cerámica! ¡Hay gnomos nuevos en todos los jardines de Valmar!" },
				{ S = "Gnomo1", T = "No son gnomos de verdad. Son de PLÁSTICO. Huecos. Sin alma. Con una cámara en el gorro.", A = "Angry", Shot = "Medio:Gnomo1" },
				{ S = "Gnomo1", T = "Pone «Made in MegaVerso». Es un insulto a mi especie.", Beat = "Respira" },
				{ S = "Gnomo1", T = "El Gran Gnomo ha convocado el Consejo de los Jardines. Pero antes hay que apagar las cámaras.", To = "Yo" },
				{ S = "Gnomo1", T = "Yo no puedo: si me agacho, me quedo boca abajo.", A = "Ashamed" },
			} },
			Espia = { Lines = {
				{ S = "Narrador", T = "El gnomo de plástico sonríe. Siempre sonríe. En el gorro, una lucecita roja parpadea." },
				{ S = "Narrador", T = "Le quitas la cámara. La lucecita se apaga. La sonrisa, no.", Pause = 0.5 },
			} },
			Consejo = { Lines = {
				{ S = "Gnomo3", T = "Se abre el Consejo de los Jardines. El primero en cuatro siglos.", Shot = "General" },
				{ S = "Gnomo3", T = "Presentes: todos los gnomos de Valmar. Ausentes: los que se han caído en una maceta.", Beat = "Respira" },
				{ S = "Gnomo3", T = "Los adoptamos. Les enseñaremos a ser gnomos de verdad: estarse quietos con orgullo y asustar gatos.", If = { Choices = { Espias = "Adoptar" } } },
				{ S = "Gnomo3", T = "En unos siglos, serán de cerámica. Por dentro.", If = { Choices = { Espias = "Adoptar" } }, Pause = 0.4 },
				{ S = "Gnomo3", T = "Al amarillo. Los gnomos respetamos las leyes del reciclaje. Somos de barro: sabemos lo que es volver a la tierra.", If = { Choices = { Espias = "Reciclar" } } },
				{ S = "Gnomo2", T = "¡Ya he escrito la nota! Pone «¡Id a espiar a vuestra abuela!». Con barro. Y faltas de ortografía a propósito.", If = { Choices = { Espias = "Devolver" } } },
				{ S = "Gnomo3", T = "Y el Consejo vota: cuando llegue la Gran Fusión, los gnomos marcharán. Todos.", IfNot = { Flags = { "FusionDetenida" } }, Shot = "Medio:Gnomo3" },
				{ S = "Gnomo3", T = "Despacito, porque tenemos las piernas cortas. Pero llegaremos.", IfNot = { Flags = { "FusionDetenida" } } },
				-- Si la batalla del monte ya pasó, los gnomos lo saben (y llegaron tarde)
				{ S = "Gnomo3", T = "Y el Consejo reconoce que la Gran Fusión ya pasó. Llegamos tarde. Piernas cortas.", If = { Flags = { "FusionDetenida" } }, Shot = "Medio:Gnomo3", A = "Ashamed" },
				{ S = "Gnomo3", T = "Pero el Consejo vota: la próxima vez que el universo esté en peligro, saldremos un mes antes.", If = { Flags = { "FusionDetenida" } } },
				{ S = "Gnomo1", T = "¡Y te nombramos Gnomo Honorario! Toma el gorro. Te queda un poco pequeño.", G = "Cheer", To = "Yo" },
				{ S = "Gnomo1", T = "A todos nos queda un poco pequeño. Es la tradición." },
				{ S = "Narrador", T = "Recibes 🔺 el Gorro de gnomo honorario. Huele a tierra mojada y a cuatro siglos de rencor. Ahora, bien dirigido." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- Tu yo malvado · Clases de ser bueno
	---------------------------------------------------------------------
	{
		Id = "Aliado_Malvado",
		Kind = "Side",
		Title = "Clases de ser bueno",
		Description = "Tu yo malvado ha vuelto. Sin perilla. Quiere ser bueno, pero no le sale: ayuda a señoras que no quieren cruzar. Te pide clases.",
		Type = "Misión de aliado · Tu yo malvado",
		Duration = { 15, 20 },
		Npcs = { "TuMalvado" },
		Offer = { Place = "PlazaCentro" },
		OfferKey = "En la plaza, alguien con tu cara (y sin perilla) intenta ayudar a una señora a cruzar. La señora no quería cruzar",
		Requires = { Stage = ADULTO, Completed = { "Loco_D5_Malvado" } },
		Moment = "Le enseñaste a tu yo malvado a ser bueno",
		Memory = "ClasesDeBondad",
		Rewards = { Items = { DiplomaBondad = 1 }, Flags = { "MalvadoAprendeBondad" } },
		Props = {
			Cartera = { Kind = "Llavero", Name = "Una cartera perdida", Prompt = "Devolverla (con tu yo malvado)", Place = "PlazaCentro", Offset = V(-4, 0, 3), Color = Color3.fromRGB(110, 70, 40), Dialogue = "Cartera", Once = true },
			Gato = { Kind = "Gato", Name = "Un gato subido a un árbol", Prompt = "Bajar al gato", Place = "Parque", Offset = V(4, 0, 4), Dialogue = "Gato", Once = true },
			Banco = { Kind = "Banco", Name = "Un banco con pintadas malvadas", Prompt = "Limpiar las pintadas", Place = "ParadaBus", Offset = V(2, 0, 2), Dialogue = "Banco", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "TuMalvado", Dialogue = "Ayuda", Text = "Habla con tu yo (ex)malvado",
				Actors = { { Npc = "TuMalvado", Place = "PlazaCentro", Offset = V(4, 0, 12) } } },
			{ Type = "Group", Text = "Enséñale a ser bueno (con ejemplos)",
				Actors = { { Npc = "TuMalvado", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Cartera", Text = "Devolver una cartera perdida (la plaza)" },
					{ Type = "Use", Prop = "Gato", Text = "Bajar a un gato de un árbol (el parque)" },
					{ Type = "Use", Prop = "Banco", Text = "Limpiar un banco (la parada del autobús)" },
				} },
			{ Type = "Choice", Key = "Leccion", Text = "Última lección. ¿Qué le enseñas?",
				Options = {
					{ Id = "Perdon", Text = "A pedir perdón (de verdad, sin «pero»)", Effects = { Traits = { Empatia = 2 } } },
					{ Id = "Gracias", Text = "A dar las gracias (aunque cueste)", Effects = { Traits = { Responsabilidad = 1, Empatia = 1 } } },
					{ Id = "Nadie", Text = "A hacer algo bueno sin que nadie lo vea", Effects = { Traits = { Valentia = 1, Empatia = 1 } } },
				},
				Actors = { { Npc = "TuMalvado", Place = "ParadaBus", Offset = V(-3, 0, 3) } } },
			{ Type = "Scene", Dialogue = "Diploma", Actors = { { Npc = "TuMalvado", Place = "ParadaBus", Offset = V(-3, 0, 3), Mode = "Cheer" } } },
		},
		Dialogues = {
			Ayuda = { Lines = {
				{ S = "TuMalvado", T = "Ah. Tú. Hola. No me mires así. Estoy ayudando. Creo.", Shot = "Medio:TuMalvado", A = "Nervous" },
				{ S = "TuMalvado", T = "La señora me ha dado con el bolso. Eso es que funciona, ¿no?", A = "Ask" },
				-- En la 66-B te dijo dónde estaba la rejilla (Saga_16)
				{ S = "TuMalvado", T = "Ya te ayudé una vez, con la rejilla de la 66-B. Pero eso fue sin querer. Ahora quiero que sea queriendo.", If = { Flags = { "MalvadoAyudo" } } },
				{ S = "TuMalvado", T = "En la 66-B intento ser bueno. Me han multado tres veces por «bondad en la vía pública».", If = { Flags = { "MalvadoRedimido" } } },
				{ S = "TuMalvado", T = "Y mi gato ha vuelto. Dice que ahora le caigo bien. Qué miedo.", If = { Flags = { "MalvadoRedimido" } } },
				{ S = "TuMalvado", T = "Soy aprendiz de Cosme. Le llevo la contraria todo el día. Es lo único que sé hacer bien.", If = { Flags = { "MalvadoAprendiz" } } },
				{ S = "TuMalvado", T = "Pero quiero aprender a hacer algo más.", If = { Flags = { "MalvadoAprendiz" } } },
				{ S = "TuMalvado", T = "El problema es que no sé ser bueno. Nunca lo he practicado. Tú llevas toda la vida.", Beat = "Baja" },
				{ S = "TuMalvado", T = "Enséñame. Con ejemplos. Despacio. Tomaré apuntes.", To = "Yo" },
			} },
			Cartera = { Lines = {
				{ S = "TuMalvado", T = "(Mira la cartera del suelo. Se relame. Te mira a ti. Suspira.)", A = "Sad" },
				{ S = "Narrador", T = "Buscáis juntos al dueño: un señor que casi llora de alegría." },
				{ S = "TuMalvado", T = "Me ha dado las gracias. Y un caramelo. ¿Esto pasa siempre? ¿Por qué nadie me lo había dicho?" },
			} },
			Gato = { Lines = {
				{ S = "Narrador", T = "Un gato en una rama, con cara de «yo no he sido». Lo bajas con cuidado." },
				{ S = "TuMalvado", T = "(Sujeta al gato. El gato le ronronea. Se pone rojo.)", A = "Ashamed" },
				{ S = "TuMalvado", T = "No lloro. Es alergia. A los gatos. Y a la bondad. Me pica todo." },
			} },
			Banco = { Lines = {
				{ S = "Narrador", T = "El banco pone «CÓSIMO ALCALDE» y «MUAHAHA» con espray. Lo limpias." },
				{ S = "TuMalvado", T = "El «MUAHAHA» es mío. De antes. …Froto el doble.", A = "Ashamed" },
			} },
			Diploma = { Lines = {
				{ S = "TuMalvado", T = "Perdón. …Perdón por intentar quedarme con tu vida. Y con tu sofá. Sin «pero».", If = { Choices = { Leccion = "Perdon" } }, Beat = "Baja", Shot = "PrimerPlano:TuMalvado" },
				{ S = "TuMalvado", T = "…Uf. Qué difícil. Me tiemblan las piernas.", If = { Choices = { Leccion = "Perdon" } }, A = "Nervous" },
				{ S = "TuMalvado", T = "Gracias. …Gracias por no dejarme en el suelo del garaje, sin perilla.", If = { Choices = { Leccion = "Gracias" } }, Beat = "Respira", Shot = "PrimerPlano:TuMalvado" },
				{ S = "TuMalvado", T = "Ya está. Lo he dicho. No se lo cuentes a nadie de la 66-B.", If = { Choices = { Leccion = "Gracias" } }, A = "Ashamed" },
				{ S = "TuMalvado", T = "¿Algo bueno sin que nadie me vea? ¿Y entonces para qué…?", If = { Choices = { Leccion = "Nadie" } }, A = "Ask" },
				{ S = "TuMalvado", T = "…Ah. Ya. Es para mí. Qué cosa más rara. Me gusta.", If = { Choices = { Leccion = "Nadie" } }, Pause = 0.8, A = "Happy" },
				{ S = "TuMalvado", T = "Y te voy a decir otra cosa. Cósimo nos robó la cara. La tuya y la mía.", Beat = "Respira", A = "Angry" },
				{ S = "TuMalvado", T = "Dijo que me daría tu vida y me dejó con deudas. Cuando llegue la batalla, voy. Contra él. Por los dos.", IfNot = { Flags = { "FusionDetenida" } }, To = "Yo" },
				{ S = "TuMalvado", T = "Dijo que me daría tu vida y me dejó con deudas. Me alegro de que le ganaras. Por los dos.", If = { Flags = { "FusionDetenida" } }, To = "Yo" },
				{ S = "TuMalvado", T = "Toma. Me he hecho un diploma. «Aprobado en bondad». Tiene faltas de ortografía.", G = "Point" },
				{ S = "TuMalvado", T = "Es a propósito. Un poco de maldad hay que conservarla.", Beat = "Sonrie" },
				{ S = "Narrador", T = "Recibes 🎖️ el Diploma de bondad (con faltas)." },
			} },
		},
	},
}
