-- CafeService: las cafeterías funcionan como en la vida real (oficio de barista).
--
-- PEDIR (cualquier jugador)
--   * En la caja registradora ("Pedir") eliges hasta 3 cosas de la carta y pagas.
--   * Te lo prepara el barista (un jugador o, si no hay, un barista NPC) y te lo da en la RECOGIDA.
--     Lo que te sirven va a la mochila (se toma desde ahí).
--
-- TRABAJAR DE BARISTA (tablón "Trabajar" de la puerta; también lo usa la historia)
--   * Los pedidos (de clientes NPC y de jugadores) salen en tu panel, con sus pasos en orden:
--     coger taza, moler, sacar el espresso, echar leche, espumar, chocolate, zumo, té, bollería…
--   * Vas de puesto en puesto (la línea azul te lleva) y pulsas su cartel: cada paso tarda un poco.
--     Lo que preparas se ve en tu bandeja. Si te equivocas de puesto, te avisa.
--   * Cuando está todo, lo entregas en la RECOGIDA: cobras por pedido y por paso, y propina si
--     lo has hecho rápido. Cada pedido cuenta como tarea hecha para la historia (JobTaskDone).
--
-- Clientes NPC: llegan, hacen cola en la caja, piden, esperan en la recogida, se sientan a
-- tomárselo y se van. Si esperan demasiado, se van enfadados.
-- Solo hay vida en las cafeterías con algún jugador cerca.
-- Mapa (Kit/Cafe): modelo con la etiqueta Cafe y dentro CafeStation (+Station), CafeRegister,
-- CafePickup, CafeSeat y CafeMenuBoard.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CafeMenu = require(ReplicatedStorage.Shared.CafeMenu)
local Format = require(ReplicatedStorage.Shared.Format)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local InventoryService = require(script.Parent.InventoryService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local CafeService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Cafe :: RemoteEvent
local JOB = CafeMenu.Job
local STATIONS = CafeMenu.Stations

local ACTIVE_RANGE = 260
local MAX_ITEMS = 3

type Task = { Item: number, Station: string }
type Order = {
	Id: number,
	Name: string, -- quién lo pide
	Items: { string },
	Tasks: { Task },
	Done: number,
	Ready: boolean,
	Created: number,
	Player: Player?, -- cliente jugador
	Customer: any?, -- cliente NPC
	Delivered: boolean,
}
type Cafe = {
	Model: Model,
	Stations: { [string]: BasePart },
	Register: BasePart,
	Pickup: BasePart,
	Seats: { BasePart },
	Taken: { [BasePart]: boolean },
	Board: BasePart?,
	Barista: Player?,
	NpcBarista: Model?,
	NpcBusy: boolean,
	Orders: { Order },
	Queue: { any },
	Customers: { any },
	Folder: Folder,
	LastSpawn: number,
}

local cafes: { Cafe } = {}
local baristaOf: { [Player]: Cafe } = {}
local trays: { [Player]: Model } = {}
local nextOrderId = 0

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isDay(): boolean
	local clock = Lighting.ClockTime
	return clock >= 7 and clock < 22.5
end

local function point(cafe: Cafe, name: string): Vector3
	return cafe.Model:GetAttribute(name) :: Vector3
end

local function cafeNear(position: Vector3, range: number): Cafe?
	local best, bestDist = nil, range
	for _, cafe in cafes do
		local d = (cafe.Register.Position - position).Magnitude
		if d < bestDist then
			best, bestDist = cafe, d
		end
	end
	return best
end

local function productNames(items: { string }): string
	local names = {}
	for _, id in items do
		local p = CafeMenu.byId[id]
		table.insert(names, string.lower(p.Name))
	end
	if #names == 1 then
		return names[1]
	end
	return table.concat(names, ", ", 1, #names - 1) .. " y " .. names[#names]
end

local function makeOrder(name: string, items: { string }): Order
	nextOrderId += 1
	local tasks = {}
	for i, id in items do
		for _, station in CafeMenu.byId[id].Steps do
			table.insert(tasks, { Item = i, Station = station })
		end
	end
	return { Id = nextOrderId, Name = name, Items = items, Tasks = tasks, Done = 0, Ready = false, Created = os.clock(), Delivered = false }
end

---------------------------------------------------------------------
-- Bandeja del barista (se ve lo que va preparando)
---------------------------------------------------------------------

local function removeTray(player: Player)
	if trays[player] then
		trays[player]:Destroy()
		trays[player] = nil
	end
end

local function trayFor(player: Player, order: Order)
	removeTray(player)
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not hand or not torso then
		return
	end
	local model = Instance.new("Model")
	model.Name = "CafeTray"
	local function piece(name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Shape = shape or Enum.PartType.Block
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = cf
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = p
		weld.Parent = p
		p.Parent = model
		return p
	end
	local base = torso.CFrame * CFrame.new(0, -0.6, -1.4)
	piece("Tray", Vector3.new(2.4, 0.12, 1.6), base, Color3.fromRGB(60, 60, 66))
	for i, id in order.Items do
		local product = CafeMenu.byId[id]
		local x = (i - (#order.Items + 1) / 2) * 0.75
		if product.Plate then
			piece("Plate" .. i, Vector3.new(0.1, 0.7, 0.7), base * CFrame.new(x, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.new(1, 1, 1), Enum.PartType.Cylinder)
			local food = piece("Content" .. i, Vector3.new(0.5, 0.25, 0.35), base * CFrame.new(x, 0.25, 0), product.Color)
			food.Transparency = 1
		else
			piece("Cup" .. i, Vector3.new(0.55, 0.5, 0.5), base * CFrame.new(x, 0.33, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.new(1, 1, 1), Enum.PartType.Cylinder)
			local drink = piece("Content" .. i, Vector3.new(0.05, 0.42, 0.42), base * CFrame.new(x, 0.59, 0) * CFrame.Angles(0, 0, math.rad(90)), product.Color, Enum.PartType.Cylinder)
			drink.Transparency = 1
		end
	end
	model.Parent = character
	trays[player] = model
end

-- Enseña en la bandeja lo que ya está hecho de cada producto
local function refreshTray(player: Player, order: Order)
	local tray = trays[player]
	if not tray then
		return
	end
	for i in order.Items do
		local content = tray:FindFirstChild("Content" .. i) :: BasePart?
		if content then
			local started, finished = false, true
			for k, t in order.Tasks do
				if t.Item == i and t.Station ~= "Cup" then
					if k <= order.Done then
						started = true
					else
						finished = false
					end
				end
			end
			content.Transparency = if finished then 0 elseif started then 0.5 else 1
		end
	end
end

---------------------------------------------------------------------
-- Panel del barista
---------------------------------------------------------------------

local function currentOrder(cafe: Cafe): Order?
	for _, order in cafe.Orders do
		if not order.Delivered then
			return order
		end
	end
	return nil
end

local function publish(cafe: Cafe)
	local player = cafe.Barista
	if not player then
		return
	end
	local list = {}
	for _, order in cafe.Orders do
		if not order.Delivered and #list < 6 then
			local items = {}
			for _, id in order.Items do
				local p = CafeMenu.byId[id]
				table.insert(items, { Name = p.Name, Icon = p.Icon })
			end
			local tasks = {}
			for k, t in order.Tasks do
				local s = STATIONS[t.Station]
				table.insert(tasks, { Label = s.Name, Icon = s.Icon, Item = CafeMenu.byId[order.Items[t.Item]].Name, Done = k <= order.Done })
			end
			table.insert(list, { Id = order.Id, Name = order.Name, Items = items, Tasks = tasks, Ready = order.Ready, Wait = math.floor(os.clock() - order.Created) })
		end
	end
	Remote:FireClient(player, "Work", list)
	-- Línea azul: al siguiente puesto (o a la recogida)
	local order = currentOrder(cafe)
	if not order then
		player:SetAttribute("TaskTarget", cafe.Register.Position)
		player:SetAttribute("TaskText", "Espera a los clientes en la barra")
	elseif order.Ready then
		player:SetAttribute("TaskTarget", cafe.Pickup.Position)
		player:SetAttribute("TaskText", ("Entrega el pedido de %s en la recogida"):format(order.Name))
	else
		local t = order.Tasks[order.Done + 1]
		local station = cafe.Stations[t.Station]
		player:SetAttribute("TaskTarget", if station then station.Position else cafe.Register.Position)
		player:SetAttribute("TaskText", ("%s · %s para %s"):format(STATIONS[t.Station].Name, CafeMenu.byId[order.Items[t.Item]].Name, order.Name))
	end
end

---------------------------------------------------------------------
-- Entregar
---------------------------------------------------------------------

local function deliver(cafe: Cafe, order: Order, by: Player?)
	order.Delivered = true
	local i = table.find(cafe.Orders, order)
	if i then
		table.remove(cafe.Orders, i)
	end
	-- Al cliente
	if order.Player and order.Player.Parent then
		local customer = order.Player
		for _, id in order.Items do
			local product = CafeMenu.byId[id]
			if not InventoryService.add(customer, CafeMenu.itemId(id), 1) then
				NeedsService.change(customer, product.Hunger, product.Energy) -- mochila llena: se lo toma ahí mismo
			end
		end
		Notify:FireClient(customer, "Success", ("☕ Tu pedido está listo: %s. Lo tienes en la mochila."):format(productNames(order.Items)))
	elseif order.Customer then
		order.Customer.Served = true
	end
	-- Al barista
	if by then
		local wait = os.clock() - order.Created
		local tip = if wait <= JOB.FastSeconds then JOB.TipFast else 0
		local pay = math.floor((JOB.PerOrder + JOB.PerStep * #order.Tasks + tip) * MonetizationService.payMultiplier(by))
		DataService.addMoney(by, pay, true)
		local data = DataService.get(by)
		if data then
			data.Stats.TasksDone += 1
		end
		NeedsService.change(by, 0, -JOB.EnergyCost)
		Notify:FireClient(by, "Money", ("+%s · pedido de %s%s"):format(Format.money(pay), order.Name, if tip > 0 then " (¡con propina!)" else ""))
		StoryEvents.emit(by, "JobTaskDone", { JobId = "Barista", Pay = pay })
		removeTray(by)
		if not NeedsService.canWork(by) then
			CafeService.quit(by, true)
			Notify:FireClient(by, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
			return
		end
	end
	publish(cafe)
end

---------------------------------------------------------------------
-- Puestos (lo que pulsa el barista)
---------------------------------------------------------------------

local function onStation(player: Player, cafe: Cafe, stationId: string)
	if cafe.Barista ~= player then
		Notify:FireClient(player, "Info", "Esto es para el barista. Si quieres algo, pídelo en la caja.")
		return
	end
	local order = currentOrder(cafe)
	if not order then
		Notify:FireClient(player, "Info", "No hay pedidos ahora mismo. Espera a que llegue alguien.")
		return
	end
	if order.Ready then
		Notify:FireClient(player, "Info", "Este pedido ya está listo: entrégalo en la RECOGIDA.")
		return
	end
	local t = order.Tasks[order.Done + 1]
	if t.Station ~= stationId then
		Notify:FireClient(player, "Error", ("Ahora no toca eso: %s."):format(string.lower(STATIONS[t.Station].Name)))
		return
	end
	if order.Done == 0 or not trays[player] then
		trayFor(player, order)
	end
	order.Done += 1
	if order.Done >= #order.Tasks then
		order.Ready = true
		Notify:FireClient(player, "Success", "¡Listo! Llévalo a la RECOGIDA.")
	end
	refreshTray(player, order)
	publish(cafe)
end

local function onPickup(player: Player, cafe: Cafe)
	if cafe.Barista ~= player then
		Notify:FireClient(player, "Info", "Aquí te dan tu pedido cuando está listo. Si no has pedido, hazlo en la caja.")
		return
	end
	local order = currentOrder(cafe)
	if not order or not order.Ready then
		Notify:FireClient(player, "Info", "Todavía no hay nada listo para entregar.")
		return
	end
	deliver(cafe, order, player)
end

---------------------------------------------------------------------
-- Pedir (jugadores)
---------------------------------------------------------------------

local function onRegister(player: Player, cafe: Cafe)
	if cafe.Barista == player then
		Notify:FireClient(player, "Info", "Estás de barista: los pedidos te salen en el panel.")
		return
	end
	local menu = {}
	for _, p in CafeMenu.List do
		table.insert(menu, { Id = p.Id, Name = p.Name, Icon = p.Icon, Price = p.Price })
	end
	Remote:FireClient(player, "Menu", menu, if cafe.Barista then cafe.Barista.DisplayName or cafe.Barista.Name else nil)
end

local function onOrder(player: Player, items: any)
	if typeof(items) ~= "table" or #items == 0 or #items > MAX_ITEMS then
		return
	end
	local root = rootOf(player)
	local cafe = root and cafeNear(root.Position, 30)
	if not cafe then
		return
	end
	local list, total = {}, 0
	for _, id in items do
		local product = typeof(id) == "string" and CafeMenu.byId[id]
		if not product then
			return
		end
		table.insert(list, id)
		total += product.Price
	end
	for _, order in cafe.Orders do
		if order.Player == player and not order.Delivered then
			Notify:FireClient(player, "Info", "Ya tienes un pedido en marcha: espera en la recogida.")
			return
		end
	end
	if not DataService.spend(player, total) then
		Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
		return
	end
	local order = makeOrder(player.DisplayName or player.Name, list)
	order.Player = player
	table.insert(cafe.Orders, order)
	Notify:FireClient(player, "Info", ("Pedido: %s (%s). Espera en la RECOGIDA."):format(productNames(list), Format.money(total)))
	publish(cafe)
end

---------------------------------------------------------------------
-- Barista NPC (si no hay jugador) y clientes NPC
---------------------------------------------------------------------

local function npcWork(cafe: Cafe)
	if cafe.NpcBusy or not cafe.NpcBarista then
		return
	end
	local order = currentOrder(cafe)
	if not order then
		return
	end
	cafe.NpcBusy = true
	task.spawn(function()
		local npc = cafe.NpcBarista
		while order and not order.Delivered and cafe.NpcBarista == npc and not cafe.Barista do
			if order.Done >= #order.Tasks then
				order.Ready = true
				deliver(cafe, order, nil)
				break
			end
			local t = order.Tasks[order.Done + 1]
			local station = cafe.Stations[t.Station]
			if npc and station then
				Npc.face(npc, station.Position)
			end
			task.wait(CafeMenu.NpcBaristaSeconds * 0.5)
			order.Done += 1
		end
		cafe.NpcBusy = false
	end)
end

local function refreshStaff(cafe: Cafe, active: boolean)
	local want = active and not cafe.Barista and isDay()
	if want and not cafe.NpcBarista then
		cafe.NpcBarista = Npc.create("Npc_Barista", cafe.Folder, CFrame.new(point(cafe, "Staff")), { Shirt = Color3.fromRGB(40, 40, 44), Pants = Color3.fromRGB(40, 40, 46) })
		local apron = cafe.NpcBarista:FindFirstChild("UpperTorso") :: BasePart?
		if apron then
			-- Delantal marrón
			local p = Instance.new("Part")
			p.Name = "Apron"
			p.Size = Vector3.new(apron.Size.X * 0.8, apron.Size.Y * 1.3, 0.1)
			p.Color = Color3.fromRGB(120, 76, 44)
			p.Material = Enum.Material.Fabric
			p.CanCollide = false
			p.Massless = true
			p.CFrame = apron.CFrame * CFrame.new(0, -apron.Size.Y * 0.2, -apron.Size.Z / 2 - 0.05)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = apron
			weld.Part1 = p
			weld.Parent = p
			p.Parent = cafe.NpcBarista
		end
		Npc.face(cafe.NpcBarista :: Model, cafe.Register.Position)
	elseif not want and cafe.NpcBarista then
		cafe.NpcBarista:Destroy()
		cafe.NpcBarista = nil
		cafe.NpcBusy = false
	end
	if cafe.NpcBarista then
		npcWork(cafe)
	end
end

local ORDERS_TEXT = { "¡Buenas! Me pones %s, por favor.", "Hola, quería %s.", "Para mí %s, gracias.", "¿Me pones %s? Para tomar aquí." }

local function customerLife(cafe: Cafe, customer: any)
	local npc = customer.Model
	local function alive(): boolean
		return npc.Parent ~= nil
	end
	local function leave(text: string?)
		if text then
			Npc.say(npc, text)
		end
		local i = table.find(cafe.Queue, customer)
		if i then
			table.remove(cafe.Queue, i)
		end
		if customer.Seat then
			cafe.Taken[customer.Seat] = nil
			Npc.stand(npc, customer.Seat.Position + Vector3.new(0, 0, 0))
			customer.Seat = nil
		end
		Npc.walkTo(npc, { point(cafe, "Door"), point(cafe, "Outside") }, 8)
		local k = table.find(cafe.Customers, customer)
		if k then
			table.remove(cafe.Customers, k)
		end
		npc:Destroy()
	end

	Npc.walkTo(npc, { point(cafe, "Door") }, 8)
	-- Cola de la caja
	table.insert(cafe.Queue, customer)
	local slot = 0
	local since = os.clock()
	while alive() do
		local i = table.find(cafe.Queue, customer) or 1
		if i ~= slot then
			slot = i
			Npc.walkTo(npc, { point(cafe, "Queue" .. math.min(i, 4)) }, 7)
			Npc.face(npc, cafe.Register.Position)
		end
		if i == 1 then
			break
		end
		if os.clock() - since > CafeMenu.Patience then
			return leave("Uf, qué cola… otro día.")
		end
		task.wait(0.5)
	end
	if not alive() then
		return
	end
	-- Pide
	local items = {}
	for _ = 1, if math.random() < 0.35 then 2 else 1 do
		local drinks = math.random() < 0.8
		local pool = {}
		for _, p in CafeMenu.List do
			if (p.Plate == true) ~= drinks then
				table.insert(pool, p.Id)
			end
		end
		table.insert(items, pool[math.random(1, #pool)])
	end
	Npc.say(npc, ORDERS_TEXT[math.random(1, #ORDERS_TEXT)]:format(productNames(items)))
	task.wait(2.5)
	local order = makeOrder(customer.Name, items)
	order.Customer = customer
	table.insert(cafe.Orders, order)
	publish(cafe)
	npcWork(cafe)
	local i = table.find(cafe.Queue, customer)
	if i then
		table.remove(cafe.Queue, i)
	end
	Npc.say(npc, nil)
	-- Espera en la recogida
	local wait = point(cafe, "Wait") + Vector3.new(math.random(-3, 3), 0, math.random(-1, 1))
	Npc.walkTo(npc, { wait }, 6)
	Npc.face(npc, cafe.Pickup.Position)
	local start = os.clock()
	while alive() and not customer.Served do
		if os.clock() - start > CafeMenu.Patience then
			local k = table.find(cafe.Orders, order)
			if k then
				table.remove(cafe.Orders, k)
				publish(cafe)
			end
			return leave("¡Qué lento! Me voy a otro sitio.")
		end
		task.wait(0.5)
	end
	if not alive() then
		return
	end
	Npc.say(npc, if os.clock() - start < JOB.FastSeconds then "¡Qué rápido! Gracias 😊" else "Gracias.")
	-- Se sienta a tomárselo (si hay sitio) o se lo lleva
	local free = {}
	for _, seat in cafe.Seats do
		if not cafe.Taken[seat] then
			table.insert(free, seat)
		end
	end
	if #free > 0 then
		local seat = free[math.random(1, #free)]
		cafe.Taken[seat] = true
		customer.Seat = seat
		Npc.walkTo(npc, { seat.Position + seat.CFrame.LookVector * 1.8 }, 6)
		task.wait(1)
		Npc.say(npc, nil)
		Npc.sit(npc, seat)
		task.wait(math.random(20, 35))
	else
		task.wait(1.5)
	end
	leave(nil)
end

local NAMES = { "Lucía", "Mario", "Carmen", "Javi", "Nerea", "Pablo", "Irene", "Sergio", "Marta", "Álex", "Rosa", "Dani" }

local function spawnCustomer(cafe: Cafe)
	local name = NAMES[math.random(1, #NAMES)]
	local model = Npc.create("Cliente", cafe.Folder, CFrame.new(point(cafe, "Outside")), nil)
	local customer = { Model = model, Name = name, Served = false, Seat = nil }
	table.insert(cafe.Customers, customer)
	task.spawn(function()
		local ok, err = pcall(customerLife, cafe, customer)
		if not ok then
			warn("[CafeService] " .. tostring(err))
			if model.Parent then
				model:Destroy()
			end
			local k = table.find(cafe.Customers, customer)
			if k then
				table.remove(cafe.Customers, k)
			end
		end
	end)
end

local function anyoneNear(cafe: Cafe): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - cafe.Register.Position).Magnitude < ACTIVE_RANGE then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Empezar y dejar el turno
---------------------------------------------------------------------

function CafeService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	local root = rootOf(player)
	local cafe = root and cafeNear(root.Position, 80)
	if not cafe then
		return
	end
	if cafe.Barista and cafe.Barista ~= player then
		Notify:FireClient(player, "Error", ("Ya está %s de barista. Vuelve más tarde."):format(cafe.Barista.DisplayName or cafe.Barista.Name))
		return
	end
	JobService.quit(player, true)
	cafe.Barista = player
	baristaOf[player] = cafe
	RoleService.setOnDuty(player, "Barista")
	player:SetAttribute("Job", "Barista")
	refreshStaff(cafe, true)
	Remote:FireClient(player, "Start", JOB.Text)
	Notify:FireClient(player, "Success", "¡Contratado como barista! Los pedidos salen en tu panel.")
	publish(cafe)
end

function CafeService.quit(player: Player, silent: boolean?)
	local cafe = baristaOf[player]
	if not cafe then
		return
	end
	baristaOf[player] = nil
	if cafe.Barista == player then
		cafe.Barista = nil
	end
	-- Lo que estuviera a medias lo termina el barista NPC (o el siguiente)
	removeTray(player)
	RoleService.offDuty(player, "Barista")
	if player:GetAttribute("Job") == "Barista" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has dejado el trabajo de barista.")
	end
	refreshStaff(cafe, anyoneNear(cafe))
end

---------------------------------------------------------------------

local function prompt(parent: BasePart, action: string, object: string, hold: number?, staff: boolean?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 8
	p.RequiresLineOfSight = false
	if staff then
		p:SetAttribute("CafeStaff", true) -- el cliente solo lo enseña a quien trabaja de barista
	end
	p.Parent = parent
	return p
end

local function menuBoard(board: BasePart)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0.2
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.18, 0)
	title.BackgroundTransparency = 1
	title.Text = "☕ NUESTRA CARTA"
	title.TextScaled = true
	title.Font = Enum.Font.Fondamento
	title.TextColor3 = Color3.fromRGB(250, 240, 210)
	title.Parent = gui
	local half = math.ceil(#CafeMenu.List / 2)
	for i, p in CafeMenu.List do
		local col = if i <= half then 0 else 1
		local row = if i <= half then i - 1 else i - half - 1
		local line = Instance.new("TextLabel")
		line.Size = UDim2.new(0.46, 0, 0.13, 0)
		line.Position = UDim2.new(0.03 + col * 0.5, 0, 0.2 + row * 0.13, 0)
		line.BackgroundTransparency = 1
		line.Text = ("%s %s ........ %s"):format(p.Icon, p.Name, Format.money(p.Price))
		line.TextScaled = true
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Font = Enum.Font.Fondamento
		line.TextColor3 = Color3.fromRGB(240, 240, 235)
		line.Parent = gui
	end
end

local function setupCafe(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for _, c in cafes do
		if c.Model == model then
			return
		end
	end
	local stations, seats = {}, {}
	local register, pickup, board = nil, nil, nil
	for _, d in model:GetDescendants() do
		if d:HasTag("CafeStation") then
			stations[d:GetAttribute("Station")] = d
		elseif d:HasTag("CafeRegister") then
			register = d
		elseif d:HasTag("CafePickup") then
			pickup = d
		elseif d:HasTag("CafeSeat") then
			table.insert(seats, d)
		elseif d:HasTag("CafeMenuBoard") then
			board = d
		end
	end
	if not register or not pickup then
		warn("[CafeService] Cafetería sin caja o sin recogida:", model:GetFullName())
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "CafeLife"
	folder.Parent = model
	local cafe: Cafe = {
		Model = model,
		Stations = stations,
		Register = register,
		Pickup = pickup,
		Seats = seats,
		Taken = {},
		Board = board,
		Barista = nil,
		NpcBarista = nil,
		NpcBusy = false,
		Orders = {},
		Queue = {},
		Customers = {},
		Folder = folder,
		LastSpawn = 0,
	}
	table.insert(cafes, cafe)
	if board then
		menuBoard(board)
	end
	for id, part in stations do
		local s = STATIONS[id]
		if s then
			prompt(part, s.Name, s.Icon .. " " .. s.Object, s.Hold, true).Triggered:Connect(function(player)
				onStation(player, cafe, id)
			end)
		end
	end
	prompt(register, "Pedir", "☕ Caja · la carta").Triggered:Connect(function(player)
		onRegister(player, cafe)
	end)
	prompt(pickup, "Entregar pedido", "🛎️ Recogida", 0.4, true).Triggered:Connect(function(player)
		onPickup(player, cafe)
	end)
end

function CafeService.init()
	for _, model in CollectionService:GetTagged("Cafe") do
		setupCafe(model)
	end
	CollectionService:GetInstanceAddedSignal("Cafe"):Connect(setupCafe)

	JobService.setHandler("Barista", { Start = CafeService.start, Quit = CafeService.quit })

	Remote.OnServerEvent:Connect(function(player, action, payload)
		if action == "Order" then
			onOrder(player, payload)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		CafeService.quit(player, true)
		removeTray(player)
	end)

	-- Vida de cada cafetería: clientes que llegan, barista NPC y panel del barista
	task.spawn(function()
		while true do
			task.wait(1)
			for _, cafe in cafes do
				local ok, err = pcall(function()
					local active = anyoneNear(cafe)
					refreshStaff(cafe, active)
					if active and isDay() and #cafe.Customers < CafeMenu.MaxNpc and os.clock() - cafe.LastSpawn > math.random(10, 18) then
						cafe.LastSpawn = os.clock()
						spawnCustomer(cafe)
					end
					if cafe.Barista then
						publish(cafe) -- actualiza los tiempos de espera
					end
				end)
				if not ok then
					warn("[CafeService] " .. tostring(err))
				end
			end
		end
	end)
end

return CafeService
