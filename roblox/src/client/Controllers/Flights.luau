-- Flights (cliente): los aviones del Aeropuerto de Valmar, fluidos y a la vez en todas las pantallas.
--   * El servidor publica el estado de cada avión en ReplicatedStorage.FlightState.<avión> (fase,
--     ruta y hora de salida). Aquí se calcula con Shared/Airport.pose dónde va el avión en cada
--     fotograma (el mismo cálculo que el servidor: todos lo ven en el mismo sitio).
--   * En el avión: panel del vuelo (de dónde a dónde, qué está haciendo y cuánto falta), cámara
--     de cine por fuera del avión, vista por la ventanilla o la cámara normal (botón 🎥), y antes
--     de despegar, el botón para bajarse.
--   * Megafonía del aeropuerto: gong, voz y subtítulo.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Airport = require(ReplicatedStorage.Shared.Airport)
local Theme = require(script.Parent.Parent.UI.Theme)
local SoundFx = require(script.Parent.SoundFx)
local CineCamera = require(script.Parent.CineCamera)

local Flights = {}

local player = Players.LocalPlayer
local roots: { [string]: BasePart } = {} -- avión -> su pieza Root
local riding: { [string]: any }? = nil -- datos del vuelo en el que vas
local cameraMode = "Exterior" -- "Exterior" | "Ventanilla" | "Normal"
local MODES = { "Exterior", "Ventanilla", "Normal" }
local MODE_TEXT = { Exterior = "🎥 Cámara: exterior", Ventanilla = "🪟 Cámara: ventanilla", Normal = "🎮 Cámara: normal" }
local orbit = 0
local savedCamera: CFrame? = nil
local panel: Frame? = nil
local title: TextLabel? = nil
local status: TextLabel? = nil
local bar: Frame? = nil
local camButton: TextButton? = nil
local leaveButton: TextButton? = nil
local subtitle: TextLabel? = nil
local subtitleUntil = 0

local function now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok then t else os.clock()
end

local function collect(model: Instance)
	local id = model:GetAttribute("PlaneId")
	if typeof(id) ~= "string" then
		return
	end
	local root = model:FindFirstChild("Root")
	if root and root:IsA("BasePart") then
		roots[id] = root
	end
end

local function refresh()
	for _, model in CollectionService:GetTagged("Plane") do
		collect(model)
	end
end

-- Estado publicado por el servidor: ruta, fase y cuánto lleva de vuelo
local function stateOf(id: string): (Airport.Route?, string?, number)
	local root = ReplicatedStorage:FindFirstChild("FlightState")
	local f = root and root:FindFirstChild(id)
	if not f then
		return nil, nil, 0
	end
	local route = Airport.Routes[f:GetAttribute("Route") or ""]
	local phase = f:GetAttribute("Phase")
	local t0 = f:GetAttribute("T0") or 0
	return route, phase, if phase == "Flight" and route then math.clamp(now() - t0, 0, route.Total) else 0
end

---------------------------------------------------------------------
-- Cámara del vuelo
---------------------------------------------------------------------
local function setCamera(root: BasePart, dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if cameraMode == "Normal" then
		if camera.CameraType == Enum.CameraType.Scriptable then
			CineCamera.restore(nil)
		end
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local cf = root.CFrame
	local big = riding and riding.Kind == "Avion"
	if cameraMode == "Exterior" then
		-- Plano de cine: la cámara gira despacio alrededor del avión (sin inclinarse con él)
		orbit += dt * 0.15
		local look = cf.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		local dist = if big then 70 else 36
		local offset = CFrame.Angles(0, yaw + orbit, 0) * Vector3.new(0, if big then 16 else 9, dist)
		local focus = cf.Position + Vector3.new(0, if big then 4 else 2, 0)
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
	else
		-- Ventanilla: desde tu asiento, mirando por el lado de la ventana
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local base = if seat then seat.CFrame else cf
		local side = if seat and cf:PointToObjectSpace(seat.Position).X > 0 then -1 else 1
		camera.CFrame = base * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, math.rad(75) * side, 0) * CFrame.Angles(math.rad(-12), 0, 0)
	end
end

---------------------------------------------------------------------
-- Cada fotograma: coloca los aviones (y la cámara si vas volando)
---------------------------------------------------------------------
local function update(dt: number)
	local parts, cframes = {}, {}
	for _, spec in Airport.Planes do
		local root = roots[spec.Id]
		local route, phase, t = stateOf(spec.Id)
		if root and root.Parent and route and phase then
			local pose = if phase == "Flight" then (Airport.pose(route, t)) else Airport.parkPose(route)
			table.insert(parts, root)
			table.insert(cframes, Airport.rootCFrame(spec.Kind, pose))
		end
	end
	if #parts > 0 then
		local ok = pcall(function()
			workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end)
		if not ok then
			for i, p in parts do
				p.CFrame = cframes[i]
			end
		end
	end
	local ride = riding
	if ride then
		local root = roots[ride.Plane]
		if root then
			setCamera(root, dt)
		end
	end
end

---------------------------------------------------------------------
-- Panel del vuelo
---------------------------------------------------------------------
local function refreshPanel()
	local ride = riding
	if not ride or not panel then
		return
	end
	local route, phase, t = stateOf(ride.Plane)
	if not route then
		return
	end
	if status and bar then
		if phase == "Flight" then
			local _, legPhase = Airport.pose(route, t)
			local left = route.Total - t
			status.Text = ("%s · llegamos en %s"):format(Airport.PhaseText[legPhase] or legPhase, Airport.duration(left))
			bar.Size = UDim2.fromScale(math.clamp(t / route.Total, 0, 1), 1)
		else
			local root = ReplicatedStorage:FindFirstChild("FlightState")
			local f = root and root:FindFirstChild(ride.Plane)
			local boardEnd = f and f:GetAttribute("BoardEnd") or now()
			status.Text = ("Embarque · despegamos en %s. ¡Abróchate el cinturón!"):format(Airport.duration(boardEnd - now()))
			bar.Size = UDim2.fromScale(0, 1)
		end
	end
	if leaveButton then
		leaveButton.Visible = phase ~= "Flight"
	end
end

local function showPanel(data: { [string]: any }?)
	if panel then
		panel.Visible = data ~= nil
	end
	if data and title then
		title.Text = ("✈️ %s · %s → %s"):format(data.Plane, data.From, data.To)
	end
	if camButton then
		camButton.Text = MODE_TEXT[cameraMode]
	end
end

local function buildPanel(gui: ScreenGui)
	local frame = Theme.panel({
		Name = "Flight",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(420, 112),
		Visible = false,
		Parent = gui,
	})
	panel = frame
	title = Theme.title({ Name = "Title", Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 24), TextSize = 18, Text = "", Parent = frame })
	status = Theme.label({ Name = "Status", Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 20), TextSize = 15, Text = "", Parent = frame })
	local track = Theme.create("Frame", { Name = "Track", Position = UDim2.fromOffset(14, 58), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = Color3.fromRGB(30, 40, 60), BorderSizePixel = 0, Parent = frame }, { Theme.corner(3) })
	bar = Theme.create("Frame", { Name = "Bar", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 190, 255), BorderSizePixel = 0, Parent = track }, { Theme.corner(3) })
	local cam = Theme.button({ Name = "Camera", Position = UDim2.fromOffset(14, 72), Size = UDim2.fromOffset(190, 32), TextSize = 14, Text = MODE_TEXT[cameraMode], Parent = frame })
	camButton = cam
	cam.Activated:Connect(function()
		local i = table.find(MODES, cameraMode) or 1
		cameraMode = MODES[i % #MODES + 1]
		cam.Text = MODE_TEXT[cameraMode]
		if cameraMode == "Normal" then
			CineCamera.restore(savedCamera)
		end
	end)
	local leave = Theme.button({ Name = "Leave", Position = UDim2.new(1, -164, 0, 72), Size = UDim2.fromOffset(150, 32), TextSize = 14, Text = "🚪 Bajar del avión", Parent = frame })
	leaveButton = leave
	leave.Activated:Connect(function()
		local remote = ReplicatedStorage:FindFirstChild("Remotes")
		local flight = remote and remote:FindFirstChild("Flight")
		if flight then
			(flight :: RemoteEvent):FireServer("Leave")
		end
	end)
	subtitle = Theme.label({
		Name = "Subtitle",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -250),
		Size = UDim2.fromOffset(620, 30),
		Text = "",
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		Visible = false,
		Parent = gui,
	})
end

local function startRide(data: { [string]: any })
	riding = data
	orbit = 0
	cameraMode = "Exterior"
	local camera = workspace.CurrentCamera
	savedCamera = camera and camera.CFrame
	CineCamera.quietLabels("Flight", true)
	showPanel(data)
	refreshPanel()
end

local function stopRide()
	if not riding then
		return
	end
	riding = nil
	showPanel(nil)
	CineCamera.quietLabels("Flight", false)
	CineCamera.restore(nil)
end

local function onAnnounce(data: { [string]: any })
	if typeof(data) ~= "table" or typeof(data.Text) ~= "string" then
		return
	end
	SoundFx.play("MetroGong")
	task.delay(0.6, function()
		SoundFx.voice(data.Text, 1.05, 0.9)
	end)
	local label = subtitle
	if label then
		label.Text = "🔊 " .. data.Text
		label.Visible = true
		subtitleUntil = os.clock() + math.clamp(#data.Text * 0.07 + 2, 3, 9)
	end
end

function Flights.init()
	refresh()
	CollectionService:GetInstanceAddedSignal("Plane"):Connect(collect)
	-- (con la carga por zonas los aviones pueden llegar más tarde: se vuelven a buscar de vez en cuando)
	task.spawn(function()
		while true do
			task.wait(3)
			refresh()
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "Flights"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")
	Theme.fit(gui)
	buildPanel(gui)

	local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Flight") :: RemoteEvent
	Remote.OnClientEvent:Connect(function(action, data)
		if action == "Board" and typeof(data) == "table" then
			startRide(data)
		elseif action == "Off" then
			stopRide()
		elseif action == "Takeoff" then
			refreshPanel()
		elseif action == "Announce" then
			onAnnounce(data)
		end
	end)
	player.CharacterAdded:Connect(function()
		stopRide()
	end)

	local warned = false
	local function safeUpdate(dt: number)
		local ok, err = pcall(update, dt)
		if not ok and not warned then
			warned = true
			warn("[Flights] " .. tostring(err))
		end
	end
	-- Antes de pintar (fluido aunque llegue la posición del servidor) y antes de la física
	RunService.PreRender:Connect(safeUpdate)
	RunService.PreSimulation:Connect(function()
		safeUpdate(0)
	end)
	local clock = 0
	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		if clock >= 0.5 then
			clock = 0
			refreshPanel()
		end
		local label = subtitle
		if label and label.Visible and os.clock() > subtitleUntil then
			label.Visible = false
		end
	end)
end

return Flights
