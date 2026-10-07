-- InteriorProps: muebles, comida y objetos de la Tienda de creadores (assets que eligió Sebastián)
-- dentro de las casas, tiendas, bares, oficinas, naves, el hospital y la comisaría de Valmar.
-- Qué trae cada asset: docs/assets-usuario*.md. Qué va dónde: InteriorProps.Rules (abajo) y
-- docs/assets-implementados.md.
--
--   * Al arrancar el servidor (Main, en un hilo aparte) carga cada asset UNA vez (World/AssetLoader:
--     AssetService:LoadAssetAsync y, si falla, InsertService:LoadAsset) y borra sus scripts.
--   * De cada asset se hace una copia LIMPIA (InteriorProps.clean): solo piezas (MeshPart, Part, Union)
--     con su malla (SpecialMesh…), su SurfaceAppearance y sus Texture. Todo lo demás se tira: scripts,
--     sonidos, luces, ProximityPrompt, ClickDetector, constraints, welds, Decal (logos), SurfaceGui
--     (textos), valores, atributos y etiquetas (ahí escondían los virus de la 4ª tanda: así no queda nada).
--     Sin las piezas con marcas reales (latas de cola, logo del autor, texturas bloqueadas) ni las de
--     otros juegos o de miedo (InteriorProps.AvoidNames). Nombre genérico en español, anclado, con
--     tope de piezas y escalado a una talla real (una persona mide ~5 studs).
--   * Se ponen en las salas al montarse (InteriorService.onBuilt, World/Interiors) y en los edificios
--     de la ciudad (naves, hospital, centro de salud, comisaría). Tres maneras:
--       OnTop   encima de un mueble (mesa, encimera, mostrador, cómoda, escritorio), en un hueco libre
--       Floor   en el suelo, pegado a una pared, cerca de algo (Near) y sin tapar puertas ni la entrada
--       Replace en lugar de una pieza hecha por código (almohadas, váter, puerta, alfombra, chimenea):
--               la de antes se esconde (etiqueta PropShell) y la malla se pone en su sitio, del mismo
--               tamaño; la de antes sigue chocando y se usa igual (sentarse, salir…).
--   * Nivel gráfico (shared/Graphics.DetailTags, Controllers/MaterialDetail): lo añadido lleva la
--     etiqueta DecorProp y la pieza de antes PropShell. Son muebles baratos: se ven en TODOS los
--     niveles, también en Bajo (si un nivel los escondiera, volvería a verse la pieza PropShell).
--   * Si un asset no carga, esa regla no hace nada. Si nada carga, todo se queda como estaba.

local InteriorProps = {}

local V = Vector3.new
local CF = CFrame.new

InteriorProps.Folder = "MueblesValmar" -- (dentro de cada sala o edificio: lo añadido)
InteriorProps.MaxParts = 160 -- tope de piezas por objeto

-- Los assets (nombre interno -> id de la Tienda)
InteriorProps.Assets = {
	TeleAntigua = 8236576991,
	Estanterias = 13395313510,
	MueblesGrunge = 13262637537,
	Mueble = 5674029686,
	MesaOrdenador = 5677783820,
	Vater = 8136205160,
	Almohada = 991205683,
	ComodaHotel = 106442157390222,
	PropsJaponeses = 130817699186912,
	PackIndustrial = 9802494780,
	PackRealista1 = 9658188636,
	PackRealista2 = 12110426279,
	ComidaCallejera = 17519952806,
	PackComida = 4609898985,
	MasComida = 82460675146164,
	HuevoFrito = 95413639317338,
	Magdalena = 9766849655,
	ComidaGato = 15666503758,
	Fajos = 1305075170,
	Portapapeles = 11329271645,
	PuertaMadera = 11444948273,
	SillaGigante = 166379099,
	CofrePremio = 123778443128832,
}

-- No se cargan nunca (y por qué)
InteriorProps.Skipped = {
	[123553303846741] = "las 65 texturas son las de Bloxburg (subidas por su creador) y trae un virus: no queda nada propio que usar",
}

-- Texturas que no se copian: marcas reales, el logo del autor y las que Roblox tiene bloqueadas
InteriorProps.DenyTextures = {
	["3152296920"] = true, -- lata de cola (marca real)
	["3152299417"] = true, -- lata de cola (marca real)
	["3152317461"] = true, -- botella de cola (marca real)
	["3156941268"] = true, -- logo del autor («JEJ»)
	["3157451449"] = true, -- bloqueada
	["3157529485"] = true, -- bloqueada
	["3157633680"] = true, -- bloqueada
	["52081598"] = true, -- bolsa de comida de gato con la marca pintada
}

-- Piezas que no se copian por su nombre (otros juegos, miedo, vehículos, armas). Patrones en minúsculas.
InteriorProps.AvoidNames = {
	"seek", "rush", "figure", "mimic", "doors", "bloxburg", "scp", "bone", "skull", "crow", "raven",
	"dracula", "zombie", "ritual", "candle", "corrupt", "hugo", "startercharacter", "explosive",
	"oil drum", "aid crate", "^car%s*%d", "truck", "hatchback", "frontloader", "torii", "gun", "weapon",
	"blood", "poster", "lore", "lsplash",
}

local HOMES = { Casa = true, Villa = true, Piso = true }
local HOMES_DORM = { Casa = true, Villa = true, Piso = true, Dorm = true }
local EATERIES = { Cafeteria = true, Bar = true, Pizzeria = true, Hamburgueseria = true, Kebab = true, Sushi = true }

export type Fit = { Height: number?, Max: number?, Range: { number }?, MaxFoot: number? }
export type Rule = {
	Name: string, -- nombre del objeto en el juego (español)
	Asset: string,
	Pick: { [string]: any }, -- Whole | All | Find (+Avoid, Count, MaxY, Tallest, Crop)
	Mode: string, -- OnTop | Floor | Replace | ReplaceModel | Store | NaveSide | NaveReplace | TownOnTop
	Kinds: { [string]: boolean }?, -- tipos de sala (Interior_<Tipo>)
	Shops: { [string]: boolean }?, -- comercios (atributo Shop de la sala)
	Anchors: { string }?, -- OnTop: piezas sobre las que va; Replace: piezas que cambia
	Near: { string }?, -- Floor: modelos junto a los que va
	Hide: { string }?, -- Replace: más piezas que se esconden (del mismo modelo)
	Model: string?, -- ReplaceModel: modelo que cambia
	Ref: string?, -- ReplaceModel: pieza que da el giro
	Tags: { string }?, -- TownOnTop: etiquetas de las piezas de la ciudad
	TownNames: { string }?, -- TownOnTop: o nombres
	Fit: Fit?,
	Count: number?, -- máximo por sala
	Chance: number?,
	Rebrand: { [string]: any }?,
}

-- Qué va dónde. (Las salas: World/Interiors. Los comercios: Interiors.ShopProfiles.)
InteriorProps.Rules = {
	-- Casas
	{ Name = "Almohada", Asset = "Almohada", Pick = { Whole = true }, Mode = "Replace", Anchors = { "Pillow" }, Kinds = HOMES_DORM, Count = 4 },
	{ Name = "Vater", Asset = "Vater", Pick = { Whole = true }, Mode = "ReplaceModel", Model = "Toilet", Ref = "ToiletBowl", Hide = { "ToiletBowl", "ToiletTank", "ToiletLid", "Flush" }, Fit = { Height = 3.1 }, Kinds = HOMES },
	{ Name = "PuertaMadera", Asset = "PuertaMadera", Pick = { Whole = true }, Mode = "Replace", Anchors = { "InteriorExit" }, Kinds = HOMES },
	{ Name = "AlfombraPersa", Asset = "MueblesGrunge", Pick = { Find = { "kilim", "khamseh", "carpet" } }, Mode = "Replace", Anchors = { "Rug" }, Hide = { "RugBorder", "RugCenter" }, Kinds = { Villa = true }, Count = 1 },
	{ Name = "Aparador", Asset = "MueblesGrunge", Pick = { Find = { "credenza" } }, Mode = "Floor", Near = { "Sofa", "TVUnit" }, Fit = { Range = { 2.5, 4.2 }, MaxFoot = 9 }, Kinds = { Villa = true, Casa = true }, Chance = 0.7 },
	{ Name = "Consola", Asset = "MueblesGrunge", Pick = { Find = { "console" } }, Mode = "Floor", Near = { "CoatRack" }, Fit = { Range = { 2.5, 4 }, MaxFoot = 7 }, Kinds = HOMES, Chance = 0.5 },
	{ Name = "Armario", Asset = "MueblesGrunge", Pick = { Find = { "amoire", "armoire", "wardrobe" } }, Mode = "Floor", Near = { "Bed" }, Fit = { Range = { 6.5, 8 }, MaxFoot = 7 }, Kinds = { Villa = true } },
	{ Name = "SillonCuadros", Asset = "MueblesGrunge", Pick = { Find = { "couch_single", "single_plaid", "armchair" } }, Mode = "Floor", Near = { "Fireplace", "Bookshelf" }, Fit = { Range = { 3, 4.5 }, MaxFoot = 5 }, Kinds = { Villa = true } },
	{ Name = "Mueble", Asset = "Mueble", Pick = { Whole = true }, Mode = "Floor", Near = { "DiningSet", "Sofa" }, Fit = { Range = { 2.8, 3.6 }, MaxFoot = 9 }, Kinds = { Casa = true, Piso = true }, Chance = 0.6 },
	{ Name = "TeleAntigua", Asset = "TeleAntigua", Pick = { Whole = true }, Mode = "OnTop", Anchors = { "Dresser" }, Fit = { Max = 2.6 }, Kinds = { Casa = true, Piso = true, Dorm = true }, Chance = 0.6 },
	{ Name = "ComodaHotel", Asset = "ComodaHotel", Pick = { Whole = true }, Mode = "Floor", Near = { "Bed" }, Fit = { Range = { 3, 3.6 }, MaxFoot = 4 }, Kinds = { Dorm = true, Casa = true }, Chance = 0.5 },
	{ Name = "PlatoComida", Asset = "PackComida", Pick = { All = true }, Mode = "OnTop", Anchors = { "TableTop", "Worktop" }, Fit = { Max = 1.8 }, Kinds = HOMES, Count = 1 },
	{ Name = "HuevoFrito", Asset = "HuevoFrito", Pick = { Whole = true }, Mode = "OnTop", Anchors = { "Plate" }, Fit = { Max = 0.85 }, Kinds = HOMES, Shops = { Cafeteria = true, Bar = true }, Count = 2, Chance = 0.7 },
	{ Name = "MontonComida", Asset = "MasComida", Pick = { Whole = true }, Mode = "OnTop", Anchors = { "Worktop", "CounterTop" }, Fit = { Height = 1.4 }, Kinds = { Villa = true }, Shops = { Ultramarinos = true, Fruteria = true }, Count = 1 },
	-- Restaurantes, bares y tiendas de comida
	{ Name = "PlatoComida", Asset = "PackComida", Pick = { All = true }, Mode = "OnTop", Anchors = { "TableTop" }, Fit = { Max = 1.8 }, Shops = EATERIES, Count = 3 },
	{ Name = "PinchoCallejero", Asset = "ComidaCallejera", Pick = { All = true }, Mode = "OnTop", Anchors = { "CounterTop" }, Fit = { Max = 1 }, Shops = { Kebab = true, Bar = true, Hamburgueseria = true }, Count = 3 },
	{ Name = "Magdalena", Asset = "Magdalena", Pick = { Whole = true }, Mode = "OnTop", Anchors = { "CounterTop", "ShowcaseBase" }, Fit = { Height = 0.7 }, Shops = { Panaderia = true, Cafeteria = true, Heladeria = true }, Count = 3 },
	{ Name = "Bonsai", Asset = "PropsJaponeses", Pick = { Find = { "bonsai" } }, Mode = "OnTop", Anchors = { "CounterTop" }, Fit = { Height = 1.6 }, Shops = { Sushi = true }, Count = 1 },
	{ Name = "Ramen", Asset = "PropsJaponeses", Pick = { Find = { "ramen", "noodle" } }, Mode = "OnTop", Anchors = { "TableTop" }, Fit = { Max = 1.2 }, Shops = { Sushi = true }, Count = 3 },
	{ Name = "FarolJapones", Asset = "PropsJaponeses", Pick = { Find = { "lamp", "lantern" } }, Mode = "Floor", Near = { "Checkout" }, Fit = { Range = { 2, 6 }, MaxFoot = 3 }, Shops = { Sushi = true }, Count = 2 },
	{ Name = "Jardinera", Asset = "PropsJaponeses", Pick = { Find = { "planter", "plant", "pot" }, Avoid = { "hanging", "colgante" } }, Mode = "Floor", Near = { "InteriorExit" }, Fit = { Range = { 1.5, 5 }, MaxFoot = 4 }, Shops = { Sushi = true }, Count = 2 },
	{ Name = "Nevera", Asset = "PackRealista2", Pick = { Find = { "fridge", "refrigerator" } }, Mode = "Floor", Near = { "BackBar", "Checkout" }, Fit = { Range = { 6, 7 }, MaxFoot = 4 }, Shops = { Bar = true, Cafeteria = true, Kebab = true, Hamburgueseria = true }, Count = 1 },
	{ Name = "SillaCafeteria", Asset = "PackRealista2", Pick = { Find = { "chair" }, Count = 3 }, Mode = "Floor", Near = { "Table" }, Fit = { Range = { 3, 4 }, MaxFoot = 2.6 }, Shops = { Cafeteria = true }, Count = 2 },
	-- Tiendas
	{ Name = "ComidaGato", Asset = "ComidaGato", Pick = { Whole = true }, Mode = "OnTop", Anchors = { "CounterTop", "ShelfBoard" }, Fit = { Height = 1.5 }, Shops = { Mascotas = true }, Count = 4, Rebrand = { Text = "KESTREL", Sub = "comida para gatos", Color = Color3.fromRGB(110, 60, 150) } },
	{ Name = "CasetaPerro", Asset = "PackRealista2", Pick = { Find = { "dog" } }, Mode = "Floor", Near = { "Checkout" }, Fit = { Range = { 3, 5 }, MaxFoot = 5 }, Shops = { Mascotas = true } },
	{ Name = "SillaGigante", Asset = "SillaGigante", Pick = { Whole = true }, Mode = "Floor", Near = { "Checkout" }, Fit = { Height = 9, MaxFoot = 10 }, Shops = { Muebles = true } },
	{ Name = "CofreRecompensa", Asset = "CofrePremio", Pick = { Whole = true }, Mode = "Floor", Near = { "Checkout" }, Fit = { Height = 2.6, MaxFoot = 4 }, Shops = { Jugueteria = true } },
	{ Name = "CofreRecompensa", Asset = "CofrePremio", Pick = { Whole = true }, Mode = "Store", Fit = { Height = 2.6, MaxFoot = 4 } },
	-- Banco, oficinas, comisaría, hospital
	{ Name = "FajosBilletes", Asset = "Fajos", Pick = { Whole = true }, Mode = "OnTop", Anchors = { "CounterTop" }, Fit = { Max = 2.4 }, Shops = { Banco = true }, Count = 1 },
	{ Name = "Portapapeles", Asset = "Portapapeles", Pick = { Whole = true }, Mode = "OnTop", Anchors = { "DeskTop" }, Fit = { Max = 1.1 }, Kinds = { Oficina = true, Juzgado = true, Hacienda = true, Cuartel = true }, Count = 2 },
	{ Name = "Portapapeles", Asset = "Portapapeles", Pick = { Whole = true }, Mode = "TownOnTop", Tags = { "ClinicDesk", "ClinicReception", "PoliceDesk" }, TownNames = { "NurseDesk" }, Fit = { Max = 1.1 } },
	{ Name = "MesaOrdenador", Asset = "MesaOrdenador", Pick = { Whole = true }, Mode = "Floor", Near = { "Desk" }, Fit = { Range = { 2.6, 5 }, MaxFoot = 7 }, Kinds = { Oficina = true }, Shops = { Inmobiliaria = true, Seguros = true, Copisteria = true } },
	{ Name = "MuebleOficina", Asset = "PackRealista1", Pick = { Find = { "pergolesi", "chair", "table", "desk", "sofa" }, Count = 4 }, Mode = "Floor", Near = { "Desk", "Plant" }, Fit = { Range = { 2.5, 5 }, MaxFoot = 6 }, Kinds = { Oficina = true, OficinaLobby = true }, Shops = { Banco = true, Seguros = true }, Count = 2 },
	{ Name = "Archivador", Asset = "PackRealista2", Pick = { Find = { "filing", "file cabinet" } }, Mode = "Floor", Near = { "FilingCabinet" }, Fit = { Range = { 3.5, 5 }, MaxFoot = 3 }, Kinds = { Oficina = true, Hacienda = true } },
	{ Name = "Sofa", Asset = "PackRealista2", Pick = { Find = { "sofa", "couch" } }, Mode = "Floor", Near = { "Plant" }, Fit = { Range = { 3, 4 }, MaxFoot = 8 }, Kinds = { OficinaLobby = true } },
	{ Name = "Extintor", Asset = "PackRealista2", Pick = { Find = { "extinguisher" } }, Mode = "Floor", Near = { "InteriorExit" }, Fit = { Height = 1.8 }, Kinds = { Oficina = true, OficinaLobby = true, Local = true, Cuartel = true, Aula = true, Nave = true } },
	{ Name = "Taquillas", Asset = "PackRealista2", Pick = { Find = { "locker" } }, Mode = "Floor", Near = { "Lockers", "Bench" }, Fit = { Range = { 6, 8 }, MaxFoot = 10 }, Kinds = { Cuartel = true, Nave = true } },
	{ Name = "Papelera", Asset = "PackRealista2", Pick = { Find = { "bin", "trash", "garbage" } }, Mode = "Floor", Near = { "Desk", "Checkout" }, Fit = { Range = { 1.6, 2.6 }, MaxFoot = 2 }, Kinds = { Oficina = true, OficinaLobby = true, Hacienda = true, Juzgado = true } },
	-- Naves
	{ Name = "EstanteriaAlmacen", Asset = "Estanterias", Pick = { All = true, Count = 1, Crop = 30 }, Mode = "Floor", Near = { "Rack" }, Fit = { Height = 13 }, Kinds = { Nave = true }, Count = 2 },
	{ Name = "DepositoIndustrial", Asset = "PackIndustrial", Pick = { All = true, MaxY = 25 }, Mode = "NaveSide", Fit = { Max = 13 } },
	{ Name = "ChimeneaIndustrial", Asset = "PackIndustrial", Pick = { All = true, Tallest = true }, Mode = "NaveReplace", Anchors = { "Chimney" } },
}

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

function InteriorProps.hash(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

local function lower(s: string): string
	return string.lower(s)
end

local function matchesAny(name: string, patterns: { string }?): boolean
	if not patterns then
		return false
	end
	local n = lower(name)
	for _, p in patterns do
		if string.find(n, p) then
			return true
		end
	end
	return false
end
InteriorProps.matchesAny = matchesAny

local function textureOf(p: Instance): string
	local ok, id = pcall(function()
		return (p :: any).TextureID
	end)
	if ok and type(id) == "string" then
		return id
	end
	return ""
end

local function prop(inst: Instance, name: string): string
	local ok, v = pcall(function()
		return (inst :: any)[name]
	end)
	return if ok and type(v) == "string" then v else ""
end

local function denied(id: string): boolean
	local digits = string.match(id or "", "(%d+)")
	return digits ~= nil and InteriorProps.DenyTextures[digits] == true
end

-- Caja alineada con los ejes de unas piezas (con su giro)
local function bounds(list: { BasePart }): (Vector3, Vector3)
	local lo = V(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in list do
		local cf, s = p.CFrame, p.Size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local e = V(
			math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
			math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
			math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
		)
		local c = cf.Position
		lo = V(math.min(lo.X, c.X - e.X), math.min(lo.Y, c.Y - e.Y), math.min(lo.Z, c.Z - e.Z))
		hi = V(math.max(hi.X, c.X + e.X), math.max(hi.Y, c.Y + e.Y), math.max(hi.Z, c.Z + e.Z))
	end
	return lo, hi
end
InteriorProps.bounds = bounds

local function partsOf(root: Instance): { BasePart }
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

-- Lo que hay dentro de un asset, objeto a objeto (un Model con piezas, o una pieza suelta)
function InteriorProps.units(root: Instance): { Instance }
	local out = {}
	local function hasDirectParts(m: Instance): boolean
		for _, c in m:GetChildren() do
			if c:IsA("BasePart") then
				return true
			end
		end
		return false
	end
	local function visit(node: Instance)
		for _, c in node:GetChildren() do
			if c:IsA("BasePart") then
				table.insert(out, c)
			elseif c:IsA("Model") or c:IsA("Tool") then
				if hasDirectParts(c) then
					table.insert(out, c)
				else
					visit(c)
				end
			elseif c:IsA("Folder") or c:IsA("Accessory") or c:IsA("Configuration") then
				visit(c)
			end
		end
	end
	visit(root)
	return out
end

---------------------------------------------------------------------
-- Copia limpia
---------------------------------------------------------------------

export type Template = { Model: Model, Size: Vector3, Name: string }

local function clearExtras(inst: Instance)
	local ok, attributes = pcall(inst.GetAttributes, inst)
	if ok then
		for k in attributes do
			inst:SetAttribute(k, nil)
		end
	end
	local okTags, tags = pcall(inst.GetTags, inst)
	if okTags then
		for _, t in tags do
			inst:RemoveTag(t)
		end
	end
end

-- ¿Se puede quedar este hijo de una pieza? (malla, apariencia PBR o textura sin marca)
local function keepChild(c: Instance): boolean
	if c:IsA("DataModelMesh") or c:IsA("SurfaceAppearance") then
		return true
	end
	if c:IsA("Texture") then
		return not denied(prop(c, "Texture"))
	end
	return false
end

-- Pasa por el nombre de la pieza y de sus modelos hasta source (sin contar source)
local function avoided(p: Instance, source: Instance, extra: { string }?): boolean
	local node: Instance? = p
	while node and node ~= source do
		if matchesAny(node.Name, InteriorProps.AvoidNames) or matchesAny(node.Name, extra) then
			return true
		end
		node = node.Parent
	end
	return false
end

local function scaleModel(model: Model, f: number)
	for _, p in partsOf(model) do
		local cf = p.CFrame
		local rot = cf - cf.Position
		p.Size = p.Size * f
		p.CFrame = CF(cf.Position * f) * rot
		for _, c in p:GetChildren() do
			if c:IsA("SpecialMesh") then
				local m = c :: any
				pcall(function()
					if m.MeshType == Enum.MeshType.FileMesh then
						m.Scale = m.Scale * f
					end
					m.Offset = m.Offset * f
				end)
			elseif c:IsA("Texture") then
				local t = c :: any
				t.StudsPerTileU *= f
				t.StudsPerTileV *= f
			end
		end
	end
end

-- Escala a la talla del juego. Devuelve el factor.
function InteriorProps.fitFactor(size: Vector3, fit: Fit?): number
	if not fit then
		return 1
	end
	local f = 1
	if fit.Height then
		f = fit.Height / math.max(size.Y, 1e-3)
	elseif fit.Max then
		f = fit.Max / math.max(size.X, size.Y, size.Z, 1e-3)
	elseif fit.Range then
		local h = math.clamp(size.Y, fit.Range[1], fit.Range[2])
		f = h / math.max(size.Y, 1e-3)
	end
	if fit.MaxFoot then
		local foot = math.max(size.X, size.Z) * f
		if foot > fit.MaxFoot then
			f *= fit.MaxFoot / foot
		end
	end
	return f
end

-- Copia limpia de source (Model o pieza): plantilla con el pivote (centro de la base) en el origen.
-- opts: Crop (largo máximo por su lado largo), Avoid (más nombres), Fit.
function InteriorProps.clean(source: Instance, name: string, opts: { [string]: any }?): Template?
	local o = opts or {}
	local list: { BasePart } = {}
	for _, p in partsOf(source) do
		local skip = p:IsA("SpawnLocation") or p.Transparency >= 0.98 or denied(textureOf(p)) or avoided(p, source, o.Avoid)
		if not skip then
			for _, c in p:GetChildren() do
				if c:IsA("SpecialMesh") and denied(prop(c, "TextureId")) and not o.Rebrand then
					skip = true
				end
			end
		end
		if not skip then
			table.insert(list, p)
		end
	end
	if #list == 0 then
		return nil
	end
	-- Recorte (solo un tramo de una estantería larguísima)
	if o.Crop then
		local lo, hi = bounds(list)
		local alongX = (hi.X - lo.X) >= (hi.Z - lo.Z)
		local start = if alongX then lo.X else lo.Z
		local kept = {}
		for _, p in list do
			local c = p.CFrame.Position
			if (if alongX then c.X else c.Z) - start <= o.Crop then
				table.insert(kept, p)
			end
		end
		list = kept
	end
	-- Tope de piezas: las más grandes
	if #list > InteriorProps.MaxParts then
		table.sort(list, function(a, b)
			return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z
		end)
		for i = #list, InteriorProps.MaxParts + 1, -1 do
			table.remove(list, i)
		end
	end
	local lo, hi = bounds(list)
	local pivot = CF((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	local model = Instance.new("Model")
	model.Name = name
	local i = 0
	for _, p in list do
		local okClone, clone = pcall(function()
			return p:Clone()
		end)
		if okClone and clone then
			local doomed = {}
			for _, c in clone:GetChildren() do
				if keepChild(c) then
					clearExtras(c)
					for _, cc in c:GetChildren() do
						table.insert(doomed, cc)
					end
				else
					table.insert(doomed, c)
				end
			end
			for _, d in doomed do
				pcall(function()
					d:Destroy()
				end)
			end
			clearExtras(clone)
			for _, c in clone:GetChildren() do
				if c:IsA("SpecialMesh") and denied(prop(c, "TextureId")) then
					(c :: any).TextureId = ""
				end
			end
			if clone:IsA("Seat") or clone:IsA("VehicleSeat") then
				pcall(function()
					(clone :: any).Disabled = true
				end)
			end
			i += 1
			clone.Name = name .. "_" .. i
			clone.Anchored = true
			clone.CanTouch = false
			local big = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z) >= 2 and not o.NoCollide
			clone.CanCollide = big
			clone.CanQuery = big
			clone.CastShadow = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z) >= 1
			clone.CFrame = pivot:ToObjectSpace(p.CFrame)
			clone.Parent = model
		end
	end
	if i == 0 then
		return nil
	end
	local size = hi - lo
	local f = InteriorProps.fitFactor(size, o.Fit)
	if math.abs(f - 1) > 1e-3 then
		scaleModel(model, f)
		-- Lo que choca se decide con la talla FINAL (antes, con la del asset: un armario hecho de piezas
		-- pequeñas y escalado a 7 studs no chocaba y el personaje se metía dentro)
		for _, p in partsOf(model) do
			local big = math.max(p.Size.X, p.Size.Y, p.Size.Z) >= 2 and not o.NoCollide
			p.CanCollide = big
			p.CanQuery = big
		end
	end
	pcall(function()
		model.WorldPivot = CF()
	end)
	local t: Template = { Model = model, Size = size * f, Name = name }
	if o.Rebrand then
		InteriorProps.rebrand(t, o.Rebrand)
	end
	return t
end

-- Marca inventada (la de verdad iba pintada en la textura, que ya se ha quitado)
function InteriorProps.rebrand(t: Template, brand: { [string]: any })
	for _, p in partsOf(t.Model) do
		for _, c in p:GetChildren() do
			if c:IsA("SpecialMesh") then
				(c :: any).TextureId = ""
			end
		end
		p.Color = brand.Color
		p.Material = Enum.Material.SmoothPlastic
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Etiqueta"
		gui.Face = Enum.NormalId.Front
		gui.PixelsPerStud = 60
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = brand.Text .. "\n" .. (brand.Sub or "")
		label.Parent = gui
		gui.Parent = p
	end
end

-- Cambia el tamaño de una plantilla de UNA pieza a una caja (en los ejes de la pieza a cambiar)
local function fitBox(t: Template, box: Vector3): Template
	local list = partsOf(t.Model)
	if #list == 1 then
		local p = list[1]
		local cf = p.CFrame
		local axes = { cf.RightVector, cf.UpVector, cf.LookVector }
		local want = { box.X, box.Y, box.Z }
		local s = {}
		for k, a in axes do
			local ax, ay, az = math.abs(a.X), math.abs(a.Y), math.abs(a.Z)
			s[k] = if ax >= ay and ax >= az then want[1] elseif ay >= az then want[2] else want[3]
		end
		p.Size = V(s[1], s[2], s[3])
		p.CFrame = CF(0, box.Y / 2, 0) * (cf - cf.Position)
		t.Size = box
	else
		local f = math.min(box.X / t.Size.X, box.Y / t.Size.Y, box.Z / t.Size.Z)
		scaleModel(t.Model, f)
		t.Size *= f
	end
	return t
end

---------------------------------------------------------------------
-- Plantillas
---------------------------------------------------------------------

-- Plantillas de una regla a partir de su asset (ya cargado)
function InteriorProps.templatesFor(rule: Rule, asset: Instance): { Template }
	local pick = rule.Pick
	local opts = { Fit = rule.Fit, Crop = pick.Crop, Avoid = pick.Avoid, Rebrand = rule.Rebrand, NoCollide = rule.Mode == "Replace" or rule.Mode == "ReplaceModel" or rule.Mode == "OnTop" or rule.Mode == "TownOnTop" or rule.Mode == "NaveReplace" }
	if rule.Mode == "Replace" or rule.Mode == "NaveReplace" then
		opts.Fit = nil -- (la talla la da la pieza que cambia)
	end
	local sources: { Instance } = {}
	if pick.Whole then
		-- (un asset con un solo objeto: se mira desde ese objeto, que suele llevar el título de la Tienda)
		local units = InteriorProps.units(asset)
		sources = if #units == 1 and units[1]:IsA("Model") then units else { asset }
	else
		local units = InteriorProps.units(asset)
		for _, u in units do
			local ok = true
			if pick.Find then
				ok = matchesAny(u.Name, pick.Find) and not matchesAny(u.Name, pick.Avoid)
			end
			if ok and matchesAny(u.Name, InteriorProps.AvoidNames) then
				ok = false
			end
			if ok and (pick.MaxY or pick.Tallest) then
				local lo, hi = bounds(partsOf(u))
				if pick.MaxY and hi.Y - lo.Y > pick.MaxY then
					ok = false
				end
			end
			if ok then
				table.insert(sources, u)
			end
		end
		if pick.Tallest and #sources > 0 then
			local best, bestH = sources[1], -1
			for _, u in sources do
				local lo, hi = bounds(partsOf(u))
				if hi.Y - lo.Y > bestH then
					best, bestH = u, hi.Y - lo.Y
				end
			end
			sources = { best }
		end
	end
	local out = {}
	for _, s in sources do
		if pick.Count and #out >= pick.Count then
			break
		end
		local t = InteriorProps.clean(s, rule.Name, opts)
		if t then
			table.insert(out, t)
		end
	end
	return out
end

-- Carga los assets que usan las reglas y hace las plantillas: library[índice de la regla] = { Template }
function InteriorProps.prepare(load: (number) -> Instance?, strip: ((Instance) -> any)?): { [number]: { Template } }
	local assets: { [string]: Instance | false } = {}
	local library: { [number]: { Template } } = {}
	for index, rule in InteriorProps.Rules do
		local key = rule.Asset
		if assets[key] == nil then
			local id = InteriorProps.Assets[key]
			local ok, asset = pcall(load, id)
			if ok and asset then
				if strip then
					pcall(strip, asset)
				end
				assets[key] = asset
			else
				assets[key] = false
				warn(("[InteriorProps] no carga %s (%s)"):format(key, tostring(id)))
			end
		end
		local asset = assets[key]
		if asset then
			local ok, list = pcall(InteriorProps.templatesFor, rule, asset :: Instance)
			if ok and #list > 0 then
				library[index] = list
			elseif not ok then
				warn("[InteriorProps] " .. rule.Name .. ": " .. tostring(list))
			end
		end
	end
	for _, asset in assets do
		if asset then
			pcall(function()
				(asset :: Instance):Destroy()
			end)
		end
	end
	return library
end

---------------------------------------------------------------------
-- Colocar
---------------------------------------------------------------------

export type Overlap = (CFrame, Vector3, Instance?) -> { BasePart }

local function defaultOverlap(cf: CFrame, size: Vector3, within: Instance?): { BasePart }
	local params = OverlapParams.new()
	if within then
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { within }
	end
	return workspace:GetPartBoundsInBox(cf, size, params)
end

-- Una copia de la plantilla en target (el centro de su base)
local function put(t: Template, target: CFrame, parent: Instance, tag: string?): Model
	local copy = t.Model:Clone()
	for _, p in partsOf(copy) do
		p.CFrame = target * p.CFrame
		p:AddTag(tag or "DecorProp")
		if p.CanCollide then
			p:SetAttribute("Solid", true)
		end
	end
	pcall(function()
		copy.WorldPivot = target
	end)
	copy.Parent = parent
	return copy
end

-- Lo grande que va en el suelo (armarios, cómodas, neveras, sofás, estanterías, taquillas…) es sólido:
-- una caja invisible de su tamaño (un poco más estrecha, para no chocar con el aire de sus huecos).
-- Las mallas de la Tienda vienen en piezas sueltas y finas, y con sus huecos el personaje se metía dentro.
InteriorProps.HitboxName = "Choque"
function InteriorProps.hitbox(copy: Model, t: Template, target: CFrame): BasePart?
	local s = t.Size
	if s.Y < 2 or math.max(s.X, s.Z) < 1.5 then
		return nil -- (lo pequeño, como una papelera o un extintor, no: así no te quedas enganchado)
	end
	local box = Instance.new("Part")
	box.Name = InteriorProps.HitboxName
	box.Size = V(math.max(s.X * 0.9, 1), s.Y, math.max(s.Z * 0.9, 1))
	box.CFrame = target * CF(0, s.Y / 2, 0)
	box.Anchored = true
	box.Transparency = 1
	box.CanCollide = true
	box.CanQuery = false
	box.CanTouch = false
	box.CastShadow = false
	box:AddTag("DecorProp")
	box:SetAttribute("Solid", true)
	box.Parent = copy
	return box
end

local CLEAR = { "door", "exit", "entry", "elevator", "clerk", "stairs", "spot" }

-- ¿Hay sitio para una caja (cf en el centro de su base)? Lo plano del suelo y ignore no cuentan.
local function free(overlap: Overlap, cf: CFrame, size: Vector3, within: Instance?, floorY: number, ignore: { [Instance]: boolean }?, onTable: boolean?): boolean
	local center = cf * CF(0, size.Y / 2 + 0.05, 0)
	local box = size - V(0.1, 0.1, 0.1)
	for _, p in overlap(center, box, within) do
		if not (ignore and ignore[p]) and p.Name ~= "Floor" and p.Name ~= "Ceiling" then
			local _, hi = bounds({ p })
			if hi.Y > floorY + 0.35 then
				return false
			end
		end
	end
	if onTable then
		return true
	end
	-- Sin tapar puertas, la entrada, el ascensor ni el sitio de los dependientes
	for _, p in overlap(center, box + V(6, 0, 6), within) do
		if matchesAny(p.Name, CLEAR) and not (ignore and ignore[p]) and not string.find(lower(p.Name), "mat") then
			return false
		end
	end
	return true
end
InteriorProps.free = free

local function yawOf(cf: CFrame): CFrame
	local look = cf.LookVector
	local flat = V(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		return CF()
	end
	return CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
end

local function namedParts(root: Instance, names: { string }): { BasePart }
	local set = {}
	for _, n in names do
		set[n] = true
	end
	local out = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and set[d.Name] then
			table.insert(out, d)
		end
	end
	return out
end

local function namedModels(root: Instance, names: { string }): { Instance }
	local set = {}
	for _, n in names do
		set[n] = true
	end
	local out = {}
	for _, d in root:GetDescendants() do
		if set[d.Name] then
			table.insert(out, d)
		end
	end
	return out
end

local function centerOf(inst: Instance): Vector3?
	local list = partsOf(inst)
	if #list == 0 then
		return nil
	end
	local lo, hi = bounds(list)
	return (lo + hi) / 2
end

-- Orden fijo pero distinto en cada sala
local function shuffled<T>(list: { T }, seed: string): { T }
	local out = table.clone(list)
	local h = InteriorProps.hash(seed)
	for i = #out, 2, -1 do
		h = (h * 1103515245 + 12345) % 2147483648
		local j = h % i + 1
		out[i], out[j] = out[j], out[i]
	end
	return out
end

local function hide(part: BasePart)
	if not part:HasTag("PropShell") then
		part:SetAttribute("ShellTransparency", part.Transparency)
		part.Transparency = 1
		part:AddTag("PropShell")
	end
end

-- Encima de piezas (mesas, encimeras…). Devuelve cuántos.
local function onTop(anchors: { BasePart }, templates: { Template }, folder: Instance, overlap: Overlap, within: Instance?, seed: string, count: number): number
	local n = 0
	local offsets = { { 0, 0 }, { 0.5, 0.3 }, { -0.5, -0.3 }, { 0.5, -0.3 }, { -0.5, 0.3 }, { 0.8, 0 }, { -0.8, 0 } }
	for k, anchor in shuffled(anchors, seed) do
		if n >= count then
			break
		end
		local t = templates[InteriorProps.hash(seed .. k) % #templates + 1]
		local lo, hi = bounds({ anchor })
		local half = (hi - lo) / 2
		local center = (lo + hi) / 2
		local r = math.max(t.Size.X, t.Size.Z) / 2
		for _, o in offsets do
			local dx = o[1] * math.max(half.X - r, 0)
			local dz = o[2] * math.max(half.Z - r, 0)
			local target = CF(center.X + dx, hi.Y, center.Z + dz) * yawOf(anchor.CFrame)
			if free(overlap, target, t.Size, within, hi.Y, { [anchor] = true }, true) then
				put(t, target, folder)
				n += 1
				break
			end
		end
	end
	return n
end

-- En el suelo de una sala, pegado a una pared y lo más cerca posible de Near. Devuelve cuántos.
local function onFloor(room: Instance, floor: BasePart, templates: { Template }, near: { string }?, folder: Instance, overlap: Overlap, seed: string, count: number): number
	local frame = floor.CFrame * CF(0, floor.Size.Y / 2, 0)
	local W, D = floor.Size.X, floor.Size.Z
	local anchors = {}
	for _, m in namedModels(room, near or {}) do
		local c = centerOf(m)
		if c then
			table.insert(anchors, c)
		end
	end
	local n = 0
	for k = 1, count do
		local t = templates[InteriorProps.hash(seed .. "#" .. k) % #templates + 1]
		local best, bestScore = nil, math.huge
		-- (lado: giro y posición; la espalda del mueble, +Z, a la pared)
		for side = 0, 3 do
			local yaw = ({ 0, math.pi / 2, math.pi, -math.pi / 2 })[side + 1]
			local along = if side % 2 == 0 then W else D
			local depth = t.Size.Z / 2 + 0.6
			local width = t.Size.X
			local step = 2
			local u = -along / 2 + width / 2 + 0.6
			while u <= along / 2 - width / 2 - 0.6 do
				local x, z
				if side == 0 then
					x, z = u, D / 2 - depth
				elseif side == 1 then
					x, z = W / 2 - depth, u
				elseif side == 2 then
					x, z = u, -D / 2 + depth
				else
					x, z = -W / 2 + depth, u
				end
				local target = frame * CF(x, 0, z) * CFrame.Angles(0, yaw, 0)
				local score = 0
				if #anchors > 0 then
					score = math.huge
					for _, a in anchors do
						score = math.min(score, (a - target.Position).Magnitude)
					end
				end
				score += (InteriorProps.hash(seed .. x .. ":" .. z) % 100) / 1000
				if score < bestScore then
					local rotated = if side % 2 == 0 then t.Size else V(t.Size.Z, t.Size.Y, t.Size.X)
					local box = CF(target.Position) * (frame - frame.Position)
					if free(overlap, box, rotated, room, frame.Position.Y) then
						best, bestScore = target, score
					end
				end
				u += step
			end
		end
		if best then
			InteriorProps.hitbox(put(t, best, folder), t, best)
			n += 1
		end
	end
	return n
end

-- En lugar de piezas hechas por código (misma caja). Devuelve cuántas.
local function replaceParts(root: Instance, rule: Rule, templates: { Template }, folder: Instance, seed: string): number
	local n = 0
	local count = rule.Count or 99
	for k, anchor in namedParts(root, rule.Anchors or {}) do
		if n >= count then
			break
		end
		if not anchor:HasTag("PropShell") then
			local base = templates[InteriorProps.hash(seed .. k) % #templates + 1]
			local t = { Model = base.Model:Clone(), Size = base.Size, Name = base.Name }
			local cf, size = anchor.CFrame, anchor.Size
			local target, box
			if math.abs(cf.RightVector.Y) > 0.9 then
				-- (cilindro de pie: su eje es X)
				box = V(size.Y, size.X, size.Z)
				target = CF(cf.Position - V(0, size.X / 2, 0))
			else
				box = size
				target = cf * CF(0, -size.Y / 2, 0)
			end
			fitBox(t, box)
			put(t, target, folder)
			hide(anchor)
			if anchor.Parent then
				for _, p in namedParts(anchor.Parent, rule.Hide or {}) do
					hide(p)
				end
			end
			n += 1
		end
	end
	return n
end

-- En lugar de un mueble entero (el váter): se esconden sus piezas menos el asiento
local function replaceModel(root: Instance, rule: Rule, templates: { Template }, folder: Instance): number
	local n = 0
	for _, m in namedModels(root, { rule.Model :: string }) do
		local hidden = namedParts(m, rule.Hide or {})
		local ref = m:FindFirstChild(rule.Ref or "")
		if #hidden > 0 and ref and ref:IsA("BasePart") and not ref:HasTag("PropShell") then
			local lo, hi = bounds(hidden)
			local target = CF((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2) * yawOf(ref.CFrame)
			put(templates[1], target, folder)
			for _, p in hidden do
				hide(p)
			end
			n += 1
		end
	end
	return n
end

local function folderIn(parent: Instance): Instance
	local f = parent:FindFirstChild(InteriorProps.Folder)
	if not f then
		f = Instance.new("Model")
		f.Name = InteriorProps.Folder
		f.Parent = parent
	end
	return f :: Instance
end

-- Amuebla una sala de World/Interiors (Model «Interior_<Tipo>»). Devuelve cuántos objetos puso.
function InteriorProps.dressRoom(room: Instance, library: { [number]: { Template } }, overlap: Overlap?): number
	if room:FindFirstChild(InteriorProps.Folder) then
		return 0
	end
	local kind = string.match(room.Name, "^Interior_(.+)$")
	local floor = room:FindFirstChild("Floor")
	if not kind or not (floor and floor:IsA("BasePart")) then
		return 0
	end
	local shop = room:GetAttribute("Shop")
	local key = room:GetAttribute("Key")
	local seed = if type(key) == "string" then key else room.Name
	local ov = overlap or defaultOverlap
	local folder = folderIn(room)
	local total = 0
	for index, rule in InteriorProps.Rules do
		local templates = library[index]
		local fits = (rule.Kinds and rule.Kinds[kind]) or (rule.Shops and kind == "Local" and type(shop) == "string" and rule.Shops[shop])
		if templates and #templates > 0 and fits then
			local s = seed .. "/" .. rule.Name .. index
			local lucky = rule.Chance == nil or (InteriorProps.hash(s) % 1000) / 1000 < rule.Chance
			if lucky then
				local ok, n = pcall(function()
					if rule.Mode == "OnTop" then
						return onTop(namedParts(room, rule.Anchors or {}), templates, folder, ov, room, s, rule.Count or 1)
					elseif rule.Mode == "Floor" then
						return onFloor(room, floor :: BasePart, templates, rule.Near, folder, ov, s, rule.Count or 1)
					elseif rule.Mode == "Replace" then
						return replaceParts(room, rule, templates, folder, s)
					elseif rule.Mode == "ReplaceModel" then
						return replaceModel(room, rule, templates, folder)
					end
					return 0
				end)
				if ok then
					total += n
				else
					warn("[InteriorProps] " .. rule.Name .. ": " .. tostring(n))
				end
			end
		end
	end
	return total
end

local function inside(inst: Instance, root: Instance): boolean
	local node = inst.Parent
	while node do
		if node == root then
			return true
		end
		node = node.Parent
	end
	return false
end

-- La ciudad: naves (depósitos y chimeneas), hospital, centro de salud y comisaría (portapapeles)
function InteriorProps.dressTown(town: Instance, library: { [number]: { Template } }, overlap: Overlap?, tagged: ((string) -> { Instance })?): number
	local ov = overlap or defaultOverlap
	local total = 0
	local naves = {}
	for _, d in town:GetDescendants() do
		if d.Name == "Nave" and d:IsA("Model") and d:FindFirstChild("Hall") and not d:FindFirstChild(InteriorProps.Folder) then
			table.insert(naves, d)
		end
	end
	for index, rule in InteriorProps.Rules do
		local templates = library[index]
		if templates and #templates > 0 then
			if rule.Mode == "NaveSide" then
				for k, nave in naves do
					local hall = nave:FindFirstChild("Hall") :: BasePart
					local t = templates[InteriorProps.hash(nave:GetFullName() .. k) % #templates + 1]
					local base = hall.CFrame * CF(0, -hall.Size.Y / 2, 0)
					local target = base * CF(hall.Size.X / 2 + 1.5 + t.Size.X / 2, 0, hall.Size.Z / 4) * CFrame.Angles(0, math.pi / 2, 0)
					if free(ov, target, V(t.Size.Z, t.Size.Y, t.Size.X), nil, base.Position.Y, { [hall] = true }) then
						InteriorProps.hitbox(put(t, target, folderIn(nave)), t, target)
						total += 1
					end
				end
			elseif rule.Mode == "NaveReplace" then
				for _, nave in naves do
					total += replaceParts(nave, rule, templates, folderIn(nave), nave:GetFullName())
				end
			elseif rule.Mode == "TownOnTop" then
				local anchors = {}
				local seen = {}
				for _, tag in rule.Tags or {} do
					for _, p in (if tagged then tagged(tag) else {}) do
						if p:IsA("BasePart") and not seen[p] and inside(p, town) then
							seen[p] = true
							table.insert(anchors, p)
						end
					end
				end
				for _, p in namedParts(town, rule.TownNames or {}) do
					if not seen[p] then
						seen[p] = true
						table.insert(anchors, p)
					end
				end
				for k, anchor in anchors do
					local holder = anchor.Parent or town
					total += onTop({ anchor :: BasePart }, templates, folderIn(holder), ov, nil, rule.Name .. k, 1)
				end
			end
		end
	end
	return total
end

-- Plantillas que se guardan para otros sistemas (el cofre del pase y de los premios)
function InteriorProps.store(library: { [number]: { Template } }, parent: Instance): number
	local folder = parent:FindFirstChild("ModelosPremio") or Instance.new("Folder")
	folder.Name = "ModelosPremio"
	local n = 0
	for index, rule in InteriorProps.Rules do
		local templates = library[index]
		if rule.Mode == "Store" and templates and templates[1] and not folder:FindFirstChild(rule.Name) then
			local m = templates[1].Model:Clone()
			m.Name = rule.Name
			m.Parent = folder
			n += 1
		end
	end
	folder.Parent = parent
	return n
end

---------------------------------------------------------------------
-- Arranque (Main, en un hilo aparte)
---------------------------------------------------------------------
function InteriorProps.start(load: ((number) -> Instance?)?)
	local World = script.Parent
	local loader = load or require(World.AssetLoader).download
	local MeshLibrary = require(World.MeshLibrary)
	local library = InteriorProps.prepare(loader, MeshLibrary.stripScripts)
	local kinds = 0
	for _ in library do
		kinds += 1
	end
	if kinds == 0 then
		warn("[InteriorProps] no cargó ningún asset: los interiores se quedan como estaban")
		return
	end
	pcall(InteriorProps.store, library, game:GetService("ReplicatedStorage"))
	-- La ciudad (ya construida en el archivo)
	local town = workspace:FindFirstChild("Town")
	if town then
		local CollectionService = game:GetService("CollectionService")
		local ok, n = pcall(InteriorProps.dressTown, town, library, nil, function(tag)
			return CollectionService:GetTagged(tag)
		end)
		if not ok then
			warn("[InteriorProps] ciudad: " .. tostring(n))
		end
	end
	-- Las salas que se montan al entrar alguien (y las que ya están)
	local services = World.Parent:FindFirstChild("Services")
	local module = services and services:FindFirstChild("InteriorService")
	if module then
		local okReq, InteriorService = pcall(require, module :: any)
		if okReq and type(InteriorService) == "table" and type(InteriorService.onBuilt) == "function" then
			InteriorService.onBuilt(function(inst: any)
				local model = inst and inst.Room and inst.Room.Model
				if model and model.Parent then
					-- (en otro hilo: no retrasa la entrada a la sala)
					task.spawn(function()
						local ok, err = pcall(InteriorProps.dressRoom, model, library)
						if not ok then
							warn("[InteriorProps] sala: " .. tostring(err))
						end
					end)
				end
			end)
		end
	end
	print(("[InteriorProps] %d de %d reglas con muebles de la Tienda"):format(kinds, #InteriorProps.Rules))
end

return InteriorProps
