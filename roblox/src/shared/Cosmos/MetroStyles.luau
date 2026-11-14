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
		Districts = {
			{ Id = "Fundiciones", Name = "Fundiciones del Norte", Icon = "🏭", X = 0, Z = -760, Mix = { Fundicion = 4, Nave = 3, Bloque = 1 }, Floors = { 2, 4 }, Plaza = 0.03 },
			{ Id = "Barracas", Name = "Barracas de la Guardia", Icon = "🛡️", X = 760, Z = -200, Mix = { Bunker = 4, Bloque = 2, Mastil = 1 }, Floors = { 1, 3 }, Plaza = 0.05 },
			{ Id = "Hollin", Name = "Barrio Hollín", Icon = "🏚️", X = -760, Z = -300, Mix = { Bloque = 5, Casa = 2, Mercado = 1 }, Floors = { 2, 5 }, Plaza = 0.07 },
			{ Id = "Azufre", Name = "Mercado del Azufre", Icon = "⚖️", X = -420, Z = 720, Mix = { Mercado = 4, Bloque = 2, Casa = 1 }, Floors = { 1, 3 }, Plaza = 0.12 },
			{ Id = "Refugios", Name = "Refugios de Ovilla", Icon = "⛺", X = 520, Z = 700, Mix = { Bloque = 3, Casa = 3, Parque = 1 }, Floors = { 1, 3 }, Plaza = 0.08 },
			{ Id = "Blindados", Name = "Cementerio de Blindados", Icon = "⚙️", X = 860, Z = 300, Mix = { Chatarra = 4, Nave = 2 }, Floors = { 1, 2 }, Plaza = 0.02 },
			{ Id = "Chimeneas", Name = "Las Chimeneas", Icon = "🔥", X = -840, Z = 320, Mix = { Fundicion = 3, Torre = 2, Bloque = 1 }, Floors = { 3, 7 }, Plaza = 0.03 },
		},
		Look = {
			Walls = { rgb(62, 58, 58), rgb(84, 76, 72), rgb(48, 46, 50), rgb(104, 92, 84) },
			WallMaterial = "Basalt",
			Trim = rgb(38, 34, 34),
			TrimMaterial = "Metal",
			Window = rgb(40, 34, 30),
			WindowNight = rgb(255, 150, 70),
			Roof = rgb(46, 42, 42),
			RoofKind = "Parapet",
			Accent = rgb(255, 96, 32),
			Glow = rgb(255, 110, 40),
			Ground = rgb(58, 54, 52),
			Lamp = rgb(255, 170, 90),
			Metal = rgb(70, 66, 64),
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
		Avoid = { { X = 760, Z = -300, R = 280 } }, -- (las Salinas Blancas)
		Districts = {
			{ Id = "ZocoViejo", Name = "Zoco Viejo", Icon = "🏺", X = -520, Z = -320, Mix = { Casa = 4, Mercado = 3, Cupula = 1 }, Floors = { 1, 3 }, Plaza = 0.08 },
			{ Id = "Pozos", Name = "Barrio de los Pozos", Icon = "💧", X = 460, Z = -460, Mix = { Casa = 4, TorreViento = 2, Jardin = 1 }, Floors = { 1, 2 }, Plaza = 0.07 },
			{ Id = "Chatarrerias", Name = "Las Chatarrerías", Icon = "🔧", X = 680, Z = 260, Mix = { Chatarra = 4, Nave = 2, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.03 },
			{ Id = "Escuderias", Name = "Ciudad de las Escuderías", Icon = "🏁", X = 0, Z = 700, Mix = { Nave = 4, Bloque = 2, Plaza = 1 }, Floors = { 1, 3 }, Plaza = 0.05 },
			{ Id = "Velas", Name = "Barrio de las Velas", Icon = "⛵", X = -680, Z = 360, Mix = { Casa = 3, TorreViento = 2, Mercado = 1 }, Floors = { 1, 3 }, Plaza = 0.06 },
			{ Id = "DunasAltas", Name = "Dunas Altas", Icon = "🏜️", X = -160, Z = -780, Mix = { Casa = 3, Cupula = 2, Bloque = 1 }, Floors = { 2, 4 }, Plaza = 0.05 },
			{ Id = "PuertoSeco", Name = "Puerto Seco", Icon = "⚓", X = 420, Z = 760, Mix = { Nave = 3, Mercado = 2, Chatarra = 1 }, Floors = { 1, 2 }, Plaza = 0.05 },
		},
		Look = {
			Walls = { rgb(214, 172, 120), rgb(198, 150, 100), rgb(226, 196, 150), rgb(184, 128, 86) },
			WallMaterial = "Sandstone",
			Trim = rgb(150, 100, 64),
			TrimMaterial = "WoodPlanks",
			Window = rgb(52, 40, 30),
			WindowNight = rgb(255, 196, 110),
			Roof = rgb(232, 210, 172),
			RoofKind = "Dome",
			Accent = rgb(40, 120, 150),
			Glow = rgb(255, 180, 90),
			Ground = rgb(196, 156, 108),
			Lamp = rgb(255, 200, 130),
			Metal = rgb(120, 96, 76),
			Leaf = rgb(110, 140, 70),
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
		Districts = {
			{ Id = "Cupulas", Name = "Las Cúpulas", Icon = "💠", X = -460, Z = -420, Mix = { Cupula = 4, Torre = 2, Jardin = 1 }, Floors = { 2, 5 }, Plaza = 0.06 },
			{ Id = "Nacar", Name = "Muelles de Nácar", Icon = "⚓", X = 520, Z = -380, Mix = { Nave = 3, Mercado = 3, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.05 },
			{ Id = "Algas", Name = "Jardines de Algas", Icon = "🌿", X = -620, Z = 260, Mix = { Jardin = 4, Casa = 2 }, Floors = { 1, 2 }, Plaza = 0.08 },
			{ Id = "Buzos", Name = "Barrio de los Buzos", Icon = "🤿", X = 180, Z = 640, Mix = { Casa = 4, Bloque = 2, Cupula = 1 }, Floors = { 1, 3 }, Plaza = 0.07 },
			{ Id = "Faro", Name = "Anillo del Faro", Icon = "🗼", X = 0, Z = -700, Mix = { Torre = 3, Plaza = 1, Cupula = 1 }, Floors = { 3, 7 }, Plaza = 0.08 },
			{ Id = "Astilleros", Name = "Astilleros Hondos", Icon = "🛠️", X = 660, Z = 300, Mix = { Nave = 4, Bloque = 1 }, Floors = { 1, 3 }, Plaza = 0.03 },
			{ Id = "Marea", Name = "Barrio Marea", Icon = "🌊", X = -300, Z = 680, Mix = { Casa = 3, Cupula = 2, Mercado = 1 }, Floors = { 1, 3 }, Plaza = 0.06 },
		},
		Look = {
			Walls = { rgb(236, 242, 246), rgb(214, 230, 238), rgb(196, 220, 232), rgb(244, 240, 230) },
			WallMaterial = "SmoothPlastic",
			Trim = rgb(70, 150, 180),
			TrimMaterial = "Metal",
			Window = rgb(60, 120, 150),
			WindowNight = rgb(120, 230, 255),
			Roof = rgb(150, 210, 230),
			RoofKind = "Dome",
			Accent = rgb(60, 200, 210),
			Glow = rgb(90, 220, 255),
			Ground = rgb(220, 228, 232),
			Lamp = rgb(150, 230, 255),
			Metal = rgb(150, 170, 180),
			Leaf = rgb(40, 140, 110),
			Trunk = rgb(60, 90, 80),
			Deck = rgb(206, 214, 218),
			DeckMaterial = "Concrete",
			Pylon = rgb(120, 140, 150),
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
		-- (el Lago de los Ahogados, las Fuentes Calientes y la lengua del Glaciar Azul se quedan como están)
		Avoid = { { X = -380, Z = 300, R = 150 }, { X = 420, Z = 380, R = 60 }, { X = -620, Z = -520, R = 240 } },
		Districts = {
			{ Id = "CiudadAlta", Name = "Ciudad Alta", Icon = "🏰", X = 0, Z = -560, Mix = { Torre = 3, Bloque = 3, Plaza = 1 }, Floors = { 3, 5 }, Plaza = 0.06 },
			{ Id = "Faroleros", Name = "Barrio de los Faroleros", Icon = "🏮", X = 540, Z = -260, Mix = { Casa = 5, Bloque = 1 }, Floors = { 2, 3 }, Plaza = 0.06 },
			{ Id = "Lonja", Name = "Lonja del Hielo", Icon = "🧊", X = 560, Z = 380, Mix = { Mercado = 3, Nave = 2, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.08 },
			{ Id = "Pastores", Name = "Barrio de los Pastores", Icon = "🐑", X = 0, Z = 620, Mix = { Casa = 4, Parque = 1 }, Floors = { 1, 2 }, Plaza = 0.05 },
			{ Id = "Cuarteles", Name = "Cuarteles del Regente", Icon = "⚔️", X = -560, Z = 380, Mix = { Bloque = 3, Torre = 2, Bunker = 1 }, Floors = { 2, 4 }, Plaza = 0.04 },
			{ Id = "Cantera", Name = "Cantera Vieja", Icon = "⛏️", X = -620, Z = -200, Mix = { Nave = 3, Chatarra = 1, Casa = 1 }, Floors = { 1, 2 }, Plaza = 0.03 },
			{ Id = "Fraguas", Name = "Barrio de las Fraguas", Icon = "🔨", X = -300, Z = -700, Mix = { Fundicion = 2, Casa = 3 }, Floors = { 1, 3 }, Plaza = 0.04 },
		},
		Look = {
			Walls = { rgb(150, 156, 166), rgb(128, 134, 146), rgb(176, 178, 184), rgb(112, 112, 122) },
			WallMaterial = "Cobblestone",
			Trim = rgb(90, 74, 60),
			TrimMaterial = "WoodPlanks",
			Window = rgb(40, 46, 60),
			WindowNight = rgb(255, 196, 120),
			Roof = rgb(62, 70, 86),
			RoofKind = "Pitched",
			Snow = rgb(242, 246, 252),
			Accent = rgb(110, 160, 220),
			Glow = rgb(255, 170, 90),
			Ground = rgb(170, 176, 186),
			Lamp = rgb(255, 196, 120),
			Metal = rgb(70, 74, 82),
			Leaf = rgb(52, 84, 70),
			Trunk = rgb(70, 56, 46),
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
			Walls = { rgb(122, 92, 62), rgb(104, 78, 52), rgb(140, 108, 72), rgb(96, 82, 60) },
			WallMaterial = "WoodPlanks",
			Trim = rgb(70, 52, 36),
			TrimMaterial = "Wood",
			Window = rgb(34, 40, 28),
			WindowNight = rgb(200, 255, 150),
			Roof = rgb(96, 116, 56),
			RoofKind = "Cone",
			Accent = rgb(150, 220, 90),
			Glow = rgb(170, 255, 140),
			Ground = rgb(92, 76, 56),
			Lamp = rgb(190, 255, 160),
			Metal = rgb(80, 70, 56),
			Leaf = rgb(46, 110, 52),
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
		Districts = {
			{ Id = "Globos", Name = "Muelles de Globos", Icon = "🎈", X = -520, Z = -420, Mix = { Globo = 4, Nave = 2 }, Floors = { 1, 2 }, Plaza = 0.04 },
			{ Id = "Filtros", Name = "Fábrica de Filtros", Icon = "🏭", X = 560, Z = -400, Mix = { Fundicion = 3, Nave = 2 }, Floors = { 2, 4 }, Plaza = 0.03 },
			{ Id = "Oxido", Name = "Barrio Óxido", Icon = "🔩", X = 680, Z = 280, Mix = { Bloque = 4, Casa = 2, Mercado = 1 }, Floors = { 2, 5 }, Plaza = 0.06 },
			{ Id = "Pararrayos", Name = "Los Pararrayos", Icon = "⚡", X = 0, Z = -760, Mix = { Mastil = 4, Torre = 2 }, Floors = { 3, 6 }, Plaza = 0.03 },
			{ Id = "Flota", Name = "Hangares de la Flota", Icon = "✈️", X = -720, Z = 300, Mix = { Nave = 4, Bunker = 1 }, Floors = { 1, 3 }, Plaza = 0.03 },
			{ Id = "Colgante", Name = "Mercado Colgante", Icon = "🛒", X = 160, Z = 700, Mix = { Mercado = 4, Casa = 2 }, Floors = { 1, 2 }, Plaza = 0.1 },
			{ Id = "Silbido", Name = "Barrio Silbido", Icon = "🌫️", X = -320, Z = 700, Mix = { Casa = 3, Globo = 1, Bloque = 1 }, Floors = { 1, 3 }, Plaza = 0.06 },
		},
		Look = {
			Walls = { rgb(120, 104, 84), rgb(96, 88, 78), rgb(140, 110, 80), rgb(84, 92, 86) },
			WallMaterial = "CorrodedMetal",
			Trim = rgb(60, 56, 52),
			TrimMaterial = "Metal",
			Window = rgb(40, 52, 40),
			WindowNight = rgb(200, 255, 120),
			Roof = rgb(90, 80, 70),
			RoofKind = "Pitched",
			Accent = rgb(190, 230, 70),
			Glow = rgb(190, 255, 110),
			Ground = rgb(92, 90, 84),
			Lamp = rgb(210, 255, 140),
			Metal = rgb(80, 78, 74),
			Leaf = rgb(90, 120, 60),
			Trunk = rgb(70, 60, 50),
			Deck = rgb(88, 86, 80),
			DeckMaterial = "DiamondPlate",
			Pylon = rgb(60, 58, 56),
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
			Walls = { rgb(60, 66, 80), rgb(40, 44, 56), rgb(84, 92, 108), rgb(120, 128, 140) },
			WallMaterial = "Glass",
			Trim = rgb(30, 32, 40),
			TrimMaterial = "Metal",
			Window = rgb(50, 70, 100),
			WindowNight = rgb(140, 200, 255),
			Roof = rgb(40, 42, 50),
			RoofKind = "Flat",
			Neon = { rgb(255, 60, 180), rgb(40, 220, 255), rgb(255, 200, 40), rgb(140, 90, 255) },
			Accent = rgb(255, 60, 180),
			Glow = rgb(40, 220, 255),
			Ground = rgb(70, 72, 80),
			Lamp = rgb(200, 230, 255),
			Metal = rgb(60, 64, 72),
			Leaf = rgb(60, 130, 90),
			Trunk = rgb(60, 50, 44),
		},
	},
}

function MetroStyles.get(id: string): { [string]: any }?
	return MetroStyles.Planets[id]
end

return MetroStyles
