-- LA ACADEMIA DE GUERREROS ESPACIALES (17-11-2026, petición del dueño): sin prólogo, el juego empieza aquí.
-- La Academia es el TUTORIAL y donde se APRENDEN LAS HABILIDADES (Effects.Skills → Services/HunterSkillService.learn).
-- Cinco misiones seguidas (capítulo Academia_Guerreros, shared/LifeStory/Chapters):
--   1. Llegada: moverse, correr y el combate de práctica (Atacar).
--   2. Técnicas: Tajo circular y Embestida.
--   3. Primera caza: salir a un distrito de caza (los de fuera del Distrito Central) y cazar bestias.
--   4. Espíritu: Tormenta de acero y Furia del cazador; más caza.
--   5. El juramento: Golpe sísmico y Coraza, el examen final y graduarte (las demás llegan con el nivel).
-- La comandante Kael dirige la Academia; Brenn es el cadete veterano que te entrena; Sorel entra contigo.
-- (17-11-2026, el dueño: «historia para gente algo más adulta, nada infantil».) Trasfondo: hace dos años, en LA
-- CAÍDA, las bestias de la Grieta arrasaron los distritos de fuera; Valmar los evacuó y se encerró en el Distrito
-- Central. Sorel vivía en el Sur; Brenn perdió a su hermano allí; Kael perdió a su escuadra en Tefra.

local V = Vector3.new

local ENTRADA = {
	{ Npc = "Kael", Place = "EntradaColegio", Offset = V(0, 0, 6) },
	{ Npc = "Sorel", Place = "EntradaColegio", Offset = V(4, 0, 4), Mode = "Chat" },
	{ Npc = "Brenn", Place = "EntradaColegio", Offset = V(-5, 0, 7) },
}
local PISTA = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
	{ Npc = "Sorel", Place = "Pista", Offset = V(6, 0, -2), Mode = "Cheer" },
	{ Npc = "Brenn", Place = "Pista", Offset = V(-4, 0, -4) },
}
local PISTA_SIN_BRENN = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
	{ Npc = "Sorel", Place = "Pista", Offset = V(6, 0, -2), Mode = "Cheer" },
}

local COMUN = {
	Kind = "Main",
	Chapter = "Academia_Guerreros",
	AgeRange = { 13, 15 },
	Difficulty = 1,
	Npcs = { "Kael", "Brenn", "Sorel" },
	Locations = { "EntradaColegio", "Pista" },
}
local function mision(t: { [string]: any }): { [string]: any }
	for k, v in COMUN do
		if t[k] == nil then
			t[k] = v
		end
	end
	return t
end

return {
	mision({
		Id = "Acad01_Llegada",
		Title = "La Academia de Guerreros",
		Description = "Dos años después de la Caída, Valmar es una ciudad amurallada rodeada de barrios muertos. La Academia busca a quien quiera recuperarlos. Hoy entras tú.",
		Duration = { 5, 8 },
		Type = "Academia · Tutorial",
		Next = { "Acad02_Tecnicas" },
		Moment = "Tu primer día en la Academia",
		Rewards = { Money = 100, Flags = { "CadeteAcademia" } },
		Steps = {
			{ Type = "Transition", Text = "Valmar. Dos años después de la Caída.", Seconds = 3 },
			{ Type = "Scene", Dialogue = "Llegada", Teleport = "EntradaColegio", Actors = ENTRADA },
			{ Type = "Reach", Place = "Pista", Text = "Ve a la pista de entrenamiento (muévete con el joystick o con W A S D)", Actors = PISTA },
			{ Type = "Event", Event = "Sprinted", Place = "Pista", Text = "Kael quiere verte correr: mantén Correr (Shift en el ordenador)", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Combate", Actors = PISTA },
			{ Type = "Fight", Place = "Pista", Respawn = "Pista", Action = "Golpe ⚔", HP = 4,
				Text = "Combate de práctica: pulsa Atacar para golpear a Brenn ({count}/{total})",
				CaughtLine = "En el suelo estás muerto. Levanta.",
				Actors = PISTA_SIN_BRENN,
				Enemies = {
					{ Npc = "Brenn", Offset = V(0, 0, -8), Speed = 10, HP = 4, Hurt = "Más rápido. Ahí fuera no esperan.", Bye = "Suficiente. Tienes fuerza. Te falta saber cuándo usarla." },
				} },
			{ Type = "Scene", Dialogue = "Primero", Actors = PISTA },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "La Academia ocupa el viejo colegio del barrio. Las ventanas de la planta baja están tapiadas desde la Caída. En la puerta, un escudo nuevo: una estrella partida atravesada por una espada." },
				{ S = "Kael", T = "Soy la comandante Kael. Hace dos años las bestias de la Grieta entraron por el Sur y en una noche perdimos cuatro distritos. Yo estaba en Tefra. Cuando volví, ya no quedaba nada que defender." },
				{ S = "Kael", T = "De cada diez que entran por esa puerta, terminan cuatro. No es una amenaza: es estadística. Si alguien quiere irse, este es el momento." },
				{ S = "Narrador", T = "Nadie se mueve. A tu lado, una chica aprieta tanto la correa de la mochila que tiene los nudillos blancos." },
				{ S = "Sorel", T = "Soy Sorel. Vivía en el Sur, en la calle del mercado. Ahora allí solo hay hierba y huesos. Quiero volver a ver mi casa, aunque esté en ruinas." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Volveremos. Y la recuperaremos.»", Effects = { Rel = { Sorel = 5 }, Traits = { Empatia = 1 } }, Then = {
						{ S = "Sorel", T = "No prometas eso. …Pero gracias." },
					} },
					{ T = "«Yo no vengo a recuperar nada. Vengo a pararlas.»", Effects = { Rel = { Sorel = 2 }, Traits = { Valentia = 1 } }, Then = {
						{ S = "Sorel", T = "Eso también vale. Si las paramos, alguien podrá volver." },
					} },
				} },
				{ S = "Brenn", T = "Brenn, último curso. Os entreno yo. No me hace falta saber vuestros nombres hasta que paséis la primera semana. A la pista." },
			} },
			Combate = { Lines = {
				{ S = "Kael", T = "Primera lección: el cuerpo antes que el arma. Un rifle se encasquilla, se queda sin carga, delata dónde estás. Tus manos y tu espada, no." },
				{ S = "Kael", T = "Pulsa Atacar: vas directo al objetivo más cercano y encadenas golpes. Toca a un enemigo para elegirlo. Brenn, enséñale lo que es un golpe de verdad." },
				{ S = "Brenn", T = "No voy a ir flojo. Las bestias tampoco lo hacen." },
			} },
			Primero = { Lines = {
				{ S = "Kael", T = "Lento, pero no te has rendido. Eso no se enseña." },
				{ S = "Brenn", T = "(en voz baja, limpiándose la sangre del labio) Mi hermano peleaba así. Murió en el Sur la noche de la Caída. No hagas lo mismo que él: no te quedes cuando hay que retirarse." },
				{ S = "Sorel", T = "¿Estás bien? Tienes un corte en la ceja. …Mañana nos toca a nosotras ganar." },
			}, Effects = { Rel = { Brenn = 4 } } },
		},
	}),

	mision({
		Id = "Acad02_Tecnicas",
		Title = "Técnicas de guerrero",
		Description = "Las bestias cazan en manada y no dan segundas oportunidades. Kael os enseña las dos técnicas que mantienen vivo a un guerrero rodeado.",
		Duration = { 4, 6 },
		Type = "Academia · Habilidades",
		Next = { "Acad03_PrimeraCaza" },
		Rewards = { Money = 150 },
		Steps = {
			{ Type = "Talk", Npc = "Kael", Dialogue = "Tajo", Text = "Habla con la comandante Kael en la pista", Actors = PISTA },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "TajoCircular" }, Count = 3, Place = "Pista",
				Text = "Usa el Tajo circular 3 veces (botón 🌀, tecla Z) ({count}/{total})", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Embestida", Actors = PISTA },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "Embestida" }, Count = 2, Place = "Pista",
				Text = "Usa la Embestida 2 veces (botón 💨, tecla X) ({count}/{total})", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Salida", Actors = PISTA },
		},
		Dialogues = {
			Tajo = { Lines = {
				{ S = "Kael", T = "En la Caída, la mayoría no murió por una bestia. Murió por la tercera, la que llegó por detrás mientras peleaba con las dos primeras." },
				{ S = "Kael", T = "Si te rodean, giras y cortas a todas: el Tajo circular. Gasta espíritu, la barra azul. Se recupera sola, más rápido cuando no estás peleando. Si te quedas sin él en mitad de un combate, estás muerto." },
				{ S = "Narrador", T = "Has aprendido el Tajo circular 🌀." },
			}, Effects = { Skills = { "TajoCircular" } } },
			Embestida = { Lines = {
				{ S = "Kael", T = "La Embestida: te lanzas hacia delante y arrollas lo que haya en medio. Sirve para entrar y, sobre todo, para salir." },
				{ S = "Brenn", T = "Úsala para huir sin vergüenza. Los que vuelven son los que saben cuándo irse." },
				{ S = "Narrador", T = "Has aprendido la Embestida 💨." },
			}, Effects = { Skills = { "Embestida" } } },
			Salida = { Lines = {
				{ S = "Kael", T = "Mañana salís de la muralla. Primera caza en los distritos perdidos." },
				{ S = "Sorel", T = "El Sur… ¿podemos ir al Sur?" },
				{ S = "Kael", T = "Podéis ir donde queráis. Pero los recuerdos no os van a proteger. Id a cazar, no a llorar." },
			} },
		},
	}),

	mision({
		Id = "Acad03_PrimeraCaza",
		Title = "Primera caza",
		Description = "Al otro lado de la muralla del Distrito Central están los barrios que perdimos en la Caída. Ahora son territorio de bestias. Sal, caza y vuelve con vida.",
		Duration = { 6, 10 },
		Difficulty = 2,
		Type = "Academia · Caza",
		Next = { "Acad04_Espiritu" },
		Rewards = { Money = 250 },
		Steps = {
			{ Type = "Scene", Dialogue = "Antes", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 3,
				Text = "Sal del Distrito Central a los distritos perdidos (mira el mapa) y caza 3 bestias ({count}/{total})" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Vuelta", Text = "Vuelve a la Academia y cuéntaselo a Kael", Actors = PISTA },
		},
		Dialogues = {
			Antes = { Lines = {
				{ S = "Kael", T = "Pasada la última calle del centro empiezan los distritos perdidos. Ahí ya no hay vecinos: hay guaridas." },
				{ S = "Kael", T = "Las bestias más débiles rondan cerca de la muralla. Cuanto más os alejéis, más duras. No os separéis más de lo necesario." },
				{ S = "Brenn", T = "Si caes, despiertas en el hospital. Esta vez. Fuera de Valmar no hay hospital que te recoja." },
			} },
			Vuelta = { Lines = {
				{ S = "Kael", T = "Tres bestias y vuelves por tu propio pie. Bien." },
				{ S = "Sorel", T = "Fui a mi calle. La puerta de mi casa sigue ahí, con el número. Dentro había un nido. Lo quemé." },
				{ S = "Narrador", T = "Nadie dice nada durante un rato." },
				{ S = "Kael", T = "Siguiente lección: el espíritu. Tormenta de acero para limpiar un grupo; Furia del cazador cuando necesitas que cada golpe cuente." },
				{ S = "Narrador", T = "Has aprendido la Tormenta de acero ⚔ y la Furia del cazador 🔥." },
			}, Effects = { Skills = { "TormentaAcero", "Furia" }, Rel = { Kael = 4, Sorel = 3 } } },
		},
	}),

	mision({
		Id = "Acad04_Espiritu",
		Title = "Espíritu de guerrero",
		Description = "Dos técnicas nuevas, bestias más duras y la primera vez que alguien de tu promoción no vuelve.",
		Duration = { 8, 12 },
		Difficulty = 2,
		Type = "Academia · Habilidades",
		Next = { "Acad05_Juramento" },
		Rewards = { Money = 400 },
		Steps = {
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "TormentaAcero" }, Count = 2,
				Text = "Usa la Tormenta de acero 2 veces (botón ⚔, tecla B) ({count}/{total})" },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "Furia" }, Count = 1,
				Text = "Usa la Furia del cazador (botón 🔥, tecla C)" },
			{ Type = "Event", Event = "BeastKilled", Count = 6,
				Text = "Caza 6 bestias en los distritos de caza ({count}/{total})" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Informe", Text = "Informa a Kael en la Academia", Actors = PISTA },
		},
		Dialogues = {
			Informe = { Lines = {
				{ S = "Kael", T = "Te he visto desde la torre. Furia primero, Tormenta después. Así se hace." },
				{ S = "Kael", T = "Hoy dos cadetes de tu promoción se han separado del grupo en el Oeste. Hemos encontrado a uno." },
				{ S = "Brenn", T = "Por eso os grito. No porque me guste." },
				{ S = "Kael", T = "Últimas técnicas: el Golpe sísmico y la Coraza de grieta. Después, el examen. Y después, ya no habrá nadie mirándote desde la torre." },
				{ S = "Narrador", T = "Has aprendido el Golpe sísmico 💥 y la Coraza de grieta 🛡." },
			}, Effects = { Skills = { "GolpeSismico", "Coraza" }, Rel = { Brenn = 3 } } },
		},
	}),

	mision({
		Id = "Acad05_Juramento",
		Title = "El juramento",
		Description = "El examen final: diez bestias, sin ayuda. Si vuelves, juras como guerrero espacial. Si no, tu nombre va a la pared de la entrada.",
		Duration = { 10, 15 },
		Difficulty = 3,
		Type = "Academia · Examen",
		Moment = "Juraste como guerrero espacial",
		Rewards = { Money = 1000, Flags = { "GuerreroEspacial" }, SetStage = "AdultoJoven" },
		Steps = {
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "GolpeSismico" }, Count = 1,
				Text = "Usa el Golpe sísmico (botón 💥, tecla V)" },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "Coraza" }, Count = 1,
				Text = "Usa la Coraza de grieta (botón 🛡, tecla N)" },
			{ Type = "Event", Event = "BeastKilled", Count = 10,
				Text = "Examen final: caza 10 bestias en los distritos de caza ({count}/{total})" },
			{ Type = "Reach", Place = "Pista", Text = "Vuelve a la Academia: te esperan para el juramento", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Juramento", Actors = PISTA },
		},
		Dialogues = {
			Juramento = { Lines = {
				{ S = "Narrador", T = "En la entrada de la Academia hay una pared con nombres grabados. Hoy hay uno nuevo: el del cadete que no volvió del Oeste." },
				{ S = "Kael", T = "{nombre}. Has peleado con el cuerpo, con la espada y con el espíritu. Has salido de la muralla y has vuelto. Otros no." },
				{ S = "Kael", T = "Repite conmigo: «Defenderé Valmar y los mundos de más allá. No dejaré a nadie atrás.»" },
				{ Ask = "¿Juras?", Options = {
					{ T = "«Lo juro.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Kael", T = "Ya no eres cadete. {Bienvenido/Bienvenida}, guerrero espacial." },
					} },
					{ T = "«Lo juro. Y no dejaré a nadie atrás, aunque me lo ordenen.»", Effects = { Traits = { Rebeldia = 1, Valentia = 1 } }, Then = {
						{ S = "Kael", T = "Yo juré lo mismo en Tefra. Desobedecí una orden por cumplirlo y salvé a dos de once. Ojalá tengas más suerte. {Bienvenido/Bienvenida}, guerrero espacial." },
					} },
				} },
				{ S = "Sorel", T = "Lo hemos conseguido. Quiero alegrarme, pero no puedo dejar de mirar esa pared." },
				{ S = "Brenn", T = "Mírala siempre antes de salir. Para eso está." },
				{ S = "Narrador", T = "Te has graduado: las demás técnicas llegarán con tu nivel de cazador. El puerto espacial ya te deja despegar." },
			}, Effects = { Skills = { "*" }, Rel = { Kael = 6, Sorel = 4, Brenn = 4 } } },
		},
	}),
}
