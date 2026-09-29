-- LifeStory (cliente): dibuja la historia de vida que decide el servidor.
--   * Tarjeta "Tu vida" (arriba a la derecha): qué estás viviendo ahora y el siguiente paso, con el
--     tipo de misión (⭐ tu vida, 🌀 misión loca, ❗ saga) y el botón 📖 «Mi historia» (StoryJournal).
--   * Momentos: "Has cobrado tu primer sueldo" (no "Misión completada +100 XP").
--   * Pantallas de capítulo y de transición ("Han pasado varios años…").
--   * Decisiones y ofrecimientos de otras personas ("¿Me ayudas a buscar mi mochila?"), con quién te
--     lo pide y por qué; y al empezar una misión, su tarjeta de contexto.
--   * «Anteriormente en tu vida…» al volver al juego (nunca encima de una conversación o una escena).
-- No decide nada: solo muestra y envía lo que el jugador elige (el servidor lo valida).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local StoryAudio = require(script.Parent.StoryAudio)
local Cinematics = require(script.Parent.Cinematics)
local StoryJournal = require(script.Parent.StoryJournal)

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
local tab: TextButton
local tabArrow: TextLabel
local newDot: Frame
local expanded = true
local hasContent = false
local lastSeen: string? = nil -- último objetivo que el jugador ha visto (para el aviso de "nuevo")
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
	-- Los textos de las misiones hablan de ti y de tu familia: "Dile a {familia} que ya estás listo"
	resolved.nombre = resolved.nombre or player.DisplayName
	resolved.familia = resolved.familia or Strings.get(player:GetAttribute("FamilyKey") or "NPC.MAMA")
	resolved.abu = resolved.abu or Strings.get(player:GetAttribute("AbuKey") or "NPC.ABU_ROSA")
	if resolved.subjectKey then
		resolved.subject = Strings.get(resolved.subjectKey)
	end
	if resolved.degreeKey then
		resolved.degree = Strings.get(resolved.degreeKey)
	end
	return Strings.get(key, resolved)
end

---------------------------------------------------------------------
-- Tarjeta "Tu vida": pestaña vertical en el borde derecho que despliega un panel pequeño
---------------------------------------------------------------------

local function refreshVisibility()
	card.Visible = expanded and hasContent
	tab.Visible = hasContent
	tabArrow.Text = if expanded then "▶" else "◀"
	if expanded then
		newDot.Visible = false
	end
end

local function buildCard()
	-- Contenedor pegado al borde derecho, a media altura: [panel][pestaña]
	local dock = create("Frame", {
		Name = "LifeStoryDock",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = dock,
	})

	card = Theme.panel({
		Name = "LifeStoryCard",
		Size = UDim2.fromOffset(200, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Visible = false,
		Parent = dock,
	})
	Theme.padding(8).Parent = card
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	cardHeader = Theme.label({
		Size = UDim2.new(1, 0, 0, 13),
		TextSize = 11,
		TextColor3 = C.Accent,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = card,
	})
	cardTitle = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.FontBold,
		TextSize = 14,
		TextWrapped = true,
		LayoutOrder = 2,
		Parent = card,
	})
	cardText = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 12,
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
	create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = cardList })
	switchButton = Theme.button({
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
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
	-- 📖 «Mi historia»: capítulos, personajes y recuerdos (sin botón nuevo en el HUD)
	local journalButton = Theme.button({
		Name = "JournalButton",
		Size = UDim2.new(1, 0, 0, 24),
		Text = Strings.get("JOURNAL.OPEN"),
		TextSize = 12,
		LayoutOrder = 6,
		Parent = card,
	})
	journalButton.Activated:Connect(function()
		StoryJournal.open()
	end)

	-- Pestaña vertical: pulsar para ocultar o desplegar
	tab = Theme.button({
		Name = "LifeStoryTab",
		Size = UDim2.fromOffset(28, 104),
		Text = "",
		LayoutOrder = 2,
		Visible = false,
		Parent = dock,
	})
	tabArrow = Theme.label({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 4),
		Text = "▶",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.Accent,
		Parent = tab,
	})
	Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 8),
		Size = UDim2.fromOffset(76, 20),
		Rotation = -90,
		Text = Strings.get("STORY.CARD.HEADER"),
		Font = Theme.FontBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = tab,
	})
	newDot = create("Frame", {
		Size = UDim2.fromOffset(9, 9),
		Position = UDim2.fromOffset(-3, -3),
		BackgroundColor3 = C.Gold,
		BorderSizePixel = 0,
		Visible = false,
		Parent = tab,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = newDot })
	tab.Activated:Connect(function()
		expanded = not expanded
		refreshVisibility()
	end)

	-- En pantallas pequeñas (móvil, ventana de Studio) empieza plegada
	local camera = workspace.CurrentCamera
	expanded = camera.ViewportSize.Y >= 700
	refreshVisibility()
end

local function renderCard(state: { [string]: any })
	lastState = state
	for _, child in cardList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	cardHeader.Text = if state.ChapterTitleKey then Strings.get(state.ChapterTitleKey) else Strings.get("STORY.CARD.HEADER")

	local tracked = state.Tracked
	if tracked then
		-- El icono dice qué tipo de misión es (⭐ tu vida, 🌀 misión loca, ❗ saga de la Grieta…)
		local icon = tracked.Icon or (if tracked.Kind == "Side" then "🔶" else nil)
		cardTitle.Text = (if icon then icon .. " " else "") .. Strings.get(tracked.TitleKey)
		cardText.Text = text(tracked.TextKey, tracked.Args)
		if tracked.Need and tracked.Children then
			-- "Haz 3 de estas 5 cosas": cuántas llevas
			local done = 0
			for _, child in tracked.Children do
				done += if child.Done then 1 else 0
			end
			cardText.Text ..= ("  (%d de %d)"):format(math.min(done, tracked.Need), tracked.Need)
		end
		for i, child in tracked.Children or {} do
			Theme.label({
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextSize = 12,
				TextWrapped = true,
				TextColor3 = if child.Done then C.Money else C.Text,
				Text = (if child.Done then "✔ " else "• ") .. text(child.TextKey, child.Args),
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
	local others = {}
	for _, other in state.Others or {} do
		if not other.Later then
			table.insert(others, other) -- (las que esperan al cole o a salir de él no se pueden seguir ahora)
		end
	end
	switchButton.Visible = tracked ~= nil and #others > 0
	switchButton.Text = Strings.get("STORY.CARD.SWITCH", { title = if others[1] then Strings.get(others[1].TitleKey) else "" })
	if not tracked and not state.Waiting then
		-- Sin nada que hacer ahora: la tarjeta sigue (con «Mi historia» a mano)
		cardTitle.Text = ""
		cardText.Text = ""
	end
	hasContent = true

	-- Si está plegada y hay un objetivo nuevo, un puntito dorado en la pestaña lo avisa
	local current = cardTitle.Text .. "|" .. cardText.Text
	if current ~= lastSeen then
		lastSeen = current
		if not expanded then
			newDot.Visible = true
		end
	end
	refreshVisibility()
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
			-- Si uno falla, la cola sigue (si no, se quedaba parada y los diálogos esperando)
			local ok, err = pcall(table.remove(momentQueue, 1))
			if not ok then
				warn("[LifeStory] " .. tostring(err))
			end
		end
		showingMoment = false
	end)
end

-- ¿Se está enseñando un momento, un capítulo o una escena? (DialogueUI espera a que acaben)
function LifeStory.isShowing(): boolean
	return showingMoment
end

-- Frase grande en el centro de la pantalla que aparece y se desvanece
local function showMoment(message: string, color: Color3?)
	local label = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.8, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, -- las frases largas ocupan varias líneas sin cortarse
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
	local function line(content: string?, y: number, size: number, color: Color3, bold: boolean, top: boolean?)
		if not content or content == "" then
			return
		end
		table.insert(labels, Theme.label({
			AnchorPoint = Vector2.new(0.5, if top then 0 else 0.5), -- el texto largo crece hacia abajo
			Position = UDim2.fromScale(0.5, y),
			Size = UDim2.new(0.8, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, -- un texto largo no se corta ni se monta sobre otro
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
	line(body, 0.53, 18, C.Muted, false, true)

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
-- Tarjetas de contexto: el comienzo de una misión y «Anteriormente en tu vida…»
---------------------------------------------------------------------

-- ¿Hay una conversación o una escena en pantalla? Espera a que acaben (como mucho maxSeconds).
-- Devuelve false si siguen: entonces la tarjeta no sale (nunca encima de una conversación o escena).
local function waitFree(maxSeconds: number): boolean
	local since = os.clock()
	while player:GetAttribute("InDialogue") or Cinematics.isOnScreen() do
		if os.clock() - since > maxSeconds then
			return false
		end
		task.wait(0.2)
	end
	return true
end

-- Tarjeta en el centro que se cierra al tocarla (o sola a los `seconds`, o si empieza una
-- conversación). fill(add) añade las líneas: add(texto, tamaño, color, negrita)
local function tapCard(name: string, seconds: number, fill: (add: (string?, number?, Color3?, boolean?) -> ()) -> ())
	local closed = false
	local shade = create("TextButton", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 28,
		Parent = gui,
	})
	local panel = Theme.panel({
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 29,
		Parent = shade,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(500, 1000), Parent = panel })
	Theme.padding(12).Parent = panel
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	local order = 0
	local function add(content: string?, size: number?, color: Color3?, bold: boolean?)
		if not content or content == "" then
			return
		end
		order += 1
		Theme.label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = content,
			TextSize = size or 15,
			TextWrapped = true,
			Font = if bold then Theme.FontBold else Theme.Font,
			TextColor3 = color or C.Text,
			LayoutOrder = order,
			ZIndex = 30,
			Parent = panel,
		})
	end
	fill(add)
	shade.Activated:Connect(function()
		closed = true
	end)
	local waited = 0
	while not closed and waited < seconds and not player:GetAttribute("InDialogue") and shade.Parent do
		waited += task.wait(0.1)
	end
	shade:Destroy()
end

-- Al empezar una misión: qué tipo es, quién te lo pide y por qué
local function showIntro(payload: { [string]: any })
	if not waitFree(20) then
		return
	end
	tapCard("QuestIntro", 7, function(add)
		add(("%s %s"):format(payload.Icon or "", payload.Label or ""), 13, C.Gold, true)
		add(text(payload.TitleKey), 19, C.Text, true)
		if payload.Asker then
			add(Strings.get("STORY.CONTEXT.ASKS", { who = text(payload.Asker) }), 14, C.Accent)
		end
		add(text(payload.Description), 15, C.Text)
		add(Strings.get("STORY.CONTEXT.TAP"), 12, C.Muted)
	end)
end

-- Al volver: capítulo, etapa, lo último que pasó y lo que estabas haciendo
local function showRecap(payload: { [string]: any })
	if not waitFree(12) then
		return -- había una conversación o una escena: mejor no taparla
	end
	tapCard("Recap", 10, function(add)
		add(Strings.get("RECAP.TITLE"), 20, C.Gold, true)
		if payload.ChapterTitleKey then
			add(Strings.get("RECAP.CHAPTER", { chapter = text(payload.ChapterTitleKey) }), 15, C.Text, true)
		end
		if payload.StageName then
			add(Strings.get("RECAP.STAGE", { stage = payload.StageName }), 14, C.Muted)
		end
		local recent = payload.Recent or {}
		if #recent > 0 then
			add(Strings.get("RECAP.RECENT"), 14, C.Accent)
			for _, item in recent do
				local line = text(item.Key, item.Args)
				if item.Kind == "Choice" then
					line = Strings.get("RECAP.CHOICE", { text = line })
				end
				add(("%s %s"):format(item.Icon or "•", line), 14, C.Text)
			end
		end
		local objective = payload.Objective
		if objective then
			local now = Strings.get("RECAP.NOW", { title = (if objective.Icon then objective.Icon .. " " else "") .. text(objective.TitleKey) })
			add(now, 15, C.Money, true)
			add(text(objective.TextKey, objective.Args), 14, C.Text)
		else
			add(Strings.get("RECAP.NOTHING"), 14, C.Text)
		end
		add(Strings.get("RECAP.TAP"), 12, C.Muted)
	end)
end

---------------------------------------------------------------------
-- Decisiones y ofrecimientos
---------------------------------------------------------------------

-- Una ventana por tipo: una decisión y un ofrecimiento pueden estar a la vez (antes uno borraba al otro
-- y la decisión se perdía). El ofrecimiento se pone encima de la decisión.
local openDialogs: { [string]: Frame } = {}
local choiceShown: string? = nil -- qué decisión se está enseñando (para no rehacerla si llega otra vez)

local function layoutDialogs()
	local choice = openDialogs.Choice
	local offer = openDialogs.Offer
	if offer then
		local above = if choice and choice.Parent then choice.AbsoluteSize.Y + 10 else 0
		offer.Position = UDim2.new(0.5, 0, 1, -110 - above)
	end
end

-- ¿Hay una decisión o un ofrecimiento en pantalla? (abajo en el centro: la tarjeta de los primeros
-- pasos, Controllers/Guide, espera a que se cierre)
function LifeStory.hasDialog(): boolean
	for _, panel in openDialogs do
		if panel.Parent then
			return true
		end
	end
	return false
end

local function closeDialog(slot: string, panel: Frame)
	if openDialogs[slot] == panel then
		openDialogs[slot] = nil
		if slot == "Choice" then
			choiceShown = nil
		end
	end
	panel:Destroy()
	layoutDialogs()
end

-- extra: líneas de contexto entre el mensaje y las opciones ({ Text, Color?, Size? })
-- inline: las opciones en una fila (ocupa menos alto en el móvil)
local function dialog(slot: string, title: string?, message: string, options: { { Text: string, OnPick: () -> () } }, extra: { { [string]: any } }?, inline: boolean?)
	if openDialogs[slot] then
		closeDialog(slot, openDialogs[slot])
	end
	local panel = Theme.panel({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 25,
		Parent = gui,
	})
	openDialogs[slot] = panel
	Theme.padding(if extra then 10 else 14).Parent = panel
	create("UIListLayout", { Padding = UDim.new(0, if extra then 5 else 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	if title then
		Theme.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, Text = title, Font = Theme.FontBold, TextSize = 17, TextColor3 = C.Accent, LayoutOrder = 1, ZIndex = 26, Parent = panel })
	end
	Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = message or "",
		TextSize = 15,
		TextWrapped = true,
		LayoutOrder = 2,
		ZIndex = 26,
		Parent = panel,
	})
	for i, line in extra or {} do
		Theme.label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = line.Text,
			TextSize = line.Size or 13,
			TextWrapped = true,
			TextColor3 = line.Color or C.Muted,
			LayoutOrder = 10 + i, -- después del mensaje y antes de las opciones
			ZIndex = 26,
			Parent = panel,
		})
	end
	local row: Frame? = nil
	if inline then
		row = create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = 99, ZIndex = 26, Parent = panel })
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	end
	for i, option in options do
		local button = Theme.button({
			Size = if row then UDim2.new(1 / #options, -8 * (#options - 1) / #options, 1, 0) else UDim2.new(1, 0, 0, 34),
			AutomaticSize = if row then Enum.AutomaticSize.None else Enum.AutomaticSize.Y, -- las opciones largas pasan a dos líneas
			TextWrapped = true,
			Text = option.Text,
			TextSize = 15,
			LayoutOrder = 100 + i,
			ZIndex = 26,
			Parent = row or panel,
		})
		button.Activated:Connect(function()
			closeDialog(slot, panel)
			option.OnPick()
		end)
	end
	-- (el tamaño final se sabe un momento después)
	task.defer(layoutDialogs)
	if slot == "Choice" then
		panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutDialogs)
	end
	return panel
end

---------------------------------------------------------------------

local handlers: { [string]: (payload: { [string]: any }) -> () } = {
	State = function(payload)
		renderCard(payload)
		StoryAudio.setAmbient(payload.ChapterMusic)
	end,
	Moment = function(payload)
		queue(function()
			StoryAudio.sting(payload.Sting)
			showMoment(text(payload.TextKey, payload.Args))
		end)
	end,
	Cinematic = function(payload)
		-- Cuenta como escena en marcha desde que llega (un diálogo no se abre mientras espera su turno)
		local release = Cinematics.hold()
		queue(function()
			pcall(Cinematics.play, payload)
			release()
		end)
	end,
	Chapter = function(payload)
		queue(function()
			StoryAudio.sting("Capitulo")
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
		-- El servidor vuelve a mandar la decisión mientras no se elige: si ya está en pantalla, se deja
		local key = tostring(payload.QuestId) .. "|" .. tostring(payload.PromptKey)
		for _, option in payload.Options do
			key ..= "|" .. tostring(option.Id)
		end
		if openDialogs.Choice and openDialogs.Choice.Parent and choiceShown == key then
			return
		end
		local options = {}
		for _, option in payload.Options do
			table.insert(options, {
				Text = Strings.get(option.TextKey),
				OnPick = function()
					Remote:FireServer("Choose", payload.QuestId, option.Id)
				end,
			})
		end
		dialog("Choice", nil, Strings.get(payload.PromptKey), options)
		choiceShown = key
	end,
	Offer = function(payload)
		-- Título con el tipo (⭐/🌀/❗/🔶), lo que te dicen y, debajo, quién te lo pide y por qué
		local title = Strings.get(payload.TitleKey)
		if payload.Icon then
			title = payload.Icon .. " " .. title
		end
		local extra = {}
		if payload.Label then
			table.insert(extra, { Text = payload.Label, Color = C.Gold, Size = 12 })
		end
		if payload.Asker then
			table.insert(extra, { Text = Strings.get("STORY.CONTEXT.ASKS", { who = text(payload.Asker) }), Color = C.Accent, Size = 13 })
		end
		if payload.Description then
			table.insert(extra, { Text = text(payload.Description), Color = C.Muted, Size = 13 })
		end
		local panel = dialog("Offer", title, Strings.get(payload.TextKey), {
			{ Text = Strings.get("STORY.OFFER.ACCEPT"), OnPick = function()
				Remote:FireServer("Offer", payload.QuestId, true)
			end },
			{ Text = Strings.get("STORY.OFFER.DECLINE"), OnPick = function()
				Remote:FireServer("Offer", payload.QuestId, false)
			end },
		}, if #extra > 0 then extra else nil, true)
		-- Si no contesta, el ofrecimiento se va solo (el servidor lo olvida a los 30 s)
		task.delay(28, function()
			if panel.Parent then
				closeDialog("Offer", panel)
			end
		end)
	end,
	QuestIntro = function(payload)
		queue(function()
			showIntro(payload)
		end)
	end,
	Recap = function(payload)
		queue(function()
			showRecap(payload)
		end)
	end,
	Journal = function(payload)
		StoryJournal.show(payload)
	end,
}

-- «Mi historia» (desde el Menú)
function LifeStory.openJournal()
	StoryJournal.open()
end

function LifeStory.init()
	gui = create("ScreenGui", {
		Name = "LifeStory",
		ResetOnSpawn = false,
		DisplayOrder = 8, -- encima del HUD y del minimapa (pantallas de capítulo, decisiones)
		IgnoreGuiInset = true, -- el fundido cubre también la franja de arriba
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	buildCard()

	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LifeStory") :: RemoteEvent
	StoryJournal.init(Remote)
	local synced = false
	Remote.OnClientEvent:Connect(function(kind: string, payload: { [string]: any })
		if kind == "State" then
			synced = true
		end
		local handler = handlers[kind]
		if handler and kind == "Offer" and player:GetAttribute("InDialogue") then
			-- Un ofrecimiento nunca tapa una conversación: sale cuando termina (como mucho, 20 s)
			task.spawn(function()
				local since = os.clock()
				while player:GetAttribute("InDialogue") and os.clock() - since < 20 do
					task.wait(0.3)
				end
				if not player:GetAttribute("InDialogue") then
					handler(payload)
				end
			end)
			return
		end
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
