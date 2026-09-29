-- SchoolService: la gente del colegio VIVE su día. En cada colegio del mapa están los compañeros de tu
-- generación (Nico, Sara y Omar) y la profe (Lucía; en el instituto, Javier), y siguen el horario
-- (shared/LifeStory/SchoolLife):
--   8:30-9:00  en la puerta, charlando mientras abren
--   clase      sentados en sus pupitres; la profe explica junto a la pizarra
--   recreo     en el patio, juntos y charlando; la profe vigila
--   14:00-15:00 en el comedor, sentados comiendo; la profe de guardia vigila
--   17:00      salen por la puerta y se van a casa (de noche el colegio está vacío)
-- Van andando de un sitio a otro (PathfindingService; si no hay camino o se atascan, desaparecen con un
-- fundido y aparecen allí). Si tu misión te pide hablar con uno de ellos (atributo StoryNpc que pone la
-- historia), va él a buscarte, aunque sea fuera de hora. Si la escena de tu misión ya trae a ese
-- personaje, no hace falta: tu pantalla oculta a este y ves el de la escena (SceneClient).
--
-- Rendimiento: solo se mueven los de los colegios con algún jugador cerca; el resto se queda quieto
-- (anclado) en su sitio del horario. Se revisa dos veces por segundo, no en cada fotograma.
--
-- Hablar con ellos cuenta para la historia (StoryEvents "Talk") y lo recuerdan. Para que un toque de más
-- en el móvil no saque otra frase una y otra vez, cada personaje espera unos segundos
-- (SchoolLife.TalkCooldown) antes de volver a decirte algo.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Ground = require(ReplicatedStorage.Shared.Ground)
local SchoolLife = require(ReplicatedStorage.Shared.LifeStory.SchoolLife)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local Npc = require(script.Parent.Parent.World.Npc)
local LifeStoryService = require(script.Parent.LifeStoryService)
local DataService = require(script.Parent.DataService)
local StoryState = require(ReplicatedStorage.Shared.LifeStory.StoryState)
local TimeContext = require(ReplicatedStorage.Shared.LifeStory.TimeContext)
local LocationService = require(script.Parent.LocationService)

local SchoolService = {}

local V = Vector3.new
local TICK = 0.5 -- cada cuánto se revisa a la gente de los colegios
local ACTIVE_RANGE = 280 -- con un jugador a menos de esto del colegio, su gente se mueve
local NEED_RANGE = 260 -- a esta distancia del colegio, el que buscas va a tu encuentro
local FAR = 150 -- más lejos que esto, no va andando: aparece allí (con un fundido)
local STUCK = 4 -- segundos sin avanzar = atascado

local SayRemote: RemoteEvent
local hiddenFolder: Folder

type Person = {
	Id: string,
	School: School,
	Model: Model,
	Humanoid: Humanoid?,
	Root: BasePart?,
	Kid: boolean,
	GoalKey: string?,
	Goal: { [string]: any }?,
	Path: { Vector3 }?,
	PathIndex: number,
	Computing: boolean,
	LastPos: Vector3?,
	LastProgress: number,
	Hidden: boolean,
	Seated: boolean,
	Walking: boolean,
}

export type School = {
	Recess: BasePart,
	Model: Instance,
	Instituto: boolean,
	Scale: number,
	People: { [string]: Person },
	Active: boolean,
	Canteen: BasePart?,
	CanteenCheckedAt: number,
	Goals: { [string]: { [string]: any } }, -- sitios del horario ya calculados (activity|npc)
}

local schools: { School } = {}
local lastTalk: { [Player]: { [string]: number } } = {}

---------------------------------------------------------------------
-- Ayudas
---------------------------------------------------------------------

local function flat(v: Vector3): Vector3
	return V(v.X, 0, v.Z)
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- El suelo (o el banco, la silla) que hay debajo de un punto
local function groundAt(position: Vector3, ignore: { Instance }): Vector3
	local list = table.clone(ignore)
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	local scenes = workspace:FindFirstChild("StoryScenes")
	if scenes then
		table.insert(list, scenes)
	end
	rayParams.FilterDescendantsInstances = list
	-- (solo suelo de verdad: no la cabeza de otro niño de la fila, que dejaba a uno flotando todo el día)
	local result = Ground.cast(position + V(0, 4, 0), V(0, -12, 0), rayParams)
	return if result then result.Position else position
end

local function descendantTagged(root: Instance, tag: string, attribute: string?, value: any): BasePart?
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag(tag) and (attribute == nil or d:GetAttribute(attribute) == value) then
			return d
		end
	end
	return nil
end

local function people(school: School): { Person }
	local list = {}
	for _, person in school.People do
		table.insert(list, person)
	end
	table.sort(list, function(a, b)
		return a.Id < b.Id
	end)
	return list
end

---------------------------------------------------------------------
-- Hablar (con espera entre frase y frase)
---------------------------------------------------------------------

-- speaker: el modelo de quien habla (su bocadillo sale encima de él)
local function say(player: Player, speakerKey: string, textKey: string, teacher: boolean, speaker: Model?)
	-- El texto se rellena aquí ({nombre}) y con el saludo de la hora que es
	local hour, weather = TimeContext.now()
	local text = TimeContext.adapt(Strings.get(textKey, { nombre = player.DisplayName }), hour, weather)
	SayRemote:FireClient(player, "Say", { SpeakerKey = speakerKey, TextKey = text, Role = if teacher then "Profe" else "Nino", Speaker = speaker })
end



-- ¿Puede decirte algo ya? (una frase cada SchoolLife.TalkCooldown segundos por personaje)
function SchoolService.canTalk(player: Player, npcId: string, now: number): boolean
	local mine = lastTalk[player]
	if not mine then
		mine = {}
		lastTalk[player] = mine
	end
	local last = mine[npcId]
	if last and now - last < SchoolLife.TalkCooldown then
		return false
	end
	mine[npcId] = now
	return true
end

local function onTalk(person: Person, player: Player)
	local lines = SchoolLife.Lines[person.Id]
	local nameKey = (Cast.People[person.Id] and Cast.People[person.Id].Name) or person.Id
	if lines and SchoolService.canTalk(player, person.Id, os.clock()) then
		-- ¿Os conocéis ya? (de esta charla o de la historia: una misión juntos, una relación…)
		local data = DataService.get(player)
		local state = StoryState.of(data)
		local first = not LifeStoryService.recall(player, person.Id, "SeConocen") and not state.knows(person.Id)
		if first then
			LifeStoryService.remember(player, person.Id, "SeConocen")
			LifeStoryService.addAffinity(player, person.Id, 1)
			say(player, nameKey, lines.First, not person.Kid, person.Model)
		else
			if not LifeStoryService.recall(player, person.Id, "SeConocen") then
				LifeStoryService.remember(player, person.Id, "SeConocen")
			end
			local line = SchoolLife.knownLine(person.Id, state, math.random())
			say(player, nameKey, line or lines.Lines[math.random(1, #lines.Lines)], not person.Kid, person.Model)
		end
		-- Te mira mientras te habla (si está quieto)
		local root = person.Root
		local character = player.Character
		local mine = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and root.Anchored and mine and not person.Seated then
			Npc.faceSmooth(person.Model, mine.Position)
		end
	end
	-- Para la historia cuenta siempre (una misión puede pedir "habla con Nico")
	StoryEvents.emit(player, "Talk", { Npc = person.Id })
end

---------------------------------------------------------------------
-- Crear a cada uno (mismo aspecto que en las escenas de la historia: Cast)
---------------------------------------------------------------------

local function makePerson(school: School, npcId: string, kid: boolean): Person?
	local cast = Cast.People[npcId] or {}
	local skin = cast.Skin or Color3.fromRGB(226, 186, 150)
	local ok, model = pcall(function()
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = cast.Shirt or skin
		description.LeftLegColor = cast.Pants or skin
		description.RightLegColor = cast.Pants or skin
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		return nil
	end
	local name = Strings.get(Cast.nameOf(npcId, nil))
	model.Name = name
	model:SetAttribute("NpcId", npcId) -- si una escena de la historia lo trae, este se oculta (SceneClient)
	CollectionService:AddTag(model, "StaticNpc")
	Npc.atomic(model) -- que llegue entero al cliente (si no, a veces no se le podía animar)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid then
		humanoid.DisplayName = name
		-- El nombre lo pinta el cliente (Controllers/NameTags: legible y sin pisar los bocadillos)
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		CollectionService:AddTag(model, "NamedActor")
		humanoid.WalkSpeed = if kid then 11 else 9
		humanoid.BreakJointsOnDeath = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end
	pcall(Npc.dress, model, {
		Skin = cast.Skin,
		Shirt = cast.Shirt,
		Pants = cast.Pants,
		Shoes = cast.Shoes,
		Hair = cast.Hair,
		LongHair = cast.LongHair == true,
		Backpack = if kid then cast.Backpack or Color3.fromHSV(math.random(), 0.6, 0.8) else nil,
		LongSleeves = cast.LongSleeves == true,
	})
	if kid then
		-- Niños del cole o adolescentes del instituto: se mueven como tales (Controllers/AgeMotion)
		model:SetAttribute("Age", if school.Instituto then "Adolescente" else "Nino")
		pcall(function()
			model:ScaleTo(school.Scale)
		end)
	end
	if root then
		root.Anchored = true
		model.PrimaryPart = root
		-- Solo chocan con el suelo y las paredes, no se empujan con los jugadores
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanTouch = false
			end
		end
	end
	local person: Person = {
		Id = npcId,
		School = school,
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Kid = kid,
		GoalKey = nil,
		Goal = nil,
		Path = nil,
		PathIndex = 1,
		Computing = false,
		LastPos = nil,
		LastProgress = os.clock(),
		Hidden = true,
		Seated = false,
		Walking = false,
	}
	model.Parent = hiddenFolder
	if root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ActionText = Strings.get("BABY.PROMPT.TALK")
		prompt.ObjectText = name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		prompt.Triggered:Connect(function(player)
			onTalk(person, player)
		end)
	end
	return person
end

---------------------------------------------------------------------
-- Adónde tiene que ir cada uno a cada hora
---------------------------------------------------------------------
-- Goal = { Key, CFrame (pies o asiento, mirando hacia donde mira), Pose = "Stand"|"Sit", Work?, Chat?, Hide? }

local function canteenOf(school: School): BasePart?
	local canteen = school.Canteen
	if canteen and canteen:IsDescendantOf(workspace) then
		return canteen
	end
	-- (buscar entre todas las piezas del colegio cuesta: como mucho cada 20 s)
	if os.clock() - school.CanteenCheckedAt < 20 then
		return nil
	end
	school.CanteenCheckedAt = os.clock()
	canteen = descendantTagged(school.Model, "StoryArea", "AreaId", "Comedor")
	school.Canteen = canteen
	if canteen then
		table.clear(school.Goals) -- ya hay comedor: se vuelven a calcular los sitios
	end
	return canteen
end

-- Punto en los ejes de una pieza (a ras de su suelo), mirando hacia `look` (también en sus ejes)
local function onFloor(part: BasePart, offset: Vector3, look: Vector3, ignore: { Instance }): CFrame
	local base = part.CFrame * CFrame.new(offset.X, -part.Size.Y / 2, offset.Z)
	local feet = groundAt(base.Position + V(0, 0.2, 0), ignore)
	local dir = flat(part.CFrame:VectorToWorldSpace(look))
	if dir.Magnitude < 0.01 then
		dir = flat(part.CFrame.LookVector)
	end
	return CFrame.lookAt(feet, feet + dir)
end

-- En el comedor: los mismos sitios que la escena de la comida (Locations: AsientoComedor1-3, ProfeComedor)
local LUNCH_SEATS = {
	{ V(-13, 0, 1.5), V(1, 0, 0) },
	{ V(-9, 0, -2), V(-1, 0, 0) },
	{ V(-13, 0, -2), V(1, 0, 0) },
}
local LUNCH_TEACHER = { V(1.5, 0, 4), V(-1, 0, 0) }
local RECESS_SPOTS = { V(0, 0, 0), V(2.6, 0, 1.4), V(-2.2, 0, 2) }

local function kidIndex(npcId: string): number
	return table.find(SchoolLife.Kids, npcId) or 1
end

local computeGoal

-- Sitio del horario (calculado una vez: buscar pupitres y marcas entre las piezas del colegio cuesta)
local function scheduleGoal(person: Person, activity: string): { [string]: any }
	local school = person.School
	local key = activity .. "|" .. person.Id
	local goal = school.Goals[key]
	if goal and not (activity == "Comedor" and goal.Key ~= "Comedor" and canteenOf(school)) then
		return goal
	end
	goal = computeGoal(person, activity)
	school.Goals[key] = goal
	return goal
end

function computeGoal(person: Person, activity: string): { [string]: any }
	local school = person.School
	local model = person.Model
	local ignore = { model }
	local i = kidIndex(person.Id)
	local entrance = descendantTagged(school.Model, "SchoolEntrance")
	if activity == "Fuera" then
		return { Key = "Fuera", Hide = true }
	end
	if activity == "Llegada" or activity == "Salida" then
		if entrance then
			local out = if activity == "Salida" then 12 else 5
			local offset = if person.Kid then V((i - 2) * 2.6, 0, -out - (i % 2) * 1.5) else V(0, 0, -2)
			local cf = onFloor(entrance, offset, V(0, 0, 1), ignore)
			return { Key = activity, CFrame = cf, Pose = "Stand", Chat = person.Kid, Work = if person.Kid then nil else "Clipboard" }
		end
		activity = "Recreo"
	end
	if activity == "Clase" then
		if person.Kid then
			-- Sentados en su pupitre, mirando a la pizarra
			local desks = {}
			for _, d in school.Model:GetDescendants() do
				if d:IsA("BasePart") and d:HasTag("Desk") and d:GetAttribute("ClassroomId") == "A" then
					table.insert(desks, d)
				end
			end
			table.sort(desks, function(a, b)
				return (a.Position.X * 1000 + a.Position.Z) < (b.Position.X * 1000 + b.Position.Z)
			end)
			local desk = desks[({ 2, 5, 7 })[i] or i] or desks[i]
			if desk then
				local chair: BasePart? = nil
				local best = 4.5
				for _, other in desk.Parent:GetChildren() do
					if other:IsA("BasePart") and other.Name == "Chair" and (other.Position - desk.Position).Magnitude < best then
						chair, best = other, (other.Position - desk.Position).Magnitude
					end
				end
				if chair then
					local top = chair.Position + V(0, chair.Size.Y / 2, 0)
					local look = flat(desk.Position - chair.Position)
					return { Key = "Clase", CFrame = CFrame.lookAt(top, top + look), Pose = "Sit" }
				end
			end
		else
			local spot = descendantTagged(school.Model, "TeacherSpot", "ClassroomId", "A")
			local board = descendantTagged(school.Model, "Board", "ClassroomId", "A")
			if spot then
				local feet = groundAt(spot.Position, ignore)
				local look = if board then flat(spot.Position - board.Position) else flat(spot.CFrame.LookVector)
				return { Key = "Clase", CFrame = CFrame.lookAt(feet, feet + look), Pose = "Stand", Work = "Book" }
			end
		end
		activity = "Recreo"
	end
	if activity == "Comedor" then
		local canteen = canteenOf(school)
		if canteen then
			if person.Kid then
				local seat = LUNCH_SEATS[i] or LUNCH_SEATS[1]
				return { Key = "Comedor", CFrame = onFloor(canteen, seat[1], seat[2], ignore), Pose = "Sit", Work = "Eat" }
			end
			return { Key = "Comedor", CFrame = onFloor(canteen, LUNCH_TEACHER[1], LUNCH_TEACHER[2], ignore), Pose = "Stand", Work = "Watch" }
		end
		activity = "Recreo"
	end
	-- Recreo (y lo que no tenga sitio): juntos en el patio, charlando; la profe vigila desde un lado
	local recess = school.Recess
	if person.Kid then
		local spot = RECESS_SPOTS[i] or RECESS_SPOTS[1]
		local center = V(-20, 0, 6)
		return { Key = "Recreo", CFrame = onFloor(recess, center + spot, -spot + V(0.01, 0, 0.01), ignore), Pose = "Stand", Chat = true }
	end
	return { Key = "Recreo", CFrame = onFloor(recess, V(-12, 0, -14), V(0, 0, 1), ignore), Pose = "Stand", Work = "Watch" }
end

---------------------------------------------------------------------
-- Moverse
---------------------------------------------------------------------

local function standUp(person: Person)
	if person.Seated then
		Npc.stand(person.Model)
		person.Seated = false
	end
end

local function setAnchored(person: Person, anchored: boolean)
	local root = person.Root
	if not root then
		return
	end
	root.Anchored = anchored
	if not anchored then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
end

-- Llega (o aparece) en su sitio: quieto, sentado o de pie, con su tarea
local function settle(person: Person, goal: { [string]: any })
	person.Walking = false
	person.Path = nil
	setAnchored(person, true)
	local model = person.Model
	if goal.Pose == "Sit" then
		Npc.stand(model)
		Npc.sitAt(model, goal.CFrame)
		person.Seated = true
	else
		standUp(person)
		Npc.placeFeet(model, goal.CFrame)
	end
	model:SetAttribute("Work", goal.Work)
	model:SetAttribute("Chat", if goal.Chat then true else nil)
end

local function show(person: Person)
	if person.Hidden then
		person.Hidden = false
		person.Model.Parent = person.School.Recess.Parent
	end
end

local function hide(person: Person)
	if not person.Hidden then
		person.Hidden = true
		person.Walking = false
		person.Path = nil
		standUp(person)
		setAnchored(person, true)
		person.Model.Parent = hiddenFolder
	end
end

-- Desaparece con un fundido y aparece en su sitio (el cliente hace el fundido: atributo Fade)
local function blink(person: Person, goal: { [string]: any })
	person.Model:SetAttribute("Fade", (person.Model:GetAttribute("Fade") or 0) + 1)
	local key = goal.Key
	task.delay(if person.Hidden then 0 else 0.35, function()
		if person.GoalKey ~= key or not person.Model.Parent then
			return
		end
		show(person)
		settle(person, goal)
	end)
end

local function startWalk(person: Person, goal: { [string]: any })
	local root, humanoid = person.Root, person.Humanoid
	if not root or not humanoid then
		blink(person, goal)
		return
	end
	standUp(person)
	person.Model:SetAttribute("Work", nil)
	person.Model:SetAttribute("Chat", nil)
	setAnchored(person, false)
	person.Walking = true
	person.Path = { goal.CFrame.Position }
	person.PathIndex = 1
	person.LastPos = root.Position
	person.LastProgress = os.clock()
	humanoid:MoveTo(goal.CFrame.Position)
	-- Camino por dentro de los edificios (puertas, pasillos): se calcula aparte, sin esperar
	if not person.Computing then
		person.Computing = true
		local key = goal.Key
		task.spawn(function()
			local ok, path = pcall(function()
				local p = PathfindingService:CreatePath({ AgentRadius = 1.2, AgentHeight = 4.5, AgentCanJump = false, WaypointSpacing = 5 })
				p:ComputeAsync(root.Position, goal.CFrame.Position)
				return p
			end)
			person.Computing = false
			if person.GoalKey ~= key or not person.Walking then
				return
			end
			if ok and path and path.Status == Enum.PathStatus.Success then
				local points = {}
				for _, waypoint in path:GetWaypoints() do
					table.insert(points, waypoint.Position)
				end
				if #points > 0 then
					person.Path = points
					person.PathIndex = math.min(2, #points)
					humanoid:MoveTo(points[person.PathIndex])
				end
			elseif ok and path and path.Status == Enum.PathStatus.NoPath then
				blink(person, goal) -- no hay forma de llegar andando
			end
		end)
	end
end

local function setGoal(person: Person, goal: { [string]: any }, walk: boolean)
	if person.GoalKey == goal.Key then
		return
	end
	person.GoalKey = goal.Key
	person.Goal = goal
	if goal.Hide then
		hide(person)
		return
	end
	local root = person.Root
	local far = not root or person.Hidden or (flat(root.Position - goal.CFrame.Position)).Magnitude > FAR
	if not walk or far then
		if walk then
			blink(person, goal)
		else
			show(person)
			settle(person, goal)
		end
	else
		startWalk(person, goal)
	end
end

SchoolService.StopDistance = 4 -- quien viene a buscarte se para a esta distancia de ti

-- Mientras anda: sigue el camino; al llegar, se queda; si se atasca, aparece allí
local function stepWalk(person: Person)
	local goal = person.Goal
	local root, humanoid = person.Root, person.Humanoid
	if not person.Walking or not goal or not root or not humanoid then
		return
	end
	-- Viene a buscarte (tu misión pide hablar con él): se para a unos 4 pasos de ti, nunca encima,
	-- y se queda mirándote
	if type(goal.Key) == "string" and goal.Key:sub(1, 6) == "Busca:" then
		local userId = tonumber(goal.Key:match("^Busca:(%-?%d+):"))
		local seeker = userId and Players:GetPlayerByUserId(userId)
		local character = seeker and seeker.Character
		local mine = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if mine and flat(root.Position - mine.Position).Magnitude < SchoolService.StopDistance then
			local feet = root.Position - V(0, humanoid.HipHeight + root.Size.Y / 2, 0)
			local toward = flat(mine.Position - root.Position)
			local stop = table.clone(goal)
			stop.CFrame = if toward.Magnitude > 0.1 then CFrame.lookAt(feet, feet + toward) else CFrame.new(feet)
			settle(person, stop)
			return
		end
	end
	local path = person.Path or { goal.CFrame.Position }
	local target = path[person.PathIndex] or goal.CFrame.Position
	local toTarget = flat(root.Position - target).Magnitude
	if toTarget < 2.2 then
		if person.PathIndex >= #path then
			settle(person, goal)
			return
		end
		person.PathIndex += 1
		humanoid:MoveTo(path[person.PathIndex])
	elseif humanoid.MoveDirection.Magnitude < 0.1 then
		humanoid:MoveTo(target) -- (MoveTo se rinde a los 8 s: se vuelve a pedir)
	end
	local moved = if person.LastPos then (root.Position - person.LastPos).Magnitude else 1
	person.LastPos = root.Position
	if moved > 0.6 then
		person.LastProgress = os.clock()
	elseif os.clock() - person.LastProgress > STUCK then
		blink(person, goal)
		person.Walking = false
	end
end

---------------------------------------------------------------------
-- Quién te busca: si tu misión pide hablar con alguien del colegio, va a por ti
---------------------------------------------------------------------

local function sceneHas(player: Player, npcId: string): boolean
	local scenes = workspace:FindFirstChild("StoryScenes")
	local mine = scenes and scenes:FindFirstChild("Scene_" .. player.UserId)
	if not mine then
		return false
	end
	for _, model in mine:GetChildren() do
		if model:GetAttribute("NpcId") == npcId then
			return true
		end
	end
	return false
end

-- Por cada colegio: { [npcId] = jugador que lo necesita }
local function needs(): { [School]: { [string]: Player } }
	local out = {}
	for _, player in Players:GetPlayers() do
		local npcId = player:GetAttribute("StoryNpc")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		-- (solo si vas a pie y en la calle: antes, pasando en coche junto al cole, el compañero
		-- aparecía en la carretera al lado del coche)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local onFoot = player:GetAttribute("InteriorKey") == nil and player:GetAttribute("Riding") == nil and player:GetAttribute("Passenger") == nil and not (humanoid and humanoid.SeatPart)
		if type(npcId) == "string" and root and onFoot and SchoolLife.livesAtSchool(npcId) and not sceneHas(player, npcId) then
			local best: School? = nil
			local bestDistance = NEED_RANGE
			for _, school in schools do
				local d = flat(school.Recess.Position - root.Position).Magnitude
				if d < bestDistance and school.People[npcId] then
					best, bestDistance = school, d
				end
			end
			if best then
				out[best] = out[best] or {}
				if not out[best][npcId] then
					out[best][npcId] = player
				end
			end
		end
	end
	return out
end

-- Junto a ti (delante, a unos pasos), mirándote
local function besidePlayer(person: Person, player: Player): { [string]: any }?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local look = flat(root.CFrame.LookVector)
	look = if look.Magnitude > 0.1 then look.Unit else V(0, 0, -1)
	local spot = groundAt(root.Position + look * 5.5, { person.Model, character :: Instance }) -- (a más de 5 pasos: no en tu cara)
	-- La clave cambia solo si te alejas bastante (para que no esté cambiando de sitio a cada paso)
	local cell = ("%d,%d"):format(math.floor(root.Position.X / 10), math.floor(root.Position.Z / 10))
	return { Key = "Busca:" .. player.UserId .. ":" .. cell, CFrame = CFrame.lookAt(spot, spot + flat(root.Position - spot) + V(0.001, 0, 0)), Pose = "Stand" }
end

---------------------------------------------------------------------
-- Cada colegio
---------------------------------------------------------------------

local function populate(recess: BasePart)
	if recess:GetAttribute("SchoolPeople") then
		return
	end
	recess:SetAttribute("SchoolPeople", true)
	local model = recess.Parent
	if not model then
		return
	end
	local zone = LocationService.zoneAt(recess.Position)
	local instituto = zone == "Campus Valmar"
	local school: School = {
		Recess = recess,
		Model = model,
		Instituto = instituto,
		Scale = if instituto then 0.85 else 0.65, -- en el instituto ya son adolescentes
		People = {},
		Active = false,
		Canteen = nil,
		CanteenCheckedAt = -math.huge,
		Goals = {},
	}
	for _, kid in SchoolLife.Kids do
		local person = makePerson(school, kid, true)
		if person then
			school.People[kid] = person
		end
	end
	local teacherId = if instituto then SchoolLife.Teachers.Instituto else SchoolLife.Teachers.Colegio
	local teacher = makePerson(school, teacherId, false)
	if teacher then
		school.People[teacherId] = teacher
	end
	table.insert(schools, school)
	-- Aparecen ya en su sitio del horario
	local activity = SchoolLife.activityAt(Lighting.ClockTime)
	for _, person in people(school) do
		pcall(function()
			setGoal(person, scheduleGoal(person, activity), false)
		end)
	end
end

local function nearAnyPlayer(school: School): boolean
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and flat(root.Position - school.Recess.Position).Magnitude < ACTIVE_RANGE then
			return true
		end
	end
	return false
end

local function tick()
	local activity = SchoolLife.activityAt(Lighting.ClockTime)
	local wanted = needs()
	for _, school in schools do
		local active = nearAnyPlayer(school)
		school.Active = active
		local mine = wanted[school] or {}
		for _, person in people(school) do
			local ok, err = pcall(function()
				local player = mine[person.Id]
				local goal = (player and besidePlayer(person, player)) or scheduleGoal(person, activity)
				setGoal(person, goal, active)
				if active then
					stepWalk(person)
				elseif person.Walking and person.Goal then
					settle(person, person.Goal) -- nadie mira: llega al momento
				end
			end)
			if not ok then
				warn("[SchoolService] " .. tostring(err))
			end
		end
	end
end

function SchoolService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	SayRemote = remotes:WaitForChild("Baby") :: RemoteEvent -- el mismo globo de diálogo que la familia
	hiddenFolder = Instance.new("Folder")
	hiddenFolder.Name = "GenteDelColegioEnCasa" -- fuera de horario (fuera del mundo)
	hiddenFolder.Parent = ServerStorage
	Players.PlayerRemoving:Connect(function(player)
		lastTalk[player] = nil
	end)
	task.spawn(function()
		for _, recess in CollectionService:GetTagged("RecessArea") do
			if recess:IsA("BasePart") then
				pcall(populate, recess)
			end
		end
		CollectionService:GetInstanceAddedSignal("RecessArea"):Connect(function(recess)
			if recess:IsA("BasePart") then
				pcall(populate, recess)
			end
		end)
		while true do
			task.wait(TICK)
			tick()
		end
	end)
end

return SchoolService
