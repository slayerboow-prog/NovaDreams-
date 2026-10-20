-- Cinemateca (cliente, modo pruebas): ver TODAS las escenas del juego una por una y decir si están bien.
-- La abre el panel de pruebas (TesterPanel → «🎞️ Cinemateca»). El servidor decide todo
-- (server/Services/CinematecaService, por el remoto Tester): la lista, quién puede, poner la escena en
-- modo sandbox (sin tocar tu partida), llevarte a su sitio y devolverte después. Aquí solo se pide y se
-- enseña.
--
-- Ventana: buscador, contador («37 / 2622»), la lista por grupos (saga, capítulo, planeta) y los botones
-- ⏮ Anterior · ▶ Ver · ⏭ Siguiente · ↺ Repetir. Al acabar cada escena (o al saltarla), la barra de revisión:
-- ✅ Bien / ❌ Mal + nota corta; se manda con el contexto (escena, plano en que iba, segundo, dispositivo).

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Dialog = require(script.Parent.Dialog)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud

local Cinemateca = {}

local NAME = "Cinemateca"
local MAX_ROWS = 120 -- filas a la vez (en el móvil, más se arrastra)

local remote: RemoteEvent? = nil
local list: { { [string]: any } } = {} -- { I, K, T, G, C } (Cinemateca.brief del servidor)
local verdicts: { [string]: string } = {}
local selected = 1
local query = ""
local window: Frame? = nil
local ui: { [string]: any } = {}
local pendingReview: { [string]: any }? = nil

function Cinemateca.setRemote(r: RemoteEvent?)
	remote = r
end

local function send(op: string, extra: { [string]: any }?)
	if not remote then
		return
	end
	local payload = extra or {}
	payload.Op = op
	remote:FireServer("Action", "Cinemateca", payload)
end
Cinemateca._send = send

local function norm(text: string): string
	local s = text:lower()
	for from, to in { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n" } do
		s = s:gsub(from, to)
	end
	return s
end

-- Lo que se ve con la búsqueda de ahora
function Cinemateca.filtered(): { { [string]: any } }
	local q = norm(query):gsub("^%s+", ""):gsub("%s+$", "")
	if q == "" then
		return list
	end
	local out = {}
	for _, e in list do
		if norm(tostring(e.T) .. " " .. tostring(e.G)):find(q, 1, true) then
			table.insert(out, e)
		end
	end
	return out
end

function Cinemateca.counterText(): string
	local shown = Cinemateca.filtered()
	local done = 0
	for _ in verdicts do
		done += 1
	end
	return ("%d / %d"):format(selected, #list) .. (if #shown ~= #list then (" · %d encontradas"):format(#shown) else "") .. (" · revisadas %d"):format(done)
end

local function mark(entry: { [string]: any }): string
	local v = verdicts[entry.K]
	return if v == "Bien" then "✅ " elseif v == "Mal" then "❌ " else ""
end

local refresh: () -> ()

local function rows()
	local holder = ui.Rows
	if not holder then
		return
	end
	for _, child in holder:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local shown = Cinemateca.filtered()
	-- (empieza cerca de la seleccionada: la lista entera no cabe en un móvil)
	local start = 1
	for i, e in shown do
		if e.I == selected then
			start = math.max(1, i - 10)
			break
		end
	end
	local group = nil
	local order = 0
	for i = start, math.min(#shown, start + MAX_ROWS - 1) do
		local e = shown[i]
		if e.G ~= group then
			group = e.G
			order += 1
			Theme.label({
				Size = UDim2.new(1, 0, 0, 24),
				Text = tostring(group),
				Font = Theme.FontBold,
				TextSize = 14,
				TextColor3 = H.Glow,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = order,
				Parent = holder,
			})
		end
		order += 1
		local b = Theme.button({
			Name = "Fila_" .. tostring(e.I),
			Size = UDim2.new(1, 0, 0, 40),
			Text = ("%s%d · %s"):format(mark(e), e.I, tostring(e.T)),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundColor3 = if e.I == selected then H.Glow else H.NavyLight,
			LayoutOrder = order,
			Parent = holder,
		})
		b.Activated:Connect(function()
			selected = e.I
			refresh()
		end)
	end
end

function refresh()
	if ui.Counter then
		ui.Counter.Text = Cinemateca.counterText()
	end
	local entry = list[selected]
	if ui.Now then
		ui.Now.Text = if entry then ("%s%s"):format(mark(entry), tostring(entry.T)) else "—"
	end
	rows()
end

-- La barra de revisión (después de cada escena)
local function showReview(on: boolean)
	if ui.Review then
		ui.Review.Visible = on
	end
end

local function sendReview(ok: boolean)
	local r = pendingReview
	if not r then
		return
	end
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize
	send("Review", {
		Key = r.Key,
		Ok = ok,
		Note = if ui.Note and ui.Note.Text ~= "" then ui.Note.Text else nil,
		Shot = r.Shot,
		Shots = r.Shots,
		T = r.T,
		Skipped = r.Skipped,
		Device = ("%s %dx%d"):format(if UserInputService.TouchEnabled then "Móvil" else "PC", if viewport then math.floor(viewport.X) else 0, if viewport then math.floor(viewport.Y) else 0),
	})
	verdicts[r.Key] = if ok then "Bien" else "Mal"
	pendingReview = nil
	if ui.Note then
		ui.Note.Text = ""
	end
	showReview(false)
	refresh()
end
Cinemateca._sendReview = sendReview

local function build()
	local frame, content = Dialog.window(NAME, "🎞️ Cinemateca", Vector2.new(520, 640))
	window = frame
	frame.Destroying:Connect(function()
		if window == frame then
			window = nil
			ui = {}
			send("Close")
		end
	end)
	local column = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = column })
	local search = create("TextBox", {
		Name = "Buscar",
		Size = UDim2.new(1, 0, 0, 40),
		PlaceholderText = "🔍 Buscar (id, misión, capítulo…)",
		Text = query,
		ClearTextOnFocus = false,
		TextSize = 16,
		Font = Theme.Font,
		TextColor3 = C.Text,
		BackgroundColor3 = H.NavyLight,
		LayoutOrder = 1,
		Parent = column,
	})
	search:GetPropertyChangedSignal("Text"):Connect(function()
		query = search.Text
		rows()
		if ui.Counter then
			ui.Counter.Text = Cinemateca.counterText()
		end
	end)
	ui.Search = search
	ui.Counter = Theme.label({ Name = "Contador", Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextColor3 = C.Muted, LayoutOrder = 2, Parent = column })
	ui.Now = Theme.label({ Name = "Ahora", Size = UDim2.new(1, 0, 0, 22), Font = Theme.FontBold, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 3, Parent = column })
	-- Botones (grandes, para el dedo)
	local bar = create("Frame", { Name = "Mandos", Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = 4, Parent = column })
	create("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, 46), CellPadding = UDim2.fromOffset(6, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	local function control(name: string, text: string, order: number, fn: () -> ())
		local b = Theme.button({ Name = name, Text = text, TextSize = 16, BackgroundColor3 = H.NavyLight, LayoutOrder = order, Parent = bar })
		Theme.touchText(b, 16)
		b.Activated:Connect(fn)
		return b
	end
	control("Anterior", "⏮ Anterior", 1, function()
		showReview(false)
		send("Prev")
	end)
	control("Ver", "▶ Ver", 2, function()
		showReview(false)
		send("Play", { Index = selected })
	end)
	control("Siguiente", "⏭ Siguiente", 3, function()
		showReview(false)
		send("Next")
	end)
	control("Repetir", "↺ Repetir", 4, function()
		showReview(false)
		send("Replay")
	end)
	-- Revisión
	local review = create("Frame", { Name = "Revision", Size = UDim2.new(1, 0, 0, 96), BackgroundTransparency = 1, Visible = false, LayoutOrder = 5, Parent = column })
	ui.Review = review
	ui.Note = create("TextBox", {
		Name = "Nota",
		Size = UDim2.new(1, 0, 0, 40),
		PlaceholderText = "Nota corta (opcional): qué falla",
		Text = "",
		ClearTextOnFocus = false,
		TextSize = 15,
		Font = Theme.Font,
		TextColor3 = C.Text,
		BackgroundColor3 = H.NavyLight,
		Parent = review,
	})
	local verdict = create("Frame", { Size = UDim2.new(1, 0, 0, 48), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, Parent = review })
	create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 46), CellPadding = UDim2.fromOffset(8, 0), Parent = verdict })
	local good = Theme.button({ Name = "Bien", Text = "✅ Bien", TextSize = 17, BackgroundColor3 = Color3.fromRGB(0, 140, 80), Parent = verdict })
	local bad = Theme.button({ Name = "Mal", Text = "❌ Mal", TextSize = 17, BackgroundColor3 = Color3.fromRGB(170, 40, 40), Parent = verdict })
	good.Activated:Connect(function()
		sendReview(true)
	end)
	bad.Activated:Connect(function()
		sendReview(false)
	end)
	-- La lista
	local scroll = create("ScrollingFrame", {
		Name = "Lista",
		Size = UDim2.new(1, 0, 1, -230),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = if Theme.isTouch() then 8 else 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		LayoutOrder = 6,
		Parent = column,
	})
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	ui.Rows = scroll
	-- Exportar (lo que se ha revisado, también en el registro del servidor)
	local export = Theme.button({ Name = "Exportar", Size = UDim2.new(1, 0, 0, 40), Text = "📋 Ver revisiones (y al registro del servidor)", TextSize = 14, BackgroundColor3 = H.NavyLight, LayoutOrder = 7, Parent = column })
	export.Activated:Connect(function()
		send("Export")
	end)
	ui.Export = Theme.label({ Name = "Revisiones", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 13, TextWrapped = true, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Left, Text = "", LayoutOrder = 8, Parent = column })
	refresh()
end

function Cinemateca.isOpen(): boolean
	return window ~= nil and window.Parent ~= nil
end

-- Abre la ventana y pide la lista al servidor
function Cinemateca.open()
	if not Cinemateca.isOpen() then
		build()
	end
	send("Open")
end

function Cinemateca.close()
	if window and window.Parent then
		window:Destroy()
	end
	window = nil
end

function Cinemateca.selected(): number
	return selected
end

-- Mensajes del servidor (TesterPanel los pasa: remoto Tester, tipo «Cinemateca»)
function Cinemateca.onMessage(payload: { [string]: any })
	local op = payload.Op
	if op == "List" and type(payload.List) == "table" then
		list = payload.List
		verdicts = if type(payload.Verdicts) == "table" then payload.Verdicts else verdicts
		selected = math.clamp(selected, 1, math.max(1, #list))
		refresh()
	elseif op == "Started" then
		if type(payload.Index) == "number" then
			selected = payload.Index
		end
		showReview(false)
		refresh()
	elseif op == "Ended" then
		local entry = list[tonumber(payload.Index) or selected]
		local key = payload.Key or (entry and entry.K)
		pendingReview = { Key = key, Skipped = payload.Skipped == true }
		showReview(true)
		refresh()
		-- (el plano en que iba: lo que vio esta pantalla, cuando la escena acaba de recogerse)
		task.spawn(function()
			local ok, scenes = pcall(function()
				return require(script.Parent.Parent.Controllers.HappeningClient) :: any
			end)
			if not ok or type(scenes) ~= "table" then
				return
			end
			local deadline = os.clock() + 3
			while os.clock() < deadline and scenes.isPlaying() do
				task.wait(0.1)
			end
			local info = scenes.lastRun()
			local id = type(key) == "string" and key:match("^E:(.+)$")
			if pendingReview and pendingReview.Key == key and info and id and info.Id == id then
				pendingReview.Shot, pendingReview.Shots, pendingReview.T = info.Shot, info.Shots, info.T
			end
		end)
	elseif op == "Reviewed" and type(payload.Key) == "string" then
		verdicts[payload.Key] = payload.Verdict
		refresh()
	elseif op == "Export" and ui.Export then
		ui.Export.Text = tostring(payload.Text or "")
	end
end

-- (pruebas)
function Cinemateca._state(): { [string]: any }
	return { List = list, Selected = selected, Pending = pendingReview, Verdicts = verdicts, Ui = ui }
end
function Cinemateca._setQuery(text: string)
	query = text
	if ui.Search then
		ui.Search.Text = text
	end
	rows()
end

return Cinemateca
