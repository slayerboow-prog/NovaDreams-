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
--   * La historia y los oficios del mar: más abajo (charlas de las misiones, personas que se mueven por la historia, la persecución del kelp y el mapa) y Services/MarJobService.
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
local NacaraV2 = require(ReplicatedStorage.Shared.Sea.NacaraV2)
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

-- La misión del mar que ahora te pide hablar con esta persona (un paso Talk con su Npc, o un hijo de un
-- Group sin hacer). nil = ninguna.
local function questsModule(): any
	local ok, Quests = pcall(function()
		return require(ReplicatedStorage.Shared.LifeStory.Quests)
	end)
	return if ok then Quests else nil
end

function SeaCivService.storyStep(player: Player, questId: string): ({ [string]: any }?, { [string]: any }?)
	local data = DataService.get(player)
	local story = data and data.Story
	local prog = type(story) == "table" and type(story.Active) == "table" and story.Active[questId] or nil
	local Quests = questsModule()
	local quest = Quests and Quests[questId]
	if type(prog) ~= "table" or not quest then
		return nil, nil
	end
	local steps = prog.Steps or quest.Steps
	return steps and steps[prog.Step], prog
end

function SeaCivService.storyTalk(player: Player, npcId: string): string?
	local data = DataService.get(player)
	local story = data and data.Story
	if type(story) ~= "table" or type(story.Active) ~= "table" then
		return nil
	end
	for questId in story.Active do
		if string.sub(questId, 1, 4) == "Mar_" then
			local step, prog = SeaCivService.storyStep(player, questId)
			if step and step.Type == "Talk" and step.Npc == npcId then
				return questId
			elseif step and step.Type == "Group" then
				for i, child in step.Steps or {} do
					if child.Type == "Talk" and child.Npc == npcId and not ((prog :: any).Sub and (prog :: any).Sub[tostring(i)]) then
						return questId
					end
				end
			end
		end
	end
	return nil
end

-- «Hablar» con un Hondario: si tu historia del mar te lo pide, la conversación de la misión (la lleva
-- LifeStoryService, con sus efectos y su aviso TalkDone); si no, su charla corta.
function SeaCivService.talk(player: Player, npcId: string): boolean
	if player:GetAttribute("InDialogue") then
		return false
	end
	local questId = SeaCivService.storyTalk(player, npcId)
	if questId then
		local LifeStoryService = service("LifeStoryService")
		if LifeStoryService then
			LifeStoryService.interact(player, "Actor", questId, npcId)
			return true
		end
	end
	local DialogueService = service("DialogueService")
	local model = SeaCivService.modelOf(npcId)
	local lines = SeaCivService.SmallTalk[npcId]
	if not DialogueService or not model or not lines then
		return false
	end
	local context = {
		actorOf = function(speaker: string): Instance?
			return SeaCivService.modelOf(speaker) or (if speaker == npcId then model else nil)
		end,
		apply = function() end,
		check = function()
			return true
		end,
	}
	return DialogueService.play(player, { Lines = lines }, context) == true
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
-- La historia del mar (misiones Mar_…: shared/LifeStory/Misiones/Mar_Acto1)
---------------------------------------------------------------------
-- Dónde tiene que estar alguien mientras tu misión le necesita en otro sitio: { Quest, Steps, Npc, Spot
-- (Civ.StorySpots), Offset = { x, y sobre el suelo, z } }
SeaCivService.StoryCalls = {
	{ Quest = "Mar_00_Arrecife", Steps = { 1, 2, 3 }, Npc = "Ilun", Spot = "Arrecife", Offset = { 0, 6, 4 } },
	{ Quest = "Mar_03_Juicio", Steps = { 2, 3 }, Npc = "Ilun", Spot = "Consejo", Offset = { 10, 6, -6 } },
}

local function callActive(player: Player, call: { [string]: any }): boolean
	local _, prog = SeaCivService.storyStep(player, call.Quest)
	return prog ~= nil and table.find(call.Steps, (prog :: any).Step) ~= nil
end

-- Cada uno, a donde le pide la historia de alguien (o de vuelta a su sitio de siempre)
function SeaCivService.storyTick(): number
	local wanted: { [string]: Vector3 } = {}
	for _, player in Players:GetPlayers() do
		for _, call in SeaCivService.StoryCalls do
			if not wanted[call.Npc] and callActive(player, call) then
				local spot = Civ.SpotById[call.Spot]
				if spot then
					wanted[call.Npc] = Civ.spotPosition(spot) + V(call.Offset[1], call.Offset[2], call.Offset[3])
				end
			end
		end
	end
	local moved = 0
	local seen: { [string]: boolean } = {}
	for _, call in SeaCivService.StoryCalls do
		local id = call.Npc
		if not seen[id] then
			seen[id] = true
			local model = SeaCivService.modelOf(id)
			if model then
				local home = model:GetAttribute("Home")
				local base = model:GetAttribute("BaseHome")
				if base == nil and typeof(home) == "CFrame" then
					model:SetAttribute("BaseHome", home)
					base = home
				end
				local to = wanted[id]
				if to and not model:GetAttribute("Busy") then
					if typeof(home) ~= "CFrame" or ((home :: CFrame).Position - to).Magnitude > 1 then
						setHomeCf(model, CF(to))
						model:SetAttribute("StoryAway", true)
						moved += 1
					end
				elseif not to and model:GetAttribute("StoryAway") and typeof(base) == "CFrame" and not model:GetAttribute("Busy") then
					setHomeCf(model, base :: CFrame)
					model:SetAttribute("StoryAway", nil)
					moved += 1
				end
			end
		end
	end
	return moved
end

---------------------------------------------------------------------
-- La persecución de «Redes cortadas» (Mar_04, paso 3): Sargo huye por el kelp del norte
---------------------------------------------------------------------
SeaCivService.ChaseQuest = "Mar_04_Redes"
SeaCivService.ChaseStep = 3
SeaCivService.MaxChases = 3
type Chase = { Model: Model, D: number, Started: number, Caught: boolean }
local chases: { [Player]: Chase } = {}
SeaCivService._chases = chases
SeaCivService.Clock = os.clock

local function chaseModel(player: Player): Model?
	local count = 0
	for _ in chases do
		count += 1
	end
	if count >= SeaCivService.MaxChases then
		return nil
	end
	local NacaraService = service("NacaraService")
	local look = Civ.Chase.Look
	local person = { Id = "Sargo", Name = "Sargo", Role = "Folk", Look = look }
	local start = Civ.chasePoint(0)
	local model = Npc.create("Hondario_Sargo_" .. tostring(player.UserId), NacaraCityBuilder.folder(), CF(start), {
		Skin = look.Skin,
		Shirt = look.Tunic,
		Pants = look.Scales,
		Shoes = look.Scales,
		Hair = look.Hair,
		LongSleeves = false,
		LongHair = false,
	})
	if NacaraService then
		NacaraService.dressHondario(model, person)
	end
	model:SetAttribute("NpcId", "Sargo")
	model:SetAttribute("ChaseOf", player.UserId)
	model:SetAttribute("BobSeed", 1.7)
	CollectionService:AddTag(model, "HondarioNpc")
	setHomeCf(model, CF(start))
	return model
end

local function endChase(player: Player)
	local c = chases[player]
	chases[player] = nil
	if c and c.Model then
		c.Model:Destroy()
	end
end
SeaCivService.endChase = endChase

-- Un paso de la persecución (dt segundos). Devuelve: "None" | "Run" | "Wait" | "Caught" | "Reset"
function SeaCivService.chaseStep(player: Player, dt: number): string
	local _, prog = SeaCivService.storyStep(player, SeaCivService.ChaseQuest)
	local stepIndex = if prog then (prog :: any).Step else 0
	local c = chases[player]
	-- (Sargo sigue ahí, pillado, mientras toca hablar con él y decidir; luego se va)
	if not prog or stepIndex < SeaCivService.ChaseStep or stepIndex > SeaCivService.ChaseStep + 2 then
		if c then
			endChase(player)
		end
		return "None"
	end
	if not c then
		local model = chaseModel(player)
		if not model then
			return "None"
		end
		if stepIndex ~= SeaCivService.ChaseStep then
			-- (volviste a entrar después de pillarle: está donde acabó la persecución)
			setHomeCf(model, CF(Civ.chasePoint(Civ.chaseLength())))
			chases[player] = { Model = model, D = Civ.chaseLength(), Started = SeaCivService.Clock(), Caught = true }
			return "Caught"
		end
		c = { Model = model, D = 0, Started = SeaCivService.Clock(), Caught = false }
		chases[player] = c
		toast(player, "Info", "🌿 ¡Ahí está, cortando una red! ¡Persíguele!")
	end
	local chase = c :: Chase
	if chase.Caught then
		return "Caught"
	end
	local root = rootOf(player)
	if not root then
		return "Wait"
	end
	local here = Civ.chasePoint(chase.D)
	local dist = (root.CFrame.Position - here).Magnitude
	if dist <= Civ.Chase.Catch then
		chase.Caught = true
		toast(player, "Success", "🖐 ¡Te pillé!")
		StoryEvents.emit(player, "MarChase", { Result = "Caught" })
		return "Caught"
	end
	if SeaCivService.Clock() - chase.Started > Civ.Chase.Seconds then
		chase.D = 0
		chase.Started = SeaCivService.Clock()
		setHomeCf(chase.Model, CF(Civ.chasePoint(0)))
		toast(player, "Info", "🌿 Se te ha escapado entre el kelp… ha vuelto a la red. ¡Otra vez!")
		return "Reset"
	end
	if dist < Civ.Chase.Lead then
		chase.D = math.min(Civ.chaseLength(), chase.D + Civ.Chase.Speed * dt)
		local at, dir = Civ.chasePoint(chase.D)
		setHomeCf(chase.Model, CFrame.lookAt(at, at + dir))
		return "Run"
	end
	return "Wait"
end

-- Quién es quién para la historia (LifeStoryService.worldActor): la gente de Nácara, y tu Sargo
function SeaCivService.worldActor(player: Player, npc: string): Model?
	if npc == "Sargo" then
		local c = chases[player]
		return if c then c.Model else nil
	end
	if Civ.PersonById[npc] == nil and npc ~= "Ilun" and npc ~= "Oriana" then
		return nil
	end
	return SeaCivService.modelOf(npc)
end

---------------------------------------------------------------------
-- El mapa: los sitios de la fase 1 (ReplicatedStorage.MapLandmarks; shared/MapInfo)
---------------------------------------------------------------------
SeaCivService.Landmarks = {
	{ Name = "PuntoMarConchas_Nacara", Kind = "PuntoMarConchas", Area = "Conchas" },
	{ Name = "PuntoMarJardines_Nacara", Kind = "PuntoMarJardines", Area = "Jardines" },
	{ Name = "PuntoMarConsejo_Nacara", Kind = "PuntoMarConsejo", Area = "Consejo" },
	{ Name = "PuntoMarBurbuja_Talud", Kind = "PuntoMarBurbuja", X = Civ.Posada.X, Z = Civ.Posada.Z },
}
function SeaCivService.publishLandmarks(): boolean
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks")
	if not folder then
		return false
	end
	for _, l in SeaCivService.Landmarks do
		if not folder:FindFirstChild(l.Name) then
			local a = l.Area and Civ.AreaById[l.Area]
			local x = if a then Nacara.Center.X + a.X else l.X
			local z = if a then Nacara.Center.Z + a.Z else l.Z
			local config = Instance.new("Configuration")
			config.Name = l.Name
			config:SetAttribute("Kind", l.Kind)
			config:SetAttribute("Position", V(x, 0, z))
			config:SetAttribute("District", "")
			config.Parent = folder
		end
	end
	return true
end

---------------------------------------------------------------------

function SeaCivService.setup(terrain: any?)
	NacaraCityBuilder.build(terrain)
	-- Nácara v2 (prototipo del Palacio Real y la Plaza Central): solo con Config.Sea.NacaraV2 (apagado)
	if NacaraV2.On then
		local ok, err = pcall(function()
			require(script.Parent.Parent.World.NacaraV2Builder).build(terrain)
		end)
		if not ok then
			warn("[SeaCiv] Nácara v2: " .. tostring(err))
		end
	end
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
	-- el decorado del kit del mar, el faro y las boyas: con las mallas si llegan (como mucho un minuto)
	task.spawn(function()
		local meshes = nil
		for _ = 1, 60 do
			meshes = ReplicatedStorage:FindFirstChild("MarMallas")
			if meshes then
				break
			end
			task.wait(1)
		end
		local ok, err = pcall(require(script.Parent.Parent.World.NacaraDecor).build, meshes)
		if not ok then
			warn("[SeaCiv] decorado: " .. tostring(err))
		end
	end)
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
		local since = 0
		while true do
			task.wait(2)
			since += 2
			pcall(SeaCivService.storyTick)
			if since >= SeaCivService.RoutineEvery then
				since = 0
				pcall(SeaCivService.routineTick)
			end
		end
	end)
	-- la persecución (cada quinto de segundo, solo quien la está jugando)
	task.spawn(function()
		while true do
			local dt = task.wait(0.2) or 0.2
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(SeaCivService.chaseStep, player, dt)
				if not ok then
					warn("[SeaCiv] persecución: " .. tostring(err))
				end
			end
		end
	end)
	task.spawn(function()
		for _ = 1, 120 do
			if SeaCivService.publishLandmarks() then
				break
			end
			task.wait(1)
		end
	end)
	pcall(function()
		service("LifeStoryService").worldActor = SeaCivService.worldActor
	end)
	Players.PlayerRemoving:Connect(endChase)
end

return SeaCivService
