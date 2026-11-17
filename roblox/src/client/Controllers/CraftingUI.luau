-- CraftingUI (cliente): el libro de recetas del TALLER (Services/CraftingService; recetas en shared/Crafting).
--   * Pestañas por categoría (Armas, Armaduras, Pociones, Herramientas, Munición, Materiales).
--   * Cada receta: lo que sale, su nivel y su banco, y los materiales con lo que tienes / lo que hace falta
--     (en verde lo que te sobra, en rojo lo que falta). «Fabricar» y «×5».
--   * Con la mesa plegable solo se fabrican las recetas de Mesa; las demás salen apagadas («en un Taller»).
-- El servidor lo comprueba todo; aquí solo se enseña y se pide. Se cierra con ✖ o al alejarse del Taller.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local SoundFx = require(script.Parent.SoundFx)
local Crafting = require(ReplicatedStorage.Shared.Crafting)
local Items = require(ReplicatedStorage.Shared.Items)

local CraftingUI = {}

local player = Players.LocalPlayer
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local gui: ScreenGui
local panel: Frame?
local remote: RemoteEvent
local state = { Bench = "Taller", Have = {} :: { [string]: number }, Tab = "Armas", Extra = {} :: { [string]: any } }
local REFINE_TAB = "Mejorar"
local GEAR_TAB = "Equipo"
local SKILL_TAB = "Habilidades"
local HunterSkills = require(ReplicatedStorage.Shared.HunterSkills)
local Combat = require(ReplicatedStorage.Shared.Combat)
local render: (() -> ())? = nil

local ORE_NAMES = { Hierro = "⛏ Hierro", Cobalto = "⛏ Cobalto", Cristal = "⛏ Cristal", Obsidiana = "⛏ Obsidiana" }
local function short(id: string): string
	local item = Items.get(id)
	if item then
		return item.Icon .. " " .. item.Name
	end
	return ORE_NAMES[id] or id
end

local function close(tell: boolean?)
	if panel then
		panel:Destroy()
		panel = nil
		render = nil
		if tell then
			remote:FireServer("Close")
		end
	end
end

function CraftingUI.isOpen(): boolean
	return panel ~= nil
end

local function open()
	local keep = panel ~= nil
	close(false)
	if not keep then
		SoundFx.play("MenuAbrir")
	end
	local frame = Theme.panel({ Name = "Crafting", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 540), Parent = gui })
	panel = frame
	Dialog.closeOthers("Crafting")
	Theme.padding(14).Parent = frame
	local closeButton = Theme.button({ Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(34, 30), Text = "✖", TextSize = 18, Parent = frame })
	closeButton.Activated:Connect(function()
		close(true)
	end)
	local side = Theme.touchWindow(frame, closeButton, not keep)
	local benchName = if state.Bench == "Mesa" then "🧰 Mesa plegable (solo recetas de Mesa)" elseif state.Bench == "Mochila" then "🎒 Equipo y fabricar" else "🛠 Taller · Mesa, Forja y Alquimia"
	do
		local xp = tonumber(state.Extra.Xp) or 0
		local lvl = Crafting.hunterLevel(xp)
		benchName ..= ("  ·  ⭐ Cazador nv. %d"):format(lvl)
	end
	Theme.title({ Size = UDim2.new(1, -(side + 6), 0, 26), Text = benchName, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
	local top = math.max(34, side + 2)
	-- pestañas
	local tabs = create("ScrollingFrame", { Name = "Tabs", Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, 38), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 3, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = frame })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabs })
	local list = create("ScrollingFrame", { Name = "List", Position = UDim2.fromOffset(0, top + 46), Size = UDim2.new(1, 0, 1, -(top + 46)), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = frame })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local function draw()
		for _, ch in tabs:GetChildren() do
			if ch:IsA("GuiButton") then
				ch:Destroy()
			end
		end
		local tabNames = table.clone(Crafting.Categories)
		table.insert(tabNames, 1, REFINE_TAB)
		table.insert(tabNames, 1, SKILL_TAB)
		table.insert(tabNames, 1, GEAR_TAB)
		for i, cat in tabNames do
			local b = Theme.button({ Size = UDim2.fromOffset(if Theme.isTouch() then 118 else 104, 32), Text = cat, TextSize = 14, LayoutOrder = i, Parent = tabs })
			if cat == state.Tab then
				b.BackgroundColor3 = rgb(70, 130, 210)
			end
			b.Activated:Connect(function()
				SoundFx.play("MenuOk")
				state.Tab = cat
				draw()
			end)
		end
		for _, ch in list:GetChildren() do
			if ch:IsA("Frame") then
				ch:Destroy()
			end
		end
		local order = 0
		local function row(height: number, color: Color3?): Frame
			order += 1
			local f = create("Frame", { Size = UDim2.new(1, -8, 0, height), BackgroundColor3 = color or rgb(24, 30, 46), BackgroundTransparency = 0.15, LayoutOrder = order, Parent = list })
			Theme.corner(8).Parent = f
			Theme.padding(8).Parent = f
			return f
		end
		if state.Tab == GEAR_TAB then
			-- EQUIPO: lo que llevas en cada hueco (lo mejor de tu mochila) y lo que suma todo
			local refine = if type(state.Extra.Refine) == "table" then state.Extra.Refine else {}
			local worn = Crafting.stats(state.Have, refine)
			local xp = tonumber(state.Extra.Xp) or 0
			local lvl = Crafting.hunterLevel(xp)
			local nextNeed = Crafting.hunterNeed(lvl + 1)
			local head = row(70, rgb(30, 40, 62))
			local style = Combat.weaponStyle(state.Extra.Style)
			Theme.label({ Size = UDim2.fromScale(1, 1), TextWrapped = true, TextSize = 13, RichText = true, TextYAlignment = Enum.TextYAlignment.Top, Text = ("<b>⭐ Cazador nivel %d</b>  (%d / %d de experiencia)\nEstilo de golpe: <b>%s</b>%s\n⚔️ +%d %% golpes · 🛡 −%d %% daño · 🍀 +%d %% botín raro · 💚 +%d vida por bestia"):format(lvl, xp, if lvl >= Crafting.MaxHunter then xp else nextNeed, style.Name, if style.Text then " · " .. style.Text else "", math.floor((worn.Blade + Crafting.hunterBonus(xp)) * 100 + 0.5), math.floor(worn.Defense * 100 + 0.5), math.floor(worn.Luck * 100 + 0.5), worn.Vigor), Parent = head })
			for _, slot in Crafting.Slots do
				local id = worn.Worn[slot]
				local f = row(if Theme.isTouch() then 44 else 38)
				local item = id and Items.get(id)
				local text = if item then ("%s %s"):format(item.Icon, Crafting.refinedName(item.Name, Crafting.refineOf(refine, id))) else "— vacío —"
				Theme.label({ Size = UDim2.fromScale(0.34, 1), Text = ("%s %s"):format(Crafting.SlotIcons[slot] or "", slot), TextSize = 14, TextColor3 = C.Muted, Parent = f })
				Theme.label({ Position = UDim2.fromScale(0.34, 0), Size = UDim2.fromScale(0.66, 1), Text = text, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = if id then C.Text else C.Muted, Parent = f })
			end
			local tip = row(40, rgb(20, 26, 40))
			Theme.label({ Size = UDim2.fromScale(1, 1), TextWrapped = true, TextSize = 12, TextColor3 = C.Muted, Text = "Se usa solo lo mejor de cada hueco que lleves en la mochila. En los planetas se ve puesto y tu arma cambia cómo golpeas.", Parent = tip })
		elseif state.Tab == SKILL_TAB then
			-- HABILIDADES: subir de rango con los puntos de habilidad (uno por nivel de cazador)
			local ranks = if type(state.Extra.Skills) == "table" then state.Extra.Skills else {}
			local lvl = Crafting.hunterLevel(tonumber(state.Extra.Xp) or 0)
			local left = HunterSkills.pointsLeft(lvl, ranks)
			local head = row(46, rgb(30, 40, 62))
			Theme.label({ Size = UDim2.fromScale(1, 1), TextWrapped = true, TextSize = 13, RichText = true, Text = ("<b>Puntos de habilidad: %d</b>  · Ganas uno por cada nivel de cazador. Cada rango: +12 %% de fuerza y algo menos de espera. Rango 10 = Maestra."):format(left), Parent = head })
			for _, sk in HunterSkills.List do
				local unlocked = HunterSkills.unlocked(sk, lvl, HunterSkills.knownFromText(game:GetService("Players").LocalPlayer:GetAttribute("HabilidadesSabidas")))
				local rank = HunterSkills.rankOf(ranks, sk.Id)
				local f = row(if Theme.isTouch() then 80 else 72)
				Theme.label({ Size = UDim2.new(1, -150, 0, 22), Text = ("%s %s · %s"):format(sk.Icon, sk.Name, if unlocked then HunterSkills.rankName(rank) else ("nivel %d"):format(sk.Level)), TextSize = 15, TextColor3 = if not unlocked then C.Muted elseif rank >= HunterSkills.MaxRank then rgb(255, 200, 90) else C.Text, Parent = f })
				local detail = if sk.Kind == "Buff" then ("+%d %% de daño %d s"):format(math.floor(HunterSkills.buffAmount(sk, rank) * 100 + 0.5), sk.Seconds) else ("fuerza ×%.1f"):format(HunterSkills.power(sk, rank))
				Theme.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, -150, 0, 34), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = ("%s %s · espera %d s · tecla %s"):format(sk.Desc, detail, math.floor(HunterSkills.cooldown(sk, rank) + 0.5), sk.Key), TextSize = 12, TextColor3 = C.Muted, Parent = f })
				if unlocked and rank < HunterSkills.MaxRank then
					local btn = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(136, if Theme.isTouch() then 44 else 36), Text = ("Subir a %d"):format(rank + 1), TextSize = 14, Parent = f })
					if left < 1 then
						btn.BackgroundColor3 = rgb(60, 62, 70)
						btn.TextColor3 = rgb(150, 150, 160)
					end
					btn.Activated:Connect(function()
						SoundFx.play("MenuOk")
						remote:FireServer("SkillUp", sk.Id)
					end)
				end
			end
		elseif state.Tab == REFINE_TAB then
			-- MEJORAR: tu equipo, con su nivel (+0…+9), lo que da ahora y lo que cuesta el siguiente
			local refine = if type(state.Extra.Refine) == "table" then state.Extra.Refine else {}
			local money = tonumber(state.Extra.Money) or 0
			local worn = Crafting.stats(state.Have, refine)
			local head = create("Frame", { Size = UDim2.new(1, -8, 0, 46), BackgroundColor3 = rgb(30, 40, 62), BackgroundTransparency = 0.1, LayoutOrder = 0, Parent = list })
			Theme.corner(8).Parent = head
			Theme.padding(8).Parent = head
			Theme.label({ Size = UDim2.fromScale(1, 1), TextWrapped = true, TextSize = 13, Text = ("Llevas puesto: ⚔️ +%d %% golpes · 🛡 −%d %% daño · 🍀 +%d %% botín · 💚 +%d vida por bestia. Se usa solo lo mejor de cada hueco que lleves en la mochila."):format(math.floor(worn.Blade * 100 + 0.5), math.floor(worn.Defense * 100 + 0.5), math.floor(worn.Luck * 100 + 0.5), worn.Vigor), Parent = head })
			local owned = {}
			for _, g in Crafting.Gear do
				if Crafting.isEquip(g.Id) and (state.Have[g.Id] or 0) > 0 then
					table.insert(owned, g)
				end
			end
			-- (y las armas de fuego que lleves: cada +1, un 8 % más contra las bestias con esa arma)
			local guns = {}
			for id, n in state.Have do
				if Crafting.isGun(id) and n > 0 then
					local item = Items.get(id)
					table.insert(guns, { Id = id, Name = item and item.Name or id, Icon = item and item.Icon or "🔫", Gun = true })
				end
			end
			table.sort(guns, function(a, b)
				return a.Id < b.Id
			end)
			for _, g in guns do
				table.insert(owned, g)
			end
			if #owned == 0 then
				local empty = create("Frame", { Size = UDim2.new(1, -8, 0, 60), BackgroundTransparency = 1, LayoutOrder = 1, Parent = list })
				Theme.label({ Size = UDim2.fromScale(1, 1), TextWrapped = true, TextSize = 14, TextColor3 = C.Muted, Text = "Todavía no llevas equipo. Fabrica un arma, una armadura o un accesorio en las otras pestañas y vuelve aquí para mejorarlo.", Parent = empty })
			end
			for _, g in owned do
				order += 1
				local level = Crafting.refineOf(refine, g.Id)
				local step = Crafting.refineStep(level)
				local slot = if g.Gun then "Fuego" else (Crafting.slotOf(g) or "")
				local isWorn = worn.Worn[slot] == g.Id
				local card = create("Frame", { Size = UDim2.new(1, -8, 0, if Theme.isTouch() then 92 else 84), BackgroundColor3 = if isWorn then rgb(28, 44, 40) else rgb(24, 30, 46), BackgroundTransparency = 0.15, LayoutOrder = order, Parent = list })
				Theme.corner(8).Parent = card
				Theme.padding(8).Parent = card
				local st = if g.Gun then { Blade = 0, Defense = 0, Luck = 0, Vigor = 0 } else Crafting.gearStats(g.Id, level)
				local bits = {}
				if g.Gun then
					table.insert(bits, ("🔫 +%d %% a las bestias"):format(math.floor(level * Crafting.GunBonus * 100 + 0.5)))
				end
				if st.Blade > 0 then
					table.insert(bits, ("⚔️ +%d %%"):format(math.floor(st.Blade * 100 + 0.5)))
				end
				if st.Defense > 0 then
					table.insert(bits, ("🛡 −%d %%"):format(math.floor(st.Defense * 100 + 0.5)))
				end
				if st.Luck > 0 then
					table.insert(bits, ("🍀 +%d %%"):format(math.floor(st.Luck * 100 + 0.5)))
				end
				if st.Vigor > 0 then
					table.insert(bits, ("💚 +%d"):format(st.Vigor))
				end
				Theme.label({ Size = UDim2.new(1, -150, 0, 22), Text = ("%s %s"):format(g.Icon, Crafting.refinedName(g.Name, level)), TextSize = 16, TextColor3 = if level >= 7 then rgb(255, 200, 90) elseif level >= 4 then rgb(140, 200, 255) else C.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
				Theme.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, -150, 0, 16), Text = ("%s %s%s · %s"):format(Crafting.SlotIcons[slot] or "", slot, if isWorn then " (puesto)" else "", table.concat(bits, " · ")), TextSize = 12, TextColor3 = C.Muted, Parent = card })
				if step then
					local haveStone = state.Have[step.Stone] or 0
					local okStone, okMoney = haveStone >= step.Stones, money >= step.Money
					local risk = if level + 1 >= Crafting.RefineDropFrom then " Si falla, baja un nivel (el 🔏 Sello lo evita)." else ""
					Theme.label({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, -150, 0, 34), RichText = true, TextWrapped = true, TextSize = 12, TextYAlignment = Enum.TextYAlignment.Top, Text = ('A +%d: %s <font color="%s">%d/%d</font> · <font color="%s">%d €</font> · acierto %d %%.%s'):format(level + 1, short(step.Stone), if okStone then "#8CF09A" else "#FF7A6E", haveStone, step.Stones, if okMoney then "#8CF09A" else "#FF7A6E", step.Money, math.floor(step.Chance * 100 + 0.5), risk), Parent = card })
					local btn = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(136, if Theme.isTouch() then 44 else 36), Text = ("Mejorar a +%d"):format(level + 1), TextSize = 14, Parent = card })
					if not (okStone and okMoney) then
						btn.BackgroundColor3 = rgb(60, 62, 70)
						btn.TextColor3 = rgb(150, 150, 160)
					end
					btn.Activated:Connect(function()
						SoundFx.play("MenuOk")
						remote:FireServer("Refine", g.Id)
					end)
				else
					Theme.label({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, -150, 0, 30), Text = "Al máximo: no se puede mejorar más.", TextSize = 12, TextColor3 = rgb(255, 200, 90), Parent = card })
				end
			end
		end
		for _, r in Crafting.Recipes do
			if r.Category == state.Tab then
				order += 1
				local available = Crafting.benchHas(state.Bench, r)
				local times = Crafting.times(r, state.Have)
				local card = create("Frame", { Size = UDim2.new(1, -8, 0, if Theme.isTouch() then 86 else 78), BackgroundColor3 = rgb(24, 30, 46), BackgroundTransparency = 0.15, LayoutOrder = order, Parent = list })
				Theme.corner(8).Parent = card
				Theme.padding(8).Parent = card
				local level = Crafting.Levels[r.Level] or ""
				local bench = Crafting.Benches[r.Bench]
				local makes = if r.Makes > 1 then (" ×%d"):format(r.Makes) else ""
				Theme.label({ Size = UDim2.new(1, -190, 0, 22), Text = short(r.Id) .. makes, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
				Theme.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, -190, 0, 16), Text = ("%s · %s %s"):format(level, bench.Icon, bench.Name), TextSize = 12, TextColor3 = C.Muted, Parent = card })
				-- materiales: tienes/hacen falta
				local parts = {}
				local keys = {}
				for id in r.Needs do
					table.insert(keys, id)
				end
				table.sort(keys)
				for _, id in keys do
					local need = r.Needs[id]
					local have = state.Have[id] or 0
					local color = if have >= need then "#8CF09A" else "#FF7A6E"
					table.insert(parts, ('%s <font color="%s">%d/%d</font>'):format(short(id), color, have, need))
				end
				Theme.label({ Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, -190, 0, 30), Text = table.concat(parts, "   "), RichText = true, TextWrapped = true, TextSize = 12, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
				local function craftButton(text: string, n: number, x: number)
					local btn = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(if n == 1 then 104 else 64, if Theme.isTouch() then 40 else 34), Text = text, TextSize = 14, Parent = card })
					if not available or times < n then
						btn.BackgroundColor3 = rgb(60, 62, 70)
						btn.TextColor3 = rgb(150, 150, 160)
					end
					btn.Activated:Connect(function()
						if not available then
							SoundFx.play("MenuNo")
							return
						end
						SoundFx.play("MenuOk")
						remote:FireServer("Craft", r.Id, n)
					end)
				end
				if available then
					craftButton("Fabricar", 1, -70)
					craftButton("×5", 5, 0)
				else
					Theme.label({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(170, 34), Text = "Solo en un Taller de ciudad", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = card })
				end
			end
		end
	end
	render = draw
	draw()
	-- se cierra solo si te alejas (de la mesa plegable no: va contigo)
	if state.Bench ~= "Mesa" and state.Bench ~= "Mochila" then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local origin = root and root.Position
		task.spawn(function()
			while panel == frame do
				task.wait(0.5)
				local now = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not now or not origin or (now.Position - origin).Magnitude > 18 then
					close(true)
				end
			end
		end)
	end
end

-- Abre el libro desde la mochila (fabricar y mejorar en cualquier sitio)
function CraftingUI.openFromBag()
	if remote then
		remote:FireServer("OpenBag")
	end
end

function CraftingUI.init()
	gui = create("ScreenGui", { Name = "CraftingGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 7, Parent = player:WaitForChild("PlayerGui") })
	local scale = create("UIScale", { Parent = gui })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(math.min(camera.ViewportSize.Y / 900, camera.ViewportSize.X / 1700), 0.6, 1.2)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
	Dialog.registerBig("Crafting", function()
		close(true)
	end, function()
		return panel ~= nil
	end)
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Crafting") :: RemoteEvent
	remote.OnClientEvent:Connect(function(kind: string, a: any, b: any)
		if kind == "Open" and type(a) == "table" then
			state.Bench = if a.Bench == "Mesa" then "Mesa" elseif a.Bench == "Mochila" then "Mochila" else "Taller"
			-- (desde la mochila se abre en «Equipo»; en un Taller, en las recetas)
			if a.Bench == "Mochila" and state.Bench ~= "Mochila" or (a.Bench == "Mochila" and not panel) then
				state.Tab = GEAR_TAB
			end
			state.Have = if type(a.Have) == "table" then a.Have else {}
			state.Extra = if type(a.Extra) == "table" then a.Extra else {}
			open()
		elseif kind == "Have" and type(a) == "table" then
			state.Have = a
			if type(b) == "table" then
				state.Extra = b
			end
			if render then
				render()
			end
		elseif kind == "Result" then
			SoundFx.play(if a then "MenuOk" else "MenuNo")
			local okHud, Hud = pcall(function()
				return require(script.Parent.Parent.UI.Hud) :: any
			end)
			if okHud and Hud.toast then
				Hud.toast(if a then "Success" else "Error", tostring(b or ""))
			end
		end
	end)
end

return CraftingUI
