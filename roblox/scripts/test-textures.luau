-- Prueba de las texturas PBR (MaterialService) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-textures.luau                (módulos, ciudad de mentira y PNGs)
--   lune run scripts/test-textures.luau /tmp/x.rbxl    (además, la ciudad construida de verdad:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Comprueba que:
--   * shared/TextureIds tiene la forma que escribe scripts/upload-textures.sh ("<Material>_<mapa>" ->
--     "rbxassetid://…") y cada id es de un material y un mapa que existen
--   * cada variant (shared/Textures) usa una carpeta de textures/ con sus mapas, un Enum.Material que
--     los kits del mundo usan de verdad, un tamaño de repetición razonable y un patrón válido
--   * sin ids (o con 0) no se crea nada ni se cambia ninguna pieza; con ids, World/Kit/MaterialLook
--     crea los MaterialVariant con sus mapas y pone en las piezas lo que toca (pintura vial, bordillo
--     de granito, acero cepillado, madera, laca de coche), sin tocar troncos ni lo demás
--   * el nivel gráfico Bajo quita el relieve (mapa normal) y Medio y Alto lo dejan
--   * en la ciudad construida: sin ids no hay nada cambiado; con ids de prueba, cada regla encuentra
--     sus piezas (miles de marcas viales y bordillos, cientos de coches…) y todos los materiales con
--     Override existen en el mapa
--   * cada PNG se repite sin costura (scripts/textures/check_tiling.py, con python3)

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
	local e = { Enum = Enum, Color3 = Color3, Instance = Instance, Vector3 = roblox.Vector3, CFrame = roblox.CFrame }
	for k, v in env or {} do
		e[k] = v
	end
	setmetatable(e, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = e })()
end

local Textures = load("src/shared/Textures.luau")
local TextureIds = load("src/shared/TextureIds.luau")
local Graphics = load("src/shared/Graphics.luau")

local function materialLook(): any
	local shared = { Textures = Textures, TextureIds = TextureIds }
	local fakeGame = {
		GetService = function(_, name)
			if name == "ReplicatedStorage" then
				return { Shared = shared }
			end
			error("servicio inesperado: " .. name)
		end,
	}
	return load("src/server/World/Kit/MaterialLook.luau", {
		game = fakeGame,
		require = function(x)
			return x
		end,
	})
end
local MaterialLook = materialLook()

-- Ids de prueba para todos los mapas que hay en textures/
local function fakeIds(): { [string]: string }
	local ids = {}
	local n = 1000
	for _, folder in fs.readDir("textures") do
		if fs.isDir("textures/" .. folder) then
			for _, file in fs.readDir("textures/" .. folder) do
				local map = file:match("^(%a+)%.png$")
				if map then
					n += 1
					ids[folder .. "_" .. map] = "rbxassetid://" .. n
				end
			end
		end
	end
	return ids
end
local FAKE = fakeIds()

print("TextureIds (lo que escribe upload-textures.sh)")
do
	local okShape, okKnown = true, true
	for key, id in TextureIds do
		if type(key) ~= "string" or not key:match("^%a+_%l+$") or type(id) ~= "string" or not id:match("^rbxassetid://%d+$") then
			okShape = false
			print("     forma rara: " .. tostring(key) .. " = " .. tostring(id))
		else
			local set, map = key:match("^(%a+)_(%l+)$")
			if not fs.isFile(("textures/%s/%s.png"):format(set, map)) then
				okKnown = false
				print("     sin textura: " .. key)
			end
		end
	end
	check(okShape, "cada entrada es \"<Material>_<mapa>\" = \"rbxassetid://<número>\"")
	check(okKnown, "cada id corresponde a un PNG de textures/")
	local src = fs.readFile("src/shared/TextureIds.luau")
	check(src:match("GENERADO por scripts/upload%-textures%.sh") ~= nil, "lleva la cabecera de archivo generado")
	local script = fs.readFile("scripts/upload-textures.sh")
	check(script:find("TextureIds.luau", 1, true) and script:find('-H "@${HEADERS}"', 1, true) and not script:find("echo \"$ROBLOX_API_KEY", 1, true), "upload-textures.sh escribe TextureIds y no enseña la clave (va en un archivo de cabeceras)")
end

print("Variants")
do
	local kitSource = {}
	local function scan(dir: string)
		for _, name in fs.readDir(dir) do
			local path = dir .. "/" .. name
			if fs.isDir(path) then
				scan(path)
			elseif name:match("%.luau$") then
				table.insert(kitSource, fs.readFile(path))
			end
		end
	end
	scan("src/server/World")
	local all = table.concat(kitSource, "\n")
	local names = {}
	for name in Textures.Variants do
		table.insert(names, name)
	end
	table.sort(names)
	check(#names >= 14, ("hay %d materiales con textura (≥ 14)"):format(#names))
	for _, name in names do
		local v = Textures.Variants[name]
		local okMaps = true
		for _, map in v.Maps do
			if not fs.isFile(("textures/%s/%s.png"):format(v.Set, map)) then
				okMaps = false
			end
		end
		local okEnum = pcall(function()
			return (Enum.Material :: any)[v.Base]
		end)
		local used = all:find("Enum.Material." .. v.Base, 1, true) ~= nil
		check(
			okMaps and okEnum and used and v.Studs >= 2 and v.Studs <= 24 and (v.Pattern == "Regular" or v.Pattern == "Organic") and table.find(v.Maps, "color") ~= nil,
			("%s: textures/%s (%s), sobre %s (lo usan los kits), %g studs, %s"):format(name, v.Set, table.concat(v.Maps, ", "), v.Base, v.Studs, v.Pattern)
		)
	end
	-- Un Override por material base como mucho (si no, el segundo pisaría al primero)
	local bases, dup = {}, false
	for _, name in names do
		local v = Textures.Variants[name]
		if v.Override then
			dup = dup or bases[v.Base] ~= nil
			bases[v.Base] = name
		end
	end
	check(not dup, "cada material de Roblox tiene como mucho un variant que lo sustituye")
	check(bases.Asphalt and bases.Pavement and bases.Concrete and bases.Brick and bases.Plaster and bases.ClayRoofTiles and bases.Marble and bases.Grass and bases.Sand and bases.CeramicTiles and bases.Granite and bases.Metal and bases.WoodPlanks, "sustituyen asfalto, acera, hormigón, ladrillo, estuco, teja, mármol, césped, arena, azulejo, granito, metal y tablas")
end

print("Sin ids no cambia nada")
do
	check(#Textures.available({}) == 0 and Textures.signature({}) == "", "sin ids: ningún variant")
	check(#Textures.available({ Asfalto_color = "rbxassetid://0", Teja_color = "0" }) == 0, "ids a 0: ninguno")
	check(Textures.maps("Asfalto", { Asfalto_normal = "rbxassetid://5" }) == nil, "sin ColorMap no se crea (aunque haya normal)")
	local partial = Textures.maps("Asfalto", { Asfalto_color = "rbxassetid://5" })
	check(partial and partial.ColorMap == "rbxassetid://5" and partial.NormalMap == nil, "con solo el color, se crea con lo que hay")

	local service = Instance.new("MaterialService")
	local made = MaterialLook.setup(service, {})
	check(#made == 0 and #service:GetChildren() == 0, "MaterialLook.setup sin ids: MaterialService vacío")
end

-- Una ciudad de mentira con una pieza de cada caso
local function miniTown(): (any, { [string]: any })
	local town = Instance.new("Model")
	town.Name = "Town"
	local parts = {}
	local function part(key: string, name: string, material: string, color: Color3, parent: any?): any
		local p = Instance.new("Part")
		p.Name = name
		p.Material = (Enum.Material :: any)[material]
		p.Color = color
		p.Parent = parent or town
		parts[key] = p
		return p
	end
	local streets = Instance.new("Folder")
	streets.Name = "Streets"
	streets.Parent = town
	part("road", "Road", "Asphalt", Color3.fromRGB(46, 48, 53), streets)
	part("marking", "Marking", "SmoothPlastic", Color3.fromRGB(236, 236, 230), streets)
	part("zebra", "Zebra", "SmoothPlastic", Color3.fromRGB(236, 236, 230), streets)
	part("curb", "Curb", "Concrete", Color3.fromRGB(214, 211, 204), streets)
	part("wall", "Wall", "Concrete", Color3.fromRGB(200, 202, 204))
	part("rail", "Rail", "Metal", Color3.fromRGB(205, 208, 214))
	part("pole", "Pole", "Metal", Color3.fromRGB(58, 62, 68))
	part("door", "Door", "Wood", Color3.fromRGB(80, 60, 44))
	part("trunk", "Trunk", "Wood", Color3.fromRGB(104, 78, 56))
	part("sign", "Sign", "SmoothPlastic", Color3.fromRGB(96, 60, 38))
	local car = Instance.new("Model")
	car.Name = "ParkedCar"
	car:SetAttribute("Paint", Color3.fromRGB(170, 30, 36))
	car.Parent = town
	part("body", "Body", "SmoothPlastic", Color3.fromRGB(170, 30, 36), car)
	part("bumper", "BumperFront", "Plastic", Color3.fromRGB(24, 24, 27), car)
	part("tyreTrim", "Trim", "SmoothPlastic", Color3.fromRGB(40, 41, 45), car)
	local glass = part("glass", "Windshield", "Glass", Color3.fromRGB(34, 46, 58), car)
	glass.Transparency = 0.35
	return town, parts
end

print("Con ids: MaterialService y piezas")
do
	local service = Instance.new("MaterialService")
	local made = MaterialLook.setup(service, FAKE)
	local count = 0
	for _ in Textures.Variants do
		count += 1
	end
	check(#made == count, ("se crean los %d variants"):format(count))
	local asf = service:FindFirstChild("Asfalto")
	check(asf and asf:IsA("MaterialVariant") and asf.BaseMaterial == Enum.Material.Asphalt and asf.ColorMap == FAKE.Asfalto_color and asf.NormalMap == FAKE.Asfalto_normal and asf.RoughnessMap == FAKE.Asfalto_roughness and asf.StudsPerTile == 14, "Asfalto: sobre Asphalt, con color, normal y rugosidad, 14 studs")
	check(asf and asf.MaterialPattern == Enum.MaterialPattern.Organic and asf:GetAttribute("NormalMapId") == FAKE.Asfalto_normal, "Asfalto: patrón orgánico (sin repetición visible) y guarda su mapa normal para el nivel gráfico")
	local brick = service:FindFirstChild("Ladrillo")
	check(asf and asf:GetAttribute("DryRoughnessId") == FAKE.Asfalto_roughness and asf:GetAttribute("WetRoughnessId") == FAKE.Asfalto_wet and FAKE.Asfalto_wet ~= nil and brick and brick:GetAttribute("WetRoughnessId") == "", "Asfalto guarda su rugosidad seca y la mojada (wet.png) para la lluvia; el ladrillo no tiene mojada")
	local veta = service:FindFirstChild("MaderaVeta")
	check(veta and veta.BaseMaterial == Enum.Material.Wood and veta.ColorMap == FAKE.Madera_color, "MaderaVeta usa las tablas de Madera sobre Wood")
	local steel = service:FindFirstChild("MetalCepillado")
	check(steel and steel.MetalnessMap == FAKE.MetalCepillado_metalness, "los metales llevan mapa de metal")
	check((service :: any).AsphaltName == "Asfalto" and (service :: any).GrassName == "CespedSuelo" and (service :: any).MetalName == "MetalPintado", "sustituyen al material de Roblox en todo el juego (asfalto, césped del terreno, metal)")
	-- Segunda vez: no duplica
	MaterialLook.setup(service, FAKE)
	check(#service:GetChildren() == count, "volver a llamar a setup no duplica nada")

	local town, p = miniTown()
	local changed = MaterialLook.assign(town, FAKE)
	check(p.marking.MaterialVariant == "PinturaVial" and p.zebra.MaterialVariant == "PinturaVial", "marcas viales y pasos de cebra: pintura vial gastada")
	check(p.curb.MaterialVariant == "Bordillo" and p.curb.Material == Enum.Material.Granite, "bordillo: de granito")
	check(p.rail.MaterialVariant == "MetalCepillado" and p.pole.MaterialVariant == "", "acero claro cepillado; el poste pintado se queda con el MetalPintado general")
	check(p.door.MaterialVariant == "MaderaVeta" and p.trunk.MaterialVariant == "", "puerta de madera con veta; el tronco del árbol, sin tocar")
	check(p.body.MaterialVariant == "PinturaCoche" and p.tyreTrim.MaterialVariant == "" and p.bumper.MaterialVariant == "", "carrocería con laca; el resto del coche igual")
	check(p.glass.Reflectance > 0.1, "el cristal del coche refleja")
	check(p.road.MaterialVariant == "" and p.wall.MaterialVariant == "" and p.sign.MaterialVariant == "", "lo que cubre un Override (asfalto, hormigón) o no toca (cartel) no cambia")
	check(changed == 6 and town:GetAttribute("TextureSet") == Textures.signature(FAKE), ("%d piezas cambiadas y la ciudad apunta qué ids usó"):format(changed))

	local town2, q = miniTown()
	MaterialLook.assign(town2, {})
	local untouched = true
	for _, part in q do
		if part.MaterialVariant ~= "" then
			untouched = false
		end
	end
	check(untouched and q.curb.Material == Enum.Material.Concrete and town2:GetAttribute("TextureSet") == "", "sin ids: ninguna pieza cambia de material")
end

print("Niveles gráficos")
do
	check(Graphics.Tiers.Low.NormalMaps == false and Graphics.Tiers.Medium.NormalMaps == true and Graphics.Tiers.High.NormalMaps == true, "Bajo sin relieve; Medio y Alto con relieve")
	local maps = Textures.maps("Ladrillo", FAKE) :: any
	local low = Textures.mapsForTier(maps, false)
	check(low.NormalMap == nil and low.ColorMap == maps.ColorMap and maps.NormalMap ~= nil, "en Bajo se quita solo el mapa normal")
	local client = fs.readFile("src/client/Controllers/MaterialDetail.luau")
	check(client:find("NormalMapId", 1, true) and client:find("Perf.onTier", 1, true), "el cliente quita/pone el relieve al cambiar de nivel")
end

local placePath = process.args[1]
if placePath then
	print("Ciudad construida (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	check(town ~= nil, "hay ciudad")
	if town then
		local expected = Textures.signature(TextureIds)
		check(town:GetAttribute("TextureSet") == expected, "la ciudad apunta los ids con los que se construyó (" .. (if expected == "" then "ninguno" else expected) .. ")")
		local ours = {}
		for name in Textures.Variants do
			ours[name] = true
		end
		local tagged, bases = 0, {}
		for _, d in town:GetDescendants() do
			if d:IsA("BasePart") then
				if ours[d.MaterialVariant] then
					tagged += 1
				end
				bases[d.Material.Name] = (bases[d.Material.Name] or 0) + 1
			end
		end
		if expected == "" then
			check(tagged == 0, "sin ids subidos ninguna pieza lleva variant (se ve como antes)")
		end
		local missing = {}
		for name, v in Textures.Variants do
			if v.Override and not bases[v.Base] then
				table.insert(missing, name .. " (" .. v.Base .. ")")
			end
		end
		check(#missing == 0, "cada material con Override está en el mapa" .. (if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))

		-- Con ids de prueba, qué encuentra cada regla
		local clock = os.clock()
		MaterialLook.assign(town, FAKE)
		local per = {}
		local bark = 0
		for _, d in town:GetDescendants() do
			if d:IsA("BasePart") then
				if d.MaterialVariant ~= "" then
					per[d.MaterialVariant] = (per[d.MaterialVariant] or 0) + 1
				end
				if d.Name == "Trunk" and d.MaterialVariant ~= "" then
					bark += 1
				end
			end
		end
		print(("     (repaso de la ciudad: %.1f s)"):format(os.clock() - clock))
		local function n(name: string): number
			return per[name] or 0
		end
		check(n("PinturaVial") > 5000, ("pintura vial en %d marcas y pasos de cebra"):format(n("PinturaVial")))
		check(n("Bordillo") > 4000, ("bordillo de granito en %d piezas"):format(n("Bordillo")))
		check(n("PinturaCoche") > 500, ("laca en %d piezas de coches"):format(n("PinturaCoche")))
		check(n("MetalCepillado") > 200, ("acero cepillado en %d piezas"):format(n("MetalCepillado")))
		check(n("MaderaVeta") > 1000, ("madera con veta en %d piezas"):format(n("MaderaVeta")))
		check(bark == 0, "ningún tronco de árbol con tablas")
	end
end

print("PNGs sin costura (python3 scripts/textures/check_tiling.py)")
do
	local run = (process :: any).exec or (process :: any).spawn
	local ok, result = pcall(run, "python3", { "scripts/textures/check_tiling.py" })
	if not ok or (result.code ~= 0 and result.stderr:find("No module named", 1, true)) then
		print("  ⚠️  no hay python3 con numpy y pillow: no se comprueban las costuras")
	else
		local bad = {}
		for line in result.stdout:gmatch("[^\n]+") do
			if line:find("❌", 1, true) then
				table.insert(bad, line)
			end
		end
		local pngs = select(2, result.stdout:gsub("sin costura", ""))
		check(result.code == 0, ("%d PNG se repiten sin costura, tamaños y peso bien"):format(pngs - 1) .. (if #bad > 0 then "\n" .. table.concat(bad, "\n") else ""))
	end
end

if failures > 0 then
	print(("\n❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("\n✅ Texturas PBR: todo bien")
