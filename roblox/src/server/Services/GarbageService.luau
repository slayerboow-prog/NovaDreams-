-- GarbageService: oficio de basurero (Limpieza Valmar).
--
--   1) Tablón "Trabajar" del Punto Limpio (el mismo de siempre) -> te dan una RUTA de papeleras
--      llenas por las calles (se ven rebosando, con la bolsa asomando).
--   2) Con carnet B coges el CAMIÓN DE LA BASURA en el Punto Limpio; si no, vas a pie.
--   3) En cada papelera "Vaciar papelera". Las bolsas sueltas de la calle también cuentan
--      ("Recoger bolsa"); vuelven a aparecer al cabo de un rato.
--   4) Con la ruta hecha, "Descargar" en los contenedores del Punto Limpio: bonus (doble si has
--      sido rápido) y te dan otra ruta.
-- Cada papelera vaciada cuenta como tarea para la historia (JobTaskDone con JobId "Basurero").
-- Los carteles solo los ve el basurero de esa ruta (JobOnly / OwnerUserId).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local VehicleService = require(script.Parent.VehicleService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local GarbageService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Garbage :: RemoteEvent
local G = Gameplay.Garbage

type Stop = { Bin: BasePart, Done: boolean, Overflow: BasePart?, Prompt: ProximityPrompt? }
type Route = {
	Player: Player,
	Phase: "Collect" | "Unload",
	Stops: { Stop },
	Bags: number,
	Started: number,
	Carry: BasePart?,
}

local routes: { [Player]: Route } = {}
local busyBins: { [BasePart]: boolean } = {} -- papeleras que ya están en la ruta de alguien
local depot: Model?
local unloadPart: BasePart?

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function pay(player: Player, amount: number, what: string)
	local total = math.floor(amount * MonetizationService.payMultiplier(player))
	DataService.addMoney(player, total, true)
	Notify:FireClient(player, "Money", ("+%s · %s"):format(Format.money(total), what))
end

---------------------------------------------------------------------
-- Bolsa en la mano (a pie)
---------------------------------------------------------------------

local function refreshCarry(route: Route)
	local player = route.Player
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	local want = route.Bags > 0 and route.Phase ~= nil and player:GetAttribute("Riding") == nil and hand ~= nil
	if not want then
		if route.Carry then
			route.Carry:Destroy()
			route.Carry = nil
		end
		return
	end
	if route.Carry and route.Carry.Parent == character then
		return
	end
	local bag = Instance.new("Part")
	bag.Name = "GarbageBag"
	bag.Shape = Enum.PartType.Ball
	bag.Size = Vector3.new(1.6, 1.8, 1.6)
	bag.Color = Color3.fromRGB(24, 24, 28)
	bag.Material = Enum.Material.Plastic
	bag.CanCollide = false
	bag.CanQuery = false
	bag.CanTouch = false
	bag.Massless = true
	bag.CFrame = (hand :: BasePart).CFrame * CFrame.new(0, -1.1, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = bag
	weld.Parent = bag
	bag.Parent = character
	route.Carry = bag
end

---------------------------------------------------------------------
-- Ruta
---------------------------------------------------------------------

local function publish(route: Route)
	local player = route.Player
	local left = 0
	local nextStop: Stop? = nil
	local root = rootOf(player)
	local best = math.huge
	for _, stop in route.Stops do
		if not stop.Done then
			left += 1
			local d = if root then (stop.Bin.Position - root.Position).Magnitude else 0
			if d < best then
				best, nextStop = d, stop
			end
		end
	end
	Remote:FireClient(player, "Route", {
		Phase = route.Phase,
		Left = left,
		Total = #route.Stops,
		Bags = route.Bags,
		Elapsed = math.floor(os.clock() - route.Started),
	})
	if route.Phase == "Unload" and unloadPart then
		player:SetAttribute("TaskTarget", unloadPart.Position)
		player:SetAttribute("TaskText", ("Descarga %d bolsas en el Punto Limpio"):format(route.Bags))
	elseif nextStop then
		player:SetAttribute("TaskTarget", nextStop.Bin.Position)
		player:SetAttribute("TaskText", ("Vacía la papelera llena (quedan %d)"):format(left))
	end
end

local function clearStop(stop: Stop)
	if stop.Overflow then
		stop.Overflow:Destroy()
		stop.Overflow = nil
	end
	if stop.Prompt then
		stop.Prompt:Destroy()
		stop.Prompt = nil
	end
	busyBins[stop.Bin] = nil
end

local function emptyBin(route: Route, stop: Stop)
	if stop.Done or routes[route.Player] ~= route or route.Phase ~= "Collect" then
		return
	end
	local player = route.Player
	stop.Done = true
	clearStop(stop)
	route.Bags += 1
	pay(player, G.PerBin, "papelera vaciada")
	local data = DataService.get(player)
	if data then
		data.Stats.TasksDone += 1
	end
	NeedsService.change(player, 0, -G.EnergyCost)
	StoryEvents.emit(player, "JobTaskDone", { JobId = "Basurero" })
	local left = 0
	for _, s in route.Stops do
		if not s.Done then
			left += 1
		end
	end
	if left == 0 then
		route.Phase = "Unload"
		Notify:FireClient(player, "Success", "¡Ruta limpia! Lleva las bolsas a los contenedores del Punto Limpio.")
	end
	refreshCarry(route)
	publish(route)
	if not NeedsService.canWork(player) then
		GarbageService.quit(player, true)
		Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
	end
end

local function makeRoute(route: Route)
	local origin = if depot and unloadPart then unloadPart.Position else (rootOf(route.Player) or { Position = Vector3.zero } :: any).Position
	local candidates = {}
	for _, bin in CollectionService:GetTagged("Papelera") do
		if bin:IsA("BasePart") and not busyBins[bin] and bin:IsDescendantOf(workspace) then
			local d = Vector3.new(bin.Position.X - origin.X, 0, bin.Position.Z - origin.Z).Magnitude
			if d >= G.MinDistance and d <= G.MaxDistance then
				table.insert(candidates, bin)
			end
		end
	end
	route.Stops = {}
	route.Phase = "Collect"
	route.Started = os.clock()
	for _ = 1, math.min(G.Bins, #candidates) do
		local bin = table.remove(candidates, math.random(1, #candidates))
		busyBins[bin] = true
		local stop: Stop = { Bin = bin, Done = false }
		-- Se ve rebosante: la bolsa asoma por arriba
		local overflow = Instance.new("Part")
		overflow.Name = "Overflow"
		overflow.Shape = Enum.PartType.Ball
		overflow.Size = Vector3.new(1.7, 1.2, 1.7)
		overflow.Color = Color3.fromRGB(24, 24, 28)
		overflow.Material = Enum.Material.Plastic
		overflow.Anchored = true
		overflow.CanCollide = false
		overflow.CanQuery = false
		overflow.CanTouch = false
		overflow.CFrame = CFrame.new(bin.Position + Vector3.new(0, bin.Size.X / 2 + 0.2, 0))
		overflow.Parent = bin
		stop.Overflow = overflow
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Vaciar papelera"
		prompt.ObjectText = "🗑️ Papelera llena"
		prompt.HoldDuration = 1.2
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("JobOnly", "Basurero")
		prompt:SetAttribute("OwnerUserId", route.Player.UserId)
		prompt.Parent = bin
		prompt.Triggered:Connect(function(player)
			if player == route.Player then
				emptyBin(route, stop)
			end
		end)
		stop.Prompt = prompt
		table.insert(route.Stops, stop)
	end
end

local function onUnload(player: Player)
	local route = routes[player]
	if not route then
		return
	end
	if route.Bags == 0 then
		Notify:FireClient(player, "Info", "No llevas bolsas. Vacía las papeleras de tu ruta.")
		return
	end
	local fast = route.Phase == "Unload" and os.clock() - route.Started <= G.RouteSeconds
	local bonus = if route.Phase == "Unload" then G.UnloadBonus * (if fast then 2 else 1) else 0
	pay(player, bonus, ("%d bolsas descargadas%s"):format(route.Bags, if fast then " (¡bonus por rapidez!)" else ""))
	route.Bags = 0
	refreshCarry(route)
	if route.Phase == "Unload" then
		makeRoute(route)
		Notify:FireClient(player, "Info", "Nueva ruta: hay más papeleras llenas por la ciudad.")
	end
	publish(route)
end

---------------------------------------------------------------------
-- Bolsas sueltas por la calle
---------------------------------------------------------------------

local function setupBag(bag: Instance)
	if not bag:IsA("BasePart") or bag:FindFirstChild("BagPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BagPrompt"
	prompt.ActionText = "Recoger bolsa"
	prompt.ObjectText = "🗑️ Basura en la calle"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("JobOnly", "Basurero")
	prompt.Parent = bag
	prompt.Triggered:Connect(function(player)
		local route = routes[player]
		if not route or (bag.Transparency or 0) >= 1 then
			return
		end
		bag.Transparency = 1
		prompt.Enabled = false
		route.Bags += 1
		pay(player, G.PerBag, "bolsa recogida")
		refreshCarry(route)
		publish(route)
		task.delay(G.BagRespawn, function()
			bag.Transparency = 0
			prompt.Enabled = true
		end)
	end)
end

---------------------------------------------------------------------
-- Empezar y dejar el turno
---------------------------------------------------------------------

function GarbageService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	JobService.quit(player, true)
	local route: Route = { Player = player, Phase = "Collect", Stops = {}, Bags = 0, Started = os.clock() }
	routes[player] = route
	makeRoute(route)
	RoleService.setOnDuty(player, "Basurero")
	player:SetAttribute("Job", "Basurero")
	Remote:FireClient(player, "Start")
	Notify:FireClient(player, "Success", ("¡Contratado como basurero! Hay %d papeleras llenas. Con carnet B, coge el camión."):format(#route.Stops))
	publish(route)
end

function GarbageService.quit(player: Player, silent: boolean?)
	local route = routes[player]
	if not route then
		return
	end
	routes[player] = nil
	for _, stop in route.Stops do
		clearStop(stop)
	end
	if route.Carry then
		route.Carry:Destroy()
	end
	RoleService.offDuty(player, "Basurero")
	if player:GetAttribute("Job") == "Basurero" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "Stop")
	if not silent then
		Notify:FireClient(player, "Info", "Has dejado el trabajo de basurero.")
	end
end

---------------------------------------------------------------------

local function jobPrompt(parent: BasePart, action: string, object: string, hold: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p:SetAttribute("JobOnly", "Basurero")
	p.Parent = parent
	return p
end

local function setupDepot(model: Instance)
	if not model:IsA("Model") or depot then
		return
	end
	depot = model
	for _, d in model:GetDescendants() do
		if d:HasTag("GarbageUnload") then
			unloadPart = d
			jobPrompt(d, "Descargar", "♻ Contenedores del Punto Limpio", 1).Triggered:Connect(onUnload)
		elseif d:HasTag("GarbageTruck") then
			jobPrompt(d, "Camión de la basura", "🚛 Limpieza Valmar (carnet B)", 0.4).Triggered:Connect(function(player)
				if not routes[player] then
					return
				end
				if not VehicleService.mount(player, "Camion", { Rented = true }) then
					Notify:FireClient(player, "Info", "Para el camión hace falta el carnet B. Puedes hacer la ruta a pie.")
				end
			end)
		end
	end
end

function GarbageService.init()
	for _, model in CollectionService:GetTagged("GarbageDepot") do
		setupDepot(model)
	end
	CollectionService:GetInstanceAddedSignal("GarbageDepot"):Connect(setupDepot)
	for _, bag in CollectionService:GetTagged("Pickup_Basurero") do
		setupBag(bag)
	end
	CollectionService:GetInstanceAddedSignal("Pickup_Basurero"):Connect(setupBag)
	JobService.setHandler("Basurero", { Start = GarbageService.start, Quit = GarbageService.quit })
	Players.PlayerRemoving:Connect(function(player)
		GarbageService.quit(player, true)
	end)
	-- La bolsa en la mano aparece o desaparece al subir y bajar del camión; panel al día
	task.spawn(function()
		while true do
			task.wait(2)
			for _, route in routes do
				refreshCarry(route)
				publish(route)
			end
		end
	end)
end

return GarbageService
