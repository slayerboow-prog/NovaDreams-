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

local arrow = MapScreen.toArt(-62, 60) -- (tu flecha en la Plaza Mayor)
local out = { Screens = {}, Districts = {}, Places = {}, Pins = {}, Bounds = CityPlan.Bounds, Art = MapScreen.Art, IslandBox = MapScreen.IslandBox, Arrow = { arrow.X, arrow.Y }, Sea = color(MapScreen.Colors.Sea), Text = {
	Title = MapScreen.Title,
	Tagline = MapScreen.Tagline,
	Badge = MapScreen.Badge,
	Hint = MapScreen.Hint,
	Region = MapScreen.Region,
	Coords = MapScreen.coords(0, 0),
} }
local landmarks = {}
for _, place in serde.decode("json", fs.readFile("docs/mapa/lugares.json")) do
	local kind = MapInfo.KindByModel[place.Kind]
	if kind then
		local item = { Kind = kind, Position = roblox.Vector3.new(place.X, 0, place.Z), District = if place.Host then "" else place.District }
		table.insert(landmarks, item)
	end
end
-- Todo en píxeles de la imagen (MapScreen.toArt: la proyección de la cámara del render)
local function art(x: number, z: number): { number }
	local a = MapScreen.toArt(x, z)
	return { a.X, a.Y }
end
local function artPoly(poly: { { number } }): { { number } }
	local out = {}
	for _, p in poly do
		table.insert(out, art(p[1], p[2]))
	end
	return out
end
for i = 2, #process.args do
	local w, h = string.match(process.args[i], "^(%d+)x(%d+)$")
	local layout = MapScreen.layout(roblox.Vector2.new(tonumber(w), tonumber(h)))
	local fit = MapScreen.fitScale(layout)
	local labels = {}
	for id, l in MapScreen.districtLabels(layout, landmarks, MapScreen.toArt, fit) do
		labels[id] = { l.X, l.Y, l.W, l.H }
	end
	table.insert(out.Screens, {
		Viewport = { tonumber(w), tonumber(h) },
		Scale = layout.Scale,
		Canvas = { layout.Canvas.X, layout.Canvas.Y },
		Wide = layout.Wide,
		Rects = layout.Rects,
		Map = layout.Map,
		Row = layout.Row,
		TextSizes = layout.Text,
		Fit = fit,
		LabelScale = MapScreen.labelScale(layout),
		Labels = labels,
	})
end
for _, d in MapInfo.Districts do
	table.insert(out.Districts, {
		Id = d.Id,
		Name = d.Name,
		Sub = d.Theme,
		Icon = d.Icon,
		Color = color(d.Color),
		Smooth = artPoly(MapScreen.smooth(d.Poly)),
		Poly = artPoly(d.Poly),
	})
end
local seen = {}
for _, item in landmarks do
	local kind = item.Kind
	if MapScreen.Featured[kind.Model] and not seen[kind.Model] then
		seen[kind.Model] = true
		local a = art(item.Position.X, item.Position.Z)
		table.insert(out.Pins, { Model = kind.Model, Name = kind.Name, Icon = kind.Icon, U = a[1], V = a[2] })
	end
end
for _, row in MapScreen.placeRows(landmarks) do
	table.insert(out.Places, { Title = row.Title, Sub = row.Sub, Icon = row.Icon, Color = color(row.Color) })
end
fs.writeFile(process.args[1], serde.encode("json", out, true))
print("✅ " .. process.args[1])
