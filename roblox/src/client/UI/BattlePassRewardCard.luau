-- BattlePassRewardCard: la tarjeta de UNA recompensa en la fila de niveles del pase de temporada.
--
--   local card = RewardCard.new(parent, layout, position)   -- se crea una vez por nivel
--   card:set(reward, { Current = bool, Next = bool, Selected = bool, Pending = bool })
--   card.Button.Activated   -> elegirla (la ventana la enseña en grande)
--   card.Claim.Activated    -> RECLAMAR (solo cuando el servidor dice DISPONIBLE)
--
-- Enseña icono, nombre, rareza (con su color), tipo, nivel, pista (GRATIS / PREMIUM) y estado
-- (BLOQUEADA / DISPONIBLE / RECLAMADA / PREMIUM BLOQUEADA). Todo lo decide el servidor: aquí solo se pinta.

local Theme = require(script.Parent.Theme)
local View = require(script.Parent.BattlePassView)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud

local RewardCard = {}
RewardCard.__index = RewardCard

local function place(object: GuiObject, r: { X: number, Y: number, W: number, H: number })
	object.Position = UDim2.fromOffset(r.X, r.Y)
	object.Size = UDim2.fromOffset(r.W, r.H)
end

function RewardCard.new(parent: Instance, layout: { [string]: any }, position: Vector2, name: string?)
	local size = layout.Rewards.Card
	local inner = layout.Card
	local text = layout.Text
	local self = setmetatable({}, RewardCard)
	-- La tarjeta entera es un botón (elegirla); el de RECLAMAR va encima
	local button = create("TextButton", {
		Name = name or "Card",
		Position = UDim2.fromOffset(position.X, position.Y),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIGradient", { Rotation = 90, Color = Theme.PanelSheen }),
	})
	local stroke = create("UIStroke", {
		Name = "Edge",
		Color = C.Stroke,
		Thickness = 1.5,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = button,
	})
	-- Franja de rareza arriba (el color de la rareza, discreto)
	local rarityBar = create("Frame", {
		Name = "RarityBar",
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 0, 3),
		BackgroundColor3 = C.Muted,
		BorderSizePixel = 0,
		Parent = button,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local level = Theme.label({
		Name = "Level",
		Text = "NV. 01",
		Font = Theme.FontBold,
		TextSize = text.Small,
		TextColor3 = C.Text,
		Parent = button,
	})
	place(level, inner.Level)
	local badge = Theme.label({
		Name = "Badge",
		Text = "",
		Font = Theme.FontBold,
		TextSize = text.Small - 1,
		TextColor3 = H.Glow,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = button,
	})
	place(badge, inner.Badge)
	local icon = Theme.label({
		Name = "Icon",
		Text = "🎁",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = button,
	})
	place(icon, inner.Icon)
	local title = Theme.label({
		Name = "RewardName",
		Text = "",
		Font = Theme.FontBold,
		TextSize = text.Body - 1,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Parent = button,
	})
	place(title, inner.Name)
	local meta = Theme.label({
		Name = "Meta",
		Text = "",
		TextSize = text.Small - 1,
		TextColor3 = C.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = button,
	})
	place(meta, inner.Meta)
	-- Estado: botón RECLAMAR (disponible) o una etiqueta (bloqueada, reclamada, premium)
	local claim = create("TextButton", {
		Name = "State",
		BackgroundColor3 = H.NavyLight,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Theme.FontBold,
		TextSize = text.Button,
		TextColor3 = C.Text,
		Text = "",
		Parent = button,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	place(claim, inner.State)
	local claimStroke = create("UIStroke", {
		Color = H.Glow,
		Thickness = 1.5,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = claim,
	})
	Theme.pressable(claim)
	Theme.hover(button, nil)

	self.Button = button
	self.Claim = claim
	self.Stroke = stroke
	self.ClaimStroke = claimStroke
	self.RarityBar = rarityBar
	self.LevelLabel = level
	self.Badge = badge
	self.Icon = icon
	self.Title = title
	self.Meta = meta
	self.Reward = nil
	return self
end

-- Pinta la recompensa (y resalta la actual, la siguiente y la elegida)
function RewardCard:set(reward: { [string]: any }?, flags: { [string]: any }?)
	local f = flags or {}
	self.Reward = reward
	self.Button.Visible = reward ~= nil
	if not reward then
		return
	end
	local rarity = if typeof(reward.RarityColor) == "Color3" then reward.RarityColor else C.Muted
	local info = View.stateInfo(reward.State)
	local premium = reward.Track == "Premium"
	Theme.setText(self.LevelLabel, "NV. " .. View.levelText(reward.Level))
	Theme.setText(self.Icon, tostring(reward.Icon or "🎁"))
	Theme.setText(self.Title, tostring(reward.Name or ""))
	Theme.setText(self.Meta, ("%s · %s"):format(tostring(reward.RarityName or reward.Rarity or ""), tostring(reward.TypeName or reward.Type or "")))
	self.Meta.TextColor3 = rarity
	self.RarityBar.BackgroundColor3 = rarity
	-- Arriba a la derecha: ACTUAL / SIGUIENTE / ★ (hito cada 5) / la pista
	local badge = if f.Current then "ACTUAL" elseif f.Next then "SIGUIENTE" elseif reward.Milestone then "★ HITO" else View.trackName(reward.Track)
	Theme.setText(self.Badge, badge)
	self.Badge.TextColor3 = if f.Current or f.Next then H.Glow elseif premium then View.Colors.Premium else C.Muted
	-- Estado
	local text = if f.Pending then "…" else info.Text
	Theme.setText(self.Claim, text)
	self.Claim:SetAttribute("State", reward.State)
	self.Claim.AutoButtonColor = info.Claim == true
	self.Claim.Active = info.Claim == true and not f.Pending
	if info.Claim then
		self.Claim.BackgroundColor3 = View.Colors.Claim
		self.Claim.BackgroundTransparency = 0
		self.Claim.TextColor3 = C.Text
		self.ClaimStroke.Transparency = 0.1
	else
		self.Claim.BackgroundColor3 = if reward.State == "PREMIUM_LOCKED" then View.Colors.PremiumDark else H.NavyLight
		self.Claim.BackgroundTransparency = 0.35
		self.Claim.TextColor3 = info.Color
		self.ClaimStroke.Transparency = 1
	end
	-- Borde: la elegida brilla; la disponible, cian; la legendaria, dorada; el resto, suave
	local edge = if f.Selected then H.Glow elseif reward.State == "AVAILABLE" then H.SelectLight elseif reward.Rarity == "Legendaria" then View.Colors.Premium else C.Stroke
	self.Stroke.Color = edge
	self.Stroke.Thickness = if f.Selected then 2.5 else 1.5
	self.Stroke.Transparency = if f.Selected or reward.State == "AVAILABLE" then 0 else 0.45
	-- Lo que aún no tienes se ve un poco apagado (sin esconderlo: se ve qué vas a conseguir)
	local dim = reward.State == "LOCKED" or reward.State == "PREMIUM_LOCKED"
	self.Icon.TextTransparency = if dim then 0.3 else 0
	self.Title.TextColor3 = if dim then C.Muted else C.Text
	self.Button.BackgroundTransparency = if f.Current then 0.12 else 0.25
end

return RewardCard
