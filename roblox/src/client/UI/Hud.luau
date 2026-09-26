-- Hud: la interfaz principal del juego (diseño v2, paneles azul marino con borde azul).
--
--   Arriba en el centro  -> hora del día y fecha ("Lunes, 12 de septiembre · Día 1 · Primer día de colegio")
--   Arriba a la derecha  -> botones: Mochila, Personaje, Mapa, Misiones, Teléfono y Menú (el minimapa va debajo)
--   Izquierda            -> ficha del jugador (foto, nombre, nivel y experiencia, dinero), objetivos de la
--                           historia (principal y opcionales) y el trabajo actual
--   Abajo a la izquierda -> Salud, Energía, Hambre y Estamina
--   Abajo a la derecha   -> dónde estás ("Tu casa · Salón", "Colegio · Biblioteca", "Los Pinos")
--   Avisos en el centro, pantalla negra para dormir y viajar.
-- Otros sistemas se enganchan con Hud.setAction (botones de arriba) y Hud.addButton (apps del teléfono).

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local GameClock = require(ReplicatedStorage.Shared.GameClock)
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Theme)

local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local Hud = {}

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui: ScreenGui
local popupGui: ScreenGui -- teléfono y menú: por encima del minimapa
local toastList: Frame
local sleepOverlay: Frame
local actions: { [string]: () -> () } = {}
local phoneApps: { { Text: string, Color: Color3?, Order: number, Callback: () -> () } } = {}
local questBadge: Frame
local objectivesPanel: Frame
local questTitleShown = ""

local WEEKDAYS = { "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo" }
local MONTHS = { "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre" }

---------------------------------------------------------------------
-- Piezas comunes
---------------------------------------------------------------------

-- Panel de cristal: azul marino semitransparente, esquinas redondeadas y borde azul
local function glass(props: { [string]: any }): Frame
	props.BackgroundTransparency = props.BackgroundTransparency or 0.18
	local panel = Theme.panel(props)
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(rgb(24, 40, 72), rgb(10, 18, 34)),
		Parent = panel,
	})
	panel.BackgroundColor3 = Color3.new(1, 1, 1) -- el degradado pone el color
	return panel
end

local function icon(parent: Instance, text: string, size: number, position: UDim2): TextLabel
	return Theme.label({
		Size = UDim2.fromOffset(size, size),
		Position = position,
		Text = text,
		TextSize = math.floor(size * 0.7),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = parent,
	})
end

-- Barra con degradado (vida, energía…). Devuelve la función para actualizarla.
local function gradientBar(parent: Instance, y: number, emoji: string, name: string, from: Color3, to: Color3): (number, number) -> ()
	local row = create("Frame", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1, Parent = parent })
	local badge = create("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(0, 1), BackgroundColor3 = from, Parent = row }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = emoji, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Parent = badge })
	Theme.label({ Size = UDim2.new(1, -90, 0, 14), Position = UDim2.fromOffset(38, 0), Text = name, TextSize = 12, Font = Theme.FontBold, Parent = row })
	local track = create("Frame", { Size = UDim2.new(1, -88, 0, 10), Position = UDim2.fromOffset(38, 16), BackgroundColor3 = rgb(20, 30, 52), BorderSizePixel = 0, Parent = row }, { Theme.corner(5) })
	local fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track }, {
		Theme.corner(5),
		create("UIGradient", { Color = ColorSequence.new(from, to) }),
	})
	local value = Theme.label({ Size = UDim2.fromOffset(44, 30), Position = UDim2.new(1, -44, 0, 0), TextSize = 14, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
	return function(amount: number, max: number)
		local ratio = math.clamp(amount / math.max(max, 1), 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(ratio, 1) }):Play()
		value.Text = tostring(math.floor(amount + 0.5))
	end
end

---------------------------------------------------------------------
-- Arriba en el centro: hora y fecha
---------------------------------------------------------------------
local function buildClock(parent: Instance)
	local panel = glass({
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(470, 58),
		Position = UDim2.new(0.5, 0, 0, 10),
		Parent = parent,
	})
	local sun = icon(panel, "☀", 34, UDim2.fromOffset(14, 12))
	local time = Theme.label({ Size = UDim2.fromOffset(90, 58), Position = UDim2.fromOffset(52, 0), Font = Theme.FontBold, TextSize = 26, Parent = panel })
	create("Frame", { Size = UDim2.fromOffset(1, 34), Position = UDim2.fromOffset(150, 12), BackgroundColor3 = C.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = panel })
	icon(panel, "📅", 28, UDim2.fromOffset(164, 15))
	local date = Theme.label({ Size = UDim2.new(1, -206, 0, 22), Position = UDim2.fromOffset(200, 8), Font = Theme.FontBold, TextSize = 16, Parent = panel })
	local sub = Theme.label({ Size = UDim2.new(1, -206, 0, 18), Position = UDim2.fromOffset(200, 30), TextSize = 13, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	local function tick()
		local clock = Lighting.ClockTime
		local day = clock >= 6.5 and clock < 19.5
		sun.Text = if day then "☀" else "🌙"
		time.Text = Format.clock(clock)
		local now = GameClock.now()
		date.Text = ("%s, %d de %s"):format(WEEKDAYS[now.Weekday] or "", now.DayOfMonth, MONTHS[now.Month] or "")
		sub.Text = "Día " .. tostring(now.Day) .. (if questTitleShown ~= "" then " · " .. questTitleShown else "")
	end
	-- 4 veces por segundo basta (un minuto del juego dura menos de un segundo real)
	task.spawn(function()
		while true do
			tick()
			task.wait(0.25)
		end
	end)
end

---------------------------------------------------------------------
-- Arriba a la derecha: botones grandes
---------------------------------------------------------------------
local TOP_BUTTONS = {
	{ Id = "Mochila", Icon = "🎒", Text = "Mochila" },
	{ Id = "Personaje", Icon = "⭐", Text = "Personaje" },
	{ Id = "Mapa", Icon = "🗺", Text = "Mapa" },
	{ Id = "Misiones", Icon = "📋", Text = "Misiones" },
	{ Id = "Telefono", Icon = "📱", Text = "Teléfono" },
	{ Id = "Menu", Icon = "☰", Text = "Menú" },
}

local function buildTopButtons(parent: Instance)
	local bar = create("Frame", {
		Name = "TopButtons",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(#TOP_BUTTONS * 80 + (#TOP_BUTTONS - 1) * 6, 70),
		Position = UDim2.new(1, -12, 0, 10),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	for i, def in TOP_BUTTONS do
		local button = create("TextButton", {
			Name = def.Id,
			Size = UDim2.fromOffset(80, 70),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.18,
			AutoButtonColor = true,
			Text = "",
			LayoutOrder = i,
			Parent = bar,
		}, { Theme.corner(12), Theme.stroke(), create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(26, 44, 80), rgb(10, 18, 34)) }) })
		Theme.label({ Name = "Icon", Size = UDim2.new(1, 0, 0, 38), Position = UDim2.fromOffset(0, 6), Text = def.Icon, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Parent = button })
		Theme.label({ Name = "Caption", Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 46), Text = def.Text, TextSize = 13, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = button })
		button.Activated:Connect(function()
			local action = actions[def.Id]
			if action then
				action()
			end
		end)
		if def.Id == "Misiones" then
			questBadge = create("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -16, 0, 2), BackgroundColor3 = rgb(235, 50, 70), Visible = false, Parent = button }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		end
	end
end

---------------------------------------------------------------------
-- Izquierda: ficha del jugador
---------------------------------------------------------------------
local function buildPlayerCard(parent: Instance)
	local card = glass({ Name = "PlayerCard", Size = UDim2.fromOffset(420, 104), Position = UDim2.fromOffset(12, 76), Parent = parent })
	local ring = create("Frame", { Size = UDim2.fromOffset(84, 84), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = rgb(20, 34, 60), Parent = card }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = C.Accent, Thickness = 3 }),
	})
	local photo = create("ImageLabel", { Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, Parent = ring }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then
			photo.Image = image
		end
	end)
	Theme.label({ Size = UDim2.new(1, -120, 0, 26), Position = UDim2.fromOffset(108, 10), Text = player.DisplayName, Font = Theme.FontBold, TextSize = 21, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
	local levelChip = create("Frame", { Size = UDim2.fromOffset(96, 22), Position = UDim2.fromOffset(108, 40), BackgroundColor3 = rgb(36, 110, 230), Parent = card }, { Theme.corner(11) })
	local levelText = Theme.label({ Size = UDim2.fromScale(1, 1), Font = Theme.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Parent = levelChip })
	local money = Theme.label({ Size = UDim2.fromOffset(170, 22), Position = UDim2.new(1, -180, 0, 40), Font = Theme.FontBold, TextSize = 16, TextColor3 = C.Money, TextXAlignment = Enum.TextXAlignment.Right, Parent = card })
	local track = create("Frame", { Size = UDim2.new(1, -120, 0, 10), Position = UDim2.fromOffset(108, 72), BackgroundColor3 = rgb(20, 30, 52), BorderSizePixel = 0, Parent = card }, { Theme.corner(5) })
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track }, {
		Theme.corner(5),
		create("UIGradient", { Color = ColorSequence.new(rgb(40, 120, 255), rgb(90, 200, 255)) }),
	})
	local xpText = Theme.label({ Size = UDim2.new(1, -120, 0, 14), Position = UDim2.fromOffset(108, 84), TextSize = 12, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = card })

	local function update()
		local level = player:GetAttribute("Level") or 1
		local points = player:GetAttribute("StatPoints") or 0
		levelText.Text = ("⭐ Nivel %d%s"):format(level, if points > 0 then " +" else "")
		local xp, need = player:GetAttribute("Xp") or 0, player:GetAttribute("XpNext") or 100
		TweenService:Create(fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(xp / math.max(need, 1), 0, 1), 1) }):Play()
		xpText.Text = ("%d / %d XP"):format(xp, need)
		local tickets = player:GetAttribute("Tickets") or 0
		money.Text = Format.money(player:GetAttribute("Money") or 0) .. (if tickets > 0 then ("   🎟 %d"):format(tickets) else "")
	end
	for _, attribute in { "Level", "StatPoints", "Xp", "XpNext", "Money", "Tickets" } do
		player:GetAttributeChangedSignal(attribute):Connect(update)
	end
	update()
end

---------------------------------------------------------------------
-- Izquierda: objetivos de la historia y trabajo actual
---------------------------------------------------------------------
local function storyText(key: string?, args: { [string]: any }?): string
	if not key then
		return ""
	end
	local resolved = table.clone(args or {})
	if resolved.placeKey then
		resolved.place = Strings.get(resolved.placeKey)
	end
	resolved.nombre = resolved.nombre or player.DisplayName
	resolved.familia = resolved.familia or Strings.get(player:GetAttribute("FamilyKey") or "NPC.MAMA")
	if resolved.subjectKey then
		resolved.subject = Strings.get(resolved.subjectKey)
	end
	if resolved.degreeKey then
		resolved.degree = Strings.get(resolved.degreeKey)
	end
	return Strings.get(key, resolved)
end

local objectivesList: Frame
local objectivesWanted = true -- el botón Misiones los muestra u oculta
local busy = false -- en una conversación o cinemática
local jobBox: Frame

local function objectiveRow(parent: Instance, order: number, text: string, done: boolean?, strong: boolean?)
	local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local dot = create("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(4, 3), BackgroundColor3 = if done then C.Money else C.Gold, BackgroundTransparency = if done or strong then 0 else 1, Parent = row }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = if done then C.Money else C.Muted, Thickness = 1.5 }),
	})
	if done then
		Theme.label({ Size = UDim2.fromScale(1, 1), Text = "✓", TextSize = 11, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = dot })
	end
	Theme.label({
		Size = UDim2.new(1, -28, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(26, 0),
		Text = text,
		TextSize = 15,
		TextWrapped = true,
		TextColor3 = if done then C.Muted else C.Text,
		Parent = row,
	})
	return row
end

local function section(parent: Instance, order: number, emoji: string, title: string, color: Color3)
	local header = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local badge = create("Frame", { Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = color, Parent = header }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = emoji, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Parent = badge })
	Theme.label({ Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(36, 0), Text = title, Font = Theme.FontBold, TextSize = 16, TextColor3 = color, Parent = header })
end

-- 7.5 -> "7:30"
local function hourText(hour: number): string
	local h = math.floor(hour)
	return ("%d:%02d"):format(h, math.floor((hour - h) * 60 + 0.5))
end

local function renderObjectives(state: { [string]: any })
	for _, child in objectivesList:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local tracked = state.Tracked
	local title = ""
	if tracked then
		section(objectivesList, nextOrder(), "★", if tracked.Kind == "Side" then "Objetivo opcional" else "Objetivo principal", C.Gold)
		title = Strings.get(tracked.TitleKey)
		local titleBox = create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = rgb(30, 56, 110), BackgroundTransparency = 0.3, LayoutOrder = nextOrder(), Parent = objectivesList }, { Theme.corner(8) })
		Theme.label({ Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), Text = "⭐ " .. title, Font = Theme.FontBold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, Parent = titleBox })
		if tracked.Closed then
			-- El sitio al que toca ir está cerrado a esta hora
			objectiveRow(objectivesList, nextOrder(), ("🌙 %s está cerrado · abre a las %s"):format(tracked.Closed.Name, hourText(tracked.Closed.From)), false, true)
			objectiveRow(objectivesList, nextOrder(), "💤 Puedes dormir en tu cama para que pase antes el tiempo", false)
		end
		local children = tracked.Children or {}
		if #children > 0 then
			local firstPending = true
			for _, child in children do
				objectiveRow(objectivesList, nextOrder(), storyText(child.TextKey, child.Args), child.Done, not child.Done and firstPending)
				if not child.Done then
					firstPending = false
				end
			end
		else
			objectiveRow(objectivesList, nextOrder(), storyText(tracked.TextKey, tracked.Args), false, true)
		end
	elseif state.Waiting then
		local waiting = state.Waiting
		section(objectivesList, nextOrder(), "★", "Objetivo principal", C.Gold)
		title = Strings.get(waiting.TitleKey)
		objectiveRow(objectivesList, nextOrder(), title, false, true)
		objectiveRow(objectivesList, nextOrder(), if waiting.Reason == "Hours" and waiting.From then ("🕗 Empieza a las %s (ahora está cerrado)"):format(hourText(waiting.From)) elseif waiting.Reason == "Hours" then Strings.get("STORY.WAIT.HOURS", { from = waiting.From, to = waiting.To }) else Strings.get("STORY.WAIT.DAYS"), false)
		if waiting.Reason == "Hours" then
			objectiveRow(objectivesList, nextOrder(), "💤 Puedes dormir en tu cama para que pase antes el tiempo", false)
		end
	end
	local others = state.Others or {}
	if #others > 0 then
		section(objectivesList, nextOrder(), "◆", "Objetivos opcionales", C.Purple)
		for i = 1, math.min(3, #others) do
			local other = others[i]
			local row = objectiveRow(objectivesList, nextOrder(), Strings.get(other.TitleKey), false)
			-- Pulsar un objetivo opcional lo convierte en el que sigues
			if other.QuestId then
				local pick = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = row })
				pick.Activated:Connect(function()
					(Remotes:WaitForChild("LifeStory") :: RemoteEvent):FireServer("Track", other.QuestId)
				end)
			end
		end
	end
	if title ~= questTitleShown then
		questTitleShown = title
		if questBadge and not objectivesPanel.Visible and title ~= "" then
			questBadge.Visible = true
		end
	end
	objectivesList.Parent.Visible = order > 0
end

local function buildObjectives(parent: Instance)
	objectivesPanel = create("Frame", {
		Name = "Objectives",
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(12, 188),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = objectivesPanel })

	local story = glass({ Name = "Story", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 1, Parent = objectivesPanel })
	Theme.padding(12).Parent = story
	objectivesList = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = story })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = objectivesList })

	-- Trabajo actual (camarero, repartidor…) con su tarea y el botón para dejarlo
	jobBox = glass({ Name = "Job", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 2, Parent = objectivesPanel })
	Theme.padding(12).Parent = jobBox
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = jobBox })
	local jobTitle = Theme.label({ Size = UDim2.new(1, 0, 0, 22), Font = Theme.FontBold, TextSize = 16, TextColor3 = C.Accent, LayoutOrder = 1, Parent = jobBox })
	local jobTask = Theme.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14, TextWrapped = true, LayoutOrder = 2, Parent = jobBox })
	local quit = Theme.button({ Size = UDim2.fromOffset(140, 28), Text = "Dejar trabajo", TextSize = 13, BackgroundColor3 = rgb(140, 40, 50), LayoutOrder = 3, Parent = jobBox })
	quit.Activated:Connect(function()
		(Remotes:WaitForChild("QuitJob") :: RemoteEvent):FireServer()
	end)
	local function updateJob()
		local jobId = player:GetAttribute("Job")
		local job = jobId and (Config.Jobs[jobId] or Gameplay.Jobs[jobId])
		jobBox.Visible = job ~= nil
		if job then
			jobTitle.Text = "💼 " .. job.DisplayName .. "  ·  " .. Format.money(job.Pay)
			jobTask.Text = player:GetAttribute("TaskText") or ""
		end
	end
	player:GetAttributeChangedSignal("Job"):Connect(updateJob)
	player:GetAttributeChangedSignal("TaskText"):Connect(updateJob)
	updateJob()

	-- Los objetivos llegan de la historia (el mismo estado que usa LifeStory)
	task.spawn(function()
		local remote = Remotes:WaitForChild("LifeStory") :: RemoteEvent
		local synced = false
		remote.OnClientEvent:Connect(function(kind: string, payload: any)
			if kind == "State" and typeof(payload) == "table" then
				synced = true
				renderObjectives(payload)
			end
		end)
		for _ = 1, 20 do
			if synced then
				break
			end
			remote:FireServer("Sync")
			task.wait(3)
		end
	end)

	actions.Misiones = function()
		objectivesWanted = not objectivesWanted
		objectivesPanel.Visible = objectivesWanted and not busy
		questBadge.Visible = false
	end
end

---------------------------------------------------------------------
-- Abajo a la izquierda: Salud, Energía, Hambre y Estamina
---------------------------------------------------------------------
local function buildVitals(parent: Instance)
	local panel = glass({ Name = "Vitals", AnchorPoint = Vector2.new(0, 1), Size = UDim2.fromOffset(330, 150), Position = UDim2.new(0, 12, 1, -12), Parent = parent })
	local inner = create("Frame", { Size = UDim2.new(1, -24, 1, -16), Position = UDim2.fromOffset(12, 8), BackgroundTransparency = 1, Parent = panel })
	local setHealth = gradientBar(inner, 0, "❤", "Salud", rgb(170, 60, 220), rgb(245, 60, 90))
	local setEnergy = gradientBar(inner, 34, "⚡", "Energía", rgb(245, 140, 30), rgb(255, 220, 60))
	local setHunger = gradientBar(inner, 68, "🍔", "Hambre", rgb(40, 140, 255), rgb(90, 220, 255))
	local setStamina = gradientBar(inner, 102, "🏃", "Estamina", rgb(40, 180, 110), rgb(140, 240, 160))

	local healthConnection: RBXScriptConnection? = nil
	local function watchHumanoid(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		if healthConnection then
			healthConnection:Disconnect()
		end
		local function update()
			setHealth(humanoid.Health, humanoid.MaxHealth)
		end
		healthConnection = humanoid.HealthChanged:Connect(update)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
		update()
	end
	player.CharacterAdded:Connect(watchHumanoid)
	if player.Character then
		task.spawn(watchHumanoid, player.Character)
	end
	local function needs()
		setEnergy(player:GetAttribute("Energy") or Config.Needs.Max, Config.Needs.Max)
		setHunger(player:GetAttribute("Hunger") or Config.Needs.Max, Config.Needs.Max)
		local max = player:GetAttribute("MaxStamina") or Gameplay.Progression.Stamina.Base
		setStamina(player:GetAttribute("Stamina") or max, max)
	end
	for _, attribute in { "Energy", "Hunger", "Stamina", "MaxStamina" } do
		player:GetAttributeChangedSignal(attribute):Connect(needs)
	end
	needs()
end

---------------------------------------------------------------------
-- Abajo a la derecha: dónde estás
---------------------------------------------------------------------
local ROOM_NAMES = { Salon = "Salón", Cocina = "Cocina", Dormitorio = "Dormitorio" }
local AREA_NAMES = {
	Pasillo = { "Colegio", "Pasillo" }, Patio = { "Colegio", "Patio" }, Gimnasio = { "Colegio", "Gimnasio" },
	Almacen = { "Colegio", "Almacén" }, Comedor = { "Colegio", "Comedor" }, Biblioteca = { "Colegio", "Biblioteca" },
	SalaCerrada = { "Colegio", "Sala cerrada" }, Parque = { "Parque", "Zona verde" },
}

local function inside(part: Instance, position: Vector3): boolean
	if not part:IsA("BasePart") then
		return false
	end
	local p = part.CFrame:PointToObjectSpace(position)
	local h = part.Size / 2
	return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y + 2 and math.abs(p.Z) <= h.Z
end

local function nearestZone(position: Vector3): (string?, number)
	local zones = ReplicatedStorage:FindFirstChild("MapZones")
	local best, bestDistance = nil, math.huge
	for _, zone in if zones then zones:GetChildren() else {} do
		local center = zone:GetAttribute("Center")
		if typeof(center) == "Vector3" then
			local d = (Vector3.new(center.X, 0, center.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
			if d < bestDistance then
				best, bestDistance = zone:GetAttribute("ZoneName"), d
			end
		end
	end
	return best, bestDistance
end

local function buildLocation(parent: Instance)
	local panel = glass({ Name = "Location", AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(300, 66), Position = UDim2.new(1, -12, 1, -12), Parent = parent })
	local emoji = icon(panel, "🏙", 40, UDim2.fromOffset(12, 13))
	local title = Theme.label({ Size = UDim2.new(1, -110, 0, 26), Position = UDim2.fromOffset(64, 9), Font = Theme.FontBold, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	local sub = Theme.label({ Size = UDim2.new(1, -110, 0, 18), Position = UDim2.fromOffset(64, 36), TextSize = 13, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	icon(panel, "📍", 26, UDim2.new(1, -38, 0, 20))
	task.spawn(function()
		while true do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local position = root.Position
				-- Título: el barrio (si estás cerca de uno); debajo, el distrito
				local zone, zoneDistance = nearestZone(position)
				local district = MapInfo.districtAt(position.X, position.Z)
				local districtName = if district then district.Name else "Naturaleza de Valmar"
				local t, s, e = if zone and zoneDistance < 650 then zone else districtName, if zone and zoneDistance < 650 then districtName else (if district then district.Theme else "Montes y costa"), "🏙"
				zone = districtName
				local homeId = player:GetAttribute("FamilyHomeId")
				for _, room in CollectionService:GetTagged("Room") do
					if inside(room, position) then
						local mine = homeId ~= nil and room:GetAttribute("HomeId") == homeId
						t, s, e = if mine then "Tu casa" else "Casa", (ROOM_NAMES[room:GetAttribute("Room")] or "") .. " · Zona residencial", "🏠"
						break
					end
				end
				if e == "🏙" then
					for _, area in CollectionService:GetTagged("StoryArea") do
						local names = AREA_NAMES[area:GetAttribute("AreaId")]
						if names and inside(area, position) then
							t, s, e = names[1], names[2] .. " · " .. zone, if names[1] == "Parque" then "🌳" else "🏫"
							break
						end
					end
				end
				if e == "🏙" then
					for _, classroom in CollectionService:GetTagged("Classroom") do
						if inside(classroom, position) then
							t, s, e = "Colegio", "Aula · " .. zone, "🏫"
							break
						end
					end
				end
				title.Text, sub.Text, emoji.Text = t, s, e
			end
			task.wait(0.5)
		end
	end)
end

---------------------------------------------------------------------
-- Teléfono (apps que añaden otros sistemas) y menú
---------------------------------------------------------------------
local phone: Frame
local menu: Frame

local function buildPhone(parent: Instance)
	phone = glass({
		Name = "Phone",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(240, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -12, 0, 88),
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	})
	Theme.padding(12).Parent = phone
	create("UIGridLayout", { CellSize = UDim2.fromOffset(100, 64), CellPadding = UDim2.fromOffset(12, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = phone })
	actions.Telefono = function()
		phone.Visible = not phone.Visible
		if menu then
			menu.Visible = false
		end
	end
end

local function refreshPhone()
	for _, child in phone:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	table.sort(phoneApps, function(a, b)
		return a.Order < b.Order
	end)
	for i, app in phoneApps do
		local button = Theme.button({ Text = app.Text, TextSize = 14, TextWrapped = true, BackgroundColor3 = app.Color or C.PanelLight, LayoutOrder = i, ZIndex = 21, Parent = phone })
		button.Activated:Connect(function()
			phone.Visible = false
			app.Callback()
		end)
	end
end

local function buildMenu(parent: Instance)
	menu = glass({
		Name = "Menu",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(260, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -12, 0, 88),
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	})
	Theme.padding(12).Parent = menu
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "Menú", Font = Theme.FontBold, TextSize = 18, LayoutOrder = 0, ZIndex = 21, Parent = menu })
	local help = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = if game:GetService("UserInputService").TouchEnabled
			then "Controles en el móvil:\nToca los botones que salen sobre las cosas para usarlas\n🏃 correr · 😀 gestos · 🔦 linterna · 📷 foto\nConduciendo: joystick para girar y acelerar · 📯 claxon\n🗺️ Mapa y 🎒 Mochila, arriba"
			else "Controles:\nE interactuar · Shift correr · F bajarse\nM mapa · 1-9 barra rápida\nG gestos y bailes · L linterna · P modo foto\nConducir: W/A/S/D · H claxon\nSalta contra un muro bajo para trepar",
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = C.Muted,
		LayoutOrder = 99,
		ZIndex = 21,
		Parent = menu,
	})
	local _ = help
	actions.Menu = function()
		menu.Visible = not menu.Visible
		phone.Visible = false
	end
end

-- Añade una opción al menú (la usa el cliente para el botón de la música)
function Hud.addMenuToggle(text: string, order: number, callback: () -> string)
	local button = Theme.button({ Size = UDim2.new(1, 0, 0, 36), Text = text, TextSize = 15, LayoutOrder = order, ZIndex = 21, Parent = menu })
	button.Activated:Connect(function()
		button.Text = callback()
	end)
end

-- Botones de arriba (Mochila, Mapa, Personaje…): los conecta cada sistema
function Hud.setAction(id: string, callback: () -> ())
	actions[id] = callback
end

-- Añade una app al teléfono (antes eran botones sueltos a la izquierda)
function Hud.addButton(text: string, color: Color3?, order: number, callback: () -> ()): TextButton?
	table.insert(phoneApps, { Text = text, Color = color, Order = order, Callback = callback })
	if phone then
		refreshPhone()
	end
	return nil
end

---------------------------------------------------------------------
-- Avisos
---------------------------------------------------------------------

local TOAST_COLORS = {
	Success = C.Accent,
	Money = C.Money,
	Error = C.Error,
	Food = C.Energy,
	Info = C.Muted,
	Sleep = C.Muted,
}

function Hud.toast(kind: string, text: string)
	local color = TOAST_COLORS[kind] or C.Muted
	local toast = glass({
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = toastList,
	})
	Theme.padding(10).Parent = toast
	local stroke = toast:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = color
	local label = Theme.label({
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = text,
		Font = Theme.FontBold,
		TextColor3 = color,
		Parent = toast,
	})
	task.delay(3, function()
		local fadeOut = TweenInfo.new(0.4)
		TweenService:Create(toast, fadeOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, fadeOut, { Transparency = 1 }):Play()
		TweenService:Create(label, fadeOut, { TextTransparency = 1 }):Play()
		task.wait(0.45)
		toast:Destroy()
	end)
end

-- Pantalla en negro con un texto (dormir, viajar…)
function Hud.fade(text: string, seconds: number)
	local caption = sleepOverlay:FindFirstChild("Caption") :: TextLabel?
	if caption then
		caption.Text = text
	end
	sleepOverlay.Visible = true
	sleepOverlay.BackgroundTransparency = 1
	TweenService:Create(sleepOverlay, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
	task.delay(math.max(seconds - 0.6, 0.6), function()
		local tween = TweenService:Create(sleepOverlay, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		sleepOverlay.Visible = false
	end)
end

function Hud.sleep()
	Hud.fade("Zzz...", Config.SleepSeconds)
end

-- Aviso fijo bajo el reloj (examen de conducir, etc.)
local function buildActivity(parent: Instance)
	local panel = glass({
		Name = "Activity",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 0, 76),
		Visible = false,
		Parent = parent,
	})
	Theme.padding(8).Parent = panel
	local label = Theme.label({ Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Font = Theme.FontBold, TextSize = 16, TextColor3 = C.Gold, Parent = panel })
	local function update()
		local text = player:GetAttribute("ActivityText")
		panel.Visible = typeof(text) == "string" and text ~= ""
		label.Text = if typeof(text) == "string" then text else ""
	end
	player:GetAttributeChangedSignal("ActivityText"):Connect(update)
	update()
end

---------------------------------------------------------------------

function Hud.init(openStore: () -> ()): ScreenGui
	gui = create("ScreenGui", {
		Name = "MainHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true, -- el diseño comparte la franja de arriba con los botones de Roblox
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Escala la interfaz según el tamaño de pantalla (móvil / PC)
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.55, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	buildClock(gui)
	buildActivity(gui)
	buildTopButtons(gui)
	buildPlayerCard(gui)
	buildObjectives(gui)
	buildVitals(gui)
	buildLocation(gui)
	-- El teléfono y el menú van en su propia capa, por encima del minimapa (que es de MapUI)
	popupGui = create("ScreenGui", { Name = "HudPopups", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, Parent = gui.Parent })
	local popupScale = create("UIScale", { Parent = popupGui })
	local function rescalePopups()
		popupScale.Scale = scale.Scale
	end
	scale:GetPropertyChangedSignal("Scale"):Connect(rescalePopups)
	rescalePopups()
	buildPhone(popupGui)
	buildMenu(popupGui)

	-- Colocación según la pantalla: en móvil y pantallas estrechas todo se recoloca
	--   * la columna izquierda empieza debajo de la barra de Roblox (menú y chat)
	--   * los botones de arriba se hacen pequeños y sin texto si no caben junto al reloj
	--   * en táctil: las barras de vida suben (abajo a la izquierda está el joystick)
	--     y el cartel de "dónde estás" se quita (abajo a la derecha está el botón de saltar;
	--     el nombre de la zona ya sale bajo el minimapa)
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local objectivesLimit = create("UISizeConstraint", { Parent = objectivesPanel })
	objectivesPanel.ClipsDescendants = true
	local function layout()
		local s = scale.Scale
		local canvas = camera.ViewportSize / s
		local inset = GuiService:GetGuiInset()
		local top = math.max(76, inset.Y / s + 8)
		local narrow = canvas.X < 1500
		local bar = gui:FindFirstChild("TopButtons") :: Frame
		local w, h = if narrow then 58 else 80, if narrow then 58 else 70
		bar.Size = UDim2.fromOffset(#TOP_BUTTONS * w + (#TOP_BUTTONS - 1) * 6, h)
		for _, button in bar:GetChildren() do
			if button:IsA("TextButton") then
				button.Size = UDim2.fromOffset(w, h)
				local caption = button:FindFirstChild("Caption") :: TextLabel
				local iconLabel = button:FindFirstChild("Icon") :: TextLabel
				caption.Visible = not narrow
				iconLabel.Position = UDim2.fromOffset(0, if narrow then 10 else 6)
			end
		end
		local clock = gui:FindFirstChild("Clock") :: Frame
		clock.Size = UDim2.fromOffset(if narrow then 400 else 470, 58)
		local card = gui:FindFirstChild("PlayerCard") :: Frame
		local vitals = gui:FindFirstChild("Vitals") :: Frame
		local location = gui:FindFirstChild("Location") :: Frame
		card.Position = UDim2.fromOffset(12, top)
		local y = top + 112
		if touch then
			vitals.AnchorPoint = Vector2.new(0, 0)
			vitals.Position = UDim2.fromOffset(12, y)
			y += 158
			location.Visible = false
		else
			vitals.AnchorPoint = Vector2.new(0, 1)
			vitals.Position = UDim2.new(0, 12, 1, -12)
		end
		objectivesPanel.Position = UDim2.fromOffset(12, y)
		local room = canvas.Y - y - (if touch then 16 else 176)
		objectivesLimit.MaxSize = Vector2.new(math.huge, math.max(120, room))
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.defer(layout)
	end)
	layout()

	-- Apps del teléfono que pone el propio HUD
	Hud.addButton("🏠 Ir a casa", rgb(40, 110, 200), 1, function()
		(Remotes:WaitForChild("GoHome") :: RemoteEvent):FireServer()
	end)
	Hud.addButton("🛒 Tienda", rgb(160, 115, 20), 2, openStore)
	refreshPhone()

	toastList = create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(600, 200),
		Position = UDim2.new(0.5, 0, 0, 118),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastList })

	-- La pantalla negra de dormir va en su propio ScreenGui (sin UIScale) para cubrirlo todo
	local overlayGui = create("ScreenGui", { Name = "SleepOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, Parent = gui.Parent })
	sleepOverlay = create("Frame", { Name = "Sleep", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false, Parent = overlayGui })
	Theme.label({ Name = "Caption", Size = UDim2.fromScale(1, 1), Text = "Zzz...", Font = Theme.FontBold, TextSize = 40, TextXAlignment = Enum.TextXAlignment.Center, Parent = sleepOverlay })

	-- De bebé casi todo sobra: solo la hora y dónde estás
	local function stage()
		local baby = player:GetAttribute("LifeStage") == "Bebe"
		for _, name in { "TopButtons", "PlayerCard", "Vitals" } do
			local element = gui:FindFirstChild(name)
			if element then
				element.Visible = not baby
			end
		end
	end
	player:GetAttributeChangedSignal("LifeStage"):Connect(stage)
	stage()

	return gui
end

-- Mientras hablas con alguien o ves una cinemática, los objetivos no tapan la escena
function Hud.setBusy(value: boolean)
	busy = value
	if objectivesPanel then
		objectivesPanel.Visible = objectivesWanted and not busy
	end
end

return Hud
