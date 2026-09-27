-- FishingUI (cliente): la pesca.
--   * Al lanzar: caña en la mano, sedal y corcho flotando en el agua. Abajo, el botón "¡TIRAR!"
--     (en el ordenador también la tecla R). Cuando el corcho se hunde, ¡a tirar rápido!
--   * Peces grandes: pelean. Barra de tirones: toca "¡TIRA!" muchas veces antes de que se suelte.
--   * Monstruos (Megalodón, Kraken): arriba sale su barra de vida; todos los del barco tiran a la vez.
--   * Tienda de pesca: cañas, herramientas y cebo (lo bueno pide nivel).
--   * App "🐟 Guía de pesca" del teléfono: tu nivel, todos los peces, dónde viven y qué piden.

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Format = require(ReplicatedStorage.Shared.Format)
local Fishing = require(ReplicatedStorage.Shared.Fishing)
local Hud = require(script.Parent.Parent.UI.Hud)
local SoundFx = require(script.Parent.SoundFx)

local FishingUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Fishing") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local panel: Frame
local hereButton: TextButton
local status: TextLabel
local reelButton: TextButton
local stopButton: TextButton
local fightBar: Frame
local fightFill: Frame
local bossPanel: Frame
local bossParts: { [string]: any } = {}

type Session = { Token: number, Bobber: BasePart?, Rod: BasePart?, Beam: Beam?, Base: Vector3, Bite: boolean, Done: boolean, Folder: Folder, Fight: boolean? }
local session: Session? = nil

local function cleanup()
	if session then
		session.Folder:Destroy()
		if session.Rod then
			session.Rod:Destroy()
		end
	end
	session = nil
	panel.Visible = false
	fightBar.Visible = false
	ContextActionService:UnbindAction("FishReel")
end

local function setButton(text: string, color: Color3)
	reelButton.Text = text
	reelButton.BackgroundColor3 = color
end

local function reel()
	local s = session
	if not s then
		return
	end
	if s.Done then
		Remote:FireServer("Again")
		return
	end
	Remote:FireServer("Reel", s.Token)
end

-- Caña en la mano, sedal y corcho
local function props(bobberAt: Vector3): (BasePart?, BasePart, Beam?, Folder)
	local folder = Instance.new("Folder")
	folder.Name = "Fishing"
	folder.Parent = workspace.CurrentCamera
	local bobber = Instance.new("Part")
	bobber.Name = "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.7, 0.7, 0.7)
	bobber.Color = rgb(230, 40, 40)
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.CFrame = CFrame.new(bobberAt)
	bobber.Parent = folder
	local top = Instance.new("Part")
	top.Name = "BobberTop"
	top.Shape = Enum.PartType.Ball
	top.Size = Vector3.new(0.45, 0.45, 0.45)
	top.Color = rgb(250, 250, 250)
	top.Anchored = true
	top.CanCollide = false
	top.CanQuery = false
	top.CFrame = CFrame.new(bobberAt + Vector3.new(0, 0.4, 0))
	top.Parent = bobber
	local hand = player.Character and (player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("Right Arm")) :: BasePart?
	if not hand then
		return nil, bobber, nil, folder
	end
	local rod = Instance.new("Part")
	rod.Name = "FishingRod"
	rod.Size = Vector3.new(0.14, 0.14, 7)
	rod.Color = rgb(40, 40, 44)
	rod.Material = Enum.Material.Metal
	rod.CanCollide = false
	rod.CanQuery = false
	rod.Massless = true
	rod.CFrame = hand.CFrame * CFrame.new(0, -0.2, -3.2) * CFrame.Angles(math.rad(35), 0, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = rod
	weld.Parent = rod
	rod.Parent = player.Character
	local tip = Instance.new("Attachment")
	tip.Position = Vector3.new(0, 0, -3.5)
	tip.Parent = rod
	local float = Instance.new("Attachment")
	float.Parent = bobber
	local beam = Instance.new("Beam")
	beam.Attachment0 = tip
	beam.Attachment1 = float
	beam.Width0 = 0.04
	beam.Width1 = 0.04
	beam.Color = ColorSequence.new(rgb(240, 240, 240))
	beam.CurveSize0 = -2
	beam.FaceCamera = true
	beam.Parent = rod
	return rod, bobber, beam, folder
end

local function onCast(data: { [string]: any })
	cleanup()
	local rod, bobber, beam, folder = props(data.Bobber)
	session = { Token = data.Token, Bobber = bobber, Rod = rod, Beam = beam, Base = data.Bobber, Bite = false, Done = false, Folder = folder }
	panel.Visible = true
	status.Text = ("🎣 Nv %d · %s con tu %s%s · 🐟 banco %d%%… espera a que el corcho se hunda"):format(
		data.Level or 1,
		data.Water,
		string.lower(data.Rod),
		if data.Bait then (" (cebo: %d)"):format(data.BaitLeft) else "",
		data.Shoal or 100
	)
	status.TextColor3 = C.Text
	setButton("¡TIRAR!", rgb(60, 70, 90))
	ContextActionService:BindAction("FishReel", function(_, state)
		if state == Enum.UserInputState.Begin then
			reel()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonR2)
end

local function onBite(data: { [string]: any })
	local s = session
	if not s or s.Token ~= data.Token then
		return
	end
	s.Bite = true
	status.Text = if data.Big then "💥 ¡Pica algo GRANDE! ¡Tira ya!" else "🐟 ¡PICA! ¡Tira ya!"
	status.TextColor3 = C.Gold
	setButton("¡TIRAR YA!", rgb(40, 170, 80))
	pcall(SoundFx.play, "Aviso", 1, 1.4)
end

local RESULTS = {
	Early = "Has tirado demasiado pronto: el pez se ha asustado. Espera a que el corcho se hunda.",
	Late = "¡Se ha escapado! Cuando se hunda el corcho, hay que tirar rápido.",
	Boss = "🌊 ¡Algo GIGANTESCO ha picado! ¡Tirad todos a la vez!",
}

-- Pelea con un pez grande: barra de tirones
local function setFight(got: number, need: number)
	fightBar.Visible = true
	fightFill.Size = UDim2.fromScale(math.clamp(got / need, 0, 1), 1)
	setButton(("💪 ¡TIRA! (%d/%d)"):format(got, need), rgb(200, 90, 40))
end

local function onFight(data: { [string]: any })
	local s = session
	if not s or s.Token ~= data.Token then
		return
	end
	s.Fight = true
	local color = Fishing.RarityColors[data.Rarity] or C.Gold
	status.Text = ("%s ¡Ha picado: %s (%s)! Toca ¡TIRA! sin parar antes de que se suelte"):format(data.Icon, string.lower(data.Name), string.lower(data.Rarity or ""))
	status.TextColor3 = color
	setFight(data.Got, data.Need)
	pcall(SoundFx.play, "Aviso", 1, 1.1)
end

local function onPull(data: { [string]: any })
	local s = session
	if s and s.Token == data.Token and s.Fight then
		setFight(data.Got, data.Need)
	end
end

local function onResult(data: { [string]: any })
	local s = session
	if not s or s.Token ~= data.Token then
		return
	end
	s.Done = true
	s.Bite = false
	s.Fight = false
	fightBar.Visible = false
	if data.Kind == "Catch" then
		status.Text = ("%s ¡Has pescado %s de %s kg! %s · +%d exp · 🎒 a la mochila (%s)"):format(data.Icon, string.lower(data.Name), (string.gsub(tostring(data.Kg), "%.", ",")), data.Rarity or "", data.Xp or 0, Format.money(data.Price))
		status.TextColor3 = Fishing.RarityColors[data.Rarity] or C.Money
		pcall(SoundFx.play, "Aviso", 1, 1.8)
	elseif data.Kind == "Junk" then
		status.Text = ("%s Has sacado %s. A la basura…"):format(data.Icon, data.Name)
		status.TextColor3 = C.Muted
	elseif data.Kind == "Locked" then
		status.Text = ("%s ¡Ha picado %s y ha roto el sedal! Te falta: %s."):format(data.Icon, string.lower(data.Name), table.concat(data.Missing or {}, ", "))
		status.TextColor3 = C.Gold
	elseif data.Kind == "Escaped" then
		status.Text = ("%s ¡%s se ha soltado! Con los grandes hay que tirar más rápido (o con una caña mejor)."):format(data.Icon, data.Name)
		status.TextColor3 = C.Error
	elseif data.Kind == "Boss" then
		status.Text = RESULTS.Boss
		status.TextColor3 = C.Gold
	elseif data.Kind == "Full" then
		status.Text = ("%s ¡Mochila llena! Sueltas %s. Vende el pescado en el supermercado."):format(data.Icon, string.lower(data.Name))
		status.TextColor3 = C.Error
	else
		status.Text = RESULTS[data.Kind] or ""
		status.TextColor3 = C.Error
	end
	setButton("🎣 Lanzar otra vez", C.Accent)
	if s.Bobber then
		s.Bobber.Transparency = 1
		for _, child in s.Bobber:GetChildren() do
			if child:IsA("BasePart") then
				child.Transparency = 1
			end
		end
	end
	if s.Beam then
		s.Beam.Enabled = false
	end
end

---------------------------------------------------------------------
-- Tienda de pesca
---------------------------------------------------------------------
local function openShop(list: { any })
	local window, content, close = Dialog.window("FishingShop", ("🎣 Tienda de pesca · tu nivel: %d"):format(player:GetAttribute("FishingLevel") or 1), Vector2.new(500, 480))
	local layout = create("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = layout })
	for i, it in list do
		local row = create("Frame", { Size = UDim2.new(1, -8, 0, 62), BackgroundColor3 = rgb(20, 32, 56), BackgroundTransparency = 0.2, LayoutOrder = i, Parent = layout }, { Theme.corner(10) })
		Theme.label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -140, 0, 26), Text = ("%s <b>%s</b> · %s"):format(it.Icon, it.Name, Format.money(it.Price)), RichText = true, TextSize = 15, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -140, 0, 28), Text = it.Desc .. (if it.Have then (" (tienes %d)"):format(it.Have) else ""), TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = row })
		local buy = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(110, 40),
			Text = if it.Owned then "✅ La tienes" elseif it.Locked then ("🔒 Nivel %d"):format(it.Level) else "Comprar",
			TextSize = 14,
			BackgroundColor3 = if it.Owned or it.Locked then rgb(50, 52, 60) else C.Accent,
			Parent = row,
		})
		buy.Activated:Connect(function()
			if not it.Owned and not it.Locked then
				Remote:FireServer("Buy", it.Id)
			end
		end)
	end
	Theme.label({ Size = UDim2.new(1, 0, 0, 40), Text = "Con la caña puedes pescar en cualquier orilla (sale el botón 🎣 Pescar aquí), en los pantalanes y en el barco. Los peces grandes piden más nivel, mejor caña o una herramienta; los más grandes solo viven en alta mar (barco). Mira la 🐟 Guía de pesca del teléfono.", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, LayoutOrder = 100, Parent = layout })
	close.Activated:Connect(function()
		window:Destroy()
	end)
end

---------------------------------------------------------------------
-- "Pescar aquí": si llevas caña y tienes agua delante, en cualquier orilla
---------------------------------------------------------------------
local function hasRod(): boolean
	local ok, slots = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Inventory") or "[]")
	end)
	for _, slot in if ok and typeof(slots) == "table" then slots else {} do
		if typeof(slot) == "table" and Fishing.Rods[slot.i] then
			return true
		end
	end
	return false
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = false

local function waterAhead(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.SeatPart or humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		return false
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		return false
	end
	flat = flat.Unit
	rayParams.FilterDescendantsInstances = { workspace.Terrain }
	for _, d in { 6, 9, 12, 15 } do
		local p = root.Position + flat * d
		local hit = workspace:Raycast(Vector3.new(p.X, 12, p.Z), Vector3.new(0, -30, 0), rayParams)
		if hit and hit.Material == Enum.Material.Water then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Monstruos marinos: barra de vida arriba y botón para tirar todos juntos
---------------------------------------------------------------------
local function showBoss(data: { [string]: any })
	bossPanel.Visible = true
	bossParts.Title.Text = ("%s ¡%s!"):format(data.Icon, string.upper(data.Name))
	bossParts.Fill.Size = UDim2.fromScale(math.clamp(data.Hp / math.max(data.Max, 1), 0, 1), 1)
	bossParts.Info.Text = ("⏱️ %d s · 👥 ayudando %d (hacen falta %d) · tus tirones: %d"):format(data.Left, data.Helpers, data.MinPlayers, data.Mine)
	if data.CanHelp == false then
		bossParts.Pull.Text = "🔒 Te falta: " .. table.concat(data.Missing or {}, ", ")
		bossParts.Pull.BackgroundColor3 = rgb(50, 52, 60)
	else
		bossParts.Pull.Text = "🔱 ¡TIRAD TODOS!"
		bossParts.Pull.BackgroundColor3 = rgb(200, 60, 50)
	end
end

local function endBoss(data: { [string]: any })
	bossPanel.Visible = false
	Hud.toast(if data.Win then "Success" else "Error", data.Text)
	if session then
		status.Text = data.Text
		status.TextColor3 = if data.Win then C.Gold else C.Error
	end
	pcall(SoundFx.play, "Aviso", 1, if data.Win then 2 else 0.8)
end

local function buildBossPanel(gui: ScreenGui)
	bossPanel = Theme.panel({
		Name = "Boss",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(520, 130),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(10).Parent = bossPanel
	bossParts.Title = Theme.label({ Size = UDim2.new(1, 0, 0, 26), Text = "", Font = Theme.FontBold, TextSize = 20, TextColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = bossPanel })
	local bar = create("Frame", { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = rgb(30, 10, 14), BorderSizePixel = 0, Parent = bossPanel }, { Theme.corner(8) })
	bossParts.Fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(220, 50, 50), BorderSizePixel = 0, Parent = bar }, { Theme.corner(8) })
	bossParts.Info = Theme.label({ Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 18), Text = "", TextSize = 13, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Parent = bossPanel })
	bossParts.Pull = Theme.button({ Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 40), Text = "🔱 ¡TIRAD TODOS!", TextSize = 18, BackgroundColor3 = rgb(200, 60, 50), Parent = bossPanel })
	bossParts.Pull.Activated:Connect(function()
		Remote:FireServer("Reel", "Boss")
	end)
end

---------------------------------------------------------------------
-- Guía de pesca (app del teléfono)
---------------------------------------------------------------------
local function myGear(): (number, { [string]: boolean })
	local tier, tools = 0, {}
	local ok, slots = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("Inventory") or "[]")
	end)
	for _, slot in if ok and typeof(slots) == "table" then slots else {} do
		if typeof(slot) == "table" then
			local rod = Fishing.Rods[slot.i]
			if rod then
				tier = math.max(tier, rod.Tier)
			end
			if Fishing.Tools[slot.i] then
				tools[slot.i] = true
			end
		end
	end
	return tier, tools
end

local function openGuide()
	local level = player:GetAttribute("FishingLevel") or 1
	local xp = player:GetAttribute("FishingXp") or 0
	local caught = {}
	pcall(function()
		caught = HttpService:JSONDecode(player:GetAttribute("FishingCaught") or "{}")
	end)
	local tier, tools = myGear()
	local window, content = Dialog.window("FishingGuide", "🐟 Guía de pesca", Vector2.new(560, 520))
	local _ = window
	-- Nivel y experiencia
	local nextXp = Fishing.xpFor(level + 1)
	local prevXp = Fishing.xpFor(level)
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = if level >= Fishing.MaxLevel then ("🎣 Nivel %d (¡el máximo!) · %d exp"):format(level, xp) else ("🎣 Nivel de pesca %d · %d / %d exp para el nivel %d"):format(level, xp, nextXp, level + 1), Font = Theme.FontBold, TextSize = 15, Parent = content })
	local bar = create("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = rgb(8, 14, 28), BorderSizePixel = 0, Parent = content }, { Theme.corner(5) })
	create("Frame", { Size = UDim2.fromScale(if level >= Fishing.MaxLevel then 1 else math.clamp((xp - prevXp) / math.max(nextXp - prevXp, 1), 0, 1), 1), BackgroundColor3 = C.Money, BorderSizePixel = 0, Parent = bar }, { Theme.corner(5) })
	local seen = 0
	for _ in caught do
		seen += 1
	end
	Theme.label({ Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 18), Text = ("Especies pescadas: %d de %d · peces pequeños desde el principio; los grandes piden nivel, caña y herramienta. Los más grandes, solo en alta mar (barco)."):format(seen, #Fishing.Species), TextSize = 11, TextColor3 = C.Muted, TextWrapped = true, Parent = content })
	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 1, -62),
		BackgroundColor3 = rgb(8, 14, 28),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	Theme.padding(6).Parent = list
	local order = 0
	local function row(target: { [string]: any }, where: string, count: number?)
		order += 1
		local missing = Fishing.missing(target, level, tier, tools)
		local color = Fishing.RarityColors[target.Rarity or "Legendario"] or C.Text
		local needs = { ("Nv %d"):format(target.Level) }
		local rod = Fishing.RodByTier[target.Rod]
		if rod and target.Rod > 1 then
			table.insert(needs, rod.Name)
		end
		if target.Tool and Fishing.Tools[target.Tool] then
			table.insert(needs, Fishing.Tools[target.Tool].Icon .. " " .. Fishing.Tools[target.Tool].Name)
		end
		local lock = if #missing == 0 then "✅" else "🔒"
		local got = if count and count > 0 then ("×%d"):format(count) else "❓"
		if target.Waters and Fishing.spearable(target :: any) then
			got ..= " · 🤿 buceando"
		end
		Theme.label({
			Size = UDim2.new(1, -6, 0, 34),
			Text = ('%s %s <font color="#%s"><b>%s</b></font> · %s\n<font color="#a5b2c8">%s · %s · %s</font>'):format(lock, target.Icon, color:ToHex(), target.Name, got, where, table.concat(needs, " · "), Format.money(target.Price)),
			RichText = true,
			TextSize = 13,
			TextWrapped = true,
			LayoutOrder = order,
			Parent = list,
		})
	end
	local function header(text: string)
		order += 1
		Theme.label({ Size = UDim2.new(1, -6, 0, 24), Text = text, Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Gold, LayoutOrder = order, Parent = list })
	end
	for _, water in { "Rio", "Lago", "Mar", "AltaMar" } do
		header(("%s %s"):format(Fishing.WaterIcons[water], string.upper(string.sub(Fishing.Waters[water], 1, 1)) .. string.sub(Fishing.Waters[water], 2)) .. (if water == "AltaMar" then " (en el barco de pesca)" else ""))
		local here = {}
		for _, sp in Fishing.Species do
			if sp.Waters[water] then
				table.insert(here, sp)
			end
		end
		table.sort(here, function(a, b)
			return a.Level < b.Level
		end)
		for _, sp in here do
			row(sp, Fishing.Waters[water], caught[sp.Id])
		end
	end
	header("🤿 Pesca submarina")
	order += 1
	Theme.label({ Size = UDim2.new(1, -6, 0, 48), Text = "Nada y bucea (botones ⬇️ Bucear / ⬆️ Subir). Con el fusil submarino nadan peces a tu alrededor: apunta con la cámara y 🔱 Disparar. Vigila el aire: gafas y tubo (45 s) o equipo de buceo (150 s). Los grandes piden arpón y los del fondo, equipo de buceo.", TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, LayoutOrder = order, Parent = list })
	header("🌊 Monstruos marinos (alta mar, entre varios)")
	for _, id in Fishing.BossOrder do
		local def = Fishing.Bosses[id]
		row(def, ("hacen falta %d pescadores"):format(def.MinPlayers), caught[def.Id])
	end
end

---------------------------------------------------------------------

function FishingUI.init()
	local gui = create("ScreenGui", { Name = "FishingGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	panel = Theme.panel({
		Name = "Fishing",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(480, 128),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(10).Parent = panel
	status = Theme.label({ Size = UDim2.new(1, 0, 0, 42), Text = "", TextSize = 15, TextWrapped = true, Parent = panel })
	reelButton = Theme.button({ Position = UDim2.fromOffset(0, 50), Size = UDim2.new(0.68, 0, 0, 46), Text = "¡TIRAR!", TextSize = 20, Parent = panel })
	stopButton = Theme.button({ Position = UDim2.new(0.7, 0, 0, 50), Size = UDim2.new(0.3, 0, 0, 46), Text = "Recoger", TextSize = 15, BackgroundColor3 = rgb(50, 52, 60), Parent = panel })
	reelButton.Activated:Connect(reel)
	fightBar = create("Frame", { Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = rgb(8, 14, 28), BorderSizePixel = 0, Visible = false, Parent = panel }, { Theme.corner(4) })
	fightFill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = rgb(240, 150, 40), BorderSizePixel = 0, Parent = fightBar }, { Theme.corner(4) })
	buildBossPanel(gui)
	Hud.addButton("🐟 Guía de pesca", rgb(30, 110, 170), 7, openGuide)
	hereButton = Theme.button({
		Name = "FishHere",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -120),
		Size = UDim2.fromOffset(190, 46),
		Text = "🎣 Pescar aquí",
		TextSize = 17,
		BackgroundColor3 = rgb(30, 110, 170),
		Visible = false,
		Parent = gui,
	})
	hereButton.Activated:Connect(function()
		hereButton.Visible = false
		Remote:FireServer("Here")
	end)
	task.spawn(function()
		while true do
			task.wait(0.4)
			local ok, show = pcall(function()
				return session == nil and hasRod() and waterAhead()
			end)
			hereButton.Visible = ok and show == true
		end
	end)
	stopButton.Activated:Connect(function()
		Remote:FireServer("Stop")
	end)

	Remote.OnClientEvent:Connect(function(action, data)
		if action == "Cast" then
			onCast(data)
		elseif action == "Bite" then
			onBite(data)
		elseif action == "Fight" then
			onFight(data)
		elseif action == "Pull" then
			onPull(data)
		elseif action == "Boss" or action == "BossHp" then
			showBoss(data)
		elseif action == "BossEnd" then
			endBoss(data)
		elseif action == "Result" then
			onResult(data)
		elseif action == "Stop" then
			cleanup()
			bossPanel.Visible = false
		elseif action == "Shop" then
			openShop(data)
		end
	end)
	player.CharacterRemoving:Connect(cleanup)

	-- El corcho flota; cuando pica, da tirones
	RunService.RenderStepped:Connect(function()
		local s = session
		local bobber = s and s.Bobber
		if not s or not bobber or s.Done then
			return
		end
		local t = os.clock()
		local y = if s.Bite then -0.35 + math.sin(t * 28) * 0.25 else math.sin(t * 2.4) * 0.08
		local cf = CFrame.new(s.Base + Vector3.new(0, y, 0))
		bobber.CFrame = cf
		local top = bobber:FindFirstChild("BobberTop") :: BasePart?
		if top then
			top.CFrame = cf * CFrame.new(0, 0.4, 0)
		end
	end)
end

return FishingUI
