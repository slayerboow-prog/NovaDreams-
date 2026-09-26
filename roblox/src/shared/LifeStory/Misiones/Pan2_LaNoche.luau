-- LA PANDILLA 2 · «LA NOCHE DEL SUPERMERCADO» (25-30 min) — arco del bien o el mal
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.42.
--
-- Rayo tiene un plan: el sábado por la noche, colarse por la puerta del almacén del súper de Paco y
-- llevarse latas y chuches. Tú decides: ir, no ir, o intentar que no lo hagan. Si vas: coger algo o
-- dejarlo y marcharte; si coges, salta la alarma y hay que correr (Timeout: si no llegas a tiempo, te
-- pillan). Si te pillan: comisaría con Inés, tu familia y Paco, y servicio a la comunidad en el Punto
-- Limpio (trabajo de verdad, JobService «Basurero»). Si escapas, las cámaras te grabaron: 2 h después
-- la policía llama a tu puerta (Eco_Camaras).

local V = Vector3.new

local VAS = { Choices = { Plan = "Ir" } }
local NO_VAS = { NotChoices = { Plan = "Ir" } }
local HURTO = { Flags = { "Hurto" } }

local PARQUE = {
	{ Npc = "Rayo", Place = "Parque", Offset = V(-12, 0, 8) },
	{ Npc = "Nerea", Place = "Parque", Offset = V(-9, 0, 9), Mode = "Sit" },
}
local SUPER = {
	{ Npc = "Rayo", Place = "Supermercado", Offset = V(-8, 0, -10) },
	{ Npc = "Nerea", Place = "Supermercado", Offset = V(-10, 0, -8) },
}
local COMISARIA = {
	{ Npc = "Ines", Place = "Policia", Offset = V(0, 0, 5) },
	{ Npc = "Familia", Place = "Policia", Offset = V(-4, 0, 4) },
	{ Npc = "Paco", Place = "Policia", Offset = V(4, 0, 4) },
	{ Npc = "Rayo", Place = "Policia", Offset = V(6, 0, 1), Mode = "Sit" },
}

return {
	Id = "Pan2_LaNoche",
	Kind = "Main",
	Title = "La noche del supermercado",
	Description = "Rayo tiene un plan para el sábado por la noche. «Una puerta que no cierra bien. Unas latas. Nadie se va a enterar.»",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 14, 15 },
	Duration = { 25, 30 },
	Difficulty = 3,
	Type = "Historia · El camino (bien o mal)",
	Requires = { Completed = { "Pan1_MalasCompanias" }, StageProgress = 0.36 },
	Npcs = { "Rayo", "Nerea", "Ines", "Familia", "Paco" },
	Locations = { "Parque", "Supermercado", "Policia", "PuntoLimpio", "HomeSalon" },
	Next = { "Ins04_PrimerEmpleo" },
	Outcomes = { "Ir o no ir", "Coger algo o marcharte", "Que te pillen, escapar (y que te pillen después) o no estar allí" },

	Moment = "La noche del supermercado",
	Memory = "LaNoche",
	Rewards = { Later = { { AfterHours = 2, Start = "Eco_Camaras", If = { Flags = { "Hurto", "Escapaste" } } } } },

	Props = {
		PuertaAlmacen = { Kind = "Marcador", Name = "La puerta del almacén", Prompt = "Entrar", Place = "Supermercado", Offset = V(-6, 0, -12), Dialogue = "Almacen", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Un sábado de primavera…", Seconds = 3 },
		{ Type = "Reach", Place = "Parque", Text = "Rayo te ha escrito: «Parque. Ahora. Tengo un plan»", Actors = PARQUE },
		{ Type = "Talk", Npc = "Rayo", Dialogue = "Plan", Text = "Escucha el plan de Rayo", Actors = PARQUE },

		-- La noche
		{ Type = "Transition", Text = "Esa noche, a las diez y media…", Seconds = 3, If = VAS },
		{ Type = "Reach", Place = "Supermercado", Text = "El súper de Paco ya ha cerrado. Rayo espera en la parte de atrás", If = VAS, Actors = SUPER },
		{ Type = "Use", Prop = "PuertaAlmacen", Text = "La puerta del almacén", If = VAS, Actors = SUPER },
		{ Type = "Scene", Dialogue = "Alarma", If = HURTO, Actors = SUPER },
		{ Type = "Reach", Place = "Parque", Text = "¡CORRE! ¡Llega al parque antes de que llegue la policía!", If = HURTO,
			Timeout = { After = 35, Flags = { "Pillado" } } },
		{ Type = "Scene", Dialogue = "Escapaste", If = { Flags = { "Hurto" }, NotFlags = { "Pillado" } },
			Effects = { Flags = { "Escapaste" } }, Actors = { { Npc = "Rayo", Place = "Parque", Offset = V(3, 0, 3) } } },

		-- Si te pillan
		{ Type = "Scene", Dialogue = "Comisaria", If = { Flags = { "Pillado" } }, Teleport = "Policia", Actors = COMISARIA },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Basurero" }, Count = 3, Place = "PuntoLimpio", If = { Flags = { "Pillado" } },
			Text = "Servicio a la comunidad: limpia en el Punto Limpio ({count}/{total})",
			Actors = { { Npc = "Ines", Place = "PuntoLimpio", Offset = V(0, 0, 6) } } },
		{ Type = "Scene", Dialogue = "Servicio", If = { Flags = { "Pillado" } }, Actors = { { Npc = "Ines", Place = "PuntoLimpio", Offset = V(0, 0, 6) } } },

		-- Si no fuiste
		{ Type = "Transition", Text = "Esa noche, en casa…", Seconds = 3, If = NO_VAS },
		{ Type = "Scene", Dialogue = "Mensajes", If = NO_VAS },

		-- El lunes
		{ Type = "Scene", Dialogue = "Lunes", Actors = { { Npc = "Nerea", Place = "CercaDeTi", Offset = V(0, 0, -5) } } },
	},

	Dialogues = {
		Plan = { Lines = {
			{ S = "Rayo", T = "Escucha. El súper de Paco cierra a las diez. La puerta del almacén no cierra bien: se abre con un empujón." },
			{ S = "Rayo", T = "Entramos, cogemos unas latas, chuches, lo que sea, y nos vamos. Cinco minutos. No es robar: Paco tiene de sobra." },
			{ S = "Nerea", T = "(sin mirarte) Yo iré. Supongo. ¿Tú vas?" },
			{ S = "Rayo", T = "Tú ya eres de los nuestros. Lo del muro fue un primer paso. Esto es el segundo.", If = { Flags = { "Pintada" } } },
			{ Ask = "¿Qué dices?", Options = {
				{ T = "«Voy.»", Effects = { Choice = { Plan = "Ir" }, Traits = { Rebeldia = 1 }, Rel = { Rayo = 5 } }, Then = {
					{ S = "Rayo", T = "¡Eso! A las diez y media, detrás del súper. Ropa oscura." },
				} },
				{ T = "«Paso. Esto ya no es una tontería.»", Effects = { Choice = { Plan = "No" }, Traits = { Responsabilidad = 1 }, Rel = { Rayo = -4 }, Flags = { "RechazasteLaPandilla" } }, Then = {
					{ S = "Rayo", T = "Tú sabrás. Luego no me vengas con que te aburres." },
				} },
				{ T = "«No lo hagáis. Os van a pillar. Nerea, tú tampoco.»", Effects = { Choice = { Plan = "Frenar" }, Traits = { Empatia = 1, Valentia = 1 }, Rel = { Rayo = -6, Nerea = 6 }, Flags = { "RechazasteLaPandilla" } }, Then = {
					{ S = "Nerea", T = "…" },
					{ S = "Rayo", T = "¿Ahora eres su madre? Nerea hace lo que quiere. ¿Verdad, Nerea?" },
					{ S = "Nerea", T = "…Esta vez me quedo en casa. Lo siento, Rayo.", If = { Flags = { "AmigaNerea" } } },
				} },
			} },
		} },
		Almacen = { Lines = {
			{ S = "Narrador", T = "La puerta se abre con un empujón, como dijo Rayo. Dentro, oscuro. Cajas. Estanterías. Huele a cartón." },
			{ S = "Rayo", T = "(susurrando) ¡Rápido! Coge lo que quieras y nos vamos." },
			{ S = "Narrador", T = "Tienes una caja de latas delante. Nadie te ve. Piensas en Paco, en su «Hmm», en sus cajas perfectamente apiladas." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Coges unas latas y unas chuches", Effects = { Flags = { "Hurto" }, Traits = { Rebeldia = 2 }, Rel = { Rayo = 4 } }, Then = {
					{ S = "Rayo", T = "¡Eso es! ¡Vámonos!" },
				} },
				{ T = "Lo dejas todo en su sitio y te vas", Effects = { Flags = { "TeFuiste" }, Traits = { Valentia = 1 }, Rel = { Rayo = -5, Nerea = 5 } }, Then = {
					{ S = "Narrador", T = "Das media vuelta y sales. Rayo te llama algo desde dentro. No lo oyes. No quieres oírlo." },
					{ S = "Nerea", T = "(te alcanza en la calle) Espera. Yo tampoco quería. Me voy contigo." },
				} },
			} },
		} },
		Alarma = { Lines = {
			{ S = "Narrador", T = "¡UUUUUUUUH! La alarma. Luces rojas. Un perro ladra en la calle de al lado." },
			{ S = "Rayo", T = "¡CORRED! ¡Cada uno por un lado! ¡Nos vemos en el parque!" },
		} },
		Escapaste = { Lines = {
			{ S = "Narrador", T = "Llegas al parque sin aliento. El corazón te va a salir por la boca. Nadie te ha seguido. Eso crees." },
			{ S = "Rayo", T = "¡JA! ¿Has visto? ¡Nadie nos pilla! Mañana nos comemos las chuches a la salud de Paco." },
			{ S = "Narrador", T = "Tienes una lata en la mano. No sabe a nada." },
		} },
		Comisaria = { Lines = {
			{ S = "Narrador", T = "No llegas. Una patrulla te para a dos calles. Media hora después estás en la comisaría, sentado o sentada en un banco de plástico." },
			{ S = "Ines", T = "Hola otra vez. Nos conocimos en la semana de las profesiones. No pensé que volveríamos a vernos así.", If = { Flags = { "Interes_Derecho" } } },
			{ S = "Ines", T = "Soy la agente Inés. Tranquilidad: nadie va a ir a la cárcel por unas latas. Pero esto tiene consecuencias." },
			{ S = "Familia", T = "(entra corriendo) ¿Estás bien? …Estás bien. Vale. Ahora sí: ¿EN QUÉ ESTABAS PENSANDO?" },
			{ S = "Paco", T = "Hmm. Treinta años con el súper abierto. Nunca me habían entrado. Y has sido tú. No me lo esperaba." },
			{ S = "Ines", T = "Como sois menores y es la primera vez: servicio a la comunidad. Tres turnos limpiando en el Punto Limpio. Y pedir perdón a Paco." },
			{ Ask = "¿Qué le dices a Paco?", Options = {
				{ T = "«Lo siento. De verdad. Te devuelvo todo y te lo pago.»", Effects = { Rel = { Paco = 3, Familia = 3 }, Traits = { Responsabilidad = 1 }, Flags = { "PerdonPaco" } }, Then = {
					{ S = "Paco", T = "Hmm. Pedir perdón mirando a los ojos. Eso ya es algo. Ya veremos." },
				} },
				{ T = "No dices nada. Miras al suelo.", Effects = { Rel = { Paco = -5 }, Traits = { Rebeldia = 1 } }, Then = {
					{ S = "Paco", T = "Ya. Hmm." },
				} },
			} },
		}, Effects = { Flags = { "AvisoPolicia" }, Rel = { Familia = -6, Paco = -8 } } },
		Servicio = { Lines = {
			{ S = "Ines", T = "Tres turnos. Bien hecho. ¿Sabes qué? La mayoría de los chavales que vienen aquí no vuelven nunca a la comisaría. Espero que tú seas de esos." },
			{ S = "Narrador", T = "Limpiando, encuentras una lata igual que la que te llevaste. La tiras al contenedor amarillo. Te sientes un poco mejor." },
		} },
		Mensajes = { Lines = {
			{ S = "Narrador", T = "Medianoche. Tu móvil vibra." },
			{ S = "Nerea", T = "(mensaje) Al final han ido Rayo y dos más. Ha saltado la alarma. A Rayo le han pillado.", If = { Choices = { Plan = "No" } } },
			{ S = "Nerea", T = "(mensaje) Me he quedado en casa. Rayo ha ido con dos más y le han pillado. Gracias por lo de esta tarde. En serio.", If = { Choices = { Plan = "Frenar" } } },
			{ S = "Nerea", T = "(mensaje) Rayo dice que alguien se ha chivado. No has sido tú, ¿no? Dime que no." },
		} },
		Lunes = { Lines = {
			{ S = "Nerea", T = "Todo el instituto sabe lo del súper. Rayo está expulsado tres días." },
			{ S = "Nerea", T = "Y tú… te pillaron. Lo siento. Rayo dice que eres «de los buenos» porque no dijiste nombres. No sé si eso es un piropo.", If = { Flags = { "Pillado" } } },
			{ S = "Nerea", T = "Tú te libraste. Pero hay cámaras en la puerta del almacén. Lo sabe todo el mundo menos Rayo.", If = { Flags = { "Escapaste" } } },
			{ S = "Nerea", T = "Te fuiste a tiempo. Yo también. Creo que es lo más valiente que he hecho nunca.", If = { Flags = { "TeFuiste" } } },
			{ S = "Nerea", T = "Tú no estabas. Mejor. Rayo… Rayo no está bien. En su casa no hay nadie nunca. No sé qué va a pasar.", If = NO_VAS },
		} },
	},
}
