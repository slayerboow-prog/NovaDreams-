-- Hud: la interfaz principal del juego.
--
--   Arriba a la izquierda  -> tu estado: la foto en un aro brillante con la corona de nivel, tu nombre,
--                             nivel y dinero, la experiencia y las barras de Energía, Hambre,
--                             Diversión (🎈; 😐 si te aburres), Ánimo (o Estamina) y Salud con su número
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
local TefraCity = require(ReplicatedStorage.Shared.Cosmos.TefraCity)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Theme)
local Icons = require(script.Parent.Icons)
local HudLayout = require(script.Parent.HudLayout)
local TouchLayout = require(script.Parent.TouchLayout)
local TopStack = require(script.Parent.TopStack)
local Dialog = require(script.Parent.Dialog)
local QuestPanel = require(script.Parent.QuestPanel)
local Races = require(ReplicatedStorage.Shared.Invasion.Races)
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
		-- Debajo de los letreros de arriba en el centro (UI/TopStack: el marcador de un deporte, la pista
		-- del paso, el aviso de la grieta…): nunca encima de ellos
		local gui = toastList.Parent
		local scaler = gui and gui:FindFirstChildOfClass("UIScale")
		local k = if scaler and scaler.Scale > 0 then scaler.Scale else 1
		-- (pilotando un avión, también debajo del panel de instrumentos: TopStack.bottom() ya lo cuenta)
		if #TopStack.shownRects() > 0 or TopStack.isPiloting() then
			top = math.max(top, math.ceil((TopStack.bottom() + TopStack.Gap) / k))
		end
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
local flightFocus = false -- a los mandos de la nave: sin la tarjeta de misión (Hud.setFlightFocus)
local zoneFocus: string? = nil -- en otro planeta: sin la tarjeta de misión de Valmar (Hud.setZoneFocus)
local shipFocus = false -- (Espacio AAA) en la nave: el HUD de la nave trae su perfil y su brújula (Hud.setShipFocus)

local WEEKDAYS = { "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo" }
-- (cortos a mano: string.sub partiría la «é» de «miércoles» en UTF-8)
local WEEKDAYS_SHORT = { "lun", "mar", "mié", "jue", "vie", "sáb", "dom" }
local MONTHS_SHORT = { "ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic" }
local MONTHS = { "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre" }

---------------------------------------------------------------------
-- Arriba en el centro: cápsula de la hora, la fecha y el tiempo
---------------------------------------------------------------------
local function separator(parent: Instance, x: number): Frame
	return create("Frame", {
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
	local sep1 = separator(panel, 180)
	local date = Theme.label({ Name = "Date", Size = UDim2.fromOffset(226, 24), Position = UDim2.fromOffset(194, 9), FontFace = Theme.ItalicFace, TextSize = 19, TextColor3 = H.SelectLight, Parent = panel })
	local sub = Theme.label({ Name = "Day", Size = UDim2.fromOffset(226, 20), Position = UDim2.fromOffset(194, 34), TextSize = 15, TextColor3 = C.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	local sep2 = separator(panel, 428)
	local weatherIcon = Icons.new("sol", { Name = "WeatherIcon", Position = UDim2.fromOffset(440, 13), Size = UDim2.fromOffset(38, 38), Parent = panel })
	local temp = Theme.label({ Name = "Temp", Size = UDim2.fromOffset(110, 26), Position = UDim2.fromOffset(484, 8), Font = Theme.FontBold, TextSize = 21, Parent = panel })
	local weatherName = Theme.label({ Name = "Weather", Size = UDim2.fromOffset(110, 20), Position = UDim2.fromOffset(484, 34), TextSize = 15, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	-- Móvil: una cápsula de una fila (HudLayout.Compact.Clock, 440x56): sol, la hora grande | el tiempo,
	-- los grados y la fecha corta («mar 2 ene»). La fecha larga y el día de tu vida siguen en el ValPhone.
	local shortDate: TextLabel? = nil
	if TOUCH then
		sun.Position, sun.Size = UDim2.fromOffset(12, 10), UDim2.fromOffset(36, 36)
		time.Position, time.Size = UDim2.fromOffset(52, 0), UDim2.fromOffset(116, 56)
		sep1.Position = UDim2.fromOffset(172, 8)
		date.Visible, sub.Visible, sep2.Visible, weatherName.Visible = false, false, false, false
		weatherIcon.Position, weatherIcon.Size = UDim2.fromOffset(184, 12), UDim2.fromOffset(32, 32)
		temp.Position, temp.Size = UDim2.fromOffset(220, 13), UDim2.fromOffset(84, 30)
		shortDate = Theme.label({ Name = "ShortDate", Size = UDim2.fromOffset(126, 30), Position = UDim2.fromOffset(306, 13), FontFace = Theme.ItalicFace, TextSize = 18, TextColor3 = H.SelectLight, Parent = panel }) -- (sin «…»: si no cabe, la letra encoge; con «…» salía «mié 3…»)
	end

	local shownMinute, shownHour = -1, -1
	local function updateWeather()
		local clock = GameClock.hour()
		-- En Tefra, el tiempo de Tefra (siempre cae ceniza y hace calor), no el de Valmar
		if player:GetAttribute("Planeta") == "Tefra" then
			local w = TefraCity.weather(clock)
			Icons.set(weatherIcon, w.Icon)
			setText(temp, ("%d°C"):format(w.Temp))
			setText(weatherName, w.Name)
			return
		end
		local weather = workspace:GetAttribute("Weather") or "Despejado"
		local season = workspace:GetAttribute("Season") or "Primavera"
		local info = Seasons.Weather[weather]
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
		local clock = GameClock.hour()
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
		if shortDate then
			setText(shortDate, ("%s %d %s"):format(WEEKDAYS_SHORT[now.Weekday] or "", now.DayOfMonth, MONTHS_SHORT[now.Month] or ""))
		end
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
	player:GetAttributeChangedSignal("Planeta"):Connect(function()
		shownMinute = -1
		shownHour = -1
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
	{ Id = "Fun", Icon = "diversion", From = rgb(160, 90, 255), To = rgb(255, 130, 220) }, -- 🎈 Diversión (NeedsService)
	{ Id = "Mood", Icon = "cara", From = rgb(255, 150, 40), To = rgb(255, 225, 90) },
	{ Id = "Health", Icon = "corazon", From = rgb(255, 60, 150), To = rgb(255, 150, 200) },
}

local status: Frame
local statusOpen = false -- (móvil) tu estado desplegado entero (al tocarlo o si algo baja mucho)
local statusToken = 0
local setStatusOpen: (open: boolean, seconds: number?) -> () = function() end

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

-- Móvil: tu estado plegado (HudLayout.Compact.Status, 390x104): la foto, «Nv. 2 ⬆  325 €» (≥ 16 pt),
-- una raya de experiencia y las 5 barras con su icono (3 + 2, ≥ 6 pt de grueso); el número de una barra
-- sale solo cuando está baja (encima del trozo vacío de la barra, así no pisa la de al lado). Tocarlo lo despliega entero (con tu nombre, la experiencia y todos los
-- números) unos segundos; también se despliega solo si una barra baja de 25 %.
local LOW = 0.25
local OPEN_SECONDS = 6
local function buildCompactStatus(card: Frame, p: { [string]: any }, bars: { [string]: any })
	-- Cada pieza: lo que tiene desplegada (como la hizo buildStatus) y plegada
	type Look = { Position: UDim2?, Size: UDim2?, Visible: boolean? }
	local looks: { { Object: GuiObject, Full: Look, Small: Look } } = {}
	local function fold(object: GuiObject?, small: Look)
		if object then
			table.insert(looks, { Object = object, Full = { Position = object.Position, Size = object.Size, Visible = object.Visible }, Small = small })
		end
	end
	fold(p.Plate, { Position = UDim2.fromOffset(40, 4), Size = UDim2.new(1, -40, 1, -6) })
	fold(p.Ring, { Position = UDim2.fromOffset(4, 10), Size = UDim2.fromOffset(84, 84) })
	fold(p.Badge, { Size = UDim2.fromOffset(28, 28) })
	fold(p.Name, { Visible = false })
	fold(p.Level, { Position = UDim2.fromOffset(98, 2), Size = UDim2.fromOffset(84, 32) })
	fold(p.Money, { Position = UDim2.fromOffset(184, 2), Size = UDim2.fromOffset(200, 32) })
	fold(p.XpTrack, { Position = UDim2.fromOffset(98, 36), Size = UDim2.fromOffset(280, 6) })
	fold(p.XpText, { Visible = false })
	local order = { "Energy", "Hunger", "Fun", "Mood", "Health" }
	for i, id in order do
		local bar = bars[id]
		-- 3 columnas de 96: arriba energía, hambre y diversión; abajo ánimo y salud
		local x = 98 + ((i - 1) % 3) * 96
		local y = if i <= 3 then 46 else 74
		fold(bar.Icon, { Position = UDim2.fromOffset(x, y + 3), Size = UDim2.fromOffset(22, 22) })
		fold(bar.Track, { Position = UDim2.fromOffset(x + 25, y + 8), Size = UDim2.fromOffset(64, 12) })
		-- (el número: solo si la barra está baja, en la parte vacía de la barra; ver paint)
		fold(bar.Value, { Position = UDim2.fromOffset(x + 55, y - 1), Size = UDim2.fromOffset(34, 30) })
	end
	local low: { [string]: boolean } = {}
	-- Toda la tarjeta se puede tocar (encima de todo lo suyo)
	local hit = create("TextButton", { Name = "Expand", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 9, Parent = card })
	local function paint()
		for _, look in looks do
			local want = if statusOpen then look.Full else look.Small
			local object = look.Object
			object.Position = want.Position or look.Full.Position :: UDim2
			object.Size = want.Size or look.Full.Size :: UDim2
			object.Visible = if want.Visible ~= nil then want.Visible else look.Full.Visible :: boolean
		end
		if not statusOpen then
			for _, id in order do
				bars[id].Value.Visible = low[id] == true
			end
		end
		card:SetAttribute("Expanded", statusOpen)
		HudLayout.apply(card, if statusOpen then HudLayout.current().Items.StatusOpen else HudLayout.current().Items.Status)
	end
	setStatusOpen = function(open: boolean, seconds: number?)
		statusToken += 1
		local mine = statusToken
		if open ~= statusOpen then
			statusOpen = open
			paint()
		end
		if open and seconds then
			task.delay(seconds, function()
				if statusToken == mine and statusOpen then
					statusOpen = false
					paint()
				end
			end)
		end
	end
	hit.Activated:Connect(function()
		setStatusOpen(not statusOpen, OPEN_SECONDS)
	end)
	-- Si una barra baja de 25 % (hambre, cansancio, salud…), se despliega sola un momento y, plegada,
	-- enseña su número
	local function watch()
		for _, id in order do
			local fill = bars[id].Fill :: Frame
			local isLow = fill.Size.X.Scale < LOW
			if isLow and not low[id] and not statusOpen then
				low[id] = true
				setStatusOpen(true, 4)
			end
			low[id] = isLow
			if not statusOpen then
				bars[id].Value.Visible = isLow
			end
		end
	end
	for _, id in order do
		(bars[id].Fill :: Frame):GetPropertyChangedSignal("Size"):Connect(watch)
	end
	statusOpen = false
	paint()
	watch()
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
	local levelText = Theme.label({ Name = "Level", Position = UDim2.fromOffset(TEXT_X, 38), Size = UDim2.fromOffset(84, 22), Font = Theme.FontBold, TextSize = if TOUCH then 20 else 18, TextStrokeTransparency = 0.5, Parent = status })
	local money = Theme.label({ Name = "Money", Position = UDim2.fromOffset(TEXT_X + 90, 38), Size = UDim2.fromOffset(200, 22), Font = Theme.FontBold, TextSize = if TOUCH then 20 else 18, TextColor3 = C.Money, TextStrokeTransparency = 0.5, Parent = status })
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

	-- Barras con icono y número (5 en 16 studs cada una: caben en el alto de siempre)
	local bars: { [string]: { Track: Frame, Fill: Frame, Value: TextLabel, Icon: Frame, Ratio: number } } = {}
	local step = math.min(19, math.floor(80 / #BARS))
	for i, def in BARS do
		local y = 86 + (i - 1) * step
		local icon = Icons.new(def.Icon, { Name = def.Id .. "Icon", Position = UDim2.fromOffset(TEXT_X, y), Size = UDim2.fromOffset(step - 1, step - 1), Parent = status })
		local track = create("Frame", {
			Name = def.Id,
			Position = UDim2.fromOffset(TEXT_X + 24, y + math.floor((step - 10) / 2)),
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
			Size = UDim2.fromOffset(52, step - 1),
			Font = Theme.FontBold,
			TextSize = if TOUCH then 18 else 16,
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
		-- (puntos por repartir: una flecha, no un «+», que en el móvil se leía junto al dinero: «Nv. 4 +535 €»)
		setText(levelText, ("Nv. %d%s"):format(level, if points > 0 then " ⬆" else ""))
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
		-- 🎈 Diversión: aburrido (Bored), la carita seria en vez del globo
		setBar("Fun", player:GetAttribute("Fun") or Config.Needs.Max, Config.Needs.Max)
		Icons.set(bars.Fun.Icon, if player:GetAttribute("Bored") == true then "aburrido" else "diversion")
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
	for _, attribute in { "Energy", "Hunger", "Fun", "Bored", "Stamina", "MaxStamina", "Mood", "MaxMood" } do
		player:GetAttributeChangedSignal(attribute):Connect(needs)
	end
	needs()
	if TOUCH then
		buildCompactStatus(status, { Plate = status:FindFirstChild("Plate"), Ring = ring, Badge = badge, Name = name, Level = levelText, Money = money, XpTrack = xpTrack, XpText = xpText }, bars)
	end
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

-- Cuándo abre un sitio cerrado: «abre a las 8:30» (hoy), «abre mañana a las 8:30» o «abre el lunes
-- a las 8:30» (el colegio y el instituto no abren el fin de semana)
local function opensText(closed: { [string]: any }): string
	local from = if type(closed.From) == "number" then closed.From else Config.SchoolDay.Opens
	local days = closed.Weekdays
	local function opens(day: number): boolean
		return type(days) ~= "table" or table.find(days, day) ~= nil
	end
	local now = GameClock.now()
	local today = now.Weekday or 1
	if opens(today) and now.ClockTime < from then
		return ("abre a las %s"):format(hourText(from))
	end
	for i = 1, 7 do
		local day = (today - 1 + i) % 7 + 1
		if opens(day) then
			if i == 1 then
				return ("abre mañana a las %s"):format(hourText(from))
			end
			return ("abre el %s a las %s"):format(string.lower(WEEKDAYS[day] or ""), hourText(from))
		end
	end
	return ("abre a las %s"):format(hourText(from))
end

-- Lo que dice la tarjeta de una misión en pausa (Later): sigue al salir del cole, o cuando abra el cole
local function laterStep(tracked: { [string]: any }): string?
	if tracked.Later == "AfterSchool" then
		return ("Sigue al salir del cole (%s)"):format(hourText(if type(tracked.From) == "number" then tracked.From else Config.SchoolDay.End))
	elseif tracked.Closed then
		local text = ("%s está cerrado · %s"):format(tracked.Closed.Name, opensText(tracked.Closed))
		local clock = GameClock.now().ClockTime
		if tracked.Later == "School" and (clock >= 19 or clock < 7) then
			text ..= " · 💤 duerme"
		end
		return text
	end
	return nil
end

-- Un paso sin texto (una escena, un minijuego…): qué toca, según su tipo; si no, el título
local STEP_TYPE_TEXT = {
	Scene = "Mira la escena", Cinematic = "Mira la escena", Transition = "Mira la escena",
	MiniGame = "Juega el minijuego", Choice = "Elige qué hacer", Use = "Usa lo que está marcado",
	Fight = "¡Defiéndete!", Chase = "¡Corre tras él!", Escape = "¡Escapa!", Class = "Ve a clase y atiende",
	Reach = "Ve al sitio marcado", Event = "Sigue con la misión", Group = "Haz lo que se pide",
}
local function stepFallback(tracked: { [string]: any }): string
	if tracked.StepType == "Talk" then
		return if tracked.NpcKey then ("Habla con %s"):format(Strings.get(tracked.NpcKey)) else "Habla con quien te espera"
	end
	return STEP_TYPE_TEXT[tracked.StepType or ""] or Strings.get(tracked.TitleKey)
end

local mission: Frame
local missionParts: { [string]: any } = {}
local storyState: { [string]: any } = {}
local storySynced = false
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
		if step == "" then
			step = stepFallback(tracked)
		end
		step = laterStep(tracked) or step
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

-- La Invasión de la Grieta (Services/InvasionService): el estado global (atributo Invasion de
-- workspace) y tus misiones de la invasión (atributo InvasionBook)
local function invasionState(): { [string]: any }?
	local raw = workspace:GetAttribute("Invasion")
	if type(raw) ~= "string" then
		return nil
	end
	local ok, st = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(st) == "table" then st else nil
end

local function invasionBook(): { { [string]: any } }
	local raw = player:GetAttribute("InvasionBook")
	if type(raw) ~= "string" then
		return {}
	end
	local ok, list = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(list) == "table" then list else {}
end

-- Las misiones de vuelo que se pueden coger durante la invasión (shared/Invasion/Missions, Chain Vuelo)
local INVASION_FLIGHTS = {
	{ Id = "Bahia", Text = "✈ Ojos sobre la bahía (avioneta)" },
	{ Id = "Evacuacion", Text = "✈ Corredor de evacuación (avioneta)" },
	{ Id = "Baliza", Text = "🚀 La baliza nodriza (nave)" },
	{ Id = "Cazadores", Text = "🎯 Cazadores del cielo (avioneta o nave)" },
}

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
	-- (la invasión ya NO se pone aquí: era un segundo «EVENTO GLOBAL» junto al del centro, todo el rato;
	-- captura del dueño. Su único aviso es el de UI/InvasionHud, y tu misión sigue aquí)
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

-- Lista completa (ventana MISIONES, como la referencia del dueño: docs/bugs/misiones-referencia.png):
-- cada apartado es una tarjeta con su título; dentro, filas con su círculo, el título y la pista en gris.
local function objectiveRow(parent: Instance, order: number, text: string, done: boolean?, strong: boolean?, hint: string?)
	local row = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local dot = create("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = if done then C.Money else C.Gold, BackgroundTransparency = if done or strong then 0 else 1, Parent = row }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = if done then C.Money elseif strong then C.Gold else C.Muted, Thickness = 1.5 }),
	})
	if done then
		Theme.label({ Size = UDim2.fromScale(1, 1), Text = "✔", TextSize = 11, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = dot })
	end
	local label = Theme.label({
		Name = "Text",
		Size = UDim2.new(1, -30, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(28, 0),
		Text = QuestPanel.rowText(text, hint),
		TextSize = 15,
		TextWrapped = true,
		TextColor3 = if done then C.Muted else C.Text,
		Parent = row,
	})
	label.RichText = true
	return row
end

-- Un apartado: tarjeta con borde, su título (◈ EVENTO GLOBAL, ◈ MISIÓN PRINCIPAL…) y lo de dentro en
-- lista. Devuelve la tarjeta: las filas del apartado van dentro.
local function section(parent: Instance, order: number, title: string, color: Color3): Frame
	local box = create("Frame", {
		Name = "Seccion",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = rgb(16, 26, 48),
		BackgroundTransparency = 0.05,
		LayoutOrder = order,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIStroke", { Color = color, Thickness = 1.2, Transparency = 0.55 }),
		create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
		create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local header = create("Frame", { Name = "Cabecera", Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 0, Parent = box })
	Icons.diamond({ Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(16, 16), Color = color, Parent = header })
	Theme.title({ Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -24, 1, 0), Text = string.upper(title), TextSize = 16, TextColor3 = color, Parent = header })
	return box
end

-- La tarjeta del evento: icono de la raza, su nombre, la oleada, la barra y una línea de qué pasa
local function eventCard(parent: Instance, order: number, info: { [string]: any }, color: Color3)
	local h = QuestPanel.EventCardHeight
	local cardFrame = create("Frame", { Name = "EventoCarta", Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = rgb(10, 18, 36), BackgroundTransparency = 0, LayoutOrder = order, Parent = parent }, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", { Color = rgb(70, 110, 170), Thickness = 1, Transparency = 0.3 }),
	})
	local icon = create("Frame", { Name = "Icono", Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(h - 12, h - 12), BackgroundColor3 = color, BackgroundTransparency = 0.55, Parent = cardFrame }, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIStroke", { Color = color, Thickness = 1.2 }),
	})
	Theme.label({ Size = UDim2.fromScale(1, 1), Text = "🛸", TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Parent = icon })
	local x = h + 4
	Theme.label({ Name = "Raza", Position = UDim2.fromOffset(x, 6), Size = UDim2.new(0.6, -x, 0, 20), Text = info.Name, TextSize = 17, Font = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, Parent = cardFrame })
	Theme.label({ Name = "Oleada", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -30, 0, 7), Size = UDim2.new(0.4, -30, 0, 18), Text = info.Wave, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, Parent = cardFrame })
	local back = create("Frame", { Name = "Barra", Position = UDim2.fromOffset(x, 30), Size = UDim2.new(1, -x - 30, 0, 6), BackgroundColor3 = rgb(30, 40, 60), BorderSizePixel = 0, Parent = cardFrame }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	create("Frame", { Name = "Relleno", Size = UDim2.fromScale(info.Progress, 1), BackgroundColor3 = rgb(80, 210, 120), BorderSizePixel = 0, Parent = back }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.label({ Name = "Texto", Position = UDim2.fromOffset(x, 40), Size = UDim2.new(1, -x - 30, 0, 20), Text = info.Desc, TextSize = 14, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = cardFrame })
	Theme.label({ Name = "Flecha", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(18, 24), Text = "›", TextSize = 24, Font = Theme.FontBold, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = cardFrame })
	return cardFrame
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
		local box = section(list, nextOrder(), "Encargo de la ciudad", rgb(80, 210, 255))
		Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = "🧺 " .. errand.Title, TextSize = 18, LayoutOrder = nextOrder(), Parent = box })
		objectiveRow(box, nextOrder(), errandStep(errand), false, true)
		objectiveRow(box, nextOrder(), ("Te lo ha pedido %s · %s y %d XP"):format(errand.Giver or "alguien", Format.money(errand.Money or 0), errand.Xp or 0), false)
		local drop = Theme.button({ Size = UDim2.fromOffset(170, 32), Text = "Dejar el encargo", TextSize = 14, BackgroundColor3 = rgb(140, 40, 50), LayoutOrder = nextOrder(), Parent = box })
		drop.Activated:Connect(abandonErrand)
	end
	-- EVENTO GLOBAL: la Invasión de la Grieta (y, después, «Recuperar la normalidad»)
	local inv = invasionState()
	local book = invasionBook()
	if inv or #book > 0 then
		local box = section(list, nextOrder(), "Evento global", Color3.fromRGB(120, 255, 230))
		if inv then
			local ids = if type(inv.Races) == "table" then inv.Races else {}
			local main = Races.get(ids[1] or inv.Main or "")
			local tint = if main then Races.color(main.Palette.Glow) else Color3.fromRGB(120, 255, 230)
			eventCard(box, nextOrder(), QuestPanel.eventInfo(inv, book, Races.names(ids)), tint)
		end
		local active: { [string]: boolean } = {}
		for _, m in book do
			active[m.Id] = true
			-- (la del evento ya va en la tarjeta; las demás, con su paso en gris)
			if not (inv and m.Chain == "Evento") then
				objectiveRow(box, nextOrder(), tostring(m.Title), false, true, tostring(m.Step or ""))
			end
		end
		if inv and inv.State ~= "End" then
			for _, f in INVASION_FLIGHTS do
				if not active[f.Id] then
					local row = objectiveRow(box, nextOrder(), f.Text, false, false, "toca para cogerla")
					local pick = create("TextButton", { Name = "Invasion_" .. f.Id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = row })
					pick.Activated:Connect(function()
						local r = Remotes:FindFirstChild("Invasion")
						if r then
							(r :: RemoteEvent):FireServer("Accept", f.Id)
						end
					end)
				end
			end
		end
	end
	local tracked = state.Tracked
	if tracked then
		local box = section(list, nextOrder(), if tracked.Kind == "Side" then "Misión opcional" else "Misión principal", H.Gold)
		Theme.title({ Size = UDim2.new(1, 0, 0, 26), Text = Strings.get(tracked.TitleKey), TextSize = 20, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = nextOrder(), Parent = box })
		if tracked.Later == "AfterSchool" then
			objectiveRow(box, nextOrder(), "🏫 " .. (laterStep(tracked) or ""), false, true)
		elseif tracked.Closed then
			objectiveRow(box, nextOrder(), ("🌙 %s está cerrado"):format(tracked.Closed.Name), false, true, opensText(tracked.Closed))
			objectiveRow(box, nextOrder(), "💤 Puedes dormir en tu cama para que pase antes el tiempo", false)
		end
		local children = tracked.Children or {}
		if #children > 0 then
			local firstPending = true
			for _, child in children do
				objectiveRow(box, nextOrder(), storyText(child.TextKey, child.Args), child.Done, not child.Done and firstPending)
				if not child.Done then
					firstPending = false
				end
			end
		else
			local text = storyText(tracked.TextKey, tracked.Args)
			objectiveRow(box, nextOrder(), if text ~= "" then text else stepFallback(tracked), false, true)
		end
	elseif state.Waiting then
		local waiting = state.Waiting
		local box = section(list, nextOrder(), "Misión principal", H.Gold)
		objectiveRow(box, nextOrder(), Strings.get(waiting.TitleKey), false, true)
		objectiveRow(box, nextOrder(), if waiting.Reason == "Hours" and waiting.From then ("🕗 Empieza a las %s (ahora está cerrado)"):format(hourText(waiting.From)) elseif waiting.Reason == "Hours" then "Podrás seguir más tarde." else Strings.get("STORY.WAIT.DAYS"), false)
		if waiting.Reason == "Hours" then
			objectiveRow(box, nextOrder(), "💤 Puedes dormir en tu cama para que pase antes el tiempo", false)
		end
	end
	-- La principal (si juegas una opcional) va en su propio apartado, no entre las opcionales
	local others, mains = {}, {}
	for _, other in state.Others or {} do
		table.insert(if other.Kind == "Main" then mains else others, other)
	end
	for _, main in mains do
		local box = section(list, nextOrder(), "Misión principal (en pausa)", H.Gold)
		-- «toca para volver» solo si de verdad se puede tocar; si no, el porqué (como las opcionales)
		local canPick = main.QuestId ~= nil and not main.Later
		local hint = if canPick then "toca para volver a ella" elseif main.Later == "AfterSchool" then "🏫 después del cole" elseif main.Later == "School" then "🏫 en horario de cole" else nil
		local row = objectiveRow(box, nextOrder(), Strings.get(main.TitleKey), false, false, hint)
		if canPick then
			local pick = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = row })
			pick.Activated:Connect(function()
				(Remotes:WaitForChild("LifeStory") :: RemoteEvent):FireServer("Track", main.QuestId)
			end)
		end
	end
	if #others > 0 then
		local box = section(list, nextOrder(), "Misiones opcionales", C.Purple)
		for i = 1, math.min(6, #others) do
			local other = others[i]
			-- Las que no tocan ahora siguen en la lista, con el porqué (no han desaparecido)
			local later = if other.Later == "AfterSchool" then "🏫 después del cole" elseif other.Later == "School" then "🏫 en horario de cole" elseif other.QuestId then "toca para seguirla" else nil
			local row = objectiveRow(box, nextOrder(), Strings.get(other.TitleKey), false, false, later)
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
	-- (opaca: antes se veían a través los letreros del mundo; del alto de lo que lleva: QuestPanel)
	local window = Theme.hudPanel({
		Name = "Quests",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(QuestPanel.Width, QuestPanel.MaxHeight),
		BackgroundTransparency = QuestPanel.Background,
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
		Name = "Lista",
		Position = UDim2.fromOffset(16, QuestPanel.Header),
		Size = UDim2.new(1, -32, 1, -(QuestPanel.Header + QuestPanel.Footer)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = window,
	})
	local list = create("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = scroll })
	local listLayout = create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	-- Trabajo actual: con su botón para dejarlo
	local jobRow = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -12), Size = UDim2.new(1, -32, 0, 50), BackgroundTransparency = 1, Parent = window })
	local jobText = Theme.label({ Size = UDim2.new(1, -160, 1, 0), TextSize = 14, TextWrapped = true, Parent = jobRow })
	local quit = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(150, 34), Text = "Dejar trabajo", TextSize = 14, BackgroundColor3 = rgb(140, 40, 50), Parent = jobRow })
	quit.Activated:Connect(function()
		(Remotes:WaitForChild("QuitJob") :: RemoteEvent):FireServer()
	end)
	-- El alto: el de lo que lleva (y la fila del trabajo si trabajas), con tope; si no cabe, se desplaza
	local function fitHeight()
		local content = 0
		pcall(function()
			content = (listLayout :: UIListLayout).AbsoluteContentSize.Y
		end)
		local job = jobRow.Visible
		scroll.Size = UDim2.new(1, -32, 1, -(QuestPanel.Header + QuestPanel.Footer + (if job then QuestPanel.JobRow else 0)))
		if content > 0 then
			-- (AbsoluteContentSize va en píxeles: se pasa a lienzo con la escala de la ventana)
			local k = 1
			pcall(function()
				if window.AbsoluteSize.X > 0 then
					k = math.max(window.AbsoluteSize.X / QuestPanel.Width, 0.01)
				end
			end)
			window.Size = UDim2.fromOffset(QuestPanel.Width, QuestPanel.height(content / k, job))
		end
	end
	local function paintJob()
		local jobId = player:GetAttribute("Job")
		local job = jobId and (Config.Jobs[jobId] or Gameplay.Jobs[jobId])
		jobRow.Visible = job ~= nil
		if job then
			jobText.Text = ("💼 %s · %s\n%s"):format(job.DisplayName, Format.money(job.Pay), player:GetAttribute("TaskText") or "")
		end
		fitHeight()
	end
	paintJob()
	pcall(function()
		(listLayout :: UIListLayout):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitHeight)
	end)
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
	-- "📍 Ruta a …" (tu ruta manda sobre la de la misión) y «Seguir misión ×» para volver a ella
	local route = create("Frame", { Name = "RouteChip", Position = UDim2.fromOffset(40, 5), Size = UDim2.fromOffset(346, 30), BackgroundColor3 = rgb(16, 70, 88), BackgroundTransparency = 0.1, Visible = false, ZIndex = 4, Parent = mission }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(90, 220, 255), Thickness = 1.5, Transparency = 0.2 }),
	})
	parts.Route = route
	parts.RouteText = Theme.label({ Name = "Text", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -150, 1, 0), Font = Theme.FontBold, TextSize = 16, TextColor3 = rgb(160, 240, 255), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5, Parent = route })
	local follow = create("TextButton", { Name = "Follow", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -3, 0.5, 0), Size = UDim2.fromOffset(136, 24), BackgroundColor3 = H.Gold, Text = "Seguir misión ×", TextSize = 14, Font = Theme.FontBold, TextColor3 = rgb(30, 24, 8), AutoButtonColor = true, ZIndex = 6, Parent = route }, {
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
			storySynced = true
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
		-- Pedir el estado hasta tenerlo: cada 3 s el primer minuto y luego cada 8 s, SIN rendirse (antes
		-- paraba a los 60 s, y si el servidor tardaba más en cargar la partida se quedaba en «CARGANDO
		-- TU PARTIDA…» para siempre)
		local tries = 0
		while not synced do
			pcall(remote.FireServer, remote, "Sync")
			tries += 1
			task.wait(if tries < 20 then 3 else 8)
		end
	end)
	player:GetAttributeChangedSignal("Job"):Connect(paintMission)
	player:GetAttributeChangedSignal("TaskText"):Connect(paintMission)
	-- (la invasión: el evento global y tus misiones de la invasión)
	local function invasionChanged()
		paintMission()
		if questList and questWindow and questWindow.Parent then
			renderQuestList(questList, storyState)
		end
	end
	player:GetAttributeChangedSignal("InvasionBook"):Connect(invasionChanged)
	local lastInvasionKey = ""
	workspace:GetAttributeChangedSignal("Invasion"):Connect(function()
		local st = invasionState()
		local key = if st then ("%s|%s|%s"):format(tostring(st.State), tostring(st.Wave), tostring(st.Text)) else ""
		if key ~= lastInvasionKey then
			lastInvasionKey = key
			invasionChanged()
		end
	end)
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
-- Valmar"; nil = ninguna) y qué hacer con «Seguir misión ×» (quitarla y volver a la misión)
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
-- Later: la misión está en pausa hasta luego («Tu misión X sigue mañana a las 8:30»).
export type Objective = { Kind: string, Title: string, Step: string, Place: string?, Target: Vector3?, Job: boolean, Key: string, Later: string? }
function Hud.objective(): Objective?
	local taskTarget = player:GetAttribute("TaskTarget")
	local jobId = player:GetAttribute("Job")
	local job = jobId and (Config.Jobs[jobId] or Gameplay.Jobs[jobId])
	local text = player:GetAttribute("TaskText")
	if job or (typeof(taskTarget) == "Vector3" and typeof(text) == "string") then
		local step = if typeof(text) == "string" and text ~= "" then text
			elseif job then ("Sigue con tu trabajo de %s"):format(job.DisplayName)
			else "Sigue con tu trabajo"
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
	local later = tracked and tracked.Later and Hud.laterText()
	return {
		Kind = summary.Kind,
		Title = summary.Title,
		Step = summary.Step,
		Place = place,
		Target = if later then nil elseif typeof(target) == "Vector3" then target else nil,
		Job = false,
		Key = summary.Title .. "|" .. summary.Step,
		Later = later or nil,
	}
end

-- ¿Ha llegado ya el estado de la historia? (antes, «¿Qué hago?» decía que no tenías misión)
function Hud.storySynced(): boolean
	return storySynced
end

-- Cuándo sigue tu misión si ahora está en pausa: «Tu misión «X» sigue mañana a las 8:30», «… sigue
-- al salir del cole (17:00)». nil si hay algo que hacer ya (o ninguna misión).
function Hud.laterText(): string?
	local tracked = storyState.Tracked
	local title, later, closed, from = nil, nil, nil, nil
	if tracked and tracked.Later then
		title, later, closed, from = Strings.get(tracked.TitleKey), tracked.Later, tracked.Closed, tracked.From
	elseif not tracked then
		for _, other in storyState.Others or {} do
			if other.Later then
				title, later = Strings.get(other.TitleKey), other.Later
				break
			end
		end
	end
	if not later then
		return nil
	end
	if later == "AfterSchool" then
		return ("Tu misión «%s» sigue al salir del cole (%s)"):format(title, hourText(if type(from) == "number" then from else Config.SchoolDay.End))
	end
	local opens = opensText(closed or { From = Config.SchoolDay.Opens, Weekdays = { 1, 2, 3, 4, 5 } })
	return ("Tu misión «%s» sigue %s"):format(title, (opens:gsub("^abre ", "")))
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
		line(5, "hablar", "Hablar · Coger…", "Con algo delante, el botón grande cambia a lo que se puede hacer (hablar, abrir, comer, coger…)")
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
	end, Hud.questsOpen)
end

-- Añade una opción al menú (la usa el cliente para la música, los sonidos, la ropa…). Sale en la app
-- Ajustes del ValPhone (Hud.menuToggles) y en la ventana MENÚ de siempre.
-- current (opcional): devuelve el texto de ahora, por si el ajuste cambia por otro lado (Hud.syncMenuToggles).
type MenuToggle = { Text: string, Order: number, Press: () -> string, Current: (() -> string)? }
local menuToggles: { MenuToggle } = {}
local menuButtons: { [MenuToggle]: TextButton } = {}
local menuLabels: { [MenuToggle]: TextLabel } = {} -- (los de − / +: su texto)
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

-- Un ajuste con − / + (los volúmenes: «🎵 Música: 7», de 0 a 10). step(delta) cambia un paso (−1 o +1;
-- quien lo llama no se sale de 0 … 10) y devuelve el texto nuevo. En la app Ajustes sale con sus
-- botones − y + grandes (UI/Phone, ≥ 44 px, cómodos en el móvil) y en la ventana MENÚ igual.
-- Press (tocar la fila, Enter o el botón A) = un paso más.
function Hud.addMenuStepper(text: string, order: number, step: (delta: number) -> string, current: (() -> string)?)
	local content = menu:FindFirstChild("Content") :: Frame
	local row = create("Frame", { Name = "Stepper", Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = H.NavyLight, BackgroundTransparency = 0.5, LayoutOrder = order, ZIndex = 31, Parent = content }, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
	local label = Theme.label({ Name = "Label", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -112, 1, 0), Text = text, Font = Theme.FontBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 32, Parent = row })
	local minus = Theme.button({ Name = "Minus", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0), Size = UDim2.fromOffset(44, 44), Text = "−", TextSize = 22, ZIndex = 32, Parent = row })
	local plus = Theme.button({ Name = "Plus", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(44, 44), Text = "+", TextSize = 22, ZIndex = 32, Parent = row })
	local entry: MenuToggle
	local function stepBy(delta: number): string
		local now = step(delta)
		entry.Text = now
		label.Text = now
		return now
	end
	entry = {
		Text = text,
		Order = order,
		Press = function(): string
			return stepBy(1)
		end,
		Current = current,
	};
	(entry :: any).Step = stepBy;
	(entry :: any).Stepper = true
	table.insert(menuToggles, entry)
	menuLabels[entry] = label
	minus.Activated:Connect(function()
		stepBy(-1)
	end)
	plus.Activated:Connect(function()
		stepBy(1)
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
				local button = menuButtons[entry] or menuLabels[entry]
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

-- Cierra el menú, los controles y las misiones (una conversación que empieza)
function Hud.closePopups()
	Hud.closeMenu()
	if controlsPanel and controlsPanel.Visible then
		controlsPanel.Visible = false
	end
	if questWindow and questWindow.Parent then
		openQuests() -- (con la ventana abierta, la cierra)
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
	Hint = C.Muted,
	Sleep = C.Muted,
}

-- Avisos a la vista (el más viejo primero) y cuándo salió cada texto: el mismo aviso repetido
-- (p. ej. al mantener una tecla) no se amontona, y nunca hay más de unos pocos a la vez
local TOAST_MAX = 4
-- Ancho máximo del texto de un aviso (dentro de la lista de 600: 560 + los márgenes del aviso)
Hud.ToastMaxWidth = 560
local TOAST_REPEAT = 2
local activeToasts: { Frame } = {}
local recentToasts: { [string]: { At: number, Slot: Frame } } = {}

-- (en conversaciones, narraciones y cinemáticas los avisos esperan y salen al acabar: Hud.setBusy)
local TOAST_QUEUE_MAX = 4
local queuedToasts: { { string } } = {}

-- PISTAS (kind "Hint": cómo despegar, cómo posarse, «fija un enemigo primero»…): de una en una (la nueva
-- quita la de antes) y la misma no vuelve a salir en Hud.HintRepeat segundos. En el vídeo del dueño en
-- Tefra (v117) salían cinco a la vez, dos de ellas diciendo lo mismo, y se repetían cada pocos segundos.
Hud.HintRepeat = 25
local hintSeen: { [string]: number } = {}
local hintSlot: Frame? = nil

function Hud.toast(kind: string, text: string)
	if busy then
		for _, waiting in queuedToasts do
			if waiting[2] == text then
				return
			end
		end
		table.insert(queuedToasts, { kind, text })
		while #queuedToasts > TOAST_QUEUE_MAX do
			table.remove(queuedToasts, 1)
		end
		return
	end
	local now = os.clock()
	local recent = recentToasts[text]
	if recent and now - recent.At < TOAST_REPEAT and recent.Slot.Parent ~= nil then
		return
	end
	local hint = kind == "Hint"
	if hint then
		local seen = hintSeen[text]
		if seen and now - seen < Hud.HintRepeat then
			return
		end
		hintSeen[text] = now
		for old, at in hintSeen do
			if now - at > Hud.HintRepeat * 4 then
				hintSeen[old] = nil
			end
		end
		local previous = hintSlot
		if previous and previous.Parent ~= nil then
			previous:Destroy() -- (de una en una: la nueva sustituye a la de antes)
		end
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
	-- (los avisos largos —«🪐 Tefra. Para posarte, FRENA cerca del suelo…», de 150 letras— iban en una
	-- sola línea y en el móvil se salían de la pantalla por los dos lados: ahora como mucho
	-- Hud.ToastMaxWidth de ancho y el resto baja a otra línea)
	local slot = create("Frame", { Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Parent = toastList })
	table.insert(activeToasts, slot)
	recentToasts[text] = { At = now, Slot = slot }
	if hint then
		hintSlot = slot
	end
	local toast = create("CanvasGroup", {
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.XY,
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
	local line = Theme.label({
		Name = "Text",
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.XY,
		Text = text,
		TextWrapped = true,
		FontFace = Theme.ItalicFace,
		TextColor3 = C.Text,
		Parent = toast,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(Hud.ToastMaxWidth, math.huge), Parent = line })
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = line })
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
	status.Visible = show and not shipFocus
	local clock = gui:FindFirstChild("Clock")
	if clock and clock:IsA("GuiObject") then
		clock.Visible = not shipFocus
	end
	if mission then
		-- (a los mandos de la nave, la tarjeta de misión estorba: UI/FlightFocus)
		-- (y en otro planeta, la de Valmar tampoco: «Las tres Valmar · Portal del parque» en Tefra)
		mission.Visible = show and hasMission and not flightFocus and zoneFocus == nil
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
	HudLayout.apply(status, if statusOpen then items.StatusOpen else items.Status)
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
	-- (DisplayOrder 5: por encima de los botones táctiles —4—, que antes quedaban encima de la ventana)
	popupGui = create("ScreenGui", { Name = "HudPopups", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
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
	TopStack.onChanged(placeToasts)

	-- La pantalla negra de dormir va en su propio ScreenGui (sin UIScale) para cubrirlo todo
	local overlayGui = create("ScreenGui", { Name = "SleepOverlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10, Parent = playerGui })
	sleepOverlay = create("Frame", { Name = "Sleep", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false, Parent = overlayGui })
	Theme.title({ Name = "Caption", Size = UDim2.fromScale(1, 1), Text = "Zzz...", TextSize = 40, TextXAlignment = Enum.TextXAlignment.Center, Parent = sleepOverlay })

	player:GetAttributeChangedSignal("LifeStage"):Connect(refreshVisible)
	refreshVisible()

	return gui
end

-- A los mandos de la nave (UI/FlightFocus): sin la tarjeta de misión (tu estado y la hora se quedan)
function Hud.setFlightFocus(value: boolean)
	flightFocus = value
	refreshVisible()
end

-- En otro planeta (UI/FlightFocus.setZone, Controllers/EnvDirector): "Planeta" o nil
function Hud.setZoneFocus(value: string?)
	zoneFocus = value
	refreshVisible()
end

-- En la nave del espacio (Controllers/AirCombatClient): el HUD de la nave (UI/AirCombatHud) trae el perfil
-- (zona A) y la brújula (zona B), así que tu estado y la cápsula de la hora se apartan mientras pilotas
function Hud.setShipFocus(value: boolean)
	shipFocus = value
	refreshVisible()
end

-- Mientras hablas con alguien o ves una cinemática, lo que tapa la escena se aparta
function Hud.setBusy(value: boolean)
	busy = value
	refreshVisible()
	TouchLayout.setBusy(value)
	-- (y los avisos de arriba: fuera mientras tanto; los que llegaron, al acabar)
	TopStack.setBusy(value)
	if toastList then
		toastList.Visible = not value
	end
	if not value and #queuedToasts > 0 then
		local waiting = queuedToasts
		queuedToasts = {}
		for _, entry in waiting do
			Hud.toast(entry[1], entry[2])
		end
	end
end

return Hud
