-- SAGA 2 «RAGNAROCK» · TEFRA · EPISODIO 1 «CENIZA EN BASTIÓN» (docs/planetas/diseno-mundos.md §3.1.16,
-- adaptado a lo que ya se puede jugar: docs/planetas/tefra-misiones.md). Misiones CANÓNICAS: su marca
-- dorada sale en Bastión Ceniza y empiezan solas al llegar al sitio. Solo en Tefra (Requires.Planet).
--
--   1 Tefra_01_Caida     «Caída sobre Bastión»   llegas, sirenas, refugio, el calor (tutorial) y la estatua
--   2 Tefra_02_Casa      «La casa de Cosme»      el Ovillo, la casa en ruinas, emboscada, Dalia, Brasa
--   3 Tefra_03_Lista     «La lista»              turno de fundidor como disfraz, el Muelle, las órdenes
--   4 Tefra_04_Pozos     «Los Pozos»             calor extremo, tres cargas, el Ingeniero Orsi
--   5 Tefra_05_OtroLado  «Al otro lado»          tierra de nadie: Tobi Renn («Tú también nos disparabas»)
--   6 Tefra_06_Lanza     «La Lanza»              primer disparo, asalto, núcleo y huida
--   7 Tefra_07_Tregua    «Alto el fuego»         escolta, la verdad de Dalia, silencio ante Nilda
--
-- Lo que cambia respecto al diseño (porque la luna Ovilla y la batalla orbital aún no existen): el vuelo
-- a Ovilla de la misión 5 es una cita en la tierra de nadie, y la batalla espacial contra la Lanza de la
-- misión 6 es un asalto a pie a su base. Las decisiones y sus consecuencias son las del diseño.
-- 13+: sin sangre; nadie muere en cámara (Orsi, si lo dejas, «no sale»; Ada murió hace dos años).

local V = Vector3.new

local TIPO = "Saga 2 · Tefra · «Ceniza en Bastión»"

local function after(id: string?, extra: { [string]: any }?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Tefra" }
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
local COSME_SIGUE = { Npc = "Cosme", Mode = "Follow" }
local DALIA_SIGUE = { Npc = "DaliaRenn", Mode = "Follow" }

return {
	---------------------------------------------------------------------
	-- 1 · Caída sobre Bastión
	---------------------------------------------------------------------
	{
		Id = "Tefra_01_Caida",
		Kind = "Side",
		Canon = true,
		Title = "Caída sobre Bastión",
		Description = "Has llegado a Tefra, el planeta donde nació Cosme. Nada más bajar de la nave, suenan las sirenas: Ovilla, la luna de enfrente, dispara sobre la ciudad.",
		Type = TIPO .. " (1/7)",
		Duration = { 12, 18 },
		Npcs = { "Cosme", "DoctoraFermina" },
		Offer = { Place = "Tefra_Plataforma" },
		OfferKey = "Bastión Ceniza. Nada más bajar de la nave, suenan las sirenas",
		Requires = after(nil),
		Moment = "Llegaste a Bastión Ceniza, la ciudad de Cosme",
		Memory = "LlegadaTefra",
		-- (el primer equipo contra el calor te lo da Fermina en el refugio: efecto de su frase)
		Rewards = { Money = 60, Flags = { "TefraLlegado" } },
		Steps = {
			{ Type = "Cinematic", Id = "Tefra_Llegada", Actors = { at("Cosme", "Tefra_Plataforma", 3, 2) } },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Llegada", Text = "Habla con Cosme en la plataforma", Actors = { at("Cosme", "Tefra_Plataforma", 3, 2) } },
			{ Type = "Reach", Place = "Tefra_RefugioDentro", Text = "¡Sirenas! Corre al refugio antibombas de los Pozos de Magma", Actors = { COSME_SIGUE } },
			{ Type = "Scene", Dialogue = "Refugio",
				Actors = { at("DoctoraFermina", "Tefra_RefugioDentro", 3, 1), at("Cosme", "Tefra_RefugioDentro", -2, 2), at("RefugiadoMayor", "Tefra_RefugioDentro", 5, -2) } },
			{ Type = "Event", Event = "HeatChanged", Match = { Phase = "Aviso" }, Place = "Tefra_PozoMagma",
				Text = "Lleva el botiquín de Fermina a los obreros del Pozo de Magma (mira tu medidor de 🌡 calor)" },
			{ Type = "Event", Event = "HeatChanged", Match = { Phase = "Normal" },
				Text = "¡Demasiado calor! Usa el 🧴 gel térmico de la mochila o métete en un refugio para enfriarte" },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Estatua", Text = "Cosme te espera en el Mirador de las Lunas, junto a la estatua",
				Actors = { at("Cosme", "Tefra_Estatua", 0, -3) } },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Cosme", T = "Treinta y ocho años, criatura. Me fui por un agujero en el cielo y vuelvo en nave. Qué vueltas da todo.", To = "Yo" },
				{ S = "Cosme", T = "Esa torre no estaba. Ni la muralla. Ni el humo.", Beat = "Mira", Shot = "PrimerPlano:Cosme" },
				{ S = "Cosme", T = "Esas sirenas… ¡Al refugio! Si en Tefra suena algo tres veces, se corre. Eso no ha cambiado.", A = "Surprised", Effects = { Scene = "Tefra_Sirenas" } },
			} },
			Refugio = { Lines = {
				{ S = "DoctoraFermina", T = "Dentro, dentro. Sentaos donde podáis. Soy Fermina, la médica del Campus.", Shot = "Medio:DoctoraFermina" },
				{ S = "RefugiadoMayor", T = "Forasteros. Con buena ropa. Ya veréis qué rápido se os quema.", To = "Yo" },
				{ S = "DoctoraFermina", T = "Escuchad: aquí lo que mata no son las bombas. Es el calor. Junto a la lava, sube rapidísimo.", To = "Yo" },
				{ S = "DoctoraFermina", T = "Mirad vuestro medidor. Si se pone rojo, a la sombra, a un refugio o un poco de gel térmico.", G = "Point" },
				{ S = "DoctoraFermina", T = "Tomad: un traje refrigerado y gel. No es mucho. Es lo que hay.", Effects = { Items = { TrajeRefrigerado2 = 1, GelTermico = 2 } } },
				{ S = "Cosme", T = "Fermina… ¿esto es la academia de la abuela Nilda? ¿El Campus?", To = "DoctoraFermina" },
				{ S = "DoctoraFermina", T = "Era. Ahora es un hospital. ¿Conocía usted a Nilda?", Beat = "Mira" },
				{ S = "Cosme", T = "…Un poco. Era mi abuela.", Pause = 0.8, A = "Sad" },
				{ S = "DoctoraFermina", T = "Pues hágame un favor y lleve este botiquín a los obreros del Pozo. Ya ha pasado el fuego.", To = "Yo" },
			} },
			Estatua = { Lines = {
				{ S = "Cosme", T = "Mírala. Con su bufanda de piedra. Siempre decía que el frío entra por el cuello.", Shot = "Medio:Cosme" },
				{ S = "Cosme", T = "Tefra era redonda, criatura. Las casas, las calles, hasta el pan. Lo de las esquinas es de la guerra.", To = "Yo" },
				{ S = "Cosme", T = "Mi casa estaba en el Ovillo. Mi hermana Ada se quedó aquí cuando yo… me caí a Valmar.", Beat = "Piensa" },
				{ S = "Cosme", T = "Quiero verla. La casa. Y a Ada, si sigue ahí. ¿Me acompañas?", To = "Yo", A = "Sad" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 2 · La casa de Cosme
	---------------------------------------------------------------------
	{
		Id = "Tefra_02_Casa",
		Kind = "Side",
		Canon = true,
		Title = "La casa de Cosme",
		Description = "Cosme quiere ver la casa de su familia en el Barrio del Ovillo, el casco viejo de cúpulas. Lo bombardearon hace años y la policía militar no deja pasar a nadie.",
		Type = TIPO .. " (2/7)",
		Duration = { 18, 25 },
		Npcs = { "Cosme", "DaliaRenn", "Brasa" },
		Offer = { Place = "Tefra_Estatua" },
		OfferKey = "Cosme mira hacia el Ovillo, al otro lado del Muelle",
		Requires = after("Tefra_01_Caida"),
		Moment = "Encontraste la casa de Cosme y conociste a Dalia Renn",
		Memory = "CasaDeCosme",
		Rewards = { Money = 80, Flags = { "TefraConoceDalia" } },
		Props = {
			Marco = { Kind = "Marcador", Name = "El marco de la puerta", Prompt = "Mirar las rayas", Place = "Tefra_CasaCosmePuerta", Offset = V(3, 0, 0), Dialogue = "Marco", Once = true },
			Mesa = { Kind = "Caja", Name = "La mesa de la cocina, quemada", Prompt = "Mirar", Place = "Tefra_CasaCosme", Offset = V(0, 0, 3), Dialogue = "Mesa", Once = true },
			Foto = { Kind = "Papel", Name = "Una foto bajo la ceniza", Prompt = "Coger la foto", Place = "Tefra_CasaCosme", Offset = V(-4, 0, -2), Dialogue = "Foto", Once = true },
		},
		Steps = {
			{ Type = "Escape", Place = "Tefra_RuinasOvillo", Respawn = "Tefra_Estatua", Catch = 4,
				Text = "Cruza hasta las cúpulas del Ovillo sin que te pare la policía militar",
				CaughtLine = "¡Alto! ¿Papeles? …¿No? Media vuelta, al Mirador. Y que no os vuelva a ver.",
				Actors = {
					COSME_SIGUE,
					{ Npc = "PoliciaMilitar1", Place = "Tefra_PuertaNorte", Offset = V(8, 0, 20), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "PoliciaMilitar2", Place = "Tefra_Panaderia", Offset = V(-10, 0, 6), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Group", Text = "Busca con Cosme lo que queda de su casa",
				Actors = { COSME_SIGUE },
				Steps = {
					{ Type = "Use", Prop = "Marco", Text = "El marco de la puerta" },
					{ Type = "Use", Prop = "Mesa", Text = "La mesa de la cocina" },
					{ Type = "Use", Prop = "Foto", Text = "Algo bajo la ceniza" },
				} },
			{ Type = "Scene", Dialogue = "Emboscada",
				Actors = { at("Cosme", "Tefra_CasaCosme", 0, 2), at("DaliaRenn", "Tefra_CasaCosmePuerta", -6, 4), at("PoliciaMilitar1", "Tefra_CasaCosmePuerta", -14, -6), at("PoliciaMilitar2", "Tefra_CasaCosmePuerta", -14, 6) } },
			{ Type = "Fight", Place = "Tefra_CasaCosmePuerta", Respawn = "Tefra_CasaCosme", Action = "Derribar 💥", HP = 4,
				Text = "¡Emboscada de la policía militar! Dalia te cubre: derriba a los dos ({count}/{total})",
				CaughtLine = "(Te tiran al suelo entre la ceniza. Dalia tira de ti hacia la cúpula.)",
				Actors = { at("DaliaRenn", "Tefra_CasaCosmePuerta", -4, 4, "Point"), at("Cosme", "Tefra_CasaCosme", 0, 2) },
				Enemies = {
					{ Npc = "PoliciaMilitar1", Offset = V(-14, 0, -6), Speed = 10, HP = 3, Bye = "¡Me rindo! ¡Que me rindo!" },
					{ Npc = "PoliciaMilitar2", Offset = V(-14, 0, 6), Speed = 11, HP = 3, Bye = "Esto no me lo pagan…" },
				} },
			{ Type = "Choice", Key = "TefraBrasa", Text = "Una niña os ha visto pelear y está escondida detrás de la cúpula. Vienen más policías. ¿Qué haces?",
				Options = {
					{ Id = "Ayudar", Text = "«Ven con nosotros.» Esconderla en el túnel", Effects = { Flags = { "BrasaAyudada" }, Rel = { Brasa = 15 }, Traits = { Empatia = 1 } } },
					{ Id = "Dejar", Text = "No hay tiempo: seguir sin ella", Effects = { Flags = { "BrasaSola" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("Brasa", "Tefra_CasaCosmePuerta", 6, -6), at("DaliaRenn", "Tefra_CasaCosmePuerta", -4, 4), at("Cosme", "Tefra_CasaCosme", 0, 2) } },
			{ Type = "Escape", Place = "Tefra_BloqueRefugio", Respawn = "Tefra_CasaCosmePuerta", Catch = 4,
				Text = "Huid por los túneles hasta el Bloque del Refugio 2, en el Mercado",
				CaughtLine = "¡Por aquí! …(Te cortan el paso. Dalia te saca por otra boca del túnel.)",
				Actors = {
					DALIA_SIGUE, COSME_SIGUE,
					{ Npc = "Brasa", Mode = "Follow", If = { Choices = { TefraBrasa = "Ayudar" } } },
					{ Npc = "PoliciaMilitar3", Place = "Tefra_RuinasOvillo", Offset = V(0, 0, 10), Mode = "Hunt", Speed = 11, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Dalia",
				Actors = { at("DaliaRenn", "Tefra_BloqueRefugio", 0, -4), at("Cosme", "Tefra_BloqueRefugio", 3, -2),
					{ Npc = "Brasa", Place = "Tefra_BloqueRefugio", Offset = V(-3, 0, -2), If = { Choices = { TefraBrasa = "Ayudar" } } } } },
		},
		Dialogues = {
			Marco = { Lines = {
				{ S = "Narrador", T = "En el marco de la puerta, rayas de lápiz con alturas. «Cosme, 8 años». «Ada, 6 años». Más arriba, solo «Ada»." },
				{ S = "Cosme", T = "Ella siguió midiéndose. Sola. Año tras año.", Shot = "PrimerPlano:Cosme", A = "Sad" },
			} },
			Mesa = { Lines = {
				{ S = "Cosme", T = "Aquí hacíamos los deberes. La abuela nos corregía con harina en las manos.", Beat = "Piensa" },
				{ S = "Cosme", T = "Ahora es carbón. Bueno. El carbón también es una forma de quedarse.", A = "Shrug" },
			} },
			Foto = { Lines = {
				{ S = "Narrador", T = "Una foto medio quemada: una mujer joven con una bufanda de lana, riéndose delante del horno del barrio." },
				{ S = "Cosme", T = "Es Ada. Mayor. Mucho mayor de lo que yo la recuerdo.", Shot = "PrimerPlano:Cosme" },
				{ S = "Cosme", T = "Lleva la bufanda de la abuela. Siempre se la quitaba. Siempre.", Pause = 0.8, A = "Sad" },
			} },
			Emboscada = { Lines = {
				{ S = "PoliciaMilitar1", T = "¡Quietos! Zona militar. Las manos donde las vea.", Shot = "DosPlanos:PoliciaMilitar1,PoliciaMilitar2", A = "Angry" },
				{ S = "Cosme", T = "¿Zona militar? ¡Es mi casa! ¡Hay rayas de lápiz con mi nombre!", A = "Angry" },
				{ S = "DaliaRenn", T = "Agachaos. Ahora.", Shot = "Medio:DaliaRenn" },
				{ S = "DaliaRenn", T = "Yo me encargo del de la izquierda. Tú, del otro. Sin héroes.", To = "Yo" },
			} },
			Dalia = { Lines = {
				{ S = "DaliaRenn", T = "Dalia Renn. Sargento. Bueno, era sargento. Ahora soy una desertora con mala suerte.", Shot = "Medio:DaliaRenn" },
				{ S = "DaliaRenn", T = "Los del Ovillo nos escondemos en los bloques. Aquí la policía militar no entra sin avisar.", To = "Yo" },
				{ S = "Brasa", T = "¡Gracias por esconderme! Me llamo Brasa. Hago recados. Si necesitáis algo, os lo consigo. Caro.", If = { Choices = { TefraBrasa = "Ayudar" } } },
				{ S = "DaliaRenn", T = "Esa cría os ha visto. Si habla, mañana tenemos a medio Muelle aquí.", If = { Choices = { TefraBrasa = "Dejar" } }, A = "ArmsCrossed" },
				{ S = "Cosme", T = "Sargento… ¿conoce a una mujer que se llama Ada? Del Ovillo. Con bufanda.", To = "DaliaRenn" },
				{ S = "DaliaRenn", T = "…Aquí todo el mundo lleva bufanda, abuelo. Preguntaré.", Beat = "Aparta" },
				{ S = "DaliaRenn", T = "Ahora escuchad. Corvo está preparando algo en el Muelle. Algo gordo. Y necesito unas manos nuevas.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 3 · La lista
	---------------------------------------------------------------------
	{
		Id = "Tefra_03_Lista",
		Kind = "Side",
		Canon = true,
		Title = "La lista",
		Description = "Dalia sospecha que el General Corvo prepara un arma en el Muelle. Para entrar a mirar sus órdenes hace falta un disfraz: el mono de los obreros de las Fundiciones.",
		Type = TIPO .. " (3/7)",
		Duration = { 18, 25 },
		Npcs = { "DaliaRenn", "Cosme" },
		Offer = { Place = "Tefra_BloqueRefugio" },
		OfferKey = "Dalia extiende un plano del Muelle sobre una caja",
		Requires = after("Tefra_02_Casa"),
		Moment = "Robaste las órdenes de Corvo: el «Proyecto Lanza»",
		Memory = "LaListaDeCorvo",
		Rewards = { Money = 100, Items = { OrdenesCorvo = 1 } },
		Props = {
			Ordenes = { Kind = "Papel", Name = "Las órdenes del General Corvo", Prompt = "Leer las órdenes", Place = "Tefra_DespachoCorvo", Offset = V(0, 0, 1), Dialogue = "Ordenes", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "DaliaRenn", Dialogue = "Plan", Text = "Escucha el plan de Dalia", Actors = { at("DaliaRenn", "Tefra_BloqueRefugio", 0, -4), at("Cosme", "Tefra_BloqueRefugio", 3, -2) } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "TefraFundidor" }, Place = "Tefra_OficinaTrabajo",
				Text = "Trabaja un turno de 🔥 fundidor/a (tablón de la Oficina de trabajo, en las Fundiciones): así te dan el mono de obrero" },
			{ Type = "Talk", Npc = "DaliaRenn", Dialogue = "Disfraz", Text = "Dalia te espera junto al astillero del Muelle", Actors = { at("DaliaRenn", "Tefra_Astillero", -6, -2) } },
			{ Type = "Escape", Place = "Tefra_DespachoCorvo", Respawn = "Tefra_Astillero", Catch = 4,
				Text = "Con el mono puesto, entra en la torre de control sin que te reconozcan",
				CaughtLine = "Tú no eres de mi turno. ¡Fuera del Muelle, obrero! (Vuelves al astillero.)",
				Actors = {
					{ Npc = "PoliciaMilitar1", Place = "Tefra_Calabozos", Offset = V(10, 0, 8), Mode = "Hunt", Speed = 9, Prompt = false },
					{ Npc = "PoliciaMilitar2", Place = "Tefra_Armeria", Offset = V(-6, 0, 12), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Use", Prop = "Ordenes", Text = "Busca las órdenes en la mesa del despacho de Corvo" },
			{ Type = "Choice", Key = "TefraPapelesDesertores", Text = "Debajo de las órdenes hay otra carpeta: «Desertores del Ovillo». Nombres, caras y escondites. ¿Te la llevas también?",
				Options = {
					{ Id = "Todo", Text = "Llevármelo todo (Dalia confiará más en ti… y Corvo pondrá precio a tu cabeza)", Effects = { Flags = { "PapelesDesertores", "PrecioCabeza" }, Rel = { DaliaRenn = 20 }, Traits = { Valentia = 1 } } },
					{ Id = "Ordenes", Text = "Solo las órdenes: que no noten nada más", Effects = { Flags = { "SoloOrdenes" }, Traits = { Responsabilidad = 1 } } },
				} },
			{ Type = "Escape", Place = "Tefra_Terraza", Respawn = "Tefra_TorreControl", Catch = 4,
				Text = "¡Salta la alarma! Escapa del Muelle y sube a la terraza del Mirador",
				CaughtLine = "¡Te tengo! …(Te zafas de la bufanda y vuelves a correr desde la torre.)",
				Actors = {
					{ Npc = "PoliciaMilitar1", Place = "Tefra_TorreControl", Offset = V(-12, 0, 6), Mode = "Hunt", Speed = 11, Prompt = false },
					{ Npc = "PoliciaMilitar2", Place = "Tefra_TorreControl", Offset = V(-12, 0, -6), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "PoliciaMilitar3", Place = "Tefra_Estatua", Offset = V(-20, 0, 0), Mode = "Hunt", Speed = 12, Prompt = false, If = { Flags = { "PrecioCabeza" } } },
				} },
			{ Type = "Scene", Dialogue = "Lanza", Actors = { at("DaliaRenn", "Tefra_Terraza", -2, 3), at("Cosme", "Tefra_Terraza", 2, 3) } },
		},
		Dialogues = {
			Plan = { Lines = {
				{ S = "DaliaRenn", T = "Al Muelle solo entran los militares y los obreros de las Fundiciones. Uniforme o mono.", To = "Yo" },
				{ S = "DaliaRenn", T = "Uniformes no tenemos. Monos sí: te lo dan al acabar tu primer turno en la Fundición.", G = "Point" },
				{ S = "Cosme", T = "¿Trabajar? ¿En una fundición? ¿Con este calor? Yo vigilo desde aquí. Por la ciencia.", A = "Shrug" },
				{ S = "DaliaRenn", T = "Un turno. Una colada. Y luego nos vemos en el astillero. En marcha.", To = "Yo" },
			} },
			Disfraz = { Lines = {
				{ S = "DaliaRenn", T = "Hueles a horno. Perfecto. Nadie mira a un obrero que huele a horno.", Shot = "Medio:DaliaRenn" },
				{ S = "DaliaRenn", T = "El despacho de Corvo está en la planta baja de la torre de control. Entra, coge papeles, sal.", To = "Yo" },
				{ S = "DaliaRenn", T = "Y si te paran, di que vienes a por el turno de noche. Nadie quiere el turno de noche.", Beat = "Sonrie" },
			} },
			Ordenes = { Lines = {
				{ S = "Narrador", T = "«PROYECTO LANZA. Alto secreto. La central de los Pozos alimentará la lente.»" },
				{ S = "Narrador", T = "«Primera descarga: sobre Ovilla. Daños previstos en la corteza del Este: aceptables.»" },
				{ S = "Narrador", T = "Al margen, con la letra pequeña y recta de Corvo: «Lo aceptable lo decido yo»." },
			} },
			Lanza = { Lines = {
				{ S = "DaliaRenn", T = "¿Qué has encontrado? Enséñamelo.", To = "Yo" },
				{ S = "DaliaRenn", T = "…La Lanza. Esa torre de los Pozos no es una antena. Es un cañón.", Shot = "PrimerPlano:DaliaRenn", A = "Angry" },
				{ S = "Cosme", T = "«Daños en la corteza del Este». Criatura, esto no rompe una ciudad. Rompe un planeta.", To = "Yo", A = "Surprised" },
				{ S = "DaliaRenn", T = "Y te has traído la carpeta de los desertores. Mis nombres. Gracias. De verdad.", If = { Choices = { TefraPapelesDesertores = "Todo" } }, A = "Sad" },
				{ S = "DaliaRenn", T = "Mañana Corvo sabrá que alguien la tiene. Va a poner tu cara en todas las puertas.", If = { Choices = { TefraPapelesDesertores = "Todo" } } },
				{ S = "DaliaRenn", T = "Hay que parar la central. Antes de que la Lanza esté lista. Hay que bajar a los Pozos.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 4 · Los Pozos
	---------------------------------------------------------------------
	{
		Id = "Tefra_04_Pozos",
		Kind = "Side",
		Canon = true,
		Title = "Los Pozos",
		Description = "La central de los Pozos de Magma alimenta la Lanza. Dalia quiere poner cargas en sus tres conductos de vapor. Ahí abajo el calor no perdona.",
		Type = TIPO .. " (4/7)",
		Duration = { 15, 22 },
		Npcs = { "DaliaRenn", "IngenieroOrsi" },
		Offer = { Place = "Tefra_Central" },
		OfferKey = "Dalia te espera a la puerta de la central, con una mochila que pesa demasiado",
		Requires = after("Tefra_03_Lista"),
		Moment = "Pusiste las cargas en los Pozos de Magma",
		Memory = "LosPozos",
		Rewards = { Money = 120, Items = { AzufreNegro = 2, GelTermico = 1 } },
		Props = {
			Conducto1 = { Kind = "Maquina", Name = "Conducto de vapor oeste", Prompt = "Poner la carga", Place = "Tefra_Conducto1", Dialogue = "Carga1", Once = true, Effects = { Scene = "Tefra_Sirenas" } },
			Conducto2 = { Kind = "Maquina", Name = "Conducto de vapor central", Prompt = "Poner la carga", Place = "Tefra_Conducto2", Dialogue = "Carga2", Once = true },
			Conducto3 = { Kind = "Maquina", Name = "Conducto de vapor este", Prompt = "Poner la carga", Place = "Tefra_Conducto3", Dialogue = "Carga3", Once = true, Effects = { Scene = "Tefra_Sirenas" } },
		},
		Steps = {
			{ Type = "Talk", Npc = "DaliaRenn", Dialogue = "Cargas", Text = "Habla con Dalia a la puerta de la central", Actors = { at("DaliaRenn", "Tefra_Central", -3, -4) } },
			{ Type = "Reach", Place = "Tefra_PozoMagma", Text = "Baja hasta el Pozo de Magma (cuidado con el 🌡 calor: usa gel si hace falta)", Actors = { DALIA_SIGUE } },
			{ Type = "Group", Text = "Pon las cargas en los tres conductos de vapor (en el orden que quieras), bajo el fuego de Ovilla",
				Actors = { DALIA_SIGUE },
				Steps = {
					{ Type = "Use", Prop = "Conducto1", Text = "El conducto oeste" },
					{ Type = "Use", Prop = "Conducto2", Text = "El conducto central" },
					{ Type = "Use", Prop = "Conducto3", Text = "El conducto este" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Temporizador de las cargas", Icon = "⏱", Hint = "Sincroniza las tres cargas: pulsa cuando la aguja pase por el verde",
				Rounds = 3, Need = 2, Zone = 0.26, Speed = 1,
				Win = { Flags = { "CargasSincronizadas" } }, Lose = { Flags = { "CargasTorpes" } },
				Actors = { at("DaliaRenn", "Tefra_PozoMagma", -4, 4) } },
			{ Type = "Talk", Npc = "IngenieroOrsi", Dialogue = "Orsi", Text = "Alguien os ha visto: un hombre con gafas sucias junto a la Lanza",
				Actors = { at("IngenieroOrsi", "Tefra_Lanza", 0, -4), at("DaliaRenn", "Tefra_PozoMagma", -4, 4) } },
			{ Type = "Choice", Key = "TefraOrsi", Text = "Orsi os ofrece su fallo secreto de la Lanza si le sacáis vivo de aquí. Corvo no perdona a los traidores. ¿Qué haces?",
				Options = {
					{ Id = "Sacar", Text = "Sacarle: irá despacio, pero sabotea la Lanza desde dentro", Effects = { Flags = { "OrsiVive" }, Rel = { IngenieroOrsi = 20 }, Traits = { Empatia = 1 } } },
					{ Id = "Dejar", Text = "Dejarle: no hay tiempo, y quizá es una trampa", Effects = { Flags = { "OrsiSeQueda" }, Traits = { Valentia = 1 } } },
				},
				Actors = { at("IngenieroOrsi", "Tefra_Lanza", 0, -4), at("DaliaRenn", "Tefra_PozoMagma", -4, 4) } },
			{ Type = "Escape", Place = "Tefra_HospitalDentro", Respawn = "Tefra_PozoMagma", Catch = 4, If = { Choices = { TefraOrsi = "Sacar" } },
				Text = "Escolta a Orsi hasta el Campus Nilda: va despacio y la policía militar le busca",
				CaughtLine = "¡Ahí está el ingeniero! (Os cortan el paso. Volvéis al Pozo a probar otra calle.)",
				Actors = {
					{ Npc = "IngenieroOrsi", Mode = "Follow" }, DALIA_SIGUE,
					{ Npc = "PoliciaMilitar1", Place = "Tefra_Central", Offset = V(-10, 0, 0), Mode = "Hunt", Speed = 9, Prompt = false },
					{ Npc = "PoliciaMilitar2", Place = "Tefra_Raciones", Offset = V(0, 0, -8), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Escape", Place = "Tefra_RefugioDentro", Respawn = "Tefra_PozoMagma", Catch = 4, If = { Choices = { TefraOrsi = "Dejar" } },
				Text = "Sal de los Pozos antes de que lleguen los guardias: corre al refugio",
				CaughtLine = "¡Alto! (Te escabulles entre el vapor y vuelves al Pozo.)",
				Actors = {
					DALIA_SIGUE,
					{ Npc = "PoliciaMilitar1", Place = "Tefra_Central", Offset = V(-10, 0, 0), Mode = "Hunt", Speed = 11, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Hospital", If = { Choices = { TefraOrsi = "Sacar" } },
				Actors = { at("IngenieroOrsi", "Tefra_HospitalDentro", 4, 1), at("DaliaRenn", "Tefra_HospitalDentro", -2, 2), at("DoctoraFermina", "Tefra_HospitalDentro", 0, 5) } },
			{ Type = "Scene", Dialogue = "Refugio", If = { Choices = { TefraOrsi = "Dejar" } },
				Actors = { at("DaliaRenn", "Tefra_RefugioDentro", -2, 2) } },
		},
		Dialogues = {
			Cargas = { Lines = {
				{ S = "DaliaRenn", T = "Tres cargas, tres conductos. Si caen los conductos, la central no puede alimentar la lente.", To = "Yo" },
				{ S = "DaliaRenn", T = "Abajo hace un calor que no te imaginas. Si el medidor se pone rojo, sales. Sin héroes.", G = "Point" },
				{ S = "DaliaRenn", T = "Y hoy Ovilla dispara sobre los Pozos. Mejor. Nadie mira a quien corre cuando caen bombas.", Beat = "Respira" },
			} },
			Carga1 = { Lines = { { S = "Narrador", T = "Atas la carga al conducto. Quema a través de los guantes. Un proyectil cae sobre la Muralla." } } },
			Carga2 = { Lines = { { S = "Narrador", T = "El conducto central vibra como un animal dormido. La carga encaja con un clic." } } },
			Carga3 = { Lines = { { S = "Narrador", T = "El último. El suelo tiembla: otra bomba, más cerca. Dalia te hace un gesto: ¡vamos!" } } },
			Orsi = { Lines = {
				{ S = "IngenieroOrsi", T = "¡No, no, no! ¡Esas cargas no! ¡Si reventáis los conductos, el pozo se desborda!", A = "Nervous", Shot = "Medio:IngenieroOrsi" },
				{ S = "IngenieroOrsi", T = "Soy Orsi. Yo construí la Lanza. Y sí, ya sé lo que hace. Por eso le puse un fallo.", Beat = "Baja" },
				{ S = "IngenieroOrsi", T = "Un fallo secreto en el núcleo. Si alguien lo toca en el momento justo, la Lanza se apaga.", To = "Yo" },
				{ S = "IngenieroOrsi", T = "Nunca me he atrevido. Corvo me mira cada mañana como si ya lo supiera.", A = "Sad" },
				{ S = "IngenieroOrsi", T = "Sacadme de aquí y os lo cuento todo. Por favor.", To = "Yo" },
				{ S = "DaliaRenn", T = "Puede ser una trampa. Puede ser la única oportunidad. Tú decides, forastero.", To = "Yo", If = { Flags = { "TefraConoceDalia" } } },
			} },
			Hospital = { Lines = {
				{ S = "DoctoraFermina", T = "Otro más. Camilla cuatro. Aquí no se pregunta de qué bando eres.", Shot = "Medio:DoctoraFermina" },
				{ S = "IngenieroOrsi", T = "Gracias. Mañana entro en la central como siempre. Y cuando Corvo dispare… estaré en el núcleo.", To = "Yo" },
				{ S = "IngenieroOrsi", T = "No podré evitar el primer disparo. El segundo, sí. O eso espero.", A = "Nervous" },
				{ S = "DaliaRenn", T = "Fermina… gracias por acogerle.", To = "DoctoraFermina" },
				{ S = "DoctoraFermina", T = "No me des las gracias, Dalia. Tú no.", Beat = "Aparta" },
				{ S = "Narrador", T = "Dalia baja la mirada. No dice nada más." },
			} },
			Refugio = { Lines = {
				{ S = "DaliaRenn", T = "Hemos salido. Él no.", Shot = "PrimerPlano:DaliaRenn", Pause = 0.8 },
				{ S = "DaliaRenn", T = "Le he visto entrar en la central con dos guardias. No ha vuelto a salir.", A = "Sad" },
				{ S = "DaliaRenn", T = "No digas nada. Ya lo sé. Era lo que había que hacer. O no. Ya no lo sé.", To = "Yo", Beat = "Aparta" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 5 · Al otro lado
	---------------------------------------------------------------------
	{
		Id = "Tefra_05_OtroLado",
		Kind = "Side",
		Canon = true,
		Title = "Al otro lado",
		Description = "Dalia ha conseguido una cita con su hermano Tobi, capitán de la Milicia de Ovilla, en la tierra de nadie, al otro lado de la Puerta Este. Bajo bandera blanca. Más o menos.",
		Type = TIPO .. " (5/7)",
		Duration = { 12, 18 },
		Npcs = { "DaliaRenn", "TobiRenn" },
		Offer = { Place = "Tefra_PuertaEste" },
		OfferKey = "Dalia ata un trapo blanco a un palo junto a la Puerta Este",
		Requires = after("Tefra_04_Pozos"),
		Moment = "Te viste cara a cara con Tobi Renn, el hermano de Dalia",
		Memory = "AlOtroLado",
		Rewards = { Money = 100, Items = { CuarzoMalva = 2 } },
		Steps = {
			{ Type = "Talk", Npc = "DaliaRenn", Dialogue = "Bandera", Text = "Habla con Dalia en la Puerta Este", Actors = { at("DaliaRenn", "Tefra_PuertaEste", -4, 2) } },
			{ Type = "Escape", Place = "Tefra_TierraDeNadie", Respawn = "Tefra_PuertaEste", Catch = 4,
				Text = "Cruza la tierra de nadie hasta las trincheras (cuidado: no todos los de Ovilla saben que hay tregua)",
				CaughtLine = "¡Alto ahí, de Bastión! (Os hacen volver a la Puerta con las manos en alto.)",
				Actors = {
					DALIA_SIGUE,
					{ Npc = "SoldadoOvilla", Place = "Tefra_TierraDeNadie", Offset = V(-30, 0, 20), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Tobi", Actors = { at("TobiRenn", "Tefra_TierraDeNadie", 0, -6), at("DaliaRenn", "Tefra_TierraDeNadie", -3, 2) } },
			{ Type = "Choice", Key = "TefraTobiLanza", Text = "Tobi no sabe nada de la Lanza. Si se lo cuentas, Ovilla evacuará sus ciudades… y Corvo sabrá que alguien habló. ¿Se lo cuentas?",
				Options = {
					{ Id = "Contar", Text = "Contárselo todo y darle una copia de las órdenes", Effects = { Flags = { "TobiSabeLanza" }, Rel = { TobiRenn = 15 }, Traits = { Valentia = 1 } } },
					{ Id = "Callar", Text = "Callar: no puedes fiarte del capitán enemigo", Effects = { Flags = { "TobiNoSabe" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("TobiRenn", "Tefra_TierraDeNadie", 0, -6), at("DaliaRenn", "Tefra_TierraDeNadie", -3, 2) } },
			{ Type = "Scene", Dialogue = "Despedida", Actors = { at("TobiRenn", "Tefra_TierraDeNadie", 0, -6), at("DaliaRenn", "Tefra_TierraDeNadie", -3, 2) } },
			{ Type = "Reach", Place = "Tefra_PuertaEste", Text = "Vuelve a Bastión por la Puerta Este", Actors = { DALIA_SIGUE } },
		},
		Dialogues = {
			Bandera = { Lines = {
				{ S = "DaliaRenn", T = "Mi hermano. Tobi. Capitán de la Milicia de Ovilla. Hace seis años que no le veo de cerca.", To = "Yo" },
				{ S = "DaliaRenn", T = "Ha aceptado vernos en la tierra de nadie. Si le contamos lo de la Lanza, quizá Ovilla se salve.", Beat = "Piensa" },
				{ S = "DaliaRenn", T = "O quizá me pegue un tiro. Con Tobi nunca se sabe. De pequeño mordía.", A = "Shrug" },
			} },
			Tobi = { Lines = {
				{ S = "TobiRenn", T = "Dalia.", Shot = "Medio:TobiRenn", Pause = 0.6 },
				{ S = "DaliaRenn", T = "Tobi. Estás más alto. O yo más vieja.", To = "TobiRenn" },
				{ S = "TobiRenn", T = "¿Has venido a pedirme que pare? ¿Tú? ¿Una sargento de Bastión?", A = "Angry" },
				{ S = "DaliaRenn", T = "Ya no soy sargento. Me fui. No quería disparar más.", Beat = "Baja" },
				{ S = "TobiRenn", T = "Tú también nos disparabas, Dalia.", Shot = "PrimerPlano:TobiRenn", Pause = 1.2 },
				{ S = "Narrador", T = "Nadie dice nada. Cae ceniza sobre la bandera blanca." },
				{ S = "TobiRenn", T = "Y yo pedí los bombardeos sobre el Muelle. Los dos tenemos las manos sucias.", A = "Sad", To = "DaliaRenn" },
				{ S = "TobiRenn", T = "¿Y tú quién eres? No tienes cara de soldado. Tienes cara de forastero que se ha perdido.", To = "Yo" },
			} },
			Despedida = { Lines = {
				{ S = "TobiRenn", T = "Si esto es verdad… evacuaremos las ciudades de la cara que mira a Tefra. Esta noche.", If = { Choices = { TefraTobiLanza = "Contar" } }, Shot = "Medio:TobiRenn" },
				{ S = "TobiRenn", T = "Gracias, forastero. Y a ti, Dalia. No te lo pienso decir dos veces.", If = { Choices = { TefraTobiLanza = "Contar" } }, To = "DaliaRenn" },
				{ S = "TobiRenn", T = "No me contáis nada. Lo noto. Pues yo tampoco. Así es la guerra, ¿no?", If = { Choices = { TefraTobiLanza = "Callar" } }, A = "Angry" },
				{ S = "TobiRenn", T = "Volved a vuestra muralla antes de que me arrepienta de la bandera.", If = { Choices = { TefraTobiLanza = "Callar" } } },
				{ S = "DaliaRenn", T = "Cuídate, enano.", To = "TobiRenn", Pause = 0.6 },
				{ S = "TobiRenn", T = "…Y tú, mandona.", Beat = "Aparta" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 6 · La Lanza
	---------------------------------------------------------------------
	{
		Id = "Tefra_06_Lanza",
		Kind = "Side",
		Canon = true,
		Title = "La Lanza",
		Description = "Corvo ha adelantado el disparo. La Lanza está cargada y apunta a Ovilla. Hay que llegar a su base y romper la lente antes del segundo disparo.",
		Type = TIPO .. " (6/7)",
		Duration = { 15, 22 },
		Npcs = { "DaliaRenn", "Cosme", "IngenieroOrsi" },
		Offer = { Place = "Tefra_Central" },
		OfferKey = "La Lanza zumba. La lente de arriba empieza a brillar",
		Requires = after("Tefra_05_OtroLado"),
		Moment = "Hiciste caer la Lanza antes del segundo disparo",
		Memory = "LaLanza",
		Rewards = { Money = 150, Items = { EscudoNaveTefra = 1, ObsidianaIgnea = 3 }, World = { ["Tefra.Lanza"] = "Caida" } },
		Props = {
			Escudos = { Kind = "Maquina", Name = "Generador de escudos de la Lanza", Prompt = "Arrancar los cables", Place = "Tefra_Lanza", Offset = V(-12, 0, -2), Dialogue = "Escudos", Once = true },
			Torretas = { Kind = "Maquina", Name = "Control de las torretas", Prompt = "Apagar las torretas", Place = "Tefra_Lanza", Offset = V(12, 0, -2), Dialogue = "Torretas", Once = true },
		},
		Steps = {
			{ Type = "Cinematic", Id = "Tefra_LanzaDispara", Actors = { at("DaliaRenn", "Tefra_Central", -4, 2), at("Cosme", "Tefra_Central", 4, 2) } },
			{ Type = "Talk", Npc = "DaliaRenn", Dialogue = "Ahora", Text = "Dalia está a la puerta de la central", Actors = { at("DaliaRenn", "Tefra_Central", -4, 2), at("Cosme", "Tefra_Central", 4, 2) } },
			{ Type = "Fight", Place = "Tefra_Lanza", Respawn = "Tefra_Central", Action = "Derribar 💥", HP = 5,
				Text = "Ábrete paso hasta la base de la Lanza ({count}/{total})",
				CaughtLine = "(Te derriban contra los andamios. Dalia te levanta: «Otra vez. Ahora».)",
				Actors = { at("DaliaRenn", "Tefra_Lanza", -6, 8, "Point") },
				Enemies = {
					{ Npc = "PoliciaMilitar1", Offset = V(-8, 0, -4), Speed = 11, HP = 3, Bye = "¡Que dispare otro!" },
					{ Npc = "PoliciaMilitar2", Offset = V(8, 0, -4), Speed = 11, HP = 3, Bye = "¡Me voy a casa!" },
					{ Npc = "PoliciaMilitar3", Offset = V(0, 0, -10), Speed = 12, HP = 4, Bye = "Esto no era una antena…" },
				} },
			{ Type = "Use", Prop = "Escudos", Text = "Fase 1: arranca los cables del generador de escudos", Actors = { at("DaliaRenn", "Tefra_Lanza", -6, 8) } },
			{ Type = "Use", Prop = "Torretas", Text = "Fase 2: apaga las torretas de la base", If = { NotChoices = { TefraOrsi = "Sacar" } }, Actors = { at("DaliaRenn", "Tefra_Lanza", -6, 8) } },
			{ Type = "Scene", Dialogue = "OrsiDentro", If = { Choices = { TefraOrsi = "Sacar" } }, Actors = { at("IngenieroOrsi", "Tefra_Lanza", 4, -6), at("DaliaRenn", "Tefra_Lanza", -6, 8) } },
			{ Type = "MiniGame", Game = "Timing", Title = "Sobrecarga del núcleo", Icon = "⚡", Hint = "Fase 3: sobrecarga el núcleo de la Lanza pulsando en el verde",
				Rounds = 5, Need = 3, Zone = 0.24, Speed = 1.1,
				Win = { Flags = { "NucleoLimpio" } }, Lose = { Flags = { "NucleoAPelo" } },
				Actors = { at("DaliaRenn", "Tefra_Lanza", -6, 8) } },
			{ Type = "Escape", Place = "Tefra_RefugioDentro", Respawn = "Tefra_Central", Catch = 4,
				Text = "¡El núcleo va a reventar! Corre al refugio antibombas",
				CaughtLine = "(Un guardia rezagado te agarra de la bufanda. Te sueltas y vuelves a correr.)",
				Actors = {
					DALIA_SIGUE,
					{ Npc = "PoliciaMilitar1", Place = "Tefra_Central", Offset = V(10, 0, 0), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Cinematic", Id = "Tefra_LanzaCae", Actors = { at("DaliaRenn", "Tefra_RefugioDentro", -2, 2) } },
			{ Type = "Scene", Dialogue = "Cae", Actors = { at("DaliaRenn", "Tefra_RefugioDentro", -2, 2), at("Cosme", "Tefra_RefugioDentro", 2, 2) } },
		},
		Dialogues = {
			Ahora = { Lines = {
				{ S = "DaliaRenn", T = "Ha disparado. Ha agrietado el Este. Los volcanes de las Trincheras echan humo.", To = "Yo" },
				{ S = "Cosme", T = "Si dispara otra vez, el planeta se parte como un pan duro. Lo he calculado. Dos veces.", A = "Surprised" },
				{ S = "DaliaRenn", T = "Base de la Lanza. Escudos, torretas, núcleo. En ese orden. En marcha.", G = "Point" },
				{ S = "DaliaRenn", T = "Y Orsi está dentro. Si cumple su palabra, nos ahorramos las torretas.", If = { Choices = { TefraOrsi = "Sacar" } } },
			} },
			Escudos = { Lines = { { S = "Narrador", T = "Arrancas el último cable. El zumbido de los escudos se apaga con un suspiro." } } },
			Torretas = { Lines = { { S = "Narrador", T = "Bajas las palancas una a una. Las torretas de la base se quedan mirando al suelo." } } },
			OrsiDentro = { Lines = {
				{ S = "IngenieroOrsi", T = "¡Las torretas ya no os ven! He tocado el fallo. Me tiemblan las manos, pero lo he tocado.", A = "Nervous", Shot = "Medio:IngenieroOrsi" },
				{ S = "IngenieroOrsi", T = "Ahora el núcleo. Con mi fallo, basta con sobrecargarlo. ¡Rápido!", G = "Point", To = "Yo" },
			} },
			Cae = { Lines = {
				{ S = "DaliaRenn", T = "…Ha caído.", Shot = "PrimerPlano:DaliaRenn", Pause = 1 },
				{ S = "Cosme", T = "No habrá segundo disparo. El planeta aguanta. Mal, pero aguanta.", To = "Yo" },
				{ S = "DaliaRenn", T = "Corvo no se va a quedar quieto. Mañana me buscarán los dos bandos.", Beat = "Piensa" },
				{ S = "DaliaRenn", T = "Así que mañana voy a hacer lo único que no esperan. Ir al Mirador. Delante de todos.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 7 · Alto el fuego
	---------------------------------------------------------------------
	{
		Id = "Tefra_07_Tregua",
		Kind = "Side",
		Canon = true,
		Title = "Alto el fuego",
		Description = "Dalia quiere contar en el Mirador de las Lunas, delante de todo Bastión, lo que era la Lanza. Toda la verdad. También la suya. Los dos bandos la buscan.",
		Type = TIPO .. " (7/7)",
		Duration = { 15, 22 },
		Npcs = { "DaliaRenn", "Cosme", "DoctoraFermina", "CapitanaFerra" },
		Offer = { Place = "Tefra_RefugioDentro" },
		OfferKey = "Dalia se ata la bufanda. «Al Mirador»",
		Requires = after("Tefra_06_Lanza"),
		Moment = "Alto el fuego en Bastión Ceniza",
		Memory = "AltoElFuego",
		-- (la bufanda, la insignia, la carta y la receta llegan en las frases de Fermina, Dalia y el soldado)
		Rewards = {
			Money = 250,
			Flags = { "TreguaTefra" },
			World = { ["Tefra.Tregua"] = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "DaliaRenn", Dialogue = "Salir", Text = "Habla con Dalia en el refugio", Actors = { at("DaliaRenn", "Tefra_RefugioDentro", -2, 2), at("Cosme", "Tefra_RefugioDentro", 2, 2) } },
			{ Type = "Escape", Place = "Tefra_MiradorCentro", Respawn = "Tefra_Refugio", Catch = 4,
				Text = "Escolta a Dalia hasta el Mirador de las Lunas: la buscan los de Corvo y los de Ovilla",
				CaughtLine = "(Os rodean junto a una fuente seca. Ferra aparece y os abre paso… de vuelta al refugio.)",
				Actors = {
					DALIA_SIGUE, COSME_SIGUE,
					{ Npc = "PoliciaMilitar1", Place = "Tefra_Hospital", Offset = V(-10, 0, -10), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "SoldadoOvilla", Place = "Tefra_Termas", Offset = V(-12, 0, -30), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "PoliciaMilitar2", Place = "Tefra_Estatua", Offset = V(30, 0, -10), Mode = "Hunt", Speed = 11, Prompt = false, If = { Flags = { "PrecioCabeza" } } },
				} },
			{ Type = "Fight", Place = "Tefra_MiradorCentro", Respawn = "Tefra_Estatua", Action = "Derribar 💥", HP = 5,
				Text = "Los últimos fieles de Corvo quieren callar a Dalia: ¡defiéndela! ({count}/{total})",
				CaughtLine = "(Te derriban junto a las tiendas. Un refugiado te ayuda a levantarte.)",
				Actors = { at("DaliaRenn", "Tefra_MiradorCentro", 0, 6, "Point") },
				Enemies = {
					{ Npc = "PoliciaMilitar3", Offset = V(-10, 0, -6), Speed = 11, HP = 3, Bye = "Que hable. Que hable de una vez." },
					{ Npc = "PoliciaMilitar1", Offset = V(10, 0, -6), Speed = 11, HP = 3, Bye = "Ya no sé ni por quién disparo." },
				} },
			{ Type = "Scene", Dialogue = "Verdad",
				Actors = { at("DaliaRenn", "Tefra_MiradorCentro", 0, 6), at("DoctoraFermina", "Tefra_MiradorCentro", -6, 2), at("CapitanaFerra", "Tefra_MiradorCentro", 6, 2), at("Cosme", "Tefra_MiradorCentro", 3, -3), at("RefugiadoMayor", "Tefra_MiradorCentro", -8, -4) } },
			{ Type = "Choice", Key = "TefraApoyoDalia", Text = "Todo el Mirador mira a Dalia. Le tiembla la voz. ¿Qué haces?",
				Options = {
					{ Id = "Apoyar", Text = "Subir a su lado, delante de todos", Effects = { Flags = { "ApoyasteADalia" }, Rel = { DaliaRenn = 20, DoctoraFermina = 5 }, Traits = { Valentia = 1 } } },
					{ Id = "Atras", Text = "Quedarte atrás: esto tiene que hacerlo ella sola", Effects = { Flags = { "DaliaSola" }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("DaliaRenn", "Tefra_MiradorCentro", 0, 6), at("DoctoraFermina", "Tefra_MiradorCentro", -6, 2), at("CapitanaFerra", "Tefra_MiradorCentro", 6, 2), at("Cosme", "Tefra_MiradorCentro", 3, -3) } },
			{ Type = "Scene", Dialogue = "Fermina",
				Actors = { at("DaliaRenn", "Tefra_MiradorCentro", 0, 6), at("DoctoraFermina", "Tefra_MiradorCentro", -6, 2), at("CapitanaFerra", "Tefra_MiradorCentro", 6, 2), at("Cosme", "Tefra_MiradorCentro", 3, -3) } },
			{ Type = "Talk", Npc = "DoctoraFermina", Dialogue = "Ada", Text = "Fermina quiere hablar con Cosme, junto a la estatua de Nilda",
				Actors = { at("DoctoraFermina", "Tefra_Estatua", -4, -2), at("Cosme", "Tefra_Estatua", 0, -3) } },
			{ Type = "Cinematic", Id = "Tefra_Silencio", Actors = { at("Cosme", "Tefra_Estatua", 0, -3) } },
			{ Type = "Scene", Dialogue = "Final", Actors = { at("Cosme", "Tefra_Estatua", 0, -3), at("DaliaRenn", "Tefra_Estatua", -5, 2), at("CapitanaFerra", "Tefra_Estatua", -8, 4) } },
		},
		Dialogues = {
			Salir = { Lines = {
				{ S = "DaliaRenn", T = "Cuando la gente sepa lo que era la Lanza, nadie querrá otra. Ni aquí ni en Ovilla.", To = "Yo" },
				{ S = "DaliaRenn", T = "Pero no basta con contar lo de Corvo. Tengo que contar lo mío.", Beat = "Baja" },
				{ S = "Cosme", T = "¿Lo tuyo? ¿Qué es lo tuyo, sargento?", To = "DaliaRenn" },
				{ S = "DaliaRenn", T = "Lo vas a oír allí, con todos. Una vez. En marcha.", A = "ArmsCrossed" },
			} },
			Verdad = { Lines = {
				{ S = "DaliaRenn", T = "Me llamo Dalia Renn. Fui sargento de la Muralla. La torre de los Pozos era un cañón: la Lanza.", Shot = "Medio:DaliaRenn" },
				{ S = "DaliaRenn", T = "Su primer disparo agrietó el Este. Con el segundo, Tefra se habría partido. Corvo lo sabía.", G = "Point" },
				{ S = "Narrador", T = "Un murmullo recorre el Mirador. Alguien deja caer un cubo de agua." },
				{ S = "DaliaRenn", T = "Y ahora lo mío. Hace seis años, el primer día de la guerra, me ordenaron disparar sobre un convoy.", Pause = 1, Shot = "PrimerPlano:DaliaRenn" },
				{ S = "DaliaRenn", T = "Decían que eran soldados de Ovilla. Eran refugiados. Y cumplí la orden.", Beat = "Silencio", A = "Sad" },
				{ S = "DoctoraFermina", T = "…Yo iba en ese convoy.", Shot = "Reaccion:DoctoraFermina", Pause = 1.2 },
			} },
			Fermina = { Lines = {
				{ S = "DoctoraFermina", T = "Me he curado esta cicatriz yo sola durante seis años. Y a cientos como yo.", To = "DaliaRenn" },
				{ S = "DaliaRenn", T = "No te pido que me perdones. Solo quería que lo supieras de mí.", If = { Choices = { TefraApoyoDalia = "Atras" } }, Beat = "Baja" },
				{ S = "DoctoraFermina", T = "Lo sé. Y no puedo. Hoy no. Quizá nunca.", If = { Choices = { TefraApoyoDalia = "Atras" } }, Beat = "Aparta" },
				{ S = "DaliaRenn", T = "No estoy sola aquí arriba. Por primera vez en seis años, no estoy sola.", If = { Choices = { TefraApoyoDalia = "Apoyar" } }, To = "Yo" },
				{ S = "DoctoraFermina", T = "…Te perdono, Dalia. No por ti. Por mí. Ya pesaba demasiado.", If = { Choices = { TefraApoyoDalia = "Apoyar" } }, Pause = 1 },
				{ S = "CapitanaFerra", T = "Dalia Renn, quedas detenida por deserción. Y Bastián Corvo también, en cuanto le encontremos.", Shot = "Medio:CapitanaFerra" },
				{ S = "CapitanaFerra", T = "Ovilla ha pedido un alto el fuego hace una hora. Por primera vez en seis años, lo hemos aceptado.", To = "Yo" },
			} },
			Ada = { Lines = {
				{ S = "DoctoraFermina", T = "Usted es el hermano de Ada. Lo supe en el refugio, por cómo dijo «abuela».", To = "Cosme" },
				{ S = "DoctoraFermina", T = "Ada trabajaba conmigo en el Campus. Repartía pan y vendas. Hace dos años, un bombardeo…", Beat = "Baja" },
				{ S = "DoctoraFermina", T = "No sufrió. Fue de noche, en el horno del barrio. Lo siento mucho.", Pause = 0.8 },
				{ S = "Cosme", T = "…", Shot = "PrimerPlano:Cosme", Pause = 1.5, A = "Sad" },
				{ S = "DoctoraFermina", T = "Guardé esto. Era suyo. Hablaba de un hermano que se cayó al cielo.", Effects = { Items = { BufandaAda = 1 } } },
			} },
			Final = { Lines = {
				{ S = "Narrador", T = "Una carta de Ovilla, traída por un soldado bajo bandera blanca: «Hemos evacuado. Gracias. Tobi».", If = { Choices = { TefraTobiLanza = "Contar" } }, Effects = { Items = { CartaTobi = 1 } } },
				{ S = "Narrador", T = "De Ovilla no llega ninguna carta. Solo el silencio de sus cañones apagados.", If = { Choices = { TefraTobiLanza = "Callar" } } },
				{ S = "DaliaRenn", T = "Toma. Mi insignia. Tú la llevarás mejor que yo.", To = "Yo", Effects = { Items = { InsigniaDalia = 1 } } },
				{ S = "DaliaRenn", T = "Y los planos del traje de la Muralla. Que no se te queme nada más, forastero.", Effects = { Items = { RecetaTraje3 = 1 } } },
				{ S = "Cosme", T = "Vámonos, criatura. Aquí ya no puedo ayudar.", Shot = "Medio:Cosme", Pause = 1, To = "Yo" },
				{ S = "Cosme", T = "Pero volveremos. Ada guardaba un candado en el puente. Lo sé. Ella siempre guardaba cosas.", A = "Sad" },
			} },
		},
	},
}
