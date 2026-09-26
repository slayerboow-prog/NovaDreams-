-- INSTITUTO 04 · «EL PRIMER EMPLEO» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.27.
--
-- Quieres algo (una bici, una cámara, ayudar en casa, ahorrar) → taller de primer empleo con Carmen:
-- tu perfil → buscar ofertas por la ciudad (cafetería, supermercado, Correos) → elegir → entrevista
-- (decir la verdad o adornarla) → primer día: llegar puntual → la primera jornada con el sistema de
-- trabajos de verdad (3 tareas) y un imprevisto en mitad del turno → el primer sueldo: qué haces con él.
-- Si trabajaste bien y no mentiste, 3 h después llega una carta de recomendación (Eco_Carta).

local V = Vector3.new

local CAFETERIA = { Choices = { Empleo = "Barista" } }
local SUPER = { Choices = { Empleo = "Reponedor" } }
local CORREOS = { Choices = { Empleo = "Repartidor" } }
local MINTIO = { Flags = { "MentisteEntrevista" } }

local CASA = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2) },
}
local JEFES = {
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 4) },
	{ Npc = "Paco", Place = "Supermercado", Offset = V(0, 0, 4) },
	{ Npc = "Ernesto", Place = "Correos", Offset = V(0, 0, 4) },
}
local function jefe(npc: string, place: string, cond: any): any
	return { Npc = npc, Place = place, Offset = V(0, 0, 4), If = cond }
end
local TRABAJO = {
	jefe("Lola", "CafeteriaCentral", CAFETERIA),
	jefe("Paco", "Supermercado", SUPER),
	jefe("Ernesto", "Correos", CORREOS),
}

return {
	Id = "Ins04_PrimerEmpleo",
	Kind = "Main",
	Title = "El primer empleo",
	Description = "Llega el verano y quieres algo que cuesta dinero. Toca buscar tu primer trabajo: perfil, ofertas, entrevista… y el primer sueldo.",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 14, 15 },
	Duration = { 20, 30 },
	Difficulty = 2,
	Type = "Historia · Trabajo",
	Requires = { Completed = { "Pan2_LaNoche" }, StageProgress = 0.44 },
	Npcs = { "Familia", "Abu", "Carmen", "Omar", "Lola", "Paco", "Ernesto", "Bruno", "Leire" },
	Locations = { "HomeSalon", "AulaInstituto", "CafeteriaCentral", "Supermercado", "Correos" },
	Next = { "Pan3_Cruce" },
	Outcomes = { "Qué trabajo eliges", "Verdad o mentira en la entrevista", "Qué haces con tu primer sueldo" },

	Moment = "Tu primer sueldo",
	Memory = "PrimerSueldo",
	Rewards = { Money = 50, Items = { PrimerSobre = 1 }, Later = {
		{ AfterHours = 3, Start = "Eco_Carta", If = { NotFlags = { "MentisteEntrevista" } } },
	} },

	Props = {
		OfertaCafe = { Kind = "Papel", Name = "Cartel: «Se busca ayudante»", Prompt = "Leer", Place = "CafeteriaCentral", Offset = V(-3, 0, 3), Dialogue = "Oferta_Cafe", Once = true },
		OfertaSuper = { Kind = "Papel", Name = "Cartel: «Se busca reponedor/a»", Prompt = "Leer", Place = "Supermercado", Offset = V(-3, 0, 3), Dialogue = "Oferta_Super", Once = true },
		OfertaCorreos = { Kind = "Papel", Name = "Cartel: «Repartidores de verano»", Prompt = "Leer", Place = "Correos", Offset = V(-3, 0, 3), Dialogue = "Oferta_Correos", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Un año después. Llega el verano…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Deseo", Teleport = "HomeSalon", Actors = CASA },
		{ Type = "Reach", Place = "AulaInstituto", Text = "Ve al instituto: taller de primer empleo con Carmen",
			Actors = { { Npc = "Carmen", Place = "AulaInstituto", Offset = V(0, 0, -6) }, { Npc = "Omar", Place = "AulaInstituto", Offset = V(3, 0, 0) } } },
		{ Type = "Scene", Dialogue = "Perfil",
			Actors = { { Npc = "Carmen", Place = "AulaInstituto", Offset = V(0, 0, -6) }, { Npc = "Omar", Place = "AulaInstituto", Offset = V(3, 0, 0) } } },

		-- Buscar ofertas
		{ Type = "Group", Text = "Busca ofertas por la ciudad (al menos dos)", Need = 2,
			Steps = {
				{ Type = "Use", Prop = "OfertaCafe", Text = "La Cafetería Central" },
				{ Type = "Use", Prop = "OfertaSuper", Text = "El supermercado" },
				{ Type = "Use", Prop = "OfertaCorreos", Text = "Correos" },
			},
			Actors = JEFES },
		{ Type = "Choice", Key = "Empleo", Text = "¿Dónde quieres trabajar? (habla con quien contrata)",
			Options = {
				{ Id = "Barista", Npc = "Lola", Text = "Cafetería: servir cafés con Lola", Dialogue = "Entrevista_Lola" },
				{ Id = "Reponedor", Npc = "Paco", Text = "Supermercado: reponer con Paco", Dialogue = "Entrevista_Paco" },
				{ Id = "Repartidor", Npc = "Ernesto", Text = "Correos: repartir paquetes con Ernesto", Dialogue = "Entrevista_Ernesto" },
			},
			Actors = JEFES },

		-- Primer día
		{ Type = "Transition", Text = "El lunes, a las nueve en punto…", Seconds = 3 },
		{ Type = "Reach", Place = "CafeteriaCentral", Text = "Primer día: llega puntual a la cafetería", If = CAFETERIA, Actors = TRABAJO,
			Late = { After = 240, Flags = { "LlegasTardeTrabajo" } } },
		{ Type = "Reach", Place = "Supermercado", Text = "Primer día: llega puntual al supermercado", If = SUPER, Actors = TRABAJO,
			Late = { After = 240, Flags = { "LlegasTardeTrabajo" } } },
		{ Type = "Reach", Place = "Correos", Text = "Primer día: llega puntual a Correos", If = CORREOS, Actors = TRABAJO,
			Late = { After = 240, Flags = { "LlegasTardeTrabajo" } } },
		{ Type = "Scene", Dialogue = "PrimerDia", Actors = TRABAJO },

		-- La jornada: el sistema de trabajos de verdad
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Barista" }, Count = 2, If = CAFETERIA, Place = "CafeteriaCentral",
			Text = "Empieza el turno (tablón de trabajo) y sirve cafés ({count}/{total})", Actors = TRABAJO },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Reponedor" }, Count = 2, If = SUPER, Place = "Supermercado",
			Text = "Empieza el turno (tablón de trabajo) y repón cajas ({count}/{total})", Actors = TRABAJO },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Repartidor" }, Count = 2, If = CORREOS, Place = "Correos",
			Text = "Empieza el turno (tablón de trabajo) y reparte paquetes ({count}/{total})", Actors = TRABAJO },
		{ Type = "Scene", Dialogue = "Imprevisto", Actors = {
			jefe("Lola", "CafeteriaCentral", CAFETERIA), jefe("Paco", "Supermercado", SUPER), jefe("Ernesto", "Correos", CORREOS),
			{ Npc = "Bruno", Place = "CercaDeTi", Offset = V(3, 0, -3), If = CAFETERIA },
			{ Npc = "Leire", Place = "CercaDeTi", Offset = V(3, 0, -3), If = CORREOS },
		} },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Barista" }, Count = 2, If = CAFETERIA, Place = "CafeteriaCentral",
			Text = "Termina el turno ({count}/{total})", Actors = TRABAJO },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Reponedor" }, Count = 2, If = SUPER, Place = "Supermercado",
			Text = "Termina el turno ({count}/{total})", Actors = TRABAJO },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Repartidor" }, Count = 2, If = CORREOS, Place = "Correos",
			Text = "Termina el turno ({count}/{total})", Actors = TRABAJO },

		-- El primer sueldo
		{ Type = "Scene", Dialogue = "Sueldo", Actors = TRABAJO },
		{ Type = "Transition", Text = "Esa noche…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Cena", Teleport = "HomeSalon", Actors = CASA },
	},

	Dialogues = {
		Deseo = { Lines = {
			{ S = "Familia", T = "¿Otra vez mirando eso en el móvil? A ver… Ya veo. Es precioso. Y caro." },
			{ Ask = "¿Qué quieres conseguir este verano?", Options = {
				{ T = "Una bici de verdad, para ir a todas partes", Effects = { Choice = { Meta = "Bici" } } },
				{ T = "Una cámara, como la de Leire", Effects = { Choice = { Meta = "Camara" } } },
				{ T = "Ayudar en casa: las cosas están caras", Effects = { Choice = { Meta = "Casa" }, Traits = { Responsabilidad = 1 }, Rel = { Familia = 4 } } },
				{ T = "Ahorrar para cuando vaya a la universidad", Effects = { Choice = { Meta = "Ahorro" }, Traits = { Responsabilidad = 1 } } },
			} },
			{ S = "Familia", T = "Pues ¿sabes qué hacía yo a tu edad? Trabajar en verano. Unas horas. Se aprende muchísimo." },
			{ S = "Abu", T = "Y el primer sueldo… ese no se olvida nunca. Yo me compré unos zapatos. Me duraron diez años." },
		} },
		Perfil = { Lines = {
			{ S = "Carmen", T = "Taller de primer empleo. Un perfil laboral es contar quién eres en pocas líneas. Sin mentir y sin esconderte." },
			{ S = "Omar", T = "Yo he puesto: «Soy muy bueno comiendo». Carmen dice que eso no es una habilidad. Discrepo." },
			{ Ask = "¿Qué pones como tu punto fuerte?", Options = {
				{ T = "Soy responsable: si digo que voy, voy", Effects = { Choice = { Perfil = "Responsable" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Carmen", T = "Es lo que más buscan. En serio: más que saber hacer cosas." },
				} },
				{ T = "Trato bien a la gente", Effects = { Choice = { Perfil = "Gente" }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Carmen", T = "Perfecto para trabajar de cara al público." },
				} },
				{ T = "Aprendo rápido", Effects = { Choice = { Perfil = "Aprendo" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Carmen", T = "Muy bien. Y ponlo con un ejemplo: tu club, un proyecto…" },
				} },
			} },
			{ S = "Carmen", T = "Tu club también cuenta. Y lo que hiciste en la semana de las profesiones. Todo lo que has vivido es experiencia." },
			{ S = "Carmen", T = "Ahora a buscar. Hay carteles de «Se busca» en la cafetería del centro, en el supermercado y en Correos." },
		} },
		Oferta_Cafe = { Lines = { { S = "Narrador", T = "«Se busca ayudante de verano. Mañanas. Buena sonrisa y pulso firme con las bandejas. Preguntar por Lola.»" } } },
		Oferta_Super = { Lines = { { S = "Narrador", T = "«Se busca reponedor/a. Fuerza, orden y paciencia. Paga semanal. Preguntar por Paco. NO preguntar por las cajas de arriba.»" } } },
		Oferta_Correos = { Lines = { { S = "Narrador", T = "«Repartidores de verano. Se valora conocer la ciudad y no tener miedo a los perros. Mejor paga. Preguntar por Ernesto.»" } } },

		Entrevista_Lola = { Lines = {
			{ S = "Lola", T = "¡Anda, si es mi visita de la semana de las profesiones! Siéntate. Entrevista rápida, que tengo cruasanes en el horno.", If = { Flags = { "Interes_Cocina" } } },
			{ S = "Lola", T = "Siéntate. Entrevista rápida, que tengo cruasanes en el horno.", If = { NotFlags = { "Interes_Cocina" } } },
			{ Ask = "«¿Has trabajado antes en una cafetería?»", Options = {
				{ T = "«No, pero aprendo rápido y tengo ganas»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Lola", T = "La verdad. Me gusta. Aquí todos empezamos sin saber. Yo quemé tres cafeteras." },
				} },
				{ T = "«Sí, mucho» (no es verdad)", Effects = { Flags = { "MentisteEntrevista" } }, Then = {
					{ S = "Lola", T = "¿Ah, sí? Estupendo. Entonces mañana no te explico nada." },
				} },
			} },
			{ S = "Lola", T = "Última pregunta: un cliente te grita porque su café está frío. ¿Qué haces?" },
			{ Ask = "¿Qué contestas?", Options = {
				{ T = "«Le pido perdón y le hago otro»", Effects = { Traits = { Empatia = 1 } }, Then = {
					{ S = "Lola", T = "Correcto. Aunque tenga la culpa él. Luego, en la cocina, te quejas conmigo." },
				} },
				{ T = "«Le explico con calma que acaba de salir»", Effects = { Traits = { Valentia = 1 } }, Then = {
					{ S = "Lola", T = "Con calma, vale. Pero la próxima vez, hazle otro. Es más rápido." },
				} },
			} },
			{ S = "Lola", T = "Contratado o contratada, lo que te toque. Lunes, nueve en punto. Ni nueve y cinco." },
		} },
		Entrevista_Paco = { Lines = {
			{ S = "Paco", T = "Hmm. Joven. Siéntate. No, ahí no, que es una caja de tomates.", If = { NotFlags = { "Hurto" } } },
			{ S = "Paco", T = "Hmm. Tú. Te conozco: lo del almacén. Me pediste perdón mirando a los ojos. Todo el mundo merece una segunda oportunidad. Una.", If = { Flags = { "Hurto", "PerdonPaco" } } },
			{ S = "Paco", T = "Hmm. Tú. Te llevaste mis latas y ni pediste perdón. …Te contrato igual, porque no encuentro a nadie. Pero te vigilo. Mucho.", If = { Flags = { "Hurto" }, NotFlags = { "PerdonPaco" } } },
			{ Ask = "«¿Has trabajado antes?»", Options = {
				{ T = "«No, pero soy de fiar»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Paco", T = "Hmm. De fiar. Eso ya lo veremos. Pero me gusta que no me cuentes historias." },
				} },
				{ T = "«Sí, en un supermercado enorme» (no es verdad)", Effects = { Flags = { "MentisteEntrevista" } }, Then = {
					{ S = "Paco", T = "¿Enorme? Hmm. Ya veremos lo enorme que era." },
				} },
			} },
			{ S = "Paco", T = "Aquí la regla es una: lo pesado abajo, lo frágil arriba. Si lo haces al revés, lo pagan los huevos." },
			{ S = "Paco", T = "Lunes a las nueve. Con zapatillas cómodas. Hmm." },
		} },
		Entrevista_Ernesto = { Lines = {
			{ S = "Ernesto", T = "¿Conoces Valmar? Te pongo a prueba: ¿dónde está la farmacia?" },
			{ Ask = "¿Qué contestas?", Options = {
				{ T = "«Al lado de la librería, donde hacía los recados de pequeño o pequeña»", Effects = { Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Ernesto", T = "¡Exacto! Los recados de niño son la mejor escuela de repartidor." },
				} },
				{ T = "«Ni idea, pero tengo mapa en el móvil»", Effects = { Traits = { Humor = 1 } }, Then = {
					{ S = "Ernesto", T = "Sincero. Y práctico. El móvil falla, eh. Los perros no." },
				} },
			} },
			{ Ask = "«¿Has repartido antes?»", Options = {
				{ T = "«No. Pero voy andando a todas partes»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Ernesto", T = "Bien. Piernas y verdad. Con eso me vale." },
				} },
				{ T = "«Sí, muchísimo» (no es verdad)", Effects = { Flags = { "MentisteEntrevista" } }, Then = {
					{ S = "Ernesto", T = "¿Muchísimo? Qué bien. Entonces el lunes te doy la ruta difícil." },
				} },
			} },
			{ S = "Ernesto", T = "Lunes a las nueve. Y un consejo: el perro del número 12 ladra, pero no muerde. El del 14, al revés." },
		} },

		PrimerDia = { Lines = {
			{ S = "Lola", T = "Llegas tarde el primer día. Hmm. Que no se repita. ¡Delantal!", If = { Flags = { "LlegasTardeTrabajo" }, Choices = { Empleo = "Barista" } } },
			{ S = "Paco", T = "Las nueve y cuarto. Hmm. En este súper, las nueve son las nueve.", If = { Flags = { "LlegasTardeTrabajo" }, Choices = { Empleo = "Reponedor" } } },
			{ S = "Ernesto", T = "Los paquetes no esperan, y tú has llegado tarde. Venga, que aún llegamos.", If = { Flags = { "LlegasTardeTrabajo" }, Choices = { Empleo = "Repartidor" } } },
			{ S = "Lola", T = "¡Puntual! Así me gusta. Mira: cafetera, bandeja, mesas. Café en la mesa que te marque. Sonrisa siempre.", If = { NotFlags = { "LlegasTardeTrabajo" }, Choices = { Empleo = "Barista" } } },
			{ S = "Paco", T = "Puntual. Hmm. Bien. Almacén, cajas, estanterías. Lo pesado abajo. Ya lo sabes.", If = { NotFlags = { "LlegasTardeTrabajo" }, Choices = { Empleo = "Reponedor" } } },
			{ S = "Ernesto", T = "¡Puntual! Así da gusto. Recoge los paquetes aquí y llévalos al buzón que te marque el mapa.", If = { NotFlags = { "LlegasTardeTrabajo" }, Choices = { Empleo = "Repartidor" } } },
			{ S = "Lola", T = "…Y como tienes TANTA experiencia, hoy te las apañas sin explicaciones. ¿No? ¿Seguro?", If = { Flags = { "MentisteEntrevista" }, Choices = { Empleo = "Barista" } } },
			{ S = "Paco", T = "El que ha trabajado en un súper enorme sabe dónde van las cajas. Adelante. Hmm.", If = { Flags = { "MentisteEntrevista" }, Choices = { Empleo = "Reponedor" } } },
			{ S = "Ernesto", T = "Ruta difícil para quien tiene muchísima experiencia. Suerte con el perro del 14.", If = { Flags = { "MentisteEntrevista" }, Choices = { Empleo = "Repartidor" } } },
			{ S = "Narrador", T = "Busca el tablón de trabajo del sitio y empieza tu turno." },
		} },
		Imprevisto = { Lines = {
			{ S = "Narrador", T = "¡CRASH! Se te cae una bandeja entera. Y el cliente de la mesa es… Bruno.", If = CAFETERIA },
			{ S = "Bruno", T = "¿Tú? ¿Aquí? Jajaja. No, espera. No me río. Bueno, un poco. ¿Te ayudo a recoger?", If = CAFETERIA },
			{ S = "Narrador", T = "Al colocar una caja, la torre de latas de arriba se tambalea… y cae. Treinta latas rodando por el pasillo.", If = SUPER },
			{ S = "Narrador", T = "Un paquete pone «Leire». Llamas al timbre. Abre Leire, en pijama.", If = CORREOS },
			{ S = "Leire", T = "…No has visto nada. No me has visto en pijama. Dame el paquete. Es una lente nueva. Gracias. Adiós.", If = CORREOS },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Lo cuentas tal cual a tu jefe y lo arreglas", Effects = { Flags = { "BuenTrabajo" }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Lola", T = "Se cae todo el mundo. Lo importante es que me lo digas. Recoge y sigue.", If = CAFETERIA },
					{ S = "Paco", T = "Hmm. Treinta latas. Ninguna rota. Y me lo has dicho tú. Bien. Muy bien, incluso.", If = SUPER },
					{ S = "Ernesto", T = "¿Que la del paquete era una amiga? Pues entrega perfecta y discreta. Así se hace.", If = CORREOS },
				} },
				{ T = "Te lo tomas con humor y sigues", Effects = { Traits = { Humor = 1 } }, Then = {
					{ S = "Bruno", T = "Esto lo cuento en clase. Es broma. …O no. Te dejo propina. Por el espectáculo.", If = CAFETERIA },
					{ S = "Narrador", T = "Haces una reverencia a los clientes que miran. Alguien aplaude. Paco no.", If = SUPER },
					{ S = "Narrador", T = "Le deseas a Leire un buen día «en su precioso pijama de nubes». Te cierra la puerta. Oyes cómo se ríe detrás.", If = CORREOS },
				} },
			} },
		} },
		Sueldo = { Lines = {
			{ S = "Lola", T = "Toma. Tu primer sobre. Te lo has ganado. Bueno, casi todo: la bandeja la descuento en abrazos.", If = CAFETERIA },
			{ S = "Paco", T = "Tu paga. Hmm. Has trabajado bien. Para ser la primera vez. No te acostumbres a que lo diga.", If = SUPER },
			{ S = "Ernesto", T = "Tu primer sueldo de repartidor. Ni un paquete perdido. Y el perro del 14 te ha cogido cariño.", If = CORREOS },
			{ S = "Narrador", T = "Un sobre con tu nombre. Dentro, el primer dinero que has ganado tú. Pesa poco. Parece que pesa mucho." },
			{ Ask = "¿Qué haces con él?", Options = {
				{ T = "Guardarlo para lo que querías", Effects = { Choice = { Sueldo = "Meta" }, Traits = { Responsabilidad = 1 } } },
				{ T = "Invitar a tu familia a cenar fuera", Effects = { Choice = { Sueldo = "Familia" }, Rel = { Familia = 8, Abu = 6 }, Traits = { Empatia = 1 } } },
				{ T = "Una parte para ti, otra para ahorrar", Effects = { Choice = { Sueldo = "Mitad" }, Traits = { Responsabilidad = 1 } } },
			} },
		} },
		Cena = { Lines = {
			{ S = "Familia", T = "¡{nombre}, con sueldo! ¿Cómo ha sido? Cuéntalo todo." },
			{ S = "Familia", T = "¿Que nos invitas a cenar? No hacía falta… Pero ya que insistes, yo quiero postre.", If = { Choices = { Sueldo = "Familia" } } },
			{ S = "Abu", T = "¿Ves? Ese sobre no se olvida. Dentro de cincuenta años te acordarás de hoy." },
			{ S = "Familia", T = "Y oye: lo de la entrevista… ¿dijiste la verdad? Porque las mentiras en el trabajo tienen patas muy cortas.", If = MINTIO },
			{ S = "Narrador", T = "Esa noche guardas el sobre vacío en un cajón. No sabes por qué. Pero lo guardas." },
		} },
	},
}
