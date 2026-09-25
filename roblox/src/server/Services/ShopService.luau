-- ShopService: comprar en las tiendas del barrio (librería, farmacia, heladería…).
-- Pone un botón "Comprar" en la entrada de cada tienda que tenga algo que vender (ShopItems.luau)
-- y avisa a la historia (StoryEvents "BoughtItem"), así los recados son de verdad: sales de casa,
-- caminas hasta la tienda, compras y vuelves.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local ShopItems = require(ReplicatedStorage.Shared.LifeStory.ShopItems)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local ShopService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

local function setup(entrance: Instance)
	if not entrance:IsA("BasePart") or entrance:FindFirstChild("ShopPrompt") then
		return
	end
	local shopId = entrance:GetAttribute("ShopId")
	local item = shopId and ShopItems[shopId]
	if not item then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = Strings.get("SHOP.BUY", { price = Format.money(item.Price) })
	prompt.ObjectText = Strings.get(item.NameKey)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = entrance
	prompt.Triggered:Connect(function(player)
		if not InventoryService.canAdd(player, item.Id) then
			Notify:FireClient(player, "Error", Strings.get("SHOP.BAG_FULL", { item = Strings.get(item.NameKey) }))
			return
		end
		if not DataService.spend(player, item.Price) then
			Notify:FireClient(player, "Error", Strings.get("SHOP.NO_MONEY"))
			return
		end
		InventoryService.add(player, item.Id) -- va a la mochila (se come desde la barra rápida)
		Notify:FireClient(player, "Success", Strings.get("SHOP.BOUGHT", { item = Strings.get(item.NameKey) }))
		StoryEvents.emit(player, "BoughtItem", { ShopId = shopId, Item = item.Id })
	end)
end

function ShopService.init()
	for _, entrance in CollectionService:GetTagged("Shop") do
		setup(entrance)
	end
	CollectionService:GetInstanceAddedSignal("Shop"):Connect(setup)
end

return ShopService
