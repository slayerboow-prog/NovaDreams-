-- VehicleService: montar en monopatín, bici, moto y coche.
--
-- Cómo funciona: cada vehículo tiene una base invisible ("Chassis") y un asiento de conductor
-- (VehicleSeat). El jugador se sienta y su ordenador lo conduce (client/Controllers/Driving.luau):
-- acelerar, frenar, marcha atrás y girar, siguiendo el suelo con rayos (sin físicas que vuelquen).
--   * Los 800+ coches aparcados de la ciudad se pueden conducir (cartel "Conducir").
--   * Bici, monopatín y patinete públicos (tag RentalStation, junto a las paradas de bus): gratis.
--   * Vehículos propios: se compran y se sacan desde el botón "🚲 Vehículos".
--   * Moto y coche piden ser mayor de edad y tener el carnet (autoescuela).
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
}
local riding: { [Player]: Ride } = {}
local dismountListeners: { (Player, string) -> () } = {}
local folder: Folder

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

local function ensure(data: { [string]: any })
	data.Vehicles = data.Vehicles or {}
	data.Licenses = data.Licenses or {}
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

function VehicleService.dismount(player: Player, silent: boolean?)
	local ride = riding[player]
	if not ride then
		return
	end
	riding[player] = nil
	if ride.Died then
		ride.Died:Disconnect()
	end
	if ride.Left then
		ride.Left:Disconnect()
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local seat = ride.Seat
	if seat.Parent then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	if humanoid then
		humanoid.Sit = false
	end
	local chassis = ride.Model.PrimaryPart
	if ride.Keep and ride.Model.Parent then
		park(ride.Model)
	end
	-- Se baja por el lado izquierdo (del coche, fuera de la carrocería)
	if root and chassis and humanoid and humanoid.Health > 0 then
		local side = (Rides.Spec[ride.Kind].Size.X / 2) + 2.5
		root.CFrame = chassis.CFrame * CFrame.new(-side, 3.5, 0)
		root.AssemblyLinearVelocity = Vector3.zero
	end
	if not ride.Keep then
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

-- ¿Puede conducir este vehículo? (edad y carnet; en el examen no hace falta carnet)
local function allowed(player: Player, kind: string, exam: boolean?): boolean
	local vehicle = Gameplay.Vehicles[kind]
	if not vehicle then
		return false
	end
	if player:GetAttribute("Sleeping") or player:GetAttribute("Crawling") then
		return false
	end
	if not stageAllows(player, vehicle.Stage) then
		return false
	end
	if vehicle.License and not exam and not VehicleService.hasLicense(player, vehicle.License) then
		Notify:FireClient(player, "Error", ("Necesitas el %s. Sácatelo en una autoescuela."):format(Gameplay.Licenses[vehicle.License].Name))
		return false
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
	VehicleService.dismount(player, true)
	if humanoid.SeatPart then
		humanoid.Sit = false
		local weld = humanoid.SeatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
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
		if ride and ride.Exam then
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
	-- Cartel ligero en la carrocería; el coche solo se prepara cuando alguien lo coge
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DrivePrompt"
	prompt.ActionText = "Conducir"
	prompt.ObjectText = "🚗 Coche"
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0.25
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		local ride = riding[player]
		if (ride and ride.Exam) or not allowed(player, "Coche") or model:GetAttribute("Drivable") then
			return
		end
		prompt:Destroy()
		Rides.prepare(model, "Coche", body.CFrame * CFrame.new(0, -2.2, 0))
		addDrivePrompt(model, "Coche")
		addHeadlight(model)
		drive(player, model, "Coche", { Keep = true })
	end)
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
	VehicleService.dismount(player, true)
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
	if not vehicle or not data then
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
			local ride = riding[player]
			if ride then
				VehicleService.dismount(player)
			end
		elseif action == "Spawn" and typeof(kind) == "string" then
			spawnOwned(player, kind)
		elseif action == "Buy" and typeof(kind) == "string" then
			VehicleService.buy(player, kind)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function()
			VehicleService.dismount(player, true)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterRemoving:Connect(function()
			VehicleService.dismount(player, true)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		VehicleService.dismount(player, true)
		if parked[player] then
			parked[player]:Destroy()
			parked[player] = nil
		end
	end)

	-- Un bebé o un niño que "baja" de etapa no puede seguir montado (p. ej. al empezar una vida nueva)
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
				local vehicle = Gameplay.Vehicles[ride.Kind]
				if player:GetAttribute("Crawling") or (vehicle and not stageAllows(player, vehicle.Stage, true)) then
					VehicleService.dismount(player, true)
				end
			end
		end
	end)
end

return VehicleService
