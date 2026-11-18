-- Bestiary: las BESTIAS de los planetas, sus GUARIDAS, los JEFES escondidos y los ALIJOS que hay por ahí.
-- Cuentas puras y repetibles: lo usan Services/BeastService (las saca, las mueve, reparte el botín),
-- World/Kit/BeastKit (cómo son y cómo son sus guaridas), shared/Crafting (lo que sueltan sirve para
-- fabricar) y las pruebas (scripts/test-bestias.luau).
--
--   * Cada planeta tiene tres bestias propias y un jefe escondido. Las guaridas están fuera de la ciudad
--     (en el monte, las dunas, los islotes, los picos que salen de la niebla…); el jefe, en la más lejana.
--   * Lo que sueltan: materiales comunes (cuero, colmillo, quitina, escama, glándula, hueso, seda), el
--     material raro del planeta y, el jefe, su trofeo. Todo va a la mochila y se usa en el Taller.
--   * Alijos: cajas escondidas con materiales; cada uno se abre una vez al día por jugador.
-- Tono (regla del dueño): bestias de verdad, para 13-15 años; sin sangre (caen y se deshacen en polvo).

local Bestiary = {}

local rgb = Color3.fromRGB

local function rng(seed: number): () -> number
	local s = math.floor(seed) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end
Bestiary.rng = rng

-- Cuerpos (World/Kit/BeastKit los dibuja): Cuadrupedo, Insecto (seis patas), Serpiente, Bipedo, Masa (slime).
-- Look = aspecto propio (World/Kit/BeastLooks: Oso, Cocodrilo, Dragon, Arana, Bandido, Minotauro, Mago, Momia,
-- Esqueleto, Caballero, Demonio, Gigante, Elemental); Weapon = lo que lleva en la mano; Shield = escudo.
-- Drops = { { Item, Min, Max, Chance } }
Bestiary.Species = {
	-- TEFRA
	Rondador = { Planet = "Tefra", Name = "Rondador de ceniza", Icon = "🐺", Body = "Cuadrupedo", Size = 5, Hp = 160, Damage = 12, Speed = 20, Aggro = 70,
		Colors = { Body = rgb(58, 52, 50), Belly = rgb(96, 86, 80), Glow = rgb(255, 110, 40) }, Material = "Slate",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 } }, Money = 15 },
	EscarabajoLava = { Planet = "Tefra", Name = "Escarabajo de lava", Icon = "🐞", Body = "Insecto", Size = 3.6, Hp = 110, Damage = 9, Speed = 16, Aggro = 55,
		Colors = { Body = rgb(40, 34, 32), Belly = rgb(120, 40, 20), Glow = rgb(255, 140, 40) }, Material = "Basalt",
		Drops = { { "Quitina", 1, 2, 1 }, { "Glandula", 1, 1, 0.35 } }, Money = 10 },
	GusanoColada = { Planet = "Tefra", Name = "Gusano de colada", Icon = "🐉", Body = "Serpiente", Size = 4.5, Hp = 230, Damage = 16, Speed = 14, Aggro = 60,
		Colors = { Body = rgb(70, 40, 30), Belly = rgb(150, 70, 30), Glow = rgb(255, 120, 30) }, Material = "Basalt",
		Drops = { { "Escama", 1, 2, 1 }, { "BrasaViva", 1, 1, 0.3 } }, Money = 20 },
	BestiaBrasa = { Planet = "Tefra", Boss = true, Name = "La Bestia de Brasa", Icon = "🔥", Body = "Cuadrupedo", Size = 18, Hp = 3200, Damage = 30, Speed = 15, Aggro = 110,
		Colors = { Body = rgb(40, 30, 28), Belly = rgb(110, 50, 30), Glow = rgb(255, 90, 20) }, Material = "Basalt",
		Drops = { { "NucleoBrasa", 1, 1, 1 }, { "BrasaViva", 2, 4, 1 }, { "Colmillo", 2, 3, 1 } }, Money = 900,
		Lore = "Dicen que nació en la Caldera Roja el día del primer bombardeo. Los soldados de la Muralla no salen de noche por ella." },

	-- SIROCO
	ChacalDuna = { Planet = "Siroco", Name = "Chacal de duna", Icon = "🐺", Body = "Cuadrupedo", Size = 4.2, Hp = 120, Damage = 10, Speed = 24, Aggro = 75,
		Colors = { Body = rgb(196, 150, 96), Belly = rgb(230, 200, 150), Glow = rgb(255, 210, 120) }, Material = "Sand",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.45 } }, Money = 12 },
	EscorpionSal = { Planet = "Siroco", Name = "Escorpión de sal", Icon = "🦂", Body = "Insecto", Size = 4, Hp = 150, Damage = 14, Speed = 15, Aggro = 50,
		Colors = { Body = rgb(230, 226, 214), Belly = rgb(190, 180, 160), Glow = rgb(120, 220, 255) }, Material = "Salt",
		Drops = { { "Quitina", 1, 2, 1 }, { "Glandula", 1, 1, 0.5 } }, Money = 14 },
	SerpienteArena = { Planet = "Siroco", Name = "Serpiente de arena", Icon = "🐍", Body = "Serpiente", Size = 4, Hp = 190, Damage = 15, Speed = 18, Aggro = 65,
		Colors = { Body = rgb(184, 128, 80), Belly = rgb(222, 180, 120), Glow = rgb(255, 160, 60) }, Material = "Sandstone",
		Drops = { { "Escama", 1, 2, 1 }, { "VidrioTormenta", 1, 1, 0.3 } }, Money = 18 },
	ReyEscorpion = { Planet = "Siroco", Boss = true, Name = "El Rey Escorpión de la Hora Roja", Icon = "🦂", Body = "Insecto", Size = 16, Hp = 3000, Damage = 28, Speed = 14, Aggro = 110,
		Colors = { Body = rgb(150, 40, 30), Belly = rgb(220, 120, 70), Glow = rgb(255, 80, 40) }, Material = "Sandstone",
		Drops = { { "AguijonRey", 1, 1, 1 }, { "VidrioTormenta", 2, 4, 1 }, { "Quitina", 3, 5, 1 } }, Money = 900,
		Lore = "Solo sale cuando el sol se pone rojo. Los pilotos de La Recta lo usan para asustar a los novatos. No es un cuento." },

	-- TÁLASA
	CangrejoNacar = { Planet = "Talasa", Name = "Cangrejo de nácar", Icon = "🦀", Body = "Insecto", Size = 3.8, Hp = 140, Damage = 11, Speed = 14, Aggro = 50,
		Colors = { Body = rgb(230, 220, 236), Belly = rgb(190, 170, 200), Glow = rgb(140, 230, 255) }, Material = "Glass",
		Drops = { { "Quitina", 1, 2, 1 }, { "NacarAbisal", 1, 1, 0.3 } }, Money = 14 },
	AnguilaArrecife = { Planet = "Talasa", Name = "Anguila de arrecife", Icon = "🐍", Body = "Serpiente", Size = 3.6, Hp = 150, Damage = 13, Speed = 20, Aggro = 60,
		Colors = { Body = rgb(40, 90, 110), Belly = rgb(120, 200, 200), Glow = rgb(80, 255, 220) }, Material = "SmoothPlastic",
		Drops = { { "Escama", 1, 2, 1 }, { "Glandula", 1, 1, 0.45 } }, Money = 14 },
	FocaColmillo = { Planet = "Talasa", Name = "Foca colmilluda", Icon = "🐾", Body = "Cuadrupedo", Size = 4.6, Hp = 200, Damage = 14, Speed = 13, Aggro = 50,
		Colors = { Body = rgb(90, 100, 110), Belly = rgb(170, 180, 186), Glow = rgb(120, 220, 255) }, Material = "SmoothPlastic",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 2, 0.6 } }, Money = 16 },
	Leviatan = { Planet = "Talasa", Boss = true, Name = "El hijo del Leviatán", Icon = "🐋", Body = "Serpiente", Size = 15, Hp = 3200, Damage = 30, Speed = 14, Aggro = 100,
		Colors = { Body = rgb(30, 50, 70), Belly = rgb(90, 150, 170), Glow = rgb(60, 255, 230) }, Material = "SmoothPlastic",
		Drops = { { "PerlaLeviatan", 1, 1, 1 }, { "NacarAbisal", 2, 4, 1 }, { "Escama", 3, 5, 1 } }, Money = 900,
		Lore = "Los buzos dicen que el Leviatán tuvo crías. Una se quedó varada en un islote y ya no cabe en el agua." },

	-- NIVALIS
	LoboEscarcha = { Planet = "Nivalis", Name = "Lobo de escarcha", Icon = "🐺", Body = "Cuadrupedo", Size = 4.6, Hp = 150, Damage = 12, Speed = 23, Aggro = 80,
		Colors = { Body = rgb(220, 228, 240), Belly = rgb(170, 180, 196), Glow = rgb(140, 200, 255) }, Material = "Snow",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 } }, Money = 14 },
	AranaHielo = { Planet = "Nivalis", Name = "Araña de hielo", Icon = "🕷", Body = "Insecto", Size = 3.8, Hp = 120, Damage = 12, Speed = 18, Aggro = 55,
		Colors = { Body = rgb(150, 200, 230), Belly = rgb(90, 130, 170), Glow = rgb(170, 240, 255) }, Material = "Ice",
		Drops = { { "Seda", 1, 2, 1 }, { "Glandula", 1, 1, 0.4 } }, Money = 12 },
	OsoLanudo = { Planet = "Nivalis", Name = "Oso lanudo", Icon = "🐻", Body = "Cuadrupedo", Size = 7, Hp = 320, Damage = 20, Speed = 14, Aggro = 50,
		Colors = { Body = rgb(130, 110, 96), Belly = rgb(200, 186, 170), Glow = rgb(255, 210, 160) }, Material = "Fabric",
		Drops = { { "Cuero", 2, 3, 1 }, { "Hueso", 1, 2, 0.7 }, { "HieloEterno", 1, 1, 0.3 } }, Money = 24 },
	Durmiente = { Planet = "Nivalis", Boss = true, Name = "Lo que duerme en el hielo", Icon = "🐉", Body = "Serpiente", Size = 16, Hp = 3400, Damage = 30, Speed = 13, Aggro = 100,
		Colors = { Body = rgb(170, 210, 240), Belly = rgb(230, 244, 255), Glow = rgb(90, 200, 255) }, Material = "Ice",
		Drops = { { "CorazonHielo", 1, 1, 1 }, { "HieloEterno", 2, 4, 1 }, { "Hueso", 2, 4, 1 } }, Money = 900,
		Lore = "El Regente prohibió las canciones que hablaban de él. Las cantan igual, en voz baja, cerca del Glaciar Azul." },

	-- UMBRÍA
	PanteraLiana = { Planet = "Umbria", Name = "Pantera de liana", Icon = "🐆", Body = "Cuadrupedo", Size = 4.8, Hp = 160, Damage = 14, Speed = 25, Aggro = 70,
		Colors = { Body = rgb(40, 60, 40), Belly = rgb(90, 120, 70), Glow = rgb(170, 255, 120) }, Material = "Grass",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 } }, Money = 15 },
	AvispaEnjambre = { Planet = "Umbria", Name = "Avispa del Enjambre", Icon = "🐝", Body = "Insecto", Size = 3.4, Hp = 90, Damage = 10, Speed = 22, Aggro = 70,
		Colors = { Body = rgb(60, 60, 64), Belly = rgb(230, 190, 40), Glow = rgb(255, 230, 80) }, Material = "Metal",
		Drops = { { "Seda", 1, 2, 1 }, { "Glandula", 1, 1, 0.45 } }, Money = 10 },
	EscarabajoCorteza = { Planet = "Umbria", Name = "Escarabajo de corteza", Icon = "🐞", Body = "Insecto", Size = 4.2, Hp = 190, Damage = 13, Speed = 13, Aggro = 45,
		Colors = { Body = rgb(90, 64, 40), Belly = rgb(60, 90, 40), Glow = rgb(200, 255, 140) }, Material = "Wood",
		Drops = { { "Quitina", 1, 2, 1 }, { "SaviaAmbar", 1, 1, 0.3 } }, Money = 16 },
	GranEscarabajo = { Planet = "Umbria", Boss = true, Name = "El Gran Escarabajo", Icon = "🐞", Body = "Insecto", Size = 17, Hp = 3200, Damage = 28, Speed = 13, Aggro = 100,
		Colors = { Body = rgb(40, 70, 50), Belly = rgb(120, 150, 70), Glow = rgb(180, 255, 100) }, Material = "Wood",
		Drops = { { "CuernoEscarabajo", 1, 1, 1 }, { "SaviaAmbar", 2, 4, 1 }, { "Quitina", 3, 5, 1 } }, Money = 900,
		Lore = "Más viejo que Raíz Honda. Las máquinas del Enjambre lo esquivan. Eso debería decirte algo." },

	-- MIASMA (en los picos que salen de la niebla)
	RataChatarra = { Planet = "Miasma", Name = "Rata de chatarra", Icon = "🐀", Body = "Cuadrupedo", Size = 3.4, Hp = 100, Damage = 9, Speed = 22, Aggro = 60,
		Colors = { Body = rgb(110, 100, 90), Belly = rgb(150, 140, 120), Glow = rgb(200, 255, 120) }, Material = "CorrodedMetal",
		Drops = { { "Cuero", 1, 1, 1 }, { "Hueso", 1, 1, 0.5 } }, Money = 10 },
	MedusaGas = { Planet = "Miasma", Name = "Medusa de gas", Icon = "🎐", Body = "Insecto", Size = 4, Hp = 130, Damage = 12, Speed = 12, Aggro = 55,
		Colors = { Body = rgb(170, 200, 120), Belly = rgb(120, 160, 90), Glow = rgb(200, 255, 110) }, Material = "Glass",
		Drops = { { "Glandula", 1, 2, 1 }, { "Seda", 1, 1, 0.4 } }, Money = 12 },
	BuitreRayo = { Planet = "Miasma", Name = "Buitre de rayo", Icon = "🦅", Body = "Bipedo", Size = 5.5, Hp = 170, Damage = 15, Speed = 20, Aggro = 75,
		Colors = { Body = rgb(60, 60, 70), Belly = rgb(130, 130, 150), Glow = rgb(180, 220, 255) }, Material = "Slate",
		Drops = { { "Hueso", 1, 2, 1 }, { "PlataRayo", 1, 1, 0.3 } }, Money = 18 },
	Silbador = { Planet = "Miasma", Boss = true, Name = "El Silbador", Icon = "🌪", Body = "Bipedo", Size = 17, Hp = 3200, Damage = 30, Speed = 13, Aggro = 110,
		Colors = { Body = rgb(70, 80, 70), Belly = rgb(140, 160, 130), Glow = rgb(200, 255, 100) }, Material = "CorrodedMetal",
		Drops = { { "OjoTormenta", 1, 1, 1 }, { "PlataRayo", 2, 4, 1 }, { "Hueso", 2, 4, 1 } }, Money = 900,
		Lore = "El silbido de la Torre no es el viento. Es él respirando. Los del Anclaje Seis lo sabían." },

	-- VÉRTICE (en los Aliviaderos y el Vertedero)
	RataCloaca = { Planet = "Vertice", Name = "Rata de cloaca", Icon = "🐀", Body = "Cuadrupedo", Size = 3.6, Hp = 110, Damage = 10, Speed = 22, Aggro = 60,
		Colors = { Body = rgb(70, 66, 64), Belly = rgb(120, 110, 104), Glow = rgb(255, 60, 180) }, Material = "Slate",
		Drops = { { "Cuero", 1, 2, 1 }, { "Hueso", 1, 1, 0.5 } }, Money = 12 },
	DronRebelde = { Planet = "Vertice", Name = "Dron rebelde", Icon = "🤖", Body = "Insecto", Size = 3.8, Hp = 140, Damage = 13, Speed = 18, Aggro = 70,
		Colors = { Body = rgb(50, 54, 64), Belly = rgb(90, 96, 110), Glow = rgb(40, 220, 255) }, Material = "Metal",
		Drops = { { "ChipUsado", 1, 1, 0.45 }, { "Quitina", 1, 2, 1 } }, Money = 16 },
	CocodriloAliviadero = { Planet = "Vertice", Name = "Cocodrilo de aliviadero", Icon = "🐊", Body = "Cuadrupedo", Size = 4.4, Hp = 240, Damage = 17, Speed = 14, Aggro = 50,
		Colors = { Body = rgb(60, 80, 56), Belly = rgb(140, 150, 110), Glow = rgb(255, 200, 40) }, Material = "Slate",
		Drops = { { "Escama", 1, 2, 1 }, { "Colmillo", 1, 1, 0.6 } }, Money = 20 },
	Recaudador = { Planet = "Vertice", Boss = true, Name = "El Recaudador", Icon = "🦾", Body = "Bipedo", Size = 16, Hp = 3200, Damage = 30, Speed = 14, Aggro = 110,
		Colors = { Body = rgb(40, 40, 48), Belly = rgb(120, 120, 130), Glow = rgb(255, 40, 60) }, Material = "Metal",
		Drops = { { "PlacaRecaudador", 1, 1, 1 }, { "ChipUsado", 2, 4, 1 }, { "Escama", 2, 3, 1 } }, Money = 900,
		Lore = "Una máquina de cobro que alguien soltó en el Vertedero cuando quebró el banco. Sigue cobrando. A todo el mundo." },

	-- VALMAR (las sierras y el campo de la isla, lejos de los barrios: World/ValmarWilds). Animales de
	-- aquí que la luz de la Grieta ha cambiado: más grandes, más listos y con vetas que brillan.
	JabaliSierra = { Planet = "Valmar", Name = "Jabalí de la sierra", Icon = "🐗", Body = "Cuadrupedo", Size = 4.6, Hp = 150, Damage = 11, Speed = 20, Aggro = 60,
		Colors = { Body = rgb(74, 58, 46), Belly = rgb(120, 98, 78), Glow = rgb(170, 120, 255) }, Material = "Slate",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.6 } }, Money = 14 },
	AvispaGrieta = { Planet = "Valmar", Name = "Avispón de la Grieta", Icon = "🐝", Body = "Insecto", Size = 3.4, Hp = 100, Damage = 9, Speed = 18, Aggro = 65,
		Colors = { Body = rgb(52, 44, 30), Belly = rgb(200, 160, 40), Glow = rgb(190, 140, 255) }, Material = "Metal",
		Drops = { { "Quitina", 1, 2, 1 }, { "Seda", 1, 1, 0.5 } }, Money = 11 },
	VivoraPenasco = { Planet = "Valmar", Name = "Víbora del peñasco", Icon = "🐍", Body = "Serpiente", Size = 4.2, Hp = 210, Damage = 15, Speed = 14, Aggro = 55,
		Colors = { Body = rgb(86, 90, 70), Belly = rgb(150, 150, 120), Glow = rgb(160, 110, 255) }, Material = "Slate",
		Drops = { { "Escama", 1, 2, 1 }, { "Glandula", 1, 1, 0.45 } }, Money = 18 },
	CiervoRoto = { Planet = "Valmar", Boss = true, Name = "El Ciervo Roto", Icon = "🦌", Body = "Cuadrupedo", Size = 15, Hp = 3000, Damage = 28, Speed = 16, Aggro = 110,
		Colors = { Body = rgb(60, 50, 44), Belly = rgb(140, 120, 100), Glow = rgb(170, 110, 255) }, Material = "Slate",
		Drops = { { "AstaGrieta", 1, 1, 1 }, { "CuarzoGrieta", 2, 4, 1 }, { "Cuero", 2, 3, 1 } }, Money = 900,
		Lore = "Bebió del agua donde cayó el primer trozo de la Grieta. Desde entonces sus astas crecen hacia dentro, como cristal." },

	-- LAS OCHO REGIONES DE VALMAR (shared/Cosmos/ValmarRegions): tres criaturas y un jefe en cada una. Arms = de
	-- pie con brazos y visor (guardianes, caballeros, gólems), no con alas. La vida y el daño de aquí son los
	-- de nivel 5: cada guarida los multiplica por su nivel (Bestiary.levelScale). Los jefes llevan los suyos.
	-- Bosque Etéreo (nv. 10-30)
	LoboBosque = { Planet = "Valmar", Region = "BosqueEtereo", Name = "Lobo salvaje", Icon = "🐺", Body = "Cuadrupedo", Size = 4.6, Hp = 130, Damage = 10, Speed = 22, Aggro = 70,
		Colors = { Body = rgb(92, 84, 74), Belly = rgb(150, 140, 120), Glow = rgb(140, 255, 170) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 }, { "MaderaEterea", 1, 1, 0.2 } }, Money = 12 },
	AranaBosque = { Planet = "Valmar", Region = "BosqueEtereo", Name = "Araña gigante", Icon = "🕷", Body = "Insecto", Look = "Arana", Size = 4.2, Hp = 115, Damage = 11, Speed = 18, Aggro = 60,
		Colors = { Body = rgb(34, 30, 40), Belly = rgb(70, 50, 80), Glow = rgb(255, 70, 70) }, Material = "Slate",
		Drops = { { "Seda", 1, 2, 1 }, { "Glandula", 1, 1, 0.45 }, { "MaderaEterea", 1, 1, 0.2 } }, Money = 12 },
	OsoGigante = { Planet = "Valmar", Region = "BosqueEtereo", Name = "Oso gris", Icon = "🐻", Body = "Cuadrupedo", Look = "Oso", Size = 6.2, Hp = 230, Damage = 15, Speed = 15, Aggro = 55,
		Colors = { Body = rgb(96, 66, 44), Belly = rgb(150, 116, 84), Glow = rgb(255, 190, 90) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 3, 1 }, { "Colmillo", 1, 1, 0.5 }, { "MaderaEterea", 1, 1, 0.3 } }, Money = 18 },
	EspirituBosque = { Planet = "Valmar", Region = "BosqueEtereo", Name = "Espíritu del bosque", Icon = "👻", Body = "Bipedo", Flies = true, Size = 4.6, Hp = 140, Damage = 13, Speed = 16, Aggro = 65,
		Colors = { Body = rgb(90, 230, 200), Belly = rgb(40, 140, 110), Glow = rgb(140, 255, 220) }, Material = "Glass",
		Drops = { { "Glandula", 1, 2, 1 }, { "MaderaEterea", 1, 1, 0.3 } }, Money = 16 },
	BandidoBosque = { Planet = "Valmar", Region = "BosqueEtereo", Name = "Bandido del bosque", Icon = "🗡", Body = "Bipedo", Size = 4.4, Hp = 150, Damage = 13, Speed = 17, Aggro = 70,
		Colors = { Body = rgb(60, 80, 46), Belly = rgb(80, 60, 40), Skin = rgb(214, 170, 130), Glow = rgb(255, 160, 80) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 2, 1 }, { "Hueso", 1, 1, 0.4 }, { "MaderaEterea", 1, 1, 0.25 } }, Money = 18 },
	GuardianMadera = { Planet = "Valmar", Region = "BosqueEtereo", Name = "Guardián de madera", Icon = "🌳", Body = "Bipedo", Arms = true, Size = 5.5, Hp = 210, Damage = 14, Speed = 12, Aggro = 50,
		Colors = { Body = rgb(96, 70, 44), Belly = rgb(70, 110, 50), Glow = rgb(150, 255, 160) }, Material = "Wood",
		Drops = { { "Hueso", 1, 2, 1 }, { "MaderaEterea", 1, 1, 0.35 } }, Money = 16 },
	GuardianAncestral = { Planet = "Valmar", Region = "BosqueEtereo", Boss = true, Arms = true, Name = "El Guardián Ancestral", Icon = "🌳", Body = "Bipedo", Size = 18, Hp = 4000, Damage = 26, Speed = 12, Aggro = 110,
		Colors = { Body = rgb(80, 60, 40), Belly = rgb(60, 120, 50), Glow = rgb(120, 255, 140) }, Material = "Wood",
		Drops = { { "CoronaAncestral", 1, 1, 1 }, { "MaderaEterea", 2, 4, 1 }, { "Hueso", 2, 3, 1 } }, Money = 1000,
		Lore = "El primer árbol que tocó la luz de la Grieta. Se levantó, y desde entonces no deja que nadie tale el bosque." },
	-- Llanuras Salvajes (nv. 20-40; con el jabalí de la sierra)
	AcechadorPradera = { Planet = "Valmar", Region = "LlanurasSalvajes", Name = "Tigre salvaje", Icon = "🐅", Body = "Cuadrupedo", Size = 4.8, Hp = 150, Damage = 13, Speed = 25, Aggro = 75,
		Colors = { Body = rgb(190, 160, 90), Belly = rgb(230, 210, 160), Glow = rgb(255, 220, 110) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 }, { "CrinSalvaje", 1, 1, 0.2 } }, Money = 14 },
	BestiaSalvaje = { Planet = "Valmar", Region = "LlanurasSalvajes", Name = "Bestia salvaje", Icon = "🐃", Body = "Cuadrupedo", Size = 5.6, Hp = 230, Damage = 16, Speed = 17, Aggro = 60,
		Colors = { Body = rgb(96, 64, 44), Belly = rgb(140, 104, 74), Glow = rgb(255, 120, 60) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 3, 1 }, { "Colmillo", 1, 1, 0.5 }, { "CrinSalvaje", 1, 1, 0.3 } }, Money = 22 },
	Depredador = { Planet = "Valmar", Region = "LlanurasSalvajes", Name = "Depredador", Icon = "🦍", Body = "Bipedo", Arms = true, Size = 6, Hp = 250, Damage = 17, Speed = 16, Aggro = 70,
		Colors = { Body = rgb(48, 44, 46), Belly = rgb(84, 74, 70), Glow = rgb(255, 60, 40) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 2, 0.5 }, { "CrinSalvaje", 1, 1, 0.35 } }, Money = 24 },
	GuerreroNomada = { Planet = "Valmar", Region = "LlanurasSalvajes", Name = "Guerrero nómada", Icon = "🗡", Body = "Bipedo", Size = 4.6, Hp = 190, Damage = 15, Speed = 17, Aggro = 70,
		Colors = { Body = rgb(150, 110, 70), Belly = rgb(90, 60, 40), Skin = rgb(176, 124, 86), Glow = rgb(255, 160, 80) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 2, 1 }, { "Hueso", 1, 1, 0.4 }, { "CrinSalvaje", 1, 1, 0.3 } }, Money = 22 },
	SaqueadorNomada = { Planet = "Valmar", Region = "LlanurasSalvajes", Name = "Bandido", Icon = "🗡", Body = "Bipedo", Look = "Bandido", Weapon = "Espada", Size = 4.4, Hp = 170, Damage = 14, Speed = 17, Aggro = 70,
		Colors = { Body = rgb(96, 64, 44), Belly = rgb(70, 60, 54), Skin = rgb(214, 170, 130), Glow = rgb(255, 120, 60) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 1, 1 }, { "Hueso", 1, 1, 0.4 }, { "CrinSalvaje", 1, 1, 0.3 } }, Money = 20 },
	Minotauro = { Planet = "Valmar", Region = "LlanurasSalvajes", Name = "Minotauro", Icon = "🐂", Body = "Bipedo", Arms = true, Look = "Minotauro", Weapon = "Hacha", Size = 6.4, Hp = 260, Damage = 17, Speed = 15, Aggro = 60,
		Colors = { Body = rgb(110, 70, 46), Belly = rgb(74, 52, 40), Glow = rgb(255, 80, 50) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 2, 1 }, { "Hueso", 1, 2, 0.6 }, { "CrinSalvaje", 1, 1, 0.35 } }, Money = 24 },
	ReyLlanuras = { Planet = "Valmar", Region = "LlanurasSalvajes", Boss = true, Arms = true, Charges = true, Name = "El Rey de las Llanuras", Icon = "🦁", Body = "Bipedo", Size = 17, Hp = 6000, Damage = 32, Speed = 19, Aggro = 120,
		Colors = { Body = rgb(150, 110, 60), Belly = rgb(220, 190, 130), Glow = rgb(255, 200, 80) }, Material = "Fabric",
		Drops = { { "CrinRey", 1, 1, 1 }, { "CrinSalvaje", 2, 4, 1 }, { "Cuero", 3, 5, 1 } }, Money = 1300,
		Lore = "Una manada entera sigue a una sola bestia. Los nómadas le pagan con comida para cruzar sus praderas." },
	-- Pantano Maldito (nv. 40-60; con el avispón de la Grieta)
	CocodriloMutado = { Planet = "Valmar", Region = "PantanoMaldito", Name = "Cocodrilo", Icon = "🐊", Body = "Cuadrupedo", Look = "Cocodrilo", Size = 5, Hp = 240, Damage = 17, Speed = 14, Aggro = 50,
		Colors = { Body = rgb(56, 80, 50), Belly = rgb(130, 150, 100), Glow = rgb(170, 255, 90) }, Material = "Slate",
		Drops = { { "Escama", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 }, { "LodoMaldito", 1, 1, 0.2 } }, Money = 20 },
	InsectoGigante = { Planet = "Valmar", Region = "PantanoMaldito", Name = "Insecto gigante", Icon = "🦗", Body = "Insecto", Size = 4.6, Hp = 190, Damage = 15, Speed = 18, Aggro = 60,
		Colors = { Body = rgb(70, 120, 50), Belly = rgb(120, 170, 70), Glow = rgb(200, 255, 80) }, Material = "Slate",
		Drops = { { "Quitina", 1, 2, 1 }, { "Glandula", 1, 1, 0.4 }, { "LodoMaldito", 1, 1, 0.25 } }, Money = 20 },
	CriaturaVenenosa = { Planet = "Valmar", Region = "PantanoMaldito", Name = "Criatura venenosa", Icon = "☠", Body = "Cuadrupedo", Size = 5, Hp = 210, Damage = 16, Speed = 20, Aggro = 65,
		Colors = { Body = rgb(90, 40, 100), Belly = rgb(140, 80, 150), Glow = rgb(170, 255, 80) }, Material = "Slate",
		Drops = { { "Escama", 1, 2, 1 }, { "Glandula", 1, 1, 0.5 }, { "LodoMaldito", 1, 1, 0.3 } }, Money = 22 },
	MuertoViviente = { Planet = "Valmar", Region = "PantanoMaldito", Name = "Muerto viviente", Icon = "🧟", Body = "Bipedo", Size = 4.8, Hp = 220, Damage = 15, Speed = 11, Aggro = 60,
		Colors = { Body = rgb(110, 130, 100), Belly = rgb(70, 60, 50), Skin = rgb(130, 150, 110), Glow = rgb(170, 255, 120) }, Material = "Fabric",
		Drops = { { "Hueso", 1, 2, 1 }, { "Glandula", 1, 1, 0.3 }, { "LodoMaldito", 1, 1, 0.3 } }, Money = 20 },
	SlimeToxico = { Planet = "Valmar", Region = "PantanoMaldito", Name = "Slime tóxico", Icon = "🧪", Body = "Masa", Size = 5.2, Hp = 180, Damage = 13, Speed = 12, Aggro = 50,
		Colors = { Body = rgb(90, 210, 70), Belly = rgb(50, 140, 50), Glow = rgb(200, 255, 90) }, Material = "Glass",
		Drops = { { "Glandula", 1, 2, 1 }, { "LodoMaldito", 1, 1, 0.3 } }, Money = 16 },
	Nigromante = { Planet = "Valmar", Region = "PantanoMaldito", Name = "Nigromante", Icon = "💀", Body = "Bipedo", Look = "Mago", Skull = true, Weapon = "Baston", Size = 4.8, Hp = 160, Damage = 16, Speed = 14, Aggro = 75,
		Colors = { Body = rgb(40, 58, 48), Belly = rgb(24, 32, 28), Skin = rgb(190, 200, 180), Glow = rgb(120, 255, 150) }, Material = "Fabric",
		Drops = { { "Hueso", 1, 2, 1 }, { "Glandula", 1, 1, 0.4 }, { "LodoMaldito", 1, 1, 0.3 } }, Money = 22 },
	EspirituCorrupto = { Planet = "Valmar", Region = "PantanoMaldito", Name = "Espíritu maldito", Icon = "👻", Body = "Bipedo", Flies = true, Size = 4.6, Hp = 150, Damage = 15, Speed = 16, Aggro = 70,
		Colors = { Body = rgb(70, 90, 80), Belly = rgb(120, 160, 140), Glow = rgb(120, 255, 200) }, Material = "Glass",
		Drops = { { "Glandula", 1, 2, 1 }, { "LodoMaldito", 1, 1, 0.3 } }, Money = 18 },
	DevoradorPantano = { Planet = "Valmar", Region = "PantanoMaldito", Boss = true, Arms = true, Breath = true, Name = "El Devorador del Pantano", Icon = "👹", Body = "Bipedo", Size = 17, Hp = 11000, Damage = 45, Speed = 14, Aggro = 110,
		Colors = { Body = rgb(40, 60, 40), Belly = rgb(110, 130, 80), Glow = rgb(160, 255, 80) }, Material = "Slate",
		Drops = { { "ColmilloDevorador", 1, 1, 1 }, { "LodoMaldito", 2, 4, 1 }, { "Escama", 3, 5, 1 } }, Money = 1900,
		Lore = "Se tragó el bidón que tiraron desde el laboratorio de Cosme. Creció. Sigue teniendo hambre." },
	-- Desierto Devastado (nv. 50-70; con la víbora del peñasco)
	EscorpionGigante = { Planet = "Valmar", Region = "DesiertoDorado", Name = "Escorpión gigante", Icon = "🦂", Body = "Insecto", Size = 4.4, Hp = 170, Damage = 15, Speed = 15, Aggro = 55,
		Colors = { Body = rgb(170, 120, 60), Belly = rgb(220, 180, 110), Glow = rgb(255, 210, 90) }, Material = "Sandstone",
		Drops = { { "Quitina", 1, 2, 1 }, { "Glandula", 1, 1, 0.5 }, { "ArenaDorada", 1, 1, 0.2 } }, Money = 18 },
	Momia = { Planet = "Valmar", Region = "DesiertoDorado", Name = "Momia", Icon = "🧟", Body = "Bipedo", Look = "Momia", Size = 4.8, Hp = 230, Damage = 16, Speed = 11, Aggro = 55,
		Colors = { Body = rgb(150, 130, 96), Belly = rgb(214, 198, 160), Glow = rgb(120, 255, 220) }, Material = "Fabric",
		Drops = { { "Hueso", 1, 2, 1 }, { "Seda", 1, 1, 0.5 }, { "ArenaDorada", 1, 1, 0.3 } }, Money = 20 },
	SerpienteDuna = { Planet = "Valmar", Region = "DesiertoDorado", Name = "Serpiente de arena", Icon = "🐍", Body = "Serpiente", Size = 5, Hp = 200, Damage = 16, Speed = 17, Aggro = 60,
		Colors = { Body = rgb(196, 160, 96), Belly = rgb(230, 206, 150), Glow = rgb(255, 210, 80) }, Material = "Sandstone",
		Drops = { { "Escama", 1, 2, 1 }, { "Glandula", 1, 1, 0.5 }, { "ArenaDorada", 1, 1, 0.25 } }, Money = 20 },
	SaqueadorDesierto = { Planet = "Valmar", Region = "DesiertoDorado", Name = "Saqueador", Icon = "🗡", Body = "Bipedo", Size = 4.6, Hp = 210, Damage = 16, Speed = 17, Aggro = 70,
		Colors = { Body = rgb(170, 140, 100), Belly = rgb(90, 60, 40), Skin = rgb(170, 120, 84), Glow = rgb(255, 180, 80) }, Material = "Fabric",
		Drops = { { "Cuero", 1, 2, 1 }, { "Hueso", 1, 1, 0.4 }, { "ArenaDorada", 1, 1, 0.3 } }, Money = 22 },
	GuardianDesierto = { Planet = "Valmar", Region = "DesiertoDorado", Name = "Guardián de arena", Icon = "🗿", Body = "Bipedo", Arms = true, Size = 5.8, Hp = 260, Damage = 17, Speed = 12, Aggro = 50,
		Colors = { Body = rgb(200, 160, 100), Belly = rgb(150, 110, 70), Glow = rgb(255, 200, 80) }, Material = "Sandstone",
		Drops = { { "Hueso", 1, 2, 1 }, { "ArenaDorada", 1, 1, 0.35 } }, Money = 22 },
	ColosoArena = { Planet = "Valmar", Region = "DesiertoDorado", Boss = true, Arms = true, Name = "El Coloso de Arena", Icon = "🗿", Body = "Bipedo", Size = 20, Hp = 14000, Damage = 52, Speed = 11, Aggro = 120,
		Colors = { Body = rgb(210, 170, 100), Belly = rgb(160, 120, 70), Glow = rgb(255, 190, 60) }, Material = "Sandstone",
		Drops = { { "NucleoColoso", 1, 1, 1 }, { "ArenaDorada", 2, 4, 1 }, { "Hueso", 3, 5, 1 } }, Money = 2300,
		Lore = "Un templo entero que decidió ponerse de pie. Los grabados de su pecho son un mapa. Nadie sabe de qué." },
	-- Ruinas Antiguas (nv. 60-80)
	CaballeroEspectral = { Planet = "Valmar", Region = "RuinasAntiguas", Name = "Caballero espectral", Icon = "👻", Body = "Bipedo", Arms = true, Size = 4.8, Hp = 220, Damage = 17, Speed = 16, Aggro = 70,
		Colors = { Body = rgb(110, 120, 140), Belly = rgb(170, 180, 200), Glow = rgb(140, 200, 255) }, Material = "Metal",
		Drops = { { "Hueso", 1, 2, 1 }, { "ReliquiaRunica", 1, 1, 0.25 } }, Money = 22 },
	GuardianPiedra = { Planet = "Valmar", Region = "RuinasAntiguas", Name = "Gólem de piedra", Icon = "🗿", Body = "Bipedo", Arms = true, Size = 6.5, Hp = 320, Damage = 19, Speed = 10, Aggro = 45,
		Colors = { Body = rgb(130, 126, 116), Belly = rgb(170, 164, 150), Glow = rgb(255, 210, 120) }, Material = "Limestone",
		Drops = { { "Hueso", 1, 2, 1 }, { "ReliquiaRunica", 1, 1, 0.3 } }, Money = 26 },
	EsqueletoGuerrero = { Planet = "Valmar", Region = "RuinasAntiguas", Name = "Esqueleto guerrero", Icon = "💀", Body = "Bipedo", Look = "Esqueleto", Weapon = "Espada", Shield = true, Size = 4.6, Hp = 200, Damage = 17, Speed = 17, Aggro = 70,
		Colors = { Body = rgb(226, 218, 196), Belly = rgb(110, 104, 96), Glow = rgb(140, 200, 255) }, Material = "SmoothPlastic",
		Drops = { { "Hueso", 1, 3, 1 }, { "ReliquiaRunica", 1, 1, 0.25 } }, Money = 22 },
	MagoAntiguo = { Planet = "Valmar", Region = "RuinasAntiguas", Name = "Mago antiguo", Icon = "🔮", Body = "Bipedo", Size = 4.8, Hp = 200, Damage = 19, Speed = 14, Aggro = 75,
		Colors = { Body = rgb(110, 70, 40), Belly = rgb(60, 40, 26), Skin = rgb(210, 180, 150), Glow = rgb(120, 200, 255) }, Material = "Fabric",
		Drops = { { "Hueso", 1, 2, 1 }, { "Seda", 1, 1, 0.4 }, { "ReliquiaRunica", 1, 1, 0.3 } }, Money = 24 },
	ArqueroEspectral = { Planet = "Valmar", Region = "RuinasAntiguas", Name = "Arquero espectral", Icon = "🏹", Body = "Bipedo", Size = 4.6, Hp = 190, Damage = 18, Speed = 16, Aggro = 80,
		Colors = { Body = rgb(110, 150, 190), Belly = rgb(60, 80, 110), Glow = rgb(140, 210, 255) }, Material = "Glass",
		Drops = { { "Hueso", 1, 2, 1 }, { "ReliquiaRunica", 1, 1, 0.3 } }, Money = 24 },
	Cultista = { Planet = "Valmar", Region = "RuinasAntiguas", Name = "Cultista", Icon = "🔮", Body = "Bipedo", Look = "Mago", Weapon = "Daga", Size = 4.6, Hp = 190, Damage = 18, Speed = 15, Aggro = 75,
		Colors = { Body = rgb(112, 26, 32), Belly = rgb(44, 16, 20), Skin = rgb(200, 170, 150), Glow = rgb(255, 80, 60) }, Material = "Fabric",
		Drops = { { "Hueso", 1, 2, 1 }, { "Seda", 1, 1, 0.4 }, { "ReliquiaRunica", 1, 1, 0.3 } }, Money = 24 },
	ConstructoRuinas = { Planet = "Valmar", Region = "RuinasAntiguas", Name = "Constructo antiguo", Icon = "⚙", Body = "Insecto", Size = 4.4, Hp = 200, Damage = 16, Speed = 15, Aggro = 60,
		Colors = { Body = rgb(150, 120, 70), Belly = rgb(110, 90, 60), Glow = rgb(255, 180, 60) }, Material = "Metal",
		Drops = { { "Quitina", 1, 2, 1 }, { "ReliquiaRunica", 1, 1, 0.2 } }, Money = 22 },
	ReyRuinas = { Planet = "Valmar", Region = "RuinasAntiguas", Boss = true, Arms = true, Name = "El Rey de las Ruinas", Icon = "👑", Body = "Bipedo", Size = 17, Hp = 18000, Damage = 60, Speed = 13, Aggro = 120,
		Colors = { Body = rgb(90, 90, 110), Belly = rgb(200, 170, 90), Glow = rgb(140, 190, 255) }, Material = "Metal",
		Drops = { { "CoronaRuinas", 1, 1, 1 }, { "ReliquiaRunica", 2, 4, 1 }, { "Hueso", 3, 5, 1 } }, Money = 2800,
		Lore = "Reinó aquí antes de que existiera Valmar. Lleva siglos esperando a que alguien le devuelva la corona." },
	-- Montañas Heladas (nv. 70-90)
	LoboArtico = { Planet = "Valmar", Region = "MontanasHeladas", Name = "Lobo ártico", Icon = "🐺", Body = "Cuadrupedo", Size = 5, Hp = 220, Damage = 17, Speed = 24, Aggro = 80,
		Colors = { Body = rgb(226, 232, 242), Belly = rgb(180, 190, 206), Glow = rgb(130, 200, 255) }, Material = "Snow",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 }, { "EscarchaPerpetua", 1, 1, 0.2 } }, Money = 22 },
	GolemHielo = { Planet = "Valmar", Region = "MontanasHeladas", Name = "Gigante de hielo", Icon = "❄", Body = "Bipedo", Arms = true, Look = "Gigante", Weapon = "Maza", Size = 7.5, Hp = 340, Damage = 20, Speed = 10, Aggro = 45,
		Colors = { Body = rgb(110, 150, 200), Belly = rgb(80, 96, 130), Skin = rgb(160, 200, 235), Glow = rgb(170, 240, 255) }, Material = "Slate",
		Drops = { { "Hueso", 1, 2, 1 }, { "EscarchaPerpetua", 1, 1, 0.35 } }, Money = 28 },
	GolemEscarcha = { Planet = "Valmar", Region = "MontanasHeladas", Name = "Gólem de hielo", Icon = "❄", Body = "Bipedo", Arms = true, Size = 6.5, Hp = 330, Damage = 20, Speed = 10, Aggro = 45,
		Colors = { Body = rgb(150, 190, 220), Belly = rgb(100, 140, 180), Glow = rgb(150, 230, 255) }, Material = "Ice",
		Drops = { { "Hueso", 1, 2, 1 }, { "EscarchaPerpetua", 1, 1, 0.35 } }, Money = 28 },
	EspectroGlacial = { Planet = "Valmar", Region = "MontanasHeladas", Name = "Espectro glacial", Icon = "👻", Body = "Bipedo", Flies = true, Size = 4.8, Hp = 230, Damage = 19, Speed = 16, Aggro = 70,
		Colors = { Body = rgb(170, 220, 250), Belly = rgb(110, 160, 210), Glow = rgb(160, 235, 255) }, Material = "Glass",
		Drops = { { "Glandula", 1, 2, 1 }, { "EscarchaPerpetua", 1, 1, 0.3 } }, Money = 26 },
	DracoHielo = { Planet = "Valmar", Region = "MontanasHeladas", Name = "Dragón de hielo", Icon = "🐉", Body = "Cuadrupedo", Look = "Dragon", Size = 7, Hp = 260, Damage = 19, Speed = 17, Aggro = 70,
		Colors = { Body = rgb(150, 190, 230), Belly = rgb(220, 236, 255), Glow = rgb(110, 210, 255) }, Material = "Ice",
		Drops = { { "Escama", 1, 2, 1 }, { "EscarchaPerpetua", 1, 1, 0.25 } }, Money = 26 },
	DragonInvierno = { Planet = "Valmar", Region = "MontanasHeladas", Boss = true, Breath = true, Name = "El Dragón del Invierno", Icon = "🐉", Body = "Cuadrupedo", Look = "Dragon", Size = 20, Hp = 23000, Damage = 70, Speed = 15, Aggro = 130,
		Colors = { Body = rgb(170, 210, 245), Belly = rgb(235, 245, 255), Glow = rgb(90, 200, 255) }, Material = "Ice",
		Drops = { { "EscamaInvierno", 1, 1, 1 }, { "EscarchaPerpetua", 2, 4, 1 }, { "Escama", 3, 5, 1 } }, Money = 3400,
		Lore = "Cuando abre las alas, nieva en Valmar. Por eso este verano ha nevado dos veces." },
	-- Tierras Oscuras (nv. 80-100)
	BestiaSombria = { Planet = "Valmar", Region = "TierrasOscuras", Name = "Bestia sombría", Icon = "🐺", Body = "Cuadrupedo", Size = 5.4, Hp = 250, Damage = 20, Speed = 24, Aggro = 80,
		Colors = { Body = rgb(30, 26, 40), Belly = rgb(70, 60, 90), Glow = rgb(180, 90, 255) }, Material = "Slate",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 2, 0.5 }, { "FragmentoSombra", 1, 1, 0.2 } }, Money = 26 },
	CaballeroCorrupto = { Planet = "Valmar", Region = "TierrasOscuras", Name = "Caballero sombrío", Icon = "🛡", Body = "Bipedo", Arms = true, Look = "Caballero", Weapon = "Espada", Shield = true, Size = 5, Hp = 300, Damage = 22, Speed = 15, Aggro = 70,
		Colors = { Body = rgb(40, 36, 50), Belly = rgb(90, 80, 110), Glow = rgb(200, 60, 255) }, Material = "Metal",
		Drops = { { "Hueso", 1, 2, 1 }, { "FragmentoSombra", 1, 1, 0.3 } }, Money = 30 },
	Demonio = { Planet = "Valmar", Region = "TierrasOscuras", Name = "Demonio menor", Icon = "👹", Body = "Bipedo", Arms = true, Look = "Demonio", Size = 6, Hp = 290, Damage = 23, Speed = 17, Aggro = 75,
		Colors = { Body = rgb(140, 30, 34), Belly = rgb(60, 16, 24), Glow = rgb(255, 130, 40) }, Material = "Slate",
		Drops = { { "Hueso", 1, 2, 1 }, { "Colmillo", 1, 2, 0.5 }, { "FragmentoSombra", 1, 1, 0.3 } }, Money = 32 },
	MagoOscuro = { Planet = "Valmar", Region = "TierrasOscuras", Name = "Hechicero oscuro", Icon = "🔮", Body = "Bipedo", Look = "Mago", Weapon = "Baston", Size = 4.8, Hp = 230, Damage = 22, Speed = 15, Aggro = 75,
		Colors = { Body = rgb(52, 32, 92), Belly = rgb(24, 16, 40), Glow = rgb(190, 90, 255) }, Material = "Fabric",
		Drops = { { "Hueso", 1, 2, 1 }, { "Seda", 1, 1, 0.4 }, { "FragmentoSombra", 1, 1, 0.3 } }, Money = 30 },
	CriaturaVacio = { Planet = "Valmar", Region = "TierrasOscuras", Name = "Espectro del vacío", Icon = "🌑", Body = "Bipedo", Flies = true, Size = 4.6, Hp = 230, Damage = 21, Speed = 19, Aggro = 70,
		Colors = { Body = rgb(20, 18, 30), Belly = rgb(60, 40, 90), Glow = rgb(150, 80, 255) }, Material = "Glass",
		Drops = { { "Quitina", 1, 2, 1 }, { "FragmentoSombra", 1, 1, 0.25 } }, Money = 28 },
	SenorSombras = { Planet = "Valmar", Region = "TierrasOscuras", Boss = true, Arms = true, Name = "El Señor de las Sombras", Icon = "💀", Body = "Bipedo", Size = 19, Hp = 29000, Damage = 80, Speed = 14, Aggro = 130,
		Colors = { Body = rgb(30, 24, 40), Belly = rgb(80, 60, 110), Glow = rgb(190, 70, 255) }, Material = "Metal",
		Drops = { { "CorazonSombra", 1, 1, 1 }, { "FragmentoSombra", 2, 4, 1 }, { "Hueso", 3, 5, 1 } }, Money = 4000,
		Lore = "Fue uno de los ayudantes de Cosme. Cruzó el puente negro para traer algo de vuelta. Volvió solo él. O algo con su cara." },
	-- Tierras Volcánicas (nv. 90-110)
	SabuesoMagma = { Planet = "Valmar", Region = "TierrasVolcanicas", Name = "Sabueso de magma", Icon = "🔥", Body = "Cuadrupedo", Size = 5, Hp = 260, Damage = 22, Speed = 24, Aggro = 80,
		Colors = { Body = rgb(50, 36, 32), Belly = rgb(140, 60, 30), Glow = rgb(255, 120, 30) }, Material = "Basalt",
		Drops = { { "Cuero", 1, 2, 1 }, { "Colmillo", 1, 2, 0.5 }, { "MagmaVivo", 1, 1, 0.2 } }, Money = 28 },
	DemonioFuego = { Planet = "Valmar", Region = "TierrasVolcanicas", Name = "Demonio de fuego", Icon = "👹", Body = "Bipedo", Arms = true, Size = 5.6, Hp = 300, Damage = 24, Speed = 17, Aggro = 75,
		Colors = { Body = rgb(190, 70, 30), Belly = rgb(100, 30, 16), Glow = rgb(255, 160, 40) }, Material = "Basalt",
		Drops = { { "Hueso", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 }, { "MagmaVivo", 1, 1, 0.3 } }, Money = 32 },
	DemonioSupremo = { Planet = "Valmar", Region = "TierrasVolcanicas", Name = "Demonio supremo", Icon = "👹", Body = "Bipedo", Arms = true, Size = 7, Hp = 380, Damage = 26, Speed = 14, Aggro = 80,
		Colors = { Body = rgb(110, 20, 24), Belly = rgb(50, 10, 14), Glow = rgb(255, 110, 30) }, Material = "Basalt",
		Drops = { { "Hueso", 1, 3, 1 }, { "Colmillo", 1, 2, 0.6 }, { "MagmaVivo", 1, 1, 0.4 } }, Money = 38 },
	GolemLava = { Planet = "Valmar", Region = "TierrasVolcanicas", Name = "Gólem de lava", Icon = "🌋", Body = "Bipedo", Arms = true, Size = 7, Hp = 380, Damage = 25, Speed = 10, Aggro = 45,
		Colors = { Body = rgb(46, 40, 38), Belly = rgb(120, 50, 30), Glow = rgb(255, 100, 20) }, Material = "Basalt",
		Drops = { { "Hueso", 1, 2, 1 }, { "MagmaVivo", 1, 1, 0.35 } }, Money = 34 },
	ElementalFuego = { Planet = "Valmar", Region = "TierrasVolcanicas", Name = "Elemental de lava", Icon = "🔥", Body = "Bipedo", Look = "Elemental", Flies = true, Size = 5, Hp = 260, Damage = 24, Speed = 17, Aggro = 75,
		Colors = { Body = rgb(255, 110, 30), Belly = rgb(255, 180, 60), Glow = rgb(255, 235, 130) }, Material = "Neon",
		Drops = { { "Glandula", 1, 2, 1 }, { "MagmaVivo", 1, 1, 0.35 } }, Money = 32 },
	DragonInfernal = { Planet = "Valmar", Region = "TierrasVolcanicas", Name = "Dragón infernal", Icon = "🐉", Body = "Cuadrupedo", Look = "Dragon", Size = 7.5, Hp = 320, Damage = 25, Speed = 18, Aggro = 80,
		Colors = { Body = rgb(120, 30, 24), Belly = rgb(52, 30, 30), Glow = rgb(255, 130, 30) }, Material = "Basalt",
		Drops = { { "Escama", 1, 2, 1 }, { "Colmillo", 1, 1, 0.5 }, { "MagmaVivo", 1, 1, 0.3 } }, Money = 34 },
	SalamandraVolcan = { Planet = "Valmar", Region = "TierrasVolcanicas", Name = "Salamandra del volcán", Icon = "🐉", Body = "Serpiente", Size = 5, Hp = 280, Damage = 23, Speed = 17, Aggro = 70,
		Colors = { Body = rgb(80, 40, 30), Belly = rgb(200, 90, 30), Glow = rgb(255, 140, 40) }, Material = "Basalt",
		Drops = { { "Escama", 1, 2, 1 }, { "MagmaVivo", 1, 1, 0.25 } }, Money = 30 },
	TitanVolcan = { Planet = "Valmar", Region = "TierrasVolcanicas", Boss = true, Arms = true, Name = "El Titán del Volcán", Icon = "🌋", Body = "Bipedo", Size = 22, Hp = 36000, Damage = 92, Speed = 12, Aggro = 140,
		Colors = { Body = rgb(40, 32, 30), Belly = rgb(130, 50, 25), Glow = rgb(255, 90, 10) }, Material = "Basalt",
		Drops = { { "CorazonTitan", 1, 1, 1 }, { "MagmaVivo", 2, 4, 1 }, { "Escama", 3, 5, 1 } }, Money = 5000,
		Lore = "Dicen que el volcán no despertó: se levantó. Lo que ves desde Valmar al atardecer no es humo. Es él respirando." },
}

-- Orden fijo de cada planeta: tres bestias y el jefe
Bestiary.ByPlanet = {
	Tefra = { "Rondador", "EscarabajoLava", "GusanoColada", Boss = "BestiaBrasa" },
	Siroco = { "ChacalDuna", "EscorpionSal", "SerpienteArena", Boss = "ReyEscorpion" },
	Talasa = { "CangrejoNacar", "AnguilaArrecife", "FocaColmillo", Boss = "Leviatan" },
	Nivalis = { "LoboEscarcha", "AranaHielo", "OsoLanudo", Boss = "Durmiente" },
	Umbria = { "PanteraLiana", "AvispaEnjambre", "EscarabajoCorteza", Boss = "GranEscarabajo" },
	Miasma = { "RataChatarra", "MedusaGas", "BuitreRayo", Boss = "Silbador" },
	Vertice = { "RataCloaca", "DronRebelde", "CocodriloAliviadero", Boss = "Recaudador" },
	Valmar = { "JabaliSierra", "AvispaGrieta", "VivoraPenasco", Boss = "CiervoRoto" },
}

-- Nombres de guarida por planeta (según la bestia que vive ahí)
local LAIR_NAMES = {
	Cuadrupedo = { "Madriguera", "Cubil", "Guarida" },
	Insecto = { "Nido", "Colmena", "Hormiguero" },
	Serpiente = { "Cueva", "Grieta", "Sima" },
	Bipedo = { "Percha", "Atalaya rota", "Nido alto" },
}
local LAIR_LOOK = { Tefra = "Roca", Siroco = "Arenisca", Talasa = "Coral", Nivalis = "Hielo", Umbria = "Raices", Miasma = "Chatarra", Vertice = "Chatarra", Valmar = "Roca" }
Bestiary.LairLook = LAIR_LOOK

-- Planetas casi sin tierra (Tálasa): guaridas y alijos sobre arrecifes de roca que salen del agua (los pone
-- World/Kit/BeastKit; Islet = true y Y = la altura de su cima)
Bestiary.WaterLairs = { Talasa = true }
Bestiary.IsletTop = 3 -- studs sobre el agua

Bestiary.Respawn = 30 -- segundos para que una bestia vuelva a su guarida (17-11-2026: farmeo continuo, estilo Metin2)
Bestiary.BossRespawn = 1200 -- el jefe: 20 minutos
Bestiary.PackMin, Bestiary.PackMax = 5, 8
Bestiary.LairsPerSpecies = 3 -- (las de siempre, junto a la ciudad: zona 1)
-- ZONAS DE CAZA: las tierras salvajes se reparten en anillos alrededor de la ciudad. Cuanto más lejos, más
-- nivel: las bestias aguantan y pegan más, y dan más experiencia, dinero y botín.
--   Level: el nivel que se enseña · Hp / Damage / Reward: por cuánto se multiplica lo de la especie
Bestiary.Zones = {
	{ Name = "Afueras", Level = 5, Hp = 1, Damage = 1, Reward = 1 },
	{ Name = "Campo abierto", Level = 15, Hp = 1.8, Damage = 1.35, Reward = 1.8 },
	{ Name = "Tierras lejanas", Level = 25, Hp = 3, Damage = 1.75, Reward = 3 },
	{ Name = "Confines", Level = 35, Hp = 4.8, Damage = 2.2, Reward = 4.6 },
}
Bestiary.PacksPerZone = 10 -- manadas en cada anillo de las tierras salvajes (zonas 2, 3 y 4)

-- ESQUIRLAS DE LA GRIETA: cristales que cayeron del cielo en las zonas de caza. Se rompen a golpes; al ir
-- perdiendo vida sueltan OLEADAS de bestias de su zona, y al romperse dan mucho botín. Vuelven a caer al rato.
Bestiary.Shard = { Id = "Esquirla", Name = "Esquirla de la Grieta", Icon = "💎", Hp = 1400, Money = 120,
	Waves = { 0.75, 0.5, 0.25 }, WaveSize = { 3, 4, 5 }, Colors = { Body = rgb(150, 90, 255), Belly = rgb(80, 40, 160), Glow = rgb(190, 140, 255) } }
Bestiary.ShardsPerZone = { 2, 3, 3, 3 }
Bestiary.ShardRespawn = 300 -- segundos
-- (19-11-2026, el dueño: fuera las hordas que salen de la Grieta) false = las esquirlas no aparecen
Bestiary.ShardsEnabled = false

-- Lo que da una esquirla rota (más cuanto más lejos esté su zona)
function Bestiary.shardLoot(tier: number?, planet: string?, roll: () -> number): { [string]: number }
	local t = math.clamp(math.floor(tonumber(tier) or 1), 1, 4)
	local out: { [string]: number } = {}
	out.PiedraPulir = 2 + t + math.floor(roll() * 3)
	if roll() < 0.25 * t then
		out.PiedraTemple = 1
	end
	if t >= 3 and roll() < 0.15 * (t - 2) then
		out.EsenciaEstelar = 1
	end
	local rare = planet and Bestiary.Rare[planet]
	if rare then
		out[rare] = 1 + math.floor(roll() * t)
	end
	local commons = { "Cuero", "Colmillo", "Quitina", "Escama", "Glandula", "Hueso", "Seda" }
	local pick = commons[1 + math.floor(roll() * #commons)]
	out[pick] = (out[pick] or 0) + 2 + t
	return out
end

function Bestiary.zone(tier: number?): { [string]: any }
	return Bestiary.Zones[math.clamp(math.floor(tonumber(tier) or 1), 1, #Bestiary.Zones)]
end
-- «Rondador de ceniza nv. 15»
function Bestiary.leveledName(name: string, tier: number?): string
	return ("%s nv. %d"):format(name, Bestiary.zone(tier).Level)
end
-- Lo que multiplica la vida, el daño y lo que da una bestia de ese nivel (nv. 5 = 1; sigue la misma recta que
-- las cuatro zonas de los planetas: nv. 35 ≈ 4,8 de vida, 2,2 de daño y 4,6 de premio; nv. 110 ≈ 14×)
function Bestiary.levelScale(level: number): { [string]: number }
	local l = math.max(1, tonumber(level) or 1)
	return { Hp = 1 + (l - 5) * 0.127, Damage = 1 + (l - 5) * 0.04, Reward = 1 + (l - 5) * 0.12 }
end
-- La zona de una guarida o esquirla: las de las regiones de Valmar llevan su nivel (Level) y el nombre de su
-- región; las de los planetas, su anillo (Tier)
function Bestiary.lairZone(l: { [string]: any }?): { [string]: any }
	if l and l.Level then
		local k = Bestiary.levelScale(l.Level)
		return { Name = l.ZoneName or "Zona de caza", Level = l.Level, Hp = math.max(1, k.Hp), Damage = math.max(1, k.Damage), Reward = math.max(1, k.Reward) }
	end
	return Bestiary.zone(l and l.Tier)
end
Bestiary.CachesPerPlanet = 8
Bestiary.CacheCooldown = 20 * 3600 -- un alijo se abre otra vez a las 20 horas (cada jugador el suyo)
Bestiary.Leash = 120 -- una bestia no persigue a nadie más allá de esto desde su guarida
Bestiary.Active = 360 -- las guaridas con alguien a menos de esto tienen bestias fuera (hay muchas: el radio es menor)
Bestiary.Despawn = 520 -- sin nadie a menos de esto (un rato), las bestias se recogen

-- El material raro de cada planeta y su trofeo de jefe (para los alijos y las recetas)
Bestiary.Rare = { Tefra = "BrasaViva", Siroco = "VidrioTormenta", Talasa = "NacarAbisal", Nivalis = "HieloEterno", Umbria = "SaviaAmbar", Miasma = "PlataRayo", Vertice = "ChipUsado", Valmar = "CuarzoGrieta" }

-- «Guarida del Rey…», «Guarida de la Bestia…», «Guarida de lo que duerme…»
function Bestiary.lairOf(name: string): string
	local rest = string.match(name, "^El (.+)$")
	if rest then
		return "Guarida del " .. rest
	end
	rest = string.match(name, "^La (.+)$")
	if rest then
		return "Guarida de la " .. rest
	end
	rest = string.match(name, "^Lo (.+)$")
	if rest then
		return "Guarida de lo " .. rest
	end
	return "Guarida de " .. name
end

function Bestiary.species(id: string): { [string]: any }?
	return Bestiary.Species[id]
end


-- Lo que solo suelta cada especie (shared/Crafting: cascos, escudos, botas y accesorios) y las piedras de
-- mejorar el equipo: de pulir (cualquier bestia, a veces) y de temple y esencia estelar (los jefes).
Bestiary.Unique = {
	Rondador = "PelajeCeniza", EscarabajoLava = "CaparazonLava", GusanoColada = "EscoriaViva",
	ChacalDuna = "GarraDuna", EscorpionSal = "VenenoSal", SerpienteArena = "PielArena",
	CangrejoNacar = "PinzaNacar", AnguilaArrecife = "OrganoElectrico", FocaColmillo = "GrasaAbisal",
	LoboEscarcha = "PelajeEscarcha", AranaHielo = "HiloHielo", OsoLanudo = "LanaGruesa",
	PanteraLiana = "GarraLiana", AvispaEnjambre = "AguijonEnjambre", EscarabajoCorteza = "CortezaViva",
	RataChatarra = "DienteCobre", MedusaGas = "VelaGas", BuitreRayo = "PlumaRayo",
	RataCloaca = "ColaCable", DronRebelde = "NucleoDron", CocodriloAliviadero = "EscamaCromo",
	JabaliSierra = "ColmilloJabali", AvispaGrieta = "AlaCristal", VivoraPenasco = "PielPenasco",
}
for id, sp in Bestiary.Species do
	if sp.Boss then
		table.insert(sp.Drops, { "PiedraTemple", 1, 2, 1 })
		table.insert(sp.Drops, { "EsenciaEstelar", 1, 1, 0.6 })
		table.insert(sp.Drops, { "PiedraPulir", 2, 4, 1 })
	else
		if Bestiary.Unique[id] then
			table.insert(sp.Drops, { Bestiary.Unique[id], 1, 1, 0.4 })
		end
		table.insert(sp.Drops, { "PiedraPulir", 1, 1, 0.18 })
	end
end

-- Lo que suelta una bestia (repetible con roll: una función 0..1)
function Bestiary.loot(id: string, roll: () -> number, luck: number?): { [string]: number }
	local sp = Bestiary.Species[id]
	local out: { [string]: number } = {}
	if not sp then
		return out
	end
	for _, d in sp.Drops do
		-- (la suerte de tus accesorios sube lo que no cae siempre)
		if roll() <= (if d[4] < 1 then d[4] * (1 + (luck or 0)) else d[4]) then
			local n = d[2] + math.floor(roll() * (d[3] - d[2] + 1))
			if n > 0 then
				out[d[1]] = (out[d[1]] or 0) + n
			end
		end
	end
	return out
end

-- Lo que hay en un alijo de un planeta
function Bestiary.cacheLoot(planet: string, roll: () -> number): ({ [string]: number }, number)
	local out: { [string]: number } = {}
	local common = { "Cuero", "Colmillo", "Quitina", "Escama", "Glandula", "Hueso", "Seda" }
	for _ = 1, 2 + math.floor(roll() * 2) do
		local id = common[1 + math.floor(roll() * #common)]
		out[id] = (out[id] or 0) + 1 + math.floor(roll() * 2)
	end
	local rare = Bestiary.Rare[planet]
	if rare and roll() < 0.6 then
		out[rare] = (out[rare] or 0) + 1
	end
	if roll() < 0.35 then
		out.PocionCuracion = (out.PocionCuracion or 0) + 1
	end
	-- (17-11-2026: y de espíritu, para las habilidades: los botones de pociones del HUD, UI/MmoHud)
	if roll() < 0.28 then
		out.PocionEspiritu = (out.PocionEspiritu or 0) + 1
	end
	return out, 40 + math.floor(roll() * 80)
end

---------------------------------------------------------------------
-- Guaridas, jefe y alijos de un planeta (S: su superficie). Repetible.
---------------------------------------------------------------------
local cache: { [string]: { [string]: any } } = {}

function Bestiary.places(S: any): { [string]: any }
	local id = S.Id
	if cache[id] then
		return cache[id]
	end
	local list = Bestiary.ByPlanet[id]
	local out = { Lairs = {}, Boss = nil :: any, Caches = {}, Shards = {}, Bosses = {} }
	cache[id] = out
	if not list then
		return out
	end
	if S.Regions then
		return Bestiary.regionPlaces(S, out)
	end
	local r = rng((S.Seed or 7) * 7121 + 99)
	local taken: { { number } } = {}
	local function far(lx: number, lz: number, gap: number): boolean
		for _, t in taken do
			if (t[1] - lx) ^ 2 + (t[2] - lz) ^ 2 < gap * gap then
				return false
			end
		end
		return true
	end
	local water = Bestiary.WaterLairs[id] == true
	local function wetOk(lx: number, lz: number): boolean
		-- (en el agua: lejos de la ciudad, de sus plataformas y de los puntos de interés)
		if S.City and S.City.inside(lx, lz, 80) then
			return false
		end
		if S.Metro and S.Metro.covers(lx, lz) then
			return false
		end
		for _, p in S.POIs or {} do
			if math.sqrt((lx - p.X) ^ 2 + (lz - p.Z) ^ 2) < (p.Flat or 0) + 60 then
				return false
			end
		end
		return true
	end
	local core = S.CoreHalf or S.Half
	local function find(gap: number, minR: number, maxSlope: number, maxR: number?): (number?, number?)
		for _ = 1, 3000 do
			local a = r() * math.pi * 2
			local d = minR + r() * ((maxR or core * 0.74) - minR)
			local lx, lz = math.cos(a) * d, math.sin(a) * d
			if far(lx, lz, gap) and (S.goodSpot(lx, lz, maxSlope, 26) or (water and wetOk(lx, lz))) then
				return lx, lz
			end
		end
		return nil, nil
	end
	local O = S.Origin
	local function y(lx: number, lz: number): (number, boolean?)
		local g = S.heightAt(O.X + lx, O.Z + lz) - O.Y
		if water and g < (S.WaterY or 0) + Bestiary.IsletTop then
			return (S.WaterY or 0) + Bestiary.IsletTop, true
		end
		return g, nil
	end
	-- (S.ZoneR: los radios de las zonas a mano, { inicio zona 1, 2, 3, 4, fin }: Valmar, cuyo campo está
	-- lejos del centro, alrededor de la ciudad. Los planetas no lo llevan: anillos desde CoreHalf)
	local ZR = S.ZoneR
	-- el jefe: lejos de todo, en un sitio llano para pelear
	local bx, bz
	if ZR then
		bx, bz = find(300, ZR[4], 0.35, ZR[5])
		if not bx then
			bx, bz = find(200, ZR[3], 0.5, ZR[5])
		end
	else
		bx, bz = find(300, core * 0.5, 0.35)
		if not bx then
			bx, bz = find(200, 300, 0.5)
		end
	end
	if bx then
		local sp = Bestiary.Species[list.Boss]
		local by, islet = y(bx, bz)
		out.Boss = { Id = id .. "_Jefe", Species = list.Boss, X = bx, Z = bz, Y = by, Islet = islet, Count = 1, Boss = true, Look = LAIR_LOOK[id] or "Roca",
			Name = Bestiary.lairOf(sp.Name) }
		table.insert(taken, { bx, bz })
	end
	-- las guaridas: tres por bestia
	for si, sid in ipairs(list) do
		local sp = Bestiary.Species[sid]
		for k = 1, Bestiary.LairsPerSpecies do
			local lx, lz
			if ZR then
				lx, lz = find(170, ZR[1], 0.6, ZR[2])
			else
				lx, lz = find(170, 200, 0.6)
			end
			if lx then
				local names = LAIR_NAMES[sp.Body] or LAIR_NAMES.Cuadrupedo
				local n = #out.Lairs + 1
				local ly, islet = y(lx, lz)
				table.insert(out.Lairs, {
					Id = ("%s_G%d"):format(id, n),
					Species = sid,
					X = lx,
					Z = lz,
					Y = ly,
					Islet = islet,
					Count = Bestiary.PackMin + math.floor(r() * (Bestiary.PackMax - Bestiary.PackMin + 1)),
					Look = LAIR_LOOK[id] or "Roca",
					Tier = 1,
					Name = ("%s de %s"):format(names[1 + (si + k) % #names], (sp.Name:gsub("^%a+ ", function(w)
						return w
					end)):lower()),
				})
				table.insert(taken, { lx, lz })
			end
		end
	end
	-- las tierras salvajes: anillos de manadas cada vez más fuertes, de la ciudad hacia fuera
	local outer = S.Half - 440
	local inner = core * 0.74
	if ZR or outer > inner + 200 then
		local rings = #Bestiary.Zones - 1
		local step = (outer - inner) / rings
		for tier = 2, #Bestiary.Zones do
			local r0, r1 = inner + (tier - 2) * step, inner + (tier - 1) * step
			if ZR then
				r0, r1 = ZR[tier], ZR[tier + 1]
			end
			for k = 1, Bestiary.PacksPerZone do
				local sid = list[1 + (k + tier) % #list]
				local sp = Bestiary.Species[sid]
				local lx, lz = find(150, r0, 0.6, r1)
				if lx then
					local names = LAIR_NAMES[sp.Body] or LAIR_NAMES.Cuadrupedo
					local ly, islet = y(lx, lz)
					table.insert(out.Lairs, {
						Id = ("%s_Z%d_%d"):format(id, tier, k),
						Species = sid,
						X = lx,
						Z = lz,
						Y = ly,
						Islet = islet,
						Count = Bestiary.PackMin + math.floor(r() * (Bestiary.PackMax - Bestiary.PackMin + 1)),
						Look = LAIR_LOOK[id] or "Roca",
						Tier = tier,
						Name = ("%s (%s)"):format(names[1 + (k + tier) % #names], Bestiary.Zones[tier].Name:lower()),
					})
					table.insert(taken, { lx, lz })
				end
			end
		end
	end
	-- las esquirlas de la Grieta: unas pocas en cada zona de caza
	do
		local outer2 = S.Half - 440
		local inner2 = core * 0.74
		local rings = #Bestiary.Zones - 1
		local step = if outer2 > inner2 + 200 then (outer2 - inner2) / rings else 0
		for tier = 1, #Bestiary.Zones do
			local r0, r1
			if ZR then
				r0, r1 = ZR[tier], ZR[tier + 1]
			elseif tier == 1 or step <= 0 then
				r0, r1 = 220, inner2
			else
				r0, r1 = inner2 + (tier - 2) * step, inner2 + (tier - 1) * step
			end
			for k = 1, Bestiary.ShardsPerZone[tier] or 2 do
				local lx, lz = find(130, r0, 0.5, r1)
				if lx then
					local sy, islet = y(lx, lz)
					table.insert(out.Shards, { Id = ("%s_E%d_%d"):format(id, tier, k), X = lx, Z = lz, Y = sy, Islet = islet, Tier = tier,
						Species = list[1 + (k + tier) % #list], Name = ("%s (%s)"):format(Bestiary.Shard.Name, Bestiary.Zones[tier].Name:lower()) })
					table.insert(taken, { lx, lz })
				end
			end
		end
	end
	-- los alijos: escondidos (algunos cerca de guaridas: el premio de atreverse)
	for k = 1, Bestiary.CachesPerPlanet do
		local lx, lz
		if ZR then
			lx, lz = find(110, ZR[1], 0.7, ZR[5])
		else
			lx, lz = find(110, 160, 0.7)
		end
		if lx then
			local cy, islet = y(lx, lz)
			table.insert(out.Caches, { Id = ("%s_A%d"):format(id, k), X = lx, Z = lz, Y = cy, Islet = islet })
			table.insert(taken, { lx, lz })
		end
	end
	return out
end

---------------------------------------------------------------------
-- Las ocho regiones de Valmar (S.Regions = shared/Cosmos/ValmarRegions): en cada sector, guaridas de sus
-- tres criaturas (el nivel sube hacia la costa), su jefe en lo más lejano, esquirlas y alijos. Repetible.
---------------------------------------------------------------------
Bestiary.LairsPerRegion = 30 -- (2 en el campo de la isla y 28 al otro lado del mar, en las Tierras Exteriores)
-- Guaridas de los distritos de caza de la isla (shared/CityPlan.Districts con Farm): una cada FarmSpacing studs
-- (17-11-2026, el dueño: «tantos monstruos como en Metin2»), como mucho LairsPerFarm por distrito
Bestiary.FarmSpacing = 230
Bestiary.LairsPerFarm = 180
Bestiary.FarmPackMin, Bestiary.FarmPackMax = 6, 9
Bestiary.ShardsPerRegion = 3
Bestiary.CachesPerRegion = 2

-- (perezoso: RegionGuide pide ValmarRegions, que ya tenemos; así no hay vueltas al cargar)
local regionGuide: any = nil
local function RegionGuide(): any
	if not regionGuide then
		regionGuide = require(script.Parent.RegionGuide)
	end
	return regionGuide
end

function Bestiary.regionPlaces(S: any, out: { [string]: any }): { [string]: any }
	local R = S.Regions
	local r = rng((S.Seed or 7) * 7121 + 991)
	local taken: { { number } } = {}
	local function far(lx: number, lz: number, gap: number): boolean
		for _, t in taken do
			if (t[1] - lx) ^ 2 + (t[2] - lz) ^ 2 < gap * gap then
				return false
			end
		end
		return true
	end
	-- un sitio bueno dentro del sector de la región, entre r0 y r1 del centro
	local function find(reg: any, gap: number, r0: number, r1: number, maxSlope: number): (number?, number?)
		local half = math.rad(R.Width / 2 - 3)
		local a0 = math.rad(reg.Bearing)
		for _ = 1, 2500 do
			local a = a0 + (r() * 2 - 1) * half
			local d = r0 + r() * (r1 - r0)
			local lx, lz = math.sin(a) * d, -math.cos(a) * d
			if far(lx, lz, gap) and S.goodSpot(lx, lz, maxSlope, 26) then
				return lx, lz
			end
		end
		-- (región casi sin campo: terreno menos salvaje, igual de lejos de lo construido)
		for _ = 1, 2500 do
			local a = a0 + (r() * 2 - 1) * half
			local d = r0 + r() * (r1 - r0)
			local lx, lz = math.sin(a) * d, -math.cos(a) * d
			if far(lx, lz, gap) and S.goodSpot(lx, lz, maxSlope, 26, true) then
				return lx, lz
			end
		end
		return nil, nil
	end
	-- un sitio en las Tierras Exteriores del sector: t = 0 (el borde del antiguo mar de Valmar) .. 1 (la costa de
	-- fuera); t < 0, en la tierra nueva donde estaba el mar (fase B: un solo terreno con la ciudad)
	local function findOuter(reg: any, gap: number, t0: number, t1: number, maxSlope: number): (number?, number?)
		if not R.Frame then
			return nil, nil
		end
		local half = R.Width / 2 - 3
		for _ = 1, 2500 do
			local a = reg.Bearing + (r() * 2 - 1) * half
			local t = t0 + r() * (t1 - t0)
			local dist = R.rayBox(a, t * R.Frame.Width)
			local lx, lz = math.sin(math.rad(a)) * dist, -math.cos(math.rad(a)) * dist
			if far(lx, lz, gap) and S.goodSpot(lx, lz, maxSlope, 26) then
				return lx, lz
			end
		end
		return nil, nil
	end
	local O = S.Origin
	local function y(lx: number, lz: number): number
		return S.heightAt(O.X + lx, O.Z + lz) - O.Y
	end
	local inner, outer = R.InnerR, 4300 -- (el campo de la isla)
	local mid = (inner + outer) / 2
	for _, reg in R.List do
		local function lairOf(sid: string, lx: number, lz: number, idSuffix: string, boss: boolean?): { [string]: any }
			local sp = Bestiary.Species[sid]
			local names = LAIR_NAMES[sp.Body] or LAIR_NAMES.Cuadrupedo
			local level = R.levelAt(reg, lx, lz)
			if boss then
				level = reg.MaxLevel
			end
			return {
				Id = ("%s_%s_%s"):format(S.Id, reg.Id, idSuffix),
				Species = sid,
				X = lx,
				Z = lz,
				Y = y(lx, lz),
				Count = if boss then 1 else Bestiary.PackMin + math.floor(r() * (Bestiary.PackMax - Bestiary.PackMin + 1)),
				Look = reg.Look or "Roca",
				Tier = math.clamp(1 + math.floor((level - 10) / 25), 1, 4),
				Level = level,
				Region = reg.Id,
				ZoneName = reg.Name,
				Boss = boss or nil,
				Name = if boss then Bestiary.lairOf(sp.Name) else ("%s de %s"):format(names[1 + (#out.Lairs % #names)], sp.Name:lower()),
			}
		end
		-- (17-11-2026) LOS LUGARES DE LA REGIÓN (shared/Cosmos/RegionGuide): cada uno con nivel tiene sus guaridas
		-- alrededor, de ese nivel, y el jefe vive en el suyo (Boss = true). Las áreas jugables del dibujo del dueño.
		local bx, bz = nil, nil
		local guide = if S.Id == "Valmar" then RegionGuide().List[reg.Id] else nil
		local KIND_SPECIES = { Territorio = 1, Cascada = 2, Cueva = 3, Ruinas = 4, Arbol = 4, Campamento = 5, Portal = 5 }
		for pi, place in (guide and guide.Places or {}) do
			local px, pz = RegionGuide().worldOf(reg.Id, place)
			if place.Boss then
				-- (la guarida del jefe, un poco detrás del lugar: el lugar se queda a la vista)
				local d = math.sqrt(px * px + pz * pz)
				local back = if place.Kind == "Arbol" then 115 else 40 -- (fuera de las raíces del árbol gigante)
				bx, bz = px + px / d * back, pz + pz / d * back
			end
			if place.Level and place.Kind ~= "Santuario" then
				for k = 1, 2 do
					local a = (pi * 1.7 + k * math.pi) % (math.pi * 2)
					local lx, lz = px + math.cos(a) * 48, pz + math.sin(a) * 48
					local sid = reg.Species[1 + ((KIND_SPECIES[place.Kind] or k) - 1 + k - 1) % #reg.Species]
					local rec = lairOf(sid, lx, lz, ("L%s%d"):format(place.Id, k))
					rec.Level = math.clamp(place.Level + (k - 1) * 2, reg.MinLevel, reg.MaxLevel)
					rec.Tier = math.clamp(1 + math.floor((rec.Level - 10) / 25), 1, 4)
					rec.Place = place.Name
					rec.ZoneName = ("%s · %s"):format(reg.Name, place.Name)
					table.insert(out.Lairs, rec)
					table.insert(taken, { lx, lz })
				end
			end
		end
		-- el jefe: en su lugar; si no, lo más lejos posible (al fondo de las Tierras Exteriores), en llano
		if not bx then
			bx, bz = findOuter(reg, 300, 0.6, 0.92, 0.35)
		end
		if not bx then
			bx, bz = findOuter(reg, 220, 0.3, 0.95, 0.5)
		end
		if not bx then
			bx, bz = find(reg, 200, inner + 200, outer - 200, 0.6)
		end
		if bx then
			local boss = lairOf(reg.Boss, bx, bz, "Jefe", true)
			table.insert(out.Lairs, boss)
			table.insert(out.Bosses, boss)
			table.insert(taken, { bx, bz })
		end
		-- un jefe raro más (el Ciervo Roto, en el Bosque Etéreo)
		if reg.Elite and Bestiary.Species[reg.Elite] then
			local ex, ez = find(reg, 260, inner + 300, outer, 0.4)
			if not ex then
				ex, ez = findOuter(reg, 260, 0.1, 0.4, 0.4)
			end
			if ex then
				local elite = lairOf(reg.Elite, ex, ez, "Elite", true)
				elite.Level = math.floor((reg.MinLevel + reg.MaxLevel) / 2)
				table.insert(out.Lairs, elite)
				table.insert(out.Bosses, elite)
				table.insert(taken, { ex, ez })
			end
		end
		-- las guaridas: de la ciudad hacia la costa, las tres criaturas por turnos
		for k = 1, Bestiary.LairsPerRegion do
			local lx, lz
			if k <= 2 then
				lx, lz = find(reg, 160, inner, outer, 0.6)
				if not lx then
					lx, lz = findOuter(reg, 160, 0.05, 0.3, 0.6)
				end
			else
				local n = Bestiary.LairsPerRegion - 2
				local t0 = -0.6 + (k - 3) / n * 1.55
				lx, lz = findOuter(reg, 160, t0, t0 + 1.55 / n, 0.6)
				if not lx then
					lx, lz = findOuter(reg, 150, -0.6, 0.95, 0.65)
				end
			end
			if lx then
				local sid = reg.Species[1 + (k - 1) % #reg.Species]
				table.insert(out.Lairs, lairOf(sid, lx, lz, "G" .. k))
				table.insert(taken, { lx, lz })
			end
		end
		-- esquirlas de la Grieta
		for k = 1, Bestiary.ShardsPerRegion do
			local lx, lz
			if k == 1 then
				lx, lz = find(reg, 130, inner + 200, outer, 0.5)
			end
			if not lx then
				lx, lz = findOuter(reg, 130, 0.1, 0.9, 0.5)
			end
			if lx then
				local level = R.levelAt(reg, lx, lz)
				table.insert(out.Shards, { Id = ("%s_%s_E%d"):format(S.Id, reg.Id, k), X = lx, Z = lz, Y = y(lx, lz),
					Tier = math.clamp(1 + math.floor((level - 10) / 25), 1, 4), Level = level, Region = reg.Id, ZoneName = reg.Name,
					Species = reg.Species[1 + (k % #reg.Species)], Name = ("%s (%s)"):format(Bestiary.Shard.Name, reg.Name) })
				table.insert(taken, { lx, lz })
			end
		end
		-- alijos
		for k = 1, Bestiary.CachesPerRegion do
			local lx, lz
			if k == 1 then
				lx, lz = find(reg, 110, inner + 100, outer, 0.7)
			end
			if not lx then
				lx, lz = findOuter(reg, 110, 0.1, 0.95, 0.7)
			end
			if lx then
				table.insert(out.Caches, { Id = ("%s_%s_A%d"):format(S.Id, reg.Id, k), X = lx, Z = lz, Y = y(lx, lz), Region = reg.Id })
				table.insert(taken, { lx, lz })
			end
		end
	end
	-- (17-11-2026) LOS DISTRITOS DE CAZA de la isla (S.Farms: los distritos de fuera del Distrito Central, con
	-- Farm = { Min, Max, Species }): guaridas de nivel bajo, de Min (la primera) a Max (la última). Aquí empiezan
	-- los cadetes de la Academia.
	for _, d in S.Farms or {} do
		local F = d.Farm
		local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
		for _, pt in d.Poly do
			x0, x1 = math.min(x0, pt[1]), math.max(x1, pt[1])
			z0, z1 = math.min(z0, pt[2]), math.max(z1, pt[2])
		end
		local placed = 0
		-- cuántas caben: el área del distrito entre el hueco de cada guarida
		local area = 0
		for idx, pt in d.Poly do
			local nx = d.Poly[idx % #d.Poly + 1]
			area += pt[1] * nx[2] - nx[1] * pt[2]
		end
		area = math.abs(area) / 2
		local n = math.clamp(math.floor(area / (Bestiary.FarmSpacing * Bestiary.FarmSpacing)), 6, Bestiary.LairsPerFarm)
		for pass = 1, 2 do
			for _ = 1, n * 60 do
				if placed >= n then
					break
				end
				local lx, lz = x0 + r() * (x1 - x0), z0 + r() * (z1 - z0)
				if S.insideFarm(d, lx, lz) and far(lx, lz, if pass == 1 then Bestiary.FarmSpacing * 0.8 else Bestiary.FarmSpacing * 0.55) and S.goodSpot(lx, lz, if pass == 1 then 0.5 else 0.7, 10, true) then
					placed += 1
					local level = F.Min + math.floor((F.Max - F.Min) * (placed - 1) / math.max(1, n - 1) + 0.5)
					local sid = F.Species[1 + (placed - 1) % #F.Species]
					local sp = Bestiary.Species[sid]
					local names = LAIR_NAMES[sp.Body] or LAIR_NAMES.Cuadrupedo
					table.insert(out.Lairs, {
						Id = ("%s_%s_F%d"):format(S.Id, d.Id, placed),
						Species = sid,
						X = lx,
						Z = lz,
						Y = y(lx, lz),
						Count = Bestiary.FarmPackMin + math.floor(r() * (Bestiary.FarmPackMax - Bestiary.FarmPackMin + 1)),
						Look = F.Look or "Roca",
						Tier = 1,
						Level = level,
						Region = "Farm_" .. d.Id,
						ZoneName = d.Name,
						Name = ("%s de %s"):format(names[1 + (#out.Lairs % #names)], sp.Name:lower()),
					})
					table.insert(taken, { lx, lz })
				end
			end
		end
	end
	return out
end

-- La guarida (o el jefe) con ese id
function Bestiary.lair(S: any, lairId: string): { [string]: any }?
	local p = Bestiary.places(S)
	if p.Boss and p.Boss.Id == lairId then
		return p.Boss
	end
	for _, l in p.Lairs do
		if l.Id == lairId then
			return l
		end
	end
	return nil
end

return Bestiary
