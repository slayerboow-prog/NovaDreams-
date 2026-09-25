-- MISIÓN 05 · «LA VENGANZA DE LA MOCHILA» (15-20 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.15.
--
-- Alguien gasta bromas a varios alumnos y todos culpan a Bruno. Lucía te pide que investigues.
-- Notas con letra muy ordenada, un horario de salidas "al baño", la "cámara" de Ramón (los dibujos de
-- Omar) y testigos → acusar a alguien (si fallas, hay consecuencias y vuelves a pensar) → Iker confiesa:
-- quería que alguien le hiciera caso → decisión social.

local V = Vector3.new

local VICTIMAS = {
	{ Npc = "Vega", Place = "SpotInformanteComedor" },
	{ Npc = "Alex", Place = "SpotGimnasioGrupo" },
	{ Npc = "Nico", Place = "PasilloColegio", Offset = V(2, 0, -2) },
}
local SOSPECHOSOS = {
	{ Npc = "Bruno", Place = "PasilloColegio", Offset = V(-4, 0, 3) },
	{ Npc = "Ruben", Place = "PasilloColegio", Offset = V(-1, 0, 4) },
	{ Npc = "Omar", Place = "PasilloColegio", Offset = V(2, 0, 4) },
	{ Npc = "Iker", Place = "PasilloColegio", Offset = V(5, 0, 3) },
}

return {
	Id = "Cole05_Venganza",
	Kind = "Main",
	Title = "La venganza de la mochila",
	Description = "Alguien está gastando bromas por todo el colegio. Todos culpan a Bruno. ¿Seguro que es él?",
	Chapter = "Nino_ElColegio",
	AgeRange = { 8, 8 },
	Duration = { 15, 20 },
	Difficulty = 3,
	Type = "Historia · Investigación",
	Requires = { Completed = { "Cole04_Malotes" }, StageProgress = 0.24 },
	Npcs = { "Lucia", "Ramon", "Vega", "Alex", "Nico", "Bruno", "Ruben", "Omar", "Iker" },
	Locations = { "AulaA", "ComedorColegio", "GimnasioColegio", "PasilloColegio", "BibliotecaColegio", "Conserjeria" },
	Next = { "Cole06_Examen" },
	Outcomes = { "Iker entra en el grupo", "Iker pide perdón él mismo", "Lucía habla con Iker", "Acusaste a Bruno sin pruebas (o no)" },

	Moment = "Resolviste el misterio de las bromas",
	Memory = "Detective",
	Rewards = { Items = { Lupa = 1 } },

	Props = {
		Nota = { Kind = "Papel", Name = "Nota en la taquilla de Nico", Prompt = "Leer", Place = "TaquillaNico", Offset = V(0, 0, 3), Dialogue = "Nota", Once = true },
		Guantes = { Kind = "Caja", Name = "Los guantes de Álex", Prompt = "Examinar", Place = "SpotInformanteBiblioteca", Offset = V(3, 0, 0), Color = Color3.fromRGB(245, 245, 245), Dialogue = "Guantes", Once = true },
		Horario = { Kind = "Papel", Name = "Registro de salidas al baño", Prompt = "Leer", Place = "PizarraA", Offset = V(2, 0, 3), Dialogue = "Horario", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Un mes después…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase", Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Scene", Dialogue = "Revuelo", Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) }, { Npc = "Bruno", Place = "AulaA", Offset = V(4, 0, 2) } } },

		-- Las víctimas
		{ Type = "Group", Text = "Habla con quienes sufrieron las bromas",
			Steps = {
				{ Type = "Talk", Npc = "Vega", Dialogue = "Victima_Vega", Text = "Vega (en el comedor)" },
				{ Type = "Talk", Npc = "Alex", Dialogue = "Victima_Alex", Text = "Álex (en el gimnasio)" },
				{ Type = "Talk", Npc = "Nico", Dialogue = "Victima_Nico", Text = "Nico (en el pasillo)" },
			},
			Actors = VICTIMAS },

		-- Las pistas
		{ Type = "Group", Text = "Busca pistas", Need = 3,
			Steps = {
				{ Type = "Use", Prop = "Nota", Text = "Una nota en la taquilla de Nico" },
				{ Type = "Use", Prop = "Guantes", Text = "Los guantes aparecieron en la biblioteca" },
				{ Type = "Use", Prop = "Horario", Text = "El registro de salidas de Lucía" },
				{ Type = "Talk", Npc = "Ramon", Dialogue = "Camaras", Text = "Las «cámaras» de Ramón (conserjería)" },
			},
			Actors = { { Npc = "Ramon", Place = "Conserjeria" } } },
		{ Type = "Scene", Dialogue = "Deduccion" },

		-- Acusar
		{ Type = "Reach", Place = "PasilloColegio", Text = "Ve al pasillo: todos los sospechosos están allí", Actors = SOSPECHOSOS },
		{ Type = "Choice", Key = "Culpable", Text = "¿Quién hizo las bromas? Habla con quien acuses",
			Options = {
				{ Id = "Bruno", Npc = "Bruno", Text = "Bruno", Dialogue = "Acusa_Bruno", Stay = true,
					Effects = { Rel = { Bruno = -6 }, Flags = { "AcusasteABruno" } } },
				{ Id = "Ruben", Npc = "Ruben", Text = "Rubén", Dialogue = "Acusa_Ruben", Stay = true, Effects = { Rel = { Ruben = -4 } } },
				{ Id = "Omar", Npc = "Omar", Text = "Omar", Dialogue = "Acusa_Omar", Stay = true, Effects = { Rel = { Omar = -2 }, Traits = { Humor = 1 } } },
				{ Id = "Iker", Npc = "Iker", Text = "Iker", Dialogue = "Acusa_Iker", Effects = { Traits = { Curiosidad = 2 } } },
			},
			Actors = SOSPECHOSOS },
		{ Type = "Scene", Dialogue = "Confesion", Actors = SOSPECHOSOS },
		{ Type = "Scene", Dialogue = "Final", Actors = { { Npc = "Iker", Place = "PasilloColegio", Offset = V(5, 0, 3) }, { Npc = "Lucia", Place = "PasilloColegio", Offset = V(0, 0, 6) }, { Npc = "Bruno", Place = "PasilloColegio", Offset = V(-4, 0, 3) } } },
	},

	Dialogues = {
		Revuelo = { Lines = {
			{ S = "Narrador", T = "Hoy el aula es un caos." },
			{ S = "Narrador", T = "A Vega le han cambiado sus pegatinas brillantes por pegatinas de calcetines sucios." },
			{ S = "Narrador", T = "A Álex le han escondido los guantes de portera. Y la taquilla de Nico está llena de papelitos." },
			{ S = "Bruno", T = "¡YA ESTÁ BIEN! ¡Todos me miráis a mí! ¡Esta vez NO he sido yo!" },
			{ S = "Bruno", T = "Tú lo sabes, ¿verdad? Tú hablaste conmigo. Sabes que no miento.", If = { Flags = { "Bruno_HablasteConEl" } } },
			{ S = "Lucia", T = "Silencio. {nombre}, tú descubriste lo de la mochila. ¿Me ayudas a averiguar qué pasa? Sin acusar a nadie sin pruebas." },
		} },

		Victima_Vega = { Lines = {
			{ S = "Vega", T = "Mis pegatinas de purpurina… y en su lugar, ¡calcetines sucios! Con una nota: «Nadie mira lo que brilla de verdad»." },
			{ S = "Vega", T = "La letra era perfecta. Como de máquina. Bruno escribe como un pollo, eso lo sabe todo el mundo." },
		}, Effects = { Flags = { "PistaLetra" } } },
		Victima_Alex = { Lines = {
			{ S = "Alex", T = "Mis guantes de portera. Desaparecidos. Y luego aparecieron… ¡en la biblioteca! Bruno no ha pisado la biblioteca en su vida." },
		}, Effects = { Flags = { "PistaBiblioteca" } } },
		Victima_Nico = { Lines = {
			{ S = "Nico", T = "¡Mi taquilla está llena de papelitos! Y cada uno tiene una pregunta: «¿Cuántos huesos tiene el cuerpo humano?»" },
			{ S = "Nico", T = "¿Quién hace una broma con PREGUNTAS DE CIENCIAS? Eso no es una broma, ¡eso es un examen!" },
		}, Effects = { Flags = { "PistaPreguntas" } } },

		Nota = { Lines = {
			{ S = "Narrador", T = "Una nota doblada en cuatro: «Doscientos seis. Pero nadie me lo ha preguntado nunca»." },
			{ S = "Narrador", T = "Doscientos seis: los huesos del cuerpo humano. Y la letra es perfecta, pequeñita, ordenada." },
		} },
		Guantes = { Lines = {
			{ S = "Narrador", T = "Los guantes estaban en la mesa del rincón de ciencias de la biblioteca. Al lado, un libro abierto: «Datos curiosos del universo»." },
		} },
		Horario = { Lines = {
			{ S = "Narrador", T = "El registro de Lucía: quién sale al baño y a qué hora." },
			{ S = "Narrador", T = "Lunes, 11:05 — Iker. Martes, 11:10 — Iker. Miércoles, 11:04 — Iker. Justo a la hora de cada broma." },
		}, Effects = { Flags = { "PistaHorario" } } },
		Camaras = { Lines = {
			{ S = "Ramon", T = "¿Cámaras? En este colegio no hay cámaras, {nombre}. Hay algo mejor: Omar." },
			{ S = "Ramon", T = "Me regala sus dibujos del pasillo. Mira este: alguien con gafas junto a la taquilla de Nico. De espaldas." },
		}, Effects = { Flags = { "PistaGafas" } } },

		Deduccion = { Lines = {
			{ S = "Narrador", T = "Repasas lo que sabes:" },
			{ S = "Narrador", T = "· La letra es perfecta, ordenada. Bruno escribe como un pollo.", If = { Flags = { "PistaLetra" } } },
			{ S = "Narrador", T = "· Los guantes aparecieron en la biblioteca, junto a un libro de datos curiosos.", If = { Flags = { "PistaBiblioteca" } } },
			{ S = "Narrador", T = "· Las «bromas» son preguntas de ciencias.", If = { Flags = { "PistaPreguntas" } } },
			{ S = "Narrador", T = "· Cada broma coincide con una salida al baño de Iker.", If = { Flags = { "PistaHorario" } } },
			{ S = "Narrador", T = "· Omar dibujó a alguien con gafas junto a la taquilla.", If = { Flags = { "PistaGafas" } } },
			{ S = "Yo", T = "Ya sé quién ha sido. Creo." },
		} },

		Acusa_Bruno = { Lines = {
			{ S = "Yo", T = "Has sido tú, Bruno." },
			{ S = "Bruno", T = "¡¿VES?! ¡Todos igual! ¡Por una vez que no hago nada!" },
			{ S = "Bruno", T = "Pensaba que tú eras diferente. Después de lo del otro día…", If = { Flags = { "Bruno_HablasteConEl" } } },
			{ S = "Narrador", T = "Bruno se cruza de brazos. No, no encaja: su letra, la biblioteca, las preguntas… Piensa otra vez." },
		} },
		Acusa_Ruben = { Lines = {
			{ S = "Ruben", T = "¿Yo? Mis bromas son buenas. Esto de las preguntas de ciencias es… rarísimo. No es mi estilo." },
			{ S = "Narrador", T = "Tiene razón: Rubén esconde cosas, no deja preguntas. Piensa otra vez." },
		} },
		Acusa_Omar = { Lines = {
			{ S = "Omar", T = "¿Yo? Si yo dibujé al culpable. ¿Me dibujé a mí mismo de espaldas? Eso sería arte muy moderno." },
			{ S = "Narrador", T = "No. Omar no lleva gafas. Piensa otra vez." },
		} },
		Acusa_Iker = { Lines = {
			{ S = "Yo", T = "Iker. Fuiste tú." },
			{ S = "Iker", T = "…" },
			{ S = "Iker", T = "¿Cómo lo has sabido?" },
		} },
		Confesion = { Lines = {
			{ S = "Iker", T = "Vale. Fui yo. Pero no para hacer daño." },
			{ S = "Iker", T = "Me paso el día contando datos curiosos y nadie me escucha. «Ya está Iker con sus cosas»." },
			{ S = "Iker", T = "Pensé que si ponía los datos en las bromas… por fin alguien los leería. Doscientos seis huesos. Nadie lo sabía." },
			{ S = "Iker", T = "Y fue más fácil que todos pensaran que era Bruno. Eso… eso estuvo mal." },
			{ S = "Bruno", T = "Pues sí. Muy mal." },
			{ Ask = "¿Qué haces con Iker?", Options = {
				{ T = "«Vente con nosotros. A mí sí me gustan tus datos.»", Effects = { Choice = { IkerFinal = "Grupo" }, Flags = { "IkerEnElGrupo" }, Rel = { Iker = 15 }, Traits = { Empatia = 2 } }, Then = {
					{ S = "Iker", T = "¿En serio? …Dato curioso: es la primera vez que alguien me invita a algo." },
				} },
				{ T = "«Tienes que pedir perdón tú mismo, a Vega, a Álex y a Nico.»", Effects = { Choice = { IkerFinal = "Perdon" }, Rel = { Iker = 6, Vega = 3, Alex = 3, Nico = 3 }, Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Iker", T = "Tienes razón. Lo haré. Y a Bruno también." },
				} },
				{ T = "«Esto se lo tiene que contar Lucía.»", Effects = { Choice = { IkerFinal = "Lucia" }, Rel = { Iker = -3, Lucia = 3 }, Traits = { Responsabilidad = 2 } }, Then = {
					{ S = "Iker", T = "…Vale. Es lo justo." },
				} },
			} },
		} },
		Final = { Lines = {
			{ S = "Lucia", T = "Bien hecho, {nombre}. Con pruebas y sin prisas. Así se hace." },
			{ S = "Lucia", T = "Toma: una lupa de detective. Era mía cuando tenía tu edad. Estudié en este mismo colegio, ¿sabes?" },
			{ S = "Bruno", T = "…Gracias por no culparme. Otra vez.", If = { NotFlags = { "AcusasteABruno" } } },
			{ S = "Bruno", T = "Me acusaste sin pruebas. Que lo sepas: me acuerdo.", If = { Flags = { "AcusasteABruno" } } },
			{ S = "Iker", T = "Dato curioso para terminar: un detective de verdad se equivoca muchas veces antes de acertar. Tú solo… algunas.", If = { Flags = { "AcusasteABruno" } } },
		} },
	},
}
