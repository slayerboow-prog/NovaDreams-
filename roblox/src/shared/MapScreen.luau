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
--   MapScreen.toArt(x, z, y?) / MapScreen.toWorld(u, v) -> del mundo a la imagen y vuelta (exacto: la cámara
--                                                       del render, shared/MapProjection)
--   MapScreen.placeLabels(items, obstáculos)         -> etiquetas sin pisarse
--   MapScreen.smooth(poly)                           -> el borde de un distrito, redondeado (para dibujarlo)

local CityPlan = require(script.Parent.CityPlan)
local MapInfo = require(script.Parent.MapInfo)
local MapLegend = require(script.Parent.MapLegend)
local MapProjection = require(script.Parent.MapProjection)

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
	Sea = Color3.fromRGB(MapProjection.Sea[1], MapProjection.Sea[2], MapProjection.Sea[3]), -- el fondo: el azul del borde de la imagen
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
-- La imagen de la isla: la ciudad de verdad en 3D (scripts/map/blender_render.py, Blender/Cycles) con
-- una cámara ortográfica inclinada. Sus coordenadas son píxeles de la imagen (0..Width, 0..Height), en
-- Cols x Rows trozos ≤ 1024 («isla_<fila>_<columna>»: los sube scripts/upload-map.sh a shared/MapTextureIds).
---------------------------------------------------------------------
MapScreen.Art = {
	AX0 = 0,
	AY0 = 0,
	AX1 = MapProjection.Width,
	AY1 = MapProjection.Height,
	Width = MapProjection.Width,
	Height = MapProjection.Height,
	Cols = MapProjection.Cols,
	Rows = MapProjection.Rows,
}
MapScreen.IslandBox = MapProjection.IslandBox -- la isla en la imagen (lo que se encaja con el zoom 1)
export type Tile = { Name: string, Image: string, X0: number, Y0: number, X1: number, Y1: number }

-- Trozos con su sitio en la imagen. Si falta alguno, ninguno (el mapa se dibuja por código, como antes).
function MapScreen.tiles(ids: { [string]: string }?): { Tile }
	local A = MapScreen.Art
	local tw, th = A.Width / A.Cols, A.Height / A.Rows
	local out: { Tile } = {}
	for row = 0, A.Rows - 1 do
		for col = 0, A.Cols - 1 do
			local name = ("isla_%d_%d"):format(row, col)
			local id = ids and ids[name]
			if type(id) ~= "string" or not string.match(id, "^rbxassetid://%d+$") then
				return {}
			end
			table.insert(out, { Name = name, Image = id, X0 = col * tw, Y0 = row * th, X1 = (col + 1) * tw, Y1 = (row + 1) * th })
		end
	end
	return out
end

-- Del mundo (X, Z y la altura Y, 0 = el suelo) al píxel de la imagen: la proyección EXACTA de la cámara
-- con la que se hizo (shared/MapProjection). La usan tu flecha, los lugares, la ruta del GPS, los
-- distritos y las misiones. Y la vuelta (del píxel al suelo): los toques e «Ir aquí».
local TILT = math.rad(MapProjection.Tilt)
local SPP = MapProjection.OrthoWidth / MapProjection.Width -- studs por píxel
function MapScreen.toArt(x: number, z: number, y: number?): Vector2
	local s = -z * math.cos(TILT) + (y or 0) * math.sin(TILT)
	return Vector2.new((x - MapProjection.CX) / SPP + MapProjection.Width / 2, MapProjection.Height / 2 - (s - MapProjection.CS) / SPP)
end
function MapScreen.toWorld(u: number, v: number): Vector2
	local x = (u - MapProjection.Width / 2) * SPP + MapProjection.CX
	local s = (MapProjection.Height / 2 - v) * SPP + MapProjection.CS
	return Vector2.new(x, -s / math.cos(TILT))
end

-- Etiquetas sin pisarse: cada una (centro X, Y y tamaño W, H) va a su sitio o, si pisa a otra o a un
-- obstáculo (un lugar con nombre), al primer hueco libre de alrededor (arriba, abajo, a los lados…).
-- Devuelve { [Id] = { X, Y, W, H } }.
export type Box = { X0: number, Y0: number, X1: number, Y1: number }
export type LabelItem = { Id: string, X: number, Y: number, W: number, H: number, Bounds: Box? }
-- Huecos que se prueban (en anchos y altos de la etiqueta), del más cercano al más lejano
local OFFSETS = {}
for _, dx in { 0, -0.25, 0.25, -0.5, 0.5 } do
	for _, dy in { 0, -0.6, 0.6, -1.1, 1.1, -1.6, 1.6 } do
		table.insert(OFFSETS, { dx, dy })
	end
end
table.sort(OFFSETS, function(a, b)
	return (a[1] * 2.5) ^ 2 + a[2] ^ 2 < (b[1] * 2.5) ^ 2 + b[2] ^ 2
end)

function MapScreen.placeLabels(items: { LabelItem }, obstacles: { Box }?, bounds: Box?): { [string]: LabelItem }
	local taken: { Box } = table.clone(obstacles or {})
	local out: { [string]: LabelItem } = {}
	local function overlap(b: Box): number
		local total = 0
		for _, o in taken do
			local w = math.min(b.X1, o.X1) - math.max(b.X0, o.X0)
			local h = math.min(b.Y1, o.Y1) - math.max(b.Y0, o.Y0)
			if w > 0 and h > 0 then
				total += w * h
			end
		end
		return total
	end
	for _, item in items do
		local best, bestOverlap = nil, math.huge
		for _, k in OFFSETS do
			local x, y = item.X + k[1] * item.W, item.Y + k[2] * item.H
			local box = { X0 = x - item.W / 2 - 4, Y0 = y - item.H / 2 - 4, X1 = x + item.W / 2 + 4, Y1 = y + item.H / 2 + 4 }
			-- (lo que se sale de la zona permitida cuenta como pisado)
			local o = overlap(box)
			local area = item.Bounds or bounds
			if area then
				local inX = math.max(0, math.min(box.X1, area.X1) - math.max(box.X0, area.X0))
				local inY = math.max(0, math.min(box.Y1, area.Y1) - math.max(box.Y0, area.Y0))
				o += (box.X1 - box.X0) * (box.Y1 - box.Y0) - inX * inY
			end
			if o < bestOverlap then
				best, bestOverlap = { Id = item.Id, X = x, Y = y, W = item.W, H = item.H }, o
				if o == 0 then
					break
				end
			end
		end
		local b = best :: LabelItem
		out[item.Id] = b
		table.insert(taken, { X0 = b.X - b.W / 2, Y0 = b.Y - b.H / 2, X1 = b.X + b.W / 2, Y1 = b.Y + b.H / 2 })
	end
	return out
end

-- Las etiquetas de los distritos con el zoom 1, ya apartadas (sin pisarse entre ellas ni tapar los
-- lugares con nombre). toPx: del mundo (x, z) al sitio donde se dibuja; unit: cuánto mide ahí una unidad
-- del lienzo (MapUI: 1, la capa; el montaje de docs/mapa: píxeles de la imagen). Devuelve { [Id] = { X, Y, W, H } }.
function MapScreen.districtLabels(layout: Layout, landmarks: { Landmark }, toPx: (number, number) -> Vector2, unit: number): { [string]: LabelItem }
	local k = MapScreen.labelScale(layout) * unit
	local obstacles: { Box } = {}
	local seen: { [string]: boolean } = {}
	for _, place in landmarks do
		if MapScreen.Featured[place.Kind.Model] and not seen[place.Kind.Model] then
			seen[place.Kind.Model] = true
			local q = toPx(place.Position.X, place.Position.Z)
			local half = math.max(17, math.min(80, (utf8.len(place.Kind.Name) or 10) * 3.8)) * k
			table.insert(obstacles, { X0 = q.X - half, Y0 = q.Y - 17 * k, X1 = q.X + half, Y1 = q.Y + 36 * k })
		end
	end
	local items: { LabelItem } = {}
	for _, d in MapInfo.Districts do
		local at = MapScreen.labelAt(d.Id, d.Center)
		local q = toPx(at.X, at.Y)
		-- (cada etiqueta, sobre su distrito: la caja de su polígono, con un poco de margen)
		local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
		for _, p in d.Poly do
			local c = toPx(p[1], p[2])
			x0, y0, x1, y1 = math.min(x0, c.X), math.min(y0, c.Y), math.max(x1, c.X), math.max(y1, c.Y)
		end
		local w, h = (46 + 18 + math.max(#d.Name * 10.5, #d.Theme * 7.2)) * k, 46 * k
		local mx, my = math.max(0, (w - (x1 - x0)) / 2) + 20 * k, math.max(0, (h - (y1 - y0)) / 2) + 10 * k
		table.insert(items, { Id = d.Id, X = q.X, Y = q.Y, W = w, H = h, Bounds = { X0 = x0 - mx, Y0 = y0 - my, X1 = x1 + mx, Y1 = y1 + my } })
	end
	return MapScreen.placeLabels(items, obstacles)
end

-- Píxeles de la imagen por unidad del lienzo con el zoom 1 (la isla encajada en el hueco libre)
function MapScreen.fitScale(layout: Layout): number
	local box, area = MapScreen.IslandBox, layout.Map
	return math.max((box.X1 - box.X0) / math.max(area.W, 100), (box.Y1 - box.Y0) / math.max(area.H, 100))
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
	-- Paneles a los lados (como el dibujo) si caben: también en el móvil apaisado grande (932x430)
	local wide = W >= 1150 and H >= 580
	local topbar = (opts.TopbarRight or TOPBAR) / scale -- (en píxeles: pasa al lienzo)
	local topbarH = TOPBAR_H / scale
	local R: { [string]: Rect } = {}
	local function rect(name: string, x: number, y: number, w: number, h: number)
		R[name] = { X = x, Y = y, W = w, H = h }
	end

	local row, text
	if wide then
		-- Medidas en proporción a la pantalla (el dibujo es 1846x852: paneles de ~1/5 del ancho)
		local panelW = math.clamp(W * 0.2, 250, 330)
		local top = math.max(84, topbarH + 10)
		rect("Logo", topbar + 8, 10, math.min(330, panelW + 10), 62)
		rect("Close", W - MARGIN - BUTTON, 12, BUTTON, BUTTON)
		local clockW = 228
		rect("Clock", W - MARGIN - BUTTON - 12 - clockW, 14, clockW, 52)
		local cardH = if H < 700 then 64 else 74
		rect("Location", MARGIN, H - MARGIN - cardH, panelW, cardH)
		local hintW = math.min(420, W * 0.32)
		rect("Hint", W - MARGIN - hintW, H - MARGIN - 54, hintW, 54)
		local placesTop = math.max(top, R.Clock.Y + R.Clock.H + 14)
		rect("Places", W - MARGIN - panelW, placesTop, panelW, R.Hint.Y - 12 - placesTop)
		-- Distritos: las 6 filas caben siempre (sin desplazar)
		local available = R.Location.Y - 10 - top - 56 - 12
		row = math.clamp(math.floor(available / #MapScreen.Districts), 54, 68)
		rect("Districts", MARGIN, top, panelW, 56 + #MapScreen.Districts * row + 12)
		-- La brújula, arriba, a la izquierda de la hora y de la columna de los lugares (como en el dibujo)
		local size = math.clamp(H * 0.17, 90, 124)
		rect("Compass", math.min(R.Clock.X - 12 - size, R.Places.X - 14 - size), 6, size, size)
		local zoomH = BUTTON * 3 + 12 * 2
		rect("Zoom", R.Places.X - 14 - BUTTON, R.Hint.Y - 14 - zoomH, BUTTON, zoomH)
		rect("ClearRoute", (W - 210) / 2, H - MARGIN - 52, 210, 52)
		-- La isla, en el hueco libre: entre los paneles, sin llegar a + / − / ◎, por debajo de la brújula y por
		-- encima de la pista (así nada tapa el aeródromo, el puerto deportivo ni la isla del faro). El mar
		-- sigue por debajo de todo hasta los bordes de la pantalla
		local mapX = R.Districts.X + R.Districts.W + 6
		local mapY = R.Compass.Y + R.Compass.H - 16
		R.Map = { X = mapX, Y = mapY, W = R.Zoom.X - 6 - mapX, H = math.min(R.Hint.Y, R.Location.Y) - 6 - mapY }
		text = if row < 62 then { Title = 16, Sub = 15, Header = 26 } else { Title = 19, Sub = 15, Header = 30 }
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
		-- (la isla, a toda la pantalla: las pestañas y los botones flotan encima, sobre el mar)
		R.Map = { X = 0, Y = 0, W = W, H = H }
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
	-- (en el móvil la isla se ve más pequeña: etiquetas algo menores, como en el dibujo)
	return if layout.Wide and layout.Scale > 0.8 then 1 else 0.8
end

function MapScreen.overlaps(a: Rect, b: Rect): boolean
	return a.X < b.X + b.W and b.X < a.X + a.W and a.Y < b.Y + b.H and b.Y < a.Y + a.H
end

function MapScreen.inside(a: Rect, canvas: Vector2): boolean
	return a.X >= 0 and a.Y >= 0 and a.X + a.W <= canvas.X + 0.01 and a.Y + a.H <= canvas.Y + 0.01
end

return MapScreen
