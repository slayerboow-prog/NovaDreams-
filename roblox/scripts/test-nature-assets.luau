-- Prueba de la naturaleza de los packs de Sebastián (World/NatureAssets) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-nature-assets.luau
--
-- No hay AssetService: un cargador falso devuelve packs con los mismos nombres que los de verdad,
-- con scripts, carteles (Decal, SurfaceGui), NumberPose y mallas que no se deben usar. Comprueba que:
--   * nunca se piden los ids con puerta trasera ni la malla de otro juego
--   * en las plantillas solo quedan MeshPart y SurfaceAppearance (sin scripts, marcas ni atributos)
--   * solo entran los objetos de la lista (sin las mallas de Half-Life 2, el kraken ni las personas)
--   * las palmeras de malla cambian las procedurales (más altas, en el suelo, choque invisible), sin
--     plantillas Palm se quedan procedurales; los topes MaxUses se respetan
--   * rocas, piedrecitas, peces del mostrador y peces que nadan quedan en su sitio
--   * si la carga falla, no se rompe nada

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Vector3, Color3, CFrame, Instance = roblox.Enum, roblox.Vector3, roblox.Color3, roblox.CFrame, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function load(path: string, env: { [string]: any }): any
	local full = setmetatable(env, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = full })()
end

local base = {
	Enum = Enum, Vector3 = Vector3, Color3 = Color3, CFrame = CFrame, Instance = Instance,
	task = { wait = function() end },
	warn = function() end,
}
local function env(extra: { [string]: any }): { [string]: any }
	local out = table.clone(base)
	for k, v in extra do
		out[k] = v
	end
	return out
end

local MeshLibrary = load("src/server/World/MeshLibrary.luau", env({}))
local MESH = {}
local NatureAssets = load("src/server/World/NatureAssets.luau", env({
	script = { Parent = { MeshLibrary = MESH } },
	require = function(m)
		if m == MESH then
			return MeshLibrary
		end
		error("require inesperado")
	end,
}))
local CityPlan = load("src/shared/CityPlan.luau", env({}))

local BUILDER, PALETTE, ASSETS = {}, {}, {}
local Builder = load("src/server/World/Builder.luau", env({}))
local Palette = load("src/server/World/Kit/Palette.luau", env({}))
local Nature = load("src/server/World/Kit/Nature.luau", env({
	script = { Parent = { Parent = { Builder = BUILDER }, Palette = PALETTE, AssetLibrary = ASSETS } },
	require = function(m)
		if m == BUILDER then
			return Builder
		elseif m == PALETTE then
			return Palette
		elseif m == ASSETS then
			return { spawn = function() return nil end }
		end
		error("require inesperado")
	end,
}))

---------------------------------------------------------------------
-- Packs falsos
---------------------------------------------------------------------
local function mesh(parent: any, name: string, size: any, center: any)
	local p = Instance.new("MeshPart")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(center)
	Instance.new("SurfaceAppearance").Parent = p
	p.Parent = parent
	return p
end
-- Objeto con copa y tronco, y basura colgando (script, cartel con marca, sonido, NumberPose)
local function treeModel(parent: any, name: string, w: number, h: number, leafName: string, trunkName: string)
	local m = Instance.new("Model")
	m.Name = name
	local at = Vector3.new(40, 3, -20)
	mesh(m, trunkName, Vector3.new(w * 0.3, h * 0.7, w * 0.3), at + Vector3.new(0, h * 0.35, 0))
	local leaves = mesh(m, leafName, Vector3.new(w, h * 0.6, w), at + Vector3.new(0, h * 0.7, 0))
	local decal = Instance.new("Decal")
	decal.Name = "Logo"
	decal.Parent = leaves
	local gui = Instance.new("SurfaceGui")
	local label = Instance.new("TextLabel")
	label.Text = "Marca Real"
	label.Parent = gui
	gui.Parent = leaves
	leaves:SetAttribute("a", "eurt=delbanEptth")
	local s = Instance.new("Script")
	s.Parent = m
	Instance.new("NumberPose").Parent = m
	Instance.new("Sound").Parent = m
	m.Parent = parent
	return m
end
local function single(parent: any, name: string, size: any)
	local m = Instance.new("Model")
	m.Name = name
	mesh(m, "Mesh", size, Vector3.new(0, size.Y / 2, 0))
	m.Parent = parent
	return m
end

local requested: { number } = {}
local function fakePack(id: number): any
	table.insert(requested, id)
	local root = Instance.new("Model")
	local folder = Instance.new("Folder")
	folder.Name = "Pack"
	folder.Parent = root
	local ls = Instance.new("LocalScript")
	ls.Parent = folder
	if id == 96924659951632 then
		local trees = Instance.new("Folder")
		trees.Name = "Trees"
		trees.Parent = folder
		treeModel(trees, "OakTree", 23.9, 33.5, "leaves", "tree")
		treeModel(trees, "CherryTree", 17.5, 20.6, "leaves", "tree")
		treeModel(trees, "PineTree", 13.3, 27.7, "leaves", "tree")
		local delete = Instance.new("Part")
		delete.Name = "DELETE ME"
		Instance.new("Decal").Parent = delete
		delete.Parent = folder
	elseif id == 8553512581 then
		treeModel(folder, "PalmtreeVar0", 24.2, 36.9, "Leaves", "Trunk")
		treeModel(folder, "PalmtreeVar1", 24.2, 36.9, "Fronds", "Bark")
		local r = mesh(folder, "LargeMossBoulder", Vector3.new(65, 52.1, 62.7), Vector3.new(0, 26, 0))
		r.Parent = folder
		single(folder, "Bush", Vector3.new(6, 4, 6))
		single(folder, "Fish_Swim", Vector3.new(1, 0.5, 2)) -- (animal con script: no está en la lista)
	elseif id == 16879341926 then
		for i = 1, 3 do
			mesh(folder, "Boulder", Vector3.new(25 + i, 20, 24), Vector3.new(i * 50, 10, 0))
		end
		mesh(folder, "Pebble", Vector3.new(1.3, 0.7, 1.1), Vector3.new(0, 0, 0))
	elseif id == 13388285234 then
		treeModel(folder, "Palm Tree", 18.7, 27.2, "Leaves", "Trunk")
		treeModel(folder, "tree_deciduous_01a", 20, 30, "Leaves", "Trunk") -- (Half-Life 2: no)
	elseif id == 9262569938 then
		for i = 1, 5 do
			mesh(folder, "Meshes/Type" .. i, Vector3.new(2, 1.5, 2.4), Vector3.new(i * 5, 0.75, 0))
		end
	elseif id == 8649374407 then
		single(folder, "Shortfin Mako Shark", Vector3.new(8.7, 6, 21.7))
		single(folder, "Young Japanese Woman", Vector3.new(2.4, 7.6, 1))
	elseif id == 130843005739076 then
		single(folder, "Cod", Vector3.new(5.2, 0.8, 1.9))
		single(folder, "Grouper", Vector3.new(9.4, 2.9, 1.9))
		single(folder, "kraken", Vector3.new(400, 139, 500))
	else
		return nil -- (los demás no cargan: el juego sigue)
	end
	return root
end

local function onlyMeshes(model: any): boolean
	for _, d in model:GetDescendants() do
		if not (d:IsA("MeshPart") or d:IsA("SurfaceAppearance")) then
			return false
		end
		if next(d:GetAttributes()) ~= nil then
			return false
		end
	end
	return true
end

---------------------------------------------------------------------
print("Carga")
local library = NatureAssets.load(fakePack)
local blockedAsked = false
for _, id in requested do
	if NatureAssets.Blocked[id] then
		blockedAsked = true
	end
end
check(not blockedAsked and #requested > 0, "no se piden los ids con puerta trasera ni el de Splatoon (" .. #requested .. " pedidos)")
check(NatureAssets.Blocked[114397068371248] and NatureAssets.Blocked[78188971759943] and NatureAssets.Blocked[116641210728889], "los packs con virus están en la lista negra")
local clean = true
local names = {}
for kind, list in library do
	for _, t in list do
		clean = clean and onlyMeshes(t.Model)
		names[t.Name] = kind
	end
end
check(clean, "las plantillas solo llevan MeshPart y SurfaceAppearance (sin scripts, carteles, textos ni atributos)")
check(#library.Park == 2 and #library.Conifer == 1, "árboles de parque (roble, cerezo) y abeto")
check(#library.Palm == 3, "palmeras de 8553512581 y 13388285234 (sin la malla de Half-Life 2)")
check(#library.Boulder == 4 and #library.Pebble == 5, "rocas grandes (sin la piedrecita de 1 stud) y 5 piedras pequeñas")
check(#library.Shark == 1 and #library.Fish == 2, "tiburón (sin las personas) y peces (sin el kraken)")
check(#library.Bush == 1, "arbusto (sin los animales)")
local oak = library.Park[1]
local hasLeaves, hasTrunk = false, false
for _, p in oak.Model:GetChildren() do
	hasLeaves = hasLeaves or p.Name == "Leaves"
	hasTrunk = hasTrunk or p.Name == "Trunk"
end
check(hasLeaves and hasTrunk, "copa «Leaves» y tronco «Trunk» (el viento lo pone Sway)")
check(string.find(oak.Name, "ArbolParque", 1, true) ~= nil and string.find(library.Palm[1].Name, "Palmera", 1, true) ~= nil, "nombres en español")
check(math.abs(oak.Height - 33.5 * 1.0) < 0.5, "altura de la plantilla medida")

---------------------------------------------------------------------
print("Palmeras y árboles por MeshLibrary (una sola pasada)")
local meshLib: any = {}
local added = NatureAssets.extend(meshLib, fakePack)
check(added == 2 + 1 + 3 + 1 and #meshLib.Palm == 3 and #meshLib.Tree == 2 and #meshLib.Conifer == 1, "extend añade Tree, Conifer, Palm y Bush")

local world = Instance.new("Model")
world.Name = "Playas"
local beach = Nature.palm(world, Vector3.new(500, -1, 300))
local info = MeshLibrary.treeInfo(beach)
local found = MeshLibrary.collect({ world }, nil, meshLib)
check(#found.Trees == 1, "MeshLibrary encuentra la palmera procedural (hay plantillas Palm)")
local replaced = MeshLibrary.replaceTree(beach, meshLib)
check(replaced ~= nil and string.find(replaced:GetAttribute("MeshVariant"), "Palmera", 1, true) ~= nil, "la palmera pasa a ser de malla")
if replaced and info then
	local lo, hi = MeshLibrary.bounds((function()
		local l = {}
		for _, p in replaced:GetChildren() do
			if p:IsA("BasePart") and p.Name ~= "Trunk" then
				table.insert(l, p)
			end
		end
		return l
	end)())
	check(math.abs(lo.Y - (info.Foot.Y - 0.25)) < 0.3, "apoyada en el suelo")
	check(hi.Y - lo.Y > info.Height * 1.1, ("más alta que la procedural (%.1f > %.1f)"):format(hi.Y - lo.Y, info.Height))
	local colliders = 0
	for _, p in replaced:GetChildren() do
		if p.Name == "Trunk" and p.Transparency == 1 and p.CanCollide then
			colliders += 1
		end
	end
	check(colliders > 0, "el tronco procedural queda como choque invisible")
	check(MeshLibrary.collect({ world }, nil, meshLib).Trees[1] == nil, "no se vuelve a cambiar (no se planta dos veces)")
end
local plain = Instance.new("Model")
local palm2 = Nature.palm(plain, Vector3.new(0, 0, 0))
check(MeshLibrary.replaceTree(palm2, { Tree = meshLib.Tree }) == nil and palm2.Parent == plain, "sin plantillas Palm la palmera se queda procedural (no pasa a árbol)")
check(#MeshLibrary.collect({ plain }, nil, { Tree = meshLib.Tree }).Trees == 0, "sin plantillas Palm no se recogen palmeras")

local one = { Name = "X", Model = library.Park[1].Model, Foot = library.Park[1].Foot, Height = 33.5, Width = 24, MaxUses = 1, Uses = 0 }
local lib1: any = { Tree = { one } }
local a = Instance.new("Model")
local t1 = Nature.tree(a, Vector3.new(10, 0, 10), 1.6)
local t2 = Nature.tree(a, Vector3.new(90, 0, 40), 1.6)
local r1 = MeshLibrary.replaceTree(t1, lib1)
local r2 = MeshLibrary.replaceTree(t2, lib1)
check(r1 ~= nil and r2 == nil and one.Uses == 1, "MaxUses: la plantilla pesada no pasa de su tope")

---------------------------------------------------------------------
print("Rocas, piedras, peces")
local folder = Instance.new("Folder")
local spots = NatureAssets.boulderSpots(CityPlan)
check(#spots > 40, "sitios para rocas en montañas, río y lagos (" .. #spots .. ")")
local probed = 0
local rocks = NatureAssets.placeBoulders(folder, library, spots, function(x, z)
	probed += 1
	if probed % 3 == 0 then
		return nil -- (calle o agua: no)
	end
	return 4
end)
check(rocks > 0 and rocks <= NatureAssets.MaxBoulders, ("rocas colocadas (%d), con tope"):format(rocks))
local okRocks = true
for _, m in folder:GetChildren() do
	local list = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(list, p)
			okRocks = okRocks and p.CanCollide and p.Anchored
		end
	end
	local lo, hi = MeshLibrary.bounds(list)
	local size = hi - lo
	okRocks = okRocks and lo.Y < 4 and lo.Y > 4 - size.Y * 0.4 and math.max(size.X, size.Y, size.Z) <= 33
end
check(okRocks, "rocas ancladas, con choque, un poco enterradas y de 9 a 23 studs")

local lawn = Instance.new("Part")
lawn.Name = "Lawn"
lawn.Size = Vector3.new(120, 0.3, 80)
lawn.CFrame = CFrame.new(1000, 0.15, 1000)
local pf = Instance.new("Folder")
local pebbles = NatureAssets.placePebbles(pf, library, lawn, nil, 100)
local okPeb = pebbles == 18
for _, m in pf:GetChildren() do
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			okPeb = okPeb and not p.CanCollide and p:HasTag("PropDetail")
				and math.abs(p.CFrame.Position.X - 1000) < 60 and math.abs(p.CFrame.Position.Z - 1000) < 40
		end
	end
end
check(okPeb, "18 piedrecitas dentro del césped, sin choque y con PropDetail (se ven también en Bajo)")
check(NatureAssets.placePebbles(pf, library, lawn, nil, 2) == 2, "las piedrecitas respetan el tope")

local counter = Instance.new("Part")
counter.Size = Vector3.new(12, 3, 4.2)
counter.CFrame = CFrame.new(50, 1.9, 50)
check(NatureAssets.dressCounter(counter, library) == 3, "3 peces en el mostrador de la pescadería")
local onTop = true
for _, p in counter.PecesMostrador:GetDescendants() do
	if p:IsA("BasePart") then
		onTop = onTop and p.CFrame.Position.Y > 3.3 and math.abs(p.CFrame.Position.X - 50) < 6.5
	end
end
check(onTop, "encima del mostrador")
check(NatureAssets.dressCounter(counter, library) == 0, "no se ponen dos veces")

local fish = Instance.new("Part")
fish.Size = Vector3.new(0.7, 0.9, 2)
fish.CFrame = CFrame.new(10, -6, 10)
fish:SetAttribute("Species", "Dorada")
check(NatureAssets.dressSwimFish(fish, library) and fish.Transparency == 1, "el pez que nada se ve con su malla")
local welded = false
for _, p in fish:GetDescendants() do
	if p:IsA("MeshPart") then
		welded = not p.Anchored and not p.CanCollide and p:FindFirstChildOfClass("WeldConstraint") ~= nil
	end
end
check(welded, "malla soldada al pez (se mueve con él) y sin choque")

local sea = true
for _, s in NatureAssets.sharkSpots(CityPlan) do
	sea = sea and not CityPlan.inside(CityPlan.Coast, s.X, s.Z) and s.Y < -2 and s.Y > -14
end
check(sea and #NatureAssets.sharkSpots(CityPlan) == 4, "tiburones en el mar, bajo el agua")

---------------------------------------------------------------------
print("Recambios limpios: rincón japonés y hogueras")
NatureAssets.reset()
local asked2: { number } = {}
local function cleanPack(id: number): any
	table.insert(asked2, id)
	local root = Instance.new("Model")
	local s = Instance.new("Script")
	s.Parent = root
	if id == 10586979345 then
		treeModel(root, "Cherry Blossom Tree", 40, 44, "Blossom", "Trunk")
	elseif id == 9854052347 then
		single(root, "Stone Lantern", Vector3.new(2, 5, 2))
	elseif id == 4698399766 then
		single(root, "Lion Dog Statue", Vector3.new(2, 4, 3))
	elseif id == 10840661513 then
		local pit = Instance.new("Model")
		pit.Name = "FirePit"
		pit.Parent = root
		local fire = Instance.new("Model")
		fire.Name = "Campfire"
		fire.Parent = pit
		mesh(fire, "Stones", Vector3.new(5, 1, 5), Vector3.new(0, 0.5, 0))
		mesh(fire, "Logs", Vector3.new(3, 1.5, 3), Vector3.new(0, 1, 0))
		single(root, "Rhododendron", Vector3.new(5, 4, 5))
	elseif id == 10562894034 then
		treeModel(root, "Palm Tree (Realistic)", 20, 30, "Leaves", "Trunk")
	else
		return nil
	end
	return root
end
local lib2 = NatureAssets.load(cleanPack)
local badAsked = false
for _, id in asked2 do
	badAsked = badAsked or NatureAssets.Blocked[id] ~= nil
end
check(not badAsked, "los recambios sustituyen a los packs con virus: esos ni se piden")
local strippedFirst = #NatureAssets.Log > 0
for _, entry in NatureAssets.Log do
	strippedFirst = strippedFirst and entry.Unparented and entry.Stripped >= 1
end
check(strippedFirst, "a cada pack se le borran los scripts nada más cargarlo, aún sin padre")
check(#lib2.Sakura == 1 and #lib2.Lantern == 1 and #lib2.Guardian == 1 and #lib2.Campfire == 1, "cerezo, farol, guardián y hoguera")
check(#lib2.Palm == 1 and #lib2.Bush == 1, "palmera limpia y arbusto del pack de jardinería")
local clean2 = true
for _, list in lib2 do
	for _, t in list do
		clean2 = clean2 and onlyMeshes(t.Model)
	end
end
check(clean2, "solo mallas, sin scripts ni carteles")

local park = Instance.new("Part")
park.Name = "Lawn"
park.Size = Vector3.new(140, 0.3, 100)
park.CFrame = CFrame.new(2000, 0.15, 2000)
local jf = Instance.new("Folder")
local placed = NatureAssets.placeJapaneseCorner(jf, lib2, park, function()
	return 0.3
end)
local inLawn, kinds = true, {}
for _, m in jf:GetChildren() do
	kinds[m.Name] = (kinds[m.Name] or 0) + 1
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			inLawn = inLawn and math.abs(p.CFrame.Position.X - 2000) < 70 and math.abs(p.CFrame.Position.Z - 2000) < 50
		end
	end
end
check(placed and kinds.Cerezo == 1 and kinds.FarolPiedra == 2 and kinds.Guardian == 2, "rincón japonés: un cerezo, dos faroles y dos guardianes")
check(inLawn, "todo dentro del césped del parque")
check(not NatureAssets.placeJapaneseCorner(Instance.new("Folder"), lib2, park, function()
	return nil
end), "sin sitio libre, no se pone")

local tables = {}
for i = 1, 6 do
	local t = Instance.new("Part")
	t.Name = "PicnicTable"
	t.CFrame = CFrame.new(i * 40, 3, 0)
	table.insert(tables, t)
end
local ff = Instance.new("Folder")
local fires = NatureAssets.placeCampfires(ff, lib2, tables, function()
	return 1
end)
local lit = true
for _, m in ff:GetChildren() do
	local flame = m:FindFirstChild("Llama")
	lit = lit and flame ~= nil and flame:FindFirstChildOfClass("Fire") ~= nil and flame:FindFirstChildOfClass("PointLight") ~= nil
end
check(fires == 3 and lit, "hogueras en una de cada dos mesas de pícnic, con fuego y luz")
NatureAssets.reset()

---------------------------------------------------------------------
print("Si falla la carga")
NatureAssets.reset()
local empty = NatureAssets.load(function()
	error("User is not authorized to access Asset.")
end)
local total = 0
for _, list in empty do
	total += #list
end
check(total == 0, "sin plantillas, sin error")
local other: any = { Tree = {} }
check(NatureAssets.extend(other, nil) == 0 and #other.Tree == 0, "extend no añade nada")
check(NatureAssets.placeBoulders(Instance.new("Folder"), empty, spots, function() return 0 end) == 0, "no se ponen rocas")
local f2 = Instance.new("Part")
check(not NatureAssets.dressSwimFish(f2, empty) and f2.Transparency == 0, "los peces que nadan siguen como estaban")

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
