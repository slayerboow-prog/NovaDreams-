-- BusService: autobús urbano de Valmar (línea L1 circular) y el oficio de conductor.
--
-- PASAJEROS
--   * La L1 pasa por todas las paradas (las marquesinas de cada barrio y del centro) siguiendo
--     las calles (BusRoute). En cada parada abre las puertas unos segundos.
--   * Con las puertas abiertas, acércate y pulsa "Subir" (billete: Gameplay.Bus.Fare). Te sientas
--     dentro y ves la próxima parada. Para bajarte, salta cuando el autobús esté parado.
--
-- CONDUCTOR (oficio)
--   * Te contratan en la Estación de Autobuses (el conductor que hay en la puerta) o en la parada
--     del centro. Te dan tu propio autobús y lo conduces tú (W/A/S/D, como cualquier vehículo).
--   * La línea azul te lleva a la siguiente parada: para al lado (despacio) y se abren las puertas.
--     Cobras por cada parada y por cada pasajero que sube. Hace falta el carnet de coche.
--   * Si no hay conductores, los autobuses los lleva el juego: el servicio nunca se para.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Rides = require(script.Parent.Parent.World.Kit.Rides)
local BusRoute = require(script.Parent.Parent.World.BusRoute)
local DataService = require(script.Parent.DataService)
local LifeService = require(script.Parent.LifeService)
local NeedsService = require(script.Parent.NeedsService)
local MonetizationService = require(script.Parent.MonetizationService)
local VehicleService = require(script.Parent.VehicleService)
local JobService = require(script.Parent.JobService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local BusService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local B = Gameplay.Bus
local LANE = 5 -- carril de la derecha
local DOOR_Z = { -14, 4.5 }

type Stop = { Name: string, Point: Vector3, S: number }
type Bus = {
	Model: Model,
	Driver: Player?, -- nil = lo lleva el juego
	S: number, -- metros recorridos en la línea (autobuses automáticos)
	Yaw: number,
	Wait: number, -- segundos que le quedan parado en la parada
	NextStop: number,
	DoorsOpen: boolean,
	Still: number, -- (conductor jugador) tiempo parado junto a la parada
}

local route: { Vector3 } = {}
local cumulative: { number } = {}
local total = 0
local stops: { Stop } = {}
local buses: { Bus } = {}
local drivers: { [Player]: Bus } = {}
local folder: Folder

---------------------------------------------------------------------
-- Recorrido
---------------------------------------------------------------------

local function pointAt(s: number): (Vector3, Vector3)
	s = s % total
	local lo, hi = 1, #route
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if cumulative[mid] <= s then
			lo = mid
		else
			hi = mid
		end
	end
	local a = route[lo]
	local bIndex = if lo < #route then lo + 1 else 1
	local b = route[bIndex]
	local segLen = (b - a).Magnitude
	local t = if segLen > 0 then (s - cumulative[lo]) / segLen else 0
	local dir = if segLen > 0 then (b - a).Unit else Vector3.new(0, 0, -1)
	return a + (b - a) * math.clamp(t, 0, 1), dir
end

local function buildRoute()
	local roadsFolder = ReplicatedStorage:WaitForChild("Ambient", 30)
	roadsFolder = roadsFolder and roadsFolder:FindFirstChild("Roads")
	if not roadsFolder then
		warn("[BusService] No hay calles publicadas: no hay autobús")
		return false
	end
	local roads = {}
	for _, config in roadsFolder:GetChildren() do
		local a, b = config:GetAttribute("A"), config:GetAttribute("B")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
			table.insert(roads, { A = a, B = b, Width = config:GetAttribute("Width") or 24 })
		end
	end
	-- Paradas: las marquesinas de cada barrio y del centro (TravelStop)
	local stopParts = {}
	for _, part in CollectionService:GetTagged("TravelStop") do
		if part:IsA("BasePart") then
			table.insert(stopParts, part)
		end
	end
	-- El centro primero (la línea empieza allí)
	table.sort(stopParts, function(a, b)
		local ca, cb = a:GetAttribute("Town") == "Valmar Centro", b:GetAttribute("Town") == "Valmar Centro"
		if ca ~= cb then
			return ca
		end
		return tostring(a:GetAttribute("Town")) < tostring(b:GetAttribute("Town"))
	end)
	local positions = {}
	for _, part in stopParts do
		table.insert(positions, part.Position)
	end
	if #positions < 2 then
		return false
	end
	local center, marks = BusRoute.loop(roads, positions)
	if #center < 2 then
		return false
	end
	route = BusRoute.lane(center, LANE)
	for i, p in route do
		route[i] = Vector3.new(p.X, 0.4, p.Z)
	end
	cumulative = { 0 }
	for i = 2, #route do
		cumulative[i] = cumulative[i - 1] + (route[i] - route[i - 1]).Magnitude
	end
	total = cumulative[#route] + (route[1] - route[#route]).Magnitude
	for _, mark in marks do
		local part = stopParts[mark.Stop]
		table.insert(stops, { Name = part:GetAttribute("Town") or "Parada", Point = route[mark.Index], S = cumulative[mark.Index] })
	end
	table.sort(stops, function(a, b)
		return a.S < b.S
	end)
	return true
end

---------------------------------------------------------------------
-- Autobús: puertas y pasajeros
---------------------------------------------------------------------

local function setDoors(bus: Bus, open: boolean)
	bus.DoorsOpen = open
	for _, part in bus.Model:GetDescendants() do
		if part.Name == "BusDoor" and part:IsA("BasePart") then
			part.Transparency = if open then 1 else 0.3
			part.CanCollide = not open
			local prompt = part:FindFirstChild("BoardPrompt") :: ProximityPrompt?
			if prompt then
				prompt.Enabled = open
			end
		end
	end
	bus.Model:SetAttribute("DoorsOpen", open)
end

local function pay(player: Player, amount: number, what: string)
	local value = math.floor(amount * MonetizationService.payMultiplier(player))
	DataService.addMoney(player, value, true)
	local data = DataService.get(player)
	if data then
		data.Stats.TasksDone += 1
	end
	Notify:FireClient(player, "Money", ("+%s · %s"):format(Format.money(value), what))
end

local function board(bus: Bus, player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart or not bus.DoorsOpen then
		return
	end
	if bus.Driver == player then
		return
	end
	if not LifeService.allows(player, "Travel") then
		return
	end
	local seat: Seat? = nil
	for _, part in bus.Model:GetDescendants() do
		if part:IsA("Seat") and part.Name == "PassengerSeat" and not part.Occupant then
			seat = part
			break
		end
	end
	if not seat then
		Notify:FireClient(player, "Error", "El autobús va lleno. Espera al siguiente.")
		return
	end
	if not DataService.spend(player, B.Fare) then
		Notify:FireClient(player, "Error", ("El billete cuesta %s y no tienes suficiente."):format(Format.money(B.Fare)))
		return
	end
	(seat :: Seat):Sit(humanoid)
	Notify:FireClient(player, "Info", ("🚌 Billete pagado (%s). Para bajarte, salta cuando el autobús esté parado."):format(Format.money(B.Fare)))
	StoryEvents.emit(player, "BusRide", { Line = "L1" })
	if bus.Driver then
		pay(bus.Driver, B.DriverPerPassenger, "pasajero")
	end
end

-- Quien se levanta de un asiento sale por la puerta más cercana (no se queda dentro del autobús)
local function watchSeats(bus: Bus)
	for _, seat in bus.Model:GetDescendants() do
		if seat:IsA("Seat") and seat.Name == "PassengerSeat" then
			local last: Humanoid? = nil
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				local occupant = seat.Occupant
				if not occupant and last then
					local root = last.Parent and last.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
					local chassis = bus.Model.PrimaryPart
					if root and chassis then
						local z = DOOR_Z[if (chassis.CFrame:PointToObjectSpace(seat.Position).Z > -5) then 2 else 1]
						task.defer(function()
							root.CFrame = chassis.CFrame * CFrame.new(8.6 / 2 + 3, 3.5, z)
							root.AssemblyLinearVelocity = Vector3.zero
						end)
					end
				end
				last = occupant
			end)
		end
	end
end

local function makeBus(cf: CFrame, driver: Player?): Bus
	local model = Rides.build("Autobus", nil, cf)
	Rides.prepare(model, "Autobus", cf)
	model.Name = if driver then "Autobus_" .. driver.Name else "Autobus_L1"
	model:SetAttribute("BusLine", "L1")
	local bus: Bus = { Model = model, Driver = driver, S = 0, Yaw = 0, Wait = 0, NextStop = 1, DoorsOpen = false, Still = 0 }
	for _, door in model:GetDescendants() do
		if door.Name == "BusDoor" and door:IsA("BasePart") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BoardPrompt"
			prompt.ActionText = "Subir"
			prompt.ObjectText = ("🚌 L1 · billete %s"):format(Format.money(B.Fare))
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false
			prompt.Parent = door
			prompt.Triggered:Connect(function(player)
				board(bus, player)
			end)
		end
	end
	-- Luces de noche en los faros
	for _, part in model:GetDescendants() do
		if part.Name == "Headlight" and part:IsA("BasePart") then
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Front
			light.Range = 50
			light.Angle = 70
			light.Brightness = 2.5
			light.Parent = part
			break
		end
	end
	watchSeats(bus)
	model.Parent = folder
	table.insert(buses, bus)
	return bus
end

-- Parada: abre puertas y avisa de la siguiente
local function arrive(bus: Bus, stopIndex: number)
	local stop = stops[stopIndex]
	setDoors(bus, true)
	bus.Model:SetAttribute("CurrentStop", stop.Name)
	local nextStop = stops[stopIndex % #stops + 1]
	bus.Model:SetAttribute("NextStop", nextStop.Name)
	bus.NextStop = stopIndex % #stops + 1
end

---------------------------------------------------------------------
-- Autobuses automáticos
---------------------------------------------------------------------

local function stepNpc(bus: Bus, dt: number)
	if bus.Wait > 0 then
		bus.Wait -= dt
		if bus.Wait <= 0 then
			setDoors(bus, false)
			bus.Model:SetAttribute("CurrentStop", nil)
		end
		return
	end
	local stop = stops[bus.NextStop]
	local toStop = (stop.S - bus.S) % total
	local speed = B.Speed
	if toStop < 60 then
		speed = math.max(5, toStop * 0.6) -- frena al llegar
	end
	-- Más despacio en las curvas
	local _, dirNow = pointAt(bus.S)
	local _, dirAhead = pointAt(bus.S + 25)
	if dirNow:Dot(dirAhead) < 0.8 then
		speed = math.min(speed, 12)
	end
	local advance = speed * dt
	if advance >= toStop then
		bus.S = stop.S
		bus.Wait = B.StopSeconds
		arrive(bus, bus.NextStop)
	else
		bus.S = (bus.S + advance) % total
	end
	local position, dir = pointAt(bus.S)
	local targetYaw = math.atan2(-dir.X, -dir.Z)
	local diff = (targetYaw - bus.Yaw + math.pi) % (2 * math.pi) - math.pi
	bus.Yaw += diff * math.min(1, dt * 4)
	-- El autobús tiene 34 de largo: su centro va 8 studs por detrás del punto de la línea
	local cf = CFrame.new(position) * CFrame.Angles(0, bus.Yaw, 0) * CFrame.new(0, 0, 8)
	bus.Model:PivotTo(cf * CFrame.new(0, 0.5, 0))
end

---------------------------------------------------------------------
-- Conductor jugador
---------------------------------------------------------------------

local function publishDriver(player: Player, bus: Bus)
	local stop = stops[bus.NextStop]
	player:SetAttribute("TaskTarget", stop.Point)
	player:SetAttribute("TaskText", ("🚌 L1 · Conduce hasta la parada «%s» y para al lado"):format(stop.Name))
	bus.Model:SetAttribute("NextStop", stop.Name)
end

local function quit(player: Player, silent: boolean?)
	local bus = drivers[player]
	if not bus then
		return
	end
	drivers[player] = nil
	if VehicleService.ridingKind(player) == "Autobus" then
		VehicleService.dismount(player, true)
	end
	-- Los pasajeros se bajan antes de retirar el autobús
	for _, seat in bus.Model:GetDescendants() do
		if seat:IsA("Seat") and seat.Occupant then
			seat.Occupant.Sit = false
		end
	end
	task.delay(0.5, function()
		bus.Model:Destroy()
	end)
	local i = table.find(buses, bus)
	if i then
		table.remove(buses, i)
	end
	if player:GetAttribute("Job") == "Conductor" then
		player:SetAttribute("Job", nil)
		player:SetAttribute("TaskTarget", nil)
		player:SetAttribute("TaskText", nil)
	end
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado tu turno de conductor. ¡Buen trabajo!")
	end
end

local function hire(player: Player)
	if drivers[player] then
		quit(player)
		return
	end
	if #stops == 0 or not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	if not VehicleService.hasLicense(player, "B") then
		Notify:FireClient(player, "Error", "Para conducir el autobús necesitas el carnet de coche. Sácatelo en la autoescuela.")
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	JobService.quit(player, true)
	-- El autobús sale en el punto de la línea más cercano, mirando hacia donde va la línea
	local best, bestD = 1, math.huge
	for i, p in route do
		local d = (p - root.Position).Magnitude
		if d < bestD then
			best, bestD = i, d
		end
	end
	local s = cumulative[best]
	local position, dir = pointAt(s + 10)
	local cf = CFrame.lookAt(position, position + dir)
	local bus = makeBus(cf, player)
	-- Siguiente parada: la primera por delante
	local nextIndex = 1
	for i, stop in stops do
		if stop.S > s then
			nextIndex = i
			break
		end
	end
	bus.NextStop = nextIndex
	drivers[player] = bus
	if not VehicleService.driveModel(player, bus.Model, "Autobus") then
		drivers[player] = nil
		local i = table.find(buses, bus)
		if i then
			table.remove(buses, i)
		end
		bus.Model:Destroy()
		return
	end
	player:SetAttribute("Job", "Conductor")
	publishDriver(player, bus)
	-- Si se baja, puede volver a subir con este cartel (solo el conductor)
	local chassis = bus.Model.PrimaryPart :: BasePart
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Conducir el autobús"
	prompt.ObjectText = "🚌 L1"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = chassis
	prompt.Triggered:Connect(function(who)
		if who == player and drivers[player] == bus and VehicleService.ridingKind(player) ~= "Autobus" then
			VehicleService.driveModel(player, bus.Model, "Autobus")
		end
	end)
	Notify:FireClient(player, "Success", "🚌 ¡Contratado de conductor! Sigue la línea azul hasta cada parada y para al lado.")
end

-- Cada medio segundo: ¿ha parado el conductor en su parada?
local function checkDrivers(dt: number)
	for player, bus in drivers do
		local chassis = bus.Model.PrimaryPart
		if chassis and bus.Model.Parent then
			if bus.Wait > 0 then
				bus.Wait -= dt
				if bus.Wait <= 0 then
					setDoors(bus, false)
					bus.Model:SetAttribute("CurrentStop", nil)
					publishDriver(player, bus)
				end
			else
				local stop = stops[bus.NextStop]
				local near = (Vector3.new(chassis.Position.X, 0, chassis.Position.Z) - Vector3.new(stop.Point.X, 0, stop.Point.Z)).Magnitude < B.StopRadius
				local slow = chassis.AssemblyLinearVelocity.Magnitude < 4 or chassis.Anchored
				if near and slow then
					bus.Still += dt
					if bus.Still > 1 then
						bus.Still = 0
						bus.Wait = B.StopSeconds
						local stopIndex = bus.NextStop
						arrive(bus, stopIndex)
						-- Pasajeros NPC que suben en la parada (también pagan al conductor)
						local riders = math.random(0, 3)
						pay(player, B.DriverPerStop + riders * B.DriverPerPassenger, ("parada %s · %d pasajeros"):format(stops[stopIndex].Name, riders))
						NeedsService.change(player, 0, -1)
						StoryEvents.emit(player, "JobTaskDone", { JobId = "Conductor" })
						player:SetAttribute("TaskText", ("🚌 Parada «%s»: puertas abiertas… espera unos segundos"):format(stops[stopIndex].Name))
					end
				else
					bus.Still = 0
				end
			end
		end
	end
end

---------------------------------------------------------------------
function BusService.init()
	folder = Instance.new("Folder")
	folder.Name = "Buses"
	folder.Parent = workspace
	task.spawn(function()
		if not buildRoute() then
			return
		end
		-- Autobuses automáticos repartidos por la línea
		for i = 1, B.NpcBuses do
			local bus = makeBus(CFrame.new(route[1]), nil)
			bus.S = total * (i - 1) / B.NpcBuses
			for k, stop in stops do
				if stop.S > bus.S then
					bus.NextStop = k
					break
				end
			end
			local chassis = bus.Model.PrimaryPart :: BasePart
			chassis.Anchored = true
		end

		-- Contratación: el conductor de la Estación de Autobuses y la parada del centro
		local function hirePrompt(part: BasePart)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BusJobPrompt"
			prompt.ActionText = "🚌 Trabajar de conductor"
			prompt.ObjectText = "Autobús urbano L1"
			prompt.HoldDuration = 0.4
			prompt.KeyboardKeyCode = Enum.KeyCode.R
			prompt.UIOffset = Vector2.new(0, 58)
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = part
			prompt.Triggered:Connect(hire)
		end
		for _, spot in CollectionService:GetTagged("WorkerSpot") do
			if spot:IsA("BasePart") and spot:GetAttribute("Role") == "Conductor" then
				hirePrompt(spot)
			end
		end
		for _, part in CollectionService:GetTagged("TravelStop") do
			if part:IsA("BasePart") and part:GetAttribute("Town") == "Valmar Centro" then
				hirePrompt(part)
			end
		end

		local last = os.clock()
		RunService.Heartbeat:Connect(function(dt)
			for _, bus in buses do
				if not bus.Driver and bus.Model.Parent then
					stepNpc(bus, dt)
				end
			end
			if os.clock() - last >= 0.5 then
				checkDrivers(os.clock() - last)
				last = os.clock()
			end
		end)
	end)

	ReplicatedStorage.Remotes.QuitJob.OnServerEvent:Connect(function(player)
		quit(player)
	end)
	local function watch(player: Player)
		player:GetAttributeChangedSignal("Job"):Connect(function()
			if drivers[player] and player:GetAttribute("Job") ~= "Conductor" then
				quit(player, true)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		quit(player, true)
	end)
end

return BusService
