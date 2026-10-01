-- StageActors (servidor): los ACTORES de las escenas de la historia (server/Services/HappeningService).
-- Personajes que aparecen de verdad en el mundo, andan hasta un punto, miran a quien habla, sienten
-- (miedo, enfado, sorpresa, alegría, tristeza, herido) y gesticulan; y CRIATURAS con el mismo motor y
-- otra piel (shared/LifeStory/StoryCreatures: más grandes o más pequeñas, con piezas extra y brillo).
--
-- Son de la historia de UN jugador: van en su carpeta workspace.StoryScenes.Scene_<UserId> (la misma
-- que SceneService), así SceneClient los esconde a los demás y ActorLife los anima en su pantalla
-- (respirar, mirar, la postura de la emoción). Lo que se ve en el cliente lo dicen los atributos:
--   Mood     = "Fear" | "Angry" | … (shared/LifeStory/ActorMoods)    → postura que se queda puesta
--   LookAt   = "Player" | "<NpcId>" | "Key:<clave>" | Vector3        → a quién o adónde mira
--   HappeningKey = clave del actor en la escena (la cámara y los efectos lo encuentran por ella)
-- Los actores de la misión que la escena toma prestados (Use) son los de SceneService: solo se les
-- cambian la emoción, la mirada y los gestos (andar lo sigue decidiendo su misión).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local ActorMoods = require(ReplicatedStorage.Shared.LifeStory.ActorMoods)
local StoryCreatures = require(ReplicatedStorage.Shared.LifeStory.StoryCreatures)

local StageActors = {}

local V = Vector3.new
local rgb = Color3.fromRGB

-- Las mismas animaciones R15 que SceneService
local ANIMS = {
	Idle = "rbxassetid://507766666",
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
	Wave = "rbxassetid://507770239",
	Cheer = "rbxassetid://507770677",
	Laugh = "rbxassetid://507770818",
	Dance = "rbxassetid://507771019",
	Point = "rbxassetid://507770453",
}
StageActors.Gestures = { Wave = true, Cheer = true, Laugh = true, Dance = true, Point = true }

local npcModule: any = nil
local function Npc(): any
	if npcModule == nil then
		npcModule = require(script.Parent.Parent.World.Npc)
	end
	return npcModule
end

-- La carpeta de la historia del jugador (la crea igual que SceneService si aún no existe)
function StageActors.folderOf(player: Player): Folder?
	local scenes = workspace:FindFirstChild("StoryScenes")
	if not scenes then
		scenes = Instance.new("Folder")
		scenes.Name = "StoryScenes"
		scenes.Parent = workspace
	end
	local name = "Scene_" .. player.UserId
	local existing = scenes:FindFirstChild(name)
	if existing then
		return existing :: Folder
	end
	if not player.Parent then
		return nil
	end
	local f = Instance.new("Folder")
	f.Name = name
	f:SetAttribute("Owner", player.UserId)
	f.Parent = scenes
	return f
end

local function color(c: any, default: Color3): Color3
	return StoryCreatures.rgb(c) or default
end

local function material(name: any): Enum.Material?
	if type(name) ~= "string" then
		return nil
	end
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok then m else nil
end

-- Piezas extra de una criatura, soldadas a la parte del cuerpo que digan (se mueven con la animación)
local function addParts(model: Model, creature: StoryCreatures.Creature)
	for _, spec in creature.Parts or {} do
		local attach = model:FindFirstChild(spec.Attach) :: BasePart?
		if attach and attach:IsA("BasePart") then
			local p: BasePart = if spec.Shape == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
			if p:IsA("Part") then
				p.Shape = if spec.Shape == "Ball" then Enum.PartType.Ball elseif spec.Shape == "Cylinder" then Enum.PartType.Cylinder else Enum.PartType.Block
			end
			p.Name = spec.Name or "Extra"
			p.Size = V(spec.Size[1], spec.Size[2], spec.Size[3])
			p.Color = color(spec.Color, rgb(200, 200, 200))
			p.Material = material(spec.Material) or Enum.Material.SmoothPlastic
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			p.CFrame = attach.CFrame * StoryCreatures.offsetOf(spec)
			local weld = Instance.new("Weld")
			weld.Part0 = attach
			weld.Part1 = p
			weld.C0 = StoryCreatures.offsetOf(spec)
			weld.Parent = p
			p.Parent = model
			if spec.Light then
				local l = Instance.new("PointLight")
				l.Color = p.Color
				l.Range = spec.Light
				l.Brightness = 1.5
				l.Shadows = false
				l.Parent = p
			end
		end
	end
end

-- Construye el cuerpo: una persona del reparto (Cast) o una criatura (StoryCreatures)
function StageActors.build(player: Player, spec: { [string]: any }): Model?
	local person = spec.Npc and Cast.People[spec.Npc] or nil
	local creature = spec.Creature and StoryCreatures.get(spec.Creature) or nil
	local skin = if creature then color(creature.Skin, rgb(200, 200, 200)) elseif person then person.Skin else rgb(220, 180, 140)
	local shirt = if creature then color(creature.Shirt, skin) elseif person then person.Shirt else skin
	local pants = if creature then color(creature.Pants, skin) elseif person then person.Pants else skin
	local ok, model = pcall(function()
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = skin
		description.LeftArmColor = skin
		description.RightArmColor = skin
		description.TorsoColor = shirt or skin
		description.LeftLegColor = pants or skin
		description.RightLegColor = pants or skin
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		return nil
	end
	if person and not creature then
		pcall(Npc().dress, model, {
			Skin = person.Skin,
			Shirt = person.Shirt,
			Pants = person.Pants,
			Shoes = person.Shoes or rgb(240, 240, 240),
			Hair = person.Hair,
			LongHair = person.LongHair == true,
			Backpack = person.Backpack,
			LongSleeves = person.LongSleeves == true,
		})
	end
	local name = spec.Name
	if not name and creature then
		name = creature.Name
	elseif not name and spec.Npc then
		local okName, text = pcall(function()
			local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
			return Strings.get(Cast.nameOf(spec.Npc, { FamilyKey = player:GetAttribute("FamilyKey"), AbuKey = player:GetAttribute("AbuKey") }))
		end)
		name = if okName then text else spec.Npc
	end
	model.Name = name or "Actor"
	model:SetAttribute("NpcId", spec.Npc or ("Creature:" .. tostring(spec.Creature)))
	if creature then
		local mat = material(creature.Material)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				if mat and part.Name ~= "HumanoidRootPart" then
					part.Material = mat
				end
				if creature.HideHuman and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 1
				end
			elseif part:IsA("Decal") and creature.HideHuman then
				part.Transparency = 1
			end
		end
		addParts(model, creature)
		if creature.Costume == "GallinaGigante" then
			pcall(function()
				require(script.Parent.Parent.World.Kit.GallinaGigante).costume(model)
			end)
		end
		local glow = StoryCreatures.rgb(creature.Glow)
		if glow then
			local highlight = Instance.new("Highlight")
			highlight.FillColor = glow
			highlight.FillTransparency = 0.82
			highlight.OutlineColor = glow
			highlight.OutlineTransparency = 0.3
			highlight.Parent = model
		end
		model:SetAttribute("Creature", spec.Creature)
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = model.Name
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.BreakJointsOnDeath = false
		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		end)
		humanoid.WalkSpeed = (creature and creature.WalkSpeed) or (if person and person.Kid then 15 else 13)
		model:SetAttribute("BaseSpeed", humanoid.WalkSpeed)
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanTouch = false
		end
	end
	if person and not creature then
		CollectionService:AddTag(model, "NamedActor") -- (el nombre encima lo pinta NameTags)
	end
	local scale = spec.Scale or (creature and creature.Scale) or (if person and person.Kid then 0.65 else 1)
	if scale ~= 1 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end
	pcall(Npc().atomic, model)
	return model
end

-- Aparece en cf (los pies en el suelo) con la clave de la escena
function StageActors.spawn(player: Player, key: string, spec: { [string]: any }, cf: CFrame): Model?
	local model = StageActors.build(player, spec)
	if not model then
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	pcall(function()
		Npc().placeFeet(model, cf)
	end)
	model:SetAttribute("HappeningKey", key)
	model.Parent = StageActors.folderOf(player)
	if root then
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	if spec.Mood then
		StageActors.mood(model, spec.Mood)
	end
	StageActors.play(model, "Idle")
	return model
end

-- Un actor de la misión que la escena toma prestado (SceneService): se le pone la clave
function StageActors.bind(model: Model, key: string)
	model:SetAttribute("HappeningKey", key)
end

-- Suelta un actor prestado: quita lo que le puso la escena (emoción, mirada, clave)
function StageActors.unbind(model: Model)
	model:SetAttribute("HappeningKey", nil)
	model:SetAttribute("Mood", nil)
	model:SetAttribute("LookAt", nil)
end

local tracks: { [Model]: { [string]: AnimationTrack } } = setmetatable({}, { __mode = "k" }) :: any

-- Animación de cuerpo (Idle, Walk, Run, o un gesto que se hace una vez)
function StageActors.play(model: Model, name: string)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or not ANIMS[name] then
		return
	end
	pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local list = tracks[model] or {}
		tracks[model] = list
		local track = list[name]
		if not track then
			local animation = Instance.new("Animation")
			animation.AnimationId = ANIMS[name]
			track = animator:LoadAnimation(animation)
			track.Looped = not StageActors.Gestures[name]
			list[name] = track
		end
		if StageActors.Gestures[name] then
			track.Priority = Enum.AnimationPriority.Action
		else
			for other, t in list do
				if other ~= name and not StageActors.Gestures[other] then
					t:Stop(0.25)
				end
			end
		end
		track:Play(0.2)
	end)
end

-- La emoción que se queda puesta (postura en el cliente, velocidad al andar aquí, gesto al empezar)
function StageActors.mood(model: Model, mood: string?)
	local name = ActorMoods.name(mood)
	model:SetAttribute("Mood", if name and name ~= "Calm" then name else nil)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local base = model:GetAttribute("BaseSpeed")
	if humanoid and type(base) == "number" then
		humanoid.WalkSpeed = ActorMoods.walkSpeed(base, name)
	end
	local m = ActorMoods.get(name)
	if m and m.Gesture then
		StageActors.play(model, m.Gesture)
	end
end

-- A quién o adónde mira (nil = como siempre)
function StageActors.look(model: Model, target: any)
	if typeof(target) == "Vector3" or type(target) == "string" or target == nil then
		model:SetAttribute("LookAt", target)
	end
end

-- Anda (o corre) hasta un punto; onArrive cuando llega (o tras un tope de tiempo)
function StageActors.move(model: Model, to: Vector3, run: boolean?, onArrive: (() -> ())?)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		if onArrive then
			onArrive()
		end
		return
	end
	root.Anchored = false
	local base = model:GetAttribute("BaseSpeed")
	if type(base) == "number" then
		humanoid.WalkSpeed = ActorMoods.walkSpeed(base, model:GetAttribute("Mood"), run)
	end
	StageActors.play(model, if run then "Run" else "Walk")
	model:SetAttribute("Arrived", false)
	local done = false
	local connection: RBXScriptConnection? = nil
	local function finish()
		if done then
			return
		end
		done = true
		if connection then
			connection:Disconnect()
		end
		if model.Parent then
			model:SetAttribute("Arrived", true)
			if type(base) == "number" then
				humanoid.WalkSpeed = ActorMoods.walkSpeed(base, model:GetAttribute("Mood"))
			end
			StageActors.play(model, "Idle")
		end
		if onArrive then
			onArrive()
		end
	end
	connection = humanoid.MoveToFinished:Connect(finish)
	humanoid:MoveTo(to)
	-- Tope: si no llega (algo en medio), a los segundos que tocaría andando + margen
	local seconds = (to - root.Position).Magnitude / math.max(humanoid.WalkSpeed, 1) + 2
	task.delay(math.min(seconds, 20), function()
		if not done and model.Parent then
			pcall(function()
				Npc().placeFeet(model, CFrame.new(to) * root.CFrame.Rotation)
			end)
		end
		finish()
	end)
end

-- Ponerse ya en un sitio (al saltar la escena)
function StageActors.place(model: Model, to: Vector3)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	pcall(function()
		Npc().placeFeet(model, CFrame.new(to) * (if root then root.CFrame.Rotation else CFrame.identity))
	end)
	model:SetAttribute("Arrived", true)
end

function StageActors.despawn(model: Model)
	if model.Parent then
		model:Destroy()
	end
end

return StageActors
