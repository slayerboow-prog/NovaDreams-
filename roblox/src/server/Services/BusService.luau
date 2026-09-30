-- BusService: los autobuses urbanos de Valmar (red de líneas de shared/BusLines) y el oficio de conductor.
--
-- PASAJEROS
--   * Cada línea (L1…L5) tiene sus autobuses dando vueltas todo el rato, con conductor del juego.
--     Paran en todas las paradas y abren las puertas; si alguien se acerca a la parada, esperan un
--     poco más (hasta Gameplay.Bus.HoldSeconds).
--   * Para subir: en la parada, el cartel del poste ("Subir al bus (L2)") o el de la puerta.
--     Los niños viajan gratis y los adolescentes pagan medio billete (Gameplay.Bus.Fares).
--   * Dentro: la próxima parada y el botón "Bajar en la próxima" (tecla G, o saltar). En la parada
--     pedida se abre la puerta y bajas en la acera, junto a la marquesina.
--   * Cada parada tiene un panel con lo que tarda cada línea ("L2 → Puerto · 3 min"): el servidor
--     calcula los tiempos cada 2 s (BusLines.eta) y los deja en el atributo "Board" del poste.
--
-- CONDUCTOR (oficio)
--   * Te contratan en la Estación de Autobuses (el conductor de la puerta) o en la parada del centro.
--     Te dan tu autobús en la línea más cercana y lo conduces tú (W/A/S/D).
--   * La línea azul te lleva a la siguiente parada: para al lado (despacio) y se abren las puertas.
--     Cobras por cada parada y por cada pasajero. Hace falta el carnet de coche.
--   * Los autobuses del juego siguen funcionando aunque no haya ningún conductor jugador.

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Format = require(ReplicatedStorage.Shared.Format)
local BusLines = require(ReplicatedStorage.Shared.BusLines)
local Rides = require(script.Parent.Parent.World.Kit.Rides)
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
local DOOR_Z = { -13.4, 4.5 } -- puertas (delantera y central), en el lado derecho del autobús
local HALF_W = 4.3 -- media anchura del autobús
local AHEAD = 8 -- el punto de la línea va 8 studs por delante del centro del autobús
local WALK = 1 -- altura de la acera

type Stop = { Id: string, Name: string, S: number, Headsign: string, Info: BusLines.StopInfo, Sign: BasePart? }
type Line = { Def: BusLines.LineDef, Plan: BusLines.LinePlan, Stops: { Stop }, StopS: { number } }
type Bus = {
	Model: Model,
	Line: Line,
	Driver: Player?, -- nil = lo lleva el juego
	S: number, -- studs recorridos en la línea (autobuses del juego)
	Yaw: number,
	Speed: number,
	Wait: number, -- segundos que le quedan parado en la parada
	Held: number, -- lo que lleva parado en esta parada
	NextStop: number,
	AtStop: number?, -- parada en la que está con las puertas abiertas
	DoorsOpen: boolean,
	Still: number, -- (conductor jugador) tiempo parado junto a la parada
	Off: number?, -- (conductor jugador) tiempo que lleva fuera del autobús
	Riders: { [Player]: Seat },
	Requests: { [Player]: boolean },
	Visit: number, -- cuántas veces ha parado (para pagar al conductor una vez por pasajero y parada)
	Paid: { [Player]: number }, -- en qué parada (Visit) se pagó al conductor por este pasajero
	PaidAt: number?, -- (conductor jugador) última parada cobrada (o salida) y dónde
	PaidPos: Vector3?,
}

-- Ritmo mínimo entre paradas cobradas al conductor: quien mueve el autobús a golpe de
-- teletransporte cobraría parada tras parada. Hace falta al menos la distancia a PACE_SPEED studs/s
-- (más de lo que corre un autobús) y nunca menos de PACE_MIN segundos. Sin DataStore (Studio sin
-- API, pruebas) no se guarda nada y no se mira.
local PACE_SPEED = 60
local PACE_MIN = 1.5
local CHECK_PACE = pcall(function()
	return DataStoreService:GetDataStore("PlayerData")
end)

local lines: { Line } = {}
local stopsById: { [string]: Stop } = {}
local stopLines: { [string]: { Line } } = {}
local buses: { Bus } = {}
local drivers: { [Player]: Bus } = {}
local folder: Folder
local ready = false

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function fareFor(player: Player): number
	local fare = B.Fares[player:GetAttribute("LifeStage") or ""]
	return if fare ~= nil then fare else B.Fare
end

local function fareText(): string
	return ("niños gratis · billete %s"):format(Format.money(B.Fare))
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

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Cambia el texto de un letrero del autobús (los hace Builder.sign: SurfaceGui > TextLabel)
local function setSign(model: Model, name: string, value: string)
	for _, part in model:GetDescendants() do
		if part.Name == name and part:IsA("BasePart") then
			for _, gui in part:GetChildren() do
				local label = gui:FindFirstChildOfClass("TextLabel")
				if label then
					label.Text = value
				end
			end
		end
	end
end

local function lineOf(id: string): Line?
	for _, line in lines do
		if line.Def.Id == id then
			return line
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Red de líneas
---------------------------------------------------------------------

local function buildNetwork(): boolean
	local ambient = ReplicatedStorage:WaitForChild("Ambient", 30)
	local roadsFolder = ambient and ambient:FindFirstChild("Roads")
	if not roadsFolder then
		warn("[BusService] No hay calles publicadas: no hay autobuses")
		return false
	end
	local roads = BusLines.roadsFrom(roadsFolder)
	-- Los postes de las paradas (Kit/BusStops). Si el mapa no los trae, se construyen ahora.
	local signs: { [string]: BasePart } = {}
	local function collect()
		for _, part in CollectionService:GetTagged("BusStop") do
			local id = part:GetAttribute("StopId")
			if part:IsA("BasePart") and typeof(id) == "string" then
				signs[id] = part
			end
		end
	end
	collect()
	if next(signs) == nil then
		local ok, err = pcall(function()
			require(script.Parent.Parent.World.Kit.BusStops).build(workspace:FindFirstChild("Town") or workspace, roads)
		end)
		if not ok then
			warn("[BusService] No se pudieron construir las paradas: " .. tostring(err))
		end
		collect()
	end
	local plan = BusLines.plan(roads)
	for i, linePlan in plan.Lines do
		local def = BusLines.byId[linePlan.Id] or BusLines.Lines[i]
		if linePlan.Total > 0 and #linePlan.Stops >= 2 then
			local line: Line = { Def = def, Plan = linePlan, Stops = {}, StopS = {} }
			for _, s in linePlan.Stops do
				local sign = signs[s.Id]
				local S = s.S
				-- Donde para de verdad (la marquesina puede estar corrida unos studs por la acera)
				local point = sign and sign:GetAttribute("StopPoint")
				if typeof(point) == "Vector3" then
					local projected, off = BusLines.project(linePlan, point)
					if off < 12 then
						S = projected
					end
				end
				local stop: Stop = { Id = s.Id, Name = plan.Stops[s.Id].Name, S = S, Headsign = s.Headsign, Info = plan.Stops[s.Id], Sign = sign }
				table.insert(line.Stops, stop)
				table.insert(line.StopS, S)
				stopsById[s.Id] = stopsById[s.Id] or stop
				stopLines[s.Id] = stopLines[s.Id] or {}
				table.insert(stopLines[s.Id], line)
			end
			table.insert(lines, line)
		end
	end
	return #lines > 0
end

-- Primera parada por delante de s
local function nextStopAfter(line: Line, s: number): number
	local best, bestD = 1, math.huge
	for k, stop in line.Stops do
		local d = (stop.S - s) % line.Plan.Total
		if d > 0.5 and d < bestD then
			best, bestD = k, d
		end
	end
	return best
end

---------------------------------------------------------------------
-- Autobús: puertas, asientos y pasajeros
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

-- Destino que lleva ahora (el de su próxima parada)
local function updateHeadsign(bus: Bus)
	local stop = bus.Line.Stops[bus.NextStop]
	local id = bus.Line.Def.Id
	if bus.Model:GetAttribute("Headsign") ~= stop.Headsign then
		bus.Model:SetAttribute("Headsign", stop.Headsign)
		setSign(bus.Model, "DestinationSign", ("%s  %s"):format(id, string.upper(stop.Headsign)))
		setSign(bus.Model, "SideSign", ("%s → %s"):format(id, stop.Headsign))
		for _, part in bus.Model:GetDescendants() do
			if part.Name == "BoardPrompt" and part:IsA("ProximityPrompt") then
				part.ObjectText = ("→ %s · %s"):format(stop.Headsign, fareText())
			end
		end
	end
	bus.Model:SetAttribute("NextStop", stop.Name)
end

-- Dónde se baja un pasajero: en la acera junto a la puerta si está en una parada; si no, al lado
local function exitCFrame(bus: Bus, seat: BasePart): CFrame?
	local chassis = bus.Model.PrimaryPart
	if not chassis then
		return nil
	end
	local z = DOOR_Z[if chassis.CFrame:PointToObjectSpace(seat.Position).Z > -5 then 2 else 1]
	local door = chassis.CFrame * CFrame.new(HALF_W, 0, z)
	local stop = if bus.AtStop then bus.Line.Stops[bus.AtStop] else nil
	if stop then
		local info = stop.Info
		-- Del carril a la acera: pasado el bordillo, mirando hacia la marquesina
		local out = (info.Width / 2 + 2.2) - (BusLines.Lane + HALF_W)
		local p = door.Position + info.Right * out
		return CFrame.new(Vector3.new(p.X, WALK + 3, p.Z)) * CFrame.Angles(0, math.atan2(-info.Right.X, -info.Right.Z), 0)
	end
	return chassis.CFrame * CFrame.new(HALF_W + 3, 3.5, z)
end

local function riderOf(bus: Bus, humanoid: Humanoid): Player?
	for player in bus.Riders do
		if player.Character == humanoid.Parent then
			return player
		end
	end
	for _, player in Players:GetPlayers() do
		if player.Character == humanoid.Parent then
			return player
		end
	end
	return nil
end

local function requestStop(bus: Bus, player: Player)
	if bus.Requests[player] then
		return
	end
	bus.Requests[player] = true
	bus.Model:SetAttribute("StopRequested", true)
	local stop = bus.Line.Stops[bus.NextStop]
	Notify:FireClient(player, "Info", ("🔔 Parada solicitada: te bajas en «%s»."):format(stop.Name))
end

-- ¿Va en marcha de verdad? Los del juego se mueven con PivotTo (cuenta su Speed); los de un jugador,
-- la velocidad del chasis y que el conductor siga al volante (si se ha bajado, no va a ningún sitio)
local function rolling(bus: Bus): boolean
	if bus.DoorsOpen then
		return false
	end
	if not bus.Driver then
		return true -- (los del juego, con las puertas cerradas, van de ruta: acaban de arrancar o frenan un momento)
	end
	local chassis = bus.Model.PrimaryPart
	if not chassis or VehicleService.ridingKind(bus.Driver) ~= "Autobus" then
		return false
	end
	return chassis.AssemblyLinearVelocity.Magnitude >= 2
end

-- Quien se levanta de un asiento con las puertas abiertas baja a la acera. Si salta con el autobús
-- en marcha, vuelve a su asiento y se le pide la parada (así nadie se cae en medio de la calle).
-- Con el autobús parado (o sin nadie al volante) se baja a su lado: si no, se quedaba atrapado.
local function watchSeats(bus: Bus)
	for _, seat in bus.Model:GetDescendants() do
		if seat:IsA("Seat") and seat.Name == "PassengerSeat" then
			local last: Humanoid? = nil
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				local occupant = seat.Occupant
				if not occupant and last then
					local humanoid = last
					local player = riderOf(bus, humanoid)
					local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
					local moving = rolling(bus)
					if player then
						bus.Riders[player] = nil
						bus.Requests[player] = nil
						player:SetAttribute("BusLine", nil)
					end
					if root and moving and player and humanoid.Health > 0 and bus.Model.Parent then
						task.defer(function()
							local near = root.Parent ~= nil and (root.Position - seat.Position).Magnitude < 15
							if near and not seat.Occupant and rolling(bus) and humanoid.Health > 0 and not humanoid.SeatPart then
								seat:Sit(humanoid)
								bus.Riders[player] = seat
								player:SetAttribute("BusLine", bus.Line.Def.Id)
								requestStop(bus, player)
							end
						end)
					elseif root then
						local cf = exitCFrame(bus, seat)
						if cf then
							task.defer(function()
								root.CFrame = cf
								root.AssemblyLinearVelocity = Vector3.zero
							end)
						end
					end
				end
				last = occupant
			end)
		end
	end
end

-- Sube al jugador al autobús (desde la puerta o desde el cartel de la parada)
function BusService.board(bus: Bus, player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = rootOf(player)
	local chassis = bus.Model.PrimaryPart
	if not humanoid or not root or not chassis or humanoid.Health <= 0 or not bus.DoorsOpen or bus.Driver == player then
		return false
	end
	if bus.Riders[player] then
		return false
	end
	if not LifeService.allows(player, "Travel") then
		return false
	end
	if (root.Position - chassis.Position).Magnitude > B.BoardDistance then
		Notify:FireClient(player, "Error", "Acércate a la parada para subir al autobús.")
		return false
	end
	-- El asiento libre más cerca de la puerta delantera
	local seat: Seat? = nil
	local best = math.huge
	for _, part in bus.Model:GetDescendants() do
		if part:IsA("Seat") and part.Name == "PassengerSeat" and not part.Occupant then
			local z = chassis.CFrame:PointToObjectSpace(part.Position).Z
			if math.abs(z - DOOR_Z[1]) < best then
				seat, best = part, math.abs(z - DOOR_Z[1])
			end
		end
	end
	if not seat then
		Notify:FireClient(player, "Error", "El autobús va lleno. Espera al siguiente.")
		return false
	end
	local fare = fareFor(player)
	if fare > 0 and not DataService.spend(player, fare) then
		Notify:FireClient(player, "Error", ("El billete cuesta %s y no tienes suficiente."):format(Format.money(fare)))
		return false
	end
	-- Si iba en bici (o de pasajero) o sentado en el banco de la parada, se levanta primero. Sin
	-- avisar a su ordenador de que «se ha bajado»: si no, le levantaría también del autobús
	VehicleService.switchOut(player)
	local current = humanoid.SeatPart
	if current then
		local weld = current:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		humanoid.Sit = false
	end
	(seat :: Seat):Sit(humanoid)
	bus.Riders[player] = seat :: Seat
	local id = bus.Line.Def.Id
	player:SetAttribute("BusLine", id)
	local ticket = if fare > 0 then ("Billete pagado (%s)."):format(Format.money(fare)) else "¡Los niños viajan gratis!"
	Notify:FireClient(player, "Info", ("🚌 %s %s Pulsa «Bajar en la próxima» (G) para pedir parada."):format(id, ticket))
	StoryEvents.emit(player, "BusRide", { Line = id })
	-- Al conductor, una vez por pasajero en cada parada (bajar y volver a subir no cuenta) y nunca
	-- más de lo que ha pagado el billete (los niños, gratis: no se cobra nada por ellos)
	local cut = math.min(fare, B.DriverPerPassenger)
	if bus.Driver and cut > 0 and bus.Paid[player] ~= bus.Visit then
		bus.Paid[player] = bus.Visit
		pay(bus.Driver, cut, "pasajero")
	end
	return true
end

-- Un conductor del juego sentado al volante (figura sencilla: pocas piezas, sin física)
local function npcDriver(model: Model, cf: CFrame)
	local chassis = model.PrimaryPart
	local seatCf = cf * Rides.Spec.Autobus.Seat
	local driver = Instance.new("Model")
	driver.Name = "BusDriverNpc"
	local shirt, skin, cap = Color3.fromRGB(60, 120, 190), Color3.fromRGB(224, 180, 140), Color3.fromRGB(30, 50, 90)
	for _, spec in {
		{ "Torso", Vector3.new(2, 2.2, 1), CFrame.new(0, 1.4, 0.2), shirt },
		{ "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 3.1, 0.2), skin },
		{ "Cap", Vector3.new(1.3, 0.4, 1.4), CFrame.new(0, 3.8, 0.1), cap },
		{ "Arms", Vector3.new(2.6, 0.6, 1.8), CFrame.new(0, 1.9, -0.7), shirt },
	} do
		local p = Instance.new("Part")
		p.Name = spec[1]
		p.Size = spec[2]
		p.CFrame = seatCf * spec[3]
		p.Color = spec[4]
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Massless = true
		p.Anchored = false
		p.Parent = driver
		if chassis then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = p
			weld.Parent = p
		end
	end
	driver.Parent = model
end

local function makeBus(line: Line, cf: CFrame, driver: Player?): Bus
	local id = line.Def.Id
	local model = Rides.build("Autobus", nil, cf, BusLines.color(line.Def))
	Rides.prepare(model, "Autobus", cf)
	model.Name = if driver then "Autobus_" .. driver.Name else "Autobus_" .. id
	model:SetAttribute("BusLine", id)
	model:SetAttribute("LineColor", BusLines.color(line.Def))
	pcall(function()
		(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	setSign(model, "RearSign", id)
	local bus: Bus = {
		Model = model,
		Line = line,
		Driver = driver,
		S = 0,
		Yaw = 0,
		Speed = 0,
		Wait = 0,
		Held = 0,
		NextStop = 1,
		DoorsOpen = false,
		Still = 0,
		Riders = {},
		Requests = {},
		Visit = 0,
		Paid = {},
	}
	for _, door in model:GetDescendants() do
		if door.Name == "BusDoor" and door:IsA("BasePart") and door:GetAttribute("Leaf") ~= 2 then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BoardPrompt"
			prompt.ActionText = ("Subir al bus (%s)"):format(id)
			prompt.ObjectText = fareText()
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false
			prompt.Parent = door
			prompt.Triggered:Connect(function(player)
				BusService.board(bus, player)
			end)
		end
	end
	-- Luces de noche en los faros
	for _, part in model:GetDescendants() do
		if part.Name == "Headlight" and part:IsA("BasePart") then
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Right -- (el faro es un cilindro mirando hacia delante)
			light.Range = 50
			light.Angle = 70
			light.Brightness = 2.5
			light.Parent = part
			break
		end
	end
	if not driver then
		npcDriver(model, cf)
	end
	watchSeats(bus)
	model.Parent = folder
	table.insert(buses, bus)
	return bus
end

-- Llega a una parada: abre las puertas y bajan los que la pidieron
local function arrive(bus: Bus, k: number)
	local line = bus.Line
	local stop = line.Stops[k]
	bus.AtStop = k
	bus.Held = 0
	bus.Visit += 1
	setDoors(bus, true)
	bus.Model:SetAttribute("CurrentStop", stop.Name)
	bus.NextStop = k % #line.Stops + 1
	updateHeadsign(bus)
	for player in bus.Requests do
		local seat = bus.Riders[player]
		local humanoid = seat and seat.Occupant
		if humanoid then
			humanoid.Sit = false
			Notify:FireClient(player, "Info", ("🚏 Has bajado en «%s»."):format(stop.Name))
		end
	end
	table.clear(bus.Requests)
end

local function depart(bus: Bus)
	setDoors(bus, false)
	bus.AtStop = nil
	bus.Model:SetAttribute("CurrentStop", nil)
	bus.Model:SetAttribute("StopRequested", false)
end

-- ¿Hay alguien en la parada que quizá quiera subir? (entonces espera un poco más)
local function someoneWaiting(bus: Bus): boolean
	local stop = if bus.AtStop then bus.Line.Stops[bus.AtStop] else nil
	local sign = stop and stop.Sign
	local chassis = bus.Model.PrimaryPart
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and not bus.Riders[player] and bus.Driver ~= player then
			local d = math.huge
			if sign then
				d = (root.Position - sign.Position).Magnitude
			end
			if chassis then
				d = math.min(d, (root.Position - chassis.Position).Magnitude)
			end
			if d < B.HoldRadius and LifeService.allows(player, "Travel", true) then
				return true
			end
		end
	end
	return false
end

---------------------------------------------------------------------
-- Autobuses del juego
---------------------------------------------------------------------

local function place(bus: Bus, dt: number?)
	local position, dir = BusLines.pointAt(bus.Line.Plan, bus.S)
	local targetYaw = math.atan2(-dir.X, -dir.Z)
	if dt then
		local diff = (targetYaw - bus.Yaw + math.pi) % (2 * math.pi) - math.pi
		bus.Yaw += diff * math.min(1, dt * 4)
	else
		bus.Yaw = targetYaw
	end
	local cf = CFrame.new(position) * CFrame.Angles(0, bus.Yaw, 0) * CFrame.new(0, 0, AHEAD)
	bus.Model:PivotTo(cf * CFrame.new(0, 0.5, 0))
end

-- Hasta qué velocidad puede ir sin llevarse por delante a un jugador que esté en su carril
-- (los del juego van anclados y se mueven con PivotTo: no chocan, atravesarían a la gente)
local LOOK_AHEAD = 30 -- studs por delante del morro que mira
local function clearAhead(bus: Bus): number
	local pivot = bus.Model:GetPivot()
	local look = Vector3.new(pivot.LookVector.X, 0, pivot.LookVector.Z)
	if look.Magnitude < 0.1 then
		return math.huge
	end
	look = look.Unit
	local nose = pivot.Position + look * 17 -- (el autobús mide 34 de largo)
	local limit = math.huge
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and not bus.Riders[player] then
			local rel = root.Position - nose
			local along = rel.X * look.X + rel.Z * look.Z
			local side = math.abs(rel.X * look.Z - rel.Z * look.X)
			if along > -4 and along < LOOK_AHEAD and side < HALF_W + 1.5 and math.abs(rel.Y) < 10 then
				-- Si va en coche o en bici, el morro de su vehículo está más cerca: más margen
				local gap = if VehicleService.ridingKind(player) then 10 else 5
				limit = math.min(limit, math.max(0, (along - gap) * 0.8))
			end
		end
	end
	return limit
end

local function stepNpc(bus: Bus, dt: number)
	local line = bus.Line
	local total = line.Plan.Total
	if bus.Wait > 0 then
		bus.Wait -= dt
		bus.Held += dt
		if bus.Wait <= 0 then
			if bus.Held < B.HoldSeconds and someoneWaiting(bus) then
				bus.Wait = 0.5
				return
			end
			depart(bus)
		end
		return
	end
	local stop = line.Stops[bus.NextStop]
	local toStop = (stop.S - bus.S) % total
	-- Frena al llegar, va más despacio en las curvas y no se pega al autobús de delante
	local target = math.min(B.Speed, math.sqrt(2 * B.Brake * toStop) + 2)
	local _, dirNow = BusLines.pointAt(line.Plan, bus.S)
	local _, dirAhead = BusLines.pointAt(line.Plan, bus.S + 30)
	local turn = dirNow:Dot(dirAhead)
	if turn < 0.3 then
		target = math.min(target, 9)
	elseif turn < 0.85 then
		target = math.min(target, 15)
	end
	-- Alguien en el carril por delante (a pie o en su vehículo): frena y, si hace falta, se para
	target = math.min(target, clearAhead(bus))
	for _, other in buses do
		if other ~= bus and other.Line == line and not other.Driver then
			local gap = (other.S - bus.S) % total
			if gap > 0.1 and gap < 60 then
				target = math.min(target, math.max(0, (gap - 42) * 0.8))
			end
		end
	end
	if bus.Speed < target then
		bus.Speed = math.min(target, bus.Speed + B.Accel * dt)
	else
		bus.Speed = math.max(target, bus.Speed - B.Brake * 2 * dt)
	end
	local advance = bus.Speed * dt
	if advance >= toStop or toStop < 0.3 then
		bus.S = stop.S
		bus.Speed = 0
		bus.Wait = B.StopSeconds
		arrive(bus, bus.NextStop)
	else
		bus.S = (bus.S + advance) % total
	end
	place(bus, dt)
end

---------------------------------------------------------------------
-- Paneles de llegada (cada Gameplay.Bus.BoardEvery s)
---------------------------------------------------------------------

-- Los próximos autobuses de cada parada (lo que sale en su panel)
function BusService.arrivals(): { [string]: { BusLines.Arrival } }
	local out: { [string]: { BusLines.Arrival } } = {}
	local speed = B.Speed * B.AverageFactor
	for _, bus in buses do
		local line = bus.Line
		local chassis = bus.Model.PrimaryPart
		if bus.Model.Parent and chassis then
			local s = bus.S
			if bus.Driver then
				s = BusLines.project(line.Plan, chassis.Position) - AHEAD
			end
			local wait = if bus.Wait > 0 then math.max(bus.Wait, 1) else 0
			for k, stop in line.Stops do
				local here = bus.AtStop == k and bus.DoorsOpen
				local seconds = if here then 0 else BusLines.eta(line.Plan.Total, s, stop.S, line.StopS, speed, B.StopSeconds + 2, wait)
				out[stop.Id] = out[stop.Id] or {}
				table.insert(out[stop.Id], { Line = line.Def.Id, Headsign = stop.Headsign, Seconds = seconds, AtStop = here })
			end
		end
	end
	for id, list in out do
		table.sort(list, function(a, b)
			if a.AtStop ~= b.AtStop then
				return a.AtStop
			end
			return a.Seconds < b.Seconds
		end)
		-- Como mucho 2 por línea y 4 en total
		local kept, perLine = {}, {}
		for _, a in list do
			perLine[a.Line] = (perLine[a.Line] or 0) + 1
			if perLine[a.Line] <= 2 and #kept < 4 then
				table.insert(kept, a)
			end
		end
		out[id] = kept
	end
	return out
end

-- El autobús con las puertas abiertas en esta parada (si hay)
local function busAt(stopId: string): Bus?
	for _, bus in buses do
		local k = bus.AtStop
		if k and bus.DoorsOpen and bus.Line.Stops[k].Id == stopId then
			return bus
		end
	end
	return nil
end

local function publishBoards()
	local all = BusService.arrivals()
	for id, stop in stopsById do
		local sign = stop.Sign
		if sign then
			local list = all[id] or {}
			local text = BusLines.encodeBoard(list)
			if sign:GetAttribute("Board") ~= text then
				sign:SetAttribute("Board", text)
			end
			local prompt = sign:FindFirstChild("BusStopPrompt") :: ProximityPrompt?
			if prompt then
				local here = busAt(id)
				if here then
					prompt.ActionText = ("Subir al bus (%s)"):format(here.Line.Def.Id)
					prompt.ObjectText = ("→ %s · %s"):format(here.Line.Stops[here.AtStop :: number].Headsign, fareText())
				else
					prompt.ActionText = "🚏 Próximos autobuses"
					prompt.ObjectText = if list[1] then BusLines.boardText(list[1]) else "Sin servicio ahora"
				end
			end
		end
	end
end

local function stopPrompt(stop: Stop)
	local sign = stop.Sign
	if not sign or sign:FindFirstChild("BusStopPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BusStopPrompt"
	prompt.ActionText = "🚏 Próximos autobuses"
	prompt.ObjectText = stop.Name
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = sign
	prompt.Triggered:Connect(function(player)
		local bus = busAt(stop.Id)
		if bus then
			BusService.board(bus, player)
			return
		end
		local list = BusLines.decodeBoard(sign:GetAttribute("Board"))
		local rows = {}
		for _, a in list do
			table.insert(rows, BusLines.boardText(a))
		end
		Notify:FireClient(player, "Info", ("🚏 %s: %s"):format(stop.Name, if #rows > 0 then table.concat(rows, " · ") else "ahora no pasa ningún autobús"))
	end)
end

---------------------------------------------------------------------
-- Conductor jugador
---------------------------------------------------------------------

local function stopPoint(line: Line, k: number): Vector3
	local p = BusLines.pointAt(line.Plan, line.Stops[k].S)
	return p
end

local function publishDriver(player: Player, bus: Bus)
	local stop = bus.Line.Stops[bus.NextStop]
	player:SetAttribute("TaskTarget", stopPoint(bus.Line, bus.NextStop))
	player:SetAttribute("TaskText", ("🚌 %s · Conduce hasta la parada «%s» y para al lado"):format(bus.Line.Def.Id, stop.Name))
	updateHeadsign(bus)
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
	bus.DoorsOpen = true
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

-- ¿Cabe el autobús en este punto de la línea? (nada que choque: personas, coches, farolas…)
local function spawnSpot(line: Line, s: number, ignore: { Instance }): CFrame?
	local position, dir = BusLines.pointAt(line.Plan, s)
	local cf = CFrame.new(position) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = table.clone(ignore)
	local hit = Ground.cast(position + Vector3.new(0, 12, 0), Vector3.new(0, -30, 0), params)
	local groundY = if hit then hit.Position.Y else position.Y
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ignore
	overlap.RespectCanCollide = true
	overlap.MaxParts = 1
	local box = Vector3.new(HALF_W * 2 + 0.4, 5, Rides.Spec.Autobus.Size.Z + 1)
	local center = CFrame.new(position.X, groundY + 0.6 + box.Y / 2, position.Z) * cf.Rotation
	local ok, parts = pcall(function()
		return workspace:GetPartBoundsInBox(center, box, overlap)
	end)
	if ok and #parts > 0 then
		return nil
	end
	return cf -- (si la consulta falla, no se impide sacarlo)
end

local function hire(player: Player)
	if drivers[player] then
		quit(player)
		return
	end
	if #lines == 0 or not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Te falta energía o tienes demasiada hambre para trabajar.")
		return
	end
	if not VehicleService.hasLicense(player, "B") then
		Notify:FireClient(player, "Error", "Para conducir el autobús necesitas el carnet de coche. Sácatelo en la autoescuela.")
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	JobService.quit(player, true)
	-- La línea que pasa más cerca; el autobús sale en ese punto, mirando hacia donde va la línea
	local line, s, bestD = lines[1], 0, math.huge
	for _, candidate in lines do
		local cs, d = BusLines.project(candidate.Plan, root.Position)
		if d < bestD then
			line, s, bestD = candidate, cs, d
		end
	end
	-- Donde salga no puede haber nadie (personas, coches, otro autobús): se prueba en varios puntos
	-- de la línea y, si en ninguno cabe, no sale
	local ignore: { Instance } = { workspace.Terrain }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local ride = VehicleService.rideModel(player)
	if ride then
		table.insert(ignore, ride) -- (su bici o su coche se retira al subirse al autobús)
	end
	local cf: CFrame? = nil
	local at = s + 10
	for _, offset in { 10, 30, 50, -20, 75 } do
		local candidate = spawnSpot(line, s + offset, ignore)
		if candidate then
			cf, at = candidate, s + offset
			break
		end
	end
	if not cf then
		Notify:FireClient(player, "Error", "Ahora no hay sitio libre en la calle para sacar el autobús. Prueba en otro momento o en otro sitio.")
		return
	end
	local bus = makeBus(line, cf :: CFrame, player)
	bus.NextStop = nextStopAfter(line, at)
	drivers[player] = bus
	bus.PaidAt = os.clock()
	bus.PaidPos = (cf :: CFrame).Position
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
	prompt.ObjectText = "🚌 " .. line.Def.Id
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = chassis
	prompt.Triggered:Connect(function(who)
		if who == player and drivers[player] == bus and VehicleService.ridingKind(player) ~= "Autobus" then
			VehicleService.driveModel(player, bus.Model, "Autobus")
		end
	end)
	Notify:FireClient(player, "Success", ("🚌 ¡Te han contratado como conductor/a en la %s (%s)! Sigue la línea azul hasta cada parada y para al lado."):format(line.Def.Id, line.Def.Name))
end

-- Cada medio segundo: ¿ha parado el conductor en su parada? (y si deja el autobús abandonado
-- DRIVER_AWAY segundos, se acaba su turno y el autobús se retira)
local DRIVER_AWAY = 120
local function checkDrivers(dt: number)
	for player, bus in drivers do
		local atWheel = VehicleService.ridingKind(player) == "Autobus"
		if atWheel then
			bus.Off = 0
		else
			bus.Off = (bus.Off or 0) + dt
			if (bus.Off :: number) >= DRIVER_AWAY then
				quit(player, true)
				Notify:FireClient(player, "Info", "🚌 Has dejado el autobús abandonado: se acabó tu turno de conductor.")
				continue
			end
		end
		local chassis = bus.Model.PrimaryPart
		if chassis and bus.Model.Parent then
			local speed = chassis.AssemblyLinearVelocity.Magnitude
			if not atWheel then
				-- Se ha bajado (quizá entre paradas): se abren las puertas para que los pasajeros no
				-- se queden encerrados en un autobús que no va a ningún sitio
				if not bus.DoorsOpen then
					setDoors(bus, true)
				end
				bus.Still = 0
			elseif bus.Wait > 0 then
				bus.Wait -= dt
				-- Arranca con las puertas abiertas: se cierran ya (nadie sube ni baja en marcha)
				if bus.Wait <= 0 or speed > 4 then
					bus.Wait = 0
					depart(bus)
					publishDriver(player, bus)
				end
			elseif bus.DoorsOpen then
				-- Vuelve al volante con las puertas abiertas (se abrieron al bajarse): se cierran
				depart(bus)
				if next(bus.Requests) then
					bus.Model:SetAttribute("StopRequested", true) -- (las paradas pedidas siguen pedidas)
				end
			else
				local k = bus.NextStop
				local point = stopPoint(bus.Line, k)
				local flatDistance = (Vector3.new(chassis.Position.X, 0, chassis.Position.Z) - Vector3.new(point.X, 0, point.Z)).Magnitude
				local slow = speed < 4 or chassis.Anchored
				if flatDistance < B.StopRadius and slow then
					bus.Still += dt
					if bus.Still > 1 then
						bus.Still = 0
						bus.Wait = B.StopSeconds
						local stop = bus.Line.Stops[k]
						arrive(bus, k)
						-- Demasiado rápido desde la parada anterior (teletransporte): para, pero no cobra
						local from, since = bus.PaidPos, os.clock() - (bus.PaidAt or -math.huge)
						local flat = if from then Vector3.new(point.X - from.X, 0, point.Z - from.Z).Magnitude else 0
						if CHECK_PACE and since < math.max(PACE_MIN, flat / PACE_SPEED) then
							Notify:FireClient(player, "Error", "🚌 Has llegado demasiado rápido: esta parada no se cobra.")
						else
							bus.PaidAt = os.clock()
							bus.PaidPos = point
							-- Pasajeros del juego que suben en la parada (también pagan al conductor)
							local riders = math.random(0, 3)
							pay(player, B.DriverPerStop + riders * B.DriverPerPassenger, ("parada %s · %d pasajeros"):format(stop.Name, riders))
							NeedsService.change(player, 0, -1)
							StoryEvents.emit(player, "JobTaskDone", { JobId = "Conductor" })
						end
						player:SetAttribute("TaskText", ("🚌 Parada «%s»: puertas abiertas… espera unos segundos"):format(stop.Name))
					end
				else
					bus.Still = 0
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Pasajero: "Bajar en la próxima"
---------------------------------------------------------------------

local function onRemote(player: Player, action: string)
	if action == "Request" then
		for _, bus in buses do
			if bus.Riders[player] then
				if bus.DoorsOpen then
					-- Ya está en una parada: se baja ahora
					local seat = bus.Riders[player]
					if seat.Occupant then
						seat.Occupant.Sit = false
					end
				else
					requestStop(bus, player)
				end
				return
			end
		end
	end
end

-- Para las pruebas y otros sistemas
function BusService.lines(): { Line }
	return lines
end
function BusService.buses(): { Bus }
	return buses
end
function BusService.isReady(): boolean
	return ready
end

---------------------------------------------------------------------
function BusService.init()
	-- Así JobService.quit (p. ej. al entrar en prisión) también termina el turno de conductor
	JobService.setHandler("Conductor", { Start = hire, Quit = quit })
	folder = Instance.new("Folder")
	folder.Name = "Buses"
	folder.Parent = workspace
	local remote = ReplicatedStorage.Remotes:FindFirstChild("Bus") :: RemoteEvent?
	if remote then
		remote.OnServerEvent:Connect(onRemote)
	end
	task.spawn(function()
		if not buildNetwork() then
			return
		end
		-- Autobuses del juego repartidos por cada línea: circulan siempre, haya o no conductores
		for _, line in lines do
			local count = math.max(1, line.Def.Buses)
			for i = 1, count do
				local bus = makeBus(line, CFrame.new(line.Plan.Route[1]), nil)
				bus.S = line.Plan.Total * (i - 1) / count + 1
				bus.NextStop = nextStopAfter(line, bus.S)
				local chassis = bus.Model.PrimaryPart :: BasePart
				chassis.Anchored = true
				updateHeadsign(bus)
				place(bus)
			end
		end
		for _, stop in stopsById do
			stopPrompt(stop)
		end

		-- Contratación: el conductor de la Estación de Autobuses y la parada del centro
		local function hirePrompt(part: BasePart)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BusJobPrompt"
			prompt.ActionText = "🚌 Trabajar de conductor"
			prompt.ObjectText = "Autobús urbano"
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
		publishBoards()
		ready = true

		local driverClock, boardClock = 0, 0
		RunService.Heartbeat:Connect(function(dt)
			for _, bus in buses do
				if not bus.Driver and bus.Model.Parent then
					stepNpc(bus, dt)
				end
			end
			driverClock += dt
			if driverClock >= 0.5 then
				checkDrivers(driverClock)
				driverClock = 0
			end
			boardClock += dt
			if boardClock >= B.BoardEvery then
				boardClock = 0
				publishBoards()
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
		for _, bus in buses do
			bus.Riders[player] = nil
			bus.Requests[player] = nil
			bus.Paid[player] = nil
		end
	end)
end

-- (para las pruebas: la línea por su nombre)
BusService.lineOf = lineOf

return BusService
