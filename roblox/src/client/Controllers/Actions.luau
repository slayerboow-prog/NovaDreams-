-- Actions (cliente): movimientos y acciones nuevas del personaje.
--   * Gestos: los de Roblox (su menú de gestos: botón Gestos, app Gestos o comando Más > Gestos).
--     Aquí queda "Saludar" para el menú de comandos (delante de alguien); se corta al andar o saltar.
--   * Trepar y saltar vallas: ahora lo hace Controllers/Parkour (saltar vallas, muros, bordes…).
--   * Linterna (tecla L, R3 en el mando): la ven todos los jugadores (y el brazo va delante,
--     sujetándola: ReactMotion). La primera noche sale un aviso.
--   * Modo foto (tecla P, LT en el mando): esconde toda la interfaz para hacer capturas bonitas
--     (con un fundido corto al entrar y al salir).
-- (Sentarse en bancos y marquesinas: cartel "Sentarse" del servidor, ActionService)
-- Las animaciones son las de Roblox que trae cualquier personaje: las del propio personaje
-- las ven también los demás jugadores. Todas entran y salen con fundido (nada de saltos de postura).

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
local FootCamera = require(script.Parent.FootCamera)
local SoundFx = require(script.Parent.SoundFx)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local Vehicles = require(script.Parent.Vehicles)
local StreetVoices = require(ReplicatedStorage.Shared.Config).StreetVoices

local Actions = {}

-- Levantarse de cualquier asiento (o bajarse del vehículo). Si el servidor no te baja en un
-- momento, se fuerza aquí: nunca te quedas sentado sin poder hacer nada.
function Actions.standUp()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	-- En un vehículo (conduciendo, de pasajero o sentado en él aunque el servidor no lo sepa):
	-- Controllers/Vehicles te baja a la primera, de pie junto a tu puerta y sin volver a sentarte
	if Vehicles.inVehicle() then
		Vehicles.exit()
		return
	end
	humanoid.Sit = false
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	task.delay(0.6, function()
		if humanoid.Parent and (humanoid.SeatPart or humanoid.Sit) then
			local seat = humanoid.SeatPart
			local weld = seat and seat:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
			humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Actions") :: RemoteEvent

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
	{ Name = "Baile 3", Icon = "🕺", R15 = 507777268, R6 = 182436935, Loop = true },
	{ Name = "Saludo militar", Icon = "🙋", R15 = 3333474484 },
	{ Name = "No sé", Icon = "🤷", R15 = 3334392772, Voice = "NoSe" },
}

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
		playing:Stop(0.35)
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
		track:Play(0.3)
		playing = track
	end
	local line = emote.Voice and StreetVoices.Emotes[emote.Voice]
	if line then
		SoundFx.voice(line, 1.05)
	end
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

-- Fundido corto (como el obturador de una cámara) al entrar y salir del modo foto
local function shutter(playerGui: Instance)
	local gui = Theme.create("ScreenGui", { Name = "PhotoShutter", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20, Parent = playerGui })
	local shade = Theme.create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = gui })
	TweenService:Create(shade, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	task.delay(0.35, function()
		gui:Destroy()
	end)
end

local function setPhoto(on: boolean)
	if on == photo or (on and busy()) then
		return
	end
	photo = on
	local playerGui = player:WaitForChild("PlayerGui")
	if on then
		hidden = {}
		for _, gui in playerGui:GetChildren() do
			if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "PhotoHint" and gui.Name ~= "PhotoExit" and gui.Name ~= "PhotoShutter" then
				gui.Enabled = false
				table.insert(hidden, gui)
			end
		end
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		end)
		FootCamera.setPhoto(true) -- la cámara se puede alejar mucho más
		shutter(playerGui)
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
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		end)
		FootCamera.setPhoto(false)
		shutter(playerGui)
	end
end

---------------------------------------------------------------------
-- Para el menú de comandos: hacer un gesto por su nombre (Saludar)
function Actions.emote(name: string)
	for _, emote in EMOTES do
		if emote.Name == name then
			playEmote(emote)
			return
		end
	end
end
-- Abre (o cierra) el menú de gestos y bailes de Roblox
function Actions.openEmotes()
	pcall(function()
		local GuiService = game:GetService("GuiService")
		GuiService:SetEmotesMenuOpen(not GuiService:GetEmotesMenuOpen())
	end)
end

function Actions.emotes(): { { Name: string, Icon: string } }
	local list = {}
	for _, emote in EMOTES do
		table.insert(list, { Name = emote.Name, Icon = emote.Icon })
	end
	return list
end

-- ¿Hay techo encima? (dentro de casa o en un túnel: la linterna sirve también de día)
local lastRoofCheck, lastRoof = 0, false
local function underRoof(): boolean
	if os.clock() - lastRoofCheck < 1 then
		return lastRoof
	end
	lastRoofCheck = os.clock()
	local _, root = parts()
	if not root then
		lastRoof = false
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	lastRoof = workspace:Raycast(root.Position, Vector3.new(0, 40, 0), params) ~= nil
	return lastRoof
end

function Actions.init()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Theme.create("ScreenGui", { Name = "ActionsGui", ResetOnSpawn = false, Parent = playerGui })
	local function bind(name: string, callback: () -> (), ...: Enum.KeyCode)
		ContextActionService:BindAction(name, function(_, state)
			if state == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then
				callback()
			end
			return Enum.ContextActionResult.Pass
		end, false, ...)
	end
	bind("Flashlight", toggleFlashlight, Enum.KeyCode.L, Enum.KeyCode.ButtonR3)
	bind("PhotoMode", function()
		setPhoto(not photo)
	end, Enum.KeyCode.P)
	-- Mando: LT, solo a pie y con las manos libres (nadando LT es bajar; conduciendo, frenar; con
	-- un arma, apuntar). (Select no sirve: Roblox lo usa para moverse por los menús con el mando)
	bind("PhotoModePad", function()
		local humanoid = parts()
		if not humanoid or humanoid.SeatPart or player:GetAttribute("Riding") ~= nil or player:GetAttribute("Weapon") ~= nil then
			return
		end
		if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
			setPhoto(not photo)
		end
	end, Enum.KeyCode.ButtonL2)

	-- Botones del racimo (móvil) y pistas de teclas (ordenador y mando): a pie
	local function onFoot(): boolean
		return player:GetAttribute("LifeStage") ~= "Bebe" and not busy() and not TouchLayout.riding()
	end
	TouchLayout.register({ Id = "Gestos", Icon = "gestos", Label = "Gestos", Slot = "Gestos", Priority = 7, Visible = onFoot, Callback = Actions.openEmotes })
	-- Linterna: de noche o bajo techo (o si ya la llevas encendida, para poder apagarla)
	TouchLayout.register({
		Id = "Linterna", Icon = "linterna", Label = "Linterna", Priority = 20, Key = "L", Pad = "R3",
		Visible = function()
			local clock = Lighting.ClockTime
			local on = player:GetAttribute("Flashlight") == true
			return onFoot() and (on or clock >= 19.5 or clock < 6.5 or underRoof())
		end,
		Active = function()
			return player:GetAttribute("Flashlight") == true
		end,
		Callback = toggleFlashlight,
	})
	TouchLayout.register({
		Id = "Foto", Icon = "camara", Label = "Foto", Priority = 40, Key = "P", Pad = "LT",
		Visible = onFoot,
		Callback = function()
			setPhoto(not photo)
		end,
	})
	-- Levantarse / bajarse: siempre que estés sentado (banco, silla, sofá, coche, bus…) ocupa el
	-- sitio de Saltar, y sale aunque haya una conversación abierta (nunca te quedas atrapado)
	TouchLayout.register({
		Id = "Levantarse", Icon = "bajarse", Label = "Levantarse", Slot = "Saltar", Priority = 1, Key = "F", Pad = "B",
		Always = true,
		Visible = function()
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			return humanoid ~= nil and (humanoid.SeatPart ~= nil or humanoid.Sit)
		end,
		Callback = Actions.standUp,
	} :: any)
	ContextActionService:BindAction("Levantarse", function(_, state)
		if state == Enum.UserInputState.Begin then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and (humanoid.SeatPart or humanoid.Sit) and not player:GetAttribute("Riding") then
				Actions.standUp()
				return Enum.ContextActionResult.Sink
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonB) -- (B: la pista del mando dice "B")
	Hud.addButton("😀 Gestos", Color3.fromRGB(200, 140, 20), 4, Actions.openEmotes)
	local _ = gui

	-- Cada personaje nuevo empieza sin animaciones cargadas
	player.CharacterAdded:Connect(function()
		tracks = {}
		playing = nil
	end)

	-- La primera noche: aviso de la linterna
	local warned = false
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		local clock = Lighting.ClockTime
		if not warned and (clock >= 20.5 or clock < 5) and not busy() and player:GetAttribute("LifeStage") ~= "Bebe" then
			warned = true
			Hud.toast("Info", if UserInputService.TouchEnabled then "🌙 Es de noche: toca el botón Linterna para encenderla" else "🌙 Es de noche: pulsa L para encender la linterna")
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
			stopEmote()
			setPhoto(false)
			return
		end
	end)
end

return Actions
