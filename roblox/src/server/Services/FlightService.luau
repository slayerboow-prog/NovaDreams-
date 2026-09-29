-- FlightService: los vuelos del Aeropuerto de Valmar (Shared/Airport, World/Kit/Airport).
--
--   * Dos aviones con horario fijo: el avión VLM101 hace la «Vuelta a la isla» (sale y vuelve a
--     Valmar) y la avioneta VLM205 va y viene entre Valmar y la Isla de las Gaviotas.
--   * Cada avión espera en su puerta con el embarque abierto (Airport.Planes[].Board segundos), sale
--     de la puerta, rueda, despega, vuela su ruta, aterriza y rueda hasta la puerta de llegada.
--     El servidor lo coloca en cada momento con Airport.pose (los pasajeros van sentados, soldados a
--     su asiento) y publica el estado en ReplicatedStorage.FlightState.<avión> para que cada cliente
--     lo mueva fluido (Controllers/Flights).
--   * Billetes en los mostradores (FlightCheckIn): los niños vuelan gratis y los adolescentes pagan
--     la mitad. Con el billete, en la puerta (FlightGate) se embarca y te sientas. Al aterrizar se
--     baja en la sala de llegadas (FlightArrival), siempre en suelo firme (Shared/Ground).
--   * Paneles de salidas (FlightBoard) y megafonía en la terminal.
--   * Nadie pilota los aviones: vuelan solos. FlightService.canPilot queda para un futuro oficio de
--     piloto.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Airport = require(ReplicatedStorage.Shared.Airport)
local Ground = require(ReplicatedStorage.Shared.Ground)
local Builder = require(script.Parent.Parent.World.Builder)
local AirportKit = require(script.Parent.Parent.World.Kit.Airport)
local DataService = require(script.Parent.DataService)
local LifeService = require(script.Parent.LifeService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local FlightService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Flight :: RemoteEvent

type Plane = {
	Spec: { [string]: any },
	Model: Model,
	Root: BasePart,
	Seats: { Seat },
	RouteIndex: number,
	Route: Airport.Route,
	Phase: string, -- "Boarding" (en la puerta) | "Flight" (de la puerta de salida a la de llegada)
	Timer: number, -- lo que queda de embarque
	Elapsed: number, -- lo que lleva de vuelo
	T0: number, -- hora del servidor a la que empezó el vuelo (para los clientes)
	LastCall: boolean,
	Passengers: { [Player]: Seat },
	PlaceTimer: number?, -- tiempo desde la última vez que se colocó en vuelo
}

-- En vuelo, el avión se coloca en el servidor solo 5 veces por segundo: cada jugador ya lo mueve en
-- su pantalla, fluido (Controllers/Flights). Al salir, al llegar y en la puerta se coloca exacto.
local PLACE_EVERY = 0.2
local NOBODY: { [Player]: Seat } = table.freeze({}) -- lista vacía (para no crear una en cada fotograma)

local planes: { [string]: Plane } = {}
local riding: { [Player]: Plane } = {}
-- Dónde estaba cada pasajero en el paso anterior del vuelo (para notar un teletransporte)
local lastRoot: { [Player]: Vector3 } = {}
local AWAY = 30 -- a más de esto del asiento (y de golpe), ya no está en el avión
-- Lo que pagó por el billete que lleva (para devolvérselo si lo cambia por otro)
local ticketPaid: { [Player]: number } = {}
-- Quiso comprar otro billete teniendo ya uno: si vuelve a pulsar enseguida, se cambia
local swapAsk: { [Player]: { Route: string, At: number } } = {}
local SWAP_CONFIRM = 10 -- segundos para confirmar el cambio de billete
local stateFolder: Folder? = nil
local LAST_CALL = 15 -- segundos antes de cerrar la puerta: último aviso

function FlightService._now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and typeof(t) == "number" then t else os.clock()
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function tagged(tag: string, attrs: { [string]: any }): BasePart?
	for _, p in CollectionService:GetTagged(tag) do
		if p:IsA("BasePart") then
			local ok = true
			for k, value in attrs do
				if p:GetAttribute(k) ~= value then
					ok = false
					break
				end
			end
			if ok then
				return p
			end
		end
	end
	return nil
end

local function placeName(id: string): string
	local place = Airport.Places[id]
	return if place then place.Name else id
end

local function flightName(plane: Plane, route: Airport.Route?): string
	local r = route or plane.Route
	return ("%s %s → %s"):format(plane.Spec.Id, Airport.Places[r.From].Short, Airport.Places[r.To].Short)
end

---------------------------------------------------------------------
-- Aviones
---------------------------------------------------------------------
local function place(plane: Plane)
	local pose = if plane.Phase == "Flight" then (Airport.pose(plane.Route, plane.Elapsed)) else Airport.parkPose(plane.Route)
	plane.Root.CFrame = Airport.rootCFrame(plane.Spec.Kind, pose)
end

-- Lo que ven los clientes para mover el avión en su pantalla
local function publish(plane: Plane)
	local root = stateFolder
	if not root then
		return
	end
	local f = root:FindFirstChild(plane.Spec.Id)
	if not f then
		f = Instance.new("Folder")
		f.Name = plane.Spec.Id
		f.Parent = root
	end
	f:SetAttribute("Phase", plane.Phase)
	f:SetAttribute("Route", plane.Route.Id)
	f:SetAttribute("T0", plane.T0)
	f:SetAttribute("Kind", plane.Spec.Kind)
	f:SetAttribute("BoardEnd", if plane.Phase == "Boarding" then FlightService._now() + math.max(0, plane.Timer) else 0)
end

-- Segundos hasta que el avión empiece a embarcar en este sitio (0 = embarcando ya)
function FlightService.eta(plane: Plane, where: string): number?
	local routes = plane.Spec.Routes
	local t = 0
	local index = plane.RouteIndex
	if plane.Phase == "Boarding" then
		if plane.Route.From == where then
			return 0
		end
		t = plane.Timer + plane.Route.Total
	else
		t = plane.Route.Total - plane.Elapsed
	end
	for _ = 1, #routes + 1 do
		index = index % #routes + 1
		local route = Airport.Routes[routes[index]]
		if route.From == where then
			return t
		end
		t += plane.Spec.Board + route.Total
	end
	return nil
end

-- Megafonía: a los pasajeros y a quien esté cerca de ese aeropuerto
local function announce(text: string, where: string?, plane: Plane?)
	local center: Vector3? = nil
	if where then
		local spot = tagged("FlightArrival", { Place = where })
		center = spot and spot.Position
	end
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local near = center ~= nil and root ~= nil and (root.Position - center).Magnitude < 450
		if near or (plane and plane.Passengers[player]) then
			Remote:FireClient(player, "Announce", { Text = text })
		end
	end
end

-- Baja al jugador en la sala de llegadas, en suelo firme (cada uno un poco separado)
local function landPlayer(player: Player, where: string, index: number)
	local spot = tagged("FlightArrival", { Place = where })
	local character = player.Character
	if not spot or not character then
		return
	end
	local angle = index * 2.4
	local radius = if index <= 1 then 0 else 2 + (index % 3) * 1.6
	local target = spot.Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local cf = CFrame.new(target)
	local hit = Ground.cast(target + Vector3.new(0, 6, 0), Vector3.new(0, -24, 0))
	if hit then
		cf = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
	end
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 5)
	end)
	character:PivotTo(cf)
end

local function stopRiding(player: Player, plane: Plane)
	local seat = plane.Passengers[player]
	plane.Passengers[player] = nil
	if riding[player] == plane then
		riding[player] = nil
	end
	player:SetAttribute("FlightLanding", nil)
	lastRoot[player] = nil
	local humanoid = humanoidOf(player)
	if humanoid and seat and humanoid.SeatPart == seat then
		humanoid.Sit = false
	end
	if seat then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	if player.Parent then
		Remote:FireClient(player, "Off", { Plane = plane.Spec.Id })
	end
end

local function depart(plane: Plane)
	plane.Phase = "Flight"
	plane.Elapsed = 0
	plane.T0 = FlightService._now()
	plane.LastCall = false
	plane.PlaceTimer = nil -- (el primer paso del vuelo lo coloca ya)
	for player in plane.Passengers do
		Remote:FireClient(player, "Takeoff", { Plane = plane.Spec.Id, Route = plane.Route.Id, T0 = plane.T0 })
	end
	announce(("Tripulación de cabina, puertas en automático. Vuelo %s: ¡buen viaje!"):format(flightName(plane)), nil, plane)
	publish(plane)
end

-- Detenido, en juicio o muerto: ya no va en el avión aunque siga en la lista
local function held(player: Player): boolean
	return player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil or player:GetAttribute("Dead") ~= nil
end

local function arrive(plane: Plane)
	local route = plane.Route
	plane.Elapsed = route.Total
	place(plane)
	-- Todos abajo, en la sala de llegadas
	local index = 0
	for player, seat in table.clone(plane.Passengers) do
		local humanoid = humanoidOf(player)
		local aboard = not held(player) and humanoid ~= nil and humanoid.SeatPart == seat
		stopRiding(player, plane)
		if not aboard then
			continue -- (quien ya no iba a bordo no aterriza ni cuenta el vuelo)
		end
		index += 1
		landPlayer(player, route.To, index)
		Notify:FireClient(player, "Success", ("✈️ Bienvenido/a a %s. ¡Gracias por volar con Valmar Air!"):format(placeName(route.To)))
		StoryEvents.emit(player, "Flew", { Route = route.Id, From = route.From, To = route.To })
	end
	-- Siguiente vuelo del avión: embarque en esta puerta
	plane.RouteIndex = plane.RouteIndex % #plane.Spec.Routes + 1
	plane.Route = Airport.Routes[plane.Spec.Routes[plane.RouteIndex]]
	plane.Phase = "Boarding"
	plane.Timer = plane.Spec.Board
	plane.Elapsed = 0
	place(plane)
	publish(plane)
	announce(("Vuelo %s: embarque abierto. Tengan preparado su billete."):format(flightName(plane)), plane.Route.From)
end

-- ¿El pasajero sigue sentado en su asiento?
local function seated(player: Player, seat: Seat): boolean
	local humanoid = humanoidOf(player)
	return humanoid ~= nil and humanoid.SeatPart == seat and (humanoid.Health or 0) > 0
end

function FlightService._step(plane: Plane, dt: number)
	if plane.Phase == "Boarding" then
		plane.Timer -= dt
		-- Quien se levanta antes de salir, se baja del avión (vuelve a la puerta)
		-- (la copia de la lista solo se hace si hay alguien a quien bajar: casi nunca)
		local anyOff = false
		for player, seat in plane.Passengers do
			if not player.Parent or not seated(player, seat) then
				anyOff = true
				break
			end
		end
		for player, seat in if anyOff then table.clone(plane.Passengers) else NOBODY do
			if not player.Parent or not seated(player, seat) then
				stopRiding(player, plane)
				local gate = tagged("FlightGate", { Plane = plane.Spec.Id, Place = plane.Route.From })
				local character = player.Character
				if gate and character and player.Parent then
					character:PivotTo(gate.CFrame * CFrame.new(0, 0, -4))
					Notify:FireClient(player, "Info", "Has bajado del avión. Si quieres volar, compra otro billete 🎫")
				end
			end
		end
		if not plane.LastCall and plane.Timer <= LAST_CALL then
			plane.LastCall = true
			announce(("Último aviso para el vuelo %s: la puerta %d se cierra."):format(flightName(plane), Airport.Gates[plane.Spec.Kind].Number), plane.Route.From)
		end
		if plane.Timer <= 0 then
			depart(plane)
		end
		return
	end
	plane.Elapsed += dt
	-- En vuelo nadie se levanta: si alguien se ha soltado, vuelve a su asiento
	-- (la copia de la lista solo se hace si hay algo que arreglar: casi nunca)
	-- Si lo han sacado del avión (detenido, cárcel, juicio, la historia lo ha llevado a otro
	-- sitio...), deja el vuelo en vez de volver a sentarlo a la fuerza.
	local anyLoose = false
	local moved: { [Player]: boolean }? = nil
	for player, seat in plane.Passengers do
		local humanoid = humanoidOf(player)
		local root = rootOf(player)
		if root then
			local before = lastRoot[player]
			if before and (root.Position - before).Magnitude > AWAY then
				moved = moved or {}
				;(moved :: { [Player]: boolean })[player] = true
			end
			lastRoot[player] = root.Position
		end
		if not player.Parent or not humanoid or (humanoid.Health or 0) <= 0 or humanoid.SeatPart ~= seat or held(player) then
			anyLoose = true
		end
	end
	for player, seat in if anyLoose then table.clone(plane.Passengers) else NOBODY do
		local humanoid = humanoidOf(player)
		local root = rootOf(player)
		-- Lejos del asiento y de un salto: lo han teletransportado (no se ha levantado sin más)
		local teleported = moved ~= nil and moved[player] == true and root ~= nil and (root.Position - seat.Position).Magnitude > AWAY
		if not player.Parent or not humanoid or (humanoid.Health or 0) <= 0 or held(player) then
			stopRiding(player, plane)
		elseif humanoid.SeatPart ~= seat then
			if teleported then
				stopRiding(player, plane)
			else
				seat:Sit(humanoid)
			end
		end
	end
	if plane.Elapsed >= plane.Route.Total then
		arrive(plane)
	else
		local waited = (plane.PlaceTimer or PLACE_EVERY) + dt
		if waited >= PLACE_EVERY then
			plane.PlaceTimer = 0
			place(plane)
		else
			plane.PlaceTimer = waited
		end
	end
end

---------------------------------------------------------------------
-- Billetes y embarque
---------------------------------------------------------------------
local function freeSeat(plane: Plane): Seat?
	local taken = {}
	for _, seat in plane.Passengers do
		taken[seat] = true
	end
	for _, seat in plane.Seats do
		if not taken[seat] and not seat.Occupant then
			return seat
		end
	end
	return nil
end

local function planeFor(routeId: string): Plane?
	for _, plane in planes do
		for _, id in plane.Spec.Routes do
			if id == routeId then
				return plane
			end
		end
	end
	return nil
end

-- Mostrador: comprar el billete de la próxima salida de esa ruta
function FlightService.buyTicket(player: Player, routeId: string): boolean
	local route = Airport.Routes[routeId]
	local plane = planeFor(routeId)
	if not route or not plane then
		return false
	end
	if not LifeService.allows(player, "Travel") then
		Notify:FireClient(player, "Info", "Los bebés no pueden volar solos 🍼")
		return false
	end
	if player:GetAttribute("FlightTicket") == routeId then
		Notify:FireClient(player, "Info", ("Ya tienes billete para %s. Ve a la puerta %d.\n"):format(route.Name, Airport.Gates[route.Kind].Number))
		return false
	end
	-- Ya lleva billete para otra ruta: no se pisa sin avisar. Si vuelve a pulsar enseguida, se
	-- cambia (y se le devuelve lo que pagó por el otro)
	local held = player:GetAttribute("FlightTicket")
	local swapping = false
	if typeof(held) == "string" and held ~= routeId then
		local ask = swapAsk[player]
		if not ask or ask.Route ~= routeId or os.clock() - ask.At > SWAP_CONFIRM then
			swapAsk[player] = { Route = routeId, At = os.clock() }
			local heldRoute = Airport.Routes[held]
			local heldName = if heldRoute then heldRoute.Name else held
			Notify:FireClient(player, "Info", ("Ya tienes billete para %s: úsalo o vuelve a pulsar para cambiarlo por %s (te devolvemos el anterior)."):format(heldName, route.Name))
			return false
		end
		swapping = true
	end
	swapAsk[player] = nil
	local stage = player:GetAttribute("LifeStage")
	local price = Airport.fare(route, if typeof(stage) == "string" then stage else nil)
	if price > 0 and not DataService.spend(player, price) then
		Notify:FireClient(player, "Info", ("El billete a %s cuesta %d €: no te llega el dinero."):format(route.Name, price))
		return false
	end
	if swapping and (ticketPaid[player] or 0) > 0 then
		DataService.addMoney(player, ticketPaid[player] :: number) -- se devuelve el billete anterior
	end
	ticketPaid[player] = price
	player:SetAttribute("FlightTicket", routeId)
	local eta = FlightService.eta(plane, route.From) or 0
	local when = if eta <= 0 then "¡ya está embarcando!" else "embarca en unos " .. Airport.duration(eta)
	local gate = if route.From == "Valmar" then ("puerta %d"):format(Airport.Gates[route.Kind].Number) else "la puerta de embarque"
	if price <= 0 then
		Notify:FireClient(player, "Success", ("🎫 Billete infantil gratis para %s. Vuelo %s: %s (%s)."):format(route.Name, plane.Spec.Id, when, gate))
	else
		Notify:FireClient(player, "Success", ("🎫 Billete para %s (%d €). Vuelo %s: %s (%s)."):format(route.Name, price, plane.Spec.Id, when, gate))
	end
	StoryEvents.emit(player, "BoughtItem", { ShopId = "Aeropuerto", ItemId = routeId })
	return true
end

-- Puerta de embarque: con billete y el avión embarcando, te sientas en el avión
function FlightService.board(player: Player, planeId: string, where: string): boolean
	local plane = planes[planeId]
	local humanoid = humanoidOf(player)
	if not plane or not humanoid or (humanoid.Health or 0) <= 0 or riding[player] then
		return false
	end
	if plane.Phase ~= "Boarding" or plane.Route.From ~= where then
		local eta = FlightService.eta(plane, where)
		Notify:FireClient(player, "Info", if eta then ("El avión todavía no está en la puerta: el embarque empieza en unos %s ⏳"):format(Airport.duration(eta)) else "Desde aquí no sale ese vuelo.")
		return false
	end
	if player:GetAttribute("FlightTicket") ~= plane.Route.Id then
		Notify:FireClient(player, "Info", ("Necesitas un billete para %s: cómpralo en el mostrador de facturación 🎫"):format(plane.Route.Name))
		return false
	end
	local seat = freeSeat(plane)
	if not seat then
		Notify:FireClient(player, "Info", "El avión va lleno. Espera al siguiente vuelo ✈️")
		return false
	end
	-- (si iba en bici o patinete, se baja antes; require aquí dentro: sin requires en círculo)
	pcall(function()
		require(script.Parent.VehicleService).standUp(player)
	end)
	player:SetAttribute("FlightTicket", nil)
	ticketPaid[player] = nil
	seat:Sit(humanoid)
	plane.Passengers[player] = seat
	riding[player] = plane
	-- (si se sale del juego en pleno vuelo, al volver aparece en la sala de llegadas: PositionService)
	local landing = tagged("FlightArrival", { Place = plane.Route.To })
	player:SetAttribute("FlightLanding", if landing then landing.Position else nil)
	Remote:FireClient(player, "Board", {
		Plane = plane.Spec.Id,
		Kind = plane.Spec.Kind,
		Route = plane.Route.Id,
		Name = plane.Route.Name,
		From = placeName(plane.Route.From),
		To = placeName(plane.Route.To),
		BoardEnd = FlightService._now() + math.max(0, plane.Timer),
	})
	Notify:FireClient(player, "Info", ("✈️ Bienvenido/a a bordo del %s. Salimos en %s."):format(flightName(plane), Airport.duration(plane.Timer)))
	StoryEvents.emit(player, "BoardedFlight", { Route = plane.Route.Id })
	return true
end

-- Bajarse antes de despegar (botón del panel)
local function onLeave(player: Player)
	local plane = riding[player]
	if not plane or plane.Phase ~= "Boarding" then
		return
	end
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.Sit = false
	end
	FlightService._step(plane, 0)
end

-- (futuro oficio de piloto: de momento los aviones vuelan solos)
function FlightService.canPilot(_player: Player, _planeId: string): boolean
	return false
end

---------------------------------------------------------------------
-- Paneles de salidas
---------------------------------------------------------------------
local function statusText(plane: Plane): string
	if plane.Phase == "Boarding" then
		return ("EMBARCANDO · sale en %s"):format(Airport.duration(plane.Timer))
	end
	local _, phase = Airport.pose(plane.Route, plane.Elapsed)
	local left = plane.Route.Total - plane.Elapsed
	if phase == "Retroceso" or phase == "Rodaje" and plane.Elapsed < plane.Route.Total / 2 or phase == "Despegue" then
		return "DESPEGANDO"
	elseif phase == "Aterrizaje" or phase == "Rodaje" then
		return "ATERRIZADO"
	end
	return ("EN VUELO · llega en %s"):format(Airport.duration(left))
end

function FlightService.boardText(): string
	local lines = { "✈  SALIDAS · VALMAR AIR" }
	for _, spec in Airport.Planes do
		local plane = planes[spec.Id]
		if plane then
			local r = plane.Route
			local gate = if r.From == "Valmar" then ("P%d"):format(Airport.Gates[spec.Kind].Number) else "--"
			table.insert(lines, ("%s  %-20s %s  %s"):format(spec.Id, string.upper(Airport.Places[r.From].Short .. " → " .. Airport.Places[r.To].Short), gate, statusText(plane)))
		end
	end
	return table.concat(lines, "\n")
end

local function refreshBoards()
	local text = FlightService.boardText()
	for _, part in CollectionService:GetTagged("FlightBoard") do
		local gui = part:FindFirstChildOfClass("SurfaceGui")
		local label = gui and gui:FindFirstChild("Text")
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
end

---------------------------------------------------------------------

local function setupPlane(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local spec = Airport.planeById(model:GetAttribute("PlaneId") or "")
	if not spec or planes[spec.Id] then
		return
	end
	local root = model:FindFirstChild("Root")
	if not root or not root:IsA("BasePart") then
		return
	end
	if model:GetAttribute("NeedsWeld") then
		-- Soldar todo el avión a su suelo aquí, con las piezas ya en su sitio (Kit/Airport.weldPlane)
		AirportKit.weldPlane(model, root)
	end
	root.Anchored = true
	local seats = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Seat") then
			table.insert(seats, d)
		end
	end
	table.sort(seats, function(a, b)
		return (a:GetAttribute("SeatIndex") or 0) < (b:GetAttribute("SeatIndex") or 0)
	end)
	local plane: Plane = {
		Spec = spec,
		Model = model,
		Root = root,
		Seats = seats,
		RouteIndex = 1,
		Route = Airport.Routes[spec.Routes[1]],
		Phase = "Boarding",
		Timer = spec.Board,
		Elapsed = 0,
		T0 = FlightService._now(),
		LastCall = false,
		Passengers = {},
	}
	planes[spec.Id] = plane
	place(plane)
	publish(plane)
end

local function setupDesk(desk: Instance)
	if not desk:IsA("BasePart") then
		return
	end
	local route = Airport.Routes[desk:GetAttribute("Route") or ""]
	if not route then
		return
	end
	local prompt = Builder.prompt(desk, "Comprar billete", ("✈️ %s · %d € (niños gratis)"):format(route.Name, route.Price), 0.3)
	prompt.MaxActivationDistance = 9
	prompt.Triggered:Connect(function(player)
		FlightService.buyTicket(player, route.Id)
	end)
end

local function setupGate(gate: Instance)
	if not gate:IsA("BasePart") then
		return
	end
	local planeId, where = gate:GetAttribute("Plane"), gate:GetAttribute("Place")
	if typeof(planeId) ~= "string" or typeof(where) ~= "string" then
		return
	end
	local prompt = Builder.prompt(gate, "Embarcar", "✈️ Puerta de embarque · vuelo " .. planeId, 0.3)
	prompt.MaxActivationDistance = 9
	prompt.Triggered:Connect(function(player)
		FlightService.board(player, planeId, where)
	end)
end

function FlightService.init()
	local folder = ReplicatedStorage:FindFirstChild("FlightState")
	if not folder then
		local f = Instance.new("Folder")
		f.Name = "FlightState"
		pcall(function()
			f.Parent = ReplicatedStorage
		end)
		folder = f
	end
	stateFolder = folder :: Folder
	for _, model in CollectionService:GetTagged("Plane") do
		setupPlane(model)
	end
	CollectionService:GetInstanceAddedSignal("Plane"):Connect(setupPlane)
	for _, desk in CollectionService:GetTagged("FlightCheckIn") do
		setupDesk(desk)
	end
	for _, gate in CollectionService:GetTagged("FlightGate") do
		setupGate(gate)
	end
	Remote.OnServerEvent:Connect(function(player, action)
		if action == "Leave" then
			onLeave(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		-- El billete sin usar solo vive en este servidor (un atributo): se le devuelve lo que pagó antes
		-- del guardado de salida, como en la cafetería y el cine (al embarcar ya se borró: no se devuelve)
		local paid = ticketPaid[player]
		if paid and paid > 0 then
			DataService.addMoney(player, paid)
		end
		ticketPaid[player] = nil
		swapAsk[player] = nil
		lastRoot[player] = nil
		local plane = riding[player]
		if plane then
			plane.Passengers[player] = nil
			riding[player] = nil
		end
	end)
	local boardClock = 0
	RunService.Heartbeat:Connect(function(dt)
		for _, plane in planes do
			local ok, err = pcall(FlightService._step, plane, dt)
			if not ok then
				warn("[FlightService] " .. tostring(err))
			end
		end
		boardClock += dt
		if boardClock >= 1 then
			boardClock = 0
			refreshBoards()
		end
	end)
	refreshBoards()
end

-- (para las pruebas)
FlightService._planes = planes
FlightService._riding = riding
FlightService._refreshBoards = refreshBoards

return FlightService
