-- Exporta la nave, los enemigos y la arena del combate aéreo (construidos con el código de verdad:
-- shared/AirCombat/ShipModel y World/AirArena) para las vistas previas de Blender
-- (scripts/aircombat/preview_render.py).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/aircombat/preview-export.luau DIR
--   python3 scripts/aircombat/preview_render.py DIR docs/combate-aereo
--
-- Escribe DIR/<nombre>.json: una lista de piezas { name, shape, size, cf (12 números), color,
-- material, transparency } de "nave", "dron", "caza", "torreta" y "arena".

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local L = require("../lib/ModuleLoader")
local outDir = process.args[1] or "aircombat-preview"
fs.writeDir(outDir)

local ShipModel = L.load("src/shared/AirCombat/ShipModel")
local AirArena = L.load("src/server/World/AirArena")
local CF = L.CFrame

local function dump(model: any): { any }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local shape = "Block"
			if d.ClassName == "WedgePart" then
				shape = "Wedge"
			elseif d:IsA("Part") then
				shape = d.Shape.Name
			end
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = d.CFrame:GetComponents()
			table.insert(out, {
				name = d.Name,
				shape = shape,
				size = { d.Size.X, d.Size.Y, d.Size.Z },
				cf = { x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 },
				color = { d.Color.R, d.Color.G, d.Color.B },
				material = d.Material.Name,
				transparency = d.Transparency,
			})
		end
	end
	return out
end

local function save(name: string, model: any)
	local parts = dump(model)
	fs.writeFile(outDir .. "/" .. name .. ".json", serde.encode("json", parts))
	print(("%s: %d piezas"):format(name, #parts))
end

save("nave", ShipModel.build("Caza", CF.new(0, 0, 0)))
save("dron", ShipModel.build("Dron", CF.new(0, 0, 0)))
save("caza", ShipModel.build("CazaEnemigo", CF.new(0, 0, 0)))
save("torreta", ShipModel.build("Torreta", CF.new(0, 0, 0)))
save("arena", AirArena.build())
