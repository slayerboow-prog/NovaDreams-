-- MapUI (cliente): el mapa de Valmar, con el estilo del mapa ilustrado de la ciudad.
--   * Minimapa redondo arriba a la derecha (junto al menú rápido, UI/HudLayout): aro brillante con la N,
--     marcas de los puntos cardinales, botones + y − para acercar, el sol (o la luna) al lado y, dentro,
--     distritos de colores, calles, mar, lugares, tu flecha, tu objetivo (★), el sitio que marques (📍)
--     y los demás jugadores. Si el objetivo está lejos, se queda en el borde señalando hacia dónde ir.
--   * Mapa grande (botón "Mapa", el botón del mapa del minimapa o la tecla M): toda la región con los distritos,
--     la lista de distritos, los lugares importantes (pulsa uno para marcarlo) y la leyenda.
--     Se mueve arrastrando y se acerca con la rueda del ratón o con los botones + y −.
-- GPS (Controllers/Gps): la ruta hasta tu destino se dibuja en los dos mapas como una línea que brilla
-- por las calles. En el mapa grande, mantén pulsado en cualquier sitio para "Ir aquí" y "Quitar ruta" la quita.
-- Lee las calles de ReplicatedStorage.Ambient.Roads, las zonas de ReplicatedStorage.MapZones y los lugares
-- de ReplicatedStorage.MapLandmarks (los publica el servidor), así que se adapta solo si el mapa cambia.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local Gps = require(script.Parent.Gps)

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

-- Medidas del mapa grande (antes de escalar)
local PANEL_PAD = 14
local HEADER = 54
local FOOTER = 26
local LEFT_W = 250
local RIGHT_W = 270
local GAP = 12

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
	Icons: { { Holder: GuiObject, Kind: string } },
	Scalers: { UIScale },
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
local hidden: { [string]: boolean } = {} -- tipos de lugar ocultos desde la leyenda

local waypoint: { Position: Vector3, Name: string }? = nil
local zoom = 1
local pan = Vector2.zero
local holderSize = Vector2.new(800, 600)
local refreshWaypointList: () -> () = function() end

---------------------------------------------------------------------
-- Datos
---------------------------------------------------------------------

local function loadData()
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
	local zoneFolder = ReplicatedStorage:WaitForChild("MapZones", 10)
	if zoneFolder then
		for _, config in zoneFolder:GetChildren() do
			local name, center = config:GetAttribute("ZoneName"), config:GetAttribute("Center")
			if type(name) == "string" and typeof(center) == "Vector3" then
				table.insert(zones, { Name = name, Center = center })
			end
		end
	end
	local landmarkFolder = ReplicatedStorage:WaitForChild("MapLandmarks", 10)
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
	return Vector2.new((x - layer.Min.X) / layer.Scale, (z - layer.Min.Y) / layer.Scale)
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

-- Cosas que no deben crecer tanto al acercar el mapa llevan un UIScale propio
local function keepSize(layer: Layer, object: GuiObject)
	local s = create("UIScale", { Parent = object })
	table.insert(layer.Scalers, s)
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

local function landmarkIcon(layer: Layer, place: Landmark, detailed: boolean)
	local p = toPixel(layer, place.Position.X, place.Position.Z)
	local important = place.Kind.Important == true
	local size = if detailed then (if important then 30 else 24) else (if important then 18 else 14)
	local district = MapInfo.districtAt(place.Position.X, place.Position.Z)
	local icon = create(if detailed then "TextButton" else "Frame", {
		Name = place.Kind.Model,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(p.X, p.Y),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = if detailed then 0.05 else 0.15,
		BorderSizePixel = 0,
		ZIndex = if important then 5 else 4,
		Parent = layer.Frame,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = if district then district.Color else rgb(60, 70, 90), Thickness = if detailed then 2 else 1.5 }),
	})
	if icon:IsA("TextButton") then
		icon.Text = ""
		icon.AutoButtonColor = true
		icon.Activated:Connect(function()
			if not dragMoved then
				setWaypoint({ Position = place.Position, Name = place.Kind.Name })
			end
		end)
	end
	Theme.label({
		Size = UDim2.fromScale(1, 1),
		Text = place.Kind.Icon,
		TextSize = math.floor(size * 0.62),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = icon.ZIndex,
		Parent = icon,
	})
	if detailed and important then
		Theme.label({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 2),
			Size = UDim2.fromOffset(140, 14),
			Text = place.Kind.Name,
			TextSize = 12,
			Font = Theme.FontBold,
			TextStrokeTransparency = 0.25,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = icon.ZIndex,
			Parent = icon,
		})
	end
	keepSize(layer, icon)
	table.insert(layer.Icons, { Holder = icon, Kind = place.Kind.Model })
end

local function buildLayer(parent: Instance, scale: number, detailed: boolean): Layer
	local extent = (boundsMax - boundsMin) / scale
	local frame = create("Frame", {
		Name = "World",
		Size = UDim2.fromOffset(extent.X, extent.Y),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = parent,
	}, { create("UIGradient", { Rotation = 90, Color = ColorSequence.new(SEA_TOP, SEA_BOTTOM) }) })
	local layer: Layer = {
		Frame = frame,
		Scale = scale,
		Min = boundsMin,
		Me = nil :: any,
		Target = nil :: any,
		Waypoint = nil :: any,
		Dots = {},
		Icons = {},
		Scalers = {},
	}
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
	-- Montañas (más oscuras, con la cima gris si es de roca)
	for _, m in CityPlan.Mountains do
		local ground = math.sqrt(math.max(0, m.R * m.R - (m.R - m.H) ^ 2))
		circle(layer, "Mountain", m.X, m.Z, ground, rgb(80, 128, 70), 1).BackgroundTransparency = 0.1
		if m.Rock then
			circle(layer, "Peak", m.X, m.Z, ground * 0.4, rgb(150, 144, 132), 1)
		end
	end
	-- Distritos: color suave y borde
	for _, d in MapInfo.Districts do
		if detailed then
			fill(d.Poly, d.Color, 0, 0.72, 1)
		end
		for k = 1, #d.Poly do
			local p1, p2 = d.Poly[k], d.Poly[k % #d.Poly + 1]
			line(Vector2.new(p1[1], p1[2]), Vector2.new(p2[1], p2[2]), if detailed then 3 else 2, d.Color, 2, 0.15)
		end
	end
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
	-- Nombre de cada distrito (solo en el mapa grande)
	if detailed then
		for _, d in MapInfo.Districts do
			local p = toPixel(layer, d.Center.X, d.Center.Y)
			local pill = create("Frame", {
				Name = "Label",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(p.X, p.Y),
				Size = UDim2.fromOffset(0, 40),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = d.Color,
				BackgroundTransparency = 0.08,
				ZIndex = 6,
				Parent = frame,
			}, {
				Theme.corner(12),
				create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.2 }),
				create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }),
			})
			Theme.label({ Size = UDim2.fromOffset(26, 40), Text = d.Icon, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6, Parent = pill })
			Theme.label({
				Position = UDim2.fromOffset(30, 3),
				Size = UDim2.fromOffset(0, 20),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = string.upper(d.Name),
				Font = Theme.FontBold,
				TextSize = 15,
				TextStrokeTransparency = 0.6,
				ZIndex = 6,
				Parent = pill,
			})
			Theme.label({
				Position = UDim2.fromOffset(30, 21),
				Size = UDim2.fromOffset(0, 16),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = d.Theme,
				TextSize = 11,
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
	for _, place in landmarks do
		landmarkIcon(layer, place, detailed)
	end
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
local routePath: { Vector3 }? = nil

local function drawRoute(layer: Layer?)
	if not layer then
		return
	end
	local old = layer.Frame:FindFirstChild("Route")
	if old then
		old:Destroy()
	end
	local path = routePath
	if not path or #path < 2 then
		return
	end
	local holderFrame = create("Frame", { Name = "Route", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = layer.Frame })
	local thick = if layer == miniLayer then 6 else 5
	for i = 1, math.min(#path - 1, MAX_ROUTE_PIECES) do
		local a = toPixel(layer, path[i].X, path[i].Z)
		local b = toPixel(layer, path[i + 1].X, path[i + 1].Z)
		local d = b - a
		local length = d.Magnitude
		if length > 0.3 then
			local middle = (a + b) / 2
			for _, style in { { thick + 7, ROUTE_GLOW, 0.6, 5 }, { thick, ROUTE, 0, 6 } } do
				create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(middle.X, middle.Y),
					Size = UDim2.fromOffset(length + style[1], style[1]),
					Rotation = math.deg(math.atan2(d.Y, d.X)),
					BackgroundColor3 = style[2],
					BackgroundTransparency = style[3],
					BorderSizePixel = 0,
					ZIndex = style[4],
					Parent = holderFrame,
				}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			end
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
		TweenService:Create(layer.Me, TweenInfo.new(0.1, Enum.EasingStyle.Linear), { Rotation = current + delta }):Play()
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

	-- Objetivo de la historia o del trabajo (el mismo que marca el haz de luz)
	local target = player:GetAttribute("TaskTarget")
	if typeof(target) ~= "Vector3" then
		target = player:GetAttribute("StoryTarget")
	end
	place(layer, layer.Target, if typeof(target) == "Vector3" then target else nil, root, clampTo)
	place(layer, layer.Waypoint, if waypoint then waypoint.Position else nil, root, clampTo)

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
	local keep = 1 / zoom ^ 0.75 -- los iconos crecen solo un poco al acercar
	for _, s in layer.Scalers do
		s.Scale = keep
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
	pan = holderSize / 2 - p * zoom
	applyView()
end

local function fitAll()
	local layer = bigLayer
	if not layer then
		return
	end
	zoom = 1
	local extent = Vector2.new(layer.Frame.Size.X.Offset, layer.Frame.Size.Y.Offset)
	pan = (holderSize - extent) / 2
	applyView()
end

local function refreshLegend()
	local layer = bigLayer
	if layer then
		for _, icon in layer.Icons do
			icon.Holder.Visible = not hidden[icon.Kind]
		end
	end
	for _, icon in miniLayer.Icons do
		icon.Holder.Visible = not hidden[icon.Kind]
	end
end

local function ensureBigLayer()
	if bigLayer then
		return
	end
	local extent = boundsMax - boundsMin
	local scale = math.max(extent.X / math.max(holderSize.X, 100), extent.Y / math.max(holderSize.Y, 100))
	bigLayer = buildLayer(holder, scale, true)
	local layer = bigLayer :: Layer
	create("UIScale", { Name = "Zoom", Parent = layer.Frame })
	drawRoute(layer)
	refreshLegend()
	fitAll()
end

local function setBigOpen(open: boolean)
	bigOpen = open
	bigGui.Enabled = open
	if open then
		ensureBigLayer()
		local root = mapRoot(player, player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?)
		if root and zoom <= 1 then
			centerOn(root.Position, 1.6)
		end
	end
end

function MapUI.toggleBig()
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
	for _, s in miniLayer.Scalers do
		s.Scale = 1 / zoom -- los iconos no cambian de tamaño
	end
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
		local clock = game:GetService("Lighting").ClockTime
		Icons.set(sky, if clock >= 6.5 and clock < 20 then "sol" else "luna")
	end
	game:GetService("Lighting"):GetPropertyChangedSignal("ClockTime"):Connect(function()
		local clock = game:GetService("Lighting").ClockTime
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

local function sectionTitle(parent: Instance, text: string, order: number)
	Theme.label({
		Size = UDim2.new(1, 0, 0, 26),
		Text = text,
		Font = Theme.FontBold,
		TextSize = 17,
		TextColor3 = C.Accent,
		LayoutOrder = order,
		ZIndex = 21,
		Parent = parent,
	})
end

local function column(parent: Instance, name: string, x: UDim, width: number): ScrollingFrame
	local frame = create("ScrollingFrame", {
		Name = name,
		Position = UDim2.new(x.Scale, x.Offset, 0, HEADER),
		Size = UDim2.new(0, width, 1, -HEADER - FOOTER),
		BackgroundColor3 = rgb(8, 16, 32),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 21,
		Parent = parent,
	}, { Theme.corner(12), Theme.padding(10) })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })
	return frame
end

local function listRow(parent: Instance, order: number, icon: string, color: Color3, title: string, sub: string): TextButton
	local row = create("TextButton", {
		Size = UDim2.new(1, -4, 0, 44),
		BackgroundColor3 = rgb(24, 38, 66),
		BackgroundTransparency = 0.2,
		AutoButtonColor = true,
		Text = "",
		LayoutOrder = order,
		ZIndex = 21,
		Parent = parent,
	}, { Theme.corner(10) })
	local badge = create("Frame", {
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(6, 6),
		BackgroundColor3 = color,
		ZIndex = 21,
		Parent = row,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = icon, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 21, Parent = badge })
	Theme.label({ Name = "Title", Size = UDim2.new(1, -52, 0, 20), Position = UDim2.fromOffset(46, 4), Text = title, Font = Theme.FontBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 21, Parent = row })
	Theme.label({ Name = "Sub", Size = UDim2.new(1, -52, 0, 16), Position = UDim2.fromOffset(46, 23), Text = sub, TextSize = 12, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 21, Parent = row })
	return row
end

local function roundButton(parent: Instance, text: string, y: number, callback: () -> ())
	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -y),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = rgb(12, 22, 42),
		BackgroundTransparency = 0.1,
		Text = text,
		TextSize = 22,
		Font = Theme.FontBold,
		TextColor3 = C.Text,
		ZIndex = 30,
		Parent = parent,
	}, { Theme.corner(10), create("UIStroke", { Color = C.Accent, Thickness = 1.5 }) })
	button.Activated:Connect(callback)
end

local function buildBig()
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
	-- Fondo oscuro: pulsar fuera del mapa lo cierra
	local shade = create("TextButton", {
		Name = "Shade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		AutoButtonColor = false,
		Text = "",
		Parent = bigGui,
	})
	shade.Activated:Connect(function()
		setBigOpen(false)
	end)
	big = create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.04,
		ZIndex = 20,
		Active = true,
		Parent = bigGui,
	}, {
		Theme.corner(18),
		create("UIStroke", { Color = C.Accent, Thickness = 2, Transparency = 0.2 }),
		create("UIGradient", { Rotation = 90, Color = Theme.Night }),
		Theme.padding(PANEL_PAD),
	})

	-- Cabecera
	Theme.label({ Size = UDim2.new(1, -200, 0, 30), Text = "🗺️  " .. string.upper(Strings.get("MAP.TITLE")), Font = Theme.FontBold, TextSize = 24, ZIndex = 21, Parent = big })
	Theme.label({
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, -200, 0, 16),
		Text = "Explora la región: 8 distritos, el puerto, la isla del faro y el mirador",
		TextSize = 13,
		TextColor3 = C.Muted,
		ZIndex = 21,
		Parent = big,
	})
	local close = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(150, 36),
		Text = "✖  " .. Strings.get("MAP.CLOSE") .. " (M)",
		TextSize = 15,
		BackgroundColor3 = rgb(40, 60, 100),
		ZIndex = 22,
		Parent = big,
	})
	close.Activated:Connect(function()
		setBigOpen(false)
	end)

	-- Columna izquierda: distritos
	local left = column(big, "Districts", UDim.new(0, 0), LEFT_W)
	sectionTitle(left, "Distritos", 0)
	for i, d in MapInfo.Districts do
		local row = listRow(left, i, d.Icon, d.Color, d.Name, d.Theme)
		row.Activated:Connect(function()
			centerOn(Vector3.new(d.Center.X, 0, d.Center.Y), 1.8)
		end)
	end

	-- Columna derecha: lugares importantes y leyenda
	local right = column(big, "Places", UDim.new(1, -RIGHT_W), RIGHT_W)
	sectionTitle(right, "Lugares importantes", 0)
	local rows: { { Row: TextButton, Place: Landmark } } = {}
	local important = {}
	for _, placeInfo in landmarks do
		if placeInfo.Kind.Important then
			table.insert(important, placeInfo)
		end
	end
	table.sort(important, function(a, b)
		return a.Kind.Name < b.Kind.Name
	end)
	for i, placeInfo in important do
		local district = MapInfo.districtAt(placeInfo.Position.X, placeInfo.Position.Z)
		local row = listRow(right, i, placeInfo.Kind.Icon, if district then district.Color else rgb(40, 110, 190), placeInfo.Kind.Name, if placeInfo.District ~= "" then placeInfo.District else "Afueras de Valmar")
		row.Activated:Connect(function()
			setWaypoint({ Position = placeInfo.Position, Name = placeInfo.Kind.Name })
			centerOn(placeInfo.Position, math.max(zoom, 2.2))
		end)
		table.insert(rows, { Row = row, Place = placeInfo })
	end
	refreshWaypointList = function()
		for _, entry in rows do
			local marked = waypoint ~= nil and waypoint.Position == entry.Place.Position
			entry.Row.BackgroundColor3 = if marked then rgb(150, 40, 60) else rgb(24, 38, 66)
			local sub = entry.Row:FindFirstChild("Sub") :: TextLabel
			sub.Text = if marked then "📍 Marcado · pulsa otra vez para quitarlo" else (if entry.Place.District ~= "" then entry.Place.District else "Afueras de Valmar")
		end
	end

	sectionTitle(right, "Leyenda", 100)
	Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "▲ " .. Strings.get("MAP.YOU") .. "     ★ " .. Strings.get("MAP.TARGET") .. "\n📍 Sitio marcado     ● Otros jugadores",
		TextSize = 13,
		TextWrapped = true,
		LayoutOrder = 101,
		ZIndex = 21,
		Parent = right,
	})
	for i, group in MapInfo.Legend do
		local row = listRow(right, 101 + i, group.Icon, rgb(40, 110, 190), group.Name, "Visible · pulsa para ocultar")
		row.Activated:Connect(function()
			local hide = not hidden[group.Models[1]]
			for _, model in group.Models do
				hidden[model] = hide or nil
			end
			(row:FindFirstChild("Sub") :: TextLabel).Text = if hide then "Oculto · pulsa para mostrar" else "Visible · pulsa para ocultar"
			row.BackgroundTransparency = if hide then 0.6 else 0.2
			refreshLegend()
		end)
	end

	-- Centro: el mapa
	holder = create("Frame", {
		Name = "Holder",
		Position = UDim2.fromOffset(LEFT_W + GAP, HEADER),
		Size = UDim2.new(1, -(LEFT_W + RIGHT_W + GAP * 2), 1, -HEADER - FOOTER),
		BackgroundColor3 = SEA_BOTTOM,
		ClipsDescendants = true,
		ZIndex = 21,
		Parent = big,
	}, { Theme.corner(14), create("UIStroke", { Color = C.Accent, Thickness = 2, Transparency = 0.3 }) })
	roundButton(holder, "+", 104, function()
		setZoom(zoom * 1.4, holderSize / 2)
	end)
	roundButton(holder, "-", 58, function()
		setZoom(zoom / 1.4, holderSize / 2)
	end)
	roundButton(holder, "🎯", 12, function()
		local root = mapRoot(player, player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?)
		if root then
			centerOn(root.Position, math.max(zoom, 2))
		else
			fitAll()
		end
	end)
	roundButton(holder, "⤡", 150, fitAll)
	-- Quitar la ruta del GPS
	local clearRoute = Theme.button({
		Name = "ClearRoute",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(150, 36),
		Text = "✖  Quitar ruta",
		TextSize = 14,
		BackgroundColor3 = rgb(140, 40, 50),
		ZIndex = 30,
		Parent = holder,
	})
	clearRoute.Activated:Connect(function()
		Gps.clear()
	end)
	Theme.label({
		Position = UDim2.new(0, 0, 1, -FOOTER + 6),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Arrastra para mover · rueda o + / - para acercar · pulsa un lugar o mantén pulsado para ir allí (GPS) · " .. Strings.get("MAP.HINT"),
		TextSize = 12,
		TextColor3 = C.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 21,
		Parent = big,
	})

	-- Tamaño según la pantalla
	local camera = workspace.CurrentCamera
	local function resize()
		local v = camera.ViewportSize
		local s = math.clamp(math.min(v.X / 1500, v.Y / 900), 0.65, 1.15)
		bigScale.Scale = s
		local w, h = v.X * 0.96 / s, v.Y * 0.92 / s
		big.Size = UDim2.fromOffset(w, h)
		holderSize = Vector2.new(w - PANEL_PAD * 2 - LEFT_W - RIGHT_W - GAP * 2, h - PANEL_PAD * 2 - HEADER - FOOTER)
		if bigLayer then
			applyView()
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	resize()

	-- Arrastrar y rueda del ratón (solo dentro del mapa)
	local dragging: InputObject? = nil
	local pressedAt = 0
	local dragStart = Vector2.zero
	local panStart = Vector2.zero
	local function insideHolder(screen: Vector2): boolean
		local p, s = holder.AbsolutePosition, holder.AbsoluteSize
		return screen.X >= p.X and screen.X <= p.X + s.X and screen.Y >= p.Y and screen.Y <= p.Y + s.Y
	end
	local function pointer(input: InputObject): Vector2
		if input.UserInputType == Enum.UserInputType.Touch then
			return Vector2.new(input.Position.X, input.Position.Y) + game:GetService("GuiService"):GetGuiInset()
		end
		return UserInputService:GetMouseLocation()
	end
	UserInputService.InputBegan:Connect(function(input)
		if not bigOpen then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local at = pointer(input)
			if insideHolder(at) then
				dragging = input
				dragStart = at
				panStart = pan
				dragMoved = false
				pressedAt = os.clock()
			end
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not bigOpen then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local at = UserInputService:GetMouseLocation()
			if insideHolder(at) then
				local focus = (at - holder.AbsolutePosition) / bigScale.Scale
				setZoom(zoom * (if input.Position.Z > 0 then 1.2 else 1 / 1.2), focus)
			end
		elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragging) then
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
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
			-- Mantener pulsado (sin arrastrar) en cualquier sitio: "Ir aquí"
			local layer = bigLayer
			if not dragMoved and os.clock() - pressedAt > 0.5 and layer then
				local localPoint = (dragStart - holder.AbsolutePosition) / bigScale.Scale
				local layerPoint = (localPoint - pan) / zoom
				local world = Vector3.new(layer.Min.X + layerPoint.X * layer.Scale, 0, layer.Min.Y + layerPoint.Y * layer.Scale)
				waypoint = nil
				setWaypoint({ Position = world, Name = "Punto marcado" })
			end
			dragging = nil
			task.defer(function()
				dragMoved = false
			end)
		end
	end)
end

function MapUI.init()
	loadData()
	buildMini()
	buildBig()
	-- GPS: la línea de la ruta en los dos mapas, y el sitio marcado se quita al llegar
	Gps.onChanged(function(path)
		routePath = path
		drawRoute(miniLayer)
		drawRoute(bigLayer)
	end)
	Gps.onManual(function(place)
		if not place and waypoint then
			waypoint = nil
			refreshWaypointList()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			MapUI.toggleBig()
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		local character = player.Character
		local root = mapRoot(player, character and character:FindFirstChild("HumanoidRootPart") :: BasePart?)
		-- El minimapa se mueve para que tú estés siempre en el centro
		local inner = MINI_SIZE - 8
		local zoom = MINI_ZOOMS[miniZoom]
		if root then
			local p = toPixel(miniLayer, root.Position.X, root.Position.Z)
			miniLayer.Frame.Position = UDim2.fromOffset(inner / 2 - p.X * zoom, inner / 2 - p.Y * zoom)
			local current = waypoint
			if current then
				local distance = Vector3.new(current.Position.X - root.Position.X, 0, current.Position.Z - root.Position.Z).Magnitude
				zoneLabel.Text = ("📍 %s · %d m"):format(current.Name, math.floor(distance / 3.5))
			end
			if not waypoint then
				local district = MapInfo.districtAt(root.Position.X, root.Position.Z)
				local zone = zoneAt(root.Position)
				zoneLabel.Text = if district and zone then zone .. " · " .. district.Name elseif district then district.Name else (zone or "Valmar")
			end
		end
		updateLayer(miniLayer, root, (inner / 2 - 12) / zoom)
		if bigOpen and bigLayer then
			updateLayer(bigLayer, root, nil)
		end
	end)
end

return MapUI
