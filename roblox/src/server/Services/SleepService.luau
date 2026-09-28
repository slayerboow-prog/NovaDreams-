-- SleepService: dormir en una cama.
--
--   * Energía y estamina al máximo.
--   * La cama pasa a ser tu PUNTO DE REAPARICIÓN: si te caes, te quedas sin vida o vuelves a entrar al
--     juego, apareces ahí (se guarda con tus datos).
--   * De noche (desde las 18:00, o de madrugada antes de las 8:30), la noche pasa: te despiertas a las
--     8:30 del día siguiente. Si duermes a las 21:30, te levantas a las 8:30.
--     La hora es la misma para todo el servidor, así que la noche solo pasa cuando duermen todos los
--     jugadores (o si estás solo). Mientras tanto esperas en la cama unos segundos; si los demás siguen
--     despiertos, te levantas descansado pero la noche sigue.
--   * De día es una siesta: descansas del todo, pero no pasa el tiempo.
--
-- Camas que valen:
--   * La de tu casa (HouseService → SleepService.sleep).
--   * La de tu casa familiar (StoryProp PropId = "Cama" con el mismo HomeId que tu FamilyHomeId).
--   * Cualquier pieza con tag "PublicBed" (camas de la residencia, hoteles… las pone el mapa).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local ProgressionService = require(script.Parent.ProgressionService)
local WorldService = require(script.Parent.WorldService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local SleepService = {}

local Notify: RemoteEvent
local sleepers: { [Player]: boolean } = {} -- quién está en la cama esperando a que pase la noche

local function isNight(clock: number): boolean
	return clock >= Config.SleepNightFrom or clock < Config.WakeClockTime
end

local function formatClock(clock: number): string
	local hours = math.floor(clock)
	return ("%d:%02d"):format(hours, math.floor((clock - hours) * 60 + 0.5))
end

-- ¿Quién cuenta para «que duerma todo el servidor»? (los bebés duermen en la cuna a su aire)
local function awakePlayers(): number
	local awake = 0
	for _, other in Players:GetPlayers() do
		if not sleepers[other] and other:GetAttribute("LifeStage") ~= "Bebe" and other.Character then
			awake += 1
		end
	end
	return awake
end

local function rest(player: Player)
	NeedsService.change(player, 0, Config.Needs.Max)
	ProgressionService.restoreStamina(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and humanoid.MaxHealth then
		humanoid.Health = humanoid.MaxHealth
	end
end

local function wake(player: Player, message: string)
	sleepers[player] = nil
	player:SetAttribute("Sleeping", nil)
	if player.Parent then
		rest(player)
		Notify:FireClient(player, "Success", message)
		StoryEvents.emit(player, "Slept", {})
	end
end

-- Punto de reaparición: junto a la cama (encima, para no aparecer dentro de una pared)
local function setSpawn(player: Player, bed: BasePart)
	local data = DataService.get(player)
	if not data then
		return
	end
	local top = bed.Position + Vector3.new(0, bed.Size.Y / 2 + 3, 0)
	data.SpawnPoint = { X = math.round(top.X * 10) / 10, Y = math.round(top.Y * 10) / 10, Z = math.round(top.Z * 10) / 10 }
	player:SetAttribute("SpawnPoint", top)
end

-- Todos dormidos (o solo tú): amanece para todos
local function passNight()
	local newDay = WorldService.skipTo(Config.WakeClockTime)
	local text = ("☀️ ¡Buenos días! Son las %s%s. Energía y estamina al máximo."):format(
		formatClock(Config.WakeClockTime),
		if newDay then " de un nuevo día" else ""
	)
	for sleeper in table.clone(sleepers) do
		wake(sleeper, text)
	end
end

function SleepService.sleep(player: Player, bed: BasePart)
	if player:GetAttribute("Sleeping") or player:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	player:SetAttribute("Sleeping", true)
	setSpawn(player, bed)
	Notify:FireClient(player, "Sleep", "Zzz...")
	task.wait(Config.SleepSeconds)
	if not player.Parent then
		return
	end
	if not isNight(Lighting.ClockTime) then
		wake(player, "😴 Siesta: energía y estamina al máximo. (De noche, desde las 18:00, dormir te lleva a la mañana siguiente.) Aparecerás aquí si reapareces.")
		return
	end
	sleepers[player] = true
	if awakePlayers() == 0 then
		passNight()
		return
	end
	Notify:FireClient(player, "Info", ("Zzz… Esperando a que se acuesten los demás (%d despiertos). La hora es la misma para todo el servidor."):format(awakePlayers()))
	local waited = 0
	while sleepers[player] and waited < Config.SleepWaitSeconds do
		task.wait(1)
		waited += 1
		if sleepers[player] and awakePlayers() == 0 then
			passNight()
			return
		end
	end
	if sleepers[player] then
		wake(player, "Has descansado (energía y estamina al máximo), pero los demás siguen despiertos: la noche continúa.")
	end
end

-- Al aparecer, a tu cama (si has dormido en alguna). Los bebés aparecen en su cuna (BabyService).
local function toSpawn(player: Player, character: Model)
	local data = DataService.get(player)
	local point = data and data.SpawnPoint
	if type(point) ~= "table" or player:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	task.wait(0.6) -- después de que LifeService ajuste el tamaño
	if root and character.Parent then
		character:PivotTo(CFrame.new(point.X, point.Y, point.Z))
	end
end

local function bedPrompt(part: BasePart, check: (Player) -> boolean)
	if part:FindFirstChild("SleepPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SleepPrompt"
	prompt.ActionText = "Dormir"
	prompt.ObjectText = "Cama"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		if check(player) then
			task.spawn(SleepService.sleep, player, part)
		else
			Notify:FireClient(player, "Error", "Esta cama no es tuya.")
		end
	end)
end

local function watchBed(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	if instance:HasTag("PublicBed") then
		bedPrompt(instance, function()
			return true
		end)
	elseif instance:GetAttribute("PropId") == "Cama" and instance:GetAttribute("HomeId") ~= nil then
		-- La cama de la casa familiar: solo para quien vive en esa casa
		bedPrompt(instance, function(player)
			return player:GetAttribute("FamilyHomeId") == instance:GetAttribute("HomeId")
		end)
	end
end

function SleepService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	for _, tag in { "StoryProp", "PublicBed" } do
		for _, instance in CollectionService:GetTagged(tag) do
			watchBed(instance)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(watchBed)
	end
	local function watchPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			toSpawn(player, character)
		end)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	DataService.onLoaded(function(player, data)
		local point = data.SpawnPoint
		if type(point) == "table" then
			player:SetAttribute("SpawnPoint", Vector3.new(point.X, point.Y, point.Z))
			if player.Character then
				task.spawn(toSpawn, player, player.Character)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		sleepers[player] = nil
		-- Si se va el último despierto, los que esperaban en la cama ya pueden pasar la noche
		task.defer(function()
			if next(sleepers) and awakePlayers() == 0 then
				passNight()
			end
		end)
	end)
end

return SleepService
