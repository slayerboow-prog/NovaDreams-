-- ArcadeService: los recreativos.
--   * Máquinas (tag ArcadeMachine, atributo GameId): Lanzabolas y Canastas. Cada partida cuesta dinero.
--   * La puntuación da tickets; los tickets se canjean en el mostrador (tag PrizeCounter).
--   * Marcador de récords (tag ArcadeScoreboard): los mejores de todos los servidores
--     (OrderedDataStore) y, si no hay acceso a DataStore (Studio), los de esta partida.
-- Datos guardados: data.Tickets, data.Prizes, data.Wearing, data.ArcadeBest

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Builder = require(script.Parent.Parent.World.Builder)
local DataService = require(script.Parent.DataService)
local VehicleService = require(script.Parent.VehicleService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local ArcadeService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Arcade :: RemoteEvent
local Arcade = Gameplay.Arcade

type Session = { Token: string, GameId: string, Start: number }
local sessions: { [Player]: Session } = {}

type Entry = { Name: string, Score: number }
local localBest: { [string]: { [number]: Entry } } = {} -- récords de este servidor
local globalTop: { [string]: { Entry } } = {}
local names: { [number]: string } = {}
local boards: { BasePart } = {}

local function ensure(data: { [string]: any })
	data.Tickets = data.Tickets or 0
	data.Prizes = data.Prizes or {}
	data.Wearing = data.Wearing or {}
	data.ArcadeBest = data.ArcadeBest or {}
end

local function keys(t: { [string]: any }): string
	local list = {}
	for key, value in t do
		if value then
			table.insert(list, key)
		end
	end
	table.sort(list)
	return table.concat(list, ",")
end

local function sync(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	ensure(data)
	player:SetAttribute("Tickets", data.Tickets)
	player:SetAttribute("Prizes", keys(data.Prizes))
	player:SetAttribute("Wearing", keys(data.Wearing))
end

---------------------------------------------------------------------
-- Ropa de premio (gafas y gorra) soldada a la cabeza
---------------------------------------------------------------------
local function applyWearables(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	local data = DataService.get(player)
	if not character or not head or not data then
		return
	end
	ensure(data)
	for _, child in character:GetChildren() do
		if string.sub(child.Name, 1, 9) == "Wearable_" then
			child:Destroy()
		end
	end
	local s = head.Size
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?)
		local part = Instance.new("Part")
		part.Name = "Wearable_" .. name
		part.Size = size
		part.Shape = shape or Enum.PartType.Block
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CFrame = head.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = part
		weld.Parent = part
		part.Parent = character
	end
	if data.Wearing.Gafas and data.Prizes.Gafas then
		piece("Gafas", Vector3.new(s.X * 0.95, s.Y * 0.22, 0.15), CFrame.new(0, s.Y * 0.1, -s.Z / 2 - 0.05), Color3.fromRGB(20, 20, 24))
	end
	if data.Wearing.Gorra and data.Prizes.Gorra then
		piece("Gorra", Vector3.new(s.X * 1.08, s.Y * 0.32, s.Z * 1.08), CFrame.new(0, s.Y * 0.5, 0), Color3.fromRGB(200, 40, 50))
		piece("Visera", Vector3.new(s.X * 0.9, 0.12, s.Z * 0.55), CFrame.new(0, s.Y * 0.38, -s.Z * 0.72), Color3.fromRGB(200, 40, 50))
	end
end

---------------------------------------------------------------------
-- Récords
---------------------------------------------------------------------
local stores: { [string]: OrderedDataStore } = {}
do
	for gameId in Arcade.Games do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore("ArcadeTop_" .. gameId)
		end)
		if ok then
			stores[gameId] = store
		end
	end
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = if ok then name else "Jugador"
	return names[userId]
end

local function topFor(gameId: string): { Entry }
	local merged: { [string]: Entry } = {}
	for _, entry in globalTop[gameId] or {} do
		merged[entry.Name] = entry
	end
	for _, entry in localBest[gameId] or {} do
		local current = merged[entry.Name]
		if not current or current.Score < entry.Score then
			merged[entry.Name] = entry
		end
	end
	local list = {}
	for _, entry in merged do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		return a.Score > b.Score
	end)
	local top = {}
	for i = 1, math.min(Arcade.TopSize, #list) do
		top[i] = list[i]
	end
	return top
end

local function drawBoards()
	local lines = { "🏆 RÉCORDS" }
	for _, gameId in { "Bolas", "Canasta" } do
		local info = Arcade.Games[gameId]
		local row = {}
		for i, entry in topFor(gameId) do
			table.insert(row, ("%d. %s %d"):format(i, entry.Name, entry.Score))
		end
		table.insert(lines, info.Name .. ": " .. (if #row > 0 then table.concat(row, "   ") else "¡sé el primero!"))
	end
	local text = table.concat(lines, "\n")
	for _, board in boards do
		local label = board:FindFirstChild("RecordsGui") and board.RecordsGui:FindFirstChildOfClass("TextLabel")
		if label then
			label.Text = text
		end
	end
end

local function refreshGlobal()
	for gameId, store in stores do
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, Arcade.TopSize)
		end)
		if ok and pages then
			local list = {}
			for _, item in pages:GetCurrentPage() do
				local userId = tonumber(item.key)
				if userId then
					table.insert(list, { Name = nameOf(userId), Score = item.value })
				end
			end
			globalTop[gameId] = list
		end
	end
	drawBoards()
end

local function recordScore(player: Player, gameId: string, score: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	ensure(data)
	local best = data.ArcadeBest[gameId] or 0
	if score <= best then
		return
	end
	data.ArcadeBest[gameId] = score
	localBest[gameId] = localBest[gameId] or {}
	localBest[gameId][player.UserId] = { Name = player.Name, Score = score }
	Notify:FireClient(player, "Success", ("🏆 ¡Nuevo récord personal en %s: %d!"):format(Arcade.Games[gameId].Name, score))
	local store = stores[gameId]
	if store then
		task.spawn(pcall, function()
			store:SetAsync(tostring(player.UserId), score)
		end)
	end
	drawBoards()
end

---------------------------------------------------------------------
-- Partidas
---------------------------------------------------------------------
local function startGame(player: Player, gameId: string)
	local info = Arcade.Games[gameId]
	if not info or sessions[player] or not DataService.get(player) then
		return
	end
	if not Stages.allows(player:GetAttribute("LifeStage"), "Arcade", { Arcade = Arcade.Stage }) then
		Notify:FireClient(player, "Error", "Eres demasiado pequeño para jugar a las máquinas.")
		return
	end
	if not DataService.spend(player, info.Price) then
		Notify:FireClient(player, "Error", "Necesitas " .. Format.money(info.Price) .. " para jugar.")
		return
	end
	local session = { Token = HttpService:GenerateGUID(false), GameId = gameId, Start = os.clock() }
	sessions[player] = session
	Remote:FireClient(player, "Play", session.Token, gameId, info)
end

local function endGame(player: Player, token: any, result: any)
	local session = sessions[player]
	if not session or session.Token ~= token then
		return
	end
	sessions[player] = nil
	local info = Arcade.Games[session.GameId]
	local elapsed = os.clock() - session.Start
	if elapsed < info.MinSeconds then
		Notify:FireClient(player, "Error", "Partida no válida.")
		return
	end
	local score = 0
	if session.GameId == "Bolas" and typeof(result) == "table" then
		for i = 1, math.min(#result, info.Balls) do
			local power = result[i]
			if typeof(power) == "number" then
				score += Gameplay.bolasScore(math.clamp(power, 0, 1))
			end
		end
	elseif session.GameId == "Canasta" and typeof(result) == "number" then
		score = math.floor(result)
	end
	score = math.clamp(score, 0, info.MaxScore)
	-- La Suerte del personaje da algún ticket de más
	local tickets = math.floor(score / info.TicketsPer * (1 + 0.02 * (player:GetAttribute("Stat_Suerte") or 0)))
	local data = DataService.get(player)
	if data then
		ensure(data)
		data.Tickets += tickets
		sync(player)
	end
	Notify:FireClient(player, "Money", ("%s: %d puntos · 🎟 +%d tickets"):format(info.Name, score, tickets))
	recordScore(player, session.GameId, score)
	StoryEvents.emit(player, "ArcadePlayed", { GameId = session.GameId, Score = score, Tickets = tickets })
end

local function redeem(player: Player, prizeId: any)
	local prize = typeof(prizeId) == "string" and Gameplay.Prizes[prizeId]
	local data = DataService.get(player)
	if not prize or not data then
		return
	end
	ensure(data)
	local owned = if prize.Kind == "Wear" then data.Prizes[prizeId] elseif prize.Kind == "Vehicle" then data.Vehicles and data.Vehicles[prizeId] else false
	if owned then
		Notify:FireClient(player, "Info", "Ya tienes " .. prize.Name .. ".")
		return
	end
	if data.Tickets < prize.Tickets then
		Notify:FireClient(player, "Error", ("Te faltan %d tickets."):format(prize.Tickets - data.Tickets))
		return
	end
	data.Tickets -= prize.Tickets
	data.Prizes[prizeId] = true
	if prize.Kind == "Vehicle" then
		VehicleService.grant(player, prizeId)
	elseif prize.Kind == "Wear" then
		data.Wearing[prizeId] = true
		applyWearables(player)
	end
	sync(player)
	Notify:FireClient(player, "Success", ("%s ¡Has conseguido: %s!"):format(prize.Icon, prize.Name))
	StoryEvents.emit(player, "PrizeRedeemed", { Prize = prizeId })
end

local function toggleWear(player: Player, prizeId: any)
	local prize = typeof(prizeId) == "string" and Gameplay.Prizes[prizeId]
	local data = DataService.get(player)
	if not prize or prize.Kind ~= "Wear" or not data then
		return
	end
	ensure(data)
	if not data.Prizes[prizeId] then
		return
	end
	data.Wearing[prizeId] = not data.Wearing[prizeId] or nil
	applyWearables(player)
	sync(player)
end

---------------------------------------------------------------------

local function setupMachine(machine: Instance)
	if not machine:IsA("BasePart") then
		return
	end
	local gameId = machine:GetAttribute("GameId")
	local info = Arcade.Games[gameId]
	if not info then
		return
	end
	local prompt = Builder.prompt(machine, "Jugar", ("%s · %s"):format(info.Name, Format.money(info.Price)), 0.2)
	prompt.MaxActivationDistance = 8
	prompt.Triggered:Connect(function(player)
		startGame(player, gameId)
	end)
end

local function setupCounter(counter: Instance)
	if not counter:IsA("BasePart") then
		return
	end
	local prompt = Builder.prompt(counter, "Canjear premios", "Mostrador de premios", 0)
	prompt.Triggered:Connect(function(player)
		sync(player)
		Remote:FireClient(player, "Prizes")
	end)
end

local function setupBoard(board: Instance)
	if not board:IsA("BasePart") then
		return
	end
	local label = Builder.sign(board, "🏆 RÉCORDS", Enum.NormalId.Front, Color3.fromRGB(255, 230, 90))
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent.Name = "RecordsGui"
	table.insert(boards, board)
end

function ArcadeService.init()
	for _, machine in CollectionService:GetTagged("ArcadeMachine") do
		setupMachine(machine)
	end
	for _, counter in CollectionService:GetTagged("PrizeCounter") do
		setupCounter(counter)
	end
	for _, board in CollectionService:GetTagged("ArcadeScoreboard") do
		setupBoard(board)
	end
	CollectionService:GetInstanceAddedSignal("ArcadeMachine"):Connect(setupMachine)
	CollectionService:GetInstanceAddedSignal("PrizeCounter"):Connect(setupCounter)
	CollectionService:GetInstanceAddedSignal("ArcadeScoreboard"):Connect(setupBoard)

	DataService.onLoaded(function(player, data)
		ensure(data)
		for gameId, score in data.ArcadeBest do
			localBest[gameId] = localBest[gameId] or {}
			localBest[gameId][player.UserId] = { Name = player.Name, Score = score }
		end
		sync(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)
			task.wait(1) -- después de que LifeService ajuste el tamaño
			applyWearables(player)
		end)
		if player.Character then
			applyWearables(player)
		end
		drawBoards()
	end)

	Remote.OnServerEvent:Connect(function(player, action, a, b)
		if action == "Result" then
			endGame(player, a, b)
		elseif action == "Cancel" then
			local session = sessions[player]
			if session and session.Token == a then
				sessions[player] = nil
			end
		elseif action == "Redeem" then
			redeem(player, a)
		elseif action == "Wear" then
			toggleWear(player, a)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)

	task.spawn(function()
		while true do
			refreshGlobal()
			task.wait(60)
		end
	end)
end

return ArcadeService
