-- Character: ficha del personaje y correr.
--   (La vida, la estamina, el nivel y la experiencia los dibuja el HUD: UI/Hud.luau)
--   * Botón "⭐ Personaje" de arriba: reparte los puntos de cada nivel en Salud, Resistencia, Fuerza, Destreza y Suerte
--   * Correr: mantén Shift (en móvil, el botón 🏃) mientras te quede estamina

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	Hud.setAction("Personaje", openSheet)

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
			Position = UDim2.new(1, -24, 1, -96), -- encima del cartel de "dónde estás"
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
