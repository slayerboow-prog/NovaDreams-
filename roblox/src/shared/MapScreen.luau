-- MapScreen: la pantalla del MAPA GRANDE (Controllers/MapUI), sin nada de Roblox dentro: dónde va cada
-- pieza según la pantalla, qué sale en las listas y la imagen de la isla. Lo usan MapUI, las pruebas
-- (scripts/test-hud.luau, test-gps.luau) y el montaje de docs/mapa (scripts/map/mockup.py).
--
--   ┌──────────────────────────────────────────────────────────────────────────────────────┐
--   │ [botones de Roblox] [logo REAL LIFE SIMULATOR]          (brújula) [☀ 10:27 ☁ 22°C] [✖] │
--   │ ┌ Distritos ┐                                                      ┌ Lugares importantes┐│
--   │ │ 6 filas   │            la isla vista desde arriba                │ lista (se desplaza) ││
--   │ └───────────┘            (distritos con su borde de color,         │                     ││
--   │                           lugares, tu flecha, la ruta del GPS)  [+]│                     ││
--   │                                                                 [−]└─────────────────────┘│
--   │ [📍 Valmar · coordenadas]          [✖ Quitar ruta]              [◎] [🎮 Toca un lugar…] │
--   └──────────────────────────────────────────────────────────────────────────────────────┘
-- En pantallas pequeñas (móvil apaisado, 932x430) los dos paneles se recogen en dos pestañas
-- («Distritos» y «Lugares») debajo del logo: se abre uno a la vez, encima del mapa.
--
--   MapScreen.layout(viewport, { TopbarRight = px }) -> Layout (todo en unidades del lienzo)
--   MapScreen.Districts                              -> los 6 distritos del panel (CityPlan)
--   MapScreen.placeRows(landmarks)                   -> filas de «Lugares importantes»
--   MapScreen.districtNear(x, z)                     -> distrito de un sitio (o el más cercano)
--   MapScreen.coords(x, z)                           -> "37.6289° N  0.7307° W"
--   MapScreen.tiles(ids)                             -> trozos de la imagen de la isla (o {} si no está subida)
--   MapScreen.smooth(poly)                           -> el borde de un distrito, redondeado (para dibujarlo)

local CityPlan = require(script.Parent.CityPlan)
local MapInfo = require(script.Parent.MapInfo)
local MapLegend = require(script.Parent.MapLegend)

local MapScreen = {}

MapScreen.Title = "REAL LIFE SIMULATOR"
MapScreen.Tagline = "Tu vida, tu historia"
MapScreen.Hint = "Toca un lugar o mantén el dedo para ver más"
MapScreen.HintDesktop = "Pulsa un lugar o mantén pulsado para ver más · rueda: acercar · M: cerrar"
MapScreen.Outskirts = "Afueras de Valmar"
MapScreen.Region = "Valmar"

---------------------------------------------------------------------
-- Colores (los del dibujo de referencia: azul marino con un filo azul que brilla)
---------------------------------------------------------------------
local rgb = Color3.fromRGB
MapScreen.Colors = {
	Panel = rgb(8, 18, 46), -- fondo de los paneles
	PanelTransparency = 0.12,
	Row = rgb(16, 32, 72), -- cada fila de una lista
	RowMarked = rgb(120, 34, 60), -- la fila del sitio marcado
	Edge = rgb(70, 150, 255), -- filo
	Glow = rgb(110, 200, 255), -- brillo del filo
	Title = rgb(255, 255, 255),
	Sub = rgb(186, 198, 222), -- subtítulos: gris claro
	Sea = rgb(10, 40, 96), -- fuera de la imagen
	Pin = rgb(14, 26, 58), -- los lugares del mapa: círculo oscuro
}

-- Color del círculo de cada lugar de la lista, por su categoría de la leyenda (shared/MapLegend)
MapScreen.CategoryColors = {
	Aeropuertos = rgb(40, 120, 240),
	Instituciones = rgb(40, 110, 220),
	Ciudad = rgb(40, 110, 220),
	Tiendas = rgb(60, 110, 230),
	Hoteles = rgb(230, 70, 70),
	Ocio = rgb(230, 60, 60),
	Naturaleza = rgb(230, 80, 60),
	Gimnasios = rgb(40, 170, 90),
	Supermercados = rgb(160, 90, 240),
	CentrosComerciales = rgb(160, 90, 240),
	Restaurantes = rgb(245, 150, 40),
	Salud = rgb(230, 60, 90),
	Universidad = rgb(30, 180, 200),
	Puertos = rgb(30, 160, 200),
	Tren = rgb(70, 120, 230),
	Bus = rgb(70, 120, 230),
}
MapScreen.DefaultColor = rgb(50, 120, 230)

---------------------------------------------------------------------
-- Los 6 distritos (shared/CityPlan): nombre, subtítulo, icono y color
---------------------------------------------------------------------
export type DistrictRow = { Id: string, Name: string, Sub: string, Icon: string, Color: Color3, Center: Vector2 }
MapScreen.Districts = {} :: { DistrictRow }
for _, d in MapInfo.Districts do
	table.insert(MapScreen.Districts, { Id = d.Id, Name = d.Name, Sub = d.Theme, Icon = d.Icon, Color = d.Color, Center = d.Center })
end

-- Dónde va la etiqueta de cada distrito en el mapa (su centro; la del Centro, algo más al norte para no
-- tapar el Ayuntamiento ni la Estación Central)
local LABEL_OFFSET = { Centro = Vector2.new(0, -380) }
function MapScreen.labelAt(id: string, center: Vector2): Vector2
	return center + (LABEL_OFFSET[id] or Vector2.zero)
end

-- Lugares que salen en el mapa con su nombre siempre (los del dibujo de referencia). El resto de
-- lugares importantes salen como un punto con icono y su nombre si cabe.
MapScreen.Featured = {
	Aerodromo = true,
	Hotel = true,
	Ayuntamiento = true,
	GimnasioValmar = true,
	EstacionCentral = true,
	EstacionAutobuses = true,
	Marina = true,
	Aeropuerto = true,
	Puerto = true,
	Faro = true,
}

---------------------------------------------------------------------
-- Distrito de un sitio: el que lo contiene o, si cae entre dos (el río, la avenida del este, la
-- costa, el puerto), el más cercano a menos de NEAR studs. Si no, «Afueras de Valmar».
---------------------------------------------------------------------
local NEAR = 420
function MapScreen.districtNear(x: number, z: number): DistrictRow?
	local inside = MapInfo.districtAt(x, z)
	local best, bestDistance = nil, NEAR
	for _, d in MapInfo.Districts do
		if inside and d.Id == inside.Id then
			best, bestDistance = d, 0
			break
		end
		local poly = d.Poly
		for i = 1, #poly do
			local a, b = poly[i], poly[i % #poly + 1]
			local distance = CityPlan.segmentDistance(x, z, a[1], a[2], b[1], b[2])
			if distance < bestDistance then
				best, bestDistance = d, distance
			end
		end
	end
	if not best then
		return nil
	end
	for _, row in MapScreen.Districts do
		if row.Id == best.Id then
			return row
		end
	end
	return nil
end

function MapScreen.districtName(x: number, z: number): string
	local d = MapScreen.districtNear(x, z)
	return if d then d.Name else MapScreen.Outskirts
end

---------------------------------------------------------------------
-- «Lugares importantes»: un tipo que se repite sale UNA vez («Armería (3)») y al tocarlo marca el
-- más cercano. Orden alfabético (como en el dibujo: Aeropuerto, Aeródromo, Agencia…).
---------------------------------------------------------------------
export type Landmark = { Kind: MapInfo.Kind, Position: Vector3, District: string }
export type PlaceRow = {
	Kind: MapInfo.Kind,
	Title: string,
	Sub: string,
	Icon: string,
	Color: Color3,
	Places: { Landmark },
}
MapScreen.NearestHint = "Toca: te marca el más cercano"

function MapScreen.placeRows(landmarks: { Landmark }): { PlaceRow }
	local byKind: { [string]: { Landmark } } = {}
	local kinds: { MapInfo.Kind } = {}
	for _, place in landmarks do
		if place.Kind.Important then
			local list = byKind[place.Kind.Model]
			if not list then
				list = {}
				byKind[place.Kind.Model] = list
				table.insert(kinds, place.Kind)
			end
			table.insert(list, place)
		end
	end
	table.sort(kinds, function(a, b)
		return a.Name < b.Name
	end)
	local rows: { PlaceRow } = {}
	for _, kind in kinds do
		local list = byKind[kind.Model]
		local first = list[1]
		local single = #list == 1
		local district = if first.District ~= "" then first.District else MapScreen.districtName(first.Position.X, first.Position.Z)
		local category = MapLegend.categoryOf(kind.Model)
		table.insert(rows, {
			Kind = kind,
			Title = if single then kind.Name else ("%s (%d)"):format(kind.Name, #list),
			Sub = if single then district else MapScreen.NearestHint,
			Icon = kind.Icon,
			Color = (category and MapScreen.CategoryColors[category.Id]) or MapScreen.DefaultColor,
			Places = list,
		})
	end
	return rows
end

-- El sitio de la lista más cerca de `from` (o el primero, si no se sabe dónde estás)
function MapScreen.nearest(list: { Landmark }, from: Vector3?): Landmark
	if not from or #list == 1 then
		return list[1]
	end
	local best, bestDistance = list[1], math.huge
	for _, place in list do
		local d = Vector2.new(place.Position.X - from.X, place.Position.Z - from.Z).Magnitude
		if d < bestDistance then
			best, bestDistance = place, d
		end
	end
	return best
end

---------------------------------------------------------------------
-- Coordenadas «de verdad» de Valmar (como en un mapa: grados norte y oeste). Valmar Centro, en el
-- origen, está en 37.6289° N, 0.7307° W; 1 stud ≈ 0,28 m (shared/Config: 3,5 studs por metro).
---------------------------------------------------------------------
MapScreen.Origin = { Lat = 37.6289, Lon = -0.7307 }
local METERS_PER_STUD = 1 / 3.5
function MapScreen.coords(x: number, z: number): string
	local lat = MapScreen.Origin.Lat - z * METERS_PER_STUD / 111320
	local lon = MapScreen.Origin.Lon + x * METERS_PER_STUD / (111320 * math.cos(math.rad(MapScreen.Origin.Lat)))
	return ("%.4f° %s   %.4f° %s"):format(math.abs(lat), if lat >= 0 then "N" else "S", math.abs(lon), if lon >= 0 then "E" else "W")
end

---------------------------------------------------------------------
-- La imagen de la isla (scripts/map/render.py): 3x3 trozos de 1024x891 que cubren CityPlan.Bounds
-- (3072x2673 en total). Los ids los pone scripts/upload-map.sh en shared/MapTextureIds.
---------------------------------------------------------------------
MapScreen.Image = { Width = 3072, Height = 2673, Tiles = 3 }
export type Tile = { Name: string, Image: string, X0: number, Z0: number, X1: number, Z1: number }

-- Trozos con su sitio en el mundo. Si falta alguno, ninguno (el mapa se dibuja como antes).
function MapScreen.tiles(ids: { [string]: string }?): { Tile }
	local b = CityPlan.Bounds
	local I = MapScreen.Image
	local perPixel = (b.MaxX - b.MinX) / I.Width -- studs por píxel de la imagen
	local tw, th = I.Width / I.Tiles, I.Height / I.Tiles
	local out: { Tile } = {}
	for row = 0, I.Tiles - 1 do
		for col = 0, I.Tiles - 1 do
			local name = ("mapa_%d_%d"):format(row, col)
			local id = ids and ids[name]
			if type(id) ~= "string" or not string.match(id, "^rbxassetid://%d+$") then
				return {}
			end
			table.insert(out, {
				Name = name,
				Image = id,
				X0 = b.MinX + col * tw * perPixel,
				Z0 = b.MinZ + row * th * perPixel,
				X1 = b.MinX + (col + 1) * tw * perPixel,
				Z1 = b.MinZ + (row + 1) * th * perPixel,
			})
		end
	end
	return out
end

---------------------------------------------------------------------
-- Borde de un distrito redondeado (Chaikin): el plano tiene esquinas; en el mapa se ven como manchas
-- suaves, como en el dibujo. Solo para dibujar (MapInfo.districtAt sigue usando el polígono exacto).
---------------------------------------------------------------------
function MapScreen.smooth(poly: { { number } }, passes: number?): { { number } }
	local points = poly
	for _ = 1, passes or 2 do
		local out = {}
		for i = 1, #points do
			local a, b = points[i], points[i % #points + 1]
			table.insert(out, { a[1] * 0.75 + b[1] * 0.25, a[2] * 0.75 + b[2] * 0.25 })
			table.insert(out, { a[1] * 0.25 + b[1] * 0.75, a[2] * 0.25 + b[2] * 0.75 })
		end
		points = out
	end
	return points
end

---------------------------------------------------------------------
-- Dónde va cada pieza
---------------------------------------------------------------------
export type Rect = { X: number, Y: number, W: number, H: number }
export type Layout = {
	Scale: number, -- UIScale de la pantalla (píxeles por unidad del lienzo)
	Canvas: Vector2, -- tamaño del lienzo (viewport / Scale)
	Wide: boolean, -- paneles abiertos a los lados (si no, pestañas)
	Rects: { [string]: Rect }, -- Logo, Close, Clock, Compass, Zoom, Location, Hint, ClearRoute,
	-- Districts, Places y, en pantallas pequeñas, TabDistricts y TabPlaces
	Map: Rect, -- dónde se encaja la isla entera con el zoom 1
	Row: number, -- alto de cada fila de las listas
	Text: { Title: number, Sub: number, Header: number }, -- tamaños de letra
	Fixed: { string }, -- las piezas que se ven siempre (no se pueden pisar entre ellas)
}

MapScreen.MinScale = 0.72 -- (en el móvil apaisado: letras de 11 pt como poco)
local MARGIN = 14
local BUTTON = 56 -- botones redondos (+, −, ◎, ✖): ≥ 40 pt en el móvil
local TOPBAR = 250 -- hueco de los botones de Roblox (arriba a la izquierda, en píxeles) si no se sabe
local TOPBAR_H = 58 -- y su alto (píxeles)

export type LayoutOptions = { TopbarRight: number? }

function MapScreen.layout(viewport: Vector2, options: LayoutOptions?): Layout
	local opts = options or {}
	local scale = math.clamp(math.min(viewport.X / 1650, viewport.Y / 760), MapScreen.MinScale, 1.25)
	local W, H = viewport.X / scale, viewport.Y / scale
	local wide = W >= 1500 and H >= 700
	local topbar = (opts.TopbarRight or TOPBAR) / scale -- (en píxeles: pasa al lienzo)
	local topbarH = TOPBAR_H / scale
	local R: { [string]: Rect } = {}
	local function rect(name: string, x: number, y: number, w: number, h: number)
		R[name] = { X = x, Y = y, W = w, H = h }
	end

	local row, text
	if wide then
		local top = math.max(84, topbarH + 10)
		rect("Logo", topbar + 8, 10, 330, 62)
		rect("Close", W - MARGIN - BUTTON, 12, BUTTON, BUTTON)
		rect("Clock", W - MARGIN - BUTTON - 12 - 240, 14, 240, 52)
		row = 68
		local leftH = 56 + #MapScreen.Districts * row + 12
		rect("Districts", MARGIN, top, 340, leftH)
		rect("Location", MARGIN, H - MARGIN - 74, 340, 74)
		rect("Hint", W - MARGIN - 420, H - MARGIN - 54, 420, 54)
		local placesTop = math.max(top, R.Clock.Y + R.Clock.H + 14)
		rect("Places", W - MARGIN - 330, placesTop, 330, R.Hint.Y - 12 - placesTop)
		-- La brújula, arriba, a la izquierda de la columna de los lugares (como en el dibujo)
		rect("Compass", R.Places.X - 14 - 124, 6, 124, 124)
		local zoomH = BUTTON * 3 + 12 * 2
		rect("Zoom", R.Places.X - 14 - BUTTON, R.Hint.Y - 14 - zoomH, BUTTON, zoomH)
		rect("ClearRoute", (W - 210) / 2, H - MARGIN - 52, 210, 52)
		R.Map = { X = R.Districts.X + R.Districts.W + 10, Y = 10, W = R.Zoom.X - 10 - (R.Districts.X + R.Districts.W + 10), H = H - 20 }
		text = { Title = 19, Sub = 15, Header = 30 }
	else
		rect("Close", W - MARGIN - BUTTON, 8, BUTTON, BUTTON)
		rect("Clock", W - MARGIN - BUTTON - 10 - 206, 12, 206, 48)
		-- El logo, a la derecha de los botones de Roblox; si no cabe antes de la hora, debajo de ellos
		local space = R.Clock.X - 12 - (topbar + 8)
		if space >= 240 then
			rect("Logo", topbar + 8, 8, math.min(300, space), 56)
		else
			rect("Logo", MARGIN, topbarH + 6, 300, 56)
		end
		rect("Compass", W - MARGIN - 92, R.Close.Y + R.Close.H + 10, 92, 92)
		local zoomH = BUTTON * 3 + 10 * 2
		rect("Zoom", W - MARGIN - BUTTON, R.Compass.Y + R.Compass.H + 12, BUTTON, zoomH)
		local tabY = math.max(R.Logo.Y + R.Logo.H + 10, topbarH + 8)
		rect("TabDistricts", MARGIN, tabY, 158, BUTTON)
		rect("TabPlaces", MARGIN + 158 + 10, tabY, 158, BUTTON)
		rect("Location", MARGIN, H - MARGIN - 66, 300, 66)
		local hintW = math.min(400, W - MARGIN * 2 - 300 - 220 - 40)
		if hintW >= 300 then
			rect("Hint", W - MARGIN - hintW, H - MARGIN - 50, hintW, 50)
		end
		-- «Quitar ruta»: abajo, entre la tarjeta del sitio y la pista (o pegado a la tarjeta)
		local left = R.Location.X + R.Location.W + 14
		local right = if R.Hint then R.Hint.X - 14 else W - MARGIN - BUTTON - 14
		rect("ClearRoute", math.max(left, (left + right) / 2 - 100), H - MARGIN - 50, math.min(200, right - left), 50)
		local panelY = R.TabDistricts.Y + R.TabDistricts.H + 8
		local panelH = R.Location.Y - 10 - panelY
		rect("Districts", MARGIN, panelY, 380, panelH)
		rect("Places", MARGIN, panelY, 380, panelH)
		R.Map = { X = MARGIN, Y = R.TabDistricts.Y, W = R.Zoom.X - 10 - MARGIN, H = R.Location.Y - 6 - R.TabDistricts.Y }
		row = 68
		text = { Title = 20, Sub = 16, Header = 24 }
	end
	local fixed = { "Logo", "Close", "Clock", "Compass", "Zoom", "Location", "ClearRoute" }
	if R.Hint then
		table.insert(fixed, "Hint")
	end
	if wide then
		table.insert(fixed, "Districts")
		table.insert(fixed, "Places")
	else
		table.insert(fixed, "TabDistricts")
		table.insert(fixed, "TabPlaces")
	end
	local map = R.Map
	R.Map = nil
	return {
		Scale = scale,
		Canvas = Vector2.new(W, H),
		Wide = wide,
		Rects = R,
		Map = map,
		Row = row,
		Text = text,
		Fixed = fixed,
	}
end

-- Tamaño de los iconos y etiquetas del mapa con el zoom 1 (en pantallas pequeñas, algo menores)
function MapScreen.labelScale(layout: Layout): number
	return if layout.Wide then 1 else 0.8
end

function MapScreen.overlaps(a: Rect, b: Rect): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end

function MapScreen.inside(a: Rect, canvas: Vector2): boolean
	return a.X >= 0 and a.Y >= 0 and a.X + a.W <= canvas.X + 0.01 and a.Y + a.H <= canvas.Y + 0.01
end

return MapScreen
