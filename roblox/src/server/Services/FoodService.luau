-- FoodService: comprar comida en los mostradores (tag "FoodStand" + atributo FoodId).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)

local FoodService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local lastUse: { [Player]: { [string]: number } } = {}

function FoodService.eat(player: Player, foodId: string, stand: BasePart?)
	local food = Config.Foods[foodId]
	if not food or not DataService.get(player) then
		return
	end

	-- La nevera solo funciona en tu propia casa
	if stand and stand:GetAttribute("PlotId") and stand:GetAttribute("PlotId") ~= player:GetAttribute("PlotId") then
		Notify:FireClient(player, "Error", "Esta nevera no es tuya.")
		return
	end

	if food.Cooldown then
		lastUse[player] = lastUse[player] or {}
		local last = lastUse[player][foodId]
		if last and os.clock() - last < food.Cooldown then
			local left = math.ceil(food.Cooldown - (os.clock() - last))
			Notify:FireClient(player, "Error", ("La nevera está vacía. Vuelve en %d s."):format(left))
			return
		end
	end

	if food.Price > 0 and not DataService.spend(player, food.Price) then
		Notify:FireClient(player, "Error", "No tienes suficiente dinero.")
		return
	end

	if food.Cooldown then
		lastUse[player][foodId] = os.clock()
	end
	NeedsService.change(player, food.Hunger, food.Energy or 0)
	Notify:FireClient(player, "Food", ("¡Ñam! %s"):format(food.Name))
end

local function setupStand(stand: Instance)
	if not stand:IsA("BasePart") then
		return
	end
	local foodId = stand:GetAttribute("FoodId")
	local food = Config.Foods[foodId]
	if not food then
		warn("[FoodService] FoodStand con FoodId desconocido:", foodId)
		return
	end
	local action = if food.Price > 0 then "Comprar" else "Comer"
	local object = if food.Price > 0 then ("%s · %s"):format(food.Name, Format.money(food.Price)) else food.Name
	local prompt = Builder.prompt(stand, action, object, 0.3)
	prompt.Triggered:Connect(function(player)
		FoodService.eat(player, foodId, stand)
	end)
end

function FoodService.init()
	for _, stand in CollectionService:GetTagged("FoodStand") do
		setupStand(stand)
	end
	CollectionService:GetInstanceAddedSignal("FoodStand"):Connect(setupStand)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return FoodService
