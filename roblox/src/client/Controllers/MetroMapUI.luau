-- MetroMapUI (cliente): el plano del metro.
--   * Plano de la red con la geografía real a escala: cada línea con su color, las estaciones (las de
--     transbordo más grandes y con aro), la estación más cercana ("ESTÁS AQUÍ" si estás dentro), dónde
--     estás tú y los trenes moviéndose en vivo (ReplicatedStorage.MetroState, cada 0,2 s).
--   * Pestañas a la derecha:
--       📍 Cercana -> la estación más cercana, a cuánto andando, próximos trenes y "Cómo llegar" (GPS)
--       🧭 Ruta    -> planificador: distrito → estación → ruta recomendada (líneas, transbordos,
--                     tiempo aproximado y próximo tren). Tocar una estación del plano la elige.
--       ⚠️ Avisos  -> horario actual, las líneas y las incidencias activas
--   * Se abre desde el móvil (🚇 Metro), desde los carteles del plano de las estaciones (Remote "OpenMap")
--     y con el botón 🗺️ Plano del panel del tren (MetroUI).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local Gps = require(script.Parent.Gps)
local Metro = require(ReplicatedStorage.Shared.Metro)

local MetroMapUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

-- Medidas de la ventana (Dialog la encoge en pantallas bajas: en 800x400 queda en ~585x390)
local WINDOW = Vector2.new(900, 600)
local MAP_W, MAP_H = 530, 536
local SIDE_X, SIDE_W = 542, 326
local LIVE_EVERY = 0.2 -- los trenes del plano se mueven cada 0,2 s
local HERE_RANGE = 260 -- studs: bajo tierra y tan cerca de una estación, "ESTÁS AQUÍ"
local TAP = 44 -- tamaño mínimo de lo que se toca

---------------------------------------------------------------------
-- Datos: recorrido de cada línea y estado en vivo de los trenes
---------------------------------------------------------------------
local geometry: { [string]: { Points: { Vector3 }, Centers: { number } } } = {}

local function lineGeometry(line: Metro.Line): { Points: { Vector3 }, Centers: { number } }
	local g = geometry[line.Id]
	if not g then
		local points, centers = Metro.path(line)
		g = { Points = points, Centers = centers }
		geometry[line.Id] = g
	end
	return g
end

-- Distancias del recorrido de cada estación de la línea (centers[i])
function MetroMapUI.centers(lineId: string): { number }?
	local line = Metro.lineById[lineId]
	return if line then lineGeometry(line).Centers else nil
end

local function num(value: any, default: number?): number?
	return if type(value) == "number" then value else default
end

-- Estado publicado del tren de una línea (nil si el servidor aún no lo ha publicado)
function MetroMapUI.trainState(lineId: string): { [string]: any }?
	local root = ReplicatedStorage:FindFirstChild("MetroState")
	local folder = root and root:FindFirstChild(lineId)
	if not folder then
		return nil
	end
	local phase = folder:GetAttribute("Phase")
	if phase ~= "Dwell" and phase ~= "Move" then
		return nil
	end
	local speed = num(folder:GetAttribute("Speed"))
	local line = Metro.lineById[lineId]
	local n = if line then #line.Stations else 1
	local dir = num(folder:GetAttribute("Dir"), 1) :: number
	return {
		Phase = phase,
		S = num(folder:GetAttribute("S"), 0),
		From = num(folder:GetAttribute("From"), 0),
		To = num(folder:GetAttribute("To"), 0),
		Duration = num(folder:GetAttribute("Duration"), 0),
		T0 = num(folder:GetAttribute("T0"), 0),
		Speed = if speed and speed > 0 then speed else nil,
		Index = math.clamp(math.floor(num(folder:GetAttribute("Index"), 1) :: number), 1, math.max(1, n)),
		Dir = if dir < 0 then -1 else 1,
		DwellEnd = num(folder:GetAttribute("DwellEnd"), 0),
		DwellTime = num(folder:GetAttribute("DwellTime")),
		Layover = num(folder:GetAttribute("Layover"), 0),
	}
end

-- Dónde va el centro del tren ahora (distancia del recorrido)
function MetroMapUI.trainPosition(lineId: string): (number?, number?)
	local st = MetroMapUI.trainState(lineId)
	if not st then
		return nil, nil
	end
	return Metro.positionAt(st, workspace:GetServerTimeNow()), st.Dir
end

-- Cuánto falta para que el tren de la línea esté en la estación fromIdx yendo hacia toIdx (si se da).
-- Devuelve (segundos, índice de la cabecera hacia la que va, segundos para cerrar puertas si ya está).
function MetroMapUI.nextTrain(line: Metro.Line, fromIdx: number, toIdx: number?): (number?, number?, number?)
	local st = MetroMapUI.trainState(line.Id)
	if not st then
		return nil, nil, nil
	end
	local now = workspace:GetServerTimeNow()
	local centers = lineGeometry(line).Centers
	local n = #centers
	local train = {
		Centers = centers,
		Index = st.Index,
		Dir = st.Dir,
		Phase = st.Phase,
		Timer = st.DwellEnd - now,
		Duration = st.Duration,
		Elapsed = now - st.T0,
		DwellTime = st.DwellTime,
		Layover = st.Layover,
		Speed = st.Speed,
	}
	local t, toward = Metro.eta(train, fromIdx)
	local dwellLeft = if t <= 0 then math.max(0, st.DwellEnd - now) else nil
	if toIdx and toIdx ~= fromIdx then
		local want = if toIdx > fromIdx then n else 1
		if toward ~= want then
			-- Este pasa en el otro sentido: el bueno es el mismo tren a la vuelta de la cabecera
			local wrongDir = if toward == n then 1 else -1
			local function from(index: number, target: number): number
				local ghost = { Centers = centers, Index = index, Dir = wrongDir, Phase = "Move", Duration = 0, Elapsed = 0, DwellTime = st.DwellTime, Layover = st.Layover, Speed = st.Speed }
				return (Metro.eta(ghost, target))
			end
			t = t + from(fromIdx, toward) + from(toward, fromIdx)
			toward = want
			dwellLeft = nil
		end
	end
	return t, toward, dwellLeft
end

local function boardText(line: Metro.Line, fromIdx: number, toIdx: number?): string
	local t, toward, dwellLeft = MetroMapUI.nextTrain(line, fromIdx, toIdx)
	if not t or not toward then
		return line.Name .. " · sin datos del tren ahora mismo"
	end
	return Metro.boardText(line, t, toward, dwellLeft)
end

-- Incidencias activas (atributo "Incidents": una por renglón, "Kind|LineId|StationId|Icon|Text|Alt")
function MetroMapUI.incidents(): { { Kind: string, Line: string, Station: string, Icon: string, Text: string, Alt: string } }
	local root = ReplicatedStorage:FindFirstChild("MetroState")
	local raw = root and root:GetAttribute("Incidents")
	local list = {}
	if type(raw) ~= "string" then
		return list
	end
	for _, row in string.split(raw, "\n") do
		if row ~= "" then
			local f = string.split(row, "|")
			table.insert(list, { Kind = f[1] or "", Line = f[2] or "", Station = f[3] or "", Icon = f[4] or "⚠️", Text = f[5] or "", Alt = f[6] or "" })
		end
	end
	return list
end

local function scheduleName(): string
	local root = ReplicatedStorage:FindFirstChild("MetroState")
	local name = root and root:GetAttribute("ScheduleName")
	if type(name) == "string" and name ~= "" then
		return name
	end
	return Metro.scheduleAt(Lighting.ClockTime).Name
end

local function hex(c: Color3): string
	return ("#%02X%02X%02X"):format(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function lineTag(line: Metro.Line): string
	return ('<font color="%s"><b>%s</b></font>'):format(hex(line.Color), line.Name)
end

local function stationName(id: string): string
	local st = Metro.Stations[id]
	return if st then st.Name else id
end

-- Dónde estás (el personaje o, si no hay, la cámara)
local function myPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position
end

-- La estación más cercana: id, studs y si estás dentro (bajo tierra y cerca)
local function nearest(): (string?, number, boolean)
	local pos = myPosition()
	if not pos then
		return nil, 0, false
	end
	local id, studs = Metro.nearestStation(pos)
	return id, studs, pos.Y < Metro.Underground and studs < HERE_RANGE
end

---------------------------------------------------------------------
-- La ventana
---------------------------------------------------------------------
local window: Frame? = nil
local body: ScrollingFrame? = nil
local mapLayer: Frame? = nil
local tabButtons: { [string]: TextButton } = {}
local currentTab = "Cercana"
local plannerDistrict: string? = nil
local plannerDest: string? = nil
local liveLabels: { { Label: TextLabel, Text: () -> string } } = {}
local trainMarkers: { [string]: Frame } = {}
local hereRing: Frame? = nil
local hereLabel: TextLabel? = nil
local destRing: Frame? = nil
local meDot: Frame? = nil
local shownIncidents = ""
local selectTab: (string) -> ()

-- Proyección: X a la derecha y Z hacia abajo (como el mapa grande), a escala, centrada
local projection: { MinX: number, MinZ: number, K: number, OX: number, OY: number }? = nil

local function toMap(x: number, z: number): Vector2
	local p = projection :: any
	if not p then
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		local function add(px: number, pz: number)
			minX, maxX = math.min(minX, px), math.max(maxX, px)
			minZ, maxZ = math.min(minZ, pz), math.max(maxZ, pz)
		end
		for _, line in Metro.Lines do
			for _, point in lineGeometry(line).Points do
				add(point.X, point.Z)
			end
		end
		for _, st in Metro.Stations do
			add(st.Surface[1], st.Surface[2])
		end
		local padX, padTop, padBottom = 40, 30, 78 -- (abajo queda sitio para la leyenda)
		local w, h = MAP_W - padX * 2, MAP_H - padTop - padBottom
		local k = math.min(w / math.max(1, maxX - minX), h / math.max(1, maxZ - minZ))
		p = { MinX = minX, MinZ = minZ, K = k, OX = padX + (w - (maxX - minX) * k) / 2, OY = padTop + (h - (maxZ - minZ) * k) / 2 }
		projection = p
	end
	return Vector2.new(p.OX + (x - p.MinX) * p.K, p.OY + (z - p.MinZ) * p.K)
end

local function stationPoint(id: string): Vector2
	local st = Metro.Stations[id]
	return toMap(st.Surface[1], st.Surface[2])
end

local function segment(parent: Instance, a: Vector2, b: Vector2, width: number, color: Color3)
	local d = b - a
	local len = d.Magnitude
	if len < 0.5 then
		return
	end
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
		Size = UDim2.fromOffset(len + width * 0.5, width),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = parent,
	})
end

local function ring(parent: Instance, size: number, color: Color3, thickness: number): Frame
	return create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Parent = parent,
	}, { Theme.corner(size), create("UIStroke", { Color = color, Thickness = thickness }) })
end

local function buildMap(content: Frame)
	local map = create("Frame", {
		Name = "Map",
		Size = UDim2.fromOffset(MAP_W, MAP_H),
		BackgroundColor3 = rgb(8, 14, 30),
		BackgroundTransparency = 0.1,
		ClipsDescendants = true,
		Parent = content,
	}, { Theme.corner(10) })
	mapLayer = map
	local lines = create("Frame", { Name = "Lines", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, Parent = map })
	local marks = create("Frame", { Name = "Marks", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = map })
	local stations = create("Frame", { Name = "Stations", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = map })
	local trains = create("Frame", { Name = "Trains", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, Parent = map })

	-- Las líneas: el recorrido de los túneles (con sus curvas), con su color
	for _, line in Metro.Lines do
		local points = lineGeometry(line).Points
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			segment(lines, toMap(a.X, a.Z), toMap(b.X, b.Z), 6, line.Color)
		end
	end

	-- Las estaciones (una vez cada una aunque pasen dos líneas)
	for id, st in Metro.Stations do
		local served = Metro.linesAt(id)
		if #served == 0 then
			continue
		end
		local transfer = st.Hub == true or #served > 1
		local p = stationPoint(id)
		local size = if transfer then 20 else 13
		local hit = create("TextButton", {
			Name = id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(p.X, p.Y),
			Size = UDim2.fromOffset(TAP, TAP),
			BackgroundTransparency = 1,
			Text = "",
			Parent = stations,
		})
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = if transfer then Color3.new(1, 1, 1) else served[1].Color,
			Parent = hit,
		}, { Theme.corner(size), create("UIStroke", { Color = if transfer then rgb(20, 24, 36) else Color3.new(1, 1, 1), Thickness = if transfer then 3 else 2 }) })
		if transfer then
			ring(hit, size + 10, Color3.new(1, 1, 1), 2).Position = UDim2.fromScale(0.5, 0.5)
		end
		-- El nombre a la derecha (o a la izquierda si la estación está pegada al borde derecho)
		local left = p.X > MAP_W * 0.68
		Theme.label({
			AnchorPoint = Vector2.new(if left then 1 else 0, 0.5),
			Position = UDim2.fromOffset(if left then p.X - size / 2 - 6 else p.X + size / 2 + 6, p.Y),
			Size = UDim2.fromOffset(150, 16),
			Text = st.Name,
			TextSize = if transfer then 14 else 12,
			Font = if transfer then Theme.FontBold else Theme.Font,
			TextXAlignment = if left then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left,
			TextStrokeTransparency = 0.35,
			Parent = stations,
		})
		hit.Activated:Connect(function()
			plannerDest = id
			plannerDistrict = (Metro.StationInfo[id] or {}).District
			selectTab("Ruta")
		end)
	end

	-- La más cercana (aro dorado), el destino elegido (aro verde) y tú
	hereRing = ring(marks, 34, C.Gold, 3)
	hereLabel = Theme.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(120, 16),
		Text = "",
		TextSize = 11,
		Font = Theme.FontBold,
		TextColor3 = C.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		Parent = marks,
	})
	destRing = ring(marks, 38, rgb(90, 230, 120), 3)
	;(destRing :: Frame).Visible = false
	meDot = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = rgb(80, 220, 255),
		Parent = marks,
	}, { Theme.corner(10), create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })

	-- Los trenes
	for _, line in Metro.Lines do
		local marker = create("Frame", {
			Name = line.Id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = line.Color,
			Visible = false,
			Parent = trains,
		}, { Theme.corner(8), create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })
		Theme.label({ Size = UDim2.fromScale(1, 1), Text = "🚇", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Parent = marker })
		trainMarkers[line.Id] = marker
	end

	-- Leyenda (abajo a la izquierda): las líneas y el horario
	local legend = create("Frame", {
		Position = UDim2.fromOffset(10, MAP_H - 72),
		Size = UDim2.fromOffset(MAP_W - 20, 64),
		BackgroundColor3 = rgb(14, 24, 48),
		BackgroundTransparency = 0.25,
		ZIndex = 5,
		Parent = map,
	}, { Theme.corner(8) })
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = legend })
	Theme.padding(6).Parent = legend
	for i, line in Metro.Lines do
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = i, Parent = legend })
		create("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(22, 6), BackgroundColor3 = line.Color, BorderSizePixel = 0, Parent = row })
		Theme.label({
			Position = UDim2.fromOffset(30, 0),
			Size = UDim2.new(1, -30, 1, 0),
			Text = ("<b>%s</b> · %s ↔ %s"):format(line.Name, stationName(line.Stations[1]), stationName(line.Stations[#line.Stations])),
			RichText = true,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
	end
	local schedule = Theme.label({ Size = UDim2.new(1, 0, 0, 16), Text = "", TextSize = 12, TextColor3 = C.Muted, LayoutOrder = 99, Parent = legend })
	table.insert(liveLabels, {
		Label = schedule,
		Text = function()
			local n = #MetroMapUI.incidents()
			return "🕒 " .. scheduleName() .. (if n > 0 then ("  ·  ⚠️ %d incidencia%s"):format(n, if n == 1 then "" else "s") else "")
		end,
	})
end

-- Mueve los trenes, el aro de "estás aquí" y tu punto
local function updateMap()
	if not mapLayer then
		return
	end
	for _, line in Metro.Lines do
		local marker = trainMarkers[line.Id]
		local s = MetroMapUI.trainPosition(line.Id)
		if marker then
			if s then
				local point = Metro.sample(lineGeometry(line).Points, s)
				local p = toMap(point.X, point.Z)
				local target = UDim2.fromOffset(p.X, p.Y)
				if marker.Visible then
					TweenService:Create(marker, TweenInfo.new(LIVE_EVERY, Enum.EasingStyle.Linear), { Position = target }):Play()
				else
					marker.Position = target
					marker.Visible = true
				end
			else
				marker.Visible = false
			end
		end
	end
	local id, _, inside = nearest()
	if id and hereRing and hereLabel then
		local p = stationPoint(id)
		hereRing.Position = UDim2.fromOffset(p.X, p.Y)
		hereLabel.Position = UDim2.fromOffset(p.X, p.Y - 20)
		hereLabel.Text = if inside then "ESTÁS AQUÍ" else "MÁS CERCANA"
	end
	if destRing then
		destRing.Visible = plannerDest ~= nil
		if plannerDest then
			local p = stationPoint(plannerDest)
			destRing.Position = UDim2.fromOffset(p.X, p.Y)
		end
	end
	local pos = myPosition()
	if meDot then
		meDot.Visible = pos ~= nil
		if pos then
			local p = toMap(pos.X, pos.Z)
			meDot.Position = UDim2.fromOffset(math.clamp(p.X, 6, MAP_W - 6), math.clamp(p.Y, 6, MAP_H - 6))
		end
	end
end

---------------------------------------------------------------------
-- Panel de la derecha (pestañas)
---------------------------------------------------------------------
local order = 0
local function nextOrder(): number
	order += 1
	return order
end

local function clearBody()
	liveLabels = {}
	if body then
		for _, child in body:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end
	order = 0
end

local function text(value: string, size: number?, color: Color3?, bold: boolean?): TextLabel
	return Theme.label({
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = value,
		RichText = true,
		TextWrapped = true,
		TextSize = size or 14,
		TextColor3 = color or C.Text,
		Font = if bold then Theme.FontBold else Theme.Font,
		LayoutOrder = nextOrder(),
		Parent = body,
	})
end

local function live(size: number?, color: Color3?, fn: () -> string): TextLabel
	local label = text(fn(), size, color)
	table.insert(liveLabels, { Label = label, Text = fn })
	return label
end

local function button(value: string, color: Color3?, callback: () -> ()): TextButton
	local b = Theme.button({
		Size = UDim2.new(1, -8, 0, TAP),
		Text = value,
		TextSize = 15,
		TextWrapped = true,
		BackgroundColor3 = color or C.PanelLight,
		LayoutOrder = nextOrder(),
		Parent = body,
	})
	b.Activated:Connect(callback)
	return b
end

local function gap(height: number)
	create("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = body })
end

-- Una fila con la barra de color de la línea
local function lineRow(line: Metro.Line?, value: string, height: number?): TextLabel
	local row = create("Frame", {
		Size = UDim2.new(1, -8, 0, height or 44),
		BackgroundColor3 = rgb(20, 32, 56),
		BackgroundTransparency = 0.2,
		LayoutOrder = nextOrder(),
		Parent = body,
	}, { Theme.corner(8) })
	create("Frame", { Size = UDim2.new(0, 6, 1, -10), Position = UDim2.fromOffset(6, 5), BackgroundColor3 = if line then line.Color else C.Muted, BorderSizePixel = 0, Parent = row }, { Theme.corner(3) })
	return Theme.label({
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Text = value,
		RichText = true,
		TextWrapped = true,
		TextSize = 13,
		Parent = row,
	})
end

local function goTo(id: string)
	Gps.setManual(Metro.entrance(id), "Metro " .. stationName(id))
	Hud.toast("Info", "🧭 GPS: boca de metro de " .. stationName(id))
	if window then
		window:Destroy()
	end
end

-- 📍 La estación más cercana
local function showNearest()
	local id = nearest()
	if not id then
		text("No se sabe dónde estás ahora mismo.", 14, C.Muted)
		return
	end
	local st = Metro.Stations[id]
	local info = Metro.StationInfo[id]
	text("📍 Estación más cercana", 13, C.Muted, true)
	text(("<b>%s</b>"):format(st.Name), 22)
	local tags = {}
	for _, line in Metro.linesAt(id) do
		table.insert(tags, lineTag(line))
	end
	text((if info then "Distrito " .. info.District .. " · " else "") .. table.concat(tags, ", "), 13)
	if info and info.Serves then
		text("Cerca: " .. table.concat(info.Serves, ", "), 12, C.Muted)
	end
	live(15, C.Gold, function()
		local nowId, studs, inside = nearest()
		if inside and nowId == id then
			return "🚇 Estás en esta estación"
		end
		return ("📏 %s · 🚶 %s andando"):format(Metro.meters(studs), Metro.duration(studs / Metro.WalkSpeed))
	end)
	button("🧭 Cómo llegar", rgb(20, 150, 140), function()
		goTo(id)
	end)
	gap(4)
	text("🚆 Próximos trenes", 13, C.Muted, true)
	for _, line in Metro.linesAt(id) do
		local i = table.find(line.Stations, id) :: number
		local n = #line.Stations
		for _, terminal in { n, 1 } do
			if terminal ~= i then
				local label = lineRow(line, "", 40)
				local function update(): string
					return boardText(line, i, terminal)
				end
				label.Text = update()
				label.TextSize = 12
				table.insert(liveLabels, { Label = label, Text = update })
			end
		end
	end
	gap(4)
	button("🗺️ Planificar un viaje", nil, function()
		selectTab("Ruta")
	end)
end

-- 🧭 Planificador
local function showPlanner()
	local origin = nearest()
	if not origin then
		text("No se sabe dónde estás ahora mismo.", 14, C.Muted)
		return
	end
	text(("Origen: <b>%s</b> (tu estación más cercana)"):format(stationName(origin)), 13, C.Muted)
	if not plannerDest then
		if not plannerDistrict then
			text("<b>1 ·</b> ¿A qué zona vas?", 16)
			text("(o toca una estación en el plano)", 12, C.Muted)
			local grid = create("Frame", { Size = UDim2.new(1, -8, 0, math.ceil(#Metro.Districts / 2) * (TAP + 6)), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = body })
			create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, TAP), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
			for i, d in Metro.Districts do
				local b = Theme.button({ Text = d.Icon .. " " .. d.Name, TextSize = 14, LayoutOrder = i, Parent = grid })
				b.Activated:Connect(function()
					plannerDistrict = d.Id
					selectTab("Ruta")
				end)
			end
			return
		end
		local districtName = plannerDistrict :: string
		for _, d in Metro.Districts do
			if d.Id == plannerDistrict then
				districtName = d.Icon .. " " .. d.Name
			end
		end
		text(("<b>2 ·</b> Elige la estación · %s"):format(districtName), 16)
		local ids = {}
		for id, info in Metro.StationInfo do
			if info.District == plannerDistrict and Metro.Stations[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return stationName(a) < stationName(b)
		end)
		for _, id in ids do
			local serves = (Metro.StationInfo[id] or {}).Serves or {}
			local b = button(("%s\n<font size=\"11\">%s</font>"):format(stationName(id), table.concat(serves, ", ")), nil, function()
				plannerDest = id
				selectTab("Ruta")
			end)
			b.RichText = true
			b.Size = UDim2.new(1, -8, 0, 52)
		end
		button("‹ Otra zona", rgb(60, 70, 100), function()
			plannerDistrict = nil
			selectTab("Ruta")
		end)
		return
	end

	local dest = plannerDest :: string
	text("<b>3 ·</b> Ruta recomendada", 16)
	text(("Destino: <b>%s</b>"):format(stationName(dest)), 15)
	if dest == origin then
		text("Ya es tu estación más cercana: ¡puedes ir andando!", 14, C.Gold)
	else
		local route = Metro.route(origin, dest)
		if not route or #route.Legs == 0 then
			text("No hay ruta entre esas estaciones.", 14, C.Error)
		else
			for k, leg in route.Legs do
				local line = Metro.lineById[leg.Line]
				if k > 1 and line then
					lineRow(nil, ("🔁 Transbordo en <b>%s</b> a %s"):format(stationName(leg.From), lineTag(line)), 36)
				end
				local stops = #leg.Stops - 1
				lineRow(line, ("%s  %s → %s (%d parada%s)"):format(if line then lineTag(line) else leg.Line, stationName(leg.From), stationName(leg.To), stops, if stops == 1 then "" else "s"), 46)
			end
			text(("⏱️ Tiempo aproximado: <b>%s</b>%s"):format(Metro.duration(route.Seconds), if route.Transfers > 0 then (" · %d transbordo%s"):format(route.Transfers, if route.Transfers == 1 then "" else "s") else ""), 14)
			local first = route.Legs[1]
			local line = Metro.lineById[first.Line]
			if line then
				local i = table.find(line.Stations, first.From)
				local j = table.find(line.Stations, first.To)
				if i and j then
					live(13, C.Gold, function()
						return "Próximo tren: " .. boardText(line, i, j)
					end)
				end
			end
		end
		button("🧭 Cómo llegar a " .. stationName(origin), rgb(20, 150, 140), function()
			goTo(origin)
		end)
	end
	button("‹ Cambiar destino", rgb(60, 70, 100), function()
		plannerDest = nil
		selectTab("Ruta")
	end)
end

-- ⚠️ Horario, líneas e incidencias
local function showStatus()
	live(15, C.Text, function()
		return "🕒 Horario: <b>" .. scheduleName() .. "</b>"
	end)
	gap(2)
	text("Líneas", 13, C.Muted, true)
	for _, line in Metro.Lines do
		lineRow(line, ("%s · %s ↔ %s · %d estaciones"):format(lineTag(line), stationName(line.Stations[1]), stationName(line.Stations[#line.Stations]), #line.Stations), 44)
	end
	gap(2)
	text("⚠️ Incidencias", 13, C.Muted, true)
	local list = MetroMapUI.incidents()
	if #list == 0 then
		text("Sin incidencias: el servicio funciona con normalidad.", 13, rgb(120, 230, 140))
	end
	for _, inc in list do
		local line = Metro.lineById[inc.Line]
		local where = if line then lineTag(line) else ""
		if inc.Station ~= "" and Metro.Stations[inc.Station] then
			where ..= (if where ~= "" then " · " else "") .. stationName(inc.Station)
		end
		local value = ("%s %s%s"):format(inc.Icon, if where ~= "" then where .. "\n" else "", inc.Text)
		if inc.Alt ~= "" then
			value ..= "\n<i>" .. inc.Alt .. "</i>"
		end
		lineRow(line, value, if inc.Alt ~= "" then 72 else 56)
	end
end

local TABS = {
	{ Id = "Cercana", Text = "📍 Cercana", Show = showNearest },
	{ Id = "Ruta", Text = "🧭 Ruta", Show = showPlanner },
	{ Id = "Avisos", Text = "⚠️ Avisos", Show = showStatus },
}

selectTab = function(id: string)
	if not window or not body then
		return
	end
	currentTab = id
	for tabId, b in tabButtons do
		b.BackgroundColor3 = if tabId == id then C.Accent else C.PanelLight
	end
	clearBody()
	for _, tab in TABS do
		if tab.Id == id then
			tab.Show()
		end
	end
	local root = ReplicatedStorage:FindFirstChild("MetroState")
	local raw = root and root:GetAttribute("Incidents")
	shownIncidents = if type(raw) == "string" then raw else ""
	;(body :: ScrollingFrame).CanvasPosition = Vector2.zero
	updateMap()
end

---------------------------------------------------------------------

-- Abre el plano (tab = "Cercana", "Ruta" o "Avisos")
function MetroMapUI.open(tab: string?)
	local w, content, close = Dialog.window("MetroMap", "🚇 Plano del metro", WINDOW)
	window = w
	tabButtons = {}
	trainMarkers = {}
	buildMap(content)
	local side = create("Frame", { Position = UDim2.fromOffset(SIDE_X, 0), Size = UDim2.new(0, SIDE_W, 1, 0), BackgroundTransparency = 1, Parent = content })
	for i, t in TABS do
		local b = Theme.button({
			Position = UDim2.new((i - 1) / #TABS, if i == 1 then 0 else 3, 0, 0),
			Size = UDim2.new(1 / #TABS, -4, 0, TAP),
			Text = t.Text,
			TextSize = 14,
			Parent = side,
		})
		b.Activated:Connect(function()
			selectTab(t.Id)
		end)
		tabButtons[t.Id] = b
	end
	body = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, TAP + 8),
		Size = UDim2.new(1, 0, 1, -(TAP + 8)),
		BackgroundColor3 = rgb(8, 14, 28),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = side,
	}, { Theme.corner(8) })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	Theme.padding(6).Parent = body
	close.Activated:Connect(function()
		w:Destroy()
	end)
	w.Destroying:Connect(function()
		if window == w then
			window, body, mapLayer = nil, nil, nil
			hereRing, hereLabel, destRing, meDot = nil, nil, nil, nil
		end
	end)
	local first = tab
	if first ~= "Cercana" and first ~= "Ruta" and first ~= "Avisos" then
		first = currentTab
	end
	selectTab(first :: string)

	-- En vivo: trenes cada 0,2 s; textos (tiempos, horario) cada segundo; incidencias al cambiar
	task.spawn(function()
		local ticks = 0
		while window == w and w.Parent do
			updateMap()
			ticks += 1
			if ticks % 5 == 0 then
				for _, entry in liveLabels do
					if entry.Label.Parent then
						entry.Label.Text = entry.Text()
					end
				end
				local root = ReplicatedStorage:FindFirstChild("MetroState")
				local raw = root and root:GetAttribute("Incidents")
				if currentTab == "Avisos" and (if type(raw) == "string" then raw else "") ~= shownIncidents then
					selectTab("Avisos")
				end
			end
			task.wait(LIVE_EVERY)
		end
	end)
end

function MetroMapUI.close()
	if window then
		window:Destroy()
	end
end

-- Elige un destino desde fuera (p. ej. una misión) y abre el planificador
function MetroMapUI.planTo(stationId: string)
	if Metro.Stations[stationId] then
		plannerDest = stationId
		plannerDistrict = (Metro.StationInfo[stationId] or {}).District
		MetroMapUI.open("Ruta")
	end
end

function MetroMapUI.init()
	Hud.addButton("🚇 Metro", rgb(200, 40, 60), 5, function()
		if window then
			MetroMapUI.close()
		else
			MetroMapUI.open()
		end
	end)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:WaitForChild("Metro") :: RemoteEvent
	remote.OnClientEvent:Connect(function(action, data)
		if action == "OpenMap" then
			MetroMapUI.open(if type(data) == "string" then data else nil)
		end
	end)
end

return MetroMapUI
