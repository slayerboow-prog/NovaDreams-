-- FridgeService: lo que hay dentro de las neveras de las casas (reglas en shared/Fridge).
--
--   * Etapa del colegio (con tus padres): la nevera de la casa familiar es gratis y sin límite
--     (InteractService: "Coger algo de comer").
--   * Desde la universidad: la comida se compra en el supermercado (va a la mochila) y se guarda
--     en la nevera de tu casa, de tu piso o de tu habitación de la residencia. Se guarda con tu
--     partida (data.Fridges[clave de la nevera] = { [objeto] = cuántos }).
--   * Al abrirla sale un panel (FridgeUI): lo que hay dentro ("Comer" o "Coger") y lo que llevas en
--     la mochila ("Guardar"). Vacía: "La nevera está vacía: compra comida en el supermercado" (y el
--     botón para llevarte al supermercado más cercano con el GPS).
--   * En casa de otro jugador, solo si estás invitado (su grupo): comes de lo que tiene guardado él.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fridge = require(ReplicatedStorage.Shared.Fridge)
local Floors = require(ReplicatedStorage.Shared.Floors)
local Items = require(ReplicatedStorage.Shared.Items)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local InventoryService = require(script.Parent.InventoryService)

local FridgeService = {}

local Remote: RemoteEvent
local Notify: RemoteEvent
local SESSION_SECONDS = 120
local REACH = 16

export type Context = {
	Mode: string, -- "Free" | "Stock" | "Pay" | "Look"
	Key: string?, -- clave de la nevera en la partida del dueño
	Owner: Player?, -- de quién es lo que hay dentro
	Title: string?,
	Why: string?, -- (Look) por qué no
}

type Session = { Context: Context, Part: BasePart, At: number }
local sessions: { [Player]: Session } = {}

-- Lo guardado en la nevera (en la partida de su dueño)
function FridgeService.stock(owner: Player, key: string): { [string]: number }?
	local data = DataService.get(owner)
	if not data then
		return nil
	end
	data.Fridges = data.Fridges or {}
	data.Fridges[key] = data.Fridges[key] or {}
	return data.Fridges[key]
end

-- ¿Qué pasa al abrir esta nevera? part = la nevera; inst = la sala (nil en la casa familiar)
function FridgeService.context(player: Player, part: BasePart, inst: any, access: string, roomKind: string?): Context
	local stage = player:GetAttribute("LifeStage")
	local familyHome = part:GetAttribute("FamilyHomeId")
	if familyHome ~= nil then
		-- La casa de tus padres
		if familyHome ~= player:GetAttribute("FamilyHomeId") then
			return { Mode = "Look", Why = "🧊 Esta nevera no es de tu casa." }
		end
		if Fridge.freeAtFamily(stage) then
			return { Mode = "Free" }
		end
		return { Mode = "Look", Why = "🧊 Ya no vives con tus padres: tu comida la compras tú en el supermercado." }
	end
	if part:GetAttribute("PlotId") ~= nil then
		-- La casa de la parcela (HouseService): del dueño de la parcela
		if part:GetAttribute("PlotId") ~= player:GetAttribute("PlotId") then
			return { Mode = "Look", Why = "🧊 Esta nevera no es tuya." }
		end
		return { Mode = "Stock", Key = "parcela", Owner = player, Title = "🏡 Tu casa" }
	end
	if roomKind == "Dorm" and inst then
		local key = inst.Building.Key .. "#" .. Floors.unitId(inst.Floor, inst.Unit)
		if player:GetAttribute("DormUnit") ~= key then
			return { Mode = "Look", Why = "🧊 Es la nevera de otra habitación." }
		end
		return { Mode = "Stock", Key = "residencia:" .. key, Owner = player, Title = "🛏 Tu habitación" }
	end
	if access == "Owner" or access == "Guest" then
		local owner = player
		if access == "Guest" and inst then
			local ok, PropertyService = pcall(function()
				return require(script.Parent.PropertyService) :: any
			end)
			local record = ok and PropertyService.ownerOf(inst.Building, inst.Floor, inst.Unit)
			owner = record and Players:GetPlayerByUserId(record.UserId) or nil
		end
		if not owner or not inst then
			return { Mode = "Look", Why = "🧊 El dueño no está: mejor no tocar su comida." }
		end
		local key = "casa:" .. inst.Building.Key .. "#" .. Floors.unitId(inst.Floor, inst.Unit)
		return { Mode = "Stock", Key = key, Owner = owner, Title = if owner == player then "🏠 Tu casa" else ("🏠 Casa de %s"):format(owner.DisplayName) }
	end
	if access == "Public" and roomKind and (require(ReplicatedStorage.Shared.Interact) :: any).ShopKinds[roomKind] then
		return { Mode = "Pay" }
	end
	return { Mode = "Look", Why = "🧊 Echas un vistazo… Mejor no tocar lo que no es tuyo." }
end

-- Lo que ve el panel
local function panelData(player: Player, ctx: Context): { [string]: any }
	local stock = if ctx.Owner and ctx.Key then FridgeService.stock(ctx.Owner, ctx.Key) else nil
	local inside = {}
	for _, entry in Fridge.list(stock) do
		local item = Items.get(entry.Id)
		table.insert(inside, { Id = entry.Id, Count = entry.Count, Name = item and item.Name or entry.Id, Icon = item and item.Icon or "🍽" })
	end
	local bag = {}
	local data = DataService.get(player)
	for id, count in (data and data.Items) or {} do
		local item = Items.get(id)
		if Fridge.isFood(item) and count > 0 then
			table.insert(bag, { Id = id, Count = count, Name = (item :: any).Name, Icon = (item :: any).Icon })
		end
	end
	table.sort(bag, function(a, b)
		return a.Id < b.Id
	end)
	return { Title = ctx.Title or "🧊 Nevera", Inside = inside, Bag = bag, Space = Fridge.MaxStock - Fridge.total(stock), Empty = #inside == 0, Guest = ctx.Owner ~= player }
end

-- Abre el panel de la nevera (modo "Stock")
function FridgeService.show(player: Player, ctx: Context, part: BasePart)
	sessions[player] = { Context = ctx, Part = part, At = os.clock() }
	local data = panelData(player, ctx)
	if data.Empty and #data.Bag == 0 then
		Notify:FireClient(player, "Info", Fridge.EmptyText)
	end
	Remote:FireClient(player, "Fridge", data)
end

local function sessionOf(player: Player): Session?
	local s = sessions[player]
	if not s or os.clock() - s.At > SESSION_SECONDS or not s.Part.Parent then
		sessions[player] = nil
		return nil
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - s.Part.Position).Magnitude > REACH then
		return nil
	end
	return s
end

-- Comer algo de la nevera (se gasta uno)
function FridgeService.eat(player: Player, id: string): boolean
	local s = sessionOf(player)
	local ctx = s and s.Context
	local stock = ctx and ctx.Owner and ctx.Key and FridgeService.stock(ctx.Owner, ctx.Key)
	local item = Items.get(id)
	if not stock or not Fridge.isFood(item) or not Fridge.take(stock, id) then
		return false
	end
	NeedsService.change(player, (item :: any).Hunger or 0, (item :: any).Energy or 0)
	Notify:FireClient(player, "Food", ("¡Ñam! %s"):format((item :: any).Name))
	StoryEvents.emit(player, "Ate", { FoodId = id })
	return true
end

-- Llevárselo a la mochila
function FridgeService.takeOut(player: Player, id: string): boolean
	local s = sessionOf(player)
	local ctx = s and s.Context
	-- Los invitados solo comen: llevarse la comida de otro a la mochila, no
	if not ctx or ctx.Owner ~= player then
		return false
	end
	local stock = ctx.Owner and ctx.Key and FridgeService.stock(ctx.Owner, ctx.Key)
	if not stock or (stock[id] or 0) <= 0 then
		return false
	end
	if not InventoryService.canAdd(player, id, 1) then
		Notify:FireClient(player, "Error", "🎒 No te cabe en la mochila.")
		return false
	end
	Fridge.take(stock, id)
	InventoryService.add(player, id, 1)
	return true
end

-- Guardar comida de la mochila (count o todo lo que haya de eso)
function FridgeService.store(player: Player, id: string, count: number?): number
	local s = sessionOf(player)
	local ctx = s and s.Context
	local stock = ctx and ctx.Owner and ctx.Key and FridgeService.stock(ctx.Owner, ctx.Key)
	local item = Items.get(id)
	if not stock or not Fridge.isFood(item) then
		return 0
	end
	local have = InventoryService.count(player, id)
	local want = math.min(have, count or have)
	local room = Fridge.MaxStock - Fridge.total(stock)
	local n = math.min(want, room)
	if n <= 0 or not InventoryService.remove(player, id, n) then
		if room <= 0 then
			Notify:FireClient(player, "Error", "🧊 La nevera está llena.")
		end
		return 0
	end
	Fridge.store(stock, id, n)
	return n
end

function FridgeService.storeAll(player: Player): number
	local data = DataService.get(player)
	local total = 0
	for id in table.clone((data and data.Items) or {}) do
		if Fridge.isFood(Items.get(id)) then
			total += FridgeService.store(player, id, nil)
		end
	end
	return total
end

function FridgeService.close(player: Player)
	sessions[player] = nil
end

function FridgeService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	Remote = remotes:WaitForChild("Interact") :: RemoteEvent
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, action: any, id: any)
		if kind ~= "Fridge" or type(action) ~= "string" then
			return
		end
		local s = sessionOf(player)
		if not s then
			return
		end
		if action == "Eat" and type(id) == "string" then
			FridgeService.eat(player, id)
		elseif action == "Take" and type(id) == "string" then
			FridgeService.takeOut(player, id)
		elseif action == "Store" and type(id) == "string" then
			FridgeService.store(player, id, nil)
		elseif action == "StoreAll" then
			local n = FridgeService.storeAll(player)
			if n > 0 then
				Notify:FireClient(player, "Success", ("🧊 Has guardado %d cosas en la nevera."):format(n))
			end
		elseif action == "Close" then
			sessions[player] = nil
			return
		end
		s.At = os.clock()
		Remote:FireClient(player, "Fridge", panelData(player, s.Context))
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return FridgeService
