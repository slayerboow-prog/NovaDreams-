-- PlayerCard: la FICHA del jugador de las pantallas grandes (arriba a la izquierda del mapa galáctico, como
-- el dibujo del dueño docs/espacio-aaa/referencia-mapa-galactico.png): cara del avatar en un aro, «Nv. 12»,
-- el nombre, el dinero, tres barras y tres contadores. Es una pieza que se puede usar en cualquier pantalla
-- (no depende del HUD de la nave: Controllers/ShipHudClient tiene la suya).
--
--   local card = PlayerCard.new(parent, { Compact = true })   -- un Frame que llena a su padre
--   card.set({ Name, Level, Money (texto), UserId, Bars = { { K = 0..1, Color } x3 }, Counters = { { Icon, Text, Color } x3 } })
-- Se pinta solo cuando cambia algo (set compara): nada por fotograma.

local Theme = require(script.Parent.Theme)

local create = Theme.create
local rgb = Color3.fromRGB

local PlayerCard = {}

PlayerCard.Edge = rgb(90, 200, 255)

export type Info = {
	Name: string?,
	Level: number?,
	Money: string?,
	UserId: number?,
	Bars: { { K: number, Color: Color3 } }?,
	Counters: { { Icon: string, Text: string, Color: Color3? } }?,
}

function PlayerCard.headshot(userId: number?): string
	if not userId or userId <= 0 then
		return ""
	end
	return ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
end

function PlayerCard.new(parent: GuiObject, opts: { [string]: any }?)
	local o = opts or {}
	local compact = o.Compact == true
	local z = (o.ZIndex or 30) :: number
	local root = create("Frame", {
		Name = "Ficha",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rgb(8, 16, 40),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = z,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIStroke", { Color = PlayerCard.Edge, Thickness = 1.5, Transparency = 0.35 }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(40, 70, 130), rgb(10, 16, 40)) }),
	})
	-- Cara del avatar en un aro
	local face = if compact then 64 else 92
	local ring = create("Frame", {
		Name = "Aro",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(face, face),
		BackgroundColor3 = rgb(20, 40, 80),
		ZIndex = z + 1,
		Parent = root,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = PlayerCard.Edge, Thickness = 2.5 }),
	})
	local avatar = create("ImageLabel", {
		Name = "Avatar",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ZIndex = z + 2,
		Parent = ring,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local x = face + 18
	local textSize = if compact then 17 else 20
	local level = Theme.label({ Name = "Nivel", Position = UDim2.fromOffset(x, 4), Size = UDim2.fromOffset(if compact then 62 else 76, 24), Text = "Nv. 1", Font = Theme.FontBold, TextSize = textSize, ZIndex = z + 1, Parent = root })
	local name = Theme.label({ Name = "Nombre", Position = UDim2.fromOffset(x + (if compact then 64 else 80), 4), Size = UDim2.new(1, -(x + (if compact then 70 else 86)), 0, 24), Text = "", Font = Theme.FontBold, TextSize = textSize, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = z + 1, Parent = root })
	local money = Theme.label({ Name = "Dinero", Position = UDim2.fromOffset(x, if compact then 26 else 30), Size = UDim2.new(1, -x - 8, 0, 22), Text = "", Font = Theme.FontBold, TextSize = if compact then 16 else 19, TextColor3 = Theme.Colors.Money, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = z + 1, Parent = root })
	-- Tres barras (vida, energía, experiencia)
	local bars = {}
	local barY = if compact then 50 else 56
	local barH = if compact then 6 else 8
	for i = 1, 3 do
		local track = create("Frame", {
			Name = "Barra" .. i,
			Position = UDim2.fromOffset(x, barY + (i - 1) * (barH + 4)),
			Size = UDim2.new(if compact then 1 else 0.6, if compact then -x - 10 else -x, 0, barH),
			BackgroundColor3 = rgb(10, 14, 28),
			BorderSizePixel = 0,
			ZIndex = z + 1,
			Parent = root,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local fill = create("Frame", { Name = "Lleno", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z + 2, Parent = track }, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
		bars[i] = fill
	end
	-- Tres contadores (a la derecha en la ancha; en la compacta no caben: van en la línea del dinero)
	local counters = {}
	if not compact then
		for i = 1, 3 do
			local chip = create("Frame", {
				Name = "Contador" .. i,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 30 + (i - 1) * 27),
				Size = UDim2.new(0.4, -14, 0, 24),
				BackgroundColor3 = rgb(12, 24, 54),
				BackgroundTransparency = 0.2,
				ZIndex = z + 1,
				Parent = root,
			}, {
				create("UICorner", { CornerRadius = UDim.new(0, 8) }),
				create("UIStroke", { Color = PlayerCard.Edge, Transparency = 0.6 }),
			})
			counters[i] = Theme.label({ Name = "Texto", Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -12, 1, 0), Text = "", TextSize = 16, Font = Theme.FontBold, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = z + 2, Parent = chip })
		end
	end
	local last = ""
	local card = { Root = root, Avatar = avatar, Level = level, Name = name, Money = money, Bars = bars, Counters = counters }
	function card.set(info: Info)
		local parts = { tostring(info.Name), tostring(info.Level), tostring(info.Money), tostring(info.UserId) }
		for _, b in info.Bars or {} do
			table.insert(parts, ("%.3f"):format(b.K))
		end
		for _, c in info.Counters or {} do
			table.insert(parts, c.Icon .. c.Text)
		end
		local key = table.concat(parts, "|")
		if key == last then
			return
		end
		last = key
		level.Text = ("Nv. %d"):format(math.floor(info.Level or 1))
		name.Text = info.Name or ""
		local image = PlayerCard.headshot(info.UserId)
		if avatar.Image ~= image then
			avatar.Image = image
		end
		local moneyText = info.Money or ""
		if compact then
			-- (los contadores, detrás del dinero)
			local extra = {}
			for _, c in info.Counters or {} do
				table.insert(extra, c.Icon .. " " .. c.Text)
			end
			if #extra > 0 then
				moneyText ..= "   " .. table.concat(extra, "  ")
			end
		end
		money.Text = moneyText
		for i, fill in bars do
			local b = info.Bars and info.Bars[i]
			fill.Size = UDim2.fromScale(math.clamp(if b then b.K else 0, 0, 1), 1)
			fill.BackgroundColor3 = if b then b.Color else rgb(80, 80, 80)
		end
		for i, label in counters do
			local c = info.Counters and info.Counters[i]
			label.Text = if c then c.Icon .. "  " .. c.Text else ""
			label.TextColor3 = if c and c.Color then c.Color else Theme.Colors.Text
		end
	end
	return card
end

return PlayerCard
