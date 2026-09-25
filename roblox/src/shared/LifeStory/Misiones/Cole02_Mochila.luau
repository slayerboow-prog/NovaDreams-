-- MISIÓN 02 · «LA MOCHILA DESAPARECIDA» (15-25 min)
-- Ficha de diseño completa: docs/historia/11-misiones-episodicas.md, apartado 11.8.
--
-- Recado a conserjería → la mochila no está (se va de tu inventario) → buscar en el aula →
-- preguntar a compañeros (pistas distintas) → pistas en el patio → Álex y sus 3 canastas →
-- el almacén del gimnasio → Rubén: "¿Buscas esto?" → decisión → Lucía → la mochila vuelve.
-- Consecuencia a las 10 h de juego: Rubén reaparece (Eco_Ruben).

local V = Vector3.new

local function seated(npc: string, index: number): { [string]: any }
	return { Npc = npc, Place = "PupitreA", Index = index, Offset = V(2.4, 0, 0), Mode = "Sit", Look = V(-1, 0, 0), Prompt = false }
end
local CLASE = {
	{ Npc = "Lucia", Place = "PizarraA", Look = V(1, 0, 0) },
	seated("Iker", 1),
	seated("Sara", 2),
	seated("Vega", 4),
	seated("Omar", 5),
	seated("Alex", 6),
	seated("Hugo", 8),
	seated("Bruno", 9),
	seated("Mateo", 12),
	seated("Nico", 13),
}
local RAMON = { Npc = "Ramon", Place = "Conserjeria", Look = V(-1, 0, 0) }

-- Tus compañeros, de pie por el colegio (cada uno vio algo distinto)
local TESTIGOS = {
	{ Npc = "Sara", Place = "AulaA", Offset = V(2, 0, -4) },
	{ Npc = "Omar", Place = "SpotInformantePasillo" },
	{ Npc = "Iker", Place = "SpotInformanteBiblioteca" },
	{ Npc = "Mateo", Place = "JuegosColegio", Offset = V(-4, 0, 2), If = { Flags = { "AyudasteAMateo" } } },
	{ Npc = "Nico", Place = "SpotGrupoDeportistas", Talk = "Nico_Mochila" },
}
local CANCHA = { -- el grupo del gimnasio (junto a la canasta de dentro)
	{ Npc = "Alex", Place = "SpotGimnasioGrupo" },
	{ Npc = "Mayor1", Place = "SpotGimnasioGrupo", Offset = V(-2.5, 0, 1), Bark = "¡Ni la toques, que es nuestra canasta!" },
	{ Npc = "Mayor2", Place = "SpotGimnasioGrupo", Offset = V(2.5, 0, 1), Bark = "Álex siempre gana. Siempre." },
}
local RUBEN_ALMACEN = { Npc = "Ruben", Place = "SpotAlmacenNPC" }
local LUCIA_ALMACEN = { Npc = "Lucia", Place = "AlmacenColegio", Offset = V(-3, 0, 3) }

return {
	Id = "Cole02_Mochila",
	Kind = "Main",
	Title = "La mochila desaparecida",
	Description = "Tu mochila ha desaparecido. Alguien sabe algo… y vas a descubrir quién.",
	Chapter = "Nino_ElColegio",
	AgeRange = { 6, 7 },
	Duration = { 15, 25 },
	Difficulty = 2,
	Type = "Historia · Investigación",
	Requires = { Completed = { "Cole01_PrimerDia" }, StageProgress = 0.08 },
	Npcs = { "Lucia", "Ramon", "Sara", "Omar", "Iker", "Mateo", "Nico", "Alex", "Mayor1", "Mayor2", "Ruben", "Bruno", "Hugo" },
	Locations = { "AulaA", "Conserjeria", "PasilloColegio", "BibliotecaColegio", "Patio", "JuegosColegio", "GimnasioColegio", "AlmacenColegio" },
	Next = { "Cole03_Grupo" },
	Outcomes = { "Enfadarte con Rubén", "Perdonarle", "Contárselo a Lucía", "Devolverle la broma" },

	Moment = "Recuperaste tu mochila",
	Memory = "MochilaPerdida",
	Rewards = { Later = { { AfterHours = 10, Start = "Eco_Ruben" } } },

	Props = {
		Pupitre = { Kind = "Marcador", Name = "Tu sitio", Prompt = "Buscar", Place = "AulaA", Offset = V(4, 0, 0), Dialogue = "Buscar_Pupitre", Once = true },
		Taquilla = { Kind = "Caja", Name = "Tu taquilla (la 3)", Prompt = "Abrir", Place = "TaquillaColegio", Offset = V(0, 0, 4), Dialogue = "Buscar_Taquilla", Once = true },
		Papelera = { Kind = "Papelera", Name = "Papelera", Prompt = "Buscar", Place = "AulaA", Offset = V(-6, 0, 11), Dialogue = "Buscar_Papelera", Once = true },

		Papel = { Kind = "Papel", Name = "Papel arrugado", Prompt = "Examinar", Place = "SpotPistaPapel", Dialogue = "Pista_Papel", Once = true },
		Pegatina = { Kind = "Pegatina", Name = "Algo brillante", Prompt = "Examinar", Place = "SpotPistaPegatina", Dialogue = "Pista_Pegatina", Once = true },
		Huella = { Kind = "Huella", Name = "Huellas de barro", Prompt = "Examinar", Place = "SpotPistaHuella", Dialogue = "Pista_Huella", Once = true },
		Llavero = { Kind = "Llavero", Name = "Llavero", Prompt = "Examinar", Place = "SpotPistaObjeto", Dialogue = "Pista_Llavero", Once = true },
		Envoltorio = { Kind = "Envoltorio", Name = "Envoltorio rosa", Prompt = "Examinar", Place = "Patio", Offset = V(12, 0, 2), Dialogue = "Pista_Envoltorio", Once = true },

		MochilaRoja = { Kind = "Mochila", Name = "Mochila roja", Prompt = "Mirar", Place = "MochilaAlmacen1", Offset = V(-2, 0, -2), Color = Color3.fromRGB(200, 40, 40), Dialogue = "Almacen_Roja" },
		MochilaVerde = { Kind = "Mochila", Name = "Mochila verde", Prompt = "Mirar", Place = "MochilaAlmacen2", Offset = V(0, 0, -3), Color = Color3.fromRGB(40, 150, 60), Dialogue = "Almacen_Verde" },
		MochilaGris = { Kind = "Mochila", Name = "Mochila amarilla", Prompt = "Mirar", Place = "MochilaAlmacen3", Offset = V(2, 0, -2), Color = Color3.fromRGB(240, 190, 40), Dialogue = "Almacen_Gris" },
		TuMochila = { Kind = "Mochila", Name = "¡Tu mochila!", Prompt = false, Place = "MochilaAlmacen5", Offset = V(4.5, 0, 2.5), Color = Color3.fromRGB(40, 110, 200) },
		GorraRuben = { Kind = "Caja", Name = "La gorra de Rubén (en una caja)", Prompt = "Esconder la gorra", Place = "AlmacenColegio", Offset = V(-4, 0, -1), Color = Color3.fromRGB(110, 60, 150), Dialogue = "Broma_Gorra", Once = true },
	},

	Steps = {
		{ Type = "Transition", Text = "Unos días después…", Seconds = 3 },
		{ Type = "Reach", Place = "AulaA", Text = "Ve a clase (1.º A)", Actors = CLASE },
		{ Type = "Scene", Dialogue = "Encargo", Actors = CLASE },
		{ Type = "Talk", Npc = "Ramon", Dialogue = "Ramon_Lista", Text = "Lleva la lista de clase a Ramón (conserjería, en la entrada)",
			Actors = { RAMON } },
		{ Type = "Reach", Place = "AulaA", Text = "Vuelve a clase", Actors = { RAMON } },

		-- La mochila no está
		{ Type = "Scene", Dialogue = "NoEsta", Effects = { Take = { MochilaCole = 1 } } },
		{ Type = "Group", Text = "Busca tu mochila en el aula",
			Steps = {
				{ Type = "Use", Prop = "Pupitre", Text = "Tu pupitre" },
				{ Type = "Use", Prop = "Taquilla", Text = "Tu taquilla del pasillo" },
				{ Type = "Use", Prop = "Papelera", Text = "La papelera (por si acaso)" },
			} },
		{ Type = "Scene", Dialogue = "Lucia_Pregunta", Actors = { { Npc = "Lucia", Place = "AulaA", Offset = V(-2, 0, 0) } } },

		-- Preguntar: cada compañero vio algo distinto
		{ Type = "Group", Text = "Pregunta a tus compañeros", Need = 3,
			Steps = {
				-- Si Mateo es tu amigo, va el primero: la línea guía te lleva antes a él
				{ Type = "Talk", Npc = "Mateo", Dialogue = "Testigo_Mateo", Text = "Mateo quiere decirte algo (zona de juegos)", If = { Flags = { "AyudasteAMateo" } } },
				{ Type = "Talk", Npc = "Sara", Dialogue = "Testigo_Sara", Text = "Sara (en el aula)" },
				{ Type = "Talk", Npc = "Omar", Dialogue = "Testigo_Omar", Text = "Omar (en el pasillo)" },
				{ Type = "Talk", Npc = "Iker", Dialogue = "Testigo_Iker", Text = "Iker (en la biblioteca)" },
			},
			Actors = TESTIGOS },

		-- Investigar el patio
		{ Type = "Group", Text = "Busca pistas en el patio", Need = 4,
			Steps = {
				{ Type = "Use", Prop = "Papel", Text = "Un papel arrugado" },
				{ Type = "Use", Prop = "Pegatina", Text = "Algo que brilla" },
				{ Type = "Use", Prop = "Huella", Text = "Huellas de barro" },
				{ Type = "Use", Prop = "Llavero", Text = "Un llavero" },
				{ Type = "Use", Prop = "Envoltorio", Text = "Un envoltorio" },
			},
			Actors = TESTIGOS },
		{ Type = "Scene", Dialogue = "Deduccion" },

		-- La cancha: Álex sabe algo
		{ Type = "Reach", Place = "GimnasioColegio", Text = "Sigue las huellas hasta el gimnasio", Actors = CANCHA },
		{ Type = "Talk", Npc = "Alex", Dialogue = "Alex_Reto", Text = "Habla con Álex", Actors = CANCHA },
		{ Type = "MiniGame", Game = "Timing", Title = "¡Mete 3 canastas!", Icon = "🏀", Hint = "Suelta cuando la aguja esté en verde. Cada canasta, más difícil.",
			Rounds = 8, Need = 3, Zone = 0.24, Shrink = 0.035, Speed = 1.1,
			Win = { Flags = { "CanastasAlex" }, Rel = { Alex = 10 }, Traits = { Deportividad = 1 } },
			Lose = { Flags = { "SinCanastas" }, Rel = { Alex = 3 } },
			Actors = CANCHA },
		{ Type = "Scene", Dialogue = "Alex_Pista", Actors = CANCHA },

		-- El almacén
		{ Type = "Reach", Place = "AlmacenColegio", Text = "Ve al almacén del gimnasio" },
		{ Type = "Scene", Dialogue = "Almacen_Entra" },
		{ Type = "Group", Text = "Revisa las mochilas del almacén",
			Steps = {
				{ Type = "Use", Prop = "MochilaRoja", Text = "La roja" },
				{ Type = "Use", Prop = "MochilaVerde", Text = "La verde" },
				{ Type = "Use", Prop = "MochilaGris", Text = "La amarilla" },
			} },
		{ Type = "Scene", Dialogue = "Ruben_Aparece", Actors = { RUBEN_ALMACEN }, Props = { "TuMochila" } },

		-- La broma de vuelta (solo si eliges devolvérsela)
		{ Type = "Use", Prop = "GorraRuben", Text = "Esconde la gorra de Rubén", If = { Choices = { MochilaRuben = "Broma" } },
			Actors = { RUBEN_ALMACEN }, Props = { "TuMochila" } },

		{ Type = "Scene", Dialogue = "Lucia_Final", Actors = { RUBEN_ALMACEN, LUCIA_ALMACEN }, Props = { "TuMochila" },
			Effects = { Items = { MochilaCole = 1 } } },
	},

	Dialogues = {
		Encargo = { Lines = {
			{ S = "Lucia", T = "¡Buenos días! {nombre}, ¿me haces un favor? Lleva esta lista de clase a Ramón, a conserjería." },
			{ S = "Lucia", T = "Deja la mochila en tu silla, que vuelves enseguida." },
			{ S = "Narrador", T = "Cuelgas la mochila en el respaldo. Al fondo, Bruno le susurra algo a Rubén. Rubén se ríe." },
		}, Effects = { Flags = { "DejasteMochila" } } },

		Ramon_Lista = { Lines = {
			{ S = "Ramon", T = "¡La lista! Gracias. Veinte nombres, veinte mochilas, veinte bocadillos. Y un conserje." },
			{ S = "Ramon", T = "¿Sabes cuántas cosas pierde un colegio en un año? Trescientas doce. Las tengo apuntadas." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "¿Y dónde van todas esas cosas?", Effects = { Traits = { Curiosidad = 1 }, Rel = { Ramon = 3 } }, Then = {
					{ S = "Ramon", T = "Unas a mi caja de objetos perdidos. Otras… a sitios donde nadie mira. Jejeje." },
				} },
				{ T = "¡Me tengo que ir, que me espera Lucía!", Effects = { Traits = { Responsabilidad = 1 } }, Then = {
					{ S = "Ramon", T = "¡Corre, corre! Qué responsabilidad tan grande tan pequeña." },
				} },
			} },
		} },

		NoEsta = { Lines = {
			{ S = "Narrador", T = "Vuelves a tu sitio. La silla está vacía." },
			{ S = "Yo", T = "…¿Y mi mochila?" },
			{ S = "Narrador", T = "No está. Ni en la silla, ni debajo. Tu mochila azul, con tu nombre bordado, ha desaparecido." },
			{ S = "Narrador", T = "(Ya no está en tu inventario.)" },
			{ S = "Yo", T = "Y el cromo de la suerte estaba dentro…", If = { Flags = { "LlevaCromo" } } },
			{ S = "Narrador", T = "Busca bien por el aula. A lo mejor alguien la ha cambiado de sitio." },
		} },
		Buscar_Pupitre = { Lines = {
			{ S = "Narrador", T = "Debajo del pupitre: una goma, dos lápices sin punta y un chicle pegado de hace años. Ni rastro." },
		} },
		Buscar_Taquilla = { Lines = {
			{ S = "Narrador", T = "Tu taquilla, la número 3. Dentro: el chándal de gimnasia y una foto de tu familia. La mochila no cabe aquí." },
		} },
		Buscar_Papelera = { Lines = {
			{ S = "Narrador", T = "Miras dentro de la papelera. Solo papeles. Y una piel de plátano que te mira con pena." },
			{ S = "Yo", T = "Vale. Esto ya no es un despiste. Alguien se la ha llevado." },
		} },

		Lucia_Pregunta = { Lines = {
			{ S = "Lucia", T = "¿Qué pasa, {nombre}? Tienes cara de haber visto un fantasma." },
			{ S = "Yo", T = "Mi mochila. No está. La dejé aquí y… no está." },
			{ S = "Lucia", T = "Vaya. Mochilas no vuelan. Pregunta a tus compañeros: alguien habrá visto algo. Yo aviso a Ramón." },
		} },

		Testigo_Sara = { Lines = {
			{ S = "Sara", T = "¿Una mochila azul? Sí. Hace diez minutos. Por la ventana. Hacia el patio." },
			{ S = "Sara", T = "La llevaba alguien con prisa. Y con sudadera morada. Dato importante: la sudadera era MORADA." },
		}, Effects = { Flags = { "PistaSara" } } },
		Testigo_Omar = { Lines = {
			{ S = "Omar", T = "Espera, que lo tengo dibujado. Dibujo todo lo que pasa en el pasillo. Es mi sitio." },
			{ S = "Narrador", T = "Omar te enseña su cuaderno: un niño corriendo con una mochila azul hacia… el gimnasio." },
			{ S = "Omar", T = "No le vi la cara. Iba muy rápido y los dibujos rápidos salen borrosos." },
		}, Effects = { Flags = { "PistaOmar" }, Rel = { Omar = 3 } } },
		Testigo_Iker = { Lines = {
			{ S = "Iker", T = "Oí algo. «La mochila azul», dijo uno. «Al sitio de siempre», dijo otro. Y se rieron." },
			{ S = "Iker", T = "Dato curioso: el sitio de siempre suele ser el sitio donde nadie mira." },
		}, Effects = { Flags = { "PistaIker" } } },
		Testigo_Mateo = { Lines = {
			{ S = "Mateo", T = "{nombre}… yo lo vi. Fue Rubén. Bruno le dijo que lo hiciera." },
			{ S = "Mateo", T = "No dije nada porque… me dio miedo. Perdona." },
			{ Ask = "¿Qué le dices?", Options = {
				{ T = "Gracias por contármelo. Eres valiente.", Effects = { Rel = { Mateo = 10 }, Traits = { Empatia = 1 } }, Then = {
					{ S = "Mateo", T = "¿Yo? ¿Valiente? …Nadie me había dicho eso." },
				} },
				{ T = "¿Por qué no lo dijiste antes?", Effects = { Rel = { Mateo = -3 } }, Then = {
					{ S = "Mateo", T = "Ya… lo siento. Es que Bruno da miedo." },
				} },
			} },
		}, Effects = { Flags = { "PistaMateo" } } },
		Nico_Mochila = { Lines = {
			{ S = "Nico", T = "¿Tu mochila? ¡Qué fuerte! Si pillo al que ha sido, le reto a una carrera. Y le gano." },
		} },

		Pista_Papel = { Lines = {
			{ S = "Narrador", T = "Un horario de clase arrugado. En una esquina, alguien ha dibujado una calavera y ha firmado: «R.»" },
		}, Effects = { Flags = { "PistaR" } } },
		Pista_Pegatina = { Lines = {
			{ S = "Narrador", T = "¡Es tu cromo de la suerte! El portero legendario, tirado en el suelo. Se ha caído de tu mochila.", If = { Flags = { "LlevaCromo" } } },
			{ S = "Narrador", T = "Una pegatina de dinosaurio. Es la que estaba pegada en tu mochila. Se ha despegado aquí.", If = { NotFlags = { "LlevaCromo" } } },
			{ S = "Yo", T = "Mi mochila ha pasado por aquí. Seguro." },
		}, Effects = { Flags = { "PistaMochilaPaso" } } },
		Pista_Huella = { Lines = {
			{ S = "Narrador", T = "Huellas de barro. Zapatillas pequeñas. Van hacia el gimnasio… y se nota que alguien corría." },
		}, Effects = { Flags = { "PistaHuellas" } } },
		Pista_Llavero = { Lines = {
			{ S = "Narrador", T = "Un llavero rojo con una «B» enorme. B… de Bruno." },
			{ S = "Yo", T = "Bruno no estaba solo. Pero este llavero es suyo." },
		}, Effects = { Flags = { "PistaB" } } },
		Pista_Envoltorio = { Lines = {
			{ S = "Narrador", T = "Un envoltorio de chicle de fresa. Huele a fresa. Nada más. A veces una pista es solo basura." },
		}, Effects = { Traits = { Humor = 1 } } },

		Deduccion = { Lines = {
			{ S = "Narrador", T = "Repasas lo que sabes:" },
			{ S = "Narrador", T = "· Alguien con sudadera morada se la llevó hacia el patio.", If = { Flags = { "PistaSara" } } },
			{ S = "Narrador", T = "· Omar dibujó a alguien corriendo hacia el gimnasio.", If = { Flags = { "PistaOmar" } } },
			{ S = "Narrador", T = "· «Al sitio de siempre», el sitio donde nadie mira.", If = { Flags = { "PistaIker" } } },
			{ S = "Narrador", T = "· Mateo vio a Rubén. Y Bruno se lo mandó.", If = { Flags = { "PistaMateo" } } },
			{ S = "Narrador", T = "· Un papel firmado con una «R».", If = { Flags = { "PistaR" } } },
			{ S = "Narrador", T = "· Un llavero con una «B».", If = { Flags = { "PistaB" } } },
			{ S = "Narrador", T = "· Huellas de barro hacia el gimnasio.", If = { Flags = { "PistaHuellas" } } },
			{ S = "Yo", T = "Todo apunta al gimnasio. Allí, junto a la canasta, siempre están los mayores con Álex." },
		} },

		Alex_Reto = { Lines = {
			{ S = "Alex", T = "Hola. ¿Buscas algo? Tienes cara de buscar algo." },
			{ S = "Yo", T = "Mi mochila. ¿Has visto a alguien pasar corriendo con una mochila azul?" },
			{ S = "Alex", T = "Puede. Puede que sí. Pero la información es cara." },
			{ S = "Alex", T = "Trato: mete tres canastas. Si las metes, te lo cuento todo." },
			{ S = "Alex", T = "Y ya me debes una por la apuesta del otro día, que lo sé.", If = { Choices = { GrupoRecreo = "Deportistas" } } },
		} },
		Alex_Pista = { Lines = {
			{ S = "Alex", T = "Vale, vale. Tres canastas. Un trato es un trato.", If = { Flags = { "CanastasAlex" } } },
			{ S = "Alex", T = "Ni una. Uf. Mira… te lo cuento igual, que me das pena. Pero que no se entere nadie.", If = { Flags = { "SinCanastas" } } },
			{ S = "Alex", T = "Rubén pasó con una mochila azul hace un rato. Se metió en el almacén del gimnasio." },
			{ S = "Alex", T = "Y Rubén solo hace cosas cuando Bruno se lo dice." },
			{ S = "Yo", T = "El almacén… Ramón dijo que ahí no se entra sin permiso.", If = { Flags = { "SabeDelAlmacen" } } },
		} },

		Almacen_Entra = { Lines = {
			{ S = "Narrador", T = "La puerta del almacén está entreabierta. Dentro huele a goma, a polvo y a secretos." },
			{ S = "Narrador", T = "Colchonetas, balones deshinchados… y varias mochilas amontonadas en una esquina." },
		} },
		Almacen_Roja = { Lines = {
			{ S = "Narrador", T = "Roja, con un llavero de unicornio. No es la tuya." },
		} },
		Almacen_Verde = { Lines = {
			{ S = "Narrador", T = "Verde. Huele muchísimo a bocadillo de chorizo. Definitivamente, no es la tuya." },
		} },
		Almacen_Gris = { Lines = {
			{ S = "Narrador", T = "Amarilla y gastada. Dentro, un libro de piratas con el nombre «Hugo» en la primera página." },
			{ S = "Yo", T = "¿Hugo? ¿El amigo de Bruno lee libros de piratas?" },
		}, Effects = { Flags = { "SabeLibroHugo" } } },

		Ruben_Aparece = { Lines = {
			{ S = "Ruben", T = "¿Buscas esto?" },
			{ S = "Narrador", T = "Rubén está detrás de ti. Señala la mochila azul del rincón: ¡la tuya! Sonríe… pero no mucho." },
			{ S = "Ruben", T = "Era una BROMA. Bruno dijo que a los nuevos hay que darles la bienvenida. Es una tradición." },
			{ S = "Yo", T = "Mateo te vio. Y Bruno te lo mandó.", If = { Flags = { "PistaMateo" } } },
			{ S = "Ruben", T = "…Mateo es un chivato. Bueno. Da igual. Ahí la tienes, entera." },
			{ Ask = "¿Qué haces?", Options = {
				{ T = "¡Enfadarte! «¡No tiene gracia!»", Effects = { Choice = { MochilaRuben = "Enfado" }, Rel = { Ruben = -15, Bruno = -5 }, Traits = { Valentia = 2 }, Flags = { "Ruben_Rival" } }, Then = {
					{ S = "Yo", T = "¡No tiene NINGUNA gracia! ¡Me he pasado la mañana buscándola!" },
					{ S = "Ruben", T = "Vale, vale, no grites… Jo. Era solo una broma." },
				} },
				{ T = "Perdonarle. «Vale. Pero no lo vuelvas a hacer.»", Effects = { Choice = { MochilaRuben = "Perdon" }, Rel = { Ruben = 15 }, Traits = { Empatia = 2 }, Flags = { "Ruben_Perdonado" } }, Then = {
					{ S = "Yo", T = "Vale. Te perdono. Pero no vuelvas a hacerlo, ¿eh?" },
					{ S = "Ruben", T = "¿En serio? …Vale. Oye. Gracias. Bruno no perdona nunca a nadie." },
				} },
				{ T = "Contárselo a Lucía.", Effects = { Choice = { MochilaRuben = "Profe" }, Rel = { Ruben = -5, Bruno = -10, Lucia = 5 }, Traits = { Responsabilidad = 2 }, Flags = { "AvisasteALucia" } }, Then = {
					{ S = "Yo", T = "Esto se lo tiene que saber Lucía." },
					{ S = "Ruben", T = "¡No! ¡Espera! …Uf. Bruno me va a matar. Bueno, a matar no. Pero se va a enfadar." },
				} },
				{ T = "Devolverle la broma…", Effects = { Choice = { MochilaRuben = "Broma" }, Rel = { Ruben = 5 }, Traits = { Humor = 2 }, Flags = { "BromaDeVuelta" } }, Then = {
					{ S = "Narrador", T = "Rubén deja la mochila en el suelo para atarse una zapatilla. Su gorra morada se queda junto a una caja…" },
					{ S = "Narrador", T = "Una idea malvada (pero pequeñita) cruza tu cabeza." },
				} },
			} },
		} },

		Broma_Gorra = { Lines = {
			{ S = "Narrador", T = "Metes la gorra de Rubén dentro de la caja de balones deshinchados. Perfecto." },
			{ S = "Ruben", T = "¿Y mi gorra? ¿DÓNDE ESTÁ MI GORRA? …Ah. Ya. Ja. Ja. Muy gracioso." },
			{ S = "Ruben", T = "…Vale, vale. Ha tenido gracia. Un poco." },
		} },

		Lucia_Final = { Lines = {
			{ S = "Lucia", T = "¿Qué hacéis los dos en el almacén? ¿No os ha dicho Ramón mil veces que aquí no se entra?" },
			{ S = "Lucia", T = "Rubén. Explícamelo. Ahora.", If = { Choices = { MochilaRuben = "Profe" } } },
			{ S = "Ruben", T = "Fue… una broma. Bruno me dijo… Da igual. Lo siento, {nombre}. De verdad.", If = { Choices = { MochilaRuben = "Profe" } } },
			{ S = "Lucia", T = "Gracias por contármelo, {nombre}. Hablaré con Bruno y con Rubén. Esto no es una tradición: es una tontería.", If = { Choices = { MochilaRuben = "Profe" } } },
			{ S = "Ruben", T = "Nada, profe. Estábamos… buscando un balón. Ya lo hemos encontrado.", If = { Choices = { MochilaRuben = "Perdon" } } },
			{ S = "Lucia", T = "Ya. Un balón azul con forma de mochila. Id a clase, anda. Los dos.", If = { Choices = { MochilaRuben = "Perdon" } } },
			{ S = "Ruben", T = "¡Me ha gritado, profe!", If = { Choices = { MochilaRuben = "Enfado" } } },
			{ S = "Lucia", T = "Normal, Rubén. Yo también gritaría si me escondieran la mochila. {nombre}: la próxima vez, respira hondo y ven a buscarme.", If = { Choices = { MochilaRuben = "Enfado" } } },
			{ S = "Ruben", T = "¡Profe! ¡Me ha escondido la gorra!", If = { Choices = { MochilaRuben = "Broma" } } },
			{ S = "Lucia", T = "Y tú a su mochila. Empate técnico. Ahora os la devolvéis los dos y a clase. Sin más bromas.", If = { Choices = { MochilaRuben = "Broma" } } },
			{ S = "Narrador", T = "Recuperas tu mochila. Dentro está todo. (Vuelve a estar en tu inventario.)" },
			{ S = "Narrador", T = "Al salir, ves a Bruno mirándoos desde la puerta del gimnasio. No parece contento." },
			{ S = "Narrador", T = "Detrás de él, Hugo baja la mirada. Como si quisiera estar en cualquier otro sitio.", If = { Flags = { "SabeLibroHugo" } } },
		} },
	},
}
