-- LA ACADEMIA DE GUERREROS ESPACIALES (17-11-2026, petición del dueño): sin prólogo, el juego empieza aquí.
-- La Academia es el TUTORIAL y donde se APRENDEN LAS HABILIDADES (Effects.Skills → Services/HunterSkillService.learn).
-- Cinco misiones seguidas (capítulo Academia_Guerreros, shared/LifeStory/Chapters):
--   1. Llegada: moverse, correr y el combate de práctica (Atacar).
--   2. Técnicas: Tajo circular y Embestida.
--   3. Primera caza: salir a un distrito de caza (los de fuera del Distrito Central) y cazar bestias.
--   4. Espíritu: Tormenta de acero y Furia del cazador; más caza.
--   5. El juramento: Golpe sísmico y Coraza, el examen final y graduarte (las demás llegan con el nivel).
-- La comandante Kael dirige la Academia; Brenn es el cadete veterano que te entrena; Sorel entra contigo.

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
		Description = "Llevas toda la vida mirando las naves cruzar el cielo de Valmar. Hoy entras en la Academia: si aguantas, saldrás guerrero espacial.",
		Duration = { 5, 8 },
		Type = "Academia · Tutorial",
		Next = { "Acad02_Tecnicas" },
		Moment = "Tu primer día en la Academia",
		Rewards = { Money = 100, Flags = { "CadeteAcademia" } },
		Steps = {
			{ Type = "Transition", Text = "Valmar. Primer día en la Academia de Guerreros Espaciales.", Seconds = 3 },
			{ Type = "Scene", Dialogue = "Llegada", Teleport = "EntradaColegio", Actors = ENTRADA },
			{ Type = "Reach", Place = "Pista", Text = "Ve a la pista de entrenamiento (muévete con el joystick o con W A S D)", Actors = PISTA },
			{ Type = "Event", Event = "Sprinted", Place = "Pista", Text = "Kael quiere verte correr: mantén Correr (Shift en el ordenador)", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Combate", Actors = PISTA },
			{ Type = "Fight", Place = "Pista", Respawn = "Pista", Action = "Golpe ⚔", HP = 4,
				Text = "Combate de práctica: pulsa Atacar para golpear a Brenn ({count}/{total})",
				CaughtLine = "Te he tumbado. Arriba, cadete: el suelo no da medallas.",
				Actors = PISTA_SIN_BRENN,
				Enemies = {
					{ Npc = "Brenn", Offset = V(0, 0, -8), Speed = 10, HP = 4, Hurt = "Bien. Otra vez, más rápido.", Bye = "Vale, vale. Tienes brazo. Ahora falta cabeza." },
				} },
			{ Type = "Scene", Dialogue = "Primero", Actors = PISTA },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "La Academia ocupa lo que antes era el colegio del barrio. Ahora en la puerta hay un escudo: una estrella partida y una espada." },
				{ S = "Kael", T = "Cadetes nuevos, a mí. Soy la comandante Kael. He pilotado en tres planetas y he enterrado a gente mejor que yo. Aquí no se viene a jugar." },
				{ S = "Kael", T = "Ahí fuera, pasado el Distrito Central, hay bestias que bajaron por la Grieta. Alguien tiene que pararlas. Si sales de aquí, serás tú." },
				{ S = "Sorel", T = "(en voz baja) Soy Sorel. ¿Tú también llevas años soñando con esto? Yo tengo pósters de naves hasta en el techo." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Desde que vi despegar mi primera nave.»", Effects = { Rel = { Sorel = 5 }, Traits = { Curiosidad = 1 } }, Then = {
						{ S = "Sorel", T = "Lo sabía. Se te nota en la cara. Vamos a llegar, ya verás." },
					} },
					{ T = "«Sueños aparte: vengo a ganar.»", Effects = { Rel = { Sorel = 2 }, Traits = { Valentia = 1 } }, Then = {
						{ S = "Sorel", T = "Uf. Vale. Recuérdame que no me toque contra ti." },
					} },
				} },
				{ S = "Brenn", T = "Soy Brenn, de último curso. Os entreno yo. A la pista, novatos." },
			} },
			Combate = { Lines = {
				{ S = "Kael", T = "Primera lección: el cuerpo antes que el arma. Las armas de fuego se encasquillan; tus puños y tu espada, no." },
				{ S = "Kael", T = "Pulsa Atacar: corres solo hacia el objetivo más cercano y encadenas golpes. Tocar a un enemigo lo elige." },
				{ S = "Brenn", T = "Venga. Prueba conmigo. No me voy a romper." },
			} },
			Primero = { Lines = {
				{ S = "Kael", T = "No está mal para el primer día. Mañana, técnicas de verdad." },
				{ S = "Sorel", T = "¡Le has dado a Brenn! Nadie le da a Brenn el primer día." },
				{ S = "Brenn", T = "Me he dejado. Un poco. …Bastante poco, la verdad." },
			}, Effects = { Rel = { Brenn = 4 } } },
		},
	}),

	mision({
		Id = "Acad02_Tecnicas",
		Title = "Técnicas de guerrero",
		Description = "Kael os enseña las dos primeras técnicas: el Tajo circular, para cuando te rodean, y la Embestida, para entrar en la pelea.",
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
				{ S = "Kael", T = "Las bestias cazan en grupo. Si te rodean, giras y cortas a todas a la vez: el Tajo circular." },
				{ S = "Kael", T = "Cada técnica gasta espíritu: la barra azul. Se recupera sola, más deprisa cuando no estás peleando." },
				{ S = "Narrador", T = "Has aprendido el Tajo circular 🌀." },
			}, Effects = { Skills = { "TajoCircular" } } },
			Embestida = { Lines = {
				{ S = "Kael", T = "Bien. Ahora la Embestida: te lanzas hacia delante y arrollas lo que haya en medio. Para entrar… o para salir." },
				{ S = "Brenn", T = "Consejo de veterano: mira dónde acabas. Yo una vez acabé en la fuente." },
				{ S = "Narrador", T = "Has aprendido la Embestida 💨." },
			}, Effects = { Skills = { "Embestida" } } },
			Salida = { Lines = {
				{ S = "Kael", T = "Suficiente pista. Mañana salís fuera, a los distritos de caza. Ahí las bestias no se dejan." },
				{ S = "Sorel", T = "¿Fuera? ¿Ya? …Vale. Vale. Respira, Sorel." },
			} },
		},
	}),

	mision({
		Id = "Acad03_PrimeraCaza",
		Title = "Primera caza",
		Description = "Valmar es ahora un solo distrito: todo lo de alrededor son tierras de caza. Sal, caza tus primeras bestias y vuelve a contarlo.",
		Duration = { 6, 10 },
		Difficulty = 2,
		Type = "Academia · Caza",
		Next = { "Acad04_Espiritu" },
		Rewards = { Money = 250 },
		Steps = {
			{ Type = "Scene", Dialogue = "Antes", Actors = PISTA },
			{ Type = "Event", Event = "BeastKilled", Count = 3,
				Text = "Sal del Distrito Central a un distrito de caza (mira el mapa) y caza 3 bestias ({count}/{total})" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Vuelta", Text = "Vuelve a la Academia y cuéntaselo a Kael", Actors = PISTA },
		},
		Dialogues = {
			Antes = { Lines = {
				{ S = "Kael", T = "Escuchad. Pasada la última calle del Distrito Central empiezan los distritos de caza. Antes había barrios; ahora hay bestias." },
				{ S = "Kael", T = "Las más flojas están cerca de la ciudad. Cuanto más lejos, más duras. Empezad cerca." },
				{ S = "Brenn", T = "Si te tumban, despiertas en el hospital. Duele en el orgullo, no en otra cosa." },
			} },
			Vuelta = { Lines = {
				{ S = "Kael", T = "Tres bestias y vuelves de pie. Así empiezan los buenos." },
				{ S = "Sorel", T = "Yo cacé dos. Y una casi me caza a mí. No se lo digas a nadie." },
				{ S = "Kael", T = "Ahora lo difícil: el espíritu. Dos técnicas más. Tormenta de acero y Furia del cazador." },
				{ S = "Narrador", T = "Has aprendido la Tormenta de acero ⚔ y la Furia del cazador 🔥." },
			}, Effects = { Skills = { "TormentaAcero", "Furia" }, Rel = { Kael = 4 } } },
		},
	}),

	mision({
		Id = "Acad04_Espiritu",
		Title = "Espíritu de guerrero",
		Description = "Dos técnicas nuevas y bestias más duras. Aprende a gastar el espíritu en el momento justo.",
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
				{ S = "Kael", T = "Te he visto desde la torre. Furia primero y Tormenta después: así se hace." },
				{ S = "Brenn", T = "A mí me costó un mes entender eso. A ti, una tarde. Me caes peor." },
				{ S = "Kael", T = "Últimas técnicas: el Golpe sísmico y la Coraza de grieta. Después, el examen." },
				{ S = "Narrador", T = "Has aprendido el Golpe sísmico 💥 y la Coraza de grieta 🛡." },
			}, Effects = { Skills = { "GolpeSismico", "Coraza" }, Rel = { Brenn = 3 } } },
		},
	}),

	mision({
		Id = "Acad05_Juramento",
		Title = "El juramento",
		Description = "El examen final de la Academia. Si lo pasas, juras como guerrero espacial y el cielo deja de ser un sueño.",
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
				{ S = "Narrador", T = "En la pista están todos los cadetes en fila. Kael lleva el uniforme de gala. Hasta Brenn se ha peinado." },
				{ S = "Kael", T = "{nombre}. Has aprendido a pelear con el cuerpo, con la espada y con el espíritu. Has cazado lejos y has vuelto." },
				{ S = "Kael", T = "Repite conmigo: «Defenderé Valmar y los mundos de más allá. No dejaré a nadie atrás.»" },
				{ Ask = "¿Juras?", Options = {
					{ T = "«Lo juro.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Kael", T = "Entonces ya no eres cadete. {Bienvenido/Bienvenida} al cielo, guerrero espacial." },
					} },
					{ T = "«Lo juro. Y no dejaré a nadie atrás, aunque me lo ordenen.»", Effects = { Traits = { Rebeldia = 1, Valentia = 1 } }, Then = {
						{ S = "Kael", T = "…Eso mismo dije yo. Me costó un expediente. {Bienvenido/Bienvenida} al cielo, guerrero espacial." },
					} },
				} },
				{ S = "Sorel", T = "¡Lo hemos hecho! ¡Guerreros! Esta noche no duermo." },
				{ S = "Brenn", T = "Ahora sois mis compañeros. Que no se os suba. Bueno, un poco sí." },
				{ S = "Narrador", T = "Te has graduado: las demás técnicas llegarán con tu nivel de cazador. El espaciopuerto ya te deja despegar." },
			}, Effects = { Skills = { "*" }, Rel = { Kael = 6, Sorel = 4, Brenn = 4 } } },
		},
	}),
}
