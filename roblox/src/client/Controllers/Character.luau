-- Character: ficha del personaje y correr.
--   (La vida, la estamina, el nivel y la experiencia los dibuja el HUD: UI/Hud.luau)
--   * Botón "⭐ Personaje" de arriba: reparte los puntos de cada nivel en Salud, Resistencia, Fuerza, Destreza y Suerte
--   * Correr: mantén Shift (L3 en el mando; en móvil, el botón 🏃 o el joystick hasta el borde)
--     mientras te quede estamina

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Pantalla táctil sin teclado (móvil o tableta)
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)

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
-- Correr (lo decide el servidor: ProgressionService pone "Sprinting" y NeedsService la velocidad)
--   Teclado: mantener Shift.
--   Mando:   pulsar el stick izquierdo (L3) enciende y apaga; se apaga solo al pararte.
--   Móvil:   el botón 🏃 enciende y apaga; y, con "AutoRun" (atributo del jugador, sí por defecto),
--            empujar el joystick hasta el borde un momento también corre (al soltarlo un poco, anda).
--   El botón 🏃 enseña el estado: gris apagado, ámbar pedido (pero quieto o sin aliento), verde
--   corriendo, y abajo una barrita con la estamina.
---------------------------------------------------------------------
local wants = false
local held = false -- Shift mantenido
local toggled = false -- botón 🏃 o L3
local toggledByPad = false
local auto = false -- joystick empujado hasta el borde
local refreshButton: () -> () = function() end

local function sync()
	local on = held or toggled or auto
	if wants ~= on then
		wants = on
		Remote:FireServer("Sprint", on)
	end
	refreshButton()
end

-- (para un ajuste del menú) correr al empujar el joystick hasta el borde
function Character.setAutoRun(on: boolean)
	player:SetAttribute("AutoRun", on)
	if not on and auto then
		auto = false
		sync()
	end
end

local function controlModule(): any
	local ok, controls = pcall(function()
		local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 30) :: any)
		return module:GetControls()
	end)
	return if ok then controls else nil
end

function Character.init()
	Hud.setAction("Personaje", openSheet)

	ContextActionService:BindAction("Sprint", function(_, state)
		if state == Enum.UserInputState.Begin then
			held = true
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			held = false
		end
		sync()
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
	ContextActionService:BindAction("SprintPad", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggled = not toggled
			toggledByPad = toggled
			sync()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.ButtonL3)

	-- Sin aliento: se apaga lo encendido con botón (Shift se suelta solo)
	player:GetAttributeChangedSignal("Stamina"):Connect(function()
		if (toggled or auto) and (player:GetAttribute("Stamina") or 0) <= 0 then
			toggled, auto = false, false
			sync()
		end
		refreshButton()
	end)
	player:GetAttributeChangedSignal("Sprinting"):Connect(function()
		refreshButton()
	end)
	player.CharacterAdded:Connect(function()
		held, toggled, auto = false, false, false
		sync()
	end)

	-- Mando: al pararte un rato se deja de correr (como en casi todos los juegos)
	local stillFor = 0
	local controls: any = nil
	task.spawn(function()
		controls = controlModule()
	end)
	local edgeSince: number? = nil
	RunService.Heartbeat:Connect(function(dt)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
		if toggled and toggledByPad then
			stillFor = if moving then 0 else stillFor + dt
			if stillFor > 1 then
				toggled, toggledByPad = false, false
				sync()
			end
		end
		-- Móvil: joystick hasta el borde → corre
		if not TOUCH or not controls then
			return
		end
		local ok, vector = pcall(function()
			return controls:GetMoveVector()
		end)
		local push = if ok and typeof(vector) == "Vector3" then vector.Magnitude else 0
		local allowed = player:GetAttribute("AutoRun") ~= false and player:GetAttribute("LifeStage") ~= "Bebe" and player:GetAttribute("Riding") == nil
		if allowed and push >= 0.97 then
			edgeSince = edgeSince or os.clock()
			if not auto and os.clock() - edgeSince > 0.35 and (player:GetAttribute("Stamina") or 100) > 0 then
				auto = true
				sync()
			end
		else
			edgeSince = nil
			if auto and (not allowed or push < 0.75) then
				auto = false
				sync()
			end
		end
	end)

	-- Móvil: botón redondo que se enciende y se apaga
	-- (en su propia pantalla, sin la escala del HUD: así tiene el mismo tamaño que el botón de saltar)
	if UserInputService.TouchEnabled then
		-- (DisplayOrder alto: ningún panel del HUD puede quedar encima y quitarle los toques)
		local gui = Theme.create("ScreenGui", { Name = "SprintGui", ResetOnSpawn = false, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
		local button = Theme.button({
			Name = "SprintButton",
			Size = UDim2.fromOffset(56, 56),
			Text = "🏃",
			TextSize = 28,
			BackgroundTransparency = 0.3,
			Parent = gui,
		})
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0.5, 0)
		end
		-- Barrita de estamina dentro del botón
		local track = Theme.create("Frame", {
			Name = "Stamina",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(0.6, 0, 0, 4),
			BackgroundColor3 = rgb(12, 18, 32),
			BorderSizePixel = 0,
			Parent = button,
		}, { Theme.corner(2) })
		local fill = Theme.create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(110, 170, 255), BorderSizePixel = 0, Parent = track }, { Theme.corner(2) })
		refreshButton = function()
			local running = player:GetAttribute("Sprinting") == true
			local color = if running then rgb(0, 150, 80) elseif wants then rgb(190, 140, 30) else C.PanelLight
			TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = color }):Play()
			local max = player:GetAttribute("MaxStamina") or Gameplay.Progression.Stamina.Base
			local ratio = math.clamp((player:GetAttribute("Stamina") or max) / math.max(max, 1), 0, 1)
			TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(ratio, 1) }):Play()
			fill.BackgroundColor3 = if ratio < 0.2 then rgb(230, 80, 60) else rgb(110, 170, 255)
			track.Visible = ratio < 0.999 or running
		end
		TouchLayout.place(button, "Correr")
		TouchLayout.showWhen(button, "Pie")
		button.Activated:Connect(function()
			toggled = not toggled
			toggledByPad = false
			if not toggled then
				auto = false
			end
			sync()
		end)
		refreshButton()
	end
end

return Character
