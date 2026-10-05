-- NatureAssets: los packs de naturaleza que eligió Sebastián en la Tienda de creadores (revisados en
-- docs/assets-usuario-2.md … -5.md), por toda Valmar.
--
--   * Carga (una vez, en el servidor) con AssetService:LoadAssetAsync y, si falla,
--     InsertService:LoadAsset. De cada pack SOLO se copian MeshPart con su SurfaceAppearance (PBR):
--     scripts, sonidos, huesos, decals, carteles, SurfaceGui, textos, NumberPose, PlaneConstraint…
--     no pasan nunca (varios packs traían puertas traseras o carteles del autor). Además se borran
--     todos los LuaSourceContainer de lo cargado antes de tirarlo.
--   * Solo se usan los objetos de una lista por nombre (los árboles, palmeras, rocas, peces…): así
--     las mallas sacadas de juegos que hay en algunos packs (Half-Life 2, Sketchfab…) no entran.
--   * Árboles, palmeras, abetos y arbustos: no se plantan aparte. Se añaden como plantillas a
--     World/MeshLibrary (extend), que ya cambia en una sola pasada los árboles procedurales de
--     Kit/Nature: nada se planta dos veces. Las palmeras van donde ya había palmeras (playas, plaza
--     mayor, chalés) y los abetos/pinos al monte (cipreses del campo y parte de los árboles).
--   * Lo que se añade (start): rocas grandes con musgo en las laderas, las orillas del río y los
--     lagos; piedras pequeñas en el césped de los parques; peces de verdad en el mostrador de las
--     pescaderías; tiburones que nadan mar adentro; y los peces que nadan al bucear con fusil
--     (DivingService, piezas SwimFish) pasan a verse con su malla.
--   * Lo pequeño lleva la etiqueta LeafDetail (el nivel gráfico Bajo lo esconde, Controllers/
--     MaterialDetail). Las rocas grandes chocan y no se esconden (son parte del paisaje).
--   * Los packs con puerta trasera (docs/assets-usuario-4.md, familias 1, 3 y 5) no se cargan nunca
--     (Blocked): van sus recambios limpios de docs/assets-reemplazos.md. Aun así, de todo lo cargado
--     se borran TODOS los LuaSourceContainer nada más descargar, con lo cargado aún sin padre, ANTES
--     de meter nada en ningún sitio, y luego solo se copian las mallas (Log lo apunta).
--   * Rincón japonés en los parques más grandes: cerezo en flor, dos faroles de piedra y dos
--     guardianes de piedra. Hogueras junto a las mesas de pícnic del parque natural (con fuego y
--     luz nuestros).
--   * Si algo no carga, el juego sigue con lo procedural, sin errores.

local MeshLibrary = require(script.Parent.MeshLibrary)

local NatureAssets = {}

type Take = { Kind: string, Match: { string }, MaxUses: number?, Whole: boolean?, KeepTextures: boolean? }
type Pack = { Id: number, Name: string, Take: { Take } }

-- Qué se coge de cada pack (nombres tal cual vienen; se comparan en minúsculas)
NatureAssets.Packs = {
	-- Realistic Trees Pack [MOVING]: 4 árboles PBR. Sus 14 scripts (viento y sonidos) fuera: el viento
	-- lo pone nuestro Sway (Controllers/ObjectMotion)
	{ Id = 96924659951632, Name = "ArbolesViento", Take = {
		{ Kind = "Park", Match = { "^oaktree$", "^cherrytree$", "^oldtree$" }, MaxUses = 160 },
		{ Kind = "Conifer", Match = { "^pinetree$" }, MaxUses = 160 },
	} },
	-- Realistic Pack (RedWood Roleplay): palmeras PalmtreeVar0/1, rocas grandes y arbustos
	{ Id = 8553512581, Name = "PackNaturaleza", Take = {
		{ Kind = "Palm", Match = { "^palmtreevar" }, MaxUses = 400 },
		{ Kind = "Boulder", Match = { "^largemossboulder$", "^largeriverboulder$" } },
		{ Kind = "Bush", Match = { "^bush$", "^flowerbush$", "^fern$" }, MaxUses = 300 },
	} },
	-- Mossy rock pack: rocas con musgo
	{ Id = 16879341926, Name = "RocasMusgo", Take = {
		{ Kind = "Boulder", Match = { "^boulder$", "^largeboulder$", "^rock$", "^nordic cliff$" } },
	} },
	-- Realistic Terrain Asset Pack: solo las 4 «Palm Tree» sueltas (el resto, recopilado de otros)
	{ Id = 13388285234, Name = "PalmerasTerreno", Take = {
		{ Kind = "Palm", Match = { "^palm tree$" }, MaxUses = 300 },
	} },
	-- Realistic Landscape Pack: rocas medianas con musgo y rododendros (muy pesado entero: poco)
	{ Id = 13877830677, Name = "Paisaje", Take = {
		{ Kind = "Boulder", Match = { "^medium moss boulder$" } },
		{ Kind = "Bush", Match = { "^rhododendron$" }, MaxUses = 300 },
	} },
	-- Realistic Rock Pack: 5 piedras pequeñas (~1 000 tris)
	{ Id = 9262569938, Name = "Piedras", Take = {
		{ Kind = "Pebble", Match = { "type%d$" } },
	} },
	-- Velvet's Realistic Nature Pack: robles, arce y olmo (parques) y abetos (monte). Pesados: pocos
	{ Id = 8919681750, Name = "Velvet", Take = {
		{ Kind = "Park", Match = { "^oak%-0%d%-0lod", "^mapletree%-01", "^elmtree%-01" }, MaxUses = 60 },
		{ Kind = "Conifer", Match = { "^douglasfir%-0%d", "^oldsprucetree%-0%d", "^ponderosapine01" }, MaxUses = 60 },
	} },
	-- Recambios limpios (docs/assets-reemplazos.md: sin virus, revisados uno a uno) de los packs
	-- con puerta trasera, que no se cargan nunca (Blocked)
	-- Palm Tree (Realistic): palmera de 3 mallas, muy ligera
	{ Id = 10562894034, Name = "Palmera", Take = {
		{ Kind = "Palm", Match = { "palm" }, MaxUses = 300, Whole = true },
	} },
	-- Tropical PBR Plants: solo las palmeras (sin el tocón, el maniquí «Scale» ni la cámara)
	{ Id = 9501994254, Name = "Tropical", Take = {
		{ Kind = "Palm", Match = { "^large palm$", "^curved palm$", "^straight palm$", "^dark palm$", "^thick palm$", "^small palm$" }, MaxUses = 200 },
	} },
	-- Cherry Blossom Tree y Sakura Park Tree: cerezos del rincón japonés (sin pétalos ni StringValue)
	{ Id = 10586979345, Name = "Cerezo", Take = {
		{ Kind = "Sakura", Match = { "cherry", "blossom", "sakura" }, Whole = true },
	} },
	{ Id = 15343255788, Name = "CerezoParque", Take = {
		{ Kind = "Sakura", Match = { "cherry", "blossom", "sakura" }, Whole = true },
	} },
	-- PBR Bush
	{ Id = 9522573337, Name = "ArbustoPBR", Take = {
		{ Kind = "Bush", Match = { "bush" }, MaxUses = 250, Whole = true },
	} },
	-- Landscaping Pack (Roblox): arbustos de la carpeta Bushes y la hoguera del FirePit
	{ Id = 10840661513, Name = "Jardineria", Take = {
		{ Kind = "Bush", Match = { "rhododendron", "laurel", "fern", "chinese_evergreen", "philodendron" }, MaxUses = 250 },
		{ Kind = "Campfire", Match = { "^campfire$" } },
	} },
	-- Farol de piedra japonés
	{ Id = 9854052347, Name = "Farol", Take = {
		{ Kind = "Lantern", Match = { "lantern", "toro" }, Whole = true },
	} },
	-- Perro-león de piedra: los guardianes del rincón japonés (en lugar del Moai)
	{ Id = 4698399766, Name = "Guardian", Take = {
		{ Kind = "Guardian", Match = { "lion", "dog", "statue", "komainu" }, Whole = true },
	} },
	-- Forest Pack (Roblox): secuoyas para el monte, rocas grandes y piedras
	{ Id = 6432306802, Name = "Bosque", Take = {
		{ Kind = "Conifer", Match = { "redwood" }, MaxUses = 200 },
		{ Kind = "Boulder", Match = { "boulder" } },
		{ Kind = "Pebble", Match = { "smallrock", "small rock", "pebble" } },
	} },
	-- Realistic Pack (xXCHARLIE_BOlXx): solo los tiburones (las personas, el perro y el conejo no)
	{ Id = 8649374407, Name = "Tiburones", Take = {
		{ Kind = "Shark", Match = { "shark", "mako", "thresher", "hammerhead", "white tip" } },
	} },
	-- Realistic Fish PACK: solo los peces sueltos (sin kraken, cocodrilo, NPC, Sketchfab ni mosasaurio)
	{ Id = 130843005739076, Name = "Peces", Take = {
		{ Kind = "Fish", Match = { "^cod$", "^grouper$", "^barramundi$", "^amberjack$", "^cobia$", "^barracuda$", "^blue fish$", "^tiger muskellunge$", "^blenny$" } },
	} },
} :: { Pack }

-- Nunca se cargan: mallas sacadas de otro juego (docs/assets-usuario-5.md)
NatureAssets.Blocked = {
	[11330013072] = "Moai: malla sacada de Splatoon 3",
	-- Puerta trasera (docs/assets-usuario-4.md): Sebastián prefiere los recambios limpios
	[114397068371248] = "Foliage Pack: puerta trasera (familia 1)",
	[72475149726020] = "Palmeras tropicales: puerta trasera (familia 1)",
	[109211499509239] = "Cerezo: puerta trasera (familia 1)",
	[126164979250031] = "Haya: puerta trasera (familia 1)",
	[116641210728889] = "Hoguera: puerta trasera (familia 5)",
	[78188971759943] = "Farol japonés: puerta trasera (familias 3 y 5)",
}

-- Nombres (en español) y topes por tipo
NatureAssets.Kinds = {
	Park = { Name = "ArbolParque", MaxParts = 30, Tree = true },
	Conifer = { Name = "Abeto", MaxParts = 30, Tree = true },
	Palm = { Name = "Palmera", MaxParts = 12, Tree = true },
	Bush = { Name = "Arbusto", MaxParts = 4 },
	Boulder = { Name = "Roca", MaxParts = 3, MaxSize = 80 },
	Pebble = { Name = "Piedrecita", MaxParts = 1, MaxSize = 6 },
	Shark = { Name = "Tiburon", MaxParts = 4, MaxSize = 30 },
	Fish = { Name = "Pez", MaxParts = 4, MaxSize = 26 },
	Sakura = { Name = "Cerezo", MaxParts = 10, Tree = true },
	Lantern = { Name = "FarolPiedra", MaxParts = 4, MaxSize = 20 },
	Campfire = { Name = "Hoguera", MaxParts = 50, MaxSize = 15 },
	Guardian = { Name = "Guardian", MaxParts = 10, MaxSize = 40 },
}
NatureAssets.JapaneseCorners = 4 -- parques con rincón japonés
NatureAssets.Campfires = 8
NatureAssets.PerKind = 6 -- plantillas como mucho de un tipo en un mismo pack
NatureAssets.MaxBoulders = 90
NatureAssets.MaxPebbles = 360
NatureAssets.Sharks = 4

export type Template = MeshLibrary.Template
export type Library = { [string]: { Template } }

---------------------------------------------------------------------
-- Carga y limpieza
---------------------------------------------------------------------

local function isCode(d: Instance): boolean
	local ok, yes = pcall(function()
		return d:IsA("LuaSourceContainer")
	end)
	if ok then
		return yes
	end
	return d.ClassName == "Script" or d.ClassName == "LocalScript" or d.ClassName == "ModuleScript"
end

-- Borra todos los scripts de lo cargado (antes de nada). Devuelve cuántos.
function NatureAssets.stripScripts(root: Instance): number
	return MeshLibrary.stripScripts(root)
end

local function bounds(list: { BasePart }): (Vector3, Vector3)
	return MeshLibrary.bounds(list)
end

local function meshesOf(node: Instance): { BasePart }
	local list = {}
	if node:IsA("MeshPart") then
		table.insert(list, node)
	end
	for _, d in node:GetDescendants() do
		if d:IsA("MeshPart") then
			table.insert(list, d)
		end
	end
	return list
end

local CROWN = { "leaf", "leaves", "foliage", "frond", "needle", "crown", "branch", "flower", "blossom", "hoja", "palm_l" }
local TRUNK = { "trunk", "bark", "stem", "tronco", "log" }
local function has(name: string, words: { string }): boolean
	local lower = string.lower(name)
	for _, w in words do
		if string.find(lower, w, 1, true) then
			return true
		end
	end
	return false
end

-- Copia limpia de una MeshPart: solo con su SurfaceAppearance (o sus Texture de corteza y hojas, si
-- se pide); sin atributos ni etiquetas, y sin nada colgando de esos hijos
local function cleanCopy(m: BasePart, keepTextures: boolean?): BasePart
	local clone = m:Clone()
	for _, child in clone:GetChildren() do
		if child:IsA("SurfaceAppearance") or (keepTextures and child.ClassName == "Texture") then
			for _, sub in child:GetChildren() do
				sub:Destroy()
			end
			pcall(function()
				for key in child:GetAttributes() do
					child:SetAttribute(key, nil)
				end
			end)
		else
			child:Destroy()
		end
	end
	pcall(function()
		for key in clone:GetAttributes() do
			clone:SetAttribute(key, nil)
		end
		for _, tag in clone:GetTags() do
			clone:RemoveTag(tag)
		end
	end)
	clone.Anchored = true
	return clone
end

-- Plantilla de un objeto del pack (Model o MeshPart). nil si no vale (sin mallas, demasiadas, enorme)
function NatureAssets.template(source: Instance, kind: string, index: number, maxUses: number?, keepTextures: boolean?): Template?
	local spec = NatureAssets.Kinds[kind]
	local meshes = meshesOf(source)
	if not spec or #meshes == 0 or #meshes > spec.MaxParts then
		return nil
	end
	local lo, hi = bounds(meshes)
	local size = hi - lo
	if spec.MaxSize and math.max(size.X, size.Y, size.Z) > spec.MaxSize then
		return nil
	end
	if size.Y <= 0.05 then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = spec.Name .. "_" .. index
	local copies = {}
	for _, m in meshes do
		local c = cleanCopy(m, keepTextures)
		c.Parent = model
		table.insert(copies, c)
	end
	-- Árboles: copa "Leaves" y tronco "Trunk" (MeshLibrary.role). Lo que no se sabe por el nombre: la
	-- pieza que llega más abajo es el tronco y el resto, copa.
	local trunks = {}
	if spec.Tree then
		local roles = {}
		for i, c in copies do
			roles[i] = if has(meshes[i].Name, CROWN) then "Leaves" elseif has(meshes[i].Name, TRUNK) then "Trunk" else nil
		end
		local anyTrunk = false
		for i in copies do
			anyTrunk = anyTrunk or roles[i] == "Trunk"
		end
		if not anyTrunk and #copies > 1 then
			local lowest, lowY = nil, math.huge
			for i, c in copies do
				if roles[i] == nil then
					local b = bounds({ c })
					if b.Y < lowY then
						lowest, lowY = i, b.Y
					end
				end
			end
			if lowest then
				roles[lowest] = "Trunk"
			end
		end
		for i, c in copies do
			c.Name = roles[i] or "Leaves"
			if c.Name == "Trunk" then
				table.insert(trunks, c)
			end
		end
	else
		for _, c in copies do
			c.Name = spec.Name
		end
	end
	local foot = Vector3.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	if #trunks > 0 then
		local tlo, thi = bounds(trunks)
		foot = Vector3.new((tlo.X + thi.X) / 2, lo.Y, (tlo.Z + thi.Z) / 2)
	end
	model:SetAttribute("Height", size.Y)
	return {
		Name = model.Name,
		Model = model,
		Foot = foot,
		Height = size.Y,
		Width = math.max(size.X, size.Z),
		MaxUses = maxUses,
		Uses = 0,
	}
end

-- Objetos de un pack que casan con la lista (sin bajar dentro de uno que ya casa)
local function matches(root: Instance, patterns: { string }): { Instance }
	local found = {}
	local function walk(node: Instance)
		for _, child in node:GetChildren() do
			local name = string.lower(child.Name)
			local hit = false
			if child:IsA("Model") or child:IsA("MeshPart") then
				for _, p in patterns do
					if string.find(name, p) then
						hit = true
						break
					end
				end
			end
			if hit then
				table.insert(found, child)
			else
				walk(child)
			end
		end
	end
	walk(root)
	return found
end

-- De los packs cargados ({ [id] = raíz }) saca las plantillas por tipo. Borra los scripts de todo.
function NatureAssets.prepare(loaded: { [number]: Instance }): Library
	local library: Library = {}
	for kind in NatureAssets.Kinds do
		library[kind] = {}
	end
	for _, pack in NatureAssets.Packs do
		local root = loaded[pack.Id]
		if root and not NatureAssets.Blocked[pack.Id] then
			NatureAssets.stripScripts(root)
			for _, take in pack.Take do
				local n = 0
				local sources = matches(root, take.Match)
				if #sources == 0 and take.Whole then
					sources = { root } -- (nombre desconocido: el pack entero es el objeto)
				end
				for _, source in sources do
					if n >= NatureAssets.PerKind then
						break
					end
					local t = NatureAssets.template(source, take.Kind, #library[take.Kind] + 1, take.MaxUses, take.KeepTextures)
					if t then
						table.insert(library[take.Kind], t)
						n += 1
					end
				end
			end
		end
	end
	return library
end

local function download(id: number): Instance?
	local ok, result = pcall(function()
		return (game:GetService("AssetService") :: any):LoadAssetAsync(id)
	end)
	if ok and result then
		return result
	end
	local err = result
	ok, result = pcall(function()
		return game:GetService("InsertService"):LoadAsset(id)
	end)
	if ok and result then
		return result
	end
	warn(("[NatureAssets] no carga %d: %s / %s"):format(id, tostring(err), tostring(result)))
	return nil
end

-- Registro de la limpieza (para las pruebas): { Id, Stripped (scripts borrados), Unparented }
NatureAssets.Log = {} :: { { Id: number, Stripped: number, Unparented: boolean } }

local cached: Library? = nil
local loading = false

-- Carga los packs una vez (los demás que lo pidan esperan). "fetch" se puede cambiar (pruebas).
function NatureAssets.load(fetch: ((number) -> Instance?)?): Library
	if cached then
		return cached
	end
	if loading then
		while loading do
			task.wait(0.5)
		end
		return cached or {}
	end
	loading = true
	local get = fetch or download
	local loaded: { [number]: Instance } = {}
	for _, pack in NatureAssets.Packs do
		if not NatureAssets.Blocked[pack.Id] then
			local ok, asset = pcall(get, pack.Id)
			if ok and asset then
				-- LO PRIMERO: fuera todos los scripts, con lo cargado aún sin padre (así no pueden
				-- correr). Nada de este pack se mete en ningún sitio antes de esto.
				local stripped = NatureAssets.stripScripts(asset)
				table.insert(NatureAssets.Log, { Id = pack.Id, Stripped = stripped, Unparented = asset.Parent == nil })
				if asset.Parent == nil then
					loaded[pack.Id] = asset
				else
					warn(("[NatureAssets] %d llegó con padre: no se usa"):format(pack.Id))
					pcall(function()
						asset:Destroy()
					end)
				end
			end
		end
	end
	local ok, result = pcall(NatureAssets.prepare, loaded)
	for _, root in loaded do
		pcall(function()
			NatureAssets.stripScripts(root)
			root:Destroy()
		end)
	end
	if not ok then
		warn("[NatureAssets] " .. tostring(result))
		result = {}
	end
	cached = result
	loading = false
	return result
end

function NatureAssets.reset()
	cached, loading = nil, false
	NatureAssets.Log = {}
end

-- MeshLibrary: añade a su biblioteca los árboles de parque (Tree), los abetos (Conifer), las palmeras
-- (Palm) y los arbustos (Bush)
function NatureAssets.extend(library: { [string]: { Template } }, fetch: ((number) -> Instance?)?): number
	local mine = NatureAssets.load(fetch)
	local added = 0
	for from, to in { Park = "Tree", Conifer = "Conifer", Palm = "Palm", Bush = "Bush" } do
		for _, t in mine[from] or {} do
			library[to] = library[to] or {}
			table.insert(library[to], t)
			added += 1
		end
	end
	return added
end

---------------------------------------------------------------------
-- Colocar
---------------------------------------------------------------------

local function setFlags(p: BasePart, collide: boolean)
	p.Anchored = true
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.CastShadow = collide
	pcall(function()
		(p :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
end

-- Copia de una plantilla con el pie en "foot", de tamaño "size" (su lado mayor), girada "yaw"
function NatureAssets.place(t: Template, parent: Instance, foot: Vector3, size: number, yaw: number, opts: { Collide: boolean?, Detail: boolean?, Name: string? }?): Model
	local o = opts or {}
	local lo, hi = bounds(meshesOf(t.Model))
	local big = math.max(hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z)
	local copy = MeshLibrary.placeCopy(t, foot, yaw, size / big) :: Model
	copy.Name = o.Name or t.Name
	copy:SetAttribute("MeshVariant", t.Name)
	for _, p in meshesOf(copy) do
		setFlags(p, o.Collide == true)
		if o.Detail then
			p:AddTag("LeafDetail") -- el nivel gráfico Bajo lo esconde
		end
	end
	copy.Parent = parent
	return copy
end

-- Sitio libre para una roca: devuelve la altura del suelo o nil. En Roblox: rayo desde arriba que
-- tiene que dar en el terreno (no agua, no una pieza) y caja sin piezas encima.
export type Probe = (x: number, z: number, radius: number) -> number?

-- Sitios para rocas (siempre los mismos): laderas de las montañas, orillas del río y de los lagos
function NatureAssets.boulderSpots(CityPlan: any): { Vector3 }
	local spots = {}
	for i, m in CityPlan.Mountains do
		local ground = math.sqrt(math.max(0, m.R * m.R - (m.R - m.H) ^ 2))
		for k = 1, 7 do
			local seed = Vector3.new(m.X + i * 13, 0, m.Z + k * 29)
			local a = MeshLibrary.hash(seed, 11) * math.pi * 2
			local r = ground * (0.75 + MeshLibrary.hash(seed, 12) * 0.35)
			table.insert(spots, Vector3.new(m.X + math.cos(a) * r, 0, m.Z + math.sin(a) * r))
		end
	end
	local pts = CityPlan.River.Points
	local W = CityPlan.River.Width
	for i = 1, #pts - 1 do
		local a, b = Vector3.new(pts[i][1], 0, pts[i][2]), Vector3.new(pts[i + 1][1], 0, pts[i + 1][2])
		local dir = (b - a).Unit
		local perp = Vector3.new(-dir.Z, 0, dir.X)
		for d = 120, (b - a).Magnitude - 60, 260 do
			local side = if (i + math.floor(d / 260)) % 2 == 0 then 1 else -1
			table.insert(spots, a + dir * d + perp * side * (W / 2 + 14))
		end
	end
	for _, lake in CityPlan.Lakes do
		for k = 0, 8 do
			local a = k / 9 * math.pi * 2 + 0.3
			local r = lake.R + 14 + (k % 3) * 6
			table.insert(spots, Vector3.new(lake.X + math.cos(a) * r, 0, lake.Z + math.sin(a) * r))
		end
	end
	return spots
end

function NatureAssets.placeBoulders(parent: Instance, library: Library, spots: { Vector3 }, probe: Probe): number
	local list = library.Boulder
	if not list or #list == 0 then
		return 0
	end
	local n = 0
	for _, spot in spots do
		if n >= NatureAssets.MaxBoulders then
			break
		end
		local size = 9 + MeshLibrary.hash(spot, 21) * 14
		local y = probe(spot.X, spot.Z, size / 2)
		if y then
			local t = list[math.floor(MeshLibrary.hash(spot, 22) * #list) + 1]
			local lo, hi = bounds(meshesOf(t.Model))
			local scale = size / math.max(hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z)
			local sink = (hi.Y - lo.Y) * scale * 0.2 -- un poco enterrada: no flota en las cuestas
			NatureAssets.place(t, parent, Vector3.new(spot.X, y - sink, spot.Z), size, MeshLibrary.hash(spot, 23) * math.pi * 2, { Collide = true, Name = "Roca" })
			n += 1
		end
	end
	return n
end

-- Piedrecitas en el césped de un parque (pieza "Lawn"): grupos de 3 en sitios fijos del borde
function NatureAssets.placePebbles(parent: Instance, library: Library, lawn: BasePart, probe: Probe?, budget: number): number
	local list = library.Pebble
	if not list or #list == 0 or budget <= 0 then
		return 0
	end
	local cf, size = lawn.CFrame, lawn.Size
	local n = 0
	for g = 0, 5 do
		local seed = cf.Position + Vector3.new(g * 7, 0, g * 3)
		local u = (MeshLibrary.hash(seed, 31) - 0.5) * (size.X - 8)
		local v = (if g % 2 == 0 then 0.5 else -0.5) * (size.Z - 6) * (0.6 + MeshLibrary.hash(seed, 32) * 0.3)
		local center = (cf * CFrame.new(u, size.Y / 2, v)).Position
		for k = 1, 3 do
			if n >= budget then
				return n
			end
			local p = center + Vector3.new(math.cos(k * 2.1) * 1.6, 0, math.sin(k * 2.1) * 1.6)
			local y = if probe then probe(p.X, p.Z, 1) else center.Y
			if y then
				local t = list[math.floor(MeshLibrary.hash(p, 33) * #list) + 1]
				NatureAssets.place(t, parent, Vector3.new(p.X, y - 0.1, p.Z), 1.2 + MeshLibrary.hash(p, 34) * 1.6, MeshLibrary.hash(p, 35) * math.pi * 2, { Detail = true, Name = "Piedrecita" })
				n += 1
			end
		end
	end
	return n
end

-- Giro para que el largo de la plantilla (peces, tiburones) quede en el eje Z, como las piezas SwimFish
-- Rincón japonés en una esquina libre del césped de un parque: cerezo en flor, dos faroles de piedra
-- delante y dos guardianes de piedra a los lados, mirando al centro del parque. Prueba las cuatro
-- esquinas y se queda con la primera donde todo cae en el césped. Devuelve si lo ha puesto.
function NatureAssets.placeJapaneseCorner(parent: Instance, library: Library, lawn: BasePart, probe: Probe): boolean
	local sakura, lanterns, guardians = library.Sakura, library.Lantern, library.Guardian
	if not sakura or #sakura == 0 then
		return false
	end
	local cf, size = lawn.CFrame, lawn.Size
	if size.X < 40 or size.Z < 40 then
		return false
	end
	local center = cf.Position
	for k = 0, 3 do
		local sx = if k % 2 == 0 then 1 else -1
		local sz = if k < 2 then 1 else -1
		local at = (cf * CFrame.new(sx * (size.X / 2 - 14), size.Y / 2, sz * (size.Z / 2 - 14))).Position
		local inward = Vector3.new(center.X - at.X, 0, center.Z - at.Z)
		if inward.Magnitude < 1 then
			continue
		end
		inward = inward.Unit
		local side = Vector3.new(-inward.Z, 0, inward.X)
		local spots = {
			{ Kind = "Sakura", Pos = at, Size = 18, Radius = 6 },
			{ Kind = "Lantern", Pos = at + inward * 9 + side * 4, Size = 4.5, Radius = 1.5 },
			{ Kind = "Lantern", Pos = at + inward * 9 - side * 4, Size = 4.5, Radius = 1.5 },
			{ Kind = "Guardian", Pos = at + inward * 13 + side * 7, Size = 4, Radius = 1.5 },
			{ Kind = "Guardian", Pos = at + inward * 13 - side * 7, Size = 4, Radius = 1.5 },
		}
		local ys = {}
		local ok = true
		for i, spot in spots do
			ys[i] = probe(spot.Pos.X, spot.Pos.Z, spot.Radius)
			if ys[i] == nil and spot.Kind == "Sakura" then
				ok = false
				break
			end
		end
		if ok then
			local face = math.atan2(-inward.X, -inward.Z)
			for i, spot in spots do
				local list = library[spot.Kind]
				local y = ys[i]
				if y and list and #list > 0 then
					local t = list[(i - 1) % #list + 1]
					NatureAssets.place(t, parent, Vector3.new(spot.Pos.X, y, spot.Pos.Z), spot.Size, face, {
						Collide = spot.Kind ~= "Sakura",
						Detail = spot.Kind ~= "Sakura",
						Name = NatureAssets.Kinds[spot.Kind].Name,
					})
				end
			end
			return true
		end
	end
	return false
end

-- Hogueras junto a las mesas de pícnic (una sí y otra no), con fuego y luz nuestros
function NatureAssets.placeCampfires(parent: Instance, library: Library, tables: { BasePart }, probe: Probe): number
	local list = library.Campfire
	if not list or #list == 0 then
		return 0
	end
	local n = 0
	for i, t in tables do
		if n >= NatureAssets.Campfires then
			break
		end
		if i % 2 == 1 then
			local p = (t.CFrame * CFrame.new(0, 0, -9)).Position
			local y = probe(p.X, p.Z, 3)
			if y then
				local m = NatureAssets.place(list[(n % #list) + 1], parent, Vector3.new(p.X, y, p.Z), 4.5, i * 0.7, { Collide = true, Name = "Hoguera" })
				local flame = Instance.new("Part")
				flame.Name = "Llama"
				flame.Anchored = true
				flame.CanCollide = false
				flame.CanQuery = false
				flame.CanTouch = false
				flame.Transparency = 1
				flame.Size = Vector3.new(1, 1, 1)
				flame.CFrame = CFrame.new(p.X, y + 1, p.Z)
				local fire = Instance.new("Fire")
				fire.Size = 4
				fire.Heat = 6
				fire.Parent = flame
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 150, 60)
				light.Range = 18
				light.Brightness = 1.8
				light.Parent = flame
				flame.Parent = m
				n += 1
			end
		end
	end
	return n
end

function NatureAssets.lengthYaw(t: Template): number
	local lo, hi = bounds(meshesOf(t.Model))
	return if hi.X - lo.X > hi.Z - lo.Z then math.pi / 2 else 0
end

-- Pescadería: 3 peces tumbados sobre el mostrador (pieza con la etiqueta SuperFish)
function NatureAssets.dressCounter(counter: BasePart, library: Library): number
	local list = library.Fish
	if not list or #list == 0 or counter:FindFirstChild("PecesMostrador") then
		return 0
	end
	local folder = Instance.new("Model")
	folder.Name = "PecesMostrador"
	local cf, size = counter.CFrame, counter.Size
	local n = 0
	for k = -1, 1 do
		local spot = cf * CFrame.new(k * size.X / 3.2, size.Y / 2, 0)
		local t = list[((n + math.floor(MeshLibrary.hash(cf.Position, 41) * #list)) % #list) + 1]
		local length = math.min(2.2, size.X / 4)
		-- (la plantilla tiene el largo en X o Z: se gira para que quede a lo largo del mostrador)
		local copy = NatureAssets.place(t, folder, spot.Position + Vector3.new(0, 0.05, 0), length, 0, { Detail = true, Name = "Pez" })
		pcall(function()
			copy:PivotTo(spot * CFrame.Angles(0, math.rad(k * 12), 0))
		end)
		n += 1
	end
	folder.Parent = counter
	return n
end

-- Pez que nada (pieza SwimFish de DivingService): su malla soldada encima; la caja se hace invisible
function NatureAssets.dressSwimFish(part: BasePart, library: Library): boolean
	local species = tostring(part:GetAttribute("Species") or "")
	local shark = string.find(string.lower(species), "tiburon", 1, true) ~= nil
	local list = if shark and library.Shark and #library.Shark > 0 then library.Shark else library.Fish
	if not list or #list == 0 or part:FindFirstChild("Malla") then
		return false
	end
	local t = list[(#species % #list) + 1]
	local length = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	local copy = NatureAssets.place(t, part, part.CFrame.Position, length, 0, { Name = "Malla" })
	pcall(function()
		copy.WorldPivot = CFrame.new((copy:GetBoundingBox()).Position) -- (el centro del pez, no su base)
		copy:PivotTo(part.CFrame * CFrame.Angles(0, NatureAssets.lengthYaw(t), 0))
	end)
	for _, p in meshesOf(copy) do
		p.Anchored = false
		p.Massless = true
		p.CanCollide = false
		p.CanQuery = false
		pcall(function()
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = part
			weld.Part1 = p
			weld.Parent = p
		end)
	end
	part.Transparency = 1
	return true
end

-- Tiburones mar adentro (frente a las playas del este): sitios fijos en el agua
function NatureAssets.sharkSpots(CityPlan: any): { Vector3 }
	local spots = {}
	for _, z in { -300, 500, 1300, 2100 } do
		local spans = CityPlan.spans(CityPlan.Coast, z)
		local last = spans[#spans]
		if last then
			table.insert(spots, Vector3.new(last[2] + 240, -9, z))
		end
	end
	return spots
end

---------------------------------------------------------------------
-- Arranque en el servidor
---------------------------------------------------------------------

local function ground(folder: Instance): Probe
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { folder }
	return function(x: number, z: number, radius: number): number?
		local hit = workspace:Raycast(Vector3.new(x, 700, z), Vector3.new(0, -1400, 0), params)
		if not hit or hit.Instance ~= workspace.Terrain or hit.Material == Enum.Material.Water then
			return nil
		end
		local y = hit.Position.Y
		local near = workspace:GetPartBoundsInBox(CFrame.new(x, y + 6, z), Vector3.new(radius * 2 + 4, 10, radius * 2 + 4), overlap)
		if #near > 0 then
			return nil
		end
		return y
	end
end

-- Pieza de césped de un parque: rayo que tiene que dar en ella
local function onLawn(lawn: BasePart, folder: Instance): Probe
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	return function(x: number, z: number): number?
		local hit = workspace:Raycast(Vector3.new(x, lawn.Position.Y + 40, z), Vector3.new(0, -60, 0), params)
		if hit and hit.Instance == lawn then
			return hit.Position.Y
		end
		return nil
	end
end

local function swimSharks(models: { Model })
	if #models == 0 then
		return
	end
	local Players = game:GetService("Players")
	local centers = {}
	for i, m in models do
		centers[i] = m:GetPivot()
	end
	local t = 0
	while true do
		task.wait(0.2)
		t += 0.2
		for i, m in models do
			if not m.Parent then
				continue
			end
			local c = centers[i].Position
			local near = false
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (root.Position - c).Magnitude < 600 then
					near = true
					break
				end
			end
			if near then
				-- vuelta lenta de 45 studs de radio (~4 studs/s), cada uno a su ritmo
				local a = t * 0.09 + i * 1.7
				local pos = c + Vector3.new(math.cos(a) * 45, math.sin(t * 0.3 + i) * 1.5, math.sin(a) * 45)
				local ahead = c + Vector3.new(math.cos(a + 0.1) * 45, 0, math.sin(a + 0.1) * 45)
				pcall(function()
					m:PivotTo(CFrame.lookAt(pos, Vector3.new(ahead.X, pos.Y, ahead.Z)) * CFrame.Angles(0, m:GetAttribute("LengthYaw") or 0, 0))
				end)
			end
		end
	end
end

function NatureAssets.start()
	local library = NatureAssets.load()
	local summary = {}
	for kind, list in library do
		table.insert(summary, ("%s=%d"):format(kind, #list))
	end
	table.sort(summary)
	print("[NatureAssets] Plantillas: " .. table.concat(summary, " "))

	local CityPlan = require(game:GetService("ReplicatedStorage").Shared.CityPlan)
	local folder = Instance.new("Folder")
	folder.Name = "NaturalezaReal"
	folder.Parent = workspace

	-- Rocas grandes (laderas, río, lagos)
	local rocks = 0
	local ok, err = pcall(function()
		rocks = NatureAssets.placeBoulders(folder, library, NatureAssets.boulderSpots(CityPlan), ground(folder))
	end)
	if not ok then
		warn("[NatureAssets] rocas: " .. tostring(err))
	end

	-- Piedrecitas en el césped de los parques
	local pebbles = 0
	ok, err = pcall(function()
		local town = workspace:FindFirstChild("Town") or workspace
		for _, d in town:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Lawn" and d.Parent and d.Parent.Name == "Parque" then
				pebbles += NatureAssets.placePebbles(folder, library, d, onLawn(d, folder), NatureAssets.MaxPebbles - pebbles)
				if pebbles >= NatureAssets.MaxPebbles then
					break
				end
			end
		end
	end)
	if not ok then
		warn("[NatureAssets] piedras: " .. tostring(err))
	end

	-- Rincón japonés en los parques más grandes
	local corners = 0
	ok, err = pcall(function()
		local town = workspace:FindFirstChild("Town") or workspace
		local lawns = {}
		for _, d in town:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Lawn" and d.Parent and d.Parent.Name == "Parque" then
				table.insert(lawns, d)
			end
		end
		table.sort(lawns, function(a, b)
			return a.Size.X * a.Size.Z > b.Size.X * b.Size.Z
		end)
		for _, lawn in lawns do
			if corners >= NatureAssets.JapaneseCorners then
				break
			end
			if NatureAssets.placeJapaneseCorner(folder, library, lawn, onLawn(lawn, folder)) then
				corners += 1
			end
		end
	end)
	if not ok then
		warn("[NatureAssets] rincón japonés: " .. tostring(err))
	end

	-- Hogueras junto a las mesas de pícnic del parque natural
	local fires = 0
	ok, err = pcall(function()
		local tables = {}
		for _, d in workspace:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "PicnicTable" then
				table.insert(tables, d)
			end
		end
		fires = NatureAssets.placeCampfires(folder, library, tables, ground(folder))
	end)
	if not ok then
		warn("[NatureAssets] hogueras: " .. tostring(err))
	end

	-- Peces en las pescaderías (también las que se monten después)
	local CollectionService = game:GetService("CollectionService")
	local function counter(c: Instance)
		if c:IsA("BasePart") then
			pcall(NatureAssets.dressCounter, c, library)
		end
	end
	for _, c in CollectionService:GetTagged("SuperFish") do
		counter(c)
	end
	CollectionService:GetInstanceAddedSignal("SuperFish"):Connect(counter)

	-- Peces que nadan al bucear (DivingService los crea en workspace.SwimFish)
	local function fish(part: Instance)
		if part:IsA("BasePart") then
			task.defer(function()
				pcall(NatureAssets.dressSwimFish, part :: BasePart, library)
			end)
		end
	end
	local function watch(f: Instance)
		if f.Name == "SwimFish" and f:IsA("Folder") then
			for _, p in f:GetChildren() do
				fish(p)
			end
			f.ChildAdded:Connect(fish)
		end
	end
	for _, f in workspace:GetChildren() do
		watch(f)
	end
	workspace.ChildAdded:Connect(watch)

	-- Tiburones mar adentro
	local sharks = {}
	ok, err = pcall(function()
		local list = library.Shark
		if list and #list > 0 then
			for i, spot in NatureAssets.sharkSpots(CityPlan) do
				if i > NatureAssets.Sharks then
					break
				end
				local t = list[(i - 1) % #list + 1]
				local m = NatureAssets.place(t, folder, spot, 11 + (i % 3) * 2, i * 1.3, { Detail = true, Name = "Tiburon" })
				m:SetAttribute("LengthYaw", NatureAssets.lengthYaw(t))
				table.insert(sharks, m)
			end
		end
	end)
	if not ok then
		warn("[NatureAssets] tiburones: " .. tostring(err))
	end
	task.spawn(swimSharks, sharks)

	print(("[NatureAssets] %d rocas, %d piedrecitas, %d rincones japoneses, %d hogueras, %d tiburones"):format(rocks, pebbles, corners, fires, #sharks))
end

return NatureAssets
