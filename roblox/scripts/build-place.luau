-- Genera RealLifeSimulator.rbxlx con la ciudad YA construida dentro, para que se vea
-- al abrir el archivo en Studio (sin tener que pulsar Play).
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o RealLifeSimulator.rbxlx
--   lune run scripts/build-place.luau RealLifeSimulator.rbxlx
--
-- Ejecuta el mismo TownBuilder que usa el servidor, pero con las APIs de
-- Instance de Lune, y guarda el resultado en el Workspace del archivo.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1] or "RealLifeSimulator.rbxlx"
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

function requireModule(target: any): any
	local path = rawget(target, "__path")
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = target,
		require = requireModule,
		workspace = workspace,
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
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

local count = 0
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") then
		count += 1
	end
end

fs.writeFile(placePath, roblox.serializePlace(game, true))
print(("Ciudad construida en %s (%d piezas)"):format(placePath, count))
