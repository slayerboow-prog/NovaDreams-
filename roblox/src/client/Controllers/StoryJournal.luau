-- StoryJournal (cliente): «📖 Mi historia», el diario de tu vida. Se abre desde la tarjeta "Tu vida"
-- (botón 📖), desde el Menú o con la tecla J. Tres pestañas:
--   * Capítulos: los que has vivido y el de ahora, con su frase de entrada (y volver a jugar el prólogo).
--   * Personajes: la gente que conoces, quién es y cómo os lleváis.
--   * Recuerdos: los grandes recuerdos y las decisiones importantes.
-- Los datos los manda el servidor (LifeStoryService, "Journal" → StoryContext.journal).
-- Pensado para el móvil (844x390): panel casi a pantalla completa y lista con scroll.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)

local create = Theme.create
local C = Theme.Colors

local StoryJournal = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent? = nil
local gui: ScreenGui? = nil
local panel: Frame? = nil
local list: ScrollingFrame? = nil
local tabs: { [string]: TextButton } = {}
local current = "Chapters"
local lastData: { [string]: any }? = nil

-- Texto de una clave o texto ya escrito (con la familia de este jugador)
local function text(key: any, args: { [string]: any }?): string
	if type(key) ~= "string" then
		return ""
	end
	local resolved = {}
	for k, v in args or {} do
		resolved[k] = v
	end
	resolved.nombre = resolved.nombre or player.DisplayName
	resolved.familia = resolved.familia or Strings.get(player:GetAttribute("FamilyKey") or "NPC.MAMA")
	resolved.abu = resolved.abu or Strings.get(player:GetAttribute("AbuKey") or "NPC.ABU_ROSA")
	return Strings.get(key, resolved)
end

local function clearList()
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local order = 0
local function row(content: string, props: { [string]: any }?): TextLabel
	order += 1
	local label = Theme.label({
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = content,
		TextSize = 15,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = order,
		ZIndex = 42,
		Parent = list,
	})
	for key, value in props or {} do
		(label :: any)[key] = value
	end
	return label
end

-- Una ficha: título en negrita y una o dos líneas debajo
local function entry(title: string, lines: { string }, accent: Color3?)
	order += 1
	local box = create("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = C.PanelLight,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 42,
		Parent = list,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })
	Theme.padding(8).Parent = box
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })
	Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = title,
		Font = Theme.FontBold,
		TextSize = 16,
		TextWrapped = true,
		TextColor3 = accent or C.Text,
		LayoutOrder = 1,
		ZIndex = 43,
		Parent = box,
	})
	for i, line in lines do
		if line ~= "" then
			Theme.label({
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = line,
				TextSize = 14,
				TextWrapped = true,
				TextColor3 = if i == 1 then C.Muted else C.Text,
				LayoutOrder = 1 + i,
				ZIndex = 43,
				Parent = box,
			})
		end
	end
	return box
end

local function render()
	if not list then
		return
	end
	clearList()
	order = 0
	for name, button in tabs do
		button.BackgroundColor3 = if name == current then C.Accent else C.PanelLight
	end
	local data = lastData
	if not data then
		row(Strings.get("JOURNAL.LOADING"), { TextColor3 = C.Muted })
		return
	end
	if current == "Chapters" then
		row(Strings.get("JOURNAL.HELP"), { TextSize = 13, TextColor3 = C.Muted })
		local chapters = data.Chapters or {}
		if #chapters == 0 then
			row(Strings.get("JOURNAL.EMPTY.CHAPTERS"), { TextColor3 = C.Muted })
		end
		for _, chapter in chapters do
			local status = if chapter.Current then Strings.get("JOURNAL.NOW") else Strings.get("JOURNAL.DONE")
			entry(text(chapter.TitleKey), { status, text(chapter.IntroKey) }, if chapter.Current then C.Gold else C.Text)
		end
		-- Volver a jugar el prólogo (tutorial de controles y el comienzo de la saga)
		order += 1
		local replay = Theme.button({
			Size = UDim2.new(1, -8, 0, 36),
			Text = Strings.get("JOURNAL.REPLAY"),
			TextSize = 15,
			LayoutOrder = order,
			ZIndex = 43,
			Parent = list,
		})
		replay.Activated:Connect(function()
			if Remote then
				Remote:FireServer("Prologue", "Replay")
			end
			StoryJournal.close()
		end)
	elseif current == "People" then
		local people = data.People or {}
		if #people == 0 then
			row(Strings.get("JOURNAL.EMPTY.PEOPLE"), { TextColor3 = C.Muted })
		end
		for _, person in people do
			entry(text(person.Name), { person.RelText or "", person.Who or "" })
		end
	else
		local memories = data.Memories or {}
		if #memories == 0 and #(data.Choices or {}) == 0 then
			row(Strings.get("JOURNAL.EMPTY.MEMORIES"), { TextColor3 = C.Muted })
		end
		for _, memory in memories do
			row(("%s  %s"):format(memory.Icon or "💭", text(memory.Text)))
		end
		if #(data.Choices or {}) > 0 then
			row("<b>" .. Strings.get("JOURNAL.CHOICES") .. "</b>", { TextColor3 = C.Gold })
			for _, choice in data.Choices do
				row(("%s  %s"):format(choice.Icon or "🔀", text(choice.Key)), { TextColor3 = C.Muted })
			end
		end
	end
end

local function build()
	gui = create("ScreenGui", {
		Name = "StoryJournal",
		ResetOnSpawn = false,
		DisplayOrder = 12,
		IgnoreGuiInset = true,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Fondo oscuro que se toca para cerrar
	local shade = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 40,
		Parent = gui,
	})
	shade.Activated:Connect(function()
		StoryJournal.close()
	end)
	panel = Theme.panel({
		Name = "Journal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.94, 0, 0.9, 0),
		ZIndex = 41,
		Active = true,
		Parent = gui,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(660, 460), Parent = panel })
	Theme.padding(10).Parent = panel
	local p = panel :: Frame
	-- Cabecera: título y cerrar
	Theme.label({ Size = UDim2.new(1, -96, 0, 26), Text = Strings.get("JOURNAL.TITLE"), Font = Theme.FontBold, TextSize = 20, TextColor3 = C.Gold, ZIndex = 42, Parent = p })
	local close = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(88, 28), Text = Strings.get("JOURNAL.CLOSE"), TextSize = 14, ZIndex = 42, Parent = p })
	close.Activated:Connect(function()
		StoryJournal.close()
	end)
	-- Pestañas
	local bar = create("Frame", { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, ZIndex = 42, Parent = p })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	for i, spec in { { "Chapters", "JOURNAL.TAB.CHAPTERS" }, { "People", "JOURNAL.TAB.PEOPLE" }, { "Memories", "JOURNAL.TAB.MEMORIES" } } do
		local button = Theme.button({ Size = UDim2.new(1 / 3, -4, 1, 0), Text = Strings.get(spec[2]), TextSize = 15, LayoutOrder = i, ZIndex = 43, Parent = bar })
		button.Name = "Tab" .. spec[1]
		tabs[spec[1]] = button
		button.Activated:Connect(function()
			current = spec[1]
			render()
		end)
	end
	-- Lista con scroll
	list = create("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(0, 70),
		Size = UDim2.new(1, 0, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 42,
		Parent = p,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
end

function StoryJournal.isOpen(): boolean
	return gui ~= nil and gui.Enabled
end

function StoryJournal.open(tab: string?)
	if not gui then
		return
	end
	current = tab or current
	gui.Enabled = true
	render()
	if Remote then
		Remote:FireServer("Journal") -- el servidor manda los datos al momento
	end
end

function StoryJournal.close()
	if gui then
		gui.Enabled = false
	end
end

function StoryJournal.toggle()
	if StoryJournal.isOpen() then
		StoryJournal.close()
	else
		StoryJournal.open()
	end
end

-- Llegan los datos del servidor
function StoryJournal.show(data: { [string]: any })
	lastData = data
	if StoryJournal.isOpen() then
		render()
	end
end

function StoryJournal.init(remote: RemoteEvent)
	Remote = remote
	build()
	-- Una conversación o una escena manda: el diario se cierra
	player:GetAttributeChangedSignal("InDialogue"):Connect(function()
		if player:GetAttribute("InDialogue") then
			StoryJournal.close()
		end
	end)
	player:GetAttributeChangedSignal("InCinematic"):Connect(function()
		if player:GetAttribute("InCinematic") then
			StoryJournal.close()
		end
	end)
	-- Teclado: J abre y cierra el diario
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.J then
			StoryJournal.toggle()
		end
	end)
end

return StoryJournal
