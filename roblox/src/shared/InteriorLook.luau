-- InteriorLook: qué textura realista de los packs del dueño lleva cada suelo, pared, techo, encimera,
-- rodapié y escalón de los INTERIORES de Valmar (casas, pisos, villas, tiendas, bares, oficinas,
-- hospital, colegio, hotel, naves, juzgado, museo…). Lo aplica en vivo el servidor
-- (World/InteriorDress), después de las calles (World/StreetDress) y las fachadas (World/HouseDress).
--
-- Cuentas puras (sin Instances): se prueban fuera de Roblox (scripts/test-interiorlook.luau).
--
--   * Como en HouseLook: se viste pieza a pieza (part.MaterialVariant) y, si hace falta, se cambia el
--     MATERIAL DE LA PIEZA al BaseMaterial del variant (en un servidor real no se puede cambiar el
--     BaseMaterial de un variant de la Tienda), guardando su física de antes (Convertible).
--   * Escala interior (una persona mide ~5 studs): cada aspecto lleva su StudsPerTile (Studs). Para no
--     cambiar la escala de los variants que ya usan las fachadas o las calles, World/InteriorDress
--     pone en MaterialService una COPIA de cada variant con la escala de aquí («U_In_<aspecto>_<n>»).
--       - tarima/parqué: 6 studs por repetición (tablas de ~0,5-1 stud de ancho)
--       - baldosa de suelo 5-6, azulejo de pared 4 (piezas de ~1 stud, no baldosas gigantes)
--       - mármol 8, moqueta 6, hormigón 12, yeso/pintura 8-10, encimeras y rodapiés 4
--   * Estancia: el tipo de sala (Interior_<Tipo> de World/Interiors, el cartel del local —atributo Shop—
--     o, en la ciudad, el edificio que la contiene: Hospital, Colegio, Hotel…) -> categoría (Categories).
--     Pieza: por NOMBRE (Roles) y MATERIAL. Así:
--       SUELOS   parqué (casas, pisos, dormitorios, juzgado) · baldosa (cocina, baño, tiendas, bares)
--                mármol (villa, portal, oficinas, banco, hotel, ayuntamiento, museo) · terrazo
--                (estación, centro comercial, escaleras de los bloques) · linóleo (hospital, colegio)
--                moqueta (oficinas; estampada en teatro y cine) · hormigón (naves, talleres, cuartel,
--                garajes, cárcel) · pizarra y granito donde la sala ya los traía
--       PAREDES  pintura/enlucido liso (casi todas, con su color) · papel pintado (paños de color de los
--                dormitorios, cuartos de arriba de algunas casas, la mitad de las villas, el hotel) ·
--                azulejo (cocina y baño) · ladrillo visto (la pared del fondo de algunos bares) ·
--                ladrillo pintado (naves, talleres, cuartel)
--       TECHOS   yeso liso blanco · placas de techo registrable (oficinas, colegio, hospital, tiendas)
--       OTROS    encimeras de granito, mármol o madera (según su material) · rodapiés de madera (los
--                blancos lacados se quedan lisos) · peldaños de madera en las casas y de terrazo en los
--                bloques (los de la escalera de emergencia, de hormigón)
--   * Variedad fija por vivienda o local (Seed: la clave de la sala, «id:3B», o el sitio del edificio):
--     dos casas vecinas no tienen el mismo parqué, pero la misma casa siempre sale igual.
--   * El color de cada pieza se conserva: solo se aclara un poco (Whiten) porque estas texturas traen su
--     color y Roblox lo multiplica por el de la pieza.
--   * Nunca: cristales, neón, puertas, muebles (salvo encimeras, que son la superficie de la cocina),
--     lámparas, pantallas, lo que ya lleva variant, lo invisible, mallas con textura propia. Fuera de las
--     salas del cielo solo se miran los nombres de suelo/techo/pared interior de TownRoles (la fachada
--     «Wall» de los edificios es de HouseDress). No añade piezas.
--   * Elección solo por NOMBRE (las texturas no se pueden mirar desde un script): cada fila dice por qué.
--     Los packs oficiales «Duvall Drive» y «Modern City Materials» no tienen su lista de nombres en los
--     docs: sus candidatos buscan por palabras (Find) y por el BaseMaterial que traigan; si no encajan,
--     se usan los del Mega Pack.

local InteriorLook = {}

-- Packs que carga además de los de shared/UserMaterialChoice y StreetLook (oficiales de Roblox)
InteriorLook.Packs = {
	{ Id = 10841357434, Short = "Duvall", Title = "Realistic Material Variants – Duvall Drive (Roblox)" },
	{ Id = 13168345645, Short = "MCity", Title = "Modern City Materials Pack (Roblox)" },
}

export type Candidate = {
	Pack: string,
	Name: string?, -- nombre exacto (de los docs)
	Find: { string }?, -- o palabras que tiene que llevar el nombre (minúsculas), si no se sabe el exacto
	Avoid: { string }?, -- palabras que no puede llevar
	From: string?, -- BaseMaterial según el doc (nil: el que traiga)
}
export type Look = {
	Options: { Candidate }, -- en orden: los primeros Variety que carguen se reparten; el resto, respaldo
	Variety: number,
	Weights: { number }?,
	Studs: number, -- StudsPerTile de la copia de interior
	Pattern: ("Regular" | "Organic")?,
	Whiten: number,
	Fallback: string?, -- otro aspecto si este no tiene ninguno cargado
	Why: string,
}

local function c(pack: string, name: string, from: string): Candidate
	return { Pack = pack, Name = name, From = from }
end
local function find(pack: string, words: { string }, avoid: { string }?): Candidate
	return { Pack = pack, Find = words, Avoid = avoid }
end

-- Material de la pieza -> BaseMaterial de los variants que puede llevar (además del suyo). En los
-- interiores las piezas son casi todas plástico liso pintado; la física se deja como estaba.
InteriorLook.Convertible = {
	SmoothPlastic = { Concrete = true, Brick = true, Plastic = true, Fabric = true, Wood = true, WoodPlanks = true, Pavement = true },
	Plastic = { Concrete = true, Brick = true, SmoothPlastic = true, Fabric = true, Pavement = true },
	Plaster = { Concrete = true, Brick = true, Plastic = true, Fabric = true },
	WoodPlanks = { Wood = true, Pavement = true, Plastic = true },
	Wood = { WoodPlanks = true },
	Marble = { Pavement = true, CeramicTiles = true, Granite = true },
	CeramicTiles = { Pavement = true, Concrete = true, Marble = true, Plastic = true },
	Slate = { Pavement = true, Granite = true },
	Granite = { Marble = true },
	Carpet = { Fabric = true },
	Concrete = { Marble = true },
} :: { [string]: { [string]: boolean } }

function InteriorLook.canUse(partMaterial: string, variantBase: string): boolean
	if partMaterial == variantBase then
		return true
	end
	local list = InteriorLook.Convertible[partMaterial]
	return list ~= nil and list[variantBase] == true
end

InteriorLook.Looks = {
	---------------------------------------------------------------- Suelos
	Parquet = {
		-- Tarima de roble: la del pack oficial Duvall Drive (casa realista de Roblox) si trae «wood floor»;
		-- si no, «Oak Floor» y «Mahogany Floor» del Mega Pack (tarima de tablas). Respaldo: tablas de
		-- Realistic Packs y del pack de madera. 6 studs: tablas de medio stud a uno.
		Options = {
			find("Duvall", { "wood", "floor" }),
			c("Mega", "Oak Floor", "WoodPlanks"),
			c("Mega", "Mahogany Floor", "WoodPlanks"),
			c("RPacks", "WoodenPlanks", "WoodPlanks"),
			c("RealMad", "Realistic Wood Planks", "WoodPlanks"),
		},
		Variety = 3,
		Studs = 6,
		Whiten = 0.5,
		Why = "tarima/parqué de madera (Duvall Drive Wood Floor, Oak Floor, Mahogany Floor)",
	},
	Peldano = {
		-- Peldaños de la escalera de las casas: la misma tarima, más menuda
		Options = { c("Mega", "Oak Floor", "WoodPlanks"), c("Mega", "Mahogany Floor", "WoodPlanks"), c("RPacks", "WoodenPlanks", "WoodPlanks") },
		Variety = 1,
		Studs = 4,
		Whiten = 0.45,
		Why = "peldaños de tarima de roble (Oak Floor)",
	},
	BaldosaCocina = {
		-- Cocinas: baldosa hidráulica (la de las casas mediterráneas: «Vintage Tile») o cerámica lisa
		Options = { c("Mega", "Vintage Tile", "Pavement"), c("Tyler", "CeramicTiles1", "CeramicTiles"), c("Mega", "Modern Tiles", "Pavement"), c("Mega", "Tile", "Pavement") },
		Variety = 2,
		Studs = 5,
		Whiten = 0.3,
		Why = "baldosa de cocina: hidráulica (Vintage Tile) o cerámica (CeramicTiles1)",
	},
	BaldosaBano = {
		-- Baños: gres moderno y cerámica pequeña
		Options = { c("Mega", "Modern Tiles", "Pavement"), c("Tyler", "CeramicTiles2", "CeramicTiles"), c("Mega", "Spaced Tiles", "Pavement"), c("Mega", "Tile", "Pavement") },
		Variety = 2,
		Studs = 4,
		Whiten = 0.3,
		Why = "gres de baño (Modern Tiles, CeramicTiles2)",
	},
	BaldosaLocal = {
		-- Tiendas, bares, súper, gasolinera: baldosa cerámica de local comercial
		Options = { c("Mega", "Tile", "Pavement"), c("Tyler", "CeramicTiles5", "CeramicTiles"), c("Mega", "Industrial Tiles", "Pavement"), c("Mega", "Stone Tiles", "Pavement") },
		Variety = 2,
		Studs = 6,
		Whiten = 0.35,
		Why = "baldosa cerámica de local (Tile, CeramicTiles5)",
	},
	Terrazo = {
		-- Terrazo (mármol moteado): estaciones, centro comercial, escaleras y rellanos de los bloques
		Options = { c("Mega", "Marble Speckled", "Marble"), c("Mega", "Marble Tile 1", "Marble") },
		Variety = 1,
		Studs = 6,
		Whiten = 0.25,
		Why = "terrazo de portales, escaleras y estaciones (Marble Speckled)",
	},
	Marmol = {
		-- Mármol en losas: villas, portales, oficinas, banco, hotel, ayuntamiento, museo. Primero el
		-- oficial de Duvall Drive si trae mármol; «Marble Tile 1» (losas con junta) y «Streaked Marble».
		Options = {
			find("Duvall", { "marble" }),
			c("Mega", "Marble Tile 1", "Marble"),
			c("Mega", "Streaked Marble", "Marble"),
			c("Mega", "Marble SmoothPolishedElegantMaterial", "Marble"),
			c("RPacks", "Marble Tile 1", "Marble"),
		},
		Variety = 2,
		Studs = 8,
		Whiten = 0.2,
		Why = "mármol en losas (Marble Tile 1, Streaked Marble)",
	},
	Linoleo = {
		-- Hospital y colegio: linóleo/vinilo (bastante aclarado: que se vea limpio). Respaldo: baldosa
		-- industrial y cerámica.
		Options = { c("Mega", "Cheap Old Linoleum", "Pavement"), c("Mega", "Industrial Tiles", "Pavement"), c("Mega", "Tile", "Pavement") },
		Variety = 1,
		Studs = 8,
		Whiten = 0.55,
		Why = "linóleo de hospital y colegio (Cheap Old Linoleum)",
	},
	Moqueta = {
		-- Oficinas: moqueta de oficina y moqueta de tejido apretado
		Options = { c("Mega", "Office Carpet Fabric", "Fabric"), c("Mega", "Tight Weave Carpet", "Fabric"), c("Tyler", "Carpet2", "Fabric"), c("RPacks", "Carpet 1", "Fabric") },
		Variety = 2,
		Studs = 6,
		Whiten = 0.45,
		Why = "moqueta de oficina (Office Carpet Fabric, Tight Weave Carpet)",
	},
	MoquetaCine = {
		-- Teatro y cine: moqueta mullida estampada (con su rojo/granate de siempre)
		Options = { c("Mega", "Carpet SoftPlushPatternedMaterial", "Fabric"), c("Mega", "Tight Weave Carpet", "Fabric"), c("Tyler", "Carpet2", "Fabric") },
		Variety = 1,
		Studs = 6,
		Pattern = "Organic",
		Whiten = 0.3,
		Why = "moqueta estampada de teatro y cine (Carpet SoftPlushPatternedMaterial)",
	},
	Hormigon = {
		-- Naves, talleres, cuartel, garajes y cárcel: hormigón pulido fino
		Options = { c("Mega", "Fine Particles Concrete", "Concrete"), c("Tyler", "Concrete3", "Concrete"), c("Real", "Concrete", "Concrete") },
		Variety = 2,
		Studs = 12,
		Whiten = 0.35,
		Why = "hormigón pulido de naves y garajes (Fine Particles Concrete, Concrete3)",
	},
	Pizarra = {
		-- Donde la sala ya traía pizarra (suelos de pisos y rellanos): losas de pizarra
		Options = { c("Mega", "Slate Tiled", "Slate"), c("Tyler", "Stonetiles", "Slate") },
		Variety = 1,
		Studs = 6,
		Whiten = 0.35,
		Why = "losas de pizarra (Slate Tiled)",
	},
	GranitoSuelo = {
		Options = { c("Mega", "Smooth Granite", "Granite"), c("Mega", "Gray Granite", "Granite") },
		Variety = 1,
		Studs = 8,
		Whiten = 0.3,
		Why = "granito pulido de rellanos (Smooth Granite)",
	},
	---------------------------------------------------------------- Paredes
	Pintura = {
		-- Pared pintada: el yeso oficial de Modern City («Plaster_A»), estuco liso y gotelé («Sprayed
		-- Wall Texture», el de los pisos de verdad). Casi no aclara: manda el color de cada pared.
		Options = {
			{ Pack = "MCity", Name = "Plaster_A", Find = { "plaster" }, Avoid = { "brick" } },
			c("Mega", "Smooth Stucco", "Concrete"),
			c("Mega", "Sprayed Wall Texture", "Concrete"),
			c("Mega", "Fibrous Plaster", "Concrete"),
		},
		Variety = 3,
		Weights = { 2, 2, 1 },
		Studs = 8,
		Whiten = 0.05,
		Why = "pintura sobre enlucido (Plaster_A, Smooth Stucco, gotelé)",
	},
	PapelPintado = {
		-- Papel pintado: el oficial de Duvall Drive y los del Mega Pack (relieve floral, motivo redondo)
		Options = {
			find("Duvall", { "wallpaper" }),
			c("Mega", "Floral Embossed Wallpaper", "Concrete"),
			c("Mega", "Round Pattern Wallpaper", "Concrete"),
			c("Mega", "Wallpaper", "Brick"),
		},
		Variety = 3,
		Studs = 6,
		Whiten = 0.15,
		Why = "papel pintado (Duvall Drive Wallpaper, Floral Embossed, Round Pattern)",
	},
	Azulejo = {
		-- Cocina (frente de la encimera) y baño: azulejo cerámico brillante, pieza pequeña
		Options = {
			c("Tyler", "CeramicTiles4", "CeramicTiles"),
			c("Mega", "CeramicTiles GlossyPatternedDurableMaterial", "Concrete"),
			c("Tyler", "Ceramictiles3", "CeramicTiles"),
			c("Mega", "Modern Tiles", "Pavement"),
		},
		Variety = 2,
		Studs = 4,
		Whiten = 0.3,
		Why = "azulejo de cocina y baño (CeramicTiles4, CeramicTiles Glossy)",
	},
	LadrilloVisto = {
		-- La pared del fondo de algunos bares: ladrillo visto rojo
		Options = { c("Mega", "Red Bricks", "Brick"), c("Mega", "Rough Brick", "Brick"), c("RealMad", "Realistic Bricks", "Brick") },
		Variety = 2,
		Studs = 8,
		Whiten = 0.55,
		Why = "ladrillo visto de bar (Red Bricks, Rough Brick)",
	},
	LadrilloPintado = {
		-- Naves, talleres y cuartel: bloque/ladrillo pintado (el oficial de Modern City o el del Mega Pack)
		Options = { { Pack = "MCity", Name = "PaintedBrick", Find = { "painted", "brick" } }, c("Mega", "Painted Brick", "Brick"), c("Mega", "Gray Bricks", "Brick") },
		Variety = 1,
		Studs = 8,
		Whiten = 0.2,
		Why = "ladrillo pintado de naves y talleres (PaintedBrick)",
	},
	---------------------------------------------------------------- Techos
	Yeso = {
		-- Techo de escayola/yeso liso blanco
		Options = { c("Mega", "Smooth Stucco", "Concrete"), { Pack = "MCity", Name = "Plaster_A", Find = { "plaster" }, Avoid = { "brick" } }, c("Mega", "Fibrous Plaster", "Concrete") },
		Variety = 1,
		Studs = 10,
		Whiten = 0.05,
		Why = "techo de yeso liso (Smooth Stucco)",
	},
	Placas = {
		-- Techo registrable de placas: oficinas, colegio, hospital, tiendas. Si no carga, yeso.
		Options = { c("Mega", "Office Ceiling Tiles", "Plastic") },
		Variety = 1,
		Studs = 10,
		Whiten = 0.25,
		Fallback = "Yeso",
		Why = "techo de placas de oficina (Office Ceiling Tiles)",
	},
	---------------------------------------------------------------- Encimeras, rodapiés
	EncimeraGranito = {
		Options = { c("Mega", "Speckled Countertop", "Granite"), c("Mega", "Smooth Granite", "Granite"), c("Mega", "Gray Granite Flecks", "Granite") },
		Variety = 2,
		Studs = 4,
		Whiten = 0.3,
		Why = "encimera de granito (Speckled Countertop, Smooth Granite)",
	},
	EncimeraMarmol = {
		Options = { c("Mega", "Marble SmoothPolishedElegantMaterial", "Marble"), c("Mega", "Streaked Marble", "Marble"), c("Mega", "Stringy Marble", "Marble") },
		Variety = 2,
		Studs = 4,
		Whiten = 0.15,
		Why = "encimera de mármol pulido (Marble SmoothPolished, Streaked Marble)",
	},
	EncimeraMadera = {
		Options = { c("Mega", "Oak", "Wood"), c("Mega", "Veneer Wood", "Wood"), c("RealMad", "Realistic Wood", "Wood") },
		Variety = 1,
		Studs = 4,
		Whiten = 0.3,
		Why = "encimera de madera maciza (Oak)",
	},
	Rodapie = {
		Options = { c("Mega", "Veneer Wood", "Wood"), c("Mega", "Oak", "Wood") },
		Variety = 1,
		Studs = 4,
		Whiten = 0.3,
		Why = "rodapié de madera chapada (Veneer Wood)",
	},
} :: { [string]: Look }

-- Nombre de pieza -> parte de la sala. Lo que no está aquí (muebles, puertas, cristales, luces,
-- carteles, cuadros…) nunca se toca.
InteriorLook.Roles = {
	-- Suelos
	Floor = "Floor",
	FloorSlab = "Floor", -- pasillos de los bloques (World/Tower)
	CoreFloor = "Floor",
	UpperFloor = "Floor", -- planta de arriba de las casas
	FloorFinish = "Patch", -- suelo de otro material en una zona (cocina, baño, dormitorio)
	TileFloor = "Floor", -- duchas del gimnasio
	SalaFloor = "Floor", -- sala del cine
	HallFloor = "Floor",
	PrisonFloor = "Floor",
	OldRoomFloor = "Floor",
	ShopFloor = "Floor",
	MidLanding = "Landing",
	EmergencyLanding = "Landing",
	Step = "Step",
	-- Paredes
	WallBack = "Wall",
	WallLeft = "Wall",
	WallRight = "Wall",
	WallFront = "Wall",
	Wall = "Wall", -- (solo en las salas del cielo: en la calle es la fachada, de HouseDress)
	Partition = "Wall",
	Lintel = "Wall",
	UpperWall = "Wall",
	UpperPartition = "Wall",
	UpperLintel = "Wall",
	EndWall = "Wall",
	CoreBack = "Wall",
	CoreLeft = "Wall",
	CoreRight = "Wall",
	StairDivider = "Wall",
	EmergencyOuter = "Wall",
	EmergencyBack = "Wall",
	EmergencyFront = "Wall",
	EmergencyInner = "Wall",
	OfficeWall = "Wall",
	InnerWall = "Wall",
	RoomWall = "Wall",
	SalaWall = "Wall",
	BackWall = "Wall",
	OldRoomWall = "Wall",
	DeliBackWall = "Wall",
	FishBackWall = "Wall",
	WallFinish = "Finish", -- paño de pintura o azulejos pegado a la pared
	-- Techos
	Ceiling = "Ceiling",
	UpperCeiling = "Ceiling",
	Roof = "Ceiling", -- (solo en las salas del cielo: el techo de la última planta de los bloques)
	-- Encimeras y rodapiés
	Worktop = "Counter",
	CounterTop = "Counter",
	BackCounterTop = "Counter",
	IslandTop = "Counter",
	VanityTop = "Counter",
	Baseboard = "Baseboard",
} :: { [string]: string }

-- En la ciudad (fuera de las salas del cielo) solo estos nombres son de interior
InteriorLook.TownRoles = {
	Floor = true,
	Ceiling = true,
	TileFloor = true,
	SalaFloor = true,
	HallFloor = true,
	PrisonFloor = true,
	OldRoomFloor = true,
	ShopFloor = true,
	InnerWall = true,
	RoomWall = true,
	SalaWall = true,
	BackWall = true,
	OldRoomWall = true,
	DeliBackWall = true,
	FishBackWall = true,
	CounterTop = true,
	BackCounterTop = true,
	Worktop = true,
} :: { [string]: boolean }

InteriorLook.SKY_Y = 2000 -- por encima, salas de interiores (InteriorService las monta a 6000)

---------------------------------------------------------------------
-- Estancias
---------------------------------------------------------------------

-- Categoría de cada sala de World/Interiors (Interior_<Tipo>)
InteriorLook.Categories = {
	Casa = "Casa",
	Piso = "Casa",
	Dorm = "Casa",
	Villa = "Villa",
	Portal = "Lujo",
	OficinaLobby = "Oficina",
	Oficina = "Oficina",
	Hacienda = "Oficina",
	Local = "Tienda", -- (afinado por el cartel: ShopCategories)
	Nave = "Industrial",
	Taller = "Industrial",
	Cuartel = "Industrial",
	Ocio = "Ocio",
	Aula = "Colegio",
	Ayuntamiento = "Lujo",
	Museo = "Lujo",
	Juzgado = "Lujo",
	Teatro = "Cine",
	Estacion = "Publico",
	CentroComercial = "Publico",
	Tower = "Escalera", -- portal, escalera y pasillos de los bloques (World/Tower)
} :: { [string]: string }

-- Locales (atributo Shop de Interior_Local: el Id del perfil de World/Interiors)
InteriorLook.ShopCategories = {
	Bar = "Bar",
	Cafeteria = "Bar",
	Pizzeria = "Bar",
	Heladeria = "Bar",
	Sushi = "Bar",
	Hamburgueseria = "Bar",
	Kebab = "Bar",
	Banco = "Lujo",
	Joyeria = "Lujo",
	Inmobiliaria = "Oficina",
	Seguros = "Oficina",
	Copisteria = "Oficina",
	Academia = "Colegio",
	Taller = "Oficina",
} :: { [string]: string }

-- Edificios de la ciudad con su planta baja de verdad (por el nombre de sus modelos)
InteriorLook.TownCategories = {
	Hospital = "Hospital",
	CentroSalud = "Hospital",
	Colegio = "Colegio",
	Hotel = "Hotel",
	RecepcionHotel = "Hotel",
	Supermercado = "Tienda",
	Cine = "Cine",
	CentroPenitenciario = "Industrial",
	GarajeCosme = "Industrial",
	Granero = "Industrial",
	Policia = "Oficina",
	Torre = "Oficina",
	CentroComercial = "Publico",
	Gasolinera = "Tienda",
	Autoescuela = "Tienda",
	Correos = "Tienda",
	Cafeteria = "Bar",
	Restaurante = "Bar",
	MegaBurger = "Bar",
	Recreativos = "Ocio",
	Gimnasio = "Gimnasio",
	GimnasioValmar = "Gimnasio",
	GymInterior = "Gimnasio",
} :: { [string]: string }

-- Categoría por los nombres de los modelos que contienen la pieza (de dentro a fuera) y el cartel
function InteriorLook.categoryOf(names: { string }, shop: string?): string?
	for _, name in names do
		local kind = string.match(name, "^Interior_(.+)$")
		if kind then
			if kind == "Local" and shop and InteriorLook.ShopCategories[shop] then
				return InteriorLook.ShopCategories[shop]
			end
			return InteriorLook.Categories[kind]
		end
		local town = InteriorLook.TownCategories[name]
		if town then
			return town
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Azar fijo por vivienda o local
---------------------------------------------------------------------

local function strHash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483629
	end
	return h
end

-- 0..1, siempre el mismo para la misma semilla y sal
function InteriorLook.hash(seed: string, salt: string): number
	local h = strHash(salt .. "|" .. seed)
	local v = math.sin(h * 0.000123 + 1.7) * 43758.5453
	return v - math.floor(v)
end

function InteriorLook.chance(seed: string, salt: string, p: number): boolean
	return InteriorLook.hash(seed, salt) < p
end

-- Semilla de un edificio de la ciudad por su sitio (redondeado: la misma desde cualquier pieza)
function InteriorLook.placeSeed(x: number, z: number): string
	return ("%d,%d"):format(math.floor(x / 4 + 0.5), math.floor(z / 4 + 0.5))
end

---------------------------------------------------------------------
-- Qué aspecto lleva cada pieza
---------------------------------------------------------------------

export type PartInfo = {
	Name: string,
	Material: string, -- Enum.Material.Name
	Variant: string?,
	Transparency: number?,
	Color: Color3?,
	Category: string?, -- de categoryOf
	Sky: boolean?, -- en una sala del cielo (InteriorService) o en la carpeta Interiores
	Seed: string?, -- vivienda o local (variedad fija)
	LocalY: number?, -- altura sobre el suelo de la sala (para los parches del piso de arriba)
	LocalZ: number?, -- fondo de la sala (+) o entrada (-): baño al fondo, cocina delante
	Skip: boolean?,
}

local MAIN_WALLS = { WallBack = true, WallLeft = true, WallRight = true, WallFront = true, UpperWall = true }
local PAINTABLE = { SmoothPlastic = true, Plastic = true, Plaster = true }

local function luminance(color: Color3?): number
	if not color then
		return 0.5
	end
	return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
end

function InteriorLook.classify(info: PartInfo): string?
	local name, m = info.Name, info.Material
	local role = InteriorLook.Roles[name]
	if not role or info.Skip or (info.Variant ~= nil and info.Variant ~= "") then
		return nil
	end
	if (info.Transparency or 0) >= 0.5 or m == "Glass" or m == "Neon" or m == "ForceField" then
		return nil
	end
	if not info.Sky and not InteriorLook.TownRoles[name] then
		return nil -- (la fachada y lo demás de la calle no es de aquí)
	end
	local cat = info.Category
	local seed = info.Seed or ""
	if role == "Floor" or role == "Patch" then
		if m == "WoodPlanks" or m == "Wood" then
			return if cat == "Colegio" or cat == "Hospital" then "Linoleo" else "Parquet"
		elseif m == "Marble" then
			if name == "TileFloor" then
				return "BaldosaBano"
			elseif cat == "Tienda" or cat == "Bar" then
				return "BaldosaLocal"
			elseif cat == "Publico" then
				return "Terrazo"
			end
			return "Marmol"
		elseif m == "CeramicTiles" then
			if cat == "Hospital" or cat == "Colegio" then
				return "Linoleo"
			elseif role == "Patch" and (cat == "Casa" or cat == "Villa") then
				-- baño al fondo o arriba, cocina delante
				if (info.LocalY or 0) > 5 or (info.LocalZ or 0) > 0 then
					return "BaldosaBano"
				end
				return "BaldosaCocina"
			end
			return "BaldosaLocal"
		elseif m == "Carpet" then
			return if cat == "Cine" then "MoquetaCine" else "Moqueta"
		elseif m == "Concrete" then
			return "Hormigon"
		elseif m == "Slate" then
			return "Pizarra"
		elseif m == "Granite" then
			return "GranitoSuelo"
		elseif m == "SmoothPlastic" or m == "Plastic" then
			return if cat == "Hospital" or cat == "Colegio" then "Linoleo" else nil
		end
		return nil
	elseif role == "Step" then
		if m == "WoodPlanks" or m == "Wood" then
			return "Peldano"
		elseif m == "Concrete" or m == "Marble" then
			return "Terrazo"
		end
		return nil
	elseif role == "Landing" then
		if m == "Concrete" or m == "Marble" then
			return if name == "EmergencyLanding" then "Hormigon" else "Terrazo"
		end
		return nil
	elseif role == "Wall" then
		if not PAINTABLE[m] then
			return nil
		end
		if cat == "Industrial" then
			return "LadrilloPintado"
		elseif cat == "Bar" and name == "WallBack" and InteriorLook.chance(seed, "LadrilloBar", 0.6) then
			return "LadrilloVisto"
		elseif cat == "Hotel" then
			return "PapelPintado"
		elseif cat == "Villa" and MAIN_WALLS[name] and InteriorLook.chance(seed, "PapelVilla", 0.5) then
			return "PapelPintado"
		elseif cat == "Casa" and (name == "UpperPartition" or name == "UpperWall") and InteriorLook.chance(seed, "PapelArriba", 0.35) then
			return "PapelPintado"
		end
		return "Pintura"
	elseif role == "Finish" then
		if m == "CeramicTiles" then
			return "Azulejo"
		elseif PAINTABLE[m] then
			return "PapelPintado" -- (paños de color de dormitorios e infantiles)
		end
		return nil
	elseif role == "Ceiling" then
		if not PAINTABLE[m] then
			return nil
		end
		if cat == "Oficina" or cat == "Colegio" or cat == "Hospital" or cat == "Tienda" then
			return "Placas"
		end
		return "Yeso"
	elseif role == "Counter" then
		if m == "Granite" or m == "Slate" then
			return "EncimeraGranito"
		elseif m == "Marble" then
			return "EncimeraMarmol"
		elseif m == "Wood" or m == "WoodPlanks" then
			return "EncimeraMadera"
		end
		return nil
	elseif role == "Baseboard" then
		-- (los blancos lacados se quedan lisos: una veta de madera los volvería marrones)
		if luminance(info.Color) > 0.8 then
			return nil
		end
		return if m == "SmoothPlastic" or m == "Plastic" or m == "Wood" then "Rodapie" else nil
	end
	return nil
end

---------------------------------------------------------------------
-- Elección del variant
---------------------------------------------------------------------

-- Nombre del pack que vale para el candidato (exacto o, si no está, por palabras). nil = ninguno.
function InteriorLook.match(cand: Candidate, pack: { [string]: string }?): string?
	if not pack then
		return nil
	end
	if cand.Name and pack[cand.Name] then
		return cand.Name
	end
	if not cand.Find then
		return nil
	end
	local best: string? = nil
	for name in pack do
		local lower = string.lower(name)
		local ok = true
		for _, word in cand.Find do
			if not string.find(lower, word, 1, true) then
				ok = false
				break
			end
		end
		for _, word in cand.Avoid or {} do
			if ok and string.find(lower, word, 1, true) then
				ok = false
			end
		end
		-- (el más corto y, a igualdad, por orden alfabético: siempre el mismo)
		if ok and (best == nil or #name < #best or (#name == #best and name < best)) then
			best = name
		end
	end
	return best
end

export type Resolved = { Pack: string, Name: string, From: string }

-- Candidatos de un aspecto que se pueden usar, en orden, ya recortados a su variedad.
-- available[pack][nombre] = BaseMaterial de verdad del variant cargado.
function InteriorLook.candidates(key: string, available: { [string]: { [string]: string } }): { Resolved }
	local look = InteriorLook.Looks[key]
	local out = {}
	if not look then
		return out
	end
	local seen = {}
	for _, cand in look.Options do
		local name = InteriorLook.match(cand, available[cand.Pack])
		local id = name and (cand.Pack .. "/" .. name)
		if name and not seen[id] then
			seen[id] = true
			table.insert(out, { Pack = cand.Pack, Name = name, From = available[cand.Pack][name] })
			if #out >= look.Variety then
				break
			end
		end
	end
	return out
end

-- Los de la lista que puede llevar una pieza de este material (en orden)
function InteriorLook.usable<T>(list: { T & { Base: string } }, partMaterial: string): { T }
	local out = {}
	for _, r in list do
		if InteriorLook.canUse(partMaterial, r.Base) then
			table.insert(out, r)
		end
	end
	return out
end

-- Cuál de los n le toca a la vivienda o local de esa semilla: 1..n (siempre el mismo)
function InteriorLook.pick(key: string, n: number, seed: string): number
	if n <= 1 then
		return 1
	end
	local look = InteriorLook.Looks[key]
	local weights = {}
	local total = 0
	for i = 1, n do
		local w = (look and look.Weights and look.Weights[i]) or 1
		weights[i] = w
		total += w
	end
	local r = InteriorLook.hash(seed, key) * total
	for i = 1, n do
		r -= weights[i]
		if r < 0 then
			return i
		end
	end
	return n
end

-- Color aclarado hacia el blanco (como HouseLook.whiten)
function InteriorLook.whiten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), math.clamp(amount, 0, 1))
end

return InteriorLook
