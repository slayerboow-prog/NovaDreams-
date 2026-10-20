-- Exporta las recetas del fondo de la orilla (shared/Sea/ShoreDecor) para verlas en una hoja de
-- muestras (scripts/map/orilla_preview.py). Es una VISTA PREVIA aproximada, no una captura del juego.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/map/orilla-export.luau SALIDA.json
--   python3 scripts/map/orilla_preview.py SALIDA.json docs/mar/orilla-recetas.png
--
-- Escribe, por cada tipo, unas cuantas variantes: cada pieza con su tamaño, su posición, sus ejes, su
-- color y su forma (Ball, Cylinder, elipsoide de malla o bloque), y la luz bajo el agua de día y de
-- noche en la orilla (shared/Sea/OceanBiomes.look).

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local L = require("../lib/ModuleLoader")

local ShoreDecor = L.load("src/shared/Sea/ShoreDecor")
local OceanBiomes = L.load("src/shared/Sea/OceanBiomes")

local out = process.args[1] or "orilla-recetas.json"

local function h(a: number, b: number, c: number): number
	local v = math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453
	return v - math.floor(v)
end

local function color(c: Color3): { number }
	return { c.R, c.G, c.B }
end

local function piece(size: Vector3, cf: CFrame, c: Color3, kind: string, material: string?): { [string]: any }
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return {
		Size = { size.X, size.Y, size.Z },
		Pos = { cf.Position.X, cf.Position.Y, cf.Position.Z },
		Axes = { { r.X, r.Y, r.Z }, { u.X, u.Y, u.Z }, { -l.X, -l.Y, -l.Z } },
		Color = color(c),
		Kind = kind,
		Material = material or "SmoothPlastic",
	}
end

local result = { Kinds = {}, Look = {} }
local order = { "CoralHead", "Branch", "Table", "Fan", "Anemone", "Seagrass", "Rock", "Shell", "Starfish", "Crab", "Urchin" }
for _, kind in order do
	local variants = {}
	for v = 1, 3 do
		local at = Vector3.new(0, 0, 0)
		local rec = ShoreDecor.Kinds[kind](at + Vector3.new(v * 31.7, 0, v * 17.3), (v - 0.5) / 3, h, { Mobile = false, MeshRocks = false })
		local list = {}
		for _, p in rec.Pieces do
			local k = if p.Shape == "Ball" then "Ball" elseif p.Shape == "Cylinder" then "Cylinder" elseif p.Mesh == "Sphere" then "Ellipsoid" elseif p.Mesh == "Cylinder" then "MeshCylinder" else "Block"
			local cf = p.CFrame - Vector3.new(v * 31.7, 0, v * 17.3)
			table.insert(list, piece(p.Size, cf, p.Color, k, p.Material))
		end
		for _, sw in rec.Sways do
			local cur = sw.Base - Vector3.new(v * 31.7, 0, v * 17.3)
			for _, hh in sw.Heights do
				local k = if sw.Mesh == "Sphere" then "Ellipsoid" elseif sw.Mesh == "Cylinder" then "MeshCylinder" else "Block"
				table.insert(list, piece(Vector3.new(sw.Width, hh, sw.Depth), cur * CFrame.new(0, hh / 2, 0), sw.Color, k, sw.Material))
				cur = cur * CFrame.new(0, hh, 0) * CFrame.Angles(0.12, 0, 0.05)
			end
		end
		table.insert(variants, list)
	end
	result.Kinds[kind] = variants
end
result.Order = order
for _, name in { "Orilla", "Coral" } do
	local day = OceanBiomes.look(name, 2, nil, 0)
	local night = OceanBiomes.look(name, 2, nil, 1)
	result.Look[name] = {
		Day = { Water = color(day.Water), Fog = color(day.Fog), Tint = color(day.Tint), Ambient = color(day.Ambient) },
		Night = { Water = color(night.Water), Fog = color(night.Fog), Tint = color(night.Tint), Ambient = color(night.Ambient) },
	}
end
fs.writeFile(out, serde.encode("json", result))
print("Escrito " .. out)
