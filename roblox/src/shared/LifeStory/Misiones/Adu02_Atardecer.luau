-- VIDA ADULTA 02 · «UN ATARDECER CON {ABU}» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.39.
--
-- {abu} se ha caído (nada grave) y está en el hospital con Nuria → te pide ver el mar otra vez, como
-- cuando era joven → cómo le llevas: sacarte el carnet en la autoescuela (LicenseEarned) y pedir el coche
-- a tu familia, o en autobús como hacía {abu} (Traveled a Playa Dorada) → la playa: {abu} te cuenta su
-- historia y te pide una promesa → el atardecer (cinemática). Un capítulo tranquilo, sin prisa.

local V = Vector3.new

local COCHE = { Choices = { ViajeAbu = "Coche" } }
local BUS = { Choices = { ViajeAbu = "Bus" } }

local HOSPITAL = {
	{ Npc = "Abu", Place = "Hospital", Offset = V(0, 0, 4), Mode = "Sit" },
	{ Npc = "Nuria", Place = "Hospital", Offset = V(3, 0, 5) },
	{ Npc = "Familia", Place = "Hospital", Offset = V(-3, 0, 5) },
}

return {
	Id = "Adu02_Atardecer",
	Kind = "Main",
	Title = "Un atardecer junto al mar",
	Description = "Tu abu se ha caído. No es grave, pero tiene un deseo: ver el mar otra vez. Contigo.",
	Chapter = "Adulto_VolarDelNido",
	AgeRange = { 23, 24 },
	Duration = { 20, 30 },
	Difficulty = 1,
	Type = "Historia · Familia",
	Requires = { Completed = { "Adu01_PrimerContrato" } },
	Npcs = { "Abu", "Nuria", "Familia" },
	Locations = { "Hospital", "Autoescuela", "ParadaBus", "Playa" },
	Next = { "Adu03_Reencuentro" },
	Outcomes = { "Coche o autobús", "Lo que le prometes a {abu}" },

	Moment = "El atardecer con {abu}",
	Memory = "AtardecerConAbu",
	Rewards = { Items = { ConchaAbu = 1 } },

	Props = {
		Concha = { Kind = "Marcador", Name = "Una concha en la arena", Prompt = "Cogerla", Place = "Playa", Offset = V(3, 0, -2), Dialogue = "Concha", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Un sábado por la mañana, suena el teléfono.", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Llamada" },
		{ Type = "Reach", Place = "Hospital", Text = "Ve al hospital: {abu} está allí", Actors = HOSPITAL },
		{ Type = "Talk", Npc = "Abu", Dialogue = "Hospital", Text = "Siéntate con {abu}", Actors = HOSPITAL },
		{ Type = "Choice", Key = "ViajeAbu", Text = "¿Cómo vas a llevar a {abu} a ver el mar?",
			Options = {
				{ Id = "Coche", Text = "Me saco el carnet y le llevo en coche", Effects = { Traits = { Valentia = 1 } } },
				{ Id = "Bus", Text = "En autobús, como hacía {abu} de joven", Effects = { Traits = { Empatia = 1 } } },
			},
			Actors = HOSPITAL },

		-- El camino
		{ Type = "Event", Event = "LicenseEarned", Match = { License = "B" }, Place = "Autoescuela", Text = "Sácate el carnet de coche en la autoescuela", If = COCHE,
			Nudge = { After = 240, Every = 240, S = "Familia", T = "(mensaje) {abu} pregunta cada día si ya tienes el carnet. Dice que conduces seguro mejor que yo." } },
		{ Type = "Scene", Dialogue = "Coche", If = COCHE,
			Actors = { { Npc = "Familia", Place = "CercaDeTi", Offset = V(-3, 0, -4) }, { Npc = "Abu", Place = "CercaDeTi", Offset = V(3, 0, -4) } } },
		{ Type = "Scene", Dialogue = "Autobus", If = BUS,
			Actors = { { Npc = "Abu", Place = "ParadaBus", Offset = V(2, 0, 3), Mode = "Sit" } } },
		{ Type = "Reach", Place = "ParadaBus", Text = "Recoge a {abu} en la parada del autobús", If = BUS,
			Actors = { { Npc = "Abu", Place = "ParadaBus", Offset = V(2, 0, 3), Mode = "Sit" } } },
		{ Type = "Event", Event = "Traveled", Match = { Town = "Playa Dorada" }, Place = "ParadaBus", Text = "Coge el autobús a Playa Dorada con {abu}", If = BUS,
			Actors = { { Npc = "Abu", Mode = "Follow" } } },
		{ Type = "Reach", Place = "Playa", Text = "Llega a la playa con {abu}", Actors = { { Npc = "Abu", Mode = "Follow" } } },

		-- La playa
		{ Type = "Scene", Dialogue = "Mar", Actors = { { Npc = "Abu", Place = "Playa", Offset = V(0, 0, 3), Mode = "Sit" } } },
		{ Type = "Use", Prop = "Concha", Text = "Coge una concha para {abu}", Actors = { { Npc = "Abu", Place = "Playa", Offset = V(0, 0, 3), Mode = "Sit" } } },
		{ Type = "Scene", Dialogue = "Promesa", Actors = { { Npc = "Abu", Place = "Playa", Offset = V(0, 0, 3), Mode = "Sit" } } },
		{ Type = "Cinematic", Id = "Adu02_Atardecer", Actors = { { Npc = "Abu", Place = "Playa", Offset = V(0, 0, 3), Mode = "Sit" } } },
	},

	Dialogues = {
		Llamada = { Lines = {
			{ S = "Familia", T = "(al teléfono) No te asustes, ¿vale? {abu} se ha caído en la escalera. Está bien. En el hospital, para que le miren." },
			{ S = "Familia", T = "Pregunta por ti. Bueno, pregunta por ti y por si alguien le ha regado la planta." },
		} },
		Hospital = { Lines = {
			{ S = "Nuria", T = "Tranquilidad: nada roto. Un golpe y un buen susto. Unos días de descanso y como nuevo.", If = { NotFlags = { "Graduado" } } },
			{ S = "Nuria", T = "Tranquilidad, colega: nada roto. Ya lo sabías, ¿verdad? Has mirado la placa antes que yo.", If = { Flags = { "Graduado" }, Choices = { Estudios = "Medicina" } } },
			{ S = "Nuria", T = "Tranquilidad: nada roto. Un golpe y un buen susto. Unos días de descanso y como nuevo.", If = { Flags = { "Graduado" }, NotChoices = { Estudios = "Medicina" } } },
			{ S = "Abu", T = "Mírate. Con tu trabajo, tu casa… Y yo aquí, con una bata que no cierra por detrás. Qué vergüenza." },
			{ S = "Abu", T = "¿Llevas el reloj? …Lo llevas. Bien.", If = { Memories = { "PrimerDiaUni" } } },
			{ S = "Abu", T = "Oye, tengo que pedirte una cosa." },
			{ S = "Abu", T = "Cuando era joven, iba cada domingo a ver el mar a Playa Dorada. En autobús. Hace años que no voy. Me gustaría verlo otra vez. Contigo." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«En cuanto salgas de aquí, vamos. Te lo prometo.»", Effects = { Rel = { Abu = 8 } }, Then = {
					{ S = "Abu", T = "Trato hecho. Y no me lleves corriendo, que ya no estoy para sustos." },
				} },
				{ T = "Le coges la mano sin decir nada", Effects = { Rel = { Abu = 10 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Abu", T = "(aprieta tu mano) Ya. Ya lo sé. Tú siempre has dicho las cosas así." },
				} },
			} },
		} },
		Coche = { Lines = {
			{ S = "Familia", T = "¡Carnet nuevo! Toma las llaves del coche viejo. Tiene más años que tú. Trátalo con cariño, que hace ruidos raros." },
			{ S = "Abu", T = "Despacio, ¿eh? Y con las dos manos en el volante. Y sin música alta. Bueno, un poquito de música." },
		} },
		Autobus = { Lines = {
			{ S = "Abu", T = "El autobús de Playa Dorada. Hace cincuenta años lo cogía con mis amigos. Íbamos cantando. El conductor nos odiaba." },
		} },
		Mar = { Lines = {
			{ S = "Narrador", T = "El mar. {abu} se sienta en la arena despacito. Cierra los ojos. Respira hondo." },
			{ S = "Narrador", T = "Llueve un poco sobre el mar. A {abu} no le importa: «el mar con lluvia también es el mar».", If = { Weather = { "Lluvia", "Tormenta" } } },
			{ S = "Narrador", T = "Hace frío y el viento sopla. Le pones tu chaqueta por encima. {abu} protesta, pero no se la quita.", If = { Season = "Invierno" } },
			{ S = "Abu", T = "Aquí conocí a la persona más importante de mi vida. Y aquí vine el día que naciste, a contárselo al mar." },
			{ S = "Abu", T = "¿Sabes qué le dije? «Hoy ha nacido alguien que va a hacer cosas bonitas». Y mira. No me equivoqué." },
			{ S = "Abu", T = "Me acuerdo de tu primer día de colegio. Te agarrabas a mi mano como si te fueras a otro planeta.", If = { Memories = { "PrimerDiaCole" } } },
			{ S = "Abu", T = "Y de tu graduación. Lloré tanto que se me empañaron las gafas y no vi el diploma. No se lo digas a nadie.", If = { Memories = { "Graduacion" } } },
		} },
		Concha = { Lines = {
			{ S = "Narrador", T = "Una concha blanca, perfecta. Se la das a {abu}. {abu} te la devuelve." },
			{ S = "Abu", T = "No, no. Esta es para ti. Para que vuelvas aquí. Con quien tú quieras." },
		} },
		Promesa = { Lines = {
			{ S = "Abu", T = "Prométeme una cosa, cariño." },
			{ Ask = "¿Qué le prometes?", Options = {
				{ T = "«Volveré aquí cada año. Contigo o por ti.»", Effects = { Choice = { PromesaAbu = "Volver" }, Rel = { Abu = 6 } }, Then = {
					{ S = "Abu", T = "Cada año. Me vale. Y si un año no puedo venir, tráeme una foto." },
				} },
				{ T = "«Haré cosas bonitas. Como dijiste.»", Effects = { Choice = { PromesaAbu = "CosasBonitas" }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Abu", T = "Ya las haces. Pero haz más. Muchas. Y que se note que eres feliz haciéndolas." },
				} },
				{ T = "«Cuidaré de la familia como tú cuidaste de mí.»", Effects = { Choice = { PromesaAbu = "Familia" }, Traits = { Responsabilidad = 1 }, Rel = { Familia = 5 } }, Then = {
					{ S = "Abu", T = "Eso ya lo sé. Lo sé desde que me diste la mitad de tu bocadillo con cinco años." },
				} },
			} },
			{ S = "Narrador", T = "El sol baja despacio. Os quedáis callados, mirando el mar. No hace falta decir nada más." },
		} },
	},
}
