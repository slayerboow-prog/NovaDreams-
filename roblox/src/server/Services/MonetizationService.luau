-- MonetizationService: Game Passes y Developer Products (compras con Robux).
--
-- Game Pass  = se compra UNA vez y es para siempre (ej. VIP).
-- Dev Product = se puede comprar muchas veces (ej. paquetes de dinero).
--
-- Los IDs se configuran en Shared/Config.luau.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

local function passAttribute(key: string): string
	return "Pass_" .. key
end

function MonetizationService.hasPass(player: Player, key: string): boolean
	return player:GetAttribute(passAttribute(key)) == true
end

-- Multiplicador de sueldo (VIP cobra el doble)
function MonetizationService.payMultiplier(player: Player): number
	if MonetizationService.hasPass(player, "VIP") then
		return Config.GamePasses.VIP.PayMultiplier
	end
	return 1
end

-- Multiplicador de gasto de hambre/energía (Metabolismo Pro gasta la mitad)
function MonetizationService.needsMultiplier(player: Player): number
	if MonetizationService.hasPass(player, "Metabolismo") then
		return Config.GamePasses.Metabolismo.NeedsMultiplier
	end
	return 1
end

local function checkPasses(player: Player)
	for key, pass in Config.GamePasses do
		if pass.Id ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and owns then
				player:SetAttribute(passAttribute(key), true)
			end
		end
	end
end

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		-- El jugador se fue: Roblox lo volverá a intentar cuando vuelva
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.waitFor(player, 20)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- ¿Ya lo habíamos entregado? (Roblox puede repetir el aviso)
	if DataService.hasProcessedReceipt(player, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = nil
	for _, p in Config.DevProducts do
		if p.Id ~= 0 and p.Id == receipt.ProductId then
			product = p
			break
		end
	end
	if not product then
		warn("[Monetization] Producto desconocido:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.addMoney(player, product.Cash)
	DataService.markReceipt(player, receipt.PurchaseId)

	-- Guardamos YA. Si falla, devolvemos NotProcessedYet y Roblox reintentará
	-- (el recibo queda marcado en memoria, así que en esta sesión no se duplica).
	if not DataService.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Notify:FireClient(player, "Money", ("¡Gracias por tu compra! +%d"):format(product.Cash))
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.init()
	Players.PlayerAdded:Connect(checkPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPasses, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Config.GamePasses do
			if pass.Id == passId then
				player:SetAttribute(passAttribute(key), true)
				Notify:FireClient(player, "Success", ("¡Ya tienes %s!"):format(pass.Name))
			end
		end
	end)

	MarketplaceService.ProcessReceipt = processReceipt
end

return MonetizationService
