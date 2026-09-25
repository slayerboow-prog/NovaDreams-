-- MISIÓN 04 · «LOS MALOTES» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.14.
--
-- Burlas en el recreo → tu objeto favorito desaparece → investigación → persecución por el colegio
-- (¡corre con Shift!, escóndete de Ramón, atajo por el aula de música) → alcanzas a Hugo, que no
-- quería participar → decisión (Lucía, hablar con ellos, tu grupo o dejarlo) → consecuencias.
-- Sin violencia: nadie pega a nadie. Los "malotes" son personas con sus motivos.

local V = Vector3.new

local AMIGO_MATEO = { Flags = { "AyudasteAMateo" } }
local LLEVA_CROMO = { Flags = { "LlevaCromo" } }
local SIN_CROMO = { NotFlags = { "LlevaCromo" } }

local GRUPO_BANCO = {
	{ Npc = "Nico", Place = "SpotGrupoEstudiantes", Offset = V(-2, 0, 0) },
	{ Npc = "Sara", Place = "SpotGrupoEstudiantes", Offset = V(1, 0, 1) },
	{ Npc = "Omar", Place = "SpotGrupoEstudiantes", Offset = V(3, 0, -1) },
	{ Npc = "Mateo", Place = "SpotGrupoEstudiantes", Offset = V(-4, 0, 1), If = AMIGO_MATEO },
}
local MALOTES_PATIO = {
	{ Npc = "Bruno", Place = "SpotGrupoEstudiantes", Offset = V(0, 0, 6) },
	{ Npc = "Ruben", Place = "SpotGrupoEstudiantes", Offset = V(2.5, 0, 7) },
	{ Npc = "Hugo", Place = "SpotGrupoEstudiantes", Offset = V(-3, 0, 8) },
}

local function joined(...): { any }
	local out = {}
	for _, list in { ... } do
		for _, item in list do
			table.insert(out, item)
		end
	end
	return out
end

local TESTIGOS = {
	{ Npc = "Nico", Place = "SpotGrupoDeportistas" },
	{ Npc = "Sara", Place = "AulaA", Offset = V(2, 0, -4) },
	{ Npc = "Omar", Place = "SpotInformantePasillo" },
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	{ Npc = "Ramon", Place = "Conserjeria" },
	{ Npc = "Mateo", Place = "JuegosColegio", Offset = V(-3, 0, 2), If = AMIGO_MATEO },
}

-- La persecución: los tres salen corriendo del pasillo. Bruno y Rubén (rápidos) escapan por la puerta;
-- Hugo (el que no quería) corre menos y acaba escondido detrás del gimnasio.
local HUYEN = {
	{ Npc = "Hugo", Place = "PasilloColegio", Offset = V(-3, 0, 2), Mode = "Flee", Speed = 16, Prompt = false,
		Route = { "PasilloColegio", "Patio", "GimnasioColegio", "SpotGimnasioPuerta", "AlmacenFuera" } },
	{ Npc = "Bruno", Place = "PasilloColegio", Offset = V(0, 0, 3), Mode = "Flee", Speed = 20, Prompt = false,
		Route = { "PasilloColegio", "Patio", "SpotGimnasioPuerta", "EntradaColegio" } },
	{ Npc = "Ruben", Place = "PasilloColegio", Offset = V(3, 0, 2), Mode = "Flee", Speed = 20, Prompt = false,
		Route = { "PasilloColegio", "Patio", "CampoColegio", "EntradaColegio" } },
}
local HUGO_ESCONDIDO = { Npc = "Hugo", Place = "AlmacenFuera", Offset = V(0, 0, 0) }

return {
	Id = "Cole04_Malotes",
	Kind = "Main",
	Title = "Los malotes",
	Description = "Bruno y su pandilla se han pasado de la raya. Esta vez, algo tuyo ha desaparecido.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 7, 8 },
	Duration = { 20, 30 },
	Difficulty = 3,
	Type = "Historia · Conflicto",
	Requires = { Completed = { "Cole03_Grupo" }, StageProgress = 0.18 },
	Npcs = { "Bruno", "Ruben", "Hugo", "Nico", "Sara", "Omar", "Mateo", "Lucia", "Ramon" },
	Locations = { "Patio", "AulaA", "PasilloColegio", "GimnasioColegio", "SpotGimnasioPuerta", "AlmacenFuera", "AulaMusica" },
	Next = { "Cole05_Venganza" },
	Outcomes = { "Lucía interviene", "Hablas con Bruno (lo de su hermano)", "Tu grupo se planta", "Lo dejas estar" },

	Moment = "Recuperaste lo que era tuyo… y conociste de verdad a Hugo",
	Memory = "LosMalotes",
	Rewards = { Later = { { AfterHours = 2, Start = "Eco_Hugo" } } },

	Props = {
		Escondite = { Kind = "Caja", Name = "Detrás de las cajas", Prompt = "Esconderte", Place = "Patio", Offset = V(-6, 0, -14), Dialogue = "Escondido", Once = true },
		Atajo = { Kind = "Marcador", Name = "Atajo por el aula de música", Prompt = "Colarte", Place = "AulaMusica", Dialogue = "Atajo", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Unas semanas después…", Seconds = 3 },
		{ Type = "Reach", Place = "Patio", Text = "Es la hora del recreo: busca a tu grupo", Actors = GRUPO_BANCO },
		{ Type = "Scene", Dialogue = "Burlas", Actors = joined(GRUPO_BANCO, MALOTES_PATIO) },

		-- Tu objeto favorito desaparece
		{ Type = "Reach", Place = "AulaA", Text = "Vuelve a clase", Actors = { { Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) } } },
		{ Type = "Scene", Dialogue = "SinCromo", If = LLEVA_CROMO, Effects = { Take = { CromoSuerte = 1 }, Flags = { "ObjetoCromo" } } },
		{ Type = "Scene", Dialogue = "SinFoto", If = SIN_CROMO, Effects = { Take = { FotoGrupo = 1 }, Flags = { "ObjetoFoto" } } },

		-- Investigar
		{ Type = "Group", Text = "Averigua qué ha pasado", Need = 3,
			Steps = {
				{ Type = "Talk", Npc = "Mateo", Dialogue = "Pista_Mateo", Text = "Mateo quiere decirte algo", If = AMIGO_MATEO },
				{ Type = "Talk", Npc = "Nico", Dialogue = "Pista_Nico", Text = "Nico (en la pista)" },
				{ Type = "Talk", Npc = "Sara", Dialogue = "Pista_Sara", Text = "Sara (en el aula)" },
				{ Type = "Talk", Npc = "Omar", Dialogue = "Pista_Omar", Text = "Omar (en el pasillo)" },
				{ Type = "Talk", Npc = "Lucia", Dialogue = "Pista_Lucia", Text = "Lucía (en la pizarra)" },
				{ Type = "Talk", Npc = "Ramon", Dialogue = "Pista_Ramon", Text = "Ramón (en conserjería)" },
			},
			Actors = TESTIGOS },

		-- ¡Ahí están! La persecución
		{ Type = "Reach", Place = "PasilloColegio", Text = "Ve al pasillo", Actors = MALOTES_PATIO },
		{ Type = "Scene", Dialogue = "LosVes", Actors = {
			{ Npc = "Bruno", Place = "PasilloColegio", Offset = V(0, 0, 3) },
			{ Npc = "Ruben", Place = "PasilloColegio", Offset = V(3, 0, 2) },
			{ Npc = "Hugo", Place = "PasilloColegio", Offset = V(-3, 0, 2) },
		} },
		{ Type = "Reach", Place = "Patio", Text = "¡Síguelos! Corre (Shift) hacia el patio", Actors = HUYEN, Props = { "Atajo" } },
		{ Type = "Scene", Dialogue = "RamonAparece", Actors = joined(HUYEN, { { Npc = "Ramon", Place = "Patio", Offset = V(8, 0, -10) } }) },
		{ Type = "Use", Prop = "Escondite", Text = "¡Escóndete detrás de las cajas antes de que Ramón te vea!",
			Timeout = { After = 12, Flags = { "PilladoCorriendo" } },
			Actors = joined(HUYEN, { { Npc = "Ramon", Place = "Patio", Offset = V(8, 0, -10) } }) },
		{ Type = "Scene", Dialogue = "Pillado", If = { Flags = { "PilladoCorriendo" } },
			Actors = joined(HUYEN, { { Npc = "Ramon", Place = "Patio", Offset = V(8, 0, -10) } }) },
		{ Type = "Chase", Npc = "Hugo", Catch = 7, Text = "¡Alcanza a Hugo! Se ha ido hacia el gimnasio (atajo: el aula de música)",
			Actors = HUYEN, Props = { "Atajo" } },

		-- Hugo
		{ Type = "Scene", Dialogue = "Hugo", Actors = { HUGO_ESCONDIDO },
			Effects = { Rel = { Hugo = 10 } } },
		{ Type = "Scene", Dialogue = "Devuelve", If = LLEVA_CROMO, Actors = { HUGO_ESCONDIDO }, Effects = { Items = { CromoSuerte = 1 } } },
		{ Type = "Scene", Dialogue = "Devuelve", If = SIN_CROMO, Actors = { HUGO_ESCONDIDO }, Effects = { Items = { FotoGrupo = 1 } } },
		{ Type = "Scene", Dialogue = "Decision", Actors = { HUGO_ESCONDIDO } },

		-- A) Lucía
		{ Type = "Talk", Npc = "Lucia", Dialogue = "Rama_Lucia", Text = "Cuéntaselo a Lucía (en el aula)", If = { Choices = { Malotes = "Lucia" } },
			Actors = { { Npc = "Lucia", Place = "AulaA", Offset = V(-2, 0, 0) }, { Npc = "Hugo", Mode = "Follow" } } },
		-- B) Hablar con ellos
		{ Type = "Talk", Npc = "Bruno", Dialogue = "Rama_Hablar", Text = "Busca a Bruno (en la puerta del cole)", If = { Choices = { Malotes = "Hablar" } },
			Actors = { { Npc = "Bruno", Place = "SpotProfesorEntrada", Offset = V(3, 0, 0) }, { Npc = "Ruben", Place = "SpotProfesorEntrada", Offset = V(5, 0, 1) } } },
		-- C) Con tu grupo
		{ Type = "Reach", Place = "SpotGrupoEstudiantes", Text = "Ve a buscar a tu grupo (el banco del patio)", If = { Choices = { Malotes = "Grupo" } },
			Actors = GRUPO_BANCO },
		{ Type = "Talk", Npc = "Bruno", Dialogue = "Rama_Grupo", Text = "Id juntos a hablar con Bruno (puerta del cole)", If = { Choices = { Malotes = "Grupo" } },
			Actors = {
				{ Npc = "Bruno", Place = "SpotProfesorEntrada", Offset = V(3, 0, 0) },
				{ Npc = "Ruben", Place = "SpotProfesorEntrada", Offset = V(5, 0, 1) },
				{ Npc = "Nico", Mode = "Follow" },
				{ Npc = "Sara", Mode = "Follow" },
				{ Npc = "Omar", Mode = "Follow" },
			} },
		-- D) Dejarlo estar
		{ Type = "Scene", Dialogue = "Rama_Ignorar", If = { Choices = { Malotes = "Ignorar" } }, Actors = { HUGO_ESCONDIDO } },

		{ Type = "Scene", Dialogue = "Cierre" },
	},

	Dialogues = {
		Burlas = { Lines = {
			{ S = "Narrador", T = "Recreo. Tu grupo está en el banco de siempre. Hasta que llegan ellos." },
			{ S = "Bruno", T = "Mira, mira. El grupito del banco. ¿Qué pasa, os habéis perdido?" },
			{ S = "Bruno", T = "¿Seguís con ese nombre? «{grupo}». Suena a club de abuelos." },
			{ S = "Ruben", T = "(Rubén se ríe… pero bajito, y no te mira)", If = { Flags = { "Ruben_Perdonado" } } },
			{ S = "Ruben", T = "¡Cuidado, que aquí hay quien se chiva! ¡Que viene Lucía! Jajaja.", If = { Flags = { "AvisasteALucia" } } },
			{ S = "Bruno", T = "El otro día ganasteis de chiripa. La próxima os vais a enterar.", If = { Flags = { "PartidoGanado" } } },
			{ S = "Hugo", T = "…Bruno, vámonos ya." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Ignorarles y seguir hablando con los tuyos", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Sara", T = "Estadísticamente, el que busca pelea se aburre en treinta segundos." },
				} },
				{ T = "«Por lo menos nosotros tenemos nombre, Bruno.»", Effects = { Traits = { Humor = 1 }, Rel = { Bruno = -3, Nico = 3 } }, Then = {
					{ S = "Nico", T = "¡Jajaja! ¡Toma ya!" },
					{ S = "Bruno", T = "Muy gracioso. Ya te reirás menos." },
				} },
				{ T = "Levantarte y ponerte delante: «Déjanos en paz.»", Effects = { Traits = { Valentia = 2 }, Rel = { Bruno = -2 } }, Then = {
					{ S = "Bruno", T = "Uy, qué valiente. Vale, vale. Ya nos vamos." },
				} },
			} },
			{ S = "Narrador", T = "Se van riéndose. Al pasar junto a tu mochila, Bruno le da un golpecito con el pie. Nadie le da importancia." },
		} },

		SinCromo = { Lines = {
			{ S = "Narrador", T = "Vuelves a clase. Abres el bolsillo pequeño de la mochila, el de las emergencias…" },
			{ S = "Yo", T = "¿Mi cromo? ¿Dónde está mi cromo de la suerte?" },
			{ S = "Narrador", T = "No está. El portero legendario ha desaparecido. (Ya no está en tu inventario.)" },
		} },
		SinFoto = { Lines = {
			{ S = "Narrador", T = "Vuelves a clase y buscas en la mochila la foto del grupo, la del parque…" },
			{ S = "Yo", T = "¿Y la foto? Estaba aquí. ¡Estaba AQUÍ!" },
			{ S = "Narrador", T = "No está. La foto del grupo ha desaparecido. (Ya no está en tu inventario.)" },
		} },

		Pista_Mateo = { Lines = {
			{ S = "Mateo", T = "Lo vi. Cuando Bruno pasó junto a tu mochila, Hugo se agachó y cogió algo. Pero… ponía cara de no querer." },
		}, Effects = { Flags = { "PistaHugo" } } },
		Pista_Nico = { Lines = {
			{ S = "Nico", T = "¡Sabía que Bruno tramaba algo! Al salir del recreo iban los tres juntos, riéndose, hacia el pasillo." },
			{ S = "Nico", T = "Si quieres les reto a una carrera y el que gane se queda… vale, no, eso no funciona así." },
		} },
		Pista_Sara = { Lines = {
			{ S = "Sara", T = "Datos: los tres salieron del recreo dos minutos antes que nadie. Suelen esconderse en el pasillo, junto a las taquillas." },
			{ S = "Sara", T = "Y otro dato: Hugo no se reía. En ningún momento. Lo anoté." },
		} },
		Pista_Omar = { Lines = {
			{ S = "Omar", T = "Tengo un dibujo de hace un rato: Bruno enseñándole algo pequeño a Rubén. Y Hugo mirando al suelo." },
			{ S = "Omar", T = "Los dibujos no mienten. Bueno, a veces pongo capas. Pero en esto no." },
		} },
		Pista_Lucia = { Lines = {
			{ S = "Lucia", T = "¿Te han quitado algo? Uf. Sin pruebas no puedo acusar a nadie, {nombre}. Pero te creo." },
			{ S = "Lucia", T = "Si lo encuentras, ven a contármelo. Y nada de correr por los pasillos, ¿eh?" },
		} },
		Pista_Ramon = { Lines = {
			{ S = "Ramon", T = "¿Bruno y compañía? Hace un rato los he visto en el pasillo, junto a las taquillas. Como siempre." },
			{ S = "Ramon", T = "Y cuando les pillan, salen corriendo hacia el gimnasio. Se creen que no lo sé. Lo sé todo." },
		} },

		LosVes = { Lines = {
			{ S = "Narrador", T = "Ahí están, junto a las taquillas. Bruno tiene en la mano algo pequeño que brilla." },
			{ S = "Yo", T = "¡Eh! ¡Eso es mío!" },
			{ S = "Bruno", T = "¡Corred!" },
			{ S = "Narrador", T = "Salen disparados hacia el patio. ¡Corre tras ellos! (Mantén Shift para correr; vigila tu estamina.)" },
		} },
		RamonAparece = { Lines = {
			{ S = "Ramon", T = "¿QUIÉN ESTÁ CORRIENDO POR MI PATIO?" },
			{ S = "Narrador", T = "¡Ramón! Si te ve corriendo, te toca charla. Rápido, ¡escóndete detrás de las cajas!" },
		} },
		Escondido = { Lines = {
			{ S = "Narrador", T = "Te agachas detrás de las cajas. Ramón pasa de largo, silbando." },
			{ S = "Ramon", T = "Hmm. Juraría que he oído a alguien. Serán los gatos." },
		}, Effects = { Traits = { Curiosidad = 1 } } },
		Pillado = { Lines = {
			{ S = "Ramon", T = "¡Ajá! ¡Te pillé! ¿Tú corriendo? Esto no me lo esperaba." },
			{ S = "Yo", T = "¡Es que me han quitado una cosa! ¡Se han ido por ahí!" },
			{ S = "Ramon", T = "…Vale. Por esta vez. Hugo ha ido hacia el gimnasio. Andando, ¿eh? ANDANDO." },
		}, Effects = { Rel = { Ramon = 2 } } },
		Atajo = { Lines = {
			{ S = "Narrador", T = "Te cuelas por el aula de música (¡perdón, piano!) y sales por la otra puerta, justo al lado del gimnasio." },
		}, Effects = { Teleport = "SpotGimnasioPuerta", Traits = { Curiosidad = 1 } } },

		Hugo = { Lines = {
			{ S = "Narrador", T = "Detrás del gimnasio, Hugo se ha quedado sin aire. No sigue corriendo. Se sienta en el bordillo." },
			{ S = "Hugo", T = "Vale… vale. Me rindo. No sé correr. Nunca he sabido." },
			{ S = "Yo", T = "¿Por qué lo habéis hecho?" },
			{ S = "Hugo", T = "Yo no quería. Bruno dijo «cógelo tú, que a ti no te vigilan». Y yo… no sé decir que no." },
			{ S = "Hugo", T = "Bruno no es tan malo. Su hermano mayor se ríe de él todo el rato. Y él… hace lo mismo con los demás." },
			{ S = "Yo", T = "El otro día vi tu libro de piratas en el almacén.", If = { Flags = { "SabeLibroHugo" } } },
			{ S = "Hugo", T = "¿«La isla de las mil llaves»? ¿Lo has leído? …Nadie se fija en eso. Bruno dice que leer es de pringados.", If = { Flags = { "SabeLibroHugo" } } },
		} },
		Devuelve = { Lines = {
			{ S = "Hugo", T = "Toma. Es tuyo. Lo siento. De verdad." },
			{ S = "Narrador", T = "Lo recuperas. (Vuelve a estar en tu inventario.)" },
		} },
		Decision = { Lines = {
			{ S = "Hugo", T = "¿Y ahora qué vas a hacer?" },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Contárselo a Lucía. Esto tiene que parar.", Effects = { Choice = { Malotes = "Lucia" }, Traits = { Responsabilidad = 2 }, Rel = { Hugo = -2, Lucia = 3 } }, Then = {
					{ S = "Hugo", T = "…Vale. Iré contigo. Si voy yo también, quizá no se enfade tanto conmigo." },
				} },
				{ T = "Hablar con Bruno. Cara a cara.", Effects = { Choice = { Malotes = "Hablar" }, Traits = { Valentia = 2 }, Rel = { Hugo = 5 } }, Then = {
					{ S = "Hugo", T = "¿Sin nadie más? Qué valor. …Me gusta." },
				} },
				{ T = "Pedir ayuda a mi grupo. Juntos.", Effects = { Choice = { Malotes = "Grupo" }, Traits = { Empatia = 1, Valentia = 1 }, Rel = { Hugo = 3 } }, Then = {
					{ S = "Hugo", T = "Tenéis suerte. Un grupo de verdad. Yo tengo… a Bruno." },
				} },
				{ T = "Dejarlo estar. Ya tengo lo mío.", Effects = { Choice = { Malotes = "Ignorar" }, Rel = { Hugo = -3 } }, Then = {
					{ S = "Hugo", T = "Ya. Normal. …Bueno. Adiós." },
				} },
			} },
		} },

		Rama_Lucia = { Lines = {
			{ S = "Yo", T = "Lucía. Bruno, Rubén y Hugo me quitaron una cosa. Ya la tengo, pero…" },
			{ S = "Hugo", T = "Es verdad. Yo la cogí. Bruno me lo dijo. Pero yo la cogí." },
			{ S = "Lucia", T = "Gracias a los dos por decirlo. Hugo, eso ha sido muy valiente." },
			{ S = "Lucia", T = "Hablaré con Bruno. Y con su familia. Esto no es una broma: es hacer daño. Y hay que pararlo." },
		}, Effects = { Flags = { "Bruno_Castigado" }, Rel = { Bruno = -8, Hugo = 5 } } },
		Rama_Hablar = { Lines = {
			{ S = "Bruno", T = "¿Qué quieres? ¿Vienes a chivarte?" },
			{ S = "Yo", T = "No. Vengo a hablar contigo. Hugo me lo ha contado todo. Lo de tu hermano también." },
			{ S = "Bruno", T = "…Hugo habla demasiado." },
			{ S = "Bruno", T = "Mi hermano me llama enano. Delante de sus amigos. Todos los días. ¿Contento?" },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "Pues ya sabes lo que se siente. No se lo hagas a otros.", Effects = { Rel = { Bruno = 6 }, Traits = { Empatia = 2 } }, Then = {
					{ S = "Bruno", T = "…Ya. Vale. Lo pillo. No te prometo nada. Pero lo pillo." },
				} },
				{ T = "Eso no te da derecho a quitarme las cosas.", Effects = { Rel = { Bruno = 2 }, Traits = { Valentia = 1 } }, Then = {
					{ S = "Bruno", T = "Ya lo sé. Ya lo SÉ. …Perdona. Ya está. No me hagas repetirlo." },
				} },
			} },
			{ S = "Ruben", T = "(Rubén os mira a los dos, sorprendido. Nunca había oído a Bruno pedir perdón.)" },
		}, Effects = { Flags = { "Bruno_HablasteConEl" } } },
		Rama_Grupo = { Lines = {
			{ S = "Nico", T = "Bruno. Somos cinco. Y estamos hartos." },
			{ S = "Sara", T = "Tenemos pruebas: testigos, un dibujo de Omar y el horario. Si sigues, se lo contamos a Lucía." },
			{ S = "Omar", T = "El dibujo es muy bueno, por cierto. Sales tú con cara de culpable." },
			{ S = "Bruno", T = "…Vale, vale. Os dejamos en paz. Qué pesados." },
			{ S = "Bruno", T = "(A Hugo, que se ha quedado con vosotros) ¿Tú no vienes?" },
			{ S = "Hugo", T = "…No. Hoy no." },
		}, Effects = { Flags = { "HugoConElGrupo" }, Rel = { Hugo = 8, Nico = 3, Sara = 3, Omar = 3 } } },
		Rama_Ignorar = { Lines = {
			{ S = "Narrador", T = "Te das la vuelta y te vas. Ya tienes lo tuyo." },
			{ S = "Narrador", T = "Al girar la esquina miras atrás. Hugo sigue sentado en el bordillo, solo." },
		}, Effects = { Flags = { "HugoSolo" } } },

		Cierre = { Lines = {
			{ S = "Narrador", T = "Ese día aprendiste algo: casi nadie es malo del todo. Y casi nadie es valiente del todo." },
			{ S = "Narrador", T = "Hugo, desde la otra punta del patio, te saluda con la mano. Es la primera vez que le ves sonreír.", If = { NotFlags = { "HugoSolo" } } },
		} },
	},
}
