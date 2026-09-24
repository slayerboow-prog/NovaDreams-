-- MapUI (cliente): mapa al estilo de los juegos MMO.
--   * Minimapa arriba a la derecha: calles, tu flecha, tu objetivo (★) y los demás jugadores.
--     Si el objetivo está lejos, la estrella se queda en el borde señalando hacia dónde ir.
--   * Mapa grande de toda la región con la tecla M (o el botón 🗺️): zonas, calles y objetivo.
-- Lee las calles de ReplicatedStorage.Ambient.Roads y las zonas de ReplicatedStorage.MapZones
-- (las publica el servidor), así que se adapta solo si el mapa cambia.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)

local create = Theme.create
local C = Theme.Colors

local MapUI = {}

local player = Players.LocalPlayer

local MINI_SIZE = 150
local MINI_SCALE = 2.6 -- studs por píxel en el minimapa
local ROAD_WIDTH = 22 -- ancho aproximado de una calle (studs)
local GROUND = Color3.fromRGB(58, 92, 60)
local ROAD = Color3.fromRGB(205, 205, 200)
local TARGET = C.Gold
local OTHERS = Color3.fromRGB(90, 180, 255)

type Road = { Axis: string, At: number, From: number, To: number }
type Zone = { Name: string, Center: Vector3 }
type Layer = {
	Frame: Frame,
	Scale: number,
	Min: Vector2,
	Me: TextLabel,
	Target: TextLabel,
	Dots: { [Player]: Frame },
}

local roads: { Road } = {}
local zones: { Zone } = {}
local boundsMin = Vector2.new(-1700, -1550)
local boundsMax = Vector2.new(1700, 1550)

local gui: ScreenGui
local mini: CanvasGroup
local miniHolder: Frame
local miniLayer: Layer
local zoneLabel: TextLabel
local big: Frame
local bigLayer: Layer?
local bigOpen = false

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
	-- Límites del mapa: lo que ocupan las calles y las zonas, con margen
	if #roads > 0 or #zones > 0 then
		local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
		local function grow(x: number, z: number)
			minX, minZ = math.min(minX, x), math.min(minZ, z)
			maxX, maxZ = math.max(maxX, x), math.max(maxZ, z)
		end
		for _, road in roads do
			if road.Axis == "X" then
				grow(road.From, road.At)
				grow(road.To, road.At)
			else
				grow(road.At, road.From)
				grow(road.At, road.To)
			end
		end
		for _, zone in zones do
			grow(zone.Center.X, zone.Center.Z)
		end
		boundsMin = Vector2.new(minX - 150, minZ - 150)
		boundsMax = Vector2.new(maxX + 150, maxZ + 150)
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
-- Capa del mapa (calles y zonas dibujadas a una escala)
---------------------------------------------------------------------

-- El norte (−Z) queda arriba: X del mundo -> x de pantalla, Z del mundo -> y de pantalla
local function toPixel(layer: Layer, x: number, z: number): Vector2
	return Vector2.new((x - layer.Min.X) / layer.Scale, (z - layer.Min.Y) / layer.Scale)
end

local function marker(text: string, color: Color3, size: number, parent: Instance, z: number): TextLabel
	return Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		Text = text,
		TextSize = size,
		Font = Theme.FontBold,
		TextColor3 = color,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = z,
		Parent = parent,
	})
end

local function buildLayer(parent: Instance, scale: number, withZoneNames: boolean): Layer
	local extent = (boundsMax - boundsMin) / scale
	local frame = create("Frame", {
		Name = "World",
		Size = UDim2.fromOffset(extent.X, extent.Y),
		BackgroundColor3 = GROUND,
		BorderSizePixel = 0,
		Parent = parent,
	})
	local layer: Layer = { Frame = frame, Scale = scale, Min = boundsMin, Me = nil :: any, Target = nil :: any, Dots = {} }
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
	if withZoneNames then
		for _, zone in zones do
			local p = toPixel(layer, zone.Center.X, zone.Center.Z)
			Theme.label({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(p.X, p.Y),
				Size = UDim2.fromOffset(160, 20),
				Text = zone.Name,
				TextSize = 15,
				Font = Theme.FontBold,
				TextStrokeTransparency = 0.2,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 3,
				Parent = frame,
			})
		end
	end
	layer.Target = marker("★", TARGET, 20, frame, 5)
	layer.Me = marker("▲", Color3.new(1, 1, 1), 16, frame, 6)
	return layer
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
	if typeof(target) == "Vector3" then
		local p = toPixel(layer, target.X, target.Z)
		if clampTo and root then
			-- En el minimapa: si está fuera, se queda en el borde
			local me = toPixel(layer, root.Position.X, root.Position.Z)
			local offset = p - me
			if offset.Magnitude > clampTo then
				p = me + offset.Unit * clampTo
			end
		end
		layer.Target.Position = UDim2.fromOffset(p.X, p.Y)
		layer.Target.Visible = true
	else
		layer.Target.Visible = false
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
					Size = UDim2.fromOffset(7, 7),
					BackgroundColor3 = OTHERS,
					BorderSizePixel = 0,
					ZIndex = 4,
					Parent = layer.Frame,
				}, { Theme.corner(4) })
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
-- Minimapa y mapa grande
---------------------------------------------------------------------

local function setBigOpen(open: boolean)
	bigOpen = open
	big.Visible = open
	if open and not bigLayer then
		local holder = big:FindFirstChild("Holder") :: Frame
		local area = holder.AbsoluteSize
		local extent = boundsMax - boundsMin
		local scale = math.max(extent.X / math.max(area.X, 100), extent.Y / math.max(area.Y, 100))
		bigLayer = buildLayer(holder, scale, true)
		local layer = bigLayer :: Layer
		layer.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
		layer.Frame.Position = UDim2.fromScale(0.5, 0.5)
	end
end

local function build()
	gui = create("ScreenGui", {
		Name = "MapUI",
		ResetOnSpawn = false,
		DisplayOrder = 2,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 850, 0.65, 1.25)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	-- Minimapa (arriba a la derecha; baja un poco si está abierto el panel del trabajo)
	miniHolder = create("Frame", {
		Name = "Minimap",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 12),
		Size = UDim2.fromOffset(MINI_SIZE, MINI_SIZE),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	mini = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = GROUND,
		BorderSizePixel = 0,
		Parent = miniHolder,
	}, { Theme.corner(MINI_SIZE // 2) })
	create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.4, Thickness = 2, Parent = miniHolder })
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = miniHolder })
	miniLayer = buildLayer(mini, MINI_SCALE, false)
	zoneLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.new(1, 20, 0, 16),
		TextSize = 12,
		Font = Theme.FontBold,
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = miniHolder,
	})
	local open = Theme.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromOffset(34, 34),
		Text = "🗺️",
		TextSize = 18,
		ZIndex = 5,
		Parent = miniHolder,
	})
	open.Activated:Connect(function()
		setBigOpen(not bigOpen)
	end)

	local function place()
		miniHolder.Position = UDim2.new(1, -16, 0, if player:GetAttribute("Job") then 124 else 12)
	end
	player:GetAttributeChangedSignal("Job"):Connect(place)
	place()

	-- Mapa grande (centrado)
	big = Theme.panel({
		Name = "BigMap",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0.82, 0),
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(900, 820), Parent = big })
	Theme.padding(12).Parent = big
	Theme.label({
		Size = UDim2.new(1, -100, 0, 24),
		Text = "🗺️ " .. Strings.get("MAP.TITLE"),
		Font = Theme.FontBold,
		TextSize = 20,
		Parent = big,
	})
	Theme.label({
		Position = UDim2.new(0, 0, 1, -16),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "▲ " .. Strings.get("MAP.YOU") .. "    ★ " .. Strings.get("MAP.TARGET") .. "    ●  Jugadores    ·    " .. Strings.get("MAP.HINT"),
		TextSize = 12,
		TextColor3 = C.Muted,
		Parent = big,
	})
	local close = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(90, 26),
		Text = Strings.get("MAP.CLOSE"),
		TextSize = 14,
		Parent = big,
	})
	close.Activated:Connect(function()
		setBigOpen(false)
	end)
	create("Frame", {
		Name = "Holder",
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = big,
	}, { Theme.corner(8) })
end

function MapUI.init()
	loadData()
	build()

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			setBigOpen(not bigOpen)
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
		if root then
			local p = toPixel(miniLayer, root.Position.X, root.Position.Z)
			miniLayer.Frame.Position = UDim2.fromOffset(MINI_SIZE / 2 - p.X, MINI_SIZE / 2 - p.Y)
			zoneLabel.Text = zoneAt(root.Position) or ""
		end
		updateLayer(miniLayer, root, MINI_SIZE / 2 - 12)
		if bigOpen and bigLayer then
			updateLayer(bigLayer, root, nil)
		end
	end)
end

return MapUI
