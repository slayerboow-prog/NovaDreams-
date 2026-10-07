-- Hud: la interfaz principal del juego.
--
--   Arriba a la izquierda  -> tu estado: la foto en un aro brillante con la corona de nivel, tu nombre,
--                             nivel y dinero, la experiencia y las barras de Energía, Hambre, Ánimo
--                             (o Estamina) y Salud con su número
--   Arriba en el centro    -> cápsula con la hora, la fecha, el día de tu historia y el tiempo (°C)
--   Arriba a la derecha    -> minimapa (MapUI), pegado a la esquina
--   Derecha                -> la misión que sigues (o tu trabajo, o el encargo de la ciudad que has
--                             aceptado: atributo CityErrand), justo debajo del minimapa; › abre la
--                             lista de misiones
--   Abajo                  -> el ValPhone asomando a la izquierda (UI/Phone: el menú del juego son sus
--                             apps), barra rápida (InventoryUI), los botones táctiles (UI/TouchLayout)
--                             y la tira de acciones de ahora junto a ellos (Commands/ContextStrip)
--   Las apps (Ir a casa, Ruta a casa, Tienda, Vehículos, Gestos, Metro, Mercadillo, Guía de pesca…)
--   son apps del ValPhone (Hud.addButton); las opciones del menú (música, sonidos, ropa, GPS,
--   Gráficos…) salen en su app Ajustes (Hud.addMenuToggle).
--   Al llegar a un sitio nuevo, su nombre aparece en grande. Avisos arriba y pantalla negra para dormir.
-- Dónde va cada cosa lo calcula UI/HudLayout (así nada se pisa en ningún tamaño de pantalla).
-- Otros sistemas se enganchan con Hud.setAction (comandos) y Hud.addButton (apps del ValPhone).

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
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
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local HudLayout = require(script.Parent.HudLayout)
local TouchLayout = require(script.Parent.TouchLayout)
local Dialog = require(script.Parent.Dialog)
local CommandRegistry = require(script.Parent.Parent.Commands.CommandRegistry)

local create = Theme.create
local setText = Theme.setText
local C = Theme.Colors
local H = Theme.Hud
local rgb = Color3.fromRGB

local Hud = {}

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Pantalla táctil sin teclado (móvil o tableta)
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local gui: ScreenGui
local popupGui: ScreenGui -- menú, controles y misiones: por encima del minimapa
local toastList: Frame
-- Avisos y cartel de zona van debajo de las estrellas de búsqueda (HudLayout.Items.Toasts);
-- mientras sale el cartel de zona, los avisos bajan para no quedar debajo de él.
local toastTop = 240
local BANNER_ROOM = 96
local bannerOn = false
-- Con un arma en la mano los avisos suben (justo debajo del reloj y el GPS), salen más pequeños y como
-- mucho dos: nunca tapan la mira del centro
local armedToastTop = 140
local function armedNow(): boolean
	return Players.LocalPlayer:GetAttribute("Weapon") ~= nil
end
local function placeToasts()
	if toastList then
		local armed = armedNow()
		local top = if armed then armedToastTop else toastTop + (if bannerOn then BANNER_ROOM else 0)
		toastList.Position = UDim2.new(0.5, 0, 0, top)
		local small = toastList:FindFirstChild("ArmedScale") :: UIScale?
		if small then
			small.Scale = if armed then 0.8 else 1
		end
	end
end
local sleepOverlay: Frame
local actions: { [string]: () -> () } = {}
local questTitleShown = ""
local busy = false -- en una conversación o cinemática
local refreshVisible: () -> () -- se define más abajo

local WEEKDAYS = { "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo" }
local MONTHS = { "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre" }

---------------------------------------------------------------------
-- Arriba en el centro: cápsula de la hora, la fecha y el tiempo
---------------------------------------------------------------------
local function separator(parent: Instance, x: number)
	create("Frame", {
		Size = UDim2.fromOffset(2, 40),
		Position = UDim2.fromOffset(x, 12),
		BackgroundColor3 = H.Glow,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = parent,
	}, {
		create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
		}),
	})
end

local function buildClock(parent: Instance)
	local panel = Theme.hudPanel({ Name = "Clock", CornerRadius = 32, Parent = parent })
	Theme.bevel(panel)
	local sun = Icons.new("sol", { Name = "Sky", Position = UDim2.fromOffset(18, 12), Size = UDim2.fromOffset(40, 40), Parent = panel })
	local time = Theme.title({ Name = "Time", Size = UDim2.fromOffset(112, 64), Position = UDim2.fromOffset(64, 0), TextSize = 36, TextStrokeTransparency = 0.6, Parent = panel })
	separator(panel, 180)
	local date = Theme.label({ Name = "Date", Size = UDim2.fromOffset(226, 24), Position = UDim2.fromOffset(194, 9), FontFace = Theme.ItalicFace, TextSize = 19, TextColor3 = H.SelectLight, Parent = panel })
	local sub = Theme.label({ Name = "Day", Size = UDim2.fromOffset(226, 20), Position = UDim2.fromOffset(194, 34), TextSize = 15, TextColor3 = C.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	separator(panel, 428)
	local weatherIcon = Icons.new("sol", { Name = "WeatherIcon", Position = UDim2.fromOffset(440, 13), Size = UDim2.fromOffset(38, 38), Parent = panel })
	local temp = Theme.label({ Name = "Temp", Size = UDim2.fromOffset(110, 26), Position = UDim2.fromOffset(484, 8), Font = Theme.FontBold, TextSize = 21, Parent = panel })
	local weatherName = Theme.label({ Name = "Weather", Size = UDim2.fromOffset(110, 20), Position = UDim2.fromOffset(484, 34), TextSize = 15, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })

	local shownMinute, shownHour = -1, -1
	local function updateWeather()
		local weather = workspace:GetAttribute("Weather") or "Despejado"
		local season = workspace:GetAttribute("Season") or "Primavera"
		local info = Seasons.Weather[weather]
		local clock = Lighting.ClockTime
		local night = clock < 6.5 or clock >= 20
		-- De noche y despejado: la luna en vez del sol
		local iconName = Icons.Weather[weather] or "sol"
		if iconName == "sol" and night then
			iconName = "luna"
		end
		Icons.set(weatherIcon, iconName)
		setText(temp, ("%d°C"):format(Seasons.temperature(season, weather, clock)))
		setText(weatherName, if info then info.Name else weather)
	end
	local function tick()
		local clock = Lighting.ClockTime
		local minute = math.floor(clock * 60)
		if minute == shownMinute then
			return -- ClockTime cambia cada fotograma: solo se reescribe al cambiar el minuto
		end
		shownMinute = minute
		local day = clock >= 6.5 and clock < 20
		Icons.set(sun, if day then "sol" else "luna")
		setText(time, Format.clock(clock))
		local now = GameClock.now()
		setText(date, ("%s, %d de %s"):format(WEEKDAYS[now.Weekday] or "", now.DayOfMonth, MONTHS[now.Month] or ""))
		-- (el día de TU vida, que se guarda con la partida: CalendarService; si aún no ha llegado, el del mundo)
		local lifeDay = player:GetAttribute("LifeDay")
		local dayNumber = if type(lifeDay) == "number" and lifeDay >= 1 then lifeDay else now.Day
		setText(sub, "Día " .. tostring(dayNumber) .. (if questTitleShown ~= "" then " · " .. questTitleShown else ""))
		local hour = math.floor(clock)
		if hour ~= shownHour then
			shownHour = hour
			updateWeather()
		end
	end
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(tick)
	for _, attribute in { "Weather", "Season", "Day" } do
		workspace:GetAttributeChangedSignal(attribute):Connect(function()
			shownMinute = -1
			shownHour = -1
			tick()
		end)
	end
	player:GetAttributeChangedSignal("LifeDay"):Connect(function()
		shownMinute = -1
		tick()
	end)
	tick()
	-- (por si el reloj del juego avanza sin cambiar ClockTime: un repaso cada pocos segundos)
	task.spawn(function()
		while panel.Parent do
			task.wait(5)
			shownMinute = -1
			tick()
		end
	end)
end

---------------------------------------------------------------------
-- Comandos (Mochila, Personaje, Mapa, Misiones, Menú): los usan las apps del ValPhone
---------------------------------------------------------------------
local questPending = false

function Hud.runCommand(id: string)
	local action = actions[id]
	if action then
		action()
	end
end

-- ¿Hay una misión nueva sin mirar? (el ValPhone pone un punto rojo en la app Misiones)
function Hud.questPending(): boolean
	return questPending
end

---------------------------------------------------------------------
-- Arriba a la izquierda: tu estado
---------------------------------------------------------------------
local PORTRAIT = 120
local TEXT_X = 142
local BAR_W = 206
local BARS = {
	-- Id, icono, colores del degradado (de izquierda a derecha)
	{ Id = "Energy", Icon = "rayo", From = rgb(40, 150, 255), To = rgb(120, 235, 255) },
	{ Id = "Hunger", Icon = "comida", From = rgb(70, 210, 120), To = rgb(235, 225, 70) },
	{ Id = "Mood", Icon = "cara", From = rgb(255, 150, 40), To = rgb(255, 225, 90) },
	{ Id = "Health", Icon = "corazon", From = rgb(255, 60, 150), To = rgb(255, 150, 200) },
}

local status: Frame

local function floatText(parent: GuiObject, text: string, color: Color3, position: UDim2)
	local label = Theme.label({
		Position = position,
		Size = UDim2.fromOffset(120, 22),
		Text = text,
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = color,
		TextStrokeTransparency = 0.3,
		ZIndex = 8,
		Parent = parent,
	})
	TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = position - UDim2.fromOffset(0, 26),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(1, function()
		label:Destroy()
	end)
end

local function buildStatus(parent: Instance)
	status = create("Frame", { Name = "Status", BackgroundTransparency = 1, Parent = parent })
	-- Fondo oscuro detrás del texto, que se desvanece hacia la derecha (no es una tarjeta)
	create("Frame", {
		Name = "Plate",
		Position = UDim2.fromOffset(60, 8),
		Size = UDim2.new(1, -60, 1, -12),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = status,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.25), NumberSequenceKeypoint.new(1, 1) }),
		}),
	})

	-- Foto en un aro brillante
	local ring = create("Frame", {
		Name = "Portrait",
		Position = UDim2.fromOffset(6, 12),
		Size = UDim2.fromOffset(PORTRAIT, PORTRAIT),
		BackgroundColor3 = H.NavyLight,
		ZIndex = 3,
		Parent = status,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(90, 160, 255), rgb(20, 40, 90)) }),
	})
	local ringStroke = Theme.edge(ring, nil, 5)
	Theme.halo(ring, H.Glow, 12, 999)
	local photo = create("ImageLabel", {
		Name = "Photo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = ring,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then
			photo.Image = image
		end
	end)
	-- Insignia de nivel: la corona arriba del aro
	local badge = create("Frame", {
		Name = "LevelBadge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = H.Navy,
		ZIndex = 6,
		Parent = ring,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.edge(badge, H.Gold, 2)
	Icons.new("corona", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), ZIndex = 7, Parent = badge })

	local name = Theme.title({ Name = "Name", Position = UDim2.fromOffset(TEXT_X, 10), Size = UDim2.fromOffset(290, 28), Text = player.DisplayName, TextSize = 24, TextStrokeTransparency = 0.5, TextTruncate = Enum.TextTruncate.AtEnd, Parent = status })
	-- De servicio en una institución: el rango junto al nombre ("Ana · Sargento")
	local function nameText()
		local rank = player:GetAttribute("Rank")
		setText(name, if rank then ("%s · %s"):format(player.DisplayName, rank) else player.DisplayName)
	end
	player:GetAttributeChangedSignal("Rank"):Connect(nameText)
	nameText()
	local levelText = Theme.label({ Name = "Level", Position = UDim2.fromOffset(TEXT_X, 38), Size = UDim2.fromOffset(84, 22), Font = Theme.FontBold, TextSize = 18, TextStrokeTransparency = 0.5, Parent = status })
	local money = Theme.label({ Name = "Money", Position = UDim2.fromOffset(TEXT_X + 90, 38), Size = UDim2.fromOffset(200, 22), Font = Theme.FontBold, TextSize = 18, TextColor3 = C.Money, TextStrokeTransparency = 0.5, Parent = status })
	local xpTrack = create("Frame", {
		Name = "XpBar",
		Position = UDim2.fromOffset(TEXT_X, 66),
		Size = UDim2.fromOffset(BAR_W - 20, 10),
		BackgroundColor3 = H.Track,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = status,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIStroke", { Color = H.Edge, Transparency = 0.6 }) })
	local xpFill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = xpTrack }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Color = ColorSequence.new(rgb(40, 110, 255), rgb(120, 225, 255)) }),
	})
	local xpText = Theme.label({ Name = "Xp", Position = UDim2.fromOffset(TEXT_X + BAR_W - 14, 60), Size = UDim2.fromOffset(110, 20), Font = Theme.FontBold, TextSize = 14, TextColor3 = C.Muted, TextStrokeTransparency = 0.6, Parent = status })

	-- Barras con icono y número
	local bars: { [string]: { Track: Frame, Fill: Frame, Value: TextLabel, Icon: Frame, Ratio: number } } = {}
	for i, def in BARS do
		local y = 86 + (i - 1) * 19
		local icon = Icons.new(def.Icon, { Name = def.Id .. "Icon", Position = UDim2.fromOffset(TEXT_X, y), Size = UDim2.fromOffset(18, 18), Parent = status })
		local track = create("Frame", {
			Name = def.Id,
			Position = UDim2.fromOffset(TEXT_X + 24, y + 4),
			Size = UDim2.fromOffset(BAR_W, 10),
			BackgroundColor3 = H.Track,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Parent = status,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track }, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			create("UIGradient", { Color = ColorSequence.new(def.From, def.To) }),
		})
		local value = Theme.label({
			Name = def.Id .. "Value",
			Position = UDim2.fromOffset(TEXT_X + 24 + BAR_W + 4, y),
			Size = UDim2.fromOffset(52, 18),
			Font = Theme.FontBold,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextStrokeTransparency = 0.4,
			Parent = status,
		})
		bars[def.Id] = { Track = track, Fill = fill, Value = value, Icon = icon, Ratio = -1 }
	end

	local function setBar(id: string, amount: number, max: number)
		local bar = bars[id]
		local ratio = math.clamp(amount / math.max(max, 1), 0, 1)
		setText(bar.Value, tostring(math.floor(amount + 0.5)))
		if math.abs(ratio - bar.Ratio) < 0.002 then
			return
		end
		bar.Ratio = ratio
		TweenService:Create(bar.Fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(ratio, 1) }):Play()
	end

	local lastLevel = player:GetAttribute("Level") or 1
	local lastMoney = player:GetAttribute("Money")
	local function progress()
		local level = player:GetAttribute("Level") or 1
		local points = player:GetAttribute("StatPoints") or 0
		setText(levelText, ("Nv. %d%s"):format(level, if points > 0 then " +" else ""))
		local xp, need = player:GetAttribute("Xp") or 0, player:GetAttribute("XpNext") or 100
		TweenService:Create(xpFill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(xp / math.max(need, 1), 0, 1), 1) }):Play()
		setText(xpText, ("%d / %d XP"):format(xp, need))
		local tickets = player:GetAttribute("Tickets") or 0
		local cash = player:GetAttribute("Money") or 0
		setText(money, Format.money(cash) .. (if tickets > 0 then ("  🎟 %d"):format(tickets) else ""))
		-- Dinero que entra: el número da un salto y sube un "+50 €"
		if lastMoney ~= nil and cash ~= lastMoney then
			local diff = cash - lastMoney
			Theme.pop(money, if diff > 0 then 1.2 else 1.08)
			floatText(status, (if diff > 0 then "+" else "-") .. Format.money(math.abs(diff)), if diff > 0 then C.Money else C.Error, UDim2.fromOffset(TEXT_X + 90, 30))
		end
		lastMoney = cash
		-- Nivel nuevo: el aro se vuelve dorado un momento y la corona salta
		if level > lastLevel then
			Theme.pop(badge, 1.5)
			Theme.pop(ring, 1.08)
			ringStroke.Color = H.Gold
			TweenService:Create(ringStroke, TweenInfo.new(1.2), { Color = Color3.new(1, 1, 1) }):Play()
			floatText(status, ("¡Nivel %d!"):format(level), H.Gold, UDim2.fromOffset(TEXT_X, 10))
		end
		lastLevel = level
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
		-- Ánimo si el juego lo lleva; si no, la estamina (correr)
		local mood = player:GetAttribute("Mood")
		if typeof(mood) == "number" then
			Icons.set(bars.Mood.Icon, "cara")
			setBar("Mood", mood, player:GetAttribute("MaxMood") or Config.Needs.Max)
		else
			Icons.set(bars.Mood.Icon, "correr")
			local max = player:GetAttribute("MaxStamina") or Gameplay.Progression.Stamina.Base
			setBar("Mood", player:GetAttribute("Stamina") or max, max)
		end
	end
	for _, attribute in { "Energy", "Hunger", "Stamina", "MaxStamina", "Mood", "MaxMood" } do
		player:GetAttributeChangedSignal(attribute):Connect(needs)
	end
	needs()
end

---------------------------------------------------------------------
-- Derecha: la misión que sigues (y la lista completa en una ventana)
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
	resolved.abu = resolved.abu or Strings.get(player:GetAttribute("AbuKey") or "NPC.ABU_ROSA") -- (si no, salía «{abu}» tal cual)
	if resolved.subjectKey then
		resolved.subject = Strings.get(resolved.subjectKey)
	end
	if resolved.degreeKey then
		resolved.degree = Strings.get(resolved.degreeKey)
	end
	return Strings.get(key, resolved)
end

-- 7.5 -> "7:30"
local function hourText(hour: number): string
	local h = math.floor(hour)
	return ("%d:%02d"):format(h, math.floor((hour - h) * 60 + 0.5))
end

local mission: Frame
local missionParts: { [string]: any } = {}
local storyState: { [string]: any } = {}
local lastTracked: string? = nil
local hasMission = false
-- La ruta que has elegido tú (Controllers/Gps): la tarjeta se atenúa y enseña "📍 Ruta a …" con
-- «Seguir misión» en el sitio del título pequeño (dentro de la tarjeta: no pisa nada)
local routeChip: string? = nil
local routeCancel: (() -> ())? = nil

local function paintRouteChip()
	local parts = missionParts
	local chip = parts.Route
	if not chip then
		return
	end
	local on = routeChip ~= nil
	chip.Visible = on
	parts.Kind.Visible = not on
	if on then
		setText(parts.RouteText, routeChip :: string)
	end
	local fade = if on then 0.45 else 0
	parts.Title.TextTransparency = fade
	parts.Step.TextTransparency = fade
	parts.Count.TextTransparency = fade
end

-- El encargo de la ciudad que estás haciendo (CityErrandService lo manda en el atributo CityErrand)
local function errandState(): { [string]: any }?
	local raw = player:GetAttribute("CityErrand")
	if type(raw) ~= "string" then
		return nil
	end
	local ok, state = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(state) == "table" and type(state.Title) == "string" then state else nil
end

local function errandStep(errand: { [string]: any }): string
	local step = errand.Step or ""
	if type(errand.Left) == "number" then
		step ..= (" · ⏱ %d s"):format(errand.Left)
	end
	return step
end

local function abandonErrand()
	local remote = Remotes:FindFirstChild("CityErrand")
	if remote then
		(remote :: RemoteEvent):FireServer("Abandon")
	end
end

-- El contador: en un grupo, las que hacen falta (Need) y no todas las que hay; en un paso con
-- cuenta propia ("Trabaja (2/3)"), esa cuenta (antes salía 3/6 al acabar o 0/1 a medias)
local function countText(tracked: { [string]: any }, done: number, children: number): string
	if children > 0 then
		local need = if type(tracked.Need) == "number" and tracked.Need > 0 then math.min(tracked.Need, children) else children
		return ("%d/%d"):format(math.min(done, need), need)
	end
	local args = tracked.Args
	local count, total = type(args) == "table" and tonumber(args.count), type(args) == "table" and tonumber(args.total)
	if count and total and total > 0 then
		return ("%d/%d"):format(count, total)
	end
	return "0/1"
end

-- Lo que enseña el panel: título, nombre, paso actual y contador
local function missionSummary(state: { [string]: any }): { Kind: string, Title: string, Step: string, Count: string }?
	local tracked = state.Tracked
	if tracked then
		local children = tracked.Children or {}
		local step, done = "", 0
		for _, child in children do
			if child.Done then
				done += 1
			elseif step == "" then
				step = storyText(child.TextKey, child.Args)
			end
		end
		if #children == 0 then
			step = storyText(tracked.TextKey, tracked.Args)
		end
		if tracked.Closed then
			step = ("%s está cerrado · abre a las %s"):format(tracked.Closed.Name, hourText(tracked.Closed.From))
		end
		return {
			Kind = if tracked.Kind == "Side" then "MISIÓN OPCIONAL" else "MISIÓN PRINCIPAL",
			Title = Strings.get(tracked.TitleKey),
			Step = step,
			Count = countText(tracked, done, #children),
		}
	elseif state.Waiting then
		local waiting = state.Waiting
		return {
			Kind = "MISIÓN PRINCIPAL",
			Title = Strings.get(waiting.TitleKey),
			Step = if waiting.Reason == "Hours" and waiting.From then ("Empieza a las %s"):format(hourText(waiting.From)) else Strings.get("STORY.WAIT.DAYS"),
			Count = "0/1",
		}
	end
	return nil
end

local function paintMission()
	if not mission then
		return
	end
	local jobId = player:GetAttribute("Job")
	local job = jobId and (Config.Jobs[jobId] or Gameplay.Jobs[jobId])
	local parts = missionParts
	if job then
		-- Trabajando: lo que importa es la tarea del trabajo
		setText(parts.Kind, "TRABAJO · " .. Format.money(job.Pay))
		parts.Kind.TextColor3 = H.SelectLight
		setText(parts.Title, "💼 " .. job.DisplayName)
		setText(parts.Step, player:GetAttribute("TaskText") or "")
		parts.Count.Visible = false
		parts.Quit.Visible = true
		hasMission = true
	elseif errandState() then
		-- Un encargo de la ciudad: lo que te han pedido, la paga y el botón para dejarlo
		local errand = errandState() :: { [string]: any }
		setText(parts.Kind, ("ENCARGO · %s · %d XP"):format(Format.money(errand.Money or 0), errand.Xp or 0))
		parts.Kind.TextColor3 = rgb(80, 210, 255)
		setText(parts.Title, "🧺 " .. errand.Title)
		setText(parts.Step, errandStep(errand))
		parts.Count.Visible = false
		parts.Quit.Visible = true
		hasMission = true
	else
		parts.Quit.Visible = false
		parts.Count.Visible = true
		parts.Kind.TextColor3 = H.Gold
		local summary = missionSummary(storyState)
		hasMission = summary ~= nil
		if summary then
			setText(parts.Kind, summary.Kind)
			setText(parts.Title, summary.Title)
			setText(parts.Step, summary.Step)
			setText(parts.Count, summary.Count)
		end
	end
	parts.Pending.Visible = questPending
	paintRouteChip()
	refreshVisible()
end

-- Lista completa (ventana): objetivo principal con sus pasos, opcionales (pulsa uno para seguirlo) y trabajo
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

local function section(parent: Instance, order: number, title: string, color: Color3)
	local header = create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	Icons.diamond({ Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(16, 16), Color = color, Parent = header })
	Theme.title({ Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -24, 1, 0), Text = string.upper(title), TextSize = 15, TextColor3 = color, Parent = header })
end

local function renderQuestList(list: Frame, state: { [string]: any })
	for _, child in list:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	-- El encargo de la ciudad que has aceptado (con su botón para dejarlo)
	local errand = errandState()
	if errand then
		section(list, nextOrder(), "Encargo de la ciudad", rgb(80, 210, 255))
		Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = "🧺 " .. errand.Title, TextSize = 18, LayoutOrder = nextOrder(), Parent = list })
		objectiveRow(list, nextOrder(), errandStep(errand), false, true)
		objectiveRow(list, nextOrder(), ("Te lo ha pedido %s · %s y %d XP"):format(errand.Giver or "alguien", Format.money(errand.Money or 0), errand.Xp or 0), false)
		local drop = Theme.button({ Size = UDim2.fromOffset(170, 32), Text = "Dejar el encargo", TextSize = 14, BackgroundColor3 = rgb(140, 40, 50), LayoutOrder = nextOrder(), Parent = list })
		drop.Activated:Connect(abandonErrand)
	end
	local tracked = state.Tracked
	if tracked then
		section(list, nextOrder(), if tracked.Kind == "Side" then "Misión opcional" else "Misión principal", H.Gold)
		Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = Strings.get(tracked.TitleKey), TextSize = 18, LayoutOrder = nextOrder(), Parent = list })
		if tracked.Closed then
			objectiveRow(list, nextOrder(), ("🌙 %s está cerrado · abre a las %s"):format(tracked.Closed.Name, hourText(tracked.Closed.From)), false, true)
			objectiveRow(list, nextOrder(), "💤 Puedes dormir en tu cama para que pase antes el tiempo", false)
		end
		local children = tracked.Children or {}
		if #children > 0 then
			local firstPending = true
			for _, child in children do
				objectiveRow(list, nextOrder(), storyText(child.TextKey, child.Args), child.Done, not child.Done and firstPending)
				if not child.Done then
					firstPending = false
				end
			end
		else
			objectiveRow(list, nextOrder(), storyText(tracked.TextKey, tracked.Args), false, true)
		end
	elseif state.Waiting then
		local waiting = state.Waiting
		section(list, nextOrder(), "Misión principal", H.Gold)
		objectiveRow(list, nextOrder(), Strings.get(waiting.TitleKey), false, true)
		objectiveRow(list, nextOrder(), if waiting.Reason == "Hours" and waiting.From then ("🕗 Empieza a las %s (ahora está cerrado)"):format(hourText(waiting.From)) elseif waiting.Reason == "Hours" then "Podrás seguir más tarde." else Strings.get("STORY.WAIT.DAYS"), false)
		if waiting.Reason == "Hours" then
			objectiveRow(list, nextOrder(), "💤 Puedes dormir en tu cama para que pase antes el tiempo", false)
		end
	end
	-- La principal (si juegas una opcional) va en su propio apartado, no entre las opcionales
	local others, mains = {}, {}
	for _, other in state.Others or {} do
		table.insert(if other.Kind == "Main" then mains else others, other)
	end
	for _, main in mains do
		section(list, nextOrder(), "Misión principal (en pausa)", H.Gold)
		-- «toca para volver» solo si de verdad se puede tocar; si no, el porqué (como las opcionales)
		local canPick = main.QuestId ~= nil and not main.Later
		local suffix = if canPick then "  · toca para volver a ella" elseif main.Later == "AfterSchool" then "  · 🏫 después del cole" elseif main.Later == "School" then "  · 🏫 en horario de cole" else ""
		local row = objectiveRow(list, nextOrder(), Strings.get(main.TitleKey) .. suffix, false)
		if canPick then
			local pick = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = row })
			pick.Activated:Connect(function()
				(Remotes:WaitForChild("LifeStory") :: RemoteEvent):FireServer("Track", main.QuestId)
			end)
		end
	end
	if #others > 0 then
		section(list, nextOrder(), "Misiones opcionales", C.Purple)
		for i = 1, math.min(6, #others) do
			local other = others[i]
			-- Las que no tocan ahora siguen en la lista, con el porqué (no han desaparecido)
			local later = if other.Later == "AfterSchool" then "  · 🏫 después del cole" elseif other.Later == "School" then "  · 🏫 en horario de cole" else ""
			local row = objectiveRow(list, nextOrder(), Strings.get(other.TitleKey) .. later, false)
			-- Pulsar una opcional la convierte en la que sigues
			if other.QuestId and not other.Later then
				local pick = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = row })
				pick.Activated:Connect(function()
					(Remotes:WaitForChild("LifeStory") :: RemoteEvent):FireServer("Track", other.QuestId)
				end)
			end
		end
	end
	if order == 0 then
		objectiveRow(list, nextOrder(), "Ahora mismo no tienes ninguna misión.", false)
	end
end

local questWindow: Frame? = nil
local questList: Frame? = nil

-- Móvil: las ventanas del HUD (menú, controles, misiones) salían a la escala del HUD (0,4-0,5, texto de
-- 7 px): se agrandan hasta la de las ventanas de UI/Dialog sin salirse de la pantalla, y su ✖ mide
-- al menos ~36 px en pantalla.
local function touchPopup(panel: GuiObject, close: GuiObject?)
	if not TOUCH then
		return
	end
	local camera = workspace.CurrentCamera
	local closeSide = if close then close.Size.X.Offset else 0
	local function apply()
		local view = camera.ViewportSize
		local hud = HudLayout.scaleFor(view)
		local size = panel.Size
		local want = math.min(Dialog.baseScale(), (view.Y - 60) / math.max(size.Y.Offset, 1), (view.X - 24) / math.max(size.X.Offset, 1))
		local k = math.max(1, want / hud)
		Theme.setBaseScale(panel, k)
		if close then
			local side = math.max(closeSide, math.ceil(36 / (hud * k)))
			close.Size = UDim2.fromOffset(side, side)
			-- (el aspa crece con el botón)
			for _, icon in close:GetChildren() do
				if icon:IsA("Frame") then
					icon.Size = UDim2.fromScale(0.45, 0.45)
				end
			end
		end
	end
	local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
	panel.Destroying:Connect(function()
		connection:Disconnect()
	end)
	apply()
end

local function openQuests()
	questPending = false
	if questWindow and questWindow.Parent then
		questWindow:Destroy()
		questWindow = nil
		paintMission()
		return
	end
	-- Una sola ventana grande a la vez (menú, controles, tienda…)
	Dialog.closeOthers("Quests")
	local window = Theme.hudPanel({
		Name = "Quests",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 440),
		BackgroundTransparency = 0.12,
		ZIndex = 30,
		Parent = popupGui,
	})
	Theme.bevel(window)
	Icons.new("misiones", { Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(28, 28), Parent = window })
	Theme.title({ Position = UDim2.fromOffset(52, 10), Size = UDim2.new(1, -110, 0, 32), Text = "MISIONES", TextSize = 22, Parent = window })
	local close = create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = H.NavyLight, Text = "", Parent = window }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	Icons.plus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), Rotation = 45, Parent = close })
	close.Activated:Connect(openQuests)
	touchPopup(window, close)
	local scroll = create("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.new(1, -32, 1, -120),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = window,
	})
	local list = create("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = scroll })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	-- Trabajo actual: con su botón para dejarlo
	local jobRow = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -12), Size = UDim2.new(1, -32, 0, 50), BackgroundTransparency = 1, Parent = window })
	local jobText = Theme.label({ Size = UDim2.new(1, -160, 1, 0), TextSize = 14, TextWrapped = true, Parent = jobRow })
	local quit = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(150, 34), Text = "Dejar trabajo", TextSize = 14, BackgroundColor3 = rgb(140, 40, 50), Parent = jobRow })
	quit.Activated:Connect(function()
		(Remotes:WaitForChild("QuitJob") :: RemoteEvent):FireServer()
	end)
	local function paintJob()
		local jobId = player:GetAttribute("Job")
		local job = jobId and (Config.Jobs[jobId] or Gameplay.Jobs[jobId])
		jobRow.Visible = job ~= nil
		if job then
			jobText.Text = ("💼 %s · %s\n%s"):format(job.DisplayName, Format.money(job.Pay), player:GetAttribute("TaskText") or "")
		end
	end
	paintJob()
	-- Si coges o dejas un trabajo (o cambia la tarea) con la ventana abierta, la fila se actualiza.
	-- Las conexiones se cortan al cerrar la ventana.
	local jobConn = player:GetAttributeChangedSignal("Job"):Connect(paintJob)
	local taskConn = player:GetAttributeChangedSignal("TaskText"):Connect(paintJob)
	window.Destroying:Connect(function()
		jobConn:Disconnect()
		taskConn:Disconnect()
	end)
	questWindow = window
	questList = list
	renderQuestList(list, storyState)
	Theme.pop(window, 1.04)
	paintMission()
end

local function buildMission(parent: Instance)
	mission = Theme.hudPanel({ Name = "Mission", Parent = parent })
	Theme.bevel(mission, H.Gold)
	-- Filo dorado a la izquierda
	create("Frame", { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(0, 4, 1, -28), BackgroundColor3 = H.Gold, BorderSizePixel = 0, Parent = mission }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Icons.diamond({ Position = UDim2.fromOffset(16, 11), Size = UDim2.fromOffset(20, 20), Color = H.Gold, Parent = mission })
	local parts = missionParts
	parts.Kind = Theme.title({ Name = "Kind", Position = UDim2.fromOffset(44, 6), Size = UDim2.fromOffset(330, 28), Text = "MISIÓN PRINCIPAL", TextSize = 18, TextColor3 = H.Gold, TextStrokeTransparency = 0.6, Parent = mission })
	parts.Title = Theme.label({ Name = "Title", Position = UDim2.fromOffset(44, 34), Size = UDim2.fromOffset(340, 28), Font = Theme.FontBold, TextSize = 22, TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.6, Parent = mission })
	Icons.dot({ Position = UDim2.fromOffset(48, 79), Size = UDim2.fromOffset(7, 7), Parent = mission })
	parts.Step = Theme.label({ Name = "Step", Position = UDim2.fromOffset(62, 68), Size = UDim2.fromOffset(300, 28), TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.6, Parent = mission })
	parts.Count = Theme.label({ Name = "Count", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 68), Size = UDim2.fromOffset(60, 28), Font = Theme.FontBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Right, Parent = mission })
	parts.Quit = Theme.button({ Name = "Quit", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 68), Size = UDim2.fromOffset(78, 30), Text = "Dejar", TextSize = 14, BackgroundColor3 = rgb(140, 40, 50), Visible = false, ZIndex = 3, Parent = mission })
	parts.Quit.Activated:Connect(function()
		if player:GetAttribute("Job") == nil and errandState() then
			abandonErrand()
			return
		end
		(Remotes:WaitForChild("QuitJob") :: RemoteEvent):FireServer()
	end)
	-- Todo el panel abre la lista de misiones (y la flecha › lo indica)
	local open = create("TextButton", { Name = "Open", Size = UDim2.new(1, -96, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = mission })
	local chevronButton = create("TextButton", { Name = "Chevron", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 10), Size = UDim2.fromOffset(40, 50), BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = mission })
	Icons.chevron({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 26), Thickness = 3, ZIndex = 2, Parent = chevronButton })
	parts.Pending = create("Frame", { Name = "New", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -10, 0, 12), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = rgb(255, 70, 90), Visible = false, ZIndex = 4, Parent = mission }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	open.Activated:Connect(openQuests)
	chevronButton.Activated:Connect(openQuests)
	Theme.pressable(chevronButton)
	-- "📍 Ruta a …" (tu ruta manda sobre la de la misión) y «Seguir misión ✕» para volver a ella
	local route = create("Frame", { Name = "RouteChip", Position = UDim2.fromOffset(40, 5), Size = UDim2.fromOffset(346, 30), BackgroundColor3 = rgb(16, 70, 88), BackgroundTransparency = 0.1, Visible = false, ZIndex = 4, Parent = mission }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(90, 220, 255), Thickness = 1.5, Transparency = 0.2 }),
	})
	parts.Route = route
	parts.RouteText = Theme.label({ Name = "Text", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -150, 1, 0), Font = Theme.FontBold, TextSize = 16, TextColor3 = rgb(160, 240, 255), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5, Parent = route })
	local follow = create("TextButton", { Name = "Follow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -3, 0.5, 0), Size = UDim2.fromOffset(136, 24), BackgroundColor3 = H.Gold, Text = "Seguir misión ✕", TextSize = 14, Font = Theme.FontBold, TextColor3 = rgb(30, 24, 8), AutoButtonColor = true, ZIndex = 6, Parent = route }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	Theme.pressable(follow)
	follow.Activated:Connect(function()
		local cancel = routeCancel
		if cancel then
			cancel()
		end
	end)

	-- Los objetivos llegan de la historia (el mismo estado que usa LifeStory)
	task.spawn(function()
		local remote = Remotes:WaitForChild("LifeStory") :: RemoteEvent
		local synced = false
		remote.OnClientEvent:Connect(function(kind: string, payload: any)
			if kind ~= "State" or typeof(payload) ~= "table" then
				return
			end
			synced = true
			storyState = payload
			local tracked = payload.Tracked
			local trackedId = tracked and tracked.QuestId
			local summary = missionSummary(payload)
			local title = if summary then summary.Title else ""
			if title ~= questTitleShown then
				questTitleShown = title
				if title ~= "" and not (questWindow and questWindow.Parent) then
					questPending = true
				end
			end
			-- Misión cumplida: el panel destella en verde
			if lastTracked and trackedId ~= lastTracked then
				local edge = mission:FindFirstChild("Edge") :: UIStroke?
				if edge then
					edge.Color = C.Money
					TweenService:Create(edge, TweenInfo.new(1.2), { Color = Color3.new(1, 1, 1) }):Play()
				end
				Theme.pop(mission, 1.05)
			end
			lastTracked = trackedId
			paintMission()
			if questList and questWindow and questWindow.Parent then
				renderQuestList(questList, payload)
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
	player:GetAttributeChangedSignal("Job"):Connect(paintMission)
	player:GetAttributeChangedSignal("TaskText"):Connect(paintMission)
	player:GetAttributeChangedSignal("CityErrand"):Connect(function()
		paintMission()
		if questList and questWindow and questWindow.Parent then
			renderQuestList(questList, storyState)
		end
	end)
	actions.Misiones = openQuests
	paintMission()
end

-- Controllers/Gps: la ruta que has elegido (texto de la etiqueta, p. ej. "📍 Ruta a Aeropuerto de
-- Valmar"; nil = ninguna) y qué hacer con «Seguir misión ✕» (quitarla y volver a la misión)
function Hud.setRouteChip(text: string?, onCancel: (() -> ())?)
	routeChip = text
	routeCancel = onCancel
	paintRouteChip()
end

-- (pruebas y Guide) la etiqueta de la ruta que se ve en la tarjeta de la misión
function Hud.routeChip(): string?
	return routeChip
end

-- Abre la lista de misiones sin cerrarla si ya está abierta ("Ver mis misiones" de la ayuda y
-- de las pistas: el comando "Misiones" alterna y la cerraba si ya estaba a la vista).
function Hud.showQuests()
	if questWindow and questWindow.Parent then
		return
	end
	local action = actions.Misiones
	if action then
		action()
	end
end

-- ¿Está abierta la lista de misiones? (el tutorial cuenta abrirla como "seguir la misión")
function Hud.questsOpen(): boolean
	return questWindow ~= nil and questWindow.Parent ~= nil
end

-- Lo que tienes que hacer ahora, en claro (para "¿Qué hago ahora?" y las pistas): el paso de tu
-- trabajo o de la misión que sigues, el sitio (si se sabe) y dónde está. nil = nada que hacer.
-- Key cambia cada vez que cambia el paso (así se sabe si llevas rato atascado).
export type Objective = { Kind: string, Title: string, Step: string, Place: string?, Target: Vector3?, Job: boolean, Key: string }
function Hud.objective(): Objective?
	local taskTarget = player:GetAttribute("TaskTarget")
	local jobId = player:GetAttribute("Job")
	local job = jobId and (Config.Jobs[jobId] or Gameplay.Jobs[jobId])
	local text = player:GetAttribute("TaskText")
	if job or (typeof(taskTarget) == "Vector3" and typeof(text) == "string") then
		local step = if typeof(text) == "string" then text else ""
		return {
			Kind = "TRABAJO",
			Title = if job then job.DisplayName else "Tu trabajo",
			Step = step,
			Target = if typeof(taskTarget) == "Vector3" then taskTarget else nil,
			Job = true,
			Key = "Trabajo|" .. step,
		}
	end
	local errand = errandState()
	if errand then
		local target = player:GetAttribute("CityErrandTarget")
		return {
			Kind = "ENCARGO",
			Title = errand.Title,
			Step = errand.Step or "",
			Target = if typeof(target) == "Vector3" then target else nil,
			Job = false,
			Key = "Encargo|" .. errand.Title .. "|" .. (errand.Step or ""),
		}
	end
	local summary = missionSummary(storyState)
	if not summary then
		return nil
	end
	-- El sitio del paso (el primero sin hacer si son varios)
	local place: string? = nil
	local tracked = storyState.Tracked
	if tracked then
		local args = tracked.Args
		for _, child in tracked.Children or {} do
			if not child.Done then
				args = child.Args
				break
			end
		end
		if type(args) == "table" and args.placeKey then
			place = Strings.get(args.placeKey)
		end
	end
	local target = player:GetAttribute("StoryTarget")
	return {
		Kind = summary.Kind,
		Title = summary.Title,
		Step = summary.Step,
		Place = place,
		Target = if typeof(target) == "Vector3" then target else nil,
		Job = false,
		Key = summary.Title .. "|" .. summary.Step,
	}
end

---------------------------------------------------------------------
-- Al llegar a un sitio: su nombre en grande
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
		Position = UDim2.new(0.5, 0, 0, toastTop),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = parent,
	})
	local title = Theme.title({ Size = UDim2.new(1, 0, 0, 46), TextSize = 40, TextStrokeTransparency = 0.3, TextStrokeColor3 = C.Ink, TextXAlignment = Enum.TextXAlignment.Center, Parent = banner })
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
		bannerOn = true
		placeToasts()
		banner.Position = UDim2.new(0.5, 0, 0, toastTop + 12)
		TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0, toastTop) }):Play()
		task.delay(3, function()
			if showing ~= id then
				return
			end
			local out = TweenService:Create(banner, TweenInfo.new(0.8), { GroupTransparency = 1 })
			out:Play()
			out.Completed:Wait()
			if showing == id then
				banner.Visible = false
				bannerOn = false
				placeToasts()
			end
		end)
	end

	-- Dónde estás: una vez por segundo. El cartel sale cuando cambias de sitio y llevas ahí un
	-- par de segundos (así no parpadea si andas justo por el borde entre dos barrios).
	local shown, pending, stable = "", "", 0
	task.spawn(function()
		while true do
			task.wait(1)
			-- Protegido: un error no deja sin cartel de zona el resto de la partida
			local ok, err = pcall(function()
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not root or busy then
					return -- (dentro del pcall: espera al siguiente segundo)
				end
				local position = root.Position
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
			end)
			if not ok then
				warn("[Hud] " .. tostring(err))
			end
		end
	end)
end

---------------------------------------------------------------------
-- Menú de ajustes y controles (las apps del antiguo menú rápido son apps del ValPhone)
---------------------------------------------------------------------
local menu: Frame
local controlsPanel: Frame

-- Icono de cada app por su nombre (las apps llegan como "🏠 Ir a casa")
local APP_ICONS = {
	["Ir a casa"] = "casa",
	["Tienda"] = "tienda",
	["Vehículos"] = "coche",
	["Gestos"] = "gestos",
	["Foto"] = "camara",
	["Mercadillo"] = "mercadillo",
	["Guía de pesca"] = "pesca",
	["Ruta a casa"] = "lugar",
}

-- "🏠 Ir a casa" -> ("Ir a casa", icono)
local function splitApp(text: string): (string, string)
	local first, rest = string.match(text, "^(%S+)%s+(.+)$")
	if first and rest and not string.match(first, "^[%w%p]") then
		return rest, APP_ICONS[rest] or first
	end
	return text, APP_ICONS[text] or "telefono"
end

local function popupPanel(name: string, title: string, iconName: string, size: Vector2): (Frame, Frame)
	local panel = Theme.hudPanel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 0.12,
		Visible = false,
		ZIndex = 30,
		Parent = popupGui,
	})
	Theme.bevel(panel)
	Icons.new(iconName, { Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(26, 26), Parent = panel })
	Theme.title({ Position = UDim2.fromOffset(50, 10), Size = UDim2.new(1, -100, 0, 30), Text = title, TextSize = 21, Parent = panel })
	local close = create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = H.NavyLight, Text = "", Parent = panel }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	Icons.plus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(16, 16), Rotation = 45, Parent = close })
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	touchPopup(panel, close)
	local content = create("Frame", { Name = "Content", Position = UDim2.fromOffset(16, 50), Size = UDim2.new(1, -32, 1, -62), BackgroundTransparency = 1, Parent = panel })
	return panel, content
end

-- Leyenda de controles (la franja "CONTROLES EN MÓVIL" de la referencia, como ventana de ayuda)
local function buildControls()
	local panel, content = popupPanel("Controls", "CONTROLES", "mando", Vector2.new(660, 400))
	controlsPanel = panel
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	local function line(order: number, iconName: string, title: string, text: string)
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = H.NavyLight, BackgroundTransparency = 0.5, LayoutOrder = order, Parent = content }, {
			create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		})
		Icons.new(iconName, { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(28, 28), Parent = row })
		Theme.label({ Position = UDim2.fromOffset(46, 0), Size = UDim2.fromOffset(170, 40), Text = title, Font = Theme.FontBold, TextSize = 15, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(220, 0), Size = UDim2.new(1, -228, 1, 0), Text = text, TextSize = 14, TextColor3 = C.Muted, TextWrapped = true, Parent = row })
	end
	if TOUCH then
		line(1, "flecha", "Pulgar izquierdo", "Movimiento: el joystick de abajo a la izquierda (hasta el borde: corres)")
		line(2, "interactuar", "Pulgar derecho", "Cámara (arrastra) y acciones: los botones redondos")
		line(3, "espada", "Ataque · Defensa", "Golpea (seguido = combo) · mantén el escudo para recibir menos daño")
		line(4, "esquivar", "Esquivar · Saltar", "Voltereta por el suelo para evitar un golpe · salta (también corriendo) y trepa muros bajos")
		line(5, "hablar", "Interactuar", "Hablar, abrir, usar objetos y entrar en sitios (lo que tengas delante)")
		line(6, "objetivo", "Fijar objetivo", "Miras siempre a quien tienes más cerca; otra vez para soltarlo")
	else
		line(1, "flecha", "Teclado", "WASD moverse · mantén Mayús correr · Espacio saltar · E usar lo de delante")
		line(2, "espada", "Pelear", "X golpear · Z defenderse · Q esquivar · V fijar objetivo")
		line(3, "telefono", "ValPhone", "Tab abre el teléfono (flechas y Enter dentro) · Enter hace la acción elegida de la tira")
		line(4, "mapa", "Atajos", "M mapa · 1-9 barra rápida · L linterna · P foto · B piedra · F bajarse · H claxon")
		line(5, "mando", "Mando", "L3 correr · RB golpear · LB defenderse · B esquivar o bajarse · A saltar")
		line(6, "linterna", "Mando (más)", "R3 linterna · LT foto · Y piedra · RT recoger sedal · Select: ValPhone · cruceta: acciones")
	end
end

local function buildMenu()
	local panel, content = popupPanel("Menu", "MENÚ", "menu", Vector2.new(340, 480))
	menu = panel
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	local controls = Theme.button({ Size = UDim2.new(1, 0, 0, 36), Text = "🎮 Controles", TextSize = 15, LayoutOrder = 50, ZIndex = 31, Parent = content })
	controls.Activated:Connect(function()
		Dialog.closeOthers("Controls")
		controlsPanel.Visible = true
		Theme.pop(controlsPanel, 1.04)
	end)
	actions.Menu = function()
		if not menu.Visible then
			-- Una sola ventana grande a la vez: fuera los controles, las misiones o la tienda
			Dialog.closeOthers("Menu")
		end
		menu.Visible = not menu.Visible
		if menu.Visible then
			Theme.pop(menu, 1.04)
		end
	end
	actions.Controles = function()
		if not controlsPanel.Visible then
			Dialog.closeOthers("Controls")
		end
		controlsPanel.Visible = not controlsPanel.Visible
	end
	Dialog.registerBig("Menu", function()
		menu.Visible = false
	end, function()
		return menu.Visible
	end)
	Dialog.registerBig("Controls", function()
		controlsPanel.Visible = false
	end, function()
		return controlsPanel.Visible
	end)
	Dialog.registerBig("Quests", function()
		if questWindow and questWindow.Parent then
			openQuests() -- (con la ventana abierta, la cierra)
		end
	end)
end

-- Añade una opción al menú (la usa el cliente para la música, los sonidos, la ropa…). Sale en la app
-- Ajustes del ValPhone (Hud.menuToggles) y en la ventana MENÚ de siempre.
-- current (opcional): devuelve el texto de ahora, por si el ajuste cambia por otro lado (Hud.syncMenuToggles).
type MenuToggle = { Text: string, Order: number, Press: () -> string, Current: (() -> string)? }
local menuToggles: { MenuToggle } = {}
local menuButtons: { [MenuToggle]: TextButton } = {}
function Hud.addMenuToggle(text: string, order: number, callback: () -> string, current: (() -> string)?)
	local content = menu:FindFirstChild("Content") :: Frame
	local button = Theme.button({ Size = UDim2.new(1, 0, 0, 36), Text = text, TextSize = 14, TextWrapped = true, LayoutOrder = order, ZIndex = 31, Parent = content })
	local entry: MenuToggle
	entry = {
		Text = text,
		Order = order,
		Press = function(): string
			local now = callback()
			entry.Text = now
			button.Text = now
			return now
		end,
		Current = current,
	}
	table.insert(menuToggles, entry)
	menuButtons[entry] = button
	button.Activated:Connect(function()
		entry.Press()
	end)
end

-- Las opciones del menú en orden (app Ajustes del ValPhone): { Text, Order, Press() -> texto nuevo }
function Hud.menuToggles(): { MenuToggle }
	local list = table.clone(menuToggles)
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end

-- Vuelve a leer el texto de los ajustes que saben el suyo (p. ej. los gráficos elegidos en Ajustes)
function Hud.syncMenuToggles()
	for _, entry in menuToggles do
		if entry.Current then
			local ok, now = pcall(entry.Current)
			if ok and type(now) == "string" then
				entry.Text = now
				local button = menuButtons[entry]
				if button then
					button.Text = now
				end
			end
		end
	end
end

-- Cierra la ventana MENÚ si está abierta (p. ej. al volver a ver el tutorial)
function Hud.closeMenu()
	if menu and menu.Visible then
		menu.Visible = false
	end
end

-- Acciones de los comandos (Mochila, Mapa, Personaje…): las conecta cada sistema
function Hud.setAction(id: string, callback: () -> ())
	actions[id] = callback
end

-- Añade una app (Ir a casa, Tienda, Vehículos…) al ValPhone, después de Mochila y Mapa y antes de las
-- de «Más», en el orden de `order` (su icono y color: Commands/PhoneApps.Catalog). Hace lo mismo que
-- el botón del antiguo menú rápido. (El color de aquí ya no se usa.)
function Hud.addButton(text: string, _color: Color3?, order: number, callback: () -> ()): TextButton?
	local label, iconName = splitApp(text)
	CommandRegistry.register({
		Id = "App" .. label,
		Label = label,
		Icon = iconName,
		-- Mapa es 51 y Más 60: las apps van en medio (order 1-7 -> 52-55,5)
		Priority = 51.5 + math.clamp(order, 0, 16) * 0.5,
		When = function(ctx)
			return ctx.Stage ~= "Bebe"
		end,
		Run = function()
			callback()
		end,
	})
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

-- Avisos a la vista (el más viejo primero) y cuándo salió cada texto: el mismo aviso repetido
-- (p. ej. al mantener una tecla) no se amontona, y nunca hay más de unos pocos a la vez
local TOAST_MAX = 4
local TOAST_REPEAT = 2
local activeToasts: { Frame } = {}
local recentToasts: { [string]: { At: number, Slot: Frame } } = {}

function Hud.toast(kind: string, text: string)
	local now = os.clock()
	local recent = recentToasts[text]
	if recent and now - recent.At < TOAST_REPEAT and recent.Slot.Parent ~= nil then
		return
	end
	local color = TOAST_COLORS[kind] or C.Muted
	-- Demasiados: se quita el más viejo (con un arma en la mano, como mucho dos)
	local max = if armedNow() then 2 else TOAST_MAX
	for i = #activeToasts, 1, -1 do
		if activeToasts[i].Parent == nil then
			table.remove(activeToasts, i)
		end
	end
	while #activeToasts >= max do
		table.remove(activeToasts, 1):Destroy()
	end
	-- El aviso entra deslizándose desde arriba y se va desvaneciendo
	local slot = create("Frame", { Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = toastList })
	table.insert(activeToasts, slot)
	recentToasts[text] = { At = now, Slot = slot }
	local toast = create("CanvasGroup", {
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(0, -14),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.2,
		GroupTransparency = 1,
		Parent = slot,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }), create("UIGradient", { Rotation = 90, Color = Theme.PanelSheen }) })
	local stroke = Theme.stroke(0.2)
	stroke.Color = color
	stroke.Parent = toast
	create("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 14), Parent = toast })
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
		if slot.Parent == nil then
			return -- (ya se quitó por haber demasiados)
		end
		local fadeOut = TweenService:Create(toast, TweenInfo.new(0.4), { GroupTransparency = 1 })
		fadeOut:Play()
		fadeOut.Completed:Wait()
		slot:Destroy()
		local entry = recentToasts[text]
		if entry and entry.Slot == slot then
			recentToasts[text] = nil
		end
	end)
end

-- Pantalla en negro con un texto (dormir, viajar…). Si llega otro fundido antes de acabar el
-- anterior, manda el último: el viejo ya no quita la pantalla negra (ficha `fadeToken`)
local fadeToken = 0
function Hud.fade(text: string, seconds: number)
	fadeToken += 1
	local token = fadeToken
	local caption = sleepOverlay:FindFirstChild("Caption") :: TextLabel?
	if caption then
		caption.Text = text
	end
	local already = sleepOverlay.Visible
	sleepOverlay.Visible = true
	if not already then
		sleepOverlay.BackgroundTransparency = 1
		if caption then
			caption.TextTransparency = 1
		end
	end
	-- El texto aparece y se va a la vez que el fondo
	TweenService:Create(sleepOverlay, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
	if caption then
		TweenService:Create(caption, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
	end
	task.delay(math.max(seconds - 0.6, 0.6), function()
		if token ~= fadeToken then
			return
		end
		local tween = TweenService:Create(sleepOverlay, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
		tween:Play()
		if caption then
			TweenService:Create(caption, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		end
		tween.Completed:Wait()
		if token == fadeToken then
			sleepOverlay.Visible = false
		end
	end)
end

function Hud.sleep()
	Hud.fade("Zzz...", Config.SleepSeconds)
end

-- Aviso fijo bajo el reloj (examen de conducir, etc.)
local function buildActivity(parent: Instance)
	local panel = Theme.hudPanel({
		Name = "Activity",
		AutomaticSize = Enum.AutomaticSize.X,
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

-- Quien quiere saber si la tarjeta de la misión está a la vista (LifeStory: en el móvil, la pestaña
-- «Tu vida» se aparta mientras se ve la misión, que dice lo mismo)
local missionListeners: { () -> () } = {}
local missionWasShown = false
function Hud.missionShown(): boolean
	return mission ~= nil and mission.Visible == true and mission.Parent ~= nil
end
function Hud.onMissionShown(listener: () -> ())
	table.insert(missionListeners, listener)
end

-- De bebé casi todo sobra (solo la hora); en conversaciones y cinemáticas tu estado y la misión se
-- apartan para dejar ver la escena
function refreshVisible()
	if not gui then
		return
	end
	local baby = player:GetAttribute("LifeStage") == "Bebe"
	local show = not busy and not baby
	status.Visible = show
	if mission then
		mission.Visible = show and hasMission
	end
	local shown = Hud.missionShown()
	if shown ~= missionWasShown then
		missionWasShown = shown
		for _, listener in missionListeners do
			task.spawn(listener)
		end
	end
end

local function applyLayout(layout: HudLayout.Layout)
	local items = layout.Items
	HudLayout.apply(status, items.Status)
	HudLayout.apply(gui:FindFirstChild("Clock") :: Frame, items.Clock)
	HudLayout.apply(mission, items.Mission)
	local activity = gui:FindFirstChild("Activity") :: Frame
	HudLayout.apply(activity, items.Activity, true)
	activity.Size = UDim2.fromOffset(0, items.Activity.Size.Y)
	toastTop = items.Toasts.Position.Y.Offset
	armedToastTop = items.Activity.Position.Y.Offset
	placeToasts()
	refreshVisible()
end

function Hud.init(openStore: () -> ()): ScreenGui
	local playerGui = player:WaitForChild("PlayerGui")
	HudLayout.start()
	gui = create("ScreenGui", {
		Name = "MainHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true, -- el diseño comparte la franja de arriba con los botones de Roblox
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	local scale = HudLayout.scaleGui(gui)

	buildClock(gui)
	buildActivity(gui)
	buildStatus(gui)
	buildMission(gui)
	buildAreaBanner(gui)
	-- Menú, controles y misiones en su propia capa, por encima del minimapa (que es de MapUI)
	popupGui = create("ScreenGui", { Name = "HudPopups", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
	HudLayout.scaleGui(popupGui)
	buildControls()
	buildMenu()
	TouchLayout.init(playerGui)

	HudLayout.onChanged(applyLayout)

	-- Apps que pone el propio HUD (en el ValPhone)
	Hud.addButton("🏠 Ir a casa", rgb(40, 110, 220), 1, function()
		(Remotes:WaitForChild("GoHome") :: RemoteEvent):FireServer()
	end)
	Hud.addButton("🛒 Tienda", rgb(200, 145, 20), 2, openStore)

	-- Los avisos van en su propia capa, por encima de las ventanas (tiendas, vehículos…): si no, un
	-- "no tienes dinero" quedaba escondido detrás de la ventana y parecía que el botón no hacía nada
	local toastGui = create("ScreenGui", { Name = "HudToasts", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9, Parent = playerGui })
	local toastScale = create("UIScale", { Scale = scale.Scale, Parent = toastGui })
	if TOUCH then
		HudLayout.boostText(toastGui)
		toastGui.DescendantAdded:Connect(HudLayout.boostText) -- (móvil: avisos más legibles)
	end
	scale:GetPropertyChangedSignal("Scale"):Connect(function()
		toastScale.Scale = scale.Scale
	end)
	toastList = create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(600, 200),
		Position = UDim2.new(0.5, 0, 0, toastTop),
		BackgroundTransparency = 1,
		Active = false,
		Parent = toastGui,
	})
	create("UIScale", { Name = "ArmedScale", Parent = toastList })
	placeToasts()
	create("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastList })
	Players.LocalPlayer:GetAttributeChangedSignal("Weapon"):Connect(placeToasts)

	-- La pantalla negra de dormir va en su propio ScreenGui (sin UIScale) para cubrirlo todo
	local overlayGui = create("ScreenGui", { Name = "SleepOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, Parent = playerGui })
	sleepOverlay = create("Frame", { Name = "Sleep", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false, Parent = overlayGui })
	Theme.title({ Name = "Caption", Size = UDim2.fromScale(1, 1), Text = "Zzz...", TextSize = 40, TextXAlignment = Enum.TextXAlignment.Center, Parent = sleepOverlay })

	player:GetAttributeChangedSignal("LifeStage"):Connect(refreshVisible)
	refreshVisible()

	return gui
end

-- Mientras hablas con alguien o ves una cinemática, lo que tapa la escena se aparta
function Hud.setBusy(value: boolean)
	busy = value
	refreshVisible()
	TouchLayout.setBusy(value)
end

return Hud
