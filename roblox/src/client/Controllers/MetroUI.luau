-- MetroUI (cliente): el metro subterráneo.
--   * En el tren: panel arriba con la línea, las estaciones y la próxima; en cada parada, "Bajar aquí".
--   * Máquinas de billetes, tiendas, tablón de encargos (y el encargo que llevas, con su tiempo).
--   * Fotomatón (flash) y escenario: minijuego de guitarra (pulsa cuando la marca está en verde).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Format = require(ReplicatedStorage.Shared.Format)

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
local alightButton: TextButton
local missionLabel: TextLabel
local flash: Frame
local lineInfo: { [string]: any }? = nil
local missionDeadline: number? = nil
local missionText = ""

---------------------------------------------------------------------
-- En el tren
---------------------------------------------------------------------
local function drawStrip(current: string?, nextName: string?)
	for _, child in rideStrip:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local info = lineInfo
	if not info then
		return
	end
	for i, name in info.Stations do
		local isHere = name == current
		local isNext = name == nextName
		local cell = create("Frame", { Size = UDim2.new(1 / #info.Stations, -4, 1, 0), BackgroundTransparency = 1, LayoutOrder = i, Parent = rideStrip })
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.fromOffset(if isHere or isNext then 16 else 12, if isHere or isNext then 16 else 12),
			BackgroundColor3 = if isHere then Color3.new(1, 1, 1) elseif isNext then C.Gold else info.Color,
			Parent = cell,
		}, { Theme.corner(8) })
		Theme.label({
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, 0, 0, 16),
			Text = name,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if isHere then Color3.new(1, 1, 1) elseif isNext then C.Gold else C.Muted,
			Font = if isHere or isNext then Theme.FontBold else Theme.Font,
			Parent = cell,
		})
	end
end

local function onBoard(data: { [string]: any })
	lineInfo = data
	ride.Visible = true
	ride.BackgroundColor3 = C.Panel
	rideTitle.Text = ("🚇 %s · próxima: <b>%s</b>"):format(data.LineName, data.Next)
	drawStrip(data.Station, data.Next)
	alightButton.Visible = true
	alightButton.Text = "Bajar en " .. data.Station
end

local function onArrive(data: { [string]: any })
	if not lineInfo then
		return
	end
	rideTitle.Text = ("🚇 %s · <b>%s</b> (puertas abiertas)"):format(lineInfo.LineName, data.Station)
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
	ride.Visible = false
end

---------------------------------------------------------------------
-- Menús (billetes, tiendas, encargos)
---------------------------------------------------------------------
local function listWindow(name: string, title: string, rows: { any }, height: number?)
	local window, content, close = Dialog.window(name, title, Vector2.new(460, height or (110 + #rows * 70)))
	local layout = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
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

local function openTickets(tickets: { any })
	local rows = {}
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
	listWindow("MetroTickets", "🎫 Billetes de metro", rows)
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

function MetroUI.init()
	gui = create("ScreenGui", { Name = "MetroGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	ride = Theme.panel({
		Name = "Ride",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(560, 104),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = ride
	rideTitle = Theme.label({ Size = UDim2.new(1, 0, 0, 24), Text = "", RichText = true, TextSize = 16, Parent = ride })
	rideStrip = create("Frame", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = ride })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = rideStrip })
	alightButton = Theme.button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 6),
		Size = UDim2.fromOffset(230, 42),
		Text = "Bajar aquí",
		TextSize = 16,
		BackgroundColor3 = rgb(40, 170, 80),
		Visible = false,
		Parent = ride,
	})
	alightButton.Activated:Connect(function()
		Remote:FireServer("Alight")
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

	Remote.OnClientEvent:Connect(function(action, data)
		if action == "Board" then
			onBoard(data)
		elseif action == "Arrive" then
			onArrive(data)
		elseif action == "Depart" then
			onDepart(data)
		elseif action == "Off" then
			onOff()
		elseif action == "Tickets" then
			openTickets(data)
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
				missionDeadline = nil
				missionLabel.Visible = false
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
	task.spawn(function()
		while true do
			task.wait(0.5)
			if missionLabel.Visible then
				local left = if missionDeadline then math.max(0, math.floor(missionDeadline - os.clock())) else nil
				missionLabel.Text = "📌 " .. missionText .. (if left then ("  ⏱️ %d:%02d"):format(left // 60, left % 60) else "")
			end
		end
	end)
end

return MetroUI
