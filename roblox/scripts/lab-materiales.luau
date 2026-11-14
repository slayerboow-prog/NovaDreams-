--!nocheck
-- Laboratorio de cine: deja en LaboratorioCine.rbxl los MaterialVariant de las ciudades de los planetas
-- (shared/Cosmos/EspacioLook.Variants «Ciudad…», con las imágenes de shared/TextureImageIds), como hace
-- scripts/build-place.luau en el juego de verdad. Un script no puede crearlos al jugar (los mapas son de plugin).
--   lune run scripts/lab-materiales.luau [LaboratorioCine.rbxl]      (con Studio cerrado)
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local labPath = process.args[1] or "LaboratorioCine.rbxl"
local lab = roblox.deserializePlace(fs.readFile(labPath))
local EspacioLook = L.load("src/shared/Cosmos/EspacioLook")
local Ids = L.load("src/shared/Cosmos/EspacioTextureIds")
local ImageOf = L.load("src/shared/TextureImageIds")
local ids = {}
for key, value in Ids do
	local n = type(value) == "string" and string.match(value, "(%d+)%s*$")
	ids[key] = n and ImageOf[n] or value
end
local service = lab:GetService("MaterialService")
local n = 0
for name, def in EspacioLook.Variants do
	local maps = EspacioLook.variantMaps(ids, name)
	if maps and string.sub(name, 1, 6) == "Ciudad" then
		local variant = service:FindFirstChild(name) or roblox.Instance.new("MaterialVariant")
		variant.Name = name
		variant.BaseMaterial = (roblox.Enum.Material :: any)[def.Base]
		variant.StudsPerTile = def.Studs
		pcall(function()
			variant.MaterialPattern = (roblox.Enum.MaterialPattern :: any)[def.Pattern]
		end)
		for prop, id in maps do
			variant[prop] = id
		end
		variant.Parent = service
		n += 1
	end
end
fs.writeFile(labPath, roblox.serializePlace(lab))
print(("Laboratorio: %d MaterialVariant de ciudad puestos (%s)"):format(n, labPath))
