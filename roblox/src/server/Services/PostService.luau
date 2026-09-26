-- PostService: oficio de repartidor de Correos.
--
--   1) Tablón "Trabajar" de Correos (el mismo que usa la historia) -> te dan una RUTA de paquetes
--      para casas de verdad de Valmar (cada casa tiene su dirección y su buzón: HouseKit).
--   2) En la mesa del escáner "Cargar la ruta": los paquetes van contigo (se ven en tus manos).
--   3) Fuera tienes la moto de reparto (con carnet A) o la bici de reparto.
--   4) Casa por casa (línea azul y panel con las direcciones):
--        cartas y paquetes pequeños -> "Dejar en el buzón"
--        cajas grandes y urgentes   -> "Llamar al timbre": sale el vecino a recogerlo y firma
--      Cobras por cada paquete (más si la casa está lejos). Cada entrega cuenta para la historia
--      (JobTaskDone con JobId "Repartidor").
--   5) Vuelves a Correos y "Cerrar la ruta": bonus (doble si has sido rápido) y ruta nueva.
-- Los carteles de entrega solo los ve el repartidor de esa ruta (atributos JobOnly/OwnerUserId).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local VehicleService = require(script.Parent.VehicleService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local PostService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Post :: RemoteEvent
local P = Gameplay.Post

type Stop = {
	Target: BasePart,
	Address: string,
	Kind: { [string]: any },
	Point: Vector3, -- donde se entrega (buzón o puerta)
	Distance: number,
	Done: boolean,
}
type Office = { Model: Model, Sort: BasePart, Vehicle: BasePart? }
type Route = {
	Player: Player,
	Office: Office,
	Phase: "Load" | "Deliver" | "Return",
	Stops: { Stop },
	Index: number,
	Started: number,
	Prompt: ProximityPrompt?,
	Marker: BasePart?,
	Carry: Model?,
	Busy: boolean,
}

local offices: { Office } = {}
local routes: { [Player]: Route } = {}
local markers: Folder

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nearestOffice(position: Vector3, range: number): Office?
	local best, bestDist = nil, range
	for _, office in offices do
		local d = (office.Sort.Position - position).Magnitude
		if d < bestDist then
			best, bestDist = office, d
		end
	end
	return best
end

---------------------------------------------------------------------
-- Ruta
---------------------------------------------------------------------

local function makeStops(office: Office): { Stop }
	local origin = office.Sort.Position
	local candidates = {}
	for _, part in CollectionService:GetTagged("Buzon") do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local flat = Vector3.new(part.Position.X - origin.X, 0, part.Position.Z - origin.Z).Magnitude
			if flat >= P.MinDistance and flat <= P.MaxDistance then
				table.insert(candidates, part)
			end
		end
	end
	local chosen = {}
	for _ = 1, math.min(P.Parcels, #candidates) do
		local i = math.random(1, #candidates)
		table.insert(chosen, table.remove(candidates, i))
	end
	-- Orden: siempre a la casa más cercana a la anterior (una ruta con sentido)
	local stops: { Stop } = {}
	local at = origin
	while #chosen > 0 do
		local bestI, bestD = 1, math.huge
		for i, part in chosen do
			local d = (part.Position - at).Magnitude
			if d < bestD then
				bestI, bestD = i, d
			end
		end
		local part = table.remove(chosen, bestI)
		local kind = P.Kinds[math.random(1, #P.Kinds)]
		local doorSpot = part:GetAttribute("DoorSpot")
		local door = kind.Door and typeof(doorSpot) == "Vector3"
		table.insert(stops, {
			Target = part,
			Address = part:GetAttribute("Address") or "Sin dirección",
			Kind = kind,
			Point = if door then doorSpot + Vector3.new(0, 2.5, 0) else part.Position,
			Distance = (part.Position - origin).Magnitude,
			Done = false,
			Door = door,
		} :: any)
		at = part.Position
	end
	return stops
end

local function publish(route: Route)
	local player = route.Player
	local list = {}
	for i, stop in route.Stops do
		table.insert(list, { Address = stop.Address, Icon = stop.Kind.Icon, Name = stop.Kind.Name, Done = stop.Done, Current = i == route.Index and route.Phase == "Deliver" })
	end
	Remote:FireClient(player, "Route", { Phase = route.Phase, Stops = list, Elapsed = math.floor(os.clock() - route.Started) })
	if route.Phase == "Load" then
		player:SetAttribute("TaskTarget", route.Office.Sort.Position)
		player:SetAttribute("TaskText", "Carga los paquetes en la mesa del escáner de Correos")
	elseif route.Phase == "Return" then
		player:SetAttribute("TaskTarget", route.Office.Sort.Position)
		player:SetAttribute("TaskText", "Vuelve a Correos y cierra la ruta")
	else
		local stop = route.Stops[route.Index]
		player:SetAttribute("TaskTarget", stop.Point)
		player:SetAttribute("TaskText", ("%s %s · %s"):format(stop.Kind.Icon, stop.Kind.Name, stop.Address))
	end
end

---------------------------------------------------------------------
-- Paquete en las manos
---------------------------------------------------------------------

local function removeCarry(route: Route)
	if route.Carry then
		route.Carry:Destroy()
		route.Carry = nil
	end
end

local function giveCarry(route: Route)
	removeCarry(route)
	local stop = route.Stops[route.Index]
	local character = route.Player.Character
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not stop or not torso then
		return
	end
	local model = Instance.new("Model")
	model.Name = "PostParcel"
	local size = stop.Kind.Size
	local p = Instance.new("Part")
	p.Name = "Parcel"
	p.Size = size
	p.Color = if stop.Kind.Id == "Carta" then Color3.fromRGB(250, 245, 230) elseif stop.Kind.Id == "Urgente" then Color3.fromRGB(230, 60, 50) else Color3.fromRGB(190, 150, 100)
	p.Material = if stop.Kind.Id == "Carta" then Enum.Material.SmoothPlastic else Enum.Material.Cardboard
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = torso.CFrame * CFrame.new(0, -0.3, -torso.Size.Z / 2 - size.Z / 2 - 0.2)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
	if stop.Kind.Id ~= "Carta" then
		local tape = p:Clone()
		tape.Name = "Tape"
		tape.Size = Vector3.new(size.X + 0.02, 0.08, size.Z * 0.25)
		tape.Color = Color3.fromRGB(250, 200, 30)
		tape.Material = Enum.Material.SmoothPlastic
		tape.CFrame = p.CFrame * CFrame.new(0, size.Y / 2, 0)
		tape:FindFirstChildOfClass("WeldConstraint"):Destroy()
		local w = Instance.new("WeldConstraint")
		w.Part0 = p
		w.Part1 = tape
		w.Parent = tape
		tape.Parent = model
	end
	model.Parent = character
	route.Carry = model
end

---------------------------------------------------------------------
-- Entregar
---------------------------------------------------------------------

local deliver -- se define más abajo

local function clearStopPrompt(route: Route)
	if route.Prompt then
		route.Prompt:Destroy()
		route.Prompt = nil
	end
	if route.Marker then
		route.Marker:Destroy()
		route.Marker = nil
	end
end

local function setStopPrompt(route: Route)
	clearStopPrompt(route)
	local stop: any = route.Stops[route.Index]
	if not stop then
		return
	end
	local parent: BasePart = stop.Target
	if stop.Door then
		-- Punto invisible delante de la puerta de la casa
		local marker = Instance.new("Part")
		marker.Name = "PostDoor"
		marker.Size = Vector3.new(2, 5, 2)
		marker.CFrame = CFrame.new(stop.Point)
		marker.Transparency = 1
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.CanTouch = false
		marker.Parent = markers
		route.Marker = marker
		parent = marker
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = if stop.Door then "Llamar al timbre" else "Dejar en el buzón"
	prompt.ObjectText = ("%s %s"):format(stop.Kind.Icon, stop.Address)
	prompt.HoldDuration = if stop.Door then 0.6 else 0.8
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("JobOnly", "Repartidor")
	prompt:SetAttribute("OwnerUserId", route.Player.UserId)
	prompt.Parent = parent
	prompt.Triggered:Connect(function(player)
		if player == route.Player and routes[player] == route then
			deliver(route)
		end
	end)
	route.Prompt = prompt
end

local THANKS = { "¡Por fin! Lo estaba esperando. ¡Gracias!", "¡Qué rapidez! Firmo aquí, ¿no?", "Gracias, majo. ¡Que vaya bien la ruta!", "¡Anda, mi pedido! Muchas gracias." }

function deliver(route: Route)
	local stop: any = route.Stops[route.Index]
	if route.Phase ~= "Deliver" or not stop or route.Busy then
		return
	end
	route.Busy = true
	local player = route.Player
	if stop.Door then
		-- Sale el vecino a recogerlo
		local feet = stop.Point - Vector3.new(0, 2.5, 0)
		local root = rootOf(player)
		local look = if root then Vector3.new(root.Position.X, feet.Y, root.Position.Z) else feet + Vector3.new(0, 0, -1)
		local cf = if (look - feet).Magnitude > 0.1 then CFrame.lookAt(feet, look) else CFrame.new(feet)
		local ok, npc = pcall(Npc.create, "Vecino", markers, cf, nil)
		if ok and npc then
			Npc.say(npc, THANKS[math.random(1, #THANKS)])
			task.delay(4, function()
				npc:Destroy()
			end)
		end
		task.wait(1.2)
		if routes[player] ~= route then
			return
		end
	end
	route.Busy = false
	stop.Done = true
	clearStopPrompt(route)
	removeCarry(route)
	local pay = math.floor((P.PerParcel + stop.Distance * P.PerStud) * MonetizationService.payMultiplier(player))
	DataService.addMoney(player, pay, true)
	local data = DataService.get(player)
	if data then
		data.Stats.TasksDone += 1
	end
	NeedsService.change(player, 0, -P.EnergyCost)
	Notify:FireClient(player, "Money", ("+%s · %s entregado en %s"):format(Format.money(pay), stop.Kind.Name, stop.Address))
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Repartidor", Pay = pay })
	if not NeedsService.canWork(player) then
		PostService.quit(player, true)
		Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
		return
	end
	route.Index += 1
	if route.Index > #route.Stops then
		route.Phase = "Return"
		Notify:FireClient(player, "Success", "¡Ruta repartida! Vuelve a Correos para cerrarla.")
	else
		setStopPrompt(route)
		giveCarry(route)
	end
	publish(route)
end

---------------------------------------------------------------------
-- Mesa del escáner: cargar y cerrar la ruta
---------------------------------------------------------------------

local function newRoute(route: Route)
	route.Stops = makeStops(route.Office)
	route.Index = 1
	route.Phase = "Load"
	route.Started = os.clock()
end

local function onSort(player: Player, office: Office)
	local route = routes[player]
	if not route then
		Notify:FireClient(player, "Info", "Para repartir, apúntate en el tablón «Trabajar» de la puerta.")
		return
	end
	if route.Phase == "Load" then
		if #route.Stops == 0 then
			Notify:FireClient(player, "Error", "Hoy no hay paquetes para esta zona. Prueba más tarde.")
			return
		end
		route.Office = office
		route.Phase = "Deliver"
		route.Started = os.clock()
		setStopPrompt(route)
		giveCarry(route)
		Notify:FireClient(player, "Success", ("📦 %d paquetes cargados. ¡A repartir! Fuera tienes la moto o la bici de reparto."):format(#route.Stops))
	elseif route.Phase == "Return" then
		local fast = os.clock() - route.Started <= P.RouteSeconds
		local bonus = math.floor(P.RouteBonus * (if fast then 2 else 1) * MonetizationService.payMultiplier(player))
		DataService.addMoney(player, bonus, true)
		Notify:FireClient(player, "Money", ("+%s · ruta cerrada%s"):format(Format.money(bonus), if fast then " (¡bonus por rapidez!)" else ""))
		newRoute(route)
		Notify:FireClient(player, "Info", "Tienes otra ruta preparada: pulsa en la mesa para cargarla.")
	else
		local left = #route.Stops - route.Index + 1
		Notify:FireClient(player, "Info", ("Aún te quedan %d paquetes por entregar."):format(left))
	end
	publish(route)
end

local function onVehicle(player: Player, kind: string)
	if not routes[player] then
		Notify:FireClient(player, "Info", "Los vehículos de reparto son para los repartidores de Correos.")
		return
	end
	if not VehicleService.mount(player, kind, { Rented = true }) and kind == "Moto" then
		Notify:FireClient(player, "Info", "Para la moto hace falta el carnet A. Coge la bici de reparto.")
	end
end

---------------------------------------------------------------------
-- Empezar y dejar el turno
---------------------------------------------------------------------

function PostService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	local root = rootOf(player)
	local office = root and nearestOffice(root.Position, 120)
	if not office then
		return
	end
	JobService.quit(player, true)
	local route: Route = { Player = player, Office = office, Phase = "Load", Stops = {}, Index = 1, Started = os.clock(), Busy = false }
	newRoute(route)
	routes[player] = route
	RoleService.setOnDuty(player, "Repartidor")
	player:SetAttribute("Job", "Repartidor")
	Remote:FireClient(player, "Start")
	Notify:FireClient(player, "Success", "¡Contratado como repartidor! Carga los paquetes en la mesa del escáner.")
	publish(route)
end

function PostService.quit(player: Player, silent: boolean?)
	local route = routes[player]
	if not route then
		return
	end
	routes[player] = nil
	clearStopPrompt(route)
	removeCarry(route)
	RoleService.offDuty(player, "Repartidor")
	if player:GetAttribute("Job") == "Repartidor" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has dejado el trabajo de repartidor.")
	end
end

---------------------------------------------------------------------

local function jobPrompt(parent: BasePart, action: string, object: string, hold: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	p:SetAttribute("JobOnly", "Repartidor")
	p.Parent = parent
	return p
end

local function setupOffice(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for _, o in offices do
		if o.Model == model then
			return
		end
	end
	local sort, vehicle
	for _, d in model:GetDescendants() do
		if d:HasTag("PostSort") then
			sort = d
		elseif d:HasTag("PostVehicle") then
			vehicle = d
		end
	end
	if not sort then
		return
	end
	local office: Office = { Model = model, Sort = sort, Vehicle = vehicle }
	table.insert(offices, office)
	jobPrompt(sort, "Cargar / cerrar la ruta", "📦 Mesa del escáner", 1).Triggered:Connect(function(player)
		onSort(player, office)
	end)
	if vehicle then
		local moto = jobPrompt(vehicle, "Moto de reparto", "🛵 Correos (carnet A)", 0.3)
		moto.KeyboardKeyCode = Enum.KeyCode.E
		moto.Triggered:Connect(function(player)
			onVehicle(player, "Moto")
		end)
		local bike = jobPrompt(vehicle, "Bici de reparto", "🚲 Correos", 0.3)
		bike.KeyboardKeyCode = Enum.KeyCode.R
		bike.UIOffset = Vector2.new(0, 58)
		bike.Triggered:Connect(function(player)
			onVehicle(player, "Bici")
		end)
	end
end

function PostService.init()
	markers = Instance.new("Folder")
	markers.Name = "PostMarkers"
	markers.Parent = workspace
	for _, model in CollectionService:GetTagged("PostOffice") do
		setupOffice(model)
	end
	CollectionService:GetInstanceAddedSignal("PostOffice"):Connect(setupOffice)
	JobService.setHandler("Repartidor", { Start = PostService.start, Quit = PostService.quit })
	Players.PlayerRemoving:Connect(function(player)
		PostService.quit(player, true)
	end)
	-- Si reaparece (muere o se reinicia), vuelve a llevar el paquete en las manos
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local route = routes[player]
			if route and route.Phase == "Deliver" then
				task.wait(1)
				giveCarry(route)
			end
		end)
	end)
	-- El panel enseña el tiempo de la ruta
	task.spawn(function()
		while true do
			task.wait(5)
			for _, route in routes do
				publish(route)
			end
		end
	end)
end

return PostService
