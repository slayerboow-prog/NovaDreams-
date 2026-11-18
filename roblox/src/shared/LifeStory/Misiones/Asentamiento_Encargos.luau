-- ENCARGOS DEL ASENTAMIENTO (18-11-2026, el dueño: «juego súper adictivo, historia única, 0 infantil; todo muy
-- interactivo»). Secundarias de la vida en Valmar después de la Caída: gente del asentamiento con algo que perder.
-- Sustituyen a las secundarias de la vida de antes (retiradas). Todas se juegan en terreno hostil (lugares Guarida…)
-- y tienen decisiones que cambian cómo acaban. Salen cuando ya eres guerrero de primera.
--   Enc01_Radio       «La radio de la señora Ortal»   el hijo radioaficionado y su última emisión; ¿la verdad o una mentira piadosa?
--   Enc02_Medicinas   «Carga sin etiqueta»            Kerr el contrabandista, una caja de medicinas y saqueadores; ¿hospital o dinero?
--   Enc03_Tunel       «Los del túnel»                 supervivientes del campus que llevan dos años fuera; ¿los traes o los ayudas allí?
--   Enc04_Desertor    «El chaleco»                    un guardia del Consejo quiere desertar; ayudarle a cruzar la empalizada sin que le vean

local V = Vector3.new

local function side(t: { [string]: any }): { [string]: any }
	t.Kind = "Side"
	t.Requires = t.Requires or { Flags = { "GuerreroDePrimera" } }
	return t
end

return {
	---------------------------------------------------------------------
	side({
		Id = "Enc01_Radio",
		Title = "La radio de la señora Ortal",
		Description = "Cada tarde, una mujer mayor se sienta en la plaza con una radio apagada en el regazo. Esperando una voz que no llega.",
		Type = "Encargo del asentamiento",
		Duration = { 10, 14 },
		Npcs = { "Ortal" },
		Offer = { Place = "PlazaCentro" },
		OfferKey = "Una mujer en la plaza te llama: «Usted es de la Academia, ¿verdad? Necesito que alguien vaya al Sur.»",
		Moment = "Le llevaste a la señora Ortal la última voz de su hijo",
		Rewards = { Money = 900 },
		Props = {
			Antena = { Kind = "Maquina", Name = "Una antena casera en un tejado", Prompt = "Revisar la antena", Place = "GuaridaSur", Offset = V(-10, 0, 12), Dialogue = "Antena", Once = true },
			Cinta = { Kind = "Papel", Name = "Una cinta de grabación etiquetada «Para mamá»", Prompt = "Coger la cinta", Place = "GuaridaSur", Offset = V(8, 0, 16), Dialogue = "Cinta", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Ortal", Dialogue = "Pide", Text = "Habla con la señora Ortal en la plaza",
				Actors = { { Npc = "Ortal", Place = "PlazaCentro", Offset = V(4, 0, 6), Mode = "Sit" } } },
			{ Type = "Reach", Place = "GuaridaSur", Text = "Ve a la calle de la antena, junto a la guarida del Sur" },
			{ Type = "Event", Event = "BeastKilled", Count = 6, Match = { Region = "Farm_Sur" }, Text = "La calle está tomada: despéjala ({count}/{total})" },
			{ Type = "Group", Text = "Busca en la casa del hijo de Ortal",
				Steps = {
					{ Type = "Use", Prop = "Antena", Text = "La antena del tejado" },
					{ Type = "Use", Prop = "Cinta", Text = "La cinta «Para mamá»" },
				} },
			{ Type = "MiniGame", Game = "Timing", Title = "Rebobinar la cinta", Icon = "📼", Hint = "La cinta está dañada: pulsa en el verde para no romperla",
				Rounds = 3, Need = 2, Zone = 0.26, Speed = 0.95,
				Win = { Flags = { "CintaOrtalEntera" } }, Lose = { Flags = { "CintaOrtalRota" } } },
			{ Type = "Scene", Dialogue = "Escucha" },
			{ Type = "Choice", Key = "EncOrtal", Text = "La cinta acaba de golpe. Su hijo no salió del Sur. ¿Qué le dices a la señora Ortal?",
				Options = {
					{ Id = "Verdad", Text = "La verdad, y darle la cinta", Effects = { Flags = { "OrtalVerdad" }, Traits = { Responsabilidad = 1 } } },
					{ Id = "Mentira", Text = "Que la casa estaba vacía: que se marchó a otro asentamiento", Effects = { Flags = { "OrtalMentira" }, Traits = { Empatia = 1 } } },
				} },
			{ Type = "Talk", Npc = "Ortal", Dialogue = "Final", Text = "Vuelve con la señora Ortal",
				Actors = { { Npc = "Ortal", Place = "PlazaCentro", Offset = V(4, 0, 6), Mode = "Sit" } } },
		},
		Dialogues = {
			Pide = { Lines = {
				{ S = "Ortal", T = "Mi hijo, Iván. Tenía una antena en el tejado; hablaba con medio mundo. La noche de la Caída estaba en casa, en el Sur. Me dijo por radio que venía." },
				{ S = "Ortal", T = "No vino. Pero esta radio es suya, y a veces, de noche, hace un ruido. Como si alguien intentara hablar." },
				{ S = "Ortal", T = "No le pido que lo traiga. Solo que vaya a mirar. Que alguien mire." },
			} },
			Antena = { Lines = {
				{ S = "Narrador", T = "La antena sigue apuntando al centro de Valmar. Alguien la ha atado con alambre para que el viento no la tumbe. Hace mucho." },
			} },
			Cinta = { Lines = {
				{ S = "Narrador", T = "En la mesa de la radio, una cinta con letra torpe: «Para mamá. Por si no llega la señal»." },
			} },
			Escucha = { Lines = {
				{ S = "Narrador", T = "La voz de un chico joven, tranquila a la fuerza: «Mamá. No puedo salir, hay demasiadas en la calle. La radio no llega al centro. Grabo esto por si alguien la encuentra»." },
				{ S = "Narrador", T = "«No estoy asustado. Bueno, un poco. Riega los geranios. Y no te quedes esperando en la plaza, que te conozco». Un golpe en la puerta. La cinta se acaba." },
			} },
			Final = { Lines = {
				{ S = "Ortal", T = "Lo sabía. Creo que lo sabía desde el primer día. Gracias por mirar." },
				{ S = "Narrador", T = "Al día siguiente, la señora Ortal no está en la plaza. En su ventana hay geranios nuevos." },
			} },
		},
	}),

	---------------------------------------------------------------------
	side({
		Id = "Enc02_Medicinas",
		Title = "Carga sin etiqueta",
		Description = "Kerr, el contrabandista del puerto, paga bien por un trabajo sencillo: recoger una caja fuera de la empalizada y no preguntar qué lleva.",
		Type = "Encargo del asentamiento",
		Duration = { 12, 16 },
		Npcs = { "Kerr", "Saqueador1", "Saqueador2" },
		Offer = { Place = "PuertoEspacial" },
		OfferKey = "Un hombre con abrigo largo te silba desde una esquina del puerto: «Tú. ¿Quieres ganar dinero de verdad?»",
		Moment = "Decidiste qué hacer con la caja de Kerr",
		Rewards = { Money = 1200 },
		Props = {
			Caja = { Kind = "Caja", Name = "Una caja metálica sin etiqueta", Prompt = "Abrir la caja", Place = "GuaridaEste", Offset = V(10, 0, 14), Dialogue = "Caja", Once = true },
		},
		Steps = {
			{ Type = "Talk", Npc = "Kerr", Dialogue = "Trato", Text = "Habla con Kerr en el puerto",
				Actors = { { Npc = "Kerr", Place = "PuertoEspacial", Offset = V(-10, 0, 8) } } },
			{ Type = "Reach", Place = "GuaridaEste", Text = "Ve al punto de recogida, junto a la guarida del Este" },
			{ Type = "Use", Prop = "Caja", Text = "Encuentra la caja" },
			{ Type = "Scene", Dialogue = "Saqueadores",
				Actors = { { Npc = "Saqueador1", Place = "GuaridaEste", Offset = V(-8, 0, 2) }, { Npc = "Saqueador2", Place = "GuaridaEste", Offset = V(8, 0, 2) } } },
			{ Type = "Fight", Place = "GuaridaEste", Respawn = "GuaridaEste", Action = "Golpe ⚔", HP = 5,
				Text = "Los saqueadores quieren la caja. Derríbalos sin matarlos ({count}/{total})",
				CaughtLine = "(Te tiran al suelo y te quitan el aliento. La caja sigue a tu lado. Te levantas.)",
				Enemies = {
					{ Npc = "Saqueador1", Offset = V(-8, 0, 2), Speed = 11, HP = 3, Bye = "Vale… vale. Llévatela. Era para mi hija." },
					{ Npc = "Saqueador2", Offset = V(8, 0, 2), Speed = 11, HP = 3, Bye = "La próxima vez no estarás tú solo." },
				} },
			{ Type = "Choice", Key = "EncMedicinas", Text = "La caja lleva antibióticos: lo que más falta en el hospital. Kerr los venderá a precio de oro. Uno de los saqueadores tiene una hija enferma. ¿Qué haces?",
				Options = {
					{ Id = "Kerr", Text = "Cumplir el trato: llevársela a Kerr y cobrar", Effects = { Flags = { "MedicinasKerr" }, Money = 1500 } },
					{ Id = "Hospital", Text = "Llevarla al hospital del asentamiento, gratis", Effects = { Flags = { "MedicinasHospital" }, Traits = { Empatia = 1 }, Rel = { Kerr = -10 } } },
					{ Id = "Saqueador", Text = "Darle un frasco al saqueador para su hija y el resto al hospital", Effects = { Flags = { "MedicinasReparto" }, Traits = { Empatia = 1 }, Rel = { Kerr = -10 } } },
				} },
			{ Type = "Talk", Npc = "Kerr", Dialogue = "Cobro", Text = "Vuelve al puerto: Kerr te espera", If = { Choices = { EncMedicinas = "Kerr" } },
				Actors = { { Npc = "Kerr", Place = "PuertoEspacial", Offset = V(-10, 0, 8) } } },
			{ Type = "Talk", Npc = "Kerr", Dialogue = "Enfado", Text = "Kerr se ha enterado. Te busca en el puerto", If = { Choices = { EncMedicinas = "Hospital" } },
				Actors = { { Npc = "Kerr", Place = "PuertoEspacial", Offset = V(-10, 0, 8) } } },
			{ Type = "Talk", Npc = "Kerr", Dialogue = "Enfado", Text = "Kerr se ha enterado. Te busca en el puerto", If = { Choices = { EncMedicinas = "Saqueador" } },
				Actors = { { Npc = "Kerr", Place = "PuertoEspacial", Offset = V(-10, 0, 8) } } },
		},
		Dialogues = {
			Trato = { Lines = {
				{ S = "Kerr", T = "Una caja. Junto a la guarida del Este. La dejó allí un amigo que ya no puede ir a por ella. Me la traes sin abrirla y te pago lo que gana un guardia en un mes." },
				{ S = "Kerr", T = "Sin abrirla. Eso es parte del precio." },
			} },
			Caja = { Lines = {
				{ S = "Narrador", T = "La abres, claro. Dentro, en espuma, frascos de antibióticos con el sello del viejo hospital central. Medio centenar." },
				{ S = "Narrador", T = "Pasos detrás de ti." },
			} },
			Saqueadores = { Lines = {
				{ S = "Saqueador1", T = "Esa caja es nuestra. La vimos nosotros primero." },
				{ S = "Saqueador2", T = "No tienes que hacerte daño por las medicinas de un contrabandista, chaval. Déjala y vete." },
			} },
			Cobro = { Lines = {
				{ S = "Kerr", T = "Sin preguntas. Me gusta la gente sin preguntas. Habrá más trabajos." },
				{ S = "Narrador", T = "Esa semana, en el hospital, un frasco de antibiótico cuesta tres meses de raciones." },
			} },
			Enfado = { Lines = {
				{ S = "Kerr", T = "Me debes una caja. No me importa a quién se la hayas dado." },
				{ S = "Kerr", T = "No voy a hacer nada. Hoy. Pero en este puerto todo se acaba pagando." },
			} },
		},
	}),

	---------------------------------------------------------------------
	side({
		Id = "Enc03_Tunel",
		Title = "Los del túnel",
		Description = "Del refugio del campus salió un grupo por el túnel la tercera noche. Alguien ha visto humo de una hoguera al otro lado del Campus.",
		Type = "Encargo del asentamiento",
		Duration = { 14, 18 },
		Npcs = { "Lena", "Sorel" },
		Requires = { Flags = { "GuerreroDePrimera" }, Completed = { "Rec04_Campus" } },
		Offer = { Place = "Pista" },
		OfferKey = "Sorel te espera en la pista, nerviosa: «Brenn ha visto humo más allá del campus. Humo de hoguera.»",
		Moment = "Encontraste a los supervivientes del túnel",
		Rewards = { Money = 1500 },
		Props = {
			Hoguera = { Kind = "Marcador", Name = "Restos de una hoguera, todavía caliente", Prompt = "Examinar la hoguera", Place = "GuaridaCampus", Offset = V(-12, 0, 18), Dialogue = "Hoguera", Once = true },
			Marcas = { Kind = "Mural", Name = "Marcas de tiza en una pared", Prompt = "Leer las marcas", Place = "GuaridaCampus", Offset = V(12, 0, 20), Dialogue = "Marcas", Once = true },
		},
		Steps = {
			{ Type = "Reach", Place = "GuaridaCampus", Text = "Ve con Sorel más allá del campus, donde se vio el humo", Actors = { { Npc = "Sorel", Mode = "Follow" } } },
			{ Type = "Group", Text = "Busca el rastro del grupo", Actors = { { Npc = "Sorel", Mode = "Follow" } },
				Steps = {
					{ Type = "Use", Prop = "Hoguera", Text = "La hoguera" },
					{ Type = "Use", Prop = "Marcas", Text = "Las marcas de tiza" },
				} },
			{ Type = "Event", Event = "BeastKilled", Count = 8, Match = { Region = "Farm_Universitario" }, Text = "Una manada ha olido lo mismo que tú. Aléjala del campamento ({count}/{total})" },
			{ Type = "Talk", Npc = "Lena", Dialogue = "Lena", Text = "Alguien te observa desde unas ruinas. Habla con ella",
				Actors = { { Npc = "Lena", Place = "GuaridaCampus", Offset = V(0, 0, 26) }, { Npc = "Sorel", Place = "GuaridaCampus", Offset = V(-4, 0, 22) } } },
			{ Type = "Choice", Key = "EncTunel", Text = "Son once. Dos están enfermos. No se fían del Consejo, que les dejó fuera la noche de la Caída. ¿Qué les propones?",
				Options = {
					{ Id = "Traer", Text = "Traerlos al asentamiento: la Academia responderá por ellos", Effects = { Flags = { "TunelAsentamiento" }, Rel = { Sorel = 6, Lena = 8 } } },
					{ Id = "Ayudar", Text = "Respetar su decisión y traerles medicinas y comida donde están", Effects = { Flags = { "TunelFuera" }, Rel = { Lena = 10 } } },
				},
				Actors = { { Npc = "Lena", Place = "GuaridaCampus", Offset = V(0, 0, 26) } } },
			{ Type = "Reach", Place = "Pista", Text = "Escolta al grupo hasta la empalizada", If = { Choices = { EncTunel = "Traer" } },
				Actors = { { Npc = "Lena", Mode = "Follow" }, { Npc = "Sorel", Mode = "Follow" } } },
			{ Type = "Scene", Dialogue = "Sorel", Actors = { { Npc = "Sorel", Place = "Pista", Offset = V(4, 0, 0) } } },
		},
		Dialogues = {
			Hoguera = { Lines = {
				{ S = "Narrador", T = "Las brasas todavía queman. Alrededor, huesos de bestia limpios, roídos con cuchillo: alguien ha aprendido a comérselas." },
			} },
			Marcas = { Lines = {
				{ S = "Narrador", T = "Rayas de tiza en grupos de cinco. Cientos. Días. Al final, una lista de nombres. Algunos tachados." },
				{ S = "Sorel", T = "(muy bajito) Busco dos nombres. …No están. Ni tachados ni sin tachar." },
			} },
			Lena = { Lines = {
				{ S = "Lena", T = "Quieta. Hay tres arcos apuntándote ahora mismo. …Uniforme de la Academia. No sabía que aún existía." },
				{ S = "Lena", T = "Salimos del campus por el túnel la tercera noche. Éramos cuarenta. Quedamos once." },
				{ S = "Sorel", T = "¿Había un hombre con un cuaderno azul? ¿Y una mujer que…?" },
				{ S = "Lena", T = "El del cuaderno nos sacó por el túnel. Se quedó atrás cerrando la compuerta para que pasáramos. Lo siento." },
			} },
			Sorel = { Lines = {
				{ S = "Sorel", T = "Cerró la compuerta para que pasaran los demás. Claro que sí. Era muy de él." },
				{ S = "Sorel", T = "Gracias por venir conmigo. Ya sé dónde terminó la historia. Ahora puedo empezar otra." },
			}, Effects = { Rel = { Sorel = 8 } } },
		},
	}),

	---------------------------------------------------------------------
	side({
		Id = "Enc04_Desertor",
		Title = "El chaleco",
		Description = "Uno de los guardias del Consejo vio los papeles del archivo. Quiere irse. Si le pillan cruzando la empalizada, le acusarán de traición.",
		Type = "Encargo del asentamiento",
		Duration = { 10, 14 },
		Npcs = { "Tavo", "GuardiaConsejo1", "GuardiaConsejo2" },
		Requires = { Flags = { "GuerreroDePrimera" }, Completed = { "Gri03_Umbral" } },
		Offer = { Place = "PlazaCentro" },
		OfferKey = "Un guardia del Consejo se te acerca sin mirarte a la cara: «Tú entraste en el archivo. Necesito tu ayuda.»",
		Moment = "Ayudaste a Tavo a dejar el Consejo",
		Rewards = { Money = 1000 },
		Steps = {
			{ Type = "Talk", Npc = "Tavo", Dialogue = "Pide", Text = "Habla con el guardia en la plaza",
				Actors = { { Npc = "Tavo", Place = "PlazaCentro", Offset = V(-6, 0, 4) } } },
			{ Type = "Escape", Place = "GuaridaOeste", Respawn = "PlazaCentro", Catch = 4,
				Text = "Saca a Tavo por la puerta oeste de la empalizada sin que os vean sus compañeros",
				CaughtLine = "¡Tavo! ¿Adónde vas sin el relevo? …Volved a la plaza. Ahora.",
				Actors = {
					{ Npc = "Tavo", Mode = "Follow" },
					{ Npc = "GuardiaConsejo1", Place = "PlazaCentro", Offset = V(14, 0, 10), Mode = "Hunt", Speed = 10, Prompt = false },
					{ Npc = "GuardiaConsejo2", Place = "PlazaCentro", Offset = V(-14, 0, 12), Mode = "Hunt", Speed = 9, Prompt = false },
				} },
			{ Type = "Choice", Key = "EncTavo", Text = "Fuera de la empalizada, Tavo se quita el chaleco del Consejo. ¿Qué le dices?",
				Options = {
					{ Id = "Academia", Text = "«En la Academia hace falta gente que sepa decir que no.»", Effects = { Flags = { "TavoAcademia" }, Rel = { Kael = 2 } } },
					{ Id = "Tunel", Text = "«Hay un grupo fuera, más allá del campus. Les vendría bien alguien como tú.»", Effects = { Flags = { "TavoTunel" } }, If = { Completed = { "Enc03_Tunel" } } },
					{ Id = "Libre", Text = "«Ve donde quieras. Ya no le debes nada a nadie.»", Effects = { Flags = { "TavoLibre" } } },
				},
				Actors = { { Npc = "Tavo", Place = "GuaridaOeste", Offset = V(0, 0, 20) } } },
			{ Type = "Scene", Dialogue = "Adios", Actors = { { Npc = "Tavo", Place = "GuaridaOeste", Offset = V(0, 0, 20) } } },
		},
		Dialogues = {
			Pide = { Lines = {
				{ S = "Tavo", T = "Me llamo Tavo. Llevo seis años en la guardia. La noche de la Caída escolté a los coches del Consorcio por la carretera principal mientras el Sur ardía. Creí que eran órdenes normales." },
				{ S = "Tavo", T = "Ahora sé lo que eran. No puedo seguir llevando esto. Si me voy por la puerta, me acusarán de traición. Sácame por el oeste." },
			} },
			Adios = { Lines = {
				{ S = "Tavo", T = "Seis años con el chaleco puesto y es la primera vez que respiro." },
				{ S = "Narrador", T = "Deja el chaleco colgado de un poste de la valla, bien a la vista. Que lo encuentren." },
			} },
		},
	}),
}
