-- SAGA 2 «RAGNAROCK» · LOS PELIGROS DEL TERRENO: una misión secundaria por planeta que presenta su
-- problema propio del suelo o del clima (shared/Cosmos/TerrainPerils; Services/PlanetPerilService).
-- Se OFRECEN (se pueden rechazar sin castigo) después de la primera misión de cada planeta. Cada una
-- empieza con su escena (Happenings/<Planeta>.luau: <Planeta>_Peligro) y la enseña alguien del lugar.
-- Los peligros de momento (rayos, ramas, paneles) se fuerzan mientras sigues la misión: el planeta la
-- tiene en S.StoryModes (así la tormenta llega cuando toca y no hay que esperar a su hora).
--
--   Siroco_Peligro   «Las dunas que tragan»     Tavo · las arenas movedizas
--   Talasa_Peligro   «Cubierta en la tormenta»  Bruma · los rayos de la tormenta eléctrica
--   Nivalis_Peligro  «El lago de los ahogados»  Tila · el hielo fino
--   Umbria_Peligro   «Cuando llueve en Raíz»    Garza · las ramas que caen con la lluvia
--   Miasma_Peligro   «Pararrayos»               la vieja Bruma · los rayos de la lluvia ácida
--   Vertice_Peligro  «La Cúpula a oscuras»      Gil · los paneles que caen en el apagón
--
-- Para cumplir el paso del peligro vale esquivarlo o que te pille (las dos cosas enseñan): un Group con
-- Need = 1. Nadie muere: el golpe nunca te deja por debajo de 15 de vida.

local V = Vector3.new

local function after(planet: string, id: string): { [string]: any }
	return { Stage = { Min = "Adulto" }, Planet = planet, Completed = { id } }
end

local function at(npc: string, place: string, x: number, z: number, mode: string?): { [string]: any }
	return { Npc = npc, Place = place, Offset = V(x, 0, z), Mode = mode }
end

-- El paso del peligro: esquivarlo o que te pille (Need = 1)
local function peril(planet: string, perilId: string, text: string, actors: { any }?): { [string]: any }
	return {
		Type = "Group",
		Need = 1,
		Text = text,
		Actors = actors,
		Steps = {
			{ Type = "Event", Event = "PerilDodged", Match = { Planet = planet, Peril = perilId }, Text = "Esquivarlo" },
			{ Type = "Event", Event = "PerilHit", Match = { Planet = planet, Peril = perilId }, Text = "(o aprender por las malas)" },
		},
	}
end

return {
	---------------------------------------------------------------------
	-- SIROCO · Las dunas que tragan
	--   Tavo perdió un carro de bidones en las arenas movedizas de las dunas. Enseña la regla del
	--   desierto: no se corre en la arena oscura, se sale andando hacia el borde.
	---------------------------------------------------------------------
	{
		Id = "Siroco_Peligro",
		Kind = "Side",
		Title = "Las dunas que tragan",
		Description = "Tavo, el aguador, perdió un carro de bidones en las dunas, fuera del cañón. La arena oscura de Siroco se traga lo que pisa.",
		Type = "Saga 2 · Siroco · Peligros del terreno",
		Duration = { 4, 6 },
		Npcs = { "TavoAguador" },
		Offer = { Place = "Siroco_Fuente" },
		OfferKey = "Tavo mira las dunas con cara de haber perdido algo",
		Requires = after("Siroco", "Siroco_02_Deudas"),
		Moment = "Saliste de las arenas movedizas de Siroco",
		Memory = "ArenasSiroco",
		Rewards = { Money = 80, Items = { AguaFresca = 2 } },
		Steps = {
			{ Type = "Cinematic", Id = "Siroco_Peligro", Actors = { at("TavoAguador", "Siroco_Fuente", 2, 2) } },
			{ Type = "Talk", Npc = "TavoAguador", Dialogue = "Aviso", Text = "Habla con Tavo junto a la fuente de Pozo Hondo", Actors = { at("TavoAguador", "Siroco_Fuente", 2, 2) } },
			peril("Siroco", "Siroco_Arenas", "Ve a las dunas, fuera del cañón, y busca la mancha de arena oscura donde se hundió el carro. Entra y sal andando hacia el borde"),
			{ Type = "Talk", Npc = "TavoAguador", Dialogue = "Vuelta", Text = "Vuelve con Tavo a la fuente", Actors = { at("TavoAguador", "Siroco_Fuente", 2, 2) } },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "TavoAguador", T = "Esta mañana se me fue el carro por las dunas. Seis bidones. Seis días de agua para Pozo Hondo.", To = "Yo", Shot = "Medio:TavoAguador" },
				{ S = "TavoAguador", T = "Se quedó en la arena oscura. La que parece mojada. Aquí no llueve, así que ya sabes lo que es.", Beat = "Piensa" },
				{ S = "TavoAguador", T = "Arenas movedizas. Si corres, te hunde más. Si te quedas quieto, también.", A = "Shrug" },
				{ S = "TavoAguador", T = "Se sale andando. Despacio. Siempre hacia el borde. Y bebiendo, que ahí dentro la sed sube el doble.", To = "Yo", G = "Point" },
			} },
			Vuelta = { Lines = {
				{ S = "TavoAguador", T = "¡Has vuelto con los dos pies! Los bidones, que se los quede la arena. Los pies no se compran en el Zoco.", To = "Yo", A = "Happy" },
				{ S = "TavoAguador", T = "Ahora ya sabes leer la arena: la oscura no se pisa. Toma, agua fresca. Para el camino.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- TÁLASA · Cubierta en la tormenta
	--   Bruma tiene que llevar un cabo al Faro en plena tormenta eléctrica. Los rayos buscan lo que está
	--   al descubierto sobre el agua; el círculo rojo avisa justo antes.
	---------------------------------------------------------------------
	{
		Id = "Talasa_Peligro",
		Kind = "Side",
		Title = "Cubierta en la tormenta",
		Description = "Se acerca una tormenta eléctrica a Abisalia y alguien tiene que asegurar los amarres de las balsas. Bruma dice que los rayos de Tálasa avisan, si sabes mirar.",
		Type = "Saga 2 · Tálasa · Peligros del terreno",
		Duration = { 4, 6 },
		Npcs = { "Bruma" },
		Offer = { Place = "Talasa_Muelle" },
		OfferKey = "Bruma mira al cielo verde, que se ha puesto negro",
		Requires = after("Talasa", "Talasa_01_Llegada"),
		Moment = "Cruzaste la cubierta de Abisalia en plena tormenta",
		Memory = "TormentaTalasa",
		Rewards = { Money = 80 },
		Steps = {
			{ Type = "Cinematic", Id = "Talasa_Peligro", Actors = { at("Bruma", "Talasa_Muelle", 2, 2) } },
			{ Type = "Talk", Npc = "Bruma", Dialogue = "Aviso", Text = "Habla con Bruma en el muelle flotante", Actors = { at("Bruma", "Talasa_Muelle", 2, 2) } },
			peril("Talasa", "Talasa_Rayos", "Sal a la cubierta descubierta en plena tormenta: cuando veas un círculo rojo a tus pies, sal de él antes del rayo"),
			{ Type = "Talk", Npc = "Bruma", Dialogue = "Vuelta", Text = "Vuelve con Bruma al muelle", Actors = { at("Bruma", "Talasa_Muelle", 2, 2) } },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "Bruma", T = "Huele a ozono. Eso es que viene de las gordas. Las tormentas de aquí no mojan: queman.", To = "Yo", Shot = "Medio:Bruma" },
				{ S = "Bruma", T = "El rayo busca lo que está más alto y más solo. En cubierta, eso eres tú.", Beat = "Baja" },
				{ S = "Bruma", T = "Pero avisa. Justo antes, el agua de la cubierta brilla en rojo alrededor de tus pies.", G = "Point" },
				{ S = "Bruma", T = "Ves el rojo, das tres pasos. No dos. Tres. Venga, que los amarres no se atan solos.", To = "Yo" },
			} },
			Vuelta = { Lines = {
				{ S = "Bruma", T = "¿Sigues con todos los pelos en su sitio? Más o menos. Bien.", To = "Yo", A = "Happy" },
				{ S = "Bruma", T = "Con las tormentas de Tálasa no se pelea. Se baila con ellas. Tú ya sabes el paso.", To = "Yo" },
				-- (la decisión sobre la doctora Ferrán vuelve: Talasa_05_Senal)
				{ S = "Bruma", T = "Por cierto: la doctora Ferrán me pidió que te diera las gracias. No me dijo por qué. Y yo no pregunté.", To = "Yo", If = { Choices = { TalasaNoa = "Callar" } } },
				{ S = "Bruma", T = "La Almirante dice que eres de fiar. La doctora Ferrán ya no baja al muelle. En Tálasa cada verdad moja a alguien.", To = "Yo", If = { Choices = { TalasaNoa = "Contar" } } },
			} },
		},
	},

	---------------------------------------------------------------------
	-- NIVALIS · El lago de los ahogados
	--   Tila explica por qué el lago se llama así: el hielo joven aguanta al que se mueve y se rompe bajo
	--   el que se para. Hay que cruzarlo sin pararse para llevar un farol a la otra orilla.
	---------------------------------------------------------------------
	{
		Id = "Nivalis_Peligro",
		Kind = "Side",
		Title = "El lago de los ahogados",
		Description = "Viene ventisca y hay que avisar a los faroleros de la otra orilla del Lago de los Ahogados. El camino de tierra tarda una hora. El del hielo, un minuto… si no te paras.",
		Type = "Saga 2 · Nivalis · Peligros del terreno",
		Duration = { 4, 6 },
		Npcs = { "Tila" },
		Offer = { Place = "Nivalis_Hoguera" },
		OfferKey = "Tila mira hacia el lago: «Alguien tiene que cruzar»",
		Requires = after("Nivalis", "Nivalis_01_Oscuras"),
		Moment = "Cruzaste el Lago de los Ahogados",
		Memory = "LagoNivalis",
		Rewards = { Money = 80 },
		Steps = {
			{ Type = "Cinematic", Id = "Nivalis_Peligro", Actors = { at("Tila", "Nivalis_Hoguera", 2, 2) } },
			{ Type = "Talk", Npc = "Tila", Dialogue = "Aviso", Text = "Habla con Tila junto a la hoguera", Actors = { at("Tila", "Nivalis_Hoguera", 2, 2) } },
			peril("Nivalis", "Nivalis_HieloFino", "Cruza el Lago de los Ahogados por las manchas de hielo claro sin pararte. Si cruje, muévete"),
			{ Type = "Talk", Npc = "Tila", Dialogue = "Vuelta", Text = "Vuelve con Tila a la hoguera", Actors = { at("Tila", "Nivalis_Hoguera", 2, 2) } },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "Tila", T = "¿Sabes por qué el lago se llama así? No es por los cuentos. Es por la gente que se paró a mirar la aurora.", To = "Yo", Shot = "Medio:Tila" },
				{ S = "Tila", T = "El hielo claro es joven. Aguanta al que se mueve. Al que se para, no.", Beat = "Baja" },
				{ S = "Tila", T = "Si oyes que cruje, no mires abajo. Da un paso. Luego otro.", G = "Point" },
				{ S = "Tila", T = "Cruza y avisa a los de la otra orilla de que viene ventisca. Y no te pares ni para estornudar.", To = "Yo" },
			} },
			Vuelta = { Lines = {
				{ S = "Tila", T = "Seco o mojado, pero aquí. Eso es lo que cuenta en Nivalis.", To = "Yo", A = "Happy" },
				{ S = "Tila", T = "Ya han encendido los faroles al otro lado. Esta noche nadie se perderá en la ventisca.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- UMBRÍA · Cuando llueve en Raíz
	--   La lluvia torrencial de la mañana parte las ramas viejas de las copas. Garza enseña a leer la
	--   sombra que cae antes de la rama.
	---------------------------------------------------------------------
	{
		Id = "Umbria_Peligro",
		Kind = "Side",
		Title = "Cuando llueve en Raíz",
		Description = "Con la lluvia torrencial de Umbría, las ramas viejas de los árboles gigantes se parten y caen. Garza tiene que recoger semillas en plena lluvia y no quiere ir solo.",
		Type = "Saga 2 · Umbría · Peligros del terreno",
		Duration = { 4, 6 },
		Npcs = { "Garza" },
		Offer = { Place = "Umbria_Raices" },
		OfferKey = "Garza se cala el sombrero: «Va a llover fuerte»",
		Requires = after("Umbria", "Umbria_01_Caida"),
		Moment = "Esquivaste las ramas de la lluvia de Umbría",
		Memory = "LluviaUmbria",
		Rewards = { Money = 80 },
		Steps = {
			{ Type = "Cinematic", Id = "Umbria_Peligro", Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
			{ Type = "Talk", Npc = "Garza", Dialogue = "Aviso", Text = "Habla con Garza en la Plaza de las Raíces", Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
			peril("Umbria", "Umbria_Ramas", "Sal bajo la lluvia, fuera de los techos: cuando veas un círculo rojo en el suelo, apártate antes de que caiga la rama"),
			{ Type = "Talk", Npc = "Garza", Dialogue = "Vuelta", Text = "Vuelve con Garza a la plaza", Actors = { at("Garza", "Umbria_Raices", 2, 2) } },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "Garza", T = "Veinte años fuera y lo primero que se me olvidó fue esto: cuando llueve en Raíz, llueve madera.", To = "Yo", Shot = "Medio:Garza" },
				{ S = "Garza", T = "Las copas están tan altas que la rama tarda en caer. Primero se ve su sombra. Un círculo oscuro, rojizo.", G = "Point" },
				{ S = "Garza", T = "Ves la sombra, te apartas. No hay más ciencia. Bueno, sí: no te quedes debajo mirándola.", A = "Shrug" },
				{ S = "Garza", T = "Vamos. Las semillas buenas caen con la lluvia, como las ramas.", To = "Yo" },
			} },
			Vuelta = { Lines = {
				{ S = "Garza", T = "Ni un chichón. O uno pequeño. Ya eres de Raíz más que yo.", To = "Yo", A = "Happy" },
				{ S = "Garza", T = "Guarda las semillas. Lo que cae en Umbría, si lo plantas, vuelve a subir.", To = "Yo" },
			} },
		},
	},

	---------------------------------------------------------------------
	-- MIASMA · Pararrayos
	--   La vieja Bruma, la del taller de filtros, revisa los pararrayos del borde de Lastre durante la
	--   lluvia ácida. Los rayos de Miasma caen donde no hay pararrayos.
	---------------------------------------------------------------------
	{
		Id = "Miasma_Peligro",
		Kind = "Side",
		Title = "Pararrayos",
		Description = "En Anclaje Siete, la lluvia ácida trae rayos. La vieja Bruma tiene que revisar los pararrayos del borde de Lastre, y los rayos caen justo donde falta uno.",
		Type = "Saga 2 · Miasma · Peligros del terreno",
		Duration = { 4, 6 },
		Npcs = { "BrumaTaller" },
		Offer = { Place = "Miasma_Taller" },
		OfferKey = "La vieja Bruma recoge una caja de herramientas: «Viene lluvia ácida»",
		Requires = after("Miasma", "Miasma_01_Asedio"),
		Moment = "Revisaste los pararrayos de Lastre bajo la lluvia ácida",
		Memory = "PararrayosMiasma",
		Rewards = { Money = 80 },
		Steps = {
			{ Type = "Cinematic", Id = "Miasma_Peligro", Actors = { at("BrumaTaller", "Miasma_Taller", 2, 2) } },
			{ Type = "Talk", Npc = "BrumaTaller", Dialogue = "Aviso", Text = "Habla con la vieja Bruma en el taller de filtros de Lastre", Actors = { at("BrumaTaller", "Miasma_Taller", 2, 2) } },
			peril("Miasma", "Miasma_Rayos", "Ve al borde de Lastre, al descubierto, bajo la lluvia ácida: cuando veas un círculo rojo a tus pies, sal antes del rayo"),
			{ Type = "Talk", Npc = "BrumaTaller", Dialogue = "Vuelta", Text = "Vuelve con la vieja Bruma al taller", Actors = { at("BrumaTaller", "Miasma_Taller", 2, 2) } },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "BrumaTaller", T = "Lluvia ácida. Pica en la piel y trae rayos. Los rayos de aquí no caen del cielo: suben de la niebla.", To = "Yo", Shot = "Medio:BrumaTaller" },
				{ S = "BrumaTaller", T = "Donde hay pararrayos, nada. Donde falta uno, el suelo se pone rojo un segundo antes.", G = "Point" },
				{ S = "BrumaTaller", T = "Me falta saber cuál se ha roto. Tú caminas por el borde y yo miro dónde se enciende el rojo.", A = "Shrug" },
				{ S = "BrumaTaller", T = "Y si notas un cosquilleo en la nuca, no preguntes: sal corriendo.", To = "Yo" },
			} },
			Vuelta = { Lines = {
				{ S = "BrumaTaller", T = "Ya sé cuál es: el tercero. Torcido desde la última batalla. Mañana lo cambio.", To = "Yo", A = "Happy" },
				{ S = "BrumaTaller", T = "Hoy has hecho de pararrayos y no te has quemado. Eso en Lastre te da derecho a un té.", To = "Yo" },
				-- (la decisión de las góndolas de «Guerra en el cielo» vuelve: Miasma_04_Ataque)
				{ S = "BrumaTaller", T = "En la enfermería dicen tu nombre cuando cambian las vendas. Aquella noche elegiste su góndola. Aquí eso no se olvida.", To = "Yo", If = { Choices = { MiasmaGondolas = "Hospital" } } },
				{ S = "BrumaTaller", T = "Los críos de los Garúa han pintado tu cara en la barandilla de los pañuelos. Mal, pero con cariño. Aquella noche elegiste su góndola.", To = "Yo", If = { Choices = { MiasmaGondolas = "Barrio" } } },
			} },
		},
	},

	---------------------------------------------------------------------
	-- VÉRTICE · La Cúpula a oscuras
	--   En el apagón, los paneles sueltos de la Cúpula de anuncios caen sobre las aceras. Gil sabe dónde
	--   mirar: la sombra roja que se pinta en el suelo justo antes.
	---------------------------------------------------------------------
	{
		Id = "Vertice_Peligro",
		Kind = "Side",
		Title = "La Cúpula a oscuras",
		Description = "Cuando la Cúpula de Vértice se apaga, se sueltan los paneles viejos y caen sobre las aceras. Gil tiene que cruzar la Avenida a oscuras y te pide que vayas con él.",
		Type = "Saga 2 · Vértice · Peligros del terreno",
		Duration = { 4, 6 },
		Npcs = { "Gil" },
		Offer = { Place = "Vertice_Plaza" },
		OfferKey = "Gil mira la Cúpula, que parpadea: «Va a haber apagón»",
		Requires = after("Vertice", "Vertice_01_Llegada"),
		Moment = "Cruzaste Distrito Cero durante el apagón",
		Memory = "ApagonVertice",
		Rewards = { Money = 80 },
		Steps = {
			{ Type = "Cinematic", Id = "Vertice_Peligro", Actors = { at("Gil", "Vertice_Plaza", 2, 2) } },
			{ Type = "Talk", Npc = "Gil", Dialogue = "Aviso", Text = "Habla con Gil en la Plaza del Primer Cliente", Actors = { at("Gil", "Vertice_Plaza", 2, 2) } },
			peril("Vertice", "Vertice_Paneles", "Cruza la ciudad a oscuras por la calle: si ves un círculo rojo en la acera, apártate antes de que caiga el panel"),
			{ Type = "Talk", Npc = "Gil", Dialogue = "Vuelta", Text = "Vuelve con Gil a la plaza", Actors = { at("Gil", "Vertice_Plaza", 2, 2) } },
		},
		Dialogues = {
			Aviso = { Lines = {
				{ S = "Gil", T = "Mira arriba. ¿Ves cómo parpadea? MegaVerso no paga la luz desde que quebró. Va a apagarse.", To = "Yo", Shot = "Medio:Gil" },
				{ S = "Gil", T = "Cuando la Cúpula se apaga, se enfría. Y cuando se enfría, los paneles viejos se sueltan.", Beat = "Piensa" },
				{ S = "Gil", T = "Pesan como una moto. Pero antes de caer, el láser de seguridad pinta un círculo rojo en la acera. Lo único que funciona en esta ciudad.", A = "Shrug" },
				{ S = "Gil", T = "Tú vigila el suelo, que yo vigilo el cielo. Y si gritas, grita bajito, que hay cámaras.", To = "Yo" },
			} },
			Vuelta = { Lines = {
				{ S = "Gil", T = "Llegamos. Y sin multa. En Vértice eso es un milagro doble.", To = "Yo", A = "Happy" },
				{ S = "Gil", T = "Algún día alguien arreglará la Cúpula. Mientras tanto, mira al suelo. Ahí está la verdad.", To = "Yo" },
				-- (la decisión de la etiqueta vuelve: Vertice_05_Luz)
				{ S = "Gil", T = "Abril revuelve todo Distrito Cero buscando a ese tal «V.». Gracias a ti, por fin tiene un nombre que buscar.", To = "Yo", If = { Choices = { VerticeVerdad = "Contar" } } },
				{ S = "Gil", T = "¿Sigues con la etiqueta en el bolsillo? Haces bien. Aquí, quien enseña sus cartas antes de tiempo acaba en la lista de despidos.", To = "Yo", If = { Choices = { VerticeVerdad = "Guardar" } } },
			} },
		},
	},
}
