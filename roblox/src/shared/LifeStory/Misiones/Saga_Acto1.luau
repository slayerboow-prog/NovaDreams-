-- SAGA DE LA GRIETA · ACTO I «La Grieta» (infancia). Misiones CANÓNICAS: siempre en el mapa hasta hacerlas.
-- Plan completo y reglas de coherencia: docs/historia/13-saga-de-la-grieta.md
--
--   1 Loco_N1_Cosme      «El vecino del garaje»       (en Loco_Nino.luau) el microondas temporal… y una línea verde en el cielo
--   2 Saga_02_Grieta     «La grieta en el cielo»      cosas que caen del cielo; una moneda con la cara de Cosme… con perilla
--   3 Saga_03_Pez        «El pez que sabía demasiado»  Don Escamas, los agentes grises del Consorcio y la palabra «Ancla»
--   4 Saga_04_Ventanilla «La ventanilla 42»           la Aduana del Tiempo multa la Grieta: burocracia cósmica
--   5 Saga_05_Perdidas   «La noche de las cosas perdidas»  lo perdido de Valmar cae en el gimnasio; el Monstruo de los Calcetines
--   6 Saga_06_Coser      «Coser el cielo»             final del acto: la aguja cuántica… y una voz: «Ya te he visto, Ancla»

local V = Vector3.new

local function after(id: string): { [string]: any }
	return { Stage = { Min = "Nino" }, Completed = { id } }
end

local COSME = { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) }
local PIP = { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) }

return {
	---------------------------------------------------------------------
	-- 2 · La grieta en el cielo
	---------------------------------------------------------------------
	{
		Id = "Saga_02_Grieta",
		Kind = "Side",
		Canon = true,
		Title = "La grieta en el cielo",
		Description = "La línea verde del cielo ha crecido. Esta noche han caído cosas. Cosas que no son de aquí.",
		Type = "Saga de la Grieta · Acto I (2/6)",
		Duration = { 25, 35 },
		Npcs = { "Cosme", "Pip", "Bigotes", "Nico" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme te espera en el garaje con un aparato que pita mucho",
		Requires = after("Loco_N1_Cosme"),
		Moment = "Viste la Grieta por primera vez",
		Memory = "GrietaEnElCielo",
		Rewards = { Items = { MonedaPerilla = 1 }, Flags = { "SabeDeCosimo" } },
		Props = {
			Calcetin = { Kind = "Moco", Name = "Un calcetín que brilla… y habla", Prompt = "Coger el calcetín", Place = "FuenteParque", Offset = V(-3, 0, 3), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Calcetin", Once = true },
			Paraguas = { Kind = "Cristal", Name = "Un paraguas que llueve hacia arriba", Prompt = "Cerrar el paraguas", Place = "JuegosColegio", Offset = V(3, 0, 3), Color = Color3.fromRGB(150, 200, 255), Dialogue = "Paraguas", Once = true },
			Moneda = { Kind = "Pegatina", Name = "Una moneda caliente", Prompt = "Recoger la moneda", Place = "CaminoAlCole", Offset = V(2, 0, 2), Color = Color3.fromRGB(255, 200, 60), Dialogue = "Moneda", Once = true },
			Medidor = { Kind = "Maquina", Name = "El medidor de rarezas", Place = "GarajeCosme", Offset = V(-3, 0, 0), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Medidor", Text = "Cosme quiere enseñarte su medidor de rarezas",
				Actors = { COSME, PIP }, Props = { "Medidor" } },
			{ Type = "Group", Text = "El medidor pita en tres sitios. Recoge lo que ha caído de la Grieta",
				Actors = { { Npc = "Pip", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Calcetin", Text = "Algo brilla junto a la fuente del parque" },
					{ Type = "Use", Prop = "Paraguas", Text = "Algo raro en la zona de juegos del cole" },
					{ Type = "Use", Prop = "Moneda", Text = "Algo quema en el camino al cole" },
				} },
			{ Type = "Talk", Npc = "Bigotes", Dialogue = "Bigotes", Text = "Bigotes te espera en el tejado del cole… bueno, en el patio",
				Actors = { { Npc = "Bigotes", Place = "Patio", Offset = V(2, 0, 3), Scale = 0.35 } } },
			{ Type = "Reach", Place = "GarajeCosme", Text = "Lleva los restos al garaje de Cosme", Actors = { COSME, PIP }, Props = { "Medidor" } },
			{ Type = "Scene", Dialogue = "Perilla", Actors = { COSME, PIP }, Props = { "Medidor" } },
		},
		Dialogues = {
			Medidor = { Lines = {
				{ S = "Cosme", T = "¿Viste la línea verde del cielo? Ha crecido. Tres centímetros. En el cielo, tres centímetros son MUCHOS kilómetros." },
				{ S = "Cosme", T = "Esto es un medidor de rarezas. Pita cuando algo no es de esta dimensión. Esta mañana ha pitado tanto que Pip se ha desmayado." },
				{ S = "Pip", T = "No me he desmayado. Me he reiniciado con elegancia." },
				{ S = "Cosme", T = "Esta noche han caído cosas de la grieta. Hay que recogerlas antes de que las encuentre alguien. O algo. Pip va contigo. Yo me quedo… calculando. Y un poco escondido." },
			} },
			Calcetin = { Lines = {
				{ S = "Narrador", T = "Un calcetín verde. Cuando lo coges, dice con vocecita: «¿Has visto a mi pareja? Es igual que yo, pero del pie izquierdo»." },
				{ S = "Pip", T = "Calcetín de otra dimensión. Allí los calcetines hablan. Y se pierden igual. Algunas cosas son universales." },
			} },
			Paraguas = { Lines = {
				{ S = "Narrador", T = "Un paraguas abierto. Debajo, la lluvia cae hacia ARRIBA. Tres niños de primero lo miran con la boca abierta. Lo cierras. Los niños aplauden." },
			} },
			Moneda = { Lines = {
				{ S = "Narrador", T = "Una moneda caliente, como recién salida de un horno. En una cara pone «66-B». En la otra hay una cara. Es la cara de Cosme." },
				{ S = "Narrador", T = "…Pero con perilla. Y una sonrisa que no es la de Cosme. Una sonrisa de anuncio de la tele." },
				{ S = "Pip", T = "…Oh, no. Oh, no, no, no. Mejor que esto lo vea el señor Cosme. Mejor que no lo vea. Mejor que lo vea. Tengo un conflicto de programación." },
			} },
			Bigotes = { Lines = {
				{ S = "Bigotes", T = "Cría humana. Deja de hacer como que no me oyes hablar. Tengo información imperial.", If = { Flags = { "BigotesHabla" } } },
				{ S = "Bigotes", T = "Miau. …Vale. Sé que sabes que hablamos. Escucha.", If = { NotFlags = { "BigotesHabla" } } },
				{ S = "Bigotes", T = "Esa grieta del cielo ya la vi una vez. En Gatonia la llamamos «La Puerta Mal Cerrada». Por ahí entran los problemas. Las cucarachas. Los cobradores. Los que venden cosas." },
				{ S = "Bigotes", T = "Y esta noche he oído algo al otro lado. Una voz de hombre. Muy elegante. Decía tu nombre, humano. Varias veces. Como quien cuenta monedas." },
			} },
			Perilla = { Lines = {
				{ S = "Cosme", T = "Un calcetín parlante, un paraguas al revés… normal. Todo normal. Ciencia. ¿Qué más traes? ¿Una moneda? A ver…" },
				{ S = "Narrador", T = "Cosme mira la moneda. Se queda muy quieto. Se le cae el batido de apio. Pip lo recoge antes de que toque el suelo." },
				{ S = "Cosme", T = "…Cósimo." },
				{ S = "Yo", T = "¿Quién es Cósimo?" },
				{ S = "Cosme", T = "Nadie. Un viejo… conocido. Un socio. Hace años. Muchos años. Tantos como tú tienes, más o menos. No importa. No importa nada. Ciencia. Vete a cenar, criatura.", A = "Sad" },
				{ S = "Pip", T = "(En voz baja, mientras te acompaña a la puerta) El señor Cosme no ha dormido desde que vio la línea del cielo. Cuide de él. Él lleva mucho tiempo cuidando de usted. Aunque usted no lo sepa." },
				{ S = "Narrador", T = "Te quedas la moneda. Cosme no quiere tenerla cerca. Recibes 🪙 la Moneda de la 66-B." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 3 · El pez que sabía demasiado
	---------------------------------------------------------------------
	{
		Id = "Saga_03_Pez",
		Kind = "Side",
		Canon = true,
		Title = "El pez que sabía demasiado",
		Description = "En el estanque del parque hay un pez naranja que respira aire, lleva corbata y pide auxilio con mucha educación.",
		Type = "Saga de la Grieta · Acto I (3/6)",
		Duration = { 25, 35 },
		Npcs = { "DonEscamas", "AgenteGris1", "AgenteGris2", "Cosme", "Pip" },
		Offer = { Place = "EstanqueParque" },
		OfferKey = "¡Psst! ¡Aquí! ¡En el estanque! ¡Un pez te está llamando!",
		Requires = after("Saga_02_Grieta"),
		Moment = "Rescataste a Don Escamas del Consorcio",
		Memory = "DonEscamas",
		Rewards = { Items = { EscamaBrillante = 1 }, Flags = { "ConoceConsorcio", "OyoAncla" } },
		Props = {
			Cubo = { Kind = "Papelera", Name = "Un cubo del parque", Prompt = "Coger el cubo", Place = "EstanqueParque", Offset = V(-4, 0, 2), Dialogue = "Cubo", Once = true },
			Tarjeta = { Kind = "Papel", Name = "Una tarjeta de visita gris", Prompt = "Leer la tarjeta", Place = "EstanqueParque", Offset = V(4, 0, 4), Dialogue = "Tarjeta", Once = true },
			Pecera = { Kind = "Caja", Name = "La pecera nueva de Cosme", Place = "GarajeCosme", Offset = V(-3, 0, 0), Color = Color3.fromRGB(120, 200, 255), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "DonEscamas", Dialogue = "Auxilio", Text = "Habla con el pez del estanque",
				Actors = { { Npc = "DonEscamas", Place = "EstanqueParque", Offset = V(0, 0, 3), Scale = 0.35 } } },
			{ Type = "Group", Text = "Prepara la huida de Don Escamas",
				Actors = { { Npc = "DonEscamas", Place = "EstanqueParque", Offset = V(0, 0, 3), Scale = 0.35 } },
				Steps = {
					{ Type = "Use", Prop = "Cubo", Text = "Un cubo para llevarle" },
					{ Type = "Use", Prop = "Tarjeta", Text = "Mira qué se les ha caído a los que le buscan" },
				} },
			{ Type = "Escape", Place = "GarajeCosme", Respawn = "EstanqueParque", Catch = 4,
				Text = "¡Los agentes grises! Lleva a Don Escamas al garaje de Cosme sin que te atrapen",
				CaughtLine = "¡Qué oferta tan irresistible! …Digo: ¡alto! (Te quitan el cubo, se les cae, lo recuperas en el estanque.)",
				Actors = {
					{ Npc = "DonEscamas", Mode = "Follow", Scale = 0.35 },
					{ Npc = "AgenteGris1", Place = "Parque", Offset = V(-12, 0, 6), Mode = "Hunt", Speed = 11, Prompt = false },
					{ Npc = "AgenteGris2", Place = "Parque", Offset = V(12, 0, 6), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Pecera", Props = { "Pecera" },
				Actors = { COSME, PIP, { Npc = "DonEscamas", Place = "GarajeCosme", Offset = V(-3, 0, 1), Scale = 0.35 } } },
		},
		Dialogues = {
			Auxilio = { Lines = {
				{ S = "DonEscamas", T = "¡Gracias a Neptuno! Un humano con cara de buena persona. Me presento: Don Escamas. Contable. Pez. Refugiado dimensional." },
				{ S = "DonEscamas", T = "Me colé por esa grieta del cielo huyendo de mi antiguo jefe: el Consorcio MegaVerso Sociedad Anónima. Venden vacaciones a otras dimensiones. Y cosas peores. Mucho peores." },
				{ S = "DonEscamas", T = "Yo llevaba sus cuentas. Vi cosas en las cuentas. Cosas que un pez no debería ver. Y ahora me buscan dos agentes de gris. Con gafas de sol. De noche. Eso nunca es buena señal." },
				{ Ask = "¿Qué haces?", Options = {
					{ T = "«Te saco de aquí. Conozco a alguien.»", Effects = { Traits = { Valentia = 1 }, Rel = { DonEscamas = 8 } }, Then = {
						{ S = "DonEscamas", T = "¡Un humano con contactos! Esto es lo que yo llamo un activo." },
					} },
					{ T = "«¿Qué viste en las cuentas?»", Effects = { Traits = { Curiosidad = 2 } }, Then = {
						{ S = "DonEscamas", T = "Un pedido enorme. «Proyecto Fusión». Firmado por un tal doctor… no, aquí no. Las paredes tienen oídos. Y los árboles tienen agentes." },
					} },
				} },
			} },
			Cubo = { Lines = {
				{ S = "Narrador", T = "Un cubo con agua del estanque. Don Escamas salta dentro con un «¡hop!» muy digno y se ajusta la corbata." },
			} },
			Tarjeta = { Lines = {
				{ S = "Narrador", T = "Una tarjeta gris: «MegaVerso S.A. — Tu vida, en mil dimensiones. Delegación Valmar: PRÓXIMAMENTE». Por detrás, escrito a mano: «Localizar al Ancla»." },
				{ S = "Narrador", T = "Dos hombres de traje gris aparecen entre los árboles. Sonríen a la vez. Exactamente a la vez." },
				{ S = "AgenteGris1", T = "{Saludo}. ¿Ha visto usted un pez? Contable. Traidor. Con corbata. Hay recompensa: un fin de semana en la dimensión de los helados." },
			} },
			Pecera = { Lines = {
				{ S = "Cosme", T = "¿Un pez? ¿En mi garaje? ¿Contable? Siempre he querido un contable. Pip, la pecera buena. La que no explota." },
				{ S = "DonEscamas", T = "Doctor Cosme. Por fin. En el Consorcio su nombre sale mucho. Bueno, el de su socio. El de la perilla." },
				{ S = "Cosme", T = "…No sé de qué me habla. Pez." },
				{ S = "DonEscamas", T = "Su socio, Cósimo, está en la dimensión 66-B. El Consorcio le paga el laboratorio. Y le buscan algo aquí: el Ancla. Por eso la grieta no se abre del todo. Por el Ancla." },
				{ S = "Yo", T = "¿Qué es el Ancla?" },
				{ S = "DonEscamas", T = "…Uy. He hablado de más. Es un tic de contable: lo cuento todo. Me callo. Me callo muy fuerte. Glu." },
				{ S = "Narrador", T = "Cosme y Pip se miran. No te miran a ti. Te miran mucho, pero sin mirarte." },
				{ S = "Cosme", T = "Nadie ha dicho nada de anclas. Ni de barcos. El pez se queda aquí. Tú vete a casa. Y, criatura… si ves a alguien de gris, corre. Siempre." },
				{ S = "Narrador", T = "Antes de irte, Don Escamas te da una escama que brilla. «Por si necesitas un contable. O un amigo. Soy las dos cosas.» Recibes ✨ una Escama brillante." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 4 · La ventanilla 42
	---------------------------------------------------------------------
	{
		Id = "Saga_04_Ventanilla",
		Kind = "Side",
		Canon = true,
		Title = "La ventanilla 42",
		Description = "La Aduana del Tiempo ha multado a Cosme por tener «una grieta dimensional sin licencia». Para pagarla hay que rellenar un formulario. En tres ventanillas.",
		Type = "Saga de la Grieta · Acto I (4/6)",
		Duration = { 25, 35 },
		Npcs = { "CazadorTiempo", "Funcionaria", "Ines", "Cosme" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Hay un señor con traje y cuarenta formularios en la puerta del garaje de Cosme",
		Requires = after("Saga_03_Pez"),
		Moment = "Sobreviviste a la burocracia del tiempo",
		Memory = "VentanillaAduana",
		Rewards = { Items = { SelloAduana = 1 }, Flags = { "CronosTeConoce" } },
		Steps = {
			{ Type = "Talk", Npc = "CazadorTiempo", Dialogue = "Multa", Text = "Habla con el señor de los formularios",
				Actors = { COSME, { Npc = "CazadorTiempo", Place = "GarajeCosme", Offset = V(-3, 0, 4) } } },
			{ Type = "Talk", Npc = "Funcionaria", Dialogue = "Ventanilla1", Text = "Ventanilla 1: Correos",
				Actors = { { Npc = "Funcionaria", Place = "Correos", Offset = V(0, 0, 3) } } },
			{ Type = "Talk", Npc = "Funcionaria", Dialogue = "Ventanilla2", Text = "Ventanilla 2: el banco (la misma señora… ¿cómo ha llegado antes que tú?)",
				Actors = { { Npc = "Funcionaria", Place = "Banco", Offset = V(0, 0, 3) } } },
			{ Type = "Talk", Npc = "Ines", Dialogue = "Ventanilla3", Text = "Ventanilla 3: la comisaría (necesitas un sello de la policía)",
				Actors = { { Npc = "Ines", Place = "Policia", Offset = V(0, 0, 4) }, { Npc = "Funcionaria", Place = "Policia", Offset = V(4, 0, 4) } } },
			{ Type = "Talk", Npc = "CazadorTiempo", Dialogue = "Sello", Text = "Vuelve al garaje con el formulario sellado",
				Actors = { COSME, { Npc = "CazadorTiempo", Place = "GarajeCosme", Offset = V(-3, 0, 4) } } },
		},
		Dialogues = {
			Multa = { Lines = {
				{ S = "CazadorTiempo", T = "Agente Cronos, Aduana del Tiempo. El señor Cosme tiene en su barrio una grieta dimensional sin licencia. Multa. Formulario 42. Tres ventanillas." },
				{ S = "Cosme", T = "¡Esa grieta no es mía! Bueno. Es un poco mía. Un cincuenta por ciento. El otro cincuenta es de un señor con perilla que no está." },
				{ S = "CazadorTiempo", T = "Ya. Todos dicen que la grieta es del de la perilla. Formulario 42. El pequeño humano puede hacer el trámite; el señor Cosme tiene prohibidas las ventanillas desde 1994." },
				{ S = "Cosme", T = "¡Fue un accidente! ¡La ventanilla estaba así cuando llegué! …Ve tú, criatura. Y no discutas con nadie que lleve un sello. Nunca." },
			} },
			Ventanilla1 = { Lines = {
				{ S = "Funcionaria", T = "Formulario 42. Muy bien. Le falta la fotocopia del formulario 42." },
				{ S = "Yo", T = "¿Una fotocopia… del mismo formulario?" },
				{ S = "Funcionaria", T = "Claro. ¿Cómo voy a saber que es el formulario 42 si no tengo una copia del formulario 42? Hágala en el banco. Ventanilla 2." },
			} },
			Ventanilla2 = { Lines = {
				{ S = "Funcionaria", T = "{Saludo}. Formulario 42 con fotocopia. Muy bien. ¿Y el sello de la policía que certifica que la fotocopia es una fotocopia?" },
				{ S = "Yo", T = "¿Usted no estaba en Correos?" },
				{ S = "Funcionaria", T = "Yo estoy en todas las ventanillas. Es mi trabajo. Nadie sabe cómo. Ni yo. Comisaría. Ventanilla 3. Y no se le olvide sonreír en la foto." },
			} },
			Ventanilla3 = { Lines = {
				{ S = "Ines", T = "¿Un sello para certificar que una fotocopia es una fotocopia de un formulario del tiempo? …Llevo veinte años de policía y hoy es el día más raro." },
				{ Ask = "¿Cómo la convences?", Options = {
					{ T = "«Por favor. Es para que no multen a mi vecino.»", Effects = { Traits = { Empatia = 1 }, Rel = { Ines = 4 } }, Then = {
						{ S = "Ines", T = "¿El de las explosiones verdes? …Vale. Toma. Sello. Y dile que la próxima vez avise antes de explotar." },
					} },
					{ T = "«Si no me lo pone, la señora de la ventanilla vendrá aquí.»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Funcionaria", T = "(Desde detrás de Inés, sin que nadie la haya visto llegar) Ya estoy aquí." },
						{ S = "Ines", T = "¡AH! ¡Toma el sello! ¡Toma diez sellos! ¡Fuera todos de mi comisaría!" },
					} },
				} },
			} },
			Sello = { Lines = {
				{ S = "CazadorTiempo", T = "Formulario 42, fotocopia, sello de la fotocopia. Perfecto. En cuatrocientos años, nadie lo había conseguido en el mismo día. Me ha impresionado." },
				{ S = "CazadorTiempo", T = "Le daré un consejo, pequeño humano, gratis, que en la Aduana es rarísimo. Esa grieta no es un accidente. Alguien del otro lado tira de ella. Tira fuerte. Hacia usted." },
				{ S = "CazadorTiempo", T = "Por qué hacia usted, no lo sé. No tengo el formulario de eso. Pero volveremos a vernos. Muchas veces. Lo pone en mi agenda. Mi agenda es del futuro." },
				{ S = "Cosme", T = "…Gracias, criatura. De verdad. Nunca nadie había hecho un trámite por mí. Es lo más bonito que me han hecho desde que Pip me planchó los calcetines." },
				{ S = "Narrador", T = "Recibes 📄 el Sello de la Aduana del Tiempo. Cronos te lo regala: «Uno de repuesto. Nunca se sabe cuándo hay que sellar algo»." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 5 · La noche de las cosas perdidas
	---------------------------------------------------------------------
	{
		Id = "Saga_05_Perdidas",
		Kind = "Side",
		Canon = true,
		Title = "La noche de las cosas perdidas",
		Description = "Esta noche la Grieta ha absorbido todo lo que se ha perdido alguna vez en Valmar. Y lo ha escupido en el gimnasio del cole.",
		Type = "Saga de la Grieta · Acto I (5/6)",
		Duration = { 25, 35 },
		Npcs = { "Ramon", "Lucia", "Nico", "CalcetinMonstruo", "Pip" },
		Offer = { Place = "EntradaColegio" },
		OfferKey = "El gimnasio del cole está lleno hasta el techo de cosas perdidas. Ramón, el conserje, no da crédito",
		-- «Esta noche»: pasa de noche, con el cole cerrado (Ramón os abre), no en horario de clase
		Requires = (function()
			local req = after("Saga_04_Ventanilla")
			req.Hours = { From = 19, To = 6 }
			return req
		end)(),
		Schedule = false,
		Moment = "Devolviste las cosas perdidas de Valmar",
		Memory = "CosasPerdidas",
		Rewards = { Items = { CalcetinSolitario = 1 }, Flags = { "VecinosNotanRarezas" } },
		Props = {
			Llaves = { Kind = "Llavero", Name = "Un manojo de llaves antiguo", Prompt = "Coger las llaves", Place = "GimnasioColegio", Offset = V(-4, 0, 3), Dialogue = "Llaves", Once = true },
			Balon = { Kind = "Balon", Name = "Un balón firmado", Prompt = "Coger el balón", Place = "GimnasioColegio", Offset = V(4, 0, 3), Color = Color3.fromRGB(250, 250, 250), Dialogue = "Balon", Once = true },
			Diario = { Kind = "Libro", Name = "Un diario con candado", Prompt = "Coger el diario", Place = "GimnasioColegio", Offset = V(0, 0, 6), Color = Color3.fromRGB(240, 196, 60), Dialogue = "Diario", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Ramon", Dialogue = "Ramon", Text = "Habla con Ramón en la entrada del cole",
				Actors = { { Npc = "Ramon", Place = "EntradaColegio", Offset = V(0, 0, 4) }, { Npc = "Pip", Place = "EntradaColegio", Offset = V(4, 0, 5) } } },
			{ Type = "Group", Text = "Encuentra en el gimnasio las cosas más importantes y devuélvelas",
				Actors = { { Npc = "Pip", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Llaves", Text = "Unas llaves muy viejas" },
					{ Type = "Use", Prop = "Balon", Text = "Un balón firmado" },
					{ Type = "Use", Prop = "Diario", Text = "Un diario amarillo" },
				} },
			{ Type = "Group", Text = "Devuelve cada cosa a su dueño",
				Actors = {
					{ Npc = "Ramon", Place = "EntradaColegio", Offset = V(0, 0, 4) },
					{ Npc = "Nico", Place = "Patio", Offset = V(-3, 0, 3) },
					{ Npc = "Lucia", Place = "Patio", Offset = V(3, 0, 3) },
				},
				Steps = {
					{ Type = "Talk", Npc = "Ramon", Dialogue = "DevolverLlaves", Text = "Las llaves, a Ramón" },
					{ Type = "Talk", Npc = "Nico", Dialogue = "DevolverBalon", Text = "El balón, a Nico" },
					{ Type = "Talk", Npc = "Lucia", Dialogue = "DevolverDiario", Text = "El diario, a Lucía" },
				} },
			{ Type = "Fight", Place = "GimnasioColegio", Respawn = "EntradaColegio", Action = "Emparejar calcetines 🧦", HP = 8, BeamColor = Color3.fromRGB(255, 120, 200),
				Text = "¡Del montón sale el Monstruo de los Calcetines Desparejados! Empareja sus calcetines",
				CaughtLine = "¡ABRAZO DE CALCETÍN! (Hueles a pie durante una semana. Vuelves a la entrada.)",
				Actors = { { Npc = "Pip", Place = "GimnasioColegio", Offset = V(6, 0, 6), Mode = "Cheer" } },
				Enemies = {
					{ Npc = "CalcetinMonstruo", Offset = V(0, 0, -6), Speed = 10, HP = 8, Scale = 1.6,
						Hurt = "¡Ese es de rayas! ¡Yo busco uno de lunares! …¡Pero qué bien quedan juntos!",
						Bye = "¡Por fin tengo pareja! ¡Tengo MUCHAS parejas! (Se deshace en cientos de pares de calcetines, felices, que salen volando por la ventana.)" },
				} },
			{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Pip", Place = "GimnasioColegio", Offset = V(3, 0, 3) } } },
		},
		Dialogues = {
			Ramon = { Lines = {
				{ S = "Ramon", T = "Treinta años de conserje. Treinta. He visto de todo. Pero esto… El gimnasio está lleno de cosas perdidas. De todo Valmar. De todas las épocas." },
				{ S = "Ramon", T = "Hay un bolso de 1950. Una dentadura de 1972. Y un pato de goma que no deja de mirarme." },
				{ S = "Pip", T = "La Grieta absorbe todo lo que se pierde y lo devuelve donde le da la gana. El señor Cosme dice que es «un fallo de la papelera cósmica». Sugiere devolver lo importante primero." },
			} },
			Llaves = { Lines = {
				{ S = "Narrador", T = "Un manojo de llaves oxidadas con una etiqueta: «Conserjería, 1994». Ramón las lleva buscando treinta años. Siempre dijo que las tenía «en algún sitio»." },
			} },
			Balon = { Lines = {
				{ S = "Narrador", T = "Un balón firmado por todo un equipo de fútbol. Con rotulador infantil, pone: «De Nico. NO TOCAR». Es el que perdió en el torneo." },
			} },
			Diario = { Lines = {
				{ S = "Narrador", T = "Un diario amarillo con candado. En la portada: «Lucía, 3.º B, 1998. PRIVADO. Si lo lees, eres un cotilla»." },
				{ Ask = "¿Lo abres?", Options = {
					{ T = "No. Es de Lucía.", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Lucia = 3 } } },
					{ T = "Solo la primera página…", Effects = { Traits = { Curiosidad = 1 } }, Then = {
						{ S = "Narrador", T = "Primera página: «Hoy he decidido que de mayor seré profe. Y que no le leeré el diario a nadie. Ni a los cotillas». …Cierras el diario muy despacio." },
					} },
				} },
			} },
			DevolverLlaves = { Lines = {
				{ S = "Ramon", T = "¡Mis llaves de 1994! ¡Con estas se abre la sala del reloj! Nadie ha entrado ahí desde entonces. …Otro día te cuento. O no. Gracias, de verdad." },
			} },
			DevolverBalon = { Lines = {
				{ S = "Nico", T = "¡MI BALÓN! ¡El del torneo! ¡Lo busqué por todas partes! ¿Dónde estaba? ¿En el cielo? …¿Cómo que en el cielo?" },
			} },
			DevolverDiario = { Lines = {
				{ S = "Lucia", T = "Mi diario… de cuando tenía tu edad. Lo perdí en una excursión. ¿Lo has leído?" },
				{ S = "Lucia", T = "No me contestes. Tu cara ya me ha contestado. …Gracias. De verdad. Hay cosas que perdemos y no sabemos que las echábamos de menos." },
				{ S = "Narrador", T = "Del gimnasio sale un ruido enorme. Como si mil pies arrastraran calcetines a la vez." },
			} },
			Final = { Lines = {
				{ S = "Pip", T = "Monstruo emparejado. El señor Cosme estará orgulloso. Bueno, dirá que es lo mínimo. Pero estará orgulloso." },
				{ S = "Pip", T = "Hay un problema: esta vez lo ha visto todo el barrio. Ramón, Lucía, Nico. Los vecinos hablan. Y la Grieta crece. El señor Cosme dice que hay que coserla. Ya." },
				{ S = "Narrador", T = "En el suelo queda un único calcetín. Verde. Sin pareja. Te mira. Te lo quedas. Recibes 🧦 el Calcetín solitario." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 6 · Coser el cielo (final del Acto I)
	---------------------------------------------------------------------
	{
		Id = "Saga_06_Coser",
		Kind = "Side",
		Canon = true,
		Title = "Coser el cielo",
		Description = "Cosme ha terminado la aguja cuántica. Esta noche se cose la Grieta. Hacen falta tres anclajes, un pulso firme y alguien muy valiente.",
		Type = "Saga de la Grieta · Acto I (6/6) · Final del acto",
		Duration = { 30, 40 },
		Npcs = { "Cosme", "Pip", "DonEscamas", "AgenteGris1", "AgenteGris2", "Cosimo" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Esta noche se cose el cielo. Cosme te espera",
		Requires = { Stage = { Min = "Nino" }, Completed = { "Saga_05_Perdidas" }, Hours = { From = 19, To = 6 } },
		-- De noche en el patio del cole: sin el horario del cole (si no, nunca podría empezar: pide la
		-- noche y el cole cierra a las 17:00)
		Schedule = false,
		Moment = "Cosiste el cielo de Valmar (por ahora)",
		Memory = "CoserElCielo",
		Rewards = { Items = { AgujaCuantica = 1 }, Flags = { "SagaActo1", "CosimoTeHaVisto" } },
		Props = {
			Anclaje1 = { Kind = "Cristal", Name = "Anclaje del parque", Prompt = "Clavar el anclaje", Place = "Parque", Offset = V(0, 0, 8), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Anclaje", Once = true },
			Anclaje2 = { Kind = "Cristal", Name = "Anclaje del cole", Prompt = "Clavar el anclaje", Place = "Patio", Offset = V(0, 0, 8), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Anclaje", Once = true },
			Anclaje3 = { Kind = "Cristal", Name = "Anclaje de la plaza", Prompt = "Clavar el anclaje", Place = "PlazaCentro", Offset = V(0, 0, 8), Color = Color3.fromRGB(120, 255, 160), Dialogue = "Anclaje", Once = true },
			Aguja = { Kind = "Cohete", Name = "La aguja cuántica", Place = "Patio", Offset = V(0, 0, -6), Color = Color3.fromRGB(200, 255, 220), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Plan", Text = "Cosme te explica el plan", Actors = { COSME, PIP } },
			{ Type = "Group", Text = "Clava los tres anclajes (cuidado: el Consorcio vigila)",
				Actors = {
					{ Npc = "AgenteGris1", Place = "Parque", Offset = V(-10, 0, 10), Mode = "Wander", Prompt = false },
					{ Npc = "AgenteGris2", Place = "PlazaCentro", Offset = V(10, 0, 10), Mode = "Wander", Prompt = false },
				},
				Steps = {
					{ Type = "Use", Prop = "Anclaje1", Text = "Anclaje del parque" },
					{ Type = "Use", Prop = "Anclaje2", Text = "Anclaje del patio del cole" },
					{ Type = "Use", Prop = "Anclaje3", Text = "Anclaje de la plaza del centro" },
				} },
			{ Type = "Fight", Place = "Patio", Respawn = "Patio", Action = "Apagarle el comunicador 📡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160), Props = { "Aguja" },
				Text = "¡Los agentes grises quieren robar la aguja! Apágales el comunicador ({count}/{total})",
				CaughtLine = "¡Oferta exclusiva! ¡Firme aquí! (Consigues no firmar. Vuelves junto a la aguja.)",
				Actors = { { Npc = "Cosme", Place = "Patio", Offset = V(4, 0, -3) }, { Npc = "Pip", Place = "Patio", Offset = V(6, 0, -1) } },
				Enemies = {
					{ Npc = "AgenteGris1", Offset = V(-10, 0, 6), Speed = 12, Hurt = "¡Esto no está en nuestro plan de negocio!", Bye = "¡Nos vamos! ¡Pero el Consorcio siempre vuelve! ¡Es nuestro eslogan! (Chispas grises. Fuera.)" },
					{ Npc = "AgenteGris2", Offset = V(10, 0, 6), Speed = 12, Hurt = "¡Mi comunicador de edición limitada!", Bye = "¡Hablaremos con su superior! (No tienes superior. Se van igual.)" },
				} },
			{ Type = "Cinematic", Id = "Saga_Coser", Props = { "Aguja" } },
			{ Type = "Scene", Dialogue = "Voz", Props = { "Aguja" },
				Actors = { { Npc = "Cosme", Place = "Patio", Offset = V(4, 0, -3) }, { Npc = "Pip", Place = "Patio", Offset = V(6, 0, -1) } } },
		},
		Dialogues = {
			Plan = { Lines = {
				{ S = "Cosme", T = "La aguja cuántica. Mi obra maestra. Bueno, la tercera: la primera fue el microondas y la segunda, un peine que peina hacia el pasado. No preguntes." },
				{ S = "Cosme", T = "Plan: tres anclajes en tres sitios de Valmar. Forman un triángulo. La aguja, en el centro, cose la grieta. Como un botón. Un botón del tamaño del cielo." },
				{ S = "DonEscamas", T = "(Desde la pecera) Y el Consorcio lo sabe. Mis antiguos compañeros vigilan el parque y la plaza. Yo les he calculado la ruta: si no te ven, no te ven. Es contabilidad básica." },
				{ Ask = "Antes de salir, le preguntas a Cosme:", Options = {
					{ T = "«¿Quién es Cósimo de verdad?»", Effects = { Traits = { Curiosidad = 1 } }, Then = {
						{ S = "Cosme", T = "Mi mejor amigo. Hace mucho. Construimos juntos la máquina que abrió esto. Una noche salió mal y él… se cayó. Al otro lado. Por mi culpa. O por la suya. Llevo años sin saberlo.", A = "Sad" },
					} },
					{ T = "«¿Por qué la Grieta tira hacia mí?»", Effects = { Traits = { Valentia = 1 } }, Then = {
						{ S = "Cosme", T = "…Porque eres importante. Para mí, desde luego. Para el universo, un poquito también. Te lo contaré cuando seas mayor. Te lo juro por mi batido." },
					} },
				} },
			} },
			Anclaje = { Lines = {
				{ S = "Narrador", T = "Clavas el cristal en el suelo. Suena como una campana muy lejos. En el cielo, la línea verde tiembla." },
			} },
			Voz = { Lines = {
				{ S = "Narrador", T = "La aguja sube como un cohete y cose el cielo, punto a punto, con hilo de luz. La grieta se cierra. Valmar entera se queda a oscuras un segundo… y vuelve la luz." },
				{ S = "Cosme", T = "¡LO HEMOS HECHO! ¡Cosido! ¡Como un calcetín! ¡Soy un genio! ¡Somos unos genios! ¡Tú eres un genio en miniatura, yo uno grande!" },
				{ S = "Narrador", T = "Entonces, del último punto de la costura sale una voz. Elegante. Tranquila. Como un presentador de concursos a medianoche." },
				{ S = "Cosimo", T = "Bravo, Cosme. Precioso trabajo de costura. Siempre fuiste el de las manualidades." },
				{ S = "Cosimo", T = "Y tú… hola. Por fin te veo la cara. Qué grande estás. La última vez eras así de chiquitín o chiquitina. Ya te he visto, Ancla. Nos veremos pronto. Las costuras… siempre se sueltan." },
				{ S = "Narrador", T = "Silencio. La costura brilla un momento y se apaga. Cosme está blanco como su bata." },
				{ S = "Pip", T = "Señor. Tiene que contárselo. Algún día." },
				{ S = "Cosme", T = "Algún día, Pip. No hoy. Hoy hemos cosido el cielo. Hoy… a cenar. Criatura: te quedas la aguja. Tú la has hecho funcionar. Siempre has sido tú." },
				{ S = "Narrador", T = "Recibes 🪡 la Aguja cuántica. FIN DEL ACTO I. La Grieta está cosida… por ahora." },
			} },
		},
	},
}
