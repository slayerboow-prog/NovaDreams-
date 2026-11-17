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
		Description = "Meses sin Cosme. Pip mantiene el garaje como lo dejó, por si vuelve. Cosme dejó instrucciones por si le pasaba algo. Hay que traerle de vuelta.",
		Type = "Saga de la Grieta · Acto III (1/6)",
		Duration = { 25, 35 },
		Npcs = { "Pip", "DonEscamas", "Sorel", "Brenn" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip te abre la puerta del garaje de Cosme: «Tenemos que hablar»",
		Requires = after("Saga_12_Graduacion"),
		Moment = "Formaste el equipo de rescate",
		Memory = "EquipoRescate",
		Rewards = { Items = { CuadernoCosme = 1 }, Flags = { "EquipoRescate", "CompisSabenGrieta" } },
		Props = {
			Cuaderno = { Kind = "Libro", Name = "El cuaderno de Cosme", Prompt = "Leer el cuaderno", Place = "GarajeCosme", Offset = V(-2, 0, 3), Color = Color3.fromRGB(120, 60, 40), Dialogue = "Cuaderno", Once = true },
			Mando = { Kind = "Maquina", Name = "El mando de salto entre dimensiones", Prompt = "Coger el mando", Place = "GarajeCosme", Offset = V(2, 0, 3), Color = Color3.fromRGB(90, 255, 110), Dialogue = "Mando", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Pip", Text = "Habla con Pip", Actors = { PIP, ESCAMAS } },
			{ Type = "Group", Text = "Busca en el garaje lo que dejó Cosme", Actors = { PIP, ESCAMAS },
				Steps = {
					{ Type = "Use", Prop = "Cuaderno", Text = "Su cuaderno" },
					{ Type = "Use", Prop = "Mando", Text = "El mando del banco de trabajo" },
				} },
			{ Type = "Talk", Npc = "Sorel", Dialogue = "Equipo", Text = "Ve a la Academia: necesitas un equipo",
				Actors = {
					{ Npc = "Brenn", Place = "Pista", Offset = V(-3, 0, 2) },
					{ Npc = "Sorel", Place = "Pista", Offset = V(3, 0, 2) },
				} },
			{ Type = "Scene", Dialogue = "Plan", Actors = { PIP, ESCAMAS, { Npc = "Brenn", Place = "GarajeCosme", Offset = V(-4, 0, 5) }, { Npc = "Sorel", Place = "GarajeCosme", Offset = V(4, 0, 5) } } },
		},
		Dialogues = {
			Pip = { Lines = {
				{ S = "Pip", T = "{Saludo}. Llevo cuatrocientos doce días limpiando el polvo del garaje. Por si vuelve.", Shot = "Medio:Pip", A = "Sad" },
				{ S = "Pip", T = "Tiene que encontrarlo limpio. Si no, se queja.", Beat = "Baja" },
				-- Desde la graduación (Saga_12), el garaje no ha vuelto a oler a batido de apio
				{ S = "Pip", T = "Desde su ceremonia, el garaje está en silencio. Nunca pensé que echaría de menos sus explosiones.", If = { Memories = { "GraduacionInterdimensional" } } },
				{ S = "DonEscamas", T = "He calculado nuestras posibilidades de rescatarle sin ayuda: un 3 %. Con ayuda: un 4 %.", Shot = "Medio:DonEscamas" },
				{ S = "DonEscamas", T = "Pero con amigos, las matemáticas cambian.", Pause = 0.6, To = "Yo" },
				-- Le sacaste del estanque en un cubo (Saga_03)
				{ S = "DonEscamas", T = "Usted me sacó del parque delante del Consorcio. Ahora me toca a mí ayudar a sacar a alguien.", If = { Memories = { "DonEscamas" } } },
				{ S = "Pip", T = "El señor dejó dicho que usted sabría qué hacer. Yo creo que lo dijo por decir. Pero aquí estamos.", To = "Yo" },
				-- La credencial de ayudante oficial (Saga_07)
				{ S = "Pip", T = "Además, tiene la credencial del laboratorio. Eso le convierte en responsable en su ausencia.", If = { Flags = { "AyudanteOficial" } }, G = "Nod" },
			} },
			Cuaderno = { Lines = {
				{ S = "Narrador", T = "El cuaderno de Cosme, lleno de dibujos y coordenadas. En la última página, escrito deprisa: «Si me pasa algo:»." },
				{ S = "Narrador", T = "«1) G-4 (gatos): Bigotes sabe dónde está la 66-B. 2) La Capitana Ñoz tiene cámaras en todas las dimensiones»." },
				{ S = "Narrador", T = "«3) NO dejar que la criatura vaya sola».", Pause = 0.6 },
				{ S = "Narrador", T = "Debajo, más pequeño: «Dile que estoy orgulloso. Por si acaso». Lo ha tachado. Pero se lee.", Pause = 1 },
			} },
			Mando = { Lines = {
				{ S = "Narrador", T = "Un mando de dimensiones a medio montar. Pip lo termina en diez minutos." },
				{ S = "Pip", T = "El señor lo dejó casi hecho. Siempre deja las cosas casi hechas.", A = "Sad" },
			} },
			Equipo = { Lines = {
				{ S = "Sorel", T = "Cosme está al otro lado de la Grieta, con la otra versión de sí mismo. Y hay que ir a buscarle.", Shot = "Medio:Sorel" },
				{ S = "Brenn", T = "Sin permiso de la Academia, sin refuerzos y sin saber qué hay allí. Me apunto." },
				{ S = "Sorel", T = "Yo también. Le debo una por lo de la feria. Y tú me sacaste del campus." },
			} },
			Plan = { Lines = {
				{ S = "Candela", T = "Plan: uno, la dimensión de los gatos. Dos, una capitana alienígena con cámaras. Tres, rescate.", Shot = "General", G = "Point" },
				{ S = "Candela", T = "Cuatro, volver a tiempo para el examen de Beltrán. El punto cuatro no es negociable.", Beat = "Mira", To = "Ivan" },
				{ S = "Ivan", T = "Yo me pido llevar el mando. …Vale, no. Yo me pido llevar la merienda.", A = "Shrug" },
				{ S = "Pip", T = "Iré con ustedes. El señor Cosme me dijo «no dejes a la criatura sola».", Shot = "Medio:Pip" },
				{ S = "Pip", T = "Por una vez, voy a obedecer sin rechistar.", Pause = 0.5, G = "Nod" },
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
		Title = "El refugio de G-4",
		Description = "Primera parada: G-4, el último refugio del pueblo de Bigotes, una especie felina que perdió su mundo por culpa del Consorcio.",
		Type = "Saga de la Grieta · Acto III (2/6)",
		Duration = { 20, 30 },
		Npcs = { "Bigotes", "GatoPolicia1", "GatoPolicia2", "Brenn", "Sorel" },
		Offer = { Place = "Parque" },
		OfferKey = "Pip ha abierto un portal en el parque hacia G-4",
		Requires = after("Saga_13_SinCosme"),
		Moment = "Pediste ayuda a Bigotes en el refugio de G-4",
		Memory = "PresidenteBigotes",
		Rewards = { Items = { CollarDiplomatico = 1 }, Flags = { "CoordenadasCosimo" } },
		Props = {
			Portal = { Kind = "Portal", Name = "Portal a la dimensión G-4", Place = "Parque", Offset = V(0, 0, 8), Prompt = false },
		},
		Steps = {
			{ Type = "Transition", Text = "Cruzas el portal. Las mismas calles de Valmar, llenas de tiendas de refugiados felinos altos como personas.", Seconds = 5, Teleport = "Parque" },
			{ Type = "Escape", Place = "PlazaCentro", Respawn = "Parque", Catch = 4, Props = { "Portal" },
				Text = "Los guardias felinos te toman por una amenaza: llega a la plaza sin pelear con ellos",
				CaughtLine = "(Te reducen y te devuelven al portal. Lo intentas de nuevo.)",
				Actors = {
					{ Npc = "Brenn", Mode = "Follow" },
					{ Npc = "Sorel", Mode = "Follow" },
					{ Npc = "GatoPolicia1", Place = "Parque", Offset = V(-10, 0, 6), Mode = "Hunt", Speed = 12, Prompt = false },
					{ Npc = "GatoPolicia2", Place = "Parque", Offset = V(10, 0, 6), Mode = "Hunt", Speed = 11, Prompt = false },
				} },
			{ Type = "Talk", Npc = "Bigotes", Dialogue = "Presidente", Text = "Habla con Bigotes, el líder de G-4",
				Actors = {
					{ Npc = "Bigotes", Place = "PlazaCentro", Offset = V(0, 0, 5) },
					{ Npc = "Brenn", Place = "PlazaCentro", Offset = V(-4, 0, 8) },
					{ Npc = "Sorel", Place = "PlazaCentro", Offset = V(4, 0, 8) },
				} },
		},
		Dialogues = {
			Presidente = { Lines = {
				{ S = "Bigotes", T = "Así que has llegado. Este es mi cuerpo de verdad. Mi pueblo me eligió para guiarle después de perder nuestro mundo." },
				{ S = "Sorel", T = "Buscamos la dimensión 66-B. Se han llevado a Cosme.", To = "Bigotes" },
				{ S = "Bigotes", T = "Te daré las coordenadas. Su laboratorio en tu mundo está bajo el campus abandonado.", Shot = "Medio:Bigotes" },
				{ S = "Bigotes", T = "Toma este collar: la señal de mi pueblo. En cualquier refugio de los míos te abrirán la puerta." },
				{ S = "Narrador", T = "Recibes 📿 el collar de G-4. Primera pieza del rescate: las coordenadas." },
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
		Title = "La capitana Ñoz",
		Description = "Para entrar en la 66-B hay que saber dónde está el laboratorio de Cósimo. La capitana Ñoz, una contrabandista que espía entre dimensiones, aterriza esta noche en el Monte del Silencio.",
		Type = "Saga de la Grieta · Acto III (3/6)",
		Duration = { 20, 30 },
		Npcs = { "CapitanNoz", "Blorp", "Zarg", "Brenn", "Sorel" },
		Offer = { Place = "MonteSilencio" },
		OfferKey = "Una nave ha aterrizado en el Monte del Silencio: la de la capitana Ñoz",
		Requires = after("Saga_14_Bigotes", { Hours = { From = 21, To = 5 } }),
		Moment = "Hiciste de antena para la nave de la capitana Ñoz",
		Memory = "EpisodioEspecial",
		Rewards = { Items = { PaseVIP = 1 }, Flags = { "GrabacionLaboratorio" } },
		Props = {
			Nave = { Kind = "Nave", Name = "La nave de la capitana Ñoz", Place = "MonteSilencio", Offset = V(0, 0, -8), Height = 20, Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "CapitanNoz", Dialogue = "Capitana", Text = "Habla con la Capitana Ñoz junto a su nave, en el monte",
				Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3) },
					{ Npc = "Blorp", Place = "MonteSilencio", Offset = V(-4, 0, 2), Mode = "Chat" },
					{ Npc = "Brenn", Place = "MonteSilencio", Offset = V(-3, 0, 8) },
					{ Npc = "Sorel", Place = "MonteSilencio", Offset = V(3, 0, 8) },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Afinar los sensores", Icon = "📡", Hint = "Empuja con tu resonancia justo cuando se enciende la luz roja",
				Rounds = 5, Need = 3, Zone = 0.26, Speed = 1,
				Win = { Flags = { "BuenRodaje" }, Traits = { Valentia = 1 } }, Lose = { Traits = { Responsabilidad = 1 } },
				Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3), Mode = "Point" },
					{ Npc = "Zarg", Place = "MonteSilencio", Offset = V(4, 0, 2) },
				} },
			{ Type = "Scene", Dialogue = "Grabacion", Props = { "Nave" },
				Actors = {
					{ Npc = "CapitanNoz", Place = "MonteSilencio", Offset = V(0, 0, 3) },
					{ Npc = "Brenn", Place = "MonteSilencio", Offset = V(-3, 0, 8) },
					{ Npc = "Sorel", Place = "MonteSilencio", Offset = V(3, 0, 8) },
				} },
		},
		Dialogues = {
			Capitana = { Lines = {
				{ S = "CapitanNoz", T = "Mi nave ve a través de las grietas. ¿El laboratorio de Cósimo? Lo tengo, con imagen y sonido.", Shot = "Medio:CapitanNoz" },
				{ S = "CapitanNoz", T = "Pero no regalo nada. Tu resonancia de Ancla puede afinar mis sensores. Ese es el precio.", To = "Yo" },
			} },
			Grabacion = { Lines = {
				{ S = "CapitanNoz", T = "Señal limpia. Aquí lo tienes.", If = { Flags = { "BuenRodaje" } } },
				{ S = "CapitanNoz", T = "Señal sucia, pero suficiente. Aquí lo tienes.", IfNot = { Flags = { "BuenRodaje" } } },
				{ S = "Narrador", T = "Un laboratorio bajo un campus. En una cápsula de cristal, dormido y con cables en la cabeza, está Cosme." },
				{ S = "Brenn", T = "Está vivo. Eso es lo que importa.", Shot = "Reaccion:Brenn" },
				{ S = "CapitanNoz", T = "Te dejo mi frecuencia. Si salís vivos, avísame. Esa historia también valdrá mucho." },
				{ S = "Narrador", T = "Recibes 🎫 la frecuencia de Ñoz. Segunda pieza del rescate: la imagen del laboratorio." },
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
		Description = "La Valmar de la 66-B: la misma ciudad, gris y controlada por el Consorcio. Allí vive otra versión de ti a la que nadie salvó.",
		Type = "Saga de la Grieta · Acto III (4/6)",
		Duration = { 25, 35 },
		Npcs = { "TuMalvado", "Brenn", "Sorel", "Pip", "DronCosimo1", "DronCosimo2" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip ha calibrado el mando con las coordenadas. El portal a la 66-B está abierto en el garaje",
		Requires = after("Saga_15_Reestreno"),
		Moment = "Entraste en la Valmar de la 66-B",
		Memory = "Dimension66B",
		Rewards = { Items = { MapaMalvado = 1 }, Flags = { "ConoceTuMalvado" } },
		Props = {
			Portal = { Kind = "Portal", Name = "Portal a la 66-B", Place = "GarajeCosme", Offset = V(0, 0, -5), Color = Color3.fromRGB(180, 40, 70), Prompt = false },
			Cartel = { Kind = "Mural", Name = "Un cartel: «Cósimo. Orden. Futuro.»", Prompt = "Mirar el cartel", Place = "PlazaCentro", Offset = V(0, 0, 8), Color = Color3.fromRGB(150, 30, 50), Dialogue = "Cartel", Once = true },
			Rejilla = { Kind = "Maquina", Name = "Una rejilla de ventilación con vapor verde", Prompt = "Mirar por la rejilla", Place = "OficinasFinanciero", Offset = V(6, 0, 4), Dialogue = "Rejilla", Once = true },
		},
		Steps = {
			{ Type = "Transition", Text = "La Valmar de la 66-B: cielo de ceniza, altavoces del Consorcio en cada esquina y gente que camina sin mirar arriba.", Seconds = 5, Teleport = "PlazaCentro" },
			{ Type = "Use", Prop = "Cartel", Text = "Mira a tu alrededor en la plaza", Actors = EQUIPO },
			{ Type = "Talk", Npc = "TuMalvado", Dialogue = "Malvado", Text = "Habla con tu otra versión en el banco de la plaza",
				Actors = {
					{ Npc = "TuMalvado", Place = "PlazaCentro", Offset = V(4, 0, 4) },
					{ Npc = "Brenn", Place = "PlazaCentro", Offset = V(-3, 0, 6) },
					{ Npc = "Sorel", Place = "PlazaCentro", Offset = V(-1, 0, 7) },
				} },
			{ Type = "Escape", Place = "OficinasFinanciero", Respawn = "PlazaCentro", Catch = 4,
				Text = "Los drones del Consorcio os han detectado: corre hasta la torre del Distrito Financiero",
				CaughtLine = "(Un disparo aturdidor te tumba. Sorel te arrastra de vuelta a la plaza.)",
				Actors = {
					{ Npc = "Brenn", Mode = "Follow" },
					{ Npc = "Sorel", Mode = "Follow" },
					{ Npc = "DronCosimo1", Place = "PlazaCentro", Offset = V(-12, 0, 6), Mode = "Hunt", Speed = 12, Prompt = false },
					{ Npc = "DronCosimo2", Place = "PlazaCentro", Offset = V(12, 0, 6), Mode = "Hunt", Speed = 12, Prompt = false },
				} },
			{ Type = "Use", Prop = "Rejilla", Text = "Busca la entrada al laboratorio, bajo la torre", Actors = EQUIPO },
		},
		Dialogues = {
			Cartel = { Lines = {
				{ S = "Narrador", T = "«Cósimo. Orden. Futuro.» Debajo, alguien ha escrito con pintura: «Lía vive»." },
				{ S = "Sorel", T = "Aquí también la conocían. Y alguien todavía se acuerda de ella." },
			} },
			Malvado = { Lines = {
				{ S = "TuMalvado", T = "Así que eres tú. La versión a la que sacaron del laboratorio. A mí nadie me sacó.", Shot = "Medio:TuMalvado" },
				{ S = "TuMalvado", T = "Cósimo me encontró y me dio un techo. Le debo la vida, aunque sea esta vida." },
				{ Ask = "¿Qué le dices a tu otra versión?", Options = {
					{ T = "«Ayúdanos. No tienes por qué seguir con él.»", Effects = { Flags = { "MalvadoAyudo" }, Traits = { Empatia = 1 } }, Then = {
						{ S = "TuMalvado", T = "…Nadie me había preguntado eso nunca. La entrada está bajo la torre del Consorcio. Yo no os lo he dicho." },
					} },
					{ T = "«No me fío de ti.»", Effects = { Traits = { Valentia = 1 } }, Then = {
						{ S = "TuMalvado", T = "Haces bien. Yo tampoco me fío de mí. Pero la rejilla de la torre echa vapor verde. Por si te interesa." },
					} },
				} },
				{ S = "TuMalvado", T = "Si Cósimo gana, tu Valmar será como esta. Piénsalo antes de fallar." },
			} },
			Rejilla = { Lines = {
				{ S = "Narrador", T = "Por la rejilla sale vapor verde. Abajo hay un pasillo largo iluminado en blanco." },
				{ S = "Sorel", T = "Es el pasillo de la imagen de Ñoz. Las mismas luces.", If = { Flags = { "GrabacionLaboratorio" } }, Shot = "Medio:Sorel" },
				{ S = "Pip", T = "(Por el comunicador) Coordenadas confirmadas. Descansen esta noche. Mañana entramos." },
				{ S = "Narrador", T = "Recibes 🗺️ el mapa de la 66-B, dibujado por Sorel." },
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
		Description = "Bajo la torre del Consorcio en la 66-B, en una cápsula de cristal, duerme Cosme. Entre él y tú: guardias, robots y drones.",
		Type = "Saga de la Grieta · Acto III (5/6)",
		Duration = { 30, 40 },
		Npcs = { "Cosme", "Cosimo", "RobotSeguridad", "DronCosimo1", "DronCosimo2", "DronCosimo3", "Brenn", "Sorel", "Pip" },
		Offer = { Place = "OficinasFinanciero" },
		OfferKey = "La rejilla del laboratorio de Cósimo. Tu equipo está listo",
		Requires = after("Saga_16_66B"),
		Moment = "Rescataste a Cosme",
		Memory = "RescateCosme",
		Rewards = { Unflags = { "CosmeSecuestrado" }, Flags = { "CosmeRescatado", "CosmeSinMemoria" } },
		Props = {
			Capsula = { Kind = "Huevo", Name = "La cápsula de cristal", Prompt = "Abrir la cápsula", Place = "OficinasFinanciero", Offset = V(0, 0, -10), Color = Color3.fromRGB(180, 230, 255), Dialogue = "Capsula", Once = true },
		},
		Steps = {
			{ Type = "Fight", Place = "OficinasFinanciero", Respawn = "OficinasFinanciero", Action = "Desconectar ⚡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160),
				Text = "El pasillo del laboratorio está lleno de guardias: pelea y desconéctalos ({count}/{total})",
				CaughtLine = "(Un guardia te inmoviliza. Sorel tira de ti hacia atrás.)",
				Actors = EQUIPO,
				Enemies = {
					{ Npc = "RobotSeguridad", Offset = V(-6, 0, -4), Speed = 10, HP = 4, Bye = "(Se apaga.)" },
					{ Npc = "DronCosimo1", Offset = V(6, 0, -4), Speed = 13, Bye = "(Cae entre chispas.)" },
					{ Npc = "DronCosimo2", Offset = V(0, 0, -8), Speed = 13, Bye = "(Su núcleo se apaga.)" },
				} },
			{ Type = "Use", Prop = "Capsula", Text = "Abre la cápsula de Cosme", Actors = EQUIPO },
			{ Type = "Escape", Place = "GarajeCosme", Respawn = "OficinasFinanciero", Catch = 4,
				Text = "Alarma: vuelve con Cosme al portal del garaje",
				CaughtLine = "(El dron te atrapa. Pip le dispara un pulso y te suelta.)",
				Actors = {
					{ Npc = "Cosme", Mode = "Follow" },
					{ Npc = "Brenn", Mode = "Follow" },
					{ Npc = "Sorel", Mode = "Follow" },
					{ Npc = "DronCosimo3", Place = "OficinasFinanciero", Offset = V(0, 0, 12), Mode = "Hunt", Speed = 13, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Casa",
				Actors = {
					{ Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3), Mode = "Sit" },
					PIP, ESCAMAS,
					{ Npc = "Brenn", Place = "GarajeCosme", Offset = V(-4, 0, 5) },
					{ Npc = "Sorel", Place = "GarajeCosme", Offset = V(4, 0, 5) },
				} },
		},
		Dialogues = {
			Capsula = { Lines = {
				{ S = "Narrador", T = "La cápsula se abre con un silbido. Cosme abre los ojos y te mira mucho rato." },
				{ S = "Cosme", T = "…Te conozco. Eres…", Shot = "PrimerPlano:Cosme", Pause = 0.8 },
				{ S = "Narrador", T = "En una pantalla de la pared: «Recuerdos extraídos: 87 %».", Pause = 0.8 },
				{ S = "Sorel", T = "Le ha estado vaciando la memoria. Para saber cómo soltar el Ancla.", Shot = "Reaccion:Sorel" },
				{ S = "Cosimo", T = "(Por los altavoces) Llegáis tarde. Ya sé casi todo lo que él sabía. Lo que queda, os lo podéis llevar." },
				{ S = "Brenn", T = "Tu otra versión no mentía: la rejilla llevaba justo aquí.", If = { Flags = { "MalvadoAyudo" } }, To = "Yo" },
				{ S = "Sorel", T = "Ya nos ocuparemos de su memoria. Primero, salir.", G = "Point" },
			} },
			Casa = { Lines = {
				{ S = "Pip", T = "Señor. Ha vuelto.", Shot = "Medio:Pip", To = "Cosme" },
				{ S = "Cosme", T = "¿Eres mi asistente? Perdona. No… no recuerdo tu nombre.", To = "Pip" },
				{ S = "Pip", T = "Pip, señor. Me llamo Pip. Usted me construyó.", Pause = 1 },
				{ S = "DonEscamas", T = "Los recuerdos no se borran del todo. Se esconden. Lo sé por experiencia.", To = "Yo" },
				{ S = "Narrador", T = "Cosme está en casa. Pero no sabe quién eres." },
				{ S = "Cosme", T = "(Medio dormido, bajo la manta que le pone Pip) …Lía.", Shot = "PrimerPlano:Cosme", Pause = 1.5 },
				{ S = "Narrador", T = "Solo eso. Luego se duerme.", Pause = 0.8 },
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
				{ S = "Cosimo", T = "(En todas las pantallas) ¡{Saludo}, Valmar! Tengo un anuncio. La Gran Fusión se celebrará en el Monte del Silencio." },
				{ S = "Cosimo", T = "(En todas las pantallas) Cuando el Ancla ya no sea una criatura, sino una persona adulta con trabajo y facturas.", Shot = "Reaccion:Pip" },
				{ S = "Cosimo", T = "(En todas las pantallas) Porque los adultos, querido público, están tan cansados que sueltan cualquier cosa. Hasta un universo." },
				{ S = "Cosimo", T = "(En todas las pantallas) ¡No se lo pierdan! Entradas a la venta en MegaVerso.", Shot = "Reaccion:Cosme" },
				{ S = "Pip", T = "Nos da tiempo. Años.", Pause = 1, Shot = "Medio:Pip", To = "Yo" },
				{ S = "Pip", T = "Tiempo para que el señor recupere la memoria. Y para prepararnos.", Beat = "Mira", To = "Cosme" },
			}, Effects = { Scene = "Grieta_Inminente" } }, -- (el cielo truena, como si lo hubiera oído: antesala de la etapa 6)
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
				{ S = "Narrador", T = "Candela hace una foto: Cosme en la puerta del garaje, con cara de no entender nada, y tú a su lado." },
				{ S = "Narrador", T = "Iván sale en una esquina comiendo moras." },
				{ S = "Narrador", T = "Recibes 📸 la foto «Cosme sin memoria». FIN DEL ACTO III." },
				{ S = "Narrador", T = "Cosme está en casa. Faltan sus recuerdos. Y falta la Gran Fusión.", Pause = 1 },
			} },
		},
	},
}
