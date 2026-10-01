-- Prueba de los materiales PBR del dueño (World/UserMaterials, shared/UserMaterialChoice) FUERA de
-- Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):  lune run scripts/test-usermaterials.luau
--
-- Los packs de mentira se montan con el contenido real de docs/assets-usuario.md (mismos nombres,
-- BaseMaterial, StudsPerTile y patrón; un Model raíz con carpeta, como llegan) y además con scripts
-- metidos dentro. Comprueba que:
--   * la tabla de elección solo apunta a variants que existen en el doc (con su pack y su
--     BaseMaterial), sin rotos ni nombres repetidos, con materiales de Roblox de verdad
--   * al desempaquetar: se borran los scripts y los variants rotos, cada variant se renombra con
--     prefijo único "U_<pack>_…" (sin nombres repetidos) y se guarda en la biblioteca
--   * al aplicar: cada material de la tabla queda sustituido por su variant (en MaterialService, con
--     el BaseMaterial cambiado si venía sobre otro), y si falta un pack se usa el respaldo
--   * convive con lo nuestro (Kit/MaterialLook): gana el del dueño arranque antes o después, el
--     metal y el bordillo siguen siendo nuestros y las reglas pieza a pieza siguen funcionando
--   * aclara las piezas y el terreno de esos materiales una sola vez, sin tocar lo que lleva variant
--   * sin carga no se toca nada

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Color3, Instance = roblox.Enum, roblox.Color3, roblox.Instance

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function load(path: string, env: { [string]: any }?): any
	local e = { Enum = Enum, Color3 = Color3, Instance = Instance, Vector3 = roblox.Vector3, CFrame = roblox.CFrame, warn = print }
	for k, v in env or {} do
		e[k] = v
	end
	setmetatable(e, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = e })()
end

local Choice = load("src/shared/UserMaterialChoice.luau")
local Textures = load("src/shared/Textures.luau")

---------------------------------------------------------------------
-- El doc: id del pack -> lista de { Name, Base, Studs, Pattern }
---------------------------------------------------------------------
local doc: { [number]: { { Name: string, Base: string, Studs: number, Pattern: string } } } = {}
do
	local current: number? = nil
	for line in fs.readFile("docs/assets-usuario.md"):gmatch("[^\n]+") do
		local id = line:match("^## (%d+) ")
		if id then
			current = tonumber(id)
			doc[current :: number] = {}
		elseif line:match("^## ") then
			current = nil
		elseif current then
			local name, base, studs, pattern = line:match("^| (.-) | (%a+) | ([%d%.]+) | (%a+) |$")
			if name then
				table.insert(doc[current], { Name = name, Base = base, Studs = tonumber(studs) :: number, Pattern = pattern })
			end
		end
	end
end
local byShort: { [string]: { [string]: { Base: string, Count: number } } } = {}
for _, pack in Choice.Packs do
	local list = doc[pack.Id]
	byShort[pack.Short] = {}
	for _, v in list or {} do
		local entry = byShort[pack.Short][v.Name]
		if entry then
			entry.Count += 1
		else
			byShort[pack.Short][v.Name] = { Base = v.Base, Count = 1 }
		end
	end
end

print("El doc de los packs")
do
	local expected = { [11392874817] = 1, [13277933714] = 20, [14527172541] = 6, [15221806045] = 524, [15446413305] = 8, [92927007790601] = 68 }
	local ok = true
	for id, n in expected do
		if not doc[id] or #doc[id] ~= n then
			ok = false
			print(("     pack %d: %d variants en el doc (se esperaban %d)"):format(id, if doc[id] then #doc[id] else -1, n))
		end
	end
	check(ok and #Choice.Packs == 6, "se leen los 6 packs del doc con todos sus variants (1, 20, 6, 524, 8, 68)")
end

print("La tabla de elección")
do
	local okRefs, okBase, okUnique, okBroken = true, true, true, true
	local materials = {}
	local okMat, okNum = true, true
	for _, choice in Choice.Table do
		if materials[choice.Material] then
			okUnique = false
		end
		materials[choice.Material] = true
		if not pcall(function()
			return (Enum.Material :: any)[choice.Material]
		end) then
			okMat = false
		end
		if choice.Whiten < 0 or choice.Whiten > 1 or (choice.Studs and (choice.Studs < 3 or choice.Studs > 30)) then
			okNum = false
		end
		if choice.Pattern and choice.Pattern ~= "Regular" and choice.Pattern ~= "Organic" then
			okNum = false
		end
		check(#choice.Candidates >= 2 and type(choice.Why) == "string" and #choice.Why > 5, ("%s: al menos un respaldo y su porqué (%s)"):format(choice.Material, choice.Why))
		for _, cand in choice.Candidates do
			local entry = byShort[cand.Pack] and byShort[cand.Pack][cand.Name]
			if not entry then
				okRefs = false
				print(("     %s: %s/%s no está en el doc"):format(choice.Material, cand.Pack, cand.Name))
			else
				if entry.Base ~= cand.From then
					okBase = false
					print(("     %s: %s/%s va sobre %s en el doc, no %s"):format(choice.Material, cand.Pack, cand.Name, entry.Base, cand.From))
				end
				if entry.Count > 1 then
					okUnique = false
				end
			end
			if Choice.isBroken(cand.Pack, cand.Name) then
				okBroken = false
			end
		end
	end
	check(okRefs, "cada candidato es un variant que existe en docs/assets-usuario.md (pack y nombre)")
	check(okBase, "cada candidato dice bien su BaseMaterial del doc (From)")
	check(okUnique, "un material por fila y ningún candidato con nombre repetido en su pack")
	check(okBroken, "ningún candidato es de los rotos (texturas rbxtemp://)")
	check(okMat and okNum, "materiales de Roblox de verdad, Whiten 0..1, StudsPerTile 3-30 y patrón válido")
	for _, m in { "Grass", "LeafyGrass", "Asphalt", "Pavement", "Concrete", "Brick", "Plaster", "ClayRoofTiles", "Cobblestone", "Slate", "Marble", "Sand", "Rock", "Ground", "Wood", "WoodPlanks" } do
		if not materials[m] then
			check(false, "la tabla cubre " .. m)
		end
	end
	check(not materials.Metal and not materials.Granite and not materials.SmoothPlastic, "metal pintado, bordillo de granito y plásticos se quedan con lo nuestro")
	local grass = Choice.choose({ Cesped = { ["MaterialVariant 3"] = true }, Real = { Grass = true } })
	check(#grass == 1 and grass[1].Pack == "Cesped", "el césped es el 2k que eligió el dueño")
	check(Choice.variantName("Mega", "Marble SmoothPolishedElegantMaterial") == "U_Mega_MarbleSmoothPolishedElegantMaterial" and Choice.variantName("Cesped", "MaterialVariant 3") == "U_Cesped_MaterialVariant3", "nombre con prefijo U_ y el pack, sin espacios")
	local w = Choice.whiten(Color3.fromRGB(46, 48, 53), 0.65)
	check(w.R > 0.65 and w.R < 0.8 and math.abs(w.R - w.B) < 0.05, ("aclarar el asfalto: gris claro sin cambiar de tono (%.2f)"):format(w.R))
	check(Choice.whiten(Color3.new(0.2, 0.4, 0.6), 0) == Color3.new(0.2, 0.4, 0.6), "Whiten 0 no cambia el color")
end

---------------------------------------------------------------------
-- Packs de mentira (con el contenido del doc) y el módulo del servidor
---------------------------------------------------------------------
local function fakePack(id: number): any
	local model = Instance.new("Model")
	model.Name = "Model"
	local folder = Instance.new("Folder")
	folder.Name = "Pack"
	folder.Parent = model
	for _, v in doc[id] do
		local mv = Instance.new("MaterialVariant")
		mv.Name = v.Name
		mv.BaseMaterial = (Enum.Material :: any)[v.Base]
		mv.StudsPerTile = v.Studs
		mv.MaterialPattern = (Enum.MaterialPattern :: any)[v.Pattern]
		mv.Parent = folder
	end
	local s = Instance.new("Script")
	s.Name = "Virus"
	s.Parent = folder
	local m = Instance.new("ModuleScript")
	m.Name = "Nested"
	m.Parent = folder:FindFirstChildWhichIsA("MaterialVariant")
	return model
end

local function newModules(): (any, any, any, any)
	local service = Instance.new("MaterialService")
	local storage = Instance.new("Folder")
	local shared = { Textures = Textures, TextureIds = {}, UserMaterialChoice = Choice }
	local fakeGame = {
		GetService = function(_, name)
			if name == "ReplicatedStorage" then
				return { Shared = shared }
			elseif name == "MaterialService" then
				return service
			elseif name == "ServerStorage" then
				return storage
			end
			return {}
		end,
	}
	local town = Instance.new("Model")
	town.Name = "Town"
	local terrain = Instance.new("Terrain")
	local fakeWorkspace = {
		DescendantAdded = { Connect = function() end },
		Terrain = terrain,
		GetDescendants = function()
			return town:GetDescendants()
		end,
	}
	local env = { game = fakeGame, workspace = fakeWorkspace, require = function(x)
		return x
	end }
	local UserMaterials = load("src/server/World/UserMaterials.luau", env)
	local MaterialLook = load("src/server/World/Kit/MaterialLook.luau", env)
	return UserMaterials, MaterialLook, { service = service, storage = storage, town = town, terrain = terrain }, shared
end

local function part(parent: any, name: string, material: string, color: Color3): any
	local p = Instance.new("Part")
	p.Name = name
	p.Material = (Enum.Material :: any)[material]
	p.Color = color
	p.Parent = parent
	return p
end

local function overrideOf(service: any, material: string): string
	return service[material .. "Name"]
end

-- Ids de prueba para nuestras texturas (todas)
local OURS: { [string]: string } = {}
do
	local n = 5000
	for _, def in Textures.Variants do
		for _, map in def.Maps do
			n += 1
			OURS[def.Set .. "_" .. map] = "rbxassetid://" .. n
		end
	end
	OURS.Asfalto_wet = "rbxassetid://4999"
end

print("Sin carga no se toca nada")
do
	local UserMaterials, _, w = newModules()
	local road = part(w.town, "Road", "Asphalt", Color3.fromRGB(46, 48, 53))
	local before = w.terrain:GetMaterialColor(Enum.Material.Grass)
	UserMaterials.start(function()
		return nil
	end)
	check(#w.service:GetChildren() == 0 and overrideOf(w.service, "Asphalt") == "Asphalt" and w.service:GetAttribute("UserOverride_Asphalt") == nil, "MaterialService vacío y sin overrides")
	check(road.Color == Color3.fromRGB(46, 48, 53) and w.terrain:GetMaterialColor(Enum.Material.Grass) == before, "ni las piezas ni el terreno cambian de color")
	local _, MaterialLook, w2 = newModules()
	MaterialLook.setup(w2.service, OURS)
	check(overrideOf(w2.service, "Asphalt") == "Asfalto" and overrideOf(w2.service, "Plaster") == "Estuco", "nuestras texturas siguen como siempre (Asfalto, Estuco)")
end

print("Con todos los packs")
local scriptsLeft, renamedOk = 0, true
do
	local UserMaterials, MaterialLook, w = newModules()
	-- Antes, lo nuestro (MaterialLook puede arrancar antes)
	MaterialLook.setup(w.service, OURS)
	local road = part(w.town, "Road", "Asphalt", Color3.fromRGB(46, 48, 53))
	local wall = part(w.town, "Wall", "Plaster", Color3.fromRGB(230, 200, 150))
	local pole = part(w.town, "Pole", "Metal", Color3.fromRGB(58, 62, 68))
	local curb = part(w.town, "Curb", "Concrete", Color3.fromRGB(214, 211, 204))
	local marking = part(w.town, "Marking", "SmoothPlastic", Color3.fromRGB(236, 236, 230))
	local door = part(w.town, "Door", "Wood", Color3.fromRGB(80, 60, 44))
	local lawn = part(w.town, "Lawn", "Grass", Color3.fromRGB(100, 146, 70))
	MaterialLook.assign(w.town, OURS) -- (bordillo -> Granite + Bordillo, marca -> PinturaVial, puerta -> MaderaVeta)
	local grassBefore = w.terrain:GetMaterialColor(Enum.Material.Grass)

	local loaded = {}
	for _, pack in Choice.Packs do
		local asset = fakePack(pack.Id)
		loaded[pack.Short] = UserMaterials.unpack(asset, pack.Short, w.storage)
	end
	-- Biblioteca: scripts, nombres
	local seenNames = {}
	for _, item in w.storage:GetDescendants() do
		if item:IsA("LuaSourceContainer") then
			scriptsLeft += 1
		elseif item:IsA("MaterialVariant") then
			if item.Name:sub(1, 2) ~= "U_" or seenNames[item.Name] or item.Name:find(" ", 1, true) then
				renamedOk = false
			end
			seenNames[item.Name] = true
		end
	end
	check(scriptsLeft == 0, "se borran todos los scripts de los packs")
	check(renamedOk, "cada variant con prefijo U_<pack>_ y sin nombres repetidos")
	local mega = w.storage:FindFirstChild("Mega")
	local megaOk = 0
	for _, v in doc[15221806045] do
		if not Choice.isBroken("Mega", v.Name) then
			megaOk += 1
		end
	end
	check(mega and #mega:GetChildren() == megaOk and megaOk >= 515 and loaded.Mega.Circuitry == nil and loaded.Mega["Smooth Stucco"], ("Mega Pack: %d variants, sin los rotos (los de nombre repetido, con _2)"):format(megaOk))
	check(mega and mega:FindFirstChild("U_Mega_Concrete2") and mega:FindFirstChild("U_Mega_Concrete2_2"), "dos «Concrete 2» en el Mega Pack: U_Mega_Concrete2 y U_Mega_Concrete2_2")
	local grass = w.storage.Cesped:FindFirstChild("U_Cesped_MaterialVariant3")
	check(grass and grass:GetAttribute("SourceName") == "MaterialVariant 3" and grass:GetAttribute("SourcePack") == "Cesped", "el césped 2k se llama U_Cesped_MaterialVariant3 y recuerda su nombre original")

	local applied = UserMaterials.apply(w.service, w.storage, loaded)
	check(#applied == #Choice.Table, ("%d materiales sustituidos (todos los de la tabla)"):format(#applied))
	local allOk = true
	for _, pick in applied do
		local v = w.service:FindFirstChild(pick.VariantName)
		if not v or v.BaseMaterial ~= (Enum.Material :: any)[pick.Material] or overrideOf(w.service, pick.Material) ~= pick.VariantName or w.service:GetAttribute("UserOverride_" .. pick.Material) ~= pick.VariantName then
			allOk = false
			print("     falla " .. pick.Material)
		end
	end
	check(allOk, "cada uno está en MaterialService, sobre su material, puesto como override y apuntado en el atributo")
	check(overrideOf(w.service, "Grass") == "U_Cesped_MaterialVariant3" and w.service.U_Cesped_MaterialVariant3.MaterialPattern == Enum.MaterialPattern.Organic, "césped (piezas y terreno): el 2k del dueño, orgánico")
	-- (en un servidor real no se puede cambiar BaseMaterial a un variant de la Tienda: ganan los que
	-- ya vienen sobre el material bueno)
	local asphalt = w.service:FindFirstChild("U_Real_Asphalt")
	check(asphalt and asphalt.BaseMaterial == Enum.Material.Asphalt and overrideOf(w.service, "Asphalt") == "U_Real_Asphalt" and asphalt.StudsPerTile == 17, "asfalto: el Asphalt del pack de piedras (ya es Asphalt), 17 studs")
	check(overrideOf(w.service, "Pavement") == "U_Mega_StoneTiles" and overrideOf(w.service, "Plaster") == "U_Mega_SmoothStucco" and overrideOf(w.service, "ClayRoofTiles") == "U_Mega_ClayShingles", "acera de losas de piedra, estuco liso y tejas de barro del Mega Pack")
	check(w.storage.Mega:FindFirstChild("U_Mega_RedBricks") ~= nil and w.service:FindFirstChild("U_Mega_RedBricks") == nil, "los no elegidos se quedan en ServerStorage (no se replican)")
	-- Lo nuestro
	check(overrideOf(w.service, "Metal") == "MetalPintado" and overrideOf(w.service, "Granite") == "Bordillo", "el metal pintado y el bordillo de granito siguen siendo nuestros")
	check(w.service:FindFirstChild("Asfalto") ~= nil and w.service:FindFirstChild("PinturaVial") ~= nil, "nuestros variants siguen en MaterialService (pieza a pieza y respaldo)")
	MaterialLook.setup(w.service, OURS) -- (MaterialLook también puede arrancar después)
	check(overrideOf(w.service, "Asphalt") == "U_Real_Asphalt" and overrideOf(w.service, "Grass") == "U_Cesped_MaterialVariant3", "si MaterialLook arranca después, no pisa los del dueño")
	check(curb.MaterialVariant == "Bordillo" and marking.MaterialVariant == "PinturaVial" and door.MaterialVariant == "MaderaVeta", "las piezas con variant nuestro (bordillo, pintura vial, madera de la puerta) no cambian")

	-- Aclarar
	local amounts = UserMaterials.amounts(applied)
	local tinted = UserMaterials.tint(w.town, amounts, nil, w.terrain)
	check(road.Color.R > 0.6 and lawn.Color.R > lawn.Color.G * 0.85, ("asfalto (%.2f) y césped aclarados: manda el color de la textura"):format(road.Color.R))
	check(wall.Color.R > 0.9 and wall.Color.B < 0.7, "fachada de estuco apenas aclarada: sigue de su color")
	check(pole.Color == Color3.fromRGB(58, 62, 68) and curb.Color == Color3.fromRGB(214, 211, 204) and door.Color == Color3.fromRGB(80, 60, 44), "metal y piezas con variant nuestro, sin tocar")
	check(tinted == 3, ("%d piezas aclaradas (asfalto, estuco, césped)"):format(tinted))
	local g = w.terrain:GetMaterialColor(Enum.Material.Grass)
	check(g.R > grassBefore.R + 0.2, "el césped del terreno también se aclara")
	local seen = setmetatable({}, { __mode = "k" })
	UserMaterials.tint(w.town, amounts, seen)
	local r1 = road.Color
	UserMaterials.tint(w.town, amounts, seen)
	check(road.Color == r1, "con la misma lista de vistos no se aclara dos veces")
end

print("Respaldo si falta un pack")
do
	local UserMaterials, _, w = newModules()
	local loaded = {}
	for _, pack in Choice.Packs do
		if pack.Short ~= "Tyler" and pack.Short ~= "Cesped" then
			loaded[pack.Short] = UserMaterials.unpack(fakePack(pack.Id), pack.Short, w.storage)
		end
	end
	UserMaterials.apply(w.service, w.storage, loaded)
	check(overrideOf(w.service, "Asphalt") == "U_Real_Asphalt" and overrideOf(w.service, "Grass") == "U_Real_Grass", "sin Tyler ni el césped 2k: asfalto y césped del pack de piedras")
	check(overrideOf(w.service, "Pavement") == "U_Mega_StoneTiles" and w.service.U_Mega_StoneTiles.BaseMaterial == Enum.Material.Pavement, "acera: losas de piedra del Mega Pack")
end

print("Arranque entero (start) con packs de mentira")
do
	local UserMaterials, _, w = newModules()
	local road = part(w.town, "Road", "Asphalt", Color3.fromRGB(46, 48, 53))
	local ids = {}
	for _, pack in Choice.Packs do
		ids[pack.Id] = true
	end
	UserMaterials.start(function(id)
		return if ids[id] then fakePack(id) else nil
	end)
	check(overrideOf(w.service, "Asphalt") == "U_Real_Asphalt" and road.Color.R > 0.6 and w.storage:FindFirstChild("UserMaterials") ~= nil, "carga, sustituye, aclara y guarda la biblioteca en ServerStorage.UserMaterials")
end

print("Cableado")
do
	local main = fs.readFile("src/server/Main.server.luau")
	check(main:find("World.UserMaterials", 1, true) and main:find("[UserMaterials]", 1, true), "Main arranca UserMaterials en un hilo aparte con pcall")
	check(fs.readFile("src/server/World/Kit/MaterialLook.luau"):find("UserMaterialChoice.attribute", 1, true) ~= nil, "MaterialLook respeta el atributo de los del dueño")
	local src = fs.readFile("src/server/World/UserMaterials.luau")
	check(src:find("LoadAssetAsync", 1, true) and src:find("InsertService:LoadAsset", 1, true), "carga con LoadAssetAsync y, si falla, InsertService")
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Materiales del dueño correctos")
