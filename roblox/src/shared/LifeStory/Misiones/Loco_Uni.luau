-- MISIONES LOCAS · UNIVERSIDAD (secundarias). Ficha de diseño: docs/historia/12-misiones-locas.md
--
--   Loco_U1_Monte       «La luz del Monte del Silencio»  la nave, huir, derrotar a los alienígenas → 🔫 Pistola de rayos
--   Loco_U2_Rex         «Mi compañero de piso es un dinosaurio»  la Aduana del Tiempo → 🦖 Diente de Rex
--   Loco_U3_Multiverso  «Las tres Valmar»                  portales y un Cosme de otra dimensión → 🌀 Mando de dimensiones
--   Loco_U4_Fiesta      «La fiesta de los cambiaformas»     encontrar a los impostores → 🕶️ Gafas de ver impostores
--   Loco_U5_Examen      «El examen del universo»            tres pruebas para que la Tierra apruebe → 📜 Diploma del Universo

local V = Vector3.new

local UNI = { Stage = { Min = "AdultoJoven", Max = "AdultoJoven" } }

local CIMA = "CimaMonte"
local NAVE_PROPS = { "Nave" }

return {
	---------------------------------------------------------------------
	-- U1 · La luz del Monte del Silencio
	---------------------------------------------------------------------
	{
		Id = "Loco_U1_Monte",
		Kind = "Side",
		Title = "La luz del Monte del Silencio",
		Description = "En la cafetería del campus todos hablan de lo mismo: en lo alto del monte hay una luz que se lleva a la gente. A las tres de la madrugada.",
		Type = "Misión loca · Universidad (1/5)",
		Duration = { 20, 30 },
		Npcs = { "Luca", "Zarg", "Blorp", "CapitanNoz", "Fermin", "Ines" },
		Offer = { Place = "Universidad" },
		OfferKey = "Rumores en el campus: en el Monte del Silencio desaparece gente. ¿Lo investigas?",
		Requires = UNI,
		Moment = "Resolviste el caso del Monte del Silencio",
		Memory = "Abduccion",
		Rewards = { Items = { PistolaRayos = 1 }, Money = 150 },
		Props = {
			Cartel = { Kind = "Papel", Name = "Cartel: «SE BUSCA: Fermín, senderista»", Prompt = "Leer", Place = "MonteSilencio", Offset = V(3, 0, 2), Dialogue = "Cartel", Once = true },
			Mochila = { Kind = "Mochila", Name = "Una mochila de senderista", Prompt = "Registrar", Place = CIMA, Offset = V(-4, 0, 3), Color = Color3.fromRGB(200, 120, 40), Dialogue = "MochilaFermin", Once = true },
			Nave = { Kind = "Nave", Name = "La luz", Place = CIMA, Offset = V(0, 0, -6), Height = 22, Prompt = false },
			Pistola = { Kind = "Cristal", Name = "La pistola de Blorp", Prompt = "Coger la pistola de rayos", Place = CIMA, Offset = V(2, 0, 4), Color = Color3.fromRGB(90, 255, 120), Dialogue = "Pistola", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Luca", Dialogue = "Rumor", Text = "Luca tiene que contarte algo (bajando la voz)",
				Actors = { { Npc = "Luca", Place = "Universidad", Offset = V(-6, 0, -3) } } },
			{ Type = "Use", Prop = "Cartel", Text = "Ve al pie del Monte del Silencio y busca pistas" },
			{ Type = "Reach", Place = CIMA, Hours = { From = 2, To = 5 }, Text = "Sube a la cima del monte de madrugada (entre las 2:00 y las 5:00)" },
			{ Type = "Use", Prop = "Mochila", Text = "Hay algo tirado en la cima…" },
			{ Type = "Cinematic", Id = "Loco_Abduccion", Props = NAVE_PROPS },
			{ Type = "Escape", Seconds = 25, Respawn = CIMA, Catch = 4, Props = NAVE_PROPS,
				Text = "¡La luz te está absorbiendo! Corre y que no te atrapen durante 25 segundos",
				CaughtLine = "¡Blorp! ¡Te tengo! …¡Ay, se me escapa! (Vuelves a la cima. La luz te busca otra vez.)",
				Actors = { { Npc = "Blorp", Place = CIMA, Offset = V(0, 0, -10), Mode = "Hunt", Speed = 12, Prompt = false } } },
			{ Type = "Scene", Dialogue = "Bajan", Props = NAVE_PROPS,
				Actors = {
					{ Npc = "CapitanNoz", Place = CIMA, Offset = V(0, 0, -8) },
					{ Npc = "Zarg", Place = CIMA, Offset = V(-4, 0, -6) },
					{ Npc = "Blorp", Place = CIMA, Offset = V(4, 0, -6) },
				} },
			{ Type = "Use", Prop = "Pistola", Text = "¡A Blorp se le ha caído su pistola de rayos! ¡Cógela!", Props = NAVE_PROPS,
				Actors = {
					{ Npc = "CapitanNoz", Place = CIMA, Offset = V(0, 0, -8) },
					{ Npc = "Zarg", Place = CIMA, Offset = V(-4, 0, -6) },
					{ Npc = "Blorp", Place = CIMA, Offset = V(4, 0, -6), Mode = "Point" },
				} },
			{ Type = "Fight", Place = CIMA, Respawn = CIMA, Action = "Disparar 🔫", HP = 3, BeamColor = Color3.fromRGB(90, 255, 120), Props = NAVE_PROPS,
				Text = "¡Quieren capturarte! Derrota a los alienígenas con su propia pistola ({count}/{total})",
				CaughtLine = "¡Te tengo, terrícola! (Te suelta al ver la pistola. Vuelves a la cima.)",
				Enemies = {
					{ Npc = "Blorp", Offset = V(4, 0, -6), Speed = 11, HP = 2, Hurt = "¡Blorp! ¡Eso es MI pistola! ¡Me la regaló mi madre!", Bye = "¡Me vuelvo a la nave! ¡Blooorp!" },
					{ Npc = "Zarg", Offset = V(-4, 0, -6), Speed = 13, HP = 3, Hurt = "¡Esto no estaba en el guion!", Bye = "¡Os denunciaré al sindicato de alienígenas!" },
					{ Npc = "CapitanNoz", Offset = V(0, 0, -10), Speed = 14, HP = 5, Hurt = "¡Cámaras, grabad esto! ¡Es oro televisivo!", Bye = "¡Nos vamos! ¡Pero qué final de temporada, terrícola!" },
				} },
			{ Type = "Scene", Dialogue = "Liberados", Props = NAVE_PROPS,
				Actors = { { Npc = "Fermin", Place = CIMA, Offset = V(0, 0, -3) } } },
			{ Type = "Talk", Npc = "Ines", Dialogue = "Caso", Text = "Cuéntaselo a la policía: la agente Inés te espera en comisaría",
				Actors = { { Npc = "Ines", Place = "Policia", Offset = V(0, 0, 4) }, { Npc = "Fermin", Place = "Policia", Offset = V(3, 0, 4) } } },
		},
		Dialogues = {
			Rumor = { Lines = {
				{ S = "Luca", T = "Oye. ¿Te has enterado? Lo del Monte del Silencio. El que se ve desde la biblioteca." },
				{ S = "Luca", T = "Dicen que a las tres de la madrugada sale una luz en la cima. Y que si estás cerca… ¡zas! Desapareces. Tres personas este mes. La última, un senderista, Fermín." },
				{ S = "Luca", T = "Mi primo dice que son gases del monte. Mi abuela dice que es un castigo por no ir a misa. Yo digo que no pienso ir a comprobarlo." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Pues yo sí voy.»", Effects = { Traits = { Valentia = 2 }, Rel = { Luca = 3 } }, Then = {
						{ S = "Luca", T = "¿Tú estás mal? …Vale. Si no vuelves, me quedo tus apuntes de Estadística." },
					} },
					{ T = "«Seguro que hay una explicación científica.»", Effects = { Traits = { Curiosidad = 2 } }, Then = {
						{ S = "Luca", T = "Claro. Como la vez que dijiste que el comedor no podía envenenar a nadie. Y luego el jueves." },
					} },
				} },
			} },
			Cartel = { Lines = {
				{ S = "Narrador", T = "«SE BUSCA: Fermín, 58 años, senderista. Visto por última vez subiendo al Monte del Silencio con un bocadillo de tortilla. Recompensa.»" },
				{ S = "Narrador", T = "Alguien ha escrito debajo, con otra letra: «NO SUBAS DE NOCHE». Y debajo, con otra letra más: «¿Por?». Y debajo: «POR LA LUZ, LISTO»." },
			} },
			MochilaFermin = { Lines = {
				{ S = "Narrador", T = "La mochila de Fermín. Dentro: un mapa, una cantimplora y medio bocadillo de tortilla… perfectamente conservado. Como si el tiempo no hubiera pasado." },
				{ S = "Narrador", T = "El aire zumba. Se te erizan los pelos de los brazos. Arriba, las estrellas… se apagan una a una." },
			} },
			Bajan = { Lines = {
				{ S = "Narrador", T = "La luz se apaga de golpe. Una escalerilla baja de la nave. Por ella bajan tres… personas. Verdes. Con antenas. Y cara de estar MUY hartas." },
				{ S = "CapitanNoz", T = "¡CORTEN! ¡Corten, corten! ¡Terrícola! ¡Nos estás estropeando el episodio!" },
				{ S = "Yo", T = "¿El… episodio?" },
				{ S = "CapitanNoz", T = "«Terrícolas en apuros», el reality número uno de la galaxia. Trescientas temporadas. Abducimos humanos y los vemos intentar abrir un bote de pepinillos con guantes de boxeo." },
				{ S = "Zarg", T = "Y tú no te dejas abducir. Llevamos veinticinco segundos de huida. La audiencia se aburre. Se aburre MUCHO." },
				{ S = "Blorp", T = "¡Blorp! ¡Capitana! ¡Los datos dicen que la audiencia se ha triplicado! ¡Les encanta cómo corre!", A = "Cheer" },
				{ S = "CapitanNoz", T = "…Entonces te queremos de protagonista. PARA SIEMPRE. ¡A por él! ¡A por ella! ¡A por lo que sea! ¡CAPTURADLE!" },
				{ S = "Narrador", T = "Blorp tropieza al bajar la escalerilla. Su pistola de rayos rueda por el suelo hasta tus pies." },
			} },
			Pistola = { Lines = {
				{ S = "Narrador", T = "Es ligera, brillante y tiene un solo botón. Encima del botón pone, en algún idioma alienígena, algo que seguro significa «NO»." },
				{ S = "Blorp", T = "¡Eso es mío! ¡Tiene mis babas! ¡Devuélvemela, terrícola!" },
			} },
			Liberados = { Lines = {
				{ S = "Narrador", T = "Los tres alienígenas se desintegran en chispas verdes y reaparecen dentro de la nave, teletransportados, castigados y sin merienda." },
				{ S = "CapitanNoz", T = "(Por el altavoz de la nave) ¡Está bien! ¡Está bien! ¡Devolvemos a los terrícolas! ¡Y cancelamos la temporada! …¡Pero te llevarás un premio a mejor actor o actriz revelación!" },
				{ S = "Narrador", T = "De la luz bajan flotando tres personas en pijama. La última lleva botas de montaña y un bocadillo de tortilla a medio comer." },
				{ S = "Fermin", T = "¡Tres semanas! ¡Tres semanas abriendo botes de pepinillos con guantes de boxeo! …Aunque he ganado dos concursos. En la galaxia soy muy conocido." },
				{ S = "Fermin", T = "Gracias, de verdad. Me has salvado. Y a los otros dos. Uno es un fontanero; la otra, una profesora de yoga. Ahora son pareja. Cosas del plató." },
				{ S = "Narrador", T = "La nave sube, sube… y desaparece con un «piuuu» ridículo. En el cielo vuelven a salir las estrellas." },
			} },
			Caso = { Lines = {
				{ S = "Ines", T = "A ver si lo entiendo. Tres desaparecidos. Una luz. Y tú me dices que eran… alienígenas de un programa de la tele." },
				{ S = "Fermin", T = "Doy fe, agente. Tengo una taza de la tripulación." },
				{ Ask = "¿Qué pones en la declaración?", Options = {
					{ T = "«La verdad: alienígenas. Con antenas.»", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Ines = 4 }, Flags = { "DeclaracionAlien" } }, Then = {
						{ S = "Ines", T = "…Lo escribo tal cual. Voy a ser el hazmerreír de comisaría. Pero lo escribo. Caso cerrado." },
					} },
					{ T = "«Gases del monte. Mucho gas.»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Ines", T = "Gases. Perfecto. Eso sí me lo aprueba el comisario. Aunque me miras con una cara…" },
					} },
				} },
				{ S = "Ines", T = "Por encontrar a los desaparecidos hay una recompensa: 150. Y esa… pistola de juguete que llevas… quédatela. No quiero ni saber qué es." },
				{ S = "Narrador", T = "Recibes 🔫 la Pistola de rayos alienígena (úsala desde tu mochila) y 150 de recompensa." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- U2 · Mi compañero de piso es un dinosaurio
	---------------------------------------------------------------------
	{
		Id = "Loco_U2_Rex",
		Kind = "Side",
		Title = "Mi compañero de piso es un dinosaurio",
		Description = "Tu nuevo compañero de piso es educado, estudia Derecho y paga a tiempo. También tiene garras, cola y se come tu jamón.",
		Type = "Misión loca · Universidad (2/5)",
		Duration = { 15, 22 },
		Npcs = { "Rex", "CazadorTiempo", "Cosme" },
		Offer = { Place = "Home" },
		OfferKey = "Ha llegado tu nuevo compañero de piso. Hay unas huellas muy raras en la entrada…",
		Requires = { Stage = { Min = "AdultoJoven", Max = "AdultoJoven" }, NotFlags = { "CosmeSecuestrado" } }, -- Cosme sale en el juicio
		Moment = "Defendiste a Rex ante la Aduana del Tiempo",
		Memory = "CompaneroRex",
		Rewards = { Items = { DienteRex = 1 } },
		Props = {
			Nevera = { Kind = "Caja", Name = "La nevera", Prompt = "Abrir la nevera", Place = "HomeCocina", Offset = V(2, 0, 0), Color = Color3.fromRGB(235, 240, 245), Dialogue = "Nevera", Once = true },
			Sofa = { Kind = "Banco", Name = "El sofá (con zarpazos)", Prompt = "Mirar el sofá", Place = "HomeSalon", Offset = V(0, 0, 3), Dialogue = "Sofa", Once = true },
			Codigo = { Kind = "Libro", Name = "El Código Civil de Rex (mordido)", Prompt = "Hojear", Place = "HomeSalon", Offset = V(-3, 0, 1), Color = Color3.fromRGB(40, 70, 140), Dialogue = "Codigo", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Rex", Dialogue = "Hola", Text = "Conoce a tu nuevo compañero de piso",
				Actors = { { Npc = "Rex", Place = "HomeSalon", Offset = V(2, 0, 2) } } },
			{ Type = "Group", Text = "La primera semana de convivencia",
				Actors = { { Npc = "Rex", Place = "HomeSalon", Offset = V(2, 0, 2), Mode = "Chat" } },
				Steps = {
					{ Type = "Use", Prop = "Nevera", Text = "La nevera" },
					{ Type = "Use", Prop = "Sofa", Text = "El sofá" },
					{ Type = "Use", Prop = "Codigo", Text = "Los libros de Rex" },
				} },
			{ Type = "Scene", Dialogue = "Aduana",
				Actors = { { Npc = "Rex", Place = "HomeSalon", Offset = V(2, 0, 2) }, { Npc = "CazadorTiempo", Place = "HomeSalon", Offset = V(-2, 0, 4) } } },
			{ Type = "Escape", Place = "FacultadDerecho", Respawn = "Home", Catch = 4,
				Text = "¡Llévate a Rex a la Facultad de Derecho antes de que el agente Cronos os atrape!",
				CaughtLine = "¡Formulario 27-B! ¡Queda usted retenido! …Ah, no, que me falta un sello. Vuelvan a empezar.",
				Actors = {
					{ Npc = "Rex", Mode = "Follow" },
					{ Npc = "CazadorTiempo", Place = "Home", Offset = V(-8, 0, 6), Mode = "Hunt", Speed = 11, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Juicio",
				Actors = {
					{ Npc = "Rex", Place = "FacultadDerecho", Offset = V(2, 0, 3) },
					{ Npc = "CazadorTiempo", Place = "FacultadDerecho", Offset = V(-2, 0, 4) },
					{ Npc = "Cosme", Place = "FacultadDerecho", Offset = V(5, 0, 6) },
				} },
		},
		Dialogues = {
			Hola = { Lines = {
				{ S = "Rex", T = "{Saludo}. Soy Rex. Estudio segundo de Derecho. No fumo, no hago ruido, pago puntual. Tengo garras, pero las limo los domingos." },
				{ S = "Yo", T = "Eres… ¿un dinosaurio?" },
				{ S = "Rex", T = "Velocirraptor. De una línea temporal donde el meteorito falló por tres kilómetros. Allí los dinosaurios tenemos universidades, hipotecas y atascos." },
				{ S = "Rex", T = "Vine aquí de Erasmus temporal. El programa se llama «Erasmus», sí. Igual que el vuestro. El universo es muy poco original." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«¡Bienvenido! ¿Te gusta la pizza?»", Effects = { Rel = { Rex = 6 }, Traits = { Empatia = 1 } }, Then = {
						{ S = "Rex", T = "Me gusta todo lo que tenga carne. Incluida la pizza. Incluida la caja de la pizza." },
					} },
					{ T = "«Normas: mi jamón es MÍO.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Rex", T = "Entendido. Tu jamón es tuyo. …¿Y el de la nevera de quién es? Porque ya no está." },
					} },
				} },
			} },
			Nevera = { Lines = {
				{ S = "Narrador", T = "La nevera está vacía. Solo queda un pósit con letra muy cuidada: «Perdón por el jamón. Y por el pollo. Y por los yogures. Instinto. Te lo repongo. — Rex»." },
			} },
			Sofa = { Lines = {
				{ S = "Narrador", T = "Tres zarpazos en el sofá. Y una nota: «Tuve una pesadilla con un meteorito. Pagaré la tapicería en cómodos plazos»." },
			} },
			Codigo = { Lines = {
				{ S = "Narrador", T = "El Código Civil de Rex, lleno de subrayados. En la página del derecho de residencia hay una esquina mordida. Y un billete de vuelta caducado hace dos meses." },
				{ S = "Narrador", T = "Ay. Rex lleva dos meses aquí sin papeles temporales." },
			} },
			Aduana = { Lines = {
				{ S = "Narrador", T = "Llaman al timbre. Al abrir, un hombre con traje, maletín y cuarenta formularios bajo el brazo. Todo él brilla un poquito." },
				{ S = "CazadorTiempo", T = "Agente Cronos, Aduana del Tiempo. Busco a un velocirraptor con el visado temporal caducado. Tiene que volver a su época. Hoy." },
				{ S = "Rex", T = "¡Si vuelvo, me pierdo el examen de Derecho Romano! ¡Llevo tres semanas estudiando! ¡Y allí los romanos son iguanas!" },
				{ S = "Rex", T = "Solo hay un sitio donde pueden ayudarme: la Facultad de Derecho. Allí hay una ventanilla de recursos. ¡Hay que llegar antes de que cierre!" },
				{ S = "CazadorTiempo", T = "Nadie huye de la Aduana del Tiempo. Bueno, todos lo intentan. Pero despacito, porque yo corro poco." },
			} },
			Juicio = { Lines = {
				{ S = "Rex", T = "¡Llegamos! Señor agente: solicito un recurso de residencia excepcional por… por… ¡por arraigo! Tengo piso, tengo compañero, tengo examen." },
				{ S = "CazadorTiempo", T = "El arraigo hay que demostrarlo. ¿Algún testigo?" },
				{ Ask = "Todos te miran. ¿Qué dices?", Options = {
					{ T = "«Rex es el mejor compañero de piso que he tenido.»", Effects = { Rel = { Rex = 10 }, Traits = { Empatia = 2 }, Flags = { "RexSeQueda" } }, Then = {
						{ S = "Rex", T = "…¿De verdad? ¿Con lo del jamón?" },
						{ S = "Yo", T = "Con lo del jamón. Y lo del sofá." },
					} },
					{ T = "«Es un velocirraptor. Pero paga a tiempo.»", Effects = { Traits = { Humor = 1 }, Rel = { Rex = 5 }, Flags = { "RexSeQueda" } }, Then = {
						{ S = "CazadorTiempo", T = "Pagar a tiempo. En mis cuatrocientos años de carrera, es el mejor argumento que he oído." },
					} },
				} },
				{ S = "Cosme", T = "(Desde el fondo) Y si no vale, yo le hago unos papeles. Tengo una fotocopiadora que fotocopia en el pasado. Técnicamente, siempre tuvo visado.", If = { NotFlags = { "CosmeSinMemoria" } } },
				{ S = "Cosme", T = "(Desde el fondo) No sé quién es este dinosaurio. Tampoco sé quién soy yo, la verdad. Pero tengo una fotocopiadora rarísima en el garaje, y seguro que algo sabe hacer. Técnicamente, siempre tuvo visado.", If = { Flags = { "CosmeSinMemoria" } } },
				{ S = "CazadorTiempo", T = "No he oído nada. …Recurso aceptado. Residencia temporal concedida. Sello. Sello. Y sello." },
				{ S = "Rex", T = "¡GRAAAAH! Perdón. Es de alegría. Toma: un diente mío. En mi época es lo que se regala a los amigos. Me salen nuevos cada martes." },
				{ S = "Narrador", T = "Recibes 🦖 el Diente de Rex." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- U3 · Las tres Valmar
	---------------------------------------------------------------------
	{
		Id = "Loco_U3_Multiverso",
		Kind = "Side",
		Title = "Las tres Valmar",
		Description = "Cosme ha inventado un mando que abre portales a otras dimensiones. Necesita un voluntario. Te mira. Solo te mira a ti.",
		Type = "Misión loca · Universidad (3/5)",
		Duration = { 15, 22 },
		Npcs = { "Cosme", "Bigotes", "Pip" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme te llama desde el garaje: «¡Criatura! ¿Te apetece ver otras dimensiones? Es para una cosa de ciencia. Y de ego.»",
		Requires = { Stage = { Min = "AdultoJoven" }, NotFlags = { "CosmeSecuestrado", "CosmeSinMemoria" } }, -- con el Cosme de siempre: no mientras está secuestrado ni sin memoria (si pasa, queda para la vida adulta)
		Moment = "Visitaste tres dimensiones con Cosme",
		Memory = "Multiverso",
		Rewards = { Items = { MandoDimensiones = 1 } },
		Props = {
			PortalGatos = { Kind = "Portal", Name = "Portal a la dimensión G-4 (gatos)", Prompt = "Entrar en el portal", Place = "Parque", Offset = V(0, 0, 6), Dialogue = "Gatos", Once = true },
			PortalAlcalde = { Kind = "Portal", Name = "Portal a la dimensión V-9 (tú mandas)", Prompt = "Entrar en el portal", Place = "PlazaCentro", Offset = V(0, 0, 6), Color = Color3.fromRGB(255, 200, 60), Dialogue = "Alcalde", Once = true },
			PortalAburrido = { Kind = "Portal", Name = "Portal a la dimensión A-0 (aburrida)", Prompt = "Entrar en el portal", Place = "Playa", Offset = V(0, 0, 6), Color = Color3.fromRGB(160, 160, 170), Dialogue = "Aburrida", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Mando", Text = "Cosme quiere enseñarte un mando (con muchos botones)",
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) }, { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) } } },
			{ Type = "Group", Text = "Entra en los tres portales y apunta qué ves",
				Actors = { { Npc = "Cosme", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "PortalGatos", Text = "Portal del parque" },
					{ Type = "Use", Prop = "PortalAlcalde", Text = "Portal de la plaza del centro" },
					{ Type = "Use", Prop = "PortalAburrido", Text = "Portal de la playa" },
				} },
			{ Type = "Scene", Dialogue = "Verdad",
				Actors = { { Npc = "Cosme", Place = "Playa", Offset = V(3, 0, 3) } } },
			{ Type = "Choice", Key = "CualCosme", Text = "¿Qué haces con el Cosme de la dimensión aburrida?",
				Options = {
					{ Id = "Rescatar", Text = "Volver a por el Cosme de siempre (y dejar a cada uno en su sitio)", Effects = { Rel = { Cosme = 8 }, Traits = { Valentia = 1 }, Flags = { "CosmeOriginal" } } },
					{ Id = "Quedarse", Text = "Quedarte con los dos Cosmes (¿qué podría salir mal?)", Effects = { Traits = { Humor = 1 }, Flags = { "DosCosmes" } } },
				},
				Actors = { { Npc = "Cosme", Place = "Playa", Offset = V(3, 0, 3) } } },
			{ Type = "Scene", Dialogue = "Final",
				Actors = { { Npc = "Cosme", Place = "Playa", Offset = V(3, 0, 3) } } },
		},
		Dialogues = {
			Mando = { Lines = {
				{ S = "Cosme", T = "¡Criatura! ¡Cuánto has crecido! Ya estudias en la universidad… ¿Cuántos años tienes? No me lo digas. Me da igual. El tiempo es una ilusión. El alquiler, no.", If = { Stage = { Max = "AdultoJoven" } } },
				{ S = "Cosme", T = "¡Criatura! ¡Cuánto has crecido! Ya trabajas, pagas facturas… ¿Cuántos años tienes? No me lo digas. Me da igual. El tiempo es una ilusión. El alquiler, no.", If = { Stage = { Min = "Adulto" } } },
				{ S = "Cosme", T = "Mira: el mando de dimensiones. Cada botón, una Valmar distinta. Hay infinitas. En una eres rico. En otra eres una silla. No toques el botón de la silla." },
				{ S = "Pip", T = "El señor Cosme quiere presentarlo en un congreso de científicos. Necesita pruebas. Y un voluntario. El último voluntario fui yo. Ahora tengo un tornillo que canta." },
				{ S = "Cosme", T = "He abierto tres portales: en el parque, en la plaza del centro y en la playa. Tú entras, miras, sales. Yo apunto. Ciencia." },
			} },
			Gatos = { Lines = {
				{ S = "Narrador", T = "Al otro lado del portal, Valmar es igual… pero todo el mundo es un gato. Los coches son gatos. Las farolas son gatos. Hay un gato conduciendo un autobús lleno de gatos." },
				{ S = "Bigotes", T = "Humano. Aquí no se permiten humanos sin correa. Soy el presidente de esta dimensión y exijo que… ¿Te conozco? Tienes cara de haberme tocado la barriga alguna vez." },
				{ S = "Narrador", T = "Sales del portal antes de que te pongan un collar. Cosme apunta: «Dimensión G-4: gatos. Descartada. Los gatos no pagan congresos»." },
			} },
			Alcalde = { Lines = {
				{ S = "Narrador", T = "En esta Valmar hay estatuas de ti en todas las esquinas. Carteles con tu cara: «{nombre}, alcaldía para siempre». Todo el mundo lleva tu peinado. Qué horror." },
				{ S = "Narrador", T = "Un señor se arrodilla al verte: «¡Excelencia! ¡Los baches! ¡Los baches de la calle Mayor!». Otro: «¡Excelencia! ¡Mi gato quiere votar!»." },
				{ S = "Narrador", T = "Sales corriendo. Ser tú en otra dimensión da muchísimo trabajo. Cosme apunta: «V-9: poder absoluto. Aburrido. Demasiadas reuniones»." },
			} },
			Aburrida = { Lines = {
				{ S = "Narrador", T = "Esta Valmar es gris. Nadie inventa nada. Nadie sueña nada. En la playa, un señor de pelo blanco muy bien peinado lee el periódico. Es Cosme. Un Cosme… normal." },
				{ S = "Narrador", T = "Lleva corbata. Dice «buenas tardes». Trabaja en un banco. No ha hecho explotar nada en toda su vida. Está tranquilo. Parece… feliz, a su manera." },
				{ S = "Narrador", T = "Al salir del portal, el Cosme que venía contigo se ha quedado muy callado. Tiene cara de alguien que ha visto algo que no quería ver." },
			} },
			Verdad = { Lines = {
				{ S = "Cosme", T = "Criatura. Tengo que contarte una cosa. Yo no soy tu Cosme. Bueno, sí. Soy un Cosme. Pero soy el de la dimensión K-12." },
				{ S = "Cosme", T = "Tu Cosme, el de siempre, el del microondas y la gallina… hace un mes probó el mando. Llegó a la dimensión aburrida. Y… se quedó." },
				{ S = "Yo", T = "¿Se quedó? ¿Por qué?" },
				{ S = "Cosme", T = "Porque allí nadie le mira como a un loco. Porque allí todo sale bien. Yo vine a sustituirle para que no lo echaras de menos. Somos casi iguales. Yo tengo un lunar más.", A = "Sad" },
			} },
			Final = { Lines = {
				{ S = "Cosme", T = "Pase lo que pase, el mando ya es tuyo. Te llevará a otros sitios de la región. Casi nunca a la dimensión de los gatos. Casi.", If = { Choices = { CualCosme = "Quedarse" } } },
				{ S = "Narrador", T = "Así que ahora hay dos Cosmes en el garaje. Discuten todo el día. Ya han explotado dos microondas. Los vecinos no notan la diferencia.", If = { Choices = { CualCosme = "Quedarse" } } },
				{ S = "Narrador", T = "Vuelves a la dimensión aburrida. Tu Cosme te mira desde la tumbona. Y, por primera vez en un mes, sonríe de verdad.", If = { Choices = { CualCosme = "Rescatar" } } },
				{ S = "Cosme", T = "Criatura. Has venido a por mí. …Lo aburrido es cómodo, ¿sabes? Pero allí nadie me necesitaba. Aquí, al menos, alguien me pregunta qué he roto hoy.", If = { Choices = { CualCosme = "Rescatar" } } },
				{ S = "Cosme", T = "Toma el mando. Úsalo para ir de un sitio a otro. Y si algún día quieres una vida aburrida… no la quieras. Es muy aburrida.", If = { Choices = { CualCosme = "Rescatar" } } },
				{ S = "Narrador", T = "Recibes 🌀 el Mando de dimensiones (te lleva a un sitio de la región; usa la mochila)." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- U4 · La fiesta de los cambiaformas
	---------------------------------------------------------------------
	{
		Id = "Loco_U4_Fiesta",
		Kind = "Side",
		Title = "La fiesta de los cambiaformas",
		Description = "Fiesta en el campus. Música, pizza y dos invitados que saludan con el codo y se ríen tres segundos tarde.",
		Type = "Misión loca · Universidad (4/5)",
		Duration = { 15, 20 },
		Npcs = { "Julia", "Adrian", "Luca", "Impostor1", "Impostor2" },
		Offer = { Place = "Universidad" },
		OfferKey = "Julia organiza una fiesta en el estadio del campus esta noche. ¿Vas?",
		Requires = { Stage = { Min = "AdultoJoven", Max = "AdultoJoven" }, Hours = { From = 18, To = 4 } },
		Moment = "Desenmascaraste a los cambiaformas de la fiesta",
		Memory = "FiestaImpostores",
		Rewards = { Items = { GafasImpostores = 1 } },
		Steps = {
			{ Type = "Talk", Npc = "Julia", Dialogue = "Julia", Text = "Llega a la fiesta: Julia te espera en el estadio",
				Actors = {
					{ Npc = "Julia", Place = "EstadioUniversitario", Offset = V(0, 0, 4) },
					{ Npc = "Adrian", Place = "EstadioUniversitario", Offset = V(-6, 0, 6), Mode = "Dance" },
					{ Npc = "Luca", Place = "EstadioUniversitario", Offset = V(-4, 0, 8), Mode = "Chat" },
					{ Npc = "Impostor1", Place = "EstadioUniversitario", Offset = V(6, 0, 6) },
					{ Npc = "Impostor2", Place = "EstadioUniversitario", Offset = V(5, 0, 9) },
				} },
			{ Type = "Group", Text = "Habla con los invitados y busca pistas",
				Actors = {
					{ Npc = "Adrian", Place = "EstadioUniversitario", Offset = V(-6, 0, 6) },
					{ Npc = "Luca", Place = "EstadioUniversitario", Offset = V(-4, 0, 8) },
					{ Npc = "Impostor1", Place = "EstadioUniversitario", Offset = V(6, 0, 6) },
					{ Npc = "Impostor2", Place = "EstadioUniversitario", Offset = V(5, 0, 9) },
				},
				Steps = {
					{ Type = "Talk", Npc = "Adrian", Dialogue = "Adrian", Text = "Adrián" },
					{ Type = "Talk", Npc = "Luca", Dialogue = "Luca", Text = "Luca" },
					{ Type = "Talk", Npc = "Impostor1", Dialogue = "Imp1", Text = "El chico de la camiseta amarilla" },
					{ Type = "Talk", Npc = "Impostor2", Dialogue = "Imp2", Text = "La chica de la camiseta turquesa" },
				} },
			{ Type = "Choice", Key = "Acusar", Text = "¿Quiénes son los cambiaformas?",
				Options = {
					{ Id = "Bien", Text = "Los de las camisetas amarilla y turquesa", Effects = { Traits = { Curiosidad = 2 } } },
					{ Id = "Mal", Text = "Adrián y Luca (están muy raros esta noche)", Effects = { Rel = { Adrian = -3, Luca = -3 }, Traits = { Humor = 1 } } },
				},
				Actors = {
					{ Npc = "Julia", Place = "EstadioUniversitario", Offset = V(0, 0, 4) },
					{ Npc = "Adrian", Place = "EstadioUniversitario", Offset = V(-6, 0, 6) },
					{ Npc = "Luca", Place = "EstadioUniversitario", Offset = V(-4, 0, 8) },
					{ Npc = "Impostor1", Place = "EstadioUniversitario", Offset = V(6, 0, 6) },
					{ Npc = "Impostor2", Place = "EstadioUniversitario", Offset = V(5, 0, 9) },
				} },
			{ Type = "Scene", Dialogue = "Descubiertos",
				Actors = {
					{ Npc = "Julia", Place = "EstadioUniversitario", Offset = V(0, 0, 4) },
					{ Npc = "Impostor1", Place = "EstadioUniversitario", Offset = V(6, 0, 6) },
					{ Npc = "Impostor2", Place = "EstadioUniversitario", Offset = V(5, 0, 9) },
				} },
			{ Type = "Fight", Place = "EstadioUniversitario", Respawn = "EstadioUniversitario", Action = "Arrancarle el disfraz", HP = 3, BeamColor = Color3.fromRGB(120, 255, 255),
				Text = "¡Los cambiaformas intentan copiarte la cara! Quítales el disfraz ({count}/{total})",
				CaughtLine = "¡Ya casi tengo tu nariz! …Uy, se me escapa. (Te zafas y vuelves al centro de la pista.)",
				Enemies = {
					{ Npc = "Impostor1", Offset = V(6, 0, 6), Speed = 12, Hurt = "¡Hola, compañero humano! ¡Deja mi cara humana!", Bye = "¡Glglglgl! (Se convierte en un charco de gelatina azul que sale reptando hacia su nave.)" },
					{ Npc = "Impostor2", Offset = V(5, 0, 9), Speed = 12, Hurt = "¡Esto no es una bienvenida humana correcta!", Bye = "¡Volveremos con mejores caras! (Charco de gelatina. Fuera.)" },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = {
					{ Npc = "Julia", Place = "EstadioUniversitario", Offset = V(0, 0, 4), Mode = "Cheer" },
					{ Npc = "Adrian", Place = "EstadioUniversitario", Offset = V(-6, 0, 6), Mode = "Cheer" },
					{ Npc = "Luca", Place = "EstadioUniversitario", Offset = V(-4, 0, 8), Mode = "Cheer" },
				} },
		},
		Dialogues = {
			Julia = { Lines = {
				{ S = "Julia", T = "¡Has venido! {Bienvenido/Bienvenida} a la mejor fiesta de la facultad. Hay pizza, hay música… y hay dos personas que no ha invitado nadie." },
				{ S = "Julia", T = "No sé. Son raros. Muy raros. Uno me ha dado la mano con el codo. La otra me ha preguntado «qué tal tu digestión humana». Habla con la gente, ¿vale? Tú tienes buen ojo." },
			} },
			Adrian = { Lines = {
				{ S = "Adrian", T = "¿Yo raro? Estoy bailando. Bueno. Intentándolo. Es mi primera fiesta desde el examen de Estadística. Tengo el cuerpo oxidado." },
				{ S = "Narrador", T = "Adrián baila fatal. Pero fatal humano: pisa, se ríe, pide perdón. Ninguna pista aquí." },
			} },
			Luca = { Lines = {
				{ S = "Luca", T = "Esos dos no comen pizza. Se la acercan a la oreja. Como si la escucharan. ¿Tú has escuchado una pizza alguna vez? Yo sí, una vez, pero estaba muy cansado." },
			} },
			Imp1 = { Lines = {
				{ S = "Impostor1", T = "Hola, compañero humano. Yo también soy humano. Me gustan las cosas humanas: el oxígeno, los impuestos y la gravedad." },
				{ S = "Impostor1", T = "Jajaja. (Tres segundos después.) Jajaja. Perdón. Me he reído dos veces. Es que soy muy humano." },
				{ S = "Narrador", T = "Cuando parpadea, sus párpados van de lado a lado. Como una persiana." },
			} },
			Imp2 = { Lines = {
				{ S = "Impostor2", T = "Qué fiesta más humana. ¿Tú también tienes dos piernas? Yo tengo… dos. Exactamente dos. Ni una más. Nunca." },
				{ S = "Narrador", T = "Debajo de la mesa, por un momento, ves una tercera pierna. Se esconde rápido." },
			} },
			Descubiertos = { Lines = {
				{ S = "Narrador", T = "Adrián y Luca te miran con la boca abierta. «¿NOSOTROS?». Mientras tanto, los dos invitados raros intentan escaparse detrás de la mesa de la pizza.", If = { Choices = { Acusar = "Mal" } } },
				{ S = "Julia", T = "¡Espera! ¡Mira a esos dos! ¡Les está saliendo una antena por la oreja!", If = { Choices = { Acusar = "Mal" } } },
				{ S = "Impostor1", T = "¡Nos ha descubierto el compañero humano! ¡Plan B! ¡Copiar su cara y quedarnos con su vida humana!" },
				{ S = "Impostor2", T = "¡Tiene una cara muy copiable! ¡A por la cara!" },
			} },
			Final = { Lines = {
				{ S = "Julia", T = "¿Qué acaba de pasar? No. No me lo expliques. Voy a poner esto en la lista de «cosas que pasan en la universidad y nadie te avisa»." },
				{ S = "Luca", T = "Se les han caído unas gafas. Dice la etiqueta: «Gafas de ver impostores — prohibidas en la Tierra». Tú las mereces más que nadie." },
				{ S = "Adrian", T = "Y la próxima vez que me acuses de alienígena, me avisas antes. Para prepararme el papel.", If = { Choices = { Acusar = "Mal" } } },
				{ S = "Narrador", T = "Recibes 🕶️ las Gafas de ver impostores." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- U5 · El examen del universo
	---------------------------------------------------------------------
	{
		Id = "Loco_U5_Examen",
		Kind = "Side",
		Title = "El examen del universo",
		Description = "En la biblioteca el tiempo se congela. Todos quietos. Todos menos tú. Y un ser que brilla y lleva una carpeta.",
		Type = "Misión loca · Universidad (5/5)",
		Duration = { 15, 22 },
		Npcs = { "Evaluador", "Lapiz1", "Lapiz2", "Lapiz3" },
		Offer = { Place = "Biblioteca" },
		OfferKey = "En la biblioteca, el reloj se ha parado. Y la gente también. ¿Qué está pasando?",
		Requires = { Stage = { Min = "AdultoJoven", Max = "AdultoJoven" }, Completed = { "Loco_U1_Monte" } },
		Moment = "La Tierra aprobó el examen del universo gracias a ti",
		Memory = "ExamenUniverso",
		Rewards = { Items = { DiplomaUniverso = 1 }, Traits = { Curiosidad = 1 } },
		Steps = {
			{ Type = "Talk", Npc = "Evaluador", Dialogue = "Presentacion", Text = "Habla con el ser que brilla",
				Actors = { { Npc = "Evaluador", Place = "Biblioteca", Offset = V(0, 0, 5) } } },
			{ Type = "MiniGame", Game = "Timing", Title = "Prueba 1: atrapa las estrellas fugaces", Icon = "🌠", Hint = "Pulsa justo cuando pasan",
				Rounds = 5, Need = 3, Zone = 0.24, Speed = 1.1,
				Win = { Flags = { "Prueba1Bien" } }, Lose = { Traits = { Humor = 1 } },
				Actors = { { Npc = "Evaluador", Place = "Biblioteca", Offset = V(0, 0, 5) } } },
			{ Type = "Talk", Npc = "Evaluador", Dialogue = "Prueba2", Text = "Prueba 2: una pregunta difícil",
				Actors = { { Npc = "Evaluador", Place = "Biblioteca", Offset = V(0, 0, 5) } } },
			{ Type = "Fight", Place = "Biblioteca", Respawn = "Biblioteca", Action = "Responder bien 🧠", HP = 2, BeamColor = Color3.fromRGB(200, 120, 255),
				Text = "Prueba 3: los exámenes sorpresa te persiguen. ¡Respóndelos! ({count}/{total})",
				CaughtLine = "¡SUSPENSO! …Es broma. Tienes otra oportunidad. Vuelve a empezar.",
				Actors = { { Npc = "Evaluador", Place = "Biblioteca", Offset = V(0, 0, 8) } },
				Enemies = {
					{ Npc = "Lapiz1", Offset = V(-8, 0, -4), Speed = 11, Hurt = "¡Correcto! ¡Grrr!", Bye = "¡Aprobado! (El lápiz se afila solo hasta desaparecer.)" },
					{ Npc = "Lapiz2", Offset = V(8, 0, -4), Speed = 11, Hurt = "¡Esa respuesta tiene buena letra!", Bye = "¡Aprobado con nota! (Se borra a sí mismo.)" },
					{ Npc = "Lapiz3", Offset = V(0, 0, -10), Speed = 13, HP = 3, Hurt = "¡No se puede responder tan rápido! ¡Es trampa!", Bye = "¡Nunca había corregido un examen perfecto! (Se rompe la punta de la emoción.)" },
				} },
			{ Type = "Scene", Dialogue = "Nota", Actors = { { Npc = "Evaluador", Place = "Biblioteca", Offset = V(0, 0, 5) } } },
		},
		Dialogues = {
			Presentacion = { Lines = {
				{ S = "Evaluador", T = "{Saludo}, humano. Soy El Evaluador. Cada mil años examino a un planeta para ver si pasa de curso o repite." },
				{ S = "Evaluador", T = "Examino a un solo habitante al azar. Esta vez el azar ha elegido… a alguien que estaba subrayando con un fosforito sin tapa. A ti." },
				{ S = "Yo", T = "¿Y si suspendo?" },
				{ S = "Evaluador", T = "Si suspendes, la Tierra repite curso. Vuelta a los dinosaurios. Nada personal. Es burocracia cósmica." },
				{ S = "Evaluador", T = "Tres pruebas. Reflejos, juicio y valor. Sin chuletas. Puedes usar calculadora, eso sí. Soy exigente, no un monstruo." },
			} },
			Prueba2 = { Lines = {
				{ S = "Evaluador", T = "Prueba dos. Hay un botón. Si lo pulsas, todos los humanos de la Tierra reciben un helado gratis cada día… pero tu vecino Cosme se convierte en pato. Para siempre." },
				{ Ask = "¿Pulsas el botón?", Options = {
					{ T = "«No. Cosme es insoportable, pero es MI vecino insoportable.»", Effects = { Traits = { Empatia = 2 }, Rel = { Cosme = 5 }, Flags = { "SalvasteACosme" } }, Then = {
						{ S = "Evaluador", T = "Lealtad por encima del helado. Interesante. Muy poco frecuente en los humanos." },
					} },
					{ T = "«¿De qué sabor es el helado?»", Effects = { Traits = { Humor = 1 } }, Then = {
						{ S = "Evaluador", T = "Vainilla. …Tu cara dice que la respuesta es «no». Anotado. Pregunta trampa superada." },
					} },
					{ T = "«Preguntaría a Cosme. A lo mejor le hace ilusión ser pato.»", Effects = { Traits = { Curiosidad = 1, Responsabilidad = 1 } }, Then = {
						{ S = "Evaluador", T = "Consultar al afectado. Nadie lo había hecho en diez mil años. …Por cierto, sí le haría ilusión. Pero no se lo digas." },
					} },
				} },
			} },
			Nota = { Lines = {
				{ S = "Evaluador", T = "Resultado final: la Tierra… aprueba. Por los pelos. Muy por los pelos. Un cinco raspado." },
				{ S = "Evaluador", T = "Pero en la casilla de «actitud» he puesto un diez. Eso se lo debéis a ti. Enhorabuena. Hasta dentro de mil años." },
				{ S = "Narrador", T = "El tiempo vuelve a moverse. Nadie en la biblioteca se ha enterado de nada. Sobre tu mesa hay un pergamino que brilla." },
				{ S = "Narrador", T = "Recibes 📜 el Diploma del Universo." },
			} },
		},
	},
}
