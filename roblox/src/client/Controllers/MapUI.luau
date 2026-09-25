-- MapUI (cliente): el mapa de Valmar, con el estilo del mapa ilustrado de la ciudad.
--   * Minimapa redondo arriba a la derecha (debajo de los botones): distritos de colores, calles, mar,
--     lugares, tu flecha, tu objetivo (★), el sitio que marques (📍) y los demás jugadores.
--     Si el objetivo está lejos, se queda en el borde señalando hacia dónde ir.
--   * Mapa grande (botón "Mapa", el botón ⤢ del minimapa o la tecla M): toda la región con los distritos,
--     la lista de distritos, los lugares importantes (pulsa uno para marcarlo) y la leyenda.
--     Se mueve arrastrando y se acerca con la rueda del ratón o con los botones + y −.
-- Lee las calles de ReplicatedStorage.Ambient.Roads, las zonas de ReplicatedStorage.MapZones y los lugares
-- de ReplicatedStorage.MapLandmarks (los publica el servidor), así que se adapta solo si el mapa cambia.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local MapUI = {}

local player = Players.LocalPlayer

local MINI_SIZE = 176
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

type Road = { Axis: string, At: number, From: number, To: number }
type Zone = { Name: string, Center: Vector3 }
type Landmark = { Kind: MapInfo.Kind, Position: Vector3, District: string }
type Layer = {
	Frame: Frame,
	Scale: number,
	Min: Vector2,
	Me: TextLabel,
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
			local axis, at, from, to = config:GetAttribute("Axis"), config:GetAttribute("At"), config:GetAttribute("From"), config:GetAttribute("To")
			if type(at) == "number" and type(from) == "number" and type(to) == "number" then
				table.insert(roads, { Axis = axis, At = at, From = math.min(from, to), To = math.max(from, to) })
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

-- Zona más cercana a una posición
local function zoneAt(position: Vector3): string?
	local best, bestDistance = nil, math.huge
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
	local coast = MapInfo.CoastX
	-- Tierra (todo lo que queda al oeste de la costa), con playa a lo largo del mar
	rect(layer, "Land", boundsMin.X - 50, boundsMin.Y - 50, coast, boundsMax.Y + 50, LAND, 1)
	rect(layer, "Shore", coast - 34, boundsMin.Y - 50, coast + 6, boundsMax.Y + 50, SAND, 1)
	rect(layer, "Beach", 1500, -380, coast + 6, 380, SAND, 1, 6)
	-- Isla del faro y colina del mirador
	local islandPlace, hillPlace
	for _, place in landmarks do
		if place.Kind.Model == "Faro" then
			islandPlace = place.Position
		elseif place.Kind.Model == "Mirador" then
			hillPlace = place.Position
		end
	end
	if islandPlace then
		circle(layer, "Island", islandPlace.X, islandPlace.Z, 66, SAND, 1)
		circle(layer, "IslandGrass", islandPlace.X, islandPlace.Z, 46, LAND, 1)
	end
	if hillPlace then
		circle(layer, "Hill", hillPlace.X, hillPlace.Z + 20, 75, rgb(80, 132, 70), 1)
	end
	-- Distritos de colores
	for _, d in MapInfo.Districts do
		local area = rect(layer, d.Name, d.Min.X, d.Min.Y, d.Max.X, d.Max.Y, d.Color, 1, if detailed then 16 else 10)
		area.BackgroundTransparency = 0.55
		create("UIStroke", { Color = d.Color, Thickness = if detailed then 3 else 2, Transparency = 0.1, Parent = area })
	end
	-- Calles
	local width = math.max(2, ROAD_WIDTH / scale)
	for _, road in roads do
		local a = if road.Axis == "X" then toPixel(layer, road.From, road.At) else toPixel(layer, road.At, road.From)
		local b = if road.Axis == "X" then toPixel(layer, road.To, road.At) else toPixel(layer, road.At, road.To)
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
			Size = if road.Axis == "X" then UDim2.fromOffset(b.X - a.X + width, width) else UDim2.fromOffset(width, b.Y - a.Y + width),
			BackgroundColor3 = ROAD,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = frame,
		})
	end
	-- Nombre de cada distrito (solo en el mapa grande)
	if detailed then
		for _, d in MapInfo.Districts do
			local p = toPixel(layer, (d.Min.X + d.Max.X) / 2, d.Min.Y)
			local pill = create("Frame", {
				Name = "Label",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(p.X, p.Y + 6),
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
				Text = d.Town .. " · " .. d.Theme,
				TextSize = 11,
				TextStrokeTransparency = 0.7,
				ZIndex = 6,
				Parent = pill,
			})
			keepSize(layer, pill)
		end
		-- El mar tiene nombre
		local sea = toPixel(layer, (MapInfo.CoastX + boundsMax.X) / 2 + 60, 900)
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
	layer.Me = marker(layer, "▲", Color3.new(1, 1, 1), if detailed then 22 else 16, 9)
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

local function updateLayer(layer: Layer, root: BasePart?, clampTo: number?)
	-- Tu posición y hacia dónde miras
	if root then
		local p = toPixel(layer, root.Position.X, root.Position.Z)
		layer.Me.Position = UDim2.fromOffset(p.X, p.Y)
		local look = root.CFrame.LookVector
		layer.Me.Rotation = math.deg(math.atan2(look.X, -look.Z))
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
			local p = toPixel(layer, otherRoot.Position.X, otherRoot.Position.Z)
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
	refreshLegend()
	fitAll()
end

local function setBigOpen(open: boolean)
	bigOpen = open
	bigGui.Enabled = open
	if open then
		ensureBigLayer()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
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

-- Misma escala que el HUD, para que el minimapa quede justo debajo de sus botones
local function hudScale(): number
	local v = workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(v.Y / 900, v.X / 1700), 0.55, 1.2)
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
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = hudScale()
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	-- Minimapa redondo con aro azul, debajo de los botones de arriba a la derecha
	miniHolder = create("Frame", {
		Name = "Minimap",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 92),
		Size = UDim2.fromOffset(MINI_SIZE, MINI_SIZE),
		BackgroundColor3 = rgb(12, 22, 42),
		Parent = gui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = C.Accent, Thickness = 4, Transparency = 0.05 }),
	})
	local mini = create("CanvasGroup", {
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = LAND,
		BorderSizePixel = 0,
		Parent = miniHolder,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	miniLayer = buildLayer(mini, MINI_SCALE, false)
	-- Norte arriba
	local north = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = rgb(12, 22, 42),
		ZIndex = 10,
		Parent = miniHolder,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Color = C.Accent, Thickness = 2 }) })
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = "N", Font = Theme.FontBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 10, Parent = north })

	zoneLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 6),
		Size = UDim2.new(1, 20, 0, 18),
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.FontBold,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = miniHolder,
	})
	-- Botón para desplegar el mapa completo
	local expand = create("TextButton", {
		Name = "Expand",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.12, 0, 0.88, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = rgb(20, 40, 80),
		Text = "⤢",
		TextSize = 22,
		Font = Theme.FontBold,
		TextColor3 = C.Text,
		ZIndex = 10,
		Parent = miniHolder,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Color = C.Accent, Thickness = 2 }) })
	expand.Activated:Connect(MapUI.toggleBig)
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
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(20, 34, 62), rgb(8, 14, 28)) }),
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
		Text = "✕  " .. Strings.get("MAP.CLOSE") .. " (M)",
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
		local row = listRow(left, i, d.Icon, d.Color, d.Name, d.Town .. " · " .. d.Theme)
		row.Activated:Connect(function()
			centerOn(Vector3.new((d.Min.X + d.Max.X) / 2, 0, (d.Min.Y + d.Max.Y) / 2), 2.2)
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
	roundButton(holder, "−", 58, function()
		setZoom(zoom / 1.4, holderSize / 2)
	end)
	roundButton(holder, "⌖", 12, function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			centerOn(root.Position, math.max(zoom, 2))
		else
			fitAll()
		end
	end)
	roundButton(holder, "⤡", 150, fitAll)
	Theme.label({
		Position = UDim2.new(0, 0, 1, -FOOTER + 6),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Arrastra para mover · rueda o + / − para acercar · pulsa un lugar para marcarlo · " .. Strings.get("MAP.HINT"),
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

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			MapUI.toggleBig()
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.05 then
			return
		end
		elapsed = 0
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		-- El minimapa se mueve para que tú estés siempre en el centro
		local inner = MINI_SIZE - 6
		if root then
			local p = toPixel(miniLayer, root.Position.X, root.Position.Z)
			miniLayer.Frame.Position = UDim2.fromOffset(inner / 2 - p.X, inner / 2 - p.Y)
			local current = waypoint
			if current then
				local distance = Vector3.new(current.Position.X - root.Position.X, 0, current.Position.Z - root.Position.Z).Magnitude
				if distance < 30 then
					waypoint = nil -- ya has llegado
					refreshWaypointList()
				else
					zoneLabel.Text = ("📍 %s · %d m"):format(current.Name, math.floor(distance / 3.5))
				end
			end
			if not waypoint then
				local district = MapInfo.districtAt(root.Position.X, root.Position.Z)
				zoneLabel.Text = if district then district.Name .. " · " .. district.Town else (zoneAt(root.Position) or "Valmar")
			end
		end
		updateLayer(miniLayer, root, inner / 2 - 12)
		if bigOpen and bigLayer then
			updateLayer(bigLayer, root, nil)
		end
	end)
end

return MapUI
