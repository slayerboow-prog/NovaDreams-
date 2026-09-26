-- SoundFx (cliente): efectos de sonido del juego (no música).
--   * Personaje: salto, aterrizaje fuerte (golpe según la altura de la caída), chocar corriendo
--     contra una pared, chapuzón al caer al agua y trepar
--   * Interfaz: clic en los botones y un "ding" en los avisos (otro tono en los errores)
--   * Vehículos: arranque, choques según la velocidad, motor en bucle (sube de tono al acelerar)
--     y claxon / timbre con la tecla H
--   * Gente: los trabajadores de la ciudad dicen sus frases en voz alta al hablar con ellos y,
--     de vez en cuando, alguien cercano comenta algo (voz sintetizada de Roblox, como la historia).
--     Los gestos (saludar, reír…) también tienen voz. Murmullo de gente en el centro si hay audio.
-- Qué sonido es cada cosa: Config.Sounds (y Config.StreetVoices para las voces).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local SoundFx = {}

local player = Players.LocalPlayer
local SOUNDS = Config.Sounds
local VOICES = Config.StreetVoices
local folder: Folder
local muted = false

---------------------------------------------------------------------
-- Reproducir
---------------------------------------------------------------------

-- ID del sonido: primero un Sound en ReplicatedStorage.Sonidos con ese nombre; luego Config.Sounds
local function soundId(name: string): string?
	local custom = ReplicatedStorage:FindFirstChild("Sonidos")
	local sound = custom and custom:FindFirstChild(name)
	if sound and sound:IsA("Sound") and sound.SoundId ~= "" then
		return sound.SoundId
	end
	local entry = SOUNDS[name]
	if not entry then
		return nil
	end
	local id = entry.Id
	if typeof(id) == "number" then
		return if id > 0 then "rbxassetid://" .. id else nil
	end
	return if typeof(id) == "string" and id ~= "" then id else nil
end

-- Toca un sonido una vez. at = pieza donde suena (se oye más flojo de lejos); sin at, suena "en la cabeza"
function SoundFx.play(name: string, volume: number?, pitch: number?, at: BasePart?): Sound?
	local id = soundId(name)
	if not id or muted then
		return nil
	end
	local entry = SOUNDS[name] or {}
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = (entry.Volume or 0.5) * (volume or 1)
	sound.PlaybackSpeed = (entry.Pitch or 1) * (pitch or 1) * (0.95 + math.random() * 0.1)
	sound.RollOffMaxDistance = 120
	sound.Parent = at or folder
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(8, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
	return sound
end

-- Sonido en bucle (motor, murmullo). Devuelve nil si no hay audio para ese nombre.
function SoundFx.loop(name: string, parent: Instance?): Sound?
	local id = soundId(name)
	if not id then
		return nil
	end
	local entry = SOUNDS[name] or {}
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = if muted then 0 else (entry.Volume or 0.5)
	sound.PlaybackSpeed = entry.Pitch or 1
	sound.Parent = parent or folder
	sound:Play()
	return sound
end

---------------------------------------------------------------------
-- Voces (voz sintetizada de Roblox)
---------------------------------------------------------------------
local ttsAvailable = VOICES.Enabled
local talking = 0

-- Dice un texto en voz alta. pitch cambia la voz (cada persona tiene la suya)
function SoundFx.voice(text: string, pitch: number?, volume: number?)
	if not ttsAvailable or muted or talking >= 2 then
		return
	end
	talking += 1
	task.spawn(function()
		local ok = pcall(function()
			local tts = Instance.new("AudioTextToSpeech")
			tts.Text = text
			pcall(function()
				tts.Pitch = pitch or 1
			end)
			pcall(function()
				tts.Volume = (VOICES.Volume or 0.7) * (volume or 1)
			end)
			local output = Instance.new("AudioDeviceOutput")
			output.Parent = tts
			local wire = Instance.new("Wire")
			wire.SourceInstance = tts
			wire.TargetInstance = output
			wire.Parent = tts
			tts.Parent = folder
			pcall(function()
				tts:LoadAsync()
			end)
			tts:Play()
			task.delay(math.clamp(#text * 0.08 + 1, 1.5, 8), function()
				tts:Destroy()
			end)
		end)
		if not ok then
			ttsAvailable = false -- el motor no tiene voz sintetizada: solo se ven los textos
		end
		task.wait(math.clamp(#text * 0.08, 1, 6))
		talking -= 1
	end)
end

---------------------------------------------------------------------
-- Personaje
---------------------------------------------------------------------
local function watchCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end
	local fallSpeed = 0
	local lastSpeed = 0
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			SoundFx.play("Salto", 1, nil, root)
		elseif new == Enum.HumanoidStateType.Landed then
			-- Cuanto más alta la caída, más fuerte el golpe
			if fallSpeed > 55 then
				SoundFx.play("Aterrizaje", math.clamp(fallSpeed / 90, 0.6, 1.4), nil, root)
				SoundFx.play("Golpe", math.clamp((fallSpeed - 55) / 60, 0.3, 1), 0.8, root)
			end
		elseif new == Enum.HumanoidStateType.Swimming and fallSpeed > 20 then
			SoundFx.play("Chapuzon", math.clamp(fallSpeed / 60, 0.5, 1.2), nil, root)
		end
	end)
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not root.Parent then
			connection:Disconnect()
			return
		end
		local velocity = root.AssemblyLinearVelocity
		if velocity.Y < 0 then
			fallSpeed = -velocity.Y
		elseif humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			fallSpeed = 0
		end
		-- Chocar corriendo contra algo: se para de golpe mientras sigue empujando
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		if not humanoid.SeatPart and lastSpeed > 22 and speed < 4 and humanoid.MoveDirection.Magnitude > 0.5 then
			SoundFx.play("Golpe", 0.6, 1.1, root)
		end
		lastSpeed = speed
	end)
end

---------------------------------------------------------------------
-- Vehículos: motor, claxon y choques (Driving.luau llama a estas funciones)
---------------------------------------------------------------------
local engine: Sound? = nil
local vehicleKind: string? = nil
local lastHorn = 0

function SoundFx.vehicleStart(kind: string, chassis: BasePart)
	vehicleKind = kind
	if kind == "Coche" or kind == "Moto" or kind == "Autobus" or kind == "Camion" then
		SoundFx.play("Arranque", 1, nil, chassis)
		engine = SoundFx.loop("Motor", chassis)
		if engine and kind == "Moto" then
			engine.PlaybackSpeed *= 1.35
		end
	end
end

function SoundFx.vehicleStop()
	if engine then
		engine:Destroy()
		engine = nil
	end
	vehicleKind = nil
end

-- Cada fotograma: el motor sube de tono con la velocidad (ratio 0..1)
function SoundFx.vehicleSpeed(ratio: number)
	if engine then
		local base = if vehicleKind == "Moto" then 1.35 else 1
		engine.PlaybackSpeed = base * (0.75 + ratio * 0.9)
		engine.Volume = if muted then 0 else (SOUNDS.Motor.Volume or 0.45) * (0.7 + ratio * 0.5)
	end
end

function SoundFx.crash(speed: number, at: BasePart?)
	if speed > 8 then
		SoundFx.play("Choque", math.clamp(speed / 50, 0.3, 1.3), nil, at)
	end
end

local function horn()
	if not vehicleKind or os.clock() - lastHorn < 0.6 then
		return
	end
	lastHorn = os.clock()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if vehicleKind == "Coche" or vehicleKind == "Moto" or vehicleKind == "Autobus" or vehicleKind == "Camion" then
		SoundFx.play("Claxon", 1, if vehicleKind == "Moto" then 1.3 elseif vehicleKind == "Autobus" or vehicleKind == "Camion" then 0.75 else 1, root)
	else
		SoundFx.play("Timbre", 1, nil, root)
	end
end

---------------------------------------------------------------------
-- Gente de la ciudad
---------------------------------------------------------------------
local pitches: { [Instance]: number } = {}
local function pitchOf(npc: Instance): number
	if not pitches[npc] then
		pitches[npc] = 0.85 + math.random() * 0.35
	end
	return pitches[npc]
end

-- Cuando un trabajador dice algo (su bocadillo cambia) y estás cerca, se oye
local function watchWorker(npc: Instance)
	local head = npc:WaitForChild("Head", 10)
	if not head then
		return
	end
	local function hook(gui: Instance)
		if gui.Name ~= "Bubble" or not gui:IsA("BillboardGui") then
			return
		end
		local label = gui:FindFirstChildOfClass("TextLabel")
		if not label then
			return
		end
		label:GetPropertyChangedSignal("Text"):Connect(function()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if label.Text ~= "" and root and (root.Position - (head :: BasePart).Position).Magnitude < 30 then
				SoundFx.voice(label.Text, pitchOf(npc))
			end
		end)
	end
	for _, child in head:GetChildren() do
		hook(child)
	end
	head.ChildAdded:Connect(function(child)
		task.defer(hook, child)
	end)
end

-- Bocadillo solo para ti (comentarios sueltos de la gente)
local function localBubble(npc: Model, text: string)
	local head = npc:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "LocalBubble"
	gui.Size = UDim2.fromOffset(220, 54)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 60
	gui.Adornee = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 0.1
	label.TextColor3 = Color3.fromRGB(20, 20, 24)
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label
	gui.Parent = player:WaitForChild("PlayerGui")
	task.delay(3.5, function()
		gui:Destroy()
	end)
end

local function streetChatter()
	while true do
		task.wait(math.random(VOICES.Every[1], VOICES.Every[2]))
		local workers = workspace:FindFirstChild("Trabajadores")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if workers and root and not muted then
			local best, bestDistance = nil, VOICES.Distance
			for _, npc in workers:GetChildren() do
				local head = npc:FindFirstChild("Head") :: BasePart?
				if head then
					local d = (head.Position - root.Position).Magnitude
					if d < bestDistance then
						best, bestDistance = npc, d
					end
				end
			end
			if best then
				local line = VOICES.Lines[math.random(1, #VOICES.Lines)]
				localBubble(best, line)
				SoundFx.voice(line, pitchOf(best), 1 - bestDistance / (VOICES.Distance * 1.5))
			end
		end
	end
end

-- Murmullo de gente cerca del centro (solo si hay un audio "Multitud")
local function crowd()
	local sound = SoundFx.loop("Multitud")
	if not sound then
		return
	end
	local base = SOUNDS.Multitud.Volume or 0.25
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			return
		end
		local d = Vector2.new(root.Position.X, root.Position.Z).Magnitude -- distancia a la Plaza Mayor
		sound.Volume = if muted then 0 else base * math.clamp(1 - (d - 150) / 350, 0, 1)
	end)
end

---------------------------------------------------------------------
function SoundFx.setMuted(value: boolean)
	muted = value
	if engine then
		engine.Volume = if muted then 0 else (SOUNDS.Motor.Volume or 0.45)
	end
end

function SoundFx.init()
	folder = Instance.new("Folder")
	folder.Name = "SoundFx"
	folder.Parent = SoundService

	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)

	-- Clic en cualquier botón de la interfaz
	local playerGui = player:WaitForChild("PlayerGui")
	local function hookButton(obj: Instance)
		if obj:IsA("GuiButton") then
			obj.Activated:Connect(function()
				SoundFx.play("Clic")
			end)
		end
	end
	for _, obj in playerGui:GetDescendants() do
		hookButton(obj)
	end
	playerGui.DescendantAdded:Connect(hookButton)

	-- Avisos del servidor: ding (y otro tono si es un error)
	local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
	notify.OnClientEvent:Connect(function(kind)
		if kind == "Error" then
			SoundFx.play("Error")
		elseif kind == "Success" or kind == "Money" then
			SoundFx.play("Aviso")
		end
	end)

	-- Claxon / timbre
	ContextActionService:BindAction("Horn", function(_, state)
		if state == Enum.UserInputState.Begin then
			horn()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.H, Enum.KeyCode.DPadUp)

	-- Gente de la ciudad
	local function watchFolder(workers: Instance)
		for _, npc in workers:GetChildren() do
			task.spawn(watchWorker, npc)
		end
		workers.ChildAdded:Connect(function(npc)
			task.spawn(watchWorker, npc)
		end)
	end
	local workers = workspace:FindFirstChild("Trabajadores")
	if workers then
		watchFolder(workers)
	else
		workspace.ChildAdded:Connect(function(child)
			if child.Name == "Trabajadores" then
				watchFolder(child)
			end
		end)
	end
	task.spawn(streetChatter)
	task.spawn(crowd)
end

return SoundFx
