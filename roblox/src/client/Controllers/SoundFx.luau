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
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local SpeechBubbles = require(script.Parent.Parent.UI.SpeechBubbles)

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
local horn: () -> () -- más abajo

local function hornAction(_, state)
	if state == Enum.UserInputState.Begin then
		horn()
	end
	return Enum.ContextActionResult.Pass
end

function SoundFx.vehicleStart(kind: string, chassis: BasePart)
	vehicleKind = kind
	-- Móvil: botón de claxon/timbre solo mientras vas montado
	local bell = kind == "Bici" or kind == "Patinete"
	TouchLayout.register({
		Id = "Claxon",
		Icon = if bell then "timbre" else "claxon",
		Label = if bell then "Timbre" else "Claxon",
		Slot = "Gestos", -- (el hueco grande del Ataque es el acelerador)
		Priority = 2.5,
		Key = "H",
		Visible = function()
			return vehicleKind ~= nil and TouchLayout.riding()
		end,
		Callback = horn,
	})
	if kind == "Coche" or kind == "Moto" or kind == "Autobus" or kind == "Camion" or kind == "Patrulla" or kind == "Bomberos" then
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
	ContextActionService:UnbindAction("HornTouch")
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

function horn()
	if not vehicleKind or os.clock() - lastHorn < 0.6 then
		return
	end
	lastHorn = os.clock()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if vehicleKind == "Coche" or vehicleKind == "Moto" or vehicleKind == "Autobus" or vehicleKind == "Camion" or vehicleKind == "Patrulla" or vehicleKind == "Bomberos" then
		SoundFx.play("Claxon", 1, if vehicleKind == "Moto" then 1.3 elseif vehicleKind == "Autobus" or vehicleKind == "Camion" or vehicleKind == "Bomberos" then 0.75 else 1, root)
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

-- Cuando un trabajador dice algo (Npc.say: su bocadillo) y estás cerca, se oye
local function workerVoice(npc: Instance, text: string, source: string)
	if source ~= "Server" or muted then
		return
	end
	local workers = workspace:FindFirstChild("Trabajadores")
	local head = npc:FindFirstChild("Head") :: BasePart?
	if not workers or not head or not npc:IsDescendantOf(workers) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if player:GetAttribute("InDialogue") or player:GetAttribute("InCinematic") then
		return
	end
	if root and (root.Position - head.Position).Magnitude < 30 then
		SoundFx.voice(text, pitchOf(npc))
	end
end

-- Bocadillo solo para ti (comentarios sueltos de la gente)
local function localBubble(npc: Model, text: string)
	SpeechBubbles.show(npc, text, { Seconds = 3.5 })
end

local function streetChatter()
	while true do
		task.wait(math.random(VOICES.Every[1], VOICES.Every[2]))
		local workers = workspace:FindFirstChild("Trabajadores")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		-- (no mientras hablas con alguien o ves una escena: su voz se montaba encima de la conversación)
		local busy = player:GetAttribute("InDialogue") or player:GetAttribute("InCinematic")
		if workers and root and not muted and not busy then
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
				-- Algo que pegue con la hora y el tiempo (nada de "¡Buenos días!" de noche ni "qué calor" nevando)
				local TimeContext = require(ReplicatedStorage.Shared.LifeStory.TimeContext)
				local hour, weather = TimeContext.now()
				local line = TimeContext.pick(VOICES.Lines, hour, weather) or VOICES.Lines[math.random(1, #VOICES.Lines)]
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
		local indoors = root.Position.Y > 3000 -- salas de los edificios (en el cielo)
		sound.Volume = if muted or indoors then 0 else base * math.clamp(1 - (d - 150) / 350, 0, 1)
	end)
end

-- ID de un sonido por su nombre (para quien lo reproduce a su manera, p. ej. WeaponFx en un punto)
function SoundFx.id(name: string): string?
	return soundId(name)
end

function SoundFx.isMuted(): boolean
	return muted
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
	SpeechBubbles.onSpoken(workerVoice)
	task.spawn(streetChatter)
	task.spawn(crowd)
end

return SoundFx
