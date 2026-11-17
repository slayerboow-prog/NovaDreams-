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
local RESTOS = { "BuzonPasado", "FarolaOpera", "PerroBinario", "LluviaEspaguetis", "Piso13", "RelojAtras", "SemaforoOpina", "NubePerdida",
	"ColumpioPasado", "SombraEscapada", "EspejoContesta", "PalomasCola", "CafeConsejos", "EcoFuturo", "Contestador1999", "GatoCuantico",
	"HeladoRecuerdos", "CharcoSinFondo", "CancionPegadiza", "TaquillaDimensional", "FotocopiasVivas", "Wifi1987", "LavadoraMultiversal", "CajeroDeTiempo" }
local MUCHOS_RESTOS = { MemoriesAtLeast = { N = 4, Of = RESTOS } }
local POCOS_RESTOS = { MemoriesFewer = { N = 4, Of = RESTOS } }

-- Aliados en la batalla final: solo vienen los que ayudaste (marcas de las misiones de toda tu vida)
local ALIADOS_FINAL = {
	{ Npc = "Brenn", Place = CIMA, Offset = V(-8, 0, 8), Mode = "Cheer" },
	{ Npc = "Sorel", Place = CIMA, Offset = V(8, 0, 8), Mode = "Cheer" },
	{ Npc = "Kael", Place = CIMA, Offset = V(0, 0, 6), Mode = "Point" },
	{ Npc = "Pip", Place = CIMA, Offset = V(0, 0, 10), Mode = "Cheer" },
	{ Npc = "CazadorTiempo", Place = CIMA, Offset = V(-12, 0, 4), Mode = "Point", If = { Flags = { "CronosAliado" } } },
	{ Npc = "Bigotes", Place = CIMA, Offset = V(12, 0, 4), If = { Flags = { "AliadoBigotes" } } },
	{ Npc = "Rex", Place = CIMA, Offset = V(-14, 0, 10), Mode = "Cheer", If = { Flags = { "AliadoRex" } } },
	{ Npc = "RatonPerez", Place = CIMA, Offset = V(14, 0, 10), If = { Flags = { "AliadoPerez" } } },
	{ Npc = "Gnomo1", Place = CIMA, Offset = V(-4, 0, 12), If = { Flags = { "AliadoGnomos" } } },
	{ Npc = "TuMalvado", Place = CIMA, Offset = V(4, 0, 12), If = { Flags = { "AliadoMalvado" } } },
	{ Npc = "CapitanNoz", Place = CIMA, Offset = V(0, 0, 14), If = { Flags = { "GrabacionLaboratorio" } } },
}

return {
	---------------------------------------------------------------------
	-- 19 · Recuerdos de tostadora
	---------------------------------------------------------------------
	{
		Id = "Saga_19_Recuerdos",
		Kind = "Side",
		Canon = true,
		Title = "Lo que queda",
		Description = "Cosme sigue sin recordar casi nada. Pip cree que los recuerdos se quedan pegados a los sitios: hay que llevarle a los que más le importaban.",
		Type = "Saga de la Grieta · Acto IV (1/6)",
		Duration = { 30, 40 },
		Npcs = { "Cosme", "Pip", "DonEscamas" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Pip te espera con Cosme y una lista de sitios",
		Requires = after("Saga_18_Precio"),
		Moment = "Cosme recuperó sus recuerdos",
		Memory = "CosmeRecuerda",
		Rewards = { Unflags = { "CosmeSinMemoria" }, Flags = { "CosmeRecuerda" }, Items = { AlbumRecuerdos = 1 } },
		Props = {
			Microondas = { Kind = "Maquina", Name = "El detector de resonancia (reparado por Pip)", Prompt = "Encender el detector", Place = "GarajeCosme", Offset = V(-3, 0, 0), Dialogue = "Microondas", Once = true },
			Gallinero = { Kind = "Mural", Name = "La pared de los caídos", Prompt = "Leer los nombres", Place = "EntradaColegio", Offset = V(4, 0, 4), Dialogue = "Gallina", Once = true },
			Cielo = { Kind = "Cristal", Name = "El viejo anclaje del parque", Prompt = "Tocar el anclaje", Place = "Parque", Offset = V(0, 0, 8), Dialogue = "Anclaje", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Pip", Dialogue = "Lista", Text = "Habla con Pip", Actors = { COSME, PIP, ESCAMAS } },
			{ Type = "Group", Text = "Lleva a Cosme a los sitios de vuestros recuerdos",
				Actors = { { Npc = "Cosme", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Microondas", Text = "El garaje: el detector de resonancia" },
					{ Type = "Use", Prop = "Gallinero", Text = "La Academia: la pared de los caídos" },
					{ Type = "Use", Prop = "Cielo", Text = "El parque: el anclaje del cielo" },
				} },
			{ Type = "Scene", Dialogue = "Vuelve", Actors = { COSME, PIP, ESCAMAS } },
		},
		Dialogues = {
			Lista = { Lines = {
				{ S = "Pip", T = "He hecho una lista de los sitios que más le importaban al doctor. En casi todos estaba usted.", To = "Yo" },
				{ S = "Cosme", T = "Sé tu nombre. Es lo único que tengo seguro. Empezaremos por ahí.", If = { Memories = { "TuNombre" } }, To = "Yo" },
				{ S = "DonEscamas", T = "Los recuerdos no desaparecen. Se esconden en cosas.", Shot = "Medio:DonEscamas" },
			} },
			Microondas = { Lines = {
				{ S = "Narrador", T = "El detector se enciende. La pantalla se llena de líneas, como aquella primera noche." },
				{ S = "Cosme", T = "Alguien vino a ayudarme sin preguntar nada. Eras tú. Llegaste tarde.", Beat = "Piensa", Shot = "PrimerPlano:Cosme" },
			} },
			Gallina = { Lines = {
				{ S = "Narrador", T = "Entre los nombres de la pared: «Lía. Investigadora. No dejó a nadie atrás»." },
				{ S = "Cosme", T = "…Lía. Mi hermana. La noche de la Caída le dije que saliera de allí. No me hizo caso.", A = "Sad" },
			} },
			Anclaje = { Lines = {
				{ S = "Narrador", T = "El primer anclaje que clavaste. Todavía brilla un poco. Cosme lo toca." },
				{ S = "Cosme", T = "La noche de la aguja. Estaba tan orgulloso que no fui capaz de decírtelo.", Pause = 0.8, A = "Sad", Shot = "PrimerPlano:Cosme" },
			} },
			Vuelve = { Lines = {
				{ S = "Cosme", T = "Me acuerdo. De todo.", Pause = 1, Shot = "PrimerPlano:Cosme", To = "Yo" },
				{ S = "Cosme", T = "Y de que guardaste mi secreto. Nunca se lo contaste a nadie.", If = { Flags = { "SecretoCosme" } } },
				{ S = "Cosme", T = "Y de que fuiste a buscarme a otro mundo.", If = { Memories = { "RescateCosme" } } },
				{ S = "Pip", T = "Bienvenido, doctor. Esta vez de verdad.", Shot = "Reaccion:Pip" },
				{ S = "Cosme", T = "Y me acuerdo de lo peor: Cósimo ya sabe cómo soltar el Ancla. Va a venir a por ti.", A = "Angry", To = "Yo" },
				{ S = "Narrador", T = "Pip guarda una foto de cada sitio. Recibes 📔 el álbum de recuerdos." },
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
		Description = "Para enfrentarse a la Gran Fusión hace falta todo el que te debe algo. Vendrán los que ayudaste.",
		Type = "Saga de la Grieta · Acto IV (2/6)",
		Duration = { 30, 45 },
		Npcs = { "Sorel", "Brenn", "CazadorTiempo", "Bigotes", "Rex", "RatonPerez", "Gnomo1", "TuMalvado", "Kael" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme ha hecho una lista de aliados",
		Requires = after("Saga_19_Recuerdos"),
		Moment = "Reuniste a todos tus aliados",
		Memory = "TodosLosAliados",
		Rewards = { Flags = { "AliadosReunidos" } },
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Lista", Text = "Habla con Cosme en el garaje: tiene la lista de aliados", Actors = { COSME, PIP } },
			{ Type = "Group", Text = "Visita a tus aliados (vendrán los que ayudaste en tu vida)", Need = 3,
				Actors = {
					{ Npc = "Brenn", Place = "Pista", Offset = V(-3, 0, 2) },
					{ Npc = "Sorel", Place = "Pista", Offset = V(3, 0, 2) },
					{ Npc = "CazadorTiempo", Place = "Correos", Offset = V(0, 0, 4), If = { Flags = { "CronosAliado" } } },
					{ Npc = "Bigotes", Place = "JuegosColegio", Offset = V(2, 0, 2), If = { Flags = { "CoordenadasCosimo" } } },
					{ Npc = "Rex", Place = "PlazaCentro", Offset = V(-6, 0, 3), If = { Flags = { "RexSeQueda" } } },
					{ Npc = "RatonPerez", Place = "Parque", Offset = V(3, 0, 3), If = { Completed = { "Loco_N5_Perez" } } },
					{ Npc = "Gnomo1", Place = "Home", Offset = V(4, 0, 6), If = { Completed = { "Loco_D4_Gnomos" } } },
					{ Npc = "TuMalvado", Place = "PlazaCentro", Offset = V(4, 0, 4), If = { Flags = { "ConoceTuMalvado" } } },
				},
				Steps = {
					{ Type = "Talk", Npc = "Sorel", Dialogue = "Compis", Text = "Sorel y Brenn (la Academia)" },
					{ Type = "Talk", Npc = "CazadorTiempo", Dialogue = "Cronos", Text = "El agente Cronos (Correos)", If = { Flags = { "CronosAliado" } } },
					{ Type = "Talk", Npc = "Bigotes", Dialogue = "Bigotes", Text = "Bigotes (junto a la Academia)", If = { Flags = { "CoordenadasCosimo" } } },
					{ Type = "Talk", Npc = "Rex", Dialogue = "Rex", Text = "Rex (la plaza)", If = { Flags = { "RexSeQueda" } } },
					{ Type = "Talk", Npc = "RatonPerez", Dialogue = "Perez", Text = "El Ratón Pérez (el parque)", If = { Completed = { "Loco_N5_Perez" } } },
					{ Type = "Talk", Npc = "Gnomo1", Dialogue = "Gnomos", Text = "Rigoberto y los gnomos (tu jardín)", If = { Completed = { "Loco_D4_Gnomos" } } },
					{ Type = "Talk", Npc = "TuMalvado", Dialogue = "Malvado", Text = "Tu otra versión de la 66-B (la plaza)", If = { Flags = { "ConoceTuMalvado" } } },
				} },
			-- (los aliados que has ido a buscar, en el garaje: «Vaya. De verdad vinieron». Antes hablaban sin estar)
			{ Type = "Scene", Dialogue = "Reunion", Actors = { COSME, PIP, { Npc = "DonEscamas", Place = "GarajeCosme", Offset = V(-2, 0, 6), Scale = 0.35 },
				{ Npc = "Brenn", Place = "GarajeCosme", Offset = V(-6, 0, 6) },
				{ Npc = "Sorel", Place = "GarajeCosme", Offset = V(6, 0, 6) },
				{ Npc = "Kael", Place = "GarajeCosme", Offset = V(0, 0, 9) },
				{ Npc = "CazadorTiempo", Place = "GarajeCosme", Offset = V(-9, 0, 3), If = { Flags = { "CronosAliado" } } },
				{ Npc = "Bigotes", Place = "GarajeCosme", Offset = V(9, 0, 3), If = { Flags = { "AliadoBigotes" } } },
				{ Npc = "Rex", Place = "GarajeCosme", Offset = V(-10, 0, 9), If = { Flags = { "RexSeQueda" } } },
				{ Npc = "TuMalvado", Place = "GarajeCosme", Offset = V(10, 0, 9), If = { Flags = { "ConoceTuMalvado" } } },
			} },
		},
		Dialogues = {
			Lista = { Lines = {
				{ S = "Cosme", T = "Una lista de aliados: todos los que te deben algo y a los que les debes algo tú.", G = "Point" },
				{ S = "Cosme", T = "No vendrán todos. Vendrán los que ayudaste de verdad.", Beat = "Piensa" },
			} },			Compis = { Lines = {
				{ S = "Sorel", T = "¿Ir contra Cósimo en el Monte del Silencio? Llevo esperando esto desde la feria." },
				{ S = "Brenn", T = "Doce cadetes de último curso dispuestos. Sin permiso. Con mucho miedo." },
			}, Effects = { Flags = { "AliadoCompis" } } },			Cronos = { Lines = {
				{ S = "CazadorTiempo", T = "La Aduana no participa en batallas. Yo, desde hoy, no soy solo la Aduana." },
			}, Effects = { Flags = { "AliadoCronos" } } },			Bigotes = { Lines = {
				{ S = "Bigotes", T = "Mi pueblo perdió un mundo por culpa del Consorcio. No dejaré que pierdas el tuyo. La guardia de G-4 cruzará contigo." },
			}, Effects = { Flags = { "AliadoBigotes" } } },			Rex = { Lines = {
				{ S = "Rex", T = "Me defendiste cuando nadie lo habría hecho. Estaré allí." },
			}, Effects = { Flags = { "AliadoRex" } } },			Perez = { Lines = {
				{ S = "RatonPerez", T = "Te debo una. Mi gente cortará los cables del Consorcio antes de que empiece." },
			}, Effects = { Flags = { "AliadoPerez" } } },			Gnomos = { Lines = {
				{ S = "Gnomo1", T = "Prometimos defender lo que importa. Vamos contigo." },
			}, Effects = { Flags = { "AliadoGnomos" } } },			Malvado = { Lines = {
				{ S = "TuMalvado", T = "Iré. No por ti. Por la versión de mí que habría sido si alguien me hubiera sacado de aquel laboratorio.", A = "ArmsCrossed" },
			}, Effects = { Flags = { "AliadoMalvado" } } },			Reunion = { Lines = {
				{ S = "Cosme", T = "Mira cuánta gente.", Shot = "General" },
				{ S = "Kael", T = "Oficialmente no estoy aquí. Extraoficialmente, traigo a todos los guerreros de la Academia que pueden andar." },
				{ S = "DonEscamas", T = "Para vencer a Cósimo, primero hay que dejarle sin dinero. Y yo sé dónde lo guarda.", Shot = "Medio:DonEscamas" },
			} },		},
	},

	---------------------------------------------------------------------
	-- 21 · La caída del Consorcio
	---------------------------------------------------------------------
	{
		Id = "Saga_21_Consorcio",
		Kind = "Side",
		Canon = true,
		Title = "La caída del Consorcio",
		Description = "Escamas ha localizado el servidor central del Consorcio: allí están las cuentas del Proyecto Fusión. Si salen a la luz, el Consorcio cae y Cósimo se queda sin dinero.",
		Type = "Saga de la Grieta · Acto IV (3/6)",
		Duration = { 25, 35 },
		Npcs = { "RobotSeguridad", "AgenteGris1", "AgenteGris2", "Sorel", "Brenn", "Glub" },
		Offer = { Place = "OficinasFinanciero" },
		OfferKey = "La sede del Consorcio. Escamas da la señal: «Ahora»",
		Requires = after("Saga_20_Aliados"),
		Moment = "Hiciste caer al Consorcio",
		Memory = "CaidaConsorcio",
		Rewards = { Flags = { "ConsorcioCaido" }, Money = 200 },
		Props = {
			Servidor = { Kind = "Maquina", Name = "El servidor central del Consorcio", Prompt = "Conectar la memoria de Escamas", Place = "OficinasFinanciero", Offset = V(0, 0, 10), Color = Color3.fromRGB(60, 60, 70), Dialogue = "Servidor", Once = true },
		},
		Steps = {
			{ Type = "Fight", Place = "OficinasFinanciero", Respawn = "OficinasFinanciero", Action = "Desconectar ⚡", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160),
				Text = "Asalta la sede del Consorcio: supera a la seguridad ({count}/{total})",
				CaughtLine = "(Te derriban. Sorel te saca de ahí a rastras.)",
				Actors = { { Npc = "Sorel", Place = "OficinasFinanciero", Offset = V(-6, 0, 10), Mode = "Point" }, { Npc = "AgenteGris2", Place = "OficinasFinanciero", Offset = V(6, 0, 10), Mode = "Point", If = { Flags = { "GrisArrepentida" } } } },
				Enemies = {
					{ Npc = "RobotSeguridad", Offset = V(-6, 0, 2), Speed = 10, HP = 5, Bye = "(Se apaga.)" },
					{ Npc = "AgenteGris1", Offset = V(6, 0, 2), Speed = 12, Bye = "(Retrocede y huye por la escalera de emergencia.)" },
				} },
			{ Type = "Use", Prop = "Servidor", Text = "Conecta la memoria de Escamas al servidor central",
				Actors = { { Npc = "Brenn", Place = "OficinasFinanciero", Offset = V(-3, 0, 8) }, { Npc = "Sorel", Place = "OficinasFinanciero", Offset = V(3, 0, 8) } } },
			{ Type = "Scene", Dialogue = "Quiebra",
				Actors = {
					{ Npc = "Glub", Place = "OficinasFinanciero", Offset = V(0, 0, 4) },
					{ Npc = "Brenn", Place = "OficinasFinanciero", Offset = V(-3, 0, 8), Mode = "Cheer" },
					{ Npc = "Sorel", Place = "OficinasFinanciero", Offset = V(3, 0, 8), Mode = "Cheer" },
				} },
		},
		Dialogues = {
			Servidor = { Lines = {
				{ S = "Narrador", T = "Conectas la memoria de Escamas. Las cuentas del Consorcio llenan todas las pantallas." },
				{ S = "Brenn", T = "Mundos comprados por debajo de su precio después de cada Caída. Decenas.", Shot = "DosPlanos:Brenn,Sorel" },
				{ S = "Sorel", T = "Y una transferencia enorme: «Laboratorio Dr. Cósimo. Proyecto Fusión».", To = "Brenn" },
			} },
			Quiebra = { Lines = {
				{ S = "Glub", T = "Agente Glub, del Banco Galáctico. Hemos recibido un informe contable impecable, firmado por un tal Escamas.", Shot = "General" },
				{ S = "Glub", T = "El Consorcio queda intervenido. Cuentas congeladas en todos los mundos. El doctor Cósimo se queda sin financiación." },
				{ S = "Sorel", T = "Sin dinero, Cósimo solo tiene una salida: hacer la Fusión él solo. Viene a por el Ancla. Ahora sí." },
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
		Description = "Esta noche alguien llama a la puerta de tu casa. Es Cósimo. Viene solo, sin dinero y sin ejército. Trae una oferta.",
		Type = "Saga de la Grieta · Acto IV (4/6)",
		Duration = { 15, 25 },
		Npcs = { "Cosimo" },
		Offer = { Place = "Home" },
		OfferKey = "Llaman a la puerta de tu casa a estas horas",
		Requires = after("Saga_21_Consorcio", { Hours = { From = 20, To = 6 } }),
		Moment = "Le dijiste que no a Cósimo",
		Memory = "ElTrato",
		Steps = {
			{ Type = "Talk", Npc = "Cosimo", Dialogue = "Oferta", Text = "Llaman a tu puerta: ábrela",
				Actors = { { Npc = "Cosimo", Place = "Home", Offset = V(0, 0, 5) } } },
			{ Type = "Choice", Key = "Trato", Text = "Cósimo te ofrece un mundo en el que la Caída nunca ocurrió, a cambio de soltar el Ancla. ¿Qué haces?",
				Options = {
					{ Id = "No", Text = "«No.» Así de simple", Effects = { Traits = { Valentia = 2 } } },
					{ Id = "Trampa", Text = "Fingir que aceptas… para tenderle una trampa en el monte", Effects = { Traits = { Curiosidad = 1, Valentia = 1 }, Flags = { "TrampaCosimo" } } },
				},
				Actors = { { Npc = "Cosimo", Place = "Home", Offset = V(0, 0, 5) } } },
			{ Type = "Scene", Dialogue = "Respuesta", Actors = { { Npc = "Cosimo", Place = "Home", Offset = V(0, 0, 5) } } },
		},
		Dialogues = {
			Oferta = { Lines = {
				{ S = "Cosimo", T = "Buenas noches. Vengo solo. Ya no me queda nadie a quien mandar.", Shot = "Medio:Cosimo" },
				{ S = "Cosimo", T = "En el mundo fusionado, la Caída nunca ocurrió. Lía está viva. Solo tienes que soltar el Ancla." },
				{ S = "Cosimo", T = "Algunos de aquí no encajarán. Toda corrección tiene un margen de error.", Shot = "PrimerPlano:Cosimo", Pause = 0.6 },
			} },
			Respuesta = { Lines = {
				{ S = "Cosimo", T = "Como él. Siempre prefiriendo un mundo roto a uno arreglado por mí. Te espero en el Monte del Silencio.", If = { Choices = { Trato = "No" } } },
				{ S = "Cosimo", T = "Aceptas. En la cima del monte, mañana a medianoche. …Sé reconocer una mentira. Pero vendré igual.", If = { Choices = { Trato = "Trampa" } } },
				{ S = "Narrador", T = "Cósimo se va. Llamas a Cosme. Contesta al primer tono: estaba esperando." },
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
		Description = "Medianoche en el Monte del Silencio. La Grieta se abre del todo. Dos Valmar a punto de convertirse en una. Tus aliados a tu espalda. La batalla final.",
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
			-- ESCENA del motor (Happenings/Cielo): medianoche, el cielo se rompe (etapa 7) y sube Cósimo
			{ Type = "Cinematic", Id = "Grieta_Fusion", Props = { "Grieta" }, Actors = { { Npc = "Cosme", Place = CIMA, Offset = V(3, 0, 6) } } },
			{ Type = "Scene", Dialogue = "Llegada", Props = { "Grieta" },
				Actors = { { Npc = "Cosimo", Place = CIMA, Offset = V(0, 0, -6) }, { Npc = "Cosme", Place = CIMA, Offset = V(3, 0, 6) } } },
			{ Type = "Escape", Seconds = 25, Respawn = CIMA, Catch = 4, Props = { "Grieta" },
				Text = "La Grieta tira de ti: aguanta 25 s en la cima del monte",
				CaughtLine = "(La Grieta te arrastra. Cosme te agarra de la mano. Esta vez no te suelta.)",
				Actors = {
					{ Npc = "DronCosimo1", Place = CIMA, Offset = V(-10, 0, -4), Mode = "Hunt", Speed = 13, Prompt = false },
					{ Npc = "DronCosimo2", Place = CIMA, Offset = V(10, 0, -4), Mode = "Hunt", Speed = 13, Prompt = false },
					{ Npc = "Cosme", Place = CIMA, Offset = V(3, 0, 6), Mode = "Point" },
				} },
			{ Type = "Fight", Place = CIMA, Respawn = CIMA, Action = "Golpear ⚔", HP = 3, BeamColor = Color3.fromRGB(120, 255, 160), Props = { "Grieta" },
				Text = "Oleada en la cima: derriba drones y robots ({count}/{total})",
				CaughtLine = "(Una explosión te tumba. Un aliado te levanta. Vuelves a la cima.)",
				Actors = ALIADOS_FINAL,
				Enemies = {
					{ Npc = "DronCosimo1", Offset = V(-10, 0, -4), Speed = 13, Bye = "(Cae ladera abajo entre chispas.)" },
					{ Npc = "DronCosimo2", Offset = V(10, 0, -4), Speed = 13, Bye = "(Su núcleo estalla.)" },
					{ Npc = "DronCosimo3", Offset = V(0, 0, -8), Speed = 14, HP = 4, Bye = "(El dron de mando se estrella. Los demás pierden la formación.)" },
					{ Npc = "RobotSeguridad", Offset = V(0, 0, 4), Speed = 10, HP = 5, Bye = "(Se apaga.)" },
				} },
			{ Type = "Scene", Dialogue = "Restos", If = MUCHOS_RESTOS, Props = { "Grieta" },
				Actors = { { Npc = "Pip", Place = CIMA, Offset = V(0, 0, 10) }, { Npc = "Cosimo", Place = CIMA, Offset = V(0, 0, -6) } } },
			{ Type = "Fight", Place = CIMA, Respawn = CIMA, Action = "Golpear con la aguja ⚔", HP = 6, If = MUCHOS_RESTOS, BeamColor = Color3.fromRGB(120, 255, 160), Props = { "Grieta" },
				Text = "Los restos de la Grieta frenan a Cósimo: derrótalo",
				CaughtLine = "(Un golpe de energía te lanza lejos. Tus aliados te levantan.)",
				Actors = ALIADOS_FINAL,
				Enemies = {
					{ Npc = "Cosimo", Offset = V(0, 0, -6), Speed = 10, HP = 6, Hurt = "Veinte años… no voy a perder ahora.", Bye = "…Basta. Me rindo. (Se deja caer de rodillas.)" },
				} },
			{ Type = "Fight", Place = CIMA, Respawn = CIMA, Action = "Golpear con la aguja ⚔", HP = 10, If = POCOS_RESTOS, BeamColor = Color3.fromRGB(120, 255, 160), Props = { "Grieta" },
				Text = "Cósimo en persona: derrótalo",
				CaughtLine = "(Un golpe de energía te lanza lejos. Tus aliados te levantan.)",
				Actors = ALIADOS_FINAL,
				Enemies = {
					{ Npc = "Cosimo", Offset = V(0, 0, -6), Speed = 12, HP = 10, Hurt = "Veinte años… no voy a perder ahora.", Bye = "…Basta. Me rindo. (Se deja caer de rodillas.)" },
				} },
			{ Type = "Scene", Dialogue = "Rendicion", Props = { "Grieta" },
				Actors = {
					{ Npc = "Cosimo", Place = CIMA, Offset = V(0, 0, -4), Mode = "Sit" },
					{ Npc = "Cosme", Place = CIMA, Offset = V(3, 0, 2) },
					{ Npc = "Pip", Place = CIMA, Offset = V(0, 0, 10) },
					{ Npc = "TuMalvado", Place = CIMA, Offset = V(4, 0, 12), If = { Flags = { "AliadoMalvado" } } },
				} },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Cosimo", T = "Has venido. Y no vienes sin compañía. Lo sabía.", If = { Choices = { Trato = "No" } }, Shot = "Medio:Cosimo" },
				{ S = "Cosimo", T = "Aceptaste. Y traes un ejército. Ya sabía que mentías.", If = { Choices = { Trato = "Trampa" } }, Shot = "Medio:Cosimo" },
				{ S = "Cosme", T = "Cósimo. Todavía estás a tiempo. Apágala.", To = "Cosimo", Shot = "Hombro:Yo>Cosme" },
				{ S = "Cosimo", T = "¿Para volver a qué? Tú tuviste a Lía. Yo tuve una máquina y una tumba. ¡Drones!", To = "Cosme", G = "Point" },
			} },
			Restos = { Lines = {
				{ S = "Pip", T = "Los restos de la Grieta que devolvió a su sitio están reaccionando. Le frenan.", Shot = "Medio:Pip", G = "Point" },
			} },
			Rendicion = { Lines = {
				{ S = "Cosimo", T = "Veinte años preparando esto. Y me gana un guerrero recién salido de la Academia.", Shot = "Medio:Cosimo", A = "Sad", Pause = 0.6 },
				{ S = "Cosme", T = "Alguien me dijo que debí contar las cosas antes. Así que lo digo ahora.", If = { Flags = { "EnfadoConCosme" } }, To = "Yo" },
				{ S = "Cosme", T = "Alguien me perdonó una noche sin que me lo mereciera. Ahora me toca a mí.", If = { Flags = { "PerdonaACosme" } }, To = "Yo" },
				{ S = "Cosme", T = "Cósimo. Eres lo que yo habría sido sin Lía. No voy a odiarte por eso.", To = "Cosimo", Shot = "DosPlanos:Cosme,Cosimo" },
				{ S = "Cosimo", T = "…Eres insoportable, Cosme. En todos los mundos.", Pause = 0.6, A = "Sad" },
				{ Ask = "Cósimo te mira a ti. «¿Y tú qué harías conmigo, Ancla?»", Options = {
					{ T = "«Que vuelva. Que empiece de cero. En esta Valmar.»", Effects = { Flags = { "CosimoPerdonado" }, Traits = { Empatia = 2 } }, Then = {
						{ S = "Cosimo", T = "¿Aquí? ¿En el mundo que intenté borrar? …No sé si sabré. Pero lo intentaré. Gracias." },
					} },
					{ T = "«Que vuelva a la 66-B. A arreglar lo que rompió.»", Effects = { Flags = { "CosimoArregla66B" }, Traits = { Responsabilidad = 2 } }, Then = {
						{ S = "Cosimo", T = "¿Arreglar la 66-B? ¿Lo que yo mismo rompí? …Es lo único que me queda por hacer bien. Acepto." },
						{ S = "TuMalvado", T = "Yo iré con él. Alguien tiene que vigilar que cumpla.", If = { Flags = { "AliadoMalvado" } }, Shot = "Medio:TuMalvado", To = "Cosimo" },
					} },
				} },
				{ S = "Narrador", T = "La máquina de la Fusión se apaga. Pero la Grieta sigue abierta en el cielo, enorme, temblando." },
				{ S = "Cosme", T = "Ya no tira nadie de ella. Solo falta cerrarla. Para siempre.", Shot = "Reaccion:Cosme", To = "Yo" },
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
		Title = "Cerrar la Grieta",
		Description = "La Grieta sigue abierta. Para cerrarla para siempre hay que hacerlo desde los dos lados a la vez: Cosme aquí, Cósimo allí. Y tú en medio, sujetándolo todo por última vez.",
		Type = "Saga de la Grieta · Epílogo",
		Duration = { 20, 30 },
		Npcs = { "Cosme", "Cosimo", "Pip", "Sorel", "Brenn", "Kael" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme y Cósimo te esperan en el garaje. Juntos",
		Requires = { Stage = { Min = "Adulto" }, Completed = { "Saga_23_Fusion" } },
		Moment = "Cerraste la Grieta para siempre",
		Memory = "FinDeLaSaga",
		Rewards = { Items = { AgujaDeOro = 1 }, Flags = { "SagaCompleta" }, Money = 500 },
		Props = {
			Cosedora = { Kind = "Maquina", Name = "La Cosedora Dimensional (versión 2)", Place = "GarajeCosme", Offset = V(0, 0, -4), Color = Color3.fromRGB(200, 255, 220), Prompt = false },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Garaje", Props = { "Cosedora" },
				Actors = { COSME, { Npc = "Cosimo", Place = "GarajeCosme", Offset = V(-3, 0, 3) }, PIP, ESCAMAS } },
			{ Type = "Reach", Place = "Patio", Text = "Ve al patio de la Academia, donde clavaste el primer anclaje",
				Actors = { { Npc = "Cosme", Mode = "Follow" }, { Npc = "Cosimo", Mode = "Follow" }, { Npc = "Brenn", Mode = "Follow" }, { Npc = "Sorel", Mode = "Follow" } } },
			-- ESCENA del motor (Happenings/Cielo): la última costura (de la etapa 4 a cerrada) y el amanecer
			{ Type = "Cinematic", Id = "Grieta_Final",
				Actors = {
					{ Npc = "Cosme", Place = "Patio", Offset = V(2, 0, 3) },
					{ Npc = "Cosimo", Place = "Patio", Offset = V(-2, 0, 3) },
					{ Npc = "Brenn", Place = "Patio", Offset = V(-5, 0, 6) },
					{ Npc = "Sorel", Place = "Patio", Offset = V(5, 0, 6) },
					{ Npc = "Pip", Place = "Patio", Offset = V(0, 0, 8) },
				} },
			{ Type = "Scene", Dialogue = "Final",
				Actors = {
					{ Npc = "Cosme", Place = "Patio", Offset = V(2, 0, 3) },
					{ Npc = "Cosimo", Place = "Patio", Offset = V(-2, 0, 3) },
					{ Npc = "Brenn", Place = "Patio", Offset = V(-5, 0, 6), Mode = "Cheer" },
					{ Npc = "Sorel", Place = "Patio", Offset = V(5, 0, 6), Mode = "Cheer" },
					{ Npc = "Pip", Place = "Patio", Offset = V(0, 0, 8), Mode = "Cheer" },
				} },
		},
		Dialogues = {
			Garaje = { Lines = {
				{ S = "Cosme", T = "Esa pieza va al revés.", To = "Cosimo", Shot = "DosPlanos:Cosme,Cosimo" },
				{ S = "Cosimo", T = "Va al revés porque tú la habrías puesto al revés. En mi mundo también lo hacías.", To = "Cosme" },
				{ S = "Cosimo", T = "Voy a quedarme. Ya veré qué hago con un mundo que intenté borrar.", If = { Flags = { "CosimoPerdonado" } }, To = "Cosme" },
				{ S = "Cosimo", T = "Mañana vuelvo a la 66-B. Tengo un mundo entero que reparar.", If = { Flags = { "CosimoArregla66B" } }, To = "Cosme" },
				{ S = "Pip", T = "Llevan tres horas discutiendo. Es lo más parecido a una familia que ha habido aquí desde la Caída.", Shot = "Medio:Pip", To = "Yo" },
				{ S = "Cosme", T = "Hay que cerrarla desde los dos lados a la vez. Y tú en el centro: el patio de la Academia.", Shot = "Medio:Cosme", To = "Yo" },
			} },
			Final = { Lines = {
				{ S = "Cosimo", T = "Ya está. Ya no eres el Ancla. Ahora eres solo una persona.", Shot = "Medio:Cosimo", To = "Yo" },
				{ S = "Cosme", T = "Te lo digo ahora que tengo todos los recuerdos: estoy orgulloso de ti. Desde el primer día.", If = { Memories = { "CosmeRecuerda" } }, Pause = 0.5 },
				{ S = "Cosme", T = "Estoy orgulloso de ti. Desde el primer día.", IfNot = { Memories = { "CosmeRecuerda" } }, Pause = 0.5 },
				{ Ask = "¿Qué le dices a Cosme?", Options = {
					{ T = "«Gracias por no dejar de vigilar el cielo.»", Effects = { Rel = { Cosme = 20 } }, Then = {
						{ S = "Cosme", T = "Alguien tenía que hacerlo. Me alegro de que al final no fuera solo yo." },
					} },
					{ T = "«¿Y ahora qué?»", Effects = { Rel = { Cosme = 15 }, Traits = { Curiosidad = 2 } }, Then = {
						{ S = "Cosme", T = "Ahora, por primera vez en dos años, voy a dormir una noche entera. Mañana ya veremos." },
					} },
				} },
				{ S = "Brenn", T = "Mi hermano habría querido ver esto.", Shot = "DosPlanos:Brenn,Sorel" },
				{ S = "Kael", T = "Hoy no ha caído nadie. Apúntalo: no pasa a menudo." },
				{ S = "Pip", T = "Doctor. Hay una señal muy débil al otro lado de la costura. Es la baliza del laboratorio de Lía. Sigue emitiendo.", Pause = 0.8 },
				{ S = "Cosme", T = "…Eso no es posible.", Shot = "PrimerPlano:Cosme" },
				{ S = "Narrador", T = "Recibes 🧵 la Aguja de oro. FIN DE LA SAGA DE LA GRIETA." },
				{ S = "Narrador", T = "La Grieta está cerrada. Pero algo, al otro lado, sigue llamando.", Pause = 1 },
			} },
		},
	},
}
