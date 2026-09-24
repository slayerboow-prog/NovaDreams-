-- LifeStory (cliente): dibuja la historia de vida que decide el servidor.
--   * Tarjeta "Tu vida" (arriba a la derecha): qué estás viviendo ahora y el siguiente paso.
--   * Momentos: "Has cobrado tu primer sueldo" (no "Misión completada +100 XP").
--   * Pantallas de capítulo y de transición ("Han pasado varios años…").
--   * Decisiones y ofrecimientos de otras personas ("¿Me ayudas a buscar mi mochila?").
-- No decide nada: solo muestra y envía lo que el jugador elige (el servidor lo valida).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)

local create = Theme.create
local C = Theme.Colors

local LifeStory = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent

local gui: ScreenGui
local card: Frame
local cardHeader: TextLabel
local cardTitle: TextLabel
local cardText: TextLabel
local cardList: Frame
local switchButton: TextButton
local lastState: { [string]: any }? = nil

-- Resuelve el texto de una clave. Los lugares llegan como clave (placeKey) y se traducen aquí.
local function text(key: string?, args: { [string]: any }?): string
	if not key then
		return ""
	end
	local resolved = {}
	for name, value in args or {} do
		resolved[name] = value
	end
	if resolved.placeKey then
		resolved.place = Strings.get(resolved.placeKey)
	end
	return Strings.get(key, resolved)
end

---------------------------------------------------------------------
-- Tarjeta "Tu vida"
---------------------------------------------------------------------

local function buildCard()
	card = Theme.panel({
		Name = "LifeStoryCard",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(280, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -16, 0, 12),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(12).Parent = card
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	cardHeader = Theme.label({
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 12,
		TextColor3 = C.Accent,
		LayoutOrder = 1,
		Parent = card,
	})
	cardTitle = Theme.label({
		Size = UDim2.new(1, 0, 0, 20),
		Font = Theme.FontBold,
		TextSize = 17,
		LayoutOrder = 2,
		Parent = card,
	})
	cardText = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 14,
		TextColor3 = C.Muted,
		TextWrapped = true,
		LayoutOrder = 3,
		Parent = card,
	})
	cardList = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = card,
	})
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = cardList })
	switchButton = Theme.button({
		Size = UDim2.fromOffset(150, 22),
		TextSize = 12,
		LayoutOrder = 5,
		Visible = false,
		Parent = card,
	})
	switchButton.Activated:Connect(function()
		local state = lastState
		if state and state.Others and state.Others[1] then
			Remote:FireServer("Track", state.Others[1].QuestId)
		end
	end)

	-- Si el jugador está trabajando, la tarjeta baja para no tapar el panel del trabajo
	local function place()
		local working = player:GetAttribute("Job") ~= nil
		card.Position = UDim2.new(1, -16, 0, if working then 120 else 12)
	end
	player:GetAttributeChangedSignal("Job"):Connect(place)
	place()
end

local function renderCard(state: { [string]: any })
	lastState = state
	for _, child in cardList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local header = Strings.get("STORY.CARD.HEADER")
	if state.ChapterTitleKey then
		header ..= "  ·  " .. Strings.get(state.ChapterTitleKey)
	end
	cardHeader.Text = header

	local tracked = state.Tracked
	if tracked then
		cardTitle.Text = (if tracked.Kind == "Side" then "✦ " else "") .. Strings.get(tracked.TitleKey)
		cardText.Text = text(tracked.TextKey, tracked.Args)
		for i, child in tracked.Children or {} do
			Theme.label({
				Size = UDim2.new(1, 0, 0, 18),
				TextSize = 13,
				TextColor3 = if child.Done then C.Money else C.Text,
				Text = (if child.Done then "✓ " else "• ") .. text(child.TextKey, child.Args),
				LayoutOrder = i,
				Parent = cardList,
			})
		end
	elseif state.Waiting then
		local waiting = state.Waiting
		cardTitle.Text = Strings.get(waiting.TitleKey)
		cardText.Text = if waiting.Reason == "Hours"
			then Strings.get("STORY.WAIT.HOURS", { from = waiting.From, to = waiting.To })
			else Strings.get("STORY.WAIT.DAYS")
	end
	local others = state.Others or {}
	switchButton.Visible = tracked ~= nil and #others > 0
	switchButton.Text = Strings.get("STORY.CARD.SWITCH", { title = if others[1] then Strings.get(others[1].TitleKey) else "" })
	card.Visible = tracked ~= nil or state.Waiting ~= nil
end

---------------------------------------------------------------------
-- Momentos, capítulos y transiciones
---------------------------------------------------------------------

local momentQueue: { () -> () } = {}
local showingMoment = false

local function queue(show: () -> ())
	table.insert(momentQueue, show)
	if showingMoment then
		return
	end
	showingMoment = true
	task.spawn(function()
		while #momentQueue > 0 do
			table.remove(momentQueue, 1)()
		end
		showingMoment = false
	end)
end

-- Frase grande en el centro de la pantalla que aparece y se desvanece
local function showMoment(message: string, color: Color3?)
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.8, 0, 0, 60),
		Text = message,
		Font = Theme.FontBold,
		TextSize = 30,
		TextScaled = false,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = color or C.Gold,
		TextStrokeTransparency = 0.5,
		TextTransparency = 1,
		ZIndex = 20,
		Parent = gui,
	})
	TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	task.wait(3.2)
	local out = TweenService:Create(label, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 })
	out:Play()
	out.Completed:Wait()
	label:Destroy()
end

-- Pantalla completa (capítulo nuevo, "Han pasado varios años…")
local function showScreen(small: string?, big: string, body: string?, seconds: number)
	local overlay = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 10, 16),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = gui,
	})
	local labels = {}
	local function line(content: string?, y: number, size: number, color: Color3, bold: boolean)
		if not content or content == "" then
			return
		end
		table.insert(labels, Theme.label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, y),
			Size = UDim2.new(0.8, 0, 0, size + 16),
			Text = content,
			Font = if bold then Theme.FontBold else Theme.Font,
			TextSize = size,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = color,
			TextTransparency = 1,
			ZIndex = 31,
			Parent = overlay,
		}))
	end
	line(small, 0.4, 16, C.Accent, false)
	line(big, 0.47, 34, C.Text, true)
	line(body, 0.56, 18, C.Muted, false)

	local fadeIn = TweenInfo.new(0.8)
	TweenService:Create(overlay, fadeIn, { BackgroundTransparency = 0.05 }):Play()
	for _, label in labels do
		TweenService:Create(label, fadeIn, { TextTransparency = 0 }):Play()
	end
	task.wait(seconds)
	local fadeOut = TweenInfo.new(0.8)
	TweenService:Create(overlay, fadeOut, { BackgroundTransparency = 1 }):Play()
	for _, label in labels do
		TweenService:Create(label, fadeOut, { TextTransparency = 1 }):Play()
	end
	task.wait(0.85)
	overlay:Destroy()
end

---------------------------------------------------------------------
-- Decisiones y ofrecimientos
---------------------------------------------------------------------

local openDialog: Frame? = nil

local function dialog(title: string?, message: string, options: { { Text: string, OnPick: () -> () } })
	if openDialog then
		openDialog:Destroy()
	end
	local panel = Theme.panel({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 25,
		Parent = gui,
	})
	openDialog = panel
	Theme.padding(14).Parent = panel
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	if title then
		Theme.label({ Size = UDim2.new(1, 0, 0, 20), Text = title, Font = Theme.FontBold, TextSize = 17, TextColor3 = C.Accent, LayoutOrder = 1, ZIndex = 26, Parent = panel })
	end
	Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = message,
		TextSize = 15,
		TextWrapped = true,
		LayoutOrder = 2,
		ZIndex = 26,
		Parent = panel,
	})
	for i, option in options do
		local button = Theme.button({
			Size = UDim2.new(1, 0, 0, 34),
			Text = option.Text,
			TextSize = 15,
			LayoutOrder = 2 + i,
			ZIndex = 26,
			Parent = panel,
		})
		button.Activated:Connect(function()
			if openDialog == panel then
				openDialog = nil
			end
			panel:Destroy()
			option.OnPick()
		end)
	end
	return panel
end

---------------------------------------------------------------------

local handlers: { [string]: (payload: { [string]: any }) -> () } = {
	State = function(payload)
		renderCard(payload)
	end,
	Moment = function(payload)
		queue(function()
			showMoment(text(payload.TextKey, payload.Args))
		end)
	end,
	Chapter = function(payload)
		queue(function()
			local small = if payload.Phase == "Intro" then Strings.get("STORY.CHAPTER.LABEL") else nil
			showScreen(small, Strings.get(payload.TitleKey), Strings.get(payload.TextKey), 3.5)
		end)
	end,
	Transition = function(payload)
		queue(function()
			showScreen(nil, Strings.get(payload.TextKey), nil, payload.Seconds or 4)
		end)
	end,
	Discover = function(payload)
		queue(function()
			showMoment(Strings.get("STORY.DISCOVER.ZONE", { zone = payload.Zone }), C.Accent)
		end)
	end,
	Choice = function(payload)
		local options = {}
		for _, option in payload.Options do
			table.insert(options, {
				Text = Strings.get(option.TextKey),
				OnPick = function()
					Remote:FireServer("Choose", payload.QuestId, option.Id)
				end,
			})
		end
		dialog(nil, Strings.get(payload.PromptKey), options)
	end,
	Offer = function(payload)
		local panel = dialog(Strings.get(payload.TitleKey), Strings.get(payload.TextKey), {
			{ Text = Strings.get("STORY.OFFER.ACCEPT"), OnPick = function()
				Remote:FireServer("Offer", payload.QuestId, true)
			end },
			{ Text = Strings.get("STORY.OFFER.DECLINE"), OnPick = function()
				Remote:FireServer("Offer", payload.QuestId, false)
			end },
		})
		-- Si no contesta, el ofrecimiento se va solo (el servidor lo olvida a los 30 s)
		task.delay(28, function()
			if panel.Parent then
				panel:Destroy()
				if openDialog == panel then
					openDialog = nil
				end
			end
		end)
	end,
}

function LifeStory.init()
	gui = create("ScreenGui", {
		Name = "LifeStory",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	buildCard()

	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LifeStory") :: RemoteEvent
	local synced = false
	Remote.OnClientEvent:Connect(function(kind: string, payload: { [string]: any })
		if kind == "State" then
			synced = true
		end
		local handler = handlers[kind]
		if handler then
			handler(payload)
		end
	end)
	-- Avisar al servidor de que ya escuchamos (y pedir el estado). Se repite hasta que responda,
	-- porque los datos del jugador pueden tardar unos segundos en cargar.
	for _ = 1, 20 do
		if synced then
			break
		end
		Remote:FireServer("Sync")
		task.wait(3)
	end
end

return LifeStory
