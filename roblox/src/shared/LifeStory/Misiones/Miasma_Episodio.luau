-- SAGA 2 «RAGNAROCK» · MIASMA · ANCLAJE SIETE: la primera parte jugable (unos 30 minutos) del episodio 6
-- «Guerra en el cielo» (docs/planetas/diseno-mundos.md §3.6; marco común: docs/planetas/marco-planetas.md).
-- Misiones CANÓNICAS: su marca dorada sale en Anclaje Siete y empiezan solas al llegar al sitio. Solo en
-- Miasma (Requires.Planet). Lugares «Miasma_…» (shared/Cosmos/MiasmaCity.StorySpots).
--
--   1 Miasma_01_Asedio   «Bajo el asedio»       llegas entre cañonazos, Mara, las toxinas (tutorial), la cantina
--   2 Miasma_02_Racion   «Ración doble»         faltan latas: pistas, la Señora Garúa y sus nietos (decisión)
--   3 Miasma_03_Filtros  «Aire para el Lastre»  el oficio de filtrador y el musgo filtro para el taller de Bruma
--   4 Miasma_04_Ataque   «El ataque»            el Dominio aborda las Góndolas: huida, pelea y dos góndolas (decisión)
--   5 Miasma_05_Senal    «La señal del Seis»    la radio de la Abuela Niebla, la antena, una canción desde abajo
-- Termina con el gancho del episodio: el Anclaje Seis vive bajo la niebla, y Mara esconde algo sobre el bloqueo.
-- 13+: sin sangre; los soldados del Dominio se rinden; la góndola que cae, cae fuera de cámara (pañuelo).

local V = Vector3.new

local TIPO = "Saga 2 · Miasma · «Guerra en el cielo»"

local function after(id: string?, extra: { [string]: any }?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Miasma" }
	if id then
		req.Completed = { id }
	end
	for key, value in extra or {} do
		req[key] = value
	end
	return req
end

local function at(npc: string, place: string, x: number, z: number, mode: string?): { [string]: any }
	return { Npc = npc, Place = place, Offset = V(x, 0, z), Mode = mode }
end
local MARA_SIGUE = { Npc = "MaraSolis", Mode = "Follow" }
local LEO_SIGUE = { Npc = "LeoSolis", Mode = "Follow" }

return {
	---------------------------------------------------------------------
	-- 1 · Bajo el asedio
	---------------------------------------------------------------------
	{
		Id = "Miasma_01_Asedio",
		Kind = "Side",
		Canon = true,
		Title = "Bajo el asedio",
		Description = "Has aterrizado en Anclaje Siete, la última ciudad de Miasma, en mitad de un asedio. La flota del Dominio Talar bloquea el cielo y abajo solo hay niebla venenosa.",
		Type = TIPO .. " (1/5)",
		Duration = { 6, 8 },
		Npcs = { "MaraSolis", "BrumaTaller" },
		Offer = { Place = "Miasma_Plataforma" },
		OfferKey = "Anclaje Siete. La batería antiaérea gira hacia el cielo",
		Requires = after(nil),
		Moment = "Llegaste a Anclaje Siete, la ciudad sobre la niebla",
		Memory = "LlegadaMiasma",
		Rewards = { Money = 60, Flags = { "MiasmaLlegado" } },
		Steps = {
			{ Type = "Cinematic", Id = "Miasma_Llegada", Actors = { at("MaraSolis", "Miasma_Plataforma", 3, 2) } },
			{ Type = "Talk", Npc = "MaraSolis", Dialogue = "Llegada", Text = "Habla con la piloto que te hace señas en la plataforma", Actors = { at("MaraSolis", "Miasma_Plataforma", 3, 2) } },
			{ Type = "Reach", Place = "Miasma_BordeLastre", Text = "Sigue a Mara por la pasarela del sur hasta el borde del Barrio Lastre", Actors = { MARA_SIGUE } },
			{ Type = "Talk", Npc = "MaraSolis", Dialogue = "Filtro", Text = "Mara quiere enseñarte algo antes de que respires más", Actors = { at("MaraSolis", "Miasma_BordeLastre", 3, -3) } },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Miasma" }, Place = "Miasma_BordeLastre",
				Text = "Usa una 🫧 cápsula de aire limpio de la mochila (mira tu medidor de ☣ toxinas)", Actors = { at("MaraSolis", "Miasma_BordeLastre", 3, -3) } },
			{ Type = "Reach", Place = "Miasma_CantinaDentro", Text = "Entra con Mara en la cantina El Lastre (dentro el aire está filtrado)", Actors = { MARA_SIGUE } },
			{ Type = "Scene", Dialogue = "Cantina", Actors = { at("MaraSolis", "Miasma_CantinaDentro", 2, 1), at("BrumaTaller", "Miasma_CantinaDentro", -3, 2) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "MaraSolis", T = "¡Eh, tú! ¡El de la nave bonita! ¿Has aterrizado en mitad de un asedio a propósito?", To = "Yo", A = "Surprised" },
				{ S = "MaraSolis", T = "Mara Solís. Contrabandista. No lo digas muy alto, que aquí la Defensa tiene oídos hasta en los globos.", Shot = "Medio:MaraSolis" },
				{ S = "MaraSolis", T = "Esas luces de arriba son la flota del Dominio Talar. Quieren nuestro gas. Llevan tres semanas esperando.", Beat = "Mira" },
				{ S = "MaraSolis", T = "Y lo de abajo es la niebla. Si caes, no hay suelo. Hay veneno. Ven, que te enseño a respirar aquí.", To = "Yo" },
			} },
			Filtro = { Lines = {
				{ S = "MaraSolis", T = "¿Notas el picor en la garganta? Es la niebla. En Lastre sube casi hasta las pasarelas.", To = "Yo" },
				{ S = "MaraSolis", T = "Mira tu medidor. Si se pone rojo, toses, te mareas y te caes. Aquí nadie se muere de un golpe: se muere poco a poco.", G = "Point" },
				{ S = "MaraSolis", T = "Toma: una máscara de filtro y dos cápsulas de aire limpio. Regalo de la casa. La próxima, la pagas.", Effects = { Items = { MascaraFiltro = 1, CapsulaAire = 2 } } },
				{ S = "MaraSolis", T = "Una cápsula, ahora. Respira hondo. Eso es el aire de antes de la niebla, embotellado.", To = "Yo" },
			} },
			Cantina = { Lines = {
				{ S = "BrumaTaller", T = "¿Otro forastero, Mara? ¿Este también viene a por el gas o a por tus rutas?", To = "MaraSolis", Shot = "Medio:BrumaTaller" },
				{ S = "MaraSolis", T = "Este viene a por un caldo de musgo, Bruma. Y a ayudar, si se deja.", A = "Shrug" },
				{ S = "MaraSolis", T = "Siete Anclajes había en Miasma. Quedamos nosotros. Los otros seis se los tragó la niebla.", To = "Yo", Beat = "Piensa" },
				{ S = "MaraSolis", T = "Mi hijo, Leo, quiere ser piloto de la Defensa. Tiene quince años. Yo quiero sacarlo de aquí antes de que lo consiga.", A = "Sad" },
				{ S = "BrumaTaller", T = "Si te quedas, forastero, en la Plaza falta comida y en mi taller faltan manos. Elige.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 2 · Ración doble (dilema: en un asedio, todo el mundo es un poco ladrón)
	---------------------------------------------------------------------
	{
		Id = "Miasma_02_Racion",
		Kind = "Side",
		Canon = true,
		Title = "Ración doble",
		Description = "En el racionamiento de la Plaza de las Veletas faltan latas. Acaparar comida durante el asedio es delito. Pía, la racionadora, necesita a alguien de fuera que no conozca a nadie.",
		Type = TIPO .. " (2/5)",
		Duration = { 6, 8 },
		Npcs = { "RacionadoraPia", "SenoraGarua" },
		Offer = { Place = "Miasma_Racionamiento" },
		OfferKey = "Pía cuenta latas por segunda vez y frunce el ceño",
		Requires = after("Miasma_01_Asedio"),
		Moment = "Descubriste quién se llevaba las raciones de la Plaza",
		Memory = "RacionDoble",
		Rewards = { Money = 70 },
		Props = {
			Lata = { Kind = "Caja", Name = "Una lata vacía", Prompt = "Mirar", Place = "Miasma_PlazaEste", Offset = V(3, 0, 2), Dialogue = "Lata", Once = true },
			Huellas = { Kind = "Marcador", Name = "Huellas de barro verde", Prompt = "Seguir", Place = "Miasma_Gondolas", Offset = V(-4, 0, 0), Dialogue = "Huellas", Once = true },
			Dibujo = { Kind = "Papel", Name = "Un dibujo infantil", Prompt = "Coger", Place = "Miasma_GondolaGarua", Offset = V(-3, 0, 4), Dialogue = "Dibujo", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "RacionadoraPia", Dialogue = "Faltan", Text = "Habla con Pía en el racionamiento de la Plaza de las Veletas", Actors = { at("RacionadoraPia", "Miasma_Racionamiento", 0, 3) } },
			{ Type = "Group", Text = "Busca pistas de quién se lleva las latas",
				Steps = {
					{ Type = "Use", Prop = "Lata", Text = "Junto a los puestos de la Plaza" },
					{ Type = "Use", Prop = "Huellas", Text = "En la pasarela de las Góndolas" },
					{ Type = "Use", Prop = "Dibujo", Text = "Junto a una góndola" },
				} },
			{ Type = "Talk", Npc = "SenoraGarua", Dialogue = "Garua", Text = "Llama a la góndola de los Garúa", Actors = { at("SenoraGarua", "Miasma_GondolaGarua", 0, -1) } },
			{ Type = "Choice", Key = "MiasmaGarua", Text = "La Señora Garúa guarda latas para sus nietos, que tosen de niebla. ¿Qué haces?",
				Options = {
					{ Id = "Denunciar", Text = "Contárselo a Pía: las raciones son de todos", Effects = { Flags = { "GaruaDenunciada" }, Rel = { RacionadoraPia = 10 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Callar", Text = "Callar. No has visto nada", Effects = { Flags = { "GaruaCallada" }, Rel = { SenoraGarua = 10 }, Traits = { Empatia = 1 } } },
					{ Id = "Medicinas", Text = "Pagar tú unas medicinas para los críos (30 €) y que devuelva las latas", Effects = { Spend = 30, Flags = { "NietosCurados" }, Rel = { SenoraGarua = 20, RacionadoraPia = 5 }, Traits = { Empatia = 1 } } },
				},
				Actors = { at("SenoraGarua", "Miasma_GondolaGarua", 0, -1) } },
			{ Type = "Scene", Dialogue = "Final", Actors = { at("RacionadoraPia", "Miasma_GondolaGarua", -3, -2), at("SenoraGarua", "Miasma_GondolaGarua", 2, 2) } },
		},
		Dialogues = {
			Faltan = { Lines = {
				{ S = "RacionadoraPia", T = "Doce latas. Ayer había doce más. Las he contado dos veces. Tres.", Shot = "Medio:RacionadoraPia" },
				{ S = "RacionadoraPia", T = "Tú eres de fuera: a ti no te van a mentir por costumbre. ¿Me ayudas a saber quién es?", To = "Yo" },
				{ S = "RacionadoraPia", T = "Si es un acaparador, se lo diré a la Policía del Muelle. Si no… ya veremos.", A = "Sad" },
			} },
			Lata = { Lines = {
				{ S = "Narrador", T = "Una lata vacía detrás del puesto. Rascada con cuchara hasta brillar. Quien la vació tenía hambre de verdad." },
			} },
			Huellas = { Lines = {
				{ S = "Narrador", T = "Huellas de barro verde, pequeñas y grandes, que van hacia las Góndolas. El barro verde solo está en el borde, donde la niebla toca." },
			} },
			Dibujo = { Lines = {
				{ S = "Narrador", T = "Un dibujo con lápices de colores: dos niños tosiendo y una abuela con una lata en cada mano. Pone «GRACIAS ABUELA»." },
			} },
			Garua = { Lines = {
				{ S = "SenoraGarua", T = "Ya sé a qué vienes. Se te nota en la cara. Pasa, pero no hagas ruido: duermen.", Shot = "Medio:SenoraGarua" },
				{ S = "SenoraGarua", T = "Mis nietos bajaron al borde a buscar musgo. Tosen desde entonces. Con media ración no se curan.", A = "Sad" },
				{ S = "SenoraGarua", T = "Sí, me llevé las latas. Y me las volvería a llevar. Haz lo que tengas que hacer.", To = "Yo" },
			} },
			Final = { Lines = {
				{ S = "RacionadoraPia", T = "Lo siento, Garúa. Las normas son las normas. Pero hablaré con la Defensa por tus nietos.", If = { Choices = { MiasmaGarua = "Denunciar" } } },
				{ S = "SenoraGarua", T = "…Gracias por no ver nada. Algún día te devolveré el favor. Con latas, si quieres.", If = { Choices = { MiasmaGarua = "Callar" } } },
				{ S = "RacionadoraPia", T = "Medicinas pagadas y doce latas de vuelta. En un asedio, esto es casi un milagro.", If = { Choices = { MiasmaGarua = "Medicinas" } } },
				{ S = "SenoraGarua", T = "Ya respiran mejor. Mira cómo duermen. Eres buena gente, forastero.", If = { Choices = { MiasmaGarua = "Medicinas" } } },
				{ S = "RacionadoraPia", T = "En un asedio todo el mundo es un poco ladrón. Lo difícil es saber de quién.", To = "Yo", Beat = "Piensa" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 3 · Aire para el Lastre (el oficio de filtrador y el material del planeta)
	---------------------------------------------------------------------
	{
		Id = "Miasma_03_Filtros",
		Kind = "Side",
		Canon = true,
		Title = "Aire para el Lastre",
		Description = "Los filtros de las estaciones del borde están sucios y en Barrio Lastre la gente tose. La vieja Bruma no da abasto: necesita un filtrador y espora de filtro fresca.",
		Type = TIPO .. " (3/5)",
		Duration = { 7, 10 },
		Npcs = { "BrumaTaller" },
		Offer = { Place = "Miasma_Taller" },
		OfferKey = "Bruma tose detrás del mostrador del taller de filtros",
		Requires = after("Miasma_01_Asedio"),
		Moment = "Cambiaste los filtros del Barrio Lastre",
		Memory = "AireParaLastre",
		Rewards = { Money = 80, Items = { CapsulaAire = 2 } },
		Steps = {
			{ Type = "Talk", Npc = "BrumaTaller", Dialogue = "Trato", Text = "Habla con la vieja Bruma en el taller de filtros de Lastre", Actors = { at("BrumaTaller", "Miasma_Taller", 0, 3) } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "MiasmaFiltrador" }, Count = 2, Place = "Miasma_Taller",
				Text = "Trabaja de filtrador: tablón «Trabajar» en la puerta del taller (cambia 2 filtros)" },
			{ Type = "Event", Event = "PlanetGather", Match = { Item = "EsporaFiltro" }, Place = "Miasma_Gondolas",
				Text = "Recoge espora de filtro: el musgo amarillo de las Góndolas o de Lastre («Recoger»)" },
			{ Type = "Talk", Npc = "BrumaTaller", Dialogue = "Gracias", Text = "Lleva la espora a Bruma", Actors = { at("BrumaTaller", "Miasma_Taller", 0, 3) } },
		},
		Dialogues = {
			Trato = { Lines = {
				{ S = "BrumaTaller", T = "Tos, tos. No es la niebla, es la risa. Me río mucho. Bueno, y la niebla.", Shot = "Medio:BrumaTaller", A = "Laugh" },
				{ S = "BrumaTaller", T = "Las estaciones del borde chupan la niebla y escupen aire. Si el filtro se ensucia, escupen veneno.", To = "Yo" },
				{ S = "BrumaTaller", T = "Coge un filtro nuevo, cámbialo, y tráeme el sucio: lo limpio con esporas. Te pago como a un filtrador de verdad.", G = "Point" },
				{ S = "BrumaTaller", T = "Y si ves musgo filtro, el amarillo, tráeme un puñado. Sin espora no hay filtros. Sin filtros no hay Lastre.", To = "Yo" },
			} },
			Gracias = { Lines = {
				{ S = "BrumaTaller", T = "Espora fresca. Huele a lluvia de antes. Hacía meses que nadie me traía de esta.", Shot = "Medio:BrumaTaller" },
				{ S = "BrumaTaller", T = "Toma, dos cápsulas. Y el tablón sigue ahí: cuando quieras, hay filtros que cambiar.", To = "Yo", Effects = { Rel = { BrumaTaller = 10 } } },
				{ S = "BrumaTaller", T = "Por cierto: el comandante Andrés busca manos en el hangar. Dicen que el Dominio prepara algo para esta noche.", Beat = "Mira" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 4 · El ataque (huida, pelea y una decisión que duele)
	---------------------------------------------------------------------
	{
		Id = "Miasma_04_Ataque",
		Kind = "Side",
		Canon = true,
		Title = "El ataque",
		Description = "El Dominio Talar lanza un ataque contra las Góndolas, el barrio de las casas colgadas de globos. El comandante Andrés necesita a todo el que sepa correr.",
		Type = TIPO .. " (4/5)",
		Duration = { 7, 9 },
		Npcs = { "ComandanteAndres", "LeoSolis", "SoldadoDominio1", "SoldadoDominio2" },
		Offer = { Place = "Miasma_Hangar" },
		OfferKey = "El comandante Andrés reparte cascos en el hangar de la Defensa",
		Requires = after("Miasma_03_Filtros", { Completed = { "Miasma_02_Racion", "Miasma_03_Filtros" } }),
		Moment = "Defendiste las Góndolas del ataque del Dominio",
		Memory = "PanuelosMiasma",
		Rewards = { Money = 100, Items = { PanueloMiasma = 1 } },
		Steps = {
			{ Type = "Talk", Npc = "ComandanteAndres", Dialogue = "Defensa", Text = "Habla con el comandante Andrés en el hangar de la Defensa",
				Actors = { at("ComandanteAndres", "Miasma_Hangar", 2, 2), at("LeoSolis", "Miasma_Hangar", -2, 3) } },
			{ Type = "Cinematic", Id = "Miasma_Ataque", Actors = { at("ComandanteAndres", "Miasma_Hangar", 2, 2), at("LeoSolis", "Miasma_Hangar", -2, 3) } },
			{ Type = "Escape", Place = "Miasma_Gondolas", Respawn = "Miasma_Plataforma", Catch = 4,
				Text = "¡Corre a las Góndolas por la pasarela del norte sin que te alcancen los del Dominio!",
				CaughtLine = "(Un soldado te corta el paso en la pasarela. Leo te agarra y te saca por debajo de un globo.)",
				Actors = {
					LEO_SIGUE,
					{ Npc = "SoldadoDominio1", Place = "Miasma_Torre", Offset = V(6, 0, -8), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Fight", Place = "Miasma_Gondolas", Respawn = "Miasma_Panuelos", Action = "Derribar 💥", HP = 4,
				Text = "¡Dos soldados del Dominio en las Góndolas! Derríbalos antes de que corten los cables ({count}/{total})",
				CaughtLine = "(Te tiran al suelo de la pasarela. Leo te ayuda a levantarte: «¡Otra vez!».)",
				Actors = { at("LeoSolis", "Miasma_Gondolas", -4, 4, "Point") },
				Enemies = {
					{ Npc = "SoldadoDominio1", Offset = V(-8, 0, -10), Speed = 10, HP = 3, Bye = "¡Me rindo! ¡No disparéis, me rindo!" },
					{ Npc = "SoldadoDominio2", Offset = V(8, 0, -12), Speed = 11, HP = 3, Bye = "Nuestra nave se ha ido… nos han dejado aquí." },
				} },
			{ Type = "Choice", Key = "MiasmaGondolas", Text = "¡Los del Dominio han cortado dos cables! Dos góndolas se sueltan a la vez y solo da tiempo a enganchar una. ¿Cuál?",
				Options = {
					{ Id = "Hospital", Text = "La góndola de la enfermería, con los enfermos dentro", Effects = { Flags = { "GondolaHospital" }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Barrio", Text = "La góndola de los Garúa, con los niños dentro", Effects = { Flags = { "GondolaBarrio" }, Traits = { Empatia = 1 }, Rel = { SenoraGarua = 10 } } },
				},
				Actors = { at("LeoSolis", "Miasma_Gondolas", -4, 4) } },
			{ Type = "Scene", Dialogue = "Panuelo", Actors = { at("LeoSolis", "Miasma_Panuelos", 3, -6), at("ComandanteAndres", "Miasma_Panuelos", 3, -2) } },
		},
		Dialogues = {
			Defensa = { Lines = {
				{ S = "ComandanteAndres", T = "Tú eres el forastero que ayuda a Bruma. Bien. Esta noche necesito piernas, no pilotos.", To = "Yo", Shot = "Medio:ComandanteAndres" },
				{ S = "LeoSolis", T = "¡Yo sí soy piloto! Bueno, casi. Me falta despegar. Y aterrizar.", A = "Cheer" },
				{ S = "ComandanteAndres", T = "Leo, tú a la batería. Y no le digas a tu madre que te he visto aquí.", To = "LeoSolis", A = "ArmsCrossed" },
				{ S = "ComandanteAndres", T = "Si el Dominio ataca, irá a por las Góndolas. Si cortan los cables, las casas caen a la niebla.", To = "Yo" },
			} },
			Panuelo = { Lines = {
				{ S = "Narrador", T = "La otra góndola se pierde en la niebla, despacio, sin un ruido. Había tiempo para una. Solo para una." },
				{ S = "LeoSolis", T = "Había gente dentro. ¿Verdad? Había gente…", Shot = "PrimerPlano:LeoSolis", A = "Sad" },
				{ S = "ComandanteAndres", T = "Toma un pañuelo, chaval. Átalo a la barandilla. Aquí lo hacemos así.", To = "LeoSolis" },
				{ S = "ComandanteAndres", T = "Tú también. Has salvado a muchos esta noche. No a todos. Nunca a todos.", To = "Yo", Pause = 0.8 },
				{ S = "LeoSolis", T = "Mi madre dice que el Dominio conoce nuestras rutas. Que alguien se las ha dado. ¿Tú crees que es verdad?", To = "Yo", Beat = "Piensa" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 5 · La señal del Seis (el gancho del episodio)
	---------------------------------------------------------------------
	{
		Id = "Miasma_05_Senal",
		Kind = "Side",
		Canon = true,
		Title = "La señal del Seis",
		Description = "La Abuela Niebla escucha cada noche la radio con la antena hacia abajo, hacia la niebla. Esta noche jura que ha oído una canción. Una canción del Anclaje Seis, el que cayó hace cuarenta años.",
		Type = TIPO .. " (5/5)",
		Duration = { 5, 7 },
		Npcs = { "AbuelaNiebla", "MaraSolis" },
		Offer = { Place = "Miasma_GondolaNiebla" },
		OfferKey = "La Abuela Niebla te llama desde su góndola con la radio en las manos",
		Requires = after("Miasma_04_Ataque"),
		Moment = "Oíste una canción desde debajo de la niebla",
		Memory = "CancionDelSeis",
		Rewards = { Money = 90, Flags = { "MiasmaSenalSeis" }, World = { ["Miasma.Senal"] = true } },
		Props = {
			Radio = { Kind = "Caja", Name = "La antena de la Refinería", Prompt = "Girar la antena hacia abajo", Place = "Miasma_Antena", Offset = V(2, 0, 0), Dialogue = "Antena", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "AbuelaNiebla", Dialogue = "Radio", Text = "Habla con la Abuela Niebla en su góndola", Actors = { at("AbuelaNiebla", "Miasma_GondolaNiebla", 2, 2) } },
			{ Type = "Reach", Place = "Miasma_Antena", Text = "Ve a la antena de la Refinería: es la única que llega hasta la niebla" },
			{ Type = "Use", Prop = "Radio", Text = "Gira la antena hacia abajo, hacia la niebla" },
			{ Type = "Cinematic", Id = "Miasma_Senal", Actors = { at("AbuelaNiebla", "Miasma_Antena", -3, 2) } },
			{ Type = "Talk", Npc = "MaraSolis", Dialogue = "Codigos", Text = "Cuéntaselo a Mara en su hangar", Actors = { at("MaraSolis", "Miasma_HangarMara", 2, 1) } },
		},
		Dialogues = {
			Radio = { Lines = {
				{ S = "AbuelaNiebla", T = "Yo era del Seis, ¿sabes? Del Anclaje Seis. Cayó cuando yo tenía tu edad, más o menos.", Shot = "Medio:AbuelaNiebla" },
				{ S = "AbuelaNiebla", T = "Todos dicen que allí abajo no queda nadie. Pero anoche, en la radio… una canción. «La medusa dormilona».", A = "Sad" },
				{ S = "AbuelaNiebla", T = "Esa canción solo la cantábamos en el Seis. Solo allí. Sube a la antena grande de la Refinería, por favor.", To = "Yo" },
			} },
			Antena = { Lines = {
				{ S = "Narrador", T = "La antena chirría al girar. La radio escupe ruido de niebla… y, de pronto, debajo del ruido, una voz de niño que canta." },
			} },
			Codigos = { Lines = {
				{ S = "MaraSolis", T = "¿Una canción? ¿Desde el Seis? No digas tonterías. Allí abajo no se puede vivir.", Shot = "Medio:MaraSolis", A = "ArmsCrossed" },
				{ S = "MaraSolis", T = "…Aunque yo he volado bajo, muy bajo, por el Ojo de la Tormenta. Y he visto luces. Luces de casa.", Beat = "Piensa" },
				{ S = "MaraSolis", T = "Escucha: si alguien pregunta por mis rutas, tú no sabes nada. Nada. Ni la Defensa, ni el Dominio.", To = "Yo", A = "Nervous" },
				{ S = "MaraSolis", T = "Mañana te enseño a bajar a la niebla. Con traje. Si de verdad hay alguien allí, alguien tiene que ir a buscarlo.", To = "Yo" },
			} },
		},
	},
}
