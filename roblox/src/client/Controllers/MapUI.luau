-- MapUI (cliente): el mapa de Valmar, con el estilo del mapa ilustrado de la ciudad.
--   * Minimapa redondo arriba a la derecha (pegado a la esquina, UI/HudLayout): aro brillante con la N,
--     marcas de los puntos cardinales, botones + y − para acercar, el sol (o la luna) al lado y, dentro,
--     distritos de colores, calles, mar, lugares, tu flecha, tu objetivo (★), el sitio que marques (📍)
--     y los demás jugadores. Si el objetivo está lejos, se queda en el borde señalando hacia dónde ir.
--   * Mapa grande (botón "Mapa", el botón del mapa del minimapa o la tecla M): pantalla entera como el dibujo
--     de referencia (docs/mapa/comparacion.png). Dónde va cada pieza lo dice shared/MapScreen.layout:
--     logo HEROES OF HISTORY, «Distritos» (tocar = centrar), la isla vista desde arriba (la imagen de la
--     ciudad de verdad, shared/MapTextureIds, o el dibujo por código si aún no está subida) con el borde
--     que brilla y la etiqueta de cada distrito, los lugares, brújula, hora y tiempo, «Lugares importantes»
--     (tocar = ruta del GPS; mantener = tarjeta con más datos) y la leyenda, + / − / ◎, «dónde estás» con
--     coordenadas y la pista. En pantallas pequeñas los dos paneles se recogen en pestañas.
--     Se mueve arrastrando y se acerca con la rueda, pellizcando con dos dedos o con + y −.
--   * 🏠 Casa: tu casa (y la de tu familia, «Casa familiar», si tienes otra tuya) sale SIEMPRE en los
--     dos mapas, con cualquier filtro; en el minimapa, si está lejos, en el borde señalando hacia ella.
--     Las posiciones las pone el servidor (atributos FamilyHomePos y OwnHomePos).
--   * Leyenda por categorías (shared/MapLegend): «🏋️ Gimnasios (7)», «🛒 Supermercados (4)»… Tocar
--     una oculta o muestra todos sus lugares en los dos mapas; se guarda con la partida (MapFilters).
-- GPS (Controllers/Gps): la ruta hasta tu destino se dibuja en los dos mapas como una línea que brilla
-- por las calles. En el mapa grande, mantén pulsado en cualquier sitio para "Ir aquí" y "Quitar ruta" la quita.
-- Lee las calles de ReplicatedStorage.Ambient.Roads, las zonas de ReplicatedStorage.MapZones y los lugares
-- de ReplicatedStorage.MapLandmarks (los publica el servidor), así que se adapta solo si el mapa cambia.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local GameClock = require(ReplicatedStorage.Shared.GameClock) -- (la hora del juego: GameClock.hour())
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local MapLegend = require(ReplicatedStorage.Shared.MapLegend)
local MapScreen = require(ReplicatedStorage.Shared.MapScreen)
local MapTextureIds = require(ReplicatedStorage.Shared.MapTextureIds)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Images = require(ReplicatedStorage.Shared.Images)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Airport = require(ReplicatedStorage.Shared.Airport)
local Rail = require(ReplicatedStorage.Shared.Rail)
local Tefra = require(ReplicatedStorage.Shared.Cosmos.Tefra)
local TefraCity = require(ReplicatedStorage.Shared.Cosmos.TefraCity)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local ServerWait = require(script.Parent.Parent.UI.ServerWait)
local Gps = require(script.Parent.Gps)
local CanonMarkers = require(script.Parent.CanonMarkers)
local CityErrands = require(script.Parent.CityErrands)

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local MapUI = {}

local player = Players.LocalPlayer

local MINI_SIZE = HudLayout.Sizes.Minimap
local MINI_ZOOMS = { 0.55, 0.8, 1.2, 1.8 } -- acercar / alejar el minimapa (+ y −)
local MINI_SCALE = 2.6 -- studs por píxel en el minimapa
local ROAD_WIDTH = 22 -- ancho aproximado de una calle (studs)
local LAND = rgb(104, 160, 88)
local SEA_TOP = rgb(52, 140, 210)
local SEA_BOTTOM = rgb(26, 92, 170)
local SAND = rgb(236, 214, 160)
local ROAD = rgb(236, 236, 228)
local TARGET = C.Gold
local OTHERS = rgb(90, 180, 255)
local WAYPOINT = rgb(255, 80, 90)

-- Mapa grande: dónde va cada pieza según la pantalla (shared/MapScreen.layout)
local screen: MapScreen.Layout = MapScreen.layout(Vector2.new(1920, 1080))

type Road = { A: Vector3, B: Vector3, Width: number }
type Zone = { Name: string, Center: Vector3 }
type Landmark = { Kind: MapInfo.Kind, Position: Vector3, District: string }
type Layer = {
	Frame: Frame,
	Scale: number,
	Min: Vector2,
	Me: GuiObject,
	Target: TextLabel,
	Waypoint: TextLabel,
	Dots: { [Player]: Frame },
	Icons: { { Holder: GuiObject, Kind: string, MinZoom: number } }, -- MinZoom: desde qué zoom se ve (mapa grande)
	Shown: { [string]: boolean }, -- tipos de lugar que ya tienen uno a la vista con el zoom 1
	PinRects: { { Rect: Rect, Model: string } }, -- los lugares con nombre con el zoom 1 (sus nombres no los tapan)
	Scalers: { UIScale },
	Keep: number, -- la escala que llevan ahora los Scalers (según el zoom)
	Labels: { Rect }, -- dónde ya hay un nombre de lugar (para no ponerlos unos encima de otros)
	Canon: { [string]: TextLabel }, -- misiones canónicas pendientes (❗ dorado)
	Homes: { [string]: Frame }, -- 🏠 tus casas (siempre visibles)
	Outlines: { { Frame: Frame, Length: number, Thickness: number } }, -- bordes de los distritos (mapa grande)
	Image: boolean, -- la isla es la imagen de verdad (shared/MapTextureIds) y no el dibujo por código
	OutlineZoom: number?, -- con qué zoom se puso el grosor de los bordes
}

local roads: { Road } = {}
local zones: { Zone } = {}
local landmarks: { Landmark } = {}
local boundsMin = MapInfo.BoundsMin
local boundsMax = MapInfo.BoundsMax

local gui: ScreenGui
local bigGui: ScreenGui
local miniHolder: Frame
local miniLayer: Layer
local zoneLabel: TextLabel
local big: Frame
local holder: Frame
local bigLayer: Layer?
local bigOpen = false
local bigScale: UIScale
local hidden: { [string]: boolean } = {} -- categorías (MapLegend) ocultas desde la leyenda
local refreshLegendRows: () -> () = function() end

local waypoint: { Position: Vector3, Name: string }? = nil
local zoom = 1
local pan = Vector2.zero
local holderSize = Vector2.new(800, 600)
local refreshWaypointList: () -> () = function() end
local MC = MapScreen.Colors
local overlays: { [string]: GuiObject } = {} -- las piezas de MapScreen.layout, por su nombre
local headers: { TextLabel } = {}
local drawerOpen: string? = nil -- en pantallas pequeñas: el panel abierto («Districts» o «Places»)
local refreshDrawers: () -> () = function() end
local updateHud: () -> () = function() end -- la hora, el tiempo y «dónde estás» (mientras está abierto)
local clearRouteButton: GuiObject? = nil

---------------------------------------------------------------------
-- Datos
---------------------------------------------------------------------

local function loadData()
	-- Las calles, barrios y lugares los publica el servidor al arrancar: se espera a que acabe (antes,
	-- 10 s y sin ellos para toda la partida en un servidor recién abierto)
	ServerWait.ready()
	local ambient = ReplicatedStorage:WaitForChild("Ambient", 30)
	local roadFolder = ambient and ambient:FindFirstChild("Roads")
	if roadFolder then
		for _, config in roadFolder:GetChildren() do
			local a, b = config:GetAttribute("A"), config:GetAttribute("B")
			if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
				table.insert(roads, { A = a, B = b, Width = config:GetAttribute("Width") or ROAD_WIDTH })
			end
		end
	end
	local zoneFolder = ServerWait.child(ReplicatedStorage, "MapZones")
	if zoneFolder then
		for _, config in zoneFolder:GetChildren() do
			local name, center = config:GetAttribute("ZoneName"), config:GetAttribute("Center")
			if type(name) == "string" and typeof(center) == "Vector3" then
				table.insert(zones, { Name = name, Center = center })
			end
		end
	end
	local landmarkFolder = ServerWait.child(ReplicatedStorage, "MapLandmarks")
	if landmarkFolder then
		for _, config in landmarkFolder:GetChildren() do
			local kind = MapInfo.KindByModel[config:GetAttribute("Kind") or ""]
			local position = config:GetAttribute("Position")
			if kind and typeof(position) == "Vector3" then
				table.insert(landmarks, { Kind = kind, Position = position, District = config:GetAttribute("District") or "" })
			end
		end
	end
end

-- Barrio más cercano a una posición (si estás a menos de 650 studs de él)
local function zoneAt(position: Vector3): string?
	local best, bestDistance = nil, 650
	for _, zone in zones do
		local d = Vector2.new(position.X - zone.Center.X, position.Z - zone.Center.Z).Magnitude
		if d < bestDistance then
			best, bestDistance = zone.Name, d
		end
	end
	return best
end

---------------------------------------------------------------------
-- Capa del mapa (mar, distritos, calles y lugares dibujados a una escala)
---------------------------------------------------------------------

-- El norte (−Z) queda arriba: X del mundo -> x de pantalla, Z del mundo -> y de pantalla
-- Dónde está alguien en el mapa: dentro de un edificio (salas en el cielo) es la puerta de ese
-- edificio en la calle, no la sala. Devuelve algo con Position y CFrame, como la pieza.
local function mapRoot(who: Player, root: BasePart?): any
	local door = who:GetAttribute("InteriorDoor")
	if root and typeof(door) == "Vector3" then
		return { Position = door, CFrame = CFrame.new(door) * root.CFrame.Rotation }
	end
	return root
end

local function toPixel(layer: Layer, x: number, z: number): Vector2
	if layer.Image then
		-- Mapa grande con el arte: del mundo al dibujo (shared/MapWarp) y del dibujo a la capa
		local a = MapScreen.toArt(x, z)
		return Vector2.new((a.X - layer.Min.X) / layer.Scale, (a.Y - layer.Min.Y) / layer.Scale)
	end
	return Vector2.new((x - layer.Min.X) / layer.Scale, (z - layer.Min.Y) / layer.Scale)
end

-- Del dibujo (píxeles de la referencia) a la capa: para lo que ya viene pintado en el arte
local function artPixel(layer: Layer, u: number, v: number): Vector2
	return Vector2.new((u - layer.Min.X) / layer.Scale, (v - layer.Min.Y) / layer.Scale)
end

-- De un punto de la capa al mundo (X, Z): «Ir aquí»
local function toWorld(layer: Layer, point: Vector2): Vector3
	local source = layer.Min + point * layer.Scale
	if layer.Image then
		local w = MapScreen.toWorld(source.X, source.Y)
		return Vector3.new(w.X, 0, w.Y)
	end
	return Vector3.new(source.X, 0, source.Y)
end

local function rect(layer: Layer, name: string, x0: number, z0: number, x1: number, z1: number, color: Color3, z: number, radius: number?): Frame
	local a, b = toPixel(layer, x0, z0), toPixel(layer, x1, z1)
	local frame = create("Frame", {
		Name = name,
		Position = UDim2.fromOffset(a.X, a.Y),
		Size = UDim2.fromOffset(b.X - a.X, b.Y - a.Y),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = layer.Frame,
	})
	if radius then
		Theme.corner(radius).Parent = frame
	end
	return frame
end

local function circle(layer: Layer, name: string, x: number, z: number, radius: number, color: Color3, zIndex: number): Frame
	local p = toPixel(layer, x, z)
	local d = radius * 2 / layer.Scale
	return create("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = UDim2.fromOffset(d, d),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = zIndex,
		Parent = layer.Frame,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
end

-- Cosas que no deben crecer tanto al acercar el mapa llevan un UIScale propio.
-- Nace ya con la escala del zoom actual (si no, un marcador nuevo sale enorme hasta que se mueve
-- el zoom) y se quita de la lista al destruirse (si no, la lista crece para siempre)
local function keepSize(layer: Layer, object: GuiObject)
	local s = create("UIScale", { Scale = layer.Keep, Parent = object })
	table.insert(layer.Scalers, s)
	object.Destroying:Connect(function()
		local i = table.find(layer.Scalers, s)
		if i then
			table.remove(layer.Scalers, i)
		end
	end)
end

local function marker(layer: Layer, text: string, color: Color3, size: number, z: number): TextLabel
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		Text = text,
		TextSize = size,
		Font = Theme.FontBold,
		TextColor3 = color,
		TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = z,
		Parent = layer.Frame,
	})
	keepSize(layer, label)
	return label
end

local function setWaypoint(place: { Position: Vector3, Name: string }?)
	if waypoint and place and waypoint.Name == place.Name and waypoint.Position == place.Position then
		waypoint = nil -- pulsar otra vez el mismo sitio lo desmarca
	else
		waypoint = place
	end
	-- El GPS lleva hasta el sitio marcado
	Gps.setManual(if waypoint then waypoint.Position else nil, if waypoint then waypoint.Name else nil)
	refreshWaypointList()
end

local dragMoved = false
local homeIcon: (Layer, string, boolean) -> Frame
local HOLD = 0.45 -- segundos con el dedo encima = «ver más» (en vez de marcar la ruta)
local pinPressed = false -- se ha pulsado un lugar: soltar no es «mantener pulsado en el mapa» (Ir aquí)
local showInfo: (string, Vector3, string?) -> () = function() end

local function landmarkIcon(layer: Layer, place: Landmark, detailed: boolean)
	local p = toPixel(layer, place.Position.X, place.Position.Z)
	local important = place.Kind.Important == true
	local featured = MapScreen.Featured[place.Kind.Model] == true
	local size = if detailed then (if featured then 34 elseif important then 28 else 22) else (if important then 18 else 14)
	local district = MapInfo.districtAt(place.Position.X, place.Position.Z)
	-- Mapa grande: círculo azul marino con borde blanco y el icono dentro (como en el dibujo).
	-- Minimapa: círculo blanco con el borde del color de su distrito.
	local icon = create(if detailed then "TextButton" else "Frame", {
		Name = place.Kind.Model,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = if detailed then MapScreen.Colors.Pin else Color3.new(1, 1, 1),
		BackgroundTransparency = if detailed then 0.04 else 0.15,
		BorderSizePixel = 0,
		ZIndex = if important then 5 else 4,
		Parent = layer.Frame,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", {
			Color = if detailed then Color3.new(1, 1, 1) elseif district then district.Color else rgb(60, 70, 90),
			Thickness = if detailed then 2 else 1.5,
			Transparency = if detailed then 0.1 else 0,
		}),
	})
	if icon:IsA("TextButton") then
		icon.Text = ""
		icon.AutoButtonColor = true
		local pressedAt = 0
		icon.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				pressedAt = os.clock()
				pinPressed = true
			end
		end)
		icon.Activated:Connect(function()
			if dragMoved then
				return
			end
			if pressedAt > 0 and os.clock() - pressedAt >= HOLD then
				showInfo(place.Kind.Name, place.Position, place.Kind.Icon) -- mantener: ver más
			else
				setWaypoint({ Position = place.Position, Name = place.Kind.Name })
			end
		end)
	end
	Theme.label({
		Size = UDim2.fromScale(1, 1),
		Text = place.Kind.Icon,
		TextSize = math.floor(size * 0.6),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = icon.ZIndex,
		Parent = icon,
	})
	-- Mapa grande: con toda la isla a la vista, solo los lugares del dibujo (uno de cada tipo: «Hotel»,
	-- «Gimnasio»…); al acercar salen los demás importantes y, más cerca, el resto. (Se leen mejor)
	local minZoom = 1
	if detailed then
		if featured and not layer.Shown[place.Kind.Model] then
			layer.Shown[place.Kind.Model] = true
		else
			minZoom = if important then 1.8 else 2.6
		end
	end
	-- El nombre: debajo; si ahí pisa otro nombre, una etiqueta de distrito u otro lugar con nombre, encima,
	-- a la derecha o a la izquierda; si no cabe en ningún sitio, sin nombre (mejor que ilegible)
	local k = if minZoom <= 1 then MapScreen.labelScale(screen) else 1 -- (tamaño con el zoom 1)
	local half = math.min(80, (utf8.len(place.Kind.Name) or #place.Kind.Name) * 3.8) * k -- (ancho aproximado del texto)
	local r, lh = size / 2 * k, 18 * k
	local candidates = {
		{ Rect.new(p.X - half, p.Y + r + 2, p.X + half, p.Y + r + lh), Vector2.new(0.5, 0), UDim2.new(0.5, 0, 1, 2) },
		{ Rect.new(p.X - half, p.Y - r - lh, p.X + half, p.Y - r - 2), Vector2.new(0.5, 1), UDim2.new(0.5, 0, 0, -2) },
		{ Rect.new(p.X + r + 3, p.Y - lh / 2, p.X + r + 3 + half * 2, p.Y + lh / 2), Vector2.new(0, 0.5), UDim2.new(1, 3, 0.5, 0) },
		{ Rect.new(p.X - r - 3 - half * 2, p.Y - lh / 2, p.X - r - 3, p.Y + lh / 2), Vector2.new(1, 0.5), UDim2.new(0, -3, 0.5, 0) },
	}
	local function clear(box: Rect): boolean
		if minZoom > 1 then
			return true
		end
		for _, other in layer.Labels do
			if box.Min.X < other.Max.X and other.Min.X < box.Max.X and box.Min.Y < other.Max.Y and other.Min.Y < box.Max.Y then
				return false
			end
		end
		for _, pin in layer.PinRects do
			local other = pin.Rect
			if pin.Model ~= place.Kind.Model and box.Min.X < other.Max.X and other.Min.X < box.Max.X and box.Min.Y < other.Max.Y and other.Min.Y < box.Max.Y then
				return false
			end
		end
		return true
	end
	local chosen = nil
	for _, candidate in candidates do
		if clear(candidate[1]) then
			chosen = candidate
			break
		end
	end
	if detailed and important and chosen then
		if minZoom <= 1 then
			table.insert(layer.Labels, chosen[1])
		end
		Theme.label({
			Name = "Title",
			AnchorPoint = chosen[2],
			Position = chosen[3],
			Size = UDim2.fromOffset(170, 16),
			Text = place.Kind.Name,
			TextSize = if featured then 14 else 12,
			Font = Theme.FontBold,
			TextStrokeTransparency = 0.1,
			TextStrokeColor3 = rgb(6, 14, 36),
			TextXAlignment = if chosen[2].X == 0 then Enum.TextXAlignment.Left elseif chosen[2].X == 1 then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center,
			ZIndex = icon.ZIndex,
			Parent = icon,
		})
	end
	keepSize(layer, icon)
	table.insert(layer.Icons, { Holder = icon, Kind = place.Kind.Model, MinZoom = minZoom })
end

-- 🏠 de una casa tuya: círculo blanco con borde naranja y, en el mapa grande, su nombre debajo
local HOME_COLOR = rgb(255, 150, 40)
homeIcon = function(layer: Layer, name: string, detailed: boolean): Frame
	local size = if detailed then 34 else 24
	local icon = create(if detailed then "TextButton" else "Frame", {
		Name = "Home",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 8,
		Parent = layer.Frame,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = HOME_COLOR, Thickness = if detailed then 3 else 2.5 }),
	})
	if icon:IsA("TextButton") then
		icon.Text = ""
		icon.Activated:Connect(function()
			if not dragMoved then
				local family = player:GetAttribute("FamilyHomePos")
				local own = player:GetAttribute("OwnHomePos")
				for _, home in MapLegend.homeMarkers(family, own) do
					if home.Name == (icon:FindFirstChild("Title") :: TextLabel).Text then
						setWaypoint({ Position = home.Position, Name = home.Name })
					end
				end
			end
		end)
	end
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = MapLegend.Home.Icon, TextSize = math.floor(size * 0.66), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8, Parent = icon })
	Theme.label({
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.fromOffset(120, 16),
		Text = name,
		TextSize = if detailed then 14 else 11,
		Font = Theme.FontBold,
		TextColor3 = rgb(255, 214, 150),
		TextStrokeTransparency = 0.1,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = detailed,
		ZIndex = 8,
		Parent = icon,
	})
	keepSize(layer, icon)
	return icon
end

-- Lo que lleva cada capa encima: el 📍, la ★ del objetivo y tu flecha (Valmar y Tefra)
local function addMarkers(layer: Layer, detailed: boolean)
	layer.Waypoint = marker(layer, "📍", WAYPOINT, if detailed then 26 else 20, 7)
	layer.Target = marker(layer, "★", TARGET, if detailed then 26 else 20, 8)
	-- Tu flecha: grande, con borde blanco y sombra (se lee sobre cualquier color), y un cono suave
	-- que enseña hacia dónde mira la cámara. Dibujada con marcos ("▲" no se ve en algunos móviles).
	local size = if detailed then 48 else 40
	local me = create("Frame", {
		Name = "Me",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = 9,
		Parent = layer.Frame,
	})
	-- Cono de visión (tres rayos que se abren, cada vez más transparentes hacia fuera)
	local cone = create("Frame", { Name = "Cone", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8, Parent = me })
	for _, angle in { -22, 0, 22 } do
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.34, 1.25),
			Rotation = angle,
			BackgroundColor3 = rgb(150, 235, 255),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 8,
			Parent = cone,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.35) }),
		})
	end
	-- La flecha: sombra oscura detrás y dos barras gruesas con borde blanco
	local function arrow(parent: Instance, color: Color3, grow: number, z: number, stroke: boolean)
		for _, side in { -1, 1 } do
			create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5 + side * 0.13, 0, 0.47, 0),
				Size = UDim2.new(0.26, grow, 0.78, grow),
				Rotation = -side * 28,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				ZIndex = z,
				Parent = parent,
			}, {
				create("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
				if stroke then create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2.5 }) else nil,
			} :: any)
		end
	end
	local body = create("Frame", { Name = "Arrow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), BackgroundTransparency = 1, ZIndex = 9, Parent = me })
	arrow(body, Color3.new(0, 0, 0), 6, 9, false)
	for _, child in body:GetChildren() do
		(child :: Frame).BackgroundTransparency = 0.55
		(child :: Frame).Position += UDim2.fromOffset(1.5, 2)
	end
	arrow(body, rgb(70, 225, 120), 0, 10, true)
	keepSize(layer, me)
	layer.Me = me
end

local function buildLayer(parent: Instance, scale: number, detailed: boolean): Layer
	-- El arte de la isla (el dibujo del dueño, shared/MapTextureIds): si está, la capa va en píxeles del
	-- dibujo y todo lo del mundo pasa por la deformación (toPixel). Si no, el dibujo por código, en studs.
	local tiles = if detailed then MapScreen.tiles(MapTextureIds) else {}
	local art = MapScreen.Art
	local min = if #tiles > 0 then Vector2.new(art.AX0, art.AY0) else boundsMin
	local extent = (if #tiles > 0 then Vector2.new(art.AX1, art.AY1) - min else boundsMax - boundsMin) / scale
	local frame = create("Frame", {
		Name = "World",
		Size = UDim2.fromOffset(extent.X, extent.Y),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = if #tiles > 0 then 1 else 0,
		BorderSizePixel = 0,
		Parent = parent,
	}, { create("UIGradient", { Rotation = 90, Color = ColorSequence.new(SEA_TOP, SEA_BOTTOM) }) })
	local layer: Layer = {
		Frame = frame,
		Scale = scale,
		Min = min,
		Me = nil :: any,
		Target = nil :: any,
		Waypoint = nil :: any,
		Dots = {},
		Icons = {},
		Scalers = {},
		Keep = 1,
		Labels = {},
		Shown = {},
		PinRects = {},
		Canon = {},
		Homes = {},
		Outlines = {},
		Image = false,
	}
	-- El arte en trozos de 1024 como mucho (límite de Roblox). Hasta que se suban (scripts/upload-map.sh),
	-- el dibujo de siempre.
	layer.Image = #tiles > 0
	for _, tile in tiles do
		local a, c = artPixel(layer, tile.X0, tile.Y0), artPixel(layer, tile.X1, tile.Y1)
		create("ImageLabel", {
			Name = tile.Name,
			Position = UDim2.fromOffset(a.X, a.Y),
			-- (medio píxel de más: sin rayas entre trozos al acercar)
			Size = UDim2.fromOffset(c.X - a.X + 0.5, c.Y - a.Y + 0.5),
			BackgroundTransparency = 1,
			Image = Images.of(tile.Image), -- (si se subió como Decal, el id de su imagen: shared/Images)
			ScaleType = Enum.ScaleType.Stretch,
			ZIndex = 1,
			Parent = frame,
		})
	end
	local drawn = not layer.Image
	-- Isla: arena en la orilla y hierba dentro (franjas horizontales del polígono de la costa)
	-- (en el minimapa, franjas más gruesas: menos piezas que redibujar al moverse)
	local stripe = if detailed then math.max(24, scale * 3) else 64
	local b = CityPlan.Bounds
	local function fill(poly: { { number } }, color: Color3, inset: number, transparency: number, z: number)
		for zz = b.MinZ, b.MaxZ, stripe do
			for _, span in CityPlan.spans(poly, zz + stripe / 2) do
				local x0, x1 = span[1] + inset, span[2] - inset
				if x1 > x0 then
					rect(layer, "Fill", x0, zz, x1, zz + stripe + 0.5 * scale, color, z).BackgroundTransparency = transparency
				end
			end
		end
	end
	local function line(a: Vector2, c: Vector2, width: number, color: Color3, z: number, transparency: number?)
		local pa, pc = toPixel(layer, a.X, a.Y), toPixel(layer, c.X, c.Y)
		local d = pc - pa
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((pa.X + pc.X) / 2, (pa.Y + pc.Y) / 2),
			Size = UDim2.fromOffset(d.Magnitude + width, width),
			Rotation = math.deg(math.atan2(d.Y, d.X)),
			BackgroundColor3 = color,
			BackgroundTransparency = transparency or 0,
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = frame,
		})
	end
	if drawn then
		if detailed then
			fill(CityPlan.Coast, SAND, 0, 0, 1)
			fill(CityPlan.Coast, LAND, 70, 0, 1)
		else
			fill(CityPlan.Coast, LAND, 0, 0, 1)
		end
		for _, island in CityPlan.Islands do
			circle(layer, "Island", island.X, island.Z, island.R, SAND, 1)
			circle(layer, "IslandGrass", island.X, island.Z, island.R - 30, LAND, 1)
		end
		-- Aeropuerto (tierra ganada al mar) con su pista, y la pista del aeródromo de las Gaviotas
		do
			local L, R, S = Airport.Land, Airport.Runway, Airport.Strip
			rect(layer, "Airport", L.X0, L.Z0, L.X1, L.Z1, LAND, 1)
			rect(layer, "Runway", R.X0, R.Z - R.Width / 2, R.X1, R.Z + R.Width / 2, rgb(96, 98, 104), 3)
			rect(layer, "Runway", S.X0, S.Z - S.Width / 2, S.X1, S.Z + S.Width / 2, rgb(96, 98, 104), 3)
			local A, Ln = Airport.Access, Airport.Lane
			line(Vector2.new(A.X, A.Z0), Vector2.new(A.X, (Ln.Z0 + Ln.Z1) / 2), math.max(2, 24 / scale), ROAD, 3)
			line(Vector2.new(Ln.X0, (Ln.Z0 + Ln.Z1) / 2), Vector2.new(Ln.X1, (Ln.Z0 + Ln.Z1) / 2), math.max(2, 24 / scale), ROAD, 3)
		end
		-- Montañas (más oscuras, con la cima gris si es de roca)
		for _, m in CityPlan.Mountains do
			local ground = math.sqrt(math.max(0, m.R * m.R - (m.R - m.H) ^ 2))
			circle(layer, "Mountain", m.X, m.Z, ground, rgb(80, 128, 70), 1).BackgroundTransparency = 0.1
			if m.Rock then
				circle(layer, "Peak", m.X, m.Z, ground * 0.4, rgb(150, 144, 132), 1)
			end
		end
	end
	-- Distritos. Minimapa: borde fino. Mapa grande: tinte suave y un borde que brilla (tres trazos: halo
	-- ancho y transparente, trazo de color y filo claro), redondeado como en el dibujo. El grosor no
	-- crece al acercar (applyView lo corrige: layer.Outlines).
	for _, d in MapInfo.Districts do
		if not detailed then
			for k = 1, #d.Poly do
				local p1, p2 = d.Poly[k], d.Poly[k % #d.Poly + 1]
				line(Vector2.new(p1[1], p1[2]), Vector2.new(p2[1], p2[2]), 2, d.Color, 2, 0.15)
			end
			continue
		end
		fill(d.Poly, d.Color, 0, if layer.Image then 0.88 else 0.72, 2)
		local smooth = MapScreen.smooth(d.Poly)
		local light = d.Color:Lerp(Color3.new(1, 1, 1), 0.45)
		for _, stroke in { { 12, d.Color, 0.78 }, { 5.5, d.Color, 0.25 }, { 2, light, 0 } } do
			for k = 1, #smooth do
				local p1, p2 = smooth[k], smooth[k % #smooth + 1]
				local pa, pc = toPixel(layer, p1[1], p1[2]), toPixel(layer, p2[1], p2[2])
				local delta = pc - pa
				local piece = create("Frame", {
					Name = "Outline",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset((pa.X + pc.X) / 2, (pa.Y + pc.Y) / 2),
					Size = UDim2.fromOffset(delta.Magnitude + stroke[1], stroke[1]),
					Rotation = math.deg(math.atan2(delta.Y, delta.X)),
					BackgroundColor3 = stroke[2],
					BackgroundTransparency = stroke[3],
					BorderSizePixel = 0,
					ZIndex = 3,
					Parent = frame,
				}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
				table.insert(layer.Outlines, { Frame = piece, Length = delta.Magnitude, Thickness = stroke[1] })
			end
		end
	end
	if drawn then
		-- Río y lagos
		local riverWidth = math.max(3, CityPlan.River.Width / scale)
		local pts = CityPlan.River.Points
		for k = 1, #pts - 1 do
			line(Vector2.new(pts[k][1], pts[k][2]), Vector2.new(pts[k + 1][1], pts[k + 1][2]), riverWidth, SEA_TOP, 2)
		end
		for _, lake in CityPlan.Lakes do
			circle(layer, "Lake", lake.X, lake.Z, lake.R, SEA_TOP, 2)
		end
		-- Calles (en cualquier ángulo) y rotondas
		for _, road in roads do
			local width = math.max(2, road.Width / scale)
			line(Vector2.new(road.A.X, road.A.Z), Vector2.new(road.B.X, road.B.Z), width, if road.Width > 30 then rgb(250, 214, 120) else ROAD, 3)
		end
		for _, r in CityPlan.Roundabouts do
			circle(layer, "Roundabout", r[1], r[2], 56, ROAD, 3)
			circle(layer, "RoundaboutIsland", r[1], r[2], 22, LAND, 3)
		end
		-- Vía del tren de Cercanías (Shared/Rail): gris oscuro con el color de la línea por encima
		local railPoints = Rail.path()
		for k = 1, #railPoints - 1 do
			local a, c = railPoints[k], railPoints[k + 1]
			line(Vector2.new(a.X, a.Z), Vector2.new(c.X, c.Z), math.max(3, 9 / scale), rgb(60, 56, 62), 3)
			if detailed then
				line(Vector2.new(a.X, a.Z), Vector2.new(c.X, c.Z), math.max(1, 4 / scale), Rail.Line.Color, 3)
			end
		end
	end
	-- Nombre de cada distrito (solo en el mapa grande): cápsula oscura con el borde de su color, el
	-- icono en un círculo de color, el NOMBRE en mayúsculas y su subtítulo. Sin pisarse entre ellas ni
	-- tapar los lugares que llevan nombre (MapScreen.placeLabels: se apartan a un hueco libre)
	if detailed then
		local placed = MapScreen.districtLabels(screen, landmarks :: any, function(x, z)
			return toPixel(layer, x, z)
		end, 1)
		for _, d in MapInfo.Districts do
			local p = placed[d.Id]
			table.insert(layer.Labels, Rect.new(p.X - p.W / 2, p.Y - p.H / 2, p.X + p.W / 2, p.Y + p.H / 2))
			local pill = create("Frame", {
				Name = "Label",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(p.X, p.Y),
				Size = UDim2.fromOffset(0, 46),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = d.Color:Lerp(Color3.new(0, 0, 0), 0.55),
				BackgroundTransparency = 0.1,
				ZIndex = 6,
				Parent = frame,
			}, {
				create("UICorner", { CornerRadius = UDim.new(0, 14) }),
				create("UIStroke", { Color = d.Color:Lerp(Color3.new(1, 1, 1), 0.25), Thickness = 2 }),
				create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(170, 170, 190)) }),
				create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 14) }),
			})
			local badge = create("Frame", {
				Name = "Badge",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(38, 38),
				BackgroundColor3 = d.Color,
				ZIndex = 6,
				Parent = pill,
			}, {
				create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5, Transparency = 0.3 }),
			})
			Theme.label({ Size = UDim2.fromScale(1, 1), Text = d.Icon, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6, Parent = badge })
			Theme.label({
				Name = "Name",
				Position = UDim2.fromOffset(46, 4),
				Size = UDim2.fromOffset(0, 20),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = string.upper(d.Name),
				Font = Theme.FontBold,
				TextSize = 16,
				TextStrokeTransparency = 0.5,
				ZIndex = 6,
				Parent = pill,
			})
			Theme.label({
				Name = "Sub",
				Position = UDim2.fromOffset(46, 24),
				Size = UDim2.fromOffset(0, 16),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = d.Theme,
				TextSize = 13,
				TextColor3 = rgb(236, 240, 250),
				TextStrokeTransparency = 0.7,
				ZIndex = 6,
				Parent = pill,
			})
			keepSize(layer, pill)
		end
		-- El mar tiene nombre
		local sea = toPixel(layer, 4600, -300)
		local seaLabel = Theme.label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(sea.X, sea.Y),
			Size = UDim2.fromOffset(140, 40),
			Text = "MAR DE\nVALMAR",
			Font = Theme.FontBold,
			TextSize = 16,
			TextColor3 = rgb(200, 230, 255),
			TextTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 2,
			Parent = frame,
		})
		keepSize(layer, seaLabel)
	end
	-- Lugares: primero los que llevan su nombre siempre (así sus nombres caben antes que los demás). Antes,
	-- dónde cae cada uno de esos (uno de cada tipo): los nombres de los demás no los tapan
	if detailed then
		local k = MapScreen.labelScale(screen)
		local seen = {}
		for _, place in landmarks do
			if MapScreen.Featured[place.Kind.Model] and not seen[place.Kind.Model] then
				seen[place.Kind.Model] = true
				local q = toPixel(layer, place.Position.X, place.Position.Z)
				table.insert(layer.PinRects, { Rect = Rect.new(q.X - 17 * k, q.Y - 17 * k, q.X + 17 * k, q.Y + 17 * k), Model = place.Kind.Model })
			end
		end
	end
	for _, pass in { true, false } do
		for _, place in landmarks do
			if (MapScreen.Featured[place.Kind.Model] == true) == pass then
				landmarkIcon(layer, place, detailed)
			end
		end
	end
	addMarkers(layer, detailed)
	return layer
end

-- El minimapa de Tefra: Bastión Ceniza (shared/Cosmos/TefraCity), con sus barrios, calles, la lava, la
-- muralla, los edificios y los sitios (con su icono). Mismo tipo de capa que la de Valmar: tu flecha,
-- la ★ y los demás jugadores se ponen igual (updateLayer).
local TEFRA_GROUND = rgb(92, 80, 90)
local TEFRA_CITY = rgb(54, 48, 56)
local TEFRA_ROAD = rgb(150, 136, 140)
local TEFRA_LAVA = rgb(255, 120, 40)
local function buildTefraLayer(parent: Instance, scale: number): Layer
	local R = TefraCity.Rect
	local O = Tefra.Origin
	local pad = 420
	local min = Vector2.new(O.X + R.X0 - pad, O.Z + R.Z0 - pad)
	local max = Vector2.new(O.X + R.X1 + pad, O.Z + R.Z1 + pad)
	local extent = (max - min) / scale
	local frame = create("Frame", {
		Name = "Tefra",
		Size = UDim2.fromOffset(extent.X, extent.Y),
		BackgroundColor3 = TEFRA_GROUND,
		BorderSizePixel = 0,
		Parent = parent,
	})
	local layer: Layer = {
		Frame = frame,
		Scale = scale,
		Min = min,
		Me = nil :: any,
		Target = nil :: any,
		Waypoint = nil :: any,
		Dots = {},
		Icons = {},
		Scalers = {},
		Keep = 1,
		Labels = {},
		Shown = {},
		PinRects = {},
		Canon = {},
		Homes = {},
		Outlines = {},
		Image = false,
	}
	local function wrect(name: string, x0: number, z0: number, x1: number, z1: number, color: Color3, z: number): Frame
		return rect(layer, name, O.X + x0, O.Z + z0, O.X + x1, O.Z + z1, color, z)
	end
	-- Los lagos de alrededor
	for _, lake in Tefra.Lakes do
		circle(layer, "Lake", O.X + lake.X, O.Z + lake.Z, lake.R, rgb(80, 96, 120), 1)
	end
	-- El foso de lava, la muralla y el suelo de la ciudad
	local a, b = TefraCity.WallThick, TefraCity.MoatOut
	wrect("Foso", R.X0 - b, R.Z0 - b, R.X1 + b, R.Z1 + b, TEFRA_LAVA, 1)
	wrect("Muralla", R.X0 - a, R.Z0 - a, R.X1 + a, R.Z1 + a, rgb(30, 26, 30), 1)
	wrect("Ciudad", R.X0, R.Z0, R.X1, R.Z1, TEFRA_CITY, 1)
	-- Los barrios (tinte suave de su color)
	for _, d in TefraCity.Districts do
		local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
		for _, p in d.Poly do
			x0, z0 = math.min(x0, p[1]), math.min(z0, p[2])
			x1, z1 = math.max(x1, p[1]), math.max(z1, p[2])
		end
		local color = Color3.fromRGB(d.Color[1], d.Color[2], d.Color[3])
		-- (los barrios en L: por franjas de 40 studs, solo lo que cae dentro)
		for zz = z0, z1 - 1, 40 do
			for xx = x0, x1 - 1, 40 do
				if TefraCity.pointIn(d.Poly, xx + 20, zz + 20) then
					wrect("Barrio", xx, zz, xx + 40.5, zz + 40.5, color, 2).BackgroundTransparency = 0.72
				end
			end
		end
	end
	-- Calles, el canal y los pozos de lava
	for _, st in TefraCity.Streets do
		local hw = 12
		if st.Axis == "X" then
			wrect("Calle", st.From - hw, st.At - hw, st.To + hw, st.At + hw, TEFRA_ROAD, 3)
		else
			wrect("Calle", st.At - hw, st.From - hw, st.At + hw, st.To + hw, TEFRA_ROAD, 3)
		end
	end
	local c = TefraCity.Canal
	wrect("Canal", R.X0, c.Z - c.Half, R.X1, c.Z + c.Half, TEFRA_LAVA, 3)
	for _, st in TefraCity.Streets do
		if st.Axis == "Z" and st.From < c.Z and st.To > c.Z then
			wrect("Puente", st.At - 12, c.Z - c.Half, st.At + 12, c.Z + c.Half, TEFRA_ROAD, 4)
		end
	end
	for _, w in TefraCity.Wells do
		circle(layer, "Pozo", O.X + w.X, O.Z + w.Z, w.R, TEFRA_LAVA, 4)
	end
	-- Edificios (sus huellas) y los sitios con icono
	for _, bld in TefraCity.Buildings do
		if bld.Shape ~= "Court" and bld.Shape ~= "Stall" then
			local x0, x1, z0, z1 = TefraCity.footprint(bld)
			wrect("Edificio", x0, z0, x1, z1, if bld.Shape == "Dome" or bld.Shape == "Skeleton" then rgb(196, 170, 186) else rgb(34, 30, 36), 4)
		end
	end
	for _, l in TefraCity.landmarks() do
		local icon = marker(layer, l.Icon, Color3.new(1, 1, 1), 15, 6)
		local q = toPixel(layer, O.X + l.X, O.Z + l.Z)
		icon.Position = UDim2.fromOffset(q.X, q.Y)
	end
	addMarkers(layer, false)
	return layer
end

local function place(layer: Layer, label: GuiObject, target: Vector3?, root: BasePart?, clampTo: number?)
	if not target then
		label.Visible = false
		return
	end
	local p = toPixel(layer, target.X, target.Z)
	if clampTo and root then
		-- En el minimapa: si está fuera, se queda en el borde
		local me = toPixel(layer, root.Position.X, root.Position.Z)
		local offset = p - me
		if offset.Magnitude > clampTo then
			p = me + offset.Unit * clampTo
		end
	end
	label.Position = UDim2.fromOffset(p.X, p.Y)
	label.Visible = true
end

-- Ruta del GPS: una línea gruesa que brilla por las calles (se redibuja solo al cambiar la ruta:
-- como el mapa se mueve debajo de ti, no hace falta tocarla al andar)
local ROUTE = rgb(80, 210, 255)
local ROUTE_GLOW = rgb(20, 120, 255)
local MAX_ROUTE_PIECES = 80
local routePath: { Vector3 }? = nil -- lo que queda de ruta (desde donde estás)
local routeFull: { Vector3 }? = nil -- la ruta entera (la misma tabla mientras no cambie)
local routeIndex = 1 -- en qué tramo de la ruta entera vas
local bigRouteDirty = false -- el mapa grande está cerrado: se redibuja al abrirlo

-- La línea se hace con piezas (un brillo y la línea encima) que se guardan y se reutilizan: antes se
-- borraba y se volvía a crear entera cada vez que pasabas de un tramo a otro. Ahora, con la misma
-- ruta, solo se esconden los tramos que ya has pasado y se recoloca el primero (desde donde estás).
type RoutePiece = { Glow: Frame, Line: Frame }
type RouteDraw = {
	Holder: Frame,
	Route: { Vector3 }?, -- para qué ruta son las piezas de Segments
	Head: RoutePiece?, -- el primer trozo: de donde estás al final de tu tramo
	Segments: { [number]: RoutePiece | false }, -- tramo j de la ruta entera (false: muy corto, sin pieza)
	Pool: { RoutePiece },
}
local routeDraws: { [Layer]: RouteDraw } = {}

local function newPiece(holderFrame: Frame): RoutePiece
	local pair = {}
	for k, style in { { 0.6, 5 }, { 0, 6 } } do
		pair[k] = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = if k == 1 then ROUTE_GLOW else ROUTE,
			BackgroundTransparency = style[1],
			BorderSizePixel = 0,
			ZIndex = style[2],
			Parent = holderFrame,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	return { Glow = pair[1], Line = pair[2] }
end

local function takePiece(draw: RouteDraw): RoutePiece
	local piece = table.remove(draw.Pool)
	return piece or newPiece(draw.Holder)
end

local function releasePiece(draw: RouteDraw, piece: RoutePiece)
	piece.Glow.Visible = false
	piece.Line.Visible = false
	table.insert(draw.Pool, piece)
end

-- Coloca una pieza de a a b (en píxeles del mapa); false si es tan corta que no se dibuja
local function setPiece(layer: Layer, piece: RoutePiece, from: Vector3, to: Vector3): boolean
	local a = toPixel(layer, from.X, from.Z)
	local b = toPixel(layer, to.X, to.Z)
	local d = b - a
	local length = d.Magnitude
	if length <= 0.3 then
		piece.Glow.Visible = false
		piece.Line.Visible = false
		return false
	end
	local thick = if layer == miniLayer then 6 else 5
	local middle = (a + b) / 2
	local rotation = math.deg(math.atan2(d.Y, d.X))
	for k, part in { piece.Glow, piece.Line } do
		local width = if k == 1 then thick + 7 else thick
		part.Position = UDim2.fromOffset(middle.X, middle.Y)
		part.Size = UDim2.fromOffset(length + width, width)
		part.Rotation = rotation
		part.Visible = true
	end
	return true
end

local function drawRoute(layer: Layer?)
	if not layer then
		return
	end
	local draw = routeDraws[layer]
	local path = routePath
	if not draw then
		if not path or #path < 2 then
			return
		end
		local holderFrame = create("Frame", { Name = "Route", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = layer.Frame })
		draw = { Holder = holderFrame, Route = nil, Head = nil, Segments = {}, Pool = {} }
		routeDraws[layer] = draw
	end
	local d = draw :: RouteDraw
	local full = routeFull or path
	local index = if routeFull then routeIndex else 1
	-- Ruta nueva (o sin ruta): todas las piezas vuelven al montón
	if d.Route ~= full or not path or #path < 2 then
		for _, piece in d.Segments do
			if piece then
				releasePiece(d, piece)
			end
		end
		table.clear(d.Segments)
		d.Route = full
	end
	if not path or #path < 2 or not full then
		d.Holder.Visible = false
		return
	end
	d.Holder.Visible = true
	-- Primer trozo: de donde estás al final del tramo
	local head = d.Head or takePiece(d)
	d.Head = head
	setPiece(layer, head, path[1], path[2])
	-- El resto: tramos enteros de la ruta (path[i] es full[index + i - 1]); hasta MAX_ROUTE_PIECES
	local last = index + math.min(#path - 1, MAX_ROUTE_PIECES) - 1
	for j, piece in d.Segments do
		if piece and (j <= index or j > last) then
			piece.Glow.Visible = false
			piece.Line.Visible = false
		end
	end
	for j = index + 1, last do
		local piece = d.Segments[j]
		if piece == nil then
			local fresh = takePiece(d)
			if setPiece(layer, fresh, full[j], full[j + 1]) then
				d.Segments[j] = fresh
			else
				releasePiece(d, fresh)
				d.Segments[j] = false
			end
		elseif piece then
			piece.Glow.Visible = true
			piece.Line.Visible = true
		end
	end
end

-- Giro suave de tu flecha: antes se creaba un Tween nuevo por mapa cada 0,1 s (y otro más para el
-- mapa grande). Ahora se guarda de dónde a dónde gira y se mueve en cada fotograma, sin crear nada;
-- se ve igual (0,1 s, lineal) y si la flecha no gira no se toca.
local SPIN_TIME = 0.1
local spins: { [GuiObject]: { From: number, To: number, T: number } } = {}
local function stepSpins(dt: number)
	for me, spin in spins do
		spin.T += dt
		local alpha = math.min(1, spin.T / SPIN_TIME)
		me.Rotation = spin.From + (spin.To - spin.From) * alpha
		if alpha >= 1 then
			spins[me] = nil
		end
	end
end

local function updateLayer(layer: Layer, root: BasePart?, clampTo: number?)
	-- Tu posición y hacia dónde miras
	if root then
		local p = toPixel(layer, root.Position.X, root.Position.Z)
		layer.Me.Position = UDim2.fromOffset(p.X, p.Y)
		local look = root.CFrame.LookVector
		local target = math.deg(math.atan2(look.X, -look.Z))
		-- Giro suave: por el lado corto (sin dar la vuelta entera al pasar de 179° a -179°)
		local current = layer.Me.Rotation
		local delta = (target - current + 180) % 360 - 180
		if math.abs(delta) > 1e-3 then
			spins[layer.Me] = { From = current, To = current + delta, T = 0 }
		else
			spins[layer.Me] = nil
		end
		-- El cono mira hacia donde mira la cámara (es hijo de la flecha: se le resta su giro)
		local cameraLook = workspace.CurrentCamera.CFrame.LookVector
		local cone = layer.Me:FindFirstChild("Cone") :: Frame?
		if cone then
			cone.Rotation = math.deg(math.atan2(cameraLook.X, -cameraLook.Z)) - (current + delta)
		end
		layer.Me.Visible = true
	else
		layer.Me.Visible = false
	end

	-- Objetivo del trabajo, del encargo o de la historia (el mismo que marca el haz de luz). Mientras
	-- sigues una ruta tuya no sale: solo su 📍 y su línea (una sola guía a la vez)
	-- (en el minimapa de Tefra, nada de Valmar: ni su objetivo, ni sus ❗, ni tus casas de allí)
	local planet = layer.Frame.Name == "Tefra"
	local target = if planet then nil else Gps.missionMarker()
	place(layer, layer.Target, target, root, clampTo)
	place(layer, layer.Waypoint, if waypoint and not planet then waypoint.Position else nil, root, clampTo)

	-- Misiones canónicas pendientes: un ❗ dorado donde empiezan (siempre, hasta que las haces)
	-- y los encargos de la ciudad que tienes cerca: un ! azul, más pequeño (Controllers/CityErrands)
	local seenCanon = {}
	local marks = {}
	for _, mark in if planet then {} else CanonMarkers.list() do
		table.insert(marks, { Id = mark.Id, X = mark.X, Z = mark.Z, Errand = false })
	end
	for _, mark in if planet then {} else CityErrands.list() do
		table.insert(marks, { Id = "Encargo:" .. mark.Id, X = mark.X, Z = mark.Z, Errand = true })
	end
	for _, mark in marks do
		seenCanon[mark.Id] = true
		local label = layer.Canon[mark.Id]
		if not label then
			label = if mark.Errand then marker(layer, "!", Color3.fromRGB(80, 210, 255), 15, 5) else marker(layer, "❗", Color3.fromRGB(255, 200, 60), 18, 5)
			layer.Canon[mark.Id] = label
		end
		local p = toPixel(layer, mark.X, mark.Z)
		if clampTo and root then
			local me = toPixel(layer, root.Position.X, root.Position.Z)
			local offset = p - me
			if offset.Magnitude > clampTo then
				p = me + offset.Unit * clampTo
			end
		end
		label.Position = UDim2.fromOffset(p.X, p.Y)
		label.Visible = true
	end
	for id, label in layer.Canon do
		if not seenCanon[id] then
			label:Destroy()
			layer.Canon[id] = nil
		end
	end

	-- 🏠 Tus casas: siempre (ningún filtro, misión ni ajuste las quita)
	local seenHomes = {}
	for _, home in if planet then {} else MapLegend.homeMarkers(player:GetAttribute("FamilyHomePos"), player:GetAttribute("OwnHomePos")) do
		seenHomes[home.Id] = true
		local icon = layer.Homes[home.Id]
		if not icon then
			icon = homeIcon(layer, home.Name, clampTo == nil)
			layer.Homes[home.Id] = icon
		end
		local title = icon:FindFirstChild("Title") :: TextLabel?
		if title and title.Text ~= home.Name then
			title.Text = home.Name
		end
		local p = toPixel(layer, home.Position.X, home.Position.Z)
		if clampTo and root then
			local me = toPixel(layer, root.Position.X, root.Position.Z)
			local offset = p - me
			if offset.Magnitude > clampTo then
				p = me + offset.Unit * clampTo
			end
		end
		icon.Position = UDim2.fromOffset(p.X, p.Y)
		icon.Visible = true
	end
	for id, icon in layer.Homes do
		if not seenHomes[id] then
			icon:Destroy()
			layer.Homes[id] = nil
		end
	end

	-- Los demás jugadores (puntos azules)
	local seen = {}
	for _, other in Players:GetPlayers() do
		local character = other ~= player and other.Character
		local otherRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if otherRoot then
			seen[other] = true
			local dot = layer.Dots[other]
			if not dot then
				dot = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(8, 8),
					BackgroundColor3 = OTHERS,
					BorderSizePixel = 0,
					ZIndex = 6,
					Parent = layer.Frame,
				}, { Theme.corner(4), create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1 }) })
				layer.Dots[other] = dot
			end
			local at = mapRoot(other, otherRoot).Position
			local p = toPixel(layer, at.X, at.Z)
			dot.Position = UDim2.fromOffset(p.X, p.Y)
		end
	end
	for other, dot in layer.Dots do
		if not seen[other] then
			dot:Destroy()
			layer.Dots[other] = nil
		end
	end
end

---------------------------------------------------------------------
-- Mapa grande: mover y acercar
---------------------------------------------------------------------

local function applyView()
	local layer = bigLayer
	if not layer then
		return
	end
	local extent = layer.Frame.Size
	local w, h = extent.X.Offset * zoom, extent.Y.Offset * zoom
	-- Que el mapa no se escape del todo de la ventana
	local minX, maxX = math.min(0, holderSize.X - w), math.max(0, holderSize.X - w)
	local minY, maxY = math.min(0, holderSize.Y - h), math.max(0, holderSize.Y - h)
	pan = Vector2.new(math.clamp(pan.X, minX - 80, maxX + 80), math.clamp(pan.Y, minY - 80, maxY + 80))
	layer.Frame.Position = UDim2.fromOffset(pan.X, pan.Y)
	local scaler = layer.Frame:FindFirstChild("Zoom") :: UIScale
	scaler.Scale = zoom
	-- Los iconos y etiquetas crecen solo un poco al acercar (y en el móvil, algo más pequeños: la isla
	-- entera ocupa menos y si no se pisan)
	local keep = MapScreen.labelScale(screen) / zoom ^ 0.75
	layer.Keep = keep
	for _, s in layer.Scalers do
		s.Scale = keep
	end
	-- Los bordes de los distritos, del mismo grosor con cualquier zoom (siguen nítidos y finos), y los
	-- lugares que salen al acercar
	if layer.OutlineZoom ~= zoom then
		for _, icon in layer.Icons do
			local want = MapLegend.visible(hidden, icon.Kind) and zoom >= icon.MinZoom - 1e-3
			if icon.Holder.Visible ~= want then
				icon.Holder.Visible = want
			end
		end
		layer.OutlineZoom = zoom
		for _, outline in layer.Outlines do
			local thickness = outline.Thickness / zoom
			outline.Frame.Size = UDim2.fromOffset(outline.Length + thickness, thickness)
		end
	end
end

local function setZoom(newZoom: number, focus: Vector2)
	newZoom = math.clamp(newZoom, 1, 6)
	local world = (focus - pan) / zoom
	zoom = newZoom
	pan = focus - world * zoom
	applyView()
end

local function centerOn(position: Vector3, newZoom: number?)
	local layer = bigLayer
	if not layer then
		return
	end
	zoom = math.clamp(newZoom or zoom, 1, 6)
	local p = toPixel(layer, position.X, position.Z)
	-- (en el centro del hueco libre entre los paneles, no de la pantalla)
	local area = screen.Map
	pan = Vector2.new(area.X + area.W / 2, area.Y + area.H / 2) - p * zoom
	applyView()
end

local function fitAll()
	local layer = bigLayer
	if not layer then
		return
	end
	zoom = 1
	-- La isla (con el arte: la isla del dibujo; si no, toda la región) en el centro del hueco libre
	local area = screen.Map
	local box = MapScreen.IslandBox
	local a, b
	if layer.Image then
		a, b = artPixel(layer, box.X0, box.Y0), artPixel(layer, box.X1, box.Y1)
	else
		a, b = Vector2.zero, Vector2.new(layer.Frame.Size.X.Offset, layer.Frame.Size.Y.Offset)
	end
	pan = Vector2.new(area.X + area.W / 2, area.Y + area.H / 2) - (a + b) / 2
	applyView()
end

local function refreshLegend()
	local layer = bigLayer
	if layer then
		for _, icon in layer.Icons do
			icon.Holder.Visible = MapLegend.visible(hidden, icon.Kind) and zoom >= icon.MinZoom - 1e-3
		end
	end
	for _, icon in miniLayer.Icons do
		icon.Holder.Visible = MapLegend.visible(hidden, icon.Kind)
	end
	refreshLegendRows()
end

-- Tocar una categoría de la leyenda: se ocultan (o vuelven) todos sus lugares, y se guarda
local function saveFilters()
	local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("MapFilters")
	if remote then
		(remote :: RemoteEvent):FireServer(MapLegend.encode(hidden))
	end
end

local function ensureBigLayer()
	if bigLayer then
		return
	end
	-- Con el zoom 1, toda la isla cabe en el hueco libre entre los paneles (MapScreen: Map). Con el arte,
	-- la isla del dibujo (MapScreen.IslandBox, en píxeles de la referencia); si no, toda la región (studs)
	local extent = boundsMax - boundsMin
	local area = screen.Map
	local scale = if #MapScreen.tiles(MapTextureIds) > 0 then MapScreen.fitScale(screen) else math.max(extent.X / math.max(area.W, 100), extent.Y / math.max(area.H, 100))
	bigLayer = buildLayer(holder, scale, true)
	local layer = bigLayer :: Layer
	create("UIScale", { Name = "Zoom", Parent = layer.Frame })
	drawRoute(layer)
	bigRouteDirty = false
	refreshLegend()
	fitAll()
end

local function setBigOpen(open: boolean)
	if not bigGui then
		return -- (aún esperando los datos del mapa: el servidor está arrancando)
	end
	if open and not bigOpen then
		-- Una ventana grande a la vez: fuera la mochila, la tienda, las misiones, el ❓…
		Dialog.closeOthers("BigMap")
	end
	bigOpen = open
	bigGui.Enabled = open
	if open then
		ensureBigLayer()
		-- (la ruta del mapa grande solo se redibuja al abrirlo, si cambió mientras estaba cerrado)
		if bigRouteDirty then
			bigRouteDirty = false
			drawRoute(bigLayer)
		end
		-- (la primera vez se ve toda la isla, como en el dibujo; luego, donde lo dejaste)
		updateHud()
	end
end

-- (en Tefra: lo pone más abajo, junto al minimapa)
local tefraToggle: () -> boolean = function()
	return false
end

function MapUI.toggleBig()
	-- En Tefra no hay mapa grande de Valmar que valga: el minimapa se aleja hasta ver Bastión Ceniza
	-- entera (y vuelve al tocar otra vez). El mapa grande de Tefra llegará más adelante.
	if tefraToggle() then
		if bigOpen then
			setBigOpen(false)
		end
		return
	end
	setBigOpen(not bigOpen)
end

function MapUI.isOpen(): boolean
	return bigOpen
end

---------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------

local miniZoom = 2 -- índice en MINI_ZOOMS
local miniScaler: UIScale
local miniCanvas: CanvasGroup? = nil
local valmarMini: Layer? = nil -- la capa de Valmar (la de siempre)
local tefraMini: Layer? = nil -- la de Bastión Ceniza (se hace la primera vez que llegas a Tefra)
local zoomBeforeTefra: number? = nil -- en Tefra, «Mapa» aleja el minimapa hasta ver la ciudad entera

local function onTefra(): boolean
	return player:GetAttribute("Planeta") == "Tefra"
end

-- ¿Qué minimapa toca? (Valmar o Tefra) Devuelve true si ha cambiado
local function syncMiniWorld(): boolean
	if not miniCanvas or not valmarMini then
		return false
	end
	local want = if onTefra() then "Tefra" else "Valmar"
	local current = if miniLayer == tefraMini and tefraMini ~= nil then "Tefra" else "Valmar"
	if want == current then
		return false
	end
	if want == "Tefra" and not tefraMini then
		local layer = buildTefraLayer(miniCanvas, MINI_SCALE)
		create("UIScale", { Name = "Zoom", Parent = layer.Frame })
		tefraMini = layer
	end
	local nextLayer = if want == "Tefra" then tefraMini :: Layer else valmarMini :: Layer
	miniLayer.Frame.Visible = false
	nextLayer.Frame.Visible = true
	miniLayer = nextLayer
	miniScaler = nextLayer.Frame:FindFirstChild("Zoom") :: UIScale
	zoomBeforeTefra = nil
	return true
end

local function roundTool(parent: Instance, name: string, position: UDim2, size: number): TextButton
	local button = create("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Theme.Hud.Navy,
		BackgroundTransparency = 0.1,
		Text = "",
		ZIndex = 11,
		Parent = parent,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.edge(button, Theme.Hud.Glow, 2)
	Theme.pressable(button)
	return button
end

local function setMiniZoom(index: number)
	miniZoom = math.clamp(index, 1, #MINI_ZOOMS)
	local zoom = MINI_ZOOMS[miniZoom]
	miniScaler.Scale = zoom
	miniLayer.Keep = 1 / zoom
	for _, s in miniLayer.Scalers do
		s.Scale = 1 / zoom -- los iconos no cambian de tamaño
	end
end

tefraToggle = function(): boolean
	if not onTefra() or not miniScaler then
		return false
	end
	if zoomBeforeTefra then
		setMiniZoom(zoomBeforeTefra)
		zoomBeforeTefra = nil
	else
		zoomBeforeTefra = miniZoom
		setMiniZoom(1)
	end
	return true
end

local function buildMini()
	gui = create("ScreenGui", {
		Name = "MapUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HudLayout.scaleGui(gui)

	-- Hueco del minimapa (UI/HudLayout): el círculo arriba y el nombre de la zona debajo
	miniHolder = create("Frame", {
		Name = "Minimap",
		BackgroundTransparency = 1,
		Parent = gui,
	})
	HudLayout.onChanged(function(layout)
		HudLayout.apply(miniHolder, layout.Items.Minimap)
	end)
	local disc = create("Frame", {
		Name = "Disc",
		Size = UDim2.fromOffset(MINI_SIZE, MINI_SIZE),
		BackgroundColor3 = rgb(12, 22, 42),
		Parent = miniHolder,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	-- Aro brillante (borde con degradado y halo suave por fuera)
	Theme.edge(disc, nil, 5)
	Theme.halo(disc, Theme.Hud.Glow, 12, 999)
	local mini = create("CanvasGroup", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = LAND,
		BorderSizePixel = 0,
		Parent = disc,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	miniLayer = buildLayer(mini, MINI_SCALE, false)
	miniScaler = create("UIScale", { Name = "Zoom", Parent = miniLayer.Frame })
	miniCanvas = mini
	valmarMini = miniLayer
	-- Brújula: marcas de los puntos cardinales en el aro y la N arriba
	for i, angle in { 90, 180, 270 } do
		local a = math.rad(angle - 90)
		create("Frame", {
			Name = "Tick" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.cos(a) * (MINI_SIZE / 2 - 3), 0.5, math.sin(a) * (MINI_SIZE / 2 - 3)),
			Size = UDim2.fromOffset(4, 12),
			Rotation = angle,
			BackgroundColor3 = Theme.Hud.Glow,
			BorderSizePixel = 0,
			ZIndex = 10,
			Parent = disc,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	local north = create("Frame", {
		Name = "North",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = Theme.Hud.Navy,
		ZIndex = 10,
		Parent = disc,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.edge(north, Theme.Hud.Glow, 2)
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = "N", Font = Theme.FontBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 11, Parent = north })

	-- Acercar y alejar (en el aro, abajo a la derecha)
	local function onRing(degrees: number): UDim2
		local a = math.rad(degrees)
		return UDim2.new(0.5, math.cos(a) * MINI_SIZE / 2, 0.5, math.sin(a) * MINI_SIZE / 2)
	end
	local plus = roundTool(disc, "ZoomIn", onRing(20), 30)
	Icons.plus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Thickness = 3, ZIndex = 12, Parent = plus })
	plus.Activated:Connect(function()
		setMiniZoom(miniZoom + 1)
	end)
	local minus = roundTool(disc, "ZoomOut", onRing(50), 30)
	Icons.minus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Thickness = 3, ZIndex = 12, Parent = minus })
	minus.Activated:Connect(function()
		setMiniZoom(miniZoom - 1)
	end)
	-- Botón para desplegar el mapa completo (abajo a la izquierda del aro)
	local expand = roundTool(disc, "Expand", onRing(140), 38)
	Icons.new("mapa", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), ZIndex = 12, Parent = expand })
	expand.Activated:Connect(MapUI.toggleBig)
	-- El sol (o la luna) junto al minimapa, en la esquina de arriba a la derecha
	local sky = Icons.new("sol", { Name = "Sky", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 4, 0, -4), Size = UDim2.fromOffset(34, 34), ZIndex = 12, Parent = miniHolder })
	local function skyIcon()
		local clock = GameClock.hour()
		Icons.set(sky, if clock >= 6.5 and clock < 20 then "sol" else "luna")
	end
	game:GetService("Lighting"):GetPropertyChangedSignal("ClockTime"):Connect(function()
		local clock = GameClock.hour()
		local want = if clock >= 6.5 and clock < 20 then "sol" else "luna"
		if sky:GetAttribute("Icon") ~= want then
			skyIcon()
		end
	end)
	skyIcon()

	zoneLabel = Theme.label({
		Name = "Zone",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 20, 0, 20),
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.FontBold,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = miniHolder,
	})
	setMiniZoom(miniZoom)
end

---------------------------------------------------------------------
-- Mapa grande: la pantalla (shared/MapScreen dice dónde va cada pieza en cada pantalla)
---------------------------------------------------------------------

-- Panel azul marino con el filo azul que brilla y esquinas redondeadas (como en el dibujo)
local function navyPanel(name: string, radius: number?): Frame
	local frame = create("Frame", {
		Name = name,
		BackgroundColor3 = MC.Panel,
		BackgroundTransparency = MC.PanelTransparency,
		BorderSizePixel = 0,
		Active = true, -- (no deja pasar el dedo al mapa de debajo)
		ZIndex = 22,
		Parent = big,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, radius or 18) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(165, 175, 200)) }),
	})
	create("UIStroke", { Name = "Edge", Color = MC.Edge, Thickness = 2, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
	Theme.halo(frame, MC.Glow, 8, (radius or 18) + 4)
	overlays[name] = frame
	return frame
end

-- Botón redondo azul marino (+, −, ◎, ✖)
local function circleButton(parent: Instance, name: string): TextButton
	local button = create("TextButton", {
		Name = name,
		Size = UDim2.fromOffset(56, 56),
		BackgroundColor3 = MC.Panel,
		BackgroundTransparency = 0.05,
		AutoButtonColor = true,
		Text = "",
		ZIndex = 24,
		Parent = parent,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	create("UIStroke", { Color = MC.Edge, Thickness = 2, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button })
	Theme.pressable(button)
	return button
end

-- Una fila de las listas: círculo grande de color con el icono, título en negrita y subtítulo gris claro
local function listRow(parent: Instance, name: string, order: number, icon: string, color: Color3, title: string, sub: string): TextButton
	local h = screen.Row - 8
	local row = create("TextButton", {
		Name = name,
		Size = UDim2.new(1, -10, 0, h),
		BackgroundColor3 = MC.Row,
		BackgroundTransparency = 0.2,
		AutoButtonColor = true,
		Text = "",
		LayoutOrder = order,
		ZIndex = 23,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIStroke", { Color = MC.Edge, Thickness = 1, Transparency = 0.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	local d = h - 6
	local badge = create("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(d, d),
		BackgroundColor3 = color,
		ZIndex = 23,
		Parent = row,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(175, 175, 190)) }),
		create("UIStroke", { Color = color:Lerp(Color3.new(1, 1, 1), 0.5), Thickness = 2, Transparency = 0.2 }),
	})
	Theme.label({ Name = "Icon", Size = UDim2.fromScale(1, 1), Text = icon, TextSize = math.floor(d * 0.5), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23, Parent = badge })
	Theme.label({
		Name = "Title",
		Position = UDim2.new(0, d + 14, 0.5, -21),
		Size = UDim2.new(1, -(d + 20), 0, 22),
		Text = title,
		Font = Theme.FontBold,
		TextSize = screen.Text.Title,
		TextColor3 = MC.Title,
		TextScaled = true, -- (encoge un poco si no cabe: «Distrito Universitario» entero en paneles estrechos)
		ZIndex = 23,
		Parent = row,
	})
	create("UITextSizeConstraint", { MaxTextSize = screen.Text.Title, MinTextSize = 12, Parent = row:FindFirstChild("Title") })
	Theme.label({
		Name = "Sub",
		Position = UDim2.new(0, d + 14, 0.5, 2),
		Size = UDim2.new(1, -(d + 20), 0, 20),
		Text = sub,
		TextSize = screen.Text.Sub,
		TextColor3 = MC.Sub,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 23,
		Parent = row,
	})
	return row
end

-- Panel con título y lista que se desplaza («Distritos», «Lugares importantes»)
local function listPanel(name: string, title: string): (Frame, ScrollingFrame)
	local panel = navyPanel(name, 20)
	local header = Theme.label({
		Name = "Header",
		Position = UDim2.fromOffset(20, 8),
		Size = UDim2.new(1, -40, 0, 40),
		Text = title,
		Font = Theme.FontBold,
		TextSize = screen.Text.Header,
		TextColor3 = MC.Title,
		TextScaled = true, -- (encoge si el panel es estrecho: «Lugares importantes» cabe entero)
		ZIndex = 23,
		Parent = panel,
	})
	create("UITextSizeConstraint", { Name = "Max", MaxTextSize = screen.Text.Header, Parent = header })
	table.insert(headers, header)
	local list = create("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(10, 52),
		Size = UDim2.new(1, -14, 1, -60),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = MC.Glow,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 23,
		Parent = panel,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), Parent = list })
	return panel, list
end

-- Mantener el dedo en una fila (o en un lugar del mapa) = ver más; tocar = lo de siempre
local function onPress(button: GuiButton, tap: () -> (), hold: () -> ())
	local pressedAt = 0
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressedAt = os.clock()
		end
	end)
	button.Activated:Connect(function()
		if pressedAt > 0 and os.clock() - pressedAt >= HOLD then
			hold()
		else
			tap()
		end
		pressedAt = 0
	end)
end

local function myRoot(): any
	return mapRoot(player, player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?)
end

local function distanceText(position: Vector3): string?
	local root = myRoot()
	if not root then
		return nil
	end
	local meters = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z).Magnitude / 3.5
	return if meters >= 1000 then ("%.1f km"):format(meters / 1000) else ("%d m"):format(math.floor(meters))
end

local function buildBig()
	-- ¿Solo pantalla táctil (móvil o tableta, sin teclado)?
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	-- (las filas y letras nacen con las medidas de esta pantalla; resize() las recoloca después)
	screen = MapScreen.layout(workspace.CurrentCamera.ViewportSize)
	bigGui = create("ScreenGui", {
		Name = "BigMap",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 6,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	bigScale = create("UIScale", { Parent = bigGui })
	-- Las cinemáticas apagan y vuelven a encender todas las pantallas: el mapa solo se enciende si está abierto
	bigGui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if bigGui.Enabled ~= bigOpen then
			bigGui.Enabled = bigOpen
		end
	end)
	-- Empieza una escena de cine: el mapa grande se cierra (antes tapaba toda la escena del prólogo)
	player:GetAttributeChangedSignal("InCinematic"):Connect(function()
		if player:GetAttribute("InCinematic") and bigOpen then
			setBigOpen(false)
		end
	end)
	-- Toda la pantalla: el mar de fondo, la isla y, encima, los paneles
	-- (el fondo, del mismo azul que el borde del arte: el mar llega de lado a lado de la pantalla)
	big = create("Frame", {
		Name = "Panel",
		BackgroundColor3 = MC.Sea,
		BorderSizePixel = 0,
		ZIndex = 20,
		Active = true,
		Parent = bigGui,
	})
	holder = create("Frame", {
		Name = "Holder",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 21,
		Parent = big,
	})

	-- Logo: HEROES OF HISTORY · History of Valmar (después de los botones de Roblox)
	local logo = navyPanel("Logo", 20)
	local mark = create("Frame", {
		Name = "Mark",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 23,
		Parent = logo,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIGradient", { Rotation = 45, Color = ColorSequence.new(rgb(60, 170, 255), rgb(130, 90, 255)) }),
	})
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = MapScreen.Badge, Font = Theme.FontBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 24, Parent = mark })
	Theme.label({
		Name = "Title",
		Position = UDim2.new(0, 60, 0.5, -22),
		Size = UDim2.new(1, -68, 0, 26),
		Text = MapScreen.Title,
		Font = Theme.FontBold,
		TextSize = 21,
		TextColor3 = MC.Title,
		TextScaled = true,
		ZIndex = 23,
		Parent = logo,
	})
	create("UITextSizeConstraint", { MaxTextSize = 21, Parent = logo:FindFirstChild("Title") })
	Theme.label({
		Name = "Tagline",
		Position = UDim2.new(0, 61, 0.5, 4),
		Size = UDim2.new(1, -68, 0, 18),
		Text = MapScreen.Tagline,
		TextSize = 15,
		TextColor3 = MC.Sub,
		ZIndex = 23,
		Parent = logo,
	})

	-- ✖ Cerrar (arriba a la derecha)
	local close = circleButton(big, "Close")
	overlays.Close = close
	close.Text = "✖"
	close.TextSize = 26
	close.Font = Theme.FontBold
	close.TextColor3 = MC.Title
	close.Activated:Connect(function()
		setBigOpen(false)
	end)

	-- Hora y tiempo: ☀ 10:27  ☁ 22°C
	-- (cada pieza en su sitio, sin UIListLayout: el halo del panel también es un hijo y la lista lo
	-- contaba como una pieza más: salían cápsulas vacías y la hora encima del ✖)
	local clock = navyPanel("Clock", 26)
	local skyIcon = Icons.new("sol", { Name = "Sky", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.12, 0.5), Size = UDim2.fromOffset(30, 30), ZIndex = 23, Parent = clock })
	local timeLabel = Theme.label({ Name = "Time", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.35, 0.5), Size = UDim2.new(0.3, 0, 0, 30), Text = "--:--", Font = Theme.FontBold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23, Parent = clock })
	local weatherIcon = Icons.new("nube", { Name = "Weather", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.6, 0.5), Size = UDim2.fromOffset(30, 30), ZIndex = 23, Parent = clock })
	local tempLabel = Theme.label({ Name = "Temp", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.83, 0.5), Size = UDim2.new(0.28, 0, 0, 30), Text = "--°C", Font = Theme.FontBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23, Parent = clock })

	-- Brújula (N / S / E / O): el norte del mapa siempre arriba
	local compass = create("Frame", {
		Name = "Compass",
		BackgroundColor3 = MC.Panel,
		BackgroundTransparency = 0.1,
		ZIndex = 22,
		Parent = big,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(160, 170, 200)) }),
	})
	create("UIStroke", { Color = MC.Edge, Thickness = 3, Transparency = 0.05, Parent = compass })
	Theme.halo(compass, MC.Glow, 10, 999)
	overlays.Compass = compass
	-- Rosa: dos barras largas (norte-sur y este-oeste), dos diagonales más cortas y el centro
	for _, bar in { { 0, 0.09, 0.66, rgb(235, 245, 255) }, { 90, 0.09, 0.66, rgb(235, 245, 255) }, { 45, 0.05, 0.44, rgb(120, 200, 255) }, { -45, 0.05, 0.44, rgb(120, 200, 255) } } do
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(bar[2], bar[3]),
			Rotation = bar[1],
			BackgroundColor3 = bar[4],
			BorderSizePixel = 0,
			ZIndex = 23,
			Parent = compass,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(60, 140, 255)) }),
		})
	end
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.14, 0.14), BackgroundColor3 = rgb(40, 120, 255), ZIndex = 24, Parent = compass }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),
	})
	for _, letter in { { "N", 0.5, 0.11 }, { "S", 0.5, 0.89 }, { "E", 0.89, 0.5 }, { "O", 0.11, 0.5 } } do
		Theme.label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(letter[2], letter[3]),
			Size = UDim2.fromScale(0.2, 0.2),
			Text = letter[1],
			Font = Theme.FontBold,
			TextScaled = true,
			TextColor3 = MC.Title,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 24,
			Parent = compass,
		})
	end

	-- Acercar, alejar y «dónde estoy»
	local zoomColumn = create("Frame", { Name = "Zoom", BackgroundTransparency = 1, ZIndex = 22, Parent = big })
	overlays.Zoom = zoomColumn
	local zoomList = create("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = zoomColumn })
	local function mapCenter(): Vector2
		local area = screen.Map
		return Vector2.new(area.X + area.W / 2, area.Y + area.H / 2)
	end
	local zoomIn = circleButton(zoomColumn, "ZoomIn")
	zoomIn.LayoutOrder = 1
	Icons.plus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), Thickness = 4, ZIndex = 25, Parent = zoomIn })
	zoomIn.Activated:Connect(function()
		setZoom(zoom * 1.4, mapCenter())
	end)
	local zoomOut = circleButton(zoomColumn, "ZoomOut")
	zoomOut.LayoutOrder = 2
	Icons.minus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), Thickness = 4, ZIndex = 25, Parent = zoomOut })
	zoomOut.Activated:Connect(function()
		setZoom(zoom / 1.4, mapCenter())
	end)
	local locate = circleButton(zoomColumn, "Locate")
	locate.LayoutOrder = 3
	Icons.new("lugar", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), ZIndex = 25, Parent = locate })
	locate.Activated:Connect(function()
		local root = myRoot()
		if root and zoom < 1.9 then
			centerOn(root.Position, 2.2)
		else
			fitAll() -- (ya estabas centrado: otra vez, toda la isla)
		end
	end)

	-- Dónde estás: 📍 Valmar · 37.6289° N 0.7307° W
	local location = navyPanel("Location", 20)
	Icons.new("lugar", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(34, 34), ZIndex = 23, Parent = location })
	local placeTitle = Theme.label({ Name = "Title", Position = UDim2.new(0, 60, 0.5, -24), Size = UDim2.new(1, -70, 0, 24), Text = MapScreen.Region, Font = Theme.FontBold, TextSize = 21, TextColor3 = MC.Title, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 23, Parent = location })
	local placeCoords = Theme.label({ Name = "Coords", Position = UDim2.new(0, 60, 0.5, 2), Size = UDim2.new(1, -70, 0, 20), Text = MapScreen.coords(0, 0), TextSize = 16, TextColor3 = MC.Sub, TextScaled = true, ZIndex = 23, Parent = location })
	create("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 11, Parent = placeCoords })

	-- 🎮 Toca un lugar o mantén el dedo para ver más
	local hint = navyPanel("Hint", 26)
	Icons.new("mando", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.fromOffset(28, 28), ZIndex = 23, Parent = hint })
	Theme.label({
		Name = "Text",
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.new(1, -64, 1, 0),
		Text = if touchOnly then MapScreen.Hint else MapScreen.HintDesktop,
		TextSize = 16,
		TextColor3 = rgb(225, 232, 248),
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 23,
		Parent = hint,
	})

	-- ✖ Quitar ruta (solo con una ruta tuya marcada)
	local clearRoute = Theme.button({
		Name = "ClearRoute",
		Text = "✖  Quitar ruta",
		TextSize = 17,
		BackgroundColor3 = rgb(170, 40, 60),
		Visible = false,
		ZIndex = 24,
		Parent = big,
	})
	local corner = clearRoute:FindFirstChildWhichIsA("UICorner")
	if corner then
		corner.CornerRadius = UDim.new(1, 0)
	end
	overlays.ClearRoute = clearRoute
	clearRouteButton = clearRoute
	clearRoute.Activated:Connect(function()
		Gps.clear()
		setWaypoint(nil)
	end)

	-- Distritos: tocar uno centra el mapa en él
	local districtPanel, districtList = listPanel("Districts", "Distritos")
	for i, d in MapScreen.Districts do
		local row = listRow(districtList, "District_" .. d.Id, i, d.Icon, d.Color, d.Name, d.Sub)
		row.Activated:Connect(function()
			centerOn(Vector3.new(d.Center.X, 0, d.Center.Y), 1.8)
			if not screen.Wide then
				drawerOpen = nil
				refreshDrawers()
			end
		end)
	end

	-- Lugares importantes: tocar marca la ruta con el GPS (al más cercano si hay varios) y mantener
	-- el dedo enseña la tarjeta con más datos. Debajo, la leyenda por categorías.
	local placesPanel, placesList = listPanel("Places", "Lugares importantes")
	local rows: { { Row: TextButton, Places: { Landmark }, Sub: string } } = {}
	for i, entry in MapScreen.placeRows(landmarks :: any) do
		local row = listRow(placesList, "Place_" .. entry.Kind.Model, i, entry.Icon, entry.Color, entry.Title, entry.Sub)
		local function target(): Landmark
			local root = myRoot()
			return MapScreen.nearest(entry.Places :: any, if root then root.Position else nil) :: any
		end
		onPress(row, function()
			local place = target()
			if not (waypoint and waypoint.Position == place.Position) then
				setWaypoint({ Position = place.Position, Name = entry.Kind.Name })
			end
			centerOn(place.Position, math.max(zoom, 2.2))
		end, function()
			local place = target()
			showInfo(entry.Kind.Name, place.Position, entry.Icon)
		end)
		table.insert(rows, { Row = row, Places = entry.Places :: any, Sub = entry.Sub })
	end
	refreshWaypointList = function()
		for _, entry in rows do
			local marked = false
			for _, placeInfo in entry.Places do
				if waypoint ~= nil and waypoint.Position == placeInfo.Position then
					marked = true
				end
			end
			entry.Row.BackgroundColor3 = if marked then MC.RowMarked else MC.Row
			local sub = entry.Row:FindFirstChild("Sub") :: TextLabel
			sub.Text = if marked then "📍 Ruta marcada · toca ✖ para quitarla" else entry.Sub
		end
		if clearRouteButton then
			clearRouteButton.Visible = waypoint ~= nil
		end
	end

	Theme.label({ Name = "LegendTitle", Size = UDim2.new(1, -10, 0, 34), Text = "Leyenda", Font = Theme.FontBold, TextSize = 22, TextColor3 = MC.Title, LayoutOrder = 100, ZIndex = 23, Parent = placesList })
	Theme.label({
		Name = "LegendKeys",
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "▲ " .. Strings.get("MAP.YOU") .. "     ★ " .. Strings.get("MAP.TARGET") .. "\n📍 Sitio marcado     ● Otros jugadores",
		TextSize = 15,
		TextColor3 = MC.Sub,
		TextWrapped = true,
		LayoutOrder = 101,
		ZIndex = 23,
		Parent = placesList,
	})
	-- 🏠 Casa: fija (no se puede ocultar)
	local homeRow = listRow(placesList, "Home", 102, MapLegend.Home.Icon, rgb(255, 150, 40), "Casa", "Siempre visible")
	homeRow.Activated:Connect(function()
		local homes = MapLegend.homeMarkers(player:GetAttribute("FamilyHomePos"), player:GetAttribute("OwnHomePos"))
		if homes[1] then
			centerOn(homes[1].Position, math.max(zoom, 2.2))
		end
	end)
	-- Categorías con cuántos lugares hay de cada una (las que no tienen ninguno no salen)
	local models = {}
	for _, placeInfo in landmarks do
		table.insert(models, placeInfo.Kind.Model)
	end
	local legendRows: { { Row: TextButton, Id: string } } = {}
	local allRow = listRow(placesList, "ShowAll", 103, "👁", rgb(60, 80, 120), "Mostrar todo", "Toca para ocultar todos los lugares")
	allRow.Activated:Connect(function()
		MapLegend.setAll(hidden, next(hidden) == nil)
		refreshLegend()
		saveFilters()
	end)
	for i, entry in MapLegend.summary(models) do
		local category = entry.Category
		local row = listRow(placesList, "Legend_" .. category.Id, 103 + i, category.Icon, MapScreen.CategoryColors[category.Id] or MapScreen.DefaultColor, MapLegend.title(category, entry.Count), "")
		row.Activated:Connect(function()
			MapLegend.toggle(hidden, category.Id)
			refreshLegend()
			saveFilters()
		end)
		table.insert(legendRows, { Row = row, Id = category.Id })
	end
	refreshLegendRows = function()
		for _, entry in legendRows do
			local hide = hidden[entry.Id] == true
			(entry.Row:FindFirstChild("Sub") :: TextLabel).Text = if hide then "Oculto · toca para mostrar" else "Visible · toca para ocultar"
			entry.Row.BackgroundTransparency = if hide then 0.65 else 0.2
		end
		local any = next(hidden) ~= nil
		(allRow:FindFirstChild("Title") :: TextLabel).Text = if any then "Mostrar todo" else "Ocultar todo"
		(allRow:FindFirstChild("Sub") :: TextLabel).Text = if any then "Toca para ver todos los lugares" else "Toca para ocultar todos los lugares (🏠 sigue)"
	end
	refreshLegendRows()

	-- Pantallas pequeñas: los dos paneles se recogen en pestañas (uno abierto a la vez, encima del mapa)
	local tabs: { [string]: TextButton } = {}
	for _, tab in { { "TabDistricts", "🏙️  Distritos", "Districts" }, { "TabPlaces", "📍  Lugares", "Places" } } do
		local button = create("TextButton", {
			Name = tab[1],
			BackgroundColor3 = MC.Panel,
			BackgroundTransparency = 0.08,
			AutoButtonColor = true,
			Text = tab[2],
			Font = Theme.FontBold,
			TextSize = 18,
			TextColor3 = MC.Title,
			ZIndex = 24,
			Parent = big,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		create("UIStroke", { Color = MC.Edge, Thickness = 2, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button })
		Theme.pressable(button)
		button.Activated:Connect(function()
			drawerOpen = if drawerOpen == tab[3] then nil else tab[3]
			refreshDrawers()
		end)
		overlays[tab[1]] = button
		tabs[tab[3]] = button
	end
	refreshDrawers = function()
		local wide = screen.Wide
		districtPanel.Visible = wide or drawerOpen == "Districts"
		placesPanel.Visible = wide or drawerOpen == "Places"
		for id, button in tabs do
			button.Visible = not wide
			button.BackgroundColor3 = if drawerOpen == id then Theme.Hud.Select else MC.Panel
		end
	end

	-- Tarjeta «ver más» (mantener el dedo en un lugar): nombre, distrito, distancia e «Ir aquí»
	local info = navyPanel("Info", 20)
	info.Visible = false
	local infoTitle = Theme.label({ Name = "Title", Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -80, 0, 26), Text = "", Font = Theme.FontBold, TextSize = 21, TextColor3 = MC.Title, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 23, Parent = info })
	local infoSub = Theme.label({ Name = "Sub", Position = UDim2.fromOffset(18, 38), Size = UDim2.new(1, -36, 0, 20), Text = "", TextSize = 16, TextColor3 = MC.Sub, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 23, Parent = info })
	local infoClose = circleButton(info, "InfoClose")
	infoClose.AnchorPoint = Vector2.new(1, 0)
	infoClose.Position = UDim2.new(1, -8, 0, 8)
	infoClose.Size = UDim2.fromOffset(44, 44)
	infoClose.Text = "✖"
	infoClose.TextSize = 20
	infoClose.TextColor3 = MC.Title
	local infoGo = Theme.button({
		Name = "Go",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -10),
		Size = UDim2.new(1, -28, 0, 44),
		Text = "🧭  Ir aquí (GPS)",
		TextSize = 17,
		BackgroundColor3 = Theme.Hud.Select,
		ZIndex = 24,
		Parent = info,
	})
	local infoTarget: { Position: Vector3, Name: string }? = nil
	infoClose.Activated:Connect(function()
		info.Visible = false
	end)
	infoGo.Activated:Connect(function()
		local target = infoTarget
		if target and not (waypoint and waypoint.Position == target.Position) then
			setWaypoint(target)
		end
		info.Visible = false
	end)
	showInfo = function(name: string, position: Vector3, icon: string?)
		infoTarget = { Position = position, Name = name }
		infoTitle.Text = (if icon then icon .. "  " else "") .. name
		local distance = distanceText(position)
		infoSub.Text = MapScreen.districtName(position.X, position.Z) .. (if distance then "  ·  a " .. distance else "")
		local area = screen.Map
		info.Size = UDim2.fromOffset(math.min(400, area.W - 20), 128)
		info.Position = UDim2.fromOffset(area.X + (area.W - math.min(400, area.W - 20)) / 2, area.Y + area.H - 128 - 70)
		info.Visible = true
		centerOn(position, math.max(zoom, 2.2))
	end

	-- La hora, el tiempo y dónde estás (solo se reescriben si cambian)
	updateHud = function()
		local hour = GameClock.hour()
		Theme.setText(timeLabel, ("%02d:%02d"):format(math.floor(hour) % 24, math.floor((hour % 1) * 60)))
		local night = hour < 6.5 or hour >= 20
		local sky = if night then "luna" else "sol"
		if skyIcon:GetAttribute("Icon") ~= sky then
			Icons.set(skyIcon, sky)
		end
		local weather = workspace:GetAttribute("Weather") or "Despejado"
		local season = workspace:GetAttribute("Season") or "Primavera"
		local weatherName = Icons.Weather[weather] or "nube"
		if weatherName == "sol" then
			weatherName = "nube" -- (el sol ya sale a la izquierda: despejado = nube clara, como en el dibujo)
		end
		if weatherIcon:GetAttribute("Icon") ~= weatherName then
			Icons.set(weatherIcon, weatherName)
		end
		local okTemp, temp = pcall(Seasons.temperature, season, weather, hour)
		Theme.setText(tempLabel, if okTemp then ("%d°C"):format(temp) else "--°C")
		local root = myRoot()
		if root then
			local zone = zoneAt(root.Position)
			local district = MapScreen.districtNear(root.Position.X, root.Position.Z)
			Theme.setText(placeTitle, zone or (if district then district.Name else MapScreen.Region))
			Theme.setText(placeCoords, MapScreen.coords(root.Position.X, root.Position.Z))
		end
	end

	-- Dónde va cada pieza según la pantalla (MapScreen.layout)
	local camera = workspace.CurrentCamera
	local function resize()
		local v = camera.ViewportSize
		local topbarRight: number? = nil
		pcall(function()
			local inset = (GuiService :: any).TopbarInset
			if typeof(inset) == "Rect" and inset.Min.X > 0 then
				topbarRight = inset.Min.X
			end
		end)
		screen = MapScreen.layout(v, { TopbarRight = topbarRight })
		bigScale.Scale = screen.Scale
		big.Size = UDim2.fromOffset(screen.Canvas.X, screen.Canvas.Y)
		holderSize = screen.Canvas
		for name, object in overlays do
			local r = screen.Rects[name]
			if r then
				object.Position = UDim2.fromOffset(r.X, r.Y)
				object.Size = UDim2.fromOffset(r.W, r.H)
			end
		end
		hint.Visible = screen.Rects.Hint ~= nil
		-- (+ / − / ◎: en fila debajo de los lugares o en columna, según su hueco)
		local z = screen.Rects.Zoom
		zoomList.FillDirection = if z.W > z.H then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
		for _, header in headers do
			header.TextSize = screen.Text.Header
			local max = header:FindFirstChild("Max") :: UITextSizeConstraint?
			if max then
				max.MaxTextSize = screen.Text.Header
			end
		end
		refreshDrawers()
		if bigLayer then
			applyView()
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	resize()

	-- Mover (arrastrar), acercar (rueda o pellizco con dos dedos) y mantener pulsado = «Ir aquí»
	local dragging: InputObject? = nil
	local pressedAt = 0
	local dragStart = Vector2.zero
	local panStart = Vector2.zero
	local touches: { [InputObject]: Vector2 } = {}
	local pinch: { Distance: number, Zoom: number, Middle: Vector2 }? = nil
	local function pointer(input: InputObject): Vector2
		if input.UserInputType == Enum.UserInputType.Touch then
			return Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
		end
		return UserInputService:GetMouseLocation()
	end
	-- ¿Ese punto de la pantalla cae en el mapa (y no en un panel, un botón o la tarjeta)?
	local function onMap(screenPoint: Vector2): boolean
		local p, s = big.AbsolutePosition, big.AbsoluteSize
		if screenPoint.X < p.X or screenPoint.X > p.X + s.X or screenPoint.Y < p.Y or screenPoint.Y > p.Y + s.Y then
			return false
		end
		for _, object in overlays do
			if object.Visible then
				local op, os_ = object.AbsolutePosition, object.AbsoluteSize
				if screenPoint.X >= op.X and screenPoint.X <= op.X + os_.X and screenPoint.Y >= op.Y and screenPoint.Y <= op.Y + os_.Y then
					return false
				end
			end
		end
		return true
	end
	local function toCanvas(screenPoint: Vector2): Vector2
		return (screenPoint - big.AbsolutePosition) / bigScale.Scale
	end
	local function twoTouches(): (Vector2?, Vector2?)
		local a, b = nil, nil
		for _, at in touches do
			if not a then
				a = at
			elseif not b then
				b = at
			end
		end
		return a, b
	end
	UserInputService.InputBegan:Connect(function(input)
		if not bigOpen then
			return
		end
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			local at = pointer(input)
			if not onMap(at) then
				return
			end
			if kind == Enum.UserInputType.Touch then
				touches[input] = at
				local a, b = twoTouches()
				if a and b then
					-- Segundo dedo: pellizco (y nada de arrastrar ni de «mantener pulsado»)
					pinch = { Distance = math.max(1, (a - b).Magnitude), Zoom = zoom, Middle = toCanvas((a + b) / 2) }
					dragging = nil
					dragMoved = true
					return
				end
			end
			dragging = input
			dragStart = at
			panStart = pan
			dragMoved = false
			pressedAt = os.clock()
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not bigOpen then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local at = UserInputService:GetMouseLocation()
			if onMap(at) then
				setZoom(zoom * (if input.Position.Z > 0 then 1.2 else 1 / 1.2), toCanvas(at))
			end
			return
		end
		if touches[input] then
			touches[input] = pointer(input)
			local a, b = twoTouches()
			local current = pinch
			if current and a and b then
				local middle = toCanvas((a + b) / 2)
				pan += middle - current.Middle -- (los dos dedos también mueven el mapa)
				current.Middle = middle
				setZoom(current.Zoom * (a - b).Magnitude / current.Distance, middle)
				return
			end
		end
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragging) then
			local delta = (pointer(input) - dragStart) / bigScale.Scale
			if delta.Magnitude > 6 then
				dragMoved = true
			end
			if dragMoved then
				pan = panStart + delta
				applyView()
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if touches[input] then
			touches[input] = nil
			local a, b = twoTouches()
			if not (a and b) then
				pinch = nil
			end
		end
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
			-- Mantener pulsado (sin arrastrar) en un sitio sin nada: «Ir aquí». Si era un lugar del mapa, ya
			-- lo ha atendido el lugar (tocar = ruta, mantener = tarjeta)
			local layer = bigLayer
			if not dragMoved and not pinPressed and os.clock() - pressedAt > 0.5 and layer then
				local world = toWorld(layer, (toCanvas(dragStart) - pan) / zoom)
				waypoint = nil
				setWaypoint({ Position = world, Name = "Punto marcado" })
			end
			dragging = nil
			task.defer(function()
				dragMoved = false
			end)
		end
		pinPressed = false
	end)
end

-- Para las pruebas (scripts/test-clientboot.luau): lo que hay dentro del mapa grande
function MapUI._state(): { [string]: any }
	return {
		Zoom = zoom,
		Waypoint = waypoint,
		Screen = screen,
		Layer = bigLayer,
		Landmarks = #landmarks,
		Drawer = drawerOpen,
	}
end

function MapUI.init()
	loadData()
	-- Filtros guardados con la partida (HomeMapService): llegan en el atributo MapHidden
	hidden = MapLegend.decode(player:GetAttribute("MapHidden"))
	buildMini()
	buildBig()
	Dialog.registerBig("BigMap", function()
		if bigOpen then
			setBigOpen(false)
		end
	end, MapUI.isOpen)
	refreshLegend()
	player:GetAttributeChangedSignal("MapHidden"):Connect(function()
		local saved = MapLegend.decode(player:GetAttribute("MapHidden"))
		if MapLegend.encode(saved) ~= MapLegend.encode(hidden) then
			hidden = saved
			refreshLegend()
		end
	end)
	-- GPS: la línea de la ruta en los dos mapas, y el sitio marcado se quita al llegar
	Gps.onChanged(function(path, full, index)
		routePath = path
		routeFull = if path then full else nil
		routeIndex = index or 1
		drawRoute(miniLayer)
		if bigOpen then
			drawRoute(bigLayer)
		else
			bigRouteDirty = true
		end
	end)
	-- El 📍 va con la ruta marcada, la ponga quien la ponga (el mapa, "Ruta a casa", el plano del
	-- metro, el ❓…) y se quita al llegar, con × o con «Seguir misión»
	Gps.onManual(function(place)
		local same = (waypoint == nil and place == nil) or (waypoint ~= nil and place ~= nil and waypoint.Position == place.Position and waypoint.Name == place.Name)
		if not same then
			waypoint = if place then { Position = place.Position, Name = place.Name } else nil
			refreshWaypointList()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			MapUI.toggleBig()
		end
	end)

	local elapsed = 0
	local miniAt: Vector2? = nil -- dónde se puso el minimapa la última vez
	RunService.Heartbeat:Connect(function(dt)
		if next(spins) then
			stepSpins(dt)
		end
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		local character = player.Character
		local root = mapRoot(player, character and character:FindFirstChild("HumanoidRootPart") :: BasePart?)
		-- En Tefra, el minimapa de Bastión Ceniza (y al volver, el de Valmar)
		if syncMiniWorld() then
			miniAt = nil
			setMiniZoom(miniZoom)
		end
		-- El minimapa se mueve para que tú estés siempre en el centro
		local inner = MINI_SIZE - 8
		local zoom = MINI_ZOOMS[miniZoom]
		if root then
			local p = toPixel(miniLayer, root.Position.X, root.Position.Z)
			-- (si se ha movido menos de 1 píxel no se toca: cada cambio de Position recoloca todo el mapa)
			local at = Vector2.new(inner / 2 - p.X * zoom, inner / 2 - p.Y * zoom)
			if not miniAt or (at - miniAt).Magnitude >= 1 then
				miniAt = at
				miniLayer.Frame.Position = UDim2.fromOffset(at.X, at.Y)
			end
			local current = waypoint
			if current then
				local distance = Vector3.new(current.Position.X - root.Position.X, 0, current.Position.Z - root.Position.Z).Magnitude
				zoneLabel.Text = ("📍 %s · %d m"):format(current.Name, math.floor(distance / 3.5))
			end
			if onTefra() then
				local lx, lz = Tefra.toLocal(root.Position)
				local barrio = TefraCity.districtAt(lx, lz)
				zoneLabel.Text = if barrio then barrio.Name .. " · " .. TefraCity.Name else "Tefra"
			elseif not waypoint then
				local district = MapInfo.districtAt(root.Position.X, root.Position.Z)
				local zone = zoneAt(root.Position)
				zoneLabel.Text = if district and zone then zone .. " · " .. district.Name elseif district then district.Name else (zone or "Valmar")
			end
		end
		updateLayer(miniLayer, root, (inner / 2 - 12) / zoom)
		if bigOpen and bigLayer then
			updateLayer(bigLayer, root, nil)
			updateHud()
		end
	end)
end

return MapUI
