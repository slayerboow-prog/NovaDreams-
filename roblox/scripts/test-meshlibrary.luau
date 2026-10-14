-- Prueba de la vegetación con modelos 3D (World/MeshLibrary) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-meshlibrary.luau                (packs falsos y árboles de Kit/Nature)
--   lune run scripts/test-meshlibrary.luau /tmp/x.rbxl     (además, con los árboles del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- En Lune no hay InsertService: se hace un pack falso (Folder "Forest Pack" y "Landscaping Pack" con
-- Models de MeshPart con los mismos nombres y tallas que los de verdad, y scripts como los animales).
-- Comprueba que:
--   * se borran TODOS los scripts de lo cargado y la tierra (Soil) de debajo de los árboles
--   * de nombres repetidos (BeechwoodTree_Var03 x2) se queda el que tiene copa; los animales no entran
--   * la variante sale según la posición (mismo sitio, misma; sitios distintos, varias)
--   * el árbol nuevo tiene la altura del original (± la variación), apoyado en el suelo, copa sin
--     colisión con Sway + Pivot, tronco de malla sin colisión y el choque del tronco original invisible
--   * arbustos y flores también; sin plantillas (fallo de carga) no se toca nada
--   * MeshLibrary.load() en Lune (sin InsertService) no rompe: devuelve nil

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

local waits = 0
local base = {
	Enum = Enum,
	Vector3 = Vector3,
	Color3 = Color3,
	CFrame = CFrame,
	Instance = Instance,
	task = {
		wait = function()
			waits += 1
		end,
	},
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
-- Packs falsos (mismos nombres y tallas que los de verdad)
---------------------------------------------------------------------
local function mesh(parent: any, name: string, size: any, center: any)
	local p = Instance.new("MeshPart")
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(center)
	p.Anchored = false
	p.CanCollide = true
	local sa = Instance.new("SurfaceAppearance")
	sa.Parent = p
	p.Parent = parent
	return p
end

-- Árbol: copa arriba, tronco abajo (su caja casi tan grande como la copa, como en el pack), tierra
local function tree(parent: any, name: string, w: number, h: number, d: number, soil: boolean?, leafName: string?)
	local m = Instance.new("Model")
	m.Name = name
	local at = Vector3.new(100, 0, -50) -- el pack no está en el origen
	mesh(m, "Trunk", Vector3.new(w * 0.8, h * 0.94, d * 0.8), at + Vector3.new(0, h * 0.47, 0))
	mesh(m, leafName or "Leaf", Vector3.new(w, h * 0.85, d), at + Vector3.new(0, h - h * 0.425, 0))
	if soil then
		mesh(m, "Soil", Vector3.new(w * 0.3, 2, d * 0.3), at + Vector3.new(0, -0.5, 0))
	end
	m.Parent = parent
	return m
end
local function plant(parent: any, name: string, w: number, h: number, d: number)
	local m = Instance.new("Model")
	m.Name = name
	mesh(m, "Flower", Vector3.new(w, h, d), Vector3.new(-30, h / 2, 12))
	m.Parent = parent
	return m
end
local function animal(parent: any, name: string)
	local m = Instance.new("Model")
	m.Name = name
	mesh(m, "GEO_" .. name, Vector3.new(1.1, 0.2, 0.7), Vector3.new(0, 5, 0))
	local s = Instance.new("Script")
	s.Parent = m
	m.Parent = parent
end

local function fakeForest()
	local root = Instance.new("Model")
	root.Name = "Model"
	local pack = Instance.new("Folder")
	pack.Name = "Forest Pack"
	pack.Parent = root
	tree(pack, "BroadLeafTree_Var01", 28.1, 36, 34.7)
	tree(pack, "MapleLeafTreeVar01", 47, 32.4, 44.7, false, "OuterLeaves")
	-- Dogwood: las piezas dentro de un modelo "Meshes"
	local dog = Instance.new("Model")
	dog.Name = "DogwoodTree_Var01"
	local meshes = Instance.new("Model")
	meshes.Name = "Meshes"
	meshes.Parent = dog
	mesh(meshes, "Dogwood Trees 01_Trunk", Vector3.new(23.4, 25.5, 25.2), Vector3.new(0, 12.75, 0))
	mesh(meshes, "Dogwood Trees 01_Leaf", Vector3.new(31.9, 21.5, 31.5), Vector3.new(0, 15.75, 0))
	dog.Parent = pack
	-- Dos BeechwoodTree_Var03: primero el que es solo un tronco (no vale), luego el bueno
	local bare = Instance.new("Model")
	bare.Name = "BeechwoodTree_Var03"
	mesh(bare, "Trunk", Vector3.new(7.7, 25.6, 14.6), Vector3.new(0, 12.8, 0))
	bare.Parent = pack
	tree(pack, "BeechwoodTree_Var03", 38.7, 46.3, 29.3, true)
	tree(pack, "BeechwoodTree_Var02", 13.3, 25.3, 18.1, false, "Leaves")
	tree(pack, "BeechwoodSapling_Var01", 7.2, 12.5, 7.3, false, "Leaves")
	tree(pack, "MountainLaurelBush_Var01", 6.7, 5.3, 6.7)
	tree(pack, "RhododendronVar01", 10, 5.8, 12.3, false, "Leaves")
	tree(pack, "RhododendronVar02", 10, 5.3, 12.3, false, "Leaves")
	plant(pack, "WildFlower01", 4.4, 2.7, 5.3)
	plant(pack, "Wildflower02", 3.5, 2.6, 2.9)
	plant(pack, "WildFlower03", 1.4, 3.2, 1.4)
	plant(pack, "WildFlower04", 1.2, 2.6, 1.2)
	animal(pack, "Butterfly_FlightPath01")
	animal(pack, "Hawk_FlightPath01")
	-- El secuoya grande lleva dentro un Dogwood: no cuenta como modelo suelto
	local redwood = tree(pack, "RedwoodTreeLarge-Var01", 110, 263, 107, true, "OuterLeaves")
	tree(redwood, "DogwoodTree_Var01", 1, 1, 1)
	return root
end

local function fakeLandscaping()
	local root = Instance.new("Model")
	root.Name = "Model"
	local pack = Instance.new("Folder")
	pack.Name = "Landscaping Pack"
	pack.Parent = root
	local bushes = Instance.new("Folder")
	bushes.Name = "Bushes"
	bushes.Parent = pack
	tree(bushes, "Hedge_Bush_Long", 4.2, 10.6, 18.8)
	local flowers = Instance.new("Folder")
	flowers.Name = "Flowers"
	flowers.Parent = pack
	plant(flowers, "Flowering_Shrub_04", 3.8, 3.6, 3.3)
	plant(flowers, "Flowering_Shrub_05", 3, 3.2, 2.3)
	plant(flowers, "Marigold_A", 1.2, 1.6, 1.3)
	plant(flowers, "Flowering_Shrub_01", 1.3, 1.8, 1.7)
	local rocks = Instance.new("Folder")
	rocks.Name = "Rocks|Bricks"
	rocks.Parent = pack
	animal(rocks, "Rock_Pillars_large_floating")
	animal(rocks, "HerbGardenBrick_TriangleLarge_Floating")
	local loose = Instance.new("ModuleScript")
	loose.Parent = pack
	return root
end

local function countCode(root: any): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------------
print("Carga en Lune (sin InsertService)")
---------------------------------------------------------------------
do
	local ok, result = pcall(MeshLibrary.load)
	check(ok and result == nil, "MeshLibrary.load() no rompe y no devuelve nada")
	local okStart = pcall(MeshLibrary.start, {})
	check(okStart, "MeshLibrary.start() tampoco rompe (se queda lo procedural)")
	local src = fs.readFile("src/server/Main.server.luau")
	check(src:find("World.MeshLibrary", 1, true) ~= nil and src:find("task.spawn", src:find("World.MeshLibrary", 1, true) - 200, true) ~= nil, "Main lo arranca en un hilo aparte (task.spawn + pcall)")
end

---------------------------------------------------------------------
print("Plantillas")
---------------------------------------------------------------------
local forest, land = fakeForest(), fakeLandscaping()
check(countCode(forest) + countCode(land) == 5, "los packs falsos traen scripts (como los de verdad)")
local library = MeshLibrary.prepare({ forest, land })
check(countCode(forest) + countCode(land) == 0, "se borran TODOS los scripts de lo cargado")
local function names(kind: string): { [string]: boolean }
	local out = {}
	for _, t in library[kind] do
		out[t.Name] = true
	end
	return out
end
local okCode, okSoil, okAnchored = true, true, true
for _, list in library do
	for _, t in list do
		if countCode(t.Model) > 0 then
			okCode = false
		end
		for _, d in t.Model:GetDescendants() do
			if d.Name == "Soil" then
				okSoil = false
			end
			if d:IsA("BasePart") and not d.Anchored then
				okAnchored = false
			end
		end
	end
end
check(okCode, "ninguna plantilla lleva scripts")
check(okSoil and okAnchored, "sin la tierra de debajo y todas las piezas ancladas")
local treeNames = names("Tree")
check(#library.Tree == 4 and treeNames.BroadLeafTree_Var01 and treeNames.DogwoodTree_Var01 and treeNames.MapleLeafTreeVar01 and treeNames.BeechwoodTree_Var03, ("árboles de hoja ancha: %d variantes"):format(#library.Tree))
local beech = nil
for _, t in library.Tree do
	if t.Name == "BeechwoodTree_Var03" then
		beech = t
	end
end
check(beech and math.abs(beech.Height - 46.3) < 0.6, "BeechwoodTree_Var03: el que tiene copa (46 de alto), no el tronco suelto")
check(#library.Street == 3 and #library.Young == 2, ("árboles de calle %d y jóvenes %d"):format(#library.Street, #library.Young))
check(#library.Bush == 5 and names("Bush").Flowering_Shrub_04, ("arbustos: %d (Forest y Landscaping)"):format(#library.Bush))
check(#library.Flower == 6, ("flores: %d"):format(#library.Flower))
local okAnimals = true
for _, list in library do
	for _, t in list do
		if t.Name:find("Butterfly") or t.Name:find("Hawk") or t.Name:find("floating") or t.Name:find("Redwood") or t.Name:find("Hedge") then
			okAnimals = false
		end
	end
end
check(okAnimals, "ni animales, ni rocas flotantes, ni secuoyas, ni setos")
local broad = library.Tree[1]
check(broad.Name == "BroadLeafTree_Var01" and math.abs(broad.Height - 36) < 0.5 and math.abs(broad.Foot.X - 100) < 0.01, "altura natural y pie del tronco medidos")

---------------------------------------------------------------------
print("Variante según la posición")
---------------------------------------------------------------------
do
	local a = MeshLibrary.pick(library, "Tree", Vector3.new(10, 0, 20))
	local b = MeshLibrary.pick(library, "Tree", Vector3.new(10, 0, 20))
	check(a ~= nil and a == b, "mismo sitio, misma variante")
	local seen, n = {}, 0
	for i = 1, 60 do
		local t = MeshLibrary.pick(library, "Tree", Vector3.new(i * 37.3, 0, i * 11.9))
		if t and not seen[t.Name] then
			seen[t.Name] = true
			n += 1
		end
	end
	check(n == #library.Tree, ("sitios distintos dan todas las variantes (%d de %d)"):format(n, #library.Tree))
	local narrow = MeshLibrary.pick(library, "Tree", Vector3.new(5, 0, 5), 0.7)
	check(narrow and narrow.Width / narrow.Height <= 0.7 * 1.4, "con un hueco estrecho no sale una copa muy ancha")
	check(MeshLibrary.pick({}, "Tree", Vector3.new()) == nil, "sin plantillas: nada")
end

---------------------------------------------------------------------
print("Árboles cambiados")
---------------------------------------------------------------------
local world = Instance.new("Model")
world.Name = "Town"
local streets = Instance.new("Folder")
streets.Name = "Streets"
streets.Parent = world
local park = Instance.new("Folder")
park.Name = "Jardin"
park.Parent = world

local function heightOf(m: any): (number, number)
	local list = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(list, d)
		end
	end
	local lo, hi = MeshLibrary.bounds(list)
	return hi.Y - lo.Y, lo.Y
end

local okHeight, okGround, okCrown, okTrunk, okCollider, okName, okSway, okVariant, okStreet = true, true, true, true, true, true, true, true, true
local worst = 0
local variants = {}
for i = 1, 40 do
	local parent = if i % 2 == 0 then streets else park
	local pos = Vector3.new((i % 8) * 41.3 - 160, (i % 3) * 2, math.floor(i / 8) * 45.7 - 120)
	local original = Nature.tree(parent, pos, 0.8 + (i % 6) * 0.15)
	local origH = heightOf(original)
	local trunks = {}
	for _, d in original:GetChildren() do
		if d.Name == "Trunk" then
			table.insert(trunks, { Size = d.Size, CFrame = d.CFrame })
		end
	end
	local info = MeshLibrary.treeInfo(original)
	local new = MeshLibrary.replaceTree(original, library)
	if not new then
		okVariant = false
		continue
	end
	variants[new:GetAttribute("MeshVariant")] = true
	if original.Parent ~= nil or new.Parent ~= parent or new.Name ~= "Tree" then
		okName = false
	end
	local h, bottom = heightOf(new)
	local ratio = h / origH
	worst = math.max(worst, math.abs(1 - ratio))
	if ratio < 0.68 or ratio > 1.15 then
		okHeight = false
	end
	if math.abs(bottom - (info.Foot.Y - 0.25)) > 0.05 then
		okGround = false
	end
	local colliders = 0
	for _, d in new:GetChildren() do
		if d:IsA("BasePart") then
			if d.Name == "Leaves" then
				if d.CanCollide or d.CanQuery or d.CanTouch then
					okCrown = false
				end
				if not d:HasTag("Sway") or typeof(d:GetAttribute("Pivot")) ~= "Vector3" then
					okSway = false
				end
			elseif d.Name == "TrunkMesh" then
				if d.CanCollide or d.CanQuery then
					okTrunk = false
				end
			elseif d.Name == "Trunk" then
				colliders += 1
				if not d.CanCollide or d.Transparency ~= 1 or d.CastShadow then
					okCollider = false
				end
			end
		end
	end
	if colliders ~= #trunks then
		okCollider = false
	end
	for _, t in trunks do
		local found = false
		for _, d in new:GetChildren() do
			if d.Name == "Trunk" and (d.CFrame.Position - t.CFrame.Position).Magnitude < 0.01 and (d.Size - t.Size).Magnitude < 0.01 then
				found = true
			end
		end
		if not found then
			okCollider = false
		end
	end
	if parent == streets and not (new:GetAttribute("MeshVariant") == "BeechwoodTree_Var02" or new:GetAttribute("MeshVariant") == "BroadLeafTree_Var01" or new:GetAttribute("MeshVariant") == "BeechwoodTree_Var03" or new:GetAttribute("MeshVariant") == "BeechwoodSapling_Var01") then
		okStreet = false
	end
end
check(okVariant and okName, "cada árbol se cambia por un Model \"Tree\" en el mismo sitio (el original se borra)")
check(okHeight, ("escalado a la altura del original (desvío máximo %.0f %%)"):format(worst * 100))
check(okGround, "apoyado en el suelo (un pelín hundido)")
check(okCrown and okSway, "copa \"Leaves\" sin colisión ni consultas, con Sway y Pivot (viento)")
check(okTrunk, "tronco de malla (con ramas) sin colisión")
check(okCollider, "el choque del tronco original se queda, invisible y en su sitio")
check(okStreet, "en las calles, solo variantes de copa estrecha")
local nv = 0
for _ in variants do
	nv += 1
end
check(nv >= 3, ("varias variantes en la ciudad (%d)"):format(nv))

-- Mismo sitio, mismo árbol (aunque se vuelva a construir)
do
	local w1, w2 = Instance.new("Folder"), Instance.new("Folder")
	local a = MeshLibrary.replaceTree(Nature.tree(w1, Vector3.new(12, 0, 34), 1), library)
	local b = MeshLibrary.replaceTree(Nature.tree(w2, Vector3.new(12, 0, 34), 1), library)
	local ha, hb = heightOf(a), heightOf(b)
	check(a:GetAttribute("MeshVariant") == b:GetAttribute("MeshVariant") and math.abs(ha - hb) < 1e-3, "mismo sitio: misma variante, misma talla")
	check(MeshLibrary.replaceTree(a, library) == nil, "un árbol ya cambiado no se vuelve a cambiar")
end

---------------------------------------------------------------------
print("Arbustos y flores")
---------------------------------------------------------------------
do
	local garden = Instance.new("Model")
	for i = 1, 12 do
		Nature.bush(garden, Vector3.new(i * 9, 0, 3))
	end
	local bed = Nature.flowerBed(garden, CFrame.new(0, 0, 40), 8, 5)
	local nFlowers = 0
	for _, d in bed:GetChildren() do
		if d.Name == "Flower" then
			nFlowers += 1
		end
	end
	local done = MeshLibrary.run({ garden }, library, nil)
	check(done.Bushes == 12 and done.Flowers == nFlowers, ("cambiados %d arbustos y %d de %d flores"):format(done.Bushes, done.Flowers, nFlowers))
	local okBush, okFlower = true, true
	for _, d in garden:GetChildren() do
		if d.Name == "Bush" then
			if not d:IsA("Model") then
				okBush = false
			end
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") and (p.CanCollide or p.CastShadow) then
					okBush = false
				end
			end
			local h = heightOf(d)
			if h < 1.5 or h > 5 then
				okBush = false
			end
		end
	end
	for _, d in bed:GetChildren() do
		if d.Name == "Flower" then
			if not d:IsA("MeshPart") or d.CanCollide or d.CastShadow or d:GetAttribute("MeshVariant") == nil or d.Size.Y > 2.5 then
				okFlower = false
			end
		end
	end
	check(okBush, "arbustos: Model \"Bush\" (se apartan al pasar), sin choque ni sombra, de su talla")
	check(okFlower, "flores de malla pequeñas en el parterre, sin choque ni sombra")
	check(waits > 0, "va en tandas (task.wait entre tandas)")
end

---------------------------------------------------------------------
print("Sin plantillas (falla la carga)")
---------------------------------------------------------------------
do
	local w = Instance.new("Model")
	local t = Nature.tree(w, Vector3.new(1, 0, 1), 1)
	Nature.bush(w, Vector3.new(5, 0, 5))
	local before = #w:GetDescendants()
	local empty = MeshLibrary.prepare({})
	local done = MeshLibrary.run({ w }, empty, nil)
	check(MeshLibrary.count(empty) == 0 and done.Trees == 0 and done.Bushes == 0, "no se cambia nada")
	check(t.Parent == w and #w:GetDescendants() == before, "el árbol procedural se queda entero")
	check(MeshLibrary.replaceTree(t, empty) == nil and t.Parent == w, "replaceTree sin plantillas deja el original")
end

---------------------------------------------------------------------
print("Topes y orden")
---------------------------------------------------------------------
do
	local w = Instance.new("Model")
	local town = Instance.new("Folder")
	town.Name = "Streets"
	town.Parent = w
	local wild = Instance.new("Folder")
	wild.Name = "Naturaleza"
	wild.Parent = w
	for i = 1, 10 do
		Nature.tree(wild, Vector3.new(i * 30, 0, 5), 1)
		Nature.tree(town, Vector3.new(i * 30, 0, 600), 1)
	end
	local old = MeshLibrary.MaxTrees
	MeshLibrary.MaxTrees = 12
	local found = MeshLibrary.collect({ w }, { { A = Vector3.new(0, 0, 600), B = Vector3.new(400, 0, 600) } })
	MeshLibrary.MaxTrees = old
	local town10 = 0
	for i = 1, 10 do
		if found.Trees[i].Parent == town then
			town10 += 1
		end
	end
	check(#found.Trees == 12 and town10 == 10, "con tope, primero los de cerca de las calles; el monte, lo último")
end

---------------------------------------------------------------------
-- El mapa construido
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("Mapa construido (" .. placePath .. ")")
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local ws = place:GetService("Workspace")
	local roots = {}
	for _, child in ws:GetChildren() do
		if child:IsA("Model") or child:IsA("Folder") then
			table.insert(roots, child)
		end
	end
	local found = MeshLibrary.collect(roots, nil)
	check(#found.Trees > 1000 and #found.Trees <= MeshLibrary.MaxTrees, ("%d árboles a cambiar (tope %d)"):format(#found.Trees, MeshLibrary.MaxTrees))
	check(#found.Bushes > 100 and #found.Flowers > 100, ("%d arbustos y %d flores"):format(#found.Bushes, #found.Flowers))
	local bad, n = 0, 0
	for i = 1, #found.Trees, 7 do
		local t = found.Trees[i]
		local ok, new = pcall(MeshLibrary.replaceTree, t, library)
		n += 1
		if not ok or not new or not new:FindFirstChild("Trunk") or not new:FindFirstChild("Leaves") then
			bad += 1
		end
	end
	check(bad == 0, ("%d árboles del mapa cambiados sin fallos (%d raros)"):format(n, bad))
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
