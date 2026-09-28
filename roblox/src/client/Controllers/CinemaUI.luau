-- CinemaUI (cliente): los cines.
--   * La PANTALLA de cada sala enseña la película de la sesión (escenas con dibujo y texto), la
--     cuenta atrás antes de empezar y el descanso. La pantalla de HORARIOS del vestíbulo y los
--     CARTELES también. Todo se calcula con la hora del servidor: todos ven lo mismo a la vez.
--   * En la taquilla: cuántas entradas y qué de la barra (palomitas, refresco, nachos).
--   * Taquillero/a: panel con los pedidos; para imprimir las entradas eliges la película y cuántas.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Format = require(ReplicatedStorage.Shared.Format)
local Cinema = require(ReplicatedStorage.Shared.Cinema)

local CinemaUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Cinema") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

---------------------------------------------------------------------
-- Pantallas, horarios y carteles
---------------------------------------------------------------------
type Screen = { Frame: Frame, Icon: TextLabel, Text: TextLabel, Title: TextLabel }
local screens: { [BasePart]: Screen } = {}
local boards: { [BasePart]: TextLabel } = {}

local function surface(part: BasePart, pixels: number?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixels or 25
	gui.LightInfluence = 0
	gui.Parent = part
	return gui
end

local function addScreen(part: Instance)
	if not part:IsA("BasePart") or screens[part] then
		return
	end
	local gui = surface(part, 20)
	local frame = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(10, 10, 14), BorderSizePixel = 0, Parent = gui })
	local title = create("TextLabel", { Size = UDim2.fromScale(1, 0.14), Position = UDim2.fromScale(0, 0.03), BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.GothamBold, TextColor3 = rgb(255, 214, 90), Text = "", Parent = frame })
	local icon = create("TextLabel", { Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.2), BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.GothamBold, Text = "", Parent = frame })
	local text = create("TextLabel", { Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.74), BackgroundTransparency = 1, TextScaled = true, TextWrapped = true, Font = Enum.Font.GothamMedium, TextColor3 = rgb(250, 250, 250), Text = "", Parent = frame })
	screens[part] = { Frame = frame, Icon = icon, Text = text, Title = title }
end

local function addBoard(part: Instance)
	if not part:IsA("BasePart") or boards[part] then
		return
	end
	local gui = surface(part, 30)
	boards[part] = create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(18, 16, 24), TextScaled = true, TextWrapped = true, RichText = true, Font = Enum.Font.GothamBold, TextColor3 = rgb(255, 214, 90), Text = "", Parent = gui })
end

local function addPoster(part: Instance)
	if not part:IsA("BasePart") or part:FindFirstChildOfClass("SurfaceGui") then
		return
	end
	local film = Cinema.Films[part:GetAttribute("FilmIndex") or 1]
	if not film then
		return
	end
	-- Los carteles miran hacia +X (pared izquierda del vestíbulo)
	local gui = surface(part, 30)
	gui.Face = Enum.NormalId.Right
	local frame = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = film.Poster, BorderSizePixel = 0, Parent = gui })
	create("TextLabel", { Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.08), BackgroundTransparency = 1, TextScaled = true, Text = film.Icon, Parent = frame })
	create("TextLabel", { Size = UDim2.fromScale(0.9, 0.22), Position = UDim2.fromScale(0.05, 0.6), BackgroundTransparency = 1, TextScaled = true, TextWrapped = true, Font = Enum.Font.GothamBlack, TextColor3 = rgb(255, 255, 255), Text = string.upper(film.Title), Parent = frame })
	create("TextLabel", { Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, 0.86), BackgroundTransparency = 1, TextScaled = true, Font = Enum.Font.GothamMedium, TextColor3 = rgb(255, 230, 150), Text = film.Genre, Parent = frame })
end

local function refreshScreens()
	local t = workspace:GetServerTimeNow()
	local film, phase, value = Cinema.session(t)
	local nextFilm = Cinema.session(t + Cinema.Cycle)
	for part, s in screens do
		if not part.Parent then
			screens[part] = nil
			continue
		end
		if phase == "Entry" then
			s.Frame.BackgroundColor3 = film.Poster:Lerp(Color3.new(0, 0, 0), 0.5)
			s.Title.Text = "PRÓXIMA SESIÓN"
			s.Icon.Text = film.Icon
			s.Text.Text = ("«%s» empieza en %d s · apagad los móviles 📵"):format(film.Title, math.ceil(value))
		elseif phase == "Film" then
			local per = Cinema.FilmSeconds / #film.Scenes
			local scene = film.Scenes[math.min(#film.Scenes, math.floor(value / per) + 1)]
			s.Frame.BackgroundColor3 = scene.Color
			s.Title.Text = ""
			s.Icon.Text = scene.Icon
			s.Text.Text = scene.Text
		else
			s.Frame.BackgroundColor3 = rgb(10, 10, 14)
			s.Title.Text = "DESCANSO"
			s.Icon.Text = "🍿"
			s.Text.Text = ("Próxima película: «%s»"):format(nextFilm.Title)
		end
	end
	local status = if phase == "Entry" then ("ENTRADA · empieza en %d s"):format(math.ceil(value)) elseif phase == "Film" then "EN PANTALLA" else "DESCANSO"
	for part, label in boards do
		if not part.Parent then
			boards[part] = nil
			continue
		end
		label.Text = ("🎬 SALA 1\n%s %s\n<font size=\"20\">%s</font>\nDespués: %s %s"):format(film.Icon, film.Title, status, nextFilm.Icon, nextFilm.Title)
	end
end

---------------------------------------------------------------------
-- Comprar en la taquilla
---------------------------------------------------------------------
local function openMenu(menu: { [string]: any })
	local count = 1
	local chosen: { string } = {}
	local window, content, close = Dialog.window("CinemaMenu", "🎟️ Taquilla", Vector2.new(440, 330))
	Theme.label({
		Size = UDim2.new(1, 0, 0, 40),
		Text = ("%s Próxima sesión: <b>%s</b>%s"):format(menu.Icon, menu.Title, if menu.Staff then ("\nTe atiende %s."):format(menu.Staff) else ""),
		RichText = true,
		TextSize = 14,
		TextWrapped = true,
		Parent = content,
	})
	local row = create("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = row })
	Theme.label({ Size = UDim2.fromOffset(110, 36), Text = ("Entradas (%s):"):format(Format.money(menu.Price)), TextSize = 13, Parent = row })
	local countButtons = {}
	local snackRow = create("Frame", { Position = UDim2.fromOffset(0, 90), Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = snackRow })
	local summary = Theme.label({ Position = UDim2.new(0, 0, 1, -80), Size = UDim2.new(1, 0, 0, 26), Text = "", TextSize = 14, Parent = content })
	local pay = Theme.button({ Position = UDim2.new(0, 0, 1, -44), Size = UDim2.new(1, 0, 0, 40), Text = "Pagar", TextSize = 16, BackgroundColor3 = C.Accent, Parent = content })
	local snackButtons = {}
	local function refresh()
		local total = menu.Price * count
		for _, id in chosen do
			for _, s in menu.Snacks do
				if s.Id == id then
					total += s.Price
				end
			end
		end
		for n, b in countButtons do
			b.BackgroundColor3 = if n == count then C.Accent else rgb(50, 52, 60)
		end
		for id, b in snackButtons do
			b.BackgroundColor3 = if table.find(chosen, id) then C.Accent else rgb(50, 52, 60)
		end
		summary.Text = ("%d × 🎟️%s   ·   Total %s"):format(count, if #chosen > 0 then " + barra" else "", Format.money(total))
	end
	for n = 1, 4 do
		local b = Theme.button({ Size = UDim2.fromOffset(44, 36), Text = tostring(n), TextSize = 16, Parent = row })
		countButtons[n] = b
		b.Activated:Connect(function()
			count = n
			refresh()
		end)
	end
	for _, s in menu.Snacks do
		local b = Theme.button({ Size = UDim2.fromOffset(136, 40), Text = ("%s %s %s"):format(s.Icon, s.Name, Format.money(s.Price)), TextSize = 12, TextWrapped = true, Parent = snackRow })
		snackButtons[s.Id] = b
		b.Activated:Connect(function()
			local at = table.find(chosen, s.Id)
			if at then
				table.remove(chosen, at)
			else
				table.insert(chosen, s.Id)
			end
			refresh()
		end)
	end
	pay.Activated:Connect(function()
		Remote:FireServer("Buy", count, chosen)
		window:Destroy()
	end)
	close.Activated:Connect(function()
		window:Destroy()
	end)
	refresh()
end

---------------------------------------------------------------------
-- Panel del taquillero
---------------------------------------------------------------------
local panel: Frame
local list: Frame
local pick = { Film = nil :: string?, Count = 1 }

local function showWork(orders: { any }, films: { any })
	panel.Visible = true
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
	if #orders == 0 then
		Theme.label({ Size = UDim2.new(1, 0, 0, 40), Text = "Sin clientes. Espera en la taquilla.", TextSize = 13, TextColor3 = C.Muted, LayoutOrder = nextOrder(), Parent = list })
	end
	for i, o in orders do
		local wait = o.Wait
		Theme.label({
			Size = UDim2.new(1, 0, 0, if i == 1 then 40 else 20),
			Text = ("%s<b>%s</b> (%d s): %s"):format(if i == 1 then "➡️ " else "", o.Name, wait, o.Text),
			RichText = true,
			TextWrapped = true,
			TextSize = if i == 1 then 13 else 11,
			TextColor3 = if i == 1 then rgb(255, 230, 170) else C.Muted,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
		if i == 1 then
			if not o.Printed then
				Theme.label({ Size = UDim2.new(1, 0, 0, 18), Text = "1) Película y cuántas entradas:", TextSize = 12, LayoutOrder = nextOrder(), Parent = list })
				for _, f in films do
					local b = Theme.button({ Size = UDim2.new(1, 0, 0, 26), Text = f.Icon .. " " .. f.Title, TextSize = 12, LayoutOrder = nextOrder(), BackgroundColor3 = if pick.Film == f.Id then C.Accent else rgb(50, 52, 60), Parent = list })
					b.Activated:Connect(function()
						pick.Film = f.Id
						b.BackgroundColor3 = C.Accent
					end)
				end
				local row = create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = list })
				create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = row })
				for n = 1, 4 do
					local b = Theme.button({ Size = UDim2.fromOffset(40, 28), Text = tostring(n), TextSize = 14, BackgroundColor3 = if pick.Count == n then C.Accent else rgb(50, 52, 60), Parent = row })
					b.Activated:Connect(function()
						pick.Count = n
						b.BackgroundColor3 = C.Accent
					end)
				end
				local print_ = Theme.button({ Size = UDim2.new(1, 0, 0, 30), Text = "🖨️ Imprimir entradas", TextSize = 14, LayoutOrder = nextOrder(), BackgroundColor3 = rgb(150, 24, 36), Parent = list })
				print_.Activated:Connect(function()
					if pick.Film then
						Remote:FireServer("Print", pick.Film, pick.Count)
					end
				end)
			else
				local lines = { "✅ Entradas impresas" }
				for _, s in o.Snacks do
					table.insert(lines, (if s.Done then "✅ " else "⬜ ") .. s.Icon .. " " .. s.Name)
				end
				table.insert(lines, "➡️ Entrega el pedido en la taquilla")
				Theme.label({ Size = UDim2.new(1, 0, 0, #lines * 17), Text = table.concat(lines, "\n"), TextSize = 12, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = nextOrder(), Parent = list })
			end
		end
	end
end

function CinemaUI.init()
	local gui = create("ScreenGui", { Name = "CinemaGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	panel = Theme.panel({
		Name = "Taquilla",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(290, 400),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "🎟️ Taquilla · pedidos", Font = Theme.FontBold, TextSize = 16, Parent = panel })
	list = create("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 1, -26), BackgroundTransparency = 1, Parent = panel })
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	Remote.OnClientEvent:Connect(function(action, a, b)
		if action == "Menu" then
			openMenu(a)
		elseif action == "Work" then
			showWork(a, b)
		elseif action == "Start" then
			panel.Visible = true
		elseif action == "Stop" then
			panel.Visible = false
		end
	end)
	player:GetAttributeChangedSignal("Job"):Connect(function()
		if player:GetAttribute("Job") ~= "Taquillero" then
			panel.Visible = false
		end
	end)

	for tag, fn in { CinemaScreen = addScreen, CinemaSchedule = addBoard, CinemaPoster = addPoster } do
		for _, part in CollectionService:GetTagged(tag) do
			fn(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
	end
	task.spawn(function()
		while true do
			refreshScreens()
			task.wait(0.5)
		end
	end)
end

return CinemaUI
