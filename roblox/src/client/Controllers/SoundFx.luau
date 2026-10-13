-- SoundFx (cliente): efectos de sonido del juego (no música).
--   * Personaje: salto, aterrizaje fuerte (golpe según la altura de la caída), chocar corriendo
--     contra una pared, chapuzón al caer al agua y trepar
--   * Interfaz: clic en los botones y un "ding" en los avisos (otro tono en los errores)
--   * Vehículos: arranque, choques según la velocidad, motor en bucle (sube de tono al acelerar)
--     y claxon / timbre con la tecla H; intermitente (tic-tac suave), freno de mano y luces
--   * Gente: los trabajadores de la ciudad dicen sus frases en voz alta al hablar con ellos y,
--     de vez en cuando, alguien cercano comenta algo (voz sintetizada de Roblox, como la historia).
--     Los gestos (saludar, reír…) también tienen voz. Murmullo de gente en el centro si hay audio.
-- Qué sonido es cada cosa: Config.Sounds (y Config.StreetVoices para las voces).
-- Mezcla (Config.SfxMix): volumen por categoría (UI, Recompensa, Momento, Mundo), tope de efectos a la
-- vez, cooldown por nombre, variación de tono y volumen, capas (Layers) y agache de la música (Duck).
-- Niveles del menú (🔔 Efectos, 🌳 Ambiente, 🎵 Música: de 0 a 10) = SoundFx.setGroupLevel, desde
-- Controllers/AudioMix. Los sonidos del mundo van en 3D con su alcance (Config.Sounds MinDistance /
-- MaxDistance; World = true marca los que salen de una pieza). Lo que responde a la partida
-- (dinero, XP, nivel, misiones, grillos, olas) está en Controllers/GameSfx.

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

-- Volumen de cada grupo = apagado (0) o su nivel del menú (Controllers/AudioMix: 🎵 Música, 🔔 Efectos,
-- 🌳 Ambiente…, ya con la curva de shared/AudioSettings) × agache (duck). El agache de la música va
-- encima del nivel elegido: con la música a 6, una fanfarria la baja desde ahí y vuelve a 6.
local groupOff: { [string]: boolean } = {}
local groupLevel: { [string]: number } = {}
local groupDuck: { [string]: number } = {}
local function applyGroup(name: string)
	SoundFx.group(name).Volume = (if groupOff[name] then 0 else (groupLevel[name] or 1)) * (groupDuck[name] or 1)
end

-- Nivel de los efectos (menú «🔔 Efectos»): 0 … 1 (ganancia)
local sfxLevel = 1

-- Silencia (volumen 0) o devuelve el volumen a un grupo (a su nivel del menú)
function SoundFx.setGroupOn(name: string, on: boolean)
	groupOff[name] = not on
	applyGroup(name)
end

-- Nivel (ganancia 0 … 1) de un grupo: Music, Voice, SFX o Ambience (lo pone Controllers/AudioMix)
function SoundFx.setGroupLevel(name: string, gain: number)
	local g = math.clamp(tonumber(gain) or 1, 0, 1)
	groupLevel[name] = g
	if name == "SFX" then
		sfxLevel = g
	end
	applyGroup(name)
end

-- Nivel elegido de un grupo (sin el agache ni el silencio)
function SoundFx.groupLevel(name: string): number
	return groupLevel[name] or 1
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
local usingFallback: { [string]: boolean } = {} -- nombres que suenan con su Fallback (File sin subir)
local function forget()
	table.clear(resolvedFiles)
	table.clear(resolvedNames)
	table.clear(usingFallback)
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
-- siempre (así se cambia cualquier efecto sin tocar código); si no, Config.Sounds con SoundFx.resolve;
-- y si su audio (File) aún no está subido, el Fallback de Config (un sonido de Roblox retocado)
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
		local fallback = entry and entry.Fallback
		if not found and type(fallback) == "table" then
			found = SoundFx.resolve(fallback.Id)
			usingFallback[name] = found ~= nil
		end
	end
	resolvedNames[name] = found or false
	return found
end

-- collide.wav por debajo de este tono suena a explosión ("bomba atómica"): nunca más grave
local COLLIDE = "rbxasset://sounds/collide.wav"
local COLLIDE_MIN_PITCH = 0.9

-- Volumen y tono de un sonido ya con el multiplicador (el de Config, o el de su Fallback si suena ese).
-- id = el que va a sonar (SoundFx.id). Sin aleatorio: quien lo usa añade su variación.
function SoundFx.tune(name: string, id: string, volume: number?, pitch: number?): (number, number)
	local entry = SOUNDS[name] or {}
	local base = if usingFallback[name] and type(entry.Fallback) == "table" then entry.Fallback else entry
	local v = (base.Volume or 0.5) * (volume or 1)
	local p = (base.Pitch or 1) * (pitch or 1)
	if id == COLLIDE then
		p = math.max(p, COLLIDE_MIN_PITCH)
	end
	return v, p
end

-- Clic automático de los botones: si el propio botón ya toca su sonido (en menos de 50 ms), el
-- clic se quita para que no suenen dos a la vez
local CLICK_WINDOW = 0.05
local lastUiSound = -1
local autoClick: { Sound: Sound, At: number }? = nil

---------------------------------------------------------------------
-- Mezcla de los efectos (Config.SfxMix): volumen por categoría, cuántos a la vez, agache de la música
---------------------------------------------------------------------
local MIX = Config.SfxMix or {}
local CATEGORY = MIX.Categories or {}
local MAX_ACTIVE = MIX.MaxActive or 18
local active = 0 -- efectos sueltos sonando ahora (SoundFx.play)
local lastPlayed: { [string]: number } = {}

-- Volumen de la categoría de un sonido (UI, Recompensa, Momento, Mundo…)
function SoundFx.categoryVolume(name: string): number
	local entry = SOUNDS[name]
	local cat = entry and entry.Category
	return if cat and type(CATEGORY[cat]) == "number" then CATEGORY[cat] else 1
end

-- ¿Puede sonar ya? Cooldown (no ametrallar: botes, XP…) y tope de sonidos a la vez (móvil). Los del
-- mundo se quedan fuera antes que los de la interfaz o las recompensas.
function SoundFx.allowed(name: string, now: number?): boolean
	local entry = SOUNDS[name]
	local t = now or os.clock()
	local cooldown = entry and entry.Cooldown
	if cooldown and t - (lastPlayed[name] or -math.huge) < cooldown then
		return false
	end
	local world = entry == nil or entry.Category == nil or entry.Category == "Mundo"
	if active >= (if world then MAX_ACTIVE else MAX_ACTIVE + 6) then
		return false
	end
	return true
end

-- Mientras habla un personaje (StoryAudio) el ambiente baja a `amount` (0.5 = mitad); al acabar, vuelve
function SoundFx.voiceDuck(on: boolean, amount: number?)
	groupDuck.Ambience = if on then math.clamp(amount or 0.5, 0.1, 1) else 1
	applyGroup("Ambience")
end

-- Agacha la música un momento (fanfarria de nivel, misión cumplida…) y la devuelve suave.
-- amount = volumen al que baja (0.5 = mitad); hold = cuánto se queda abajo (s)
local duckToken = 0
function SoundFx.duck(amount: number, hold: number?)
	duckToken += 1
	local token = duckToken
	local target = math.clamp(amount, 0.1, 1)
	local attack, release = MIX.DuckAttack or 0.08, MIX.DuckRelease or 0.9
	task.spawn(function()
		local from = groupDuck.Music or 1
		local t0 = os.clock()
		while token == duckToken and os.clock() - t0 < attack do
			groupDuck.Music = from + (target - from) * ((os.clock() - t0) / attack)
			applyGroup("Music")
			task.wait()
		end
		groupDuck.Music = target
		applyGroup("Music")
		task.wait(hold or 1)
		t0 = os.clock()
		while token == duckToken and os.clock() - t0 < release do
			groupDuck.Music = target + (1 - target) * ((os.clock() - t0) / release)
			applyGroup("Music")
			task.wait()
		end
		if token == duckToken then
			groupDuck.Music = 1
			applyGroup("Music")
		end
	end)
end

-- Trozo de una grabación de la biblioteca (Config.Sounds[name].Region = { desde, hasta }, en segundos):
-- solo vale para su Id de Config (no para un Sound de ReplicatedStorage > Sonidos ni para el Fallback).
-- En los bucles, el bucle se queda dentro del trozo. Devuelve cuánto dura (s) o nil si no hay trozo.
local function applyRegion(sound: Sound, name: string, id: string, looped: boolean): number?
	local entry = SOUNDS[name]
	local region = entry and entry.Region
	if type(region) ~= "table" or type(region[1]) ~= "number" or type(region[2]) ~= "number" or region[2] <= region[1] then
		return nil
	end
	if SoundFx.resolve(entry.Id) ~= id then
		return nil
	end
	local ok = pcall(function()
		local range = NumberRange.new(region[1], region[2])
		sound.PlaybackRegionsEnabled = true
		sound.PlaybackRegion = range
		if looped then
			sound.LoopRegion = range
		end
	end)
	return if ok then region[2] - region[1] else nil
end

-- At: la pieza (o el Attachment) de donde sale, o un punto (Vector3) del mundo; sin At, en 2D
type At = BasePart | Attachment | Vector3
type PlayOpts = { Volume: number?, Pitch: number?, At: At?, NoLayers: boolean? }
local playOne: (name: string, volume: number?, pitch: number?, at: At?) -> Sound?

-- Toca un sonido una vez. at = pieza donde suena (se oye más flojo de lejos); sin at, suena "en la cabeza".
-- También vale SoundFx.play(name, { Volume, Pitch, At }). Si no hay audio para ese nombre, no suena
-- (sin errores). Config.Sounds[name] puede llevar Layers (otros sonidos encima, con su retraso), Duck
-- (agacha la música), Cooldown, Vary (variación de tono) y Category (volumen por categoría).
function SoundFx.play(name: string, volume: (number | PlayOpts)?, pitch: number?, at: At?): Sound?
	local noLayers = false
	if type(volume) == "table" then
		local opts = volume :: PlayOpts
		volume, pitch, at, noLayers = opts.Volume, opts.Pitch, opts.At, opts.NoLayers == true
	end
	if muted or sfxLevel <= 0 then
		return nil
	end
	local entry = SOUNDS[name]
	if not SoundFx.allowed(name) then
		return nil
	end
	lastPlayed[name] = os.clock()
	local sound = playOne(name, volume :: number?, pitch, at)
	if entry and not noLayers then
		if type(entry.Layers) == "table" then
			for _, layer in entry.Layers do
				local function go()
					playOne(layer.Name, (layer.Volume or 1) * ((volume :: number?) or 1), (layer.Pitch or 1) * (pitch or 1), at)
				end
				if (layer.Delay or 0) > 0 then
					task.delay(layer.Delay, go)
				else
					go()
				end
			end
		end
		if type(entry.Duck) == "number" and (sound or entry.Layers) then
			SoundFx.duck(entry.Duck, entry.DuckHold)
		end
	end
	return sound
end

-- Distancias de un sonido del mundo (Config.Sounds: MinDistance / MaxDistance): entero hasta Min y se
-- apaga suave (InverseTapered) hasta Max. Cerca, fuerte; al alejarte, más flojo.
function SoundFx.distances(name: string): (number, number)
	local entry = SOUNDS[name] or {}
	local maxD = tonumber(entry.MaxDistance) or 120
	local minD = math.min(tonumber(entry.MinDistance) or 10, maxD * 0.5)
	return minD, maxD
end

function SoundFx.make3D(sound: Sound, name: string)
	local minD, maxD = SoundFx.distances(name)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = minD
	sound.RollOffMaxDistance = maxD
end

function playOne(name: string, volume: number?, pitch: number?, at: At?): Sound?
	local id = soundId(name)
	if not id or muted then
		return nil
	end
	local entry = SOUNDS[name] or {}
	if not at and name ~= "Clic" then
		-- Sonido de interfaz: si acaba de sonar el clic automático, se corta (no dos sonidos por pulsación)
		lastUiSound = os.clock()
		local click = autoClick
		if click and os.clock() - click.At < CLICK_WINDOW then
			autoClick = nil
			click.Sound:Destroy()
		end
	end
	-- (el multiplicador no pasa de 1: por encima satura)
	local v, p = SoundFx.tune(name, id, math.min(volume or 1, 1), pitch)
	-- Variación (nunca dos golpes iguales): tono ±Vary (por defecto ±5 %) y volumen ±8 %
	local vary = if type(entry.Vary) == "number" then entry.Vary else 0.05
	local sound = Instance.new("Sound")
	sound.SoundId = id
	-- (el Fallback de Roblox ya estaba a su volumen: la categoría solo ajusta los nuestros)
	local category = if usingFallback[name] then 1 else SoundFx.categoryVolume(name)
	sound.Volume = v * category * (1 - vary * 1.6 * math.random())
	sound.PlaybackSpeed = p * (1 - vary + math.random() * vary * 2)
	local spot: Attachment? = nil -- (un punto suelto: un Attachment que se va con el sonido)
	if typeof(at) == "Vector3" then
		local a = Instance.new("Attachment")
		a.Name = "SonidoEn"
		a.WorldPosition = at :: Vector3
		a.Parent = workspace.Terrain
		spot = a
	end
	if at then
		-- En el mundo: se oye entero cerca y se apaga hasta MaxDistance (InverseTapered: sin cortes)
		SoundFx.make3D(sound, name)
	end
	-- Su control del menú: 🔔 Efectos (grupo SFX) o 🌳 Ambiente (Bus = "Ambience" en Config.Sounds)
	sound.SoundGroup = SoundFx.group(if entry.Bus == "Ambience" then "Ambience" else "SFX")
	local span = applyRegion(sound, name, id, false)
	sound.Parent = spot or (at :: Instance?) or folder
	sound:Play()
	active += 1
	local gone = false
	local function done()
		if not gone then
			gone = true
			active -= 1
			sound:Destroy()
			if spot then
				spot:Destroy()
			end
		end
	end
	sound.Ended:Connect(done)
	sound.Destroying:Connect(function()
		if not gone then
			gone = true
			active -= 1
		end
	end)
	local speed = math.max(sound.PlaybackSpeed, 0.05)
	-- Un trozo de una grabación larga: se apaga con un fundido corto (sin «clic» al cortar) y se quita al acabar
	local fade = entry.FadeOut
	if span and type(fade) == "number" and fade > 0 then
		task.delay(math.max(0, span - fade) / speed, function()
			if not gone then
				pcall(function()
					game:GetService("TweenService"):Create(sound, TweenInfo.new(fade / speed), { Volume = 0 }):Play()
				end)
			end
		end)
	end
	task.delay(if span then math.min(entry.MaxSeconds or 8, span / speed + 0.25) else entry.MaxSeconds or 8, done)
	return sound
end

-- Nivel de los efectos (0 … 1). 0 = no suena ningún efecto (sin callar el ambiente, que va aparte)
function SoundFx.setLevel(value: number)
	SoundFx.setGroupLevel("SFX", value)
end

function SoundFx.level(): number
	return sfxLevel
end

-- Cuántos efectos sueltos suenan ahora (pruebas y DebugHud)
function SoundFx.activeCount(): number
	return active
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
	sound.SoundGroup = SoundFx.group(groupName or (if entry.Bus == "Ambience" then "Ambience" else "SFX"))
	applyRegion(sound, name, id, true)
	if parent and (parent:IsA("BasePart") or parent:IsA("Attachment")) then
		-- En un sitio del mundo: se oye solo cerca (por defecto llegaba a 10000 studs); el alcance, el
		-- de su entrada de Config.Sounds (un motor se oye más lejos que una tele)
		SoundFx.make3D(sound, name)
		if not (SOUNDS[name] and SOUNDS[name].MaxDistance) then
			sound.RollOffMaxDistance = 40
			sound.RollOffMinDistance = math.min(sound.RollOffMinDistance, 10)
		end
	end
	sound.Parent = parent or folder
	sound:Play()
	return sound
end

-- Un golpe suelto del ambiente (tic-tac del reloj, pitido del monitor, una puerta lejos): suena "en la
-- cabeza", en el grupo Ambience (control 🌳 Ambiente) y sin contar como sonido de la interfaz (no
-- quita el clic de los botones). volume y pitch multiplican los de Config.Sounds. nil si no hay audio.
function SoundFx.ambient(name: string, volume: number?, pitch: number?): Sound?
	local id = soundId(name)
	if not id or muted then
		return nil
	end
	local v, p = SoundFx.tune(name, id, math.min(volume or 1, 1), pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = v
	sound.PlaybackSpeed = p * (0.97 + math.random() * 0.06)
	sound.SoundGroup = SoundFx.group("Ambience")
	sound.Parent = folder or SoundService
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

---------------------------------------------------------------------
-- Voces (voz sintetizada de Roblox)
---------------------------------------------------------------------
local talking = 0
local lastVoice: any = nil -- (la que suena: se corta al silenciar)
local Speech: any = nil -- (Controllers/Speech; se carga al primer uso)
local CastVoices: any = nil

-- La voz que toca: una tabla { VoiceId, Pitch, Speed }, un personaje o perfil ("Megafonia", "Lucia"…)
-- o un número (forma antigua: multiplicador de tono → la voz de megafonía, más aguda o más grave)
local function resolveVoice(voice: any): { [string]: any }
	if type(voice) == "table" and voice.VoiceId then
		return voice
	elseif type(voice) == "string" then
		return Speech.voiceFor(voice)
	end
	local base = CastVoices.resolve("Megafonia")
	if type(voice) == "number" and voice > 0 then
		return { VoiceId = base.VoiceId, Pitch = math.clamp(base.Pitch + 12 * math.log(voice, 2), -12, 12), Speed = base.Speed }
	end
	return base
end

-- Dice un texto en voz alta (voz sintetizada de Roblox, Controllers/Speech).
--   voice: la voz (ver resolveVoice); volume: multiplicador; at: la cabeza de quien habla (suena
--   desde ahí, más bajo cuanto más lejos; es gente de la calle: solo si sobra cupo de voces)
function SoundFx.voice(text: string, voice: any?, volume: number?, at: Instance?)
	if not VOICES.Enabled or muted or talking >= 1 then
		return
	end
	if not Speech then
		Speech = require(script.Parent.Speech)
		CastVoices = require(ReplicatedStorage.Shared.LifeStory.CastVoices)
	end
	-- (la gente de la calle no habla encima de una voz de la historia)
	if at and Speech.busy() then
		return
	end
	talking += 1
	task.spawn(function()
		pcall(function()
			lastVoice = Speech.say(text, resolveVoice(voice), {
				At = at,
				Kind = if at then "Street" else "Story",
				Volume = (VOICES.Volume or 0.7) * (volume or 1),
				Range = if at then VOICES.Far else nil,
				Cancelled = function()
					return muted
				end,
			})
		end)
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
	local lastBump = 0
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			SoundFx.play("Salto", 1, nil, root)
		elseif new == Enum.HumanoidStateType.Landed then
			-- Caída alta: un solo "pof" del cuerpo, más fuerte cuanto más alta (con tope; nada de explosión)
			if fallSpeed > 55 then
				SoundFx.play("GolpeCaida", SoundFx.landingVolume(fallSpeed), nil, root)
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
		if not humanoid.SeatPart and lastSpeed > 22 and speed < 4 and humanoid.MoveDirection.Magnitude > 0.5 and os.clock() - lastBump > 0.4 then
			lastBump = os.clock()
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
local vehicleChassis: BasePart? = nil
local enginePitch = 1 -- tono propio del motor (vehículos premium del pase: atributo EnginePitch)
local lastHorn = 0
local horn: () -> () -- más abajo
-- Sin motor: la cadena de la bici, el zumbido del patinete eléctrico y las ruedas del monopatín
-- (en bucle, suben de volumen y de tono con la velocidad; parados no suenan)
local RIDE_LOOPS = { Bici = "BiciCadena", Patinete = "PatineteZumbido", Monopatin = "MonopatinRodar" }
local ride: Sound? = nil
-- Con puertas: al subir se cierra la puerta (y luego arranca); al bajar se abre
local CAR_DOORS = { Coche = true, Patrulla = true, Bomberos = true, Camion = true }
-- Bocina grave (autobús, camión, bomberos y los barcos); la moto, el claxon más agudo
local HEAVY_HORN = { Autobus = true, Camion = true, Bomberos = true, Lancha = true, Gaviota = true }
local MOTOR_KINDS = { Coche = true, Moto = true, Autobus = true, Camion = true, Patrulla = true, Bomberos = true, Lancha = true, Gaviota = true }
-- Marchas: el cambio suena al subir de marcha (coche y moto). Umbrales de velocidad (ratio 0..1)
local GEAR_UP = { 0.2, 0.38, 0.56, 0.74 }
local GEAR_DOWN_MARGIN = 0.06 -- (para bajar hay que perder algo más de velocidad: no suena dos veces)
local gear = 1
local skid: Sound? = nil
local skidLevel = 0

local function hornAction(_, state)
	if state == Enum.UserInputState.Begin then
		horn()
	end
	return Enum.ContextActionResult.Pass
end

-- La marcha que toca con esta velocidad (ratio 0..1), sabiendo la de ahora (pura: test-sfx)
function SoundFx.gearFor(ratio: number, current: number): number
	local g = current
	while g <= #GEAR_UP and ratio >= GEAR_UP[g] do
		g += 1
	end
	while g > 1 and ratio < GEAR_UP[g - 1] - GEAR_DOWN_MARGIN do
		g -= 1
	end
	return g
end

-- Cuánto chirrían las ruedas (0..1): derrapando con el freno de mano o frenando a fondo deprisa.
-- Solo coches, camiones…: ni motos, bicis, barcos ni el caballo (pura: test-sfx)
function SoundFx.skidAmount(kind: string?, drift: boolean, hardBrake: boolean, speed: number): number
	if not kind or not CAR_DOORS[kind] and kind ~= "Autobus" then
		return 0
	end
	local fast = math.abs(speed)
	if drift and fast > 8 then
		return math.clamp(fast / 35, 0.4, 1)
	elseif hardBrake and fast > 22 then
		return math.clamp((fast - 22) / 25, 0.3, 0.75)
	end
	return 0
end

function SoundFx.vehicleStart(kind: string, chassis: BasePart)
	vehicleKind = kind
	vehicleChassis = chassis
	gear = 1
	-- Móvil: botón de claxon/timbre solo mientras vas montado
	local bell = kind == "Bici" or kind == "Patinete"
	TouchLayout.register({
		Id = "Claxon",
		Icon = if bell then "timbre" else "claxon",
		Label = if bell then "Timbre" else "Claxon",
		Slot = "Gestos", -- (el hueco grande del Ataque es el acelerador)
		DriveSlot = "Claxon", -- (al volante en el móvil: junto a Bajarse, UI/HudLayout.Drive)
		Priority = 2.5,
		Key = "H",
		Visible = function()
			return vehicleKind ~= nil and TouchLayout.riding()
		end,
		Callback = horn,
	})
	if CAR_DOORS[kind] then
		SoundFx.play("PuertaCoche", 1, nil, chassis)
	end
	if MOTOR_KINDS[kind] then
		-- (con puerta, el motor arranca cuando ya está cerrada)
		task.delay(if CAR_DOORS[kind] then 0.35 else 0, function()
			if vehicleChassis == chassis then
				SoundFx.play("Arranque", 1, nil, chassis)
			end
		end)
		engine = SoundFx.loop("Motor", chassis)
		local model = chassis.Parent
		local pitch = if model then model:GetAttribute("EnginePitch") else nil
		enginePitch = if type(pitch) == "number" then math.clamp(pitch, 0.7, 1.4) else 1
		if engine then
			engine.PlaybackSpeed *= (if kind == "Moto" then 1.35 else 1) * enginePitch
		end
	elseif RIDE_LOOPS[kind] then
		ride = SoundFx.loop(RIDE_LOOPS[kind], chassis)
		if ride then
			ride.Volume = 0
		end
	end
end

function SoundFx.vehicleStop()
	if engine then
		engine:Destroy()
		engine = nil
	end
	if ride then
		ride:Destroy()
		ride = nil
	end
	if skid then
		skid:Destroy()
		skid = nil
	end
	skidLevel = 0
	if vehicleKind and CAR_DOORS[vehicleKind] then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		SoundFx.play("PuertaCocheAbrir", 1, nil, root or vehicleChassis)
	end
	ContextActionService:UnbindAction("HornTouch")
	vehicleKind = nil
	vehicleChassis = nil
end

-- Cada fotograma: el motor sube de tono con la velocidad (ratio 0..1); la cadena, el zumbido o las
-- ruedas suben de volumen y de tono; en coche y moto, «clac» del cambio al subir de marcha
function SoundFx.vehicleSpeed(ratio: number)
	if engine then
		local base = (if vehicleKind == "Moto" then 1.35 else 1) * enginePitch
		engine.PlaybackSpeed = base * (0.75 + ratio * 0.9)
		engine.Volume = (SOUNDS.Motor.Volume or 0.45) * (0.7 + ratio * 0.5) -- (el silencio lo pone el grupo SFX)
		if vehicleKind == "Coche" or vehicleKind == "Moto" or vehicleKind == "Patrulla" then
			local g = SoundFx.gearFor(ratio, gear)
			if g > gear then
				SoundFx.play("CambioMarcha", 1, nil, vehicleChassis)
			end
			gear = g
		end
	end
	if ride and vehicleKind then
		local entry = SOUNDS[RIDE_LOOPS[vehicleKind]] or {}
		ride.Volume = (entry.Volume or 0.5) * math.clamp(ratio * 2.2, 0, 1)
		ride.PlaybackSpeed = (entry.Pitch or 1) * (0.75 + ratio * 0.5)
	end
end

-- Chirrido de las ruedas (Driving, cada fotograma): amount 0..1 (SoundFx.skidAmount). Un bucle que
-- entra y sale suave; sin derrapar se queda callado
function SoundFx.skid(amount: number)
	skidLevel += (math.clamp(amount, 0, 1) - skidLevel) * (if amount > skidLevel then 0.35 else 0.15)
	if skidLevel < 0.02 then
		skidLevel = 0
		if skid then
			skid.Volume = 0
		end
		return
	end
	if not skid and vehicleChassis then
		skid = SoundFx.loop("Derrape", vehicleChassis)
	end
	if skid then
		skid.Volume = ((SOUNDS.Derrape and SOUNDS.Derrape.Volume) or 0.5) * skidLevel
		skid.PlaybackSpeed = 0.92 + 0.12 * skidLevel
	end
end

-- Choques: flojo o fuerte según la velocidad, con tope de volumen y como mucho uno cada CRASH_COOLDOWN
-- por vehículo (al rebotar contra la pared se tocaba varias veces seguidas)
local CRASH_MIN, CRASH_STRONG, CRASH_MAX_VOLUME, CRASH_COOLDOWN = 8, 30, 0.8, 0.35
local lastCrash: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local NO_PART = {}

-- Qué choque suena y a qué volumen (multiplicador 0..CRASH_MAX_VOLUME); nil = demasiado lento
function SoundFx.crashSound(speed: number): (string?, number)
	if speed <= CRASH_MIN then
		return nil, 0
	end
	local name = if speed >= CRASH_STRONG then "ChoqueFuerte" else "ChoqueLeve"
	return name, math.clamp(speed / 60, 0.3, CRASH_MAX_VOLUME)
end

function SoundFx.crash(speed: number, at: BasePart?)
	local name, volume = SoundFx.crashSound(speed)
	if not name then
		return
	end
	local key = at or NO_PART
	if os.clock() - (lastCrash[key] or -math.huge) < CRASH_COOLDOWN then
		return
	end
	lastCrash[key] = os.clock()
	SoundFx.play(name, volume, nil, at)
end

-- Intermitente: «tic» al encenderse y «tac» (más grave) al apagarse, muy suave (solo lo oye el conductor)
function SoundFx.indicatorTick(on: boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	SoundFx.play("Intermitente", 1, if on then 1 else 0.8, root)
end

-- Freno de mano echado o quitado (el «clac» de la palanca) y el interruptor de las luces
function SoundFx.handbrake(engaged: boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	SoundFx.play("FrenoMano", 1, if engaged then 1 else 1.25, root)
end

function SoundFx.lightSwitch()
	SoundFx.play("LucesCoche")
end

-- Comer y beber (gestos de ReactMotion "Eat" / "Drink"): el bocado o el trago, cuando la mano llega a
-- la boca. Devuelve el nombre del sonido (o nil si el gesto no suena)
local GESTURE_SOUNDS = { Eat = "Comer", Drink = "Beber" }
function SoundFx.gesture(kind: string?): string?
	local name = kind and GESTURE_SOUNDS[kind]
	if name then
		task.delay(0.3, function()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			SoundFx.play(name, { At = root })
		end)
	end
	return name
end

-- Cocinar o fabricar algo (ventanas de la granja y de los negocios: acción "Make" con la receta).
-- Cocina, horno y conservas: la sartén; molino, almazara y telar: el taller. Devuelve el sonido o nil
local CRAFT_SOUNDS = { Cocina = "Cocinar", Horno = "Cocinar", Conservas = "Cocinar", Molino = "Fabricar", Almazara = "Fabricar", Telar = "Fabricar" }
function SoundFx.craftSound(station: string?): string?
	return if station then CRAFT_SOUNDS[station] else nil
end
function SoundFx.craft(recipeId: any)
	local ok, Farming = pcall(require, ReplicatedStorage.Shared.Farming)
	local recipe = ok and type(recipeId) == "string" and Farming.recipeById[recipeId]
	local name = recipe and SoundFx.craftSound(recipe.Station)
	if name then
		local character = player.Character
		SoundFx.play(name, { At = character and character:FindFirstChild("HumanoidRootPart") :: BasePart? })
	end
end

-- Volumen del golpe al caer desde alto (velocidad de caída en studs/s): de 0.4 a 1 como mucho
function SoundFx.landingVolume(fallSpeed: number): number
	return math.clamp(0.4 + (fallSpeed - 55) / 80, 0.4, 1)
end

function horn()
	if not vehicleKind or os.clock() - lastHorn < 0.6 then
		return
	end
	lastHorn = os.clock()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if HEAVY_HORN[vehicleKind] then
		-- (la bocina del barco, grave como la de los camiones)
		SoundFx.play("ClaxonPesado", 1, if vehicleKind == "Lancha" or vehicleKind == "Gaviota" then 0.85 else 1, root)
	elseif MOTOR_KINDS[vehicleKind] then
		SoundFx.play("Claxon", 1, if vehicleKind == "Moto" then 1.2 else 1, root)
	else
		SoundFx.play("Timbre", 1, nil, root)
	end
end

---------------------------------------------------------------------
-- Gente de la ciudad
---------------------------------------------------------------------
-- (tabla débil: aunque no llegue el Destroying, lo que desaparece se olvida solo)
-- Cada persona de la calle tiene su voz (una de Config.StreetVoices.Presets según su edad: atributo Age)
local pitches: { [Instance]: { [string]: any } } = setmetatable({}, { __mode = "k" }) :: any
local function pitchOf(npc: Instance): { [string]: any }
	if not pitches[npc] then
		local presets = VOICES.Presets or {}
		local age = npc:GetAttribute("Age")
		local list = presets[if type(age) == "string" and presets[age] then age else "Adulto"] or {}
		pitches[npc] = list[math.random(1, math.max(1, #list))] or { VoiceId = "101", Pitch = 0, Speed = 1 }
		-- (al desaparecer la persona se olvida su voz: si no, la tabla crece sin parar)
		npc.Destroying:Connect(function()
			pitches[npc] = nil
		end)
	end
	return pitches[npc]
end

-- La voz de un NPC: la de su personaje si es del reparto (atributo NpcId, CastVoices); si no, una de
-- Config.StreetVoices.Presets según su edad (fija para esa persona)
local function voiceOfNpc(npc: Instance): any
	local id = npc:GetAttribute("NpcId")
	if type(id) == "string" then
		if not CastVoices then
			CastVoices = require(ReplicatedStorage.Shared.LifeStory.CastVoices)
		end
		if CastVoices.People[id] or id == "Familia" or id == "Abu" then
			return id -- (SoundFx.voice lo resuelve con la casa y la etapa del jugador)
		end
	end
	return pitchOf(npc)
end

-- Desde dónde se oye (la cabeza de tu personaje; si no hay, la cámara)
local function earPosition(): Vector3?
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if head then
		return head.Position
	end
	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position
end

-- Todo NPC que habla (su bocadillo: Npc.say del servidor, las frases de la calle, los «¡Eh!»…) se oye
-- con su voz, desde su cabeza: se oye bien de cerca (Near) y cada vez menos hasta Far studs; más lejos,
-- nada (ni se pide la voz). Si hablan varios a la vez, se oye al más cercano (la voz tiene límite por
-- minuto: Speech). Las frases de la historia ya las dice StoryAudio (conversaciones, escenas, Baby).
local candidates: { { Npc: Instance, Head: BasePart, Text: string, Distance: number } } = {}
local picking = false
local function npcVoice(npc: Instance, text: string, source: string, opts: { [string]: any }?)
	if muted or not VOICES.Enabled or type(text) ~= "string" then
		return
	end
	local o = opts or {}
	if source ~= "Server" and (o.Story or o.Hold) then
		return -- (la dice StoryAudio con la voz de la historia)
	end
	if npc == player.Character or Players:GetPlayerFromCharacter(npc) then
		return -- (los jugadores no tienen voz sintetizada)
	end
	if not npc:FindFirstChildOfClass("Humanoid") or npc:GetAttribute("Species") ~= nil then
		return -- (animales y cosas: sus sonidos son otros)
	end
	if player:GetAttribute("InDialogue") or player:GetAttribute("InCinematic") then
		return
	end
	local head = npc:FindFirstChild("Head")
	local ear = earPosition()
	if not head or not head:IsA("BasePart") or not ear then
		return
	end
	local distance = ((head :: BasePart).Position - ear).Magnitude
	if distance > (VOICES.Far or 55) then
		return
	end
	table.insert(candidates, { Npc = npc, Head = head :: BasePart, Text = text, Distance = distance })
	if picking then
		return
	end
	picking = true
	task.delay(0.25, function()
		picking = false
		local best = nil
		for _, c in candidates do
			if c.Head.Parent and (not best or c.Distance < best.Distance) then
				best = c
			end
		end
		table.clear(candidates)
		if best then
			SoundFx.voice(best.Text, voiceOfNpc(best.Npc), 1, best.Head)
		end
	end)
end

-- Bocadillo solo para ti (comentarios sueltos de la gente)
local function localBubble(npc: Model, text: string)
	SpeechBubbles.show(npc, text, { Seconds = 3.5, Ambient = true })
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
				localBubble(best, line) -- (su voz la pone npcVoice, al salir el bocadillo)
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
-- (silencio total de efectos y ambiente: el menú ya no lo usa, va por niveles en Controllers/AudioMix)
function SoundFx.setMuted(value: boolean)
	muted = value
	-- Los grupos callan todo lo que ya suena (bucles, motor, lluvia, sonidos del servidor)
	SoundFx.setGroupOn("SFX", not value)
	SoundFx.setGroupOn("Ambience", not value)
	if value then
		-- La voz sintetizada no va en un grupo: la que esté sonando se corta
		if lastVoice then
			pcall(lastVoice.Stop)
			lastVoice = nil
		end
	end
end

-- Sonidos creados por el servidor (romper cosas, patear juguetes) llevan el atributo SfxGroup:
-- aquí se meten en su grupo para que su control del menú (🔔 Efectos o 🌳 Ambiente) también les valga.
-- Y ningún sonido del mundo se queda sin grupo (uno de un modelo, de un personaje…): el que no tiene,
-- a Efectos. Así ninguno se salta los volúmenes del menú.
function SoundFx.tagSound(obj: Instance)
	if obj:IsA("Sound") then
		local name = obj:GetAttribute("SfxGroup")
		if type(name) == "string" and name ~= "" then
			obj.SoundGroup = SoundFx.group(name)
		elseif (obj :: Sound).SoundGroup == nil then
			(obj :: Sound).SoundGroup = SoundFx.group("SFX")
		end
	end
end
local tagServerSound = SoundFx.tagSound

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
		elseif kind == "Success" then
			SoundFx.play("Aviso")
		elseif kind == "Money" then
			-- El «ka-ching» lo pone GameSfx al subir el dinero; si aún no está subido, el aviso de siempre
			if not SoundFx.id("Dinero") then
				SoundFx.play("Aviso")
			end
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
	SpeechBubbles.onSpoken(npcVoice)
	task.spawn(streetChatter)
	task.spawn(crowd)
end

return SoundFx
