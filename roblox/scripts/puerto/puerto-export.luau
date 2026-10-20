-- Exporta el Puerto de Valmar YA CONSTRUIDO (y lo que lo rodea) para las vistas previas
-- (scripts/puerto/puerto_preview.py: plano desde arriba; scripts/puerto/puerto_blender.py --vista: en 3D).
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
--   lune run scripts/puerto/puerto-export.luau X.rbxl SALIDA.json
--
-- Escribe una lista de piezas visibles (forma, CFrame, tamaño, color, material, transparencia, de qué
-- modelo es) de la zona del puerto, más el plano (la costa, la dársena, los muelles: shared/Port/PuertoPlan).

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")

local placePath, outPath = process.args[1], process.args[2]
if not placePath or not outPath then
	print("Uso: lune run scripts/puerto/puerto-export.luau X.rbxl SALIDA.json")
	process.exit(1)
end

local Plan = L.load("src/shared/Port/PuertoPlan")
local CityPlan = L.load("src/shared/CityPlan")

local game = roblox.deserializePlace(fs.readFile(placePath))
local town = game:GetService("Workspace"):FindFirstChild("Town")
assert(town, "sin Workspace.Town")

local X0, X1, Z0, Z1 = 200, 1000, 3060, 3760
local parts = {}
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") and d.Transparency < 0.98 and not d:HasTag("EditOnly") then
		local p = d.CFrame.Position
		if p.X > X0 and p.X < X1 and p.Z > Z0 and p.Z < Z1 and p.Y > -60 then
			local top = d
			while top.Parent and top.Parent ~= town do
				top = top.Parent
			end
			local shape = "Block"
			if d:IsA("WedgePart") then
				shape = "Wedge"
			elseif d:IsA("Part") then
				shape = d.Shape.Name
			end
			local c = d.Color
			local cf = { d.CFrame:GetComponents() }
			table.insert(parts, {
				s = shape,
				cf = cf,
				size = { d.Size.X, d.Size.Y, d.Size.Z },
				c = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) },
				m = d.Material.Name,
				t = d.Transparency,
				top = top.Name,
				n = d.Name,
			})
		end
	end
end

local plan = {
	Basin = Plan.Basin,
	Quays = Plan.Quays,
	Breakwater = Plan.Breakwater,
	Aprons = Plan.Aprons,
	Coast = CityPlan.Coast,
	Box = { X0, X1, Z0, Z1 },
	Sea = Plan.SeaLevel,
	Ground = Plan.Ground,
}
fs.writeFile(outPath, serde.encode("json", { parts = parts, plan = plan }))
print(("%d piezas -> %s"):format(#parts, outPath))
