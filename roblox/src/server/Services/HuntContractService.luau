-- HuntContractService: los CONTRATOS DE CAZA (las cuentas, en shared/HuntContracts).
--
--   * TABLONES DE CAZA: uno junto a la puerta de la Academia (Distrito Central) y uno en cada campamento de las
--     Tierras Exteriores (shared/Cosmos/OuterLands.Bridges). «Ver contratos» abre una conversación con los
--     contratos de hoy para tu nivel; eliges uno (o ninguno).
--   * Como mucho HuntContracts.MaxActive a la vez; el mismo contrato no se coge dos veces el mismo día.
--   * Cada bestia que cae (BeastService → StoryEvents «BeastKilled», con su Region) suma a los contratos que
--     cuadran. Al completar uno se cobra solo: dinero, experiencia (ProgressionService) y pociones de curación.
--   * El cliente los ve en el atributo HuntContracts (JSON: Title, Reward, Have, Need) en el panel de misiones
--     (UI/Hud). Remoto HuntContracts: "Abandon" (índice) para dejar uno.
-- Se guarda en data.Hunt = { Day, Taken = { [Key] = true }, Active = { contratos }, Done = n }.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HuntContracts = require(ReplicatedStorage.Shared.HuntContracts)
local DataService = require(script.Parent.DataService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local HuntContractService = {}

local Notify: RemoteEvent? = nil
local Remote: RemoteEvent? = nil

local function tell(player: Player, kind: string, text: string)
	if Notify then
		Notify:FireClient(player, kind, text)
	end
end

local function service(name: string): any?
	local ok, mod = pcall(function()
		return require(script.Parent[name]) :: any
	end)
	return if ok then mod else nil
end

-- Los contratos del jugador (con el día al día: lo cogido ayer ya se puede volver a coger)
local function huntOf(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local h = data.Hunt
	if type(h) ~= "table" then
		h = { Day = 0, Taken = {}, Active = {}, Done = 0 }
		data.Hunt = h
	end
	h.Taken = if type(h.Taken) == "table" then h.Taken else {}
	h.Active = if type(h.Active) == "table" then h.Active else {}
	local today = HuntContracts.day()
	if h.Day ~= today then
		h.Day = today
		h.Taken = {}
	end
	return h
end

local function levelOf(player: Player): number
	return math.max(1, tonumber(player:GetAttribute("Level")) or 1)
end

function HuntContractService.publish(player: Player)
	local h = huntOf(player)
	if not h then
		return
	end
	local list = {}
	for _, c in h.Active do
		table.insert(list, { Title = HuntContracts.title(c), Reward = HuntContracts.rewardText(c), Have = c.Have, Need = c.Need })
	end
	player:SetAttribute("HuntContracts", if #list > 0 then HttpService:JSONEncode(list) else nil)
end

-- Los contratos de hoy que aún se pueden coger
function HuntContractService.offers(player: Player): { HuntContracts.Contract }
	local h = huntOf(player)
	if not h then
		return {}
	end
	local out = {}
	for _, c in HuntContracts.offers(levelOf(player), player.UserId, h.Day) do
		local active = false
		for _, a in h.Active do
			if a.Key == c.Key then
				active = true
			end
		end
		if not h.Taken[c.Key] and not active then
			table.insert(out, c)
		end
	end
	return out
end

function HuntContractService.accept(player: Player, key: string): (boolean, string?)
	local h = huntOf(player)
	if not h then
		return false, "Sin datos"
	end
	if #h.Active >= HuntContracts.MaxActive then
		return false, ("Ya llevas %d contratos: acaba o deja alguno."):format(HuntContracts.MaxActive)
	end
	for _, c in HuntContractService.offers(player) do
		if c.Key == key then
			h.Taken[key] = true
			table.insert(h.Active, c)
			HuntContractService.publish(player)
			tell(player, "Success", "📜 Contrato aceptado: " .. HuntContracts.title(c))
			return true, nil
		end
	end
	return false, "Ese contrato ya no está en el tablón."
end

function HuntContractService.abandon(player: Player, index: number): boolean
	local h = huntOf(player)
	if not h or not h.Active[index] then
		return false
	end
	local c = table.remove(h.Active, index)
	HuntContractService.publish(player)
	tell(player, "Info", "📜 Has dejado el contrato: " .. HuntContracts.title(c))
	return true
end

local function pay(player: Player, c: HuntContracts.Contract)
	DataService.addMoney(player, c.Money, true)
	local P = service("ProgressionService")
	if P and P.addXp then
		pcall(P.addXp, player, c.Xp, "HuntContract")
	end
	local Inv = service("InventoryService")
	if Inv and Inv.add and c.Potions > 0 then
		pcall(Inv.add, player, "PocionCuracion", c.Potions)
	end
	tell(player, "Success", ("📜 ¡Contrato cumplido! %s · %s"):format(HuntContracts.title(c), HuntContracts.rewardText(c)))
end

-- Una bestia ha caído (ev: Species, Region, Boss, Planet)
function HuntContractService.onKill(player: Player, ev: { [string]: any })
	local h = huntOf(player)
	if not h or #h.Active == 0 then
		return
	end
	local changed = false
	for i = #h.Active, 1, -1 do
		local c = h.Active[i]
		if HuntContracts.matches(c, ev) then
			c.Have = math.min(c.Need, (tonumber(c.Have) or 0) + 1)
			changed = true
			if c.Have >= c.Need then
				table.remove(h.Active, i)
				h.Done = (tonumber(h.Done) or 0) + 1
				pay(player, c)
			end
		end
	end
	if changed then
		HuntContractService.publish(player)
	end
end

---------------------------------------------------------------------
-- El tablón
---------------------------------------------------------------------
function HuntContractService.openBoard(player: Player)
	local Dialogue = service("DialogueService")
	local h = huntOf(player)
	if not h then
		return
	end
	if #h.Active >= HuntContracts.MaxActive then
		tell(player, "Info", ("📜 Ya llevas %d contratos de caza. Acaba alguno (o déjalo en Misiones) y vuelve."):format(HuntContracts.MaxActive))
		return
	end
	local offers = HuntContractService.offers(player)
	if #offers == 0 then
		tell(player, "Info", "📜 Hoy ya no quedan contratos para ti. Mañana habrá más.")
		return
	end
	if not Dialogue or (Dialogue.isBusy and Dialogue.isBusy(player)) then
		return
	end
	local options = {}
	for _, c in offers do
		table.insert(options, { T = ("%s (%s)"):format(HuntContracts.title(c), HuntContracts.rewardText(c)), Effects = { HuntAccept = c.Key } })
	end
	table.insert(options, { T = "Ahora no" })
	local lines = {
		{ S = "Narrador", T = ("Tablón de caza. Contratos de hoy para nivel %d. Llevas %d de %d."):format(levelOf(player), #h.Active, HuntContracts.MaxActive) },
		{ Ask = "¿Qué contrato coges?", Options = options },
	}
	Dialogue.play(player, { Lines = lines }, {
		apply = function(effects)
			if type(effects) == "table" and type(effects.HuntAccept) == "string" then
				local ok, why = HuntContractService.accept(player, effects.HuntAccept)
				if not ok and why then
					tell(player, "Error", "📜 " .. why)
				end
			end
		end,
	})
end

local function buildBoard(parent: Instance, cf: CFrame, name: string)
	local Builder = require(script.Parent.Parent.World.Builder) :: any
	local rgb = Color3.fromRGB
	local m = Builder.model("TablonCaza", parent)
	m:SetAttribute("Name", name)
	for _, side in { -1, 1 } do
		Builder.part({ Name = "Poste", Size = Vector3.new(0.8, 8, 0.8), CFrame = cf * CFrame.new(side * 3.4, 4, 0), Color = rgb(96, 70, 46), Material = Enum.Material.Wood, Parent = m })
	end
	local board = Builder.part({ Name = "Tablon", Size = Vector3.new(7.6, 4.4, 0.5), CFrame = cf * CFrame.new(0, 5.4, 0), Color = rgb(128, 94, 60), Material = Enum.Material.WoodPlanks, Parent = m })
	Builder.part({ Name = "Tejadillo", Size = Vector3.new(8.6, 0.5, 1.8), CFrame = cf * CFrame.new(0, 7.9, 0) * CFrame.Angles(math.rad(-12), 0, 0), Color = rgb(70, 50, 34), Material = Enum.Material.Wood, Parent = m })
	-- papeles clavados
	for i, off in { { -2.4, 0.6 }, { -0.6, -0.5 }, { 1.2, 0.7 }, { 2.6, -0.4 } } do
		Builder.part({ Name = "Papel", Size = Vector3.new(1.4, 1.7, 0.06), CFrame = cf * CFrame.new(off[1], 5.4 + off[2], -0.3) * CFrame.Angles(0, 0, math.rad((i % 2 == 0 and 4 or -5))), Color = rgb(236, 226, 200), Material = Enum.Material.SmoothPlastic, CanCollide = false, CastShadow = false, Parent = m })
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Cartel"
	gui.Size = UDim2.fromOffset(170, 34)
	gui.StudsOffset = Vector3.new(0, 4.4, 0)
	gui.MaxDistance = 90
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = rgb(30, 22, 16)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = rgb(255, 214, 140)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "📜 Tablón de caza"
	label.Parent = gui
	local prompt = Builder.prompt(board, "Ver contratos", "Tablón de caza", 0)
	prompt.Triggered:Connect(function(player)
		HuntContractService.openBoard(player)
	end)
	return m
end

function HuntContractService.buildBoards()
	local folder = workspace:FindFirstChild("TablonesCaza")
	if folder then
		return folder
	end
	folder = Instance.new("Folder")
	folder.Name = "TablonesCaza"
	folder.Parent = workspace
	-- la Academia (la puerta del cole: etiqueta SchoolEntrance)
	local CollectionService = game:GetService("CollectionService")
	local entrance = CollectionService:GetTagged("SchoolEntrance")[1]
	if entrance then
		local cf = if entrance:IsA("BasePart") then entrance.CFrame elseif entrance:IsA("Model") then entrance:GetPivot() else nil
		if cf then
			local at = cf.Position + cf.RightVector * 14
			local hit = workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0))
			local y = if hit then hit.Position.Y else at.Y
			pcall(buildBoard, folder, CFrame.lookAt(Vector3.new(at.X, y, at.Z), Vector3.new(at.X, y, at.Z) - cf.LookVector), "Academia")
		end
	end
	-- los campamentos de las Tierras Exteriores
	task.spawn(function()
		local t0 = os.clock()
		while not workspace:GetAttribute("TierrasReady") and os.clock() - t0 < 900 do
			task.wait(3)
		end
		local OuterLands = require(ReplicatedStorage.Shared.Cosmos.OuterLands)
		for _, b in OuterLands.Bridges do
			local c = Vector3.new(b.CampX, OuterLands.CampY, b.CampZ)
			local at = c + Vector3.new(-22, 0, 14)
			pcall(buildBoard, folder, CFrame.lookAt(at, c), "Campamento" .. b.Id)
		end
	end)
	return folder
end

function HuntContractService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local r = remotes:FindFirstChild("HuntContracts") :: RemoteEvent?
	if not r then
		local made = Instance.new("RemoteEvent")
		made.Name = "HuntContracts"
		made.Parent = remotes
		r = made
	end
	Remote = r
	;(r :: RemoteEvent).OnServerEvent:Connect(function(player, action, a)
		if action == "Abandon" and type(a) == "number" then
			HuntContractService.abandon(player, math.floor(a))
		end
	end)
	StoryEvents.connect(function(player, name, payload)
		if name == "BeastKilled" then
			HuntContractService.onKill(player, payload)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			-- (cuando ya están sus datos)
			for _ = 1, 30 do
				task.wait(2)
				if not player.Parent then
					return
				end
				if DataService.get(player) then
					HuntContractService.publish(player)
					return
				end
			end
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(HuntContractService.publish, player)
	end
	task.delay(8, function()
		local ok, err = pcall(HuntContractService.buildBoards)
		if not ok then
			warn("[HuntContracts] tablones: " .. tostring(err))
		end
	end)
end

return HuntContractService
