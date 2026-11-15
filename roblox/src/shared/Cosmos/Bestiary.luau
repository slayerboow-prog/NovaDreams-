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

-- Cuerpos (World/Kit/BeastKit los dibuja): Cuadrupedo, Insecto (seis patas), Serpiente, Bipedo
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
}

-- Nombres de guarida por planeta (según la bestia que vive ahí)
local LAIR_NAMES = {
	Cuadrupedo = { "Madriguera", "Cubil", "Guarida" },
	Insecto = { "Nido", "Colmena", "Hormiguero" },
	Serpiente = { "Cueva", "Grieta", "Sima" },
	Bipedo = { "Percha", "Atalaya rota", "Nido alto" },
}
local LAIR_LOOK = { Tefra = "Roca", Siroco = "Arenisca", Talasa = "Coral", Nivalis = "Hielo", Umbria = "Raices", Miasma = "Chatarra", Vertice = "Chatarra" }

-- Planetas casi sin tierra (Tálasa): guaridas y alijos sobre arrecifes de roca que salen del agua (los pone
-- World/Kit/BeastKit; Islet = true y Y = la altura de su cima)
Bestiary.WaterLairs = { Talasa = true }
Bestiary.IsletTop = 3 -- studs sobre el agua

Bestiary.Respawn = 90 -- segundos para que una bestia vuelva a su guarida
Bestiary.BossRespawn = 1200 -- el jefe: 20 minutos
Bestiary.PackMin, Bestiary.PackMax = 3, 5
Bestiary.LairsPerSpecies = 3
Bestiary.CachesPerPlanet = 8
Bestiary.CacheCooldown = 20 * 3600 -- un alijo se abre otra vez a las 20 horas (cada jugador el suyo)
Bestiary.Leash = 120 -- una bestia no persigue a nadie más allá de esto desde su guarida
Bestiary.Active = 480 -- las guaridas con alguien a menos de esto tienen bestias fuera
Bestiary.Despawn = 650 -- sin nadie a menos de esto (un rato), las bestias se recogen

-- El material raro de cada planeta y su trofeo de jefe (para los alijos y las recetas)
Bestiary.Rare = { Tefra = "BrasaViva", Siroco = "VidrioTormenta", Talasa = "NacarAbisal", Nivalis = "HieloEterno", Umbria = "SaviaAmbar", Miasma = "PlataRayo", Vertice = "ChipUsado" }

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
	local out = { Lairs = {}, Boss = nil :: any, Caches = {} }
	cache[id] = out
	if not list then
		return out
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
	local function find(gap: number, minR: number, maxSlope: number): (number?, number?)
		for _ = 1, 3000 do
			local a = r() * math.pi * 2
			local d = minR + r() * (S.Half * 0.74 - minR)
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
	-- el jefe: lejos de todo, en un sitio llano para pelear
	local bx, bz = find(300, S.Half * 0.5, 0.35)
	if not bx then
		bx, bz = find(200, 300, 0.5)
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
			local lx, lz = find(170, 200, 0.6)
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
					Name = ("%s de %s"):format(names[1 + (si + k) % #names], (sp.Name:gsub("^%a+ ", function(w)
						return w
					end)):lower()),
				})
				table.insert(taken, { lx, lz })
			end
		end
	end
	-- los alijos: escondidos (algunos cerca de guaridas: el premio de atreverse)
	for k = 1, Bestiary.CachesPerPlanet do
		local lx, lz = find(110, 160, 0.7)
		if lx then
			local cy, islet = y(lx, lz)
			table.insert(out.Caches, { Id = ("%s_A%d"):format(id, k), X = lx, Z = lz, Y = cy, Islet = islet })
			table.insert(taken, { lx, lz })
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
