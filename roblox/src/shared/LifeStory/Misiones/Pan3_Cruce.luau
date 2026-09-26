-- LA PANDILLA 3 · «EL CRUCE DE CAMINOS» (20-30 min) — la decisión que marca tu vida
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.43.
--
-- Rayo, expulsado y cada vez más solo, te ofrece «un negocio»: vender camisetas falsas del Altamar a la
-- salida del estadio. Nerea quiere salir de la pandilla. Tú eliges tu camino:
--  * Entrar en el negocio → Camino_Delincuente (dinero fácil, Rebeldía; en el estadio te ve Nico: aún
--    puedes echarte atrás). Si sigues, 3 h después la policía desmantela el puesto (Eco_Redada).
--  * Alejarte y ayudar a Nerea → Camino_Trabajador (Carmen le abre un taller de cómic).
--  * Intentar sacar a Rayo → Camino_Trabajador + RayoCambia (Tomás le ofrece aprender en su taller).
-- Años después, ya de adulto, Rayo vuelve a aparecer (Eco_RayoAdulto) y lo que pase depende de esto.

local V = Vector3.new

local NEGOCIO = { Choices = { Camino = "Negocio" } }
local ALEJARSE = { Choices = { Camino = "Alejarse" } }
local SALVAR = { Choices = { Camino = "Salvar" } }

return {
	Id = "Pan3_Cruce",
	Kind = "Main",
	Title = "El cruce de caminos",
	Description = "Rayo te ofrece dinero fácil. Nerea quiere salir. Hay decisiones que marcan quién vas a ser.",
	Chapter = "Adolescente_Instituto",
	AgeRange = { 15, 15 },
	Duration = { 20, 30 },
	Difficulty = 3,
	Type = "Historia · El camino (bien o mal)",
	Requires = { Completed = { "Ins04_PrimerEmpleo" }, StageProgress = 0.52 },
	Npcs = { "Rayo", "Nerea", "Nico", "Carmen", "Tomas", "Familia", "Abu" },
	Locations = { "Parque", "PatioInstituto", "EstadioAltamar", "AulaInstituto", "Gasolinera", "HomeSalon" },
	Next = { "Ins05_ElRumor" },
	Outcomes = { "Camino delincuente (con una última oportunidad)", "Camino trabajador", "Salvar a Rayo" },

	Moment = "El cruce de caminos",
	Memory = "ElCruce",
	Rewards = { Later = {
		{ AfterHours = 3, Start = "Eco_Redada", If = { Flags = { "Camino_Delincuente" } } },
		{ AfterHours = 12, Start = "Eco_RayoAdulto" },
	} },

	Steps = {
		{ Type = "Transition", Text = "Unos meses después. Tercero de la ESO.", Seconds = 3 },
		{ Type = "Reach", Place = "Parque", Text = "Rayo está en el parque, solo", Actors = { { Npc = "Rayo", Place = "Parque", Offset = V(-12, 0, 8), Mode = "Sit" } } },
		{ Type = "Talk", Npc = "Rayo", Dialogue = "Oferta", Text = "Habla con Rayo", Actors = { { Npc = "Rayo", Place = "Parque", Offset = V(-12, 0, 8), Mode = "Sit" } } },
		{ Type = "Reach", Place = "PatioInstituto", Text = "Nerea quiere hablar contigo en el patio", Actors = { { Npc = "Nerea", Place = "PatioInstituto", Offset = V(4, 0, 4), Mode = "Sit" } } },
		{ Type = "Talk", Npc = "Nerea", Dialogue = "Nerea", Text = "Siéntate con Nerea", Actors = { { Npc = "Nerea", Place = "PatioInstituto", Offset = V(4, 0, 4), Mode = "Sit" } } },

		{ Type = "Choice", Key = "Camino", Text = "¿Qué camino eliges?",
			Options = {
				{ Id = "Negocio", Text = "Entrar en el negocio de Rayo: dinero fácil", Effects = { Flags = { "Camino_Delincuente" }, Traits = { Rebeldia = 3 }, Rel = { Rayo = 8, Nerea = -6 } } },
				{ Id = "Alejarse", Text = "Alejarte de la pandilla y ayudar a Nerea a salir", Effects = { Flags = { "Camino_Trabajador" }, Traits = { Responsabilidad = 2 }, Rel = { Nerea = 10, Rayo = -4 } } },
				{ Id = "Salvar", Text = "Intentar que Rayo lo deje (y ofrecerle otra cosa)", Effects = { Flags = { "Camino_Trabajador" }, Traits = { Empatia = 2, Valentia = 1 }, Rel = { Rayo = 4, Nerea = 6 } } },
			} },

		-- El negocio
		{ Type = "Reach", Place = "EstadioAltamar", Text = "Sábado: vende camisetas falsas del Altamar a la salida del estadio", If = NEGOCIO,
			Actors = { { Npc = "Rayo", Place = "EstadioAltamar", Offset = V(-6, 0, 6) } } },
		{ Type = "Scene", Dialogue = "Estadio", If = NEGOCIO,
			Actors = { { Npc = "Rayo", Place = "EstadioAltamar", Offset = V(-6, 0, 6) }, { Npc = "Nico", Place = "EstadioAltamar", Offset = V(4, 0, 4) } } },

		-- Alejarse con Nerea
		{ Type = "Reach", Place = "AulaInstituto", Text = "Acompaña a Nerea a hablar con Carmen, la orientadora", If = ALEJARSE,
			Actors = { { Npc = "Carmen", Place = "AulaInstituto", Offset = V(0, 0, -6) }, { Npc = "Nerea", Mode = "Follow" } } },
		{ Type = "Scene", Dialogue = "Carmen", If = ALEJARSE,
			Actors = { { Npc = "Carmen", Place = "AulaInstituto", Offset = V(0, 0, -6) }, { Npc = "Nerea", Place = "AulaInstituto", Offset = V(2, 0, -3) } } },

		-- Salvar a Rayo
		{ Type = "Reach", Place = "Gasolinera", Text = "Ve al taller de Tomás (gasolinera): a Rayo le encantan los motores", If = SALVAR,
			Actors = { { Npc = "Tomas", Place = "Gasolinera", Offset = V(0, 0, 4) } } },
		{ Type = "Talk", Npc = "Tomas", Dialogue = "Tomas", Text = "Habla con Tomás", If = SALVAR, Actors = { { Npc = "Tomas", Place = "Gasolinera", Offset = V(0, 0, 4) } } },
		{ Type = "Reach", Place = "Parque", Text = "Vuelve al parque: díselo a Rayo", If = SALVAR, Actors = { { Npc = "Rayo", Place = "Parque", Offset = V(-12, 0, 8), Mode = "Sit" } } },
		{ Type = "Talk", Npc = "Rayo", Dialogue = "Salvar", Text = "Habla con Rayo", If = SALVAR, Actors = { { Npc = "Rayo", Place = "Parque", Offset = V(-12, 0, 8), Mode = "Sit" } } },

		-- En casa: el espejo
		{ Type = "Transition", Text = "Esa noche…", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Espejo", Teleport = "HomeSalon",
			Actors = { { Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) }, { Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2), Mode = "Sit" } } },
	},

	Dialogues = {
		Oferta = { Lines = {
			{ S = "Rayo", T = "Tres días de expulsión. Mi madre ni se ha enterado. Trabaja de noche. Duerme de día. Somos compañeros de piso, más o menos." },
			{ S = "Rayo", T = "Por lo del súper. Y tú… tú no dijiste nada. Eso no se me olvida.", If = { Flags = { "Pillado" } } },
			{ S = "Rayo", T = "Tú no viniste. Da igual. Te voy a dar otra oportunidad. Porque me caes bien. No sé por qué.", If = { NotFlags = { "Hurto" } } },
			{ S = "Rayo", T = "Tengo un negocio. Camisetas del Altamar. Iguales que las de verdad, a una cuarta parte del precio. Las vendemos a la salida del estadio." },
			{ S = "Rayo", T = "Cincuenta pavos por tarde. Nadie sale herido. El club tiene millones. ¿Qué me dices?" },
			{ S = "Narrador", T = "Cincuenta. Por una tarde. Piensas en todo lo que se puede hacer con cincuenta." },
		} },
		Nerea = { Lines = {
			{ S = "Nerea", T = "Me voy de la pandilla. Ya está. Estoy harta de correr, de mentir en casa y de que Rayo decida por mí." },
			{ S = "Nerea", T = "Pero me da miedo. Si me voy, no tengo a nadie. En mi clase soy «la de la pandilla de Rayo». Nadie se me acerca." },
			{ S = "Nerea", T = "Tú me dijiste que mis dibujos eran buenos. Nadie me había dicho eso. Nunca.", If = { Flags = { "AmigaNerea" } } },
			{ S = "Nerea", T = "Rayo te ha ofrecido lo de las camisetas, ¿no? A mí también. ¿Qué vas a hacer?" },
		} },
		Estadio = { Lines = {
			{ S = "Narrador", T = "A la salida del partido, cientos de personas. Rayo abre una bolsa: camisetas del Altamar. Iguales. Casi." },
			{ S = "Rayo", T = "Tú grita: «¡Camisetas, a diez!». Yo cobro. Si ves a un policía, silba." },
			{ S = "Narrador", T = "Vendes una. Dos. Cinco. Es fácil. Demasiado fácil." },
			{ S = "Narrador", T = "Y entonces, entre la gente, alguien se para delante de ti con la bolsa de deporte del juvenil del Altamar. Es Nico." },
			{ S = "Nico", T = "¿{nombre}? ¿Qué haces con… esas camisetas? Son falsas. Son de MI equipo. ¿En serio?" },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "«Es solo un negocio. No te metas.»", Effects = { Rel = { Nico = -15 }, Money = 50, Traits = { Rebeldia = 1 } }, Then = {
					{ S = "Nico", T = "…Vale. No me meto. Pero no me hables en el recreo. No sé quién eres." },
					{ S = "Narrador", T = "Esa tarde ganas cincuenta. Te pesan en el bolsillo más que cualquier mochila." },
				} },
				{ T = "Dejas la bolsa en el suelo y te vas con Nico", Effects = { Unflags = { "Camino_Delincuente" }, Flags = { "Camino_Trabajador", "Redimido" }, Rel = { Nico = 6, Rayo = -8 }, Traits = { Valentia = 2 } }, Then = {
					{ S = "Rayo", T = "¡Eh! ¿Adónde vas? ¡¿ADÓNDE VAS?!" },
					{ S = "Nico", T = "Vámonos. Te invito a un bocadillo. Y no se lo cuento a nadie. Bueno, a Omar sí. A Omar se lo cuento todo." },
				} },
			} },
		} },
		Carmen = { Lines = {
			{ S = "Carmen", T = "Nerea, ¿verdad? He visto tus dibujos. {nombre} me los ha enseñado. Con tu permiso, espero." },
			{ S = "Carmen", T = "Los jueves hay un taller de cómic en la biblioteca del campus. Lo lleva Toni, el tío de Leire. Creo que te encantaría." },
			{ S = "Nerea", T = "¿Un taller de… cómic? ¿Con gente que dibuja? …Vale. Pero {nombre} viene conmigo el primer día." },
			{ S = "Carmen", T = "Salir de un sitio así cuesta mucho. Hacerlo acompañado, un poco menos. Bien hecho, los dos." },
		} },
		Tomas = { Lines = {
			{ S = "Tomas", T = "¿Un chaval que se pasa el día desmontando motos que no son suyas? Hmm. Eso es talento mal usado." },
			{ S = "Tomas", T = "Que venga mañana a las ocho. Si llega a las ocho y cinco, que no venga. Si llega a las ocho, le enseño todo lo que sé." },
		} },
		Salvar = { Lines = {
			{ S = "Rayo", T = "¿Tú otra vez? ¿Vienes a comprarme una camiseta?" },
			{ S = "Narrador", T = "Le cuentas lo de Tomás. Un taller de verdad. Motores de verdad. Mañana a las ocho." },
			{ S = "Rayo", T = "¿Por qué haces esto? Tú siempre me has dicho que no a todo. Eres la única persona que no me ha dejado tirado. Qué raro.", If = { RelBelow = { Rayo = 5 } } },
			{ S = "Rayo", T = "¿Por qué haces esto? Estabas en todo conmigo. Podrías seguir. Y vienes a sacarme a mí.", If = { Rel = { Rayo = 5 } } },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "«Porque te mereces algo mejor que correr delante de la policía.»", Effects = { Flags = { "RayoCambia" }, Rel = { Rayo = 10 } }, Then = {
					{ S = "Rayo", T = "…A las ocho. Vale. Pero si el viejo es un pesado, me piro." },
					{ S = "Narrador", T = "No se pira. Al día siguiente llega a las ocho menos cuarto." },
				} },
				{ T = "«Porque eres mi amigo. Aunque a veces no lo parezca.»", Effects = { Flags = { "RayoCambia" }, Rel = { Rayo = 12 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Rayo", T = "(se frota la cara) …Qué pesado o pesada. Vale. A las ocho. Y no se lo digas a nadie de la pandilla." },
				} },
			} },
		} },
		Espejo = { Lines = {
			{ S = "Narrador", T = "Esa noche te miras en el espejo del baño. Quince años. Te preguntas quién estás siendo." },
			{ S = "Narrador", T = "Tienes cincuenta euros escondidos en un calcetín. Y un mensaje de Nico sin contestar.", If = { Flags = { "Camino_Delincuente" } } },
			{ S = "Familia", T = "Te noto rara o raro últimamente. Llegas tarde, no hablas… Sabes que puedes contarme lo que sea, ¿verdad? Lo que sea.", If = { Flags = { "Camino_Delincuente" } } },
			{ S = "Abu", T = "Yo también tuve malas compañías a tu edad. Lo difícil no es entrar. Es salir. Pero se sale. Siempre se sale.", If = { Flags = { "Camino_Delincuente" } } },
			{ S = "Narrador", T = "Hiciste cosas de las que no estás orgulloso u orgullosa. Pero hoy has elegido otra cosa. Y eso también cuenta. Mucho.",
				If = { Flags = { "Camino_Trabajador" }, Traits = { Rebeldia = 2 } }, Effects = { Flags = { "Redimido" } } },
			{ S = "Narrador", T = "Nunca te dejaste arrastrar. Y hoy, además, has tendido la mano a alguien. Así se construye una persona.", If = { Flags = { "Camino_Trabajador" }, TraitsBelow = { Rebeldia = 2 } } },
			{ S = "Familia", T = "Me ha llamado la madre de Nerea. Dice que su hija ha vuelto a dibujar. Que ha sido gracias a ti. …Ven aquí. Abrazo. No te escapes.", If = ALEJARSE },
			{ S = "Familia", T = "Me ha contado Tomás, el del taller, que le has llevado a un chaval. Que llegó a las ocho menos cuarto. Qué orgullo me das.", If = SALVAR },
		} },
	},
}
