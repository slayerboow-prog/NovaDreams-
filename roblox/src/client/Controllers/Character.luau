-- Character: ficha del personaje y correr.
--   (La vida, la estamina, el nivel y la experiencia los dibuja el HUD: UI/Hud.luau)
--   * Botón "⭐ Personaje" de arriba: reparte los puntos de cada nivel en Salud, Resistencia, Fuerza, Destreza y Suerte
--     (y abajo, tu historial de comportamiento 😇/😈: ConductService)
--   * Correr: mantén Shift (L3 en el mando; en móvil, el botón Correr o el joystick hasta el borde)
--     mientras te quede estamina

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Pantalla táctil sin teclado (móvil o tableta)
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Gym = require(ReplicatedStorage.Shared.Gym)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local Joystick = require(script.Parent.Joystick)

local create = Theme.create
local C = Theme.Colors

local Character = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Progression") :: RemoteEvent
local P = Gameplay.Progression
local rgb = Color3.fromRGB

local function openSheet()
	local window, content = Dialog.window("CharacterSheet", "⭐ Tu personaje", Vector2.new(470, 670))
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
	-- Gimnasio: la Fuerza que se nota en el cuerpo y la Forma física (GymService)
	local gym = Theme.panel({ Size = UDim2.new(1, 0, 0, 104), BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0, LayoutOrder = 100, Parent = list })
	Theme.padding(8).Parent = gym
	local gymBars = {}
	for i, id in { "GymStrength", "GymCardio" } do
		local y = (i - 1) * 40
		local label = Theme.label({ Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 22), Font = Theme.FontBold, TextSize = 16, Parent = gym })
		local track = create("Frame", { Position = UDim2.fromOffset(0, y + 24), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = rgb(12, 18, 32), BorderSizePixel = 0, Parent = gym }, { Theme.corner(4) })
		local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = if i == 1 then rgb(240, 140, 40) else rgb(90, 190, 230), BorderSizePixel = 0, Parent = track }, { Theme.corner(4) })
		gymBars[id] = { Label = label, Fill = fill }
	end
	local gymNote = Theme.label({ Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 16), TextSize = 12, TextColor3 = C.Muted, Parent = gym })
	-- Historial de comportamiento (😇 / 😈): ConductService
	local conduct = Theme.panel({ Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = C.PanelLight, BackgroundTransparency = 0, LayoutOrder = 101, Parent = list })
	Theme.padding(8).Parent = conduct
	local conductTitle = Theme.label({ Size = UDim2.new(1, 0, 0, 22), Font = Theme.FontBold, TextSize = 16, Parent = conduct })
	local conductNote = Theme.label({ Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 30), TextSize = 12, TextWrapped = true, TextColor3 = C.Muted, TextYAlignment = Enum.TextYAlignment.Top, Parent = conduct })
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
		local strength = player:GetAttribute("GymStrength") or 0
		local cardio = player:GetAttribute("GymCardio") or 0
		gymBars.GymStrength.Label.Text = ("💪 Fuerza  ·  %d / 100  ·  %s"):format(math.floor(strength), Gym.level(strength))
		gymBars.GymCardio.Label.Text = ("🏃 Forma física  ·  %d / 100  ·  %s"):format(math.floor(cardio), Gym.level(cardio))
		gymBars.GymStrength.Fill.Size = UDim2.fromScale(math.clamp(strength / Gym.MaxStat, 0, 1), 1)
		gymBars.GymCardio.Fill.Size = UDim2.fromScale(math.clamp(cardio / Gym.MaxStat, 0, 1), 1)
		local days = player:GetAttribute("GymPassDays") or 0
		local level = player:GetAttribute("ConductLevel")
		local conductPoints = player:GetAttribute("Conduct") or 0
		conductTitle.Text = ("%s  ·  %d punto%s"):format(if typeof(level) == "string" then level else "😇 Un angelito", conductPoints, if conductPoints == 1 then "" else "s")
		local notes = {}
		local last = player:GetAttribute("ConductLast")
		if typeof(last) == "string" then
			table.insert(notes, "Lo último: " .. last)
		end
		local records = player:GetAttribute("Records") or 0
		if records > 0 then
			table.insert(notes, ("Antecedentes: %d"):format(records))
		end
		local grounded = player:GetAttribute("GroundedUntil")
		if typeof(grounded) == "number" and grounded > os.time() then
			table.insert(notes, ("🏠 Castigado/a %d min: sin paga"):format(math.ceil((grounded - os.time()) / 60)))
		end
		conductNote.Text = if #notes > 0 then table.concat(notes, "  ·  ") else "Pórtate bien: lo que hagas mal lo sabrá tu familia (y la policía)."
		gymNote.Text = if days > 0 then ("🏋️ Gimnasio: te queda%s %d día%s de entrada · entrena para ponerte fuerte"):format(if days == 1 then "" else "n", days, if days == 1 then "" else "s")
			else "🏋️ Entrena en el gimnasio (💪 en el mapa): la Fuerza se nota en el cuerpo"
	end
	local connections = {}
	for _, attribute in { "StatPoints", "Level", "Xp", "XpNext", "Stat_Salud", "Stat_Resistencia", "Stat_Fuerza", "Stat_Destreza", "Stat_Suerte", "GymStrength", "GymCardio", "GymPassDays", "Conduct", "ConductLevel", "ConductLast", "GroundedUntil", "Records" } do
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
--   Móvil:   el botón Correr (UI/TouchLayout) enciende y apaga; y, con "AutoRun" (atributo del jugador,
--            sí por defecto; se cambia en el Menú), empujar el joystick hasta el borde un momento
--            también corre (al soltarlo un poco, anda).
--   El botón enseña el estado: apagado, ámbar pedido (pero quieto o sin aliento), azul corriendo,
--   y abajo una barrita con la estamina.
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
		if on then
			-- Agachado o tumbado: correr te levanta (si hay sitio encima)
			pcall(function()
				require(script.Parent.Stances).standUp()
			end)
		end
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
		if not TOUCH or not (controls or Joystick.active()) then
			return
		end
		local push = 0
		if Joystick.active() then
			-- Joystick propio (UI del HUD): lo lejos que llevas el pomo
			push = Joystick.push()
		else
			local ok, vector = pcall(function()
				return controls:GetMoveVector()
			end)
			push = if ok and typeof(vector) == "Vector3" then vector.Magnitude else 0
		end
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

	-- Móvil: botón Correr del racimo (enciende y apaga, con la estamina); en el ordenador, en las pistas
	local function seated(): boolean
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.SeatPart ~= nil
	end
	TouchLayout.register({
		Id = "Correr",
		Icon = "correr",
		Label = "Correr",
		Slot = "Correr",
		Priority = 4.5,
		Key = "Mayús",
		Pad = "L3",
		Visible = function()
			return player:GetAttribute("LifeStage") ~= "Bebe" and not seated() and not TouchLayout.riding()
		end,
		Active = function(): any
			if player:GetAttribute("Sprinting") == true then
				return true
			end
			return if wants then "wait" else false
		end,
		Meter = function(): number?
			local max = player:GetAttribute("MaxStamina") or Gameplay.Progression.Stamina.Base
			local ratio = math.clamp((player:GetAttribute("Stamina") or max) / math.max(max, 1), 0, 1)
			return if ratio < 0.999 or wants then ratio else nil
		end,
		Callback = function()
			toggled = not toggled
			toggledByPad = false
			if not toggled then
				auto = false
			end
			sync()
		end,
	})
	refreshButton = function()
		TouchLayout.refresh()
	end
end

return Character
