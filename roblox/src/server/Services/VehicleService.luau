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
--   * Barcos (Gameplay.Vehicles con Boat = true: lancha y «Gaviota»): se conducen igual, pero solo se
--     sacan y se guardan en el puerto deportivo (BoatService, VehicleService.launchAt) y navegan
--     por el mar (Driving + shared/Boats). Al bajarse cerca de un pantalán se sale a él; en alta mar
--     te quedas de pie en cubierta (el barco queda fondeado donde lo dejas).
-- Datos guardados: data.Vehicles = { Bici = true, ... }, data.Licenses = { A = true, B = true }
-- (los barcos van aparte: data.Boats, ver BoatService)

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Ground = require(ReplicatedStorage.Shared.Ground)
local RideSpot = require(ReplicatedStorage.Shared.RideSpot)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Builder = require(script.Parent.Parent.World.Builder)
local Rides = require(script.Parent.Parent.World.Kit.Rides)
local DataService = require(script.Parent.DataService)
local TesterService = require(script.Parent.TesterService) -- modo pruebas: se salta los requisitos
local LifeService = require(script.Parent.LifeService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local VehicleService = {}

-- Acabado de los vehículos propios (pase de temporada, BattlePassRewardService.paintFor): color con el
-- que sale tu vehículo al sacarlo. Solo cambia el aspecto (mismas prestaciones). nil = color al azar.
VehicleService.PaintFor = nil :: ((Player, string) -> Color3?)?

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
	Gone: RBXScriptConnection?, -- el vehículo desaparece con él dentro
	-- Combustible y cuentakilómetros (solo coche, moto y patinete)
	Fuel: number?,
	Odometer: number?,
	Trip: number?,
	Owned: boolean?,
	Driven: number?, -- studs recorridos en este viaje (todos los vehículos; lo usa el pase de temporada)
	LastPos: Vector3?,
	LastCFrame: CFrame?, -- último sitio bueno de la base (si salta de golpe, vuelve aquí)
	LastAt: number?,
	Reseated: boolean?, -- ya se le volvió a sentar una vez (el personaje no llegó a sentarse)
	Reseating: boolean?, -- se le está volviendo a sentar ahora (quitar la soldadura no es bajarse)
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
local leftModel: { [Player]: Model } = {} -- el vehículo del que se bajó (no se vuelve a subir enseguida)
local spawnedAt: { [Player]: { number } } = {} -- cuándo sacó sus últimos vehículos desde el menú
local SAME_VEHICLE_COOLDOWN = 3 -- segundos sin volver a subir al mismo vehículo
local SPAWN_BURST, SPAWN_WINDOW = 3, 6 -- como mucho 3 vehículos sacados cada 6 s (uno cada 2 s de media)

-- ¿Se acaba de bajar? (un cartel pulsado sin querer no le vuelve a subir)
local function justExited(player: Player): boolean
	return os.clock() - (exitedAt[player] or -math.huge) < Gameplay.ExitCooldown
end

-- ¿Se acaba de bajar de ESTE vehículo? (un cartel pulsado sin querer no le vuelve a subir). Al tuyo
-- propio sí puedes volver enseguida (pasado Gameplay.ExitCooldown): es tuyo y lo coges a propósito.
local function justLeft(player: Player, model: Instance): boolean
	if model:GetAttribute("OwnerId") == player.UserId then
		return false
	end
	return leftModel[player] == model and os.clock() - (exitedAt[player] or -math.huge) < SAME_VEHICLE_COOLDOWN
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
	local vehicle = Gameplay.Vehicles[kind]
	if not data or not vehicle or vehicle.Boat then
		return false -- (los barcos los da BoatService)
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
	if Stages.allows(player:GetAttribute("LifeStage"), "Ride", { Ride = stage }) or TesterService.bypass(player) then
		return true
	end
	if not silent then
		Notify:FireClient(player, "Error", ("Tienes que ser %s para esto."):format(STAGE_TEXT[stage] or stage))
	end
	return false
end

-- Lo deja quieto, recto y a ras de suelo (por si se paró inclinado en una cuesta)
local function level(model: Model)
	local chassis = model.PrimaryPart
	if not chassis then
		return
	end
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
	local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)
	if look.Magnitude > 0.1 then
		chassis.CFrame = CFrame.lookAt(chassis.Position, chassis.Position + look.Unit)
	end
	-- A ras de suelo: si se quedó medio hundido (o en el aire), se apoya en el suelo que tenga debajo.
	-- (Los barcos no: flotan donde están.) Solo si el suelo está cerca: nunca a otro piso.
	local kind = model:GetAttribute("Kind")
	local spec = typeof(kind) == "string" and Rides.Spec[kind] or nil
	if spec and spec.Boat then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { model }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.RespectCanCollide = true
	local half = chassis.Size.Y / 2
	local hit = Ground.cast(chassis.Position + Vector3.new(0, 4, 0), Vector3.new(0, -12, 0), params)
	if hit and hit.Material ~= Enum.Material.Water then
		local base = chassis.Position.Y - half
		if math.abs(hit.Position.Y - base) > 0.2 and math.abs(hit.Position.Y - base) < 6 then
			chassis.CFrame = chassis.CFrame + Vector3.new(0, hit.Position.Y - base, 0)
		end
	end
end

-- Aparca el vehículo donde está: anclado, con sus choques de nuevo y quieto
-- (leveled = ya se ha dejado recto antes de bajar a la gente)
local function park(model: Model, leveled: boolean?)
	local chassis = model.PrimaryPart
	if not chassis then
		return
	end
	if not leveled then
		level(model)
	end
	chassis.Anchored = true
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Collide") ~= nil then
			part.CanCollide = part:GetAttribute("Collide")
		end
	end
	model:SetAttribute("Driver", nil)
	Rides.setStand(model, true) -- aparcada: la pata de cabra (o el caballete) abajo
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
	local length = if spec then spec.Size.Z else chassis.Size.Z
	local gap = (width / 2) + 2.5
	local flat = chassis.CFrame.Rotation:VectorToWorldSpace(Vector3.new(1, 0, 0))
	flat = Vector3.new(flat.X, 0, flat.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.xAxis
	local forward = chassis.CFrame.Rotation:VectorToWorldSpace(Vector3.new(0, 0, along or 0))
	forward = Vector3.new(forward.X, 0, forward.Z)
	-- Mirando hacia el morro, como quien acaba de bajarse (y la cámara queda detrás, no dentro del coche)
	local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)
	look = if look.Magnitude > 0.1 then look.Unit else Vector3.new(0, 0, -1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, character :: Instance }
	params.RespectCanCollide = true
	local height = humanoid.HipHeight + root.Size.Y / 2 + 0.5
	-- (a la altura del asiento; en un barco, por encima del pantalán: su borde no es una pared)
	local boat = spec ~= nil and spec.Boat == true
	local lift = Vector3.new(0, if boat then 3.5 else 2, 0)
	-- Su lado; si hay una pared, el otro; luego delante y detrás. Nunca a través de una pared
	-- (rayo en horizontal desde el asiento) y siempre sobre suelo firme (rayo hacia abajo desde poco
	-- más arriba del vehículo: así no acaba encima de un toldo o un tejado)
	local seatAt = chassis.Position + forward
	local tries = {
		{ seatAt, seatAt + flat * side * gap },
		{ seatAt, seatAt - flat * side * gap },
		{ chassis.Position, chassis.Position + look * (length / 2 + 2.5) },
		{ chassis.Position, chassis.Position - look * (length / 2 + 2.5) },
	}
	if boat then
		-- Un barco se arrima al pantalán con algo de hueco: también un poco más lejos
		for _, extra in { 3, 6 } do
			table.insert(tries, { seatAt, seatAt + flat * side * (gap + extra) })
			table.insert(tries, { seatAt, seatAt - flat * side * (gap + extra) })
			table.insert(tries, { chassis.Position, chassis.Position - look * (length / 2 + 2.5 + extra) })
		end
	end
	local spot, ground = nil :: Vector3?, nil :: number?
	for _, try in tries do
		local from, to = try[1] + lift, try[2] + lift
		local wall = workspace:Raycast(from, to - from, params)
		if not wall or wall.Normal.Y >= 0.6 then -- (una cuesta no es una pared)
			local hit = workspace:Raycast(try[2] + Vector3.new(0, if boat then 5 else 4, 0), Vector3.new(0, -40, 0), params)
			-- (el agua no es suelo: nadie se baja al mar)
			if hit and hit.Material ~= Enum.Material.Water and not (hit.Instance == workspace.Terrain and hit.Position.Y < chassis.Position.Y - 3) then
				spot, ground = try[2], math.max(hit.Position.Y, chassis.Position.Y - 2)
				break
			end
		end
	end
	if (not spot or not ground) and spec and spec.Stand then
		-- Barco en alta mar: de pie en su cubierta (queda fondeado; «Pilotar» para seguir)
		local stand = (chassis.CFrame * CFrame.new(0, -chassis.Size.Y / 2, 0) * spec.Stand).Position
		spot, ground = stand, stand.Y
	end
	if not spot or not ground then
		-- nada firme alrededor: encima del propio vehículo (por encima del techo)
		local box, size = model:GetBoundingBox()
		spot, ground = chassis.Position, box.Position.Y + size.Y / 2
	end
	local placed = CFrame.new(spot.X, ground + height, spot.Z) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
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
local switching: { [Player]: boolean } = {} -- (se cambia de vehículo o de asiento: no es bajarse; cada uno el suyo)
local switchOut: (Player) -> ()
local function exited(player: Player, placed: CFrame?, model: Model?)
	if switching[player] then
		return
	end
	exitedAt[player] = os.clock()
	leftModel[player] = model
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

-- ¿Se ha movido más de lo que puede? Al vehículo lo mueve el ordenador del conductor: un tramposo
-- podría teletransportarlo o hacerlo volar (con sus pasajeros dentro). Lo más que corre su
-- vehículo, con margen, en dt segundos.
local function jumped(kind: string, from: Vector3, to: Vector3, dt: number): boolean
	local vehicle = Gameplay.Vehicles[kind]
	local speed = if vehicle then vehicle.Speed else 80
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
	return flat > (speed * 1.3 + 10) * dt or to.Y - from.Y > (speed + 10) * dt
end

-- Cada medio segundo: vigila que el vehículo no dé saltos imposibles y gasta según la distancia
local function burnFuel()
	local now = os.clock()
	for player, ride in riding do
		local chassis = ride.Model.PrimaryPart
		-- (solo si lo mueve el ordenador del conductor: lo que mueve el servidor no se discute)
		local ok, owner = pcall(function()
			return chassis and chassis:GetNetworkOwner()
		end)
		if chassis and ok and owner == player and not chassis.Anchored and ride.LastPos and ride.LastCFrame then
			local dt = math.max(0.5, now - (ride.LastAt or now))
			if jumped(ride.Kind, ride.LastPos, chassis.Position, dt) then
				-- El conductor se queda donde ha llegado (a pie) y el vehículo, con quien vaya dentro,
				-- vuelve a donde estaba. (Si lo movió el propio juego, p. ej. al llevarte a casa, llegas
				-- tú solo y el vehículo se queda aparcado donde lo dejaste.)
				warn(("[Vehicles] %s: salto imposible con %s"):format(player.Name, ride.Kind))
				local good = ride.LastCFrame
				VehicleService.dismount(player, true)
				if ride.Model.Parent and chassis.Parent then
					chassis.AssemblyLinearVelocity = Vector3.zero
					chassis.CFrame = good
				end
				continue
			end
		end
		local last = ride.LastPos
		if chassis then
			ride.LastPos = chassis.Position
			ride.LastCFrame = chassis.CFrame
			ride.LastAt = now
		end
		-- Distancia del viaje (cualquier vehículo; un salto grande es un teletransporte, no cuenta)
		if chassis and last then
			local moved = Vector3.new(chassis.Position.X - last.X, 0, chassis.Position.Z - last.Z).Magnitude
			if moved > 0.05 and moved < 200 then
				ride.Driven = (ride.Driven or 0) + moved
			end
		end
		local spec = FUEL.Kinds[ride.Kind]
		if spec and ride.Fuel and chassis then
			local pos = chassis.Position
			last = last or pos
			local d = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
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
	-- Kilómetros del viaje (misiones y XP del pase de temporada). No en el examen de la autoescuela.
	if (ride.Driven or 0) > 50 and not ride.Exam and require(ReplicatedStorage.Shared.BattlePass.Config).Enabled then
		StoryEvents.emit(player, "VehicleTrip", { Kind = ride.Kind, Km = (ride.Driven or 0) * FUEL.KmPerStud, Rented = ride.Rented })
	end
	if ride.Died then
		ride.Died:Disconnect()
	end
	if ride.Left then
		ride.Left:Disconnect()
	end
	if ride.Gone then
		ride.Gone:Disconnect()
	end
	-- Bajarse de verdad (asiento, sitio al lado, aparcar, retirar). Si algo de esto falla (por ejemplo,
	-- el vehículo se está borrando justo ahora), el estado de «montado» se quita igual: si no, se
	-- quedaba el panel del patinete puesto y la velocidad del vehículo yendo a pie.
	local ok, err = pcall(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		unseat(humanoid, ride.Seat)
		if ride.Keep and ride.Model.Parent then
			level(ride.Model)
		end
		-- Se baja por el lado izquierdo (del coche, fuera de la carrocería)
		local placed = if character and ride.Model.PrimaryPart then placeBeside(character, ride.Model, ride.Kind, -1, 0) else nil
		-- Y luego se aparca (con sus choques de nuevo: ya no está dentro)
		if ride.Keep and ride.Model.Parent then
			park(ride.Model, true)
		end
		exited(player, placed, ride.Model)
		if not ride.Keep then
			-- Vehículo de alquiler o de trabajo: se retira (los pasajeros se bajan antes, a su lado)
			VehicleService.emptyPassengers(ride.Model)
			pcall(function()
				ride.Model:Destroy() -- (si ya se estaba borrando, no pasa nada)
			end)
		end
	end)
	if not ok then
		warn("[VehicleService] Al bajarse:", err)
		pcall(exited, player, nil, nil)
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
	if model:GetAttribute("BusLine") then
		return false -- (el autobús urbano: sus asientos los lleva BusService)
	end
	unseat(humanoid, seat)
	local kind = model:GetAttribute("Kind")
	local chassis = model.PrimaryPart
	local side = seat:GetAttribute("Side")
	local along = if chassis then chassis.CFrame:PointToObjectSpace(seat.Position).Z else 0
	-- Si iba al volante, el vehículo se queda aparcado ahí (salvo que lo conduzca otra persona):
	-- recto, se le baja a su lado y luego vuelven sus choques
	local driver = model:GetAttribute("Driver")
	local parking = seat.Name == "DriverSeat" and (driver == nil or driver == player.UserId) and chassis ~= nil and not chassis.Anchored
	if parking then
		level(model)
	end
	local placed = placeBeside(character, model, if typeof(kind) == "string" then kind else "Coche", if typeof(side) == "number" then side else -1, along)
	if parking then
		park(model, true)
	end
	player:SetAttribute("Riding", nil)
	player:SetAttribute("Passenger", nil)
	player:SetAttribute("VehicleSpeed", nil)
	LifeService.refresh(player)
	exited(player, placed, model)
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
		VehicleService.clearStale(player, true) -- («Bajarse»: ya mismo)
	end
end

-- «Montado» sin vehículo (se perdió al bajarse o se borró el vehículo): se quita ese estado, que
-- dejaba el panel del vehículo en pantalla y la velocidad del vehículo yendo a pie
local staleSince: { [Player]: number } = {}
function VehicleService.clearStale(player: Player, now: boolean?): boolean
	if riding[player] or passengers[player] then
		staleSince[player] = nil
		return false
	end
	if player:GetAttribute("Riding") == nil and player:GetAttribute("VehicleSpeed") == nil and player:GetAttribute("Passenger") == nil then
		staleSince[player] = nil
		return false
	end
	-- (la vigilancia solo lo quita si sigue así en dos vueltas seguidas: nada a medio montar)
	if not now then
		local since = staleSince[player]
		if not since then
			staleSince[player] = os.clock()
			return false
		elseif os.clock() - since < 1.5 then
			return false
		end
	end
	staleSince[player] = nil
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat and seat:FindFirstAncestorOfClass("Model") and (seat:FindFirstAncestorOfClass("Model") :: Model):GetAttribute("Drivable") then
		return false -- (va sentado en uno: eso lo resuelve orphanExit)
	end
	player:SetAttribute("Riding", nil)
	player:SetAttribute("Passenger", nil)
	player:SetAttribute("VehicleSpeed", nil)
	clearFuel(player)
	LifeService.refresh(player)
	return true
end

-- Antes de llevarle a otro sitio (viajes, metro…): se baja del vehículo y se levanta de cualquier
-- asiento. Si no, se llevaría el vehículo (y a quien vaya dentro) con él, o se quedaría soldado.
function VehicleService.standUp(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local model = seat and seat:FindFirstAncestorOfClass("Model")
	if riding[player] or passengers[player] or (model and model:GetAttribute("Drivable")) then
		VehicleService.exitAny(player, true)
	end
	if humanoid and humanoid.SeatPart then
		unseat(humanoid, humanoid.SeatPart)
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
		exited(player, placed, entry.Model)
	end
	if not silent then
		Notify:FireClient(player, "Info", "Te has bajado.")
	end
end

-- Se cambia de vehículo o de asiento: se baja del anterior sin que eso cuente como bajarse
function switchOut(player: Player)
	switching[player] = true
	local ok, err = pcall(function()
		VehicleService.dismount(player, true)
		VehicleService.leavePassenger(player, true, false)
	end)
	switching[player] = nil
	if not ok then
		warn("[Vehicles] " .. tostring(err))
	end
end

-- Se baja de su vehículo sin que cuente como bajarse (ni aviso «Exited» a su ordenador): para
-- subirse a otra cosa enseguida (el autobús urbano)
VehicleService.switchOut = switchOut

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
	if justExited(player) or justLeft(player, model) then
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

-- Sienta al personaje al volante. En el monopatín y el patinete va de pie: se coloca de pie sobre la tabla.
local function sitDriver(humanoid: Humanoid, root: BasePart, seat: VehicleSeat, kind: string)
	local standing = Rides.Spec[kind] and Rides.Spec[kind].Standing
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

	sitDriver(humanoid, root, seat, kind)
	Rides.setStand(model, false) -- en marcha: la pata de cabra (o el caballete) arriba
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
		if seat.Occupant ~= humanoid and riding[player] == ride and not ride.Reseating then
			VehicleService.dismount(player)
		end
	end)
	-- Si el vehículo se retira con él dentro (lo quita otro sistema), se baja: si no, se quedaría
	-- «montado» a pie (con la velocidad del vehículo, sin poder correr y conduciendo para la policía)
	ride.Gone = model.Destroying:Connect(function()
		if riding[player] == ride then
			VehicleService.dismount(player, true)
		end
	end)
	riding[player] = ride
	loadFuel(player, ride)
	-- Desde aquí se vigila que no dé saltos imposibles (burnFuel)
	ride.LastPos, ride.LastCFrame, ride.LastAt = chassis.Position, chassis.CFrame, os.clock()
	player:SetAttribute("Riding", kind)
	player:SetAttribute("VehicleSpeed", vehicle.Speed)
	StoryEvents.emit(player, "VehicleMounted", { Vehicle = kind, Rented = ride.Rented })
	return true
end

-- Su ordenador avisa de que el personaje no llegó a sentarse al volante (le llegó la soldadura del
-- asiento, pero no se sentó: iba de pie arrastrando el coche medio hundido, con los pedales en
-- pantalla y la velocidad del coche). Se le vuelve a sentar UNA vez; si vuelve a pasar, su
-- ordenador pide bajarse ("Dismount") y queda todo limpio.
function VehicleService.reseat(player: Player): boolean
	local ride = riding[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not ride or ride.Reseated or not humanoid or not root or humanoid.Health <= 0 then
		return false
	end
	ride.Reseated = true
	local seat = ride.Seat
	if not seat.Parent or not ride.Model.Parent then
		VehicleService.dismount(player, true)
		return false
	end
	ride.Reseating = true
	local ok, err = pcall(function()
		unseat(humanoid, seat)
		if ride.Keep then
			level(ride.Model) -- (recto y a ras de suelo: estaba medio hundido)
		end
		sitDriver(humanoid, root, seat, ride.Kind)
		claimOwnership(ride.Model)
	end)
	ride.Reseating = nil
	if not ok then
		warn("[VehicleService] Al volver a sentar:", err)
	end
	if not ok or seat.Occupant ~= humanoid then
		VehicleService.dismount(player, true)
		return false
	end
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
	prompt.ActionText = if kind == "Coche" then "Conducir" elseif vehicle.Boat then "Pilotar" else "Montar"
	prompt.ObjectText = if owner then vehicle.Icon .. " Tu " .. (if vehicle.Boat then vehicle.Name else string.lower(vehicle.Name)) else vehicle.Icon .. " " .. vehicle.Name
	prompt.MaxActivationDistance = if kind == "Coche" then 8 elseif vehicle.Boat then 10 else 7 -- (de cerca y manteniendo: nadie se sube sin querer)
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.5
	-- (si ya lo conduce alguien, apagado: antes salía «Conducir» en tu propio coche mientras lo llevabas)
	prompt.Enabled = model:GetAttribute("Driver") == nil
	prompt.Parent = chassis
	prompt.Triggered:Connect(function(player)
		if owner and player ~= owner then
			Notify:FireClient(player, "Error", "Este vehículo es de otra persona.")
			return
		end
		local ride = riding[player]
		if (ride and ride.Exam) or justExited(player) or justLeft(player, model) then
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

-- Dónde estaba aparcado cada coche de la calle (vuelve ahí si lo dejan abandonado en otro sitio)
local homes: { [Model]: { CFrame: CFrame, Since: number } } = {}

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
	prompt.MaxActivationDistance = 8 -- (de cerca y manteniendo: nadie se sube sin querer)
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.5
	prompt.Parent = body
	local sit = Instance.new("ProximityPrompt")
	sit.Name = "SitPrompt"
	sit.ActionText = "Sentarse"
	sit.ObjectText = "🚗 Coche aparcado"
	sit.MaxActivationDistance = 7
	sit.RequiresLineOfSight = false
	sit.HoldDuration = 0.5
	sit.UIOffset = Vector2.new(0, 58)
	sit.Parent = body
	-- Al cogerlo (o sentarse) se ve con todo detalle (interior, montantes, retrovisores…) y ya
	-- tiene sus asientos de verdad, cada uno con su cartel
	local function activate()
		prompt:Destroy()
		sit:Destroy()
		local ground = body.CFrame * CFrame.new(0, -2.2, 0)
		require(script.Parent.Parent.World.Kit.CarModel).upgrade(model :: Model, ground)
		local chassis = Rides.prepare(model :: Model, "Coche", ground)
		homes[model :: Model] = { CFrame = chassis.CFrame, Since = os.clock() }
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

-- ¿Cabe un vehículo de este tamaño aquí (cf a ras de suelo)? Nada que choque donde irá: paredes,
-- farolas, otros coches, personas (sin contar el suelo ni lo que haya en ignore)
local function fits(size: Vector3, cf: CFrame, ignore: { Instance }): boolean
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ignore
	overlap.RespectCanCollide = true
	overlap.MaxParts = 1
	local box = Vector3.new(size.X, 4, size.Z)
	local ok, parts = pcall(function()
		return workspace:GetPartBoundsInBox(cf * CFrame.new(0, 0.6 + box.Y / 2, 0), box, overlap)
	end)
	return not ok or #parts == 0 -- (si la consulta falla, no se impide sacarlo)
end

-- ¿Es parte de una persona (jugador o personaje)?
local function isPerson(part: Instance): boolean
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return true
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return false
end

-- El mundo de verdad para RideSpot: el suelo con Ground (sin coches, personas ni adornos; el agua
-- no es suelo; la calzada es una pieza "Road" y va a lo largo) y lo que ocupa sitio: todo lo que
-- choca, las personas y lo que se ve y abulta aunque no choque (farolas, papeleras, señales)
local function spawnWorld(rayIgnore: { Instance }, boxIgnore: { Instance }): RideSpot.World
	local function params(): RaycastParams
		local p = RaycastParams.new()
		p.FilterType = Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances = table.clone(rayIgnore)
		p.RespectCanCollide = true
		return p
	end
	return {
		ground = function(x: number, z: number, top: number, bottom: number): (number?, Vector3?, boolean?)
			local hit = Ground.cast(Vector3.new(x, top, z), Vector3.new(0, bottom - top, 0), params())
			if not hit then
				return nil, nil, false
			end
			if hit.Material == Enum.Material.Water then
				return nil, nil, true
			end
			local part = hit.Instance
			local axis: Vector3? = nil
			if part:IsA("BasePart") and part.Name == "Road" then
				axis = if part.Size.Z >= part.Size.X then part.CFrame.LookVector else part.CFrame.RightVector
			end
			return hit.Position.Y, axis, false
		end,
		blocked = function(cf: CFrame, size: Vector3): boolean
			local box = Vector3.new(size.X + 0.3, RideSpot.Height, size.Z + 0.3)
			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Exclude
			overlap.FilterDescendantsInstances = boxIgnore
			overlap.RespectCanCollide = false
			overlap.MaxParts = 60
			local ok, parts = pcall(function()
				return workspace:GetPartBoundsInBox(cf * CFrame.new(0, RideSpot.Lift + box.Y / 2, 0), box, overlap)
			end)
			if not ok or type(parts) ~= "table" then
				return false -- (si la consulta falla, no se impide sacarlo)
			end
			for _, part in parts do
				if part.CanCollide or isPerson(part) or (part.Transparency < 0.5 and part.Size.Magnitude > 1.5) then
					return true
				end
			end
			return false
		end,
		clear = function(from: Vector3, to: Vector3): boolean
			local ok, hit = pcall(function()
				return workspace:Raycast(from, to - from, params())
			end)
			return not ok or hit == nil or hit.Normal.Y >= 0.6 or isPerson(hit.Instance)
		end,
	}
end

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
	-- Sale a ras de suelo junto al jugador (RideSpot): en un sitio llano y libre de verdad (sin
	-- bordillos, muretes, farolas, papeleras, coches ni personas dentro), mejor en la calzada y a lo
	-- largo de la calle. Si no cabe en ningún sitio cerca, no sale.
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = if look.Magnitude > 0.1 then look.Unit else Vector3.new(0, 0, -1)
	local humanoid = (character :: Model):FindFirstChildOfClass("Humanoid")
	local feet = root.Position.Y - ((if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2)
	local size = Rides.Spec[kind].Size
	local old = parked[player]
	local rayIgnore: { Instance } = { character :: Instance, folder }
	local boxIgnore: { Instance } = { character :: Instance, workspace.Terrain }
	if old then
		table.insert(boxIgnore, old) -- (el tuyo de antes se retira al sacar este)
	end
	local cf = RideSpot.choose(spawnWorld(rayIgnore, boxIgnore), root.Position, feet, look, size)
	if not cf then
		Notify:FireClient(player, "Error", "Aquí no cabe: busca un sitio más despejado para sacar el vehículo.")
		return false
	end
	local paint: Color3? = nil
	if VehicleService.PaintFor and not options.Rented and not options.Exam then
		local okPaint, color = pcall(VehicleService.PaintFor, player, kind)
		paint = if okPaint and typeof(color) == "Color3" then color else nil
	end
	local model = Rides.build(kind, nil, cf, paint)
	model:SetAttribute("OwnerId", player.UserId)
	Rides.prepare(model, kind, cf)
	addHeadlight(model)
	setupSeats(model, kind)
	-- Llega entero a su ordenador (con StreamingEnabled, por piezas podía llegar el asiento antes que
	-- la base y el ordenador no empezaba a conducirlo)
	pcall(function()
		(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	model.Parent = folder
	local keep = not options.Rented and not options.Exam
	if not drive(player, model, kind, { Rented = options.Rented, Exam = options.Exam, Keep = keep }) then
		model:Destroy()
		return false
	end
	-- Solo ahora (ya va montado en el nuevo) se retira el que tenía aparcado
	if keep then
		if old and old ~= model and parked[player] == old then
			old:Destroy()
		end
		parked[player] = model
		addDrivePrompt(model, kind, player)
	end
	return true
end

-- Saca un vehículo ya colocado en su sitio (BoatService: el barco en su amarre del puerto deportivo)
-- y sube a su dueño al volante. No mira si cabe (lo mira quien lo pide) ni cuenta como «tu vehículo»
-- aparcado (ese es el de tierra). opts.Color = su pintura; opts.Decorate(model) se llama antes de
-- soldar las piezas (el nombre en la popa). Devuelve el modelo, o nil si no se ha podido subir.
function VehicleService.launchAt(player: Player, kind: string, cf: CFrame, opts: { Color: Color3?, Decorate: ((Model) -> ())? }?): Model?
	local options = opts or {}
	if not Gameplay.Vehicles[kind] or not Rides.Spec[kind] or not allowed(player, kind) then
		return nil
	end
	switchOut(player)
	local model = Rides.build(kind, nil, cf, options.Color)
	model:SetAttribute("OwnerId", player.UserId)
	if options.Decorate then
		local ok, err = pcall(options.Decorate, model)
		if not ok then
			warn("[VehicleService] " .. tostring(err))
		end
	end
	Rides.prepare(model, kind, cf)
	addHeadlight(model)
	setupSeats(model, kind)
	model.Parent = folder
	if not drive(player, model, kind, { Keep = true }) then
		model:Destroy()
		return nil
	end
	addDrivePrompt(model, kind, player)
	return model
end

-- Coches de la calle abandonados lejos de su sitio: si llevan STREET_IDLE segundos sin nadie
-- dentro y no hay nadie cerca (ni de él ni de su sitio), vuelven a su plaza con el depósito nuevo
local STREET_IDLE = 300
local STREET_NEAR = 60
local function returnStreetCars()
	local now = os.clock()
	local near: { Vector3 } = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			table.insert(near, root.Position)
		end
	end
	for model, home in homes do
		local chassis = model.PrimaryPart
		if not model.Parent or not chassis then
			homes[model] = nil
			continue
		end
		local busy = model:GetAttribute("Driver") ~= nil or not chassis.Anchored
		for _, seat in model:GetChildren() do
			if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Occupant then
				busy = true
			end
		end
		if busy or (chassis.Position - home.CFrame.Position).Magnitude < 3 then
			home.Since = now
		elseif now - home.Since >= STREET_IDLE then
			local seen = false
			for _, position in near do
				if (position - chassis.Position).Magnitude < STREET_NEAR or (position - home.CFrame.Position).Magnitude < STREET_NEAR then
					seen = true
					break
				end
			end
			local size = Rides.Spec.Coche.Size
			if not seen and fits(size, home.CFrame * CFrame.new(0, -size.Y / 2, 0), { model, workspace.Terrain }) then
				chassis.CFrame = home.CFrame
				model:SetAttribute("Fuel", nil) -- (depósito nuevo al volver a cogerlo)
				home.Since = now
			end
		end
	end
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

-- ¿Puede sacar ahora un vehículo? No en la cárcel, en un juicio, muerto, KO, dentro de un edificio
-- ni sentado en algo que no sea su vehículo (el autobús, un banco, de pasajero…)
local function canSpawn(player: Player): boolean
	for _, attribute in { "JailUntil", "OnTrial", "Dead", "KO", "InteriorKey" } do
		if player:GetAttribute(attribute) then
			return false
		end
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or (humanoid.SeatPart and not riding[player]) then
		return false
	end
	return true
end

-- El menú no se puede pulsar en ráfaga (cada vehículo sacado se construye entero en el servidor)
-- (bucket: cada forma de sacar vehículos lleva su propia cuenta: alquilar una bici no te quita
-- sacar la tuya, ni coger el coche patrulla)
local rentedAt: { [Player]: { number } } = {}
local patrolAt: { [Player]: { number } } = {}
local function spawnStore(bucket: string?): { [Player]: { number } }
	return if bucket == "Rent" then rentedAt elseif bucket == "Patrol" then patrolAt else spawnedAt
end

-- ¿Puede sacar otro vehículo ya? Si no, se le avisa. Solo mira: la cuenta se apunta con spawnDone
-- cuando el vehículo sale de verdad (si falla, no le cuenta)
local function spawnAllowed(player: Player, bucket: string?): boolean
	local store = spawnStore(bucket)
	local now = os.clock()
	local recent = {}
	for _, at in store[player] or {} do
		if now - at < SPAWN_WINDOW then
			table.insert(recent, at)
		end
	end
	store[player] = recent
	if #recent >= SPAWN_BURST then
		local wait = math.max(1, math.ceil(SPAWN_WINDOW - (now - recent[1])))
		Notify:FireClient(player, "Error", ("Espera un momento: has sacado varios vehículos seguidos. Prueba en %d s."):format(wait))
		return false
	end
	return true
end

-- Apunta un vehículo sacado (después de subirse con éxito)
local function spawnDone(player: Player, bucket: string?)
	local store = spawnStore(bucket)
	local recent = store[player] or {}
	table.insert(recent, os.clock())
	store[player] = recent
end

-- (también lo usan otros sitios que sacan vehículos: el coche patrulla de la comisaría)
VehicleService.spawnAllowed = spawnAllowed
VehicleService.spawnDone = spawnDone
VehicleService.canSpawn = canSpawn

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
	if not canSpawn(player) or not spawnAllowed(player) then
		return
	end
	if VehicleService.mount(player, kind) then
		spawnDone(player)
	end
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
			-- (el mismo límite que el menú: pulsar en ráfaga construye vehículos enteros en el servidor)
			if (ride and ride.Exam) or not canSpawn(player) or not spawnAllowed(player, "Rent") then
				return
			end
			if VehicleService.mount(player, kind, { Rented = true }) then
				spawnDone(player, "Rent")
			end
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

	-- Cada poco: nadie se queda «montado» sin vehículo
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in Players:GetPlayers() do
				pcall(VehicleService.clearStale, player)
			end
		end
	end)

	Remote.OnServerEvent:Connect(function(player, action, kind)
		if action == "Dismount" then
			VehicleService.exitAny(player)
		elseif action == "Reseat" then
			VehicleService.reseat(player)
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
		leftModel[player] = nil
		spawnedAt[player] = nil
		rentedAt[player] = nil
		patrolAt[player] = nil
		switching[player] = nil
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
			local ok, err = pcall(function()
				burnFuel()
			end)
			if not ok then
				warn("[VehicleService] " .. tostring(err))
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(15)
			local ok, err = pcall(function()
				returnStreetCars()
			end)
			if not ok then
				warn("[VehicleService] " .. tostring(err))
			end
		end
	end)

	-- Un bebé (o quien vuelve a serlo, p. ej. al empezar una vida nueva) no puede seguir montado
	task.spawn(function()
		while true do
			task.wait(2)
			local dark = isDark()
			for player, ride in riding do
				-- Un vehículo con error no para las luces ni las bajadas del resto
				local ok, err = pcall(function()
					for _, light in ride.Model:GetDescendants() do
						if light:IsA("SpotLight") then
							light.Enabled = dark
						end
					end
					if player:GetAttribute("Crawling") or not stageAllows(player, Gameplay.DriveMinStage, true) then
						VehicleService.dismount(player, true)
						return
					end
					-- Ya no está en el asiento (la soldadura se perdió sin avisar): se baja del todo, sin
					-- quedarse «conduciendo» a pie con la velocidad del vehículo
					local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					if not ride.Reseating and (not ride.Seat.Parent or not humanoid or ride.Seat.Occupant ~= humanoid) then
						VehicleService.dismount(player, true)
					end
				end)
				if not ok then
					warn("[VehicleService] " .. tostring(err))
				end
			end
		end
	end)
end

return VehicleService
