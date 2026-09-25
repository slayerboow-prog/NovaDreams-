-- MISIÓN 03 · «EL GRUPO» (20-25 min)
-- Ficha de diseño completa: docs/historia/11-misiones-episodicas.md, apartado 11.9.
--
-- Ciencias → recreo: tres invitaciones (Nico, Omar, Sara) → tu actividad → el partido contra el
-- equipo de Bruno → banquillo → "¡al parque!" (con permiso de casa si lo pides) → el parque con tus
-- amigos siguiéndote → actividades → el banco: ¿qué quieres ser de mayor? → el gato del colegio →
-- el nombre del grupo y la foto.

local V = Vector3.new

local function seated(npc: string, index: number): { [string]: any }
	return { Npc = npc, Place = "PupitreA", Index = index, Offset = V(2.4, 0, 0), Mode = "Sit", Look = V(-1, 0, 0), Prompt = false }
end
local CLASE = {
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	seated("Iker", 1),
	seated("Sara", 2),
	seated("Omar", 5),
	seated("Hugo", 8),
	seated("Bruno", 9),
	seated("Ruben", 10),
	seated("Mateo", 12),
	seated("Nico", 13),
}
local MATEO_AMIGO = { Flags = { "AyudasteAMateo" } }

local INVITAN = {
	{ Npc = "Nico", Place = "CanchaColegio", Offset = V(-4, 0, 0) },
	{ Npc = "Omar", Place = "Patio", Offset = V(10, 0, -16) },
	{ Npc = "Sara", Place = "JuegosColegio", Offset = V(-3, 0, 4) },
}

-- El partido: tu equipo contra el de Bruno. Andrés arbitra.
local CAMPO = {
	{ Npc = "Andres", Place = "CampoColegio", Offset = V(0, 0, -20), Look = V(0, 0, 1) },
	{ Npc = "Nico", Place = "CampoColegio", Offset = V(-8, 0, -3), Look = V(1, 0, 0) },
	{ Npc = "Sara", Place = "CampoColegio", Offset = V(-14, 0, 6), Look = V(1, 0, 0) },
	{ Npc = "Omar", Place = "CampoColegio", Offset = V(-30, 0, 0), Look = V(1, 0, 0) },
	{ Npc = "Mateo", Place = "CampoColegio", Offset = V(-16, 0, -8), Look = V(1, 0, 0), If = MATEO_AMIGO },
	{ Npc = "Bruno", Place = "CampoColegio", Offset = V(8, 0, 2), Look = V(-1, 0, 0) },
	{ Npc = "Ruben", Place = "CampoColegio", Offset = V(12, 0, -6), Look = V(-1, 0, 0) },
	{ Npc = "Hugo", Place = "CampoColegio", Offset = V(14, 0, 8), Look = V(-1, 0, 0) },
	{ Npc = "Alex", Place = "CampoColegio", Offset = V(35, 0, 0), Look = V(-1, 0, 0) },
}

-- Tus amigos te siguen por la ciudad
local AMIGOS_SIGUEN = {
	{ Npc = "Nico", Mode = "Follow" },
	{ Npc = "Sara", Mode = "Follow" },
	{ Npc = "Omar", Mode = "Follow" },
	{ Npc = "Mateo", Mode = "Follow", If = MATEO_AMIGO },
}
local PARQUE = {
	{ Npc = "Nico", Place = "Parque", Offset = V(8, 0, 0) },
	{ Npc = "Sara", Place = "EstanqueParque", Offset = V(0, 0, 19) },
	{ Npc = "Omar", Place = "JuegosParque", Offset = V(3, 0, 6) },
	{ Npc = "Mateo", Place = "Parque", Offset = V(-6, 0, 6), If = MATEO_AMIGO },
}
local BANCO = {
	{ Npc = "Nico", Place = "Parque", Offset = V(-2, 0, -12) },
	{ Npc = "Sara", Place = "Parque", Offset = V(2, 0, -12) },
	{ Npc = "Omar", Place = "Parque", Offset = V(4, 0, -10) },
	{ Npc = "Mateo", Place = "Parque", Offset = V(-4, 0, -10), If = MATEO_AMIGO },
}

return {
	Id = "Cole03_Grupo",
	Kind = "Main",
	Title = "El grupo",
	Description = "Nico te quiere en su equipo, Omar en su mural y Sara en su expedición. Hoy nace algo importante.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 7, 7 },
	Duration = { 20, 25 },
	Difficulty = 2,
	Type = "Historia · Amistad",
	Requires = { Completed = { "Cole02_Mochila" }, StageProgress = 0.13 },
	Npcs = { "Lucia", "Nico", "Sara", "Omar", "Mateo", "Andres", "Bruno", "Ruben", "Hugo", "Alex", "Familia" },
	Locations = { "AulaA", "Patio", "JuegosColegio", "CanchaColegio", "CampoColegio", "CasaFamiliar", "Parque", "JuegosParque", "EstanqueParque" },
	Next = { "Nino_Recados" },
	Outcomes = { "Partido ganado, perdido o empatado", "Sueño de mayor", "Nombre del grupo", "Secundaria: el gato del colegio" },

	Moment = "Ya tienes tu grupo de amigos",
	Memory = "PrimerGrupo",
	Rewards = { Items = { FotoGrupo = 1 }, Rel = { Nico = 5, Sara = 5, Omar = 5 } },

	Props = {
		Mural1 = { Kind = "Mural", Name = "Mural: el cielo", Prompt = "Pintar", Place = "Patio", Offset = V(14, 0, -18), Look = V(0, 0, 1), Color = Color3.fromRGB(120, 190, 250), Dialogue = "Mural_Cielo", Once = true },
		Mural2 = { Kind = "Mural", Name = "Mural: el colegio", Prompt = "Pintar", Place = "Patio", Offset = V(20, 0, -18), Look = V(0, 0, 1), Color = Color3.fromRGB(240, 150, 110), Dialogue = "Mural_Colegio", Once = true },
		Mural3 = { Kind = "Mural", Name = "Mural: nosotros", Prompt = "Pintar", Place = "Patio", Offset = V(26, 0, -18), Look = V(0, 0, 1), Color = Color3.fromRGB(250, 230, 120), Dialogue = "Mural_Nosotros", Once = true },
		Escarabajo1 = { Kind = "Escarabajo", Name = "Escarabajo brillante", Prompt = "Observar", Place = "JuegosColegio", Offset = V(-6, 0, 6), Dialogue = "Bicho1", Once = true },
		Escarabajo2 = { Kind = "Escarabajo", Name = "Escarabajo brillante", Prompt = "Observar", Place = "CanchaColegio", Offset = V(24, 0, 12), Dialogue = "Bicho2", Once = true },
		Escarabajo3 = { Kind = "Escarabajo", Name = "Escarabajo brillante", Prompt = "Observar", Place = "Patio", Offset = V(-18, 0, -6), Dialogue = "Bicho3", Once = true },
		CanastaParque = { Kind = "Canasta", Name = "Canasta del parque", Prompt = "Tirar", Place = "Parque", Offset = V(12, 0, 2), Look = V(-1, 0, 0), Dialogue = "Parque_Canasta", Once = true },
		Columpio = { Kind = "Marcador", Name = "Columpios", Prompt = "Columpiarte", Place = "JuegosParque", Offset = V(5, 0, 2), Dialogue = "Parque_Columpio", Once = true },
		Estanque = { Kind = "Marcador", Name = "Estanque", Prompt = "Experimentar", Place = "EstanqueParque", Offset = V(0, 0, 17.5), Dialogue = "Parque_Estanque", Once = true },
		Kiosco = { Kind = "Kiosco", Name = "Quiosco de helados", Prompt = "Pedir helados", Place = "Parque", Offset = V(-12, 0, 4), Look = V(1, 0, 0), Dialogue = "Parque_Kiosco", Once = true },
		Banco = { Kind = "Banco", Name = "Banco", Prompt = "Sentarse", Place = "Parque", Offset = V(0, 0, -14) },
	},

	Steps = {
		{ Type = "Transition", Text = "Una semana después…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase", Actors = CLASE },
		{ Type = "Class", Subject = "Ciencias", Mode = "Clase", Place = "AulaA", Text = "Clase de Ciencias", Actors = CLASE },
		{ Type = "Scene", Dialogue = "Timbre", Actors = CLASE },

		-- Tres invitaciones
		{ Type = "Reach", Place = "Patio", Text = "Sal al recreo", Actors = INVITAN },
		{ Type = "Choice", Key = "Invitacion", Text = "Nico, Omar y Sara quieren que vayas con ellos. ¿Con quién vas?",
			Options = {
				{ Id = "Nico", Npc = "Nico", Text = "Nico: «¡Calienta, que hay partido!»", Dialogue = "Invita_Nico", Effects = { Rel = { Nico = 6 } } },
				{ Id = "Omar", Npc = "Omar", Text = "Omar: «¿Me ayudas con el mural?»", Dialogue = "Invita_Omar", Effects = { Rel = { Omar = 6 } } },
				{ Id = "Sara", Npc = "Sara", Text = "Sara: «¡He visto un escarabajo rarísimo!»", Dialogue = "Invita_Sara", Effects = { Rel = { Sara = 6 } } },
			},
			Actors = INVITAN },

		-- Con Nico: calentar tirando penaltis
		{ Type = "MiniGame", Game = "Timing", Title = "Calienta: tres penaltis", Icon = "🥅", Hint = "Chuta cuando la aguja esté en verde",
			Rounds = 3, Need = 2, Zone = 0.25, Speed = 1, If = { Choices = { Invitacion = "Nico" } },
			Win = { Rel = { Nico = 4 }, Traits = { Deportividad = 1 } }, Lose = { Rel = { Nico = 2 } },
			Actors = { { Npc = "Nico", Place = "CanchaColegio", Offset = V(-4, 0, 0) } } },
		-- Con Omar: pintar el mural
		{ Type = "Group", Text = "Pinta el mural con Omar", If = { Choices = { Invitacion = "Omar" } },
			Steps = {
				{ Type = "Use", Prop = "Mural1", Text = "El cielo" },
				{ Type = "Use", Prop = "Mural2", Text = "El colegio" },
				{ Type = "Use", Prop = "Mural3", Text = "Nosotros" },
			},
			Effects = { Traits = { Creatividad = 2 }, Rel = { Omar = 6 } },
			Actors = { { Npc = "Omar", Place = "Patio", Offset = V(18, 0, -15) } } },
		-- Con Sara: seguir al escarabajo
		{ Type = "Use", Prop = "Escarabajo1", Text = "Sigue al escarabajo (zona de juegos)", If = { Choices = { Invitacion = "Sara" } },
			Actors = { { Npc = "Sara", Mode = "Follow" } } },
		{ Type = "Use", Prop = "Escarabajo2", Text = "¡Se ha ido volando hacia la cancha!", If = { Choices = { Invitacion = "Sara" } },
			Actors = { { Npc = "Sara", Mode = "Follow" } } },
		{ Type = "Use", Prop = "Escarabajo3", Text = "¡Ahora está junto al edificio!", If = { Choices = { Invitacion = "Sara" } },
			Actors = { { Npc = "Sara", Mode = "Follow" } }, Effects = { Traits = { Curiosidad = 2 }, Rel = { Sara = 6 } } },

		-- Todo acaba en el partido
		{ Type = "Scene", Dialogue = "FaltanJugadores", Actors = { { Npc = "Nico", Mode = "Follow" }, { Npc = "Sara", Mode = "Follow" }, { Npc = "Omar", Mode = "Follow" } } },
		{ Type = "Reach", Place = "CampoColegio", Text = "Ve al campo de fútbol", Actors = CAMPO },
		{ Type = "Scene", Dialogue = "PrePartido", Actors = CAMPO },
		{ Type = "MiniGame", Game = "Futbol", Title = "¡Partido contra el equipo de Bruno!", Icon = "⚽", Plays = 6, Rival = "el equipo de Bruno",
			PositionFrom = "Posicion",
			Win = { Flags = { "PartidoGanado" }, Rel = { Nico = 5, Sara = 3, Omar = 3, Bruno = -3 }, Memory = "PrimerPartido", Items = { CuadernoOmar = 1 } },
			Lose = { Flags = { "PartidoPerdido" }, Rel = { Nico = 3, Sara = 3, Omar = 3 }, Memory = "PrimerPartido", Items = { CuadernoOmar = 1 } },
			Draw = { Flags = { "PartidoEmpate" } },
			Actors = CAMPO },
		{ Type = "Scene", Dialogue = "Banquillo", Actors = CAMPO },

		-- Por la tarde, al parque
		{ Type = "Transition", Text = "Por la tarde…", Seconds = 3 },
		{ Type = "Reach", Place = "CasaFamiliar", Text = "Pide permiso en casa", If = { Choices = { Permiso = "Casa" } } },
		{ Type = "Talk", Npc = "Familia", Dialogue = "Permiso", Text = "Habla con {familia}", If = { Choices = { Permiso = "Casa" } },
			Actors = { { Npc = "Familia", Place = "HomeSalon", Offset = V(0, 0, -2) } } },
		{ Type = "Scene", Dialogue = "Quedada", Teleport = { Place = "CasaFamiliar", Offset = V(0, 0, -18) }, Actors = AMIGOS_SIGUEN },
		{ Type = "Reach", Place = "Parque", Text = "Ve al parque con tus amigos (te siguen)", Actors = AMIGOS_SIGUEN },
		{ Type = "Group", Text = "Pasa la tarde en el parque", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "CanastaParque", Text = "Tirar a canasta con Nico" },
				{ Type = "Use", Prop = "Columpio", Text = "Columpios con Omar" },
				{ Type = "Use", Prop = "Estanque", Text = "Experimento con Sara en el estanque" },
				{ Type = "Use", Prop = "Kiosco", Text = "Helados en el quiosco" },
			},
			Actors = PARQUE },
		{ Type = "Use", Prop = "Banco", Text = "Sentaos en el banco", Actors = BANCO },
		{ Type = "Scene", Dialogue = "Suenos", Actors = BANCO, Props = { "Banco" } },
		{ Type = "Scene", Dialogue = "ElGato", Actors = BANCO, Props = { "Banco" } },
		{ Type = "Scene", Dialogue = "NombreGrupo", Actors = BANCO, Props = { "Banco" } },
		{ Type = "Cinematic", Id = "Cole03_Foto", Actors = BANCO, Props = { "Banco" } },
	},

	Dialogues = {
		Timbre = { Lines = {
			{ S = "Lucia", T = "Y por eso las plantas giran hacia el sol. ¡Recreo! Y Nico: el balón NO se lanza dentro del aula." },
			{ S = "Nico", T = "¡Si todavía no lo he sacado!" },
		} },

		Invita_Nico = { Lines = {
			{ S = "Nico", T = "¡Por fin! Hoy jugamos contra los de Bruno. Me falta gente buena. Y tú eres gente buena." },
			{ S = "Nico", T = "Pero antes, calentamiento. Tres penaltis. Si metes dos, eres titular." },
			{ S = "Nico", T = "¡Y encima te gusta el fútbol! Lo dijiste el primer día. Me acuerdo de TODO.", If = { Choices = { Gusto = "Futbol" } } },
		} },
		Invita_Omar = { Lines = {
			{ S = "Omar", T = "Lucía me deja pintar esta parte de la valla. Tres trozos: el cielo, el colegio y… nosotros." },
			{ S = "Omar", T = "Yo dibujo las líneas y tú rellenas. Es un trabajo en equipo. Y luego merendamos. Tengo hambre." },
		} },
		Invita_Sara = { Lines = {
			{ S = "Sara", T = "¡Rápido! ¡Un escarabajo VERDE BRILLANTE! No sale en mi libro de insectos. ¡Puede ser una especie nueva!" },
			{ S = "Sara", T = "Si lo descubrimos nosotros, le ponemos nuestro nombre. «Escarabajus Sara-y-{nombre}»." },
		} },

		Mural_Cielo = { Lines = {
			{ S = "Omar", T = "El cielo. Azul, pero no un azul cualquiera: azul de «hoy no hay deberes»." },
			{ Ask = "¿Qué le añades?", Options = {
				{ T = "Un sol con gafas de sol", Effects = { Traits = { Humor = 1 } }, Then = { { S = "Omar", T = "Genial. Un sol que se protege del sol." } } },
				{ T = "Un cohete", Effects = { Traits = { Curiosidad = 1 } }, Then = { { S = "Omar", T = "Rumbo a Marte. Sara lo va a aprobar." } } },
			} },
		} },
		Mural_Colegio = { Lines = {
			{ S = "Omar", T = "El colegio. Con Ramón en la puerta, que si no, no es nuestro colegio." },
			{ S = "Narrador", T = "Pintas a Ramón con su manojo gigante de llaves. Le sale una sonrisa enorme." },
		} },
		Mural_Nosotros = { Lines = {
			{ S = "Omar", T = "Y aquí… nosotros. Tú, yo, y los que vengan. Dejo sitio. Siempre hay que dejar sitio." },
			{ S = "Omar", T = "¿Sabes? No suelo dejar pintar a nadie en mis dibujos. Contigo es distinto." },
		}, Effects = { Rel = { Omar = 4 } } },

		Bicho1 = { Lines = {
			{ S = "Sara", T = "¡Ahí! No respires. Seis patas, caparazón verde… ¡y brilla! ¡BRILLA!" },
			{ S = "Narrador", T = "El escarabajo abre las alas y sale volando hacia la cancha." },
			{ S = "Sara", T = "¡Síguelo! ¡La ciencia no espera!" },
		} },
		Bicho2 = { Lines = {
			{ S = "Sara", T = "Se ha posado aquí. Fíjate: cuando le da el sol, cambia de color. ¡Es iridiscente!" },
			{ Ask = "¿Qué dices?", Options = {
				{ T = "¿Iri-qué?", Effects = { Traits = { Humor = 1 } }, Then = { { S = "Sara", T = "Iridiscente. Como las pompas de jabón. Te lo apunto." } } },
				{ T = "Como las pompas de jabón, ¿no?", Effects = { Traits = { Curiosidad = 1 }, Rel = { Sara = 3 } }, Then = { { S = "Sara", T = "¡EXACTO! ¡Por fin alguien de mi nivel!" } } },
			} },
		} },
		Bicho3 = { Lines = {
			{ S = "Narrador", T = "El escarabajo se queda quieto en la pared. Sara saca su cuaderno y lo dibuja con muchísimo cuidado." },
			{ S = "Sara", T = "Registro científico número uno. Descubridores: Sara y {nombre}. Fecha: hoy." },
			{ S = "Sara", T = "Oye… ha sido el mejor recreo de mi vida." },
		} },

		FaltanJugadores = { Lines = {
			{ S = "Nico", T = "¡EH! ¡Vosotros! ¡Nos faltan jugadores! Bruno dice que si no somos cinco, perdemos sin jugar." },
			{ S = "Omar", T = "Yo no sé jugar. Pero puedo ponerme de portero y no moverme. Soy muy bueno no moviéndome." },
			{ S = "Sara", T = "Estadísticamente, con cinco jugadores nuestras probabilidades suben un… bueno, suben. ¡Vamos!" },
			{ S = "Mateo", T = "¿Yo… también puedo jugar?", If = MATEO_AMIGO },
			{ S = "Nico", T = "¡Claro que sí, Mateo! ¡Cuantos más, mejor!", If = MATEO_AMIGO },
		} },

		PrePartido = { Lines = {
			{ S = "Andres", T = "¡Bien! Partido amistoso. A-MIS-TO-SO. Sin empujones, sin trampas y dando la mano al final. ¿Entendido?" },
			{ S = "Bruno", T = "Mirad quién viene. Quien se chiva a los profes.", If = { Flags = { "AvisasteALucia" } } },
			{ S = "Ruben", T = "(Rubén te guiña un ojo) Suerte. Pero no mucha, ¿eh?", If = { Flags = { "Ruben_Perdonado" } } },
			{ S = "Ruben", T = "Hoy me toca ganar a mí. Por lo de la gorra.", If = { Flags = { "BromaDeVuelta" } } },
			{ S = "Bruno", T = "Esto va a ser muy fácil. Cinco minutos y os vais llorando." },
			{ S = "Hugo", T = "…Bruno, que es solo un partido." },
			{ S = "Nico", T = "¿Dónde juegas?" },
			{ Ask = "Elige tu posición", Options = {
				{ T = "Delante: ¡a marcar goles!", Effects = { Choice = { Posicion = "Delantero" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Nico", T = "¡Dúo de ataque! Tú y yo. Que tiemble Álex." },
				} },
				{ T = "Defensa: que no pase nadie.", Effects = { Choice = { Posicion = "Defensa" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Sara", T = "Un muro humano. Sólido. Me gusta." },
				} },
				{ T = "Portería: que Omar descanse.", Effects = { Choice = { Posicion = "Portero" }, Rel = { Omar = 4 } }, Then = {
					{ S = "Omar", T = "¡Gracias! Yo defiendo el bocadillo del banquillo." },
				} },
			} },
			{ S = "Andres", T = "¡Preparados…! ¡PRRRRIII!" },
		} },

		Banquillo = { Lines = {
			{ S = "Andres", T = "¡Final! Y ahora, todos a dar la mano. Todos, Bruno." },
			{ S = "Nico", T = "¡HEMOS GANADO! ¡HEMOS GANADO A BRUNO! ¡Esto hay que contárselo a mis nietos!", If = { Flags = { "PartidoGanado" } } },
			{ S = "Nico", T = "Empate. Bueno. Un empate contra Bruno es como ganar. Casi.", If = { Flags = { "PartidoEmpate" } } },
			{ S = "Nico", T = "Hemos perdido… Pero ¿habéis visto esa jugada? La próxima vez, les ganamos.", If = { Flags = { "PartidoPerdido" } } },
			{ S = "Sara", T = "He contado los pases: veintitrés. Somos un equipo con futuro. Los datos no mienten." },
			{ S = "Omar", T = "Lo he dibujado todo. Toma, este es para ti. Sales tú marcando. Más o menos así fue." },
			{ S = "Mateo", T = "Yo… he tocado el balón dos veces. Dos. Es mi récord.", If = MATEO_AMIGO },
			{ S = "Hugo", T = "(Hugo pasa a tu lado y habla muy bajito) Buen partido. En serio." },
			{ Ask = "¿Qué dices al grupo?", Options = {
				{ T = "¡Somos un equipazo!", Effects = { Traits = { Deportividad = 1 }, Rel = { Nico = 3, Sara = 3, Omar = 3 } } },
				{ T = "Omar, casi te comes el bocadillo en plena jugada.", Effects = { Traits = { Humor = 1 }, Rel = { Omar = 4 } }, Then = {
					{ S = "Omar", T = "Estaba defendiéndolo. Es distinto." },
				} },
				{ T = "Lo mejor ha sido jugar juntos.", Effects = { Traits = { Empatia = 1 }, Rel = { Nico = 3, Sara = 3, Omar = 3, Mateo = 3 } } },
			} },
			{ S = "Nico", T = "Oye… ¿y si después de clase vamos todos al parque? Hay canasta, columpios, y un quiosco de helados." },
			{ Ask = "¿Vas?", Options = {
				{ T = "¡Sí! ¡Nos vemos allí!", Effects = { Choice = { Permiso = "Directo" } } },
				{ T = "Primero pido permiso en casa.", Effects = { Choice = { Permiso = "Casa" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Sara", T = "Muy responsable. Te esperamos en la puerta de tu casa." },
				} },
			} },
		} },

		Permiso = { Lines = {
			{ S = "Yo", T = "¿Puedo ir al parque con mis amigos? ¡Porfa! Volvemos antes de cenar." },
			{ S = "Familia", T = "¿Amigos? ¿Ya tienes amigos? ¡Eso es maravilloso!" },
			{ S = "Familia", T = "Claro que sí. Antes de cenar. Y nada de subirse a los árboles." },
		}, Effects = { Rel = { Familia = 3 } } },

		Quedada = { Lines = {
			{ S = "Nico", T = "¡Estamos todos! ¡Al parque!" },
			{ S = "Omar", T = "Yo me he traído merienda. Por si acaso. Siempre por si acaso." },
			{ S = "Narrador", T = "Tus amigos te siguen. Guíales hasta el parque." },
		} },

		Parque_Canasta = { Lines = {
			{ S = "Nico", T = "Reto: el que meta desde más lejos, elige el helado de todos." },
			{ Ask = "¿Cómo tiras?", Options = {
				{ T = "Tiro lejano. A lo grande.", Effects = { Traits = { Valentia = 1 } }, Then = {
					{ S = "Narrador", T = "El balón vuela… rebota en el aro… ¡y entra! Nico se tira al suelo de la emoción." },
				} },
				{ T = "Bandeja, sin arriesgar.", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Narrador", T = "Canasta segura. Nico falla la suya a propósito para que ganes. Luego lo niega." },
				} },
			} },
		}, Effects = { Rel = { Nico = 4 } } },
		Parque_Columpio = { Lines = {
			{ S = "Omar", T = "Cuando te columpias muy alto, las nubes parecen dibujos. Esa es un dragón comiéndose un bocadillo." },
			{ S = "Yo", T = "Tú ves bocadillos en todas partes." },
			{ S = "Omar", T = "Y tú, cuando te conozca más, también." },
		}, Effects = { Rel = { Omar = 4 } } },
		Parque_Estanque = { Lines = {
			{ S = "Sara", T = "Experimento: ¿qué flota? Tenemos una hoja, una piedrecita y una piña." },
			{ Ask = "¿Qué flotará?", Options = {
				{ T = "La hoja y la piña", Effects = { Traits = { Curiosidad = 1 }, Rel = { Sara = 4 } }, Then = {
					{ S = "Sara", T = "¡Correcto! La piña tiene aire dentro. Serías una científica o un científico estupendo." },
				} },
				{ T = "La piedra, que es muy valiente", Effects = { Traits = { Humor = 1 }, Rel = { Sara = 2 } }, Then = {
					{ S = "Narrador", T = "¡PLOP! La piedra se hunde. Sara se ríe tanto que casi se cae al estanque." },
				} },
			} },
		} },
		Parque_Kiosco = { Lines = {
			{ S = "Narrador", T = "El quiosquero os mira por encima de las gafas. Helados a 2 $." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "¡Invito yo a todos! (8 $)", Effects = { Spend = 8, Rel = { Nico = 3, Sara = 3, Omar = 3, Mateo = 3 }, Items = { Helado = 1 } }, Then = {
					{ S = "Omar", T = "Eres la mejor persona que conozco. Después de mi abuela.", If = { NotFlags = { "SinDinero" } } },
					{ S = "Mateo", T = "No te llega… Yo tengo mi paga. Invito yo. Nunca había invitado a nadie.", If = { Flags = { "SinDinero" } } },
				} },
				{ T = "Uno para mí (2 $)", Effects = { Spend = 2, Items = { Helado = 1 } }, Then = {
					{ S = "Omar", T = "¿Me das un chupito? Solo la puntita.", If = { NotFlags = { "SinDinero" } } },
					{ S = "Narrador", T = "No te llega el dinero. Omar comparte el suyo contigo sin decir nada.", If = { Flags = { "SinDinero" } } },
				} },
			} },
		} },

		Suenos = { Lines = {
			{ S = "Narrador", T = "El sol empieza a bajar. Os sentáis todos apretados en el banco." },
			{ S = "Sara", T = "Pregunta importante. ¿Qué queréis ser de mayores?" },
			{ S = "Nico", T = "Futbolista. Obvio. En la selección. Y luego entrenador. Y luego presidente del club." },
			{ S = "Omar", T = "Dibujante de cómics. De los que salen en las tiendas. Con mi nombre en la portada." },
			{ S = "Sara", T = "Yo, astronauta. O científica. O las dos: científica en el espacio." },
			{ S = "Mateo", T = "Yo… veterinario. Para cuidar animales que nadie quiere.", If = MATEO_AMIGO },
			{ S = "Sara", T = "¿Y tú, {nombre}?" },
			{ Ask = "¿Qué quieres ser de mayor?", Options = {
				{ T = "Salvar vidas en un hospital", Effects = { Choice = { SuenoInfancia = "Medicina" }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Mateo", T = "Tú curas a las personas y yo a los animales. Somos un equipo.", If = MATEO_AMIGO },
				} },
				{ T = "Inventar cosas que no existen", Effects = { Choice = { SuenoInfancia = "Ingenieria" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Sara", T = "¡Me haces un cohete y yo lo piloto!" },
				} },
				{ T = "Defender a la gente en los juzgados", Effects = { Choice = { SuenoInfancia = "Derecho" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Nico", T = "Pues ya puedes empezar defendiéndome de los deberes." },
				} },
				{ T = "Tener mi propia tienda o empresa", Effects = { Choice = { SuenoInfancia = "Economia" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Omar", T = "Que sea una tienda de bocadillos. Te hago el cartel." },
				} },
				{ T = "Ser artista", Effects = { Choice = { SuenoInfancia = "Arte" }, Traits = { Creatividad = 1 } }, Then = {
					{ S = "Omar", T = "¡Lo sabía! Haremos un cómic juntos." },
				} },
				{ T = "Deportista profesional", Effects = { Choice = { SuenoInfancia = "Deporte" }, Traits = { Deportividad = 1 } }, Then = {
					{ S = "Nico", T = "¡En mi equipo! ¡Fichado!" },
				} },
			} },
			{ S = "Narrador", T = "Nadie lo sabe todavía, pero este momento volverá a tu memoria muchos años después." },
		}, Effects = { Memory = { "SuenoDeMayor", "TardeEnElParque" } } },

		ElGato = { Lines = {
			{ S = "Omar", T = "Por cierto… ¿sabéis que en el cole vive un gato? Naranja. Duerme detrás del gimnasio." },
			{ S = "Sara", T = "Nadie sabe de quién es. Ramón le deja agua, pero dice que no es suyo." },
			{ S = "Omar", T = "Esta semana no le he visto. Y a lo mejor tiene hambre. ¿Me ayudáis a buscarlo?" },
			{ Ask = "¿Buscaréis al gato?", Options = {
				{ T = "¡Claro! Mañana lo buscamos.", Effects = { Rel = { Omar = 4 }, Traits = { Empatia = 1 }, Later = { { AfterMinutes = 3, Start = "Side_GatoDelCole" } } }, Then = {
					{ S = "Omar", T = "Sabía que dirías que sí. Le llamo Bigotes. En secreto." },
				} },
				{ T = "Seguro que está bien, los gatos saben cuidarse.", Then = {
					{ S = "Omar", T = "Ya… seguramente." },
				} },
			} },
		} },

		NombreGrupo = { Lines = {
			{ S = "Nico", T = "Oye. Ahora somos un grupo, ¿no? Los grupos tienen nombre. Es la ley." },
			{ Ask = "¿Cómo os llamáis?", Options = {
				{ T = "Los Imparables", Effects = { Choice = { NombreGrupo = "Los Imparables" } } },
				{ T = "La Patrulla Valmar", Effects = { Choice = { NombreGrupo = "La Patrulla Valmar" } } },
				{ T = "Los del Banco Azul", Effects = { Choice = { NombreGrupo = "Los del Banco Azul" } } },
				{ T = "Los Dinosaurios", If = { Choices = { Ropa = "Dinosaurios" } }, Effects = { Choice = { NombreGrupo = "Los Dinosaurios" } } },
			} },
			{ S = "Nico", T = "¡{grupo}! ¡Me encanta! ¡Grito de guerra!" },
			{ S = "Omar", T = "Foto. Tenemos que hacernos una foto. Para dibujarla luego." },
			{ S = "Sara", T = "Todos juntos. Tres, dos, uno…" },
		} },
	},
}
