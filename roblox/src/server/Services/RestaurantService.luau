-- RestaurantService: el Restaurante Valmar, un trabajo en PAREJA.
--
--   CAMARERO (sala)  -> atiende a los clientes NPC que se sientan (✋). El cliente dice lo que quiere
--                       y el camarero tiene que elegir, entre varias opciones, lo que ha pedido.
--                       Luego recoge el plato en el pase y se lo sirve.
--   BARMAN (barra)   -> recibe las comandas y, para cada plato, elige los ingredientes correctos.
--
-- Si solo hay un jugador trabajando, el otro puesto lo hace un NPC (nunca se queda nadie esperando).
-- Etiquetas del mapa (TownBuilder.buildRestaurant): RestaurantBoard, RestaurantBar, RestaurantPass,
-- RestaurantTable/RestaurantSeat (+TableId), RestaurantDoor, RestaurantWaiterSpot, RestaurantBarmanSpot.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local MonetizationService = require(script.Parent.MonetizationService)
local LifeService = require(script.Parent.LifeService)
local JobService = require(script.Parent.JobService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local RestaurantService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Restaurant :: RemoteEvent
local R = Gameplay.Restaurant

type Order = {
	Id: number,
	CustomerId: number,
	TableId: number,
	Items: { string },
	Done: { boolean },
	Ready: boolean,
	Plate: BasePart?,
}

type Customer = {
	Id: number,
	TableId: number,
	Seat: BasePart,
	Model: Model,
	State: "Arriving" | "WaitingOrder" | "Ordering" | "WaitingFood" | "Eating" | "Leaving",
	Items: { string },
	Since: number, -- desde cuándo espera (para la paciencia)
	Arrived: number,
	Mistakes: number,
	Order: Order?,
	Choice: { Token: string, Correct: number, Waiter: Player }?,
	Prompt: ProximityPrompt?,
}

type Place = {
	Bar: BasePart,
	Pass: BasePart,
	Door: BasePart,
	WaiterSpot: BasePart,
	BarmanSpot: BasePart,
	Seats: { [number]: { BasePart } },
}

local place: Place? = nil
local staff: { Camarero: Player?, Barman: Player? } = {}
local customers: { [number]: Customer } = {}
local orders: { Order } = {}
local carrying: { [Player]: { Order: Order, Part: BasePart } } = {}
local barToken: { [Player]: string } = {}
local nextId = 0
local npcWaiter: Model? = nil
local npcBarman: Model? = nil
local folder: Folder

local function newId(): number
	nextId += 1
	return nextId
end

local function floorOf(part: BasePart): Vector3
	-- Los marcadores están a 2 studs sobre el suelo
	return part.Position - Vector3.new(0, 2, 0)
end

local function isOpen(): boolean
	return staff.Camarero ~= nil or staff.Barman ~= nil
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

---------------------------------------------------------------------
-- Comandas
---------------------------------------------------------------------

local function pendingDishes(): { any }
	local list = {}
	for _, order in orders do
		if not order.Ready then
			for index, dishId in order.Items do
				if not order.Done[index] then
					local dish = Gameplay.dish(dishId)
					table.insert(list, { OrderId = order.Id, Index = index, TableId = order.TableId, Dish = dish and dish.Name or dishId })
				end
			end
		end
	end
	return list
end

-- Ingredientes que ve el barman para un plato: los buenos + otros de relleno, mezclados
local function ingredientOptions(dishId: string): { string }
	local dish = Gameplay.dish(dishId)
	local options = table.clone(dish and dish.Ingredients or {})
	local pool = table.clone(Gameplay.Ingredients)
	while #options < R.IngredientOptions and #pool > 0 do
		local candidate = table.remove(pool, math.random(1, #pool)) :: string
		if not table.find(options, candidate) then
			table.insert(options, candidate)
		end
	end
	for i = #options, 2, -1 do
		local j = math.random(1, i)
		options[i], options[j] = options[j], options[i]
	end
	return options
end

local function sendBar(player: Player, open: boolean)
	local token = barToken[player]
	if not token then
		return
	end
	local dishes = pendingDishes()
	for _, entry in dishes do
		local order = nil
		for _, o in orders do
			if o.Id == entry.OrderId then
				order = o
			end
		end
		entry.Options = if order then ingredientOptions(order.Items[entry.Index]) else {}
	end
	local recipes = {}
	for _, dish in Gameplay.Menu do
		table.insert(recipes, dish.Name .. ": " .. table.concat(dish.Ingredients, ", "))
	end
	Remote:FireClient(player, if open then "Bar" else "BarUpdate", token, dishes, recipes)
end

local function notifyBarman()
	local barman = staff.Barman
	if barman and barToken[barman] then
		sendBar(barman, false)
	end
end

local function placePlate(order: Order)
	if not place or order.Plate then
		return
	end
	local readyCount = 0
	for _, o in orders do
		if o.Ready and o.Plate then
			readyCount += 1
		end
	end
	local plate = Builder.part({
		Name = "Plate_" .. order.Id,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 1.8, 1.8),
		CFrame = place.Pass.CFrame * CFrame.new(-1.2 + (readyCount % 3) * 1.2, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(250, 250, 250),
		CanCollide = false,
		Parent = folder,
	})
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 30)
	gui.StudsOffset = Vector3.new(0, 1.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 40
	gui.Parent = plate
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Text = "🍽 Mesa " .. order.TableId
	label.Parent = gui
	order.Plate = plate
end

local function markPrepared(order: Order, index: number, by: Player?)
	order.Done[index] = true
	if by then
		pay(by, Gameplay.Jobs.Barman.Pay, "plato preparado")
		NeedsService.change(by, 0, -1.5)
		StoryEvents.emit(by, "JobTaskDone", { JobId = "Barman" })
	end
	for _, done in order.Done do
		if not done then
			notifyBarman()
			return
		end
	end
	order.Ready = true
	placePlate(order)
	if staff.Camarero then
		Notify:FireClient(staff.Camarero, "Info", ("🍽 El pedido de la mesa %d está listo en el pase."):format(order.TableId))
	end
	notifyBarman()
end

local function removeOrder(order: Order)
	local index = table.find(orders, order)
	if index then
		table.remove(orders, index)
	end
	if order.Plate then
		order.Plate:Destroy()
		order.Plate = nil
	end
	notifyBarman()
end

---------------------------------------------------------------------
-- Clientes
---------------------------------------------------------------------

local function randomItems(): { string }
	local first = Gameplay.Menu[math.random(1, #Gameplay.Menu)].Id
	if math.random() < 0.6 then
		return { first }
	end
	local second = first
	while second == first do
		second = Gameplay.Menu[math.random(1, #Gameplay.Menu)].Id
	end
	return { first, second }
end

-- Opciones que ve el camarero: la buena y otras parecidas
local function orderOptions(items: { string }): ({ string }, number)
	local correct = Gameplay.orderText(items)
	local options = { correct }
	local tries = 0
	while #options < R.OrderOptions and tries < 50 do
		tries += 1
		local alt = table.clone(items)
		local slot = math.random(1, #alt)
		alt[slot] = Gameplay.Menu[math.random(1, #Gameplay.Menu)].Id
		if #alt == 1 and math.random() < 0.3 then
			table.insert(alt, Gameplay.Menu[math.random(1, #Gameplay.Menu)].Id)
		elseif #alt == 2 and math.random() < 0.3 then
			table.remove(alt, math.random(1, 2))
		end
		local text = Gameplay.orderText(alt)
		if not table.find(options, text) then
			table.insert(options, text)
		end
	end
	for i = #options, 2, -1 do
		local j = math.random(1, i)
		options[i], options[j] = options[j], options[i]
	end
	return options, table.find(options, correct) :: number
end

local function setState(customer: Customer, state: string)
	customer.State = state :: any
	customer.Since = os.clock()
	local model = customer.Model
	local prompt = customer.Prompt
	if state == "WaitingOrder" then
		Npc.icon(model, "✋")
	elseif state == "WaitingFood" then
		Npc.icon(model, "⏳")
	elseif state == "Eating" then
		Npc.icon(model, "😋")
	else
		Npc.icon(model, nil)
	end
	if prompt then
		prompt.Enabled = state == "WaitingOrder" or state == "WaitingFood"
		prompt.ActionText = if state == "WaitingOrder" then "Tomar nota" else "Servir"
	end
end

local function leave(customer: Customer, angry: boolean?)
	if customer.State == "Leaving" then
		return
	end
	setState(customer, "Leaving")
	if customer.Order then
		removeOrder(customer.Order)
		customer.Order = nil
	end
	customer.Seat:SetAttribute("Taken", nil)
	task.spawn(function()
		if angry then
			Npc.icon(customer.Model, "😠")
			Npc.say(customer.Model, "¡Qué lento! Me voy a otro sitio.")
			task.wait(2.5)
		end
		Npc.say(customer.Model, nil)
		if place then
			local door = floorOf(place.Door)
			local seat = customer.Seat
			Npc.stand(customer.Model, Vector3.new(seat.Position.X, door.Y, seat.Position.Z) + seat.CFrame.RightVector * 2)
			local inside = (place.Door.CFrame * CFrame.new(0, -2, 10)).Position
			Npc.walkTo(customer.Model, { inside, door }, 8)
		end
		customer.Model:Destroy()
		customers[customer.Id] = nil
	end)
end

local function speakOrder(customer: Customer)
	Npc.say(customer.Model, "¡Hola! Quiero " .. string.lower(string.sub(Gameplay.orderText(customer.Items), 1, 1)) .. string.sub(Gameplay.orderText(customer.Items), 2) .. ", por favor.")
end

local function sendToBar(customer: Customer)
	local order: Order = { Id = newId(), CustomerId = customer.Id, TableId = customer.TableId, Items = customer.Items, Done = {}, Ready = false }
	for i = 1, #customer.Items do
		order.Done[i] = false
	end
	customer.Order = order
	table.insert(orders, order)
	setState(customer, "WaitingFood")
	local barman = staff.Barman
	if barman then
		Notify:FireClient(barman, "Info", ("🧾 Nueva comanda · Mesa %d: %s"):format(customer.TableId, Gameplay.orderText(customer.Items)))
	end
	notifyBarman()
end

local function serve(customer: Customer, waiter: Player?)
	local order = customer.Order
	if not order then
		return
	end
	local index = table.find(orders, order)
	if index then
		table.remove(orders, index)
	end
	if order.Plate then
		order.Plate:Destroy()
		order.Plate = nil
	end
	customer.Order = nil
	setState(customer, "Eating")
	Npc.say(customer.Model, "¡Gracias! Tiene muy buena pinta.")
	-- Un plato en la mesa mientras come
	local plate = Builder.part({
		Name = "ServedPlate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1.6, 1.6),
		CFrame = customer.Seat.CFrame * CFrame.new(0, 1.3, -2.4) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(250, 250, 250), CanCollide = false, Parent = folder,
	})
	if waiter then
		local waited = os.clock() - customer.Arrived
		local tip = math.max(0, R.MaxTip - customer.Mistakes * 5 - math.floor(waited / 20))
		pay(waiter, Gameplay.Jobs.Camarero.Pay + tip, if tip > 0 then ("mesa servida · propina %s"):format(Format.money(tip)) else "mesa servida")
		NeedsService.change(waiter, 0, -2)
		StoryEvents.emit(waiter, "JobTaskDone", { JobId = "Camarero", Tip = tip })
	end
	task.delay(R.EatSeconds, function()
		plate:Destroy()
		if customers[customer.Id] then
			Npc.say(customer.Model, "¡Estaba buenísimo! Adiós.")
			task.wait(1.5)
			leave(customer)
		end
	end)
end

---------------------------------------------------------------------
-- Camarero: tomar nota y servir
---------------------------------------------------------------------

local function dropCarry(player: Player)
	local carry = carrying[player]
	if carry then
		carry.Part:Destroy()
		carrying[player] = nil
		-- El plato vuelve al pase
		if table.find(orders, carry.Order) then
			placePlate(carry.Order)
		end
	end
end

local function askWaiter(customer: Customer, waiter: Player)
	local options, correct = orderOptions(customer.Items)
	local token = HttpService:GenerateGUID(false)
	customer.Choice = { Token = token, Correct = correct, Waiter = waiter }
	Remote:FireClient(waiter, "TakeOrder", token, options, customer.TableId)
end

local function takeOrder(customer: Customer, waiter: Player)
	if customer.State ~= "WaitingOrder" then
		return
	end
	setState(customer, "Ordering")
	speakOrder(customer)
	task.delay(R.SpeakSeconds, function()
		if customers[customer.Id] and customer.State == "Ordering" then
			Npc.say(customer.Model, nil)
			if staff.Camarero == waiter and waiter.Parent then
				askWaiter(customer, waiter)
			else
				setState(customer, "WaitingOrder")
			end
		end
	end)
end

local function onOrderChoice(player: Player, token: any, choice: any)
	for _, customer in customers do
		local pending = customer.Choice
		if pending and pending.Token == token and pending.Waiter == player then
			customer.Choice = nil
			if customer.State ~= "Ordering" then
				return
			end
			if choice == nil then
				setState(customer, "WaitingOrder")
				return
			end
			if choice == pending.Correct then
				Npc.say(customer.Model, "¡Eso es! Gracias.")
				task.delay(2, function()
					if customers[customer.Id] then
						Npc.say(customer.Model, nil)
					end
				end)
				Notify:FireClient(player, "Success", "📝 Comanda enviada a la barra.")
				sendToBar(customer)
			else
				customer.Mistakes += 1
				Notify:FireClient(player, "Error", "El cliente no ha pedido eso. ¡Escucha otra vez!")
				Npc.say(customer.Model, "No, no… Te lo repito.")
				task.delay(1.5, function()
					if customers[customer.Id] and customer.State == "Ordering" then
						speakOrder(customer)
						task.wait(R.SpeakSeconds)
						if customers[customer.Id] and customer.State == "Ordering" and staff.Camarero == player then
							Npc.say(customer.Model, nil)
							askWaiter(customer, player)
						end
					end
				end)
			end
			return
		end
	end
end

local function onCustomerPrompt(customer: Customer, player: Player)
	if staff.Camarero ~= player then
		Notify:FireClient(player, "Info", "Para atender mesas, trabaja de camarero (tablón de la puerta).")
		return
	end
	if customer.State == "WaitingOrder" then
		takeOrder(customer, player)
	elseif customer.State == "WaitingFood" then
		local carry = carrying[player]
		if not carry then
			Notify:FireClient(player, "Info", "Su pedido aún no está. Recógelo en el pase cuando esté listo.")
		elseif carry.Order.CustomerId ~= customer.Id then
			Notify:FireClient(player, "Error", ("Ese plato es de la mesa %d."):format(carry.Order.TableId))
		else
			carry.Part:Destroy()
			carrying[player] = nil
			serve(customer, player)
		end
	end
end

local function pickUp(player: Player)
	if staff.Camarero ~= player then
		return
	end
	if carrying[player] then
		Notify:FireClient(player, "Info", "Ya llevas un plato. Sírvelo primero.")
		return
	end
	local order: Order? = nil
	for _, o in orders do
		if o.Ready and o.Plate then
			order = o
			break
		end
	end
	if not order then
		Notify:FireClient(player, "Info", "No hay platos listos todavía.")
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if order.Plate then
		order.Plate:Destroy()
		order.Plate = nil
	end
	local part = Instance.new("Part")
	part.Name = "CarriedPlate"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.3, 1.8, 1.8)
	part.Color = Color3.fromRGB(250, 250, 250)
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = root.CFrame * CFrame.new(0, 0.2, -1.6) * CFrame.Angles(0, 0, math.rad(90))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = player.Character
	carrying[player] = { Order = order, Part = part }
	Notify:FireClient(player, "Info", ("Lleva el plato a la mesa %d."):format(order.TableId))
end

---------------------------------------------------------------------
-- Barman
---------------------------------------------------------------------

local function onPrepare(player: Player, token: any, orderId: any, index: any, chosen: any)
	if staff.Barman ~= player or barToken[player] ~= token or typeof(chosen) ~= "table" then
		return
	end
	local order: Order? = nil
	for _, o in orders do
		if o.Id == orderId then
			order = o
		end
	end
	if not order or typeof(index) ~= "number" or order.Done[index] ~= false then
		sendBar(player, false)
		return
	end
	local dish = Gameplay.dish(order.Items[index])
	if not dish then
		return
	end
	local ok = #chosen == #dish.Ingredients
	if ok then
		for _, ingredient in dish.Ingredients do
			if not table.find(chosen, ingredient) then
				ok = false
			end
		end
	end
	if ok then
		Notify:FireClient(player, "Success", "✅ " .. dish.Name .. " preparado.")
		markPrepared(order, index, player)
	else
		for _, customer in customers do
			if customer.Id == order.CustomerId then
				customer.Mistakes += 1
			end
		end
		Notify:FireClient(player, "Error", "❌ Ingredientes incorrectos para " .. dish.Name .. ". ¡Prueba otra vez!")
		sendBar(player, false)
	end
end

---------------------------------------------------------------------
-- Turnos
---------------------------------------------------------------------

local function ensureNpcStaff()
	if not place then
		return
	end
	local open = isOpen()
	if open and not staff.Camarero and not npcWaiter then
		npcWaiter = Npc.create("Npc_Camarero", folder, CFrame.new(floorOf(place.WaiterSpot)), {
			Shirt = Color3.fromRGB(245, 245, 245), Pants = Color3.fromRGB(30, 30, 34),
		})
	elseif (not open or staff.Camarero) and npcWaiter then
		npcWaiter:Destroy()
		npcWaiter = nil
	end
	if open and not staff.Barman and not npcBarman then
		npcBarman = Npc.create("Npc_Barman", folder, place.BarmanSpot.CFrame * CFrame.new(0, -2, 0), {
			Shirt = Color3.fromRGB(30, 30, 34), Pants = Color3.fromRGB(30, 30, 34),
		})
	elseif (not open or staff.Barman) and npcBarman then
		npcBarman:Destroy()
		npcBarman = nil
	end
end

function RestaurantService.quit(player: Player, silent: boolean?)
	local role = nil
	if staff.Camarero == player then
		role = "Camarero"
		staff.Camarero = nil
	elseif staff.Barman == player then
		role = "Barman"
		staff.Barman = nil
	end
	if not role then
		return
	end
	dropCarry(player)
	barToken[player] = nil
	-- Las notas a medias vuelven a esperar
	for _, customer in customers do
		if customer.Choice and customer.Choice.Waiter == player then
			customer.Choice = nil
			setState(customer, "WaitingOrder")
		end
	end
	if player:GetAttribute("Job") == role then
		player:SetAttribute("Job", nil)
		player:SetAttribute("TaskTarget", nil)
		player:SetAttribute("TaskText", nil)
	end
	if not silent then
		Notify:FireClient(player, "Info", "Has dejado el trabajo en el restaurante.")
	end
	ensureNpcStaff()
	if not isOpen() then
		for _, customer in customers do
			leave(customer)
		end
	end
end

local function start(player: Player, role: "Camarero" | "Barman")
	if staff[role] == player then
		RestaurantService.quit(player)
		return
	end
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	if staff[role] then
		Notify:FireClient(player, "Error", "Ese puesto ya lo tiene otro jugador. ¡Prueba el otro!")
		return
	end
	JobService.quit(player, true)
	RestaurantService.quit(player, true)
	staff[role] = player
	player:SetAttribute("Job", role)
	if role == "Camarero" then
		player:SetAttribute("TaskText", "Atiende las mesas con ✋ y lleva los platos del pase.")
		Notify:FireClient(player, "Success", "¡Contratado de camarero! Acércate a los clientes con ✋ para tomar nota.")
	else
		player:SetAttribute("TaskText", "Prepara las comandas en la barra.")
		Notify:FireClient(player, "Success", "¡Contratado de barman! Ponte detrás de la barra para preparar las comandas.")
	end
	ensureNpcStaff()
end

---------------------------------------------------------------------
-- Bucle del restaurante
---------------------------------------------------------------------

local function freeSeat(): (number?, BasePart?)
	if not place then
		return nil, nil
	end
	local free = {}
	for tableId, seats in place.Seats do
		local taken = false
		for _, seat in seats do
			if seat:GetAttribute("Taken") then
				taken = true
			end
		end
		if not taken then
			table.insert(free, tableId)
		end
	end
	if #free == 0 then
		return nil, nil
	end
	local tableId = free[math.random(1, #free)]
	local seats = place.Seats[tableId]
	return tableId, seats[math.random(1, #seats)]
end

local function spawnCustomer()
	local count = 0
	for _ in customers do
		count += 1
	end
	if not place or count >= R.MaxCustomers then
		return
	end
	local tableId, seat = freeSeat()
	if not tableId or not seat then
		return
	end
	seat:SetAttribute("Taken", true)
	local id = newId()
	local door = floorOf(place.Door)
	local model = Npc.create("Cliente_" .. id, folder, CFrame.new(door))
	local customer: Customer = {
		Id = id, TableId = tableId, Seat = seat, Model = model, State = "Arriving",
		Items = randomItems(), Since = os.clock(), Arrived = os.clock(), Mistakes = 0,
	}
	customers[id] = customer
	local prompt = Builder.prompt(model.PrimaryPart :: BasePart, "Tomar nota", "Mesa " .. tableId, 0)
	prompt.MaxActivationDistance = 9
	prompt.Enabled = false
	prompt.Triggered:Connect(function(player)
		onCustomerPrompt(customer, player)
	end)
	customer.Prompt = prompt
	task.spawn(function()
		local inside = (place.Door.CFrame * CFrame.new(0, -2, 10)).Position
		local approach = Vector3.new(seat.Position.X, door.Y, seat.Position.Z) + seat.CFrame.RightVector * 2
		Npc.walkTo(model, { inside, approach }, 8)
		if customers[id] and customer.State == "Arriving" and model.Parent then
			Npc.sit(model, seat)
			setState(customer, "WaitingOrder")
		end
	end)
end

-- Camarero NPC: una tarea cada vez
local npcWaiterBusy = false
local function npcWaiterStep()
	if npcWaiterBusy or not npcWaiter or not place then
		return
	end
	local waiter = npcWaiter
	local target: Customer? = nil
	local readyOrder: Order? = nil
	for _, o in orders do
		if o.Ready and o.Plate then
			readyOrder = o
			break
		end
	end
	if not readyOrder then
		for _, customer in customers do
			if customer.State == "WaitingOrder" then
				target = customer
				break
			end
		end
	end
	if not readyOrder and not target then
		return
	end
	npcWaiterBusy = true
	task.spawn(function()
		local home = floorOf(place.WaiterSpot)
		local function near(seat: BasePart): Vector3
			return Vector3.new(seat.Position.X, home.Y, seat.Position.Z) + seat.CFrame.LookVector * 1.7 + seat.CFrame.RightVector * 2.4
		end
		if readyOrder then
			local customer = customers[readyOrder.CustomerId]
			local pass = place.Pass.Position
			Npc.walkTo(waiter, { Vector3.new(pass.X, home.Y, pass.Z) + place.Pass.CFrame.LookVector * 3 }, 12)
			if customer and customer.Order == readyOrder and waiter.Parent then
				if readyOrder.Plate then
					readyOrder.Plate:Destroy()
					readyOrder.Plate = nil
				end
				Npc.walkTo(waiter, { near(customer.Seat) }, 12)
				if customers[customer.Id] and customer.Order == readyOrder then
					serve(customer, nil)
				end
			end
		elseif target then
			setState(target, "Ordering")
			Npc.walkTo(waiter, { near(target.Seat) }, 12)
			if customers[target.Id] and target.State == "Ordering" then
				speakOrder(target)
				Npc.say(waiter, "Apuntado 📝")
				task.wait(R.NpcWaiterSeconds)
				Npc.say(waiter, nil)
				if customers[target.Id] and target.State == "Ordering" then
					Npc.say(target.Model, nil)
					sendToBar(target)
				end
			end
		end
		if waiter.Parent then
			Npc.walkTo(waiter, { home }, 12)
		end
		npcWaiterBusy = false
	end)
end

-- Barman NPC: prepara el siguiente plato pendiente
local npcBarmanBusy = false
local function npcBarmanStep()
	if npcBarmanBusy or not npcBarman then
		return
	end
	for _, order in orders do
		if not order.Ready then
			for index, done in order.Done do
				if not done then
					npcBarmanBusy = true
					task.spawn(function()
						Npc.say(npcBarman :: Model, "Marchando " .. string.lower((Gameplay.dish(order.Items[index]) or { Name = "" }).Name) .. "…")
						task.wait(R.NpcBarmanSeconds)
						if npcBarman then
							Npc.say(npcBarman, nil)
						end
						if table.find(orders, order) and not order.Done[index] then
							markPrepared(order, index, nil)
						end
						npcBarmanBusy = false
					end)
					return
				end
			end
		end
	end
end

local function updateTargets()
	local waiter = staff.Camarero
	if waiter then
		local target: Vector3? = nil
		local carry = carrying[waiter]
		if carry then
			local customer = customers[carry.Order.CustomerId]
			target = customer and customer.Seat.Position
		else
			for _, o in orders do
				if o.Ready and o.Plate then
					target = o.Plate.Position
					break
				end
			end
			if not target then
				for _, customer in customers do
					if customer.State == "WaitingOrder" then
						target = customer.Seat.Position
						break
					end
				end
			end
		end
		if waiter:GetAttribute("TaskTarget") ~= target then
			waiter:SetAttribute("TaskTarget", target)
		end
	end
	local barman = staff.Barman
	if barman and place then
		local target = if #pendingDishes() > 0 then place.Bar.Position else nil
		if barman:GetAttribute("TaskTarget") ~= target then
			barman:SetAttribute("TaskTarget", target)
		end
	end
end

local function findPlace(): Place?
	local function first(tag: string): BasePart?
		local list = CollectionService:GetTagged(tag)
		return if #list > 0 and list[1]:IsA("BasePart") then list[1] :: BasePart else nil
	end
	local bar, pass, door = first("RestaurantBar"), first("RestaurantPass"), first("RestaurantDoor")
	local waiterSpot, barmanSpot = first("RestaurantWaiterSpot"), first("RestaurantBarmanSpot")
	if not (bar and pass and door and waiterSpot and barmanSpot) then
		warn("[RestaurantService] No se encuentra el restaurante en el mapa")
		return nil
	end
	local seats: { [number]: { BasePart } } = {}
	for _, seat in CollectionService:GetTagged("RestaurantSeat") do
		local tableId = seat:GetAttribute("TableId")
		if seat:IsA("BasePart") and typeof(tableId) == "number" then
			seats[tableId] = seats[tableId] or {}
			table.insert(seats[tableId], seat)
			if seat:IsA("Seat") then
				seat.Disabled = true -- las sillas del restaurante son para los clientes
			end
		end
	end
	return { Bar = bar, Pass = pass, Door = door, WaiterSpot = waiterSpot, BarmanSpot = barmanSpot, Seats = seats }
end

function RestaurantService.init()
	folder = Instance.new("Folder")
	folder.Name = "RestaurantLife"
	folder.Parent = workspace
	place = findPlace()
	if not place then
		return
	end
	local p = place :: Place

	for _, board in CollectionService:GetTagged("RestaurantBoard") do
		if board:IsA("BasePart") then
			local waiterPrompt = Builder.prompt(board, "Camarero (sala)", ("Restaurante · %s/mesa + propinas"):format(Format.money(Gameplay.Jobs.Camarero.Pay)), 0.5)
			waiterPrompt.KeyboardKeyCode = Enum.KeyCode.E
			waiterPrompt.Triggered:Connect(function(player)
				start(player, "Camarero")
			end)
			local barPrompt = Builder.prompt(board, "Barman (barra)", ("Restaurante · %s/plato"):format(Format.money(Gameplay.Jobs.Barman.Pay)), 0.5)
			barPrompt.KeyboardKeyCode = Enum.KeyCode.R
			barPrompt.UIOffset = Vector2.new(0, 58)
			barPrompt.Triggered:Connect(function(player)
				start(player, "Barman")
			end)
		end
	end

	local barPrompt = Builder.prompt(p.Bar, "Preparar comandas", "Barra", 0)
	barPrompt.MaxActivationDistance = 8
	barPrompt.Triggered:Connect(function(player)
		if staff.Barman ~= player then
			Notify:FireClient(player, "Info", "Para preparar comandas, trabaja de barman (tablón de la puerta).")
			return
		end
		barToken[player] = HttpService:GenerateGUID(false)
		sendBar(player, true)
	end)

	local passPrompt = Builder.prompt(p.Pass, "Recoger plato", "Pase", 0)
	passPrompt.MaxActivationDistance = 8
	passPrompt.Triggered:Connect(pickUp)

	Remote.OnServerEvent:Connect(function(player, action, a, b, c, d)
		if action == "OrderChoice" then
			onOrderChoice(player, a, b)
		elseif action == "Prepare" then
			onPrepare(player, a, b, c, d)
		elseif action == "CloseBar" and barToken[player] == a then
			barToken[player] = nil
		end
	end)

	-- "Dejar trabajo" del HUD y cambios de trabajo
	ReplicatedStorage.Remotes.QuitJob.OnServerEvent:Connect(function(player)
		RestaurantService.quit(player)
	end)
	local function watch(player: Player)
		player:GetAttributeChangedSignal("Job"):Connect(function()
			local job = player:GetAttribute("Job")
			if (staff.Camarero == player and job ~= "Camarero") or (staff.Barman == player and job ~= "Barman") then
				RestaurantService.quit(player, true)
			end
		end)
		player.CharacterRemoving:Connect(function()
			dropCarry(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		RestaurantService.quit(player, true)
		carrying[player] = nil
	end)

	-- Llegada de clientes
	task.spawn(function()
		while true do
			task.wait(math.random(R.SpawnEvery[1], R.SpawnEvery[2]))
			if isOpen() then
				spawnCustomer()
			end
		end
	end)

	-- Paciencia, NPC de servicio y línea guía
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, customer in customers do
				local waiting = customer.State == "WaitingOrder" or customer.State == "WaitingFood"
				if waiting and os.clock() - customer.Arrived > R.Patience then
					leave(customer, true)
				end
			end
			npcWaiterStep()
			npcBarmanStep()
			updateTargets()
		end
	end)
end

return RestaurantService
