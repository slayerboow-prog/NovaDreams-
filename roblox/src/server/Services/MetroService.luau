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
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Items = require(ReplicatedStorage.Shared.Items)
local Format = require(ReplicatedStorage.Shared.Format)
local Npc = require(script.Parent.Parent.World.Npc)
local MetroKit = require(script.Parent.Parent.World.Kit.MetroKit)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local InventoryService = require(script.Parent.InventoryService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local StaffService = require(script.Parent.StaffService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local TesterService = require(script.Parent.TesterService) -- modo pruebas: pasa el torno sin billete

local MetroService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Metro :: RemoteEvent
local REV = Metro.Revisor
local rgb = Color3.fromRGB
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
	Speed: number, -- velocidad de crucero (baja con una avería)
	DwellTime: number, -- lo que para en cada estación (según el horario)
	Layover: number, -- descanso en las cabeceras (según el horario)
	Hold: number?, -- espera extra en la próxima parada (retraso, incidencia de seguridad)
	T0: number, -- hora del servidor a la que salió del último andén (para los clientes)
	DoorsOpen: boolean,
	Warned: boolean, -- ya ha avisado "las puertas van a cerrarse"
	Announced: boolean, -- ya ha avisado en el andén de que llega
	Riders: { Model }, -- viajeros NPC sentados en el tren
}

local trains: { [string]: Train } = {}
local riding: { [Player]: Train } = {}
local lastBusk: { [Player]: number } = {}
local busking: { [Player]: { Token: number, Started: number } } = {}
local missions: { [Player]: { [string]: any } } = {}
local onDuty: { [Player]: boolean } = {}
local nextToken = 0
local stateFolder: Folder? = nil -- ReplicatedStorage.MetroState: lo que ven los clientes
local incidents: { { [string]: any } } = {} -- incidencias activas
local closedUntil: { [string]: number } = {} -- estaciones cerradas (hora de os.clock hasta la que lo están)
local schedule = Metro.scheduleAt(8)

-- Hora del servidor (la misma que ven los clientes con workspace:GetServerTimeNow())
function MetroService._now(): number
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
	for _, npc in train.Riders do
		local car = train.Cars[npc:GetAttribute("MetroCar") or 1]
		local rel = npc:GetAttribute("MetroOffset")
		if car and typeof(rel) == "CFrame" and npc.Parent and not npc:GetAttribute("ChangingCar") then
			npc:PivotTo(car.Root.CFrame * rel)
		end
	end
end

-- Dónde va cada coche ahora mismo (para saber quién va dentro, aunque sea de pie)
local function carAt(train: Train, position: Vector3): Car?
	for _, car in train.Cars do
		local q = car.Root.CFrame:PointToObjectSpace(position)
		if math.abs(q.X) < 4.4 and q.Y > -1 and q.Y < 9 and math.abs(q.Z) < Metro.CarLength / 2 + 1 then
			return car
		end
	end
	return nil
end

-- Lo que ven los clientes para mover el tren en su pantalla (ReplicatedStorage.MetroState.<línea>)
local function publish(train: Train)
	local root = stateFolder
	if not root then
		return
	end
	local f = root:FindFirstChild(train.Line.Id)
	if not f then
		f = Instance.new("Folder")
		f.Name = train.Line.Id
		f.Parent = root
	end
	local now = MetroService._now()
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
	f:SetAttribute("DwellTime", train.DwellTime)
	f:SetAttribute("Layover", train.Layover)
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

-- Megafonía: a los viajeros del tren y/o a quien está en el andén
local function announce(train: Train, text: string, toRiders: boolean, platformIndex: number?)
	if toRiders then
		for player in train.Passengers do
			Remote:FireClient(player, "Announce", { Text = text, Line = train.Line.Id })
		end
	end
	if platformIndex then
		local center = Metro.center(train.Line.Stations[platformIndex], train.Line)
		for _, player in playersNear(center, 110) do
			if not train.Passengers[player] then
				Remote:FireClient(player, "Announce", { Text = text, Line = train.Line.Id, Platform = true })
			end
		end
	end
end

local function isClosed(stationId: string): boolean
	local t = closedUntil[stationId]
	return t ~= nil and os.clock() < t
end

local function setDoors(train: Train, open: boolean)
	-- Solo se abren las puertas del lado del andén (las del otro lado dan a la pared y a la vía)
	local frame = if open then Metro.frame(train.Line.Stations[train.Index], train.Line) else nil
	for _, car in train.Cars do
		-- ¿El lado derecho del coche da al andén? (el andén está a la derecha de la estación)
		local facing = if frame and frame.RightVector:Dot(car.Root.CFrame.RightVector) < 0 then -1 else 1
		for _, door in car.Doors do
			local platformSide = frame == nil or (door:GetAttribute("Side") or 1) * facing > 0
			local opened = open and platformSide
			door.Transparency = if opened then 1 else 0
			door.CanCollide = not opened
		end
	end
end

local function freeSeat(train: Train, from: Vector3?): Seat?
	if train.Full and os.clock() < train.Full then
		return nil -- (tren lleno: se va de pie)
	end
	local best, bestD = nil, math.huge
	for _, car in train.Cars do
		for _, seat in car.Seats do
			if not seat.Occupant and not seat:GetAttribute("NpcRider") then
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

local refreshRiders: (Train) -> () -- (más abajo: viajeros NPC que suben y bajan)

local function arrive(train: Train)
	train.Phase = "Dwell"
	local id = train.Line.Stations[train.Index]
	local closed = isClosed(id)
	local hold = train.Hold or 0
	train.Hold = nil
	-- Estación cerrada: el tren para un momento con las puertas cerradas y sigue
	train.Timer = if closed then 3 else Metro.dwellAt(train, train.Index) + hold
	train.S = train.Centers[train.Index]
	train.Warned = false
	train.Announced = false
	train.DoorsOpen = not closed
	placeTrain(train)
	setDoors(train, not closed)
	publish(train)
	local nextI = nextIndex(train)
	for player in train.Passengers do
		Remote:FireClient(player, "Arrive", { Line = train.Line.Id, Station = stationName(id), Next = stationName(train.Line.Stations[nextI]), Closed = closed })
		if missions[player] then
			missions[player].Rode = true
		end
	end
	if closed then
		announce(train, ("Estación %s cerrada temporalmente. El tren no abre las puertas."):format(stationName(id)), true, nil)
	elseif hold > 0 then
		announce(train, ("Por motivos de regulación, el tren permanecerá detenido en %s unos instantes."):format(stationName(id)), true, train.Index)
	end
	if refreshRiders and not closed then
		refreshRiders(train)
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
	train.Duration = Metro.legDuration(dist, train.Speed)
	train.Elapsed = 0
	train.T0 = MetroService._now()
	train.Phase = "Move"
	train.DoorsOpen = false
	setDoors(train, false)
	publish(train)
	for player in train.Passengers do
		Remote:FireClient(player, "Depart", { Line = train.Line.Id, Next = stationName(train.Line.Stations[i]) })
	end
	announce(train, Metro.announceNext(train.Line, train.Line.Stations[i]), true, nil)
end

-- Distancia recorrida a los t segundos de un tramo (acelera, crucero y frena)
local function travelled(train: Train, t: number): number
	return Metro.travelled(math.abs(train.To - train.From), t, train.Duration, train.Speed)
end

local function step(train: Train, dt: number)
	if train.Phase == "Dwell" then
		-- Si algo ha movido un coche (un viajero sentado al que otro sistema llevó a otro sitio se
		-- llevaba el coche con él: aparecía en la calle), vuelve a su sitio
		local first = train.Cars[1]
		if first and first.Root.Parent then
			local offset = (1 - (#train.Cars + 1) / 2) * STEP
			local p = Metro.sample(train.Points, train.S - offset)
			if (first.Root.Position - p).Magnitude > 4 then
				placeTrain(train)
			end
		end
		train.Timer -= dt
		if train.DoorsOpen and not train.Warned and train.Timer <= 4 then
			train.Warned = true
			announce(train, Metro.AnnounceDoors, true, train.Index)
			Remote:FireAllClients("Doors", { Line = train.Line.Id, Closing = true })
		end
		if train.Timer <= 0 then
			depart(train)
		end
		return
	end
	train.Elapsed += dt
	if not train.Announced and train.Duration - train.Elapsed <= 12 then
		train.Announced = true
		local toward = Metro.Stations[train.Line.Stations[select(2, Metro.eta(train :: any, train.Index))]].Name
		announce(train, Metro.announceArriving(train.Line, toward), false, train.Index)
	end
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
			if carModel:GetAttribute("NeedsWeld") then
				-- Soldar todo el coche a su suelo aquí, con las piezas ya en su sitio (MetroKit.weldCar)
				carModel:SetAttribute("NeedsWeld", nil)
				MetroKit.weldCar(carModel :: Model, root)
			end
			local car: Car = { Root = root, Seats = {}, Doors = {} }
			for _, d in carModel:GetDescendants() do
				if d:IsA("Seat") then
					table.insert(car.Seats, d)
				elseif d:IsA("BasePart") and d:HasTag("MetroDoor") then
					-- De qué lado del coche está (a la derecha o a la izquierda de su suelo)
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
		Speed = Metro.Speed,
		DwellTime = schedule.Dwell,
		Layover = schedule.Layover,
		T0 = MetroService._now(),
		DoorsOpen = true,
		Warned = false,
		Announced = false,
		Riders = {},
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

-- Panel del viaje para quien va en el tren (sentado o de pie)
local function startRide(player: Player, train: Train)
	train.Passengers[player] = true
	riding[player] = train
	local nextI = nextIndex(train)
	local names = {}
	for _, id in train.Line.Stations do
		table.insert(names, stationName(id))
	end
	Remote:FireClient(player, "Board", {
		Line = train.Line.Id,
		LineName = train.Line.Name,
		Color = train.Line.Color,
		Stations = names,
		Station = stationName(train.Line.Stations[train.Index]),
		Next = stationName(train.Line.Stations[nextI]),
	})
end

-- Sienta al jugador en el tren y le enseña el panel del viaje
local function seatPlayer(player: Player, train: Train, seat: Seat, humanoid: Humanoid)
	require(script.Parent.VehicleService).standUp(player) -- (si iba en bici o patinete, se baja antes)
	seat:Sit(humanoid)
	if riding[player] ~= train then
		startRide(player, train)
	end
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
	if not train.DoorsOpen then
		Notify:FireClient(player, "Info", "Esta estación está cerrada: el tren no abre las puertas.")
		return
	end
	local seat = freeSeat(train, marker.Position)
	if not seat then
		-- Sin asiento libre: se sube de pie (dentro del coche más cercano)
		local root = rootOf(player)
		local best, bestD = nil, math.huge
		for _, car in train.Cars do
			local d = if root then (car.Root.Position - root.Position).Magnitude else 0
			if d < bestD then
				best, bestD = car, d
			end
		end
		if best then
			require(script.Parent.VehicleService).standUp(player)
			teleport(player, best.Root.CFrame * CFrame.new(0, 3.5, 0))
			startRide(player, train)
			Notify:FireClient(player, "Info", "No quedan asientos libres: vas de pie. Agárrate a la barra 🧍")
		end
		return
	end
	seatPlayer(player, train, seat, humanoid)
end

-- Al cerrar las puertas: quien se ha metido andando en un coche viaja (de pie, o se sienta si quiere)
function boardWalkIns(train: Train)
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local humanoid = humanoidOf(player)
		if root and humanoid and (humanoid.Health or 0) > 0 and not riding[player] and carAt(train, root.Position) then
			startRide(player, train)
		end
	end
end

local function onAlight(player: Player)
	local train = riding[player]
	if not train or train.Phase ~= "Dwell" or not train.DoorsOpen then
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

-- Pasajeros: se puede ir sentado o de pie, andar por el coche y cambiar de coche. Si con el tren
-- parado sales por la puerta, has bajado en esa estación.
-- Nadie andando por la vía ni por los túneles: quien baje a la vía (o se cuele en un túnel) y no
-- vaya dentro de un coche vuelve al andén de la estación más cercana, con un aviso. (Antes se podía
-- andar por los túneles y el tren, que no choca, te atravesaba.)
local lineCache: { [string]: { Vector3 } } = {}
local function onTrack(position: Vector3): (Metro.Line?, number)
	for _, line in Metro.Lines do
		if position.Y > line.Y - 3 and position.Y < line.Y + 7 then
			local points = lineCache[line.Id]
			if not points then
				points = Metro.path(line)
				local first, last = points[1], points[#points]
				table.insert(points, 1, first + (first - points[2]).Unit * 60)
				table.insert(points, last + (last - points[#points - 1]).Unit * 60)
				lineCache[line.Id] = points
			end
			for i = 1, #points - 1 do
				local a, b = points[i], points[i + 1]
				local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
				local ap = Vector3.new(position.X - a.X, 0, position.Z - a.Z)
				local t = math.clamp(ap:Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
				if (ap - ab * t).Magnitude < 4.6 then
					return line, i
				end
			end
		end
	end
	return nil, 0
end

local function guardTracks()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and (humanoid.Health or 100) > 0 and not humanoid.SeatPart and root.Position.Y < Metro.Underground then
			local line = onTrack(root.Position - Vector3.new(0, 3, 0))
			local train = line and trains[line.Id]
			local inCar = train ~= nil and (train.Passengers[player] ~= nil or carAt(train, root.Position) ~= nil)
			if line and not inCar then
				-- Al andén de la estación de esa línea más cercana (a unos pasos del borde)
				local best, bestD = nil, math.huge
				for _, id in line.Stations do
					local d = (Metro.center(id, line) - root.Position).Magnitude
					if d < bestD then
						best, bestD = id, d
					end
				end
				if best then
					local frame = Metro.frame(best, line)
					root.AssemblyLinearVelocity = Vector3.zero
					character:PivotTo(frame * CFrame.new(9, 3, 0))
					Notify:FireClient(player, "Error", "⚠️ ¡No se puede andar por la vía! Espera al tren en el andén.")
				end
			end
		end
	end
end

local function checkPassengers()
	for player, train in riding do
		local humanoid = humanoidOf(player)
		local root = rootOf(player)
		if not player.Parent or not humanoid or humanoid.Health <= 0 or not root then
			stopRiding(player)
		elseif not isTrainSeat(train, humanoid.SeatPart) and not carAt(train, root.Position) then
			if train.Phase == "Dwell" then
				local id = train.Line.Stations[train.Index]
				stopRiding(player)
				StoryEvents.emit(player, "RodeMetro", { Station = id })
			elseif (root.Position - train.Cars[1].Root.Position).Magnitude > 200 then
				stopRiding(player) -- (se ha ido del tren de otra forma: teletransporte, muerte…)
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

-- Cuándo cruzó cada jugador un torno (un segundo toque de Interactuar no le devuelve al otro lado)
local passedGateAt: { [Player]: number } = {}
Players.PlayerRemoving:Connect(function(player)
	passedGateAt[player] = nil
end)

-- Al otro lado del torno, de espaldas a él (el cartel del otro lado no le llega: Metro.Gate)
local function crossGate(player: Player, gate: BasePart): boolean
	local through = gate:GetAttribute("Through")
	if typeof(through) ~= "Vector3" then
		return false
	end
	local root = rootOf(player)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end
	teleport(player, Metro.gateLanding(gate.Position, through))
	return true
end

-- ¿Está en el lado desde el que se usa el torno? (desde el otro lado no hace nada: ni cobra ni te mueve)
local function onUseSide(player: Player, gate: BasePart): boolean
	local through = gate:GetAttribute("Through")
	local root = rootOf(player)
	return typeof(through) == "Vector3" and root ~= nil and Metro.gateSide(gate.Position, through, root.Position) < 0
end

local function onGate(player: Player, gate: BasePart)
	-- (ya está en el andén, o acaba de salir por el torno de salida: ni le vuelve a pasar ni le cobra)
	if not onUseSide(player, gate) or os.clock() - (passedGateAt[player] or -math.huge) < Metro.Gate.Grace then
		return
	end
	local job = player:GetAttribute("Job")
	local pass = MetroService.passOf(player)
	local mode = Metro.gatePass({
		Stage = player:GetAttribute("LifeStage"),
		FreeJob = typeof(job) == "string" and Metro.FreeJobs[job] == true,
		Pass = pass ~= nil,
		Tickets = InventoryService.count(player, Metro.TicketItem),
		Tester = TesterService.bypass(player),
	})
	if not mode then
		Notify:FireClient(player, "Info", "Necesitas un billete o un abono: cómpralo en las máquinas azules del vestíbulo 🎫")
		return
	end
	if mode == "Billete" then
		InventoryService.remove(player, Metro.TicketItem, 1)
	end
	crossGate(player, gate)
	passedGateAt[player] = os.clock()
	player:SetAttribute("MetroTicket", true) -- (para el revisor: tiene billete validado)
	StoryEvents.emit(player, "MetroGate", { Station = gate:GetAttribute("Station"), Pass = if mode == "Abono" and pass then pass.Id else mode })
	if mode == "Gratis" then
		-- Los niños viajan gratis (con un adulto o solos: en Valmar el metro es seguro)
		Notify:FireClient(player, "Info", "🎫 Los niños viajan gratis en el metro. ¡Buen viaje!")
	elseif mode == "Abono" and pass then
		Notify:FireClient(player, "Info", ("%s %s: ¡buen viaje!"):format(pass.Icon, pass.Name))
	elseif mode == "Servicio" then
		Notify:FireClient(player, "Info", "🚇 Vas de servicio: el metro es gratis para ti.")
	elseif mode == "Pruebas" then
		Notify:FireClient(player, "Info", "🧪 Modo pruebas: pasas el torno sin billete.")
	end
end

local function onGateExit(player: Player, gate: BasePart)
	-- Recién pasado el torno de entrada, un segundo toque de Interactuar no le devuelve al vestíbulo
	if os.clock() - (passedGateAt[player] or -math.huge) < Metro.Gate.Grace or not onUseSide(player, gate) then
		return
	end
	crossGate(player, gate)
	passedGateAt[player] = os.clock()
	player:SetAttribute("MetroTicket", nil)
end

-- Cartel de un torno: flota delante, en el lado desde el que se usa, y llega poco (Metro.Gate)
local function gatePrompt(gate: BasePart, action: string, object: string, reach: number): ProximityPrompt
	local through = gate:GetAttribute("Through")
	local holder: Instance = gate
	if typeof(through) == "Vector3" then
		local att = Instance.new("Attachment")
		att.Name = "GatePrompt"
		att.Position = gate.CFrame:PointToObjectSpace(Metro.gatePromptAt(gate.Position, through))
		att.Parent = gate
		holder = att
	end
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0.3
	p.MaxActivationDistance = reach
	p.RequiresLineOfSight = false
	p:SetAttribute("PromptPriority", Metro.Gate.Priority)
	p.Parent = holder
	return p
end

-- ¿Está junto a una máquina de billetes o a una taquilla? (las dos venden lo mismo)
local function nearTicketSeller(player: Player): boolean
	local root = rootOf(player)
	if not root then
		return false
	end
	for _, tag in { "MetroTicketMachine", "MetroTicketBooth" } do
		for _, m in tagged(tag) do
			if (m.Position - root.Position).Magnitude < 14 then
				return true
			end
		end
	end
	return false
end

local function onBuyTicket(player: Player, id: any)
	if not nearTicketSeller(player) then
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
-- Abonos (se guardan en data.Metro: PassUntil = hora real a la que caduca)
---------------------------------------------------------------------
local function passSeconds(days: number): number
	local Config = require(ReplicatedStorage.Shared.Config)
	return days * (Config.DayLengthMinutes or 20) * 60
end

-- El abono en vigor del jugador (o nil)
function MetroService.passOf(player: Player): { [string]: any }?
	local data = DataService.get(player)
	local m = data and data.Metro
	if not m or not m.PassKind or m.PassKind == "" or (m.PassUntil or 0) <= os.time() then
		return nil
	end
	return Metro.passById[m.PassKind]
end

local function syncPass(player: Player)
	local data = DataService.get(player)
	local m = data and data.Metro
	local pass = MetroService.passOf(player)
	player:SetAttribute("MetroPass", pass and pass.Name or nil)
	player:SetAttribute("MetroPassUntil", if pass and m then m.PassUntil else nil)
end

local function isWorker(player: Player): boolean
	if player:GetAttribute("Job") then
		return true
	end
	local data = DataService.get(player)
	if data and data.Careers then
		for _ in data.Careers do
			return true
		end
	end
	return data ~= nil and data.Stats ~= nil and (data.Stats.TasksDone or 0) > 0
end

local function onBuyPass(player: Player, id: any)
	local pass = typeof(id) == "string" and Metro.passById[id]
	if not pass or not nearTicketSeller(player) then
		return
	end
	if pass.Student and not Metro.StudentStages[player:GetAttribute("LifeStage") or ""] then
		Notify:FireClient(player, "Error", "El abono estudiante es para estudiantes de instituto o universidad.")
		return
	end
	if pass.Worker and not isWorker(player) then
		Notify:FireClient(player, "Error", "El abono trabajador es para quien tiene trabajo. ¡Busca uno en el móvil!")
		return
	end
	local data = DataService.get(player)
	if not data then
		return
	end
	if not DataService.spend(player, pass.Price) then
		Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
		return
	end
	data.Metro = data.Metro or {}
	-- Si aún le queda abono (del tipo que sea), los días nuevos se suman: no se pierde lo que quedaba
	local from = math.max(os.time(), if data.Metro.PassKind then data.Metro.PassUntil or 0 else 0)
	data.Metro.PassKind = pass.Id
	data.Metro.PassUntil = from + passSeconds(pass.Days)
	syncPass(player)
	Notify:FireClient(player, "Success", ("%s %s: pasa por los tornos sin billete (%d %s de juego)."):format(pass.Icon, pass.Name, pass.Days, if pass.Days == 1 then "día" else "días"))
	StoryEvents.emit(player, "BoughtItem", { ShopId = "MetroAbono", ItemId = pass.Id })
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
				Notify:FireClient(player, "Error", "Te has quedado sin energía. Come algo o duerme antes de seguir trabajando.")
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
		Notify:FireClient(player, "Error", "Te falta energía o tienes demasiada hambre para trabajar.")
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
local boothClerks: { [BasePart]: Model } = {} -- taquillero/a de cada taquilla
local BOOTH_LINES = { "¡Hola! ¿Qué billete le pongo?", "Buenas. ¿Sencillo, bonometro o abono?", "¿A dónde va hoy?", "Si viaja mucho, el abono le sale más barato." }
local BOOTH_LOOKS = {
	{ Name = "Taquillera", Look = { Shirt = rgb(30, 90, 170), Pants = rgb(40, 44, 60), LongSleeves = true, LongHair = true } },
	{ Name = "Taquillero", Look = { Shirt = rgb(30, 90, 170), Pants = rgb(40, 44, 60), LongSleeves = true } },
}

local function anyoneNear(position: Vector3, range: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - position).Magnitude < range then
			return true
		end
	end
	return false
end

-- Bancos del andén: cada banco tiene dos sitios (benchUsed[banco][sitio] = quien está sentado)
local benchUsed: { [BasePart]: { [number]: Model } } = {}
local benchOf: { [Model]: { any } } = setmetatable({}, { __mode = "k" }) :: any
local benchCache: { [BasePart]: { BasePart } } = {}
local BENCH_SLOTS = { -1.2, 1.2 }

local function benchesNear(alight: BasePart): { BasePart }
	local cached = benchCache[alight]
	if cached then
		return cached
	end
	local list = {}
	local parent = alight.Parent
	if parent then
		for _, b in parent:GetChildren() do
			if b:IsA("BasePart") and b.Name == "Bench" and math.abs(b.Position.Y - alight.Position.Y) < 6 and (b.Position - alight.Position).Magnitude < 90 then
				table.insert(list, b)
			end
		end
	end
	benchCache[alight] = list
	return list
end

-- Dónde se sienta uno en ese sitio del banco: la superficie del asiento, mirando hacia la vía
local function benchSeat(alight: BasePart, bench: BasePart, slot: number): CFrame
	local along = if bench.Size.Z >= bench.Size.X then Vector3.new(0, 0, BENCH_SLOTS[slot]) else Vector3.new(BENCH_SLOTS[slot], 0, 0)
	local top = bench.CFrame * CFrame.new(along + Vector3.new(0, bench.Size.Y / 2, 0))
	local d = -alight.CFrame.RightVector -- (la vía queda a -X de la marca, recto desde el banco)
	d = Vector3.new(d.X, 0, d.Z)
	return CFrame.new(top.Position) * CFrame.Angles(0, math.atan2(-d.X, -d.Z), 0)
end

-- Un sitio libre en los bancos (sin nadie sentado ni ningún jugador a menos de 5 studs)
local function freeBench(alight: BasePart): (BasePart?, number?)
	local options = {}
	for _, bench in benchesNear(alight) do
		local used = benchUsed[bench] or {}
		for slot in BENCH_SLOTS do
			local who = used[slot]
			if not (who and who.Parent) and not anyoneNear(benchSeat(alight, bench, slot).Position, 5) then
				table.insert(options, { bench, slot })
			end
		end
	end
	if #options == 0 then
		return nil, nil
	end
	local pick = options[math.random(1, #options)]
	return pick[1], pick[2]
end

local function sitOnBench(npc: Model, alight: BasePart, bench: BasePart, slot: number)
	benchUsed[bench] = benchUsed[bench] or {}
	benchUsed[bench][slot] = npc
	benchOf[npc] = { bench, slot }
	local seatCf = benchSeat(alight, bench, slot)
	pcall(Npc.sitAt, npc, seatCf)
	local root = npc.PrimaryPart
	if root then
		root.CFrame = CFrame.new(root.Position) * seatCf.Rotation -- (mirando a la vía, venga de donde venga)
	end
	if math.random() < 0.5 then
		pcall(Npc.work, npc, if math.random() < 0.5 then "Phone" else "Book")
	end
end

-- Se levanta del banco (pies delante del asiento)
local function leaveBench(npc: Model)
	local b = benchOf[npc]
	if not b then
		return
	end
	benchOf[npc] = nil
	local bench, slot = b[1] :: BasePart, b[2] :: number
	if benchUsed[bench] and benchUsed[bench][slot] == npc then
		benchUsed[bench][slot] = nil
	end
	pcall(Npc.work, npc, nil)
	local root = npc.PrimaryPart
	local front = if root then root.Position + root.CFrame.LookVector * 1.6 else bench.Position
	pcall(Npc.stand, npc, Npc.feetAt(front, 6))
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
		if active and #list < (schedule.Crowd or 3) then
			local bench, slot = nil, nil
			-- (el primero que llega a un andén vacío se sienta si hay banco; luego, algunos)
			if #list == 0 or math.random() < 0.4 then
				bench, slot = freeBench(alight)
			end
			-- Un sitio libre del andén: entre el borde y los bancos/la máquina (x -3..1 de la marca),
			-- lejos de los extremos, sin pisar a otro viajero ni aparecer al lado de un jugador; de pie
			-- en el suelo (la marca va a media altura: antes flotaban 3 studs)
			local spot: CFrame? = nil
			for _ = 1, if bench then 0 else 6 do
				local cf = alight.CFrame * CFrame.new(math.random(-30, 10) / 10, 0, math.random(-50, 50))
				local free = not anyoneNear(cf.Position, 5)
				for _, other in list do
					local root = other.PrimaryPart
					if root and Vector3.new(root.Position.X - cf.X, 0, root.Position.Z - cf.Z).Magnitude < 3.5 then
						free = false
						break
					end
				end
				if free then
					spot = cf
					break
				end
			end
			if bench and slot then
				-- Sentado en un banco esperando el tren
				local seatCf = benchSeat(alight, bench, slot)
				local npc = Npc.create("Viajero", alight.Parent :: Instance, seatCf, nil)
				sitOnBench(npc, alight, bench, slot)
				table.insert(list, npc)
			elseif spot then
				local feet = Npc.feetAt(spot.Position, alight.Size.Y / 2 + 4)
				local npc = Npc.create("Viajero", alight.Parent :: Instance, CFrame.new(feet) * spot.Rotation, nil)
				Npc.face(npc, (alight.CFrame * CFrame.new(-20, 0, 0)).Position)
				table.insert(list, npc)
			end
		elseif active and #list > 0 and math.random() < 0.05 then
			-- De vez en cuando, uno que espera de pie se va andando a sentarse a un banco libre
			local npc = list[math.random(1, #list)]
			local bench, slot = freeBench(alight)
			if bench and slot and not benchOf[npc] and not Npc.isWalking(npc) and npc.PrimaryPart then
				benchUsed[bench] = benchUsed[bench] or {}
				benchUsed[bench][slot] = npc -- (reservado mientras va)
				benchOf[npc] = { bench, slot }
				local seatCf = benchSeat(alight, bench, slot)
				local front = Npc.feetAt((seatCf * CFrame.new(0, 0, -1.4)).Position, 6)
				task.spawn(function()
					pcall(Npc.walkTo, npc, { front }, 5)
					if npc.Parent and benchOf[npc] and benchOf[npc][1] == bench then
						sitOnBench(npc, alight, bench, slot)
					end
				end)
			end
		elseif not active then
			for _, npc in list do
				benchOf[npc] = nil
				npc:Destroy()
			end
			table.clear(list)
		end
	end
	-- Taquillas: una persona detrás del mostrador cuando hay alguien cerca (nunca aparece al lado de
	-- nadie; se va cuando ya no queda nadie que lo vea)
	for _, counter in tagged("MetroTicketBooth") do
		local spot = counter:GetAttribute("StaffSpot")
		if typeof(spot) == "Vector3" then
			local active = anyoneNear(counter.Position, 150)
			local clerk = boothClerks[counter]
			if active and not (clerk and clerk.Parent) and not anyoneNear(spot, 5) then
				local who = BOOTH_LOOKS[math.random(1, #BOOTH_LOOKS)]
				local feet = Npc.feetAt(spot)
				local look = Vector3.new(counter.Position.X, feet.Y, counter.Position.Z)
				local ok, npc = pcall(Npc.create, who.Name, counter.Parent :: Instance, if (look - feet).Magnitude > 0.1 then CFrame.lookAt(feet, look) else CFrame.new(feet), who.Look)
				if ok and npc then
					local humanoid = npc:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.DisplayName = who.Name
						-- (el nombre lo pinta el cliente: Controllers/NameTags)
						humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					end
					npc:AddTag("NamedActor")
					pcall(Npc.work, npc, "Type")
					boothClerks[counter] = npc
				end
			elseif not active and clerk then
				clerk:Destroy()
				boothClerks[counter] = nil
			end
		end
	end
	for _, counter in tagged("MetroShop") do
		local spot = counter:GetAttribute("StaffSpot")
		if typeof(spot) == "Vector3" then
			local active = anyoneNear(counter.Position, 150)
			if active and not clerks[counter] and not anyoneNear(spot, 5) then
				-- (de pie en el suelo detrás del mostrador: la marca va un poco por encima, y Npc.create
				-- ya sube la raíz a la altura de la cadera; con +3 flotaba)
				local feet = Npc.feetAt(spot)
				local look = Vector3.new(counter.Position.X, feet.Y, counter.Position.Z)
				local npc = Npc.create("Npc_Dependiente", counter.Parent :: Instance, if (look - feet).Magnitude > 0.1 then CFrame.lookAt(feet, look) else CFrame.new(feet), nil)
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
	-- Los que suben andan hasta la puerta más cercana del tren y entran (antes se esfumaban en el andén)
	local doors = {}
	for _, board in tagged("MetroBoard") do
		if board:GetAttribute("Station") == id and board:GetAttribute("Line") == train.Line.Id then
			table.insert(doors, board)
		end
	end
	for i = #list, 1, -1 do
		if math.random() < 0.6 then
			local npc = table.remove(list, i) :: Model
			leaveBench(npc) -- (si estaba sentado, primero se levanta)
			local root = npc.PrimaryPart
			local best, bestD = nil, math.huge
			for _, door in doors do
				local d = if root then (door.Position - root.Position).Magnitude else 0
				if d < bestD then
					best, bestD = door, d
				end
			end
			if best and root and bestD < 40 then
				task.spawn(function()
					task.wait(math.random() * 0.8)
					local ground = Npc.feetAt(Vector3.new(best.Position.X, root.Position.Y, best.Position.Z), 8)
					pcall(Npc.walkTo, npc, { ground }, 6)
					if npc.Parent then
						npc:Destroy() -- (ya dentro del coche)
					end
				end)
			else
				npc:Destroy()
			end
		end
	end
end

---------------------------------------------------------------------
-- Viajeros NPC dentro del tren (van sentados; los clientes los mueven con su coche)
---------------------------------------------------------------------
local RIDER_LINES = {
	"Voy tardísimo al trabajo…", "¿Has visto el partido de ayer?", "La próxima es la mía.", "Qué sueño tengo hoy.",
	"Mira este vídeo, jajaja 😂", "¿Sabes si para en Plaza Mayor?", "Hoy hay examen, qué nervios.", "Me encanta ir en metro, se lee muy bien.",
	"Buf, qué lleno va hoy.", "Luego quedamos en la galería, ¿vale?",
}
local RIDER_ICONS = { "📱", "📖", "🎧", "📰", "☕" }
local riderSeat: { [Model]: Seat } = {}

local function removeRider(train: Train, index: number)
	local npc = table.remove(train.Riders, index) :: Model
	local seat = riderSeat[npc]
	riderSeat[npc] = nil
	if seat then
		seat:SetAttribute("NpcRider", nil)
	end
	if npc.Parent then
		npc:Destroy()
	end
end

local function spawnRider(train: Train): boolean
	local options = {}
	for k, car in train.Cars do
		for _, seat in car.Seats do
			if not seat.Occupant and not seat:GetAttribute("NpcRider") then
				table.insert(options, { K = k, Car = car, Seat = seat })
			end
		end
	end
	if #options == 0 then
		return false
	end
	local pick = options[math.random(1, #options)]
	local seat = pick.Seat
	local npc = Npc.create("Viajero", seat.Parent :: Instance, seat.CFrame, nil)
	pcall(Npc.sit, npc, seat)
	seat:SetAttribute("NpcRider", true)
	riderSeat[npc] = seat
	npc:SetAttribute("MetroLine", train.Line.Id)
	npc:SetAttribute("MetroCar", pick.K)
	npc:SetAttribute("MetroOffset", pick.Car.Root.CFrame:ToObjectSpace(npc:GetPivot()))
	npc:AddTag("MetroRider")
	if math.random() < 0.5 then
		pcall(Npc.icon, npc, RIDER_ICONS[math.random(1, #RIDER_ICONS)])
	end
	table.insert(train.Riders, npc)
	return true
end

-- Punto del pasillo de un coche (en el suelo, a lo largo del coche en z)
local function aisle(car: Car, z: number): Vector3
	return (car.Root.CFrame * CFrame.new(0, car.Root.Size.Y / 2, z)).Position
end

-- Un viajero se levanta y se va andando por el pasillo (y el paso entre coches) a un asiento libre del
-- coche de al lado. Solo con el tren parado y tiempo de sobra; mientras va, el cliente no lo mueve con
-- el coche (se le quita MetroRider) y placeTrain tampoco (ChangingCar).
local function changeCar(train: Train, npc: Model): boolean
	local k = npc:GetAttribute("MetroCar") or 1
	local oldSeat = riderSeat[npc]
	local options = {}
	for _, k2 in { k - 1, k + 1 } do
		local car = train.Cars[k2]
		if car then
			for _, seat in car.Seats do
				if not seat.Occupant and not seat:GetAttribute("NpcRider") then
					table.insert(options, { K = k2, Seat = seat })
				end
			end
		end
	end
	local from, pick = train.Cars[k], options[math.random(1, math.max(1, #options))]
	if not from or not oldSeat or not pick or train.Phase ~= "Dwell" or npc:GetAttribute("ChangingCar") then
		return false
	end
	local to = train.Cars[pick.K]
	local seat = pick.Seat :: Seat
	-- Cambia de asiento (el nuevo queda reservado mientras va)
	oldSeat:SetAttribute("NpcRider", nil)
	seat:SetAttribute("NpcRider", true)
	riderSeat[npc] = seat
	npc:SetAttribute("ChangingCar", true)
	npc:RemoveTag("MetroRider")
	pcall(Npc.icon, npc, nil)
	local L = Metro.CarLength / 2
	local sFrom = if from.Root.CFrame:PointToObjectSpace(to.Root.Position).Z > 0 then 1 else -1
	local sTo = if to.Root.CFrame:PointToObjectSpace(from.Root.Position).Z > 0 then 1 else -1
	local path = {
		aisle(from, from.Root.CFrame:PointToObjectSpace(oldSeat.Position).Z),
		aisle(from, sFrom * (L - 1)),
		aisle(to, sTo * (L - 1)),
		aisle(to, to.Root.CFrame:PointToObjectSpace(seat.Position).Z),
	}
	pcall(Npc.stand, npc, path[1])
	task.spawn(function()
		pcall(Npc.walkTo, npc, path, 6)
		if npc.Parent and riderSeat[npc] == seat then
			pcall(Npc.sit, npc, seat)
			npc:SetAttribute("MetroCar", pick.K)
			npc:SetAttribute("MetroOffset", to.Root.CFrame:ToObjectSpace(npc:GetPivot()))
			npc:SetAttribute("ChangingCar", nil)
			npc:AddTag("MetroRider")
		end
	end)
	return true
end

-- En cada parada: unos bajan y otros suben (solo si hay algún jugador cerca, para no gastar)
function refreshRiders(train: Train)
	for i = #train.Riders, 1, -1 do
		if not train.Riders[i].Parent or math.random() < 0.35 then
			removeRider(train, i)
		end
	end
	local watched = next(train.Passengers) ~= nil or #playersNear(train.Cars[math.ceil(#train.Cars / 2)].Root.Position, 260) > 0
	if not watched then
		for i = #train.Riders, 1, -1 do
			removeRider(train, i)
		end
		return
	end
	-- De vez en cuando alguien se cambia de vagón (si el tren va a estar parado lo bastante)
	if #train.Riders > 0 and train.Timer > 9 and math.random() < 0.3 then
		changeCar(train, train.Riders[math.random(1, #train.Riders)])
	end
	local want = schedule.Riders or 4
	if train.Full and os.clock() < train.Full then
		want = 99 -- (tren lleno: todos los asientos ocupados)
	end
	for _ = 1, 30 do
		if #train.Riders >= want or not spawnRider(train) then
			break
		end
	end
end

local function riderChatter()
	for _, train in trains do
		if next(train.Passengers) ~= nil and #train.Riders > 0 and math.random() < 0.08 then
			local npc = train.Riders[math.random(1, #train.Riders)]
			if npc.Parent then
				pcall(Npc.say, npc, RIDER_LINES[math.random(1, #RIDER_LINES)], 4)
			end
		end
	end
end

---------------------------------------------------------------------
-- Horarios (con el reloj del juego) e incidencias
---------------------------------------------------------------------
local nextIncident = os.clock() + math.random(Metro.IncidentEvery[1], Metro.IncidentEvery[2])

local function updateSchedule()
	local ok, date = pcall(GameClock.now)
	local sch = Metro.scheduleAt(if ok and date then date.ClockTime else 12)
	if sch ~= schedule then
		schedule = sch
		for _, train in trains do
			train.DwellTime = sch.Dwell
			train.Layover = sch.Layover
			publish(train)
		end
	end
	if stateFolder then
		stateFolder:SetAttribute("Schedule", sch.Id)
		stateFolder:SetAttribute("ScheduleName", sch.Name)
		stateFolder:SetAttribute("Night", sch.Night == true)
	end
end

local function publishIncidents()
	local lines = {}
	for _, inc in incidents do
		table.insert(lines, table.concat({ inc.Kind, inc.Line, inc.Station, inc.Icon, inc.Text, inc.Alt or "" }, "|"))
	end
	if stateFolder then
		stateFolder:SetAttribute("Incidents", table.concat(lines, "\n"))
	end
end

-- Lanza una incidencia (kind = Metro.Incidents; sin línea/estación, al azar)
function MetroService.startIncident(kind: string, lineId: string?, stationId: string?): { [string]: any }?
	local def = Metro.Incidents[kind]
	if not def then
		return nil
	end
	local line = if lineId then Metro.lineById[lineId] else Metro.Lines[math.random(1, #Metro.Lines)]
	local train = line and trains[line.Id]
	if not line or not train then
		return nil
	end
	local candidates = {}
	for _, id in line.Stations do
		if not Metro.Stations[id].Hub then
			table.insert(candidates, id)
		end
	end
	local station = stationId or candidates[math.random(1, #candidates)]
	local inc: { [string]: any } = { Kind = kind, Line = line.Id, Station = station, Icon = def.Icon, Until = os.clock() + (def.Seconds or 120) }
	local other = nil
	for _, l in Metro.Lines do
		if l.Id ~= line.Id then
			other = l
		end
	end
	if kind == "Retraso" or kind == "Seguridad" then
		local hold = math.random(def.Hold[1], def.Hold[2])
		train.Hold = (train.Hold or 0) + hold
		inc.Until = os.clock() + hold + 150
		if kind == "Retraso" then
			inc.Text = def.Text:format(math.max(1, math.ceil(hold / 60)), line.Name)
		else
			inc.Station = train.Line.Stations[train.Index]
			inc.Text = def.Text:format(stationName(inc.Station))
		end
		inc.Alt = if other then "Se recomienda utilizar la " .. other.Name .. " si te sirve." else ""
	elseif kind == "Averia" then
		train.Speed = Metro.Speed * def.Slow
		inc.Text = def.Text:format(line.Name)
		inc.Alt = if other then "Se recomienda utilizar la " .. other.Name .. "." else ""
	elseif kind == "Lleno" then
		train.Full = inc.Until
		inc.Text = def.Text:format(line.Name)
		inc.Alt = "Puedes ir de pie o esperar al siguiente."
	else -- Cerrada / Mantenimiento
		closedUntil[station] = inc.Until
		inc.Text = def.Text:format(stationName(station))
		local i = table.find(line.Stations, station) :: number
		local near = line.Stations[if i > 1 then i - 1 else i + 1]
		inc.Alt = ("Usa la estación %s y sigue andando."):format(stationName(near))
	end
	table.insert(incidents, inc)
	publishIncidents()
	Remote:FireAllClients("Incident", { Kind = kind, Line = inc.Line, Station = inc.Station, Icon = inc.Icon, Text = inc.Text, Alt = inc.Alt })
	-- Aviso por megafonía a los viajeros de la línea
	announce(train, "Atención: " .. inc.Text .. ".", true, nil)
	return inc
end

-- Policía en las incidencias de seguridad: una o dos agentes bajan al andén (entrando por los tornos),
-- van hasta las puertas del coche de en medio, avisan a la gente y se quedan vigilando. Cuando acaba la
-- incidencia se vuelven andando y se van cuando nadie las ve (StaffService.retireNpc).
local POLICE_LOOK = { Shirt = rgb(40, 60, 110), Pants = rgb(30, 35, 60), LongSleeves = true }
local POLICE_LINES = { "Policía. Mantengan la calma, por favor.", "Aléjense de las puertas: estamos revisando el tren.", "Un momento, enseguida podrá salir el tren.", "Todo controlado. Gracias por su paciencia." }
local POLICE_BYE = { "Todo en orden. ¡Buen viaje!", "Ya está, pueden continuar.", "Falsa alarma. ¡Que tengan buen día!" }

local function spawnPolice(inc: { [string]: any })
	local alight = findTagged("MetroAlight", { Station = inc.Station, Line = inc.Line })
	if not alight or not anyoneNear(alight.Position, 150) then
		return -- (sin nadie cerca no hace falta: vendrán cuando llegue alguien)
	end
	inc.Police = {}
	local floor = alight.Size.Y / 2 + 4
	-- De dónde vienen (los tornos o las puntas del andén) y adónde van (puertas del coche de en medio)
	local starts = { { 2.5, -4 }, { 2.5, 4 }, { 2, -34 }, { 2, 34 }, { 2, -60 }, { 2, 60 } }
	local goals = { { -4, -Metro.CarLength / 4 }, { -4, Metro.CarLength / 4 } }
	local count = math.random(1, 2)
	for n = 1, count do
		local from: Vector3? = nil
		for _, s0 in starts do
			local p = (alight.CFrame * CFrame.new(s0[1], 0, s0[2])).Position
			if not anyoneNear(p, 5) then
				from = p
				table.remove(starts, table.find(starts, s0))
				break
			end
		end
		if not from then
			break
		end
		local feet = Npc.feetAt(from, floor)
		local goal = Npc.feetAt((alight.CFrame * CFrame.new(goals[n][1], 0, goals[n][2])).Position, floor)
		local ok, npc = pcall(Npc.create, "Policía", alight.Parent :: Instance, CFrame.new(feet), POLICE_LOOK)
		if ok and npc then
			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayName = "Policía"
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			-- (sin NamedActor: un agente sin nombre propio no lleva cartel con su nombre encima)
			npc:SetAttribute("MetroPolice", true)
			npc:SetAttribute("Home", feet)
			pcall(Npc.icon, npc, "👮")
			table.insert(inc.Police, npc)
			task.spawn(function()
				task.wait(n * 0.6)
				pcall(Npc.walkTo, npc, { goal }, 8)
				if npc.Parent and not StaffService.isLeaving(npc) then
					pcall(Npc.face, npc, (alight.CFrame * CFrame.new(-20, 0, goals[n][2])).Position)
					pcall(Npc.say, npc, POLICE_LINES[math.random(1, #POLICE_LINES)], 5)
					pcall(Npc.work, npc, "Guard")
				end
			end)
		end
	end
end

local function retirePolice(inc: { [string]: any })
	for _, npc in inc.Police or {} do
		if npc.Parent then
			local home = npc:GetAttribute("Home")
			task.spawn(StaffService.retireNpc, npc, if typeof(home) == "Vector3" then home else nil, POLICE_BYE[math.random(1, #POLICE_BYE)])
		end
	end
	inc.Police = nil
end

local function incidentTick()
	local now = os.clock()
	for _, inc in incidents do
		if inc.Kind == "Seguridad" and not inc.Police then
			spawnPolice(inc)
		end
	end
	for i = #incidents, 1, -1 do
		local inc = incidents[i]
		if now > inc.Until then
			table.remove(incidents, i)
			retirePolice(inc)
			local train = trains[inc.Line]
			if train and inc.Kind == "Averia" then
				train.Speed = Metro.Speed
			end
			closedUntil[inc.Station] = nil
			publishIncidents()
			Remote:FireAllClients("IncidentEnd", { Kind = inc.Kind, Line = inc.Line })
		end
	end
	if now >= nextIncident then
		nextIncident = now + math.random(Metro.IncidentEvery[1], Metro.IncidentEvery[2])
		if #incidents == 0 and math.random() < Metro.IncidentChance then
			local kinds = {}
			for id, def in Metro.Incidents do
				if not def.NightOnly or schedule.Night then
					table.insert(kinds, id)
				end
			end
			table.sort(kinds)
			MetroService.startIncident(kinds[math.random(1, #kinds)])
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

-- Menú de billetes y abonos (máquinas y taquillas)
local function openTickets(player: Player)
	syncPass(player)
	Remote:FireClient(player, "Tickets", Metro.Tickets, { Passes = Metro.Passes, Current = player:GetAttribute("MetroPass"), Until = player:GetAttribute("MetroPassUntil"), Now = os.time() })
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
		gatePrompt(gate, "Pasar (billete)", "🎫 Torno", Metro.Gate.Reach).Triggered:Connect(function(player)
			onGate(player, gate)
		end)
	end,
	MetroGateExit = function(gate)
		gatePrompt(gate, "Salir", "🚪 Salida", Metro.Gate.ExitReach).Triggered:Connect(function(player)
			onGateExit(player, gate)
		end)
	end,
	MetroTicketMachine = function(machine)
		prompt(machine, "Comprar billete", "🎫 Máquina de billetes", 0.3, 8).Triggered:Connect(openTickets)
	end,
	MetroTicketBooth = function(counter)
		-- La taquilla abre la misma compra que la máquina; el taquillero/a saluda
		prompt(counter, "Comprar billete", "🎫 Taquilla", 0.3, 8).Triggered:Connect(function(player)
			local clerk = boothClerks[counter]
			if clerk and clerk.Parent then
				pcall(Npc.say, clerk, BOOTH_LINES[math.random(1, #BOOTH_LINES)], 4)
				local root = rootOf(player)
				if root then
					pcall(Npc.face, clerk, root.Position)
				end
			end
			openTickets(player)
		end)
	end,
	MetroBoard = function(marker)
		local line = Metro.lineById[marker:GetAttribute("Line")]
		local p = prompt(marker, "Subir al metro", "🚇 " .. (if line then line.Name else "Metro"), 0.2, 7)
		p:SetAttribute("PromptPriority", Metro.Gate.Priority)
		p.Triggered:Connect(function(player)
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
		prompt(counter, "Objetos Perdidos", "👛 Ventanilla", 0.4, 9).Triggered:Connect(onLostOffice)
	end,
	MetroMapSign = function(sign)
		prompt(sign, "Ver plano del metro", "🗺️ Plano de la red", 0.2, 10).Triggered:Connect(function(player)
			Remote:FireClient(player, "OpenMap")
		end)
	end,
}

function MetroService.init()
	stateFolder = ReplicatedStorage:FindFirstChild("MetroState") :: Folder?
	if not stateFolder then
		local f = Instance.new("Folder")
		f.Name = "MetroState"
		pcall(function()
			f.Parent = ReplicatedStorage
		end)
		stateFolder = f
	end
	updateSchedule()
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
		elseif action == "BuyPass" then
			onBuyPass(player, a)
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
	-- El abono no caduca mientras estás desconectado: se corre su caducidad el tiempo que estuvo fuera
	-- (uno que ya había caducado al irse sigue caducado)
	DataService.onLoaded(function(player, data)
		local m = data.Metro
		local away = if DataService.offlineSeconds then DataService.offlineSeconds(player) else 0
		if type(m) == "table" and type(m.PassUntil) == "number" and m.PassUntil > 0 and away > 0 then
			m.PassUntil += away
		end
		syncPass(player)
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
				guardTracks()
				updateDisplays()
				ambientTick()
				updateSchedule()
				incidentTick()
				riderChatter()
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
MetroService._incidents = incidents
MetroService._closed = closedUntil
MetroService._schedule = function()
	return schedule
end
MetroService._checkPassengers = function()
	checkPassengers()
end
MetroService._refreshRiders = function(train: Train)
	refreshRiders(train)
end
MetroService._changeCar = changeCar
MetroService._removeRider = removeRider
MetroService._incidentTick = function()
	incidentTick()
end
MetroService._ambientTick = function()
	ambientTick()
end
MetroService._trains = trains
MetroService._riding = riding
MetroService._missions = missions
MetroService._step = step
MetroService._guardTracks = guardTracks

return MetroService
