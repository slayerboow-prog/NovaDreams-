-- MetroStyles: cómo es la CIUDAD GRANDE de cada planeta (shared/Cosmos/PlanetMetro la planifica;
-- World/PlanetMetroBuilder la dibuja). Alrededor del barrio hecho a mano (shared/Cosmos/<X>City) crece la
-- capital entera: siete distritos con su carácter, su trazado de calles y sus edificios.
--
--   Mode     "Ground" (sobre el terreno; las calles se pintan en él) | "Deck" (plataformas: sobre el mar o la
--            niebla, unidas por pasarelas)
--   Layout   "Grid" (cuadrícula) | "Zoco" (cuadrícula torcida, calles estrechas) | "Rings" (anillos y radios)
--   Radius   hasta dónde llega la ciudad (studs desde el centro del planeta)
--   Block    paso de la cuadrícula de calles · Street ancho de calle · Avenue { Every, Width } avenidas
--   Lot      paso de las parcelas (un edificio por parcela)
--   Soften   (Ground) cuánto relieve se deja bajo la ciudad: 0 = llano, 1 = el terreno tal cual
--   DeckY    (Deck) altura de las plataformas sobre la de aterrizaje; DeckClear: hueco mínimo con el terreno
--   Avoid    { { X, Z, R } } sitios del paisaje que la ciudad respeta (lagos helados, salinas, claros…)
--   Downtown (opcional) cuánto más altos son los edificios cerca del centro
--   Districts { Id, Name, Icon, X, Z, Mix = { [Kind] = peso }, Floors = { min, max }, Plaza = probabilidad }
--   Landmark { X, Z, R, Kind, Name } el gran monumento de la ciudad (lo dibuja PlanetMetroBuilder; ningún
--            solar dentro de R)
--   Look     colores y materiales (nombres de Enum.Material) para PlanetMetroBuilder
--   (calles: solo materiales de terreno que el planeta pinta con su color: <Planeta>.TerrainColors)
--
-- Tipos de edificio (Kind): Bloque, Torre, Rascacielos, Casa, Cupula, Nave, Fundicion, Bunker, Mercado, Plaza,
-- Parque, Arbol, Choza, Globo, Mastil, TorreViento, Chatarra, Jardin.
-- Tono (regla del dueño): ciudades de verdad para 13-15 años, nada de parque infantil.

local rgb = Color3.fromRGB

local MetroStyles = {}

MetroStyles.Kinds = {
	"Bloque", "Torre", "Rascacielos", "Casa", "Cupula", "Nave", "Fundicion", "Bunker", "Mercado",
	"Plaza", "Parque", "Arbol", "Choza", "Globo", "Mastil", "TorreViento", "Chatarra", "Jardin",
	"Aguja", "Tanque",
}

MetroStyles.Planets = {
	-- TEFRA · Bastión Ceniza: ciudad-fortaleza industrial en guerra, basalto y hollín entre coladas de lava
	Tefra = {
		Name = "Bastión Ceniza",
		Mode = "Ground",
		Layout = "Grid",
		Radius = 1000,
		Block = 140,
		Street = 24,
		Avenue = { Every = 3, Width = 34 },
		Lot = 44,
		Soften = 0.2,
		StreetMaterial = "Basalt",
		AvenueMaterial = "Slate", -- (solo materiales con color propio de Tefra: Tefra.TerrainColors)
		Seed = 41,
		Landmark = { X = 0, Z = -560, R = 74, Kind = "Ciudadela", Name = "La Forja Mayor" },
		Districts = {
			{ Id = "Fundiciones", Name = "Fundiciones del Norte", Icon = "🏭", X = 0, Z = -760, Mix = { Fundicion = 4, Nave = 3, Bloque = 1 }, Floors = { 2, 4 }, Plaza = 0.03 },
			{ Id = "Barracas", Name = "Barracas de la Guardia", Icon = "🛡️", X = 760, Z = -200, Mix = { Bunker = 3, Aguja = 1, Bloque = 2, Mastil = 1 }, Floors = { 2, 5 }, Plaza = 0.05 },
			{ Id = "Hollin", Name = "Barrio Hollín", Icon = "🏚️", X = -760, Z = -300, Mix = { Bloque = 5, Casa = 2, Mercado = 1 }, Floors = { 2, 5 }, Plaza = 0.07 },
			{ Id = "Azufre", Name = "Mercado del Azufre", Icon = "⚖️", X = -420, Z = 720, Mix = { Mercado = 4, Bloque = 2, Casa = 1 }, Floors = { 1, 3 }, Plaza = 0.12 },
			{ Id = "Refugios", Name = "Refugios de Ovilla", Icon = "⛺", X = 520, Z = 700, Mix = { Bloque = 3, Casa = 3, Parque = 1 }, Floors = { 1, 3 }, Plaza = 0.08 },
			{ Id = "Blindados", Name = "Cementerio de Blindados", Icon = "⚙️", X = 860, Z = 300, Mix = { Chatarra = 4, Nave = 2 }, Floors = { 1, 2 }, Plaza = 0.02 },
			{ Id = "Chimeneas", Name = "Las Chimeneas", Icon = "🔥", X = -840, Z = 320, Mix = { Fundicion = 3, Aguja = 2, Torre = 1 }, Floors = { 3, 7 }, Plaza = 0.03 },
		},
		Look = {
			Walls = { rgb(44, 38, 40), rgb(60, 50, 50), rgb(32, 28, 30), rgb(74, 60, 56) },
			WallMaterial = "Basalt",
			Trim = rgb(24, 20, 22),
			TrimMaterial = "Metal",
			Window = rgb(60, 30, 20),
			WindowNight = rgb(255, 140, 60),
			Roof = rgb(36, 30, 32),
			RoofKind = "Spire",
			Accent = rgb(255, 96, 32),
			Glow = rgb(255, 100, 30),
			Strip = rgb(255, 100, 30),
			Awning = rgb(150, 40, 30),
			Ground = rgb(50, 44, 44),
			Lamp = rgb(255, 160, 80),
			Metal = rgb(60, 54, 54),
			Leaf = rgb(70, 64, 52),
			Trunk = rgb(40, 34, 30),
		},
	},

	-- SIROCO · Puerto Calcina: adobe, cúpulas, torres de viento y chatarra de carreras en el desierto
	Siroco = {
		Name = "Puerto Calcina",
		Mode = "Ground",
		Layout = "Zoco",
		Radius = 1060,
		Block = 96,
		Street = 16,
		Avenue = { Every = 4, Width = 30 },
		Lot = 34,
		Soften = 0.25,
		StreetMaterial = "Ground", -- (la tierra pisada de la ciudad; avenidas de piedra roja del cañón)
		AvenueMaterial = "Sandstone",
		Seed = 17,
		Landmark = { X = 0, Z = -340, R = 70, Kind = "Puerta", Name = "La Puerta del Sol" },
		Avoid = { { X = 760, Z = -300, R = 280 } }, -- (las Salinas Blancas)
		Districts = {
			{ Id = "ZocoViejo", Name = "Zoco Viejo", Icon = "🏺", X = -520, Z = -320, Mix = { Casa = 4, Mercado = 3, Cupula = 1 }, Floors = { 1, 3 }, Plaza = 0.08 },
			{ Id = "Pozos", Name = "Barrio de los Pozos", Icon = "💧", X = 460, Z = -460, Mix = { Casa = 4, TorreViento = 2, Jardin = 1 }, Floors = { 1, 2 }, Plaza = 0.07 },
			{ Id = "Chatarrerias", Name = "Las Chatarrerías", Icon = "🔧", X = 680, Z = 260, Mix = { Chatarra = 4, Nave = 2, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.03 },
			{ Id = "Escuderias", Name = "Ciudad de las Escuderías", Icon = "🏁", X = 0, Z = 700, Mix = { Nave = 4, Bloque = 2, Plaza = 1 }, Floors = { 1, 3 }, Plaza = 0.05 },
			{ Id = "Velas", Name = "Barrio de las Velas", Icon = "⛵", X = -680, Z = 360, Mix = { Casa = 3, TorreViento = 2, Mercado = 1 }, Floors = { 1, 3 }, Plaza = 0.06 },
			{ Id = "DunasAltas", Name = "Dunas Altas", Icon = "🏜️", X = -160, Z = -780, Mix = { Aguja = 2, Cupula = 2, Casa = 2, Bloque = 1 }, Floors = { 2, 5 }, Plaza = 0.05 },
			{ Id = "PuertoSeco", Name = "Puerto Seco", Icon = "⚓", X = 420, Z = 760, Mix = { Nave = 3, Mercado = 2, Chatarra = 1 }, Floors = { 1, 2 }, Plaza = 0.05 },
		},
		Look = {
			Walls = { rgb(220, 180, 126), rgb(204, 160, 108), rgb(232, 204, 158), rgb(190, 140, 94) },
			WallMaterial = "Sandstone",
			Trim = rgb(130, 96, 66),
			TrimMaterial = "Metal",
			Window = rgb(60, 110, 140),
			WindowNight = rgb(120, 220, 255),
			Roof = rgb(236, 214, 176),
			RoofKind = "Dome",
			Accent = rgb(60, 200, 255),
			Glow = rgb(80, 210, 255),
			Strip = rgb(80, 210, 255),
			Awning = rgb(200, 52, 40),
			Ground = rgb(196, 156, 108),
			Lamp = rgb(255, 210, 140),
			Metal = rgb(120, 100, 80),
			Leaf = rgb(90, 150, 70),
			Trunk = rgb(120, 90, 60),
		},
	},

	-- TÁLASA · Abisalia: plataformas blancas sobre el mar, cúpulas de cristal, muelles y jardines de algas
	Talasa = {
		Name = "Abisalia",
		Mode = "Deck",
		Layout = "Grid",
		Radius = 880,
		Block = 116,
		Street = 12,
		Lot = 46,
		DeckY = 1,
		DeckClear = 3,
		Seed = 23,
		Landmark = { X = 0, Z = -340, R = 70, Kind = "Reactor", Name = "El Reactor de Mareas" },
		Districts = {
			{ Id = "Cupulas", Name = "Las Cúpulas", Icon = "💠", X = -460, Z = -420, Mix = { Cupula = 4, Torre = 2, Jardin = 1 }, Floors = { 2, 5 }, Plaza = 0.06 },
			{ Id = "Nacar", Name = "Muelles de Nácar", Icon = "⚓", X = 520, Z = -380, Mix = { Nave = 3, Mercado = 3, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.05 },
			{ Id = "Algas", Name = "Jardines de Algas", Icon = "🌿", X = -620, Z = 260, Mix = { Jardin = 4, Casa = 2 }, Floors = { 1, 2 }, Plaza = 0.08 },
			{ Id = "Buzos", Name = "Barrio de los Buzos", Icon = "🤿", X = 180, Z = 640, Mix = { Casa = 4, Bloque = 2, Cupula = 1 }, Floors = { 1, 3 }, Plaza = 0.07 },
			{ Id = "Faro", Name = "Anillo del Faro", Icon = "🗼", X = 0, Z = -700, Mix = { Torre = 3, Aguja = 1, Plaza = 1, Cupula = 1 }, Floors = { 3, 8 }, Plaza = 0.08 },
			{ Id = "Astilleros", Name = "Astilleros Hondos", Icon = "🛠️", X = 660, Z = 300, Mix = { Nave = 4, Bloque = 1 }, Floors = { 1, 3 }, Plaza = 0.03 },
			{ Id = "Marea", Name = "Barrio Marea", Icon = "🌊", X = -300, Z = 680, Mix = { Casa = 3, Cupula = 2, Mercado = 1 }, Floors = { 1, 3 }, Plaza = 0.06 },
		},
		Look = {
			Walls = { rgb(232, 238, 244), rgb(206, 216, 228), rgb(180, 192, 208), rgb(244, 246, 250) },
			WallMaterial = "SmoothPlastic",
			Trim = rgb(44, 60, 86),
			TrimMaterial = "Metal",
			Window = rgb(50, 120, 180),
			WindowNight = rgb(110, 210, 255),
			Roof = rgb(170, 210, 236),
			RoofKind = "Flat",
			Accent = rgb(50, 180, 255),
			Glow = rgb(70, 200, 255),
			Strip = rgb(70, 200, 255),
			Awning = rgb(40, 140, 200),
			Ground = rgb(214, 222, 230),
			Lamp = rgb(150, 220, 255),
			Metal = rgb(120, 136, 156),
			Leaf = rgb(40, 140, 110),
			Trunk = rgb(60, 90, 80),
			Deck = rgb(196, 206, 216),
			DeckMaterial = "Concrete",
			Pylon = rgb(90, 104, 124),
		},
	},

	-- NIVALIS · Fortaleza Albor: ciudad antigua de piedra y hielo en anillos, tejados de pizarra nevados
	Nivalis = {
		Name = "Fortaleza Albor",
		Mode = "Ground",
		Layout = "Rings",
		Radius = 900,
		Block = 150,
		Street = 20,
		Rays = 8,
		Lot = 40,
		Soften = 0.18,
		StreetMaterial = "Slate", -- (losas de piedra gris; avenidas de piedra oscura)
		AvenueMaterial = "Basalt",
		Seed = 31,
		Landmark = { X = 380, Z = 0, R = 74, Kind = "Palacio", Name = "El Palacio de Hielo" },
		-- (el Lago de los Ahogados, las Fuentes Calientes y la lengua del Glaciar Azul se quedan como están)
		Avoid = { { X = -380, Z = 300, R = 150 }, { X = 420, Z = 380, R = 60 }, { X = -620, Z = -520, R = 240 } },
		Districts = {
			{ Id = "CiudadAlta", Name = "Ciudad Alta", Icon = "🏰", X = 0, Z = -560, Mix = { Aguja = 3, Torre = 2, Bloque = 2, Plaza = 1 }, Floors = { 4, 8 }, Plaza = 0.06 },
			{ Id = "Faroleros", Name = "Barrio de los Faroleros", Icon = "🏮", X = 540, Z = -260, Mix = { Casa = 3, Cupula = 2, Bloque = 2 }, Floors = { 2, 4 }, Plaza = 0.06 },
			{ Id = "Lonja", Name = "Lonja del Hielo", Icon = "🧊", X = 560, Z = 380, Mix = { Mercado = 3, Nave = 2, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.08 },
			{ Id = "Pastores", Name = "Barrio de los Pastores", Icon = "🐑", X = 0, Z = 620, Mix = { Casa = 4, Parque = 1 }, Floors = { 1, 2 }, Plaza = 0.05 },
			{ Id = "Cuarteles", Name = "Cuarteles del Regente", Icon = "⚔️", X = -560, Z = 380, Mix = { Aguja = 2, Bloque = 3, Torre = 2 }, Floors = { 3, 6 }, Plaza = 0.04 },
			{ Id = "Cantera", Name = "Cantera Vieja", Icon = "⛏️", X = -620, Z = -200, Mix = { Nave = 3, Chatarra = 1, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.03 },
			{ Id = "Fraguas", Name = "Barrio de las Fraguas", Icon = "🔨", X = -300, Z = -700, Mix = { Fundicion = 2, Casa = 3 }, Floors = { 1, 3 }, Plaza = 0.04 },
		},
		Look = {
			Walls = { rgb(228, 238, 248), rgb(204, 222, 242), rgb(178, 204, 232), rgb(242, 246, 252) },
			WallMaterial = "SmoothPlastic",
			Trim = rgb(90, 140, 196),
			TrimMaterial = "Metal",
			Window = rgb(70, 150, 220),
			WindowNight = rgb(140, 225, 255),
			Roof = rgb(196, 222, 246),
			RoofKind = "Spire",
			Accent = rgb(90, 200, 255),
			Glow = rgb(110, 220, 255),
			Strip = rgb(110, 220, 255),
			Awning = rgb(60, 120, 200),
			Ground = rgb(200, 214, 230),
			Lamp = rgb(170, 230, 255),
			Metal = rgb(110, 130, 156),
			Leaf = rgb(52, 84, 70),
			Trunk = rgb(70, 56, 46),
			Snow = rgb(244, 248, 254),
		},
	},

	-- UMBRÍA · Raíz Honda: ciudad orgánica entre árboles gigantes, chozas en zancos y pasarelas
	Umbria = {
		Name = "Raíz Honda",
		Mode = "Ground",
		Layout = "Zoco",
		Radius = 840,
		Block = 140,
		Street = 18,
		Lot = 46,
		Soften = 0.3,
		StreetMaterial = "Sandstone", -- (barro oscuro; avenidas de piedras con musgo)
		AvenueMaterial = "Cobblestone",
		Avenue = { Every = 3, Width = 24 },
		Seed = 29,
		Landmark = { X = 0, Z = -390, R = 74, Kind = "ArbolMadre", Name = "El Árbol Madre" },
		Avoid = { { X = 340, Z = -300, R = 190 } }, -- (el Claro Muerto: pelado por el Enjambre)
		Districts = {
			{ Id = "Troncos", Name = "Bosque de los Troncos", Icon = "🌳", X = -500, Z = -460, Mix = { Arbol = 5, Choza = 2 }, Floors = { 1, 2 }, Plaza = 0.04 },
			{ Id = "Pasarelas", Name = "Las Pasarelas", Icon = "🌉", X = 520, Z = -440, Mix = { Choza = 4, Arbol = 2 }, Floors = { 1, 2 }, Plaza = 0.05 },
			{ Id = "Savia", Name = "Mercado de la Savia", Icon = "🍯", X = 700, Z = 200, Mix = { Mercado = 4, Choza = 2 }, Floors = { 1, 2 }, Plaza = 0.1 },
			{ Id = "Vivero", Name = "El Vivero", Icon = "🌱", X = 140, Z = 700, Mix = { Jardin = 3, Parque = 2, Choza = 1 }, Floors = { 1, 2 }, Plaza = 0.06 },
			{ Id = "Barricadas", Name = "Talleres de las Barricadas", Icon = "🛠️", X = -400, Z = 640, Mix = { Nave = 3, Bunker = 2, Choza = 1 }, Floors = { 1, 2 }, Plaza = 0.03 },
			{ Id = "Cascada", Name = "Barrio Cascada", Icon = "💦", X = -780, Z = 160, Mix = { Choza = 3, Casa = 2, Arbol = 1 }, Floors = { 1, 2 }, Plaza = 0.06 },
			{ Id = "Nidos", Name = "Nidos de Planeadores", Icon = "🪂", X = 0, Z = -800, Mix = { Mastil = 3, Choza = 2, Arbol = 1 }, Floors = { 2, 4 }, Plaza = 0.04 },
		},
		Look = {
			Walls = { rgb(206, 196, 168), rgb(180, 170, 146), rgb(150, 132, 100), rgb(220, 212, 190) },
			WallMaterial = "SmoothPlastic",
			Trim = rgb(96, 70, 46),
			TrimMaterial = "Wood",
			Window = rgb(60, 120, 140),
			WindowNight = rgb(120, 230, 255),
			Roof = rgb(150, 190, 170),
			RoofKind = "Dome",
			Accent = rgb(80, 220, 255),
			Glow = rgb(110, 230, 255),
			Strip = rgb(110, 230, 255),
			Awning = rgb(200, 90, 40),
			Ground = rgb(92, 76, 56),
			Lamp = rgb(170, 240, 255),
			Metal = rgb(90, 84, 72),
			Leaf = rgb(46, 120, 52),
			Trunk = rgb(86, 64, 44),
		},
	},

	-- MIASMA · Anclaje Siete: plataformas de chapa colgadas sobre la niebla tóxica, globos y pararrayos
	Miasma = {
		Name = "Anclaje Siete",
		Mode = "Deck",
		Layout = "Grid",
		Radius = 960,
		Block = 126,
		Street = 12,
		Lot = 48,
		DeckY = 1,
		DeckClear = 24,
		Rescue = 12, -- (quien cae más de 12 studs por debajo de las plataformas sale a la pasarela más cercana)
		Seed = 37,
		Landmark = { X = 0, Z = -340, R = 70, Kind = "ReactorVerde", Name = "El Reactor Verde" },
		Districts = {
			{ Id = "Globos", Name = "Muelles de Globos", Icon = "🎈", X = -520, Z = -420, Mix = { Globo = 4, Nave = 2 }, Floors = { 1, 2 }, Plaza = 0.04 },
			{ Id = "Filtros", Name = "Fábrica de Filtros", Icon = "🏭", X = 560, Z = -400, Mix = { Tanque = 4, Fundicion = 2, Nave = 1 }, Floors = { 2, 4 }, Plaza = 0.03 },
			{ Id = "Oxido", Name = "Barrio Óxido", Icon = "🔩", X = 680, Z = 280, Mix = { Bloque = 3, Tanque = 2, Cupula = 1, Mercado = 1 }, Floors = { 2, 5 }, Plaza = 0.06 },
			{ Id = "Pararrayos", Name = "Los Pararrayos", Icon = "⚡", X = 0, Z = -760, Mix = { Mastil = 3, Tanque = 2, Torre = 2 }, Floors = { 3, 6 }, Plaza = 0.03 },
			{ Id = "Flota", Name = "Hangares de la Flota", Icon = "✈️", X = -720, Z = 300, Mix = { Nave = 4, Bunker = 1 }, Floors = { 1, 3 }, Plaza = 0.03 },
			{ Id = "Colgante", Name = "Mercado Colgante", Icon = "🛒", X = 160, Z = 700, Mix = { Mercado = 4, Casa = 2 }, Floors = { 1, 2 }, Plaza = 0.1 },
			{ Id = "Silbido", Name = "Barrio Silbido", Icon = "🌫️", X = -320, Z = 700, Mix = { Casa = 3, Globo = 1, Bloque = 1 }, Floors = { 1, 3 }, Plaza = 0.06 },
		},
		Look = {
			Walls = { rgb(72, 78, 72), rgb(92, 98, 90), rgb(56, 60, 58), rgb(110, 112, 100) },
			WallMaterial = "Metal",
			Trim = rgb(40, 44, 42),
			TrimMaterial = "Metal",
			Window = rgb(50, 90, 40),
			WindowNight = rgb(170, 255, 90),
			Roof = rgb(84, 90, 84),
			RoofKind = "Dome",
			Accent = rgb(140, 255, 60),
			Glow = rgb(140, 255, 60),
			Strip = rgb(140, 255, 60),
			Awning = rgb(90, 130, 40),
			Ground = rgb(80, 84, 78),
			Lamp = rgb(190, 255, 120),
			Metal = rgb(70, 74, 70),
			Leaf = rgb(90, 140, 50),
			Trunk = rgb(60, 56, 50),
			Deck = rgb(76, 80, 76),
			DeckMaterial = "DiamondPlate",
			Pylon = rgb(52, 54, 52),
		},
	},

	-- VÉRTICE · la megaciudad: rascacielos de neón, avenidas anchas, anuncios y torres del crédito
	Vertice = {
		Name = "Vértice",
		Mode = "Ground",
		Layout = "Grid",
		Radius = 1100,
		Block = 150,
		Street = 28,
		Avenue = { Every = 3, Width = 44 },
		Lot = 50,
		Soften = 1, -- (el Nivel Bajo ya es llano: el terreno se queda como está, con sus canales)
		StreetMaterial = "Asphalt",
		AvenueMaterial = "Asphalt",
		Downtown = 2.2,
		Seed = 53,
		Landmark = { X = 0, Z = -340, R = 70, Kind = "TorreAnillos", Name = "La Torre del Crédito" },
		Districts = {
			{ Id = "Credito", Name = "Torres del Crédito", Icon = "🏦", X = 0, Z = -520, Mix = { Rascacielos = 6, Torre = 1 }, Floors = { 14, 34 }, Plaza = 0.04 },
			{ Id = "Neon", Name = "Barrio Neón", Icon = "🌃", X = 520, Z = -280, Mix = { Torre = 3, Rascacielos = 2, Bloque = 2 }, Floors = { 6, 16 }, Plaza = 0.05 },
			{ Id = "MercadoGris", Name = "Mercado Gris", Icon = "🛍️", X = 560, Z = 360, Mix = { Mercado = 3, Bloque = 3 }, Floors = { 3, 7 }, Plaza = 0.08 },
			{ Id = "Colmenas", Name = "Las Colmenas", Icon = "🏢", X = 0, Z = 620, Mix = { Bloque = 5, Torre = 1 }, Floors = { 8, 18 }, Plaza = 0.04 },
			{ Id = "Aliviaderos", Name = "Los Aliviaderos", Icon = "🚧", X = -600, Z = 420, Mix = { Nave = 3, Chatarra = 2, Bloque = 1 }, Floors = { 2, 4 }, Plaza = 0.03 },
			{ Id = "Cupula", Name = "Distrito Cúpula", Icon = "🔭", X = -560, Z = -360, Mix = { Cupula = 3, Torre = 2, Jardin = 1 }, Floors = { 5, 12 }, Plaza = 0.06 },
			{ Id = "Antes", Name = "Los Barrios de Antes", Icon = "🏘️", X = -260, Z = -760, Mix = { Casa = 3, Bloque = 2, Parque = 1 }, Floors = { 2, 4 }, Plaza = 0.07 },
		},
		Look = {
			Walls = { rgb(40, 30, 70), rgb(60, 42, 104), rgb(30, 24, 54), rgb(84, 62, 134) },
			WallMaterial = "Glass",
			Trim = rgb(24, 18, 40),
			TrimMaterial = "Metal",
			Window = rgb(90, 60, 170),
			WindowNight = rgb(230, 150, 255),
			Roof = rgb(34, 26, 56),
			RoofKind = "Flat",
			Accent = rgb(255, 50, 200),
			Glow = rgb(190, 90, 255),
			Strip = rgb(190, 90, 255),
			Awning = rgb(255, 50, 200),
			Ground = rgb(60, 52, 80),
			Lamp = rgb(220, 170, 255),
			Metal = rgb(56, 50, 76),
			Leaf = rgb(60, 130, 90),
			Trunk = rgb(60, 50, 44),
			Neon = { rgb(255, 50, 200), rgb(60, 220, 255), rgb(170, 80, 255), rgb(255, 120, 230) },
		},
	},
}

function MetroStyles.get(id: string): { [string]: any }?
	return MetroStyles.Planets[id]
end

return MetroStyles
