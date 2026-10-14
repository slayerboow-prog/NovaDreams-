-- FeriaService (servidor): el Mercadillo y Recinto de Fiestas de la Explanada del Este (zona 7).
-- Las reglas (horario, premios, precios) están en shared/OcioFeria; el sitio, en Kit/ZonasVerdes/Mercadillo.
--
--   * Puestos (tag OcioStall): «Alquilar puesto · 40 €» (en horario de mercadillo o de fiesta). Mientras
--     dura el alquiler, los clientes (gente de la ciudad, NPC) llegan cada 14-26 s y te compran lo de tu
--     mochila que se vende en un puesto (granja y pesca) a precio de puesto; los demás jugadores te
--     compran con «Comprar · …». Tú lo cierras con «Cerrar mi puesto» (o se acaba el tiempo).
--   * Casetas de la feria (tag OcioFairGame): solo en la fiesta del sábado (17:00-2:00). Cada juego es
--     la barra de precisión de MiniGameService; da tickets de los recreativos, algo de dinero y diversión.
--   * Escenario (tag OcioStage): «Actuar» (barra de precisión): propinas (más en la fiesta) y diversión.
--   * Panel del horario (tag OcioFeriaInfo) y atributo OcioFiesta de workspace (el cliente pone el
--     bullicio de la fiesta: Controllers/OcioClient).
--   * El oficio «Cocinero/a de food truck» es el de siempre de JobService (Config.Jobs.FoodTruck).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Feria = require(ReplicatedStorage.Shared.OcioFeria)
local Format = require(ReplicatedStorage.Shared.Format)
local OcioFun = require(script.Parent.OcioFun)

local FeriaService = {}

type Stall = {
	Id: number,
	Counter: BasePart,
	Owner: Player?,
	Until: number,
	NextCustomer: number,
	Sold: number,
	Earned: number,
	Rent: ProximityPrompt,
	Buy: ProximityPrompt,
	Close: ProximityPrompt,
}

local stalls: { [number]: Stall } = {}
local fairPrompts: { { Prompt: ProximityPrompt, Game: string } } = {}
local lastStage: { [Player]: number } = {}
local farmPrice: { [string]: number } = {}
local fishPrice: { [string]: number } = {}
local rng = Random.new()

FeriaService.STAGE_COOLDOWN = 25 -- s entre propinas del escenario
FeriaService.SaleFun = 2
FeriaService.SaleXp = 1

local function service(name: string): any
	local ok, svc = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	return if ok and type(svc) == "table" then svc else nil
end

-- (día de la semana, hora del juego con decimales). Las pruebas lo cambian.
function FeriaService.clock(): (number, number)
	local GameClock = require(ReplicatedStorage.Shared.GameClock)
	local d = GameClock.now()
	return d.Weekday, d.Hour + d.Minute / 60
end

local function bypass(player: Player): boolean
	local Tester = service("TesterService")
	return Tester ~= nil and Tester.bypass ~= nil and Tester.bypass(player) == true
end

local function now(): number
	return os.clock()
end

function FeriaService.status(): { [string]: any }
	local weekday, hour = FeriaService.clock()
	return Feria.status(weekday, hour)
end

---------------------------------------------------------------------
-- Puestos
---------------------------------------------------------------------
function FeriaService.priceOf(id: string): number
	return Feria.priceFor(id, farmPrice[id], fishPrice[id])
end

-- Lo que el dueño de un puesto tiene para vender: { [id] = cantidad }
function FeriaService.stockOf(player: Player): { [string]: number }
	local stock = {}
	local Inventory = service("InventoryService")
	if not Inventory then
		return stock
	end
	for id in farmPrice do
		local n = Inventory.count(player, id)
		if n > 0 then
			stock[id] = n
		end
	end
	for id in fishPrice do
		local n = Inventory.count(player, id)
		if n > 0 then
			stock[id] = (stock[id] or 0) + n
		end
	end
	return stock
end

local function itemName(id: string): string
	local Items = require(ReplicatedStorage.Shared.Items)
	local item = Items.get(id)
	return if item then item.Icon .. " " .. item.Name else id
end

local function setSign(stall: Stall, text: string)
	local model = stall.Counter.Parent
	local sign = model and model:FindFirstChild("StallSign")
	local gui = sign and sign:FindFirstChildWhichIsA("SurfaceGui")
	local label = gui and gui:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = text
	end
end

local function refreshStall(stall: Stall)
	local owner = stall.Owner
	stall.Rent.Enabled = owner == nil
	stall.Buy.Enabled = owner ~= nil
	stall.Close.Enabled = owner ~= nil
	if owner then
		local stock = FeriaService.stockOf(owner)
		local best = Feria.pickSale(stock, 0)
		stall.Buy.ObjectText = if best then ("%s · %s"):format(itemName(best), Format.money(FeriaService.priceOf(best))) else "Puesto vacío"
		stall.Buy.ActionText = "Comprar"
		setSign(stall, ("Puesto %d · %s"):format(stall.Id, owner.DisplayName))
	else
		setSign(stall, ("Puesto %d · Se alquila"):format(stall.Id))
	end
end

function FeriaService.ownedStall(player: Player): Stall?
	for _, s in stalls do
		if s.Owner == player then
			return s
		end
	end
	return nil
end

function FeriaService.closeStall(stall: Stall, why: string?)
	local owner = stall.Owner
	if not owner then
		return
	end
	stall.Owner = nil
	owner:SetAttribute("OcioStall", nil)
	if owner.Parent then
		OcioFun.say(owner, "Info", ("🧺 %s Vendido: %d (%s)."):format(why or "Has cerrado tu puesto.", stall.Sold, Format.money(stall.Earned)))
	end
	refreshStall(stall)
end

function FeriaService.rent(player: Player, stall: Stall): boolean
	if stall.Owner then
		return false
	end
	if FeriaService.ownedStall(player) then
		OcioFun.say(player, "Error", "Ya tienes un puesto alquilado.")
		return false
	end
	local st = FeriaService.status()
	if not st.Market and not st.Fair and not bypass(player) then
		OcioFun.say(player, "Error", ("🧺 El mercadillo está cerrado. Abre de %d:00 a %d:00 (el sábado, hasta las %d:00)."):format(Feria.Market.Open, Feria.Market.Close, Feria.Market.SaturdayClose))
		return false
	end
	local Data = service("DataService")
	if not Data or not Data.spend(player, Feria.Stall.Rent) then
		OcioFun.say(player, "Error", "No tienes suficiente dinero para el alquiler.")
		return false
	end
	stall.Owner = player
	stall.Until = now() + Feria.Stall.Seconds
	stall.NextCustomer = now() + rng:NextNumber(Feria.Stall.CustomerEvery[1], Feria.Stall.CustomerEvery[2])
	stall.Sold, stall.Earned = 0, 0
	player:SetAttribute("OcioStall", stall.Id)
	refreshStall(stall)
	local stock = FeriaService.stockOf(player)
	local kinds = 0
	for _ in stock do
		kinds += 1
	end
	OcioFun.say(player, "Success", if kinds > 0
		then ("🧺 Puesto %d alquilado %d min. La gente te comprará lo de tu mochila (granja y pesca)."):format(stall.Id, Feria.Stall.Seconds // 60)
		else ("🧺 Puesto %d alquilado. Trae cosas de la granja o pescado para vender."):format(stall.Id))
	OcioFun.reward(player, { Event = "OcioPlayed", Data = { Activity = "Puesto" } })
	return true
end

-- Una venta (a un cliente NPC o a otro jugador). buyer = nil: cliente de la ciudad.
function FeriaService.sell(stall: Stall, id: string, buyer: Player?): boolean
	local owner = stall.Owner
	local Inventory, Data = service("InventoryService"), service("DataService")
	if not owner or not Inventory or not Data then
		return false
	end
	local price = FeriaService.priceOf(id)
	if price <= 0 or Inventory.count(owner, id) <= 0 then
		return false
	end
	if buyer then
		if not Inventory.canAdd(buyer, id, 1) then
			OcioFun.say(buyer, "Error", "No te cabe en la mochila.")
			return false
		end
		if not Data.spend(buyer, price) then
			OcioFun.say(buyer, "Error", "No tienes suficiente dinero.")
			return false
		end
	end
	if not Inventory.remove(owner, id, 1) then
		if buyer then
			Data.addMoney(buyer, price, false) -- (devolverle el dinero)
		end
		return false
	end
	if buyer then
		Inventory.add(buyer, id, 1)
		OcioFun.say(buyer, "Success", ("🧺 Has comprado %s a %s."):format(itemName(id), owner.DisplayName))
	end
	Data.addMoney(owner, price, true)
	stall.Sold += 1
	stall.Earned += price
	OcioFun.reward(owner, { Fun = FeriaService.SaleFun, Xp = FeriaService.SaleXp, Reason = "Mercadillo", Event = "OcioSale", Data = { Item = id, Price = price } })
	OcioFun.say(owner, "Money", ("🧺 %s te ha comprado %s: +%s"):format(if buyer then buyer.DisplayName else "Una clienta", itemName(id), Format.money(price)))
	OcioFun.fire("Sound", { Name = "Pago", At = stall.Counter.CFrame.Position })
	refreshStall(stall)
	return true
end

local function customerArrives(stall: Stall)
	local owner = stall.Owner :: Player
	local id = Feria.pickSale(FeriaService.stockOf(owner), rng:NextNumber())
	if not id then
		return
	end
	-- Alguien de la ciudad se acerca al mostrador un momento
	pcall(function()
		local Npc = require(script.Parent.Parent.World.Npc)
		local at = stall.Counter.CFrame * CFrame.new(0, 1.5, -3.5) * CFrame.Angles(0, math.pi, 0)
		local model = Npc.create("Cliente", stall.Counter.Parent :: Instance, at)
		CollectionService:AddTag(model, "StaticNpc")
		task.delay(6, function()
			model:Destroy()
		end)
	end)
	FeriaService.sell(stall, id, nil)
end

---------------------------------------------------------------------
-- Feria y escenario (barra de precisión de MiniGameService)
---------------------------------------------------------------------
function FeriaService.playGame(player: Player, gameId: string): boolean
	local g = Feria.Games[gameId]
	if not g then
		return false
	end
	if not FeriaService.status().Fair and not bypass(player) then
		OcioFun.say(player, "Error", ("🎡 Las casetas abren en la fiesta del sábado (de %d:00 a 2:00)."):format(Feria.Fair.Open))
		return false
	end
	local MiniGame, Data = service("MiniGameService"), service("DataService")
	if not MiniGame or not Data or MiniGame.isRunning(player) then
		return false
	end
	if not Data.spend(player, g.Price) then
		OcioFun.say(player, "Error", "No tienes suficiente dinero.")
		return false
	end
	local started = MiniGame.start(player, table.clone(g.Spec), function(result)
		local hits = if type(result) == "table" then tonumber(result.Score) or 0 else 0
		local won = type(result) == "table" and result.Won == true
		local prize = Feria.prize(gameId, hits, won)
		OcioFun.reward(player, { Fun = prize.Fun, Money = prize.Money, Tickets = prize.Tickets, Xp = 2, Reason = "Feria", Event = "OcioPlayed", Data = { Activity = gameId, Hits = hits, Won = won }, Text = g.Icon .. " " .. g.Name })
		if hits >= g.Spec.Rounds then
			OcioFun.fire("Sound", { Name = "Ovacion", At = player.Character and player.Character:GetPivot().Position or nil }, player)
		end
	end)
	if not started then
		Data.addMoney(player, g.Price, false)
	end
	return started
end

function FeriaService.perform(player: Player): boolean
	local MiniGame = service("MiniGameService")
	if not MiniGame or MiniGame.isRunning(player) then
		return false
	end
	local fair = FeriaService.status().Fair
	return MiniGame.start(player, { Game = "Timing", Title = "Toca en el escenario", Icon = "🎸", Rounds = 4, Need = 2, Speed = 1.2, Zone = 0.22 }, function(result)
		local hits = if type(result) == "table" then math.clamp(math.floor(tonumber(result.Score) or 0), 0, 4) else 0
		local paid = lastStage[player] == nil or now() - lastStage[player] >= FeriaService.STAGE_COOLDOWN
		lastStage[player] = now()
		local tips = if paid then hits * (if fair then 5 else 3) else 0
		OcioFun.reward(player, { Fun = 6 + hits, Money = tips, Xp = 2, Reason = "Escenario", Event = "BuskPlayed", Data = { Hits = hits, Fair = fair }, Text = if hits >= 3 then "🎸 ¡El público aplaude!" else "🎸 Actuación" })
		if hits >= 3 then
			OcioFun.fire("Sound", { Name = "Ovacion", At = player.Character and player.Character:GetPivot().Position or nil })
		end
	end)
end

---------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------
local function prompt(parent: Instance, action: string, object: string, hold: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function setupStall(counter: Instance)
	if not counter:IsA("BasePart") then
		return
	end
	local id = tonumber(counter:GetAttribute("StallId")) or (#stalls + 1)
	if stalls[id] then
		return
	end
	local stall: Stall = {
		Id = id,
		Counter = counter,
		Owner = nil,
		Until = 0,
		NextCustomer = 0,
		Sold = 0,
		Earned = 0,
		Rent = prompt(counter, "Alquilar puesto", ("Puesto %d · %s · %d min"):format(id, Format.money(Feria.Stall.Rent), Feria.Stall.Seconds // 60)),
		Buy = prompt(counter, "Comprar", "Puesto"),
		Close = prompt(counter, "Cerrar mi puesto", "Solo quien lo alquila", 0.8),
	}
	stall.Buy.KeyboardKeyCode = Enum.KeyCode.E
	stall.Close.KeyboardKeyCode = Enum.KeyCode.R
	stalls[id] = stall
	stall.Rent.Triggered:Connect(function(player)
		FeriaService.rent(player, stall)
	end)
	stall.Buy.Triggered:Connect(function(player)
		if stall.Owner == player then
			OcioFun.say(player, "Info", "🧺 Es tu puesto: la gente te compra sola. Para cerrarlo, «Cerrar mi puesto».")
			return
		end
		local owner = stall.Owner
		local id2 = owner and Feria.pickSale(FeriaService.stockOf(owner), 0)
		if not id2 then
			OcioFun.say(player, "Error", "Este puesto no tiene nada a la venta ahora.")
			return
		end
		FeriaService.sell(stall, id2, player)
	end)
	stall.Close.Triggered:Connect(function(player)
		if stall.Owner ~= player then
			OcioFun.say(player, "Error", "Este puesto no es tuyo.")
			return
		end
		FeriaService.closeStall(stall)
	end)
	refreshStall(stall)
end

local function setupGame(counter: Instance)
	if not counter:IsA("BasePart") then
		return
	end
	local gameId = counter:GetAttribute("Game")
	local g = Feria.Games[gameId]
	if not g then
		return
	end
	local p = prompt(counter, "Jugar", ("%s %s · %s"):format(g.Icon, g.Name, Format.money(g.Price)))
	table.insert(fairPrompts, { Prompt = p, Game = gameId })
	p.Triggered:Connect(function(player)
		FeriaService.playGame(player, gameId)
	end)
end

local function setupStage(stage: Instance)
	if stage:IsA("BasePart") then
		local p = prompt(stage, "Actuar", "🎸 Escenario", 0.3)
		p.MaxActivationDistance = 14
		p.Triggered:Connect(function(player)
			FeriaService.perform(player)
		end)
	end
end

-- Cada pocos segundos: horario (panel, carteles de las casetas, fiesta) y clientes de los puestos
function FeriaService.tick()
	local st = FeriaService.status()
	workspace:SetAttribute("OcioFiesta", st.Fair)
	for _, info in CollectionService:GetTagged("OcioFeriaInfo") do
		local gui = info:FindFirstChildWhichIsA("SurfaceGui")
		local label = gui and gui:FindFirstChildWhichIsA("TextLabel")
		if label then
			label.Text = st.Text
		end
	end
	for _, fp in fairPrompts do
		local g = Feria.Games[fp.Game]
		fp.Prompt.ActionText = if st.Fair then "Jugar" else "Cerrado"
		fp.Prompt.ObjectText = if st.Fair then ("%s %s · %s"):format(g.Icon, g.Name, Format.money(g.Price)) else ("%s abre el sábado a las %d:00"):format(g.Icon, Feria.Fair.Open)
	end
	local t = now()
	for _, stall in stalls do
		local owner = stall.Owner
		if owner then
			if not owner.Parent then
				FeriaService.closeStall(stall)
			elseif t >= stall.Until then
				FeriaService.closeStall(stall, "Se ha acabado el alquiler del puesto.")
			elseif t >= stall.NextCustomer then
				-- Más clientes en la fiesta; fuera de horario no viene nadie
				local open = st.Market or st.Fair
				local wait = rng:NextNumber(Feria.Stall.CustomerEvery[1], Feria.Stall.CustomerEvery[2])
				stall.NextCustomer = t + (if st.Fair then wait * 0.6 else wait)
				if open then
					customerArrives(stall)
				end
			else
				refreshStall(stall)
			end
		end
	end
end

function FeriaService.stalls(): { [number]: Stall }
	return stalls
end

function FeriaService.init()
	local Farming = require(ReplicatedStorage.Shared.Farming)
	local Fishing = require(ReplicatedStorage.Shared.Fishing)
	for id, p in Farming.Products do
		if type(p) == "table" and (p.Price or 0) > 0 then
			farmPrice[id] = p.Price
		end
	end
	for _, s in Fishing.Species do
		if s.Item and (s.Price or 0) > 0 then
			fishPrice[s.Item] = s.Price
		end
	end
	OcioFun.remote()
	for _, c in CollectionService:GetTagged("OcioStall") do
		setupStall(c)
	end
	for _, c in CollectionService:GetTagged("OcioFairGame") do
		setupGame(c)
	end
	for _, s in CollectionService:GetTagged("OcioStage") do
		setupStage(s)
	end
	Players.PlayerRemoving:Connect(function(player)
		local s = FeriaService.ownedStall(player)
		if s then
			FeriaService.closeStall(s)
		end
		lastStage[player] = nil
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(FeriaService.tick)
			if not ok then
				warn("[Feria] " .. tostring(err))
			end
			task.wait(2)
		end
	end)
end

return FeriaService
