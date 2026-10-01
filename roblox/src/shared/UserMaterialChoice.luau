-- UserMaterialChoice: qué material PBR de los packs de la Tienda de creadores que eligió Sebastián
-- se pone en lugar de cada material de Roblox en toda la ciudad (World/UserMaterials).
--
-- Cuentas puras (sin Instances): se prueban fuera de Roblox (scripts/test-usermaterials.luau).
--
--   * Packs: los 6 packs de MaterialVariant (contenido real en docs/assets-usuario.md). Cada variant
--     se renombra a "U_<pack>_<nombre>" (UserMaterialChoice.variantName): los nombres originales
--     chocan entre packs ("Brick", "Grass"…), con los materiales de Roblox y con los nuestros (Asfalto,
--     Estuco…). El prefijo "U_" es solo de este módulo (los demás agentes usan otros).
--   * Table: un material de Roblox -> candidatos en orden (el primero que haya cargado gana). Solo se
--     elige por NOMBRE: las texturas no se pueden mirar desde un script. Cada elección dice por qué.
--     From = BaseMaterial del variant según el doc; si no es el material que sustituye, se le cambia
--     (p. ej. el asfalto de Tyler viene sobre Concrete).
--   * Studs / Pattern: si se ponen, cambian StudsPerTile / MaterialPattern del variant (nil = el suyo).
--     Escala de Valmar: una persona mide ~5 studs, un carril ~12, una acera 8-12.
--   * Whiten (0..1): las texturas de estos packs TRAEN su color (asfalto gris, césped verde, ladrillo
--     rojo…) y Roblox lo multiplica por el Color de la pieza; nuestra paleta (Kit/Palette) estaba hecha
--     para nuestras texturas neutras (casi blancas). Sin aclarar, el asfalto (46,48,53) saldría casi
--     negro. Por eso las piezas (y el terreno) de ese material se acercan al blanco en esa proporción:
--     0 = no se tocan (fachadas de colores), 0,7 = casi blanco (que mande el color de la foto).
--   * Lo que NO está en la tabla se queda con lo nuestro (shared/Textures, Kit/MaterialLook): el
--     metal pintado (Metal), el bordillo de granito (Granite, con rugosidad mojada) y lo de pieza a
--     pieza (pintura vial, laca de coche, acero cepillado, madera con veta de muebles y puertas).

local UserMaterialChoice = {}

UserMaterialChoice.Prefix = "U_"

export type Pack = { Id: number, Short: string, Title: string }

-- Packs (orden de carga). Short va en el nombre de cada variant.
UserMaterialChoice.Packs = {
	{ Id = 11392874817, Short = "Cesped", Title = "Césped 2k PBR" },
	{ Id = 13277933714, Short = "Real", Title = "Realistic Materials (piedras)" },
	{ Id = 14527172541, Short = "RealMad", Title = "Realistic Materials (madera)" },
	{ Id = 15221806045, Short = "Mega", Title = "PBR Realistic Material Mega Pack" },
	{ Id = 15446413305, Short = "Gen", Title = "Realistic Materials MADE WITH MATERIAL GENERATOR" },
	{ Id = 92927007790601, Short = "Tyler", Title = "Tylers Realistic Materials (asfaltos)" },
} :: { Pack }

-- Variants rotos (texturas rbxtemp://, salen errores en la consola al cargar el Mega Pack): se borran
UserMaterialChoice.Broken = {
	Mega = {
		["Circuitry"] = true,
		["Lava"] = true,
		["Microchip"] = true,
		["Obsidian"] = true,
		["Skulls In Ground"] = true,
		["WeatheredWood AgedRusticTexturedMaterial"] = true,
		["MaterialVariant"] = true,
	},
} :: { [string]: { [string]: boolean } }

export type Candidate = { Pack: string, Name: string, From: string }
export type Choice = {
	Material: string, -- Enum.Material que se sustituye en todo el juego (piezas y terreno)
	Candidates: { Candidate },
	Studs: number?,
	Pattern: ("Regular" | "Organic")?,
	Whiten: number,
	Why: string,
}

local function c(pack: string, name: string, from: string): Candidate
	return { Pack = pack, Name = name, From = from }
end

-- LA TABLA DE ELECCIÓN. Para cambiar el aspecto de un material: cambiar aquí su primer candidato
-- (un nombre de docs/assets-usuario.md, con su pack y su BaseMaterial de allí).
UserMaterialChoice.Table = {
	{
		Material = "Grass",
		-- El césped 2k es el pack que eligió para el césped (se llama "MaterialVariant 3"). Orgánico: en
		-- los parques grandes y en el terreno no se ve la repetición. (Respaldo: el del pack de piedras.)
		Candidates = { c("Cesped", "MaterialVariant 3", "Grass"), c("Real", "Grass", "Grass") },
		Pattern = "Organic",
		Whiten = 0.7,
		Why = "césped 2k del dueño, sin repetición visible",
	},
	{
		Material = "LeafyGrass",
		-- Hierba alta del mismo pack que el resto del suelo natural (mismo tono y escala que Ground/Rock)
		Candidates = { c("Real", "LeafyGrass", "LeafyGrass"), c("Tyler", "LeaftGrass2", "LeafyGrass") },
		Whiten = 0.7,
		Why = "hierba alta del pack Realistic Materials, a juego con tierra y roca",
	},
	{
		Material = "Asphalt",
		-- Tyler's es el pack «de asfaltos»: su Asphalt2 (orgánico, 17 studs: algo más que un carril, sin
		-- repetición) viene sobre Concrete y se pasa a Asphalt. Respaldo: el Asphalt del pack de piedras.
		-- (Los del Mega Pack son asfaltos pintados/rotos o de colores «Lab»: no para una calle normal.)
		Candidates = { c("Tyler", "Asphalt2", "Concrete"), c("Real", "Asphalt", "Asphalt") },
		Whiten = 0.65,
		Why = "asfalto de calle del pack de asfaltos de Tyler, a escala de carril",
	},
	{
		Material = "Pavement",
		-- Aceras: las «Pavement» de Tyler son de exterior (las Pavement del Mega Pack son azulejos de
		-- interior: baño, linóleo…). Pavement2: la primera, 10 studs, con juntas (Regular). Sobre Concrete:
		-- se pasa a Pavement. Respaldo: «Stone Tiles» del Mega Pack (losas de piedra).
		Candidates = { c("Tyler", "Pavement2", "Concrete"), c("Mega", "Stone Tiles", "Pavement") },
		Pattern = "Regular",
		Whiten = 0.45,
		Why = "losas de acera de exterior de Tyler",
	},
	{
		Material = "Concrete",
		-- Hormigón del pack de piedras (el juego coherente de suelos y muros). Respaldo: el del generador
		-- y el Concrete2 de Tyler.
		Candidates = { c("Real", "Concrete", "Concrete"), c("Gen", "RealisticConcrete", "Concrete"), c("Tyler", "Concrete2", "Concrete") },
		Whiten = 0.35,
		Why = "hormigón genérico del pack Realistic Materials",
	},
	{
		Material = "Brick",
		-- Ladrillo con patrón Regular (las hiladas no se rompen); el Brick del pack de piedras es
		-- orgánico y torcería las juntas. Respaldo: «Red Bricks» del Mega Pack.
		Candidates = { c("RealMad", "Realistic Bricks", "Brick"), c("Mega", "Red Bricks", "Brick"), c("Gen", "RealisticBricks", "Brick") },
		Pattern = "Regular",
		Whiten = 0.45,
		Why = "ladrillo rojo con hiladas rectas",
	},
	{
		Material = "Plaster",
		-- Fachadas mediterráneas encaladas: «Smooth Stucco» del Mega Pack (estuco liso; viene sobre
		-- Concrete, se pasa a Plaster). Orgánico para que no se vea la repetición en fachadas enteras.
		-- Casi sin aclarar: los colores pastel de cada fachada (Palette) tienen que seguir viéndose.
		Candidates = { c("Mega", "Smooth Stucco", "Concrete"), c("Mega", "Stucco", "Concrete"), c("Mega", "Grainy Stucco", "Concrete") },
		Pattern = "Organic",
		Whiten = 0.15,
		Why = "estuco liso de fachada mediterránea",
	},
	{
		Material = "ClayRoofTiles",
		-- Tejados de teja árabe/cerámica: «Clay Shingles» del Mega Pack (sobre Brick, se pasa a
		-- ClayRoofTiles). Respaldo: Roof1 de Tyler (sobre CeramicTiles).
		Candidates = { c("Mega", "Clay Shingles", "Brick"), c("Tyler", "Roof1", "CeramicTiles") },
		Pattern = "Regular",
		Whiten = 0.45,
		Why = "tejas de barro para los tejados",
	},
	{
		Material = "Cobblestone",
		-- Zócalos de piedra y bordes de estanques: adoquín del pack de piedras. Respaldo: el del generador.
		Candidates = { c("Real", "Cobblestone", "Cobblestone"), c("Gen", "RealisticCobbleStone", "Cobblestone"), c("Mega", "Dusty Cobble", "Cobblestone") },
		Whiten = 0.4,
		Why = "adoquín/piedra de zócalo",
	},
	{
		Material = "Limestone",
		-- Cornisas, jambas, plazas, fuentes y el muelle: piedra caliza clara («Flat Textured Limestone»,
		-- sin dibujo de bloques que choque con piezas pequeñas).
		Candidates = { c("Mega", "Flat Textured Limestone", "Limestone"), c("Mega", "Limestone 2", "Limestone") },
		Whiten = 0.25,
		Why = "piedra caliza clara de cornisas, plazas y fuentes",
	},
	{
		Material = "Slate",
		-- Peldaños, rompeolas, tejadillos y pizarras de clase: pizarra natural (sin baldosas: «Slate
		-- Tiled» pondría juntas en las pizarras de las aulas).
		Candidates = { c("Real", "Slate", "Slate"), c("Mega", "Slate Cliff Rock", "Slate") },
		Whiten = 0.2,
		Why = "pizarra natural (peldaños, rompeolas, pizarras)",
	},
	{
		Material = "Marble",
		Candidates = { c("Real", "Marble", "Marble"), c("Mega", "Marble SmoothPolishedElegantMaterial", "Marble") },
		Whiten = 0.25,
		Why = "mármol de suelos y edificios nobles, del pack de piedras",
	},
	{
		Material = "Sand",
		-- Playas y fondo del mar (terreno). OJO: el «RealisticGold» del generador va sobre Sand y es oro.
		Candidates = { c("Real", "Sand", "Sand"), c("Mega", "Sand 1", "Sand") },
		Whiten = 0.55,
		Why = "arena de playa (terreno)",
	},
	{
		Material = "Rock",
		-- Montañas del terreno y rocas sueltas
		Candidates = { c("Real", "Rock", "Rock"), c("Mega", "Rough Rock", "Rock") },
		Whiten = 0.5,
		Why = "roca de las montañas del terreno",
	},
	{
		Material = "Ground",
		-- Claros de tierra del terreno y huertos. OJO: el «RealisticStone» del generador va sobre Ground.
		Candidates = { c("Real", "Ground", "Ground"), c("Mega", "Dry Dirt", "Ground") },
		Whiten = 0.5,
		Why = "tierra del terreno y los huertos",
	},
	{
		Material = "WoodPlanks",
		-- Suelos y tarimas de tablas: con patrón Regular (las tablas siguen rectas)
		Candidates = { c("RealMad", "Realistic Wood Planks", "WoodPlanks"), c("Real", "WoodPlanks", "WoodPlanks") },
		Pattern = "Regular",
		Whiten = 0.35,
		Why = "tablas de madera rectas",
	},
	{
		Material = "Wood",
		-- La madera que no lleva nuestra «MaderaVeta» pieza a pieza (troncos, ramas y lo de fuera de
		-- la ciudad): madera genérica del pack de madera. Los muebles y puertas siguen con MaderaVeta.
		Candidates = { c("RealMad", "Realistic Wood", "Wood"), c("Real", "Wood", "Wood") },
		Whiten = 0.35,
		Why = "madera genérica del pack de madera",
	},
	{
		Material = "CeramicTiles",
		-- Baños, cocinas y piscinas: los CeramicTiles de Tyler son los únicos sobre CeramicTiles
		Candidates = { c("Tyler", "CeramicTiles1", "CeramicTiles"), c("Tyler", "CeramicTiles5", "CeramicTiles") },
		Pattern = "Regular",
		Whiten = 0.2,
		Why = "azulejo cerámico de Tyler",
	},
} :: { Choice }

-- Nombre único del variant de un pack: "U_<pack>_<nombre sin espacios ni signos>"
function UserMaterialChoice.variantName(short: string, name: string): string
	local clean = name:gsub("[^%w]", "")
	if clean == "" then
		clean = "Variant"
	end
	return UserMaterialChoice.Prefix .. short .. "_" .. clean
end

-- ¿Este variant es de los rotos?
function UserMaterialChoice.isBroken(short: string, name: string): boolean
	local list = UserMaterialChoice.Broken[short]
	return list ~= nil and list[name] == true
end

-- La elección según lo que haya cargado. loaded[short][nombre original] = true.
-- Devuelve, por material, el candidato que gana (los materiales sin ninguno cargado no salen).
export type Pick = { Material: string, Pack: string, Name: string, From: string, Studs: number?, Pattern: string?, Whiten: number }
function UserMaterialChoice.choose(loaded: { [string]: { [string]: boolean } }): { Pick }
	local picks = {}
	for _, choice in UserMaterialChoice.Table do
		for _, cand in choice.Candidates do
			local pack = loaded[cand.Pack]
			if pack and pack[cand.Name] then
				table.insert(picks, {
					Material = choice.Material,
					Pack = cand.Pack,
					Name = cand.Name,
					From = cand.From,
					Studs = choice.Studs,
					Pattern = choice.Pattern,
					Whiten = choice.Whiten,
				})
				break
			end
		end
	end
	return picks
end

-- Materiales que cubre la tabla -> cuánto aclarar
function UserMaterialChoice.whitenOf(material: string): number?
	for _, choice in UserMaterialChoice.Table do
		if choice.Material == material then
			return choice.Whiten
		end
	end
	return nil
end

-- Color aclarado hacia el blanco (ver Whiten)
function UserMaterialChoice.whiten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), math.clamp(amount, 0, 1))
end

-- Atributo de MaterialService que dice qué variant del dueño sustituye a un material: así
-- Kit/MaterialLook no le pone encima el nuestro aunque arranque después.
function UserMaterialChoice.attribute(material: string): string
	return "UserOverride_" .. material
end

return UserMaterialChoice
