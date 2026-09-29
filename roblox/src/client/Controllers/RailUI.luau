-- RailUI (cliente): el tren de Cercanías de Valmar (Shared/Rail).
--   * En el tren: panel arriba con la línea y las estaciones (✓ pasadas, ● aquí, ○ próximas) y, con el
--     tren parado, el botón "Bajar en…".
--   * Máquina de billetes del andén: billete sencillo o bono de 10 viajes.
--   * Pasos a nivel (tag RailCrossing): las barreras bajan y las luces rojas parpadean cuando llega el
--     tren (se calcula aquí, con el estado del tren que publica el servidor en RailState: sin red), y los
--     coches del tráfico esperan (Controllers/Traffic).
--   * La primera vez que llegas a un andén en cada partida, cómo se viaja.
-- (El tren se mueve en Controllers/MetroTrains; la megafonía y los sonidos también van allí.)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local Format = require(ReplicatedStorage.Shared.Format)
local Rail = require(ReplicatedStorage.Shared.Rail)
local Traffic = require(script.Parent.Traffic)

local RailUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local Remote: RemoteEvent? = nil
local ride: Frame
local rideTitle: TextLabel
local rideStrip: TextLabel
local alightButton: TextButton
local rideInfo: { [string]: any }? = nil

local ACTIVE_RANGE = 450 -- solo se animan los pasos a nivel que tienes cerca
local ARM_SPEED = 55 -- grados por segundo
local LIGHT_ON = rgb(255, 40, 30)
local LIGHT_OFF = rgb(90, 20, 20)

local function now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then t else os.clock()
end

---------------------------------------------------------------------
-- En el tren
---------------------------------------------------------------------
local function drawStrip(current: string?, nextName: string?)
	local info = rideInfo
	if not info then
		return
	end
	local here = current and table.find(info.Stations, current)
	local after = nextName and table.find(info.Stations, nextName)
	local dir = if here and after then (if after > here then 1 else -1) elseif after and info.Last then (if after > info.Last then 1 else -1) else 1
	if here then
		info.Last = here
	end
	local parts = {}
	for i, name in info.Stations do
		local passed = info.Last ~= nil and i ~= here and (if dir > 0 then i < info.Last else i > info.Last)
		local mark = if i == here then "●" elseif passed then "✓" else "○"
		local text = mark .. " " .. name
		if i == here then
			text = "<b>" .. text .. "</b>"
		elseif i == after then
			text = '<font color="#FFD24A">' .. text .. "</font>"
		end
		table.insert(parts, text)
	end
	rideStrip.Text = table.concat(parts, "  —  ")
end

local function onBoard(data: { [string]: any })
	rideInfo = { Stations = data.Stations, LineName = data.LineName, Last = nil }
	ride.Visible = true
	rideTitle.Text = ("🚆 %s · próxima: <b>%s</b>"):format(data.LineName, data.Next)
	drawStrip(data.Station, data.Next)
	alightButton.Visible = true
	alightButton.Text = "Bajar en " .. tostring(data.Station)
end

local function onArrive(data: { [string]: any })
	local info = rideInfo
	if not info then
		return
	end
	rideTitle.Text = ("🚆 %s · <b>%s</b> · puertas abiertas"):format(info.LineName, data.Station)
	drawStrip(data.Station, data.Next)
	alightButton.Visible = true
	alightButton.Text = "Bajar en " .. tostring(data.Station)
end

local function onDepart(data: { [string]: any })
	local info = rideInfo
	if not info then
		return
	end
	rideTitle.Text = ("🚆 %s · próxima: <b>%s</b>"):format(info.LineName, data.Next)
	drawStrip(nil, data.Next)
	alightButton.Visible = false
end

local function onOff()
	rideInfo = nil
	ride.Visible = false
end

---------------------------------------------------------------------
-- Billetes
---------------------------------------------------------------------
local function openTickets(tickets: { any }, extra: { [string]: any }?)
	local rows = {}
	if extra and extra.Free then
		table.insert(rows, { Title = ("✅ <b>Viajas sin billete</b> · %s"):format(tostring(extra.Free)), Sub = "Pulsa «Subir al tren» en el andén cuando llegue." })
	end
	if extra and typeof(extra.Have) == "number" and extra.Have > 0 then
		table.insert(rows, { Title = ("🎫 Tienes <b>%d</b> %s"):format(extra.Have, if extra.Have == 1 then "billete" else "billetes"), Sub = "Se gasta uno al subir al tren." })
	end
	for _, t in tickets do
		table.insert(rows, {
			Title = ("%s <b>%s</b> · %s"):format(t.Icon, t.Name, Format.money(t.Price)),
			Sub = if t.Count > 1 then ("%d viajes en el tren de Cercanías"):format(t.Count) else "Un viaje: se gasta al subir al tren",
			Button = "Comprar",
			Action = function()
				local remote = Remote
				if remote then
					remote:FireServer("BuyTicket", t.Id)
				end
			end,
		})
	end
	table.insert(rows, { Title = "🚇 <b>¿Tienes abono de metro?</b>", Sub = "También vale en Cercanías: subes sin billete." })
	local window, content, close = Dialog.window("RailTickets", "🎫 Billetes de Cercanías", Vector2.new(460, math.min(110 + #rows * 70, 470)))
	local list = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	for i, r in rows do
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = rgb(20, 32, 56), BackgroundTransparency = 0.2, LayoutOrder = i, Parent = list }, { Theme.corner(10) })
		local wide = if r.Button then -140 else -20
		Theme.label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, wide, 0, 26), Text = r.Title, RichText = true, TextSize = 15, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, wide, 0, 28), Text = r.Sub or "", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = row })
		if r.Button then
			local b = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(110, 40), Text = r.Button, TextSize = 14, BackgroundColor3 = Rail.Line.Color, Parent = row })
			b.Activated:Connect(r.Action)
		end
	end
	close.Activated:Connect(function()
		window:Destroy()
	end)
end

---------------------------------------------------------------------
-- Pasos a nivel: barreras, luces y tráfico
---------------------------------------------------------------------
type Arm = { Hinge: CFrame, Parts: { { Part: BasePart, Local: CFrame } } }
type CrossingData = { Model: Instance, S: number, Center: Vector3, Stop: number, Arms: { Arm }, Lights: { BasePart }, Angle: number, Closed: boolean }
local crossings: { [Instance]: CrossingData } = {}

local function collectCrossing(model: Instance)
	local s = model:GetAttribute("S")
	local center = model:GetAttribute("Center")
	if typeof(s) ~= "number" or typeof(center) ~= "Vector3" then
		return
	end
	local data: CrossingData = { Model = model, S = s, Center = center, Stop = model:GetAttribute("Stop") or 12, Arms = {}, Lights = {}, Angle = 88, Closed = false }
	for _, d in model:GetDescendants() do
		if d:IsA("Model") and d.Name == "Barrera" then
			local hinge = d:GetAttribute("Hinge")
			if typeof(hinge) == "CFrame" then
				local arm: Arm = { Hinge = hinge, Parts = {} }
				for _, p in d:GetChildren() do
					local rel = p:GetAttribute("Local")
					if p:IsA("BasePart") and typeof(rel) == "CFrame" then
						table.insert(arm.Parts, { Part = p, Local = rel })
					end
				end
				table.insert(data.Arms, arm)
			end
		elseif d:IsA("BasePart") and d.Name == "CrossingLight" then
			table.insert(data.Lights, d)
		end
	end
	crossings[model] = data
end

local function refreshCrossings()
	for model in crossings do
		if not model.Parent then
			crossings[model] = nil
		end
	end
	for _, model in CollectionService:GetTagged("RailCrossing") do
		-- (con la carga por zonas llegan poco a poco: se vuelven a mirar si les faltaban piezas)
		local known = crossings[model]
		if not known or #known.Arms == 0 then
			collectCrossing(model)
		end
	end
end

local function trainState(): { [string]: any }?
	local root = ReplicatedStorage:FindFirstChild("RailState")
	local f = root and root:FindFirstChild(Rail.Line.Id)
	local phase = f and f:GetAttribute("Phase")
	if not f or not phase then
		return nil
	end
	return {
		Phase = phase,
		S = f:GetAttribute("S") or 0,
		From = f:GetAttribute("From") or 0,
		To = f:GetAttribute("To") or 0,
		Duration = f:GetAttribute("Duration") or 1,
		T0 = f:GetAttribute("T0") or 0,
		Speed = f:GetAttribute("Speed"),
		DwellEnd = f:GetAttribute("DwellEnd") or 0,
	}
end

local function updateCrossings(dt: number)
	local state = trainState()
	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local t = now()
	local blink = math.floor(os.clock() * 2) % 2 == 0
	local stops = {}
	for _, c in crossings do
		local closed = state ~= nil and Rail.crossingClosed(state, c.S, t)
		if closed then
			table.insert(stops, { Pos = c.Center, Stop = c.Stop })
		end
		if (c.Center - eye).Magnitude < ACTIVE_RANGE then
			local target = if closed then 0 else 88
			if c.Angle ~= target then
				local stepAngle = ARM_SPEED * dt
				c.Angle = if c.Angle < target then math.min(target, c.Angle + stepAngle) else math.max(target, c.Angle - stepAngle)
				for _, arm in c.Arms do
					local pivot = arm.Hinge * CFrame.Angles(math.rad(c.Angle), 0, 0)
					for _, item in arm.Parts do
						if item.Part.Parent then
							item.Part.CFrame = pivot * item.Local
						end
					end
				end
			end
			-- Luces: parpadean de dos en dos mientras está cerrado
			if closed ~= c.Closed or closed then
				for _, light in c.Lights do
					local on = closed and ((light:GetAttribute("Pair") == 1) == blink)
					light.Color = if on then LIGHT_ON else LIGHT_OFF
					light.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
				end
			end
		end
		c.Closed = closed
	end
	pcall(Traffic.setRailStops, stops)
end

---------------------------------------------------------------------

function RailUI.init()
	local gui = create("ScreenGui", { Name = "RailGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	ride = Theme.panel({
		Name = "RailRide",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(620, 74),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = ride
	rideTitle = Theme.label({ Size = UDim2.new(1, 0, 0, 24), Text = "", RichText = true, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Parent = ride })
	rideStrip = Theme.label({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 24), Text = "", RichText = true, TextSize = 13, TextWrapped = true, TextColor3 = C.Muted, Parent = ride })
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
		local remote = Remote
		if remote then
			remote:FireServer("Alight")
		end
	end)

	refreshCrossings()
	CollectionService:GetInstanceAddedSignal("RailCrossing"):Connect(collectCrossing)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.05 then
			return
		end
		local ok, err = pcall(updateCrossings, acc)
		acc = 0
		if not ok then
			warn("[RailUI] " .. tostring(err))
		end
	end)

	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local remote = remotes:WaitForChild("Rail", 30) :: RemoteEvent?
		if not remote then
			return
		end
		Remote = remote
		remote.OnClientEvent:Connect(function(action, data, extra)
			if action == "Board" then
				onBoard(data)
			elseif action == "Arrive" then
				onArrive(data)
			elseif action == "Depart" then
				onDepart(data)
			elseif action == "Off" then
				onOff()
			elseif action == "Tickets" then
				openTickets(data, extra)
			end
		end)
	end)

	-- La primera vez que llegas a un andén en cada partida: cómo se viaja
	task.spawn(function()
		local told = false
		while true do
			task.wait(2)
			refreshCrossings()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and not told then
				for id in Rail.Stations do
					local p = Rail.center(id)
					if (Vector3.new(p.X, 0, p.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude < 60 then
						told = true
						local ticket = if Rail.FreeStages[player:GetAttribute("LifeStage") or ""] then "Los niños viajan gratis." else "Compra el billete en la máquina roja del andén (el abono del metro también vale)."
						Hud.toast("Info", "🚆 Cercanías de Valmar: " .. ticket .. " Mira el panel de salidas y pulsa «Subir al tren» cuando llegue. Para bajar: «Bajar en…».")
						break
					end
				end
			end
		end
	end)
end

return RailUI
