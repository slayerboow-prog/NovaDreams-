-- Hud: la interfaz principal del juego (estilo Kingdom Hearts 3).
--
--   Arriba en el centro  -> hora del día y fecha ("Lunes, 12 de septiembre · Día 1 · Primer día de colegio")
--   Abajo a la izquierda -> menú de comandos (Mochila, Personaje, Mapa, Misiones, Teléfono y Menú), como el
--                           "COMANDO" de KH3; en el móvil son iconos arriba a la derecha (abajo va el joystick)
--   Abajo a la derecha   -> tu estado: la foto en un aro y, saliendo de ella, las barras de Salud (verde),
--                           Energía (azul), Hambre y Estamina, con tu nombre, nivel, experiencia y dinero
--                           (en el móvil va arriba a la izquierda, al revés: abajo están los botones de saltar)
--   Izquierda            -> objetivos de la historia (principal y opcionales) y el trabajo actual
--   Al llegar a un sitio nuevo, su nombre aparece en grande (como al entrar en un mundo de KH3).
--   Avisos arriba en el centro, pantalla negra para dormir y viajar.
-- Otros sistemas se enganchan con Hud.setAction (comandos) y Hud.addButton (apps del teléfono).

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
local setText = Theme.setText
local C = Theme.Colors
local rgb = Color3.fromRGB

local Hud = {}

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Pantalla táctil sin teclado (móvil o tableta): abajo están el joystick y los botones de saltar
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local gui: ScreenGui
local popupGui: ScreenGui -- teléfono y menú: por encima del minimapa
local toastList: Frame
local sleepOverlay: Frame
local actions: { [string]: () -> () } = {}
local phoneApps: { { Text: string, Color: Color3?, Order: number, Callback: () -> () } } = {}
local objectivesPanel: Frame
local questTitleShown = ""

local WEEKDAYS = { "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo" }
local MONTHS = { "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre" }


---------------------------------------------------------------------
-- Piezas comunes
---------------------------------------------------------------------

-- Panel de cristal azul noche (el del tema)
local function glass(props: { [string]: any }): Frame
	props.BackgroundTransparency = props.BackgroundTransparency or 0.15
	return Theme.panel(props)
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

-- Pestaña de título (blanco-cian con letra oscura, o del color que se pida)
local function tab(parent: Instance, text: string, color: Color3?, props: { [string]: any }?): Frame
	local frame = create("Frame", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color or Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = parent,
	}, {
		Theme.corner(4),
		create("UIGradient", { Rotation = 90, Color = if color then Theme.Sheen else Theme.Selected }),
		create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 16) }),
	})
	for key, value in props or {} do
		(frame :: any)[key] = value
	end
	Theme.title({ Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Text = text, TextSize = 13, TextColor3 = C.Ink, Parent = frame })
	return frame
end

---------------------------------------------------------------------
-- Arriba en el centro: hora y fecha
---------------------------------------------------------------------
local function buildClock(parent: Instance)
	local panel = glass({
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(440, 54),
		Position = UDim2.new(0.5, 0, 0, 10),
		Parent = parent,
	})
	local sun = icon(panel, "☀", 32, UDim2.fromOffset(12, 11))
	local time = Theme.title({ Size = UDim2.fromOffset(92, 54), Position = UDim2.fromOffset(48, 0), TextSize = 26, Parent = panel })
	create("Frame", { Size = UDim2.fromOffset(2, 30), Position = UDim2.fromOffset(146, 12), BackgroundColor3 = C.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = panel })
	local date = Theme.label({ Size = UDim2.new(1, -170, 0, 22), Position = UDim2.fromOffset(160, 7), FontFace = Theme.ItalicFace, TextSize = 16, Parent = panel })
	local sub = Theme.label({ Size = UDim2.new(1, -170, 0, 18), Position = UDim2.fromOffset(160, 29), TextSize = 13, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	local function tick()
		local clock = Lighting.ClockTime
		local day = clock >= 6.5 and clock < 19.5
		setText(sun, if day then "☀" else "🌙")
		setText(time, Format.clock(clock))
		local now = GameClock.now()
		setText(date, ("%s, %d de %s"):format(WEEKDAYS[now.Weekday] or "", now.DayOfMonth, MONTHS[now.Month] or ""))
		setText(sub, "Día " .. tostring(now.Day) .. (if questTitleShown ~= "" then " · " .. questTitleShown else ""))
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
-- Comandos (Mochila, Personaje, Mapa, Misiones, Teléfono, Menú): los usa el menú de comandos
-- (client/Commands), que está abajo a la izquierda en todos los dispositivos
---------------------------------------------------------------------
local questPending = false

function Hud.runCommand(id: string)
	local action = actions[id]
	if action then
		action()
	end
end

-- ¿Hay una misión nueva sin mirar? (el menú de comandos pone un punto rojo en MISIONES)
function Hud.questPending(): boolean
	return questPending
end

---------------------------------------------------------------------
-- Tu estado (estilo "aro y gancho"): la foto dentro de un aro verde de VIDA que la rodea por
-- fuera y sigue por abajo como una barra larga. Al perder vida se vacía desde la punta de la
-- barra hacia la foto. Encima de la barra verde salen Estamina (azul), Energía y Hambre.
---------------------------------------------------------------------
local PORTRAIT = 96
local STATUS_W, STATUS_H = 380, 138
local RING_T = 12 -- grosor del aro y de la barra de vida
local RING_R = PORTRAIT / 2 + 4 + RING_T / 2 -- radio (línea central) del aro
local OUTER = RING_R + RING_T / 2 + 2
local CENTER = Vector2.new(OUTER + 2, OUTER + 2) -- centro de la foto (con la foto a la izquierda)
local ARC_FROM, ARC_TO = -150, 90 -- el aro empieza arriba (lado de las barras), rodea por fuera y baja
local SEGMENTS = 48
local HEALTH_LEN = 240 -- largo de la barra verde (desde el centro de la foto)
local ARC_LEN = RING_R * math.rad(ARC_TO - ARC_FROM)
local BARS = {
	-- Id, texto, alto, largo (desde el borde de la foto), colores del degradado
	{ Id = "Stamina", Emoji = "🏃", Height = 9, Width = 196, From = rgb(40, 80, 230), To = rgb(110, 170, 255) },
	{ Id = "Energy", Emoji = "⚡", Height = 8, Width = 168, From = rgb(245, 150, 30), To = rgb(255, 225, 80) },
	{ Id = "Hunger", Emoji = "🍔", Height = 8, Width = 140, From = rgb(230, 80, 40), To = rgb(255, 160, 70) },
}
local HEALTH_GREEN = { rgb(70, 200, 50), rgb(170, 255, 110) }
local HEALTH_YELLOW = { rgb(230, 180, 20), rgb(255, 235, 110) }
local HEALTH_RED = { rgb(220, 40, 40), rgb(255, 120, 100) }
local TRACK = rgb(12, 18, 32)

local status: Frame
local arrangeStatus: (side: string) -> ()

local function buildStatus(parent: Instance)
	status = create("Frame", { Name = "Status", Size = UDim2.fromOffset(STATUS_W, STATUS_H), BackgroundTransparency = 1, Parent = parent })

	-- Aro de vida: trocitos que siguen la curva (borde oscuro debajo y relleno encima)
	local rim, segs = {}, {}
	for i = 1, SEGMENTS do
		local chord = RING_R * math.rad((ARC_TO - ARC_FROM) / SEGMENTS)
		rim[i] = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(chord * 1.35 + 2, RING_T + 4), BackgroundColor3 = rgb(4, 8, 16), BorderSizePixel = 0, ZIndex = 1, Parent = status })
		segs[i] = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(chord * 1.3 + 1, RING_T), BackgroundColor3 = TRACK, BorderSizePixel = 0, ZIndex = 2, Parent = status })
	end
	-- Barra de vida (el "gancho" que sale por abajo)
	local healthTrack = create("Frame", { Name = "Health", Size = UDim2.fromOffset(HEALTH_LEN, RING_T), BackgroundColor3 = TRACK, BorderSizePixel = 0, ZIndex = 2, Parent = status }, {
		create("UIStroke", { Color = rgb(4, 8, 16), Thickness = 2 }),
		create("UICorner", { CornerRadius = UDim.new(0, 3) }),
	})
	local healthGradient = create("UIGradient", { Rotation = 90 })
	local healthFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = healthTrack }, {
		create("UICorner", { CornerRadius = UDim.new(0, 3) }),
		healthGradient,
	})
	local healthCaption = Theme.label({ Size = UDim2.fromOffset(62, 16), Font = Theme.FontBold, TextSize = 13, TextStrokeTransparency = 0.3, ZIndex = 4, Parent = status })

	-- Foto
	local ring = create("Frame", { Name = "Portrait", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(PORTRAIT, PORTRAIT), BackgroundColor3 = C.Panel, ZIndex = 4, Parent = status }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(4, 8, 16), Thickness = 3 }),
	})
	local photo = create("ImageLabel", { Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, ZIndex = 4, Parent = ring }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then
			photo.Image = image
		end
	end)
	local levelChip = create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(62, 20), Position = UDim2.new(0.5, 0, 1, -4), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5, Parent = ring }, {
		Theme.corner(10),
		create("UIGradient", { Rotation = 90, Color = Theme.Selected }),
		create("UIStroke", { Color = C.Ink, Thickness = 1, Transparency = 0.4 }),
	})
	local levelText = Theme.title({ Size = UDim2.fromScale(1, 1), TextSize = 12, TextColor3 = C.Ink, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5, Parent = levelChip })

	local name = Theme.title({ Name = "Name", Size = UDim2.fromOffset(STATUS_W - OUTER * 2 - 16, 22), Text = player.DisplayName, TextSize = 19, TextStrokeTransparency = 0.5, TextTruncate = Enum.TextTruncate.AtEnd, Parent = status })
	-- De servicio en una institución: el rango junto al nombre ("Ana · Sargento")
	local function nameText()
		local rank = player:GetAttribute("Rank")
		setText(name, if rank then ("%s · %s"):format(player.DisplayName, rank) else player.DisplayName)
	end
	player:GetAttributeChangedSignal("Rank"):Connect(nameText)
	nameText()
	local money = Theme.label({ Name = "Money", Size = UDim2.fromOffset(180, 18), Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Money, TextStrokeTransparency = 0.5, Parent = status })
	local xpText = Theme.label({ Name = "Xp", Size = UDim2.fromOffset(60, 14), Font = Theme.FontBold, TextSize = 11, TextColor3 = C.Muted, TextStrokeTransparency = 0.6, Parent = status })
	local xpTrack = create("Frame", { Name = "XpBar", Size = UDim2.fromOffset(150, 4), BackgroundColor3 = TRACK, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = status }, { Theme.corner(2) })
	local xpFill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = xpTrack }, {
		Theme.corner(2),
		create("UIGradient", { Color = ColorSequence.new(rgb(90, 200, 255), rgb(230, 250, 255)) }),
	})

	-- Barras finas encima de la de vida: el relleno se vacía desde la punta hacia la foto
	local bars: { [string]: { Track: Frame, Fill: Frame, Caption: TextLabel, Ratio: number } } = {}
	for _, def in BARS do
		local track = create("Frame", { Name = def.Id, Size = UDim2.fromOffset(def.Width, def.Height), BackgroundColor3 = TRACK, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 2, Parent = status }, {
			Theme.corner(2),
			create("UIStroke", { Color = rgb(4, 8, 16), Thickness = 1.5 }),
		})
		local fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = track }, {
			Theme.corner(2),
			create("UIGradient", { Rotation = 90, Color = ColorSequence.new(def.To, def.From) }),
		})
		local caption = Theme.label({ Size = UDim2.fromOffset(52, 12), Font = Theme.FontBold, TextSize = 11, TextStrokeTransparency = 0.3, ZIndex = 4, Parent = status })
		bars[def.Id] = { Track = track, Fill = fill, Caption = caption, Ratio = -1 }
	end

	-- Vida: cuánto camino (aro + barra) está lleno; se anima con un NumberValue
	local healthRatio = 1
	local shown = create("NumberValue", { Value = 1 })
	local function paintHealth()
		local ratio = shown.Value
		local colors = if healthRatio > 0.5 then HEALTH_GREEN elseif healthRatio > 0.25 then HEALTH_YELLOW else HEALTH_RED
		local filled = ratio * (ARC_LEN + HEALTH_LEN)
		for i, seg in segs do
			local at = (i - 0.5) / SEGMENTS * ARC_LEN
			seg.BackgroundColor3 = if at <= filled then colors[1]:Lerp(colors[2], 0.35) else TRACK
		end
		healthGradient.Color = ColorSequence.new(colors[2], colors[1])
		healthFill.Size = UDim2.fromScale(math.clamp((filled - ARC_LEN) / HEALTH_LEN, 0, 1), 1)
	end
	shown.Changed:Connect(paintHealth)

	local function setBar(id: string, amount: number, max: number)
		local ratio = math.clamp(amount / math.max(max, 1), 0, 1)
		if id == "Health" then
			setText(healthCaption, "❤ " .. tostring(math.floor(amount + 0.5)))
			healthRatio = ratio
			TweenService:Create(shown, TweenInfo.new(0.35), { Value = ratio }):Play()
			paintHealth()
			return
		end
		local bar = bars[id]
		local def = nil
		for _, d in BARS do
			if d.Id == id then
				def = d
			end
		end
		setText(bar.Caption, (if def then def.Emoji .. " " else "") .. tostring(math.floor(amount + 0.5)))
		if math.abs(ratio - bar.Ratio) < 0.002 then
			return
		end
		bar.Ratio = ratio
		TweenService:Create(bar.Fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(ratio, 1) }):Play()
	end

	-- Colocar a un lado u otro: "Right" (la foto a la derecha y las barras hacia la izquierda) o "Left"
	arrangeStatus = function(side: string)
		local right = side == "Right"
		local align = if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		-- Todo se piensa con la foto a la izquierda; a la derecha se refleja
		local function x(value: number): number
			return if right then STATUS_W - value else value
		end
		-- object se coloca con su lado cercano a la foto en fromX (y su borde superior en y)
		local function place(object: GuiObject, fromX: number, y: number)
			object.AnchorPoint = Vector2.new(if right then 1 else 0, 0)
			object.Position = UDim2.fromOffset(x(fromX), y)
		end
		local cx, cy = CENTER.X, CENTER.Y
		ring.Position = UDim2.fromOffset(x(cx), cy)
		for i = 1, SEGMENTS do
			local degrees = ARC_FROM + (ARC_TO - ARC_FROM) * (i - 0.5) / SEGMENTS
			if not right then
				degrees = 180 - degrees -- reflejado: rodea por la izquierda
			end
			local a = math.rad(degrees)
			local px, py = CENTER.X + math.cos(a) * RING_R, cy + math.sin(a) * RING_R
			if right then
				px = STATUS_W - CENTER.X + math.cos(a) * RING_R
			end
			for _, piece in { rim[i], segs[i] } do
				piece.Position = UDim2.fromOffset(px, py)
				piece.Rotation = degrees + 90
			end
		end
		local barY = cy + RING_R - RING_T / 2
		place(healthTrack, cx, barY)
		-- La vida se vacía desde la punta lejana: el relleno va pegado a la foto
		healthFill.AnchorPoint = Vector2.new(if right then 1 else 0, 0)
		healthFill.Position = UDim2.fromScale(if right then 1 else 0, 0)
		place(healthCaption, cx + HEALTH_LEN + 4, barY - 2)
		healthCaption.TextXAlignment = align

		local lane = OUTER * 2 + 12 -- el texto de arriba empieza pasado el aro
		place(name, lane, 2)
		name.TextXAlignment = align
		place(money, lane, 24)
		money.TextXAlignment = align
		place(xpTrack, lane, 48)
		place(xpText, lane + 156, 43)
		xpText.TextXAlignment = align
		xpFill.AnchorPoint = Vector2.new(if right then 1 else 0, 0)
		xpFill.Position = UDim2.fromScale(if right then 1 else 0, 0)

		local y = barY - 4
		local from = cx + PORTRAIT / 2 * 0.55 -- salen de debajo de la foto
		for _, def in BARS do
			local bar = bars[def.Id]
			y -= def.Height + 4
			place(bar.Track, from, y)
			bar.Fill.AnchorPoint = Vector2.new(if right then 1 else 0, 0)
			bar.Fill.Position = UDim2.fromScale(if right then 1 else 0, 0)
			place(bar.Caption, from + def.Width + 4, y + def.Height / 2 - 6)
			bar.Caption.TextXAlignment = align
		end
	end
	arrangeStatus("Right")
	paintHealth()

	local function progress()
		local level = player:GetAttribute("Level") or 1
		local points = player:GetAttribute("StatPoints") or 0
		setText(levelText, ("Nv %d%s"):format(level, if points > 0 then " +" else ""))
		local xp, need = player:GetAttribute("Xp") or 0, player:GetAttribute("XpNext") or 100
		TweenService:Create(xpFill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(xp / math.max(need, 1), 0, 1), 1) }):Play()
		setText(xpText, ("XP %d%%"):format(math.floor(math.clamp(xp / math.max(need, 1), 0, 1) * 100)))
		local tickets = player:GetAttribute("Tickets") or 0
		setText(money, Format.money(player:GetAttribute("Money") or 0) .. (if tickets > 0 then ("  🎟 %d"):format(tickets) else ""))
	end
	for _, attribute in { "Level", "StatPoints", "Xp", "XpNext", "Money", "Tickets" } do
		player:GetAttributeChangedSignal(attribute):Connect(progress)
	end
	progress()

	local healthConnections: { RBXScriptConnection } = {}
	local function watchHumanoid(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		for _, connection in healthConnections do
			connection:Disconnect()
		end
		local function update()
			setBar("Health", humanoid.Health, humanoid.MaxHealth)
		end
		healthConnections = { humanoid.HealthChanged:Connect(update), humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update) }
		update()
	end
	player.CharacterAdded:Connect(watchHumanoid)
	if player.Character then
		task.spawn(watchHumanoid, player.Character)
	end
	local function needs()
		setBar("Energy", player:GetAttribute("Energy") or Config.Needs.Max, Config.Needs.Max)
		setBar("Hunger", player:GetAttribute("Hunger") or Config.Needs.Max, Config.Needs.Max)
		local max = player:GetAttribute("MaxStamina") or Gameplay.Progression.Stamina.Base
		setBar("Stamina", player:GetAttribute("Stamina") or max, max)
	end
	for _, attribute in { "Energy", "Hunger", "Stamina", "MaxStamina" } do
		player:GetAttributeChangedSignal(attribute):Connect(needs)
	end
	needs()
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
local refreshVisible: () -> () -- se define más abajo
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

-- Cabecera de sección: pestaña de color con el título en cursiva
local function section(parent: Instance, order: number, emoji: string, title: string, color: Color3)
	local header = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	tab(header, emoji .. "  " .. string.upper(title), color)
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
		local titleBox = create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0.25, BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = objectivesList }, {
			Theme.corner(5),
			create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(90, 110, 150)), Transparency = NumberSequence.new(0, 0.6) }),
		})
		Theme.title({ Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), Text = title, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Parent = titleBox })
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
		if not objectivesPanel.Visible and title ~= "" then
			questPending = true
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
	local jobTitle = Theme.title({ Size = UDim2.new(1, 0, 0, 22), TextSize = 16, TextColor3 = C.Accent, LayoutOrder = 1, Parent = jobBox })
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
		questPending = false
	end
end

---------------------------------------------------------------------
-- Al llegar a un sitio: su nombre en grande (como al entrar en un mundo de KH3)
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

local function buildAreaBanner(parent: Instance)
	local banner = create("CanvasGroup", {
		Name = "AreaBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(640, 86),
		Position = UDim2.new(0.5, 0, 0, 150),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = parent,
	})
	local title = Theme.title({ Size = UDim2.new(1, 0, 0, 46), TextSize = 40, TextStrokeTransparency = 0.3, TextStrokeColor3 = C.Ink, TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })
	-- Línea que se desvanece por los lados, debajo del nombre
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0.9, 0, 0, 2), Position = UDim2.new(0.5, 0, 0, 52), BackgroundColor3 = C.Highlight, BorderSizePixel = 0, Parent = banner }, {
		create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	local sub = Theme.label({ Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 58), FontFace = Theme.ItalicFace, TextSize = 17, TextColor3 = C.Highlight, TextStrokeTransparency = 0.5, TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })

	local showing = 0
	local function show(text: string, subtitle: string)
		showing += 1
		local id = showing
		title.Text = text
		sub.Text = subtitle
		banner.Visible = true
		banner.Position = UDim2.new(0.5, 0, 0, 162)
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0, 150) }):Play()
		task.delay(3, function()
			if showing ~= id then
				return
			end
			local out = TweenService:Create(banner, TweenInfo.new(0.8), { GroupTransparency = 1 })
			out:Play()
			out.Completed:Wait()
			if showing == id then
				banner.Visible = false
			end
		end)
	end

	-- Dónde estás: una vez por segundo. El cartel sale cuando cambias de sitio y llevas ahí un
	-- par de segundos (así no parpadea si andas justo por el borde entre dos barrios).
	local shown, pending, stable = "", "", 0
	task.spawn(function()
		while true do
			task.wait(1)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root or busy then
				continue
			end
			local position = root.Position
			-- Título: el barrio (si estás cerca de uno); debajo, el distrito
			local zone, zoneDistance = nearestZone(position)
			local district = MapInfo.districtAt(position.X, position.Z)
			local districtName = if district then district.Name else "Naturaleza de Valmar"
			local near = zone ~= nil and zoneDistance < 650
			local t = if near then zone :: string else districtName
			local s = if near then districtName else (if district then district.Theme else "Montes y costa")
			local homeId = player:GetAttribute("FamilyHomeId")
			local found = false
			for _, room in CollectionService:GetTagged("Room") do
				if inside(room, position) then
					local mine = homeId ~= nil and room:GetAttribute("HomeId") == homeId
					t, s, found = if mine then "Tu casa" else "Casa", ROOM_NAMES[room:GetAttribute("Room")] or "Zona residencial", true
					break
				end
			end
			if not found then
				for _, area in CollectionService:GetTagged("StoryArea") do
					local names = AREA_NAMES[area:GetAttribute("AreaId")]
					if names and inside(area, position) then
						t, s, found = names[1], names[2], true
						break
					end
				end
			end
			if not found then
				for _, classroom in CollectionService:GetTagged("Classroom") do
					if inside(classroom, position) then
						t, s = "Colegio", "Aula"
						break
					end
				end
			end
			if t ~= pending then
				pending, stable = t, 0
			else
				stable += 1
			end
			if stable == 2 and t ~= shown then
				shown = t
				show(t, s)
			end
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
	-- El aviso entra deslizándose desde arriba y se va desvaneciendo
	local slot = create("Frame", { Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = toastList })
	local toast = create("CanvasGroup", {
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(0, -14),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.12,
		GroupTransparency = 1,
		Parent = slot,
	}, { Theme.corner(6), create("UIGradient", { Rotation = 90, Color = Theme.Sheen }) })
	local stroke = Theme.stroke(0.2)
	stroke.Color = color
	stroke.Parent = toast
	create("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 14), Parent = toast })
	-- Franja de color a la izquierda
	create("Frame", { Size = UDim2.new(0, 4, 1, -12), Position = UDim2.fromOffset(-12, 6), BackgroundColor3 = color, BorderSizePixel = 0, Parent = toast }, { Theme.corner(2) })
	Theme.label({
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = text,
		FontFace = Theme.ItalicFace,
		TextColor3 = C.Text,
		Parent = toast,
	})
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }):Play()
	task.delay(3, function()
		local fadeOut = TweenService:Create(toast, TweenInfo.new(0.4), { GroupTransparency = 1 })
		fadeOut:Play()
		fadeOut.Completed:Wait()
		slot:Destroy()
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

-- De bebé casi todo sobra (solo la hora); en conversaciones y cinemáticas, los comandos y tu estado
-- se apartan para dejar ver la escena (como en KH3)
function refreshVisible()
	if not gui then
		return
	end
	local show = not busy and player:GetAttribute("LifeStage") ~= "Bebe"
	for _, name in { "Status" } do
		local element = gui:FindFirstChild(name)
		if element then
			element.Visible = show
		end
	end
end

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
	buildStatus(gui)
	buildObjectives(gui)
	buildAreaBanner(gui)
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

	-- Colocación según la pantalla:
	--   * ordenador: comandos abajo a la izquierda, tu estado abajo a la derecha y los objetivos a la
	--     izquierda, debajo de la barra de Roblox
	--   * táctil: abajo están el joystick y los botones, así que tu estado sube arriba a la izquierda
	--     (al revés: la foto a la izquierda) y los objetivos van debajo
	local objectivesLimit = create("UISizeConstraint", { Parent = objectivesPanel })
	objectivesPanel.ClipsDescendants = true
	local function layout()
		local s = scale.Scale
		local canvas = camera.ViewportSize / s
		local inset = GuiService:GetGuiInset()
		local top = math.max(72, inset.Y / s + 8)
		local clock = gui:FindFirstChild("Clock") :: Frame
		clock.Size = UDim2.fromOffset(if canvas.X < 1500 then 400 else 440, 54)
		local y = top
		if TOUCH then
			status.AnchorPoint = Vector2.new(0, 0)
			status.Position = UDim2.fromOffset(8, top)
			arrangeStatus("Left")
			y = top + STATUS_H + 12
		else
			status.AnchorPoint = Vector2.new(1, 1)
			status.Position = UDim2.new(1, -18, 1, -16)
			arrangeStatus("Right")
		end
		objectivesPanel.Position = UDim2.fromOffset(12, y)
		-- Los objetivos no bajan hasta el menú de comandos (abajo a la izquierda)
		local room = canvas.Y - y - (if TOUCH then 420 else 300)
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
		Position = UDim2.new(0.5, 0, 0, 112),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	create("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastList })

	-- La pantalla negra de dormir va en su propio ScreenGui (sin UIScale) para cubrirlo todo
	local overlayGui = create("ScreenGui", { Name = "SleepOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, Parent = gui.Parent })
	sleepOverlay = create("Frame", { Name = "Sleep", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false, Parent = overlayGui })
	Theme.title({ Name = "Caption", Size = UDim2.fromScale(1, 1), Text = "Zzz...", TextSize = 40, TextXAlignment = Enum.TextXAlignment.Center, Parent = sleepOverlay })

	player:GetAttributeChangedSignal("LifeStage"):Connect(refreshVisible)
	refreshVisible()

	return gui
end

-- Mientras hablas con alguien o ves una cinemática, los objetivos no tapan la escena
function Hud.setBusy(value: boolean)
	busy = value
	refreshVisible()
	if objectivesPanel then
		objectivesPanel.Visible = objectivesWanted and not busy
	end
end

return Hud
