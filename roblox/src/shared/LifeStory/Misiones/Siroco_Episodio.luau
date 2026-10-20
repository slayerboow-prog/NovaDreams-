-- SAGA 2 «RAGNAROCK» · SIROCO · PUERTO CALCINA: la primera parte jugable (unos 30 minutos) del episodio 2
-- «El último Gran Premio» (docs/planetas/diseno-mundos.md §3.2; marco común: docs/planetas/marco-planetas.md).
-- Misiones CANÓNICAS: su marca dorada sale en Puerto Calcina y empiezan solas al llegar al sitio. Solo en
-- Siroco (Requires.Planet). Lugares «Siroco_…» (shared/Cosmos/SirocoCity.StorySpots).
--
--   1 Siroco_01_HoraRoja  «Tormenta de fuego»     llegas en la hora roja, corres tras Rafa, la sed (tutorial)
--   2 Siroco_02_Deudas    «Deudas»                los cobradores de Hierro, la huida por el Zoco, Tavo (decisión)
--   3 Siroco_03_Agua      «El agua de Pozo Hondo» Luz, el oficio de aguador y el cactus de agua
--   4 Siroco_04_Chatarra  «Chatarra»              el Cementerio de Deslizadores, pelea por las piezas, Nina
--   5 Siroco_05_Arco      «El nombre tachado»     las flores bajo el nombre de Rafa, Marisa Duna, la Gran Vuelta
-- Termina con el gancho del episodio: la Gran Vuelta promete plazas en las Arcas al barrio que gane.
-- 13+: sin sangre; los cobradores te tiran al suelo y se van; nadie muere en cámara (Cholo murió hace diez años).

local V = Vector3.new

local TIPO = "Saga 2 · Siroco · «El último Gran Premio»"

local function after(id: string?, extra: { [string]: any }?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Siroco" }
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
local RAFA_SIGUE = { Npc = "RafaQuiroga", Mode = "Follow" }
local NINA_SIGUE = { Npc = "NinaQuiroga", Mode = "Follow" }

return {
	---------------------------------------------------------------------
	-- 1 · Tormenta de fuego
	---------------------------------------------------------------------
	{
		Id = "Siroco_01_HoraRoja",
		Kind = "Side",
		Canon = true,
		Title = "Tormenta de fuego",
		Description = "Has aterrizado en Puerto Calcina, la ciudad del cañón, justo cuando empieza la hora roja: el sol de Siroco crece cada año y a mediodía lo quema todo.",
		Type = TIPO .. " (1/5)",
		Duration = { 6, 8 },
		Npcs = { "RafaQuiroga", "NinaQuiroga" },
		Offer = { Place = "Siroco_Plataforma" },
		OfferKey = "Puerto Calcina. El aire tiembla de calor sobre la pista",
		Requires = after(nil),
		Moment = "Llegaste a Puerto Calcina en plena hora roja",
		Memory = "LlegadaSiroco",
		Rewards = { Money = 60, Flags = { "SirocoLlegado" } },
		Steps = {
			{ Type = "Cinematic", Id = "Siroco_Llegada", Actors = { at("RafaQuiroga", "Siroco_Plataforma", 3, 2) } },
			{ Type = "Talk", Npc = "RafaQuiroga", Dialogue = "Llegada", Text = "Habla con el mecánico que te grita desde la pista", Actors = { at("RafaQuiroga", "Siroco_Plataforma", 3, 2) } },
			{ Type = "Reach", Place = "Siroco_TallerDentro", Text = "¡Hora roja! Corre detrás de Rafa hasta su taller en los Boxes (por la sombra de los toldos)", Actors = { RAFA_SIGUE } },
			{ Type = "Scene", Dialogue = "Taller", Actors = { at("RafaQuiroga", "Siroco_TallerDentro", 3, 1), at("NinaQuiroga", "Siroco_TallerDentro", -3, 2) } },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Siroco" }, Place = "Siroco_TallerDentro",
				Text = "Bebe 💧 agua fresca de la mochila (mira tu medidor de sed)", Actors = { at("NinaQuiroga", "Siroco_TallerDentro", -3, 2) } },
			{ Type = "Talk", Npc = "NinaQuiroga", Dialogue = "Nina", Text = "Habla con Nina, que te mira con cara de pocos amigos", Actors = { at("NinaQuiroga", "Siroco_TallerDentro", -3, 2), at("RafaQuiroga", "Siroco_TallerDentro", 3, 1) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "RafaQuiroga", T = "¡Eh! ¡Tú, el de la nave! ¿No ves la hora que es? ¡Es la hora roja, criatura del espacio!", To = "Yo", A = "Surprised" },
				{ S = "RafaQuiroga", T = "Rafa Quiroga. El Zorro. Campeón de la Gran Vuelta. Bueno, lo fui. ¡Corre, que se te derriten las botas!", Shot = "Medio:RafaQuiroga" },
				{ S = "RafaQuiroga", T = "Al taller. Por la sombra de los toldos. ¡Y no te pares a mirar el sol, que te deja ciego!", G = "Point" },
			} },
			Taller = { Lines = {
				{ S = "NinaQuiroga", T = "¿Otra vez trayendo gente, papá? Aquí no cabe ni un tornillo más.", To = "RafaQuiroga", Shot = "Medio:NinaQuiroga", A = "ArmsCrossed" },
				{ S = "RafaQuiroga", T = "Es un visitante, Nina. Un cliente, quizá. ¿Un cliente con dinero?", To = "Yo", A = "Shrug" },
				{ S = "NinaQuiroga", T = "Mira tu medidor de sed. En Siroco sube siempre, y al sol más. Si se pone rojo, te desmayas.", To = "Yo" },
				{ S = "NinaQuiroga", T = "Toma una cantimplora y dos botellas de agua fresca. Aquí el agua vale más que el dinero. Bebe una ya.", Effects = { Items = { Cantimplora = 1, AguaFresca = 2 } } },
			} },
			Nina = { Lines = {
				{ S = "NinaQuiroga", T = "Soy Nina. La que arregla lo que mi padre rompe. Que es todo.", Shot = "Medio:NinaQuiroga" },
				{ S = "RafaQuiroga", T = "¡Eso es mentira! Solo rompo lo importante.", A = "Laugh" },
				{ S = "NinaQuiroga", T = "Papá debe dinero a la Escudería Hierro. Mucho. Y sus cobradores no esperan a que acabe la hora roja.", To = "Yo", A = "Sad" },
				{ S = "RafaQuiroga", T = "Bah. Hoy no vendrán. Hace demasiado calor hasta para cobrar.", Beat = "Mira" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 2 · Deudas
	---------------------------------------------------------------------
	{
		Id = "Siroco_02_Deudas",
		Kind = "Side",
		Canon = true,
		Title = "Deudas",
		Description = "Los cobradores de Doña Hierro han venido a por Rafa. En Siroco, las deudas se cobran: si no pagas, te persiguen.",
		Type = TIPO .. " (2/5)",
		Duration = { 6, 8 },
		Npcs = { "RafaQuiroga", "CobradorHierro1", "CobradorHierro2", "TavoAguador" },
		Offer = { Place = "Siroco_Taller" },
		OfferKey = "Dos sombras con chaleco negro esperan en la puerta del taller",
		Requires = after("Siroco_01_HoraRoja"),
		Moment = "Escapaste de los cobradores de Hierro por el Zoco",
		Memory = "DeudasDeRafa",
		Rewards = { Money = 80 },
		Steps = {
			{ Type = "Scene", Dialogue = "Cobradores", Actors = { at("RafaQuiroga", "Siroco_Taller", 2, 2), at("CobradorHierro1", "Siroco_Taller", -6, -2), at("CobradorHierro2", "Siroco_Taller", -6, 4) } },
			{ Type = "Escape", Place = "Siroco_CantinaDentro", Respawn = "Siroco_Taller", Catch = 4,
				Text = "¡Huye con Rafa por el Zoco del Viento hasta la cantina sin que te pillen los cobradores!",
				CaughtLine = "¡Te pillé! …(Rafa tira un bidón al suelo, el cobrador resbala y seguís corriendo.)",
				Actors = {
					RAFA_SIGUE,
					{ Npc = "CobradorHierro1", Place = "Siroco_Taller", Offset = V(-10, 0, -4), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "CobradorHierro2", Place = "Siroco_Zoco", Offset = V(6, 0, 8), Mode = "Hunt", Speed = 10.5, Prompt = false },
				} },
			{ Type = "Talk", Npc = "TavoAguador", Dialogue = "Tavo", Text = "En la cantina os espera Tavo, el amigo de Rafa", Actors = { at("TavoAguador", "Siroco_CantinaDentro", 2, 2), at("RafaQuiroga", "Siroco_CantinaDentro", -2, 2) } },
			{ Type = "Choice", Key = "SirocoDeuda", Text = "Rafa debe 400 € a Doña Hierro. Si pagas una parte, los cobradores le darán una semana. ¿Qué haces?",
				Options = {
					{ Id = "Pagar", Text = "Pagar una parte de la deuda (40 €)", Effects = { Spend = 40, Flags = { "PagasteRafa" }, Rel = { RafaQuiroga = 15 }, Traits = { Empatia = 1 } } },
					{ Id = "NoPagar", Text = "No pagar: las deudas de Rafa son de Rafa", Effects = { Flags = { "NoPagasteRafa" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("TavoAguador", "Siroco_CantinaDentro", 2, 2), at("RafaQuiroga", "Siroco_CantinaDentro", -2, 2) } },
			{ Type = "Scene", Dialogue = "Despues", Actors = { at("TavoAguador", "Siroco_CantinaDentro", 2, 2), at("RafaQuiroga", "Siroco_CantinaDentro", -2, 2) } },
		},
		Dialogues = {
			Cobradores = { Lines = {
				{ S = "CobradorHierro1", T = "Rafa Quiroga. Doña Hierro manda saludos. Y una factura.", Shot = "DosPlanos:CobradorHierro1,CobradorHierro2", A = "ArmsCrossed" },
				{ S = "RafaQuiroga", T = "¡Chicos! ¡Qué alegría! Justo estaba pensando en vosotros. Y en correr.", To = "Yo", A = "Laugh" },
				{ S = "CobradorHierro2", T = "Ni se te ocurra, Zorro.", A = "Angry" },
				{ S = "RafaQuiroga", T = "¡Ahora!", To = "Yo", G = "Point" },
			} },
			Tavo = { Lines = {
				{ S = "TavoAguador", T = "¡Rafa! ¿Otra vez corriendo? A tu edad, con esa rodilla…", Shot = "Medio:TavoAguador", A = "Laugh" },
				{ S = "RafaQuiroga", T = "Tavo, el mejor amigo que tengo. Y el único. Es el jefe de los Aguadores.", To = "Yo" },
				{ S = "TavoAguador", T = "Hablaré con Doña Hierro. Pero quiere ver algo de dinero. Hoy.", To = "Yo", Beat = "Piensa" },
			} },
			Despues = { Lines = {
				{ S = "RafaQuiroga", T = "Te lo devolveré. Con intereses. Con intereses de campeón.", If = { Choices = { SirocoDeuda = "Pagar" } }, To = "Yo" },
				{ S = "TavoAguador", T = "Una semana, Rafa. Te he conseguido una semana. No la malgastes.", If = { Choices = { SirocoDeuda = "Pagar" } } },
				{ S = "RafaQuiroga", T = "Lo entiendo. Yo tampoco me prestaría dinero. Ya se me ocurrirá algo.", If = { Choices = { SirocoDeuda = "NoPagar" } }, A = "Shrug" },
				{ S = "TavoAguador", T = "Dicen que este año el gobierno dará plazas en las Arcas al barrio que gane la Gran Vuelta.", To = "RafaQuiroga" },
				{ S = "RafaQuiroga", T = "…Plazas en las Arcas. Para Nina. Para salir de este horno.", Pause = 0.8, Shot = "PrimerPlano:RafaQuiroga" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 3 · El agua de Pozo Hondo (el oficio de aguador y el cactus de agua)
	---------------------------------------------------------------------
	{
		Id = "Siroco_03_Agua",
		Kind = "Side",
		Canon = true,
		Title = "El agua de Pozo Hondo",
		Description = "En Pozo Hondo, el barrio del fondo del cañón, el agua se acaba. Luz reparte la que queda familia por familia y necesita a alguien que lleve los bidones.",
		Type = TIPO .. " (3/5)",
		Duration = { 7, 10 },
		Npcs = { "LuzPozo" },
		Offer = { Place = "Siroco_CasaLuz" },
		OfferKey = "Luz repasa la lista del agua en la puerta de su casa",
		Requires = after("Siroco_01_HoraRoja"),
		Moment = "Repartiste el agua de Pozo Hondo",
		Memory = "AguaDeTodos",
		Rewards = { Money = 80, Items = { AguaFresca = 2 } },
		Steps = {
			{ Type = "Talk", Npc = "LuzPozo", Dialogue = "Luz", Text = "Habla con Luz en la puerta de su casa de Pozo Hondo", Actors = { at("LuzPozo", "Siroco_CasaLuz", 2, 2) } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "SirocoAguador" }, Count = 2, Place = "Siroco_Fuente",
				Text = "Trabaja de aguador/a: el tablón «Trabajar» está junto a la fuente (haz 2 repartos)" },
			{ Type = "Event", Event = "PlanetGather", Match = { Item = "AguaFresca" }, Place = "Siroco_Zoco",
				Text = "Corta un cactus de agua con cuidado (hay uno en el Zoco y otro junto a los Boxes)" },
			{ Type = "Talk", Npc = "LuzPozo", Dialogue = "Gracias", Text = "Vuelve con Luz", Actors = { at("LuzPozo", "Siroco_CasaLuz", 2, 2) } },
		},
		Dialogues = {
			Luz = { Lines = {
				{ S = "LuzPozo", T = "¿Vienes de parte de Rafa? Entonces vienes a pedir. Aquí no hay nada que dar.", Shot = "Medio:LuzPozo", A = "ArmsCrossed" },
				{ S = "LuzPozo", T = "Ah, ¿vienes a ayudar? Eso es nuevo. Pozo Hondo se queda sin agua: la Guardia de Hierro cierra los pozos.", To = "Yo" },
				{ S = "LuzPozo", T = "Llena bidones en la fuente y llévalos a las casas de la roca. Sin derramar: cada gota es de alguien.", G = "Point" },
				{ S = "LuzPozo", T = "Y si ves un cactus de agua, córtalo por la base, en diagonal. Mal cortado, se pierde todo.", To = "Yo" },
			} },
			Gracias = { Lines = {
				{ S = "LuzPozo", T = "Seis familias con agua para dos días. Hoy dormirán sin sed. Gracias.", Shot = "Medio:LuzPozo" },
				{ S = "LuzPozo", T = "Toma, ropa de sol de los Clanes de la Duna. Con ella la sed te dará menos guerra.", To = "Yo", Effects = { Items = { RopaSol = 1 }, Rel = { LuzPozo = 10 } } },
				{ S = "LuzPozo", T = "Y dile a Rafa… no, no le digas nada. Que venga él, si se atreve.", Beat = "Aparta", A = "Sad" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 4 · Chatarra (el Cementerio de Deslizadores)
	---------------------------------------------------------------------
	{
		Id = "Siroco_04_Chatarra",
		Kind = "Side",
		Canon = true,
		Title = "Chatarra",
		Description = "Nina necesita tres piezas para algo que construye en secreto. En el Cementerio de Deslizadores, fuera de la ciudad, hay de todo. También chatarreros de la Escudería Hierro.",
		Type = TIPO .. " (4/5)",
		Duration = { 6, 8 },
		Npcs = { "NinaQuiroga", "CobradorHierro1", "CobradorHierro2" },
		Offer = { Place = "Siroco_Taller" },
		OfferKey = "Nina dibuja un motor en la pared del taller con un trozo de tiza",
		Requires = after("Siroco_02_Deudas", { Completed = { "Siroco_02_Deudas", "Siroco_03_Agua" } }),
		Moment = "Sacaste las piezas del Cementerio de Deslizadores",
		Memory = "CementerioDeslizadores",
		Rewards = { Money = 90, Items = { ChatarraAntigua = 2, VidrioTormenta = 1 } },
		Props = {
			Bobina = { Kind = "Caja", Name = "Una bobina de encendido", Prompt = "Desmontar", Place = "Siroco_Cementerio", Offset = V(-12, 0, 6), Dialogue = "Bobina", Once = true },
			Turbina = { Kind = "Caja", Name = "La turbina de un deslizador", Prompt = "Desmontar", Place = "Siroco_Cementerio", Offset = V(10, 0, 10), Dialogue = "Turbina", Once = true },
			Caja = { Kind = "Caja", Name = "Una caja de cambios antigua", Prompt = "Desmontar", Place = "Siroco_Cementerio", Offset = V(4, 0, -12), Dialogue = "Caja", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "NinaQuiroga", Dialogue = "Piezas", Text = "Habla con Nina en el taller", Actors = { at("NinaQuiroga", "Siroco_Taller", 2, 2) } },
			{ Type = "Reach", Place = "Siroco_Cementerio", Text = "Ve al Cementerio de Deslizadores (al este del cañón: mejor en tu nave)" },
			{ Type = "Group", Text = "Desmonta las tres piezas que necesita Nina",
				Steps = {
					{ Type = "Use", Prop = "Bobina", Text = "Una bobina de encendido" },
					{ Type = "Use", Prop = "Turbina", Text = "Una turbina" },
					{ Type = "Use", Prop = "Caja", Text = "Una caja de cambios" },
				} },
			{ Type = "Fight", Place = "Siroco_Cementerio", Respawn = "Siroco_Cementerio", Action = "Derribar 💥", HP = 4,
				Text = "¡Los chatarreros de Hierro quieren tus piezas! Derríbalos ({count}/{total})",
				CaughtLine = "(Te tiran a la arena. Las piezas siguen en tu mochila. Levántate.)",
				Enemies = {
					{ Npc = "CobradorHierro1", Offset = V(-10, 0, -10), Speed = 10, HP = 3, Bye = "¡Vale, vale! Quédatelas. Esto no me lo pagan." },
					{ Npc = "CobradorHierro2", Offset = V(10, 0, -12), Speed = 10.5, HP = 3, Bye = "Doña Hierro se va a enterar de esto…" },
				} },
			{ Type = "Reach", Place = "Siroco_TallerDentro", Text = "Vuelve al taller de Rafa con las piezas", Actors = { at("NinaQuiroga", "Siroco_TallerDentro", -3, 2) } },
			{ Type = "Scene", Dialogue = "Motor", Actors = { at("NinaQuiroga", "Siroco_TallerDentro", -3, 2) } },
		},
		Dialogues = {
			Piezas = { Lines = {
				{ S = "NinaQuiroga", T = "Necesito tres piezas. No preguntes para qué. Bueno, pregunta, pero no te lo voy a decir.", Shot = "Medio:NinaQuiroga" },
				{ S = "NinaQuiroga", T = "En el Cementerio de Deslizadores hay miles de máquinas rotas. Busca una bobina, una turbina y una caja de cambios.", To = "Yo" },
				{ S = "NinaQuiroga", T = "Cuidado con los chatarreros de Hierro: dicen que todo lo que hay allí es de su escudería.", G = "Point" },
			} },
			Bobina = { Lines = { { S = "Narrador", T = "Una bobina de encendido, enterrada en la arena. Todavía tiene el sello de la Ciudad Primera: un sol con los ojos cerrados." } } },
			Turbina = { Lines = { { S = "Narrador", T = "La turbina de un deslizador de carreras. Un número 7 pintado a mano en el carenado." } } },
			Caja = { Lines = { { S = "Narrador", T = "Una caja de cambios pesadísima. La arrastras como puedes hasta la mochila." } } },
			Motor = { Lines = {
				{ S = "NinaQuiroga", T = "La bobina es de la Ciudad Primera. Nadie sabe hacerlas ya. Con ella, un motor aguanta una tormenta.", Shot = "Medio:NinaQuiroga" },
				{ S = "NinaQuiroga", T = "Vale. Te lo enseño. Pero no se lo digas a mi padre.", Beat = "Mira" },
				{ S = "Narrador", T = "Detrás de una lona, medio deslizador: chapa nueva, piezas viejas y un número 7 en el morro." },
				{ S = "NinaQuiroga", T = "Es para Pozo Hondo. Si alguien de mi barrio gana la Gran Vuelta, nos toca un sitio en las Arcas. A todos.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 5 · El nombre tachado (el gancho del episodio)
	---------------------------------------------------------------------
	{
		Id = "Siroco_05_Arco",
		Kind = "Side",
		Canon = true,
		Title = "El nombre tachado",
		Description = "En el Arco del Campeón están tallados los nombres de todos los ganadores de la Gran Vuelta. Uno está tachado: el de Rafa. Y alguien le deja flores frescas.",
		Type = TIPO .. " (5/5)",
		Duration = { 5, 7 },
		Npcs = { "MarisaDuna", "RafaQuiroga" },
		Offer = { Place = "Siroco_PlazaArco" },
		OfferKey = "Bajo el Arco del Campeón hay flores frescas. En Siroco. Con este sol",
		Requires = after("Siroco_04_Chatarra"),
		Moment = "Supiste por qué el nombre de Rafa está tachado",
		Memory = "NombreTachado",
		Rewards = { Money = 100, Flags = { "SirocoGranVuelta" }, Items = { CascoNina = 1 }, World = { ["Siroco.GranVuelta"] = true } },
		Props = {
			Flores = { Kind = "Marcador", Name = "Flores frescas bajo el nombre tachado", Prompt = "Mirar", Place = "Siroco_Arco", Offset = V(14, 0, 4), Dialogue = "Flores", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "Siroco_Arco", Text = "Ve al Arco del Campeón, en mitad de La Recta" },
			{ Type = "Use", Prop = "Flores", Text = "Mira las flores bajo el nombre tachado" },
			{ Type = "Talk", Npc = "MarisaDuna", Dialogue = "Marisa", Text = "Habla con la señora que vuelve a por las flores", Actors = { at("MarisaDuna", "Siroco_PlazaArco", 2, 2) } },
			{ Type = "Cinematic", Id = "Siroco_Arco", Actors = { at("RafaQuiroga", "Siroco_Arco", 3, -4), at("MarisaDuna", "Siroco_PlazaArco", 2, 2) } },
			{ Type = "Talk", Npc = "RafaQuiroga", Dialogue = "GranVuelta", Text = "Rafa se ha quedado mirando su nombre", Actors = { at("RafaQuiroga", "Siroco_Arco", 3, -4), NINA_SIGUE } },
		},
		Dialogues = {
			Flores = { Lines = {
				{ S = "Narrador", T = "Tres flores de noche, abiertas, bajo «R. QUIROGA». Alguien las ha regado con su ración de agua." },
			} },
			Marisa = { Lines = {
				{ S = "MarisaDuna", T = "Son para Cholo, no para Rafa. Cholo era mi hijo. Su copiloto.", Shot = "Medio:MarisaDuna" },
				{ S = "MarisaDuna", T = "Hace diez años, en la Gran Vuelta, Rafa forzó el motor en la última curva. Ganó. Cholo no salió del deslizador.", A = "Sad" },
				{ S = "MarisaDuna", T = "La gente tachó su nombre. Yo vengo cada semana. No sé si a perdonarle o a recordárselo.", To = "Yo", Pause = 0.8 },
			} },
			GranVuelta = { Lines = {
				{ S = "RafaQuiroga", T = "Marisa tiene razón en todo. En todo menos en una cosa: yo no sabía que el motor estaba mal.", Shot = "PrimerPlano:RafaQuiroga", A = "Sad" },
				{ S = "NinaQuiroga", T = "Papá… La Gran Vuelta. Este año dan plazas en las Arcas al barrio que gane.", To = "RafaQuiroga" },
				{ S = "RafaQuiroga", T = "Lo sé, Nina. Y lo he pensado. Una última carrera. Por Pozo Hondo. Por ti. Por Cholo.", Beat = "Mira" },
				{ S = "RafaQuiroga", T = "Necesitaré un deslizador. Y un copiloto que no tenga miedo. ¿Te apuntas, criatura del espacio?", To = "Yo" },
				{ S = "NinaQuiroga", T = "Toma mi casco. El del 7. Trae suerte… a quien lo lleva. Y lo vas a necesitar.", To = "Yo", Effects = { Rel = { NinaQuiroga = 15 } } },
			} },
		},
	},
}
