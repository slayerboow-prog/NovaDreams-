-- SceneClient (cliente): cada jugador ve SOLO su historia.
--   * Los actores y objetos de las misiones de otros jugadores (workspace.StoryScenes.Scene_<id>)
--     se vuelven invisibles y sin botones para ti.
--   * Si tu escena trae a un personaje que también existe fijo en el mundo (Nico en el patio,
--     tu familia en casa…), el fijo se oculta mientras dure tu escena: nunca ves a dos Nicos.
--   * Fundidos: los personajes de tu escena aparecen con un fundido suave, y los del colegio que
--     "saltan" a otro sitio porque no pueden ir andando (atributo Fade, SchoolService) se desvanecen
--     y reaparecen allí.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
			instance:SetAttribute("SceneHidden", if hidden then true else nil)
			instance.Enabled = not hidden and not instance:GetAttribute("GuardOff") -- (PromptGuard)
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

-- Fundido de un personaje (solo en tu pantalla): de `from` a `to` de transparencia en `seconds`
local function fade(model: Instance, from: number, to: number, seconds: number, onDone: (() -> ())?)
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			table.insert(parts, d)
		end
	end
	local start = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local k = math.clamp((os.clock() - start) / seconds, 0, 1)
		local value = from + (to - from) * k
		if hiddenStatic[model] then
			value = 1 -- (oculto por tu escena mientras tanto: sigue oculto)
		end
		for _, p in parts do
			if p.Parent then
				(p :: any).LocalTransparencyModifier = value
			end
		end
		if k >= 1 or not model.Parent then
			connection:Disconnect()
			if onDone then
				onDone()
			end
		end
	end)
end

local watched: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function watchFade(npc: Instance)
	if watched[npc] then
		return -- (vuelve a aparecer en el mundo cada mañana: se escucha una sola vez)
	end
	watched[npc] = true
	npc:GetAttributeChangedSignal("Fade"):Connect(function()
		if hiddenStatic[npc] then
			return
		end
		-- Se desvanece, el servidor lo cambia de sitio, y reaparece
		fade(npc, 0, 1, 0.3, function()
			task.delay(0.1, function()
				if npc.Parent and not hiddenStatic[npc] then
					fade(npc, 1, 0, 0.4)
				end
			end)
		end)
	end)
end

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
		folder.ChildAdded:Connect(function(child)
			task.defer(refreshStatic)
			if child:IsA("Model") and child:GetAttribute("NpcId") then
				-- Tu escena trae a alguien: aparece con un fundido (no de golpe)
				task.defer(fade, child, 1, 0, 0.45)
			end
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
	for _, npc in CollectionService:GetTagged("StaticNpc") do
		watchFade(npc)
	end
	CollectionService:GetInstanceAddedSignal("StaticNpc"):Connect(function(npc)
		watchFade(npc)
		task.defer(refreshStatic)
	end)
end

return SceneClient
