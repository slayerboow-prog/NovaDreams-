-- VehicleService: montar en monopatín, bici, moto y coche.
--
-- Cómo funciona: el vehículo se suelda al personaje (sin peso ni colisiones) y el personaje
-- se mueve más rápido. Es la forma más estable en Roblox: nada de físicas que vuelquen.
--   * Bici y monopatín públicos (tag RentalStation, junto a las paradas de autobús): gratis.
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

local JUMP = { Monopatin = 6, Bici = 3, Moto = 0, Coche = 0 }
local STAGE_TEXT = { Nino = "niño", Adolescente = "adolescente", AdultoJoven = "mayor de edad", Adulto = "adulto", Mayor = "mayor" }

type Ride = { Model: Model, Kind: string, Rented: boolean, Exam: boolean, BaseHip: number, Died: RBXScriptConnection? }
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
		light.Shadows = true
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

function VehicleService.dismount(player: Player, silent: boolean?)
	local ride = riding[player]
	if not ride then
		return
	end
	riding[player] = nil
	if ride.Died then
		ride.Died:Disconnect()
	end
	ride.Model:Destroy()
	player:SetAttribute("Riding", nil)
	player:SetAttribute("VehicleSpeed", nil)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.HipHeight = ride.BaseHip
	end
	LifeService.refresh(player) -- vuelve la velocidad y el salto de su edad
	if not silent then
		Notify:FireClient(player, "Info", "Te has bajado.")
	end
	for _, listener in dismountListeners do
		task.spawn(listener, player, ride.Kind)
	end
end

-- Monta al jugador. opts.Rented = de una estación pública; opts.Exam = examen práctico (sin carnet)
function VehicleService.mount(player: Player, kind: string, opts: { Rented: boolean?, Exam: boolean? }?): boolean
	local vehicle = Gameplay.Vehicles[kind]
	local options = opts or {}
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not vehicle or not humanoid or not root or humanoid.Health <= 0 then
		return false
	end
	if player:GetAttribute("Sleeping") or player:GetAttribute("Crawling") then
		return false
	end
	if not stageAllows(player, vehicle.Stage) then
		return false
	end
	if vehicle.License and not options.Exam and not VehicleService.hasLicense(player, vehicle.License) then
		Notify:FireClient(player, "Error", ("Necesitas el %s. Sácatelo en una autoescuela."):format(Gameplay.Licenses[vehicle.License].Name))
		return false
	end
	VehicleService.dismount(player, true)

	-- Altura del suelo bajo el personaje (R15: HipHeight + media raíz; R6: además 2 de piernas)
	local baseHip = humanoid.HipHeight
	local lift = Rides.Lift[kind] or 0
	local legs = if humanoid.RigType == Enum.HumanoidRigType.R6 then 2 else 0
	local toGround = baseHip + lift + root.Size.Y / 2 + legs
	humanoid.HipHeight = baseHip + lift

	local model = Rides.build(kind, nil, root.CFrame * CFrame.new(0, -toGround, 0))
	model:SetAttribute("OwnerId", player.UserId)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = part
		end
	end
	addHeadlight(model)
	model.Parent = folder

	local ride: Ride = { Model = model, Kind = kind, Rented = options.Rented == true, Exam = options.Exam == true, BaseHip = baseHip }
	ride.Died = humanoid.Died:Connect(function()
		VehicleService.dismount(player, true)
	end)
	riding[player] = ride
	player:SetAttribute("Riding", kind)
	player:SetAttribute("VehicleSpeed", vehicle.Speed)
	humanoid.WalkSpeed = vehicle.Speed
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = JUMP[kind] or 0
	StoryEvents.emit(player, "VehicleMounted", { Vehicle = kind, Rented = ride.Rented })
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
		local prompt = Builder.prompt(station, "Coger " .. string.lower(vehicle.Name), "Bici pública · gratis", 0.3)
		prompt.KeyboardKeyCode = if i == 1 then Enum.KeyCode.E else Enum.KeyCode.R
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
