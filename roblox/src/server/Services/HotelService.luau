-- HotelService: los hoteles funcionan (habitaciones de verdad y oficio de recepcionista).
--
-- DORMIR EN EL HOTEL (cualquier jugador)
--   * En el MOSTRADOR "Reservar habitación": eliges el tipo (individual, doble o suite) y pagas.
--     El recepcionista (un jugador o, si no hay, uno NPC) te da una habitación libre y su llave.
--   * En el ASCENSOR "Subir a tu habitación": con la llave, descansas un rato y recuperas energía.
--     Al bajar dejas la habitación libre (la llave se queda en recepción).
--
-- RECEPCIONISTA (tablón "Trabajar" junto al hotel)
--   * ENTRADAS: el huésped pide un tipo de habitación. En tu panel eliges una habitación LIBRE de ese
--     tipo y le das la llave.
--   * SALIDAS: el huésped devuelve la llave. Buscas SU habitación en el panel y la cobras (queda libre).
--   * Cobras por cada entrada y salida bien hecha, y propina si atiendes rápido. Cuenta para la
--     historia (JobTaskDone con JobId "Recepcionista").
-- Huéspedes NPC: llegan, hacen cola, suben a su habitación, se quedan un rato y bajan a irse.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hotel = require(ReplicatedStorage.Shared.Hotel)
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

local HotelService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Hotel :: RemoteEvent
local JOB = Hotel.Job

local ACTIVE_RANGE = 240
local REST_ENERGY = 45

type Guest = { Name: string, Until: number, Player: Player?, Customer: any?, Leaving: boolean? }
type Request = {
	Id: number,
	Kind: string, -- "In" | "Out"
	Name: string,
	Type: string?, -- lo que pide (entradas)
	Room: number?, -- su habitación (salidas)
	Created: number,
	Player: Player?,
	Customer: any?,
}
type Lobby = {
	Model: Model,
	Desk: BasePart,
	Elevator: BasePart,
	Name: string,
	Rooms: { [number]: Guest },
	Staff: Player?,
	NpcStaff: Model?,
	NpcBusy: boolean,
	Requests: { Request },
	Queue: { any },
	Customers: { any },
	Folder: Folder,
	LastSpawn: number,
}

local lobbies: { Lobby } = {}
local staffOf: { [Player]: Lobby } = {}
local roomOf: { [Player]: { Lobby: Lobby, Room: number } } = {}
local resting: { [Player]: boolean } = {}
local nextId = 0

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function point(lobby: Lobby, name: string): Vector3
	return lobby.Model:GetAttribute(name) :: Vector3
end

local function lobbyNear(position: Vector3, range: number): Lobby?
	local best, bestDist = nil, range
	for _, lobby in lobbies do
		local d = (lobby.Desk.Position - position).Magnitude
		if d < bestDist then
			best, bestDist = lobby, d
		end
	end
	return best
end

local function freeRooms(lobby: Lobby, typeId: string): { number }
	local list = {}
	for _, room in Hotel.typeById[typeId].Rooms do
		if not lobby.Rooms[room] then
			table.insert(list, room)
		end
	end
	return list
end

local function requestText(r: Request): string
	if r.Kind == "In" then
		return ("quiere una habitación %s"):format(string.lower(Hotel.typeById[r.Type :: string].Name))
	end
	return ("se va y devuelve su llave (habitación %d)"):format(r.Room :: number)
end

local function removeRequest(lobby: Lobby, r: Request)
	local i = table.find(lobby.Requests, r)
	if i then
		table.remove(lobby.Requests, i)
	end
end

---------------------------------------------------------------------
-- Panel del recepcionista
---------------------------------------------------------------------

local function publish(lobby: Lobby)
	local player = lobby.Staff
	if not player then
		return
	end
	local list = {}
	for i, r in lobby.Requests do
		if i > 5 then
			break
		end
		table.insert(list, { Id = r.Id, Kind = r.Kind, Name = r.Name, Text = requestText(r), Type = r.Type, Wait = math.floor(os.clock() - r.Created) })
	end
	local rooms = {}
	for _, t in Hotel.Types do
		for _, room in t.Rooms do
			local guest = lobby.Rooms[room]
			-- En el panel sale quién está en cada habitación: en las salidas hay que buscarla por el nombre
			table.insert(rooms, { Room = room, Type = t.Id, Icon = t.Icon, Guest = if guest then guest.Name else nil })
		end
	end
	Remote:FireClient(player, "Work", list, rooms)
	local r = lobby.Requests[1]
	player:SetAttribute("TaskTarget", lobby.Desk.Position)
	if not r then
		player:SetAttribute("TaskText", "Espera a los huéspedes en recepción")
	elseif r.Kind == "In" then
		player:SetAttribute("TaskText", ("Da a %s una habitación %s libre (panel)"):format(r.Name, string.lower(Hotel.typeById[r.Type :: string].Name)))
	else
		player:SetAttribute("TaskText", ("Cobra la salida de %s (panel)"):format(r.Name))
	end
end

---------------------------------------------------------------------
-- Atender
---------------------------------------------------------------------

local function pay(by: Player, amount: number, text: string)
	local total = math.floor(amount * MonetizationService.payMultiplier(by))
	DataService.addMoney(by, total, true)
	local data = DataService.get(by)
	if data then
		data.Stats.TasksDone += 1
	end
	NeedsService.change(by, 0, -JOB.EnergyCost)
	Notify:FireClient(by, "Money", ("+%s · %s"):format(Format.money(total), text))
	StoryEvents.emit(by, "JobTaskDone", { JobId = "Recepcionista", Pay = total })
	if not NeedsService.canWork(by) then
		HotelService.quit(by, true)
		Notify:FireClient(by, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
	end
end

-- Hace la entrada o la salida. `room` ya está comprobada.
local function serve(lobby: Lobby, r: Request, room: number, by: Player?)
	removeRequest(lobby, r)
	local fast = os.clock() - r.Created <= JOB.FastSeconds
	if r.Kind == "In" then
		local stay = math.random(Hotel.StayMin, Hotel.StayMax)
		lobby.Rooms[room] = { Name = r.Name, Until = os.clock() + stay, Player = r.Player, Customer = r.Customer }
		if r.Player and r.Player.Parent then
			InventoryService.add(r.Player, Hotel.KeyItem, 1)
			roomOf[r.Player] = { Lobby = lobby, Room = room }
			Notify:FireClient(r.Player, "Success", ("🔑 Habitación %d. Sube por el ascensor cuando quieras descansar."):format(room))
		elseif r.Customer then
			r.Customer.Room = room
			r.Customer.Served = true
		end
		if by then
			pay(by, JOB.PerCheckIn + (if fast then JOB.Tip else 0), ("entrada de %s (hab. %d)"):format(r.Name, room))
		end
	else
		lobby.Rooms[room] = nil
		if r.Customer then
			r.Customer.Served = true
		end
		if by then
			pay(by, JOB.PerCheckOut + (if fast then JOB.Tip else 0), ("salida de %s (hab. %d)"):format(r.Name, room))
		end
	end
	publish(lobby)
end

local function onAssign(player: Player, room: any)
	local lobby = staffOf[player]
	local r = lobby and lobby.Requests[1]
	if not lobby or not r or typeof(room) ~= "number" or not Hotel.typeOfRoom[room] then
		return
	end
	local root = rootOf(player)
	if root and (root.Position - lobby.Desk.Position).Magnitude > 20 then
		Notify:FireClient(player, "Info", "Vuelve al mostrador para atender.")
		return
	end
	if r.Kind == "In" then
		if Hotel.typeOfRoom[room] ~= r.Type then
			Notify:FireClient(player, "Error", ("Esa no es: %s %s."):format(r.Name, requestText(r)))
			return
		end
		if lobby.Rooms[room] then
			Notify:FireClient(player, "Error", ("La %d está ocupada. Busca una libre."):format(room))
			return
		end
	elseif room ~= r.Room then
		Notify:FireClient(player, "Error", ("Esa no es la habitación de %s. Búscala por su nombre."):format(r.Name))
		return
	end
	serve(lobby, r, room, player)
end

---------------------------------------------------------------------
-- Reservar (jugadores) y descansar
---------------------------------------------------------------------

local function onDesk(player: Player, lobby: Lobby)
	local types = {}
	for _, t in Hotel.Types do
		table.insert(types, { Id = t.Id, Name = t.Name, Icon = t.Icon, Price = t.Price, Free = #freeRooms(lobby, t.Id) })
	end
	Remote:FireClient(player, "Menu", { Hotel = lobby.Name, Types = types, Staff = if lobby.Staff then lobby.Staff.DisplayName or lobby.Staff.Name else nil })
end

local function onBook(player: Player, typeId: any)
	local t = typeof(typeId) == "string" and Hotel.typeById[typeId]
	if not t then
		return
	end
	local root = rootOf(player)
	local lobby = root and lobbyNear(root.Position, 30)
	if not lobby then
		return
	end
	if lobby.Staff == player then
		Notify:FireClient(player, "Info", "Estás trabajando: no puedes reservar ahora.")
		return
	end
	if roomOf[player] or InventoryService.count(player, Hotel.KeyItem) > 0 then
		Notify:FireClient(player, "Info", "Ya tienes una habitación. Sube por el ascensor.")
		return
	end
	for _, r in lobby.Requests do
		if r.Player == player then
			Notify:FireClient(player, "Info", "Ya estás esperando tu llave.")
			return
		end
	end
	if #freeRooms(lobby, t.Id) == 0 then
		Notify:FireClient(player, "Error", "No quedan habitaciones de ese tipo. Prueba otra.")
		return
	end
	if not DataService.spend(player, t.Price) then
		Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
		return
	end
	nextId += 1
	table.insert(lobby.Requests, { Id = nextId, Kind = "In", Name = player.DisplayName or player.Name, Type = t.Id, Created = os.clock(), Player = player })
	Notify:FireClient(player, "Info", ("Habitación %s (%s). Un momento, que te dan la llave…"):format(string.lower(t.Name), Format.money(t.Price)))
	publish(lobby)
end

local function releaseRoom(player: Player)
	local stay = roomOf[player]
	if stay then
		roomOf[player] = nil
		if stay.Lobby.Rooms[stay.Room] and stay.Lobby.Rooms[stay.Room].Player == player then
			stay.Lobby.Rooms[stay.Room] = nil
			publish(stay.Lobby)
		end
	end
end

local function onElevator(player: Player, lobby: Lobby)
	if resting[player] then
		return
	end
	if InventoryService.count(player, Hotel.KeyItem) < 1 then
		Notify:FireClient(player, "Info", "Necesitas la llave de una habitación: resérvala en recepción.")
		return
	end
	InventoryService.remove(player, Hotel.KeyItem, 1)
	local stay = roomOf[player]
	resting[player] = true
	Notify:FireClient(player, "Info", ("🛏️ Subes a la habitación %s y te echas un rato…"):format(if stay then tostring(stay.Room) else ""))
	Remote:FireClient(player, "Rest", Hotel.RestSeconds)
	local root = rootOf(player)
	if root then
		root.Anchored = true
	end
	task.delay(Hotel.RestSeconds, function()
		resting[player] = nil
		if not player.Parent then
			return
		end
		local r = rootOf(player)
		if r then
			r.Anchored = false
		end
		NeedsService.change(player, 0, REST_ENERGY)
		releaseRoom(player)
		local character = player.Character
		if character then
			character:PivotTo(CFrame.new(point(lobby, "Elevator") + Vector3.new(-3, 3, 0)))
		end
		Notify:FireClient(player, "Success", "😴 ¡Como nuevo! Has descansado en el hotel.")
	end)
end

---------------------------------------------------------------------
-- Recepcionista NPC y huéspedes NPC
---------------------------------------------------------------------

local function npcWork(lobby: Lobby)
	if lobby.NpcBusy or not lobby.NpcStaff or lobby.Staff then
		return
	end
	local r = lobby.Requests[1]
	if not r then
		return
	end
	lobby.NpcBusy = true
	task.delay(4, function()
		lobby.NpcBusy = false
		if lobby.Staff ~= nil or not table.find(lobby.Requests, r) then
			return
		end
		local room = r.Room
		if r.Kind == "In" then
			room = freeRooms(lobby, r.Type :: string)[1]
		end
		if room then
			serve(lobby, r, room, nil)
		else
			removeRequest(lobby, r)
		end
		npcWork(lobby)
	end)
end

local function refreshStaff(lobby: Lobby, active: boolean)
	local want = active and not lobby.Staff
	if want and not lobby.NpcStaff then
		lobby.NpcStaff = Npc.create("Npc_Recepcionista", lobby.Folder, CFrame.new(point(lobby, "Staff")), { Shirt = Color3.fromRGB(30, 36, 60), Pants = Color3.fromRGB(24, 24, 30) })
		Npc.face(lobby.NpcStaff :: Model, lobby.Desk.Position)
	elseif not want and lobby.NpcStaff then
		lobby.NpcStaff:Destroy()
		lobby.NpcStaff = nil
		lobby.NpcBusy = false
	end
	npcWork(lobby)
end

local HELLO = { "Buenas, una habitación %s, por favor.", "Hola, tengo reserva: %s.", "¿Les queda alguna %s?" }
local BYE = { "Me voy ya, aquí tiene la llave.", "¡Qué bien he dormido! La cuenta, por favor.", "Dejo la habitación, gracias." }

-- Espera su turno en la cola. Devuelve false si se cansa.
local function waitTurn(lobby: Lobby, customer: any): boolean
	local npc = customer.Model
	table.insert(lobby.Queue, customer)
	local slot, since = 0, os.clock()
	while npc.Parent do
		local i = table.find(lobby.Queue, customer) or 1
		if i ~= slot then
			slot = i
			Npc.walkTo(npc, { point(lobby, "Queue" .. math.min(i, 3)) }, 7)
			Npc.face(npc, lobby.Desk.Position)
		end
		if i == 1 then
			return true
		end
		if os.clock() - since > 150 then
			return false
		end
		task.wait(0.5)
	end
	return false
end

local function leaveQueue(lobby: Lobby, customer: any)
	local i = table.find(lobby.Queue, customer)
	if i then
		table.remove(lobby.Queue, i)
	end
end

-- Espera a que le atiendan. Devuelve false si se cansa.
local function waitServed(lobby: Lobby, customer: any, r: Request): boolean
	local start = os.clock()
	while customer.Model.Parent and not customer.Served do
		if os.clock() - start > 150 then
			removeRequest(lobby, r)
			publish(lobby)
			return false
		end
		task.wait(0.5)
	end
	return customer.Served
end

local function customerLife(lobby: Lobby, customer: any)
	local npc = customer.Model
	local function leave(text: string?)
		if text then
			Npc.say(npc, text)
		end
		leaveQueue(lobby, customer)
		Npc.walkTo(npc, { point(lobby, "Door"), point(lobby, "Outside") }, 8)
		local k = table.find(lobby.Customers, customer)
		if k then
			table.remove(lobby.Customers, k)
		end
		npc:Destroy()
	end
	if not customer.Room then
		Npc.walkTo(npc, { point(lobby, "Door") }, 8)
	end -- (los que se van ya bajan en el ascensor)
	if not waitTurn(lobby, customer) then
		return leave("Uf, qué cola… vuelvo luego.")
	end
	nextId += 1
	local r: Request
	if customer.Room then
		r = { Id = nextId, Kind = "Out", Name = customer.Name, Room = customer.Room, Created = os.clock(), Customer = customer }
		Npc.say(npc, BYE[math.random(1, #BYE)])
	else
		-- Pide un tipo que quede libre
		local options = {}
		for _, t in Hotel.Types do
			if #freeRooms(lobby, t.Id) > 0 then
				table.insert(options, t)
			end
		end
		if #options == 0 then
			return leave("¿Completo? Vaya… otro día.")
		end
		local t = options[math.random(1, #options)]
		r = { Id = nextId, Kind = "In", Name = customer.Name, Type = t.Id, Created = os.clock(), Customer = customer }
		Npc.say(npc, HELLO[math.random(1, #HELLO)]:format(string.lower(t.Name)))
	end
	table.insert(lobby.Requests, r)
	publish(lobby)
	npcWork(lobby)
	if not waitServed(lobby, customer, r) then
		return leave("Tardan mucho… me voy.")
	end
	leaveQueue(lobby, customer)
	if r.Kind == "Out" then
		return leave("¡Hasta la próxima!")
	end
	Npc.say(npc, "¡Gracias!")
	Npc.walkTo(npc, { point(lobby, "Elevator") }, 7)
	-- Sube a su habitación: desaparece hasta que le toque irse (spawnGuests lo baja)
	local k = table.find(lobby.Customers, customer)
	if k then
		table.remove(lobby.Customers, k)
	end
	npc:Destroy()
end

local NAMES = { "Sr. Ortega", "Sra. Vidal", "Familia Ruiz", "Sr. Navarro", "Sra. Castro", "Sr. Molina", "Sra. Iglesias", "Sr. Herrera", "Sra. Garrido", "Sr. Prieto" }

local function spawnCustomer(lobby: Lobby, name: string?, room: number?)
	local start = if room then point(lobby, "Elevator") else point(lobby, "Outside")
	local model = Npc.create(if room then "Huesped" else "Viajero", lobby.Folder, CFrame.new(start), nil)
	local customer = { Model = model, Name = name or NAMES[math.random(1, #NAMES)], Served = false, Room = room }
	table.insert(lobby.Customers, customer)
	task.spawn(function()
		local ok, err = pcall(customerLife, lobby, customer)
		if not ok then
			warn("[HotelService] " .. tostring(err))
			if model.Parent then
				model:Destroy()
			end
			local k = table.find(lobby.Customers, customer)
			if k then
				table.remove(lobby.Customers, k)
			end
		end
	end)
end

local function anyoneNear(lobby: Lobby): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - lobby.Desk.Position).Magnitude < ACTIVE_RANGE then
			return true
		end
	end
	return false
end

-- Huéspedes NPC que ya han terminado su estancia bajan a dejar la llave
local function checkouts(lobby: Lobby)
	for room, guest in lobby.Rooms do
		if guest.Customer and not guest.Leaving and os.clock() >= guest.Until and #lobby.Customers < Hotel.MaxNpc + 1 then
			guest.Leaving = true
			spawnCustomer(lobby, guest.Name, room)
		elseif guest.Player and os.clock() >= guest.Until + 600 then
			-- Un jugador que reservó y nunca subió: se libera
			lobby.Rooms[room] = nil
			if roomOf[guest.Player] and roomOf[guest.Player].Room == room then
				roomOf[guest.Player] = nil
			end
		end
	end
end

---------------------------------------------------------------------
-- Turno
---------------------------------------------------------------------

function HotelService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	local root = rootOf(player)
	local lobby = root and lobbyNear(root.Position, 90)
	if not lobby then
		return
	end
	if lobby.Staff and lobby.Staff ~= player then
		Notify:FireClient(player, "Error", "Ya hay alguien en recepción. Vuelve más tarde.")
		return
	end
	JobService.quit(player, true)
	lobby.Staff = player
	staffOf[player] = lobby
	RoleService.setOnDuty(player, "Recepcionista")
	player:SetAttribute("Job", "Recepcionista")
	refreshStaff(lobby, true)
	Remote:FireClient(player, "Start")
	Notify:FireClient(player, "Success", "¡A recepción! Las entradas y salidas salen en tu panel.")
	publish(lobby)
end

function HotelService.quit(player: Player, silent: boolean?)
	local lobby = staffOf[player]
	if not lobby then
		return
	end
	staffOf[player] = nil
	if lobby.Staff == player then
		lobby.Staff = nil
	end
	RoleService.offDuty(player, "Recepcionista")
	if player:GetAttribute("Job") == "Recepcionista" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado el turno en recepción.")
	end
	refreshStaff(lobby, anyoneNear(lobby))
end

---------------------------------------------------------------------

local function prompt(parent: BasePart, action: string, object: string, hold: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function setupLobby(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for _, l in lobbies do
		if l.Model == model then
			return
		end
	end
	local desk, elevator
	for _, d in model:GetDescendants() do
		if d:HasTag("HotelDesk") then
			desk = d
		elseif d:HasTag("HotelElevator") then
			elevator = d
		end
	end
	if not desk or not elevator then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "HotelLife"
	folder.Parent = model
	local lobby: Lobby = { Model = model, Desk = desk, Elevator = elevator, Name = model:GetAttribute("HotelName") or "Hotel", Rooms = {}, Staff = nil, NpcStaff = nil, NpcBusy = false, Requests = {}, Queue = {}, Customers = {}, Folder = folder, LastSpawn = 0 }
	table.insert(lobbies, lobby)
	-- Algunos huéspedes ya están dentro al empezar (para que haya salidas desde el principio)
	for _ = 1, 3 do
		local t = Hotel.Types[math.random(1, #Hotel.Types)]
		local free = freeRooms(lobby, t.Id)
		if #free > 0 then
			lobby.Rooms[free[math.random(1, #free)]] = { Name = NAMES[math.random(1, #NAMES)], Until = os.clock() + math.random(30, 120), Customer = {} }
		end
	end
	prompt(desk, "Reservar habitación", "🛎️ Recepción", 0.3).Triggered:Connect(function(player)
		if lobby.Staff ~= player then
			onDesk(player, lobby)
		end
	end)
	prompt(elevator, "Subir a tu habitación", "🛗 Ascensor (con llave)", 0.5).Triggered:Connect(function(player)
		onElevator(player, lobby)
	end)
end

function HotelService.init()
	for _, model in CollectionService:GetTagged("HotelLobby") do
		setupLobby(model)
	end
	CollectionService:GetInstanceAddedSignal("HotelLobby"):Connect(setupLobby)
	JobService.setHandler("Recepcionista", { Start = HotelService.start, Quit = HotelService.quit })
	Remote.OnServerEvent:Connect(function(player, action, a)
		if action == "Book" then
			onBook(player, a)
		elseif action == "Assign" then
			onAssign(player, a)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		HotelService.quit(player, true)
		releaseRoom(player)
		resting[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, lobby in lobbies do
				local ok, err = pcall(function()
					local active = anyoneNear(lobby)
					refreshStaff(lobby, active)
					if not active then
						return
					end
					checkouts(lobby)
					if #lobby.Customers < Hotel.MaxNpc and os.clock() - lobby.LastSpawn > math.random(15, 28) then
						lobby.LastSpawn = os.clock()
						spawnCustomer(lobby, nil, nil)
					end
					if lobby.Staff then
						publish(lobby)
					end
				end)
				if not ok then
					warn("[HotelService] " .. tostring(err))
				end
			end
		end
	end)
end

return HotelService
