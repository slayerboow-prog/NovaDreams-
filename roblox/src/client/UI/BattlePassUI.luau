-- BattlePassUI: la ventana del pase de temporada («Luces de Valmar») y sus entradas.
--
--   BattlePassUI.init()           -> lo llama Main.client (safeInit). Con BattlePassConfig.Enabled = false
--                                    no hace NADA: ni fila en COMANDOS, ni tecla, ni ventana, ni remoto.
--   BattlePassUI.open(section?)   -> "Rewards" (por defecto) | "Missions" | "Shop"
--   BattlePassUI.close() / toggle() / isOpen() / state()
--   Aviso de nivel: la interfaz se lo dice al servidor (BattlePassClient.setLevelUpToasts) y este ya no
--                                    manda su Notify de «¡nivel n!»: solo sale «RECOMPENSA DESBLOQUEADA».
--   Cosméticos equipados (tema del teléfono y del HUD): UI/BattlePassCosmetics, que se arranca aquí.
--
-- Entradas: la fila «🏆 Pase de temporada» del menú de COMANDOS (las «apps del teléfono» son esas filas:
-- no hay otra ventana), la tecla N en el ordenador y el aviso de recompensa desbloqueada.
--
-- Diseño: ventana compacta del estilo del HUD (azul marino translúcido, filo cian que brilla). Arriba,
-- «TEMPORADA 1 · LUCES DE VALMAR», el nivel, la barra de XP y los días que quedan; tres secciones
-- (RECOMPENSAS, MISIONES, FICHAS). En RECOMPENSAS: la recompensa elegida en grande (vista previa 3D que
-- se gira, rareza, tipo, nivel, pista, estado y RECLAMAR), los carriles GRATIS / PREMIUM, la franja del
-- pase premium (sin presión: «PASE PREMIUM · Temporada 1 · 50 recompensas · [Vista previa] [Comprar]»)
-- y la fila de niveles 01…50 que se desplaza. En el móvil es una hoja casi a pantalla completa con botones
-- grandes y menos piezas a la vez; en el ordenador, tooltips al pasar el ratón, rueda y tecla rápida.
--
-- Rendimiento: nada va por fotograma. Se guarda el último estado del servidor y se repinta solo cuando
-- llega uno nuevo (el servidor los junta: uno cada 0,5 s como mucho) o al tocar algo.
-- Seguridad: el cliente solo PIDE (reclamar, comprar, equipar…). El servidor decide todo; la compra la
-- abre el servidor con MarketplaceService (Controllers/BattlePassClient.buy).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Dialog = require(script.Parent.Dialog)
local Layout = require(script.Parent.BattlePassLayout)
local View = require(script.Parent.BattlePassView)
local RewardCard = require(script.Parent.BattlePassRewardCard)
local Pages = require(script.Parent.BattlePassPages)
local Preview = require(script.Parent.BattlePassPreview)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud

local BattlePassUI = {}

local NAME = "BattlePass"
local HOTKEY = Enum.KeyCode.N -- (B es la piedra, M el mapa, E usar, H ayuda, J historia)
local ROW_ID = "PaseTemporada"

local player = Players.LocalPlayer

local enabled = false
local started = false
local BP: any = nil -- Controllers/BattlePassClient (solo se carga con el pase encendido)
local config: { [string]: any }? = nil
local state: { [string]: any }? = nil
local rowSignature = ""

-- La ventana abierta (nil si está cerrada)
type Ui = { [string]: any }
local ui: Ui? = nil
-- Lo que se recuerda entre aperturas
local section = "Rewards"
local lane = "Free"
local selected: { Track: string, Level: number }? = nil
local pending: { [string]: boolean } = {}
local buyPending = false
local claimAllPending = false

local function loadConfig(): { [string]: any }?
	local ok, result = pcall(function()
		return require((ReplicatedStorage :: any).Shared.BattlePass.Config)
	end)
	return if ok and type(result) == "table" then result else nil
end

function BattlePassUI.enabled(): boolean
	return enabled
end

function BattlePassUI.state(): { [string]: any }?
	return state
end

function BattlePassUI.isOpen(): boolean
	return ui ~= nil and ui.Window ~= nil and ui.Window.Parent ~= nil
end

local function rarityColor(key: string?): Color3?
	local rarities = config and config.Rarities
	local entry = rarities and rarities[key or ""]
	return if entry then entry.Color else nil
end

local function place(object: GuiObject, r: { X: number, Y: number, W: number, H: number })
	object.Position = UDim2.fromOffset(r.X, r.Y)
	object.Size = UDim2.fromOffset(r.W, r.H)
end

-- Botón del estilo del HUD (azul marino, filo cian al pasar el ratón)
local function button(parent: Instance, name: string, text: string, size: number, primary: boolean?): TextButton
	local b = Theme.button({
		Name = name,
		Text = text,
		TextSize = size,
		TextWrapped = true,
		BackgroundColor3 = if primary then H.Select else H.NavyLight,
		Parent = parent,
	})
	Theme.pressable(b)
	return b
end

local function setButton(b: TextButton, text: string, active: boolean, style: string?)
	Theme.setText(b, text)
	b.AutoButtonColor = active
	b.Active = active
	if style == "Primary" then
		b.BackgroundColor3 = H.Select
	elseif style == "Gold" then
		b.BackgroundColor3 = View.Colors.PremiumDark
	else
		b.BackgroundColor3 = H.NavyLight
	end
	b.BackgroundTransparency = if active then 0.05 else 0.45
	b.TextColor3 = if style == "Gold" then View.Colors.Premium elseif active then C.Text else C.Muted
end

-- Filo cian que brilla (como los paneles del HUD) sobre la ventana de Dialog
local function glow(frame: Frame)
	frame.BackgroundColor3 = H.Navy
	frame.BackgroundTransparency = 0.14
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = H.Glow
		stroke.Thickness = 2
		stroke.Transparency = 0.05
	end
	Theme.halo(frame, H.Glow, 8, 10)
end

-- Texto que se encoge un poco si no cabe (sin bajar de min)
local function fitText(label: TextLabel, max: number, min: number)
	label.TextScaled = true
	create("UITextSizeConstraint", { MaxTextSize = max, MinTextSize = min, Parent = label })
end

local function subPanel(parent: Instance, name: string, r: { X: number, Y: number, W: number, H: number }): Frame
	local frame = create("Frame", {
		Name = name,
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = parent,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }), create("UIGradient", { Rotation = 90, Color = Theme.PanelSheen }) })
	create("UIStroke", { Color = C.Stroke, Transparency = 0.6, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
	place(frame, r)
	return frame
end

---------------------------------------------------------------------
-- Tooltip (solo ordenador): una etiqueta junto al ratón con la descripción y el estado
---------------------------------------------------------------------
local tipGui: ScreenGui? = nil
local tipFrame: Frame? = nil

local function hideTip()
	if tipFrame then
		tipFrame.Visible = false
	end
end

local function showTip(reward: { [string]: any }?)
	if Theme.isTouch() or not reward then
		return
	end
	if not tipGui then
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			return
		end
		tipGui = create("ScreenGui", { Name = "BattlePassTip", ResetOnSpawn = false, DisplayOrder = 7, IgnoreGuiInset = true, Parent = playerGui })
		tipFrame = create("Frame", {
			Name = "Tip",
			Size = UDim2.fromOffset(280, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = H.Navy,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Visible = false,
			Parent = tipGui,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 8) }),
			create("UIStroke", { Color = H.Glow, Thickness = 1.5, Transparency = 0.2 }),
			create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
			create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		for i, name in { "TipName", "TipMeta", "TipText", "TipState" } do
			Theme.label({
				Name = name,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				TextSize = if i == 1 then 15 else 13,
				Font = if i == 1 or i == 4 then Theme.FontBold else Theme.Font,
				TextColor3 = if i == 3 then C.Muted else C.Text,
				LayoutOrder = i,
				Parent = tipFrame,
			})
		end
	end
	local frame = tipFrame :: Frame
	local info = View.stateInfo(reward.State)
	Theme.setText(frame:FindFirstChild("TipName") :: TextLabel, ("%s  %s"):format(tostring(reward.Icon or ""), tostring(reward.Name or "")))
	local meta = frame:FindFirstChild("TipMeta") :: TextLabel
	Theme.setText(meta, ("%s · %s · Nivel %s · %s"):format(tostring(reward.RarityName or ""), tostring(reward.TypeName or ""), View.levelText(reward.Level or 1), View.trackName(reward.Track)))
	meta.TextColor3 = if typeof(reward.RarityColor) == "Color3" then reward.RarityColor else C.Muted
	Theme.setText(frame:FindFirstChild("TipText") :: TextLabel, tostring(reward.Description or ""))
	local stateLabel = frame:FindFirstChild("TipState") :: TextLabel
	Theme.setText(stateLabel, info.Short)
	stateLabel.TextColor3 = info.Color
	local ok, mouse = pcall(function()
		return UserInputService:GetMouseLocation()
	end)
	if ok and typeof(mouse) == "Vector2" then
		local viewport = workspace.CurrentCamera.ViewportSize
		local x = math.min(mouse.X + 18, viewport.X - 290)
		local y = math.min(mouse.Y + 18, viewport.Y - 140)
		frame.Position = UDim2.fromOffset(x, y)
	end
	frame.Visible = true
end

---------------------------------------------------------------------
-- Acciones (todas son PETICIONES al servidor)
---------------------------------------------------------------------
local render: () -> () -- (se define más abajo)

local function claim(reward: { [string]: any }?)
	if not reward or reward.State ~= "AVAILABLE" or not BP then
		return
	end
	local key = reward.Track .. ":" .. reward.Level
	if pending[key] then
		return
	end
	if BP.claim(reward.Track, reward.Level) then
		pending[key] = true
		render()
	end
end

local function claimAll()
	if not BP or claimAllPending or View.available(state) == 0 then
		return
	end
	if BP.claimAll() then
		claimAllPending = true
		render()
	end
end

local function buy()
	local premium = state and state.Premium
	local _, can = View.buyText(premium)
	if not can or buyPending or not BP then
		return
	end
	if BP.buy() then
		buyPending = true
		render()
	end
end

local function equip(reward: { [string]: any })
	local slot = View.equipSlot(reward)
	if not slot or not BP then
		return
	end
	if slot == "Decor" then
		BP.equip("Decor", reward.Id) -- (pone o quita ese objeto)
	elseif View.isEquipped(state, reward) then
		BP.equip(slot, nil, if slot == "VehicleSkin" then reward.Kind else nil)
	else
		BP.equip(slot, reward.Id)
	end
end

-- Probar un gesto que ya es tuyo (en tu personaje; la animación se ve también para los demás)
local function tryEmote(reward: { [string]: any })
	local preview = type(reward.Preview) == "table" and reward.Preview or {}
	local id = preview.AnimationId
	if not id then
		return
	end
	pcall(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = create("Animation", { AnimationId = "rbxassetid://" .. tostring(id) })
			local track = (animator :: Animator):LoadAnimation(animation)
			track:Play(0.2, 1, tonumber(preview.Speed) or 1)
		end
	end)
end

local function track(id: string, on: boolean)
	if BP then
		BP.track(if on then id else nil)
	end
end

local missionActions = {
	track = track,
	reroll = function(id: string)
		if BP then
			BP.reroll(id)
		end
	end,
	choose = function(storyId: string, optionId: string)
		if BP then
			BP.choose(storyId, optionId)
		end
	end,
	buyToken = function(id: string)
		if BP and not pending["Token:" .. id] and BP.buyToken(id) then
			pending["Token:" .. id] = true
			render()
		end
	end,
	rarityColor = rarityColor,
	pending = pending,
}

---------------------------------------------------------------------
-- Pintar
---------------------------------------------------------------------
local function selectedReward(): { [string]: any }?
	if not state then
		return nil
	end
	if not selected or selected.Track ~= lane then
		selected = { Track = lane, Level = View.defaultLevel(state, lane) }
	end
	return View.find(state, lane, (selected :: any).Level)
end

local function scrollTo(level: number)
	if not ui then
		return
	end
	local R = ui.Layout.Rewards
	local pitch = R.Card.X + R.CardGap
	local x = (level - 1) * pitch - (R.Track.W - R.Card.X) / 2
	local maxX = math.max(0, ui.Track.CanvasSize.X.Offset - R.Track.W)
	ui.Track.CanvasPosition = Vector2.new(math.clamp(x, 0, maxX), 0)
end

local function renderFeatured(reward: { [string]: any }?)
	if not ui then
		return
	end
	local F = ui.Featured
	local T = ui.Layout.Text
	if ui.PreviewFor ~= (reward and reward.Id) then
		if ui.PreviewHandle then
			ui.PreviewHandle.destroy()
		end
		ui.PreviewHandle = Preview.mount(F.Preview, reward, { Touch = ui.Layout.Touch, TextSize = T.Small, HintSize = T.Small - 1 })
		ui.PreviewFor = reward and reward.Id
	end
	if not reward then
		Theme.setText(F.Name, "Cargando el pase…")
		Theme.setText(F.Meta, "")
		Theme.setText(F.Level, "")
		Theme.setText(F.Description, "")
		F.Primary.Visible = false
		F.Secondary.Visible = false
		return
	end
	local info = View.stateInfo(reward.State)
	Theme.setText(F.Name, tostring(reward.Name or ""))
	Theme.setText(F.Meta, ("%s · %s"):format(tostring(reward.RarityName or ""), tostring(reward.TypeName or "")))
	F.Meta.TextColor3 = if typeof(reward.RarityColor) == "Color3" then reward.RarityColor else C.Muted
	Theme.setText(F.Level, ("Nivel %s · %s · %s"):format(View.levelText(reward.Level), View.trackName(reward.Track), info.Short))
	F.Level.TextColor3 = info.Color
	local description = tostring(reward.Description or "")
	if type(reward.Items) == "table" and #reward.Items > 0 then
		local names = {}
		for _, item in reward.Items do
			table.insert(names, ("%s %s"):format(tostring(item.Icon or ""), tostring(item.Name or "")))
		end
		description ..= "\nIncluye: " .. table.concat(names, " · ")
	end
	Theme.setText(F.Description, description)
	-- Botones: principal según el estado; secundario (equipar / probar) solo con lo que ya es tuyo
	local key = reward.Track .. ":" .. reward.Level
	local secondary: string? = nil
	if reward.State == "CLAIMED" or reward.Owned then
		local slot = View.equipSlot(reward)
		if slot == "Decor" then
			secondary = if View.isEquipped(state, reward) then "QUITAR" else "PONER EN CASA"
		elseif slot then
			secondary = if View.isEquipped(state, reward) then "QUITAR" else "EQUIPAR"
		elseif reward.Type == "Emote" then
			secondary = "PROBAR"
		end
	end
	if reward.State == "AVAILABLE" then
		setButton(F.Primary, if pending[key] then "…" else "RECLAMAR", not pending[key], "Primary")
	elseif reward.State == "CLAIMED" then
		setButton(F.Primary, "✔ RECLAMADA", false)
	elseif reward.State == "PREMIUM_LOCKED" then
		local text, can = View.buyText(state and state.Premium)
		setButton(F.Primary, if buyPending then "…" else (if can then "⭐ " .. text else "⭐ PREMIUM · " .. text), can and not buyPending, "Gold")
	else
		local progress = state and state.Progress
		local need = if progress then reward.Level - (progress.Level or 1) else 0
		setButton(F.Primary, if need > 0 then ("🔒 Faltan %d nivel%s"):format(need, if need == 1 then "" else "es") else "🔒 BLOQUEADA", false)
	end
	F.Primary.Visible = true
	F.Secondary.Visible = secondary ~= nil
	local L = ui.Layout.Featured
	if secondary then
		place(F.Primary, L.Primary)
		setButton(F.Secondary, secondary, true)
	else
		place(F.Primary, L.Buttons)
	end
end

local function renderRewards()
	if not ui then
		return
	end
	local current = selectedReward()
	local progress = state and state.Progress
	local level = (progress and progress.Level) or 0
	local laneMap = View.lane(state, lane)
	for i, card in ui.Cards do
		local reward = laneMap[i]
		card:set(reward, {
			Current = reward ~= nil and reward.Level == level,
			Next = reward ~= nil and reward.Level == level + 1 and not (progress and progress.IsMax),
			Selected = current ~= nil and reward ~= nil and reward.Id == current.Id,
			Pending = reward ~= nil and pending[reward.Track .. ":" .. reward.Level] == true,
		})
	end
	-- Carriles
	local freeCount, premiumCount = View.available(state, "Free"), View.available(state, "Premium")
	for track, tab in { Free = ui.FreeTab, Premium = ui.PremiumTab } do
		local on = lane == track
		local count = if track == "Free" then freeCount else premiumCount
		local base = if track == "Free" then "GRATIS" else "⭐ PREMIUM"
		Theme.setText(tab, if count > 0 then ("%s · %d"):format(base, count) else base)
		tab.BackgroundColor3 = if on then (if track == "Premium" then View.Colors.PremiumDark else H.Select) else H.NavyLight
		tab.BackgroundTransparency = if on then 0 else 0.35
		tab.TextColor3 = if track == "Premium" then View.Colors.Premium elseif on then C.Text else C.Muted
	end
	local total = freeCount + premiumCount
	setButton(ui.ClaimAll, if claimAllPending then "…" elseif total > 0 then ("RECLAMAR TODO · %d"):format(total) else "RECLAMAR TODO", total > 0 and not claimAllPending, if total > 0 then "Primary" else nil)
	-- Franja: la oferta del premium en su carril (si no lo tienes), si no, lo siguiente que consigues
	local premium = state and state.Premium
	local showOffer = lane == "Premium" and premium ~= nil and not premium.Owned
	ui.Offer.Visible = showOffer
	ui.NextLine.Visible = not showOffer
	if showOffer then
		Theme.setText(ui.OfferText, View.premiumLine(state))
		local text, can = View.buyText(premium)
		setButton(ui.BuyButton, if buyPending then "…" else text, can and not buyPending, if can then "Gold" else nil)
	else
		local owned = premium ~= nil and premium.Owned
		local line = View.nextText(state, lane)
		if lane == "Premium" and owned then
			line = (if premium.Simulated and not premium.Purchased then "⭐ Premium simulado (modo pruebas) · " else "⭐ Pase premium activo · ") .. line
		end
		Theme.setText(ui.NextLine, line)
	end
	-- Misión destacada (ordenador)
	if ui.Spotlight then
		local mission = View.spotlight(state)
		ui.Spotlight.Visible = true
		if mission then
			Theme.setText(ui.SpotIcon, tostring(mission.Icon or "🎯"))
			Theme.setText(ui.SpotTitle, ("%s  ·  %s"):format(tostring(mission.Title or ""), View.missionReward(mission)))
			Theme.setText(ui.SpotProgress, View.missionProgress(mission))
			ui.SpotFill.Size = UDim2.fromScale(View.missionFraction(mission), 1)
		else
			Theme.setText(ui.SpotIcon, "✔")
			Theme.setText(ui.SpotTitle, "Todas las misiones de ahora están hechas")
			Theme.setText(ui.SpotProgress, "")
			ui.SpotFill.Size = UDim2.fromScale(1, 1)
		end
	end
	renderFeatured(current)
end

local function renderHeader()
	if not ui then
		return
	end
	local season = state and state.Season
	local progress = state and state.Progress
	Theme.setText(ui.Title, View.title(season))
	Theme.setText(ui.Days, View.timeLeft(season))
	local max = (season and season.MaxLevel) or 50
	local level = (progress and progress.Level) or 0
	Theme.setText(ui.LevelText, ("NIVEL %d / %d"):format(level, max))
	local xp, need = (progress and progress.Xp) or 0, (progress and progress.XpForNext) or 1
	local multiplier = progress and tonumber(progress.EventMultiplier) or 1
	local xpText = if progress and progress.IsMax then "NIVEL MÁXIMO" else ("%s / %s XP"):format(View.number(xp), View.number(need))
	if multiplier > 1 then
		xpText = ("×%s XP · %s"):format((("%.2f"):format(multiplier):gsub("0+$", ""):gsub("%.$", ""):gsub("%.", ",")), xpText)
	end
	Theme.setText(ui.XpText, xpText)
	ui.XpFill.Size = UDim2.fromScale(if progress and progress.IsMax then 1 else math.clamp(xp / math.max(1, need), 0, 1), 1)
	-- Secciones
	local counts = { Rewards = View.available(state), Missions = 0, Shop = 0 }
	for key, tab in ui.Tabs do
		local on = key == section
		tab.BackgroundColor3 = if on then H.Select else H.NavyLight
		tab.BackgroundTransparency = if on then 0 else 0.35
		tab.TextColor3 = if on then C.Text else C.Muted
		local dot = tab:FindFirstChild("Dot") :: TextLabel?
		if dot then
			local n = counts[key] or 0
			dot.Visible = n > 0
			Theme.setText(dot, tostring(n))
		end
	end
	Theme.setText(ui.Tabs.Shop, ("FICHAS · 🪙 %d"):format((progress and progress.Tokens) or 0))
	ui.RewardsPage.Visible = section == "Rewards"
	ui.MissionsPage.Visible = section == "Missions"
	ui.ShopPage.Visible = section == "Shop"
end

function render()
	if not BattlePassUI.isOpen() then
		return
	end
	local ok, err = pcall(function()
		renderHeader()
		if section == "Rewards" then
			renderRewards()
		elseif section == "Missions" then
			Pages.missions(ui.MissionsPage, ui.Layout, state, missionActions)
		elseif section == "Shop" then
			Pages.shop(ui.ShopPage, ui.Layout, state, missionActions)
		end
	end)
	if not ok then
		warn("[BattlePassUI] " .. tostring(err))
	end
end

---------------------------------------------------------------------
-- Construir la ventana
---------------------------------------------------------------------
local function setSection(name: string)
	section = name
	hideTip()
	render()
end

local function setLane(track: string)
	if lane ~= track then
		lane = track
		selected = nil
		render()
		if selected then
			scrollTo(selected.Level)
		end
	end
end

-- «Vista previa» del premium: su carril y su recompensa estrella en grande
local function previewPremium()
	section = "Rewards"
	lane = "Premium"
	local star = View.premiumHighlight(state)
	selected = if star then { Track = "Premium", Level = star.Level } else nil
	render()
	if selected then
		scrollTo(selected.Level)
	end
end

local function build()
	local touch = Theme.isTouch()
	local viewport = workspace.CurrentCamera.ViewportSize
	local L = Layout.compute(viewport, touch, Dialog.baseScale())
	local T = L.Text
	local frame, content, close = Dialog.window(NAME, View.title(state and state.Season), L.Window)
	glow(frame)
	local u: Ui = { Layout = L, Window = frame, Cards = {} }
	ui = u
	frame.Destroying:Connect(function()
		if ui == u then
			if u.PreviewHandle then
				u.PreviewHandle.destroy()
			end
			for _, connection in u.Connections or {} do
				connection:Disconnect()
			end
			ui = nil
			hideTip()
		end
	end)
	u.Connections = {}
	-- Título (en la barra de la ventana) y días
	local title = frame:FindFirstChild("Title") :: TextLabel
	place(title, L.Title)
	title.FontFace = Theme.TitleFace
	title.TextSize = T.Title
	title.TextWrapped = false
	title.TextTruncate = Enum.TextTruncate.AtEnd
	u.Title = title
	u.Close = close
	close.AnchorPoint = Vector2.new(0, 0)
	place(close, L.Close)
	u.Days = Theme.label({ Name = "Days", Text = "", TextSize = T.Small, TextColor3 = H.Glow, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame })
	place(u.Days, L.Days)
	fitText(u.Days, T.Small, T.Small - 4)
	place(content, L.Content)

	-- Cabecera: nivel y barra de XP
	local header = create("Frame", { Name = "Header", BackgroundTransparency = 1, Parent = content })
	place(header, L.Header)
	u.LevelText = Theme.label({ Name = "Level", Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0.5, 0, 0, 30), Text = "NIVEL 0 / 50", FontFace = Theme.TitleFace, TextSize = T.Big, Parent = header })
	u.XpText = Theme.label({ Name = "Xp", Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.new(0.5, 0, 0, 26), Text = "", TextSize = T.Small, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = header })
	fitText(u.XpText, T.Small, T.Small - 4)
	local bar = create("Frame", { Name = "XpBar", Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = H.Track, BorderSizePixel = 0, Parent = header }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = H.Edge, Transparency = 0.5, Thickness = 1 }),
	})
	u.XpFill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = H.Glow, BorderSizePixel = 0, Parent = bar }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 235, 255), Color3.fromRGB(60, 150, 255)) }),
	})

	-- Secciones
	local tabs = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, Parent = content })
	place(tabs, L.Tabs)
	u.Tabs = {}
	for i, entry in { { "Rewards", "RECOMPENSAS" }, { "Missions", "MISIONES" }, { "Shop", "FICHAS" } } do
		local tab = button(tabs, entry[1] .. "Tab", entry[2], T.Button)
		tab.TextWrapped = false
		place(tab, { X = (i - 1) * (L.TabWidth + 8), Y = 0, W = L.TabWidth, H = L.Button })
		local dot = Theme.label({ Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(230, 60, 80), Text = "", Font = Theme.FontBold, TextSize = math.max(T.Small - 2, 13), TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 3, Parent = tab })
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		tab.Activated:Connect(function()
			setSection(entry[1])
		end)
		u.Tabs[entry[1]] = tab
	end

	-- Página de recompensas
	local page = create("Frame", { Name = "Page", BackgroundTransparency = 1, Parent = content })
	place(page, L.Page)
	local R = L.Rewards
	local rewards = create("Frame", { Name = "Rewards", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = page })
	u.RewardsPage = rewards
	-- Recompensa elegida
	local featured = subPanel(rewards, "Featured", R.Featured)
	local FL = L.Featured
	local previewBox = create("Frame", { Name = "Preview", BackgroundColor3 = H.Track, BackgroundTransparency = 0.25, BorderSizePixel = 0, ClipsDescendants = true, Parent = featured }, {
		create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		create("UIGradient", { Rotation = 90, Color = Theme.Night }),
	})
	place(previewBox, FL.Preview)
	local F = { Preview = previewBox }
	F.Name = Theme.label({ Name = "RewardName", Text = "", FontFace = Theme.TitleFace, TextSize = T.Big - 2, TextTruncate = Enum.TextTruncate.AtEnd, Parent = featured })
	place(F.Name, FL.Name)
	F.Meta = Theme.label({ Name = "Meta", Text = "", Font = Theme.FontBold, TextSize = T.Small, Parent = featured })
	place(F.Meta, FL.Meta)
	F.Level = Theme.label({ Name = "LevelLine", Text = "", TextSize = T.Small, Parent = featured })
	place(F.Level, FL.Level)
	F.Description = Theme.label({ Name = "Description", Text = "", TextSize = T.Small, TextColor3 = C.Muted, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, TextYAlignment = Enum.TextYAlignment.Top, Parent = featured })
	place(F.Description, FL.Description)
	F.Primary = button(featured, "Primary", "", T.Button, true)
	place(F.Primary, FL.Buttons)
	F.Secondary = button(featured, "Secondary", "", T.Button)
	place(F.Secondary, FL.Secondary)
	F.Secondary.Visible = false
	F.Primary.Activated:Connect(function()
		local reward = selectedReward()
		if reward and reward.State == "AVAILABLE" then
			claim(reward)
		elseif reward and reward.State == "PREMIUM_LOCKED" then
			buy()
		end
	end)
	F.Secondary.Activated:Connect(function()
		local reward = selectedReward()
		if reward and View.equipSlot(reward) then
			equip(reward)
		elseif reward and reward.Type == "Emote" then
			tryEmote(reward)
		end
	end)
	u.Featured = F

	-- Carriles GRATIS / PREMIUM y «Reclamar todo»
	local lanes = create("Frame", { Name = "Lanes", BackgroundTransparency = 1, Parent = rewards })
	place(lanes, R.Lanes)
	u.FreeTab = button(lanes, "FreeLane", "GRATIS", T.Button)
	place(u.FreeTab, { X = 0, Y = 0, W = R.LaneTab.X, H = R.LaneTab.Y })
	u.PremiumTab = button(lanes, "PremiumLane", "⭐ PREMIUM", T.Button)
	place(u.PremiumTab, { X = R.LaneTab.X + 8, Y = 0, W = R.LaneTab.X, H = R.LaneTab.Y })
	u.FreeTab.Activated:Connect(function()
		setLane("Free")
	end)
	u.PremiumTab.Activated:Connect(function()
		setLane("Premium")
	end)
	u.ClaimAll = button(lanes, "ClaimAll", "RECLAMAR TODO", T.Button, true)
	place(u.ClaimAll, { X = R.Lanes.W - R.ClaimAll.X, Y = 0, W = R.ClaimAll.X, H = R.ClaimAll.Y })
	u.ClaimAll.Activated:Connect(claimAll)

	-- Franja: oferta del premium o lo siguiente
	local strip = subPanel(rewards, "Strip", R.Strip)
	u.NextLine = Theme.label({ Name = "NextLine", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Text = "", TextSize = T.Small, TextTruncate = Enum.TextTruncate.AtEnd, Parent = strip })
	local offer = create("Frame", { Name = "Offer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = strip })
	create("UIStroke", { Color = View.Colors.Premium, Transparency = 0.45, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = offer })
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = offer })
	local btnW = if touch then 180 else 150
	local buttonH = R.Strip.H - 4
	u.OfferText = Theme.label({ Name = "OfferText", Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -(24 + btnW * 2 + 8), 1, 0), Text = "", Font = Theme.FontBold, TextScaled = true, TextWrapped = true, TextColor3 = View.Colors.Premium, Parent = offer })
	create("UITextSizeConstraint", { MaxTextSize = T.Body, MinTextSize = math.max(10, T.Small - 3), Parent = u.OfferText })
	local previewButton = button(offer, "PreviewButton", "Vista previa", T.Button)
	place(previewButton, { X = R.Strip.W - 8 - btnW * 2 - 8, Y = 2, W = btnW, H = buttonH })
	previewButton.Activated:Connect(previewPremium)
	u.BuyButton = button(offer, "Buy", "Comprar", T.Button)
	place(u.BuyButton, { X = R.Strip.W - 8 - btnW, Y = 2, W = btnW, H = buttonH })
	u.BuyButton.Activated:Connect(buy)
	u.Offer = offer

	-- Fila de niveles 01…50 (se desplaza en horizontal; en el ordenador, también con la rueda)
	local trackFrame = create("ScrollingFrame", {
		Name = "Track",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = R.ScrollBar,
		ScrollBarImageColor3 = H.Glow,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		Parent = rewards,
	})
	place(trackFrame, R.Track)
	u.Track = trackFrame
	local max = (state and state.Season and state.Season.MaxLevel) or 50
	local pitch = R.Card.X + R.CardGap
	trackFrame.CanvasSize = UDim2.fromOffset(max * pitch - R.CardGap, 0)
	for i = 1, max do
		local card = RewardCard.new(trackFrame, L, Vector2.new((i - 1) * pitch, 0), "Card" .. View.levelText(i))
		card.Button.Activated:Connect(function()
			if card.Reward then
				selected = { Track = card.Reward.Track, Level = card.Reward.Level }
				render()
			end
		end)
		card.Claim.Activated:Connect(function()
			claim(card.Reward)
		end)
		if not touch then
			card.Button.MouseEnter:Connect(function()
				showTip(card.Reward)
			end)
			card.Button.MouseMoved:Connect(function()
				showTip(card.Reward)
			end)
			card.Button.MouseLeave:Connect(hideTip)
		end
		u.Cards[i] = card
	end
	if not touch then
		-- La rueda del ratón mueve la fila en horizontal
		table.insert(u.Connections, trackFrame.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local maxX = math.max(0, trackFrame.CanvasSize.X.Offset - R.Track.W)
				trackFrame.CanvasPosition = Vector2.new(math.clamp(trackFrame.CanvasPosition.X - input.Position.Z * pitch, 0, maxX), 0)
			end
		end))
	end

	-- Misión destacada (solo ordenador: en el móvil está en MISIONES, para no amontonar)
	if R.Spotlight then
		local spot = subPanel(rewards, "Spotlight", R.Spotlight)
		u.Spotlight = spot
		u.SpotIcon = Theme.label({ Name = "Icon", Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(34, 34), Text = "🎯", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = spot })
		local seeW = 150
		u.SpotTitle = Theme.label({ Name = "Mission", Position = UDim2.fromOffset(52, 5), Size = UDim2.new(1, -(52 + seeW + 16 + 90), 0, 22), Text = "", Font = Theme.FontBold, TextSize = T.Small, TextTruncate = Enum.TextTruncate.AtEnd, Parent = spot })
		local spotBar = create("Frame", { Name = "Bar", Position = UDim2.fromOffset(52, 32), Size = UDim2.new(1, -(52 + seeW + 16 + 90), 0, 8), BackgroundColor3 = H.Track, BorderSizePixel = 0, Parent = spot }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		u.SpotFill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = H.Glow, BorderSizePixel = 0, Parent = spotBar }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		u.SpotProgress = Theme.label({ Name = "Progress", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(seeW + 16), 0, 0), Size = UDim2.new(0, 84, 1, 0), Text = "", TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Right, Parent = spot })
		local see = button(spot, "SeeMissions", "VER MISIONES", T.Button)
		place(see, { X = R.Spotlight.W - seeW - 8, Y = math.floor((R.Spotlight.H - L.Button) / 2), W = seeW, H = L.Button })
		see.Activated:Connect(function()
			setSection("Missions")
		end)
	end

	-- Páginas de misiones y fichas (listas verticales)
	local function listPage(name: string): ScrollingFrame
		return create("ScrollingFrame", {
			Name = name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = L.Missions.ScrollBar,
			ScrollBarImageColor3 = H.Glow,
			CanvasSize = UDim2.new(),
			Visible = false,
			Parent = page,
		})
	end
	u.MissionsPage = listPage("Missions")
	u.ShopPage = listPage("Shop")

	-- Si la pantalla cambia de tamaño (girar el móvil), se vuelve a montar a la medida
	table.insert(u.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.defer(function()
			if ui ~= u or not BattlePassUI.isOpen() then
				return
			end
			-- (solo si cambia la medida de la ventana: arrastrar el borde no la rehace a cada paso)
			local now = Layout.compute(workspace.CurrentCamera.ViewportSize, touch, Dialog.baseScale())
			if now.Window ~= u.Layout.Window then
				local keep = section
				BattlePassUI.close()
				BattlePassUI.open(keep)
			end
		end)
	end))
	render()
	local chosen = selectedReward()
	scrollTo(if chosen then chosen.Level else ((state and state.Progress and state.Progress.Level) or 1))
end

---------------------------------------------------------------------
-- Abrir y cerrar
---------------------------------------------------------------------
function BattlePassUI.open(which: string?)
	if not enabled then
		return
	end
	if which == "Rewards" or which == "Missions" or which == "Shop" then
		section = which
	end
	if BP then
		BP.refresh() -- (estado fresco; mientras llega, se pinta el último guardado)
	end
	if BattlePassUI.isOpen() then
		render()
		return
	end
	build()
end

function BattlePassUI.close()
	hideTip()
	if ui and ui.Window and ui.Window.Parent then
		ui.Window:Destroy()
	end
	ui = nil
end

function BattlePassUI.toggle()
	if BattlePassUI.isOpen() then
		BattlePassUI.close()
	else
		BattlePassUI.open()
	end
end

---------------------------------------------------------------------
-- Entradas: fila de COMANDOS, tecla y avisos
---------------------------------------------------------------------
local function refreshRow()
	local visible = View.rowVisible(enabled, state)
	local available = View.available(state)
	local level = (state and state.Progress and state.Progress.Level) or 0
	local signature = ("%s|%d|%d"):format(tostring(visible), available, level)
	if signature == rowSignature then
		return
	end
	rowSignature = signature
	pcall(function()
		local CommandMenu = require(script.Parent.Parent.Commands.CommandMenu :: any)
		if CommandMenu.refresh then
			CommandMenu.refresh()
		end
	end)
	-- Si la temporada deja de estar en marcha con la ventana abierta, se cierra
	if not visible and BattlePassUI.isOpen() then
		BattlePassUI.close()
	end
end

local function registerRow()
	local ok, err = pcall(function()
		local CommandRegistry = require(script.Parent.Parent.Commands.CommandRegistry :: any)
		-- (proveedor: el detalle y el punto rojo cambian con el estado)
		CommandRegistry.addProvider(function(ctx)
			if ctx.Stage == "Bebe" or not View.rowVisible(enabled, state) then
				return {}
			end
			local available = View.available(state)
			local level = (state and state.Progress and state.Progress.Level) or 0
			return {
				{
					Id = ROW_ID,
					Label = "Pase de temporada",
					Detail = if available > 0 then ("Nv. %d · %d por reclamar"):format(level, available) else ("Nv. %d"):format(level),
					Icon = "🏆",
					Priority = 55.5, -- (con las apps: después de Mapa y antes de «Más»)
					Badge = available > 0,
					Run = function()
						BattlePassUI.toggle()
					end,
				},
			}
		end)
	end)
	if not ok then
		warn("[BattlePassUI] Fila de comandos: " .. tostring(err))
	end
end

local function toast(kind: string, text: string)
	pcall(function()
		local Hud = require(script.Parent.Hud :: any)
		Hud.toast(kind, text)
	end)
end

-- Aviso discreto al subir de nivel: «RECOMPENSA DESBLOQUEADA» (sin ventanas ni pausas)
local function onUnlocked(info: any)
	if type(info) ~= "table" or type(info.Rewards) ~= "table" then
		return
	end
	local ready = {}
	for _, reward in info.Rewards do
		if reward.State == "AVAILABLE" then
			table.insert(ready, reward)
		end
	end
	if #ready == 0 then
		-- (nada nuevo que reclamar: si el servidor no avisó, un aviso corto del nivel)
		if info.Notified == false and tonumber(info.Level) then
			toast("Success", ("🎟 Pase de temporada · Nv. %d"):format(tonumber(info.Level) :: number))
		end
		return
	end
	local hint = if Theme.isTouch() then "" else " · N para verla"
	local text
	if #ready == 1 then
		text = ("🏆 RECOMPENSA DESBLOQUEADA · Nv. %s · %s%s"):format(View.levelText(ready[1].Level or 1), tostring(ready[1].Name or ""), hint)
	else
		text = ("🏆 RECOMPENSAS DESBLOQUEADAS · Nv. %d · %d nuevas%s"):format(tonumber(info.Level) or 0, #ready, hint)
	end
	toast("Success", text)
end

local function onState(new: { [string]: any })
	state = new
	-- Lo pendiente se resuelve con el estado nuevo (el servidor manda la verdad)
	for key in pending do
		pending[key] = nil
	end
	claimAllPending = false
	refreshRow()
	render()
end

local function onResult(result: any)
	if type(result) ~= "table" then
		return
	end
	if result.Action == "Buy" then
		buyPending = false
		render()
	elseif result.Action == "ClaimAll" then
		claimAllPending = false
		render()
	elseif result.Action == "Claim" and not result.Ok and result.Track and result.Level then
		pending[tostring(result.Track) .. ":" .. tostring(result.Level)] = nil
		render()
	elseif result.Action == "BuyToken" and not result.Ok and result.Item then
		pending["Token:" .. tostring(result.Item)] = nil
		render()
	end
end

function BattlePassUI.init()
	config = loadConfig()
	enabled = config ~= nil and config.Enabled == true
	if not enabled or started then
		return -- (pase apagado: BattlePassConfig.Enabled = false -> nada de nada)
	end
	started = true
	BP = require(script.Parent.Parent.Controllers.BattlePassClient :: any)
	BP.setLevelUpToasts(true) -- (el aviso de nivel lo enseña onUnlocked: el servidor no repite el suyo)
	Dialog.registerBig(NAME, BattlePassUI.close)
	registerRow()
	-- Tu tema del HUD y del teléfono (solo colores; lo que llevas lo dice el servidor con atributos)
	local okSkin, errSkin = pcall(function()
		require(script.Parent.BattlePassCosmetics :: any).start()
	end)
	if not okSkin then
		warn("[BattlePassUI] Temas: " .. tostring(errSkin))
	end
	BP.onState(onState)
	BP.on("Unlocked", onUnlocked)
	BP.on("Result", onResult)
	BP.on("Premium", function()
		buyPending = false
		lane = "Premium"
		selected = nil
		render()
	end)
	BP.start()
	-- Tecla rápida (ordenador): N abre y cierra
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= HOTKEY then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if View.rowVisible(enabled, state) and player:GetAttribute("LifeStage") ~= "Bebe" then
			BattlePassUI.toggle()
		end
	end)
end

-- Para las pruebas: la medida y la ventana abiertas
function BattlePassUI._debug(): { [string]: any }
	return { Ui = ui, Section = section, Lane = lane, Selected = selected, Pending = pending }
end

return BattlePassUI
