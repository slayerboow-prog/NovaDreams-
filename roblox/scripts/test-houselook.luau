-- Prueba de las casas y edificios realistas (shared/HouseLook, World/HouseDress) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-houselook.luau                 (packs de mentira y una ciudad de prueba)
--   lune run scripts/test-houselook.luau /tmp/x.rbxl      (además, el mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Los packs de mentira se montan con el contenido real de los docs (docs/assets-usuario.md y
-- docs/assets-usuario-3.md: mismos nombres y BaseMaterial). Comprueba que:
--   * cada aspecto apunta a variants que existen en el doc, con su BaseMaterial, que la pieza puede
--     llevar (mismo material o un cambio seguro), y dice por qué; lo más realista va primero
--   * la elección por parte: estuco, ladrillo, colegio, zócalo, tejas (también las hiladas de
--     CityDetail), contraventanas, madera, hormigón, naves; nunca cristales ni puertas
--   * variedad fija por edificio (2-3 estucos, 2 ladrillos, 2 tejas) y la misma en todo el edificio
--   * en vivo: no se cambia el BaseMaterial de ningún variant, la pieza que cambia de material guarda
--     su física, el color de cada casa se conserva (apenas aclarado), y no se tocan las puertas
--     usables, los cristales, lo que ya lleva variant, los prefabs 3D, los interiores ni los coches
--   * sin carga (o sin un pack) no se hace nada (o se usa el respaldo)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Enum, Color3, Instance, Vector3, CFrame = roblox.Enum, roblox.Color3, roblox.Instance, roblox.Vector3, roblox.CFrame
local V3 = Vector3.new
local rgb = Color3.fromRGB

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
	local e = {
		Enum = Enum,
		Color3 = Color3,
		Instance = Instance,
		Vector3 = Vector3,
		CFrame = CFrame,
		PhysicalProperties = roblox.PhysicalProperties,
		warn = print,
		task = { wait = function() end },
	}
	for k, v in env or {} do
		e[k] = v
	end
	setmetatable(e, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = e })()
end

local HouseLook = load("src/shared/HouseLook.luau")
local Choice = load("src/shared/UserMaterialChoice.luau")

---------------------------------------------------------------------
-- Los docs: id del pack -> { Name, Base }
---------------------------------------------------------------------
local doc: { [number]: { { Name: string, Base: string, Studs: number, Pattern: string } } } = {}
for _, path in { "docs/assets-usuario.md", "docs/assets-usuario-3.md", "docs/assets-usuario-5.md" } do
	local current: number? = nil
	for line in fs.readFile(path):gmatch("[^\n]+") do
		local id = line:match("^#+ (%d+) ") -- (PBR_Textures va con «####» en la 5ª tanda)
		if id then
			current = tonumber(id)
			doc[current :: number] = doc[current :: number] or {}
		elseif line:match("^#") then
			current = nil
		elseif current then
			local name, base, studs, pattern = line:match("^| (.-) | (%a+) | ([%d%.]+) | (%a+) |$")
			if name then
				table.insert(doc[current], { Name = name, Base = base, Studs = tonumber(studs) :: number, Pattern = pattern })
			end
		end
	end
end
local packIds: { [string]: number } = { RPacks = 13752145820 }
for _, pack in Choice.Packs do
	packIds[pack.Short] = pack.Id
end
for _, pack in Choice.ExtraPacks do
	packIds[pack.Short] = pack.Id
end

print("Los aspectos")
do
	check(doc[15221806045] and #doc[15221806045] == 524 and doc[92927007790601] and #doc[92927007790601] == 68, "se leen los packs (Mega 524, Tyler 68)")
	local okRefs, okBase, okUse, okNum, okWhy, okDup = true, true, true, true, true, true
	-- materiales de pieza que pueden llevar cada aspecto (de HouseLook.classify)
	local partMaterials = {
		Estuco = { "Plaster" }, EstucoLiso = { "SmoothPlastic" }, Ladrillo = { "Brick" }, Colegio = { "Plaster", "Brick" },
		Zocalo = { "Cobblestone" }, Teja = { "ClayRoofTiles" }, Contraventana = { "Wood", "WoodPlanks" }, Tablas = { "WoodPlanks" },
		Madera = { "Wood", "WoodPlanks" }, Hormigon = { "Concrete" }, Nave = { "CorrodedMetal" }, NaveTecho = { "Metal" }, NaveHormigon = { "Concrete" },
	}
	for key, look in HouseLook.Looks do
		if type(look.Why) ~= "string" or #look.Why < 10 or look.Variety < 1 or look.Variety > #look.Options then
			okWhy = false
			print("     " .. key)
		end
		if look.Whiten < 0 or look.Whiten > 0.6 then
			okNum = false
		end
		local seen = {}
		for i, cand in look.Options do
			if cand.Find then
				-- (ALL MATERIALS no tiene lista: busca por palabras, solo de respaldo)
				if i <= look.Variety and cand.Pack ~= "PBR" then
					okRefs = false
					print(("     %s: %s busca por palabras dentro de la variedad"):format(key, cand.Pack))
				end
				continue
			end
			local found, count = nil, 0
			for _, v in doc[packIds[cand.Pack] or 0] or {} do
				if v.Name == cand.Name then
					found = found or v
					count += 1
				end
			end
			if count > 1 then
				okDup = false -- (nombres repetidos en el Mega Pack: no se sabe cuál se coge)
			end
			if not found or Choice.isBroken(cand.Pack, cand.Name) then
				okRefs = false
				print(("     %s: %s/%s no está en el doc"):format(key, cand.Pack, cand.Name))
			elseif found.Base ~= cand.From then
				okBase = false
				print(("     %s: %s/%s va sobre %s, no %s"):format(key, cand.Pack, cand.Name, found.Base, cand.From))
			end
			for _, m in partMaterials[key] or { "?" } do
				if not HouseLook.canUse(m, cand.From) then
					okUse = false
					print(("     %s: una pieza de %s no puede llevar un variant de %s"):format(key, m, cand.From))
				end
			end
			seen[cand.Name] = true
		end
	end
	check(okRefs, "cada candidato existe en su doc (pack y nombre) y no es de los rotos")
	check(okBase, "cada candidato dice bien su BaseMaterial del doc")
	check(okDup, "ningún nombre repetido del Mega Pack")
	check(okWhy, "cada aspecto dice por qué y su variedad cabe en la lista")
	check(okNum, "Whiten entre 0 y 0,6")
	local first = {
		Estuco = "Smooth Stucco", Ladrillo = "Red Bricks", Colegio = "Modern Brick", Zocalo = "Chipped Stonework", Teja = "Clay Shingles",
		Contraventana = "Worn Painted Wood Siding", Madera = "Mature Oak", Hormigon = "Fine Particles Concrete", Nave = "Worn Factory Siding",
	}
	local ok = true
	for key, name in first do
		if HouseLook.Looks[key].Options[1].Name ~= name then
			ok = false
			print("     " .. key)
		end
	end
	check(ok, "lo más realista de cada parte va primero (Smooth Stucco, Red Bricks, Modern Brick, Chipped Stonework, Clay Shingles…)")
	check(HouseLook.Looks.Estuco.Variety == 3 and HouseLook.Looks.Ladrillo.Variety == 3 and HouseLook.Looks.Teja.Variety == 3 and HouseLook.Looks.Zocalo.Variety == 3 and HouseLook.Looks.Hormigon.Variety == 3, "variedad: 3 estucos, 3 ladrillos, 3 tejas, 3 zócalos, 3 hormigones")
	local pack = { ["Roof Tiles"] = "ClayRoofTiles", ["Roof"] = "Metal", ["Old Roof Tiles"] = "ClayRoofTiles" }
	check(HouseLook.match({ "roof" }, "ClayRoofTiles", pack) == "Roof Tiles" and HouseLook.match({ "brick" }, "Brick", pack) == nil, "ALL MATERIALS: busca por palabras el más corto sobre su material")
	local onlyNew = HouseLook.candidates("Ladrillo", { PBR = { Brick_PBR = "Brick" }, Todos = { ["Old Brick"] = "Brick", ["Brick Wall"] = "Brick" } })
	check(#onlyNew == 2 and onlyNew[1].Name == "Brick_PBR" and onlyNew[2].Name == "Old Brick", "sin los packs de siempre: ladrillo de PBR_Textures y de ALL MATERIALS")
	check(HouseLook.Looks.Estuco.Whiten <= 0.15, "el estuco casi no aclara: manda el color pastel de cada casa")
	check(HouseLook.canUse("Plaster", "Concrete") and HouseLook.canUse("ClayRoofTiles", "Brick") and not HouseLook.canUse("Glass", "Concrete") and not HouseLook.canUse("Concrete", "Brick"), "cambios de material seguros (estuco Plaster->Concrete, teja->Brick) y nada raro")
end

print("Elección por parte")
do
	local function cl(name: string, material: string, extra: { [string]: any }?): string?
		local info: any = { Name = name, Material = material }
		for k, v in extra or {} do
			info[k] = v
		end
		return HouseLook.classify(info)
	end
	check(cl("Body", "Plaster") == "Estuco" and cl("Wall", "Plaster") == "Estuco" and cl("GableWall", "Plaster") == "Estuco" and cl("Trim", "Plaster") == "Estuco", "fachadas encaladas: estuco (también hastiales e impostas del mismo material)")
	check(cl("Body", "Brick") == "Ladrillo" and cl("Chimney", "Brick") == "Ladrillo", "ladrillo visto")
	check(cl("Wall", "Plaster", { Kind = "Colegio" }) == "Colegio" and cl("Wall", "Brick", { Kind = "Colegio" }) == "Colegio", "colegio: ladrillo cara vista")
	check(cl("Plinth", "Cobblestone") == "Zocalo" and cl("StonePlinth", "Cobblestone") == "Zocalo" and cl("Plinth", "Concrete") == nil, "zócalos de piedra (el de hormigón de la casa moderna no)")
	check(cl("Roof", "ClayRoofTiles") == "Teja" and cl("RoofTiles", "ClayRoofTiles") == "Teja" and cl("RidgeTiles", "ClayRoofTiles") == "Teja" and cl("PorchRoof", "ClayRoofTiles") == "Teja", "tejados de teja y las hiladas de CityDetail")
	check(cl("Roof", "Slate") == nil and cl("Roof", "Concrete") == nil and cl("Roof", "Metal") == nil, "pizarra, azoteas y tejados de metal (fuera de las naves): no")
	check(cl("Shutter", "WoodPlanks") == "Contraventana" and cl("Shutter", "Wood") == "Contraventana" and cl("Verge", "Wood") == "Madera" and cl("PorchPost", "Wood") == "Madera", "contraventanas y maderas")
	check(cl("Body", "SmoothPlastic", { Style = "Moderna" }) == "EstucoLiso" and cl("Body", "SmoothPlastic") == nil, "casas modernas: enfoscado liso (el plástico de lo demás, como los coches, no)")
	check(cl("Body", "WoodPlanks", { Style = "Colonial" }) == "Tablas" and cl("Cladding", "WoodPlanks", { Style = "Colonial" }) == "Madera", "casas coloniales de tablas")
	check(cl("Wall", "Concrete") == "Hormigon" and cl("Hall", "CorrodedMetal", { Kind = "Nave" }) == "Nave" and cl("Roof", "Metal", { Kind = "Nave" }) == "NaveTecho" and cl("Dock", "Concrete", { Kind = "Nave" }) == "NaveHormigon", "edificios públicos de hormigón y naves")
	local never = true
	for _, n in { "Door", "DoorPanel", "DoorFrame", "DoorKnob", "GarageDoor", "RollerDoor", "WindowGlass", "Glass", "Windows", "WindowFrame", "Sill", "Railing", "Sign", "Partition", "LowWall", "Floor", "Ceiling" } do
		for _, m in { "Plaster", "Wood", "Brick", "Concrete", "Glass", "ClayRoofTiles" } do
			if cl(n, m) then
				never = false
				print("     " .. n .. " " .. m)
			end
		end
	end
	check(never, "nunca: puertas, cristales, marcos, alféizares, barandillas, carteles, tabiques, suelos")
	check(cl("Body", "Glass") == nil and cl("Body", "Neon") == nil, "cristal y neón: no")
	check(cl("Body", "Plaster", { Variant = "MaderaVeta" }) == nil and cl("Body", "Plaster", { Transparency = 1 }) == nil and cl("Body", "Plaster", { Y = 6000 }) == nil and cl("Body", "Plaster", { Skip = true }) == nil, "lo que ya lleva variant, lo invisible, los interiores del cielo y los prefabs 3D: no")
	-- Variedad determinista
	local seenE, same = {}, true
	for i = 1, 200 do
		local x, z = i * 37.3, -i * 91.1
		local k = HouseLook.pick("Estuco", 3, x, z)
		seenE[k] = (seenE[k] or 0) + 1
		if HouseLook.pick("Estuco", 3, x, z) ~= k or HouseLook.pick("Estuco", 3, x + 0.01, z) ~= k then
			same = false
		end
	end
	check(seenE[1] and seenE[2] and seenE[3] and seenE[1] > 30 and seenE[2] > 30 and seenE[3] > 30, ("los 3 estucos se reparten (%d/%d/%d de 200 casas)"):format(seenE[1] or 0, seenE[2] or 0, seenE[3] or 0))
	check(same, "siempre el mismo para la misma casa")
	local clay = 0
	for i = 1, 300 do
		if HouseLook.pick("Teja", 2, i * 13.7, i * 7.9) == 1 then
			clay += 1
		end
	end
	check(clay > 160 and clay < 240, ("tejas: Clay Shingles en unas 2/3 de las casas (%d de 300)"):format(clay))
end

---------------------------------------------------------------------
-- Packs de mentira y módulos del servidor
---------------------------------------------------------------------
local function fakeVariantPack(id: number): any
	local model = Instance.new("Model")
	local folder = Instance.new("Folder")
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
	s.Parent = folder
	return model
end

local function newModules(): (any, any, any)
	local service = Instance.new("MaterialService")
	local storage = Instance.new("Folder")
	local shared = { UserMaterialChoice = Choice, HouseLook = HouseLook, Textures = {}, TextureIds = {} }
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
	local env = { game = fakeGame, workspace = { DescendantAdded = { Connect = function() end }, Terrain = Instance.new("Terrain"), GetDescendants = function()
		return {}
	end, FindFirstChild = function()
		return nil
	end }, require = function(x)
		return x
	end }
	local UserMaterials = load("src/server/World/UserMaterials.luau", env)
	local HouseDress = load("src/server/World/HouseDress.luau", env)
	return UserMaterials, HouseDress, { service = service, storage = storage }
end

local function part(parent: any, name: string, material: string, pos: any, color: any?, class: string?): any
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Material = (Enum.Material :: any)[material]
	p.Color = color or rgb(200, 200, 200)
	p.Size = V3(4, 4, 1)
	p.CFrame = CFrame.new(pos)
	p.Parent = parent
	return p
end

local function model(parent: any, name: string, class: string?): any
	local f = Instance.new(class or "Model")
	f.Name = name
	f.Parent = parent
	return f
end

local PASTEL = { rgb(212, 132, 96), rgb(224, 176, 96), rgb(170, 196, 212), rgb(236, 214, 150), rgb(246, 242, 232) }

-- Casa como las de Kit/HouseKit (con hiladas de CityDetail)
local function house(parent: any, at: any, style: string, wallMat: string, color: any): any
	local m = model(parent, "Casa")
	m:SetAttribute("Style", style)
	local h = {
		model = m,
		body = part(m, "Body", wallMat, at + V3(0, 5, 0), color),
		roof = part(m, "Roof", "ClayRoofTiles", at + V3(0, 12, -3), rgb(176, 84, 52), "WedgePart"),
		tiles = part(m, "RoofTiles", "ClayRoofTiles", at + V3(0, 12.3, -3), rgb(160, 76, 50)),
		ridge = part(m, "Ridge", "ClayRoofTiles", at + V3(0, 14, 0), rgb(130, 60, 40)),
		plinth = part(m, "Plinth", "Cobblestone", at + V3(0, 0.7, 0), rgb(190, 176, 150)),
		gable = part(m, "GableWall", wallMat, at + V3(8, 12, 0), color),
		shutter = part(m, "Shutter", "WoodPlanks", at + V3(3, 4, -6), rgb(40, 110, 80)),
		verge = part(m, "Verge", "Wood", at + V3(8, 12.5, -3), rgb(236, 230, 214)),
		door = part(m, "Door", "Wood", at + V3(-2, 3.9, -6), rgb(40, 110, 80)),
		doorPanel = part(m, "DoorPanel", "Wood", at + V3(-2, 3.9, -6.2), rgb(34, 94, 68)),
		frame = part(m, "WindowFrame", "SmoothPlastic", at + V3(3, 4, -6), rgb(236, 230, 214)),
		glass = part(m, "WindowGlass", "Glass", at + V3(3, 4, -6.1), rgb(70, 96, 120)),
		veta = part(m, "Shutter", "Wood", at + V3(-3, 4, -6), rgb(40, 110, 80)),
	}
	h.tiles:AddTag("CityDetail")
	h.door:SetAttribute("DoorOut", V3(0, 0, -1))
	h.veta.MaterialVariant = "MaderaVeta"
	return h
end

local function buildTown(): any
	local town = model(nil, "Town", "Folder")
	local barrio = model(town, "Manzana_Casas")
	local w: any = { town = town, houses = {} }
	for i = 1, 60 do
		local at = V3(-2000 + i * 61.7, 0, 400 + (i % 7) * 53.3)
		table.insert(w.houses, house(barrio, at, "Mediterranea", "Plaster", PASTEL[(i % #PASTEL) + 1]))
	end
	for i = 1, 30 do
		table.insert(w.houses, house(barrio, V3(1000 + i * 47.9, 0, -300 - (i % 5) * 61.1), "Ladrillo", "Brick", rgb(170, 90, 70)))
	end
	w.moderna = house(barrio, V3(50, 0, 50), "Moderna", "SmoothPlastic", rgb(242, 242, 240))
	w.colonial = house(barrio, V3(150, 0, 50), "Colonial", "WoodPlanks", rgb(200, 216, 232))
	-- Colegio (Kit/Civic.school -> Kit/Building)
	local colegio = model(model(town, "Manzana_Colegio"), "Colegio")
	local edificio = model(colegio, "Edificio")
	w.schoolWall = part(edificio, "Wall", "Plaster", V3(500, 6, 500), rgb(196, 112, 84))
	w.schoolGlass = part(edificio, "Glass", "Glass", V3(500, 6, 499), rgb(52, 70, 84))
	w.schoolTrim = part(edificio, "Trim", "Limestone", V3(500, 1, 499), rgb(246, 242, 232))
	w.schoolPartition = part(edificio, "Partition", "Plaster", V3(505, 6, 505), rgb(240, 240, 236))
	-- Hospital de hormigón
	local hospital = model(model(town, "Manzana_Civica"), "Hospital")
	w.hospitalWall = part(model(hospital, "Edificio"), "Wall", "Concrete", V3(800, 6, 800), rgb(240, 242, 244))
	-- Nave
	local nave = model(model(town, "Manzana_Industria"), "Nave")
	w.hall = part(nave, "Hall", "CorrodedMetal", V3(-800, 10, -800), rgb(170, 180, 190))
	w.naveRoof = part(nave, "Roof", "Metal", V3(-800, 22, -800), rgb(90, 96, 104))
	w.dock = part(nave, "Dock", "Concrete", V3(-800, 1.5, -760), rgb(150, 150, 146))
	w.roller = part(nave, "RollerDoor", "DiamondPlate", V3(-800, 6, -770), rgb(70, 80, 92))
	-- Bloque ya cambiado por un prefab 3D (World/Buildings3D)
	local bloque = model(model(town, "Manzana_Pisos"), "Bloque")
	bloque:SetAttribute("Prefab3D", "A")
	w.prefabBody = part(bloque, "Body", "Plaster", V3(300, 10, -300), rgb(232, 214, 184))
	w.prefabMesh = part(model(bloque, "Prefab3D_A"), "Wall", "Brick", V3(300, 10, -300), rgb(200, 200, 200), "MeshPart")
	w.prefabMesh:AddTag("BuildingMesh")
	w.shell = part(model(town, "Otro"), "Body", "Plaster", V3(320, 10, -300), rgb(232, 214, 184))
	w.shell:AddTag("BuildingShell")
	-- Coche aparcado (Body de plástico liso)
	w.carBody = part(model(barrio, "Car"), "Body", "SmoothPlastic", V3(20, 2, 20), rgb(170, 30, 36))
	w.carRoof = part(model(barrio, "Car"), "Roof", "SmoothPlastic", V3(20, 3, 20), rgb(170, 30, 36))
	-- Interiores: sala en el cielo y carpeta de interiores
	w.skyWall = part(model(town, "Sala"), "Wall", "Plaster", V3(0, 6000, 0), rgb(240, 236, 228))
	w.interiorWall = part(model(model(town, "Interiores", "Folder"), "Casa"), "Wall", "Plaster", V3(10, 10, 10), rgb(240, 236, 228))
	-- Caja invisible
	w.invisible = part(model(town, "Caja"), "Wall", "Plaster", V3(30, 5, 30), rgb(240, 236, 228))
	w.invisible.Transparency = 1
	return w
end

local function snapshot(p: any): any
	return { Material = p.Material, Variant = p.MaterialVariant, Color = p.Color }
end
local function same(p: any, s: any): boolean
	return p.Material == s.Material and p.MaterialVariant == s.Variant and p.Color == s.Color
end

local function allVariants(service: any, storage: any): { [any]: any }
	local out = {}
	for _, root in { service, storage } do
		for _, item in root:GetDescendants() do
			if item:IsA("MaterialVariant") then
				out[item] = item.BaseMaterial
			end
		end
	end
	return out
end

-- Carga los packs (los que diga skip, no) como lo hace el servidor. En un servidor real los overrides
-- globales que cambian el BaseMaterial (estuco, teja) fallan: aquí, por defecto, solo se ponen los que
-- ya vienen sobre su material (como allí). studio = true: se ponen todos (como en Studio/Lune).
local function loadPacks(UserMaterials: any, w: any, skip: { [string]: boolean }?, studio: boolean?)
	local loaded = {}
	for _, pack in Choice.Packs do
		if not (skip and skip[pack.Short]) and doc[pack.Id] and #doc[pack.Id] > 0 then
			loaded[pack.Short] = UserMaterials.unpack(fakeVariantPack(pack.Id), pack.Short, w.storage)
		end
	end
	if studio then
		UserMaterials.apply(w.service, w.storage, loaded)
		return
	end
	local real = {}
	for short, names in loaded do
		real[short] = {}
		for name in names do
			local folder = w.storage:FindFirstChild(short)
			for _, v in if folder then folder:GetChildren() else {} do
				if v:GetAttribute("SourceName") == name then
					real[short][name] = v.BaseMaterial.Name
					break
				end
			end
		end
	end
	-- (los candidatos que van sobre otro material, fuera: no se pueden poner)
	local saved = Choice.Table
	local only = {}
	for _, choice in saved do
		local copy = table.clone(choice)
		copy.Candidates = {}
		for _, cand in choice.Candidates do
			if cand.From == choice.Material then
				table.insert(copy.Candidates, cand)
			end
		end
		table.insert(only, copy)
	end
	Choice.Table = only
	UserMaterials.apply(w.service, w.storage, loaded)
	Choice.Table = saved
end

print("Sin carga no se hace nada")
do
	local UserMaterials, HouseDress, w = newModules()
	local t = buildTown()
	local before = snapshot(t.houses[1].body)
	UserMaterials.start(function()
		return nil
	end)
	HouseDress.start(w.service, w.storage, t.town)
	local untouched = true
	for _, d in t.town:GetDescendants() do
		if d:IsA("BasePart") and d.MaterialVariant ~= "" and d.MaterialVariant ~= "MaderaVeta" then
			untouched = false
		end
	end
	check(untouched and same(t.houses[1].body, before) and #w.service:GetChildren() == 0, "sin packs: ni variants ni piezas tocadas")
end

local function variantOf(w: any, p: any): any
	return w.service:FindFirstChild(p.MaterialVariant)
end
local function source(w: any, p: any): string?
	local v = variantOf(w, p)
	return v and v:GetAttribute("SourceName")
end

local first: { [number]: { [string]: string? } } = {}

print("Con todos los packs")
do
	local UserMaterials, HouseDress, w = newModules()
	local t = buildTown()
	loadPacks(UserMaterials, w)
	local before = allVariants(w.service, w.storage)
	local snaps = {}
	for _, d in t.town:GetDescendants() do
		if d:IsA("BasePart") then
			snaps[d] = snapshot(d)
		end
	end
	local resolved = HouseDress.resolve(w.service, w.storage)
	local counts = HouseDress.dress(t.town, resolved)
	local after = allVariants(w.service, w.storage)
	local okBase = true
	for v, base in after do
		if before[v] ~= nil and before[v] ~= base then
			okBase = false
		end
	end
	check(okBase, "no cambia el BaseMaterial de ningún variant (en un servidor real falla)")
	check(#resolved.Estuco == 3 and #resolved.Ladrillo == 3 and #resolved.Teja == 3 and #resolved.Zocalo == 3 and #resolved.Colegio == 1, "variedad cargada: 3 estucos, 3 ladrillos, 3 tejas, 3 piedras de zócalo, 1 ladrillo de colegio")
	local list = {}
	for key, n in counts do
		table.insert(list, key .. " " .. n)
	end
	table.sort(list)
	print("     " .. table.concat(list, ", "))

	-- Cada casa: todas sus piezas con lo que les toca, y la misma elección en toda la casa
	local okParts, okWhole, okPhys, okColor, okKeep = true, true, true, true, true
	local estucos, ladrillos, tejas = {}, {}, {}
	local plaster = roblox.PhysicalProperties.new(Enum.Material.Plaster)
	for i, h in t.houses do
		local isBrick = h.model:GetAttribute("Style") == "Ladrillo"
		local wallSrc, roofSrc = source(w, h.body), source(w, h.roof)
		first[i] = { wall = wallSrc, roof = roofSrc, plinth = source(w, h.plinth) }
		if isBrick then
			ladrillos[wallSrc or "?"] = true
			if h.body.Material ~= Enum.Material.Brick or not (wallSrc == "Red Bricks" or wallSrc == "Realistic Bricks" or wallSrc == "RealisticBricks") then
				okParts = false
			end
		else
			estucos[wallSrc or "?"] = true
			if h.body.Material ~= Enum.Material.Concrete or not (wallSrc and wallSrc:find("Stucco")) then
				okParts = false
			end
			local phys = h.body.CustomPhysicalProperties
			if not phys or math.abs(phys.Density - plaster.Density) > 1e-3 or math.abs(phys.Friction - plaster.Friction) > 1e-3 then
				okPhys = false
			end
		end
		tejas[roofSrc or "?"] = true
		if source(w, h.gable) ~= wallSrc or source(w, h.tiles) ~= roofSrc or source(w, h.ridge) ~= roofSrc then
			okWhole = false
		end
		if not (roofSrc == "Clay Shingles" or roofSrc == "Roof1" or roofSrc == "Roof2") or not (source(w, h.plinth) == "Chipped Stonework" or source(w, h.plinth) == "Stone Block Wall" or source(w, h.plinth) == "Chisled Cobble") then
			okParts = false
		end
		if source(w, h.shutter) ~= "Worn Painted Wood Siding" or not (source(w, h.verge) == "Mature Oak" or source(w, h.verge) == "Oak" or source(w, h.verge) == "Realistic Wood") then
			okParts = false
		end
		-- Color: el de la casa, apenas aclarado (mismo tono)
		local c0, c1 = snaps[h.body].Color, h.body.Color
		local amount = if isBrick then 0.45 else 0.1
		local want = c0:Lerp(Color3.new(1, 1, 1), amount)
		if math.abs(c1.R - want.R) > 1e-3 or math.abs(c1.G - want.G) > 1e-3 or math.abs(c1.B - want.B) > 1e-3 then
			okColor = false
		end
		if (c0.R > c0.B) ~= (c1.R > c1.B) or (c0.G > c0.B) ~= (c1.G > c1.B) then
			okColor = false
		end
		-- Lo que no se toca
		for _, k in { "door", "doorPanel", "frame", "glass", "veta" } do
			if not same(h[k], snaps[h[k]]) then
				okKeep = false
			end
		end
	end
	local function n(set: any): number
		local c = 0
		for _ in set do
			c += 1
		end
		return c
	end
	check(okParts, "cada parte con lo suyo: estuco (pasa a Concrete), ladrillo, teja, piedra de zócalo, contraventana de tablas, madera de roble")
	check(okWhole, "la misma elección en toda la casa (hastiales con su pared; faldones, hiladas y cumbrera con la misma teja)")
	check(n(estucos) == 3 and n(ladrillos) >= 2 and n(tejas) == 3, ("variedad entre casas: %d estucos, %d ladrillos, %d tejas"):format(n(estucos), n(ladrillos), n(tejas)))
	check(okPhys, "las paredes que cambian de material guardan la física del estuco")
	check(okColor, "cada casa conserva su color (estuco aclarado un 10 %, ladrillo un 45 %; mismo tono)")
	check(okKeep, "puertas usables (Door, DoorPanel), marcos, cristales y la madera con veta: sin tocar")
	check(t.houses[1].door:GetAttribute("DoorOut") ~= nil, "la puerta sigue con su salida (InteriorService)")
	check(source(w, t.moderna.body) == "Smooth Stucco" and t.moderna.body.Material == Enum.Material.Concrete, "casa moderna: enfoscado liso")
	check(source(w, t.colonial.body) == "Worn Painted Wood Siding", "casa colonial: tablas pintadas")
	check(source(w, t.schoolWall) == "Modern Brick" and t.schoolWall.Material == Enum.Material.Brick and same(t.schoolGlass, snaps[t.schoolGlass]), "colegio: ladrillo cara vista (pasa a Brick); sus cristales sin tocar")
	check(same(t.schoolPartition, snaps[t.schoolPartition]) and t.schoolTrim.MaterialVariant == "", "tabiques del colegio y piedra caliza (ya es del dueño) sin tocar")
	check(source(w, t.hospitalWall) == "Fine Particles Concrete" or source(w, t.hospitalWall) == "Concrete 1" or source(w, t.hospitalWall) == "Concrete", "hospital: hormigón (fino, liso o el del pack de piedras)")
	check(source(w, t.hall) == "Worn Factory Siding" or source(w, t.hall) == "Rigid Metal Siding", "nave: chapa de fábrica (pasa a Metal)")
	check(source(w, t.naveRoof) == "Rigid Metal Siding" and source(w, t.dock) == "Concrete IndustrialGrittySturdyMaterial" and same(t.roller, snaps[t.roller]), "nave: cubierta de chapa, muelle de hormigón, persianas sin tocar")
	check(same(t.prefabBody, snaps[t.prefabBody]) and same(t.prefabMesh, snaps[t.prefabMesh]) and same(t.shell, snaps[t.shell]), "edificios con prefab 3D (y sus mallas y cajas): sin tocar")
	check(same(t.carBody, snaps[t.carBody]) and same(t.carRoof, snaps[t.carRoof]), "coches: sin tocar")
	check(same(t.skyWall, snaps[t.skyWall]) and same(t.interiorWall, snaps[t.interiorWall]) and same(t.invisible, snaps[t.invisible]), "interiores (en el cielo y en la carpeta Interiores) y cajas invisibles: sin tocar")
	local added = 0
	for _, d in t.town:GetDescendants() do
		if d:IsA("BasePart") and not snaps[d] then
			added += 1
		end
	end
	check(added == 0, "no añade ni una pieza (gráficos Bajo: igual que antes)")
	-- Otra vez sobre lo ya vestido: nada cambia
	local again = HouseDress.dress(t.town, resolved)
	check(next(again) == nil, "repasar lo ya vestido no lo vuelve a aclarar")
end

print("Determinista")
do
	local UserMaterials, HouseDress, w = newModules()
	local t = buildTown()
	loadPacks(UserMaterials, w)
	HouseDress.dress(t.town, HouseDress.resolve(w.service, w.storage))
	local ok = true
	for i, h in t.houses do
		local f = first[i]
		if not f or f.wall ~= source(w, h.body) or f.roof ~= source(w, h.roof) or f.plinth ~= source(w, h.plinth) then
			ok = false
		end
	end
	check(ok, "otro servidor, mismo mapa: cada casa con el mismo estuco, ladrillo, teja y zócalo")
end

print("Con los overrides globales puestos (como en Studio)")
do
	local UserMaterials, HouseDress, w = newModules()
	local t = buildTown()
	loadPacks(UserMaterials, w, nil, true)
	HouseDress.dress(t.town, HouseDress.resolve(w.service, w.storage))
	local h = t.houses[1]
	local roofs = {}
	for _, x in t.houses do
		roofs[source(w, x.roof) or "?"] = true
	end
	check(roofs["Clay Shingles"] and h.roof.MaterialVariant ~= "" and (h.roof.Material == Enum.Material.ClayRoofTiles or h.roof.Material == Enum.Material.CeramicTiles), "si el override de la teja sí se pudo poner, la teja la lleva igual sin cambiar de material")
	check(source(w, h.body) ~= nil and source(w, h.body):find("Stucco") ~= nil, "y el estuco también")
end

print("Sin el Mega Pack: respaldos")
do
	local UserMaterials, HouseDress, w = newModules()
	local t = buildTown()
	loadPacks(UserMaterials, w, { Mega = true })
	local snapBody = snapshot(t.houses[1].body)
	HouseDress.dress(t.town, HouseDress.resolve(w.service, w.storage))
	check(same(t.houses[1].body, snapBody), "sin estucos cargados, la fachada encalada se queda como estaba")
	local r1 = source(w, t.houses[1].roof)
	check((r1 == "Roof1" or r1 == "Roof2") and t.houses[1].roof.Material == Enum.Material.CeramicTiles, "tejas: Roof1/Roof2 de Tyler (pasa a CeramicTiles)")
	local brick = t.houses[61]
	local b1 = source(w, brick.body)
	check(b1 == "Realistic Bricks" or b1 == "RealisticBricks", "ladrillo: los de los packs de madera y del generador")
	check(source(w, t.schoolWall) == "Realistic Bricks", "colegio: el ladrillo de respaldo")
end

print("Cableado")
do
	local um = fs.readFile("src/server/World/UserMaterials.luau")
	local a, b, c = um:find("pcall(dress", 1, true), um:find('FindFirstChild("HouseDress")', 1, true), um:find("UserMaterials.tint(workspace", 1, true)
	check(a and b and c and a < b and b < c, "UserMaterials viste los edificios con pcall, después de las calles y antes de aclarar")
	local hd = fs.readFile("src/server/World/HouseDress.luau")
	check(hd:find("Prefab3D", 1, true) and hd:find("BuildingShell", 1, true) and hd:find("BuildingMesh", 1, true), "HouseDress se salta los prefabs 3D")
	check(not hd:find("BaseMaterial =", 1, true), "HouseDress nunca cambia el BaseMaterial de un variant")
end

---------------------------------------------------------------------
-- El mapa construido (opcional)
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("Mapa construido: " .. placePath)
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local town = place:GetService("Workspace"):FindFirstChild("Town")
	check(town ~= nil, "hay Town")
	if town then
		local UserMaterials, HouseDress, w = newModules()
		loadPacks(UserMaterials, w)
		local snaps = {}
		local parts = 0
		for _, d in town:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				if Choice and (d.Material == Enum.Material.Glass or string.find(d.Name, "Door", 1, true) or d.MaterialVariant ~= "") then
					snaps[d] = snapshot(d)
				end
			end
		end
		local counts, byVariant = HouseDress.dress(town, HouseDress.resolve(w.service, w.storage))
		local total, list = 0, {}
		for key, n in counts do
			total += n
			table.insert(list, ("%s %d"):format(key, n))
		end
		table.sort(list)
		print(("     %d piezas en Town; vestidas %d: %s"):format(parts, total, table.concat(list, ", ")))
		local vlist = {}
		for name, n in byVariant do
			table.insert(vlist, ("%s %d"):format(name, n))
		end
		table.sort(vlist)
		print("     " .. table.concat(vlist, ", "))
		check((counts.Estuco or 0) > 100 and (counts.Teja or 0) > 100 and (counts.Ladrillo or 0) > 20 and (counts.Zocalo or 0) > 50, "en el mapa: fachadas encaladas, tejas, ladrillo y zócalos vestidos")
		check((counts.Colegio or 0) > 0 and (counts.Nave or 0) > 0, "en el mapa: el colegio y las naves")
		local kept = true
		for d, s in snaps do
			if not same(d, s) then
				kept = false
				print("     tocada: " .. d:GetFullName())
				break
			end
		end
		check(kept, "en el mapa: ningún cristal, puerta ni pieza con variant propio cambia")
		check(total < parts * 0.5, "en el mapa: solo piezas de edificio (menos de la mitad de la ciudad)")
	end
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Casas y edificios realistas correctos")
