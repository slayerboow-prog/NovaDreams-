-- FishingService: la pesca y el oficio de pescador.
--
-- PESCAR (cualquiera con caña)
--   * En un sitio de pesca (muelle del puerto, pantalanes de los lagos y del río, barco de pesca)
--     "Pescar". Se lanza el sedal y el corcho cae al agua. Cuando pica (el corcho se hunde) hay que
--     "¡Tirar!" enseguida: si tiras antes, se asusta; si tardas, se escapa.
--   * Lo que pesca depende del agua (mar, alta mar, río, lago) y de la caña (la profesional saca
--     más peces raros). Con cebo pican antes (se gasta uno por lanzamiento).
--   * Las cañas y el cebo se compran en la tienda de pesca del centro (mostrador "Comprar").
--   * El barco de pesca está fondeado en alta mar: se sube desde el amarre del puerto (gratis para
--     los pescadores de turno; los demás pagan el alquiler).
--
-- VENDER: en la pescadería de cualquier supermercado, "Vender pescado". Lo que vendes se pone en el
-- mostrador y los clientes lo pueden comprar. Si nadie pesca, el supermercado no tiene pescado
-- (solo lo poco que trae el pescador NPC del puerto de vez en cuando).
--
-- PESCADOR (tablón "Trabajar" en el puerto): te prestan una caña si no tienes, el supermercado te
-- paga más y cada venta cuenta para la historia (JobTaskDone con JobId "Pescador").

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fishing = require(ReplicatedStorage.Shared.Fishing)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local InventoryService = require(script.Parent.InventoryService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local SupermarketService = require(script.Parent.SupermarketService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local FishingService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Fishing :: RemoteEvent
local JOB = Fishing.Job
local WATER_Y = -2
local LATENCY = 0.4 -- margen por el retraso de la red al tirar

type State = {
	Spot: BasePart,
	Token: number,
	Phase: string, -- "Wait" | "Bite" | "Done"
	BiteAt: number,
}

-- Números al azar (con math.random: funciona igual en Roblox y en las pruebas)
local rng = {}
function rng.NextNumber(_self: any, min: number?, max: number?): number
	local lo, hi = min or 0, max or 1
	return lo + math.random() * (hi - lo)
end
function rng.NextInteger(_self: any, min: number, max: number): number
	return math.random(min, max)
end
local fishing: { [Player]: State } = {}
local spotOwner: { [BasePart]: Player } = {}
local onDuty: { [Player]: boolean } = {}
local lentRod: { [Player]: boolean } = {}
local nextToken = 0

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nameOf(player: Player): string
	return player.DisplayName or player.Name
end

local function isBaby(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	return type(stage) == "string" and Stages.isValid(stage) and not Stages.inRange(stage, "Nino", nil)
end

-- La mejor caña que tienes (o nil)
local function rodOf(player: Player): { [string]: any }?
	for _, id in Fishing.RodOrder do
		if InventoryService.count(player, id) > 0 then
			return Fishing.Rods[id]
		end
	end
	return nil
end

local function fishCount(player: Player): number
	local n = 0
	for _, s in Fishing.Species do
		n += InventoryService.count(player, s.Item)
	end
	return n
end

---------------------------------------------------------------------
-- Pescar
---------------------------------------------------------------------

local function stop(player: Player, silent: boolean?)
	local state = fishing[player]
	if not state then
		return
	end
	fishing[player] = nil
	if spotOwner[state.Spot] == player then
		spotOwner[state.Spot] = nil
	end
	if player.Parent then
		Remote:FireClient(player, "Stop")
		if not silent then
			Notify:FireClient(player, "Info", "🎣 Recoges el sedal.")
		end
	end
end

local function bobberOf(spot: BasePart): Vector3
	local p = (spot.CFrame * CFrame.new(0, 0, -(spot:GetAttribute("CastDistance") or 10))).Position
	return Vector3.new(p.X, WATER_Y + 0.2, p.Z)
end

local function cast(player: Player, spot: BasePart)
	local rod = rodOf(player)
	if not rod then
		Notify:FireClient(player, "Info", "Necesitas una caña de pescar. Cómprala en la tienda de pesca del centro 🎣")
		return
	end
	local state = fishing[player]
	if state and state.Spot ~= spot then
		stop(player, true)
		state = nil
	end
	if spotOwner[spot] and spotOwner[spot] ~= player then
		Notify:FireClient(player, "Info", "Aquí ya está pescando " .. nameOf(spotOwner[spot] :: Player) .. ".")
		return
	end
	spotOwner[spot] = player
	-- Cuánto tardan en picar: caña, cebo y oficio
	local delay = rng:NextNumber(Fishing.BiteMin, Fishing.BiteMax) * rod.Bite
	local bait = InventoryService.count(player, Fishing.Bait.Id) > 0
	if bait then
		InventoryService.remove(player, Fishing.Bait.Id, 1)
		delay *= Fishing.Bait.Bite
	end
	if onDuty[player] then
		delay *= 0.85
	end
	nextToken += 1
	local token = nextToken
	fishing[player] = { Spot = spot, Token = token, Phase = "Wait", BiteAt = 0 }
	-- Mirando al agua
	local character = player.Character
	if character then
		character:PivotTo(spot.CFrame * CFrame.new(0, 0.5, 0))
	end
	Remote:FireClient(player, "Cast", {
		Token = token,
		Bobber = bobberOf(spot),
		Water = Fishing.Waters[spot:GetAttribute("Water")] or "el agua",
		Rod = rod.Name,
		Bait = bait,
		BaitLeft = InventoryService.count(player, Fishing.Bait.Id),
	})
	task.delay(delay, function()
		local now = fishing[player]
		if not now or now.Token ~= token or now.Phase ~= "Wait" then
			return
		end
		now.Phase = "Bite"
		now.BiteAt = os.clock()
		Remote:FireClient(player, "Bite", { Token = token, Window = Fishing.Window })
		task.delay(Fishing.Window + LATENCY, function()
			local later = fishing[player]
			if later and later.Token == token and later.Phase == "Bite" then
				later.Phase = "Done"
				Remote:FireClient(player, "Result", { Token = token, Kind = "Late" })
			end
		end)
	end)
end

local function reel(player: Player, token: any)
	local state = fishing[player]
	if not state or state.Token ~= token then
		return
	end
	if state.Phase == "Wait" then
		state.Phase = "Done"
		Remote:FireClient(player, "Result", { Token = token, Kind = "Early" })
		return
	end
	if state.Phase ~= "Bite" then
		return
	end
	state.Phase = "Done"
	if os.clock() - state.BiteAt > Fishing.Window + LATENCY then
		Remote:FireClient(player, "Result", { Token = token, Kind = "Late" })
		return
	end
	local rod = rodOf(player)
	local species = Fishing.roll(state.Spot:GetAttribute("Water") or "Mar", if rod then rod.Rare else 1, rng :: any)
	if not species then
		local junk = Fishing.Junk[rng:NextInteger(1, #Fishing.Junk)]
		Remote:FireClient(player, "Result", { Token = token, Kind = "Junk", Name = junk.Name, Icon = junk.Icon })
		return
	end
	if not InventoryService.add(player, species.Item, 1) then
		Remote:FireClient(player, "Result", { Token = token, Kind = "Full", Name = species.Name, Icon = species.Icon })
		return
	end
	local kg = math.floor(rng:NextNumber(species.Kg[1], species.Kg[2]) * 100 + 0.5) / 100
	Remote:FireClient(player, "Result", { Token = token, Kind = "Catch", Name = species.Name, Icon = species.Icon, Kg = kg, Rare = species.Rare == true, Price = species.Price })
	StoryEvents.emit(player, "CaughtFish", { Species = species.Id })
end

local function onSpot(player: Player, spot: BasePart)
	if isBaby(player) then
		Notify:FireClient(player, "Info", "Los bebés no pueden pescar.")
		return
	end
	local state = fishing[player]
	if state and state.Spot == spot and state.Phase ~= "Done" then
		stop(player)
		return
	end
	cast(player, spot)
end

---------------------------------------------------------------------
-- Tienda de pesca
---------------------------------------------------------------------

local function shopList(player: Player): { any }
	local list = {}
	for _, id in { "CanaPescar", "CanaPro" } do
		local rod = Fishing.Rods[id]
		table.insert(list, { Id = id, Name = rod.Name, Icon = rod.Icon, Price = rod.Price, Desc = rod.Desc, Owned = InventoryService.count(player, id) > 0 })
	end
	local bait = Fishing.Bait
	table.insert(list, { Id = bait.Id, Name = ("%s (x%d)"):format(bait.Name, bait.Pack), Icon = bait.Icon, Price = bait.Price, Desc = bait.Desc, Owned = false, Have = InventoryService.count(player, bait.Id) })
	return list
end

local function onBuy(player: Player, id: any)
	local rod = typeof(id) == "string" and Fishing.Rods[id]
	local isBait = id == Fishing.Bait.Id
	if not rod and not isBait then
		return
	end
	local root = rootOf(player)
	local near = false
	for _, counter in CollectionService:GetTagged("FishingShopCounter") do
		if counter:IsA("BasePart") and root and (counter.Position - root.Position).Magnitude < 20 then
			near = true
		end
	end
	if not near then
		return
	end
	local price = if rod then rod.Price else Fishing.Bait.Price
	local count = if rod then 1 else Fishing.Bait.Pack
	if rod and InventoryService.count(player, rod.Id) > 0 then
		Notify:FireClient(player, "Info", "Ya tienes una " .. string.lower(rod.Name) .. ".")
		return
	end
	if not InventoryService.canAdd(player, id, count) then
		Notify:FireClient(player, "Error", "No te cabe en la mochila.")
		return
	end
	if not DataService.spend(player, price) then
		Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
		return
	end
	InventoryService.add(player, id, count)
	if rod and lentRod[player] then
		lentRod[player] = nil -- ya tiene la suya: la prestada se queda (se devuelve al acabar el turno)
	end
	Notify:FireClient(player, "Success", ("🎣 Has comprado: %s."):format(if rod then rod.Name else ("%d de cebo"):format(count)))
	Remote:FireClient(player, "Shop", shopList(player))
end

---------------------------------------------------------------------
-- Barco de pesca
---------------------------------------------------------------------

local function first(tag: string): BasePart?
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function onDock(player: Player, dock: BasePart)
	if isBaby(player) then
		return
	end
	local deck = first("FishingBoatDeck")
	if not deck then
		return
	end
	if not onDuty[player] then
		if not DataService.spend(player, Fishing.BoatPrice) then
			Notify:FireClient(player, "Error", ("El barco cuesta %s y no tienes suficiente."):format(Format.money(Fishing.BoatPrice)))
			return
		end
		Notify:FireClient(player, "Info", ("⛴️ Alquiler del barco: %s. ¡Buena pesca en alta mar!"):format(Format.money(Fishing.BoatPrice)))
	else
		Notify:FireClient(player, "Info", "⛴️ ¡A faenar! En alta mar salen merluzas, gambas y hasta atunes.")
	end
	stop(player, true)
	local character = player.Character
	if character then
		character:PivotTo(deck.CFrame * CFrame.new(0, 3, 0))
	end
	player:SetAttribute("BoatReturn", dock.Position)
end

local function onReturn(player: Player)
	stop(player, true)
	local back = player:GetAttribute("BoatReturn")
	local dock = first("FishingBoatDock")
	local target = if typeof(back) == "Vector3" then back elseif dock then dock.Position else nil
	local character = player.Character
	if character and target then
		character:PivotTo(CFrame.new(target + Vector3.new(0, 1, -5)))
	end
	player:SetAttribute("BoatReturn", nil)
end

---------------------------------------------------------------------
-- Vender en la pescadería
---------------------------------------------------------------------

local function onSell(player: Player, counter: BasePart)
	if fishCount(player) == 0 then
		Notify:FireClient(player, "Info", "No llevas pescado. ¡Ve a pescar! 🎣")
		return
	end
	local total, sold, full = 0, 0, {}
	local bonus = if onDuty[player] then JOB.PayBonus * MonetizationService.payMultiplier(player) else 1
	for _, species in Fishing.Species do
		local have = InventoryService.count(player, species.Item)
		if have > 0 then
			local n = math.min(have, SupermarketService.fishRoom(counter, species.Product))
			if n > 0 and InventoryService.remove(player, species.Item, n) then
				local put = SupermarketService.addFish(counter, species.Product, n)
				if put < n then
					InventoryService.add(player, species.Item, n - put) -- lo que no ha cabido, te lo quedas
				end
				sold += put
				total += math.floor(species.Price * put * bonus + 0.5)
			end
			if n < have then
				table.insert(full, species.Name)
			end
		end
	end
	if sold == 0 then
		Notify:FireClient(player, "Info", "La pescadería está llena de eso ahora mismo. Prueba en otro supermercado.")
		return
	end
	DataService.addMoney(player, total, true)
	Notify:FireClient(player, "Money", ("+%s · has vendido %d %s a la pescadería"):format(Format.money(total), sold, if sold == 1 then "pieza" else "piezas"))
	if #full > 0 then
		Notify:FireClient(player, "Info", "No caben más de: " .. table.concat(full, ", ") .. ". Te los quedas (véndelos en otro supermercado).")
	end
	if onDuty[player] then
		local data = DataService.get(player)
		if data and data.Stats then
			data.Stats.TasksDone += 1
		end
		NeedsService.change(player, 0, -JOB.EnergyCost)
		StoryEvents.emit(player, "JobTaskDone", { JobId = "Pescador", Pay = total })
		if not NeedsService.canWork(player) then
			FishingService.quit(player, true)
			Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
		end
	end
end

---------------------------------------------------------------------
-- Oficio de pescador
---------------------------------------------------------------------

local function nearestTagged(tag: string, from: Vector3): BasePart?
	local best, bestD = nil, math.huge
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") then
			local d = (part.Position - from).Magnitude
			if d < bestD then
				best, bestD = part, d
			end
		end
	end
	return best
end

local function guide(player: Player)
	local root = rootOf(player)
	if not root then
		return
	end
	if fishCount(player) >= JOB.CarryGoal then
		local counter = nearestTagged("SuperFish", root.Position)
		player:SetAttribute("TaskTarget", if counter then counter.Position else nil)
		player:SetAttribute("TaskText", ("Lleva el pescado (%d) a la pescadería del supermercado"):format(fishCount(player)))
	else
		local spot = if fishing[player] then fishing[player].Spot else nearestTagged("FishingSpot", root.Position)
		player:SetAttribute("TaskTarget", if spot then spot.Position else nil)
		player:SetAttribute("TaskText", ("Pesca (%d/%d) en el muelle, el río, los lagos o el barco"):format(fishCount(player), JOB.CarryGoal))
	end
end

function FishingService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	JobService.quit(player, true)
	onDuty[player] = true
	if not rodOf(player) and InventoryService.add(player, "CanaPescar", 1) then
		lentRod[player] = true
		Notify:FireClient(player, "Info", "🎣 Te prestan una caña de pescar mientras trabajas.")
	end
	RoleService.setOnDuty(player, "Pescador")
	player:SetAttribute("Job", "Pescador")
	Remote:FireClient(player, "JobStart")
	Notify:FireClient(player, "Success", "¡A pescar! Llena la mochila y vende el pescado en el supermercado. El barco de pesca te sale gratis.")
	guide(player)
end

function FishingService.quit(player: Player, silent: boolean?)
	if not onDuty[player] then
		return
	end
	onDuty[player] = nil
	if lentRod[player] then
		lentRod[player] = nil
		stop(player, true)
		InventoryService.remove(player, "CanaPescar", 1)
	end
	RoleService.offDuty(player, "Pescador")
	if player:GetAttribute("Job") == "Pescador" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "JobStop")
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado tu jornada de pesca.")
	end
end

---------------------------------------------------------------------
-- Pescador NPC del puerto
---------------------------------------------------------------------

local npcModel: Model? = nil

local function refreshNpc()
	local spot = first("FishingNpcSpot")
	if not spot then
		return
	end
	local near = false
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - spot.Position).Magnitude < 250 then
			near = true
			break
		end
	end
	if near and not npcModel then
		local folder = spot.Parent :: Instance
		npcModel = Npc.create("Npc_Pescador", folder, spot.CFrame * CFrame.new(0, 0.5, 0), { Shirt = Color3.fromRGB(230, 200, 60), Pants = Color3.fromRGB(40, 60, 90) })
		local rod = Instance.new("Part")
		rod.Name = "Rod"
		rod.Size = Vector3.new(0.15, 0.15, 8)
		rod.Anchored = true
		rod.CanCollide = false
		rod.CanQuery = false
		rod.Color = Color3.fromRGB(40, 40, 44)
		rod.CFrame = spot.CFrame * CFrame.new(0.9, 1.4, -3.6) * CFrame.Angles(math.rad(25), 0, 0)
		rod.Parent = npcModel
	elseif not near and npcModel then
		npcModel:Destroy()
		npcModel = nil
	end
end

-- Si ningún jugador pesca de turno, el pescador del puerto lleva un poco de pescado a un supermercado
local function npcDelivery()
	for _ in onDuty do
		return
	end
	local counters = CollectionService:GetTagged("SuperFish")
	if #counters == 0 then
		return
	end
	local counter = counters[rng:NextInteger(1, #counters)]
	for _ = 1, Fishing.NpcDeliveryCount do
		local species = Fishing.roll("Mar", 1, rng :: any)
		if species then
			SupermarketService.addFish(counter, species.Product, 1)
		end
	end
end

---------------------------------------------------------------------

local function prompt(parent: BasePart, action: string, object: string, hold: number, distance: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = distance or 8
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function setupSpot(spot: Instance)
	if not spot:IsA("BasePart") or spot:FindFirstChild("FishPrompt") then
		return
	end
	local p = prompt(spot, "Pescar", "🎣 Sitio de pesca", 0.2, 7)
	p.Name = "FishPrompt"
	p.Triggered:Connect(function(player)
		onSpot(player, spot)
	end)
end

local function setupCounter(counter: Instance)
	if not counter:IsA("BasePart") or counter:FindFirstChild("SellPrompt") then
		return
	end
	local p = prompt(counter, "Vender pescado", "🐟 Pescadería", 0.5, 9)
	p.Name = "SellPrompt"
	p.Triggered:Connect(function(player)
		onSell(player, counter)
	end)
end

local function setupShop(counter: Instance)
	if not counter:IsA("BasePart") or counter:FindFirstChild("ShopPrompt") then
		return
	end
	local p = prompt(counter, "Comprar", "🎣 Tienda de pesca", 0.3, 10)
	p.Name = "ShopPrompt"
	p.Triggered:Connect(function(player)
		Remote:FireClient(player, "Shop", shopList(player))
	end)
	local spot = counter:GetAttribute("StaffSpot")
	if typeof(spot) == "Vector3" then
		local clerk = Npc.create("Npc_TenderoPesca", counter.Parent :: Instance, CFrame.lookAt(spot + Vector3.new(0, 3, 0), counter.Position * Vector3.new(1, 0, 1) + Vector3.new(0, spot.Y + 3, 0)), { Shirt = Color3.fromRGB(40, 110, 60), Pants = Color3.fromRGB(90, 70, 50) })
		local _ = clerk
	end
end

local function setupDock(dock: Instance)
	if not dock:IsA("BasePart") or dock:FindFirstChild("DockPrompt") then
		return
	end
	local p = prompt(dock, "Subir al barco de pesca", ("⛴️ Alta mar (%s; gratis para pescadores)"):format(Format.money(Fishing.BoatPrice)), 0.5, 10)
	p.Name = "DockPrompt"
	p.Triggered:Connect(function(player)
		onDock(player, dock)
	end)
end

local function setupReturn(board: Instance)
	if not board:IsA("BasePart") or board:FindFirstChild("ReturnPrompt") then
		return
	end
	local p = prompt(board, "Volver a puerto", "⛴️ Barco de pesca", 0.5, 10)
	p.Name = "ReturnPrompt"
	p.Triggered:Connect(onReturn)
end

function FishingService.init()
	for tag, fn in { FishingSpot = setupSpot, SuperFish = setupCounter, FishingShopCounter = setupShop, FishingBoatDock = setupDock, FishingBoatReturn = setupReturn } do
		for _, part in CollectionService:GetTagged(tag) do
			fn(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
	end
	JobService.setHandler("Pescador", { Start = FishingService.start, Quit = FishingService.quit })
	Remote.OnServerEvent:Connect(function(player, action, a)
		if action == "Reel" then
			reel(player, a)
		elseif action == "Again" then
			local state = fishing[player]
			if state and state.Phase == "Done" then
				cast(player, state.Spot)
			end
		elseif action == "Stop" then
			stop(player)
		elseif action == "Buy" then
			onBuy(player, a)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		stop(player, true)
		FishingService.quit(player, true)
		onDuty[player] = nil
		lentRod[player] = nil
	end)
	task.spawn(function()
		local sinceDelivery = 0
		while true do
			task.wait(1)
			local ok, err = pcall(function()
				-- Si te alejas del sitio, se recoge el sedal
				for player, state in fishing do
					local root = rootOf(player)
					if not root or (root.Position - state.Spot.Position).Magnitude > Fishing.MoveCancel then
						stop(player)
					end
				end
				for player in onDuty do
					guide(player)
				end
				refreshNpc()
				sinceDelivery += 1
				if sinceDelivery >= Fishing.NpcDeliveryEvery then
					sinceDelivery = 0
					npcDelivery()
				end
			end)
			if not ok then
				warn("[FishingService] " .. tostring(err))
			end
		end
	end)
end

-- Para las pruebas
FishingService._fishing = fishing

return FishingService
