-- Guide (cliente): ayuda para el jugador nuevo, en una tarjeta pequeña encima de la barra rápida
-- (UI/HudLayout: Items.Guide).
--
--   1. Primeros pasos (solo jugadores nuevos; OnboardingService decide y guarda): una lista de pasos
--      (shared/Onboarding.Steps). La tarjeta enseña el primero que falta con un aro brillante y una
--      flecha sobre el botón de verdad del HUD, y el botón «Saltar». Cada paso se cumple cuando lo
--      haces de verdad (andar, correr, hablar o usar algo, abrir el mapa, la mochila, el ❓ y seguir
--      la misión). Los pasos cuentan aunque la tarjeta no se vea (p. ej. durante el prólogo, con el
--      atributo InPrologue): al acabar solo salen los que falten, y si no falta ninguno, se da por
--      hecho sin decir nada. «Ver tutorial otra vez» (menú) lo empieza de nuevo: Guide.restart().
--   2. Pistas: si llevas 90 s jugando sin avanzar en la misión (o te alejas mucho rato de ella):
--      "💡 Pista: …" con «Toca para ir» (pone el GPS). Como mucho dos veces la misma.
--   3. Consejos de la primera vez (shared/Onboarding.Tips): vehículo, tienda, máquina del gimnasio,
--      parada de bus o metro, estrellas de búsqueda y hambre o cansancio. Uno solo y se guarda.
--   Las notas (pistas, consejos, avisos de la ruta) llevan una ✕ (48 px) y se van solas. Con una
--   ventana abierta (Mis vehículos, la tienda, la mochila, el mapa, el ValPhone, el pase…) no salen
--   encima: esperan en la cola a que se cierre (y la pista de «atascado» no cuenta el tiempo). Una
--   nota cerrada con la ✕ no vuelve en HINT_SNOOZE s (ni otra pista de «atascado» en HINT_QUIET s).
--   Nada de esto sale en conversaciones, cinemáticas (Guide.setBusy), el prólogo, de bebé ni mientras abajo
--   en el centro hay otra cosa (una decisión de la historia, la barra del gimnasio, el panel del autobús).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Onboarding = require(ReplicatedStorage.Shared.Onboarding)
local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local Hud = require(script.Parent.Parent.UI.Hud)
local Gps = require(script.Parent.Gps)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Phone = require(script.Parent.Parent.UI.Phone)

local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

local Guide = {}

export type Hooks = {
	mapOpen: (() -> boolean)?, -- ¿está abierto el mapa grande? (MapUI.isOpen)
	bagOpen: (() -> boolean)?, -- ¿está abierta la mochila? (InventoryUI.isOpen)
	dialogOpen: (() -> boolean)?, -- ¿hay una decisión de la historia en pantalla? (LifeStory.hasDialog)
	windowOpen: (() -> boolean)?, -- ¿otra ventana abierta? (el ❓, el diario, el pase, una conversación…)
}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local NOTE_SECONDS = { Tip = 9, Hint = 10, Info = 5 }
local HINT_SNOOZE = 300 -- una nota cerrada con la ✕: la misma no vuelve en 5 min (y ninguna pista de «atascado» en 3)
local HINT_QUIET = 180
local NOTE_STALE = 120 -- una pista que lleva tanto en la cola (detrás de una ventana) ya no sirve
local CLOSE_SIZE = 48 -- la ✕ de la nota (móvil: ≥ 44 px)
local MOVE_SECONDS = 1 -- andando este rato cuenta "muévete"
local MISSION_APPROACH = 20 -- studs que hay que acercarse al objetivo para "sigue tu misión"
local SHOP_KINDS = { Supermercado = 40, CentroComercial = 40, GranCentroComercial = 50, TiendaPesca = 25, Armeria = 25 }
local STOP_KINDS = { ParadaBus = 14, BocaMetro = 22, EstacionCercanias = 22 }
local STEP_ICONS = { Mover = "flecha", Correr = "correr", Interactuar = "interactuar", Mapa = "mapa", Mochila = "mochila", Ayuda = "ayuda", Mision = "misiones" }

local hooks: Hooks = {}
local remote: RemoteEvent? = nil
local started = false
local busy = false
local tutorial = "" -- "Pendiente", "Hecho", "Saltado", "Veterano" ("" = aún no lo ha dicho el servidor)
local done: { [string]: boolean } = {}
local tipsSeen: { [string]: boolean } = {}
local moveTime = 0
local missionKey: string? = nil
local missionBest: number? = nil
local stuck = Onboarding.newStuck()
local promptedTips: { [string]: boolean } = {} -- consejos que ha pedido un cartel (PromptShown)

type Note = { Kind: string, Text: string, Button: string?, Go: (() -> ())?, TipId: string?, At: number? }
local queue: { Note } = {}
local note: Note? = nil
local noteLeft = 0
local clock = 0 -- segundos de juego (Guide.tick)
local snoozed: { [string]: number } = {} -- texto de la nota -> hasta cuándo no vuelve (cerrada con la ✕)
local hintsQuietUntil = 0

local gui: ScreenGui? = nil
local card: Frame? = nil
local cardParts: { [string]: any } = {}
local noteFrame: Frame? = nil
local noteParts: { [string]: any } = {}
local highlight: ScreenGui? = nil
local ring: Frame? = nil
local arrow: Frame? = nil

local function send(kind: string, id: string?)
	if remote then
		pcall(function()
			(remote :: RemoteEvent):FireServer(kind, id)
		end)
	end
end

local function humanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function rootPosition(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position
end

local function safe(fn: (() -> boolean)?): boolean
	if not fn then
		return false
	end
	local ok, value = pcall(fn)
	return ok and value == true
end

-- ¿Se puede enseñar algo ahora? (ni conversación, ni cinemática, ni prólogo, ni bebé)
local function quiet(): boolean
	return busy
		or player:GetAttribute("InDialogue") == true
		or player:GetAttribute("InPrologue") == true
		or player:GetAttribute("LifeStage") == "Bebe"
end

-- Abajo en el centro hay otra cosa: la barra del ritmo del gimnasio o el panel del autobús
-- (y también la clase —el examen de mates, el circuito— o un minijuego: la tarjeta los tapaba)
local function areaTaken(): boolean
	if player:GetAttribute("Training") ~= nil or player:GetAttribute("BusLine") ~= nil or player:GetAttribute("InMiniGame") then
		return true
	end
	local gui = player:FindFirstChild("PlayerGui")
	-- (en el metro: el panel del tren va ahí, HudLayout.Items.Ride)
	local metro = gui and gui:FindFirstChild("MetroRideGui")
	local ridePanel = metro and metro:FindFirstChild("Ride")
	if ridePanel and ridePanel:IsA("GuiObject") and ridePanel.Visible then
		return true
	end
	local class = gui and gui:FindFirstChild("ClassUI")
	if class then
		for _, name in { "Class", "Circuit" } do
			local panel = class:FindFirstChild(name, true)
			if panel and panel:IsA("GuiObject") and panel.Visible then
				return true
			end
		end
	end
	return false
end

-- Conduciendo o de pasajero: la tarjeta abajo en el centro tapaba la carretera. Fuera mientras vas
-- en un vehículo (vuelve al bajarte); solo se deja el consejo del propio vehículo (sale al subir).
local function inVehicle(): boolean
	if player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil then
		return true
	end
	local character = player.Character
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local seat = h and h.SeatPart
	local model = seat and seat:FindFirstAncestorOfClass("Model")
	return model ~= nil and model:GetAttribute("Drivable") == true
end

-- ¿Hay una ventana abierta? (las notas y la tarjeta esperan: si no, tapaban la ventana —en el
-- móvil, la pista «Toca para ir» se ponía encima de la lista de Mis vehículos—)
local function windowOpen(): boolean
	if safe(hooks.bagOpen) or safe(hooks.mapOpen) or safe(hooks.windowOpen) then
		return true
	end
	local ok, open = pcall(function()
		if Dialog.anyOpen() or Phone.isOpen() then print("DBG", Dialog.anyOpen(), Phone.isOpen()) end
		return Dialog.anyOpen() or Phone.isOpen()
	end)
	if safe(hooks.windowOpen) then print("DBG hook") end
	return ok and open == true
end
Guide.windowOpen = windowOpen

local function tutorialActive(): boolean
	return tutorial == Onboarding.Pending and not Onboarding.allDone(done)
end

---------------------------------------------------------------------
-- La tarjeta (primeros pasos) y las notas (pistas y consejos)
---------------------------------------------------------------------
local function buildCard(parent: ScreenGui)
	local panel = Theme.hudPanel({ Name = "TutorialCard", BackgroundTransparency = 0.18, CornerRadius = 16, Visible = false, ZIndex = 20, Parent = parent })
	Theme.bevel(panel, H.Gold)
	create("Frame", { Position = UDim2.fromOffset(0, 16), Size = UDim2.new(0, 5, 1, -32), BackgroundColor3 = H.Gold, BorderSizePixel = 0, ZIndex = 21, Parent = panel }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	cardParts.Count = Theme.title({ Name = "Count", Position = UDim2.fromOffset(22, 10), Size = UDim2.fromOffset(360, 24), TextSize = 17, TextColor3 = H.Gold, ZIndex = 21, Parent = panel })
	cardParts.Icon = Icons.new("flecha", { Name = "StepIcon", Position = UDim2.fromOffset(22, 48), Size = UDim2.fromOffset(52, 52), ZIndex = 21, Parent = panel })
	cardParts.Title = Theme.label({ Name = "Title", Position = UDim2.fromOffset(88, 36), Size = UDim2.new(1, -236, 0, 34), Font = Theme.FontBold, TextSize = 28, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 21, Parent = panel })
	cardParts.Text = Theme.label({ Name = "Text", Position = UDim2.fromOffset(88, 72), Size = UDim2.new(1, -104, 0, 66), TextSize = 21, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 21, Parent = panel })
	local skip = Theme.button({ Name = "Skip", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12), Size = UDim2.fromOffset(132, 44), Text = "Saltar ⏭", TextSize = 19, BackgroundColor3 = H.NavyLight, ZIndex = 22, Parent = panel })
	Theme.pressable(skip)
	skip.Activated:Connect(function()
		Guide.skip()
	end)
	cardParts.Skip = skip
	card = panel
end

local function buildNote(parent: ScreenGui)
	local panel = Theme.hudPanel({ Name = "GuideNote", BackgroundTransparency = 0.15, CornerRadius = 16, Visible = false, ZIndex = 20, Parent = parent })
	-- Toda la nota se puede tocar (lo que hace su botón)
	local hit = create("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 21, Parent = panel })
	noteParts.Text = Theme.label({ Name = "Text", Position = UDim2.fromOffset(22, 14), Size = UDim2.new(1, -(44 + CLOSE_SIZE), 0, 76), TextSize = 21, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 22, Parent = panel })
	-- ✕: quitar la nota sin hacer nada (y que la misma no vuelva en un rato)
	local close = Theme.button({ Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(CLOSE_SIZE, CLOSE_SIZE), Text = "✕", TextSize = 24, BackgroundColor3 = H.NavyLight, ZIndex = 24, Parent = panel })
	Theme.pressable(close)
	close.Activated:Connect(function()
		Guide.closeNote()
	end)
	noteParts.Close = close
	local button = Theme.button({ Name = "Go", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -12), Size = UDim2.fromOffset(210, 44), TextSize = 19, BackgroundColor3 = rgb(30, 140, 90), ZIndex = 23, Parent = panel })
	Theme.pressable(button)
	local function act()
		local current = note
		Guide.dismissNote()
		if current and current.Go then
			current.Go()
		end
	end
	hit.Activated:Connect(act)
	button.Activated:Connect(act)
	noteParts.Button = button
	noteParts.Edge = panel:FindFirstChild("Edge")
	noteFrame = panel
end

-- Aro brillante y flecha sobre la pieza del HUD que hay que tocar
local function buildHighlight()
	local screen = create("ScreenGui", {
		Name = "GuideHighlight",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5, -- encima de los botones (4), debajo de la tarjeta (6)
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HudLayout.scaleGui(screen)
	local frame = create("Frame", { Name = "Ring", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Active = false, Parent = screen })
	create("UICorner", { Name = "Corner", CornerRadius = UDim.new(0, 18), Parent = frame })
	local stroke = create("UIStroke", { Name = "Glow", Color = H.Gold, Thickness = 5, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
	-- Late (más y menos brillo) sin parar
	TweenService:Create(stroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.65 }):Play()
	local holder = create("Frame", { Name = "Arrow", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, Visible = false, Active = false, Parent = screen })
	local bob = create("Frame", { Name = "Bob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = holder })
	Icons.chevron({ Name = "Chevron", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 40), Thickness = 7, Color = H.Gold, Parent = bob })
	highlight = screen
	ring = frame
	arrow = holder
end

-- Rectángulo (en el lienzo) de "Items.X" o "Slots.X" de la colocación actual
local function targetRect(path: string?): { X: number, Y: number, W: number, H: number }?
	if not path then
		return nil
	end
	local group, name = string.match(path, "^(%a+)%.(%a+)$")
	local layout = HudLayout.current()
	local list = if group == "Slots" then layout.Slots elseif group == "Items" then layout.Items else nil
	local placement = list and name and list[name]
	if not placement then
		return nil
	end
	return HudLayout.rect(placement, layout.Canvas)
end

local function hideHighlight()
	if ring then
		ring.Visible = false
	end
	if arrow then
		arrow.Visible = false
	end
end

local function showHighlight(step: Onboarding.Step)
	local frame, holder = ring, arrow
	if not frame or not holder then
		return
	end
	local path = if TOUCH then step.Target.Touch else step.Target.Keys
	local rect = targetRect(path)
	if not rect then
		hideHighlight()
		return
	end
	local round = string.find(path, "^Slots") ~= nil or path == "Items.Joystick" or path == "Items.Help"
	local pad = 10
	local center = Vector2.new(rect.X + rect.W / 2, rect.Y + rect.H / 2)
	frame.Position = UDim2.fromOffset(center.X, center.Y)
	frame.Size = UDim2.fromOffset(rect.W + pad * 2, rect.H + pad * 2)
	local corner = frame:FindFirstChild("Corner") :: UICorner?
	if corner then
		corner.CornerRadius = if round then UDim.new(1, 0) else UDim.new(0, 18)
	end
	frame.Visible = true
	-- La flecha, fuera del aro, del lado de la tarjeta, apuntando a la pieza
	local layout = HudLayout.current()
	local guideRect = HudLayout.rect(layout.Items.Guide, layout.Canvas)
	local from = Vector2.new(guideRect.X + guideRect.W / 2, guideRect.Y + guideRect.H / 2)
	local dir = from - center
	if dir.Magnitude < 1 then
		dir = Vector2.new(0, 1)
	end
	dir = dir.Unit
	local reach = math.max(rect.W, rect.H) / 2 + pad + 34
	local at = center + dir * reach
	holder.Position = UDim2.fromOffset(at.X, at.Y)
	holder.Rotation = math.deg(math.atan2(-dir.Y, -dir.X)) -- el chevron mira a la derecha: se gira hacia la pieza
	holder.Visible = true
end

local function paintCard(step: Onboarding.Step)
	Theme.setText(cardParts.Count, ("PRIMEROS PASOS · %d/%d"):format((step :: any).Index, #Onboarding.Steps))
	Theme.setText(cardParts.Title, step.Title)
	Theme.setText(cardParts.Text, if TOUCH then step.Touch else step.Keys)
	Icons.set(cardParts.Icon, STEP_ICONS[step.Id] or "flecha")
end

-- Qué se ve ahora: una nota (pista o consejo), la tarjeta del paso, o nada
local function refresh()
	local panel, noteView = card, noteFrame
	if not panel or not noteView then
		return
	end
	-- Con la mochila o el mapa abiertos la tarjeta se aparta: si no, tapaba lo que estás mirando.
	local blocked = quiet() or areaTaken() or safe(hooks.dialogOpen) or windowOpen()
	local current = note
	local driving = inVehicle()
	if driving and not (current and current.TipId == "Vehiculo") then
		blocked = true
	end
	if current and not blocked then
		noteView.Visible = true
		Theme.setText(noteParts.Text, current.Text)
		noteParts.Button.Visible = current.Button ~= nil
		if current.Button then
			Theme.setText(noteParts.Button, current.Button)
		end
	else
		noteView.Visible = false
	end
	local step = if tutorialActive() then Onboarding.nextStep(done) else nil
	local showCard = step ~= nil and not blocked and not noteView.Visible
	if showCard and step then
		if not panel.Visible then
			Theme.pop(panel, 1.05)
		end
		panel.Visible = true
		paintCard(step)
		showHighlight(step)
	else
		panel.Visible = false
		hideHighlight()
	end
end
Guide.refresh = refresh

---------------------------------------------------------------------
-- Notas: pistas y consejos (una detrás de otra)
---------------------------------------------------------------------
local function nextNote()
	note = table.remove(queue, 1)
	-- (las pistas que se quedaron esperando detrás de una ventana mucho rato ya no valen)
	while note and note.Kind == "Hint" and clock - (note.At or clock) > NOTE_STALE do
		note = table.remove(queue, 1)
	end
	noteLeft = if note then NOTE_SECONDS[note.Kind] or 8 else 0
	refresh()
end

function Guide.note(kind: string, text: string, button: string?, go: (() -> ())?, tipId: string?)
	-- Ni repetida (ya en pantalla o en la cola) ni una que cerraste con la ✕ hace poco
	if (snoozed[text] or -math.huge) > clock or (note and note.Text == text) then
		return
	end
	for _, waiting in queue do
		if waiting.Text == text then
			return
		end
	end
	table.insert(queue, { Kind = kind, Text = text, Button = button, Go = go, TipId = tipId, At = clock })
	if not note then
		nextNote()
	end
end

function Guide.dismissNote()
	nextNote()
end

-- La ✕: la nota se va y la misma no vuelve en HINT_SNOOZE s (ni otra pista de «atascado» en HINT_QUIET)
function Guide.closeNote()
	local current = note
	if current then
		snoozed[current.Text] = clock + HINT_SNOOZE
		if current.Kind == "Hint" then
			hintsQuietUntil = clock + HINT_QUIET
		end
	end
	nextNote()
end

-- (pruebas) la nota que se ve
function Guide.currentNote(): Note?
	return note
end

---------------------------------------------------------------------
-- Primeros pasos
---------------------------------------------------------------------
-- Un paso hecho de verdad (lo llaman los detectores de abajo y Main: el ❓ y «Llévame»)
function Guide.mark(id: string)
	if tutorial ~= Onboarding.Pending or done[id] or not Onboarding.StepById[id] then
		return
	end
	local wasShowing = card ~= nil and card.Visible
	done[id] = true
	send("Step", id)
	if Onboarding.allDone(done) then
		-- Si lo acaba con la tarjeta delante, se felicita; si lo hizo todo sin verla (el prólogo), sin decir nada
		if wasShowing then
			Hud.toast("Success", if TOUCH then "🎉 ¡Ya sabes lo básico! Si no sabes qué hacer, toca ❓" else "🎉 ¡Ya sabes lo básico! Si no sabes qué hacer, pulsa H")
		end
		tutorial = Onboarding.Done
	elseif wasShowing then
		Hud.toast("Success", "✅ ¡Bien hecho!")
	end
	refresh()
end

function Guide.skip()
	if tutorial ~= Onboarding.Pending then
		return
	end
	tutorial = Onboarding.Skipped
	send("Skip")
	refresh()
	Hud.toast("Info", "Puedes verlo otra vez en Menú › 🎓 Ver tutorial otra vez")
end

function Guide.restart()
	tutorial = Onboarding.Pending
	table.clear(done)
	moveTime = 0
	missionKey, missionBest = nil, nil
	send("Restart")
	refresh()
end

function Guide.isShowing(): boolean
	return card ~= nil and card.Visible
end

function Guide.state(): (string, { [string]: boolean })
	return tutorial, done
end

-- Estado que manda el servidor (atributos Tutorial y TutorialSteps)
local function readServer()
	local value = player:GetAttribute("Tutorial")
	if type(value) == "string" and value ~= "" then
		tutorial = value
	end
	for id in Onboarding.decode(player:GetAttribute("TutorialSteps")) do
		done[id] = true
	end
	for id in Onboarding.decode(player:GetAttribute("TipsSeen")) do
		tipsSeen[id] = true
	end
	if tutorial == Onboarding.Pending and Onboarding.allDone(done) then
		tutorial = Onboarding.Done
	end
	refresh()
end
Guide.readServer = readServer

---------------------------------------------------------------------
-- Consejos de la primera vez
---------------------------------------------------------------------
function Guide.tip(id: string)
	if tipsSeen[id] or not Onboarding.Tips[id] or tutorial == Onboarding.Veteran then
		return
	end
	tipsSeen[id] = true
	send("Tip", id)
	Guide.note("Tip", Onboarding.Tips[id], "Vale 👍", nil, id)
end

-- ¿Qué consejo pide lo que tienes delante? (el cartel de un objeto: máquina, tienda, parada…)
local function tipForPrompt(prompt: Instance): string?
	local object: Instance? = prompt
	for _ = 1, 6 do
		if not object then
			break
		end
		if object:GetAttribute("GymMachine") ~= nil then
			return "Gimnasio"
		elseif object:GetAttribute("Shop") ~= nil or object:GetAttribute("ShopId") ~= nil or object:GetAttribute("ShopName") ~= nil then
			return "Tienda"
		elseif object:GetAttribute("StopId") ~= nil or object:GetAttribute("BusLine") ~= nil then
			return "Transporte"
		end
		object = object.Parent
	end
	return nil
end

-- Tiendas y paradas del mapa (ReplicatedStorage.MapLandmarks): se leen una vez
local landmarkCache: { { Kind: string, Position: Vector3 } }? = nil
local function nearKind(kinds: { [string]: number }, position: Vector3): boolean
	if not landmarkCache then
		local folder = ReplicatedStorage:FindFirstChild("MapLandmarks")
		if not folder then
			return false
		end
		local list = {}
		for _, config in folder:GetChildren() do
			local kind, at = config:GetAttribute("Kind"), config:GetAttribute("Position")
			if type(kind) == "string" and (SHOP_KINDS[kind] or STOP_KINDS[kind]) and typeof(at) == "Vector3" then
				table.insert(list, { Kind = kind, Position = at })
			end
		end
		landmarkCache = list
	end
	for _, mark in landmarkCache :: { { Kind: string, Position: Vector3 } } do
		local radius = kinds[mark.Kind]
		if radius and Vector3.new(mark.Position.X - position.X, 0, mark.Position.Z - position.Z).Magnitude < radius then
			return true
		end
	end
	return false
end

local function checkTips()
	if player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil then
		Guide.tip("Vehiculo")
	end
	if (tonumber(player:GetAttribute("Wanted")) or 0) > 0 then
		Guide.tip("Busqueda")
	end
	local hunger, energy = tonumber(player:GetAttribute("Hunger")), tonumber(player:GetAttribute("Energy"))
	if (hunger and hunger < 30) or (energy and energy < 25) then
		Guide.tip("Necesidades")
	end
	if player:GetAttribute("Cart") ~= nil then
		Guide.tip("Tienda")
	end
	for id in promptedTips do
		Guide.tip(id)
	end
	table.clear(promptedTips)
	local position = rootPosition()
	if position then
		if not tipsSeen.Tienda and nearKind(SHOP_KINDS, position) then
			Guide.tip("Tienda")
		end
		if not tipsSeen.Transporte and nearKind(STOP_KINDS, position) then
			Guide.tip("Transporte")
		end
	end
end

---------------------------------------------------------------------
-- Cada vuelta (4 veces por segundo): detectar pasos, consejos y pistas
---------------------------------------------------------------------
local function distanceTo(target: Vector3?): number?
	local position = rootPosition()
	if not target or not position then
		return nil
	end
	return Vector3.new(target.X - position.X, 0, target.Z - position.Z).Magnitude
end

local function detectSteps(dt: number)
	if tutorial ~= Onboarding.Pending then
		return
	end
	local h = humanoid()
	if h and h.MoveDirection.Magnitude > 0.1 then
		moveTime += dt
		if moveTime >= MOVE_SECONDS then
			Guide.mark("Mover")
		end
	end
	if player:GetAttribute("Sprinting") == true then
		Guide.mark("Correr")
	end
	if player:GetAttribute("InDialogue") == true then
		Guide.mark("Interactuar")
	end
	if safe(hooks.mapOpen) then
		Guide.mark("Mapa")
	end
	if safe(hooks.bagOpen) then
		Guide.mark("Mochila")
	end
	if Hud.questsOpen() then
		Guide.mark("Mision")
	end
	-- Seguir la misión: acercarse de verdad a su objetivo
	local objective = Hud.objective()
	local key = objective and objective.Target and objective.Key
	if key ~= missionKey then
		missionKey = key
		missionBest = distanceTo(objective and objective.Target)
	elseif objective and objective.Target then
		local d = distanceTo(objective.Target)
		if d and missionBest then
			if d <= missionBest - MISSION_APPROACH then
				Guide.mark("Mision")
			end
		elseif d then
			missionBest = d
		end
	end
end

local function checkStuck(dt: number)
	local objective = Hud.objective()
	-- (una misión en pausa hasta mañana no es estar atascado)
	local key = if objective and objective.Step ~= "" and not objective.Later then objective.Key else nil
	-- (siguiendo una ruta que has elegido tú —el aeropuerto, tu casa…— alejarse de la misión es lo
	-- normal: ni «te estás alejando» ni «Toca para ir», que te quitaba tu ruta)
	-- (con una ventana abierta, una nota en pantalla o recién cerrada una pista con la ✕, el tiempo de «atascado» no corre: no se amontonan ni salen una tras otra)
	local blocked = quiet() or tutorialActive() or areaTaken() or safe(hooks.dialogOpen) or inVehicle() or Gps.manual() ~= nil
		or windowOpen() or note ~= nil or clock < hintsQuietUntil
	local kind = Onboarding.stuckStep(stuck, dt, key, distanceTo(objective and objective.Target), blocked)
	if not kind or not objective then
		return
	end
	local text = if kind == "Away" then "💡 Pista: te estás alejando. " .. objective.Step else "💡 Pista: " .. objective.Step
	if objective.Target then
		Guide.note("Hint", text, "🧭 Toca para ir", function()
			Gps.follow()
			pcall(Gps.update)
			Guide.mark("Mision")
		end)
	else
		Guide.note("Hint", text .. " (mira la lista de misiones)", "📋 Ver misiones", function()
			Hud.showQuests() -- solo abre (no cierra si ya estaba abierta)
		end)
	end
end

function Guide.tick(dt: number)
	clock += dt
	detectSteps(dt)
	if not quiet() then
		checkTips()
	end
	checkStuck(dt)
	-- Las notas se van solas a su tiempo (el tiempo no corre mientras no se ven)
	if note and noteFrame and noteFrame.Visible then
		noteLeft -= dt
		if noteLeft <= 0 then
			nextNote()
		end
	end
	refresh()
end

-- En conversaciones y cinemáticas: nada (Main.client, igual que el resto del HUD)
function Guide.setBusy(value: boolean)
	busy = value
	refresh()
end

function Guide.init(options: Hooks?)
	if started then
		return
	end
	started = true
	hooks = options or {}
	local screen = create("ScreenGui", {
		Name = "GuideGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 6, -- encima de los botones y del aro (la tarjeta se puede tocar siempre)
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HudLayout.scaleGui(screen)
	gui = screen
	buildCard(screen)
	buildNote(screen)
	buildHighlight()
	HudLayout.onChanged(function(layout)
		if card then
			HudLayout.apply(card, layout.Items.Guide)
		end
		if noteFrame then
			HudLayout.apply(noteFrame, layout.Items.Guide)
		end
		refresh()
	end)

	remote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Onboarding") :: RemoteEvent?
	for _, attribute in { "Tutorial", "TutorialSteps", "TipsSeen" } do
		player:GetAttributeChangedSignal(attribute):Connect(readServer)
	end
	for _, attribute in { "InPrologue", "InDialogue", "LifeStage" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	player:GetAttributeChangedSignal("Sprinting"):Connect(function()
		if player:GetAttribute("Sprinting") == true then
			Guide.mark("Correr")
		end
	end)
	-- Hablar o usar algo: cualquier cartel que actives tú
	ProximityPromptService.PromptTriggered:Connect(function(_, who)
		if who == player then
			Guide.mark("Interactuar")
		end
	end)
	-- Lo que tienes delante (su cartel) puede pedir un consejo: máquina del gimnasio, tienda, parada
	ProximityPromptService.PromptShown:Connect(function(prompt)
		local id = tipForPrompt(prompt)
		if id then
			promptedTips[id] = true
		end
	end)
	readServer()
	-- La misión cambia mientras sigues tu ruta: un aviso que se puede tocar para volver a ella
	Gps.onNotice(function(text)
		Guide.note("Hint", "🎯 " .. text, "🧭 Seguir misión", function()
			Gps.follow()
			pcall(Gps.update)
		end)
	end)

	task.spawn(function()
		local last = os.clock()
		while gui and gui.Parent do
			task.wait(0.25)
			local now = os.clock()
			local ok, err = pcall(Guide.tick, math.clamp(now - last, 0, 1))
			last = now
			if not ok then
				warn("[Guía] " .. tostring(err))
			end
		end
	end)
end

return Guide
