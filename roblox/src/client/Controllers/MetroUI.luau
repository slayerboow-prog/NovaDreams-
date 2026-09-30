-- MetroUI (cliente): el metro subterráneo.
--   * En el tren: panel compacto abajo en el centro, encima de la barra rápida (HudLayout: Items.Ride,
--     a la escala del HUD: no pisa ni los botones táctiles, ni el joystick, ni los comandos, ni la
--     misión, ni el ❓) con la línea, la tira de estaciones (✓ pasadas, ● aquí, ○ próximas) y un
--     trenecito que avanza por ella en vivo; en cada parada, "Bajar en…"; y "🗺️" (MetroMapUI). La
--     incidencia de tu línea y el encargo con tiempo van dentro, en una línea pequeña. Mientras vas
--     en el tren no salen los carteles de "Subir al metro" (antes asomaban detrás del panel).
--   * Incidencias (Remote "Incident"): aviso arriba durante unos segundos (tocarlo abre los avisos);
--     si vas en el tren, dentro de su panel.
--   * Máquinas de billetes, tiendas, tablón de encargos (y el encargo que llevas, con su tiempo).
--   * Fotomatón (flash) y escenario: minijuego de guitarra (pulsa cuando la marca está en verde).
--   * Escaleras mecánicas de las bocas de metro: los peldaños se mueven (solo las que tienes cerca)
--     y la cinta invisible de debajo te lleva (también se le pone aquí la velocidad, por si acaso).

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local Format = require(ReplicatedStorage.Shared.Format)
local Metro = require(ReplicatedStorage.Shared.Metro)
local MetroMapUI = require(script.Parent.MetroMapUI)

local MetroUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Metro") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local gui: ScreenGui
local ride: Frame
local rideTitle: TextLabel
local rideStrip: Frame
local rideMarker: Frame
local rideArrow: TextLabel
local alightButton: TextButton
local rideInfo: TextLabel -- la línea pequeña de abajo (incidencia de tu línea, encargo con tiempo)
local rideIncident = "" -- (texto de la incidencia de la línea en la que vas)
local rideIncidentToken = 0
local banner: TextButton
local bannerText: TextLabel
local bannerStripe: Frame
local bannerToken = 0
local missionLabel: TextLabel
local flash: Frame
local lineInfo: { [string]: any }? = nil
local rideAt: number? = nil -- índice de la estación en la que está el tren (nil: en marcha)
local rideLast: number? = nil -- la última estación en la que ha parado
local rideNext: number? = nil -- la siguiente
local markerFrac = 0.5 -- dónde va el trenecito de la tira (0-1)
local missionDeadline: number? = nil
local missionText = ""

-- Medidas del panel del tren (en unidades del lienzo del HUD; el tamaño máximo es HudLayout.Sizes.Ride)
local RIDE_PAD = 10
local RIDE_TITLE = 40 -- fila del título (con "Bajar en…" y 🗺️ a la derecha)
local RIDE_STRIP = 58 -- la tira de estaciones
local RIDE_LINE = 26 -- cada línea pequeña de abajo
local TRACK_Y = 16 -- la vía de la tira (dentro de rideStrip)

---------------------------------------------------------------------
-- En el tren: la tira de estaciones (✓ pasadas, ● aquí, ○ próximas) y el trenecito en vivo
---------------------------------------------------------------------
local function stationIndex(name: string?): number?
	local info = lineInfo
	if not info or not name then
		return nil
	end
	return table.find(info.Stations, name)
end

local function rideDir(): number
	if rideLast and rideNext and rideNext ~= rideLast then
		return if rideNext > rideLast then 1 else -1
	end
	return 1
end

local function drawStrip(current: string?, nextName: string?)
	for _, child in rideStrip:GetChildren() do
		if child:IsA("GuiObject") and child ~= rideMarker then
			child:Destroy()
		end
	end
	local info = lineInfo
	if not info then
		return
	end
	rideAt = stationIndex(current)
	if rideAt then
		rideLast = rideAt
	end
	rideNext = stationIndex(nextName)
	local n = #info.Stations
	local dir = rideDir()
	-- La vía
	create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5 / n, 0, 0, TRACK_Y),
		Size = UDim2.new((n - 1) / n, 0, 0, 4),
		BackgroundColor3 = info.Color,
		BorderSizePixel = 0,
		Parent = rideStrip,
	})
	for i, name in info.Stations do
		local here = i == rideAt
		local isNext = i == rideNext
		local passed = not here and rideLast ~= nil and (if dir > 0 then i <= rideLast else i >= rideLast)
		local size = if here then 26 else 22
		create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new((i - 0.5) / n, 0, 0, TRACK_Y),
			Size = UDim2.fromOffset(size, size),
			BackgroundColor3 = if here then Color3.new(1, 1, 1) elseif passed then rgb(52, 62, 86) else C.Panel,
			Text = if here then "●" elseif passed then "✓" else "○",
			TextColor3 = if here then info.Color elseif passed then C.Muted elseif isNext then C.Gold else C.Text,
			TextSize = if here then 18 else 14,
			Font = Theme.FontBold,
			ZIndex = 2,
			Parent = rideStrip,
		}, {
			Theme.corner(size),
			create("UIStroke", { Color = if isNext then C.Gold elseif here then Color3.new(1, 1, 1) else info.Color, Thickness = if isNext or here then 2.5 else 1.5 }),
		})
		Theme.label({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new((i - 0.5) / n, 0, 0, TRACK_Y + 15),
			Size = UDim2.new(1 / n, -2, 0, 22),
			Text = name,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = if here then Color3.new(1, 1, 1) elseif isNext then C.Gold elseif passed then rgb(120, 135, 160) else C.Muted,
			Font = if here or isNext then Theme.FontBold else Theme.Font,
			Parent = rideStrip,
		})
	end
end

-- Parte de la tira (0-1) que corresponde a una distancia del recorrido de la línea
local function stripFraction(centers: { number }, s: number): number
	local n = #centers
	if s <= centers[1] then
		return 0.5 / n
	end
	for k = 1, n - 1 do
		if s <= centers[k + 1] then
			local t = (s - centers[k]) / math.max(1, centers[k + 1] - centers[k])
			return (k - 0.5 + math.clamp(t, 0, 1)) / n
		end
	end
	return (n - 0.5) / n
end

-- Cada fotograma: el trenecito va por la tira según dónde está el tren de verdad (MetroState);
-- si aún no hay datos, entre la última parada y la siguiente
local function updateMarker(dt: number)
	local info = lineInfo
	if not info or not ride.Visible then
		return
	end
	local n = #info.Stations
	local target: number
	local dir = rideDir()
	local centers = MetroMapUI.centers(info.Line)
	local s, liveDir = MetroMapUI.trainPosition(info.Line)
	if s and centers and #centers == n then
		target = stripFraction(centers, s)
		dir = liveDir or dir
		markerFrac = target
	else
		if rideAt then
			target = (rideAt - 0.5) / n
		elseif rideLast and rideNext then
			target = (rideLast + rideNext - 1) / (2 * n)
		else
			target = markerFrac
		end
		markerFrac += (target - markerFrac) * math.min(1, dt * 2)
	end
	rideMarker.Position = UDim2.new(markerFrac, 0, 0, 8)
	rideArrow.Text = if dir < 0 then "◀🚇" else "🚇▶"
end

-- Las líneas pequeñas de abajo del panel (incidencia y encargo): el panel crece hacia arriba
local function missionLine(): string
	if not missionLabel or not missionLabel.Visible then
		return ""
	end
	return missionLabel.Text
end

local function layoutRide()
	if not ride then
		return
	end
	local lines = {}
	if rideIncident ~= "" then
		table.insert(lines, rideIncident)
	end
	local mission = missionLine()
	if mission ~= "" then
		table.insert(lines, mission)
	end
	rideInfo.Text = table.concat(lines, "\n")
	rideInfo.Visible = #lines > 0
	rideInfo.Size = UDim2.new(1, 0, 0, RIDE_LINE * #lines)
	local maxSize = HudLayout.Sizes.Ride
	ride.Size = UDim2.fromOffset(maxSize.X, math.min(maxSize.Y, RIDE_PAD * 2 + RIDE_TITLE + RIDE_STRIP + RIDE_LINE * #lines))
end

-- Mientras vas en el tren, fuera los carteles de "Subir al metro" (solo en tu pantalla)
local function boardPrompts(enabled: boolean)
	for _, marker in CollectionService:GetTagged("MetroBoard") do
		for _, p in marker:GetChildren() do
			if p:IsA("ProximityPrompt") then
				p.Enabled = enabled
			end
		end
	end
end

local function onBoard(data: { [string]: any })
	lineInfo = data
	rideLast, rideNext, rideAt = nil, nil, nil
	ride.Visible = true
	ride.BackgroundColor3 = C.Panel
	rideTitle.Text = ("🚇 %s · próxima: <b>%s</b>"):format(data.LineName, data.Next)
	drawStrip(data.Station, data.Next)
	markerFrac = if rideAt then (rideAt - 0.5) / #data.Stations else 0.5
	rideMarker.BackgroundColor3 = data.Color or C.Accent
	alightButton.Visible = true
	alightButton.Text = "Bajar en " .. data.Station
	-- (la incidencia que hubiera en otra línea no va en el panel; la de esta, sí)
	if banner.Visible then
		banner.Visible = false
	end
	boardPrompts(false)
	layoutRide()
end

local function onArrive(data: { [string]: any })
	if not lineInfo then
		return
	end
	rideTitle.Text = ("🚇 %s · <b>%s</b> · puertas abiertas"):format(lineInfo.LineName, data.Station)
	drawStrip(data.Station, data.Next)
	alightButton.Visible = true
	alightButton.Text = "Bajar en " .. data.Station
end

local function onDepart(data: { [string]: any })
	if not lineInfo then
		return
	end
	rideTitle.Text = ("🚇 %s · próxima: <b>%s</b>"):format(lineInfo.LineName, data.Next)
	drawStrip(nil, data.Next)
	alightButton.Visible = false
end

local function onOff()
	lineInfo = nil
	rideAt, rideLast, rideNext = nil, nil, nil
	ride.Visible = false
	rideIncident = ""
	boardPrompts(true)
	missionLabel.Visible = missionDeadline ~= nil or missionText ~= ""
end

---------------------------------------------------------------------
-- Incidencias: aviso arriba ("⚠️ INCIDENCIA · Línea 1 · Retraso de 2 min · Se recomienda…")
---------------------------------------------------------------------
local function showIncident(data: any)
	if type(data) ~= "table" then
		banner.Visible = false
		return
	end
	local line = Metro.lineById[data.Line or ""]
	local parts = { "⚠️ <b>INCIDENCIA</b>" }
	if line then
		table.insert(parts, "<b>" .. line.Name .. "</b>")
	end
	local station = Metro.Stations[data.Station or ""]
	local body = tostring(data.Text or "")
	if station and not string.find(body, station.Name, 1, true) then
		table.insert(parts, station.Name)
	end
	if body ~= "" then
		table.insert(parts, (if data.Icon then tostring(data.Icon) .. " " else "") .. body)
	end
	if type(data.Alt) == "string" and data.Alt ~= "" then
		table.insert(parts, data.Alt)
	end
	-- En el tren: una línea pequeña dentro del panel (antes un cartel naranja debajo, pisando todo)
	if ride.Visible then
		if lineInfo and data.Line ~= nil and data.Line ~= lineInfo.Line then
			return -- (de otra línea: se ve en los avisos del plano)
		end
		local short = { "⚠️ <b>Incidencia</b>" }
		local stationName = station and station.Name
		if body ~= "" then
			table.insert(short, body)
		elseif stationName then
			table.insert(short, stationName)
		end
		rideIncident = '<font color="#FFC857">' .. table.concat(short, ": ") .. "</font>"
		rideIncidentToken += 1
		local token = rideIncidentToken
		layoutRide()
		task.delay(30, function()
			if token == rideIncidentToken then
				rideIncident = ""
				layoutRide()
			end
		end)
		return
	end
	bannerText.Text = table.concat(parts, " · ")
	bannerStripe.BackgroundColor3 = if line then line.Color else C.Gold
	banner.Position = UDim2.new(0.5, 0, 0, 70)
	banner.Visible = true
	bannerToken += 1
	local token = bannerToken
	task.delay(12, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

---------------------------------------------------------------------
-- Menús (billetes, tiendas, encargos)
---------------------------------------------------------------------
local function listWindow(name: string, title: string, rows: { any }, height: number?)
	-- (con muchas filas la lista se desplaza: que quepa también en el móvil)
	local window, content, close = Dialog.window(name, title, Vector2.new(460, math.min(height or (110 + #rows * 70), 470)))
	local layout = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = layout })
	for i, r in rows do
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = rgb(20, 32, 56), BackgroundTransparency = 0.2, LayoutOrder = i, Parent = layout }, { Theme.corner(10) })
		Theme.label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -140, 0, 26), Text = r.Title, RichText = true, TextSize = 15, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -140, 0, 28), Text = r.Sub or "", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = row })
		local b = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(110, 40), Text = r.Button, TextSize = 14, BackgroundColor3 = r.Color or C.Accent, Parent = row })
		b.Activated:Connect(function()
			r.Action()
			if r.Close then
				window:Destroy()
			end
		end)
	end
	close.Activated:Connect(function()
		window:Destroy()
	end)
	return window, layout
end

local function openTickets(tickets: { any }, passes: { [string]: any }?)
	local rows = {}
	if passes and passes.Current then
		local left = if typeof(passes.Until) == "number" and typeof(passes.Now) == "number" then math.max(0, passes.Until - passes.Now) else 0
		table.insert(rows, {
			Title = ("✅ <b>Tu abono:</b> %s"):format(passes.Current),
			Sub = ("Te quedan %s reales. Pasas los tornos sin billete."):format(Metro.duration(left)),
			Button = "Plano",
			Close = true,
			Action = function()
				local ok, MetroMapUI = pcall(require, script.Parent.MetroMapUI)
				if ok and MetroMapUI.open then
					MetroMapUI.open()
				end
			end,
		})
	end
	for _, t in tickets do
		table.insert(rows, {
			Title = ("%s <b>%s</b> · %s"):format(t.Icon, t.Name, Format.money(t.Price)),
			Sub = if t.Count > 1 then ("%d viajes (cada uno, un paso por el torno)"):format(t.Count) else "Un viaje: se gasta al pasar el torno",
			Button = "Comprar",
			Action = function()
				Remote:FireServer("BuyTicket", t.Id)
			end,
		})
	end
	for _, p in (passes and passes.Passes) or {} do
		local who = if p.Student then " · para estudiantes" elseif p.Worker then " · para quien trabaja" else ""
		table.insert(rows, {
			Title = ("%s <b>%s</b> · %s"):format(p.Icon, p.Name, Format.money(p.Price)),
			Sub = ("Viajes sin límite durante %d %s de juego%s"):format(p.Days, if p.Days == 1 then "día" else "días", who),
			Button = "Comprar",
			Action = function()
				Remote:FireServer("BuyPass", p.Id)
			end,
		})
	end
	listWindow("MetroTickets", "🎫 Billetes y abonos de metro", rows)
end

local function openShop(shop: { [string]: any })
	local rows = {}
	for _, it in shop.Items do
		table.insert(rows, {
			Title = ("%s <b>%s</b> · %s"):format(it.Icon, it.Name, Format.money(it.Price)),
			Sub = it.Desc,
			Button = "Comprar",
			Action = function()
				Remote:FireServer("Buy", shop.ShopId, it.Id)
			end,
		})
	end
	listWindow("MetroShop", shop.Icon .. " " .. shop.Name, rows)
end

local function openMissions(data: { [string]: any })
	local rows = {}
	if data.Current then
		table.insert(rows, {
			Title = "<b>Tu encargo:</b> " .. data.Current.Text,
			Sub = "Solo puedes llevar un encargo a la vez.",
			Button = "Cancelar",
			Color = rgb(150, 50, 50),
			Close = true,
			Action = function()
				Remote:FireServer("CancelMission")
			end,
		})
	else
		for _, o in data.Offers do
			table.insert(rows, {
				Title = ("%s <b>%s</b> · %s"):format(o.Icon, o.Name, Format.money(o.Reward)),
				Sub = "Una estación al azar del metro. ¡Acepta y sigue la línea guía!",
				Button = "Aceptar",
				Close = true,
				Action = function()
					Remote:FireServer("Accept", o.Id)
				end,
			})
		end
	end
	listWindow("MetroMissions", "📌 Encargos del metro", rows)
end

---------------------------------------------------------------------
-- Escenario: minijuego de guitarra
---------------------------------------------------------------------
local function busk(data: { [string]: any })
	local window, content, close = Dialog.window("MetroBusk", "🎸 ¡A tocar!", Vector2.new(480, 250))
	local info = Theme.label({ Size = UDim2.new(1, 0, 0, 40), Text = "Pulsa «¡Toca!» (o la tecla F) cuando la marca esté en la zona verde.", TextSize = 14, TextWrapped = true, Parent = content })
	local bar = create("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = rgb(30, 34, 44), Parent = content }, { Theme.corner(8) })
	local zone = create("Frame", { Size = UDim2.new(0.16, 0, 1, 0), BackgroundColor3 = rgb(50, 190, 90), Parent = bar }, { Theme.corner(8) })
	local mark = create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 6, 1, 8), Position = UDim2.new(0, 0, 0, -4), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar })
	local score = Theme.label({ Position = UDim2.fromOffset(0, 94), Size = UDim2.new(1, 0, 0, 24), Text = "", TextSize = 16, Font = Theme.FontBold, Parent = content })
	local hit = Theme.button({ Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 0, 48), Text = "🎸 ¡Toca!", TextSize = 20, BackgroundColor3 = C.Accent, Parent = content })
	local notes, hits, pos, speed, dir, zoneStart = 0, 0, 0, 0.9, 1, 0.4
	local finished = false
	local function newNote()
		notes += 1
		zoneStart = 0.08 + math.random() * 0.76
		zone.Position = UDim2.fromScale(zoneStart, 0)
		speed = 0.8 + notes * 0.06
		score.Text = ("Nota %d de %d · aciertos: %d"):format(notes, data.Notes, hits)
	end
	local function finish()
		if finished then
			return
		end
		finished = true
		ContextActionService:UnbindAction("MetroBusk")
		Remote:FireServer("BuskEnd", data.Token, hits)
		score.Text = ("¡Bravo! %d de %d notas"):format(hits, data.Notes)
		info.Text = "La gente está echando monedas en la funda de la guitarra…"
		hit.Visible = false
		task.delay(2.5, function()
			if window.Parent then
				window:Destroy()
			end
		end)
	end
	local lastPress = 0
	local function press()
		if finished or os.clock() - lastPress < 0.25 then
			return
		end
		lastPress = os.clock()
		if pos >= zoneStart and pos <= zoneStart + 0.16 then
			hits += 1
			zone.BackgroundColor3 = rgb(120, 255, 150)
		else
			zone.BackgroundColor3 = rgb(200, 60, 60)
		end
		task.delay(0.15, function()
			zone.BackgroundColor3 = rgb(50, 190, 90)
		end)
		if notes >= data.Notes then
			finish()
		else
			newNote()
		end
	end
	hit.Activated:Connect(press)
	ContextActionService:BindAction("MetroBusk", function(_, state)
		if state == Enum.UserInputState.Begin then
			press()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonA)
	close.Activated:Connect(function()
		finish()
		window:Destroy()
	end)
	newNote()
	local started = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if finished or not window.Parent then
			conn:Disconnect()
			return
		end
		pos += dir * speed * dt
		if pos > 1 then
			pos, dir = 1, -1
		elseif pos < 0 then
			pos, dir = 0, 1
		end
		mark.Position = UDim2.new(pos, 0, 0, -4)
		-- Si tardas mucho en una nota, cuenta como fallo
		if os.clock() - started > 60 then
			finish()
		end
	end)
end

---------------------------------------------------------------------
-- Escaleras mecánicas: peldaños que se mueven
---------------------------------------------------------------------
local ESCALATOR_RANGE = 170
local escalators: { [Instance]: { Steps: { BasePart }, Refresh: number } } = {}

local function collectSteps(model: Instance): { BasePart }
	local list = {}
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and typeof(p:GetAttribute("I")) == "number" then
			table.insert(list, p)
		end
	end
	return list
end

local function startEscalators()
	local function add(model: Instance)
		escalators[model] = { Steps = collectSteps(model), Refresh = os.clock() }
	end
	for _, m in CollectionService:GetTagged("MetroEscalatorSteps") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("MetroEscalatorSteps"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("MetroEscalatorSteps"):Connect(function(m)
		escalators[m] = nil
	end)
	-- La cinta de debajo (el servidor ya le pone la velocidad; aquí también, que es quien mueve al personaje)
	local function belt(p: Instance)
		local v = p:GetAttribute("Velocity")
		if p:IsA("BasePart") and typeof(v) == "Vector3" then
			p.AssemblyLinearVelocity = v
		end
	end
	for _, p in CollectionService:GetTagged("MetroEscalator") do
		belt(p)
	end
	CollectionService:GetInstanceAddedSignal("MetroEscalator"):Connect(belt)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / 30 then
			return
		end
		acc = 0
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local eye = camera.CFrame.Position
		local now = os.clock()
		for model, e in escalators do
			local origin = model:GetAttribute("Origin")
			if typeof(origin) == "CFrame" and (origin.Position - eye).Magnitude < ESCALATOR_RANGE then
				if now - e.Refresh > 2 then
					e.Steps = collectSteps(model) -- (con la carga por zonas llegan poco a poco)
					e.Refresh = now
				end
				local pitch, count = model:GetAttribute("Pitch"), model:GetAttribute("Count")
				local tan, speed = model:GetAttribute("Tan"), model:GetAttribute("Speed")
				local parts, cframes = {}, {}
				for _, p in e.Steps do
					if p.Parent then
						local d = Metro.escalatorOffset(p:GetAttribute("I"), now, pitch, count, speed)
						table.insert(parts, p)
						table.insert(cframes, origin * CFrame.new(0, -d * tan - pitch * tan / 2 + 0.05, -d))
					end
				end
				local ok = pcall(function()
					workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
				end)
				if not ok then
					for i, p in parts do
						p.CFrame = cframes[i]
					end
				end
			end
		end
	end)
end

---------------------------------------------------------------------

function MetroUI.init()
	task.spawn(startEscalators)
	gui = create("ScreenGui", { Name = "MetroGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	-- Panel del tren: en su propia pantalla, a la escala del HUD y donde dice HudLayout (Items.Ride)
	local rideGui = create("ScreenGui", { Name = "MetroRideGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	HudLayout.scaleGui(rideGui)
	ride = Theme.panel({
		Name = "Ride",
		Size = UDim2.fromOffset(HudLayout.Sizes.Ride.X, RIDE_PAD * 2 + RIDE_TITLE + RIDE_STRIP),
		Visible = false,
		Parent = rideGui,
	})
	HudLayout.onChanged(function(layout)
		local p = layout.Items.Ride
		if p then
			HudLayout.apply(ride, p, true) -- (el alto depende de las líneas pequeñas: crece hacia arriba)
		end
	end)
	Theme.padding(RIDE_PAD).Parent = ride
	rideTitle = Theme.label({ Size = UDim2.new(1, -262, 0, RIDE_TITLE), Text = "", RichText = true, TextSize = 22, TextTruncate = Enum.TextTruncate.AtEnd, Parent = ride })
	rideStrip = create("Frame", { Position = UDim2.fromOffset(0, RIDE_TITLE), Size = UDim2.new(1, 0, 0, RIDE_STRIP), BackgroundTransparency = 1, Parent = ride })
	rideMarker = create("Frame", {
		Name = "Train",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(40, 18),
		BackgroundColor3 = C.Accent,
		ZIndex = 3,
		Parent = rideStrip,
	}, { Theme.corner(6), create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }) })
	rideArrow = Theme.label({ Size = UDim2.fromScale(1, 1), Text = "🚇▶", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, Parent = rideMarker })
	rideInfo = Theme.label({
		Name = "Info",
		Position = UDim2.fromOffset(0, RIDE_TITLE + RIDE_STRIP),
		Size = UDim2.new(1, 0, 0, RIDE_LINE),
		Text = "",
		RichText = true,
		TextSize = 16,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = C.Muted,
		Visible = false,
		Parent = ride,
	})
	-- "Bajar en…" y el plano, dentro del panel (arriba a la derecha): nada cuelga por fuera
	alightButton = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -62, 0, 0),
		Size = UDim2.fromOffset(190, RIDE_TITLE - 2),
		Text = "Bajar aquí",
		TextSize = 18,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundColor3 = rgb(40, 170, 80),
		Visible = false,
		Parent = ride,
	})
	alightButton.Activated:Connect(function()
		Remote:FireServer("Alight")
	end)
	local planButton = Theme.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(56, RIDE_TITLE - 2),
		Text = "🗺️",
		TextSize = 20,
		Parent = ride,
	})
	planButton.Activated:Connect(function()
		MetroMapUI.open("Ruta")
	end)
	-- (lo que entra en el metro después, con el panel ya abierto: tampoco sale "Subir al metro")
	CollectionService:GetInstanceAddedSignal("MetroBoard"):Connect(function()
		if ride.Visible then
			task.defer(boardPrompts, false)
		end
	end)
	RunService.RenderStepped:Connect(updateMarker)
	banner = create("TextButton", {
		Name = "MetroIncident",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(600, 52),
		BackgroundColor3 = rgb(70, 40, 8),
		BackgroundTransparency = 0.08,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	}, { Theme.corner(10), create("UIStroke", { Color = C.Gold, Thickness = 2 }) })
	bannerStripe = create("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, 6, 1, -16), BackgroundColor3 = C.Gold, BorderSizePixel = 0, ZIndex = 21, Parent = banner }, { Theme.corner(3) })
	bannerText = Theme.label({
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Text = "",
		RichText = true,
		TextWrapped = true,
		TextSize = 14,
		ZIndex = 21,
		Parent = banner,
	})
	banner.Activated:Connect(function()
		banner.Visible = false
		MetroMapUI.open("Avisos")
	end)
	missionLabel = Theme.label({
		Name = "MetroMission",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -176),
		Size = UDim2.fromOffset(520, 26),
		Text = "",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.4,
		Visible = false,
		Parent = gui,
	})
	flash = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 40, Parent = gui })

	Remote.OnClientEvent:Connect(function(action, data, extra)
		if action == "Board" then
			onBoard(data)
		elseif action == "Arrive" then
			onArrive(data)
		elseif action == "Depart" then
			onDepart(data)
		elseif action == "Off" then
			onOff()
		elseif action == "Incident" then
			showIncident(data)
		elseif action == "Tickets" then
			openTickets(data, extra)
		elseif action == "Shop" then
			openShop(data)
		elseif action == "Missions" then
			openMissions(data)
		elseif action == "Mission" then
			if data then
				missionText = data.Text
				missionDeadline = if data.Deadline then os.clock() + data.Deadline else nil
				missionLabel.Visible = true
			else
				missionText = ""
				missionDeadline = nil
				missionLabel.Visible = false
			end
			if ride.Visible then
				layoutRide()
			end
		elseif action == "Busk" then
			busk(data)
		elseif action == "Flash" then
			for _ = 1, 4 do
				flash.Visible = true
				flash.BackgroundTransparency = 0
				TweenService:Create(flash, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
				task.wait(0.3)
			end
			flash.Visible = false
		end
	end)
	-- La primera vez que bajas al metro en cada partida: cómo se viaja
	task.spawn(function()
		while true do
			task.wait(1)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and root.Position.Y < Metro.Underground then
				local stage = player:GetAttribute("LifeStage")
				local ticket = if Metro.FreeStages[stage or ""] then "Pasas el torno gratis." else "Compra el billete en las máquinas azules."
				Hud.toast("Info", "🚇 ¡Te damos la bienvenida al metro! " .. ticket .. " Pulsa «Subir al metro» en el andén.")
				break
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if missionText ~= "" then
				local left = if missionDeadline then math.max(0, math.floor(missionDeadline - os.clock())) else nil
				missionLabel.Text = "📌 " .. missionText .. (if left then ("  ⏱️ %d:%02d"):format(left // 60, left % 60) else "")
			end
			-- En el tren, el encargo va dentro del panel (una línea pequeña), no suelto por la pantalla
			if ride.Visible then
				missionLabel.Visible = false
				local want = if missionText ~= "" then missionLabel.Text else ""
				if want ~= "" and not string.find(rideInfo.Text, want, 1, true) or (want == "" and string.find(rideInfo.Text, "📌", 1, true)) then
					layoutRide()
				end
			end
		end
	end)
end

return MetroUI
