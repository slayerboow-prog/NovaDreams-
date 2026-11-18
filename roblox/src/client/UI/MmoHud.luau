-- MmoHud: el HUD del MAPA DEFINITIVO del dueño (17-11-2026, docs/mapa/mapa-definitivo.png):
--
--   [Roblox ☰ 💬] (foto)⁷⁵ [❤ 4.850 / 4.850 ████████]          [💰 1.250.460 +] [💎 12.530 +] [⚙]
--                        [⚡ 1.250 / 1.250 ████████]
--   [🎒]
--   [📊]   (botones de la izquierda: mochila, personaje, amigos)
--   [👥]
--
--   * La foto con su nivel en una insignia dorada; la VIDA (barra roja, la del personaje) y la ENERGÍA (barra azul:
--     el espíritu de las habilidades, atributos Espiritu / EspirituMax) con su número dentro.
--   * Arriba a la derecha (a la izquierda del minimapa): el dinero (💰, atributo Money) y las gemas (💎, atributo
--     Tickets), cada uno con su «+», y el engranaje de ajustes (el menú del HUD).
--   * Abajo en el centro, los botones de POCIONES: 🧪 vida (HP) y 💧 espíritu (MP), con cuántas llevas.
--   * Si el hambre, el cansancio o el ánimo están bajos, un aviso pequeño debajo de las barras (las necesidades
--     siguen existiendo aunque el HUD de antes no se vea).
-- Sustituye al panel de estado de antes (UI/Hud: buildStatus), que se esconde.

local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local create = Theme.create
local rgb = Color3.fromRGB

local MmoHud = {}

local player = Players.LocalPlayer

-- 4850 → «4,850» como en el dibujo del dueño (con coma de miles)
function MmoHud.number(n: number): string
	local s = tostring(math.floor(math.abs(n) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if n < 0 then "-" else "") .. out
end

local function bar(parent: Instance, name: string, y: number, icon: string, iconColor: Color3, from: Color3, to: Color3, height: number): (Frame, TextLabel)
	local track = create("Frame", {
		Name = name,
		Position = UDim2.fromOffset(110, y),
		Size = UDim2.fromOffset(300, height),
		BackgroundColor3 = rgb(18, 22, 34),
		BackgroundTransparency = 0.1,
		Parent = parent,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(10, 12, 20), Thickness = 2 }),
	})
	local fill = create("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(from, to) }),
	})
	local text = create("TextLabel", { Name = "Valor", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Font = Theme.FontBold, TextSize = math.floor(height * 0.66), TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.4, ZIndex = 3, Parent = track })
	create("TextLabel", { Name = "Icono", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, -2, 0.5, 0), Size = UDim2.fromOffset(height + 8, height + 8), BackgroundTransparency = 1, Text = icon, TextScaled = true, Font = Theme.FontBold, TextColor3 = iconColor, ZIndex = 4, Parent = track })
	return fill, text
end

local function pill(parent: Instance, name: string, order: number, icon: string, iconColor: Color3, onPlus: () -> ()): TextLabel
	local f = create("Frame", { Name = name, Size = UDim2.fromOffset(152, 46), BackgroundColor3 = rgb(16, 22, 40), BackgroundTransparency = 0.12, LayoutOrder = order, Parent = parent }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(40, 54, 90), Thickness = 2 }),
		create("TextLabel", { Name = "Icono", Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Text = icon, TextScaled = true, Font = Theme.FontBold, TextColor3 = iconColor }),
	})
	local value = create("TextLabel", { Name = "Valor", Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -96, 1, 0), BackgroundTransparency = 1, Text = "0", Font = Theme.FontBold, TextSize = 20, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = f }, {
		create("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 10 }),
	})
	value.TextScaled = true
	local plus = create("TextButton", { Name = "Mas", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = rgb(40, 120, 255), Text = "+", Font = Theme.FontBold, TextSize = 30, TextColor3 = rgb(255, 255, 255), Parent = f }, {
		create("UICorner", { CornerRadius = UDim.new(0, 9) }),
		create("UIStroke", { Color = rgb(150, 200, 255), Thickness = 1.5 }),
	})
	plus.Activated:Connect(onPlus)
	return value
end

local function sideButton(parent: Instance, name: string, order: number, icon: string, onClick: () -> ())
	local b = create("TextButton", { Name = name, Size = UDim2.fromOffset(84, 84), BackgroundColor3 = rgb(44, 62, 104), BackgroundTransparency = 0.05, Text = icon, TextScaled = true, Font = Theme.FontBold, TextColor3 = rgb(255, 255, 255), LayoutOrder = order, Parent = parent }, {
		create("UICorner", { CornerRadius = UDim.new(0, 16) }),
		create("UIStroke", { Color = rgb(130, 170, 240), Thickness = 2.5 }),
		create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
	b.Activated:Connect(onClick)
end

-- actions: lo que abren los botones ({ Bag, Stats, Menu }: los pone UI/Hud)
function MmoHud.build(parent: Instance, actions: { [string]: () -> () }): Frame
	local root = create("Frame", { Name = "MmoHud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = parent })

	-- tu retrato y tus barras (arriba a la izquierda, después de los botones de Roblox)
	local me = create("Frame", { Name = "Jugador", Position = UDim2.fromOffset(230, 8), Size = UDim2.fromOffset(420, 110), BackgroundTransparency = 1, Parent = root })
	local ring = create("Frame", { Name = "Retrato", Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(96, 96), BackgroundColor3 = rgb(30, 40, 66), ZIndex = 3, Parent = me }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(20, 24, 36), Thickness = 4 }),
	})
	local photo = create("ImageLabel", { Name = "Foto", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, ZIndex = 4, Parent = ring }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then
			photo.Image = image
		end
	end)
	local badge = create("TextLabel", { Name = "Nivel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 1, -8), Size = UDim2.fromOffset(38, 38), BackgroundColor3 = rgb(255, 196, 40), Text = "1", Font = Theme.FontBold, TextScaled = true, TextColor3 = rgb(40, 26, 6), ZIndex = 6, Parent = ring }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(120, 70, 10), Thickness = 2 }),
		create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
	})
	local hpFill, hpText = bar(me, "Vida", 14, "❤", rgb(255, 60, 70), rgb(255, 80, 80), rgb(190, 20, 30), 34)
	local enFill, enText = bar(me, "Energia", 56, "⚡", rgb(80, 180, 255), rgb(80, 170, 255), rgb(20, 80, 200), 30)
	local warn = create("TextLabel", { Name = "Avisos", Position = UDim2.fromOffset(112, 90), Size = UDim2.fromOffset(300, 20), BackgroundTransparency = 1, Text = "", Font = Theme.FontBold, TextSize = 15, TextColor3 = rgb(255, 210, 120), TextStrokeTransparency = 0.4, TextXAlignment = Enum.TextXAlignment.Left, Parent = me })

	-- el dinero y las gemas (arriba a la derecha, a la izquierda del minimapa) y los ajustes
	local top = create("Frame", { Name = "Monedas", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -238, 0, 74), Size = UDim2.fromOffset(380, 50), BackgroundTransparency = 1, Parent = root }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local menu = actions.Menu or function() end
	local coins = pill(top, "Dinero", 1, "💰", rgb(255, 200, 60), menu)
	local gems = pill(top, "Gemas", 2, "💎", rgb(200, 110, 255), menu)
	local gear = create("TextButton", { Name = "Ajustes", Size = UDim2.fromOffset(46, 46), BackgroundColor3 = rgb(16, 22, 40), BackgroundTransparency = 0.12, Text = "⚙", TextScaled = true, Font = Theme.FontBold, TextColor3 = rgb(255, 255, 255), LayoutOrder = 3, Parent = top }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(40, 54, 90), Thickness = 2 }),
	})
	gear.Activated:Connect(menu)

	-- los botones de la izquierda
	local side = create("Frame", { Name = "Lateral", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.42, 0), Size = UDim2.fromOffset(84, 276), BackgroundTransparency = 1, Parent = root }, {
		create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	sideButton(side, "Mochila", 1, "🎒", actions.Bag or function() end)
	sideButton(side, "Personaje", 2, "📊", actions.Stats or actions.Menu or function() end)
	sideButton(side, "Amigos", 3, "👥", function()
		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	end)

	-- los botones de POCIONES (abajo en el centro, encima de la barra rápida): vida (HP) y espíritu (MP), con cuántas
	-- llevas; al tocar se bebe la mejor que tengas (Services/CraftingService.quickPotion)
	-- (en el ordenador, a la izquierda de la barra de habilidades: Controllers/HunterSkillsUI)
	local potions = create("Frame", { Name = "Pociones", AnchorPoint = Vector2.new(0.5, 1), Position = if Theme.isTouch() then UDim2.new(0.5, 0, 1, -112) else UDim2.new(0.5, -290, 1, -112), Size = UDim2.fromOffset(196, 84), BackgroundTransparency = 1, Parent = root }, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local counts: { [string]: TextLabel } = {}
	for i, def in { { "HP", "🧪", rgb(255, 70, 80), rgb(120, 20, 30) }, { "MP", "💧", rgb(80, 170, 255), rgb(20, 50, 130) } } do
		local b = create("TextButton", { Name = "Pocion" .. def[1], Size = UDim2.fromOffset(84, 84), BackgroundColor3 = def[4], AutoButtonColor = true, Text = "", LayoutOrder = i, Parent = potions }, {
			create("UICorner", { CornerRadius = UDim.new(0, 16) }),
			create("UIStroke", { Color = def[3], Thickness = 3 }),
			create("UIGradient", { Rotation = 90, Color = ColorSequence.new(def[3]:Lerp(Color3.new(1, 1, 1), 0.15), def[4]) }),
			create("TextLabel", { Name = "Icono", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.62, 0.62), BackgroundTransparency = 1, Text = def[2], TextScaled = true, Font = Theme.FontBold }),
			create("TextLabel", { Name = "Tipo", Position = UDim2.fromOffset(6, 2), Size = UDim2.fromOffset(40, 22), BackgroundTransparency = 1, Text = def[1], Font = Theme.FontBold, TextSize = 18, TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Left }),
		})
		counts[def[1]] = create("TextLabel", { Name = "Cuantas", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -2), Size = UDim2.fromOffset(60, 24), BackgroundTransparency = 1, Text = "0", Font = Theme.FontBold, TextSize = 22, TextColor3 = rgb(255, 255, 255), TextStrokeTransparency = 0.2, TextXAlignment = Enum.TextXAlignment.Right, Parent = b })
		local kind = def[1]
		b.Activated:Connect(function()
			local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
			local r = remotes and remotes:FindFirstChild("Crafting")
			if r then
				(r :: RemoteEvent):FireServer("QuickPotion", kind)
			end
			TweenService:Create(b, TweenInfo.new(0.08), { Size = UDim2.fromOffset(76, 76) }):Play()
			task.delay(0.09, function()
				TweenService:Create(b, TweenInfo.new(0.12), { Size = UDim2.fromOffset(84, 84) }):Play()
			end)
		end)
	end
	local function potionCounts(): (number, number)
		local raw = player:GetAttribute("Inventory")
		local hp, mp = 0, 0
		if type(raw) == "string" then
			local ok, slots = pcall(function()
				return game:GetService("HttpService"):JSONDecode(raw)
			end)
			if ok and type(slots) == "table" then
				for _, e in slots do
					if type(e) == "table" then
						if e.i == "PocionCuracion" or e.i == "PocionRegeneracion" then
							hp += tonumber(e.n) or 0
						elseif e.i == "PocionEspiritu" then
							mp += tonumber(e.n) or 0
						end
					end
				end
			end
		end
		return hp, mp
	end
	local function paintPotions()
		local hp, mp = potionCounts()
		counts.HP.Text = tostring(hp)
		counts.MP.Text = tostring(mp)
	end
	player:GetAttributeChangedSignal("Inventory"):Connect(paintPotions)
	paintPotions()

	-- en vivo
	local lastHp, lastEn = -1, -1
	local function paint()
		local c = player.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		local hp, hpMax = if hum then hum.Health else 0, if hum then hum.MaxHealth else 100
		local en = tonumber(player:GetAttribute("Espiritu")) or 0
		local enMax = math.max(1, tonumber(player:GetAttribute("EspirituMax")) or 100)
		hpText.Text = ("%s / %s"):format(MmoHud.number(hp), MmoHud.number(hpMax))
		enText.Text = ("%s / %s"):format(MmoHud.number(en), MmoHud.number(enMax))
		local hr = math.clamp(hp / math.max(hpMax, 1), 0, 1)
		local er = math.clamp(en / enMax, 0, 1)
		if math.abs(hr - lastHp) > 0.002 then
			lastHp = hr
			TweenService:Create(hpFill, TweenInfo.new(0.25), { Size = UDim2.fromScale(hr, 1) }):Play()
		end
		if math.abs(er - lastEn) > 0.002 then
			lastEn = er
			TweenService:Create(enFill, TweenInfo.new(0.25), { Size = UDim2.fromScale(er, 1) }):Play()
		end
		badge.Text = tostring(player:GetAttribute("Level") or 1)
		coins.Text = MmoHud.number(tonumber(player:GetAttribute("Money")) or 0)
		gems.Text = MmoHud.number(tonumber(player:GetAttribute("Tickets")) or 0)
		local low = {}
		if (tonumber(player:GetAttribute("Hunger")) or 100) < 25 then
			table.insert(low, "🍗 Hambre")
		end
		if (tonumber(player:GetAttribute("Energy")) or 100) < 20 then
			table.insert(low, "💤 Cansancio")
		end
		if (tonumber(player:GetAttribute("Fun")) or 100) < 20 then
			table.insert(low, "😞 Ánimo")
		end
		warn.Text = table.concat(low, "   ")
	end
	task.spawn(function()
		while root.Parent do
			pcall(paint)
			task.wait(0.2)
		end
	end)
	return root
end

return MmoHud
