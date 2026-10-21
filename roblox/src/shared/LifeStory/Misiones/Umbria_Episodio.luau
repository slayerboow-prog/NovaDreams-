-- SAGA 2 «RAGNAROCK» · UMBRÍA · RAÍZ HONDA: la primera parte jugable (unos 30 minutos) del episodio 5
-- «El Enjambre» (docs/planetas/diseno-mundos.md §3.5; lo que se juega: docs/planetas/nivalis-umbria.md;
-- marco común: docs/planetas/marco-planetas.md). Misiones CANÓNICAS: su marca dorada sale en Raíz Honda y
-- empiezan solas al llegar al sitio. Solo en Umbría (Requires.Planet). Lugares «Umbria_…»
-- (shared/Cosmos/UmbriaCity.StorySpots).
--
--   1 Umbria_01_Caida     «Caída lenta»          llegas bajo el Árbol Madre, Garza, las esporas (tutorial)
--   2 Umbria_02_Contrato  «El contrato»          la alcaldesa, las barricadas y la primera oleada (decisión)
--   3 Umbria_03_Savia     «Savia en las heridas» un turno de podador y lo que Nía esconde en su vaina (decisión)
--   4 Umbria_04_Baliza    «La baliza del Claro»  el Claro Muerto, la baliza de Torca y lo que Garza calla
--   5 Umbria_05_Socios    «Viejos socios»        la voz de Vesna y qué le dices a Garza (decisión)
-- Termina con el gancho del episodio: la Reina del Enjambre viene hacia Raíz Honda.
-- 13+: sin sangre; las máquinas del Enjambre caen en chispas; nadie muere en cámara.

local V = Vector3.new

local TIPO = "Saga 2 · Umbría · «El Enjambre»"

local function after(id: string?, extra: { [string]: any }?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Umbria" }
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
local GARZA_SIGUE = { Npc = "Garza", Mode = "Follow" }

return {
	---------------------------------------------------------------------
	-- 1 · Caída lenta
	---------------------------------------------------------------------
	{
		Id = "Umbria_01_Caida",
		Kind = "Side",
		Canon = true,
		Title = "Caída lenta",
		Description = "Has aterrizado en Raíz Honda, la ciudad viva tallada al pie de árboles de un kilómetro. Te espera Garza, un mercenario que vuelve a casa después de veinte años.",
		Type = TIPO .. " (1/5)",
		Duration = { 7, 9 },
		Npcs = { "Garza" },
		Offer = { Place = "Umbria_Plataforma" },
		OfferKey = "Raíz Honda. Huele a madera mojada y algo zumba muy lejos",
		Requires = after(nil),
		Moment = "Llegaste a Raíz Honda, al pie del Árbol Madre",
		Memory = "LlegadaUmbria",
		Rewards = { Money = 60, Flags = { "UmbriaLlegado" } },
		Steps = {
			{ Type = "Cinematic", Id = "Umbria_Llegada", Actors = { at("Garza", "Umbria_Plataforma", 3, 2) } },
			{ Type = "Talk", Npc = "Garza", Dialogue = "Llegada", Text = "Habla con el hombre de la chaqueta remendada", Actors = { at("Garza", "Umbria_Plataforma", 3, 2) } },
			{ Type = "Reach", Place = "Umbria_SueloHondo", Text = "Baja con Garza al Suelo Hondo, al bosque de setas de fuera de la empalizada (mira el medidor de 🍄 esporas)", Actors = { GARZA_SIGUE } },
			{ Type = "Event", Event = "HazardChanged", Match = { Planet = "Umbria", Phase = "Aviso" }, Place = "Umbria_SueloHondo",
				Text = "Busca con Garza el rastro de las máquinas entre las esporeras (cuidado: pican)", Actors = { at("Garza", "Umbria_SueloHondo", 3, 3) } },
			{ Type = "Talk", Npc = "Garza", Dialogue = "Mascarilla", Text = "¡Estornudas! Garza te llama", Actors = { at("Garza", "Umbria_SueloHondo", 3, 3) } },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Umbria" }, Place = "Umbria_SueloHondo",
				Text = "Úntate el 🍯 ungüento de savia (desde la mochila)", Actors = { at("Garza", "Umbria_SueloHondo", 3, 3) } },
			{ Type = "Talk", Npc = "Garza", Dialogue = "Vuelta", Text = "Garza te espera de vuelta en la Plaza de las Raíces", Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Garza", T = "Tú eres a quien mandaron. Bien. Me llamo Garza. Nací aquí. Hace mucho.", To = "Yo", Shot = "Medio:Garza" },
				{ S = "Garza", T = "Veinte años fuera y el Árbol Madre sigue igual. Nosotros no. Mira la empalizada: antes no hacía falta.", G = "Point" },
				{ S = "Garza", T = "Hay máquinas que se comen la madera y hacen más máquinas. Vamos a ver por dónde entran. Abajo, al Suelo.", A = "ArmsCrossed" },
			} },
			Mascarilla = { Lines = {
				{ S = "Garza", T = "Eso son esporas. Las esporeras sueltan polvo que brilla. Bonito. Y te deja sin respirar.", To = "Yo" },
				{ S = "Garza", T = "Mira tu medidor. Abajo sube; en la ciudad, poco; en un refugio, nada. Al anochecer llueven esporas.", G = "Point" },
				{ S = "Garza", T = "Toma: mascarilla de hojas, dos tarros de ungüento de savia y un farolillo de setas para la noche.", Effects = { Items = { MascarillaHojas = 1, UnguentoSavia = 2, FarolSetas = 1 } } },
				{ S = "Garza", T = "Úntate el ungüento debajo de la nariz. Huele a miel. Mi madre me lo ponía de pequeño.", Beat = "Piensa" },
			} },
			Vuelta = { Lines = {
				{ S = "Garza", T = "Ramas peladas, astillas, y ni una sola hoja en el suelo. Han pasado por aquí. Muchas.", To = "Yo", Shot = "Medio:Garza" },
				{ S = "Garza", T = "La alcaldesa Savia quiere vernos. Va a pedirme que me quede a defender la ciudad.", A = "Shrug" },
				{ S = "Garza", T = "Yo vine a cobrar un trabajo y a irme. Eso es lo que hago siempre.", Pause = 0.8 },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 2 · El contrato
	---------------------------------------------------------------------
	{
		Id = "Umbria_02_Contrato",
		Kind = "Side",
		Canon = true,
		Title = "El contrato",
		Description = "La alcaldesa Savia quiere contratar a Garza para defender Raíz Honda del Enjambre. Garza quiere su precio. Y el Vivero, la primera línea, no tiene barricadas.",
		Type = TIPO .. " (2/5)",
		Duration = { 7, 9 },
		Npcs = { "Garza", "AlcaldesaSavia", "DronEnjambre1", "DronEnjambre2", "DronEnjambre3" },
		Offer = { Place = "Umbria_Raices" },
		OfferKey = "Suena un cuerno desde el Tronco Mayor: dos toques largos",
		Requires = after("Umbria_01_Caida"),
		Moment = "Levantaste las barricadas del Vivero y viste caer la primera oleada",
		Memory = "PrimeraOleada",
		Rewards = { Money = 90, Items = { ChatarraEnjambre = 2 } },
		Props = {
			Barricada1 = { Kind = "Caja", Name = "Hueco oeste de la barricada", Prompt = "Poner los troncos", Place = "Umbria_Barricada1", Dialogue = "Troncos1", Once = true },
			Barricada2 = { Kind = "Caja", Name = "Hueco del centro", Prompt = "Tender la red de seda", Place = "Umbria_Barricada2", Dialogue = "Troncos2", Once = true },
			Barricada3 = { Kind = "Caja", Name = "Hueco este de la barricada", Prompt = "Clavar las estacas", Place = "Umbria_Barricada3", Dialogue = "Troncos3", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "AlcaldesaSavia", Dialogue = "Contrato", Text = "Ve con Garza al despacho de la alcaldesa, en el Tronco Mayor",
				Actors = { at("AlcaldesaSavia", "Umbria_AyuntamientoDentro", -2, 0), at("Garza", "Umbria_AyuntamientoDentro", 3, 2) } },
			{ Type = "Choice", Key = "UmbriaPaga", Text = "La alcaldesa le ofrece a Garza la mitad de lo que pide. Te mira a ti: «¿Y tú? ¿Cuánto cobras?» ¿Qué le dices?",
				Options = {
					{ Id = "Pedir", Text = "«Lo mismo que él.» Pedir tu paga", Effects = { Flags = { "UmbriaCobras" }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Gratis", Text = "«Nada. Esto lo hago gratis.»", Effects = { Flags = { "UmbriaGratis" }, Rel = { AlcaldesaSavia = 15 }, Traits = { Empatia = 1 } } },
				},
				Actors = { at("AlcaldesaSavia", "Umbria_AyuntamientoDentro", -2, 0), at("Garza", "Umbria_AyuntamientoDentro", 3, 2) } },
			{ Type = "Group", Text = "Tapa los tres huecos de la barricada del Vivero, en la Puerta Sur",
				Actors = { GARZA_SIGUE },
				Steps = {
					{ Type = "Use", Prop = "Barricada1", Text = "El hueco oeste" },
					{ Type = "Use", Prop = "Barricada2", Text = "El hueco del centro" },
					{ Type = "Use", Prop = "Barricada3", Text = "El hueco este" },
				} },
			{ Type = "Scene", Dialogue = "Zumbido", Actors = { at("Garza", "Umbria_PuertaSur", 3, -2) } },
			{ Type = "Fight", Place = "Umbria_PuertaSur", Respawn = "Umbria_Raices", Action = "Golpear 💥", HP = 4,
				Text = "¡La primera oleada! Derriba a las máquinas del Enjambre antes de que muerdan la madera ({count}/{total})",
				CaughtLine = "(Una máquina te tira al barro. Garza te levanta de un tirón: «¡Arriba!».)",
				Actors = { at("Garza", "Umbria_PuertaSur", 3, -2, "Point") },
				Enemies = {
					{ Npc = "DronEnjambre1", Offset = V(-10, 0, 14), Speed = 9, HP = 2, Bye = "*bzzzt… chispas*" },
					{ Npc = "DronEnjambre2", Offset = V(0, 0, 16), Speed = 10, HP = 2, Bye = "*clic-clic… chispas*" },
					{ Npc = "DronEnjambre3", Offset = V(10, 0, 14), Speed = 9.5, HP = 2, Bye = "*zzzum… chispas*" },
				} },
			{ Type = "Scene", Dialogue = "Chatarra", Actors = { at("Garza", "Umbria_PuertaSur", 3, -2) } },
		},
		Dialogues = {
			Contrato = { Lines = {
				{ S = "AlcaldesaSavia", T = "Garza. El hijo de Enea. Te fuiste con veinte años y vuelves con cuarenta y una nave.", To = "Garza", Shot = "Medio:AlcaldesaSavia" },
				{ S = "Garza", T = "Y con un precio, alcaldesa. Defender una ciudad cuesta. Lo sabes mejor que nadie.", A = "ArmsCrossed" },
				{ S = "AlcaldesaSavia", T = "Te pago la mitad. La otra mitad, cuando las máquinas se vayan. Si se van.", Beat = "Piensa" },
			} },
			Troncos1 = { Lines = { { S = "Narrador", T = "Troncos de madera muerta, cruzados. Ningún árbol vivo se corta en Raíz Honda. Nunca." } } },
			Troncos2 = { Lines = { { S = "Narrador", T = "La red de seda de liana no pesa nada y aguanta un escarabajo de carga." } } },
			Troncos3 = { Lines = { { S = "Narrador", T = "Estacas hacia fuera. Garza las prueba con el pie y asiente." } } },
			Zumbido = { Lines = {
				{ S = "Narrador", T = "Primero el zumbido. Luego, entre los helechos, un brillo de plata fría que se mueve a saltos." },
				{ S = "Garza", T = "Ahí están. Tres. Exploradoras. Si llegan a la madera, mañana serán seis.", To = "Yo", A = "Angry" },
				{ S = "Garza", T = "Al cuerpo no. A las patas. Sin patas no comen.", G = "Point" },
			} },
			Chatarra = { Lines = {
				{ S = "Garza", T = "Chatarra. En Umbría el metal no crece en los árboles: sale de ellas. Guárdala.", To = "Yo" },
				{ S = "Garza", T = "Bien pensado lo de cobrar. Los héroes gratis duran poco.", If = { Choices = { UmbriaPaga = "Pedir" } }, Shot = "Medio:Garza" },
				{ S = "Garza", T = "Gratis. Hace mucho que no oía esa palabra. Aquí la decía mi madre.", If = { Choices = { UmbriaPaga = "Gratis" } }, Shot = "Medio:Garza", A = "Sad" },
				{ S = "Garza", T = "Esto no era una oleada. Era una prueba. Están midiendo la empalizada.", Beat = "Mira" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 3 · Savia en las heridas
	---------------------------------------------------------------------
	{
		Id = "Umbria_03_Savia",
		Kind = "Side",
		Canon = true,
		Title = "Savia en las heridas",
		Description = "Las máquinas han mordido los árboles de Las Raíces. La podadora Liquen necesita manos para curarlos. Y una niña del Vivero esconde algo que zumba.",
		Type = TIPO .. " (3/5)",
		Duration = { 6, 8 },
		Npcs = { "PodadoraLiquen", "NiaVaina", "Dron7" },
		Offer = { Place = "Umbria_Ayuntamiento" },
		OfferKey = "Una podadora con el hacha al hombro mira las heridas de la corteza",
		Requires = after("Umbria_02_Contrato"),
		Moment = "Conociste a Dron 7, la máquina que no quería comerse la madera",
		Memory = "Dron7",
		Rewards = { Money = 80, Items = { SaviaAmbar = 2, MaderaHierro = 1 } },
		Props = {
			MaderaMuerta = { Kind = "Caja", Name = "Un montón de madera muerta", Prompt = "Darle madera muerta", Place = "Umbria_VainaNiaDentro", Offset = V(2, 0, 0), Dialogue = "Madera", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "PodadoraLiquen", Dialogue = "Oficio", Text = "Habla con la podadora junto al Tronco Mayor", Actors = { at("PodadoraLiquen", "Umbria_Ayuntamiento", 2, 4) } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "UmbriaPodador" }, Place = "Umbria_Ayuntamiento",
				Text = "Cura un árbol como 🪓 podador/a (tablón «Trabajar» junto al Tronco Mayor)", Actors = { at("PodadoraLiquen", "Umbria_Ayuntamiento", 2, 4) } },
			{ Type = "Talk", Npc = "NiaVaina", Dialogue = "Nia", Text = "Una niña te hace señas desde su vaina, en el Vivero", Actors = { at("NiaVaina", "Umbria_VainaNia", 0, 2) } },
			{ Type = "Use", Prop = "MaderaMuerta", Text = "Entra en la vaina y dale madera muerta a lo que zumba", Actors = { at("NiaVaina", "Umbria_VainaNiaDentro", -2, 1), at("Dron7", "Umbria_VainaNiaDentro", 3, -1) } },
			{ Type = "Choice", Key = "UmbriaDron", Text = "Es una máquina del Enjambre. Pequeña, estropeada… y no ataca. Nía te pide que no se lo digas a nadie. ¿Qué haces?",
				Options = {
					{ Id = "Secreto", Text = "Guardar el secreto de Nía", Effects = { Flags = { "Dron7Secreto" }, Rel = { NiaVaina = 15 }, Traits = { Empatia = 1 } } },
					{ Id = "Garza", Text = "Contárselo a Garza: él sabrá qué es", Effects = { Flags = { "Dron7Garza" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("NiaVaina", "Umbria_VainaNiaDentro", -2, 1), at("Dron7", "Umbria_VainaNiaDentro", 3, -1) } },
			{ Type = "Scene", Dialogue = "Dron", Actors = { at("NiaVaina", "Umbria_VainaNiaDentro", -2, 1), at("Dron7", "Umbria_VainaNiaDentro", 3, -1) } },
		},
		Dialogues = {
			Oficio = { Lines = {
				{ S = "PodadoraLiquen", T = "¿Manos nuevas? Bien. Las máquinas muerden y el árbol sangra savia. Si no se tapa, se seca.", To = "Yo", Shot = "Medio:PodadoraLiquen" },
				{ S = "PodadoraLiquen", T = "Se corta lo muerto, nunca lo vivo. Se coge savia del cubo y se unta despacio. Coge un turno del tablón.", G = "Point" },
			} },
			Nia = { Lines = {
				{ S = "NiaVaina", T = "¡Psst! ¿Tú eres el que pegó a las máquinas? ¿Me prometes no pegarle a una que es buena?", To = "Yo", Shot = "Medio:NiaVaina" },
				{ S = "NiaVaina", T = "Se llama Dron 7. Bueno, yo la llamo así. Tiene hambre. Pero no se come las casas. Solo lo muerto.", A = "Shrug" },
				{ S = "NiaVaina", T = "Pasa. Despacio. Se asusta.", G = "Point" },
			} },
			Madera = { Lines = {
				{ S = "Narrador", T = "Una máquina del tamaño de un perro, con una pata torcida, mastica la madera muerta con cuidado." },
				{ S = "Dron7", T = "…Gra… cias.", Pause = 0.8 },
				{ S = "NiaVaina", T = "¡Ha hablado! ¡Nunca había hablado!", A = "Surprised" },
			} },
			Dron = { Lines = {
				{ S = "NiaVaina", T = "Gracias, gracias, gracias. Te prometo que la cuido. Que no muerde. Casi nada.", If = { Choices = { UmbriaDron = "Secreto" } }, A = "Laugh" },
				{ S = "NiaVaina", T = "Vale. Pero Garza tiene que prometer que no le hace daño. Prométemelo tú.", If = { Choices = { UmbriaDron = "Garza" } }, A = "Sad" },
				{ S = "Dron7", T = "Llaman. Las otras. Desde el Claro. La… Reina.", Shot = "PrimerPlano:Dron7" },
				{ S = "NiaVaina", T = "¿El Claro Muerto? Ahí hay una antena de los forasteros. La de la luz roja.", To = "Yo", Beat = "Piensa" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 4 · La baliza del Claro
	---------------------------------------------------------------------
	{
		Id = "Umbria_04_Baliza",
		Kind = "Side",
		Canon = true,
		Title = "La baliza del Claro",
		Description = "En el Claro Muerto, donde el Enjambre ya no dejó ni un árbol, hay una baliza de la Compañía Torca. Garza quiere leerla. Las máquinas la vigilan.",
		Type = TIPO .. " (4/5)",
		Duration = { 7, 9 },
		Npcs = { "Garza", "DronEnjambre1", "DronEnjambre2" },
		Offer = { Place = "Umbria_PuertaSur" },
		OfferKey = "Garza espera en la Puerta Sur mirando hacia el Claro Muerto",
		Requires = after("Umbria_03_Savia"),
		Moment = "Leíste la baliza de Torca y Garza te contó lo que callaba",
		Memory = "BalizaTorca",
		Rewards = { Money = 110, Items = { ChatarraEnjambre = 2, SedaLiana = 2 } },
		Props = {
			Baliza = { Kind = "Marcador", Name = "La baliza de la Compañía Torca", Prompt = "Abrir la baliza", Place = "Umbria_ClaroMuerto", Offset = V(4, 0, 0), Dialogue = "Baliza", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Garza", Dialogue = "Claro", Text = "Habla con Garza en la Puerta Sur", Actors = { at("Garza", "Umbria_PuertaSur", 3, 0) } },
			{ Type = "Escape", Place = "Umbria_ClaroMuerto", Respawn = "Umbria_PuertaSur", Catch = 4,
				Text = "Cruza el bosque hasta el Claro Muerto sin que te alcancen las máquinas que patrullan",
				CaughtLine = "(Una máquina te derriba entre los helechos. Garza la aparta y volvéis a la puerta.)",
				Actors = {
					GARZA_SIGUE,
					{ Npc = "DronEnjambre1", Place = "Umbria_ClaroMuerto", Offset = V(-40, 0, 30), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Use", Prop = "Baliza", Text = "Abre la baliza de la Compañía Torca", Actors = { at("Garza", "Umbria_ClaroMuerto", -3, 2) } },
			{ Type = "Fight", Place = "Umbria_ClaroMuerto", Respawn = "Umbria_ClaroMuerto", Action = "Golpear 💥", HP = 4,
				Text = "¡La baliza las llama! Defiéndela mientras Garza la lee ({count}/{total})",
				CaughtLine = "(Te tiran contra un tocón. Garza grita: «¡Un minuto más!».)",
				Actors = { at("Garza", "Umbria_ClaroMuerto", -3, 2, "Point") },
				Enemies = {
					{ Npc = "DronEnjambre1", Offset = V(-16, 0, -10), Speed = 9.5, HP = 2, Bye = "*bzzzt… chispas*" },
					{ Npc = "DronEnjambre2", Offset = V(14, 0, -12), Speed = 10, HP = 2, Bye = "*clic… chispas*" },
				} },
			{ Type = "Scene", Dialogue = "Confesion", Actors = { at("Garza", "Umbria_ClaroMuerto", -3, 2) } },
			{ Type = "Escape", Place = "Umbria_Raices", Respawn = "Umbria_ClaroMuerto", Catch = 4,
				Text = "¡Viene un enjambre entero! Corre con Garza de vuelta a la Plaza de las Raíces",
				CaughtLine = "(El zumbido te rodea. Garza tira de ti hacia otro sendero.)",
				Actors = {
					GARZA_SIGUE,
					{ Npc = "DronEnjambre2", Place = "Umbria_ClaroMuerto", Offset = V(20, 0, 20), Mode = "Hunt", Speed = 10.5, Prompt = false },
				} },
		},
		Dialogues = {
			Claro = { Lines = {
				{ S = "Garza", T = "Nía dice que las máquinas «llaman» desde el Claro. Hay una baliza. Si la leemos, sabremos quién las manda.", To = "Yo" },
				{ S = "Garza", T = "Ve por los helechos. Las máquinas ven el calor, no la sombra.", G = "Point" },
			} },
			Baliza = { Lines = {
				{ S = "Narrador", T = "En la placa: «Compañía Torca. Proyecto Poda. Unidad de control 3». Y debajo, una firma: «V.»" },
				{ S = "Garza", T = "…Vesna.", Pause = 1, Shot = "PrimerPlano:Garza" },
			} },
			Confesion = { Lines = {
				{ S = "Garza", T = "Ya está. La baliza le da órdenes a la Reina del Enjambre. Y la Reina, a todas las demás.", To = "Yo" },
				{ S = "Garza", T = "Tengo que contarte algo. Yo ya había visto estas máquinas. En otro planeta. Hace años.", Shot = "Medio:Garza", A = "Sad" },
				{ S = "Garza", T = "Trabajaba para Torca. Con Vesna. Vi lo que hacían y miré hacia otro lado. Me pagaban bien.", Pause = 0.8 },
				{ S = "Garza", T = "No te lo conté porque me daba vergüenza. Ahora ya lo sabes. Y ahora, corre.", Beat = "Mira" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 5 · Viejos socios
	---------------------------------------------------------------------
	{
		Id = "Umbria_05_Socios",
		Kind = "Side",
		Canon = true,
		Title = "Viejos socios",
		Description = "La baliza que abriste en el Claro tenía un canal abierto. Esta noche, en la Plaza de las Raíces, una voz conocida llama a Garza por su nombre.",
		Type = TIPO .. " (5/5)",
		Duration = { 5, 7 },
		Npcs = { "Garza", "VesnaTorca" },
		Offer = { Place = "Umbria_Raices" },
		OfferKey = "La pieza de la baliza que trajo Garza se enciende sola en la plaza",
		Requires = after("Umbria_04_Baliza"),
		Moment = "Vesna le ofreció a Garza la mitad del negocio si se iba",
		Memory = "ViejosSocios",
		Rewards = { Money = 140, Items = { MascarillaSeda = 1 }, Flags = { "UmbriaReinaViene" } },
		Steps = {
			{ Type = "Cinematic", Id = "Umbria_Vesna", Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
			{ Type = "Talk", Npc = "Garza", Dialogue = "Duda", Text = "Garza se ha quedado callado mirando el Árbol Madre", Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
			{ Type = "Choice", Key = "UmbriaConsejo", Text = "«La mitad del negocio si me voy esta noche.» Garza te pregunta qué harías tú. ¿Qué le dices?",
				Options = {
					{ Id = "Quedate", Text = "«Quédate. Tu madre vive aquí.»", Effects = { Flags = { "GarzaQuedate" }, Rel = { Garza = 15 }, Traits = { Empatia = 1 } } },
					{ Id = "Vete", Text = "«Vete. Nadie te va a perdonar lo de Torca.»", Effects = { Flags = { "GarzaVete" }, Traits = { Valentia = 1 } } },
					{ Id = "Libre", Text = "«Haz lo que quieras. Es tu vida.»", Effects = { Flags = { "GarzaLibre" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
			{ Type = "Talk", Npc = "Garza", Dialogue = "Decision", Text = "Escucha lo que decide Garza", Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
		},
		Dialogues = {
			Duda = { Lines = {
				{ S = "Garza", T = "La mitad del negocio. Con eso compras una luna. Y no vuelves a oír un zumbido en tu vida.", To = "Yo", Shot = "Medio:Garza" },
				{ S = "Garza", T = "Ella sabe que lo pienso. Vesna siempre supo lo que yo pensaba antes que yo.", A = "Sad" },
			} },
			Decision = { Lines = {
				{ S = "Garza", T = "Mi madre. Enea. Vive en una vaina de las Ramas Altas y no me ha abierto la puerta en veinte años.", If = { Choices = { UmbriaConsejo = "Quedate" } }, To = "Yo" },
				{ S = "Garza", T = "Tienes razón. Nadie me lo va a perdonar. Por eso no me voy: no quiero que me perdonen, quiero arreglarlo.", If = { Choices = { UmbriaConsejo = "Vete" } }, To = "Yo", A = "ArmsCrossed" },
				{ S = "Garza", T = "Mi vida. Vaya. Hacía tiempo que nadie me la devolvía.", If = { Choices = { UmbriaConsejo = "Libre" } }, To = "Yo", A = "Shrug" },
				{ S = "Garza", T = "Me quedo. Vesna ha cometido un error: me ha recordado de qué lado estaba antes de venderme.", Shot = "PrimerPlano:Garza" },
				{ S = "Narrador", T = "Muy lejos, debajo de la niebla, algo enorme y plateado empieza a moverse hacia Raíz Honda." },
				{ S = "Garza", T = "Toma: mascarilla de seda de liana. La buena. La vas a necesitar. La Reina viene.", To = "Yo", Beat = "Mira" },
			} },
		},
	},
}
