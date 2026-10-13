-- NeedsService: hambre y energía. Bajan con el tiempo; se recuperan comiendo y durmiendo.
-- Los valores se envían al cliente como atributos del jugador ("Hunger", "Energy").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local TesterService = require(script.Parent.TesterService)

local NeedsService = {}

local TICK = 1 -- segundos entre actualizaciones
local MAX = Config.Needs.Max

local function clamp(value: number): number
	return math.clamp(value, 0, MAX)
end

local AIM_WALK = Weapons.Aim.WalkFactor

local function applyWalkSpeed(player: Player)
	local data = DataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not humanoid then
		return
	end
	-- (Montado en un vehículo NO se toca: al vehículo lo mueve Controllers/Driving, no el andar. Antes
	-- se ponía la velocidad del vehículo y, si el personaje no llegaba a sentarse, corría a 80 a pie.)
	local tired = data.Hunger <= Config.Needs.LowThreshold or data.Energy <= Config.Needs.LowThreshold
	-- La velocidad base depende de la etapa de vida (LifeService); corriendo (ProgressionService) más
	-- rápido mientras dure la estamina (la Destreza suma); apuntando más despacio (WeaponService); con
	-- hambre o sueño se anda más lento, pero corriendo SIEMPRE se va más rápido que andando normal
	-- (Gameplay.walkSpeed)
	local speed = Gameplay.walkSpeed({
		Stage = player:GetAttribute("StageWalkSpeed") or Config.WalkSpeed,
		Sprinting = player:GetAttribute("Sprinting") == true,
		Destreza = player:GetAttribute("Stat_Destreza") or 0,
		Aiming = player:GetAttribute("Aiming") == true,
		Tired = tired,
		TiredWalk = Config.TiredWalkSpeed,
		AimFactor = AIM_WALK,
	})
	-- La velocidad que debe tener (el cliente la mira: si algo suyo la dejó pisada —una carrera que no
	-- acabó bien—, la vuelve a poner; Controllers/Character)
	player:SetAttribute("WalkTarget", math.floor(speed * 100 + 0.5) / 100)
	humanoid.WalkSpeed = speed
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
	if data ~= nil and TesterService.bypass(player) then
		return true -- (modo pruebas: se trabaja aunque falte energía o haya hambre)
	end
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
				-- Un jugador con error no para las necesidades del resto
				local ok, err = pcall(function()
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
				end)
				if not ok then
					warn("[NeedsService] " .. tostring(err))
				end
			end
		end
	end)
end

return NeedsService
