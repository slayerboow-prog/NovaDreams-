-- SceneClient (cliente): cada jugador ve SOLO su historia.
--   * Los actores y objetos de las misiones de otros jugadores (workspace.StoryScenes.Scene_<id>)
--     se vuelven invisibles y sin botones para ti.
--   * Si tu escena trae a un personaje que también existe fijo en el mundo (Nico en el patio,
--     tu familia en casa…), el fijo se oculta mientras dure tu escena: nunca ves a dos Nicos.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local SceneClient = {}

local player = Players.LocalPlayer

local function setHidden(root: Instance, hidden: boolean)
	local function apply(instance: Instance)
		if instance:IsA("BasePart") then
			instance.LocalTransparencyModifier = if hidden then 1 else 0
			if hidden then
				instance.CanQuery = false
			end
		elseif instance:IsA("Decal") then
			instance.LocalTransparencyModifier = if hidden then 1 else 0
		elseif instance:IsA("ProximityPrompt") then
			instance.Enabled = not hidden
		elseif instance:IsA("Highlight") then
			instance.Enabled = not hidden
		elseif instance:IsA("Humanoid") then
			instance.DisplayDistanceType = if hidden then Enum.HumanoidDisplayDistanceType.None else Enum.HumanoidDisplayDistanceType.Viewer
		end
	end
	apply(root)
	for _, descendant in root:GetDescendants() do
		apply(descendant)
	end
end

local mine: Instance? = nil
local hiddenStatic: { [Instance]: boolean } = {}

-- Los personajes fijos que ahora mismo están en tu escena se ocultan
local function refreshStatic()
	local inScene: { [string]: boolean } = {}
	if mine then
		for _, model in mine:GetChildren() do
			local id = model:GetAttribute("NpcId")
			if id then
				inScene[id] = true
			end
		end
	end
	for _, npc in CollectionService:GetTagged("StaticNpc") do
		local hide = inScene[npc:GetAttribute("NpcId") or ""] == true
		if hide ~= (hiddenStatic[npc] == true) then
			setHidden(npc, hide)
			hiddenStatic[npc] = if hide then true else nil
		end
	end
end

local function watchScene(folder: Instance)
	if not folder:IsA("Folder") then
		return
	end
	local owner = folder:GetAttribute("Owner")
	if owner == player.UserId then
		mine = folder
		folder.ChildAdded:Connect(function()
			task.defer(refreshStatic)
		end)
		folder.ChildRemoved:Connect(function()
			task.defer(refreshStatic)
		end)
		refreshStatic()
		return
	end
	-- Escena de otro jugador: todo invisible para ti, también lo que se añada después
	setHidden(folder, true)
	folder.DescendantAdded:Connect(function(descendant)
		task.defer(setHidden, descendant, true)
	end)
end

function SceneClient.init()
	local scenes = workspace:WaitForChild("StoryScenes", 60)
	if not scenes then
		return
	end
	for _, folder in scenes:GetChildren() do
		watchScene(folder)
	end
	scenes.ChildAdded:Connect(watchScene)
	CollectionService:GetInstanceAddedSignal("StaticNpc"):Connect(function()
		task.defer(refreshStatic)
	end)
end

return SceneClient
