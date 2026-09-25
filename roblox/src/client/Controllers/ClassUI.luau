-- ClassUI (cliente): la pantalla de las clases, exámenes y la Educación Física.
--   * Preguntas con 4 respuestas y una barra de tiempo. El servidor dice si acertaste.
--   * Circuito: aros brillantes en la pista a los que hay que llegar corriendo.
--   * Al final, la nota (0-10) y cuántas acertaste.
-- No decide nada: solo muestra lo que manda el servidor (remote "Class") y envía la respuesta elegida.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local StoryAudio = require(script.Parent.StoryAudio)

local create = Theme.create
local C = Theme.Colors

local ClassUI = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent

local GREEN = Color3.fromRGB(70, 190, 110)
local RED = Color3.fromRGB(200, 70, 70)
local RING_COLOR = Color3.fromRGB(255, 196, 60)

local gui: ScreenGui
local panel: Frame
local header: TextLabel
local progress: TextLabel
local timerBar: Frame
local question: TextLabel
local answers: { TextButton } = {}
local feedback: TextLabel

local circuitPanel: Frame
local circuitLabel: TextLabel
local circuitTimer: Frame

local currentIndex = 0
local chosen: number? = nil
local deadline = 0
local duration = 1
local rings: { BasePart } = {}
local circuitDeadline = 0
local circuitDuration = 1
local hideToken = 0

local function fmtGrade(grade: number): string
	local text = if grade == math.floor(grade) then tostring(math.floor(grade)) else ("%.1f"):format(grade)
	return (text:gsub("%.", ","))
end

---------------------------------------------------------------------
-- Interfaz
---------------------------------------------------------------------

local function build()
	gui = create("ScreenGui", {
		Name = "ClassUI",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 850, 0.65, 1.25)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	-- Panel de preguntas: abajo en el centro, sin tapar al personaje
	panel = Theme.panel({
		Name = "Class",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -86), -- encima de la barra rápida
		Size = UDim2.fromOffset(480, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	Theme.padding(12).Parent = panel
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	header = Theme.label({
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 13,
		TextColor3 = C.Accent,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = panel,
	})
	progress = Theme.label({ Size = UDim2.new(1, 0, 0, 14), TextSize = 12, TextColor3 = C.Muted, LayoutOrder = 2, Parent = panel })
	local bar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = panel,
	}, { Theme.corner(3) })
	timerBar = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
		Parent = bar,
	}, { Theme.corner(3) })
	question = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.FontBold,
		TextSize = 18,
		TextWrapped = true,
		LayoutOrder = 4,
		Parent = panel,
	})
	local grid = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		Parent = panel,
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 40),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	for i = 1, 4 do
		local button = Theme.button({
			Text = "",
			TextSize = 15,
			TextWrapped = true,
			LayoutOrder = i,
			Parent = grid,
		})
		create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = button })
		button.Activated:Connect(function()
			if chosen or currentIndex == 0 then
				return
			end
			chosen = i
			button.BackgroundColor3 = C.Accent
			for _, other in answers do
				other.AutoButtonColor = false
			end
			Remote:FireServer("Answer", currentIndex, i)
		end)
		answers[i] = button
	end
	feedback = Theme.label({
		Size = UDim2.new(1, 0, 0, 20),
		Font = Theme.FontBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 6,
		Parent = panel,
	})

	-- Panel pequeño del circuito (arriba en el centro, debajo del reloj)
	circuitPanel = Theme.panel({
		Name = "Circuit",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 110),
		Size = UDim2.fromOffset(260, 46),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = circuitPanel
	circuitLabel = Theme.label({
		Size = UDim2.new(1, 0, 0, 18),
		Font = Theme.FontBold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = circuitPanel,
	})
	local cbar = create("Frame", {
		Position = UDim2.new(0, 0, 1, -6),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		Parent = circuitPanel,
	}, { Theme.corner(3) })
	circuitTimer = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
		Parent = cbar,
	}, { Theme.corner(3) })
end

local function setAnswersVisible(visible: boolean)
	for _, button in answers do
		button.Visible = visible
	end
end

local function clearRings()
	for _, ring in rings do
		ring:Destroy()
	end
	table.clear(rings)
end

-- Aro brillante en el suelo con un haz de luz para verlo de lejos
local function makeRing(position: Vector3, index: number): BasePart
	local ring = Instance.new("Part")
	ring.Name = "ClassRing" .. index
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 12, 12)
	ring.CFrame = CFrame.new(position - Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = RING_COLOR
	ring.Transparency = 0.6
	local light = Instance.new("PointLight")
	light.Color = RING_COLOR
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = ring
	local beam = Instance.new("Part")
	beam.Name = "Beam"
	beam.Size = Vector3.new(1.2, 40, 1.2)
	beam.CFrame = CFrame.new(position + Vector3.new(0, 18, 0))
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = RING_COLOR
	beam.Transparency = 0.75
	beam.Parent = ring
	ring.Parent = workspace
	return ring
end

local function highlightNextRing(done: number)
	for i, ring in rings do
		local active = i == done + 1
		ring.Transparency = if i <= done then 1 elseif active then 0.1 else 0.7
		local beam = ring:FindFirstChild("Beam") :: BasePart?
		if beam then
			beam.Transparency = if active then 0.45 else 1
		end
		local light = ring:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = active
		end
	end
end

---------------------------------------------------------------------
-- Mensajes del servidor
---------------------------------------------------------------------

local handlers: { [string]: (any) -> () } = {}

function handlers.Start(data)
	hideToken += 1
	currentIndex = 0
	chosen = nil
	local parts = { Strings.get(data.SubjectKey), Strings.get(data.ModeKey) }
	local teacher = data.TeacherName or (data.TeacherKey and Strings.get(data.TeacherKey))
	if teacher then
		table.insert(parts, Strings.get("CLASS.WITH", { teacher = teacher }))
	end
	header.Text = "📚 " .. table.concat(parts, " · ")
	progress.Text = ""
	question.Text = Strings.get("CLASS.READY")
	feedback.Text = ""
	timerBar.Size = UDim2.fromScale(1, 1)
	setAnswersVisible(false)
	panel.Visible = true
end

function handlers.Question(data)
	currentIndex = data.Index
	chosen = nil
	progress.Text = Strings.get("CLASS.QUESTION", { n = data.Index, total = data.Total })
	question.Text = data.Q
	feedback.Text = ""
	for i, button in answers do
		local option = data.Options[i]
		button.Visible = option ~= nil
		button.Text = option or ""
		button.BackgroundColor3 = C.PanelLight
		button.AutoButtonColor = true
	end
	duration = math.max(1, data.Seconds or 14)
	deadline = os.clock() + duration
end

function handlers.Feedback(data)
	if data.Right and answers[data.Right] then
		answers[data.Right].BackgroundColor3 = GREEN
	end
	if chosen and not data.Correct then
		answers[chosen].BackgroundColor3 = RED
	end
	if data.Correct then
		feedback.Text = Strings.get("CLASS.RIGHT")
		feedback.TextColor3 = GREEN
	else
		feedback.Text = Strings.get(if chosen then "CLASS.WRONG" else "CLASS.TIMEOUT")
		feedback.TextColor3 = RED
	end
	currentIndex = 0
	deadline = 0
end

function handlers.Circuit(data)
	panel.Visible = false
	clearRings()
	for i, point in data.Points do
		table.insert(rings, makeRing(point, i))
	end
	highlightNextRing(0)
	circuitLabel.Text = Strings.get("CLASS.CIRCUIT", { done = 0, total = #data.Points })
	circuitDuration = math.max(1, data.Seconds or 60)
	circuitDeadline = os.clock() + circuitDuration
	circuitPanel.Visible = true
end

function handlers.CircuitProgress(data)
	highlightNextRing(data.Done)
	circuitLabel.Text = Strings.get("CLASS.CIRCUIT", { done = data.Done, total = data.Total })
	StoryAudio.sting("Momento")
end

function handlers.End(data)
	clearRings()
	circuitPanel.Visible = false
	circuitDeadline = 0
	deadline = 0
	currentIndex = 0
	setAnswersVisible(false)
	progress.Text = ""
	timerBar.Size = UDim2.fromScale(0, 1)
	question.Text = Strings.get("CLASS.GRADE", { grade = fmtGrade(data.Grade) }) .. " · " .. Strings.get(data.GradeKey)
	if data.Total and data.Total > 0 and data.Correct == math.floor(data.Correct) then
		feedback.Text = Strings.get("CLASS.CORRECT_COUNT", { correct = data.Correct, total = data.Total })
	else
		feedback.Text = ""
	end
	feedback.TextColor3 = if data.Grade >= 5 then GREEN else C.Muted
	panel.Visible = true
	if data.Grade >= 9 then
		StoryAudio.sting("Momento")
	end
	hideToken += 1
	local token = hideToken
	task.delay(4.5, function()
		if token == hideToken then
			panel.Visible = false
		end
	end)
end

---------------------------------------------------------------------

function ClassUI.init()
	build()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Class") :: RemoteEvent
	Remote.OnClientEvent:Connect(function(kind: string, data: any)
		local handler = handlers[kind]
		if handler then
			handler(data or {})
		end
	end)
	RunService.RenderStepped:Connect(function()
		if deadline > 0 then
			local left = math.max(0, deadline - os.clock())
			timerBar.Size = UDim2.fromScale(left / duration, 1)
			timerBar.BackgroundColor3 = if left < 4 then RED else C.Gold
		end
		if circuitDeadline > 0 then
			local left = math.max(0, circuitDeadline - os.clock())
			circuitTimer.Size = UDim2.fromScale(left / circuitDuration, 1)
		end
	end)
	player.CharacterRemoving:Connect(function()
		clearRings()
	end)
end

return ClassUI
