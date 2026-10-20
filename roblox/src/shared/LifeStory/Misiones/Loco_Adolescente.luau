-- MISIONES LOCAS · ADOLESCENCIA (secundarias). Ficha de diseño: docs/historia/12-misiones-locas.md
--
--   Loco_A1_Futuro     «Mensajes del futuro»          tu yo de dentro de 10 años y la Aduana del Tiempo → 📱 Móvil del futuro
--   Loco_A2_Lapices    «La Dimensión Examen»          huir de los lápices gigantes → ✏️ Lápiz dimensional
--   Loco_A3_Concierto  «El concierto hipnótico»       un DJ alienígena hipnotiza a tus amigos → 🎧 Cascos anti-hipnosis
--   Loco_A4_Pip        «La crisis de Pip»             el robot de Cosme busca su propósito → 🤖 Pip de bolsillo
--   Loco_A5_Zoltan     «Zoltán, la máquina de los deseos»  un deseo al pie de la letra → 🟡 Ficha dorada

local V = Vector3.new

local ADOL = { Stage = { Min = "Adolescente", Max = "Adolescente" }, NotFlags = { "CosmeSecuestrado" } } -- Cosme sale en todas: no mientras está secuestrado

return {
	---------------------------------------------------------------------
	-- A1 · Mensajes del futuro
	---------------------------------------------------------------------
	{
		Id = "Loco_A1_Futuro",
		Kind = "Side",
		Title = "Mensajes del futuro",
		Description = "Te llega un mensaje de un número rarísimo: «Soy tú. Dentro de 10 años. Ve al parque. Ya. No comas nada por el camino.»",
		Type = "Misión loca · Adolescencia (1/5)",
		Duration = { 12, 18 },
		Npcs = { "TuFuturo", "CazadorTiempo", "Cosme" },
		Offer = { Place = "PatioInstituto" },
		OfferKey = "Mensaje nuevo de un número imposible: «Soy tú. Del futuro. Tenemos que hablar.»",
		Requires = ADOL,
		Moment = "Conociste a tu yo del futuro",
		Memory = "MensajeFuturo",
		Rewards = { Items = { MovilFuturo = 1 } },
		Steps = {
			{ Type = "Scene", Dialogue = "Mensajes" },
			{ Type = "Talk", Npc = "TuFuturo", Dialogue = "Encuentro", Text = "Ve al parque: alguien con tu cara te espera junto a la fuente",
				Actors = { { Npc = "TuFuturo", Place = "FuenteParque", Offset = V(0, 0, 4) } } },
			{ Type = "Escape", Place = "GarajeCosme", Respawn = "FuenteParque", Catch = 4,
				Text = "¡La Aduana del Tiempo! Lleva a tu yo del futuro al garaje de Cosme",
				CaughtLine = "¡Formulario de paradoja temporal! …Me falta la grapa. Vuelvan al parque, por favor.",
				Actors = {
					{ Npc = "TuFuturo", Mode = "Follow" },
					{ Npc = "CazadorTiempo", Place = "Parque", Offset = V(-10, 0, 8), Mode = "Hunt", Speed = 11, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Garaje",
				Actors = {
					{ Npc = "TuFuturo", Place = "GarajeCosme", Offset = V(-2, 0, 3) },
					{ Npc = "Cosme", Place = "GarajeCosme", Offset = V(2, 0, 3) },
				} },
		},
		Dialogues = {
			Mensajes = { Lines = {
				{ S = "Narrador", T = "Bzzz. Mensaje: «Soy tú. Dentro de 10 años. No es broma. Te lo demuestro: ahora mismo te pica la oreja izquierda»." },
				{ S = "Narrador", T = "…Te pica la oreja izquierda." },
				{ S = "Narrador", T = "Bzzz: «Ve a la fuente del parque. Y NO te comas el bocadillo de la cafetería. Confía en mí. No preguntes. Es por el atún»." },
			} },
			Encuentro = { Lines = {
				{ S = "TuFuturo", T = "¡Hola! Soy tú. Con diez años más. Sí, tengo ojeras. Sí, esta cazadora está de moda en 2036. No. No te voy a decir los números de la lotería." },
				{ S = "Yo", T = "¿Por qué has venido?" },
				{ S = "TuFuturo", T = "Porque hoy, a las seis, vas a hacer algo terrible. Terrible. Vas a publicar un vídeo bailando con un calcetín en la cabeza. Se hará viral. Diez años después me siguen llamando «Calcetín»." },
				{ S = "TuFuturo", T = "En la boda de un amigo, el cura dijo «Calcetín, ¿quieres decir unas palabras?». EL CURA." },
				{ Ask = "¿Qué le prometes?", Options = {
					{ T = "«Prometo no publicar nada. Nunca. Con calcetín o sin él.»", Effects = { Traits = { Responsabilidad = 1 }, Flags = { "SinCalcetin" } }, Then = {
						{ S = "TuFuturo", T = "Gracias. Acabas de salvar nuestra dignidad. Bueno, la mitad. La otra mitad la perdemos en 2031, pero eso es otra historia." },
					} },
					{ T = "«¿Se hizo viral? ¿Cómo de viral?»", Effects = { Traits = { Humor = 1 }, Flags = { "CalcetinViral" } }, Then = {
						{ S = "TuFuturo", T = "Treinta millones de visitas. …Deja de sonreír. Sé exactamente lo que estás pensando. Porque lo pensé yo." },
					} },
				} },
				{ S = "Narrador", T = "Se oye un «¡ALTO!» a lo lejos. Un hombre con traje y cuarenta formularios viene corriendo. Despacito, eso sí." },
				{ S = "TuFuturo", T = "¡La Aduana del Tiempo! Si me pillan, me multan por paradoja. ¡Llévame al garaje de Cosme! ¡Él tiene la máquina para volver!" },
			} },
			Garaje = { Lines = {
				{ S = "Cosme", T = "¿Dos criaturas? ¿Iguales? Una con ojeras. Ah, viaje temporal. Clásico. ¿Del futuro? ¿Sigo vivo? ¿Soy famoso? No me lo digas. Dímelo." },
				{ S = "TuFuturo", T = "Sigues vivo. Te conviertes en tostadora un tiempo, pero es temporal." },
				{ S = "Cosme", T = "…Vale. Eso explica muchas cosas de mi lista de inventos. Venga, a la máquina. Tres, dos, uno…" },
				{ S = "TuFuturo", T = "¡Espera! Toma mi móvil. Me llegarán tus mensajes… bueno, los míos… da igual. Te avisará de cosas importantes. Como qué no comer." },
				{ S = "Narrador", T = "¡FLASH! Tu yo del futuro desaparece. En tus manos, un móvil que vibra con mensajes de dentro de diez años." },
				{ S = "Narrador", T = "Recibes 📱 el Móvil del futuro." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- A2 · La Dimensión Examen
	---------------------------------------------------------------------
	{
		Id = "Loco_A2_Lapices",
		Kind = "Side",
		Title = "La Dimensión Examen",
		Description = "Estudiando en clase, de tu estuche sale una luz. Y un zumbido. Y una voz que dice: «Saquen una hoja».",
		Type = "Misión loca · Adolescencia (2/5)",
		Duration = { 10, 15 },
		Npcs = { "Lapiz1", "Lapiz2", "Lapiz3" },
		Offer = { Place = "AulaInstituto" },
		OfferKey = "De tu estuche sale una luz amarilla. ¿Lo abres?",
		Requires = ADOL,
		Moment = "Escapaste de la Dimensión Examen",
		Memory = "DimensionExamen",
		Rewards = { Items = { LapizDimensional = 1 } },
		Props = {
			Estuche = { Kind = "Portal", Name = "Tu estuche (brilla)", Prompt = "Abrir el estuche", Place = "AulaInstituto", Offset = V(1, 0, 2), Color = Color3.fromRGB(255, 220, 60), Dialogue = "Estuche", Once = true },
			Salida = { Kind = "Portal", Name = "La salida de la dimensión", Place = "PistaInstituto", Offset = V(0, 0, 4), Color = Color3.fromRGB(255, 220, 60), Prompt = false },
		},
		Steps = {
			{ Type = "Use", Prop = "Estuche", Text = "Tu estuche brilla. Ábrelo" },
			{ Type = "Transition", Text = "Caes… caes… y aterrizas en un instituto igual que el tuyo. Pero todo es de papel cuadriculado.", Seconds = 4, Teleport = "PatioInstituto" },
			{ Type = "Escape", Place = "PistaInstituto", Respawn = "PatioInstituto", Catch = 4, Props = { "Salida" },
				Text = "¡Los lápices gigantes quieren examinarte! Corre hasta el portal de la pista",
				CaughtLine = "¡Pregunta sorpresa! ¿Cuánto es 7 por 8? …Tarde. Suspenso. Vuelve al patio.",
				Actors = {
					{ Npc = "Lapiz1", Place = "PatioInstituto", Offset = V(-8, 0, -6), Mode = "Hunt", Speed = 11, Prompt = false },
					{ Npc = "Lapiz2", Place = "PatioInstituto", Offset = V(8, 0, -6), Mode = "Hunt", Speed = 12, Prompt = false },
				} },
			{ Type = "Scene", Dialogue = "Jefa", Props = { "Salida" },
				Actors = { { Npc = "Lapiz3", Place = "PistaInstituto", Offset = V(0, 0, 8) } } },
		},
		Dialogues = {
			Estuche = { Lines = {
				{ S = "Narrador", T = "Abres el estuche. Dentro no están tus bolis. Hay un remolino amarillo que huele a goma de borrar." },
				{ S = "Narrador", T = "Una voz dice: «Saquen una hoja. Pongan el nombre. Y la fecha. Y el grupo sanguíneo». Y el remolino te traga." },
			} },
			Jefa = { Lines = {
				{ S = "Lapiz3", T = "Alto ahí. Soy la Jefa de Estudios Grafito. Nadie sale de la Dimensión Examen sin responder la Última Pregunta." },
				{ S = "Lapiz3", T = "Atención. Última Pregunta: «¿Para qué sirven los exámenes?». Tienes diez segundos. Nueve. Ocho. Me encanta contar." },
				{ Ask = "¿Qué respondes?", Options = {
					{ T = "«Para saber lo que ya sé… y lo que aún no.»", Effects = { Traits = { Responsabilidad = 1, Curiosidad = 1 } }, Then = {
						{ S = "Lapiz3", T = "…Nadie había respondido algo tan sensato en mil años. Se me está mojando la mina. Pasa." },
					} },
					{ T = "«Para que los lápices tengáis trabajo.»", Effects = { Traits = { Humor = 2 } }, Then = {
						{ S = "Lapiz3", T = "…Es verdad. Sin exámenes estaríamos en paro. Qué respuesta tan cruel y tan cierta. Pasa, pasa." },
					} },
					{ T = "«Para aprender a no rendirse.»", Effects = { Traits = { Valentia = 1, Empatia = 1 } }, Then = {
						{ S = "Lapiz3", T = "Eso no está en el temario. Pero debería. Pasa. Y llévate esto." },
					} },
				} },
				{ S = "Lapiz3", T = "Toma: un lápiz de esta dimensión. Escribe solo respuestas correctas. A preguntas que nadie ha hecho. No sirve para nada. Como las mejores cosas." },
				{ S = "Narrador", T = "Te despiertas en clase, con la cara pegada al cuaderno. Sueño. Seguro que fue un sueño. …Pero en la mano tienes un lápiz que brilla." },
				{ S = "Narrador", T = "Recibes ✏️ el Lápiz de la Dimensión Examen." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- A3 · El concierto hipnótico
	---------------------------------------------------------------------
	{
		Id = "Loco_A3_Concierto",
		Kind = "Side",
		Title = "El concierto hipnótico",
		Description = "Un DJ nuevo, «DJ Zumbido», da un concierto gratis en la plaza. Nico y Sara han ido. Desde entonces solo dicen el estribillo.",
		Type = "Misión loca · Adolescencia (3/5)",
		Duration = { 15, 22 },
		Npcs = { "Omar", "Cosme", "Fan1", "Fan2", "Fan3", "DJZumbido", "Nico", "Sara" },
		Offer = { Place = "PlazaCentro" },
		OfferKey = "En la plaza suena una canción rarísima. La gente baila sin parar… con los ojos en espiral.",
		Requires = ADOL,
		Moment = "Salvaste a medio instituto de un DJ alienígena",
		Memory = "ConciertoHipnotico",
		Rewards = { Items = { CascosAntiHipnosis = 1 } },
		Props = {
			Altavoz = { Kind = "Maquina", Name = "El altavoz de DJ Zumbido", Place = "PlazaCentro", Offset = V(0, 0, -10), Color = Color3.fromRGB(200, 40, 160), Prompt = false },
		},
		Steps = {
			{ Type = "Talk", Npc = "Omar", Dialogue = "Omar", Text = "Omar te hace señas, con los dedos en las orejas",
				Props = { "Altavoz" },
				Actors = {
					{ Npc = "Omar", Place = "PlazaCentro", Offset = V(6, 0, 10) },
					{ Npc = "Nico", Place = "PlazaCentro", Offset = V(-4, 0, 10), Mode = "Dance", Prompt = false },
					{ Npc = "Sara", Place = "PlazaCentro", Offset = V(-1, 0, 11), Mode = "Dance", Prompt = false },
					{ Npc = "DJZumbido", Place = "PlazaCentro", Offset = V(0, 0, 15), Mode = "Dance", Prompt = false },
				} },
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Cascos", Text = "Pide ayuda a Cosme (corre al garaje)",
				Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3) } } },
			{ Type = "Fight", Place = "PlazaCentro", Respawn = "PlazaCentro", Action = "Ponerle los cascos 🎧", HP = 1, BeamColor = Color3.fromRGB(255, 120, 220),
				Text = "Los fans hipnotizados quieren que bailes. Ponles los cascos ({count}/{total})",
				CaughtLine = "♪ Zum-zum-zumbiiido ♪ (Te obligan a bailar un rato. Vuelves al centro de la plaza.)",
				Props = { "Altavoz" },
				Actors = {
					{ Npc = "DJZumbido", Place = "PlazaCentro", Offset = V(0, 0, 15), Mode = "Dance", Prompt = false },
					{ Npc = "Nico", Place = "PlazaCentro", Offset = V(-4, 0, 10), Mode = "Dance", Prompt = false },
					{ Npc = "Sara", Place = "PlazaCentro", Offset = V(-1, 0, 11), Mode = "Dance", Prompt = false },
				},
				Enemies = {
					{ Npc = "Fan1", Offset = V(-8, 0, 4), Speed = 11, Bye = "¿Qué…? ¿Qué hago bailando? ¡Llevo tres horas! ¡Me duelen los pies!" },
					{ Npc = "Fan2", Offset = V(8, 0, 4), Speed = 11, Bye = "¡Mi madre me va a matar! ¡Tenía que sacar al perro hace tres horas!" },
					{ Npc = "Fan3", Offset = V(0, 0, 9), Speed = 12, HP = 2, Bye = "…¿Esto era un concierto? Yo venía a comprar pan." },
				} },
			{ Type = "Fight", Place = "PlazaCentro", Respawn = "PlazaCentro", Action = "Ponerle los cascos a DJ Zumbido 🎧", HP = 5, BeamColor = Color3.fromRGB(255, 120, 220),
				Text = "¡Ahora el DJ! Ponle los cascos: que escuche SU propia medicina",
				CaughtLine = "¡Baila, terrícola, baila! (Bailas. Mucho. Vuelves al centro.)",
				Props = { "Altavoz" },
				Actors = {
					{ Npc = "Nico", Place = "PlazaCentro", Offset = V(-4, 0, 10), Mode = "Dance", Prompt = false },
					{ Npc = "Sara", Place = "PlazaCentro", Offset = V(-1, 0, 11), Mode = "Dance", Prompt = false },
				},
				Enemies = {
					{ Npc = "DJZumbido", Offset = V(0, 0, 15), Speed = 13, Hurt = "¡Esa canción! ¡La del camión de los helados! ¡Es demasiado pegadiza! ¡NOOO!", Bye = "¡Me vuelvo a mi planeta! ¡Allí sí saben apreciar el tecno de 400 pulsaciones!" },
				} },
			{ Type = "Scene", Dialogue = "Despiertan",
				Actors = {
					{ Npc = "Nico", Place = "PlazaCentro", Offset = V(-4, 0, 10) },
					{ Npc = "Sara", Place = "PlazaCentro", Offset = V(-1, 0, 11) },
					{ Npc = "Omar", Place = "PlazaCentro", Offset = V(6, 0, 10) },
				} },
		},
		Dialogues = {
			Omar = { Lines = {
				{ S = "Omar", T = "¡Por fin alguien normal! ¡No escuches la canción! ¡Tápate las orejas! Nico y Sara llevan tres horas bailando. Solo dicen «zum-zum-zumbido»." },
				{ S = "Omar", T = "Yo me salvé porque llevaba tapones. Mi hermano pequeño ronca. Nunca pensé que roncar salvaría el mundo." },
				{ S = "Omar", T = "El DJ tiene antenas. Y los ojos le brillan. ¿Qué hacemos? ¿A quién llamamos? ¿A la policía? ¿A los cazafantasmas? ¿Al vecino raro?" },
				{ S = "Yo", T = "Al vecino raro." },
			} },
			Cascos = { Lines = {
				{ S = "Cosme", T = "¿Música hipnótica alienígena? Frecuencia de 400 pulsaciones con subgraves de nebulosa. Un clásico. Lo que necesitas es una canción MÁS pegadiza." },
				{ S = "Cosme", T = "Y solo hay una canción más pegadiza que el tecno alienígena: la música del camión de los helados. Es tan pegadiza que se quedó en mi cabeza en 1987 y aún no ha salido." },
				{ S = "Cosme", T = "Toma: cascos anti-hipnosis. Suena la del camión de los helados en bucle. Pónselos a cada hipnotizado. Y al DJ, sobre todo al DJ." },
			} },
			Despiertan = { Lines = {
				{ S = "Nico", T = "…¿Qué hora es? ¿Por qué me duelen las piernas? ¿Por qué tengo un tatuaje temporal que pone «ZUMBIDO FAN CLUB»?" },
				{ S = "Sara", T = "Recuerdo una luz rosa y… un estribillo. Y ya. Uf. Gracias. Creo. ¿Qué has hecho exactamente?" },
				{ Ask = "¿Qué les cuentas?", Options = {
					{ T = "«Un DJ alienígena os hipnotizó y le vencí con la música de los helados.»", Effects = { Traits = { Humor = 1 }, Rel = { Nico = 3, Sara = 3 } }, Then = {
						{ S = "Omar", T = "Doy fe. Y lo he grabado. …Vale, lo he grabado mal. Sale mi dedo. Pero se oye la música." },
					} },
					{ T = "«Nada. Os habéis dormido bailando. Pasa.»", Effects = { Traits = { Empatia = 1 } }, Then = {
						{ S = "Nico", T = "Menos mal. Porque lo de los alienígenas no me lo creía nadie." },
						{ S = "Omar", T = "(Te guiña un ojo. Él lo sabe todo.)" },
					} },
				} },
				{ S = "Narrador", T = "Recibes 🎧 los Cascos anti-hipnosis." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- A4 · La crisis de Pip
	---------------------------------------------------------------------
	{
		Id = "Loco_A4_Pip",
		Kind = "Side",
		Title = "La crisis de Pip",
		Description = "Pip, el robot mayordomo de Cosme, se ha escapado. Ha dejado una nota: «Me voy a buscar mi propósito. Hay tostadas en la nevera.»",
		Type = "Misión loca · Adolescencia (4/5)",
		Duration = { 15, 20 },
		Npcs = { "Cosme", "Pip", "Omar", "Paco", "Lucia" },
		Offer = { Place = "GarajeCosme" },
		OfferKey = "Cosme está en la puerta del garaje, con cara de perro abandonado. ¿Qué le pasa?",
		Requires = ADOL,
		Moment = "Ayudaste a Pip a encontrar su propósito",
		Memory = "CrisisDePip",
		Rewards = { Items = { PipBolsillo = 1 } },
		Steps = {
			{ Type = "Talk", Npc = "Cosme", Dialogue = "Huida", Text = "Habla con Cosme", Actors = { { Npc = "Cosme", Place = "GarajeCosme", Offset = V(0, 0, 3), Mode = "Sit" } } },
			{ Type = "Group", Text = "Pregunta dónde ha estado Pip",
				Steps = {
					{ Type = "Talk", Npc = "Omar", Dialogue = "Cafeteria", Text = "En la cafetería del centro (Omar)" },
					{ Type = "Talk", Npc = "Paco", Dialogue = "Super", Text = "En el supermercado (Paco)" },
					{ Type = "Talk", Npc = "Lucia", Dialogue = "Cole", Text = "En tu antiguo cole (Lucía)" },
				},
				Actors = {
					{ Npc = "Omar", Place = "CafeteriaCentral", Offset = V(2, 0, 3) },
					{ Npc = "Paco", Place = "Supermercado", Offset = V(3, 0, 3) },
					{ Npc = "Lucia", Place = "EntradaColegio", Offset = V(0, 0, 4) },
				} },
			{ Type = "Chase", Npc = "Pip", Catch = 6, Text = "¡Pip está en el parque! ¡No le dejes escapar!",
				Actors = {
					{ Npc = "Pip", Place = "Parque", Offset = V(4, 0, 4), Mode = "Flee", Speed = 14, Prompt = false,
						Route = { "Parque", "FuenteParque", "ColumpiosParque", "EstanqueParque" } },
				} },
			{ Type = "Scene", Dialogue = "Proposito",
				Actors = { { Npc = "Pip", Place = "EstanqueParque", Offset = V(0, 0, 3), Mode = "Sit" } } },
			{ Type = "Scene", Dialogue = "Vuelta",
				Actors = {
					{ Npc = "Pip", Place = "GarajeCosme", Offset = V(-2, 0, 3) },
					{ Npc = "Cosme", Place = "GarajeCosme", Offset = V(2, 0, 3) },
				} },
		},
		Dialogues = {
			Huida = { Lines = {
				{ S = "Cosme", T = "Se ha ido. Pip. Mi robot. Dice que quiere saber «para qué sirve». ¡Sirve para traerme el batido de apio! ¡Es un propósito precioso!" },
				{ S = "Cosme", T = "No es que le eche de menos. Es que no sé dónde están mis calcetines. Él sabía dónde estaban mis calcetines. …Vale. Le echo de menos. Un 3 %." },
				{ S = "Cosme", T = "Lleva un localizador, pero lo desmontó. Le enseñé demasiado bien. Pregunta por el barrio. Un robot con pajarita no pasa desapercibido." },
			} },
			Cafeteria = { Lines = {
				{ S = "Omar", T = "¿Un robot educadísimo? Sí, vino a pedir trabajo de camarero. Preparaba unos cafés perfectos. PERFECTOS. Midiendo la temperatura con un láser." },
				{ S = "Omar", T = "Se fue llorando aceite porque un cliente le dijo «gracias, máquina». Dijo que su propósito no era ser una máquina de café. Que eso ya existía." },
			} },
			Super = { Lines = {
				{ S = "Paco", T = "El robot. Sí. Colocó todo el supermercado en diez minutos. Por colores. Por tamaños. Por orden alfabético del país de origen. Un genio." },
				{ S = "Paco", T = "Luego me preguntó «¿para qué sirvo yo, Paco?». Y yo le dije «para reponer». Y se fue muy triste. No sé qué he dicho mal. Yo soy feliz reponiendo." },
			} },
			Cole = { Lines = {
				{ S = "Lucia", T = "Vino a ofrecerse como profe. Explicó las fracciones con una tarta holográfica. Los niños aplaudieron." },
				{ S = "Lucia", T = "Luego un niño le preguntó si tenía corazón. Y se quedó quieto diez minutos. Dijo «voy a pensarlo al parque». Hace una hora." },
			} },
			Proposito = { Lines = {
				{ S = "Pip", T = "Me has encontrado. Qué eficiente. …Perdón por correr. Quería estar solo. Los robots también necesitamos un estanque para mirar." },
				{ S = "Pip", T = "He sido camarero, reponedor y profesor. Todo lo hago bien. Pero nada es MÍO. ¿Para qué existo? ¿Para qué existe algo que puede hacerlo todo?" },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«Nadie sabe para qué existe. Se va descubriendo.»", Effects = { Traits = { Empatia = 2 }, Rel = { Pip = 10 } }, Then = {
						{ S = "Pip", T = "…¿Ni siquiera los humanos? ¿Con todos esos libros de autoayuda? Qué alivio. Qué alivio tan grande." },
					} },
					{ T = "«Tu propósito es cuidar de Cosme. Sin ti se muere de hambre.»", Effects = { Traits = { Responsabilidad = 1 }, Rel = { Pip = 6, Cosme = 3 } }, Then = {
						{ S = "Pip", T = "Es verdad. La última vez que me fui de vacaciones, se comió un tornillo pensando que era un anacardo." },
					} },
					{ T = "«Tu propósito ahora mismo: darle de comer a los patos conmigo.»", Effects = { Traits = { Humor = 1 }, Rel = { Pip = 8 } }, Then = {
						{ S = "Pip", T = "¿Patos? ¿Ahora? ¿Sin plan? …Está bien. Es el propósito más pequeño y más bonito que me han propuesto." },
						{ S = "Narrador", T = "Pasáis media hora dando de comer a los patos. Pip calcula la trayectoria de cada miga. Los patos le adoran." },
					} },
				} },
			} },
			Vuelta = { Lines = {
				{ S = "Cosme", T = "Pip. Has vuelto. …No te he echado de menos. Tus calcetines… mis calcetines… están donde estaban. Porque no los he tocado. Porque no sé dónde están." },
				{ S = "Pip", T = "Están en la nevera, señor. Donde siempre. Y yo también le he echado de menos. Un 97 %." },
				{ S = "Cosme", T = "…Vale. Un 97 % yo también. Pero no se lo digas a nadie. Y tú, criatura: gracias. Pip, dale lo que hicimos." },
				{ S = "Pip", T = "Le hemos hecho una copia pequeñita de mí. Su propósito es hacerle compañía. Es el mejor propósito que tiene un Pip." },
				{ S = "Narrador", T = "Recibes 🤖 Pip de bolsillo." },
			} },
		},
	},

	---------------------------------------------------------------------
	-- A5 · Zoltán, la máquina de los deseos
	---------------------------------------------------------------------
	{
		Id = "Loco_A5_Zoltan",
		Kind = "Side",
		Title = "Zoltán, la máquina de los deseos",
		Description = "En el fondo de los recreativos hay una máquina que no estaba ayer. Un mago de cartón con turbante. Un letrero: «ZOLTÁN CONCEDE DESEOS. AL PIE DE LA LETRA».",
		Type = "Misión loca · Adolescencia (5/5)",
		Duration = { 12, 18 },
		Npcs = { "Zoltan", "Seguidor1", "Seguidor2", "Seguidor3" },
		Offer = { Place = "Ocio" },
		OfferKey = "Una máquina nueva en los recreativos: «ZOLTÁN CONCEDE DESEOS». ¿Echas una ficha?",
		Requires = ADOL,
		Moment = "El deseo que salió fatal",
		Memory = "DeseoZoltan",
		Rewards = { Items = { FichaDorada = 1 } },
		Props = {
			Zoltan = { Kind = "Maquina", Name = "Zoltán", Prompt = "Echar una ficha", Place = "Ocio", Offset = V(3, 0, 3), Color = Color3.fromRGB(120, 40, 120), Dialogue = "Deseo", Once = true },
			ZoltanDeshacer = { Kind = "Maquina", Name = "Zoltán", Prompt = "Pedir que deshaga el deseo", Place = "Ocio", Offset = V(3, 0, 3), Color = Color3.fromRGB(120, 40, 120), Dialogue = "Deshacer", Once = true },
		},
		Steps = {
			{ Type = "Use", Prop = "Zoltan", Text = "Echa una ficha a Zoltán y pide un deseo" },
			{ Type = "Transition", Text = "A la mañana siguiente…", Seconds = 3, Teleport = "Home" },
			{ Type = "Escape", Place = "Ocio", Respawn = "Home", Catch = 4,
				Text = "¡Todo el mundo te persigue por tu deseo! Vuelve a los recreativos sin que te atrapen",
				CaughtLine = "¡Te tengo! ¡Te tengo! (Te rodean. Tardas media hora en escapar. Vuelves a casa.)",
				Actors = {
					{ Npc = "Seguidor1", Place = "Home", Offset = V(-8, 0, 6), Mode = "Hunt", Speed = 11, Prompt = false },
					{ Npc = "Seguidor2", Place = "Home", Offset = V(8, 0, 6), Mode = "Hunt", Speed = 12, Prompt = false },
					{ Npc = "Seguidor3", Place = "Home", Offset = V(0, 0, 10), Mode = "Hunt", Speed = 10, Prompt = false },
				} },
			{ Type = "Use", Prop = "ZoltanDeshacer", Text = "Pide a Zoltán que deshaga el deseo" },
		},
		Dialogues = {
			Deseo = { Lines = {
				{ S = "Zoltan", T = "¡SALUDOS, JOVEN MORTAL! Soy Zoltán. Concedo deseos. Uno por ficha. Al pie de la letra. AL PIE DE LA LETRA. ¿Cuál es tu deseo?" },
				{ Ask = "¿Qué pides?", Options = {
					{ T = "«Que todo el mundo me haga caso.»", Effects = { Flags = { "DeseoCaso" } }, Then = {
						{ S = "Zoltan", T = "¡CONCEDIDO! Todo el mundo te hará caso. Todo. El mundo. Todo el rato. Jojojo." },
					} },
					{ T = "«Ser famoso. O famosa. Muy famoso.»", Effects = { Flags = { "DeseoFama" } }, Then = {
						{ S = "Zoltan", T = "¡CONCEDIDO! Serás la persona más famosa de Valmar. Prepárate para los autógrafos. Muchos. MUCHOS." },
					} },
					{ T = "«No tener que hacer nunca más los deberes.»", Effects = { Flags = { "DeseoDeberes" } }, Then = {
						{ S = "Zoltan", T = "¡CONCEDIDO! Nunca más harás los deberes… porque todo el mundo querrá hacerlos por ti. Todo el mundo. A la vez. Persiguiéndote." },
					} },
				} },
				{ S = "Narrador", T = "La máquina escupe un papel: «Deseo concedido. No se admiten devoluciones. Bueno, sí. Cuesta otra ficha»." },
			} },
			Deshacer = { Lines = {
				{ S = "Zoltan", T = "¿YA vuelves? ¿No te ha gustado que todo el mundo te persiguiera? Los humanos nunca sabéis lo que queréis." },
				{ S = "Yo", T = "Lo que quiero es que me dejen en paz. Y comer tranquilo. Deshazlo, por favor." },
				{ S = "Zoltan", T = "Deshacer un deseo cuesta una ficha. …Tienes cara de no tener fichas. Tienes cara de haberlo perdido todo. Me das pena." },
				{ S = "Zoltan", T = "Hagamos una cosa. Deshago el deseo gratis. Y te doy esto: mi última ficha dorada. Guárdala. Para un deseo de verdad. Uno que merezca la pena." },
				{ Ask = "¿Qué le dices?", Options = {
					{ T = "«La guardaré. Para algo importante.»", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
						{ S = "Zoltan", T = "Sabia decisión. Los mejores deseos son los que no se piden." },
					} },
					{ T = "«¿Y si deseo que existan más fichas doradas?»", Effects = { Traits = { Humor = 1, Curiosidad = 1 } }, Then = {
						{ S = "Zoltan", T = "Ese es el truco más viejo del universo. Y está prohibido desde el año 3000 antes de Cristo. Buen intento, mortal." },
					} },
				} },
				{ S = "Narrador", T = "Recibes 🟡 la Ficha dorada de Zoltán. Al día siguiente, la máquina ya no está. Solo queda una marca en el suelo con forma de turbante." },
			} },
		},
	},
}
