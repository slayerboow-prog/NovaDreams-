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

-- Escenas escritas a mano (Happenings/Adulto): la llegada el primer día, la firma, el primer turno al
-- mando y el buzón de final de mes. Con Adu_Escenas.paso, si el grupo de escenas aún no está registrado
-- se juegan como conversación con las mismas frases.

local Comun = require(script.Parent.Adu_Escenas)

local GRADUADO = Comun.GRADUADO
local TRABAJA = Comun.TRABAJA
local MED, ING, DER, ECO = Comun.MED, Comun.ING, Comun.DER, Comun.ECO
local CAFE, SUPER, CORREOS = Comun.CAFE, Comun.SUPER, Comun.CORREOS
local JEFE = Comun.JEFE
local V = Vector3.new

-- Una frase igual para el jefe de cada carrera (cada uno con su If)
local function jefesCarrera(texto: string, extra: { [string]: any }?): { { [string]: any } }
	local out = {}
	for _, pair in { { "Nuria", MED }, { "Sofia", ING }, { "Montse", DER }, { "Ignacio", ECO } } do
		local cond = table.clone(pair[2])
		cond.Flags = table.clone(cond.Flags)
		for k, v in extra or {} do
			if k == "Flags" then
				for _, f in v do
					table.insert(cond.Flags, f)
				end
			else
				cond[k] = v
			end
		end
		table.insert(out, { S = pair[1], T = texto, If = cond })
	end
	return out
end

local function juntar(...: { any }): { any }
	local out = {}
	for _, list in { ... } do
		for _, x in list do
			table.insert(out, x)
		end
	end
	return out
end

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
		Later = {
			{ AfterHours = 2, Start = "Eco_Factura", If = { Flags = { "FacturaPendiente" } } },
			-- Meses después, recortes: le toca a quien llegó tarde el primer día o mintió en su primera entrevista
			{ AfterHours = 3, Start = "Eco_Despido", If = { Flags = { "LlegasTardeContrato" } } },
			{ AfterHours = 3, Start = "Eco_Despido", If = { Flags = { "MentisteEntrevista" }, NotFlags = { "Graduado" } } },
		} },

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
		Comun.paso("Adu01_PrimerDia", JEFE),
		{ Type = "Scene", Dialogue = "Contrato", Actors = JEFE },
		Comun.paso("Adu01_Firma", JEFE),

		-- La jornada
		{ Type = "Class", Subject = "$Carrera.Practica", Mode = "Practica", Place = "$Carrera.LugarPracticas", Text = "Tu primer día como profesional", If = GRADUADO, Actors = JEFE },
		{ Type = "Scene", Dialogue = "PrimerCaso", If = GRADUADO, Actors = JEFE },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Barista" }, Count = 3, If = CAFE, Place = "CafeteriaCentral",
			Text = "Primer turno de encargado/a ({count}/{total})", Actors = JEFE },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Reponedor" }, Count = 3, If = SUPER, Place = "Supermercado",
			Text = "Primer turno de encargado/a ({count}/{total})", Actors = JEFE },
		{ Type = "Event", Event = "JobTaskDone", Match = { JobId = "Repartidor" }, Count = 3, If = CORREOS, Place = "Correos",
			Text = "Primer turno de jefe/a de ruta ({count}/{total})", Actors = JEFE },
		Comun.paso("Adu01_PrimerTurno", JEFE, { If = TRABAJA }),

		-- Las facturas
		{ Type = "Transition", Text = "Final de mes…", Seconds = 3 },
		Comun.paso("Adu01_Buzon"),
		{ Type = "Scene", Dialogue = "Facturas" },
		{ Type = "Reach", Place = "Banco", Text = "Ve al banco: Ignacio te ayuda a hacer tu primer presupuesto", If = { Choices = { Facturas = "Presupuesto" } },
			Actors = { { Npc = "Ignacio", Place = "Banco", Offset = V(0, 0, 4) } } },
		{ Type = "Scene", Dialogue = "Presupuesto", If = { Choices = { Facturas = "Presupuesto" } },
			Actors = { { Npc = "Ignacio", Place = "Banco", Offset = V(0, 0, 4) } } },
		{ Type = "Scene", Dialogue = "Llamada" },
	},

	Dialogues = {
		Contrato = { Lines = juntar({
			{ S = "Nuria", T = "¡Aquí está! Te esperábamos desde las prácticas. Bienvenid{o/a} al equipo. Esta vez, con bata propia.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Medicina" } } },
			{ S = "Sofia", T = "¡Por fin! En TecnoVal nadie se ha olvidado de quién confesó su propio error. Tienes mesa, ordenador y un proyecto.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Ingenieria" } } },
			{ S = "Montse", T = "Te guardamos el despacho pequeño. El de la ventana. Aquí la honestidad se paga… bueno, se paga con un contrato.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Derecho" } } },
			{ S = "Ignacio", T = "La oficina te esperaba. Firma aquí. Y aquí. Y aquí. Los bancos adoramos las firmas.", If = { Flags = { "Graduado", "OfertaTrabajo" }, Choices = { Estudios = "Economia" } } },
			-- Sin oferta de las prácticas: mandaste el currículum a veinte sitios y te llamaron de uno
			{ S = "Nuria", T = "Veinte currículums y vuelves aquí. Buena elección: en esta casa ya sabemos cómo trabajas.", If = { Flags = { "Graduado" }, NotFlags = { "OfertaTrabajo" }, Choices = { Estudios = "Medicina" } } },
			{ S = "Sofia", T = "Veinte currículums enviados y te llamamos nosotros. Ya sabíamos cómo trabajabas en las prácticas.", If = { Flags = { "Graduado" }, NotFlags = { "OfertaTrabajo" }, Choices = { Estudios = "Ingenieria" } } },
			{ S = "Montse", T = "De veinte sitios, solo uno te llamó. Este. Aquí no olvidamos a quien trabaja bien.", If = { Flags = { "Graduado" }, NotFlags = { "OfertaTrabajo" }, Choices = { Estudios = "Derecho" } } },
			{ S = "Ignacio", T = "Veinte currículums. Una respuesta. Estadísticamente, un cinco por ciento. Personalmente, un cien.", If = { Flags = { "Graduado" }, NotFlags = { "OfertaTrabajo" }, Choices = { Estudios = "Economia" } } },
			{ S = "Lola", T = "Siéntate. Me jubilo el año que viene y necesito a alguien que lleve esto. Encargad{o/a}. ¿Te atreves?", If = CAFE },
			{ S = "Paco", T = "Hmm. Siéntate. Llevas años aquí. Nunca una caja mal puesta. Quiero que seas encargad{o/a}. No me hagas repetirlo.", If = SUPER },
			{ S = "Ernesto", T = "Necesito a alguien que lleve la ruta de todo Valmar. Conoces cada calle y cada perro. Jef{e/a} de ruta. ¿Aceptas?", If = CORREOS },
			{ S = "Lola", T = "Sé lo del estadio. Y lo de la comisaría. Todo Valmar lo sabe. Aun así, confío en ti. No me hagas arrepentirme.", If = { Flags = { "Antecedentes" }, NotFlags = { "Graduado" }, Choices = { Empleo = "Barista" } } },
		}, jefesCarrera("En la entrevista nos contaste lo de tu expediente de menores. Todo. Te contratamos por cómo lo contaste.", { Flags = { "Antecedentes" } })) },
		PrimerCaso = { Lines = {
			{ S = "Nuria", T = "Tu primer paciente sin supervisión directa. Estaré en la sala de al lado. Confío en ti.", If = MED },
			{ S = "Sofia", T = "La pasarela del río. ¿Te acuerdas? El ayuntamiento ha aprobado tu idea de los amortiguadores. Ahora hay que construirla.", If = ING },
			{ S = "Montse", T = "Tu primer cliente propio: el vecino de la multa. Ha vuelto. Otra multa. Dice que solo confía en ti.", If = DER },
			{ S = "Ignacio", T = "Marcos ha abierto la tienda de bicis de la playa. Va bien. Quiere otra. Tu primer cliente propio.", If = ECO },
			{ Ask = "¿Cómo lo afrontas?", Options = {
				{ T = "Pido consejo cuando dudo: preguntar no es de novatos", Effects = { Traits = { Responsabilidad = 1 }, Choice = { PrimerCaso = "Consejo" } },
					Then = jefesCarrera("Bien preguntado. …Y esa también, bien preguntada. Caso resuelto antes de comer.") },
				{ T = "Me lanzo: sé más de lo que creo", Effects = { Traits = { Valentia = 1 }, Choice = { PrimerCaso = "Lanzarse" } },
					Then = jefesCarrera("Casi todo bien. Lo que no, lo has arreglado por la tarde. Hoy has aprendido más que en un semestre.") },
			} },
		} },
		Facturas = { Lines = {
			{ Ask = "¿Qué haces con las facturas?", Options = {
				{ T = "Pagarlas ya, todas", Effects = { Choice = { Facturas = "Pagar" }, Spend = 60, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Yo", T = "Pagado. El sueldo ha adelgazado bastante. Pero esta noche duermo tranquil{o/a}." },
				} },
				{ T = "Dejarlas para la semana que viene", Effects = { Choice = { Facturas = "Luego" }, Flags = { "FacturaPendiente" } }, Then = {
					{ S = "Yo", T = "Las dejo en la mesa. Encima, una planta. Así no se ven. Problema resuelto. Seguro." },
				} },
				{ T = "Hacer un presupuesto: ¿cuánto entra y cuánto sale?", Effects = { Choice = { Facturas = "Presupuesto" }, Traits = { Curiosidad = 1 } }, Then = {
					{ S = "Yo", T = "Mejor pido ayuda. En el banco está Ignacio, el de los números." },
				} },
			} },
		} },
		Presupuesto = { Lines = {
			{ S = "Ignacio", T = "¡La persona de los números! Siéntate. Regla sencilla: la mitad para vivir, un tercio para lo que te guste y el resto, a ahorrar." },
			{ S = "Ignacio", T = "Las facturas, primero. Lo que queda, tuyo. Y un colchón para imprevistos, que siempre llegan." },
			{ S = "Ignacio", T = "Mira: una hoja de colores. Facturas pagadas y hasta sobra para ahorrar. Los números, cuando se ordenan, son preciosos." },
		}, Effects = { Spend = 60, Traits = { Responsabilidad = 1 }, Rel = { Ignacio = 4 } } },
		Llamada = { Lines = {
			{ S = "Familia", T = "(al teléfono) ¿Qué tal el primer mes? ¿Has comido bien? ¿Has pagado las facturas? Perdona. No lo puedo evitar." },
			{ S = "Familia", T = "Oye… {abu} no está muy bien. Nada grave, creo. Pero te echa de menos. Pásate cuando puedas, ¿vale?" },
		} },
	},
}
