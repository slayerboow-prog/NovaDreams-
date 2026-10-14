-- Exporta el relieve y los bosques del mapa YA CONSTRUIDO para las vistas de comparación del paisaje
-- (scripts/paisaje/render_paisaje.py; docs/paisaje/paisaje.md).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/paisaje/export-relief.luau X.rbxl DIR
--
-- Escribe en DIR:
--   relief.f32   alturas del suelo (Y del mundo) cada 16 studs, float32, fila a fila (de norte a sur),
--                desde (Relief.MinX, Relief.MinZ): el terreno que pone TerrainBuilder al arrancar (llano a
--                -1, las montañas de siempre, la colina del mirador) MÁS el relieve horneado si el
--                archivo lo trae (ServerStorage.ReliefMap). Fuera de la isla, el fondo del mar (-14).
--   relief.json  tamaño de la rejilla y si hay relieve
--   copas.tsv    las copas de los bosques (elipsoides: centro y tamaño) y sus troncos

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")

local placePath, outDir = process.args[1], process.args[2]
if not placePath or not outDir then
	print("Uso: lune run scripts/paisaje/export-relief.luau X.rbxl DIR")
	process.exit(1)
end
fs.writeDir(outDir)

local Relief = L.load("src/shared/Relief")
local CityPlan = L.load("src/shared/CityPlan")

local game = roblox.deserializePlace(fs.readFile(placePath))
local field = Relief.fromValue(game:GetService("ServerStorage"):FindFirstChild("ReliefMap"))
print(("▶ %s: %s"):format(placePath, if field then "con relieve" else "sin relieve (llano y montañas de siempre)"))

local STEP = 16
local nx = math.floor((5024 - Relief.MinX) / STEP) + 1
local nz = math.floor((4320 - Relief.MinZ) / STEP) + 1
local values = table.create(nx * nz)
-- Colina del mirador (Kit/Landmarks.terrain): bola de radio HILL_RADIUS con la cima en HillTop - 1
local landmarks = fs.readFile("src/server/World/Kit/Landmarks.luau")
local hillR = tonumber(landmarks:match("local HILL_RADIUS = (%d+)")) or 0
local hillTop = tonumber(landmarks:match("Landmarks.HillTop = ([%d%.]+)")) or 0
local hill = CityPlan.Places.Mirador
for j = 0, nz - 1 do
	local z = Relief.MinZ + j * STEP
	local spans = CityPlan.spans(CityPlan.Coast, z)
	for i = 0, nx - 1 do
		local x = Relief.MinX + i * STEP
		local inside = false
		for _, s in spans do
			if x > s[1] and x < s[2] then
				inside = true
				break
			end
		end
		local y
		if inside then
			y = math.max(Relief.surfaceY(field, x, z), Relief.domeY(CityPlan.Mountains, x, z))
			if hill and hillR > 0 then
				local d2 = (x - hill[1]) ^ 2 + (z - hill[2]) ^ 2
				if d2 < hillR * hillR then
					y = math.max(y, (hillTop - 1 - hillR) + math.sqrt(hillR * hillR - d2))
				end
			end
		else
			y = -14
			for _, island in CityPlan.Islands do
				if (x - island.X) ^ 2 + (z - island.Z) ^ 2 < island.R * island.R then
					y = -1
				end
			end
		end
		values[j * nx + i + 1] = y
	end
end
local buf = buffer.create(nx * nz * 4)
for k, v in values do
	buffer.writef32(buf, (k - 1) * 4, v)
end
fs.writeFile(outDir .. "/relief.f32", buffer.tostring(buf))
fs.writeFile(outDir .. "/relief.json", serde.encode("json", { NX = nx, NZ = nz, MinX = Relief.MinX, MinZ = Relief.MinZ, Step = STEP, Relief = field ~= nil }))

-- Copas y troncos de los bosques
local lines = {}
local town = game:GetService("Workspace"):FindFirstChild("Town")
local forests = town and town:FindFirstChild("Bosques")
if forests then
	for _, d in forests:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d.CFrame.Position
			local c = d.Color
			if d.Name == "Copa" then
				table.insert(lines, ("C\t%.1f,%.1f,%.1f\t%.2f,%.2f,%.2f\t%d,%d,%d"):format(p.X, p.Y, p.Z, d.Size.X, d.Size.Y, d.Size.Z, c.R * 255, c.G * 255, c.B * 255))
			elseif d.Name == "Trunk" then
				table.insert(lines, ("T\t%.1f,%.1f,%.1f\t%.2f,%.2f,%.2f\t%d,%d,%d"):format(p.X, p.Y, p.Z, d.Size.Y, d.Size.X, d.Size.Z, c.R * 255, c.G * 255, c.B * 255))
			end
		end
	end
end
fs.writeFile(outDir .. "/copas.tsv", table.concat(lines, "\n"))
print(("  relieve %d × %d, %d piezas de bosque"):format(nx, nz, #lines))
