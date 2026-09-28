-- Baby (cliente): lo que se ve durante el tutorial de bebé.
--   * Botón grande "¡Levántate!" (también con la barra espaciadora) mientras el bebé gatea.
--   * Lo que dicen Abu y la familia (y los niños y profes del cole, y las frases sueltas de la
--     historia): en un bocadillo encima de quien lo dice (UI/SpeechBubbles), con su voz. Lo que no
--     dice nadie (el narrador) o quien no está a la vista sale como subtítulo abajo, de uno en uno.
--   (La vista de la ciudad desde el ventanal es una cinemática: Controllers/Cinematics.luau.)
-- El servidor (BabyService) decide todo; aquí solo se dibuja y se envía "Stand".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)
local BubbleLayout = require(script.Parent.Parent.UI.BubbleLayout)
local StoryAudio = require(script.Parent.StoryAudio)

local C = Theme.Colors

local Baby = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent
local gui: ScreenGui
local standButton: TextButton

---------------------------------------------------------------------
-- Botón de levantarse
---------------------------------------------------------------------

local function buildStandButton()
	standButton = Theme.button({
		Name = "Stand",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -140),
		Size = UDim2.fromOffset(260, 64),
		Text = "🧸 " .. Strings.get("BABY.STAND_BUTTON"),
		TextSize = 26,
		BackgroundColor3 = C.Accent,
		Visible = false,
		Parent = gui,
	})
	standButton.Activated:Connect(function()
		Remote:FireServer("Stand")
	end)

	-- Latido suave para que se note que hay que pulsarlo
	task.spawn(function()
		while true do
			if standButton.Visible then
				local grow = TweenService:Create(standButton, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Size = UDim2.fromOffset(276, 70) })
				grow:Play()
				grow.Completed:Wait()
				local shrink = TweenService:Create(standButton, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Size = UDim2.fromOffset(260, 64) })
				shrink:Play()
				shrink.Completed:Wait()
			else
				task.wait(0.5)
			end
		end
	end)

	local function update()
		standButton.Visible = player:GetAttribute("BabyCanStand") == true
	end
	player:GetAttributeChangedSignal("BabyCanStand"):Connect(update)
	update()

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Space and standButton.Visible then
			Remote:FireServer("Stand")
		end
	end)
end

---------------------------------------------------------------------
-- Lo que dicen: bocadillo encima de quien habla; si no hay nadie a la vista, subtítulo
---------------------------------------------------------------------

type Line = { SpeakerKey: string?, TextKey: string, Role: string?, Speaker: Instance? }

local caption: Frame? = nil
local captionName: TextLabel? = nil
local captionText: TextLabel? = nil
local captionSerial = 0
local sayingUntil = -math.huge

-- Subtítulo abajo (narrador o alguien que no está a la vista): uno solo, el nuevo sustituye al viejo
local function showCaption(name: string?, text: string, seconds: number)
	if not caption then
		local panel = Theme.panel({
			Name = "Caption",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -220),
			Size = UDim2.fromOffset(460, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			Parent = gui,
		})
		Theme.padding(12).Parent = panel
		Theme.create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
		captionName = Theme.label({
			Size = UDim2.new(1, 0, 0, 18),
			Font = Theme.FontBold,
			TextSize = 15,
			TextColor3 = C.Gold,
			LayoutOrder = 1,
			Parent = panel,
		})
		captionText = Theme.label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = 17,
			TextWrapped = true,
			LayoutOrder = 2,
			Parent = panel,
		})
		caption = panel
	end
	local panel = caption :: Frame
	local nameLabel = captionName :: TextLabel
	local textLabel = captionText :: TextLabel
	captionSerial += 1
	local serial = captionSerial
	nameLabel.Visible = name ~= nil
	nameLabel.Text = name or ""
	textLabel.Text = text
	panel.Visible = true
	local fadeIn = TweenInfo.new(0.25)
	TweenService:Create(panel, fadeIn, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(nameLabel, fadeIn, { TextTransparency = 0 }):Play()
	TweenService:Create(textLabel, fadeIn, { TextTransparency = 0 }):Play()
	task.delay(seconds, function()
		if captionSerial ~= serial then
			return -- ya hay otro subtítulo
		end
		local fadeOut = TweenInfo.new(0.3)
		TweenService:Create(panel, fadeOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(nameLabel, fadeOut, { TextTransparency = 1 }):Play()
		TweenService:Create(textLabel, fadeOut, { TextTransparency = 1 }):Play()
		task.delay(0.35, function()
			if captionSerial == serial then
				panel.Visible = false
			end
		end)
	end)
end

local lastSaid: { [string]: number } = {}

local function say(line: Line)
	-- La misma frase de la misma persona otra vez (un toque de más) no se repite
	local key = tostring(line.SpeakerKey) .. "|" .. tostring(line.TextKey)
	local now = os.clock()
	if lastSaid[key] and now - lastSaid[key] < 8 then
		return
	end
	lastSaid[key] = now
	for k, t in lastSaid do
		if now - t > 30 then
			lastSaid[k] = nil
		end
	end
	local name = if line.SpeakerKey then Strings.get(line.SpeakerKey) else nil
	local text = Strings.get(line.TextKey)
	local seconds = BubbleLayout.duration(text)
	StoryAudio.speak(line.Role, line.TextKey)
	sayingUntil = math.max(sayingUntil, now + seconds)
	if line.Speaker and SpeechBubbles.show(line.Speaker, text, { Name = name, Seconds = seconds }) then
		return
	end
	showCaption(name, text, seconds)
end

-- ¿Te están diciendo algo (o acaban de decírtelo)? (Main apaga los carteles de hablar mientras)
function Baby.isSaying(grace: number?): boolean
	return os.clock() < sayingUntil + (grace or 0)
end

---------------------------------------------------------------------

function Baby.init()
	gui = Theme.create("ScreenGui", {
		Name = "Baby",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Baby") :: RemoteEvent
	buildStandButton()

	Remote.OnClientEvent:Connect(function(kind: string, payload: { [string]: any })
		if kind == "Say" then
			say({ SpeakerKey = payload.SpeakerKey, TextKey = payload.TextKey, Role = payload.Role, Speaker = payload.Speaker })
		end
	end)
end

return Baby
