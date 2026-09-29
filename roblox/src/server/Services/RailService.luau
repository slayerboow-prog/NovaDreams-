-- RailService: el tren de Cercanías de Valmar (Shared/Rail.luau, World/Kit/RailKit.luau).
--
--   * Un tren de 3 coches va y viene por la línea C1 (Villaverde – Valmar Norte – Los Pinos – Levante –
--     Campus). Para en cada estación con las puertas del lado del andén abiertas y descansa un poco en
--     las cabeceras. Sale y frena como el metro (las mismas cuentas: Shared/Metro).
--   * En el andén: "Subir al tren" (te sientas; si no hay sitio, vas de pie). Hace falta un billete de
--     Cercanías (máquinas rojas del andén) o un abono del metro (vale también en el tren). Los niños y
--     quien va de servicio no pagan. Quien se cuela andando por la puerta paga al revisor (o multa).
--   * En cada estación sale "Bajar en…" (RailUI) o se baja andando por la puerta con el tren parado.
--   * Paneles de salidas en los andenes (RailDisplay) y megafonía a bordo y en el andén.
--   * Nadie se queda en la vía cuando pasa el tren: se le aparta con un aviso.
-- Los clientes mueven el tren (Controllers/MetroTrains) con lo que se publica en ReplicatedStorage.RailState.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Rail = require(ReplicatedStorage.Shared.Rail)
local MetroKit = require(script.Parent.Parent.World.Kit.MetroKit)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local MetroService = require(script.Parent.MetroService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local RailService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Rail :: RemoteEvent
local STEP = Rail.CarLength + Rail.CarGap

type Car = { Root: BasePart, Seats: { Seat }, Doors: { BasePart } }
type Train = {
	Model: Model?,
	Cars: { Car },
	Points: { Vector3 },
	Centers: { number },
	S: number, -- dónde va el centro del tren en el recorrido
	Index: number, -- estación donde está parado (o hacia la que va)
	Dir: number, -- +1 hacia Campus, -1 hacia Villaverde
	Phase: string, -- "Dwell" | "Move"
	Timer: number,
	From: number,
	To: number,
	Duration: number,
	Elapsed: number,
	Passengers: { [Player]: boolean },
	Speed: number,
	DwellTime: number,
	Layover: number,
	T0: number,
	DoorsOpen: boolean,
	Warned: boolean,
	Announced: boolean,
}

local trains: { [string]: Train } = {}
local riding: { [Player]: Train } = {}
local paid: { [Player]: boolean } = {} -- ya ha pagado este viaje (hasta que se baja)
local stateFolder: Folder? = nil -- ReplicatedStorage.RailState: lo que ven los clientes

function RailService._now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and typeof(t) == "number" then t else os.clock()
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function tagged(tag: string): { BasePart }
	local list = {}
	for _, p in CollectionService:GetTagged(tag) do
		if p:IsA("BasePart") then
			table.insert(list, p)
		end
	end
	return list
end

local function findTagged(tag: string, attrs: { [string]: any }): BasePart?
	for _, p in tagged(tag) do
		local ok = true
		for k, v in attrs do
			if p:GetAttribute(k) ~= v then
				ok = false
				break
			end
		end
		if ok then
			return p
		end
	end
	return nil
end

local function teleport(player: Player, cf: CFrame)
	require(script.Parent.VehicleService).standUp(player)
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 5)
	end)
	local character = player.Character
	if character then
		character:PivotTo(cf)
	end
end

local function stationId(_: Train, index: number): string
	return Rail.Line.Stations[index]
end

---------------------------------------------------------------------
-- Tren
---------------------------------------------------------------------

local function placeTrain(train: Train)
	for k, car in train.Cars do
		local offset = (k - (#train.Cars + 1) / 2) * STEP
		local p, t = Rail.sample(train.Points, train.S - offset)
		car.Root.CFrame = CFrame.lookAt(p, p + t) * CFrame.new(0, -0.3, 0)
	end
end

-- ¿En qué coche está este punto? (para saber quién va dentro, aunque sea de pie)
local function carAt(train: Train, position: Vector3): Car?
	for _, car in train.Cars do
		local q = car.Root.CFrame:PointToObjectSpace(position)
		if math.abs(q.X) < Rail.CarWidth / 2 - 0.1 and q.Y > -1 and q.Y < 9 and math.abs(q.Z) < Rail.CarLength / 2 + 1 then
			return car
		end
	end
	return nil
end

local function publish(train: Train)
	local root = stateFolder
	if not root then
		return
	end
	local f = root:FindFirstChild(Rail.Line.Id)
	if not f then
		f = Instance.new("Folder")
		f.Name = Rail.Line.Id
		f.Parent = root
	end
	local now = RailService._now()
	f:SetAttribute("Phase", train.Phase)
	f:SetAttribute("S", train.S)
	f:SetAttribute("From", train.From)
	f:SetAttribute("To", train.To)
	f:SetAttribute("Duration", train.Duration)
	f:SetAttribute("T0", train.T0)
	f:SetAttribute("Speed", train.Speed)
	f:SetAttribute("Index", train.Index)
	f:SetAttribute("Dir", train.Dir)
	f:SetAttribute("DwellEnd", if train.Phase == "Dwell" then now + math.max(0, train.Timer) else 0)
	f:SetAttribute("Doors", train.DoorsOpen)
end

local function playersNear(position: Vector3, range: number): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - position).Magnitude < range then
			table.insert(list, player)
		end
	end
	return list
end

-- Megafonía: a los viajeros del tren y/o a quien espera en el andén
local function announce(train: Train, text: string, toRiders: boolean, platformIndex: number?)
	if toRiders then
		for player in train.Passengers do
			Remote:FireClient(player, "Announce", { Text = text })
		end
	end
	if platformIndex then
		for _, player in playersNear(Rail.center(stationId(train, platformIndex)), 110) do
			if not train.Passengers[player] then
				Remote:FireClient(player, "Announce", { Text = text, Platform = true })
			end
		end
	end
end

-- Solo se abren las puertas del lado del andén
local function setDoors(train: Train, open: boolean)
	local side = if open then Rail.frame(stationId(train, train.Index)).RightVector else nil
	for _, car in train.Cars do
		local facing = if side and side:Dot(car.Root.CFrame.RightVector) < 0 then -1 else 1
		for _, door in car.Doors do
			local opened = open and (side == nil or (door:GetAttribute("Side") or 1) * facing > 0)
			door.Transparency = if opened then 1 else 0
			door.CanCollide = not opened
		end
	end
end

local function freeSeat(train: Train, from: Vector3?): Seat?
	local best, bestD = nil, math.huge
	for _, car in train.Cars do
		for _, seat in car.Seats do
			if not seat.Occupant then
				local d = if from then (seat.Position - from).Magnitude else 0
				if d < bestD then
					best, bestD = seat, d
				end
			end
		end
	end
	return best
end

local function isTrainSeat(train: Train, seat: Instance?): boolean
	if not seat then
		return false
	end
	for _, car in train.Cars do
		if table.find(car.Seats, seat :: any) then
			return true
		end
	end
	return false
end

local function dwellAt(train: Train, index: number): number
	return train.DwellTime + (if index == 1 or index == #train.Centers then train.Layover else 0)
end

local function arrive(train: Train)
	train.Phase = "Dwell"
	local id = stationId(train, train.Index)
	train.Timer = dwellAt(train, train.Index)
	train.S = train.Centers[train.Index]
	train.Warned = false
	train.Announced = false
	train.DoorsOpen = true
	placeTrain(train)
	setDoors(train, true)
	publish(train)
	local nextI = Rail.nextStop(#train.Centers, train.Index, train.Dir)
	for player in train.Passengers do
		Remote:FireClient(player, "Arrive", { Station = Rail.stationName(id), Next = Rail.stationName(stationId(train, nextI)) })
	end
end

local boardWalkIns: (Train) -> ()

local function depart(train: Train)
	boardWalkIns(train)
	local i, dir = Rail.nextStop(#train.Centers, train.Index, train.Dir)
	train.Dir = dir
	train.From = train.S
	train.To = train.Centers[i]
	train.Index = i
	train.Duration = Rail.travelTime(math.abs(train.To - train.From), train.Speed)
	train.Elapsed = 0
	train.T0 = RailService._now()
	train.Phase = "Move"
	train.DoorsOpen = false
	setDoors(train, false)
	publish(train)
	for player in train.Passengers do
		Remote:FireClient(player, "Depart", { Next = Rail.stationName(stationId(train, i)) })
	end
	announce(train, Rail.announceNext(stationId(train, i)), true, nil)
end

local function step(train: Train, dt: number)
	if train.Phase == "Dwell" then
		-- Si algo se ha llevado un coche (un viajero sentado al que otro sistema movió), vuelve a su sitio
		local first = train.Cars[1]
		if first and first.Root.Parent then
			local offset = (1 - (#train.Cars + 1) / 2) * STEP
			local p = Rail.sample(train.Points, train.S - offset)
			if (first.Root.Position - p).Magnitude > 4 then
				placeTrain(train)
			end
		end
		train.Timer -= dt
		if not train.Warned and train.Timer <= 4 then
			train.Warned = true
			announce(train, Rail.AnnounceDoors, true, train.Index)
			Remote:FireAllClients("Doors", { Line = Rail.Line.Id })
		end
		if train.Timer <= 0 then
			depart(train)
		end
		return
	end
	train.Elapsed += dt
	if not train.Announced and train.Duration - train.Elapsed <= 12 then
		train.Announced = true
		local _, toward = Rail.eta(train :: any, train.Index)
		announce(train, Rail.announceArriving(Rail.stationName(stationId(train, toward))), false, train.Index)
	end
	if train.Elapsed >= train.Duration then
		arrive(train)
		return
	end
	local d = Rail.travelled(math.abs(train.To - train.From), train.Elapsed, train.Duration, train.Speed)
	train.S = train.From + (if train.To >= train.From then d else -d)
	placeTrain(train)
end

local function setupTrain(model: Instance)
	if not model:IsA("Model") or model:GetAttribute("Line") ~= Rail.Line.Id or trains[Rail.Line.Id] then
		return
	end
	local cars = {}
	for k = 1, Rail.Cars do
		local carModel = model:FindFirstChild("Car" .. k)
		local root = carModel and carModel:FindFirstChild("Root")
		if carModel and root and root:IsA("BasePart") then
			if carModel:GetAttribute("NeedsWeld") then
				-- Soldar el coche entero a su suelo aquí, con las piezas ya en su sitio (como el metro)
				carModel:SetAttribute("NeedsWeld", nil)
				MetroKit.weldCar(carModel :: Model, root)
			end
			local car: Car = { Root = root, Seats = {}, Doors = {} }
			for _, d in carModel:GetDescendants() do
				if d:IsA("Seat") then
					table.insert(car.Seats, d)
				elseif d:IsA("BasePart") and d:HasTag("RailDoor") then
					d:SetAttribute("Side", if root.CFrame:PointToObjectSpace(d.Position).X > 0 then 1 else -1)
					table.insert(car.Doors, d)
				end
			end
			table.insert(cars, car)
		end
	end
	if #cars == 0 then
		return
	end
	local points, centers = Rail.path()
	local train: Train = {
		Model = model,
		Cars = cars,
		Points = points,
		Centers = centers,
		S = centers[1],
		Index = 1,
		Dir = 1,
		Phase = "Dwell",
		Timer = Rail.Dwell,
		From = 0,
		To = 0,
		Duration = 1,
		Elapsed = 0,
		Passengers = {},
		Speed = Rail.Speed,
		DwellTime = Rail.Dwell,
		Layover = Rail.Layover,
		T0 = RailService._now(),
		DoorsOpen = true,
		Warned = false,
		Announced = false,
	}
	trains[Rail.Line.Id] = train
	arrive(train)
end

---------------------------------------------------------------------
-- Billete: quién viaja gratis, con abono o gastando un billete
---------------------------------------------------------------------

-- ¿Puede viajar sin gastar billete? Devuelve el motivo (o nil)
local function freeRide(player: Player): string?
	if Rail.FreeStages[player:GetAttribute("LifeStage") or ""] then
		return "Gratis"
	end
	local job = player:GetAttribute("Job")
	if typeof(job) == "string" and Rail.FreeJobs[job] then
		return "Servicio"
	end
	local ok, pass = pcall(MetroService.passOf, player)
	if ok and pass then
		return pass.Name
	end
	return nil
end

-- Cobra el viaje (si hace falta). Devuelve si puede viajar
local function payFare(player: Player): boolean
	if paid[player] or freeRide(player) then
		paid[player] = true
		return true
	end
	if InventoryService.count(player, Rail.TicketItem) >= 1 then
		InventoryService.remove(player, Rail.TicketItem, 1)
		paid[player] = true
		return true
	end
	return false
end

---------------------------------------------------------------------
-- Viajeros
---------------------------------------------------------------------

local function stopRiding(player: Player)
	local train = riding[player]
	if train then
		train.Passengers[player] = nil
		riding[player] = nil
	end
	paid[player] = nil
	if player.Parent then
		Remote:FireClient(player, "Off")
	end
end

local function startRide(player: Player, train: Train)
	train.Passengers[player] = true
	riding[player] = train
	local nextI = Rail.nextStop(#train.Centers, train.Index, train.Dir)
	local names = {}
	for _, id in Rail.Line.Stations do
		table.insert(names, Rail.stationName(id))
	end
	Remote:FireClient(player, "Board", {
		Line = Rail.Line.Id,
		LineName = Rail.Line.Name,
		Color = Rail.Line.Color,
		Stations = names,
		Station = Rail.stationName(stationId(train, train.Index)),
		Next = Rail.stationName(stationId(train, if train.Phase == "Dwell" then nextI else train.Index)),
	})
end

local function onBoard(player: Player, marker: BasePart)
	local train = trains[marker:GetAttribute("Line") or ""]
	local humanoid = humanoidOf(player)
	if not train or not humanoid or humanoid.Health <= 0 or riding[player] then
		return
	end
	local here = table.find(Rail.Line.Stations, marker:GetAttribute("Station"))
	if train.Phase ~= "Dwell" or train.Index ~= here or not train.DoorsOpen then
		local seconds = math.floor((Rail.eta(train :: any, here or 1)))
		Notify:FireClient(player, "Info", ("🚆 El tren no está en el andén. Llega en %d s (mira el panel)."):format(seconds))
		return
	end
	if not payFare(player) then
		Notify:FireClient(player, "Info", "🎫 Necesitas un billete de Cercanías (máquina roja del andén) o un abono de metro.")
		return
	end
	local seat = freeSeat(train, marker.Position)
	require(script.Parent.VehicleService).standUp(player) -- (si iba en bici o patinete, se baja antes)
	if seat then
		seat:Sit(humanoid)
	else
		local best, bestD = nil, math.huge
		for _, car in train.Cars do
			local d = (car.Root.Position - marker.Position).Magnitude
			if d < bestD then
				best, bestD = car, d
			end
		end
		if best then
			teleport(player, best.Root.CFrame * CFrame.new(0, 3.5, 0))
			Notify:FireClient(player, "Info", "No quedan asientos libres: vas de pie. Agárrate a la barra 🧍")
		end
	end
	startRide(player, train)
	local free = freeRide(player)
	StoryEvents.emit(player, "TrainBoard", { Station = marker:GetAttribute("Station"), Pass = free or "Billete" })
end

-- Al cerrar las puertas: quien se ha metido andando en un coche viaja (y paga al revisor)
function boardWalkIns(train: Train)
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local humanoid = humanoidOf(player)
		if root and humanoid and (humanoid.Health or 0) > 0 and not riding[player] and carAt(train, root.Position) then
			if not payFare(player) then
				paid[player] = true
				if DataService.spend(player, Rail.Fine) then
					Notify:FireClient(player, "Error", ("🎫 El revisor te ha pillado sin billete: multa de %d €."):format(Rail.Fine))
				else
					Notify:FireClient(player, "Error", "🎫 El revisor te ha pillado sin billete (y no llevas para la multa). ¡Que no se repita!")
				end
			end
			startRide(player, train)
		end
	end
end

local function onAlight(player: Player)
	local train = riding[player]
	if not train or train.Phase ~= "Dwell" or not train.DoorsOpen then
		return
	end
	local id = stationId(train, train.Index)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.Sit = false
	end
	stopRiding(player)
	local spot = findTagged("RailAlight", { Station = id })
	if spot then
		task.defer(function()
			teleport(player, spot.CFrame)
		end)
	end
	StoryEvents.emit(player, "RodeTrain", { Station = id })
end

local function checkPassengers()
	for player, train in riding do
		local humanoid = humanoidOf(player)
		local root = rootOf(player)
		if not player.Parent or not humanoid or humanoid.Health <= 0 or not root then
			stopRiding(player)
		elseif not isTrainSeat(train, humanoid.SeatPart) and not carAt(train, root.Position) then
			if train.Phase == "Dwell" then
				local id = stationId(train, train.Index)
				stopRiding(player)
				StoryEvents.emit(player, "RodeTrain", { Station = id })
			elseif (root.Position - train.Cars[1].Root.Position).Magnitude > 200 then
				stopRiding(player)
			end
		end
	end
end

-- Nadie en la vía cuando pasa el tren: quien está delante (o debajo) se aparta a un lado, con un aviso
local function guardTracks()
	local train = trains[Rail.Line.Id]
	if not train then
		return
	end
	local half = Rail.halfTrain()
	local ahead = if train.Phase == "Move" then 40 else 4
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = rootOf(player)
		local humanoid = humanoidOf(player)
		if character and root and humanoid and (humanoid.Health or 100) > 0 and not humanoid.SeatPart and not riding[player] then
			local p = root.Position
			if p.Y > -3 and p.Y < Rail.Deck + 7 then
				local d, s = Rail.distance(p)
				local rel = (s - train.S) * (if train.Phase == "Move" and train.To < train.From then -1 else 1)
				local inFront = math.abs(s - train.S) < half + 2 or (train.Phase == "Move" and rel > 0 and rel < half + ahead)
				if d < Rail.CarWidth / 2 + 0.6 and inFront and not carAt(train, p) then
					local q, t = Rail.sample(train.Points, s)
					local n = Vector3.new(-t.Z, 0, t.X)
					local side = if (Vector3.new(p.X - q.X, 0, p.Z - q.Z)):Dot(n) >= 0 then 1 else -1
					local to = Vector3.new(q.X, 3.5, q.Z) + n * side * (Rail.Clearance + 2)
					root.AssemblyLinearVelocity = Vector3.zero
					character:PivotTo(CFrame.new(to))
					Notify:FireClient(player, "Error", "⚠️ ¡Cuidado con el tren! No te quedes en la vía.")
				end
			end
		end
	end
end

-- Paneles de salidas de los andenes
local function updateDisplays()
	for _, display in tagged("RailDisplay") do
		local train = trains[display:GetAttribute("Line") or ""]
		local index = table.find(Rail.Line.Stations, display:GetAttribute("Station"))
		if train and index then
			local seconds, toward = Rail.eta(train :: any, index)
			local text = Rail.boardText(seconds, toward, if train.Phase == "Dwell" then train.Timer else nil)
			for _, label in display:GetDescendants() do
				if label:IsA("TextLabel") and label.Text ~= text then
					label.Text = text
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Billetes
---------------------------------------------------------------------
local function nearMachine(player: Player): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	for _, m in tagged("RailTicketMachine") do
		if (m.Position - root.Position).Magnitude < 14 then
			return true
		end
	end
	return false
end

local function openTickets(player: Player)
	local free = freeRide(player)
	Remote:FireClient(player, "Tickets", Rail.Tickets, { Free = free, Have = InventoryService.count(player, Rail.TicketItem) })
end

local function onBuyTicket(player: Player, id: any)
	if not nearMachine(player) then
		return
	end
	for _, t in Rail.Tickets do
		if t.Id == id then
			if not InventoryService.canAdd(player, Rail.TicketItem, t.Count) then
				Notify:FireClient(player, "Error", "No te caben más billetes en la mochila.")
				return
			end
			if not DataService.spend(player, t.Price) then
				Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
				return
			end
			InventoryService.add(player, Rail.TicketItem, t.Count)
			Notify:FireClient(player, "Success", ("🎫 %s comprado. Se gasta al subir al tren."):format(t.Name))
			StoryEvents.emit(player, "BoughtItem", { ShopId = "Cercanias", ItemId = t.Id })
			return
		end
	end
end

---------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------
local function prompt(parent: BasePart, action: string, object: string, hold: number, distance: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = distance or 9
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local SETUP: { [string]: (BasePart) -> () } = {
	RailBoard = function(marker)
		prompt(marker, "Subir al tren", "🚆 " .. Rail.Line.Name, 0.2, 8).Triggered:Connect(function(player)
			onBoard(player, marker)
		end)
	end,
	RailTicketMachine = function(machine)
		prompt(machine, "Comprar billete", "🎫 Máquina de billetes · Cercanías", 0.3, 8).Triggered:Connect(openTickets)
	end,
}

function RailService.init()
	stateFolder = ReplicatedStorage:FindFirstChild("RailState") :: Folder?
	if not stateFolder then
		local f = Instance.new("Folder")
		f.Name = "RailState"
		pcall(function()
			f.Parent = ReplicatedStorage
		end)
		stateFolder = f
	end
	for tag, fn in SETUP do
		for _, p in tagged(tag) do
			fn(p)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(p)
			if p:IsA("BasePart") then
				fn(p)
			end
		end)
	end
	for _, model in CollectionService:GetTagged("RailTrain") do
		setupTrain(model)
	end
	CollectionService:GetInstanceAddedSignal("RailTrain"):Connect(setupTrain)

	Remote.OnServerEvent:Connect(function(player, action, a)
		if action == "Alight" then
			onAlight(player)
		elseif action == "BuyTicket" then
			onBuyTicket(player, a)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		stopRiding(player)
	end)

	RunService.Heartbeat:Connect(function(dt)
		for _, train in trains do
			local ok, err = pcall(step, train, dt)
			if not ok then
				warn("[RailService] " .. tostring(err))
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(function()
				checkPassengers()
				guardTracks()
				updateDisplays()
			end)
			if not ok then
				warn("[RailService] " .. tostring(err))
			end
		end
	end)
end

-- Para las pruebas
RailService._trains = trains
RailService._riding = riding
RailService._step = step
RailService._guardTracks = guardTracks
RailService._checkPassengers = checkPassengers
RailService._updateDisplays = updateDisplays

return RailService
