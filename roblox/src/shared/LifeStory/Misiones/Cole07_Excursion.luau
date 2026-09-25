-- MISIÓN 07 · «LA EXCURSIÓN» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.17.
--
-- Autobús (con quién te sientas) → viaje → la Granja escuela de Villaverde (escena aérea) → Paula
-- presenta la granja → actividades → ¡falta Mateo! (u Omar, si Mateo no es tu amigo) → pistas →
-- le encuentras siguiendo a un corderito → vuelta al autobús → foto de la clase.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local SIN_MATEO = { NotFlags = { "AyudasteAMateo" } }

-- En el autobús (antes de salir): cada uno en su asiento, esperando a ver quién se sienta a su lado
local AUTOBUS = {
	{ Npc = "Lucia", Place = "AutobusCole", Offset = V(-4, 0, 0) },
	{ Npc = "Nico", Place = "AutobusCole", Offset = V(2, 0, 2) },
	{ Npc = "Sara", Place = "AutobusCole", Offset = V(4, 0, -1) },
	{ Npc = "Omar", Place = "AutobusCole", Offset = V(6, 0, 2) },
	{ Npc = "Mateo", Place = "AutobusCole", Offset = V(0, 0, -3), If = AMIGO_MATEO },
	{ Npc = "Hugo", Place = "AutobusCole", Offset = V(-2, 0, 3), If = { Flags = { "HugoConElGrupo" } } },
	{ Npc = "Bruno", Place = "AutobusCole", Offset = V(8, 0, -2), Bark = "¡Yo me pido la última fila!" },
}

local GRANJA = {
	{ Npc = "Paula", Place = "Granja", Offset = V(0, 0, 6) },
	{ Npc = "Lucia", Place = "Granja", Offset = V(-4, 0, 8) },
	{ Npc = "Nico", Place = "Granja", Offset = V(4, 0, 9) },
	{ Npc = "Sara", Place = "Granja", Offset = V(6, 0, 7) },
	{ Npc = "Omar", Place = "Granja", Offset = V(2, 0, 11) },
	{ Npc = "Mateo", Place = "Granja", Offset = V(-2, 0, 11), If = AMIGO_MATEO },
	{ Npc = "Bruno", Place = "Granja", Offset = V(-8, 0, 10), Bark = "Huele a vaca. Me encanta. No se lo digáis a nadie." },
}
-- Durante la búsqueda: el perdido no está con el grupo
local BUSQUEDA = {
	{ Npc = "Paula", Place = "Granja", Offset = V(0, 0, 6) },
	{ Npc = "Lucia", Place = "Granja", Offset = V(-4, 0, 8) },
	{ Npc = "Julian", Place = "GranjaSilo", Offset = V(6, 0, 4) },
	{ Npc = "Nico", Mode = "Follow" },
	{ Npc = "Sara", Mode = "Follow" },
	{ Npc = "Omar", Mode = "Follow", If = AMIGO_MATEO },
}
local PERDIDO_MATEO = { Npc = "Mateo", Place = "GranjaGranero", Offset = V(-14, 0, 10), If = AMIGO_MATEO }
local PERDIDO_OMAR = { Npc = "Omar", Place = "GranjaGranero", Offset = V(-14, 0, 10), If = SIN_MATEO }

return {
	Id = "Cole07_Excursion",
	Kind = "Main",
	Title = "La excursión",
	Description = "¡Excursión a la Granja escuela de Villaverde! Autobús, animales, campo… y un susto.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 9, 9 },
	Duration = { 25, 35 },
	Difficulty = 2,
	Type = "Historia · Episodio especial",
	Requires = { Completed = { "Nino_Recados" }, StageProgress = 0.44 },
	Npcs = { "Lucia", "Paula", "Julian", "Nico", "Sara", "Omar", "Mateo", "Hugo", "Bruno" },
	Locations = { "AutobusCole", "Granja", "GranjaGranero", "GranjaSilo" },
	Next = { "Cole08_Torneo" },
	Outcomes = { "Te sientas con…", "Encuentras a Mateo (u Omar)", "Avisas a Lucía o le traes tú" },

	Moment = "La excursión a la granja",
	Memory = "PrimeraExcursion",
	Rewards = { Items = { FotoExcursion = 1 } },

	Props = {
		Gallinas = { Kind = "Animal", Name = "Las gallinas", Prompt = "Dar de comer", Place = "GranjaGranero", Offset = V(10, 0, 10), Color = Color3.fromRGB(250, 240, 220), Dialogue = "Act_Gallinas", Once = true },
		Huerto = { Kind = "Marcador", Name = "El huerto", Prompt = "Coger zanahorias", Place = "Granja", Offset = V(14, 0, -4), Dialogue = "Act_Huerto", Once = true },
		Caballos = { Kind = "Animal", Name = "Los caballos", Prompt = "Acariciar", Place = "Granja", Offset = V(-14, 0, -6), Color = Color3.fromRGB(130, 80, 40), Dialogue = "Act_Caballos", Once = true },
		Tractor = { Kind = "Caja", Name = "El tractor", Prompt = "Subirte", Place = "GranjaSilo", Offset = V(-6, 0, 6), Color = Color3.fromRGB(200, 40, 40), Dialogue = "Act_Tractor", Once = true },
		PistaMochila = { Kind = "Mochila", Name = "Una mochila en la hierba", Prompt = "Examinar", Place = "Granja", Offset = V(-10, 0, 14), Color = Color3.fromRGB(90, 90, 200), Dialogue = "Pista_Mochila", Once = true },
		PistaBotella = { Kind = "Marcador", Name = "Una botella de agua", Prompt = "Examinar", Place = "GranjaSilo", Offset = V(-8, 0, -4), Dialogue = "Pista_Botella", Once = true },
		PistaMapa = { Kind = "Papel", Name = "Un mapa dibujado", Prompt = "Examinar", Place = "GranjaGranero", Offset = V(-8, 0, 4), Dialogue = "Pista_Mapa", Once = true },
		Corderito = { Kind = "Animal", Name = "Un corderito", Prompt = false, Place = "GranjaGranero", Offset = V(-12, 0, 12), Color = Color3.fromRGB(245, 245, 245) },
	},

	Steps = {
		{ Type = "Transition", Text = "Semanas después, un día muy esperado…", Seconds = 3 },
		{ Type = "Reach", Place = "AutobusCole", Text = "Ve al autobús de la excursión (en la puerta del cole)", Actors = AUTOBUS },
		{ Type = "Scene", Dialogue = "Salida", Actors = AUTOBUS },
		{ Type = "Choice", Key = "AsientoBus", Text = "¿Con quién te sientas en el autobús? (habla con quien elijas)",
			Options = {
				{ Id = "Nico", Npc = "Nico", Text = "Con Nico", Dialogue = "Bus_Nico", Effects = { Rel = { Nico = 5 } } },
				{ Id = "Sara", Npc = "Sara", Text = "Con Sara", Dialogue = "Bus_Sara", Effects = { Rel = { Sara = 5 } } },
				{ Id = "Omar", Npc = "Omar", Text = "Con Omar", Dialogue = "Bus_Omar", Effects = { Rel = { Omar = 5 } } },
				{ Id = "Mateo", Npc = "Mateo", Text = "Con Mateo", Dialogue = "Bus_Mateo", Effects = { Rel = { Mateo = 5 } } },
				{ Id = "Hugo", Npc = "Hugo", Text = "Con Hugo", Dialogue = "Bus_Hugo", Effects = { Rel = { Hugo = 6 } } },
			},
			Actors = AUTOBUS },
		{ Type = "Scene", Dialogue = "Viaje", Actors = AUTOBUS },
		{ Type = "Cinematic", Id = "Cole07_Viaje", Effects = { Teleport = "Granja" } },

		-- La granja
		{ Type = "Scene", Dialogue = "Llegada", Teleport = "Granja", Actors = GRANJA },
		{ Type = "Group", Text = "Descubre la granja", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "Gallinas", Text = "Dar de comer a las gallinas" },
				{ Type = "Use", Prop = "Huerto", Text = "Coger zanahorias en el huerto" },
				{ Type = "Use", Prop = "Caballos", Text = "Acariciar a los caballos" },
				{ Type = "Use", Prop = "Tractor", Text = "Subirte al tractor" },
			},
			Actors = GRANJA },
		{ Type = "MiniGame", Game = "Timing", Title = "Echa el grano a las gallinas", Icon = "🐔", Hint = "Suelta el grano cuando la aguja esté en verde",
			Rounds = 5, Need = 3, Zone = 0.26, Speed = 1, Win = { Traits = { Responsabilidad = 1 } }, Lose = { Traits = { Humor = 1 } },
			Actors = GRANJA },

		-- ¡Falta alguien!
		{ Type = "Scene", Dialogue = "Falta", Actors = BUSQUEDA },
		{ Type = "Group", Text = "Busca pistas por la granja", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "PistaMochila", Text = "Una mochila en la hierba" },
				{ Type = "Use", Prop = "PistaBotella", Text = "Una botella junto al silo" },
				{ Type = "Use", Prop = "PistaMapa", Text = "Un papel junto al granero" },
				{ Type = "Talk", Npc = "Julian", Dialogue = "Julian", Text = "Pregunta a Julián, el granjero (junto al silo)" },
			},
			Actors = BUSQUEDA },
		{ Type = "Reach", Place = "GranjaGranero", Text = "Busca detrás del granero",
			Actors = { BUSQUEDA[1], BUSQUEDA[2], BUSQUEDA[4], BUSQUEDA[5], PERDIDO_MATEO, PERDIDO_OMAR }, Props = { "Corderito" } },
		{ Type = "Scene", Dialogue = "Encontrado", Actors = { PERDIDO_MATEO, PERDIDO_OMAR, BUSQUEDA[4], BUSQUEDA[5] }, Props = { "Corderito" } },

		-- Vuelta y foto
		{ Type = "Scene", Dialogue = "Reunion", Actors = GRANJA },
		{ Type = "Cinematic", Id = "Cole07_Foto", Actors = GRANJA },
		{ Type = "Scene", Dialogue = "Vuelta", Actors = GRANJA, Effects = { Teleport = "AutobusCole" } },
	},

	Dialogues = {
		Salida = { Lines = {
			{ S = "Lucia", T = "¡Todos arriba! Contad cuántos sois en vuestra fila. Y nadie se deja nada en el autobús, ¿de acuerdo?" },
			{ S = "Nico", T = "¡{nombre}! ¡Aquí hay sitio!" },
			{ S = "Sara", T = "Yo tengo la ventana. Puedo compartir la ventana. A ratos." },
			{ S = "Narrador", T = "Busca con quién sentarte." },
		} },
		Bus_Nico = { Lines = {
			{ S = "Nico", T = "¡Bien! Tengo un juego: el que vea más vacas gana. Yo llevo… una. Esa. ¡Dos!" },
		} },
		Bus_Sara = { Lines = {
			{ S = "Sara", T = "He traído una lista de todas las plantas que vamos a ver. Y una lupa. Bueno, la tuya no, la mía." },
		} },
		Bus_Omar = { Lines = {
			{ S = "Omar", T = "Te guardé el sitio. Y te guardé medio bocadillo. Bueno… un cuarto. Tenía hambre." },
		} },
		Bus_Mateo = { Lines = {
			{ S = "Mateo", T = "Nunca he ido de excursión. En mi otro cole no íbamos. Estoy… contento. Y un poco nervioso." },
		} },
		Bus_Hugo = { Lines = {
			{ S = "Hugo", T = "¿Conmigo? Antes siempre me sentaba donde decía Bruno. Esto está mejor. Mira, te leo un trozo del libro." },
		} },
		Viaje = { Lines = {
			{ S = "Narrador", T = "El autobús sale de Valmar. Carreteras, campos, un tractor que os adelanta (¡os adelanta un tractor!)." },
			{ S = "Omar", T = "Ya me he comido el bocadillo. Estamos en el primer kilómetro." },
			{ S = "Sara", T = "Técnicamente, en el kilómetro cero coma ocho." },
			{ S = "Nico", T = "¡VACA! ¡Siete! ¡Voy ganando!", If = { Choices = { AsientoBus = "Nico" } } },
			{ S = "Mateo", T = "(Mateo pega la nariz a la ventana. No dice nada. Pero sonríe todo el rato.)", If = { Choices = { AsientoBus = "Mateo" } } },
			{ S = "Lucia", T = "¡Ya llegamos! Villaverde, la Granja escuela. Recordad: los animales no son juguetes." },
		} },
		Llegada = { Lines = {
			{ S = "Paula", T = "¡Bienvenidos a la Granja escuela! Soy Paula. Aquí tenemos gallinas, caballos, un huerto, un tractor…" },
			{ S = "Paula", T = "…y una norma de oro: nadie se separa del grupo. El campo es muy grande y todo se parece." },
			{ S = "Paula", T = "Podéis ir a ver lo que queráis de la granja, pero siempre a la vista. ¡Adelante!" },
			{ S = "Bruno", T = "Huele a caca de vaca." },
			{ S = "Paula", T = "Huele a campo, jovencito. Y son caballos." },
		} },
		Act_Gallinas = { Lines = {
			{ S = "Paula", T = "Estas son Clotilde, Petra y la Señora Bigotes. No, no tiene bigotes. Se lo pusimos por fastidiar." },
			{ S = "Paula", T = "Toma grano. Échalo cerca, no encima. Las gallinas son muy educadas si tú lo eres." },
		} },
		Act_Huerto = { Lines = {
			{ S = "Narrador", T = "Tiras de una hoja verde… y sale una zanahoria ENORME. Toda la clase aplaude." },
			{ S = "Sara", T = "Técnicamente, es una raíz. Pero es una raíz impresionante." },
		}, Effects = { Traits = { Curiosidad = 1 } } },
		Act_Caballos = { Lines = {
			{ S = "Narrador", T = "El caballo te mira con sus ojos grandes y te sopla en la mano. Hace cosquillas." },
			{ S = "Omar", T = "Lo voy a dibujar. Tiene cara de llamarse Galleta." },
		}, Effects = { Traits = { Empatia = 1 } } },
		Act_Tractor = { Lines = {
			{ S = "Julian", T = "¿Quieres subir? Venga, arriba. Las manos en el volante. ¡Brrrrum! Sin arrancar, ¿eh?" },
			{ S = "Nico", T = "¡Hazme una foto! ¡Hazme una foto!" },
		}, Effects = { Rel = { Julian = 3 } } },

		Falta = { Lines = {
			{ S = "Lucia", T = "A ver… ¿estamos todos? Uno, dos, tres…" },
			{ S = "Lucia", T = "Falta Mateo. ¿Alguien ha visto a Mateo?", If = AMIGO_MATEO },
			{ S = "Lucia", T = "Falta Omar. ¿Alguien ha visto a Omar?", If = SIN_MATEO },
			{ S = "Paula", T = "Tranquilidad. Suele pasar: alguien ve algo bonito y se despista. Buscamos por la granja." },
			{ S = "Lucia", T = "{nombre}, tú y tus amigos, mirad por la zona del granero y del silo. Sin alejaros de la granja." },
		} },
		Pista_Mochila = { Lines = {
			{ S = "Narrador", T = "Una mochila en la hierba. Llena de cromos. Es la de Mateo.", If = AMIGO_MATEO },
			{ S = "Narrador", T = "Una mochila en la hierba. Dentro, un cuaderno de dibujo y migas de bocadillo. Es la de Omar.", If = SIN_MATEO },
		} },
		Pista_Botella = { Lines = {
			{ S = "Narrador", T = "Una botella medio vacía junto al silo. Y huellas pequeñas… y otras más pequeñas todavía, de pezuñas." },
		} },
		Pista_Mapa = { Lines = {
			{ S = "Narrador", T = "Un papel con un dibujo: el granero, una flecha y un animalito blanco. Pone: «¡Le sigo!»." },
		} },
		Julian = { Lines = {
			{ S = "Julian", T = "¿Un chaval? Sí, hace un rato. Iba detrás de Copito, el corderito que siempre se escapa." },
			{ S = "Julian", T = "Copito siempre acaba detrás del granero, donde crece la hierba buena. Mirad allí." },
		} },
		Encontrado = { Lines = {
			{ S = "Narrador", T = "Detrás del granero, sentado en la hierba, con un corderito blanco en el regazo." },
			{ S = "Mateo", T = "¡{nombre}! Se había escapado y… y lo seguí. Y luego no sabía volver. Todo se parece." , If = AMIGO_MATEO },
			{ S = "Omar", T = "¡{nombre}! Lo estaba dibujando y se movió, y lo seguí para terminar el dibujo. Y luego… no sabía volver.", If = SIN_MATEO },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Le das la mano y volvéis juntos", Effects = { Rel = { Mateo = 8, Omar = 8 }, Traits = { Empatia = 1 }, Choice = { Rescate = "Juntos" } }, Then = {
					{ S = "Narrador", T = "Volvéis juntos. Copito os sigue un rato, como si quisiera ir de excursión también." },
				} },
				{ T = "Te quedas con él y mandas a Nico a avisar a Lucía", Effects = { Rel = { Mateo = 5, Omar = 5, Lucia = 3 }, Traits = { Responsabilidad = 1 }, Choice = { Rescate = "Avisar" } }, Then = {
					{ S = "Nico", T = "¡Voy corriendo! ¡Soy el más rápido! ¡Bueno, casi!" },
				} },
			} },
		} },
		Reunion = { Lines = {
			{ S = "Lucia", T = "¡Aquí estáis! Menudo susto. Buen trabajo, equipo. Buen trabajo de verdad." },
			{ S = "Paula", T = "Y Copito, a su corral. Que eres un fugitivo profesional." },
			{ S = "Lucia", T = "¡Foto de grupo antes de volver! Todos delante del granero. Bruno, sin cuernos con los dedos." },
		} },
		Vuelta = { Lines = {
			{ S = "Narrador", T = "En el autobús de vuelta, medio autobús se queda dormido. Omar ronca. Sara lo apunta." },
			{ S = "Andres", T = "¡Atención, deportistas! Cuando volvamos… ¡empieza el torneo del colegio! Fútbol, baloncesto y atletismo." },
			{ S = "Nico", T = "¿TORNEO? ¡Estoy despierto! ¡ESTOY DESPIERTO!" },
		} },
	},
}
