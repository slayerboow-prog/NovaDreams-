-- NameTags (cliente): el nombre encima de los personajes de la historia (actores con la marca
-- "NamedActor", que pone SceneService).
--   * Letra blanca y gruesa con borde oscuro sobre una pastilla semitransparente: se lee sobre
--     cualquier fondo (el nombre de serie de Roblox era gris, fino y casi no se veía).
--   * Se esconde mientras ese personaje habla (el bocadillo ya lleva su nombre y no se pisan),
--     en las escenas de cámara, si el personaje está oculto en tu pantalla y de lejos.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)

local NameTags = {}

local player = Players.LocalPlayer
local MAX_DISTANCE = 45
local TAG = "NamedActor"

type Entry = { Model: Model, Gui: BillboardGui, Label: TextLabel }

local entries: { [Model]: Entry } = {}
local folder: Folder? = nil

local function headOf(model: Model): BasePart?
	local head = model:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

local function nameOf(model: Model): string
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local name = humanoid and humanoid.DisplayName
	return if name and name ~= "" then name else model.Name
end

local function build(model: Model)
	if entries[model] or not folder then
		return
	end
	local head = headOf(model)
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag_" .. model.Name
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(240, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + 1.1, 0)
	gui.MaxDistance = MAX_DISTANCE
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	local pill = Instance.new("Frame")
	pill.Name = "Pill"
	pill.AnchorPoint = Vector2.new(0.5, 0.5)
	pill.Position = UDim2.fromScale(0.5, 0.5)
	pill.Size = UDim2.fromOffset(0, 26)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
	pill.BackgroundTransparency = 0.35
	pill.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = pill
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = pill
	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Size = UDim2.fromScale(0, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 17
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.fromRGB(10, 12, 20)
	label.TextStrokeTransparency = 0.4
	label.Text = nameOf(model)
	label.Parent = pill
	gui.Parent = folder
	entries[model] = { Model = model, Gui = gui, Label = label }
end

local function drop(model: Model)
	local entry = entries[model]
	if entry then
		entry.Gui:Destroy()
		entries[model] = nil
	end
end

local function track(instance: Instance)
	if instance:IsA("Model") then
		if headOf(instance) then
			build(instance)
		else
			-- El personaje llega a trozos: se espera a su cabeza
			task.delay(1, function()
				if instance.Parent and CollectionService:HasTag(instance, TAG) then
					build(instance)
				end
			end)
		end
	end
end

-- ¿Hay una escena de cámara? (la cámara la mueve un guion)
local function inCinematic(): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and camera.CameraType == Enum.CameraType.Scriptable
end

local function update()
	local cinematic = inCinematic()
	for model, entry in entries do
		local head = headOf(model)
		if not model.Parent or not head then
			drop(model)
			continue
		end
		local hidden = head.LocalTransparencyModifier > 0.5 or head.Transparency > 0.9
		entry.Gui.Enabled = not cinematic and not hidden and not SpeechBubbles.isSpeaking(model)
		local name = nameOf(model)
		if entry.Label.Text ~= name then
			entry.Label.Text = name
		end
	end
end

-- Red de seguridad: cualquier personaje que no sea un jugador y enseñe el nombre de serie de Roblox
-- (gris y fino, encima de los bocadillos) pasa a llevar el nuestro. Los jugadores lo conservan.
local watched: { [Humanoid]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function adopt(humanoid: Humanoid)
	if watched[humanoid] then
		return
	end
	local model = humanoid.Parent
	if not model or not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then
		return
	end
	watched[humanoid] = true
	local function fix()
		if humanoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
			local name = humanoid.DisplayName
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			-- (solo los que tenían nombre que enseñar: los peatones sin nombre siguen sin él)
			if name ~= nil and name ~= "" and humanoid.Parent and not entries[humanoid.Parent :: Model] then
				track(humanoid.Parent :: Model)
			end
		end
	end
	humanoid:GetPropertyChangedSignal("DisplayDistanceType"):Connect(fix)
	fix()
end

function NameTags.init()
	local gui = Instance.new("Folder")
	gui.Name = "NameTags"
	gui.Parent = player:WaitForChild("PlayerGui")
	folder = gui
	CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
		if instance:IsA("Model") then
			drop(instance)
		end
	end)
	for _, instance in CollectionService:GetTagged(TAG) do
		track(instance)
	end
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("Humanoid") then
			task.defer(adopt, d)
		end
	end)
	task.spawn(function()
		for _, d in workspace:GetDescendants() do
			if d:IsA("Humanoid") then
				adopt(d)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.15)
			local ok, err = pcall(update)
			if not ok then
				warn("[NameTags] " .. tostring(err))
			end
		end
	end)
end

return NameTags
