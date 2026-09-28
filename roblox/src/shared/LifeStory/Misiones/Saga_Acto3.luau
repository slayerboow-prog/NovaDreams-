-- SAGA DE LA GRIETA · ACTO III «El Multiverso» (universidad). Misiones CANÓNICAS: siempre en el mapa.
-- Con Iván y Candela, tus compañeros de cuarto, como equipo de rescate. Plan: docs/historia/13-saga-de-la-grieta.md
--
--   13 Saga_13_SinCosme   «Sin Cosme»              el garaje vacío, el cuaderno de coordenadas y tu equipo
--   14 Saga_14_Bigotes    «El presidente Bigotes»  la dimensión de los gatos (G-4): coordenadas de la 66-B
--   15 Saga_15_Reestreno  «Reestreno»              la Capitana Ñoz y un episodio especial a cambio de la grabación
--   16 Saga_16_66B        «Dimensión 66-B»         la Valmar malvada (y tu yo con perilla)
--   17 Saga_17_Rescate    «El rescate»             el laboratorio de Cósimo; Cosme vuelve… sin memoria
--   18 Saga_18_Precio     «Todo tiene un precio»   final del acto: la fecha de la Gran Fusión

local V = Vector3.new

local function after(id: string, extra: { [string]: any }?): { [string]: any }
	local req = { Stage = { Min = "AdultoJoven" }, Completed = { id } }
	for key, value in extra or {} do
		req[key] = value
	end
	return req
end

local PIP = { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) }
local ESCAMAS = { Npc = "DonEscamas", Place = "GarajeCosme", Offset = V(-3, 0, 1), Scale = 0.35 }
local EQUIPO = { { Npc = "Ivan", Mode = "Follow" }, { Npc = "Candela", Mode = "Follow" } }

return {
	---------------------------------------------------------------------
	-- 13 · Sin Cosme
	---------------------------------------------------------------------
	{
		Id = "Saga_13_SinCosme",
		Kind = "Side",
		Canon = true,
		Title = "Sin Cosme",
		Description = "El garaje de Cosme lleva meses cerrado. Pip limpia el polvo cada día «por si vuelve». Don Escamas ha adelgazado. Hay que traerle de vuelta.",
		Type = "Saga de la Grieta · Acto III (1/6)",
		Duration = { 25, 35 },
		Npcs = { "Pip", "DonEscamas", "Ivan", "Candela" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "El garaje de Cosme. Cerrado. Pip te abre la puerta: «Por fin. Tenemos que hablar»",
		Requires = after("Saga_12_Graduacion"),
		Moment = "Formaste el equipo de rescate",
		Memory = "EquipoRescate",
		Rewards = { Items = { CuadernoCosme = 1 }, Flags = { "EquipoRescate", "CompisSabenGrieta" } },
		Props = {
			Cuaderno = { Kind = "Libro", Name = "El cuaderno de Cosme", Prompt = "Leer el cuaderno", Place = "GarajeCosme", Offset = V(-2, 0, 3), Color = Color3.fromRGB(120, 60, 40), Dialogue = "Cuaderno", Once = true },
			Mando = { Kind = "Maquina", Name = "El prototipo de mando de rescate", Prompt = "Coger el mando", Place = "GarajeCosme", Offset = V(2, 0, 3), Color = Color3.fromRGB(90, 255, 110), Dialogue = "Mando", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Habla con Pip", Actors = { PIP, ESCAMAS } },
			{ Type = "Group", Text = "Busca en el garaje lo que dejó Cosme", Actors = { PIP, ESCAMAS },
				Steps = {
					{ Type = "Use", Prop = "Cuaderno", Text = "Su cuaderno" },
					{ Type = "Use", Prop = "Mando", Text = "El mando del banco de trabajo" },
				} },
			{ Type = "Talk", Npc = "Candela", Dialogue = "Equipo", Text = "Vuelve a la residencia: necesitas un equipo",
				Actors = {
					{ Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2) },
					{ Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2) },
				} },
			{ Type = "Scene", Dialogue = "Plan", Actors = { PIP, ESCAMAS, { Npc = "Ivan", Place = "GarajeCosme", Offset = V(-4, 0, 5) }, { Npc = "Candela", Place = "GarajeCosme", Offset = V(4, 0, 5) } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "{Saludo}. Llevo cuatrocientos doce días limpiando el polvo del garaje. Por si vuelve. Tiene que encontrarlo limpio. Si no, se queja." },
				{ S = "DonEscamas", T = "(Desde la pecera) He calculado nuestras posibilidades de rescatarle sin ayuda: un 3 %. Con ayuda: un 4 %. Pero con amigos, las matemáticas cambian." },
				{ S = "Pip", T = "El señor dejó dicho que usted sabría qué hacer. Yo creo que lo dijo por decir. Pero aquí estamos." },
			} },
			Cuaderno = { Lines = {
				{ S = "Narrador", T = "El cuaderno de Cosme, lleno de dibujos y coordenadas. En la última página, escrito deprisa: «Si me pasa algo: 1) G-4 (gatos) — Bigotes sabe dónde está la 66-B. 2) La Capitana Ñoz tiene cámaras en todas las dimensiones. 3) NO dejar que la criatura vaya sola»." },
				{ S = "Narrador", T = "Debajo, más pequeño: «Dile que estoy orgulloso. Por si acaso». Lo ha tachado. Pero se lee." },
			} },
			Mando = { Lines = {
				{ S = "Narrador", T = "Un mando de dimensiones a medio montar. Pip lo termina en diez minutos: «El señor lo dejó casi hecho. Siempre deja las cosas casi hechas»." },
			} },
			Equipo = { Lines = {
				{ S = "Candela", T = "Así que tu vecino inventor está secuestrado en otra dimensión por su gemelo malvado con perilla. Y hay que rescatarle. Vale. Lo apunto." },
				{ S = "Ivan", T = "¿Otra dimensión? ¿Con portal y todo? ¡Voy! Llevo zumo. De mora. De día." },
				{ S = "Candela", T = "Iré. Pero con un plan plastificado. Nadie cruza un portal sin plan plastificado. Es la norma." },
			} },
			Plan = { Lines = {
				{ S = "Candela", T = "Plan: uno, la dimensión de los gatos. Dos, una capitana alienígena con cámaras. Tres, rescate. Cuatro, volver a tiempo para el examen de Beltrán. El punto cuatro no es negociable." },
				{ S = "Ivan", T = "Yo me pido llevar el mando. …Vale, no. Yo me pido llevar la merienda." },
				{ S = "Pip", T = "Iré con ustedes. El señor Cosme me dijo «no dejes a la criatura sola». Por una vez, voy a obedecer sin rechistar." },
				{ S = "Narrador", T = "Recibes 📓 el Cuaderno de Cosme. Es oficial: hay un equipo de rescate. Tres estudiantes, un robot y un pez en un cubo." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 14 · El presidente Bigotes
	---------------------------------------------------------------------
	{
		Id = "Saga_14_Bigotes",
		Kind = "Side",
		Canon = true,
		Title = "El presidente Bigotes",
		Description = "Primera parada: la dimensión G-4, donde los gatos mandan. El presidente se llama Bigotes. Y dicen que te conoce.",
		Type = "Saga de la Grieta · Acto III (2/6)",
		Duration = { 20, 30 },
		Npcs = { "Bigotes", "GatoPolicia1", "GatoPolicia2", "Ivan", "Candela" },
		Offer = { Place = "Parque" },
		OfferKey = "Pip ha abierto un portal en el parque. Huele a pienso y a sofá. Es la dimensión de los gatos",
		Requires = after("Saga_13_SinCosme"),
		Moment = "Pediste ayuda al presidente de los gatos",
		Memory = "PresidenteBigotes",
		Rewards = { Items = { CollarDiplomatico = 1 }, Flags = { "CoordenadasCosimo" } },
		Props = {
			Portal = { Kind = "Portal", Name = "Portal a la dimensión G-4", Place = "Parque", Offset = V(0, 0, 8), Prompt = false },
		},
		Steps = {
			{ Type = "Transition", Text = "Cruzas el portal. En esta Valmar todo es igual… pero los gatos son del tamaño de personas y las personas llevan correa.", Seconds = 5, Teleport = "Parque" },
			{ Type = "Escape", Place = "PlazaCentro", Respawn = "Parque", Catch = 4, Props = { "Portal" },
				Text = "¡La policía gatuna quiere ponerte correa! Llega al palacio presidencial (la plaza del centro)",
				CaughtLine = "¡Correa reglamentaria! (Te la quitas mientras el gato se lame una pata. Vuelves al portal.)",
				Actors = {
					{ Npc = "Ivan", Mode = "Follow" },
					{ Npc = "Candela", Mode = "Follow" },
					{ Npc = "GatoPolicia1", Place = "Parque", Offset = V(-10, 0, 6), Mode = "Hunt", Speed = 12, Prompt = false },
					{ Npc = "GatoPolicia2", Place = "Parque", Offset = V(10, 0, 6), Mode = "Hunt", Speed = 11, Prompt = false },
				} },
			{ Type = "Talk", Npc = "Bigotes", Dialogue = "Presidente", Text = "Habla con el presidente Bigotes",
				Actors = {
					{ Npc = "Bigotes", Place = "PlazaCentro", Offset = V(0, 0, 5) },
					{ Npc = "Ivan", Place = "PlazaCentro", Offset = V(-4, 0, 8) },
					{ Npc = "Candela", Place = "PlazaCentro", Offset = V(4, 0, 8) },
				} },
		},
		Dialogues = {
			Presidente = { Lines = {
				{ S = "Bigotes", T = "Humano. Otra vez tú. Aquí soy presidente. En tu dimensión soy emperador exiliado. En todas soy el mejor. Es una constante universal.", If = { Completed = { "Loco_N2_Bigotes" } } },
				{ S = "Bigotes", T = "Humano. Tú eres el del cole. Allí mi otro yo duerme en el patio y finge no hablar. Aquí soy presidente. En todas las dimensiones soy el mejor. Es una constante universal.", If = { NotCompleted = { "Loco_N2_Bigotes" } } },
				{ S = "Bigotes", T = "Me tocaste la barriga una vez. No lo he olvidado. Nunca lo olvidaré.", If = { Flags = { "DuqueDeGatonia" } } },
				{ S = "Bigotes", T = "Ah, el Duque o Duquesa del Cojín. Siempre es un honor.", If = { Flags = { "DuqueDeGatonia" } } },
				{ S = "Candela", T = "Señor presidente gato. Buscamos la dimensión 66-B. Tenemos un plan plastificado." },
				{ S = "Bigotes", T = "La 66-B. La dimensión de las perillas. Los gatos no vamos allí: allí nadie da de comer a los gatos. Es inhumano. Es ingatuno." },
				{ S = "Bigotes", T = "Os daré sus coordenadas. Y un consejo: el doctor de la perilla tiene su laboratorio donde en vuestra Valmar está la universidad. Bajo tierra. Los malos siempre ponen el laboratorio debajo de algo." },
				{ S = "Ivan", T = "Señor gato, ¿me puedo hacer una foto con usted?" },
				{ S = "Bigotes", T = "Una. Sin flash. De mi lado bueno. Todos mis lados son buenos." },
				{ S = "Bigotes", T = "Y tomad: un collar diplomático. En cualquier dimensión con gatos, os abrirá puertas. Y latas." },
				{ S = "Narrador", T = "Recibes 🎀 el Collar diplomático de Gatonia. Primera pieza del rescate: las coordenadas." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 15 · Reestreno
	---------------------------------------------------------------------
	{
		Id = "Saga_15_Reestreno",
		Kind = "Side",
		Canon = true,
		Title = "Reestreno",
		Description = "Para entrar en la 66-B hace falta saber dónde está exactamente el laboratorio de Cósimo. Hay alguien que graba todas las dimensiones: la Capitana Ñoz. Y su nave vuelve esta noche al Monte del Silencio.",
		Type = "Saga de la Grieta · Acto III (3/6)",
		Duration = { 20, 30 },
		Npcs = { "CapitanNoz", "Blorp", "Zarg", "Ivan", "Candela" },
		Offer = { Place = "MonteSilencio" },
		OfferKey = "Una luz sobre el Monte del Silencio. La nave del reality ha vuelto",
		Requires = after("Saga_14_Bigotes", { Hours = { From = 21, To = 5 } }),
		Moment = "Protagonizaste un episodio especial de «Terrícolas en apuros»",
		Memory = "EpisodioEspecial",
		Rewards = { Items = { PaseVIP = 1 }, Flags = { "GrabacionLaboratorio" } },
		Props = {
			Nave = { Kind = "Nave", Name = "La nave del reality", Place = "MonteSilencio", Offset = V(0, 0, -8), Height = 20, Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "CapitanNoz", Dialogue = "Capitana", Text = "La Capitana Ñoz baja de la nave",
				Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3) },
					{ Npc = "Blorp", Place = "MonteSilencio", Offset = V(-4, 0, 2), Mode = "Wave" },
					{ Npc = "Ivan", Place = "MonteSilencio", Offset = V(-3, 0, 8) },
					{ Npc = "Candela", Place = "MonteSilencio", Offset = V(3, 0, 8) },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Rodaje: ¡acción!", Icon = "🎬", Hint = "Di tu frase justo cuando se enciende la luz roja",
				Rounds = 5, Need = 3, Zone = 0.26, Speed = 1,
				Win = { Flags = { "BuenRodaje" }, Traits = { Valentia = 1 } }, Lose = { Traits = { Humor = 1 } },
				Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3), Mode = "Point" },
					{ Npc = "Zarg", Place = "MonteSilencio", Offset = V(4, 0, 2) },
				} },
			{ Type = "Scene", Dialogue = "Grabacion", Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3) },
					{ Npc = "Ivan", Place = "MonteSilencio", Offset = V(-3, 0, 8) },
					{ Npc = "Candela", Place = "MonteSilencio", Offset = V(3, 0, 8) },
				} },
		},
		Dialogues = {
			Capitana = { Lines = {
				{ S = "CapitanNoz", T = "¡La estrella! ¡Mi terrícola favorito o favorita! Tu huida del monte fue nuestro episodio más visto. Trescientas galaxias lo repitieron.", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Terrícola. Me dicen que buscas algo. En mi nave hay cámaras en todas las dimensiones. Todo se graba. Todo. Hasta lo que no se debe.", If = { NotCompleted = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "¿El laboratorio del de la perilla? Lo tengo. En alta definición. Pero en la tele nada es gratis, cariño. Quiero un episodio especial: «Terrícola rescata a su vecino loco»." },
				{ S = "Candela", T = "Nosotros también salimos. Y queremos ver el guion antes. Plastificado." },
				{ S = "Blorp", T = "¡Blorp! ¡Yo hago de malo! ¡Siempre he querido hacer de malo! ¡Tengo una perilla de pega!" },
			} },
			Grabacion = { Lines = {
				{ S = "CapitanNoz", T = "¡Corten! ¡Eres un talento natural! Bueno, natural no. Pero un talento. Toma: la grabación del laboratorio del doctor Cósimo." },
				{ S = "Narrador", T = "En la pantalla: un laboratorio enorme bajo la universidad de la Valmar malvada. Una cápsula de cristal. Dentro, dormido, Cosme. Todavía con sus zapatillas de estar por casa." },
				{ S = "Ivan", T = "…Está vivo. Está bien. Lleva zapatillas. Eso es buena señal. Nadie secuestra a alguien con zapatillas para hacerle algo malo, ¿no?" },
				{ S = "CapitanNoz", T = "Y un pase VIP. Cuando todo esto acabe, venid a la final de temporada. Traed al vecino. Que salga en el último episodio." },
				{ S = "Narrador", T = "Recibes 🎫 el Pase VIP del plató. Segunda pieza del rescate: la grabación." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 16 · Dimensión 66-B
	---------------------------------------------------------------------
	{
		Id = "Saga_16_66B",
		Kind = "Side",
		Canon = true,
		Title = "Dimensión 66-B",
		Description = "La Valmar malvada. Todo es igual pero peor: las palomas roban, los semáforos mienten y todo el mundo lleva perilla. Incluso… tú.",
		Type = "Saga de la Grieta · Acto III (4/6)",
		Duration = { 25, 35 },
		Npcs = { "TuMalvado", "Ivan", "Candela", "Pip", "DronCosimo1", "DronCosimo2" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip ha calibrado el mando con las coordenadas. El portal a la 66-B está abierto en el garaje",
		Requires = after("Saga_15_Reestreno"),
		Moment = "Entraste en la Valmar malvada",
		Memory = "Dimension66B",
		Rewards = { Items = { MapaMalvado = 1 }, Flags = { "ConoceTuMalvado" } },
		Props = {
			Portal = { Kind = "Portal", Name = "Portal a la 66-B", Place = "GarajeCosme", Offset = V(0, 0, -5), Color = Color3.fromRGB(180, 40, 70), Prompt = false },
			Cartel = { Kind = "Mural", Name = "Un cartel: «CÓSIMO ALCALDE PARA SIEMPRE»", Prompt = "Mirar el cartel", Place = "PlazaCentro", Offset = V(0, 0, 8), Color = Color3.fromRGB(150, 30, 50), Dialogue = "Cartel", Once = true },
			Rejilla = { Kind = "Maquina", Name = "Una rejilla de ventilación con vapor verde", Prompt = "Mirar por la rejilla", Place = "Universidad", Offset = V(6, 0, 4), Dialogue = "Rejilla", Once = true },
		},
		Steps = {
			{ Type = "Transition", Text = "Cruzas el portal. La Valmar 66-B: el cielo es morado, las farolas se burlan de ti y en todos los balcones hay un señor con perilla regando plantas carnívoras.", Seconds = 5, Teleport = "PlazaCentro" },
			{ Type = "Use", Prop = "Cartel", Text = "Mira a tu alrededor en la plaza", Actors = EQUIPO },
			{ Type = "Talk", Npc = "TuMalvado", Dialogue = "Malvado", Text = "Alguien con tu cara (y perilla) te mira desde un banco",
				Actors = {
					{ Npc = "TuMalvado", Place = "PlazaCentro", Offset = V(4, 0, 4) },
					{ Npc = "Ivan", Place = "PlazaCentro", Offset = V(-3, 0, 6) },
					{ Npc = "Candela", Place = "PlazaCentro", Offset = V(-1, 0, 7) },
				} },
			{ Type = "Escape", Place = "Universidad", Respawn = "PlazaCentro", Catch = 4,
				Text = "¡Drones de Cósimo! Corre hasta la universidad (malvada) con tu equipo",
				CaughtLine = "¡Participante descalificado! (Te sueltan en la plaza. Candela te recoge.)",
				Actors = {
					{ Npc = "Ivan", Mode = "Follow" },
					{ Npc = "Candela", Mode = "Follow" },
					{ Npc = "DronCosimo1", Place = "PlazaCentro", Offset = V(-12, 0, 6), Mode = "Hunt", Speed = 12, Prompt = false },
					{ Npc = "DronCosimo2", Place = "PlazaCentro", Offset = V(12, 0, 6), Mode = "Hunt", Speed = 12, Prompt = false },
				} },
			{ Type = "Use", Prop = "Rejilla", Text = "Busca la entrada al laboratorio subterráneo", Actors = EQUIPO },
		},
		Dialogues = {
			Cartel = { Lines = {
				{ S = "Narrador", T = "«CÓSIMO ALCALDE PARA SIEMPRE. Votar es opcional. El resultado, no». Debajo, un grafiti pequeñito: «Cosme volverá»." },
				{ S = "Candela", T = "Alguien en esta dimensión todavía se acuerda de Cosme. Eso es un dato importante. Lo apunto en rojo." },
			} },
			Malvado = { Lines = {
				{ S = "TuMalvado", T = "Vaya. Tú. Mi yo bueno. Con tus amigos buenos. Qué asco. Qué envidia. Mayormente asco." },
				{ S = "TuMalvado", T = "Aquí mi vida es un desastre: me echaron del trabajo por malvado, mi gato me dejó por un vecino menos malvado y mis compañeros de cuarto me odian. Los de la 66-B, digo." },
				{ S = "Ivan", T = "(susurrando) ¿Yo soy su compañero de cuarto aquí? ¿Y tengo perilla? …Me pido no saberlo." },
				{ Ask = "¿Qué le dices a tu yo malvado?", Options = {
					{ T = "«Ayúdanos a llegar al laboratorio. Te lo agradeceré.»", Effects = { Flags = { "MalvadoAyudo" }, Traits = { Empatia = 1 } }, Then = {
						{ S = "TuMalvado", T = "¿Agradecer? ¿A mí? …Qué sensación tan rara. Me gusta. La entrada está en la rejilla de la universidad. Y no me des las gracias, que me sale urticaria." },
					} },
					{ T = "«No me fío de ti. Ni de tu perilla.»", Effects = { Traits = { Valentia = 1 } }, Then = {
						{ S = "TuMalvado", T = "Haces bien. Yo tampoco me fío de mí. …Pero la rejilla de la universidad echa humo verde. Por si te interesa. No te lo he dicho." },
					} },
				} },
				{ S = "TuMalvado", T = "Algún día iré a tu Valmar a quedarme con tu vida. Te aviso ahora, para ser justo. Soy malvado, pero de palabra." },
			} },
			Rejilla = { Lines = {
				{ S = "Narrador", T = "Por la rejilla sale vapor verde y música de concurso. Abajo se ve un pasillo enorme, iluminado con neones: «LABORATORIO DEL DR. CÓSIMO — PROHIBIDO EL PASO (excepto concursantes)»." },
				{ S = "Pip", T = "(Por el comunicador) Coordenadas confirmadas. Descansen. Mañana, rescate. Y señor Iván: no se coma las plantas carnívoras. Otra vez." },
				{ S = "Narrador", T = "Recibes 🗺️ el Mapa de la Valmar malvada (dibujado por Candela, con leyenda de colores)." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 17 · El rescate
	---------------------------------------------------------------------
	{
		Id = "Saga_17_Rescate",
		Kind = "Side",
		Canon = true,
		Title = "El rescate",
		Description = "Bajo la universidad de la Valmar malvada, en una cápsula de cristal, duerme Cosme. Entre él y tú: robots, drones y un pasillo con música de concurso.",
		Type = "Saga de la Grieta · Acto III (5/6)",
		Duration = { 30, 40 },
		Npcs = { "Cosme", "Cosimo", "RobotSeguridad", "DronCosimo1", "DronCosimo2", "DronCosimo3", "Ivan", "Candela", "Pip" },
		Offer = { Place = "Universidad" },
		OfferKey = "La rejilla del laboratorio de Cósimo. Tu equipo está listo",
		Requires = after("Saga_16_66B"),
		Moment = "Rescataste a Cosme",
		Memory = "RescateCosme",
		Rewards = { Unflags = { "CosmeSecuestrado" }, Flags = { "CosmeRescatado", "CosmeSinMemoria" } },
		Props = {
			Capsula = { Kind = "Huevo", Name = "La cápsula de cristal", Prompt = "Abrir la cápsula", Place = "Universidad", Offset = V(0, 0, -10), Color = Color3.fromRGB(180, 230, 255), Dialogue = "Capsula", Once = true },
		},
		Steps = {
			{ Type = "Fight", Place = "Universidad", Respawn = "Universidad", Action = "Desconectar ⚡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160),
				Text = "El pasillo del laboratorio: desconecta a los guardias ({count}/{total})",
				CaughtLine = "Tiene usted una llamada de ventas… (Candela tira de ti hacia atrás.)",
				Actors = EQUIPO,
				Enemies = {
					{ Npc = "RobotSeguridad", Offset = V(-6, 0, -4), Speed = 10, HP = 4, Bye = "Llamada… finalizada." },
					{ Npc = "DronCosimo1", Offset = V(6, 0, -4), Speed = 13, Bye = "¡Bzzt! ¡Eliminado!" },
					{ Npc = "DronCosimo2", Offset = V(0, 0, -8), Speed = 13, Bye = "¡Bzzt! ¡A publicidad!" },
				} },
			{ Type = "Use", Prop = "Capsula", Text = "Abre la cápsula de Cosme", Actors = EQUIPO },
			{ Type = "Escape", Place = "GarajeCosme", Respawn = "Universidad", Catch = 4,
				Text = "¡Cósimo ha activado la alarma! Vuelve al portal (el garaje) con Cosme",
				CaughtLine = "¡Concursante atrapado! (Pip dispara confeti al dron y te suelta.)",
				Actors = {
					{ Npc = "Cosme", Mode = "Follow" },
					{ Npc = "Ivan", Mode = "Follow" },
					{ Npc = "Candela", Mode = "Follow" },
					{ Npc = "DronCosimo3", Place = "Universidad", Offset = V(0, 0, 12), Mode = "Hunt", Speed = 13, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Casa",
				Actors = {
					{ Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3), Mode = "Sit" },
					PIP, ESCAMAS,
					{ Npc = "Ivan", Place = "GarajeCosme", Offset = V(-4, 0, 5) },
					{ Npc = "Candela", Place = "GarajeCosme", Offset = V(4, 0, 5) },
				} },
		},
		Dialogues = {
			Capsula = { Lines = {
				{ S = "Narrador", T = "La cápsula se abre con un silbido. Cosme abre los ojos. Te mira. Parpadea. Te mira otra vez." },
				{ S = "Cosme", T = "…Hola. ¿Nos conocemos? Tienes cara de alguien que ha roto algo mío. Muchas veces." },
				{ S = "Narrador", T = "No te recuerda. Cósimo le ha estado sacando los recuerdos, uno a uno, para encontrar cómo soltar el ancla. En una pantalla de la pared pone: «Recuerdos extraídos: 87 %»." },
				{ S = "Cosimo", T = "(Por los altavoces) ¡Qué momento más emocionante! ¡El reencuentro! Lástima que él no se acuerde de ti. Lo mejor de los recuerdos es que se pueden quitar." },
				{ S = "Candela", T = "Ya nos preocuparemos por su memoria. Primero, salir. ¡Ahora!" },
			} },
			Casa = { Lines = {
				{ S = "Pip", T = "Señor. Ha vuelto. …Ha vuelto." },
				{ S = "Cosme", T = "¿Tú eres mi robot? Qué robot más educado. ¿Y ese pez de la pecera me está mirando mal?" },
				{ S = "DonEscamas", T = "Te estoy mirando con cariño. Es mi cara. Los peces no tenemos otra." },
				{ S = "Ivan", T = "Bueno… lo hemos traído. Con zapatillas y todo. Eso es un diez." },
				{ S = "Narrador", T = "Cosme está en casa. Pero no sabe quién eres. Esta noche Pip le pone una manta, y Cosme, medio dormido, dice «criatura». Solo eso. Luego se duerme." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 18 · Todo tiene un precio (final del Acto III)
	---------------------------------------------------------------------
	{
		Id = "Saga_18_Precio",
		Kind = "Side",
		Canon = true,
		Title = "Todo tiene un precio",
		Description = "Cosme está en casa, pero sin recuerdos. Y esta noche, en todas las pantallas de Valmar, aparece un hombre con perilla con un anuncio.",
		Type = "Saga de la Grieta · Acto III (6/6) · Final del acto",
		Duration = { 20, 30 },
		Npcs = { "Cosme", "Cosimo", "Pip", "Ivan", "Candela" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip te llama: «Venga. Todas las pantallas de Valmar se han encendido a la vez»",
		Requires = after("Saga_17_Rescate"),
		Moment = "Cosme recordó tu nombre",
		Memory = "TuNombre",
		Rewards = { Items = { FotoSinMemoria = 1 }, Flags = { "SagaActo3" } },
		Props = {
			Tele = { Kind = "Pantalla", Name = "La tele del garaje", Place = "GarajeCosme", Offset = V(0, 0, -4), Color = Color3.fromRGB(200, 40, 60), Prompt = false },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Anuncio", Props = { "Tele" },
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3), Mode = "Sit" }, PIP } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Nombre", Text = "Siéntate con Cosme",
				Props = { "Tele" },
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3), Mode = "Sit" } } },
		},
		Dialogues = {
			Anuncio = { Lines = {
				{ S = "Cosimo", T = "(En todas las pantallas) ¡{Saludo}, Valmar! Tengo un anuncio. La Gran Fusión se celebrará en el Monte del Silencio. Cuando el Ancla ya no sea una criatura, sino una persona adulta con trabajo y facturas." },
				{ S = "Cosimo", T = "Porque los adultos, querido público, están tan cansados que sueltan cualquier cosa. Hasta un universo. ¡No se lo pierdan! Entradas a la venta en MegaVerso." },
				{ S = "Pip", T = "Nos da tiempo. Años. Tiempo para que el señor recupere la memoria. Y para prepararnos." },
			} },
			Nombre = { Lines = {
				{ S = "Cosme", T = "Mira. No sé quién eres. Pero cuando entras, este garaje huele distinto. Huele a… burbujas. ¿Tiene sentido? No tiene sentido." },
				{ S = "Cosme", T = "Tengo un hueco aquí dentro. Muy grande. Y cuando te miro, el hueco se hace más pequeño. Un poquito." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "Le cuentas lo del microondas temporal y el bocadillo del martes", Effects = { Rel = { Cosme = 6 }, Traits = { Humor = 1 } }, Then = {
						{ S = "Cosme", T = "¿Un microondas que calienta en el pasado? Qué idea más estúpida. Y más genial. …¿Fue idea mía? Claro que fue idea mía." },
					} },
					{ T = "Le dices tu nombre y le das la mano", Effects = { Rel = { Cosme = 8 }, Traits = { Empatia = 2 } }, Then = {
						{ S = "Cosme", T = "{nombre}… {nombre}. …Criatura. Tú eres la criatura. Eso sí lo sé. No sé nada más. Pero eso lo sé." },
					} },
				} },
				{ S = "Narrador", T = "Candela hace una foto: Cosme en su sillón, con cara de no entender nada, y tú a su lado. Iván sale en una esquina comiendo moras." },
				{ S = "Narrador", T = "Recibes 📸 la foto «Cosme sin memoria». FIN DEL ACTO III. Cosme está en casa. Faltan sus recuerdos. Y falta la Gran Fusión." },
			} },
		},
	},
}
