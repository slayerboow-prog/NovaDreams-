-- BabyService: el tutorial de bebé (fase 2, 5-10 minutos) en una casa familiar de Los Pinos.
--
-- Qué hace:
--   * Da a cada bebé una casa familiar del mapa (tag FamilyHome) y lo hace aparecer junto a su cuna.
--   * Pone en casa a toda la familia (NPC): Papá, Mamá y la abuela siempre (shared/LifeStory/Family:
--     household), la pareja de la historia en sus sitios (tag FamilySpot) y los demás al lado. De
--     noche se les enciende una luz suave para que se les vea por las ventanas.
--   * TODOS los jugadores tienen casa familiar (no solo los bebés): al nacer les toca una libre al
--     azar (Family.chooseHome) y se guarda (data.Life.FamilyHomeId). Al volver a entrar o reaparecer
--     se comprueba: si ya no existe o vive en ella otro jugador del servidor, se da otra libre.
--     Atributos: FamilyHomeId y FamilyHomePos (dónde está, para el 🏠 de los mapas).
--   * Convierte lo que hace el bebé en eventos para la historia de vida (StoryEvents):
--       BabyStood (se levanta), BabySteps (cada paso), Talk (habla con la familia),
--       BabyInteract (juega con los bloques, mira la tele), LookedOutside (mira por el ventanal).
--   * Un bebé no sale solo de casa: si se aleja, vuelve con su familia.
-- Las misiones del tutorial están en shared/LifeStory/Quests.luau (capítulo Bebe_PrimerosPasos).
-- El mapa (casas, habitaciones, cuna, ventanal) lo hace World/Kit/Home.luau: aquí solo se LEE.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Family = require(ReplicatedStorage.Shared.LifeStory.Family)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local CinematicService = require(script.Parent.CinematicService)
local Npc = require(script.Parent.Parent.World.Npc)
local PromptGate = require(script.Parent.Parent.World.PromptGate)

-- Antes de llevar a alguien a otro sitio: que se levante del asiento en que vaya (coche, autobús,
-- metro). Si no, se llevaba el vehículo con él (un coche del metro acababa en la calle).
local function standUpBefore(character: Model?)
	local ok, who = pcall(function()
		return character and game:GetService("Players"):GetPlayerFromCharacter(character)
	end)
	if ok and who then
		pcall(function()
			require(script.Parent.VehicleService).standUp(who)
		end)
	end
end


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
	Npcs: { [string]: Model }, -- la familia de esa casa (para poner su bocadillo encima)
	Lights: { PointLight }, -- luz suave de cada familiar (encendida de noche)
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
local residents: { [Player]: string } = {} -- la casa familiar de cada jugador conectado

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

-- El familiar que habla, en la casa de tu familia (su bocadillo sale encima de él)
local function familyModel(player: Player, role: string?): Model?
	if not role then
		return nil
	end
	local baby = babies[player]
	local home = homes[player:GetAttribute("FamilyHomeId") or (baby and baby.HomeId) or ""]
	local model = home and home.Npcs[if role == "Abu" then "Familia_Abu" else "Familia_Padre"]
	return if model and model.Parent then model else nil
end

-- ¿Está viendo una escena? (InScene lo pone el SERVIDOR, CinematicService; InCinematic es solo
-- del cliente y aquí nunca llega: por eso antes Abu hablaba encima del nacimiento, M-04)
local SAY_WAIT = 30
local function inScene(player: Player): boolean
	return player:GetAttribute("InScene") == true
end

-- Role: quién habla ("Abu", "Familia" o nil = narrador), para ponerle su voz
local function say(player: Player, speakerKey: string?, textKey: string, delay: number?)
	local role = if speakerKey == "NPC.ABU_ROSA" or speakerKey == "NPC.ABU_TOMAS"
		then "Abu"
		elseif speakerKey then "Familia"
		else nil
	local function send()
		if player.Parent then
			Remote:FireClient(player, "Say", { SpeakerKey = speakerKey, TextKey = textKey, Role = role, Speaker = familyModel(player, role) })
		end
	end
	local function fire()
		if not inScene(player) then
			send()
			return
		end
		-- En mitad de una escena (InScene, lo marca el servidor) la familia no habla encima: espera a
		-- que acabe (con tope) y lo dice después
		task.spawn(function()
			local since = os.clock()
			while player.Parent and inScene(player) and os.clock() - since < SAY_WAIT do
				task.wait(0.5)
			end
			task.wait(0.8)
			send()
		end)
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
	-- Una pulsación, una acción: con Papá, Mamá y la abuela juntos, solo habla el más cercano (PromptGate)
	p.Triggered:Connect(function(player)
		PromptGate.run(player, PromptGate.positionOf(p), function()
			onTrigger(player)
		end)
	end)
	return p
end

---------------------------------------------------------------------
-- La familia (NPC)
---------------------------------------------------------------------

local refreshLights: (Home) -> ()

local function makeNpc(home: Home, feetAt: CFrame, nameKey: string, skin: Color3, longHair: boolean?): Model
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
			-- El nombre lo pinta el cliente (Controllers/NameTags: legible y sin pisar los bocadillos)
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			CollectionService:AddTag(model, "NamedActor")
		end
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.Anchored = true
		end
		Npc.dress(model, { Skin = skin, LongHair = if longHair ~= nil then longHair else (nameKey == "NPC.MAMA" or nameKey == "NPC.ABU_ROSA"), Hair = if string.find(nameKey, "ABU") then Color3.fromRGB(200, 200, 205) else nil })
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
	Npc.placeFeet(model, feetAt)
	model.Parent = home.Model
	return model
end

local onTalk -- se define más abajo

-- De noche (y al anochecer) la familia lleva una luz suave encima
local function isNight(): boolean
	local clock = Lighting.ClockTime
	return clock >= 18.5 or clock < 7
end

refreshLights = function(home: Home)
	local night = isNight()
	for _, light in home.Lights do
		if light.Parent and light.Enabled ~= night then
			light.Enabled = night
		end
	end
end

local function setupHome(home: Home)
	if home.Ready then
		return
	end
	home.Ready = true
	-- Toda la familia (Family.household): la pareja de la historia en sus FamilySpot y los demás al
	-- lado. Work: la abuela teje en el salón y papá/mamá cocina en la cocina (lo anima el cliente)
	local skins = {
		Familia_Abu = Color3.fromRGB(234, 196, 160),
		Familia_Padre = Color3.fromRGB(198, 150, 112),
		Familia_Pareja = Color3.fromRGB(214, 168, 128),
		Familia_Abuela = Color3.fromRGB(230, 190, 156),
	}
	local spots: { [string]: BasePart } = {}
	for _, member in Family.household(home.Index) do
		local anchorName = member.Anchor or member.Npc
		local spot = spots[anchorName] or findTagged(home.Model, "FamilySpot", { Npc = anchorName })
		if not spot then
			warn("[BabyService] Falta FamilySpot", anchorName, "en", home.Id)
			continue
		end
		spots[anchorName] = spot
		-- De pie en el suelo del sitio (los extra, desplazados en los ejes de la casa)
		local at = spot.CFrame.Position
		local feetAt = CFrame.new(at.X, at.Y - spot.Size.Y / 2, at.Z) * spot.CFrame.Rotation
		if member.Offset then
			feetAt = feetAt * CFrame.new(member.Offset)
		end
		local npc = makeNpc(home, feetAt, member.NameKey, skins[member.Npc] or Color3.fromRGB(210, 166, 128), member.LongHair)
		home.Npcs[member.Npc] = npc
		-- Id del reparto (Cast): si una escena de la historia trae a este personaje, el fijo se oculta
		npc:SetAttribute("NpcId", member.NpcId)
		npc:SetAttribute("FamilyHomeId", home.Id)
		if member.Work then
			Npc.work(npc, member.Work)
		end
		if member.Old then
			npc:SetAttribute("Age", "Mayor") -- anda encorvado (Controllers/AgeMotion)
		end
		CollectionService:AddTag(npc, "StaticNpc")
		local root = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			-- Luz suave de noche: que se vea a la familia en casa (por las ventanas)
			local light = Instance.new("PointLight")
			light.Name = "HomeGlow"
			light.Range = 9
			light.Brightness = 0.6
			light.Color = Color3.fromRGB(255, 220, 170)
			light.Shadows = false
			light.Enabled = false
			light.Parent = root
			table.insert(home.Lights, light)
			prompt(root, Strings.get("BABY.PROMPT.TALK"), Strings.get(member.NameKey), function(player)
				if member.Story then
					onTalk(player, home, member.Npc, member.NameKey)
				else
					-- Los demás de la casa: una frase de familia, con su bocadillo encima de él o ella
					Remote:FireClient(player, "Say", {
						SpeakerKey = member.NameKey,
						TextKey = if member.Old then "DLG.ABU.BEBE.GENERICO" else "DLG.FAMILIA.GENERICO",
						Role = if member.Old then "Abu" else "Familia",
						Speaker = npc,
					})
				end
			end)
		end
	end
	refreshLights(home)

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
			-- Escena: sale por el ventanal y enseña Valmar (Happenings Bebe_VentanalFamilia)
			local duration = CinematicService.play(player, "Bebe_VentanalFamilia")
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

-- Última vez que cada jugador habló con cada familiar (el aviso "Talk" da experiencia: con pausa)
local TALK_GAP = 6
local talkedAt: { [Player]: { [string]: number } } = {}

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
	-- La frase sale siempre, pero para la historia (y la experiencia) cuenta una vez cada TALK_GAP
	local mine = talkedAt[player] or {}
	talkedAt[player] = mine
	if os.clock() - (mine[npc] or -math.huge) < TALK_GAP then
		return
	end
	mine[npc] = os.clock()
	StoryEvents.emit(player, "Talk", { Npc = npc })
end

---------------------------------------------------------------------
-- Bebés
---------------------------------------------------------------------

local function indexHomes()
	-- (una casa que ya no está en el mapa deja de valer: a quien viviera en ella se le da otra)
	for id, home in homes do
		if not home.Model.Parent then
			homes[id] = nil
		end
	end
	local list = CollectionService:GetTagged("FamilyHome")
	table.sort(list, function(a, b)
		return tostring(a:GetAttribute("HomeId")) < tostring(b:GetAttribute("HomeId"))
	end)
	for index, model in list do
		local id = model:GetAttribute("HomeId")
		if model:IsA("Model") and id and not homes[id] then
			homes[id] = { Id = id, Model = model, Index = index, Users = {}, Ready = false, Npcs = {}, Lights = {} }
		end
	end
end

-- La casa familiar de un jugador (Family.chooseHome): la guardada si existe y no vive en ella otro
-- jugador del servidor; si no, una libre al azar (o, si no queda ninguna, la menos llena)
local rng = Random.new()
local function chooseHome(player: Player, saved: string?): (Home?, string)
	indexHomes()
	local ids = {}
	for id in homes do
		table.insert(ids, id)
	end
	table.sort(ids)
	local others: { [string]: number } = {}
	for other, id in residents do
		if other ~= player and other.Parent then
			others[id] = (others[id] or 0) + 1
		end
	end
	local id, reason = Family.chooseHome(ids, saved, others, rng)
	return if id then homes[id] else nil, reason
end

-- Dónde está la casa (para el 🏠 de los mapas): delante de la puerta, a ras de suelo
local function homePosition(home: Home): Vector3
	local door = findTagged(home.Model, "StorySpot", { SpotId = "SalirCasa" })
	if door then
		return door.CFrame.Position
	end
	local ok, cf = pcall(function()
		return home.Model:GetBoundingBox()
	end)
	return if ok then (cf :: CFrame).Position else home.Model:GetPivot().Position
end

-- Le da (o le confirma) su casa: atributos, lo guardado y la familia montada
local setFamily: (Player, { [string]: any }, Home) -> ()
local function settle(player: Player, data: { [string]: any }, home: Home, reason: string)
	local before = data.Life.FamilyHomeId
	data.Life.FamilyHomeId = home.Id
	residents[player] = home.Id
	setupHome(home)
	player:SetAttribute("FamilyHomeId", home.Id)
	player:SetAttribute("FamilyHomePos", homePosition(home))
	if before ~= nil and before ~= home.Id and (reason == "Taken" or reason == "Invalid") then
		Notify:FireClient(player, "Info", "🏠 Tu familia vive ahora en otra casa de Los Pinos. Sale en el mapa como 🏠 Casa.")
	end
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
	standUpBefore(character)
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

-- Los nombres de tu familia (atributos FamilyKey y AbuKey), sacados de la casa y guardados en
-- data.Life: así los demás (escenas, historial de conducta) usan siempre la misma pareja
setFamily = function(player: Player, data: { [string]: any }, home: Home)
	local familyKey, abuKey = Family.keysFor(home.Index)
	data.Life.FamilyKey = familyKey
	data.Life.AbuKey = abuKey
	player:SetAttribute("AbuKey", abuKey)
	player:SetAttribute("FamilyKey", familyKey)
end

local function start(player: Player)
	if babies[player] or player:GetAttribute("LifeStage") ~= "Bebe" then
		return
	end
	local data = DataService.get(player)
	if not data then
		return
	end
	local home, reason = chooseHome(player, data.Life.FamilyHomeId)
	if not home then
		warn("[BabyService] El mapa no tiene casas familiares (tag FamilyHome)")
		return
	end
	settle(player, data, home, reason)
	home.Users[player] = true
	local stood = data.Story.Flags.BebeDePie == true
	local baby: Baby = { HomeId = home.Id, Stood = stood, Walked = 0, Busy = false, LastWarn = 0 }
	babies[player] = baby
	setFamily(player, data, home)
	player:SetAttribute("Crawling", if stood then nil else true)
	player:SetAttribute("BabyCanStand", if stood then nil else true)
	spawnAtCrib(player, baby)
	if not stood then
		task.delay(3, function()
			-- Espera a que acabe la escena del nacimiento o el sueño (antes Abu hablaba encima, M-04):
			-- libre = sin escena (InScene, del servidor), sin sueño, sin conversación y con el primer
			-- capítulo ya empezado (su escena del nacimiento se lanza al entrar en él), y así durante
			-- un rato seguido. Con tope: nunca se queda sin decirlo.
			local since = os.clock()
			local freeFor = 0
			while player.Parent and freeFor < 1.5 and os.clock() - since < 120 do
				local story = data.Story
				local waitingChapter = type(story) == "table" and story.Chapter == nil
				local busy = inScene(player)
					or player:GetAttribute("InPrologue")
					or player:GetAttribute("InDialogue")
					or player:GetAttribute("InCinematic")
					or (waitingChapter and os.clock() - since < 30)
				freeFor = if busy then 0 else freeFor + 0.5
				task.wait(0.5)
			end
			if babies[player] == baby and not baby.Stood then
				say(player, select(2, Family.keysFor(home.Index)), "DLG.ABU.BEBE.LEVANTATE")
			end
		end)
	end
end

-- Niños y adolescentes siguen viviendo con su familia: su casa y los nombres de su familia
-- (los usan las misiones del colegio: "Mamá te despierta", "Abu te da un consejo"…). Los adultos
-- también conservan su casa familiar (sale en el mapa como 🏠 Casa familiar si tienen otra suya).
-- Se mira al entrar, al cargar la partida, al cambiar de etapa y al reaparecer.
local function ensureFamily(player: Player)
	local stage = player:GetAttribute("LifeStage")
	local data = DataService.get(player)
	if not player.Parent or babies[player] or not data or type(data.Life) ~= "table" then
		return
	end
	if stage == "Bebe" then
		start(player)
		return
	end
	local current = player:GetAttribute("FamilyHomeId")
	local saved = data.Life.FamilyHomeId
	if current ~= nil and current == saved and residents[player] == current and homes[current] and homes[current].Model.Parent then
		return -- (todo en orden)
	end
	local home, reason = chooseHome(player, if type(saved) == "string" then saved else (if type(current) == "string" then current else nil))
	if not home then
		return
	end
	settle(player, data, home, reason)
	setFamily(player, data, home)
end

-- Para las pruebas y otros servicios: la casa familiar de un jugador (o nil)
function BabyService.homeOf(player: Player): string?
	return residents[player]
end

BabyService.ensureFamily = ensureFamily

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
	say(player, select(2, Family.keysFor(home and home.Index)), "DLG.ABU.BEBE.VEN")
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

-- (pruebas) el RemoteEvent de los bocadillos sin montar todo init
function BabyService._setRemote(remote: any)
	Remote = remote
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
			else
				ensureFamily(player) -- al reaparecer: que siga teniendo casa (y que siga siendo válida)
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
	Players.PlayerRemoving:Connect(function(player)
		talkedAt[player] = nil
		residents[player] = nil -- su casa queda libre para otros en este servidor
	end)
	-- Partida cargada (puede llegar después de entrar): su casa familiar, la guardada o una nueva
	DataService.onLoaded(function(player)
		task.defer(ensureFamily, player)
	end)

	-- Luces de la familia (de noche encendidas) y repaso de que todos siguen teniendo casa
	task.spawn(function()
		while true do
			task.wait(5)
			for _, home in homes do
				if home.Ready then
					pcall(refreshLights, home)
				end
			end
			for _, player in Players:GetPlayers() do
				pcall(ensureFamily, player)
			end
		end
	end)

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
