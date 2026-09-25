-- Consecuencias y secundarias de las misiones 01-03 (docs/historia/11, apartados 11.5 y 11.11).
-- Las lanza el motor cuando llega su momento (Effects.Later) o una decisión del jugador.
--   Eco_MateoDibujo   ~1 h después de ayudar a Mateo: te busca para darte las gracias con un dibujo.
--   Eco_MateoSolo     ~1 h después de ignorarle: le ves comiendo solo. Segunda oportunidad.
--   Eco_Ruben         10 h de juego después de la mochila (ya en el instituto): Rubén vuelve.
--   Side_GatoDelCole  si dices a Omar que buscaréis al gato del colegio.

local V = Vector3.new

return {
	{
		Id = "Eco_MateoDibujo",
		Kind = "Side",
		Title = "Un regalo de Mateo",
		Description = "Mateo te estaba buscando.",
		Type = "Consecuencia",
		Duration = { 2, 3 },
		Npcs = { "Mateo" },
		Requires = { Stage = { Min = "Nino", Max = "Adolescente" } },
		Moment = "Mateo te regaló un dibujo",
		Steps = {
			{ Type = "Talk", Npc = "Mateo", Dialogue = "Regalo", Text = "Mateo te está buscando: habla con él",
				Actors = { { Npc = "Mateo", Place = "CercaDeTi", Offset = V(0, 0, -4), Mode = "Wave" } } },
		},
		Dialogues = {
			Regalo = { Lines = {
				{ S = "Mateo", T = "¡{nombre}! Te estaba buscando. Toma… lo he hecho yo." },
				{ S = "Narrador", T = "Es un dibujo: tú, recogiendo sus libros en el patio. Arriba pone «Para mi primer amigo»." },
				{ S = "Mateo", T = "Dani dice que es el dibujo más bonito que he hecho. Dani dice muchas cosas." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "¡Lo voy a colgar en mi cuarto!", Effects = { Rel = { Mateo = 6 } }, Then = {
						{ S = "Mateo", T = "(Mateo se pone rojo como un tomate) Vale. Bien. Genial." },
					} },
					{ T = "Pues ahora te hago yo uno a ti.", Effects = { Rel = { Mateo = 6 }, Traits = { Creatividad = 1 } }, Then = {
						{ S = "Mateo", T = "¿De verdad? Nadie me ha regalado nunca un dibujo." },
					} },
				} },
			}, Effects = { Items = { DibujoMateo = 1 } } },
		},
	},

	{
		Id = "Eco_MateoSolo",
		Kind = "Side",
		Title = "Mateo come solo",
		Description = "Hay alguien que lleva días comiendo solo.",
		Type = "Consecuencia",
		Duration = { 2, 4 },
		Npcs = { "Mateo" },
		Requires = { Stage = { Min = "Nino", Max = "Nino" } },
		Steps = {
			{ Type = "Scene", Dialogue = "LoVes", Actors = { { Npc = "Mateo", Place = "CercaDeTi", Offset = V(3, 0, -6) } } },
			{ Type = "Talk", Npc = "Mateo", Dialogue = "Sentarte", Text = "¿Te sientas con Mateo?",
				Actors = { { Npc = "Mateo", Place = "CercaDeTi", Offset = V(3, 0, -6) } },
				Timeout = { After = 60, Rel = { Mateo = -3 } } },
		},
		Dialogues = {
			LoVes = { Lines = {
				{ S = "Narrador", T = "Ahí está Mateo, el del primer día. Comiendo su bocadillo solo. Otra vez." },
				{ S = "Narrador", T = "Nadie se ha sentado con él en toda la semana." },
			} },
			Sentarte = { Lines = {
				{ S = "Yo", T = "¿Puedo sentarme?" },
				{ S = "Mateo", T = "…¿Conmigo? Vale. Sí. Claro." },
				{ S = "Mateo", T = "Oye… el primer día se me cayeron los libros. Tú estabas al lado." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "Perdona. Debí ayudarte.", Effects = { Rel = { Mateo = 12 }, Traits = { Empatia = 2 } }, Then = {
						{ S = "Mateo", T = "No pasa nada. Ahora estás aquí. Eso cuenta más." },
					} },
					{ T = "¿Me enseñas tus cromos?", Effects = { Rel = { Mateo = 10 } }, Then = {
						{ S = "Mateo", T = "¡Tengo trescientos cuarenta y dos! Bueno, trescientos cuarenta y uno sin contar el roto." },
					} },
				} },
			}, Effects = { Flags = { "AyudasteAMateo" }, Memory = "SegundaOportunidad" } },
		},
		Moment = "Te sentaste con Mateo",
	},

	{
		Id = "Eco_Ruben",
		Kind = "Side",
		Title = "Rubén",
		Description = "Alguien del pasado quiere hablar contigo.",
		Type = "Consecuencia diferida (10 h)",
		Duration = { 3, 5 },
		Npcs = { "Ruben" },
		Moment = "Rubén volvió a aparecer",
		Memory = "ReencuentroRuben",
		Steps = {
			{ Type = "Talk", Npc = "Ruben", Dialogue = "Vuelve", Text = "Alguien te llama: es Rubén",
				Actors = { { Npc = "Ruben", Place = "CercaDeTi", Offset = V(0, 0, -5), Scale = 0.85, Mode = "Wave" } } },
		},
		Dialogues = {
			Vuelve = { Lines = {
				{ S = "Ruben", T = "¡Eh! ¡{nombre}! ¿Te acuerdas de mí? Rubén. El de la mochila." },
				{ S = "Ruben", T = "Ha pasado un montón. Ya vamos al instituto, qué fuerte.", If = { Stage = { Min = "Adolescente" } } },

				-- Si le perdonaste
				{ S = "Ruben", T = "Nunca te lo dije, pero aquel día me cambió. Fuiste la única persona que me perdonó sin pedir nada.", If = { Choices = { MochilaRuben = "Perdon" } } },
				{ S = "Ruben", T = "Dejé de ir con Bruno poco después. Ahora hago teatro. Hago reír a la gente sin esconderle nada.", If = { Choices = { MochilaRuben = "Perdon" } } },
				-- Si se lo contaste a Lucía
				{ S = "Ruben", T = "Durante un tiempo fui diciendo por ahí que te chivabas. Mucho tiempo, la verdad.", If = { Choices = { MochilaRuben = "Profe" } } },
				{ S = "Ruben", T = "Pero Lucía habló con mis padres, y con Bruno, y… bueno. Me vino bien que alguien parara aquello.", If = { Choices = { MochilaRuben = "Profe" } } },
				-- Si te enfadaste
				{ S = "Ruben", T = "Me acuerdo de cómo me gritaste en el almacén. Me lo merecía. Me asusté, pero me lo merecía.", If = { Choices = { MochilaRuben = "Enfado" } } },
				-- Si le devolviste la broma
				{ S = "Ruben", T = "¡Todavía me acuerdo de la gorra en la caja de balones! Te la tengo guardada, que lo sepas.", If = { Choices = { MochilaRuben = "Broma" } } },
				{ S = "Narrador", T = "Rubén te quita la gorra imaginaria de la cabeza y sale corriendo. Luego vuelve, riéndose.", If = { Choices = { MochilaRuben = "Broma" } } },

				{ S = "Ruben", T = "Solo quería decirte… perdona. Por lo de la mochila. Lo digo en serio esta vez." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "Hace mucho que te perdoné.", If = { Choices = { MochilaRuben = "Perdon" } }, Effects = { Rel = { Ruben = 15 } }, Then = {
						{ S = "Ruben", T = "Lo sé. Por eso quería decírtelo a ti el primero." },
					} },
					{ T = "Gracias por decírmelo. Empezamos de cero.", Effects = { Rel = { Ruben = 12 }, Traits = { Empatia = 1 } }, Then = {
						{ S = "Ruben", T = "¿De cero? Trato hecho. Oye, hay función de teatro el viernes. Guardo sitio." },
					} },
					{ T = "Todavía me acuerdo de lo mal que lo pasé.", Effects = { Rel = { Ruben = 3 } }, Then = {
						{ S = "Ruben", T = "Ya… Lo entiendo. Si algún día quieres, aquí estoy." },
					} },
				} },
			} },
		},
	},

	{
		Id = "Side_GatoDelCole",
		Kind = "Side",
		Title = "El gato del colegio",
		Description = "Omar lleva días sin ver a Bigotes, el gato naranja que duerme detrás del gimnasio.",
		Type = "Secundaria",
		Duration = { 6, 10 },
		Npcs = { "Omar", "Ramon" },
		Requires = { Stage = { Min = "Nino", Max = "Nino" } },
		Moment = "Encontrasteis a Bigotes, el gato del colegio",
		Memory = "GatoDelCole",
		Props = {
			Huella1 = { Kind = "Huella", Name = "Huellitas de gato", Prompt = "Seguir", Place = "Patio", Offset = V(-14, 0, 4), Dialogue = "Huella1", Once = true },
			Huella2 = { Kind = "Huella", Name = "Huellitas de gato", Prompt = "Seguir", Place = "CanchaColegio", Offset = V(20, 0, -10), Dialogue = "Huella2", Once = true },
			Huella3 = { Kind = "Huella", Name = "Huellitas de gato", Prompt = "Seguir", Place = "SpotGimnasioPuerta", Offset = V(3, 0, 0), Dialogue = "Huella3", Once = true },
			Bigotes = { Kind = "Gato", Name = "Bigotes", Prompt = "Acercarte", Place = "SpotAlmacenNPC", Offset = V(-3, 0, 0) },
		},
		Steps = {
			{ Type = "Reach", Place = "SpotGimnasioPuerta", Text = "Busca a Bigotes junto al gimnasio (en el cole)",
				Actors = { { Npc = "Omar", Place = "SpotGimnasioPuerta", Offset = V(-3, 0, -2) } } },
			{ Type = "Talk", Npc = "Omar", Dialogue = "Omar_Preocupado", Text = "Habla con Omar",
				Actors = { { Npc = "Omar", Place = "SpotGimnasioPuerta", Offset = V(-3, 0, -2) } } },
			{ Type = "Group", Text = "Sigue las huellitas", Steps = {
				{ Type = "Use", Prop = "Huella1", Text = "En el patio" },
				{ Type = "Use", Prop = "Huella2", Text = "En la cancha" },
				{ Type = "Use", Prop = "Huella3", Text = "Junto al gimnasio" },
			}, Actors = { { Npc = "Omar", Mode = "Follow" } } },
			{ Type = "Use", Prop = "Bigotes", Text = "¡Ahí está! Acércate despacio", Actors = { { Npc = "Omar", Mode = "Follow" } } },
			{ Type = "Scene", Dialogue = "Encontrado", Actors = { { Npc = "Omar", Place = "SpotAlmacenNPC", Offset = V(0, 0, 2) }, { Npc = "Ramon", Place = "SpotAlmacenNPC", Offset = V(3, 0, 2) } }, Props = { "Bigotes" } },
		},
		Dialogues = {
			Omar_Preocupado = { Lines = {
				{ S = "Omar", T = "Aquí es donde duerme siempre. Mira: su cartón. Pero está frío. Hace mucho que no viene." },
				{ S = "Omar", T = "He traído jamón de mi bocadillo. Bueno, la mitad. La otra mitad me la he comido de los nervios." },
			} },
			Huella1 = { Lines = { { S = "Narrador", T = "Huellitas pequeñas en la arena del patio. Van hacia la cancha." } } },
			Huella2 = { Lines = {
				{ S = "Narrador", T = "Más huellas, y un pelito naranja enganchado en la valla." },
				{ S = "Omar", T = "¡Es suyo! ¡Es naranja Bigotes! Es un naranja muy concreto." },
			} },
			Huella3 = { Lines = { { S = "Narrador", T = "Las huellas terminan junto a la puerta del almacén. Se oye un maullido muy flojito." } } },
			Encontrado = { Lines = {
				{ S = "Narrador", T = "Detrás de unas colchonetas, un gato naranja os mira. Y a su lado… ¡tres gatitos diminutos!" },
				{ S = "Omar", T = "¡Bigotes es mamá! ¡Por eso no salía!" },
				{ S = "Ramon", T = "¡Así que era aquí donde te escondías, pillina! Tranquilos, yo me encargo: agua, una manta y a buscarles casa." },
				{ Ask = "¿Qué haces?", Options = {
					{ T = "Acariciar a Bigotes muy despacio", Effects = { Traits = { Empatia = 1 }, Rel = { Omar = 4 } }, Then = {
						{ S = "Narrador", T = "Bigotes cierra los ojos y ronronea. Omar lo dibuja en ese instante. Dice que es su mejor dibujo." },
					} },
					{ T = "Ponerle nombre a los gatitos", Effects = { Traits = { Creatividad = 1 }, Rel = { Omar = 4 } }, Then = {
						{ S = "Omar", T = "Lápiz, Goma y… Sacapuntas. ¡Son perfectos!" },
					} },
				} },
				{ S = "Ramon", T = "Buen trabajo, detectives. Esto queda entre nosotros y el colegio entero, que lo va a saber mañana." },
			}, Effects = { Rel = { Ramon = 5 } } },
		},
	},
}
