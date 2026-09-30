-- InteractClient (cliente): lo que se ve y se oye al usar los muebles (InteractService en el servidor).
--
--   * Tele encendida: imagen animada en la pantalla (colores del canal, formas que se mueven, el
--     nombre del canal y un rótulo que pasa) y su sintonía al encenderla.
--   * Ordenador en uso: líneas de texto que van saliendo en la pantalla y el tecleo.
--   * Piano: suena una melodía mientras alguien toca.
--   * Grifos y ducha: el agua suena. Interruptores, puertas, armarios y neveras: su clic.
--   * Tu personaje: al empezar algo de pie (grifo, nevera, ducha, ventana) se gira hacia ello
--     (Locomotion.face) y se acerca al sitio (en la ducha, dentro); saltar o echar a andar lo deja.
--     Tumbado en la cama, saltar te levanta.
-- Solo se anima lo que está cerca (a menos de 70 studs) y como mucho 20 veces por segundo.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Interact = require(ReplicatedStorage.Shared.Interact)
local SoundFx = require(script.Parent.SoundFx)
local UseAnim = require(script.Parent.UseAnim)

local InteractClient = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent
local NEAR = 70
local STANDING = { Tap = true, Fridge = true, Shower = true, Window = true }

type Screen = { Part: BasePart, Gui: SurfaceGui, Kind: string, Shapes: { Frame }, Lines: { TextLabel }?, Ticker: TextLabel?, Label: TextLabel?, Background: Frame }
local screens: { [BasePart]: Screen } = {}
-- (tablas débiles: si la pieza desaparece sin avisar, se olvida sola)
local loops: { [BasePart]: Sound } = setmetatable({}, { __mode = "k" }) :: any
-- Grifos y duchas abiertos (y de qué tipo): el bucle del agua solo existe si estás cerca
local waterOn: { [BasePart]: string } = setmetatable({}, { __mode = "k" }) :: any
local WATER_NEAR = 60 -- se crea el bucle (se oye hasta 40 studs: SoundFx.loop)
local WATER_FAR = 80 -- se quita (un poco más lejos, para no crearlo y quitarlo sin parar)
local pianos: { [BasePart]: boolean } = {}

local function near(part: BasePart, distance: number?): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and (camera.CFrame.Position - part.Position).Magnitude < (distance or NEAR)
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

---------------------------------------------------------------------
-- Pantallas (tele y ordenador)
---------------------------------------------------------------------
local function removeScreen(part: BasePart)
	local screen = screens[part]
	if screen then
		screen.Gui:Destroy()
		screens[part] = nil
	end
end

local function makeScreen(part: BasePart, kind: string)
	removeScreen(part)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "ScreenImage"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.Adornee = part
	gui.Parent = part
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BorderSizePixel = 0
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.ClipsDescendants = true
	bg.Parent = gui
	local screen: Screen = { Part = part, Gui = gui, Kind = kind, Shapes = {}, Background = bg }
	if kind == "TV" then
		for i = 1, 3 do
			local shape = Instance.new("Frame")
			shape.AnchorPoint = Vector2.new(0.5, 0.5)
			shape.Size = UDim2.fromScale(0.35 - i * 0.06, 0.5 - i * 0.08)
			shape.BorderSizePixel = 0
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(if i == 2 then 0.5 else 0.1, 0)
			corner.Parent = shape
			shape.Parent = bg
			table.insert(screen.Shapes, shape)
		end
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 0.35
		label.BackgroundColor3 = Color3.new(0, 0, 0)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Size = UDim2.fromScale(0.5, 0.14)
		label.Position = UDim2.fromScale(0.03, 0.04)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = bg
		screen.Label = label
		local ticker = Instance.new("TextLabel")
		ticker.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
		ticker.BorderSizePixel = 0
		ticker.TextColor3 = Color3.new(1, 1, 1)
		ticker.Size = UDim2.fromScale(2, 0.12)
		ticker.Position = UDim2.fromScale(0, 0.86)
		ticker.TextScaled = true
		ticker.Font = Enum.Font.Gotham
		ticker.TextXAlignment = Enum.TextXAlignment.Left
		ticker.Text = "  VALMAR HOY · El tiempo: sol y nubes · El metro amplía horario · Mañana, mercadillo en la plaza · "
		ticker.Parent = bg
		screen.Ticker = ticker
	else
		bg.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
		local lines = {}
		for i = 1, 7 do
			local line = Instance.new("TextLabel")
			line.BackgroundTransparency = 1
			line.TextColor3 = if i % 3 == 0 then Color3.fromRGB(120, 220, 140) else Color3.fromRGB(200, 214, 240)
			line.Size = UDim2.fromScale(0.9, 0.11)
			line.Position = UDim2.fromScale(0.05, 0.05 + (i - 1) * 0.13)
			line.TextScaled = true
			line.Font = Enum.Font.Code
			line.TextXAlignment = Enum.TextXAlignment.Left
			line.Text = ""
			line.Parent = bg
			table.insert(lines, line)
		end
		screen.Lines = lines
	end
	screens[part] = screen
end

local WORDS = { "informe", "ventas", "Valmar", "total", "=", "suma(", ")", "cliente", "pedido", "fecha", "OK", "enviar", "correo", "tabla", "08:30", "reunión", "presupuesto" }

local function updateScreen(screen: Screen, now: number)
	local part = screen.Part
	if screen.Kind == "TV" then
		local channel = Interact.Channels[part:GetAttribute("Channel") or 1] or Interact.Channels[1]
		local speed = channel.Speed
		local colors = channel.Colors
		local k = (now * speed * 0.25) % 1
		screen.Background.BackgroundColor3 = rgb(colors[1]):Lerp(rgb(colors[2]), 0.5 + 0.5 * math.sin(now * speed * 0.7))
		for i, shape in screen.Shapes do
			local phase = now * speed * (0.6 + i * 0.25) + i * 2.1
			shape.Position = UDim2.fromScale(0.5 + 0.32 * math.sin(phase), 0.45 + 0.22 * math.cos(phase * 1.3))
			shape.BackgroundColor3 = rgb(colors[(i % #colors) + 1]):Lerp(Color3.new(1, 1, 1), 0.15 * (1 + math.sin(phase * 2)))
			shape.Rotation = (phase * 20) % 360
		end
		if screen.Label then
			screen.Label.Text = channel.Name
		end
		if screen.Ticker then
			screen.Ticker.Position = UDim2.fromScale(-k, 0.86)
		end
	elseif screen.Lines then
		-- Una línea nueva cada poco (como si escribiera)
		local step = math.floor(now * 2.5)
		for i, line in screen.Lines do
			local n = (step + i) * 7919
			local words = {}
			for w = 1, 2 + n % 4 do
				table.insert(words, WORDS[(n // (w * 13)) % #WORDS + 1])
			end
			line.Text = (if i == #screen.Lines then "> " else "") .. table.concat(words, " ")
		end
	end
end

---------------------------------------------------------------------
-- Sonidos de cada cosa
---------------------------------------------------------------------
local function stopLoop(part: BasePart)
	local sound = loops[part]
	if sound then
		sound:Destroy()
		loops[part] = nil
	end
end

local function startWater(target: BasePart, use: string)
	local sound = SoundFx.loop("Agua", target)
	if sound then
		if use == "Shower" then
			sound.PlaybackSpeed = 1.1
		end
		loops[target] = sound
	end
end

-- Cada medio segundo: pone o quita el sonido del agua según lo cerca que estés
local function refreshWaterLoops()
	for target, use in waterOn do
		if not target.Parent then
			waterOn[target] = nil
			stopLoop(target)
		elseif loops[target] then
			if not near(target, WATER_FAR) then
				stopLoop(target)
			end
		elseif near(target, WATER_NEAR) then
			startWater(target, use)
		end
	end
end

local function playPiano(part: BasePart)
	if pianos[part] then
		return
	end
	pianos[part] = true
	task.spawn(function()
		local i = 0
		while part.Parent and part:GetAttribute("Playing") do
			if near(part, 60) then
				local note = Interact.Melody[i % #Interact.Melody + 1]
				SoundFx.play("Piano", 1, 2 ^ (note / 12), part)
			end
			i += 1
			task.wait(if i % 4 == 0 then 0.5 else 0.28)
		end
		pianos[part] = nil
	end)
end

-- Tecleo mientras el ordenador está en uso
local function playKeys(part: BasePart)
	if pianos[part] then
		return
	end
	pianos[part] = true
	task.spawn(function()
		while part.Parent and part:GetAttribute("On") do
			if near(part, 30) then
				SoundFx.play("Tecla", 1, 0.9 + math.random() * 0.3, part)
			end
			task.wait(0.1 + math.random() * 0.2)
		end
		pianos[part] = nil
	end)
end

local function jingle(part: BasePart)
	for k, pitch in { 1, 1.26, 1.5 } do
		task.delay((k - 1) * 0.12, function()
			SoundFx.play("Piano", 0.6, pitch * 1.4, part)
		end)
	end
end

local function watch(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local use = part:GetAttribute("Use")
	if use == "TV" or use == "Computer" then
		local function refresh()
			if part:GetAttribute("On") then
				makeScreen(part, use)
				if use == "Computer" then
					playKeys(part)
				end
				if use == "TV" and near(part) then
					jingle(part)
					local sound = SoundFx.loop("Tele", part)
					if sound then
						stopLoop(part)
						loops[part] = sound
					end
				end
			else
				removeScreen(part)
				stopLoop(part)
				if near(part) then
					SoundFx.play("Interruptor", 1, 0.8, part)
				end
			end
		end
		part:GetAttributeChangedSignal("On"):Connect(refresh)
		if part:GetAttribute("On") then
			refresh()
		end
	elseif use == "Light" then
		part:GetAttributeChangedSignal("On"):Connect(function()
			if near(part) then
				SoundFx.play("Interruptor", 1, 1, part)
			end
		end)
	elseif use == "Door" or use == "Wardrobe" then
		part:GetAttributeChangedSignal("Open"):Connect(function()
			if near(part) then
				SoundFx.play("Puerta", 1, if part:GetAttribute("Open") then 1 else 0.85, part)
			end
		end)
	elseif use == "Fridge" then
		-- (la puerta de la nevera es otra pieza: se oye al abrirla y al cerrarla)
		for _, d in (part.Parent or part):GetDescendants() do
			if d:IsA("BasePart") and typeof(d:GetAttribute("Hinge")) == "CFrame" then
				d:GetAttributeChangedSignal("Open"):Connect(function()
					if near(part) then
						SoundFx.play("Nevera", 1, if d:GetAttribute("Open") then 1 else 0.8, part)
					end
				end)
			end
		end
	elseif use == "Piano" then
		part:GetAttributeChangedSignal("Playing"):Connect(function()
			if part:GetAttribute("Playing") then
				playPiano(part)
			end
		end)
	end
	-- Agua (grifos; en la ducha corre en la alcachofa, que es otra pieza)
	local function watchWater(target: BasePart)
		local function refreshWater()
			if target:GetAttribute("Running") then
				stopLoop(target)
				-- Solo se crea cerca (a menos de WATER_NEAR, antes de que se oiga): antes se creaba en
				-- cada grifo abierto de la ciudad. Al acercarte lo crea el bucle de InteractClient.init,
				-- así ya suena sin tener que estar allí cuando se abrió el grifo
				waterOn[target] = use
				if near(target, WATER_NEAR) then
					startWater(target, use)
				end
			else
				waterOn[target] = nil
				stopLoop(target)
			end
		end
		target:GetAttributeChangedSignal("Running"):Connect(refreshWater)
		if target:GetAttribute("Running") then
			refreshWater() -- (ya estaba abierto al llegar)
		end
	end
	if use == "Tap" then
		watchWater(part)
	elseif use == "Shower" then
		for _, d in (part.Parent or part):GetDescendants() do
			if d:IsA("BasePart") and d.Name == "ShowerHead" then
				watchWater(d)
			end
		end
	end
	part.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			removeScreen(part)
			waterOn[part] = nil
			stopLoop(part)
		end
	end)
end

---------------------------------------------------------------------
-- Tu personaje
---------------------------------------------------------------------
local startedAt = 0
local glideFrom: Vector3? = nil

local lastPose: string? = nil

local function onPose()
	local pose = player:GetAttribute("UsePose")
	startedAt = os.clock()
	glideFrom = nil
	if lastPose == "Lie" and pose ~= "Lie" then
		-- Al levantarse de la cama vuelve a poder andar (aquí también, por si llega antes)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
	lastPose = if type(pose) == "string" then pose else nil
	if type(pose) ~= "string" then
		return
	end
	local at = player:GetAttribute("UseAt")
	if STANDING[pose] and typeof(at) == "Vector3" then
		local ok, Locomotion = pcall(function()
			return require(script.Parent.Locomotion) :: any
		end)
		if ok and Locomotion and Locomotion.face then
			local info = Interact.Uses[pose]
			pcall(Locomotion.face, at, if info and info.Seconds then info.Seconds else 2)
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local spot = player:GetAttribute("UseSpot")
		if root and typeof(spot) == "Vector3" and (Vector3.new(spot.X, root.Position.Y, spot.Z) - root.Position).Magnitude < 7 then
			glideFrom = root.Position
		end
	end
end

local function stop()
	if player:GetAttribute("UsePose") then
		Remote:FireServer("Stop")
	end
end

local function localStep()
	local pose = player:GetAttribute("UsePose")
	if type(pose) ~= "string" then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end
	local since = os.clock() - startedAt
	if pose == "Lie" then
		humanoid.PlatformStand = true
		return
	end
	if STANDING[pose] then
		-- Acercarse al sitio (dentro de la ducha, delante del grifo) con suavidad
		local spot = player:GetAttribute("UseSpot")
		if glideFrom and typeof(spot) == "Vector3" and since < 0.5 then
			local target = Vector3.new(spot.X, root.Position.Y, spot.Z)
			local w = UseAnim.ease(since / 0.45)
			local position = glideFrom:Lerp(Vector3.new(target.X, glideFrom.Y, target.Z), w)
			root.CFrame = CFrame.new(position.X, root.Position.Y, position.Z) * root.CFrame.Rotation
		end
		-- Echar a andar lo deja
		if since > 0.6 and humanoid.MoveDirection.Magnitude > 0.3 then
			stop()
		end
	end
end

---------------------------------------------------------------------

function InteractClient.init()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Interact") :: RemoteEvent
	for _, part in CollectionService:GetTagged("Interact") do
		watch(part)
	end
	CollectionService:GetInstanceAddedSignal("Interact"):Connect(watch)
	CollectionService:GetInstanceRemovedSignal("Interact"):Connect(function(part)
		if part:IsA("BasePart") then
			removeScreen(part)
			waterOn[part] = nil
			stopLoop(part)
		end
	end)

	player:GetAttributeChangedSignal("UsePose"):Connect(onPose)
	UserInputService.JumpRequest:Connect(function()
		local pose = player:GetAttribute("UsePose")
		if pose == "Lie" or STANDING[pose] then
			stop()
		end
	end)
	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(localStep)
		if not ok then
			warn("[InteractClient] " .. tostring(err))
		end
	end)

	-- Pantallas: se animan de cerca, 20 veces por segundo (y el agua, cada medio segundo)
	task.spawn(function()
		local ticks = 0
		while true do
			ticks += 1
			if ticks % 10 == 0 then
				local ok, err = pcall(refreshWaterLoops)
				if not ok then
					warn("[InteractClient] " .. tostring(err))
				end
			end
			local now = os.clock()
			for part, screen in screens do
				if not part.Parent then
					removeScreen(part)
				elseif near(part) then
					screen.Gui.Enabled = true
					updateScreen(screen, now)
				else
					screen.Gui.Enabled = false
				end
			end
			task.wait(0.05)
		end
	end)
end

return InteractClient
