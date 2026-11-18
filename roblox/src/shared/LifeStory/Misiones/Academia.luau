-- LA ACADEMIA DE GUERREROS ESPACIALES (17-11-2026, petición del dueño): sin prólogo, el juego empieza aquí.
-- La Academia es el TUTORIAL y donde se APRENDEN LAS HABILIDADES (Effects.Skills → Services/HunterSkillService.learn).
-- Cinco misiones seguidas (capítulo Academia_Guerreros, shared/LifeStory/Chapters):
--   1. Llegada: el equipo de la armería, la pared de los nombres, correr y el combate de práctica (Atacar).
--   2. Técnicas: Tajo circular, bloqueo (minijuego), Embestida y un combate rodeado (dos contra uno).
--   3. Primera caza: firmar la salida, salir de la muralla, cazar y lo que encuentras junto a una guarida.
--   4. Espíritu: Tormenta de acero y Furia; Dara se pierde en el Oeste: buscarla en la guarida, la radio, y decidir.
--   5. El juramento: Golpe sísmico y Coraza, el examen (caza + duelo contra Kael) y el juramento.
-- La comandante Kael dirige la Academia; Brenn es el cadete veterano que te entrena; Sorel entra contigo; Vossa lleva
-- la armería; Dara es de tu promoción.
-- (18-11-2026, el dueño: «muchas misiones no son interactivas, simplemente es mensaje y ya está; tiene que ser todo
-- muy interactivo» y «para chicos de 15 años para arriba».) Cada misión se JUEGA: recoger el equipo, mirar, elegir,
-- pelear, buscar en terreno hostil, sintonizar una radio. Trasfondo: hace dos años, en LA CAÍDA, las bestias de la
-- Grieta arrasaron los distritos de fuera; Valmar los evacuó y se encerró en el Distrito Central. Sorel vivía en el
-- Sur; Brenn perdió a su hermano allí; Kael perdió a su escuadra en Tefra.

local V = Vector3.new

local ENTRADA = {
	{ Npc = "Kael", Place = "EntradaColegio", Offset = V(0, 0, 6) },
	{ Npc = "Sorel", Place = "EntradaColegio", Offset = V(4, 0, 4), Mode = "Chat" },
	{ Npc = "Brenn", Place = "EntradaColegio", Offset = V(-5, 0, 7) },
}
local ARMERIA = {
	{ Npc = "Vossa", Place = "Vestibulo", Offset = V(4, 0, -2) },
	{ Npc = "Sorel", Place = "Vestibulo", Offset = V(-3, 0, 2), Mode = "Chat" },
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
local PISTA_SOLO_KAEL = {
	{ Npc = "Kael", Place = "Pista", Offset = V(0, 0, -6) },
}

local COMUN = {
	Kind = "Main",
	Chapter = "Academia_Guerreros",
	AgeRange = { 15, 17 },
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
		Duration = { 8, 12 },
		Type = "Academia · Tutorial",
		Next = { "Acad02_Tecnicas" },
		Moment = "Tu primer día en la Academia",
		Rewards = { Money = 100, Flags = { "CadeteAcademia" } },
		Npcs = { "Kael", "Brenn", "Sorel", "Vossa" },
		Props = {
			Uniforme = { Kind = "Armario", Name = "Taquilla 31 · tu uniforme", Prompt = "Ponerte el uniforme", Place = "Vestibulo", Offset = V(-6, 0, -3), Dialogue = "Uniforme", Once = true },
			Espada = { Kind = "Caja", Name = "Armero · espada de cadete", Prompt = "Coger la espada", Place = "Vestibulo", Offset = V(6, 0, -4), Dialogue = "Espada", Once = true },
			Pared = { Kind = "Mural", Name = "La pared de los nombres", Prompt = "Leer los nombres", Place = "EntradaColegio", Offset = V(-8, 0, 2), Dialogue = "Pared", Once = true },
		},
		Steps = {
			{ Type = "Transition", Text = "Valmar. Dos años después de la Caída.", Seconds = 3 },
			{ Type = "Scene", Dialogue = "Llegada", Teleport = "EntradaColegio", Actors = ENTRADA },
			{ Type = "Group", Text = "Prepárate antes de la pista: la armería está en el vestíbulo",
				Actors = ARMERIA,
				Steps = {
					{ Type = "Use", Prop = "Uniforme", Text = "Ponte el uniforme de cadete (taquilla 31)" },
					{ Type = "Use", Prop = "Espada", Text = "Recoge tu espada en el armero" },
					{ Type = "Use", Prop = "Pared", Text = "Lee la pared de la entrada" },
				} },
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
			{ Type = "Choice", Key = "AcadManoBrenn", Text = "Brenn está en el suelo, con el labio partido. Toda la promoción mira. ¿Qué haces?",
				Options = {
					{ Id = "Mano", Text = "Tenderle la mano para que se levante", Effects = { Rel = { Brenn = 6 }, Traits = { Empatia = 1 } } },
					{ Id = "Esperar", Text = "Quedarte en guardia: el combate no ha terminado hasta que Kael lo diga", Effects = { Rel = { Kael = 4 }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Burla", Text = "«¿Eso es todo lo que tiene el último curso?»", Effects = { Rel = { Brenn = -4, Sorel = -2 }, Traits = { Rebeldia = 1 } } },
				},
				Actors = PISTA },
			{ Type = "Scene", Dialogue = "Primero", Actors = PISTA },
		},
		Dialogues = {
			Llegada = { Lines = {
				{ S = "Narrador", T = "La Academia ocupa el viejo colegio del barrio. Las ventanas de la planta baja están tapiadas desde la Caída. En la puerta, un escudo nuevo: una estrella partida atravesada por una espada." },
				{ S = "Kael", T = "Soy la comandante Kael. Hace dos años las bestias de la Grieta entraron por el Sur y en una noche perdimos cuatro distritos. Yo estaba en Tefra. Cuando volví, ya no quedaba nada que defender." },
				{ S = "Kael", T = "De cada diez que entran por esa puerta, terminan cuatro. No es una amenaza: es estadística. Si alguien quiere irse, este es el momento." },
				{ S = "Narrador", T = "Nadie se mueve. A tu lado, una chica aprieta tanto la correa de la mochila que tiene los nudillos blancos." },
				{ S = "Sorel", T = "Soy Sorel. Vivía en el Sur, en la calle del mercado. Ahora allí solo hay hierba y escombros. Quiero volver a ver mi casa, aunque esté en ruinas." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Volveremos. Y la recuperaremos.»", Effects = { Rel = { Sorel = 5 }, Traits = { Empatia = 1 } }, Then = {
						{ S = "Sorel", T = "No prometas eso. …Pero gracias." },
					} },
					{ T = "«Yo no vengo a recuperar nada. Vengo a pararlas.»", Effects = { Rel = { Sorel = 2 }, Traits = { Valentia = 1 } }, Then = {
						{ S = "Sorel", T = "Eso también vale. Si las paramos, alguien podrá volver." },
					} },
					{ T = "(No decir nada. Asentir.)", Effects = { Rel = { Sorel = 1 } }, Then = {
						{ S = "Sorel", T = "Ya. Yo tampoco sé qué decir." },
					} },
				} },
				{ S = "Brenn", T = "Brenn, último curso. Os entreno yo. Pasad por la armería, vestíos, coged acero. En la pista en cinco minutos. El que llegue tarde, corre hasta que yo me aburra." },
			} },
			Uniforme = { Lines = {
				{ S = "Narrador", T = "El uniforme es gris, de lona gruesa, con refuerzos en codos y rodillas. Huele a lejía. Alguien lo llevó antes que tú: hay un nombre tachado con rotulador en la etiqueta." },
				{ S = "Vossa", T = "No preguntes de quién era. Aquí la ropa se hereda. Si lo cuidas, a lo mejor lo hereda alguien de ti y no al revés." },
			} },
			Espada = { Lines = {
				{ S = "Vossa", T = "Acero de chapa de ascensor, templado en la vieja fundición. No es bonito, pero no se dobla." },
				{ S = "Vossa", T = "Firma aquí. Cada vez que salgas de la muralla, firmas. Cada vez que vuelvas, firmas. Las páginas sin la segunda firma las guardo en otro cajón." },
				{ S = "Narrador", T = "Recibes la espada de cadete. Pesa más de lo que esperabas." },
			} },
			Pared = { Lines = {
				{ S = "Narrador", T = "Una pared entera de nombres grabados a punta de cuchillo. Algunos tienen flores secas encajadas en las grietas del ladrillo." },
				{ S = "Narrador", T = "Debajo, una línea más reciente: «Promoción 2. Seis nombres». Y debajo, espacio. Mucho espacio." },
				{ S = "Brenn", T = "(desde la puerta) Mírala bien. La miras antes de cada salida. Para eso está." },
			} },
			Combate = { Lines = {
				{ S = "Kael", T = "Primera lección: el cuerpo antes que el arma. Un rifle se encasquilla, se queda sin carga, delata dónde estás. Tus manos y tu espada, no." },
				{ S = "Kael", T = "Pulsa Atacar: vas directo al objetivo más cercano y encadenas golpes. Toca a un enemigo para elegirlo. Brenn, enséñale lo que es un golpe de verdad." },
				{ S = "Brenn", T = "No voy a ir flojo. Las bestias tampoco lo hacen." },
			} },
			Primero = { Lines = {
				{ S = "Kael", T = "Lento, pero no te has rendido. Eso no se enseña." },
				{ S = "Brenn", T = "(en voz baja, limpiándose el labio con la manga) Mi hermano peleaba así. Murió en el Sur la noche de la Caída. No hagas lo mismo que él: no te quedes cuando hay que retirarse." },
				{ S = "Sorel", T = "¿Estás bien? Tienes un corte en la ceja. …Mañana me toca a mí ganarle." },
			}, Effects = { Rel = { Brenn = 4 } } },
		},
	}),

	mision({
		Id = "Acad02_Tecnicas",
		Title = "Técnicas de guerrero",
		Description = "Las bestias cazan en manada y no dan segundas oportunidades. Kael os enseña a sobrevivir cuando te rodean.",
		Duration = { 6, 9 },
		Type = "Academia · Habilidades",
		Next = { "Acad03_PrimeraCaza" },
		Rewards = { Money = 150 },
		Steps = {
			{ Type = "Talk", Npc = "Kael", Dialogue = "Tajo", Text = "Habla con la comandante Kael en la pista", Actors = PISTA },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "TajoCircular" }, Count = 3, Place = "Pista",
				Text = "Usa el Tajo circular 3 veces (botón del remolino, tecla Z) ({count}/{total})", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Bloqueo", Actors = PISTA },
			{ Type = "MiniGame", Game = "Timing", Title = "Bloquear a Brenn", Icon = "🛡", Hint = "Brenn ataca: pulsa justo cuando la aguja pase por el verde para parar el golpe",
				Rounds = 4, Need = 3, Zone = 0.28, Speed = 1,
				Win = { Flags = { "AcadBloqueoLimpio" }, Rel = { Brenn = 2 } }, Lose = { Flags = { "AcadBloqueoTorpe" } },
				Actors = PISTA },
			{ Type = "Scene", Dialogue = "Embestida", Actors = PISTA },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "Embestida" }, Count = 2, Place = "Pista",
				Text = "Usa la Embestida 2 veces (botón de las flechas, tecla X) ({count}/{total})", Actors = PISTA },
			{ Type = "Scene", Dialogue = "Rodeado", Actors = PISTA },
			{ Type = "Fight", Place = "Pista", Respawn = "Pista", Action = "Golpe ⚔", HP = 6,
				Text = "Dos contra uno: Brenn y Sorel te rodean. Usa el Tajo y la Embestida ({count}/{total})",
				CaughtLine = "Te han cerrado por detrás. Así es como muere la gente. Otra vez.",
				Actors = PISTA_SOLO_KAEL,
				Enemies = {
					{ Npc = "Brenn", Offset = V(-6, 0, -8), Speed = 11, HP = 4, Hurt = "¡Gira! ¡No me des la espalda!", Bye = "Vale. Vale. Has girado a tiempo." },
					{ Npc = "Sorel", Offset = V(6, 0, -8), Speed = 10, HP = 3, Hurt = "¡Perdona! …No, no perdono. ¡Defiéndete!", Bye = "Me rindo. Pero la próxima no." },
				} },
			{ Type = "Scene", Dialogue = "Salida", Actors = PISTA },
		},
		Dialogues = {
			Tajo = { Lines = {
				{ S = "Kael", T = "En la Caída, la mayoría no murió por una bestia. Murió por la tercera, la que llegó por detrás mientras peleaba con las dos primeras." },
				{ S = "Kael", T = "Si te rodean, giras y cortas a todas: el Tajo circular. Gasta espíritu, la barra azul. Se recupera sola, más rápido cuando no estás peleando. Si te quedas sin él en mitad de un combate, estás muerto." },
				{ S = "Narrador", T = "Has aprendido el Tajo circular." },
			}, Effects = { Skills = { "TajoCircular" } } },
			Bloqueo = { Lines = {
				{ S = "Brenn", T = "Atacar lo sabe hacer cualquiera. Lo difícil es no comerte el golpe. Te voy a lanzar cuatro. Para tres." },
				{ S = "Kael", T = "No mires su espada. Mírale los hombros. El golpe sale de ahí antes que del brazo." },
			} },
			Embestida = { Lines = {
				{ S = "Kael", T = "La Embestida: te lanzas hacia delante y arrollas lo que haya en medio. Sirve para entrar y, sobre todo, para salir." },
				{ S = "Brenn", T = "Úsala para huir sin vergüenza. Los que vuelven son los que saben cuándo irse." },
				{ S = "Narrador", T = "Has aprendido la Embestida." },
			}, Effects = { Skills = { "Embestida" } } },
			Rodeado = { Lines = {
				{ S = "Kael", T = "Ahora todo junto. Brenn y Sorel van a por ti a la vez. Sin bajar el ritmo." },
				{ S = "Sorel", T = "Lo siento de antemano." },
			} },
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
		Duration = { 10, 14 },
		Difficulty = 2,
		Type = "Academia · Caza",
		Next = { "Acad04_Espiritu" },
		Rewards = { Money = 250 },
		Npcs = { "Kael", "Brenn", "Sorel", "Vossa" },
		Props = {
			Libro = { Kind = "Libro", Name = "El libro de salidas", Prompt = "Firmar la salida", Place = "Vestibulo", Offset = V(5, 0, -3), Dialogue = "Firma", Once = true },
			Chapa = { Kind = "Marcador", Name = "Algo brilla entre la hierba", Prompt = "Mirar", Place = "GuaridaCercana", Offset = V(6, 0, 4), Dialogue = "Chapa", Once = true },
		},
		Steps = {
			{ Type = "Scene", Dialogue = "Antes", Actors = PISTA },
			{ Type = "Use", Prop = "Libro", Text = "Firma la salida en el libro de Vossa (vestíbulo)", Actors = ARMERIA },
			{ Type = "Event", Event = "BeastKilled", Count = 3,
				Text = "Sal del Distrito Central a los distritos perdidos (mira el mapa) y caza 3 bestias ({count}/{total})" },
			{ Type = "Use", Prop = "Chapa", Text = "Junto a la guarida más cercana algo brilla entre la hierba: acércate a mirarlo" },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Vuelta", Text = "Vuelve a la Academia y cuéntaselo a Kael", Actors = PISTA },
		},
		Dialogues = {
			Antes = { Lines = {
				{ S = "Kael", T = "Pasada la última calle del centro empiezan los distritos perdidos. Ahí ya no hay vecinos: hay guaridas." },
				{ S = "Kael", T = "Las bestias más débiles rondan cerca de la muralla. Cuanto más os alejéis, más duras. No os separéis más de lo necesario." },
				{ S = "Brenn", T = "Si caes, despiertas en el hospital. Esta vez. Fuera de Valmar no hay hospital que te recoja." },
			} },
			Firma = { Lines = {
				{ S = "Vossa", T = "Nombre, hora, destino. Letra clara: si no vuelves, alguien tendrá que leerla." },
				{ S = "Narrador", T = "En la página de al lado hay una fila de nombres con una sola firma. La última es de hace seis días." },
			} },
			Chapa = { Lines = {
				{ S = "Narrador", T = "Una chapa de identificación de la Academia, medio enterrada. El cordón está podrido. Grabado: «Promoción 1 · Ander Vey»." },
				{ S = "Narrador", T = "Alrededor no hay nada más. Solo la hierba aplastada en círculo, como si algo grande durmiera aquí cada noche." },
			} },
			Vuelta = { Lines = {
				{ S = "Kael", T = "Tres bestias y vuelves por tu propio pie. Bien. ¿Qué es eso que llevas en la mano?" },
				{ S = "Narrador", T = "Le enseñas la chapa. Kael la mira mucho rato sin tocarla." },
				{ S = "Kael", T = "Ander Vey. Promoción uno. Salió a por un compañero herido y no volvió ninguno de los dos." },
				{ Ask = "¿Qué haces con la chapa?", Options = {
					{ T = "Dársela a Kael: «Ponla en la pared.»", Effects = { Rel = { Kael = 5 }, Flags = { "ChapaAnderPared" } }, Then = {
						{ S = "Kael", T = "Esta noche la clavo junto a su nombre. Gracias. Su madre sigue viviendo en el asentamiento." },
					} },
					{ T = "Guardarla: «La llevo yo. Para no olvidarme de por qué salgo.»", Effects = { Traits = { Responsabilidad = 1 }, Flags = { "ChapaAnderGuardada" } }, Then = {
						{ S = "Kael", T = "Mucha gente aquí lleva una. No dejes que pese más que tu espada." },
					} },
				} },
				{ S = "Sorel", T = "Fui a mi calle. La puerta de mi casa sigue ahí, con el número. Dentro había un nido. Lo quemé." },
				{ S = "Narrador", T = "Nadie dice nada durante un rato." },
				{ S = "Kael", T = "Siguiente lección: el espíritu. Tormenta de acero para limpiar un grupo; Furia del cazador cuando necesitas que cada golpe cuente." },
				{ S = "Narrador", T = "Has aprendido la Tormenta de acero y la Furia del cazador." },
			}, Effects = { Skills = { "TormentaAcero", "Furia" }, Rel = { Kael = 4, Sorel = 3 } } },
		},
	}),

	mision({
		Id = "Acad04_Espiritu",
		Title = "Espíritu de guerrero",
		Description = "Dos técnicas nuevas, bestias más duras y la primera vez que alguien de tu promoción no vuelve a la hora.",
		Duration = { 14, 20 },
		Difficulty = 2,
		Type = "Academia · Habilidades",
		Next = { "Acad05_Juramento" },
		Rewards = { Money = 400 },
		Npcs = { "Kael", "Brenn", "Sorel", "Dara" },
		Props = {
			Mochila = { Kind = "Mochila", Name = "Una mochila de la Academia, rajada", Prompt = "Registrar la mochila", Place = "GuaridaOeste", Offset = V(-8, 0, 6), Dialogue = "Mochila", Once = true },
			Huellas = { Kind = "Huella", Name = "Huellas de botas que se alejan corriendo", Prompt = "Seguir el rastro con la vista", Place = "GuaridaOeste", Offset = V(10, 0, -4), Dialogue = "Huellas", Once = true },
			Radio = { Kind = "Maquina", Name = "Una radio de la Academia, todavía encendida", Prompt = "Coger la radio", Place = "GuaridaOeste", Offset = V(2, 0, 12), Dialogue = "Radio", Once = true },
		},
		Steps = {
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "TormentaAcero" }, Count = 2,
				Text = "Usa la Tormenta de acero 2 veces (botón de las espadas, tecla B) ({count}/{total})" },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "Furia" }, Count = 1,
				Text = "Usa la Furia del cazador (botón de la llama, tecla C)" },
			{ Type = "Event", Event = "BeastKilled", Count = 6,
				Text = "Caza 6 bestias en los distritos de caza ({count}/{total})" },
			{ Type = "Scene", Dialogue = "Aviso", Actors = PISTA },
			{ Type = "Reach", Place = "GuaridaOeste", Text = "Dara no ha vuelto. Ve a la guarida de la Caza del Oeste, donde se la vio por última vez" },
			{ Type = "Group", Text = "Busca pistas de Dara alrededor de la guarida",
				Steps = {
					{ Type = "Use", Prop = "Mochila", Text = "La mochila rajada" },
					{ Type = "Use", Prop = "Huellas", Text = "Las huellas de botas" },
					{ Type = "Use", Prop = "Radio", Text = "La radio que todavía emite" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Sintonizar la radio", Icon = "📻", Hint = "Gira el dial: pulsa cuando la aguja pase por la frecuencia buena (el verde)",
				Rounds = 3, Need = 2, Zone = 0.24, Speed = 1,
				Win = { Flags = { "AcadRadioClara" } }, Lose = { Flags = { "AcadRadioRuido" } } },
			{ Type = "Scene", Dialogue = "Mensaje" },
			{ Type = "Event", Event = "BeastKilled", Count = 4, Match = { Region = "Farm_Oeste" },
				Text = "La manada vuelve a su guarida. Aguanta: caza 4 bestias de la Caza del Oeste ({count}/{total})" },
			{ Type = "Choice", Key = "AcadDara", Text = "Encuentras a Dara escondida en una casa en ruinas, con el tobillo roto. Oscurece y se oyen más bestias. ¿Qué haces?",
				Options = {
					{ Id = "Cargar", Text = "Cargar con ella hasta la muralla, aunque vayas más lento", Effects = { Flags = { "DaraSalvada" }, Rel = { Dara = 15, Kael = 3 }, Traits = { Valentia = 1, Empatia = 1 } } },
					{ Id = "Bengala", Text = "Dejarla escondida y disparar la bengala para que venga la patrulla", Effects = { Flags = { "DaraBengala" }, Rel = { Dara = 6, Brenn = 4 }, Traits = { Responsabilidad = 1 } } },
				},
				Actors = { { Npc = "Dara", Place = "GuaridaOeste", Offset = V(-14, 0, -10) } } },
			{ Type = "Reach", Place = "Pista", Text = "Vuelve a la Academia",
				Actors = { { Npc = "Dara", Mode = "Follow", If = { Choices = { AcadDara = "Cargar" } } } } },
			{ Type = "Talk", Npc = "Kael", Dialogue = "Informe", Text = "Informa a Kael", Actors = PISTA },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "Kael", T = "Dos cadetes de tu promoción se han separado del grupo en el Oeste. Hemos encontrado a uno. Dara sigue fuera." },
				{ S = "Brenn", T = "La patrulla está en el Sur. Tardaría una hora. Dara no tiene una hora." },
				{ S = "Kael", T = "No te lo ordeno. Te lo pido. Ve a la guarida del Oeste, busca qué ha pasado y, si la encuentras, tráela." },
				{ S = "Sorel", T = "Ten cuidado. Por favor." },
			} },
			Mochila = { Lines = {
				{ S = "Narrador", T = "La mochila está rajada de arriba abajo por algo con garras. Dentro: una cantimplora vacía, una venda sin usar y una foto de una familia delante del mercado del Sur." },
				{ S = "Narrador", T = "La venda sin usar es buena señal. Si estuviera herida de gravedad, la habría usado. O no le dio tiempo." },
			} },
			Huellas = { Lines = {
				{ S = "Narrador", T = "Huellas de botas, muy separadas: corría. Van hacia las casas en ruinas del otro lado de la calle. Encima, huellas mucho más grandes. Más nuevas." },
			} },
			Radio = { Lines = {
				{ S = "Narrador", T = "La radio está en el suelo, todavía encendida. Del altavoz sale ruido blanco y, por debajo, algo parecido a una voz." },
			} },
			Mensaje = { Lines = {
				{ S = "Narrador", T = "Entre el ruido, la voz de Dara, muy baja: «…casa azul, segunda planta… el tobillo… no puedo bajar… si alguien oye esto…»" },
				{ S = "Narrador", T = "Un golpe al otro lado de la calle. La manada ha vuelto." },
			} },
			Informe = { Lines = {
				{ S = "Kael", T = "Dara está viva. Eso es lo único que importa esta noche." },
				{ S = "Brenn", T = "Por eso os grito. No porque me guste." },
				{ S = "Dara", T = "(desde la enfermería, con la pierna en alto) Me separé porque creí que podía sola. No podía. Te debo una." },
				{ S = "Kael", T = "Últimas técnicas: el Golpe sísmico y la Coraza de grieta. Después, el examen. Y después, ya no habrá nadie mirándote desde la torre." },
				{ S = "Narrador", T = "Has aprendido el Golpe sísmico y la Coraza de grieta." },
			}, Effects = { Skills = { "GolpeSismico", "Coraza" }, Rel = { Brenn = 3 } } },
		},
	}),

	mision({
		Id = "Acad05_Juramento",
		Title = "El juramento",
		Description = "El examen final: diez bestias sin ayuda y un duelo contra la comandante. Si vuelves, juras como guerrero espacial. Si no, tu nombre va a la pared de la entrada.",
		Duration = { 14, 20 },
		Difficulty = 3,
		Type = "Academia · Examen",
		Moment = "Juraste como guerrero espacial",
		Rewards = { Money = 1000, Flags = { "GuerreroEspacial" }, SetStage = "AdultoJoven" },
		Steps = {
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "GolpeSismico" }, Count = 1,
				Text = "Usa el Golpe sísmico (botón del impacto, tecla V)" },
			{ Type = "Event", Event = "SkillUsed", Match = { Skill = "Coraza" }, Count = 1,
				Text = "Usa la Coraza de grieta (botón del escudo, tecla N)" },
			{ Type = "Event", Event = "BeastKilled", Count = 10,
				Text = "Examen, parte 1: caza 10 bestias en los distritos de caza ({count}/{total})" },
			{ Type = "Reach", Place = "Pista", Text = "Vuelve a la pista: la comandante te espera para la segunda parte", Actors = PISTA_SOLO_KAEL },
			{ Type = "Scene", Dialogue = "Duelo", Actors = PISTA },
			{ Type = "Fight", Place = "Pista", Respawn = "Pista", Action = "Golpe ⚔", HP = 6,
				Text = "Examen, parte 2: duelo contra la comandante Kael. Usa todo lo que has aprendido ({count}/{total})",
				CaughtLine = "Muerto. Levanta y vuelve a empezar. Las bestias no te dan una segunda vez; yo sí.",
				Actors = PISTA_SIN_BRENN,
				Enemies = {
					{ Npc = "Kael", Offset = V(0, 0, -8), Speed = 12, HP = 6, Hurt = "Bien. Otra vez. No bajes la guardia después de acertar.", Bye = "Suficiente. …Me has hecho retroceder. Hacía años que nadie lo conseguía." },
				} },
			{ Type = "Scene", Dialogue = "Juramento", Actors = PISTA },
		},
		Dialogues = {
			Duelo = { Lines = {
				{ S = "Kael", T = "Las bestias son fuertes, pero son tontas. Lo que de verdad te va a matar ahí fuera es alguien que piensa. Quiero ver cómo peleas contra alguien que piensa." },
				{ S = "Brenn", T = "(a Sorel, en voz baja) A mí me tumbó en cuatro segundos." },
			} },
			Juramento = { Lines = {
				{ S = "Narrador", T = "En la entrada de la Academia, la pared de los nombres. Este año no hay ninguno nuevo de tu promoción." },
				{ S = "Kael", T = "{nombre}. Has peleado con el cuerpo, con la espada y con el espíritu. Has salido de la muralla y has vuelto. Y has traído a otros de vuelta." },
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
