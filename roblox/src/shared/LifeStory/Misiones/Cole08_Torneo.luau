-- MISIÓN 08 · «EL TORNEO» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.18.
--
-- Andrés presenta el torneo → eliges deporte (fútbol con Nico, baloncesto con Álex, atletismo con
-- Sara) → entrenamiento (distinto en cada deporte) → charla del equipo (capitán y estrategia) →
-- clasificación contra 1.º B → descanso: tu familia en la grada y Bruno antes de la final → la
-- final contra el equipo de Bruno → cómo celebras o encajas el resultado → medallas. Al final corre
-- un rumor: la sala cerrada del fondo del pasillo (misión 09).

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }

local FUTBOL = { Choices = { Deporte = "Futbol" } }
local BALONCESTO = { Choices = { Deporte = "Baloncesto" } }
local ATLETISMO = { Choices = { Deporte = "Atletismo" } }

-- La presentación: Andrés en la pista y cada capitán de deporte buscando gente
local PRESENTA = {
	{ Npc = "Andres", Place = "Pista", Offset = V(0, 0, 6) },
	{ Npc = "Nico", Place = "Pista", Offset = V(-6, 0, 2), Bark = "¡Fútbol! ¡Aquí! ¡FÚTBOL!" },
	{ Npc = "Alex", Place = "Pista", Offset = V(0, 0, -1), Bark = "Baloncesto. Sin gritar. Con estilo." },
	{ Npc = "Sara", Place = "Pista", Offset = V(6, 0, 2), Bark = "Atletismo: ciencia aplicada a correr." },
	{ Npc = "Omar", Place = "Pista", Offset = V(-3, 0, 5) },
	{ Npc = "Mateo", Place = "Pista", Offset = V(3, 0, 5), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "Pista", Offset = V(8, 0, 6), If = CON_HUGO },
	{ Npc = "Bruno", Place = "Pista", Offset = V(-10, 0, 7), Bark = "Da igual el deporte. Os vamos a ganar en todos." },
	{ Npc = "Ruben", Place = "Pista", Offset = V(-12, 0, 5) },
}

-- Tu equipo, según el deporte (Omar, Mateo y Hugo se apuntan contigo a lo que elijas)
local function equipo(place: string): { any }
	return {
		{ Npc = "Andres", Place = place, Offset = V(0, 0, 8) },
		{ Npc = "Nico", Place = place, Offset = V(-4, 0, 2), If = FUTBOL },
		{ Npc = "Alex", Place = place, Offset = V(-4, 0, 2), If = BALONCESTO },
		{ Npc = "Sara", Place = place, Offset = V(-4, 0, 2), If = ATLETISMO },
		{ Npc = "Omar", Place = place, Offset = V(3, 0, 3) },
		{ Npc = "Mateo", Place = place, Offset = V(-1, 0, 5), If = AMIGO_MATEO },
		{ Npc = "Hugo", Place = place, Offset = V(5, 0, -1), If = CON_HUGO },
	}
end
local EQUIPO_FUTBOL = equipo("CampoColegio")
local EQUIPO_BALONCESTO = equipo("CanchaColegio")
local EQUIPO_ATLETISMO = equipo("Pista")

-- El rival de la clasificación: dos alumnos de 1.º B
local function rival1B(place: string): { any }
	return {
		{ Npc = "Alumno1", Place = place, Offset = V(8, 0, -6), Bark = "¡1.º B! ¡1.º B!" },
		{ Npc = "Alumno2", Place = place, Offset = V(11, 0, -4) },
	}
end
local function con(list: { any }, extra: { any }): { any }
	local out = table.clone(list)
	for _, actor in extra do
		table.insert(out, actor)
	end
	return out
end

-- La grada: tu familia y Abu han venido a verte; Bruno calienta cerca
local GRADA = {
	{ Npc = "Familia", Place = "Pista", Offset = V(-8, 0, 12), Mode = "Cheer" },
	{ Npc = "Abu", Place = "Pista", Offset = V(-5, 0, 13), Mode = "Wave" },
	{ Npc = "Omar", Place = "Pista", Offset = V(2, 0, 6) },
	{ Npc = "Nico", Place = "Pista", Offset = V(5, 0, 4), If = FUTBOL },
	{ Npc = "Alex", Place = "Pista", Offset = V(5, 0, 4), If = BALONCESTO },
	{ Npc = "Sara", Place = "Pista", Offset = V(5, 0, 4), If = ATLETISMO },
	{ Npc = "Hugo", Place = "Pista", Offset = V(8, 0, 8), If = CON_HUGO },
	{ Npc = "Bruno", Place = "Pista", Offset = V(12, 0, -4) },
	{ Npc = "Ruben", Place = "Pista", Offset = V(14, 0, -2) },
}

local function final(place: string): { any }
	return con(equipo(place), {
		{ Npc = "Bruno", Place = place, Offset = V(8, 0, -6) },
		{ Npc = "Ruben", Place = place, Offset = V(11, 0, -4) },
		{ Npc = "Familia", Place = place, Offset = V(-10, 0, 10), Mode = "Cheer" },
		{ Npc = "Abu", Place = place, Offset = V(-7, 0, 11), Mode = "Wave" },
	})
end
local FINAL_FUTBOL = final("CampoColegio")
local FINAL_BALONCESTO = final("CanchaColegio")
local FINAL_ATLETISMO = final("Pista")

local GANADO = { Flags = { "TorneoGanado" } }
local PERDIDO = { Flags = { "TorneoPerdido" } }
local CLASIFICA_BIEN = { Flags = { "ClasificacionGanada" } }
local CLASIFICA_MAL = { NotFlags = { "ClasificacionGanada" } }

return {
	Id = "Cole08_Torneo",
	Kind = "Main",
	Title = "El torneo",
	Description = "Empieza el torneo del colegio. Elige tu deporte, entrena con tu equipo… y llega a la final.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 9, 9 },
	Duration = { 20, 30 },
	Difficulty = 3,
	Type = "Historia · Deporte",
	Requires = { Completed = { "Cole07_Excursion" }, StageProgress = 0.54 },
	Npcs = { "Andres", "Nico", "Alex", "Sara", "Omar", "Mateo", "Hugo", "Bruno", "Ruben", "Familia", "Abu", "Alumno1", "Alumno2" },
	Locations = { "Pista", "CampoColegio", "CanchaColegio" },
	Next = { "Cole09_Misterio" },
	Outcomes = { "Fútbol, baloncesto o atletismo", "Capitán o no", "Oro o plata", "Cómo ganas o pierdes" },

	Moment = "Tu primer torneo",
	Memory = "PrimerTorneo",
	Rewards = { Money = 10 },

	Props = {
		Botella = { Kind = "Marcador", Name = "La fuente de la pista", Prompt = "Beber agua", Place = "Pista", Offset = V(-2, 0, 14), Dialogue = "Beber", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "El lunes siguiente…", Seconds = 3 },
		{ Type = "Reach", Place = "Pista", Text = "Ve a la pista: Andrés reúne a toda la clase", Actors = PRESENTA },
		{ Type = "Scene", Dialogue = "Presentacion", Actors = PRESENTA },
		{ Type = "Choice", Key = "Deporte", Text = "¿A qué deporte te apuntas? (habla con quien elijas)",
			Options = {
				{ Id = "Futbol", Npc = "Nico", Text = "Fútbol, con Nico", Dialogue = "Elige_Futbol", Effects = { Rel = { Nico = 5 } } },
				{ Id = "Baloncesto", Npc = "Alex", Text = "Baloncesto, con Álex", Dialogue = "Elige_Baloncesto", Effects = { Rel = { Alex = 5 } } },
				{ Id = "Atletismo", Npc = "Sara", Text = "Atletismo, con Sara", Dialogue = "Elige_Atletismo", Effects = { Rel = { Sara = 5 } } },
			},
			Actors = PRESENTA },

		-- Entrenamiento: cada deporte, el suyo
		{ Type = "Reach", Place = "CampoColegio", Text = "Ve al campo de fútbol a entrenar", If = FUTBOL, Actors = EQUIPO_FUTBOL },
		{ Type = "Scene", Dialogue = "Entreno_Futbol", If = FUTBOL, Actors = EQUIPO_FUTBOL },
		{ Type = "MiniGame", Game = "Timing", Title = "Entrenamiento: pases al hueco", Icon = "⚽", Hint = "Pasa cuando la aguja esté en verde",
			Rounds = 5, Need = 3, Zone = 0.26, Speed = 1, If = FUTBOL,
			Win = { Rel = { Nico = 3 }, Flags = { "BuenEntreno" } }, Lose = { Traits = { Humor = 1 } },
			Actors = EQUIPO_FUTBOL },

		{ Type = "Reach", Place = "CanchaColegio", Text = "Ve a la cancha a entrenar", If = BALONCESTO, Actors = EQUIPO_BALONCESTO },
		{ Type = "Scene", Dialogue = "Entreno_Baloncesto", If = BALONCESTO, Actors = EQUIPO_BALONCESTO },
		{ Type = "MiniGame", Game = "Timing", Title = "Entrenamiento: tiros libres", Icon = "🏀", Hint = "Suelta cuando la aguja esté en verde",
			Rounds = 6, Need = 3, Zone = 0.25, Shrink = 0.02, Speed = 1, If = BALONCESTO,
			Win = { Rel = { Alex = 3 }, Flags = { "BuenEntreno" } }, Lose = { Traits = { Humor = 1 } },
			Actors = EQUIPO_BALONCESTO },

		{ Type = "Scene", Dialogue = "Entreno_Atletismo", If = ATLETISMO, Actors = EQUIPO_ATLETISMO },
		{ Type = "Class", Subject = "EducacionFisica", Mode = "Circuito", Place = "Pista", Text = "Entrena el circuito de la pista", If = ATLETISMO,
			Effects = { Rel = { Sara = 3 }, Flags = { "BuenEntreno" } }, Actors = EQUIPO_ATLETISMO },

		-- La charla del equipo: capitán y estrategia
		{ Type = "Scene", Dialogue = "Charla", Actors = EQUIPO_FUTBOL, If = FUTBOL },
		{ Type = "Scene", Dialogue = "Charla", Actors = EQUIPO_BALONCESTO, If = BALONCESTO },
		{ Type = "Scene", Dialogue = "Charla", Actors = EQUIPO_ATLETISMO, If = ATLETISMO },

		-- Clasificación contra 1.º B
		{ Type = "Transition", Text = "El día del torneo…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Clasificacion", If = FUTBOL, Teleport = "CampoColegio", Actors = con(EQUIPO_FUTBOL, rival1B("CampoColegio")) },
		{ Type = "MiniGame", Game = "Futbol", Title = "Clasificación contra 1.º B", Icon = "⚽", Plays = 4, Rival = "1.º B",
			PositionFrom = "Posicion", If = FUTBOL, Win = CLASIFICA_BIEN, Lose = { Traits = { Deportividad = 1 } },
			Actors = con(EQUIPO_FUTBOL, rival1B("CampoColegio")) },
		{ Type = "Scene", Dialogue = "Clasificacion", If = BALONCESTO, Teleport = "CanchaColegio", Actors = con(EQUIPO_BALONCESTO, rival1B("CanchaColegio")) },
		{ Type = "MiniGame", Game = "Timing", Title = "Clasificación contra 1.º B", Icon = "🏀", Hint = "Cada canasta cuenta. Necesitáis 3.",
			Rounds = 6, Need = 3, Zone = 0.24, Shrink = 0.02, Speed = 1.05, If = BALONCESTO,
			Win = CLASIFICA_BIEN, Lose = { Traits = { Deportividad = 1 } },
			Actors = con(EQUIPO_BALONCESTO, rival1B("CanchaColegio")) },
		{ Type = "Scene", Dialogue = "Clasificacion", If = ATLETISMO, Teleport = "Pista", Actors = con(EQUIPO_ATLETISMO, rival1B("Pista")) },
		{ Type = "MiniGame", Game = "Timing", Title = "Clasificación: ¡la salida!", Icon = "🏃", Hint = "Sal justo cuando la aguja esté en verde",
			Rounds = 4, Need = 2, Zone = 0.22, Speed = 1.15, If = ATLETISMO,
			Win = CLASIFICA_BIEN, Lose = { Traits = { Deportividad = 1 } },
			Actors = con(EQUIPO_ATLETISMO, rival1B("Pista")) },
		{ Type = "Scene", Dialogue = "TrasClasificacion" },

		-- El descanso: la grada
		{ Type = "Reach", Place = "Pista", Text = "Descanso: ve a la grada de la pista", Actors = GRADA },
		{ Type = "Group", Text = "Aprovecha el descanso", Need = 2,
			Steps = {
				{ Type = "Talk", Npc = "Familia", Dialogue = "Grada_Familia", Text = "Saluda a {familia} en la grada" },
				{ Type = "Talk", Npc = "Abu", Dialogue = "Grada_Abu", Text = "Habla con {abu}" },
				{ Type = "Use", Prop = "Botella", Text = "Bebe agua en la fuente" },
			},
			Props = { "Botella" }, Actors = GRADA },
		{ Type = "Talk", Npc = "Bruno", Dialogue = "Bruno_PreFinal", Text = "Bruno te está mirando. Habla con él", Actors = GRADA },

		-- La final contra el equipo de Bruno
		{ Type = "Scene", Dialogue = "Final", If = FUTBOL, Teleport = "CampoColegio", Actors = FINAL_FUTBOL },
		{ Type = "MiniGame", Game = "Futbol", Title = "¡LA FINAL! Contra el equipo de Bruno", Icon = "🏆", Plays = 6, Rival = "el equipo de Bruno",
			PositionFrom = "Posicion", If = FUTBOL,
			Win = { Flags = { "TorneoGanado" }, Items = { MedallaOro = 1 }, Traits = { Deportividad = 1 }, Rel = { Nico = 5, Omar = 3 } },
			Lose = { Flags = { "TorneoPerdido" }, Items = { MedallaPlata = 1 }, Rel = { Nico = 3, Omar = 3 } },
			Actors = FINAL_FUTBOL },
		{ Type = "Scene", Dialogue = "Final", If = BALONCESTO, Teleport = "CanchaColegio", Actors = FINAL_BALONCESTO },
		{ Type = "MiniGame", Game = "Timing", Title = "¡LA FINAL! Contra el equipo de Bruno", Icon = "🏆", Hint = "Cada vez más difícil. Necesitáis 4 canastas.",
			Rounds = 8, Need = 4, Zone = 0.24, Shrink = 0.03, Speed = 1.1, If = BALONCESTO,
			Win = { Flags = { "TorneoGanado" }, Items = { MedallaOro = 1 }, Traits = { Deportividad = 1 }, Rel = { Alex = 6, Omar = 3 } },
			Lose = { Flags = { "TorneoPerdido" }, Items = { MedallaPlata = 1 }, Rel = { Alex = 4, Omar = 3 } },
			Actors = FINAL_BALONCESTO },
		{ Type = "Scene", Dialogue = "Final", If = ATLETISMO, Teleport = "Pista", Actors = FINAL_ATLETISMO },
		{ Type = "MiniGame", Game = "Timing", Title = "¡LA FINAL! El relevo contra el equipo de Bruno", Icon = "🏆", Hint = "Pasa el testigo en la zona verde. ¡No lo sueltes!",
			Rounds = 6, Need = 4, Zone = 0.24, Shrink = 0.02, Speed = 1.15, If = ATLETISMO,
			Win = { Flags = { "TorneoGanado" }, Items = { MedallaOro = 1 }, Traits = { Deportividad = 1 }, Rel = { Sara = 6, Omar = 3 } },
			Lose = { Flags = { "TorneoPerdido" }, Items = { MedallaPlata = 1 }, Rel = { Sara = 4, Omar = 3 } },
			Actors = FINAL_ATLETISMO },

		-- Ganar y perder
		{ Type = "Scene", Dialogue = "Resultado", If = FUTBOL, Actors = FINAL_FUTBOL },
		{ Type = "Scene", Dialogue = "Resultado", If = BALONCESTO, Actors = FINAL_BALONCESTO },
		{ Type = "Scene", Dialogue = "Resultado", If = ATLETISMO, Actors = FINAL_ATLETISMO },
		{ Type = "Reach", Place = "Pista", Text = "Ve a la pista: ¡entrega de medallas!", Actors = PRESENTA },
		{ Type = "Scene", Dialogue = "Medallas", Actors = PRESENTA },
		{ Type = "Scene", Dialogue = "Rumor", Actors = {
			{ Npc = "Omar", Mode = "Follow" },
			{ Npc = "Sara", Mode = "Follow" },
			{ Npc = "Nico", Mode = "Follow" },
		} },
	},

	Dialogues = {
		Presentacion = { Lines = {
			{ S = "Andres", T = "¡Atención, deportistas! Empieza el torneo de primavera del colegio. Tres deportes: fútbol, baloncesto y atletismo." },
			{ S = "Andres", T = "Cada uno elige UNO. Entrenamos esta semana, y el viernes: clasificación contra 1.º B y, si pasáis… la final." },
			{ S = "Bruno", T = "La final es nuestra. Siempre es nuestra." },
			{ S = "Andres", T = "Bruno, la final es de quien juegue mejor. Y de quien juegue limpio. Venga: id con vuestro capitán de deporte." },
			{ S = "Omar", T = "Yo voy a donde vaya {nombre}. Soy malo en los tres deportes por igual. Es un talento." },
		} },
		Elige_Futbol = { Lines = {
			{ S = "Nico", T = "¡SÍ! ¡Lo sabía! Tú y yo, en el mismo equipo. Otra vez. Como el primer partido." },
			{ S = "Nico", T = "Y esta vez vamos a entrenar. Bueno, esta vez vamos a entrenar MÁS." },
		} },
		Elige_Baloncesto = { Lines = {
			{ S = "Alex", T = "Bien. Me acuerdo de tus canastas en el gimnasio. Tienes muñeca." },
			{ S = "Alex", T = "Regla número uno: no se tira desde el medio del campo. Regla número dos: a veces sí." },
		} },
		Elige_Atletismo = { Lines = {
			{ S = "Sara", T = "Excelente elección. He calculado que si movemos los brazos a la vez que las piernas, corremos un doce por ciento más." },
			{ S = "Sara", T = "Técnicamente todo el mundo lo hace ya. Pero ahora lo haremos A PROPÓSITO." },
		} },

		Entreno_Futbol = { Lines = {
			{ S = "Andres", T = "Hoy: pases. El fútbol es de todos, no del que más corre. Nico, eso va por ti." },
			{ S = "Nico", T = "¡Yo paso muchísimo! Cuando me acuerdo." },
			{ S = "Omar", T = "Yo me pongo de portero. Así corro menos y pienso más." },
		} },
		Entreno_Baloncesto = { Lines = {
			{ S = "Alex", T = "Tiros libres. Respira, mira el aro, flexiona las rodillas y… suelta. Como si nada." },
			{ S = "Omar", T = "Como si nada. Vale. Lo mío es más bien «como si todo»." },
		} },
		Entreno_Atletismo = { Lines = {
			{ S = "Sara", T = "El circuito: vallas, saltos, conos y un sprint final. Andrés lo cronometra." },
			{ S = "Andres", T = "Y la carrera del viernes es un relevo. Así que hoy también aprendéis a pasaros el testigo sin tirarlo." },
			{ S = "Omar", T = "¿Y si lo tiro?" },
			{ S = "Sara", T = "Entonces lo recoges. Muy rápido. Y finges que era parte del plan." },
		} },

		Charla = { Lines = {
			{ S = "Andres", T = "Buen entrenamiento, equipo. Antes del viernes necesitáis dos cosas: un capitán y un plan." },
			{ S = "Nico", T = "Yo creo que el capitán debería ser {nombre}.", If = FUTBOL },
			{ S = "Alex", T = "Yo votaría a {nombre}. Pero también me votaría a mí. Decidid.", If = BALONCESTO },
			{ S = "Sara", T = "Propongo votar. Datos: {nombre} tiene buena cabeza. Yo tengo mejor cabeza. Pero {nombre} tiene más amigos.", If = ATLETISMO },
			{ S = "Hugo", T = "Yo… no he estado nunca en un equipo donde se vota. Me gusta.", If = CON_HUGO },
			{ Ask = "¿Quién es el capitán?", Options = {
				{ T = "Yo. Me hace ilusión.", Effects = { Choice = { Capitan = "Yo" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Omar", T = "¡Capitán {nombre}! Te hago un brazalete con cinta de carrocero." },
				} },
				{ T = "Nico. Nadie tiene más ganas que él.", If = FUTBOL, Effects = { Choice = { Capitan = "Otro" }, Rel = { Nico = 8 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Nico", T = "¿Yo? ¿YO? ¡No os voy a fallar! ¡Voy a llorar! ¡No voy a llorar!" },
				} },
				{ T = "Álex. Sabe más que nadie.", If = BALONCESTO, Effects = { Choice = { Capitan = "Otro" }, Rel = { Alex = 8 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Alex", T = "Vale. Primera orden de la capitana: nadie se agobia. Segunda: nadie se agobia." },
				} },
				{ T = "Sara. Tiene un plan para todo.", If = ATLETISMO, Effects = { Choice = { Capitan = "Otro" }, Rel = { Sara = 8 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Sara", T = "Acepto. He traído un cuaderno para anotar la estrategia. Lo traía por si acaso. Siempre lo traigo." },
				} },
				{ T = "Omar. Hace falta alguien tranquilo.", Effects = { Choice = { Capitan = "Omar" }, Rel = { Omar = 10 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Omar", T = "¿Yo? Nunca me han elegido para nada. Bueno, una vez para borrar la pizarra. Gracias. De verdad." },
				} },
			} },
			{ S = "Andres", T = "Y el plan: ¿cómo vais a jugar?" },
			{ Ask = "¿Qué estrategia proponéis?", Options = {
				{ T = "Ir a por todas desde el principio", Effects = { Choice = { Estrategia = "Ataque" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Andres", T = "Con valentía. Me gusta. Pero guardad aire para el final." },
				} },
				{ T = "Paciencia: cansarlos y rematar al final", Effects = { Choice = { Estrategia = "Paciencia" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Andres", T = "Con cabeza. Los partidos se ganan en el último minuto." },
				} },
				{ T = "Que juegue todo el mundo, aunque perdamos", Effects = { Choice = { Estrategia = "Todos" }, Traits = { Deportividad = 1 }, Rel = { Omar = 3, Mateo = 3, Hugo = 3 } }, Then = {
					{ S = "Andres", T = "Eso, equipo, es lo que yo llamo un equipo. Así da gusto." },
				} },
			} },
		} },

		Clasificacion = { Lines = {
			{ S = "Andres", T = "¡Clasificación! 4.º A contra 1.º B. Los que ganen pasan directos a la final." },
			{ S = "Alumno1", T = "¡Somos más pequeños pero somos MÁS RÁPIDOS!" },
			{ S = "Omar", T = "Son pequeñitos. Me dan un poco de miedo. Parecen muy motivados." },
		} },
		TrasClasificacion = { Lines = {
			{ S = "Andres", T = "¡Ganáis la clasificación! Directos a la final.", If = CLASIFICA_BIEN },
			{ S = "Andres", T = "1.º B gana… ¡pero pasáis como mejor segundo! Estáis en la final por los pelos.", If = CLASIFICA_MAL },
			{ S = "Alumno1", T = "Buen partido. El año que viene os ganamos. Bueno, este también casi.", If = CLASIFICA_BIEN },
			{ S = "Andres", T = "Descanso de veinte minutos. Y la final es contra… cómo no: el equipo de Bruno." },
		} },

		Grada_Familia = { Lines = {
			{ S = "Familia", T = "¡{nombre}! ¡Hemos venido todos! Bueno, estamos {abu} y yo, que es como todos." },
			{ S = "Familia", T = "Ganes o pierdas, esta noche hay cena especial. Aunque si ganas, con postre doble." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Me tiemblan las piernas. ¿Y si fallo?»", Effects = { Traits = { Empatia = 1 } }, Then = {
					{ S = "Familia", T = "Entonces fallas, y lo vuelves a intentar. Así se hace todo en la vida. Todo." },
				} },
				{ T = "«¡Vamos a ganar!»", Effects = { Traits = { Valentia = 1 } }, Then = {
					{ S = "Familia", T = "¡Esa es la actitud! Yo gritaré tanto que me quedaré sin voz." },
				} },
			} },
		} },
		Grada_Abu = { Lines = {
			{ S = "Abu", T = "Yo jugué una final a tu edad. Perdimos por un gol. ¿Sabes qué recuerdo? El bocadillo de después con mis amigos." },
			{ S = "Abu", T = "Del resultado casi no me acuerdo. De los amigos, de todos. Disfrútalo, cariño." },
		} },
		Beber = { Lines = {
			{ S = "Narrador", T = "Agua fresquita. Respiras hondo. Desde aquí se oye a tu familia animando. Y a Omar, que anima más fuerte." },
		}, Effects = { Needs = { Energy = 10 } } },

		Bruno_PreFinal = { Lines = {
			{ S = "Bruno", T = "Oye. Lo del otro día… gracias por hablar conmigo en vez de ir contándolo por ahí.", If = { Flags = { "Bruno_HablasteConEl" } } },
			{ S = "Bruno", T = "Pero hoy os gano igual. Que una cosa no quita la otra.", If = { Flags = { "Bruno_HablasteConEl" } } },
			{ S = "Bruno", T = "Mira, el detective. Hoy no hay nada que investigar: solo vais a perder.", If = { Flags = { "AcusasteABruno" }, NotFlags = { "Bruno_HablasteConEl" } } },
			{ S = "Bruno", T = "¿Vosotros en la final? Qué valor.", If = { NotFlags = { "Bruno_HablasteConEl", "AcusasteABruno" } } },
			{ S = "Hugo", T = "Bruno. Juego con ellos. Y ya está. No pasa nada.", If = CON_HUGO },
			{ S = "Bruno", T = "…Ya. Ya lo sé. Pues suerte. Pero poca.", If = CON_HUGO },
			{ S = "Ruben", T = "(Rubén, bajito:) Buena suerte. De verdad.", If = { Flags = { "Ruben_Perdonado" } } },
			{ Ask = "¿Qué le contestas a Bruno?", Options = {
				{ T = "«Que gane el mejor. Y que sea divertido.»", Effects = { Traits = { Deportividad = 2 }, Rel = { Bruno = 4 }, Choice = { PreFinal = "Deportivo" } }, Then = {
					{ S = "Bruno", T = "…Vale. Que sea divertido. Pero que gane yo." },
				} },
				{ T = "«Ya veremos en el campo.»", Effects = { Traits = { Valentia = 1 }, Choice = { PreFinal = "Reto" } }, Then = {
					{ S = "Bruno", T = "Ya veremos. Eso digo yo." },
				} },
				{ T = "No le contestas. Vuelves con tu equipo.", Effects = { Choice = { PreFinal = "Nada" } }, Then = {
					{ S = "Narrador", T = "Bruno se queda con la frase a medias. Tu equipo te está esperando." },
				} },
			} },
		} },

		Final = { Lines = {
			{ S = "Andres", T = "¡LA FINAL! 4.º A contra… 4.º A. El equipo de {nombre} contra el equipo de Bruno." },
			{ S = "Familia", T = "¡VAMOS, {nombre}!" },
			{ S = "Omar", T = "Capitán, unas palabras.", If = { Choices = { Capitan = "Yo" } } },
			{ S = "Omar", T = "Soy el capitán. Unas palabras: ¡a por ellos! Con cariño.", If = { Choices = { Capitan = "Omar" } } },
			{ S = "Andres", T = "Recordad el plan. ¡Y a disfrutar!" },
		} },

		Resultado = { Lines = {
			{ S = "Andres", T = "¡Final! ¡Gana el equipo de {nombre}! ¡CAMPEONES DEL TORNEO!", If = GANADO },
			{ S = "Andres", T = "¡Final! Gana el equipo de Bruno… ¡pero qué final! Subcampeones, y con la cabeza bien alta.", If = PERDIDO },
			{ S = "Bruno", T = "…Bien jugado. De verdad. Lo odio, pero bien jugado.", If = GANADO },
			{ S = "Bruno", T = "¡Lo sabía! …Aunque ha estado muy cerca. Muy cerca. Casi me da algo.", If = PERDIDO },
			{ Ask = "¿Qué haces ahora?", Options = {
				{ T = "Dar la mano a todo el equipo de Bruno", Effects = { Traits = { Deportividad = 2 }, Rel = { Bruno = 5, Ruben = 3 }, Choice = { TrasFinal = "Mano" } }, Then = {
					{ S = "Bruno", T = "¿La mano? Vale. Toma. Pero no se lo cuentes a nadie. Es broma. Cuéntaselo.", If = GANADO },
					{ S = "Bruno", T = "¿Me das la mano después de perder? Tú eres de otro planeta. Vale. Toma. Buen partido.", If = PERDIDO },
				} },
				{ T = "Celebrarlo (o consolaros) con tu equipo, todos juntos", Effects = { Traits = { Empatia = 1 }, Rel = { Omar = 3, Nico = 2, Sara = 2, Alex = 2 }, Choice = { TrasFinal = "Equipo" } }, Then = {
					{ S = "Omar", T = "¡Abrazo de grupo! ¡Todos! ¡Tú también, Andrés!" },
					{ S = "Andres", T = "…Venga, vale. Un abrazo rápido." },
				} },
				{ T = "Irte a un rincón sin hablar con nadie", Effects = { Traits = { Deportividad = -1 }, Choice = { TrasFinal = "Rincon" } }, Then = {
					{ S = "Narrador", T = "Te sientas en un rincón un rato. Omar se sienta a tu lado sin decir nada. A veces eso es lo que hace falta.", If = PERDIDO },
					{ S = "Narrador", T = "Te apartas un momento. Ha sido tanto que necesitas respirar. Omar te trae agua sin decir nada.", If = GANADO },
				} },
			} },
		} },

		Medallas = { Lines = {
			{ S = "Andres", T = "Y ahora… ¡las medallas! Primero, los subcampeones." },
			{ S = "Narrador", T = "Andrés te cuelga una medalla de ORO. Pesa más de lo que parece. O será la emoción.", If = GANADO },
			{ S = "Narrador", T = "Andrés te cuelga una medalla de PLATA. Brilla muchísimo. Más que muchas de oro.", If = PERDIDO },
			{ S = "Familia", T = "¡Mirad! ¡Es {nombre}! ¡Es de mi familia!" },
			{ S = "Abu", T = "(Abu no dice nada. Solo aplaude. Y se le escapa una lagrimilla.)" },
			{ S = "Andres", T = "Un último premio: el de deportividad del torneo. Es para… {nombre}. Por cómo has jugado. Y por cómo has tratado a todos.", If = { Traits = { Deportividad = 4 } } },
		} },
		Rumor = { Lines = {
			{ S = "Omar", T = "Oye… ¿habéis oído lo que dicen los de sexto?" },
			{ S = "Sara", T = "¿Lo de la puerta del fondo del pasillo? Esa que siempre está cerrada con un candado." },
			{ S = "Nico", T = "¡Dicen que dentro hay un fantasma! O un tesoro. O un fantasma con un tesoro." },
			{ S = "Sara", T = "Los fantasmas no existen. Los tesoros… a veces." },
		} },
	},
}
