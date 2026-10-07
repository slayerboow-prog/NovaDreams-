-- ShopService: comprar en las tiendas del barrio (librería, farmacia, heladería…).
-- Pone un botón "Comprar" en la entrada de cada tienda que tenga algo que vender (ShopItems.luau)
-- y avisa a la historia (StoryEvents "BoughtItem"), así los recados son de verdad: sales de casa,
-- caminas hasta la tienda, compras y vuelves.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Groceries = require(ReplicatedStorage.Shared.Groceries)
local OpeningHours = require(ReplicatedStorage.Shared.OpeningHours)
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
	-- Con la tienda cerrada, el botón de comprar no sale (antes salía y luego decía "cerrado")
	task.spawn(function()
		local hours = OpeningHours.forShop(shopId)
		while prompt.Parent do
			prompt.Enabled = OpeningHours.openNow(hours)
			task.wait(5)
		end
	end)
	prompt.Triggered:Connect(function(player)
		-- Con la tienda cerrada no se vende (su dependiente no está: shared/OpeningHours)
		local hours = OpeningHours.forShop(shopId)
		if not OpeningHours.openNow(hours) then
			Notify:FireClient(player, "Info", ("🔒 Está cerrado: %s. Vuelve más tarde."):format(OpeningHours.label(hours :: { number })))
			return
		end
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

---------------------------------------------------------------------
-- Fruterías: cada caja de fruta o verdura se compra en la misma caja (etiqueta ProduceCrate,
-- atributo Product = un producto de shared/Groceries; World/Interiors). Pulsas «Comprar» y va a la
-- mochila (se come desde la barra rápida o se guarda en la nevera). Si el local es el negocio de un
-- jugador, se compra en su tienda (BusinessService.shopFor: sus precios y su caja).
---------------------------------------------------------------------
ShopService.ProduceShopId = "Fruteria"

function ShopService.buyProduce(player: Player, id: string): boolean
	local product = Groceries.byId[id]
	if not product then
		return false
	end
	if not InventoryService.canAdd(player, product.Id) then
		Notify:FireClient(player, "Error", Strings.get("SHOP.BAG_FULL", { item = product.Name }))
		return false
	end
	if not DataService.spend(player, product.Price) then
		Notify:FireClient(player, "Error", Strings.get("SHOP.NO_MONEY"))
		return false
	end
	InventoryService.add(player, product.Id)
	Notify:FireClient(player, "Success", ("%s %s: %s 🎒"):format(product.Icon, product.Name, Format.money(product.Price)))
	StoryEvents.emit(player, "BoughtItem", { ShopId = ShopService.ProduceShopId, Item = product.Id })
	return true
end

function ShopService.setupProduce(inst: any)
	local model = inst and inst.Room and inst.Room.Model
	if not model then
		return
	end
	for _, crate in model:GetDescendants() do
		local id = crate:IsA("BasePart") and crate:HasTag("ProduceCrate") and crate:GetAttribute("Product")
		local product = type(id) == "string" and Groceries.byId[id]
		if product and not crate:FindFirstChild("ProducePrompt") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ProducePrompt"
			prompt.ActionText = "Comprar"
			prompt.ObjectText = ("%s %s · %s"):format(product.Icon, product.Name, Format.money(product.Price))
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Parent = crate
			prompt.Triggered:Connect(function(player)
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or (root.Position - crate.Position).Magnitude > 12 then
					return
				end
				-- El local es el negocio de un jugador: se compra en su tienda
				local ok, BusinessService = pcall(function()
					return require(script.Parent.BusinessService) :: any
				end)
				if ok and BusinessService and BusinessService.shopFor and BusinessService.shopFor(player, inst) then
					return
				end
				ShopService.buyProduce(player, product.Id)
			end)
		end
	end
end

function ShopService.init()
	for _, entrance in CollectionService:GetTagged("Shop") do
		setup(entrance)
	end
	CollectionService:GetInstanceAddedSignal("Shop"):Connect(setup)
	-- (require aquí dentro: InteriorService carga muchas cosas y así no hay requires en círculo)
	local ok, InteriorService = pcall(function()
		return require(script.Parent.InteriorService) :: any
	end)
	if ok and InteriorService and InteriorService.onBuilt then
		InteriorService.onBuilt(ShopService.setupProduce)
	end
end

return ShopService
