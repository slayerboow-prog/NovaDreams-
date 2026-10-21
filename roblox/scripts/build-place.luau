-- Genera RealLifeSimulator.rbxl con la ciudad YA construida dentro, para que se vea
-- al abrir el archivo en Studio (sin tener que pulsar Play).
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o RealLifeSimulator.rbxl
--   lune run scripts/build-place.luau RealLifeSimulator.rbxl
--
-- Ejecuta el mismo TownBuilder que usa el servidor, pero con las APIs de
-- Instance de Lune, y guarda el resultado en el Workspace del archivo.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1] or "RealLifeSimulator.rbxl"
local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")

local existing = workspace:FindFirstChild("Town")
if existing then
	existing:Destroy()
end

-- Imitamos "script.Parent.X" y "require" de Roblox sobre las carpetas de src/server
local baseEnv = getfenv(1)
local cache: { [string]: any } = {}
local requireModule

-- Árbol de carpetas y módulos, leído por adelantado (Lune no permite esperar dentro de __index)
local function node(path: string, parent: any?): any
	local self = { __path = path, Parent = parent }
	if fs.isDir(path) then
		for _, name in fs.readDir(path) do
			local child = path .. "/" .. name
			if fs.isDir(child) then
				self[name] = node(child, self)
			elseif name:match("%.luau$") and not name:match("%.server%.luau$") and not name:match("%.client%.luau$") then
				self[name:gsub("%.luau$", "")] = node(child, self)
			end
		end
	end
	return setmetatable(self, {
		__index = function(_, name)
			error(("No existe '%s' dentro de %s"):format(tostring(name), path))
		end,
	})
end

local sharedTree = node("src/shared", nil)

function requireModule(target: any): any
	-- Módulos compartidos (ReplicatedStorage.Shared.X) -> src/shared/X.luau (con su carpeta, para que
	-- dentro funcione script.Parent.Y, p. ej. Pets -> NameFilter)
	if type(target) ~= "table" then
		-- (también en subcarpetas: ReplicatedStorage.Shared.Port.PuertoPlan -> src/shared/Port/PuertoPlan)
		local names = {}
		local inst = target
		while inst and inst.Name ~= "Shared" do
			table.insert(names, 1, inst.Name)
			inst = inst.Parent
		end
		local found: any = if inst then sharedTree else nil
		for _, name in names do
			found = found and rawget(found, name)
		end
		target = found or rawget(sharedTree, target.Name) or { __path = "src/shared/" .. target.Name .. ".luau" }
	end
	local path = rawget(target, "__path")
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = target,
		require = requireModule,
		workspace = workspace,
		game = game,
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		ColorSequence = roblox.ColorSequence,
	}, { __index = baseEnv })
	local chunk = luau.load(fs.readFile(path), { debugName = path, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

-- Semilla fija: el mapa sale igual en cada build (árboles, colores, alturas)
math.randomseed(2026)

local world = node("src/server/World", nil)
local TownBuilder = requireModule(world.TownBuilder)
local town = TownBuilder.build()
town.Parent = workspace

-- MaterialVariant ya creados (con su BaseMaterial): en el servidor un Script no puede escribir
-- BaseMaterial, así que World/Kit/MaterialLook solo les pone los mapas al arrancar
local Textures = requireModule(rawget(sharedTree, "Textures"))
local TextureIds = requireModule(rawget(sharedTree, "TextureIds"))
-- (con los mapas ya puestos: el id de imagen de cada Decal sale de shared/TextureImageIds)
local imageOf: { [string]: string } = {}
if fs.isFile("src/shared/TextureImageIds.luau") then
	for decal, image in requireModule(rawget(sharedTree, "TextureImageIds")) do
		imageOf[tostring(decal)] = image
	end
end
local ids = {}
for key, value in TextureIds do
	local n = type(value) == "string" and (value:match("(%d+)%s*$") or value:match("id=(%d+)"))
	ids[key] = n and imageOf[n] or value
end
local materialService = game:GetService("MaterialService")
for _, name in Textures.available(ids) do
	local def = Textures.Variants[name]
	local maps = Textures.maps(name, ids)
	local variant = materialService:FindFirstChild(name) or roblox.Instance.new("MaterialVariant")
	variant.Name = name
	variant.BaseMaterial = (roblox.Enum.Material :: any)[def.Base]
	variant.StudsPerTile = def.Studs
	pcall(function()
		variant.MaterialPattern = (roblox.Enum.MaterialPattern :: any)[def.Pattern]
	end)
	if next(imageOf) then
		for _, prop in Textures.MapProperty do
			variant[prop] = maps[prop] or ""
		end
		variant:SetAttribute("NormalMapId", maps.NormalMap or "")
		variant:SetAttribute("DryRoughnessId", maps.RoughnessMap or "")
		variant:SetAttribute("WetRoughnessId", Textures.wetMap(name, ids) or "")
	end
	variant.Parent = materialService
end

-- Los del espacio (shared/Cosmos/EspacioLook: «NaveCasco» y «TefraRoca», sin Override) con los ids de
-- scripts/upload-espacio.sh (shared/Cosmos/EspacioTextureIds). Sin ids, no se crea nada.
do
	local cosmosTree = rawget(sharedTree, "Cosmos")
	local EspacioLook = requireModule(rawget(cosmosTree, "EspacioLook"))
	local espacioIds = {}
	for key, value in requireModule(rawget(cosmosTree, "EspacioTextureIds")) do
		local n = type(value) == "string" and (value:match("(%d+)%s*$") or value:match("id=(%d+)"))
		espacioIds[key] = n and imageOf[n] or value
	end
	for name, def in EspacioLook.Variants do
		local maps = EspacioLook.variantMaps(espacioIds, name)
		if maps then
			local variant = materialService:FindFirstChild(name) or roblox.Instance.new("MaterialVariant")
			variant.Name = name
			variant.BaseMaterial = (roblox.Enum.Material :: any)[def.Base]
			variant.StudsPerTile = def.Studs
			pcall(function()
				variant.MaterialPattern = (roblox.Enum.MaterialPattern :: any)[def.Pattern]
			end)
			for prop, id in maps do
				variant[prop] = id
			end
			variant.Parent = materialService
		end
	end
end

-- (v4 del mar) El MaterialVariant «MarCoral» (los corales de cuerpo macizo: shared/Sea/MarKit.V4Variant) con las
-- texturas «coralv4_*» de assets/mar/tex (las sube scripts/upload-mar.sh; su imagen, scripts/textures/image-ids.sh).
-- Sin ids, no se crea: los corales se quedan con su material (MarKit.V4Material).
do
	local seaTree = rawget(sharedTree, "Sea")
	local MarAssetIds = requireModule(rawget(seaTree, "MarAssetIds"))
	local tex = MarAssetIds.Texturas or {}
	local function image(key: string): string?
		local value = tex[key]
		local n = type(value) == "string" and (value:match("(%d+)%s*$") or value:match("id=(%d+)"))
		return if n and imageOf[n] then imageOf[n] else nil
	end
	local color = image("coralv4_color")
	if color then
		local variant = materialService:FindFirstChild("MarCoral") or roblox.Instance.new("MaterialVariant")
		variant.Name = "MarCoral"
		variant.BaseMaterial = roblox.Enum.Material.Limestone
		variant.StudsPerTile = 3
		pcall(function()
			variant.MaterialPattern = roblox.Enum.MaterialPattern.Organic
		end)
		variant.ColorMap = color
		variant.NormalMap = image("coralv4_normal") or ""
		variant.RoughnessMap = image("coralv4_roughness") or ""
		variant.Parent = materialService
	end
end

local count = 0
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
	end
end

-- .rbxlx = texto (XML); .rbxl = binario (mucho más ligero)
fs.writeFile(placePath, roblox.serializePlace(game, placePath:match("%.rbxlx$") ~= nil))
print(("Ciudad construida en %s (%d piezas)"):format(placePath, count))
-- Relieve del paisaje (World/ReliefBake, docs/paisaje/paisaje.md)
local relief = game:GetService("ServerStorage"):FindFirstChild("ReliefMap")
if relief then
	print(("Relieve: %d celdas de 16 studs con lomas (máx. %d studs), %d árboles subidos, bosques con %d árboles (%d piezas)"):format(
		relief:GetAttribute("Raised") or 0, relief:GetAttribute("Max") or 0, relief:GetAttribute("Lifted") or 0,
		relief:GetAttribute("ForestTrees") or 0, relief:GetAttribute("ForestParts") or 0))
else
	print("⚠️  Sin relieve (World/ReliefBake no ha dejado ServerStorage.ReliefMap)")
end
