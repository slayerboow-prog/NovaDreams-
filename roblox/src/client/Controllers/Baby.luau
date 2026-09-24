-- Baby (cliente): lo que se ve durante el tutorial de bebé.
--   * Botón grande "¡Levántate!" (también con la barra espaciadora) mientras el bebé gatea.
--   * Lo que dicen Abu y la familia, en un globo abajo de la pantalla, con su voz.
--   (La vista de la ciudad desde el ventanal es una cinemática: Controllers/Cinematics.luau.)
-- El servidor (BabyService) decide todo; aquí solo se dibuja y se envía "Stand".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
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
-- Globos de diálogo
---------------------------------------------------------------------

local sayQueue: { { SpeakerKey: string?, TextKey: string, Role: string? } } = {}
local saying = false

local function showLine(line: { SpeakerKey: string?, TextKey: string, Role: string? })
	StoryAudio.speak(line.Role, line.TextKey)
	local panel = Theme.panel({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -220),
		Size = UDim2.fromOffset(460, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Theme.padding(12).Parent = panel
	Theme.create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	local labels = {}
	if line.SpeakerKey then
		table.insert(labels, Theme.label({
			Size = UDim2.new(1, 0, 0, 18),
			Text = Strings.get(line.SpeakerKey),
			Font = Theme.FontBold,
			TextSize = 15,
			TextColor3 = C.Gold,
			TextTransparency = 1,
			LayoutOrder = 1,
			Parent = panel,
		}))
	end
	table.insert(labels, Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = Strings.get(line.TextKey),
		TextSize = 17,
		TextWrapped = true,
		TextTransparency = 1,
		LayoutOrder = 2,
		Parent = panel,
	}))

	local fadeIn = TweenInfo.new(0.3)
	TweenService:Create(panel, fadeIn, { BackgroundTransparency = 0.15 }):Play()
	for _, label in labels do
		TweenService:Create(label, fadeIn, { TextTransparency = 0 }):Play()
	end
	task.wait(3.6)
	local fadeOut = TweenInfo.new(0.3)
	TweenService:Create(panel, fadeOut, { BackgroundTransparency = 1 }):Play()
	for _, label in labels do
		TweenService:Create(label, fadeOut, { TextTransparency = 1 }):Play()
	end
	task.wait(0.35)
	panel:Destroy()
end

local function say(line: { SpeakerKey: string?, TextKey: string, Role: string? })
	table.insert(sayQueue, line)
	if saying then
		return
	end
	saying = true
	task.spawn(function()
		while #sayQueue > 0 do
			showLine(table.remove(sayQueue, 1) :: any)
		end
		saying = false
	end)
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
			say({ SpeakerKey = payload.SpeakerKey, TextKey = payload.TextKey, Role = payload.Role })
		end
	end)
end

return Baby
