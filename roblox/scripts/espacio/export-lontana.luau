-- Exporta el terreno de Lontana (shared/Cosmos/Lontana) a un JSON para la vista previa de
-- docs/planetas/lontana-terreno.jpg (scripts/espacio/gen.py --terreno lo dibuja).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/espacio/export-lontana.luau [salida.json]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")

local Lontana = L.load("src/shared/Cosmos/Lontana")

local out = process.args[1] or "assets/espacio/.lontana-terreno.json"
local step = 8
local n = math.floor(Lontana.Half * 2 / step)
local heights, mats = {}, {}
local names = {}
local index = {}
for j = 0, n - 1 do
	local hrow, mrow = {}, {}
	for i = 0, n - 1 do
		local x = Lontana.Origin.X - Lontana.Half + i * step + step / 2
		local z = Lontana.Origin.Z - Lontana.Half + j * step + step / 2
		local h = Lontana.heightAt(x, z)
		local m = Lontana.materialAt(x, z, h)
		if not index[m] then
			table.insert(names, m)
			index[m] = #names
		end
		table.insert(hrow, math.floor(h * 10 + 0.5) / 10)
		table.insert(mrow, index[m])
	end
	table.insert(heights, hrow)
	table.insert(mats, mrow)
end
local colors = {}
for name, c in Lontana.TerrainColors do
	colors[name] = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end
local pois = {}
for _, p in Lontana.POIs do
	table.insert(pois, { Id = p.Id, X = p.X, Z = p.Z })
end
local nodes = {}
for _, nd in Lontana.nodes() do
	table.insert(nodes, { X = nd.Pos.X - Lontana.Origin.X, Z = nd.Pos.Z - Lontana.Origin.Z, Ore = nd.Ore })
end
fs.writeFile(out, serde.encode("json", {
	Step = step,
	Half = Lontana.Half,
	Water = Lontana.WaterY,
	Heights = heights,
	Materials = mats,
	Names = names,
	Colors = colors,
	POIs = pois,
	Nodes = nodes,
}))
print(("Terreno de Lontana exportado a %s (%d × %d)"):format(out, n, n))
