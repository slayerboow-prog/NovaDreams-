-- Crafting: FABRICAR cosas con lo que consigues (al estilo Minecraft). Cuentas puras: lo usan
-- Services/CraftingService (el Taller: comprueba, gasta y da; pociones y armaduras), Services/BeastService
-- (el daño de las armas blancas y la armadura contra las bestias), shared/Items (los objetos nuevos),
-- Controllers/CraftingUI (el libro de recetas) y las pruebas (scripts/test-crafting.luau).
--
--   * Materiales: lo que sueltan las bestias (cuero, colmillo, quitina, escama, glándula, hueso, seda), el
--     material raro de cada planeta, los trofeos de los jefes, los minerales (hierro, cobalto, cristal y
--     obsidiana: valen los de la mochila y los de la bodega de tu nave) y los materiales de las misiones.
--   * Bancos: «Mesa» (lo básico: también la mesa plegable, en cualquier sitio), «Forja» (armas y
--     armaduras) y «Alquimia» (pociones fuertes). Los Talleres de las ciudades de los planetas tienen los tres.
--   * Niveles (diseño de los mundos §2.2): 1 Chatarra · 2 Común · 3 Refinado · 4 Raro · 5 Reliquia.
--   * Armaduras: la mejor que lleves en la mochila te protege sola (Defense: parte del daño que no te llega
--     de bestias y enemigos de misión). Armas blancas: la mejor que lleves pega más fuerte a las bestias
--     (Blade: +% a tus golpes). Pociones: se usan desde la mochila.

local Crafting = {}

-- Minerales: se cuentan los de la mochila y los de la bodega de la nave (data.Space.Ore)
Crafting.Ores = { Hierro = true, Cobalto = true, Cristal = true, Obsidiana = true }

Crafting.Levels = { "Chatarra", "Común", "Refinado", "Raro", "Reliquia" }
Crafting.Benches = {
	Mesa = { Name = "Mesa de trabajo", Icon = "🧰" },
	Forja = { Name = "Forja", Icon = "🔨" },
	Alquimia = { Name = "Alquimia", Icon = "⚗️" },
}
Crafting.Categories = { "Armas", "Armaduras", "Accesorios", "Pociones", "Herramientas", "Munición", "Materiales" }

-- { Id, Nombre, Icono, Descripción }
Crafting.Materials = {
	-- de las bestias (todos los planetas)
	{ "Cuero", "Cuero de bestia", "🐾", "Piel curtida de una bestia de los planetas. Para armaduras ligeras y correas." },
	{ "Colmillo", "Colmillo", "🦷", "Afilado y duro como el acero. Para cuchillos y puntas de lanza." },
	{ "Quitina", "Placa de quitina", "🐞", "El caparazón de un insecto grande. Ligera y dura: armaduras." },
	{ "Escama", "Escama", "🐉", "Escamas de reptil que aguantan golpes, fuego y frío." },
	{ "Glandula", "Glándula", "🧫", "Lo que hace que una bestia escupa, pique o brille. Base de casi todas las pociones." },
	{ "Hueso", "Hueso grande", "🦴", "Hueso de bestia: mangos, empuñaduras y armaduras pesadas." },
	{ "Seda", "Seda de bestia", "🧵", "Hilo de araña o de avispa. Más fuerte que el acero si lo trenzas bien." },
	-- el material raro de cada planeta
	{ "BrasaViva", "Brasa viva", "🔥", "Un trozo de colada que nunca se enfría (Tefra). Para armas que queman." },
	{ "VidrioTormenta", "Vidrio de tormenta", "🔷", "Arena fundida por los rayos de las tormentas de Siroco." },
	{ "NacarAbisal", "Nácar abisal", "🐚", "El nácar de las Fosas de Tálasa: brilla solo en la oscuridad." },
	{ "HieloEterno", "Hielo eterno", "🧊", "Hielo de Nivalis que no se derrite ni al fuego." },
	{ "SaviaAmbar", "Savia ámbar", "🍯", "La savia de los árboles gigantes de Umbría. Cura y pega." },
	{ "PlataRayo", "Plata de rayo", "⚡", "Plata cargada por los rayos de Miasma. Pica al tocarla." },
	{ "ChipUsado", "Chip usado", "💾", "Un chip de Vértice que todavía guarda algo. Para aparatos." },
	-- los trofeos de los jefes escondidos
	{ "NucleoBrasa", "Núcleo de la Bestia de Brasa", "💠", "Late como un corazón. Trofeo de Tefra." },
	{ "AguijonRey", "Aguijón del Rey Escorpión", "🦂", "Todavía gotea. Trofeo de Siroco." },
	{ "PerlaLeviatan", "Perla del Leviatán", "⚪", "Del tamaño de un puño. Trofeo de Tálasa." },
	{ "CorazonHielo", "Corazón de hielo", "💙", "Frío como el espacio. Trofeo de Nivalis." },
	{ "CuernoEscarabajo", "Cuerno del Gran Escarabajo", "🌿", "Más duro que cualquier metal. Trofeo de Umbría." },
	{ "OjoTormenta", "Ojo de la tormenta", "🌀", "Dentro se ve un remolino. Trofeo de Miasma." },
	{ "PlacaRecaudador", "Placa del Recaudador", "🔩", "Con un número de serie borrado a arañazos. Trofeo de Vértice." },
	-- intermedios que se fabrican
	{ "LingoteHierro", "Lingote de hierro", "🧱", "Hierro fundido y limpio: la base de la Forja." },
	{ "LingoteCobalto", "Lingote de cobalto", "🟦", "Cobalto fundido: más ligero y más duro que el hierro." },
	{ "CuerdaTrenzada", "Cuerda trenzada", "🧶", "Seda y cuero trenzados. Para mangos, arcos y correas." },
	{ "Polvora", "Pólvora casera", "🧂", "Glándula seca y molida con azufre. Para hacer munición." },
	-- lo que solo suelta UNA bestia (hay que ir a por ella: cascos, escudos, botas y accesorios)
	{ "PelajeCeniza", "Pelaje de ceniza", "🐺", "Del Rondador de ceniza (Tefra). No arde." },
	{ "CaparazonLava", "Caparazón de lava", "🐞", "Del Escarabajo de lava (Tefra). Todavía está tibio." },
	{ "EscoriaViva", "Escoria viva", "🔥", "Del Gusano de colada (Tefra). Se mueve un poco si la miras." },
	{ "GarraDuna", "Garra de duna", "🐾", "Del Chacal de duna (Siroco). Afilada por la arena." },
	{ "VenenoSal", "Veneno de sal", "🧪", "Del Escorpión de sal (Siroco). Cristaliza al aire." },
	{ "PielArena", "Piel de arena", "🐍", "De la Serpiente de arena (Siroco). Flexible y áspera." },
	{ "PinzaNacar", "Pinza de nácar", "🦀", "Del Cangrejo de nácar (Tálasa). Corta el acero." },
	{ "OrganoElectrico", "Órgano eléctrico", "⚡", "De la Anguila de arrecife (Tálasa). Da calambre." },
	{ "GrasaAbisal", "Grasa abisal", "💧", "De la Foca colmilluda (Tálasa). Aísla del frío y del agua." },
	{ "PelajeEscarcha", "Pelaje de escarcha", "🐺", "Del Lobo de escarcha (Nivalis). Siempre está frío." },
	{ "HiloHielo", "Hilo de hielo", "🕷", "De la Araña de hielo (Nivalis). Transparente y durísimo." },
	{ "LanaGruesa", "Lana gruesa", "🐻", "Del Oso lanudo (Nivalis). Abriga más que tres abrigos." },
	{ "GarraLiana", "Garra de liana", "🐆", "De la Pantera de liana (Umbría). Curva como un anzuelo." },
	{ "AguijonEnjambre", "Aguijón del Enjambre", "🐝", "De la Avispa del Enjambre (Umbría). Zumba solo." },
	{ "CortezaViva", "Corteza viva", "🌿", "Del Escarabajo de corteza (Umbría). Sigue creciendo." },
	{ "DienteCobre", "Diente de cobre", "🐀", "De la Rata de chatarra (Miasma). Come cables." },
	{ "VelaGas", "Vela de gas", "🎐", "De la Medusa de gas (Miasma). Flota si la sueltas." },
	{ "PlumaRayo", "Pluma de rayo", "🦅", "Del Buitre de rayo (Miasma). Chisporrotea." },
	{ "ColaCable", "Cola de cable", "🐀", "De la Rata de cloaca (Vértice). Mitad cola, mitad cable." },
	{ "NucleoDron", "Núcleo de dron", "🤖", "Del Dron rebelde (Vértice). Parpadea en rojo." },
	{ "EscamaCromo", "Escama de cromo", "🐊", "Del Cocodrilo de aliviadero (Vértice). Te ves reflejado." },
	-- más intermedios
	{ "PlacaReforzada", "Placa reforzada", "🔩", "Hierro y quitina en capas. Para cascos y escudos." },
	{ "HiloEnergia", "Hilo de energía", "🧵", "Seda cargada con plata de rayo. Para collares." },
	{ "NucleoMenor", "Núcleo menor", "💠", "Un chip dentro de un cristal. Para pendientes y aparatos." },
	{ "TinteAlquimico", "Tinte alquímico", "⚗️", "Glándula y savia. Para pulseras y grabados." },
	{ "FiltroCarbon", "Filtro de carbón", "⬛", "Hueso quemado y cuero. Para botas y máscaras." },
	-- para MEJORAR el equipo (+1, +2, +3…)
	{ "PiedraPulir", "Piedra de pulir", "🔘", "La sueltan las bestias. Con ella se mejora el equipo de +0 a +4." },
	{ "PiedraTemple", "Piedra de temple", "💎", "De los jefes, o fundiendo piedras de pulir. Para mejorar de +4 a +9." },
	{ "EsenciaEstelar", "Esencia estelar", "✨", "Solo la sueltan los jefes. Para sellos y pendientes." },
	{ "SelloHerrero", "Sello del herrero", "🔏", "Si una mejora falla, el sello se gasta y tu objeto NO baja de nivel." },
}

-- Los objetos que se fabrican (Kind de shared/Items): armaduras (Armor), armas blancas (Blade), pociones
-- (Potion) y herramientas (Tool). Defense: 0..1 · Blade: +% de daño a las bestias
Crafting.Gear = {
	-- Armaduras
	{ Id = "ArmaduraCuero", Name = "Armadura de cuero", Icon = "🦺", Kind = "Armor", Defense = 0.12, Level = 1, Desc = "Llevándola en la mochila, las bestias te hacen un 12 % menos de daño." },
	{ Id = "ArmaduraQuitina", Name = "Armadura de quitina", Icon = "🛡", Kind = "Armor", Defense = 0.22, Level = 2, Desc = "Placas de insecto cosidas sobre cuero: un 22 % menos de daño." },
	{ Id = "ArmaduraEscamas", Name = "Cota de escamas", Icon = "🛡", Kind = "Armor", Defense = 0.3, Level = 3, Desc = "Escamas sobre una malla de cobalto: un 30 % menos de daño." },
	{ Id = "ArmaduraHueso", Name = "Armadura de hueso y hierro", Icon = "🛡", Kind = "Armor", Defense = 0.36, Level = 3, Desc = "Pesada, pero nada la atraviesa fácil: un 36 % menos de daño." },
	{ Id = "ArmaduraPlanetaria", Name = "Armadura de explorador", Icon = "🧥", Kind = "Armor", Defense = 0.44, Level = 4, Desc = "Con los materiales raros de tres planetas: un 44 % menos de daño." },
	{ Id = "ArmaduraTrofeo", Name = "Armadura de cazador de jefes", Icon = "👑", Kind = "Armor", Defense = 0.55, Level = 5, Desc = "Hecha con trofeos de jefes. Quien la ve sabe lo que has hecho: un 55 % menos de daño." },
	-- Armas blancas (contra las bestias)
	{ Id = "CuchilloColmillo", Name = "Cuchillo de colmillo", Icon = "🔪", Kind = "Blade", Blade = 0.25, Level = 1, Desc = "Llevándolo en la mochila, tus golpes a las bestias hacen un 25 % más." },
	{ Id = "HachaHueso", Name = "Hacha de hueso", Icon = "🪓", Kind = "Blade", Blade = 0.45, Level = 2, Desc = "Pesada y fea, pero corta: +45 % a tus golpes contra las bestias." },
	{ Id = "LanzaEscama", Name = "Lanza de escama", Icon = "🔱", Kind = "Blade", Blade = 0.65, Level = 3, Desc = "Punta de escama y mango de cobalto: +65 % contra las bestias." },
	{ Id = "EspadaCristal", Name = "Espada de cristal solar", Icon = "⚔️", Kind = "Blade", Blade = 0.9, Level = 4, Desc = "Brilla un poco al golpear: +90 % contra las bestias." },
	{ Id = "EspadaTrofeo", Name = "Hoja de los jefes", Icon = "🗡", Kind = "Blade", Blade = 1.3, Level = 5, Desc = "Forjada con trofeos de jefe: +130 % contra las bestias." },
	-- Cascos, escudos y botas (cada uno en su hueco: se suman a la armadura)
	{ Id = "CascoCeniza", Name = "Casco de ceniza", Icon = "⛑", Kind = "Armor", Slot = "Casco", Defense = 0.05, Level = 2, Desc = "Casco: un 5 % menos de daño, además de tu armadura." },
	{ Id = "CascoCromo", Name = "Casco de cromo", Icon = "⛑", Kind = "Armor", Slot = "Casco", Defense = 0.09, Level = 4, Desc = "Casco: un 9 % menos de daño, además de tu armadura." },
	{ Id = "EscudoNacar", Name = "Escudo de nácar", Icon = "🛡", Kind = "Armor", Slot = "Escudo", Defense = 0.06, Level = 2, Desc = "Escudo: un 6 % menos de daño, además de tu armadura." },
	{ Id = "EscudoCorteza", Name = "Escudo de corteza viva", Icon = "🛡", Kind = "Armor", Slot = "Escudo", Defense = 0.1, Level = 4, Desc = "Escudo: un 10 % menos de daño, además de tu armadura." },
	{ Id = "BotasDuna", Name = "Botas de duna", Icon = "👢", Kind = "Armor", Slot = "Botas", Defense = 0.04, Level = 2, Desc = "Botas: un 4 % menos de daño, además de tu armadura." },
	{ Id = "BotasEscarcha", Name = "Botas de escarcha", Icon = "👢", Kind = "Armor", Slot = "Botas", Defense = 0.07, Level = 3, Desc = "Botas: un 7 % menos de daño, además de tu armadura." },
	-- Accesorios (collar, pulsera y pendientes: uno de cada)
	{ Id = "CollarEnjambre", Name = "Collar del Enjambre", Icon = "📿", Kind = "Accessory", Slot = "Collar", Blade = 0.1, Level = 2, Desc = "Collar: +10 % a tus golpes contra las bestias." },
	{ Id = "CollarTormenta", Name = "Collar de tormenta", Icon = "📿", Kind = "Accessory", Slot = "Collar", Blade = 0.18, Level = 4, Desc = "Collar: +18 % a tus golpes contra las bestias." },
	{ Id = "PulseraCobre", Name = "Pulsera de cobre", Icon = "⭕", Kind = "Accessory", Slot = "Pulsera", Luck = 0.1, Level = 2, Desc = "Pulsera: las bestias sueltan botín raro un 10 % más a menudo." },
	{ Id = "PulseraVeneno", Name = "Pulsera de veneno", Icon = "⭕", Kind = "Accessory", Slot = "Pulsera", Blade = 0.08, Luck = 0.08, Level = 3, Desc = "Pulsera: +8 % a tus golpes y un 8 % más de botín raro." },
	{ Id = "PendientesHielo", Name = "Pendientes de hielo", Icon = "💍", Kind = "Accessory", Slot = "Pendientes", Vigor = 12, Level = 2, Desc = "Pendientes: recuperas 12 de vida cada vez que cae una bestia." },
	{ Id = "PendientesEstelares", Name = "Pendientes estelares", Icon = "💍", Kind = "Accessory", Slot = "Pendientes", Vigor = 24, Defense = 0.04, Level = 5, Desc = "Pendientes: recuperas 24 de vida por bestia y un 4 % menos de daño." },
	-- Pociones
	{ Id = "PocionCuracion", Name = "Poción de curación", Icon = "🧪", Kind = "Potion", Effect = "Heal", Amount = 50, Level = 1, Desc = "Úsala desde la mochila: te cura 50 de vida al momento." },
	{ Id = "PocionRegeneracion", Name = "Poción de regeneración", Icon = "💚", Kind = "Potion", Effect = "Regen", Amount = 4, Seconds = 25, Level = 2, Desc = "Te cura 4 de vida por segundo durante 25 segundos." },
	{ Id = "PocionFuerza", Name = "Poción de fuerza", Icon = "💪", Kind = "Potion", Effect = "Strength", Amount = 0.5, Seconds = 90, Level = 2, Desc = "Durante 90 segundos tus golpes a las bestias hacen un 50 % más." },
	{ Id = "PocionPiedra", Name = "Poción de piel de piedra", Icon = "🗿", Kind = "Potion", Effect = "Stone", Amount = 0.25, Seconds = 90, Level = 3, Desc = "Durante 90 segundos recibes un 25 % menos de daño (además de tu armadura)." },
	{ Id = "PocionVelocidad", Name = "Poción de velocidad", Icon = "💨", Kind = "Potion", Effect = "Speed", Amount = 8, Seconds = 60, Level = 2, Desc = "Durante un minuto corres bastante más." },
	{ Id = "TonicoEntorno", Name = "Tónico de entorno", Icon = "🌡", Kind = "Potion", Effect = "Hazard", Amount = 50, Level = 3, Desc = "Baja a la mitad el medidor de la desventaja del planeta (calor, sed, frío, esporas, toxinas…)." },
	-- Herramientas
	{ Id = "MesaPlegable", Name = "Mesa de trabajo plegable", Icon = "🧰", Kind = "Tool", Effect = "Bench", Level = 1, Desc = "Úsala desde la mochila para fabricar lo básico (recetas de Mesa) en cualquier sitio. No se gasta." },
	{ Id = "BrujulaBestias", Name = "Brújula de bestias", Icon = "🧭", Kind = "Tool", Effect = "Compass", Level = 2, Desc = "Úsala en un planeta: te dice hacia dónde está la guarida más cercana y si el jefe anda cerca. No se gasta." },
	{ Id = "Ganzua", Name = "Ganzúa de explorador", Icon = "🗝", Kind = "Tool", Effect = "Picklock", Level = 2, Desc = "Con ella en la mochila, los alijos escondidos te dan el doble de dinero." },
}

-- Recetas. Bench: Mesa | Forja | Alquimia. Needs: { [objeto] = cantidad }
Crafting.Recipes = {
	-- Materiales intermedios
	{ Id = "LingoteHierro", Makes = 1, Bench = "Forja", Category = "Materiales", Level = 1, Needs = { Hierro = 3 } },
	{ Id = "LingoteCobalto", Makes = 1, Bench = "Forja", Category = "Materiales", Level = 2, Needs = { Cobalto = 3 } },
	{ Id = "CuerdaTrenzada", Makes = 2, Bench = "Mesa", Category = "Materiales", Level = 1, Needs = { Seda = 2, Cuero = 1 } },
	{ Id = "Polvora", Makes = 2, Bench = "Alquimia", Category = "Materiales", Level = 1, Needs = { Glandula = 1, Hueso = 1 } },
	-- Armas blancas
	{ Id = "CuchilloColmillo", Makes = 1, Bench = "Mesa", Category = "Armas", Level = 1, Needs = { Colmillo = 2, Cuero = 1 } },
	{ Id = "HachaHueso", Makes = 1, Bench = "Forja", Category = "Armas", Level = 2, Needs = { Hueso = 3, LingoteHierro = 1, CuerdaTrenzada = 1 } },
	{ Id = "LanzaEscama", Makes = 1, Bench = "Forja", Category = "Armas", Level = 3, Needs = { Escama = 4, LingoteCobalto = 2, CuerdaTrenzada = 1 } },
	{ Id = "EspadaCristal", Makes = 1, Bench = "Forja", Category = "Armas", Level = 4, Needs = { Cristal = 3, LingoteCobalto = 2, Colmillo = 3, VidrioTormenta = 1 } },
	{ Id = "EspadaTrofeo", Makes = 1, Bench = "Forja", Category = "Armas", Level = 5, Needs = { NucleoBrasa = 1, AguijonRey = 1, LingoteCobalto = 3, Cristal = 2 } },
	-- Armas de fuego (para quien tenga la licencia: se usan igual que las de la Armería)
	{ Id = "Arma_Pistola", Makes = 1, Bench = "Forja", Category = "Armas", Level = 2, Needs = { LingoteHierro = 3, Hueso = 1, Polvora = 2 } },
	{ Id = "Arma_Escopeta", Makes = 1, Bench = "Forja", Category = "Armas", Level = 3, Needs = { LingoteHierro = 4, LingoteCobalto = 1, Hueso = 2, Polvora = 3 } },
	{ Id = "Arma_Fusil", Makes = 1, Bench = "Forja", Category = "Armas", Level = 4, Needs = { LingoteCobalto = 4, ChipUsado = 1, Polvora = 4, Escama = 2 } },
	-- Munición
	{ Id = "Municion_9mm", Makes = 15, Bench = "Forja", Category = "Munición", Level = 1, Needs = { Polvora = 1, Hierro = 1 } },
	{ Id = "Cartuchos_12", Makes = 8, Bench = "Forja", Category = "Munición", Level = 2, Needs = { Polvora = 1, Hierro = 2 } },
	{ Id = "Municion_556", Makes = 20, Bench = "Forja", Category = "Munición", Level = 3, Needs = { Polvora = 2, Cobalto = 1 } },
	-- Armaduras
	{ Id = "ArmaduraCuero", Makes = 1, Bench = "Mesa", Category = "Armaduras", Level = 1, Needs = { Cuero = 5 } },
	{ Id = "ArmaduraQuitina", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 2, Needs = { Quitina = 5, Cuero = 2, CuerdaTrenzada = 1 } },
	{ Id = "ArmaduraEscamas", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 3, Needs = { Escama = 6, LingoteCobalto = 2 } },
	{ Id = "ArmaduraHueso", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 3, Needs = { Hueso = 6, LingoteHierro = 3, Cuero = 2 } },
	{ Id = "ArmaduraPlanetaria", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 4, Needs = { HieloEterno = 2, NacarAbisal = 2, SaviaAmbar = 2, LingoteCobalto = 3 } },
	{ Id = "ArmaduraTrofeo", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 5, Needs = { CorazonHielo = 1, PerlaLeviatan = 1, CuernoEscarabajo = 1, PlacaRecaudador = 1, OjoTormenta = 1 } },
	-- Cascos, escudos y botas
	{ Id = "CascoCeniza", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 2, Needs = { PelajeCeniza = 3, CaparazonLava = 2, PlacaReforzada = 1 } },
	{ Id = "CascoCromo", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 4, Needs = { EscamaCromo = 3, NucleoDron = 1, PlacaReforzada = 2 } },
	{ Id = "EscudoNacar", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 2, Needs = { PinzaNacar = 3, GrasaAbisal = 1, PlacaReforzada = 1 } },
	{ Id = "EscudoCorteza", Makes = 1, Bench = "Forja", Category = "Armaduras", Level = 4, Needs = { CortezaViva = 4, EscoriaViva = 2, LingoteCobalto = 2 } },
	{ Id = "BotasDuna", Makes = 1, Bench = "Mesa", Category = "Armaduras", Level = 2, Needs = { PielArena = 3, GarraDuna = 2, CuerdaTrenzada = 1 } },
	{ Id = "BotasEscarcha", Makes = 1, Bench = "Mesa", Category = "Armaduras", Level = 3, Needs = { PelajeEscarcha = 3, LanaGruesa = 2, FiltroCarbon = 1 } },
	-- Accesorios
	{ Id = "CollarEnjambre", Makes = 1, Bench = "Mesa", Category = "Accesorios", Level = 2, Needs = { AguijonEnjambre = 3, GarraLiana = 1, HiloEnergia = 1 } },
	{ Id = "CollarTormenta", Makes = 1, Bench = "Forja", Category = "Accesorios", Level = 4, Needs = { PlumaRayo = 3, OrganoElectrico = 2, HiloEnergia = 2 } },
	{ Id = "PulseraCobre", Makes = 1, Bench = "Mesa", Category = "Accesorios", Level = 2, Needs = { DienteCobre = 4, ColaCable = 2, TinteAlquimico = 1 } },
	{ Id = "PulseraVeneno", Makes = 1, Bench = "Alquimia", Category = "Accesorios", Level = 3, Needs = { VenenoSal = 3, VelaGas = 2, TinteAlquimico = 1 } },
	{ Id = "PendientesHielo", Makes = 1, Bench = "Mesa", Category = "Accesorios", Level = 2, Needs = { HiloHielo = 3, NucleoMenor = 1 } },
	{ Id = "PendientesEstelares", Makes = 1, Bench = "Forja", Category = "Accesorios", Level = 5, Needs = { NucleoMenor = 2, HiloHielo = 2, EsenciaEstelar = 1 } },
	-- Más intermedios y lo de mejorar
	{ Id = "PlacaReforzada", Makes = 1, Bench = "Forja", Category = "Materiales", Level = 2, Needs = { LingoteHierro = 2, Quitina = 2 } },
	{ Id = "HiloEnergia", Makes = 1, Bench = "Mesa", Category = "Materiales", Level = 2, Needs = { Seda = 2, PlataRayo = 1 } },
	{ Id = "NucleoMenor", Makes = 1, Bench = "Mesa", Category = "Materiales", Level = 3, Needs = { ChipUsado = 1, Cristal = 1 } },
	{ Id = "TinteAlquimico", Makes = 2, Bench = "Alquimia", Category = "Materiales", Level = 2, Needs = { Glandula = 1, SaviaAmbar = 1 } },
	{ Id = "FiltroCarbon", Makes = 1, Bench = "Mesa", Category = "Materiales", Level = 1, Needs = { Hueso = 2, Cuero = 1 } },
	{ Id = "PiedraTemple", Makes = 1, Bench = "Forja", Category = "Materiales", Level = 3, Needs = { PiedraPulir = 5 } },
	{ Id = "SelloHerrero", Makes = 1, Bench = "Forja", Category = "Materiales", Level = 4, Needs = { PiedraTemple = 2, EsenciaEstelar = 1 } },
	-- Pociones
	{ Id = "PocionCuracion", Makes = 2, Bench = "Mesa", Category = "Pociones", Level = 1, Needs = { Glandula = 1, SaviaAmbar = 0 } },
	{ Id = "PocionRegeneracion", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 2, Needs = { Glandula = 2, SaviaAmbar = 1 } },
	{ Id = "PocionFuerza", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 2, Needs = { Glandula = 1, Colmillo = 1, BrasaViva = 1 } },
	{ Id = "PocionPiedra", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 3, Needs = { Glandula = 1, Escama = 2, HieloEterno = 1 } },
	{ Id = "PocionVelocidad", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 2, Needs = { Glandula = 1, Seda = 1, PlataRayo = 1 } },
	{ Id = "TonicoEntorno", Makes = 1, Bench = "Alquimia", Category = "Pociones", Level = 3, Needs = { Glandula = 2, NacarAbisal = 1 } },
	-- Herramientas
	{ Id = "MesaPlegable", Makes = 1, Bench = "Mesa", Category = "Herramientas", Level = 1, Needs = { Hierro = 4, Cuero = 2 } },
	{ Id = "BrujulaBestias", Makes = 1, Bench = "Mesa", Category = "Herramientas", Level = 2, Needs = { Hierro = 2, Glandula = 1, ChipUsado = 1 } },
	{ Id = "Ganzua", Makes = 1, Bench = "Forja", Category = "Herramientas", Level = 2, Needs = { LingoteHierro = 1, Colmillo = 1 } },
}

-- (cantidad 0 = no hace falta: se limpia aquí para que las recetas queden como se leen)
for _, r in Crafting.Recipes do
	for k, v in r.Needs do
		if v <= 0 then
			r.Needs[k] = nil
		end
	end
end

local byId: { [string]: { [string]: any } } = {}
for _, r in Crafting.Recipes do
	byId[r.Id] = r
end
local gearById: { [string]: { [string]: any } } = {}
for _, g in Crafting.Gear do
	gearById[g.Id] = g
end

function Crafting.recipe(id: string): { [string]: any }?
	return byId[id]
end
function Crafting.gear(id: string): { [string]: any }?
	return gearById[id]
end

-- ¿Se puede hacer en este banco? (los Talleres de las ciudades tienen todos: bench = "Taller"; desde la
-- mochila —bench = "Mochila"— también se fabrica todo, en cualquier sitio)
function Crafting.benchHas(bench: string, recipe: { [string]: any }): boolean
	return bench == "Taller" or bench == "Mochila" or bench == recipe.Bench
end

-- Cuántas veces se puede fabricar con lo que hay (have: { [objeto] = cantidad })
function Crafting.times(recipe: { [string]: any }, have: { [string]: number }): number
	local n = math.huge
	for item, need in recipe.Needs do
		n = math.min(n, math.floor((have[item] or 0) / need))
	end
	return if n == math.huge then 0 else n
end

-- Lo que falta: { { Item, Have, Need } }
function Crafting.missing(recipe: { [string]: any }, have: { [string]: number }): { { any } }
	local out = {}
	for item, need in recipe.Needs do
		local h = have[item] or 0
		if h < need then
			table.insert(out, { item, h, need })
		end
	end
	table.sort(out, function(a, b)
		return a[1] < b[1]
	end)
	return out
end

-- Lo que hay para fabricar: la mochila + (minerales) la bodega de la nave
function Crafting.have(data: { [string]: any }): { [string]: number }
	local out: { [string]: number } = {}
	for id, n in data.Items or {} do
		if type(n) == "number" and n > 0 then
			out[id] = n
		end
	end
	local ore = data.Space and data.Space.Ore
	if type(ore) == "table" then
		for id in Crafting.Ores do
			local n = tonumber(ore[id])
			if n and n > 0 then
				out[id] = (out[id] or 0) + n
			end
		end
	end
	return out
end

---------------------------------------------------------------------
-- EQUIPO: un objeto por hueco (el mejor que lleves en la mochila se usa solo) y MEJORAS +0…+9
---------------------------------------------------------------------
Crafting.Slots = { "Arma", "Armadura", "Casco", "Escudo", "Botas", "Collar", "Pulsera", "Pendientes" }
Crafting.SlotIcons = { Arma = "⚔️", Armadura = "🛡", Casco = "⛑", Escudo = "🛡", Botas = "👢", Collar = "📿", Pulsera = "⭕", Pendientes = "💍" }
Crafting.MaxRefine = 9
Crafting.RefineBonus = 0.1 -- cada +1 sube un 10 % lo que da el objeto (+9 = casi el doble)
Crafting.MaxDefense = 0.7

function Crafting.slotOf(g: { [string]: any }): string?
	if g.Slot then
		return g.Slot
	end
	return if g.Kind == "Blade" then "Arma" elseif g.Kind == "Armor" then "Armadura" else nil
end

-- ¿Es equipo (se puede mejorar)?
function Crafting.isEquip(id: string): boolean
	local g = gearById[id]
	return g ~= nil and Crafting.slotOf(g) ~= nil
end

function Crafting.refineOf(refine: { [string]: any }?, id: string): number
	local n = refine and tonumber(refine[id]) or 0
	return math.clamp(math.floor(n), 0, Crafting.MaxRefine)
end

-- Lo que da un objeto con su mejora: { Blade, Defense, Luck, Vigor }
function Crafting.gearStats(id: string, level: number?): { [string]: number }
	local g = gearById[id]
	local k = 1 + Crafting.RefineBonus * (level or 0)
	return {
		Blade = (g and g.Blade or 0) * k,
		Defense = (g and g.Defense or 0) * k,
		Luck = (g and g.Luck or 0) * k,
		Vigor = math.floor((g and g.Vigor or 0) * k + 0.5),
	}
end

local function power(st: { [string]: number }): number
	return st.Blade + st.Defense * 2 + st.Luck + st.Vigor / 100
end

-- Todo lo que llevas puesto: el mejor objeto de cada hueco (con su mejora), sumado.
-- → { Blade, Defense, Luck, Vigor, Worn = { [hueco] = id } }
function Crafting.stats(items: { [string]: number }?, refine: { [string]: any }?): { [string]: any }
	local best: { [string]: { Id: string, St: { [string]: number }, P: number } } = {}
	for id, n in items or {} do
		local g = gearById[id]
		local slot = g and Crafting.slotOf(g)
		if g and slot and type(n) == "number" and n > 0 then
			local st = Crafting.gearStats(id, Crafting.refineOf(refine, id))
			local p = power(st)
			local cur = best[slot]
			if not cur or p > cur.P or (p == cur.P and id < cur.Id) then
				best[slot] = { Id = id, St = st, P = p }
			end
		end
	end
	local out: { [string]: any } = { Blade = 0, Defense = 0, Luck = 0, Vigor = 0, Worn = {} }
	for slot, b in best do
		out.Blade += b.St.Blade
		out.Defense += b.St.Defense
		out.Luck += b.St.Luck
		out.Vigor += b.St.Vigor
		out.Worn[slot] = b.Id
	end
	out.Defense = math.min(out.Defense, Crafting.MaxDefense)
	return out
end

function Crafting.defenseOf(items: { [string]: number }?, refine: { [string]: any }?): number
	return Crafting.stats(items, refine).Defense
end
function Crafting.bladeOf(items: { [string]: number }?, refine: { [string]: any }?): number
	return Crafting.stats(items, refine).Blade
end

-- Los pasos de mejora: para llegar a +i hace falta esto. Chance: probabilidad de que salga bien.
-- Si falla, se pierden las piedras y el dinero; a partir de +5 el objeto además BAJA un nivel, salvo que lleves
-- un Sello del herrero (se gasta él). Nunca se rompe el objeto.
Crafting.RefineSteps = {
	{ Chance = 1.0, Money = 200, Stone = "PiedraPulir", Stones = 1 },
	{ Chance = 0.95, Money = 400, Stone = "PiedraPulir", Stones = 1 },
	{ Chance = 0.9, Money = 700, Stone = "PiedraPulir", Stones = 2 },
	{ Chance = 0.8, Money = 1200, Stone = "PiedraPulir", Stones = 3 },
	{ Chance = 0.7, Money = 2000, Stone = "PiedraTemple", Stones = 1 },
	{ Chance = 0.6, Money = 3200, Stone = "PiedraTemple", Stones = 1 },
	{ Chance = 0.5, Money = 5000, Stone = "PiedraTemple", Stones = 2 },
	{ Chance = 0.4, Money = 8000, Stone = "PiedraTemple", Stones = 2 },
	{ Chance = 0.3, Money = 12000, Stone = "PiedraTemple", Stones = 3 },
}
Crafting.RefineDropFrom = 5 -- intentar +5 o más: si falla, baja uno

-- El paso para subir desde `level` (nil si ya está al máximo)
function Crafting.refineStep(level: number): { [string]: any }?
	return Crafting.RefineSteps[level + 1]
end

-- El resultado de un intento. roll: 0..1. → (nivel nuevo, "Ok" | "Fail" | "Saved" | "Drop")
function Crafting.refineRoll(level: number, roll: number, hasSeal: boolean): (number, string)
	local step = Crafting.refineStep(level)
	if not step then
		return level, "Fail"
	end
	if roll < step.Chance then
		return level + 1, "Ok"
	end
	if level + 1 >= Crafting.RefineDropFrom then
		if hasSeal then
			return level, "Saved"
		end
		return math.max(0, level - 1), "Drop"
	end
	return level, "Fail"
end

-- El nombre con su mejora: «Lanza de escama +3»
function Crafting.refinedName(name: string, level: number): string
	return if level > 0 then ("%s +%d"):format(name, level) else name
end

---------------------------------------------------------------------
-- NIVEL DE CAZADOR: experiencia por cada bestia. Cada nivel, +2 % a tus golpes contra las bestias.
---------------------------------------------------------------------
Crafting.MaxHunter = 60
Crafting.HunterDamage = 0.02

function Crafting.killXp(hp: number, boss: boolean?): number
	return math.max(1, math.floor(hp / 8 + 0.5)) * (if boss then 2 else 1)
end
-- La experiencia que hace falta para ESTAR en un nivel
function Crafting.hunterNeed(level: number): number
	return 50 * (level - 1) ^ 2
end
function Crafting.hunterLevel(xp: number?): number
	local x = math.max(0, tonumber(xp) or 0)
	return math.clamp(math.floor(math.sqrt(x / 50)) + 1, 1, Crafting.MaxHunter)
end
function Crafting.hunterBonus(xp: number?): number
	return (Crafting.hunterLevel(xp) - 1) * Crafting.HunterDamage
end

-- El daño que te llega de una bestia (armadura + piel de piedra, nunca menos del 25 %)
function Crafting.damageTaken(amount: number, defense: number, stone: number?): number
	local k = math.clamp(1 - defense - (stone or 0), 0.25, 1)
	return math.max(1, math.floor(amount * k + 0.5))
end

return Crafting
