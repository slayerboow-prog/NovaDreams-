-- WorldMapUI: el MAPA DEFINITIVO del planeta (17-11-2026, el dueño: «aquí tienes el mapa definitivo del planeta
-- principal, hay que imitarlo exactamente igual»; su imagen: docs/mapa/mapa-definitivo.png).
--
--   ┌ (📍) Mapa ─────────────────────────────────────────────────────────── ✕ ┐
--   │ ┌ el dibujo del dueño (textures/mapa/definitivo.png) ────────┐ ┌ Leyenda ┐ │
--   │ │  Valmar en el centro, amurallada; las ocho regiones        │ │ 🏠 Tu…  │ │
--   │ │  alrededor con su nivel y su candado (🔒 si aún no te toca, │ │ 🏰 …    │ │
--   │ │  ✓ si ya puedes); tu posición en vivo, campamentos y jefes │ │ …       │ │
--   │ └────────────────────────────────────────────────────────────┘ └─────────┘ │
--   │ [🏰 Valmar  X: 1023  Y: 876]   (i) Explora el mundo, derrota…   [− 100% +] │
--   └────────────────────────────────────────────────────────────────────────────┘
--
-- En Valmar sustituye al mapa grande de antes (Controllers/MapUI.toggleBig llama aquí cuando la imagen está
-- subida: shared/MapTextureIds.definitivo). Rueda / botones − + para acercar y arrastrar para moverse.
-- La proyección (WorldMapUI.toArt) pone el mundo sobre el dibujo: Valmar en el centro de la ciudad dibujada y
-- cada región en su sitio (shared/Cosmos/ValmarRegions sigue el mismo orden que el dibujo).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MapTextureIds = require(ReplicatedStorage.Shared.MapTextureIds)
local Images = require(ReplicatedStorage.Shared.Images)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local VR = require(ReplicatedStorage.Shared.Cosmos.ValmarRegions)
local OuterLands = require(ReplicatedStorage.Shared.Cosmos.OuterLands)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)

local create = Theme.create
local rgb = Color3.fromRGB

local WorldMapUI = {}

-- El dibujo (en píxeles de textures/mapa/definitivo.png)
WorldMapUI.ArtW, WorldMapUI.ArtH = 1024, 482
-- Dónde cae el centro de Valmar en el dibujo y cuántos píxeles es un stud (el dibujo está algo «tumbado»)
WorldMapUI.Center = { X = 573, Y = 228 }
WorldMapUI.Scale = { X = 0.066, Z = 0.040 }
-- Dónde está el candado dibujado de cada región (se tapa con el de verdad: 🔒 o ✓ según tu nivel)
WorldMapUI.Locks = {
	TierrasOscuras = { 293, 111 },
	MontanasHeladas = { 576, 84 },
	TierrasVolcanicas = { 871, 111 },
	PantanoMaldito = { 212, 246 },
	DesiertoDorado = { 904, 262 },
	BosqueEtereo = { 250, 409 },
	LlanurasSalvajes = { 566, 446 },
	RuinasAntiguas = { 857, 415 },
}
WorldMapUI.Legend = {
	{ "🏠", "Tu ubicación", rgb(80, 170, 255) },
	{ "🏰", "Ciudad / Asentamiento", rgb(220, 220, 235) },
	{ "🌀", "Portal", rgb(170, 110, 255) },
	{ "🏛", "Mazmorra", rgb(220, 220, 235) },
	{ "💀", "Jefe Mundial", rgb(255, 80, 80) },
	{ "🚩", "Evento", rgb(255, 170, 60) },
	{ "❗", "Misión", rgb(255, 210, 60) },
	{ "⚔", "Zona de Farmeo", rgb(230, 230, 230) },
	{ "💎", "Zona Especial", rgb(200, 110, 255) },
	{ "🧰", "Tesoro", rgb(255, 190, 80) },
	{ "🔥", "Campamento", rgb(255, 150, 60) },
	{ "- - -", "Camino Principal", rgb(240, 220, 160) },
	{ "——", "Camino Secundario", rgb(255, 210, 90) },
}
WorldMapUI.Hint = "Explora el mundo, derrota monstruos y mejora tu personaje."
-- Dónde está el cartel dibujado de cada región (al tocarlo se abre su vista: Controllers/RegionMapUI)
WorldMapUI.Labels = {
	TierrasOscuras = { 285, 85 },
	MontanasHeladas = { 575, 58 },
	TierrasVolcanicas = { 875, 85 },
	PantanoMaldito = { 205, 222 },
	DesiertoDorado = { 895, 238 },
	BosqueEtereo = { 232, 380 },
	LlanurasSalvajes = { 565, 418 },
	RuinasAntiguas = { 850, 390 },
}
WorldMapUI.MinZoom, WorldMapUI.MaxZoom = 1, 3

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local window: Frame? = nil
local viewport: Frame? = nil
local art: Frame? = nil
local me: Frame? = nil
local coords: TextLabel? = nil
local place: TextLabel? = nil
local zoomText: TextLabel? = nil
local locks: { [string]: TextLabel } = {}
local regionView: any = nil
local mapParts: { GuiObject } = {}
local open = false
local zoom = 1
local pan = Vector2.zero

-- ¿Está subido el dibujo?
function WorldMapUI.available(): boolean
	local id = MapTextureIds.definitivo
	return type(id) == "string" and string.match(id, "^rbxassetid://%d+$") ~= nil
end

-- Del mundo (x, z) al dibujo (píxeles)
function WorldMapUI.toArt(x: number, z: number): (number, number)
	local C, S = WorldMapUI.Center, WorldMapUI.Scale
	local px = math.clamp(C.X + x * S.X, 4, WorldMapUI.ArtW - 4)
	local py = math.clamp(C.Y + z * S.Z, 4, WorldMapUI.ArtH - 4)
	return px, py
end

-- El nombre del sitio donde estás («Valmar», «Caza del Oeste», «Bosque Etéreo»…)
function WorldMapUI.placeName(x: number, z: number): string
	if CityPlan.isCentral(x, z) then
		return "Valmar"
	end
	local farm = CityPlan.farmAt(x, z)
	if farm then
		return farm.Name
	end
	local reg = VR.at(x, z, true)
	return if reg then reg.Name else "Valmar"
end

local function rootPos(): Vector3?
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	return r and r.Position
end

local function marker(parent: Instance, px: number, pz: number, icon: string, color: Color3, size: number, name: string): Frame
	local f = create("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(px / WorldMapUI.ArtW, pz / WorldMapUI.ArtH),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = rgb(16, 22, 40),
		BackgroundTransparency = 0.15,
		ZIndex = 6,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = color, Thickness = 2 }),
		create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = icon, TextScaled = true, Font = Theme.FontBold, TextColor3 = color, ZIndex = 7 }),
	})
	return f
end

local function applyZoom()
	if not art or not viewport then
		return
	end
	local vs = viewport.AbsoluteSize
	-- (no se sale del borde: el dibujo siempre tapa todo el hueco)
	local maxX = vs.X * (zoom - 1) / 2
	local maxY = vs.Y * (zoom - 1) / 2
	pan = Vector2.new(math.clamp(pan.X, -maxX, maxX), math.clamp(pan.Y, -maxY, maxY))
	art.Size = UDim2.fromScale(zoom, zoom)
	art.Position = UDim2.new(0.5, pan.X, 0.5, pan.Y)
	if zoomText then
		zoomText.Text = ("%d%%"):format(math.floor(zoom * 100 + 0.5))
	end
end

local function setZoom(z: number)
	zoom = math.clamp(z, WorldMapUI.MinZoom, WorldMapUI.MaxZoom)
	applyZoom()
end

local function refreshLocks()
	local level = tonumber(player:GetAttribute("Level")) or 1
	for id, label in locks do
		local reg = VR.ById[id]
		local okLevel = reg and level >= reg.MinLevel
		label.Text = if okLevel then "✓" else "🔒"
		label.TextColor3 = if okLevel then rgb(120, 255, 140) else rgb(230, 230, 236)
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if okLevel then rgb(80, 220, 110) else rgb(150, 150, 160)
		end
	end
end

local function build()
	local pg = player:WaitForChild("PlayerGui")
	gui = create("ScreenGui", { Name = "WorldMap", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = pg })
	-- la ventana (con el borde azul claro y el degradado azul noche del dibujo)
	-- (la ventana se diseña a 1480 × 780, como el dibujo del dueño, y se escala entera para caber en la pantalla)
	window = create("Frame", {
		Name = "Ventana",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1480, 780),
		BackgroundColor3 = rgb(14, 26, 52),
		BackgroundTransparency = 0.04,
		Parent = gui,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 18) }),
		create("UIStroke", { Color = rgb(120, 170, 240), Thickness = 2, Transparency = 0.25 }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(30, 46, 84), rgb(10, 18, 38)) }),
	})
	local w = window :: Frame
	local fit = create("UIScale", { Name = "Encaje", Parent = w })
	local function refit()
		local cam = workspace.CurrentCamera
		local v = if cam then cam.ViewportSize else Vector2.new(1480, 800)
		fit.Scale = math.min((v.X - 16) / 1480, (v.Y - 16) / 780, 1.25)
	end
	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	-- cabecera: el pin en un círculo, «Mapa» y la ✕
	local head = create("Frame", { Name = "Cabecera", Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Parent = w })
	create("Frame", { Name = "Pin", Position = UDim2.fromOffset(14, 4), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = rgb(22, 34, 64), Parent = head }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(150, 190, 250), Thickness = 2 }),
		create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "📍", TextScaled = true, Font = Theme.FontBold, TextColor3 = rgb(255, 255, 255) }),
	})
	create("TextLabel", { Name = "Titulo", Position = UDim2.fromOffset(78, 6), Size = UDim2.new(0, 300, 0, 46), BackgroundTransparency = 1, Text = "Mapa", Font = Theme.FontBold, TextSize = 34, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = head })
	local close = create("TextButton", { Name = "Cerrar", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, Text = "X", Font = Theme.FontBold, TextSize = 38, TextColor3 = rgb(255, 255, 255), Parent = head })
	close.Activated:Connect(function()
		WorldMapUI.close()
	end)
	-- leyenda a la derecha
	local legendW = 200
	local legend = create("Frame", {
		Name = "Leyenda",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 66),
		Size = UDim2.new(0, legendW, 1, -66 - 66),
		BackgroundColor3 = rgb(12, 20, 40),
		BackgroundTransparency = 0.1,
		Parent = w,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIStroke", { Color = rgb(70, 100, 150), Thickness = 1 }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	create("TextLabel", { Name = "Titulo", Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "Leyenda", Font = Theme.FontBold, TextSize = 19, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = legend })
	for i, row in WorldMapUI.Legend do
		local r = create("Frame", { Name = "Fila", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = i, Parent = legend })
		create("TextLabel", { Name = "Icono", Size = UDim2.new(0, 30, 1, 0), BackgroundTransparency = 1, Text = row[1], TextScaled = true, Font = Theme.FontBold, TextColor3 = row[3], Parent = r })
		create("TextLabel", { Name = "Texto", Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -38, 1, 0), BackgroundTransparency = 1, Text = row[2], TextSize = 15, Font = Theme.Font, TextColor3 = rgb(230, 236, 248), TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
	end
	-- el dibujo (recortado al hueco: se acerca y se arrastra por dentro)
	viewport = create("Frame", {
		Name = "Dibujo",
		Position = UDim2.fromOffset(12, 66),
		Size = UDim2.new(1, -legendW - 36, 1, -66 - 66),
		BackgroundColor3 = rgb(8, 30, 60),
		ClipsDescendants = true,
		Active = true,
		Parent = w,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
	})
	local vp = viewport :: Frame
	local holder = create("Frame", { Name = "Encaje", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = vp }, {
		create("UIAspectRatioConstraint", { AspectRatio = WorldMapUI.ArtW / WorldMapUI.ArtH, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width }),
	})
	art = create("Frame", { Name = "Arte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = holder })
	local a = art :: Frame
	create("ImageLabel", { Name = "Imagen", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = Images.of(MapTextureIds.definitivo or ""), ScaleType = Enum.ScaleType.Stretch, ZIndex = 2, Parent = a })
	-- los candados de verdad sobre los dibujados
	for id, at in WorldMapUI.Locks do
		local l = create("TextLabel", {
			Name = "Candado_" .. id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(at[1] / WorldMapUI.ArtW, at[2] / WorldMapUI.ArtH),
			Size = UDim2.fromScale(28 / WorldMapUI.ArtW, 28 / WorldMapUI.ArtH),
			BackgroundColor3 = rgb(26, 30, 40),
			Text = "🔒",
			TextScaled = true,
			Font = Theme.FontBold,
			ZIndex = 5,
			Parent = a,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0.3, 0) }),
			create("UIStroke", { Color = rgb(150, 150, 160), Thickness = 1.5 }),
			create("UIAspectRatioConstraint", { AspectRatio = 1 }),
		})
		locks[id] = l
	end
	-- los campamentos y los jefes de cada región
	for _, b in OuterLands.Bridges do
		local px, pz = WorldMapUI.toArt(b.CampX, b.CampZ)
		marker(a, px, pz, "🔥", rgb(255, 150, 60), 22, "Campamento_" .. b.Id)
	end
	for _, reg in VR.List do
		local x, z = VR.point(reg, 6600)
		local px, pz = WorldMapUI.toArt(x, z)
		marker(a, px, pz, "💀", rgb(255, 80, 80), 22, "Jefe_" .. reg.Id)
	end
	-- cada región se toca (sobre su cartel dibujado) y se abre su vista
	for id, at in WorldMapUI.Labels do
		local b = create("TextButton", {
			Name = "Region_" .. id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(at[1] / WorldMapUI.ArtW, at[2] / WorldMapUI.ArtH),
			Size = UDim2.fromScale(170 / WorldMapUI.ArtW, 80 / WorldMapUI.ArtH),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 8,
			Parent = a,
		})
		b.Activated:Connect(function()
			WorldMapUI.openRegion(id)
		end)
	end
	-- tú (azul, con la casita de «Tu ubicación» y un halo)
	me = marker(a, WorldMapUI.Center.X, WorldMapUI.Center.Y, "🏠", rgb(80, 170, 255), 30, "Tu")
	;(me :: Frame).ZIndex = 9
	-- barra de abajo: dónde estás, la pista y el zoom
	local bottom = create("Frame", { Name = "Abajo", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = w })
	local where = create("Frame", { Name = "Donde", Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(250, 52), BackgroundColor3 = rgb(12, 20, 40), BackgroundTransparency = 0.1, Parent = bottom }, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIStroke", { Color = rgb(70, 100, 150), Thickness = 1 }),
		create("TextLabel", { Name = "Icono", Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, Text = "🏰", TextScaled = true, Font = Theme.FontBold, TextColor3 = rgb(230, 230, 240) }),
	})
	place = create("TextLabel", { Name = "Sitio", Position = UDim2.fromOffset(56, 3), Size = UDim2.new(1, -60, 0, 26), BackgroundTransparency = 1, Text = "Valmar", Font = Theme.FontBold, TextSize = 22, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = where })
	coords = create("TextLabel", { Name = "Coordenadas", Position = UDim2.fromOffset(56, 28), Size = UDim2.new(1, -60, 0, 20), BackgroundTransparency = 1, Text = "X: 0   Y: 0", Font = Theme.Font, TextSize = 16, TextColor3 = rgb(200, 210, 230), TextXAlignment = Enum.TextXAlignment.Left, Parent = where })
	create("Frame", { Name = "Pista", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.47, 0.5), Size = UDim2.fromOffset(520, 38), BackgroundColor3 = rgb(12, 20, 40), BackgroundTransparency = 0.15, Parent = bottom }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(70, 100, 150), Thickness = 1 }),
		create("TextLabel", { Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = rgb(255, 196, 40), Text = "i", TextScaled = true, Font = Theme.FontBold, TextColor3 = rgb(40, 30, 10) }, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}),
		create("TextLabel", { Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, Text = WorldMapUI.Hint, TextScaled = true, Font = Theme.Font, TextColor3 = rgb(235, 240, 250), TextXAlignment = Enum.TextXAlignment.Left }, {
			create("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 9 }),
		}),
	})
	local zoomBox = create("Frame", { Name = "Zoom", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.fromOffset(220, 52), BackgroundColor3 = rgb(12, 20, 40), BackgroundTransparency = 0.1, Parent = bottom }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(90, 130, 200), Thickness = 1.5 }),
	})
	local minus = create("TextButton", { Name = "Menos", Size = UDim2.fromOffset(56, 52), BackgroundTransparency = 1, Text = "−", Font = Theme.FontBold, TextSize = 34, TextColor3 = rgb(255, 255, 255), Parent = zoomBox })
	zoomText = create("TextLabel", { Name = "Porcentaje", Position = UDim2.fromOffset(56, 0), Size = UDim2.fromOffset(108, 52), BackgroundTransparency = 1, Text = "100%", Font = Theme.FontBold, TextSize = 22, TextColor3 = rgb(255, 255, 255), Parent = zoomBox })
	local plus = create("TextButton", { Name = "Mas", Position = UDim2.fromOffset(164, 0), Size = UDim2.fromOffset(56, 52), BackgroundTransparency = 1, Text = "+", Font = Theme.FontBold, TextSize = 34, TextColor3 = rgb(255, 255, 255), Parent = zoomBox })
	minus.Activated:Connect(function()
		setZoom(zoom - 0.25)
	end)
	plus.Activated:Connect(function()
		setZoom(zoom + 0.25)
	end)
	-- la vista de cada región (ocupa la ventana; lo del mapa grande se esconde mientras)
	mapParts = { head, legend, vp, bottom }
	local okR, RegionMapUI = pcall(function()
		return require(script.Parent.RegionMapUI) :: any
	end)
	if okR then
		regionView = RegionMapUI.build(w, WorldMapUI.toArt, function()
			WorldMapUI.closeRegion()
		end)
	end
	-- rueda para acercar y arrastrar para moverse
	local dragging: Vector2? = nil
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	vp.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			setZoom(zoom + (if input.Position.Z > 0 then 0.25 else -0.25))
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			pan += p - dragging
			dragging = p
			applyZoom()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = nil
		end
	end)
	player:GetAttributeChangedSignal("Level"):Connect(refreshLocks)
	refreshLocks()
	-- tú, en vivo
	RunService.RenderStepped:Connect(function()
		if not open or not me then
			return
		end
		local p = rootPos()
		if not p then
			return
		end
		local px, pz = WorldMapUI.toArt(p.X, p.Z)
		me.Position = UDim2.fromScale(px / WorldMapUI.ArtW, pz / WorldMapUI.ArtH)
		if coords then
			coords.Text = ("X: %d   Y: %d"):format(math.floor(p.X + 0.5), math.floor(p.Z + 0.5))
		end
		if place then
			place.Text = WorldMapUI.placeName(p.X, p.Z)
		end
	end)
end

function WorldMapUI.openRegion(id: string)
	if not regionView then
		return
	end
	for _, p in mapParts do
		p.Visible = false
	end
	regionView.Open(id)
end

function WorldMapUI.closeRegion()
	if regionView then
		regionView.Close()
	end
	for _, p in mapParts do
		p.Visible = true
	end
end

function WorldMapUI.isOpen(): boolean
	return open
end

function WorldMapUI.open()
	if open then
		return
	end
	if not gui then
		build()
	end
	Dialog.closeOthers("WorldMap")
	open = true
	WorldMapUI.closeRegion()
	zoom, pan = 1, Vector2.zero
	applyZoom()
	refreshLocks()
	;(gui :: ScreenGui).Enabled = true
end

function WorldMapUI.close()
	if not open then
		return
	end
	open = false
	if gui then
		gui.Enabled = false
	end
end

function WorldMapUI.toggle()
	if open then
		WorldMapUI.close()
	else
		WorldMapUI.open()
	end
end

function WorldMapUI.init()
	Dialog.registerBig("WorldMap", WorldMapUI.close, WorldMapUI.isOpen)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and open and input.KeyCode == Enum.KeyCode.Escape then
			WorldMapUI.close()
		end
	end)
end

return WorldMapUI
