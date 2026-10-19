-- Lo que el servidor construye AL ARRANCAR y no viene en el archivo del mapa, añadido a una COPIA del
-- mapa para la auditoría de las cinemáticas (scripts/lib/CinePlanos.buildMap). Nunca toca
-- RealLifeSimulator.rbxl.
--   * La isla del sueño del prólogo (World/Kit/DreamIsland, Main.server.luau «DreamIsland»): sin ella
--     las 9 escenas del prólogo —lo primero que ve un jugador nuevo— no se podían revisar.
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

function requireModule(target: any): any
	if type(target) ~= "table" then
		target = rawget(sharedTree, target.Name) or { __path = "src/shared/" .. target.Name .. ".luau" }
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

math.randomseed(2026)
local world = node("src/server/World", nil)
local added = {}
local ok, err = pcall(function()
	local kit = rawget(world, "Kit")
	requireModule(rawget(kit, "DreamIsland")).build()
end)
table.insert(added, if ok then "isla del sueño" else ("isla del sueño: ERROR " .. tostring(err)))
fs.writeFile(placePath, roblox.serializePlace(game, placePath:match("%.rbxlx$") ~= nil))
print("Extras de arranque añadidos: " .. table.concat(added, ", "))
