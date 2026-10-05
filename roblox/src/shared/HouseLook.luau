-- HouseLook: qué textura realista de los packs del dueño lleva cada parte de las casas, el colegio,
-- los edificios públicos y las naves de Valmar (fachada, zócalo, tejado, contraventanas, madera…).
-- Lo aplica en vivo el servidor (World/HouseDress) justo después de cargar los packs
-- (World/UserMaterials) y de vestir las calles (World/StreetDress), antes de aclarar.
--
-- Cuentas puras (sin Instances): se prueban fuera de Roblox (scripts/test-houselook.luau).
--
--   * Los overrides globales (shared/UserMaterialChoice) de Plaster y ClayRoofTiles no se pueden poner
--     en un servidor real: sus variants vienen sobre otro material y a un variant de la Tienda NO se le
--     puede cambiar el BaseMaterial. Por eso las fachadas encaladas y los tejados seguían lisos. Aquí
--     se viste pieza a pieza (part.MaterialVariant) y, si hace falta, se cambia el MATERIAL DE LA PIEZA
--     al del variant (Convertible: estuco Plaster -> Concrete, teja ClayRoofTiles -> Brick…); se le
--     deja la física de antes (como World/StreetDress).
--   * Variedad por edificio, fija según su sitio: 3 estucos, 2 ladrillos, 2 tejas, 2 piedras de
--     zócalo… (Variety = cuántos de la lista se reparten; los demás son respaldo por si no cargan).
--   * El color de cada casa se conserva: la pieza solo se aclara un poco (Whiten, como
--     UserMaterials.tint) porque estas texturas traen su propio color y Roblox lo multiplica por el de
--     la pieza. El estuco casi no (es blanco roto: el pastel de cada casa sigue mandando).
--   * Solo piezas de edificio por NOMBRE (Roles) y MATERIAL: nunca cristales, puertas (Door, DoorPanel,
--     GarageDoor…), lo que ya lleva variant propio (la madera con veta de las puertas, la pintura…),
--     lo invisible, los edificios ya cambiados por prefabs 3D (World/Buildings3D), ni las salas de los
--     interiores (InteriorService, en el cielo). Los variants no añaden piezas: en gráficos Bajo pesa
--     lo mismo.
--   * Elección solo por NOMBRE (las texturas no se pueden mirar desde un script): cada fila dice por qué.

local HouseLook = {}

-- Find: para los packs sin lista en los docs («ALL MATERIALS»): palabras que tiene que llevar el nombre
-- (minúsculas); se queda el más corto que venga sobre From. Solo de respaldo, nunca el primero.
export type Candidate = { Pack: string, Name: string, From: string, Find: { string }? }
export type Look = {
	Options: { Candidate }, -- en orden: los primeros Variety que carguen se reparten; el resto, respaldo
	Variety: number,
	Weights: { number }?, -- peso de cada uno de los que se reparten (nil = iguales)
	Pattern: ("Regular" | "Organic")?, -- solo si el variant es solo de los edificios
	Whiten: number, -- cuánto se aclara el color de la pieza (0 = nada, 1 = blanco)
	Why: string,
}

local function c(pack: string, name: string, from: string): Candidate
	return { Pack = pack, Name = name, From = from }
end
local function find(pack: string, words: { string }, from: string): Candidate
	return { Pack = pack, Name = "", From = from, Find = words }
end

-- Material de la pieza -> BaseMaterial de los variants que puede llevar (además del suyo). Sonido y
-- aspecto parecidos; la física se deja como estaba y nada del juego mira estos materiales.
HouseLook.Convertible = {
	Plaster = { Concrete = true, Brick = true }, -- estucos del Mega Pack (sobre Concrete); colegio de ladrillo
	SmoothPlastic = { Concrete = true }, -- casas modernas: enfoscado liso
	ClayRoofTiles = { Brick = true, CeramicTiles = true }, -- tejas (Clay Shingles sobre Brick, Roof1 sobre CeramicTiles)
	Cobblestone = { Brick = true }, -- zócalo de sillares
	Wood = { WoodPlanks = true }, -- contraventanas de tablas
	WoodPlanks = { Wood = true }, -- vigas y paños de madera
	CorrodedMetal = { Metal = true }, -- chapa de las naves
} :: { [string]: { [string]: boolean } }

function HouseLook.canUse(partMaterial: string, variantBase: string): boolean
	if partMaterial == variantBase then
		return true
	end
	local list = HouseLook.Convertible[partMaterial]
	return list ~= nil and list[variantBase] == true
end

HouseLook.Looks = {
	Estuco = {
		-- Fachadas encaladas mediterráneas: estuco liso, estuco normal y enlucido rugoso (el de las
		-- casas de pueblo). Blanco roto: el color pastel de cada casa se sigue viendo. Respaldo: el
		-- estuco granulado y el yeso fibroso. Orgánico: sin repetición en fachadas enteras.
		Options = {
			c("Mega", "Smooth Stucco", "Concrete"),
			c("Mega", "Stucco", "Concrete"),
			c("Mega", "Stucco TexturedRoughPlasteredMaterial", "Concrete"),
			c("Mega", "Grainy Stucco", "Concrete"),
			c("Mega", "Fibrous Plaster", "Concrete"),
			find("Todos", { "stucco" }, "Concrete"),
		},
		Variety = 3,
		Pattern = "Organic",
		Whiten = 0.1,
		Why = "estuco/enlucido de fachada mediterránea (Smooth Stucco, Stucco, enlucido rugoso)",
	},
	EstucoLiso = {
		-- Casas modernas (antes plástico liso): enfoscado liso pintado
		Options = { c("Mega", "Smooth Stucco", "Concrete"), c("Mega", "Stucco", "Concrete") },
		Variety = 1,
		Whiten = 0.06,
		Why = "enfoscado liso de las casas modernas (Smooth Stucco)",
	},
	Ladrillo = {
		-- Ladrillo visto rojo con hiladas rectas: «Red Bricks» del Mega Pack y el «Realistic Bricks»
		-- del pack de madera (el global). Respaldo: el del generador.
		-- 3 ladrillos repartidos por edificio (antes 2): que dos bloques de ladrillo vecinos no sean
		-- iguales. Respaldo: «Brick_PBR» de PBR_Textures y el de ALL MATERIALS.
		Options = {
			c("Mega", "Red Bricks", "Brick"),
			c("RealMad", "Realistic Bricks", "Brick"),
			c("Gen", "RealisticBricks", "Brick"),
			c("PBR", "Brick_PBR", "Brick"),
			find("Todos", { "brick" }, "Brick"),
		},
		Variety = 3,
		Whiten = 0.45,
		Why = "ladrillo visto rojo (Red Bricks, Realistic Bricks y el del generador)",
	},
	Colegio = {
		-- Colegio: ladrillo cara vista moderno (el de los colegios públicos de verdad), a juego con su
		-- color terracota. Respaldo: los ladrillos rojos.
		Options = { c("Mega", "Modern Brick", "Brick"), c("Mega", "Red Bricks", "Brick"), c("RealMad", "Realistic Bricks", "Brick") },
		Variety = 1,
		Whiten = 0.5,
		Why = "ladrillo cara vista del colegio (Modern Brick)",
	},
	Zocalo = {
		-- Zócalo: sillares de piedra (no adoquín de calle): piedra labrada desgastada y muro de bloques
		-- (3 repartidos: sillares labrados, muro de bloques y piedra cincelada; respaldo: PBR_Textures)
		Options = {
			c("Mega", "Chipped Stonework", "Cobblestone"),
			c("Mega", "Stone Block Wall", "Brick"),
			c("Mega", "Chisled Cobble", "Cobblestone"),
			c("Real", "Cobblestone", "Cobblestone"),
			c("PBR", "Cobblestone_PBR", "Cobblestone"),
		},
		Variety = 3,
		Whiten = 0.35,
		Why = "piedra de zócalo (Chipped Stonework, Stone Block Wall)",
	},
	Teja = {
		-- Tejas de barro: «Clay Shingles» del Mega Pack (la más común) y «Roof1» de Tyler (cerámica).
		-- Respaldo: Roof2 de Tyler. Las hiladas de Kit/CityDetail también.
		-- 3 tejas repartidas (antes 2): la árabe de barro manda (peso 3) y las cerámicas de Tyler dan
		-- variedad. Respaldo: lo que traiga ALL MATERIALS de tejas.
		Options = {
			c("Mega", "Clay Shingles", "Brick"),
			c("Tyler", "Roof1", "CeramicTiles"),
			c("Tyler", "Roof2", "CeramicTiles"),
			find("Todos", { "roof" }, "ClayRoofTiles"),
			find("Todos", { "shingle" }, "ClayRoofTiles"),
		},
		Variety = 3,
		Weights = { 3, 1, 1 },
		Whiten = 0.45,
		Why = "teja de barro/cerámica (Clay Shingles y Roof1)",
	},
	Contraventana = {
		-- Contraventanas de tablas pintadas (de verdad son de madera pintada): «Worn Painted Wood Siding»
		Options = { c("Mega", "Worn Painted Wood Siding", "WoodPlanks"), c("RealMad", "Realistic Wood Planks", "WoodPlanks"), c("PBR", "WoodPlanks_PBR", "WoodPlanks") },
		Variety = 1,
		Whiten = 0.3,
		Why = "contraventanas de tablas pintadas (Worn Painted Wood Siding)",
	},
	Tablas = {
		-- Casas coloniales (de tablas): el mismo entablado pintado
		Options = { c("Mega", "Worn Painted Wood Siding", "WoodPlanks"), c("RealMad", "Realistic Wood Planks", "WoodPlanks") },
		Variety = 1,
		Whiten = 0.25,
		Why = "fachada de tablas pintadas de las casas coloniales",
	},
	Madera = {
		-- Vigas, postes del porche, remates del tejado y paños de madera: roble
		Options = { c("Mega", "Mature Oak", "Wood"), c("Mega", "Oak", "Wood"), c("RealMad", "Realistic Wood", "Wood"), c("PBR", "Wood_PBR", "Wood") },
		Variety = 3,
		Whiten = 0.3,
		Why = "madera de roble de vigas y postes (Mature Oak, Oak)",
	},
	Hormigon = {
		-- Edificios públicos y bloques modernos: hormigón fino arquitectónico. Respaldo: el global.
		Options = {
			c("Mega", "Fine Particles Concrete", "Concrete"),
			c("Mega", "Concrete 1", "Concrete"),
			c("Real", "Concrete", "Concrete"),
			c("PBR", "Concrete_PBR", "Concrete"),
			find("Todos", { "concrete" }, "Concrete"),
		},
		Variety = 3,
		Whiten = 0.35,
		Why = "hormigón fino de edificios públicos (Fine Particles Concrete, Concrete 1)",
	},
	Nave = {
		-- Naves industriales: chapa de fábrica (la de verdad es chapa grecada). Respaldo: el lateral de
		-- contenedor de Tyler y la chapa vieja.
		Options = {
			c("Mega", "Worn Factory Siding", "Metal"),
			c("Mega", "Rigid Metal Siding", "Metal"),
			c("Tyler", "ContainerSide", "Metal"),
			c("Mega", "Old Sheet Metal", "CorrodedMetal"),
			c("PBR", "CorrodedMetal_PBR", "CorrodedMetal"),
		},
		Variety = 2,
		Whiten = 0.35,
		Why = "chapa de nave industrial (Worn Factory Siding, Rigid Metal Siding)",
	},
	NaveTecho = {
		Options = { c("Mega", "Rigid Metal Siding", "Metal"), c("Tyler", "ContainerSide", "Metal") },
		Variety = 1,
		Whiten = 0.3,
		Why = "cubierta de chapa de las naves (Rigid Metal Siding)",
	},
	NaveHormigon = {
		-- Muelles de carga: hormigón industrial basto
		Options = { c("Mega", "Concrete IndustrialGrittySturdyMaterial", "Concrete"), c("Real", "Concrete", "Concrete") },
		Variety = 1,
		Whiten = 0.35,
		Why = "hormigón industrial de los muelles de carga",
	},
} :: { [string]: Look }

-- Nombre de pieza -> parte del edificio. Lo que no está aquí (cristales, puertas, marcos, ventanas,
-- barandillas, carteles, muebles…) nunca se toca.
HouseLook.Roles = {
	-- Paredes y lo que va del color de la pared
	Body = "Wall", -- casas (HouseKit), bloques (Lite), villas
	Wall = "Wall", -- edificios de Kit/Building, tapias
	Upper = "Wall",
	Garage = "Wall",
	Parapet = "Wall",
	GableWall = "Wall",
	Gable = "Wall",
	GatePillar = "Wall",
	Chimney = "Wall",
	Mullion = "Wall",
	Cornice = "Wall",
	Trim = "Wall", -- (impostas, alféizares y zócalo de Kit/Building del material de la fachada)
	BalconySlab = "Wall",
	Balcony = "Wall",
	Hall = "Wall", -- naves
	Dock = "Wall",
	-- Zócalos
	Plinth = "Plinth",
	StonePlinth = "Plinth",
	-- Tejados (faldones, hiladas de CityDetail, cumbreras, porches y garajes)
	Roof = "Roof",
	RoofTiles = "Roof",
	Ridge = "Roof",
	RidgeTiles = "Roof",
	PorchRoof = "Roof",
	GarageRoof = "Roof",
	-- Carpintería
	Shutter = "Shutter",
	Verge = "Wood",
	PorchPost = "Wood",
	Cladding = "Wood",
	FlowerBox = "Wood",
} :: { [string]: string }

-- Carpetas que nunca se miran (salas de los interiores)
HouseLook.SkipAncestors = { Interiores = true, Interior = true }
HouseLook.SKY_Y = 2000 -- por encima, salas de interiores (InteriorService las monta a 6000)

export type PartInfo = {
	Name: string,
	Material: string, -- Enum.Material.Name
	Variant: string?, -- MaterialVariant que ya lleva
	Kind: string?, -- "Colegio", "Nave" u otro (de los modelos que la contienen)
	Style: string?, -- atributo Style de la casa (HouseKit)
	Transparency: number?,
	Y: number?,
	Skip: boolean?, -- prefab 3D, caja escondida, interior, malla con textura…
}

-- Qué aspecto lleva una pieza (nil = no se toca)
function HouseLook.classify(info: PartInfo): string?
	local role = HouseLook.Roles[info.Name]
	if not role or info.Skip or (info.Variant ~= nil and info.Variant ~= "") then
		return nil
	end
	if (info.Transparency or 0) >= 0.95 or (info.Y or 0) > HouseLook.SKY_Y then
		return nil
	end
	local m, kind, style = info.Material, info.Kind, info.Style
	if role == "Wall" then
		if m == "Plaster" then
			return if kind == "Colegio" then "Colegio" else "Estuco"
		elseif m == "Brick" then
			return if kind == "Colegio" then "Colegio" else "Ladrillo"
		elseif m == "Concrete" then
			return if kind == "Nave" then "NaveHormigon" else "Hormigon"
		elseif m == "CorrodedMetal" then
			return if kind == "Nave" then "Nave" else nil
		elseif m == "SmoothPlastic" then
			-- (solo las paredes de las casas modernas: el plástico liso de lo demás es otra cosa)
			local wall = info.Name == "Body" or info.Name == "Parapet" or info.Name == "Garage"
			return if style == "Moderna" and wall then "EstucoLiso" else nil
		elseif m == "WoodPlanks" then
			return if style == "Colonial" and info.Name ~= "Cladding" then "Tablas" else nil
		end
		return nil
	elseif role == "Plinth" then
		return if m == "Cobblestone" then "Zocalo" else nil
	elseif role == "Roof" then
		if m == "ClayRoofTiles" then
			return "Teja"
		elseif m == "Metal" and kind == "Nave" then
			return "NaveTecho"
		end
		return nil
	elseif role == "Shutter" then
		return if m == "Wood" or m == "WoodPlanks" then "Contraventana" else nil
	elseif role == "Wood" then
		return if m == "Wood" or m == "WoodPlanks" then "Madera" else nil
	end
	return nil
end

-- Clase de edificio por los nombres de los modelos que contienen la pieza (de dentro a fuera)
function HouseLook.kindOf(names: { string }): string?
	for _, name in names do
		if name == "Colegio" then
			return "Colegio"
		elseif name == "Nave" then
			return "Nave"
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Elección del variant
---------------------------------------------------------------------

-- Candidatos de un aspecto que se pueden usar, en orden, ya recortados a su variedad.
-- available[pack][nombre] = BaseMaterial de verdad del variant cargado.
function HouseLook.candidates(key: string, available: { [string]: { [string]: string } }): { Candidate }
	local look = HouseLook.Looks[key]
	local out = {}
	if not look then
		return out
	end
	for _, cand in look.Options do
		local pack = available[cand.Pack]
		local name = cand.Name
		if pack and cand.Find then
			name = HouseLook.match(cand.Find, cand.From, pack) or ""
		end
		local base = pack and pack[name]
		-- (el BaseMaterial de verdad: el del doc o, si el override global sí pudo cambiarlo, como en
		-- Studio, el nuevo; cada pieza mira luego si lo puede llevar)
		if base then
			table.insert(out, { Pack = cand.Pack, Name = name, From = base })
			if #out >= look.Variety then
				break
			end
		end
	end
	return out
end

-- El nombre más corto de pack (pack[nombre] = BaseMaterial) que lleva todas las palabras y viene sobre
-- from (a igualdad, el primero por orden alfabético: siempre el mismo). nil = ninguno.
function HouseLook.match(words: { string }, from: string, pack: { [string]: string }): string?
	local best: string? = nil
	for name, base in pack do
		local lower = string.lower(name)
		local ok = base == from
		for _, word in words do
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

-- Azar fijo según el sitio (0..1), el mismo de Kit/CityDetail
function HouseLook.hash(x: number, z: number, salt: number): number
	local v = math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	v -= math.floor(v)
	local w = math.sin(v * 91.345 + salt * 3.117 + x * 0.013) * 24634.6345
	return w - math.floor(w)
end

-- Sal de cada aspecto (que el estuco y la teja de una casa salgan independientes)
local SALT = { Estuco = 101, EstucoLiso = 102, Ladrillo = 103, Colegio = 104, Zocalo = 105, Teja = 106, Contraventana = 107, Tablas = 108, Madera = 109, Hormigon = 110, Nave = 111, NaveTecho = 112, NaveHormigon = 113 }

-- Los de la lista que puede llevar una pieza de este material (en orden)
function HouseLook.usable<T>(list: { T & { Base: string } }, partMaterial: string): { T }
	local out = {}
	for _, r in list do
		if HouseLook.canUse(partMaterial, r.Base) then
			table.insert(out, r)
		end
	end
	return out
end

-- Cuál de los n candidatos le toca al edificio que está en (x, z): 1..n (siempre el mismo)
function HouseLook.pick(key: string, n: number, x: number, z: number): number
	if n <= 1 then
		return 1
	end
	local look = HouseLook.Looks[key]
	local weights = {}
	local total = 0
	for i = 1, n do
		local w = (look and look.Weights and look.Weights[i]) or 1
		weights[i] = w
		total += w
	end
	-- (redondeo a décimas de stud: la misma casa da lo mismo aunque se mire desde otra pieza)
	local r = HouseLook.hash(math.floor(x * 10 + 0.5) / 10, math.floor(z * 10 + 0.5) / 10, SALT[key] or 100) * total
	for i = 1, n do
		r -= weights[i]
		if r < 0 then
			return i
		end
	end
	return n
end

-- Color aclarado hacia el blanco (como UserMaterialChoice.whiten)
function HouseLook.whiten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), math.clamp(amount, 0, 1))
end

return HouseLook
