-- MISIÓN 12 · «EL ÚLTIMO DÍA» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.22.
--
-- La mañana en casa → el colegio por última vez → recorres los sitios de tu historia y cada uno trae
-- un RECUERDO DE VERDAD (lo que elegiste y viviste: dónde te sentaste, tu grupo, el partido, el
-- torneo, el examen, Hugo, Bruno…) → se abre la cápsula del tiempo (lo que metiste en la misión 09) →
-- foto de la clase → ceremonia → despedidas (Bruno incluido, según vuestra historia) → una promesa →
-- fin de primaria y paso al instituto.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local CON_HUGO = { Flags = { "HugoConElGrupo" } }
local CON_IKER = { Flags = { "IkerEnElGrupo" } }

local AMIGOS = {
	{ Npc = "Nico", Mode = "Follow" },
	{ Npc = "Sara", Mode = "Follow" },
	{ Npc = "Omar", Mode = "Follow" },
}

local function grupoEn(place: string): { any }
	return {
		{ Npc = "Nico", Place = place, Offset = V(-3, 0, 2) },
		{ Npc = "Sara", Place = place, Offset = V(3, 0, 2) },
		{ Npc = "Omar", Place = place, Offset = V(0, 0, 4) },
		{ Npc = "Mateo", Place = place, Offset = V(-5, 0, 4), If = AMIGO_MATEO },
		{ Npc = "Hugo", Place = place, Offset = V(5, 0, 4), If = CON_HUGO },
		{ Npc = "Iker", Place = place, Offset = V(6, 0, 1), If = CON_IKER },
	}
end

local SALA = grupoEn("SalaCerrada")
table.insert(SALA, { Npc = "Lucia", Place = "SalaCerrada", Offset = V(0, 0, -3) })
table.insert(SALA, { Npc = "Ramon", Place = "SalaCerrada", Offset = V(-6, 0, -2) })

local CEREMONIA = grupoEn("Patio")
for _, actor in {
	{ Npc = "Lucia", Place = "Patio", Offset = V(0, 0, 10) },
	{ Npc = "Andres", Place = "Patio", Offset = V(-4, 0, 11) },
	{ Npc = "Marta", Place = "Patio", Offset = V(4, 0, 11) },
	{ Npc = "Ramon", Place = "Patio", Offset = V(10, 0, 9) },
	{ Npc = "Marisa", Place = "Patio", Offset = V(12, 0, 10) },
	{ Npc = "Familia", Place = "Patio", Offset = V(-10, 0, 6), Mode = "Wave" },
	{ Npc = "Abu", Place = "Patio", Offset = V(-12, 0, 8) },
	{ Npc = "Bruno", Place = "Patio", Offset = V(9, 0, -3) },
	{ Npc = "Ruben", Place = "Patio", Offset = V(11, 0, -1) },
	{ Npc = "Vega", Place = "Patio", Offset = V(-7, 0, -2) },
	{ Npc = "Alex", Place = "Patio", Offset = V(-9, 0, 0) },
} do
	table.insert(CEREMONIA, actor)
end

-- Un recuerdo: el narrador lo cuenta como flashback
local function recuerdo(text: string, cond: any?): any
	return { S = "Narrador", T = "✨ " .. text, If = cond }
end

return {
	Id = "Cole12_UltimoDia",
	Kind = "Main",
	Title = "El último día",
	Description = "Último día de primaria. Un paseo por todos los sitios donde pasó tu historia… y una cápsula del tiempo por abrir.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 10, 11 },
	Duration = { 20, 30 },
	Difficulty = 1,
	Type = "Historia · Final de capítulo",
	Requires = { Completed = { "Cole11_Proyecto" }, StageProgress = 0.94 },
	Npcs = { "Familia", "Abu", "Nico", "Sara", "Omar", "Mateo", "Hugo", "Iker", "Lucia", "Ramon", "Marisa", "Andres", "Marta", "Bruno", "Ruben", "Vega", "Alex" },
	Locations = { "HomeSalon", "Vestibulo", "PupitreA", "TaquillaColegio", "CampoColegio", "BibliotecaColegio", "AlmacenColegio", "Patio", "SalaCerrada" },
	Next = { "Adol_NuevoInstituto" },
	Outcomes = { "Los recuerdos que visitas", "Lo que había en tu cápsula", "Cómo te despides de Bruno", "Tu promesa al grupo" },

	Moment = "Tu último día de primaria",
	MomentSting = false,
	Memory = "UltimoDiaCole",
	Rewards = { Items = { DiplomaPrimaria = 1 }, Money = 30 },

	Props = {
		RecPupitre = { Kind = "Asiento", Name = "Tu primer pupitre", Prompt = "Recordar", Place = "PupitreA", Dialogue = "Rec_Pupitre", Once = true },
		RecTaquilla = { Kind = "Marcador", Name = "Tu taquilla", Prompt = "Recordar", Place = "TaquillaColegio", Dialogue = "Rec_Taquilla", Once = true },
		RecCampo = { Kind = "Balon", Name = "Un balón olvidado", Prompt = "Recordar", Place = "CampoColegio", Dialogue = "Rec_Campo", Once = true },
		RecBiblioteca = { Kind = "Libro", Name = "La mesa donde estudiabas", Prompt = "Recordar", Place = "BibliotecaColegio", Offset = V(6, 0, 4), Dialogue = "Rec_Biblioteca", Once = true },
		RecAlmacen = { Kind = "Caja", Name = "El almacén del gimnasio", Prompt = "Recordar", Place = "AlmacenColegio", Offset = V(-2, 0, 2), Dialogue = "Rec_Almacen", Once = true },
		RecBanco = { Kind = "Banco", Name = "El banco del patio", Prompt = "Recordar", Place = "Patio", Offset = V(-14, 0, 10), Dialogue = "Rec_Banco", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "El último día de colegio…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Manana", Teleport = "HomeSalon",
			Actors = { { Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) }, { Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2) } } },
		{ Type = "Reach", Place = "Vestibulo", Text = "Ve al colegio por última vez", Actors = grupoEn("Vestibulo") },
		{ Type = "Scene", Dialogue = "Llegada", Actors = grupoEn("Vestibulo") },

		-- Los sitios de tu historia
		{ Type = "Group", Text = "Despídete de los sitios del cole (al menos cuatro)", Need = 4,
			Steps = {
				{ Type = "Use", Prop = "RecPupitre", Text = "Tu primer pupitre (clase)" },
				{ Type = "Use", Prop = "RecTaquilla", Text = "Tu taquilla (pasillo)" },
				{ Type = "Use", Prop = "RecCampo", Text = "El campo de fútbol" },
				{ Type = "Use", Prop = "RecBiblioteca", Text = "La biblioteca" },
				{ Type = "Use", Prop = "RecAlmacen", Text = "El almacén del gimnasio" },
				{ Type = "Use", Prop = "RecBanco", Text = "El banco del patio" },
			},
			Actors = AMIGOS },

		-- La cápsula del tiempo
		{ Type = "Reach", Place = "SalaCerrada", Text = "Ve a la sala del fondo: hoy se abre la cápsula", Actors = SALA },
		{ Type = "Scene", Dialogue = "Capsula", Actors = SALA },

		-- Foto, ceremonia y despedidas
		{ Type = "Reach", Place = "Patio", Text = "Ve al patio: la ceremonia está a punto de empezar", Actors = CEREMONIA },
		{ Type = "Cinematic", Id = "Cole12_Foto", Actors = CEREMONIA },
		{ Type = "Scene", Dialogue = "Ceremonia", Actors = CEREMONIA },
		{ Type = "Group", Text = "Despídete",
			Steps = {
				{ Type = "Talk", Npc = "Lucia", Dialogue = "Adios_Lucia", Text = "Lucía" },
				{ Type = "Talk", Npc = "Bruno", Dialogue = "Adios_Bruno", Text = "Bruno" },
				{ Type = "Talk", Npc = "Ramon", Dialogue = "Adios_Ramon", Text = "Ramón" },
			},
			Actors = CEREMONIA },
		{ Type = "Scene", Dialogue = "Promesa", Actors = grupoEn("Patio") },
		{ Type = "Cinematic", Id = "Nino_FinPrimaria" },
		{ Type = "Transition", SetStage = "Adolescente", TextKey = "TRANSITION.INSTITUTO", Cinematic = "Nino_AInstituto" },
	},

	Dialogues = {
		Manana = { Lines = {
			{ S = "Familia", T = "Buenos días, {nombre}. Hoy es el último día. ¿Cómo puede pasar tan rápido? Ayer mismo te ponía la mochila por primera vez." },
			{ S = "Abu", T = "Disfruta cada rincón. Los últimos días se recuerdan tanto como los primeros." },
			{ S = "Familia", T = "Esta tarde vamos todos a la ceremonia. Con la cámara. Y con pañuelos, por si acaso." },
		} },
		Llegada = { Lines = {
			{ S = "Nico", T = "¡{nombre}! ¿Te das cuenta? Es el último día. El último. Mañana ya no venimos. Qué raro." },
			{ S = "Sara", T = "Técnicamente venimos cinco años. Hoy termina un capítulo, no el libro." },
			{ S = "Omar", T = "Propongo una vuelta por todo el cole. Para despedirnos de cada sitio. Y del comedor, sobre todo." },
			{ S = "Narrador", T = "«{grupo}» recorre el colegio por última vez.", If = { Memories = { "PrimerGrupo" } } },
		} },

		Rec_Pupitre = { Lines = {
			recuerdo("Tu primer día. La clase era enorme y no conocías a nadie."),
			recuerdo("Te sentaste junto a Sara, y te habló de escarabajos durante media hora.", { Choices = { Asiento = "Sara" } }),
			recuerdo("Te sentaste junto a Nico, que te enseñó su balón firmado (por él mismo).", { Choices = { Asiento = "Nico" } }),
			recuerdo("Te sentaste junto a Mateo, el nuevo, que no se atrevía a hablar.", { Choices = { Asiento = "Mateo" } }),
			recuerdo("Y en el pasillo, a Mateo se le cayeron los libros. Tú le ayudaste a recogerlos. Tu primer amigo.", { Memories = { "PrimerAmigo" } }),
			recuerdo("Un día viste a Mateo comiendo solo… y te sentaste con él.", { Memories = { "SegundaOportunidad" } }),
			{ S = "Mateo", T = "Yo también me acuerdo. De todo. Gracias por aquel día.", If = AMIGO_MATEO },
		} },
		Rec_Taquilla = { Lines = {
			recuerdo("El día que desapareció tu mochila. Rubén, el mensajero de Bruno, y todo el colegio buscándola.", { Memories = { "MochilaPerdida" } }),
			recuerdo("Y detrás de la chapa, una nota vieja: «NO ENTRES». La nota de una niña de 1998 que hoy es tu profe.", { Memories = { "MisterioColegio" } }),
			{ S = "Omar", T = "Esta taquilla ha visto más aventuras que cualquier otra. Deberían ponerle una placa." },
		} },
		Rec_Campo = { Lines = {
			recuerdo("Tu primer partido contra el equipo de Bruno. Ganasteis. Nico corrió por todo el campo gritando.", { Flags = { "PartidoGanado" } }),
			recuerdo("Tu primer partido contra el equipo de Bruno. Perdisteis… pero Omar hizo una parada imposible.", { Flags = { "PartidoPerdido" } }),
			recuerdo("Empatasteis tu primer partido. Nico dijo que un empate es una victoria compartida.", { Flags = { "PartidoEmpate" } }),
			recuerdo("Y el torneo. La final. Medalla de oro, colgada al cuello delante de tu familia.", { Flags = { "TorneoGanado" } }),
			recuerdo("Y el torneo. La final. Medalla de plata… y Abu diciendo que del resultado casi no se acuerda.", { Flags = { "TorneoPerdido" } }),
			{ S = "Nico", T = "Aquí he pasado la mitad de mi vida. La otra mitad, hablando de fútbol." },
		} },
		Rec_Biblioteca = { Lines = {
			recuerdo("El examen imposible. Los apuntes, Marisa, y estudiar hasta tarde.", { Memories = { "PrimerExamen" } }),
			recuerdo("Aquel examen que casi suspendes. Y Lucía dándote otra oportunidad.", { Memories = { "CasiSuspendo" } }),
			recuerdo("Estudiaste con Sara. Te hizo un esquema con colores. Todavía lo tienes.", { Choices = { CompaneroEstudio = "Sara" } }),
			recuerdo("Estudiaste con Iker. Tenía una tabla para todo. Hasta para los descansos.", { Choices = { CompaneroEstudio = "Iker" } }),
			recuerdo("Estudiaste con Mateo, que explicaba los problemas con dibujos.", { Choices = { CompaneroEstudio = "Mateo" } }),
			{ S = "Marisa", T = "(desde el mostrador) Venid a verme en el instituto. Los libros no se jubilan. Y yo tampoco." },
		} },
		Rec_Almacen = { Lines = {
			recuerdo("Aquí encontraste el libro de Hugo, «La isla de las mil llaves». Nadie sabía que era suyo.", { Flags = { "SabeLibroHugo" } }),
			recuerdo("La persecución por el colegio. Esconderte de Ramón. Y Hugo diciendo «Yo no quería».", { Memories = { "LosMalotes" } }),
			recuerdo("Y el día que Hugo dejó a Bruno y se vino con vosotros.", { Memories = { "HugoAmigo" } }),
			recuerdo("Y el caso de las bromas del colegio, resuelto con una lupa.", { Memories = { "Detective" } }),
			{ S = "Hugo", T = "Aquí empezó todo, ¿verdad? Si no hubieras encontrado mi libro… Me alegro de que lo encontraras.", If = CON_HUGO },
		} },
		Rec_Banco = { Lines = {
			recuerdo("En un banco como este os pusisteis nombre: «{grupo}».", { Memories = { "PrimerGrupo" } }),
			recuerdo("La tarde en el parque. Querías trabajar en un hospital y salvar vidas.", { Choices = { SuenoInfancia = "Medicina" } }),
			recuerdo("La tarde en el parque. Querías inventar cosas que no existen.", { Choices = { SuenoInfancia = "Ingenieria" } }),
			recuerdo("La tarde en el parque. Querías pintar cosas que la gente no olvidara.", { Choices = { SuenoInfancia = "Arte" } }),
			recuerdo("La tarde en el parque. Querías ser deportista de verdad.", { Choices = { SuenoInfancia = "Deporte" } }),
			recuerdo("La tarde en el parque. Querías defender a la gente que no puede defenderse.", { Choices = { SuenoInfancia = "Derecho" } }),
			recuerdo("La tarde en el parque. Querías tener tu propio negocio.", { Choices = { SuenoInfancia = "Economia" } }),
			recuerdo("Y Bigotes, el gato del cole, durmiendo al sol justo aquí.", { Memories = { "GatoDelCole" } }),
			{ S = "Sara", T = "¿Seguís queriendo ser lo que dijimos aquella tarde? Yo sí. Aunque ahora también quiero ser astronauta." },
		} },

		Capsula = { Lines = {
			{ S = "Lucia", T = "Lo prometí: la cápsula se abre el último día de colegio. Y yo esta vez no me olvido." },
			{ S = "Ramon", T = "Código secreto… clac. Abierta. Treinta años guardando llaves y esta es la que más me ha gustado abrir." },
			{ S = "Narrador", T = "Dentro está todo lo que metió la clase: dibujos, predicciones, cromos… y lo tuyo." },
			{ S = "Narrador", T = "Tu carta: «Querido yo del último día: ¿has sido valiente? ¿Sigues con tus amigos? Espero que sí.»", If = { Choices = { Capsula = "Carta" } } },
			{ S = "Narrador", T = "Tu dibujo del grupo. Omar sale con un bocadillo. Omar dice que es el retrato más realista de su vida.", If = { Choices = { Capsula = "Dibujo" } } },
			{ S = "Narrador", T = "Tu predicción: «Nico será futbolista». Nico la lee tres veces y se la guarda en el bolsillo sin decir nada.", If = { Choices = { Capsula = "Prediccion" } } },
			{ S = "Narrador", T = "Tu pregunta: «¿Seguimos siendo amigos?». Nadie contesta con palabras. Omar te da un abrazo. Luego todos.", If = { Choices = { Capsula = "Pregunta" } } },
			{ S = "Lucia", T = "Mi clase de 1998 hizo esto mismo. Y aquí estoy, veintitantos años después, en la misma sala. Las cosas importantes vuelven." },
		} },
		Ceremonia = { Lines = {
			{ S = "Lucia", T = "Familias, alumnos: hoy 4.º A termina la primaria." },
			{ S = "Lucia", T = "Os he visto llegar con mochilas más grandes que vosotros. Os he visto perder mochilas, encontrar amigos, resolver misterios…" },
			{ S = "Lucia", T = "…ganar torneos, perderlos, y aprender a dar la mano. Estoy muy orgullosa de cada uno." },
			{ S = "Narrador", T = "Uno a uno, subís a recoger el diploma. Cuando dicen tu nombre, tu familia aplaude tan fuerte que Marta se ríe." },
			{ S = "Andres", T = "¡Y el premio a la deportividad de todo el curso es para {nombre}!", If = { Traits = { Deportividad = 5 } } },
			{ S = "Marta", T = "♪ Y ahora, todos juntos, la canción del festival ♪" },
		} },
		Adios_Lucia = { Lines = {
			{ S = "Lucia", T = "{nombre}. Ven aquí. Ha sido un placer ser tu profe." },
			{ S = "Lucia", T = "Y gracias por guardar mi secreto. La foto sigue en mi mesa.", If = { Flags = { "SecretoLucia" } } },
			{ S = "Lucia", T = "Y gracias por devolverme la foto. Ya no me da vergüenza. Casi.", If = { Choices = { FotoLucia = "Devolver" } } },
			{ S = "Lucia", T = "Toda la clase me llama ya «la de las coletas». Me encanta. No se lo digas.", If = { Choices = { FotoLucia = "Clase" } } },
			{ S = "Lucia", T = "Cuando seas mayor, vuelve a visitarme. Los profes queremos saber cómo acaba cada historia." },
		}, Effects = { Rel = { Lucia = 5 } } },
		Adios_Bruno = { Lines = {
			{ S = "Bruno", T = "Eh. Tú." },
			{ S = "Bruno", T = "Cuando hablaste conmigo, cara a cara… nadie había hecho eso. Todos se chivaban o se callaban.", If = { Flags = { "Bruno_HablasteConEl" } } },
			{ S = "Bruno", T = "Lo de la limonada del festival… eso estuvo bien. Muy bien.", If = { Choices = { FestivalBruno = "Ayudar" } } },
			{ S = "Bruno", T = "Todavía me acuerdo de cuando me acusaste de lo de las bromas. No fui yo. Pero bueno. Ya pasó.", If = { Flags = { "AcusasteABruno" } } },
			{ S = "Bruno", T = "Y el torneo. Me ganaste. Todavía me duele. Un poquito.", If = { Flags = { "TorneoGanado" } } },
			{ S = "Bruno", T = "Y el torneo. Te gané. Pero fue la final más difícil que he jugado.", If = { Flags = { "TorneoPerdido" } } },
			{ Ask = "¿Qué le dices a Bruno?", Options = {
				{ T = "«En el instituto, ¿empezamos de cero?»", Effects = { Choice = { AdiosBruno = "DeCero" }, Rel = { Bruno = 10 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Bruno", T = "…De cero. Vale. Pero en fútbol no te voy a dejar ganar ni en el instituto." },
				} },
				{ T = "«Suerte, Bruno. De verdad.»", Effects = { Choice = { AdiosBruno = "Suerte" }, Rel = { Bruno = 5 } }, Then = {
					{ S = "Bruno", T = "Suerte. …Tú también. Y lo digo de verdad. No te acostumbres." },
				} },
				{ T = "«Ya nos veremos.»", Effects = { Choice = { AdiosBruno = "Seco" } }, Then = {
					{ S = "Bruno", T = "Ya nos veremos. Eso seguro." },
				} },
			} },
			{ S = "Ruben", T = "(Rubén, por detrás) Adiós, {nombre}. Gracias por perdonarme lo de la mochila.", If = { Flags = { "Ruben_Perdonado" } } },
		} },
		Adios_Ramon = { Lines = {
			{ S = "Ramon", T = "Otro curso que se va. Y yo aquí, con mis llaves." },
			{ S = "Ramon", T = "Toma, un recuerdo: un llavero con el número 13. Para que no se te olvide que las puertas cerradas a veces esconden cosas bonitas." },
		}, Effects = { Rel = { Ramon = 5 }, Items = { Llavero13 = 1 } } },
		Promesa = { Lines = {
			{ S = "Omar", T = "Bueno. ¿Y ahora qué? En el instituto habrá cientos de personas. Y no conoceremos a nadie." },
			{ S = "Nico", T = "¡Nos conoceremos a nosotros! Eso ya es algo." },
			{ S = "Sara", T = "Propongo una promesa. Formal. Con las manos juntas. {nombre}, tú la dices." },
			{ S = "Mateo", T = "Yo llegué sin conocer a nadie. Y ahora mirad. Así que el instituto… no me da miedo. Casi.", If = AMIGO_MATEO },
			{ Ask = "¿Qué prometéis?", Options = {
				{ T = "«Pase lo que pase, seguimos juntos.»", Effects = { Choice = { Promesa = "Juntos" }, Traits = { Empatia = 1 }, Rel = { Nico = 5, Sara = 5, Omar = 5 } }, Then = {
					{ S = "Omar", T = "Juntos. Hasta en el comedor del instituto, que dicen que es peor. Juntos contra el puré." },
				} },
				{ T = "«Conocer a gente nueva… sin olvidarnos nunca.»", Effects = { Choice = { Promesa = "Nuevos" }, Traits = { Valentia = 1 }, Rel = { Nico = 3, Sara = 3, Omar = 3 } }, Then = {
					{ S = "Sara", T = "Me gusta. Crecer sin perder nada. Técnicamente, es lo más difícil. Y lo más bonito." },
				} },
				{ T = "«Quedar en el banco del parque cada verano.»", Effects = { Choice = { Promesa = "Banco" }, Traits = { Responsabilidad = 1 }, Rel = { Nico = 4, Sara = 4, Omar = 4 } }, Then = {
					{ S = "Nico", T = "¡Cada verano! ¡Y el que no venga, paga los helados!" },
				} },
			} },
			{ S = "Narrador", T = "Os quedáis un rato más en el patio. Nadie quiere ser el primero en irse." },
		} },
	},
}
