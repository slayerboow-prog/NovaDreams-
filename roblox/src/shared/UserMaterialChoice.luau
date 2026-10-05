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

-- Packs de la 5ª y 6ª tanda (docs/assets-usuario-5.md y docs/assets-implementados.md). Se cargan
-- después de los 6 de arriba y solo son RESPALDO o VARIEDAD (nunca el primero de una fila, salvo la
-- arena de playa que eligió el dueño):
--   * PBR: 20 MaterialVariant de IAmAGreenStickMan, uno por material de Roblox («Brick_PBR»…).
--     Tiene 10 votos negativos y no se ha visto en el juego: van detrás de los que ya se han probado.
--   * Todos: «ALL MATERIALS» (no está en los docs: se busca por palabras y por BaseMaterial).
--   * Arena: «realistic sand texture» (no está en los docs: cualquier variant que venga sobre Sand).
UserMaterialChoice.ExtraPacks = {
	{ Id = 9408271791, Short = "PBR", Title = "PBR_Textures (20 MaterialVariant)" },
	{ Id = 12715816700, Short = "Todos", Title = "ALL MATERIALS" },
	{ Id = 9268236860, Short = "Arena", Title = "Realistic sand texture" },
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

-- Name: nombre exacto (de los docs). Find: si no se sabe el nombre (packs sin lista en los docs),
-- palabras que tiene que llevar (minúsculas; {} = cualquiera); se queda el más corto.
export type Candidate = { Pack: string, Name: string, From: string, Find: { string }? }
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
-- Buscar por palabras en un pack sin lista (Name = "" hasta que se encuentra)
local function find(pack: string, words: { string }, from: string): Candidate
	return { Pack = pack, Name = "", From = from, Find = words }
end

-- LA TABLA DE ELECCIÓN. Para cambiar el aspecto de un material: cambiar aquí su primer candidato
-- (un nombre de docs/assets-usuario.md, con su pack y su BaseMaterial de allí).
UserMaterialChoice.Table = {
	{
		Material = "Grass",
		-- El césped 2k es el pack que eligió para el césped (se llama "MaterialVariant 3"). Orgánico: en
		-- los parques grandes y en el terreno no se ve la repetición. (Respaldo: el del pack de piedras.)
		Candidates = { c("Cesped", "MaterialVariant 3", "Grass"), c("Real", "Grass", "Grass"), c("Gen", "RealisticGrass", "Grass"), c("Tyler", "Grass2", "Grass") },
		Pattern = "Organic",
		-- 0,3 (antes 0,7): con 0,7 el verde de las piezas casi era blanco y el césped salía color oliva
		-- seco (captura del dueño, v81); así conserva más verde y se ve fresco
		Whiten = 0.3,
		Why = "césped 2k del dueño, sin repetición visible",
	},
	{
		Material = "LeafyGrass",
		-- Hierba alta del mismo pack que el resto del suelo natural (mismo tono y escala que Ground/Rock)
		Candidates = { c("Real", "LeafyGrass", "LeafyGrass"), c("Tyler", "LeaftGrass2", "LeafyGrass"), find("Todos", { "leafy" }, "LeafyGrass") },
		Whiten = 0.7,
		Why = "hierba alta del pack Realistic Materials, a juego con tierra y roca",
	},
	{
		Material = "Asphalt",
		-- El Asphalt del pack de piedras ya viene sobre Asphalt (en un servidor real no se puede cambiar el
		-- BaseMaterial de un variant de la Tienda: el Asphalt2 de Tyler, sobre Concrete, queda de respaldo
		-- por si algún día se puede). 17 studs: algo más que un carril, sin repetición visible.
		-- (Los del Mega Pack son asfaltos pintados/rotos o de colores «Lab»: no para una calle normal.)
		Candidates = { c("Real", "Asphalt", "Asphalt"), c("Tyler", "Asphalt2", "Concrete") },
		Studs = 17,
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
		Candidates = { c("Real", "Concrete", "Concrete"), c("Gen", "RealisticConcrete", "Concrete"), c("Tyler", "Concrete2", "Concrete"), c("PBR", "Concrete_PBR", "Concrete"), find("Todos", { "concrete" }, "Concrete") },
		Whiten = 0.35,
		Why = "hormigón genérico del pack Realistic Materials",
	},
	{
		Material = "Brick",
		-- Ladrillo con patrón Regular (las hiladas no se rompen); el Brick del pack de piedras es
		-- orgánico y torcería las juntas. Respaldo: «Red Bricks» del Mega Pack.
		Candidates = { c("RealMad", "Realistic Bricks", "Brick"), c("Mega", "Red Bricks", "Brick"), c("Gen", "RealisticBricks", "Brick"), c("Real", "Brick", "Brick"), c("PBR", "Brick_PBR", "Brick"), find("Todos", { "brick" }, "Brick") },
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
		Candidates = { c("Real", "Cobblestone", "Cobblestone"), c("Gen", "RealisticCobbleStone", "Cobblestone"), c("Mega", "Dusty Cobble", "Cobblestone"), c("PBR", "Cobblestone_PBR", "Cobblestone") },
		Whiten = 0.4,
		Why = "adoquín/piedra de zócalo",
	},
	{
		Material = "Limestone",
		-- Cornisas, jambas, plazas, fuentes y el muelle: piedra caliza clara («Flat Textured Limestone»,
		-- sin dibujo de bloques que choque con piezas pequeñas).
		Candidates = { c("Mega", "Flat Textured Limestone", "Limestone"), c("Mega", "Limestone 2", "Limestone"), c("Mega", "Carved Limestone", "Limestone") },
		Whiten = 0.25,
		Why = "piedra caliza clara de cornisas, plazas y fuentes",
	},
	{
		Material = "Slate",
		-- Peldaños, rompeolas, tejadillos y pizarras de clase: pizarra natural (sin baldosas: «Slate
		-- Tiled» pondría juntas en las pizarras de las aulas).
		Candidates = { c("Real", "Slate", "Slate"), c("Mega", "Slate Cliff Rock", "Slate"), c("Tyler", "Stone", "Slate"), c("PBR", "Slate_PBR", "Slate") },
		Whiten = 0.2,
		Why = "pizarra natural (peldaños, rompeolas, pizarras)",
	},
	{
		Material = "Marble",
		Candidates = { c("Real", "Marble", "Marble"), c("Mega", "Marble SmoothPolishedElegantMaterial", "Marble"), c("PBR", "Marble_PBR", "Marble"), find("Todos", { "marble" }, "Marble") },
		Whiten = 0.25,
		Why = "mármol de suelos y edificios nobles, del pack de piedras",
	},
	{
		Material = "Sand",
		-- Playas y fondo del mar (terreno). Primero la arena que eligió el dueño para la playa
		-- («realistic sand texture», 9268236860: cualquier variant suyo que venga sobre Sand; si viene
		-- sobre otro material, World/MaterialExtras lo pone pieza a pieza en la arena de la playa). Luego
		-- la del pack de piedras, la del Mega Pack y la de PBR_Textures. OJO: el «RealisticGold» del
		-- generador va sobre Sand y es oro (por eso Arena busca «sand» antes que cualquier otro nombre).
		Candidates = {
			find("Arena", { "sand" }, "Sand"),
			find("Arena", {}, "Sand"),
			c("Real", "Sand", "Sand"),
			c("Mega", "Sand 1", "Sand"),
			c("PBR", "Sand_PBR", "Sand"),
			find("Todos", { "sand" }, "Sand"),
		},
		Whiten = 0.55,
		Why = "arena de playa del dueño (realistic sand) o la del pack de piedras",
	},
	{
		Material = "Rock",
		-- Montañas del terreno y rocas sueltas
		Candidates = { c("Real", "Rock", "Rock"), c("Mega", "Rough Rock", "Rock"), c("Tyler", "Stone3", "Rock"), find("Todos", { "rock" }, "Rock") },
		Whiten = 0.5,
		Why = "roca de las montañas del terreno",
	},
	{
		Material = "Ground",
		-- Claros de tierra del terreno y huertos. OJO: el «RealisticStone» del generador va sobre Ground.
		Candidates = { c("Real", "Ground", "Ground"), c("Mega", "Dry Dirt", "Ground"), c("Gen", "RealisticStone", "Ground"), c("Tyler", "Ground2", "Ground"), find("Todos", { "ground" }, "Ground") },
		Whiten = 0.5,
		Why = "tierra del terreno y los huertos",
	},
	{
		Material = "WoodPlanks",
		-- Suelos y tarimas de tablas: con patrón Regular (las tablas siguen rectas)
		Candidates = { c("RealMad", "Realistic Wood Planks", "WoodPlanks"), c("Real", "WoodPlanks", "WoodPlanks"), c("PBR", "WoodPlanks_PBR", "WoodPlanks") },
		Pattern = "Regular",
		Whiten = 0.35,
		Why = "tablas de madera rectas",
	},
	{
		Material = "Wood",
		-- La madera que no lleva nuestra «MaderaVeta» pieza a pieza (troncos, ramas y lo de fuera de
		-- la ciudad): madera genérica del pack de madera. Los muebles y puertas siguen con MaderaVeta.
		Candidates = { c("RealMad", "Realistic Wood", "Wood"), c("Real", "Wood", "Wood"), c("Gen", "RealisticWood", "Wood"), c("PBR", "Wood_PBR", "Wood") },
		Whiten = 0.35,
		Why = "madera genérica del pack de madera",
	},
	{
		Material = "CeramicTiles",
		-- Baños, cocinas y piscinas: los CeramicTiles de Tyler son los únicos sobre CeramicTiles
		Candidates = { c("Tyler", "CeramicTiles1", "CeramicTiles"), c("Tyler", "CeramicTiles5", "CeramicTiles"), find("Todos", { "ceramic" }, "CeramicTiles") },
		Pattern = "Regular",
		Whiten = 0.2,
		Why = "azulejo cerámico de Tyler",
	},
	{
		Material = "Pebble",
		-- Grava de caminos y alcorques: la del pack de piedras no existe; «Pebble_PBR» de PBR_Textures
		-- (sobre Pebble) y lo que traiga «ALL MATERIALS».
		Candidates = { c("PBR", "Pebble_PBR", "Pebble"), find("Todos", { "pebble" }, "Pebble") },
		Pattern = "Organic",
		Whiten = 0.4,
		Why = "grava de caminos (Pebble_PBR)",
	},
	{
		Material = "Mud",
		-- Barro de las granjas y corrales (Kit/AnimalKit): el del pack de piedras, el de Tyler y barro con musgo
		Candidates = { c("Real", "Mud", "Mud"), c("Tyler", "Mud2", "Mud"), c("Mega", "Mossy Mud", "Mud") },
		Pattern = "Organic",
		Whiten = 0.4,
		Why = "barro de granjas y corrales (Mud del pack de piedras)",
	},
	{
		Material = "DiamondPlate",
		-- Chapa estriada (rampas, escalones de camión, muelles): la del pack de madera, la de PBR_Textures
		Candidates = { c("RealMad", "Realistic Metal Plate", "DiamondPlate"), c("Real", "DiamondPlate", "DiamondPlate"), c("PBR", "Diamondplate_PBR", "DiamondPlate") },
		Whiten = 0.3,
		Why = "chapa estriada de muelles y rampas (Realistic Metal Plate)",
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

-- Nombre del pack que vale para un candidato: el exacto o, si busca por palabras, el más corto que
-- las lleve todas (a igualdad, el primero por orden alfabético: siempre el mismo). nil = ninguno.
-- names[nombre] = cualquier cosa (true o el BaseMaterial); bases (opcional) = BaseMaterial de cada uno,
-- para quedarse solo con los que vienen sobre From.
function UserMaterialChoice.match(cand: Candidate, names: { [string]: any }?, bases: { [string]: string }?): string?
	if not names then
		return nil
	end
	if cand.Name ~= "" and names[cand.Name] then
		return cand.Name
	end
	if not cand.Find then
		return nil
	end
	local best: string? = nil
	for name in names do
		local lower = string.lower(name)
		local ok = not bases or bases[name] == nil or bases[name] == cand.From
		for _, word in cand.Find do
			if ok and not string.find(lower, word, 1, true) then
				ok = false
			end
		end
		if ok and (best == nil or #name < #best or (#name == #best and name < (best :: string))) then
			best = name
		end
	end
	return best
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
			local name = UserMaterialChoice.match(cand, loaded[cand.Pack])
			if name then
				table.insert(picks, {
					Material = choice.Material,
					Pack = cand.Pack,
					Name = name,
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
