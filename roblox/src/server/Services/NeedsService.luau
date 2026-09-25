-- NeedsService: hambre y energía. Bajan con el tiempo; se recuperan comiendo y durmiendo.
-- Los valores se envían al cliente como atributos del jugador ("Hunger", "Energy").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local NeedsService = {}

local TICK = 1 -- segundos entre actualizaciones
local MAX = Config.Needs.Max

local function clamp(value: number): number
	return math.clamp(value, 0, MAX)
end

local function applyWalkSpeed(player: Player)
	local data = DataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not humanoid then
		return
	end
	-- Montado en un vehículo manda la velocidad del vehículo (VehicleService)
	local vehicleSpeed = player:GetAttribute("VehicleSpeed")
	if typeof(vehicleSpeed) == "number" then
		humanoid.WalkSpeed = vehicleSpeed
		return
	end
	local tired = data.Hunger <= Config.Needs.LowThreshold or data.Energy <= Config.Needs.LowThreshold
	-- La velocidad base depende de la etapa de vida (LifeService); si estás agotado, vas más lento
	local base = player:GetAttribute("StageWalkSpeed") or Config.WalkSpeed
	-- Corriendo (ProgressionService): más rápido mientras dure la estamina; la Destreza suma
	if player:GetAttribute("Sprinting") and not tired then
		local stamina = Gameplay.Progression.Stamina
		base *= stamina.SprintMultiplier + (player:GetAttribute("Stat_Destreza") or 0) * stamina.PerDestreza
	end
	humanoid.WalkSpeed = if tired then math.min(base, Config.TiredWalkSpeed) else base
end

local function sync(player: Player, data: { [string]: any })
	-- Redondeamos para no mandar un cambio de atributo por cada décima
	player:SetAttribute("Hunger", math.floor(data.Hunger + 0.5))
	player:SetAttribute("Energy", math.floor(data.Energy + 0.5))
	applyWalkSpeed(player)
end

-- Suma (o resta) hambre y energía.
function NeedsService.change(player: Player, hunger: number, energy: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.Hunger = clamp(data.Hunger + hunger)
	data.Energy = clamp(data.Energy + energy)
	sync(player, data)
end

-- Vuelve a calcular la velocidad al momento (al empezar o dejar de correr)
function NeedsService.refreshSpeed(player: Player)
	applyWalkSpeed(player)
end

function NeedsService.canWork(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil
		and data.Hunger > Config.Needs.CantWorkThreshold
		and data.Energy > Config.Needs.CantWorkThreshold
end

function NeedsService.init()
	DataService.onLoaded(function(player, data)
		sync(player, data)
		player.CharacterAdded:Connect(function()
			task.defer(applyWalkSpeed, player)
		end)
		if player.Character then
			applyWalkSpeed(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				local data = DataService.get(player)
				if data and not player:GetAttribute("Sleeping") then
					local multiplier = MonetizationService.needsMultiplier(player)
					data.Hunger = clamp(data.Hunger - Config.Needs.HungerPerMinute / 60 * TICK * multiplier)
					-- Sentado en un banco se descansa: la energía sube un poco en vez de bajar
					local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					local seat = humanoid and humanoid.SeatPart
					if seat and seat.Parent and seat.Parent:HasTag("Bench") then
						data.Energy = clamp(data.Energy + 3 / 60 * TICK)
					else
						data.Energy = clamp(data.Energy - Config.Needs.EnergyPerMinute / 60 * TICK * multiplier)
					end
					sync(player, data)
				end
			end
		end
	end)
end

return NeedsService
