-- SupermarketService: los supermercados funcionan como en la vida real.
--
-- COMPRAR
--   * Coges productos de las estanterías, neveras, congeladores y la frutería (cartel "Coger"):
--     van a tu carrito (arriba a la derecha ves lo que llevas y cuánto suma; puedes devolver cosas).
--   * Pagas en una caja (con cajero: jugador o NPC) o en el autocobro. Lo pagado va a la mochila.
--   * Cada sección tiene existencias: si se vacía, se ve el hueco y hay que reponerla.
--   * Charcutería: pides al corte (producto y gramos) y te lo prepara el charcutero.
--   * Si sales por la puerta sin pagar, pita la alarma y los productos se quedan en la tienda.
--
-- TRABAJAR (tablón "SE BUSCA" de la entrada)
--   * Cajero/a: te sientas en una caja libre. Los clientes hacen cola; pasas sus productos por el
--     lector uno a uno y, si pagan en efectivo, eliges el cambio correcto. Cobras por cliente.
--   * Reponedor/a: coges cajas del almacén y rellenas las secciones vacías (JobService).
--   * Charcutero/a: atiendes el mostrador: cortas y pesas lo que te piden.
--   Si no hay nadie en un puesto, lo hace un NPC: la tienda nunca se queda sin servicio.
--
-- Clientes NPC: entran, recorren los pasillos cogiendo cosas (las secciones se van vaciando),
-- hacen cola en las cajas (prefieren las de jugadores) y se van.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Groceries = require(ReplicatedStorage.Shared.Groceries)
local Format = require(ReplicatedStorage.Shared.Format)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local InventoryService = require(script.Parent.InventoryService)
local JobService = require(script.Parent.JobService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local SupermarketService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Supermarket :: RemoteEvent
local JOBS = Groceries.Jobs

local MAX_CART = 30
local MAX_NPC = 5 -- clientes NPC a la vez en cada supermercado
local ACTIVE_RANGE = 320 -- solo hay vida en los supermercados con algún jugador cerca

type Lane = {
	Belt: BasePart,
	Index: number,
	Cashier: Player?,
	NpcCashier: Model?,
	Queue: { any },
	Session: any?,
	Light: BasePart?,
}

type Store = {
	Model: Model,
	Name: string,
	Shelves: { BasePart },
	Lanes: { Lane },
	Self: { BasePart },
	Deli: BasePart?,
	DeliWorker: Player?,
	NpcDeli: Model?,
	DeliQueue: { any },
	Stock: { BasePart },
	Bounds: BasePart,
	Customers: { any },
	Folder: Folder,
	Doors: { any }?,
}

type Cart = { Store: Store, Items: { [string]: number }, Count: number }

local stores: { Store } = {}
local carts: { [Player]: Cart } = {}
local sessions: { [string]: any } = {}
local jobs: { [Player]: { Role: string, Store: Store, Lane: Lane? } } = {}

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inside(store: Store, position: Vector3): boolean
	local localPos = store.Bounds.CFrame:PointToObjectSpace(position)
	local half = store.Bounds.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Z) <= half.Z and localPos.Y > -half.Y - 2 and localPos.Y < half.Y
end

local function storeOfPart(part: Instance): Store?
	for _, store in stores do
		if part:IsDescendantOf(store.Model) then
			return store
		end
	end
	return nil
end

local function nearestStore(position: Vector3): Store?
	local best, bestDistance = nil, math.huge
	for _, store in stores do
		local d = (store.Bounds.Position - position).Magnitude
		if d < bestDistance then
			best, bestDistance = store, d
		end
	end
	return best
end

local function isDay(): boolean
	local clock = Lighting.ClockTime
	return clock >= 7.5 and clock < 22.5
end

local function pay(player: Player, amount: number, what: string)
	local total = math.floor(amount * MonetizationService.payMultiplier(player))
	DataService.addMoney(player, total, true)
	local data = DataService.get(player)
	if data then
		data.Stats.TasksDone += 1
	end
	Notify:FireClient(player, "Money", ("+%s · %s"):format(Format.money(total), what))
end

local function itemsList(items: { [string]: number }): ({ any }, number)
	local list, total = {}, 0
	for id, count in items do
		local product = Groceries.byId[id]
		if product then
			table.insert(list, { Id = id, Name = product.Name, Icon = product.Icon, Count = count, Price = product.Price })
			total += product.Price * count
		end
	end
	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)
	return list, total
end

---------------------------------------------------------------------
-- Existencias de las estanterías
---------------------------------------------------------------------

local function setStock(shelf: BasePart, stock: number)
	stock = math.clamp(stock, 0, Groceries.StockMax)
	shelf:SetAttribute("Stock", stock)
	-- Se ve el hueco cuando está vacía (y medio llena por debajo de la mitad)
	local goods = {}
	for _, good in shelf:GetChildren() do
		if good:IsA("BasePart") then
			table.insert(goods, good)
		end
	end
	local visible = math.ceil(#goods * stock / Groceries.StockMax)
	for i, good in goods do
		good.Transparency = if i <= visible then 0 else 1
	end
	local prompt = shelf:FindFirstChild("TakePrompt") :: ProximityPrompt?
	if prompt then
		local product = Groceries.byId[shelf:GetAttribute("Product")]
		prompt.ActionText = if stock > 0 then "Coger" else "Agotado"
		prompt.Enabled = stock > 0
		prompt.ObjectText = ("%s %s · %s"):format(product.Icon, product.Name, Format.money(product.Price))
	end
end

local function take(shelf: BasePart): boolean
	local stock = shelf:GetAttribute("Stock") or 0
	if stock <= 0 then
		return false
	end
	setStock(shelf, stock - 1)
	return true
end

-- Devuelve un producto a su sitio en esa tienda
local function giveBack(store: Store, id: string, count: number)
	for _ = 1, count do
		local best: BasePart? = nil
		for _, shelf in store.Shelves do
			if shelf:GetAttribute("Product") == id and (shelf:GetAttribute("Stock") or 0) < Groceries.StockMax then
				if not best or (shelf:GetAttribute("Stock") or 0) < (best:GetAttribute("Stock") or 0) then
					best = shelf
				end
			end
		end
		if best then
			setStock(best, (best:GetAttribute("Stock") or 0) + 1)
		end
	end
end

---------------------------------------------------------------------
-- Carrito
---------------------------------------------------------------------

local function publishCart(player: Player)
	local cart = carts[player]
	if not cart or cart.Count == 0 then
		player:SetAttribute("Cart", nil)
		return
	end
	local list, total = itemsList(cart.Items)
	player:SetAttribute("Cart", HttpService:JSONEncode({ Store = cart.Store.Name, Items = list, Total = total }))
end

local function clearCart(player: Player, restock: boolean)
	local cart = carts[player]
	if not cart then
		return
	end
	if restock then
		for id, count in cart.Items do
			giveBack(cart.Store, id, count)
		end
	end
	carts[player] = nil
	publishCart(player)
end

local function onTake(player: Player, shelf: BasePart)
	local store = storeOfPart(shelf)
	local id = shelf:GetAttribute("Product")
	local product = id and Groceries.byId[id]
	if not store or not product then
		return
	end
	local cart = carts[player]
	if cart and cart.Store ~= store then
		clearCart(player, true)
		cart = nil
	end
	if not cart then
		cart = { Store = store, Items = {}, Count = 0 }
		carts[player] = cart
	end
	local c = cart :: Cart
	if c.Count >= MAX_CART then
		Notify:FireClient(player, "Error", "Tu carrito está lleno. Ve a pagar a una caja.")
		return
	end
	if not take(shelf) then
		Notify:FireClient(player, "Error", "No queda. ¡Avisa al reponedor!")
		return
	end
	c.Items[id] = (c.Items[id] or 0) + 1
	c.Count += 1
	publishCart(player)
end

local function onReturn(player: Player, id: any)
	local cart = carts[player]
	if not cart or typeof(id) ~= "string" or not cart.Items[id] then
		return
	end
	cart.Items[id] -= 1
	cart.Count -= 1
	if cart.Items[id] <= 0 then
		cart.Items[id] = nil
	end
	giveBack(cart.Store, id, 1)
	if cart.Count <= 0 then
		carts[player] = nil
	end
	publishCart(player)
end

---------------------------------------------------------------------
-- Pagar
---------------------------------------------------------------------

-- Cobra el carrito del jugador (ya pasado por caja) y lo mete en la mochila
local function checkout(player: Player): boolean
	local cart = carts[player]
	if not cart or cart.Count == 0 then
		return false
	end
	local list, total = itemsList(cart.Items)
	for _, item in list do
		if not InventoryService.canAdd(player, item.Id, item.Count) then
			Notify:FireClient(player, "Error", "No te cabe todo en la mochila. Devuelve algo o haz hueco.")
			return false
		end
	end
	if not DataService.spend(player, total) then
		Notify:FireClient(player, "Error", ("No tienes suficiente dinero (%s). Devuelve algo al carrito."):format(Format.money(total)))
		return false
	end
	for _, item in list do
		InventoryService.add(player, item.Id, item.Count)
		StoryEvents.emit(player, "BoughtItem", { ShopId = "Supermercado", Item = item.Id, Count = item.Count })
	end
	carts[player] = nil
	publishCart(player)
	Notify:FireClient(player, "Success", ("🧾 Pagado: %s. ¡Está todo en tu mochila!"):format(Format.money(total)))
	StoryEvents.emit(player, "SupermarketPurchase", { Store = cart.Store.Name, Total = total })
	return true
end

-- Ticket para el cliente: la lista, el total y el botón de pagar
local function sendReceipt(player: Player, mode: string, sessionId: string?)
	local cart = carts[player]
	if not cart then
		return
	end
	local list, total = itemsList(cart.Items)
	local token = sessionId or HttpService:GenerateGUID(false)
	sessions[token] = sessions[token] or { Kind = "Receipt", Customer = player }
	sessions[token].Receipt = true
	Remote:FireClient(player, "Receipt", token, list, total, mode)
end

---------------------------------------------------------------------
-- Cajas
---------------------------------------------------------------------

local function laneOpen(lane: Lane): boolean
	return lane.Cashier ~= nil or lane.NpcCashier ~= nil
end

local function setLaneLight(lane: Lane)
	if lane.Light then
		lane.Light.Color = if laneOpen(lane) then Color3.fromRGB(80, 220, 120) else Color3.fromRGB(200, 60, 60)
	end
end

-- Efectivo: con qué billete paga un NPC y opciones de cambio (una correcta)
local function cashFor(total: number): (number, { number }, number)
	local paid = total
	for _, bill in { 5, 10, 20, 50, 100 } do
		if bill > total then
			paid = bill
			break
		end
	end
	local change = paid - total
	local options = { change }
	local tries = 0
	while #options < 3 and tries < 20 do
		tries += 1
		local wrong = math.max(0, change + math.random(-3, 3))
		if not table.find(options, wrong) then
			table.insert(options, wrong)
		end
	end
	for i = #options, 2, -1 do
		local j = math.random(1, i)
		options[i], options[j] = options[j], options[i]
	end
	return paid, options, change
end

-- Empieza a cobrar a alguien en una caja. customer = { Player = p } o { Npc = model, Items = {...} }
local function startSession(store: Store, lane: Lane, customer: any)
	local token = HttpService:GenerateGUID(false)
	local items: { [string]: number }
	if customer.Player then
		local cart = carts[customer.Player]
		items = cart and cart.Items or {}
	else
		items = customer.Items
	end
	local list, total = itemsList(items)
	local session = { Kind = "Lane", Token = token, Store = store, Lane = lane, Customer = customer, List = list, Total = total, Scanned = {}, Started = os.clock() }
	sessions[token] = session
	lane.Session = session
	if lane.Cashier then
		-- El cajero pasa los productos uno a uno
		Remote:FireClient(lane.Cashier, "Scan", token, list, if customer.Player then customer.Player.DisplayName else "Cliente")
		if customer.Player then
			Remote:FireClient(customer.Player, "Waiting", "El cajero está pasando tus productos…")
		end
	else
		-- NPC cajero: tarda un poco y cobra
		task.delay(1.5 + #list * 0.25, function()
			if sessions[token] ~= session then
				return
			end
			if customer.Player then
				sendReceipt(customer.Player, "Caja " .. lane.Index, token)
			else
				sessions[token] = nil
				lane.Session = nil
				if customer.Done then
					customer.Done()
				end
			end
		end)
	end
end

local function endSession(session: any)
	sessions[session.Token] = nil
	if session.Lane then
		session.Lane.Session = nil
	end
end

local function finishCustomer(session: any)
	local lane: Lane = session.Lane
	local customer = session.Customer
	endSession(session)
	if lane.Cashier then
		local job = JOBS.Cajero
		pay(lane.Cashier, job.PerCustomer + job.PerItem * #session.List, "cliente cobrado")
		NeedsService.change(lane.Cashier, 0, -1)
		StoryEvents.emit(lane.Cashier, "JobTaskDone", { JobId = "Cajero" })
		Remote:FireClient(lane.Cashier, "CloseScan")
	end
	if customer.Done then
		customer.Done()
	end
end

local function onScan(player: Player, token: any, index: any)
	local session = sessions[token]
	if not session or session.Kind ~= "Lane" or session.Lane.Cashier ~= player or typeof(index) ~= "number" then
		return
	end
	if not session.List[index] then
		return
	end
	session.Scanned[index] = true
	for i = 1, #session.List do
		if not session.Scanned[i] then
			return
		end
	end
	-- Todo pasado
	if session.Customer.Player then
		sendReceipt(session.Customer.Player, "Caja " .. session.Lane.Index, session.Token)
		Remote:FireClient(player, "ScanDone", token, "Esperando a que el cliente pague con tarjeta…")
	else
		local paid, options = cashFor(session.Total)
		session.Paid = paid
		Remote:FireClient(player, "Change", token, session.Total, paid, options)
	end
end

local function onChange(player: Player, token: any, choice: any)
	local session = sessions[token]
	if not session or session.Kind ~= "Lane" or session.Lane.Cashier ~= player or typeof(choice) ~= "number" or not session.Paid then
		return
	end
	local correct = session.Paid - session.Total
	if choice == correct then
		Notify:FireClient(player, "Success", "¡Cambio correcto! El cliente se va contento.")
		finishCustomer(session)
	else
		session.Mistakes = (session.Mistakes or 0) + 1
		if session.Mistakes >= 2 then
			Notify:FireClient(player, "Error", ("El cambio era %s. El cliente se va algo molesto."):format(Format.money(correct)))
			finishCustomer(session)
		else
			Notify:FireClient(player, "Error", "Ese no es el cambio. ¡Cuenta otra vez!")
		end
	end
end

-- El cliente jugador paga (caja o autocobro)
local function onPay(player: Player, token: any)
	local session = sessions[token]
	if not session or (session.Customer and session.Customer.Player ~= player and session.Customer ~= player) then
		return
	end
	if not checkout(player) then
		return
	end
	if session.Kind == "Lane" then
		finishCustomer(session)
	else
		sessions[token] = nil
	end
end

local function onCancelPay(player: Player, token: any)
	local session = sessions[token]
	if not session then
		return
	end
	if session.Kind == "Lane" and session.Customer.Player == player then
		endSession(session)
		if session.Lane.Cashier then
			Remote:FireClient(session.Lane.Cashier, "CloseScan")
		end
	elseif session.Kind ~= "Lane" then
		sessions[token] = nil
	end
end

local function onLanePrompt(player: Player, store: Store, lane: Lane)
	local cart = carts[player]
	if not cart or cart.Count == 0 then
		Notify:FireClient(player, "Info", "Coge productos de las estanterías y luego ven a pagar aquí.")
		return
	end
	if lane.Cashier == player then
		return
	end
	if not laneOpen(lane) then
		Notify:FireClient(player, "Info", "Esta caja está cerrada. Busca una con la luz verde o usa el autocobro.")
		return
	end
	if lane.Session then
		Notify:FireClient(player, "Info", "Están atendiendo a otra persona. Espera un momento.")
		return
	end
	startSession(store, lane, { Player = player })
end

---------------------------------------------------------------------
-- Charcutería
---------------------------------------------------------------------

local function deliServe(_store: Store, order: any)
	-- order = { Player = p?, Npc = model?, Id, Grams, Done = fn? }
	if order.Player then
		local player: Player = order.Player
		local price = Groceries.deliPrice(order.Id, order.Grams)
		local packs = math.max(1, math.floor(order.Grams / 100 + 0.5))
		if not InventoryService.canAdd(player, order.Id, packs) then
			Notify:FireClient(player, "Error", "No te cabe en la mochila.")
			return
		end
		if not DataService.spend(player, price) then
			Notify:FireClient(player, "Error", "No tienes suficiente dinero para la charcutería.")
			return
		end
		InventoryService.add(player, order.Id, packs)
		local d = Groceries.deliById[order.Id]
		Notify:FireClient(player, "Success", ("🔪 %d g de %s: %s. ¡A la mochila!"):format(order.Grams, d.Name, Format.money(price)))
	end
	if order.Done then
		order.Done()
	end
end

local function deliNext(store: Store)
	local order = store.DeliQueue[1]
	if not order or order.Serving then
		return
	end
	order.Serving = true
	if store.DeliWorker then
		local token = HttpService:GenerateGUID(false)
		sessions[token] = { Kind = "Deli", Store = store, Order = order, Token = token }
		order.Token = token
		local d = Groceries.deliById[order.Id]
		Remote:FireClient(store.DeliWorker, "DeliWork", token, ("%d g de %s"):format(order.Grams, d.Name), order.Player and order.Player.DisplayName or "Cliente")
	else
		task.delay(3, function()
			local i = table.find(store.DeliQueue, order)
			if not i or store.DeliWorker then
				order.Serving = false -- ha llegado un charcutero: lo atiende él
				return
			end
			table.remove(store.DeliQueue, i)
			deliServe(store, order)
			deliNext(store)
		end)
	end
end

local function onDeliServe(player: Player, token: any, id: any, grams: any)
	local session = sessions[token]
	if not session or session.Kind ~= "Deli" or session.Store.DeliWorker ~= player then
		return
	end
	local order = session.Order
	if id ~= order.Id or grams ~= order.Grams then
		Notify:FireClient(player, "Error", "Eso no es lo que te han pedido. ¡Míralo bien!")
		return
	end
	sessions[token] = nil
	local store: Store = session.Store
	local i = table.find(store.DeliQueue, order)
	if i then
		table.remove(store.DeliQueue, i)
	end
	pay(player, JOBS.Charcutero.PerOrder, "pedido de charcutería")
	NeedsService.change(player, 0, -1)
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Charcutero" })
	Remote:FireClient(player, "CloseDeli")
	deliServe(store, order)
	deliNext(store)
end

local function onDeliOrder(player: Player, id: any, grams: any)
	if typeof(id) ~= "string" or not Groceries.deliById[id] or not table.find(Groceries.DeliGrams, grams) then
		return
	end
	local root = rootOf(player)
	local store = root and nearestStore(root.Position)
	if not store or not store.Deli or (store.Deli.Position - (root :: BasePart).Position).Magnitude > 20 then
		return
	end
	for _, o in store.DeliQueue do
		if o.Player == player then
			Notify:FireClient(player, "Info", "Ya tienes un pedido en la charcutería. Espera tu turno.")
			return
		end
	end
	table.insert(store.DeliQueue, { Player = player, Id = id, Grams = grams })
	Notify:FireClient(player, "Info", if store.DeliWorker then "Pedido hecho: el charcutero te lo está preparando." else "Pedido hecho: un momento, que te lo cortan.")
	deliNext(store)
end

---------------------------------------------------------------------
-- Personal NPC (cuando no hay jugadores en el puesto)
---------------------------------------------------------------------

local UNIFORM = { Shirt = Color3.fromRGB(36, 132, 76), Pants = Color3.fromRGB(40, 40, 46) }

local function refreshStaff(store: Store, active: boolean)
	-- Caja 1 siempre abierta con un NPC (si no la lleva un jugador); el resto solo con jugadores
	for i, lane in store.Lanes do
		local wantNpc = active and i == 1 and not lane.Cashier and isDay()
		if wantNpc and not lane.NpcCashier then
			local spot = lane.Belt:GetAttribute("CashierSpot") :: Vector3
			lane.NpcCashier = Npc.create("Npc_Cajero", store.Folder, CFrame.new(spot), UNIFORM)
			Npc.face(lane.NpcCashier :: Model, lane.Belt.Position)
		elseif not wantNpc and lane.NpcCashier then
			lane.NpcCashier:Destroy()
			lane.NpcCashier = nil
		end
		setLaneLight(lane)
	end
	if store.Deli then
		local wantNpc = active and not store.DeliWorker and isDay()
		if wantNpc and not store.NpcDeli then
			local spot = store.Deli:GetAttribute("StaffSpot") :: Vector3
			store.NpcDeli = Npc.create("Npc_Charcutero", store.Folder, CFrame.new(spot), { Shirt = Color3.fromRGB(245, 245, 245), Pants = Color3.fromRGB(40, 40, 46) })
			Npc.face(store.NpcDeli :: Model, store.Deli:GetAttribute("CustomerSpot") :: Vector3)
		elseif not wantNpc and store.NpcDeli then
			store.NpcDeli:Destroy()
			store.NpcDeli = nil
		end
	end
end

---------------------------------------------------------------------
-- Clientes NPC
---------------------------------------------------------------------

local LOOKS = {
	{ Shirt = Color3.fromRGB(200, 70, 60) }, { Shirt = Color3.fromRGB(60, 100, 180) }, { Shirt = Color3.fromRGB(230, 200, 80) },
	{ Shirt = Color3.fromRGB(90, 160, 90) }, { Shirt = Color3.fromRGB(150, 90, 170) }, { Shirt = Color3.fromRGB(240, 240, 240) },
}

local function worldPoint(store: Store, x: number, z: number): Vector3
	local origin = store.Model:GetAttribute("Origin") :: CFrame
	return (origin * CFrame.new(x, 0.4, z)).Position
end

local function chooseLane(store: Store): Lane?
	local best, bestScore = nil, math.huge
	for _, lane in store.Lanes do
		if laneOpen(lane) then
			-- Las cajas con cajero jugador van primero (así tiene trabajo)
			local score = #lane.Queue + (if lane.Cashier then -2 else 0)
			if score < bestScore then
				best, bestScore = lane, score
			end
		end
	end
	return best
end

local function spawnCustomer(store: Store)
	local model = store.Model
	local door = model:GetAttribute("Door") :: Vector3
	local entry = model:GetAttribute("Inside") :: Vector3
	local frontZ = model:GetAttribute("FrontZ") :: number
	local backZ = model:GetAttribute("BackZ") :: number
	local aisles = {}
	for x in string.gmatch(model:GetAttribute("AisleXs") or "", "[^,]+") do
		table.insert(aisles, tonumber(x))
	end
	if #aisles == 0 then
		return
	end
	local npc = Npc.create("Cliente", store.Folder, CFrame.new(door), LOOKS[math.random(1, #LOOKS)])
	local customer = { Npc = npc, Items = {}, Store = store }
	table.insert(store.Customers, customer)
	task.spawn(function()
		pcall(function()
			Npc.walkTo(npc, { entry }, 8)
			-- Recorre 1-3 pasillos cogiendo cosas
			for _ = 1, math.random(1, 3) do
				local x = aisles[math.random(1, #aisles)]
				local z = frontZ + math.random() * (backZ - frontZ)
				Npc.walkTo(npc, { worldPoint(store, x, frontZ), worldPoint(store, x, z) }, 7)
				task.wait(1 + math.random() * 1.5)
				-- Coge algo de la estantería más cercana (se va vaciando de verdad)
				local root = npc.PrimaryPart :: BasePart
				local best, bestDistance = nil, 9
				for _, shelf in store.Shelves do
					local d = (shelf.Position - root.Position).Magnitude
					if d < bestDistance and (shelf:GetAttribute("Stock") or 0) > 0 then
						best, bestDistance = shelf, d
					end
				end
				if best and take(best) then
					local id = best:GetAttribute("Product")
					customer.Items[id] = (customer.Items[id] or 0) + math.random(1, 2)
				end
				Npc.walkTo(npc, { worldPoint(store, x, frontZ) }, 7)
			end
			-- A veces pasa por la charcutería
			if store.Deli and math.random() < 0.3 then
				local spot = store.Deli:GetAttribute("CustomerSpot") :: Vector3
				Npc.walkTo(npc, { spot }, 7)
				local served = false
				local d = Groceries.Deli[math.random(1, #Groceries.Deli)]
				table.insert(store.DeliQueue, { Npc = npc, Id = d.Id, Grams = Groceries.DeliGrams[math.random(1, #Groceries.DeliGrams)], Done = function()
					served = true
				end })
				Npc.say(npc, ("¿Me pone %s, por favor?"):format(string.lower(d.Name)))
				deliNext(store)
				local t0 = os.clock()
				while not served and os.clock() - t0 < 60 do
					task.wait(0.5)
				end
				Npc.say(npc, nil)
			end
			if next(customer.Items) == nil then
				customer.Items.Agua = 1
			end
			-- Cola en una caja
			local lane = chooseLane(store)
			if lane then
				table.insert(lane.Queue, customer)
				local queueSpot = lane.Belt:GetAttribute("QueueSpot") :: Vector3
				local paySpot = lane.Belt:GetAttribute("PaySpot") :: Vector3
				local back = (queueSpot - paySpot).Unit
				local myTurn = false
				while not myTurn do
					local position = table.find(lane.Queue, customer) or 1
					Npc.walkTo(npc, { queueSpot + back * (position - 1) * 3 }, 6)
					if position == 1 and not lane.Session then
						myTurn = true
					else
						task.wait(1)
					end
					if not laneOpen(lane) then
						break
					end
				end
				if myTurn then
					Npc.walkTo(npc, { paySpot }, 6)
					local done = false
					customer.Done = function()
						done = true
					end
					startSession(store, lane, customer)
					local t0 = os.clock()
					while not done and os.clock() - t0 < 90 do
						task.wait(0.5)
					end
					if not done and lane.Session and lane.Session.Customer == customer then
						endSession(lane.Session)
						if lane.Cashier then
							Remote:FireClient(lane.Cashier, "CloseScan")
						end
					end
				end
				local i = table.find(lane.Queue, customer)
				if i then
					table.remove(lane.Queue, i)
				end
			end
			Npc.walkTo(npc, { door }, 8)
		end)
		local i = table.find(store.Customers, customer)
		if i then
			table.remove(store.Customers, i)
		end
		npc:Destroy()
	end)
end

---------------------------------------------------------------------
-- Oficios
---------------------------------------------------------------------

local function quitRole(player: Player, silent: boolean?)
	local job = jobs[player]
	if not job then
		return
	end
	jobs[player] = nil
	if job.Lane then
		local lane = job.Lane
		lane.Cashier = nil
		if lane.Session then
			local session = lane.Session
			endSession(session)
			if session.Customer.Player then
				Remote:FireClient(session.Customer.Player, "Waiting", nil)
			end
		end
	end
	if job.Role == "Charcutero" and job.Store.DeliWorker == player then
		job.Store.DeliWorker = nil
		for _, order in job.Store.DeliQueue do
			order.Serving = false
		end
		for token, s in sessions do
			if s.Kind == "Deli" and s.Store == job.Store then
				sessions[token] = nil
			end
		end
		deliNext(job.Store)
	end
	if player:GetAttribute("Job") == job.Role then
		player:SetAttribute("Job", nil)
		player:SetAttribute("TaskTarget", nil)
		player:SetAttribute("TaskText", nil)
	end
	Remote:FireClient(player, "CloseScan")
	Remote:FireClient(player, "CloseDeli")
	refreshStaff(job.Store, true)
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado tu turno en el supermercado.")
	end
end

local function startRole(player: Player, store: Store, role: string)
	if jobs[player] and jobs[player].Role == role then
		quitRole(player)
		return
	end
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	if role == "Reponedor" then
		quitRole(player, true)
		JobService.start(player, "Reponedor", { Store = store })
		return
	end
	JobService.quit(player, true)
	quitRole(player, true)
	if role == "Cajero" then
		local free: Lane? = nil
		for _, lane in store.Lanes do
			if not lane.Cashier then
				free = lane
				break
			end
		end
		if not free then
			Notify:FireClient(player, "Error", "Todas las cajas tienen cajero. ¡Prueba otro puesto!")
			return
		end
		local lane = free :: Lane
		if lane.NpcCashier then
			lane.NpcCashier:Destroy()
			lane.NpcCashier = nil
		end
		lane.Cashier = player
		jobs[player] = { Role = "Cajero", Store = store, Lane = lane }
		player:SetAttribute("Job", "Cajero")
		player:SetAttribute("TaskTarget", lane.Belt:GetAttribute("CashierSpot"))
		player:SetAttribute("TaskText", ("Caja %d: %s"):format(lane.Index, JOBS.Cajero.Text))
		Notify:FireClient(player, "Success", ("🧾 ¡Contratado de cajero! Ponte en la caja %d. Los clientes vendrán a tu cola."):format(lane.Index))
	elseif role == "Charcutero" then
		if not store.Deli then
			return
		end
		if store.DeliWorker then
			Notify:FireClient(player, "Error", "La charcutería ya tiene charcutero. ¡Prueba otro puesto!")
			return
		end
		store.DeliWorker = player
		if store.NpcDeli then
			store.NpcDeli:Destroy()
			store.NpcDeli = nil
		end
		jobs[player] = { Role = "Charcutero", Store = store }
		player:SetAttribute("Job", "Charcutero")
		player:SetAttribute("TaskTarget", store.Deli:GetAttribute("StaffSpot"))
		player:SetAttribute("TaskText", JOBS.Charcutero.Text)
		Notify:FireClient(player, "Success", "🔪 ¡Contratado de charcutero! Ponte detrás del mostrador.")
		for _, order in store.DeliQueue do
			order.Serving = false
		end
		deliNext(store)
	end
	refreshStaff(store, true)
end

-- Reponedor (JobService): coge una caja en el almacén de SU tienda y rellena el hueco más vacío
local function storeForShift(player: Player, shift: any): Store?
	local context = shift.Context
	if context and context.Store then
		return context.Store
	end
	local root = rootOf(player)
	local store = root and nearestStore(root.Position)
	shift.Context = { Store = store }
	return store
end

JobService.setProvider("Reponedor", {
	Pickup = function(player, shift)
		local store = storeForShift(player, shift)
		if not store or #store.Stock == 0 then
			return nil
		end
		return store.Stock[math.random(1, #store.Stock)]
	end,
	Dropoff = function(player, shift)
		local store = storeForShift(player, shift)
		if not store then
			return nil
		end
		local best, bestStock = nil, math.huge
		for _, shelf in store.Shelves do
			local stock = (shelf:GetAttribute("Stock") or 0) + math.random() * 0.5
			if stock < bestStock then
				best, bestStock = shelf, stock
			end
		end
		shift.Context.Shelf = best
		return best
	end,
	Done = function(_player, shift)
		local shelf = shift.Context and shift.Context.Shelf
		if shelf then
			setStock(shelf, Groceries.StockMax)
		end
	end,
})

---------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------

local function prompt(parent: Instance, action: string, object: string, key: Enum.KeyCode?, distance: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = distance or 7
	p.RequiresLineOfSight = false
	if key then
		p.KeyboardKeyCode = key
	end
	p.Parent = parent
	return p
end

local function setupStore(model: Instance)
	if not model:IsA("Model") or model:GetAttribute("Setup") then
		return
	end
	model:SetAttribute("Setup", true)
	local folder = Instance.new("Folder")
	folder.Name = "Vida_" .. (model:GetAttribute("Store") or "Super")
	folder.Parent = workspace
	local store: Store = {
		Model = model,
		Name = model:GetAttribute("Store") or "Supermercado",
		Shelves = {},
		Lanes = {},
		Self = {},
		DeliQueue = {},
		Stock = {},
		Bounds = nil :: any,
		Customers = {},
		Folder = folder,
	}
	local lights = {}
	for _, d in model:GetDescendants() do
		if d:HasTag("SuperShelf") then
			table.insert(store.Shelves, d)
		elseif d:HasTag("SuperCheckout") then
			table.insert(store.Lanes, { Belt = d, Index = d:GetAttribute("Lane") or #store.Lanes + 1, Queue = {} })
		elseif d:HasTag("SuperSelfCheckout") then
			table.insert(store.Self, d)
		elseif d:HasTag("SuperDeli") then
			store.Deli = d
		elseif d:HasTag("SuperStock") then
			table.insert(store.Stock, d)
		elseif d:HasTag("SuperBounds") then
			store.Bounds = d
		elseif d.Name == "LaneLight" then
			lights[d:GetAttribute("Lane")] = d
		end
	end
	if not store.Bounds then
		return
	end
	table.sort(store.Lanes, function(a, b)
		return a.Index < b.Index
	end)
	for _, lane in store.Lanes do
		lane.Light = lights[lane.Index]
	end
	table.insert(stores, store)

	-- Estanterías: coger productos
	for _, shelf in store.Shelves do
		local product = Groceries.byId[shelf:GetAttribute("Product")]
		if product then
			local p = prompt(shelf, "Coger", "", Enum.KeyCode.E, 6)
			p.Name = "TakePrompt"
			p.Triggered:Connect(function(player)
				onTake(player, shelf)
			end)
			-- Unas llenas y otras a medias (como en una tienda de verdad)
			setStock(shelf, math.random(6, Groceries.StockMax))
		end
	end
	-- Cajas
	for _, lane in store.Lanes do
		local p = prompt(lane.Belt, "Pagar aquí", "🧾 Caja " .. lane.Index, Enum.KeyCode.E, 8)
		p.Triggered:Connect(function(player)
			onLanePrompt(player, store, lane)
		end)
	end
	-- Autocobro
	for _, kiosk in store.Self do
		local p = prompt(kiosk, "Pagar", "🖥️ Autocobro", Enum.KeyCode.E, 7)
		p.Triggered:Connect(function(player)
			local cart = carts[player]
			if not cart or cart.Count == 0 then
				Notify:FireClient(player, "Info", "El carrito está vacío. Coge productos y vuelve a pagar.")
				return
			end
			sendReceipt(player, "Autocobro")
		end)
	end
	-- Charcutería
	if store.Deli then
		local p = prompt(store.Deli, "Pedir al corte", "🔪 Charcutería", Enum.KeyCode.E, 9)
		p.Triggered:Connect(function(player)
			if store.DeliWorker == player then
				return
			end
			Remote:FireClient(player, "DeliMenu", Groceries.Deli, Groceries.DeliGrams)
		end)
	end
	-- Tablón de empleo
	for _, board in model:GetDescendants() do
		if board:HasTag("SuperBoard") then
			local keys = { Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.T }
			for i, role in { "Cajero", "Reponedor", "Charcutero" } do
				local job = JOBS[role]
				local p = prompt(board, job.Icon .. " " .. job.Name, "Trabajar en " .. store.Name, keys[i], 8)
				p.UIOffset = Vector2.new(0, (i - 1) * 58)
				p.HoldDuration = 0.4
				p.Triggered:Connect(function(player)
					startRole(player, store, role)
				end)
			end
		end
	end
	-- Puertas automáticas
	local doors = {}
	for _, door in model:GetDescendants() do
		if door:HasTag("SuperDoor") and door:IsA("BasePart") then
			local slide = door:GetAttribute("Slide") :: Vector3
			local closed = door.CFrame
			table.insert(doors, { Part = door, Closed = closed, Open = closed + closed:VectorToWorldSpace(slide), IsOpen = false })
		end
	end
	store.Doors = doors
end

-- ¿Hay alguien junto a la puerta? (jugadores o clientes NPC)
local function someoneNear(position: Vector3, store: Store): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - position).Magnitude < 10 then
			return true
		end
	end
	for _, customer in store.Customers do
		local root = customer.Npc.PrimaryPart
		if root and (root.Position - position).Magnitude < 10 then
			return true
		end
	end
	return false
end

function SupermarketService.init()
	for _, model in CollectionService:GetTagged("Supermarket") do
		setupStore(model)
	end
	CollectionService:GetInstanceAddedSignal("Supermarket"):Connect(setupStore)

	Remote.OnServerEvent:Connect(function(player, action, a, b, c)
		if action == "Return" then
			onReturn(player, a)
		elseif action == "Pay" then
			onPay(player, a)
		elseif action == "CancelPay" then
			onCancelPay(player, a)
		elseif action == "Scan" then
			onScan(player, a, b)
		elseif action == "Change" then
			onChange(player, a, b)
		elseif action == "DeliOrder" then
			onDeliOrder(player, a, b)
		elseif action == "DeliServe" then
			onDeliServe(player, a, b, c)
		end
	end)

	ReplicatedStorage.Remotes.QuitJob.OnServerEvent:Connect(function(player)
		quitRole(player)
	end)
	local function watch(player: Player)
		player:GetAttributeChangedSignal("Job"):Connect(function()
			local job = jobs[player]
			if job and player:GetAttribute("Job") ~= job.Role then
				quitRole(player, true)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		quitRole(player, true)
		clearCart(player, true)
		for token, s in sessions do
			if s.Customer and (s.Customer.Player == player or s.Customer == player) then
				if s.Kind == "Lane" then
					endSession(s)
					if s.Lane.Cashier then
						Remote:FireClient(s.Lane.Cashier, "CloseScan")
					end
				else
					sessions[token] = nil
				end
			end
		end
	end)

	-- Puertas, alarma de salida y personal (varias veces por segundo)
	task.spawn(function()
		while true do
			task.wait(0.3)
			for _, store in stores do
				for _, door in store.Doors or {} do
					local open = someoneNear(door.Closed.Position, store)
					if open ~= door.IsOpen then
						door.IsOpen = open
						TweenService:Create(door.Part, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { CFrame = if open then door.Open else door.Closed }):Play()
					end
				end
			end
			for player, cart in carts do
				local root = rootOf(player)
				if root and not inside(cart.Store, root.Position) then
					clearCart(player, true)
					Notify:FireClient(player, "Error", "🚨 ¡Pi-pi-pi! Has salido sin pagar: los productos se quedan en la tienda.")
				end
			end
		end
	end)

	-- Vida de cada supermercado: clientes, personal NPC y reposición
	task.spawn(function()
		local lastRestock: { [Store]: number } = {}
		while true do
			task.wait(2)
			for _, store in stores do
				local active = false
				for _, player in Players:GetPlayers() do
					local root = rootOf(player)
					if root and (root.Position - store.Bounds.Position).Magnitude < ACTIVE_RANGE then
						active = true
						break
					end
				end
				refreshStaff(store, active)
				if active and isDay() and #store.Customers < MAX_NPC and math.random() < 0.18 then
					spawnCustomer(store)
				end
				-- Reposición NPC si nadie repone en esta tienda
				local restocker = false
				for _, player in Players:GetPlayers() do
					local shift = JobService.shiftOf(player)
					if shift and shift.JobId == "Reponedor" and shift.Context and shift.Context.Store == store then
						restocker = true
					end
				end
				if not restocker and os.clock() - (lastRestock[store] or 0) > Groceries.NpcRestockEvery then
					lastRestock[store] = os.clock()
					for _, shelf in store.Shelves do
						if (shelf:GetAttribute("Stock") or 0) <= 2 then
							setStock(shelf, Groceries.StockMax)
							break
						end
					end
				end
			end
			-- Cobros que se atascan (el cajero se ha ido): los termina el sistema
			for _, session in sessions do
				if session.Kind == "Lane" and os.clock() - session.Started > 120 and not session.Customer.Player then
					finishCustomer(session)
				end
			end
		end
	end)
end

return SupermarketService
