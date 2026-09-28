-- MetroService: el metro subterráneo de Valmar (Shared/Metro.luau, World/Kit/MetroKit.luau).
--
-- VIAJAR
--   * Boca de metro junto a la acera: se baja ANDANDO por las escaleras hasta el vestíbulo y de ahí
--     por las escaleras mecánicas (llevan solas: son cintas, tag MetroEscalator) hasta los andenes.
--     El ascensor de la boca ("Bajar en ascensor") y el del vestíbulo de andenes ("Subir en ascensor")
--     son el único atajo.
--   * Máquinas de billetes: billete sencillo o bonometro. El torno gasta un billete para pasar al andén.
--   * Los trenes van y vienen solos por cada línea (paran en todas las estaciones con las puertas
--     abiertas unos segundos). En el andén, "Subir al metro" y te sientas. En cada estación sale
--     "Bajar aquí" (o salta con el tren parado). En Plaza Mayor se hace transbordo entre líneas.
--
-- EL SUBMUNDO (galería de Plaza Mayor y vestíbulos)
--   * Tiendas (quiosco, cafetería, bocatería, tienda de discos, máquinas), fotomatón.
--   * Escenario: con una guitarra, "Tocar música" (minijuego) y la gente te deja propinas.
--   * Tablón de encargos: objeto perdido (búscalo y llévalo a Objetos Perdidos), paquete urgente
--     (llévalo al quiosco de otra estación a tiempo) y el gato del metro (encuéntralo y tráelo).
--   * Revisor/a (oficio): pide el billete a los viajeros; los que no lo tienen, multa.
-- Viajeros NPC esperan en los andenes, bajan de los trenes y pasean por la galería.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Metro = require(ReplicatedStorage.Shared.Metro)
local Items = require(ReplicatedStorage.Shared.Items)
local Format = require(ReplicatedStorage.Shared.Format)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local InventoryService = require(script.Parent.InventoryService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local MetroService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Metro :: RemoteEvent
local REV = Metro.Revisor
local STEP = Metro.CarLength + Metro.CarGap

type Car = { Root: BasePart, Seats: { Seat }, Doors: { BasePart } }
type Train = {
	Line: Metro.Line,
	Model: Model?,
	Cars: { Car },
	Points: { Vector3 },
	Centers: { number },
	S: number, -- dónde va el centro del tren en el recorrido
	Index: number, -- estación donde está parado (o de donde salió)
	Dir: number, -- +1 hacia el final de la línea, -1 hacia el principio
	Phase: string, -- "Dwell" | "Move"
	Timer: number,
	From: number,
	To: number,
	Duration: number,
	Elapsed: number,
	Passengers: { [Player]: boolean },
}

local trains: { [string]: Train } = {}
local riding: { [Player]: Train } = {}
local lastBusk: { [Player]: number } = {}
local busking: { [Player]: { Token: number, Started: number } } = {}
local missions: { [Player]: { [string]: any } } = {}
local onDuty: { [Player]: boolean } = {}
local nextToken = 0

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
	-- Primero se baja del vehículo (si no, se lo llevaría con él). (require aquí dentro: así no hay
	-- requires en círculo)
	require(script.Parent.VehicleService).standUp(player)
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 5)
	end)
	local character = player.Character
	if character then
		character:PivotTo(cf)
	end
end

local function stationName(id: string): string
	return Metro.Stations[id].Name
end

---------------------------------------------------------------------
-- Trenes
---------------------------------------------------------------------

local function placeTrain(train: Train)
	for k, car in train.Cars do
		local offset = (k - (#train.Cars + 1) / 2) * STEP
		local p, t = Metro.sample(train.Points, train.S - offset)
		car.Root.CFrame = CFrame.lookAt(p, p + t) * CFrame.new(0, -0.3, 0)
	end
end

local function setDoors(train: Train, open: boolean)
	for _, car in train.Cars do
		for _, door in car.Doors do
			door.Transparency = if open then 1 else 0
			door.CanCollide = not open
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

local function nextIndex(train: Train): (number, number)
	return Metro.nextStop(#train.Line.Stations, train.Index, train.Dir)
end

local function eta(train: Train, index: number): number
	return math.floor((Metro.eta(train, index)))
end

local function arrive(train: Train)
	train.Phase = "Dwell"
	train.Timer = Metro.Dwell
	train.S = train.Centers[train.Index]
	placeTrain(train)
	setDoors(train, true)
	local id = train.Line.Stations[train.Index]
	local nextI = nextIndex(train)
	for player in train.Passengers do
		Remote:FireClient(player, "Arrive", { Line = train.Line.Id, Station = stationName(id), Next = stationName(train.Line.Stations[nextI]) })
		if missions[player] then
			missions[player].Rode = true
		end
	end
end

local boardWalkIns: (Train) -> () -- (más abajo: sienta a quien se ha metido andando en el tren)

local function depart(train: Train)
	boardWalkIns(train)
	local i, dir = nextIndex(train)
	train.Dir = dir
	train.From = train.S
	train.To = train.Centers[i]
	train.Index = i
	local dist = math.abs(train.To - train.From)
	-- Arranca y frena suave (aceleración constante hasta la velocidad de crucero)
	local accelDist = Metro.Speed * Metro.Speed / Metro.Accel
	if dist >= accelDist then
		train.Duration = 2 * Metro.Speed / Metro.Accel + (dist - accelDist) / Metro.Speed
	else
		train.Duration = 2 * math.sqrt(dist / Metro.Accel)
	end
	train.Elapsed = 0
	train.Phase = "Move"
	setDoors(train, false)
	for player in train.Passengers do
		Remote:FireClient(player, "Depart", { Line = train.Line.Id, Next = stationName(train.Line.Stations[i]) })
	end
end

-- Distancia recorrida a los t segundos de un tramo (acelera, crucero y frena)
local function travelled(train: Train, t: number): number
	local dist = math.abs(train.To - train.From)
	local a, v = Metro.Accel, Metro.Speed
	local ta = v / a
	if dist < v * v / a then
		ta = math.sqrt(dist / a)
		v = a * ta
	end
	local T = train.Duration
	if t <= ta then
		return 0.5 * a * t * t
	elseif t >= T - ta then
		local r = math.max(0, T - t)
		return dist - 0.5 * a * r * r
	end
	return 0.5 * a * ta * ta + v * (t - ta)
end

local function step(train: Train, dt: number)
	if train.Phase == "Dwell" then
		train.Timer -= dt
		if train.Timer <= 0 then
			depart(train)
		end
		return
	end
	train.Elapsed += dt
	if train.Elapsed >= train.Duration then
		arrive(train)
		return
	end
	local d = travelled(train, train.Elapsed)
	train.S = train.From + (if train.To >= train.From then d else -d)
	placeTrain(train)
end

local function setupTrain(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local line = Metro.lineById[model:GetAttribute("Line")]
	if not line or trains[line.Id] then
		return
	end
	local cars = {}
	for k = 1, Metro.Cars do
		local carModel = model:FindFirstChild("Car" .. k)
		local root = carModel and carModel:FindFirstChild("Root")
		if carModel and root and root:IsA("BasePart") then
			local car: Car = { Root = root, Seats = {}, Doors = {} }
			for _, d in carModel:GetDescendants() do
				if d:IsA("Seat") then
					table.insert(car.Seats, d)
				elseif d:IsA("BasePart") and d:HasTag("MetroDoor") then
					table.insert(car.Doors, d)
				end
			end
			table.insert(cars, car)
		end
	end
	if #cars == 0 then
		return
	end
	local points, centers = Metro.path(line)
	local train: Train = {
		Line = line,
		Model = model,
		Cars = cars,
		Points = points,
		Centers = centers,
		S = centers[1],
		Index = 1,
		Dir = 1,
		Phase = "Dwell",
		Timer = Metro.Dwell,
		From = 0,
		To = 0,
		Duration = 1,
		Elapsed = 0,
		Passengers = {},
	}
	trains[line.Id] = train
	arrive(train)
end

local function stopRiding(player: Player)
	local train = riding[player]
	if train then
		train.Passengers[player] = nil
		riding[player] = nil
	end
	if player.Parent then
		Remote:FireClient(player, "Off")
	end
end

-- Sienta al jugador en el tren y le enseña el panel del viaje
local function seatPlayer(player: Player, train: Train, seat: Seat, humanoid: Humanoid)
	require(script.Parent.VehicleService).standUp(player) -- (si iba en bici o patinete, se baja antes)
	seat:Sit(humanoid)
	train.Passengers[player] = true
	riding[player] = train
	local nextI = nextIndex(train)
	Remote:FireClient(player, "Board", {
		Line = train.Line.Id,
		LineName = train.Line.Name,
		Color = train.Line.Color,
		Stations = (function()
			local names = {}
			for _, id in train.Line.Stations do
				table.insert(names, stationName(id))
			end
			return names
		end)(),
		Station = stationName(train.Line.Stations[train.Index]),
		Next = stationName(train.Line.Stations[nextI]),
	})
end

local function onBoard(player: Player, marker: BasePart)
	local line = marker:GetAttribute("Line")
	local train = trains[line]
	local humanoid = humanoidOf(player)
	if not train or not humanoid or humanoid.Health <= 0 then
		return
	end
	local here = table.find(train.Line.Stations, marker:GetAttribute("Station"))
	if train.Phase ~= "Dwell" or train.Index ~= here then
		Notify:FireClient(player, "Info", ("El tren de la %s no está en el andén. Mira el panel: llega en %d s."):format(train.Line.Name, eta(train, here or 1)))
		return
	end
	local seat = freeSeat(train, marker.Position)
	if not seat then
		Notify:FireClient(player, "Info", "El tren va lleno. Espera al siguiente.")
		return
	end
	seatPlayer(player, train, seat, humanoid)
end

-- Al cerrar las puertas: quien se ha metido andando en un coche, se sienta y viaja
function boardWalkIns(train: Train)
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local humanoid = humanoidOf(player)
		if root and humanoid and (humanoid.Health or 0) > 0 and not riding[player] then
			for _, car in train.Cars do
				local q = car.Root.CFrame:PointToObjectSpace(root.Position)
				if math.abs(q.X) < 4.4 and q.Y > -1 and q.Y < 9 and math.abs(q.Z) < Metro.CarLength / 2 then
					local seat = freeSeat(train, root.Position)
					if seat then
						seatPlayer(player, train, seat, humanoid)
					end
					break
				end
			end
		end
	end
end

local function onAlight(player: Player)
	local train = riding[player]
	if not train or train.Phase ~= "Dwell" then
		return
	end
	local id = train.Line.Stations[train.Index]
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.Sit = false
	end
	stopRiding(player)
	local spot = findTagged("MetroAlight", { Station = id, Line = train.Line.Id })
	if spot then
		task.defer(function()
			teleport(player, spot.CFrame)
		end)
	end
	StoryEvents.emit(player, "RodeMetro", { Station = id })
end

-- Pasajeros: si se levantan con el tren en marcha, vuelven a su asiento; si se bajan parados, fuera
local function checkPassengers()
	for player, train in riding do
		local humanoid = humanoidOf(player)
		if not player.Parent or not humanoid or humanoid.Health <= 0 then
			stopRiding(player)
		elseif not isTrainSeat(train, humanoid.SeatPart) then
			if train.Phase == "Move" then
				local root = rootOf(player)
				local seat = freeSeat(train, root and root.Position)
				if seat then
					seat:Sit(humanoid)
				end
			else
				stopRiding(player)
			end
		end
	end
end

---------------------------------------------------------------------
-- Entrar, salir, tornos, transbordo
---------------------------------------------------------------------

local function arrivalFor(stationId: string): BasePart?
	return findTagged("MetroArrival", { Station = stationId, Line = "L1" }) or findTagged("MetroArrival", { Station = stationId })
end

local function onEntrance(player: Player, door: BasePart)
	local id = door:GetAttribute("Station")
	local arrival = id and arrivalFor(id)
	if not arrival then
		return
	end
	teleport(player, arrival.CFrame)
	Notify:FireClient(player, "Info", ("🚇 Metro · %s. Compra el billete en las máquinas y pasa por los tornos. (Para salir: ascensor o escaleras mecánicas)"):format(stationName(id)))
end

local function onExit(player: Player, exitPart: BasePart)
	local id = exitPart:GetAttribute("Station")
	local door = findTagged("MetroEntrance", { Station = id })
	if door then
		teleport(player, door.CFrame * CFrame.new(0, 0.5, -5) * CFrame.Angles(0, math.pi, 0))
	end
end

local function onTransfer(player: Player, marker: BasePart)
	local to = marker:GetAttribute("To")
	local target = if to == "Hub" then findTagged("MetroHubArrival", {}) else findTagged("MetroArrival", { Station = "PlazaMayor", Line = to })
	if target then
		teleport(player, target.CFrame)
	end
end

local function onGate(player: Player, gate: BasePart)
	-- Los niños viajan gratis (con un adulto o solos: en Valmar el metro es seguro)
	if Metro.FreeStages[player:GetAttribute("LifeStage") or ""] then
		local through = gate:GetAttribute("Through")
		if typeof(through) == "Vector3" then
			teleport(player, CFrame.new(through))
		end
		player:SetAttribute("MetroTicket", true)
		Notify:FireClient(player, "Info", "🎫 Los niños viajan gratis en el metro. ¡Buen viaje!")
		return
	end
	if InventoryService.count(player, Metro.TicketItem) < 1 then
		Notify:FireClient(player, "Info", "Necesitas un billete: cómpralo en las máquinas azules del vestíbulo 🎫")
		return
	end
	InventoryService.remove(player, Metro.TicketItem, 1)
	local through = gate:GetAttribute("Through")
	if typeof(through) == "Vector3" then
		teleport(player, CFrame.new(through))
	end
	player:SetAttribute("MetroTicket", true) -- (para el revisor: tiene billete validado)
end

local function onGateExit(player: Player, gate: BasePart)
	local through = gate:GetAttribute("Through")
	if typeof(through) == "Vector3" then
		teleport(player, CFrame.new(through))
	end
	player:SetAttribute("MetroTicket", nil)
end

local function onBuyTicket(player: Player, id: any)
	local root = rootOf(player)
	local machine = nil
	for _, m in tagged("MetroTicketMachine") do
		if root and (m.Position - root.Position).Magnitude < 14 then
			machine = m
		end
	end
	if not machine then
		return
	end
	for _, t in Metro.Tickets do
		if t.Id == id then
			if t.Stages and not t.Stages[player:GetAttribute("LifeStage") or ""] then
				Notify:FireClient(player, "Error", "El billete joven es para adolescentes y jóvenes. Coge el sencillo o el bonometro.")
				return
			end
			if not InventoryService.canAdd(player, Metro.TicketItem, t.Count) then
				Notify:FireClient(player, "Error", "No te caben más billetes en la mochila.")
				return
			end
			if not DataService.spend(player, t.Price) then
				Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
				return
			end
			InventoryService.add(player, Metro.TicketItem, t.Count)
			Notify:FireClient(player, "Success", ("🎫 %s comprado. Pásalo por el torno."):format(t.Name))
			return
		end
	end
end

---------------------------------------------------------------------
-- Tiendas y fotomatón
---------------------------------------------------------------------

local function shopData(shopId: string): { [string]: any }?
	local shop = Metro.Shops[shopId]
	if not shop then
		return nil
	end
	local list = {}
	for _, entry in shop.Items do
		local item = Items.get(entry[1])
		if item then
			table.insert(list, { Id = entry[1], Name = item.Name, Icon = item.Icon, Price = entry[2], Desc = item.Desc })
		end
	end
	return { ShopId = shopId, Name = shop.Name, Icon = shop.Icon, Items = list }
end

local function onBuy(player: Player, shopId: any, itemId: any)
	local shop = typeof(shopId) == "string" and Metro.Shops[shopId]
	if not shop then
		return
	end
	local root = rootOf(player)
	local ok = false
	for _, p in tagged("MetroShop") do
		if p:GetAttribute("ShopId") == shopId and root and (p.Position - root.Position).Magnitude < 16 then
			ok = true
		end
	end
	if not ok then
		return
	end
	for _, entry in shop.Items do
		if entry[1] == itemId then
			if not InventoryService.canAdd(player, itemId, 1) then
				Notify:FireClient(player, "Error", "No te cabe en la mochila.")
				return
			end
			if not DataService.spend(player, entry[2]) then
				Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
				return
			end
			InventoryService.add(player, itemId, 1)
			local item = Items.get(itemId) :: any
			Notify:FireClient(player, "Success", ("%s %s · %s"):format(item.Icon, item.Name, Format.money(entry[2])))
			StoryEvents.emit(player, "BoughtItem", { ShopId = "Metro" .. shopId, ItemId = itemId })
			return
		end
	end
end

local function onPhoto(player: Player)
	if not InventoryService.canAdd(player, "FotoMaton", 1) then
		Notify:FireClient(player, "Error", "No te cabe en la mochila.")
		return
	end
	if not DataService.spend(player, Metro.PhotoPrice) then
		Notify:FireClient(player, "Error", ("El fotomatón cuesta %s."):format(Format.money(Metro.PhotoPrice)))
		return
	end
	Remote:FireClient(player, "Flash")
	task.delay(1.2, function()
		if player.Parent then
			InventoryService.add(player, "FotoMaton", 1)
			Notify:FireClient(player, "Success", "📸 ¡Clic, clic, clic, clic! Tu tira de fotos está en la mochila.")
		end
	end)
end

---------------------------------------------------------------------
-- Músicos en el escenario
---------------------------------------------------------------------

local function onStage(player: Player)
	if InventoryService.count(player, Metro.Busk.Instrument) < 1 then
		Notify:FireClient(player, "Info", "Necesitas una guitarra 🎸. Hay en la tienda de discos de la galería.")
		return
	end
	local last = lastBusk[player]
	if last and os.clock() - last < Metro.Busk.Cooldown then
		Notify:FireClient(player, "Info", ("Descansa un poco la voz: podrás volver a tocar en %d s."):format(math.ceil(Metro.Busk.Cooldown - (os.clock() - last))))
		return
	end
	nextToken += 1
	busking[player] = { Token = nextToken, Started = os.clock() }
	lastBusk[player] = os.clock()
	Remote:FireClient(player, "Busk", { Token = nextToken, Notes = Metro.Busk.Notes })
end

local function onBuskEnd(player: Player, token: any, hits: any)
	local b = busking[player]
	if not b or b.Token ~= token or typeof(hits) ~= "number" then
		return
	end
	busking[player] = nil
	if os.clock() - b.Started < Metro.Busk.MinSeconds then
		return -- demasiado rápido para ser de verdad
	end
	local good = math.clamp(math.floor(hits), 0, Metro.Busk.Notes)
	local tips = math.min(good * Metro.Busk.PerHit, Metro.Busk.MaxTips)
	if tips > 0 then
		DataService.addMoney(player, tips, true)
		Notify:FireClient(player, "Money", ("+%s · propinas del público (%d/%d notas)"):format(Format.money(tips), good, Metro.Busk.Notes))
	else
		Notify:FireClient(player, "Info", "Nadie ha echado nada… ¡a practicar!")
	end
	StoryEvents.emit(player, "BuskPlayed", { Hits = good })
end

---------------------------------------------------------------------
-- Encargos del tablón
---------------------------------------------------------------------

local function otherStations(): { string }
	local list = {}
	for id, st in Metro.Stations do
		if not st.Hub then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

local function platformSpot(stationId: string): CFrame?
	local alight = findTagged("MetroAlight", { Station = stationId })
	if not alight then
		return nil
	end
	return alight.CFrame * CFrame.new(math.random(-2, 3), -2.4, math.random(-50, 50))
end

local function missionPrompt(parent: BasePart, action: string, object: string, owner: Player): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0.4
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	p:SetAttribute("OwnerUserId", owner.UserId)
	p.Parent = parent
	return p
end

local function clearMission(player: Player)
	local m = missions[player]
	if not m then
		return
	end
	missions[player] = nil
	if m.Thing and m.Thing.Parent then
		m.Thing:Destroy()
	end
	for _, id in { "CarteraPerdida", "PaqueteMetro" } do
		local n = InventoryService.count(player, id)
		if n > 0 then
			InventoryService.remove(player, id, n)
		end
	end
	player:SetAttribute("CarryingCat", nil)
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Mission", nil)
end

local function missionStatus(player: Player)
	local m = missions[player]
	if not m then
		Remote:FireClient(player, "Mission", nil)
		return
	end
	Remote:FireClient(player, "Mission", { Kind = m.Kind, Text = m.Text, Deadline = m.Deadline and math.max(0, math.floor(m.Deadline - os.clock())) or nil })
	if m.Target then
		player:SetAttribute("TaskTarget", m.Target)
		player:SetAttribute("TaskText", m.Guide)
	end
end

local function completeMission(player: Player, extra: number?)
	local m = missions[player]
	if not m then
		return
	end
	local def = Metro.Missions[m.Kind]
	local pay = def.Reward + (extra or 0)
	clearMission(player)
	DataService.addMoney(player, pay, true)
	Notify:FireClient(player, "Money", ("+%s · encargo cumplido: %s %s"):format(Format.money(pay), def.Icon, def.Name))
	StoryEvents.emit(player, "MetroMissionDone", { Kind = def.Name })
end

local function spawnThing(stationId: string, kind: string): BasePart?
	local cf = platformSpot(stationId)
	if not cf then
		return nil
	end
	local thing = Instance.new("Part")
	thing.Anchored = true
	thing.CanCollide = false
	thing.CanQuery = false
	if kind == "Gato" then
		thing.Name = "GatoMetro"
		thing.Size = Vector3.new(1.4, 1.2, 2.4)
		thing.Color = Color3.fromRGB(230, 140, 50)
		thing.Material = Enum.Material.Fabric
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(1.1, 1.1, 1.1)
		head.Color = thing.Color
		head.Anchored = true
		head.CanCollide = false
		head.CFrame = cf * CFrame.new(0, 1.3, -1.4)
		head.Parent = thing
	else
		thing.Name = "ObjetoPerdido"
		thing.Size = Vector3.new(1, 0.4, 1.4)
		thing.Color = Color3.fromRGB(150, 60, 170)
		thing.Material = Enum.Material.Neon
	end
	thing.CFrame = cf * CFrame.new(0, 0.8, 0)
	local folder = workspace:FindFirstChild("MetroMissions") or (function()
		local f = Instance.new("Folder")
		f.Name = "MetroMissions"
		f.Parent = workspace
		return f
	end)()
	thing.Parent = folder
	return thing
end

local function acceptMission(player: Player, kind: any)
	local def = typeof(kind) == "string" and Metro.Missions[kind]
	if not def then
		return
	end
	if missions[player] then
		Notify:FireClient(player, "Info", "Ya tienes un encargo. Termínalo o cancélalo primero.")
		return
	end
	local list = otherStations()
	local stationId = list[math.random(1, #list)]
	local m: { [string]: any } = { Kind = kind, Station = stationId, Text = def.Text:format(stationName(stationId)) }
	if kind == "Paquete" then
		if not InventoryService.add(player, "PaqueteMetro", 1) then
			Notify:FireClient(player, "Error", "No te cabe el paquete en la mochila.")
			return
		end
		m.Deadline = os.clock() + def.Seconds
		m.Started = os.clock()
		local kiosk = findTagged("MetroDelivery", { Station = stationId })
		m.Target = kiosk and kiosk.Position
		m.Guide = "Lleva el paquete al quiosco de " .. stationName(stationId)
	else
		local thing = spawnThing(stationId, kind)
		if not thing then
			return
		end
		m.Thing = thing
		m.Target = thing.Position
		m.Guide = if kind == "Gato" then "Busca al gato en el andén de " .. stationName(stationId) else "Busca el objeto perdido en el andén de " .. stationName(stationId)
		local p = missionPrompt(thing, if kind == "Gato" then "Coger al gato" else "Recoger", if kind == "Gato" then "🐈 Gato del metro" else "👛 Objeto perdido", player)
		p.Triggered:Connect(function(who)
			local now = missions[who]
			if who ~= player or not now or now.Thing ~= thing then
				return
			end
			thing:Destroy()
			now.Thing = nil
			if kind == "Gato" then
				player:SetAttribute("CarryingCat", true)
				local board = tagged("MetroMissionBoard")[1]
				now.Target = board and board.Position
				now.Guide = "Lleva el gato al tablón de encargos (galería de Plaza Mayor)"
				Notify:FireClient(player, "Success", "🐈 ¡Miau! Ya lo tienes. Llévalo al tablón de la galería.")
			else
				InventoryService.add(player, "CarteraPerdida", 1)
				local office = tagged("MetroLostOffice")[1]
				now.Target = office and office.Position
				now.Guide = "Lleva el objeto a Objetos Perdidos (galería de Plaza Mayor)"
				Notify:FireClient(player, "Success", "👛 ¡Encontrado! Llévalo a Objetos Perdidos.")
			end
			missionStatus(player)
		end)
	end
	missions[player] = m
	Notify:FireClient(player, "Success", ("%s Encargo aceptado: %s"):format(def.Icon, m.Text))
	missionStatus(player)
end

local function onMissionBoard(player: Player)
	local m = missions[player]
	if m and m.Kind == "Gato" and player:GetAttribute("CarryingCat") then
		completeMission(player)
		return
	end
	local offers = {}
	for id, def in Metro.Missions do
		table.insert(offers, { Id = id, Name = def.Name, Icon = def.Icon, Reward = def.Reward })
	end
	table.sort(offers, function(a, b)
		return a.Name < b.Name
	end)
	Remote:FireClient(player, "Missions", { Offers = offers, Current = m and { Kind = m.Kind, Text = m.Text } or nil })
end

local function onLostOffice(player: Player)
	local m = missions[player]
	if m and m.Kind == "Perdido" and InventoryService.count(player, "CarteraPerdida") > 0 then
		completeMission(player)
	else
		Notify:FireClient(player, "Info", "Objetos Perdidos: si encuentras algo en el metro, tráelo aquí. (Mira el tablón de encargos.)")
	end
end

local function onDelivery(player: Player, kiosk: BasePart)
	local m = missions[player]
	if not m or m.Kind ~= "Paquete" or kiosk:GetAttribute("Station") ~= m.Station or InventoryService.count(player, "PaqueteMetro") < 1 then
		return false
	end
	local fast = os.clock() - m.Started < Metro.Missions.Paquete.Seconds / 2
	completeMission(player, if fast then Metro.Missions.Paquete.Bonus else 0)
	return true
end

---------------------------------------------------------------------
-- Revisor/a
---------------------------------------------------------------------

local revisorNpcs: { [Player]: { Model } } = {}

local function nearestStation(position: Vector3, range: number): BasePart?
	local best, bestD = nil, range
	for _, a in tagged("MetroAlight") do
		local d = (a.Position - position).Magnitude
		if d < bestD then
			best, bestD = a, d
		end
	end
	return best
end

local LINES_OK = { "Aquí tiene.", "Sí, sí, un momento… ¡aquí está!", "Claro, mi billete." }
local LINES_NO = { "Eh… lo tenía por aquí…", "¡Uy! Se me ha olvidado…", "¿Billete? ¿Qué billete?" }

local function spawnPassenger(player: Player, alight: BasePart)
	local folder = alight.Parent :: Instance
	local cf = alight.CFrame * CFrame.new(math.random(-2, 3), 0, math.random(-55, 55))
	local model = Npc.create("Viajero", folder, cf, nil)
	model:SetAttribute("HasTicket", math.random() > REV.NoTicketChance)
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	if root and root:IsA("BasePart") then
		local p = Instance.new("ProximityPrompt")
		p.ActionText = "Pedir el billete"
		p.ObjectText = "🎫 Viajero"
		p.HoldDuration = 0.5
		p.MaxActivationDistance = 8
		p.RequiresLineOfSight = false
		p:SetAttribute("JobOnly", "Revisor")
		p:SetAttribute("OwnerUserId", player.UserId)
		p.Parent = root
		p.Triggered:Connect(function(who)
			if who ~= player or not onDuty[player] or model:GetAttribute("Checked") then
				return
			end
			model:SetAttribute("Checked", true)
			p:Destroy()
			local has = model:GetAttribute("HasTicket")
			local pay = math.floor((if has then REV.PerCheck else REV.PerFine) * MonetizationService.payMultiplier(player))
			Npc.say(model, if has then LINES_OK[math.random(1, #LINES_OK)] else LINES_NO[math.random(1, #LINES_NO)])
			DataService.addMoney(player, pay, true)
			Notify:FireClient(player, "Money", ("+%s · %s"):format(Format.money(pay), if has then "billete en regla" else "¡multa por viajar sin billete!"))
			local data = DataService.get(player)
			if data and data.Stats then
				data.Stats.TasksDone += 1
			end
			NeedsService.change(player, 0, -REV.EnergyCost)
			StoryEvents.emit(player, "JobTaskDone", { JobId = "Revisor", Pay = pay })
			task.delay(3, function()
				if model.Parent then
					model:Destroy()
				end
			end)
			if not NeedsService.canWork(player) then
				MetroService.quitRevisor(player, true)
				Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
			end
		end)
	end
	table.insert(revisorNpcs[player], model)
end

local function revisorTick(player: Player)
	local list = revisorNpcs[player]
	for i = #list, 1, -1 do
		if not list[i].Parent then
			table.remove(list, i)
		end
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local alight = nearestStation(root.Position, 160)
	if not alight then
		local door, best = nil, math.huge
		for _, d in tagged("MetroEntrance") do
			local dist = (d.Position - root.Position).Magnitude
			if dist < best then
				door, best = d, dist
			end
		end
		player:SetAttribute("TaskTarget", door and door.Position)
		player:SetAttribute("TaskText", "Baja al metro a revisar billetes")
		return
	end
	while #list < REV.MaxNpc do
		spawnPassenger(player, alight)
	end
	local target, best = nil, math.huge
	for _, model in list do
		local r = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r and not model:GetAttribute("Checked") then
			local d = (r.Position - root.Position).Magnitude
			if d < best then
				target, best = r, d
			end
		end
	end
	player:SetAttribute("TaskTarget", target and target.Position)
	player:SetAttribute("TaskText", "Pide el billete a los viajeros del andén")
end

function MetroService.startRevisor(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	JobService.quit(player, true)
	onDuty[player] = true
	revisorNpcs[player] = {}
	RoleService.setOnDuty(player, "Revisor")
	player:SetAttribute("Job", "Revisor")
	Notify:FireClient(player, "Success", "¡De revisor/a! Pide el billete a los viajeros de los andenes. Multa a los que no lo tengan.")
	revisorTick(player)
end

function MetroService.quitRevisor(player: Player, silent: boolean?)
	if not onDuty[player] then
		return
	end
	onDuty[player] = nil
	for _, model in revisorNpcs[player] or {} do
		if model.Parent then
			model:Destroy()
		end
	end
	revisorNpcs[player] = nil
	RoleService.offDuty(player, "Revisor")
	if player:GetAttribute("Job") == "Revisor" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado tu turno de revisor/a.")
	end
end

---------------------------------------------------------------------
-- Ambiente: viajeros esperando en los andenes y dependientes en las tiendas
---------------------------------------------------------------------

local ambient: { [BasePart]: { Model } } = {}
local clerks: { [BasePart]: Model } = {}

local function anyoneNear(position: Vector3, range: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - position).Magnitude < range then
			return true
		end
	end
	return false
end

local function ambientTick()
	for _, alight in tagged("MetroAlight") do
		local active = anyoneNear(alight.Position, 140)
		local list = ambient[alight] or {}
		ambient[alight] = list
		for i = #list, 1, -1 do
			if not list[i].Parent then
				table.remove(list, i)
			end
		end
		if active and #list < 3 then
			local cf = alight.CFrame * CFrame.new(math.random(-3, 3), 0, math.random(-60, 60))
			local npc = Npc.create("Viajero", alight.Parent :: Instance, cf, nil)
			Npc.face(npc, (alight.CFrame * CFrame.new(-20, 0, 0)).Position)
			table.insert(list, npc)
		elseif not active then
			for _, npc in list do
				npc:Destroy()
			end
			table.clear(list)
		end
	end
	for _, counter in tagged("MetroShop") do
		local spot = counter:GetAttribute("StaffSpot")
		if typeof(spot) == "Vector3" then
			local active = anyoneNear(counter.Position, 150)
			if active and not clerks[counter] then
				local npc = Npc.create("Npc_Dependiente", counter.Parent :: Instance, CFrame.new(spot + Vector3.new(0, 3, 0)), nil)
				Npc.face(npc, counter.Position)
				clerks[counter] = npc
			elseif not active and clerks[counter] then
				clerks[counter]:Destroy()
				clerks[counter] = nil
			end
		end
	end
end

-- Cuando un tren llega, los que esperaban "suben" (desaparecen) y otros bajan
local function trainArrivedAmbient(train: Train)
	local id = train.Line.Stations[train.Index]
	local alight = findTagged("MetroAlight", { Station = id, Line = train.Line.Id })
	local list = alight and ambient[alight]
	if not list or #list == 0 then
		return
	end
	for i = #list, 1, -1 do
		if math.random() < 0.6 then
			list[i]:Destroy()
			table.remove(list, i)
		end
	end
end

-- Paneles "PRÓXIMO TREN": "Línea 1 → Levante · 2 min", "LLEGANDO", "EN ANDÉN"
local function updateDisplays()
	for _, display in tagged("MetroDisplay") do
		local train = trains[display:GetAttribute("Line")]
		local index = train and table.find(train.Line.Stations, display:GetAttribute("Station"))
		if train and index then
			local seconds, toward = Metro.eta(train, index)
			local text = Metro.boardText(train.Line, seconds, toward, if train.Phase == "Dwell" then train.Timer else nil)
			for _, label in display:GetDescendants() do
				if label:IsA("TextLabel") and label.Text ~= text then
					label.Text = text
				end
			end
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

-- Escaleras mecánicas: su suelo invisible es una cinta transportadora (lleva a quien se sube)
local function setupEscalator(belt: BasePart)
	local v = belt:GetAttribute("Velocity")
	if typeof(v) == "Vector3" then
		belt.AssemblyLinearVelocity = v
	end
end

local SETUP: { [string]: (BasePart) -> () } = {
	MetroEntrance = function(door)
		prompt(door, "Bajar en ascensor", "♿ Ascensor · Metro " .. stationName(door:GetAttribute("Station")), 0.4, 8).Triggered:Connect(function(player)
			onEntrance(player, door)
		end)
	end,
	MetroExit = function(part)
		prompt(part, "Subir en ascensor", "♿ Ascensor · calle", 0.4, 8).Triggered:Connect(function(player)
			onExit(player, part)
		end)
	end,
	MetroEscalator = setupEscalator,
	MetroTransfer = function(part)
		local to = part:GetAttribute("To")
		prompt(part, if to == "Hub" then "Ascensor a la galería" else "Ascensor a la Línea 2", if to == "Hub" then "🔴 Línea 1 · galería" else "🔵 Línea 2", 0.4, 10).Triggered:Connect(function(player)
			onTransfer(player, part)
		end)
	end,
	MetroGate = function(gate)
		prompt(gate, "Pasar (billete)", "🎫 Torno", 0.3, 7).Triggered:Connect(function(player)
			onGate(player, gate)
		end)
	end,
	MetroGateExit = function(gate)
		prompt(gate, "Salir", "🚪 Salida", 0.3, 7).Triggered:Connect(function(player)
			onGateExit(player, gate)
		end)
	end,
	MetroTicketMachine = function(machine)
		prompt(machine, "Comprar billete", "🎫 Máquina de billetes", 0.3, 8).Triggered:Connect(function(player)
			Remote:FireClient(player, "Tickets", Metro.Tickets)
		end)
	end,
	MetroBoard = function(marker)
		local line = Metro.lineById[marker:GetAttribute("Line")]
		prompt(marker, "Subir al metro", "🚇 " .. (if line then line.Name else "Metro"), 0.2, 7).Triggered:Connect(function(player)
			onBoard(player, marker)
		end)
	end,
	MetroShop = function(counter)
		local shop = Metro.Shops[counter:GetAttribute("ShopId")]
		if not shop then
			return
		end
		prompt(counter, "Comprar", shop.Icon .. " " .. shop.Name, 0.3, 9).Triggered:Connect(function(player)
			Remote:FireClient(player, "Shop", shopData(counter:GetAttribute("ShopId")))
		end)
		if counter:HasTag("MetroDelivery") then
			local p = prompt(counter, "Entregar paquete", "📦 Quiosco", 0.5, 9)
			p.KeyboardKeyCode = Enum.KeyCode.F
			p.UIOffset = Vector2.new(0, 60)
			p.Triggered:Connect(function(player)
				if not onDelivery(player, counter) then
					Notify:FireClient(player, "Info", "Este quiosco no espera ningún paquete tuyo.")
				end
			end)
		end
	end,
	MetroPhoto = function(booth)
		prompt(booth, ("Hacerse una foto (%s)"):format(Format.money(Metro.PhotoPrice)), "📸 Fotomatón", 0.5, 9).Triggered:Connect(onPhoto)
	end,
	MetroStage = function(mic)
		prompt(mic, "Tocar música", "🎸 Escenario", 0.5, 10).Triggered:Connect(onStage)
	end,
	MetroMissionBoard = function(board)
		prompt(board, "Ver encargos", "📌 Tablón del metro", 0.3, 10).Triggered:Connect(onMissionBoard)
	end,
	MetroLostOffice = function(counter)
		prompt(counter, "Objetos perdidos", "👛 Ventanilla", 0.4, 9).Triggered:Connect(onLostOffice)
	end,
}

function MetroService.init()
	for tag, fn in SETUP do
		for _, part in tagged(tag) do
			fn(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(part)
			if part:IsA("BasePart") then
				fn(part)
			end
		end)
	end
	for _, model in CollectionService:GetTagged("MetroTrain") do
		setupTrain(model)
	end
	CollectionService:GetInstanceAddedSignal("MetroTrain"):Connect(setupTrain)
	JobService.setHandler("Revisor", { Start = MetroService.startRevisor, Quit = MetroService.quitRevisor })

	Remote.OnServerEvent:Connect(function(player, action, a, b)
		if action == "Alight" then
			onAlight(player)
		elseif action == "BuyTicket" then
			onBuyTicket(player, a)
		elseif action == "Buy" then
			onBuy(player, a, b)
		elseif action == "Accept" then
			acceptMission(player, a)
		elseif action == "CancelMission" then
			clearMission(player)
			Notify:FireClient(player, "Info", "Encargo cancelado.")
		elseif action == "BuskEnd" then
			onBuskEnd(player, a, b)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		stopRiding(player)
		clearMission(player)
		MetroService.quitRevisor(player, true)
		busking[player] = nil
		lastBusk[player] = nil
	end)

	-- Trenes: se mueven cada fotograma
	RunService.Heartbeat:Connect(function(dt)
		for _, train in trains do
			local was = train.Phase
			local ok, err = pcall(step, train, dt)
			if not ok then
				warn("[MetroService] " .. tostring(err))
			elseif was == "Move" and train.Phase == "Dwell" then
				trainArrivedAmbient(train)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(function()
				checkPassengers()
				updateDisplays()
				ambientTick()
				for player in onDuty do
					revisorTick(player)
				end
				for player, m in missions do
					if m.Deadline and os.clock() > m.Deadline then
						clearMission(player)
						Notify:FireClient(player, "Error", "📦 Se acabó el tiempo: el paquete ha vuelto a la galería.")
					end
				end
			end)
			if not ok then
				warn("[MetroService] " .. tostring(err))
			end
		end
	end)
end

-- Para las pruebas
MetroService._trains = trains
MetroService._riding = riding
MetroService._missions = missions
MetroService._step = step

return MetroService
