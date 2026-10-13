-- Datos para el montaje de la pantalla del mapa grande (scripts/map/mockup.py): lo mismo que usa el
-- juego (shared/MapScreen: sitio de cada pieza, distritos, «Lugares importantes», bordes redondeados).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/map/layout.luau SALIDA.json 1846x852 932x430

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local shared: { [string]: any } = {}
local function load(name: string): any
	if shared[name] == nil then
		local parent = setmetatable({}, { __index = function(_, key)
			return { __shared = key }
		end })
		local env = setmetatable({
			Vector3 = roblox.Vector3,
			Vector2 = roblox.Vector2,
			Color3 = roblox.Color3,
			script = { Parent = parent },
			require = function(target: any)
				return load(target.__shared)
			end,
		}, { __index = _G })
		shared[name] = luau.load(fs.readFile("src/shared/" .. name .. ".luau"), { debugName = name, environment = env })()
	end
	return shared[name]
end
local MapScreen = load("MapScreen")
local MapInfo = load("MapInfo")
local CityPlan = load("CityPlan")

local function color(c: any): { number }
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

local out = { Screens = {}, Districts = {}, Places = {}, Pins = {}, Bounds = CityPlan.Bounds, Text = {
	Title = MapScreen.Title,
	Tagline = MapScreen.Tagline,
	Hint = MapScreen.Hint,
	Region = MapScreen.Region,
	Coords = MapScreen.coords(0, 0),
} }
for i = 2, #process.args do
	local w, h = string.match(process.args[i], "^(%d+)x(%d+)$")
	local layout = MapScreen.layout(roblox.Vector2.new(tonumber(w), tonumber(h)))
	table.insert(out.Screens, {
		Viewport = { tonumber(w), tonumber(h) },
		Scale = layout.Scale,
		Canvas = { layout.Canvas.X, layout.Canvas.Y },
		Wide = layout.Wide,
		Rects = layout.Rects,
		Map = layout.Map,
		Row = layout.Row,
		TextSizes = layout.Text,
	})
end
for _, d in MapInfo.Districts do
	table.insert(out.Districts, {
		Id = d.Id,
		Name = d.Name,
		Sub = d.Theme,
		Icon = d.Icon,
		Color = color(d.Color),
		Center = { d.Center.X, d.Center.Y },
		Label = { MapScreen.labelAt(d.Id, d.Center).X, MapScreen.labelAt(d.Id, d.Center).Y },
		Smooth = MapScreen.smooth(d.Poly),
		Poly = d.Poly,
	})
end
local landmarks = {}
for _, place in serde.decode("json", fs.readFile("docs/mapa/lugares.json")) do
	local kind = MapInfo.KindByModel[place.Kind]
	if kind then
		local item = { Kind = kind, Position = roblox.Vector3.new(place.X, 0, place.Z), District = if place.Host then "" else place.District }
		table.insert(landmarks, item)
		table.insert(out.Pins, { Model = kind.Model, Name = kind.Name, Icon = kind.Icon, X = place.X, Z = place.Z, Important = kind.Important == true, Featured = MapScreen.Featured[kind.Model] == true })
	end
end
for _, row in MapScreen.placeRows(landmarks) do
	table.insert(out.Places, { Title = row.Title, Sub = row.Sub, Icon = row.Icon, Color = color(row.Color) })
end
fs.writeFile(process.args[1], serde.encode("json", out, true))
print("✅ " .. process.args[1])
