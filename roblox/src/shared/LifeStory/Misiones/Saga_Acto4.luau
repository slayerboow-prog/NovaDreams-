-- SAGA DE LA GRIETA · ACTO IV «La Gran Fusión» (vida adulta). Misiones CANÓNICAS: siempre en el mapa.
-- El final de toda la historia. Plan: docs/historia/13-saga-de-la-grieta.md
--
--   19 Saga_19_Recuerdos «Recuerdos de tostadora»   devolverle a Cosme sus recuerdos con lo que vivisteis juntos
--   20 Saga_20_Aliados   «Todos los aliados»        vuelven los que ayudaste en toda tu vida (según lo que hiciste)
--   21 Saga_21_Consorcio «La caída del Consorcio»   asalto a MegaVerso con la contabilidad de Don Escamas
--   22 Saga_22_Ancla     «El Ancla»                 Cósimo te ofrece un trato: tu vida perfecta a cambio de soltar el ancla
--   23 Saga_23_Fusion    «La Gran Fusión»           la batalla final en el Monte del Silencio
--   24 Saga_24_Final     «Coser el cielo (de verdad)»  epílogo: la Grieta se cierra para siempre

local V = Vector3.new

local function after(id: string, extra: { [string]: any }?): { [string]: any }
	local req = { Stage = { Min = "Adulto" }, Completed = { id } }
	for key, value in extra or {} do
		req[key] = value
	end
	return req
end

local COSME = { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) }
local PIP = { Npc = "Pip", Place = "GarajeCosme", Offset = V(3, 0, 2) }
local ESCAMAS = { Npc = "DonEscamas", Place = "GarajeCosme", Offset = V(-3, 0, 1), Scale = 0.35 }
local CIMA = "CimaMonte"
-- Colección «Restos de la Grieta» (recuerdos de las rarezas): con 4 o más, Cósimo llega debilitado a la batalla final
local RESTOS = { "BuzonPasado", "FarolaOpera", "PerroBinario", "LluviaEspaguetis", "Piso13", "RelojAtras", "SemaforoOpina", "NubePerdida" }
local MUCHOS_RESTOS = { MemoriesAtLeast = { N = 4, Of = RESTOS } }
local POCOS_RESTOS = { MemoriesFewer = { N = 4, Of = RESTOS } }

-- Aliados en la batalla final: solo vienen los que ayudaste (marcas de las misiones de toda tu vida)
local ALIADOS_FINAL = {
	{ Npc = "Ivan", Place = CIMA, Offset = V(-8, 0, 8), Mode = "Cheer" },
	{ Npc = "Candela", Place = CIMA, Offset = V(8, 0, 8), Mode = "Cheer" },
	{ Npc = "Pip", Place = CIMA, Offset = V(0, 0, 10), Mode = "Cheer" },
	{ Npc = "CazadorTiempo", Place = CIMA, Offset = V(-12, 0, 4), Mode = "Point", If = { Flags = { "CronosAliado" } } },
	{ Npc = "Bigotes", Place = CIMA, Offset = V(12, 0, 4), If = { Flags = { "AliadoBigotes" } } },
	{ Npc = "Rex", Place = CIMA, Offset = V(-14, 0, 10), Mode = "Cheer", If = { Flags = { "AliadoRex" } } },
	{ Npc = "RatonPerez", Place = CIMA, Offset = V(14, 0, 10), If = { Flags = { "AliadoPerez" } } },
	{ Npc = "Gnomo1", Place = CIMA, Offset = V(-4, 0, 12), If = { Flags = { "AliadoGnomos" } } },
	{ Npc = "TuMalvado", Place = CIMA, Offset = V(4, 0, 12), If = { Flags = { "AliadoMalvado" } } },
	{ Npc = "CapitanNoz", Place = CIMA, Offset = V(0, 0, 14), Mode = "Wave" },
}

return {
	---------------------------------------------------------------------
	-- 19 · Recuerdos de tostadora
	---------------------------------------------------------------------
	{
		Id = "Saga_19_Recuerdos",
		Kind = "Side",
		Canon = true,
		Title = "Recuerdos de tostadora",
		Description = "Cosme sigue sin recordar casi nada. Pip tiene una idea: llevarle a los sitios donde vivisteis cosas juntos. Los recuerdos, dice Pip, se quedan pegados a los sitios.",
		Type = "Saga de la Grieta · Acto IV (1/6)",
		Duration = { 30, 40 },
		Npcs = { "Cosme", "Pip", "Julian" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip te espera con Cosme y una lista: «Sitios donde el señor fue feliz»",
		Requires = after("Saga_18_Precio"),
		Moment = "Cosme recuperó sus recuerdos",
		Memory = "CosmeRecuerda",
		Rewards = { Unflags = { "CosmeSinMemoria" }, Flags = { "CosmeRecuerda" }, Items = { AlbumRecuerdos = 1 } },
		Props = {
			Microondas = { Kind = "Maquina", Name = "El microondas temporal (reparado por Pip)", Prompt = "Calentar un bocadillo", Place = "GarajeCosme", Offset = V(-3, 0, 0), Dialogue = "Microondas", Once = true },
			Gallinero = { Kind = "Huevo", Name = "El gallinero de Petra", Prompt = "Enseñarle a Petra", Place = "GranjaGranero", Offset = V(4, 0, 4), Dialogue = "Gallina", Once = true },
			Cielo = { Kind = "Cristal", Name = "El viejo anclaje del parque", Prompt = "Tocar el anclaje", Place = "Parque", Offset = V(0, 0, 8), Dialogue = "Anclaje", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Lista", Text = "Habla con Pip", Actors = { COSME, PIP, ESCAMAS } },
			{ Type = "Group", Text = "Lleva a Cosme a los sitios de vuestros recuerdos",
				Actors = { { Npc = "Cosme", Mode = "Follow" }, { Npc = "Julian", Place = "GranjaGranero", Offset = V(-3, 0, 3) } },
				Steps = {
					{ Type = "Use", Prop = "Microondas", Text = "El garaje: el microondas temporal" },
					{ Type = "Use", Prop = "Gallinero", Text = "La granja de Villaverde: Petra" },
					{ Type = "Use", Prop = "Cielo", Text = "El parque: el anclaje del cielo" },
				} },
			{ Type = "Scene", Dialogue = "Vuelve", Actors = { COSME, PIP, ESCAMAS } },
		},
		Dialogues = {
			Lista = { Lines = {
				{ S = "Pip", T = "He hecho una lista de sitios donde el señor fue feliz. Es corta. El señor no salía mucho. Pero en casi todos estaba usted." },
				{ S = "Cosme", T = "¿Yo fui feliz? ¿En sitios? ¿Con esta cara? Qué raro. Vamos. Pero volvemos pronto: echo de menos una cosa que no sé cuál es." },
				{ S = "DonEscamas", T = "(Desde la pecera) Y si la tostadora con su mente sigue por ahí, que la traiga. Yo nunca tiro una copia de seguridad.", If = { Completed = { "Loco_D3_Tostadora" } } },
			} },
			Microondas = { Lines = {
				{ S = "Narrador", T = "Metes un bocadillo en el microondas temporal. «Ding». Sale caliente… y mordido. Mordido por el Cosme de ayer." },
				{ S = "Cosme", T = "…El martes pasado. Tenía hambre el martes pasado. ¡Me acuerdo del martes pasado! Y de un bocadillo de chorizo. Y de una criatura con las manos llenas de piezas." },
			} },
			Gallina = { Lines = {
				{ S = "Julian", T = "Hombre, Cosme. ¿Vienes a disculparte con Petra? Ya iba siendo hora. Solo han pasado… muchos años." },
				{ S = "Narrador", T = "Petra, la gallina, mira a Cosme. Cosme mira a Petra. Petra le da un picotazo en la rodilla." },
				{ S = "Cosme", T = "¡AY! ¡La gallina! ¡La gallina de seis metros! ¡El rayo agrandador! ¡Tú disparaste con los ojos cerrados! ¡Me acuerdo!" },
				{ S = "Cosme", T = "Y me acuerdo de lo que le dije a la criatura en la furgoneta. Que no era nada. Que esperara al martes en que me convertí en perchero.", If = { Completed = { "Loco_N3_Pollo" } } },
			} },
			Anclaje = { Lines = {
				{ S = "Narrador", T = "El viejo anclaje de cristal, el que clavaste de niño. Todavía brilla un poco. Cosme lo toca." },
				{ S = "Cosme", T = "La noche de la aguja. Coser el cielo. Tú subiste al tejado del cole… no, eso no. Tú clavaste esto. Y yo… yo me sentí tan orgulloso que no supe decírtelo." },
			} },
			Vuelve = { Lines = {
				{ S = "Cosme", T = "Criatura." },
				{ S = "Narrador", T = "Lo dice de otra manera. Como antes. Como siempre." },
				{ S = "Cosme", T = "Me acuerdo. De todo. Del microondas, de las burbujas, del pez, de la cinta, de la cápsula. Me acuerdo de que viniste a por mí a otra dimensión. Con zumo de mora." },
				{ S = "Pip", T = "Señor. Bienvenido. Otra vez. De verdad esta vez." },
				{ S = "Cosme", T = "Y ahora me acuerdo de otra cosa, criatura: de lo que Cósimo me sacó. Cómo soltar el ancla. Lo sabe todo. Viene a por ti. Necesitamos a todo el mundo." },
				{ S = "Narrador", T = "Pip os hace un álbum con fotos de cada sitio. Recibes 📔 el Álbum de recuerdos." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 20 · Todos los aliados
	---------------------------------------------------------------------
	{
		Id = "Saga_20_Aliados",
		Kind = "Side",
		Canon = true,
		Title = "Todos los aliados",
		Description = "Para la Gran Fusión hace falta todo el mundo. Todo el que te ha debido algo alguna vez. Y resulta que es mucha gente. Y muchos gatos. Y un velocirraptor.",
		Type = "Saga de la Grieta · Acto IV (2/6)",
		Duration = { 30, 45 },
		Npcs = { "Ivan", "Candela", "CazadorTiempo", "Bigotes", "Rex", "RatonPerez", "Gnomo1", "TuMalvado" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme ha hecho una lista de aliados. Es larguísima. Y la mitad no son humanos",
		Requires = after("Saga_19_Recuerdos"),
		Moment = "Reuniste a todos tus aliados",
		Memory = "TodosLosAliados",
		Rewards = { Flags = { "AliadosReunidos" } },
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Lista", Text = "Cosme tiene la lista de aliados", Actors = { COSME, PIP } },
			{ Type = "Group", Text = "Visita a tus aliados (vendrán los que ayudaste en tu vida)", Need = 3,
				Actors = {
					{ Npc = "Ivan", Place = "HabitacionResidencia", Offset = V(-3, 0, 2) },
					{ Npc = "Candela", Place = "HabitacionResidencia", Offset = V(3, 0, 2) },
					{ Npc = "CazadorTiempo", Place = "Correos", Offset = V(0, 0, 4), If = { Flags = { "CronosAliado" } } },
					{ Npc = "Bigotes", Place = "JuegosColegio", Offset = V(2, 0, 2), If = { Completed = { "Loco_N2_Bigotes" } } },
					{ Npc = "Rex", Place = "FacultadDerecho", Offset = V(2, 0, 3), If = { Flags = { "RexSeQueda" } } },
					{ Npc = "RatonPerez", Place = "Parque", Offset = V(3, 0, 3), If = { Completed = { "Loco_N5_Perez" } } },
					{ Npc = "Gnomo1", Place = "Home", Offset = V(4, 0, 6), If = { Completed = { "Loco_D4_Gnomos" } } },
					{ Npc = "TuMalvado", Place = "PlazaCentro", Offset = V(4, 0, 4), If = { Flags = { "ConoceTuMalvado" } } },
				},
				Steps = {
					{ Type = "Talk", Npc = "Candela", Dialogue = "Compis", Text = "Iván y Candela (la residencia)" },
					{ Type = "Talk", Npc = "CazadorTiempo", Dialogue = "Cronos", Text = "El agente Cronos (Correos)", If = { Flags = { "CronosAliado" } } },
					{ Type = "Talk", Npc = "Bigotes", Dialogue = "Bigotes", Text = "Bigotes (el cole)", If = { Completed = { "Loco_N2_Bigotes" } } },
					{ Type = "Talk", Npc = "Rex", Dialogue = "Rex", Text = "Rex (Facultad de Derecho)", If = { Flags = { "RexSeQueda" } } },
					{ Type = "Talk", Npc = "RatonPerez", Dialogue = "Perez", Text = "El Ratón Pérez (el parque)", If = { Completed = { "Loco_N5_Perez" } } },
					{ Type = "Talk", Npc = "Gnomo1", Dialogue = "Gnomos", Text = "Rigoberto y los gnomos (tu jardín)", If = { Completed = { "Loco_D4_Gnomos" } } },
					{ Type = "Talk", Npc = "TuMalvado", Dialogue = "Malvado", Text = "Tu yo malvado (la plaza)", If = { Flags = { "ConoceTuMalvado" } } },
				} },
			{ Type = "Scene", Dialogue = "Reunion", Actors = { COSME, PIP, ESCAMAS } },
		},
		Dialogues = {
			Lista = { Lines = {
				{ S = "Cosme", T = "Lista de aliados. La he hecho con mis recuerdos nuevos. Bueno, viejos. Bueno, recuperados. Es larguísima. La mitad no son humanos. Me encanta." },
				{ S = "Cosme", T = "No todos vendrán. Vendrán los que ayudaste. Así funciona el universo: lo que das, vuelve. A veces en forma de gato." },
			} },
			Compis = { Lines = {
				{ S = "Candela", T = "¿Batalla final contra un gemelo malvado para salvar la realidad? Tengo el sábado libre. Lo he comprobado en el calendario." },
				{ S = "Ivan", T = "Y yo he hecho zumo de mora para cuarenta. Para el ejército. De día, tranquilos." },
			}, Effects = { Flags = { "AliadoCompis" } } },
			Cronos = { Lines = {
				{ S = "CazadorTiempo", T = "Mi agenda del futuro dice que el sábado hay una batalla en el Monte del Silencio. Y que yo estoy allí. Mi agenda nunca falla. Casi nunca." },
			}, Effects = { Flags = { "AliadoCronos" } } },
			Bigotes = { Lines = {
				{ S = "Bigotes", T = "¿Una batalla por el destino del universo? Los gatos no participamos en batallas. Las supervisamos desde una caja. Estaré allí. En mi caja." },
			}, Effects = { Flags = { "AliadoBigotes" } } },
			Rex = { Lines = {
				{ S = "Rex", T = "Me defendiste ante la Aduana del Tiempo. Un velocirraptor no olvida. Y un abogado, menos. Iré. Con garras y con código civil." },
			}, Effects = { Flags = { "AliadoRex" } } },
			Perez = { Lines = {
				{ S = "RatonPerez", T = "¿Una batalla? Tengo vacaciones gracias a ti. Mi ayudante, la rata, cubre el turno. Iré con la patrulla de ratones. Somos pequeños, pero mordemos cables." },
			}, Effects = { Flags = { "AliadoPerez" } } },
			Gnomos = { Lines = {
				{ S = "Gnomo1", T = "¡El tratado de paz nos obliga a defender el jardín! Y el universo es un jardín muy grande. ¡Los gnomos marchamos! Despacito." },
			}, Effects = { Flags = { "AliadoGnomos" } } },
			Malvado = { Lines = {
				{ S = "TuMalvado", T = "¿Ayudarte? ¿Contra Cósimo? …Él me prometió tu vida y nunca me la dio. Además, me ha subido el alquiler. Iré. Por venganza. Y un poco por ti. Poco." },
			}, Effects = { Flags = { "AliadoMalvado" } } },
			Reunion = { Lines = {
				{ S = "Cosme", T = "¡Mira cuánta gente! Y gatos. Y roedores. Y… ¿eso es un velocirraptor con corbata? Criatura, tienes una vida rarísima. Me encanta." },
				{ S = "DonEscamas", T = "(Desde la pecera) Y yo tengo lo más importante: las cuentas de MegaVerso. Para vencer a Cósimo, primero hay que dejarle sin dinero. Y yo sé dónde lo esconde." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 21 · La caída del Consorcio
	---------------------------------------------------------------------
	{
		Id = "Saga_21_Consorcio",
		Kind = "Side",
		Canon = true,
		Title = "La caída del Consorcio",
		Description = "Don Escamas ha encontrado el servidor central de MegaVerso: allí están todas las cuentas del Proyecto Fusión. Si cae el servidor, cae el Consorcio. Y Cósimo se queda sin dinero.",
		Type = "Saga de la Grieta · Acto IV (3/6)",
		Duration = { 25, 35 },
		Npcs = { "RobotSeguridad", "AgenteGris1", "AgenteGris2", "Candela", "Ivan", "Glub" },
		Offer = { Place = "OficinasFinanciero" },
		OfferKey = "La sede de MegaVerso. Don Escamas, en su cubo, te da la señal: «Ahora»",
		Requires = after("Saga_20_Aliados"),
		Moment = "Hiciste caer al Consorcio MegaVerso",
		Memory = "CaidaConsorcio",
		Rewards = { Flags = { "ConsorcioCaido" }, Money = 200 },
		Props = {
			Servidor = { Kind = "Maquina", Name = "El servidor central de MegaVerso", Prompt = "Enchufar el pendrive de Don Escamas", Place = "OficinasFinanciero", Offset = V(0, 0, 10), Color = Color3.fromRGB(60, 60, 70), Dialogue = "Servidor", Once = true },
		},
		Steps = {
			{ Type = "Fight", Place = "OficinasFinanciero", Respawn = "OficinasFinanciero", Action = "Desconectar ⚡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160),
				Text = "Asalto a la sede de MegaVerso: aparta a la seguridad ({count}/{total})",
				CaughtLine = "Tiene usted una llamada de ventas. (Candela te saca de ahí por la oreja.)",
				Actors = { { Npc = "Candela", Place = "OficinasFinanciero", Offset = V(-6, 0, 10), Mode = "Point" }, { Npc = "AgenteGris2", Place = "OficinasFinanciero", Offset = V(6, 0, 10), Mode = "Wave", If = { Flags = { "GrisArrepentida" } } } },
				Enemies = {
					{ Npc = "RobotSeguridad", Offset = V(-6, 0, 2), Speed = 10, HP = 5, Bye = "Llamada… finalizada. Para siempre." },
					{ Npc = "AgenteGris1", Offset = V(6, 0, 2), Speed = 12, Bye = "¡Me voy a la competencia! ¡Pagan mejor!" },
				} },
			{ Type = "Use", Prop = "Servidor", Text = "Enchufa el pendrive de Don Escamas en el servidor central",
				Actors = { { Npc = "Ivan", Place = "OficinasFinanciero", Offset = V(-3, 0, 8) }, { Npc = "Candela", Place = "OficinasFinanciero", Offset = V(3, 0, 8) } } },
			{ Type = "Scene", Dialogue = "Quiebra",
				Actors = {
					{ Npc = "Glub", Place = "OficinasFinanciero", Offset = V(0, 0, 4) },
					{ Npc = "Ivan", Place = "OficinasFinanciero", Offset = V(-3, 0, 8), Mode = "Cheer" },
					{ Npc = "Candela", Place = "OficinasFinanciero", Offset = V(3, 0, 8), Mode = "Cheer" },
				} },
		},
		Dialogues = {
			Servidor = { Lines = {
				{ S = "Narrador", T = "El pendrive de Don Escamas tiene forma de pez. Lo enchufas. La pantalla se llena de números. Las cuentas del Consorcio aparecen, una a una, en las pantallas de toda la oficina." },
				{ S = "Narrador", T = "Facturas falsas. Planetas embargados. Un pedido de «perillas postizas, 40.000 unidades». Y una transferencia enorme: «Laboratorio Dr. Cósimo — Proyecto Fusión»." },
			} },
			Quiebra = { Lines = {
				{ S = "Glub", T = "Agente Glub, Banco Galáctico. Hemos recibido un chivatazo contable impecable. Firmado por un tal «D. Escamas». Muy buena caligrafía para ser un pez." },
				{ S = "Glub", T = "¿Nos conocemos? Usted es quien leyó la letra pequeña. O quien nos resistió. Me acuerdo. No es fácil olvidarle.", If = { Completed = { "Loco_D2_Deuda" } } },
				{ S = "Glub", T = "MegaVerso S.A. queda intervenida. Cuentas congeladas. Sellado, sellado y sellado. El doctor Cósimo se queda sin financiación." },
				{ S = "Ivan", T = "¡Hemos arruinado a una multinacional malvada! ¡Con un pendrive con forma de pez! ¡Esto hay que ponerlo en el currículum!" },
				{ S = "Candela", T = "Sin dinero, Cósimo solo tiene una opción: hacer la Fusión él solo. Y rápido. Viene a por el Ancla. Ahora sí." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 22 · El Ancla
	---------------------------------------------------------------------
	{
		Id = "Saga_22_Ancla",
		Kind = "Side",
		Canon = true,
		Title = "El Ancla",
		Description = "Esta noche, en tu casa, alguien llama a la puerta. Un hombre de pelo blanco muy peinado. Con perilla. Trae flores. Y una oferta.",
		Type = "Saga de la Grieta · Acto IV (4/6)",
		Duration = { 15, 25 },
		Npcs = { "Cosimo" },
		Offer = { Place = "Home" },
		OfferKey = "Llaman a la puerta de tu casa. A estas horas. Con música de concurso",
		Requires = after("Saga_21_Consorcio", { Hours = { From = 20, To = 6 } }),
		Moment = "Le dijiste que no a Cósimo",
		Memory = "ElTrato",
		Steps = {
			{ Type = "Talk", Npc = "Cosimo", Dialogue = "Oferta", Text = "Abre la puerta",
				Actors = { { Npc = "Cosimo", Place = "Home", Offset = V(0, 0, 5) } } },
			{ Type = "Choice", Key = "Trato", Text = "Cósimo te ofrece una vida perfecta en la 66-B a cambio de soltar el ancla. ¿Qué haces?",
				Options = {
					{ Id = "No", Text = "«No.» Así de simple", Effects = { Traits = { Valentia = 2 } } },
					{ Id = "Trampa", Text = "Fingir que aceptas… para tenderle una trampa en el monte", Effects = { Traits = { Curiosidad = 1, Humor = 1 }, Flags = { "TrampaCosimo" } } },
				},
				Actors = { { Npc = "Cosimo", Place = "Home", Offset = V(0, 0, 5) } } },
			{ Type = "Scene", Dialogue = "Respuesta", Actors = { { Npc = "Cosimo", Place = "Home", Offset = V(0, 0, 5) } } },
		},
		Dialogues = {
			Oferta = { Lines = {
				{ S = "Cosimo", T = "Buenas noches. Perdona la hora. Traigo flores. De la 66-B: muerden un poco, no las toques." },
				{ S = "Cosimo", T = "Me habéis arruinado el Consorcio. Muy bien hecho. Me impresionas. Así que vengo a negociar, como la gente civilizada. Con perilla." },
				{ S = "Cosimo", T = "En mi Valmar puedo darte la vida perfecta: el mejor trabajo, la casa más grande, un gato que te hace caso. Solo tienes que venir conmigo. Soltar el ancla. Nada más." },
				{ S = "Cosimo", T = "¿Sabes lo que es quedarse al otro lado veinte años, solo, porque alguien te soltó la mano? Yo solo quiero volver. A lo grande. Con las dos Valmar para mí." },
				{ S = "Narrador", T = "Por un segundo, detrás de la perilla y la sonrisa de anuncio, ves a un hombre muy cansado. Y muy solo." },
			} },
			Respuesta = { Lines = {
				{ S = "Cosimo", T = "¿No? …Qué predecible. Como él. Os parecéis tanto que da rabia. Nos veremos en el Monte del Silencio, Ancla. Traiga a quien quiera. Yo traeré el final.", If = { Choices = { Trato = "No" } } },
				{ S = "Cosimo", T = "¿Aceptas? ¡Maravilloso! Nos vemos en la cima del monte. Mañana a medianoche. Ven sola, ven solo. …¿Por qué sonríes así? Bah. Será la emoción.", If = { Choices = { Trato = "Trampa" } } },
				{ S = "Narrador", T = "Cósimo se va. Te quedas mirando las flores que muerden. Mañana es la Gran Fusión. Llamas a Cosme. Contesta al primer tono: estaba esperando la llamada." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 23 · La Gran Fusión
	---------------------------------------------------------------------
	{
		Id = "Saga_23_Fusion",
		Kind = "Side",
		Canon = true,
		Title = "La Gran Fusión",
		Description = "Medianoche en el Monte del Silencio. El cielo se abre como una cremallera. Dos Valmar a punto de convertirse en una. Todos tus aliados a tu espalda. Esto es el final.",
		Type = "Saga de la Grieta · Acto IV (5/6) · Batalla final",
		Duration = { 35, 50 },
		Npcs = { "Cosimo", "Cosme", "DronCosimo1", "DronCosimo2", "DronCosimo3", "RobotSeguridad" },
		Offer = { Place = CIMA },
		OfferKey = "Medianoche. La cima del Monte del Silencio. La Gran Fusión",
		Requires = after("Saga_22_Ancla", { Hours = { From = 22, To = 4 } }),
		Moment = "Venciste en la Gran Fusión",
		Memory = "GranFusion",
		Rewards = { Flags = { "FusionDetenida" } },
		Props = {
			Grieta = { Kind = "Nave", Name = "La Grieta abierta", Place = CIMA, Offset = V(0, 0, -12), Height = 26, Prompt = false },
		},
		Steps = {
			{ Type = "Cinematic", Id = "Saga_Fusion", Props = { "Grieta" } },
			{ Type = "Scene", Dialogue = "Llegada", Props = { "Grieta" },
				Actors = { { Npc = "Cosimo", Place = CIMA, Offset = V(0, 0, -6) }, { Npc = "Cosme", Place = CIMA, Offset = V(3, 0, 6) } } },
			{ Type = "Escape", Seconds = 25, Respawn = CIMA, Catch = 4, Props = { "Grieta" },
				Text = "¡La Grieta tira de ti! Aguanta 25 segundos sin que los drones te empujen dentro",
				CaughtLine = "¡Casi! (Cosme te agarra de la mano. Esta vez no te suelta.)",
				Actors = {
					{ Npc = "DronCosimo1", Place = CIMA, Offset = V(-10, 0, -4), Mode = "Hunt", Speed = 13, Prompt = false },
					{ Npc = "DronCosimo2", Place = CIMA, Offset = V(10, 0, -4), Mode = "Hunt", Speed = 13, Prompt = false },
					{ Npc = "Cosme", Place = CIMA, Offset = V(3, 0, 6), Mode = "Point" },
				} },
			{ Type = "Fight", Place = CIMA, Respawn = CIMA, Action = "Coser con la aguja 🪡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160), Props = { "Grieta" },
				Text = "¡Oleada de drones y robots! Tus aliados te cubren ({count}/{total})",
				CaughtLine = "¡Te tengo! (Un aliado te rescata. Vuelves a la cima.)",
				Actors = ALIADOS_FINAL,
				Enemies = {
					{ Npc = "DronCosimo1", Offset = V(-10, 0, -4), Speed = 13, Bye = "¡Bzzt! ¡Fin de temporada!" },
					{ Npc = "DronCosimo2", Offset = V(10, 0, -4), Speed = 13, Bye = "¡Bzzt! ¡Cancelado!" },
					{ Npc = "DronCosimo3", Offset = V(0, 0, -8), Speed = 14, HP = 4, Bye = "¡Mi pajarita! ¡Otra vez!" },
					{ Npc = "RobotSeguridad", Offset = V(0, 0, 4), Speed = 10, HP = 5, Bye = "Llamada… finalizada." },
				} },
			{ Type = "Scene", Dialogue = "Restos", If = MUCHOS_RESTOS, Props = { "Grieta" },
				Actors = { { Npc = "Pip", Place = CIMA, Offset = V(0, 0, 10) }, { Npc = "Cosimo", Place = CIMA, Offset = V(0, 0, -6) } } },
			{ Type = "Fight", Place = CIMA, Respawn = CIMA, Action = "Coser su perilla con la aguja 🪡", HP = 6, If = MUCHOS_RESTOS, BeamColor = Color3.fromRGB(120, 255, 160), Props = { "Grieta" },
				Text = "¡Cósimo en persona! Tus Restos de la Grieta brillan y le frenan: cóselo de vuelta a su dimensión",
				CaughtLine = "¡Ja! ¡El público adora un giro! (Te lanza lejos. Tus aliados te levantan.)",
				Actors = ALIADOS_FINAL,
				Enemies = {
					{ Npc = "Cosimo", Offset = V(0, 0, -6), Speed = 10, HP = 6, Hurt = "¡Mi perilla! ¡Veinte años cultivándola!", Bye = "…Basta. Basta. Me rindo. (Se deja caer de rodillas. No desaparece. Se queda ahí, muy cansado.)" },
				} },
			{ Type = "Fight", Place = CIMA, Respawn = CIMA, Action = "Coser su perilla con la aguja 🪡", HP = 10, If = POCOS_RESTOS, BeamColor = Color3.fromRGB(120, 255, 160), Props = { "Grieta" },
				Text = "¡Cósimo en persona! Cóselo de vuelta a su dimensión",
				CaughtLine = "¡Ja! ¡El público adora un giro! (Te lanza lejos. Tus aliados te levantan.)",
				Actors = ALIADOS_FINAL,
				Enemies = {
					{ Npc = "Cosimo", Offset = V(0, 0, -6), Speed = 12, HP = 10, Hurt = "¡Mi perilla! ¡Veinte años cultivándola!", Bye = "…Basta. Basta. Me rindo. (Se deja caer de rodillas. No desaparece. Se queda ahí, muy cansado.)" },
				} },
			{ Type = "Scene", Dialogue = "Rendicion", Props = { "Grieta" },
				Actors = {
					{ Npc = "Cosimo", Place = CIMA, Offset = V(0, 0, -4), Mode = "Sit" },
					{ Npc = "Cosme", Place = CIMA, Offset = V(3, 0, 2) },
					{ Npc = "Pip", Place = CIMA, Offset = V(0, 0, 10) },
				} },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Cosimo", T = "¡Bienvenidos, bienvenidas, a la GRAN FUSIÓN! ¡En directo desde el Monte del Silencio! ¡Y traes público! Qué detalle.", If = { Choices = { Trato = "No" } } },
				{ S = "Cosimo", T = "Habías aceptado… ¿Y traes un EJÉRCITO? ¿Gatos? ¿Un velocirraptor? …Me has engañado. Me has engañado MUY bien. Como él.", If = { Choices = { Trato = "Trampa" } } },
				{ S = "Cosme", T = "Cósimo. Todavía estás a tiempo. Deja la máquina. Ven a casa. Te hago un batido." },
				{ S = "Cosimo", T = "¿A casa? ¿A qué casa, Cosme? Tú tienes una vida. Un robot. Un pez. Una criatura. Yo tengo una perilla y una dimensión que me odia. ¡Drones!" },
			} },
			Restos = { Lines = {
				{ S = "Pip", T = "¡Ancla! ¡Los Restos de la Grieta! El sello, la bombilla, mi chapa… Todo lo que devolvió a su sitio. ¡Están brillando!" },
				{ S = "Narrador", T = "Las cosas raras que arreglaste por Valmar se encienden a la vez. La Grieta las reconoce: son tuyas. Y tira de Cósimo hacia atrás." },
				{ S = "Cosimo", T = "¿Una farola que canta? ¿Un tenedor? ¿Esto es un ejército o un mercadillo? …¿Por qué me pesan las piernas?" },
			} },
			Rendicion = { Lines = {
				{ S = "Cosimo", T = "Veinte años preparando esto. Y me gana un Ancla con un ejército de gatos, gnomos y un pez contable. …Qué vergüenza. Qué episodio tan bueno." },
				{ S = "Cosme", T = "Cósimo. Aquella noche te solté la mano. Llevo veinte años pensándolo. No fue a propósito. Fue miedo. Perdóname." },
				{ S = "Cosimo", T = "…¿Veinte años y ahora me pides perdón? ¿Así? ¿En directo? …Eres insoportable, Cosme." },
				{ Ask = "Cósimo te mira a ti. «¿Y tú qué harías conmigo, Ancla?»", Options = {
					{ T = "«Que vuelva. Que empiece de cero. En esta Valmar.»", Effects = { Flags = { "CosimoPerdonado" }, Traits = { Empatia = 2 } }, Then = {
						{ S = "Cosimo", T = "¿Aquí? ¿Sin perilla? …Me afeitaré. Me sentará fatal. …Gracias." },
					} },
					{ T = "«Que vuelva a la 66-B. Pero sin maldad: a arreglarla.»", Effects = { Flags = { "CosimoArregla66B" }, Traits = { Responsabilidad = 2 } }, Then = {
						{ S = "Cosimo", T = "¿Arreglar la 66-B? ¿Una dimensión entera de malvados? …Sería el reto más grande de mi vida. Me gustan los retos grandes. Acepto." },
						{ S = "TuMalvado", T = "(Desde atrás) Yo le ayudo. Ya sé cómo es ser bueno. Un poco. Tengo práctica.", If = { Flags = { "AliadoMalvado" } } },
					} },
				} },
				{ S = "Narrador", T = "La máquina de la Fusión se apaga. Pero la Grieta sigue abierta en el cielo, enorme, temblando. Ahora sin nadie que tire de ella. Solo falta cerrarla. Para siempre." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 24 · Coser el cielo (de verdad) — epílogo
	---------------------------------------------------------------------
	{
		Id = "Saga_24_Final",
		Kind = "Side",
		Canon = true,
		Title = "Coser el cielo (de verdad)",
		Description = "La Grieta sigue abierta. Para cerrarla para siempre hay que coserla desde los dos lados a la vez. Cosme y Cósimo. Juntos. Como la primera noche. Y tú, en medio, sujetándolo todo.",
		Type = "Saga de la Grieta · Epílogo",
		Duration = { 20, 30 },
		Npcs = { "Cosme", "Cosimo", "Pip", "Ivan", "Candela" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme y Cósimo te esperan en el garaje. Juntos. Discutiendo. Como antes",
		Requires = { Stage = { Min = "Adulto" }, Completed = { "Saga_23_Fusion" } },
		Moment = "Cosiste el cielo para siempre",
		Memory = "FinDeLaSaga",
		Rewards = { Items = { AgujaDeOro = 1 }, Flags = { "SagaCompleta" }, Money = 500 },
		Props = {
			Cosedora = { Kind = "Maquina", Name = "La Cosedora Dimensional (versión 2)", Place = "GarajeCosme", Offset = V(0, 0, -4), Color = Color3.fromRGB(200, 255, 220), Prompt = false },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Garaje", Props = { "Cosedora" },
				Actors = { COSME, { Npc = "Cosimo", Place = "GarajeCosme", Offset = V(-3, 0, 3) }, PIP, ESCAMAS } },
			{ Type = "Reach", Place = "Patio", Text = "Id al patio del cole: donde clavaste el primer anclaje, de niño",
				Actors = { { Npc = "Cosme", Mode = "Follow" }, { Npc = "Cosimo", Mode = "Follow" }, { Npc = "Ivan", Mode = "Follow" }, { Npc = "Candela", Mode = "Follow" } } },
			{ Type = "Cinematic", Id = "Saga_Final" },
			{ Type = "Scene", Dialogue = "Final",
				Actors = {
					{ Npc = "Cosme", Place = "Patio", Offset = V(2, 0, 3) },
					{ Npc = "Cosimo", Place = "Patio", Offset = V(-2, 0, 3) },
					{ Npc = "Ivan", Place = "Patio", Offset = V(-5, 0, 6), Mode = "Cheer" },
					{ Npc = "Candela", Place = "Patio", Offset = V(5, 0, 6), Mode = "Cheer" },
					{ Npc = "Pip", Place = "Patio", Offset = V(0, 0, 8), Mode = "Cheer" },
				} },
		},
		Dialogues = {
			Garaje = { Lines = {
				{ S = "Cosme", T = "¡Esa pieza va al revés!" },
				{ S = "Cosimo", T = "¡Va al revés porque la pusiste tú al revés en 2003!" },
				{ S = "Pip", T = "Llevan así tres horas. Es precioso. Es como antes. Tengo el aceite de los ojos alterado." },
				{ S = "Cosme", T = "Criatura: la Cosedora versión 2. Hay que coser el cielo desde los dos lados a la vez. Yo desde aquí, él desde su lado. Y tú en el centro, que eres el ancla. Donde empezó todo." },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "La aguja sube. Cosme cose desde un lado. Cósimo, desde el otro. Tú sujetas el hilo en el centro, como llevas haciendo toda tu vida sin saberlo." },
				{ S = "Narrador", T = "El último punto. La Grieta se cierra con un sonido pequeño, como un botón que encaja. El cielo de Valmar queda limpio. Por primera vez desde que naciste." },
				{ S = "Cosimo", T = "Ya está. Ya no eres un ancla. Eres… una persona. Qué aburrido. Qué bien." },
				{ S = "Cosme", T = "Criatura. …Te lo digo ahora, que tengo todos los recuerdos y ninguno pendiente: estoy orgulloso de ti. Desde el microondas. Desde siempre." },
				{ Ask = "¿Qué le dices a Cosme?", Options = {
					{ T = "«Gracias por cuidarme toda la vida.»", Effects = { Rel = { Cosme = 20 } }, Then = {
						{ S = "Cosme", T = "No me des las gracias. Dame un abrazo. Rápido, que viene Cósimo y no quiero que se ría. …Vale, que se ría." },
					} },
					{ T = "«¿Y ahora qué inventamos?»", Effects = { Rel = { Cosme = 15 }, Traits = { Curiosidad = 2 } }, Then = {
						{ S = "Cosme", T = "¡Esa es mi criatura! Tengo una idea sobre un tostador que tuesta en el futuro. Así el pan ya está hecho mañana. ¡Cósimo, trae el destornillador!" },
					} },
				} },
				{ S = "Ivan", T = "¿Ya está? ¿Hemos salvado el universo? …¡Zumo de mora para todos! ¡De día!" },
				{ S = "Candela", T = "Tachado el último punto de la lista plastificada. Es el mejor día de mi vida. Lo apunto." },
				{ S = "Narrador", T = "Recibes 🪡 la Aguja de oro. FIN DE LA SAGA DE LA GRIETA. …Pero en Valmar, las cosas raras nunca se acaban del todo." },
			} },
		},
	},
}
