-- SeaCivService (servidor): la FASE 1 de la civilización de los Hondarios (docs/mar/civilizacion-marina.md).
--
--   * Cuando la plaza de la fase 0 está hecha (workspace.NacaraReady), World/NacaraCityBuilder construye
--     el resto de Nácara y La Burbuja (UNA vez) y aquí se pone la gente nueva (shared/Sea/Civ.People:
--     Maresa, Bartolo, Tomé, Lía y la Guardia del Consejo), vestida como los de la plaza
--     (NacaraService.dressHondario: cola, cresta, peto de nácar; siempre vestidos).
--   * Rutinas: cada persona tiene sus sitios según la hora del juego (Civ.spotAt). Se la cambia de sitio
--     solo cuando no hay nadie cerca de donde está ni de donde va (sin teletransportes delante de ti).
--   * «Hablar» con los Hondarios (los nuevos y los de la plaza, Ilun y Oriana): si tu historia del mar te
--     pide hablar con esa persona (paso Event «MarTalk» con su Npc), suena la conversación de la misión
--     (sus frases son del guion: docs/historia/reescritura/Mar_*.md → Guiones/) y, al acabar, se avisa a
--     la historia (StoryEvents «MarTalk» { Npc }). Si no, una charla corta suya.
--   * Viviendas del mar (conchas de alquiler y camas de la posada): «Alquilar» (Civ.Rent €) apunta la
--     concha en data.Sea.Civ.Home (clave MarCasa_…, que nunca choca con las de Valmar). La hamaca es una
--     cama de verdad (SleepService): al dormir, es tu punto de reaparición.
--   * La historia y los oficios del mar: ver más abajo (startStory, MarStep) y Services/MarJobService.
-- Datos guardados (los crea el servidor si faltan, también en partidas viejas): data.Sea.Civ =
-- { Home = "MarCasa_…" | "", Rep = { Consejo = n } }. Sin DataStores nuevos.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameClock = require(ReplicatedStorage.Shared.GameClock)
local Format = require(ReplicatedStorage.Shared.Format)
local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local Civ = require(ReplicatedStorage.Shared.Sea.Civ)
local NacaraCityBuilder = require(script.Parent.Parent.World.NacaraCityBuilder)
local Npc = require(script.Parent.Parent.World.Npc)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)

local SeaCivService = {}

SeaCivService.People = {} :: { [string]: Model }
SeaCivService.Stats = { People = 0, PeopleParts = 0 }
SeaCivService.WaitPlaza = 900
SeaCivService.RoutineEvery = 10
SeaCivService.WatchRange = 70 -- nadie a menos de esto para cambiar a alguien de sitio

local V = Vector3.new
local CF = CFrame.new

local notify: RemoteEvent? = nil

local function service(name: string): any
	local ok, result = pcall(function()
		return require(script.Parent[name])
	end)
	return if ok then result else nil
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

---------------------------------------------------------------------
-- Datos (data.Sea.Civ)
---------------------------------------------------------------------
function SeaCivService.civOf(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	data.Sea = if type(data.Sea) == "table" then data.Sea else {}
	local civ = data.Sea.Civ
	if type(civ) ~= "table" then
		civ = {}
		data.Sea.Civ = civ
	end
	civ.Home = if type(civ.Home) == "string" and Civ.HomeByKey[civ.Home] then civ.Home else ""
	civ.Rep = if type(civ.Rep) == "table" then civ.Rep else {}
	civ.Rep.Consejo = tonumber(civ.Rep.Consejo) or 0
	return civ
end

function SeaCivService.addRep(player: Player, faction: string, amount: number)
	local civ = SeaCivService.civOf(player)
	if civ then
		civ.Rep[faction] = math.clamp((tonumber(civ.Rep[faction]) or 0) + amount, -100, 100)
	end
end

---------------------------------------------------------------------
-- Viviendas
---------------------------------------------------------------------
-- Apunta la vivienda del mar (free = sin pagar: la de la vida hondaria de pruebas)
function SeaCivService.setHome(player: Player, key: string, free: boolean?): boolean
	local home = Civ.HomeByKey[key]
	local civ = SeaCivService.civOf(player)
	if not home or not civ then
		return false
	end
	if civ.Home == key then
		return true
	end
	if not free then
		local Data = service("DataService")
		if not Data or not Data.spend(player, Civ.Rent) then
			toast(player, "Error", ("Te faltan %s para alquilar %s."):format(Format.money(Civ.Rent), home.Name))
			return false
		end
	end
	civ.Home = key
	player:SetAttribute("MarHome", key)
	if not free then
		toast(player, "Success", ("🐚 Has alquilado %s. Duerme en la hamaca para que sea tu punto de reaparición."):format(home.Name))
	end
	StoryEvents.emit(player, "MarHome", { Key = key })
	return true
end

local function homePrompt(board: Instance)
	if not board:IsA("BasePart") then
		return
	end
	local key = board:GetAttribute("HomeKey")
	local home = Civ.HomeByKey[key or ""]
	if not home or board:FindFirstChild("MarHomePrompt") then
		return
	end
	local p = Instance.new("ProximityPrompt")
	p.Name = "MarHomePrompt"
	p.ActionText = ("Alquilar · %s"):format(Format.money(Civ.Rent))
	p.ObjectText = home.Name
	p.HoldDuration = 0.4
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p:SetAttribute("MinStage", "AdultoJoven")
	p.Parent = board
	p.Triggered:Connect(function(player: Player)
		local civ = SeaCivService.civOf(player)
		if civ and civ.Home == key then
			toast(player, "Info", ("🐚 %s ya es tuya. Duerme en la hamaca para reaparecer aquí."):format(home.Name))
			return
		end
		SeaCivService.setHome(player, key)
	end)
end

---------------------------------------------------------------------
-- La gente
---------------------------------------------------------------------
local function setHomeCf(model: Model, cf: CFrame)
	model:SetAttribute("Home", cf)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = cf
	end
end

local function facing(person: { [string]: any }, at: Vector3, y: number): CFrame
	local face = if person.Face then Civ.personWorld(person, person.Face[1], person.Face[2], y) else Nacara.centerPosition() + V(0, y, 0)
	local dir = (face - at) * V(1, 0, 1)
	local yaw = if dir.Magnitude > 0.1 then math.atan2(-dir.X, -dir.Z) else 0
	return CF(at) * CFrame.Angles(0, yaw, 0)
end

function SeaCivService.spawnPerson(person: { [string]: any }, parent: Instance, hour: number?): Model?
	local NacaraService = service("NacaraService")
	local x, z, y = Civ.spotAt(person, hour or 12)
	local at = Civ.personWorld(person, x, z, y)
	local look = person.Look
	local model = Npc.create("Hondario_" .. person.Id, parent, facing(person, at, y), {
		Skin = look.Skin,
		Shirt = look.Tunic,
		Pants = look.Scales,
		Shoes = look.Scales,
		Hair = look.Hair,
		LongSleeves = false,
		LongHair = person.Role ~= "Guard",
		Id = "Nacara:" .. person.Id, -- (su cara con textura: shared/LifeStory/CastLook)
	})
	local count = if NacaraService then NacaraService.dressHondario(model, person) else 0
	if not NacaraCityBuilder.take(count) then
		warn(("[SeaCiv] sin presupuesto de piezas para %s (%d)"):format(person.Id, count))
		model:Destroy()
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		setHomeCf(model, root.CFrame)
	end
	model:SetAttribute("NpcId", person.Id)
	model:SetAttribute("HondarioRole", person.Role)
	model:SetAttribute("BobSeed", (#person.Id * 5.1) % 6.28)
	model:SetAttribute("Spot", ("%d,%d"):format(x, z))
	CollectionService:AddTag(model, "HondarioNpc")
	SeaCivService.People[person.Id] = model
	SeaCivService.Stats.People += 1
	SeaCivService.Stats.PeopleParts += count
	return model
end

-- Un Hondario por su id (los de la fase 1 y los de la plaza)
function SeaCivService.modelOf(id: string): Model?
	local m = SeaCivService.People[id]
	if m and m.Parent then
		return m
	end
	local NacaraService = service("NacaraService")
	local other = NacaraService and NacaraService.People[id]
	return if other and other.Parent then other else nil
end

local function anyoneNear(points: { Vector3 }, range: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root then
			for _, p in points do
				if (root.Position - p).Magnitude < range then
					return true
				end
			end
		end
	end
	return false
end

-- Las rutinas: cada uno a su sitio de esta hora (si nadie mira)
function SeaCivService.routineTick(hour: number?): number
	local h = hour or GameClock.hour()
	local moved = 0
	for _, person in Civ.People do
		local model = SeaCivService.People[person.Id]
		if model and person.Routine and not model:GetAttribute("Busy") then
			local x, z, y = Civ.spotAt(person, h)
			local key = ("%d,%d"):format(x, z)
			if model:GetAttribute("Spot") ~= key then
				local now = model:GetAttribute("Home")
				local to = Civ.personWorld(person, x, z, y)
				local from = if typeof(now) == "CFrame" then (now :: CFrame).Position else to
				if not anyoneNear({ from, to }, SeaCivService.WatchRange) then
					setHomeCf(model, facing(person, to, y))
					model:SetAttribute("Spot", key)
					moved += 1
				end
			end
		end
	end
	return moved
end

---------------------------------------------------------------------
-- Charlas
---------------------------------------------------------------------
-- Charlas cortas de cada uno cuando la historia no pide nada (sin efectos)
SeaCivService.SmallTalk = {
	Maresa = { { S = "Maresa", T = "El Consejo de las Corrientes escucha a quien sirve a una Corriente. Los demás, que naden con cuidado." } },
	Bartolo = { { S = "Bartolo", T = "¡Auténticas piezas de barco pirata! Bueno, de pedal de playa. Pero con mucha historia, ¿eh?" } },
	Tome = { { S = "Tomé", T = "Las algas no tienen prisa. Los caracoles, en cambio, siempre tienen hambre." }, { S = "Tomé", T = "Si quieres echar una mano, el tablón de «Trabajar» está junto a los bancales." } },
	Lia = { { S = "Lía", T = "Cuando se apaga una perla-farola, lo hondo se acerca un poco. Por eso las cargamos antes de la noche." }, { S = "Lía", T = "El tablón de los faroleros está en el paseo. Paga bien… para ser luz." } },
	GuardiaConsejo = { { S = "Guardia del Consejo", T = "Sin redes en la ciudad y sin prisas en la Concha. La Guardiana está ocupada." } },
}

-- El paso de tu historia del mar que pide hablar con esta persona: misión, nombre de la conversación
function SeaCivService.storyTalk(player: Player, npcId: string): (string?, string?)
	local data = DataService.get(player)
	local story = data and data.Story
	if type(story) ~= "table" or type(story.Active) ~= "table" then
		return nil, nil
	end
	local okQ, Quests = pcall(function()
		return require(ReplicatedStorage.Shared.LifeStory.Quests)
	end)
	if not okQ then
		return nil, nil
	end
	for questId, prog in story.Active do
		local quest = Quests[questId]
		if quest and string.sub(questId, 1, 4) == "Mar_" and type(prog) == "table" then
			local steps = prog.Steps or quest.Steps
			local step = steps and steps[prog.Step]
			local list = if step and step.Type == "Group" then step.Steps else { step }
			for i, s in list or {} do
				local done = step and step.Type == "Group" and prog.Sub and prog.Sub[tostring(i)]
				if s and not done and s.Type == "Event" and s.Event == "MarTalk" and s.Match and s.Match.Npc == npcId then
					return questId, s.Dialogue
				end
			end
		end
	end
	return nil, nil
end

function SeaCivService.talk(player: Player, npcId: string): boolean
	if player:GetAttribute("InDialogue") then
		return false
	end
	local DialogueService = service("DialogueService")
	local model = SeaCivService.modelOf(npcId)
	if not DialogueService or not model then
		return false
	end
	local questId, dialogueName = SeaCivService.storyTalk(player, npcId)
	local lines: { any }? = nil
	if questId and dialogueName then
		local okQ, Quests = pcall(function()
			return require(ReplicatedStorage.Shared.LifeStory.Quests)
		end)
		local d = okQ and Quests[questId] and Quests[questId].Dialogues and Quests[questId].Dialogues[dialogueName]
		lines = d and d.Lines
	end
	if not lines then
		lines = SeaCivService.SmallTalk[npcId]
		questId = nil
	end
	if not lines then
		return false
	end
	model:SetAttribute("Busy", true)
	local context = {
		actorOf = function(speaker: string): Instance?
			return SeaCivService.modelOf(speaker) or (if speaker == npcId then model else nil)
		end,
		apply = function() end,
		check = function()
			return true
		end,
		args = function()
			local a: { [string]: any } = { nombre = player.DisplayName }
			local gender = player:GetAttribute("Gender")
			if gender ~= nil then
				a.genero = gender
			end
			return a
		end,
	}
	local ok = DialogueService.play(player, { Lines = lines }, context, function()
		model:SetAttribute("Busy", nil)
		if questId then
			StoryEvents.emit(player, "MarTalk", { Npc = npcId })
		end
	end, function()
		model:SetAttribute("Busy", nil)
	end)
	if not ok then
		model:SetAttribute("Busy", nil)
	end
	return ok == true
end

local function talkPrompt(model: Model, person: { [string]: any })
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or root:FindFirstChild("MarPrompt") or root:FindFirstChild("NacaraPrompt") then
		return
	end
	local p = Instance.new("ProximityPrompt")
	p.Name = "MarPrompt"
	p.ActionText = "Hablar"
	p.ObjectText = ("%s · %s"):format(person.Name, person.Title or "")
	p.HoldDuration = 0.2
	p.MaxActivationDistance = 13
	p.RequiresLineOfSight = false
	p.Parent = root
	p.Triggered:Connect(function(player: Player)
		SeaCivService.talk(player, person.Id)
	end)
end

---------------------------------------------------------------------
-- La historia del mar (se completa en el paso B: misiones Mar_…)
---------------------------------------------------------------------
SeaCivService.FirstMission = "Mar_00_Arrecife"

-- La vida hondaria de pruebas empieza la historia sola (si no la has hecho)
function SeaCivService.startStory(player: Player): boolean
	local LifeStoryService = service("LifeStoryService")
	if not LifeStoryService or not LifeStoryService.startCanon then
		return false
	end
	local ok, started = pcall(LifeStoryService.startCanon, player, SeaCivService.FirstMission)
	return ok and started == true
end

---------------------------------------------------------------------

function SeaCivService.setup(terrain: any?)
	NacaraCityBuilder.build(terrain)
	local people = Instance.new("Folder")
	people.Name = "Hondarios"
	people.Parent = NacaraCityBuilder.folder()
	local hour = 12
	pcall(function()
		hour = GameClock.hour()
	end)
	for _, person in Civ.People do
		local ok, model = pcall(SeaCivService.spawnPerson, person, people, hour)
		if not ok then
			warn("[SeaCiv] " .. tostring(model))
		elseif model and person.Role == "Quest" then
			talkPrompt(model, person)
		end
	end
	for _, board in CollectionService:GetTagged("MarHome") do
		homePrompt(board)
	end
	print(("[SeaCiv] %d Hondarios nuevos (%d piezas). Fase 1: %d piezas de %d"):format(SeaCivService.Stats.People, SeaCivService.Stats.PeopleParts, NacaraCityBuilder.Stats.Parts, Civ.Budget))
end

function SeaCivService.init()
	notify = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Notify") :: RemoteEvent?
	CollectionService:GetInstanceAddedSignal("MarHome"):Connect(homePrompt)
	DataService.onLoaded(function(player)
		local civ = SeaCivService.civOf(player)
		if civ and civ.Home ~= "" then
			player:SetAttribute("MarHome", civ.Home)
		end
	end)
	task.spawn(function()
		local waited = 0
		while not workspace:GetAttribute("NacaraReady") and waited < SeaCivService.WaitPlaza do
			task.wait(1)
			waited += 1
		end
		local ok, err = pcall(SeaCivService.setup)
		if not ok then
			warn("[SeaCiv] " .. tostring(err))
		end
		while true do
			task.wait(SeaCivService.RoutineEvery)
			pcall(SeaCivService.routineTick)
		end
	end)
end

return SeaCivService
