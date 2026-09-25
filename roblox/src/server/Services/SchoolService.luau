-- SchoolService: la gente del colegio. En cada colegio del mapa pone a los compañeros de tu
-- generación (Nico, Sara y Omar) en el patio y a la profe Lucía junto a la pizarra.
-- Hablar con ellos cuenta para la historia (StoryEvents "Talk") y lo recuerdan (memoria de NPC).
-- Si hay niños jugadores, la historia los prefiere para las actividades en grupo; estos NPC
-- garantizan que nadie esté solo en el recreo.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local LifeStoryService = require(script.Parent.LifeStoryService)
local LocationService = require(script.Parent.LocationService)

local SchoolService = {}

local SayRemote: RemoteEvent

-- Quién está en el colegio y qué dice (la primera vez, y luego alguna de las demás)
local PEOPLE = {
	{ Npc = "Nico", NameKey = "NPC.NICO", Skin = Color3.fromRGB(236, 196, 160), Spot = Vector3.new(-6, 0, -3), Kid = true,
		First = "DLG.NICO.COLE", Lines = { "DLG.NICO.BICI", "DLG.NICO.SUENO", "DLG.NICO.RECREO" } },
	{ Npc = "Sara", NameKey = "NPC.SARA", Skin = Color3.fromRGB(242, 214, 180), Spot = Vector3.new(4, 0, 2), Kid = true,
		First = "DLG.SARA.COLE.01", Lines = { "DLG.SARA.CIENCIA.01", "DLG.SARA.EXAMEN", "DLG.SARA.RECREO" } },
	{ Npc = "Omar", NameKey = "NPC.OMAR", Skin = Color3.fromRGB(170, 120, 86), Spot = Vector3.new(0, 0, 6), Kid = true,
		First = "DLG.OMAR.COCINA.01", Lines = { "DLG.OMAR.RECREO", "DLG.OMAR.DIBUJO", "DLG.OMAR.MERIENDA" } },
}
local TEACHER = { Npc = "Lucia", NameKey = "NPC.PROFE_LUCIA", Skin = Color3.fromRGB(226, 186, 150),
	First = "DLG.LUCIA.COLE1.01", Lines = { "DLG.LUCIA.PREGUNTAS", "DLG.LUCIA.ANIMO", "DLG.LUCIA.EXAMEN" } }

local function say(player: Player, speakerKey: string, textKey: string)
	SayRemote:FireClient(player, "Say", { SpeakerKey = speakerKey, TextKey = textKey, Role = if speakerKey == "NPC.PROFE_LUCIA" then "Profe" else "Nino" })
end

local function makeNpc(parent: Instance, cf: CFrame, person: { [string]: any }, scale: number): Model?
	local ok, model = pcall(function()
		local description = Instance.new("HumanoidDescription")
		for _, part in { "HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor" } do
			(description :: any)[part] = person.Skin
		end
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		return nil
	end
	model.Name = Strings.get(person.NameKey)
	model:SetAttribute("NpcId", person.Npc) -- si una escena de la historia lo trae, este se oculta (SceneClient)
	CollectionService:AddTag(model, "StaticNpc")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = Strings.get(person.NameKey)
		humanoid.NameDisplayDistance = 40
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = true
	end
	pcall(function()
		model:ScaleTo(scale)
	end)
	local _, size = model:GetBoundingBox()
	model:PivotTo(cf + Vector3.new(0, size.Y / 2, 0))
	model.Parent = parent

	if root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = Strings.get("BABY.PROMPT.TALK")
		prompt.ObjectText = Strings.get(person.NameKey)
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		prompt.Triggered:Connect(function(player)
			local first = not LifeStoryService.recall(player, person.Npc, "SeConocen")
			if first then
				LifeStoryService.remember(player, person.Npc, "SeConocen")
				LifeStoryService.addAffinity(player, person.Npc, 1)
				say(player, person.NameKey, person.First)
			else
				say(player, person.NameKey, person.Lines[math.random(1, #person.Lines)])
			end
			StoryEvents.emit(player, "Talk", { Npc = person.Npc })
		end)
	end
	return model
end

-- Pone a la gente en un colegio (una sola vez por colegio)
local function populate(recess: BasePart)
	if recess:GetAttribute("SchoolPeople") then
		return
	end
	recess:SetAttribute("SchoolPeople", true)
	local zone = LocationService.zoneAt(recess.Position)
	local scale = if zone == "Campus Valmar" then 0.85 else 0.65 -- en el instituto ya son adolescentes
	local floor = recess.CFrame * CFrame.new(0, -recess.Size.Y / 2, 0)
	local folder = Instance.new("Folder")
	folder.Name = "GenteDelColegio"
	folder.Parent = recess.Parent
	for _, person in PEOPLE do
		local cf = floor * CFrame.new(person.Spot) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
		makeNpc(folder, cf, person, scale)
	end
	-- La profe junto a la pizarra del aula más cercana
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, spot in CollectionService:GetTagged("TeacherSpot") do
		if spot:IsA("BasePart") then
			local d = (spot.Position - recess.Position).Magnitude
			if d < bestDistance then
				best, bestDistance = spot, d
			end
		end
	end
	if best and bestDistance < 250 then
		local teacherFloor = best.CFrame * CFrame.new(0, -best.Size.Y / 2, 0)
		makeNpc(folder, teacherFloor, TEACHER, 1)
	end
end

function SchoolService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	SayRemote = remotes:WaitForChild("Baby") :: RemoteEvent -- el mismo globo de diálogo que la familia
	task.spawn(function()
		for _, recess in CollectionService:GetTagged("RecessArea") do
			if recess:IsA("BasePart") then
				populate(recess)
			end
		end
	end)
	CollectionService:GetInstanceAddedSignal("RecessArea"):Connect(function(recess)
		if recess:IsA("BasePart") then
			populate(recess)
		end
	end)
end

return SchoolService
