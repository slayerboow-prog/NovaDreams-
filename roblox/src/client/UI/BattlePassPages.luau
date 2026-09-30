-- BattlePassPages: las secciones MISIONES y FICHAS de la ventana del pase de temporada.
--
--   Pages.missions(list, layout, state, actions)  -> pinta las misiones en un ScrollingFrame vertical
--   Pages.shop(list, layout, state, actions)      -> pinta la tienda de fichas (solo cosméticos)
--
-- actions = { track(id, on), reroll(id), choose(storyId, optionId), buyToken(id), rarityColor(rareza),
--             pending: { [key]: true } }
-- Se vuelven a pintar solo cuando llega un estado nuevo del servidor (nunca por fotograma). Todo va
-- colocado a mano (sin UIListLayout) para que las pruebas midan dónde queda cada cosa.

local Theme = require(script.Parent.Theme)
local View = require(script.Parent.BattlePassView)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud

local Pages = {}

local function clear(list: Instance)
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function smallButton(parent: Instance, name: string, text: string, rect: { number }, size: number, primary: boolean?): TextButton
	local button = Theme.button({
		Name = name,
		Position = UDim2.fromOffset(rect[1], rect[2]),
		Size = UDim2.fromOffset(rect[3], rect[4]),
		Text = text,
		TextSize = size,
		BackgroundColor3 = if primary then H.Select else H.NavyLight,
		Parent = parent,
	})
	Theme.pressable(button)
	return button
end

local function bar(parent: Instance, x: number, y: number, w: number, h: number, fraction: number, color: Color3?)
	local track = create("Frame", {
		Name = "Bar",
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = H.Track,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = parent,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1),
		BackgroundColor3 = color or H.Glow,
		BorderSizePixel = 0,
		Parent = track,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 235, 255), Color3.fromRGB(60, 150, 255)) }) })
	return track
end

local function hoursText(seconds: number): string
	if seconds >= 86400 then
		local d = math.ceil(seconds / 86400)
		return if d == 1 then "1 día" else ("%d días"):format(d)
	end
	return ("%d h"):format(math.max(1, math.ceil(seconds / 3600)))
end

---------------------------------------------------------------------
-- MISIONES
---------------------------------------------------------------------
function Pages.missions(list: ScrollingFrame, layout: { [string]: any }, state: { [string]: any }?, actions: { [string]: any })
	clear(list)
	local M = layout.Missions
	local T = layout.Text
	local btnH = layout.Button
	local width = layout.Page.W - M.ScrollBar - 6
	local rightW = M.ButtonW * 2 + 24
	local textW = width - 56 - rightW
	local y = 0
	local missions = state and state.Missions
	local now = (state and state.Season and state.Season.Now) or 0
	local canReroll = type(missions) == "table" and missions.CanReroll == true
	local rows = 0

	local function section(text: string)
		Theme.label({
			Name = "Section",
			Position = UDim2.fromOffset(4, y),
			Size = UDim2.fromOffset(width - 8, M.Section),
			Text = text,
			FontFace = Theme.ItalicFace,
			TextSize = T.Body,
			TextColor3 = H.Glow,
			Parent = list,
		})
		y += M.Section + 4
	end

	local function row(name: string, height: number): Frame
		rows += 1
		local frame = create("Frame", {
			Name = name,
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.fromOffset(width, height),
			BackgroundColor3 = H.Navy,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Parent = list,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }), create("UIGradient", { Rotation = 90, Color = Theme.PanelSheen }) })
		create("UIStroke", { Color = C.Stroke, Transparency = 0.6, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
		y += height + M.Gap
		return frame
	end

	local function missionRow(mission: { [string]: any }, group: string)
		local frame = row("Mission_" .. tostring(mission.Id), M.Row)
		frame:SetAttribute("MissionId", mission.Id)
		Theme.label({ Name = "Icon", Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(40, 40), Text = tostring(mission.Icon or "🎯"), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
		Theme.label({ Name = "Title", Position = UDim2.fromOffset(56, 6), Size = UDim2.fromOffset(textW, 22), Text = tostring(mission.Title or ""), Font = Theme.FontBold, TextSize = T.Body, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = if mission.Done then C.Muted else C.Text, Parent = frame })
		Theme.label({ Name = "Description", Position = UDim2.fromOffset(56, 29), Size = UDim2.fromOffset(textW, 18), Text = tostring(mission.Description or ""), TextSize = T.Small, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
		local barW = math.max(40, textW - 96)
		bar(frame, 56, M.Row - 18, barW, 8, View.missionFraction(mission), if mission.Done then View.Colors.Claimed else nil)
		Theme.label({ Name = "Progress", Position = UDim2.fromOffset(56 + barW + 8, M.Row - 22), Size = UDim2.fromOffset(88, 18), Text = View.missionProgress(mission), TextSize = T.Small, TextColor3 = if mission.Done then View.Colors.Claimed else C.Text, Parent = frame })
		local right = width - 8 - M.ButtonW
		Theme.label({ Name = "Xp", Position = UDim2.fromOffset(width - rightW, 6), Size = UDim2.fromOffset(rightW - 8, 20), Text = View.missionReward(mission), Font = Theme.FontBold, TextSize = T.Small, TextColor3 = H.Gold, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame })
		local by = M.Row - btnH - 6
		if not mission.Done and mission.Place then
			local follow = smallButton(frame, "Track", if mission.Tracked then "✔ SIGUIENDO" else "📍 SEGUIR", { right, by, M.ButtonW, btnH }, T.Button, mission.Tracked)
			follow.Activated:Connect(function()
				actions.track(mission.Id, not mission.Tracked)
			end)
		end
		if group == "Daily" and canReroll and not mission.Done then
			local reroll = smallButton(frame, "Reroll", "🔄 CAMBIAR", { right - 8 - M.ButtonW, by, M.ButtonW, btnH }, T.Button)
			reroll.Activated:Connect(function()
				actions.reroll(mission.Id)
			end)
		end
	end

	if type(missions) ~= "table" then
		Theme.label({ Name = "Empty", Position = UDim2.fromOffset(4, 0), Size = UDim2.fromOffset(width - 8, 40), Text = "Cargando las misiones…", TextSize = T.Body, TextColor3 = C.Muted, Parent = list })
		list.CanvasSize = UDim2.fromOffset(0, 40)
		return
	end

	-- Historia de temporada (arriba: es lo más especial)
	for _, story in missions.Story or {} do
		section(("HISTORIA · %s %s"):format(tostring(story.Icon or "🗼"), string.upper(tostring(story.Title or ""))))
		local current = story.Current
		local choices = if current and type(current.Choices) == "table" then current.Choices else {}
		local height = M.Row + (if #choices > 0 then btnH + 8 else 0)
		local frame = row("Story_" .. tostring(story.Id), height)
		frame:SetAttribute("StoryId", story.Id)
		Theme.label({ Name = "Icon", Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(40, 40), Text = tostring(story.Icon or "🗼"), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
		local title = if story.Done then ("✔ Completada%s"):format(if story.Reward then " · " .. tostring(story.Reward.Name) else "")
			elseif current then ("Fase %d/%d · %s"):format(story.Phase or 1, story.Phases or 1, tostring(current.Title or ""))
			else tostring(story.Intro or "")
		Theme.label({ Name = "Title", Position = UDim2.fromOffset(56, 6), Size = UDim2.fromOffset(textW, 22), Text = title, Font = Theme.FontBold, TextSize = T.Body, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
		Theme.label({ Name = "Description", Position = UDim2.fromOffset(56, 29), Size = UDim2.fromOffset(textW, 18), Text = tostring(if current then current.Text else story.Intro or ""), TextSize = T.Small, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
		if current then
			local fake = { Progress = current.Progress, Goal = current.Goal, Done = false }
			local barW = math.max(40, textW - 96)
			bar(frame, 56, M.Row - 18, barW, 8, View.missionFraction(fake))
			Theme.label({ Name = "Progress", Position = UDim2.fromOffset(56 + barW + 8, M.Row - 22), Size = UDim2.fromOffset(88, 18), Text = View.missionProgress(fake), TextSize = T.Small, Parent = frame })
			Theme.label({ Name = "Xp", Position = UDim2.fromOffset(width - rightW, 6), Size = UDim2.fromOffset(rightW - 8, 20), Text = View.missionReward({ Xp = current.Xp }), Font = Theme.FontBold, TextSize = T.Small, TextColor3 = H.Gold, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame })
			if current.Place then
				local follow = smallButton(frame, "Track", if story.Tracked then "✔ SIGUIENDO" else "📍 SEGUIR", { width - 8 - M.ButtonW, M.Row - btnH - 6, M.ButtonW, btnH }, T.Button, story.Tracked)
				follow.Activated:Connect(function()
					actions.track(story.Id, not story.Tracked)
				end)
			end
			-- Decisión de la historia: un botón por opción
			local n = #choices
			if n > 0 then
				local cw = math.floor((width - 56 - 8 - (n - 1) * 8) / n)
				for i, option in choices do
					local choice = smallButton(frame, "Choice" .. i, tostring(option.Text or option.Id), { 56 + (i - 1) * (cw + 8), M.Row + 2, cw, btnH }, T.Button, true)
					choice.TextWrapped = true
					choice.Activated:Connect(function()
						actions.choose(story.Id, option.Id)
					end)
				end
			end
		end
	end

	local daily = missions.Daily
	if daily and #(daily.List or {}) > 0 then
		section(("DIARIAS · se renuevan en %s%s"):format(hoursText((daily.ResetsAt or now) - now), if canReroll then " · puedes cambiar una" else ""))
		for _, mission in daily.List do
			missionRow(mission, "Daily")
		end
	end
	for _, mission in (missions.Event and missions.Event.List) or {} do
		section(("EVENTO · %s"):format(string.upper(tostring(mission.EventName or ""))))
		missionRow(mission, "Event")
	end
	local weekly = missions.Weekly
	if weekly and #(weekly.List or {}) > 0 then
		section(("SEMANALES · se renuevan en %s"):format(hoursText((weekly.ResetsAt or now) - now)))
		for _, mission in weekly.List do
			missionRow(mission, "Weekly")
		end
	end
	local season = missions.Season
	if season and #(season.List or {}) > 0 then
		section("DE TEMPORADA")
		for _, mission in season.List do
			missionRow(mission, "Season")
		end
	end
	if rows == 0 then
		Theme.label({ Name = "Empty", Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(width - 8, 40), Text = "No hay misiones ahora mismo.", TextSize = T.Body, TextColor3 = C.Muted, Parent = list })
		y += 40
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
end

---------------------------------------------------------------------
-- FICHAS (tienda: solo cosméticos, cada uno una vez)
---------------------------------------------------------------------
function Pages.shop(list: ScrollingFrame, layout: { [string]: any }, state: { [string]: any }?, actions: { [string]: any })
	clear(list)
	local S = layout.Shop
	local T = layout.Text
	local btnH = if layout.Touch then 44 else 32
	local width = layout.Page.W - layout.Missions.ScrollBar - 6
	local tokens = (state and state.Progress and state.Progress.Tokens) or 0
	local items = (state and state.TokenShop) or {}
	Theme.label({
		Name = "Info",
		Position = UDim2.fromOffset(4, 0),
		Size = UDim2.fromOffset(width - 8, S.Info),
		Text = ("Tienes 🪙 %d ficha%s · Se ganan con la XP de más del nivel 50 y algunas misiones · Solo cosméticos"):format(tokens, if tokens == 1 then "" else "s"),
		TextSize = T.Small,
		TextColor3 = C.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = list,
	})
	local y = S.Info + 6
	if #items == 0 then
		Theme.label({ Name = "Empty", Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(width - 8, 40), Text = "Esta temporada no tiene tienda de fichas.", TextSize = T.Body, TextColor3 = C.Muted, Parent = list })
		list.CanvasSize = UDim2.fromOffset(0, y + 40)
		return
	end
	local card = S.Card
	local columns = math.max(1, math.floor((width + S.Gap) / (card.X + S.Gap)))
	for i, item in items do
		local col = (i - 1) % columns
		local line = math.floor((i - 1) / columns)
		local frame = create("Frame", {
			Name = "Item_" .. tostring(item.Id),
			Position = UDim2.fromOffset(col * (card.X + S.Gap), y + line * (card.Y + S.Gap)),
			Size = UDim2.fromOffset(card.X, card.Y),
			BackgroundColor3 = H.Navy,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Parent = list,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }), create("UIGradient", { Rotation = 90, Color = Theme.PanelSheen }) })
		frame:SetAttribute("ItemId", item.Id)
		local rarity = if typeof(item.RarityColor) == "Color3" then item.RarityColor elseif actions.rarityColor then actions.rarityColor(item.Rarity) else nil
		create("UIStroke", { Color = rarity or C.Stroke, Transparency = 0.45, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame })
		Theme.label({ Name = "Icon", Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(card.X - 16, 52), Text = tostring(item.Icon or "🎁"), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
		Theme.label({ Name = "ItemName", Position = UDim2.fromOffset(8, 64), Size = UDim2.fromOffset(card.X - 16, 40), Text = tostring(item.Name or ""), Font = Theme.FontBold, TextSize = T.Body - 1, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
		Theme.label({ Name = "Meta", Position = UDim2.fromOffset(8, 106), Size = UDim2.fromOffset(card.X - 16, 18), Text = ("%s · 🪙 %d"):format(tostring(item.TypeName or item.Type or ""), tonumber(item.Cost) or 0), TextSize = T.Small - 1, TextColor3 = C.Muted, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Center, Parent = frame })
		local cost = tonumber(item.Cost) or 0
		local pending = actions.pending and actions.pending["Token:" .. tostring(item.Id)]
		local text, active
		if item.Owned then
			text, active = "✔ TUYO", false
		elseif pending then
			text, active = "…", false
		elseif tokens < cost then
			text, active = ("Faltan %d 🪙"):format(cost - tokens), false
		else
			text, active = ("CANJEAR · 🪙 %d"):format(cost), true
		end
		local button = smallButton(frame, "Buy", text, { 8, card.Y - btnH - 8, card.X - 16, btnH }, T.Button, active)
		button.AutoButtonColor = active
		if not active then
			button.BackgroundTransparency = 0.4
			button.TextColor3 = if item.Owned then View.Colors.Claimed else C.Muted
		end
		button.Activated:Connect(function()
			if active then
				actions.buyToken(item.Id)
			end
		end)
	end
	local lines = math.ceil(#items / columns)
	list.CanvasSize = UDim2.fromOffset(0, y + lines * (card.Y + S.Gap))
end

return Pages
