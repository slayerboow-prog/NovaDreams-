-- Lo que el servidor construye AL ARRANCAR y no viene en el archivo del mapa, añadido a una COPIA del
-- mapa para la auditoría de las cinemáticas (scripts/lib/CinePlanos.buildMap). Nunca toca
-- RealLifeSimulator.rbxl.
--   * La isla del sueño del prólogo (World/Kit/DreamIsland, Main.server.luau «DreamIsland»): sin ella
--     las 9 escenas del prólogo —lo primero que ve un jugador nuevo— no se podían revisar.
--   * Bastión Ceniza, la ciudad de Tefra (World/TefraCityBuilder, la monta World/PlanetWorld la primera
--     vez que alguien baja al planeta), con sus marcas de historia StorySpot «Tefra_…»: sin ella, las
--     escenas de las misiones de Tefra salían como «SinLugar» (fase 8 del cine).
--   * Los barrios de Miasma, Siroco, Nivalis y Umbría (World/PlanetWorld.buildPlanetProps y
--     buildPlanetCity, con el kit de cada uno), con sus StorySpot (v127).
--   * Nácara, la ciudad del mar (NacaraBuilder y NacaraCityBuilder), con sus StorySpot «Mar_…» (v127).
--
-- Uso (desde roblox/):  lune run scripts/audit/cine-extras.luau mapa.rbxl

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1] or error("falta el mapa (.rbxl)")
local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")

-- (el mismo cargador que scripts/build-place.luau: script.Parent.X, require, workspace, game)
local baseEnv = getfenv(1)
-- (Nácara etiqueta con CollectionService:AddTag(instancia, etiqueta): en Lune, la etiqueta va en la
-- instancia. El resto de servicios, los de verdad del mapa)
local collectionShim = {
	AddTag = function(_, instance: any, tag: string)
		instance:AddTag(tag)
	end,
	RemoveTag = function(_, instance: any, tag: string)
		instance:RemoveTag(tag)
	end,
	HasTag = function(_, instance: any, tag: string): boolean
		return instance:HasTag(tag)
	end,
	GetTagged = function(_, tag: string): { any }
		local out = {}
		for _, d in game:GetDescendants() do
			if d:HasTag(tag) then
				table.insert(out, d)
			end
		end
		return out
	end,
}
local gameProxy = setmetatable({}, {
	__index = function(_, key)
		if key == "GetService" then
			return function(_, name: string)
				if name == "CollectionService" then
					return collectionShim
				end
				return game:GetService(name)
			end
		end
		local value = game[key]
		if type(value) == "function" then
			return function(_, ...)
				return value(game, ...)
			end
		end
		return value
	end,
})
local cache: { [string]: any } = {}
local requireModule

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

-- Un ModuleScript del mapa (ReplicatedStorage.Shared.Cosmos.Tefra) → su nodo de src/shared (con su
-- Parent, para que sus script.Parent.X sigan funcionando)
local function sharedNode(instance: any): any?
	local names = {}
	local current = instance
	while current and current.Name ~= "Shared" and current.Parent do
		table.insert(names, 1, current.Name)
		current = current.Parent
	end
	local nodeAt = sharedTree
	for _, name in names do
		nodeAt = rawget(nodeAt, name)
		if not nodeAt then
			return nil
		end
	end
	return nodeAt
end

function requireModule(target: any): any
	if type(target) ~= "table" then
		target = sharedNode(target) or rawget(sharedTree, target.Name) or { __path = "src/shared/" .. target.Name .. ".luau" }
	end
	local path = rawget(target, "__path")
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = target,
		require = requireModule,
		workspace = workspace,
		game = gameProxy,
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
		-- (lo que usa además la ciudad de Tefra)
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		BrickColor = roblox.BrickColor,
		PhysicalProperties = roblox.PhysicalProperties,
		Rect = roblox.Rect,
		Random = {
			new = function(seed: number?)
				local state = seed or 1
				local function nextRaw(): number
					state = (state * 1103515245 + 12345) % 2147483648
					return state / 2147483648
				end
				return {
					NextNumber = function(_, a, b)
						local lo, hi = a or 0, b or 1
						return lo + (hi - lo) * nextRaw()
					end,
					NextInteger = function(_, a, b)
						return math.floor(a + (b - a + 1) * nextRaw())
					end,
				}
			end,
		},
		task = { wait = function() end, spawn = function(fn, ...) fn(...) end, defer = function(fn, ...) fn(...) end, delay = function() end },
	}, { __index = baseEnv })
	local chunk = luau.load(fs.readFile(path), { debugName = path, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

math.randomseed(2026)
local world = node("src/server/World", nil)
local added = {}
local ok, err = pcall(function()
	local kit = rawget(world, "Kit")
	requireModule(rawget(kit, "DreamIsland")).build()
end)
table.insert(added, if ok then "isla del sueño" else ("isla del sueño: ERROR " .. tostring(err)))

-- Bastión Ceniza (Tefra): la ciudad con sus StorySpot, como la monta PlanetWorld.buildCity
local okCity, cityErr = pcall(function()
	local folder = roblox.Instance.new("Folder")
	folder.Name = "Tefra"
	folder.Parent = workspace
	local builder = requireModule(rawget(world, "TefraCityBuilder"))
	-- (los avisos del mundo no hacen falta para mirar planos)
	local function prompt() end
	local _, stats = builder.build(folder, prompt, {})
	return stats
end)
table.insert(added, if okCity then "ciudad de Tefra" else ("ciudad de Tefra: ERROR " .. tostring(cityErr)))

-- Los otros planetas (Miasma, Siroco, Nivalis, Umbría: shared/Cosmos/PlanetRegistry), como los monta
-- World/PlanetWorld.ensurePlanet la primera vez que alguien baja: la plataforma y los puntos de interés
-- (buildPlanetProps, con su kit) y el barrio con sus marcas StorySpot «<Planeta>_…» (buildPlanetCity).
-- Sin ellos, las escenas de sus misiones salían como «SinLugar». (El terreno de vóxeles no: Lune no lo
-- lee; la auditoría pone el suelo de cada planeta con CinePlanos.addTerrain.)
local okWorld, planetWorld = pcall(requireModule, rawget(world, "PlanetWorld"))
for _, id in { "Miasma", "Siroco", "Nivalis", "Umbria", "Talasa" } do
	local okPlanet, planetErr = pcall(function()
		assert(okWorld, planetWorld)
		-- (sin las rocas de mineral: en Lune una pieza nueva no tiene Position hasta que se le da, y
		-- genericNode la lee; para mirar planos no hacen falta)
		local registry = requireModule(rawget(rawget(sharedTree, "Cosmos"), "PlanetRegistry"))
		local S = registry.get(id)
		if S then
			S.nodes = function()
				return {}
			end
		end
		local folder = planetWorld.buildPlanetProps(id)
		assert(folder, "no está en PlanetRegistry")
		planetWorld.buildPlanetCity(id, folder)
	end)
	table.insert(added, if okPlanet then id else (id .. ": ERROR " .. tostring(planetErr)))
end
-- Nácara, la ciudad del mar (World/NacaraBuilder: la plaza; World/NacaraCityBuilder: la fase 1 con la
-- Concha del Consejo y sus StorySpot «Mar_…»). Las montan NacaraService y SeaCivService al arrancar;
-- aquí solo lo construido (sin el terreno de vóxeles: Lune no lo lee).
for _, name in { "NacaraBuilder", "NacaraCityBuilder" } do
	local okSea, seaErr = pcall(function()
		requireModule(rawget(world, name)).sites()
	end)
	table.insert(added, if okSea then name else (name .. ": ERROR " .. tostring(seaErr)))
end
-- (Lune guarda «label.Font = Enum.Font.X» como FontFace con un EnumItem y luego no sabe escribirlo: a
-- la auditoría le da igual la letra, se pone una de verdad)
for _, d in workspace:GetDescendants() do
	if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
		local okFont = pcall(function()
			d.FontFace = roblox.Font.fromEnum(roblox.Enum.Font.GothamBold)
		end)
		if not okFont then
			d:Destroy()
		end
	end
end
fs.writeFile(placePath, roblox.serializePlace(game, placePath:match("%.rbxlx$") ~= nil))
print("Extras de arranque añadidos: " .. table.concat(added, ", "))
