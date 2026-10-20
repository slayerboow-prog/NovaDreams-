-- Saca los datos de los 30 conjuntos (src/shared/Outfits.luau) en JSON, para scripts/outfits/gen.py.
-- Uso (desde roblox/): lune run scripts/outfits/export.luau > /tmp/outfits.json
-- (gen.py lo lanza solo). Los colores salen como [r, g, b] (0-255).

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local path = "src/shared/Outfits.luau"
local env = setmetatable({ Color3 = roblox.Color3, typeof = roblox.typeof or typeof }, { __index = getfenv(1) })
local Outfits = luau.load(fs.readFile(path), { debugName = path, environment = env })()

local function plain(value: any): any
	if typeof(value) == "Color3" then
		return { math.floor(value.R * 255 + 0.5), math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5) }
	elseif type(value) == "table" then
		local out = {}
		for k, v in value do
			out[k] = plain(v)
		end
		return out
	end
	return value
end

print(serde.encode("json", plain(Outfits.List), false))
