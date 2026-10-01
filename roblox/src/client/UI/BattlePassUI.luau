-- BattlePassUI: la pantalla del pase de temporada («Luces de Valmar») y sus entradas.
--
--   BattlePassUI.init()           -> lo llama Main.client (safeInit). Con BattlePassConfig.Enabled = false
--                                    no hace NADA (salvo a los testers): ni fila, ni tecla, ni ventana, ni remoto.
--   BattlePassUI.open(section?)   -> "Rewards" (por defecto) | "Missions" | "Shop"
--   BattlePassUI.close() / toggle() / isOpen() / state()
--   Aviso de nivel: la interfaz se lo dice al servidor (BattlePassClient.setLevelUpToasts) y este ya no
--                                    manda su Notify de «¡nivel n!»: solo sale «RECOMPENSA DESBLOQUEADA».
--   Cosméticos equipados (tema del teléfono y del HUD): UI/BattlePassCosmetics, que se arranca aquí.
--
-- Entradas: la app «🏆 Pase de temporada» del ValPhone, la tecla N en el ordenador, el aviso de recompensa
-- desbloqueada y, UNA VEZ POR SESIÓN, sola al entrar: después de la pantalla de inicio (la tarjeta
-- «Al volver» de la historia) y nunca encima del prólogo, el tutorial de un jugador nuevo, la etapa de
-- bebé, una conversación, una escena u otra ventana (BattlePassView.autoOpenBlock). Un jugador nuevo
-- la ve al acabar su tutorial (o en su segunda sesión). Siempre se cierra con el ✖; nada obliga a comprar.
--
-- Diseño (estilo del HUD y del ValPhone: azul marino, filo cian, dorado para lo premium):
--   * Barra de arriba: «🏆 PASE DE TEMPORADA», RECOMPENSAS / MISIONES / FICHAS, tu dinero y el ✖ (sin
--     repetir el menú del juego).
--   * Cabecera: emblema dorado, «TEMPORADA 1 · PASE DE TEMPORADA», «LUCES DE VALMAR», subtítulo, cuenta
--     atrás real («Termina en: 32 días 14 horas») y el botón dorado «👑 COMPRAR PASE PREMIUM» (o
--     «✔ PREMIUM ACTIVO»; con GamePassId = 0, «MUY PRONTO» y solo enseña los beneficios).
--   * A la derecha, la recompensa estrella (el Aurora X «Faro de Valmar» del nivel 50) en 3D girando
--     sobre un cielo de atardecer, con su rareza y «Ver recompensas». Al tocar otra tarjeta, sale esa.
--   * Dos filas que se desplazan juntas: GRATIS · Pase normal y PREMIUM · Pase de temporada, con la
--     línea de niveles en medio (los alcanzados resaltados y el tuyo marcado). «IR A MI NIVEL».
--   * Pie: hexágono TU NIVEL, barra de XP, RECLAMAR TODO y la caja del premium con VER BENEFICIOS.
--   En el móvil todo se escala a la pantalla, las filas se arrastran con el dedo y los botones son grandes.
--
-- Rendimiento: solo la recompensa destacada gira (mientras la pantalla está abierta). Lo demás se
-- repinta cuando llega un estado nuevo del servidor (uno cada 0,5 s como mucho) o al tocar algo.
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
local rgb = Color3.fromRGB

local BattlePassUI = {}

local NAME = "BattlePass"
local HOTKEY = Enum.KeyCode.N -- (B es la piedra, M el mapa, E usar, H ayuda, J historia)
local ROW_ID = "PaseTemporada"

-- Colores de la pantalla (los del HUD + el dorado del premium y el plata del pase normal)
local GOLD = View.Colors.Premium
local GOLD_DEEP = rgb(214, 140, 28)
local SILVER = rgb(196, 206, 224)
-- Cielo de atardecer detrás de la recompensa destacada (de arriba abajo: noche, violeta, naranja)
local SUNSET = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(20, 30, 78)),
	ColorSequenceKeypoint.new(0.45, rgb(92, 62, 140)),
	ColorSequenceKeypoint.new(0.78, rgb(236, 120, 92)),
	ColorSequenceKeypoint.new(1, rgb(255, 188, 96)),
})

local player = Players.LocalPlayer

local enabled = false
local started = false
local BP: any = nil -- Controllers/BattlePassClient (solo se carga con el pase encendido)
local config: { [string]: any }? = nil
local state: { [string]: any }? = nil
local stateClock = 0 -- os.clock() al llegar el estado (para la cuenta atrás en vivo)
local rowSignature = ""

-- La ventana abierta (nil si está cerrada)
type Ui = { [string]: any }
local ui: Ui? = nil
-- Lo que se recuerda entre aperturas
local section = "Rewards"
local selected: { Track: string, Level: number }? = nil -- nil = la recompensa estrella
local pending: { [string]: boolean } = {}
local buyPending = false
local claimAllPending = false
local benefitsOpen = false

-- Apertura sola al entrar (una vez por sesión)
local auto = { Shown = false, StartedAt = nil :: number?, FreeSince = nil :: number?, Opened = false }

local function loadConfig(): { [string]: any }?
	local ok, result = pcall(function()
		return require((ReplicatedStorage :: any).Shared.BattlePass.Config)
	end)
	return if ok and type(result) == "table" then result else nil
end

local function money(n: number): string
	local ok, text = pcall(function()
		return require((ReplicatedStorage :: any).Shared.Format).money(n)
	end)
	return if ok and type(text) == "string" then text else View.number(n) .. " €"
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
		b.BackgroundColor3 = GOLD
	elseif style == "GoldDim" then
		b.BackgroundColor3 = View.Colors.PremiumDark
	else
		b.BackgroundColor3 = H.NavyLight
	end
	b.BackgroundTransparency = if active or style == "GoldDim" then 0.02 else 0.45
	b.TextColor3 = if style == "Gold" then C.Ink elseif style == "GoldDim" then GOLD elseif active then C.Text else C.Muted
end

local function panel(parent: Instance, name: string, color: Color3?, transparency: number?): Frame
	local frame = create("Frame", {
		Name = name,
		BackgroundColor3 = color or H.Navy,
		BackgroundTransparency = transparency or 0.3,
		BorderSizePixel = 0,
		Parent = parent,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }), create("UIGradient", { Rotation = 90, Color = Theme.PanelSheen }) })
	return frame
end

local function stroke(parent: Instance, color: Color3, transparency: number?, thickness: number?): UIStroke
	return create("UIStroke", { Color = color, Transparency = transparency or 0.3, Thickness = thickness or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end

-- Hexágono (como el emblema y el «TU NIVEL» de la referencia) sin imágenes: tres rectángulos girados
-- 30°, 90° y 150° forman un hexágono con pico arriba. size = alto; ocupa (0,866·size × size).
local function hexagon(parent: Instance, name: string, size: number, color: Color3, z: number?): Frame
	local holder = create("Frame", {
		Name = name,
		Size = UDim2.fromOffset(math.floor(size * 0.866), size),
		BackgroundTransparency = 1,
		ZIndex = z or 1,
		Parent = parent,
	})
	for i, angle in { 30, 90, 150 } do
		create("Frame", {
			Name = "Side" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(math.floor(size / 2), math.floor(size * 0.866)),
			Rotation = angle,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z or 1,
			Parent = holder,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 2) }) })
	end
	return holder
end

-- Emblema: hexágono dorado con borde, otro más oscuro dentro y el icono encima
local function emblem(parent: Instance, name: string, size: number, icon: string, inner: Color3?): Frame
	local outer = hexagon(parent, name, size, GOLD, 2)
	local w = math.floor(size * 0.866)
	local pad = math.max(3, math.floor(size * 0.08))
	local core = hexagon(outer, "Core", size - 2 * pad, inner or rgb(120, 76, 14), 3)
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	Theme.label({
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(math.floor(w * 0.62), math.floor(size * 0.5)),
		Text = icon,
		TextScaled = true,
		Font = Theme.FontBold,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
		Parent = outer,
	})
	return outer
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
	Theme.setText(stateLabel, if reward.State == "AVAILABLE" then "DISPONIBLE · toca para reclamar" else info.Short)
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

local function toast(kind: string, text: string)
	pcall(function()
		local Hud = require(script.Parent.Hud :: any)
		Hud.toast(kind, text)
	end)
end

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

local function setBenefits(on: boolean)
	benefitsOpen = on
	render()
end

-- El botón dorado: compra (Roblox abre su ventana), o, sin Game Pass todavía, el aviso de «muy pronto»
local function buy()
	local info = View.heroBuy(state and state.Premium)
	if info.Kind == "Soon" then
		toast("Info", "👑 El pase premium llegará muy pronto. Todo lo gratis ya se puede conseguir jugando.")
		setBenefits(true)
		return
	end
	if info.Kind ~= "Buy" or buyPending or not BP then
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

local missionActions = {
	track = function(id: string, on: boolean)
		if BP then
			BP.track(if on then id else nil)
		end
	end,
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
	rarityColor = function(key: string?): Color3?
		local rarities = config and config.Rarities
		local entry = rarities and rarities[key or ""]
		return if entry then entry.Color else nil
	end,
	pending = pending,
}

---------------------------------------------------------------------
-- Pintar
---------------------------------------------------------------------
-- La recompensa que se enseña en grande: la elegida o, si no, la estrella del premium
local function featuredReward(): ({ [string]: any }?, boolean)
	if selected then
		local reward = View.find(state, selected.Track, selected.Level)
		if reward then
			return reward, false
		end
	end
	return View.premiumHighlight(state), true
end

local function scrollTo(level: number)
	if not ui then
		return
	end
	local R = ui.Layout.Rows
	local x = (level - 1) * R.Pitch - (R.Scroll.W - R.CardW) / 2
	local maxX = math.max(0, ui.Scroll.CanvasSize.X.Offset - R.Scroll.W)
	ui.Scroll.CanvasPosition = Vector2.new(math.clamp(x, 0, maxX), 0)
end

-- Hora del servidor de ahora (la del último estado + lo que ha pasado desde que llegó)
local function serverNow(): number?
	local season = state and state.Season
	local now = season and tonumber(season.Now)
	if not now then
		return nil
	end
	return now + math.max(0, os.clock() - stateClock)
end

local function renderCountdown()
	if not ui then
		return
	end
	local prefix, left = View.countdown(state and state.Season, serverNow())
	Theme.setText(ui.CountPrefix, prefix)
	Theme.setText(ui.CountText, left)
end

local function renderFeatured()
	if not ui then
		return
	end
	local F = ui.Featured
	local reward, isStar = featuredReward()
	if ui.PreviewFor ~= (reward and reward.Id) then
		if ui.PreviewHandle then
			ui.PreviewHandle.destroy()
		end
		local T = ui.Layout.Text
		ui.PreviewHandle = Preview.mount(F.Stage, reward, { Touch = ui.Layout.Touch, TextSize = T.Small, HintSize = T.Small - 1, Spin = 18, Hint = not ui.Layout.Touch })
		ui.PreviewFor = reward and reward.Id
	end
	if not reward then
		Theme.setText(F.Kicker, "RECOMPENSA ESTRELLA")
		Theme.setText(F.Name, "Cargando el pase…")
		F.Rarity.Visible = false
		F.Detail.Visible = false
		F.Action.Visible = false
		F.See.Visible = false
		return
	end
	local track = View.trackName(reward.Track)
	Theme.setText(F.Kicker, if isStar then ("RECOMPENSA ESTRELLA · NIVEL %d"):format(reward.Level or 50) else ("NIVEL %s · %s"):format(View.levelText(reward.Level or 1), track))
	F.Kicker.TextColor3 = if reward.Track == "Premium" then GOLD else SILVER
	Theme.setText(F.Name, tostring(reward.Name or ""))
	local rarity = if typeof(reward.RarityColor) == "Color3" then reward.RarityColor else C.Muted
	Theme.setText(F.Rarity, View.rarityTag(reward))
	F.Rarity.BackgroundColor3 = rarity
	F.Rarity.Visible = true
	-- Detalle: de qué es y cómo está
	local line
	if reward.State == "AVAILABLE" then
		line = "✨ ¡Lista para reclamar!"
	elseif reward.State == "CLAIMED" then
		line = "✔ Ya es tuya"
	elseif reward.State == "PREMIUM_LOCKED" then
		line = ("👑 Pase premium · nivel %d"):format(reward.Level or 1)
	else
		local level = (state and state.Progress and state.Progress.Level) or 0
		local need = (reward.Level or 1) - level
		line = if need > 0 then ("🔒 Faltan %d nivel%s"):format(need, if need == 1 then "" else "es") else "🔒 Bloqueada"
	end
	local stats = View.statsText(reward.Stats)
	Theme.setText(F.Detail, ("%s · %s%s"):format(tostring(reward.TypeName or ""), line, if stats ~= "" and not ui.Layout.Touch then "\n" .. stats else ""))
	F.Detail.Visible = ui.Layout.Hero.FeaturedParts.Detail.H >= 16
	-- Botón de acción según el estado (lo que ya es tuyo se equipa o se prueba)
	local action: string? = nil
	local style: string? = "Primary"
	local key = reward.Track .. ":" .. reward.Level
	if reward.State == "AVAILABLE" then
		action = if pending[key] then "…" else "RECLAMAR"
	elseif reward.State == "CLAIMED" or reward.Owned then
		local slot = View.equipSlot(reward)
		style = nil
		if slot == "Decor" then
			action = if View.isEquipped(state, reward) then "QUITAR" else "PONER EN CASA"
		elseif slot then
			action = if View.isEquipped(state, reward) then "QUITAR" else "EQUIPAR"
		elseif reward.Type == "Emote" then
			action = "PROBAR"
		end
	elseif reward.State == "PREMIUM_LOCKED" then
		action = "👑 PREMIUM"
		style = "GoldDim"
	end
	local P = ui.Layout.Hero.FeaturedParts
	F.See.Visible = true
	F.Action.Visible = action ~= nil
	if action then
		place(F.See, P.SeeHalf)
		Theme.setText(F.See, "👁 Ver")
		setButton(F.Action, action, not pending[key], style)
	else
		place(F.See, P.See)
		Theme.setText(F.See, "👁 Ver recompensas")
	end
end

local function renderHero()
	if not ui then
		return
	end
	local season = state and state.Season
	Theme.setText(ui.Kicker, ("TEMPORADA %s · PASE DE TEMPORADA"):format(tostring(season and season.Number or 1)))
	Theme.setText(ui.SeasonName, string.upper(tostring(season and season.Name or "Pase de temporada")))
	renderCountdown()
	local info = View.heroBuy(state and state.Premium)
	local text = info.Text
	if info.Price and ui.Layout.Hero.InfoParts.Buy.W >= 340 then
		text ..= " · " .. info.Price
	end
	if buyPending then
		text = "…"
	end
	if info.Kind == "Owned" then
		setButton(ui.Buy, text, false, "GoldDim")
	elseif info.Kind == "Off" then
		setButton(ui.Buy, text, false)
	else
		setButton(ui.Buy, text, not buyPending, "Gold")
	end
	ui.Buy:SetAttribute("Kind", info.Kind)
	renderFeatured()
end

local function renderRows()
	if not ui then
		return
	end
	local progress = state and state.Progress
	local level = (progress and progress.Level) or 0
	local current = featuredReward()
	for _, track in { "Free", "Premium" } do
		local laneMap = View.lane(state, track)
		for i, card in ui.Cards[track] do
			local reward = laneMap[i]
			card:set(reward, {
				Current = reward ~= nil and reward.Level == level,
				Selected = selected ~= nil and current ~= nil and reward ~= nil and reward.Id == current.Id,
				Pending = reward ~= nil and pending[reward.Track .. ":" .. reward.Level] == true,
			})
		end
	end
	-- Línea de niveles: los alcanzados resaltados y el tuyo marcado
	local max = #ui.Nodes
	for i, node in ui.Nodes do
		local reached = i <= level
		local here = i == level
		node.BackgroundColor3 = if here then GOLD elseif reached then H.Select else H.Navy
		node.BackgroundTransparency = if reached then 0 else 0.2
		node.TextColor3 = if here then C.Ink elseif reached then C.Text else C.Muted
		local edge = node:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Color = if here then rgb(255, 255, 255) elseif reached then H.Glow else C.Stroke
			edge.Transparency = if reached then 0 else 0.6
		end
		node:SetAttribute("Reached", reached)
		node:SetAttribute("Current", here)
		local R = ui.Layout.Rows
		local size = if here then R.LineH - 2 else R.LineH - 8
		node.Size = UDim2.fromOffset(size, size)
	end
	local fraction = if max > 1 then math.clamp((level - 1) / (max - 1), 0, 1) else 0
	ui.LineFill.Size = UDim2.new(fraction, 0, 1, 0)
	-- Carril premium: ⭐ si lo tienes
	local premium = state and state.Premium
	Theme.setText(ui.PremiumLaneSub, if premium and premium.Owned then "✔ Activo" else "Pase de temporada")
end

local function renderFooter()
	if not ui then
		return
	end
	local progress = state and state.Progress
	local level = (progress and progress.Level) or 0
	Theme.setText(ui.LevelNumber, tostring(level))
	local xp, need = (progress and progress.Xp) or 0, (progress and progress.XpForNext) or 1
	local multiplier = progress and tonumber(progress.EventMultiplier) or 1
	local xpText = if progress and progress.IsMax then "NIVEL MÁXIMO" else ("%s / %s XP"):format(View.number(xp), View.number(need))
	if multiplier > 1 then
		xpText = ("×%s · %s"):format((("%.2f"):format(multiplier):gsub("0+$", ""):gsub("%.$", ""):gsub("%.", ",")), xpText)
	end
	Theme.setText(ui.XpText, xpText)
	ui.XpFill.Size = UDim2.fromScale(if progress and progress.IsMax then 1 else math.clamp(xp / math.max(1, need), 0, 1), 1)
	local total = View.available(state)
	setButton(ui.ClaimAll, if claimAllPending then "…" elseif total > 0 then ("RECLAMAR TODO · %d"):format(total) else "RECLAMAR TODO", total > 0 and not claimAllPending, if total > 0 then "Primary" else nil)
	local premium = state and state.Premium
	local owned = premium ~= nil and premium.Owned
	Theme.setText(ui.PremiumIcon, if owned then "👑" else "🔒")
	local touch = ui.Layout.Touch
	local line
	if owned then
		line = if touch then "Premium activo: todo es tuyo al subir" else "Pase premium activo: cada nivel te da también su recompensa premium"
	else
		line = if touch then "Desbloquea todas las recompensas" else "Desbloquea el pase premium para obtener todas las recompensas"
	end
	Theme.setText(ui.PremiumText, line)
end

local function renderBenefits()
	if not ui then
		return
	end
	local B = ui.Benefits
	B.Frame.Visible = benefitsOpen
	if not benefitsOpen then
		return
	end
	local list = View.premiumBenefits(state)
	for _, child in B.List:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local T = ui.Layout.Text
	local rowH = if ui.Layout.Touch then 30 else 28
	for i, item in list do
		Theme.label({
			Name = "Benefit" .. i,
			Position = UDim2.fromOffset(4, (i - 1) * rowH),
			Size = UDim2.new(1, -8, 0, rowH),
			Text = ("%s  %s"):format(item.Icon, item.Text),
			TextSize = T.Body,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = B.List,
		})
	end
	B.List.CanvasSize = UDim2.fromOffset(0, #list * rowH)
	local info = View.heroBuy(state and state.Premium)
	local note = ""
	if info.Kind == "Soon" then
		note = "Muy pronto a la venta. Mientras, la pista gratis sigue completa."
	elseif info.Kind == "Owned" then
		note = "Ya lo tienes: gracias por apoyar Valmar."
	elseif info.Price then
		note = ("Precio: %s (lo pone Roblox al comprar). Pago único para esta temporada."):format(info.Price)
	end
	Theme.setText(B.Note, note)
	if info.Kind == "Buy" then
		setButton(B.Buy, if buyPending then "…" else "👑 COMPRAR PASE PREMIUM", not buyPending, "Gold")
	elseif info.Kind == "Owned" then
		setButton(B.Buy, "✔ PREMIUM ACTIVO", false, "GoldDim")
	else
		setButton(B.Buy, if info.Kind == "Soon" then "MUY PRONTO" else "NO DISPONIBLE", false, "GoldDim")
	end
end

local function renderTop()
	if not ui then
		return
	end
	local progress = state and state.Progress
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
	Theme.setText(ui.Money, "💶 " .. money(tonumber(player:GetAttribute("Money")) or 0))
	ui.RewardsPage.Visible = section == "Rewards"
	ui.MissionsPage.Visible = section == "Missions"
	ui.ShopPage.Visible = section == "Shop"
end

function render()
	if not BattlePassUI.isOpen() then
		return
	end
	local ok, err = pcall(function()
		renderTop()
		if section == "Rewards" then
			renderHero()
			renderRows()
			renderFooter()
		elseif section == "Missions" then
			Pages.missions(ui.MissionsPage, ui.Layout, state, missionActions)
		elseif section == "Shop" then
			Pages.shop(ui.ShopPage, ui.Layout, state, missionActions)
		end
		renderBenefits()
	end)
	if not ok then
		warn("[BattlePassUI] " .. tostring(err))
	end
end

---------------------------------------------------------------------
-- Construir la pantalla
---------------------------------------------------------------------
local function setSection(name: string)
	section = name
	benefitsOpen = false
	hideTip()
	render()
end

local function select(reward: { [string]: any }?)
	if reward then
		selected = { Track = reward.Track, Level = reward.Level }
		render()
	end
end

local function jumpToMine()
	local level = (state and state.Progress and state.Progress.Level) or 1
	scrollTo(math.max(1, level))
end

-- El contador se refresca solo mientras la pantalla está abierta (cada 30 s; nada por fotograma)
local function tick(u: Ui)
	task.delay(30, function()
		if ui == u and BattlePassUI.isOpen() then
			renderCountdown()
			tick(u)
		end
	end)
end

local function buildHero(u: Ui, parent: Instance)
	local L = u.Layout
	local T = L.Text
	local Hh = L.Hero
	local hero = create("Frame", { Name = "Hero", BackgroundTransparency = 1, Parent = parent })
	place(hero, Hh.Frame)
	-- Información (izquierda)
	local info = panel(hero, "Info", H.Navy, 0.35)
	place(info, Hh.Info)
	stroke(info, GOLD, 0.6, 1.5)
	local I = Hh.InfoParts
	local badge = emblem(info, "Emblem", I.Emblem.H, "👑")
	badge.Position = UDim2.fromOffset(I.Emblem.X + math.floor((I.Emblem.W - math.floor(I.Emblem.H * 0.866)) / 2), I.Emblem.Y)
	u.Kicker = Theme.label({ Name = "Kicker", Text = "", Font = Theme.FontBold, TextSize = T.Small, TextColor3 = SILVER, TextTruncate = Enum.TextTruncate.AtEnd, Parent = info })
	place(u.Kicker, I.Kicker)
	u.SeasonName = Theme.label({ Name = "SeasonName", Text = "", FontFace = Theme.TitleFace, TextScaled = true, TextColor3 = rgb(255, 255, 255), Parent = info })
	place(u.SeasonName, I.Name)
	create("UITextSizeConstraint", { MaxTextSize = if Hh.Compact then (if L.Touch then 28 else 32) else 44, MinTextSize = 14, Parent = u.SeasonName })
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 236, 170), GOLD_DEEP), Parent = u.SeasonName })
	u.Subtitle = Theme.label({
		Name = "Subtitle",
		Text = "Completa misiones, sube de nivel y desbloquea recompensas exclusivas.",
		TextSize = T.Small,
		TextColor3 = C.Text,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = info,
	})
	place(u.Subtitle, I.Subtitle)
	-- Cuenta atrás
	local count = panel(info, "Countdown", H.Track, 0.15)
	place(count, I.Countdown)
	stroke(count, C.Stroke, 0.55, 1)
	Theme.label({ Name = "Clock", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0, 22, 1, 0), Text = "⏱", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = count })
	local textW = I.Countdown.W - 38
	local prefixW = math.min(math.floor(textW * 0.45), if L.Touch then 92 else 100)
	u.CountPrefix = Theme.label({ Name = "Prefix", Position = UDim2.fromOffset(34, 0), Size = UDim2.new(0, prefixW, 1, 0), Text = "", TextSize = T.Small, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = count })
	u.CountText = Theme.label({ Name = "Left", Position = UDim2.fromOffset(34 + prefixW + 4, 0), Size = UDim2.new(0, textW - prefixW - 8, 1, 0), Text = "", Font = Theme.FontBold, TextSize = T.Small, TextColor3 = C.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = count })
	-- Botón dorado
	u.Buy = button(info, "Buy", "", T.Button + (if Hh.Compact then 0 else 2))
	place(u.Buy, I.Buy)
	u.Buy.TextWrapped = false
	u.Buy.TextTruncate = Enum.TextTruncate.AtEnd
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 240, 190), rgb(255, 170, 40)), Parent = u.Buy })
	Theme.halo(u.Buy, GOLD, 6, 10)
	u.Buy.Activated:Connect(buy)

	-- Recompensa destacada (derecha): cielo de atardecer, el 3D girando y su ficha
	local P = Hh.FeaturedParts
	local featured = create("Frame", { Name = "Featured", BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ClipsDescendants = true, Parent = hero }, {
		create("UICorner", { CornerRadius = UDim.new(0, 12) }),
		create("UIGradient", { Name = "Sky", Rotation = 90, Color = SUNSET }),
	})
	place(featured, Hh.Featured)
	stroke(featured, GOLD, 0.25, 2)
	-- Sol del atardecer (un círculo suave abajo) y el suelo oscuro
	create("Frame", {
		Name = "Sun",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, math.floor(P.Viewport.W / 2), 1, -math.floor(Hh.Frame.H * 0.22)),
		Size = UDim2.fromOffset(math.floor(Hh.Frame.H * 0.5), math.floor(Hh.Frame.H * 0.5)),
		BackgroundColor3 = rgb(255, 214, 140),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Parent = featured,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	create("Frame", {
		Name = "Ground",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0.18, 0),
		BackgroundColor3 = rgb(16, 18, 44),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = featured,
	})
	local stage = create("Frame", { Name = "Stage", BackgroundTransparency = 1, ZIndex = 2, Parent = featured })
	place(stage, P.Viewport)
	-- Ficha (sobre un velo oscuro para que se lea encima del cielo)
	local veil = create("Frame", {
		Name = "Veil",
		Position = UDim2.fromOffset(P.Kicker.X - 8, 0),
		Size = UDim2.new(0, Hh.Featured.W - P.Kicker.X + 8, 1, 0),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = featured,
	}, { create("UIGradient", { Transparency = NumberSequence.new(0.6, 0) }) })
	local F: { [string]: any } = { Stage = stage, Veil = veil }
	F.Kicker = Theme.label({ Name = "FeatKicker", Text = "", Font = Theme.FontBold, TextSize = T.Small, TextColor3 = GOLD, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = featured })
	place(F.Kicker, P.Kicker)
	F.Name = Theme.label({ Name = "RewardName", Text = "", FontFace = Theme.TitleFace, TextScaled = true, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 3, Parent = featured })
	place(F.Name, P.Name)
	create("UITextSizeConstraint", { MaxTextSize = if P.Name.H >= 50 then 24 else 20, MinTextSize = 12, Parent = F.Name })
	F.Rarity = Theme.label({ Name = "Rarity", Text = "", Font = Theme.FontBold, TextSize = T.Small, TextColor3 = C.Ink, TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0, BackgroundColor3 = GOLD, ZIndex = 3, Parent = featured })
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = F.Rarity })
	place(F.Rarity, P.Rarity)
	F.Detail = Theme.label({ Name = "Detail", Text = "", TextSize = T.Small, TextColor3 = C.Text, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 3, Parent = featured })
	place(F.Detail, P.Detail)
	F.See = button(featured, "See", "👁 Ver recompensas", T.Button)
	F.See.ZIndex = 3
	F.See.TextWrapped = false
	place(F.See, P.See)
	F.Action = button(featured, "Action", "", T.Button, true)
	F.Action.ZIndex = 3
	F.Action.TextWrapped = false
	place(F.Action, P.Action)
	F.Action.Visible = false
	F.See.Activated:Connect(function()
		local reward = featuredReward()
		if reward then
			scrollTo(reward.Level or 1)
		end
	end)
	F.Action.Activated:Connect(function()
		local reward = featuredReward()
		if not reward then
			return
		end
		if reward.State == "AVAILABLE" then
			claim(reward)
		elseif reward.State == "PREMIUM_LOCKED" then
			setBenefits(true)
		elseif View.equipSlot(reward) then
			equip(reward)
		elseif reward.Type == "Emote" then
			tryEmote(reward)
		end
	end)
	u.Featured = F
end

local function buildRows(u: Ui, parent: Instance)
	local L = u.Layout
	local T = L.Text
	local R = L.Rows
	local rows = create("Frame", { Name = "Rows", BackgroundTransparency = 1, Parent = parent })
	place(rows, R.Frame)
	-- Carriles (izquierda)
	local lanes = create("Frame", { Name = "Lanes", BackgroundTransparency = 1, Parent = rows })
	place(lanes, R.Lanes)
	local function lane(name: string, r: { [string]: number }, title: string, sub: string, color: Color3, fill: Color3, icon: string): (Frame, TextLabel)
		local box = panel(lanes, name, fill, 0.1)
		place(box, r)
		stroke(box, color, 0.15, 2)
		local iconSize = math.min(math.floor(r.H * 0.36), 40)
		local mark = Theme.label({ Name = "Icon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(iconSize, iconSize), Text = icon, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = box })
		mark.TextColor3 = color
		local titleY = 4 + iconSize + 2
		Theme.label({ Name = "Title", Position = UDim2.fromOffset(4, titleY), Size = UDim2.new(1, -8, 0, T.Body + 4), Text = title, FontFace = Theme.TitleFace, TextSize = T.Body, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, Parent = box })
		local subLabel = Theme.label({ Name = "Sub", Position = UDim2.fromOffset(4, titleY + T.Body + 4), Size = UDim2.new(1, -8, 0, T.Small + 4), Text = sub, TextSize = T.Small, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Center, Parent = box })
		return box, subLabel
	end
	lane("FreeLane", R.Free, "GRATIS", "Pase normal", SILVER, H.NavyLight, "🎟")
	local _, premiumSub = lane("PremiumLane", R.Premium, "PREMIUM", "Pase de temporada", GOLD, View.Colors.PremiumDark, "👑")
	u.PremiumLaneSub = premiumSub
	local levelsLabel = Theme.label({ Name = "LevelsLabel", Text = "NIVEL", Font = Theme.FontBold, TextSize = T.Small, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = lanes })
	place(levelsLabel, R.LineLabel)

	-- Las dos filas y la línea de niveles: un solo lienzo que se desplaza en horizontal
	local scroll = create("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = R.ScrollBar,
		ScrollBarImageColor3 = GOLD,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		Parent = rows,
	})
	place(scroll, R.Scroll)
	u.Scroll = scroll
	local max = (state and state.Season and state.Season.MaxLevel) or 50
	scroll.CanvasSize = UDim2.fromOffset(max * R.Pitch - R.Gap, 0)
	-- Línea de niveles
	local line = create("Frame", { Name = "Line", Position = UDim2.fromOffset(0, R.CardH), Size = UDim2.fromOffset(max * R.Pitch - R.Gap, R.LineH), BackgroundTransparency = 1, Parent = scroll })
	local trackBar = create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, math.floor(R.CardW / 2), 0.5, 0),
		Size = UDim2.new(0, (max - 1) * R.Pitch, 0, 4),
		BackgroundColor3 = H.Track,
		BorderSizePixel = 0,
		Parent = line,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	u.LineFill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = trackBar }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Color = ColorSequence.new(H.Glow, GOLD) }),
	})
	u.Nodes = {}
	u.Cards = { Free = {}, Premium = {} }
	local touch = L.Touch
	for i = 1, max do
		local x = (i - 1) * R.Pitch
		local node = Theme.label({
			Name = "Node" .. View.levelText(i),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x + math.floor(R.CardW / 2), math.floor(R.LineH / 2)),
			Size = UDim2.fromOffset(R.LineH - 8, R.LineH - 8),
			Text = tostring(i),
			Font = Theme.FontBold,
			TextSize = T.Small,
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundTransparency = 0.2,
			BackgroundColor3 = H.Navy,
			ZIndex = 2,
			Parent = line,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = node })
		stroke(node, C.Stroke, 0.6, 1.5)
		u.Nodes[i] = node
		for _, track in { "Free", "Premium" } do
			local y = if track == "Free" then 0 else R.CardH + R.LineH
			local card = RewardCard.new(scroll, L, Vector2.new(x, y), track .. View.levelText(i), track == "Premium")
			-- Tocar: si está lista se reclama; si no, se enseña en grande arriba
			card.Button.Activated:Connect(function()
				local reward = card.Reward
				if reward and reward.State == "AVAILABLE" then
					selected = { Track = reward.Track, Level = reward.Level }
					claim(reward)
				else
					select(reward)
				end
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
			u.Cards[track][i] = card
		end
	end
	if not touch then
		-- La rueda del ratón mueve las filas en horizontal
		table.insert(u.Connections, scroll.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local maxX = math.max(0, scroll.CanvasSize.X.Offset - R.Scroll.W)
				scroll.CanvasPosition = Vector2.new(math.clamp(scroll.CanvasPosition.X - input.Position.Z * R.Pitch, 0, maxX), 0)
			end
		end))
	end
end

local function buildFooter(u: Ui, parent: Instance)
	local L = u.Layout
	local T = L.Text
	local Fo = L.Footer
	local foot = create("Frame", { Name = "Footer", BackgroundTransparency = 1, Parent = parent })
	place(foot, Fo.Frame)
	-- Hexágono «TU NIVEL» (también lleva a tu nivel en las filas)
	local hexHolder = create("TextButton", { Name = "Hex", Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Parent = foot })
	place(hexHolder, Fo.Hex)
	local hx = emblem(hexHolder, "Shape", Fo.Hex.H, "", rgb(10, 24, 60))
	hx.Position = UDim2.fromOffset(math.floor((Fo.Hex.W - math.floor(Fo.Hex.H * 0.866)) / 2), 0)
	u.LevelNumber = Theme.label({
		Name = "Number",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(math.floor(Fo.Hex.H * 0.6), math.floor(Fo.Hex.H * 0.5)),
		Text = "0",
		TextScaled = true,
		FontFace = Theme.TitleFace,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
		Parent = hexHolder,
	})
	hexHolder.Activated:Connect(jumpToMine)
	-- Barra de XP
	local xp = create("Frame", { Name = "Xp", BackgroundTransparency = 1, Parent = foot })
	place(xp, Fo.Xp)
	local half = math.floor(Fo.Xp.H / 2)
	Theme.label({ Name = "Label", Position = UDim2.fromOffset(0, half - T.Small - 8), Size = UDim2.new(0.45, 0, 0, T.Small + 4), Text = "TU NIVEL", Font = Theme.FontBold, TextSize = T.Small, TextColor3 = C.Muted, Parent = xp })
	u.XpText = Theme.label({ Name = "XpText", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, half - T.Small - 8), Size = UDim2.new(0.55, -4, 0, T.Small + 4), Text = "", Font = Theme.FontBold, TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = xp })
	local bar = create("Frame", { Name = "XpBar", Position = UDim2.fromOffset(0, half + 2), Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = H.Track, BorderSizePixel = 0, Parent = xp }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = H.Edge, Transparency = 0.5, Thickness = 1 }),
	})
	u.XpFill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = bar }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Color = ColorSequence.new(rgb(255, 230, 150), rgb(255, 170, 40)) }),
	})
	-- Ir a mi nivel y reclamar todo
	local jump = button(foot, "Jump", "📍 IR A MI NIVEL", T.Button)
	jump.TextWrapped = false
	place(jump, Fo.Jump)
	jump.Activated:Connect(jumpToMine)
	u.ClaimAll = button(foot, "ClaimAll", "RECLAMAR TODO", T.Button, true)
	u.ClaimAll.TextWrapped = false
	place(u.ClaimAll, Fo.ClaimAll)
	u.ClaimAll.Activated:Connect(claimAll)
	-- Caja del premium
	local box = panel(foot, "PremiumBox", H.Navy, 0.2)
	place(box, Fo.Premium)
	stroke(box, GOLD, 0.35, 1.5)
	u.PremiumIcon = Theme.label({ Name = "Icon", Text = "🔒", TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = box })
	place(u.PremiumIcon, Fo.PremiumIcon)
	u.PremiumText = Theme.label({ Name = "Text", Text = "", TextSize = T.Small, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box })
	place(u.PremiumText, Fo.PremiumText)
	local see = button(box, "SeeBenefits", "VER BENEFICIOS", T.Button)
	see.TextWrapped = false
	place(see, Fo.PremiumButton)
	setButton(see, "VER BENEFICIOS", true, "Gold")
	see.Activated:Connect(function()
		setBenefits(not benefitsOpen)
	end)
end

-- «VER BENEFICIOS»: hoja encima con todo lo que trae el premium (y la compra, sin presión)
local function buildBenefits(u: Ui, parent: Instance)
	local L = u.Layout
	local T = L.Text
	local r = L.Benefits
	local sheet = panel(parent, "Benefits", H.Navy, 0.02)
	sheet.ZIndex = 20
	place(sheet, r)
	stroke(sheet, GOLD, 0.1, 2)
	sheet.Visible = false
	local pad = 14
	local btn = L.Button
	local title = Theme.label({ Name = "Title", Position = UDim2.fromOffset(pad, pad), Size = UDim2.new(1, -(2 * pad + btn + 8), 0, 30), Text = "👑 PASE PREMIUM · LO QUE TRAE", FontFace = Theme.TitleFace, TextSize = T.Big, TextColor3 = GOLD, TextTruncate = Enum.TextTruncate.AtEnd, Parent = sheet })
	title.ZIndex = 21
	local close = button(sheet, "BenefitsClose", "✖", T.Button)
	close.ZIndex = 21
	place(close, { X = r.W - pad - btn, Y = pad - 4, W = btn, H = btn })
	close.Activated:Connect(function()
		setBenefits(false)
	end)
	local listY = pad + btn + 6
	local bottomH = btn + 10 + T.Small + 8
	local list = create("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(pad, listY),
		Size = UDim2.fromOffset(r.W - 2 * pad, r.H - listY - bottomH - pad),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = GOLD,
		ZIndex = 21,
		Parent = sheet,
	})
	local note = Theme.label({ Name = "Note", Position = UDim2.fromOffset(pad, r.H - pad - btn - 6 - T.Small - 6), Size = UDim2.new(1, -2 * pad, 0, T.Small + 6), Text = "", TextSize = T.Small, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 21, Parent = sheet })
	local buyButton = button(sheet, "BenefitsBuy", "", T.Button + 1)
	buyButton.ZIndex = 21
	buyButton.TextWrapped = false
	place(buyButton, { X = math.floor((r.W - math.min(360, r.W - 2 * pad)) / 2), Y = r.H - pad - btn, W = math.min(360, r.W - 2 * pad), H = btn })
	buyButton.Activated:Connect(buy)
	u.Benefits = { Frame = sheet, List = list, Note = note, Buy = buyButton }
end

local function build()
	local touch = Theme.isTouch()
	local viewport = workspace.CurrentCamera.ViewportSize
	local L = Layout.compute(viewport, touch, Dialog.baseScale())
	local T = L.Text
	local frame, content, close = Dialog.window(NAME, "🏆 PASE DE TEMPORADA", L.Window)
	frame.BackgroundColor3 = H.Navy
	frame.BackgroundTransparency = 0.04
	local edge = frame:FindFirstChildOfClass("UIStroke")
	if edge then
		edge.Color = H.Glow
		edge.Thickness = 2
		edge.Transparency = 0.05
	end
	Theme.halo(frame, H.Glow, 8, 10)
	local u: Ui = { Layout = L, Window = frame, Connections = {} }
	ui = u
	auto.Shown = true -- (si ya la has abierto, no se vuelve a abrir sola)
	frame.Destroying:Connect(function()
		if ui == u then
			if u.PreviewHandle then
				u.PreviewHandle.destroy()
			end
			for _, connection in u.Connections do
				connection:Disconnect()
			end
			ui = nil
			hideTip()
		end
	end)
	-- Barra de arriba: título, secciones, dinero y ✖
	local title = frame:FindFirstChild("Title") :: TextLabel
	place(title, L.Title)
	title.FontFace = Theme.TitleFace
	title.TextSize = T.Title
	title.TextWrapped = false
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Visible = L.Title.W >= 120
	u.Title = title
	u.Close = close
	close.AnchorPoint = Vector2.new(0, 0)
	place(close, L.Close)
	local tabs = create("Frame", { Name = "Tabs", BackgroundTransparency = 1, Parent = frame })
	place(tabs, L.Tabs)
	u.Tabs = {}
	for i, entry in { { "Rewards", "RECOMPENSAS" }, { "Missions", "MISIONES" }, { "Shop", "FICHAS" } } do
		local tab = button(tabs, entry[1] .. "Tab", entry[2], T.Button)
		tab.TextWrapped = false
		place(tab, { X = (i - 1) * (L.TabWidth + 8), Y = 0, W = L.TabWidth, H = L.Button })
		local dot = Theme.label({ Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 0, BackgroundColor3 = rgb(230, 60, 80), Text = "", Font = Theme.FontBold, TextSize = math.max(T.Small - 1, 13), TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 3, Parent = tab })
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		tab.Activated:Connect(function()
			setSection(entry[1])
		end)
		u.Tabs[entry[1]] = tab
	end
	local moneyChip = panel(frame, "Money", H.Track, 0.2)
	place(moneyChip, L.Money)
	stroke(moneyChip, C.Money, 0.5, 1)
	u.Money = Theme.label({ Name = "Amount", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), Text = "", Font = Theme.FontBold, TextSize = T.Small, TextColor3 = C.Money, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = moneyChip })
	table.insert(u.Connections, player:GetAttributeChangedSignal("Money"):Connect(function()
		if ui == u then
			Theme.setText(u.Money, "💶 " .. money(tonumber(player:GetAttribute("Money")) or 0))
		end
	end))
	place(content, L.Content)

	-- Página de recompensas: cabecera, filas y pie
	local page = create("Frame", { Name = "Page", BackgroundTransparency = 1, Parent = content })
	place(page, L.Page)
	local rewards = create("Frame", { Name = "Rewards", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = page })
	u.RewardsPage = rewards
	buildHero(u, rewards)
	buildRows(u, rewards)
	buildFooter(u, rewards)

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
	buildBenefits(u, content)

	-- Si la pantalla cambia de tamaño (girar el móvil), se vuelve a montar a la medida
	table.insert(u.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.defer(function()
			if ui ~= u or not BattlePassUI.isOpen() then
				return
			end
			local now = Layout.compute(workspace.CurrentCamera.ViewportSize, touch, Dialog.baseScale())
			if now.Window ~= u.Layout.Window then
				local keep = section
				BattlePassUI.close()
				BattlePassUI.open(keep)
			end
		end)
	end))
	render()
	jumpToMine()
	tick(u)
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
	benefitsOpen = false
	selected = nil -- (al abrir, arriba sale la recompensa estrella)
	build()
end

function BattlePassUI.close()
	hideTip()
	benefitsOpen = false
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
-- Apertura sola al entrar (una vez por sesión, después de la pantalla de inicio)
---------------------------------------------------------------------
local function startCardOnScreen(): boolean
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local story = playerGui and playerGui:FindFirstChild("LifeStory")
	if not story then
		return false
	end
	-- (la tarjeta «Al volver» y la de misión nueva: las de Controllers/LifeStory)
	return story:FindFirstChild("Recap") ~= nil or story:FindFirstChild("QuestIntro") ~= nil
end

local function otherWindowOpen(): boolean
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local dialogs = playerGui and playerGui:FindFirstChild("Dialogs")
	if not dialogs then
		return false
	end
	for _, child in dialogs:GetChildren() do
		if child:IsA("GuiObject") and child.Visible and child.Name ~= NAME then
			return true
		end
	end
	return false
end

-- Una comprobación (cada segundo mientras no se ha abierto). now = os.clock() (las pruebas lo dan).
-- Devuelve el motivo de esperar, o "Opened" si la ha abierto.
function BattlePassUI._autoTick(now: number?): string
	local t = now or os.clock()
	auto.StartedAt = auto.StartedAt or t
	local busy = player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
	local startCard = startCardOnScreen()
	local window = otherWindowOpen() or BattlePassUI.isOpen()
	if busy or startCard or window then
		auto.FreeSince = nil
	else
		auto.FreeSince = auto.FreeSince or t
	end
	local block = View.autoOpenBlock({
		Enabled = enabled,
		Visible = View.rowVisible(enabled, state),
		Shown = auto.Shown,
		Stage = player:GetAttribute("LifeStage"),
		InPrologue = player:GetAttribute("InPrologue") == true,
		Tutorial = player:GetAttribute("Tutorial"),
		Busy = busy,
		StartCard = startCard,
		OtherWindow = window,
		Elapsed = t - (auto.StartedAt :: number),
		FreeFor = if auto.FreeSince then t - auto.FreeSince else 0,
	})
	if block then
		return block
	end
	BattlePassUI.open("Rewards")
	auto.Opened = BattlePassUI.isOpen()
	return "Opened"
end

local function startAutoOpen()
	task.spawn(function()
		local began = os.clock()
		while not auto.Shown and os.clock() - began < 3600 do
			task.wait(1)
			local ok, err = pcall(BattlePassUI._autoTick)
			if not ok then
				warn("[BattlePassUI] Apertura al entrar: " .. tostring(err))
				return
			end
		end
	end)
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
	stateClock = os.clock()
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

local watchingTester = false
function BattlePassUI.init()
	config = loadConfig()
	-- Apagado (BattlePassConfig.Enabled = false) -> nada de nada, salvo a los testers (atributo Tester,
	-- modo pruebas: el servidor solo les atiende a ellos). El atributo puede llegar después.
	enabled = config ~= nil and (config.Enabled == true or player:GetAttribute("Tester") == true)
	if config ~= nil and not enabled and not watchingTester then
		watchingTester = true
		player:GetAttributeChangedSignal("Tester"):Connect(function()
			if player:GetAttribute("Tester") == true and not started then
				BattlePassUI.init()
			end
		end)
	end
	if not enabled or started then
		return
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
	-- Al entrar: la pantalla del pase sale sola una vez (cuando toca)
	startAutoOpen()
end

-- Para las pruebas: la medida y la ventana abiertas
function BattlePassUI._debug(): { [string]: any }
	return { Ui = ui, Section = section, Selected = selected, Pending = pending, Auto = auto, Benefits = benefitsOpen }
end

-- Para las pruebas: empezar la sesión de nuevo (la apertura al entrar vuelve a estar pendiente)
function BattlePassUI._resetSession()
	auto.Shown = false
	auto.StartedAt = nil
	auto.FreeSince = nil
	auto.Opened = false
end

return BattlePassUI
