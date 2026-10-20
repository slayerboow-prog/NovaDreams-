-- Exporta el Cañón de Dorada (shared/Sea/ReefZone) para las vistas previas de Blender
-- (scripts/map/mar_kit_blender.py --zona): la MISMA geometría que construye el juego, en vóxeles de 2 studs
-- (el fondo de shared/Sea/Ocean + las operaciones de terreno de ReefZone en orden), las piezas del kit,
-- las luces, los haces y las cámaras de la revisión (ReefZone.Cameras).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/map/canon-export.luau /tmp/canon.json /tmp/canon.vox
--
-- canon.vox: un byte por vóxel (x más rápido, luego z, luego y) con el material:
--   0 agua · 1 arena (Salt) · 2 roca · 3 caliza · 4 arenisca · 5 tierra · 6 fango · 7 tierra firme (playa)

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")

local Ocean = L.load("src/shared/Sea/Ocean")
local ReefZone = L.load("src/shared/Sea/ReefZone")

local out, vox = process.args[1], process.args[2]
if not out or not vox then
	print("uso: lune run scripts/map/canon-export.luau <json> <vox>")
	process.exit(1)
end

local floor = math.floor
local floorCache = {}
local function floorY(x: number, z: number): number?
	local gx, gz = floor(x / 2 + 0.5), floor(z / 2 + 0.5)
	local key = gx * 100000 + gz
	local v = floorCache[key]
	if v == nil then
		local f = Ocean.floorY(gx * 2, gz * 2)
		v = if f then f else false
		floorCache[key] = v
	end
	return if v == false then nil else v
end

local STEP = 2
local X0, X1 = 4180, 4960
local Z0, Z1 = -580, -20
local Y0, Y1 = -150, 6
local NX, NZ, NY = floor((X1 - X0) / STEP), floor((Z1 - Z0) / STEP), floor((Y1 - Y0) / STEP)

local CODE = { Bed = 1, Salt = 1, Rock = 2, Limestone = 3, Sandstone = 4, Ground = 5, Mud = 6 }

-- material del lecho en cada columna: las manchas de ReefZone (Patch) o el del fondo del mar
local patches = {}
for _, op in ReefZone.ops() do
	if op.Tag == "Patch" then
		table.insert(patches, op)
	end
end
local function bedMaterial(x: number, z: number): number
	for i = #patches, 1, -1 do
		local p = patches[i]
		local dx, dz = x - p.X, z - p.Z
		if dx * dx + dz * dz <= p.R * p.R then
			return CODE[p.Material] or 1
		end
	end
	if ReefZone.contains(x, z) then
		return 1
	end
	local _, material = Ocean.cellInfo(x, z)
	return CODE[material] or 1
end

local t0 = os.clock()
local bytes = table.create(NX * NZ * NY, "\0")
local colMat = {}
for k = 0, NZ - 1 do
	local z = Z0 + (k + 0.5) * STEP
	for i = 0, NX - 1 do
		local x = X0 + (i + 0.5) * STEP
		colMat[k * NX + i] = bedMaterial(x, z)
	end
end
local codes = {}
for c = 0, 7 do
	codes[c] = string.char(c)
end
for j = 0, NY - 1 do
	local y = Y0 + (j + 0.5) * STEP
	for k = 0, NZ - 1 do
		local z = Z0 + (k + 0.5) * STEP
		for i = 0, NX - 1 do
			local x = X0 + (i + 0.5) * STEP
			local code = 0
			local f = floorY(x, z)
			if f == nil then
				code = if y <= 2 then 7 else 0 -- (la playa: tierra firme hasta y = 2)
			elseif y <= ReefZone.Surface then
				local solid, material, tag = ReefZone.solid(x, y, z, floorY)
				if solid then
					if tag == "Bed" then
						code = colMat[k * NX + i]
					else
						code = CODE[material] or 2
					end
				end
			end
			bytes[1 + j * NX * NZ + k * NX + i] = codes[code]
		end
	end
end
fs.writeFile(vox, table.concat(bytes))
print(("vóxeles %d×%d×%d en %.1f s"):format(NX, NZ, NY, os.clock() - t0))

local lights = {}
for _, l in ReefZone.Lights do
	local x, z = ReefZone.where(l)
	local y = l.Y or ((floorY(x, z) or -40) + (l.Lift or 0))
	table.insert(lights, { X = x, Y = y, Z = z, Range = l.Range, Brightness = l.Brightness, Color = l.Color })
end
local shafts = {}
for _, s in ReefZone.Shafts do
	local x, z = ReefZone.where(s)
	table.insert(shafts, { X = x, Z = z, Top = s.Top, Bottom = s.Bottom, R = s.R, Tilt = s.Tilt or 0 })
end
fs.writeFile(
	out,
	serde.encode("json", {
		Voxels = { X0 = X0, Z0 = Z0, Y0 = Y0, Step = STEP, NX = NX, NZ = NZ, NY = NY, File = vox },
		Surface = ReefZone.Surface,
		Cameras = ReefZone.Cameras,
		Placements = ReefZone.placements(floorY),
		Lights = lights,
		Shafts = shafts,
	})
)
print("📄 " .. out)
