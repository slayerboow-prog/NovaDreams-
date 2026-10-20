-- Exporta las fichas de aspecto del reparto (shared/LifeStory/CastLook) a JSON para dibujar sus texturas
-- (scripts/personajes/gen.py) y las vistas previas (scripts/personajes/render.py). Una sola fuente: lo
-- que dibuja Python es lo que el juego pide.
--
-- Uso (desde roblox/):  lune run scripts/personajes/export.luau [salida.json]
-- (por defecto scripts/personajes/out/personajes.json; la carpeta out/ no se sube)

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")

local CastLook = L.load("src/shared/LifeStory/CastLook")
local Cast = L.load("src/shared/LifeStory/Cast")

local out = process.args[1] or "scripts/personajes/out/personajes.json"
local dir = out:match("^(.*)/[^/]+$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end

local list = {}
for _, spec in CastLook.all() do
	local person = Cast.People[spec.Id]
	table.insert(list, {
		Id = spec.Id,
		Key = spec.Key,
		Kind = spec.Kind,
		Group = CastLook.groupOf(spec),
		Name = spec.Name,
		Faces = spec.Faces,
		Face = spec.Face,
		Shirt = spec.Shirt,
		Pants = spec.Pants,
		Hair = spec.Hair,
		Colors = spec.Colors,
		LongHair = person and person.LongHair == true or (spec.Key == "Familia_Mama" or spec.Key == "Abu_Rosa"),
		Kid = person and person.Kid == true,
		Teen = person and person.Teen == true,
		Old = person and person.Old == true,
		Principal = table.find(Cast.Principales, spec.Id) ~= nil,
		Body = person and person.Body,
		Glow = person and person.Glow ~= nil,
		Shoes = person and person.Shoes and { math.floor(person.Shoes.R * 255 + 0.5), math.floor(person.Shoes.G * 255 + 0.5), math.floor(person.Shoes.B * 255 + 0.5) } or nil,
		Backpack = person and person.Backpack ~= nil,
	})
end
local shirts, pants = {}, {}
for name, s in CastLook.ShirtStyles do
	shirts[name] = { Short = s.Short == true, Label = s.Label }
end
for name, s in CastLook.PantsStyles do
	pants[name] = { Label = s.Label }
end
local data = {
	Characters = list,
	Full = CastLook.Full,
	Basic = CastLook.Basic,
	ShirtStyles = shirts,
	PantsStyles = pants,
	EyeColors = CastLook.EyeColors,
	HairFile = CastLook.HAIR_FILE,
}
fs.writeFile(out, serde.encode("json", data, true))
local kinds = {}
for _, c in list do
	kinds[c.Kind] = (kinds[c.Kind] or 0) + 1
end
local parts = {}
for k, n in kinds do
	table.insert(parts, ("%s %d"):format(k, n))
end
table.sort(parts)
print(("✅ %s: %d personajes (%s)"):format(out, #list, table.concat(parts, ", ")))
