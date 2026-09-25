-- UNIVERSIDAD 05 · «TU PRIMER PISO» (20-30 min)
-- Ficha de diseño: docs/historia/11-misiones-episodicas.md, apartado 11.35.
--
-- Independizarse: la conversación en casa → con quién vives (Sara, Luca o a tu aire) → buscar casa con
-- el sistema de casas de verdad (HomeClaimed) → la mudanza (cajas; la caja misteriosa de tu infancia)
-- → la primera cena que te haces tú (Ate) → la primera noche: un problema de convivencia (o la soledad)
-- → {abu} viene de visita → dormir por primera vez en tu casa (Slept). Deja la marca TieneHogar (la
-- vida adulta ya no pide buscar casa otra vez).

local V = Vector3.new

local SARA = { Choices = { CompiPiso = "Sara" } }
local LUCA = { Choices = { CompiPiso = "Luca" } }
local SOLO = { Choices = { CompiPiso = "Solo" } }

local CASA_FAMILIA = {
	{ Npc = "Familia", Place = "HomeSalon", Offset = V(-4, 0, 0) },
	{ Npc = "Abu", Place = "HomeSalon", Offset = V(10, 0, -2), Mode = "Sit" },
}
local COMPIS = {
	{ Npc = "Sara", Mode = "Follow", If = SARA },
	{ Npc = "Luca", Mode = "Follow", If = LUCA },
}

return {
	Id = "Uni05_PrimerPiso",
	Kind = "Main",
	Title = "Tu primer piso",
	Description = "Llaves propias, cajas por todas partes y la nevera vacía. Te independizas.",
	Chapter = "Joven_Universidad",
	AgeRange = { 21, 21 },
	Duration = { 20, 30 },
	Difficulty = 2,
	Type = "Historia · Vida adulta",
	Requires = { Completed = { "Uni04_Practicas" }, StageProgress = 0.72 },
	Npcs = { "Familia", "Abu", "Sara", "Luca" },
	Locations = { "HomeSalon", "Universidad", "CercaDeTi" },
	Next = { "Uni06_Graduacion" },
	Outcomes = { "Con quién vives", "La caja misteriosa", "Cómo resolvéis la convivencia" },

	Moment = "Tu primer piso",
	Memory = "PrimerPiso",
	Rewards = { Items = { LlavesPiso = 1 }, Flags = { "TieneHogar" } },

	Props = {
		MesaSola = { Kind = "Asiento", Name = "Un banco del campus", Prompt = "Vivir a tu aire", Place = "Universidad", Offset = V(-8, 0, -2) },
		Caja1 = { Kind = "Caja", Name = "Caja: «COCINA»", Prompt = "Deshacer", Place = "CercaDeTi", Offset = V(3, 0, -3), Dialogue = "Caja_Cocina", Once = true },
		Caja2 = { Kind = "Caja", Name = "Caja: «ROPA (y más ropa)»", Prompt = "Deshacer", Place = "CercaDeTi", Offset = V(-3, 0, -3), Dialogue = "Caja_Ropa", Once = true },
		Caja3 = { Kind = "Caja", Name = "Caja: «NO ABRIR — de tu familia»", Prompt = "Abrir igualmente", Place = "CercaDeTi", Offset = V(0, 0, -5), Color = Color3.fromRGB(230, 200, 120), Dialogue = "Caja_Recuerdos", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Cuarto curso. Es hora de volar.", Seconds = 3 },
		{ Type = "Scene", Dialogue = "Conversacion", Teleport = "HomeSalon", Actors = CASA_FAMILIA },
		{ Type = "Choice", Key = "CompiPiso", Text = "¿Con quién vas a vivir? (habla con quien elijas en el campus, o siéntate a pensarlo a tu aire)",
			Options = {
				{ Id = "Sara", Npc = "Sara", Text = "Con Sara", Dialogue = "Con_Sara", Effects = { Rel = { Sara = 6 } } },
				{ Id = "Luca", Npc = "Luca", Text = "Con Luca", Dialogue = "Con_Luca", Effects = { Rel = { Luca = 6 } } },
				{ Id = "Solo", Prop = "MesaSola", Text = "A tu aire", Dialogue = "Sin_Compi", Effects = { Traits = { Valentia = 1 } } },
			},
			Actors = {
				{ Npc = "Sara", Place = "Universidad", Offset = V(-6, 0, -6) },
				{ Npc = "Luca", Place = "Universidad", Offset = V(-10, 0, -4) },
			} },
		{ Type = "Event", Event = "HomeClaimed", Text = "Busca una casa libre (cartel «Se vende») y quédatela", Actors = COMPIS },
		{ Type = "Scene", Dialogue = "Llaves", Actors = COMPIS },
		{ Type = "Group", Text = "Deshaz la mudanza",
			Steps = {
				{ Type = "Use", Prop = "Caja1", Text = "La caja de la cocina" },
				{ Type = "Use", Prop = "Caja2", Text = "La caja de la ropa" },
				{ Type = "Use", Prop = "Caja3", Text = "La caja que pone «NO ABRIR»" },
			},
			Actors = COMPIS },
		{ Type = "Event", Event = "Ate", Text = "Primera cena en tu casa: compra algo y cómetelo", Actors = COMPIS,
			Nudge = { After = 120, Every = 120, S = "Narrador", T = "La nevera sigue vacía. Hay sitios de comida por toda la ciudad." } },
		{ Type = "Scene", Dialogue = "PrimeraNoche", Actors = COMPIS },
		{ Type = "Talk", Npc = "Abu", Dialogue = "Visita", Text = "Llaman a la puerta: es {abu}",
			Actors = { { Npc = "Abu", Place = "CercaDeTi", Offset = V(0, 0, -5), Mode = "Wave" } } },
		{ Type = "Event", Event = "Slept", Text = "Duerme por primera vez en tu casa (tu cama)" },
		{ Type = "Scene", Dialogue = "Manana", Actors = COMPIS },
	},

	Dialogues = {
		Conversacion = { Lines = {
			{ S = "Familia", T = "Siéntate. Tenemos que hablar. No, no es nada malo. Es que… estás en cuarto. Y el campus está lejos." },
			{ S = "Familia", T = "Hemos pensado que quizá es hora de que tengas tu propio sitio. Te ayudamos a empezar." },
			{ S = "Familia", T = "Y lo que llevas ahorrando desde aquel verano del instituto por fin va a servir para algo grande.", If = { Choices = { Meta = "Ahorro" } } },
			{ S = "Abu", T = "Yo me fui de casa con una maleta y un bocadillo. El bocadillo me duró dos horas. La maleta, cuarenta años." },
			{ Ask = "¿Qué sientes?", Options = {
				{ T = "«¡Por fin! Tengo muchas ganas.»", Effects = { Traits = { Valentia = 1 } }, Then = {
					{ S = "Familia", T = "Ya lo sé. Se te nota desde los catorce. Pero vendrás a comer los domingos, ¿eh? Eso no es negociable." },
				} },
				{ T = "«Me da un poco de miedo.»", Effects = { Traits = { Empatia = 1 }, Rel = { Familia = 5 } }, Then = {
					{ S = "Familia", T = "A mí también me dio miedo. Y a {abu}. El miedo es la señal de que estás creciendo. Aquí tienes siempre tu cuarto." },
				} },
			} },
		} },
		Con_Sara = { Lines = {
			{ S = "Sara", T = "¡Sí! Llevo dos años diseñando mentalmente la convivencia ideal. Tengo un cuadrante de limpieza. Con colores." },
			{ S = "Sara", T = "Y mis hongos del laboratorio vienen conmigo. Están en un tarro. Son muy tranquilos." },
		} },
		Con_Luca = { Lines = {
			{ S = "Luca", T = "¡Perfetto! Me quedo en Valmar para el máster. Yo cocino, tú friegas. Es el pacto italiano." },
			{ S = "Luca", T = "Y los domingos, pasta fresca. Con la receta de mi nonna. Es un secreto de Estado." },
		} },
		Sin_Compi = { Lines = {
			{ S = "Narrador", T = "Te sientas a pensar. Nunca has vivido a tu aire. Nadie que te diga qué comer ni a qué hora dormir. Da vértigo. Y ganas." },
		} },
		Llaves = { Lines = {
			{ S = "Narrador", T = "La llave gira. La puerta se abre. Huele a pintura y a casa vacía. Es tuya." },
			{ S = "Sara", T = "Técnicamente, las paredes son de un color llamado «hueso». Lo cambiaremos. Por el bien de todos.", If = SARA },
			{ S = "Luca", T = "¡Mamma mia, qué luz! Aquí pongo la mesa grande. Para las cenas. Vendrá gente. Siempre viene gente.", If = LUCA },
			{ S = "Narrador", T = "Dices «hola» en voz alta. El eco te contesta. Te ríes solo o sola. Qué raro. Qué bien.", If = SOLO },
		} },
		Caja_Cocina = { Lines = { { S = "Narrador", T = "Dos platos, dos vasos, una sartén y un tupper de croquetas con una nota: «Por si acaso. Te queremos»." } } },
		Caja_Ropa = { Lines = { { S = "Narrador", T = "Ropa, más ropa… y al fondo, la sudadera de dinosaurios de cuando tenías seis años. ¿Quién ha metido esto aquí?" } } },
		Caja_Recuerdos = { Lines = {
			{ S = "Narrador", T = "Dentro: tu primera mochila del cole, dibujos tuyos de pequeño o pequeña, y una carta de tu familia." },
			{ S = "Narrador", T = "«Para cuando te vayas de casa. Aquí tienes todo lo que fuiste. Llévalo contigo a todo lo que vas a ser.»" },
			{ S = "Narrador", T = "Debajo de la carta, el cromo de la suerte del primer día de colegio.", If = { Flags = { "LlevaCromo" } } },
		}, Effects = { Rel = { Familia = 5 } } },
		PrimeraNoche = { Lines = {
			{ S = "Narrador", T = "Primera noche. Sara ha colgado el cuadrante de limpieza. Tú ya vas tarde con la primera tarea: fregar.", If = SARA },
			{ S = "Narrador", T = "Primera noche. Luca ha cocinado para ocho. Sois dos. La cocina parece un campo de batalla.", If = LUCA },
			{ S = "Narrador", T = "Primera noche. Silencio. Solo el frigorífico hace ruido. Nunca te habías fijado en lo que suena un frigorífico.", If = SOLO },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "Friegas lo tuyo y lo de los demás sin decir nada", Effects = { Traits = { Responsabilidad = 1 }, Choice = { Convivencia = "Hacerlo" } }, Then = {
					{ S = "Narrador", T = "La cocina queda reluciente. Mañana, ya veremos." },
				} },
				{ T = "Habláis y hacéis un reparto justo", Effects = { Traits = { Empatia = 1 }, Choice = { Convivencia = "Hablar" }, Rel = { Sara = 3, Luca = 3 } }, Then = {
					{ S = "Sara", T = "Propuesta aceptada. Añado una columna al cuadrante: «Quien cocina no friega». Es justo.", If = SARA },
					{ S = "Luca", T = "Ok, ok. Yo cocino para dos. No para ocho. Bueno, para cuatro. Por si viene alguien.", If = LUCA },
					{ S = "Narrador", T = "Hablas contigo: «¿Quién friega hoy?» «Yo.» «Vale.» Te ríes. Es un buen reparto.", If = SOLO },
				} },
				{ T = "Llamas a tu familia", Effects = { Rel = { Familia = 4 }, Choice = { Convivencia = "Llamar" } }, Then = {
					{ S = "Familia", T = "(al teléfono) ¿Ya nos echas de menos? ¡Si te has ido esta mañana! …Nosotros también. Mucho." },
				} },
			} },
		} },
		Visita = { Lines = {
			{ S = "Abu", T = "¿Se puede? Traigo una planta. Toda casa necesita algo vivo. Riégala los lunes. Si no, te la regaño yo." },
			{ S = "Abu", T = "¿Llevas el reloj? Muy bien. Ahora tienes tu casa y tu tiempo. Úsalos bien." },
			{ S = "Abu", T = "Y esto… son unas croquetas. No son de Lola, son mías. Mejores. No se lo digas." },
		}, Effects = { Rel = { Abu = 6 } } },
		Manana = { Lines = {
			{ S = "Narrador", T = "Te despiertas con la luz que entra por una ventana que todavía no tiene cortinas. Es tu casa. Es tu vida." },
			{ S = "Sara", T = "Buenos días. He hecho café. Y he etiquetado tu taza. Por si la confundías con la mía.", If = SARA },
			{ S = "Luca", T = "¡Buongiorno! Hay pasta de ayer. En Italia, la pasta de ayer es desayuno. Es la ley.", If = LUCA },
		} },
	},
}
