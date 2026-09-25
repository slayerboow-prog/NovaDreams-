-- INSTITUTO 05 · «EL RUMOR» (25-35 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.28.
--
-- Una foto trucada de Omar corre por el grupo de la clase («Omar el Tragón»). Omar no viene a clase.
-- Qué haces tú con la foto → investigar quién la hizo (la captura, Leire y el fondo de la foto, Bruno
-- —a quien todos culpan—, la grada) → la hizo Darío, de segundo… y el primero en compartirla fue Nico
-- → hablar con Nico (en privado o delante de todos) → qué hacer con Darío (pedirle que la borre,
-- contárselo a Javier o devolvérsela) → buscar a Omar en el banco del parque → el día después.
-- 3 h después, Nico vuelve a hablar contigo (Eco_Nico), distinto según cómo se lo dijiste.

local V = Vector3.new

local ACUSASTE = { Flags = { "AcusasteABruno" } }

local CLASE = {
	{ Npc = "Javier", Place = "AulaInstituto", Offset = V(0, 0, -6) },
	{ Npc = "Sara", Place = "AulaInstituto", Offset = V(-2, 0, 2) },
	{ Npc = "Leire", Place = "AulaInstituto", Offset = V(6, 0, 3) },
	{ Npc = "Nico", Place = "AulaInstituto", Offset = V(-4, 0, 2) },
	{ Npc = "Bruno", Place = "AulaInstituto", Offset = V(-6, 0, -1) },
	{ Npc = "Alumno1", Place = "AulaInstituto", Offset = V(-2, 0, 5) },
	{ Npc = "Alumno4", Place = "AulaInstituto", Offset = V(4, 0, 6) },
}
local INVESTIGAR = {
	{ Npc = "Sara", Mode = "Follow" },
	{ Npc = "Leire", Place = "PatioInstituto", Offset = V(8, 0, 4) },
	{ Npc = "Bruno", Place = "PatioInstituto", Offset = V(-10, 0, 6) },
}
local PISTA = {
	{ Npc = "Nico", Place = "PistaInstituto", Offset = V(-4, 0, 4) },
	{ Npc = "Dario", Place = "PistaInstituto", Offset = V(6, 0, 6) },
	{ Npc = "Alumno3", Place = "PistaInstituto", Offset = V(10, 0, 2) },
	{ Npc = "Sara", Mode = "Follow" },
}
local BANCO = {
	{ Npc = "Omar", Place = "Parque", Offset = V(-6, 0, 6), Mode = "Sit" },
}
local DIA_DESPUES = {
	{ Npc = "Javier", Place = "AulaInstituto", Offset = V(0, 0, -6) },
	{ Npc = "Omar", Place = "AulaInstituto", Offset = V(3, 0, 0) },
	{ Npc = "Nico", Place = "AulaInstituto", Offset = V(-4, 0, 2) },
	{ Npc = "Sara", Place = "AulaInstituto", Offset = V(-2, 0, 2) },
	{ Npc = "Leire", Place = "AulaInstituto", Offset = V(6, 0, 3) },
	{ Npc = "Bruno", Place = "AulaInstituto", Offset = V(-6, 0, -1) },
	{ Npc = "Dario", Place = "AulaInstituto", Offset = V(8, 0, -4), If = { Choices = { Dario = "Javier" } } },
}

return {
	Id = "Ins05_ElRumor",
	Kind = "Main",
	Title = "El rumor",
	Description = "Una foto trucada de Omar corre por el grupo de la clase. Omar no ha venido. Alguien la hizo, y alguien la compartió.",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 15, 16 },
	Duration = { 25, 35 },
	Difficulty = 3,
	Type = "Historia · Conflicto",
	Requires = { Completed = { "Ins04_PrimerEmpleo" }, StageProgress = 0.58 },
	Npcs = { "Javier", "Sara", "Leire", "Nico", "Bruno", "Dario", "Omar" },
	Locations = { "AulaInstituto", "PatioInstituto", "PistaInstituto", "Parque" },
	Next = { "Ins06_LaGranDecision" },
	Outcomes = { "Reenviar o frenar la foto", "Confiar en Bruno o no", "Cómo hablas con Nico", "Qué pasa con Darío", "Cómo consuelas a Omar" },

	Moment = "Cuando defendiste a Omar",
	Memory = "ElRumor",
	Rewards = { Items = { PulseraGrupo = 1 }, Later = { { AfterHours = 3, Start = "Eco_Nico" } } },

	Props = {
		Captura = { Kind = "Papel", Name = "La captura del grupo de clase", Prompt = "Mirar con calma", Place = "PatioInstituto", Offset = V(2, 0, 2), Dialogue = "Pista_Captura", Once = true },
		Grada = { Kind = "Marcador", Name = "La grada de la pista", Prompt = "Buscar desde dónde se hizo", Place = "PistaInstituto", Offset = V(-12, 0, 8), Dialogue = "Pista_Grada", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Un año después. Un martes cualquiera…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaInstituto", Text = "Ve a clase: todo el mundo está mirando el móvil", Actors = CLASE },
		{ Type = "Scene", Dialogue = "LaFoto", Actors = CLASE },

		-- Investigar
		{ Type = "Group", Text = "Averigua quién hizo la foto (en el recreo)", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "Captura", Text = "Mira la captura con calma" },
				{ Type = "Talk", Npc = "Leire", Dialogue = "Pista_Leire", Text = "Pregunta a Leire: sabe de fotos" },
				{ Type = "Talk", Npc = "Bruno", Dialogue = "Pista_Bruno", Text = "Todos dicen que ha sido Bruno. Habla con él" },
				{ Type = "Use", Prop = "Grada", Text = "Busca en la pista desde dónde se hizo la foto" },
			},
			Actors = INVESTIGAR },
		{ Type = "Scene", Dialogue = "Deduccion", Actors = { { Npc = "Sara", Mode = "Follow" } } },

		-- Nico y Darío
		{ Type = "Reach", Place = "PistaInstituto", Text = "Ve a la pista: Nico y Darío están en el entreno", Actors = PISTA },
		{ Type = "Talk", Npc = "Nico", Dialogue = "Nico", Text = "Habla con Nico", Actors = PISTA },
		{ Type = "Talk", Npc = "Dario", Dialogue = "Dario", Text = "Habla con Darío", Actors = PISTA },

		-- Omar
		{ Type = "Reach", Place = "Parque", Text = "Busca a Omar. Sara cree que sabe dónde está: en el banco del parque", Actors = BANCO },
		{ Type = "Talk", Npc = "Omar", Dialogue = "Omar", Text = "Siéntate con Omar", Actors = BANCO },

		-- El día después
		{ Type = "Transition", Text = "Al día siguiente…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaInstituto", Text = "Ve a clase", Actors = DIA_DESPUES },
		{ Type = "Scene", Dialogue = "DiaDespues", Actors = DIA_DESPUES },
	},

	Dialogues = {
		LaFoto = { Lines = {
			{ S = "Narrador", T = "Toda la clase mira el móvil. Risitas. Alguien dice «qué bueno» y otro «pobre»." },
			{ S = "Sara", T = "{nombre}, mira. Está en el grupo de la clase desde anoche." },
			{ S = "Narrador", T = "Es una foto de Omar comiendo, trucada: la cabeza es un bocadillo gigante. Debajo pone «OMAR EL TRAGÓN». Tiene cuarenta reacciones." },
			{ S = "Sara", T = "Omar no ha venido hoy. Omar no falta nunca. Ni con fiebre." },
			{ Ask = "¿Qué haces con la foto?", Options = {
				{ T = "Escribes en el grupo: «Borradla. No tiene gracia.»", Effects = { Choice = { Foto = "Frenar" }, Traits = { Valentia = 2 }, Rel = { Omar = 5, Sara = 3 } }, Then = {
					{ S = "Narrador", T = "Durante un minuto nadie contesta. Luego Leire escribe «+1». Luego Sara. Luego tres más. La foto deja de moverse." },
				} },
				{ T = "No haces nada en el grupo, pero no la reenvías", Effects = { Choice = { Foto = "Nada" } }, Then = {
					{ S = "Sara", T = "No reenviarla está bien. Pero no sé si basta." },
				} },
				{ T = "Se te escapa una sonrisa… y luego te sientes fatal", Effects = { Choice = { Foto = "Reiste" }, Flags = { "TeReiste" }, Traits = { Humor = -1 } }, Then = {
					{ S = "Sara", T = "…¿En serio? Es Omar. NUESTRO Omar." },
					{ S = "Narrador", T = "Tiene razón. Se te borra la sonrisa. Esto hay que arreglarlo." },
				} },
			} },
			{ S = "Javier", T = "Móviles fuera, que empieza la clase. …Y si alguien tiene algo que contarme, mi puerta está abierta. Siempre." },
			{ S = "Sara", T = "En el recreo averiguamos quién la hizo. Y luego buscamos a Omar." },
		} },
		Pista_Captura = { Lines = {
			{ S = "Narrador", T = "Miras la captura despacio. La primera persona que la subió al grupo de la clase… es Nico." },
			{ S = "Sara", T = "¿Nico? No puede ser. Nico y Omar se conocen desde los seis años." },
			{ S = "Narrador", T = "Pero en una esquina de la foto hay algo más: una marca de agua pequeñita, «DR», como una firma." },
		} },
		Pista_Leire = { Lines = {
			{ S = "Leire", T = "Esa foto es un montaje malísimo. Pero la original es buena: está hecha desde arriba, con teleobjetivo." },
			{ S = "Leire", T = "Por la luz, de tarde. Por el fondo, la pista del instituto. Alguien estaba en la grada durante un entreno." },
			{ S = "Leire", T = "Y quien hace fotos así de otra persona sin preguntar… no me cae bien. Cuenta conmigo." },
		}, Effects = { Rel = { Leire = 3 } } },
		Pista_Bruno = { Lines = {
			{ S = "Bruno", T = "Ya. Ya sé lo que dicen. Que he sido yo. Siempre soy yo, ¿no?" },
			{ S = "Bruno", T = "Como en el colegio, con lo de las bromas. Me acusaste sin pruebas. Y tampoco fui yo.", If = ACUSASTE },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Te creo. Pero ayúdame: ¿sabes algo?»", Effects = { Choice = { Bruno = "Confiar" }, Rel = { Bruno = 8 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Bruno", T = "…¿Me crees? Vale. En el vestuario, los de segundo se reían con el móvil de Darío. Darío Ruiz. D. R." },
					{ S = "Bruno", T = "No me chivo. Te lo cuento. Que es distinto. Creo." },
				} },
				{ T = "«Demuéstralo»", Effects = { Choice = { Bruno = "Dudar" }, Rel = { Bruno = -4 } }, Then = {
					{ S = "Bruno", T = "¿Que lo demuestre? Pues mira mi móvil. No hay nada. Y ahora, déjame en paz." },
				} },
			} },
		} },
		Pista_Grada = { Lines = {
			{ S = "Narrador", T = "Subes a la grada. Desde aquí se ve exactamente el ángulo de la foto: el banquillo, la canasta, Omar merendando." },
			{ S = "Narrador", T = "En el asiento hay una pegatina del equipo de fútbol de segundo. Y alguien ha escrito con rotulador: «DR estuvo aquí»." },
		} },
		Deduccion = { Lines = {
			{ S = "Sara", T = "Recapitulemos. La foto se hizo desde la grada, en un entreno. Firmada «DR»." },
			{ S = "Sara", T = "Darío Ruiz, de segundo. Del equipo de fútbol. El nuevo amigo de Nico." },
			{ S = "Sara", T = "Y Nico… Nico la compartió primero. Eso es lo que más me duele." },
		} },
		Nico = { Lines = {
			{ S = "Nico", T = "¡{nombre}! ¿Vienes a ver el entreno? …¿Por qué me miras así?" },
			{ Ask = "¿Cómo hablas con Nico?", Options = {
				{ T = "Te lo llevas aparte: «¿Por qué la compartiste?»", Effects = { Choice = { HablasNico = "Privado" }, Traits = { Empatia = 1 }, Rel = { Nico = 3 } }, Then = {
					{ S = "Nico", T = "Yo… Darío me la pasó y todos se reían. Quería que se rieran conmigo. Que me vieran como uno de ellos." },
					{ S = "Nico", T = "No pensé que Omar la vería. No pensé nada. Qué idiota. Omar es… Omar." },
				} },
				{ T = "Se lo dices delante de todo el equipo", Effects = { Choice = { HablasNico = "Publico" }, Traits = { Valentia = 1 }, Rel = { Nico = -6 } }, Then = {
					{ S = "Nico", T = "¿Delante de todos? Vale, vale, me lo merezco. Pero podías haberme dicho algo a mí primero." },
					{ S = "Narrador", T = "El equipo se queda en silencio. Nico mira al suelo." },
				} },
			} },
			{ S = "Nico", T = "Voy a hablar con Omar. Hoy. Te lo prometo." },
		} },
		Dario = { Lines = {
			{ S = "Dario", T = "¿Qué pasa? Era una broma. Se ha hecho viral, eso es bueno, ¿no? Omar es famoso." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "«Bórrala y pídele perdón. Tú no la estás viviendo; él sí.»", Effects = { Choice = { Dario = "Perdon" }, Traits = { Valentia = 1, Empatia = 1 } }, Then = {
					{ S = "Dario", T = "…No lo había visto así. Él no se reía, ¿no? Vale. La borro. Y… le escribo." },
				} },
				{ T = "Se lo cuentas a Javier, el tutor", Effects = { Choice = { Dario = "Javier" }, Traits = { Responsabilidad = 2 }, Rel = { Javier = 4 } }, Then = {
					{ S = "Javier", T = "(más tarde) Gracias por contármelo. Esto no es una broma: es hacer daño en público. Me encargo. Y hablaré con toda la clase." },
				} },
				{ T = "Le devuelves la broma: un montaje suyo en el grupo", Effects = { Choice = { Dario = "Venganza" }, Flags = { "MontajeDario" }, Traits = { Humor = 1 }, Rel = { Omar = -2 } }, Then = {
					{ S = "Dario", T = "¿Ah, sí? Pues ahora os vais a enterar." },
					{ S = "Narrador", T = "Durante dos días el grupo de clase es una guerra de montajes. Nadie se ríe ya. Y Omar sigue sin venir." },
				} },
			} },
		} },
		Omar = { Lines = {
			{ S = "Narrador", T = "Omar está en el banco del parque. El mismo banco de siempre. Con la capucha puesta." },
			{ S = "Omar", T = "El banco del verano. Prometimos quedar aquí. No pensaba que lo usaría para esconderme.", If = { Choices = { Promesa = "Banco" } } },
			{ S = "Omar", T = "Hola. Ya has visto la foto, ¿no? Todo el mundo la ha visto. «Omar el Tragón». Ja." },
			{ S = "Omar", T = "Lo peor no es la foto. Lo peor es que Nico la compartió. Nico." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "Te sientas a su lado sin decir nada. Solo estar", Effects = { Traits = { Empatia = 2 }, Rel = { Omar = 8 } }, Then = {
					{ S = "Narrador", T = "Os quedáis un rato largo en silencio. Al final, Omar te da la mitad de su bocadillo. «Toma. Tragones los dos.» Y se ríe. Un poco." },
				} },
				{ T = "«Borré la foto del grupo. Y no va a volver.»", If = { Choices = { Foto = "Frenar" } }, Effects = { Rel = { Omar = 10 } }, Then = {
					{ S = "Omar", T = "¿Fuiste tú? Leire me dijo que alguien había plantado cara. No sabía que eras tú. Gracias." },
				} },
				{ T = "«Nico está fatal. Quiere pedirte perdón.»", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Omar = 5, Nico = 3 } }, Then = {
					{ S = "Omar", T = "…Que venga él. Que me lo diga él. Si lo hace, a lo mejor le perdono. A lo mejor." },
				} },
				{ T = "«Perdona. Yo también me reí al principio.»", If = { Flags = { "TeReiste" } }, Effects = { Traits = { Valentia = 1 }, Rel = { Omar = 6 } }, Then = {
					{ S = "Omar", T = "…Gracias por decírmelo. Duele. Pero prefiero saberlo de ti que enterarme por otro." },
				} },
			} },
			{ S = "Omar", T = "Mañana vuelvo a clase. Si vienes a buscarme. Por la mañana. A la parada." },
		} },
		DiaDespues = { Lines = {
			{ S = "Narrador", T = "Pasas a buscar a Omar a la parada. Entráis juntos en clase. Nadie dice nada. Alguien le choca la mano." },
			{ S = "Javier", T = "Antes de empezar: el grupo de clase es un sitio de esta clase. Lo que no diríais a la cara, no se escribe ahí.", If = { Choices = { Dario = "Javier" } } },
			{ S = "Javier", T = "Y si alguna vez os pasa algo así, contadlo a un adulto. A mí, a vuestra familia. Siempre. No es chivarse: es cuidarse." },
			{ S = "Dario", T = "(Darío, desde la puerta) Omar… lo siento. De verdad. Era una tontería y no lo pensé.", If = { Choices = { Dario = "Javier" } } },
			{ S = "Narrador", T = "Darío ha escrito a Omar por privado. Omar te enseña el mensaje: «Perdón. La he borrado. Fue una idiotez.»", If = { Choices = { Dario = "Perdon" } } },
			{ S = "Narrador", T = "La guerra de montajes ha terminado porque Javier ha borrado el grupo entero. Nadie sale bien parado. Tú tampoco.", If = { Choices = { Dario = "Venganza" } } },
			{ S = "Nico", T = "Omar. Yo… lo siento. No hay excusa. Me pasé. Te echo de menos en el recreo." },
			{ S = "Omar", T = "…Vale. Pero me debes diez bocadillos. Y los eliges tú, que así sufres." },
			{ S = "Omar", T = "He hecho pulseras para todos. Del grupo. Por si se nos olvida quiénes somos." },
		} },
	},
}
