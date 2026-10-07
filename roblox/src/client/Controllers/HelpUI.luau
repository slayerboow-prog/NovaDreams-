-- HelpUI (cliente): el botón ❓ "¿Qué hago ahora?" y su tarjeta.
--
--   * El botón va siempre a la izquierda del panel de la misión (UI/HudLayout: Items.Help). En el
--     móvil es un botón redondo más del racimo (TouchLayout, hueco "Ayuda"); en el ordenador, el mismo
--     botón para el ratón y la tecla H (sale en la lista de teclas). Montado en un vehículo se esconde
--     (la H es el claxon).
--   * Al tocarlo sale una tarjeta en el centro:
--       - con misión o trabajo: lo que tienes que hacer en claro, dónde está y a cuánto
--         ("📍 Colegio · 120 m · 1 min · hacia el norte") y el botón «🧭 Llévame» (pone la ruta del GPS);
--       - sin nada que hacer: 2-3 ideas para ahora mismo según tu edad, la hora y lo que está abierto
--         (shared/Onboarding.suggest), cada una con su «Llévame». Si alguien con ❗ cerca necesita
--         ayuda (encargos de la ciudad: Controllers/CityErrands), sale la primera.
--   * HelpUI.onOpen(fn) / HelpUI.onGo(fn): el tutorial (Controllers/Guide) cuenta abrirla y usar «Llévame».

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GameClock = require(ReplicatedStorage.Shared.GameClock)
local GpsMath = require(ReplicatedStorage.Shared.Gps)
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local Onboarding = require(ReplicatedStorage.Shared.Onboarding)
local OpeningHours = require(ReplicatedStorage.Shared.OpeningHours)
local Theme = require(script.Parent.Parent.UI.Theme)
local Icons = require(script.Parent.Parent.UI.Icons)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local Hud = require(script.Parent.Parent.UI.Hud)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Gps = require(script.Parent.Gps)
local CityErrands = require(script.Parent.CityErrands)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud
local rgb = Color3.fromRGB

local HelpUI = {}

local player = Players.LocalPlayer
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local GO_HEIGHT = 56 -- (móvil) alto de «🧭 Llévame»: ~37 px en pantalla con la escala 0.667
local fitCard: () -> ()

local deskButton: TextButton? = nil
local card: Frame? = nil
local body: Frame? = nil
local busy = false
local openListeners: { () -> () } = {}
local goListeners: { () -> () } = {}

---------------------------------------------------------------------
-- Dónde estás y dónde está el objetivo
---------------------------------------------------------------------
local function myPosition(): Vector3?
	-- Dentro de un edificio (salas en el cielo) cuenta la puerta del edificio en la calle, como en el mapa
	local door = player:GetAttribute("InteriorDoor")
	if typeof(door) == "Vector3" then
		return door
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position
end

local function walkSpeed(): number
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return if humanoid and humanoid.WalkSpeed > 0 then humanoid.WalkSpeed else 16
end

-- "📍 Colegio · 120 m · 1 min · hacia el norte"
function HelpUI.whereText(target: Vector3, place: string?): string
	local district = MapInfo.districtAt(target.X, target.Z)
	local name = place or (if district then district.Name else "Valmar")
	local from = myPosition()
	if not from then
		return "📍 " .. name
	end
	local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z).Magnitude
	return ("📍 %s · %s · %s"):format(name, GpsMath.distanceText(flat, walkSpeed()), Onboarding.direction(from, target))
end

-- Los sitios del mapa (los publica el servidor en ReplicatedStorage.MapLandmarks)
local function landmarks(): { { Kind: string, Position: Vector3 } }
	local out = {}
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks")
	for _, config in if folder then folder:GetChildren() else {} do
		local kind, position = config:GetAttribute("Kind"), config:GetAttribute("Position")
		if type(kind) == "string" and typeof(position) == "Vector3" then
			table.insert(out, { Kind = kind, Position = position })
		end
	end
	return out
end

-- Lo que se le pasa a Onboarding.suggest (tu edad, la hora, cómo estás…)
function HelpUI.context(): Onboarding.Context
	local weekday: number? = nil
	pcall(function()
		weekday = GameClock.now().Weekday
	end)
	local job = player:GetAttribute("Job")
	return {
		Stage = player:GetAttribute("LifeStage"),
		Clock = OpeningHours.clock(),
		Weekday = weekday,
		Hunger = player:GetAttribute("Hunger"),
		Energy = player:GetAttribute("Energy"),
		Wanted = player:GetAttribute("Wanted"),
		Job = if type(job) == "string" then job else nil,
	}
end

---------------------------------------------------------------------
-- La tarjeta
---------------------------------------------------------------------
local function fire(list: { () -> () })
	for _, fn in list do
		task.spawn(fn)
	end
end

-- «Llévame» a tu misión o trabajo
function HelpUI.go()
	Gps.follow()
	pcall(Gps.update)
	Hud.toast("Success", "🧭 Ruta marcada: sigue las flechas azules del suelo")
	HelpUI.close()
	fire(goListeners)
end

local function goTo(suggestion: Onboarding.Suggestion, position: Vector3?)
	if suggestion.Place == "Casa" then
		Gps.routeHome()
	elseif position then
		Gps.setManual(position, suggestion.Name or "Destino")
		Hud.toast("Success", "🧭 Ruta a " .. (suggestion.Name or "tu destino") .. ": sigue las flechas azules")
	end
	HelpUI.close()
	fire(goListeners)
end

local function line(order: number, name: string, text: string, size: number, color: Color3?, bold: boolean?): TextLabel
	return Theme.label({
		Name = name,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextSize = size,
		TextWrapped = true,
		TextColor3 = color or C.Text,
		Font = if bold then Theme.FontBold else Theme.Font,
		LayoutOrder = order,
		ZIndex = 32,
		Parent = body,
	})
end

local function bigButton(order: number, name: string, text: string, color: Color3, callback: () -> ()): TextButton
	local button = Theme.button({
		Name = name,
		Size = UDim2.new(1, 0, 0, if TOUCH then math.max(52, GO_HEIGHT) else 52),
		Text = text,
		TextSize = 22,
		BackgroundColor3 = color,
		LayoutOrder = order,
		ZIndex = 32,
		Parent = body,
	})
	Theme.pressable(button)
	button.Activated:Connect(callback)
	return button
end

-- Móvil: la tarjeta salía con la escala del HUD (0.39 en 667x375: textos de 5-9 px, ✖ de 20 px).
-- Se agranda hasta la escala de las ventanas (Dialog.baseScale; la de touchPopup del HUD) sin salirse
-- de la pantalla; con ella el texto más pequeño (17) mide ≥ 11 px y «🧭 Llévame» y el ✖ ≥ 36 px.
-- El alto se calcula de las filas (la tarjeta crece sola con AutomaticSize).
local CARD_W = 660
local function cardHeight(): number
	local total = 58 + 18
	local count = 0
	for _, child in (body and body:GetChildren()) or {} do
		if child:IsA("GuiObject") then
			count += 1
			local h = child.Size.Y.Offset
			if child:IsA("TextLabel") and h <= 0 then
				-- (filas de texto que crecen solas: unas líneas según el largo)
				local perLine = math.max(1, math.floor((CARD_W - 40) / (child.TextSize * 0.55)))
				h = math.ceil(#child.Text / perLine) * child.TextSize * 1.25
			end
			total += h
		end
	end
	return total + math.max(0, count - 1) * 10
end

fitCard = function()
	local panel = card
	if not panel or not TOUCH then
		return
	end
	local view = workspace.CurrentCamera.ViewportSize
	local hud = HudLayout.scaleFor(view)
	local want = math.min(Dialog.baseScale(), (view.Y - 16) / math.max(cardHeight(), 1), (view.X - 24) / CARD_W)
	local total = math.max(want, Dialog.MIN_TOUCH_SCALE)
	Theme.setBaseScale(panel, math.max(1, total / hud))
	local close = panel:FindFirstChild("Close") :: GuiObject?
	if close then
		local side = math.max(48, math.ceil(37 / math.max(total, 0.01)))
		close.Size = UDim2.fromOffset(side, side)
	end
end

local function render()
	local list = body
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	local objective = Hud.objective()
	if objective and objective.Step ~= "" then
		line(1, "Kind", objective.Kind .. " · " .. objective.Title, 17, H.Gold, true)
		line(2, "Step", "👉 " .. objective.Step, 24, C.Text, true)
		if objective.Target then
			line(3, "Where", HelpUI.whereText(objective.Target, objective.Place), 19, H.SelectLight)
			bigButton(4, "Go", "🧭 Llévame", rgb(30, 140, 90), HelpUI.go)
		else
			line(3, "Where", if objective.Place then "📍 " .. objective.Place else "📍 No hay un sitio marcado: mira la lista de misiones.", 19, H.SelectLight)
			bigButton(4, "Quests", "📋 Ver mis misiones", H.NavyLight, function()
				HelpUI.close()
				Hud.showQuests() -- solo abre (no cierra si ya estaba abierta)
			end)
		end
	else
		line(1, "Kind", "AHORA NO TIENES MISIÓN", 17, H.Gold, true)
		line(2, "Step", "Puedes hacer una de estas cosas:", 20, C.Text)
		local marks = landmarks()
		local from = myPosition()
		local function idea(order: number, name: string, text: string, onGo: (() -> ())?)
			local row = create("Frame", {
				Name = name,
				Size = UDim2.new(1, 0, 0, if TOUCH then 64 else 52),
				BackgroundColor3 = H.NavyLight,
				BackgroundTransparency = 0.35,
				LayoutOrder = order,
				ZIndex = 32,
				Parent = list,
			}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
			Theme.label({ Name = "Text", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -170, 1, 0), Text = text, TextSize = 18, TextWrapped = true, ZIndex = 33, Parent = row })
			if onGo then
				local go = Theme.button({ Name = "Go", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(148, if TOUCH then GO_HEIGHT else 40), Text = "🧭 Llévame", TextSize = 18, BackgroundColor3 = rgb(30, 140, 90), ZIndex = 33, Parent = row })
				Theme.pressable(go)
				go.Activated:Connect(onGo)
			end
		end
		-- Alguien cerca con un ❗ que necesita ayuda (encargo de la ciudad): la primera idea
		local best, bestDistance = nil, math.huge
		for _, mark in CityErrands.list() do
			local d = if from then (Vector3.new(mark.X, 0, mark.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude else 0
			if d < bestDistance then
				best, bestDistance = mark, d
			end
		end
		if best then
			local mark = best
			idea(3, "Encargo", ("❗ %s necesita ayuda: «%s»"):format(mark.Giver, mark.Title), function()
				goTo({ Text = mark.Title, Name = mark.Giver, Place = "Encargo" } :: any, Vector3.new(mark.X, mark.Y, mark.Z))
			end)
		end
		for i, suggestion in Onboarding.suggest(HelpUI.context()) do
			local position = if suggestion.Place and suggestion.Place ~= "Casa" then Onboarding.nearest(marks, suggestion.Place, from) else nil
			idea(3 + i, "Idea" .. i, suggestion.Text, if suggestion.Place == "Casa" or position then function()
				goTo(suggestion, position)
			end else nil)
		end
	end
	line(20, "Footer", if TOUCH then "Toca ✕ para cerrar" else "H o Esc para cerrar", if TOUCH then 17 else 14, C.Muted)
	fitCard()
end

local function buildCard(parent: ScreenGui)
	local panel = Theme.hudPanel({
		Name = "HelpCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(660, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.1,
		Visible = false,
		ZIndex = 30,
		Parent = parent,
	})
	Theme.bevel(panel, H.Gold)
	Icons.new("ayuda", { Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(30, 30), ZIndex = 31, Parent = panel })
	Theme.title({ Name = "Title", Position = UDim2.fromOffset(58, 12), Size = UDim2.new(1, -120, 0, 34), Text = "¿QUÉ HAGO AHORA?", TextSize = 24, ZIndex = 31, Parent = panel })
	local close = create("TextButton", { Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = H.NavyLight, Text = "", ZIndex = 32, Parent = panel }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	Icons.plus({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), Rotation = 45, ZIndex = 33, Parent = close })
	Theme.pressable(close)
	close.Activated:Connect(function()
		HelpUI.close()
	end)
	local content = create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(20, 58),
		Size = UDim2.new(1, -40, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 31,
		Parent = panel,
	})
	create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	-- Relleno de abajo (la tarjeta crece con el contenido)
	create("UIPadding", { PaddingBottom = UDim.new(0, 18), Parent = panel })
	card = panel
	body = content
end

function HelpUI.open()
	local panel = card
	if not panel or busy then
		return
	end
	-- Una ventana grande a la vez: fuera la mochila, el mapa, la tienda, el diario…
	Dialog.closeOthers("Help")
	render()
	panel.Visible = true
	Theme.pop(panel, 1.04)
	fire(openListeners)
end

function HelpUI.close()
	if card then
		card.Visible = false
	end
end

function HelpUI.isOpen(): boolean
	return card ~= nil and card.Visible
end

function HelpUI.toggle()
	if HelpUI.isOpen() then
		HelpUI.close()
	else
		HelpUI.open()
	end
end

function HelpUI.onOpen(fn: () -> ())
	table.insert(openListeners, fn)
end

function HelpUI.onGo(fn: () -> ())
	table.insert(goListeners, fn)
end

---------------------------------------------------------------------
-- El botón ❓
---------------------------------------------------------------------
local function available(): boolean
	return not busy and player:GetAttribute("Riding") == nil
end

local function refreshButton()
	if deskButton then
		deskButton.Visible = available()
	end
end

-- Ordenador: el mismo botón redondo que en el móvil, para el ratón (con la tecla H en la esquina)
local function buildDeskButton(parent: ScreenGui)
	local button = create("TextButton", {
		Name = "HelpButton",
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.28,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(120, 170, 255), rgb(40, 60, 120)) }),
	})
	Theme.edge(button, nil, 2.5)
	Icons.new("ayuda", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.44, 0.44), Parent = button })
	Theme.label({ Name = "Caption", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.66), Size = UDim2.fromScale(0.96, 0.2), Text = "¿Qué hago?", Font = Theme.FontBold, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.5, Parent = button })
	local key = Theme.label({ Name = "Key", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1.05, -0.05), Size = UDim2.fromOffset(24, 22), BackgroundColor3 = H.Gold, BackgroundTransparency = 0, Text = "H", Font = Theme.FontBold, TextSize = 14, TextColor3 = C.Ink, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, Parent = button })
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = key })
	Theme.pressable(button)
	button.Activated:Connect(HelpUI.toggle)
	HudLayout.onChanged(function(layout)
		HudLayout.apply(button, layout.Items.Help)
	end)
	deskButton = button
end

-- En conversaciones y cinemáticas no hay botón ni tarjeta
function HelpUI.setBusy(value: boolean)
	busy = value
	if value then
		HelpUI.close()
	end
	refreshButton()
end

function HelpUI.init()
	local screen = create("ScreenGui", {
		Name = "HelpGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 7, -- por encima del HUD y de los botones (la tarjeta tapa lo de detrás)
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HudLayout.scaleGui(screen)
	buildCard(screen)
	Dialog.registerBig("Help", HelpUI.close, HelpUI.isOpen)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		fitCard()
	end)
	-- Móvil: un botón redondo más (hueco "Ayuda" junto a la misión). Ordenador: la fila "H · ¿Qué hago?"
	-- en la lista de teclas, y el botón para el ratón
	TouchLayout.register({
		Id = "Ayuda",
		Icon = "ayuda",
		Label = "¿Qué hago?",
		Slot = "Ayuda",
		Priority = 0.5,
		Key = "H",
		Visible = function()
			return player:GetAttribute("Riding") == nil
		end,
		Callback = HelpUI.toggle,
	})
	if not TOUCH then
		buildDeskButton(screen)
	end
	player:GetAttributeChangedSignal("Riding"):Connect(refreshButton)
	refreshButton()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == Enum.KeyCode.H and available() and player:GetAttribute("InDialogue") ~= true then
			HelpUI.toggle()
		elseif input.KeyCode == Enum.KeyCode.Escape and HelpUI.isOpen() then
			HelpUI.close()
		end
	end)
end

return HelpUI
