-- UNIVERSIDAD 04 · «LAS PRÁCTICAS» (30-40 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.34.
--
-- Las prácticas dependen de la carrera ("$Carrera.LugarPracticas"): Medicina en el hospital con Nuria,
-- Ingeniería con Sofía, Derecho en el bufete con Montse, Economía en el banco con Ignacio. Primer día →
-- primera jornada (Class Practica) → el caso: tres tareas propias de cada carrera → un error tuyo en el
-- informe (decirlo, arreglarlo en silencio o dejarlo) → segunda jornada → la evaluación del tutor. Si
-- fuiste honesto u honesta y trabajaste bien: una oferta de trabajo para cuando termines.

local V = Vector3.new

local MED = { Choices = { Estudios = "Medicina" } }
local ING = { Choices = { Estudios = "Ingenieria" } }
local DER = { Choices = { Estudios = "Derecho" } }
local ECO = { Choices = { Estudios = "Economia" } }
local CONFESADO = { Choices = { ErrorInforme = "Decir" } }

local TUTOR = {
	{ Npc = "Nuria", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = MED },
	{ Npc = "Sofia", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = ING },
	{ Npc = "Montse", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = DER },
	{ Npc = "Ignacio", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = ECO },
}
local CASO = table.clone(TUTOR)
table.insert(CASO, { Npc = "Paciente", Place = "$Carrera.LugarPracticas", Offset = V(-5, 0, 3), If = MED, Mode = "Sit" })
table.insert(CASO, { Npc = "Vecino", Place = "$Carrera.LugarPracticas", Offset = V(-5, 0, 3), If = DER })
table.insert(CASO, { Npc = "Marcos", Place = "$Carrera.LugarPracticas", Offset = V(-5, 0, 3), If = ECO })

-- Tres tareas para cada carrera (objetos que solo existen en la tuya)
local function tarea(name: string, prompt: string, offset: Vector3, dialogue: string, cond: any): any
	return { Kind = "Marcador", Name = name, Prompt = prompt, Place = "$Carrera.LugarPracticas", Offset = offset, Dialogue = dialogue, Once = true, If = cond }
end

return {
	Id = "Uni04_Practicas",
	Kind = "Main",
	Title = "Las prácticas",
	Description = "Por primera vez, lo que estudias pasa en el mundo real. Un tutor, un caso de verdad… y un error que nadie ha visto todavía.",
	Chapter = "Joven_Universidad",
	AgeRange = { 20, 21 },
	Duration = { 30, 40 },
	Difficulty = 3,
	Type = "Historia · Prácticas",
	Requires = { Completed = { "Uni03_PrimerTrabajo" }, StageProgress = 0.55 },
	Npcs = { "Nuria", "Sofia", "Montse", "Ignacio", "Paciente", "Vecino", "Marcos" },
	Locations = { "$Carrera.LugarPracticas" },
	Next = { "Uni05_PrimerPiso" },
	Outcomes = { "Un caso distinto para cada carrera", "Qué haces con tu error", "Oferta de trabajo o no" },

	Moment = "Tus primeras prácticas",
	Memory = "Practicas",
	Rewards = { Money = 150, Items = { InformePracticas = 1 } },

	Props = {
		-- Medicina
		Historial = tarea("Historial del paciente", "Leer", V(4, 0, 3), "Med_Historial", MED),
		Exploracion = tarea("Camilla", "Explorar", V(-4, 0, 1), "Med_Exploracion", MED),
		Analisis = tarea("Resultados del análisis", "Revisar", V(6, 0, -2), "Med_Analisis", MED),
		-- Ingeniería
		Inspeccion = tarea("La pasarela del río (maqueta)", "Inspeccionar", V(4, 0, 3), "Ing_Inspeccion", ING),
		Materiales = tarea("Muestras de materiales", "Comparar", V(-4, 0, 1), "Ing_Materiales", ING),
		Planos = tarea("Mesa de planos", "Diseñar", V(6, 0, -2), "Ing_Planos", ING),
		-- Derecho
		Expediente = tarea("El expediente del caso", "Leer", V(4, 0, 3), "Der_Expediente", DER),
		Testigo = tarea("Declaración del testigo", "Analizar", V(-4, 0, 1), "Der_Testigo", DER),
		Leyes = tarea("Estantería de leyes", "Buscar", V(6, 0, -2), "Der_Leyes", DER),
		-- Economía
		Cuentas = tarea("Las cuentas de la empresa", "Revisar", V(4, 0, 3), "Eco_Cuentas", ECO),
		Mercado = tarea("Estudio de mercado", "Analizar", V(-4, 0, 1), "Eco_Mercado", ECO),
		Riesgo = tarea("Informe de riesgos", "Calcular", V(6, 0, -2), "Eco_Riesgo", ECO),
	},

	Steps = {
		{ Type = "Transition", Text = "Tercer curso. Empiezan las prácticas.", Seconds = 3 },
		{ Type = "Reach", Place = "$Carrera.LugarPracticas", Text = "Ve al sitio de tus prácticas", Actors = TUTOR,
			Late = { After = 300, Flags = { "LlegasTardePracticas" } } },
		{ Type = "Scene", Dialogue = "Bienvenida", Actors = TUTOR },
		{ Type = "Class", Subject = "$Carrera.Practica", Mode = "Practica", Place = "$Carrera.LugarPracticas", Text = "Primera jornada de prácticas", Actors = TUTOR },

		-- El caso
		{ Type = "Scene", Dialogue = "Caso", Actors = CASO },
		{ Type = "Group", Text = "Trabaja en el caso",
			Steps = {
				{ Type = "Use", Prop = "Historial", Text = "Lee el historial", If = MED },
				{ Type = "Use", Prop = "Exploracion", Text = "Explora al paciente (con Nuria)", If = MED },
				{ Type = "Use", Prop = "Analisis", Text = "Revisa los análisis", If = MED },
				{ Type = "Use", Prop = "Inspeccion", Text = "Inspecciona la pasarela", If = ING },
				{ Type = "Use", Prop = "Materiales", Text = "Compara materiales", If = ING },
				{ Type = "Use", Prop = "Planos", Text = "Diseña la solución", If = ING },
				{ Type = "Use", Prop = "Expediente", Text = "Lee el expediente", If = DER },
				{ Type = "Use", Prop = "Testigo", Text = "Analiza la declaración", If = DER },
				{ Type = "Use", Prop = "Leyes", Text = "Busca la ley que se aplica", If = DER },
				{ Type = "Use", Prop = "Cuentas", Text = "Revisa las cuentas", If = ECO },
				{ Type = "Use", Prop = "Mercado", Text = "Analiza el mercado", If = ECO },
				{ Type = "Use", Prop = "Riesgo", Text = "Calcula el riesgo", If = ECO },
			},
			Effects = { Traits = { Curiosidad = 1 } }, Actors = CASO },
		{ Type = "Scene", Dialogue = "Error", Actors = TUTOR },
		{ Type = "Class", Subject = "$Carrera.Practica", Mode = "Practica", Place = "$Carrera.LugarPracticas", Text = "Segunda jornada: presenta tu informe",
			Bonus = { If = CONFESADO, Seconds = 4 }, Actors = TUTOR },
		{ Type = "Scene", Dialogue = "Evaluacion", Actors = TUTOR },
	},

	Dialogues = {
		Bienvenida = { Lines = {
			{ S = "Nuria", T = "¡Anda! ¡La persona de la semana de las profesiones! Te dije que te guardaría el sitio. Bienvenida, bienvenido a urgencias.", If = { Flags = { "Interes_Medicina" }, Choices = { Estudios = "Medicina" } } },
			{ S = "Nuria", T = "Bienvenida, bienvenido a urgencias. Soy Nuria. Aquí se aprende rápido o se aprende corriendo.", If = { NotFlags = { "Interes_Medicina" }, Choices = { Estudios = "Medicina" } } },
			{ S = "Sofia", T = "¡La persona de los triángulos! Ahora trabajo para TecnoVal, y adivina: eres mi estudiante en prácticas.", If = { Flags = { "Interes_Ingenieria" }, Choices = { Estudios = "Ingenieria" } } },
			{ S = "Sofia", T = "Soy Sofía, ingeniera de TecnoVal. Aquí rompemos cosas para que no se rompan. Bienvenida, bienvenido.", If = { NotFlags = { "Interes_Ingenieria" }, Choices = { Estudios = "Ingenieria" } } },
			{ S = "Montse", T = "Soy Montse. En este bufete la regla es sencilla: primero se escucha, luego se lee, y al final se habla.", If = DER },
			{ S = "Ignacio", T = "Soy Ignacio, director de la oficina. Aquí los números cuentan historias. Tu trabajo es leerlas.", If = ECO },
			{ S = "Narrador", T = "Llegas tarde el primer día. Tu tutor mira el reloj. No dice nada. No hace falta.", If = { Flags = { "LlegasTardePracticas" } } },
		} },
		Caso = { Lines = {
			{ S = "Nuria", T = "Tu primer caso: este señor llega con dolor en el pecho. Puede ser muchas cosas. No adivines: investiga.", If = MED },
			{ S = "Sofia", T = "Tu caso: la pasarela del río de Valmar vibra cuando pasa mucha gente. ¿Es peligroso? ¿Cómo se arregla?", If = ING },
			{ S = "Montse", T = "Tu caso: este vecino dice que el ayuntamiento le ha multado injustamente. Él dice que no aparcó allí. ¿Tiene razón?", If = DER },
			{ S = "Ignacio", T = "Tu caso: Marcos, el de las bicicletas, pide un préstamo para abrir otra tienda. ¿Se lo damos?", If = ECO },
			{ S = "Marcos", T = "¡Anda, eres tú! ¡La persona de las bicis azules! Ahora sí que estoy en tus manos. Literalmente.", If = { Flags = { "Interes_Economia" }, Choices = { Estudios = "Economia" } } },
		} },
		Med_Historial = { Lines = { { S = "Narrador", T = "Sesenta años, fumador hasta hace poco, sube tres pisos cada día. Y ayer comió muchísimo en una boda." } } },
		Med_Exploracion = { Lines = {
			{ S = "Paciente", T = "Me duele aquí, al tragar. Y cuando me tumbo, más." },
			{ S = "Nuria", T = "Buena pregunta la tuya: «¿cuándo le duele más?». Eso no lo pregunta todo el mundo." },
		} },
		Med_Analisis = { Lines = {
			{ S = "Narrador", T = "El corazón está perfecto. El estómago, no tanto: es ardor, de la comida de la boda. Nada grave. El señor suspira aliviado." },
		} },
		Ing_Inspeccion = { Lines = { { S = "Narrador", T = "La pasarela vibra al ritmo de los pasos. Si todos caminan igual, la vibración crece. Por eso hay carteles de «no correr»." } } },
		Ing_Materiales = { Lines = { { S = "Narrador", T = "Acero, madera laminada, fibra de carbono. El acero pesa, la fibra es cara. Hay que elegir con cabeza, no con el bolsillo." } } },
		Ing_Planos = { Lines = {
			{ S = "Narrador", T = "Dibujas unos amortiguadores debajo del tablero. Como los de una bici, pero gigantes." },
			{ S = "Sofia", T = "Amortiguadores de masa. Así se hizo con un puente famoso de Londres. Tienes buen ojo." },
		} },
		Der_Expediente = { Lines = { { S = "Narrador", T = "La multa dice: calle Mayor, 10:15. La señal de prohibido se puso… a las 10:30, según el ayuntamiento." } } },
		Der_Testigo = { Lines = {
			{ S = "Vecino", T = "Yo vi cómo ponían la señal. Mi coche ya estaba ahí desde las nueve. Tengo el tique de la panadería de las 9:05." },
		} },
		Der_Leyes = { Lines = {
			{ S = "Narrador", T = "La ley es clara: una señal no puede multar algo que pasó antes de que existiera. El vecino tiene razón." },
			{ S = "Montse", T = "Muy bien. La mitad de este trabajo es mirar las horas. La otra mitad, explicarlo sin que nadie se enfade." },
		} },
		Eco_Cuentas = { Lines = { { S = "Narrador", T = "La tienda de Marcos vende más cada año. Poco, pero siempre más. Y no debe nada a nadie." } } },
		Eco_Mercado = { Lines = { { S = "Narrador", T = "En Playa Dorada no hay ninguna tienda de bicis. Y cada verano llegan miles de turistas." } } },
		Eco_Riesgo = { Lines = {
			{ S = "Narrador", T = "Calculas el riesgo: bajo. La idea de alquilar bicis a turistas (¿te suena?) tiene sentido." },
			{ S = "Ignacio", T = "Bien razonado. Los buenos préstamos no se dan por simpatía, pero tampoco se niegan por miedo." },
		} },
		Error = { Lines = {
			{ S = "Narrador", T = "Esa noche, revisando tu informe, te quedas helado o helada: hay un error. Un número mal copiado." },
			{ S = "Narrador", T = "Pusiste mal una dosis en la hoja del paciente. Nadie la ha usado todavía. Pero podría pasar.", If = MED },
			{ S = "Narrador", T = "Un cálculo de carga está mal. Si alguien construyera con tus números, la pasarela vibraría el doble.", If = ING },
			{ S = "Narrador", T = "Copiaste mal una hora en el recurso. Con esa hora, el vecino perdería el caso.", If = DER },
			{ S = "Narrador", T = "Un cero de más en el informe. Con ese número, el préstamo de Marcos parecería un riesgo enorme.", If = ECO },
			{ S = "Narrador", T = "Nadie lo ha visto todavía. Mañana entregas el informe." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Decírselo a tu tutor mañana a primera hora y corregirlo", Effects = { Choice = { ErrorInforme = "Decir" }, Traits = { Responsabilidad = 2, Valentia = 1 } } },
				{ T = "Corregirlo en silencio: nadie tiene por qué saberlo", Effects = { Choice = { ErrorInforme = "Silencio" }, Traits = { Responsabilidad = 1 } } },
				{ T = "Dejarlo. Seguramente nadie lo note", Effects = { Choice = { ErrorInforme = "Dejar" } } },
			} },
		} },
		Evaluacion = { Lines = {
			{ S = "Nuria", T = "Viniste a decirme tu propio error antes de que lo viera yo. ¿Sabes cuántos médicos no lo hacen? Esto vale más que acertar.", If = { Choices = { ErrorInforme = "Decir", Estudios = "Medicina" } } },
			{ S = "Sofia", T = "Me contaste tu error sin que te lo pidiera. Así se construyen puentes que no se caen.", If = { Choices = { ErrorInforme = "Decir", Estudios = "Ingenieria" } } },
			{ S = "Montse", T = "Reconocer un error ante tu tutora es lo más difícil de esta profesión. Lo has hecho el primer mes.", If = { Choices = { ErrorInforme = "Decir", Estudios = "Derecho" } } },
			{ S = "Ignacio", T = "Me avisaste del cero de más antes de que llegara al comité. Eso, en un banco, es oro.", If = { Choices = { ErrorInforme = "Decir", Estudios = "Economia" } } },
			{ S = "Narrador", T = "Tu tutor revisa el informe. Está bien. Nadie sabe que hubo un error. Tú sí.", If = { Choices = { ErrorInforme = "Silencio" } } },
			{ S = "Narrador", T = "Tu tutor encuentra el error en la revisión. «Esto podría haber sido grave. La próxima vez, revisa y avisa.»", If = { Choices = { ErrorInforme = "Dejar" } } },
			{ S = "Narrador", T = "Al final de las prácticas, te llaman al despacho. Hay una oferta: cuando termines la carrera, aquí tienes un sitio.", If = { Choices = { ErrorInforme = "Decir" }, LastGradeAtLeast = 6 },
				Effects = { Flags = { "OfertaTrabajo" } } },
			{ S = "Narrador", T = "Terminan las prácticas. Te llevas un informe firmado y la sensación de que esto va en serio." },
		} },
	},
}
