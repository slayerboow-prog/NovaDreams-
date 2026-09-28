-- VehicleService: montar en monopatín, bici, moto y coche.
--
-- Cómo funciona: cada vehículo tiene una base invisible ("Chassis") y un asiento de conductor
-- (VehicleSeat). El jugador se sienta y su ordenador lo conduce (client/Controllers/Driving.luau):
-- acelerar, frenar, marcha atrás y girar, siguiendo el suelo con rayos (sin físicas que vuelquen).
--   * Los 800+ coches aparcados de la ciudad se pueden conducir (cartel "Conducir").
--   * Bici, monopatín y patinete públicos (tag RentalStation, junto a las paradas de bus): gratis.
--   * Vehículos propios: se compran y se sacan desde el botón "🚲 Vehículos".
--   * Conducir: cualquier vehículo desde niño (Gameplay.DriveMinStage; los bebés no), con carnet
--     o sin él. Sin el carnet que toca (o siendo menor) es delito, pero solo si te ve la policía:
--     lo vigila WantedService (drivingOffence). Comprar sí pide la edad de cada vehículo.
--   * Pasajeros: coches, moto, coche patrulla, camiones llevan asientos de pasajero ("RideSeat",
--     Rides.passengerSeats) con su cartel ("Subir de copiloto", "Subir detrás"). Cualquiera se
--     puede subir (amigos, otros jugadores), también a un coche aparcado ("Sentarse"). Conducir
--     tu vehículo es solo cosa tuya. Para bajarse: saltar, F / B o el botón "Bajarse"; se
--     baja por su lado del vehículo, de pie en el suelo.
--   * Bajarse funciona SIEMPRE a la primera (conduciendo o de pasajero, parado o en marcha, y
--     aunque el servidor no sepa que ibas sentado): se quita la soldadura del asiento, el vehículo
--     se para, quedas de pie a su lado y tu ordenador lo repite al momento (evento "Exited" a
--     Controllers/Vehicles). Después, durante Gameplay.ExitCooldown nada te vuelve a sentar.
--   * Todo el vehículo (con el conductor y los pasajeros) lo mueve el ordenador del conductor:
--     así nadie tiembla (la base, "Chassis", es la raíz del conjunto: RootPriority).
-- Datos guardados: data.Vehicles = { Bici = true, ... }, data.Licenses = { A = true, B = true }

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Builder = require(script.Parent.Parent.World.Builder)
local Rides = require(script.Parent.Parent.World.Kit.Rides)
local DataService = require(script.Parent.DataService)
local LifeService = require(script.Parent.LifeService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local VehicleService = {}

-- Gasolineras de jugadores (BusinessService): precio y litros que quedan, y aviso de la venta
VehicleService.FuelSeller = nil :: { quote: (BasePart) -> (number?, number?), sold: (BasePart, number, number) -> () }?

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Vehicle :: RemoteEvent

local STAGE_TEXT = { Nino = "niño", Adolescente = "adolescente", AdultoJoven = "mayor de edad", Adulto = "adulto", Mayor = "mayor" }

type Ride = {
	Model: Model,
	Kind: string,
	Seat: VehicleSeat,
	Rented: boolean,
	Exam: boolean,
	Keep: boolean, -- se queda aparcado al bajarse
	Died: RBXScriptConnection?,
	Left: RBXScriptConnection?,
	-- Combustible y cuentakilómetros (solo coche, moto y patinete)
	Fuel: number?,
	Odometer: number?,
	Trip: number?,
	Owned: boolean?,
	LastPos: Vector3?,
}
local riding: { [Player]: Ride } = {}

-- Quién va de pasajero y dónde
type Passenger = {
	Model: Model,
	Seat: Seat,
	Kind: string,
	Humanoid: Humanoid,
	Left: RBXScriptConnection?,
	Died: RBXScriptConnection?,
}
local passengers: { [Player]: Passenger } = {}
local dismountListeners: { (Player, string) -> () } = {}
local folder: Folder
local exitedAt: { [Player]: number } = {} -- cuándo se bajó (nada le vuelve a sentar enseguida)
local warnedAt: { [Player]: number } = {} -- último aviso de «conduces sin carnet»

-- ¿Se acaba de bajar? (un cartel pulsado sin querer no le vuelve a subir)
local function justExited(player: Player): boolean
	return os.clock() - (exitedAt[player] or -math.huge) < Gameplay.ExitCooldown
end

local function isDark(): boolean
	local clock = Lighting.ClockTime
	return clock >= 18.3 or clock < 7.2
end

-- Faro delantero de verdad en coche y moto (se enciende de noche)
local function addHeadlight(model: Model)
	local lens = model:FindFirstChild("Headlight")
	if lens and lens:IsA("BasePart") then
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Front
		light.Angle = 60
		light.Range = 50
		light.Brightness = 3.2
		light.Color = Color3.fromRGB(255, 244, 222)
		light.Shadows = false
		light.Enabled = isDark()
		light.Parent = lens
	end
end

-- De regalo desde el principio (se sacan en cualquier sitio desde "Vehículos"; los bebés no pueden)
local STARTER = { "Bici", "Patinete" }

local function ensure(data: { [string]: any })
	data.Vehicles = data.Vehicles or {}
	data.Licenses = data.Licenses or {}
	for _, kind in STARTER do
		data.Vehicles[kind] = true
	end
end

local function listKeys(t: { [string]: any }): string
	local keys = {}
	for key, value in t do
		if value then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	return table.concat(keys, ",")
end

-- El cliente lee estos atributos para pintar el menú de vehículos
function VehicleService.sync(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	ensure(data)
	player:SetAttribute("OwnedVehicles", listKeys(data.Vehicles))
	player:SetAttribute("Licenses", listKeys(data.Licenses))
end

function VehicleService.hasLicense(player: Player, license: string): boolean
	local data = DataService.get(player)
	return data ~= nil and data.Licenses ~= nil and data.Licenses[license] == true
end

function VehicleService.grantLicense(player: Player, license: string)
	local data = DataService.get(player)
	if not data then
		return
	end
	ensure(data)
	data.Licenses[license] = true
	VehicleService.sync(player)
end

-- Regala un vehículo (premios de los recreativos). Devuelve false si ya lo tenía.
function VehicleService.grant(player: Player, kind: string): boolean
	local data = DataService.get(player)
	if not data or not Gameplay.Vehicles[kind] then
		return false
	end
	ensure(data)
	if data.Vehicles[kind] then
		return false
	end
	data.Vehicles[kind] = true
	VehicleService.sync(player)
	return true
end

-- Avisa cuando alguien se baja (la autoescuela suspende si te bajas en el examen)
function VehicleService.onDismount(listener: (Player, string) -> ())
	table.insert(dismountListeners, listener)
end

function VehicleService.ridingKind(player: Player): string?
	local ride = riding[player]
	return if ride then ride.Kind else nil
end

local function stageAllows(player: Player, stage: string, silent: boolean?): boolean
	if Stages.allows(player:GetAttribute("LifeStage"), "Ride", { Ride = stage }) then
		return true
	end
	if not silent then
		Notify:FireClient(player, "Error", ("Tienes que ser %s para esto."):format(STAGE_TEXT[stage] or stage))
	end
	return false
end

-- Aparca el vehículo donde está: anclado, con sus choques de nuevo y quieto
local function park(model: Model)
	local chassis = model.PrimaryPart
	if not chassis then
		return
	end
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
	-- Se deja recto y a ras de suelo (por si se paró inclinado en una cuesta)
	local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)
	if look.Magnitude > 0.1 then
		chassis.CFrame = CFrame.lookAt(chassis.Position, chassis.Position + look.Unit)
	end
	chassis.Anchored = true
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Collide") ~= nil then
			part.CanCollide = part:GetAttribute("Collide")
		end
	end
	model:SetAttribute("Driver", nil)
end

-- Deja a alguien de pie junto al vehículo, por su lado (side: -1 izquierda, 1 derecha) y a la
-- altura de su asiento (along: z del asiento respecto a la base). Siempre en el suelo que haya
-- ahí (nunca dentro ni debajo de nada); si al lado no hay nada firme, encima del vehículo.
local function placeBeside(character: Model, model: Model, kind: string, side: number, along: number?): CFrame?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local chassis = model.PrimaryPart
	if not root or not chassis or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local spec = Rides.Spec[kind]
	local width = if spec then spec.Size.X else chassis.Size.X
	local gap = (width / 2) + 2.5
	local flat = chassis.CFrame.Rotation:VectorToWorldSpace(Vector3.new(side, 0, 0))
	flat = Vector3.new(flat.X, 0, flat.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(side, 0, 0)
	local forward = chassis.CFrame.Rotation:VectorToWorldSpace(Vector3.new(0, 0, along or 0))
	forward = Vector3.new(forward.X, 0, forward.Z)
	local spot = chassis.Position + flat * gap + forward
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, character :: Instance }
	params.RespectCanCollide = true
	local hit = workspace:Raycast(spot + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
	if not hit or (hit.Instance == workspace.Terrain and hit.Position.Y < chassis.Position.Y - 3) then
		-- nada firme al lado: encima del propio vehículo
		hit = workspace:Raycast(chassis.Position + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), params)
		spot = chassis.Position
	end
	local ground = if hit then hit.Position.Y else chassis.Position.Y
	local height = humanoid.HipHeight + root.Size.Y / 2 + 0.5
	-- Mirando hacia el morro, como quien acaba de bajarse (y la cámara queda detrás, no dentro del coche)
	local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)
	look = if look.Magnitude > 0.1 then look.Unit else Vector3.new(0, 0, -1)
	local placed = CFrame.new(spot.X, math.max(ground, chassis.Position.Y - 2) + height, spot.Z) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
	root.CFrame = placed
	root.AssemblyLinearVelocity = Vector3.zero
	-- Vuelve a moverlo su propio ordenador (mientras iba sentado lo movía el del conductor)
	pcall(function()
		root:SetNetworkOwner(Players:GetPlayerFromCharacter(character))
	end)
	return placed
end

-- Quita la soldadura del asiento y levanta al humanoide. Todas las soldaduras (a veces queda más
-- de una) y aunque el asiento ya no diga que está ocupado: así nunca se queda nadie pegado.
local function unseat(humanoid: Humanoid?, seat: BasePart?)
	if seat and seat.Parent then
		for _, child in seat:GetChildren() do
			if child.Name == "SeatWeld" then
				child:Destroy()
			end
		end
	end
	if humanoid then
		humanoid.Sit = false
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end

-- Se ha bajado: su ordenador lo repite al momento (de pie en ese sitio, cámara normal) y durante
-- un momento nada le vuelve a sentar
local switching = false -- (se cambia de vehículo o de asiento: no es bajarse)
local switchOut: (Player) -> ()
local function exited(player: Player, placed: CFrame?)
	if switching then
		return
	end
	exitedAt[player] = os.clock()
	Remote:FireClient(player, "Exited", { CFrame = placed })
end

-- El ordenador del conductor mueve todo el vehículo, con quien vaya dentro
local function claimOwnership(model: Model)
	local chassis = model.PrimaryPart
	local driverId = model:GetAttribute("Driver")
	if not chassis or chassis.Anchored or typeof(driverId) ~= "number" then
		return
	end
	local driver = Players:GetPlayerByUserId(driverId)
	if driver then
		pcall(function()
			chassis:SetNetworkOwner(driver)
		end)
	end
end

---------------------------------------------------------------------
-- Combustible y cuentakilómetros
---------------------------------------------------------------------
local FUEL = Gameplay.Fuel

local function publishFuel(player: Player, ride: Ride)
	local spec = FUEL.Kinds[ride.Kind]
	if not spec or not ride.Fuel then
		return
	end
	player:SetAttribute("Fuel", math.floor(ride.Fuel / spec.Tank * 1000) / 1000)
	player:SetAttribute("FuelType", spec.Type)
	player:SetAttribute("Odometer", math.floor((ride.Odometer or 0) * 10) / 10)
	player:SetAttribute("Trip", math.floor((ride.Trip or 0) * 100) / 100)
	player:SetAttribute("OutOfFuel", ride.Fuel <= 0)
end

local function clearFuel(player: Player)
	for _, key in { "Fuel", "FuelType", "Odometer", "Trip", "OutOfFuel" } do
		player:SetAttribute(key, nil)
	end
end

-- Al subir: el depósito de tu vehículo (guardado) o el del coche de la calle (en el modelo)
local function loadFuel(player: Player, ride: Ride)
	local spec = FUEL.Kinds[ride.Kind]
	if not spec or ride.Exam then
		return
	end
	local model = ride.Model
	ride.Owned = model:GetAttribute("OwnerId") == player.UserId and ride.Keep
	if ride.Owned then
		local data = DataService.get(player)
		if data then
			data.Fuel = data.Fuel or {}
			data.Odometer = data.Odometer or {}
			ride.Fuel = data.Fuel[ride.Kind] or spec.Tank
			ride.Odometer = data.Odometer[ride.Kind] or 0
		end
	end
	if not ride.Fuel then
		-- Coches de la calle y alquilados: cada uno con su depósito y sus kilómetros
		ride.Fuel = model:GetAttribute("Fuel") or spec.Tank * (0.35 + math.random() * 0.6)
		ride.Odometer = model:GetAttribute("Odometer") or math.random(3000, 140000) + math.random()
	end
	ride.Trip = 0
	ride.LastPos = model.PrimaryPart and model.PrimaryPart.Position
	publishFuel(player, ride)
end

local function saveFuel(player: Player, ride: Ride)
	if not ride.Fuel then
		return
	end
	if ride.Owned then
		local data = DataService.get(player)
		if data then
			data.Fuel = data.Fuel or {}
			data.Odometer = data.Odometer or {}
			data.Fuel[ride.Kind] = ride.Fuel
			data.Odometer[ride.Kind] = ride.Odometer
		end
	end
	if ride.Model.Parent then
		ride.Model:SetAttribute("Fuel", ride.Fuel)
		ride.Model:SetAttribute("Odometer", ride.Odometer)
	end
end

-- Cada medio segundo: gasta según la distancia recorrida
local function burnFuel()
	for player, ride in riding do
		local spec = FUEL.Kinds[ride.Kind]
		local chassis = ride.Model.PrimaryPart
		if spec and ride.Fuel and chassis then
			local pos = chassis.Position
			local last = ride.LastPos or pos
			local d = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
			ride.LastPos = pos
			if d > 0.05 and d < 200 then -- (un salto grande es un teletransporte, no un viaje)
				ride.Fuel = math.max(0, ride.Fuel - d / 1000 * spec.Per1000)
				local km = d * FUEL.KmPerStud
				ride.Odometer = (ride.Odometer or 0) + km
				ride.Trip = (ride.Trip or 0) + km
				local wasEmpty = player:GetAttribute("OutOfFuel")
				publishFuel(player, ride)
				if ride.Fuel <= 0 and not wasEmpty then
					Notify:FireClient(player, "Error", if spec.Type == "Bateria" then "🔋 ¡Sin batería! Llévalo a cargar a una gasolinera." else "⛽ ¡Sin gasolina! Empuja hasta una gasolinera y reposta.")
				end
			end
		end
	end
end

-- Surtidor: reposta (o carga la batería) del vehículo en el que vas
local function refuel(player: Player, pump: BasePart)
	local ride = riding[player]
	local spec = ride and FUEL.Kinds[ride.Kind]
	if not ride or not spec or not ride.Fuel then
		Notify:FireClient(player, "Info", "Acércate al surtidor montado en tu coche, moto o patinete eléctrico.")
		return
	end
	local chassis = ride.Model.PrimaryPart
	if chassis and (chassis.Position - pump.Position).Magnitude > 18 then
		Notify:FireClient(player, "Info", "Arrima el vehículo al surtidor.")
		return
	end
	local missing = spec.Tank - ride.Fuel
	if missing < 0.5 then
		Notify:FireClient(player, "Info", if spec.Type == "Bateria" then "La batería ya está llena." else "El depósito ya está lleno.")
		return
	end
	-- Gasolinera de un jugador: su precio, y como mucho los litros que le quedan (BusinessService)
	local price, left = spec.Price, math.huge
	local seller = VehicleService.FuelSeller
	if seller and spec.Type == "Gasolina" then
		local ok, p, stock = pcall(seller.quote, pump)
		if ok and type(p) == "number" and type(stock) == "number" and p > 0 then
			price, left = p, stock
		end
	end
	local data = DataService.get(player)
	local money = data and data.Money or 0
	local amount = math.min(missing, math.floor(money / price), left)
	if amount < 0.5 then
		Notify:FireClient(player, "Error", "No tienes dinero para repostar.")
		return
	end
	local cost = math.max(1, math.ceil(amount * price))
	if not DataService.spend(player, cost) then
		Notify:FireClient(player, "Error", "No tienes dinero para repostar.")
		return
	end
	ride.Fuel = math.min(spec.Tank, ride.Fuel + amount)
	publishFuel(player, ride)
	if seller and left ~= math.huge then
		pcall(seller.sold, pump, amount, cost)
	end
	if spec.Type == "Bateria" then
		Notify:FireClient(player, "Success", ("🔋 Batería cargada al %d%% (%s)"):format(math.floor(ride.Fuel / spec.Tank * 100), Format.money(cost)))
	else
		Notify:FireClient(player, "Success", ("⛽ Has repostado %.1f L (%s)"):format(amount, Format.money(cost)))
	end
end

function VehicleService.dismount(player: Player, silent: boolean?)
	local ride = riding[player]
	if not ride then
		return
	end
	riding[player] = nil
	saveFuel(player, ride)
	clearFuel(player)
	if ride.Died then
		ride.Died:Disconnect()
	end
	if ride.Left then
		ride.Left:Disconnect()
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	unseat(humanoid, ride.Seat)
	if ride.Keep and ride.Model.Parent then
		park(ride.Model)
	end
	-- Se baja por el lado izquierdo (del coche, fuera de la carrocería)
	local placed = if character then placeBeside(character, ride.Model, ride.Kind, -1, 0) else nil
	exited(player, placed)
	if not ride.Keep then
		-- Vehículo de alquiler o de trabajo: se retira (los pasajeros se bajan antes, a su lado)
		VehicleService.emptyPassengers(ride.Model)
		ride.Model:Destroy()
	end
	player:SetAttribute("Riding", nil)
	player:SetAttribute("VehicleSpeed", nil)
	LifeService.refresh(player) -- vuelve la velocidad y el salto de su edad
	if not silent then
		Notify:FireClient(player, "Info", "Te has bajado.")
	end
	for _, listener in dismountListeners do
		task.spawn(listener, player, ride.Kind)
	end
end

---------------------------------------------------------------------
-- Pasajeros
---------------------------------------------------------------------
local function orphanExit(player: Player): boolean
	-- Sentado en un vehículo sin que el servidor lo sepa (una desincronización): se le baja igual
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat:FindFirstAncestorOfClass("Model")
	if not character or not humanoid or not seat or not model or not model:GetAttribute("Drivable") then
		return false
	end
	unseat(humanoid, seat)
	local kind = model:GetAttribute("Kind")
	local chassis = model.PrimaryPart
	local side = seat:GetAttribute("Side")
	local along = if chassis then chassis.CFrame:PointToObjectSpace(seat.Position).Z else 0
	-- Si iba al volante, el vehículo se queda aparcado ahí (salvo que lo conduzca otra persona)
	local driver = model:GetAttribute("Driver")
	if seat.Name == "DriverSeat" and (driver == nil or driver == player.UserId) and chassis and not chassis.Anchored then
		park(model)
	end
	local placed = placeBeside(character, model, if typeof(kind) == "string" then kind else "Coche", if typeof(side) == "number" then side else -1, along)
	player:SetAttribute("Riding", nil)
	player:SetAttribute("Passenger", nil)
	player:SetAttribute("VehicleSpeed", nil)
	LifeService.refresh(player)
	exited(player, placed)
	return true
end

-- Bajarse pase lo que pase (tecla F / B, botón «Bajarse» o «Levantarse»): conduciendo, de
-- pasajero o sentado en un vehículo sin que el servidor lo sepa. Siempre contesta a su ordenador
-- ("Exited"), que se levanta él también: nunca se queda nadie dentro.
function VehicleService.exitAny(player: Player, silent: boolean?)
	if riding[player] then
		VehicleService.dismount(player, silent)
	elseif passengers[player] then
		VehicleService.leavePassenger(player, silent)
	elseif not orphanExit(player) then
		exited(player, nil)
	end
end

function VehicleService.passengerKind(player: Player): string?
	local entry = passengers[player]
	return if entry then entry.Kind else nil
end

-- Se baja del asiento de pasajero. place = false: no se le recoloca (se cambia de asiento,
-- se muere o se va del juego)
function VehicleService.leavePassenger(player: Player, silent: boolean?, place: boolean?)
	local entry = passengers[player]
	if not entry then
		return
	end
	passengers[player] = nil
	if entry.Left then
		entry.Left:Disconnect()
	end
	if entry.Died then
		entry.Died:Disconnect()
	end
	player:SetAttribute("Passenger", nil)
	local seat = entry.Seat
	if seat.Occupant == nil or seat.Occupant == entry.Humanoid then
		unseat(if entry.Humanoid.SeatPart == seat or seat.Occupant == entry.Humanoid then entry.Humanoid else nil, seat)
	elseif entry.Humanoid.SeatPart == seat then
		entry.Humanoid.Sit = false
	end
	local character = player.Character
	local chassis = entry.Model.PrimaryPart
	local placed: CFrame? = nil
	if place ~= false and character and chassis and entry.Model.Parent then
		local along = chassis.CFrame:PointToObjectSpace(seat.Position).Z
		local side = seat:GetAttribute("Side")
		placed = placeBeside(character, entry.Model, entry.Kind, if typeof(side) == "number" then side else 1, along)
	end
	if place ~= false then
		exited(player, placed)
	end
	if not silent then
		Notify:FireClient(player, "Info", "Te has bajado.")
	end
end

-- Se cambia de vehículo o de asiento: se baja del anterior sin que eso cuente como bajarse
function switchOut(player: Player)
	switching = true
	local ok, err = pcall(function()
		VehicleService.dismount(player, true)
		VehicleService.leavePassenger(player, true, false)
	end)
	switching = false
	if not ok then
		warn("[Vehicles] " .. tostring(err))
	end
end

-- Todos abajo (el vehículo se va a retirar): cada uno por su lado
function VehicleService.emptyPassengers(model: Model)
	for player, entry in passengers do
		if entry.Model == model then
			VehicleService.leavePassenger(player, true)
		end
	end
end

-- Sube a alguien a un asiento de pasajero. Cualquiera puede ir de pasajero (también en un coche
-- ajeno o aparcado); tu vehículo solo lo conduces tú.
function VehicleService.board(player: Player, seat: Seat): boolean
	local model = seat.Parent
	if not model or not model:IsA("Model") or not model:GetAttribute("Drivable") or seat.Name ~= "RideSeat" then
		return false
	end
	local kind = model:GetAttribute("Kind")
	if typeof(kind) ~= "string" then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end
	if justExited(player) then
		return false -- se acaba de bajar: un cartel pulsado sin querer no le vuelve a sentar
	end
	if player:GetAttribute("Sleeping") or player:GetAttribute("Crawling") or player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
		return false
	end
	if not LifeService.allows(player, "Travel") then
		return false
	end
	if seat.Occupant and seat.Occupant ~= humanoid then
		Notify:FireClient(player, "Error", "Ese asiento ya está ocupado.")
		return false
	end
	-- Ya va en este vehículo: para cambiarse de sitio, que se baje primero
	local ride = riding[player]
	local current = passengers[player]
	if (ride and ride.Model == model) or (current and current.Model == model) then
		return false
	end
	if ride and ride.Exam then
		return false -- en el examen práctico no se cambia de vehículo
	end
	switchOut(player)
	if humanoid.SeatPart then
		unseat(humanoid, humanoid.SeatPart)
	end
	root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
	seat:Sit(humanoid)
	local entry: Passenger = { Model = model, Seat = seat, Kind = kind, Humanoid = humanoid }
	passengers[player] = entry
	-- Saltar (o "Bajarse") le levanta del asiento: se baja por su lado
	entry.Left = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant ~= humanoid and passengers[player] == entry then
			VehicleService.leavePassenger(player)
		end
	end)
	entry.Died = humanoid.Died:Connect(function()
		if passengers[player] == entry then
			VehicleService.leavePassenger(player, true, false)
		end
	end)
	player:SetAttribute("Passenger", kind)
	claimOwnership(model)
	local vehicle = Gameplay.Vehicles[kind]
	Notify:FireClient(player, "Info", ("%s Vas de pasajero. Para bajarte, salta o pulsa «Bajarse»."):format(vehicle and vehicle.Icon or "🚗"))
	return true
end

-- Carteles de los asientos de pasajero ("Subir de copiloto", "Subir detrás") de un vehículo
-- preparado con Rides.prepare. Si el vehículo se retira, los pasajeros se bajan antes.
local function setupSeats(model: Model, kind: string)
	if model:GetAttribute("SeatsReady") then
		return
	end
	model:SetAttribute("SeatsReady", true)
	local vehicle = Gameplay.Vehicles[kind]
	local spec = Rides.Spec[kind]
	local big = spec ~= nil and spec.Size.X > 7
	for _, seat in model:GetChildren() do
		if seat:IsA("Seat") and seat.Name == "RideSeat" then
			local label = seat:GetAttribute("Label")
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "SeatPrompt"
			prompt.ActionText = if typeof(label) == "string" then label else "Sentarse"
			prompt.ObjectText = if vehicle then vehicle.Icon .. " " .. vehicle.Name else ""
			prompt.MaxActivationDistance = if big then 10 else 7
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = 0.2
			prompt.Parent = seat
			prompt.Triggered:Connect(function(player)
				VehicleService.board(player, seat)
			end)
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				prompt.Enabled = seat.Occupant == nil
			end)
		end
	end
	model.Destroying:Connect(function()
		VehicleService.emptyPassengers(model)
	end)
end
VehicleService.setupSeats = setupSeats

-- ¿Qué delito comete ahora mismo al volante? nil = ninguno (no pide carnet, lo tiene o es el
-- examen práctico de la autoescuela). Lo vigila WantedService: solo cuenta si le ve la policía.
function VehicleService.drivingOffence(player: Player): string?
	local ride = riding[player]
	if not ride or ride.Exam then
		return nil
	end
	local vehicle = Gameplay.Vehicles[ride.Kind]
	if vehicle and vehicle.Hidden and player:GetAttribute("Job") then
		return nil -- (el vehículo de tu trabajo, de servicio: autobús, patrulla, camión…)
	end
	local license = vehicle and vehicle.License
	local has = license ~= nil and VehicleService.hasLicense(player, license)
	return Gameplay.drivingOffence(player:GetAttribute("LifeStage"), has, ride.Kind)
end

-- Lo rápido que va su vehículo (studs/s, sin contar la altura)
function VehicleService.rideSpeed(player: Player): number
	local ride = riding[player]
	local chassis = ride and ride.Model.PrimaryPart
	local velocity = chassis and chassis.AssemblyLinearVelocity
	if typeof(velocity) ~= "Vector3" then
		return 0
	end
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
end

-- El vehículo que conduce (o nil)
function VehicleService.rideModel(player: Player): Model?
	local ride = riding[player]
	return if ride then ride.Model else nil
end

-- ¿Puede conducir este vehículo? Cualquiera desde niño (los bebés no), con carnet o sin él.
-- Sin el carnet que toca se le avisa: si le ve la policía, le parará.
local function allowed(player: Player, kind: string, exam: boolean?): boolean
	local vehicle = Gameplay.Vehicles[kind]
	if not vehicle then
		return false
	end
	if player:GetAttribute("Sleeping") or player:GetAttribute("Crawling") then
		return false
	end
	if not stageAllows(player, Gameplay.DriveMinStage) then
		return false
	end
	if vehicle.License and not exam then
		local has = VehicleService.hasLicense(player, vehicle.License)
		local offence = Gameplay.drivingOffence(player:GetAttribute("LifeStage"), has, kind)
		if offence and os.clock() - (warnedAt[player] or -math.huge) > 60 then
			warnedAt[player] = os.clock()
			if offence == "MenorVolante" then
				Notify:FireClient(player, "Error", "⚠️ Eres menor y no tienes carnet: si te ve la policía conduciendo, te parará y llamará a tu familia.")
			else
				Notify:FireClient(player, "Error", ("⚠️ Conduces sin el %s: si te ve una patrulla, te parará (es delito)."):format(Gameplay.Licenses[vehicle.License].Name))
			end
		end
	end
	return true
end

-- Sube al jugador al asiento del conductor de un vehículo preparado (Rides.prepare).
-- keep = el vehículo se queda aparcado al bajarse (coches de la calle y los tuyos)
local function drive(player: Player, model: Model, kind: string, opts: { Rented: boolean?, Exam: boolean?, Keep: boolean? }): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local seat = model:FindFirstChild("DriverSeat") :: VehicleSeat?
	local chassis = model.PrimaryPart
	if not humanoid or not root or humanoid.Health <= 0 or not seat or not chassis then
		return false
	end
	if seat.Occupant and seat.Occupant ~= humanoid then
		Notify:FireClient(player, "Error", "Ya hay alguien conduciendo.")
		return false
	end
	switchOut(player) -- (si iba de pasajero, se pasa al volante)
	if humanoid.SeatPart then
		unseat(humanoid, humanoid.SeatPart)
	end

	-- En marcha: sin choques (lo guía Driving.luau con rayos) y suelto para que se mueva
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= chassis then
			part.CanCollide = false
		end
	end
	model.Parent = folder
	chassis.Anchored = false
	model:SetAttribute("Driver", player.UserId)

	-- De pie en el monopatín y el patinete: el personaje se coloca de pie sobre la tabla
	local standing = Rides.Spec[kind].Standing
	local added: RBXScriptConnection? = nil
	if standing then
		added = seat.ChildAdded:Connect(function(child)
			if child:IsA("Weld") and child.Name == "SeatWeld" then
				local legs = if humanoid.RigType == Enum.HumanoidRigType.R6 then 2 else 0
				local height = humanoid.HipHeight + root.Size.Y / 2 + legs
				child.C1 = CFrame.new(0, -height, 0) * child.C1.Rotation
			end
		end)
	end
	root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
	seat:Sit(humanoid)
	if added then
		task.delay(1, function()
			(added :: RBXScriptConnection):Disconnect()
		end)
	end
	pcall(function()
		chassis:SetNetworkOwner(player) -- lo conduce su ordenador (sin retraso)
	end)

	local vehicle = Gameplay.Vehicles[kind]
	local ride: Ride = {
		Model = model,
		Kind = kind,
		Seat = seat,
		Rented = opts.Rented == true,
		Exam = opts.Exam == true,
		Keep = opts.Keep == true,
	}
	ride.Died = humanoid.Died:Connect(function()
		VehicleService.dismount(player, true)
	end)
	-- Saltar (o F) le baja del asiento: entonces se aparca
	ride.Left = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant ~= humanoid and riding[player] == ride then
			VehicleService.dismount(player)
		end
	end)
	riding[player] = ride
	loadFuel(player, ride)
	player:SetAttribute("Riding", kind)
	player:SetAttribute("VehicleSpeed", vehicle.Speed)
	StoryEvents.emit(player, "VehicleMounted", { Vehicle = kind, Rented = ride.Rented })
	return true
end

-- Cartel "Conducir" en un vehículo aparcado. owner = solo lo puede coger su dueño
local function addDrivePrompt(model: Model, kind: string, owner: Player?)
	local chassis = model.PrimaryPart
	if not chassis or chassis:FindFirstChild("DrivePrompt") then
		return
	end
	local vehicle = Gameplay.Vehicles[kind]
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DrivePrompt"
	prompt.ActionText = if kind == "Coche" then "Conducir" else "Montar"
	prompt.ObjectText = if owner then vehicle.Icon .. " Tu " .. string.lower(vehicle.Name) else vehicle.Icon .. " " .. vehicle.Name
	prompt.MaxActivationDistance = if kind == "Coche" then 11 else 7
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.25
	prompt.Parent = chassis
	prompt.Triggered:Connect(function(player)
		if owner and player ~= owner then
			Notify:FireClient(player, "Error", "Este vehículo es de otra persona.")
			return
		end
		local ride = riding[player]
		if (ride and ride.Exam) or justExited(player) then
			return
		end
		if allowed(player, kind) then
			drive(player, model, kind, { Keep = true })
		end
	end)
	model:GetAttributeChangedSignal("Driver"):Connect(function()
		prompt.Enabled = model:GetAttribute("Driver") == nil
	end)
end

-- Coche aparcado de la ciudad (decorativo) -> se puede conducir
local function setupParkedCar(model: Instance)
	if not model:IsA("Model") or model.Name ~= "ParkedCar" or model:GetAttribute("Drivable") then
		return
	end
	local body = model:FindFirstChild("Body")
	if not body or not body:IsA("BasePart") then
		return
	end
	-- Carteles ligeros en la carrocería; el coche solo se prepara cuando alguien lo coge
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DrivePrompt"
	prompt.ActionText = "Conducir"
	prompt.ObjectText = "🚗 Coche"
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.25
	prompt.Parent = body
	local sit = Instance.new("ProximityPrompt")
	sit.Name = "SitPrompt"
	sit.ActionText = "Sentarse"
	sit.ObjectText = "🚗 Coche aparcado"
	sit.MaxActivationDistance = 9
	sit.RequiresLineOfSight = false
	sit.HoldDuration = 0.25
	sit.UIOffset = Vector2.new(0, 58)
	sit.Parent = body
	-- Al cogerlo (o sentarse) se ve con todo detalle (interior, montantes, retrovisores…) y ya
	-- tiene sus asientos de verdad, cada uno con su cartel
	local function activate()
		prompt:Destroy()
		sit:Destroy()
		local ground = body.CFrame * CFrame.new(0, -2.2, 0)
		require(script.Parent.Parent.World.Kit.CarModel).upgrade(model :: Model, ground)
		Rides.prepare(model :: Model, "Coche", ground)
		addDrivePrompt(model :: Model, "Coche")
		addHeadlight(model :: Model)
		setupSeats(model :: Model, "Coche")
	end
	prompt.Triggered:Connect(function(player)
		local ride = riding[player]
		if (ride and ride.Exam) or justExited(player) or not allowed(player, "Coche") or model:GetAttribute("Drivable") then
			return
		end
		activate()
		drive(player, model :: Model, "Coche", { Keep = true })
	end)
	sit.Triggered:Connect(function(player)
		local ride = riding[player]
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if (ride and ride.Exam) or justExited(player) or not root or model:GetAttribute("Drivable") or not LifeService.allows(player, "Travel") then
			return
		end
		activate()
		-- El asiento libre más cercano (el de su lado)
		local best, bestD = nil, math.huge
		for _, seat in model:GetChildren() do
			if seat:IsA("Seat") and seat.Name == "RideSeat" and not seat.Occupant then
				local d = (seat.Position - root.Position).Magnitude
				if d < bestD then
					best, bestD = seat, d
				end
			end
		end
		if best then
			VehicleService.board(player, best)
		end
	end)
end

-- Sube al jugador a un vehículo ya preparado con Rides.prepare (lo usa BusService con el autobús).
-- Al bajarse, el vehículo se queda aparcado donde esté.
function VehicleService.driveModel(player: Player, model: Model, kind: string): boolean
	if not allowed(player, kind) then
		return false
	end
	return drive(player, model, kind, { Keep = true })
end

-- Tu vehículo aparcado (solo uno a la vez: al sacar otro, el anterior desaparece)
local parked: { [Player]: Model } = {}

-- Crea un vehículo al lado del jugador y le sube. opts.Rented = de una estación pública;
-- opts.Exam = examen práctico (sin carnet). Los tuyos se quedan aparcados al bajarte.
function VehicleService.mount(player: Player, kind: string, opts: { Rented: boolean?, Exam: boolean? }?): boolean
	local options = opts or {}
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not allowed(player, kind, options.Exam) then
		return false
	end
	switchOut(player)
	-- Sale a ras de suelo delante del jugador, mirando hacia donde mira
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = if look.Magnitude > 0.1 then look.Unit else Vector3.new(0, 0, -1)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character :: Instance, folder }
	params.RespectCanCollide = true
	local from = root.Position + look * 2 + Vector3.new(0, 2, 0)
	local hit = workspace:Raycast(from, Vector3.new(0, -20, 0), params)
	local ground = if hit then hit.Position else root.Position - Vector3.new(0, 3, 0)
	local cf = CFrame.lookAt(ground, ground + look)
	local model = Rides.build(kind, nil, cf)
	model:SetAttribute("OwnerId", player.UserId)
	Rides.prepare(model, kind, cf)
	addHeadlight(model)
	setupSeats(model, kind)
	model.Parent = folder
	local keep = not options.Rented and not options.Exam
	if keep then
		if parked[player] and parked[player] ~= model then
			parked[player]:Destroy()
		end
		parked[player] = model
		addDrivePrompt(model, kind, player)
	end
	if not drive(player, model, kind, { Rented = options.Rented, Exam = options.Exam, Keep = keep }) then
		model:Destroy()
		return false
	end
	return true
end

function VehicleService.buy(player: Player, kind: string)
	local vehicle = Gameplay.Vehicles[kind]
	local data = DataService.get(player)
	if not vehicle or not data or vehicle.Hidden then
		return
	end
	ensure(data)
	if data.Vehicles[kind] then
		Notify:FireClient(player, "Info", "Ya tienes " .. vehicle.Name .. ".")
		return
	end
	if not stageAllows(player, vehicle.Stage) then
		return
	end
	if not DataService.spend(player, vehicle.Price) then
		Notify:FireClient(player, "Error", "No tienes suficiente dinero (" .. Format.money(vehicle.Price) .. ").")
		return
	end
	data.Vehicles[kind] = true
	VehicleService.sync(player)
	Notify:FireClient(player, "Success", ("¡%s %s es tuyo!"):format(vehicle.Icon, vehicle.Name))
	StoryEvents.emit(player, "VehicleBought", { Vehicle = kind })
end

local function spawnOwned(player: Player, kind: string)
	local data = DataService.get(player)
	if not data or not Gameplay.Vehicles[kind] then
		return
	end
	ensure(data)
	if not data.Vehicles[kind] then
		Notify:FireClient(player, "Error", "Todavía no tienes ese vehículo.")
		return
	end
	local ride = riding[player]
	if ride and ride.Exam then
		return -- en el examen no se cambia de vehículo
	end
	VehicleService.mount(player, kind)
end

local function setupStation(station: Instance)
	if not station:IsA("BasePart") then
		return
	end
	for i, kind in Gameplay.RentalVehicles do
		local vehicle = Gameplay.Vehicles[kind]
		local prompt = Builder.prompt(station, "Coger " .. string.lower(vehicle.Name), vehicle.Icon .. " Público · gratis", 0.3)
		prompt.KeyboardKeyCode = ({ Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.T })[i] or Enum.KeyCode.E
		prompt.UIOffset = Vector2.new(0, (i - 1) * 58)
		prompt.Triggered:Connect(function(player)
			local ride = riding[player]
			if ride and ride.Exam then
				return
			end
			VehicleService.mount(player, kind, { Rented = true })
		end)
	end
end

function VehicleService.init()
	folder = Instance.new("Folder")
	folder.Name = "Rides"
	folder.Parent = workspace

	for _, station in CollectionService:GetTagged("RentalStation") do
		setupStation(station)
	end
	CollectionService:GetInstanceAddedSignal("RentalStation"):Connect(setupStation)

	-- Coches aparcados por toda la ciudad
	task.defer(function()
		local town = workspace:FindFirstChild("Town")
		if town then
			for _, model in town:GetDescendants() do
				if model.Name == "ParkedCar" then
					setupParkedCar(model)
				end
			end
		end
	end)

	DataService.onLoaded(function(player)
		VehicleService.sync(player)
	end)

	Remote.OnServerEvent:Connect(function(player, action, kind)
		if action == "Dismount" then
			VehicleService.exitAny(player)
		elseif action == "Spawn" and typeof(kind) == "string" then
			spawnOwned(player, kind)
		elseif action == "Buy" and typeof(kind) == "string" then
			VehicleService.buy(player, kind)
		end
	end)

	local function watchCharacter(player: Player)
		player.CharacterRemoving:Connect(function()
			VehicleService.dismount(player, true)
			VehicleService.leavePassenger(player, true, false)
		end)
	end
	Players.PlayerAdded:Connect(watchCharacter)
	for _, player in Players:GetPlayers() do
		watchCharacter(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		VehicleService.dismount(player, true)
		VehicleService.leavePassenger(player, true, false)
		if parked[player] then
			parked[player]:Destroy()
			parked[player] = nil
		end
		exitedAt[player] = nil
		warnedAt[player] = nil
	end)

	-- Surtidores de las gasolineras
	local function setupPump(pump: Instance)
		if not pump:IsA("BasePart") or pump:FindFirstChild("FuelPrompt") then
			return
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "FuelPrompt"
		prompt.ActionText = "Repostar / cargar"
		prompt.ObjectText = "⛽ Gasolina 1,50 €/L · 🔋 carga 0,10 €/%"
		prompt.HoldDuration = 0.8
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.Parent = pump
		prompt.Triggered:Connect(function(player)
			refuel(player, pump)
		end)
	end
	for _, pump in CollectionService:GetTagged("FuelPump") do
		setupPump(pump)
	end
	CollectionService:GetInstanceAddedSignal("FuelPump"):Connect(setupPump)
	task.spawn(function()
		while true do
			task.wait(0.5)
			burnFuel()
		end
	end)

	-- Un bebé (o quien vuelve a serlo, p. ej. al empezar una vida nueva) no puede seguir montado
	task.spawn(function()
		while true do
			task.wait(2)
			local dark = isDark()
			for player, ride in riding do
				for _, light in ride.Model:GetDescendants() do
					if light:IsA("SpotLight") then
						light.Enabled = dark
					end
				end
				if player:GetAttribute("Crawling") or not stageAllows(player, Gameplay.DriveMinStage, true) then
					VehicleService.dismount(player, true)
				end
			end
		end
	end)
end

return VehicleService
