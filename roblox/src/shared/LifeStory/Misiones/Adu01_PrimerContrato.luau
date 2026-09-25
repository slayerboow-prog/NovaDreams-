-- VIDA ADULTA 01 · «MI PRIMER CONTRATO» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.38.
--
-- Dos caminos según lo que elegiste al terminar el instituto:
--  * Con carrera (Graduado): tu primer trabajo de lo tuyo, donde hiciste las prácticas (si confesaste
--    tu error, te estaban esperando). Primer día, un primer caso con responsabilidad de verdad.
--  * Sin carrera (EmpiezaATrabajar): tu jefe del primer verano te ofrece un puesto fijo de encargado/a.
--    Si aún no tienes casa, la buscas (HomeClaimed).
-- En los dos: el primer sueldo completo y las primeras facturas (pagar ya, dejarlo para luego —y llega
-- un aviso 2 h después— o hacer un presupuesto con Ignacio en el banco).

local V = Vector3.new

local GRADUADO = { Flags = { "Graduado" } }
local TRABAJA = { NotFlags = { "Graduado" } }
local MED = { Flags = { "Graduado" }, Choices = { Estudios = "Medicina" } }
local ING = { Flags = { "Graduado" }, Choices = { Estudios = "Ingenieria" } }
local DER = { Flags = { "Graduado" }, Choices = { Estudios = "Derecho" } }
local ECO = { Flags = { "Graduado" }, Choices = { Estudios = "Economia" } }
local CAFE = { NotFlags = { "Graduado" }, Choices = { Empleo = "Barista" } }
local SUPER = { NotFlags = { "Graduado" }, Choices = { Empleo = "Reponedor" } }
local CORREOS = { NotFlags = { "Graduado" }, Choices = { Empleo = "Repartidor" } }

local JEFE = {
	{ Npc = "Nuria", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = MED },
	{ Npc = "Sofia", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = ING },
	{ Npc = "Montse", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = DER },
	{ Npc = "Ignacio", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = ECO },
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 5), If = CAFE },
	{ Npc = "Paco", Place = "Supermercado", Offset = V(0, 0, 5), If = SUPER },
	{ Npc = "Ernesto", Place = "Correos", Offset = V(0, 0, 5), If = CORREOS },
}

return {
	Id = "Adu01_PrimerContrato",
	Kind = "Main",
	Title = "Mi primer contrato",
	Description = "Un contrato de verdad, con tu nombre. Un primer día de adulto. Y las primeras facturas, que también llevan tu nombre.",
	Chapter = "Adulto_VolarDelNido",
	AgeRange = { 22, 23 },
	Duration = { 20, 30 },
	Difficulty = 2,
	Type = "Historia · Vida adulta",
	Npcs = { "Nuria", "Sofia", "Montse", "Ignacio", "Lola", "Paco", "Ernesto", "Omar", "Familia" },
	Locations = { "$Carrera.LugarPracticas", "CafeteriaCentral", "Supermercado", "Correos", "Banco" },
	Next = { "Adu02_Atardecer" },
	Outcomes = { "Trabajo de tu carrera o ascenso en tu trabajo", "Qué haces con las facturas" },

	Moment = "Tu primer contrato",
	Memory = "PrimerContrato",
	Rewards = { Money = 200, Items = { PrimeraNomina = 1 }, Flags = { "TieneHogar" },
		Later = { { AfterHours = 2, Start = "Eco_Factura", If = { Flags = { "FacturaPendiente" } } } } },

	Steps = {
		{ Type = "Transition", Text = "Septiembre. Un lunes cualquiera… que no es cualquiera.", Seconds = 3 },
		-- Si todavía vives con tu familia (sin carrera), toca independizarse
		{ Type = "Event", Event = "HomeClaimed", Text = "Busca una casa libre (cartel «Se vende») y quédatela: vas a necesitar tu propio sitio",
			If = { NotFlags = { "TieneHogar" } } },

		-- El primer día
		{ Type = "Reach", Place = "$Carrera.LugarPracticas", Text = "Primer día de trabajo: ve donde hiciste las prácticas", If = GRADUADO, Actors = JEFE,
			Late = { After = 300, Flags = { "LlegasTardeContrato" } } },
		{ Type = "Reach", Place = "CafeteriaCentral", Text = "Lola quiere hablar contigo en la cafetería", If = CAFE, Actors = JEFE },
		{ Type = "Reach", Place = "Supermercado", Text = "Paco quiere hablar contigo en el supermercado", If = SUPER, Actors = JEFE },
		{ Type = "Reach", Place = "Correos", Text = "Ernesto quiere hablar contigo en Correos", If = CORREOS, Actors = JEFE },
		{ Type = "Scene", Dialogue = "Contrato", Actors = JEFE },

		-- La jornada
		{ Type = "Class", Subject = "$Carrera.Practica", Mode = "Practica", Place = "$Carrera.LugarPracticas", Text = "Tu primer día como profesional", If = GRADUADO, Actors = JEFE },
		{ Type = "Scene", Dialogue = "PrimerCaso", If = GRADUADO, Actors = JEFE },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Barista" }, Count = 3, If = CAFE, Place = "CafeteriaCentral",
			Text = "Primer turno de encargado/a ({count}/{total})", Actors = JEFE },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Reponedor" }, Count = 3, If = SUPER, Place = "Supermercado",
			Text = "Primer turno de encargado/a ({count}/{total})", Actors = JEFE },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Repartidor" }, Count = 3, If = CORREOS, Place = "Correos",
			Text = "Primer turno de jefe/a de ruta ({count}/{total})", Actors = JEFE },
		{ Type = "Scene", Dialogue = "PrimerEquipo", If = TRABAJA, Actors = JEFE },

		-- Las facturas
		{ Type = "Transition", Text = "Final de mes…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Facturas" },
		{ Type = "Reach", Place = "Banco", Text = "Ve al banco: Ignacio te ayuda a hacer tu primer presupuesto", If = { Choices = { Facturas = "Presupuesto" } },
			Actors = { { Npc = "Ignacio", Place = "Banco", Offset = V(0, 0, 4) } } },
		{ Type = "Scene", Dialogue = "Presupuesto", If = { Choices = { Facturas = "Presupuesto" } },
			Actors = { { Npc = "Ignacio", Place = "Banco", Offset = V(0, 0, 4) } } },
		{ Type = "Scene", Dialogue = "Llamada" },
	},

	Dialogues = {
		Contrato = { Lines = {
			{ S = "Nuria", T = "¡Aquí está! Te estábamos esperando desde las prácticas. Bienvenida, bienvenido al equipo. Esta vez, con bata propia.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Medicina" } } },
			{ S = "Sofia", T = "¡Por fin! En TecnoVal nadie se ha olvidado de quién confesó su propio error. Tienes mesa, ordenador y un proyecto.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Ingenieria" } } },
			{ S = "Montse", T = "Te guardamos el despacho pequeño. El de la ventana. Aquí la honestidad se paga… bueno, se paga con un contrato.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Derecho" } } },
			{ S = "Ignacio", T = "La oficina te esperaba. Firma aquí. Y aquí. Y aquí. Los bancos adoramos las firmas.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Economia" } } },
			{ S = "Narrador", T = "Mandaste tu currículum a veinte sitios. Te llamaron de uno: el de tus prácticas. Aquí estás, con los nervios del primer día.", If = { Flags = { "Graduado" }, NotFlags = { "OfertaTrabajo" } } },
			{ S = "Lola", T = "Siéntate. Me jubilo el año que viene y necesito a alguien que lleve esto. Encargado o encargada. ¿Te atreves?", If = CAFE },
			{ S = "Paco", T = "Hmm. Siéntate. Llevas años aquí. Nunca una caja mal puesta. Quiero que seas encargado o encargada. No me hagas repetirlo.", If = SUPER },
			{ S = "Ernesto", T = "Necesito a alguien que lleve la ruta de todo Valmar. Conoces cada calle y cada perro. Jefe o jefa de ruta. ¿Aceptas?", If = CORREOS },
			{ S = "Narrador", T = "Firmas. Es tu nombre, en un contrato de verdad. Por primera vez, sin «de prácticas», sin «de verano»." },
		} },
		PrimerCaso = { Lines = {
			{ S = "Nuria", T = "Tu primer paciente sin supervisión directa. Estaré en la sala de al lado. Confío en ti.", If = MED },
			{ S = "Sofia", T = "La pasarela del río. ¿Te acuerdas? El ayuntamiento ha aprobado tu idea de los amortiguadores. Ahora hay que construirla.", If = ING },
			{ S = "Montse", T = "Tu primer cliente propio: el vecino de la multa. Ha vuelto. Otra multa. Dice que solo confía en ti.", If = DER },
			{ S = "Ignacio", T = "Marcos ha abierto la tienda de bicis de la playa. Va bien. Quiere otra. Tu primer cliente propio.", If = ECO },
			{ Ask = "¿Cómo lo afrontas?", Options = {
				{ T = "Pido consejo cuando dudo: preguntar no es de novatos", Effects = { Traits = { Responsabilidad = 1 }, Choice = { PrimerCaso = "Consejo" } }, Then = {
					{ S = "Narrador", T = "Preguntas dos veces. Las dos veces tu jefa te dice lo mismo: «Bien preguntado». Acabas el día con el caso resuelto." },
				} },
				{ T = "Me lanzo: sé más de lo que creo", Effects = { Traits = { Valentia = 1 }, Choice = { PrimerCaso = "Lanzarse" } }, Then = {
					{ S = "Narrador", T = "Te lanzas. Casi todo sale bien. Lo que no, lo arreglas por la tarde. Aprendes más en un día que en un semestre." },
				} },
			} },
		} },
		PrimerEquipo = { Lines = {
			{ S = "Omar", T = "(en la cocina) ¡Encargado o encargada! ¡Ya puedo decir que mi jefe es mi amigo! …Espera, eso no es bueno para mí.", If = CAFE },
			{ S = "Narrador", T = "Tu primer turno como responsable: organizas, ayudas, resuelves. Nadie se da cuenta de lo difícil que es. Salvo tú." },
			{ S = "Narrador", T = "Tu jefe o jefa te mira al final del turno y asiente. No dice nada. No hace falta." },
		} },
		Facturas = { Lines = {
			{ S = "Narrador", T = "Tu primer sueldo completo. Y, en el buzón, tres sobres: alquiler, luz y agua. Ser adulto viene con correo." },
			{ Ask = "¿Qué haces con las facturas?", Options = {
				{ T = "Pagarlas ya, todas", Effects = { Choice = { Facturas = "Pagar" }, Spend = 60, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Narrador", T = "Pagado. El sueldo baja bastante. Pero duermes tranquilo o tranquila." },
				} },
				{ T = "Dejarlas para la semana que viene", Effects = { Choice = { Facturas = "Luego" }, Flags = { "FacturaPendiente" } }, Then = {
					{ S = "Narrador", T = "Las dejas en la mesa. Encima de ellas pones una planta. Así no se ven. Eso lo arregla todo, seguro." },
				} },
				{ T = "Hacer un presupuesto: ¿cuánto entra y cuánto sale?", Effects = { Choice = { Facturas = "Presupuesto" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Narrador", T = "Buscas ayuda. En el banco hay alguien que conoces de las prácticas… o que te han recomendado." },
				} },
			} },
		} },
		Presupuesto = { Lines = {
			{ S = "Ignacio", T = "¡La persona de los números! Siéntate. Regla sencilla: la mitad para vivir, un tercio para lo que te guste y el resto, a ahorrar." },
			{ S = "Ignacio", T = "Las facturas, primero. Lo que queda, tuyo. Y un colchón para imprevistos, que siempre llegan." },
			{ S = "Narrador", T = "Salís con una hoja de colores. Pagas las facturas. Y hasta te sobra algo para ahorrar." },
		}, Effects = { Spend = 60, Traits = { Responsabilidad = 1 }, Rel = { Ignacio = 4 } } },
		Llamada = { Lines = {
			{ S = "Familia", T = "(al teléfono) ¿Qué tal el primer mes? ¿Has comido bien? ¿Has pagado las facturas? Perdona. No lo puedo evitar." },
			{ S = "Familia", T = "Oye… {abu} no está muy bien. Nada grave, creo. Pero te echa de menos. Pásate cuando puedas, ¿vale?" },
		} },
	},
}
