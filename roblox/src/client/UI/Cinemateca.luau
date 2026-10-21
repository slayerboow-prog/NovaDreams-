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

-- COMENTAR (v125.5: en el móvil no se podía comentar). Una pantalla aparte, «CinematecaComentar», que
-- ninguna escena apaga (UI/SceneGuis.Keep), arriba (el teclado del móvil sale abajo y no la tapa):
--   * mientras se ve una escena, el botón «💬 Comentar» (debajo de «Saltar»): para la escena y abre la caja;
--   * al acabar (o al saltarla), la caja se abre sola.
-- La caja: etiquetas rápidas, una nota corta, ✅ Bien / ❌ Mal, y ⏭ Siguiente / ↺ Repetir / ↩ Seguir.
local TAGS = { "Cámara mal", "Actores mal colocados", "Lugar equivocado", "Aburrida", "Texto tapa", "Otro" }
local overlay: { [string]: any } = {}
local playing = false -- (hay una escena de la Cinemateca en marcha)
local paused = false -- (se paró para comentar)
local chosenTags: { [string]: boolean } = {}

local function device(): string
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize
	return ("%s %dx%d"):format(if UserInputService.TouchEnabled then "Móvil" else "PC", if viewport then math.floor(viewport.X) else 0, if viewport then math.floor(viewport.Y) else 0)
end

local function buildOverlay()
	if overlay.Gui and overlay.Gui.Parent then
		return
	end
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local gui = create("ScreenGui", {
		Name = "CinematecaComentar",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 70, -- (encima de la escena: 52)
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	pcall(function()
		(gui :: any).ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	overlay.Gui = gui
	local comment = Theme.button({
		Name = "Comentar",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0.11, 8), -- (debajo de la banda de arriba y de «Saltar»)
		Size = UDim2.fromOffset(150, 44),
		Text = "💬 Comentar",
		TextSize = 17,
		BackgroundColor3 = Color3.fromRGB(70, 50, 140),
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})
	overlay.Comment = comment
	local panel = create("Frame", {
		Name = "Caja",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.12, 0),
		Size = UDim2.new(0.94, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.05,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(560, 2000), Parent = panel })
	Theme.corner(10).Parent = panel
	Theme.padding(10).Parent = panel
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	overlay.Panel = panel
	overlay.Title = Theme.label({ Name = "Titulo", Size = UDim2.new(1, 0, 0, 24), Font = Theme.FontBold, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, ZIndex = 11, Parent = panel })
	local tags = create("Frame", { Name = "Etiquetas", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 11, Parent = panel })
	create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 40), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tags })
	overlay.TagButtons = {}
	for i, tag in TAGS do
		local b = Theme.button({ Name = "Etiqueta_" .. i, Text = tag, TextSize = 15, BackgroundColor3 = H.NavyLight, LayoutOrder = i, ZIndex = 12, Parent = tags })
		overlay.TagButtons[tag] = b
		b.Activated:Connect(function()
			chosenTags[tag] = not chosenTags[tag] or nil
			b.BackgroundColor3 = if chosenTags[tag] then Color3.fromRGB(170, 110, 20) else H.NavyLight
			b.Text = (if chosenTags[tag] then "✓ " else "") .. tag
		end)
	end
	overlay.Note = create("TextBox", {
		Name = "Nota",
		Size = UDim2.new(1, 0, 0, 44),
		PlaceholderText = "Nota corta (opcional): qué falla",
		Text = "",
		ClearTextOnFocus = false,
		TextSize = 16,
		Font = Theme.Font,
		TextColor3 = C.Text,
		BackgroundColor3 = H.NavyLight,
		LayoutOrder = 3,
		ZIndex = 11,
		Parent = panel,
	})
	local verdict = create("Frame", { Name = "Veredicto", Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = 4, ZIndex = 11, Parent = panel })
	create("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 46), CellPadding = UDim2.fromOffset(8, 0), Parent = verdict })
	overlay.Good = Theme.button({ Name = "Bien", Text = "✅ Bien", TextSize = 18, BackgroundColor3 = Color3.fromRGB(0, 140, 80), ZIndex = 12, Parent = verdict })
	overlay.Bad = Theme.button({ Name = "Mal", Text = "❌ Mal", TextSize = 18, BackgroundColor3 = Color3.fromRGB(170, 40, 40), ZIndex = 12, Parent = verdict })
	local after = create("Frame", { Name = "Despues", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 5, ZIndex = 11, Parent = panel })
	create("UIGridLayout", { CellSize = UDim2.new(1 / 3, -6, 0, 44), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = after })
	overlay.Continue = Theme.button({ Name = "Seguir", Text = "↩ Seguir", TextSize = 15, BackgroundColor3 = H.NavyLight, LayoutOrder = 1, ZIndex = 12, Parent = after })
	overlay.Replay = Theme.button({ Name = "OtraVez", Text = "↺ Repetir", TextSize = 15, BackgroundColor3 = H.NavyLight, LayoutOrder = 2, ZIndex = 12, Parent = after })
	overlay.Next = Theme.button({ Name = "Proxima", Text = "⏭ Siguiente", TextSize = 15, BackgroundColor3 = H.NavyLight, LayoutOrder = 3, ZIndex = 12, Parent = after })
end

local function showReview(on: boolean)
	buildOverlay()
	overlay.Panel.Visible = on
	if on then
		local r = pendingReview
		overlay.Title.Text = ("¿Qué tal «%s»?"):format(tostring(r and r.Key or "?"):gsub("^[ED]:", ""))
		overlay.Continue.Visible = playing -- (a mitad: seguir viéndola)
	end
end

local function resetBox()
	table.clear(chosenTags)
	if overlay.TagButtons then
		for tag, b in overlay.TagButtons do
			b.BackgroundColor3 = H.NavyLight
			b.Text = tag
		end
	end
	if overlay.Note then
		overlay.Note.Text = ""
	end
end

local function resumeIfPaused()
	if paused then
		paused = false
		send("Resume")
	end
end

local function sendReview(ok: boolean)
	local r = pendingReview
	if not r then
		return
	end
	local tags = {}
	for _, tag in TAGS do
		if chosenTags[tag] then
			table.insert(tags, tag)
		end
	end
	send("Review", {
		Key = r.Key,
		Ok = ok,
		Note = if overlay.Note and overlay.Note.Text ~= "" then overlay.Note.Text else nil,
		Tags = if #tags > 0 then tags else nil,
		Shot = r.Shot,
		Shots = r.Shots,
		T = r.T,
		Skipped = r.Skipped,
		Device = device(),
	})
	verdicts[r.Key] = if ok then "Bien" else "Mal"
	pendingReview = nil
	resetBox()
	showReview(false)
	resumeIfPaused()
	refresh()
end
Cinemateca._sendReview = sendReview

-- «💬 Comentar» a mitad: para la escena y abre la caja con el plano en que va
local function commentNow()
	local entry = list[selected]
	local info = nil
	pcall(function()
		info = require(script.Parent.Parent.Controllers.HappeningClient).nowRun()
	end)
	pendingReview = {
		Key = entry and entry.K,
		Skipped = false,
		Shot = info and info.Shot,
		Shots = info and info.Shots,
		T = info and info.T,
	}
	if not paused then
		paused = true
		send("Pause")
	end
	showReview(true)
end
Cinemateca._commentNow = commentNow

local function wireOverlay()
	buildOverlay()
	if overlay.Wired then
		return
	end
	overlay.Wired = true
	overlay.Comment.Activated:Connect(commentNow)
	overlay.Good.Activated:Connect(function()
		sendReview(true)
	end)
	overlay.Bad.Activated:Connect(function()
		sendReview(false)
	end)
	overlay.Continue.Activated:Connect(function()
		pendingReview = nil
		showReview(false)
		resumeIfPaused()
	end)
	overlay.Replay.Activated:Connect(function()
		showReview(false)
		resumeIfPaused()
		send("Replay")
	end)
	overlay.Next.Activated:Connect(function()
		showReview(false)
		resumeIfPaused()
		send("Next")
	end)
end

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
	-- La lista
	local scroll = create("ScrollingFrame", {
		Name = "Lista",
		Size = UDim2.new(1, 0, 1, -170),
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
	if overlay.Gui then
		overlay.Gui:Destroy()
	end
	overlay = {}
	playing, paused = false, false
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
		wireOverlay()
		playing = payload.Ok ~= false
		paused = false
		overlay.Comment.Visible = playing
		showReview(false)
		resetBox()
		if payload.Ok == false then
			-- (no se ha podido poner: por ejemplo, su sitio no está disponible)
			pendingReview = { Key = payload.Key, Skipped = true }
			showReview(true)
			overlay.Title.Text = ("«%s»: %s"):format(tostring(payload.Key or "?"):gsub("^[ED]:", ""), tostring(payload.Why or "no se ha podido poner"))
		end
		refresh()
	elseif op == "Ended" then
		local entry = list[tonumber(payload.Index) or selected]
		local key = payload.Key or (entry and entry.K)
		wireOverlay()
		playing = false
		paused = false
		overlay.Comment.Visible = false
		-- (si ya estaba comentando a mitad, la caja sigue con lo que llevaba)
		if not (pendingReview and pendingReview.Key == key and overlay.Panel.Visible) then
			pendingReview = { Key = key, Skipped = payload.Skipped == true }
		end
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
	return { List = list, Selected = selected, Pending = pendingReview, Verdicts = verdicts, Ui = ui, Overlay = overlay, Playing = playing, Paused = paused, Tags = chosenTags }
end
function Cinemateca._setQuery(text: string)
	query = text
	if ui.Search then
		ui.Search.Text = text
	end
	rows()
end

return Cinemateca
