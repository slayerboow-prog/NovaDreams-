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
-- Grupos de sonido (Music, SFX, Voice, Ambience)
-- Cada sonido va a su grupo: silenciar = poner el volumen del grupo a 0, y así se callan también
-- los que ya estaban sonando (bucles, motor, lluvia…). Se crean una sola vez y se reutilizan.
---------------------------------------------------------------------
local groups: { [string]: SoundGroup } = {}

function SoundFx.group(name: string): SoundGroup
	local existing = groups[name]
	if existing and existing.Parent then
		return existing
	end
	local found = SoundService:FindFirstChild(name)
	local group: SoundGroup
	if found and found:IsA("SoundGroup") then
		group = found
	else
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Volume = 1
		if name == "SFX" then
			-- Compresor: muchos efectos a la vez (disparos, golpes) no saturan
			local compressor = Instance.new("CompressorSoundEffect")
			compressor.Threshold = -12
			compressor.Ratio = 4
			compressor.Attack = 0.01
			compressor.Release = 0.2
			compressor.Parent = group
		end
		group.Parent = SoundService
	end
	groups[name] = group
	return group
end

-- Silencia (volumen 0) o devuelve el volumen a un grupo
function SoundFx.setGroupOn(name: string, on: boolean)
	SoundFx.group(name).Volume = if on then 1 else 0
end

---------------------------------------------------------------------
-- Reproducir
---------------------------------------------------------------------

-- Nombre sin mayúsculas, espacios, guiones, puntos ni extensión ("Metro_Tren.ogg" = "metrotren")
local function normalize(name: string): string
	return (string.gsub(string.lower((string.gsub(name, "%.%a%w*$", ""))), "[%s_%-%.]", ""))
end

-- Un Sound con ese nombre dentro de ReplicatedStorage.Sonidos (también en subcarpetas)
local function fromSonidos(name: string): string?
	local custom = ReplicatedStorage:FindFirstChild("Sonidos")
	if not custom then
		return nil
	end
	local direct = custom:FindFirstChild(name)
	if direct and direct:IsA("Sound") and direct.SoundId ~= "" then
		return direct.SoundId
	end
	local wanted = normalize(name)
	for _, sound in custom:GetDescendants() do
		if sound:IsA("Sound") and sound.SoundId ~= "" and normalize(sound.Name) == wanted then
			return sound.SoundId
		end
	end
	return nil
end

-- Lo ya buscado: nombre -> ID (false = no hay). Buscar en Sonidos recorre toda la carpeta, y se
-- pedía en cada sonido que se tocaba. Se olvida todo si algo cambia en ReplicatedStorage.Sonidos
-- (llega o se va un Sound, o cambia su SoundId o su nombre) o si llega o se va la carpeta.
local resolvedFiles: { [string]: string | false } = {} -- SoundFx.resolve (por archivo)
local resolvedNames: { [string]: string | false } = {} -- soundId (por nombre de Config.Sounds)
local function forget()
	table.clear(resolvedFiles)
	table.clear(resolvedNames)
end
do
	local watched: Instance? = nil
	local links: { RBXScriptConnection } = {}
	local function hook(d: Instance)
		if d:IsA("Sound") then
			table.insert(links, d:GetPropertyChangedSignal("SoundId"):Connect(forget))
			table.insert(links, d:GetPropertyChangedSignal("Name"):Connect(forget))
		end
	end
	local function watch()
		local custom = ReplicatedStorage:FindFirstChild("Sonidos")
		if custom == watched then
			return
		end
		watched = custom
		forget()
		for _, link in links do
			link:Disconnect()
		end
		table.clear(links)
		if custom then
			for _, d in custom:GetDescendants() do
				hook(d)
			end
			table.insert(links, custom.DescendantAdded:Connect(function(d)
				forget()
				hook(d)
			end))
			table.insert(links, custom.DescendantRemoving:Connect(forget))
		end
	end
	pcall(function()
		watch()
		ReplicatedStorage.ChildAdded:Connect(function(child)
			if child.Name == "Sonidos" then
				watch()
			end
		end)
		ReplicatedStorage.ChildRemoved:Connect(function(child)
			if child.Name == "Sonidos" then
				watch()
			end
		end)
	end)
end

-- IDs subidos por scripts/upload-audio.sh (nombre del archivo -> "rbxassetid://…")
local uploaded: { [string]: string } = {}
do
	local module = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("SoundIds")
	if module and module:IsA("ModuleScript") then
		local ok, ids = pcall(require, module)
		if ok and type(ids) == "table" then
			uploaded = ids
		end
	end
end

-- ID subido con scripts/upload-audio.sh para un archivo ("motor", "tema_valmar.ogg"…), o nil
function SoundFx.uploaded(file: string?): string?
	if not file or file == "" then
		return nil
	end
	local known = uploaded[(string.gsub(file, "%.%a%w*$", ""))]
	return if type(known) == "string" and known ~= "" then known else nil
end

-- ID de un audio que puede no tener ID todavía. Por orden:
--   1. id (el de Config) si no es 0
--   2. SoundIds[file] (lo que escribe scripts/upload-audio.sh)
--   3. un Sound llamado como el archivo en ReplicatedStorage.Sonidos (arrastrado desde el Asset Manager)
--   4. nada (no suena, sin errores)
-- file = nombre del archivo de audio/sfx sin ".ogg" (p. ej. "motor", "lluvia").
function SoundFx.resolve(id: any, file: string?): string?
	if typeof(id) == "number" and id > 0 then
		return "rbxassetid://" .. id
	elseif typeof(id) == "string" and id ~= "" and id ~= "0" then
		return id
	end
	if not file or file == "" then
		return nil
	end
	local known = resolvedFiles[file]
	if known ~= nil then
		return known or nil
	end
	local found = SoundFx.uploaded(file) or fromSonidos((string.gsub(file, "%.%a%w*$", "")))
	resolvedFiles[file] = found or false
	return found
end

-- ID del sonido: un Sound en ReplicatedStorage.Sonidos con el nombre de Config (p. ej. "Motor") manda
-- siempre (así se cambia cualquier efecto sin tocar código); si no, Config.Sounds con SoundFx.resolve
local function soundId(name: string): string?
	local known = resolvedNames[name]
	if known ~= nil then
		return known or nil
	end
	local found: string? = nil
	local custom = ReplicatedStorage:FindFirstChild("Sonidos")
	local sound = custom and custom:FindFirstChild(name)
	if sound and sound:IsA("Sound") and sound.SoundId ~= "" then
		found = sound.SoundId
	else
		local entry = SOUNDS[name]
		found = if entry then SoundFx.resolve(entry.Id, entry.File) else nil
	end
	resolvedNames[name] = found or false
	return found
end

-- Clic automático de los botones: si el propio botón ya toca su sonido (en menos de 50 ms), el
-- clic se quita para que no suenen dos a la vez
local CLICK_WINDOW = 0.05
local lastUiSound = -1
local autoClick: { Sound: Sound, At: number }? = nil

-- Toca un sonido una vez. at = pieza donde suena (se oye más flojo de lejos); sin at, suena "en la cabeza"
function SoundFx.play(name: string, volume: number?, pitch: number?, at: BasePart?): Sound?
	local id = soundId(name)
	if not id or muted then
		return nil
	end
	if not at and name ~= "Clic" then
		-- Sonido de interfaz: si acaba de sonar el clic automático, se corta (no dos sonidos por pulsación)
		lastUiSound = os.clock()
		local click = autoClick
		if click and os.clock() - click.At < CLICK_WINDOW then
			autoClick = nil
			click.Sound:Destroy()
		end
	end
	local entry = SOUNDS[name] or {}
	local sound = Instance.new("Sound")
	sound.SoundId = id
	-- (el multiplicador no pasa de 1: por encima satura)
	sound.Volume = (entry.Volume or 0.5) * math.min(volume or 1, 1)
	sound.PlaybackSpeed = (entry.Pitch or 1) * (pitch or 1) * (0.95 + math.random() * 0.1)
	sound.RollOffMaxDistance = 120
	sound.SoundGroup = SoundFx.group("SFX")
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
-- groupName: "SFX" (por defecto) o "Ambience". El silencio lo pone el grupo (así el bucle se calla
-- aunque ya esté sonando y vuelve al quitar el silencio).
function SoundFx.loop(name: string, parent: Instance?, groupName: string?): Sound?
	local id = soundId(name)
	if not id then
		return nil
	end
	local entry = SOUNDS[name] or {}
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = entry.Volume or 0.5
	sound.PlaybackSpeed = entry.Pitch or 1
	sound.SoundGroup = SoundFx.group(groupName or "SFX")
	if parent and (parent:IsA("BasePart") or parent:IsA("Attachment")) then
		-- En un sitio del mundo: se oye solo cerca (por defecto llegaba a 10000 studs)
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMaxDistance = 40
	end
	sound.Parent = parent or folder
	sound:Play()
	return sound
end

---------------------------------------------------------------------
-- Voces (voz sintetizada de Roblox)
---------------------------------------------------------------------
local ttsAvailable = VOICES.Enabled
local talking = 0
-- Voces que suenan ahora (para cortarlas al silenciar: la voz sintetizada no va en un SoundGroup)
local activeVoices: { [Instance]: boolean } = {}

-- Dice un texto en voz alta. pitch cambia la voz (cada persona tiene la suya)
function SoundFx.voice(text: string, pitch: number?, volume: number?)
	if not ttsAvailable or muted or talking >= 2 then
		return
	end
	talking += 1
	task.spawn(function()
		local tts: any = nil
		local ok = pcall(function()
			tts = Instance.new("AudioTextToSpeech")
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
			if muted then
				-- (se silenció mientras cargaba)
				tts:Destroy()
				return
			end
			activeVoices[tts] = true
			tts:Play()
			task.delay(math.clamp(#text * 0.08 + 1, 1.5, 8), function()
				activeVoices[tts] = nil
				tts:Destroy()
			end)
		end)
		if not ok then
			ttsAvailable = false -- el motor no tiene voz sintetizada: solo se ven los textos
			-- (si falló a medias, que no se quede la instancia colgada)
			if tts then
				activeVoices[tts] = nil
				pcall(function()
					tts:Destroy()
				end)
			end
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
		engine.Volume = (SOUNDS.Motor.Volume or 0.45) * (0.7 + ratio * 0.5) -- (el silencio lo pone el grupo SFX)
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
-- (tabla débil: aunque no llegue el Destroying, lo que desaparece se olvida solo)
local pitches: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local function pitchOf(npc: Instance): number
	if not pitches[npc] then
		pitches[npc] = 0.85 + math.random() * 0.35
		-- (al desaparecer la persona se olvida su voz: si no, la tabla crece sin parar)
		npc.Destroying:Connect(function()
			pitches[npc] = nil
		end)
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
	local sound = SoundFx.loop("Multitud", nil, "Ambience")
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
		sound.Volume = if indoors then 0 else base * math.clamp(1 - (d - 150) / 350, 0, 1)
	end)
end

-- ID de un sonido por su nombre (para quien lo reproduce a su manera, p. ej. WeaponFx en un punto)
function SoundFx.id(name: string): string?
	return soundId(name)
end

function SoundFx.isMuted(): boolean
	return muted
end

-- ¿Estás en una conversación o viendo una escena? (entonces no suenan avisos por megafonía)
function SoundFx.busy(): boolean
	return player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
end

---------------------------------------------------------------------
function SoundFx.setMuted(value: boolean)
	muted = value
	-- Los grupos callan todo lo que ya suena (bucles, motor, lluvia, sonidos del servidor)
	SoundFx.setGroupOn("SFX", not value)
	SoundFx.setGroupOn("Ambience", not value)
	if value then
		-- La voz sintetizada no va en un grupo: la que esté sonando se corta
		for tts in activeVoices do
			activeVoices[tts] = nil
			pcall(function()
				tts:Destroy()
			end)
		end
	end
end

-- Sonidos creados por el servidor (romper cosas, patear juguetes) llevan el atributo SfxGroup:
-- aquí se meten en su grupo para que el botón de silenciar también los calle
local function tagServerSound(obj: Instance)
	if obj:IsA("Sound") then
		local name = obj:GetAttribute("SfxGroup")
		if type(name) == "string" and name ~= "" then
			obj.SoundGroup = SoundFx.group(name)
		end
	end
end

function SoundFx.init()
	folder = Instance.new("Folder")
	folder.Name = "SoundFx"
	folder.Parent = SoundService
	SoundFx.group("SFX")
	SoundFx.group("Ambience")

	workspace.DescendantAdded:Connect(tagServerSound)
	task.spawn(function()
		-- (poco a poco, como Weather: sin congelar el arranque con un mapa grande)
		for i, obj in workspace:GetDescendants() do
			tagServerSound(obj)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)

	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)

	-- Clic en cualquier botón de la interfaz
	local playerGui = player:WaitForChild("PlayerGui")
	local function hookButton(obj: Instance)
		if obj:IsA("GuiButton") then
			obj.Activated:Connect(function()
				-- NoClick = el botón no quiere clic; y si su código ya ha tocado su sonido, tampoco
				if obj:GetAttribute("NoClick") or os.clock() - lastUiSound < CLICK_WINDOW then
					return
				end
				local sound = SoundFx.play("Clic")
				autoClick = if sound then { Sound = sound, At = os.clock() } else nil
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
