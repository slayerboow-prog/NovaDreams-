-- Exporta los modelos de la Invasión de la Grieta (construidos con el código de verdad:
-- World/Kit/AlienModels y shared/Invasion/Races) para las vistas previas de Blender
-- (scripts/invasion/preview_render.py, que reutiliza el de scripts/aircombat).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/invasion/preview-export.luau DIR
--   python3 scripts/invasion/preview_render.py DIR docs/invasion
--
-- Escribe DIR/<raza>.json (las 4 tropas, el caza, el dron y la nave de desembarco, en fila),
-- DIR/reyes.json (los reyes) y DIR/criaturas.json (la gente transformada).

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local L = require("../lib/ModuleLoader")
local outDir = process.args[1] or "invasion-preview"
fs.writeDir(outDir)

local Races = L.load("src/shared/Invasion/Races")
local AlienModels = L.load("src/server/World/Kit/AlienModels")
local CF = L.CFrame

local function dump(model: any, offset: any, out: { any })
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local shape = if d:IsA("Part") then d.Shape.Name else "Block"
			local cf = CF.new(offset) * d.CFrame
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
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
end

local V = L.globals and require("@lune/roblox").Vector3 or require("@lune/roblox").Vector3
for _, race in Races.List do
	local out = {}
	local x = 0
	for _, kind in { "Grunt", "Heavy", "Ranged", "Elite" } do
		local m = AlienModels.ground(race, kind)
		local h = m.PrimaryPart.Size.Y
		dump(m, V.new(x, h / 2, 0), out)
		x += 12
	end
	dump(AlienModels.ship(race, "Drone"), V.new(x + 4, 10, 0), out)
	dump(AlienModels.ship(race, "Fighter"), V.new(x + 18, 12, 0), out)
	dump(AlienModels.ship(race, "Dropship"), V.new(x + 50, 18, 6), out)
	fs.writeFile(outDir .. "/" .. race.Id .. ".json", serde.encode("json", out))
end
local kings, creatures = {}, {}
for i, race in Races.List do
	local m = AlienModels.king(race)
	local h = m.PrimaryPart.Size.Y
	dump(m, V.new((i - 1) * 40, h / 2, 0), kings)
	for j, c in race.Creatures do
		dump(AlienModels.creature(race, c), V.new((i - 1) * 12 + (j - 1) * 5, 2.4, (j - 1) * 4), creatures)
	end
end
fs.writeFile(outDir .. "/reyes.json", serde.encode("json", kings))
fs.writeFile(outDir .. "/criaturas.json", serde.encode("json", creatures))
print("✅ exportado en " .. outDir)
