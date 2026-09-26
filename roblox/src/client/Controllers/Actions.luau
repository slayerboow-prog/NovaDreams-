-- Actions (cliente): movimientos y acciones nuevas del personaje.
--   * Gestos y bailes (tecla G, app "😀 Gestos" del teléfono o botón 😀 en móvil):
--     saludar, señalar, animar, reír, tres bailes, saludo militar y "no sé".
--     Se cortan solos al andar o saltar.
--   * Trepar: salta contra un muro bajo, una valla o un coche (hasta unos 9 studs) y el
--     personaje se agarra al borde y sube.
--   * Linterna (tecla L): la ven todos los jugadores. La primera noche sale un aviso.
--   * Modo foto (tecla P): esconde toda la interfaz para hacer capturas bonitas.
-- (Sentarse en bancos y marquesinas: cartel "Sentarse" del servidor, ActionService)
-- Las animaciones son las de Roblox que trae cualquier personaje: las del propio personaje
-- las ven también los demás jugadores.

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Hud = require(script.Parent.Parent.UI.Hud)
local Cinematics = require(script.Parent.Cinematics)
local SoundFx = require(script.Parent.SoundFx)
local StreetVoices = require(ReplicatedStorage.Shared.Config).StreetVoices

local Actions = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Actions") :: RemoteEvent
local C = Theme.Colors
local rgb = Color3.fromRGB

local function asset(id: number): string
	return "rbxassetid://" .. id
end

-- Gestos: animación para R15 y para R6 (nil = ese tipo de personaje no la tiene)
type Emote = { Name: string, Icon: string, R15: number, R6: number?, Loop: boolean?, Voice: string? }
local EMOTES: { Emote } = {
	{ Name = "Saludar", Icon = "👋", R15 = 507770239, R6 = 128777973, Voice = "Saludar" },
	{ Name = "Señalar", Icon = "👉", R15 = 507770453, R6 = 128853357, Voice = "Senalar" },
	{ Name = "Animar", Icon = "🙌", R15 = 507770677, R6 = 129423030, Voice = "Animar" },
	{ Name = "Reír", Icon = "😂", R15 = 507770818, R6 = 129423131, Voice = "Reir" },
	{ Name = "Baile 1", Icon = "💃", R15 = 507771019, R6 = 182435998, Loop = true },
	{ Name = "Baile 2", Icon = "🕺", R15 = 507776043, R6 = 182436842, Loop = true },
	{ Name = "Baile 3", Icon = "🪩", R15 = 507777268, R6 = 182436935, Loop = true },
	{ Name = "Saludo militar", Icon = "🫡", R15 = 3333474484 },
	{ Name = "No sé", Icon = "🤷", R15 = 3334392772, Voice = "NoSe" },
}
local CLIMB = { R15 = 507765644, R6 = 180436334 }

---------------------------------------------------------------------
-- Personaje y animaciones
---------------------------------------------------------------------
local tracks: { [string]: AnimationTrack } = {}
local playing: AnimationTrack? = nil

local function parts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isR15(humanoid: Humanoid): boolean
	return humanoid.RigType == Enum.HumanoidRigType.R15
end

local function load(humanoid: Humanoid, id: number, looped: boolean?): AnimationTrack?
	local key = tostring(id)
	if tracks[key] then
		return tracks[key]
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = asset(id)
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		return nil
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = looped == true
	tracks[key] = track
	return track
end

local function stopEmote()
	if playing then
		playing:Stop(0.25)
		playing = nil
	end
end

local function busy(): boolean
	return Cinematics.isPlaying() or player:GetAttribute("InDialogue") == true
end

local function playEmote(emote: Emote)
	local humanoid = parts()
	if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart or busy() then
		return
	end
	local id = if isR15(humanoid) then emote.R15 else emote.R6
	if not id then
		Hud.toast("Info", "Este gesto no está disponible para tu tipo de personaje")
		return
	end
	stopEmote()
	local track = load(humanoid, id, emote.Loop)
	if track then
		track:Play(0.2)
		playing = track
	end
	local line = emote.Voice and StreetVoices.Emotes[emote.Voice]
	if line then
		SoundFx.voice(line, 1.05)
	end
end

---------------------------------------------------------------------
-- Panel de gestos
---------------------------------------------------------------------
local panel: Frame? = nil

local function buildPanel(gui: ScreenGui): Frame
	local frame = Theme.panel({
		Name = "Gestos",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(5 * 78 + 4 * 6 + 20, 2 * 70 + 6 + 20 + 26),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(10).Parent = frame
	Theme.label({ Size = UDim2.new(1, -30, 0, 20), Text = "😀 Gestos  ·  G para cerrar", Font = Theme.FontBold, TextSize = 15, Parent = frame })
	local close = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(24, 20), Text = "✕", TextSize = 14, Parent = frame })
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	local grid = Theme.create("Frame", { Size = UDim2.new(1, 0, 1, -26), Position = UDim2.fromOffset(0, 26), BackgroundTransparency = 1, Parent = frame })
	Theme.create("UIGridLayout", { CellSize = UDim2.fromOffset(78, 70), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for i, emote in EMOTES do
		local button = Theme.button({ Text = "", LayoutOrder = i, BackgroundColor3 = C.PanelLight, Parent = grid })
		Theme.label({ Size = UDim2.new(1, 0, 0, 38), Text = emote.Icon, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Parent = button })
		Theme.label({ Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 40), Text = emote.Name, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, TextScaled = false, Parent = button })
		button.Activated:Connect(function()
			playEmote(emote)
			frame.Visible = false
		end)
	end
	return frame
end

local function togglePanel()
	if panel and not busy() then
		panel.Visible = not panel.Visible
	end
end

---------------------------------------------------------------------
-- Trepar muros bajos
---------------------------------------------------------------------
local climbing = false
local lastClimb = 0

local function tryClimb(humanoid: Humanoid, root: BasePart)
	if climbing or os.clock() - lastClimb < 0.8 or humanoid.SeatPart then
		return
	end
	local state = humanoid:GetState()
	if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
		return
	end
	local move = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	if move.Magnitude < 0.5 then
		return
	end
	local dir = move.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	params.IgnoreWater = true
	params.RespectCanCollide = true -- hojas, carteles y adornos no cuentan
	-- 1) ¿Hay una pared justo delante?
	local wall = workspace:Raycast(root.Position, dir * 2.6, params)
	if not wall or math.abs(wall.Normal.Y) > 0.3 then
		return
	end
	local model = wall.Instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return -- no se trepa por encima de otras personas
	end
	-- 2) ¿Dónde está el borde de arriba? (se mira desde arriba, un poco detrás de la pared)
	local feet = root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
	local probe = Vector3.new(wall.Position.X, feet + 10, wall.Position.Z) + dir * 1.4
	-- (si el muro es más alto de lo que se alcanza, esta línea choca con él: no se trepa)
	local over = Vector3.new(root.Position.X, probe.Y, root.Position.Z)
	if workspace:Raycast(over, Vector3.new(probe.X, probe.Y, probe.Z) - over, params) then
		return
	end
	local top = workspace:Raycast(probe, Vector3.new(0, -10, 0), params)
	if not top or top.Normal.Y < 0.75 then
		return
	end
	local rise = top.Position.Y - feet
	if rise < 2.2 or rise > 9.5 then
		return
	end
	-- 3) ¿Cabe el personaje encima?
	if workspace:Raycast(top.Position + Vector3.new(0, 0.3, 0), Vector3.new(0, 5.5, 0), params) then
		return
	end
	climbing = true
	lastClimb = os.clock()
	SoundFx.play("Trepar", 1, nil, root)
	local track = load(humanoid, if isR15(humanoid) then CLIMB.R15 else CLIMB.R6)
	if track then
		track:Play(0.1, 1, 1.6)
	end
	local from = root.CFrame
	local look = CFrame.lookAlong(Vector3.zero, dir)
	local target = CFrame.new(top.Position + dir * 0.8 + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.1, 0)) * look.Rotation
	-- Primero sube (hasta la altura del borde) y luego avanza encima
	local lift = CFrame.new(from.Position.X, target.Position.Y, from.Position.Z) * look.Rotation
	local duration = 0.18 + rise * 0.035
	local start = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		if t < 0.65 then
			root.CFrame = from:Lerp(lift, t / 0.65)
		else
			root.CFrame = lift:Lerp(target, (t - 0.65) / 0.35)
		end
		root.AssemblyLinearVelocity = Vector3.zero
		if t >= 1 then
			connection:Disconnect()
			if track then
				track:Stop(0.2)
			end
			humanoid:ChangeState(Enum.HumanoidStateType.Landed)
			climbing = false
		end
	end)
end

---------------------------------------------------------------------
-- Linterna
---------------------------------------------------------------------
local function toggleFlashlight()
	if busy() then
		return
	end
	local on = not (player:GetAttribute("Flashlight") == true)
	Remote:FireServer("Flashlight", on)
	Hud.toast("Info", if on then "🔦 Linterna encendida (L para apagar)" else "🔦 Linterna apagada")
end

---------------------------------------------------------------------
-- Modo foto
---------------------------------------------------------------------
local photo = false
local hidden: { ScreenGui } = {}
local savedZoom = 0

local function setPhoto(on: boolean)
	if on == photo or (on and busy()) then
		return
	end
	photo = on
	local playerGui = player:WaitForChild("PlayerGui")
	if on then
		hidden = {}
		for _, gui in playerGui:GetChildren() do
			if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "PhotoHint" and gui.Name ~= "PhotoExit" then
				gui.Enabled = false
				table.insert(hidden, gui)
			end
		end
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
		savedZoom = player.CameraMaxZoomDistance
		player.CameraMaxZoomDistance = math.max(savedZoom, 140)
		-- Aviso que se desvanece (para que la foto quede limpia)
		local hint = Theme.create("ScreenGui", { Name = "PhotoHint", ResetOnSpawn = false, Parent = playerGui })
		local label = Theme.label({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 20),
			Size = UDim2.fromOffset(360, 34),
			Text = if UserInputService.TouchEnabled then "📸 Modo foto  ·  toca ✖ para volver" else "📸 Modo foto  ·  pulsa P para volver",
			TextSize = 16,
			Font = Theme.FontBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextStrokeTransparency = 0.5,
			Parent = hint,
		})
		-- Móvil: botón pequeño para salir (no hay tecla P)
		if UserInputService.TouchEnabled then
			local exitGui = Theme.create("ScreenGui", { Name = "PhotoExit", ResetOnSpawn = false, Parent = playerGui })
			local exit = Theme.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(44, 44), Text = "✖", TextSize = 22, BackgroundTransparency = 0.5, Parent = exitGui })
			exit.Activated:Connect(function()
				setPhoto(false)
			end)
		end
		task.delay(2.5, function()
			TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			task.wait(0.9)
			hint:Destroy()
		end)
	else
		local exitGui = playerGui:FindFirstChild("PhotoExit")
		if exitGui then
			exitGui:Destroy()
		end
		for _, gui in hidden do
			if gui.Parent then
				gui.Enabled = true
			end
		end
		hidden = {}
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		player.CameraMaxZoomDistance = savedZoom
	end
end

---------------------------------------------------------------------
function Actions.init()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Theme.create("ScreenGui", { Name = "ActionsGui", ResetOnSpawn = false, Parent = playerGui })
	panel = buildPanel(gui)

	Hud.addButton("😀 Gestos", rgb(200, 120, 40), 4, togglePanel)

	local function bind(name: string, callback: () -> (), ...: Enum.KeyCode)
		ContextActionService:BindAction(name, function(_, state)
			if state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then
				callback()
			end
			return Enum.ContextActionResult.Pass
		end, false, ...)
	end
	bind("Gestures", togglePanel, Enum.KeyCode.G)
	bind("Flashlight", toggleFlashlight, Enum.KeyCode.L)
	bind("PhotoMode", function()
		setPhoto(not photo)
	end, Enum.KeyCode.P)

	-- Móvil: botón redondo de gestos junto al de correr
	if UserInputService.TouchEnabled then
		local button = Theme.button({
			Name = "GesturesButton",
			AnchorPoint = Vector2.new(1, 1),
			Size = UDim2.fromOffset(56, 56),
			Position = UDim2.new(1, -252, 1, -28),
			Text = "😀",
			TextSize = 26,
			BackgroundTransparency = 0.3,
			Parent = gui,
		})
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0.5, 0)
		end
		button.Activated:Connect(togglePanel)
		-- Linterna y modo foto (en el teclado son L y P), encima del de gestos
		local function round(name: string, icon: string, position: UDim2, callback: () -> ())
			local b = Theme.button({
				Name = name,
				AnchorPoint = Vector2.new(1, 1),
				Size = UDim2.fromOffset(48, 48),
				Position = position,
				Text = icon,
				TextSize = 22,
				BackgroundTransparency = 0.3,
				Parent = gui,
			})
			local c = b:FindFirstChildOfClass("UICorner")
			if c then
				c.CornerRadius = UDim.new(0.5, 0)
			end
			b.Activated:Connect(callback)
		end
		round("FlashlightButton", "🔦", UDim2.new(1, -256, 1, -92), toggleFlashlight)
		round("PhotoButton", "📷", UDim2.new(1, -204, 1, -100), function()
			setPhoto(not photo)
		end)
	end

	-- Cada personaje nuevo empieza sin animaciones cargadas
	player.CharacterAdded:Connect(function()
		tracks = {}
		playing = nil
		climbing = false
	end)

	-- La primera noche: aviso de la linterna
	local warned = false
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		local clock = Lighting.ClockTime
		if not warned and (clock >= 20.5 or clock < 5) and not busy() and player:GetAttribute("LifeStage") ~= "Bebe" then
			warned = true
			Hud.toast("Info", if UserInputService.TouchEnabled then "🌙 Es de noche: toca 🔦 para encender la linterna" else "🌙 Es de noche: pulsa L para encender la linterna")
		end
	end)

	RunService.Heartbeat:Connect(function()
		local humanoid, root = parts()
		if not humanoid or not root or humanoid.Health <= 0 then
			return
		end
		-- Los gestos se cortan al moverse, saltar o sentarse
		if playing and (humanoid.MoveDirection.Magnitude > 0.1 or humanoid.Jump or humanoid.SeatPart) then
			stopEmote()
		end
		if busy() then
			if panel then
				panel.Visible = false
			end
			stopEmote()
			setPhoto(false)
			return
		end
		if player:GetAttribute("LifeStage") ~= "Bebe" then
			tryClimb(humanoid, root)
		end
	end)
end

return Actions
