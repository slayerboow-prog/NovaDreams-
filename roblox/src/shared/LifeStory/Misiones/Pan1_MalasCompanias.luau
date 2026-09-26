-- LA PANDILLA 1 · «LAS MALAS COMPAÑÍAS» (20-25 min) — arco de adolescencia: el bien o el mal
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.41.
--
-- Rayo y Nerea, de 4.º, se fijan en ti y te invitan a hacer pellas. Tres caminos: irte con ellos
-- (recreativos, una pintada en el muro del parque y, por la noche, mentir o no a tu familia), volver a
-- clase, o convencer a Nerea de que no vaya. Cada decisión suma Rebeldía (trait) o lo contrario;
-- el camino de tu vida (Responsable, Gamberro/a o Delincuente) se decide en «El cruce de caminos».
-- Nada está prohibido y nada es para siempre: el juego cuenta las consecuencias, no castiga.

local V = Vector3.new

local PELLAS = { Choices = { Pellas = "Ir" } }
local CLASE_ = { Choices = { Pellas = "Clase" } }
local NEREA = { Choices = { Pellas = "Nerea" } }

local PATIO = {
	{ Npc = "Rayo", Place = "PatioInstituto", Offset = V(10, 0, 4) },
	{ Npc = "Nerea", Place = "PatioInstituto", Offset = V(12, 0, 6), Mode = "Sit" },
	{ Npc = "Javier", Place = "PatioInstituto", Offset = V(-8, 0, 8) },
	{ Npc = "Omar", Place = "PatioInstituto", Offset = V(-2, 0, 3) },
}
local PANDA = {
	{ Npc = "Rayo", Mode = "Follow" },
	{ Npc = "Nerea", Mode = "Follow" },
}
local MURO = {
	{ Npc = "Rayo", Place = "Parque", Offset = V(-12, 0, 8) },
	{ Npc = "Nerea", Place = "Parque", Offset = V(-9, 0, 9) },
}
local CASA = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2), Mode = "Sit" },
}

return {
	Id = "Pan1_MalasCompanias",
	Kind = "Main",
	Title = "Las malas compañías",
	Description = "Rayo es el más popular de 4.º. Y hoy te ha elegido a ti. «¿Te vienes? Nadie se va a enterar.»",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 14, 14 },
	Duration = { 20, 25 },
	Difficulty = 2,
	Type = "Historia · El camino (bien o mal)",
	Requires = { Completed = { "Ins03_QueQuieresSer" }, StageProgress = 0.30 },
	Npcs = { "Rayo", "Nerea", "Javier", "Omar", "Familia", "Abu", "Bruno" },
	Locations = { "PatioInstituto", "Ocio", "Parque", "AulaInstituto", "HomeSalon" },
	Next = { "Pan2_LaNoche" },
	Outcomes = { "Hacer pellas, volver a clase o frenar a Nerea", "Pintada o no", "Mentir a tu familia o decir la verdad" },

	Moment = "El día que conociste a Rayo",
	Memory = "MalasCompanias",

	Props = {
		Muro = { Kind = "Mural", Name = "El muro del parque", Prompt = "Coger el espray", Place = "Parque", Offset = V(-10, 0, 12), Dialogue = "Muro", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Segundo de la ESO. Un martes cualquiera.", Seconds = 3 },
		{ Type = "Reach", Place = "PatioInstituto", Text = "Sal al recreo", Actors = PATIO },
		{ Type = "Scene", Dialogue = "Rayo", Actors = PATIO },
		{ Type = "Choice", Key = "Pellas", Text = "¿Qué haces? (habla con quien elijas)",
			Options = {
				{ Id = "Ir", Npc = "Rayo", Text = "Irte con Rayo a los recreativos", Dialogue = "Ir", Effects = { Traits = { Rebeldia = 1 }, Rel = { Rayo = 6 }, Flags = { "HicistePellas" } } },
				{ Id = "Clase", Npc = "Javier", Text = "Volver a clase", Dialogue = "Clase", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Rayo = -3 }, Flags = { "RechazasteLaPandilla" } } },
				{ Id = "Nerea", Npc = "Nerea", Text = "Convencer a Nerea de que no vaya", Dialogue = "ConvencerNerea", Effects = { Traits = { Empatia = 1 }, Rel = { Nerea = 8, Rayo = -5 }, Flags = { "RechazasteLaPandilla", "AmigaNerea" } } },
			},
			Actors = PATIO },

		-- Camino de las pellas
		{ Type = "Reach", Place = "Ocio", Text = "Ve con Rayo y Nerea a los recreativos", If = PELLAS, Actors = PANDA },
		{ Type = "Event", Event = "ArcadePlayed", Place = "Ocio", Text = "Juega una partida en los recreativos", If = PELLAS, Actors = PANDA,
			Timeout = { After = 180 } },
		{ Type = "Scene", Dialogue = "Recreativos", If = PELLAS, Actors = PANDA },
		{ Type = "Reach", Place = "Parque", Text = "Rayo quiere enseñarte «su» muro del parque", If = PELLAS, Actors = MURO },
		{ Type = "Use", Prop = "Muro", Text = "El muro: Rayo te da un espray", If = PELLAS, Actors = MURO },

		-- Camino de clase
		{ Type = "Class", Subject = "HistoriaInstituto", Mode = "Clase", Place = "AulaInstituto", Text = "Clase de Historia con Javier", If = CLASE_,
			Actors = { { Npc = "Javier", Place = "AulaInstituto", Offset = V(0, 0, -6) } } },
		{ Type = "Scene", Dialogue = "Salida", If = CLASE_, Actors = { { Npc = "Rayo", Place = "PatioInstituto", Offset = V(4, 0, 4) }, { Npc = "Nerea", Place = "PatioInstituto", Offset = V(7, 0, 5) } } },

		-- Camino de Nerea
		{ Type = "Scene", Dialogue = "Comics", If = NEREA, Actors = { { Npc = "Nerea", Place = "PatioInstituto", Offset = V(3, 0, 3), Mode = "Sit" } } },

		-- Por la noche, en casa
		{ Type = "Transition", Text = "Esa noche…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Casa", Teleport = "HomeSalon", Actors = CASA },
		{ Type = "Talk", Npc = "Bruno", Dialogue = "Bruno", Text = "Un mensaje de Bruno: «¿Hablamos? Estoy en la puerta de tu casa»",
			Actors = { { Npc = "Bruno", Place = "CercaDeTi", Offset = V(0, 0, -5) } } },
	},

	Dialogues = {
		Rayo = { Lines = {
			{ S = "Narrador", T = "En el rincón del fondo del patio está la pandilla de Rayo. Los de 4.º. Todo el mundo los mira. Nadie se acerca." },
			{ S = "Rayo", T = "Eh, tú. Sí, tú. Te he visto. No eres como los demás pringados de segundo. Tienes pinta de saber divertirte." },
			{ S = "Rayo", T = "Después del recreo nos piramos a los recreativos. Javier ni se entera. ¿Te vienes? Nerea también viene." },
			{ S = "Nerea", T = "(sin levantar la vista de su cuaderno) Yo voy porque no tengo nada mejor que hacer. Tú verás." },
			{ S = "Omar", T = "(bajito) {nombre}… Esos se meten en líos. Todo el rato. Yo me vuelvo a clase. Tú haz lo que quieras, ¿eh?" },
		} },
		Ir = { Lines = {
			{ S = "Rayo", T = "¡Eso es! Sabía que tenías algo. Venga, que la puerta de atrás del gimnasio no la vigila nadie." },
		} },
		Clase = { Lines = {
			{ S = "Javier", T = "¿Volviendo a clase por su propio pie? Me alegra el día. No se lo digas a nadie, pero hoy toca la Revolución Francesa. Es la mejor." },
			{ S = "Rayo", T = "(desde lejos) ¡Pringado! …Tú te lo pierdes." },
		} },
		ConvencerNerea = { Lines = {
			{ S = "Nerea", T = "¿Y a ti qué te importa si voy o no?" },
			{ S = "Narrador", T = "Le dices que te ha gustado lo que dibuja. Que lo has visto de reojo. Que es bueno de verdad." },
			{ S = "Nerea", T = "…Nadie mira mis dibujos. Vale. Hoy no voy. Pero no te acostumbres a mandarme." },
			{ S = "Rayo", T = "¿Nerea se queda? Tú. Me acuerdo de tu cara." },
		} },
		Recreativos = { Lines = {
			{ S = "Narrador", T = "Luces, música, fichas. Rayo gana a todo. Es divertido, la verdad. Muy divertido." },
			{ S = "Rayo", T = "¿Ves? Esto es vivir. En clase te hacen estar quieto seis horas. Aquí mandas tú." },
			{ S = "Nerea", T = "(bajito) La primera vez también me lo pareció. Luego llegan las notas. Y las llamadas a casa." },
		} },
		Muro = { Lines = {
			{ S = "Rayo", T = "Este muro es nuestro. Cada uno pone su firma. Toma, el espray. Pon la tuya." },
			{ Ask = "¿Qué haces con el espray?", Options = {
				{ T = "Pintas tu firma, grande", Effects = { Traits = { Rebeldia = 1 }, Flags = { "Pintada" }, Rel = { Rayo = 4 } }, Then = {
					{ S = "Rayo", T = "¡Eso! Ahora eres de los nuestros. Mañana lo verá todo el barrio." },
				} },
				{ T = "Pintas un dibujo bonito en vez de una firma", Effects = { Traits = { Rebeldia = 1, Creatividad = 1 }, Flags = { "Pintada" }, Rel = { Nerea = 4 } }, Then = {
					{ S = "Nerea", T = "…Eso está bien. Muy bien. Aunque sigue siendo pintar donde no se puede." },
				} },
				{ T = "Le devuelves el espray: «Esto no»", Effects = { Traits = { Valentia = 1 }, Rel = { Rayo = -4, Nerea = 3 } }, Then = {
					{ S = "Rayo", T = "Vale, vale. Qué miedo tenéis todos a todo. Ya te lo pensarás." },
				} },
			} },
		} },
		Salida = { Lines = {
			{ S = "Narrador", T = "A la salida, Rayo y su pandilla están en la puerta. Vienen de los recreativos. Se ríen muy alto." },
			{ S = "Rayo", T = "Mira quién sale de clase. ¿Qué tal la Revolución Francesa? ¿Te has divertido mucho?" },
			{ S = "Nerea", T = "(al pasar a tu lado, bajito) Javier ha llamado a sus casas. A la mía también. Hiciste bien." },
		} },
		Comics = { Lines = {
			{ S = "Nerea", T = "Mira. Son cómics. Una chica que vuela por encima de Valmar y nadie la ve. No se los he enseñado a nadie." },
			{ S = "Nerea", T = "Rayo dice que dibujar es de críos. Pero Rayo dice muchas cosas." },
		} },
		Casa = { Lines = {
			{ S = "Familia", T = "Ha llamado Javier, tu tutor. Dice que esta tarde no estabas en clase. ¿Me lo explicas?", If = PELLAS },
			{ Ask = "¿Qué le dices?", If = PELLAS, Options = {
				{ T = "«Me encontraba mal y me fui a dar una vuelta» (mentira)", Effects = { Traits = { Rebeldia = 1 }, Flags = { "MentisteFamilia" }, Rel = { Familia = -5 } }, Then = {
					{ S = "Familia", T = "…Ya. Vale. Te creo. Esta vez." },
					{ S = "Abu", T = "(desde el sillón, sin mirarte) Las mentiras pesan más que la mochila, cariño. Lo digo por experiencia." },
				} },
				{ T = "«Me fui con unos de 4.º. Me equivoqué.»", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Familia = 3 } }, Then = {
					{ S = "Familia", T = "Me enfada. Mucho. Pero me alegra que me lo cuentes. Una semana sin paga, y lo hablamos." },
				} },
			} },
			{ S = "Familia", T = "¿Qué tal el día? ¿Mucha Historia? Tienes cara de haber aprendido algo.", If = CLASE_ },
			{ S = "Familia", T = "Me ha dicho Omar que hoy has ayudado a una chica de 4.º. Qué bien.", If = NEREA },
		} },
		Bruno = { Lines = {
			{ S = "Bruno", T = "Oye. Me he enterado de lo de Rayo. En el instituto se entera todo el mundo de todo." },
			{ S = "Bruno", T = "Yo era el malo del colegio, ¿te acuerdas? Molaba. Hasta que dejó de molar. Rayo es eso, pero en mayor." },
			{ S = "Bruno", T = "Hiciste bien en volver. De verdad.", If = { Flags = { "RechazasteLaPandilla" } } },
			{ S = "Bruno", T = "Solo… ten cuidado. Con Rayo, un día son los recreativos y otro día es otra cosa.", If = PELLAS },
		} },
	},
}
