-- BabyService: el tutorial de bebé (fase 2, 5-10 minutos) en una casa familiar de Los Pinos.
--
-- Qué hace:
--   * Da a cada bebé una casa familiar del mapa (tag FamilyHome) y lo hace aparecer junto a su cuna.
--   * Pone en casa a Abu y a otro familiar (NPC) en sus sitios (tag FamilySpot) y sus diálogos.
--   * Convierte lo que hace el bebé en eventos para la historia de vida (StoryEvents):
--       BabyStood (se levanta), BabySteps (cada paso), Talk (habla con la familia),
--       BabyInteract (juega con los bloques, mira la tele), LookedOutside (mira por el ventanal).
--   * Un bebé no sale solo de casa: si se aleja, vuelve con su familia.
-- Las misiones del tutorial están en shared/LifeStory/Quests.luau (capítulo Bebe_PrimerosPasos).
-- El mapa (casas, habitaciones, cuna, ventanal) lo hace World/Kit/Home.luau: aquí solo se LEE.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local CinematicService = require(script.Parent.CinematicService)

local BabyService = {}

local BABY = Config.Baby
local Remote: RemoteEvent
local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

type Home = {
	Id: string,
	Model: Model,
	Index: number,
	Users: { [Player]: boolean },
	Ready: boolean,
}
type Baby = {
	HomeId: string,
	Stood: boolean,
	LastPosition: Vector3?,
	Walked: number,
	Busy: boolean, -- mirando por la ventana
	LastWarn: number,
}

local homes: { [string]: Home } = {}
local babies: { [Player]: Baby } = {}

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

-- Role: quién habla ("Abu", "Familia" o nil = narrador), para ponerle su voz
local function say(player: Player, speakerKey: string?, textKey: string, delay: number?)
	local role = if speakerKey == "NPC.ABU_ROSA" or speakerKey == "NPC.ABU_TOMAS"
		then "Abu"
		elseif speakerKey then "Familia"
		else nil
	local function fire()
		if player.Parent then
			Remote:FireClient(player, "Say", { SpeakerKey = speakerKey, TextKey = textKey, Role = role })
		end
	end
	if delay then
		task.delay(delay, fire)
	else
		fire()
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Primera pieza de la casa con esa etiqueta (y esos atributos)
local function findTagged(model: Model, tag: string, attributes: { [string]: any }?): BasePart?
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:HasTag(tag) then
			local ok = true
			for name, value in attributes or {} do
				if descendant:GetAttribute(name) ~= value then
					ok = false
					break
				end
			end
			if ok then
				return descendant
			end
		end
	end
	return nil
end

local function findNamed(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

-- ¿En qué paso de qué misión está el jugador?
local function questStep(player: Player, questId: string): number?
	local data = DataService.get(player)
	local prog = data and data.Story.Active[questId]
	return prog and prog.Step
end

local function prompt(parent: BasePart, action: string, object: string, onTrigger: (Player) -> ())
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	p.Parent = parent
	p.Triggered:Connect(onTrigger)
	return p
end

---------------------------------------------------------------------
-- La familia (NPC)
---------------------------------------------------------------------

local function makeNpc(home: Home, spot: BasePart, nameKey: string, skin: Color3): Model
	local model: Model
	local ok, result = pcall(function()
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = skin
		description.TorsoColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.LeftLegColor = skin
		description.RightLegColor = skin
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if ok and result then
		model = result
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayName = Strings.get(nameKey)
			humanoid.NameDisplayDistance = 40
		end
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.Anchored = true
		end
	else
		-- Si no se puede crear un personaje de Roblox, una figura sencilla hace el papel
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = Vector3.new(2, 5, 1.2)
		body.Color = skin
		body.Anchored = true
		body.Parent = model
		model.PrimaryPart = body
	end
	model.Name = Strings.get(nameKey)
	-- De pie sobre el suelo, en el sitio que marca el mapa
	local _, size = model:GetBoundingBox()
	local floorY = spot.Position.Y - spot.Size.Y / 2
	model:PivotTo(CFrame.new(spot.Position.X, floorY + size.Y / 2, spot.Position.Z) * spot.CFrame.Rotation)
	model.Parent = home.Model
	return model
end

local onTalk -- se define más abajo

local function setupHome(home: Home)
	if home.Ready then
		return
	end
	home.Ready = true
	local abuKey = if home.Index % 2 == 1 then "NPC.ABU_ROSA" else "NPC.ABU_TOMAS"
	local familyKey = if home.Index % 2 == 1 then "NPC.PAPA" else "NPC.MAMA"
	local people = {
		{ Npc = "Familia_Abu", NameKey = abuKey, Skin = Color3.fromRGB(234, 196, 160) },
		{ Npc = "Familia_Padre", NameKey = familyKey, Skin = Color3.fromRGB(198, 150, 112) },
	}
	for _, person in people do
		local spot = findTagged(home.Model, "FamilySpot", { Npc = person.Npc })
		if spot then
			local npc = makeNpc(home, spot, person.NameKey, person.Skin)
			-- Id del reparto (Cast): si una escena de la historia trae a este personaje, el fijo se oculta
			npc:SetAttribute("NpcId", if person.Npc == "Familia_Abu" then "Abu" else "Familia")
			CollectionService:AddTag(npc, "StaticNpc")
			local root = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				prompt(root, Strings.get("BABY.PROMPT.TALK"), Strings.get(person.NameKey), function(player)
					onTalk(player, home, person.Npc, person.NameKey)
				end)
			end
		else
			warn("[BabyService] Falta FamilySpot", person.Npc, "en", home.Id)
		end
	end

	-- Cosas con las que juega el bebé
	local toys = findNamed(home.Model, "ToyBlock")
	if toys then
		prompt(toys, Strings.get("BABY.PROMPT.PLAY"), Strings.get("BABY.OBJECT.TOYS"), function(player)
			if babies[player] and babies[player].HomeId == home.Id then
				say(player, nil, "BABY.TOYS")
				StoryEvents.emit(player, "BabyInteract", { Object = "Juguetes" })
			end
		end)
	end
	local tv = findNamed(home.Model, "TV")
	if tv then
		prompt(tv, Strings.get("BABY.PROMPT.TV"), Strings.get("BABY.OBJECT.TV"), function(player)
			if babies[player] and babies[player].HomeId == home.Id then
				say(player, nil, "BABY.TV")
				StoryEvents.emit(player, "BabyInteract", { Object = "Tele" })
			end
		end)
	end
	local window = findTagged(home.Model, "LookOutside")
	if window then
		prompt(window, Strings.get("BABY.PROMPT.WINDOW"), Strings.get("BABY.OBJECT.WINDOW"), function(player)
			local baby = babies[player]
			if not baby or baby.HomeId ~= home.Id or baby.Busy then
				return
			end
			baby.Busy = true
			-- Escena de cámara: sale por el ventanal y enseña Valmar (Cinematics.Bebe_Ventanal)
			local duration = CinematicService.play(player, "Bebe_Ventanal")
			task.delay(duration, function()
				if babies[player] then
					babies[player].Busy = false
				end
				if player.Parent then
					StoryEvents.emit(player, "LookedOutside", {})
				end
			end)
		end)
	end
end

-- Qué dice cada familiar según el momento del tutorial
function onTalk(player: Player, home: Home, npc: string, nameKey: string)
	local baby = babies[player]
	if not baby or baby.HomeId ~= home.Id then
		say(player, nameKey, if npc == "Familia_Abu" then "DLG.ABU.BEBE.GENERICO" else "DLG.FAMILIA.GENERICO")
		return
	end
	local data = DataService.get(player)
	if npc == "Familia_Abu" then
		if not baby.Stood then
			say(player, nameKey, "DLG.ABU.BEBE.LEVANTATE")
		elseif questStep(player, "Bebe_AprendeACaminar") == 3 then
			-- "¡Has llegado hasta aquí!" lo dice Abu en la cinemática de primeros pasos; después, esto:
			say(player, nameKey, "DLG.ABU.BEBE.EXPLORA", 7)
			-- Primera vez que se ven las necesidades: la barriguita empieza a sonar
			if data and data.Hunger > BABY.HungryAfterFirstSteps then
				NeedsService.change(player, BABY.HungryAfterFirstSteps - data.Hunger, 0)
			end
		elseif questStep(player, "Bebe_ExploraLaCasa") ~= nil then
			say(player, nameKey, if questStep(player, "Bebe_ExploraLaCasa") == 2 then "DLG.ABU.BEBE.BARRIGA" else "DLG.ABU.BEBE.EXPLORA")
		elseif questStep(player, "Bebe_HoraDeSalir") ~= nil then
			say(player, nameKey, "DLG.ABU.BEBE.VENTANA")
		else
			say(player, nameKey, "DLG.ABU.BEBE.GENERICO")
		end
	else
		if questStep(player, "Bebe_ExploraLaCasa") == 2 then
			say(player, nameKey, "DLG.FAMILIA.BIBERON")
			NeedsService.change(player, Config.Needs.Max, 0)
		else
			say(player, nameKey, "DLG.FAMILIA.GENERICO")
		end
	end
	StoryEvents.emit(player, "Talk", { Npc = npc })
end

---------------------------------------------------------------------
-- Bebés
---------------------------------------------------------------------

local function indexHomes()
	local list = CollectionService:GetTagged("FamilyHome")
	table.sort(list, function(a, b)
		return tostring(a:GetAttribute("HomeId")) < tostring(b:GetAttribute("HomeId"))
	end)
	for index, model in list do
		local id = model:GetAttribute("HomeId")
		if model:IsA("Model") and id and not homes[id] then
			homes[id] = { Id = id, Model = model, Index = index, Users = {}, Ready = false }
		end
	end
end

-- La casa guardada, o la que tenga menos bebés en este servidor
local function chooseHome(saved: string?): Home?
	indexHomes()
	if saved and homes[saved] then
		return homes[saved]
	end
	local best: Home? = nil
	local bestCount = math.huge
	for _, home in homes do
		local count = 0
		for _ in home.Users do
			count += 1
		end
		if count < bestCount or (count == bestCount and best and home.Index < best.Index) then
			best, bestCount = home, count
		end
	end
	return best
end

local function spawnAtCrib(player: Player, baby: Baby)
	local home = homes[baby.HomeId]
	local spawn = home and findTagged(home.Model, "BabySpawn")
	local character = player.Character
	if not spawn or not character then
		return
	end
	pcall(function()
		player:RequestStreamAroundAsync(spawn.Position, 5)
	end)
	character:PivotTo(spawn.CFrame + Vector3.new(0, 2.5, 0))
end

local function release(player: Player)
	local baby = babies[player]
	if not baby then
		return
	end
	babies[player] = nil
	local home = homes[baby.HomeId]
	if home then
		home.Users[player] = nil
	end
	player:SetAttribute("Crawling", nil)
	player:SetAttribute("BabyCanStand", nil)
end

local function start(player: Player)
	if babies[player] or player:GetAttribute("LifeStage") ~= "Bebe" then
		return
	end
	local data = DataService.get(player)
	if not data then
		return
	end
	local home = chooseHome(data.Life.FamilyHomeId)
	if not home then
		warn("[BabyService] El mapa no tiene casas familiares (tag FamilyHome)")
		return
	end
	data.Life.FamilyHomeId = home.Id
	home.Users[player] = true
	setupHome(home)
	local stood = data.Story.Flags.BebeDePie == true
	local baby: Baby = { HomeId = home.Id, Stood = stood, Walked = 0, Busy = false, LastWarn = 0 }
	babies[player] = baby
	player:SetAttribute("FamilyHomeId", home.Id)
	player:SetAttribute("AbuKey", if home.Index % 2 == 1 then "NPC.ABU_ROSA" else "NPC.ABU_TOMAS")
	player:SetAttribute("FamilyKey", if home.Index % 2 == 1 then "NPC.PAPA" else "NPC.MAMA")
	player:SetAttribute("Crawling", if stood then nil else true)
	player:SetAttribute("BabyCanStand", if stood then nil else true)
	spawnAtCrib(player, baby)
	if not stood then
		task.delay(3, function()
			if babies[player] == baby and not baby.Stood then
				say(player, if home.Index % 2 == 1 then "NPC.ABU_ROSA" else "NPC.ABU_TOMAS", "DLG.ABU.BEBE.LEVANTATE")
			end
		end)
	end
end

-- Niños y adolescentes siguen viviendo con su familia: su casa y los nombres de su familia
-- (los usan las misiones del colegio: "Mamá te despierta", "Abu te da un consejo"…)
local function ensureFamily(player: Player)
	local stage = player:GetAttribute("LifeStage")
	local data = DataService.get(player)
	if stage == "Bebe" or not data or player:GetAttribute("FamilyHomeId") then
		return
	end
	local home = chooseHome(data.Life.FamilyHomeId)
	if not home then
		return
	end
	data.Life.FamilyHomeId = home.Id
	setupHome(home)
	player:SetAttribute("FamilyHomeId", home.Id)
	player:SetAttribute("AbuKey", if home.Index % 2 == 1 then "NPC.ABU_ROSA" else "NPC.ABU_TOMAS")
	player:SetAttribute("FamilyKey", if home.Index % 2 == 1 then "NPC.PAPA" else "NPC.MAMA")
end

local function stand(player: Player)
	local baby = babies[player]
	local data = DataService.get(player)
	if not baby or baby.Stood or not data then
		return
	end
	baby.Stood = true
	baby.LastPosition = nil
	baby.Walked = 0
	data.Story.Flags.BebeDePie = true
	player:SetAttribute("Crawling", nil)
	player:SetAttribute("BabyCanStand", nil)
	local home = homes[baby.HomeId]
	say(player, if home and home.Index % 2 == 1 then "NPC.ABU_ROSA" else "NPC.ABU_TOMAS", "DLG.ABU.BEBE.VEN")
	StoryEvents.emit(player, "BabyStood", {})
end

-- Pasos y "no salir de casa", cuatro veces por segundo
local function tick()
	for player, baby in babies do
		local root = rootOf(player)
		local home = homes[baby.HomeId]
		if not root or not home or baby.Busy then
			continue
		end
		-- Dentro de casa: si se aleja, vuelve junto a la cuna
		local cf, size = home.Model:GetBoundingBox()
		local rel = cf:PointToObjectSpace(root.Position)
		local margin = BABY.MaxDistanceFromHome
		if math.abs(rel.X) > size.X / 2 + margin or math.abs(rel.Z) > size.Z / 2 + margin then
			spawnAtCrib(player, baby)
			baby.LastPosition = nil
			if os.clock() - baby.LastWarn > 5 then
				baby.LastWarn = os.clock()
				Notify:FireClient(player, "Info", Strings.get("BABY.TOO_SMALL_OUT"))
			end
			continue
		end
		-- Primeros pasos: cada BABY.StepStuds andados cuenta un paso (solo mientras la misión lo pide)
		if baby.Stood and questStep(player, "Bebe_AprendeACaminar") == 2 then
			local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
			if baby.LastPosition then
				local moved = (flat - baby.LastPosition).Magnitude
				if moved < 10 then -- un salto mayor es un teletransporte, no un paso
					baby.Walked += moved
				end
			end
			baby.LastPosition = flat
			while baby.Walked >= BABY.StepStuds do
				baby.Walked -= BABY.StepStuds
				StoryEvents.emit(player, "BabySteps", {})
			end
		end
	end
end

function BabyService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Baby") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Baby"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player, action)
		if action == "Stand" then
			stand(player)
		end
	end)

	local function watch(player: Player)
		player:GetAttributeChangedSignal("LifeStage"):Connect(function()
			if player:GetAttribute("LifeStage") == "Bebe" then
				start(player)
			else
				release(player) -- ya es niño: la casa queda libre para otros bebés
				ensureFamily(player)
			end
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			local baby = babies[player]
			if baby then
				task.wait(0.2) -- dejar que LifeService le dé el tamaño de bebé
				spawnAtCrib(player, baby)
			end
		end)
		if player:GetAttribute("LifeStage") == "Bebe" then
			start(player)
		else
			ensureFamily(player)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(release)

	task.spawn(function()
		while true do
			task.wait(0.25)
			local ok, err = pcall(tick)
			if not ok then
				warn("[BabyService] " .. tostring(err))
			end
		end
	end)
end

return BabyService
