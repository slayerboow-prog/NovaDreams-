-- SAGA 2 «RAGNAROCK» · NIVALIS · FORTALEZA ALBOR: la primera parte jugable (unos 30 minutos) del episodio 4
-- «La noche del Regente» (docs/planetas/diseno-mundos.md §3.4; lo que se juega: docs/planetas/nivalis-umbria.md;
-- marco común: docs/planetas/marco-planetas.md). Misiones CANÓNICAS: su marca dorada sale en Fortaleza
-- Albor y empiezan solas al llegar al sitio. Solo en Nivalis (Requires.Planet). Lugares «Nivalis_…»
-- (shared/Cosmos/NivalisCity.StorySpots).
--
--   1 Nivalis_01_Oscuras   «Aterrizaje a oscuras»   la noche eterna, el frío (tutorial), Tila y la sopa
--   2 Nivalis_02_Silencio  «La hora del silencio»   cruzar la plaza sin que te vea la guardia, la delación (decisión)
--   3 Nivalis_03_Faroles   «El código de los faroles» un turno de farolero y los faroles que contestan
--   4 Nivalis_04_Ecos      «La Biblioteca de los Ecos» colarse, el puzle de los cristales, Madre Copo, la pelea (decisión)
--   5 Nivalis_05_Muralla   «La Muralla Vieja»       la vela por los que no vuelven y la princesa que no murió
-- Termina con el gancho del episodio: Ilse está viva y os espera en las Minas.
-- 13+: sin sangre; los guardias resbalan en la nieve y huyen; nadie muere en cámara (la reina murió en prisión
-- hace seis años, fuera de la historia).

local V = Vector3.new

local TIPO = "Saga 2 · Nivalis · «La noche del Regente»"

local function after(id: string?, extra: { [string]: any }?): { [string]: any }
	local req: { [string]: any } = { Stage = { Min = "Adulto" }, Planet = "Nivalis" }
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
local TILA_SIGUE = { Npc = "Tila", Mode = "Follow" }

return {
	---------------------------------------------------------------------
	-- 1 · Aterrizaje a oscuras
	---------------------------------------------------------------------
	{
		Id = "Nivalis_01_Oscuras",
		Kind = "Side",
		Canon = true,
		Title = "Aterrizaje a oscuras",
		Description = "Has aterrizado en Fortaleza Albor, la capital de Nivalis: un planeta de noche eterna donde el Regente decide qué barrios reciben la luz de las auroras… y cuáles se mueren de frío.",
		Type = TIPO .. " (1/5)",
		Duration = { 6, 8 },
		Npcs = { "Tila" },
		Offer = { Place = "Nivalis_Plataforma" },
		OfferKey = "Fortaleza Albor. La escarcha cruje bajo las botas y nadie habla en voz alta",
		Requires = after(nil),
		Moment = "Llegaste a Fortaleza Albor en plena noche eterna",
		Memory = "LlegadaNivalis",
		Rewards = { Money = 60, Flags = { "NivalisLlegado" } },
		Steps = {
			{ Type = "Cinematic", Id = "Nivalis_Llegada" },
			{ Type = "Reach", Place = "Nivalis_Mirador", Text = "Sal por la Puerta Norte hasta el Mirador del Valle, fuera de la muralla (mira tu medidor de ❄ frío)" },
			{ Type = "Event", Event = "HazardChanged", Match = { Planet = "Nivalis", Phase = "Aviso" }, Place = "Nivalis_Mirador",
				Text = "Mira el Palacio de Escarcha desde el Mirador… hasta que el frío te muerda" },
			{ Type = "Talk", Npc = "Tila", Dialogue = "Tila", Text = "¡Tiritas! Una farolera te hace señas desde la hoguera de la plaza", Actors = { at("Tila", "Nivalis_Hoguera", 2, 2) } },
			{ Type = "Event", Event = "HazardCountered", Match = { Planet = "Nivalis" }, Place = "Nivalis_Hoguera",
				Text = "Tómate la 🍲 sopa caliente (desde la mochila)", Actors = { at("Tila", "Nivalis_Hoguera", 2, 2) } },
			{ Type = "Talk", Npc = "Tila", Dialogue = "Silencio", Text = "Tila quiere decirte algo, muy bajito", Actors = { at("Tila", "Nivalis_Hoguera", 2, 2) } },
		},
		Dialogues = {
			Tila = { Lines = {
				{ S = "Tila", T = "Eh. Tú. El de la nave. Ven a la hoguera antes de que se te caigan las orejas.", To = "Yo", Shot = "Medio:Tila" },
				{ S = "Tila", T = "Has salido de la muralla sin abrigo. Aquí eso no lo hace ni el Regente. Y el Regente no tiene corazón.", A = "ArmsCrossed" },
				{ S = "Tila", T = "Mira tu medidor. Fuera, el frío sube siempre. Junto a una hoguera, en las Termas o en casa, baja.", G = "Point" },
				{ S = "Tila", T = "Toma: un abrigo de lana de lanudo y dos sopas de Brisa. Bébete una ya. No me mires así: bébetela.", Effects = { Items = { AbrigoLana = 1, SopaAlbor = 2 } } },
			} },
			Silencio = { Lines = {
				{ S = "Tila", T = "Soy Tila. Farolera. Enciendo los faroles del barrio. Y nadie se fija en quien enciende los faroles.", Shot = "Medio:Tila" },
				{ S = "Tila", T = "Mira el cielo. ¿Ves la aurora sobre el Palacio? Aquí no llega. El Regente se la quitó al barrio.", G = "Point" },
				{ S = "Tila", T = "Dicen que nos portamos mal. Que cantamos. Ahora cantar está prohibido. Y hablar alto en la calle, también.", A = "Sad" },
				{ S = "Tila", T = "Dentro de poco empieza la hora del silencio. Si quieres saber más, sígueme. Sin hacer ruido.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 2 · La hora del silencio
	---------------------------------------------------------------------
	{
		Id = "Nivalis_02_Silencio",
		Kind = "Side",
		Canon = true,
		Title = "La hora del silencio",
		Description = "En la hora del silencio nadie puede hablar en la calle. Tila quiere llevarte a su casa, al otro lado de la Plaza de los Faroles, y la guardia del Regente hace la ronda.",
		Type = TIPO .. " (2/5)",
		Duration = { 6, 8 },
		Npcs = { "Tila", "GuardiaRegente1", "GuardiaRegente2", "VecinoCarambano" },
		Offer = { Place = "Nivalis_Hoguera" },
		OfferKey = "Suena una campana en el Palacio. La plaza se queda muda de golpe",
		Requires = after("Nivalis_01_Oscuras"),
		Moment = "Cruzaste la plaza en la hora del silencio y te escondiste en las Termas",
		Memory = "HoraDelSilencio",
		Rewards = { Money = 80 },
		Steps = {
			{ Type = "Talk", Npc = "Tila", Dialogue = "Plan", Text = "Escucha el plan de Tila (en susurros)", Actors = { at("Tila", "Nivalis_Hoguera", 2, 2) } },
			{ Type = "Escape", Place = "Nivalis_CasaTila", Respawn = "Nivalis_Hoguera", Catch = 4,
				Text = "Cruza la Plaza de los Faroles hasta la casa de Tila sin que te pille la guardia (andando: correr se oye)",
				CaughtLine = "¡Quieto! ¿Qué hace usted en la calle en la hora del silencio? …Vuelva a la hoguera. Ahora.",
				Actors = {
					TILA_SIGUE,
					{ Npc = "GuardiaRegente1", Place = "Nivalis_Plaza", Offset = V(10, 0, 10), Mode = "Hunt", Speed = 9, Prompt = false },
					{ Npc = "GuardiaRegente2", Place = "Nivalis_Estatua", Offset = V(-12, 0, 8), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Delacion", Actors = { at("VecinoCarambano", "Nivalis_CasaTila", 6, -4), at("Tila", "Nivalis_CasaTila", -2, 2) } },
			{ Type = "Escape", Place = "Nivalis_TermasDentro", Respawn = "Nivalis_CasaTila", Catch = 4,
				Text = "¡Os han delatado! Escóndete con Tila en las Termas del Farol, en el Patio de Armas",
				CaughtLine = "¡Alto! ¡Documentos! …(Tila tira un cubo de nieve al farol del guardia y volvéis a correr desde la casa.)",
				Actors = {
					TILA_SIGUE,
					{ Npc = "GuardiaRegente1", Place = "Nivalis_Plaza", Offset = V(-6, 0, 0), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "GuardiaRegente2", Place = "Nivalis_Plataforma", Offset = V(-20, 0, 0), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Choice", Key = "NivalisVecino", Text = "Entre el vapor, Tila te cuenta quién os delató: el señor Carámbano, que roba musgo de las hogueras para sus hijos. Si lo cuentas a la guardia, se lo llevan. ¿Qué haces?",
				Options = {
					{ Id = "Castigar", Text = "Denunciarle tú también: que pruebe su medicina", Effects = { Flags = { "CarambanoDenunciado" }, Traits = { Valentia = 1 } } },
					{ Id = "Dejar", Text = "Dejarle: tiene miedo y dos hijos", Effects = { Flags = { "CarambanoPerdonado" }, Rel = { Tila = 10 }, Traits = { Empatia = 1 } } },
				},
				Actors = { at("Tila", "Nivalis_TermasDentro", 2, 2) } },
			{ Type = "Scene", Dialogue = "Termas", Actors = { at("Tila", "Nivalis_TermasDentro", 2, 2) } },
		},
		Dialogues = {
			Plan = { Lines = {
				{ S = "Tila", T = "Mi casa está al otro lado de la plaza. Dos guardias hacen la ronda con faroles azules.", To = "Yo" },
				{ S = "Tila", T = "Anda despacio. En la nieve, correr cruje y se oye desde el Palacio. Ve por donde no llega la luz.", G = "Point" },
				{ S = "Tila", T = "Si te paran, no hables. Aquí hablar es lo que te pierde.", A = "ArmsCrossed" },
			} },
			Delacion = { Lines = {
				{ S = "VecinoCarambano", T = "¡Guardia! ¡Guardia! ¡La farolera mete forasteros en casa! ¡Sin carné!", Shot = "Medio:VecinoCarambano", A = "Angry" },
				{ S = "Tila", T = "¡Señor Carámbano! ¿Qué hace?", To = "VecinoCarambano", A = "Surprised" },
				{ S = "VecinoCarambano", T = "Lo siento, niña. Lo siento. Si no aviso yo, avisa otro. Y entonces me llevan a mí.", A = "Sad", Pause = 0.6 },
				{ S = "Tila", T = "A las Termas. Corre. Ahora sí: ¡corre!", To = "Yo", G = "Point" },
			} },
			Termas = { Lines = {
				{ S = "Tila", T = "Ya está. Lo has dicho. Mañana el barrio te tendrá miedo. A lo mejor eso es bueno. O a lo mejor no.", If = { Choices = { NivalisVecino = "Castigar" } }, A = "Sad" },
				{ S = "Tila", T = "Gracias. El señor Carámbano no es malo. Es que tiene frío. Aquí todo el mundo tiene frío.", If = { Choices = { NivalisVecino = "Dejar" } }, Shot = "Medio:Tila" },
				{ S = "Tila", T = "Mi hermano Nilo desapareció hace un año. Se lo llevó la guardia de noche. Nadie sabe adónde.", To = "Yo", Beat = "Piensa" },
				{ S = "Tila", T = "Pero los faroleros tenemos un código. Si Nilo está vivo, contestará. Mañana te enseño.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 3 · El código de los faroles
	---------------------------------------------------------------------
	{
		Id = "Nivalis_03_Faroles",
		Kind = "Side",
		Canon = true,
		Title = "El código de los faroles",
		Description = "Los faroles de Fortaleza Albor no solo dan luz: los faroleros se hablan con ellos en código. Tila te enseña el oficio para mandar un mensaje a su hermano.",
		Type = TIPO .. " (3/5)",
		Duration = { 7, 9 },
		Npcs = { "Tila" },
		Offer = { Place = "Nivalis_TorreFarol" },
		OfferKey = "Tila espera al pie de la Torre del Farolero con una pértiga y una lata de aceite",
		Requires = after("Nivalis_02_Silencio"),
		Moment = "Los faroles de la plaza contestaron en código",
		Memory = "CodigoFaroles",
		Rewards = { Money = 90, Items = { MusgoNieve = 2 } },
		Props = {
			Farol1 = { Kind = "Marcador", Name = "Farol del oeste", Prompt = "Encender (largo-corto)", Place = "Nivalis_Farol1", Dialogue = "Farol1", Once = true },
			Farol2 = { Kind = "Marcador", Name = "Farol del este", Prompt = "Encender (corto-corto)", Place = "Nivalis_Farol2", Dialogue = "Farol2", Once = true },
			Farol3 = { Kind = "Marcador", Name = "Farol del Patio", Prompt = "Encender (largo)", Place = "Nivalis_Farol3", Dialogue = "Farol3", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Tila", Dialogue = "Oficio", Text = "Habla con Tila al pie de la Torre del Farolero", Actors = { at("Tila", "Nivalis_TorreFarol", 2, 2) } },
			{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "NivalisFarolero" }, Place = "Nivalis_TorreFarol",
				Text = "Haz una ronda de 🏮 farolero/a (tablón «Trabajar» junto a la Torre del Farolero)", Actors = { at("Tila", "Nivalis_TorreFarol", 2, 2) } },
			{ Type = "Talk", Npc = "Tila", Dialogue = "Codigo", Text = "Tila te espera en la plaza para mandar el mensaje", Actors = { at("Tila", "Nivalis_Plaza", 0, 2) } },
			{ Type = "Group", Text = "Enciende los tres faroles del código, como te ha dicho Tila",
				Actors = { TILA_SIGUE },
				Steps = {
					{ Type = "Use", Prop = "Farol1", Text = "El farol del oeste de la plaza" },
					{ Type = "Use", Prop = "Farol2", Text = "El farol del este de la plaza" },
					{ Type = "Use", Prop = "Farol3", Text = "El farol del Patio de Armas" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "La respuesta de los faroles", Icon = "🏮", Hint = "Lee la respuesta: pulsa cada vez que el farol de enfrente se encienda",
				Rounds = 3, Need = 2, Zone = 0.26, Speed = 1,
				Win = { Flags = { "CodigoLeido" } }, Lose = { Flags = { "CodigoATrozos" } },
				Actors = { at("Tila", "Nivalis_Plaza", 0, 2) } },
			{ Type = "Scene", Dialogue = "Respuesta", Actors = { at("Tila", "Nivalis_Plaza", 0, 2) } },
		},
		Dialogues = {
			Oficio = { Lines = {
				{ S = "Tila", T = "Un farolero sube la mecha sin que se apague y no corre nunca. Y deja mensajes en la muralla sin que lo vean.", To = "Yo", Shot = "Medio:Tila" },
				{ S = "Tila", T = "Coge una ronda del tablón. Si lo haces bien, los viejos faroleros te dejarán usar los faroles de la plaza.", G = "Point" },
				{ S = "Tila", T = "Y pagan. Poco, pero pagan. Aquí hasta la sopa cuesta.", A = "Shrug" },
			} },
			Codigo = { Lines = {
				{ S = "Tila", T = "Los viejos dicen que lo has hecho bien. Ahora, el mensaje: tres faroles, en el orden que quieras.", To = "Yo" },
				{ S = "Tila", T = "Largo-corto en el del oeste, corto-corto en el del este, largo en el del Patio. Quiere decir: «Nilo, ¿estás?».", G = "Point" },
				{ S = "Tila", T = "Si alguien lo sabe, contestará desde el farol del otro lado de la plaza.", Beat = "Piensa" },
			} },
			Farol1 = { Lines = { { S = "Narrador", T = "Subes la mecha: largo… corto. La llama ámbar tiembla en la nieve." } } },
			Farol2 = { Lines = { { S = "Narrador", T = "Corto… corto. Una ventana se cierra deprisa en una casa de la plaza." } } },
			Farol3 = { Lines = { { S = "Narrador", T = "Largo. En la Torre del Farolero, alguien apaga su luz un momento. Te ha visto." } } },
			Respuesta = { Lines = {
				{ S = "Narrador", T = "Al otro lado de la plaza, el farol de la esquina parpadea solo: largo, largo, corto. Corto, largo." },
				{ S = "Tila", T = "«Vivo». Y… «Minas». ¡Está vivo! ¡Nilo está vivo!", Shot = "PrimerPlano:Tila", A = "Surprised" },
				{ S = "Tila", T = "Lo has leído entero. Ni yo lo habría leído tan rápido.", If = { Flags = { "CodigoLeido" } }, To = "Yo" },
				{ S = "Tila", T = "Has leído la mitad, pero la mitad buena. «Minas». Las Minas de Cristal.", If = { Flags = { "CodigoATrozos" } }, To = "Yo" },
				{ S = "Tila", T = "Alguien de las Minas tiene acceso a los faroles. Madre Copo sabrá quién. Ella lo sabe todo. Y está encerrada en su biblioteca.", Beat = "Piensa" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 4 · La Biblioteca de los Ecos
	---------------------------------------------------------------------
	{
		Id = "Nivalis_04_Ecos",
		Kind = "Side",
		Canon = true,
		Title = "La Biblioteca de los Ecos",
		Description = "La Biblioteca de los Ecos guarda las canciones de Nivalis en cristales que cantan. El Regente la cerró. Madre Copo, la bibliotecaria, sigue dentro… y sabe quién contesta desde las Minas.",
		Type = TIPO .. " (4/5)",
		Duration = { 7, 9 },
		Npcs = { "Tila", "MadreCopo", "GuardiaRegente1", "GuardiaRegente2" },
		Offer = { Place = "Nivalis_Biblioteca" },
		OfferKey = "La puerta de la Biblioteca de los Ecos tiene tres candados y un sello azul del Regente",
		Requires = after("Nivalis_03_Faroles"),
		Moment = "Oíste la canción de la Reina dentro de un cristal de eco",
		Memory = "CancionDeLaReina",
		Rewards = { Money = 110, Items = { HieloEterno = 1, LanaLanudo = 2 } },
		Steps = {
			{ Type = "Talk", Npc = "Tila", Dialogue = "Callejon", Text = "Habla con Tila en el callejón de detrás de la Biblioteca", Actors = { at("Tila", "Nivalis_Callejon", 0, 2) } },
			{ Type = "Escape", Place = "Nivalis_BibliotecaDentro", Respawn = "Nivalis_Callejon", Catch = 4,
				Text = "Entra en la Biblioteca de los Ecos sin que te vea la ronda del Cuerpo de Guardia",
				CaughtLine = "¿Quién anda ahí? …(Te escondes en un ventisquero y vuelves al callejón.)",
				Actors = {
					TILA_SIGUE,
					{ Npc = "GuardiaRegente1", Place = "Nivalis_Biblioteca", Offset = V(-8, 0, -14), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Cristales de eco", Icon = "🔹", Hint = "Cada cristal canta una canción. Pulsa cuando suene la voz de mujer",
				Rounds = 3, Need = 2, Zone = 0.24, Speed = 1.05,
				Win = { Flags = { "CristalEncontrado" } }, Lose = { Flags = { "CristalAlFinal" } },
				Actors = { TILA_SIGUE } },
			{ Type = "Scene", Dialogue = "Copo", Actors = { at("MadreCopo", "Nivalis_BibliotecaDentro", -3, -2), at("Tila", "Nivalis_BibliotecaDentro", 3, 1) } },
			{ Type = "Choice", Key = "NivalisCristal", Text = "Madre Copo te ofrece el cristal con la canción de la Reina. Si te lo pillan, es delito. Si se queda aquí, la guardia puede encontrarlo. ¿Qué haces?",
				Options = {
					{ Id = "Llevar", Text = "Llevármelo: lo guardaré yo", Effects = { Items = { CristalReina = 1 }, Flags = { "CristalContigo" }, Traits = { Valentia = 1 } } },
					{ Id = "Dejar", Text = "Dejarlo con Madre Copo: nadie lo esconde mejor", Effects = { Flags = { "CristalConCopo" }, Rel = { MadreCopo = 15 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { at("MadreCopo", "Nivalis_BibliotecaDentro", -3, -2), at("Tila", "Nivalis_BibliotecaDentro", 3, 1) } },
			{ Type = "Fight", Place = "Nivalis_Biblioteca", Respawn = "Nivalis_BibliotecaDentro", Action = "Empujar a la nieve 💨", HP = 3,
				Text = "¡La guardia ha oído la canción! Empuja a los dos guardias a la nieve ({count}/{total})",
				CaughtLine = "(Resbalas en el hielo de la entrada. Tila te levanta de un tirón.)",
				Actors = { at("Tila", "Nivalis_Biblioteca", -4, 3, "Point") },
				Enemies = {
					{ Npc = "GuardiaRegente1", Offset = V(-12, 0, -6), Speed = 9, HP = 2, Bye = "¡Esto… esto lo sabrá el Regente!" },
					{ Npc = "GuardiaRegente2", Offset = V(-12, 0, 6), Speed = 10, HP = 2, Bye = "¡Mi farol! ¡Se me ha apagado el farol!" },
				} },
			{ Type = "Escape", Place = "Nivalis_Pasadizo", Respawn = "Nivalis_Biblioteca", Catch = 4,
				Text = "¡Vienen más! Huye con Tila hasta el pasadizo de la Muralla Vieja (la nieve borrará tus huellas)",
				CaughtLine = "(Una mano te agarra la capa. Tila le tira su lata de aceite y volvéis a correr.)",
				Actors = {
					TILA_SIGUE,
					{ Npc = "GuardiaRegente1", Place = "Nivalis_CuerpoGuardia", Offset = V(-4, 0, 6), Mode = "Hunt", Speed = 10.5, Prompt = false },
				} },
		},
		Dialogues = {
			Callejon = { Lines = {
				{ S = "Tila", T = "La puerta tiene tres candados. Pero la ventana del sótano da al callejón, y está rota desde el invierno.", To = "Yo" },
				{ S = "Tila", T = "La ronda pasa cada poco con su farol azul. Cuando se vaya, entramos.", G = "Point" },
			} },
			Copo = { Lines = {
				{ S = "MadreCopo", T = "Un ladrón no buscaría la voz de una mujer entre mil cristales. Tú buscabas a alguien.", Shot = "Medio:MadreCopo", To = "Yo" },
				{ S = "Tila", T = "¡Madre Copo! Nilo está vivo. Ha contestado con los faroles desde las Minas.", To = "MadreCopo", A = "Surprised" },
				{ S = "MadreCopo", T = "Lo sé, niña. Quien contesta desde las Minas no es tu hermano. Pero lo cuida.", Beat = "Piensa" },
				{ S = "MadreCopo", T = "Esa voz que has encontrado es la Reina Alva. Cantaba esto antes de que Morvan le quitara la luz al valle.", To = "Yo", A = "Sad" },
				{ S = "MadreCopo", T = "Las canciones son la memoria de un pueblo. Sin ellas, Albor no recordará quién era.", Pause = 0.8 },
			} },
		},
	},

	---------------------------------------------------------------------
	-- 5 · La Muralla Vieja
	---------------------------------------------------------------------
	{
		Id = "Nivalis_05_Muralla",
		Kind = "Side",
		Canon = true,
		Title = "La Muralla Vieja",
		Description = "Los rebeldes usan los pasadizos de la Muralla Vieja. Allí, Tila deja una vela por los que no vuelven. Esta noche, alguien la está esperando.",
		Type = TIPO .. " (5/5)",
		Duration = { 5, 7 },
		Npcs = { "Tila", "PrincesaIlse" },
		Offer = { Place = "Nivalis_Pasadizo" },
		OfferKey = "En el pasadizo de la muralla hay huellas recientes que no son de guardia",
		Requires = after("Nivalis_04_Ecos"),
		Moment = "Viste a la princesa que oficialmente murió en el Glaciar",
		Memory = "PrincesaViva",
		Rewards = { Money = 140, Items = { AbrigoLana2 = 1, VelaTila = 1 }, Flags = { "NivalisIlseViva" } },
		Props = {
			Vela = { Kind = "Marcador", Name = "La piedra de las velas", Prompt = "Encender la vela", Place = "Nivalis_Pasadizo", Offset = V(-3, 0, -2), Dialogue = "Vela", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Tila", Dialogue = "Pasadizo", Text = "Habla con Tila en el pasadizo de la Muralla Vieja", Actors = { at("Tila", "Nivalis_Pasadizo", 2, 2) } },
			{ Type = "Use", Prop = "Vela", Text = "Enciende la vela por los que no vuelven", Actors = { at("Tila", "Nivalis_Pasadizo", 2, 2) } },
			{ Type = "Cinematic", Id = "Nivalis_Princesa", Actors = { at("Tila", "Nivalis_Pasadizo", 2, 2), at("PrincesaIlse", "Nivalis_Pasadizo", -6, -6) } },
			{ Type = "Talk", Npc = "PrincesaIlse", Dialogue = "Ilse", Text = "Habla con la mujer de la capa blanca", Actors = { at("PrincesaIlse", "Nivalis_Pasadizo", -4, -4), at("Tila", "Nivalis_Pasadizo", 2, 2) } },
		},
		Dialogues = {
			Pasadizo = { Lines = {
				{ S = "Tila", T = "Aquí dejamos una vela por cada desaparecido. Está prohibido. Por eso la ponemos aquí, donde no mira nadie.", To = "Yo", Shot = "Medio:Tila" },
				{ S = "Tila", T = "Hoy, enciéndela tú. Por Nilo. Para que sepa que alguien le espera.", A = "Sad" },
			} },
			Vela = { Lines = {
				{ S = "Narrador", T = "La llama prende a la primera. En la piedra hay cientos de manchas de cera. Cientos de nombres que nadie dice." },
			} },
			Ilse = { Lines = {
				{ S = "PrincesaIlse", T = "Tila me habló de ti. El forastero que lee faroles y no delata a los vecinos asustados.", If = { Choices = { NivalisVecino = "Dejar" } }, To = "Yo" },
				{ S = "PrincesaIlse", T = "Tila me habló de ti. El forastero que lee faroles. Y que también sabe delatar.", If = { Choices = { NivalisVecino = "Castigar" } }, To = "Yo", A = "ArmsCrossed" },
				{ S = "PrincesaIlse", T = "Me llamo Ilse. Oficialmente, morí en el Glaciar hace seis años. Mi tío Morvan lloró en mi funeral.", Shot = "PrimerPlano:PrincesaIlse" },
				{ S = "PrincesaIlse", T = "Llevas la voz de mi madre en el bolsillo. Guárdala bien. Un día la oirá toda la ciudad.", If = { Choices = { NivalisCristal = "Llevar" } }, To = "Yo" },
				{ S = "PrincesaIlse", T = "Nilo está conmigo, en las Minas. Vivo. Pero el Regente hace trabajar a los presos hasta que no sienten las manos.", To = "Tila" },
				{ S = "PrincesaIlse", T = "Ponte este abrigo. Es de los faroleros. Ahí abajo el frío no perdona. Y la noche del Regente acaba de empezar.", To = "Yo", Beat = "Mira" },
			} },
		},
	},
}
