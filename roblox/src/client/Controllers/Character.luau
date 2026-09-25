-- Character: vida, estamina, nivel y estadísticas del personaje en pantalla.
--   * Barras de vida ❤ y estamina ⚡ encima de las de hambre y energía (abajo a la izquierda)
--   * Nivel y barra de experiencia junto al dinero
--   * Botón "⭐ Personaje": reparte los puntos de cada nivel en Salud, Resistencia, Fuerza, Destreza y Suerte
--   * Correr: mantén Shift (en móvil, el botón 🏃) mientras te quede estamina

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)

local create = Theme.create
local C = Theme.Colors

local Character = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Progression") :: RemoteEvent
local P = Gameplay.Progression
local rgb = Color3.fromRGB

local function bar(parent: Instance, icon: string, color: Color3, order: number): (number, number) -> ()
	local row = create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	Theme.label({ Size = UDim2.fromOffset(24, 22), Text = icon, TextSize = 16, Parent = row })
	local track = create("Frame", {
		Size = UDim2.new(1, -86, 0, 10),
		Position = UDim2.new(0, 26, 0.5, -5),
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		Parent = row,
	}, { Theme.corner(5) })
	local fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = track }, { Theme.corner(5) })
	local value = Theme.label({ Size = UDim2.fromOffset(56, 22), Position = UDim2.new(1, -56, 0, 0), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
	return function(amount: number, max: number)
		local ratio = math.clamp(amount / math.max(max, 1), 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(ratio, 1) }):Play()
		fill.BackgroundColor3 = if ratio <= 0.2 then C.Error else color
		value.Text = ("%d/%d"):format(math.floor(amount + 0.5), math.floor(max + 0.5))
	end
end

local function buildVitals(gui: Instance)
	local panel = Theme.panel({
		Name = "Vitals",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(230, 76),
		Position = UDim2.new(0, 16, 1, -100),
		Parent = gui,
	})
	Theme.padding(12).Parent = panel
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	local setHealth = bar(panel, "❤", rgb(230, 70, 80), 1)
	local setStamina = bar(panel, "🏃", rgb(90, 210, 140), 2)

	local healthConnection: RBXScriptConnection? = nil
	local function watchHumanoid(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		if healthConnection then
			healthConnection:Disconnect()
		end
		local function update()
			setHealth(humanoid.Health, humanoid.MaxHealth)
		end
		healthConnection = humanoid.HealthChanged:Connect(update)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
		update()
	end
	player.CharacterAdded:Connect(watchHumanoid)
	if player.Character then
		task.spawn(watchHumanoid, player.Character)
	end

	local function updateStamina()
		local max = player:GetAttribute("MaxStamina") or P.Stamina.Base
		setStamina(player:GetAttribute("Stamina") or max, max)
	end
	player:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
	player:GetAttributeChangedSignal("MaxStamina"):Connect(updateStamina)
	updateStamina()
	-- De bebé no hace falta (no corre ni lucha)
	local function stage()
		panel.Visible = player:GetAttribute("LifeStage") ~= "Bebe"
	end
	player:GetAttributeChangedSignal("LifeStage"):Connect(stage)
	stage()
end

local function buildLevel(gui: Instance)
	local panel = Theme.panel({
		Name = "Level",
		Size = UDim2.fromOffset(200, 30),
		Position = UDim2.fromOffset(16, 102),
		Parent = gui,
	})
	local text = Theme.label({ Size = UDim2.new(0, 70, 1, 0), Position = UDim2.fromOffset(10, 0), Font = Theme.FontBold, TextSize = 15, TextColor3 = C.Gold, Parent = panel })
	local track = create("Frame", { Size = UDim2.new(1, -92, 0, 8), Position = UDim2.new(0, 80, 0.5, -4), BackgroundColor3 = C.PanelLight, BorderSizePixel = 0, Parent = panel }, { Theme.corner(4) })
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Gold, BorderSizePixel = 0, Parent = track }, { Theme.corner(4) })
	local function update()
		local level = player:GetAttribute("Level") or 1
		local points = player:GetAttribute("StatPoints") or 0
		text.Text = ("⭐ Nv %d%s"):format(level, if points > 0 then " +" else "")
		local ratio = (player:GetAttribute("Xp") or 0) / math.max(player:GetAttribute("XpNext") or 1, 1)
		TweenService:Create(fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1) }):Play()
	end
	for _, attribute in { "Level", "Xp", "XpNext", "StatPoints" } do
		player:GetAttributeChangedSignal(attribute):Connect(update)
	end
	update()
end

local function openSheet()
	local window, content = Dialog.window("CharacterSheet", "⭐ Tu personaje", Vector2.new(470, 470))
	local list = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local header = Theme.label({ Size = UDim2.new(1, 0, 0, 44), TextSize = 15, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 0, Parent = list })
	local rows = {}
	for i, stat in P.Stats do
		local row = Theme.panel({ Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0, LayoutOrder = i, Parent = list })
		Theme.padding(8).Parent = row
		local name = Theme.label({ Size = UDim2.new(1, -120, 0, 22), Font = Theme.FontBold, TextSize = 17, Parent = row })
		Theme.label({ Size = UDim2.new(1, -120, 0, 18), Position = UDim2.fromOffset(0, 22), Text = stat.Text, TextSize = 12, TextColor3 = C.Muted, Parent = row })
		local plus = Theme.button({ AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(44, 36), Position = UDim2.fromScale(1, 0.5), Text = "+", TextSize = 24, Parent = row })
		plus.Activated:Connect(function()
			Remote:FireServer("Spend", stat.Id)
		end)
		rows[stat.Id] = { Name = name, Plus = plus, Stat = stat }
	end
	local function refresh()
		if not window.Parent then
			return
		end
		local points = player:GetAttribute("StatPoints") or 0
		header.Text = ("Nivel %d · %d / %d XP para el siguiente\nPuntos para repartir: %d  (cada nivel da %d)"):format(
			player:GetAttribute("Level") or 1, player:GetAttribute("Xp") or 0, player:GetAttribute("XpNext") or 100, points, P.PointsPerLevel)
		for id, row in rows do
			local value = player:GetAttribute("Stat_" .. id) or 0
			row.Name.Text = ("%s  %s  ·  %d"):format(row.Stat.Icon, row.Stat.Name, value)
			local can = points > 0 and value < P.MaxStat
			row.Plus.BackgroundColor3 = if can then rgb(0, 150, 80) else C.PanelLight
			row.Plus.AutoButtonColor = can
		end
	end
	local connections = {}
	for _, attribute in { "StatPoints", "Level", "Xp", "XpNext", "Stat_Salud", "Stat_Resistencia", "Stat_Fuerza", "Stat_Destreza", "Stat_Suerte" } do
		table.insert(connections, player:GetAttributeChangedSignal(attribute):Connect(refresh))
	end
	window.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	refresh()
end

---------------------------------------------------------------------
-- Correr
---------------------------------------------------------------------
local wants = false
local function setSprint(on: boolean)
	if wants ~= on then
		wants = on
		Remote:FireServer("Sprint", on)
	end
end

function Character.init()
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("MainHud")
	buildVitals(gui)
	buildLevel(gui)
	Hud.addButton("⭐ Personaje", rgb(150, 110, 20), 4, openSheet)

	-- Teclado: mantener Shift. Mando: pulsar el stick izquierdo.
	ContextActionService:BindAction("Sprint", function(_, state)
		if state == Enum.UserInputState.Begin then
			setSprint(true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			setSprint(false)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)

	-- Móvil: botón redondo que se enciende y se apaga
	if UserInputService.TouchEnabled then
		local button = Theme.button({
			Name = "SprintButton",
			AnchorPoint = Vector2.new(1, 1),
			Size = UDim2.fromOffset(70, 70),
			Position = UDim2.new(1, -190, 1, -40),
			Text = "🏃",
			TextSize = 30,
			BackgroundTransparency = 0.3,
			Parent = gui,
		})
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0.5, 0)
		end
		button.Activated:Connect(function()
			setSprint(not wants)
			button.BackgroundColor3 = if wants then rgb(0, 150, 80) else C.PanelLight
		end)
		player:GetAttributeChangedSignal("Stamina"):Connect(function()
			if wants and (player:GetAttribute("Stamina") or 0) <= 0 then
				setSprint(false)
				button.BackgroundColor3 = C.PanelLight
			end
		end)
	end
end

return Character
