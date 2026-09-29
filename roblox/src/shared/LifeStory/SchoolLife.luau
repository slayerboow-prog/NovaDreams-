-- SchoolLife: la vida diaria del colegio y del instituto, como datos (sin nada de Roblox, se prueba con Lune).
--
--   * El horario de un día de cole: a qué hora se llega, cuándo hay clase, recreo, comedor y salida.
--     Lo usan los compañeros y la profe que viven en cada colegio (SchoolService) para saber adónde ir.
--   * Quién vive en el colegio (los compañeros de tu generación y la profe).
--   * El comedor: la comida gratis para los alumnos (CanteenService) y la comida con tus compañeros
--     del día de cole (DayPlans): dónde se sienta cada uno y qué os contáis.

local Config = require(script.Parent.Parent.Config)
local SCHOOL = Config.SchoolDay

local SchoolLife = {}

---------------------------------------------------------------------
-- Horario (horas de juego). Lo que no está aquí es "Fuera": el colegio está cerrado.
---------------------------------------------------------------------
SchoolLife.Recess = { From = 11.5, To = 12 } -- recreo de media mañana

SchoolLife.Periods = {
	{ Id = "Llegada", From = SCHOOL.Opens, To = SCHOOL.Start }, -- en la puerta, esperando a que abran
	{ Id = "Clase", From = SCHOOL.Start, To = SchoolLife.Recess.From },
	{ Id = "Recreo", From = SchoolLife.Recess.From, To = SchoolLife.Recess.To },
	{ Id = "Clase", From = SchoolLife.Recess.To, To = SCHOOL.LunchFrom },
	{ Id = "Comedor", From = SCHOOL.LunchFrom, To = SCHOOL.LunchTo },
	{ Id = "Clase", From = SCHOOL.LunchTo, To = SCHOOL.End },
	{ Id = "Salida", From = SCHOOL.End, To = SCHOOL.End + 0.5 }, -- salen por la puerta y se van a casa
}

-- ¿Qué toca a esta hora? "Llegada", "Clase", "Recreo", "Comedor", "Salida" o "Fuera"
function SchoolLife.activityAt(clockTime: number): string
	for _, period in SchoolLife.Periods do
		if clockTime >= period.From and clockTime < period.To then
			return period.Id
		end
	end
	return "Fuera"
end

-- ¿Está abierto el colegio? (de que abren las puertas a que suena el último timbre)
function SchoolLife.isOpen(clockTime: number): boolean
	return clockTime >= SCHOOL.Opens and clockTime < SCHOOL.End
end

---------------------------------------------------------------------
-- Quién vive en cada colegio
---------------------------------------------------------------------
-- Los compañeros de tu generación (los del día de cole) y la tutora
SchoolLife.Kids = { "Nico", "Sara", "Omar" }
SchoolLife.Teacher = "Lucia"
-- La profe de cada sitio (la tutora del cole; en el instituto, el tutor de 1.º C)
SchoolLife.Teachers = { Colegio = "Lucia", Instituto = "Javier" }

-- Lo que dicen al hablar con ellos fuera de las misiones (la primera vez, y luego alguna de las demás)
SchoolLife.Lines = {
	Nico = { First = "DLG.NICO.COLE", Lines = { "DLG.NICO.BICI", "DLG.NICO.SUENO", "DLG.NICO.RECREO" } },
	Sara = { First = "DLG.SARA.COLE.01", Lines = { "DLG.SARA.CIENCIA.01", "DLG.SARA.EXAMEN", "DLG.SARA.RECREO" } },
	Omar = { First = "DLG.OMAR.COCINA.01", Lines = { "DLG.OMAR.RECREO", "DLG.OMAR.DIBUJO", "DLG.OMAR.MERIENDA" } },
	Lucia = { First = "DLG.LUCIA.COLE1.01", Lines = { "DLG.LUCIA.PREGUNTAS", "DLG.LUCIA.ANIMO", "DLG.LUCIA.EXAMEN" } },
	Javier = { First = "Soy Javier, tu tutor. Aquí se viene a pensar… y a comer a las dos, que también es importante.",
		Lines = { "Como decía Sócrates: solo sé que el examen es el jueves.", "¿Dudas? Pregunta. Las dudas son el principio de todo.", "Sin prisa pero sin pausa, que el trimestre se acaba." } },
}

-- Si ya os conocéis, a veces te saludan por tu nombre recordando algo que PASÓ de verdad en tu
-- historia (If: condiciones de Conditions sobre tu vida; nunca dan por hecho lo que no hiciste).
-- Lo usa SchoolService con StoryState; Validate revisa que las condiciones existan.
SchoolLife.Callbacks = {
	{ Npc = "Nico", If = { Completed = { "Cole08_Torneo" } }, T = "¡{nombre}! Aún sueño con la final del torneo. ¡Qué partidazo!" },
	{ Npc = "Nico", If = { Completed = { "Cole03_Grupo" } }, T = "¡Eh, {nombre}! ¿Cuándo nos juntamos otra vez con el grupo?" },
	{ Npc = "Sara", If = { Completed = { "Cole06_Examen" } }, T = "{nombre}, después del examen imposible cualquier examen me parece fácil. ¿A ti no?" },
	{ Npc = "Sara", If = { Completed = { "Cole09_Misterio" } }, T = "¿Te acuerdas del misterio del cole, {nombre}? Todavía me da escalofríos." },
	{ Npc = "Omar", If = { Completed = { "Cole10_Festival" } }, T = "¡{nombre}! ¿Te acuerdas del festival? Aún me tiemblan las piernas." },
	{ Npc = "Omar", If = { Completed = { "Cole07_Excursion" } }, T = "Hola, {nombre}. Echo de menos la granja de la excursión… y las gallinas." },
	{ Npc = "Lucia", If = { Completed = { "Cole02_Mochila" } }, T = "Hola, {nombre}. ¿Ya no se te pierde la mochila?" },
	{ Npc = "Lucia", If = { Completed = { "Cole11_Proyecto" } }, T = "{nombre}, sigo presumiendo de vuestro proyecto en la sala de profes." },
	{ Npc = "Javier", If = { Completed = { "Ins03_QueQuieresSer" } }, T = "¿Sigues pensando en lo que quieres ser, {nombre}? Hay tiempo, pero piénsalo." },
	{ Npc = "Javier", If = { Completed = { "Ins05_ElRumor" } }, T = "{nombre}, lo del rumor lo llevaste con cabeza. Eso también se aprende." },
}

-- Lo que te dice alguien que ya te conoce: la mitad de las veces (roll < 0.5) recuerda algo que
-- pasó de verdad (state = StoryState.of(data)); si no, nil (dice una de sus frases de siempre)
function SchoolLife.knownLine(npcId: string, state: any, roll: number): string?
	local memories = {}
	for _, entry in SchoolLife.Callbacks do
		if entry.Npc == npcId and state.check(entry.If) then
			table.insert(memories, entry.T)
		end
	end
	if #memories > 0 and roll < 0.5 then
		return memories[math.min(#memories, math.floor(roll * 2 * #memories) + 1)]
	end
	return nil
end

-- Todos los que viven en el colegio (compañeros + profe)
function SchoolLife.people(): { string }
	local list = table.clone(SchoolLife.Kids)
	table.insert(list, SchoolLife.Teachers.Colegio)
	table.insert(list, SchoolLife.Teachers.Instituto)
	return list
end

function SchoolLife.livesAtSchool(npc: string?): boolean
	return npc ~= nil and table.find(SchoolLife.people(), npc) ~= nil
end

-- Segundos que hay que esperar para volver a hablar con el mismo personaje (evita que un toque de
-- más en el móvil vuelva a sacar otra frase, una y otra vez)
SchoolLife.TalkCooldown = 8

---------------------------------------------------------------------
-- Comedor: comida gratis para los alumnos
---------------------------------------------------------------------
-- Hunger/Energy: cuánto recupera. Cooldown: segundos entre una y otra para el mismo alumno.
SchoolLife.Food = {
	Menu = { Name = "Menú del comedor", Action = "Coger comida", Hunger = 55, Energy = 6, Cooldown = 15, Gesture = "Eat" },
	Fruta = { Name = "Fruta", Action = "Coger fruta", Hunger = 15, Energy = 2, Cooldown = 10, Gesture = "Eat" },
	Agua = { Name = "Fuente de agua", Action = "Beber agua", Hunger = 3, Energy = 5, Cooldown = 6, Gesture = "Drink" },
}

-- ¿Puede comer en el comedor? Los alumnos (niños y adolescentes), mientras el colegio está abierto
-- (y siempre a la hora de comer). Devuelve el motivo si no: "Alumnos" o "Cerrado".
function SchoolLife.canEat(stage: string?, clockTime: number): (boolean, string?)
	if stage ~= "Nino" and stage ~= "Adolescente" then
		return false, "Alumnos"
	end
	local lunch = clockTime >= SCHOOL.LunchFrom and clockTime < SCHOOL.LunchTo
	if not lunch and not SchoolLife.isOpen(clockTime) then
		return false, "Cerrado"
	end
	return true, nil
end

-- Cooldown por alumno y por cosa: ¿puede ya? (last = cuándo comió la última vez, now = ahora)
function SchoolLife.ready(last: number?, now: number, cooldown: number): (boolean, number)
	if last == nil or now - last >= cooldown then
		return true, 0
	end
	return false, math.ceil(cooldown - (now - last))
end

---------------------------------------------------------------------
-- La comida con tus compañeros (día de cole / de instituto)
---------------------------------------------------------------------
-- Dónde se sienta cada uno (lugares de Locations: bancos junto a las mesas del comedor) y dónde vigila
-- la profe de guardia. El amigo del día se sienta enfrente de tu sitio; los otros dos, al lado.
local LUNCH_PLACES = {
	Colegio = { Seats = { "AsientoComedor1", "AsientoComedor2", "AsientoComedor3" }, Teacher = "ProfeComedor" },
	Instituto = { Seats = { "AsientoInstituto1", "AsientoInstituto2", "AsientoInstituto3" }, Teacher = "ProfeInstituto" },
}

-- Lo que dicen en la mesa si les hablas (una frase suelta, como mucho cada pocos segundos)
SchoolLife.LunchBarks = {
	Nico = "¡Mmm! Hoy hay croquetas. ¡Las mejores del mundo!",
	Sara = "Mastica despacio: el estómago tarda veinte minutos en saber que está lleno.",
	Omar = "Está bueno… pero yo le pondría un poco de pimentón.",
}

-- Actores de la escena del comedor: el amigo del día y los otros dos compañeros, sentados comiendo
-- (Work = "Eat": se llevan la cuchara a la boca), y la profe de guardia vigilando de pie.
-- (Solo textos y números: los pasos de un día generado se guardan con la partida.)
function SchoolLife.lunchActors(friend: string, school: string?): { { [string]: any } }
	local where = LUNCH_PLACES[school or "Colegio"] or LUNCH_PLACES.Colegio
	local actors = { { Npc = friend, Place = where.Seats[1], Mode = "Sit", Work = "Eat", Bark = SchoolLife.LunchBarks[friend] } }
	local k = 1
	for _, kid in SchoolLife.Kids do
		if kid ~= friend then
			k += 1
			table.insert(actors, { Npc = kid, Place = where.Seats[k], Mode = "Sit", Work = "Eat", Bark = SchoolLife.LunchBarks[kid] })
		end
	end
	local teacher = SchoolLife.Teachers[school or "Colegio"] or SchoolLife.Teacher
	table.insert(actors, { Npc = teacher, Place = where.Teacher, Mode = "Idle", Work = "Watch", Prompt = false })
	return actors
end

-- En el recreo, el amigo del día te espera en el patio (va andando desde donde esté)
function SchoolLife.recessActors(friend: string, school: string?): { { [string]: any } }
	return { { Npc = friend, Place = if school == "Instituto" then "PatioInstituto" else "Patio", Mode = "Wander", Radius = 5 } }
end

-- Conversaciones (Quests: Nino_Jornada y Adol_Jornada las comparten)
SchoolLife.Dialogues = {
	Comida_Nico = { Lines = {
		{ S = "Nico", T = "¡Aquí, aquí! Te he guardado sitio. ¿Qué te ha tocado?" },
		{ S = "Nico", T = "Yo me como primero el postre. Por si acaso." },
		{ Ask = "¿Qué le dices?", Options = {
			{ T = "¡Eso es trampa!", Effects = { Rel = { Nico = 1 } }, Then = {
				{ S = "Nico", T = "Es estrategia. Los bomberos comen rápido por si suena la alarma." },
			} },
			{ T = "Te cambio mi yogur por tu fruta.", Effects = { Rel = { Nico = 2 } }, Then = {
				{ S = "Nico", T = "¡Trato hecho! ¡Negocias mejor que nadie en el comedor!" },
			} },
		} },
	} },
	Comida_Sara = { Lines = {
		{ S = "Sara", T = "Siéntate. Estaba contando los guisantes: hay treinta y siete. Impar." },
		{ S = "Sara", T = "¿Sabías que las lentejas tienen más hierro que la carne? Lo he leído." },
		{ Ask = "¿Qué le dices?", Options = {
			{ T = "Entonces me las como todas.", Effects = { Rel = { Sara = 2 } }, Then = {
				{ S = "Sara", T = "Bien. Así la próxima carrera la ganas tú. O no." },
			} },
			{ T = "¿Y los guisantes qué tienen?", Effects = { Rel = { Sara = 1 } }, Then = {
				{ S = "Sara", T = "Vitamina C. Y un sabor muy discutible." },
			} },
		} },
	} },
	Comida_Omar = { Lines = {
		{ S = "Omar", T = "Mmm… a este guiso le falta un poco de comino. Mi abuela lo haría mejor." },
		{ S = "Omar", T = "Algún día cocinaré yo para todo el colegio. Menú especial los viernes." },
		{ Ask = "¿Qué le dices?", Options = {
			{ T = "Yo seré tu primer cliente.", Effects = { Rel = { Omar = 2 } }, Then = {
				{ S = "Omar", T = "Primer cliente y el único que no paga. ¡Hecho!" },
			} },
			{ T = "Pues está muy rico.", Effects = { Rel = { Omar = 1 } }, Then = {
				{ S = "Omar", T = "Está rico… pero podría estar RIQUÍSIMO." },
			} },
		} },
	} },
	Recreo_Nico = { Lines = {
		{ S = "Nico", T = "DLG.NICO.RECREO" },
		{ S = "Nico", T = "¡Venga, que se acaba el recreo! ¡La próxima vez juegas conmigo!" },
	} },
	Recreo_Sara = { Lines = {
		{ S = "Sara", T = "DLG.SARA.RECREO" },
		{ S = "Sara", T = "Bueno, ahora a clase. Te cuento más en el comedor." },
	} },
	Recreo_Omar = { Lines = {
		{ S = "Omar", T = "DLG.OMAR.MERIENDA" },
		{ S = "Omar", T = "¡Mitad para ti, mitad para mí! Así se hacen los amigos." },
	} },
}

return SchoolLife
