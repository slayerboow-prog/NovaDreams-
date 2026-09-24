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

local baseEnv = getfenv(1)
local function loadModule(path: string, extra: { [string]: any }): any
	local env = setmetatable({
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
	for key, value in extra do
		env[key] = value
	end
	local chunk = luau.load(fs.readFile(path), { debugName = path, environment = env })
	return chunk()
end

-- Semilla fija: el mapa sale igual en cada build (árboles y colores)
math.randomseed(2026)

local Builder = loadModule("src/server/World/Builder.luau", {})
local TownBuilder = loadModule("src/server/World/TownBuilder.luau", {
	script = { Parent = { Builder = Builder } },
	require = function(module)
		return module
	end,
})

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
