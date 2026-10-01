-- SceneService: los ACTORES y OBJETOS de las misiones. Cada misión dice, paso a paso, quién está en
-- escena, dónde y qué hace (Actors), y qué cosas se pueden examinar o usar (Props).
--
--   Actor = { Npc = "Nico", Place = "Patio", Offset = V(…), Index = n, Mode = "Idle"|"Wander"|"Follow"|"Sit"|"Wave"|"Cheer"|"Hunt"…,
--             Look = V(…) (hacia dónde mira, en los ejes del lugar; si no, mira al jugador), Prompt = false,
--             Action = "Disparar" (texto del botón; "Hablar" si no), Speed = n (Hunt/Flee), Glow = Color3 (brillo de alien…) }
--   Mode "Hunt": te persigue (enemigos de las misiones locas: alienígenas, robots, pollos mutantes…).
--   Prop  = { Kind = "Mochila", Place = "AulaA", Offset = V(…), Index = n, Prompt = "Examinar", Name = "…", Once = true,
--             Bed = true (cama donde se puede dormir de verdad: SleepService) }
--
-- Todo es de la historia de UN jugador: vive en workspace.StoryScenes.Scene_<UserId> con el atributo
-- Owner; los demás jugadores no lo ven (SceneClient lo oculta) ni pueden tocarlo.
-- Cuando cambia el paso, la escena se actualiza sin parpadeos: quien sigue en el mismo sitio se queda,
-- quien cambia de sitio camina hasta allí (o aparece, si está lejos), y quien sobra se va.
-- Andar: si el sitio está a más de unos pasos se busca el camino (PathfindingService: puertas, pasillos,
-- esquinas; salta si hace falta y recalcula si algo se pone en medio). Al llegar se coloca con un par de
-- pasos y se gira poco a poco (sin saltos). Si no hay camino o se atasca, se desvanece y aparece en su
-- sitio (atributo Fade: el fundido lo hace el cliente, Controllers/ActorLife).
-- Lo que pasa al hablar o usar algo lo decide la historia (SceneService.onInteract).

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Ground = require(ReplicatedStorage.Shared.Ground)

local focusOn: (Player, string?) -> boolean -- (definidas más abajo, junto al bucle de los personajes)
local onFoot: (Player) -> boolean
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Locations = require(ReplicatedStorage.Shared.LifeStory.Locations)
local LocationService = require(script.Parent.LocationService)
local Npc = require(script.Parent.Parent.World.Npc) -- ropa, pelo y pies en el suelo (lo comparte todo el juego)
local GallinaGigante = require(script.Parent.Parent.World.Kit.GallinaGigante) -- Petra (Cast: Body = "GallinaGigante")
local RoadGuard = require(script.Parent.Parent.World.RoadGuard) -- no bajar a la calzada si viene alguien
local Log = require(ReplicatedStorage.Shared.Log)

local SceneService = {}

-- La historia se engancha aquí: (player, "Actor" | "Prop", questId, id)
SceneService.onInteract = nil :: ((Player, string, string, string) -> ())?

local rgb = Color3.fromRGB
local V = Vector3.new

-- Animaciones R15 de Roblox (las de siempre). Encima, el cliente (Controllers/ActorLife) les añade
-- mirada, respiración y gestos al hablar, para que parezcan vivos.
local ANIMS = {
	Idle = "rbxassetid://507766666",
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
	Wave = "rbxassetid://507770239",
	Cheer = "rbxassetid://507770677",
	Laugh = "rbxassetid://507770818",
	Dance = "rbxassetid://507771019",
	Sit = "rbxassetid://2506281703",
	Point = "rbxassetid://507770453",
}
local ONE_SHOT = { Wave = true, Cheer = true, Point = true, Laugh = true }

local PATH_MIN = 10 -- más cerca va en línea recta (no hace falta calcular el camino)
local STUCK = 3 -- segundos sin avanzar: salta y recalcula el camino; la segunda vez, fundido
local WALK_MAX = 30 -- segundos andando como mucho: si no ha llegado, fundido

type Actor = {
	Quest: string?, -- la misión de la escena (los de otra misión no te siguen)
	Npc: string,
	Spec: { [string]: any },
	Key: string, -- lugar + modo: si cambia, el actor se mueve
	Model: Model,
	Humanoid: Humanoid?,
	Root: BasePart?,
	Home: CFrame, -- dónde debe estar
	Tracks: { [string]: AnimationTrack },
	Route: { Vector3 }?, -- Flee: puntos por los que huye
	RouteIndex: number,
	LastProgress: number,
	LastPosition: Vector3?,
	Playing: string?,
	NextWander: number,
	StuckSince: number?, -- cuándo empezó a andar hasta su sitio
	KerbSince: number?, -- esperando en el bordillo para cruzar desde entonces (World/RoadGuard)
	StunnedUntil: number?, -- (Hunt) aturdido tras un impacto
	Walk: string?, -- nil (quieto o en su modo) · "Walk" (va a su sitio) · "Settle" (se coloca) · "Fade" (fundido)
	WalkId: number, -- cambia con cada paseo: las tareas de uno viejo no tocan el nuevo
	Path: { Vector3 }?, -- puntos del camino (PathfindingService) o solo el destino
	PathJump: { boolean }?, -- en qué puntos hay que saltar
	PathIndex: number,
	PathConn: RBXScriptConnection?,
	Computing: boolean?,
	Recomputes: number,
	TurnUntil: number?, -- (Idle) girándose hacia el jugador
	Facing: boolean?, -- está girándose hacia quien le habla
	Talking: boolean?, -- está en una conversación contigo (quieto, mirándote)
	Recovered: number?, -- (vigilante) última vez que se le devolvió a su sitio
}
type Prop = { Id: string, Key: string, Model: Model }
type Scene = { Actors: { [string]: Actor }, Props: { [string]: Prop }, Last: { [string]: any }? }

local folder: Folder
local scenes: { [Player]: { [string]: Scene } } = {} -- jugador -> misión -> escena

---------------------------------------------------------------------
-- Suelo: los actores y objetos se apoyan en lo que haya debajo
---------------------------------------------------------------------

local function groundAt(position: Vector3, ignore: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = { folder }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	for _, instance in ignore do
		table.insert(list, instance)
	end
	params.FilterDescendantsInstances = list
	params.IgnoreWater = true
	-- Desde un poco por encima de los pies (no desde muy arriba: dentro de un edificio daría con el techo)
	-- (solo suelo de verdad: ni el capó de un coche aparcado, ni un autobús, ni la cabeza de alguien)
	local result = Ground.cast(position + V(0, 3.5, 0), V(0, -14, 0), params)
	return if result then result.Position else position
end

local function playerRoot(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Dónde va algo: lugar (+ n-ésimo + desplazamiento), apoyado en el suelo, mirando hacia Look.
-- Si el lugar es una marca del mapa (StoryProp / StorySpot, docs/mapa/ETIQUETAS.md) se usa tal cual:
-- un StoryProp ES el objeto (el armario de verdad), así que no se desplaza ni se duplica.
-- Devuelve también la marca (si la hay) y si es un objeto del mapa.
local function placement(player: Player, spec: { [string]: any }, forProp: boolean?): (CFrame?, BasePart?, boolean)
	local placeId = spec.Place or "CercaDeTi"
	local spot = LocationService.resolve(player, placeId, { Index = spec.Index })
	if not spot then
		return nil, nil, false
	end
	local instance = spot.Instance
	-- (un actor junto a un objeto del mapa se pone en el suelo a su lado, no dentro del objeto)
	local isProp = forProp == true and instance:IsA("BasePart") and CollectionService:HasTag(instance, "StoryProp")
	local isMark = isProp or (instance:IsA("BasePart") and CollectionService:HasTag(instance, "StorySpot"))
	if isProp then
		return instance.CFrame, instance :: BasePart, true
	end
	if spec.Offset then
		spot = LocationService.resolve(player, placeId, { Index = spec.Index, Offset = spec.Offset }) or spot
	end
	local position = groundAt(spot.Position + V(0, 0.5, 0), {})
	local rotation = spot.CFrame.Rotation
	-- Hacia dónde mira: lo que diga el actor o, si no, lo que diga el lugar (asientos del comedor…)
	local placeDef = Locations.Places[placeId]
	local lookAt = spec.Look or (placeDef and placeDef.Look)
	if isMark and not lookAt then
		-- Un StorySpot dice hacia dónde mira el personaje
		local look = V(instance.CFrame.LookVector.X, 0, instance.CFrame.LookVector.Z)
		if look.Magnitude > 0.01 then
			return CFrame.lookAt(position, position + look), instance :: BasePart, false
		end
	end
	if lookAt then
		local look = rotation:VectorToWorldSpace(lookAt)
		look = V(look.X, 0, look.Z)
		if look.Magnitude > 0.01 then
			return CFrame.lookAt(position, position + look), nil, false
		end
	end
	local root = playerRoot(player)
	if root then
		local toPlayer = V(root.Position.X - position.X, 0, root.Position.Z - position.Z)
		if toPlayer.Magnitude > 0.5 then
			return CFrame.lookAt(position, position + toPlayer), nil, false
		end
	end
	return CFrame.new(position) * rotation, nil, false
end

-- ¿Hay un asiento aquí (silla, banco, sofá…)? Lo que hay bajo los pies está algo más alto que lo que
-- hay debajo. En el suelo pelado (parque, playa, la calle de un sitio sin marca) no hay dónde sentarse:
-- el actor se quedaría "sentado en el aire", así que se queda de pie.
local function seatAt(position: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = { folder }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	params.FilterDescendantsInstances = list
	params.IgnoreWater = true
	local top = Ground.cast(position + V(0, 0.4, 0), V(0, -0.8, 0), params)
	if not top then
		return true -- (no se sabe: se deja como estaba)
	end
	if top.Instance:IsA("Seat") then
		return true
	end
	table.insert(list, top.Instance)
	params.FilterDescendantsInstances = list
	local below = Ground.cast(top.Position - V(0, 0.05, 0), V(0, -3.6, 0), params)
	return below ~= nil and top.Position.Y - below.Position.Y > 0.8
end

---------------------------------------------------------------------
-- Actores
---------------------------------------------------------------------

local function sceneFolder(player: Player): Folder?
	local name = "Scene_" .. player.UserId
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing :: Folder
	end
	if not player.Parent then
		return nil -- ya se ha ido: no se crea otra carpeta (se quedaría para siempre)
	end
	local f = Instance.new("Folder")
	f.Name = name
	f:SetAttribute("Owner", player.UserId)
	f.Parent = folder
	return f
end

local function prompt(parent: Instance, action: string, object: string, player: Player, onTrigger: () -> ())
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p:SetAttribute("Owner", player.UserId)
	p.Parent = parent
	p.Triggered:Connect(function(who)
		if who == player then
			onTrigger()
		end
	end)
	return p
end

local function play(actor: Actor, name: string)
	if actor.Playing == name then
		return
	end
	local humanoid = actor.Humanoid
	if not humanoid then
		return
	end
	pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local track = actor.Tracks[name]
		if not track then
			local animation = Instance.new("Animation")
			animation.AnimationId = ANIMS[name] or ANIMS.Idle
			track = animator:LoadAnimation(animation)
			track.Looped = not ONE_SHOT[name]
			actor.Tracks[name] = track
		end
		-- Un gesto corto (saludar, reír…) va encima de su postura: de pie, o sentado si está sentado
		-- (antes paraba la de sentarse y se quedaba de pie en la silla)
		local base = if actor.Spec.Mode == "Sit" then "Sit" else "Idle"
		for other, t in actor.Tracks do
			if other ~= name and not (ONE_SHOT[name] and other == base) then
				t:Stop(0.25)
			end
		end
		if ONE_SHOT[name] then
			local idle = actor.Tracks[base]
			if not idle then
				local animation = Instance.new("Animation")
				animation.AnimationId = ANIMS[base]
				idle = animator:LoadAnimation(animation)
				idle.Looped = true
				actor.Tracks[base] = idle
			end
			if not idle.IsPlaying then
				idle:Play(0.25)
			end
			track.Priority = Enum.AnimationPriority.Action
		end
		track:Play(0.25)
		if name == "Idle" or name == "Dance" then
			-- Cada uno a su ritmo: si no, toda la clase respira a la vez
			track.TimePosition = math.random() * math.max(0.1, track.Length)
			track:AdjustSpeed(0.9 + math.random() * 0.2)
		end
	end)
	actor.Playing = name
end

local function buildModel(npc: string, player: Player, forcedScale: number?): Model
	local person = Cast.People[npc]
	local skin = person and person.Skin or rgb(220, 180, 140)
	local ok, model = pcall(function()
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = person and person.Shirt or skin
		description.LeftLegColor = person and person.Pants or skin
		description.RightLegColor = person and person.Pants or skin
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		-- Figura sencilla si Roblox no puede crear el personaje
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = V(2, 4.5, 1.2)
		body.Color = person and person.Shirt or skin
		body.Anchored = true
		body.Parent = model
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Shape = Enum.PartType.Ball
		head.Size = V(1.4, 1.4, 1.4)
		head.Color = skin
		head.Anchored = true
		head.CFrame = body.CFrame * CFrame.new(0, 3, 0)
		head.Parent = model
		model.PrimaryPart = body
	end
	local body = person and person.Body
	if ok and model and person and not body then
		-- Siempre la misma ropa y el mismo pelo para cada personaje (Cast), en todas sus escenas
		local familyKey = player:GetAttribute(person.NameAttr or "") :: string?
		pcall(Npc.dress, model, {
			Skin = person.Skin,
			Shirt = person.Shirt,
			Pants = person.Pants,
			Shoes = person.Shoes or rgb(240, 240, 240),
			Hair = person.Hair,
			LongHair = if familyKey then (familyKey == "NPC.MAMA" or familyKey == "NPC.ABU_ROSA") else person.LongHair == true,
			Backpack = person.Backpack,
			LongSleeves = person.LongSleeves == true,
		})
	end
	local name = Strings.get(Cast.nameOf(npc, {
		FamilyKey = player:GetAttribute("FamilyKey"),
		AbuKey = player:GetAttribute("AbuKey"),
	}))
	model.Name = name
	model:SetAttribute("NpcId", npc)
	if ok and body == "GallinaGigante" then
		-- Petra: el cuerpo de persona se esconde y se ve una gallina (anda, persigue y se encoge igual)
		pcall(GallinaGigante.costume, model)
	end
	Npc.atomic(model) -- que llegue entero a tu pantalla (si no, a veces no se le podía animar)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = name
		-- El nombre lo pinta el cliente (Controllers/NameTags: más legible y se esconde mientras habla)
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		if not body then
			CollectionService:AddTag(model, "NamedActor") -- (a una gallina gigante se la reconoce sin cartel)
		end
		humanoid.WalkSpeed = if person and person.Kid then 15 else 13
	end
	-- Los compañeros de clase (Kid) crecen contigo: niños en el colegio, adolescentes en el instituto
	local stage = player:GetAttribute("LifeStage")
	local kidScale = if stage == "Adolescente" then 0.85 elseif stage == "Bebe" or stage == "Nino" or stage == nil then 0.65 else 1
	local scale = forcedScale or (if person and person.Kid then kidScale elseif person and person.Teen then 0.85 else 1)
	-- Su edad, para que se mueva como tal (Controllers/AgeMotion): los compañeros crecen contigo
	local kidAge = if stage == "Adolescente" then "Adolescente" elseif stage == "Bebe" or stage == "Nino" or stage == nil then "Nino" else nil
	model:SetAttribute("Age", if person and person.Kid then kidAge elseif person and person.Teen then "Adolescente" elseif person and person.Old then "Mayor" else nil)
	if scale ~= 1 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end
	return model
end

local function anchorActor(actor: Actor, anchored: boolean)
	local root = actor.Root
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

local function standAt(actor: Actor, cf: CFrame)
	if actor.Spec.Mode == "Sit" and actor.Root then
		-- Sentado: la cadera a la altura del asiento (cf ya está sobre la silla)
		actor.Model:PivotTo(cf * CFrame.new(0, actor.Root.Size.Y / 2 + 0.3, 0))
	else
		Npc.placeFeet(actor.Model, cf)
	end
end

local function applyMode(actor: Actor)
	local mode = actor.Spec.Mode or "Idle"
	local moving = mode == "Wander" or mode == "Follow" or mode == "Flee" or mode == "Hunt"
	anchorActor(actor, not moving)
	-- Chat: charla con los de al lado (el cliente le mueve cabeza y manos como si hablara)
	actor.Model:SetAttribute("Chat", if mode == "Chat" or actor.Spec.Chat == true then true else nil)
	-- Work: su tarea mientras está quieto (barrer, cocinar, apuntar…; Controllers/WorkAnim)
	actor.Model:SetAttribute("Work", actor.Spec.Work)
	-- Sentado: el cliente le pone además las manos en el regazo y respira (UseMotion, como a los jugadores)
	local seated = mode == "Sit"
	if (actor.Model:GetAttribute("UsePose") == "Sit") ~= seated then
		Npc.setPose(actor.Model, if seated then "Sit" else nil)
	end
	if seated then
		play(actor, "Sit")
	elseif mode == "Wave" or mode == "Cheer" or mode == "Point" or mode == "Dance" or mode == "Laugh" then
		play(actor, mode)
		actor.NextWander = os.clock() + math.random(40, 70) / 10
	else
		play(actor, "Idle")
	end
end

local function makeActor(player: Player, questId: string, spec: { [string]: any }, cf: CFrame, standing: boolean?): Actor
	local model = buildModel(spec.Npc, player, spec.Scale)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local actor: Actor = {
		Npc = spec.Npc,
		Quest = questId,
		Spec = spec,
		Key = "",
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Home = cf,
		Tracks = {},
		NextWander = 0,
		Route = nil,
		RouteIndex = 1,
		LastProgress = os.clock(),
		LastPosition = nil,
		WalkId = 0,
		PathIndex = 1,
		Recomputes = 0,
	}
	if root then
		root.Anchored = true
	end
	if standing then
		Npc.placeFeet(model, cf) -- (viene andando: de pie, aunque luego se siente)
	else
		standAt(actor, cf)
	end
	local glow = spec.Glow or (Cast.People[spec.Npc] and Cast.People[spec.Npc].Glow)
	if glow then
		-- Seres de otro mundo: brillan un poco (y se ven de noche)
		local highlight = Instance.new("Highlight")
		highlight.FillColor = glow
		highlight.FillTransparency = 0.8
		highlight.OutlineColor = glow
		highlight.OutlineTransparency = 0.2
		highlight.Parent = model
		local light = Instance.new("PointLight")
		light.Color = glow
		light.Range = 10
		light.Brightness = 1.5
		light.Parent = root or model:FindFirstChildWhichIsA("BasePart")
	end
	model.Parent = sceneFolder(player)
	if root and spec.Prompt ~= false then
		prompt(root, spec.Action or "Hablar", model.Name, player, function()
			if SceneService.onInteract then
				SceneService.onInteract(player, "Actor", questId, spec.Npc)
			end
		end)
	end
	if standing and spec.Mode ~= "Wander" then
		-- Viene andando: de pie hasta que llegue (sentarse, saludar, su tarea… al llegar)
		play(actor, "Idle")
	else
		applyMode(actor)
	end
	return actor
end

---------------------------------------------------------------------
-- Andar hasta su sitio (camino, colocarse, fundido si no puede)
---------------------------------------------------------------------

local function scaleOf(model: Model): number
	local ok, scale = pcall(function()
		return model:GetScale()
	end)
	return if ok and type(scale) == "number" and scale > 0 then scale else 1
end

local function flatDistance(a: Vector3, b: Vector3): number
	return V(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Ángulo (0..pi) entre dos orientaciones, solo en horizontal
local function yawBetween(a: CFrame, b: CFrame): number
	local la, lb = a.LookVector, b.LookVector
	local flatA, flatB = V(la.X, 0, la.Z), V(lb.X, 0, lb.Z)
	if flatA.Magnitude < 1e-3 or flatB.Magnitude < 1e-3 then
		return 0
	end
	return math.acos(math.clamp(flatA.Unit:Dot(flatB.Unit), -1, 1))
end

local function stopPath(actor: Actor)
	if actor.PathConn then
		actor.PathConn:Disconnect()
		actor.PathConn = nil
	end
	actor.Path = nil
	actor.PathJump = nil
end

-- Dónde queda su raíz cuando está en cf (lo mismo que standAt, sin moverle)
local function rootGoal(actor: Actor, cf: CFrame): CFrame?
	local root, humanoid = actor.Root, actor.Humanoid
	if not root or not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	if actor.Spec.Mode == "Sit" then
		return cf * CFrame.new(0, root.Size.Y / 2 + 0.3, 0)
	end
	return cf * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
end

-- Se desvanece y aparece en su sitio (no hay camino, se ha atascado…). El fundido lo hace el cliente.
local function fadeTo(actor: Actor)
	stopPath(actor)
	actor.WalkId += 1
	local id = actor.WalkId
	actor.Walk = "Fade"
	actor.Model:SetAttribute("Fade", (actor.Model:GetAttribute("Fade") or 0) + 1)
	if actor.Humanoid and actor.Root then
		actor.Humanoid:MoveTo(actor.Root.Position) -- se para
	end
	task.delay(0.35, function()
		if actor.WalkId ~= id or not actor.Model.Parent then
			return
		end
		actor.Walk = nil
		actor.StuckSince = nil
		anchorActor(actor, true)
		standAt(actor, actor.Home)
		applyMode(actor)
	end)
end

-- Ya está al lado: da un par de pasos hasta el punto exacto y se gira poco a poco (antes aparecía
-- de golpe en su sitio y girado)
local function settle(actor: Actor)
	stopPath(actor)
	actor.WalkId += 1
	local id = actor.WalkId
	actor.StuckSince = nil
	local root = actor.Root
	local goal = rootGoal(actor, actor.Home)
	anchorActor(actor, true)
	if not root or not goal or (root.Position - goal.Position).Magnitude > 5 then
		actor.Walk = nil
		standAt(actor, actor.Home)
		applyMode(actor)
		return
	end
	actor.Walk = "Settle"
	local distance = flatDistance(root.Position, goal.Position)
	local seconds = math.clamp(math.max(distance / 4, yawBetween(root.CFrame, goal) * 0.3), 0.2, 0.8)
	if distance > 0.4 then
		play(actor, "Walk")
		local walk = actor.Tracks.Walk
		if walk then
			walk:AdjustSpeed(0.7)
		end
	end
	TweenService:Create(root, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = goal }):Play()
	task.delay(seconds, function()
		if actor.WalkId ~= id or not actor.Model.Parent then
			return
		end
		actor.Walk = nil
		applyMode(actor)
	end)
end

-- Busca el camino hasta su sitio (sin esperar: mientras tanto va en línea recta)
local function computePath(actor: Actor)
	local root, humanoid = actor.Root, actor.Humanoid
	if actor.Computing or not root or not humanoid then
		return
	end
	actor.Computing = true
	local id = actor.WalkId
	local goal = actor.Home.Position
	task.spawn(function()
		local scale = scaleOf(actor.Model)
		local ok, path = pcall(function()
			local p = PathfindingService:CreatePath({
				AgentRadius = 1.3 * scale,
				AgentHeight = 5 * scale,
				AgentCanJump = true,
				WaypointSpacing = 4,
			})
			p:ComputeAsync(root.Position, goal)
			return p
		end)
		actor.Computing = false
		if actor.WalkId ~= id or actor.Walk ~= "Walk" or not actor.Model.Parent then
			return
		end
		if ok and path and path.Status == Enum.PathStatus.Success then
			local points, jumps = {}, {}
			for _, waypoint in path:GetWaypoints() do
				table.insert(points, waypoint.Position)
				table.insert(jumps, waypoint.Action == Enum.PathWaypointAction.Jump)
			end
			if #points == 0 then
				return
			end
			stopPath(actor)
			actor.Path, actor.PathJump = points, jumps
			actor.PathIndex = math.min(2, #points)
			actor.LastProgress = os.clock()
			humanoid:MoveTo(points[actor.PathIndex])
			-- Si algo se pone en medio (una puerta, otra persona…), se busca otro camino
			actor.PathConn = path.Blocked:Connect(function(blocked: number)
				if actor.WalkId ~= id or actor.Path ~= points or blocked < actor.PathIndex then
					return
				end
				actor.Recomputes += 1
				if actor.Recomputes <= 3 then
					computePath(actor)
				else
					fadeTo(actor)
				end
			end)
		elseif ok and path and path.Status == Enum.PathStatus.NoPath then
			fadeTo(actor) -- no hay forma de llegar andando
		end
		-- (si falla el cálculo sigue en línea recta; si se atasca, fundido)
	end)
end

-- Camina hasta cf (su nuevo sitio en la escena)
local function startWalk(actor: Actor, cf: CFrame)
	stopPath(actor)
	actor.WalkId += 1
	actor.Home = cf
	actor.Walk = "Walk"
	actor.StuckSince = os.clock()
	actor.LastProgress = os.clock()
	actor.LastPosition = nil
	actor.Recomputes = 0
	actor.Path = { cf.Position }
	actor.PathIndex = 1
	local humanoid, root = actor.Humanoid, actor.Root
	if not humanoid or not root then
		fadeTo(actor)
		return
	end
	-- Andando no está sentado ni con su tarea (al llegar vuelve a ella)
	if actor.Model:GetAttribute("UsePose") then
		Npc.setPose(actor.Model, nil)
	end
	actor.Model:SetAttribute("Work", nil)
	actor.Model:SetAttribute("Chat", nil)
	anchorActor(actor, false)
	humanoid:MoveTo(cf.Position)
	if flatDistance(root.Position, cf.Position) > PATH_MIN then
		computePath(actor)
	end
end

-- Un paso (cada 0.3 s) mientras va a su sitio
local function stepWalk(actor: Actor)
	local humanoid, root = actor.Humanoid, actor.Root
	if not humanoid or not root then
		return
	end
	actor.Walk = "Walk"
	actor.StuckSince = actor.StuckSince or os.clock()
	local path = actor.Path or { actor.Home.Position }
	local index = math.min(actor.PathIndex, #path)
	local target = path[index]
	local now = os.clock()
	if index >= #path then
		-- Último tramo: al llegar (o casi, si algo no le deja dar el último paso) se coloca
		local left = flatDistance(root.Position, actor.Home.Position)
		if left < 1.3 or (left < 3.5 and now - actor.LastProgress > 0.6) then
			settle(actor)
			return
		end
	elseif flatDistance(root.Position, target) < 2 then
		index += 1
		actor.PathIndex = index
		target = path[index]
		if actor.PathJump and actor.PathJump[index] then
			humanoid.Jump = true
		end
		humanoid:MoveTo(target)
	end
	-- En el bordillo: no baja a la calzada si su semáforo no le deja o viene un vehículo
	-- (World/RoadGuard). Esperando (hasta 40 s) no cuenta como atascado.
	local ahead = target
	for i = index, #path do
		if flatDistance(root.Position, path[i]) > 40 then
			break
		end
		ahead = path[i]
	end
	local feet = root.Position - V(0, humanoid.HipHeight + root.Size.Y / 2, 0)
	local okKerb, kerb, crosses = pcall(RoadGuard.kerb, feet, ahead)
	if okKerb and crosses and not kerb and now - (actor.KerbSince or now) < 40 and RoadGuard.mustWait(feet, ahead, humanoid.WalkSpeed) then
		actor.KerbSince = actor.KerbSince or now
		humanoid:MoveTo(root.Position)
		actor.LastProgress = now
		actor.StuckSince = (actor.StuckSince :: number) + 0.3
		actor.LastPosition = root.Position
		return
	end
	if not (okKerb and crosses) then
		actor.KerbSince = nil
	end
	if humanoid.MoveDirection.Magnitude < 0.1 then
		humanoid:MoveTo(target) -- (MoveTo se rinde a los 8 s: se vuelve a pedir)
	end
	local moved = if actor.LastPosition then (root.Position - actor.LastPosition).Magnitude else 1
	actor.LastPosition = root.Position
	if now - actor.StuckSince > WALK_MAX then
		fadeTo(actor) -- da vueltas sin llegar
	elseif moved > 0.4 then
		actor.LastProgress = now
	elseif now - actor.LastProgress > STUCK then
		actor.Recomputes += 1
		if actor.Recomputes <= 1 then
			-- Atascado: un saltito y otro camino desde donde está
			humanoid.Jump = true
			actor.LastProgress = now
			computePath(actor)
		else
			fadeTo(actor)
		end
	end
end

---------------------------------------------------------------------
-- Objetos (formas sencillas con color; no hace falta nada del catálogo)
---------------------------------------------------------------------

local function part(model: Model, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = offset
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Cada tipo de objeto: función que construye sus piezas alrededor del origen (el suelo en y = 0)
local C = CFrame.new
local BUILDERS: { [string]: (Model, { [string]: any }) -> () } = {
	Mochila = function(m, spec)
		local color = spec.Color or rgb(40, 90, 200)
		part(m, V(1.6, 2, 0.9), C(0, 1, 0), color, Enum.Material.Fabric)
		part(m, V(1.2, 0.8, 0.4), C(0, 0.8, -0.6), color:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Fabric)
	end,
	Libro = function(m, spec)
		part(m, V(1.2, 0.25, 0.9), C(0, 0.13, 0) * CFrame.Angles(0, math.rad(spec.Spin or 20), 0), spec.Color or rgb(200, 60, 60))
	end,
	Papel = function(m)
		part(m, V(0.9, 0.05, 0.7), C(0, 0.03, 0) * CFrame.Angles(0, 0.4, 0.1), rgb(245, 245, 235))
	end,
	Pegatina = function(m, spec)
		part(m, V(0.1, 0.5, 0.5), C(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), spec.Color or rgb(250, 200, 40), Enum.Material.Neon, Enum.PartType.Cylinder)
	end,
	Huella = function(m)
		part(m, V(0.9, 0.04, 1.6), C(0, 0.03, 0), rgb(90, 60, 40))
		part(m, V(0.9, 0.04, 1.6), C(0.9, 0.03, 1.8), rgb(90, 60, 40))
	end,
	Llavero = function(m)
		part(m, V(0.1, 0.5, 0.5), C(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 210), Enum.Material.Metal, Enum.PartType.Cylinder)
		part(m, V(0.4, 0.5, 0.1), C(0.4, 0.1, 0), rgb(220, 40, 40))
	end,
	Envoltorio = function(m)
		part(m, V(0.6, 0.1, 0.3), C(0, 0.05, 0), rgb(255, 90, 180), Enum.Material.Foil)
	end,
	Balon = function(m, spec)
		part(m, V(1.4, 1.4, 1.4), C(0, 0.7, 0), spec.Color or rgb(250, 250, 250), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end,
	Armario = function(m)
		part(m, V(3.5, 6.5, 1.8), C(0, 3.25, 0), rgb(150, 105, 70), Enum.Material.Wood)
		part(m, V(0.1, 6, 0.1), C(0, 3.25, -0.92), rgb(90, 60, 40))
	end,
	Espejo = function(m)
		part(m, V(1.6, 4, 0.2), C(0, 3, 0), rgb(200, 230, 240), Enum.Material.Glass).Reflectance = 0.6
		part(m, V(1.8, 4.2, 0.1), C(0, 3, 0.12), rgb(120, 80, 50), Enum.Material.Wood)
	end,
	Desayuno = function(m)
		part(m, V(1.6, 0.1, 1.6), C(0, 0.05, 0), rgb(250, 250, 250), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder).CFrame = C(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
		part(m, V(0.9, 0.2, 0.6), C(0, 0.2, 0), rgb(220, 170, 90))
		part(m, V(0.5, 0.7, 0.5), C(0.9, 0.4, 0.2), rgb(250, 240, 200), Enum.Material.Glass)
	end,
	Almohada = function(m)
		part(m, V(2, 0.6, 1.2), C(0, 0.3, 0), rgb(240, 240, 255), Enum.Material.Fabric)
	end,
	Perchero = function(m)
		part(m, V(0.3, 5, 0.3), C(0, 2.5, 0), rgb(120, 90, 60), Enum.Material.Wood)
		part(m, V(2, 0.2, 0.2), C(0, 4.8, 0), rgb(120, 90, 60), Enum.Material.Wood)
	end,
	Papelera = function(m)
		part(m, V(1.5, 1.2, 1.2), C(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(60, 140, 90), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	end,
	Asiento = function(m)
		part(m, V(2.2, 0.2, 2.2), C(0, 0.1, 0), rgb(255, 210, 60), Enum.Material.Neon)
	end,
	Canasta = function(m)
		part(m, V(0.3, 9, 0.3), C(0, 4.5, 0), rgb(70, 70, 80), Enum.Material.Metal)
		part(m, V(3, 2, 0.2), C(0, 9, 0), rgb(245, 245, 245))
		part(m, V(0.2, 1.6, 1.6), C(0, 8.2, -1), rgb(240, 110, 30), Enum.Material.Neon, Enum.PartType.Cylinder).CFrame = C(0, 8.2, -1) * CFrame.Angles(0, 0, math.rad(90))
	end,
	Kiosco = function(m)
		part(m, V(5, 4, 3), C(0, 2, 0), rgb(250, 240, 230))
		part(m, V(5.6, 0.4, 3.8), C(0, 4.6, -0.4), rgb(230, 80, 120))
		part(m, V(1, 1.2, 1), C(0, 5.6, 0), rgb(250, 210, 170), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end,
	Banco = function(m)
		part(m, V(6, 0.4, 1.6), C(0, 1.6, 0), rgb(140, 100, 60), Enum.Material.Wood)
		part(m, V(6, 1.4, 0.3), C(0, 2.4, 0.7), rgb(140, 100, 60), Enum.Material.Wood)
		part(m, V(0.3, 1.6, 1.4), C(-2.6, 0.8, 0), rgb(60, 60, 60), Enum.Material.Metal)
		part(m, V(0.3, 1.6, 1.4), C(2.6, 0.8, 0), rgb(60, 60, 60), Enum.Material.Metal)
	end,
	Escarabajo = function(m)
		part(m, V(0.6, 0.35, 0.8), C(0, 0.2, 0), rgb(40, 200, 140), Enum.Material.Neon, Enum.PartType.Ball)
	end,
	Mural = function(m, spec)
		part(m, V(6, 4, 0.2), C(0, 3, 0), spec.Color or rgb(250, 250, 250))
	end,
	-- Gato naranja atigrado (Bigotes) SENTADO, mirando hacia +X (así se reconoce enseguida como gato):
	-- ancas redondas, cuerpo inclinado, pecho blanco, patas delanteras rectas, cabeza con mofletes,
	-- orejas en punta, ojos verdes, hocico, bigotes y la cola enroscada por delante en el suelo
	Gato = function(m, spec)
		local fur = spec.Color or rgb(236, 142, 52)
		local dark = rgb(180, 95, 28)
		local white = rgb(250, 245, 235)
		local pink = rgb(240, 160, 176)
		local fabric = Enum.Material.Fabric
		local ball = Enum.PartType.Ball
		local rad = math.rad
		part(m, V(0.75, 1, 0.8), C(0.05, 1, 0) * CFrame.Angles(0, 0, rad(-18)), fur, fabric) -- cuerpo
		part(m, V(1.05, 1.05, 1.05), C(-0.2, 0.5, 0), fur, fabric, ball) -- ancas
		part(m, V(0.62, 0.62, 0.62), C(0.3, 1.05, 0), white, fabric, ball) -- pecho
		for _, x in { -0.3, -0.05 } do
			part(m, V(0.14, 0.06, 0.84), C(x, if x > -0.2 then 1.28 else 1.05, 0) * CFrame.Angles(0, 0, rad(-18)), dark, fabric) -- rayas
		end
		for _, z in { -0.17, 0.17 } do
			part(m, V(0.2, 0.95, 0.2), C(0.38, 0.48, z), fur, fabric) -- pata delantera
			part(m, V(0.3, 0.13, 0.24), C(0.43, 0.065, z), white, fabric) -- patita
			part(m, V(0.55, 0.16, 0.26), C(-0.05, 0.08, z * 2.3), fur, fabric) -- pie de atrás
		end
		-- Cabeza
		local head = C(0.32, 1.8, 0)
		part(m, V(0.9, 0.9, 0.9), head, fur, fabric, ball)
		part(m, V(0.42, 0.42, 0.42), head * C(0.3, -0.17, 0), white, fabric, ball) -- hocico
		part(m, V(0.1, 0.08, 0.14), head * C(0.51, -0.06, 0), pink) -- nariz
		for _, x in { -0.12, 0.05 } do
			part(m, V(0.08, 0.05, 0.34), head * C(x, 0.44, 0), dark, fabric) -- rayas de la frente
		end
		for _, z in { -0.19, 0.19 } do
			local side = if z > 0 then 1 else -1
			part(m, V(0.5, 0.5, 0.5), head * C(0.12, -0.14, z), fur, fabric, ball) -- moflete
			part(m, V(0.2, 0.2, 0.2), head * C(0.37, 0.08, z), rgb(138, 212, 90), Enum.Material.Neon, ball) -- ojo
			part(m, V(0.06, 0.16, 0.05), head * C(0.47, 0.08, z), rgb(17, 17, 17)) -- pupila de gato
			-- Oreja: un rombo girado y medio metido en la cabeza (asoma un triángulo)
			local ear = head * C(-0.02, 0.36, z * 1.2) * CFrame.Angles(side * rad(20), 0, 0) * CFrame.Angles(rad(45), 0, 0)
			part(m, V(0.08, 0.34, 0.34), ear, fur, fabric)
			part(m, V(0.09, 0.2, 0.2), ear * C(0.03, 0, 0), pink)
			for _, tilt in { -0.15, 0.15 } do
				part(m, V(0.5, 0.02, 0.02), head * C(0.45, -0.18, z * 1.4) * CFrame.Angles(0, -side * 1.2, tilt), white) -- bigotes
			end
		end
		-- Cola enroscada alrededor, en el suelo
		part(m, V(0.9, 0.18, 0.18), C(-0.45, 0.1, 0.52) * CFrame.Angles(0, rad(-20), 0), fur, fabric)
		part(m, V(0.6, 0.17, 0.17), C(0.15, 0.1, 0.58) * CFrame.Angles(0, rad(10), 0), fur, fabric)
		part(m, V(0.35, 0.16, 0.16), C(0.55, 0.1, 0.48) * CFrame.Angles(0, rad(40), 0), dark, fabric)
	end,
	Autobus = function(m)
		part(m, V(8, 7, 26), C(0, 4.2, 0), rgb(250, 200, 30))
		part(m, V(8.1, 2, 22), C(0, 5.5, -1), rgb(60, 80, 100), Enum.Material.Glass)
		for _, z in { -9, 9 } do
			for _, x in { -3.8, 3.8 } do
				part(m, V(1, 2.4, 2.4), C(x, 1.2, z) * CFrame.Angles(0, 0, math.rad(90)), rgb(30, 30, 30), Enum.Material.Rubber, Enum.PartType.Cylinder)
			end
		end
	end,
	Caja = function(m, spec)
		part(m, V(2, 2, 2), C(0, 1, 0), spec.Color or rgb(170, 130, 80), Enum.Material.Cardboard)
	end,
	Animal = function(m, spec)
		local color = spec.Color or rgb(250, 250, 250)
		part(m, V(1.6, 1.2, 2.6), C(0, 1.4, 0), color, Enum.Material.Fabric)
		part(m, V(1, 1, 1), C(0, 2, -1.6), color, Enum.Material.Fabric)
		for _, x in { -0.6, 0.6 } do
			for _, z in { -0.9, 0.9 } do
				part(m, V(0.3, 0.9, 0.3), C(x, 0.45, z), color:Lerp(Color3.new(0, 0, 0), 0.4))
			end
		end
	end,
	Trofeo = function(m)
		part(m, V(1, 0.3, 1), C(0, 0.15, 0), rgb(120, 90, 50), Enum.Material.Wood)
		part(m, V(0.3, 1, 0.3), C(0, 0.8, 0), rgb(220, 180, 60), Enum.Material.Metal)
		part(m, V(1, 1, 1), C(0, 1.6, 0), rgb(230, 190, 60), Enum.Material.Metal, Enum.PartType.Ball)
	end,
	Marcador = function(m)
		part(m, V(0.8, 0.8, 0.8), C(0, 1.5, 0) * CFrame.Angles(0.6, 0.6, 0), rgb(255, 210, 60), Enum.Material.Neon)
	end,

	-- Misiones locas ------------------------------------------------------
	-- Platillo volante flotando, con su rayo tractor (spec.Height = a qué altura flota)
	Nave = function(m, spec)
		local h = spec.Height or 18
		part(m, V(2, 22, 22), C(0, h, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(170, 180, 195), Enum.Material.Metal, Enum.PartType.Cylinder)
		part(m, V(9, 5, 9), C(0, h + 2, 0), rgb(120, 255, 190), Enum.Material.Glass, Enum.PartType.Ball).Transparency = 0.3
		for i = 0, 7 do
			local a = i * math.pi / 4
			part(m, V(1, 1, 1), C(math.cos(a) * 10, h - 0.6, math.sin(a) * 10), rgb(255, 240, 120), Enum.Material.Neon, Enum.PartType.Ball)
		end
		if spec.Beam ~= false then
			local beam = part(m, V(h, 8, 8), C(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(150, 255, 200), Enum.Material.Neon, Enum.PartType.Cylinder)
			beam.Transparency = 0.75
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Color = rgb(150, 255, 200)
			light.Range = h + 10
			light.Brightness = 4
			light.Parent = m:GetChildren()[1]
		end
	end,
	-- Portal a otra dimensión: anillo que brilla
	Portal = function(m, spec)
		local color = spec.Color or rgb(90, 255, 110)
		part(m, V(0.4, 7, 7), C(0, 4, 0), color, Enum.Material.Neon, Enum.PartType.Cylinder).CFrame = C(0, 4, 0) * CFrame.Angles(0, math.rad(90), 0)
		local inner = part(m, V(0.2, 6, 6), C(0, 4, 0), color:Lerp(Color3.new(1, 1, 1), 0.5), Enum.Material.Neon, Enum.PartType.Cylinder)
		inner.CFrame = C(0, 4, 0) * CFrame.Angles(0, math.rad(90), 0)
		inner.Transparency = 0.5
	end,
	-- Máquina rara de un inventor: caja con luces y una antena
	Maquina = function(m, spec)
		part(m, V(3, 3, 2), C(0, 1.5, 0), spec.Color or rgb(90, 100, 120), Enum.Material.Metal)
		part(m, V(0.2, 3, 0.2), C(0.8, 4.5, 0), rgb(180, 180, 190), Enum.Material.Metal)
		part(m, V(0.7, 0.7, 0.7), C(0.8, 6.1, 0), rgb(255, 60, 90), Enum.Material.Neon, Enum.PartType.Ball)
		for i = -1, 1 do
			part(m, V(0.4, 0.4, 0.1), C(i * 0.8, 2, -1.02), if i == 0 then rgb(60, 255, 120) else rgb(255, 200, 40), Enum.Material.Neon)
		end
	end,
	-- Huevo gigante (de dinosaurio, de alien…)
	Huevo = function(m, spec)
		part(m, V(2.4, 3.2, 2.4), C(0, 1.6, 0), spec.Color or rgb(230, 240, 200), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end,
	-- Los huevos de Petra en su nido (Loco_N3_Pollo): uno de 7,2 de alto (más que tú: unos dos metros),
	-- calentito y con «NO TOCAR» escrito con barro, otros dos más pequeños (uno tumbado) y dos plumas
	-- gigantes en la paja. spec.Brilla: el de en medio da luz (el que hay que mirar).
	HuevoGigante = function(m, spec)
		local shell = spec.Color or rgb(246, 236, 214)
		local function egg(at: CFrame, h: number, solid: boolean): Part
			local bottom = part(m, V(0.73 * h, 0.73 * h, 0.73 * h), at * C(0, 0.365 * h, 0), shell, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			part(m, V(0.6 * h, 0.6 * h, 0.6 * h), at * C(0, 0.6 * h, 0), shell, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			part(m, V(0.42 * h, 0.42 * h, 0.42 * h), at * C(0, 0.79 * h, 0), shell, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			for i = 1, 4 do
				local a = i * 1.9
				local y = 0.2 * h + (i % 3) * 0.17 * h
				local r = 0.36 * h - math.abs(y - 0.365 * h) * 0.35
				part(m, V(0.05 * h, 0.05 * h, 0.05 * h), at * C(math.cos(a) * r, y, math.sin(a) * r), rgb(196, 160, 120), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			end
			for _, p in m:GetChildren() do
				if solid and p:IsA("BasePart") and p.Size.X >= 0.4 * h then
					p.CanCollide = true
					p.CastShadow = true
				end
			end
			return bottom
		end
		local main = egg(CFrame.new(), 7.2, true)
		egg(C(4.7, 0, 1.8) * CFrame.Angles(0, 0, math.rad(-8)), 5.6, false)
		egg(C(-4.4, 1.85, 2.6) * CFrame.Angles(0, math.rad(30), math.rad(78)), 5, false)
		-- «NO TOCAR», con barro y con pata de gallina
		local label = part(m, V(3.6, 1.3, 0.05), C(0, 4.5, -2.3), shell)
		label.Transparency = 1
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.Parent = label
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = "NO TOCAR"
		text.TextScaled = true
		text.Font = Enum.Font.Cartoon
		text.TextColor3 = rgb(96, 64, 36)
		text.Rotation = -6
		text.Parent = gui
		-- Plumas gigantes (de Petra) en la paja
		for i, p in { { -3, -4.5, 30 }, { 6.5, -3.5, -50 } } do
			local feather = C(p[1], 0.75, p[2]) * CFrame.Angles(0, math.rad(p[3]), math.rad(if i == 1 then 8 else -6))
			part(m, V(1.8, 0.12, 6), feather, rgb(250, 247, 238), Enum.Material.Fabric)
			part(m, V(0.18, 0.18, 7), feather * C(0, 0.1, 0.4), rgb(236, 228, 208))
		end
		if spec.Brilla then
			-- Calentito: da una luz cálida
			local light = Instance.new("PointLight")
			light.Color = rgb(255, 196, 120)
			light.Range = 12
			light.Brightness = 1.2
			light.Parent = main
		end
	end,
	-- Una gallina de verdad (Petra cuando ya mide lo que mide una gallina), de World/Kit/GallinaGigante
	Gallina = function(m, spec)
		GallinaGigante.build(spec.Height or 2.2).Parent = m
	end,
	-- Cristal que brilla
	Cristal = function(m, spec)
		local color = spec.Color or rgb(120, 220, 255)
		part(m, V(1, 3, 1), C(0, 1.5, 0) * CFrame.Angles(0, 0.4, 0.15), color, Enum.Material.Neon)
		part(m, V(0.7, 2, 0.7), C(0.7, 1, 0.3) * CFrame.Angles(0.2, 0.9, -0.3), color, Enum.Material.Neon)
	end,
	-- Cohete de cartón (y de verdad, según la misión)
	Cohete = function(m, spec)
		part(m, V(10, 3, 3), C(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90)), spec.Color or rgb(235, 235, 240), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		part(m, V(2.4, 2.4, 2.4), C(0, 10.5, 0), rgb(230, 60, 60), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		for _, a in { 0, 2.1, 4.2 } do
			part(m, V(0.3, 2.5, 1.6), C(math.cos(a) * 1.6, 1.3, math.sin(a) * 1.6) * CFrame.Angles(0, -a, 0), rgb(230, 60, 60))
		end
	end,
	-- Charco de moco brillante (rastro de algo raro)
	Moco = function(m, spec)
		part(m, V(0.2, 3, 3), C(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), spec.Color or rgb(120, 255, 90), Enum.Material.Neon, Enum.PartType.Cylinder).Transparency = 0.2
	end,
	-- Pantalla / ordenador
	Pantalla = function(m, spec)
		part(m, V(3, 2, 0.2), C(0, 3, 0), spec.Color or rgb(40, 200, 255), Enum.Material.Neon)
		part(m, V(0.3, 2, 0.3), C(0, 1, 0.2), rgb(60, 60, 70), Enum.Material.Metal)
	end,
}

-- Construye un objeto suelto de uno de estos tipos (sin misión ni jugador): lo usan otros sistemas,
-- como los encargos de la ciudad (CityErrandService). Las piezas quedan alrededor del origen (el suelo
-- en y = 0) con una base invisible como PrimaryPart: se lleva a su sitio con PivotTo.
function SceneService.buildProp(kind: string, spec: { [string]: any }?): Model
	local model = Instance.new("Model")
	local build = BUILDERS[kind] or BUILDERS.Marcador
	build(model, spec or {})
	local base = Instance.new("Part")
	base.Name = "PropBase"
	base.Size = V(1.5, 1.5, 1.5)
	base.Transparency = 1
	base.Anchored = true
	base.CanCollide = false
	base.CFrame = CFrame.new(0, 0.75, 0)
	base.Parent = model
	model.PrimaryPart = base
	return model
end

local function makeProp(player: Player, questId: string, id: string, def: { [string]: any }, cf: CFrame, mark: BasePart?, isMapObject: boolean): Prop
	local model = Instance.new("Model")
	model.Name = def.Name or id
	if not isMapObject then
		-- Si el lugar es un punto marcado del mapa y el mapa ya tiene el objeto (el quiosco…), basta un marcador
		local kind = if mark and def.OnMark then def.OnMark else (def.Kind or "Marcador")
		local build = BUILDERS[kind] or BUILDERS.Marcador
		build(model, def)
	end
	-- Las piezas se construyeron en el origen: se llevan a su sitio
	local base = Instance.new("Part")
	base.Name = "PropBase"
	base.Size = V(1, 1, 1)
	base.Transparency = 1
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CFrame = CFrame.new()
	base.Parent = model
	model.PrimaryPart = base
	model:PivotTo(cf)
	model:SetAttribute("PropId", id)
	if def.Bed then
		-- Una cama de verdad (la de la residencia…): SleepService le pone el botón «Dormir»
		CollectionService:AddTag(base, "PublicBed")
		base.Size = V(5, 1, 7)
	end
	model.Parent = sceneFolder(player)
	if def.Prompt ~= false and isMapObject and mark then
		-- El objeto de verdad del mapa (el armario, la taquilla…): se marca con un contorno dorado
		local box = Instance.new("SelectionBox")
		box.Adornee = mark
		box.Color3 = rgb(255, 210, 60)
		box.LineThickness = 0.04
		box.SurfaceTransparency = 1
		box.Parent = model
		base.Size = mark.Size
		model:PivotTo(mark.CFrame)
	elseif def.Prompt ~= false then
		local highlight = Instance.new("Highlight")
		highlight.FillTransparency = 0.85
		highlight.OutlineColor = rgb(255, 210, 60)
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
	end
	if def.Prompt ~= false then
		prompt(base, def.Prompt or "Examinar", def.Name or id, player, function()
			if SceneService.onInteract then
				SceneService.onInteract(player, "Prop", questId, id)
			end
		end)
	end
	return { Id = id, Key = "", Model = model }
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------

local function specKey(spec: { [string]: any }): string
	local offset = spec.Offset
	return ("%s|%s|%s|%s"):format(
		tostring(spec.Place),
		tostring(spec.Index),
		if offset then ("%.1f,%.1f,%.1f"):format(offset.X, offset.Y, offset.Z) else "",
		tostring(spec.Mode) .. (if spec.Route then "|route" .. #spec.Route else "")
	)
end

local applyClear -- se define más abajo

-- Crear personajes tarda (Roblox los monta pieza a pieza): las escenas se preparan en una cola por
-- jugador, fuera del bucle de la historia, para no frenar a nadie. Se aplica siempre lo último pedido.
local requests: { [Player]: { { [string]: any } } } = {}
local working: { [Player]: boolean } = {}

local applySet

local function work(player: Player)
	if working[player] then
		return
	end
	working[player] = true
	task.spawn(function()
		while requests[player] and #requests[player] > 0 and player.Parent do
			local request = table.remove(requests[player], 1)
			local ok, err = pcall(function()
				if request.Clear then
					applyClear(player, request.QuestId)
				else
					applySet(player, request.QuestId, request.Actors, request.Props, request.Defs)
				end
			end)
			if not ok then
				warn("[SceneService] " .. tostring(err))
			end
		end
		working[player] = nil
	end)
end

local function enqueue(player: Player, request: { [string]: any })
	local queue = requests[player] or {}
	requests[player] = queue
	-- Si ya había una petición pendiente para esa misión, la nueva la sustituye
	for i = #queue, 1, -1 do
		if queue[i].QuestId == request.QuestId then
			table.remove(queue, i)
		end
	end
	table.insert(queue, request)
	work(player)
end

-- Pone la escena de una misión: estos actores y estos objetos (definiciones en `defs`, por Id)
function SceneService.set(player: Player, questId: string, actors: { { [string]: any } }, props: { string }, defs: { [string]: any }?)
	enqueue(player, { QuestId = questId, Actors = actors, Props = props, Defs = defs })
end

local spaced: (CFrame, BasePart?, { Vector3 }) -> CFrame
-- Que nadie aparezca encima de ti ni de otro: a 5 studs de ti como poco y a 3 de los demás de la
-- escena (antes, al llegar a casa, la abuela salía pegada a tu cara y la cámara se le metía dentro)
spaced = function(cf: CFrame, me: BasePart?, others: { Vector3 }): CFrame
	local pos = cf.Position
	if me then
		local flat = V(pos.X - me.Position.X, 0, pos.Z - me.Position.Z)
		if flat.Magnitude < 5 then
			local dir = if flat.Magnitude > 0.2 then flat.Unit else V(me.CFrame.LookVector.X, 0, me.CFrame.LookVector.Z).Unit
			pos = V(me.Position.X, pos.Y, me.Position.Z) + dir * 5
		end
	end
	for _, other in others do
		local flat = V(pos.X - other.X, 0, pos.Z - other.Z)
		if flat.Magnitude < 3 then
			local side = if flat.Magnitude > 0.2 then flat.Unit else V(1, 0, 0)
			pos += side * (3 - flat.Magnitude)
		end
	end
	return CFrame.new(pos) * cf.Rotation
end

function applySet(player: Player, questId: string, actors: { { [string]: any } }, props: { string }, defs: { [string]: any }?)
	scenes[player] = scenes[player] or {}
	local byQuest = scenes[player]
	local scene = byQuest[questId]
	if not scene then
		scene = { Actors = {}, Props = {} }
		Log.info("SCENE", "begin %s (%s): %d actores, %d objetos", questId, player.Name, #actors, #props)
	end
	byQuest[questId] = scene
	scene.Last = { Actors = actors, Props = props, Defs = defs } -- (para volver a montarla si cambias de misión)
	-- Crear un personaje espera a Roblox: si mientras tanto el jugador se fue (o la escena se quitó),
	-- lo recién creado se borra y se deja de montar (si no, quedaban actores fantasma en el mapa)
	local function gone(): boolean
		return not player.Parent or scenes[player] ~= byQuest or byQuest[questId] ~= scene
	end

	-- Actores
	local placedNow: { Vector3 } = {}
	local wanted: { [string]: { [string]: any } } = {}
	for _, spec in actors do
		wanted[spec.Npc] = spec
	end
	for npc, actor in scene.Actors do
		if not wanted[npc] then
			actor.Model:Destroy()
			scene.Actors[npc] = nil
		end
	end
	-- Los que se quedan donde están también ocupan su hueco (si no, uno nuevo podía salir encima)
	for npc, spec in wanted do
		local actor = scene.Actors[npc]
		if actor and actor.Key == specKey(spec) then
			table.insert(placedNow, actor.Home.Position)
		end
	end
	for npc, spec in wanted do
		local key = specKey(spec)
		local actor = scene.Actors[npc]
		if actor and actor.Key == key then
			-- (si se quedó de pie porque allí no había asiento, sigue de pie: si no, al siguiente paso se
			-- volvía a "sentar" en el aire)
			if not (actor.Spec and actor.Spec.SitDowngraded and spec.Mode == "Sit") then
				actor.Spec = spec
			end
			continue
		end
		-- ¿Ya sale en la escena de otra misión tuya? Nunca dos Ivanes: se lo queda la misión que juegas
		-- ahora (se le quita a la otra); si esta no es la que juegas, se queda donde está en la otra
		if not actor then
			local elsewhere = nil
			for otherId, other in byQuest do
				if otherId ~= questId and other.Actors[npc] then
					elsewhere = other
					break
				end
			end
			if elsewhere then
				if player:GetAttribute("StoryFocus") ~= questId then
					continue
				end
				elsewhere.Actors[npc].Model:Destroy()
				elsewhere.Actors[npc] = nil
			end
		end
		-- Acompañante: aparece a tu lado solo si su misión es la que juegas ahora y vas a pie (si no,
		-- en su sitio de la escena); cada uno en un hueco distinto (antes salían todos en el mismo punto)
		local me = playerRoot(player)
		-- Acompañante (sin sitio propio) de una misión que no juegas ahora: no sale delante de ti. Antes
		-- caía en "CercaDeTi" (el lugar por defecto) y se quedaba plantado en la calle esperándote
		-- ({abu} del tirachinas salía en la acera mientras jugabas otra misión). Si ya estaba en la
		-- escena, se queda donde está (en casa, en el parque…); si no, aparece cuando juegues su misión.
		if spec.Mode == "Follow" and spec.Place == nil and not focusOn(player, questId) then
			if actor then
				actor.Spec = spec
				actor.Key = key
				if actor.Root then
					table.insert(placedNow, actor.Root.Position)
				end
			end
			continue
		end
		local nearMe = spec.Mode == "Follow" and me ~= nil and focusOn(player, questId) and onFoot(player)
		local cf = if nearMe then (me :: BasePart).CFrame * CFrame.new(3 + #placedNow * 2.5, -3, 5) else placement(player, spec)
		if nearMe and cf then
			-- (apoyado en el suelo: con un jugador niño, en una escalera o saltando quedaba hundido o flotando)
			cf = CFrame.new(groundAt(cf.Position, {})) * cf.Rotation
		end
		if cf and spec.Mode ~= "Sit" then
			cf = spaced(cf, me, placedNow)
		end
		if cf then
			table.insert(placedNow, cf.Position)
		end
		if not cf then
			if actor then
				actor.Model:Destroy()
				scene.Actors[npc] = nil
			end
			continue
		end
		if spec.Mode == "Sit" and not seatAt(cf.Position) then
			spec = table.clone(spec)
			spec.Mode = "Idle"
			spec.SitDowngraded = true
		end
		if actor and actor.Root and (actor.Root.Position - cf.Position).Magnitude < 70 then
			-- Camina hasta su nuevo sitio
			actor.Spec = spec
			actor.Key = key
			local mode = spec.Mode or "Idle"
			if mode == "Follow" or mode == "Wander" or mode == "Flee" or mode == "Hunt" then
				-- Se mueve por su cuenta (stepActor): desde donde está
				stopPath(actor)
				actor.WalkId += 1
				actor.Walk = nil
				actor.Home = cf
				-- (empieza de cero: ruta de huida nueva y sin tiempos de antes, que lo hacían "saltar")
				actor.Route = nil
				actor.RouteIndex = 1
				actor.LastProgress = os.clock()
				actor.LastPosition = nil
				applyMode(actor)
				if actor.Humanoid and mode == "Wander" then
					actor.Humanoid:MoveTo(cf.Position)
				end
			else
				startWalk(actor, cf)
			end
			continue
		end
		if actor then
			actor.Model:Destroy()
		end
		-- ¿Está ese personaje por aquí cerca (Nico en el patio, la profe en su aula…)? Entonces sale de
		-- donde está y va andando hasta su sitio de la escena, en vez de aparecer de la nada. (Tu pantalla
		-- oculta al de siempre en cuanto llega el de tu escena: nunca se ven dos.)
		local from = if actor == nil and spec.Mode ~= "Follow" and spec.Mode ~= "Flee" then SceneService.ambientStart(spec.Npc, cf.Position) else nil
		local created = makeActor(player, questId, spec, from or cf, from ~= nil)
		if gone() then
			created.Model:Destroy()
			return
		end
		created.Key = key
		scene.Actors[npc] = created
		if from then
			created.Home = cf
			if spec.Mode ~= "Wander" then
				startWalk(created, cf)
			end
		end
	end

	-- Objetos
	local wantedProps: { [string]: boolean } = {}
	for _, id in props do
		wantedProps[id] = true
	end
	for id, prop in scene.Props do
		if not wantedProps[id] then
			prop.Model:Destroy()
			scene.Props[id] = nil
		end
	end
	for id in wantedProps do
		local def = defs and defs[id]
		if not def or scene.Props[id] then
			continue
		end
		local cf, mark, isMapObject = placement(player, def, true)
		if cf then
			local created = makeProp(player, questId, id, def, cf, mark, isMapObject)
			if gone() then
				created.Model:Destroy()
				return
			end
			scene.Props[id] = created
		else
			Log.warn("SCENE", "%s (%s): el objeto %s no tiene sitio en el mapa", questId, player.Name, id)
		end
	end
end

-- Dónde está ahora el personaje de siempre (los que viven en el mapa: StaticNpc con NpcId), si está
-- a menos de `range` studs de `target` y se puede ir andando. Devuelve sus pies, mirando hacia target.
SceneService.AmbientRange = 110
function SceneService.ambientStart(npcId: string, target: Vector3, range: number?): CFrame?
	local best: Model? = nil
	local bestDistance = range or SceneService.AmbientRange
	for _, model in CollectionService:GetTagged("StaticNpc") do
		if model:IsA("Model") and model:GetAttribute("NpcId") == npcId and model:IsDescendantOf(workspace) then
			local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local offset = root.Position - target
				local distance = V(offset.X, 0, offset.Z).Magnitude
				if distance < bestDistance and math.abs(offset.Y) < 12 then
					best, bestDistance = model, distance
				end
			end
		end
	end
	if not best or bestDistance < 3 then
		return nil
	end
	local root = best:FindFirstChild("HumanoidRootPart") :: BasePart
	local feet = groundAt(root.Position, { best })
	local toward = V(target.X - feet.X, 0, target.Z - feet.Z)
	if toward.Magnitude < 0.1 then
		return nil
	end
	return CFrame.lookAt(feet, feet + toward)
end

-- Quita toda la escena de una misión
-- Cambias de misión: se vuelven a montar tus escenas (el personaje compartido pasa a la que juegas)
function SceneService.refocus(player: Player)
	local byQuest = scenes[player]
	if not byQuest then
		return
	end
	local focus = player:GetAttribute("StoryFocus")
	-- Primero las otras (sueltan a quien comparte), luego la que juegas (se lo queda)
	for questId, scene in byQuest do
		if questId ~= focus and scene.Last then
			enqueue(player, { QuestId = questId, Actors = scene.Last.Actors, Props = scene.Last.Props, Defs = scene.Last.Defs })
		end
	end
	local mine = focus and byQuest[focus]
	if mine and mine.Last then
		enqueue(player, { QuestId = focus, Actors = mine.Last.Actors, Props = mine.Last.Props, Defs = mine.Last.Defs })
	end
end

function SceneService.clear(player: Player, questId: string)
	enqueue(player, { QuestId = questId, Clear = true })
end

function applyClear(player: Player, questId: string)
	local byQuest = scenes[player]
	local scene = byQuest and byQuest[questId]
	if not scene then
		return
	end
	for _, actor in scene.Actors do
		actor.Model:Destroy()
	end
	for _, prop in scene.Props do
		prop.Model:Destroy()
	end
	byQuest[questId] = nil
	Log.info("SCENE", "end %s (%s)", questId, player.Name)
end

-- (Vigilante) Olvida los actores y objetos rotos de una escena (borrados, caídos del mapa, sin
-- cuerpo) para que el siguiente SceneService.set los vuelva a crear en su sitio
function SceneService.respawn(player: Player, questId: string)
	local scene = scenes[player] and scenes[player][questId]
	if not scene then
		return
	end
	for npc, actor in scene.Actors do
		if not actor.Model.Parent or not actor.Root or not actor.Root:IsDescendantOf(workspace) then
			pcall(function()
				actor.Model:Destroy()
			end)
			scene.Actors[npc] = nil
			Log.warn("NPC", "respawn %s (%s · %s)", npc, questId, player.Name)
		end
	end
	for id, prop in scene.Props do
		if not prop.Model.Parent then
			scene.Props[id] = nil
			Log.warn("SCENE", "respawn del objeto %s (%s · %s)", id, questId, player.Name)
		end
	end
end

-- Un objeto que ya se usó y desaparece (un libro recogido)
function SceneService.removeProp(player: Player, questId: string, id: string)
	local scene = scenes[player] and scenes[player][questId]
	local prop = scene and scene.Props[id]
	if prop then
		prop.Model:Destroy()
		scene.Props[id] = nil
	end
end

function SceneService.propPosition(player: Player, questId: string, id: string): Vector3?
	local scene = scenes[player] and scenes[player][questId]
	local prop = scene and scene.Props[id]
	return prop and prop.Model:GetPivot().Position
end

function SceneService.hasProp(player: Player, questId: string, id: string): boolean
	local scene = scenes[player] and scenes[player][questId]
	return scene ~= nil and scene.Props[id] ~= nil
end

-- El modelo de un personaje en cualquier escena de este jugador (para la cámara de los diálogos)
function SceneService.actorOf(player: Player, npc: string): Model?
	for _, scene in scenes[player] or {} do
		local actor = scene.Actors[npc]
		if actor then
			return actor.Model
		end
	end
	return nil
end

-- (Depuración) Los actores de las escenas de este jugador: quién, dónde, qué hace y si habla contigo
function SceneService.debugActors(player: Player): { { [string]: any } }
	local list = {}
	local me = playerRoot(player)
	for questId, scene in scenes[player] or {} do
		for npc, actor in scene.Actors do
			local root = actor.Root
			local position = root and root.Position
			local home = actor.Home.Position
			table.insert(list, {
				Npc = npc,
				Quest = questId,
				Mode = actor.Spec.Mode or "Idle",
				Distance = if position and me then math.round((position - me.Position).Magnitude) else nil,
				Target = if position and V(position.X - home.X, 0, position.Z - home.Z).Magnitude > 2.5
					then ("(%d, %d, %d)"):format(math.round(home.X), math.round(home.Y), math.round(home.Z))
					else nil,
				Talking = actor.Talking == true,
				Stuck = actor.StuckSince ~= nil and os.clock() - actor.StuckSince > 4,
			})
		end
	end
	return list
end

function SceneService.hasActor(player: Player, questId: string, npc: string): boolean
	local scene = scenes[player] and scenes[player][questId]
	return scene ~= nil and scene.Actors[npc] ~= nil
end

-- Un gesto puntual (saludar, celebrar, señalar)
function SceneService.gesture(player: Player, npc: string, name: string)
	for _, scene in scenes[player] or {} do
		local actor = scene.Actors[npc]
		if actor then
			play(actor, name)
			task.delay(2.5, function()
				-- (si va andando a su sitio, no: se quedaría clavado a medio camino; al llegar ya se pone)
				if actor.Model.Parent and actor.Walk == nil then
					applyMode(actor)
				end
			end)
		end
	end
end

-- ¿Te ha atrapado un enemigo (modo Hunt)? Devuelve quién (o nil). Solo cuenta a los que no están aturdidos.
function SceneService.caught(player: Player, questId: string, radius: number): string?
	local scene = scenes[player] and scenes[player][questId]
	local me = playerRoot(player)
	if not scene or not me then
		return nil
	end
	for npc, actor in scene.Actors do
		if actor.Spec.Mode == "Hunt" and actor.Root and not (actor.StunnedUntil and os.clock() < actor.StunnedUntil) then
			local offset = actor.Root.Position - me.Position
			if V(offset.X, 0, offset.Z).Magnitude <= radius and math.abs(offset.Y) < 8 then
				-- Tras atraparte se queda un momento quieto (si no, te atraparía otra vez al reaparecer)
				actor.StunnedUntil = os.clock() + 3
				return npc
			end
		end
	end
	return nil
end

-- Un rayo desde tu mano hasta el enemigo: destello, retrocede y se queda aturdido un momento.
-- scale: si se da, el enemigo cambia a ese tamaño (el rayo encogedor: Petra mengua a cada disparo)
function SceneService.hit(player: Player, questId: string, npc: string, color: Color3?, scale: number?)
	local scene = scenes[player] and scenes[player][questId]
	local actor = scene and scene.Actors[npc]
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("HumanoidRootPart")) :: BasePart?
	if not actor or not actor.Root then
		return
	end
	local target = actor.Root.Position + V(0, 1, 0)
	local beamColor = color or rgb(90, 255, 120)
	if hand then
		local from = hand.Position
		local length = (target - from).Magnitude
		local beam = Instance.new("Part")
		beam.Name = "Rayo"
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.CastShadow = false
		beam.Material = Enum.Material.Neon
		beam.Color = beamColor
		beam.Size = V(0.25, 0.25, length)
		beam.CFrame = CFrame.lookAt(from, target) * CFrame.new(0, 0, -length / 2)
		beam.Parent = sceneFolder(player)
		task.delay(0.12, function()
			beam:Destroy()
		end)
	end
	local flash = Instance.new("Highlight")
	flash.FillColor = Color3.new(1, 1, 1)
	flash.FillTransparency = 0.1
	flash.OutlineTransparency = 1
	flash.Parent = actor.Model
	task.delay(0.15, function()
		flash:Destroy()
	end)
	actor.StunnedUntil = os.clock() + 1.2
	if scale and scale > 0 then
		pcall(function()
			-- Encoge sin hundirse ni flotar: los pies se quedan donde estaban
			local root = actor.Root :: BasePart
			local humanoid = actor.Humanoid
			local feet = root.Position.Y - root.Size.Y / 2 - (if humanoid then humanoid.HipHeight else 0)
			actor.Model:ScaleTo(scale)
			local now = root.Position.Y - root.Size.Y / 2 - (if humanoid then humanoid.HipHeight else 0)
			actor.Model:PivotTo(actor.Model:GetPivot() + V(0, feet - now, 0))
		end)
	end
	local me = playerRoot(player)
	if me and not actor.Root.Anchored then
		local away = V(actor.Root.Position.X - me.Position.X, 0, actor.Root.Position.Z - me.Position.Z)
		if away.Magnitude > 0.1 then
			actor.Model:PivotTo(actor.Model:GetPivot() + away.Unit * 3)
		end
	end
end

-- Derrotado: chispas, sube flotando y desaparece (vuelve teletransportado a su nave / su dimensión).
-- style = "Shrink": en vez de flotar, se encoge hasta su tamaño de verdad y se va (Petra al gallinero)
function SceneService.defeat(player: Player, questId: string, npc: string, style: string?)
	local scene = scenes[player] and scenes[player][questId]
	local actor = scene and scene.Actors[npc]
	if not actor then
		return
	end
	scene.Actors[npc] = nil
	local model = actor.Model
	anchorActor(actor, true)
	local root = actor.Root
	if root then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = ColorSequence.new(rgb(140, 255, 160), rgb(255, 255, 255))
		sparks.LightEmission = 1
		sparks.Size = NumberSequence.new(0.4, 0)
		sparks.Speed = NumberRange.new(4, 9)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Lifetime = NumberRange.new(0.4, 0.9)
		sparks.Rate = 0
		sparks.Parent = root
		sparks:Emit(60)
	end
	for _, prompt in model:GetDescendants() do
		if prompt:IsA("ProximityPrompt") then
			prompt.Enabled = false
		end
	end
	task.spawn(function()
		if style == "Shrink" then
			-- Mengua del todo (de pie en el suelo) y luego se desvanece
			for _ = 1, 10 do
				if not model.Parent then
					return
				end
				pcall(function()
					local before = model:GetPivot().Position.Y - model:GetScale() * 3
					model:ScaleTo(math.max(0.25, model:GetScale() * 0.85))
					local after = model:GetPivot().Position.Y - model:GetScale() * 3
					model:PivotTo(model:GetPivot() + V(0, before - after, 0))
				end)
				task.wait(0.06)
			end
		end
		for i = 1, 12 do
			if not model.Parent then
				return
			end
			if style ~= "Shrink" then
				model:PivotTo(model:GetPivot() + V(0, 0.5, 0))
			end
			for _, piece in model:GetDescendants() do
				if piece:IsA("BasePart") and piece.Name ~= "HumanoidRootPart" then
					piece.Transparency = math.max(piece.Transparency, i / 12)
				end
			end
			task.wait(0.05)
		end
		model:Destroy()
	end)
end

-- Pone al jugador en un lugar (principio de una escena: despertar en la cama…)
-- where = "HomeDormitorio" o { Place, Index?, Offset? } (un pupitre concreto…)
function SceneService.teleport(player: Player, where: any)
	local root = playerRoot(player)
	local spot = if type(where) == "table"
		then LocationService.resolve(player, where.Place, { Index = where.Index, Offset = where.Offset })
		else LocationService.resolve(player, where)
	if not root or not spot then
		return
	end
	SceneService.teleportTo(player, spot.Position)
end

-- Pone al jugador en un punto concreto del mapa (apoyado en el suelo)
function SceneService.teleportTo(player: Player, target: Vector3)
	local root = playerRoot(player)
	if not root then
		return
	end
	-- Mientras dura el salto lleva "Teleporting" (el mismo que pone InteriorService): así el autobús
	-- o el avión no lo vuelven a sentar al levantarse. Solo se quita si lo ha puesto aquí.
	local mine = not player:GetAttribute("Teleporting")
	if mine then
		player:SetAttribute("Teleporting", true)
	end
	-- Primero se baja del vehículo (o se levanta del banco): si no, se lo llevaría con él (y a quien
	-- vaya dentro) o se quedaría soldado al asiento. (require aquí dentro: sin requires en círculo)
	pcall(function()
		require(script.Parent.VehicleService).standUp(player)
	end)
	-- A la calle (las salas de los edificios están en el cielo): ya no estás dentro de ninguna
	if target.Y < 3000 and player:GetAttribute("InteriorKey") then
		player:SetAttribute("InteriorKey", nil)
		player:SetAttribute("InteriorDoor", nil)
		player:SetAttribute("TowerFloor", nil)
	end
	pcall(function()
		player:RequestStreamAroundAsync(target, 3)
	end)
	local ok = pcall(function()
		local position = groundAt(target + V(0, 1, 0), { player.Character :: Instance })
		root.AssemblyLinearVelocity = Vector3.zero
		;(player.Character :: Model):PivotTo(CFrame.new(position + V(0, 3, 0)) * root.CFrame.Rotation)
	end)
	if mine and player.Parent then
		player:SetAttribute("Teleporting", nil)
	end
	if not ok then
		warn("[SceneService] No se pudo llevar a " .. player.Name .. " a su sitio")
	end
end

---------------------------------------------------------------------
-- Movimiento: seguir al jugador, pasear, mirar a quien habla
---------------------------------------------------------------------

-- Gira el cuerpo hacia un punto poco a poco (unos 0,3 s): la cabeza ya mira antes (ActorLife, en
-- el cliente), así que parece natural: primero mira, luego se vuelve
SceneService.TurnSeconds = 0.3
local function faceSmooth(actor: Actor, target: Vector3)
	local root = actor.Root
	if not root or actor.Facing then
		return
	end
	local from = actor.Model:GetPivot()
	local flat = V(target.X - from.Position.X, 0, target.Z - from.Position.Z)
	if flat.Magnitude < 0.5 then
		return
	end
	local want = CFrame.lookAt(from.Position, from.Position + flat)
	if want.LookVector:Dot(from.LookVector) > 0.985 then
		return -- ya mira hacia allí
	end
	actor.Facing = true
	task.spawn(function()
		local start = os.clock()
		local rotation = from.Rotation
		while actor.Model.Parent do
			local t = math.min(1, (os.clock() - start) / SceneService.TurnSeconds)
			local eased = t * t * (3 - 2 * t)
			actor.Model:PivotTo(CFrame.new(actor.Model:GetPivot().Position) * rotation:Lerp(want.Rotation, eased))
			if t >= 1 then
				break
			end
			task.wait()
		end
		actor.Facing = false
	end)
end

-- ¿Habla ahora este personaje con el jugador? (DialogueService pone TalkingTo = "Nico,Sara")
local function talkingWith(player: Player, npc: string): boolean
	local list = player:GetAttribute("TalkingTo")
	if type(list) ~= "string" then
		return false
	end
	for id in list:gmatch("[^,]+") do
		if id == npc then
			return true
		end
	end
	return false
end

local FALL_LIMIT = 40 -- más abajo que esto de su sitio: se ha caído del mapa
local LOST_LIMIT = 260 -- más lejos que esto de su sitio (sin seguir a nadie): se ha perdido

-- ¿Te sigue ahora? Solo los de la misión que estás jugando (StoryFocus: LifeStoryService)
-- ¿Juegas ahora esta misión? (sin ninguna seguida —p. ej. en horario de cole, con las demás en
-- espera— no se juega ninguna: antes entonces te seguían todos los acompañantes)
focusOn = function(player: Player, questId: string?): boolean
	if questId == nil then
		return true -- (personajes sin misión)
	end
	return player:GetAttribute("StoryFocus") == questId
end

-- ¿Vas a pie y en la calle? (ni sentado en un coche, autobús o metro, ni dentro de un edificio: ahí
-- no te sigue nadie; al volver a la calle te alcanza)
onFoot = function(player: Player): boolean
	if player:GetAttribute("InteriorKey") ~= nil or player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil then
		return false
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return not (humanoid and humanoid.SeatPart)
end

local function followsNow(player: Player, actor: Actor): boolean
	return focusOn(player, actor.Quest) and onFoot(player)
end

local function stepActor(player: Player, actor: Actor, index: number)
	local humanoid, root = actor.Humanoid, actor.Root
	if not humanoid or not root or not actor.Model.Parent then
		return
	end
	local mode = actor.Spec.Mode or "Idle"
	local me = playerRoot(player)
	-- Vigilante: caído del mapa, perdido o flotando lejos de su sitio -> vuelve a su sitio
	local roaming = mode == "Follow" or mode == "Hunt" or mode == "Flee"
	local home = actor.Home.Position
	-- (quien te sigue o te persigue baja contigo: se mide desde lo más bajo entre su sitio y tú)
	local floorY = if roaming and me then math.min(home.Y, me.Position.Y) else home.Y
	if root.Position.Y < floorY - FALL_LIMIT or (not roaming and V(root.Position.X - home.X, 0, root.Position.Z - home.Z).Magnitude > LOST_LIMIT) then
		if not actor.Recovered or os.clock() - actor.Recovered > 5 then
			actor.Recovered = os.clock()
			Log.warn("NPC", "stuck %s (%s): lejos de su sitio o caído, vuelve a su sitio", actor.Npc, player.Name)
			standAt(actor, actor.Home)
			actor.StuckSince = nil
			applyMode(actor)
			Log.info("NPC", "recovered %s (%s)", actor.Npc, player.Name)
		end
		return
	end
	-- Conversación: quien habla contigo se para y se vuelve hacia ti (sin meterse encima)
	local talking = me ~= nil and talkingWith(player, actor.Npc) and mode ~= "Hunt" and mode ~= "Flee"
	if talking and me then
		if not actor.Talking then
			actor.Talking = true
			if not root.Anchored then
				humanoid:MoveTo(root.Position) -- se para donde está
				play(actor, "Idle") -- (antes seguía con la animación de andar, sin moverse)
			end
		end
		local toMe = V(me.Position.X - root.Position.X, 0, me.Position.Z - root.Position.Z)
		if mode ~= "Sit" and toMe.Magnitude < 30 then
			faceSmooth(actor, me.Position)
		end
		if not root.Anchored and toMe.Magnitude > 1 then
			-- Quieto a unos pasos (nunca dentro de ti): si está a menos de 4, se queda donde está
			humanoid:MoveTo(root.Position)
		end
		return
	elseif actor.Talking then
		actor.Talking = false
		-- El rato de charla no cuenta como "atascado" (antes al acabar se fundía y reaparecía en su sitio)
		if actor.StuckSince then
			actor.StuckSince = os.clock()
		end
		actor.LastProgress = os.clock()
		actor.LastPosition = nil
		-- Fin de la conversación: vuelve a lo suyo (y a mirar hacia donde miraba)
		if mode ~= "Sit" and actor.Spec.Look ~= nil and root.Anchored then
			faceSmooth(actor, actor.Model:GetPivot().Position + actor.Home.LookVector * 10)
		end
	end
	if mode == "Flee" then
		-- Huye por su ruta (pasillo → patio → gimnasio…). Si se atasca en una pared, "atajo": aparece en el
		-- siguiente punto. Al final de la ruta se queda escondido esperando a que llegues.
		if not actor.Route then
			actor.Route = {}
			for _, stop in actor.Spec.Route or {} do
				local placeId = if type(stop) == "table" then stop.Place else stop
				local spot = LocationService.resolve(player, placeId, if type(stop) == "table" then { Offset = stop.Offset } else nil)
				if spot then
					table.insert(actor.Route :: { Vector3 }, groundAt(spot.Position + V(0, 0.5, 0), {}))
				end
			end
		end
		local route = actor.Route :: { Vector3 }
		local target = route[actor.RouteIndex]
		if target then
			humanoid.WalkSpeed = actor.Spec.Speed or 16
			local flat = V(root.Position.X - target.X, 0, root.Position.Z - target.Z)
			if flat.Magnitude < 4 then
				actor.RouteIndex += 1
				actor.LastProgress = os.clock()
			else
				humanoid:MoveTo(target)
				local moved = if actor.LastPosition then (root.Position - actor.LastPosition).Magnitude else 1
				if moved > 0.5 then
					actor.LastProgress = os.clock()
				elseif os.clock() - actor.LastProgress > 3 then
					actor.Model:PivotTo(CFrame.new(target + V(0, 3, 0)))
					actor.LastProgress = os.clock()
				end
			end
			actor.LastPosition = root.Position
		end
	elseif mode == "Hunt" and me and not followsNow(player, actor) then
		-- Enemigo de otra misión (o vas en coche, en metro o dentro de un edificio): no te persigue
		if not root.Anchored and humanoid.MoveDirection.Magnitude > 0.1 then
			humanoid:MoveTo(root.Position)
		end
	elseif mode == "Hunt" and me then
		-- Te persigue (enemigo): va a por ti, sin atravesarte; si se atasca, "salta" un poco hacia ti
		humanoid.WalkSpeed = actor.Spec.Speed or 13
		local offset = V(me.Position.X - root.Position.X, 0, me.Position.Z - root.Position.Z)
		local distance = offset.Magnitude
		if actor.StunnedUntil and os.clock() < actor.StunnedUntil then
			humanoid:MoveTo(root.Position)
		elseif distance > 120 then
			-- Demasiado lejos (te has teletransportado): reaparece cerca
			actor.Model:PivotTo(CFrame.new(me.Position - offset.Unit * 25 + V(0, 3, 0)))
		elseif distance > 2 then
			humanoid:MoveTo(me.Position - offset.Unit * 1.5)
			local moved = if actor.LastPosition then (root.Position - actor.LastPosition).Magnitude else 1
			if moved > 0.3 then
				actor.LastProgress = os.clock()
			elseif os.clock() - actor.LastProgress > 3 then
				actor.Model:PivotTo(CFrame.new(root.Position + offset.Unit * 6 + V(0, 3, 0)))
				actor.LastProgress = os.clock()
			end
			actor.LastPosition = root.Position
		end
	elseif mode == "Follow" and me and not followsNow(player, actor) then
		-- Acompañante de otra misión (no la que juegas ahora), o vas en coche, en metro o dentro de un
		-- edificio: se queda donde está esperándote. Si se había quedado muy lejos de su sitio (te siguió
		-- a otro barrio o a un interior), vuelve a su sitio.
		if V(root.Position.X - home.X, 0, root.Position.Z - home.Z).Magnitude > LOST_LIMIT or math.abs(root.Position.Y - home.Y) > 200 then
			if not actor.Recovered or os.clock() - actor.Recovered > 5 then
				actor.Recovered = os.clock()
				standAt(actor, actor.Home)
			end
		elseif humanoid.MoveDirection.Magnitude > 0.1 then
			humanoid:MoveTo(root.Position)
		end
	elseif mode == "Follow" and me then
		-- Detrás del jugador, cada uno a un lado
		local side = if index % 2 == 0 then 1 else -1
		local target = me.Position + me.CFrame.RightVector * side * (2 + index) - me.CFrame.LookVector * (3 + index)
		local distance = (root.Position - me.Position).Magnitude
		if distance > 90 then
			actor.Model:PivotTo(CFrame.new(target) * me.CFrame.Rotation)
		elseif distance > 7 then
			humanoid.WalkSpeed = math.clamp(distance, 14, 24)
			humanoid:MoveTo(target)
			-- Atascado contra una pared o una esquina: aparece detrás de ti
			local moved = if actor.LastPosition then (root.Position - actor.LastPosition).Magnitude else 1
			if moved > 0.3 then
				actor.LastProgress = os.clock()
			elseif os.clock() - actor.LastProgress > 3 then
				actor.Model:PivotTo(CFrame.new(target + V(0, 3, 0)) * me.CFrame.Rotation)
				actor.LastProgress = os.clock()
			end
			actor.LastPosition = root.Position
		else
			actor.LastProgress = os.clock()
			actor.LastPosition = nil
		end
	elseif mode == "Wander" then
		if os.clock() > actor.NextWander then
			actor.NextWander = os.clock() + math.random(30, 60) / 10
			local angle = math.random() * math.pi * 2
			local radius = actor.Spec.Radius or 10
			humanoid:MoveTo(actor.Home.Position + V(math.cos(angle) * radius, 0, math.sin(angle) * radius))
		end
		-- Atascado lejos de su zona (contra una pared): fundido y aparece en su sitio
		local moved = if actor.LastPosition then (root.Position - actor.LastPosition).Magnitude else 1
		local away = V(root.Position.X - home.X, 0, root.Position.Z - home.Z).Magnitude
		if moved > 0.3 or away < (actor.Spec.Radius or 10) + 15 then
			actor.LastProgress = os.clock()
		elseif os.clock() - actor.LastProgress > 4 and actor.Walk ~= "Fade" then
			actor.LastProgress = os.clock()
			fadeTo(actor)
		end
		actor.LastPosition = root.Position
	elseif actor.Walk == "Settle" or actor.Walk == "Fade" then
		-- Colocándose en su sitio o en pleno fundido: ya acaba solo
		return
	elseif actor.Walk == "Walk" or not root.Anchored then
		-- Va andando hasta su sitio (por el camino); al llegar se coloca, si no puede, fundido
		stepWalk(actor)
	elseif ONE_SHOT[mode] then
		-- Saluda / celebra / se ríe / señala otra vez cada pocos segundos (no se queda congelado)
		if os.clock() > actor.NextWander then
			actor.NextWander = os.clock() + math.random(40, 70) / 10
			actor.Playing = nil
			play(actor, mode)
		end
	elseif mode == "Idle" and me and actor.Spec.Look == nil then
		-- Quieto: la cabeza y el cuerpo te siguen en tu pantalla (ActorLife, suave). Si te pones detrás
		-- de él, se da la vuelta poco a poco, con unos pasitos (antes giraba de golpe)
		local toMe = V(me.Position.X - root.Position.X, 0, me.Position.Z - root.Position.Z)
		if toMe.Magnitude < 22 and toMe.Magnitude > 1 and os.clock() > (actor.TurnUntil or 0) then
			local want = CFrame.lookAt(root.Position, root.Position + toMe)
			local angle = yawBetween(root.CFrame, want)
			if angle > math.rad(100) then
				local seconds = math.clamp(angle * 0.3, 0.35, 0.9)
				actor.TurnUntil = os.clock() + seconds + 1.5
				play(actor, "Walk")
				local walk = actor.Tracks.Walk
				if walk then
					walk:AdjustSpeed(0.6)
				end
				TweenService:Create(root, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					CFrame = CFrame.new(root.Position) * want.Rotation,
				}):Play()
				task.delay(seconds, function()
					if actor.Model.Parent and actor.Playing == "Walk" and root.Anchored and actor.Walk == nil then
						play(actor, "Idle")
					end
				end)
			end
		end
	end
	-- Andar, correr o estar quieto (la animación va al paso de sus pies, y a su tamaño: un niño da
	-- más pasos para ir igual de rápido)
	if not root.Anchored then
		local speed = V(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
		local name = if speed > 17 then "Run" elseif speed > 1 then "Walk" else "Idle"
		play(actor, name)
		local track = actor.Tracks[name]
		if track and name ~= "Idle" then
			local stride = (if name == "Run" then 20 else 12) * scaleOf(actor.Model)
			track:AdjustSpeed(math.clamp(speed / stride, 0.6, 1.8))
		end
	end
end

function SceneService.init()
	folder = workspace:FindFirstChild("StoryScenes") :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "StoryScenes"
		folder.Parent = workspace
	end
	Players.PlayerRemoving:Connect(function(player)
		requests[player] = nil
		for questId in scenes[player] or {} do
			applyClear(player, questId)
		end
		scenes[player] = nil
		local f = folder:FindFirstChild("Scene_" .. player.UserId)
		if f then
			f:Destroy()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.3)
			for player, byQuest in scenes do
				for _, scene in byQuest do
					local index = 0
					for _, actor in scene.Actors do
						index += 1
						local ok, err = pcall(stepActor, player, actor, index)
						if not ok then
							warn("[SceneService] " .. tostring(err))
						end
					end
				end
			end
		end
	end)
end

SceneService._followsNow = function(player, quest) return focusOn(player, quest) and onFoot(player) end
return SceneService
