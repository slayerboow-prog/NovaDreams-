-- TradeService: intercambio entre jugadores y mercadillo (compraventa).
--
-- INTERCAMBIO (cara a cara)
--   * Te acercas a otro jugador y "Intercambiar". Le llega la invitación; si acepta, se abre la
--     ventana a los dos. Cada uno pone lo que da (objetos de la mochila y/o dinero).
--   * Cuando los dos pulsan "Aceptar" empieza una cuenta atrás corta. Si alguien cambia algo, se
--     quitan los "Aceptar" (así nadie te cambia la oferta en el último segundo).
--   * Al acabar la cuenta atrás se hace todo a la vez: o sale entero o no sale nada.
--
-- MERCADILLO (app del teléfono)
--   * Pones cosas de tu mochila a la venta con un precio. Los demás jugadores del servidor las ven
--     y las compran al momento. El mercadillo se queda un 5 %.
--   * Los objetos no salen de tu mochila hasta que alguien los compra. Si te vas, tus anuncios se quitan.
--
-- Normas de Roblox: si PolicyService dice que en tu país no se pueden intercambiar objetos de pago
-- (IsPaidItemTradingAllowed = false), no puedes intercambiar ni usar el mercadillo (ver Trade.luau).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trade = require(ReplicatedStorage.Shared.Trade)
local Items = require(ReplicatedStorage.Shared.Items)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local TradeService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Trade :: RemoteEvent
local MARKET = Trade.Market

type Side = { Player: Player, Items: { [string]: number }, Money: number, Accepted: boolean }
type Session = { A: Side, B: Side, Token: number, Counting: boolean }
type Listing = { Id: number, Seller: Player, SellerName: string, Item: string, Count: number, Price: number }

local sessionOf: { [Player]: Session } = {}
local invites: { [Player]: { From: Player, Until: number } } = {}
local listings: { Listing } = {}
local nextListing = 0
local policyCache: { [Player]: boolean } = {}

local function nameOf(player: Player): string
	return player.DisplayName or player.Name
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function distance(a: Player, b: Player): number
	local ra, rb = rootOf(a), rootOf(b)
	if not ra or not rb then
		return math.huge
	end
	return (ra.Position - rb.Position).Magnitude
end

local function isInt(n: any, min: number, max: number): boolean
	return typeof(n) == "number" and n == n and n % 1 == 0 and n >= min and n <= max
end

-- ¿Deja Roblox a este jugador intercambiar objetos de pago? (se pregunta una vez por jugador)
local function policyAllows(player: Player): boolean?
	local cached = policyCache[player]
	if cached ~= nil then
		return cached
	end
	local ok, info = pcall(function()
		return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(player)
	end)
	if not ok or typeof(info) ~= "table" then
		return nil -- no se ha podido saber: mejor no dejar (se vuelve a intentar la próxima vez)
	end
	local allowed = info.IsPaidItemTradingAllowed == true
	policyCache[player] = allowed
	return allowed
end

-- ¿Puede este jugador intercambiar o usar el mercadillo? Si no, avisa y devuelve false.
local function allowed(player: Player, silent: boolean?): boolean
	local function no(text: string): boolean
		if not silent then
			Notify:FireClient(player, "Error", text)
		end
		return false
	end
	if not DataService.get(player) then
		return false
	end
	local stage = player:GetAttribute("LifeStage")
	if type(stage) == "string" and Stages.isValid(stage) and not Stages.inRange(stage, "Nino", nil) then
		return no("Los bebés no pueden intercambiar cosas.")
	end
	local policy = policyAllows(player)
	if policy == nil then
		return no("No se ha podido comprobar si puedes intercambiar. Prueba otra vez en un momento.")
	elseif policy == false then
		return no("En tu país las normas de Roblox no permiten intercambiar ni vender objetos entre jugadores.")
	end
	return true
end

---------------------------------------------------------------------
-- Intercambio
---------------------------------------------------------------------

local function itemList(offer: { [string]: number }): { any }
	local list = {}
	for id, count in offer do
		local item = Items.get(id)
		if item then
			table.insert(list, { Id = id, Name = item.Name, Icon = item.Icon, Count = count })
		end
	end
	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)
	return list
end

local function sides(session: Session, player: Player): (Side, Side)
	if session.A.Player == player then
		return session.A, session.B
	end
	return session.B, session.A
end

local function publish(session: Session)
	for _, side in { session.A, session.B } do
		local me, them = sides(session, side.Player)
		Remote:FireClient(side.Player, "Session", {
			Me = { Items = itemList(me.Items), Money = me.Money, Accepted = me.Accepted },
			Them = { Name = nameOf(them.Player), Items = itemList(them.Items), Money = them.Money, Accepted = them.Accepted },
			Counting = session.Counting,
			Seconds = Trade.ConfirmSeconds,
		})
	end
end

local function close(session: Session, text: string?)
	for _, side in { session.A, session.B } do
		if sessionOf[side.Player] == session then
			sessionOf[side.Player] = nil
		end
		if side.Player.Parent then
			Remote:FireClient(side.Player, "Closed", text)
		end
	end
	session.Token += 1
end

-- ¿Sigue teniendo lo que ofrece?
local function stillHas(side: Side): boolean
	for id, count in side.Items do
		if InventoryService.count(side.Player, id) < count then
			return false
		end
	end
	local data = DataService.get(side.Player)
	return data ~= nil and data.Money >= side.Money
end

local function saveBoth(a: Player, b: Player)
	local save = (DataService :: any).save
	if save then
		task.spawn(pcall, save, a)
		task.spawn(pcall, save, b)
	end
end

-- Hace el intercambio de golpe: o todo o nada
local function execute(session: Session)
	local a, b = session.A, session.B
	if not stillHas(a) or not stillHas(b) then
		close(session, "Alguien ya no tiene lo que ofrecía. Intercambio cancelado.")
		return
	end
	local removed: { { Player: Player, Id: string, Count: number } } = {}
	local added: { { Player: Player, Id: string, Count: number } } = {}
	local function rollback()
		for _, r in added do
			InventoryService.remove(r.Player, r.Id, r.Count)
		end
		for _, r in removed do
			InventoryService.add(r.Player, r.Id, r.Count)
		end
	end
	-- 1) Cada uno entrega sus objetos
	for _, side in { a, b } do
		for id, count in side.Items do
			if not InventoryService.remove(side.Player, id, count) then
				rollback()
				close(session, "No se ha podido hacer el intercambio.")
				return
			end
			table.insert(removed, { Player = side.Player, Id = id, Count = count })
		end
	end
	-- 2) Cada uno recibe los del otro (si alguno no cabe en la mochila, se deshace todo)
	for _, pair in { { a, b }, { b, a } } do
		local from, to = pair[1], pair[2]
		for id, count in from.Items do
			if not InventoryService.add(to.Player, id, count) then
				rollback()
				close(session, ("A %s no le cabe todo en la mochila. Intercambio cancelado."):format(nameOf(to.Player)))
				return
			end
			table.insert(added, { Player = to.Player, Id = id, Count = count })
		end
	end
	-- 3) El dinero
	if a.Money > 0 and not DataService.spend(a.Player, a.Money) then
		rollback()
		close(session, "No se ha podido hacer el intercambio.")
		return
	end
	if b.Money > 0 and not DataService.spend(b.Player, b.Money) then
		if a.Money > 0 then
			DataService.addMoney(a.Player, a.Money)
		end
		rollback()
		close(session, "No se ha podido hacer el intercambio.")
		return
	end
	if a.Money > 0 then
		DataService.addMoney(b.Player, a.Money)
	end
	if b.Money > 0 then
		DataService.addMoney(a.Player, b.Money)
	end
	close(session, nil)
	for _, side in { a, b } do
		local _, them = sides(session, side.Player)
		Notify:FireClient(side.Player, "Success", ("🤝 ¡Intercambio hecho con %s!"):format(nameOf(them.Player)))
	end
	saveBoth(a.Player, b.Player)
end

local function onRequest(player: Player, userId: any)
	if typeof(userId) ~= "number" or sessionOf[player] or not allowed(player) then
		return
	end
	local target = Players:GetPlayerByUserId(userId)
	if not target or target == player then
		return
	end
	if distance(player, target) > Trade.Range then
		Notify:FireClient(player, "Info", "Acércate más para intercambiar.")
		return
	end
	if sessionOf[target] then
		Notify:FireClient(player, "Info", nameOf(target) .. " ya está intercambiando con alguien.")
		return
	end
	if not allowed(target, true) then
		Notify:FireClient(player, "Info", nameOf(target) .. " no puede intercambiar ahora.")
		return
	end
	invites[target] = { From = player, Until = os.clock() + Trade.InviteSeconds }
	Remote:FireClient(target, "Invite", { Name = nameOf(player), UserId = player.UserId, Seconds = Trade.InviteSeconds })
	Notify:FireClient(player, "Info", ("Invitación enviada a %s. Esperando…"):format(nameOf(target)))
end

local function onAnswer(player: Player, userId: any, yes: any)
	local invite = invites[player]
	if not invite or typeof(userId) ~= "number" or invite.From.UserId ~= userId then
		return
	end
	invites[player] = nil
	local from = invite.From
	if os.clock() > invite.Until or not from.Parent then
		Notify:FireClient(player, "Info", "La invitación ha caducado.")
		return
	end
	if yes ~= true then
		Notify:FireClient(from, "Info", nameOf(player) .. " no quiere intercambiar ahora.")
		return
	end
	if sessionOf[player] or sessionOf[from] or not allowed(player) or not allowed(from, true) then
		return
	end
	if distance(player, from) > Trade.KeepRange then
		Notify:FireClient(player, "Info", "Estáis demasiado lejos.")
		return
	end
	local session: Session = {
		A = { Player = from, Items = {}, Money = 0, Accepted = false },
		B = { Player = player, Items = {}, Money = 0, Accepted = false },
		Token = 0,
		Counting = false,
	}
	sessionOf[from] = session
	sessionOf[player] = session
	publish(session)
end

local function onOffer(player: Player, offer: any, money: any)
	local session = sessionOf[player]
	if not session or typeof(offer) ~= "table" then
		return
	end
	local data = DataService.get(player)
	if not data or not isInt(money, 0, math.min(Trade.MaxMoney, data.Money)) then
		Notify:FireClient(player, "Error", "No tienes ese dinero.")
		return
	end
	local clean, kinds = {}, 0
	for id, count in offer do
		if not Trade.tradeable(id) then
			Notify:FireClient(player, "Error", "Eso no se puede intercambiar.")
			return
		end
		if not isInt(count, 1, InventoryService.count(player, id)) then
			Notify:FireClient(player, "Error", "No tienes tantos.")
			return
		end
		kinds += 1
		if kinds > Trade.MaxKinds then
			Notify:FireClient(player, "Error", ("Como mucho %d cosas distintas."):format(Trade.MaxKinds))
			return
		end
		clean[id] = count
	end
	local me = sides(session, player)
	me.Items = clean
	me.Money = money
	-- Cualquier cambio quita los "Aceptar" de los dos
	session.A.Accepted = false
	session.B.Accepted = false
	session.Counting = false
	session.Token += 1
	publish(session)
end

local function onAccept(player: Player, yes: any)
	local session = sessionOf[player]
	if not session then
		return
	end
	local me = sides(session, player)
	me.Accepted = yes == true
	session.Token += 1
	session.Counting = session.A.Accepted and session.B.Accepted
	publish(session)
	if session.Counting then
		local token = session.Token
		task.delay(Trade.ConfirmSeconds, function()
			if session.Token == token and session.Counting and sessionOf[session.A.Player] == session then
				execute(session)
			end
		end)
	end
end

local function cancel(player: Player, text: string?)
	local session = sessionOf[player]
	if session then
		close(session, text or (nameOf(player) .. " ha cancelado el intercambio."))
	end
end

---------------------------------------------------------------------
-- Mercadillo
---------------------------------------------------------------------

local function marketData(): { any }
	local list = {}
	for _, l in listings do
		local item = Items.get(l.Item)
		if item then
			table.insert(list, { Id = l.Id, Seller = l.SellerName, SellerId = l.Seller.UserId, Item = l.Item, Name = item.Name, Icon = item.Icon, Count = l.Count, Price = l.Price })
		end
	end
	return list
end

-- El mercado a todos, como mucho dos veces por segundo: si cambia muy seguido, los cambios se juntan
-- en un envío (antes anunciar y retirar sin parar mandaba el mercado entero a todos los jugadores en
-- cada petición). Quien ha hecho el cambio (actors) lo ve al momento.
local BROADCAST_GAP = 0.5
local lastBroadcast = -math.huge
local broadcastPending = false
local function broadcastMarket(actors: { Player }?)
	local now = os.clock()
	if broadcastPending then
		-- (ya sale uno en un momento)
	elseif now - lastBroadcast >= BROADCAST_GAP then
		lastBroadcast = now
		Remote:FireAllClients("Market", marketData())
		return
	else
		broadcastPending = true
		task.delay(BROADCAST_GAP - (now - lastBroadcast), function()
			broadcastPending = false
			lastBroadcast = os.clock()
			Remote:FireAllClients("Market", marketData())
		end)
	end
	if actors then
		local data = marketData()
		for _, player in actors do
			if player.Parent then
				Remote:FireClient(player, "Market", data)
			end
		end
	end
end

local function listedCount(seller: Player, id: string): number
	local n = 0
	for _, l in listings do
		if l.Seller == seller and l.Item == id then
			n += l.Count
		end
	end
	return n
end

local function removeListing(listing: Listing)
	local i = table.find(listings, listing)
	if i then
		table.remove(listings, i)
	end
end

local function onList(player: Player, id: any, count: any, price: any)
	if not allowed(player) then
		return
	end
	if not Trade.tradeable(id) then
		Notify:FireClient(player, "Error", "Eso no se puede vender aquí.")
		return
	end
	if not isInt(price, MARKET.MinPrice, MARKET.MaxPrice) then
		Notify:FireClient(player, "Error", ("El precio tiene que estar entre %s y %s."):format(Format.money(MARKET.MinPrice), Format.money(MARKET.MaxPrice)))
		return
	end
	if not isInt(count, 1, InventoryService.count(player, id) - listedCount(player, id)) then
		Notify:FireClient(player, "Error", "No tienes tantos (o ya los tienes a la venta).")
		return
	end
	local mine = 0
	for _, l in listings do
		if l.Seller == player then
			mine += 1
		end
	end
	if mine >= MARKET.MaxListings then
		Notify:FireClient(player, "Error", ("Como mucho %d anuncios a la vez."):format(MARKET.MaxListings))
		return
	end
	nextListing += 1
	table.insert(listings, { Id = nextListing, Seller = player, SellerName = nameOf(player), Item = id, Count = count, Price = price })
	Notify:FireClient(player, "Success", ("🛍️ Puesto a la venta: %d × %s por %s."):format(count, Items.get(id).Name, Format.money(price)))
	broadcastMarket({ player })
end

local function onUnlist(player: Player, listingId: any)
	for _, l in listings do
		if l.Id == listingId and l.Seller == player then
			removeListing(l)
			broadcastMarket({ player })
			return
		end
	end
end

local function onBuy(player: Player, listingId: any)
	local listing = nil
	for _, l in listings do
		if l.Id == listingId then
			listing = l
			break
		end
	end
	if not listing then
		Notify:FireClient(player, "Info", "Ese anuncio ya no está.")
		Remote:FireClient(player, "Market", marketData())
		return
	end
	local seller = listing.Seller
	if seller == player then
		Notify:FireClient(player, "Info", "Es tu propio anuncio.")
		return
	end
	if not allowed(player) then
		return
	end
	if not seller.Parent or InventoryService.count(seller, listing.Item) < listing.Count then
		removeListing(listing)
		broadcastMarket({ player })
		Notify:FireClient(player, "Info", "El vendedor ya no lo tiene.")
		return
	end
	if not InventoryService.canAdd(player, listing.Item, listing.Count) then
		Notify:FireClient(player, "Error", "No te cabe en la mochila.")
		return
	end
	if not DataService.spend(player, listing.Price) then
		Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
		return
	end
	if not InventoryService.remove(seller, listing.Item, listing.Count) then
		DataService.addMoney(player, listing.Price)
		return
	end
	if not InventoryService.add(player, listing.Item, listing.Count) then
		InventoryService.add(seller, listing.Item, listing.Count)
		DataService.addMoney(player, listing.Price)
		Notify:FireClient(player, "Error", "No te cabe en la mochila.")
		return
	end
	removeListing(listing)
	local earned = Trade.sellerGets(listing.Price)
	DataService.addMoney(seller, earned, true)
	local item = Items.get(listing.Item) :: any
	Notify:FireClient(player, "Success", ("🛍️ Has comprado %d × %s a %s."):format(listing.Count, item.Name, listing.SellerName))
	Notify:FireClient(seller, "Money", ("+%s · %s ha comprado tu %s"):format(Format.money(earned), nameOf(player), item.Name))
	broadcastMarket({ player, seller })
	saveBoth(player, seller)
end

---------------------------------------------------------------------

function TradeService.init()
	local lastMarket: { [Player]: number } = {}
	Remote.OnServerEvent:Connect(function(player, action, a, b, c)
		if action == "Request" then
			onRequest(player, a)
		elseif action == "Answer" then
			onAnswer(player, a, b)
		elseif action == "Offer" then
			onOffer(player, a, b)
		elseif action == "Accept" then
			onAccept(player, a)
		elseif action == "Cancel" then
			cancel(player, nil)
		elseif action == "Market" then
			-- (pedir la lista entera: una vez por segundo como mucho)
			local t = os.clock()
			if t - (lastMarket[player] or -math.huge) >= 1 then
				lastMarket[player] = t
				Remote:FireClient(player, "Market", marketData())
			end
		elseif action == "List" then
			onList(player, a, b, c)
		elseif action == "Unlist" then
			onUnlist(player, a)
		elseif action == "Buy" then
			onBuy(player, a)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastMarket[player] = nil
		cancel(player, nameOf(player) .. " se ha ido.")
		invites[player] = nil
		policyCache[player] = nil
		local changed = false
		for i = #listings, 1, -1 do
			if listings[i].Seller == player then
				table.remove(listings, i)
				changed = true
			end
		end
		if changed then
			broadcastMarket()
		end
	end)
	-- Si os separáis mucho, el intercambio se cancela
	task.spawn(function()
		while true do
			task.wait(1)
			local seen = {}
			for _, session in sessionOf do
				if not seen[session] then
					seen[session] = true
					if distance(session.A.Player, session.B.Player) > Trade.KeepRange then
						close(session, "Os habéis alejado demasiado. Intercambio cancelado.")
					end
				end
			end
		end
	end)
end

-- Para las pruebas
TradeService._sessionOf = sessionOf
TradeService._policyCache = policyCache

return TradeService
