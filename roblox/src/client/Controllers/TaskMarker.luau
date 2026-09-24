-- TaskMarker: dibuja una línea (Beam) desde tu personaje hasta el objetivo del trabajo
-- y un marcador flotante con la distancia. Solo lo ve el jugador local.
-- Si no estás trabajando, guía hacia el siguiente paso de tu historia de vida (StoryTarget).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TaskMarker = {}

local player = Players.LocalPlayer

local COLOR = Color3.fromRGB(64, 156, 255)

local anchor: Part
local targetAttachment: Attachment
local beam: Beam
local distanceLabel: TextLabel

local function build()
	anchor = Instance.new("Part")
	anchor.Name = "TaskMarker"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)

	targetAttachment = Instance.new("Attachment")
	targetAttachment.Parent = anchor

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(120, 60)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromScale(1, 0.6)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▼"
	arrow.TextColor3 = COLOR
	arrow.TextStrokeTransparency = 0.4
	arrow.TextScaled = true
	arrow.Font = Enum.Font.GothamBlack
	arrow.Parent = billboard

	distanceLabel = Instance.new("TextLabel")
	distanceLabel.Size = UDim2.fromScale(1, 0.4)
	distanceLabel.Position = UDim2.fromScale(0, 0.6)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.TextColor3 = Color3.new(1, 1, 1)
	distanceLabel.TextStrokeTransparency = 0.4
	distanceLabel.TextScaled = true
	distanceLabel.Font = Enum.Font.GothamBold
	distanceLabel.Parent = billboard

	beam = Instance.new("Beam")
	beam.Attachment1 = targetAttachment
	beam.Color = ColorSequence.new(COLOR)
	beam.Transparency = NumberSequence.new(0.35)
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.Segments = 1
	beam.Parent = anchor
end

local function characterAttachment(): Attachment?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local attachment = root:FindFirstChild("TaskBeamAttachment") :: Attachment?
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "TaskBeamAttachment"
		attachment.Position = Vector3.new(0, -2, 0) -- a la altura de los pies
		attachment.Parent = root
	end
	return attachment
end

local function update()
	local target = player:GetAttribute("TaskTarget")
	if typeof(target) ~= "Vector3" then
		target = player:GetAttribute("StoryTarget")
	end
	if typeof(target) ~= "Vector3" then
		anchor.Parent = nil
		return
	end
	anchor.Position = target
	anchor.Parent = workspace
end

function TaskMarker.init()
	build()
	player:GetAttributeChangedSignal("TaskTarget"):Connect(update)
	player:GetAttributeChangedSignal("StoryTarget"):Connect(update)
	update()

	RunService.RenderStepped:Connect(function()
		if not anchor.Parent then
			return
		end
		local attachment = characterAttachment()
		beam.Attachment0 = attachment
		if attachment then
			local distance = (attachment.WorldPosition - anchor.Position).Magnitude
			distanceLabel.Text = ("%d m"):format(math.floor(distance / 3.5))
		end
	end)
end

return TaskMarker
