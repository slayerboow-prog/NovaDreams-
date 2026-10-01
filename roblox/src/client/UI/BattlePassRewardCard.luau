-- BattlePassRewardCard: la tarjeta de UNA recompensa en las filas del pase de temporada (GRATIS arriba
-- y PREMIUM abajo, una por nivel).
--
--   local card = RewardCard.new(parent, layout, position, name)   -- se crea una vez por nivel y pista
--   card:set(reward, { Current = bool, Selected = bool, Pending = bool })
--   card.Button.Activated   -> la ventana decide: si está DISPONIBLE la reclama; si no, la enseña en grande
--
-- Enseña el icono (con el color de su rareza en el fondo y en el filo), la cantidad si la hay (250 €,
-- x2…), un candado si aún no es tuya, un ✔ si ya la reclamaste y «RECLAMAR» brillando si está lista.
-- Todo lo decide el servidor: aquí solo se pinta.

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

function RewardCard.new(parent: Instance, layout: { [string]: any }, position: Vector2, name: string?, premium: boolean?)
	local R = layout.Rows
	local inner = layout.Card
	local text = layout.Text
	local self = setmetatable({}, RewardCard)
	local base = if premium then View.Colors.PremiumDark else H.NavyLight
	-- La tarjeta entera es un botón
	local button = create("TextButton", {
		Name = name or "Card",
		Position = UDim2.fromOffset(position.X, position.Y),
		Size = UDim2.fromOffset(R.CardW, R.CardH),
		BackgroundColor3 = base,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
	})
	-- Fondo: brillo de la rareza abajo (degradado de abajo arriba)
	local gradient = create("UIGradient", {
		Rotation = 270,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
		Parent = button,
	})
	local stroke = create("UIStroke", {
		Name = "Edge",
		Color = C.Stroke,
		Thickness = 1.5,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = button,
	})
	local rarityBar = create("Frame", {
		Name = "RarityBar",
		BackgroundColor3 = C.Muted,
		BorderSizePixel = 0,
		Parent = button,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	place(rarityBar, inner.Rarity)
	local icon = Theme.label({
		Name = "Icon",
		Text = "🎁",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = button,
	})
	place(icon, inner.Icon)
	local status = Theme.label({
		Name = "Status",
		Text = "",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = H.Navy,
		BackgroundTransparency = 0.25,
		ZIndex = 3,
		Parent = button,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = status })
	place(status, inner.Status)
	local amount = Theme.label({
		Name = "Amount",
		Text = "",
		Font = Theme.FontBold,
		TextSize = text.Small,
		TextColor3 = C.Text,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 2,
		Parent = button,
	})
	place(amount, inner.Amount)
	-- «RECLAMAR» (solo cuando está lista): una franja que brilla
	local claim = Theme.label({
		Name = "Claim",
		Text = "RECLAMAR",
		Font = Theme.FontBold,
		TextSize = text.Small,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = View.Colors.Claim,
		BackgroundTransparency = 0,
		Visible = false,
		ZIndex = 3,
		Parent = button,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = claim })
	create("UIStroke", { Color = H.Glow, Thickness = 1.5, Transparency = 0.05, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = claim })
	place(claim, inner.Claim)
	Theme.pressable(button)
	Theme.hover(button, nil)

	self.Button = button
	self.Claim = claim -- (etiqueta: la tarjeta entera es la que se pulsa)
	self.Stroke = stroke
	self.Gradient = gradient
	self.RarityBar = rarityBar
	self.Icon = icon
	self.Status = status
	self.Amount = amount
	self.Premium = premium == true
	self.Reward = nil
	return self
end

-- Pinta la recompensa (y resalta la del nivel actual y la elegida)
function RewardCard:set(reward: { [string]: any }?, flags: { [string]: any }?)
	local f = flags or {}
	self.Reward = reward
	self.Button.Visible = reward ~= nil
	if not reward then
		return
	end
	local rarity = if typeof(reward.RarityColor) == "Color3" then reward.RarityColor else C.Muted
	local state = reward.State
	local available = state == "AVAILABLE"
	local claimed = state == "CLAIMED"
	local locked = state == "LOCKED" or state == "PREMIUM_LOCKED"
	self.Button:SetAttribute("State", state)
	self.Button:SetAttribute("RewardId", reward.Id)
	Theme.setText(self.Icon, tostring(reward.Icon or "🎁"))
	self.RarityBar.BackgroundColor3 = rarity
	-- Fondo: el color de la rareza sube desde abajo (más fuerte en las raras y mejores)
	local base = if self.Premium then View.Colors.PremiumDark else H.NavyLight
	local strength = if reward.Rarity == "Legendaria" then 0.55 elseif reward.Rarity == "Epica" then 0.45 elseif reward.Rarity == "Rara" then 0.35 else 0.18
	self.Button.BackgroundColor3 = Color3.new(1, 1, 1) -- (el color lo pone el degradado)
	self.Gradient.Color = ColorSequence.new(base:Lerp(rarity, strength), base)
	-- Esquina: candado (aún no) o ✔ (reclamada)
	local corner = if claimed then "✔" elseif locked then "🔒" else ""
	Theme.setText(self.Status, corner)
	self.Status.Visible = corner ~= ""
	self.Status.TextColor3 = if claimed then View.Colors.Claimed else C.Text
	-- Cantidad o RECLAMAR
	local amount = View.amountText(reward)
	self.Claim.Visible = available
	Theme.setText(self.Claim, if f.Pending then "…" else "RECLAMAR")
	Theme.setText(self.Amount, amount)
	self.Amount.Visible = not available and amount ~= ""
	-- Borde: la elegida y la lista brillan; la legendaria, dorada; el resto, suave
	local edge = if f.Selected then H.Glow elseif available then H.SelectLight elseif reward.Rarity == "Legendaria" then View.Colors.Premium elseif self.Premium then View.Colors.Premium else C.Stroke
	self.Stroke.Color = edge
	self.Stroke.Thickness = if f.Selected or available then 2.5 else 1.5
	self.Stroke.Transparency = if f.Selected or available then 0 elseif self.Premium then 0.35 else 0.55
	-- Lo que aún no tienes se ve apagado (sin esconderlo: se ve qué vas a conseguir)
	self.Icon.TextTransparency = if locked then 0.35 elseif claimed then 0.15 else 0
	self.Button.BackgroundTransparency = if f.Current then 0.02 elseif locked then 0.3 else 0.15
end

return RewardCard
