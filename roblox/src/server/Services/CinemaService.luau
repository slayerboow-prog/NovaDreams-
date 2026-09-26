-- CinemaService: los cines funcionan (sesiones de verdad y oficio de taquillero/a).
--
-- IR AL CINE (cualquier jugador)
--   * En la TAQUILLA "Comprar entradas": eliges cuántas y, si quieres, palomitas, refresco o nachos.
--     Te lo prepara el taquillero (un jugador o, si no hay, uno NPC). Todo va a la mochila.
--   * En la puerta de la SALA, con tu entrada, "Entrar a la sala" (se gasta una). Te sientas en una
--     butaca y ves la película en la pantalla. Las sesiones son iguales para todos (Cinema.session).
--
-- TAQUILLERO/A (tablón "Trabajar" junto al cine)
--   * Los pedidos salen en tu panel: imprime las entradas eligiendo la película y cuántas (tienen que
--     ser las que pide el cliente), sirve lo de la barra en su máquina y "Entregar pedido" en la taquilla.
--   * Cobras por cliente, por entrada y por cada cosa de la barra. Cuenta para la historia
--     (JobTaskDone con JobId "Taquillero").
-- Clientes NPC: hacen cola, piden, recogen, entran a la sala, se sientan a ver la película y se van.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cinema = require(ReplicatedStorage.Shared.Cinema)
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

local CinemaService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Cinema :: RemoteEvent
local JOB = Cinema.Job

local ACTIVE_RANGE = 240
local MAX_TICKETS = 4

type Order = {
	Id: number,
	Name: string,
	Film: string,
	Tickets: number,
	Snacks: { string },
	Served: { [number]: boolean },
	Printed: boolean,
	Created: number,
	Player: Player?,
	Customer: any?,
}
type Hall = {
	Model: Model,
	Register: BasePart,
	Door: BasePart,
	Exit: BasePart?,
	Stations: { [string]: BasePart },
	Seats: { BasePart },
	Taken: { [BasePart]: boolean },
	Staff: Player?,
	NpcStaff: Model?,
	NpcBusy: boolean,
	Orders: { Order },
	Queue: { any },
	Customers: { any },
	Folder: Folder,
	LastSpawn: number,
	LastPhase: string,
}

local halls: { Hall } = {}
local staffOf: { [Player]: Hall } = {}
local nextOrder = 0

local function now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and t then t else os.clock()
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isOpen(): boolean
	local clock = Lighting.ClockTime
	return clock >= 10 or clock < 1
end

local function point(hall: Hall, name: string): Vector3
	return hall.Model:GetAttribute(name) :: Vector3
end

local function hallNear(position: Vector3, range: number): Hall?
	local best, bestDist = nil, range
	for _, hall in halls do
		local d = (hall.Register.Position - position).Magnitude
		if d < bestDist then
			best, bestDist = hall, d
		end
	end
	return best
end

local function orderText(order: Order): string
	local film = Cinema.byId[order.Film]
	local parts = { ("%d %s para «%s»"):format(order.Tickets, if order.Tickets == 1 then "entrada" else "entradas", film.Title) }
	for _, id in order.Snacks do
		table.insert(parts, string.lower(Cinema.snackById[id].Name))
	end
	if #parts == 1 then
		return parts[1]
	end
	return table.concat(parts, ", ", 1, #parts - 1) .. " y " .. parts[#parts]
end

---------------------------------------------------------------------
-- Panel del taquillero
---------------------------------------------------------------------

local function currentOrder(hall: Hall): Order?
	return hall.Orders[1]
end

local function orderDone(order: Order): boolean
	if not order.Printed then
		return false
	end
	for i in order.Snacks do
		if not order.Served[i] then
			return false
		end
	end
	return true
end

local function publish(hall: Hall)
	local player = hall.Staff
	if not player then
		return
	end
	local list = {}
	for i, order in hall.Orders do
		if i > 5 then
			break
		end
		local snacks = {}
		for k, id in order.Snacks do
			local s = Cinema.snackById[id]
			table.insert(snacks, { Name = s.Name, Icon = s.Icon, Done = order.Served[k] == true })
		end
		table.insert(list, { Id = order.Id, Name = order.Name, Text = orderText(order), Printed = order.Printed, Snacks = snacks, Wait = math.floor(os.clock() - order.Created) })
	end
	local films = {}
	for _, f in Cinema.Films do
		table.insert(films, { Id = f.Id, Title = f.Title, Icon = f.Icon })
	end
	Remote:FireClient(player, "Work", list, films)
	local order = currentOrder(hall)
	if not order then
		player:SetAttribute("TaskTarget", hall.Register.Position)
		player:SetAttribute("TaskText", "Espera a los clientes en la taquilla")
	elseif not order.Printed then
		player:SetAttribute("TaskTarget", hall.Register.Position)
		player:SetAttribute("TaskText", "Imprime las entradas de " .. order.Name .. " (panel)")
	else
		local nextSnack = nil
		for k, id in order.Snacks do
			if not order.Served[k] then
				nextSnack = id
				break
			end
		end
		if nextSnack then
			local station = hall.Stations[Cinema.snackById[nextSnack].Station]
			player:SetAttribute("TaskTarget", if station then station.Position else hall.Register.Position)
			player:SetAttribute("TaskText", "Sirve: " .. Cinema.snackById[nextSnack].Name)
		else
			player:SetAttribute("TaskTarget", hall.Register.Position)
			player:SetAttribute("TaskText", "Entrega el pedido de " .. order.Name .. " en la taquilla")
		end
	end
end

---------------------------------------------------------------------
-- Entregar
---------------------------------------------------------------------

local function deliver(hall: Hall, order: Order, by: Player?)
	local i = table.find(hall.Orders, order)
	if i then
		table.remove(hall.Orders, i)
	end
	if order.Player and order.Player.Parent then
		local customer = order.Player
		InventoryService.add(customer, Cinema.TicketItem, order.Tickets)
		for _, id in order.Snacks do
			if not InventoryService.add(customer, id, 1) then
				local s = Cinema.snackById[id]
				NeedsService.change(customer, s.Hunger, s.Energy)
			end
		end
		Notify:FireClient(customer, "Success", "🎟️ ¡Aquí tienes! Enseña la entrada en la puerta de la sala.")
	elseif order.Customer then
		order.Customer.Served = true
	end
	if by then
		local pay = math.floor((JOB.PerSale + JOB.PerTicket * order.Tickets + JOB.PerSnack * #order.Snacks) * MonetizationService.payMultiplier(by))
		DataService.addMoney(by, pay, true)
		local data = DataService.get(by)
		if data then
			data.Stats.TasksDone += 1
		end
		NeedsService.change(by, 0, -JOB.EnergyCost)
		Notify:FireClient(by, "Money", ("+%s · pedido de %s"):format(Format.money(pay), order.Name))
		StoryEvents.emit(by, "JobTaskDone", { JobId = "Taquillero", Pay = pay })
		if not NeedsService.canWork(by) then
			CinemaService.quit(by, true)
			Notify:FireClient(by, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
			return
		end
	end
	publish(hall)
end

local function onPrint(player: Player, filmId: any, count: any)
	local hall = staffOf[player]
	local order = hall and currentOrder(hall)
	if not hall or not order or order.Printed then
		return
	end
	if filmId ~= order.Film or count ~= order.Tickets then
		Notify:FireClient(player, "Error", "Eso no es lo que ha pedido: " .. orderText(order) .. ".")
		return
	end
	order.Printed = true
	Notify:FireClient(player, "Success", "🎟️ Entradas impresas." .. (if #order.Snacks > 0 then " Ahora lo de la barra." else ""))
	publish(hall)
end

local function onStation(player: Player, hall: Hall, stationId: string)
	if hall.Staff ~= player then
		return
	end
	local order = currentOrder(hall)
	if not order then
		return
	end
	if not order.Printed then
		Notify:FireClient(player, "Info", "Primero imprime las entradas.")
		return
	end
	for k, id in order.Snacks do
		if not order.Served[k] and Cinema.snackById[id].Station == stationId then
			order.Served[k] = true
			publish(hall)
			return
		end
	end
	Notify:FireClient(player, "Info", "Este pedido no lleva eso.")
end

local function onRegisterStaff(player: Player, hall: Hall)
	local order = currentOrder(hall)
	if not order then
		Notify:FireClient(player, "Info", "No hay nadie en la cola.")
		return
	end
	if not orderDone(order) then
		Notify:FireClient(player, "Info", "Aún falta algo: mira tu panel.")
		return
	end
	deliver(hall, order, player)
end

---------------------------------------------------------------------
-- Comprar (jugadores)
---------------------------------------------------------------------

local function onRegister(player: Player, hall: Hall)
	if hall.Staff == player then
		onRegisterStaff(player, hall)
		return
	end
	local film = Cinema.session(now())
	local snacks = {}
	for _, s in Cinema.Snacks do
		table.insert(snacks, { Id = s.Id, Name = s.Name, Icon = s.Icon, Price = s.Price })
	end
	Remote:FireClient(player, "Menu", { Film = film.Id, Title = film.Title, Icon = film.Icon, Price = Cinema.TicketPrice, Snacks = snacks, Staff = if hall.Staff then hall.Staff.DisplayName or hall.Staff.Name else nil })
end

local function onBuy(player: Player, count: any, snacks: any)
	if typeof(count) ~= "number" or count < 1 or count > MAX_TICKETS or count % 1 ~= 0 or typeof(snacks) ~= "table" or #snacks > 3 then
		return
	end
	local root = rootOf(player)
	local hall = root and hallNear(root.Position, 30)
	if not hall then
		return
	end
	local total = Cinema.TicketPrice * count
	local list = {}
	for _, id in snacks do
		local s = typeof(id) == "string" and Cinema.snackById[id]
		if not s then
			return
		end
		table.insert(list, id)
		total += s.Price
	end
	for _, o in hall.Orders do
		if o.Player == player then
			Notify:FireClient(player, "Info", "Ya tienes un pedido en marcha.")
			return
		end
	end
	if not DataService.spend(player, total) then
		Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
		return
	end
	nextOrder += 1
	local film = Cinema.session(now())
	local order: Order = { Id = nextOrder, Name = player.DisplayName or player.Name, Film = film.Id, Tickets = count, Snacks = list, Served = {}, Printed = false, Created = os.clock(), Player = player }
	table.insert(hall.Orders, order)
	Notify:FireClient(player, "Info", ("Pedido: %s (%s). Un momento…"):format(orderText(order), Format.money(total)))
	publish(hall)
end

---------------------------------------------------------------------
-- La sala
---------------------------------------------------------------------

local function onDoor(player: Player, hall: Hall)
	local _, phase = Cinema.session(now())
	if phase == "Break" then
		Notify:FireClient(player, "Info", "Ahora están limpiando la sala. Espera a la próxima sesión.")
		return
	end
	if InventoryService.count(player, Cinema.TicketItem) < 1 then
		Notify:FireClient(player, "Info", "Necesitas una entrada: cómprala en la taquilla.")
		return
	end
	InventoryService.remove(player, Cinema.TicketItem, 1)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(point(hall, "Inside") + Vector3.new(0, 3, 0)))
	end
	Notify:FireClient(player, "Success", "🎬 Busca una butaca y siéntate. ¡Que empieza!")
end

local function onExit(player: Player, hall: Hall)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
		end
		character:PivotTo(CFrame.new(point(hall, "Lobby") + Vector3.new(0, 3, 0)))
	end
end

local function inSala(hall: Hall, position: Vector3): boolean
	local inside, lobby = point(hall, "Inside"), point(hall, "Lobby")
	return (position - inside).Magnitude < (position - lobby).Magnitude and (position - inside).Magnitude < 60
end

---------------------------------------------------------------------
-- Taquillero NPC y clientes NPC
---------------------------------------------------------------------

local function npcWork(hall: Hall)
	if hall.NpcBusy or not hall.NpcStaff or hall.Staff then
		return
	end
	local order = currentOrder(hall)
	if not order then
		return
	end
	hall.NpcBusy = true
	task.delay(3 + #order.Snacks * 1.5, function()
		hall.NpcBusy = false
		if hall.Staff == nil and table.find(hall.Orders, order) then
			deliver(hall, order, nil)
		end
	end)
end

local function refreshStaff(hall: Hall, active: boolean)
	local want = active and isOpen() and not hall.Staff
	if want and not hall.NpcStaff then
		hall.NpcStaff = Npc.create("Npc_Taquillero", hall.Folder, CFrame.new(point(hall, "Staff")), { Shirt = Color3.fromRGB(150, 24, 36), Pants = Color3.fromRGB(24, 22, 30) })
		Npc.face(hall.NpcStaff :: Model, hall.Register.Position - Vector3.new(0, 0, 0))
	elseif not want and hall.NpcStaff then
		hall.NpcStaff:Destroy()
		hall.NpcStaff = nil
		hall.NpcBusy = false
	end
	npcWork(hall)
end

local LINES = { "Hola, %s, por favor.", "¡Buenas! Quería %s.", "Me da %s, ¿vale?" }

local function customerLife(hall: Hall, customer: any)
	local npc = customer.Model
	local function leave(text: string?)
		if text then
			Npc.say(npc, text)
		end
		local i = table.find(hall.Queue, customer)
		if i then
			table.remove(hall.Queue, i)
		end
		if customer.Seat then
			hall.Taken[customer.Seat] = nil
			Npc.stand(npc, nil)
			customer.Seat = nil
			npc:PivotTo(CFrame.new(point(hall, "Lobby") + Vector3.new(0, 3, 0)))
		end
		Npc.walkTo(npc, { point(hall, "Door"), point(hall, "Outside") }, 8)
		local k = table.find(hall.Customers, customer)
		if k then
			table.remove(hall.Customers, k)
		end
		npc:Destroy()
	end
	Npc.walkTo(npc, { point(hall, "Door") }, 8)
	table.insert(hall.Queue, customer)
	local slot, since = 0, os.clock()
	while npc.Parent do
		local i = table.find(hall.Queue, customer) or 1
		if i ~= slot then
			slot = i
			Npc.walkTo(npc, { point(hall, "Queue" .. math.min(i, 4)) }, 7)
			Npc.face(npc, hall.Register.Position)
		end
		if i == 1 then
			break
		end
		if os.clock() - since > 150 then
			return leave("Uf, qué cola… otro día.")
		end
		task.wait(0.5)
	end
	if not npc.Parent then
		return
	end
	nextOrder += 1
	local film = Cinema.session(now())
	local snacks = {}
	if math.random() < 0.6 then
		table.insert(snacks, Cinema.Snacks[math.random(1, #Cinema.Snacks)].Id)
	end
	local order: Order = { Id = nextOrder, Name = customer.Name, Film = film.Id, Tickets = math.random(1, 3), Snacks = snacks, Served = {}, Printed = false, Created = os.clock(), Customer = customer }
	Npc.say(npc, LINES[math.random(1, #LINES)]:format(orderText(order)))
	table.insert(hall.Orders, order)
	publish(hall)
	npcWork(hall)
	local start = os.clock()
	while npc.Parent and not customer.Served do
		if os.clock() - start > 150 then
			local k = table.find(hall.Orders, order)
			if k then
				table.remove(hall.Orders, k)
				publish(hall)
			end
			return leave("Se me va a pasar la sesión… me voy.")
		end
		task.wait(0.5)
	end
	local i = table.find(hall.Queue, customer)
	if i then
		table.remove(hall.Queue, i)
	end
	Npc.say(npc, "¡Gracias!")
	-- A la sala: espera a que abran, entra y busca butaca
	Npc.walkTo(npc, { point(hall, "Lobby") }, 6)
	Npc.say(npc, nil)
	local waited = os.clock()
	while npc.Parent and select(2, Cinema.session(now())) == "Break" and os.clock() - waited < 60 do
		task.wait(1)
	end
	local free = {}
	for _, seat in hall.Seats do
		if not hall.Taken[seat] and not (seat :: any).Occupant then
			table.insert(free, seat)
		end
	end
	if #free == 0 or not npc.Parent then
		return leave(nil)
	end
	local seat = free[math.random(1, #free)]
	hall.Taken[seat] = true
	customer.Seat = seat
	npc:PivotTo(CFrame.new(point(hall, "Inside") + Vector3.new(0, 3, 0)))
	Npc.sit(npc, seat)
	-- Hasta que acabe la película
	local sawFilm = false
	while npc.Parent do
		local _, phase = Cinema.session(now())
		if phase == "Film" then
			sawFilm = true
		elseif sawFilm then
			break
		end
		task.wait(1)
	end
	leave(if math.random() < 0.5 then "¡Qué peliculón!" else "Pues no estaba mal.")
end

local NAMES = { "Nuria", "Iván", "Cristina", "Óscar", "Marina", "Adrián", "Patricia", "Samuel", "Andrea", "Raúl" }

local function spawnCustomer(hall: Hall)
	local model = Npc.create("Espectador", hall.Folder, CFrame.new(point(hall, "Outside")), nil)
	local customer = { Model = model, Name = NAMES[math.random(1, #NAMES)], Served = false }
	table.insert(hall.Customers, customer)
	task.spawn(function()
		local ok, err = pcall(customerLife, hall, customer)
		if not ok then
			warn("[CinemaService] " .. tostring(err))
			if model.Parent then
				model:Destroy()
			end
			local k = table.find(hall.Customers, customer)
			if k then
				table.remove(hall.Customers, k)
			end
		end
	end)
end

local function anyoneNear(hall: Hall): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - hall.Register.Position).Magnitude < ACTIVE_RANGE then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Turno
---------------------------------------------------------------------

function CinemaService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	local root = rootOf(player)
	local hall = root and hallNear(root.Position, 90)
	if not hall then
		return
	end
	if hall.Staff and hall.Staff ~= player then
		Notify:FireClient(player, "Error", "Ya hay alguien en la taquilla. Vuelve más tarde.")
		return
	end
	JobService.quit(player, true)
	hall.Staff = player
	staffOf[player] = hall
	RoleService.setOnDuty(player, "Taquillero")
	player:SetAttribute("Job", "Taquillero")
	refreshStaff(hall, true)
	Remote:FireClient(player, "Start")
	Notify:FireClient(player, "Success", "¡A la taquilla! Los pedidos salen en tu panel.")
	publish(hall)
end

function CinemaService.quit(player: Player, silent: boolean?)
	local hall = staffOf[player]
	if not hall then
		return
	end
	staffOf[player] = nil
	if hall.Staff == player then
		hall.Staff = nil
	end
	RoleService.offDuty(player, "Taquillero")
	if player:GetAttribute("Job") == "Taquillero" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has cerrado la taquilla.")
	end
	refreshStaff(hall, anyoneNear(hall))
end

---------------------------------------------------------------------

local function prompt(parent: BasePart, action: string, object: string, hold: number, staff: boolean?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	if staff then
		p:SetAttribute("JobOnly", "Taquillero")
	end
	p.Parent = parent
	return p
end

local function setupHall(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for _, h in halls do
		if h.Model == model then
			return
		end
	end
	local register, door
	local stations, seats = {}, {}
	for _, d in model:GetDescendants() do
		if d:HasTag("CinemaRegister") then
			register = d
		elseif d:HasTag("CinemaDoor") then
			door = d
		elseif d:HasTag("CinemaStation") then
			stations[d:GetAttribute("Station")] = d
		elseif d:HasTag("CinemaSeat") then
			table.insert(seats, d)
		end
	end
	if not register or not door then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "CinemaLife"
	folder.Parent = model
	local hall: Hall = { Model = model, Register = register, Door = door, Stations = stations, Seats = seats, Taken = {}, Staff = nil, NpcStaff = nil, NpcBusy = false, Orders = {}, Queue = {}, Customers = {}, Folder = folder, LastSpawn = 0, LastPhase = "" }
	table.insert(halls, hall)
	prompt(register, "Comprar entradas", "🎟️ Taquilla", 0.3).Triggered:Connect(function(player)
		onRegister(player, hall)
	end)
	prompt(register, "Entregar pedido", "🎟️ Taquilla", 0.5, true).Triggered:Connect(function(player)
		if hall.Staff == player then
			onRegisterStaff(player, hall)
		end
	end)
	prompt(door, "Entrar a la sala", "🎬 Sala 1 (con entrada)", 0.5).Triggered:Connect(function(player)
		onDoor(player, hall)
	end)
	-- Salida por dentro de la sala
	local exit = Instance.new("Part")
	exit.Name = "SalaExit"
	exit.Size = Vector3.new(4, 5, 1)
	exit.CFrame = CFrame.new(point(hall, "Inside") + Vector3.new(0, 2.5, -1))
	exit.Transparency = 1
	exit.Anchored = true
	exit.CanCollide = false
	exit.Parent = folder
	hall.Exit = exit
	prompt(exit, "Salir de la sala", "🚪 Salida", 0.3).Triggered:Connect(function(player)
		onExit(player, hall)
	end)
	local names = { Palomitas = "Servir palomitas", Refresco = "Servir refresco", Nachos = "Servir nachos" }
	for id, part in stations do
		prompt(part, names[id] or "Servir", "🍿 Barra", 1, true).Triggered:Connect(function(player)
			onStation(player, hall, id)
		end)
	end
end

function CinemaService.init()
	for _, model in CollectionService:GetTagged("Cinema") do
		setupHall(model)
	end
	CollectionService:GetInstanceAddedSignal("Cinema"):Connect(setupHall)
	JobService.setHandler("Taquillero", { Start = CinemaService.start, Quit = CinemaService.quit })
	Remote.OnServerEvent:Connect(function(player, action, a, b)
		if action == "Buy" then
			onBuy(player, a, b)
		elseif action == "Print" then
			onPrint(player, a, b)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		CinemaService.quit(player, true)
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local _, phase = Cinema.session(now())
			for _, hall in halls do
				local ok, err = pcall(function()
					local active = anyoneNear(hall)
					refreshStaff(hall, active)
					if active and isOpen() and #hall.Customers < Cinema.MaxNpc and os.clock() - hall.LastSpawn > math.random(12, 22) then
						hall.LastSpawn = os.clock()
						spawnCustomer(hall)
					end
					-- Al acabar la película, los jugadores que la han visto se llevan su recompensa
					if hall.LastPhase == "Film" and phase == "Break" then
						for _, player in Players:GetPlayers() do
							local root = rootOf(player)
							if root and inSala(hall, root.Position) then
								NeedsService.change(player, 0, 10)
								Notify:FireClient(player, "Success", "🎬 ¡Qué peliculón! Te has despejado un montón.")
								StoryEvents.emit(player, "WatchedMovie", {})
							end
						end
					end
					hall.LastPhase = phase
					if hall.Staff then
						publish(hall)
					end
				end)
				if not ok then
					warn("[CinemaService] " .. tostring(err))
				end
			end
		end
	end)
end

return CinemaService
