-- SceneService: los ACTORES y OBJETOS de las misiones. Cada misión dice, paso a paso, quién está en
-- escena, dónde y qué hace (Actors), y qué cosas se pueden examinar o usar (Props).
--
--   Actor = { Npc = "Nico", Place = "Patio", Offset = V(…), Index = n, Mode = "Idle"|"Wander"|"Follow"|"Sit"|"Wave"|"Cheer",
--             Look = V(…) (hacia dónde mira, en los ejes del lugar; si no, mira al jugador), Prompt = false }
--   Prop  = { Kind = "Mochila", Place = "AulaA", Offset = V(…), Index = n, Prompt = "Examinar", Name = "…", Once = true }
--
-- Todo es de la historia de UN jugador: vive en workspace.StoryScenes.Scene_<UserId> con el atributo
-- Owner; los demás jugadores no lo ven (SceneClient lo oculta) ni pueden tocarlo.
-- Cuando cambia el paso, la escena se actualiza sin parpadeos: quien sigue en el mismo sitio se queda,
-- quien cambia de sitio camina hasta allí (o aparece, si está lejos), y quien sobra se va.
-- Lo que pasa al hablar o usar algo lo decide la historia (SceneService.onInteract).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local LocationService = require(script.Parent.LocationService)
local Npc = require(script.Parent.Parent.World.Npc) -- ropa, pelo y pies en el suelo (lo comparte todo el juego)

local SceneService = {}

-- La historia se engancha aquí: (player, "Actor" | "Prop", questId, id)
SceneService.onInteract = nil :: ((Player, string, string, string) -> ())?

local rgb = Color3.fromRGB
local V = Vector3.new

-- Animaciones R15 de Roblox (las de siempre)
local ANIMS = {
	Idle = "rbxassetid://507766666",
	Walk = "rbxassetid://507777826",
	Wave = "rbxassetid://507770239",
	Cheer = "rbxassetid://507770677",
	Sit = "rbxassetid://2506281703",
	Point = "rbxassetid://507770453",
}

type Actor = {
	Npc: string,
	Spec: { [string]: any },
	Key: string, -- lugar + modo: si cambia, el actor se mueve
	Model: Model,
	Humanoid: Humanoid?,
	Root: BasePart?,
	Home: CFrame, -- dónde debe estar
	Tracks: { [string]: AnimationTrack },
	Playing: string?,
	NextWander: number,
	StuckSince: number?,
}
type Prop = { Id: string, Key: string, Model: Model }
type Scene = { Actors: { [string]: Actor }, Props: { [string]: Prop } }

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
	local result = workspace:Raycast(position + V(0, 3.5, 0), V(0, -14, 0), params)
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
	if isMark and not spec.Look then
		-- Un StorySpot dice hacia dónde mira el personaje
		local look = V(instance.CFrame.LookVector.X, 0, instance.CFrame.LookVector.Z)
		if look.Magnitude > 0.01 then
			return CFrame.lookAt(position, position + look), instance :: BasePart, false
		end
	end
	if spec.Look then
		local look = rotation:VectorToWorldSpace(spec.Look)
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

---------------------------------------------------------------------
-- Actores
---------------------------------------------------------------------

local function sceneFolder(player: Player): Folder
	local name = "Scene_" .. player.UserId
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing :: Folder
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
			track.Looped = name ~= "Wave" and name ~= "Cheer" and name ~= "Point"
			actor.Tracks[name] = track
		end
		for other, t in actor.Tracks do
			if other ~= name then
				t:Stop(0.2)
			end
		end
		track:Play(0.2)
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
	if ok and model and person then
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
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = name
		humanoid.NameDisplayDistance = 35
		humanoid.WalkSpeed = if person and person.Kid then 15 else 13
	end
	local scale = forcedScale or (if person and person.Kid then 0.65 elseif person and person.Teen then 0.85 else 1)
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
	local moving = mode == "Wander" or mode == "Follow"
	anchorActor(actor, not moving)
	if mode == "Sit" then
		play(actor, "Sit")
	elseif mode == "Wave" or mode == "Cheer" or mode == "Point" then
		play(actor, mode)
	else
		play(actor, "Idle")
	end
end

local function makeActor(player: Player, questId: string, spec: { [string]: any }, cf: CFrame): Actor
	local model = buildModel(spec.Npc, player, spec.Scale)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local actor: Actor = {
		Npc = spec.Npc,
		Spec = spec,
		Key = "",
		Model = model,
		Humanoid = humanoid,
		Root = root,
		Home = cf,
		Tracks = {},
		NextWander = 0,
	}
	if root then
		root.Anchored = true
	end
	standAt(actor, cf)
	model.Parent = sceneFolder(player)
	if root and spec.Prompt ~= false then
		prompt(root, "Hablar", model.Name, player, function()
			if SceneService.onInteract then
				SceneService.onInteract(player, "Actor", questId, spec.Npc)
			end
		end)
	end
	applyMode(actor)
	return actor
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
	Gato = function(m)
		part(m, V(1.8, 0.9, 0.9), C(0, 0.6, 0), rgb(240, 150, 60), Enum.Material.Fabric)
		part(m, V(0.8, 0.8, 0.8), C(1.1, 1.1, 0), rgb(240, 150, 60), Enum.Material.Fabric, Enum.PartType.Ball)
		part(m, V(0.2, 0.3, 1.2), C(-1, 1, 0) * CFrame.Angles(0.5, 0, 0), rgb(240, 150, 60), Enum.Material.Fabric)
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
	Marcador = function(m)
		part(m, V(0.8, 0.8, 0.8), C(0, 1.5, 0) * CFrame.Angles(0.6, 0.6, 0), rgb(255, 210, 60), Enum.Material.Neon)
	end,
}

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
		tostring(spec.Mode)
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

function applySet(player: Player, questId: string, actors: { { [string]: any } }, props: { string }, defs: { [string]: any }?)
	scenes[player] = scenes[player] or {}
	local scene = scenes[player][questId] or { Actors = {}, Props = {} }
	scenes[player][questId] = scene

	-- Actores
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
	for npc, spec in wanted do
		local key = specKey(spec)
		local actor = scene.Actors[npc]
		if actor and actor.Key == key then
			actor.Spec = spec
			continue
		end
		local cf = if spec.Mode == "Follow" and playerRoot(player) then (playerRoot(player) :: BasePart).CFrame * CFrame.new(3, -3, 4) else placement(player, spec)
		if not cf then
			if actor then
				actor.Model:Destroy()
				scene.Actors[npc] = nil
			end
			continue
		end
		if actor and actor.Root and (actor.Root.Position - cf.Position).Magnitude < 70 and spec.Mode ~= "Sit" then
			-- Camina hasta su nuevo sitio
			actor.Spec = spec
			actor.Key = key
			actor.Home = cf
			anchorActor(actor, false)
			if actor.Humanoid and spec.Mode ~= "Follow" then
				actor.Humanoid:MoveTo(cf.Position)
				actor.StuckSince = os.clock()
			end
			continue
		end
		if actor then
			actor.Model:Destroy()
		end
		local created = makeActor(player, questId, spec, cf)
		created.Key = key
		scene.Actors[npc] = created
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
			scene.Props[id] = makeProp(player, questId, id, def, cf, mark, isMapObject)
		end
	end
end

-- Quita toda la escena de una misión
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
				if actor.Model.Parent then
					applyMode(actor)
				end
			end)
		end
	end
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
	pcall(function()
		player:RequestStreamAroundAsync(spot.Position, 3)
	end)
	local position = groundAt(spot.Position + V(0, 1, 0), { player.Character :: Instance })
	root.AssemblyLinearVelocity = Vector3.zero
	;(player.Character :: Model):PivotTo(CFrame.new(position + V(0, 3, 0)) * root.CFrame.Rotation)
end

---------------------------------------------------------------------
-- Movimiento: seguir al jugador, pasear, mirar a quien habla
---------------------------------------------------------------------

local function stepActor(player: Player, actor: Actor, index: number)
	local humanoid, root = actor.Humanoid, actor.Root
	if not humanoid or not root or not actor.Model.Parent then
		return
	end
	local mode = actor.Spec.Mode or "Idle"
	local me = playerRoot(player)
	if mode == "Follow" and me then
		-- Detrás del jugador, cada uno a un lado
		local side = if index % 2 == 0 then 1 else -1
		local target = me.Position + me.CFrame.RightVector * side * (2 + index) - me.CFrame.LookVector * (3 + index)
		local distance = (root.Position - me.Position).Magnitude
		if distance > 90 then
			actor.Model:PivotTo(CFrame.new(target) * me.CFrame.Rotation)
		elseif distance > 7 then
			humanoid.WalkSpeed = math.clamp(distance, 14, 24)
			humanoid:MoveTo(target)
		end
	elseif mode == "Wander" then
		if os.clock() > actor.NextWander then
			actor.NextWander = os.clock() + math.random(30, 60) / 10
			local angle = math.random() * math.pi * 2
			local radius = actor.Spec.Radius or 10
			humanoid:MoveTo(actor.Home.Position + V(math.cos(angle) * radius, 0, math.sin(angle) * radius))
		end
	elseif not root.Anchored then
		-- Iba caminando hasta su sitio: al llegar (o si se atasca), se queda allí
		local flat = V(root.Position.X - actor.Home.Position.X, 0, root.Position.Z - actor.Home.Position.Z)
		if flat.Magnitude < 2.5 or (actor.StuckSince and os.clock() - actor.StuckSince > 8) then
			standAt(actor, actor.Home)
			actor.StuckSince = nil
			applyMode(actor)
		end
	elseif mode == "Idle" and me and actor.Spec.Look == nil then
		-- Quieto: se gira hacia el jugador cuando está cerca
		local toMe = V(me.Position.X - root.Position.X, 0, me.Position.Z - root.Position.Z)
		if toMe.Magnitude < 22 and toMe.Magnitude > 1 then
			local want = CFrame.lookAt(root.Position, root.Position + toMe)
			if want.LookVector:Dot(root.CFrame.LookVector) < 0.97 then
				actor.Model:PivotTo(CFrame.new(actor.Model:GetPivot().Position) * want.Rotation)
			end
		end
	end
	-- Andar o estar quieto
	if not root.Anchored then
		local speed = V(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
		play(actor, if speed > 1 then "Walk" else "Idle")
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

return SceneService
