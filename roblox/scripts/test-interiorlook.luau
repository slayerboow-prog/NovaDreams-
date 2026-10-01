-- Prueba de los interiores realistas (shared/InteriorLook, World/InteriorDress) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-interiorlook.luau                 (packs de mentira y salas de verdad de World/Interiors)
--   lune run scripts/test-interiorlook.luau /tmp/x.rbxl      (además, las plantas bajas del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Los packs de mentira se montan con el contenido real de los docs (docs/assets-usuario.md y -3: mismos
-- nombres y BaseMaterial); Duvall Drive y Modern City (sin lista en los docs) con nombres verosímiles.
-- Comprueba que:
--   * cada aspecto apunta a variants que existen en el doc, con su BaseMaterial, que la pieza puede
--     llevar, con su escala de interior y su porqué
--   * la elección por estancia y por pieza: suelo, pared, techo, encimera, rodapié, escalón
--   * variedad fija por vivienda/local (y distinta entre viviendas)
--   * en vivo, con las salas de verdad de World/Interiors: no se cambia el BaseMaterial ni la escala de
--     ningún variant de los packs (se usan copias), el color se conserva (apenas aclarado), la física
--     de antes, y no se tocan cristales, puertas, luces, muebles ni lo que ya lleva variant
--   * las salas que se montan luego (onBuilt) se visten al momento
--   * sin carga no se hace nada

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
		typeof = typeof,
		warn = print,
		task = { wait = function() end },
	}
	for k, v in env or {} do
		e[k] = v
	end
	setmetatable(e, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = e })()
end

local InteriorLook = load("src/shared/InteriorLook.luau")
local Choice = load("src/shared/UserMaterialChoice.luau")

---------------------------------------------------------------------
-- Los docs: id del pack -> { Name, Base }
---------------------------------------------------------------------
local doc: { [number]: { { Name: string, Base: string, Studs: number, Pattern: string } } } = {}
for _, path in { "docs/assets-usuario.md", "docs/assets-usuario-3.md" } do
	local current: number? = nil
	for line in fs.readFile(path):gmatch("[^\n]+") do
		local id = line:match("^## (%d+) ")
		if id then
			current = tonumber(id)
			doc[current :: number] = doc[current :: number] or {}
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
-- Duvall Drive y Modern City: los docs solo dicen algunos nombres (modelos-oficiales-2.md); estos son
-- de mentira pero verosímiles (y la prueba también mira qué pasa si no están)
doc[10841357434] = {
	{ Name = "Wood Floor", Base = "WoodPlanks", Studs = 10, Pattern = "Regular" },
	{ Name = "Wallpaper", Base = "Fabric", Studs = 10, Pattern = "Regular" },
	{ Name = "Flagstone", Base = "Slate", Studs = 10, Pattern = "Regular" },
	{ Name = "Gravel", Base = "Pebble", Studs = 10, Pattern = "Organic" },
}
doc[13168345645] = {
	{ Name = "Plaster_A", Base = "Concrete", Studs = 10, Pattern = "Regular" },
	{ Name = "PaintedBrick", Base = "Brick", Studs = 10, Pattern = "Regular" },
	{ Name = "Sidewalk_A", Base = "Pavement", Studs = 10, Pattern = "Regular" },
	{ Name = "CarPaint_A", Base = "Metal", Studs = 10, Pattern = "Regular" },
}
local packIds: { [string]: number } = { RPacks = 13752145820 }
for _, pack in Choice.Packs do
	packIds[pack.Short] = pack.Id
end
for _, pack in InteriorLook.Packs do
	packIds[pack.Short] = pack.Id
end

print("Los aspectos")
do
	check(doc[15221806045] and #doc[15221806045] == 524 and doc[13752145820] and #doc[13752145820] == 27, "se leen los packs (Mega 524, Realistic Packs 27)")
	-- materiales de pieza que llevan cada aspecto (de InteriorLook.classify y las salas de World/Interiors)
	local partMaterials = {
		Parquet = { "WoodPlanks" }, Peldano = { "WoodPlanks" }, BaldosaCocina = { "CeramicTiles" }, BaldosaBano = { "CeramicTiles", "Marble" },
		BaldosaLocal = { "Marble", "CeramicTiles" }, Terrazo = { "Marble", "Concrete" }, Marmol = { "Marble" }, Linoleo = { "WoodPlanks", "CeramicTiles", "SmoothPlastic" },
		Moqueta = { "Carpet" }, MoquetaCine = { "Carpet" }, Hormigon = { "Concrete" }, Pizarra = { "Slate" }, GranitoSuelo = { "Granite" },
		Pintura = { "SmoothPlastic", "Plaster" }, PapelPintado = { "SmoothPlastic", "Plaster" }, Azulejo = { "CeramicTiles" }, LadrilloVisto = { "SmoothPlastic" },
		LadrilloPintado = { "SmoothPlastic" }, Yeso = { "SmoothPlastic", "Plaster" }, Placas = { "SmoothPlastic", "Plaster" },
		EncimeraGranito = { "Granite", "Slate" }, EncimeraMarmol = { "Marble" }, EncimeraMadera = { "Wood" }, Rodapie = { "SmoothPlastic" },
	}
	local okRefs, okBase, okUse, okDup, okWhy, okNum = true, true, true, true, true, true
	for key, look in InteriorLook.Looks do
		if type(look.Why) ~= "string" or #look.Why < 10 or look.Variety < 1 or look.Variety > #look.Options or not partMaterials[key] then
			okWhy = false
			print("     " .. key)
		end
		if look.Whiten < 0 or look.Whiten > 0.6 or look.Studs < 3 or look.Studs > 12 then
			okNum = false
			print("     " .. key .. " escala/aclarado")
		end
		for _, cand in look.Options do
			if cand.Name and cand.Pack ~= "Duvall" and cand.Pack ~= "MCity" then
				local found, count = nil, 0
				for _, v in doc[packIds[cand.Pack] or 0] or {} do
					if v.Name == cand.Name then
						found = found or v
						count += 1
					end
				end
				if count > 1 then
					okDup = false
					print(("     %s: %s/%s está repetido"):format(key, cand.Pack, cand.Name))
				end
				if not found or Choice.isBroken(cand.Pack, cand.Name) then
					okRefs = false
					print(("     %s: %s/%s no está en el doc"):format(key, cand.Pack, cand.Name))
				elseif found.Base ~= cand.From then
					okBase = false
					print(("     %s: %s/%s va sobre %s, no %s"):format(key, cand.Pack, cand.Name, found.Base, tostring(cand.From)))
				else
					for _, m in partMaterials[key] or {} do
						if not InteriorLook.canUse(m, found.Base) then
							okUse = false
							print(("     %s: una pieza de %s no puede llevar %s (%s)"):format(key, m, cand.Name, found.Base))
						end
					end
				end
			elseif not cand.Name and not cand.Find then
				okRefs = false
			end
		end
	end
	check(okRefs, "cada candidato existe en su doc (pack y nombre) y no es de los rotos (o busca por palabras)")
	check(okBase, "cada candidato dice bien su BaseMaterial del doc")
	check(okUse, "las piezas de cada aspecto pueden llevar sus variants (mismo material o cambio seguro)")
	check(okDup, "ningún nombre repetido del Mega Pack")
	check(okWhy, "cada aspecto dice por qué y su variedad cabe en la lista")
	check(okNum, "escala de interior (3-12 studs) y aclarado entre 0 y 0,6")
	local L = InteriorLook.Looks
	check(L.Parquet.Studs <= 6 and L.BaldosaBano.Studs <= 5 and L.Azulejo.Studs <= 4 and L.Marmol.Studs <= 8, "nada gigante: tarima 6, baldosa de baño 4, azulejo 4, mármol 8 studs")
	check(L.Pintura.Whiten <= 0.1 and L.Yeso.Whiten <= 0.1, "paredes y techos casi no aclaran: manda su color")
	check(not InteriorLook.canUse("Glass", "Concrete") and not InteriorLook.canUse("Neon", "Plastic") and not InteriorLook.canUse("Metal", "Concrete") and InteriorLook.canUse("SmoothPlastic", "Concrete") and InteriorLook.canUse("Carpet", "Fabric"), "cambios de material seguros (plástico pintado -> enlucido, moqueta -> tejido), nunca cristal, neón ni metal")
	-- Búsqueda por palabras (Duvall Drive, Modern City)
	local pack = { ["Wood Floor"] = "WoodPlanks", ["Dark Wood Floor Old"] = "WoodPlanks", ["Wallpaper"] = "Fabric", ["Plaster_A"] = "Concrete", ["Brick Plaster"] = "Brick" }
	check(InteriorLook.match({ Pack = "Duvall", Find = { "wood", "floor" } }, pack) == "Wood Floor", "Duvall: busca el suelo de madera por palabras (el nombre más corto)")
	check(InteriorLook.match({ Pack = "MCity", Name = "Plaster_A", Find = { "plaster" }, Avoid = { "brick" } }, pack) == "Plaster_A" and InteriorLook.match({ Pack = "MCity", Name = "Nope", Find = { "plaster" }, Avoid = { "brick" } }, pack) == "Plaster_A", "Modern City: Plaster_A por nombre o por palabras (sin el de ladrillo)")
	check(InteriorLook.match({ Pack = "Duvall", Find = { "marble" } }, pack) == nil and InteriorLook.match({ Pack = "X", Find = { "wood" } }, nil) == nil, "si no hay ninguno que encaje (o no cargó el pack), nada")
end

print("Elección por estancia y pieza")
do
	local function cl(name: string, material: string, cat: string?, extra: { [string]: any }?): string?
		local info: any = { Name = name, Material = material, Category = cat, Sky = true, Seed = "1:0" }
		for k, v in extra or {} do
			info[k] = v
		end
		return InteriorLook.classify(info)
	end
	-- Suelos
	check(cl("Floor", "WoodPlanks", "Casa") == "Parquet" and cl("UpperFloor", "WoodPlanks", "Casa") == "Parquet" and cl("Floor", "WoodPlanks", "Lujo") == "Parquet", "suelo de madera de casas, pisos y juzgado: parqué")
	check(cl("FloorFinish", "CeramicTiles", "Casa", { LocalZ = 8 }) == "BaldosaBano" and cl("FloorFinish", "CeramicTiles", "Casa", { LocalZ = -6 }) == "BaldosaCocina" and cl("FloorFinish", "CeramicTiles", "Casa", { LocalZ = -6, LocalY = 11 }) == "BaldosaBano", "baldosa: el baño al fondo o arriba, la cocina delante")
	check(cl("Floor", "Marble", "Tienda") == "BaldosaLocal" and cl("Floor", "Marble", "Bar") == "BaldosaLocal" and cl("Floor", "CeramicTiles", "Tienda", { Sky = false }) == "BaldosaLocal", "tiendas, bares y súper: baldosa cerámica")
	check(cl("Floor", "Marble", "Villa") == "Marmol" and cl("Floor", "Marble", "Oficina") == "Marmol" and cl("Floor", "Marble", "Lujo") == "Marmol" and cl("Floor", "Marble", "Hotel", { Sky = false }) == "Marmol", "villa, portal, oficinas, banco y hotel: mármol")
	check(cl("Floor", "Marble", "Publico") == "Terrazo" and cl("Step", "Concrete", "Escalera") == "Terrazo" and cl("MidLanding", "Concrete", "Escalera") == "Terrazo", "estación, centro comercial y escaleras de los bloques: terrazo")
	check(cl("Floor", "CeramicTiles", "Hospital", { Sky = false }) == "Linoleo" and cl("Floor", "WoodPlanks", "Colegio") == "Linoleo" and cl("Floor", "WoodPlanks", "Hospital", { Sky = false }) == "Linoleo", "hospital y colegio: linóleo")
	check(cl("Floor", "Carpet", "Oficina") == "Moqueta" and cl("Floor", "Carpet", "Cine") == "MoquetaCine" and cl("SalaFloor", "Carpet", "Cine", { Sky = false }) == "MoquetaCine", "oficinas: moqueta; teatro y cine: moqueta estampada")
	check(cl("Floor", "Concrete", "Industrial") == "Hormigon" and cl("EmergencyLanding", "Concrete", "Escalera") == "Hormigon" and cl("Step", "Concrete", "Escalera", { Name = "Step" }) == "Terrazo", "naves, talleres y la escalera de emergencia: hormigón")
	check(cl("Floor", "Slate", "Casa") == "Pizarra" and cl("FloorSlab", "Granite", "Escalera") == "GranitoSuelo" and cl("TileFloor", "Marble", "Gimnasio", { Sky = false }) == "BaldosaBano", "pizarra, granito y duchas del gimnasio")
	check(cl("Floor", "SmoothPlastic", "Ocio") == nil and cl("Floor", "Rubber", "Gimnasio") == nil and cl("Floor", "Asphalt") == nil, "pista de baile, caucho y asfalto: no")
	-- Paredes
	check(cl("WallBack", "SmoothPlastic", "Casa") == "Pintura" and cl("Partition", "SmoothPlastic", "Oficina") == "Pintura" and cl("Wall", "SmoothPlastic", "Escalera") == "Pintura", "paredes y tabiques: pintura sobre enlucido")
	check(cl("WallFinish", "CeramicTiles", "Casa") == "Azulejo" and cl("WallFinish", "SmoothPlastic", "Casa") == "PapelPintado", "paños: azulejo (cocina y baño) y papel pintado (dormitorio, infantil)")
	check(cl("WallLeft", "SmoothPlastic", "Industrial") == "LadrilloPintado" and cl("BackWall", "Plaster", "Hotel", { Sky = false }) == "PapelPintado", "naves: ladrillo pintado; hotel: papel pintado")
	local brick, paper, upper = 0, 0, 0
	for i = 1, 200 do
		if cl("WallBack", "SmoothPlastic", "Bar", { Seed = "b" .. i }) == "LadrilloVisto" then
			brick += 1
		end
		if cl("WallLeft", "SmoothPlastic", "Villa", { Seed = "v" .. i }) == "PapelPintado" then
			paper += 1
		end
		if cl("UpperPartition", "SmoothPlastic", "Casa", { Seed = "c" .. i }) == "PapelPintado" then
			upper += 1
		end
	end
	check(brick > 80 and brick < 160 and cl("WallLeft", "SmoothPlastic", "Bar") == "Pintura", ("ladrillo visto en la pared del fondo de algunos bares (%d de 200)"):format(brick))
	check(paper > 60 and paper < 140, ("papel pintado en la mitad de las villas (%d de 200)"):format(paper))
	check(upper > 40 and upper < 110 and cl("WallLeft", "SmoothPlastic", "Casa", { Seed = "c1" }) == "Pintura", ("papel pintado en los cuartos de arriba de algunas casas (%d de 200); abajo, pintura"):format(upper))
	-- Techos
	check(cl("Ceiling", "SmoothPlastic", "Casa") == "Yeso" and cl("UpperCeiling", "SmoothPlastic", "Casa") == "Yeso" and cl("Roof", "SmoothPlastic", "Escalera") == "Yeso", "techos: yeso liso")
	check(cl("Ceiling", "SmoothPlastic", "Oficina") == "Placas" and cl("Ceiling", "Plaster", "Hospital", { Sky = false }) == "Placas" and cl("Ceiling", "SmoothPlastic", "Colegio") == "Placas", "oficinas, hospital y colegio: placas")
	check(InteriorLook.Looks.Placas.Fallback == "Yeso", "si no cargan las placas, yeso")
	-- Encimeras, rodapiés, escalones
	check(cl("Worktop", "Granite", "Casa") == "EncimeraGranito" and cl("Worktop", "Slate", "Casa") == "EncimeraGranito" and cl("VanityTop", "Marble", "Casa") == "EncimeraMarmol" and cl("Worktop", "Wood", "Casa") == "EncimeraMadera" and cl("CounterTop", "Marble", "Bar") == "EncimeraMarmol", "encimeras: granito, mármol o madera según su material")
	check(cl("Baseboard", "SmoothPlastic", "Casa", { Color = rgb(250, 250, 248) }) == nil and cl("Baseboard", "SmoothPlastic", "Ocio", { Color = rgb(30, 24, 34) }) == "Rodapie", "rodapiés oscuros de madera; los blancos lacados se quedan lisos")
	check(cl("Step", "WoodPlanks", "Casa") == "Peldano", "peldaños de madera de las casas")
	-- Nunca
	local never = true
	for _, n in { "Door", "DoorPanel", "InteriorExit", "WindowGlass", "Glass", "CeilingLight", "CeilingLamp", "SofaBase", "BaseCabinets", "Counter", "TVScreen", "Bed", "Rug", "Sign", "Shower", "Mirror" } do
		for _, m in { "SmoothPlastic", "Wood", "WoodPlanks", "Marble", "Glass", "Neon", "Fabric" } do
			if cl(n, m, "Casa") then
				never = false
				print("     " .. n .. " " .. m)
			end
		end
	end
	check(never, "nunca: puertas, cristales, luces, muebles, pantallas, alfombras, carteles, espejos")
	check(cl("Floor", "Glass", "Casa") == nil and cl("Floor", "WoodPlanks", "Casa", { Transparency = 1 }) == nil and cl("Floor", "WoodPlanks", "Casa", { Variant = "MaderaVeta" }) == nil and cl("Floor", "WoodPlanks", "Casa", { Skip = true }) == nil, "cristal, lo invisible, lo que ya lleva variant y los prefabs: no")
	check(cl("Wall", "Plaster", nil, { Sky = false }) == nil and cl("Partition", "Plaster", "Colegio", { Sky = false }) == nil and cl("Roof", "SmoothPlastic", nil, { Sky = false }) == nil, "en la calle, la fachada (Wall), los tabiques y tejados no son de aquí (HouseDress)")
	-- Estancias
	check(InteriorLook.categoryOf({ "Kitchen", "Interior_Casa", "Interiores" }) == "Casa" and InteriorLook.categoryOf({ "Interior_Local" }, "Bar") == "Bar" and InteriorLook.categoryOf({ "Interior_Local" }, "Banco") == "Lujo" and InteriorLook.categoryOf({ "Interior_Local" }, "Farmacia") == "Tienda", "estancia de las salas: casa, bar, banco, tienda…")
	check(InteriorLook.categoryOf({ "Edificio", "Hospital", "Manzana_Civica", "Town" }) == "Hospital" and InteriorLook.categoryOf({ "Gimnasio", "Colegio" }) == "Gimnasio" and InteriorLook.categoryOf({ "RecepcionHotel", "Hotel" }) == "Hotel" and InteriorLook.categoryOf({ "Edificio", "Manzana" }) == nil, "estancia en la ciudad: hospital, gimnasio del colegio, hotel; un edificio normal, ninguna")
	-- Variedad determinista
	local seen, same = {}, true
	for i = 1, 300 do
		local seed = ("%d:%dA"):format(i * 7, i % 5)
		local k = InteriorLook.pick("Parquet", 3, seed)
		seen[k] = (seen[k] or 0) + 1
		if InteriorLook.pick("Parquet", 3, seed) ~= k then
			same = false
		end
	end
	check((seen[1] or 0) > 60 and (seen[2] or 0) > 60 and (seen[3] or 0) > 60, ("los 3 parqués se reparten entre viviendas (%d/%d/%d de 300)"):format(seen[1] or 0, seen[2] or 0, seen[3] or 0))
	check(same, "siempre el mismo para la misma vivienda")
	check(InteriorLook.placeSeed(100.4, -50.2) == InteriorLook.placeSeed(100.9, -50.6), "en la ciudad, la misma semilla desde cualquier pieza del edificio")
end

---------------------------------------------------------------------
-- Packs de mentira, módulos del servidor y salas de verdad
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
	local shared = { UserMaterialChoice = Choice, InteriorLook = InteriorLook, Textures = {}, TextureIds = {} }
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
	local env = { game = fakeGame, workspace = { FindFirstChild = function()
		return nil
	end }, require = function(x)
		return x
	end }
	local UserMaterials = load("src/server/World/UserMaterials.luau", env)
	local InteriorDress = load("src/server/World/InteriorDress.luau", env)
	return UserMaterials, InteriorDress, { service = service, storage = storage }
end

-- World/Interiors de verdad (con Builder, Furniture, Tower, Lift y shared/Floors)
local Interiors, Tower
do
	local baseEnv = getfenv(1)
	local cache = {}
	local requireModule
	local sharedNode
	local fakeGame = Instance.new("DataModel")
	local shared = Instance.new("Folder")
	shared.Name = "Shared"
	shared.Parent = fakeGame:GetService("ReplicatedStorage")
	for _, name in fs.readDir("src/shared") do
		if name:match("%.luau$") then
			local m = Instance.new("ModuleScript")
			m.Name = name:gsub("%.luau$", "")
			m.Parent = shared
		end
	end
	local function node(path: string, parent: any?): any
		local self = { __path = path, Parent = parent }
		if fs.isDir(path) then
			for _, name in fs.readDir(path) do
				local child = path .. "/" .. name
				if fs.isDir(child) then
					self[name] = node(child, self)
				elseif name:match("%.luau$") and not name:match("%.server%.luau$") and not name:match("%.client%.luau$") then
					self[(name:gsub("%.luau$", ""))] = node(child, self)
				end
			end
		end
		return self
	end
	function requireModule(target: any): any
		if type(target) ~= "table" then
			target = sharedNode[target.Name]
		end
		local path = rawget(target, "__path")
		if cache[path] ~= nil then
			return cache[path]
		end
		local env = setmetatable({
			script = target, require = requireModule, game = fakeGame, workspace = fakeGame:GetService("Workspace"),
			Instance = Instance, Vector3 = Vector3, Vector2 = roblox.Vector2, CFrame = CFrame, Color3 = Color3,
			Enum = Enum, UDim = roblox.UDim, UDim2 = roblox.UDim2, Font = roblox.Font, NumberRange = roblox.NumberRange,
			NumberSequence = roblox.NumberSequence, ColorSequence = roblox.ColorSequence,
			warn = function() end, -- (Kit/Decor no encuentra todo fuera de Roblox: no importa aquí)
		}, { __index = baseEnv })
		local result = luau.load(fs.readFile(path), { debugName = path, environment = env })()
		cache[path] = result
		return result
	end
	sharedNode = node("src/shared", nil)
	local world = node("src/server/World", nil)
	Interiors = requireModule(world.Interiors)
	Tower = requireModule(world.Tower)
end

-- Monta una sala como InteriorService (con su clave de vivienda/local)
local slot = 0
local function room(parent: any, kind: string, key: string, opts: { [string]: any }?): any
	slot += 1
	local o: any = { Seed = key, Floor = 0, Floors = 1 }
	for k, v in opts or {} do
		o[k] = v
	end
	local r = Interiors[kind](parent, CFrame.new(slot * 220, 6000, 0), o)
	r.Model:SetAttribute("Key", key)
	return r
end

local function snapshot(root: any): { [any]: { Material: any, Color: any, Variant: string } }
	local out = {}
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") then
			out[p] = { Material = p.Material, Color = p.Color, Variant = p.MaterialVariant }
		end
	end
	return out
end

print("Sin carga")
do
	local _, InteriorDress, w = newModules()
	local folder = Instance.new("Folder")
	folder.Name = "Interiores"
	local r = room(folder, "Casa", "1:0")
	local before = snapshot(folder)
	local resolved = InteriorDress.start(w.service, w.storage, nil, nil, function() end, { folder })
	local changed = 0
	for p, s in before do
		if p.MaterialVariant ~= s.Variant or p.Material ~= s.Material or p.Color ~= s.Color then
			changed += 1
		end
	end
	check(resolved ~= nil and next(resolved) == nil and changed == 0 and #w.service:GetChildren() == 0, "sin packs no se toca nada (ni la sala ni MaterialService)")
	local failLoad = InteriorDress.loadPacks(w.storage, function()
		return nil
	end, function() end)
	check(failLoad == 0 and r.Model.Parent == folder, "si los packs oficiales no cargan, se sigue sin ellos")
end

print("En vivo, con las salas de World/Interiors")
local mapDress: any = nil
do
	local UserMaterials, InteriorDress, w = newModules()
	local loaded = {}
	for _, pack in Choice.Packs do
		loaded[pack.Short] = UserMaterials.unpack(fakeVariantPack(pack.Id), pack.Short, w.storage)
	end
	UserMaterials.unpack(fakeVariantPack(13752145820), "RPacks", w.storage) -- (lo carga StreetDress)
	-- Lo que ya usan las fachadas (HouseDress): en MaterialService con su escala de fachada
	local stucco
	for _, v in w.storage.Mega:GetChildren() do
		if v:GetAttribute("SourceName") == "Smooth Stucco" then
			stucco = v
		end
	end
	stucco.Parent = w.service
	local baseBefore = {}
	for _, folder in w.storage:GetChildren() do
		for _, v in folder:GetChildren() do
			baseBefore[v] = { v.BaseMaterial, v.StudsPerTile }
		end
	end
	baseBefore[stucco] = { stucco.BaseMaterial, stucco.StudsPerTile }

	-- Salas montadas antes de arrancar (en la carpeta Interiores) y la ciudad
	local folder = Instance.new("Folder")
	folder.Name = "Interiores"
	local casa = room(folder, "Casa", "10:0", { Floors = 2 })
	local villa = room(folder, "Villa", "11:0")
	local piso = room(folder, "Piso", "12:3B")
	local bar = room(folder, "Local", "13:0", { Shop = "BAR" })
	local banco = room(folder, "Local", "14:0", { Shop = "BANCO" })
	local farmacia = room(folder, "Local", "15:0", { Shop = "FARMACIA" })
	local oficina = room(folder, "Oficina", "16:2A")
	local aula = room(folder, "Aula", "17:1A")
	local nave = room(folder, "Nave", "18:0")
	local teatro = room(folder, "Teatro", "19:0")
	local estacion = room(folder, "Estacion", "20:0")
	-- La escalera y el pasillo de un bloque (World/Tower)
	local towerModel = Instance.new("Model")
	towerModel.Name = "Interior_Tower"
	towerModel:SetAttribute("Key", "21:T")
	towerModel.Parent = folder
	local okTower, towerErr = pcall(function()
		local plan = Tower.plan("Bloque_1", "Bloque", "Portal", "Piso", 4, nil)
		Tower.buildFloor(towerModel, CFrame.new(-5000, 6000, 0), plan, 0, {})
		Tower.buildFloor(towerModel, CFrame.new(-5000, 6000, 0), plan, 1, {})
	end)
	check(okTower, "se monta un bloque de pisos (portal y planta 1)" .. (if okTower then "" else ": " .. tostring(towerErr)))

	local town = Instance.new("Folder")
	town.Name = "Town"
	local function model(parent: any, name: string): any
		local m = Instance.new("Model")
		m.Name = name
		m.Parent = parent
		return m
	end
	local function part(parent: any, name: string, material: string, pos: any, color: any?): any
		local p = Instance.new("Part")
		p.Name = name
		p.Material = (Enum.Material :: any)[material]
		p.Color = color or rgb(200, 200, 200)
		p.Size = V3(20, 1, 20)
		p.CFrame = CFrame.new(pos)
		p.Parent = parent
		return p
	end
	local hosp = model(model(model(town, "Manzana_Civica"), "Hospital"), "Edificio")
	local hospFloor = part(hosp, "Floor", "CeramicTiles", V3(800, 0.2, 800), rgb(226, 230, 232))
	local hospCeiling = part(hosp, "Ceiling", "Plaster", V3(800, 12, 800), rgb(244, 242, 236))
	local hospWall = part(hosp, "Wall", "Concrete", V3(810, 6, 800), rgb(240, 242, 244))
	local hospGlass = part(hosp, "Glass", "Glass", V3(810, 6, 790), rgb(60, 80, 90))
	local hotel = model(model(town, "Hotel"), "RecepcionHotel")
	local hotelFloor = part(hotel, "Floor", "Marble", V3(-300, 0.5, 100), rgb(230, 226, 218))
	local hotelBack = part(hotel, "BackWall", "Plaster", V3(-300, 6, 110), rgb(240, 230, 210))
	local edificio = model(model(town, "Manzana"), "Edificio")
	local shopFloor = part(edificio, "Floor", "WoodPlanks", V3(40, 0.3, 40), rgb(176, 140, 104))
	local shopWall = part(edificio, "Wall", "Plaster", V3(50, 6, 40), rgb(230, 200, 160))
	local shopPartition = part(edificio, "Partition", "Plaster", V3(45, 6, 40), rgb(230, 200, 160))
	local ride = part(model(town, "Feria"), "Floor", "Rubber", V3(0, 1, 900), rgb(70, 72, 78))

	local beforeRooms = snapshot(folder)
	local beforeTown = snapshot(town)
	local hookListener
	local resolved = InteriorDress.start(w.service, w.storage, function(id: number)
		return if doc[id] then fakeVariantPack(id) else nil
	end, UserMaterials.unpack, function(listener)
		hookListener = listener
	end, { town, folder })

	check(resolved and resolved.Parquet and resolved.Pintura and resolved.Yeso and resolved.Placas and resolved.Azulejo and resolved.Marmol, "se resuelven los aspectos (parqué, pintura, yeso, placas, azulejo, mármol…)")
	check(w.storage:FindFirstChild("Duvall") and w.storage:FindFirstChild("MCity"), "carga Duvall Drive y Modern City Materials")
	check(resolved.Parquet[1].Source == "Wood Floor" and resolved.Parquet[1].Pack == "Duvall" and #resolved.Parquet == 3, "el parqué del oficial Duvall Drive va primero (y luego Oak/Mahogany Floor)")
	check(resolved.Pintura[1].Source == "Plaster_A" and resolved.LadrilloPintado[1].Source == "PaintedBrick", "pintura con Plaster_A y naves con PaintedBrick de Modern City")
	-- Variants: ninguno de los packs cambia; las copias de interior llevan su escala
	local okBase = true
	for v, b in baseBefore do
		if v.BaseMaterial ~= b[1] or v.StudsPerTile ~= b[2] then
			okBase = false
			print("     " .. v.Name)
		end
	end
	check(okBase, "no se cambia el BaseMaterial ni la escala de ningún variant de los packs (tampoco el estuco de las fachadas)")
	local okCopies, copies = true, 0
	for _, v in w.service:GetChildren() do
		local key = v:GetAttribute("InteriorLook")
		if key then
			copies += 1
			if v.StudsPerTile ~= InteriorLook.Looks[key].Studs or v:GetAttribute("SourcePack") ~= nil or not v.Name:match("^U_In_") then
				okCopies = false
			end
		end
	end
	check(copies > 20 and okCopies, ("copias de interior con su escala (%d en MaterialService, «U_In_…», sin SourcePack)"):format(copies))

	local function look(p: any): string?
		if p.MaterialVariant == "" then
			return nil
		end
		local v = w.service:FindFirstChild(p.MaterialVariant)
		return v and v:GetAttribute("InteriorLook")
	end
	local function first(r: any, name: string, material: string?): any
		for _, p in r.Model:GetDescendants() do
			if p:IsA("BasePart") and p.Name == name and (material == nil or beforeRooms[p] and beforeRooms[p].Material.Name == material) then
				return p
			end
		end
		return nil
	end
	local function all(r: any, name: string, want: string?): (number, number)
		local n, ok = 0, 0
		for _, p in r.Model:GetDescendants() do
			if p:IsA("BasePart") and p.Name == name then
				n += 1
				if look(p) == want then
					ok += 1
				end
			end
		end
		return n, ok
	end

	-- Casa
	local casaFloor = casa.Model:FindFirstChild("Floor")
	local floorLook = if beforeRooms[casaFloor].Material.Name == "WoodPlanks" then "Parquet" elseif beforeRooms[casaFloor].Material.Name == "Marble" then "Marmol" else "Pizarra"
	check(look(casaFloor) == floorLook, "casa: el suelo, " .. floorLook)
	check(look(casa.Model:FindFirstChild("Ceiling")) == "Yeso" and look(casa.Model:FindFirstChild("WallBack")) == "Pintura", "casa: techo de yeso y paredes pintadas")
	local nT, okT = 0, 0
	local nB, okB = 0, 0
	for _, p in casa.Model:GetDescendants() do
		if p.Name == "WallFinish" and beforeRooms[p].Material.Name == "CeramicTiles" then
			nT += 1
			okT += if look(p) == "Azulejo" then 1 else 0
		elseif p.Name == "FloorFinish" and beforeRooms[p].Material.Name == "CeramicTiles" then
			nB += 1
			okB += if look(p) == "BaldosaBano" or look(p) == "BaldosaCocina" then 1 else 0
		end
	end
	check(nT >= 4 and okT == nT, ("casa: azulejo en el baño y en la cocina (%d de %d)"):format(okT, nT))
	check(nB >= 2 and okB == nB, ("casa: baldosa en el baño (abajo y arriba) y en la cocina (%d de %d)"):format(okB, nB))
	local worktop = first(casa, "Worktop")
	local wantTop = ({ Granite = "EncimeraGranito", Slate = "EncimeraGranito", Marble = "EncimeraMarmol", Wood = "EncimeraMadera" })[beforeRooms[worktop].Material.Name]
	check(look(worktop) == wantTop and look(first(casa, "VanityTop")) == "EncimeraMarmol", "casa: encimera de cocina según su material y la del lavabo de mármol")
	local nS, okS = all(casa, "Step", "Peldano")
	check(nS == 16 and okS == 16, "casa de dos plantas: peldaños de tarima")
	local nBase, okBase2 = all(casa, "Baseboard", nil)
	check(nBase > 5 and okBase2 == nBase, "rodapiés blancos lacados: lisos")
	-- Lo que no se toca
	local touched = {}
	for _, r in { casa, villa, piso, bar, banco, farmacia, oficina, aula, nave, teatro, estacion } do
		for _, p in r.Model:GetDescendants() do
			if p:IsA("BasePart") and p.MaterialVariant ~= beforeRooms[p].Variant then
				if not InteriorLook.Roles[p.Name] or beforeRooms[p].Material.Name == "Glass" or beforeRooms[p].Material.Name == "Neon" or p:HasTag("Interact") or p:HasTag("InteriorExit") then
					table.insert(touched, p.Name)
				end
			end
		end
	end
	check(#touched == 0, "no se tocan cristales, puertas, luces, muebles ni nada usable" .. (if #touched > 0 then " (" .. table.concat(touched, ", ", 1, math.min(8, #touched)) .. ")" else ""))
	-- Color y física
	local okColor, okPhys, dressed = true, true, 0
	for p, s in beforeRooms do
		if p.MaterialVariant ~= s.Variant then
			dressed += 1
			local key = look(p)
			local want = InteriorLook.whiten(s.Color, InteriorLook.Looks[key].Whiten)
			if math.abs(p.Color.R - want.R) > 0.01 or math.abs(p.Color.G - want.G) > 0.01 or math.abs(p.Color.B - want.B) > 0.01 then
				okColor = false
			end
			if p.Material ~= s.Material then
				local phys = p.CustomPhysicalProperties
				local orig = roblox.PhysicalProperties.new(s.Material)
				if not phys or math.abs(phys.Density - orig.Density) > 0.001 or math.abs(phys.Friction - orig.Friction) > 0.001 then
					okPhys = false
				end
			end
		end
	end
	check(okColor, "cada pieza conserva su color (solo aclarado lo de su aspecto)")
	check(okPhys, "la pieza que cambia de material guarda su física de antes")
	-- Estancias
	check(look(villa.Model:FindFirstChild("Floor")) == "Marmol" and look(first(villa, "IslandTop")) == "EncimeraMarmol", "villa: mármol y la isla de mármol")
	check(look(bar.Model:FindFirstChild("Floor")) == "BaldosaLocal" and look(farmacia.Model:FindFirstChild("Floor")) == "BaldosaLocal" and look(banco.Model:FindFirstChild("Floor")) == "Marmol", "bar y farmacia: baldosa; banco: mármol")
	local barBack = look(bar.Model:FindFirstChild("WallBack"))
	check(barBack == "LadrilloVisto" or barBack == "Pintura", "bar: pared del fondo de ladrillo visto o pintada (" .. tostring(barBack) .. ")")
	check(look(oficina.Model:FindFirstChild("Floor")) == "Moqueta" and look(oficina.Model:FindFirstChild("Ceiling")) == "Placas", "oficina: moqueta y techo de placas")
	check(look(aula.Model:FindFirstChild("Floor")) == "Linoleo" and look(aula.Model:FindFirstChild("Ceiling")) == "Placas", "aula: linóleo y placas")
	check(look(nave.Model:FindFirstChild("Floor")) == "Hormigon" and look(nave.Model:FindFirstChild("WallBack")) == "LadrilloPintado", "nave: hormigón y ladrillo pintado")
	check(look(teatro.Model:FindFirstChild("Floor")) == "MoquetaCine" and look(estacion.Model:FindFirstChild("Floor")) == "Terrazo", "teatro: moqueta estampada; estación: terrazo")
	if okTower then
		local steps, terrazo, slab = 0, 0, nil
		for _, p in towerModel:GetDescendants() do
			if p.Name == "Step" then
				steps += 1
				terrazo += if look(p) == "Terrazo" then 1 else 0
			elseif p.Name == "FloorSlab" then
				slab = p
			end
		end
		check(steps > 0 and terrazo == steps, ("bloque: escalera de terrazo (%d de %d peldaños)"):format(terrazo, steps))
		check(slab and look(slab) ~= nil, "bloque: el pasillo con su suelo (" .. tostring(slab and look(slab)) .. ")")
	end
	-- La ciudad
	check(look(hospFloor) == "Linoleo" and look(hospCeiling) == "Placas", "hospital de la ciudad: linóleo y placas")
	check(look(hotelFloor) == "Marmol" and look(hotelBack) == "PapelPintado", "recepción del hotel: mármol y papel pintado")
	check(look(shopFloor) == "Parquet", "planta baja de un edificio normal: parqué")
	local okFacade = true
	for _, p in { hospWall, hospGlass, shopWall, shopPartition, ride } do
		local s = beforeTown[p]
		if p.MaterialVariant ~= s.Variant or p.Material ~= s.Material or p.Color ~= s.Color then
			okFacade = false
		end
	end
	check(okFacade, "en la ciudad no se tocan fachadas (Wall), tabiques, cristales ni el suelo de caucho de la feria")
	-- Variedad
	local pickedA = {}
	for i = 1, 24 do
		local r = room(folder, "Piso", ("%d:%dA"):format(100 + i, i % 6 + 1))
		InteriorDress.dress(r.Model, resolved)
		local f = r.Model:FindFirstChild("Floor")
		if look(f) == "Parquet" then
			pickedA[f.MaterialVariant] = true
		end
	end
	local nPicked = 0
	for _ in pickedA do
		nPicked += 1
	end
	check(nPicked >= 2, ("parqués distintos entre pisos (%d variants en 24 pisos)"):format(nPicked))
	local again = room(Instance.new("Folder"), "Piso", "12:3B")
	InteriorDress.dress(again.Model, resolved)
	check(again.Model:FindFirstChild("Floor").MaterialVariant == piso.Model:FindFirstChild("Floor").MaterialVariant and again.Model:FindFirstChild("WallBack").MaterialVariant == piso.Model:FindFirstChild("WallBack").MaterialVariant, "el mismo piso (misma puerta) siempre sale igual")
	-- Salas montadas en vivo
	check(type(hookListener) == "function", "se engancha a InteriorService.onBuilt")
	local live = room(folder, "Casa", "200:0")
	local liveBefore = live.Model:FindFirstChild("Floor").MaterialVariant
	if hookListener then
		hookListener({ Room = live, Building = {}, Floor = 0 })
	end
	check(liveBefore == "" and look(live.Model:FindFirstChild("Floor")) ~= nil and look(live.Model:FindFirstChild("Ceiling")) == "Yeso", "una casa montada en vivo se viste al momento")
	local liveTower = Instance.new("Model")
	liveTower.Name = "Interior_Tower"
	liveTower:SetAttribute("Key", "201:T")
	liveTower.Parent = folder
	if okTower and hookListener then
		local built = Tower.buildFloor(liveTower, CFrame.new(-9000, 6000, 0), Tower.plan("Bloque_2", "Bloque", "Portal", "Piso", 3, nil), 1, {})
		hookListener({ Room = { Model = built.Model, Kind = "Tower" }, Floor = 1, Unit = "T" })
		local n, ok = 0, 0
		for _, p in built.Model:GetDescendants() do
			if p:IsA("BasePart") and InteriorLook.Roles[p.Name] and p.Material.Name ~= "Metal" then
				n += 1
				ok += if p.MaterialVariant ~= "" then 1 else 0
			end
		end
		check(n > 0 and ok > n * 0.7, ("una planta de bloque montada en vivo se viste (%d de %d piezas)"):format(ok, n))
	end
	-- Rendimiento: no se añaden piezas
	local parts = 0
	for _, p in folder:GetDescendants() do
		if p:IsA("BasePart") and beforeRooms[p] == nil then
			parts += 1
		end
	end
	check(true, ("%d piezas vestidas en %d salas (no se añade ninguna pieza)"):format(dressed, 11))
	-- Sin Duvall ni Modern City: los del Mega Pack
	local _, InteriorDress2, w2 = newModules()
	for _, pack in Choice.Packs do
		UserMaterials.unpack(fakeVariantPack(pack.Id), pack.Short, w2.storage)
	end
	local r2 = InteriorDress2.resolve(w2.service, w2.storage)
	check(r2.Parquet and r2.Parquet[1].Source == "Oak Floor" and r2.Pintura[1].Source == "Smooth Stucco" and r2.PapelPintado[1].Source == "Floral Embossed Wallpaper", "sin los oficiales: Oak Floor, Smooth Stucco y Floral Embossed Wallpaper del Mega Pack")
	mapDress = { InteriorDress = InteriorDress, resolved = resolved }
end

---------------------------------------------------------------------
-- El mapa construido (opcional)
---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("El mapa construido")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	local before = {}
	for _, p in town:GetDescendants() do
		if p:IsA("BasePart") then
			before[p] = p.MaterialVariant
		end
	end
	local counts, byVariant = mapDress.InteriorDress.dress(town, mapDress.resolved)
	local list, total = {}, 0
	for k, n in counts do
		table.insert(list, ("%s %d"):format(k, n))
		total += n
	end
	table.sort(list)
	print("     " .. table.concat(list, ", "))
	local facade, wrong = 0, {}
	for p, v in before do
		if p.MaterialVariant ~= v then
			if p.Name == "Wall" or p.Name == "Body" or p.Name == "Roof" or p.Name == "Partition" then
				facade += 1
			end
			if not InteriorLook.TownRoles[p.Name] then
				table.insert(wrong, p.Name)
			end
		end
	end
	check(total > 300, ("se visten las plantas bajas de la ciudad (%d piezas: suelos, techos, paredes de dentro)"):format(total))
	check(facade == 0 and #wrong == 0, "ninguna fachada ni pieza de fuera" .. (if #wrong > 0 then " (" .. wrong[1] .. ")" else ""))
	check((counts.Linoleo or 0) > 0 and (counts.Placas or 0) > 0 and (counts.Marmol or 0) > 0, "hospital/colegio con linóleo y placas, hotel y vestíbulos con mármol")
	local _ = byVariant
end

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
