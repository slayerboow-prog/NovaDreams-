-- Exporta el mar de Valmar (shared/Sea/Ocean) a una rejilla para dibujarlo (scripts/map/mar_render.py).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/map/mar-export.luau [PASO] [SALIDA.json] [X0 Z0 X1 Z1]   (con caja: solo ese trozo,
--                                                                          para las vistas submarinas)
--   python3 scripts/map/mar_render.py SALIDA.json docs/mar/
--
-- Escribe: el fondo (Y) y la zona de cada punto de la rejilla (nil en tierra), los sitios (POI), la
-- sima, la garganta, la cuenca, los puertos que no se tocan y la costa.

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")

local Ocean = L.load("src/shared/Sea/Ocean")
local CityPlan = L.load("src/shared/CityPlan")

local step = tonumber(process.args[1]) or 48
local out = process.args[2] or "mar-grid.json"
local a = Ocean.Area
if process.args[6] then
	a = { MinX = tonumber(process.args[3]), MinZ = tonumber(process.args[4]), MaxX = tonumber(process.args[5]), MaxZ = tonumber(process.args[6]) }
end
local floors, zones = {}, {}
local nx = math.floor((a.MaxX - a.MinX) / step) + 1
local nz = math.floor((a.MaxZ - a.MinZ) / step) + 1
local zoneIndex = {}
for i, id in Ocean.World.ZoneOrder do
	zoneIndex[id] = i
end
for j = 0, nz - 1 do
	local z = a.MinZ + j * step
	local frow, zrow = {}, {}
	for i = 0, nx - 1 do
		local x = a.MinX + i * step
		local s = Ocean.sample(x, z)
		frow[i + 1] = if s.Floor then math.floor(s.Floor * 10 + 0.5) / 10 else 999
		zrow[i + 1] = if s.Zone then zoneIndex[s.Zone] else 0
	end
	floors[j + 1] = frow
	zones[j + 1] = zrow
end
local pois = {}
for _, poi in Ocean.Pois do
	local p = Ocean.poiPosition(poi)
	table.insert(pois, { Id = poi.Id, Name = poi.Name, X = p.X, Y = p.Y, Z = p.Z, Zone = poi.Zone })
end
local zoneNames = {}
for i, id in Ocean.World.ZoneOrder do
	zoneNames[i] = Ocean.World.Zones[id].Name
end
fs.writeFile(out, serde.encode("json", {
	Step = step,
	MinX = a.MinX,
	MinZ = a.MinZ,
	NX = nx,
	NZ = nz,
	Surface = Ocean.Surface,
	StudsPerMeter = Ocean.StudsPerMeter,
	Floors = floors,
	Zones = zones,
	ZoneNames = zoneNames,
	ZoneIds = Ocean.World.ZoneOrder,
	Pois = pois,
	Trench = Ocean.Trench.Points,
	Canyon = Ocean.Canyon.Points,
	Keep = Ocean.Keep,
	Coast = CityPlan.Coast,
	Islands = CityPlan.Islands,
	Lair = Ocean.Lair,
}))
print(("Escrito %s: %d x %d puntos cada %d studs"):format(out, nx, nz, step))
